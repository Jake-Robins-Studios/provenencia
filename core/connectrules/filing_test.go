package connectrules

import (
	"errors"
	"slices"
	"testing"

	"github.com/mendahu/provenencia/core/vocabkey"
)

// readerOf is a reader over links that records each call's records.
func readerOf(links []Link, calls *[][]string) func([]string) (map[string][]string, error) {
	return func(records []string) (map[string][]string, error) {
		*calls = append(*calls, slices.Clone(records))
		out := map[string][]string{}
		for _, r := range records {
			for _, l := range links {
				if l.From == r {
					out[r] = append(out[r], l.To)
				}
			}
		}
		return out, nil
	}
}

func TestLinksClosesCycle(t *testing.T) {
	chain := []Link{{"a", "b"}, {"b", "c"}}
	split := []Link{{"a", "b"}, {"a", "c"}}
	tests := []struct {
		name     string
		edges    []Link
		from, to string
		want     bool
	}{
		{"closing a chain", chain, "c", "a", true},
		{"extending a chain", chain, "a", "c", false},
		{"a split", split, "b", "c", false},
		{"a link to itself", nil, "a", "a", true},
		{"edges that already loop", []Link{{"a", "b"}, {"b", "a"}}, "c", "d", false},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got, err := NewLinks(tc.edges).ClosesCycle(tc.from, tc.to)
			if err != nil || got != tc.want {
				t.Fatalf("ClosesCycle = %v, %v, want %v", got, err, tc.want)
			}
		})
		t.Run(tc.name+" through a reader", func(t *testing.T) {
			var calls [][]string
			got, err := NewLinksReading(readerOf(tc.edges, &calls)).ClosesCycle(tc.from, tc.to)
			if err != nil || got != tc.want {
				t.Fatalf("ClosesCycle = %v, %v, want %v", got, err, tc.want)
			}
		})
	}
	t.Run("an added link counts", func(t *testing.T) {
		s := NewLinks(nil)
		s.Add(Link{"a", "b"})
		if got, _ := s.ClosesCycle("b", "a"); !got {
			t.Fatal("a→b was added, so b→a closes a loop")
		}
	})
	t.Run("an added link counts with a reader", func(t *testing.T) {
		var calls [][]string
		s := NewLinksReading(readerOf(nil, &calls))
		s.Add(Link{"a", "b"})
		if got, _ := s.ClosesCycle("b", "a"); !got {
			t.Fatal("a→b was added, so b→a closes a loop")
		}
	})
	t.Run("reads a level at a time", func(t *testing.T) {
		var calls [][]string
		s := NewLinksReading(readerOf([]Link{{"a", "b"}, {"b", "c"}, {"c", "d"}}, &calls))
		if got, err := s.ClosesCycle("d", "a"); err != nil || !got {
			t.Fatalf("ClosesCycle = %v, %v", got, err)
		}
		want := [][]string{{"a"}, {"b"}, {"c"}}
		if !slices.EqualFunc(calls, want, slices.Equal) {
			t.Fatalf("read calls = %v, want %v", calls, want)
		}
	})
	t.Run("reads each record once", func(t *testing.T) {
		var calls [][]string
		s := NewLinksReading(readerOf([]Link{{"a", "b"}, {"b", "c"}, {"a", "e"}}, &calls))
		if got, _ := s.ClosesCycle("x", "a"); got {
			t.Fatal("x is not reachable")
		}
		n := len(calls)
		if got, _ := s.ClosesCycle("y", "b"); got {
			t.Fatal("y is not reachable")
		}
		if len(calls) != n {
			t.Fatalf("a second check re-read %v", calls[n:])
		}
	})
	t.Run("a reader error", func(t *testing.T) {
		boom := errors.New("boom")
		s := NewLinksReading(func([]string) (map[string][]string, error) { return nil, boom })
		got, err := s.ClosesCycle("b", "a")
		if got || !errors.Is(err, boom) {
			t.Fatalf("ClosesCycle = %v, %v, want false, boom", got, err)
		}
	})
}

func TestFiled(t *testing.T) {
	place, _ := LookupBridge("place_relationship")
	rec := func(r string) []Value { return []Value{{Record: r}} }
	partOf := []vocabkey.BridgeTerm{vocabkey.TermPartOf}
	succ := []vocabkey.BridgeTerm{vocabkey.TermSucceededBy}
	t.Run("opens once per type and term, and a filing counts for the next bridge", func(t *testing.T) {
		opened := map[string]int{}
		f := NewFiled(func(b Bridge, term vocabkey.BridgeTerm) (*Links, error) {
			opened[b.BridgeTypeKey+"|"+string(term)]++
			return NewLinks(nil), nil
		})
		first, err := f.Decide(place, partOf, [][]Value{rec("a"), rec("b")})
		if err != nil || first.Decision != DecisionFiles {
			t.Fatalf("first = %+v, %v", first, err)
		}
		second, err := f.Decide(place, partOf, [][]Value{rec("b"), rec("a")})
		if err != nil || second.Decision != DecisionCycle {
			t.Fatalf("second = %+v, %v, want a cycle through the first", second, err)
		}
		other, err := f.Decide(place, succ, [][]Value{rec("b"), rec("a")})
		if err != nil || other.Decision != DecisionFiles {
			t.Fatalf("another term = %+v, %v", other, err)
		}
		if opened["place_relationship|part_of"] != 1 || opened["place_relationship|succeeded_by"] != 1 {
			t.Fatalf("opened = %v", opened)
		}
	})
	t.Run("an open error is returned", func(t *testing.T) {
		boom := errors.New("boom")
		f := NewFiled(func(Bridge, vocabkey.BridgeTerm) (*Links, error) { return nil, boom })
		if _, err := f.Decide(place, partOf, [][]Value{rec("a"), rec("b")}); !errors.Is(err, boom) {
			t.Fatalf("err = %v", err)
		}
	})
}

func TestDecide(t *testing.T) {
	place, _ := LookupBridge("place_relationship")
	rel, _ := LookupBridge("relationship")
	part, _ := LookupBridge("participation")
	rec := func(r string) []Value { return []Value{{Record: r}} }
	partOf := []vocabkey.BridgeTerm{vocabkey.TermPartOf}
	boom := errors.New("boom")
	edges := func(e ...Link) func() (*Links, error) {
		return func() (*Links, error) { return NewLinks(e), nil }
	}
	never := func() (*Links, error) {
		t.Fatal("filed must not be called")
		return nil, nil
	}
	tests := []struct {
		name  string
		b     Bridge
		terms []vocabkey.BridgeTerm
		ends  [][]Value
		filed func() (*Links, error)
		want  Result
		err   error
	}{
		{"term order is free", place, []vocabkey.BridgeTerm{vocabkey.TermSucceededBy, vocabkey.TermPartOf},
			[][]Value{rec("a"), rec("b")}, edges(Link{"b", "a"}), Result{Decision: DecisionCycle}, nil},
		{"term order is free, other way", place, []vocabkey.BridgeTerm{vocabkey.TermPartOf, vocabkey.TermSucceededBy},
			[][]Value{rec("a"), rec("b")}, edges(Link{"b", "a"}), Result{Decision: DecisionCycle}, nil},
		{"an endpoint with no value", place, partOf,
			[][]Value{rec("a"), nil}, never, Result{Decision: DecisionIncomplete}, nil},
		{"first waiting value", place, partOf,
			[][]Value{rec("a"), {{Record: "b"}, {Wait: "skipped"}, {Wait: "unset"}}}, never,
			Result{Decision: DecisionWaits, Endpoint: 1, Value: 1, Wait: "skipped"}, nil},
		{"endpoint 0 on two records decides before a wait on 1", place, partOf,
			[][]Value{{{Record: "a"}, {Record: "b"}}, {{Record: "c"}}}, never,
			Result{Decision: DecisionIncomplete}, nil},
		{"one record", place, partOf, [][]Value{rec("a"), rec("a")}, never,
			Result{Decision: DecisionSelfLink}, nil},
		{"self-link before term", place, nil, [][]Value{rec("a"), rec("a")}, never,
			Result{Decision: DecisionSelfLink}, nil},
		{"typed link with no term", rel, nil, [][]Value{rec("a"), rec("b")}, never,
			Result{Decision: DecisionIncomplete}, nil},
		{"role needs no term", part, nil, [][]Value{rec("a"), rec("b")}, never,
			Result{Decision: DecisionFiles, Records: []string{"a", "b"}}, nil},
		{"a filing carries its ends in endpoint order and the link it checked", place, partOf,
			[][]Value{{{Record: "a"}, {Record: "a"}}, rec("b")}, edges(Link{"c", "d"}),
			Result{Decision: DecisionFiles, Records: []string{"a", "b"}, Link: &Link{From: "a", To: "b"}}, nil},
		{"closes part_of", place, partOf, [][]Value{rec("a"), rec("b")}, edges(Link{"b", "a"}),
			Result{Decision: DecisionCycle}, nil},
		{"succeeded_by beside part_of", place, []vocabkey.BridgeTerm{vocabkey.TermSucceededBy},
			[][]Value{rec("a"), rec("b")}, edges(), Result{Decision: DecisionFiles, Records: []string{"a", "b"}, Link: &Link{From: "a", To: "b"}}, nil},
		{"spouse is not loop-checked", rel, []vocabkey.BridgeTerm{vocabkey.TermSpouse},
			[][]Value{rec("a"), rec("b")}, never, Result{Decision: DecisionFiles, Records: []string{"a", "b"}}, nil},
		{"loop check error", place, partOf, [][]Value{rec("a"), rec("b")},
			func() (*Links, error) {
				return NewLinksReading(func([]string) (map[string][]string, error) { return nil, boom }), nil
			}, Result{}, boom},
		{"filed fails", place, partOf, [][]Value{rec("a"), rec("b")},
			func() (*Links, error) { return nil, boom }, Result{}, boom},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got, err := decide(tc.b, tc.terms, tc.ends, tc.filed)
			if !errors.Is(err, tc.err) {
				t.Fatalf("err = %v, want %v", err, tc.err)
			}
			if !sameResult(got, tc.want) {
				t.Fatalf("decide = %+v, want %+v", got, tc.want)
			}
		})
	}
}

func sameResult(a, b Result) bool {
	if a.Decision != b.Decision || a.Endpoint != b.Endpoint || a.Value != b.Value || a.Wait != b.Wait ||
		!slices.Equal(a.Records, b.Records) || (a.Link == nil) != (b.Link == nil) {
		return false
	}
	return a.Link == nil || *a.Link == *b.Link
}

func TestTermIsTheLowestKey(t *testing.T) {
	got := Term([]vocabkey.BridgeTerm{vocabkey.TermSucceededBy, "", vocabkey.TermPartOf})
	if got != vocabkey.TermPartOf {
		t.Fatalf("Term = %q", got)
	}
	if Term(nil) != "" {
		t.Fatal("no terms, no term")
	}
}
