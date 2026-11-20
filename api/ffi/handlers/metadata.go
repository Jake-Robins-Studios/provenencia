package handlers

import (
	"github.com/Jake-Robins-Studios/provenencia/api/proto/engine"
	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcemetadata"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
	"google.golang.org/protobuf/proto"
)

// parseOwner reads a metadata owner off the wire. An absent message is
// sourcemetadata.ErrInvalid; the id must be a UUIDv7; the level is copied as
// given and refused by sourcemetadata when it holds no metadata.
func parseOwner(o *engine.MetadataOwner) (sourcemetadata.Owner, error) {
	if o == nil {
		return sourcemetadata.Owner{}, sourcemetadata.ErrInvalid
	}
	id, err := parseID(o.GetId())
	if err != nil {
		return sourcemetadata.Owner{}, err
	}
	return sourcemetadata.Owner{Level: vocabkey.Level(o.GetLevel()), ID: id}, nil
}

// parseDraft reads a metadata draft off the wire. An absent message is nil
// (no metadata change); a present one, empty included, is the draft the owner's
// stored values become. A malformed field id is request.invalid_id before any
// write.
func parseDraft(d *engine.MetadataDraft) (*sourcemetadata.Draft, error) {
	if d == nil {
		return nil, nil
	}
	out := &sourcemetadata.Draft{}
	for _, v := range d.GetValues() {
		id, err := parseID(v.GetFieldId())
		if err != nil {
			return nil, err
		}
		out.Values = append(out.Values, sourcemetadata.Input{FieldID: id, ValueText: v.GetValueText(), Mark: parseValueMark(v.GetMark())})
	}
	for _, l := range d.GetLayout() {
		id, err := parseID(l.GetFieldId())
		if err != nil {
			return nil, err
		}
		out.Layout = append(out.Layout, sourcemetadata.LayoutRow{FieldID: id, SortOrder: int(l.GetSortOrder()), Dismissed: l.GetDismissed()})
	}
	return out, nil
}

// applyDraft saves a draft on the owner inside the caller's write: no changes
// for an absent draft, else sourcemetadata.Apply.
func applyDraft(tx *database.Tx, userID []byte, owner sourcemetadata.Owner, d *sourcemetadata.Draft) ([]rowchange.Change, error) {
	if d == nil {
		return nil, nil
	}
	return sourcemetadata.Apply(tx, userID, owner, *d)
}

// boardsProto is each owner's board as wire boards, in the order of owners
// (sourcemetadata.ListWorkspaces' boards, index-aligned).
func boardsProto(owners []sourcemetadata.Owner, boards []sourcemetadata.Board) []*engine.MetadataBoard {
	out := make([]*engine.MetadataBoard, len(owners))
	for i, o := range owners {
		out[i] = &engine.MetadataBoard{OwnerId: database.UUIDString(o.ID), Entries: metadataEntriesProto(boards[i].Entries)}
	}
	return out
}

func SetMetadata(in []byte) ([]byte, error) {
	var req engine.SetMetadataRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("set_metadata", err)
	}
	userID, err := parseUserID(req.GetUserId())
	if err != nil {
		return nil, err
	}
	owner, err := parseOwner(req.GetOwner())
	if err != nil {
		return nil, err
	}
	fieldID, err := parseID(req.GetFieldId())
	if err != nil {
		return nil, err
	}
	var out *engine.SetMetadataResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		_, wrote, err := writes.Run(c, writes.Op{Action: "update_metadata", UserID: userID},
			func(tx *database.Tx) (sourcemetadata.Row, []rowchange.Change, error) {
				return sourcemetadata.Set(tx, userID, owner, sourcemetadata.Input{
					FieldID:   fieldID,
					ValueText: req.GetValueText(),
					Mark:      parseValueMark(req.GetMark()),
				})
			})
		if err != nil {
			return err
		}
		entries, err := ownerBoardProto(c, owner)
		if err != nil {
			return err
		}
		out = &engine.SetMetadataResponse{Effects: writeEffectsProto(wrote), Metadata: entries}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

func ClearMetadata(in []byte) ([]byte, error) {
	var req engine.ClearMetadataRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("clear_metadata", err)
	}
	userID, err := parseUserID(req.GetUserId())
	if err != nil {
		return nil, err
	}
	owner, err := parseOwner(req.GetOwner())
	if err != nil {
		return nil, err
	}
	fieldID, err := parseID(req.GetFieldId())
	if err != nil {
		return nil, err
	}
	var out *engine.ClearMetadataResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		wrote, err := writes.RunChanges(c, writes.Op{Action: "update_metadata", UserID: userID},
			func(tx *database.Tx) ([]rowchange.Change, error) {
				return sourcemetadata.Clear(tx, userID, owner, fieldID)
			})
		if err != nil {
			return err
		}
		entries, err := ownerBoardProto(c, owner)
		if err != nil {
			return err
		}
		out = &engine.ClearMetadataResponse{Effects: writeEffectsProto(wrote), Metadata: entries}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

func DismissMetadataSuggestion(in []byte) ([]byte, error) {
	var req engine.DismissMetadataSuggestionRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("dismiss_metadata_suggestion", err)
	}
	userID, err := parseUserID(req.GetUserId())
	if err != nil {
		return nil, err
	}
	owner, err := parseOwner(req.GetOwner())
	if err != nil {
		return nil, err
	}
	fieldID, err := parseID(req.GetFieldId())
	if err != nil {
		return nil, err
	}
	var out *engine.DismissMetadataSuggestionResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		wrote, err := writes.RunChanges(c, writes.Op{Action: "dismiss_metadata_suggestion", UserID: userID},
			func(tx *database.Tx) ([]rowchange.Change, error) {
				return sourcemetadata.DismissSuggestion(tx, userID, owner, fieldID)
			})
		if err != nil {
			return err
		}
		entries, err := ownerBoardProto(c, owner)
		if err != nil {
			return err
		}
		out = &engine.DismissMetadataSuggestionResponse{Effects: writeEffectsProto(wrote), Metadata: entries}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

func ReorderMetadata(in []byte) ([]byte, error) {
	var req engine.ReorderMetadataRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("reorder_metadata", err)
	}
	userID, err := parseUserID(req.GetUserId())
	if err != nil {
		return nil, err
	}
	owner, err := parseOwner(req.GetOwner())
	if err != nil {
		return nil, err
	}
	fieldIDs, err := parseIDs(req.GetFieldIds())
	if err != nil {
		return nil, err
	}
	var out *engine.ReorderMetadataResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		wrote, err := writes.RunChanges(c, writes.Op{Action: "reorder_metadata", UserID: userID},
			func(tx *database.Tx) ([]rowchange.Change, error) {
				return sourcemetadata.Reorder(tx, userID, owner, fieldIDs)
			})
		if err != nil {
			return err
		}
		entries, err := ownerBoardProto(c, owner)
		if err != nil {
			return err
		}
		out = &engine.ReorderMetadataResponse{Effects: writeEffectsProto(wrote), Metadata: entries}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

// GetMetadataBoard reads one owner's board: its type's suggestions at its
// level plus extras, by its layout. A missing owner is sourcemetadata.invalid.
func GetMetadataBoard(in []byte) ([]byte, error) {
	var req engine.GetMetadataBoardRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("get_metadata_board", err)
	}
	owner, err := parseOwner(req.GetOwner())
	if err != nil {
		return nil, err
	}
	var out *engine.GetMetadataBoardResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		entries, err := ownerBoardProto(c, owner)
		if err != nil {
			return err
		}
		out = &engine.GetMetadataBoardResponse{Board: &engine.MetadataBoard{
			OwnerId: database.UUIDString(owner.ID),
			Entries: entries,
		}}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

// GetDraftMetadataBoard reads the board a new Artifact or graph starts with on a
// Source: the type's suggestions at the level, empty, then the fields its
// citation formats head, each with its requirement. A Source that does not
// exist, or a level other than artifact or graph, is sourcemetadata.invalid.
func GetDraftMetadataBoard(in []byte) ([]byte, error) {
	var req engine.GetDraftMetadataBoardRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("get_draft_metadata_board", err)
	}
	sourceID, err := parseID(req.GetSourceId())
	if err != nil {
		return nil, err
	}
	var out *engine.GetDraftMetadataBoardResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		entries, err := sourcemetadata.ListDraftWorkspace(c, sourceID, vocabkey.Level(req.GetLevel()))
		if err != nil {
			return err
		}
		out = &engine.GetDraftMetadataBoardResponse{Entries: metadataEntriesProto(entries)}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

// ownerBoardProto is the owner's board in display order: ListWorkspace as wire
// entries. A missing owner is sourcemetadata.ErrInvalid.
func ownerBoardProto(c *database.Catalog, owner sourcemetadata.Owner) ([]*engine.MetadataWorkspaceEntry, error) {
	entries, err := sourcemetadata.ListWorkspace(c, owner)
	if err != nil {
		return nil, err
	}
	return metadataEntriesProto(entries), nil
}

// metadataEntriesProto is metadataEntryProto for a whole board, nil when empty.
func metadataEntriesProto(entries []sourcemetadata.WorkspaceEntry) []*engine.MetadataWorkspaceEntry {
	var out []*engine.MetadataWorkspaceEntry
	for _, e := range entries {
		out = append(out, metadataEntryProto(e))
	}
	return out
}

func metadataEntryProto(e sourcemetadata.WorkspaceEntry) *engine.MetadataWorkspaceEntry {
	out := &engine.MetadataWorkspaceEntry{
		Field:       metadataFieldProto(e.Field),
		Suggested:   e.Suggested,
		SortOrder:   int32(e.SortOrder),
		OpenHref:    e.OpenHref(),
		Requirement: requirementProto(e.Annotation),
	}
	if e.Value != nil {
		out.HasValue = true
		out.ValueText = e.Value.ValueText
		out.Mark = valueMarkProto(e.Value.Mark)
	}
	return out
}

// requirementProto is what the formats ask of a head as a wire requirement, nil
// when they do not read it.
func requirementProto(a sourcemetadata.Annotation) *engine.CitationRequirement {
	var need engine.CitationNeed
	switch a.Need {
	case citationformat.NeedNeeded:
		need = engine.CitationNeed_CITATION_NEED_NEEDED
	case citationformat.NeedUsed:
		need = engine.CitationNeed_CITATION_NEED_USED
	default:
		return nil
	}
	out := &engine.CitationRequirement{Need: need, MetElsewhere: a.MetElsewhere}
	for _, alt := range a.Alternatives {
		out.Alternatives = append(out.Alternatives, citationOptionProto(alt))
	}
	return out
}

// citationOptionProto is one option of a chain on the wire.
func citationOptionProto(alt sourcemetadata.Alternative) *engine.CitationRequirementOption {
	opt := &engine.CitationRequirementOption{Level: string(alt.Level), Builtin: alt.Builtin}
	if alt.Field != nil {
		opt.Field = metadataFieldProto(*alt.Field)
	}
	return opt
}
