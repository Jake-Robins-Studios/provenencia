package citationformat_test

import (
	"strings"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue/datevaluetest"
	"github.com/Jake-Robins-Studios/provenencia/core/slug"
)

type answerAll struct{}

// bigValue is long enough that a short format repeating a placeholder reaches
// MaxRenderedBytes.
var bigValue = strings.Repeat("v*[{\\", 1<<15)

func (answerAll) Resolve(citationformat.Target) citationformat.Value {
	return citationformat.Value{Text: bigValue, Date: datevaluetest.YMD(1880, 3, 3)}
}

// FuzzParse feeds arbitrary text and forms to Parse: it must not panic, a
// template comes back exactly when there are no diagnostics, every span lies in
// the text, and a template renders and rewrites.
func FuzzParse(f *testing.F) {
	for _, c := range parseCases {
		f.Add(c.text, string(c.form))
	}
	f.Add(censusFull, string(citationformat.FormFull))
	f.Add(censusShort, string(citationformat.FormShort))
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
			if got := citationformat.Render(tpl, answerAll{}).Plain(); len(got) > citationformat.MaxRenderedBytes {
				t.Fatalf("rendered %d bytes", len(got))
			}
			got, err := tpl.RewriteFields(func(f citationformat.FieldRef) (citationformat.FieldRef, error) { return f, nil })
			if err != nil || got != text {
				t.Fatalf("identity rewrite = %q, %v; want %q", got, err, text)
			}
			// Whatever key is offered, the result parses or the rewrite refuses.
			got, err = tpl.RewriteFields(func(citationformat.FieldRef) (citationformat.FieldRef, error) {
				return citationformat.FieldRef{Key: form}, nil
			})
			if err == nil {
				if _, diags := citationformat.Parse(got, tpl.Form()); len(diags) > 0 {
					t.Fatalf("rewrite with key %q = %q: %v", form, got, diags)
				}
			}
		}
		if key := slug.Kebab(text); key != "" && len(key) <= 4000 {
			if _, diags := citationformat.Parse("{source.meta."+key+"}", citationformat.FormFull); len(diags) > 0 {
				t.Fatalf("key %q: %v", key, diags)
			}
		}
	})
}
