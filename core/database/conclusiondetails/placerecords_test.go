package conclusiondetails_test

import (
	"bytes"
	"fmt"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/autoreconcile"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/conclusiondetails"
	"github.com/Jake-Robins-Studios/provenencia/core/database/databasetest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/dbtest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencegraphs/evidencegraphstest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/observations"
	"github.com/Jake-Robins-Studios/provenencia/core/database/properties"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcecredibility"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcecredibilitygrades"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sources"
	"github.com/Jake-Robins-Studios/provenencia/core/database/subjectpositions"
	"github.com/Jake-Robins-Studios/provenencia/core/database/subjects"
	"github.com/Jake-Robins-Studios/provenencia/core/database/subjectvocab/subjectvocabtest"
	"github.com/Jake-Robins-Studios/provenencia/core/hops"
	"github.com/Jake-Robins-Studios/provenencia/core/propertymeta"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
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
	h, _, _, place := f.fileBirth(src, toponyms, nil, nil, nil)
	return h, place
}

// placedBirth files a Person born at a Place named toponym on src, and
// promotes each onto the handle given (nil promotes a new handle). It returns
// the handles.
func (f *fixture) placedBirth(src sources.Source, toponym string, person, birth, place []byte) (personH, birthH, placeH []byte) {
	f.T.Helper()
	personH, birthH, placeH, _ = f.fileBirth(src, []observations.Input{text(toponym)}, person, birth, place)
	return personH, birthH, placeH
}

// fileBirth is the one filing of a birth: a Person, a birth Event and a Place
// with the toponym records given, linked, each promoted onto the handle given
// (nil for a new one). It returns the handles and the Place's Subject.
func (f *fixture) fileBirth(src sources.Source, toponyms []observations.Input, person, birth, place []byte) (personH, birthH, placeH []byte, placeSubject subjects.Subject) {
	f.T.Helper()
	p, b, pl := f.personOn(src), f.subjectOn(src, "event"), f.subjectOn(src, "place")
	f.at(p, 0, 0)
	f.at(b, 4, 0)
	f.at(pl, 8, 0)
	f.cite(p, f.nameIn(p, "form:Ann Lee"))
	eventType := f.Prop("event_type")
	term := f.Term("event_type", "birth")
	f.cite(b, observations.Input{SubjectID: b.ID, PropertyID: eventType.ID, ValueTermID: term.ID})
	for _, in := range toponyms {
		in.SubjectID, in.PropertyID = pl.ID, f.Prop("toponym").ID
		f.cite(pl, in)
	}
	// A blank toponym can't be filed through the write path; blank the marker.
	db, err := f.C.DB()
	must(f.T, err)
	_, err = db.Exec(`UPDATE observations SET value_text = '  ' || char(9) || ' ' WHERE value_text = ?`, blankMarker)
	must(f.T, err)
	f.Participation(src, f.arts[string(src.ID)], p, b, "subject")
	f.Locate(src, f.arts[string(src.ID)], b, pl)
	personH = f.promote(p, person)
	birthH = f.promote(b, birth)
	placeH = f.promote(pl, place)
	return personH, birthH, placeH, pl
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
	must(t, subjectvocabtest.EnsureBinding(f.C, f.person.ID, godparent.ID, 9))
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

// grade assesses src as the provenencia credibility grade key.
func (f *fixture) grade(src sources.Source, key string) {
	f.T.Helper()
	g, err := sourcecredibilitygrades.Lookup(f.C, key, vocabkey.OriginProvenencia)
	must(f.T, err)
	_, err = writes.Call(f.C, writes.Op{Action: "create_source_credibility_assessment", UserID: userID}, func(tx *database.Tx) (sourcecredibility.Assessment, []rowchange.Change, error) {
		return sourcecredibility.Upsert(tx, userID, sourcecredibility.UpsertInput{SourceID: src.ID, CredibilityGradeID: g.ID})
	})
	must(f.T, err)
}

// TestPlaceOwnersCarryTheVote: the Birth place sheet lists every record behind
// the event's place links, each with what the vote did to it (S16-80 AC-3.x).
func TestPlaceOwnersCarryTheVote(t *testing.T) {
	type outcome struct {
		reason    string
		vote      autoreconcile.Vote
		valueRank int // 0 for "folded"
		weakCred  bool
	}
	tests := []struct {
		name  string
		build func(f *fixture) (person, shown, other []byte)
		shown []outcome // the shown place's records
		other []outcome // the other place's records
	}{
		{"three Sources outvote the fourth", func(f *fixture) ([]byte, []byte, []byte) {
			person, birth, swift := f.placedBirth(f.source("Register 1"), "Swift Current", nil, nil, nil)
			f.placedBirth(f.source("Register 2"), "Swift Current", person, birth, swift)
			f.placedBirth(f.source("Register 3"), "Swift Current", person, birth, swift)
			_, _, england := f.placedBirth(f.source("Gazette"), "England", person, birth, nil)
			return person, swift, england
		}, []outcome{{"kept", autoreconcile.Vote{}, 1, false}, {"kept", autoreconcile.Vote{}, 1, false}, {"kept", autoreconcile.Vote{}, 1, false}},
			[]outcome{{"outvoted", autoreconcile.Vote{Support: 3, Of: 4}, 1, false}}},
		{"a container folds into the place it contains", func(f *fixture) ([]byte, []byte, []byte) {
			reg := f.source("Register")
			person, birth, swift := f.placedBirth(reg, "Swift Current", nil, nil, nil)
			_, _, canada := f.placedBirth(f.source("Gazette"), "Canada", person, birth, nil)
			rel := f.source("Atlas")
			s, c := f.subjectOn(rel, "place"), f.subjectOn(rel, "place")
			f.at(s, 0, 0)
			f.at(c, 4, 0)
			f.PlaceRel(rel, f.arts[string(rel.ID)], s, c, "part_of")
			f.promote(s, swift)
			f.promote(c, canada)
			return person, swift, canada
		}, []outcome{{"kept", autoreconcile.Vote{}, 1, false}}, []outcome{{"folded", autoreconcile.Vote{}, 0, false}}},
		{"a low-trust record is weak", func(f *fixture) ([]byte, []byte, []byte) {
			low := f.source("Rumour")
			f.grade(low, "low_trust")
			person, birth, swift := f.placedBirth(low, "Swift Current", nil, nil, nil)
			_, _, england := f.placedBirth(f.source("Gazette"), "England", person, birth, nil)
			return person, swift, england
		}, []outcome{{"weak", autoreconcile.Vote{}, 1, true}}, []outcome{{"kept", autoreconcile.Vote{}, 1, false}}},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			f := newFixture(t)
			person, shown, other := tc.build(f)
			owners := f.placeRows(person)
			if len(owners) != 2 {
				t.Fatalf("%d owners, want two (one per place)", len(owners))
			}
			for _, o := range owners {
				want := tc.shown
				if bytes.Equal(o.Place.Entity.ID, other) {
					want = tc.other
				} else if !bytes.Equal(o.Place.Entity.ID, shown) {
					t.Fatalf("owner holds place %x, want %x or %x", o.Place.Entity.ID, shown, other)
				}
				if len(o.Field.Outcomes) != len(want) {
					t.Fatalf("owner of %x: %d records, want %d", o.Place.Entity.ID, len(o.Field.Outcomes), len(want))
				}
				for i, got := range o.Field.Outcomes {
					w := want[i]
					if got.Reason != w.reason || got.Vote != w.vote || got.ValueRank != w.valueRank || (got.Provenance.Credibility < 0) != w.weakCred {
						t.Fatalf("owner of %x record %d: %q %+v rank %d provenance %+v, want %+v", o.Place.Entity.ID, i, got.Reason, got.Vote, got.ValueRank, got.Provenance, w)
					}
				}
			}
		})
	}
}

// TestOutvotedPlaceLeavesSearchOnWrite: a write that changes the event's place
// vote but not the association's displayed rows still drops the outvoted
// place from the Person's and Event's search documents, as a rebuild does.
func TestOutvotedPlaceLeavesSearchOnWrite(t *testing.T) {
	f := newFixture(t)
	englandDocs := func() []string {
		rows, err := dbtest.MustDB(t, f.C).Query(`SELECT kind, entity_id FROM catalog_search_docs
			WHERE kind IN ('person', 'event') AND (title LIKE '%England%' OR secondary LIKE '%England%')`)
		must(t, err)
		defer rows.Close()
		var out []string
		for rows.Next() {
			var kind, id string
			must(t, rows.Scan(&kind, &id))
			out = append(out, kind+" "+id)
		}
		must(t, rows.Err())
		return out
	}
	person, birth, swift := f.placedBirth(f.source("Register 1"), "Swift Current", nil, nil, nil)
	f.placedBirth(f.source("Gazette"), "England", person, birth, nil)
	f.placedBirth(f.source("Register 2"), "Swift Current", person, birth, swift)
	if got := englandDocs(); len(got) != 0 {
		t.Fatalf("outvoted England still matches search documents %v", got)
	}
}
