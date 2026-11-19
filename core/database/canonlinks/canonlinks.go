// Package canonlinks reads the canon's links: every link a node has, filed and
// implied, as edges with the key each has from each end (Reader.Links), the
// catalog's bridge terms (LoadTerms), the links the kinship patterns imply for
// one person (Reader.For, which composes them from the pivot results at each
// call), and each person's relationship links, recorded and implied, merged through
// kinship.LinkSet (Reader.Relationships), with, on request, the siblings a
// shared parent implies (Options{Siblings: true}). Relationships reads many
// people at once and loads what it reads in a fixed number of batches. Matching
// and later readers share it.
package canonlinks

import (
	"github.com/Jake-Robins-Studios/provenencia/core/connectrules"
	"github.com/Jake-Robins-Studios/provenencia/core/database/graphcache"
	"github.com/Jake-Robins-Studios/provenencia/core/segmentcompare"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

// LoadTerms reads the catalog's facts about every term of each registered
// bridge's disambiguation Property: whether it keeps direction and which term
// reads it from the other end. It is the one source of both.
func LoadTerms(g *graphcache.Graph) (segmentcompare.Terms, error) {
	v, err := g.Vocabulary()
	if err != nil {
		return nil, err
	}
	out := segmentcompare.Terms{}
	for _, b := range connectrules.Bridges() {
		if !connectrules.HasDisambiguation(b.Disambiguation) {
			continue
		}
		typ := vocabkey.SubjectType(b.BridgeTypeKey)
		for _, t := range v.Terms {
			if t.PropertyKey != b.Disambiguation {
				continue
			}
			if out[typ] == nil {
				out[typ] = map[vocabkey.BridgeTerm]segmentcompare.Term{}
			}
			out[typ][vocabkey.BridgeTerm(t.Key)] = segmentcompare.Term{
				Directed: t.Directed, Inverse: vocabkey.BridgeTerm(t.InverseKey),
			}
		}
	}
	return out, nil
}

// edgeOf reads one filed link of n as an edge between its two ends, ordered as
// recorded, with the key it has from each. neighbor is the link's other end,
// read for its event type when it is the event end. ok is false for an
// unregistered bridge.
func (d *deriver) edgeOf(n *graphcache.Node, l graphcache.Link, neighbor *graphcache.Node) (from, to []byte, keyFrom, keyTo vocabkey.BridgeKey, ok bool) {
	b, ok := connectrules.LookupBridge(l.BridgeTypeKey)
	if !ok || len(b.Endpoints) != 2 {
		return nil, nil, vocabkey.BridgeKey{}, vocabkey.BridgeKey{}, false
	}
	if l.FromEnd {
		from, to = n.ID, l.Neighbor
	} else {
		from, to = l.Neighbor, n.ID
	}
	// The event type comes from whichever end is an event; `segmentcompare.Keys` alone
	// decides whether the key keeps it.
	var eventType string
	if first, has := segmentcompare.EventEndpoint(b); has {
		// The first endpoint is the edge's from end; n is that end when the
		// link was filed from it.
		end := neighbor
		if first == l.FromEnd {
			end = n
		}
		if row, ok := graphcache.Rank1(end.Kept(d.eventTypeProp)); ok {
			eventType = row.TermKey
		}
	}
	keyFrom, keyTo = segmentcompare.Keys(b, vocabkey.BridgeTerm(l.TermKey), vocabkey.EventType(eventType), d.terms)
	return from, to, keyFrom, keyTo, true
}
