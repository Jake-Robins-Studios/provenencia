package citationformat

import "github.com/Jake-Robins-Studios/provenencia/core/vocabkey"

// Placeholder is one placeholder a format can hold, as the editor's completion
// lists it: a built-in at its level, a built-in with an option, or (when Option
// and Builtin are empty) a metadata field the caller adds, which has no level.
type Placeholder struct {
	// Level is a built-in's level; empty for a metadata field.
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

// MetaFieldPlaceholder is the placeholder row of metadata field key: no level
// and no built-in, its Text and Ref (written by key) built from one ref:
// {meta.line_number}. The engine reads the field from the nearest level that
// holds it.
func MetaFieldPlaceholder(key string) Placeholder {
	ref := "meta." + key
	return Placeholder{Text: "{" + ref + "}", Ref: ref}
}

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
