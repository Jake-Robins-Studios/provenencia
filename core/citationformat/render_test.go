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

func meta(key string) citationformat.Target {
	return citationformat.Target{Field: citationformat.FieldRef{Key: key}}
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

// A census format written out for the engine tests.
const (
	censusFull  = `{source.date:year} [{meta.creator} ]census, {meta.jurisdiction}[, {meta.schedule}][, ED {meta.enumeration_district}][, piece {meta.piece}][, fol. {meta.folio}][, p. {citation.page}][, schedule {meta.schedule_number}][, dwelling {meta.dwelling_number}][, family {meta.family_number}][, line {meta.line_number}][, {meta.item}][; {meta.format}, *{meta.provider}*][ ({meta.url}[ : accessed {meta.accessed_date}])][; citing {meta.citing}].`
	censusShort = `{source.date:year} [{meta.creator} ]census, {meta.jurisdiction}[, ED {meta.enumeration_district}][, fol. {meta.folio}][, p. {citation.page}][, dwell. {meta.dwelling_number}][, fam. {meta.family_number}][, {meta.item}].`
)

func censusValues() values {
	src, cit := vocabkey.LevelSource, vocabkey.LevelCitation
	return values{
		builtin(src, "date"):         date(datevaluetest.YMD(1880, 0, 0)),
		meta("creator"):              text("U.S."),
		meta("jurisdiction"):         text("Ottawa County, Kansas"),
		meta("schedule"):             text("population schedule"),
		meta("enumeration_district"): text("236"),
		meta("dwelling_number"):      text("112"),
		meta("family_number"):        text("118"),
		meta("item"):                 text("Ada Robins"),
		builtin(cit, "page"):         text("14"),
		meta("format"):               text("digital image"),
		meta("provider"):             text("Ancestry"),
		meta("url"):                  text("https://www.ancestry.com"),
		meta("accessed_date"):        text("12 March 2025"),
		meta("citing"):               text("NARA microfilm publication T9, roll 393"),
	}
}

const censusPlain = "1880 U.S. census, Ottawa County, Kansas, population schedule, ED 236, p. 14, dwelling 112, family 118, Ada Robins; digital image, Ancestry (https://www.ancestry.com : accessed 12 March 2025); citing NARA microfilm publication T9, roll 393."

func TestRender(t *testing.T) {
	src := vocabkey.LevelSource
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
	tests := []struct {
		name   string
		format string
		v      values
		want   string
	}{
		{"empty group drops", "[, ED {meta.enumeration_district}]", values{}, ""},
		{"nested group drops alone", "[ ({meta.url}[ : accessed {meta.accessed_date}])]",
			values{meta("url"): text("https://example.org/1")}, " (https://example.org/1)"},
		{"value is not markup", "{source.title}", values{builtin(src, "title"): text("*Kansas* [draft]")}, "*Kansas* [draft]"},
		{"escapes", `\{a\} \[b\] \*c\* \\`, values{}, `{a} [b] *c* \`},
		{"chain falls to built-in", "{meta.short_title|source.title}", values{builtin(src, "title"): text("Kansas")}, "Kansas"},
		{"chain prefers field", "{meta.short_title|source.title}",
			values{meta("short_title"): text("KS"), builtin(src, "title"): text("Kansas")}, "KS"},
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
	t.Run("chain keeps an option that differs", func(t *testing.T) {
		got := citationformat.Render(mustParse(t, "{source.date:year|source.date}", citationformat.FormFull),
			values{builtin(src, "date"): date(datevaluetest.YMD(0, 3, 5))}).Plain()
		if got != "5 March" {
			t.Fatalf("plain = %q", got)
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
	src, cit := vocabkey.LevelSource, vocabkey.LevelCitation
	unknown := valuemark.Mark{Unknown: true}
	supplied := valuemark.Mark{Supplied: true}
	tests := []struct {
		name   string
		format string
		form   citationformat.Form
		v      values
		want   string
	}{
		{"unknown text", "{meta.publication_place}: {meta.publisher}", "full", values{
			meta("publication_place"): {Mark: unknown, UnknownText: "n.p."},
			meta("publisher"):         {Mark: unknown, UnknownText: "n.p."}}, "n.p.: n.p."},
		{"supplied text", "{meta.publication_place}", "full", values{meta("publication_place"): {Text: "Topeka", Mark: supplied}}, "[Topeka]"},
		{"supplied date", "{source.date}", "full", values{builtin(src, "date"): {Date: datevaluetest.About(1880, 0, 0), Mark: supplied}}, "[ca. 1880]"},
		{"unknown date", "{source.date}", "full", values{builtin(src, "date"): {Mark: unknown}}, "n.d."},
		{"unknown page", "{citation.page}", "full", values{builtin(cit, "page"): {Mark: unknown}}, "unpaginated"},
		{"unknown without text drops group", "x[, {meta.edition}]", "full", values{meta("edition"): {Mark: unknown}}, "x"},
		{"unknown field wins", "{meta.short_title|source.title}", "full", values{
			meta("short_title"): {Mark: unknown}, builtin(src, "title"): text("Kansas")}, ""},
		{"short form date", "{source.date}", "short", values{builtin(src, "date"): date(datevaluetest.YMD(1830, 3, 3))}, "3 Mar. 1830"},
		{"long form date", "{source.date}", "full", values{builtin(src, "date"): date(datevaluetest.YMD(1830, 3, 3))}, "3 March 1830"},
		{"year keeps ca.", "{source.date:year}", "full", values{builtin(src, "date"): date(datevaluetest.About(1880, 3, 0))}, "ca. 1880"},
		{"year ignores short", "{source.date:year}", "short", values{builtin(src, "date"): date(datevaluetest.YMD(1830, 3, 3))}, "1830"},
		{"full is bare", "{source.date:full}", "short", values{builtin(src, "date"): date(datevaluetest.YMD(1830, 3, 3))}, "3 Mar. 1830"},
		{"both marks send unknown", "{meta.x}", "full", values{meta("x"): {Text: "t", Mark: valuemark.Mark{Unknown: true, Supplied: true}, UnknownText: "u"}}, "u"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := citationformat.Render(mustParse(t, tt.format, tt.form), tt.v).Plain(); got != tt.want {
				t.Fatalf("got %q want %q", got, tt.want)
			}
		})
	}
	t.Run("supplied italic", func(t *testing.T) {
		got := citationformat.Render(mustParse(t, "*{meta.provider}*", citationformat.FormFull),
			values{meta("provider"): {Text: "Ancestry", Mark: supplied}})
		want := []citationformat.Run{{Text: "[Ancestry]", Italic: true}}
		if !reflect.DeepEqual(got.Runs, want) {
			t.Fatalf("runs = %v", got.Runs)
		}
	})
}

func TestDisplay(t *testing.T) {
	supplied := valuemark.Mark{Supplied: true}
	unknown := valuemark.Mark{Unknown: true}
	tests := []struct {
		name string
		v    citationformat.Value
		want string
	}{
		{"text", citationformat.Value{Text: "Ancestry"}, "Ancestry"},
		{"supplied", citationformat.Value{Text: "Calder County", Mark: supplied}, "[Calder County]"},
		{"unknown with unknown text", citationformat.Value{Mark: unknown, UnknownText: "n.p."}, "n.p."},
		{"unknown with none", citationformat.Value{Mark: unknown}, ""},
		{"only space", citationformat.Value{Text: "  "}, ""},
		{"supplied date", citationformat.Value{Date: datevaluetest.About(1880, 0, 0), Mark: supplied}, "[ca. 1880]"},
		{"date", citationformat.Value{Date: datevaluetest.YMD(1830, 3, 3)}, "3 March 1830"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := citationformat.Display(tt.v); got != tt.want {
				t.Fatalf("Display = %q, want %q", got, tt.want)
			}
		})
	}
	t.Run("long text truncates", func(t *testing.T) {
		got := citationformat.Display(citationformat.Value{Text: strings.Repeat("a", citationformat.MaxRenderedBytes+10)})
		if len(got) > citationformat.MaxRenderedBytes {
			t.Fatalf("len = %d", len(got))
		}
	})
}
