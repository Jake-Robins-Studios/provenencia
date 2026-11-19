package sqlbatch_test

import (
	"database/sql"
	"fmt"
	"testing"

	_ "github.com/mattn/go-sqlite3"

	"github.com/Jake-Robins-Studios/provenencia/core/database/sqlbatch"
)

func ids(n int) [][]byte {
	out := make([][]byte, n)
	for i := range out {
		out[i] = []byte(fmt.Sprintf("%016d", i))
	}
	return out
}

func TestEachSlicesAtSize(t *testing.T) {
	var sizes []int
	if err := sqlbatch.Each(ids(2*sqlbatch.Size+1), func(b [][]byte) error {
		sizes = append(sizes, len(b))
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	if fmt.Sprint(sizes) != fmt.Sprint([]int{sqlbatch.Size, sqlbatch.Size, 1}) {
		t.Fatalf("batches %v", sizes)
	}
	called := false
	if err := sqlbatch.Each(nil, func([][]byte) error { called = true; return nil }); err != nil || called {
		t.Fatalf("empty list: called %v, err %v", called, err)
	}
}

// 40,000 ids are past SQLite's bind limit in one statement; Query reads
// them in batches, binding the fixed args before each batch.
func TestQueryReadsPastTheBindLimit(t *testing.T) {
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	db.SetMaxOpenConns(1)
	all := ids(40000)
	if _, err := db.Exec(`CREATE TABLE t (id BLOB PRIMARY KEY, tag TEXT)`); err != nil {
		t.Fatal(err)
	}
	for _, i := range []int{0, 777, 39999} {
		if _, err := db.Exec(`INSERT INTO t VALUES (?, 'x')`, all[i]); err != nil {
			t.Fatal(err)
		}
	}
	if _, err := db.Exec(`INSERT INTO t VALUES (?, 'y')`, all[1]); err != nil {
		t.Fatal(err)
	}
	var got int
	err = sqlbatch.Query(db, `SELECT id FROM t WHERE tag = ? AND id IN (`, `)`, []any{"x"}, all, func(rows *sql.Rows) error {
		var id []byte
		if err := rows.Scan(&id); err != nil {
			return err
		}
		got++
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if got != 3 {
		t.Fatalf("rows %d, want 3", got)
	}
}

// Text keys bind as text, so they match a TEXT column; a blob would not.
func TestQueryBindsStringKeysAsText(t *testing.T) {
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	db.SetMaxOpenConns(1)
	if _, err := db.Exec(`CREATE TABLE t (key TEXT)`); err != nil {
		t.Fatal(err)
	}
	keys := make([]string, 501)
	for i := range keys {
		keys[i] = fmt.Sprintf("key-%d", i)
		if _, err := db.Exec(`INSERT INTO t VALUES (?)`, keys[i]); err != nil {
			t.Fatal(err)
		}
	}
	batches := 0
	var got int
	err = sqlbatch.Query(db, `SELECT key FROM t WHERE key IN (`, `)`, nil, keys, func(rows *sql.Rows) error {
		got++
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	_ = sqlbatch.Each(keys, func([]string) error { batches++; return nil })
	if got != 501 || batches != 2 {
		t.Fatalf("rows %d in %d batches, want 501 in 2", got, batches)
	}
}
