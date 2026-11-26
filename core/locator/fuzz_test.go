package locator

import (
	"math"
	"testing"
)

// FuzzValidate feeds arbitrary documents to the locator parser, which reads
// locator_json the app may not have written: nothing panics, and a document
// Validate accepts still parses, holds a file page in its page selector, and
// reads as that file page.
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
		page := ArtifactPage(doc)
		if Validate(doc) != nil {
			return
		}
		d, err := parse(doc)
		if err != nil {
			t.Fatalf("Validate accepted %q but parse refused it: %v", doc, err)
		}
		sel, ok := pageSelector(d)
		if !ok {
			if page != 0 {
				t.Fatalf("ArtifactPage(%q) = %d with no page selector", doc, page)
			}
			return
		}
		if sel.ArtifactPage == nil {
			t.Fatalf("Validate accepted %q: page selector without a file page", doc)
		}
		want := *sel.ArtifactPage
		if want > math.MaxInt32 {
			want = 0
		}
		if page != want {
			t.Fatalf("ArtifactPage(%q) = %d; want %d", doc, page, want)
		}
	})
}
