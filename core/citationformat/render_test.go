package citationformat_test

import (
	"reflect"
	"strings"
	"testing"
	"unicode/utf8"

	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue/datevaluetest"
	"github.com/Jake-Robins-Studios/provenencia/core/valuemark"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

type values map[citationformat.Target]citationformat.Value

func (v values) Resolve(t citationformat.Target) citationformat.Value { return v[t] }

func meta(l vocabkey.Level, key string) citationformat.Target {
	return citationformat.Target{Level: l, Field: citationformat.FieldRef{Key: key}}
}

func builtin(l vocabkey.Level, name string) citationformat.Target {
	return citationformat.Target{Level: l, Builtin: name}
}

func text(s string) citationformat.Value { return citationformat.Value{Text: s} }

func date(d *datevalue.Value) citationformat.Value { return citationformat.Value{Date: d} }

func mustParse(t *testing.T, s string, f citationformat.Form) *citationformat.Template {
	t.Helper()
	tpl, diags := citationformat.Parse(s, f)
	if len(diags) > 0 {
		t.Fatalf("Parse(%q) = %v", s, diags)
	}
	return tpl
}

// The census formats of the seed corpus, written out so the render
// and requirement tests do not read the seed corpus.
const (
	censusFull  = `{source.date:year} [{source.meta.creator} ]census, {source.meta.jurisdiction}[, {source.meta.schedule}][, ED {source.meta.enumeration_district}][, piece {source.meta.piece}][, fol. {graph.meta.folio|source.meta.folio}][, p. {citation.page}][, schedule {graph.meta.schedule_number|source.meta.schedule_number}][, dwelling {graph.meta.dwelling_number|source.meta.dwelling_number}][, family {graph.meta.family_number|source.meta.family_number}][, line {graph.meta.line_number|source.meta.line_number}][, {graph.meta.item|source.meta.item}][; {artifact.meta.format}, *{artifact.meta.provider}*][ ({artifact.meta.url}[ : accessed {artifact.meta.accessed_date}])][; citing {artifact.meta.citing}].`
	censusShort = `{source.date:year} [{source.meta.creator} ]census, {source.meta.jurisdiction}[, ED {source.meta.enumeration_district}][, fol. {graph.meta.folio|source.meta.folio}][, p. {citation.page}][, dwell. {graph.meta.dwelling_number|source.meta.dwelling_number}][, fam. {graph.meta.family_number|source.meta.family_number}][, {graph.meta.item|source.meta.item}].`
)

func censusValues() values {
	src, art, gr, cit := vocabkey.LevelSource, vocabkey.LevelArtifact, vocabkey.LevelGraph, vocabkey.LevelCitation
	return values{
		builtin(src, "date"):              date(datevaluetest.YMD(1880, 0, 0)),
		meta(src, "creator"):              text("U.S."),
		meta(src, "jurisdiction"):         text("Ottawa County, Kansas"),
		meta(src, "schedule"):             text("population schedule"),
		meta(src, "enumeration_district"): text("236"),
		meta(gr, "dwelling_number"):       text("112"),
		meta(gr, "family_number"):         text("118"),
		meta(gr, "item"):                  text("Ada Robins"),
		builtin(cit, "page"):              text("14"),
		meta(art, "format"):               text("digital image"),
		meta(art, "provider"):             text("Ancestry"),
		meta(art, "url"):                  text("https://www.ancestry.com"),
		meta(art, "accessed_date"):        text("12 March 2025"),
		meta(art, "citing"):               text("NARA microfilm publication T9, roll 393"),
	}
}

const censusPlain = "1880 U.S. census, Ottawa County, Kansas, population schedule, ED 236, p. 14, dwelling 112, family 118, Ada Robins; digital image, Ancestry (https://www.ancestry.com : accessed 12 March 2025); citing NARA microfilm publication T9, roll 393."

func TestRender(t *testing.T) {
	src, gr := vocabkey.LevelSource, vocabkey.LevelGraph
	t.Run("census_full", func(t *testing.T) {
		got := citationformat.Render(mustParse(t, censusFull, citationformat.FormFull), censusValues())
		if got.Plain() != censusPlain {
			t.Fatalf("plain = %q", got.Plain())
		}
		var italic []string
		for _, r := range got.Runs {
			if r.Italic {
				italic = append(italic, r.Text)
			}
		}
		if !reflect.DeepEqual(italic, []string{"Ancestry"}) {
			t.Fatalf("italic runs = %v", italic)
		}
	})
	t.Run("census_item_on_source", func(t *testing.T) {
		v := censusValues()
		delete(v, meta(gr, "item"))
		v[meta(src, "item")] = text("Ada Robins")
		if got := citationformat.Render(mustParse(t, censusFull, citationformat.FormFull), v).Plain(); got != censusPlain {
			t.Fatalf("plain = %q", got)
		}
	})
	tests := []struct {
		name   string
		format string
		v      values
		want   string
	}{
		{"empty group drops", "[, ED {source.meta.enumeration_district}]", values{}, ""},
		{"nested group drops alone", "[ ({artifact.meta.url}[ : accessed {artifact.meta.accessed_date}])]",
			values{meta(vocabkey.LevelArtifact, "url"): text("https://example.org/1")}, " (https://example.org/1)"},
		{"value is not markup", "{source.title}", values{builtin(src, "title"): text("*Kansas* [draft]")}, "*Kansas* [draft]"},
		{"escapes", `\{a\} \[b\] \*c\* \\`, values{}, `{a} [b] *c* \`},
		{"chain falls to source", "{graph.meta.line_number|source.meta.line_number}", values{meta(src, "line_number"): text("12")}, "12"},
		{"chain prefers graph", "{graph.meta.line_number|source.meta.line_number}",
			values{meta(gr, "line_number"): text("3"), meta(src, "line_number"): text("12")}, "3"},
		{"specials print as given", "{source.title}", values{builtin(src, "title"): text(`a*b[x]{y}\`)}, `a*b[x]{y}\`},
		{"spaces kept", "<{source.title}>", values{builtin(src, "title"): text("  spaced  ")}, "<  spaced  >"},
		{"whitespace is unanswered", "[x{source.title}]", values{builtin(src, "title"): text("  ")}, ""},
		{"unknown target", "a{source.title}b", values{}, "ab"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := citationformat.Render(mustParse(t, tt.format, citationformat.FormFull), tt.v).Plain(); got != tt.want {
				t.Fatalf("got %q want %q", got, tt.want)
			}
		})
	}
	t.Run("nil template", func(t *testing.T) {
		if got := citationformat.Render(nil, values{}); len(got.Runs) != 0 {
			t.Fatalf("runs = %v", got.Runs)
		}
	})
	t.Run("nil resolver", func(t *testing.T) {
		if got := citationformat.Render(mustParse(t, "a{source.title}b", citationformat.FormFull), nil).Plain(); got != "ab" {
			t.Fatalf("got %q", got)
		}
	})
	t.Run("over cap", func(t *testing.T) {
		big := strings.Repeat("é", 1<<19)
		tpl := mustParse(t, strings.Repeat("{source.title}", 250), citationformat.FormFull)
		got := citationformat.Render(tpl, values{builtin(src, "title"): text(big)}).Plain()
		if len(got) > citationformat.MaxRenderedBytes || !utf8.ValidString(got) || len(got) < citationformat.MaxRenderedBytes-1 {
			t.Fatalf("rendered %d bytes, valid %v", len(got), utf8.ValidString(got))
		}
	})
	t.Run("over cap in groups", func(t *testing.T) {
		tpl := mustParse(t, strings.Repeat("[{source.title}", 8)+strings.Repeat("]", 8), citationformat.FormFull)
		got := citationformat.Render(tpl, values{builtin(src, "title"): text(strings.Repeat("a", 1<<20))}).Plain()
		if len(got) != citationformat.MaxRenderedBytes {
			t.Fatalf("rendered %d bytes", len(got))
		}
	})
	t.Run("runs merge", func(t *testing.T) {
		got := citationformat.Render(mustParse(t, "a*b*{source.title}", citationformat.FormFull), values{builtin(src, "title"): text("c")})
		want := []citationformat.Run{{Text: "a"}, {Text: "b", Italic: true}, {Text: "c"}}
		if !reflect.DeepEqual(got.Runs, want) {
			t.Fatalf("runs = %v", got.Runs)
		}
	})
}

func TestRenderMarks(t *testing.T) {
	src, gr, art, cit := vocabkey.LevelSource, vocabkey.LevelGraph, vocabkey.LevelArtifact, vocabkey.LevelCitation
	unknown := valuemark.Mark{Unknown: true}
	supplied := valuemark.Mark{Supplied: true}
	tests := []struct {
		name   string
		format string
		form   citationformat.Form
		v      values
		want   string
	}{
		{"unknown text", "{source.meta.publication_place}: {source.meta.publisher}", "full", values{
			meta(src, "publication_place"): {Mark: unknown, UnknownText: "n.p."},
			meta(src, "publisher"):         {Mark: unknown, UnknownText: "n.p."}}, "n.p.: n.p."},
		{"supplied text", "{source.meta.publication_place}", "full", values{meta(src, "publication_place"): {Text: "Topeka", Mark: supplied}}, "[Topeka]"},
		{"supplied date", "{source.date}", "full", values{builtin(src, "date"): {Date: datevaluetest.About(1880, 0, 0), Mark: supplied}}, "[ca. 1880]"},
		{"unknown date", "{source.date}", "full", values{builtin(src, "date"): {Mark: unknown}}, "n.d."},
		{"unknown page", "{citation.page}", "full", values{builtin(cit, "page"): {Mark: unknown}}, "unpaginated"},
		{"unknown without text drops group", "x[, {source.meta.edition}]", "full", values{meta(src, "edition"): {Mark: unknown}}, "x"},
		{"graph unknown wins", "{graph.meta.line_number|source.meta.line_number}", "full", values{
			meta(gr, "line_number"): {Mark: unknown}, meta(src, "line_number"): text("12")}, ""},
		{"short form date", "{source.date}", "short", values{builtin(src, "date"): date(datevaluetest.YMD(1830, 3, 3))}, "3 Mar. 1830"},
		{"long form date", "{source.date}", "full", values{builtin(src, "date"): date(datevaluetest.YMD(1830, 3, 3))}, "3 March 1830"},
		{"year keeps ca.", "{source.date:year}", "full", values{builtin(src, "date"): date(datevaluetest.About(1880, 3, 0))}, "ca. 1880"},
		{"year ignores short", "{source.date:year}", "short", values{builtin(src, "date"): date(datevaluetest.YMD(1830, 3, 3))}, "1830"},
		{"full is bare", "{source.date:full}", "short", values{builtin(src, "date"): date(datevaluetest.YMD(1830, 3, 3))}, "3 Mar. 1830"},
		{"both marks send unknown", "{source.meta.x}", "full", values{meta(src, "x"): {Text: "t", Mark: valuemark.Mark{Unknown: true, Supplied: true}, UnknownText: "u"}}, "u"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := citationformat.Render(mustParse(t, tt.format, tt.form), tt.v).Plain(); got != tt.want {
				t.Fatalf("got %q want %q", got, tt.want)
			}
		})
	}
	t.Run("supplied italic", func(t *testing.T) {
		got := citationformat.Render(mustParse(t, "*{artifact.meta.provider}*", citationformat.FormFull),
			values{meta(art, "provider"): {Text: "Ancestry", Mark: supplied}})
		want := []citationformat.Run{{Text: "[Ancestry]", Italic: true}}
		if !reflect.DeepEqual(got.Runs, want) {
			t.Fatalf("runs = %v", got.Runs)
		}
	})
}
