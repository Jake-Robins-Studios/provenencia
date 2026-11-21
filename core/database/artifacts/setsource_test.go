package artifacts_test

import (
	"bytes"
	"errors"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/artifacts"
	"github.com/Jake-Robins-Studios/provenencia/core/database/artifacts/artifactstest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencelayer/evidencelayertest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
)

func TestSetSourceTx(t *testing.T) {
	r := evidencelayertest.New(t)
	other, otherScan := r.NewSource("Other")
	second, err := artifactstest.Create(r.C, evidencelayertest.UserID, artifacts.CreateInput{SourceID: r.Source.ID, Label: "Second"})
	if err != nil {
		t.Fatal(err)
	}
	missing := make([]byte, 16)
	missing[0] = 9

	var changes []rowchange.Change
	r.Run("move", func(tx *database.Tx) ([]rowchange.Change, error) {
		var err error
		changes, err = artifacts.SetSourceTx(tx.Tx, [][]byte{second.ID, r.Artifact.ID, second.ID, missing, otherScan.ID}, other.ID)
		return changes, err
	})
	if len(changes) != 2 {
		t.Fatalf("changes %+v", changes)
	}
	if bytes.Compare(changes[0].EntityID, changes[1].EntityID) >= 0 {
		t.Fatal("changes are not in ascending id order")
	}
	for _, c := range changes {
		if c.EntityType != "artifact" || c.Action != rowchange.ActionUpdate || len(c.Fields) != 1 ||
			c.Fields["source_id"].Old != database.UUIDJSON(r.Source.ID) || c.Fields["source_id"].New != database.UUIDJSON(other.ID) {
			t.Fatalf("change %+v", c)
		}
	}
	got, err := artifacts.GetMany(r.C, [][]byte{second.ID, r.Artifact.ID})
	if err != nil {
		t.Fatal(err)
	}
	for _, a := range got {
		if !bytes.Equal(a.SourceID, other.ID) {
			t.Fatalf("Artifact %s on %x", a.Ref, a.SourceID)
		}
	}

	r.Run("noop", func(tx *database.Tx) ([]rowchange.Change, error) {
		if ch, err := artifacts.SetSourceTx(tx.Tx, nil, other.ID); ch != nil || err != nil {
			t.Fatalf("no ids: %v %v", ch, err)
		}
		if ch, err := artifacts.SetSourceTx(tx.Tx, [][]byte{second.ID}, other.ID); ch != nil || err != nil {
			t.Fatalf("already there: %v %v", ch, err)
		}
		if _, err := artifacts.SetSourceTx(tx.Tx, [][]byte{second.ID}, other.ID[:3]); !errors.Is(err, artifacts.ErrInvalid) {
			t.Fatalf("short source: %v", err)
		}
		return nil, nil
	})
}
