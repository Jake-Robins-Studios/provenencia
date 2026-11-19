package dbsql

import (
	"bytes"
	"testing"
)

func TestSQLInPlaceholders(t *testing.T) {
	tests := []struct {
		n    int
		want string
	}{
		{-1, ""},
		{0, ""},
		{1, "?"},
		{3, "?,?,?"},
	}
	for _, tt := range tests {
		if got := SQLInPlaceholders(tt.n); got != tt.want {
			t.Errorf("SQLInPlaceholders(%d) = %q, want %q", tt.n, got, tt.want)
		}
	}
}

func TestBlobArgs(t *testing.T) {
	a := bytes.Repeat([]byte{1}, 16)
	b := bytes.Repeat([]byte{2}, 16)
	tests := []struct {
		name string
		ids  [][]byte
	}{
		{"nil", nil},
		{"two", [][]byte{a, b}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := BlobArgs(tt.ids)
			if len(got) != len(tt.ids) {
				t.Fatalf("len = %d, want %d", len(got), len(tt.ids))
			}
			for i, g := range got {
				id, ok := g.([]byte)
				if !ok || !bytes.Equal(id, tt.ids[i]) {
					t.Errorf("arg %d = %v, want %v", i, g, tt.ids[i])
				}
			}
		})
	}
}
