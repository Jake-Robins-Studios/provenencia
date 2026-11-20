package citationformat

import "github.com/Jake-Robins-Studios/provenencia/core/vocabkey"

// Placeholder is one placeholder a format can hold at a level, as the editor's
// completion lists it: a built-in, a built-in with an option, or (when Option
// and Builtin are empty) a metadata field the caller adds.
type Placeholder struct {
	Level vocabkey.Level
	// Builtin is the built-in's bare name; empty for a metadata field.
	Builtin string
	// Option is the option after the colon; empty for none.
	Option Option
	// Text is the whole placeholder, braces included: {source.date:year}.
	Text string
	// Ref is what sits inside the braces: source.date:year.
	Ref string
}

// MetaPlaceholder is the whole placeholder of metadata field key at level l,
// written by key: {graph.meta.line_number}.
func MetaPlaceholder(l vocabkey.Level, key string) string {
	return "{" + metaRef(l, key) + "}"
}

func metaRef(l vocabkey.Level, key string) string { return string(l) + ".meta." + key }

// BuiltinPlaceholders lists the built-in placeholders form f may use, per level
// in vocabkey order: each built-in bare and, for each option other than
// OptionFull, with that option. The list form keeps the levels
// ListFormAllows admits.
func BuiltinPlaceholders(f Form) []Placeholder {
	var out []Placeholder
	for _, l := range vocabkey.Levels() {
		if f == FormList && !ListFormAllows(l) {
			continue
		}
		for _, b := range builtins {
			if b.Level != l {
				continue
			}
			ref := string(l) + "." + b.Name
			out = append(out, Placeholder{Level: l, Builtin: b.Name, Text: "{" + ref + "}", Ref: ref})
			for _, o := range b.Options {
				if o == OptionFull {
					continue
				}
				out = append(out, Placeholder{Level: l, Builtin: b.Name, Option: o,
					Text: "{" + ref + ":" + string(o) + "}", Ref: ref + ":" + string(o)})
			}
		}
	}
	return out
}
