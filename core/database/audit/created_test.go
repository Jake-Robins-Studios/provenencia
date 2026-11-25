package audit

import (
	"strings"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/dbtest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/users"
	"github.com/Jake-Robins-Studios/provenencia/core/ref"
)

func TestCreated(t *testing.T) {
	c, err := database.Create(t.TempDir(), "t.provenencia")
	if err != nil {
		t.Fatal(err)
	}
	defer c.Close()
	userID := []byte{16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1}
	r, err := ref.Mint(ref.PrefixUser)
	if err != nil {
		t.Fatal(err)
	}
	if err := users.Upsert(c, userID, "Jake", r); err != nil {
		t.Fatal(err)
	}
	id := func(n byte) []byte {
		b := make([]byte, 16)
		b[15] = n
		return b
	}
	db, err := c.DB()
	if err != nil {
		t.Fatal(err)
	}
	record := func(entityType string, entityID []byte, action, at string, user []byte) {
		t.Helper()
		tx, err := db.Begin()
		if err != nil {
			t.Fatal(err)
		}
		change := rowchange.Change{
			EntityType: entityType, EntityID: entityID, Action: action,
			Fields: map[string]rowchange.FieldDiff{"title": {Old: nil, New: "x"}},
		}
		if action == rowchange.ActionUpdate {
			change.Fields = map[string]rowchange.FieldDiff{"title": {Old: "x", New: "y"}}
		}
		if _, err := recordResolved(t, tx, Revision{UserID: user, ActionType: "t", CreatedAt: at, Changes: []rowchange.Change{change}}); err != nil {
			t.Fatal(err)
		}
		if err := tx.Commit(); err != nil {
			t.Fatal(err)
		}
	}
	record("source", id(1), rowchange.ActionCreate, "2026-01-01T00:00:00Z", userID)
	record("source", id(1), rowchange.ActionUpdate, "2026-02-01T00:00:00Z", userID)
	record("source", id(2), rowchange.ActionCreate, "2026-03-01T00:00:00Z", nil)
	record("source", id(4), rowchange.ActionCreate, "2026-04-01T00:00:00Z", userID)
	record("source", id(4), rowchange.ActionCreate, "2026-05-01T00:00:00Z", nil)
	record("source", id(5), rowchange.ActionUpdate, "2026-06-01T00:00:00Z", userID)
	record("source_note", id(6), rowchange.ActionCreate, "2026-07-01T00:00:00Z", userID)

	got, err := Created(db, "source", [][]byte{id(1), id(2), id(3), id(4), id(5), id(6), id(1), []byte{1}})
	if err != nil {
		t.Fatal(err)
	}
	want := map[string]Creation{
		string(id(1)): {At: "2026-01-01T00:00:00Z", UserDisplayName: "Jake"},
		string(id(2)): {At: "2026-03-01T00:00:00Z"},
		string(id(4)): {At: "2026-04-01T00:00:00Z", UserDisplayName: "Jake"},
	}
	if len(got) != len(want) {
		t.Fatalf("got %v want %v", got, want)
	}
	for k, w := range want {
		if got[k] != w {
			t.Errorf("%x: got %+v want %+v", k, got[k], w)
		}
	}
	none, err := Created(db, "source", nil)
	if err != nil || len(none) != 0 {
		t.Fatalf("empty: %v %v", none, err)
	}
	note, err := Created(db, "source_note", [][]byte{id(6)})
	if err != nil || note[string(id(6))].At != "2026-07-01T00:00:00Z" {
		t.Fatalf("note: %v %v", note, err)
	}
}

// TestCreatedQueryPlan: the create read seeks audit_changes by entity_id through the partial index of
// creates, so it reads each Source's one create and not its whole audit history.
func TestCreatedQueryPlan(t *testing.T) {
	c, err := database.Create(t.TempDir(), "t.provenencia")
	if err != nil {
		t.Fatal(err)
	}
	defer c.Close()
	db, err := c.DB()
	if err != nil {
		t.Fatal(err)
	}
	q := sqlCreated + "?" + sqlCreatedTail
	seeks := false
	for _, detail := range dbtest.QueryPlan(t, db, q, "source", make([]byte, 16)) {
		if strings.Contains(detail, "SEARCH c USING") && strings.Contains(detail, "audit_changes_created_idx") {
			seeks = true
		}
	}
	if !seeks {
		t.Error("query plan does not search audit_changes through audit_changes_created_idx")
	}
}
