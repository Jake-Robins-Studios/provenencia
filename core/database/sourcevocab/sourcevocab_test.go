package sourcevocab

import (
	"bytes"
	"database/sql"
	"errors"
	"fmt"
	"reflect"
	"slices"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/dbtest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields/metadatafieldstest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes/sourcetypestest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/users"
	"github.com/Jake-Robins-Studios/provenencia/core/ref"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
)

// install runs Install the way createCatalog does: one writes.Call, no user.
func install(c *database.Catalog) error {
	_, err := writes.RunChanges(c, writes.Op{Action: ActionInstall}, func(tx *database.Tx) ([]rowchange.Change, error) {
		return Install(tx)
	})
	return err
}

// storedFormats reads a type's formats as stored (fields by id). It opens and
// closes its own transaction, so call it with none held.
func storedFormats(t *testing.T, c *database.Catalog, typeID []byte) sourcetypes.Formats {
	t.Helper()
	tx, err := dbtest.MustDB(t, c).Begin()
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

func findSeedType(t *testing.T, key string) seedType {
	t.Helper()
	for _, st := range seedTypes {
		if st.Key == key {
			return st
		}
	}
	t.Fatalf("no seed type %s", key)
	return seedType{}
}

// catalogSnapshot is everything Install wrote that a second run must leave alone.
type catalogSnapshot struct {
	Types       map[string]string // key -> id, label, stored formats
	Fields      map[string]string // key -> id, label, unknown text
	Suggestions map[string][]string
}

func snapshot(t *testing.T, c *database.Catalog) catalogSnapshot {
	t.Helper()
	snap := catalogSnapshot{Types: map[string]string{}, Fields: map[string]string{}, Suggestions: map[string][]string{}}
	fields, err := metadatafields.List(c)
	if err != nil {
		t.Fatal(err)
	}
	for _, f := range fields {
		snap.Fields[f.Key] = string(f.ID) + "|" + f.Label + "|" + f.UnknownText
	}
	types, err := sourcetypes.List(c)
	if err != nil {
		t.Fatal(err)
	}
	for _, ty := range types {
		f := storedFormats(t, c, ty.ID)
		snap.Types[ty.Key] = string(ty.ID) + "|" + ty.Label + "|" + f.Full + "|" + f.Short + "|" + f.List
		sugs, err := ListSuggestions(c, ty.ID)
		if err != nil {
			t.Fatal(err)
		}
		for _, s := range sugs {
			snap.Suggestions[ty.Key] = append(snap.Suggestions[ty.Key], fmt.Sprintf("%s@%d", s.Field.Key, s.SortOrder))
		}
	}
	return snap
}

func TestInstall(t *testing.T) {
	tests := []struct {
		name string
		run  func(t *testing.T, c *database.Catalog)
	}{
		{
			name: "empty catalog gets the seed",
			run: func(t *testing.T, c *database.Catalog) {
				if err := install(c); err != nil {
					t.Fatal(err)
				}
				types, err := sourcetypes.List(c)
				if err != nil {
					t.Fatal(err)
				}
				fields, err := metadatafields.List(c)
				if err != nil {
					t.Fatal(err)
				}
				// The map's counts, asserted once; every other check reads the registry.
				if len(seedTypes) != 26 || len(seedFields) != 69 {
					t.Fatalf("registry holds %d types and %d fields, the map says 26 and 69", len(seedTypes), len(seedFields))
				}
				if len(types) != len(seedTypes) || len(fields) != len(seedFields) {
					t.Fatalf("types=%d fields=%d", len(types), len(fields))
				}
				byKey := map[string]metadatafields.Field{}
				byID := map[string]metadatafields.Field{}
				for _, f := range fields {
					byKey[f.Key] = f
					byID[string(f.ID)] = f
				}
				for _, want := range seedFields {
					got, ok := byKey[want.Key]
					if !ok || got.Origin != vocabkey.OriginProvenencia || got.Label != want.Label ||
						got.DataType != want.DataType || got.Description != want.Description || got.UnknownText != want.UnknownText {
						t.Fatalf("field %s = %+v, want %+v", want.Key, got, want)
					}
				}
				for _, want := range seedTypes {
					got, err := sourcetypes.Lookup(c, want.Key, vocabkey.OriginProvenencia)
					if err != nil {
						t.Fatalf("type %s: %v", want.Key, err)
					}
					if got.Label != want.Label || got.Description != want.Description || got.IconKey != want.IconKey {
						t.Fatalf("type %s = %+v, want %+v", want.Key, got, want)
					}
				}

				census, err := sourcetypes.Lookup(c, "census", vocabkey.OriginProvenencia)
				if err != nil {
					t.Fatal(err)
				}
				stored := storedFormats(t, c, census.ID)
				for _, form := range citationformat.Forms() {
					text := stored.Text(form)
					tpl, diags := citationformat.Parse(text, form)
					if len(diags) > 0 {
						t.Fatalf("stored %s: %v", form, diags)
					}
					want, _ := citationformat.Parse(findSeedType(t, "census").Formats.Text(form), form)
					var wantKeys, gotKeys []string
					for _, f := range want.Fields() {
						wantKeys = append(wantKeys, f.Key)
					}
					for _, f := range tpl.Fields() {
						field, ok := byID[string(f.ID[:])]
						if !f.ByID() || !ok || field.Origin != vocabkey.OriginProvenencia {
							t.Fatalf("stored %s names %+v, want a provenencia field id", form, f)
						}
						gotKeys = append(gotKeys, field.Key)
					}
					if !slices.Equal(gotKeys, wantKeys) {
						t.Fatalf("stored %s reads %v, want %v", form, gotKeys, wantKeys)
					}
				}
				view, err := sourcetypes.GetFormats(c, census.ID)
				if err != nil {
					t.Fatal(err)
				}
				if view.Formats != findSeedType(t, "census").Formats || len(view.Choices) != 0 || len(view.Diagnostics) != 0 {
					t.Fatalf("GetFormats = %+v", view)
				}

				// Every type's suggestion list is written in derived order.
				for _, st := range seedTypes {
					want := suggestedKeysOf(t, st.Key)
					if len(want) == 0 {
						t.Fatalf("%s has no suggestions", st.Key)
					}
					ty, err := sourcetypes.Lookup(c, st.Key, vocabkey.OriginProvenencia)
					if err != nil {
						t.Fatalf("type %s: %v", st.Key, err)
					}
					sugs, err := ListSuggestions(c, ty.ID)
					if err != nil {
						t.Fatal(err)
					}
					if len(sugs) != len(want) {
						t.Fatalf("%s lists %d fields, want %d", st.Key, len(sugs), len(want))
					}
					for i, s := range sugs {
						if s.Field.Key != want[i] || s.Field.Origin != vocabkey.OriginProvenencia || s.SortOrder != i {
							t.Fatalf("%s[%d] = %s origin %s sort %d, want %s origin provenencia sort %d",
								st.Key, i, s.Field.Key, s.Field.Origin, s.SortOrder, want[i], i)
						}
					}
				}
			},
		},
		{
			name: "a seed format reading an unseeded field is rejected",
			run: func(t *testing.T, c *database.Catalog) {
				saved := seedTypes
				t.Cleanup(func() { seedTypes = saved })
				seedTypes = []seedType{{Key: "bad_type", Label: "Bad", Description: "Bad.", IconKey: "type_document",
					Formats: sourcetypes.Formats{Full: "{meta.no_such_field}", Short: "{source.title}", List: "{source.title}"}}}
				if err := install(c); !errors.Is(err, ErrInvalid) {
					t.Fatalf("Install = %v, want ErrInvalid", err)
				}
				// The valid fields and type ahead of the bad type are rolled back.
				fields, err := metadatafields.List(c)
				if err != nil || len(fields) != 0 {
					t.Fatalf("fields after a failed install: %v %v", fields, err)
				}
				types, err := sourcetypes.List(c)
				if err != nil || len(types) != 0 {
					t.Fatalf("types after a failed install: %v %v", types, err)
				}
			},
		},
		{
			name: "install twice changes nothing",
			run: func(t *testing.T, c *database.Catalog) {
				if err := install(c); err != nil {
					t.Fatal(err)
				}
				before := snapshot(t, c)
				if err := install(c); err != nil {
					t.Fatal(err)
				}
				if after := snapshot(t, c); !reflect.DeepEqual(before, after) {
					t.Fatalf("a second install changed the catalog:\nbefore %+v\nafter  %+v", before, after)
				}
				db, err := c.DB()
				if err != nil {
					t.Fatal(err)
				}
				if got := dbtest.Revisions(t, db); got != 1 {
					t.Fatalf("revisions after a second install = %d, want 1", got)
				}
			},
		},
		{
			name: "a second install does not restore a deleted suggestion",
			run: func(t *testing.T, c *database.Catalog) {
				if err := install(c); err != nil {
					t.Fatal(err)
				}
				census, err := sourcetypes.Lookup(c, "census", vocabkey.OriginProvenencia)
				if err != nil {
					t.Fatal(err)
				}
				field, err := metadatafields.Lookup(c, "piece", vocabkey.OriginProvenencia)
				if err != nil {
					t.Fatal(err)
				}
				if err := DeleteSuggestion(c, census.ID, field.ID); err != nil {
					t.Fatal(err)
				}
				if err := install(c); err != nil {
					t.Fatal(err)
				}
				sugs, err := ListSuggestions(c, census.ID)
				if err != nil || len(sugs) != len(suggestedKeysOf(t, "census"))-1 {
					t.Fatalf("after second install %v %d", err, len(sugs))
				}
			},
		},
		{
			name: "install records one revision",
			run: func(t *testing.T, c *database.Catalog) {
				if err := install(c); err != nil {
					t.Fatal(err)
				}
				db, err := c.DB()
				if err != nil {
					t.Fatal(err)
				}
				if got := dbtest.Revisions(t, db); got != 1 {
					t.Fatalf("revisions = %d, want 1", got)
				}
				action, changes := dbtest.LatestRevision(t, db)
				if action != ActionInstall {
					t.Fatalf("action = %q", action)
				}
				counts := map[string]int{}
				for _, ch := range changes {
					if ch.Action != rowchange.ActionCreate {
						t.Fatalf("change %+v", ch)
					}
					counts[ch.EntityType]++
				}
				if len(counts) != 2 || counts["source_type"] != len(seedTypes) || counts["metadata_field"] != len(seedFields) {
					t.Fatalf("changes by entity = %v", counts)
				}
				docs := map[string]int{}
				rows, err := db.Query(`SELECT kind, COUNT(*) FROM catalog_search_docs GROUP BY kind`)
				if err != nil {
					t.Fatal(err)
				}
				defer rows.Close()
				for rows.Next() {
					var kind string
					var n int
					if err := rows.Scan(&kind, &n); err != nil {
						t.Fatal(err)
					}
					docs[kind] = n
				}
				if err := rows.Err(); err != nil {
					t.Fatal(err)
				}
				if len(docs) != 2 || docs["source_type"] != len(seedTypes) || docs["metadata_field"] != len(seedFields) {
					t.Fatalf("search docs by kind = %v", docs)
				}
				var nullUser int
				if err := db.QueryRow(`SELECT COUNT(*) FROM audit_transactions WHERE user_id IS NULL`).Scan(&nullUser); err != nil || nullUser != 1 {
					t.Fatalf("null-user revisions = %d %v", nullUser, err)
				}
			},
		},
		{
			name: "deleted provenencia type stays deleted without reinstall",
			run: func(t *testing.T, c *database.Catalog) {
				if err := install(c); err != nil {
					t.Fatal(err)
				}
				cert, err := sourcetypes.Lookup(c, "birth_certificate", vocabkey.OriginProvenencia)
				if err != nil {
					t.Fatal(err)
				}
				userID := []byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}
				userRef, err := ref.Mint(ref.PrefixUser)
				if err != nil {
					t.Fatal(err)
				}
				if err := users.Upsert(c, userID, "Tester", userRef); err != nil {
					t.Fatal(err)
				}
				if err := runSourceTypeDelete(c, userID, cert.ID); err != nil {
					t.Fatal(err)
				}
				_, err = sourcetypes.Lookup(c, "birth_certificate", vocabkey.OriginProvenencia)
				if !errors.Is(err, sql.ErrNoRows) {
					t.Fatalf("want ErrNoRows got %v", err)
				}
			},
		},
		{
			name: "deleted suggestion join stays deleted without reinstall",
			run: func(t *testing.T, c *database.Catalog) {
				if err := install(c); err != nil {
					t.Fatal(err)
				}
				census, err := sourcetypes.Lookup(c, "census", vocabkey.OriginProvenencia)
				if err != nil {
					t.Fatal(err)
				}
				field, err := metadatafields.Lookup(c, "piece", vocabkey.OriginProvenencia)
				if err != nil {
					t.Fatal(err)
				}
				if err := DeleteSuggestion(c, census.ID, field.ID); err != nil {
					t.Fatal(err)
				}
				sugs, err := ListSuggestions(c, census.ID)
				if err != nil || len(sugs) != len(suggestedKeysOf(t, "census"))-1 {
					t.Fatalf("after delete %v %d", err, len(sugs))
				}
			},
		},
		{
			name: "a user field with a seeded key does not capture a format",
			run: func(t *testing.T, c *database.Catalog) {
				userAuthor, err := metadatafieldstest.Upsert(c, metadatafields.Field{
					Key: "author", Origin: vocabkey.OriginUser, Label: "My author", DataType: metadatafields.DataTypeText,
				})
				if err != nil {
					t.Fatal(err)
				}
				if err := install(c); err != nil {
					t.Fatal(err)
				}
				book, err := sourcetypes.Lookup(c, "book", vocabkey.OriginProvenencia)
				if err != nil {
					t.Fatal(err)
				}
				fields, err := metadatafields.List(c)
				if err != nil {
					t.Fatal(err)
				}
				origin := map[string]string{}
				for _, f := range fields {
					origin[string(f.ID)] = f.Origin
				}
				stored := storedFormats(t, c, book.ID)
				named := 0
				for _, form := range citationformat.Forms() {
					tpl, diags := citationformat.Parse(stored.Text(form), form)
					if len(diags) > 0 {
						t.Fatal(diags)
					}
					for _, f := range tpl.Fields() {
						named++
						if bytes.Equal(f.ID[:], userAuthor) {
							t.Fatalf("book's %s format names the user's author", form)
						}
						if origin[string(f.ID[:])] != vocabkey.OriginProvenencia {
							t.Fatalf("book's %s format names %+v, not a provenencia field", form, f)
						}
					}
				}
				if named == 0 {
					t.Fatal("book's formats name no field")
				}
			},
		},
		{
			name: "user origin twin left alone",
			run: func(t *testing.T, c *database.Catalog) {
				if _, err := sourcetypestest.Upsert(c, sourcetypes.Type{
					Key: "birth_certificate", Origin: vocabkey.OriginUser, Label: "My Birth Cert",
				}); err != nil {
					t.Fatal(err)
				}
				if err := install(c); err != nil {
					t.Fatal(err)
				}
				userRow, err := sourcetypes.Lookup(c, "birth_certificate", vocabkey.OriginUser)
				if err != nil {
					t.Fatal(err)
				}
				if userRow.Label != "My Birth Cert" {
					t.Fatalf("user row mutated: %+v", userRow)
				}
				prov, err := sourcetypes.Lookup(c, "birth_certificate", vocabkey.OriginProvenencia)
				if err != nil {
					t.Fatal(err)
				}
				if prov.Label != "Birth certificate" {
					t.Fatalf("provenencia %+v", prov)
				}
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c, err := database.Create(t.TempDir(), "t.provenencia")
			if err != nil {
				t.Fatal(err)
			}
			defer c.Close()
			tt.run(t, c)
		})
	}
}

// suggestionFixture makes a user type "Book" and fields labelled as given.
func suggestionFixture(t *testing.T, c *database.Catalog, labels ...string) ([]byte, [][]byte) {
	t.Helper()
	typeID, err := sourcetypestest.Upsert(c, sourcetypes.Type{
		Key: "book", Origin: vocabkey.OriginUser, Label: "Book",
	})
	if err != nil {
		t.Fatal(err)
	}
	var fieldIDs [][]byte
	for _, label := range labels {
		f, err := runFieldCreate(c, label, metadatafields.DataTypeText, "")
		if err != nil {
			t.Fatal(err)
		}
		fieldIDs = append(fieldIDs, f.ID)
	}
	return typeID, fieldIDs
}

func suggestionLabels(sugs []Suggestion) []string {
	var out []string
	for _, s := range sugs {
		out = append(out, s.Field.Label)
	}
	return out
}

func TestAppendSuggestion(t *testing.T) {
	tests := []struct {
		name string
		run  func(t *testing.T, c *database.Catalog)
	}{
		{
			name: "appends in call order and is idempotent",
			run: func(t *testing.T, c *database.Catalog) {
				typeID, ids := suggestionFixture(t, c, "Author", "Publisher")
				// Assigned second first, so a plain label sort would disagree
				// with the stored order the UI has to preserve.
				for _, id := range [][]byte{ids[1], ids[0]} {
					if err := AppendSuggestion(c, typeID, id); err != nil {
						t.Fatal(err)
					}
				}
				// Re-assigning an existing pair is no error and must not move it.
				if err := AppendSuggestion(c, typeID, ids[1]); err != nil {
					t.Fatal(err)
				}
				got, err := ListSuggestions(c, typeID)
				if err != nil {
					t.Fatal(err)
				}
				if !slices.Equal(suggestionLabels(got), []string{"Publisher", "Author"}) || got[0].SortOrder != 0 || got[1].SortOrder != 1 {
					t.Fatalf("got %+v", got)
				}
			},
		},
		{
			name: "bad ids are rejected",
			run: func(t *testing.T, c *database.Catalog) {
				if err := AppendSuggestion(c, []byte{1}, []byte{2}); !errors.Is(err, ErrInvalid) {
					t.Fatalf("got %v", err)
				}
				if _, err := ListSuggestions(c, make([]byte, 15)); !errors.Is(err, ErrInvalid) {
					t.Fatalf("ListSuggestions = %v", err)
				}
				if err := DeleteSuggestion(c, []byte{1}, []byte{2}); !errors.Is(err, ErrInvalid) {
					t.Fatalf("DeleteSuggestion = %v", err)
				}
			},
		},
		{
			name: "ListSuggestionsTx reads what ListSuggestions reads, for many types at once",
			run: func(t *testing.T, c *database.Catalog) {
				typeID, _ := suggestionFixture(t, c)
				otherID, err := sourcetypestest.Upsert(c, sourcetypes.Type{
					Key: "letter", Origin: vocabkey.OriginUser, Label: "Letter",
				})
				if err != nil {
					t.Fatal(err)
				}
				emptyID, err := sourcetypestest.Upsert(c, sourcetypes.Type{
					Key: "diary", Origin: vocabkey.OriginUser, Label: "Diary",
				})
				if err != nil {
					t.Fatal(err)
				}
				for _, label := range []string{"Author", "Publisher"} {
					f, err := runFieldCreate(c, label, metadatafields.DataTypeText, "")
					if err != nil {
						t.Fatal(err)
					}
					if err := AppendSuggestion(c, typeID, f.ID); err != nil {
						t.Fatal(err)
					}
					if label == "Author" {
						if err := AppendSuggestion(c, otherID, f.ID); err != nil {
							t.Fatal(err)
						}
					}
					if label == "Publisher" {
						unknownText := "n.p."
						if _, _, err := writes.Run(c, writes.Op{Action: "update_metadata_field"},
							func(tx *database.Tx) (metadatafields.Field, []rowchange.Change, error) {
								return metadatafields.Update(tx, f.ID, f.Label, f.DataType, "", &unknownText)
							}); err != nil {
							t.Fatal(err)
						}
					}
				}
				want, err := ListSuggestions(c, typeID)
				if err != nil || len(want) != 2 || want[1].Field.UnknownText != "n.p." {
					t.Fatalf("ListSuggestions = %+v, %v", want, err)
				}
				db, err := c.DB()
				if err != nil {
					t.Fatal(err)
				}
				tx, err := db.Begin()
				if err != nil {
					t.Fatal(err)
				}
				defer func() { _ = tx.Rollback() }()
				all, err := ListSuggestionsTx(tx, [][]byte{typeID, otherID, emptyID, typeID})
				if err != nil {
					t.Fatal(err)
				}
				if len(all) != 2 {
					t.Fatalf("keys %d, want the two types that suggest something", len(all))
				}
				if _, ok := all[string(emptyID)]; ok {
					t.Fatal("a type with no suggestions must be absent")
				}
				got := all[string(typeID)]
				if len(got) != len(want) {
					t.Fatalf("got %d suggestions, want %d", len(got), len(want))
				}
				for i := range got {
					if !bytes.Equal(got[i].Field.ID, want[i].Field.ID) || got[i].SortOrder != want[i].SortOrder || got[i].Field.UnknownText != want[i].Field.UnknownText {
						t.Fatalf("suggestion %d = %+v, want %+v", i, got[i], want[i])
					}
				}
				if l := suggestionLabels(all[string(otherID)]); !slices.Equal(l, []string{"Author"}) {
					t.Fatalf("other type's list = %v", l)
				}
				none, err := ListSuggestionsTx(tx, nil)
				if err != nil || len(none) != 0 {
					t.Fatalf("no ids = %v, %v", none, err)
				}
			},
		},
		{
			name: "ListSuggestionsTx with a nil tx is invalid",
			run: func(t *testing.T, c *database.Catalog) {
				if _, err := ListSuggestionsTx(nil, [][]byte{make([]byte, 16)}); !errors.Is(err, ErrInvalid) {
					t.Fatalf("got %v", err)
				}
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c, err := database.Create(t.TempDir(), "t.provenencia")
			if err != nil {
				t.Fatal(err)
			}
			defer c.Close()
			tt.run(t, c)
		})
	}
}

func TestDeleteSuggestion(t *testing.T) {
	c, err := database.Create(t.TempDir(), "t.provenencia")
	if err != nil {
		t.Fatal(err)
	}
	defer c.Close()
	typeID, ids := suggestionFixture(t, c, "Author", "Publisher")
	for _, id := range ids {
		if err := AppendSuggestion(c, typeID, id); err != nil {
			t.Fatal(err)
		}
	}
	// Twice: the second delete finds nothing and is no error.
	for range 2 {
		if err := DeleteSuggestion(c, typeID, ids[1]); err != nil {
			t.Fatal(err)
		}
		got, err := ListSuggestions(c, typeID)
		if err != nil || !slices.Equal(suggestionLabels(got), []string{"Author"}) {
			t.Fatalf("suggestions %+v %v", got, err)
		}
	}
	if _, err := metadatafields.GetByID(c, ids[1]); err != nil {
		t.Fatalf("field should survive: %v", err)
	}
}

func runSourceTypeDelete(c *database.Catalog, userID, id []byte) error {
	_, err := writes.RunChanges(c, writes.Op{Action: "delete_source_type", UserID: userID},
		func(tx *database.Tx) ([]rowchange.Change, error) {
			return sourcetypes.Delete(tx, userID, id)
		})
	return err
}

func runFieldCreate(c *database.Catalog, label, dataType, description string) (metadatafields.Field, error) {
	got, _, err := writes.Run(c, writes.Op{Action: "create_metadata_field"},
		func(tx *database.Tx) (metadatafields.Field, []rowchange.Change, error) {
			return metadatafields.Create(tx, label, dataType, description)
		})
	return got, err
}

// suggestedKeysOf is the derived suggestion list of one seeded type.
func suggestedKeysOf(t *testing.T, typeKey string) []string {
	t.Helper()
	return suggestedKeys(findSeedType(t, typeKey).Formats)
}
