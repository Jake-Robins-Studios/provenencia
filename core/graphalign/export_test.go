package graphalign

import (
	"bytes"
	"slices"

	"github.com/Jake-Robins-Studios/provenencia/core/kinship"
)

// NominatedForTest runs Align's procedure and returns the ids of the handles
// the Subject ended with as candidates, sorted.
func NominatedForTest(layer Layer, canon CanonView, fixed []Fixed, cfg Config, subjectID []byte) [][]byte {
	st := run(layer, canon, fixed, cfg)
	var out [][]byte
	for _, c := range st.cands[string(subjectID)] {
		out = append(out, c.handleID)
	}
	slices.SortFunc(out, bytes.Compare)
	return out
}

// Canon is a canon held as lists, for tests. View reads it as a CanonView.
type Canon struct {
	Handles []Handle
	// Edges are the filed links and the links the kinship patterns imply
	// between handles; each Edges entry's Associations are ignored.
	Edges []kinship.Link
	// Candidates are each Subject's shortlisted candidates, by Subject id, in
	// Candidates order.
	Candidates map[string][][]byte
}

// View is the canon as a CanonView. The index is built once; a later change to
// c does not reach it.
func (c Canon) View() CanonView {
	ix := &canonIndex{
		handles:    make(map[string]*Handle, len(c.Handles)),
		links:      map[string][]kinship.Link{},
		candidates: c.Candidates,
	}
	for i := range c.Handles {
		h := &c.Handles[i]
		ix.handles[string(h.ID)] = h
	}
	for _, e := range c.Edges {
		ix.links[string(e.A)] = append(ix.links[string(e.A)], e)
		ix.links[string(e.B)] = append(ix.links[string(e.B)], e)
	}
	return ix
}

// canonIndex is a Canon's handles by id and its links by handle, in edge order.
type canonIndex struct {
	handles    map[string]*Handle
	links      map[string][]kinship.Link
	candidates map[string][][]byte
}

func (ix *canonIndex) Handle(id []byte) *Handle       { return ix.handles[string(id)] }
func (ix *canonIndex) Links(id []byte) []kinship.Link { return ix.links[string(id)] }
func (ix *canonIndex) Candidates(id []byte) [][]byte  { return ix.candidates[string(id)] }
