package citationformat

import (
	"strings"
	"unicode/utf8"

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
// merged and none empty, at most MaxRenderedBytes of text.
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

// writer collects runs as lists of pieces joined once, and stops taking text
// at the room it was given.
type writer struct {
	runs []runBuf
	room int
}

type runBuf struct {
	italic bool
	pieces []string
}

func (w *writer) add(text string, italic bool) {
	text = truncate(text, w.room)
	if text == "" {
		return
	}
	w.room -= len(text)
	if n := len(w.runs); n > 0 && w.runs[n-1].italic == italic {
		w.runs[n-1].pieces = append(w.runs[n-1].pieces, text)
		return
	}
	w.runs = append(w.runs, runBuf{italic, []string{text}})
}

// merge adds the runs of o, which was given no more room than w has left.
func (w *writer) merge(o *writer) {
	for _, run := range o.runs {
		for _, piece := range run.pieces {
			w.add(piece, run.italic)
		}
	}
}

func (w *writer) rendered() Rendered {
	var out Rendered
	for _, run := range w.runs {
		out.Runs = append(out.Runs, Run{strings.Join(run.pieces, ""), run.italic})
	}
	return out
}

// truncate cuts s to at most n bytes without splitting a character.
func truncate(s string, n int) string {
	if len(s) <= n {
		return s
	}
	for n > 0 && !utf8.RuneStart(s[n]) {
		n--
	}
	return s[:n]
}

// Render fills the template's placeholders from r. Values go in as literal
// text after parsing, so none changes the format. A group prints when every
// placeholder of its own prints text; otherwise it and everything inside it
// print nothing. A placeholder outside any group with no value prints nothing.
// The text stops at MaxRenderedBytes: the value that crosses it is cut and
// nothing after it prints.
func Render(t *Template, r Resolver) Rendered {
	if t == nil {
		return Rendered{}
	}
	w := writer{room: MaxRenderedBytes}
	renderNodes(t.root, false, t.form, r, &w)
	return w.rendered()
}

// renderNodes writes nodes into out and reports whether every placeholder of
// their own printed text. Nested groups decide for themselves.
func renderNodes(nodes []node, italic bool, form Form, r Resolver, out *writer) bool {
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
			inner := writer{room: out.room}
			if renderNodes(n.children, italic, form, r, &inner) {
				out.merge(&inner)
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
	isBuiltin := r.Builtin != ""
	if v.Mark.Unknown {
		if isBuiltin {
			return builtins[r.row].UnknownText, true
		}
		return v.UnknownText, true
	}
	if isBuiltin && builtins[r.row].Date {
		if v.Date != nil {
			text = datevalue.CitationDisplay(*v.Date, dateStyle(r.Option, form))
		}
	} else {
		text = truncate(v.Text, MaxRenderedBytes)
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
