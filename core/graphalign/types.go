// Package graphalign proposes a handle, New, or Skip for every primary
// Subject on one Evidence layer (S9-41). Pure: no catalog I/O. S9-42 loads
// Layer / Canon and calls Align.
package graphalign

import (
	"bytes"

	"github.com/mendahu/provenencia/core/kinship"
	"github.com/mendahu/provenencia/core/subjectcompare"
	"github.com/mendahu/provenencia/core/vocabkey"
)

// Subject is one primary Subject on the Evidence layer.
type Subject = subjectcompare.Subject

// Handle is one canonical entity in the canon: a Subject whose ID is a handle's.
type Handle = subjectcompare.Subject

// Layer is one Source's primary Subjects and bridges, recorded or implied by
// the kinship patterns. A bridge is a kinship.Link; its Edge's Associations are
// the bridge Subjects behind it, which the layers never read.
type Layer struct {
	Subjects []Subject
	Bridges  []kinship.Link
	Metas    subjectcompare.Metas
}

// CanonView is what Align reads of the canonical graph: a handle's profile, the
// links at it and a Subject's shortlisted candidates. Results are the view's
// own and read-only.
type CanonView interface {
	// Handle is the handle's profile, nil when the view does not hold it.
	Handle(id []byte) *Handle
	// Links is every link with id at an end, as stored (not turned to face id),
	// in the view's link order. A link from a handle to itself is listed once.
	// Read a link from id through kinship.Edge.Readings.
	Links(id []byte) []kinship.Link
	// Candidates are the Subject's shortlisted candidate handle ids, in
	// Candidates order.
	Candidates(subjectID []byte) [][]byte
}

// Canon is the part of the canonical graph reachable from the seed handles, as
// lists. View reads it as a CanonView.
type Canon struct {
	Handles []Handle
	// Edges are the filed links and the links the kinship patterns imply
	// between handles; each Edges entry's Associations are ignored.
	Edges []kinship.Link
	// Candidates are each Subject's shortlisted candidates, by Subject id, in
	// Candidates order; the loader fills them.
	Candidates map[string][][]byte
}

// Fixed is a decided or already-promoted row Align holds as given. Target
// empty or TargetHandle anchors SubjectID on HandleID; TargetNew or
// TargetSkip keeps the Subject off every handle, so the walk neither maps it
// nor walks through it.
type Fixed struct {
	SubjectID []byte
	HandleID  []byte
	Target    Target
}

// Target is what Align proposes for one Subject.
type Target string

const (
	TargetHandle Target = "handle"
	TargetNew    Target = "new"
	TargetSkip   Target = "skip"
)

// Assessment is the strong / medium / weak / no-match band.
type Assessment string

const (
	AssessStrong Assessment = "strong"
	AssessMedium Assessment = "medium"
	AssessWeak   Assessment = "weak"
	AssessNone   Assessment = "none"
)

// Via is the layer edge that seeded this row's handle, when the walk
// reached it from an already-decided neighbor.
type Via struct {
	NeighborSubjectID []byte
	Key               vocabkey.BridgeKey
}

// Reason is why a row reads as it does. Codes, not copy: the page words them.
type Reason string

const (
	ReasonVia     Reason = "via"     // reached from a mapped neighbor (Row.Via)
	ReasonDecided Reason = "decided" // held as given (a decision or an existing claim)
	ReasonAgrees  Reason = "agrees"  // property-only match
	ReasonTaken   Reason = "taken"   // another row took the handle (Flags.DuplicateOf)
	ReasonEmpty   Reason = "empty"   // nothing to match on
	// ReasonUnplaced is the zero value: Align placed nothing and nothing else
	// applies; the page says no record is suggested.
	ReasonUnplaced Reason = ""
)

// Move reasons: why settling released a row's earlier pair. They extend Reason
// and appear only in Move.Reason.
const (
	ReasonNeighborPlaced   Reason = "neighbor_placed"   // a neighbor was placed
	ReasonNeighborMoved    Reason = "neighbor_moved"    // a neighbor was placed on another handle than before
	ReasonNeighborReleased Reason = "neighbor_released" // a neighbor was released
)

// Move is why settling released this row's earlier pair: a neighbor was
// placed, moved or released.
type Move struct {
	Reason            Reason
	NeighborSubjectID []byte
}

// Alternative is a handle the researcher can choose, with its score.
type Alternative struct {
	HandleID []byte
	Ref      string
	Score    float64
}

// RowFlags call out conflicts and duplicates for the page.
type RowFlags struct {
	// ConflictWithFixed: a held handle row whose neighbors now point at a
	// clearly stronger handle (Alternatives[0]).
	ConflictWithFixed bool
	// PossibleDuplicate: DuplicateOf may be the same entity as this row. It
	// took the handle this row would have matched, holds the same handle,
	// or both rows would be new records (unplaced or decided New) and score
	// alike.
	PossibleDuplicate bool
	DuplicateOf       []byte
}

// Row is one Subject's proposal.
type Row struct {
	SubjectID []byte
	Kind      string
	// Target is TargetHandle when Align places the Subject; a held decision
	// keeps its TargetNew or TargetSkip; otherwise empty: Align suggests nothing.
	Target       Target
	HandleID     []byte
	HandleRef    string
	Score        float64
	Assessment   Assessment
	Alternatives []Alternative
	Reason       Reason
	Via          *Via
	Flags        RowFlags
	// Move is set when settling released an earlier pair of this row and the
	// row's final target is not that handle.
	Move *Move
}

// Proposal is Align's rows, one per primary Subject, and the caller's connections.
type Proposal struct {
	Rows []Row
	// Connections is each unfiled bridge's outcome (Connections); the caller
	// that loads the bridges fills it after Align.
	Connections []Connection
}

// RowStart is what the page starts a row on: the wire's target, handle_id
// and handle_ref.
type RowStart struct {
	Target   Target
	HandleID []byte
	Ref      string
}

// Start is what the page starts the row on: a placed row's handle when it
// has a band; a held New or Skip as given; an unplaced row's best candidate
// when it is in the weak band and no other row took it; otherwise nothing.
func (r Row) Start() RowStart {
	switch {
	case r.Target == TargetHandle:
		if r.Assessment == AssessNone {
			return RowStart{}
		}
		return RowStart{Target: TargetHandle, HandleID: r.HandleID, Ref: r.HandleRef}
	case r.Target == TargetNew || r.Target == TargetSkip:
		return RowStart{Target: r.Target}
	case r.Reason != ReasonTaken && r.Assessment == AssessWeak && len(r.Alternatives) > 0:
		return RowStart{Target: TargetHandle, HandleID: r.Alternatives[0].HandleID, Ref: r.Alternatives[0].Ref}
	}
	return RowStart{}
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
		if !bytes.Equal(e.A, e.B) {
			ix.links[string(e.B)] = append(ix.links[string(e.B)], e)
		}
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
