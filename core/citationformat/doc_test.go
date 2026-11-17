package citationformat_test

import (
	"slices"
	"testing"

	"github.com/mendahu/provenencia/core/citationformat"
	"github.com/mendahu/provenencia/core/internal/doctable"
)

// TestDocMatchesEngine holds docs/citation-formats.md to the engine: its
// built-in placeholder table lists every row of Builtins, and its diagnostics
// table every code of DiagnosticCodes.
func TestDocMatchesEngine(t *testing.T) {
	const doc = "../../docs/citation-formats.md"
	var builtins []string
	for _, b := range citationformat.Builtins() {
		builtins = append(builtins, string(b.Level)+"."+b.Name)
	}
	var codes []string
	for _, c := range citationformat.DiagnosticCodes() {
		codes = append(codes, string(c))
	}
	for _, tc := range []struct {
		section string
		want    []string
	}{{"Built-in placeholders", builtins}, {"Diagnostics", codes}} {
		got := doctable.FirstColumn(t, doc, tc.section)
		for _, w := range tc.want {
			if !slices.Contains(got, w) {
				t.Errorf("## %s has no row for %s", tc.section, w)
			}
		}
		for _, g := range got {
			if !slices.Contains(tc.want, g) {
				t.Errorf("## %s names %s, which the engine does not have", tc.section, g)
			}
		}
	}
}
