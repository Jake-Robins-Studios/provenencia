// Package grapheventtitles titles and dates every Event Subject on one Evidence
// graph, from what that graph cites: the event's own event_name and
// event_type, the people its subject-role participations name, and the places
// its locations name. The rule is eventtitle's, the same one canonical Event
// summaries use, so a card and the Event it is promoted to title themselves by
// one matrix.
//
// It reads the loaded Evidence graph and issues no query.
package grapheventtitles

import (
	"slices"
	"sort"
	"strings"

	"github.com/mendahu/provenencia/core/database/graphcache"
	"github.com/mendahu/provenencia/core/database/observations"
	"github.com/mendahu/provenencia/core/datevalue"
	"github.com/mendahu/provenencia/core/eventtitle"
	"github.com/mendahu/provenencia/core/matchregistry"
	"github.com/mendahu/provenencia/core/namevalue"
	"github.com/mendahu/provenencia/core/valuecodec"
	"github.com/mendahu/provenencia/core/valuecompare"
	"github.com/mendahu/provenencia/core/vocabkey"
)

// Title is one Event Subject's chosen title and its dating.
type Title struct {
	SubjectID []byte
	Plan      eventtitle.Plan
	Dating    valuecompare.Dating
}

// eventLead and eventPeriod are the Property keys an Event's dating reads.
var eventLead, eventPeriod = matchregistry.Default().Subject.EventPeriod()

// eventDates is what one Event Subject's Observations record: the first lead,
// start and end date and every as-of.
type eventDates struct {
	date, start, end *datevalue.Value
	samples          []datevalue.Value
}

type naming struct {
	text       string
	nameID     []byte
	termKey    string
	termOrigin string
	termText   string
}

type titledEvent struct {
	id         []byte
	ref, label string
}

// FromStored chooses titles from a loaded Evidence graph. Term labels are
// applied here; they are not stored on the graph.
func FromStored(eg graphcache.EvidenceGraph, propKey map[string]string, terms map[string]struct{ Key, Origin, Label string }) []Title {
	var events []titledEvent
	for _, s := range eg.Subjects {
		if s.TypeKey != vocabkey.Event || s.TypeOrigin != vocabkey.OriginProvenencia {
			continue
		}
		events = append(events, titledEvent{id: s.ID, ref: s.Ref, label: s.Label})
	}
	sort.Slice(events, func(i, j int) bool { return events[i].ref < events[j].ref })
	first := map[string]naming{}
	toponyms := map[string][]observations.TextRecord{}
	for _, o := range eg.Observations {
		if o.Polarity != "positive" {
			continue
		}
		keyName := propKey[string(o.PropertyID)]
		switch keyName {
		case "event_name", vocabkey.PropertyEventType, vocabkey.PropertyName, vocabkey.PropertyToponym:
		default:
			continue
		}
		if keyName == vocabkey.PropertyToponym {
			toponyms[string(o.SubjectID)] = append(toponyms[string(o.SubjectID)], observations.TextRecord{Ref: o.Ref, Polarity: o.Polarity, Text: o.Text})
			continue
		}
		n := naming{text: strings.TrimSpace(o.Text), nameID: o.NameID}
		if t, ok := terms[string(o.TermID)]; ok {
			n.termKey, n.termOrigin, n.termText = t.Key, t.Origin, t.Label
		}
		usable := n.text != "" || len(n.nameID) > 0 || n.termKey != ""
		k := key(o.SubjectID, keyName)
		if _, done := first[k]; usable && !done {
			first[k] = n
		}
	}
	dates := map[string]*eventDates{}
	for _, o := range eg.Observations {
		if o.Polarity != "positive" || len(o.Date) == 0 {
			continue
		}
		keyName := vocabkey.PropertyKey(propKey[string(o.PropertyID)])
		if keyName != eventLead && keyName != eventPeriod.Start && keyName != eventPeriod.End && keyName != eventPeriod.Samples {
			continue
		}
		d, err := valuecodec.UnmarshalDate(o.Date)
		if err != nil {
			continue
		}
		e := dates[string(o.SubjectID)]
		if e == nil {
			e = &eventDates{}
			dates[string(o.SubjectID)] = e
		}
		switch keyName {
		case eventLead:
			if e.date == nil {
				e.date = &d
			}
		case eventPeriod.Start:
			if e.start == nil {
				e.start = &d
			}
		case eventPeriod.End:
			if e.end == nil {
				e.end = &d
			}
		case eventPeriod.Samples:
			e.samples = append(e.samples, d)
		}
	}
	places := slices.Clone(eg.EventPlaces)
	names := map[string]namevalue.Value{}
	for _, o := range eg.Observations {
		if len(o.Name) == 0 || len(o.NameID) == 0 {
			continue
		}
		n, err := valuecodec.UnmarshalName(o.Name)
		if err != nil {
			continue
		}
		names[string(o.NameID)] = n
	}
	placeNames := make(map[string]string, len(toponyms))
	for id, records := range toponyms {
		placeNames[id] = observations.FirstText(records)
	}
	return assemble(events, first, placeNames, eg.EventPeople, places, names, dates)
}

func assemble(events []titledEvent, first map[string]naming, placeNames map[string]string, people, places []graphcache.EvidenceEdge, names map[string]namevalue.Value, dates map[string]*eventDates) []Title {
	peopleOf := map[string][]eventtitle.Subject{}
	seen := map[string]bool{}
	for _, e := range people {
		pair := string(e.From) + "\x00" + string(e.To)
		if seen[pair] {
			continue
		}
		seen[pair] = true
		var subject eventtitle.Subject
		if n, ok := first[key(e.To, vocabkey.PropertyName)]; ok {
			if v, ok := names[string(n.nameID)]; ok {
				subject.Name = &v
			}
		}
		peopleOf[string(e.From)] = append(peopleOf[string(e.From)], subject)
	}
	// A place's name is its first toponym (observations.FirstText); the
	// event's place is the first named one by place ref.
	sort.SliceStable(places, func(i, j int) bool { return places[i].ToRef < places[j].ToRef })
	placeOf := map[string]string{}
	for _, e := range places {
		if _, done := placeOf[string(e.From)]; done {
			continue
		}
		if name := placeNames[string(e.To)]; name != "" {
			placeOf[string(e.From)] = name
		}
	}

	out := make([]Title, 0, len(events))
	for _, e := range events {
		parts := eventtitle.Parts{
			Label:    e.label,
			Ref:      e.ref,
			Subjects: peopleOf[string(e.id)],
			Place:    placeOf[string(e.id)],
		}
		if n, ok := first[key(e.id, "event_name")]; ok {
			parts.RecordedName = n.text
		}
		if n, ok := first[key(e.id, vocabkey.PropertyEventType)]; ok {
			parts.TypeKey = n.termKey
			parts.TypeOrigin = n.termOrigin
			parts.TypeLabel = n.termText
			if parts.TypeLabel == "" {
				parts.TypeLabel = n.text
			}
		}
		t := Title{SubjectID: e.id, Plan: eventtitle.Choose(parts)}
		if d := dates[string(e.id)]; d != nil {
			t.Dating = valuecompare.DatingOf(d.date, d.start, d.end, d.samples)
		}
		out = append(out, t)
	}
	return out
}

func key(subjectID []byte, propertyKey string) string {
	return string(subjectID) + "\x00" + propertyKey
}
