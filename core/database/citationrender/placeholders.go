package citationrender

import (
	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields"
)

// Placeholder is one row of the editor's completion list: a built-in
// (citationformat.Placeholder with no Field) or a metadata field the project
// holds, at one level.
type Placeholder struct {
	citationformat.Placeholder
	Field *metadatafields.Field
}

// Placeholders lists what form f can hold, level by level in vocabkey order,
// only the levels f may read: each level's built-ins (citationformat.
// BuiltinPlaceholders), then, for a level that holds metadata, every field of
// the project in metadatafields.List order, unfiltered and not re-sorted.
func Placeholders(c *database.Catalog, f citationformat.Form) ([]Placeholder, error) {
	fields, err := metadatafields.List(c)
	if err != nil {
		return nil, err
	}
	var out []Placeholder
	builtins := citationformat.BuiltinPlaceholders(f)
	for i := 0; i < len(builtins); {
		level := builtins[i].Level
		for ; i < len(builtins) && builtins[i].Level == level; i++ {
			out = append(out, Placeholder{Placeholder: builtins[i]})
		}
		if !level.HoldsMetadata() {
			continue
		}
		for _, field := range fields {
			text := citationformat.MetaPlaceholder(level, field.Key)
			out = append(out, Placeholder{
				Placeholder: citationformat.Placeholder{Level: level, Text: text, Ref: text[1 : len(text)-1]},
				Field:       &field,
			})
		}
	}
	return out, nil
}
