package conclusiondetails_test

import (
	"fmt"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/conclusiondetails"
	"github.com/Jake-Robins-Studios/provenencia/core/database/databasetest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencegraphs/evidencegraphstest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/observations"
	"github.com/Jake-Robins-Studios/provenencia/core/database/properties"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sources"
	"github.com/Jake-Robins-Studios/provenencia/core/database/subjectpositions"
	"github.com/Jake-Robins-Studios/provenencia/core/database/subjects"
	"github.com/Jake-Robins-Studios/provenencia/core/database/subjectvocab"
	"github.com/Jake-Robins-Studios/provenencia/core/hops"
	"github.com/Jake-Robins-Studios/provenencia/core/propertymeta"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
)

func (f *fixture) at(s subjects.Subject, x, y int64) {
	f.T.Helper()
	_, err := writes.Call(f.C, writes.Op{}, func(tx *database.Tx) (subjectpositions.Position, []rowchange.Change, error) {
		return subjectpositions.Set(tx, s.ID, x, y)
	})
	must(f.T, err)
}

// birthAt files a Person born at a Place whose toponym records are given,
// promotes all three, and returns the Person's handle.
func (f *fixture) birthAt(src sources.Source, toponyms ...observations.Input) ([]byte, subjects.Subject) {
	f.T.Helper()
	person, birth, place := f.personOn(src), f.subjectOn(src, "event"), f.subjectOn(src, "place")
	f.at(person, 0, 0)
	f.at(birth, 4, 0)
	f.at(place, 8, 0)
	f.cite(person, f.nameIn(person, "form:Ann Lee"))
	eventType := f.Prop("event_type")
	term := f.Term("event_type", "birth")
	f.cite(birth, observations.Input{SubjectID: birth.ID, PropertyID: eventType.ID, ValueTermID: term.ID})
	for _, in := range toponyms {
		in.SubjectID, in.PropertyID = place.ID, f.Prop("toponym").ID
		f.cite(place, in)
	}
	// A blank toponym can't be filed through the write path; blank the marker.
	db, err := f.C.DB()
	must(f.T, err)
	_, err = db.Exec(`UPDATE observations SET value_text = '  ' || char(9) || ' ' WHERE value_text = ?`, blankMarker)
	must(f.T, err)
	f.Participation(src, f.arts[string(src.ID)], person, birth, "subject")
	f.Locate(src, f.arts[string(src.ID)], birth, place)
	h := f.promote(person, nil)
	f.promote(birth, nil)
	f.promote(place, nil)
	return h, place
}

// datedBirth dates the birth event of the Person born through birthAt and
// returns the event's handle.
func (f *fixture) datedBirth(person []byte, src sources.Source, year int) []byte {
	f.T.Helper()
	links, err := f.C.Graph().Follow(person, hops.EventsOfParticipant)
	must(f.T, err)
	if len(links) != 1 {
		f.T.Fatalf("links %+v, want the one birth", links)
	}
	event := links[0].Neighbor
	n, err := f.C.Graph().Node(event)
	must(f.T, err)
	m := n.Members[0]
	f.cite(subjects.Subject{ID: m.SubjectID, GraphID: m.GraphID, SourceID: src.ID}, f.dateIn(subjects.Subject{ID: m.SubjectID}, year))
	return event
}

const blankMarker = "BLANK"

func text(s string) observations.Input { return observations.Input{Scalar: propertymeta.TextScalar(s)} }

func (f *fixture) placeRows(person []byte) []conclusiondetails.OwnerField {
	f.T.Helper()
	rows, err := conclusiondetails.PersonDerivedRows(f.C, person, f.C.Graph().NoPageInputs())
	must(f.T, err)
	for _, r := range rows {
		if r.Kind == conclusiondetails.DerivedRowBirthPlace {
			return r.Owners
		}
	}
	return nil
}

func TestLinkRecordReadsAsItsPlacesToponym(t *testing.T) {
	neg := func(s string) observations.Input {
		in := text(s)
		in.Polarity = observations.PolarityNegative
		return in
	}
	tests := []struct {
		name     string
		toponyms []observations.Input
		want     string // "" = the lowest-ref positive, non-blank toponym is read off the catalog
		empty    bool
	}{
		{name: "one toponym", toponyms: []observations.Input{text("York")}, want: "York"},
		{name: "none reads empty", empty: true},
		{name: "a negative and a blank one are skipped", toponyms: []observations.Input{neg("Leeds"), text(blankMarker), text("York")}, want: "York"},
		{name: "several: the lowest ref", toponyms: []observations.Input{text("York"), text("Eboracum"), text("Jorvik")}},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			f := newFixture(t)
			h, place := f.birthAt(f.source("Register"), tc.toponyms...)
			owners := f.placeRows(h)
			if len(owners) != 1 || len(owners[0].Field.Outcomes) != 1 {
				t.Fatalf("owners %+v, want one link with one record", owners)
			}
			got := owners[0].Field.Outcomes[0].Recorded
			want := tc.want
			if want == "" && !tc.empty {
				db, err := f.C.DB()
				must(t, err)
				must(t, db.QueryRow(`SELECT value_text FROM observations WHERE subject_id = ? AND polarity = 'positive' AND property_id = ?
					ORDER BY ref COLLATE NOCASE LIMIT 1`, place.ID, f.Prop("toponym").ID).Scan(&want))
			}
			if tc.empty {
				if got.HasText || got.Text != "" {
					t.Fatalf("recorded %+v, want empty", got)
				}
				return
			}
			if !got.HasText || got.Text != want {
				t.Fatalf("recorded %+v, want %q", got, want)
			}
		})
	}
}

// TestLinkRecordReadsKeepQueriesConstant: the life rows' graph queries do not
// grow with unrelated toponyms, and a second read issues none and selects
// nothing.
func TestLinkRecordReadsKeepQueriesConstant(t *testing.T) {
	count := func(unrelated int) int {
		f := newFixture(t)
		src := f.source("Register")
		h, _ := f.birthAt(src, text("York"))
		for i := range unrelated {
			other := f.subjectOn(src, "place")
			f.cite(other, observations.Input{SubjectID: other.ID, PropertyID: f.Prop("toponym").ID, Scalar: propertymeta.TextScalar(fmt.Sprintf("Town %d", i))})
		}
		g := f.C.Graph()
		g.Drop()
		_, err := g.Vocabulary()
		must(t, err)
		n := 0
		g.SetQueryCounterForTest(func() { n++ })
		defer g.SetQueryCounterForTest(nil)
		_, err = conclusiondetails.PersonDerivedRows(f.C, h, f.C.Graph().NoPageInputs())
		must(t, err)
		first := n
		n = 0
		selects := databasetest.CountSelects(t, f.C)
		_, err = conclusiondetails.PersonDerivedRows(f.C, h, f.C.Graph().NoPageInputs())
		must(t, err)
		if n != 0 || selects.N() != 0 {
			t.Fatalf("a second read issued %d graph queries and %d SELECTs", n, selects.N())
		}
		return first
	}
	if small, big := count(2), count(8); small == 0 || small != big {
		t.Fatalf("queries: %d with 2 unrelated toponyms, %d with 8", small, big)
	}
}

func TestForEntityDropsSubjectValuedFields(t *testing.T) {
	f := newFixture(t)
	src := f.source("Register")
	ann, bob := f.personOn(src), f.personOn(src)
	f.cite(ann, f.nameIn(ann, "form:Ann Lee"))
	godparent, _, err := writes.Run(f.C, writes.Op{Action: "create_property", UserID: userID}, func(tx *database.Tx) (properties.Property, []rowchange.Change, error) {
		return properties.Create(tx, userID, "Godparent", propertymeta.ValueTypeSubject, "", propertymeta.CardinalitySingle)
	})
	must(t, err)
	must(t, subjectvocab.EnsureBinding(f.C, f.person.ID, godparent.ID, 9))
	f.C.Graph().Drop()
	f.cite(ann, observations.Input{SubjectID: ann.ID, PropertyID: godparent.ID, ValueSubjectID: bob.ID})
	h := f.promote(ann, nil)
	for _, fld := range f.detail(h).Fields {
		if fld.ValueType == "subject" {
			t.Fatalf("field %q of value type subject returned for a Person", fld.PropertyKey)
		}
	}
}

// TestPersonDerivedRowsRecordInputs: the life rows record each owner they read
// and the place a place owner holds, with the graphs and Sources of the
// records they show.
func TestPersonDerivedRowsRecordInputs(t *testing.T) {
	f := newFixture(t)
	src := f.source("Register")
	person, _ := f.birthAt(src, text("York"))
	f.datedBirth(person, src, 1820)
	in := f.C.Graph().PageInputs()
	rows, err := conclusiondetails.PersonDerivedRows(f.C, person, in)
	must(t, err)
	var want [][]byte
	for _, r := range rows {
		for _, o := range r.Owners {
			want = append(want, o.Entity.ID)
			if o.Place != nil {
				want = append(want, o.Place.Entity.ID)
			}
		}
	}
	if len(want) < 3 {
		t.Fatalf("expected the birth event, the link and the place among %+v", rows)
	}
	handles, graphs, srcs := in.Lists()
	holdsIDs(t, "handles", handles, false, want...)
	holdsIDs(t, "graphs", graphs, true, evidencegraphstest.SoleGraph(t, f.C, src.ID).ID)
	holdsIDs(t, "sources", srcs, true, src.ID)
}
