package sourcetypes

import (
	"bytes"
	"database/sql"
	"errors"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/catalogmodel"
	"github.com/Jake-Robins-Studios/provenencia/core/database/deleteimpact"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields/metadatafieldstest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sources"
	"github.com/Jake-Robins-Studios/provenencia/core/database/users"
	"github.com/Jake-Robins-Studios/provenencia/core/ref"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
)

func TestUpsertLookupList(t *testing.T) {
	tests := []struct {
		name string
		run  func(t *testing.T, c *database.Catalog)
	}{
		{
			name: "upsert lookup and list",
			run: func(t *testing.T, c *database.Catalog) {
				id, err := upsert(c, Type{
					Key: "photograph", Origin: vocabkey.OriginProvenencia, Label: "Photograph", Description: "Photo",
				})
				if err != nil {
					t.Fatal(err)
				}
				got, err := Lookup(c, "photograph", vocabkey.OriginProvenencia)
				if err != nil {
					t.Fatal(err)
				}
				if string(got.ID) != string(id) || got.Label != "Photograph" || got.Description != "Photo" {
					t.Fatalf("got %+v", got)
				}
				id2, err := upsert(c, Type{
					Key: "photograph", Origin: vocabkey.OriginProvenencia, Label: "Photo", Description: "Updated",
				})
				if err != nil {
					t.Fatal(err)
				}
				if string(id2) != string(id) {
					t.Fatal("id should be stable on upsert")
				}
				got, err = Lookup(c, "photograph", vocabkey.OriginProvenencia)
				if err != nil {
					t.Fatal(err)
				}
				if got.Label != "Photo" || got.Description != "Updated" {
					t.Fatalf("got %+v", got)
				}
				all, err := List(c)
				if err != nil || len(all) != 1 {
					t.Fatalf("list %v %d", err, len(all))
				}
			},
		},
		{
			name: "same key different origins",
			run: func(t *testing.T, c *database.Catalog) {
				if _, err := upsert(c, Type{Key: "book", Origin: vocabkey.OriginProvenencia, Label: "Book"}); err != nil {
					t.Fatal(err)
				}
				if _, err := upsert(c, Type{Key: "book", Origin: vocabkey.OriginUser, Label: "My Book"}); err != nil {
					t.Fatal(err)
				}
				all, err := List(c)
				if err != nil || len(all) != 2 {
					t.Fatalf("list %v %d", err, len(all))
				}
			},
		},
		{
			name: "rejects blank key",
			run: func(t *testing.T, c *database.Catalog) {
				if _, err := upsert(c, Type{Key: "  ", Origin: vocabkey.OriginUser, Label: "X"}); !errors.Is(err, ErrInvalid) {
					t.Fatalf("got %v", err)
				}
			},
		},
		{
			name: "lookup missing",
			run: func(t *testing.T, c *database.Catalog) {
				_, err := Lookup(c, "nope", vocabkey.OriginProvenencia)
				if !errors.Is(err, sql.ErrNoRows) {
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

func TestDelete(t *testing.T) {
	userID := []byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}

	mustUser := func(t *testing.T, c *database.Catalog) {
		t.Helper()
		r, err := ref.Mint(ref.PrefixUser)
		if err != nil {
			t.Fatal(err)
		}
		if err := users.Upsert(c, userID, "Jake", r); err != nil {
			t.Fatal(err)
		}
	}
	latestAction := func(t *testing.T, c *database.Catalog) string {
		t.Helper()
		db, err := c.DB()
		if err != nil {
			t.Fatal(err)
		}
		var actionType string
		if err := db.QueryRow(
			`SELECT action_type FROM audit_transactions ORDER BY revision DESC LIMIT 1`,
		).Scan(&actionType); err != nil {
			t.Fatal(err)
		}
		return actionType
	}

	tests := []struct {
		name string
		run  func(t *testing.T, c *database.Catalog)
	}{
		{
			name: "unused provenencia ok",
			run: func(t *testing.T, c *database.Catalog) {
				mustUser(t, c)
				id, err := upsert(c, Type{Key: "census", Origin: vocabkey.OriginProvenencia, Label: "Census"})
				if err != nil {
					t.Fatal(err)
				}
				if err := runDelete(c, userID, id); err != nil {
					t.Fatal(err)
				}
				if latestAction(t, c) != "delete_source_type" {
					t.Fatalf("action %q", latestAction(t, c))
				}
				_, err = Lookup(c, "census", vocabkey.OriginProvenencia)
				if !errors.Is(err, sql.ErrNoRows) {
					t.Fatalf("got %v", err)
				}
			},
		},
		{
			name: "in use refuses",
			run: func(t *testing.T, c *database.Catalog) {
				mustUser(t, c)
				id, err := upsert(c, Type{Key: "book", Origin: vocabkey.OriginUser, Label: "Book"})
				if err != nil {
					t.Fatal(err)
				}
				if _, _, err := writes.Run(c, writes.Op{Action: "create_source", UserID: userID}, func(tx *database.Tx) (sources.Source, []rowchange.Change, error) {
					return sources.Create(tx, userID, sources.CreateInput{SourceTypeID: id, Title: "T"})
				}); err != nil {
					t.Fatal(err)
				}
				if err := runDelete(c, userID, id); !errors.Is(err, ErrInUse) {
					t.Fatalf("got %v", err)
				}
				if _, err := GetByID(c, id); err != nil {
					t.Fatalf("type gone: %v", err)
				}
			},
		},
		{
			name: "unused plugin is origin locked",
			run: func(t *testing.T, c *database.Catalog) {
				mustUser(t, c)
				id, err := upsert(c, Type{
					Key: "memorial", Origin: "plugin:findagrave", Label: "Grave memorial",
				})
				if err != nil {
					t.Fatal(err)
				}
				if err := runDelete(c, userID, id); !errors.Is(err, ErrOriginLocked) {
					t.Fatalf("got %v", err)
				}
				if _, err := GetByID(c, id); err != nil {
					t.Fatalf("type gone: %v", err)
				}
			},
		},
		{
			name: "missing is invalid",
			run: func(t *testing.T, c *database.Catalog) {
				mustUser(t, c)
				missing := make([]byte, 16)
				missing[15] = 9
				if err := runDelete(c, userID, missing); !errors.Is(err, ErrInvalid) {
					t.Fatalf("got %v", err)
				}
			},
		},
		{
			name: "unused type with suggestions still erases",
			run: func(t *testing.T, c *database.Catalog) {
				mustUser(t, c)
				id, err := upsert(c, Type{Key: "book", Origin: vocabkey.OriginUser, Label: "Book"})
				if err != nil {
					t.Fatal(err)
				}
				fieldID, err := metadatafieldstest.Upsert(c, metadatafields.Field{
					Key: "author", Origin: vocabkey.OriginUser, Label: "Author", DataType: metadatafields.DataTypeText,
				})
				if err != nil {
					t.Fatal(err)
				}
				db, err := c.DB()
				if err != nil {
					t.Fatal(err)
				}
				if _, err := db.Exec(
					`INSERT INTO source_type_metadata_fields (source_type_id, field_id, level, sort_order) VALUES (?, ?, 'source', 0)`,
					id, fieldID,
				); err != nil {
					t.Fatal(err)
				}
				if err := runDelete(c, userID, id); err != nil {
					t.Fatal(err)
				}
				if _, err := GetByID(c, id); !errors.Is(err, sql.ErrNoRows) {
					t.Fatalf("type still there: %v", err)
				}
				var joins int
				if err := db.QueryRow(
					`SELECT COUNT(*) FROM source_type_metadata_fields WHERE source_type_id = ?`, id,
				).Scan(&joins); err != nil || joins != 0 {
					t.Fatalf("joins leftover %d %v", joins, err)
				}
				if _, err := metadatafields.GetByID(c, fieldID); err != nil {
					t.Fatalf("field should survive: %v", err)
				}
			},
		},
		{
			name: "keeps its formats in the delete change",
			run: func(t *testing.T, c *database.Catalog) {
				mustUser(t, c)
				id, err := upsert(c, Type{Key: "census", Origin: vocabkey.OriginUser, Label: "Census"})
				if err != nil {
					t.Fatal(err)
				}
				db, err := c.DB()
				if err != nil {
					t.Fatal(err)
				}
				if _, err := db.Exec(`UPDATE source_types SET citation_full = ?, citation_list = ? WHERE id = ?`,
					"{source.title}", "{source.date}", id); err != nil {
					t.Fatal(err)
				}
				tx, err := c.BeginWrite()
				if err != nil {
					t.Fatal(err)
				}
				defer c.EndWrite()
				defer func() { _ = tx.Rollback() }()
				changes, err := Delete(tx, userID, id)
				if err != nil {
					t.Fatal(err)
				}
				fields := changes[len(changes)-1].Fields
				if fields["citation_full"].Old != "{source.title}" || fields["citation_list"].Old != "{source.date}" {
					t.Fatalf("fields %+v", fields)
				}
				if _, ok := fields["citation_short"]; ok {
					t.Fatalf("an empty format is recorded: %+v", fields)
				}
			},
		},
		{
			name: "bad id",
			run: func(t *testing.T, c *database.Catalog) {
				if err := runDelete(c, userID, []byte{1}); !errors.Is(err, ErrInvalid) {
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

func TestCreateUpdateGetByID(t *testing.T) {
	userID := []byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}

	tests := []struct {
		name string
		run  func(t *testing.T, c *database.Catalog)
	}{
		{
			name: "create mints kebab key from label",
			run: func(t *testing.T, c *database.Catalog) {
				got, err := runCreate(c, "Parish register", "Baptisms, marriages, burials", "type_scroll")
				if err != nil {
					t.Fatal(err)
				}
				if got.Key != "parish-register" || got.Origin != vocabkey.OriginUser {
					t.Fatalf("got %+v", got)
				}
				if got.IconKey != "type_scroll" {
					t.Fatalf("icon_key %+v", got)
				}
			},
		},
		{
			name: "create refuses unknown icon_key",
			run: func(t *testing.T, c *database.Catalog) {
				if _, err := runCreate(c, "Deed", "", "type_not_a_real_icon"); !errors.Is(err, ErrInvalid) {
					t.Fatalf("got %v", err)
				}
			},
		},
		{
			name: "create empty icon_key defaults to type_evidence",
			run: func(t *testing.T, c *database.Catalog) {
				got, err := runCreate(c, "Loose note", "", "")
				if err != nil {
					t.Fatal(err)
				}
				if got.IconKey != DefaultIconKey {
					t.Fatalf("icon_key %+v", got)
				}
			},
		},
		{
			name: "create refuses an unslugifiable label",
			run: func(t *testing.T, c *database.Catalog) {
				if _, err := runCreate(c, "—", "", "type_evidence"); !errors.Is(err, ErrInvalid) {
					t.Fatalf("got %v", err)
				}
			},
		},
		{
			name: "create refuses a duplicate user key",
			run: func(t *testing.T, c *database.Catalog) {
				if _, err := runCreate(c, "Parish register", "", "type_scroll"); err != nil {
					t.Fatal(err)
				}
				_, err := runCreate(c, "Parish Register", "", "type_scroll")
				if !errors.Is(err, ErrDuplicateKey) {
					t.Fatalf("got %v", err)
				}
			},
		},
		{
			name: "create with stored formats keeps them and audits the non-empty forms",
			run: func(t *testing.T, c *database.Catalog) {
				in := Formats{Full: "{source.title}", List: "{source.title}."}
				var changes []rowchange.Change
				got, _, err := writes.Run(c, writes.Op{Action: "create_source_type"},
					func(tx *database.Tx) (Type, []rowchange.Change, error) {
						typ, ch, err := Create(tx, CreateInput{Label: "State census", Formats: in})
						changes = ch
						return typ, ch, err
					})
				if err != nil {
					t.Fatal(err)
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
				stored, err := StoredFormatsTx(tx, [][]byte{got.ID})
				if err != nil {
					t.Fatal(err)
				}
				if stored[string(got.ID)] != in {
					t.Fatalf("stored %+v", stored[string(got.ID)])
				}
				if len(changes) != 1 {
					t.Fatalf("changes %+v", changes)
				}
				f := changes[0].Fields
				if f["citation_full"].New != in.Full || f["citation_full"].Old != nil ||
					f["citation_list"].New != in.List {
					t.Fatalf("fields %+v", f)
				}
				if _, ok := f["citation_short"]; ok {
					t.Fatalf("empty short form audited: %+v", f)
				}
			},
		},
		{
			name: "get by id on a tx refuses a short id",
			run: func(t *testing.T, c *database.Catalog) {
				db, err := c.DB()
				if err != nil {
					t.Fatal(err)
				}
				tx, err := db.Begin()
				if err != nil {
					t.Fatal(err)
				}
				defer func() { _ = tx.Rollback() }()
				if _, err := GetByIDTx(tx, make([]byte, 15)); !errors.Is(err, ErrInvalid) {
					t.Fatalf("got %v", err)
				}
			},
		},
		{
			name: "create may reuse a provenencia key under user origin",
			run: func(t *testing.T, c *database.Catalog) {
				if _, err := upsert(c, Type{Key: "book", Origin: vocabkey.OriginProvenencia, Label: "Book"}); err != nil {
					t.Fatal(err)
				}
				got, err := runCreate(c, "Book", "", "type_book")
				if err != nil {
					t.Fatal(err)
				}
				if got.Key != "book" || got.Origin != vocabkey.OriginUser {
					t.Fatalf("got %+v", got)
				}
			},
		},
		{
			name: "update patches label and description, keeping the key",
			run: func(t *testing.T, c *database.Catalog) {
				id, err := upsert(c, Type{Key: "book", Origin: vocabkey.OriginProvenencia, Label: "Book", Description: "Old"})
				if err != nil {
					t.Fatal(err)
				}
				got, err := runUpdate(c, id, "Printed book", "New", "type_book")
				if err != nil {
					t.Fatal(err)
				}
				if got.Key != "book" || got.Label != "Printed book" || got.Description != "New" {
					t.Fatalf("got %+v", got)
				}
				if got.IconKey != "type_book" {
					t.Fatalf("icon_key %+v", got)
				}
			},
		},
		{
			name: "update empty icon_key preserves existing",
			run: func(t *testing.T, c *database.Catalog) {
				id, err := upsert(c, Type{
					Key: "scroll", Origin: vocabkey.OriginUser, Label: "Scroll", IconKey: "type_scroll",
				})
				if err != nil {
					t.Fatal(err)
				}
				got, err := runUpdate(c, id, "Parish scroll", "", "")
				if err != nil {
					t.Fatal(err)
				}
				if got.IconKey != "type_scroll" {
					t.Fatalf("icon_key %+v", got)
				}
			},
		},
		{
			name: "update refuses a plugin type",
			run: func(t *testing.T, c *database.Catalog) {
				id, err := upsert(c, Type{Key: "memorial", Origin: "plugin:findagrave", Label: "Grave memorial"})
				if err != nil {
					t.Fatal(err)
				}
				if _, err := runUpdate(c, id, "Mine now", "", "type_book"); !errors.Is(err, ErrLocked) {
					t.Fatalf("got %v", err)
				}
			},
		},
		{
			name: "update refuses a blank label",
			run: func(t *testing.T, c *database.Catalog) {
				id, err := upsert(c, Type{Key: "book", Origin: vocabkey.OriginUser, Label: "Book"})
				if err != nil {
					t.Fatal(err)
				}
				if _, err := runUpdate(c, id, "   ", "", "type_evidence"); !errors.Is(err, ErrInvalid) {
					t.Fatalf("got %v", err)
				}
			},
		},
		{
			name: "get by id round-trips, missing is ErrNoRows",
			run: func(t *testing.T, c *database.Catalog) {
				id, err := upsert(c, Type{Key: "book", Origin: vocabkey.OriginUser, Label: "Book"})
				if err != nil {
					t.Fatal(err)
				}
				got, err := GetByID(c, id)
				if err != nil || got.Key != "book" {
					t.Fatalf("got %+v %v", got, err)
				}
				missing := []byte{9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9}
				if _, err := GetByID(c, missing); !errors.Is(err, sql.ErrNoRows) {
					t.Fatalf("got %v", err)
				}
			},
		},
		{
			name: "list and UsedBy count the sources of a type",
			run: func(t *testing.T, c *database.Catalog) {
				r, err := ref.Mint(ref.PrefixUser)
				if err != nil {
					t.Fatal(err)
				}
				if err := users.Upsert(c, userID, "Jake", r); err != nil {
					t.Fatal(err)
				}
				used, err := upsert(c, Type{Key: "book", Origin: vocabkey.OriginUser, Label: "Book"})
				if err != nil {
					t.Fatal(err)
				}
				if _, err := upsert(c, Type{Key: "letter", Origin: vocabkey.OriginUser, Label: "Letter"}); err != nil {
					t.Fatal(err)
				}
				for _, title := range []string{"One", "Two"} {
					if _, _, err := writes.Run(c, writes.Op{Action: "create_source", UserID: userID}, func(tx *database.Tx) (sources.Source, []rowchange.Change, error) {
						return sources.Create(tx, userID, sources.CreateInput{SourceTypeID: used, Title: title})
					}); err != nil {
						t.Fatal(err)
					}
				}
				n, err := deleteimpact.UsedBy(c, catalogmodel.KindSourceType, used)
				if err != nil || n != 2 {
					t.Fatalf("UsedBy %d %v", n, err)
				}
				all, err := List(c)
				if err != nil {
					t.Fatal(err)
				}
				byKey := map[string]int{}
				for _, tp := range all {
					byKey[tp.Key] = tp.UsedBy
				}
				if byKey["book"] != 2 || byKey["letter"] != 0 {
					t.Fatalf("got %v", byKey)
				}
				db, err := c.DB()
				if err != nil {
					t.Fatal(err)
				}
				tx, err := db.Begin()
				if err != nil {
					t.Fatal(err)
				}
				defer tx.Rollback()
				if total, err := deleteimpact.InboundTotal(tx, catalogmodel.KindSourceType, used); err != nil || total != n {
					t.Fatalf("InboundTotal = %d, %v; want %d", total, err, n)
				}
			},
		},
		{
			name: "list counts the fields a type suggests at every level",
			run: func(t *testing.T, c *database.Catalog) {
				typeID, err := upsert(c, Type{Key: "book", Origin: vocabkey.OriginUser, Label: "Book"})
				if err != nil {
					t.Fatal(err)
				}
				if _, err := upsert(c, Type{Key: "letter", Origin: vocabkey.OriginUser, Label: "Letter"}); err != nil {
					t.Fatal(err)
				}
				fieldID, err := metadatafieldstest.Upsert(c, metadatafields.Field{
					Key: "author", Origin: vocabkey.OriginUser, Label: "Author", DataType: metadatafields.DataTypeText,
				})
				if err != nil {
					t.Fatal(err)
				}
				// The join belongs to sourcevocab, which imports this
				// package — insert the row directly to avoid the cycle.
				db, err := c.DB()
				if err != nil {
					t.Fatal(err)
				}
				for _, level := range []string{"source", "graph"} {
					if _, err := db.Exec(
						`INSERT INTO source_type_metadata_fields (source_type_id, field_id, level, sort_order) VALUES (?, ?, ?, 0)`,
						typeID, fieldID, level,
					); err != nil {
						t.Fatal(err)
					}
				}
				all, err := List(c)
				if err != nil {
					t.Fatal(err)
				}
				byKey := map[string]int{}
				for _, tp := range all {
					byKey[tp.Key] = tp.SuggestedFields
				}
				if byKey["book"] != 2 || byKey["letter"] != 0 {
					t.Fatalf("got %v", byKey)
				}
				if n, err := SuggestedFields(c, typeID); err != nil || n != 2 {
					t.Fatalf("SuggestedFields = %d, %v, want 2", n, err)
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

func runCreate(c *database.Catalog, label, description, iconKey string) (Type, error) {
	got, _, err := writes.Run(c, writes.Op{Action: "create_source_type"},
		func(tx *database.Tx) (Type, []rowchange.Change, error) {
			return Create(tx, CreateInput{Label: label, Description: description, IconKey: iconKey})
		})
	return got, err
}

func runUpdate(c *database.Catalog, id []byte, label, description, iconKey string) (Type, error) {
	got, _, err := writes.Run(c, writes.Op{Action: "update_source_type"},
		func(tx *database.Tx) (Type, []rowchange.Change, error) {
			return Update(tx, id, label, description, iconKey)
		})
	return got, err
}

func runDelete(c *database.Catalog, userID, id []byte) error {
	_, _, err := writes.Run(c, writes.Op{Action: "delete_source_type", UserID: userID},
		func(tx *database.Tx) (struct{}, []rowchange.Change, error) {
			changes, err := Delete(tx, userID, id)
			return struct{}{}, changes, err
		})
	return err
}

func TestUpsertTx(t *testing.T) {
	run := func(t *testing.T, c *database.Catalog, in Type) ([]byte, []rowchange.Change, error) {
		t.Helper()
		var changes []rowchange.Change
		id, err := writes.Call(c, writes.Op{Action: "upsert_source_type"}, func(tx *database.Tx) ([]byte, []rowchange.Change, error) {
			id, cs, err := UpsertTx(tx, in)
			changes = cs
			return id, cs, err
		})
		return id, changes, err
	}
	census := Type{Key: "census", Origin: vocabkey.OriginProvenencia, Label: "Census", IconKey: "type_census"}
	tests := []struct {
		name string
		run  func(t *testing.T, c *database.Catalog)
	}{
		{"insert records a create change with Create's keys", func(t *testing.T, c *database.Catalog) {
			census := census
			census.Description = "Decennial"
			id, changes, err := run(t, c, census)
			if err != nil || len(changes) != 1 || changes[0].Action != rowchange.ActionCreate || changes[0].EntityType != "source_type" {
				t.Fatalf("%v %+v", err, changes)
			}
			for _, k := range []string{"id", "key", "origin", "label", "icon_key", "description"} {
				if _, ok := changes[0].Fields[k]; !ok {
					t.Fatalf("create change lacks %s: %+v", k, changes[0].Fields)
				}
			}
			if len(changes[0].Fields) != 6 || !bytes.Equal(changes[0].EntityID, id) {
				t.Fatalf("fields %+v", changes[0].Fields)
			}
			_, createChanges, err := Create(mustBegin(t, c), CreateInput{Label: "Letter", Description: "x", IconKey: "type_book"})
			if err != nil {
				t.Fatal(err)
			}
			for k := range createChanges[0].Fields {
				if _, ok := changes[0].Fields[k]; !ok {
					t.Fatalf("Create records %s, UpsertTx does not", k)
				}
			}
		}},
		{"the same values change nothing", func(t *testing.T, c *database.Catalog) {
			id, _, err := run(t, c, census)
			if err != nil {
				t.Fatal(err)
			}
			id2, changes, err := run(t, c, census)
			if err != nil || len(changes) != 0 || !bytes.Equal(id, id2) {
				t.Fatalf("%v %x %x %+v", err, id, id2, changes)
			}
		}},
		{"a label change is one label diff", func(t *testing.T, c *database.Catalog) {
			if _, _, err := run(t, c, census); err != nil {
				t.Fatal(err)
			}
			next := census
			next.Label = "Census schedule"
			_, changes, err := run(t, c, next)
			if err != nil || len(changes) != 1 || changes[0].Action != rowchange.ActionUpdate || len(changes[0].Fields) != 1 {
				t.Fatalf("%v %+v", err, changes)
			}
			if d := changes[0].Fields["label"]; d.Old != "Census" || d.New != "Census schedule" {
				t.Fatalf("diff %+v", d)
			}
		}},
		{"an icon change is one icon_key diff", func(t *testing.T, c *database.Catalog) {
			if _, _, err := run(t, c, census); err != nil {
				t.Fatal(err)
			}
			next := census
			next.IconKey = "type_book"
			_, changes, err := run(t, c, next)
			if err != nil || len(changes) != 1 || len(changes[0].Fields) != 1 {
				t.Fatalf("%v %+v", err, changes)
			}
			if _, ok := changes[0].Fields["icon_key"]; !ok {
				t.Fatalf("%+v", changes[0].Fields)
			}
		}},
		{"a plugin origin is accepted", func(t *testing.T, c *database.Catalog) {
			in := census
			in.Origin = "plugin:acme"
			if _, changes, err := run(t, c, in); err != nil || len(changes) != 1 {
				t.Fatalf("%v %+v", err, changes)
			}
		}},
		{"invalid input writes nothing", func(t *testing.T, c *database.Catalog) {
			for _, in := range []Type{
				{Key: "  ", Origin: vocabkey.OriginUser, Label: "X"},
				{Key: "x", Origin: vocabkey.OriginUser, Label: " "},
				{Key: "x", Origin: "bogus", Label: "X"},
				{ID: make([]byte, 16), Key: "x", Origin: vocabkey.OriginUser, Label: "X"},
			} {
				if _, _, err := run(t, c, in); !errors.Is(err, ErrInvalid) {
					t.Fatalf("%+v: %v", in, err)
				}
			}
			if types, err := List(c); err != nil || len(types) != 0 {
				t.Fatalf("%v %v", types, err)
			}
		}},
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

func mustBegin(t *testing.T, c *database.Catalog) *database.Tx {
	t.Helper()
	tx, err := c.BeginWrite()
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(c.EndWrite)
	t.Cleanup(func() { _ = tx.Rollback() })
	return tx
}
