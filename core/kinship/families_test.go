package kinship_test

import (
	"bytes"
	"fmt"
	"reflect"
	"slices"
	"sort"
	"strings"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/kinship"
	"github.com/Jake-Robins-Studios/provenencia/core/kinship/kinshiptest"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

// isEvent reports whether an id is one of e(n): a participation edge has one.
func isEvent(id []byte) bool { return id[0]&0xf0 == 0x20 }

// linksFor builds the LinkSet Relationships builds for person from pure edges:
// each relationship edge with person at an end, the links the patterns imply
// with person at an end, and the siblings a shared parent implies.
func linksFor(t testing.TB, person []byte, edges []kinship.Edge) []kinship.Link {
	t.Helper()
	return linksWith(t, person, edges, rules)
}

// linksPastSiblingBound is linksFor with MaxPivotEnd raised for Siblings. With
// the registry rules Siblings implies no sibling past MaxPivotEnd parents, so
// these cases exercise SiblingGroups over kin that shows more parents than
// Siblings counted.
func linksPastSiblingBound(t testing.TB, person []byte, edges []kinship.Edge) []kinship.Link {
	t.Helper()
	siblingRules := rules
	siblingRules.MaxPivotEnd = 1 << 20
	return linksWith(t, person, edges, siblingRules)
}

// linksWith is linksFor with Siblings run under siblingRules.
func linksWith(t testing.TB, person []byte, edges []kinship.Edge, siblingRules kinship.Rules) []kinship.Link {
	t.Helper()
	set := kinship.NewLinkSet()
	var parentEdges []kinship.Edge
	for _, e := range edges {
		if isEvent(e.A) || isEvent(e.B) {
			continue
		}
		parentEdges = append(parentEdges, e)
		if bytes.Equal(e.A, person) || bytes.Equal(e.B, person) {
			set.Add(kinship.Link{Edge: e})
		}
	}
	implied := kinship.Derive(edges, terms, rules)
	for _, imp := range implied {
		if bytes.Equal(imp.A, person) || bytes.Equal(imp.B, person) {
			set.AddImplied(imp)
		}
		if imp.Pattern == kinship.PatternBirthParents {
			parentEdges = append(parentEdges, imp.Edge)
		}
	}
	for _, imp := range kinship.Siblings(person, parentEdges, terms, siblingRules) {
		set.AddImplied(imp)
	}
	return set.Links()
}

// withoutPeople drops the links whose other end is one of drop.
func withoutPeople(person []byte, links []kinship.Link, drop []byte) []kinship.Link {
	var out []kinship.Link
	for _, l := range links {
		if other, _, _ := l.From(person); !bytes.Contains(drop, other) {
			out = append(out, l)
		}
	}
	return out
}

// unitsOf groups person's family over edges as the page read does, with the
// people in drop not shown.
func unitsOf(t testing.TB, person byte, edges []kinship.Edge, drop ...byte) []kinship.Unit {
	t.Helper()
	return unitsFor(t, p(person), edges, dropIDs(drop))
}

// unitsFor is unitsOf for any person id; drop holds one-byte ids not shown.
func unitsFor(t testing.TB, person []byte, edges []kinship.Edge, drop []byte) []kinship.Unit {
	t.Helper()
	read := func(id []byte) kinship.Kin {
		return kinship.KinOf(id, withoutPeople(id, linksFor(t, id, edges), drop), terms, rules)
	}
	kin := read(person)
	kinOf := map[string]kinship.Kin{}
	for _, other := range kin.Around(person) {
		kinOf[string(other)] = read(other)
	}
	return kinship.FamilyUnits(person, kin, kinOf)
}

// groupsOf is the sibling groups of person over edges, as the page read does.
func groupsOf(t testing.TB, person byte, edges []kinship.Edge) []kinship.SiblingGroup {
	t.Helper()
	return kinship.SiblingGroups(p(person), kinship.KinOf(p(person), linksFor(t, p(person), edges), terms, rules))
}

// childIn is the child with id among groups' children, the first group holding it.
func childIn(t testing.TB, groups []kinship.SiblingGroup, id byte) kinship.Relative {
	t.Helper()
	for _, g := range groups {
		for _, r := range g.Children {
			if bytes.Equal(r.ID, p(id)) {
				return r
			}
		}
	}
	t.Fatalf("no P%d among the groups' children", id)
	return kinship.Relative{}
}

func dropIDs(drop []byte) []byte {
	out := make([]byte, len(drop))
	for i, d := range drop {
		out[i] = 0x10 + d
	}
	return out
}

func unitName(k kinship.UnitKind) string {
	switch k {
	case kinship.UnitPartner:
		return "Partner"
	case kinship.UnitOneParent:
		return "OneParent"
	}
	return fmt.Sprintf("Unit%d", k)
}

// show writes units as Kind{partners;children}, people as their numbers, each
// side sorted: partners and children are sets.
func show(units []kinship.Unit) []string {
	side := func(rs []kinship.Relative) string {
		var ns []int
		for _, r := range rs {
			ns = append(ns, int(r.ID[0]-0x10))
		}
		sort.Ints(ns)
		parts := make([]string, len(ns))
		for i, n := range ns {
			parts[i] = fmt.Sprint(n)
		}
		return strings.Join(parts, ",")
	}
	var out []string
	for _, u := range units {
		out = append(out, fmt.Sprintf("%s{%s;%s}", unitName(u.Kind), side(u.Partners), side(u.Children)))
	}
	return out
}

func relativeIn(t testing.TB, units []kinship.Unit, kind kinship.UnitKind, side string, id byte) kinship.Relative {
	t.Helper()
	for _, u := range units {
		if u.Kind != kind {
			continue
		}
		rs := u.Partners
		if side == "children" {
			rs = u.Children
		}
		for _, r := range rs {
			if bytes.Equal(r.ID, p(id)) {
				return r
			}
		}
	}
	t.Fatalf("no P%d in a %s %s", id, unitName(kind), side)
	return kinship.Relative{}
}

func shapesOf(l *kinship.Link) []string {
	var out []string
	for _, s := range l.Shapes {
		out = append(out, fmt.Sprintf("%s/%x", s.Pattern, s.Pivot))
	}
	return out
}

func TestKinOf(t *testing.T) {
	// One link of each of the eleven seeded relationship terms, filed from P1
	// to P2.
	terms11 := []vocabkey.BridgeTerm{
		vocabkey.TermParent, "child", vocabkey.TermSpouse, vocabkey.TermSibling,
		"cousin", vocabkey.TermGrandparent, "grandchild", "pibling", "nibling", "guardian", "ward",
	}
	type roles struct{ one, two []kinship.Role }
	want := map[vocabkey.BridgeTerm]roles{
		vocabkey.TermParent:  {one: []kinship.Role{kinship.RoleChild}, two: []kinship.Role{kinship.RoleParent}},
		"child":              {one: []kinship.Role{kinship.RoleParent}, two: []kinship.Role{kinship.RoleChild}},
		vocabkey.TermSpouse:  {one: []kinship.Role{kinship.RoleSpouse}, two: []kinship.Role{kinship.RoleSpouse}},
		vocabkey.TermSibling: {one: []kinship.Role{kinship.RoleSibling}, two: []kinship.Role{kinship.RoleSibling}},
	}
	if len(terms11) != 11 {
		t.Fatalf("%d terms", len(terms11))
	}
	for _, term := range terms11 {
		t.Run(string(term), func(t *testing.T) {
			l := kinship.Link{Edge: rel(1, 2, term, 1)}
			for i, person := range []byte{1, 2} {
				kin := kinship.KinOf(p(person), []kinship.Link{l}, terms, rules)
				w := want[term].one
				if i == 1 {
					w = want[term].two
				}
				var got []kinship.Role
				for _, role := range kinship.Roles() {
					if len(kin[role]) > 0 {
						got = append(got, role)
					}
				}
				if !slices.Equal(got, w) {
					t.Fatalf("P%d reads %v as roles %v, want %v", person, term, got, w)
				}
			}
		})
	}
	t.Run("a stranger", func(t *testing.T) {
		l := kinship.Link{Edge: rel(1, 2, vocabkey.TermSpouse, 1)}
		if kin := kinship.KinOf(p(3), []kinship.Link{l}, terms, rules); len(kin) != 0 {
			t.Fatalf("got %v", kin)
		}
	})
	t.Run("link order within a role", func(t *testing.T) {
		a := kinship.Link{Edge: rel(2, 1, vocabkey.TermParent, 1)}
		b := kinship.Link{Edge: rel(3, 1, vocabkey.TermParent, 2)}
		kin := kinship.KinOf(p(1), []kinship.Link{b, a}, terms, rules)
		if !reflect.DeepEqual(kin[kinship.RoleParent], []kinship.Link{b, a}) {
			t.Fatalf("got %v", kin[kinship.RoleParent])
		}
	})
}

func TestFamilies(t *testing.T) {
	const (
		marriage = vocabkey.EventMarriage
		birth    = vocabkey.EventBirth
	)
	parent := func(g, m, br byte) kinship.Edge { return rel(g, m, vocabkey.TermParent, br) }
	spouse := func(a, c, br byte) kinship.Edge { return rel(a, c, vocabkey.TermSpouse, br) }
	sibling := func(a, c, br byte) kinship.Edge { return rel(a, c, vocabkey.TermSibling, br) }
	married := func(person, event, br byte) kinship.Edge {
		return part(person, event, vocabkey.RoleSubject, marriage, br)
	}
	born := func(person, event byte, role vocabkey.Role, br byte) kinship.Edge {
		return part(person, event, role, birth, br)
	}
	// johnMaryPat is birth 1: P6 father, P7 mother, P1 subject.
	johnMaryPat := []kinship.Edge{
		born(6, 1, vocabkey.RoleFather, 21), born(7, 1, vocabkey.RoleMother, 22), born(1, 1, vocabkey.RoleSubject, 23),
	}
	// quin is birth 2: the same parents, P9 subject.
	quin := []kinship.Edge{
		born(6, 2, vocabkey.RoleFather, 24), born(7, 2, vocabkey.RoleMother, 25), born(9, 2, vocabkey.RoleSubject, 26),
	}

	cases := []struct {
		name  string
		edges []kinship.Edge
		drop  []byte
		want  []string
	}{
		{"AC-1.1", []kinship.Edge{
			married(1, 1, 1), married(2, 1, 2), married(1, 2, 3), married(3, 2, 4),
			parent(1, 4, 5), parent(2, 4, 6),
			born(1, 3, vocabkey.RoleFather, 7), born(3, 3, vocabkey.RoleMother, 8), born(5, 3, vocabkey.RoleSubject, 9),
		}, nil, []string{"Partner{2;4}", "Partner{3;5}"}},
		{"AC-1.4", []kinship.Edge{spouse(1, 2, 1), married(1, 1, 2), married(2, 1, 3)}, nil, []string{"Partner{2;}"}},
		{"AC-1.7", []kinship.Edge{parent(1, 12, 1), parent(13, 12, 2)}, nil, []string{"Partner{13;12}"}},
		{"AC-1.8", []kinship.Edge{parent(1, 14, 1), spouse(1, 2, 2)}, nil, []string{"Partner{2;}", "OneParent{;14}"}},
		{"AC-1.10", []kinship.Edge{parent(6, 1, 1), spouse(1, 6, 2)}, nil, []string{"Partner{6;}"}},
		{"AC-1.11", []kinship.Edge{
			rel(8, 1, vocabkey.TermGrandparent, 1), rel(1, 9, "cousin", 2), rel(10, 1, "guardian", 3),
			parent(6, 7, 4), parent(7, 1, 5),
		}, nil, nil},
		{"a child whose only other parent is not shown", []kinship.Edge{parent(1, 4, 1), parent(2, 4, 2)}, []byte{2},
			[]string{"OneParent{;4}"}},
		{"a child with two other parents", []kinship.Edge{parent(1, 4, 1), parent(2, 4, 2), parent(3, 4, 3)}, nil,
			[]string{"Partner{2;4}", "Partner{3;4}"}},
		{"the one-parent unit comes last", slices.Concat(johnMaryPat, []kinship.Edge{sibling(1, 11, 1), parent(1, 14, 2), spouse(1, 2, 3)}), nil,
			[]string{"Partner{2;}", "OneParent{;14}"}},
		{"empty kin", nil, nil, nil},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got := show(unitsOf(t, 1, tc.edges, tc.drop...))
			if len(got) == 0 && len(tc.want) == 0 {
				return
			}
			if !reflect.DeepEqual(got, tc.want) {
				t.Fatalf("got  %v\nwant %v", got, tc.want)
			}
		})
	}

	t.Run("links say why", func(t *testing.T) {
		// AC-1.1: Sam is implied through the marriage; Uma is recorded.
		units := unitsOf(t, 1, []kinship.Edge{
			married(1, 1, 1), married(2, 1, 2), parent(1, 4, 5), parent(2, 4, 6),
		})
		sam := relativeIn(t, units, kinship.UnitPartner, "partners", 2)
		if sam.Link == nil || !sam.Link.OnlyImplied || !slices.Equal(shapesOf(sam.Link), []string{"marriage_spouses/21"}) {
			t.Fatalf("Sam's link %+v", sam.Link)
		}
		uma := relativeIn(t, units, kinship.UnitPartner, "children", 4)
		if uma.Link == nil || uma.Link.OnlyImplied || !reflect.DeepEqual(uma.Link.Associations, [][]byte{b(5)}) {
			t.Fatalf("Uma's link %+v", uma.Link)
		}
		// AC-1.4: a recorded spouse link also implied by the marriage.
		units = unitsOf(t, 1, []kinship.Edge{spouse(1, 2, 1), married(1, 1, 2), married(2, 1, 3)})
		sam = relativeIn(t, units, kinship.UnitPartner, "partners", 2)
		if sam.Link == nil || sam.Link.OnlyImplied || !slices.Equal(shapesOf(sam.Link), []string{"marriage_spouses/21"}) || !slices.ContainsFunc(sam.Link.Associations, func(a []byte) bool { return bytes.Equal(a, b(1)) }) {
			t.Fatalf("Sam's recorded link %+v", sam.Link)
		}
		// AC-1.5: Quin's link has a shared_parent shape through each parent, Rae's
		// through one.
		groups := groupsOf(t, 1, slices.Concat(johnMaryPat, quin, []kinship.Edge{parent(7, 10, 1)}))
		q := childIn(t, groups, 9)
		if !slices.Equal(shapesOf(q.Link), []string{"shared_parent/16", "shared_parent/17"}) {
			t.Fatalf("Quin's shapes %v", shapesOf(q.Link))
		}
		r := childIn(t, groups, 10)
		if !slices.Equal(shapesOf(r.Link), []string{"shared_parent/17"}) {
			t.Fatalf("Rae's shapes %v", shapesOf(r.Link))
		}
		// AC-1.6: a recorded sibling who also shares parents is recorded and implied.
		groups = groupsOf(t, 1, slices.Concat(johnMaryPat, quin, []kinship.Edge{sibling(1, 9, 2)}))
		q = childIn(t, groups, 9)
		if q.Link.OnlyImplied || len(q.Link.Shapes) == 0 {
			t.Fatalf("Quin's link %+v", q.Link)
		}
		// AC-1.7: a co-parent known only through a child has no link.
		units = unitsOf(t, 1, []kinship.Edge{parent(1, 12, 1), parent(13, 12, 2)})
		if xan := relativeIn(t, units, kinship.UnitPartner, "partners", 13); xan.Link != nil {
			t.Fatalf("Xan has link %+v", xan.Link)
		}
		if wren := relativeIn(t, units, kinship.UnitPartner, "children", 12); wren.Link == nil {
			t.Fatal("Wren has no link")
		}
	})
}

// crowd is Pat (P1) with parents recorded parents, each pair married to each
// other, and sibs siblings who each have every one of them as a parent. Their
// ids are two bytes, so the count is not held to the p() range.
func crowd(t testing.TB, parents, sibs int) (pat []byte, edges []kinship.Edge) {
	t.Helper()
	pat = p(1)
	id := func(hi, n int) []byte { return []byte{byte(hi), byte(n)} }
	link := func(a, c []byte, term vocabkey.BridgeTerm, br int) {
		x := rel(1, 2, term, 1)
		x.A, x.B, x.Associations = a, c, [][]byte{id(0x30, br)}
		edges = append(edges, x)
	}
	br := 0
	for i := 0; i < parents; i++ {
		br++
		link(id(0x50, i), pat, vocabkey.TermParent, br)
		for j := i + 1; j < parents; j++ {
			br++
			link(id(0x50, i), id(0x50, j), vocabkey.TermSpouse, br)
		}
		for s := 0; s < sibs; s++ {
			br++
			link(id(0x50, i), id(0x60, s), vocabkey.TermParent, br)
		}
	}
	return pat, edges
}

// placements counts every relative in every unit, and the shapes on their links.
func placements(units []kinship.Unit) (relatives, shapes int) {
	for _, u := range units {
		for _, rs := range [][]kinship.Relative{u.Partners, u.Children} {
			for _, r := range rs {
				relatives++
				if r.Link != nil {
					shapes += len(r.Link.Shapes)
				}
			}
		}
	}
	return relatives, shapes
}

// pairs is Pat (P1) with parents recorded parents, each parent-to-Pat link
// carrying assocs associations, and one sibling for each pair of parents,
// whose parent links to that pair carry assocs associations each.
func pairs(t testing.TB, parents, assocs int) (pat []byte, edges []kinship.Edge, input int) {
	t.Helper()
	pat = p(1)
	id := func(hi, n int) []byte { return []byte{byte(hi), byte(n)} }
	br := 0
	link := func(a, c []byte) {
		x := rel(1, 2, vocabkey.TermParent, 1)
		x.A, x.B, x.Associations = a, c, nil
		for k := 0; k < assocs; k++ {
			br++
			x.Associations = append(x.Associations, id(0x30, br))
		}
		input += assocs
		edges = append(edges, x)
	}
	for i := 0; i < parents; i++ {
		link(id(0x50, i), pat)
	}
	sib := 0
	for i := 0; i < parents; i++ {
		for j := i + 1; j < parents; j++ {
			link(id(0x50, i), id(0x60, sib))
			link(id(0x50, j), id(0x60, sib))
			sib++
		}
	}
	return pat, edges, input
}

func TestSiblingGroupsGrowth(t *testing.T) {
	// A sibling is placed in one group and a group has the person's parents it
	// shares, so what is drawn stays bounded by the kin, whatever the count of
	// parents or of subsets of them.
	check := func(t *testing.T, pat []byte, edges []kinship.Edge) {
		t.Helper()
		kin := kinship.KinOf(pat, linksPastSiblingBound(t, pat, edges), terms, rules)
		groups := kinship.SiblingGroups(pat, kin)
		children, parents := 0, 0
		for _, g := range groups {
			children += len(g.Children)
			parents += len(g.Parents)
		}
		if want := len(kin[kinship.RoleSibling]) + 1; children != want {
			t.Fatalf("%d children in the groups, want %d", children, want)
		}
		if len(groups) > children {
			t.Fatalf("%d groups for %d children", len(groups), children)
		}
		if parents > len(groups)*len(kin[kinship.RoleParent]) {
			t.Fatalf("%d parents in %d groups of %d parents", parents, len(groups), len(kin[kinship.RoleParent]))
		}
	}
	for _, n := range []int{11, 22} {
		t.Run(fmt.Sprintf("crowd %d", n), func(t *testing.T) {
			pat, edges := crowd(t, n, 2*n)
			check(t, pat, edges)
		})
	}
	for _, parents := range []int{11, 14} {
		t.Run(fmt.Sprintf("pairs %d", parents), func(t *testing.T) {
			pat, edges, _ := pairs(t, parents, 3)
			check(t, pat, edges)
		})
	}
}

func TestUnitEmpty(t *testing.T) {
	r := []kinship.Relative{{ID: p(2)}}
	for _, tc := range []struct {
		kind         kinship.UnitKind
		partnersHold bool // the side that makes the unit non-empty
	}{
		{kinship.UnitPartner, true},
		{kinship.UnitOneParent, false},
	} {
		t.Run(unitName(tc.kind), func(t *testing.T) {
			onlyPartners := kinship.Unit{Kind: tc.kind, Partners: r}
			onlyChildren := kinship.Unit{Kind: tc.kind, Children: r}
			if onlyPartners.Empty() == tc.partnersHold || onlyChildren.Empty() != tc.partnersHold {
				t.Fatalf("empty: only partners %v, only children %v", onlyPartners.Empty(), onlyChildren.Empty())
			}
			if !(kinship.Unit{Kind: tc.kind}).Empty() {
				t.Fatal("a unit with neither side is not empty")
			}
		})
	}
}

func TestKinAround(t *testing.T) {
	links := []kinship.Link{
		{Edge: rel(6, 1, vocabkey.TermParent, 1)},
		{Edge: rel(1, 9, vocabkey.TermParent, 2)},
		{Edge: rel(6, 1, vocabkey.TermParent, 3)},
		{Edge: rel(1, 8, vocabkey.TermSpouse, 4)},
	}
	got := kinship.KinOf(p(1), links, terms, rules).Around(p(1))
	if !reflect.DeepEqual(got, [][]byte{p(6), p(9)}) {
		t.Fatalf("got %v", got)
	}
}

// FuzzFamilyUnits reads a byte string as edges among fifteen people (three
// bytes each: kind, a, c) and checks that grouping never panics, that the units
// it shows are bounded by the data, and that the sibling groups place each
// sibling once.
func FuzzFamilyUnits(f *testing.F) {
	for _, seed := range [][]byte{
		{0, 6, 1, 0, 7, 1, 1, 6, 7},           // two married parents
		{0, 6, 1, 0, 7, 1},                    // two parents, no pairing
		{0, 1, 14, 1, 1, 2},                   // a child and a spouse
		{0, 6, 1, 1, 1, 6},                    // a parent who is also a spouse
		{0, 6, 1, 0, 6, 9, 2, 1, 11, 2, 1, 9}, // siblings through a parent and recorded
		{0, 2, 1, 0, 3, 1, 0, 4, 1, 0, 5, 1, 0, 6, 1, 0, 7, 1, 0, 8, 1, 0, 9, 1, 0, 10, 1, 0, 11, 1, 0, 12, 1, 0, 2, 13, 0, 3, 13, 0, 12, 13}, // eleven parents and a sibling
	} {
		f.Add(seed)
	}
	f.Fuzz(func(t *testing.T, data []byte) {
		var edges []kinship.Edge
		for i := 0; i+2 < len(data) && i < 3*400; i += 3 {
			a, c := data[i+1]%15+1, data[i+2]%15+1
			if a == c {
				continue
			}
			switch data[i] % 3 {
			case 0:
				edges = append(edges, rel(a, c, vocabkey.TermParent, byte(i)))
			case 1:
				edges = append(edges, rel(a, c, vocabkey.TermSpouse, byte(i)))
			default:
				edges = append(edges, rel(a, c, vocabkey.TermSibling, byte(i)))
			}
		}
		units := unitsFor(t, p(1), edges, nil)
		kin := kinship.KinOf(p(1), linksFor(t, p(1), edges), terms, rules)
		bound := (len(kin[kinship.RoleChild])+1)*(len(edges)+1) + len(kin[kinship.RoleSpouse])
		if relatives, _ := placements(units); relatives > bound {
			t.Fatalf("%d relatives shown, bound %d", relatives, bound)
		}
		children := 0
		for _, g := range kinship.SiblingGroups(p(1), kin) {
			children += len(g.Children)
		}
		if want := len(kin[kinship.RoleSibling]) + 1; children != want {
			t.Fatalf("%d children in the sibling groups, want %d", children, want)
		}
	})
}

func TestKinOfCap(t *testing.T) {
	child := func(n int) kinship.Link {
		return kinship.Link{Edge: kinshiptest.Rel([]byte("person"), []byte(fmt.Sprintf("c%04d", n)), vocabkey.TermParent, []byte{1})}
	}
	children := func(n int) []kinship.Link {
		var links []kinship.Link
		for i := 0; i < n; i++ {
			links = append(links, child(i))
		}
		return links
	}
	max := rules.MaxKinPerRole
	t.Run("at the cap all are kept", func(t *testing.T) {
		if got := kinship.KinOf([]byte("person"), children(max), terms, rules)[kinship.RoleChild]; len(got) != max {
			t.Fatalf("kept %d, want %d", len(got), max)
		}
	})
	t.Run("one over keeps the first in link order", func(t *testing.T) {
		links := children(max + 1)
		got := kinship.KinOf([]byte("person"), links, terms, rules)[kinship.RoleChild]
		if !reflect.DeepEqual(got, links[:max]) {
			t.Fatalf("kept %d links, want the first %d", len(got), max)
		}
	})
	t.Run("each role has its own cap", func(t *testing.T) {
		var links []kinship.Link
		for i := 0; i < max+1; i++ {
			links = append(links, kinship.Link{Edge: kinshiptest.Rel([]byte(fmt.Sprintf("p%04d", i)), []byte("person"), vocabkey.TermParent, []byte{1})})
		}
		for i := 0; i < 3; i++ {
			links = append(links, kinship.Link{Edge: kinshiptest.Rel([]byte("person"), []byte(fmt.Sprintf("s%d", i)), vocabkey.TermSpouse, []byte{1})})
		}
		kin := kinship.KinOf([]byte("person"), links, terms, rules)
		if len(kin[kinship.RoleParent]) != max || len(kin[kinship.RoleSpouse]) != 3 {
			t.Fatalf("parents %d spouses %d, want %d and 3", len(kin[kinship.RoleParent]), len(kin[kinship.RoleSpouse]), max)
		}
	})
	t.Run("2,000 children around is the first cap", func(t *testing.T) {
		kin := kinship.KinOf([]byte("person"), children(2000), terms, rules)
		around := kin.Around([]byte("person"))
		if len(around) != max || string(around[0]) != "c0000" || string(around[max-1]) != fmt.Sprintf("c%04d", max-1) {
			t.Fatalf("Around holds %d, want the first %d children", len(around), max)
		}
	})
}

func TestSpousePatterns(t *testing.T) {
	if got := kinship.SpouseEventTypes(); !reflect.DeepEqual(got, []vocabkey.EventType{vocabkey.EventMarriage}) {
		t.Errorf("SpouseEventTypes = %v, want [marriage]", got)
	}
	for pattern, want := range map[kinship.Pattern]bool{
		kinship.PatternMarriageSpouses: true,
		kinship.PatternBirthParents:    false,
		kinship.PatternSharedParent:    false,
	} {
		if got := pattern.ImpliesSpouse(); got != want {
			t.Errorf("%s.ImpliesSpouse() = %v, want %v", pattern, got, want)
		}
	}
}

// parentsOf is person 1's parent links to each id.
func parentsOf(ids ...byte) []kinship.Link {
	var ls []kinship.Link
	for _, id := range ids {
		ls = append(ls, linkTo(1, id))
	}
	return ls
}

// linkTo is person's link to other, carrying shapes.
func linkTo(person, other byte, shapes ...kinship.Shape) kinship.Link {
	return kinship.Link{Edge: kinship.Edge{A: p(person), B: p(other)}, Recording: kinship.Recording{Shapes: shapes}}
}

func sharedVia(parent byte) kinship.Shape {
	return kinship.Shape{Pattern: kinship.PatternSharedParent, Pivot: p(parent)}
}

func marriedAt(event byte) kinship.Shape {
	return kinship.Shape{Pattern: kinship.PatternMarriageSpouses, Pivot: e(event)}
}

// showGroups writes each group as "parents:children" in order, people as their
// numbers and a nil-link member (the person) in brackets.
func showGroups(groups []kinship.SiblingGroup) []string {
	side := func(rs []kinship.Relative) string {
		parts := make([]string, len(rs))
		for i, r := range rs {
			parts[i] = fmt.Sprint(int(r.ID[0] - 0x10))
			if r.Link == nil {
				parts[i] = "[" + parts[i] + "]"
			}
		}
		return strings.Join(parts, ",")
	}
	var out []string
	for _, g := range groups {
		out = append(out, side(g.Parents)+":"+side(g.Children))
	}
	return out
}

func TestSiblingGroups(t *testing.T) {
	// Person 1; parents 2 (Heinrich), 3 (Anna), 4 (Katharina); siblings 5.. .
	cases := []struct {
		name string
		kin  kinship.Kin
		want []string
	}{
		{"AC-1.1", kinship.Kin{
			kinship.RoleParent:  parentsOf(2, 3),
			kinship.RoleSibling: {linkTo(1, 5, sharedVia(2), sharedVia(3)), linkTo(1, 6, sharedVia(2), sharedVia(3)), linkTo(1, 7, sharedVia(3))},
		}, []string{"2,3:5,6,[1]", "3:7"}},
		{"AC-1.2", kinship.Kin{
			kinship.RoleParent: parentsOf(2, 3, 4),
			kinship.RoleSibling: {
				linkTo(1, 5, sharedVia(2), sharedVia(3)), linkTo(1, 6, sharedVia(2), sharedVia(3), sharedVia(4)),
				linkTo(1, 7, sharedVia(2), sharedVia(4)), linkTo(1, 8, sharedVia(2), sharedVia(3)),
			},
		}, []string{"2,3,4:6,[1]", "2,3:5,8", "2,4:7"}},
		{"AC-1.3", kinship.Kin{
			kinship.RoleParent:  parentsOf(2, 3),
			kinship.RoleSibling: {linkTo(1, 5, sharedVia(3)), linkTo(1, 6, sharedVia(2))},
		}, []string{"2,3:[1]", "2:6", "3:5"}},
		{"AC-1.4", kinship.Kin{
			kinship.RoleParent: parentsOf(2, 3, 4, 8),
			kinship.RoleSibling: {
				linkTo(1, 9), linkTo(1, 7, sharedVia(4), sharedVia(8)),
				linkTo(1, 5, sharedVia(2), sharedVia(3)), linkTo(1, 6, sharedVia(2), sharedVia(3)),
			},
		}, []string{"2,3,4,8:[1]", "2,3:5,6", "4,8:7", ":9"}},
		{"AC-1.5", kinship.Kin{kinship.RoleSibling: {linkTo(1, 5), linkTo(1, 6)}}, []string{":5,6,[1]"}},
		{"AC-1.6", kinship.Kin{}, []string{":[1]"}},
		{"eleven parents", kinship.Kin{
			kinship.RoleParent:  parentsOf(2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12),
			kinship.RoleSibling: {linkTo(1, 13, sharedVia(12))},
		}, []string{"2,3,4,5,6,7,8,9,10,11,12:[1]", "12:13"}},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			groups := kinship.SiblingGroups(p(1), c.kin)
			if got := showGroups(groups); !slices.Equal(got, c.want) {
				t.Errorf("groups = %q, want %q", got, c.want)
			}
		})
	}
}

// showCouples writes each couple as "a+b:pivots", people and events as their
// numbers.
func showCouples(cs []kinship.Couple) []string {
	var out []string
	for _, c := range cs {
		var ev []string
		for _, pv := range c.Pivots {
			ev = append(ev, fmt.Sprint(int(pv[0]-0x20)))
		}
		out = append(out, fmt.Sprintf("%d+%d:%s", c.A[0]-0x10, c.B[0]-0x10, strings.Join(ev, ",")))
	}
	return out
}

func TestCouples(t *testing.T) {
	birthShape := kinship.Shape{Pattern: kinship.PatternBirthParents, Pivot: e(9)}
	// A married pair of parents 2 and 3 of person 1: only 3 files the spouse link.
	cases := []struct {
		name  string
		kin   kinship.Kin
		kinOf map[string]kinship.Kin
		want  []string
	}{
		{"two marriage shapes and a repeated pivot", kinship.Kin{
			kinship.RoleSpouse: {linkTo(1, 5, marriedAt(1), marriedAt(2), marriedAt(1))},
		}, nil, []string{"1+5:1,2"}},
		{"the same spouse twice", kinship.Kin{
			kinship.RoleSpouse: {linkTo(1, 5, marriedAt(1)), linkTo(1, 5, marriedAt(2))},
		}, nil, []string{"1+5:1"}},
		{"a spouse link with no marriage shape", kinship.Kin{
			kinship.RoleSpouse: {linkTo(1, 5, birthShape)},
		}, nil, nil},
		{"parents joined by a link filed by the second only", kinship.Kin{
			kinship.RoleParent: parentsOf(2, 3),
		}, map[string]kinship.Kin{string(p(3)): {kinship.RoleSpouse: {linkTo(3, 2, marriedAt(4))}}}, []string{"2+3:4"}},
		{"parents paired only by a shared birth", kinship.Kin{
			kinship.RoleParent: {linkTo(1, 2, birthShape), linkTo(1, 3, birthShape)},
		}, nil, nil},
		{"the person married to a parent who is married to another parent", kinship.Kin{
			kinship.RoleParent: parentsOf(2, 3),
			kinship.RoleSpouse: {linkTo(1, 2, marriedAt(1))},
		}, map[string]kinship.Kin{string(p(2)): {kinship.RoleSpouse: {linkTo(2, 3, marriedAt(2))}}}, []string{"1+2:1", "2+3:2"}},
		{"eleven parents pair none", kinship.Kin{
			kinship.RoleParent: parentsOf(2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12),
		}, map[string]kinship.Kin{string(p(2)): {kinship.RoleSpouse: {linkTo(2, 3, marriedAt(1))}}}, nil},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			got := showCouples(kinship.Couples(p(1), c.kin, c.kinOf, rules))
			if !slices.Equal(got, c.want) {
				t.Errorf("couples = %q, want %q", got, c.want)
			}
		})
	}
}
