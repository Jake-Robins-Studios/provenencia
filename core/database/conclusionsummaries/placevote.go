package conclusionsummaries

import (
	"bytes"

	"github.com/Jake-Robins-Studios/provenencia/core/autoreconcile"
	"github.com/Jake-Robins-Studios/provenencia/core/database/graphcache"
	"github.com/Jake-Robins-Studios/provenencia/core/database/valuerules"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue"
	"github.com/Jake-Robins-Studios/provenencia/core/hops"
	"github.com/Jake-Robins-Studios/provenencia/core/propertymeta"
	"github.com/Jake-Robins-Studios/provenencia/core/valuecompare"
)

// An event's places are the records of its location links, reconciled at the
// event's date by the same pipeline as any single-valued field
// (conclusion-reconciliation.md §11.1): a Place that contains another linked
// Place folds into it, the Sources vote, and weak evidence drops. The vote has
// two halves. prepareVote folds the linked Places with value compare and, when
// at most one survives, is done: every other Place is folded into it and
// nothing is read. Otherwise it lists the association of every link, the
// caller loads those nodes in one call, and finishVote reconciles their
// records.

// placeCardinality is the cardinality the vote reconciles with.
// decided: user, 2026-11-26: an event has one place; one declaration with matching waits on docs/ideas/one-bridge-cardinality.md
const placeCardinality = propertymeta.CardinalitySingle

// placeVote is an event's places and what the vote did to each of its links.
type placeVote struct {
	// places are the places the event shows, in vote order.
	places []ChainedPlace
	// links are the verdicts by association id, one per location link whose
	// Place has a shell and that has a record: ID, Place, Reason and Vote are
	// set; PropertyID is not.
	links map[string]FieldOwner
}

// placePrep is the first half of an event's place vote.
type placePrep struct {
	// vote is the finished vote when nothing is left to read.
	vote placeVote
	// assocs are the associations finishVote reads, in link order; empty when
	// the vote is finished.
	assocs [][]byte
	// links are the location links with a shell, one per association, and
	// survivors the places the fold left: finishVote's inputs.
	links     []graphcache.Link
	survivors map[string]ChainedPlace
	values    map[string]valuecompare.Value
	pg        *placeGraph
	at        *datevalue.Value
}

// eventFoldDate is the date an event's places are folded at: its dating's low
// end, else its high end; nil for an undated event.
func eventFoldDate(d valuecompare.Dating) *datevalue.Value {
	if d.Low != nil {
		return d.Low
	}
	return d.High
}

// prepareVote folds the places the locations link an event to at at.
// locations are the links the caller followed from the event, from
// eventLocations. Each place's names come from its entry in pg, so no place
// node is read.
func prepareVote(pg *placeGraph, at *datevalue.Value, locations []graphcache.Link) placePrep {
	var raw []ChainedPlace
	var links []graphcache.Link
	seen := map[string]bool{}
	for _, l := range locations {
		shell, ok := pg.shell(l.Neighbor)
		if !ok {
			continue
		}
		links = append(links, l)
		if seen[string(l.Neighbor)] {
			continue
		}
		seen[string(l.Neighbor)] = true
		raw = append(raw, ChainedPlace{Entity: shell.Entity, Names: shell.Names})
	}
	if len(raw) == 0 {
		return placePrep{}
	}
	var values map[string]valuecompare.Value
	if len(raw) > 1 {
		values = pg.subjectValues(raw, at)
	}
	folded := pg.FoldLocations(raw, values, at)
	prep := placePrep{links: links, survivors: map[string]ChainedPlace{}, values: values, pg: pg, at: at}
	for _, p := range folded {
		prep.survivors[string(p.Entity.ID)] = p
	}
	if len(folded) > 1 {
		listed := map[string]bool{}
		for _, l := range links {
			if len(l.Association) > 0 && !listed[string(l.Association)] {
				listed[string(l.Association)] = true
				prep.assocs = append(prep.assocs, l.Association)
			}
		}
		return prep
	}
	// At most one place survives: every other place folds into it.
	verdicts := map[string]FieldOwner{}
	for _, l := range links {
		if len(l.Association) == 0 {
			continue
		}
		reason := autoreconcile.ReasonFolded
		if _, shown := prep.survivors[string(l.Neighbor)]; shown {
			reason = autoreconcile.ReasonKept
		}
		verdicts[string(l.Association)] = prep.owner(l, reason, autoreconcile.Vote{})
	}
	prep.vote = placeVote{places: folded, links: verdicts}
	return prep
}

// owner is the verdict on link l.
func (p placePrep) owner(l graphcache.Link, reason autoreconcile.Reason, vote autoreconcile.Vote) FieldOwner {
	shell, _ := p.pg.shell(l.Neighbor)
	return FieldOwner{
		ID: l.Association, Place: &ChainedPlace{Entity: shell.Entity, Names: shell.Names}, Reason: reason, Vote: vote,
	}
}

// place is the ChainedPlace of a place the vote shows: the fold's own when it
// survived it, else built from the place's shell with its parents.
func (p placePrep) place(id []byte) (ChainedPlace, bool) {
	if c, ok := p.survivors[string(id)]; ok {
		return c, true
	}
	shell, ok := p.pg.shell(id)
	if !ok {
		return ChainedPlace{}, false
	}
	c := ChainedPlace{Entity: shell.Entity, Names: shell.Names}
	c.Parents, c.ParentsAreCandidates = p.pg.ParentChain(id, p.at)
	return c, true
}

// finishVote reconciles the records of the prepared event's location links:
// each association's outcome rows on the place Property that put the link's
// place at rank 1 (kept, or folded into it), one candidate each, from the
// Source that recorded it. The nodes are loaded by the caller and read through
// in, which records them. A link whose node is gone or whose records are all
// unusable gives no candidate, and its place is not shown.
func finishVote(in *graphcache.InputScope, v vocab, prep placePrep) (placeVote, error) {
	if len(prep.assocs) == 0 {
		return prep.vote, nil
	}
	placeProp := string(v.prop(hops.PlacesOfEvent.To()))
	var cands []autoreconcile.Candidate
	linkOf := map[string]graphcache.Link{} // Observation id -> its link
	weigh := map[string]autoreconcile.Provenance{}
	for _, l := range prep.links {
		if len(l.Association) == 0 {
			continue
		}
		n, err := in.Node(l.Association)
		if err != nil {
			return placeVote{}, err
		}
		if n == nil {
			continue
		}
		within := prep.values[string(l.Neighbor)].Within
		for _, o := range n.Outcomes[placeProp] {
			if o.ValueRank != 1 || len(o.SubjectID) == 0 || (o.Reason != string(autoreconcile.ReasonKept) && o.Reason != string(autoreconcile.ReasonFolded)) {
				continue
			}
			m, ok := memberOf(n, o.SubjectID)
			if !ok {
				continue
			}
			p := autoreconcile.Provenance{Credibility: m.Credibility, Uncertain: o.Uncertain}
			cands = append(cands, autoreconcile.Candidate{
				ObservationID: o.ObservationID,
				Value:         autoreconcile.Value{SubjectID: l.Neighbor, EntityID: l.Neighbor, Within: within},
				SourceID:      m.SourceID,
				Provenance:    p,
			})
			linkOf[string(o.ObservationID)] = l
			weigh[string(o.ObservationID)] = p
		}
	}
	res, err := autoreconcile.Reconcile(valuerules.Product(), propertymeta.ValueTypeSubject, cands, nil, placeCardinality)
	if err != nil {
		return placeVote{}, err
	}
	vote := placeVote{links: map[string]FieldOwner{}}
	for _, rv := range res.Values {
		if !rv.Displayed() {
			continue
		}
		if c, ok := prep.place(rv.Value.EntityID); ok {
			vote.places = append(vote.places, c)
		}
	}
	// A link's verdict is the outcome of its best-ranked record: the stronger
	// evidence, then the earlier Observation.
	best := map[string]autoreconcile.Outcome{}
	for _, o := range res.Outcomes {
		l := linkOf[string(o.ObservationID)]
		cur, ok := best[string(l.Association)]
		if !ok || weigh[string(o.ObservationID)].Stronger(weigh[string(cur.ObservationID)]) ||
			(!weigh[string(cur.ObservationID)].Stronger(weigh[string(o.ObservationID)]) && bytes.Compare(o.ObservationID, cur.ObservationID) < 0) {
			best[string(l.Association)] = o
		}
	}
	for _, l := range prep.links {
		if o, ok := best[string(l.Association)]; ok {
			vote.links[string(l.Association)] = prep.owner(l, o.Reason, o.Vote)
		}
	}
	return vote, nil
}

// memberOf is the member of n whose Subject is subjectID.
func memberOf(n *graphcache.Node, subjectID []byte) (graphcache.Member, bool) {
	for _, m := range n.Members {
		if bytes.Equal(m.SubjectID, subjectID) {
			return m, true
		}
	}
	return graphcache.Member{}, false
}
