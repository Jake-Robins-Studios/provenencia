package evidencegraphs_test

import (
	"bytes"
	"database/sql"
	"errors"
	"slices"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencegraphs"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencegraphs/evidencegraphstest"
)

func sortedIDs(ids ...[]byte) [][]byte {
	out := slices.Clone(ids)
	slices.SortFunc(out, bytes.Compare)
	return out
}

func TestBundleOf(t *testing.T) {
	f := newFixture(t)
	s1, _ := f.createSource(t, "Census 1881")
	other, _ := f.createSource(t, "Parish register")
	def := graphRows(t, f.c, s1.ID)[0].id

	a1 := f.newArtifact(t, s1, "A1")
	a2 := f.newArtifact(t, s1, "A2")
	a3 := f.newArtifact(t, s1, "A3")
	a4 := f.newArtifact(t, s1, "A4")
	a5 := f.newArtifact(t, s1, "A5") // in no graph
	g1 := evidencegraphstest.Create(t, f.c, userID, s1.ID, "G1", a1, a2).ID
	g2 := evidencegraphstest.Create(t, f.c, userID, s1.ID, "G2", a2, a3).ID
	g3 := evidencegraphstest.Create(t, f.c, userID, s1.ID, "G3", a4).ID
	// A second Source with its own linked pair never joins.
	oa := f.newArtifact(t, other, "Other")
	og := evidencegraphstest.Create(t, f.c, userID, other.ID, "OG", oa).ID
	_ = og

	db, err := f.c.DB()
	if err != nil {
		t.Fatal(err)
	}
	rows := []struct {
		name      string
		seed      evidencegraphs.Seed
		artifacts [][]byte
		graphs    [][]byte
		every     bool
	}{
		{"artifact seed closes over graphs", evidencegraphs.Seed{ArtifactID: a1}, sortedIDs(a1, a2, a3), sortedIDs(g1, g2), false},
		{"graph seed gives the same bundle", evidencegraphs.Seed{GraphID: g2}, sortedIDs(a1, a2, a3), sortedIDs(g1, g2), false},
		{"separate bundle", evidencegraphs.Seed{ArtifactID: a4}, sortedIDs(a4), sortedIDs(g3), false},
		{"artifact in no graph", evidencegraphs.Seed{ArtifactID: a5}, sortedIDs(a5), nil, false},
		{"graph with no Artifacts", evidencegraphs.Seed{GraphID: def}, nil, sortedIDs(def), false},
	}
	for _, tt := range rows {
		t.Run(tt.name, func(t *testing.T) {
			b, err := evidencegraphs.BundleOf(db, tt.seed)
			if err != nil {
				t.Fatal(err)
			}
			if !bytes.Equal(b.SourceID, s1.ID) {
				t.Fatalf("source %x", b.SourceID)
			}
			if !slices.EqualFunc(b.ArtifactIDs, tt.artifacts, bytes.Equal) {
				t.Fatalf("artifacts %x want %x", b.ArtifactIDs, tt.artifacts)
			}
			if !slices.EqualFunc(b.GraphIDs, tt.graphs, bytes.Equal) {
				t.Fatalf("graphs %x want %x", b.GraphIDs, tt.graphs)
			}
			if b.TakesEveryGraph != tt.every {
				t.Fatalf("TakesEveryGraph %v", b.TakesEveryGraph)
			}
		})
	}

	t.Run("cycle", func(t *testing.T) {
		// G2 links A2 and A3; link A3 into G1 and A1 into G2 too.
		f.link(t, g1, a3)
		f.link(t, g2, a1)
		b, err := evidencegraphs.BundleOf(db, evidencegraphs.Seed{GraphID: g1})
		if err != nil {
			t.Fatal(err)
		}
		if len(b.GraphIDs) != 2 || len(b.ArtifactIDs) != 3 {
			t.Fatalf("bundle %+v", b)
		}
	})

	t.Run("takes every graph", func(t *testing.T) {
		src, _ := f.createSource(t, "Solo")
		solo := graphRows(t, f.c, src.ID)[0].id
		a := f.newArtifact(t, src, "Scan")
		f.link(t, solo, a)
		b, err := evidencegraphs.BundleOf(db, evidencegraphs.Seed{ArtifactID: a})
		if err != nil {
			t.Fatal(err)
		}
		if !b.TakesEveryGraph {
			t.Fatal("TakesEveryGraph false")
		}
	})

	unknown := make([]byte, 16)
	unknown[0] = 9
	t.Run("missing seed", func(t *testing.T) {
		for _, seed := range []evidencegraphs.Seed{{ArtifactID: unknown}, {GraphID: unknown}} {
			if _, err := evidencegraphs.BundleOf(db, seed); !errors.Is(err, sql.ErrNoRows) {
				t.Fatalf("got %v", err)
			}
		}
	})
	t.Run("invalid seed", func(t *testing.T) {
		for _, seed := range []evidencegraphs.Seed{{}, {ArtifactID: a1, GraphID: g1}, {ArtifactID: a1[:3]}} {
			if _, err := evidencegraphs.BundleOf(db, seed); !errors.Is(err, evidencegraphs.ErrInvalid) {
				t.Fatalf("seed %+v: got %v", seed, err)
			}
		}
	})
}
