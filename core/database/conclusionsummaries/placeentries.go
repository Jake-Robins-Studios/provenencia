package conclusionsummaries

import (
	"bytes"
	"fmt"
	"reflect"

	"github.com/mendahu/provenencia/core/database/graphcache"
	"github.com/mendahu/provenencia/core/hops"
	"github.com/mendahu/provenencia/core/valuecompare"
	"github.com/mendahu/provenencia/core/vocabkey"
)

// maxPlaceEntries caps the place entries one graph holds. It matches the other
// per-handle entries (canonlinks.maxKeys) and holds every place of a real
// catalog; only a crafted catalog reaches it.
const maxPlaceEntries = 65536

// placeEntry is what a chain read needs of one place: its shell, its period,
// and the part_of links where it is the part, with their decoded dates. The
// fill reads only the place's values and its place_relationship links, and
// only those links' associations: never the events and other links a city
// carries, and never the dates of a child's or a succession link. Values are
// shared and read only.
type placeEntry struct {
	found    bool
	shell    PlaceSummary
	period   valuecompare.Window
	partFrom []placeLink // this place is the part: part id → wholes
	// inputs are the keys a summary row records for this place: its values, its
	// part_of links at the part end and those links' associations.
	inputs []graphcache.InputKey
}

// placePage is what only the place page and its parts question read of one
// place: the links where it is the whole, with their decoded dates. A chain
// read never builds one, so a bad date on a child link fails that place's page
// and nothing else. Values are shared and read only.
type placePage struct {
	partTo []placeLink // this place is the whole: whole id → parts
	// inputs are the place's values and every part link followed with its
	// association.
	inputs []graphcache.InputKey
}

// placeSuccession is what the succession questions read of one place: the
// links where it is the predecessor and the successor, with their decoded
// dates. It holds no part link, so a place with thousands of parts reads its
// successors without reading them, and a bad part date fails only its page.
// Values are shared and read only.
type placeSuccession struct {
	succFrom []placeLink // this place is the predecessor
	succTo   []placeLink // this place is the successor
	// inputs are the place's values and every succession link followed with its
	// association.
	inputs []graphcache.InputKey
}

// placeKeyed is one keyed place entry: its registration, its fill and its
// reader.
type placeKeyed[T any] struct {
	k    graphcache.Keyed[T]
	fill func(g *graphcache.Graph, v vocab, ids [][]byte) (map[string]T, error)
}

// registerPlaceKeyed registers a place entry named name, derived from the
// vocabulary, dropped through the keys inputs lists, checked by rebuilding it
// through fill. noun names the entry in the check's error.
func registerPlaceKeyed[T any](name, noun string, fill func(*graphcache.Graph, vocab, [][]byte) (map[string]T, error), inputs func(T) []graphcache.InputKey) placeKeyed[T] {
	return placeKeyed[T]{
		fill: fill,
		k: graphcache.RegisterKeyed(graphcache.KeyedEntry[T]{
			Name:        name,
			DerivedFrom: []graphcache.Source{graphcache.Vocabulary{}},
			Inputs:      func(_ []byte, e T) []graphcache.InputKey { return inputs(e) },
			Check: func(g *graphcache.Graph, id []byte, stored T) error {
				v, err := vocabulary(g)
				if err != nil {
					return err
				}
				fresh, err := fill(g, v, [][]byte{id})
				if err != nil {
					return err
				}
				if !reflect.DeepEqual(fresh[string(id)], stored) {
					return fmt.Errorf("conclusionsummaries: stored %s %x does not match a fresh load", noun, id)
				}
				return nil
			},
			Cap: maxPlaceEntries,
		}),
	}
}

// of returns the entry of each place in ids, keyed by raw id, filling those not
// held in one fill a frontier at a time. An id that is not 16 bytes has none.
func (p placeKeyed[T]) of(g *graphcache.Graph, v vocab, ids [][]byte) (map[string]T, error) {
	return p.k.GetMany(g, ids, func(missing [][]byte) (map[string]T, error) {
		return p.fill(g, v, missing)
	})
}

// placeEntries holds one placeEntry per place id, placePages one placePage and
// placeSuccessions one placeSuccession. A commit drops an entry through its
// Inputs, so a write that touches neither a place nor its links leaves it.
var (
	placeEntries     placeKeyed[placeEntry]
	placePages       placeKeyed[placePage]
	placeSuccessions placeKeyed[placeSuccession]
)

func init() {
	placeEntries = registerPlaceKeyed("conclusionsummaries.places", "place entry", fillPlaceEntries,
		func(e placeEntry) []graphcache.InputKey { return e.inputs })
	placePages = registerPlaceKeyed("conclusionsummaries.placePages", "place page", fillPlacePages,
		func(p placePage) []graphcache.InputKey { return p.inputs })
	placeSuccessions = registerPlaceKeyed("conclusionsummaries.placeSuccession", "place succession", fillPlaceSuccessions,
		func(s placeSuccession) []graphcache.InputKey { return s.inputs })
}

// followedPlace is a narrow node of each place in ids (values and
// place_relationship links) with the links each of hopList follows, and the
// decoded link of each, oriented from part or predecessor to whole or
// successor. A place with no entity row has no node.
type followedPlace struct {
	n        *graphcache.Node
	links    [][]graphcache.Link // one list per hop, in hopList order
	oriented [][]placeLink
}

// followHop is one hop followPlaces follows; selfOnly keeps only the links from
// the place to itself.
type followHop struct {
	hop      hops.Hop
	selfOnly bool
}

func followPlaces(g *graphcache.Graph, v vocab, ids [][]byte, hopList ...followHop) (map[string]*followedPlace, error) {
	nodes, err := g.NodesOnBridges(ids, "place_relationship")
	if err != nil {
		return nil, err
	}
	have := map[string]*followedPlace{}
	var assocIDs [][]byte
	for _, id := range ids {
		n := nodes[string(id)]
		if n == nil {
			continue
		}
		f := &followedPlace{n: n, links: make([][]graphcache.Link, len(hopList)), oriented: make([][]placeLink, len(hopList))}
		for i, h := range hopList {
			links, err := n.Follow(h.hop)
			if err != nil {
				return nil, err
			}
			for _, l := range links {
				if h.selfOnly && !bytes.Equal(l.Neighbor, id) {
					continue
				}
				f.links[i] = append(f.links[i], l)
				assocIDs = append(assocIDs, l.Association)
			}
		}
		have[string(id)] = f
	}
	assocs, err := g.NodesOnBridges(assocIDs)
	if err != nil {
		return nil, err
	}
	for id, f := range have {
		for i, links := range f.links {
			for _, l := range links {
				pl, err := orientPlaceLink(v, []byte(id), l, assocs)
				if err != nil {
					return nil, err
				}
				f.oriented[i] = append(f.oriented[i], pl)
			}
		}
	}
	return have, nil
}

// fillPlaceEntries reads the entries of ids with a narrow load: the places'
// values and the place_relationship links where each is the part, then those
// links' association values. A place with no entity row gets a found-false
// entry whose only input is its own values, so a commit that creates it drops
// the entry.
func fillPlaceEntries(g *graphcache.Graph, v vocab, ids [][]byte) (map[string]placeEntry, error) {
	have, err := followPlaces(g, v, ids, followHop{hop: hops.ParentsOfPlace})
	if err != nil {
		return nil, err
	}
	out := make(map[string]placeEntry, len(ids))
	for _, id := range ids {
		id = append([]byte(nil), id...)
		f := have[string(id)]
		if f == nil {
			out[string(id)] = placeEntry{inputs: []graphcache.InputKey{graphcache.NodeKey(id)}}
			continue
		}
		shell, err := placeShell(f.n, v)
		if err != nil {
			return nil, err
		}
		e := placeEntry{found: true, shell: shell, period: periodWindow(shell.StartDate, shell.EndDate)}
		e.partFrom = dedupePlaceLinks(f.oriented[0])
		keys := append([]graphcache.InputKey{graphcache.NodeKey(id)}, graphcache.FollowKeys(id, hops.ParentsOfPlace, f.links[0])...)
		e.inputs = graphcache.UniqueInputKeys(keys)
		out[string(id)] = e
	}
	return out, nil
}

// fillPlacePages reads the pages of ids the way fillPlaceEntries reads
// entries, over the links where each place is the whole. Its inputs come from
// the links it followed.
func fillPlacePages(g *graphcache.Graph, v vocab, ids [][]byte) (map[string]placePage, error) {
	// A place that is part of itself sits in its own list of parts as well as of
	// wholes, and the graph follows that link from only one end: the page takes
	// it from the part_of hop, and no other link of that hop.
	pageHops := []followHop{{hop: hops.PartsOfPlace}, {hop: hops.ParentsOfPlace, selfOnly: true}}
	have, err := followPlaces(g, v, ids, pageHops...)
	if err != nil {
		return nil, err
	}
	out := make(map[string]placePage, len(ids))
	for _, id := range ids {
		id = append([]byte(nil), id...)
		f := have[string(id)]
		keys := []graphcache.InputKey{graphcache.NodeKey(id)}
		if f == nil {
			out[string(id)] = placePage{inputs: keys}
			continue
		}
		for i, h := range pageHops {
			keys = append(keys, graphcache.FollowKeys(id, h.hop, f.links[i])...)
		}
		out[string(id)] = placePage{
			partTo: dedupePlaceLinks(append(f.oriented[0], f.oriented[1]...)),
			inputs: graphcache.UniqueInputKeys(keys),
		}
	}
	return out, nil
}

// fillPlaceSuccessions reads the succession entries of ids the way
// fillPlacePages reads pages, over the links where each place is the
// predecessor and the successor.
func fillPlaceSuccessions(g *graphcache.Graph, v vocab, ids [][]byte) (map[string]placeSuccession, error) {
	succHops := []followHop{{hop: hops.SuccessorsOfPlace}, {hop: hops.PredecessorsOfPlace}}
	have, err := followPlaces(g, v, ids, succHops...)
	if err != nil {
		return nil, err
	}
	out := make(map[string]placeSuccession, len(ids))
	for _, id := range ids {
		id = append([]byte(nil), id...)
		f := have[string(id)]
		keys := []graphcache.InputKey{graphcache.NodeKey(id)}
		if f == nil {
			out[string(id)] = placeSuccession{inputs: keys}
			continue
		}
		for i, h := range succHops {
			keys = append(keys, graphcache.FollowKeys(id, h.hop, f.links[i])...)
		}
		out[string(id)] = placeSuccession{
			succFrom: dedupePlaceLinks(f.oriented[0]),
			succTo:   dedupePlaceLinks(f.oriented[1]),
			inputs:   graphcache.UniqueInputKeys(keys),
		}
	}
	return out, nil
}

// dedupePlaceLinks drops a link repeated on from, to and association, keeping
// the first.
func dedupePlaceLinks(links []placeLink) []placeLink {
	seen := map[string]bool{}
	var out []placeLink
	for _, l := range links {
		key := string(l.from) + "\x00" + string(l.to) + "\x00" + string(l.association)
		if seen[key] {
			continue
		}
		seen[key] = true
		out = append(out, l)
	}
	return out
}

// orientPlaceLink makes the link l of place id a placeLink, from its part or
// predecessor to its whole or successor, with the dates of its association.
func orientPlaceLink(v vocab, id []byte, l graphcache.Link, assocs map[string]*graphcache.Node) (placeLink, error) {
	from, to := id, l.Neighbor
	if !l.FromEnd {
		from, to = l.Neighbor, id
	}
	assoc := assocs[string(l.Association)]
	if assoc == nil {
		return placeLink{}, fmt.Errorf("conclusionsummaries: association %x is missing", l.Association)
	}
	d, err := assocDatesOf(v, assoc)
	if err != nil {
		return placeLink{}, err
	}
	return placeLink{
		from: append([]byte(nil), from...), to: append([]byte(nil), to...),
		association: append([]byte(nil), l.Association...), start: d.start, end: d.end,
	}, nil
}

// FiledPlaceLinks returns, for each place in ids, the places its filed links of
// term lead to, from the part to the whole (part_of) or from the predecessor to
// the successor (succeeded_by), each list in link order with a repeated end kept
// once. A place with no entity row, or no link, is absent from the answer. A
// place that is part of itself leads to itself. It reads the chain entries for
// part_of and the succession entries for succeeded_by, and no date but the
// ones those entries decode. Any other term is an error.
func FiledPlaceLinks(g *graphcache.Graph, term vocabkey.BridgeTerm, ids [][]byte) (map[string][][]byte, error) {
	v, err := vocabulary(g)
	if err != nil {
		return nil, err
	}
	links := map[string][]placeLink{}
	switch term {
	case vocabkey.TermPartOf:
		entries, err := placeEntries.of(g, v, ids)
		if err != nil {
			return nil, err
		}
		for id, e := range entries {
			links[id] = e.partFrom
		}
	case vocabkey.TermSucceededBy:
		successions, err := placeSuccessions.of(g, v, ids)
		if err != nil {
			return nil, err
		}
		for id, s := range successions {
			links[id] = s.succFrom
		}
	default:
		return nil, fmt.Errorf("conclusionsummaries: no filed place links of term %q", term)
	}
	out := make(map[string][][]byte, len(links))
	for id, ls := range links {
		seen := map[string]bool{}
		for _, l := range ls {
			if seen[string(l.to)] {
				continue
			}
			seen[string(l.to)] = true
			out[id] = append(out[id], l.to)
		}
	}
	return out, nil
}
