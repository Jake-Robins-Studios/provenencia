package metadatafields_test

import (
	"bytes"
	"database/sql"
	"encoding/binary"
	"errors"
	"fmt"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields/metadatafieldstest"
	"slices"
	"strings"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/artifacts"
	"github.com/Jake-Robins-Studios/provenencia/core/database/catalogmodel"
	"github.com/Jake-Robins-Studios/provenencia/core/database/dbtest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/deleteimpact"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sources"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes/sourcetypestest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sqlbatch"
	"github.com/Jake-Robins-Studios/provenencia/core/database/users"
	"github.com/Jake-Robins-Studios/provenencia/core/ref"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
	"github.com/google/uuid"
)

func TestUpsertLookupList(t *testing.T) {
	tests := []struct {
		name string
		run  func(t *testing.T, c *database.Catalog)
	}{
		{
			name: "upsert lookup refresh data type",
			run: func(t *testing.T, c *database.Catalog) {
				id, err := metadatafieldstest.Upsert(c, metadatafields.Field{
					Key: "author", Origin: vocabkey.OriginProvenencia, Label: "Author", DataType: metadatafields.DataTypeText,
				})
				if err != nil {
					t.Fatal(err)
				}
				got, err := metadatafields.Lookup(c, "author", vocabkey.OriginProvenencia)
				if err != nil {
					t.Fatal(err)
				}
				if string(got.ID) != string(id) || got.DataType != metadatafields.DataTypeText {
					t.Fatalf("got %+v", got)
				}
				if _, err := metadatafieldstest.Upsert(c, metadatafields.Field{
					Key: "author", Origin: vocabkey.OriginProvenencia, Label: "Author", DataType: metadatafields.DataTypeURL,
				}); err != nil {
					t.Fatal(err)
				}
				got, err = metadatafields.Lookup(c, "author", vocabkey.OriginProvenencia)
				if err != nil {
					t.Fatal(err)
				}
				if got.DataType != metadatafields.DataTypeURL {
					t.Fatalf("data_type %q", got.DataType)
				}
			},
		},
		{
			name: "rejects bad data type",
			run: func(t *testing.T, c *database.Catalog) {
				if _, err := metadatafieldstest.Upsert(c, metadatafields.Field{
					Key: "x", Origin: vocabkey.OriginUser, Label: "X", DataType: "number",
				}); !errors.Is(err, metadatafields.ErrInvalid) {
					t.Fatalf("got %v", err)
				}
			},
		},
		{
			name: "upsert accepts url data type",
			run: func(t *testing.T, c *database.Catalog) {
				id, err := metadatafieldstest.Upsert(c, metadatafields.Field{
					Key: "landing-page", Origin: vocabkey.OriginUser, Label: "Landing page", DataType: metadatafields.DataTypeURL,
				})
				if err != nil {
					t.Fatal(err)
				}
				got, err := metadatafields.Lookup(c, "landing-page", vocabkey.OriginUser)
				if err != nil {
					t.Fatal(err)
				}
				if string(got.ID) != string(id) || got.DataType != metadatafields.DataTypeURL {
					t.Fatalf("got %+v", got)
				}
			},
		},
		{
			name: "lookup missing",
			run: func(t *testing.T, c *database.Catalog) {
				_, err := metadatafields.Lookup(c, "nope", vocabkey.OriginProvenencia)
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
				id, err := metadatafieldstest.Upsert(c, metadatafields.Field{
					Key: "author", Origin: vocabkey.OriginProvenencia, Label: "Author", DataType: metadatafields.DataTypeText,
				})
				if err != nil {
					t.Fatal(err)
				}
				if err := runDelete(c, userID, id); err != nil {
					t.Fatal(err)
				}
				if latestAction(t, c) != "delete_metadata_field" {
					t.Fatalf("action %q", latestAction(t, c))
				}
				_, err = metadatafields.Lookup(c, "author", vocabkey.OriginProvenencia)
				if !errors.Is(err, sql.ErrNoRows) {
					t.Fatalf("got %v", err)
				}
			},
		},
		{
			name: "in use refuses",
			run: func(t *testing.T, c *database.Catalog) {
				mustUser(t, c)
				typeID, err := sourcetypestest.Upsert(c, sourcetypes.Type{
					Key: "book", Origin: vocabkey.OriginUser, Label: "Book",
				})
				if err != nil {
					t.Fatal(err)
				}
				src, _, err := writes.Run(c, writes.Op{Action: "create_source", UserID: userID}, func(tx *database.Tx) (sources.Source, []rowchange.Change, error) {
					return sources.Create(tx, userID, sources.CreateInput{SourceTypeID: typeID, Title: "T"})
				})
				if err != nil {
					t.Fatal(err)
				}
				field, err := runCreate(c, "Folio", metadatafields.DataTypeText, "")
				if err != nil {
					t.Fatal(err)
				}
				db, err := c.DB()
				if err != nil {
					t.Fatal(err)
				}
				metaID, err := uuid.NewV7()
				if err != nil {
					t.Fatal(err)
				}
				if _, err := db.Exec(
					`INSERT INTO source_metadata (id, source_id, field_id, value_text) VALUES (?, ?, ?, ?)`,
					metaID[:], src.ID, field.ID, "12",
				); err != nil {
					t.Fatal(err)
				}
				if err := runDelete(c, userID, field.ID); !errors.Is(err, metadatafields.ErrInUse) {
					t.Fatalf("got %v", err)
				}
				if _, err := metadatafields.GetByID(c, field.ID); err != nil {
					t.Fatalf("field gone: %v", err)
				}
			},
		},
		{
			name: "a field a citation format names is in use",
			run: func(t *testing.T, c *database.Catalog) {
				mustUser(t, c)
				field, err := runCreate(c, "Line", metadatafields.DataTypeText, "")
				if err != nil {
					t.Fatal(err)
				}
				mustType := func(label string) []byte {
					id, err := sourcetypestest.Upsert(c, sourcetypes.Type{Key: label, Origin: vocabkey.OriginUser, Label: label})
					if err != nil {
						t.Fatal(err)
					}
					return id
				}
				census, bible := mustType("Census"), mustType("Bible")
				setFormats := func(typeID []byte, in sourcetypes.Formats) {
					t.Helper()
					view, _, err := writes.Run(c, writes.Op{Action: "update_citation_formats", UserID: userID},
						func(tx *database.Tx) (sourcetypes.FormatsView, []rowchange.Change, error) {
							return sourcetypes.UpdateFormats(tx, typeID, in, nil)
						})
					if err != nil || len(view.Diagnostics) != 0 {
						t.Fatalf("set formats: %v %+v", err, view.Diagnostics)
					}
				}
				// Census names the field twice (full and list), Bible once.
				setFormats(census, sourcetypes.Formats{Full: "{source.title}[, line {graph.meta.line}]", List: "{source.meta.line}"})
				setFormats(bible, sourcetypes.Formats{Short: "{graph.meta.line}"})

				impact := func() deleteimpact.Report {
					t.Helper()
					db := dbtest.MustDB(t, c)
					tx, err := db.Begin()
					if err != nil {
						t.Fatal(err)
					}
					defer func() { _ = tx.Rollback() }()
					report, err := deleteimpact.Impact(tx, catalogmodel.KindMetadataField, field.ID)
					if err != nil {
						t.Fatal(err)
					}
					return report
				}
				report := impact()
				if report.Allowed || report.Gate != deleteimpact.GateInbound || len(report.Groups) != 1 {
					t.Fatalf("report %+v", report)
				}
				g := report.Groups[0]
				if g.Via != "source_types.citation_formats" || g.Kind != catalogmodel.KindSourceType || g.Total != 2 || len(g.Listed) != 2 {
					t.Fatalf("group %+v", g)
				}
				for i, want := range [][]byte{bible, census} {
					if !bytes.Equal(g.Listed[i].ID, want) || g.Listed[i].Location.TypeID != database.UUIDString(want) {
						t.Fatalf("listed[%d] = %+v", i, g.Listed[i])
					}
				}
				if err := runDelete(c, userID, field.ID); !errors.Is(err, metadatafields.ErrInUse) {
					t.Fatalf("got %v", err)
				}

				// Values on two Sources add to the count.
				src, _, typeID := fieldHolders(t, c, userID)
				src2, _, err := writes.Run(c, writes.Op{Action: "create_source", UserID: userID}, func(tx *database.Tx) (sources.Source, []rowchange.Change, error) {
					return sources.Create(tx, userID, sources.CreateInput{SourceTypeID: typeID, Title: "U"})
				})
				if err != nil {
					t.Fatal(err)
				}
				db := dbtest.MustDB(t, c)
				for _, sid := range [][]byte{src.ID, src2.ID} {
					id, err := uuid.NewV7()
					if err != nil {
						t.Fatal(err)
					}
					if _, err := db.Exec(`INSERT INTO source_metadata (id, source_id, field_id, value_text) VALUES (?, ?, ?, '1')`,
						id[:], sid, field.ID); err != nil {
						t.Fatal(err)
					}
				}
				report = impact()
				vias := map[string]int{}
				for _, g := range report.Groups {
					vias[g.Via] = g.Total
				}
				if len(vias) != 2 || vias["source_metadata.field_id"] != 2 || vias["source_types.citation_formats"] != 2 {
					t.Fatalf("groups %v", vias)
				}
				if n, err := deleteimpact.UsedBy(c, catalogmodel.KindMetadataField, field.ID); err != nil || n != 4 {
					t.Fatalf("UsedBy = %d, %v; want 4", n, err)
				}
				listed, err := metadatafields.List(c)
				if err != nil {
					t.Fatal(err)
				}
				for _, f := range listed {
					if bytes.Equal(f.ID, field.ID) && f.UsedBy != 4 {
						t.Fatalf("List UsedBy = %d, want 4", f.UsedBy)
					}
				}

				// Clearing the formats and the values frees the field.
				setFormats(census, sourcetypes.Formats{})
				setFormats(bible, sourcetypes.Formats{})
				if _, err := db.Exec(`DELETE FROM source_metadata WHERE field_id = ?`, field.ID); err != nil {
					t.Fatal(err)
				}
				if err := runDelete(c, userID, field.ID); err != nil {
					t.Fatalf("delete after clearing: %v", err)
				}
			},
		},
		{
			name: "a field held only on a graph is in use",
			run: func(t *testing.T, c *database.Catalog) {
				mustUser(t, c)
				src, _, _ := fieldHolders(t, c, userID)
				graphID := insertGraph(t, c, src.ID, "Household")
				field, err := runCreate(c, "Line", metadatafields.DataTypeText, "")
				if err != nil {
					t.Fatal(err)
				}
				db := dbtest.MustDB(t, c)
				id, err := uuid.NewV7()
				if err != nil {
					t.Fatal(err)
				}
				if _, err := db.Exec(`INSERT INTO evidence_graph_metadata (id, graph_id, field_id, value_text) VALUES (?, ?, ?, '14')`,
					id[:], graphID, field.ID); err != nil {
					t.Fatal(err)
				}
				if err := runDelete(c, userID, field.ID); !errors.Is(err, metadatafields.ErrInUse) {
					t.Fatalf("got %v, want ErrInUse", err)
				}
				if _, err := metadatafields.GetByID(c, field.ID); err != nil {
					t.Fatalf("field gone: %v", err)
				}
			},
		},
		{
			name: "a format text past the format cap names no field",
			run: func(t *testing.T, c *database.Catalog) {
				mustUser(t, c)
				field, err := runCreate(c, "Line", metadatafields.DataTypeText, "")
				if err != nil {
					t.Fatal(err)
				}
				typeID, err := sourcetypestest.Upsert(c, sourcetypes.Type{Key: "huge", Origin: vocabkey.OriginUser, Label: "Huge"})
				if err != nil {
					t.Fatal(err)
				}
				u, err := uuid.FromBytes(field.ID)
				if err != nil {
					t.Fatal(err)
				}
				// A text no parse reads (D-6) holds the token past the cap.
				text := strings.Repeat("x", citationformat.MaxFormatBytes) + citationformat.FieldRef{ID: u}.Token()
				db := dbtest.MustDB(t, c)
				if _, err := db.Exec(`UPDATE source_types SET citation_full = ? WHERE id = ?`, text, typeID); err != nil {
					t.Fatal(err)
				}
				if n, err := deleteimpact.UsedBy(c, catalogmodel.KindMetadataField, field.ID); err != nil || n != 0 {
					t.Fatalf("UsedBy = %d, %v; want 0", n, err)
				}
				if err := runDelete(c, userID, field.ID); err != nil {
					t.Fatalf("delete: %v", err)
				}
			},
		},
		{
			name: "a field only dismissed on an Artifact is released audited",
			run: func(t *testing.T, c *database.Catalog) {
				mustUser(t, c)
				_, art, typeID := fieldHolders(t, c, userID)
				field, err := runCreate(c, "Provider", metadatafields.DataTypeText, "")
				if err != nil {
					t.Fatal(err)
				}
				db := dbtest.MustDB(t, c)
				if _, err := db.Exec(`INSERT INTO source_type_metadata_fields (source_type_id, field_id, level, sort_order) VALUES (?, ?, 'artifact', 0)`,
					typeID, field.ID); err != nil {
					t.Fatal(err)
				}
				if _, err := db.Exec(`INSERT INTO artifact_metadata_layout (artifact_id, field_id, sort_order, dismissed) VALUES (?, ?, 0, 1)`,
					art, field.ID); err != nil {
					t.Fatal(err)
				}
				if n, err := deleteimpact.UsedBy(c, catalogmodel.KindMetadataField, field.ID); err != nil || n != 0 {
					t.Fatalf("UsedBy = %d, %v; want 0", n, err)
				}
				var changes []rowchange.Change
				if _, _, err := writes.Run(c, writes.Op{Action: "delete_metadata_field", UserID: userID},
					func(tx *database.Tx) (struct{}, []rowchange.Change, error) {
						var err error
						changes, err = metadatafields.Delete(tx, userID, field.ID)
						return struct{}{}, changes, err
					}); err != nil {
					t.Fatal(err)
				}
				var layout []rowchange.Change
				for _, ch := range changes {
					if ch.EntityType == "artifact_metadata_layout" {
						layout = append(layout, ch)
					}
				}
				if len(layout) != 1 || layout[0].Action != rowchange.ActionDelete ||
					layout[0].Fields["artifact_id"].Old != database.UUIDString(art) ||
					layout[0].Fields["field_id"].Old != database.UUIDString(field.ID) {
					t.Fatalf("layout changes = %+v", layout)
				}
			},
		},
		{
			name: "UsedBy and List count Sources, Artifacts and graphs alike",
			run: func(t *testing.T, c *database.Catalog) {
				mustUser(t, c)
				s1, art, _ := fieldHolders(t, c, userID)
				s2, _, _ := fieldHolders(t, c, userID)
				graphID := insertGraph(t, c, s1.ID, "Household")
				field, err := runCreate(c, "Shelf mark", metadatafields.DataTypeText, "")
				if err != nil {
					t.Fatal(err)
				}
				db := dbtest.MustDB(t, c)
				for _, ins := range []struct {
					query string
					owner []byte
				}{
					{`INSERT INTO source_metadata (id, source_id, field_id, value_text) VALUES (?, ?, ?, 'a')`, s1.ID},
					{`INSERT INTO source_metadata (id, source_id, field_id, value_text) VALUES (?, ?, ?, 'b')`, s2.ID},
					{`INSERT INTO artifact_metadata (id, artifact_id, field_id, value_text) VALUES (?, ?, ?, 'c')`, art},
					{`INSERT INTO evidence_graph_metadata (id, graph_id, field_id, value_text) VALUES (?, ?, ?, 'd')`, graphID},
				} {
					id, err := uuid.NewV7()
					if err != nil {
						t.Fatal(err)
					}
					if _, err := db.Exec(ins.query, id[:], ins.owner, field.ID); err != nil {
						t.Fatal(err)
					}
				}
				if n, err := deleteimpact.UsedBy(c, catalogmodel.KindMetadataField, field.ID); err != nil || n != 4 {
					t.Fatalf("UsedBy = %d, %v; want 4", n, err)
				}
				all, err := metadatafields.List(c)
				if err != nil {
					t.Fatal(err)
				}
				for _, f := range all {
					if bytes.Equal(f.ID, field.ID) && f.UsedBy != 4 {
						t.Fatalf("List UsedBy = %d, want 4", f.UsedBy)
					}
				}
			},
		},
		{
			name: "unused plugin is origin locked",
			run: func(t *testing.T, c *database.Catalog) {
				mustUser(t, c)
				id, err := metadatafieldstest.Upsert(c, metadatafields.Field{
					Key: "memorial_id", Origin: "plugin:findagrave", Label: "Memorial id", DataType: metadatafields.DataTypeText,
				})
				if err != nil {
					t.Fatal(err)
				}
				if err := runDelete(c, userID, id); !errors.Is(err, metadatafields.ErrOriginLocked) {
					t.Fatalf("got %v", err)
				}
				if _, err := metadatafields.GetByID(c, id); err != nil {
					t.Fatalf("field gone: %v", err)
				}
			},
		},
		{
			name: "missing is invalid",
			run: func(t *testing.T, c *database.Catalog) {
				mustUser(t, c)
				missing := make([]byte, 16)
				missing[15] = 9
				if err := runDelete(c, userID, missing); !errors.Is(err, metadatafields.ErrInvalid) {
					t.Fatalf("got %v", err)
				}
			},
		},
		{
			name: "unused field with suggestion and layout still erases",
			run: func(t *testing.T, c *database.Catalog) {
				mustUser(t, c)
				typeID, err := sourcetypestest.Upsert(c, sourcetypes.Type{
					Key: "book", Origin: vocabkey.OriginUser, Label: "Book",
				})
				if err != nil {
					t.Fatal(err)
				}
				src, _, err := writes.Run(c, writes.Op{Action: "create_source", UserID: userID}, func(tx *database.Tx) (sources.Source, []rowchange.Change, error) {
					return sources.Create(tx, userID, sources.CreateInput{SourceTypeID: typeID, Title: "T"})
				})
				if err != nil {
					t.Fatal(err)
				}
				id, err := metadatafieldstest.Upsert(c, metadatafields.Field{
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
					typeID, id,
				); err != nil {
					t.Fatal(err)
				}
				if _, err := db.Exec(
					`INSERT INTO source_metadata_layout (source_id, field_id, sort_order) VALUES (?, ?, 0)`,
					src.ID, id,
				); err != nil {
					t.Fatal(err)
				}
				if err := runDelete(c, userID, id); err != nil {
					t.Fatal(err)
				}
				if _, err := metadatafields.GetByID(c, id); !errors.Is(err, sql.ErrNoRows) {
					t.Fatalf("field still there: %v", err)
				}
				var joins int
				if err := db.QueryRow(
					`SELECT COUNT(*) FROM source_type_metadata_fields WHERE field_id = ?`, id,
				).Scan(&joins); err != nil || joins != 0 {
					t.Fatalf("suggestion leftover %d %v", joins, err)
				}
				if err := db.QueryRow(
					`SELECT COUNT(*) FROM source_metadata_layout WHERE field_id = ?`, id,
				).Scan(&joins); err != nil || joins != 0 {
					t.Fatalf("layout leftover %d %v", joins, err)
				}
				if _, err := sourcetypes.GetByID(c, typeID); err != nil {
					t.Fatalf("type should survive: %v", err)
				}
			},
		},
		{
			name: "bad id",
			run: func(t *testing.T, c *database.Catalog) {
				if err := runDelete(c, userID, []byte{1}); !errors.Is(err, metadatafields.ErrInvalid) {
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
	tests := []struct {
		name string
		run  func(t *testing.T, c *database.Catalog)
	}{
		{
			name: "create mints slug key",
			run: func(t *testing.T, c *database.Catalog) {
				f, err := runCreate(c, "Grandma's album code", metadatafields.DataTypeText, "")
				if err != nil {
					t.Fatal(err)
				}
				if f.Key != "grandmas-album-code" || f.Origin != vocabkey.OriginUser {
					t.Fatalf("got %+v", f)
				}
			},
		},
		{
			name: "create rejects unslugifiable label",
			run: func(t *testing.T, c *database.Catalog) {
				if _, err := runCreate(c, "...", metadatafields.DataTypeText, ""); !errors.Is(err, metadatafields.ErrInvalid) {
					t.Fatalf("got %v", err)
				}
			},
		},
		{
			name: "create rejects duplicate key under user origin",
			run: func(t *testing.T, c *database.Catalog) {
				if _, err := runCreate(c, "Album code", metadatafields.DataTypeText, ""); err != nil {
					t.Fatal(err)
				}
				_, err := runCreate(c, "Album code", metadatafields.DataTypeText, "")
				if !errors.Is(err, metadatafields.ErrDuplicateKey) {
					t.Fatalf("got %v", err)
				}
			},
		},
		{
			name: "same key different origin does not collide",
			run: func(t *testing.T, c *database.Catalog) {
				if _, err := metadatafieldstest.Upsert(c, metadatafields.Field{
					Key: "photographer", Origin: vocabkey.OriginProvenencia, Label: "Photographer", DataType: metadatafields.DataTypeText,
				}); err != nil {
					t.Fatal(err)
				}
				f, err := runCreate(c, "Photographer", metadatafields.DataTypeText, "")
				if err != nil {
					t.Fatal(err)
				}
				if f.Key != "photographer" || f.Origin != vocabkey.OriginUser {
					t.Fatalf("got %+v", f)
				}
			},
		},
		{
			name: "update patches label and description but not key or data type",
			run: func(t *testing.T, c *database.Catalog) {
				created, err := runCreate(c, "Album code", metadatafields.DataTypeText, "old")
				if err != nil {
					t.Fatal(err)
				}
				updated, err := runUpdate(c, created.ID, "Album Code", metadatafields.DataTypeText, "new")
				if err != nil {
					t.Fatal(err)
				}
				if updated.Key != created.Key || updated.Label != "Album Code" ||
					updated.DataType != metadatafields.DataTypeText || updated.Description != "new" {
					t.Fatalf("got %+v", updated)
				}
				got, err := metadatafields.GetByID(c, created.ID)
				if err != nil {
					t.Fatal(err)
				}
				if got.Key != updated.Key || got.Label != updated.Label {
					t.Fatalf("got %+v want %+v", got, updated)
				}
			},
		},
		{
			name: "update rejects data type change",
			run: func(t *testing.T, c *database.Catalog) {
				created, err := runCreate(c, "Album code", metadatafields.DataTypeText, "")
				if err != nil {
					t.Fatal(err)
				}
				if _, err := runUpdate(c, created.ID, "Album code", metadatafields.DataTypeURL, ""); !errors.Is(err, metadatafields.ErrInvalid) {
					t.Fatalf("got %v", err)
				}
			},
		},
		{
			name: "update provenencia field",
			run: func(t *testing.T, c *database.Catalog) {
				id, err := metadatafieldstest.Upsert(c, metadatafields.Field{
					Key: "author", Origin: vocabkey.OriginProvenencia, Label: "Author", DataType: metadatafields.DataTypeText,
				})
				if err != nil {
					t.Fatal(err)
				}
				updated, err := runUpdate(c, id, "Author renamed", metadatafields.DataTypeText, "edited")
				if err != nil {
					t.Fatal(err)
				}
				if updated.Key != "author" || updated.Origin != vocabkey.OriginProvenencia ||
					updated.Label != "Author renamed" || updated.DataType != metadatafields.DataTypeText ||
					updated.Description != "edited" {
					t.Fatalf("got %+v", updated)
				}
			},
		},
		{
			name: "update rejects plugin field",
			run: func(t *testing.T, c *database.Catalog) {
				id, err := metadatafieldstest.Upsert(c, metadatafields.Field{
					Key: "memorial_id", Origin: "plugin:findagrave", Label: "Memorial id", DataType: metadatafields.DataTypeText,
				})
				if err != nil {
					t.Fatal(err)
				}
				if _, err := runUpdate(c, id, "Memorial", metadatafields.DataTypeText, ""); !errors.Is(err, metadatafields.ErrLocked) {
					t.Fatalf("got %v", err)
				}
			},
		},
		{
			name: "update takes the unknown text: absent keeps it, empty clears it",
			run: func(t *testing.T, c *database.Catalog) {
				created, err := runCreate(c, "Place", metadatafields.DataTypeText, "")
				if err != nil {
					t.Fatal(err)
				}
				ptr := func(s string) *string { return &s }
				diff := func(changes []rowchange.Change) (old, new any) {
					t.Helper()
					if len(changes) != 1 || len(changes[0].Fields) != 1 {
						t.Fatalf("changes %+v", changes)
					}
					d, ok := changes[0].Fields["unknown_text"]
					if !ok {
						t.Fatalf("no unknown_text in %+v", changes[0].Fields)
					}
					return d.Old, d.New
				}

				got, changes, err := runUpdateUnknown(c, created.ID, "Place", metadatafields.DataTypeText, "", ptr("  not stated "))
				if err != nil || got.UnknownText != "not stated" {
					t.Fatalf("set = %+v, %v", got, err)
				}
				if old, new := diff(changes); old != nil || new != "not stated" {
					t.Fatalf("set diff %v -> %v", old, new)
				}
				// Every read returns it.
				byID, err := metadatafields.GetByID(c, created.ID)
				if err != nil || byID.UnknownText != "not stated" {
					t.Fatalf("GetByID = %+v, %v", byID, err)
				}
				listed, err := metadatafields.List(c)
				if err != nil {
					t.Fatal(err)
				}
				if i := slices.IndexFunc(listed, func(f metadatafields.Field) bool { return bytes.Equal(f.ID, created.ID) }); i < 0 || listed[i].UnknownText != "not stated" {
					t.Fatalf("List = %+v", listed)
				}
				looked, err := metadatafields.Lookup(c, created.Key, created.Origin)
				if err != nil || looked.UnknownText != "not stated" {
					t.Fatalf("Lookup = %+v, %v", looked, err)
				}
				db, err := c.DB()
				if err != nil {
					t.Fatal(err)
				}
				tx, err := db.Begin()
				if err != nil {
					t.Fatal(err)
				}
				byIDs, err := metadatafields.ListByIDsTx(tx, [][]byte{created.ID})
				_ = tx.Rollback()
				if err != nil || len(byIDs) != 1 || byIDs[0].UnknownText != "not stated" {
					t.Fatalf("ListByIDsTx = %+v, %v", byIDs, err)
				}

				// Absent keeps it.
				got, changes, err = runUpdateUnknown(c, created.ID, "Place", metadatafields.DataTypeText, "", nil)
				if err != nil || got.UnknownText != "not stated" || len(changes) != 0 {
					t.Fatalf("absent = %+v, %v, %+v", got, err, changes)
				}
				// Everything equal is no change.
				if _, changes, err = runUpdateUnknown(c, created.ID, "Place", metadatafields.DataTypeText, "", ptr("not stated")); err != nil || len(changes) != 0 {
					t.Fatalf("equal = %v, %+v", err, changes)
				}
				// Empty clears it.
				got, changes, err = runUpdateUnknown(c, created.ID, "Place", metadatafields.DataTypeText, "", ptr(""))
				if err != nil || got.UnknownText != "" {
					t.Fatalf("clear = %+v, %v", got, err)
				}
				if old, new := diff(changes); old != "not stated" || new != nil {
					t.Fatalf("clear diff %v -> %v", old, new)
				}

				// A delete records the unknown text it held.
				if _, _, err := runUpdateUnknown(c, created.ID, "Place", metadatafields.DataTypeText, "", ptr("n.p.")); err != nil {
					t.Fatal(err)
				}
				var deleted []rowchange.Change
				userID := []byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}
				userRef, err := ref.Mint(ref.PrefixUser)
				if err != nil {
					t.Fatal(err)
				}
				if err := users.Upsert(c, userID, "Jake", userRef); err != nil {
					t.Fatal(err)
				}
				if _, _, err := writes.Run(c, writes.Op{Action: "delete_metadata_field", UserID: userID},
					func(tx *database.Tx) (struct{}, []rowchange.Change, error) {
						var err error
						deleted, err = metadatafields.Delete(tx, userID, created.ID)
						return struct{}{}, deleted, err
					}); err != nil {
					t.Fatal(err)
				}
				last := deleted[len(deleted)-1]
				if d := last.Fields["unknown_text"]; d.Old != "n.p." || d.New != nil {
					t.Fatalf("delete fields %+v", last.Fields)
				}
			},
		},
		{
			name: "get by id missing",
			run: func(t *testing.T, c *database.Catalog) {
				if _, err := metadatafields.GetByID(c, make([]byte, 16)); !errors.Is(err, sql.ErrNoRows) {
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

func TestListByIDsTx(t *testing.T) {
	c, err := database.Create(t.TempDir(), "t.provenencia")
	if err != nil {
		t.Fatal(err)
	}
	defer c.Close()
	a, err := runCreate(c, "Author", metadatafields.DataTypeText, "")
	if err != nil {
		t.Fatal(err)
	}
	b, err := runCreate(c, "Link", metadatafields.DataTypeURL, "")
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

	got, err := metadatafields.ListByIDsTx(tx, [][]byte{a.ID, b.ID, a.ID, make([]byte, 16)})
	if err != nil {
		t.Fatal(err)
	}
	if len(got) != 2 {
		t.Fatalf("got %d fields, want 2: %+v", len(got), got)
	}
	byID := map[string]metadatafields.Field{}
	for _, f := range got {
		byID[string(f.ID)] = f
	}
	if byID[string(a.ID)].Key != "author" || byID[string(b.ID)].DataType != metadatafields.DataTypeURL {
		t.Fatalf("got %+v", got)
	}
	none, err := metadatafields.ListByIDsTx(tx, nil)
	if err != nil || none != nil {
		t.Fatalf("nil ids = %+v, %v", none, err)
	}

	t.Run("reads past one batch", func(t *testing.T) {
		ids := [][]byte{a.ID}
		for i := 0; i < sqlbatch.Size*2+1; i++ {
			unknown := make([]byte, 16)
			binary.BigEndian.PutUint64(unknown[8:], uint64(i+1))
			ids = append(ids, unknown)
		}
		ids = append(ids, b.ID)
		got, err := metadatafields.ListByIDsTx(tx, ids)
		if err != nil {
			t.Fatal(err)
		}
		if len(got) != 2 {
			t.Fatalf("got %d fields, want the 2 known: %+v", len(got), got)
		}
	})
}

func runCreate(c *database.Catalog, label, dataType, description string) (metadatafields.Field, error) {
	got, _, err := writes.Run(c, writes.Op{Action: "create_metadata_field"},
		func(tx *database.Tx) (metadatafields.Field, []rowchange.Change, error) {
			return metadatafields.Create(tx, label, dataType, description)
		})
	return got, err
}

func runUpdate(c *database.Catalog, id []byte, label, dataType, description string) (metadatafields.Field, error) {
	got, _, err := runUpdateUnknown(c, id, label, dataType, description, nil)
	return got, err
}

// runUpdateUnknown is Update with its unknown text, returning the changes it recorded.
func runUpdateUnknown(c *database.Catalog, id []byte, label, dataType, description string, unknownText *string) (metadatafields.Field, []rowchange.Change, error) {
	var changes []rowchange.Change
	got, _, err := writes.Run(c, writes.Op{Action: "update_metadata_field"},
		func(tx *database.Tx) (metadatafields.Field, []rowchange.Change, error) {
			f, ch, err := metadatafields.Update(tx, id, label, dataType, description, unknownText)
			changes = ch
			return f, ch, err
		})
	return got, changes, err
}

func runDelete(c *database.Catalog, userID, id []byte) error {
	_, _, err := writes.Run(c, writes.Op{Action: "delete_metadata_field", UserID: userID},
		func(tx *database.Tx) (struct{}, []rowchange.Change, error) {
			changes, err := metadatafields.Delete(tx, userID, id)
			return struct{}{}, changes, err
		})
	return err
}

// fieldHolders makes a Source of a new type with an Artifact and returns the
// Source, the Artifact id and the type id.
func fieldHolders(t *testing.T, c *database.Catalog, userID []byte) (src sources.Source, artifactID, typeID []byte) {
	t.Helper()
	typeID, err := sourcetypestest.Upsert(c, sourcetypes.Type{Key: "ledger", Origin: vocabkey.OriginUser, Label: "Ledger"})
	if err != nil {
		t.Fatal(err)
	}
	src, _, err = writes.Run(c, writes.Op{Action: "create_source", UserID: userID}, func(tx *database.Tx) (sources.Source, []rowchange.Change, error) {
		return sources.Create(tx, userID, sources.CreateInput{SourceTypeID: typeID, Title: "T"})
	})
	if err != nil {
		t.Fatal(err)
	}
	art, _, err := writes.Run(c, writes.Op{Action: "create_artifact", UserID: userID}, func(tx *database.Tx) (artifacts.Artifact, []rowchange.Change, error) {
		return artifacts.Create(tx, userID, artifacts.CreateInput{SourceID: src.ID, Label: "Page"})
	})
	if err != nil {
		t.Fatal(err)
	}
	return src, art.ID, typeID
}

// insertGraph adds a graph to the Source by SQL and returns its id.
func insertGraph(t *testing.T, c *database.Catalog, sourceID []byte, name string) []byte {
	t.Helper()
	id, err := uuid.NewV7()
	if err != nil {
		t.Fatal(err)
	}
	if _, err := dbtest.MustDB(t, c).Exec(`INSERT INTO evidence_graphs (id, source_id, name) VALUES (?, ?, ?)`, id[:], sourceID, name); err != nil {
		t.Fatal(err)
	}
	return id[:]
}

func TestResolveKeysTx(t *testing.T) {
	c, err := database.Create(t.TempDir(), "t.provenencia")
	if err != nil {
		t.Fatal(err)
	}
	defer c.Close()
	upsert := func(key, origin string) []byte {
		t.Helper()
		id, err := metadatafieldstest.Upsert(c, metadatafields.Field{Key: key, Origin: origin, Label: key, DataType: metadatafields.DataTypeText})
		if err != nil {
			t.Fatal(err)
		}
		return id
	}
	solo := upsert("solo", vocabkey.OriginUser)
	prodShared := upsert("shared", vocabkey.OriginProvenencia)
	userShared := upsert("shared", vocabkey.OriginUser)
	db, err := c.DB()
	if err != nil {
		t.Fatal(err)
	}
	tx, err := db.Begin()
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = tx.Rollback() }()

	tests := []struct {
		name      string
		keys      []string
		prefer    string
		ids       map[string][]byte
		unknown   []string
		ambiguous []string
	}{
		{name: "one holder", keys: []string{"solo"}, ids: map[string][]byte{"solo": solo}},
		{name: "shared without a preference", keys: []string{"shared"}, ambiguous: []string{"shared"}},
		{name: "shared prefers provenencia", keys: []string{"shared"}, prefer: vocabkey.OriginProvenencia,
			ids: map[string][]byte{"shared": prodShared}},
		{name: "shared prefers an origin neither holds", keys: []string{"shared"}, prefer: "plugin:x",
			ambiguous: []string{"shared"}},
		{name: "shared prefers user", keys: []string{"shared"}, prefer: vocabkey.OriginUser,
			ids: map[string][]byte{"shared": userShared}},
		{name: "missing key", keys: []string{"nope", "Solo"}, unknown: []string{"Solo", "nope"}},
		{name: "repeated key", keys: []string{"solo", "solo"}, ids: map[string][]byte{"solo": solo}},
		{name: "nil keys"},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got, err := metadatafields.ResolveKeysTx(tx, tc.keys, tc.prefer)
			if err != nil {
				t.Fatal(err)
			}
			if len(got.IDs) != len(tc.ids) {
				t.Fatalf("ids %v, want %v", got.IDs, tc.ids)
			}
			for k, id := range tc.ids {
				if !bytes.Equal(got.IDs[k], id) {
					t.Fatalf("id of %q = %x, want %x", k, got.IDs[k], id)
				}
			}
			if fmt.Sprint(got.Unknown) != fmt.Sprint(tc.unknown) || fmt.Sprint(got.Ambiguous) != fmt.Sprint(tc.ambiguous) {
				t.Fatalf("unknown %v ambiguous %v, want %v %v", got.Unknown, got.Ambiguous, tc.unknown, tc.ambiguous)
			}
		})
	}
}

func TestUpsertTx(t *testing.T) {
	run := func(t *testing.T, c *database.Catalog, in metadatafields.Field) ([]byte, []rowchange.Change, error) {
		t.Helper()
		var changes []rowchange.Change
		id, err := writes.Call(c, writes.Op{Action: "upsert_metadata_field"}, func(tx *database.Tx) ([]byte, []rowchange.Change, error) {
			id, cs, err := metadatafields.UpsertTx(tx, in)
			changes = cs
			return id, cs, err
		})
		return id, changes, err
	}
	piece := metadatafields.Field{Key: "piece", Origin: vocabkey.OriginProvenencia, Label: "Piece", DataType: metadatafields.DataTypeText}
	only := func(t *testing.T, changes []rowchange.Change, column string) rowchange.FieldDiff {
		t.Helper()
		if len(changes) != 1 || changes[0].Action != rowchange.ActionUpdate || len(changes[0].Fields) != 1 {
			t.Fatalf("want one update of %s, got %+v", column, changes)
		}
		d, ok := changes[0].Fields[column]
		if !ok {
			t.Fatalf("want %s, got %+v", column, changes[0].Fields)
		}
		return d
	}
	tests := []struct {
		name string
		run  func(t *testing.T, c *database.Catalog)
	}{
		{"insert records a create change with Create's keys", func(t *testing.T, c *database.Catalog) {
			in := piece
			in.Description = "Which piece"
			id, changes, err := run(t, c, in)
			if err != nil || len(changes) != 1 || changes[0].Action != rowchange.ActionCreate || changes[0].EntityType != "metadata_field" {
				t.Fatalf("%v %+v", err, changes)
			}
			for _, k := range []string{"id", "key", "origin", "label", "data_type", "description"} {
				if _, ok := changes[0].Fields[k]; !ok {
					t.Fatalf("create change lacks %s: %+v", k, changes[0].Fields)
				}
			}
			if len(changes[0].Fields) != 6 || !bytes.Equal(changes[0].EntityID, id) {
				t.Fatalf("fields %+v", changes[0].Fields)
			}
		}},
		{"the same values change nothing", func(t *testing.T, c *database.Catalog) {
			id, _, err := run(t, c, piece)
			if err != nil {
				t.Fatal(err)
			}
			id2, changes, err := run(t, c, piece)
			if err != nil || len(changes) != 0 || !bytes.Equal(id, id2) {
				t.Fatalf("%v %+v", err, changes)
			}
		}},
		{"unknown text: cleared by an empty input, kept when it matches", func(t *testing.T, c *database.Catalog) {
			in := piece
			in.UnknownText = "n.p."
			if _, _, err := run(t, c, in); err != nil {
				t.Fatal(err)
			}
			in.UnknownText = " n.p. "
			if _, changes, err := run(t, c, in); err != nil || len(changes) != 0 {
				t.Fatalf("%v %+v", err, changes)
			}
			in.UnknownText = ""
			_, changes, err := run(t, c, in)
			if err != nil {
				t.Fatal(err)
			}
			if d := only(t, changes, "unknown_text"); d.Old != "n.p." || d.New != nil {
				t.Fatalf("diff %+v", d)
			}
			got, err := metadatafields.Lookup(c, "piece", vocabkey.OriginProvenencia)
			if err != nil || got.UnknownText != "" {
				t.Fatalf("%v %+v", err, got)
			}
			db, err := c.DB()
			if err != nil {
				t.Fatal(err)
			}
			var isNull bool
			if err := db.QueryRow(`SELECT unknown_text IS NULL FROM source_metadata_fields WHERE id = ?`, got.ID).Scan(&isNull); err != nil || !isNull {
				t.Fatalf("unknown_text not NULL: %v %v", isNull, err)
			}
		}},
		{"a description change is one description diff", func(t *testing.T, c *database.Catalog) {
			if _, _, err := run(t, c, piece); err != nil {
				t.Fatal(err)
			}
			in := piece
			in.Description = "Which piece"
			_, changes, err := run(t, c, in)
			if err != nil {
				t.Fatal(err)
			}
			only(t, changes, "description")
		}},
		{"a data type change is one data_type diff", func(t *testing.T, c *database.Catalog) {
			if _, _, err := run(t, c, piece); err != nil {
				t.Fatal(err)
			}
			in := piece
			in.DataType = metadatafields.DataTypeURL
			_, changes, err := run(t, c, in)
			if err != nil {
				t.Fatal(err)
			}
			if d := only(t, changes, "data_type"); d.Old != "text" || d.New != "url" {
				t.Fatalf("diff %+v", d)
			}
		}},
		{"invalid input writes nothing", func(t *testing.T, c *database.Catalog) {
			for _, in := range []metadatafields.Field{
				{Key: " ", Origin: vocabkey.OriginUser, Label: "X", DataType: "text"},
				{Key: "x", Origin: vocabkey.OriginUser, Label: " ", DataType: "text"},
				{Key: "x", Origin: "bogus", Label: "X", DataType: "text"},
				{Key: "x", Origin: vocabkey.OriginUser, Label: "X", DataType: "number"},
				{ID: make([]byte, 16), Key: "x", Origin: vocabkey.OriginUser, Label: "X", DataType: "text"},
			} {
				if _, _, err := run(t, c, in); !errors.Is(err, metadatafields.ErrInvalid) {
					t.Fatalf("%+v: %v", in, err)
				}
			}
			if fields, err := metadatafields.List(c); err != nil || len(fields) != 0 {
				t.Fatalf("%v %v", fields, err)
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
