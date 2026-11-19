package promotealign

import (
	"bytes"
	"cmp"
	"errors"
	"reflect"
	"slices"
	"sort"
	"strings"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/effects"
	"github.com/Jake-Robins-Studios/provenencia/core/database/graphcache"
	"github.com/Jake-Robins-Studios/provenencia/core/database/graphfill"
	"github.com/Jake-Robins-Studios/provenencia/core/database/namealiases"
	"github.com/Jake-Robins-Studios/provenencia/core/database/nameformats"
	"github.com/Jake-Robins-Studios/provenencia/core/graphalign"
	"github.com/Jake-Robins-Studios/provenencia/core/shortlist"
	"github.com/Jake-Robins-Studios/provenencia/core/subjectcompare"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

// movedKey is a shortlist key a changed handle was filed under, before or after
// a commit, in the kind it was filed in.
type movedKey struct {
	kind vocabkey.SubjectType
	key  string
}

// matchIndex is what Promote derives from the whole catalog and keeps in the
// MatchIndex entry: the profile of every unmerged person, event and place, and
// the shortlist postings filed from those profiles. Readers treat it as
// read-only; Apply patches it in place.
type matchIndex struct {
	// handles is each handle's Subject by handle id: its ID, Ref, subject type
	// key and full profile Values.
	handles   map[string]subjectcompare.Subject
	shortlist *shortlist.Index
}

// MatchIndex is the registry entry holding the match index. Build makes it
// from every person, event and place handle (promotealign.Warm at open); it is
// derived from the vocabulary, the alias index and the name format.
var MatchIndex graphcache.Whole[*matchIndex]

func init() {
	MatchIndex = graphcache.RegisterWhole(graphcache.WholeEntry[*matchIndex]{
		Name:        "promotealign.matchindex",
		Lifetime:    graphcache.LifeGraph,
		DerivedFrom: []graphcache.Source{graphcache.Vocabulary{}, namealiases.Index, nameformats.Default},
		Build:       buildMatchIndex,
		Apply:       applyMatchIndex,
		Check:       checkMatchIndex,
	})
	candidates = graphcache.RegisterKeyed(graphcache.KeyedEntry[candidatesMemo]{
		Name:        "promotealign.candidates",
		DerivedFrom: []graphcache.Source{MatchIndex},
		Apply:       graphcache.DropNamedGraphs[candidatesMemo],
		Narrow:      forgetCandidates,
		Check:       checkCandidates,
		Cap:         graphfill.MaxEvidenceGraphs,
	})
}

// matchIndexOf is the open catalog's match index, built on the first read; see
// database.ReadWhole for a write's or a nil graph.
func matchIndexOf(g *graphcache.Graph) (*matchIndex, error) {
	return database.ReadWhole(MatchIndex, g)
}

// buildMatchIndex profiles every unmerged person, event and place handle, then
// files the shortlist postings from those profiles in handle id order.
func buildMatchIndex(g *graphcache.Graph) (*matchIndex, error) {
	p, err := newProfiler(g)
	if err != nil {
		return nil, err
	}
	// One batch for every kind: subjects builds events before the people that
	// read their life, whatever order the kinds come in.
	var nodes []*graphcache.Node
	for _, kind := range vocabkey.PrimaryKinds() {
		typeID := p.types[kind]
		if len(typeID) != 16 {
			continue
		}
		ns, err := g.Kind(typeID)
		if err != nil {
			return nil, err
		}
		for _, n := range ns {
			if p.holds(n) {
				nodes = append(nodes, n)
			}
		}
	}
	handles := make(map[string]subjectcompare.Subject, len(nodes))
	if err := p.subjects(nodes, handles); err != nil {
		return nil, err
	}
	ix := shortlist.NewIndex(p.cfg.Alignment.Shortlist, p.cfg.Subject, p.cfg.Value, p.metas)
	ids := make([]string, 0, len(handles))
	for id := range handles {
		ids = append(ids, id)
	}
	sort.Strings(ids)
	for _, id := range ids {
		s := handles[id]
		ix.Put(vocabkey.SubjectType(s.Kind), s.ID, s.Values)
	}
	return &matchIndex{handles: handles, shortlist: ix}, nil
}

// applyMatchIndex patches the held index after a commit: it re-profiles the
// commit's roots and the people at the root events (readers), drops the handles
// that left (a merged, deleted or non-primary node), and refiles only the
// handles whose profile changed. It reports the keys every changed handle was
// filed under, before and after, to its readers with Patched. A commit with no
// roots changes nothing a profile reads.
func applyMatchIndex(g *graphcache.Graph, w graphcache.Whole[*matchIndex], roots [][]byte, _ effects.Set) error {
	if len(roots) == 0 {
		return nil
	}
	m, err := matchIndexOf(g)
	if err != nil {
		return err
	}
	p, err := newProfiler(g)
	if err != nil {
		return err
	}
	// The roots load first: readers classifies them by their nodes.
	if err := g.Nodes(roots); err != nil {
		return err
	}
	more, err := p.readers(roots)
	if err != nil {
		return err
	}
	if err := g.Nodes(more); err != nil {
		return err
	}
	var live []*graphcache.Node
	liveIDs := map[string]bool{}
	changed := false
	moved := map[movedKey]bool{}
	// addFiled adds the keys id is filed under now, if any.
	addFiled := func(id []byte) {
		if kind, keys, ok := m.shortlist.Filed(id); ok {
			for _, k := range keys {
				moved[movedKey{kind, k}] = true
			}
		}
	}
	for _, id := range append(slices.Clone(roots), more...) {
		if liveIDs[string(id)] {
			continue
		}
		n, err := g.Node(id)
		if err != nil {
			return err
		}
		if !p.holds(n) {
			if _, held := m.handles[string(id)]; held {
				addFiled(id)
				delete(m.handles, string(id))
				m.shortlist.Remove(id)
				changed = true
			}
			continue
		}
		liveIDs[string(id)] = true
		live = append(live, n)
	}
	old := make(map[string]subjectcompare.Subject, len(live))
	for _, n := range live {
		if s, ok := m.handles[string(n.ID)]; ok {
			old[string(n.ID)] = s
		}
	}
	// subjects builds events before the people that read their life.
	if err := p.subjects(live, m.handles); err != nil {
		return err
	}
	for _, n := range live {
		s := m.handles[string(n.ID)]
		if was, ok := old[string(n.ID)]; ok && reflect.DeepEqual(s, was) {
			continue
		}
		addFiled(s.ID)
		m.shortlist.Put(vocabkey.SubjectType(s.Kind), s.ID, s.Values)
		addFiled(s.ID)
		changed = true
	}
	if changed {
		w.Patched(g, moved)
	}
	return nil
}

// checkMatchIndex compares the stored index with a fresh build.
func checkMatchIndex(g *graphcache.Graph, stored *matchIndex) error {
	fresh, err := buildMatchIndex(g)
	if err != nil {
		return err
	}
	if !reflect.DeepEqual(stored.handles, fresh.handles) {
		return errors.New("promotealign: the stored handle profiles do not match a fresh build")
	}
	if !reflect.DeepEqual(stored.shortlist, fresh.shortlist) {
		return errors.New("promotealign: the stored shortlist index does not match a fresh build")
	}
	return nil
}

// Warm builds the match index, so the first proposal after a project opens
// ranks without building it.
func Warm(c *database.Catalog) error {
	if _, err := c.DB(); err != nil {
		return err
	}
	_, err := matchIndexOf(c.Graph())
	return err
}

// seedHandles is the handles the index offers one Subject, read from the match
// index: those filed under any of its lookup keys, in Ref then ID order.
func seedHandles(m *matchIndex, kind vocabkey.SubjectType, keys []string) []graphalign.Handle {
	var out []graphalign.Handle
	for _, id := range m.shortlist.Find(kind, keys) {
		if h, ok := m.handles[string(id)]; ok {
			out = append(out, h)
		}
	}
	slices.SortFunc(out, func(a, b graphalign.Handle) int {
		return cmp.Or(strings.Compare(a.Ref, b.Ref), bytes.Compare(a.ID, b.ID))
	})
	return out
}
