package citationformat

import (
	"errors"
	"strings"
)

// ErrFieldRef is returned by RewriteFields when the answer for a field names
// both a key and an id, or neither.
var ErrFieldRef = errors.New("citationformat: a field reference needs exactly one of key and id")

// Fields returns the distinct metadata fields the template names, in order of
// first appearance.
func (t *Template) Fields() []FieldRef {
	if t == nil {
		return nil
	}
	var out []FieldRef
	seen := map[FieldRef]bool{}
	for _, r := range t.refs {
		if r.Builtin != "" || seen[r.Field] {
			continue
		}
		seen[r.Field] = true
		out = append(out, r.Field)
	}
	return out
}

// RewriteFields returns the format with each field named as to answers. It
// calls to once per distinct field, in Fields order, and replaces only the
// bytes of each field's token, so every other byte stays as typed. It returns
// the first error to returns, or ErrFieldRef when an answer has both a key and
// an id or neither; on error the text is empty.
func (t *Template) RewriteFields(to func(FieldRef) (FieldRef, error)) (string, error) {
	if t == nil {
		return "", nil
	}
	answers := map[FieldRef]FieldRef{}
	for _, f := range t.Fields() {
		a, err := to(f)
		if err != nil {
			return "", err
		}
		if (a.Key != "") == a.ByID() {
			return "", ErrFieldRef
		}
		answers[f] = a
	}
	var b strings.Builder
	last := 0
	for _, r := range t.refs {
		if r.Builtin != "" {
			continue
		}
		b.WriteString(t.text[last:r.fieldSpan.Start])
		b.WriteString(answers[r.Field].Token())
		last = r.fieldSpan.End
	}
	b.WriteString(t.text[last:])
	return b.String(), nil
}
