package artifacts_test

import (
	"errors"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/artifacts"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencelayer/evidencelayertest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
)

// TestSetSourceTx proves the wrapper's entity name and key column; the shared
// body is tested by database.TestSetSource.
func TestSetSourceTx(t *testing.T) {
	r := evidencelayertest.New(t)
	other, _ := r.NewSource("Other")
	r.Run("move", func(tx *database.Tx) ([]rowchange.Change, error) {
		changes, err := artifacts.SetSourceTx(tx.Tx, [][]byte{r.Artifact.ID}, other.ID)
		if err != nil {
			return nil, err
		}
		if len(changes) != 1 || changes[0].EntityType != "artifact" || string(changes[0].EntityID) != string(r.Artifact.ID) ||
			changes[0].Fields["source_id"].Old != database.UUIDJSON(r.Source.ID) || changes[0].Fields["source_id"].New != database.UUIDJSON(other.ID) {
			t.Fatalf("changes %+v", changes)
		}
		if _, err := artifacts.SetSourceTx(tx.Tx, [][]byte{r.Artifact.ID}, other.ID[:3]); !errors.Is(err, artifacts.ErrInvalid) {
			t.Fatalf("short source: %v", err)
		}
		return changes, nil
	})
	got, err := artifacts.GetMany(r.C, [][]byte{r.Artifact.ID})
	if err != nil || len(got) != 1 {
		t.Fatalf("GetMany: %v %v", got, err)
	}
	for _, a := range got {
		if string(a.SourceID) != string(other.ID) {
			t.Fatalf("Artifact on %x", a.SourceID)
		}
	}
}
