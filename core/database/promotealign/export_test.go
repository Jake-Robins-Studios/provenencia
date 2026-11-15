package promotealign

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"slices"

	"github.com/mendahu/provenencia/core/database"
	"github.com/mendahu/provenencia/core/database/graphcache"
	"github.com/mendahu/provenencia/core/graphalign"
	"github.com/mendahu/provenencia/core/kinship"
	"github.com/mendahu/provenencia/core/shortlist"
	"github.com/mendahu/provenencia/core/subjectcompare"
	"github.com/mendahu/provenencia/core/vocabkey"
)

// HandlesHeldForTest is how many handle profiles the graph's match index holds,
// 0 when it holds none.
func HandlesHeldForTest(g *graphcache.Graph) int {
	m, ok := MatchIndex.Peek(g)
	if !ok {
		return 0
	}
	return len(m.handles)
}

// HandleForTest is the held Subject of a handle, and false when the graph holds
// no match index or the index has no such handle.
func HandleForTest(g *graphcache.Graph, id []byte) (subjectcompare.Subject, bool) {
	m, ok := MatchIndex.Peek(g)
	if !ok {
		return subjectcompare.Subject{}, false
	}
	s, ok := m.handles[string(id)]
	return s, ok
}

// IndexedForTest is the held shortlist index's Find of probe's lookup keys, nil
// when the graph holds no match index.
func IndexedForTest(g *graphcache.Graph, kind string, probe subjectcompare.Values) [][]byte {
	m, ok := MatchIndex.Peek(g)
	if !ok {
		return nil
	}
	k := vocabkey.SubjectType(kind)
	return m.shortlist.Find(k, m.shortlist.LookupKeys(k, probe))
}

// EmptyShortlistForTest replaces the stored shortlist index with one that
// holds no handle, so Verify can fail a test.
func EmptyShortlistForTest(c *database.Catalog) error {
	g := c.Graph()
	p, err := newProfiler(g)
	if err != nil {
		return err
	}
	m, err := matchIndexOf(g)
	if err != nil {
		return err
	}
	MatchIndex.Set(g, &matchIndex{
		handles:   m.handles,
		shortlist: shortlist.NewIndex(p.cfg.Alignment.Shortlist, p.cfg.Subject, p.cfg.Value, p.metas),
	})
	return nil
}

// CandidatesHeldForTest reports whether the candidates entry holds the graph.
func CandidatesHeldForTest(g *graphcache.Graph, graphID []byte) bool {
	_, ok := candidates.Peek(g, graphID)
	return ok
}

// HoldCandidatesForTest stores a candidates memo of subjects person Subjects
// for the graph. Subject i's id is the graph id's first 8 bytes followed by i as
// 8 bytes big-endian; its keys are keysEach strings unique to the graph and the
// Subject; its ranked ids are none. With 0, 0 the memo holds no Subject.
func HoldCandidatesForTest(g *graphcache.Graph, graphID []byte, subjects, keysEach int) {
	by := make(map[string]rankedSubject, subjects)
	for i := 0; i < subjects; i++ {
		id := binary.BigEndian.AppendUint64(bytes.Clone(graphID[:8]), uint64(i))
		keys := make([]string, keysEach)
		for j := range keys {
			keys[j] = fmt.Sprintf("name|w:%x-%d-%d", graphID[:4], i, j)
		}
		by[string(id)] = rankedSubject{kind: vocabkey.Person, keys: keys, ids: [][]byte{}}
	}
	candidates.Set(g, graphID, candidatesMemo{bySubject: by})
}

// HeldSubjectsForTest is the Subject ids the graph's candidates memo holds, an
// empty map when it holds none.
func HeldSubjectsForTest(g *graphcache.Graph, graphID []byte) map[string]bool {
	out := map[string]bool{}
	if memo, ok := candidates.Peek(g, graphID); ok {
		for id := range memo.bySubject {
			out[id] = true
		}
	}
	return out
}

// SetCandidatesCapForTest overrides the candidates entry's Cap on g.
func SetCandidatesCapForTest(g *graphcache.Graph, n int) {
	candidates.SetCapForTest(g, n)
}

// ForgetForTest narrows the candidates as a commit that moved keys in kind
// would, through forgetCandidates.
func ForgetForTest(g *graphcache.Graph, kind string, keys []string) {
	moved := map[movedKey]bool{}
	for _, k := range keys {
		moved[movedKey{vocabkey.SubjectType(kind), k}] = true
	}
	forgetCandidates(g, candidates, moved)
}

// PlaceLinksForTest is the filed-link reader Propose gives Connections.
func PlaceLinksForTest(g *graphcache.Graph) graphalign.FiledLinks { return placeLinks(g) }

// ViewLinksForTest is the links the canon view served one proposal of the
// graph: one entry for each handle Align asked Links for, whatever its length.
func ViewLinksForTest(c *database.Catalog, graphID []byte) (map[string][]kinship.Link, error) {
	in, err := loadInputs(c, graphID)
	if err != nil {
		return nil, err
	}
	_, _, view, err := alignRows(c, in, nil)
	if err != nil {
		return nil, err
	}
	out := make(map[string][]kinship.Link, len(view.links))
	for id, ls := range view.links {
		out[id] = slices.Clone(ls)
	}
	return out, nil
}
