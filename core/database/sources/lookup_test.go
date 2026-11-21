package sources_test

import (
	"errors"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database/dbtest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencelayer/evidencelayertest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sources"
)

func TestLookup(t *testing.T) {
	r := evidencelayertest.New(t)
	db := dbtest.MustDB(t, r.C)
	got, err := sources.Lookup(db, r.Source.ID)
	if err != nil || got.Title != "Register" {
		t.Fatalf("got %+v, %v", got, err)
	}
	missing := make([]byte, 16)
	missing[15] = 9
	if _, err := sources.Lookup(db, missing); !errors.Is(err, sources.ErrNotFound) {
		t.Fatalf("missing: %v", err)
	}
	if _, err := sources.Lookup(db, missing[:3]); !errors.Is(err, sources.ErrInvalid) {
		t.Fatalf("short: %v", err)
	}
}
