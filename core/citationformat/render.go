package citationformat

import (
	"strings"

	"github.com/mendahu/provenencia/core/datevalue"
	"github.com/mendahu/provenencia/core/valuemark"
)

// Resolver answers what one target holds for the Citation being written. It
// has no error: a caller loads the values first. A target it does not know
// answers the zero Value.
type Resolver interface {
	Resolve(t Target) Value
}

// Value is what a target holds. A date built-in reads Date only; every other
// target reads Text only.
type Value struct {
	Text string
	Date *datevalue.Value
	Mark valuemark.Mark
	// UnknownText is what a metadata value prints when marked unknown; a
	// built-in's comes from its row.
	UnknownText string
}

// Run is a stretch of text in one style.
type Run struct {
	Text   string
	Italic bool
}

// Rendered is a format filled in: styled runs, adjacent runs of one style
// merged and none empty.
type Rendered struct {
	Runs []Run
}

// Plain is the text of every run.
func (r Rendered) Plain() string {
	var b strings.Builder
	for _, run := range r.Runs {
		b.WriteString(run.Text)
	}
	return b.String()
}

func (r *Rendered) add(text string, italic bool) {
	if text == "" {
		return
	}
	if n := len(r.Runs); n > 0 && r.Runs[n-1].Italic == italic {
		r.Runs[n-1].Text += text
		return
	}
	r.Runs = append(r.Runs, Run{text, italic})
}

func (r *Rendered) append(o Rendered) {
	for _, run := range o.Runs {
		r.add(run.Text, run.Italic)
	}
}

// Render fills the template's placeholders from r. Values go in as literal
// text after parsing, so none changes the format. A group prints when every
// placeholder of its own prints text; otherwise it and everything inside it
// print nothing. A placeholder outside any group with no value prints nothing.
func Render(t *Template, r Resolver) Rendered {
	var out Rendered
	if t == nil {
		return out
	}
	renderNodes(t.root, false, t.form, r, &out)
	return out
}

// renderNodes writes nodes into out and reports whether every placeholder of
// their own printed text. Nested groups decide for themselves.
func renderNodes(nodes []node, italic bool, form Form, r Resolver, out *Rendered) bool {
	ok := true
	for _, n := range nodes {
		switch n.kind {
		case nodeLiteral:
			out.add(n.text, italic)
		case nodePlaceholder:
			text := chainText(n.chain, form, r)
			if text == "" {
				ok = false
			}
			out.add(text, italic)
		case nodeItalic:
			if !renderNodes(n.children, true, form, r, out) {
				ok = false
			}
		case nodeGroup:
			var inner Rendered
			if renderNodes(n.children, italic, form, r, &inner) {
				out.append(inner)
			}
		}
	}
	return ok
}

// chainText is the text of a chain's first answered option, or "".
func chainText(chain []Ref, form Form, r Resolver) string {
	for _, ref := range chain {
		if text, answered := resolve(ref, form, r); answered {
			return text
		}
	}
	return ""
}

func resolve(ref Ref, form Form, r Resolver) (string, bool) {
	if r == nil {
		return "", false
	}
	return printed(ref, r.Resolve(ref.Target), form)
}

// printed is what one option of a chain prints and whether it answered. A
// value marked unknown answers with its unknown text, which may be empty. Any
// other answers when its text has something besides space, and prints as
// given, in square brackets when supplied.
func printed(r Ref, v Value, form Form) (text string, answered bool) {
	var b Builtin
	isBuiltin := r.Builtin != ""
	if isBuiltin {
		b, _ = LookupBuiltin(r.Level, r.Builtin)
	}
	if v.Mark.Unknown {
		if isBuiltin {
			return b.UnknownText, true
		}
		return v.UnknownText, true
	}
	if isBuiltin && b.Date {
		if v.Date != nil {
			text = datevalue.CitationDisplay(*v.Date, dateStyle(r.Option, form))
		}
	} else {
		text = v.Text
	}
	if strings.TrimSpace(text) == "" {
		return "", false
	}
	if v.Mark.Supplied {
		text = "[" + text + "]"
	}
	return text, true
}

func dateStyle(o Option, form Form) datevalue.CitationStyle {
	switch {
	case o == OptionYear:
		return datevalue.CitationYear
	case form == FormShort:
		return datevalue.CitationShort
	default:
		return datevalue.CitationLong
	}
}
