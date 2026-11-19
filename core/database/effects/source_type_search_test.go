package effects_test

import (
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/effects"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sources"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes/sourcetypestest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/users"
	"github.com/Jake-Robins-Studios/provenencia/core/ref"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
)

// TestSourceTypeSearchGates checks that a Source type's search documents are
// reprojected only for the columns they read: a citation format change moves
// the source vocabulary list and no search document, label and icon changes
// reach the type and its Sources, and a description change reaches the type.
func TestSourceTypeSearchGates(t *testing.T) {
	userID := []byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}
	c, err := database.Create(t.TempDir(), "t.provenencia")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = c.Close() })
	ur, err := ref.Mint(ref.PrefixUser)
	if err != nil {
		t.Fatal(err)
	}
	if err := users.Upsert(c, userID, "Tester", ur); err != nil {
		t.Fatal(err)
	}
	typeID, err := sourcetypestest.Upsert(c, sourcetypes.Type{Key: "census", Origin: vocabkey.OriginUser, Label: "Census"})
	if err != nil {
		t.Fatal(err)
	}
	var sourceIDs [][]byte
	for _, title := range []string{"One", "Two"} {
		s, _, err := writes.Run(c, writes.Op{Action: "create_source", UserID: userID},
			func(tx *database.Tx) (sources.Source, []rowchange.Change, error) {
				return sources.Create(tx, userID, sources.CreateInput{SourceTypeID: typeID, Title: title})
			})
		if err != nil {
			t.Fatal(err)
		}
		sourceIDs = append(sourceIDs, s.ID)
	}
	tx, err := c.BeginWrite()
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(c.EndWrite)
	t.Cleanup(func() { _ = tx.Rollback() })

	docs := func(set effects.Set, kind string) [][]byte {
		for _, s := range set.Search {
			if s.Kind == kind {
				return s.IDs
			}
		}
		return nil
	}
	resolve := func(changes []rowchange.Change) effects.Set {
		t.Helper()
		set, err := effects.Resolve(tx.Tx, changes)
		if err != nil {
			t.Fatal(err)
		}
		return set
	}

	_, changes, err := sourcetypes.UpdateFormats(tx, typeID, sourcetypes.Formats{Full: "{source.title}"}, nil)
	if err != nil {
		t.Fatal(err)
	}
	set := resolve(changes)
	if len(set.Search) != 0 || !set.Has(effects.ListSourceVocabulary) {
		t.Fatalf("a format change: search %+v, lists %v", set.Search, set.Lists)
	}

	for _, tc := range []struct {
		name        string
		label, desc string
		icon        string
		typeDoc     bool
		sourceDocs  bool
	}{
		{"label", "Census returns", "", "", true, true},
		{"icon", "Census returns", "", "type_book", true, true},
		{"description", "Census returns", "Decennial", "type_book", true, false},
	} {
		t.Run(tc.name, func(t *testing.T) {
			_, changes, err := sourcetypes.Update(tx, typeID, tc.label, tc.desc, tc.icon)
			if err != nil {
				t.Fatal(err)
			}
			set := resolve(changes)
			if got := len(docs(set, effects.DocSourceType)) > 0; got != tc.typeDoc {
				t.Fatalf("type doc reprojected = %v, want %v", got, tc.typeDoc)
			}
			got := docs(set, effects.DocSource)
			if tc.sourceDocs && (len(got) != len(sourceIDs) || !database.ContainsBlobID(got, sourceIDs[0]) || !database.ContainsBlobID(got, sourceIDs[1])) {
				t.Fatalf("source docs %x, want both Sources", got)
			}
			if !tc.sourceDocs && len(got) != 0 {
				t.Fatalf("source docs %x, want none", got)
			}
		})
	}

	t.Run("an upsert of only new formats reprojects no search document", func(t *testing.T) {
		_, changes, err := sourcetypes.UpsertTx(tx, sourcetypes.Type{
			Key: "census", Origin: vocabkey.OriginUser, Label: "Census returns", Description: "Decennial", IconKey: "type_book",
		}, &sourcetypes.Formats{Full: "{source.title}!"})
		if err != nil {
			t.Fatal(err)
		}
		if len(changes) != 1 || len(changes[0].Fields) != 1 {
			t.Fatalf("changes %+v, want one format change", changes)
		}
		if _, ok := changes[0].Fields["citation_full"]; !ok {
			t.Fatalf("fields %+v, want citation_full", changes[0].Fields)
		}
		set := resolve(changes)
		if len(set.Search) != 0 {
			t.Fatalf("search %+v, want none", set.Search)
		}
	})

	t.Run("an upsert label change reprojects the type and its Sources", func(t *testing.T) {
		_, changes, err := sourcetypes.UpsertTx(tx, sourcetypes.Type{
			Key: "census", Origin: vocabkey.OriginUser, Label: "Census schedule", Description: "Decennial", IconKey: "type_book",
		}, nil)
		if err != nil {
			t.Fatal(err)
		}
		if len(changes) != 1 || len(changes[0].Fields) != 1 || changes[0].Fields["label"].New != "Census schedule" {
			t.Fatalf("changes %+v, want one label change", changes)
		}
		set := resolve(changes)
		if len(docs(set, effects.DocSourceType)) != 1 {
			t.Fatalf("type docs %x", docs(set, effects.DocSourceType))
		}
		got := docs(set, effects.DocSource)
		if len(got) != len(sourceIDs) || !database.ContainsBlobID(got, sourceIDs[0]) || !database.ContainsBlobID(got, sourceIDs[1]) {
			t.Fatalf("source docs %x, want both Sources", got)
		}
	})
}
