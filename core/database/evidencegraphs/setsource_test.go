package evidencegraphs_test

import (
	"errors"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/dbtest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencegraphs"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencelayer/evidencelayertest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
)

// TestSetSourceTx proves the wrapper's entity name and key column; the shared
// body is tested by database.TestSetSource.
func TestSetSourceTx(t *testing.T) {
	r := evidencelayertest.New(t)
	other, _ := r.NewSource("Other")
	graph := r.Graph(r.Source)
	r.Run("move", func(tx *database.Tx) ([]rowchange.Change, error) {
		changes, err := evidencegraphs.SetSourceTx(tx.Tx, [][]byte{graph}, other.ID)
		if err != nil {
			return nil, err
		}
		if len(changes) != 1 || changes[0].EntityType != "evidence_graph" || string(changes[0].EntityID) != string(graph) ||
			changes[0].Fields["source_id"].Old != database.UUIDJSON(r.Source.ID) || changes[0].Fields["source_id"].New != database.UUIDJSON(other.ID) {
			t.Fatalf("changes %+v", changes)
		}
		if _, err := evidencegraphs.SetSourceTx(tx.Tx, [][]byte{graph}, other.ID[:3]); !errors.Is(err, evidencegraphs.ErrInvalid) {
			t.Fatalf("short source: %v", err)
		}
		return changes, nil
	})
	if got, err := evidencegraphs.SourceOf(dbtest.MustDB(t, r.C), graph); err != nil || string(got) != string(other.ID) {
		t.Fatalf("graph on %x (%v)", got, err)
	}
}
