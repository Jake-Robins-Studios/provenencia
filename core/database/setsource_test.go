package database

import (
	"bytes"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
)

func TestSetSource(t *testing.T) {
	db, err := openDBURI(":memory:")
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	if _, err := db.Exec(`CREATE TABLE scratch (id BLOB PRIMARY KEY, source_id BLOB NOT NULL)`); err != nil {
		t.Fatal(err)
	}
	id := func(b byte) []byte { return bytes.Repeat([]byte{b}, 16) }
	src, target := id(0xa0), id(0xb0)
	for _, b := range []byte{1, 2, 3} {
		if _, err := db.Exec(`INSERT INTO scratch VALUES (?, ?)`, id(b), src); err != nil {
			t.Fatal(err)
		}
	}
	if _, err := db.Exec(`INSERT INTO scratch VALUES (?, ?)`, id(4), target); err != nil {
		t.Fatal(err)
	}
	tx, err := db.Begin()
	if err != nil {
		t.Fatal(err)
	}
	defer tx.Rollback()
	const selectHead = `SELECT id, source_id FROM scratch WHERE id IN (`
	const updateHead = `UPDATE scratch SET source_id = ? WHERE source_id != ? AND id IN (`

	changes, err := SetSource(tx, "scratch", selectHead, updateHead,
		[][]byte{id(3), id(1), id(3), id(4), id(9), id(2)}, target)
	if err != nil {
		t.Fatal(err)
	}
	if len(changes) != 3 {
		t.Fatalf("changes %+v", changes)
	}
	for i, want := range []byte{1, 2, 3} {
		c := changes[i]
		if !bytes.Equal(c.EntityID, id(want)) || c.EntityType != "scratch" || c.Action != rowchange.ActionUpdate ||
			c.Fields["source_id"].Old != UUIDJSON(src) || c.Fields["source_id"].New != UUIDJSON(target) {
			t.Fatalf("change %d: %+v", i, c)
		}
	}
	var onTarget int
	if err := tx.QueryRow(`SELECT COUNT(*) FROM scratch WHERE source_id = ?`, target).Scan(&onTarget); err != nil || onTarget != 4 {
		t.Fatalf("on target %d, %v", onTarget, err)
	}
	if ch, err := SetSource(tx, "scratch", selectHead, updateHead, [][]byte{id(1)}, target); ch != nil || err != nil {
		t.Fatalf("already there: %v %v", ch, err)
	}
	if ch, err := SetSource(tx, "scratch", selectHead, updateHead, nil, target); ch != nil || err != nil {
		t.Fatalf("no keys: %v %v", ch, err)
	}
	if _, err := SetSource(tx, "scratch", selectHead, updateHead, [][]byte{id(1)}, target[:3]); err == nil {
		t.Fatal("malformed source id accepted")
	}
}
