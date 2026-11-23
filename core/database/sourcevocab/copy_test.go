package sourcevocab

import (
	"bytes"
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
// description, all three formats and three suggested fields, and a
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
	// Parish, Line, Enumerator (stored order is not label order).
	for _, i := range []int{1, 0, 2} {
		if err := AppendSuggestion(c, f.census, f.fieldIDs[i]); err != nil {
			t.Fatal(err)
		}
	}
	_, err = sourcetypestest.SetFormats(c, f.userID, f.census, sourcetypes.Formats{
		Full: "{source.title} {meta.line}", Short: "{source.title}", List: "{meta.parish}",
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
	return storedFormats(t, f.c, typeID)
}

func (f *copyFixture) ids(t *testing.T, typeID []byte) [][]byte {
	t.Helper()
	sugs, err := ListSuggestions(f.c, typeID)
	if err != nil {
		t.Fatal(err)
	}
	var out [][]byte
	for _, s := range sugs {
		out = append(out, s.Field.ID)
	}
	return out
}

func (f *copyFixture) orders(t *testing.T, typeID []byte) []int {
	t.Helper()
	sugs, err := ListSuggestions(f.c, typeID)
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
	all := CopyTypeInput{Icon: true, Description: true, Formats: true, Suggestions: true}
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
				if want, have := f.ids(t, f.census), f.ids(t, got.ID); !sameIDs(want, have) || len(have) == 0 {
					t.Fatalf("%x vs %x", have, want)
				}
				if want, have := f.orders(t, f.census), f.orders(t, got.ID); !slices.Equal(want, have) {
					t.Fatalf("sort orders %v vs %v", have, want)
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
			name: "suggestions left out are not copied",
			run: func(t *testing.T, f *copyFixture) {
				in := all
				in.TypeID, in.Label = f.census, "State census"
				in.Suggestions = false
				got, _, err := f.copyType(in)
				if err != nil {
					t.Fatal(err)
				}
				if n := len(f.ids(t, got.ID)); n != 0 {
					t.Fatalf("rows %d", n)
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
				if n := len(f.ids(t, got.ID)); n != 0 {
					t.Fatalf("rows %d", n)
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
			name: "an original with no suggestions copies none",
			run: func(t *testing.T, f *copyFixture) {
				got, _, err := f.copyType(CopyTypeInput{TypeID: f.plugin, Label: "Memorial copy", Suggestions: true})
				if err != nil {
					t.Fatal(err)
				}
				if n := len(f.ids(t, got.ID)); n != 0 {
					t.Fatalf("rows %d", n)
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
				if err := DeleteSuggestion(f.c, got.ID, f.fieldIDs[0]); err != nil {
					t.Fatal(err)
				}
				if n := len(f.ids(t, f.census)); n != 3 {
					t.Fatalf("original has %d", n)
				}
				if n := len(f.ids(t, got.ID)); n != 2 {
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
