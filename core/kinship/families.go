package kinship

import (
	"bytes"
	"slices"

	"github.com/Jake-Robins-Studios/provenencia/core/segmentcompare"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

// Role is a nuclear-family role of a relative, read from the person's end.
type Role int

const (
	RoleParent Role = iota + 1
	RoleChild
	RoleSpouse
	RoleSibling
)

// roleRow says which relationship term puts a link in a role, and which end of
// the term the person stands at. For an undirected term both ends read alike
// and the person may stand at either.
type roleRow struct {
	role Role
	term vocabkey.BridgeTerm
	at   termEnd
}

type termEnd int

const (
	atFirst termEnd = iota + 1
	atSecond
)

// nuclearRoles are the roles KinOf reads, in output order. A grandparent role
// is one more row.
var nuclearRoles = []roleRow{
	{RoleParent, vocabkey.TermParent, atSecond},
	{RoleChild, vocabkey.TermParent, atFirst},
	{RoleSpouse, vocabkey.TermSpouse, atFirst},
	{RoleSibling, vocabkey.TermSibling, atFirst},
}

// Roles returns the roles KinOf reads, in output order: the one list of them.
func Roles() []Role {
	roles := make([]Role, len(nuclearRoles))
	for i, row := range nuclearRoles {
		roles[i] = row.role
	}
	return roles
}

// Kin is a person's links by role, each in link order.
type Kin map[Role][]Link

// Around returns the distinct ids of person's parents then person's children, in
// order: the people whose own kin FamilyUnits reads.
func (k Kin) Around(person []byte) [][]byte {
	var ids [][]byte
	seen := map[string]bool{}
	for _, role := range []Role{RoleParent, RoleChild} {
		for _, l := range k[role] {
			other, _, _ := l.From(person)
			if !seen[string(other)] {
				seen[string(other)] = true
				ids = append(ids, other)
			}
		}
	}
	return ids
}

// KinOf reads person's links through nuclearRoles: each link is in every role
// whose key it carries from person's end, while the role holds fewer than
// rules.MaxKinPerRole links, so each role keeps its first links in link order.
// Any other link is in no role.
func KinOf(person []byte, links []Link, terms segmentcompare.Terms, rules Rules) Kin {
	kin := Kin{}
	for _, row := range nuclearRoles {
		keyFirst, keySecond, ok := relationshipKeys(row.term, terms)
		if !ok {
			continue
		}
		undirected := keyFirst == keySecond
		for _, l := range links {
			first, second, ok := readsTerm(l.Edge, row.term, terms)
			if !ok {
				continue
			}
			stands := first
			if row.at == atSecond {
				stands = second
			}
			if len(kin[row.role]) >= rules.MaxKinPerRole {
				break
			}
			if bytes.Equal(person, stands) || undirected && (bytes.Equal(person, first) || bytes.Equal(person, second)) {
				kin[row.role] = append(kin[row.role], l)
			}
		}
	}
	return kin
}

// UnitKind is what a family unit is to the person.
type UnitKind int

const (
	UnitParents   UnitKind = iota + 1 // Partners: a set of person's parents; Children: siblings through each of them
	UnitPartner                       // Partners: one partner; Children: person's children with them
	UnitOneParent                     // Children: person's children with no other known parent
	UnitSiblings                      // Children: siblings with no shown shared parent
)

// Relative is one person in a unit and person's own link to them; Link is nil
// for a co-parent known only through a child.
type Relative struct {
	ID   []byte
	Link *Link
}

// Unit is one family unit of a person.
type Unit struct {
	Kind     UnitKind
	Partners []Relative
	Children []Relative
}

// Empty reports whether the unit names nobody it is about: a parents or partner
// unit with no partner, a one parent or siblings unit with no child. A kind it
// does not know is empty.
func (u Unit) Empty() bool {
	switch u.Kind {
	case UnitParents, UnitPartner:
		return len(u.Partners) == 0
	case UnitOneParent, UnitSiblings:
		return len(u.Children) == 0
	}
	return true
}

// relativeOf is the relative a person's link names, with the link.
func relativeOf(person []byte, l Link) Relative {
	other, _, _ := l.From(person)
	return Relative{ID: other, Link: &l}
}

// parentIDs is the id of each of person's parent links, in link order.
func parentIDs(person []byte, kin Kin) [][]byte {
	ids := make([][]byte, len(kin[RoleParent]))
	for i, l := range kin[RoleParent] {
		ids[i], _, _ = l.From(person)
	}
	return ids
}

// spouseLinks is person's spouse links, one per spouse, the first link winning.
func spouseLinks(person []byte, kin Kin) []Link {
	var out []Link
	seen := map[string]bool{}
	for _, l := range kin[RoleSpouse] {
		other, _, _ := l.From(person)
		if !seen[string(other)] {
			seen[string(other)] = true
			out = append(out, l)
		}
	}
	return out
}

// FamilyUnits groups person's kin into units: the parent sets with the
// siblings through them, each partner with the children they share, the
// children with no other known parent, and the siblings with no shown shared
// parent, in that order. Every Relative.Link is person's own link to that
// relative. kinOf holds the kin of each of person's parents and children, keyed
// by string(id); a missing entry has none.
func FamilyUnits(person []byte, kin Kin, kinOf map[string]Kin, rules Rules) []Unit {
	units, siblings := parentUnits(person, kin, kinOf, rules)
	partners, oneParent := partnerUnits(person, kin, kinOf)
	units = append(units, partners...)
	for _, u := range []Unit{oneParent, siblings} {
		if !u.Empty() {
			units = append(units, u)
		}
	}
	return units
}

// parentUnits makes the parent sets and the siblings through them, and returns
// apart the unit of siblings with no shown shared parent.
//
// More parents than rules.MaxPivotEnd read as malformed data: none is paired
// with another, and a sibling is placed once, with the first parent it shares
// (in parent order), or in the siblings unit when it shares none. That keeps
// what is shown linear in the data. With the registry rules Siblings implies no
// sibling past the bound, so that placement is a defence for a sibling link
// that carries shared-parent shapes from elsewhere.
func parentUnits(person []byte, kin Kin, kinOf map[string]Kin, rules Rules) ([]Unit, Unit) {
	parents := kin[RoleParent]
	ids := parentIDs(person, kin)
	// paired: two parents are one set when either files a spouse link to the
	// other, or the person's links to both carry a birth_parents shape with the
	// same pivot.
	paired := func(i, j int) bool {
		if _, ok := spouseLink(kinOf, ids[i], ids[j]); ok {
			return true
		}
		for _, x := range parents[i].Shapes {
			if x.Pattern != PatternBirthParents {
				continue
			}
			for _, y := range parents[j].Shapes {
				if y.Pattern == PatternBirthParents && bytes.Equal(x.Pivot, y.Pivot) {
					return true
				}
			}
		}
		return false
	}
	var sets [][]int
	inPair := make([]bool, len(parents))
	pairing := pairsParents(len(parents), rules)
	for i := range parents {
		for j := i + 1; pairing && j < len(parents); j++ {
			if paired(i, j) {
				sets = append(sets, []int{i, j})
				inPair[i], inPair[j] = true, true
			}
		}
		if !inPair[i] {
			sets = append(sets, []int{i})
		}
	}
	// A lone parent is emitted at its own place, after the pairs at lower i that
	// name it, so inPair for i is complete when i is reached.
	units := make([]Unit, len(sets))
	for k, set := range sets {
		units[k].Kind = UnitParents
		for _, i := range set {
			units[k].Partners = append(units[k].Partners, relativeOf(person, parents[i]))
		}
	}

	var unplaced Unit
	unplaced.Kind = UnitSiblings
	var extra []Unit
	var extraAt [][]int
	for _, l := range kin[RoleSibling] {
		sib := relativeOf(person, l)
		shared := sharedParents(l, ids)
		joined := false
		if !pairing {
			// Every set is one parent, at that parent's index.
			if len(shared) > 0 {
				units[shared[0]].Children = append(units[shared[0]].Children, sib)
				joined = true
			}
		} else {
			for k, set := range sets {
				if len(set) > 0 && subset(set, shared) {
					units[k].Children = append(units[k].Children, sib)
					joined = true
				}
			}
		}
		switch {
		case joined:
		case len(shared) == 0:
			unplaced.Children = append(unplaced.Children, sib)
		default:
			at := slices.IndexFunc(extraAt, func(x []int) bool { return slices.Equal(x, shared) })
			if at < 0 {
				at = len(extra)
				extraAt = append(extraAt, shared)
				u := Unit{Kind: UnitParents}
				for _, i := range shared {
					u.Partners = append(u.Partners, relativeOf(person, parents[i]))
				}
				extra = append(extra, u)
			}
			extra[at].Children = append(extra[at].Children, sib)
		}
	}
	return append(units, extra...), unplaced
}

// sharedParents is the indexes, in parent order, of the person's parents (their
// ids, parentIDs) that l carries a shared-parent shape through: the one meaning
// of "shares a parent".
func sharedParents(l Link, parentIDs [][]byte) []int {
	var shared []int
	for i, id := range parentIDs {
		if slices.ContainsFunc(l.Shapes, func(s Shape) bool {
			return s.Pattern == PatternSharedParent && bytes.Equal(s.Pivot, id)
		}) {
			shared = append(shared, i)
		}
	}
	return shared
}

// spouseLink is the spouse link joining a and b: a's link to b if a files one,
// else b's link to a.
func spouseLink(kinOf map[string]Kin, a, b []byte) (Link, bool) {
	if l, ok := filedSpouseLink(kinOf, a, b); ok {
		return l, true
	}
	return filedSpouseLink(kinOf, b, a)
}

// filedSpouseLink is the spouse link a files to c.
func filedSpouseLink(kinOf map[string]Kin, a, c []byte) (Link, bool) {
	for _, s := range kinOf[string(a)][RoleSpouse] {
		if other, _, ok := s.From(a); ok && bytes.Equal(other, c) {
			return s, true
		}
	}
	return Link{}, false
}

// pairsParents reports whether n parents are few enough to be paired: past
// rules.MaxPivotEnd they read as malformed data and none is paired.
func pairsParents(n int, rules Rules) bool { return n <= rules.MaxPivotEnd }

// subset reports whether every index of set is in of.
func subset(set, of []int) bool {
	for _, i := range set {
		if !slices.Contains(of, i) {
			return false
		}
	}
	return true
}

// partnerUnits makes one unit per partner, and the unit of children with no
// other known parent.
func partnerUnits(person []byte, kin Kin, kinOf map[string]Kin) (partners []Unit, oneParent Unit) {
	oneParent.Kind = UnitOneParent
	at := map[string]int{}
	for _, l := range spouseLinks(person, kin) {
		p := relativeOf(person, l)
		at[string(p.ID)] = len(partners)
		partners = append(partners, Unit{Kind: UnitPartner, Partners: []Relative{p}})
	}
	for _, l := range kin[RoleChild] {
		child := relativeOf(person, l)
		others := 0
		for _, pl := range kinOf[string(child.ID)][RoleParent] {
			other, _, ok := pl.From(child.ID)
			if !ok || bytes.Equal(other, person) {
				continue
			}
			others++
			i, known := at[string(other)]
			if !known {
				i = len(partners)
				at[string(other)] = i
				partners = append(partners, Unit{Kind: UnitPartner, Partners: []Relative{{ID: other}}})
			}
			if !slices.ContainsFunc(partners[i].Children, func(c Relative) bool { return bytes.Equal(c.ID, child.ID) }) {
				partners[i].Children = append(partners[i].Children, child)
			}
		}
		if others == 0 {
			oneParent.Children = append(oneParent.Children, child)
		}
	}
	return partners, oneParent
}

// SiblingGroup is the person's siblings who share exactly the same of the
// person's parents. Parents are the person's own parent links; Children are the
// person's sibling links, with the person last in the person's group (a nil
// Link).
type SiblingGroup struct {
	Parents  []Relative
	Children []Relative
}

// SiblingGroups groups the person and every sibling by the parents they share
// with the person: a sibling's signature is the person's parents its link
// carries a shared-parent shape through (sharedParents), and the person's is
// every parent. The person's group is first, and holds the person last after its
// siblings in link order, even with no parents (then it holds every sibling who
// shares none). The other groups follow by signature length, longest first, then
// by the signature's indexes compared in order, so a signature of no parents is
// last when it is not the person's. Children are in link order.
func SiblingGroups(person []byte, kin Kin) []SiblingGroup {
	parents := kin[RoleParent]
	ids := parentIDs(person, kin)
	own := make([]int, len(parents))
	for i := range parents {
		own[i] = i
	}
	type group struct {
		sig      []int
		children []Relative
	}
	groups := []*group{{sig: own}}
	for _, l := range kin[RoleSibling] {
		sig := sharedParents(l, ids)
		at := slices.IndexFunc(groups, func(g *group) bool { return slices.Equal(g.sig, sig) })
		if at < 0 {
			at = len(groups)
			groups = append(groups, &group{sig: sig})
		}
		groups[at].children = append(groups[at].children, relativeOf(person, l))
	}
	groups[0].children = append(groups[0].children, Relative{ID: person})
	rest := groups[1:]
	slices.SortStableFunc(rest, func(a, b *group) int {
		if len(a.sig) != len(b.sig) {
			return len(b.sig) - len(a.sig)
		}
		return slices.Compare(a.sig, b.sig)
	})
	out := make([]SiblingGroup, len(groups))
	for k, g := range groups {
		out[k].Children = g.children
		for _, i := range g.sig {
			out[k].Parents = append(out[k].Parents, relativeOf(person, parents[i]))
		}
	}
	return out
}

// Couple is two people the page shows together and the marriage events both are
// subjects of: the pivots of the spouse-implying shapes of their spouse link,
// distinct, in shape order (uncapped). A is the person for a partner, the
// earlier parent for a pair of parents.
type Couple struct {
	A, B   []byte
	Pivots [][]byte
}

// Couples lists the couples the page shows that carry at least one marriage
// event pivot: first the person with each spouse in kin[RoleSpouse] (once per
// spouse, the first link winning), then each two of the person's parents, in
// parent order, joined by a spouse link (spouseLink), only where pairsParents
// allows for the parent count. A partner's marriages come from the person's own link; a pair of parents' from
// the link spouseLink returns, since kinOf holds neither the person nor a
// partner. A spouse link with no spouse-implying shape makes no couple.
func Couples(person []byte, kin Kin, kinOf map[string]Kin, rules Rules) []Couple {
	var out []Couple
	for _, l := range spouseLinks(person, kin) {
		other, _, _ := l.From(person)
		if pivots := marriagePivots(l); len(pivots) > 0 {
			out = append(out, Couple{A: person, B: other, Pivots: pivots})
		}
	}
	parents := kin[RoleParent]
	if !pairsParents(len(parents), rules) {
		return out
	}
	ids := parentIDs(person, kin)
	for i := range ids {
		for j := i + 1; j < len(ids); j++ {
			l, ok := spouseLink(kinOf, ids[i], ids[j])
			if !ok {
				continue
			}
			if pivots := marriagePivots(l); len(pivots) > 0 {
				out = append(out, Couple{A: ids[i], B: ids[j], Pivots: pivots})
			}
		}
	}
	return out
}

// marriagePivots is the distinct pivots, in shape order, of l's shapes whose
// pattern implies a spouse.
func marriagePivots(l Link) [][]byte {
	var pivots [][]byte
	for _, s := range l.Shapes {
		if s.Pattern.ImpliesSpouse() && !slices.ContainsFunc(pivots, func(p []byte) bool { return bytes.Equal(p, s.Pivot) }) {
			pivots = append(pivots, s.Pivot)
		}
	}
	return pivots
}
