package persondetail

import (
	"bytes"
	"slices"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/canonlinks"
	"github.com/Jake-Robins-Studios/provenencia/core/database/conclusiondetails"
	"github.com/Jake-Robins-Studios/provenencia/core/database/conclusionsummaries"
	"github.com/Jake-Robins-Studios/provenencia/core/database/graphcache"
	"github.com/Jake-Robins-Studios/provenencia/core/kinship"
	"github.com/Jake-Robins-Studios/provenencia/core/matchregistry"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

// maxMarriagesPerCouple is the most marriage events Families keeps for one
// couple: the first of its pivots in shape order. Real couples have one to
// three, so only a crafted catalog reaches it.
// decided: user, 2026-11-08 (rule "Crafted fan-out is capped, not engineered")
const maxMarriagesPerCouple = 10

// Family is one person's family units, sibling groups and couples.
//
// Groups hold the person and every sibling by the parents they share with the
// person (kinship.SiblingGroups), the person's group first. Couples hold the
// person with each spouse and each two of the person's parents who share a
// marriage event, each with its marriages; Units[i].Couples and
// Groups[i].Couples index into it.
type Family struct {
	Person  []byte
	Units   []Unit
	Groups  []Group
	Couples []FamilyCouple
}

// Unit is one family unit and the indexes, in Family.Couples, of the couples of
// the person and its partner.
type Unit struct {
	kinship.Unit
	Couples []int
}

// Group is one sibling group and the indexes, in Family.Couples, of the couples
// among its parents.
type Group struct {
	kinship.SiblingGroup
	Couples []int
}

// FamilyCouple is two people the page shows together and the marriage events
// both are subjects of. Marriages is at most maxMarriagesPerCouple events:
// the first pivots in shape order as Families returns it, those PersonFamily
// read, earliest first, as it returns it.
type FamilyCouple struct {
	A, B      []byte
	Marriages [][]byte
}

// Families reads the family of each id that is an unmerged Person, in ids
// order, from the graph cache: canonical relatives only, a fixed number of
// batched loads cold, no query warm. An id that is not a Person, is merged, or
// is not 16 bytes is skipped, and an id repeated gives one Family. It records on
// in what the kinship read loads and every relative it names or checks, shown or
// not; over several ids in holds the union.
func Families(c *database.Catalog, ids [][]byte, in *graphcache.PageInputs) ([]Family, error) {
	if c == nil || c.Graph() == nil {
		return nil, nil
	}
	g := c.Graph()
	rules := matchregistry.Default().Kinship
	r, err := canonlinks.NewReader(g)
	if err != nil {
		return nil, err
	}
	terms, err := canonlinks.LoadTerms(g)
	if err != nil {
		return nil, err
	}
	v, err := g.Vocabulary()
	if err != nil {
		return nil, err
	}
	typeID := v.TypeIDsByKey()[vocabkey.Person]
	want := database.UniqueBlobIDs(ids)
	// One batched load of the nodes, so an id that is no node costs no query of
	// its own; only the people among them are read further.
	if err := in.Nodes(want); err != nil {
		return nil, err
	}
	var people [][]byte
	for _, id := range want {
		if n, _ := in.Cached(id); n.Is(typeID) {
			people = append(people, id)
		}
	}
	links, err := r.Relationships(people, canonlinks.Options{Siblings: true}, in)
	if err != nil {
		return nil, err
	}

	// The capped, unfiltered kin of each person, and every relative they name,
	// loaded so shownKin reads them.
	var named [][]byte
	kin := map[string]kinship.Kin{}
	for _, id := range people {
		kin[string(id)] = kinship.KinOf(id, links[string(id)], terms, rules)
		for _, role := range kinship.Roles() {
			for _, l := range kin[string(id)][role] {
				other, _, _ := l.From(id)
				named = append(named, other)
			}
		}
	}
	if err := in.Nodes(named); err != nil {
		return nil, err
	}

	// The kin of each shown relative a family unit reads, read once.
	shown := map[string]kinship.Kin{}
	var around [][]byte
	for _, id := range people {
		shown[string(id)] = shownKin(in, typeID, id, kin[string(id)])
		around = append(around, shown[string(id)].Around(id)...)
	}
	aroundLinks, err := r.Relationships(around, canonlinks.Options{}, in)
	if err != nil {
		return nil, err
	}
	aroundKin := map[string]kinship.Kin{}
	for id, ls := range aroundLinks {
		other := []byte(id)
		aroundKin[id] = shownKin(in, typeID, other, kinship.KinOf(other, ls, terms, rules))
	}

	out := make([]Family, 0, len(people))
	for _, id := range people {
		f := Family{Person: id}
		for _, u := range kinship.FamilyUnits(id, shown[string(id)], aroundKin) {
			f.Units = append(f.Units, Unit{Unit: u})
		}
		for _, g := range kinship.SiblingGroups(id, shown[string(id)]) {
			f.Groups = append(f.Groups, Group{SiblingGroup: g})
		}
		for _, c := range kinship.Couples(id, shown[string(id)], aroundKin, rules) {
			f.Couples = append(f.Couples, FamilyCouple{A: c.A, B: c.B, Marriages: c.Pivots[:min(len(c.Pivots), maxMarriagesPerCouple)]})
		}
		indexCouples(&f)
		out = append(out, f)
	}
	return out, nil
}

// indexCouples sets each group's Couples to the indexes of the couples whose
// two people are both its parents, in Couples order, and each partner unit's to
// the indexes of the couples of the person and its partner (nil for any other
// unit).
func indexCouples(f *Family) {
	for k := range f.Groups {
		g := &f.Groups[k]
		g.Couples = nil
		has := func(id []byte) bool {
			return slices.ContainsFunc(g.Parents, func(r kinship.Relative) bool { return bytes.Equal(r.ID, id) })
		}
		for i, c := range f.Couples {
			if has(c.A) && has(c.B) {
				g.Couples = append(g.Couples, i)
			}
		}
	}
	for k := range f.Units {
		u := &f.Units[k]
		u.Couples = nil
		if u.Kind != kinship.UnitPartner || len(u.Partners) != 1 {
			continue
		}
		partner := u.Partners[0].ID
		for i, c := range f.Couples {
			if bytes.Equal(c.A, f.Person) && bytes.Equal(c.B, partner) {
				u.Couples = append(u.Couples, i)
			}
		}
	}
}

// shownKin is kin without the links to people who are not shown: a relative
// who is not a canonical Person of typeID. The filter is per link, so each role
// keeps its order. Each relative is checked through in, so it is recorded
// whether or not it is shown.
func shownKin(in *graphcache.PageInputs, typeID []byte, id []byte, kin kinship.Kin) kinship.Kin {
	shown := kinship.Kin{}
	for role, links := range kin {
		for _, l := range links {
			other, _, _ := l.From(id)
			if n, _ := in.Cached(other); n.Canonical(typeID) {
				shown[role] = append(shown[role], l)
			}
		}
	}
	return shown
}

// PersonFamily is the page read: one handle's family and the summary of every
// person its units, groups and couples name and of the person. An unknown or
// merged handle, or one that is no Person, is conclusiondetails.ErrNotFound.
// The family and the summaries agree: a relative with no summary is dropped,
// and a unit left empty with it. Each unit's and group's children are in birth
// order, undated last. Each couple's marriages are the canonical events among the pivots
// Families kept, in the event list's order, with their
// summaries; a couple left with none is dropped. It records on in what Families
// does, the person, every id it reads a summary of, and every marriage event it
// loads.
func PersonFamily(c *database.Catalog, entityID []byte, in *graphcache.PageInputs) (Family, conclusionsummaries.Summaries, error) {
	if _, err := personNode(c, entityID, in); err != nil {
		return Family{}, conclusionsummaries.Summaries{}, err
	}
	families, err := Families(c, [][]byte{entityID}, in)
	if err != nil {
		return Family{}, conclusionsummaries.Summaries{}, err
	}
	if len(families) == 0 {
		return Family{}, conclusionsummaries.Summaries{}, conclusiondetails.ErrNotFound
	}
	family := families[0]
	var want conclusionsummaries.Want
	want.Add(vocabkey.Person, entityID)
	add := func(rs []kinship.Relative) {
		for _, r := range rs {
			want.Add(vocabkey.Person, r.ID)
			in.AddHandles(r.ID)
		}
	}
	for _, u := range family.Units {
		add(u.Partners)
		add(u.Children)
	}
	for _, g := range family.Groups {
		add(g.Parents)
		add(g.Children)
	}
	persons, err := conclusionsummaries.PersonsByIDs(c, want.Persons)
	if err != nil {
		return Family{}, conclusionsummaries.Summaries{}, err
	}
	events, err := marriageEvents(c, family, in)
	if err != nil {
		return Family{}, conclusionsummaries.Summaries{}, err
	}
	summaries := conclusionsummaries.NewSummaries(persons, events, nil)
	for i := range family.Couples {
		pivots := family.Couples[i].Marriages
		var marriages [][]byte
		for _, h := range events {
			if slices.ContainsFunc(pivots, func(p []byte) bool { return bytes.Equal(p, h.Entity.ID) }) {
				marriages = append(marriages, h.Entity.ID)
			}
		}
		family.Couples[i].Marriages = marriages
	}
	family = dropUnread(family, summaries)
	byBirth := func(rs []kinship.Relative) {
		conclusionsummaries.SortByBirth(rs, func(r kinship.Relative) conclusionsummaries.PersonSummary {
			h, _ := summaries.Person(r.ID)
			return h
		})
	}
	for _, u := range family.Units {
		byBirth(u.Children)
	}
	for _, g := range family.Groups {
		byBirth(g.Children)
	}
	indexCouples(&family)
	return family, summaries, nil
}

// marriageEvents loads the event nodes of each of family's couples' marriages
// in one call, and reads the summaries of the
// canonical ones in the event list's order. It leaves family as it is.
func marriageEvents(c *database.Catalog, family Family, in *graphcache.PageInputs) ([]conclusionsummaries.EventSummary, error) {
	var ids [][]byte
	for i := range family.Couples {
		ids = append(ids, family.Couples[i].Marriages...)
	}
	ids = database.UniqueBlobIDs(ids)
	if len(ids) == 0 {
		return nil, nil
	}
	v, err := c.Graph().Vocabulary()
	if err != nil {
		return nil, err
	}
	eventType := v.TypeIDsByKey()[vocabkey.Event]
	if err := in.Nodes(ids); err != nil {
		return nil, err
	}
	var canonical [][]byte
	for _, id := range ids {
		if e, _ := in.Cached(id); e.Canonical(eventType) {
			canonical = append(canonical, id)
		}
	}
	return conclusionsummaries.EventsByIDs(c, canonical)
}

// dropUnread drops each relative whose summary was not read (a node dropped
// mid-read: the next read is right, as the claims read skips) and then each unit
// that is left empty: a partner unit with no partner, and a one parent unit with
// no child. It drops the same members from the
// sibling groups: the first group stays whatever is left of it, and another
// group with no child left goes. A couple with a person not read, or with no
// marriage, goes. It does not
// reindex couples: indexCouples does, once the couples are final.
func dropUnread(family Family, summaries conclusionsummaries.Summaries) Family {
	read := func(rs []kinship.Relative) []kinship.Relative {
		var kept []kinship.Relative
		for _, r := range rs {
			if _, ok := summaries.Person(r.ID); ok {
				kept = append(kept, r)
			}
		}
		return kept
	}
	var units []Unit
	for _, u := range family.Units {
		u.Partners, u.Children = read(u.Partners), read(u.Children)
		if u.Empty() {
			continue
		}
		units = append(units, u)
	}
	family.Units = units
	var groups []Group
	for k, g := range family.Groups {
		g.Parents, g.Children = read(g.Parents), read(g.Children)
		if k > 0 && len(g.Children) == 0 {
			continue
		}
		groups = append(groups, g)
	}
	family.Groups = groups
	var couples []FamilyCouple
	for _, c := range family.Couples {
		_, a := summaries.Person(c.A)
		_, b := summaries.Person(c.B)
		if !a || !b || len(c.Marriages) == 0 {
			continue
		}
		couples = append(couples, c)
	}
	family.Couples = couples
	return family
}
