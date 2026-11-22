package citationrender

import (
	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields"
)

// Placeholder is one row of the editor's completion list: a built-in
// (citationformat.Placeholder with no Field) or a metadata field the project
// holds, which has no level (a format reads it from the nearest level that
// holds it).
type Placeholder struct {
	citationformat.Placeholder
	Field *metadatafields.Field
}

// Placeholders lists what form f can hold: every built-in it may use, level by
// level in vocabkey order (citationformat.BuiltinPlaceholders), then every
// field of the project once in metadatafields.List order, unfiltered and not
// re-sorted. Every form lists the same fields.
func Placeholders(c *database.Catalog, f citationformat.Form) ([]Placeholder, error) {
	fields, err := metadatafields.List(c)
	if err != nil {
		return nil, err
	}
	var out []Placeholder
	for _, b := range citationformat.BuiltinPlaceholders(f) {
		out = append(out, Placeholder{Placeholder: b})
	}
	for _, field := range fields {
		out = append(out, Placeholder{
			Placeholder: citationformat.MetaFieldPlaceholder(field.Key),
			Field:       &field,
		})
	}
	return out, nil
}
