package subjects_test

import (
	"bytes"
	"errors"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencegraphs"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencelayer/evidencelayertest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/subjects"
)

func TestSetSourceTx(t *testing.T) {
	r := evidencelayertest.New(t)
	other, _ := r.NewSource("Other")
	graph := r.Graph(r.Source)
	otherGraph := r.Graph(other)
	p1 := r.Bare(r.Source, "person")
	p2 := r.Bare(r.Source, "person")
	elsewhere := r.Bare(other, "person")

	var changes []rowchange.Change
	r.Run("move", func(tx *database.Tx) ([]rowchange.Change, error) {
		if err := tx.DeferForeignKeys(); err != nil {
			return nil, err
		}
		if _, err := evidencegraphs.SetSourceTx(tx.Tx, [][]byte{graph}, other.ID); err != nil {
			return nil, err
		}
		var err error
		changes, err = subjects.SetSourceTx(tx.Tx, [][]byte{graph, graph, otherGraph}, other.ID)
		return changes, err
	})
	if len(changes) != 2 {
		t.Fatalf("changes %+v", changes)
	}
	if bytes.Compare(changes[0].EntityID, changes[1].EntityID) >= 0 {
		t.Fatal("changes are not in ascending id order")
	}
	for _, c := range changes {
		if c.EntityType != "subject" || c.Action != rowchange.ActionUpdate ||
			c.Fields["source_id"].Old != database.UUIDJSON(r.Source.ID) || c.Fields["source_id"].New != database.UUIDJSON(other.ID) {
			t.Fatalf("change %+v", c)
		}
		if !bytes.Equal(c.EntityID, p1.ID) && !bytes.Equal(c.EntityID, p2.ID) {
			t.Fatalf("change names %x, not a Subject of the graph", c.EntityID)
		}
	}
	got, err := subjects.Get(r.C, p1.ID)
	if err != nil || !bytes.Equal(got.SourceID, other.ID) {
		t.Fatalf("Subject on %x (%v)", got.SourceID, err)
	}
	if got, _ := subjects.Get(r.C, elsewhere.ID); !bytes.Equal(got.SourceID, other.ID) {
		t.Fatal("a Subject already on the target moved")
	}

	r.Run("noop", func(tx *database.Tx) ([]rowchange.Change, error) {
		if ch, err := subjects.SetSourceTx(tx.Tx, nil, other.ID); ch != nil || err != nil {
			t.Fatalf("no graphs: %v %v", ch, err)
		}
		if ch, err := subjects.SetSourceTx(tx.Tx, [][]byte{graph}, other.ID); ch != nil || err != nil {
			t.Fatalf("already there: %v %v", ch, err)
		}
		if _, err := subjects.SetSourceTx(tx.Tx, [][]byte{graph}, other.ID[:3]); !errors.Is(err, subjects.ErrInvalid) {
			t.Fatalf("short source: %v", err)
		}
		return nil, nil
	})
}
