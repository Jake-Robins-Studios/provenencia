package sourcevocab

import (
	"maps"

	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
)

// suggestedKeys is the suggestion rule (docs/seeded-vocabulary.md § 2.3)
// applied to a type's formats: the type's fields as one list, each once, in the
// order its formats first read them (the full format, then the list and short
// formats' needed chains the full format does not already meet); nothing is
// appended. A format names no level, so neither does the list. Install has
// already refused a format that does not parse, so a form without a template
// reads nothing.
func suggestedKeys(f sourcetypes.Formats) []string {
	templates, _ := f.Parse()
	var order []string
	read := map[string]bool{}
	// The full format's fields, then the ones the list and the short format
	// need outside any group that the full format does not use.
	full := true
	var fullKeys map[string]bool
	for _, form := range []citationformat.Form{citationformat.FormFull, citationformat.FormList, citationformat.FormShort} {
		for _, req := range citationformat.Requirements(templates[form]) {
			if !full && req.Need != citationformat.NeedNeeded {
				continue
			}
			// A chain is met when one option is suggested, so a later form's
			// chain adds nothing when the full format already uses an option.
			met := false
			for _, target := range req.Targets {
				met = met || (!full && fullKeys[target.Field.Key])
			}
			if met {
				continue
			}
			for _, target := range req.Targets {
				key := target.Field.Key
				if key == "" || read[key] {
					continue
				}
				read[key] = true
				order = append(order, key)
			}
		}
		if full {
			full = false
			fullKeys = maps.Clone(read)
		}
	}
	return order
}
