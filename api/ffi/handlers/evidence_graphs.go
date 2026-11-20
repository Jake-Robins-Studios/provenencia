package handlers

import (
	"github.com/Jake-Robins-Studios/provenencia/api/proto/engine"
	"github.com/Jake-Robins-Studios/provenencia/core/apperr"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencegraphs"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcemetadata"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
	"google.golang.org/protobuf/proto"
)

func evidenceGraphProto(g evidencegraphs.Graph) *engine.EvidenceGraph {
	out := &engine.EvidenceGraph{
		Id:          database.UUIDString(g.ID),
		Ref:         g.Ref,
		SourceId:    database.UUIDString(g.SourceID),
		Name:        g.Name,
		Description: g.Description,
	}
	for _, id := range g.ArtifactIDs {
		out.ArtifactIds = append(out.ArtifactIds, database.UUIDString(id))
	}
	return out
}

// ListEvidenceGraphs returns the graphs of one Source in list order, or of the
// whole project grouped by Source.
func ListEvidenceGraphs(in []byte) ([]byte, error) {
	var req engine.ListEvidenceGraphsRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("list_evidence_graphs", err)
	}
	sourceID, err := optionalID(req.GetSourceId())
	if err != nil {
		return nil, err
	}
	var out *engine.ListEvidenceGraphsResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		graphs, err := evidencegraphs.List(c, sourceID)
		if err != nil {
			return err
		}
		out = &engine.ListEvidenceGraphsResponse{}
		for _, g := range graphs {
			out.Graphs = append(out.Graphs, evidenceGraphProto(g))
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

func CreateEvidenceGraph(in []byte) ([]byte, error) {
	var req engine.CreateEvidenceGraphRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("create_evidence_graph", err)
	}
	userID, err := parseUserID(req.GetUserId())
	if err != nil {
		return nil, err
	}
	sourceID, err := parseID(req.GetSourceId())
	if err != nil {
		return nil, err
	}
	artifactIDs, err := parseIDs(req.GetArtifactIds())
	if err != nil {
		return nil, err
	}
	draft, err := parseDraft(req.GetMetadata())
	if err != nil {
		return nil, err
	}
	var out *engine.CreateEvidenceGraphResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		g, wrote, err := writes.Run(c, writes.Op{Action: "create_evidence_graph", UserID: userID},
			func(tx *database.Tx) (evidencegraphs.Graph, []rowchange.Change, error) {
				g, changes, err := evidencegraphs.Create(tx, userID, evidencegraphs.CreateInput{
					SourceID:    sourceID,
					Name:        req.GetName(),
					Description: req.GetDescription(),
					ArtifactIDs: artifactIDs,
				})
				if err != nil {
					return evidencegraphs.Graph{}, nil, err
				}
				more, err := applyDraft(tx, userID, sourcemetadata.Owner{Level: vocabkey.LevelGraph, ID: g.ID}, draft)
				return g, append(changes, more...), err
			})
		if err != nil {
			return err
		}
		entries, err := ownerBoardProto(c, sourcemetadata.Owner{Level: vocabkey.LevelGraph, ID: g.ID})
		if err != nil {
			return err
		}
		out = &engine.CreateEvidenceGraphResponse{Graph: evidenceGraphProto(g), Effects: writeEffectsProto(wrote), Metadata: entries}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

func UpdateEvidenceGraph(in []byte) ([]byte, error) {
	var req engine.UpdateEvidenceGraphRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("update_evidence_graph", err)
	}
	userID, err := parseUserID(req.GetUserId())
	if err != nil {
		return nil, err
	}
	graphID, err := parseID(req.GetGraphId())
	if err != nil {
		return nil, err
	}
	artifactIDs, err := parseIDs(req.GetArtifactIds())
	if err != nil {
		return nil, err
	}
	draft, err := parseDraft(req.GetMetadata())
	if err != nil {
		return nil, err
	}
	var out *engine.UpdateEvidenceGraphResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		wrote, err := writes.RunChanges(c, writes.Op{Action: "update_evidence_graph", UserID: userID},
			func(tx *database.Tx) ([]rowchange.Change, error) {
				changes, err := evidencegraphs.Update(tx, userID, graphID, evidencegraphs.UpdateInput{
					Name:        req.GetName(),
					Description: req.GetDescription(),
					ArtifactIDs: artifactIDs,
				})
				if err != nil {
					return nil, err
				}
				more, err := applyDraft(tx, userID, sourcemetadata.Owner{Level: vocabkey.LevelGraph, ID: graphID}, draft)
				return append(changes, more...), err
			})
		if err != nil {
			return err
		}
		entries, err := ownerBoardProto(c, sourcemetadata.Owner{Level: vocabkey.LevelGraph, ID: graphID})
		if err != nil {
			return err
		}
		out = &engine.UpdateEvidenceGraphResponse{Effects: writeEffectsProto(wrote), Metadata: entries}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

func DeleteEvidenceGraph(in []byte) ([]byte, error) {
	var req engine.DeleteEvidenceGraphRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("delete_evidence_graph", err)
	}
	userID, err := parseUserID(req.GetUserId())
	if err != nil {
		return nil, err
	}
	graphID, err := parseID(req.GetGraphId())
	if err != nil {
		return nil, err
	}
	var out *engine.DeleteEvidenceGraphResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		wrote, err := writes.RunChanges(c, writes.Op{Action: "delete_evidence_graph", UserID: userID},
			func(tx *database.Tx) ([]rowchange.Change, error) {
				return evidencegraphs.Delete(tx, userID, graphID)
			})
		if err != nil {
			return err
		}
		out = &engine.DeleteEvidenceGraphResponse{Effects: writeEffectsProto(wrote)}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

// GetEvidenceGraphUnlinkImpact is a read: which of the (graph, Artifact) pairs
// an edit would unlink are refused, each with its reason.
func GetEvidenceGraphUnlinkImpact(in []byte) ([]byte, error) {
	var req engine.GetEvidenceGraphUnlinkImpactRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("get_evidence_graph_unlink_impact", err)
	}
	var pairs []evidencegraphs.Pair
	for _, p := range req.GetPairs() {
		graphID, err := parseID(p.GetGraphId())
		if err != nil {
			return nil, err
		}
		artifactID, err := parseID(p.GetArtifactId())
		if err != nil {
			return nil, err
		}
		pairs = append(pairs, evidencegraphs.Pair{GraphID: graphID, ArtifactID: artifactID})
	}
	var out *engine.GetEvidenceGraphUnlinkImpactResponse
	err := withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		blocks, err := evidencegraphs.UnlinkImpact(c, pairs)
		if err != nil {
			return err
		}
		out = &engine.GetEvidenceGraphUnlinkImpactResponse{}
		for _, b := range blocks {
			block := &engine.EvidenceGraphUnlinkBlock{
				GraphId:       database.UUIDString(b.GraphID),
				ArtifactId:    database.UUIDString(b.ArtifactID),
				ReasonCode:    apperr.From(b.Reason).Code(),
				CitationCount: int32(b.CitationCount),
			}
			out.Blocked = append(out.Blocked, block)
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}
