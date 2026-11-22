package citationformat

import (
	"slices"
	"testing"
)

func TestBuiltinPlaceholders(t *testing.T) {
	texts := func(f Form) []string {
		var out []string
		for _, p := range BuiltinPlaceholders(f) {
			out = append(out, p.Text)
		}
		return out
	}

	t.Run("list keeps the Source level", func(t *testing.T) {
		want := []string{"{source.title}", "{source.type}", "{source.date}", "{source.date:year}"}
		if got := texts(FormList); !slices.Equal(got, want) {
			t.Errorf("got %v, want %v", got, want)
		}
	})

	t.Run("full lists every built-in once, an option but never :full", func(t *testing.T) {
		got := texts(FormFull)
		for _, b := range Builtins() {
			if !slices.Contains(got, "{"+string(b.Level)+"."+b.Name+"}") {
				t.Errorf("missing %s.%s", b.Level, b.Name)
			}
		}
		if !slices.Contains(got, "{source.date:year}") || slices.Contains(got, "{source.date:full}") {
			t.Errorf("options in %v", got)
		}
		if got[0] != "{source.title}" || got[len(got)-1] != "{citation.label}" {
			t.Errorf("order %v", got)
		}
	})

	t.Run("each row's text parses and Ref is its inside", func(t *testing.T) {
		for _, p := range BuiltinPlaceholders(FormFull) {
			if _, diags := Parse(p.Text, FormFull); len(diags) != 0 {
				t.Errorf("%s: %v", p.Text, diags)
			}
			if p.Text != "{"+p.Ref+"}" {
				t.Errorf("text %q, ref %q", p.Text, p.Ref)
			}
		}
	})
}

func TestMetaFieldPlaceholder(t *testing.T) {
	p := MetaFieldPlaceholder("line_number")
	if p.Text != "{meta.line_number}" || p.Ref != "meta.line_number" || p.Level != "" || p.Builtin != "" {
		t.Fatalf("got %+v", p)
	}
	if _, diags := Parse(p.Text, FormFull); len(diags) != 0 {
		t.Errorf("does not parse: %v", diags)
	}
}
