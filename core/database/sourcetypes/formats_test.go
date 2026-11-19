package sourcetypes

import (
	"bytes"
	"database/sql"
	"errors"
	"reflect"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/effects"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields/metadatafieldstest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/users"
	"github.com/Jake-Robins-Studios/provenencia/core/ref"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
	"github.com/google/uuid"
)

// formatFixture is a catalog with a user type, a plugin type, and fields: the
// product field line_number, and a product and a user field that share the key
// publisher.
type formatFixture struct {
	c           *database.Catalog
	userID      []byte
	typeID      []byte
	pluginID    []byte
	line        []byte
	pubProduct  []byte
	pubUser     []byte
	author      []byte
	typeIDOther []byte
}

func newFormatFixture(t *testing.T) *formatFixture {
	t.Helper()
	c, err := database.Create(t.TempDir(), "t.provenencia")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = c.Close() })
	f := &formatFixture{c: c, userID: []byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}}
	r, err := ref.Mint(ref.PrefixUser)
	if err != nil {
		t.Fatal(err)
	}
	if err := users.Upsert(c, f.userID, "Tester", r); err != nil {
		t.Fatal(err)
	}
	mustType := func(key, origin string) []byte {
		id, err := upsert(c, Type{Key: key, Origin: origin, Label: key})
		if err != nil {
			t.Fatal(err)
		}
		return id
	}
	mustField := func(key, origin string) []byte {
		id, err := metadatafieldstest.Upsert(c, metadatafields.Field{Key: key, Origin: origin, Label: key, DataType: metadatafields.DataTypeText})
		if err != nil {
			t.Fatal(err)
		}
		return id
	}
	f.typeID = mustType("census", vocabkey.OriginUser)
	f.typeIDOther = mustType("bible", vocabkey.OriginUser)
	f.pluginID = mustType("plugged", "plugin:test")
	f.line = mustField("line_number", vocabkey.OriginProvenencia)
	f.pubProduct = mustField("publisher", vocabkey.OriginProvenencia)
	f.pubUser = mustField("publisher", vocabkey.OriginUser)
	f.author = mustField("author", vocabkey.OriginProvenencia)
	return f
}

func (f *formatFixture) update(t *testing.T, typeID []byte, in Formats, choices ...FieldChoice) (FormatsView, writes.Result, error) {
	t.Helper()
	return writes.Run(f.c, writes.Op{Action: "update_citation_formats", UserID: f.userID},
		func(tx *database.Tx) (FormatsView, []rowchange.Change, error) {
			return UpdateFormats(tx, typeID, in, choices)
		})
}

func (f *formatFixture) raw(t *testing.T, column string, typeID []byte) sql.NullString {
	t.Helper()
	db, err := f.c.DB()
	if err != nil {
		t.Fatal(err)
	}
	var s sql.NullString
	if err := db.QueryRow(`SELECT `+column+` FROM source_types WHERE id = ?`, typeID).Scan(&s); err != nil {
		t.Fatal(err)
	}
	return s
}

func (f *formatFixture) setRaw(t *testing.T, column, text string, typeID []byte) {
	t.Helper()
	db, err := f.c.DB()
	if err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec(`UPDATE source_types SET `+column+` = ? WHERE id = ?`, text, typeID); err != nil {
		t.Fatal(err)
	}
}

func idToken(id []byte) string { return "#" + uuid.UUID(id).String() }

func diag(form citationformat.Form, code citationformat.DiagnosticCode, start, end int) citationformat.FormDiagnostic {
	return citationformat.FormDiagnostic{Form: form, Diagnostic: citationformat.Diagnostic{Code: code, Span: citationformat.Span{Start: start, End: end}}}
}

func TestUpdateFormats(t *testing.T) {
	const full = "{source.title}[, line {graph.meta.line_number}]"

	t.Run("saves fields by id and reads them by key (AC-1.1, AC-1.5)", func(t *testing.T) {
		f := newFormatFixture(t)
		view, res, err := f.update(t, f.typeID, Formats{Full: full})
		if err != nil {
			t.Fatal(err)
		}
		want := "{source.title}[, line {graph.meta." + idToken(f.line) + "}]"
		if got := f.raw(t, "citation_full", f.typeID); got.String != want {
			t.Fatalf("stored %q, want %q", got.String, want)
		}
		if view.Full != full || view.Short != "" || view.List != "" || len(view.Diagnostics) != 0 {
			t.Fatalf("view %+v", view)
		}
		if res.Revision == 0 || !reflect.DeepEqual(res.Effects.Lists, []effects.List{effects.ListSourceVocabulary}) {
			t.Fatalf("result %+v", res)
		}
		if f.raw(t, "citation_short", f.typeID).Valid || f.raw(t, "citation_list", f.typeID).Valid {
			t.Fatal("blank forms must be NULL")
		}
	})

	t.Run("blank clears to NULL (AC-1.3)", func(t *testing.T) {
		f := newFormatFixture(t)
		if _, _, err := f.update(t, f.typeID, Formats{Full: full, Short: "{source.title}"}); err != nil {
			t.Fatal(err)
		}
		view, _, err := f.update(t, f.typeID, Formats{Full: "", Short: "  \n"})
		if err != nil {
			t.Fatal(err)
		}
		if view.Full != "" || view.Short != "" {
			t.Fatalf("view %+v", view)
		}
		if f.raw(t, "citation_full", f.typeID).Valid || f.raw(t, "citation_short", f.typeID).Valid {
			t.Fatal("cleared forms must be NULL")
		}
	})

	t.Run("an unchanged write records nothing (AC-1.4)", func(t *testing.T) {
		f := newFormatFixture(t)
		view, _, err := f.update(t, f.typeID, Formats{Full: full, List: "{source.title}"})
		if err != nil {
			t.Fatal(err)
		}
		before := f.raw(t, "citation_full", f.typeID)
		view2, res, err := f.update(t, f.typeID, view.Formats, view.Choices...)
		if err != nil {
			t.Fatal(err)
		}
		if res.Revision != 0 || len(res.Effects.Lists) != 0 {
			t.Fatalf("result %+v", res)
		}
		if f.raw(t, "citation_full", f.typeID) != before || !reflect.DeepEqual(view, view2) {
			t.Fatalf("changed: %+v vs %+v", view, view2)
		}
	})

	t.Run("the audit change holds only the changed columns (AC-1.5)", func(t *testing.T) {
		f := newFormatFixture(t)
		if _, _, err := f.update(t, f.typeID, Formats{Full: "{source.title}", Short: "{source.title}"}); err != nil {
			t.Fatal(err)
		}
		tx, err := f.c.BeginWrite()
		if err != nil {
			t.Fatal(err)
		}
		defer f.c.EndWrite()
		defer func() { _ = tx.Rollback() }()
		_, changes, err := UpdateFormats(tx, f.typeID, Formats{Full: "{source.title}", Short: "{source.date}"}, nil)
		if err != nil {
			t.Fatal(err)
		}
		if len(changes) != 1 || changes[0].EntityType != "source_type" || changes[0].Action != rowchange.ActionUpdate {
			t.Fatalf("changes %+v", changes)
		}
		got := changes[0].Fields
		if len(got) != 1 || got["citation_short"].Old != "{source.title}" || got["citation_short"].New != "{source.date}" {
			t.Fatalf("fields %+v", got)
		}
	})

	diagCases := []struct {
		name string
		in   Formats
		pick []FieldChoice
		want []citationformat.FormDiagnostic
	}{
		{"unclosed placeholder (AC-2.1)", Formats{Full: "{source.title"},
			nil, []citationformat.FormDiagnostic{diag("full", citationformat.CodeUnclosedPlaceholder, 0, 1)}},
		{"list form refuses a non-Source level (AC-2.2)", Formats{List: "{artifact.label}"},
			nil, []citationformat.FormDiagnostic{diag("list", citationformat.CodeNotInListForm, 1, 15)}},
		{"unknown key (AC-2.3)", Formats{Short: "{source.meta.no_such_key}"},
			nil, []citationformat.FormDiagnostic{diag("short", citationformat.CodeUnknownField, 13, 24)}},
		{"shared key without a choice (AC-2.4)", Formats{Full: "{source.meta.publisher}"},
			nil, []citationformat.FormDiagnostic{diag("full", citationformat.CodeAmbiguousField, 13, 22)}},
		{"parse errors and unknown keys together (AC-2.6)", Formats{Full: "{source.title", Short: "{source.meta.nope}"},
			nil, []citationformat.FormDiagnostic{
				diag("full", citationformat.CodeUnclosedPlaceholder, 0, 1),
				diag("short", citationformat.CodeUnknownField, 13, 17),
			}},
		{"a typed id no field has (AC-2.9)", Formats{Full: "{source.meta.#0192f3a4-0000-7000-8000-000000000001}"},
			nil, []citationformat.FormDiagnostic{diag("full", citationformat.CodeUnknownField, 13, 50)}},
		{"every occurrence of a shared key", Formats{Full: "{source.meta.publisher} {graph.meta.publisher}"},
			nil, []citationformat.FormDiagnostic{
				diag("full", citationformat.CodeAmbiguousField, 13, 22),
				diag("full", citationformat.CodeAmbiguousField, 36, 45),
			}},
	}
	for _, tc := range diagCases {
		t.Run(tc.name, func(t *testing.T) {
			f := newFormatFixture(t)
			if _, _, err := f.update(t, f.typeID, Formats{Full: "{source.title}"}); err != nil {
				t.Fatal(err)
			}
			view, res, err := f.update(t, f.typeID, tc.in, tc.pick...)
			if err != nil {
				t.Fatal(err)
			}
			if !reflect.DeepEqual(view.Diagnostics, tc.want) {
				t.Fatalf("diagnostics %+v, want %+v", view.Diagnostics, tc.want)
			}
			if res.Revision != 0 || len(res.Effects.Lists) != 0 {
				t.Fatalf("a refused write recorded %+v", res)
			}
			if view.Full != "{source.title}" || view.Short != "" {
				t.Fatalf("view is not what the type stores: %+v", view)
			}
			if got := f.raw(t, "citation_full", f.typeID).String; got != "{source.title}" {
				t.Fatalf("stored %q", got)
			}
		})
	}

	t.Run("a choice settles a shared key (AC-2.5)", func(t *testing.T) {
		f := newFormatFixture(t)
		view, _, err := f.update(t, f.typeID, Formats{Full: "{source.meta.publisher}"},
			FieldChoice{Key: "publisher", FieldID: f.pubUser})
		if err != nil {
			t.Fatal(err)
		}
		if got := f.raw(t, "citation_full", f.typeID).String; got != "{source.meta."+idToken(f.pubUser)+"}" {
			t.Fatalf("stored %q", got)
		}
		wantChoices := []FieldChoice{{Key: "publisher", FieldID: f.pubUser}}
		if view.Full != "{source.meta.publisher}" || !reflect.DeepEqual(view.Choices, wantChoices) {
			t.Fatalf("view %+v", view)
		}
	})

	t.Run("a bad choice is invalid and saves nothing (AC-2.7)", func(t *testing.T) {
		f := newFormatFixture(t)
		for name, choices := range map[string][]FieldChoice{
			"another key's id": {{Key: "publisher", FieldID: f.author}},
			"no such field":    {{Key: "publisher", FieldID: make([]byte, 16)}},
			"empty key":        {{Key: "", FieldID: f.pubUser}},
			"short id":         {{Key: "publisher", FieldID: []byte{1}}},
			"two for one key": {
				{Key: "publisher", FieldID: f.pubUser}, {Key: "publisher", FieldID: f.pubProduct}},
		} {
			_, res, err := f.update(t, f.typeID, Formats{Full: "{source.title}"}, choices...)
			if !errors.Is(err, ErrInvalid) || res.Revision != 0 {
				t.Fatalf("%s: err %v, result %+v", name, err, res)
			}
		}
		if f.raw(t, "citation_full", f.typeID).Valid {
			t.Fatal("something saved")
		}
	})

	t.Run("a choice for a sole holder is accepted, one for an unused key ignored", func(t *testing.T) {
		f := newFormatFixture(t)
		_, _, err := f.update(t, f.typeID, Formats{Full: "{source.meta.author}"},
			FieldChoice{Key: "author", FieldID: f.author}, FieldChoice{Key: "publisher", FieldID: f.pubUser})
		if err != nil {
			t.Fatal(err)
		}
		if got := f.raw(t, "citation_full", f.typeID).String; got != "{source.meta."+idToken(f.author)+"}" {
			t.Fatalf("stored %q", got)
		}
	})

	t.Run("a plugin or missing type is refused (AC-2.8)", func(t *testing.T) {
		f := newFormatFixture(t)
		if _, _, err := f.update(t, f.pluginID, Formats{Full: "{source.title}"}); !errors.Is(err, ErrLocked) {
			t.Fatalf("plugin: %v", err)
		}
		if _, _, err := f.update(t, []byte{1}, Formats{}); !errors.Is(err, ErrInvalid) {
			t.Fatalf("bad id: %v", err)
		}
		missing := uuid.New()
		if _, _, err := f.update(t, missing[:], Formats{Full: "{source.title}"}); !errors.Is(err, ErrInvalid) {
			t.Fatalf("missing: %v", err)
		}
	})

	t.Run("a key and an id of one field store one token", func(t *testing.T) {
		f := newFormatFixture(t)
		_, _, err := f.update(t, f.typeID, Formats{Full: "{source.meta.line_number} {graph.meta." + idToken(f.line) + "}"})
		if err != nil {
			t.Fatal(err)
		}
		want := "{source.meta." + idToken(f.line) + "} {graph.meta." + idToken(f.line) + "}"
		if got := f.raw(t, "citation_full", f.typeID).String; got != want {
			t.Fatalf("stored %q, want %q", got, want)
		}
	})

	t.Run("ToStored prefers an origin when told to", func(t *testing.T) {
		f := newFormatFixture(t)
		db, err := f.c.DB()
		if err != nil {
			t.Fatal(err)
		}
		tx, err := db.Begin()
		if err != nil {
			t.Fatal(err)
		}
		defer func() { _ = tx.Rollback() }()
		got, diags, err := ToStored(tx, Formats{Full: "{source.meta.publisher}"}, nil, vocabkey.OriginProvenencia)
		if err != nil || len(diags) != 0 {
			t.Fatalf("err %v, diagnostics %+v", err, diags)
		}
		if want := "{source.meta." + idToken(f.pubProduct) + "}"; got.Full != want {
			t.Fatalf("stored %q, want %q", got.Full, want)
		}
	})
}

func TestGetFormats(t *testing.T) {
	t.Run("keys survive a relabel (AC-1.2)", func(t *testing.T) {
		f := newFormatFixture(t)
		if _, _, err := f.update(t, f.typeID, Formats{Full: "{graph.meta.line_number}"}); err != nil {
			t.Fatal(err)
		}
		_, _, err := writes.Run(f.c, writes.Op{Action: "update_metadata_field", UserID: f.userID},
			func(tx *database.Tx) (metadatafields.Field, []rowchange.Change, error) {
				return metadatafields.Update(tx, f.line, "Line no.", metadatafields.DataTypeText, "", nil)
			})
		if err != nil {
			t.Fatal(err)
		}
		view, err := GetFormats(f.c, f.typeID)
		if err != nil {
			t.Fatal(err)
		}
		if view.Full != "{graph.meta.line_number}" {
			t.Fatalf("full %q", view.Full)
		}
	})

	t.Run("no format reads as three empty forms", func(t *testing.T) {
		f := newFormatFixture(t)
		view, err := GetFormats(f.c, f.typeID)
		if err != nil || !reflect.DeepEqual(view, FormatsView{}) {
			t.Fatalf("view %+v, err %v", view, err)
		}
	})

	t.Run("a missing type is invalid", func(t *testing.T) {
		f := newFormatFixture(t)
		missing := uuid.New()
		if _, err := GetFormats(f.c, missing[:]); !errors.Is(err, ErrInvalid) {
			t.Fatalf("err %v", err)
		}
	})

	t.Run("stored text that does not parse comes back verbatim (AC-4.1)", func(t *testing.T) {
		f := newFormatFixture(t)
		f.setRaw(t, "citation_full", "{source.title", f.typeID)
		view, err := GetFormats(f.c, f.typeID)
		if err != nil {
			t.Fatal(err)
		}
		want := []citationformat.FormDiagnostic{diag("full", citationformat.CodeUnclosedPlaceholder, 0, 1)}
		if view.Full != "{source.title" || !reflect.DeepEqual(view.Diagnostics, want) {
			t.Fatalf("view %+v", view)
		}
	})

	t.Run("an id with no field stays an id token (AC-4.2)", func(t *testing.T) {
		f := newFormatFixture(t)
		x := uuid.New()
		text := "{source.meta.#" + x.String() + "}"
		f.setRaw(t, "citation_full", text, f.typeID)
		view, err := GetFormats(f.c, f.typeID)
		if err != nil {
			t.Fatal(err)
		}
		if view.Full != text || len(view.Diagnostics) != 0 {
			t.Fatalf("view %+v", view)
		}
		// The write accepts that token only when a field has it: resaving
		// reports the mistake, saves nothing and leaves the text as stored.
		saved, res, err := f.update(t, f.typeID, view.Formats)
		if err != nil {
			t.Fatal(err)
		}
		wantDiags := []citationformat.FormDiagnostic{diag("full", citationformat.CodeUnknownField, 13, 50)}
		if !reflect.DeepEqual(saved.Diagnostics, wantDiags) || res.Revision != 0 {
			t.Fatalf("resave: view %+v, result %+v", saved, res)
		}
		if got := f.raw(t, "citation_full", f.typeID).String; got != text {
			t.Fatalf("stored %q", got)
		}
	})

	t.Run("two fields sharing a key: the first shown takes it (AC-4.3)", func(t *testing.T) {
		f := newFormatFixture(t)
		f.setRaw(t, "citation_full", "{source.meta."+idToken(f.pubProduct)+"}", f.typeID)
		f.setRaw(t, "citation_short", "{source.meta."+idToken(f.pubUser)+"}", f.typeID)
		view, err := GetFormats(f.c, f.typeID)
		if err != nil {
			t.Fatal(err)
		}
		wantShort := "{source.meta." + idToken(f.pubUser) + "}"
		wantChoices := []FieldChoice{{Key: "publisher", FieldID: f.pubProduct}}
		if view.Full != "{source.meta.publisher}" || view.Short != wantShort || !reflect.DeepEqual(view.Choices, wantChoices) {
			t.Fatalf("view %+v", view)
		}
		_, res, err := f.update(t, f.typeID, view.Formats, view.Choices...)
		if err != nil {
			t.Fatal(err)
		}
		if res.Revision != 0 {
			t.Fatalf("resave changed the type: %+v", res)
		}
		if got := f.raw(t, "citation_full", f.typeID).String; got != "{source.meta."+idToken(f.pubProduct)+"}" {
			t.Fatalf("stored %q", got)
		}
		if got := f.raw(t, "citation_short", f.typeID).String; got != wantShort {
			t.Fatalf("stored %q", got)
		}
	})

	t.Run("StoredFormatsTx reads many types and leaves an unknown id out", func(t *testing.T) {
		f := newFormatFixture(t)
		f.setRaw(t, "citation_list", "{source.title}", f.typeID)
		f.setRaw(t, "citation_full", "{source.date}", f.typeIDOther)
		db, err := f.c.DB()
		if err != nil {
			t.Fatal(err)
		}
		tx, err := db.Begin()
		if err != nil {
			t.Fatal(err)
		}
		defer func() { _ = tx.Rollback() }()
		missing := uuid.New()
		got, err := StoredFormatsTx(tx, [][]byte{f.typeID, f.typeIDOther, missing[:], f.typeID})
		if err != nil {
			t.Fatal(err)
		}
		if len(got) != 2 || got[string(f.typeID)].List != "{source.title}" || got[string(f.typeIDOther)].Full != "{source.date}" {
			t.Fatalf("got %+v", got)
		}
		if bytes.Equal(f.typeID, f.typeIDOther) {
			t.Fatal("fixture ids collide")
		}
	})
}
