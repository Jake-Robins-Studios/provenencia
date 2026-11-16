package citationformat_test

import (
	"os"
	"strings"
	"testing"

	"github.com/mendahu/provenencia/core/citationformat"
	"github.com/mendahu/provenencia/core/datevalue/datevaluetest"
	"github.com/mendahu/provenencia/core/slug"
)

type answerAll struct{}

func (answerAll) Resolve(citationformat.Target) citationformat.Value {
	return citationformat.Value{Text: "v*[{\\", Date: datevaluetest.YMD(1880, 3, 3)}
}

// FuzzParse feeds arbitrary text and forms to Parse: it must not panic, a
// template comes back exactly when there are no diagnostics, every span lies in
// the text, and a template renders and rewrites.
func FuzzParse(f *testing.F) {
	for _, c := range parseCases {
		f.Add(c.text, string(c.form))
	}
	if raw, err := os.ReadFile("testdata/seed-formats.txt"); err == nil {
		for _, line := range strings.Split(strings.TrimRight(string(raw), "\n"), "\n") {
			form, text, _ := strings.Cut(line, "\t")
			f.Add(text, form)
		}
	}
	f.Fuzz(func(t *testing.T, text, form string) {
		tpl, diags := citationformat.Parse(text, citationformat.Form(form))
		if (tpl == nil) != (len(diags) > 0) {
			t.Fatalf("template %v with %d diagnostics", tpl != nil, len(diags))
		}
		for _, d := range diags {
			if d.Span.Start < 0 || d.Span.Start > d.Span.End || d.Span.End > len(text) {
				t.Fatalf("span %v outside [0,%d]", d.Span, len(text))
			}
		}
		if tpl != nil {
			citationformat.Render(tpl, answerAll{})
			got, err := tpl.RewriteFields(func(f citationformat.FieldRef) (citationformat.FieldRef, error) { return f, nil })
			if err != nil || got != text {
				t.Fatalf("identity rewrite = %q, %v; want %q", got, err, text)
			}
		}
		if key := slug.Kebab(text); key != "" && len(key) <= 4000 {
			if _, diags := citationformat.Parse("{source.meta."+key+"}", citationformat.FormFull); len(diags) > 0 {
				t.Fatalf("key %q: %v", key, diags)
			}
		}
	})
}
