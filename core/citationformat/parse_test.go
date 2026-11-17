package citationformat_test

import (
	"os"
	"strings"
	"testing"

	"github.com/mendahu/provenencia/core/citationformat"
)

type diag struct {
	code       citationformat.DiagnosticCode
	start, end int
}

// parseCases are shared with FuzzParse as seeds.
var parseCases = []struct {
	name string
	text string
	form citationformat.Form
	want []diag
}{
	{"unprefixed meta", "{meta.page}", "full", []diag{{"unprefixed_meta", 1, 10}}},
	{"unclosed group", "p. [{citation.page}", "full", []diag{{"unclosed_group", 3, 4}}},
	{"stray close bracket", "{source.title}]", "full", []diag{{"stray_close_bracket", 14, 15}}},
	{"not in list form", "{graph.meta.line_number}", "list", []diag{{"not_in_list_form", 1, 23}}},
	{"week", "{source.date:week}", "full", []diag{{"unknown_option", 13, 17}}},
	{"title year", "{source.title:year}", "full", []diag{{"unknown_option", 14, 18}}},
	{"meta option", "{source.meta.url:year}", "full", []diag{{"unknown_option", 17, 21}}},
	{"group without placeholder", "[, ]{source.title}", "full", []diag{{"group_without_placeholder", 0, 4}}},
	{"three in order", "{source.foo} and {citation.meta.x} and {parish.title}", "full", []diag{
		{"unknown_builtin", 1, 11}, {"meta_not_at_level", 18, 33}, {"unknown_level", 40, 52}}},
	{"too long", strings.Repeat("a", 4097), "full", []diag{{"too_long", 0, 4097}}},
	{"unknown form", "x", "nope", []diag{{"unknown_form", 0, 0}}},
	{"unclosed placeholder", "[{a", "full", []diag{{"unclosed_placeholder", 1, 2}}},
	{"stray close brace", "a}b", "full", []diag{{"stray_close_brace", 1, 2}}},
	{"unclosed italic across group", "*a [{source.title}* c]", "full", []diag{{"unclosed_italic", 0, 1}, {"unclosed_italic", 18, 19}}},
	{"bad escape", `\n`, "full", []diag{{"bad_escape", 0, 2}}},
	{"bad escape last", `a\`, "full", []diag{{"bad_escape", 1, 2}}},
	{"empty placeholder", "{}", "full", []diag{{"empty_option", 1, 1}}},
	{"empty chain option", "{source.title|}", "full", []diag{{"empty_option", 14, 14}}},
	{"space in option", "{source.title x}", "full", []diag{{"bad_character", 13, 14}}},
	{"double brace", "{{source.title}", "full", []diag{{"unclosed_placeholder", 0, 1}}},
	{"missing close before next placeholder", "{source.title, p. {citation.page}.", "full", []diag{{"unclosed_placeholder", 0, 1}}},
	{"bad character trailing space", "{source.title }", "full", []diag{{"bad_character", 13, 14}}},
	{"nine mixed", "[*[*[*[*[", "full", []diag{{"too_deep", 8, 9}}},
	{"title only", "{title}", "full", []diag{{"unknown_level", 1, 6}}},
	{"level only", "{source}", "full", []diag{{"unknown_builtin", 1, 7}}},
	{"level dot", "{source.}", "full", []diag{{"unknown_builtin", 1, 8}}},
	{"meta in list", "{citation.meta.x}", "list", []diag{{"meta_not_at_level", 1, 16}}},
	{"meta without field", "{source.meta.}", "full", []diag{{"bad_field", 13, 13}}},
	{"meta bare", "{source.meta}", "full", []diag{{"bad_field", 12, 12}}},
	{"dotted key", "{source.meta.a.b}", "full", []diag{{"bad_field", 13, 16}}},
	{"key with space", "{source.meta.a b}", "full", []diag{{"bad_character", 14, 15}}},
	{"option on key", "{source.meta.A:B}", "full", []diag{{"unknown_option", 15, 16}}},
	{"year full", "{source.date:year:full}", "full", []diag{{"unknown_option", 13, 22}}},
	{"empty option after colon", "{source.title:}", "full", []diag{{"unknown_option", 14, 14}}},
	{"bad ids", "{source.meta.#not-a-uuid}", "full", []diag{{"bad_field", 13, 24}}},
	{"nil id", "{source.meta.#00000000-0000-0000-0000-000000000000}", "full", []diag{{"bad_field", 13, 50}}},
	{"upper id", "{source.meta.#0192F3A4-0000-7000-8000-000000000001}", "full", []diag{{"bad_field", 13, 50}}},
	{"nine groups", strings.Repeat("[", 9), "full", []diag{{"too_deep", 8, 9}}},
	{"eight groups", strings.Repeat("[{source.title}", 8) + strings.Repeat("]", 8), "full", nil},
	{"keys", "{source.meta.line_number}{source.meta.1880-census}{source.meta.île}{source.meta.Île}", "full", nil},
	{"id", "{source.meta.#0192f3a4-0000-7000-8000-000000000001}", "full", nil},
	{"escapes", `\{a\} \[b\] \*c\* \\`, "full", nil},
	{"chain", "{graph.meta.line_number|source.meta.line_number}", "full", nil},
	{"italic in group", "[*{source.title}*]", "full", nil},
	{"group in italic", "*a [{source.title}]*", "full", nil},
	{"pipe literal", "a | b {source.title}", "full", nil},
	{"list ok", "{source.meta.x}{source.date:year}{source.title}", "list", nil},
}

func TestParse(t *testing.T) {
	for _, tt := range parseCases {
		t.Run(tt.name, func(t *testing.T) {
			tpl, diags := citationformat.Parse(tt.text, tt.form)
			var got []diag
			for _, d := range diags {
				got = append(got, diag{d.Code, d.Span.Start, d.Span.End})
			}
			if len(got) != len(tt.want) {
				t.Fatalf("diagnostics = %v, want %v", got, tt.want)
			}
			for i := range got {
				if got[i] != tt.want[i] {
					t.Fatalf("diagnostics = %v, want %v", got, tt.want)
				}
			}
			if (tpl != nil) != (len(tt.want) == 0) {
				t.Fatalf("template = %v with %d diagnostics", tpl, len(got))
			}
			if tpl != nil && (tpl.Text() != tt.text || tpl.Form() != tt.form) {
				t.Fatalf("Text/Form = %q/%q", tpl.Text(), tpl.Form())
			}
		})
	}
}

func TestParseNilTemplate(t *testing.T) {
	var tpl *citationformat.Template
	if tpl.Text() != "" || tpl.Form() != "" || tpl.Fields() != nil {
		t.Fatal("nil template is not empty")
	}
}

type seedFormat struct {
	form citationformat.Form
	text string
}

// seedFormats reads the seed corpus, the one reader of it.
func seedFormats(tb testing.TB) []seedFormat {
	tb.Helper()
	raw, err := os.ReadFile("testdata/seed-formats.txt")
	if err != nil {
		tb.Fatal(err)
	}
	var out []seedFormat
	for i, line := range strings.Split(strings.TrimRight(string(raw), "\n"), "\n") {
		form, text, ok := strings.Cut(line, "\t")
		if !ok {
			tb.Fatalf("line %d has no tab", i+1)
		}
		out = append(out, seedFormat{citationformat.Form(form), text})
	}
	return out
}

func TestSeedFormatsParse(t *testing.T) {
	seeds := seedFormats(t)
	if len(seeds) != 66 {
		t.Fatalf("seed has %d formats, want 66", len(seeds))
	}
	for i, s := range seeds {
		if _, diags := citationformat.Parse(s.text, s.form); len(diags) > 0 {
			t.Errorf("line %d (%s): %v", i+1, s.form, diags)
		}
	}
}
