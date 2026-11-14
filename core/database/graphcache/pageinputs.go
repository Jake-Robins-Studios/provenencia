package graphcache

import (
	"bytes"
	"sort"

	"github.com/mendahu/provenencia/core/hops"
)

// PageInputs records what one per-entity page read was built from: the handles
// it read, the Evidence graphs whose records it shows and the Sources whose
// words it shows. Handles go through an InputScope, so a read that reads a
// node or a hop through PageInputs records it; graphs and Sources are not
// InputKeys (the persisted input index stores InputKey) and are plain id sets.
// One recorder may be shared by several reads of one call; it then holds the
// union.
type PageInputs struct {
	scope        *InputScope
	graphs, srcs map[string][]byte
	off          bool
}

// PageInputs returns a recorder for one page read. Only made on an open graph.
func (g *Graph) PageInputs() *PageInputs {
	return &PageInputs{scope: g.Inputs(nil), graphs: map[string][]byte{}, srcs: map[string][]byte{}}
}

// NoPageInputs returns a recorder that reads and records nothing, for a caller
// that does not report inputs. It is safe on a nil graph, which reads as one
// does.
func (g *Graph) NoPageInputs() *PageInputs {
	return &PageInputs{scope: g.NoInputs(), off: true}
}

// Node is InputScope.Node: Graph.Node, recording the node's values.
func (p *PageInputs) Node(id []byte) (*Node, error) { return p.scope.Node(id) }

// Follow is InputScope.Follow: Graph.Follow, recording the bridge end and each
// returned association.
func (p *PageInputs) Follow(id []byte, hop hops.Hop) ([]Link, error) {
	return p.scope.Follow(id, hop)
}

// Nodes is Graph.Nodes. It records nothing: it only loads.
func (p *PageInputs) Nodes(ids [][]byte) error { return p.scope.Nodes(ids) }

// Cached is Graph.Cached, which never loads, and records the id found or not.
func (p *PageInputs) Cached(id []byte) (*Node, bool) {
	n, ok := p.scope.g.Cached(id)
	if !p.off {
		p.scope.Add(NodeKey(id))
	}
	return n, ok
}

// AddHandles records the values of each id, for ids taken from rows already in
// hand and never for a node the read looks up.
func (p *PageInputs) AddHandles(ids ...[]byte) {
	if p.off {
		return
	}
	keys := make([]InputKey, len(ids))
	for i, id := range ids {
		keys[i] = NodeKey(id)
	}
	p.scope.Add(keys...)
}

// AddKeys records keys handed in as they are, such as a place entry's.
func (p *PageInputs) AddKeys(keys ...InputKey) {
	if p.off {
		return
	}
	p.scope.Add(keys...)
}

// AddEvidenceGraphs records the Evidence graphs whose records the page shows.
func (p *PageInputs) AddEvidenceGraphs(ids ...[]byte) {
	if p.off {
		return
	}
	addIDs(p.graphs, ids)
}

// AddSources records the Sources whose words the page shows.
func (p *PageInputs) AddSources(ids ...[]byte) {
	if p.off {
		return
	}
	addIDs(p.srcs, ids)
}

func addIDs(into map[string][]byte, ids [][]byte) {
	for _, id := range ids {
		if _, ok := into[string(id)]; !ok {
			into[string(id)] = cloneID(id)
		}
	}
}

// Lists returns each list distinct and in byte order, dropping any id that is
// not 16 bytes. The handles are the distinct IDs of the recorded keys.
func (p *PageInputs) Lists() (handles, evidenceGraphs, sources [][]byte) {
	if p.off {
		return nil, nil, nil
	}
	seen := map[string][]byte{}
	for _, k := range p.scope.Keys() {
		if _, ok := seen[string(k.ID)]; !ok {
			seen[string(k.ID)] = k.ID
		}
	}
	return sortedIDs(seen), sortedIDs(p.graphs), sortedIDs(p.srcs)
}

func sortedIDs(m map[string][]byte) [][]byte {
	out := make([][]byte, 0, len(m))
	for _, id := range m {
		if len(id) == 16 {
			out = append(out, id)
		}
	}
	sort.Slice(out, func(i, j int) bool { return bytes.Compare(out[i], out[j]) < 0 })
	return out
}
