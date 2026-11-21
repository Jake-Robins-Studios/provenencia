package subjects_test

import (
	"errors"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencegraphs"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencelayer/evidencelayertest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/subjects"
)

// TestSetSourceTx proves the wrapper's entity name and that it is keyed by
// graph id; the shared body is tested by database.TestSetSource. The graph
// moves with its Subjects, so the write defers foreign keys.
func TestSetSourceTx(t *testing.T) {
	r := evidencelayertest.New(t)
	other, _ := r.NewSource("Other")
	graph := r.Graph(r.Source)
	p := r.Bare(r.Source, "person")
	r.Run("move", func(tx *database.Tx) ([]rowchange.Change, error) {
		if err := tx.DeferForeignKeys(); err != nil {
			return nil, err
		}
		if _, err := evidencegraphs.SetSourceTx(tx.Tx, [][]byte{graph}, other.ID); err != nil {
			return nil, err
		}
		changes, err := subjects.SetSourceTx(tx.Tx, [][]byte{graph}, other.ID)
		if err != nil {
			return nil, err
		}
		if len(changes) != 1 || changes[0].EntityType != "subject" || string(changes[0].EntityID) != string(p.ID) ||
			changes[0].Fields["source_id"].Old != database.UUIDJSON(r.Source.ID) || changes[0].Fields["source_id"].New != database.UUIDJSON(other.ID) {
			t.Fatalf("changes %+v", changes)
		}
		if _, err := subjects.SetSourceTx(tx.Tx, [][]byte{graph}, other.ID[:3]); !errors.Is(err, subjects.ErrInvalid) {
			t.Fatalf("short source: %v", err)
		}
		return changes, nil
	})
	if got, err := subjects.Get(r.C, p.ID); err != nil || string(got.SourceID) != string(other.ID) {
		t.Fatalf("Subject on %x (%v)", got.SourceID, err)
	}
}
