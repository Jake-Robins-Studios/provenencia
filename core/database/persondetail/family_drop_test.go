package persondetail

import (
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database/canonicalentities"
	"github.com/Jake-Robins-Studios/provenencia/core/database/conclusionsummaries"
	"github.com/Jake-Robins-Studios/provenencia/core/kinship"
)

// TestDropUnread covers D-10: a relative whose summary was not read is dropped
// with the unit it leaves empty. A summary missing mid-read cannot be built
// from the catalog, so the summaries come from the rows given.
func TestDropUnread(t *testing.T) {
	id := func(n byte) []byte { return []byte{n} }
	rel := func(n byte) kinship.Relative { return kinship.Relative{ID: id(n)} }
	row := func(n byte) conclusionsummaries.PersonSummary {
		return conclusionsummaries.PersonSummary{Entity: canonicalentities.Entity{ID: id(n)}}
	}
	family := Family{Person: id(1), Units: []kinship.Unit{
		{Kind: kinship.UnitParents, Partners: []kinship.Relative{rel(2), rel(3)}, Children: []kinship.Relative{rel(4)}},
		{Kind: kinship.UnitPartner, Partners: []kinship.Relative{rel(5)}, Children: []kinship.Relative{rel(6)}},
		{Kind: kinship.UnitOneParent, Children: []kinship.Relative{rel(7)}},
		{Kind: kinship.UnitSiblings, Children: []kinship.Relative{rel(8)}},
	}}
	// 3, 4 and 6 and 5 are read; 2, 7 and 8 are not. The parents unit keeps 3; the
	// partner unit keeps both; the one-parent and siblings units are empty.
	got := dropUnread(family, conclusionsummaries.NewSummaries([]conclusionsummaries.PersonSummary{row(3), row(4), row(5), row(6)}, nil, nil))
	if len(got.Units) != 2 {
		t.Fatalf("%d units, want 2: %+v", len(got.Units), got.Units)
	}
	if u := got.Units[0]; len(u.Partners) != 1 || u.Partners[0].ID[0] != 3 || len(u.Children) != 1 {
		t.Fatalf("parents unit %+v", u)
	}
	// A partner no one read empties its unit although it has a child.
	got = dropUnread(family, conclusionsummaries.NewSummaries([]conclusionsummaries.PersonSummary{row(3), row(4), row(6)}, nil, nil))
	if len(got.Units) != 1 || got.Units[0].Kind != kinship.UnitParents {
		t.Fatalf("units %+v", got.Units)
	}
}

// TestDropUnreadGroupsAndCouples covers D-8: unread members leave a sibling
// group, the first group stays whatever is left, another group with no child
// goes, and a couple with an unread person goes.
func TestDropUnreadGroupsAndCouples(t *testing.T) {
	id := func(n byte) []byte { return []byte{n} }
	rel := func(n byte) kinship.Relative { return kinship.Relative{ID: id(n)} }
	rels := func(ns ...byte) []kinship.Relative {
		var out []kinship.Relative
		for _, n := range ns {
			out = append(out, rel(n))
		}
		return out
	}
	person := func(n byte) conclusionsummaries.PersonSummary {
		return conclusionsummaries.PersonSummary{Entity: canonicalentities.Entity{ID: id(n)}}
	}
	event := func(n byte) conclusionsummaries.EventSummary {
		return conclusionsummaries.EventSummary{Entity: canonicalentities.Entity{ID: id(n)}}
	}
	family := Family{
		Person: id(1),
		Groups: []Group{
			{SiblingGroup: kinship.SiblingGroup{Parents: rels(2, 3), Children: rels(4, 1)}},
			{SiblingGroup: kinship.SiblingGroup{Parents: rels(2), Children: rels(5)}},
			{SiblingGroup: kinship.SiblingGroup{Parents: rels(3), Children: rels(6)}},
		},
		Couples: []FamilyCouple{
			{A: id(2), B: id(3), Marriages: [][]byte{id(20)}},
			{A: id(1), B: id(7), Marriages: [][]byte{id(22)}},
			{A: id(1), B: id(8), Marriages: [][]byte{id(23)}},
		},
	}
	// 3, 4, 6 and 7 are read; the person 1, 2, 5 and 8 are not.
	read := conclusionsummaries.NewSummaries(
		[]conclusionsummaries.PersonSummary{person(3), person(6), person(7), person(4)},
		[]conclusionsummaries.EventSummary{event(20), event(22), event(23)}, nil)
	got := dropUnread(family, read)
	if len(got.Groups) != 2 {
		t.Fatalf("%d groups, want 2: %+v", len(got.Groups), got.Groups)
	}
	if g := got.Groups[0]; len(g.Parents) != 1 || g.Parents[0].ID[0] != 3 || len(g.Children) != 1 || g.Children[0].ID[0] != 4 {
		t.Fatalf("first group %+v", g)
	}
	if g := got.Groups[1]; g.Children[0].ID[0] != 6 {
		t.Fatalf("second group %+v", g)
	}
	// The pair loses person 2, so it is dropped; the person is unread, so the
	// couple with 7 goes too; the couple with 8 has an unread partner.
	if len(got.Couples) != 0 {
		t.Fatalf("couples %+v, want none", got.Couples)
	}
	// With the person and the partner read, the couples stay.
	read = conclusionsummaries.NewSummaries(
		[]conclusionsummaries.PersonSummary{person(1), person(2), person(3), person(7)},
		[]conclusionsummaries.EventSummary{event(20), event(22)}, nil)
	got = dropUnread(family, read)
	if len(got.Couples) != 2 || len(got.Couples[0].Marriages) != 1 || got.Couples[1].B[0] != 7 {
		t.Fatalf("couples %+v", got.Couples)
	}
	// An unread person leaves the first group even when no one else is left.
	got = dropUnread(Family{Person: id(1), Groups: family.Groups[:1]}, conclusionsummaries.NewSummaries(nil, nil, nil))
	if len(got.Groups) != 1 || len(got.Groups[0].Children) != 0 {
		t.Fatalf("groups %+v, want the first group kept empty", got.Groups)
	}
}
