package citationrender

import (
	"slices"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
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

	t.Run("AC-7.9 the list form: the Source built-ins, then every field", func(t *testing.T) {
		got, err := Placeholders(w.c, citationformat.FormList)
		if err != nil {
			t.Fatal(err)
		}
		builtins := 4
		if len(got) != builtins+len(all) {
			t.Fatalf("got %d rows, want %d", len(got), builtins+len(all))
		}
		for i, p := range got {
			if p.Level != vocabkey.LevelSource {
				t.Errorf("row %d at level %s", i, p.Level)
			}
			if (i < builtins) != (p.Field == nil) {
				t.Errorf("row %d (%s): field %v", i, p.Text, p.Field)
			}
		}
		for i, f := range all {
			row := got[builtins+i]
			if row.Field == nil || row.Field.Key != f.Key || row.Text != "{source.meta."+f.Key+"}" {
				t.Errorf("field row %d = %+v, want key %s", i, row, f.Key)
			}
		}
	})

	t.Run("AC-7.10 the full form: Source, Artifact, Evidence graph, Citation", func(t *testing.T) {
		got, err := Placeholders(w.c, citationformat.FormFull)
		if err != nil {
			t.Fatal(err)
		}
		var levels []vocabkey.Level
		fieldsAt := map[vocabkey.Level][]string{}
		for _, p := range got {
			if len(levels) == 0 || levels[len(levels)-1] != p.Level {
				levels = append(levels, p.Level)
			}
			if p.Field != nil {
				fieldsAt[p.Level] = append(fieldsAt[p.Level], p.Field.Key)
			}
		}
		if !slices.Equal(levels, vocabkey.Levels()) {
			t.Errorf("levels = %v", levels)
		}
		for _, l := range vocabkey.MetadataLevels() {
			if !slices.Equal(fieldsAt[l], keys) {
				t.Errorf("%s fields = %v, want %v", l, fieldsAt[l], keys)
			}
		}
		if len(fieldsAt[vocabkey.LevelCitation]) != 0 {
			t.Errorf("citation fields = %v", fieldsAt[vocabkey.LevelCitation])
		}
	})

	t.Run("every seeded type's formats load with no diagnostic", func(t *testing.T) {
		types, err := sourcetypes.List(w.c)
		if err != nil {
			t.Fatal(err)
		}
		if len(types) != 26 {
			t.Fatalf("got %d seeded types, want 26", len(types))
		}
		for _, typ := range types {
			view, err := sourcetypes.GetFormats(w.c, typ.ID)
			if err != nil {
				t.Fatal(err)
			}
			for _, form := range citationformat.Forms() {
				text := view.Text(form)
				got, err := RenderPreview(w.c, PreviewInput{Form: form, Format: &text})
				if err != nil || len(got.Diagnostics) != 0 {
					t.Errorf("%s %s: %+v, %v", typ.Key, form, got.Diagnostics, err)
				}
			}
		}
	})
}
