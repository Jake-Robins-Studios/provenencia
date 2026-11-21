package evidencegraphs_test

import (
	"bytes"
	"errors"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/artifacts"
	"github.com/Jake-Robins-Studios/provenencia/core/database/dbtest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencegraphs"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencelayer/evidencelayertest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/subjects"
)

// TestSetSourceTx moves a graph, its Subjects and its Artifact to another
// Source in one write with deferred foreign keys.
func TestSetSourceTx(t *testing.T) {
	r := evidencelayertest.New(t)
	other, _ := r.NewSource("Other")
	graph := r.Graph(r.Source)
	r.Bare(r.Source, "person")
	otherGraph := r.Graph(other)
	missing := make([]byte, 16)
	missing[0] = 9

	var changes []rowchange.Change
	r.Run("move", func(tx *database.Tx) ([]rowchange.Change, error) {
		if err := tx.DeferForeignKeys(); err != nil {
			return nil, err
		}
		g, err := evidencegraphs.SetSourceTx(tx.Tx, [][]byte{graph, graph, missing, otherGraph}, other.ID)
		if err != nil {
			return nil, err
		}
		s, err := subjects.SetSourceTx(tx.Tx, [][]byte{graph, otherGraph}, other.ID)
		if err != nil {
			return nil, err
		}
		a, err := artifacts.SetSourceTx(tx.Tx, [][]byte{r.Artifact.ID}, other.ID)
		if err != nil {
			return nil, err
		}
		changes = append(append(g, s...), a...)
		return changes, nil
	})
	if len(changes) != 3 {
		t.Fatalf("changes %+v", changes)
	}
	c := changes[0]
	if c.EntityType != "evidence_graph" || !bytes.Equal(c.EntityID, graph) || c.Action != rowchange.ActionUpdate {
		t.Fatalf("graph change %+v", c)
	}
	if c.Fields["source_id"].Old != database.UUIDJSON(r.Source.ID) || c.Fields["source_id"].New != database.UUIDJSON(other.ID) {
		t.Fatalf("graph change fields %+v", c.Fields)
	}
	gs, err := evidencegraphs.SourceOf(dbtest.MustDB(t, r.C), graph)
	if err != nil || !bytes.Equal(gs, other.ID) {
		t.Fatalf("graph on %x (%v)", gs, err)
	}

	t.Run("none and invalid", func(t *testing.T) {
		r.Run("noop", func(tx *database.Tx) ([]rowchange.Change, error) {
			ch, err := evidencegraphs.SetSourceTx(tx.Tx, nil, other.ID)
			if err != nil || ch != nil {
				t.Fatalf("no ids: %v %v", ch, err)
			}
			ch, err = evidencegraphs.SetSourceTx(tx.Tx, [][]byte{graph}, other.ID)
			if err != nil || ch != nil {
				t.Fatalf("already there: %v %v", ch, err)
			}
			if _, err := evidencegraphs.SetSourceTx(tx.Tx, [][]byte{graph}, other.ID[:3]); !errors.Is(err, evidencegraphs.ErrInvalid) {
				t.Fatalf("short source: %v", err)
			}
			return nil, nil
		})
	})
}
