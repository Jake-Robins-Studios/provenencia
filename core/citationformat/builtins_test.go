package citationformat_test

import (
	"testing"

	"github.com/mendahu/provenencia/core/citationformat"
	"github.com/mendahu/provenencia/core/vocabkey"
)

func TestBuiltins(t *testing.T) {
	want := []struct {
		level     vocabkey.Level
		name      string
		date      bool
		options   []citationformat.Option
		alwaysSet bool
		unknown   string
	}{
		{vocabkey.LevelSource, "title", false, nil, true, ""},
		{vocabkey.LevelSource, "type", false, nil, true, ""},
		{vocabkey.LevelSource, "date", true, []citationformat.Option{"year", "full"}, false, "n.d."},
		{vocabkey.LevelArtifact, "label", false, nil, true, ""},
		{vocabkey.LevelGraph, "name", false, nil, true, ""},
		{vocabkey.LevelCitation, "page", false, nil, false, "unpaginated"},
		{vocabkey.LevelCitation, "image", false, nil, false, ""},
		{vocabkey.LevelCitation, "label", false, nil, false, ""},
	}
	got := citationformat.Builtins()
	if len(got) != len(want) {
		t.Fatalf("got %d built-ins, want %d", len(got), len(want))
	}
	for i, w := range want {
		g := got[i]
		if g.Level != w.level || g.Name != w.name || g.Date != w.date || g.AlwaysSet != w.alwaysSet || g.UnknownText != w.unknown || len(g.Options) != len(w.options) {
			t.Errorf("row %d = %+v, want %+v", i, g, w)
		}
		for j := range w.options {
			if g.Options[j] != w.options[j] {
				t.Errorf("row %d option %d = %q, want %q", i, j, g.Options[j], w.options[j])
			}
		}
		if !g.Level.Valid() {
			t.Errorf("row %d level %q is not valid", i, g.Level)
		}
		if g.InListForm() != (g.Level == vocabkey.LevelSource) {
			t.Errorf("row %d InListForm = %v", i, g.InListForm())
		}
	}
	if _, ok := citationformat.LookupBuiltin(vocabkey.LevelCitation, "page"); !ok {
		t.Error("citation.page not found")
	}
	if _, ok := citationformat.LookupBuiltin(vocabkey.LevelSource, "page"); ok {
		t.Error("source.page found")
	}
	for _, l := range vocabkey.Levels() {
		if citationformat.ListFormAllows(l) != (l == vocabkey.LevelSource) {
			t.Errorf("ListFormAllows(%s) wrong", l)
		}
	}
	got[0].Name = "changed"
	got[2].Options[0] = "changed"
	again := citationformat.Builtins()
	if again[0].Name != "title" || again[2].Options[0] != "year" {
		t.Error("Builtins returned shared storage")
	}
}

func TestForms(t *testing.T) {
	got := citationformat.Forms()
	want := []citationformat.Form{"full", "short", "list"}
	if len(got) != 3 || got[0] != want[0] || got[1] != want[1] || got[2] != want[2] {
		t.Fatalf("Forms = %v", got)
	}
	got[0] = "x"
	if citationformat.Forms()[0] != "full" {
		t.Error("Forms returned shared storage")
	}
	if citationformat.Form("x").Valid() {
		t.Error(`Form("x") is valid`)
	}
	for _, f := range want {
		if !f.Valid() {
			t.Errorf("%q not valid", f)
		}
	}
}
