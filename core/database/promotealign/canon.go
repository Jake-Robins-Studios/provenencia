package promotealign

import (
	"bytes"
	"errors"
	"fmt"
	"maps"
	"reflect"
	"slices"
	"sort"

	"github.com/mendahu/provenencia/core/database/canonlinks"
	"github.com/mendahu/provenencia/core/database/evidencelayer"
	"github.com/mendahu/provenencia/core/database/graphcache"
	"github.com/mendahu/provenencia/core/graphalign"
	"github.com/mendahu/provenencia/core/kinship"
	"github.com/mendahu/provenencia/core/segmentcompare"
	"github.com/mendahu/provenencia/core/vocabkey"
)

// candidatesMemo is the ranking of each Subject the graph's Evidence graph has
// had ranked. Candidates depend on the Subject's values, the handles' profiles
// and the shortlist index, which the match index holds, so the entry is derived
// from it. A stored memo is never changed.
type candidatesMemo struct {
	bySubject map[string]rankedSubject
}

// rankedSubject is one ranked Subject: its kind, the shortlist lookup keys the
// ranking read (a commit that moves one of them forgets the Subject), and the
// candidate handle ids, in order ([][]byte{} for none).
type rankedSubject struct {
	kind vocabkey.SubjectType
	keys []string // Index.LookupKeys
	ids  [][]byte
}

// candidates holds each Evidence graph's candidatesMemo, keyed by graph id. It
// is emptied when the match index is dropped (a vocabulary, alias or name format
// change, or Drop); a commit that changes a handle forgets, through Narrow, the
// Subjects whose lookup keys meet a key that handle was filed under; a write that
// names a graph (Set.EvidenceGraphs) drops that graph's memo. It is registered
// in index.go's init, after the match index.
var candidates graphcache.Keyed[candidatesMemo]

// loadCanon reads the open catalog's graph: fixed anchors, the candidates of
// each unfixed Subject (loadCandidatesMemo), then every link those handles
// have. Link order is association ref, then the neighbor's ref, which is the
// order the walk used to break ties. Every handle's profile is the match
// index's, so nothing is built here. Recorded
// links come from the walk and implied ones from canonlinks.Reader.For, which
// composes them from the graph cache's kinship pivots for each walked person; both go
// through one kinship.LinkSet, so a link read from either end or recorded
// both ways merges, and the implied links follow the recorded ones in walk
// order.
func loadCanon(g *graphcache.Graph, graphID []byte, m *matchIndex, layer graphalign.Layer, fixed []graphalign.Fixed, cfg graphalign.Config, terms segmentcompare.Terms) (graphalign.Canon, error) {
	vocab, err := g.Vocabulary()
	if err != nil {
		return graphalign.Canon{}, err
	}
	eventTypeProp := vocab.PropertyID(vocabkey.PropertyEventType, vocabkey.OriginProvenencia)
	handles := map[string]*graphcache.Node{}
	var seeds [][]byte
	candidates := map[string][][]byte{}
	add := func(id []byte) error {
		if len(id) != 16 {
			return nil
		}
		if _, ok := handles[string(id)]; ok {
			seeds = append(seeds, id)
			return nil
		}
		n, err := g.Node(id)
		if err != nil || n == nil || n.Merged {
			return err
		}
		if _, ok := m.handles[string(id)]; !ok {
			return nil
		}
		handles[string(id)] = n
		seeds = append(seeds, id)
		return nil
	}

	for _, f := range fixed {
		if len(f.HandleID) == 16 {
			if err := add(f.HandleID); err != nil {
				return graphalign.Canon{}, err
			}
		}
	}

	fixedSubjects := map[string]bool{}
	for _, f := range fixed {
		fixedSubjects[string(f.SubjectID)] = true
	}
	var todo []graphalign.Subject
	for _, s := range layer.Subjects {
		if fixedSubjects[string(s.ID)] {
			continue
		}
		if _, ok := cfg.Subject.Weights[vocabkey.SubjectType(s.Kind)]; !ok {
			continue
		}
		todo = append(todo, s)
	}
	if len(todo) > 0 {
		known, err := loadCandidatesMemo(g, graphID, m, layer, todo, cfg)
		if err != nil {
			return graphalign.Canon{}, err
		}
		for _, s := range todo {
			for _, id := range known[string(s.ID)].ids {
				candidates[string(s.ID)] = append(candidates[string(s.ID)], id)
				if err := add(id); err != nil {
					return graphalign.Canon{}, err
				}
			}
		}
	}

	sort.SliceStable(seeds, func(i, j int) bool {
		return handles[string(seeds[i])].Ref < handles[string(seeds[j])].Ref
	})

	reader, err := canonlinks.NewReader(g)
	if err != nil {
		return graphalign.Canon{}, err
	}
	set := kinship.NewLinkSet()
	var walkedPeople [][]byte
	walked := map[string]bool{}
	queue := append([][]byte(nil), seeds...)
	for len(queue) > 0 {
		wave := queue
		queue = nil
		type reached struct {
			id []byte
			n  *graphcache.Node
		}
		var ready []reached
		var prefetch [][]byte
		for _, id := range wave {
			if walked[string(id)] {
				continue
			}
			walked[string(id)] = true
			if m.handles[string(id)].Kind == vocabkey.Person {
				walkedPeople = append(walkedPeople, id)
			}
			n, err := g.Node(id)
			if err != nil {
				return graphalign.Canon{}, err
			}
			if n == nil {
				continue
			}
			ready = append(ready, reached{id, n})
			for _, l := range n.Links {
				prefetch = append(prefetch, l.Neighbor)
			}
		}
		if err := g.Nodes(prefetch); err != nil {
			return graphalign.Canon{}, err
		}
		for _, item := range ready {
			id, n := item.id, item.n
			for _, l := range n.Links {
				neighbor, err := g.Node(l.Neighbor)
				if err != nil {
					return graphalign.Canon{}, err
				}
				if neighbor == nil || neighbor.Merged {
					continue
				}
				if _, primary := m.handles[string(neighbor.ID)]; !primary {
					continue
				}
				if from, to, keyFrom, keyTo, ok := canonlinks.EdgeOf(id, n, l, neighbor, eventTypeProp, terms); ok {
					set.Add(kinship.Link{Edge: kinship.Edge{A: from, B: to, KeyA: keyFrom, KeyB: keyTo}})
				}
				if _, ok := handles[string(neighbor.ID)]; !ok {
					handles[string(neighbor.ID)] = neighbor
					queue = append(queue, neighbor.ID)
				}
			}
		}
	}

	// The implied links are collected before any edge is built. Every link is
	// walked from both ends and each end's call returns it, so only the call
	// of its A end adds it.
	var implied []kinship.Implied
	for _, id := range walkedPeople {
		links, err := reader.For(id)
		if err != nil {
			return graphalign.Canon{}, err
		}
		for _, imp := range links {
			if !bytes.Equal(imp.A, id) {
				continue
			}
			_, aOK := handles[string(imp.A)]
			_, bOK := handles[string(imp.B)]
			if aOK && bOK {
				implied = append(implied, imp)
			}
		}
	}
	// Walked links first, in walk order. An implied link that shares ends and
	// keys with a walked or earlier implied one merges into it; the rest follow
	// in order. The implied links are the cache's, so an edge copies what it keeps.
	edges := slices.Clone(set.Links())
	for i, at := range set.PlaceImplied(implied) {
		imp := implied[i]
		rec := imp.Recording()
		if at < len(edges) {
			edges[at].Recording.Merge(rec)
			continue
		}
		edges = append(edges, kinship.Link{
			Edge:      kinship.Edge{A: bytes.Clone(imp.A), B: bytes.Clone(imp.B), KeyA: imp.KeyA, KeyB: imp.KeyB},
			Recording: rec.Clone(),
		})
	}

	// The handles are the entry's Subjects, shared: graphalign reads a Handle
	// and never writes it.
	out := graphalign.Canon{Edges: edges, Candidates: candidates}
	for id := range handles {
		out.Handles = append(out.Handles, m.handles[id])
	}
	sort.Slice(out.Handles, func(i, j int) bool {
		if out.Handles[i].Ref != out.Handles[j].Ref {
			return out.Handles[i].Ref < out.Handles[j].Ref
		}
		return bytes.Compare(out.Handles[i].ID, out.Handles[j].ID) < 0
	})
	return out, nil
}

// canonView is the canon one proposal reads, one handle at a time (S16-22): a
// handle's profile from the match index, its links from the canonlinks.Reader
// over the graph cache's nodes and kinship pivots, and each unfixed Subject's
// candidates from the candidates entry. It lives for one proposal and holds no
// answer past it. A read error is held in err and serves nothing after it;
// Propose returns it.
type canonView struct {
	m       *matchIndex
	reader  *canonlinks.Reader
	ranked  map[string][][]byte
	handles map[string]*graphalign.Handle
	links   map[string][]kinship.Link
	err     error
}

// newCanonView ranks the candidates of each layer Subject that is not fixed
// (loadCandidatesMemo) and opens the link reader. evidencelayer.Load keeps only
// Subjects of a kind the rules weigh, and Align's seed checks again.
func newCanonView(g *graphcache.Graph, graphID []byte, m *matchIndex, layer graphalign.Layer, fixed []graphalign.Fixed, cfg graphalign.Config) (*canonView, error) {
	fixedSubjects := map[string]bool{}
	for _, f := range fixed {
		fixedSubjects[string(f.SubjectID)] = true
	}
	var todo []graphalign.Subject
	for _, s := range layer.Subjects {
		if !fixedSubjects[string(s.ID)] {
			todo = append(todo, s)
		}
	}
	ranked := map[string][][]byte{}
	if len(todo) > 0 {
		known, err := loadCandidatesMemo(g, graphID, m, layer, todo, cfg)
		if err != nil {
			return nil, err
		}
		for _, s := range todo {
			if r, ok := known[string(s.ID)]; ok && len(r.ids) > 0 {
				ranked[string(s.ID)] = r.ids
			}
		}
	}
	reader, err := canonlinks.NewReader(g)
	if err != nil {
		return nil, err
	}
	return &canonView{
		m: m, reader: reader, ranked: ranked,
		handles: map[string]*graphalign.Handle{},
		links:   map[string][]kinship.Link{},
	}, nil
}

// Handle is the match index's profile of an unmerged primary handle, nil for
// any other id. Align reads a handle by pointer and never writes it.
func (v *canonView) Handle(id []byte) *graphalign.Handle {
	if h, ok := v.handles[string(id)]; ok {
		return h
	}
	s, ok := v.m.handles[string(id)]
	if !ok {
		return nil
	}
	h := s
	v.handles[string(id)] = &h
	return &h
}

// Links is every link at the handle id whose far end is a handle, in
// canonlinks.Reader.Links order, read once per proposal. An id the match index
// does not hold has none. Once a read has failed it serves nothing.
func (v *canonView) Links(id []byte) []kinship.Link {
	if v.err != nil {
		return nil
	}
	if ls, ok := v.links[string(id)]; ok {
		return ls
	}
	if _, ok := v.m.handles[string(id)]; !ok {
		return nil
	}
	all, err := v.reader.Links(id)
	if err != nil {
		v.err = err
		return nil
	}
	kept := []kinship.Link{}
	for _, l := range all {
		if other, _, ok := l.From(id); ok {
			if _, held := v.m.handles[string(other)]; held {
				kept = append(kept, l)
			}
		}
	}
	v.links[string(id)] = kept
	return kept
}

// Candidates is the Subject's ranked candidate handle ids.
func (v *canonView) Candidates(subjectID []byte) [][]byte { return v.ranked[string(subjectID)] }

// loadCandidatesMemo is the ranked candidate ids of each Subject in todo:
// graphalign.Candidates over the handles the match index offers it, held in
// the candidates entry. A commit forgets only the Subjects whose lookup keys
// it moved (forgetCandidates); a dropped match index empties the entry. It reads the stored memo,
// ranks only the Subjects it lacks, and stores a new map, never changing the
// stored one.
func loadCandidatesMemo(g *graphcache.Graph, graphID []byte, m *matchIndex, layer graphalign.Layer, todo []graphalign.Subject, cfg graphalign.Config) (map[string]rankedSubject, error) {
	var known map[string]rankedSubject
	if memo, ok := candidates.Peek(g, graphID); ok {
		known = memo.bySubject
	}
	var missing []graphalign.Subject
	for _, s := range todo {
		if _, ok := known[string(s.ID)]; !ok {
			missing = append(missing, s)
		}
	}
	if len(missing) == 0 {
		return known, nil
	}
	ranked := rankCandidates(m, layer, missing, cfg)
	stored := make(map[string]rankedSubject, len(known)+len(missing))
	maps.Copy(stored, known)
	maps.Copy(stored, ranked)
	candidates.Set(g, graphID, candidatesMemo{bySubject: stored})
	return stored, nil
}

// forgetCandidates is the Narrow of candidates: after a commit that changed
// handles it forgets every Subject with a lookup key among the moved keys the
// match index reports, in its kind. The Subject is ranked again by
// loadCandidatesMemo on its graph's next proposal. A change that is not the
// match index's moved keys clears the entry; no moved key forgets nothing. A
// stored memo is never changed: one that loses a Subject is replaced by a copy.
func forgetCandidates(g *graphcache.Graph, k graphcache.Keyed[candidatesMemo], change any) {
	moved, ok := change.(map[movedKey]bool)
	if !ok {
		k.Clear(g)
		return
	}
	if len(moved) == 0 {
		return
	}
	k.Update(g, func(_ []byte, memo candidatesMemo) candidatesMemo {
		meets := func(r rankedSubject) bool {
			for _, key := range r.keys {
				if moved[movedKey{r.kind, key}] {
					return true
				}
			}
			return false
		}
		hit := false
		for _, r := range memo.bySubject {
			if meets(r) {
				hit = true
				break
			}
		}
		if !hit {
			return memo
		}
		kept := make(map[string]rankedSubject, len(memo.bySubject))
		for id, r := range memo.bySubject {
			if !meets(r) {
				kept[id] = r
			}
		}
		return candidatesMemo{bySubject: kept}
	})
}

// rankCandidates is the ranked candidate ids of each Subject: the handles the
// shortlist index offers it, ordered by graphalign.Candidates, with the kind and
// lookup keys it read. Every Subject has an entry, an empty list for none.
func rankCandidates(m *matchIndex, layer graphalign.Layer, subjects []graphalign.Subject, cfg graphalign.Config) map[string]rankedSubject {
	out := make(map[string]rankedSubject, len(subjects))
	for _, s := range subjects {
		kind := vocabkey.SubjectType(s.Kind)
		keys := m.shortlist.LookupKeys(kind, s.Values)
		ranked := [][]byte{}
		for _, h := range graphalign.Candidates(s.Kind, s.Values, seedHandles(m, kind, keys), layer.Metas, cfg) {
			ranked = append(ranked, h.ID)
		}
		out[string(s.ID)] = rankedSubject{kind: kind, keys: keys, ids: ranked}
	}
	return out
}

// checkCandidates ranks the held graph's Subjects again from fresh inputs,
// storing nothing, and compares.
func checkCandidates(g *graphcache.Graph, graphID []byte, stored candidatesMemo) error {
	m, err := matchIndexOf(g)
	if err != nil {
		return err
	}
	ev, err := evidencelayer.Fresh(g, graphID)
	if errors.Is(err, evidencelayer.ErrNoGraph) {
		return fmt.Errorf("promotealign: candidates are held for %x, which is no Evidence graph", graphID)
	}
	if err != nil {
		return err
	}
	cfg, _, err := loadConfig(g)
	if err != nil {
		return err
	}
	layer, err := alignLayer(g, ev)
	if err != nil {
		return err
	}
	var subjects []graphalign.Subject
	for id := range stored.bySubject {
		s, ok := ev.Subject([]byte(id))
		if !ok {
			return fmt.Errorf("promotealign: candidates are held for Subject %x, which is no primary Subject of %x", id, graphID)
		}
		subjects = append(subjects, s)
	}
	if !reflect.DeepEqual(rankCandidates(m, layer, subjects, cfg), stored.bySubject) {
		return fmt.Errorf("promotealign: the stored candidates of %x do not match a fresh ranking", graphID)
	}
	return nil
}
