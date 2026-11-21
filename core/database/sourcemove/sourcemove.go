// Package sourcemove moves an Artifact or an Evidence graph to another Source
// in one write, with everything that must travel with it: the bundle, the
// closure of the picked Artifact or graph over the graph-Artifact links of its
// Source (evidencegraphs.BundleOf).
//
// A move changes only source_id, on artifacts, evidence_graphs and subjects.
// Every row keeps its id and ref, so Citations, Observations, identity claims,
// regions and metadata stay attached; Source-level values (metadata, title,
// date, credibility) are not read, copied or compared, except the two
// credibility grades Impact reports. A Subject of type source (a reification)
// moves with its graph like every Subject.
//
// The composite key subjects (graph_id, source_id) -> evidence_graphs
// (id, source_id) cannot be updated one side at a time, so Move defers foreign
// keys: the check runs at commit, when every Subject has followed its graph.
//
// Move composes owner-package calls inside the caller's writes.Run and never
// calls writes.Run itself, like sourcecopy.
package sourcemove

import (
	"bytes"
	"database/sql"
	"errors"
	"fmt"

	"github.com/Jake-Robins-Studios/provenencia/core/apperr"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/artifacts"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencegraphs"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sources"
	"github.com/Jake-Robins-Studios/provenencia/core/database/subjects"
)

var (
	// ErrInvalid: no seed, two seeds, an empty target, the target is the
	// bundle's own Source, or no user.
	ErrInvalid = apperr.New(apperr.CodeSourceMoveInvalid, apperr.KindUser)
	// ErrNotFound: the picked Artifact or graph is gone.
	ErrNotFound = apperr.New(apperr.CodeSourceMoveNotFound, apperr.KindNotFound)
)

// resolve holds every refusal, for the preflight and the write alike. An empty
// targetID skips the target checks.
func resolve(q database.Querier, seed evidencegraphs.Seed, targetID []byte) (evidencegraphs.Bundle, error) {
	if !seed.Valid() {
		return evidencegraphs.Bundle{}, ErrInvalid
	}
	bundle, err := evidencegraphs.BundleOf(q, seed)
	if errors.Is(err, sql.ErrNoRows) {
		return evidencegraphs.Bundle{}, ErrNotFound
	}
	if err != nil {
		return evidencegraphs.Bundle{}, err
	}
	if len(targetID) == 0 {
		return bundle, nil
	}
	if len(targetID) != 16 {
		return evidencegraphs.Bundle{}, ErrInvalid
	}
	if _, err := sources.Lookup(q, targetID); err != nil {
		return evidencegraphs.Bundle{}, err
	}
	if bytes.Equal(targetID, bundle.SourceID) {
		return evidencegraphs.Bundle{}, ErrInvalid
	}
	return bundle, nil
}

// Report is what a move would move and what it would leave.
type Report struct {
	Bundle    evidencegraphs.Bundle
	Artifacts []artifacts.Artifact      // ListBySource order
	Graphs    []evidencegraphs.Graph    // the index's list order; ArtifactIDs read-only
	Progress  []evidencegraphs.Progress // one per graph, same order
	// The two Sources' credibility grade keys, "" when not assessed (or, for
	// the target, when no target was given).
	SourceCredibilityKey string
	TargetCredibilityKey string
	// CredibilityDiffers: the two grades score differently, so Conclusions can
	// re-rank. Not assessed and "standard" score alike.
	CredibilityDiffers bool
	LeavesSourceEmpty  bool // every Artifact of the Source moves
	LeavesNoGraph      bool // every graph moves; the Source gets a new Default graph
}

// Impact reads what moving the seed's bundle would move. targetID is optional:
// without it there is no credibility comparison and no same-Source check.
func Impact(c *database.Catalog, seed evidencegraphs.Seed, targetID []byte) (Report, error) {
	db, err := c.DB()
	if err != nil {
		return Report{}, err
	}
	bundle, err := resolve(db, seed, targetID)
	if err != nil {
		return Report{}, err
	}
	rep := Report{Bundle: bundle, LeavesNoGraph: bundle.TakesEveryGraph}

	inBundle := func(ids [][]byte) map[string]bool {
		m := make(map[string]bool, len(ids))
		for _, id := range ids {
			m[string(id)] = true
		}
		return m
	}
	moving := inBundle(bundle.ArtifactIDs)
	all, err := artifacts.ListBySource(c, bundle.SourceID)
	if err != nil {
		return Report{}, err
	}
	for _, a := range all {
		if moving[string(a.ID)] {
			rep.Artifacts = append(rep.Artifacts, a)
		}
	}
	rep.LeavesSourceEmpty = len(all) == len(rep.Artifacts)

	idx, err := evidencegraphs.IndexOf(c.Graph())
	if err != nil {
		return Report{}, err
	}
	movingGraphs := inBundle(bundle.GraphIDs)
	for _, g := range idx.OfSource(bundle.SourceID) {
		if movingGraphs[string(g.ID)] {
			rep.Graphs = append(rep.Graphs, g)
			rep.Progress = append(rep.Progress, idx.Progress(g.ID))
		}
	}
	if len(rep.Graphs) != len(bundle.GraphIDs) {
		return Report{}, fmt.Errorf("sourcemove: %d of %d bundle graphs are in the graph index", len(rep.Graphs), len(bundle.GraphIDs))
	}

	if len(targetID) == 0 {
		return rep, nil
	}
	recs, err := sources.RecordsOf(c.Graph())
	if err != nil {
		return Report{}, err
	}
	from, ok := recs.Source(bundle.SourceID)
	if !ok {
		return Report{}, fmt.Errorf("sourcemove: Source %x is not in the Source records", bundle.SourceID)
	}
	to, ok := recs.Source(targetID)
	if !ok {
		return Report{}, fmt.Errorf("sourcemove: Source %x is not in the Source records", targetID)
	}
	rep.SourceCredibilityKey, rep.TargetCredibilityKey = from.CredibilityKey, to.CredibilityKey
	rep.CredibilityDiffers = from.Credibility != to.Credibility
	return rep, nil
}

// Result is what Move moved.
type Result struct {
	Bundle         evidencegraphs.Bundle
	DefaultGraphID []byte // nil unless the old Source got a new Default graph
}

// Move moves the seed's bundle to targetID. When the old Source's cover is a
// moved Artifact the cover reverts to the type icon; when every graph moves,
// the old Source gets a new Default graph, so it keeps at least one. The
// emptied Source is never deleted. The caller records the changes.
func Move(tx *database.Tx, userID []byte, seed evidencegraphs.Seed, targetID []byte) (Result, []rowchange.Change, error) {
	if tx == nil {
		return Result{}, nil, ErrInvalid
	}
	if err := database.RequireUserID(userID, ErrInvalid); err != nil {
		return Result{}, nil, err
	}
	if len(targetID) == 0 {
		return Result{}, nil, ErrInvalid
	}
	bundle, err := resolve(tx.Tx, seed, targetID)
	if err != nil {
		return Result{}, nil, err
	}
	old, err := sources.GetTx(tx.Tx, bundle.SourceID)
	if err != nil {
		return Result{}, nil, err
	}
	if err := tx.DeferForeignKeys(); err != nil {
		return Result{}, nil, err
	}
	res := Result{Bundle: bundle}
	var changes []rowchange.Change
	step := func(ch []rowchange.Change, err error) error {
		changes = append(changes, ch...)
		return err
	}
	if err := step(evidencegraphs.SetSourceTx(tx.Tx, bundle.GraphIDs, targetID)); err != nil {
		return Result{}, nil, err
	}
	if err := step(subjects.SetSourceTx(tx.Tx, bundle.GraphIDs, targetID)); err != nil {
		return Result{}, nil, err
	}
	if err := step(artifacts.SetSourceTx(tx.Tx, bundle.ArtifactIDs, targetID)); err != nil {
		return Result{}, nil, err
	}
	if len(old.PrimaryArtifactID) == 16 && database.ContainsBlobID(bundle.ArtifactIDs, old.PrimaryArtifactID) {
		_, ch, err := sources.SetCover(tx, userID, old.ID, sources.CoverModeTypeIcon, nil)
		if err := step(ch, err); err != nil {
			return Result{}, nil, err
		}
	}
	if bundle.TakesEveryGraph {
		g, ch, err := evidencegraphs.CreateDefault(tx, old.ID)
		if err := step(ch, err); err != nil {
			return Result{}, nil, err
		}
		res.DefaultGraphID = g.ID
	}
	return res, changes, nil
}
