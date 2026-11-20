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
				page = page.Max(ch.Need)
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
	// values builds the resolver of a graph board: the graph's own rows, the
	// Source's rows and the Source's date.
	values := func(own, source map[string]Row, date *citationformat.Value) CitationValues {
		v := CitationValues{
			Rows:   map[vocabkey.Level]map[string]Row{vocabkey.LevelGraph: own, vocabkey.LevelSource: source},
			Fields: fields,
		}
		if date != nil {
			v.Builtins = map[citationformat.Target]citationformat.Value{dateHead: *date}
		}
		return v
	}

	tests := []struct {
		name   string
		chains []citationformat.Requirement
		head   citationformat.Target
		values CitationValues
		want   Annotation
	}{
		{name: "the Source answers", chains: graphChain, head: head,
			values: values(nil, row("14", valuemark.Mark{}), nil),
			want: Annotation{Need: citationformat.NeedNeeded, MetElsewhere: true,
				Alternatives: []Alternative{{Level: vocabkey.LevelSource, Field: &field}}}},
		{name: "the Source value is unknown", chains: graphChain, head: head,
			values: values(nil, row("", valuemark.Mark{Unknown: true}), nil),
			want: Annotation{Need: citationformat.NeedNeeded, MetElsewhere: true,
				Alternatives: []Alternative{{Level: vocabkey.LevelSource, Field: &field}}}},
		{name: "nothing answers", chains: graphChain, head: head,
			values: values(nil, nil, nil),
			want: Annotation{Need: citationformat.NeedNeeded,
				Alternatives: []Alternative{{Level: vocabkey.LevelSource, Field: &field}}}},
		{name: "the head's own value does not answer for it", chains: graphChain, head: head,
			values: values(row("9", valuemark.Mark{}), nil, nil),
			want: Annotation{Need: citationformat.NeedNeeded,
				Alternatives: []Alternative{{Level: vocabkey.LevelSource, Field: &field}}}},
		{name: "a built-in answers", chains: chainsOf(t, "{graph.meta."+tok+"|source.date}."), head: head,
			values: values(nil, nil, &citationformat.Value{Date: &dated}),
			want: Annotation{Need: citationformat.NeedNeeded, MetElsewhere: true,
				Alternatives: []Alternative{{Level: vocabkey.LevelSource, Builtin: "date"}}}},
		{name: "a one-option chain is not met", chains: chainsOf(t, "{graph.meta."+tok+"}."), head: head,
			values: values(row("9", valuemark.Mark{}), nil, nil),
			want:   Annotation{Need: citationformat.NeedNeeded}},
		{name: "a used head carries no answer", chains: chainsOf(t, "[{graph.meta."+tok+"|source.meta."+tok+"}]"), head: head,
			values: values(nil, nil, nil),
			want:   Annotation{Need: citationformat.NeedUsed}},
		{name: "a head no format reads is none", chains: nil, head: head, values: values(nil, nil, nil)},
		{name: "a later option with no row is left out", chains: chainsOf(t, "{graph.meta."+tok+"|source.meta.#"+uuid.NewString()+"}."), head: head,
			values: values(nil, nil, nil),
			want:   Annotation{Need: citationformat.NeedNeeded}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ln := needsAt(tt.chains, tt.head.Level)
			if got := annotate(ln, tt.head, tt.values, fields); !reflect.DeepEqual(got, tt.want) {
				t.Errorf("annotation\n got %+v\nwant %+v", got, tt.want)
			}
		})
	}

	t.Run("the Source date head", func(t *testing.T) {
		chains := chainsOf(t, "{source.date:year}.")
		ln := needsAt(chains, vocabkey.LevelSource)
		got := annotate(ln, dateHead, CitationValues{Rows: map[vocabkey.Level]map[string]Row{vocabkey.LevelSource: nil}, Fields: fields}, fields)
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

func TestCitationValuesResolve(t *testing.T) {
	a := uuid.New()
	loaded := metadatafields.Field{ID: a[:], Key: "line_number", UnknownText: "n.l."}
	b := uuid.New()
	y := 1890
	dated := citationformat.Value{Date: &datevalue.Value{Kind: datevalue.KindPoint, StartYear: &y}}
	rows := func(text string) map[string]Row {
		return map[string]Row{string(a[:]): {FieldID: a[:], ValueText: text, Mark: valuemark.Mark{Supplied: true}}}
	}
	values := CitationValues{
		Rows: map[vocabkey.Level]map[string]Row{
			vocabkey.LevelGraph:  rows("9"),
			vocabkey.LevelSource: {string(b[:]): {FieldID: b[:], ValueText: "x"}},
		},
		Fields:   map[string]metadatafields.Field{string(a[:]): loaded},
		Builtins: map[citationformat.Target]citationformat.Value{dateHead: dated},
	}
	tests := []struct {
		name   string
		target citationformat.Target
		want   citationformat.Value
	}{
		{"a field at a level with a row", fieldTarget(vocabkey.LevelGraph, a),
			citationformat.Value{Text: "9", Mark: valuemark.Mark{Supplied: true}, UnknownText: "n.l."}},
		{"a field with no row at that level", fieldTarget(vocabkey.LevelArtifact, a), citationformat.Value{}},
		{"a field whose row did not load answers with no unknown text", fieldTarget(vocabkey.LevelSource, b),
			citationformat.Value{Text: "x"}},
		{"a field named by key", citationformat.Target{Level: vocabkey.LevelGraph, Field: citationformat.FieldRef{Key: "line_number"}}, citationformat.Value{}},
		{"a built-in that is set", dateHead, dated},
		{"a built-in that is not", pageHead, citationformat.Value{}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := values.Resolve(tt.target); got != tt.want {
				t.Errorf("Resolve = %+v, want %+v", got, tt.want)
			}
		})
	}

	t.Run("a Source-level owner answers source fields", func(t *testing.T) {
		v := CitationValues{
			Rows:   map[vocabkey.Level]map[string]Row{vocabkey.LevelSource: rows("7")},
			Fields: map[string]metadatafields.Field{string(a[:]): loaded},
		}
		if got := v.Resolve(fieldTarget(vocabkey.LevelSource, a)); got.Text != "7" {
			t.Errorf("Resolve = %+v", got)
		}
	})
}

func TestAppendOptions(t *testing.T) {
	a, b := uuid.New(), uuid.New()
	field := metadatafields.Field{ID: a[:], Key: "line_number"}
	fields := map[string]metadatafields.Field{string(a[:]): field}
	date := citationformat.Target{Level: vocabkey.LevelSource, Builtin: "date"}
	targets := []citationformat.Target{
		date,
		fieldTarget(vocabkey.LevelGraph, a),
		fieldTarget(vocabkey.LevelSource, b),
		{Level: vocabkey.LevelGraph, Field: citationformat.FieldRef{Key: "line_number"}},
		pageHead,
	}
	seen := map[citationformat.Target]bool{pageHead: true}
	got := AppendOptions(nil, seen, targets, fields)
	want := []Alternative{
		{Level: vocabkey.LevelSource, Builtin: "date"},
		{Level: vocabkey.LevelGraph, Field: &field},
	}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("AppendOptions\n got %+v\nwant %+v", got, want)
	}
	if !seen[date] || !seen[fieldTarget(vocabkey.LevelGraph, a)] {
		t.Errorf("seen = %v, want every target marked", seen)
	}
	if again := AppendOptions(nil, seen, targets, fields); len(again) != 0 {
		t.Errorf("second call = %+v, want none: every target was seen", again)
	}
}
