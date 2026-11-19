package dbsql

import (
	"bytes"
	"database/sql"
	"testing"

	_ "github.com/mattn/go-sqlite3"
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

func TestQueryIDs(t *testing.T) {
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	if _, err := db.Exec(`CREATE TABLE t (id BLOB); INSERT INTO t VALUES (x'01'), (x'0203')`); err != nil {
		t.Fatal(err)
	}
	tests := []struct {
		name    string
		query   string
		want    [][]byte
		wantErr bool
	}{
		{"two rows in order", `SELECT id FROM t ORDER BY rowid`, [][]byte{{1}, {2, 3}}, false},
		{"no rows", `SELECT id FROM t WHERE 0`, nil, false},
		{"query error", `SELECT id FROM missing`, nil, true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := QueryIDs(db, tt.query)
			if (err != nil) != tt.wantErr {
				t.Fatalf("err = %v, wantErr %v", err, tt.wantErr)
			}
			if len(got) != len(tt.want) {
				t.Fatalf("got %v, want %v", got, tt.want)
			}
			for i := range got {
				if !bytes.Equal(got[i], tt.want[i]) {
					t.Errorf("row %d = %v, want %v", i, got[i], tt.want[i])
				}
			}
		})
	}
}
