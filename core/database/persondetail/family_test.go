package persondetail_test

import (
	"bytes"
	"errors"
	"fmt"
	"reflect"
	"slices"
	"sort"
	"strings"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/conclusiondetails"
	"github.com/Jake-Robins-Studios/provenencia/core/database/conclusionsummaries"
	"github.com/Jake-Robins-Studios/provenencia/core/database/graphcache/graphcachetest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/nameformats"
	"github.com/Jake-Robins-Studios/provenencia/core/database/persondetail"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue/datevaluetest"
	"github.com/Jake-Robins-Studios/provenencia/core/kinship"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

// kin is a catalog of canonical people named for a test, and the Canon that
// writes them.
type kinWorld struct {
	t     *testing.T
	c     *database.Catalog
	k     *graphcachetest.Canon
	names map[string]string
}

func newKinWorld(t *testing.T) *kinWorld {
	t.Helper()
	c := graphcachetest.OpenCatalog(t)
	// A project session warms the default name format; a summary read needs it.
	if err := nameformats.Warm(c); err != nil {
		t.Fatal(err)
	}
	return &kinWorld{t: t, c: c, k: graphcachetest.NewCanon(t, c), names: map[string]string{}}
}

func (w *kinWorld) person(name string) []byte {
	id := w.k.Person()
	w.names[string(id)] = name
	return id
}

func (w *kinWorld) name(id []byte) string {
	if n, ok := w.names[string(id)]; ok {
		return n
	}
	return fmt.Sprintf("%x", id)
}

func unitKind(k kinship.UnitKind) string {
	return map[kinship.UnitKind]string{
		kinship.UnitParents: "Parents", kinship.UnitPartner: "Partner",
		kinship.UnitOneParent: "OneParent", kinship.UnitSiblings: "Siblings",
	}[k]
}

// show writes units as Kind{partners;children}, each side sorted by name.
func (w *kinWorld) show(units []kinship.Unit) []string {
	side := func(rs []kinship.Relative) string {
		var ns []string
		for _, r := range rs {
			ns = append(ns, w.name(r.ID))
		}
		sort.Strings(ns)
		return strings.Join(ns, ",")
	}
	var out []string
	for _, u := range units {
		out = append(out, fmt.Sprintf("%s{%s;%s}", unitKind(u.Kind), side(u.Partners), side(u.Children)))
	}
	return out
}

func (w *kinWorld) family(id []byte) (persondetail.Family, error) {
	w.t.Helper()
	f, _, _, err := persondetail.PersonFamily(w.c, id, w.c.Graph().PageInputs())
	return f, err
}

func (w *kinWorld) expect(id []byte, want ...string) persondetail.Family {
	w.t.Helper()
	f, _, summaries, err := persondetail.PersonFamily(w.c, id, w.c.Graph().PageInputs())
	if err != nil {
		w.t.Fatal(err)
	}
	got := w.show(f.Units)
	if len(got) != 0 || len(want) != 0 {
		if !reflect.DeepEqual(got, want) {
			w.t.Fatalf("family of %s:\n got %v\nwant %v", w.name(id), got, want)
		}
	}
	for _, u := range f.Units {
		for _, r := range slices.Concat(u.Partners, u.Children) {
			if _, ok := summaries.Person(r.ID); !ok {
				w.t.Errorf("no summary for %s", w.name(r.ID))
			}
		}
	}
	return f
}

func relative(t *testing.T, f persondetail.Family, kind kinship.UnitKind, children bool, id []byte) kinship.Relative {
	t.Helper()
	for _, u := range f.Units {
		rs := u.Partners
		if children {
			rs = u.Children
		}
		if u.Kind != kind {
			continue
		}
		for _, r := range rs {
			if bytes.Equal(r.ID, id) {
				return r
			}
		}
	}
	t.Fatalf("%x is in no such unit", id)
	return kinship.Relative{}
}

func TestPersonFamily(t *testing.T) {
	t.Run("AC-1.1", func(t *testing.T) {
		w := newKinWorld(t)
		pat, sam, tess, uma, vic := w.person("Pat"), w.person("Sam"), w.person("Tess"), w.person("Uma"), w.person("Vic")
		m1, _ := w.k.Marriage(pat, sam)
		w.k.Marriage(pat, tess)
		patUma := w.k.Parent(pat, uma)
		w.k.Parent(sam, uma)
		b2, _ := w.k.Birth(vic, pat, tess)
		f := w.expect(pat, "Partner{Sam;Uma}", "Partner{Tess;Vic}")

		samLink := relative(t, f, kinship.UnitPartner, false, sam).Link
		if samLink == nil || !samLink.OnlyImplied || len(samLink.Shapes) != 1 ||
			samLink.Shapes[0].Pattern != kinship.PatternMarriageSpouses || !bytes.Equal(samLink.Shapes[0].Pivot, m1) {
			t.Fatalf("Sam's link %+v", samLink)
		}
		vicLink := relative(t, f, kinship.UnitPartner, true, vic).Link
		if vicLink == nil || !vicLink.OnlyImplied || len(vicLink.Shapes) != 1 ||
			vicLink.Shapes[0].Pattern != kinship.PatternBirthParents || !bytes.Equal(vicLink.Shapes[0].Pivot, b2) {
			t.Fatalf("Vic's link %+v", vicLink)
		}
		umaLink := relative(t, f, kinship.UnitPartner, true, uma).Link
		if umaLink == nil || umaLink.OnlyImplied || !slices.ContainsFunc(umaLink.Associations, func(a []byte) bool { return bytes.Equal(a, patUma) }) {
			t.Fatalf("Uma's link %+v", umaLink)
		}
	})
	t.Run("AC-1.2", func(t *testing.T) {
		w := newKinWorld(t)
		pat, john, mary, james := w.person("Pat"), w.person("John"), w.person("Mary"), w.person("James")
		w.k.Birth(pat, john, mary)
		w.k.Parent(james, pat)
		w.expect(pat, "Parents{James;}", "Parents{John,Mary;}")
	})
	t.Run("AC-1.5", func(t *testing.T) {
		w := newKinWorld(t)
		pat, john, mary, quin, rae := w.person("Pat"), w.person("John"), w.person("Mary"), w.person("Quin"), w.person("Rae")
		w.k.Birth(pat, john, mary)
		w.k.Birth(quin, john, mary)
		w.k.Parent(mary, rae)
		f := w.expect(pat, "Parents{John,Mary;Quin}", "Parents{Mary;Rae}")
		shapes := func(id []byte) int {
			l := relative(t, f, kinship.UnitParents, true, id).Link
			n := 0
			for _, s := range l.Shapes {
				if s.Pattern == kinship.PatternSharedParent {
					n++
				}
			}
			return n
		}
		if q, r := shapes(quin), shapes(rae); q != 2 || r != 1 {
			t.Fatalf("shared_parent shapes: Quin %d, Rae %d", q, r)
		}
	})
	t.Run("AC-1.7", func(t *testing.T) {
		w := newKinWorld(t)
		pat, wren, xan := w.person("Pat"), w.person("Wren"), w.person("Xan")
		w.k.Parent(pat, wren)
		w.k.Parent(xan, wren)
		f := w.expect(pat, "Partner{Xan;Wren}")
		if l := relative(t, f, kinship.UnitPartner, false, xan).Link; l != nil {
			t.Fatalf("Xan has link %+v", l)
		}
	})
	t.Run("AC-1.9", func(t *testing.T) {
		w := newKinWorld(t)
		pat, john, uma, other := w.person("Pat"), w.person("John"), w.person("Uma"), w.person("Other")
		w.k.Parent(john, pat)
		w.k.Parent(pat, uma)
		w.k.Provisional(john)
		w.k.Merge(uma, other)
		w.k.Commit(john, uma, other)
		w.expect(pat)
	})
	t.Run("AC-1.12", func(t *testing.T) {
		w := newKinWorld(t)
		pat, other := w.person("Pat"), w.person("Other")
		ev := w.k.Event("birth")
		merged := w.person("Merged")
		w.k.Merge(merged, other)
		w.k.Commit(merged, other)
		for name, id := range map[string][]byte{"unknown": bytes.Repeat([]byte{7}, 16), "event": ev, "merged": merged, "malformed": {1, 2, 3}} {
			if _, _, _, err := persondetail.PersonFamily(w.c, id, w.c.Graph().PageInputs()); !errors.Is(err, conclusiondetails.ErrNotFound) {
				t.Errorf("%s: err %v, want ErrNotFound", name, err)
			}
		}
		got, err := persondetail.Families(w.c, [][]byte{bytes.Repeat([]byte{7}, 16), ev, merged, {1, 2, 3}, pat}, w.c.Graph().PageInputs())
		if err != nil {
			t.Fatal(err)
		}
		if len(got) != 1 || !bytes.Equal(got[0].Person, pat) {
			t.Fatalf("Families kept %d, want only Pat", len(got))
		}
	})
	t.Run("AC-1.13", func(t *testing.T) {
		w := newKinWorld(t)
		w.expect(w.person("Lone"))
	})
	t.Run("AC-1.14", func(t *testing.T) {
		w := newKinWorld(t)
		pat, sam, uma, tess := w.person("Pat"), w.person("Sam"), w.person("Uma"), w.person("Tess")
		w.k.Marriage(pat, sam)
		w.k.Marriage(pat, tess)
		w.k.Parent(pat, uma)
		w.k.Parent(sam, uma)
		ids := [][]byte{pat, sam, uma}
		got, err := persondetail.Families(w.c, ids, w.c.Graph().PageInputs())
		if err != nil {
			t.Fatal(err)
		}
		if len(got) != len(ids) {
			t.Fatalf("%d families, want %d", len(got), len(ids))
		}
		for i, id := range ids {
			if !bytes.Equal(got[i].Person, id) {
				t.Fatalf("family %d is for %s, want %s", i, w.name(got[i].Person), w.name(id))
			}
			one, _, _, err := persondetail.PersonFamily(w.c, id, w.c.Graph().PageInputs())
			if err != nil {
				t.Fatal(err)
			}
			if !reflect.DeepEqual(got[i], one) {
				t.Errorf("Families(%s) differs from PersonFamily:\n%v\n%v", w.name(id), w.show(got[i].Units), w.show(one.Units))
			}
		}
		dup, err := persondetail.Families(w.c, [][]byte{pat, pat}, w.c.Graph().PageInputs())
		if err != nil || len(dup) != 1 {
			t.Fatalf("a repeated id gave %d families, err %v", len(dup), err)
		}
	})
	t.Run("AC-2.5", func(t *testing.T) {
		w := newKinWorld(t)
		pat, ned := w.person("Pat"), w.person("Ned")
		w.expect(pat)
		link := w.k.Parent(pat, ned)
		w.k.Commit(pat, ned, link)
		w.expect(pat, "OneParent{;Ned}")
		w.k.Remove(link)
		w.k.Commit(pat, ned, link)
		w.expect(pat)
	})
}

func TestPersonFamilyOriginSiblings(t *testing.T) {
	// origin reads the origin siblings as "name[parent sets]", each set as its
	// parents' names joined with "+".
	origin := func(w *kinWorld, id []byte) []string {
		t := w.t
		t.Helper()
		f, sibs, _, err := persondetail.PersonFamily(w.c, id, w.c.Graph().PageInputs())
		if err != nil {
			t.Fatal(err)
		}
		var parents []string
		for _, u := range f.Units {
			if u.Kind != kinship.UnitParents {
				continue
			}
			var ns []string
			for _, r := range u.Partners {
				ns = append(ns, w.name(r.ID))
			}
			sort.Strings(ns)
			parents = append(parents, strings.Join(ns, "+"))
		}
		var out []string
		for _, s := range sibs {
			var sets []string
			for _, k := range s.ParentSets {
				sets = append(sets, parents[k])
			}
			sort.Strings(sets)
			out = append(out, fmt.Sprintf("%s[%s]", w.name(s.Relative.ID), strings.Join(sets, ",")))
		}
		return out
	}
	check := func(t *testing.T, got []string, want ...string) {
		t.Helper()
		if !reflect.DeepEqual(got, want) {
			t.Fatalf("origin siblings:\n got %v\nwant %v", got, want)
		}
	}

	t.Run("one pair, birth order", func(t *testing.T) {
		w := newKinWorld(t)
		johann, heinrich, anna := w.person("Johann"), w.person("Heinrich"), w.person("Anna")
		marg, fried, wil := w.person("Margarethe"), w.person("Friedrich"), w.person("Wilhelm")
		bornIn(w, johann, 1817, heinrich, anna)
		bornIn(w, fried, 1820, heinrich, anna)
		bornIn(w, wil, 0, heinrich, anna)
		bornIn(w, marg, 1815, heinrich, anna)
		check(t, origin(w, johann), "Margarethe[Anna+Heinrich]", "Johann[Anna+Heinrich]", "Friedrich[Anna+Heinrich]", "Wilhelm[Anna+Heinrich]")
		f, _, _, err := persondetail.PersonFamily(w.c, johann, w.c.Graph().PageInputs())
		if err != nil {
			t.Fatal(err)
		}
		var kids []kinship.Relative
		for _, u := range f.Units {
			if u.Kind == kinship.UnitParents {
				kids = u.Children
			}
		}
		var got []string
		for _, r := range kids {
			got = append(got, w.name(r.ID))
		}
		if want := []string{"Margarethe", "Friedrich", "Wilhelm"}; !reflect.DeepEqual(got, want) {
			t.Fatalf("unit children %v, want %v", got, want)
		}
	})
	t.Run("two sets", func(t *testing.T) {
		w := newKinWorld(t)
		johann, heinrich, anna, kath := w.person("Johann"), w.person("Heinrich"), w.person("Anna"), w.person("Katharina")
		marg, fried, wil, chris := w.person("Margarethe"), w.person("Friedrich"), w.person("Wilhelm"), w.person("Christian")
		bornIn(w, johann, 1817, heinrich, anna)
		bornIn(w, fried, 1820, heinrich, anna)
		bornIn(w, marg, 1815, heinrich, anna)
		bornIn(w, wil, 0, heinrich, anna)
		bornIn(w, chris, 1823, nil, nil)
		for _, p := range [][]byte{johann, fried, chris} {
			w.k.Parent(heinrich, p)
			w.k.Parent(kath, p)
		}
		check(t, origin(w, johann),
			"Johann[Anna+Heinrich,Katharina]", "Friedrich[Anna+Heinrich,Katharina]",
			"Christian[Katharina]", "Margarethe[Anna+Heinrich]", "Wilhelm[Anna+Heinrich]")
	})
	t.Run("two sets sharing a parent", func(t *testing.T) {
		w := newKinWorld(t)
		johann, heinrich, anna, kath := w.person("Johann"), w.person("Heinrich"), w.person("Anna"), w.person("Katharina")
		marg, fried, wil, chris := w.person("Margarethe"), w.person("Friedrich"), w.person("Wilhelm"), w.person("Christian")
		bornIn(w, johann, 1817, heinrich, anna)
		bornIn(w, fried, 1820, heinrich, anna)
		bornIn(w, marg, 1815, heinrich, anna)
		bornIn(w, wil, 0, heinrich, anna)
		bornIn(w, chris, 1823, nil, nil)
		for _, p := range [][]byte{johann, fried, chris} {
			w.k.Parent(heinrich, p)
			w.k.Parent(kath, p)
		}
		w.k.Marriage(heinrich, kath)
		check(t, origin(w, johann),
			"Johann[Anna+Heinrich,Heinrich+Katharina]", "Friedrich[Anna+Heinrich,Heinrich+Katharina]",
			"Margarethe[Anna+Heinrich]", "Wilhelm[Anna+Heinrich]", "Christian[Heinrich+Katharina]")
	})
	t.Run("recorded sibling after the set", func(t *testing.T) {
		w := newKinWorld(t)
		pat, john, mary, quin, rae := w.person("Pat"), w.person("John"), w.person("Mary"), w.person("Quin"), w.person("Rae")
		bornIn(w, pat, 1840, john, mary)
		bornIn(w, quin, 1842, john, mary)
		w.k.Relationship(pat, rae, "sibling")
		check(t, origin(w, pat), "Pat[John+Mary]", "Quin[John+Mary]", "Rae[]")
	})
	t.Run("recorded siblings only", func(t *testing.T) {
		w := newKinWorld(t)
		clara, ida, bernhard := w.person("Clara"), w.person("Ida"), w.person("Bernhard")
		bornIn(w, clara, 1841, nil, nil)
		bornIn(w, ida, 1838, nil, nil)
		bornIn(w, bernhard, 1844, nil, nil)
		w.k.Relationship(clara, ida, "sibling")
		w.k.Relationship(clara, bernhard, "sibling")
		check(t, origin(w, clara), "Ida[]", "Clara[]", "Bernhard[]")
	})
	t.Run("a spouse only", func(t *testing.T) {
		w := newKinWorld(t)
		anna, heinrich := w.person("Anna"), w.person("Heinrich")
		w.k.Marriage(anna, heinrich)
		check(t, origin(w, anna), "Anna[]")
	})
}

// TestPersonFamilyRecordsInputs: the family read records every node the
// kinship read derives from with its neighbours and links, every relative it
// names, shown or not, and every summary it reads.
func TestPersonFamilyRecordsInputs(t *testing.T) {
	read := func(t *testing.T, w *kinWorld, id []byte) [][]byte {
		t.Helper()
		in := w.c.Graph().PageInputs()
		if _, _, _, err := persondetail.PersonFamily(w.c, id, in); err != nil {
			t.Fatal(err)
		}
		handles, graphs, srcs := in.Lists()
		if len(graphs) != 0 || len(srcs) != 0 {
			t.Errorf("graphs %x, sources %x: the Family shows no records", graphs, srcs)
		}
		return handles
	}
	t.Run("shown relatives, the marriage and the parent link", func(t *testing.T) {
		w := newKinWorld(t)
		pat, sam, tess, uma, wren, xan := w.person("Pat"), w.person("Sam"), w.person("Tess"), w.person("Uma"), w.person("Wren"), w.person("Xan")
		m1, _ := w.k.Marriage(pat, sam)
		w.k.Marriage(pat, tess)
		patUma := w.k.Parent(pat, uma)
		w.k.Parent(sam, uma)
		w.k.Parent(pat, wren)
		w.k.Parent(xan, wren)
		holdsIDs(t, "handles", read(t, w, pat), false, pat, sam, tess, uma, wren, xan, m1, patUma)
	})
	t.Run("a marriage with no spouse filed", func(t *testing.T) {
		w := newKinWorld(t)
		pat := w.person("Pat")
		m2, _ := w.k.Marriage(pat)
		holdsIDs(t, "handles", read(t, w, pat), false, pat, m2)
	})
	t.Run("a provisional child that is not shown", func(t *testing.T) {
		w := newKinWorld(t)
		pat, vic := w.person("Pat"), w.person("Vic")
		w.k.Parent(pat, vic)
		w.k.Provisional(vic)
		w.k.Commit(vic)
		w.expect(pat)
		holdsIDs(t, "handles", read(t, w, pat), false, pat, vic)
	})
	t.Run("a step person's marriage", func(t *testing.T) {
		w := newKinWorld(t)
		pat, quinn, rhea := w.person("Pat"), w.person("Quinn"), w.person("Rhea")
		w.k.Parent(quinn, pat)
		m3, _ := w.k.Marriage(quinn, rhea)
		holdsIDs(t, "handles", read(t, w, pat), false, pat, quinn, m3)
	})
}

// bornIn gives a person a birth event naming the parents (nil leaves one out)
// and, when year is not 0, a birth date.
func bornIn(w *kinWorld, p []byte, year int, father, mother []byte) {
	ev, _ := w.k.Birth(p, father, mother)
	if year != 0 {
		w.k.Date(ev, vocabkey.PropertyDate, *datevaluetest.YMD(year, 0, 0))
	}
}

// filedParents records each parent of child as a parent relationship, in order,
// and gives the child a birth dated year when year is not 0.
func filedParents(w *kinWorld, child []byte, year int, parents ...[]byte) {
	for _, p := range parents {
		w.k.Parent(p, child)
	}
	bornIn(w, child, year, nil, nil)
}

// groupsOf writes each sibling group as "Heinrich+Anna: Margarethe, Johann":
// its parents in order joined with "+", then its children in order.
func (w *kinWorld) groupsOf(f persondetail.Family) []string {
	names := func(rs []kinship.Relative, sep string) string {
		var out []string
		for _, r := range rs {
			out = append(out, w.name(r.ID))
		}
		return strings.Join(out, sep)
	}
	var out []string
	for _, g := range f.Groups {
		out = append(out, names(g.Parents, "+")+": "+names(g.Children, ", "))
	}
	return out
}

func TestPersonFamilyGroups(t *testing.T) {
	check := func(t *testing.T, w *kinWorld, id []byte, want ...string) persondetail.Family {
		t.Helper()
		f, err := w.family(id)
		if err != nil {
			t.Fatal(err)
		}
		if got := w.groupsOf(f); !reflect.DeepEqual(got, want) {
			t.Fatalf("groups:\n got %q\nwant %q", got, want)
		}
		return f
	}
	type cast struct {
		w                                 *kinWorld
		johann, heinrich, anna, kath      []byte
		marg, fried, wil, chris, georg, e []byte
	}
	newCast := func(t *testing.T) cast {
		w := newKinWorld(t)
		return cast{w: w,
			johann: w.person("Johann"), heinrich: w.person("Heinrich"), anna: w.person("Anna"), kath: w.person("Katharina"),
			marg: w.person("Margarethe"), fried: w.person("Friedrich"), wil: w.person("Wilhelm"), chris: w.person("Christian"),
			georg: w.person("Georg Becker"), e: w.person("Elisabeth")}
	}
	t.Run("AC-1.1", func(t *testing.T) {
		c := newCast(t)
		bornIn(c.w, c.johann, 1817, c.heinrich, c.anna)
		bornIn(c.w, c.fried, 1820, c.heinrich, c.anna)
		bornIn(c.w, c.marg, 1815, c.heinrich, c.anna)
		bornIn(c.w, c.wil, 0, c.heinrich, c.anna)
		bornIn(c.w, c.chris, 1823, nil, c.anna)
		c.w.k.Marriage(c.heinrich, c.anna)
		check(t, c.w, c.johann, "Heinrich+Anna: Margarethe, Johann, Friedrich, Wilhelm", "Anna: Christian")
	})
	t.Run("AC-1.2", func(t *testing.T) {
		c := newCast(t)
		filedParents(c.w, c.johann, 1817, c.heinrich, c.anna, c.kath)
		filedParents(c.w, c.fried, 1820, c.heinrich, c.anna, c.kath)
		filedParents(c.w, c.marg, 1815, c.heinrich, c.anna)
		filedParents(c.w, c.wil, 0, c.heinrich, c.anna)
		filedParents(c.w, c.chris, 1823, c.heinrich, c.kath)
		check(t, c.w, c.johann,
			"Heinrich+Anna+Katharina: Johann, Friedrich",
			"Heinrich+Anna: Margarethe, Wilhelm",
			"Heinrich+Katharina: Christian")
	})
	t.Run("AC-1.3", func(t *testing.T) {
		c := newCast(t)
		bornIn(c.w, c.johann, 1817, c.heinrich, c.anna)
		bornIn(c.w, c.wil, 1819, c.heinrich, nil)
		bornIn(c.w, c.chris, 1823, nil, c.anna)
		check(t, c.w, c.johann, "Heinrich+Anna: Johann", "Heinrich: Wilhelm", "Anna: Christian")
	})
	t.Run("AC-1.4", func(t *testing.T) {
		c := newCast(t)
		filedParents(c.w, c.johann, 1817, c.heinrich, c.anna, c.georg, c.kath)
		filedParents(c.w, c.marg, 1815, c.heinrich, c.anna)
		filedParents(c.w, c.fried, 1820, c.heinrich, c.anna)
		filedParents(c.w, c.chris, 1823, c.georg, c.kath)
		c.w.k.Relationship(c.johann, c.e, "sibling")
		c.w.k.Marriage(c.heinrich, c.anna)
		c.w.k.Marriage(c.georg, c.kath)
		check(t, c.w, c.johann,
			"Heinrich+Anna+Georg Becker+Katharina: Johann",
			"Heinrich+Anna: Margarethe, Friedrich",
			"Georg Becker+Katharina: Christian",
			": Elisabeth")
	})
	t.Run("AC-1.5", func(t *testing.T) {
		c := newCast(t)
		clara, karl := c.w.person("Clara"), c.w.person("Karl")
		bornIn(c.w, c.johann, 1817, nil, nil)
		bornIn(c.w, clara, 1815, nil, nil)
		bornIn(c.w, karl, 1820, nil, nil)
		c.w.k.Relationship(c.johann, clara, "sibling")
		c.w.k.Relationship(c.johann, karl, "sibling")
		check(t, c.w, c.johann, ": Clara, Johann, Karl")
	})
	t.Run("AC-1.6", func(t *testing.T) {
		c := newCast(t)
		check(t, c.w, c.johann, ": Johann")
	})
	t.Run("a merged sibling is dropped with a group it empties", func(t *testing.T) {
		c := newCast(t)
		bornIn(c.w, c.johann, 1817, c.heinrich, c.anna)
		bornIn(c.w, c.marg, 1815, c.heinrich, c.anna)
		bornIn(c.w, c.chris, 1823, nil, c.anna)
		stranger := c.w.person("Stranger")
		c.w.k.Merge(c.chris, stranger)
		c.w.k.Commit(c.chris, stranger)
		check(t, c.w, c.johann, "Heinrich+Anna: Margarethe, Johann")
	})
	t.Run("a merged parent leaves the group its children and its other parents", func(t *testing.T) {
		c := newCast(t)
		bornIn(c.w, c.johann, 1817, c.heinrich, c.anna)
		bornIn(c.w, c.marg, 1815, c.heinrich, c.anna)
		stranger := c.w.person("Stranger")
		c.w.k.Merge(c.heinrich, stranger)
		c.w.k.Commit(c.heinrich, stranger)
		f, err := c.w.family(c.johann)
		if err != nil {
			t.Fatal(err)
		}
		got := c.w.groupsOf(f)
		if len(got) == 0 || got[0] != "Anna: Margarethe, Johann" {
			t.Fatalf("groups %q", got)
		}
	})
}

func TestPersonFamilyCouples(t *testing.T) {
	// couples writes each couple as "A+B: marriage ids in order, as m1, m2".
	couples := func(w *kinWorld, f persondetail.Family, marriages map[string]string) []string {
		var out []string
		for _, c := range f.Couples {
			var ms []string
			for _, m := range c.Marriages {
				ms = append(ms, marriages[string(m)])
			}
			out = append(out, w.name(c.A)+"+"+w.name(c.B)+": "+strings.Join(ms, ", "))
		}
		return out
	}
	t.Run("a dated marriage first, an undated one second", func(t *testing.T) {
		w := newKinWorld(t)
		johann, maria := w.person("Johann"), w.person("Maria")
		undated, _ := w.k.Marriage(johann, maria)
		dated, _ := w.k.Marriage(johann, maria)
		w.k.Date(dated, vocabkey.PropertyDate, *datevaluetest.YMD(1841, 6, 12))
		w.k.Commit(dated, undated)
		f, err := w.family(johann)
		if err != nil {
			t.Fatal(err)
		}
		got := couples(w, f, map[string]string{string(dated): "1841", string(undated): "undated"})
		if want := []string{"Johann+Maria: 1841, undated"}; !reflect.DeepEqual(got, want) {
			t.Fatalf("couples %q, want %q", got, want)
		}
	})
	t.Run("parents, a partner through a child only, a spouse link with no marriage", func(t *testing.T) {
		w := newKinWorld(t)
		johann, heinrich, anna, sophie, ida := w.person("Johann"), w.person("Heinrich"), w.person("Anna"), w.person("Sophie"), w.person("Ida")
		bornIn(w, johann, 1817, heinrich, anna)
		m, _ := w.k.Marriage(heinrich, anna)
		bornIn(w, w.person("Kid"), 1845, johann, sophie)
		w.k.Relationship(johann, ida, "spouse")
		f, err := w.family(johann)
		if err != nil {
			t.Fatal(err)
		}
		got := couples(w, f, map[string]string{string(m): "m"})
		if want := []string{"Heinrich+Anna: m"}; !reflect.DeepEqual(got, want) {
			t.Fatalf("couples %q, want %q", got, want)
		}
	})
	t.Run("a marriage merged away is not sent", func(t *testing.T) {
		w := newKinWorld(t)
		johann, maria, stranger := w.person("Johann"), w.person("Maria"), w.person("Stranger")
		keep, _ := w.k.Marriage(johann, maria)
		gone, _ := w.k.Marriage(johann, maria)
		other := w.k.Event(vocabkey.EventMarriage)
		w.k.Merge(gone, other)
		w.k.Commit(gone, other, stranger)
		f, err := w.family(johann)
		if err != nil {
			t.Fatal(err)
		}
		if got, want := couples(w, f, map[string]string{string(keep): "keep", string(gone): "gone"}), []string{"Johann+Maria: keep"}; !reflect.DeepEqual(got, want) {
			t.Fatalf("couples %q, want %q", got, want)
		}
		w.k.Merge(keep, other)
		w.k.Commit(keep, other)
		f, err = w.family(johann)
		if err != nil {
			t.Fatal(err)
		}
		if len(f.Couples) != 0 {
			t.Fatalf("a couple with no marriage left was sent: %+v", f.Couples)
		}
	})
	t.Run("AC-2.8 the couples a group and a partner unit name", func(t *testing.T) {
		w := newKinWorld(t)
		johann, heinrich, anna, kath := w.person("Johann"), w.person("Heinrich"), w.person("Anna"), w.person("Katharina")
		maria, sophie, kid := w.person("Maria"), w.person("Sophie"), w.person("Kid")
		filedParents(w, johann, 1817, heinrich, anna, kath)
		filedParents(w, w.person("Friedrich"), 1820, heinrich, anna)
		filedParents(w, w.person("Christian"), 1823, heinrich, kath)
		w.k.Marriage(heinrich, anna)
		w.k.Marriage(heinrich, kath)
		w.k.Marriage(johann, maria)
		bornIn(w, kid, 1845, johann, sophie)
		f, err := w.family(johann)
		if err != nil {
			t.Fatal(err)
		}
		pair := func(i int) string { return w.name(f.Couples[i].A) + "+" + w.name(f.Couples[i].B) }
		names := func(ix []int) []string {
			var out []string
			for _, i := range ix {
				out = append(out, pair(i))
			}
			return out
		}
		var haveGroups []string
		for _, g := range f.Groups {
			haveGroups = append(haveGroups, strings.Join(names(g.Couples), ";"))
		}
		if want := []string{"Heinrich+Anna;Heinrich+Katharina", "Heinrich+Anna", "Heinrich+Katharina"}; !reflect.DeepEqual(haveGroups, want) {
			t.Fatalf("group couples %q, want %q", haveGroups, want)
		}
		if len(f.UnitCouples) != len(f.Units) {
			t.Fatalf("%d unit couple lists for %d units", len(f.UnitCouples), len(f.Units))
		}
		partner := map[string][]string{}
		for k, u := range f.Units {
			if u.Kind == kinship.UnitPartner {
				partner[w.name(u.Partners[0].ID)] = names(f.UnitCouples[k])
			}
		}
		if want := map[string][]string{"Maria": {"Johann+Maria"}, "Sophie": nil}; !reflect.DeepEqual(partner, want) {
			t.Fatalf("partner unit couples %v, want %v", partner, want)
		}
	})
	t.Run("AC-2.7 a date edit reaches the read", func(t *testing.T) {
		w := newKinWorld(t)
		johann, maria := w.person("Johann"), w.person("Maria")
		m, _ := w.k.Marriage(johann, maria)
		w.k.Commit(m)
		read := func() (conclusionsummaries.EventSummary, [][]byte) {
			in := w.c.Graph().PageInputs()
			f, _, summaries, err := persondetail.PersonFamily(w.c, johann, in)
			if err != nil {
				t.Fatal(err)
			}
			if len(f.Couples) != 1 || len(f.Couples[0].Marriages) != 1 {
				t.Fatalf("couples %+v", f.Couples)
			}
			h, ok := summaries.Event(f.Couples[0].Marriages[0])
			if !ok {
				t.Fatal("no summary for the marriage")
			}
			handles, _, _ := in.Lists()
			return h, handles
		}
		before, handles := read()
		holdsIDs(t, "handles", handles, false, m)
		w.k.Date(m, vocabkey.PropertyDate, *datevaluetest.YMD(1850, 1, 2))
		w.k.Commit(m)
		after, handles := read()
		holdsIDs(t, "handles", handles, false, m)
		if reflect.DeepEqual(before.Dating, after.Dating) {
			t.Fatalf("the marriage kept its old date: %+v", after.Dating)
		}
	})
}
