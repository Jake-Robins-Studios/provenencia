package handlers

import (
	"github.com/Jake-Robins-Studios/provenencia/api/proto/engine"
	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/catalogmodel"
	"github.com/Jake-Robins-Studios/provenencia/core/database/deleteimpact"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcevocab"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
	"google.golang.org/protobuf/proto"
)

func ListSourceTypes(in []byte) ([]byte, error) {
	var req engine.ListSourceTypesRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("list_source_types", err)
	}
	var out *engine.ListSourceTypesResponse
	err := withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		rows, err := sourcetypes.List(c)
		if err != nil {
			return err
		}
		out = &engine.ListSourceTypesResponse{}
		for _, t := range rows {
			out.Types = append(out.Types, sourceTypeProto(t))
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

func CreateSourceType(in []byte) ([]byte, error) {
	var req engine.CreateSourceTypeRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("create_source_type", err)
	}
	if _, err := parseUserID(req.GetUserId()); err != nil {
		return nil, err
	}
	var out *engine.CreateSourceTypeResponse
	err := withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		got, wrote, err := writes.Run(c, writes.Op{Action: "create_source_type"},
			func(tx *database.Tx) (sourcetypes.Type, []rowchange.Change, error) {
				return sourcetypes.Create(tx, sourcetypes.CreateInput{
					Label: req.GetLabel(), Description: req.GetDescription(), IconKey: req.GetIconKey(),
				})
			})
		if err != nil {
			return err
		}
		out = &engine.CreateSourceTypeResponse{Type: sourceTypeProto(got), Effects: writeEffectsProto(wrote)}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

func UpdateSourceType(in []byte) ([]byte, error) {
	var req engine.UpdateSourceTypeRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("update_source_type", err)
	}
	if _, err := parseUserID(req.GetUserId()); err != nil {
		return nil, err
	}
	typeID, err := parseID(req.GetTypeId())
	if err != nil {
		return nil, err
	}
	var out *engine.UpdateSourceTypeResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		got, wrote, err := writes.Run(c, writes.Op{Action: "update_source_type"},
			func(tx *database.Tx) (sourcetypes.Type, []rowchange.Change, error) {
				return sourcetypes.Update(tx, typeID, req.GetLabel(), req.GetDescription(), req.GetIconKey())
			})
		if err != nil {
			return err
		}
		if got.UsedBy, err = deleteimpact.UsedBy(c, catalogmodel.KindSourceType, typeID); err != nil {
			return err
		}
		if got.SuggestedFields, err = sourcetypes.SuggestedFields(c, typeID); err != nil {
			return err
		}
		out = &engine.UpdateSourceTypeResponse{Type: sourceTypeProto(got), Effects: writeEffectsProto(wrote)}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

// CopySourceType starts a new user type from an existing one with the parts the
// request ticks, in one write.
func CopySourceType(in []byte) ([]byte, error) {
	var req engine.CopySourceTypeRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("copy_source_type", err)
	}
	userID, err := parseUserID(req.GetUserId())
	if err != nil {
		return nil, err
	}
	typeID, err := parseID(req.GetTypeId())
	if err != nil {
		return nil, err
	}
	levels := make([]vocabkey.Level, len(req.GetLevels()))
	for i, level := range req.GetLevels() {
		levels[i] = vocabkey.Level(level)
	}
	var out *engine.CopySourceTypeResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		got, wrote, err := writes.Run(c, writes.Op{Action: "copy_source_type", UserID: userID},
			func(tx *database.Tx) (sourcetypes.Type, []rowchange.Change, error) {
				return sourcevocab.CopyType(tx, sourcevocab.CopyTypeInput{
					TypeID:      typeID,
					Label:       req.GetLabel(),
					Icon:        req.GetCopyIcon(),
					Description: req.GetCopyDescription(),
					Formats:     req.GetCopyFormats(),
					Levels:      levels,
				})
			})
		if err != nil {
			return err
		}
		if got.SuggestedFields, err = sourcetypes.SuggestedFields(c, got.ID); err != nil {
			return err
		}
		out = &engine.CopySourceTypeResponse{Type: sourceTypeProto(got), Effects: writeEffectsProto(wrote)}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

// GetCitationFormats returns a type's citation formats with fields by key. A
// stored text that does not parse comes back as stored, with its diagnostics.
func GetCitationFormats(in []byte) ([]byte, error) {
	var req engine.GetCitationFormatsRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("get_citation_formats", err)
	}
	typeID, err := parseID(req.GetTypeId())
	if err != nil {
		return nil, err
	}
	var out *engine.GetCitationFormatsResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		view, err := sourcetypes.GetFormats(c, typeID)
		if err != nil {
			return err
		}
		out = &engine.GetCitationFormatsResponse{
			Formats:     citationFormatsProto(typeID, view),
			Diagnostics: citationFormatDiagnosticsProto(view.Diagnostics),
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

// UpdateCitationFormats replaces a type's three citation formats. A format the
// engine cannot store comes back as diagnostics with nothing saved.
func UpdateCitationFormats(in []byte) ([]byte, error) {
	var req engine.UpdateCitationFormatsRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("update_citation_formats", err)
	}
	if _, err := parseUserID(req.GetUserId()); err != nil {
		return nil, err
	}
	typeID, err := parseID(req.GetTypeId())
	if err != nil {
		return nil, err
	}
	choices, err := fieldChoicesFromProto(req.GetFieldChoices())
	if err != nil {
		return nil, err
	}
	formats := sourcetypes.Formats{Full: req.GetFull(), Short: req.GetShort(), List: req.GetList()}
	var out *engine.UpdateCitationFormatsResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		view, wrote, err := writes.Run(c, writes.Op{Action: "update_citation_formats"},
			func(tx *database.Tx) (sourcetypes.FormatsView, []rowchange.Change, error) {
				return sourcetypes.UpdateFormats(tx, typeID, formats, choices)
			})
		if err != nil {
			return err
		}
		out = &engine.UpdateCitationFormatsResponse{
			Formats:     citationFormatsProto(typeID, view),
			Diagnostics: citationFormatDiagnosticsProto(view.Diagnostics),
			Effects:     writeEffectsProto(wrote),
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

// fieldChoicesFromProto reads the field each shared key means; an id that is
// not a UUIDv7 is sourcetypes.ErrInvalid.
func fieldChoicesFromProto(in []*engine.CitationFieldChoice) ([]sourcetypes.FieldChoice, error) {
	choices := make([]sourcetypes.FieldChoice, 0, len(in))
	for _, ch := range in {
		fieldID, err := parseID(ch.GetFieldId())
		if err != nil {
			return nil, sourcetypes.ErrInvalid
		}
		choices = append(choices, sourcetypes.FieldChoice{Key: ch.GetKey(), FieldID: fieldID})
	}
	return choices, nil
}

// citationFormatsProto is a type's formats view on the wire: the three texts
// by key, the field each shared key means, and the diagnostics.
func citationFormatsProto(typeID []byte, v sourcetypes.FormatsView) *engine.CitationFormats {
	out := &engine.CitationFormats{
		TypeId: database.UUIDString(typeID),
		Full:   v.Full,
		Short:  v.Short,
		List:   v.List,
	}
	for _, ch := range v.Choices {
		out.FieldChoices = append(out.FieldChoices, &engine.CitationFieldChoice{
			Key: ch.Key, FieldId: database.UUIDString(ch.FieldID),
		})
	}
	return out
}

// citationFormatDiagnosticsProto converts the mistakes in a format's forms;
// spans are UTF-8 byte offsets in the form's text.
func citationFormatDiagnosticsProto(ds []citationformat.FormDiagnostic) []*engine.CitationFormatDiagnostic {
	var out []*engine.CitationFormatDiagnostic
	for _, d := range ds {
		out = append(out, &engine.CitationFormatDiagnostic{
			Form: string(d.Form), Code: string(d.Code), Start: int32(d.Span.Start), End: int32(d.Span.End),
		})
	}
	return out
}

func ListTypeSuggestions(in []byte) ([]byte, error) {
	var req engine.ListTypeSuggestionsRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("list_type_suggestions", err)
	}
	typeID, err := parseID(req.GetTypeId())
	if err != nil {
		return nil, err
	}
	var out *engine.ListTypeSuggestionsResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		suggestions, err := suggestionsProto(c, typeID, vocabkey.Level(req.GetLevel()))
		if err != nil {
			return err
		}
		out = &engine.ListTypeSuggestionsResponse{Suggestions: suggestions}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

func AssignTypeField(in []byte) ([]byte, error) {
	var req engine.AssignTypeFieldRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("assign_type_field", err)
	}
	typeID, fieldID, err := parseSuggestionJoin(req.GetTypeId(), req.GetFieldId())
	if err != nil {
		return nil, err
	}
	var out *engine.AssignTypeFieldResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		level := vocabkey.Level(req.GetLevel())
		if err := sourcevocab.AppendSuggestion(c, typeID, fieldID, level); err != nil {
			return err
		}
		suggestions, err := suggestionsProto(c, typeID, level)
		if err != nil {
			return err
		}
		count, err := sourcetypes.SuggestedFields(c, typeID)
		if err != nil {
			return err
		}
		out = &engine.AssignTypeFieldResponse{Suggestions: suggestions, SuggestedFieldCount: int32(count)}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

func RemoveTypeField(in []byte) ([]byte, error) {
	var req engine.RemoveTypeFieldRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("remove_type_field", err)
	}
	typeID, fieldID, err := parseSuggestionJoin(req.GetTypeId(), req.GetFieldId())
	if err != nil {
		return nil, err
	}
	var out *engine.RemoveTypeFieldResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		level := vocabkey.Level(req.GetLevel())
		if err := sourcevocab.DeleteSuggestion(c, typeID, fieldID, level); err != nil {
			return err
		}
		suggestions, err := suggestionsProto(c, typeID, level)
		if err != nil {
			return err
		}
		count, err := sourcetypes.SuggestedFields(c, typeID)
		if err != nil {
			return err
		}
		out = &engine.RemoveTypeFieldResponse{Suggestions: suggestions, SuggestedFieldCount: int32(count)}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

// parseSuggestionJoin validates both join sides — the shared preamble of
// assign and remove. The join is not audited, so it takes no user.
func parseSuggestionJoin(typeID, fieldID string) ([]byte, []byte, error) {
	tid, err := parseID(typeID)
	if err != nil {
		return nil, nil, err
	}
	fid, err := parseID(fieldID)
	if err != nil {
		return nil, nil, err
	}
	return tid, fid, nil
}

func suggestionsProto(c *database.Catalog, typeID []byte, level vocabkey.Level) ([]*engine.TypeSuggestion, error) {
	rows, err := sourcevocab.ListSuggestions(c, typeID, level)
	if err != nil {
		return nil, err
	}
	out := make([]*engine.TypeSuggestion, 0, len(rows))
	for _, s := range rows {
		out = append(out, &engine.TypeSuggestion{
			Field:     metadataFieldProto(s.Field),
			SortOrder: int32(s.SortOrder),
		})
	}
	return out, nil
}

func ListMetadataFields(in []byte) ([]byte, error) {
	var req engine.ListMetadataFieldsRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("list_metadata_fields", err)
	}
	var out *engine.ListMetadataFieldsResponse
	err := withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		rows, err := metadatafields.List(c)
		if err != nil {
			return err
		}
		out = &engine.ListMetadataFieldsResponse{}
		for _, f := range rows {
			out.Fields = append(out.Fields, metadataFieldProto(f))
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

func CreateMetadataField(in []byte) ([]byte, error) {
	var req engine.CreateMetadataFieldRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("create_metadata_field", err)
	}
	if _, err := parseUserID(req.GetUserId()); err != nil {
		return nil, err
	}
	var out *engine.CreateMetadataFieldResponse
	err := withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		got, wrote, err := writes.Run(c, writes.Op{Action: "create_metadata_field"},
			func(tx *database.Tx) (metadatafields.Field, []rowchange.Change, error) {
				return metadatafields.Create(tx, req.GetLabel(), req.GetDataType(), req.GetDescription())
			})
		if err != nil {
			return err
		}
		out = &engine.CreateMetadataFieldResponse{Field: metadataFieldProto(got), Effects: writeEffectsProto(wrote)}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

func UpdateMetadataField(in []byte) ([]byte, error) {
	var req engine.UpdateMetadataFieldRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("update_metadata_field", err)
	}
	if _, err := parseUserID(req.GetUserId()); err != nil {
		return nil, err
	}
	fieldID, err := parseID(req.GetFieldId())
	if err != nil {
		return nil, err
	}
	var out *engine.UpdateMetadataFieldResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		got, wrote, err := writes.Run(c, writes.Op{Action: "update_metadata_field"},
			func(tx *database.Tx) (metadatafields.Field, []rowchange.Change, error) {
				return metadatafields.Update(tx, fieldID, req.GetLabel(), req.GetDataType(), req.GetDescription(), req.UnknownText)
			})
		if err != nil {
			return err
		}
		if got.UsedBy, err = deleteimpact.UsedBy(c, catalogmodel.KindMetadataField, fieldID); err != nil {
			return err
		}
		out = &engine.UpdateMetadataFieldResponse{Field: metadataFieldProto(got), Effects: writeEffectsProto(wrote)}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

func DeleteSourceType(in []byte) ([]byte, error) {
	var req engine.DeleteSourceTypeRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("delete_source_type", err)
	}
	userID, err := parseUserID(req.GetUserId())
	if err != nil {
		return nil, err
	}
	typeID, err := parseID(req.GetTypeId())
	if err != nil {
		return nil, err
	}
	var out *engine.DeleteSourceTypeResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		_, wrote, err := writes.Run(c, writes.Op{Action: "delete_source_type", UserID: userID},
			func(tx *database.Tx) (struct{}, []rowchange.Change, error) {
				changes, err := sourcetypes.Delete(tx, userID, typeID)
				return struct{}{}, changes, err
			})
		if err != nil {
			return err
		}
		out = &engine.DeleteSourceTypeResponse{Effects: writeEffectsProto(wrote)}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

func DeleteMetadataField(in []byte) ([]byte, error) {
	var req engine.DeleteMetadataFieldRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("delete_metadata_field", err)
	}
	userID, err := parseUserID(req.GetUserId())
	if err != nil {
		return nil, err
	}
	fieldID, err := parseID(req.GetFieldId())
	if err != nil {
		return nil, err
	}
	var out *engine.DeleteMetadataFieldResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		_, wrote, err := writes.Run(c, writes.Op{Action: "delete_metadata_field", UserID: userID},
			func(tx *database.Tx) (struct{}, []rowchange.Change, error) {
				changes, err := metadatafields.Delete(tx, userID, fieldID)
				return struct{}{}, changes, err
			})
		if err != nil {
			return err
		}
		out = &engine.DeleteMetadataFieldResponse{Effects: writeEffectsProto(wrote)}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

func sourceTypeProto(t sourcetypes.Type) *engine.SourceType {
	return &engine.SourceType{
		Id:                  database.UUIDString(t.ID),
		Key:                 t.Key,
		Origin:              t.Origin,
		Label:               t.Label,
		Description:         t.Description,
		UsedBy:              int32(t.UsedBy),
		SuggestedFieldCount: int32(t.SuggestedFields),
		IconKey:             t.IconKey,
	}
}

func metadataFieldProto(f metadatafields.Field) *engine.MetadataField {
	return &engine.MetadataField{
		Id:          database.UUIDString(f.ID),
		Key:         f.Key,
		Origin:      f.Origin,
		Label:       f.Label,
		DataType:    f.DataType,
		Description: f.Description,
		UnknownText: f.UnknownText,
		UsedBy:      int32(f.UsedBy),
	}
}
