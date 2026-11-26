package effects_test

import (
	"bytes"
	"reflect"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/effects"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
)

func id16(b byte) []byte { return bytes.Repeat([]byte{b}, 16) }

func handleDelete(id []byte) rowchange.Change {
	return rowchange.Deleted("canonical_entity", id, map[string]any{"ref": "PER-X", "merged_into_id": nil})
}

func TestResolveReportsDeleted(t *testing.T) {
	h1, h2, h3 := id16(1), id16(2), id16(3)
	claimDelete := rowchange.Deleted("identity_claim", id16(9), map[string]any{"subject_id": id16(8), "entity_id": h1, "status": "accepted"})
	merge := rowchange.Change{
		EntityType: "canonical_entity", EntityID: h2, Action: rowchange.ActionUpdate,
		Fields: map[string]rowchange.FieldDiff{"merged_into_id": {Old: nil, New: h1}},
	}
	create := rowchange.Created("canonical_entity", h3, map[string]any{"ref": "PER-Y"})
	s1, t1 := id16(4), id16(5)
	srcDelete := rowchange.Deleted("source", s1, map[string]any{"title": "a"})
	typeDelete := rowchange.Deleted("source_type", t1, map[string]any{"label": "Deed"})
	srcUpdate := rowchange.Updated("source", s1, map[string]any{"title": "a"}, map[string]any{"title": "b"})
	typeCreate := rowchange.Created("source_type", t1, map[string]any{"label": "Deed"})
	tests := []struct {
		name    string
		changes []rowchange.Change
		want    []effects.DeletedIDs
	}{
		{"a handle delete among other changes", []rowchange.Change{handleDelete(h1), claimDelete, merge}, []effects.DeletedIDs{{Entity: "canonical_entity", IDs: [][]byte{h1}}}},
		{"two deletes in change order", []rowchange.Change{handleDelete(h1), handleDelete(h3)}, []effects.DeletedIDs{{Entity: "canonical_entity", IDs: [][]byte{h1, h3}}}},
		{"the same handle twice is listed once", []rowchange.Change{handleDelete(h1), handleDelete(h1)}, []effects.DeletedIDs{{Entity: "canonical_entity", IDs: [][]byte{h1}}}},
		{"a claim delete, a merge and a create delete no handle", []rowchange.Change{claimDelete, merge, create}, nil},
		{"a Source delete", []rowchange.Change{srcDelete}, []effects.DeletedIDs{{Entity: "source", IDs: [][]byte{s1}}}},
		{"a Source type delete", []rowchange.Change{typeDelete}, []effects.DeletedIDs{{Entity: "source_type", IDs: [][]byte{t1}}}},
		{"a Source update and a Source type create", []rowchange.Change{*srcUpdate, typeCreate}, nil},
		{"a Source delete then a Source type delete", []rowchange.Change{srcDelete, typeDelete},
			[]effects.DeletedIDs{{Entity: "source", IDs: [][]byte{s1}}, {Entity: "source_type", IDs: [][]byte{t1}}}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c, err := database.Create(t.TempDir(), "t.provenencia")
			if err != nil {
				t.Fatal(err)
			}
			t.Cleanup(func() { _ = c.Close() })
			db, err := c.DB()
			if err != nil {
				t.Fatal(err)
			}
			tx, err := db.Begin()
			if err != nil {
				t.Fatal(err)
			}
			defer func() { _ = tx.Rollback() }()
			set, err := effects.Resolve(tx, tt.changes)
			if err != nil {
				t.Fatal(err)
			}
			if !reflect.DeepEqual(set.Deleted, tt.want) {
				t.Fatalf("deleted %x, want %x", set.Deleted, tt.want)
			}
		})
	}
}
