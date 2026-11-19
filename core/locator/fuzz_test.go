package locator

import (
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/valuemark"
)

// FuzzValidate feeds arbitrary documents to the locator parser, which reads
// locator_json the app may not have written: nothing panics, the page's mark
// read by Page always passes valuemark.Validate against its label, and a
// document Validate accepts reads with the mark it was written with.
func FuzzValidate(f *testing.F) {
	for _, doc := range []string{
		`{"version":1,"selectors":[{"type":"page","page_unknown":true}]}`,
		`{"version":1,"selectors":[{"type":"artifact"},{"type":"page","artifact_page":37,"page_label":" 23 ","page_supplied":true}]}`,
		`{"version":1,"selectors":[{"type":"page","page_label":"23","page_unknown":true}]}`,
		`{"version":1,"selectors":[{"type":"page","page_unknown":true,"page_supplied":true}]}`,
		`{"version":1,"selectors":[{"type":"page","page_label":"23","page_unknown":true,"page_supplied":true}]}`,
		`{"version":1,"selectors":[{"type":"page","artifact_page":4,"page_supplied":true}]}`,
		`{"version":1,"selectors":[{"type":"page","artifact_page":3000000000,"page_unknown":true}]}`,
		`{"version":1,"selectors":[{"type":"artifact"}]}`,
		`{`,
	} {
		f.Add(doc)
	}
	f.Fuzz(func(t *testing.T, doc string) {
		err := Validate(doc)
		ref := Page(doc)
		if err := valuemark.Validate(ref.Mark, ref.Label != ""); err != nil {
			t.Fatalf("Page(%q).Mark = %+v with label %q: %v", doc, ref.Mark, ref.Label, err)
		}
		if err != nil || ref == (PageRef{}) {
			return
		}
		d, derr := decode(doc)
		if derr != nil {
			t.Fatalf("Validate accepted %q but decode refused it: %v", doc, derr)
		}
		sel, ok := pageSelector(d)
		if !ok {
			t.Fatalf("Page(%q) = %+v with no page selector", doc, ref)
		}
		if raw, _ := sel.pageMark(); raw != ref.Mark {
			t.Fatalf("Page(%q).Mark = %+v; written pair %+v", doc, ref.Mark, raw)
		}
	})
}
