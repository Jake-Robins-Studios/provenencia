package conclusionsummaries

import (
	"github.com/Jake-Robins-Studios/provenencia/core/autoreconcile"
	"github.com/Jake-Robins-Studios/provenencia/core/database/graphcache"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue"
	"github.com/Jake-Robins-Studios/provenencia/core/valuecompare"
)

// An event's places are the records of its location links, reconciled at the
// event's date by the same pipeline as any single-valued field
// (conclusion-reconciliation.md §11.1): a Place that contains another linked
// Place folds into it, the Sources vote, and weak evidence drops. The vote has
// two halves. prepareVote folds the linked Places with value compare and, when
// at most one survives, is done: every other Place is folded into it and
// nothing is read. finishVote reads the survivors' links' association nodes
// and reconciles their records.

// placeVote is an event's places and what the vote did to each of its links.
type placeVote struct {
	// places are the places the event shows, in vote order.
	places []ChainedPlace
	// links are the verdicts by association id, one per location link whose
	// Place has a shell: ID, Place, Reason and Vote are set; PropertyID is not.
	links map[string]FieldOwner
}

// placePrep is the first half of an event's place vote.
type placePrep struct {
	vote placeVote
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
	seen := map[string]bool{}
	for _, l := range locations {
		if seen[string(l.Neighbor)] {
			continue
		}
		seen[string(l.Neighbor)] = true
		shell, ok := pg.shell(l.Neighbor)
		if !ok {
			continue
		}
		raw = append(raw, ChainedPlace{Entity: shell.Entity, Names: shell.Names})
	}
	if len(raw) == 0 {
		return placePrep{}
	}
	var values map[string]valuecompare.Value
	if len(raw) > 1 {
		values = pg.subjectValues(raw, at)
	}
	survivors := pg.FoldLocations(raw, values, at)
	shown := map[string]bool{}
	for _, p := range survivors {
		shown[string(p.Entity.ID)] = true
	}
	links := map[string]FieldOwner{}
	for _, l := range locations {
		shell, ok := pg.shell(l.Neighbor)
		if !ok || len(l.Association) == 0 {
			continue
		}
		reason := autoreconcile.ReasonFolded
		if shown[string(l.Neighbor)] {
			reason = autoreconcile.ReasonKept
		}
		links[string(l.Association)] = FieldOwner{
			ID: l.Association, Place: &ChainedPlace{Entity: shell.Entity, Names: shell.Names}, Reason: reason,
		}
	}
	return placePrep{vote: placeVote{places: survivors, links: links}}
}
