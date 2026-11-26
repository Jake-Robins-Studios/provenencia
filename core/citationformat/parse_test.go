package citationformat_test

import (
	"strings"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
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
	{"field at a level", "{source.meta.page}", "full", []diag{{"meta_at_level", 1, 17}}},
	{"artifact level field", "{artifact.meta.x}", "full", []diag{{"meta_at_level", 1, 16}}},
	{"graph level field", "{graph.meta.x}", "full", []diag{{"meta_at_level", 1, 13}}},
	{"citation level field", "{citation.meta.x}", "full", []diag{{"meta_at_level", 1, 16}}},
	{"unknown level field", "{foo.meta.x}", "full", []diag{{"unknown_level", 1, 11}}},
	{"field no level", "{meta.page}", "full", nil},
	{"unclosed group", "p. [{citation.label}", "full", []diag{{"unclosed_group", 3, 4}}},
	{"stray close bracket", "{source.title}]", "full", []diag{{"stray_close_bracket", 14, 15}}},
	{"not in list form", "{graph.name}", "list", []diag{{"not_in_list_form", 1, 11}}},
	{"week", "{source.date:week}", "full", []diag{{"unknown_option", 13, 17}}},
	{"title year", "{source.title:year}", "full", []diag{{"unknown_option", 14, 18}}},
	{"meta option", "{meta.url:year}", "full", []diag{{"unknown_option", 10, 14}}},
	{"group without placeholder", "[, ]{source.title}", "full", []diag{{"group_without_placeholder", 0, 4}}},
	{"three in order", "{source.foo} and {citation.meta.x} and {parish.title}", "full", []diag{
		{"unknown_builtin", 1, 11}, {"meta_at_level", 18, 33}, {"unknown_level", 40, 52}}},
	{"too long", strings.Repeat("a", 8193), "full", []diag{{"too_long", 0, 8193}}},
	{"the parse limit is bytes", strings.Repeat("a", 8192), "full", nil},
	{"past the old limit", strings.Repeat("a", 4097), "full", nil},
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
	{"missing close before next placeholder", "{source.title, p. {citation.label}.", "full", []diag{{"unclosed_placeholder", 0, 1}}},
	{"bad character trailing space", "{source.title }", "full", []diag{{"bad_character", 13, 14}}},
	{"nine mixed", "[*[*[*[*[", "full", []diag{{"too_deep", 8, 9}}},
	{"title only", "{title}", "full", []diag{{"unknown_level", 1, 6}}},
	{"a retired page built-in", "{citation.page}", "full", []diag{{"unknown_builtin", 1, 14}}},
	{"level only", "{source}", "full", []diag{{"unknown_builtin", 1, 7}}},
	{"level dot", "{source.}", "full", []diag{{"unknown_builtin", 1, 8}}},
	{"meta in list", "{citation.meta.x}", "list", []diag{{"meta_at_level", 1, 16}}},
	{"field in list", "{meta.x}", "list", nil},
	{"meta without field", "{meta.}", "full", []diag{{"bad_field", 6, 6}}},
	{"meta bare", "{meta}", "full", []diag{{"bad_field", 5, 5}}},
	{"dotted key", "{meta.a.b}", "full", []diag{{"bad_field", 6, 9}}},
	{"key with space", "{meta.a b}", "full", []diag{{"bad_character", 7, 8}}},
	{"option on key", "{meta.A:B}", "full", []diag{{"unknown_option", 8, 9}}},
	{"year full", "{source.date:year:full}", "full", []diag{{"unknown_option", 13, 22}}},
	{"empty option after colon", "{source.title:}", "full", []diag{{"unknown_option", 14, 14}}},
	{"bad ids", "{meta.#not-a-uuid}", "full", []diag{{"bad_field", 6, 17}}},
	{"nil id", "{meta.#00000000-0000-0000-0000-000000000000}", "full", []diag{{"bad_field", 6, 43}}},
	{"upper id", "{meta.#0192F3A4-0000-7000-8000-000000000001}", "full", []diag{{"bad_field", 6, 43}}},
	{"nine groups", strings.Repeat("[", 9), "full", []diag{{"too_deep", 8, 9}}},
	{"eight groups", strings.Repeat("[{source.title}", 8) + strings.Repeat("]", 8), "full", nil},
	{"keys", "{meta.line_number}{meta.1880-census}{meta.île}{meta.Île}", "full", nil},
	{"id", "{meta.#0192f3a4-0000-7000-8000-000000000001}", "full", nil},
	{"escapes", `\{a\} \[b\] \*c\* \\`, "full", nil},
	{"chain of a field and a built-in", "{meta.short_title|source.title}", "full", nil},
	{"italic in group", "[*{source.title}*]", "full", nil},
	{"group in italic", "*a [{source.title}]*", "full", nil},
	{"pipe literal", "a | b {source.title}", "full", nil},
	{"list ok", "{meta.x}{source.date:year}{source.title}", "list", nil},
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
