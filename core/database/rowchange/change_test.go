package rowchange

import (
	"reflect"
	"testing"
)

func TestUpdatedRow(t *testing.T) {
	tests := []struct {
		name  string
		old   map[string]any
		now   map[string]any
		fixed []string
		want  map[string]FieldDiff
	}{
		{"equal", map[string]any{"a": 1}, map[string]any{"a": 1}, nil, map[string]FieldDiff{}},
		{"changed", map[string]any{"a": 1, "b": 2}, map[string]any{"a": 1, "b": 3}, nil, map[string]FieldDiff{"b": {Old: 2, New: 3}}},
		{"only in now", map[string]any{}, map[string]any{"a": "x"}, nil, map[string]FieldDiff{"a": {Old: nil, New: "x"}}},
		{"only in old", map[string]any{"a": "x"}, map[string]any{}, nil, map[string]FieldDiff{"a": {Old: "x", New: nil}}},
		{"fixed skipped", map[string]any{"id": 1, "a": 1}, map[string]any{"id": 2, "a": 1}, []string{"id"}, map[string]FieldDiff{}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := UpdatedRow(tt.old, tt.now, tt.fixed...)
			if !reflect.DeepEqual(got, tt.want) {
				t.Fatalf("got %v, want %v", got, tt.want)
			}
		})
	}
}
