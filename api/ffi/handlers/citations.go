package handlers

import (
	"bytes"
	"github.com/Jake-Robins-Studios/provenencia/api/proto/engine"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/citations"
	"github.com/Jake-Robins-Studios/provenencia/core/database/graphfill"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcemetadata"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
	"google.golang.org/protobuf/proto"
)

func CreateCitationWithObservations(in []byte) ([]byte, error) {
	var req engine.CreateCitationWithObservationsRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("create_citation_with_observations", err)
	}
	userID, err := parseUserID(req.GetUserId())
	if err != nil {
		return nil, err
	}
	artifactID, err := parseID(req.GetArtifactId())
	if err != nil {
		return nil, err
	}
	graphID, err := parseID(req.GetGraphId())
	if err != nil {
		return nil, err
	}
	inputs, err := observationDraftsToInputs(req.GetObservations())
	if err != nil {
		return nil, err
	}
	draft, err := parseDraft(req.GetMetadata())
	if err != nil {
		return nil, err
	}
	var out *engine.CreateCitationWithObservationsResponse
	err = withStagedDepictions(req.GetProjectDir(), inputs, func(c *database.Catalog) error {
		res, wrote, err := writes.Run(c, writes.Op{Action: "create_citation_with_observations", UserID: userID},
			func(tx *database.Tx) (citations.CreateResult, []rowchange.Change, error) {
				res, changes, err := citations.CreateWithObservations(tx, userID, citations.CreateInput{
					ArtifactID:             artifactID,
					GraphID:                graphID,
					LocatorJSON:            req.GetLocatorJson(),
					Transcription:          req.GetTranscription(),
					Label:                  req.GetLabel(),
					TranscriptionUncertain: req.GetTranscriptionUncertain(),
					TranscriptionNote:      req.GetTranscriptionNote(),
					Notes:                  req.GetCitationNotes(),
				}, inputs)
				if err != nil {
					return citations.CreateResult{}, nil, err
				}
				more, err := applyDraft(tx, userID, sourcemetadata.Owner{Level: vocabkey.LevelCitation, ID: res.Citation.ID}, draft)
				return res, append(changes, more...), err
			})
		if err != nil {
			return err
		}
		listed, err := listedWritten(c, res.Citation.ID, res.Observations)
		if err != nil {
			return err
		}
		board, err := ownerBoardProto(c, sourcemetadata.Owner{Level: vocabkey.LevelCitation, ID: res.Citation.ID})
		if err != nil {
			return err
		}
		out = &engine.CreateCitationWithObservationsResponse{
			Citation:     citationProto(res.Citation),
			Effects:      writeEffectsProto(wrote),
			Observations: listed,
			Metadata:     board,
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

func CitationCountsByEvidenceGraph(in []byte) ([]byte, error) {
	var req engine.CitationCountsByEvidenceGraphRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("citation_counts_by_evidence_graph", err)
	}
	graphID, err := parseID(req.GetGraphId())
	if err != nil {
		return nil, err
	}
	var out *engine.CitationCountsByEvidenceGraphResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		counts, err := citations.CountByEvidenceGraph(c, graphID)
		if err != nil {
			return err
		}
		out = &engine.CitationCountsByEvidenceGraphResponse{}
		for artifactID, n := range counts {
			out.Counts = append(out.Counts, &engine.ArtifactCitationCount{
				ArtifactId: artifactID,
				Count:      n,
			})
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

func GetCitation(in []byte) ([]byte, error) {
	var req engine.GetCitationRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("get_citation", err)
	}
	citationID, err := parseID(req.GetCitationId())
	if err != nil {
		return nil, err
	}
	graphID, err := parseID(req.GetGraphId())
	if err != nil {
		return nil, err
	}
	var out *engine.GetCitationResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		cit, err := citations.Get(c, citationID)
		if err != nil {
			return err
		}
		notes, err := citations.ListNotes(c, citationID)
		if err != nil {
			return err
		}
		eg, err := graphfill.EvidenceGraph(c.Graph(), graphID)
		if err != nil {
			return err
		}
		rows, err := listedProtosFromGraph(c, eg, citationID)
		if err != nil {
			return err
		}
		out = &engine.GetCitationResponse{
			Citation:     citationProto(cit),
			Notes:        notes,
			Observations: rows,
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

func UpdateCitation(in []byte) ([]byte, error) {
	var req engine.UpdateCitationRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("update_citation", err)
	}
	userID, err := parseUserID(req.GetUserId())
	if err != nil {
		return nil, err
	}
	citationID, err := parseID(req.GetCitationId())
	if err != nil {
		return nil, err
	}
	draft, err := parseDraft(req.GetMetadata())
	if err != nil {
		return nil, err
	}
	var out *engine.UpdateCitationResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		cit, wrote, err := writes.Run(c, writes.Op{Action: "update_citation", UserID: userID},
			func(tx *database.Tx) (citations.Citation, []rowchange.Change, error) {
				cit, changes, err := citations.Update(tx, userID, citationID, citations.CitationFieldsInput{
					LocatorJSON:            req.GetLocatorJson(),
					Transcription:          req.GetTranscription(),
					Label:                  req.GetLabel(),
					TranscriptionUncertain: req.GetTranscriptionUncertain(),
					TranscriptionNote:      req.GetTranscriptionNote(),
				})
				if err != nil {
					return citations.Citation{}, nil, err
				}
				more, err := applyDraft(tx, userID, sourcemetadata.Owner{Level: vocabkey.LevelCitation, ID: citationID}, draft)
				return cit, append(changes, more...), err
			})
		if err != nil {
			return err
		}
		board, err := ownerBoardProto(c, sourcemetadata.Owner{Level: vocabkey.LevelCitation, ID: citationID})
		if err != nil {
			return err
		}
		out = &engine.UpdateCitationResponse{
			Citation: citationProto(cit),
			Effects:  writeEffectsProto(wrote),
			Metadata: board,
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

func ListCitationsByArtifact(in []byte) ([]byte, error) {
	var req engine.ListCitationsByArtifactRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("list_citations_by_artifact", err)
	}
	graphID, err := parseID(req.GetGraphId())
	if err != nil {
		return nil, err
	}
	artifactID, err := parseID(req.GetArtifactId())
	if err != nil {
		return nil, err
	}
	var out *engine.ListCitationsByArtifactResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		list, err := citations.ListByArtifact(c, graphID, artifactID)
		if err != nil {
			return err
		}
		// One board read for every listed Citation: the opened Citation's board
		// and its printed page come from the same rows.
		owners := make([]sourcemetadata.Owner, len(list))
		for i, row := range list {
			owners[i] = sourcemetadata.Owner{Level: vocabkey.LevelCitation, ID: row.Citation.ID}
		}
		boards, err := sourcemetadata.ListWorkspaces(c, owners)
		if err != nil {
			return err
		}
		db, err := c.DB()
		if err != nil {
			return err
		}
		pageID, err := sourcemetadata.PageFieldID(db)
		if err != nil {
			return err
		}
		out = &engine.ListCitationsByArtifactResponse{}
		for i, row := range list {
			listed := &engine.ListedCitation{
				Citation:         citationProto(row.Citation),
				ObservationCount: row.ObservationCount,
				SubjectNames:     row.SubjectNames,
				Metadata:         metadataEntriesProto(boards[i].Entries),
			}
			for _, e := range boards[i].Entries {
				if pageID != nil && e.Value != nil && bytes.Equal(e.Field.ID, pageID) {
					listed.PageLabel = sourcemetadata.PageText(*e.Value, e.Field)
				}
			}
			out.Citations = append(out.Citations, listed)
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

func DeleteCitation(in []byte) ([]byte, error) {
	var req engine.DeleteCitationRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("delete_citation", err)
	}
	userID, err := parseUserID(req.GetUserId())
	if err != nil {
		return nil, err
	}
	citationID, err := parseID(req.GetCitationId())
	if err != nil {
		return nil, err
	}
	var out *engine.DeleteCitationResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		wrote, err := writes.RunChanges(c, writes.Op{Action: "delete_citation", UserID: userID},
			func(tx *database.Tx) ([]rowchange.Change, error) {
				return citations.Delete(tx, userID, citationID)
			})
		if err != nil {
			return err
		}
		out = &engine.DeleteCitationResponse{Effects: writeEffectsProto(wrote)}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

func citationProto(c citations.Citation) *engine.Citation {
	return &engine.Citation{
		Id:                     database.UUIDString(c.ID),
		Ref:                    c.Ref,
		ArtifactId:             database.UUIDString(c.ArtifactID),
		LocatorJson:            c.LocatorJSON,
		Transcription:          c.Transcription,
		Label:                  c.Label,
		TranscriptionUncertain: c.TranscriptionUncertain,
		TranscriptionNote:      c.TranscriptionNote,
	}
}
