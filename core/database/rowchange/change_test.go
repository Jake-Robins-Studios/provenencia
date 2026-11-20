package rowchange

import (
	"encoding/json"
	"reflect"
	"testing"
)

func TestBuilders(t *testing.T) {
	const mary = "aaaaaaaa-bbbb-7ccc-8ddd-eeeeeeeeeeee"
	id := []byte{1, 2}
	tests := []struct {
		name  string
		build func() *Change
		want  *Change
	}{
		{"updated equal", func() *Change { return Updated("e", id, map[string]any{"a": 1}, map[string]any{"a": 1}) }, nil},
		{"updated changed", func() *Change {
			return Updated("e", id, map[string]any{"a": 1, "b": 2}, map[string]any{"a": 1, "b": 3})
		}, &Change{EntityType: "e", EntityID: id, Action: ActionUpdate, Fields: map[string]FieldDiff{"b": {Old: 2, New: 3}}}},
		{"updated only in now", func() *Change { return Updated("e", id, map[string]any{}, map[string]any{"a": "x"}) },
			&Change{EntityType: "e", EntityID: id, Action: ActionUpdate, Fields: map[string]FieldDiff{"a": {Old: nil, New: "x"}}}},
		{"updated only in old", func() *Change { return Updated("e", id, map[string]any{"a": "x"}, map[string]any{}) },
			&Change{EntityType: "e", EntityID: id, Action: ActionUpdate, Fields: map[string]FieldDiff{"a": {Old: "x", New: nil}}}},
		{"updated fixed skipped", func() *Change {
			return Updated("e", id, map[string]any{"id": 1, "a": 1}, map[string]any{"id": 2, "a": 1}, "id")
		}, nil},
		{"updated label", func() *Change {
			return Updated("property", id, map[string]any{"id": 1, "label": "A"}, map[string]any{"id": 1, "label": "B"}, "id")
		}, &Change{EntityType: "property", EntityID: id, Action: ActionUpdate, Fields: map[string]FieldDiff{"label": {Old: "A", New: "B"}}}},
		{"created", func() *Change {
			c := Created("property", id, map[string]any{"id": "a", "label": "Born"})
			return &c
		}, &Change{EntityType: "property", EntityID: id, Action: ActionCreate, Fields: map[string]FieldDiff{"id": {Old: nil, New: "a"}, "label": {Old: nil, New: "Born"}}}},
		{"deleted", func() *Change {
			c := Deleted("observation_note", id, map[string]any{"id": "n", "body": "x"})
			return &c
		}, &Change{EntityType: "observation_note", EntityID: id, Action: ActionDelete, Fields: map[string]FieldDiff{"id": {Old: "n", New: nil}, "body": {Old: "x", New: nil}}}},
		{"created keeps null keys", func() *Change {
			c := Created("e", id, map[string]any{"id": mary, "label": "Mary", "description": nil})
			return &c
		}, &Change{EntityType: "e", EntityID: id, Action: ActionCreate, Fields: map[string]FieldDiff{
			"id": {Old: nil, New: mary}, "label": {Old: nil, New: "Mary"}, "description": {Old: nil, New: nil}}}},
		{"deleted keeps null keys", func() *Change {
			c := Deleted("e", id, map[string]any{"id": mary, "label": "Mary", "description": nil})
			return &c
		}, &Change{EntityType: "e", EntityID: id, Action: ActionDelete, Fields: map[string]FieldDiff{
			"id": {Old: mary, New: nil}, "label": {Old: "Mary", New: nil}, "description": {Old: nil, New: nil}}}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := tt.build()
			if !reflect.DeepEqual(got, tt.want) {
				t.Fatalf("got %+v, want %+v", got, tt.want)
			}
			if got == nil {
				return
			}
			raw, err := json.Marshal(got.Fields)
			if err != nil {
				t.Fatal(err)
			}
			var decoded map[string]FieldDiff
			if err := json.Unmarshal(raw, &decoded); err != nil {
				t.Fatal(err)
			}
			if d, ok := decoded["description"]; ok && (d.Old != nil || d.New != nil) {
				t.Fatalf("description should stay JSON null, got %+v", d)
			}
		})
	}

	t.Run("id copied", func(t *testing.T) {
		own := []byte{1, 2}
		c := Created("e", own, map[string]any{"a": 1})
		own[0] = 9
		if c.EntityID[0] != 1 {
			t.Fatalf("EntityID followed the caller's slice: %v", c.EntityID)
		}
	})
}
