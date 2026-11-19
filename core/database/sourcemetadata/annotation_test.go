package sourcemetadata

import (
	"reflect"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sources"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue"
	"github.com/Jake-Robins-Studios/provenencia/core/valuemark"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/google/uuid"
)

// chainsOf is the requirements of one full-form text, fields named by id.
func chainsOf(t *testing.T, text string) []citationformat.Requirement {
	t.Helper()
	tpl, diags := citationformat.Parse(text, citationformat.FormFull)
	if tpl == nil {
		t.Fatalf("%q: %v", text, diags)
	}
	return citationformat.Requirements(tpl)
}

func fieldTarget(level vocabkey.Level, id uuid.UUID) citationformat.Target {
	return citationformat.Target{Level: level, Field: citationformat.FieldRef{ID: id}}
}

func TestNeedsAt(t *testing.T) {
	a, p := uuid.New(), uuid.New()
	tok := func(id uuid.UUID) string { return "#" + id.String() }
	tests := []struct {
		name  string
		text  string
		level vocabkey.Level
		need  map[uuid.UUID]citationformat.Need
		order []uuid.UUID
		page  citationformat.Need // the need of the printed page's chain, "" for none
	}{
		{name: "outside a group is needed", text: "{source.meta." + tok(a) + "}.", level: vocabkey.LevelSource,
			need: map[uuid.UUID]citationformat.Need{a: citationformat.NeedNeeded}, order: []uuid.UUID{a}},
		{name: "inside a group is used", text: "[{source.meta." + tok(a) + "}]", level: vocabkey.LevelSource,
			need: map[uuid.UUID]citationformat.Need{a: citationformat.NeedUsed}, order: []uuid.UUID{a}},
		{name: "a graph head is needed at graph", text: "{graph.meta." + tok(a) + "|source.meta." + tok(a) + "}.", level: vocabkey.LevelGraph,
			need: map[uuid.UUID]citationformat.Need{a: citationformat.NeedNeeded}, order: []uuid.UUID{a}},
		{name: "a later option is used and no head", text: "{graph.meta." + tok(a) + "|source.meta." + tok(a) + "}.", level: vocabkey.LevelSource,
			need: map[uuid.UUID]citationformat.Need{a: citationformat.NeedUsed}},
		{name: "an always-set option makes the chain used", text: "{source.meta." + tok(a) + "|source.title}", level: vocabkey.LevelSource,
			need: map[uuid.UUID]citationformat.Need{a: citationformat.NeedUsed}, order: []uuid.UUID{a}},
		{name: "a built-in head leaves its options used", text: "{citation.page|source.meta." + tok(p) + "}", level: vocabkey.LevelSource,
			need: map[uuid.UUID]citationformat.Need{p: citationformat.NeedUsed}, page: citationformat.NeedNeeded},
		{name: "the strongest chain wins", text: "[{source.meta." + tok(a) + "}]{source.meta." + tok(a) + "}", level: vocabkey.LevelSource,
			need: map[uuid.UUID]citationformat.Need{a: citationformat.NeedNeeded}, order: []uuid.UUID{a}},
		{name: "a field named by key is not read", text: "{source.meta.line_number}.", level: vocabkey.LevelSource,
			need: map[uuid.UUID]citationformat.Need{}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ln := needsAt(chainsOf(t, tt.text), tt.level)
			if !reflect.DeepEqual(ln.need, tt.need) {
				t.Errorf("need = %v, want %v", ln.need, tt.need)
			}
			if !reflect.DeepEqual(ln.order, tt.order) {
				t.Errorf("order = %v, want %v", ln.order, tt.order)
			}
			var page citationformat.Need
			for _, ch := range ln.builtinHeads[pageHead] {
				page = stronger(page, ch.Need)
			}
			if page != tt.page {
				t.Errorf("page need = %q, want %q", page, tt.page)
			}
		})
	}
	t.Run("built-in heads only at the source level", func(t *testing.T) {
		ln := needsAt(chainsOf(t, "{citation.page}"), vocabkey.LevelGraph)
		if ln.builtinHeads != nil {
			t.Errorf("builtinHeads = %v at graph", ln.builtinHeads)
		}
	})
}

func TestAnnotate(t *testing.T) {
	a := uuid.New()
	tok := "#" + a.String()
	field := metadatafields.Field{ID: a[:], Key: "line_number", Label: "Line", UnknownText: "n.l."}
	fields := map[string]metadatafields.Field{string(a[:]): field}
	graphChain := chainsOf(t, "{graph.meta."+tok+"|source.meta."+tok+"}.")
	head := fieldTarget(vocabkey.LevelGraph, a)
	row := func(text string, mark valuemark.Mark) map[string]Row {
		return map[string]Row{string(a[:]): {FieldID: a[:], ValueText: text, Mark: mark}}
	}
	y := 1890
	dated := datevalue.Value{Kind: datevalue.KindPoint, StartYear: &y}

	tests := []struct {
		name   string
		chains []citationformat.Requirement
		head   citationformat.Target
		values ownerValues
		want   Annotation
	}{
		{name: "the Source answers", chains: graphChain, head: head,
			values: ownerValues{level: vocabkey.LevelGraph, source: row("14", valuemark.Mark{})},
			want: Annotation{Need: citationformat.NeedNeeded, MetElsewhere: true,
				Alternatives: []Alternative{{Level: vocabkey.LevelSource, Field: &field}}}},
		{name: "the Source value is unknown", chains: graphChain, head: head,
			values: ownerValues{level: vocabkey.LevelGraph, source: row("", valuemark.Mark{Unknown: true})},
			want: Annotation{Need: citationformat.NeedNeeded, MetElsewhere: true,
				Alternatives: []Alternative{{Level: vocabkey.LevelSource, Field: &field}}}},
		{name: "nothing answers", chains: graphChain, head: head,
			values: ownerValues{level: vocabkey.LevelGraph},
			want: Annotation{Need: citationformat.NeedNeeded,
				Alternatives: []Alternative{{Level: vocabkey.LevelSource, Field: &field}}}},
		{name: "the head's own value does not answer for it", chains: graphChain, head: head,
			values: ownerValues{level: vocabkey.LevelGraph, own: row("9", valuemark.Mark{})},
			want: Annotation{Need: citationformat.NeedNeeded,
				Alternatives: []Alternative{{Level: vocabkey.LevelSource, Field: &field}}}},
		{name: "a built-in answers", chains: chainsOf(t, "{graph.meta."+tok+"|source.date}."), head: head,
			values: ownerValues{level: vocabkey.LevelGraph, date: citationformat.Value{Date: &dated}},
			want: Annotation{Need: citationformat.NeedNeeded, MetElsewhere: true,
				Alternatives: []Alternative{{Level: vocabkey.LevelSource, Builtin: "date"}}}},
		{name: "a one-option chain is not met", chains: chainsOf(t, "{graph.meta."+tok+"}."), head: head,
			values: ownerValues{level: vocabkey.LevelGraph, own: row("9", valuemark.Mark{})},
			want:   Annotation{Need: citationformat.NeedNeeded}},
		{name: "a used head carries no answer", chains: chainsOf(t, "[{graph.meta."+tok+"|source.meta."+tok+"}]"), head: head,
			values: ownerValues{level: vocabkey.LevelGraph},
			want:   Annotation{Need: citationformat.NeedUsed}},
		{name: "a head no format reads is none", chains: nil, head: head, values: ownerValues{level: vocabkey.LevelGraph}},
		{name: "a later option with no row is left out", chains: chainsOf(t, "{graph.meta."+tok+"|source.meta.#"+uuid.NewString()+"}."), head: head,
			values: ownerValues{level: vocabkey.LevelGraph},
			want:   Annotation{Need: citationformat.NeedNeeded}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tt.values.fields = fields
			ln := needsAt(tt.chains, tt.head.Level)
			if got := annotate(ln, tt.head, tt.values, fields); !reflect.DeepEqual(got, tt.want) {
				t.Errorf("annotation\n got %+v\nwant %+v", got, tt.want)
			}
		})
	}

	t.Run("the Source date head", func(t *testing.T) {
		chains := chainsOf(t, "{source.date:year}.")
		ln := needsAt(chains, vocabkey.LevelSource)
		got := annotate(ln, dateHead, ownerValues{level: vocabkey.LevelSource}, fields)
		if got.Need != citationformat.NeedNeeded || got.MetElsewhere {
			t.Errorf("undated = %+v", got)
		}
	})
}

func TestCitationValues(t *testing.T) {
	f := metadatafields.Field{UnknownText: "n.l."}
	got := CitationValue(Row{ValueText: "14", Mark: valuemark.Mark{Supplied: true}}, f)
	want := citationformat.Value{Text: "14", Mark: valuemark.Mark{Supplied: true}, UnknownText: "n.l."}
	if got != want {
		t.Errorf("CitationValue = %+v, want %+v", got, want)
	}
	y := 1890
	d := datevalue.Value{Kind: datevalue.KindPoint, StartYear: &y}
	date := sources.CitationDate(sources.Source{Date: &d, DateMark: valuemark.Mark{Supplied: true}})
	if date.Date != &d || date.Mark != (valuemark.Mark{Supplied: true}) || date.Text != "" {
		t.Errorf("CitationDate = %+v", date)
	}
	if got := sources.CitationDate(sources.Source{DateMark: valuemark.Mark{Unknown: true}}); got.Date != nil || !got.Mark.Unknown {
		t.Errorf("CitationDate of an unknown date = %+v", got)
	}
}
