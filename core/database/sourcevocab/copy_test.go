package sourcevocab

import (
	"bytes"
	"database/sql"
	"errors"
	"slices"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/catalogmodel"
	"github.com/Jake-Robins-Studios/provenencia/core/database/dbtest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/deleteimpact"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes/sourcetypestest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/users"
	"github.com/Jake-Robins-Studios/provenencia/core/ref"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
)

// copyFixture is a catalog with a Provenencia census type that has an icon, a
// description, all three formats and suggestions at all three levels, and a
// bare plugin type.
type copyFixture struct {
	c        *database.Catalog
	userID   []byte
	census   []byte
	plugin   []byte
	fieldIDs [][]byte
}

func newCopyFixture(t *testing.T) *copyFixture {
	t.Helper()
	c, err := database.Create(t.TempDir(), "t.provenencia")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = c.Close() })
	f := &copyFixture{c: c, userID: []byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}}
	r, err := ref.Mint(ref.PrefixUser)
	if err != nil {
		t.Fatal(err)
	}
	if err := users.Upsert(c, f.userID, "Tester", r); err != nil {
		t.Fatal(err)
	}
	f.census, err = sourcetypestest.Upsert(c, sourcetypes.Type{
		Key: "census", Origin: vocabkey.OriginProvenencia, Label: "Census",
		Description: "A head count", IconKey: "type_scroll",
	})
	if err != nil {
		t.Fatal(err)
	}
	f.plugin, err = sourcetypestest.Upsert(c, sourcetypes.Type{
		Key: "memorial", Origin: "plugin:findagrave", Label: "Grave memorial", IconKey: "type_book",
	})
	if err != nil {
		t.Fatal(err)
	}
	for _, label := range []string{"Line", "Parish", "Enumerator"} {
		field, err := runFieldCreate(c, label, metadatafields.DataTypeText, "")
		if err != nil {
			t.Fatal(err)
		}
		f.fieldIDs = append(f.fieldIDs, field.ID)
	}
	// Source: Parish, Line, Enumerator (stored order is not label order).
	// Artifact: Line. Graph: Enumerator, Parish.
	for _, s := range []struct {
		level  vocabkey.Level
		fields []int
	}{
		{vocabkey.LevelSource, []int{1, 0, 2}},
		{vocabkey.LevelArtifact, []int{0}},
		{vocabkey.LevelGraph, []int{2, 1}},
	} {
		for _, i := range s.fields {
			if err := AppendSuggestion(c, f.census, f.fieldIDs[i], s.level); err != nil {
				t.Fatal(err)
			}
		}
	}
	_, _, err = writes.Run(c, writes.Op{Action: "update_citation_formats", UserID: f.userID},
		func(tx *database.Tx) (sourcetypes.FormatsView, []rowchange.Change, error) {
			return sourcetypes.UpdateFormats(tx, f.census, sourcetypes.Formats{
				Full: "{source.title} {source.meta.line}", Short: "{source.title}", List: "{source.meta.parish}",
			}, nil)
		})
	if err != nil {
		t.Fatal(err)
	}
	return f
}

func (f *copyFixture) copyType(in CopyTypeInput) (sourcetypes.Type, []rowchange.Change, error) {
	var changes []rowchange.Change
	got, _, err := writes.Run(f.c, writes.Op{Action: "copy_source_type", UserID: f.userID},
		func(tx *database.Tx) (sourcetypes.Type, []rowchange.Change, error) {
			typ, ch, err := CopyType(tx, in)
			changes = ch
			return typ, ch, err
		})
	return got, changes, err
}

func (f *copyFixture) formats(t *testing.T, typeID []byte) sourcetypes.Formats {
	t.Helper()
	tx, err := dbtest.MustDB(t, f.c).Begin()
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = tx.Rollback() }()
	got, err := sourcetypes.StoredFormatsTx(tx, [][]byte{typeID})
	if err != nil {
		t.Fatal(err)
	}
	return got[string(typeID)]
}

func (f *copyFixture) ids(t *testing.T, typeID []byte, level vocabkey.Level) [][]byte {
	t.Helper()
	sugs, err := ListSuggestions(f.c, typeID, level)
	if err != nil {
		t.Fatal(err)
	}
	var out [][]byte
	for _, s := range sugs {
		out = append(out, s.Field.ID)
	}
	return out
}

func (f *copyFixture) orders(t *testing.T, typeID []byte, level vocabkey.Level) []int {
	t.Helper()
	sugs, err := ListSuggestions(f.c, typeID, level)
	if err != nil {
		t.Fatal(err)
	}
	var out []int
	for _, s := range sugs {
		out = append(out, s.SortOrder)
	}
	return out
}

func sameIDs(a, b [][]byte) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if !bytes.Equal(a[i], b[i]) {
			return false
		}
	}
	return true
}

func TestCopyType(t *testing.T) {
	all := CopyTypeInput{Icon: true, Description: true, Formats: true, Levels: vocabkey.MetadataLevels()}
	tests := []struct {
		name string
		run  func(t *testing.T, f *copyFixture)
	}{
		{
			name: "every part is copied as stored, in order, with one create change",
			run: func(t *testing.T, f *copyFixture) {
				in := all
				in.TypeID, in.Label = f.census, "State census"
				got, changes, err := f.copyType(in)
				if err != nil {
					t.Fatal(err)
				}
				if got.Key != "state-census" || got.Origin != vocabkey.OriginUser || got.IconKey != "type_scroll" ||
					got.Description != "A head count" {
					t.Fatalf("got %+v", got)
				}
				if f.formats(t, got.ID) != f.formats(t, f.census) || f.formats(t, got.ID).Full == "" {
					t.Fatalf("formats %+v vs %+v", f.formats(t, got.ID), f.formats(t, f.census))
				}
				for _, level := range vocabkey.MetadataLevels() {
					if want, have := f.ids(t, f.census, level), f.ids(t, got.ID, level); !sameIDs(want, have) || len(have) == 0 {
						t.Fatalf("%s: %x vs %x", level, have, want)
					}
					if want, have := f.orders(t, f.census, level), f.orders(t, got.ID, level); !slices.Equal(want, have) {
						t.Fatalf("%s sort orders %v vs %v", level, have, want)
					}
				}
				if len(changes) != 1 || changes[0].Action != rowchange.ActionCreate || changes[0].EntityType != "source_type" {
					t.Fatalf("changes %+v", changes)
				}
				for _, col := range []string{"citation_full", "citation_short", "citation_list"} {
					if _, ok := changes[0].Fields[col]; !ok {
						t.Fatalf("no %s in %+v", col, changes[0].Fields)
					}
				}
			},
		},
		{
			name: "a level left out is not copied and the others are",
			run: func(t *testing.T, f *copyFixture) {
				in := all
				in.TypeID, in.Label = f.census, "State census"
				in.Levels = []vocabkey.Level{vocabkey.LevelSource, vocabkey.LevelGraph}
				got, _, err := f.copyType(in)
				if err != nil {
					t.Fatal(err)
				}
				if n := len(f.ids(t, got.ID, vocabkey.LevelArtifact)); n != 0 {
					t.Fatalf("artifact rows %d", n)
				}
				if len(f.ids(t, got.ID, vocabkey.LevelSource)) != 3 || len(f.ids(t, got.ID, vocabkey.LevelGraph)) != 2 {
					t.Fatal("source and graph rows not copied")
				}
			},
		},
		{
			name: "icon, description and formats left out give the defaults and no format fields",
			run: func(t *testing.T, f *copyFixture) {
				got, changes, err := f.copyType(CopyTypeInput{TypeID: f.census, Label: "State census"})
				if err != nil {
					t.Fatal(err)
				}
				if got.IconKey != sourcetypes.DefaultIconKey || got.Description != "" {
					t.Fatalf("got %+v", got)
				}
				if (f.formats(t, got.ID) != sourcetypes.Formats{}) {
					t.Fatalf("formats %+v", f.formats(t, got.ID))
				}
				for _, col := range []string{"citation_full", "citation_short", "citation_list", "description"} {
					if _, ok := changes[0].Fields[col]; ok {
						t.Fatalf("%s in %+v", col, changes[0].Fields)
					}
				}
				for _, level := range vocabkey.MetadataLevels() {
					if n := len(f.ids(t, got.ID, level)); n != 0 {
						t.Fatalf("%s rows %d", level, n)
					}
				}
			},
		},
		{
			name: "a plugin original gives an editable user copy",
			run: func(t *testing.T, f *copyFixture) {
				got, _, err := f.copyType(CopyTypeInput{TypeID: f.plugin, Label: "My memorial", Icon: true})
				if err != nil {
					t.Fatal(err)
				}
				if got.Origin != vocabkey.OriginUser || got.IconKey != "type_book" {
					t.Fatalf("got %+v", got)
				}
			},
		},
		{
			name: "a Provenencia key may be copied under user origin, once",
			run: func(t *testing.T, f *copyFixture) {
				if got, _, err := f.copyType(CopyTypeInput{TypeID: f.census, Label: "Census"}); err != nil || got.Key != "census" {
					t.Fatalf("got %+v %v", got, err)
				}
				_, _, err := f.copyType(CopyTypeInput{TypeID: f.census, Label: "Census"})
				if !errors.Is(err, sourcetypes.ErrDuplicateKey) {
					t.Fatalf("got %v", err)
				}
			},
		},
		{
			name: "an unknown original is sourcetypes.ErrInvalid",
			run: func(t *testing.T, f *copyFixture) {
				for _, id := range [][]byte{bytes.Repeat([]byte{9}, 16), {1, 2}} {
					_, _, err := f.copyType(CopyTypeInput{TypeID: id, Label: "X"})
					if !errors.Is(err, sourcetypes.ErrInvalid) {
						t.Fatalf("id %x: got %v", id, err)
					}
				}
			},
		},
		{
			name: "a level that holds no metadata or repeats is ErrInvalid and writes nothing",
			run: func(t *testing.T, f *copyFixture) {
				for _, levels := range [][]vocabkey.Level{
					{vocabkey.LevelCitation},
					{vocabkey.LevelGraph, vocabkey.LevelGraph},
					{"nonsense"},
				} {
					_, _, err := f.copyType(CopyTypeInput{TypeID: f.census, Label: "State census", Levels: levels})
					if !errors.Is(err, ErrInvalid) {
						t.Fatalf("levels %v: got %v", levels, err)
					}
				}
				if _, err := sourcetypes.Lookup(f.c, "state-census", vocabkey.OriginUser); !errors.Is(err, sql.ErrNoRows) {
					t.Fatalf("a type was written: %v", err)
				}
			},
		},
		{
			name: "a level with no rows copies none",
			run: func(t *testing.T, f *copyFixture) {
				got, _, err := f.copyType(CopyTypeInput{TypeID: f.plugin, Label: "Memorial copy", Levels: vocabkey.MetadataLevels()})
				if err != nil {
					t.Fatal(err)
				}
				for _, level := range vocabkey.MetadataLevels() {
					if n := len(f.ids(t, got.ID, level)); n != 0 {
						t.Fatalf("%s rows %d", level, n)
					}
				}
			},
		},
		{
			name: "removing a suggestion from the copy leaves the original's",
			run: func(t *testing.T, f *copyFixture) {
				in := all
				in.TypeID, in.Label = f.census, "State census"
				got, _, err := f.copyType(in)
				if err != nil {
					t.Fatal(err)
				}
				if err := DeleteSuggestion(f.c, got.ID, f.fieldIDs[0], vocabkey.LevelSource); err != nil {
					t.Fatal(err)
				}
				if n := len(f.ids(t, f.census, vocabkey.LevelSource)); n != 3 {
					t.Fatalf("original has %d", n)
				}
				if n := len(f.ids(t, got.ID, vocabkey.LevelSource)); n != 2 {
					t.Fatalf("copy has %d", n)
				}
			},
		},
		{
			name: "copied formats make the copy a second type naming the field",
			run: func(t *testing.T, f *copyFixture) {
				in := all
				in.TypeID, in.Label = f.census, "State census"
				if _, _, err := f.copyType(in); err != nil {
					t.Fatal(err)
				}
				tx, err := dbtest.MustDB(t, f.c).Begin()
				if err != nil {
					t.Fatal(err)
				}
				defer func() { _ = tx.Rollback() }()
				report, err := deleteimpact.Impact(tx, catalogmodel.KindMetadataField, f.fieldIDs[0])
				if err != nil {
					t.Fatal(err)
				}
				var total int
				for _, g := range report.Groups {
					if g.Via == deleteimpact.ViaCitationFormats {
						total = g.Total
					}
				}
				if total != 2 {
					t.Fatalf("report %+v", report)
				}
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tt.run(t, newCopyFixture(t))
		})
	}
}
