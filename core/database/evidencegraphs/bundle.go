package evidencegraphs

import (
	"bytes"
	"slices"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
)

// sqlArtifactSource is the Source an Artifact is on. It sits beside
// sqlLinkSources because artifacts imports this package, not the reverse.
const (
	sqlArtifactSource  = `SELECT source_id FROM artifacts WHERE id = ?`
	sqlSourceArtifacts = `SELECT id FROM artifacts WHERE source_id = ?`
)

// Seed is the one thing a researcher picks to move: exactly one of an Artifact
// or an Evidence graph.
type Seed struct{ ArtifactID, GraphID []byte }

// Valid reports whether exactly one id is set and it is 16 bytes.
func (s Seed) Valid() bool {
	if (len(s.ArtifactID) == 0) == (len(s.GraphID) == 0) {
		return false
	}
	return len(s.ArtifactID) == 16 || len(s.GraphID) == 16
}

// Bundle is what moves together: the closure of a Seed over the graph-Artifact
// links of one Source. A link never joins two Sources, so a bundle never
// spans one.
type Bundle struct {
	SourceID    []byte
	ArtifactIDs [][]byte // ascending id bytes
	GraphIDs    [][]byte // ascending id bytes
	// TakesEveryGraph is true when every graph of SourceID is in GraphIDs.
	TakesEveryGraph bool
}

// BundleOf is the closure of seed: every Artifact linked to a graph in the
// bundle and every graph linked to an Artifact in it, until nothing joins.
// An invalid seed is ErrInvalid; a seed with no row is sql.ErrNoRows.
func BundleOf(q database.Querier, seed Seed) (Bundle, error) {
	if q == nil || !seed.Valid() {
		return Bundle{}, ErrInvalid
	}
	var sourceID []byte
	var err error
	if len(seed.GraphID) != 0 {
		sourceID, err = sourceOf(q, seed.GraphID)
	} else {
		err = q.QueryRow(sqlArtifactSource, seed.ArtifactID).Scan(&sourceID)
	}
	if err != nil {
		return Bundle{}, err
	}
	graphs, err := list(q, sourceID)
	if err != nil {
		return Bundle{}, err
	}

	// A link to an Artifact on another Source can only be in a crafted
	// catalog; the bundle never reaches it, so the move never takes a third
	// Source's Artifact.
	own, err := database.QueryIDs(q, sqlSourceArtifacts, sourceID)
	if err != nil {
		return Bundle{}, err
	}
	ownSet := make(map[string]bool, len(own))
	for _, id := range own {
		ownSet[string(id)] = true
	}

	graphsOf := map[string][]string{}    // Artifact id -> graph ids
	artifactsOf := map[string][]string{} // graph id -> Artifact ids
	for _, g := range graphs {
		for _, a := range g.ArtifactIDs {
			if !ownSet[string(a)] {
				continue
			}
			graphsOf[string(a)] = append(graphsOf[string(a)], string(g.ID))
			artifactsOf[string(g.ID)] = append(artifactsOf[string(g.ID)], string(a))
		}
	}
	seenGraphs, seenArtifacts := map[string]bool{}, map[string]bool{}
	var visit func(artifact bool, id string)
	visit = func(artifact bool, id string) {
		seen, next := seenGraphs, artifactsOf
		if artifact {
			seen, next = seenArtifacts, graphsOf
		}
		if seen[id] {
			return
		}
		seen[id] = true
		for _, n := range next[id] {
			visit(!artifact, n)
		}
	}
	if len(seed.GraphID) != 0 {
		visit(false, string(seed.GraphID))
	} else {
		visit(true, string(seed.ArtifactID))
	}

	out := Bundle{SourceID: sourceID}
	for id := range seenArtifacts {
		out.ArtifactIDs = append(out.ArtifactIDs, []byte(id))
	}
	for id := range seenGraphs {
		out.GraphIDs = append(out.GraphIDs, []byte(id))
	}
	slices.SortFunc(out.ArtifactIDs, bytes.Compare)
	slices.SortFunc(out.GraphIDs, bytes.Compare)
	out.TakesEveryGraph = len(out.GraphIDs) == len(graphs)
	return out, nil
}
