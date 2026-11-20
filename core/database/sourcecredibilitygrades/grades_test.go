package sourcecredibilitygrades_test

import (
	"database/sql"
	"errors"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/dbtest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcecredibilitygrades"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcecredibilitygrades/sourcecredibilitygradestest"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
)

// upsert makes a grade through the write pipeline and returns its changes.
func upsert(c *database.Catalog, g sourcecredibilitygrades.Grade) ([]rowchange.Change, error) {
	return writes.Call(c, writes.Op{Action: "upsert_source_credibility_grade"},
		func(tx *database.Tx) ([]rowchange.Change, []rowchange.Change, error) {
			_, changes, err := sourcecredibilitygrades.UpsertTx(tx, g)
			return changes, changes, err
		})
}

func TestGrades(t *testing.T) {
	tests := []struct {
		name string
		run  func(t *testing.T, c *database.Catalog)
	}{
		{
			name: "install seeds three provenencia grades",
			run: func(t *testing.T, c *database.Catalog) {
				if err := sourcecredibilitygradestest.Install(c); err != nil {
					t.Fatal(err)
				}
				list, err := sourcecredibilitygrades.List(c)
				if err != nil {
					t.Fatal(err)
				}
				if len(list) != 3 {
					t.Fatalf("len=%d", len(list))
				}
				if list[0].Key != "low_trust" || list[1].Key != "standard" || list[2].Key != "high_trust" {
					t.Fatalf("order %+v", list)
				}
				std, err := sourcecredibilitygrades.Lookup(c, "standard", vocabkey.OriginProvenencia)
				if err != nil || std.Label != "Standard" || std.SortOrder != 2 {
					t.Fatalf("%v %+v", err, std)
				}
			},
		},
		{
			name: "install is idempotent",
			run: func(t *testing.T, c *database.Catalog) {
				if err := sourcecredibilitygradestest.Install(c); err != nil {
					t.Fatal(err)
				}
				if err := sourcecredibilitygradestest.Install(c); err != nil {
					t.Fatal(err)
				}
				list, err := sourcecredibilitygrades.List(c)
				if err != nil || len(list) != 3 {
					t.Fatalf("%v len=%d", err, len(list))
				}
			},
		},
		{
			name: "reject empty key label",
			run: func(t *testing.T, c *database.Catalog) {
				if _, err := upsert(c, sourcecredibilitygrades.Grade{Key: "", Origin: vocabkey.OriginUser, Label: "X"}); !errors.Is(err, sourcecredibilitygrades.ErrInvalid) {
					t.Fatalf("got %v", err)
				}
				if _, err := upsert(c, sourcecredibilitygrades.Grade{Key: "x", Origin: vocabkey.OriginUser, Label: ""}); !errors.Is(err, sourcecredibilitygrades.ErrInvalid) {
					t.Fatalf("got %v", err)
				}
			},
		},
		{
			name: "upsert changes",
			run: func(t *testing.T, c *database.Catalog) {
				g := sourcecredibilitygrades.Grade{Key: "custom", Origin: vocabkey.OriginProvenencia, Label: "Custom", SortOrder: 7}
				changes, err := upsert(c, g)
				if err != nil || len(changes) != 1 || changes[0].Action != rowchange.ActionCreate || changes[0].EntityType != "source_credibility_grade" {
					t.Fatalf("create: %v %+v", err, changes)
				}
				if changes, err = upsert(c, g); err != nil || len(changes) != 0 {
					t.Fatalf("same: %v %+v", err, changes)
				}
				g.Label = "Renamed"
				changes, err = upsert(c, g)
				if err != nil || len(changes) != 1 || changes[0].Action != rowchange.ActionUpdate || len(changes[0].Fields) != 1 {
					t.Fatalf("label: %v %+v", err, changes)
				}
				if d, ok := changes[0].Fields["label"]; !ok || d.Old != "Custom" || d.New != "Renamed" {
					t.Fatalf("label diff %+v", changes[0].Fields)
				}
				db, err := c.DB()
				if err != nil {
					t.Fatal(err)
				}
				if n := dbtest.Revisions(t, db); n != 0 {
					t.Fatalf("revisions=%d, want 0: a grade write is None", n)
				}
				got, err := sourcecredibilitygrades.Lookup(c, "custom", vocabkey.OriginProvenencia)
				if err != nil || got.Label != "Renamed" {
					t.Fatalf("%v %+v", err, got)
				}
			},
		},
		{
			name: "get missing returns ErrNoRows",
			run: func(t *testing.T, c *database.Catalog) {
				_, err := sourcecredibilitygrades.GetByID(c, make([]byte, 16))
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
