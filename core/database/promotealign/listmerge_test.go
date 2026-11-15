package promotealign_test

import (
	"fmt"
	"reflect"
	"sort"
	"testing"
	"time"

	"github.com/mendahu/provenencia/core/database"
	"github.com/mendahu/provenencia/core/database/citations"
	"github.com/mendahu/provenencia/core/database/conclusionsummaries"
	"github.com/mendahu/provenencia/core/database/databasetest"
	"github.com/mendahu/provenencia/core/database/effects"
	"github.com/mendahu/provenencia/core/database/observations"
	"github.com/mendahu/provenencia/core/database/promote"
	"github.com/mendahu/provenencia/core/database/rowchange"
	"github.com/mendahu/provenencia/core/database/subjects"
	"github.com/mendahu/provenencia/core/namevalue/namevaluetest"
	"github.com/mendahu/provenencia/core/propertymeta"
	"github.com/mendahu/provenencia/core/writes"
)

// decided: S16-26 D-13. The three filtered list reads of one write take about
// 1.3 ms at most at 4,000 persons; the ceiling catches a slip to a whole
// compose (28-73 ms).
const ceilingListRowsOfWrite = 20 * time.Millisecond

// lists is the three Conclusion lists read whole.
type lists struct {
	persons []conclusionsummaries.PersonSummary
	events  []conclusionsummaries.EventSummary
	places  []conclusionsummaries.PlaceSummary
}

func readLists(t testing.TB, c *database.Catalog) lists {
	t.Helper()
	var l lists
	var err error
	l.persons, err = conclusionsummaries.ListPersons(c)
	must(t, err)
	l.events, err = conclusionsummaries.ListEvents(c)
	must(t, err)
	l.places, err = conclusionsummaries.ListPlaces(c)
	must(t, err)
	return l
}

// readListsOf is the filtered reads of ids and how long the three took.
func readListsOf(t testing.TB, c *database.Catalog, ids [][]byte) (lists, time.Duration) {
	t.Helper()
	var l lists
	d := databasetest.Since(func() {
		var err error
		l.persons, err = conclusionsummaries.ListPersonsOf(c, ids)
		must(t, err)
		l.events, err = conclusionsummaries.ListEventsOf(c, ids)
		must(t, err)
		l.places, err = conclusionsummaries.ListPlacesOf(c, ids)
		must(t, err)
	})
	return l, d
}

// mergeRows is what the app does with a re-read: drop the touched ids and the
// returned ones, then put each returned row where its key falls.
func mergeRows[T any](rows []T, ids [][]byte, fresh []T, idOf func(T) []byte, keyOf func(T) conclusionsummaries.ListKey) []T {
	drop := map[string]bool{}
	for _, id := range ids {
		drop[string(id)] = true
	}
	for _, r := range fresh {
		drop[string(idOf(r))] = true
	}
	var out []T
	for _, r := range rows {
		if !drop[string(idOf(r))] {
			out = append(out, r)
		}
	}
	for _, r := range fresh {
		i := sort.Search(len(out), func(i int) bool { return keyOf(r).Less(keyOf(out[i])) })
		out = append(out, r)
		copy(out[i+1:], out[i:])
		out[i] = r
	}
	return out
}

func (l lists) merged(ids [][]byte, fresh lists) lists {
	return lists{
		persons: mergeRows(l.persons, ids, fresh.persons, func(h conclusionsummaries.PersonSummary) []byte { return h.Entity.ID }, func(h conclusionsummaries.PersonSummary) conclusionsummaries.ListKey { return h.ListKey }),
		events:  mergeRows(l.events, ids, fresh.events, func(h conclusionsummaries.EventSummary) []byte { return h.Entity.ID }, func(h conclusionsummaries.EventSummary) conclusionsummaries.ListKey { return h.ListKey }),
		places:  mergeRows(l.places, ids, fresh.places, func(h conclusionsummaries.PlaceSummary) []byte { return h.Entity.ID }, func(h conclusionsummaries.PlaceSummary) conclusionsummaries.ListKey { return h.ListKey }),
	}
}

// runWrite runs one write as the app does and returns what it reported.
func runWrite[T any](t testing.TB, c *database.Catalog, action string, fn func(tx *database.Tx) (T, []rowchange.Change, error)) effects.Set {
	t.Helper()
	_, res, err := writes.Run(c, writes.Op{Action: action, UserID: userID}, fn)
	must(t, err)
	return res.Effects
}

// listWrite is one of D-13's writes: setup commits, which are not measured,
// then the one commit whose effects name the rows to re-read.
type listWrite struct {
	name  string
	setup func()
	write func() effects.Set
}

// listWrites are the five writes of S16-26 D-13. They run in order on one
// fixture: W3 cites on the Person W1 promoted.
func listWrites(t testing.TB, lf *largeFixture) []listWrite {
	nameProp := lf.Prop("name").ID
	topProp := lf.Prop("toponym").ID
	promoteOf := func(s subjects.Subject) func() effects.Set {
		return func() effects.Set {
			return runWrite(t, lf.c, "promote_subject", func(tx *database.Tx) (promote.Result, []rowchange.Change, error) {
				return promote.Save(tx, userID, promote.Input{SubjectID: s.ID})
			})
		}
	}
	var person, birth, capital subjects.Subject
	return []listWrite{
		{"W1 promote a person",
			func() { person = lf.Person(lf.other, lf.otherA, "Zed Newperson") },
			func() effects.Set { return promoteOf(person)() }},
		{"W2 promote a located birth",
			func() {
				birth = lf.Birth(lf.onePlace, lf.pageArt)
				q := lf.Person(lf.onePlace, lf.pageArt, "Yan Born")
				lf.Participation(lf.onePlace, lf.pageArt, q, birth, "subject")
				lf.Locate(lf.onePlace, lf.pageArt, birth, lf.citySubject)
			},
			func() effects.Set { return promoteOf(birth)() }},
		{"W3 cite a name on a person",
			func() {},
			func() effects.Set {
				return runWrite(t, lf.c, "create_citation_with_observations", func(tx *database.Tx) (citations.CreateResult, []rowchange.Change, error) {
					return citations.CreateWithObservations(tx, userID,
						citations.CreateInput{ArtifactID: lf.otherA.ID, GraphID: person.GraphID, LocatorJSON: locator},
						[]observations.Input{{SubjectID: person.ID, PropertyID: nameProp, Name: namevaluetest.Western("Aaron Newperson")}})
				})
			}},
		{"W4 promote a place under the city",
			func() {
				capital = lf.Place(lf.onePlace, lf.pageArt, "Capital")
				lf.PlaceRel(lf.onePlace, lf.pageArt, lf.citySubject, capital, "part_of")
			},
			func() effects.Set { return promoteOf(capital)() }},
		{"W5 cite a toponym on the city",
			func() {},
			func() effects.Set {
				return runWrite(t, lf.c, "create_citation_with_observations", func(tx *database.Tx) (citations.CreateResult, []rowchange.Change, error) {
					return citations.CreateWithObservations(tx, userID,
						citations.CreateInput{ArtifactID: lf.pageArt.ID, GraphID: lf.citySubject.GraphID, LocatorJSON: locator},
						[]observations.Input{{SubjectID: lf.citySubject.ID, PropertyID: topProp, Scalar: propertymeta.TextScalar("Aardvark City")}})
				})
			}},
	}
}

// touchedIDs is the rows a write names: Handles and SummaryDeps (the app's
// touchedHandles).
func touchedIDs(set effects.Set) [][]byte {
	var ids [][]byte
	seen := map[string]bool{}
	for _, id := range append(append([][]byte(nil), set.Handles...), set.SummaryDeps...) {
		if len(id) != 0 && !seen[string(id)] {
			seen[string(id)] = true
			ids = append(ids, id)
		}
	}
	return ids
}

// TestListMergeMatchesReload holds S16-26 AC-2.1: after each of five real
// writes on the large fixture, the lists read before it with the touched rows
// merged in equal the lists read after it, row for row and in order.
func TestListMergeMatchesReload(t *testing.T) {
	lf := newLargeFixture(t, 4000)
	for _, w := range listWrites(t, lf) {
		w.setup()
		before := readLists(t, lf.c)
		set := w.write()
		ids := touchedIDs(set)
		if len(ids) == 0 {
			t.Fatalf("%s reported no handles", w.name)
		}
		fresh, took := readListsOf(t, lf.c, ids)
		if len(fresh.persons)+len(fresh.events)+len(fresh.places) == 0 {
			t.Errorf("%s: the filtered reads returned no row", w.name)
		}
		got := before.merged(ids, fresh)
		after := readLists(t, lf.c)
		t.Logf("%s: %d ids, filtered reads %v", w.name, len(ids), took)
		if !reflect.DeepEqual(got.persons, after.persons) {
			t.Errorf("%s: merged Persons list differs from a reload (%d rows, want %d)", w.name, len(got.persons), len(after.persons))
		}
		if !reflect.DeepEqual(got.events, after.events) {
			t.Errorf("%s: merged Events list differs from a reload (%d rows, want %d)", w.name, len(got.events), len(after.events))
		}
		if !reflect.DeepEqual(got.places, after.places) {
			t.Errorf("%s: merged Places list differs from a reload (%d rows, want %d)", w.name, len(got.places), len(after.places))
		}
		databasetest.WithinBudget(t, w.name+": filtered list reads", took, ceilingListRowsOfWrite)
	}
}

// BenchmarkListRowsOfWrite reports, at 4,000 and 16,000 persons, how long each
// whole list takes to read and how long the filtered reads of each of D-13's
// writes take (rows-us), so a merge can be set beside a reload. It runs its
// writes once whatever b.N.
func BenchmarkListRowsOfWrite(b *testing.B) {
	for _, persons := range []int{4000, 16000} {
		b.Run(fmt.Sprintf("persons=%d", persons), func(b *testing.B) {
			lf := newLargeFixture(b, persons)
			ms := func(f func()) float64 {
				return float64(databasetest.Fastest(3, func() time.Duration { return databasetest.Since(f) }).Microseconds()) / 1000
			}
			whole := lists{}
			b.ReportMetric(ms(func() { whole = readLists(b, lf.c) }), "all-ms")
			var pm, em, plm float64
			pm = ms(func() { _, err := conclusionsummaries.ListPersons(lf.c); must(b, err) })
			em = ms(func() { _, err := conclusionsummaries.ListEvents(lf.c); must(b, err) })
			plm = ms(func() { _, err := conclusionsummaries.ListPlaces(lf.c); must(b, err) })
			b.ReportMetric(pm, "persons-ms")
			b.ReportMetric(em, "events-ms")
			b.ReportMetric(plm, "places-ms")
			b.Logf("%d persons, %d events, %d places; whole lists: persons %.1f ms, events %.1f ms, places %.1f ms", len(whole.persons), len(whole.events), len(whole.places), pm, em, plm)
			for i, w := range listWrites(b, lf) {
				w.setup()
				ids := touchedIDs(w.write())
				// The first read after the write, which composes the dropped rows.
				fresh, d := readListsOf(b, lf.c, ids)
				us := float64(d.Nanoseconds()) / 1000
				b.ReportMetric(us, fmt.Sprintf("w%d-rows-us", i+1))
				b.Logf("%s: %d ids, %d+%d+%d rows, filtered reads %.0f us (%.1f%% of the Persons list)", w.name, len(ids), len(fresh.persons), len(fresh.events), len(fresh.places), us, us/10/pm)
			}
		})
	}
}
