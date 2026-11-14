package graphalign_test

import (
	"errors"
	"fmt"
	"slices"
	"testing"

	"github.com/mendahu/provenencia/core/graphalign"
	"github.com/mendahu/provenencia/core/vocabkey"
)

func TestConnections(t *testing.T) {
	handle := func(h string) graphalign.EndTarget {
		return graphalign.EndTarget{Target: graphalign.TargetHandle, HandleID: id(h)}
	}
	isNew := graphalign.EndTarget{Target: graphalign.TargetNew}
	skip := graphalign.EndTarget{Waits: graphalign.ConnectionSkipped}
	unset := graphalign.EndTarget{Waits: graphalign.ConnectionUnset}
	partOf := []vocabkey.BridgeTerm{vocabkey.TermPartOf}
	place := func(bid string, from, to string, terms []vocabkey.BridgeTerm) graphalign.PageBridge {
		return graphalign.PageBridge{
			ID: id(bid), TypeKey: vocabkey.BridgePlaceRelationship, Terms: terms,
			Ends: [][][]byte{{id(from)}, {id(to)}},
		}
	}
	// The filed link York part_of Ontario, and York succeeded_by Ontario.
	york := []filedLink{{vocabkey.TermPartOf, "H-york", "H-ont"}}
	yorkSucceeded := []filedLink{{vocabkey.TermSucceededBy, "H-york", "H-ont"}}
	person := graphalign.PageBridge{
		ID: id("b1"), TypeKey: vocabkey.BridgeParticipation,
		Ends: [][][]byte{{id("ann")}, {id("birth")}},
	}
	withEnds := func(b graphalign.PageBridge, ends ...[][]byte) graphalign.PageBridge {
		b.Ends = ends
		return b
	}
	rel := graphalign.PageBridge{
		ID: id("b1"), TypeKey: vocabkey.BridgeRelationship,
		Ends: [][][]byte{{id("ann")}, {id("bob")}},
	}
	ends := func(kv ...any) map[string]graphalign.EndTarget {
		m := map[string]graphalign.EndTarget{}
		for i := 0; i < len(kv); i += 2 {
			m[kv[i].(string)] = kv[i+1].(graphalign.EndTarget)
		}
		return m
	}
	tests := []struct {
		name    string
		bridges []graphalign.PageBridge
		ends    map[string]graphalign.EndTarget
		filed   []filedLink
		want    []graphalign.Connection
	}{
		{"both ends on records", []graphalign.PageBridge{person},
			ends("ann", handle("H-ann"), "birth", handle("H-birth")), nil,
			[]graphalign.Connection{{BridgeID: id("b1"), Outcome: graphalign.ConnectionFiles}}},
		{"both ends anchors, no edges", []graphalign.PageBridge{place("b1", "a", "b", partOf)},
			ends("a", handle("H-a"), "b", handle("H-b")), nil,
			[]graphalign.Connection{{BridgeID: id("b1"), Outcome: graphalign.ConnectionFiles}}},
		{"a Subject not on the page", []graphalign.PageBridge{person},
			ends("ann", handle("H-ann")), nil,
			[]graphalign.Connection{{BridgeID: id("b1"), Outcome: graphalign.ConnectionNotOnPage, Waiting: id("birth")}}},
		{"an end set to Skip", []graphalign.PageBridge{person},
			ends("ann", handle("H-ann"), "birth", skip), nil,
			[]graphalign.Connection{{BridgeID: id("b1"), Outcome: graphalign.ConnectionSkipped, Waiting: id("birth")}}},
		{"an end with no target", []graphalign.PageBridge{person},
			ends("ann", unset, "birth", handle("H-birth")), nil,
			[]graphalign.Connection{{BridgeID: id("b1"), Outcome: graphalign.ConnectionUnset, Waiting: id("ann")}}},
		{"the first waiting end in endpoint order", []graphalign.PageBridge{person},
			ends("ann", skip, "birth", unset), nil,
			[]graphalign.Connection{{BridgeID: id("b1"), Outcome: graphalign.ConnectionSkipped, Waiting: id("ann")}}},
		{"an endpoint with no Subject", []graphalign.PageBridge{withEnds(person, [][]byte{id("ann")}, nil)},
			ends("ann", handle("H-ann")), nil,
			[]graphalign.Connection{{BridgeID: id("b1"), Outcome: graphalign.ConnectionNotOnPage}}},
		{"Subjects on two records at one end", []graphalign.PageBridge{withEnds(person, [][]byte{id("ann"), id("ann2")}, [][]byte{id("birth")})},
			ends("ann", handle("H-ann"), "ann2", handle("H-ann2"), "birth", handle("H-birth")), nil,
			[]graphalign.Connection{{BridgeID: id("b1"), Outcome: graphalign.ConnectionNotOnPage}}},
		{"a typed link with no type", []graphalign.PageBridge{rel},
			ends("ann", handle("H-ann"), "bob", handle("H-bob")), nil,
			[]graphalign.Connection{{BridgeID: id("b1"), Outcome: graphalign.ConnectionNotOnPage}}},
		{"both ends one record", []graphalign.PageBridge{person},
			ends("ann", handle("H-x"), "birth", handle("H-x")), nil,
			[]graphalign.Connection{{BridgeID: id("b1"), Outcome: graphalign.ConnectionOutcome("self_link")}}},
		{"a loop with the canon", []graphalign.PageBridge{place("b1", "ont", "york", partOf)},
			ends("ont", handle("H-ont"), "york", handle("H-york")), york,
			[]graphalign.Connection{{BridgeID: id("b1"), Outcome: graphalign.ConnectionOutcome("cycle")}}},
		{"a succeeded_by loop", []graphalign.PageBridge{place("b1", "ont", "york", []vocabkey.BridgeTerm{vocabkey.TermSucceededBy})},
			ends("ont", handle("H-ont"), "york", handle("H-york")), yorkSucceeded,
			[]graphalign.Connection{{BridgeID: id("b1"), Outcome: graphalign.ConnectionOutcome("cycle")}}},
		{"succeeded_by over the same places", []graphalign.PageBridge{place("b1", "ont", "york", []vocabkey.BridgeTerm{vocabkey.TermSucceededBy})},
			ends("ont", handle("H-ont"), "york", handle("H-york")), york,
			[]graphalign.Connection{{BridgeID: id("b1"), Outcome: graphalign.ConnectionFiles}}},
		{"page links in id order", []graphalign.PageBridge{place("b2", "b", "a", partOf), place("b1", "a", "b", partOf)},
			ends("a", isNew, "b", isNew), nil,
			[]graphalign.Connection{
				{BridgeID: id("b1"), Outcome: graphalign.ConnectionFiles},
				{BridgeID: id("b2"), Outcome: graphalign.ConnectionOutcome("cycle")},
			}},
		{"a skipped end frees the loop", []graphalign.PageBridge{place("b1", "a", "b", partOf), place("b2", "b", "a", partOf)},
			ends("a", skip, "b", isNew), nil,
			[]graphalign.Connection{
				{BridgeID: id("b1"), Outcome: graphalign.ConnectionSkipped, Waiting: id("a")},
				{BridgeID: id("b2"), Outcome: graphalign.ConnectionSkipped, Waiting: id("a")},
			}},
		{"New and New", []graphalign.PageBridge{place("b1", "a", "b", partOf)},
			ends("a", isNew, "b", isNew), nil,
			[]graphalign.Connection{{BridgeID: id("b1"), Outcome: graphalign.ConnectionFiles}}},
		{"an unknown bridge type is left out", []graphalign.PageBridge{{ID: id("b1"), TypeKey: "nope"}},
			nil, nil, nil},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got, err := graphalign.Connections(tc.bridges, tc.ends, fakeFiled(tc.filed, nil))
			if err != nil {
				t.Fatal(err)
			}
			if len(got) != len(tc.want) {
				t.Fatalf("got %+v, want %+v", got, tc.want)
			}
			for i, w := range tc.want {
				g := got[i]
				if string(g.BridgeID) != string(w.BridgeID) || g.Outcome != w.Outcome || string(g.Waiting) != string(w.Waiting) {
					t.Fatalf("connection %d = %+v, want %+v", i, g, w)
				}
			}
		})
	}
}

func TestConnectionOutcomesListEveryRefusal(t *testing.T) {
	got := map[graphalign.ConnectionOutcome]bool{}
	for _, o := range graphalign.ConnectionOutcomes() {
		got[o] = true
	}
	for _, want := range []graphalign.ConnectionOutcome{"files", "skipped", "unset", "not_on_page", "self_link", "cycle"} {
		if !got[want] {
			t.Fatalf("missing outcome %q", want)
		}
	}
	if len(got) != 6 {
		t.Fatalf("outcomes %v", got)
	}
}

// filedLink is one filed place link of a term, from a handle to a handle.
type filedLink struct {
	term     vocabkey.BridgeTerm
	from, to string
}

// fakeFiled reads links as a catalog would, and records each call's type,
// term and handles in calls.
func fakeFiled(links []filedLink, calls *[]filedCall) graphalign.FiledLinks {
	return func(typeKey vocabkey.SubjectType, term vocabkey.BridgeTerm, handles [][]byte) (map[string][][]byte, error) {
		if calls != nil {
			*calls = append(*calls, filedCall{typeKey, term, handles})
		}
		out := map[string][][]byte{}
		for _, h := range handles {
			for _, l := range links {
				if l.term == term && string(id(l.from)) == string(h) {
					out[string(h)] = append(out[string(h)], id(l.to))
				}
			}
		}
		return out, nil
	}
}

type filedCall struct {
	typeKey vocabkey.SubjectType
	term    vocabkey.BridgeTerm
	handles [][]byte
}

func TestConnectionsReaderIsAskedByTypeAndTerm(t *testing.T) {
	var calls []filedCall
	bridge := graphalign.PageBridge{
		ID: id("b1"), TypeKey: vocabkey.BridgePlaceRelationship,
		Terms: []vocabkey.BridgeTerm{vocabkey.TermPartOf}, Ends: [][][]byte{{id("a")}, {id("b")}},
	}
	ends := map[string]graphalign.EndTarget{
		"a": {Target: graphalign.TargetHandle, HandleID: id("H-a")},
		"b": {Target: graphalign.TargetHandle, HandleID: id("H-b")},
	}
	if _, err := graphalign.Connections([]graphalign.PageBridge{bridge}, ends, fakeFiled(nil, &calls)); err != nil {
		t.Fatal(err)
	}
	if len(calls) != 1 || calls[0].typeKey != vocabkey.BridgePlaceRelationship || calls[0].term != vocabkey.TermPartOf ||
		len(calls[0].handles) != 1 || string(calls[0].handles[0]) != string(id("H-b")) {
		t.Fatalf("calls = %+v", calls)
	}
}

func TestConnectionsReaderError(t *testing.T) {
	boom := errors.New("boom")
	bridge := graphalign.PageBridge{
		ID: id("b1"), TypeKey: vocabkey.BridgePlaceRelationship,
		Terms: []vocabkey.BridgeTerm{vocabkey.TermPartOf}, Ends: [][][]byte{{id("a")}, {id("b")}},
	}
	ends := map[string]graphalign.EndTarget{
		"a": {Target: graphalign.TargetHandle, HandleID: id("H-a")},
		"b": {Target: graphalign.TargetHandle, HandleID: id("H-b")},
	}
	got, err := graphalign.Connections([]graphalign.PageBridge{bridge}, ends,
		func(vocabkey.SubjectType, vocabkey.BridgeTerm, [][]byte) (map[string][][]byte, error) {
			return nil, boom
		})
	if !errors.Is(err, boom) || got != nil {
		t.Fatalf("Connections = %+v, %v, want nil and boom", got, err)
	}
}

// TestConnectionsReadOnlyWhatTheLoopReaches: 200 bridges between New records
// read no filed link, and the one between two handles reads one level at a
// time from its to end, whatever else is filed.
func TestConnectionsReadOnlyWhatTheLoopReaches(t *testing.T) {
	partOf := []vocabkey.BridgeTerm{vocabkey.TermPartOf}
	ends := map[string]graphalign.EndTarget{
		"h1": {Target: graphalign.TargetHandle, HandleID: id("H1")},
		"h2": {Target: graphalign.TargetHandle, HandleID: id("H2")},
	}
	var bs []graphalign.PageBridge
	for i := 0; i < 200; i++ {
		from, to := fmt.Sprintf("a%d", i), fmt.Sprintf("b%d", i)
		ends[from] = graphalign.EndTarget{Target: graphalign.TargetNew}
		ends[to] = graphalign.EndTarget{Target: graphalign.TargetNew}
		bs = append(bs, graphalign.PageBridge{
			ID: id(fmt.Sprintf("b%06d", i)), TypeKey: vocabkey.BridgePlaceRelationship, Terms: partOf,
			Ends: [][][]byte{{id(from)}, {id(to)}},
		})
	}
	bs = append(bs, graphalign.PageBridge{
		ID: id("c"), TypeKey: vocabkey.BridgePlaceRelationship, Terms: partOf,
		Ends: [][][]byte{{id("h1")}, {id("h2")}},
	})
	links := []filedLink{{vocabkey.TermPartOf, "H2", "H3"}, {vocabkey.TermPartOf, "H3", "H4"}}
	for i := 0; i < 1000; i++ {
		links = append(links, filedLink{vocabkey.TermPartOf, fmt.Sprintf("U%d", i), fmt.Sprintf("U%d", i+1)})
	}
	var calls []filedCall
	got, err := graphalign.Connections(bs, ends, fakeFiled(links, &calls))
	if err != nil {
		t.Fatal(err)
	}
	if len(got) != 201 {
		t.Fatalf("%d connections", len(got))
	}
	var read []string
	for _, c := range calls {
		for _, h := range c.handles {
			read = append(read, string(h))
		}
	}
	want := []string{string(id("H2")), string(id("H3")), string(id("H4"))}
	if !slices.Equal(read, want) || len(calls) != 3 {
		t.Fatalf("the reader was asked for %q in %d calls, want %q one level at a time", read, len(calls), want)
	}
}
