package conclusionsummaries_test

import (
	"bytes"
	"slices"
	"testing"
	"time"

	"github.com/Jake-Robins-Studios/provenencia/core/autoreconcile"
	"github.com/Jake-Robins-Studios/provenencia/core/catalogsession/catalogsessiontest"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/conclusionsummaries"
	"github.com/Jake-Robins-Studios/provenencia/core/database/databasetest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/graphcache/graphcachetest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/nameformats"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue/datevaluetest"
	"github.com/Jake-Robins-Studios/provenencia/core/hops"
)

// voteWorld is a Person Pat born at one event, whose places are filed by
// Locations from Sources of their own. A place's ref is its name unless the
// test names another, so a parent chain reads as names.
type voteWorld struct {
	t     *testing.T
	c     *database.Catalog
	k     *graphcachetest.Canon
	pat   []byte
	birth []byte
	names map[string]string // place id -> name
	ids   [][]byte          // everything to commit
}

func newVoteWorld(t *testing.T) *voteWorld {
	t.Helper()
	c := graphcachetest.OpenCatalog(t)
	if err := nameformats.Warm(c); err != nil {
		t.Fatal(err)
	}
	w := &voteWorld{t: t, c: c, k: graphcachetest.NewCanon(t, c), names: map[string]string{}}
	w.pat = w.k.Person()
	var joins [][]byte
	w.birth, joins = w.k.Birth(w.pat, nil, nil)
	w.ids = append(w.ids, w.pat, w.birth)
	w.ids = append(w.ids, joins...)
	return w
}

// place files a Place named name, with ref ref (name when empty).
func (w *voteWorld) place(name, ref string) []byte {
	w.t.Helper()
	if ref == "" {
		ref = name
	}
	id := w.k.Entity("place")
	w.k.SetRef(id, ref)
	w.names[string(id)] = name
	w.ids = append(w.ids, id)
	return id
}

// within files part as part_of whole.
func (w *voteWorld) within(part, whole []byte) []byte {
	rel := w.k.PartOf(part, whole)
	w.ids = append(w.ids, rel)
	return rel
}

// record files the birth at place from a Source of its own; grade and
// uncertain are that Source's. It returns the Location's id.
func (w *voteWorld) record(place []byte, grade string, uncertain bool) []byte {
	w.t.Helper()
	w.k.NewSource(grade, uncertain)
	return w.at(place)
}

// at files the birth at place from the current Source.
func (w *voteWorld) at(place []byte) []byte {
	loc := w.k.Location(w.birth, place)
	w.ids = append(w.ids, loc)
	return loc
}

func (w *voteWorld) commit() {
	w.t.Helper()
	w.k.Commit(w.ids...)
	w.ids = nil
}

func (w *voteWorld) name(id []byte) string { return w.names[string(id)] }

func (w *voteWorld) event() conclusionsummaries.EventSummary {
	w.t.Helper()
	got, err := conclusionsummaries.EventsByIDs(w.c, [][]byte{w.birth})
	if err != nil || len(got) != 1 {
		w.t.Fatalf("EventsByIDs: %d rows, err %v", len(got), err)
	}
	return got[0]
}

func (w *voteWorld) person() conclusionsummaries.PersonSummary {
	w.t.Helper()
	got, err := conclusionsummaries.PersonsByIDs(w.c, [][]byte{w.pat})
	if err != nil || len(got) != 1 {
		w.t.Fatalf("PersonsByIDs: %d rows, err %v", len(got), err)
	}
	return got[0]
}

func (w *voteWorld) placeNames(ps []conclusionsummaries.ChainedPlace) []string {
	var out []string
	for _, p := range ps {
		out = append(out, w.name(p.Entity.ID))
	}
	return out
}

// verdict is what a vote did to the link to the named place.
type verdict struct {
	place  string
	reason autoreconcile.Reason
	vote   autoreconcile.Vote
}

func (w *voteWorld) verdicts(owners []conclusionsummaries.FieldOwner) []verdict {
	var out []verdict
	for _, o := range owners {
		out = append(out, verdict{w.name(o.Place.Entity.ID), o.Reason, o.Vote})
	}
	return out
}

func TestEventPlaceVote(t *testing.T) {
	const (
		kept     = autoreconcile.ReasonKept
		folded   = autoreconcile.ReasonFolded
		outvoted = autoreconcile.ReasonOutvoted
		weak     = autoreconcile.ReasonWeak
	)
	// chain is Swift Current within Saskatchewan within Canada.
	type chain struct{ swift, sask, canada []byte }
	build := func(w *voteWorld) chain {
		c := chain{swift: w.place("Swift Current", ""), sask: w.place("Saskatchewan", ""), canada: w.place("Canada", "")}
		w.within(c.swift, c.sask)
		w.within(c.sask, c.canada)
		return c
	}
	tests := []struct {
		name    string
		world   func(w *voteWorld)
		places  []string
		parents []string // of the first place
		owners  []verdict
	}{
		{"AC-1.1 three Sources outvote the fourth, whatever the refs", func(w *voteWorld) {
			swift, england := w.place("Swift Current", "PLC-B"), w.place("England", "PLC-A")
			for range 3 {
				w.record(swift, "", false)
			}
			w.record(england, "", false)
		}, []string{"Swift Current"}, nil, []verdict{
			{"Swift Current", kept, autoreconcile.Vote{}}, {"Swift Current", kept, autoreconcile.Vote{}}, {"Swift Current", kept, autoreconcile.Vote{}},
			{"England", outvoted, autoreconcile.Vote{Support: 3, Of: 4}}}},
		{"AC-1.2 one Source each: the earlier record leads", func(w *voteWorld) {
			swift, england := w.place("Swift Current", "PLC-B"), w.place("England", "PLC-A")
			w.record(swift, "", false)
			w.record(england, "", false)
		}, []string{"Swift Current", "England"}, nil, []verdict{{"Swift Current", kept, autoreconcile.Vote{}}, {"England", kept, autoreconcile.Vote{}}}},
		{"AC-1.2 the other way round", func(w *voteWorld) {
			swift, england := w.place("Swift Current", "PLC-B"), w.place("England", "PLC-A")
			w.record(england, "", false)
			w.record(swift, "", false)
		}, []string{"England", "Swift Current"}, nil, []verdict{{"England", kept, autoreconcile.Vote{}}, {"Swift Current", kept, autoreconcile.Vote{}}}},
		{"AC-1.3 a low-trust record drops", func(w *voteWorld) {
			swift, england := w.place("Swift Current", ""), w.place("England", "")
			w.record(swift, "low_trust", false)
			w.record(england, "", false)
		}, []string{"England"}, nil, []verdict{{"England", kept, autoreconcile.Vote{}}, {"Swift Current", weak, autoreconcile.Vote{}}}},
		{"AC-1.4 one Source is no majority", func(w *voteWorld) {
			swift, england := w.place("Swift Current", ""), w.place("England", "")
			w.k.NewSource("", false)
			w.at(swift)
			w.at(england)
		}, []string{"Swift Current", "England"}, nil, []verdict{{"Swift Current", kept, autoreconcile.Vote{}}, {"England", kept, autoreconcile.Vote{}}}},
		{"AC-2.1 a container folds into the place it contains", func(w *voteWorld) {
			c := build(w)
			for range 3 {
				w.record(c.swift, "", false)
			}
			w.record(c.canada, "", false)
		}, []string{"Swift Current"}, []string{"Saskatchewan", "Canada"}, []verdict{
			{"Swift Current", kept, autoreconcile.Vote{}}, {"Swift Current", kept, autoreconcile.Vote{}}, {"Swift Current", kept, autoreconcile.Vote{}},
			{"Canada", folded, autoreconcile.Vote{}}}},
		{"AC-2.2 a shared parent tips the tie", func(w *voteWorld) {
			c := build(w)
			toronto, ontario := w.place("Toronto", ""), w.place("Ontario", "")
			w.within(toronto, ontario)
			w.within(ontario, c.canada)
			w.record(c.swift, "", false)
			w.record(c.canada, "", false)
			w.record(toronto, "", false)
		}, []string{"Swift Current"}, nil, []verdict{
			{"Swift Current", kept, autoreconcile.Vote{}}, {"Canada", folded, autoreconcile.Vote{}}, {"Toronto", outvoted, autoreconcile.Vote{Support: 2, Of: 3}}}},
		{"AC-2.3 a membership that ended does not fold", func(w *voteWorld) {
			dublin, uk := w.place("Dublin", ""), w.place("United Kingdom", "")
			rel := w.within(dublin, uk)
			w.k.Date(rel, "end_date", *datevaluetest.YMD(1922, 0, 0))
			w.k.Date(w.birth, "date", *datevaluetest.YMD(1950, 0, 0))
			w.record(dublin, "", false)
			w.record(dublin, "", false)
			w.record(uk, "", false)
		}, []string{"Dublin"}, nil, []verdict{
			{"Dublin", kept, autoreconcile.Vote{}}, {"Dublin", kept, autoreconcile.Vote{}}, {"United Kingdom", outvoted, autoreconcile.Vote{Support: 2, Of: 3}}}},
		{"AC-2.4 a membership that held folds", func(w *voteWorld) {
			dublin, uk := w.place("Dublin", ""), w.place("United Kingdom", "")
			rel := w.within(dublin, uk)
			w.k.Date(rel, "end_date", *datevaluetest.YMD(1922, 0, 0))
			w.k.Date(w.birth, "date", *datevaluetest.YMD(1900, 0, 0))
			w.record(dublin, "", false)
			w.record(dublin, "", false)
			w.record(uk, "", false)
		}, []string{"Dublin"}, nil, []verdict{
			{"Dublin", kept, autoreconcile.Vote{}}, {"Dublin", kept, autoreconcile.Vote{}}, {"United Kingdom", folded, autoreconcile.Vote{}}}},
		{"two places within each other are a cycle: both stay", func(w *voteWorld) {
			a, b := w.place("A", ""), w.place("B", "")
			w.within(a, b)
			w.within(b, a)
			w.record(a, "", false)
			w.record(b, "", false)
		}, []string{"A", "B"}, nil, []verdict{{"A", kept, autoreconcile.Vote{}}, {"B", kept, autoreconcile.Vote{}}}},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			w := newVoteWorld(t)
			tc.world(w)
			w.commit()
			ev, row := w.event(), w.person()
			for what, got := range map[string][]conclusionsummaries.ChainedPlace{"event": ev.Places, "birth": row.Birth.Places} {
				if names := w.placeNames(got); !slices.Equal(names, tc.places) {
					t.Fatalf("%s places %v, want %v", what, names, tc.places)
				}
			}
			if tc.parents != nil && !slices.Equal(row.Birth.Places[0].Parents, tc.parents) {
				t.Fatalf("parents %v, want %v", row.Birth.Places[0].Parents, tc.parents)
			}
			if got := w.verdicts(row.Birth.Owners.Places); !slices.Equal(got, tc.owners) {
				t.Fatalf("owners %+v, want %+v", got, tc.owners)
			}
		})
	}
}

// TestEventPlaceVoteCap: 71 links keep the first 64, and the vote counts only those.
func TestEventPlaceVoteCap(t *testing.T) {
	w := newVoteWorld(t)
	swift, england := w.place("Swift Current", ""), w.place("England", "")
	w.k.Bulk(func() {
		for range 66 {
			w.record(swift, "", false)
		}
		for range 5 {
			w.record(england, "", false)
		}
	})
	w.commit()
	links, err := w.c.Graph().Follow(w.birth, hops.PlacesOfEvent)
	if err != nil {
		t.Fatal(err)
	}
	first := links[:64]
	var places [][]byte
	for _, l := range first {
		if !contains(places, l.Neighbor) {
			places = append(places, l.Neighbor)
		}
	}
	var row conclusionsummaries.PersonSummary
	d := catalogsessiontest.Cold(t, w.c, 2, func() { row = w.person() })
	databasetest.WithinBudget(t, "PersonsByIDs with 71 location links", d, time.Second)
	own := row.Birth.Owners
	if len(own.Dates) != 1 || len(own.Places) != 63 {
		t.Fatalf("%d date owners and %d place owners, want 1 and 63", len(own.Dates), len(own.Places))
	}
	for _, o := range own.Places {
		listed := false
		for _, l := range first {
			listed = listed || bytes.Equal(l.Association, o.ID)
		}
		if !listed {
			t.Fatalf("owner %x is not among the first 64 links", o.ID)
		}
	}
	for _, p := range row.Birth.Places {
		if !contains(places, p.Entity.ID) {
			t.Fatalf("place %x is not among the first 64 links' places", p.Entity.ID)
		}
	}
	if len(row.Birth.Places) == 0 {
		t.Fatal("the birth shows no place")
	}
}

// TestEventPlaceVoteFollowsEvidence: regrading a Source changes the event's
// place the next time it is read.
func TestEventPlaceVoteFollowsEvidence(t *testing.T) {
	w := newVoteWorld(t)
	swift, england := w.place("Swift Current", ""), w.place("England", "")
	englandSource := w.k.NewSource("", false)
	englandLoc := w.at(england)
	w.record(swift, "", false)
	w.commit()
	if got := w.placeNames(w.event().Places); !slices.Equal(got, []string{"England", "Swift Current"}) {
		t.Fatalf("before: %v", got)
	}
	db, err := w.c.DB()
	if err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec(`INSERT INTO source_credibility_assessments (id, source_id, credibility_grade_id)
		SELECT ?, ?, id FROM source_credibility_grades WHERE key = 'low_trust' AND origin = 'provenencia'`, bytes16(0x55), englandSource); err != nil {
		t.Fatal(err)
	}
	w.k.Commit(englandLoc)
	if got := w.placeNames(w.event().Places); !slices.Equal(got, []string{"Swift Current"}) {
		t.Fatalf("after: %v", got)
	}
}
