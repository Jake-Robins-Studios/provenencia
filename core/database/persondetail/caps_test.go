package persondetail_test

import (
	"reflect"
	"slices"
	"testing"
	"time"

	"github.com/Jake-Robins-Studios/provenencia/core/catalogsession/catalogsessiontest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/canonlinks"
	"github.com/Jake-Robins-Studios/provenencia/core/database/databasetest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/persondetail"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue/datevaluetest"
	"github.com/Jake-Robins-Studios/provenencia/core/kinship"
	"github.com/Jake-Robins-Studios/provenencia/core/matchregistry"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

// capBudget is bar 2 of Spike 16: a crafted project's section draws in under a second.
const capBudget = time.Second

// TestCraftedFamily: a Person with 4,000 children reads in under a second and
// holds the first MaxKinPerRole of them (S16-01 AC-1.1).
func TestCraftedFamily(t *testing.T) {
	const children = 4000
	max := matchregistry.Default().Kinship.MaxKinPerRole
	w := newKinWorld(t)
	pat := w.person("Pat")
	var kids [][]byte
	w.k.Bulk(func() {
		for i := 0; i < children; i++ {
			kid := w.k.Person()
			w.k.Parent(pat, kid)
			kids = append(kids, kid)
		}
	})
	w.k.Commit(append([][]byte{pat}, kids...)...)

	var f persondetail.Family
	d := catalogsessiontest.Cold(w.t, w.c, 2, func() {
		var err error
		if f, _, _, err = persondetail.PersonFamily(w.c, pat, w.c.Graph().PageInputs()); err != nil {
			t.Fatal(err)
		}
	})
	databasetest.WithinBudget(t, "PersonFamily at 4,000 children", d, capBudget)

	// The first MaxKinPerRole children in link order, as the reader returns them.
	g := w.c.Graph()
	r, err := canonlinks.NewReader(g)
	if err != nil {
		t.Fatal(err)
	}
	terms, err := canonlinks.LoadTerms(g)
	if err != nil {
		t.Fatal(err)
	}
	links, err := r.Relationships([][]byte{pat}, canonlinks.Options{Siblings: true}, g.NoPageInputs())
	if err != nil {
		t.Fatal(err)
	}
	want := map[string]bool{}
	for _, l := range kinship.KinOf(pat, links[string(pat)], terms, matchregistry.Default().Kinship)[kinship.RoleChild] {
		other, _, _ := l.From(pat)
		want[string(other)] = true
	}
	got := map[string]bool{}
	for _, u := range f.Units {
		if u.Kind == kinship.UnitOneParent {
			for _, r := range u.Children {
				got[string(r.ID)] = true
			}
		}
	}
	if len(got) != max || !reflect.DeepEqual(got, want) {
		t.Fatalf("the one-parent unit holds %d children, want the first %d in link order (%d)", len(got), max, len(want))
	}
}

// TestCraftedMarriages: a couple with 200 dated marriages reads in under a
// second and sends the first 10 of its pivots in shape order, in date order
// (S16-82 AC-2.5).
func TestCraftedMarriages(t *testing.T) {
	const marriages = 200
	w := newKinWorld(t)
	pat, sam := w.person("Pat"), w.person("Sam")
	year := map[string]int{}
	var events [][]byte
	w.k.Bulk(func() {
		for i := 0; i < marriages; i++ {
			m, _ := w.k.Marriage(pat, sam)
			// Dated against creation order, so shape order and date order differ.
			year[string(m)] = 1900 - i
			w.k.Date(m, vocabkey.PropertyDate, *datevaluetest.YMD(1900-i, 0, 0))
			events = append(events, m)
		}
	})
	w.k.Commit(append([][]byte{pat, sam}, events...)...)

	var f persondetail.Family
	d := catalogsessiontest.Cold(w.t, w.c, 2, func() {
		var err error
		if f, _, _, err = persondetail.PersonFamily(w.c, pat, w.c.Graph().PageInputs()); err != nil {
			t.Fatal(err)
		}
	})
	databasetest.WithinBudget(t, "PersonFamily at 200 marriages of one couple", d, capBudget)

	// The first 10 pivots of the spouse link, in shape order, as the reader returns them.
	g := w.c.Graph()
	r, err := canonlinks.NewReader(g)
	if err != nil {
		t.Fatal(err)
	}
	terms, err := canonlinks.LoadTerms(g)
	if err != nil {
		t.Fatal(err)
	}
	links, err := r.Relationships([][]byte{pat}, canonlinks.Options{}, g.NoPageInputs())
	if err != nil {
		t.Fatal(err)
	}
	spouses := kinship.KinOf(pat, links[string(pat)], terms, matchregistry.Default().Kinship)[kinship.RoleSpouse]
	if len(spouses) != 1 {
		t.Fatalf("%d spouse links, want 1", len(spouses))
	}
	var want [][]byte
	for _, s := range spouses[0].Shapes {
		if s.Pattern == kinship.PatternMarriageSpouses && len(want) < 10 {
			want = append(want, s.Pivot)
		}
	}
	slices.SortFunc(want, func(a, b []byte) int { return year[string(a)] - year[string(b)] })
	if len(f.Couples) != 1 || !reflect.DeepEqual(f.Couples[0].Marriages, want) {
		t.Fatalf("couples %x, want one with the first 10 pivots in date order %x", f.Couples, want)
	}
}

// TestCraftedClaims: a Person with 20,000 records in one Evidence graph reads
// its claims in under a second, as one group of the first MaxEntityMembers
// (S16-01 AC-1.4).
func TestCraftedClaims(t *testing.T) {
	most := matchregistry.Default().RecordLinks.MaxEntityMembers
	w := newKinWorld(t)
	pat := w.person("Pat")
	w.k.Members(pat, 20_000)
	w.k.Commit(pat)

	var groups []persondetail.ClaimGroup
	d := catalogsessiontest.Cold(w.t, w.c, 2, func() {
		var err error
		if groups, err = persondetail.Claims(w.c, pat, w.c.Graph().PageInputs()); err != nil {
			t.Fatal(err)
		}
	})
	databasetest.WithinBudget(t, "Claims at 20,000 records in one graph", d, capBudget)
	if len(groups) != 1 || len(groups[0].Claims) != most {
		t.Fatalf("%d groups, want one of %d claims", len(groups), most)
	}
	n, err := w.c.Graph().Node(pat)
	if err != nil {
		t.Fatal(err)
	}
	first := map[string]bool{}
	for _, m := range n.AcceptedMembers()[:most] {
		first[string(m.SubjectID)] = true
	}
	for _, cl := range groups[0].Claims {
		if !first[string(cl.Subject.ID)] {
			t.Fatalf("claim %x is not among the first %d members", cl.Subject.ID, most)
		}
	}
}
