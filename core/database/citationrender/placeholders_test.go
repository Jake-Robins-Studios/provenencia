package citationrender

import (
	"slices"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

func TestPlaceholders(t *testing.T) {
	w := newWorld(t)
	all, err := metadatafields.List(w.c)
	if err != nil {
		t.Fatal(err)
	}
	var keys []string
	for _, f := range all {
		keys = append(keys, f.Key)
	}

	t.Run("AC-7.9 the list form: the Source built-ins, then every field once", func(t *testing.T) {
		got, err := Placeholders(w.c, citationformat.FormList)
		if err != nil {
			t.Fatal(err)
		}
		builtins := 4
		if len(got) != builtins+len(all) {
			t.Fatalf("got %d rows, want %d", len(got), builtins+len(all))
		}
		for i, p := range got {
			if (i < builtins) != (p.Field == nil) {
				t.Errorf("row %d (%s): field %v", i, p.Text, p.Field)
			}
			if i < builtins && p.Level != vocabkey.LevelSource {
				t.Errorf("row %d at level %s", i, p.Level)
			}
		}
		for i, f := range all {
			row := got[builtins+i]
			if row.Field == nil || row.Field.Key != f.Key || row.Text != "{meta."+f.Key+"}" || row.Level != "" {
				t.Errorf("field row %d = %+v, want key %s with no level", i, row, f.Key)
			}
		}
	})

	t.Run("AC-7.10 the full form: Source, Artifact, Evidence graph, Citation, then every field once", func(t *testing.T) {
		got, err := Placeholders(w.c, citationformat.FormFull)
		if err != nil {
			t.Fatal(err)
		}
		var levels []vocabkey.Level
		var fieldKeys []string
		for _, p := range got {
			if p.Field != nil {
				fieldKeys = append(fieldKeys, p.Field.Key)
				if p.Level != "" || p.Text != "{meta."+p.Field.Key+"}" {
					t.Errorf("field row %+v: want no level, {meta.key}", p)
				}
				continue
			}
			if len(fieldKeys) > 0 {
				t.Errorf("built-in %s after a field row", p.Text)
			}
			if len(levels) == 0 || levels[len(levels)-1] != p.Level {
				levels = append(levels, p.Level)
			}
		}
		if !slices.Equal(levels, vocabkey.Levels()) {
			t.Errorf("levels = %v", levels)
		}
		if !slices.Equal(fieldKeys, keys) {
			t.Errorf("fields = %v, want %v", fieldKeys, keys)
		}
	})
}
