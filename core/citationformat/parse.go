package citationformat

import (
	"slices"
	"sort"
	"strings"
	"unicode"
	"unicode/utf8"

	"github.com/google/uuid"

	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

// Limits on a format. The text comes from the catalog, which a crafted project
// can fill, so work is bounded before it is done.
const (
	// MaxFormatChars is the longest format a researcher can write, counted in
	// Unicode code points (utf8.RuneCountInString): the limit the editor shows.
	MaxFormatChars = 4000
	// MaxFormatBytes is the longest text Parse reads, typed or stored. Saving a
	// format swaps each field key for "#" and a 36-character id, so a stored
	// text is longer than the typed one; this is MaxFormatChars (at up to about
	// 1.6 bytes a character in the seeds) plus a margin for that growth. The
	// 72 seeded formats hold at most 22 placeholders; at twice that, 44, and
	// 36 bytes of growth each (a one-character key), the margin is 1,584 bytes.
	MaxFormatBytes = 8 << 10
	// MaxRenderedBytes is the most text Render produces, and the longest value
	// it copies. It is far above the longest seeded format filled with real
	// values; a crafted format repeating a placeholder reaches it, and Render
	// stops there.
	MaxRenderedBytes = 64 << 10
	// MaxDepth is the most open groups and italic spans at once.
	MaxDepth = 8
)

// FieldRef names a metadata field by key (as the researcher types it) or by id
// (as a format is stored). Exactly one is set.
type FieldRef struct {
	Key string
	ID  uuid.UUID
}

// ByID reports whether f names its field by id.
func (f FieldRef) ByID() bool { return f.ID != uuid.Nil }

// Token is f as a format writes it: the key, or "#" and the canonical id.
func (f FieldRef) Token() string {
	if f.ByID() {
		return "#" + f.ID.String()
	}
	return f.Key
}

// Target is what a placeholder option points at: exactly one of Builtin (the
// bare name, "date") and Field is set. It is comparable and is the identity
// requirements and resolvers use.
type Target struct {
	// Level is a built-in's level. For a field it is "" (read nearest-first) or
	// the Source (the list form).
	Level   vocabkey.Level
	Builtin string
	Field   FieldRef
}

// Span is a half-open range of UTF-8 byte offsets in the format text.
type Span struct{ Start, End int }

// Ref is one option of a placeholder as it occurs in a format.
type Ref struct {
	Target
	Option Option
	Span   Span
	// fieldSpan is where a metadata option writes its field.
	fieldSpan Span
	// row is the built-in's index in builtins; it means nothing when Builtin
	// is empty.
	row int
}

// DiagnosticCode names one mistake in a format, found by Parse or by storing
// the format.
type DiagnosticCode string

const (
	CodeUnknownForm             DiagnosticCode = "unknown_form"
	CodeTooLong                 DiagnosticCode = "too_long"
	CodeTooDeep                 DiagnosticCode = "too_deep"
	CodeUnclosedPlaceholder     DiagnosticCode = "unclosed_placeholder"
	CodeStrayCloseBrace         DiagnosticCode = "stray_close_brace"
	CodeUnclosedGroup           DiagnosticCode = "unclosed_group"
	CodeStrayCloseBracket       DiagnosticCode = "stray_close_bracket"
	CodeUnclosedItalic          DiagnosticCode = "unclosed_italic"
	CodeBadEscape               DiagnosticCode = "bad_escape"
	CodeGroupWithoutPlaceholder DiagnosticCode = "group_without_placeholder"
	CodeEmptyOption             DiagnosticCode = "empty_option"
	CodeBadCharacter            DiagnosticCode = "bad_character"
	CodeMetaAtLevel             DiagnosticCode = "meta_at_level"
	CodeUnknownLevel            DiagnosticCode = "unknown_level"
	CodeBadField                DiagnosticCode = "bad_field"
	CodeUnknownBuiltin          DiagnosticCode = "unknown_builtin"
	CodeUnknownOption           DiagnosticCode = "unknown_option"
	CodeNotInListForm           DiagnosticCode = "not_in_list_form"
	CodeUnknownField            DiagnosticCode = "unknown_field"
	CodeAmbiguousField          DiagnosticCode = "ambiguous_field"
)

// DiagnosticCodes returns every code, a new slice in the order of the table in
// docs/citation-formats.md.
func DiagnosticCodes() []DiagnosticCode {
	return []DiagnosticCode{
		CodeUnknownForm, CodeTooLong, CodeTooDeep, CodeUnclosedPlaceholder,
		CodeStrayCloseBrace, CodeUnclosedGroup, CodeStrayCloseBracket,
		CodeUnclosedItalic, CodeBadEscape, CodeGroupWithoutPlaceholder,
		CodeEmptyOption, CodeBadCharacter, CodeMetaAtLevel, CodeUnknownLevel,
		CodeBadField, CodeUnknownBuiltin, CodeUnknownOption,
		CodeNotInListForm, CodeUnknownField, CodeAmbiguousField,
	}
}

// Diagnostic is one mistake in a format and where it is.
type Diagnostic struct {
	Code DiagnosticCode
	Span Span
}

type nodeKind int

const (
	nodeLiteral nodeKind = iota
	nodePlaceholder
	nodeGroup
	nodeItalic
)

// node is one piece of the tree: literal text, a placeholder (a chain of
// options), a group or an italic span.
type node struct {
	kind     nodeKind
	text     string
	chain    []Ref
	children []node
}

// Template is a parsed format. The tree is unexported: callers use Render,
// Requirements and Missing.
type Template struct {
	text string
	form Form
	root []node
	refs []Ref // every option, in text order
}

// Form is the form the template was parsed as.
func (t *Template) Form() Form {
	if t == nil {
		return ""
	}
	return t.form
}

// Text is the format as written.
func (t *Template) Text() string {
	if t == nil {
		return ""
	}
	return t.text
}

type frame struct {
	kind     nodeKind // nodeGroup or nodeItalic
	start    int
	children []node
	hasPH    bool
}

type parser struct {
	text  string
	form  Form
	diags []Diagnostic
	stack []frame // open groups and italic spans; stack[0] is the root
	lit   strings.Builder
	refs  []Ref
}

// Parse reads text as a format of the given form. A template comes back only
// with no diagnostics; otherwise every diagnostic comes back, sorted by
// position. When scanning has to stop, nothing after it is reported.
func Parse(text string, form Form) (*Template, []Diagnostic) {
	if !form.Valid() {
		return nil, []Diagnostic{{CodeUnknownForm, Span{}}}
	}
	if len(text) > MaxFormatBytes {
		return nil, []Diagnostic{{CodeTooLong, Span{0, len(text)}}}
	}
	p := &parser{text: text, form: form, stack: []frame{{}}}
	if stopped := p.scan(); !stopped {
		p.finish()
	}
	if len(p.diags) > 0 {
		sort.SliceStable(p.diags, func(i, j int) bool { return p.diags[i].Span.Start < p.diags[j].Span.Start })
		return nil, p.diags
	}
	p.flush()
	return &Template{text: text, form: form, root: p.stack[0].children, refs: p.refs}, nil
}

func (p *parser) diag(c DiagnosticCode, start, end int) {
	p.diags = append(p.diags, Diagnostic{c, Span{start, end}})
}

func (p *parser) top() *frame { return &p.stack[len(p.stack)-1] }

func (p *parser) add(n node) {
	p.flush()
	f := p.top()
	f.children = append(f.children, n)
}

func (p *parser) flush() {
	if p.lit.Len() == 0 {
		return
	}
	s := p.lit.String()
	p.lit.Reset()
	f := p.top()
	f.children = append(f.children, node{kind: nodeLiteral, text: s})
}

// open pushes a group or italic span; false when that makes the depth too great.
func (p *parser) open(kind nodeKind, at int) bool {
	if len(p.stack) > MaxDepth {
		p.diag(CodeTooDeep, at, at+1)
		return false
	}
	p.flush()
	p.stack = append(p.stack, frame{kind: kind, start: at})
	return true
}

// pop closes the top frame into its parent and returns it.
func (p *parser) pop() frame {
	p.flush()
	f := p.stack[len(p.stack)-1]
	p.stack = p.stack[:len(p.stack)-1]
	parent := p.top()
	kind := f.kind
	parent.children = append(parent.children, node{kind: kind, children: f.children})
	if kind == nodeItalic && f.hasPH {
		parent.hasPH = true
	}
	return f
}

// scan reads the text once. It reports whether it had to stop early.
func (p *parser) scan() bool {
	text := p.text
	for i := 0; i < len(text); {
		c := text[i]
		switch c {
		case '\\':
			if i+1 >= len(text) {
				p.diag(CodeBadEscape, i, i+1)
				i++
				continue
			}
			next := text[i+1]
			if strings.IndexByte(`\{}[]*`, next) >= 0 {
				p.lit.WriteByte(next)
				i += 2
				continue
			}
			_, size := utf8.DecodeRuneInString(text[i+1:])
			p.diag(CodeBadEscape, i, i+1+size)
			i += 1 + size
		case '{':
			end := strings.IndexAny(text[i+1:], "{}")
			if end < 0 {
				p.diag(CodeUnclosedPlaceholder, i, i+1)
				return true
			}
			if text[i+1+end] == '{' {
				// A later { opens its own placeholder; this one never closed.
				p.diag(CodeUnclosedPlaceholder, i, i+1)
				i += 1 + end
				continue
			}
			p.placeholder(i+1, text[i+1:i+1+end])
			i += end + 2
		case '}':
			p.diag(CodeStrayCloseBrace, i, i+1)
			i++
		case '[':
			if !p.open(nodeGroup, i) {
				return true
			}
			i++
		case ']':
			p.closeGroup(i)
			i++
		case '*':
			if p.top().kind == nodeItalic && len(p.stack) > 1 {
				p.pop()
			} else if !p.open(nodeItalic, i) {
				return true
			}
			i++
		default:
			p.lit.WriteByte(c)
			i++
		}
	}
	return false
}

func (p *parser) closeGroup(at int) {
	hasGroup := false
	for _, f := range p.stack[1:] {
		if f.kind == nodeGroup {
			hasGroup = true
		}
	}
	if !hasGroup {
		p.diag(CodeStrayCloseBracket, at, at+1)
		return
	}
	for p.top().kind == nodeItalic {
		f := p.pop()
		p.diag(CodeUnclosedItalic, f.start, f.start+1)
	}
	f := p.pop()
	if !f.hasPH {
		p.diag(CodeGroupWithoutPlaceholder, f.start, at+1)
	}
}

// finish reports what is still open at the end of the text.
func (p *parser) finish() {
	for len(p.stack) > 1 {
		f := p.pop()
		if f.kind == nodeGroup {
			p.diag(CodeUnclosedGroup, f.start, f.start+1)
		} else {
			p.diag(CodeUnclosedItalic, f.start, f.start+1)
		}
	}
}

// placeholder reads the body of one {...} whose first byte is at base.
func (p *parser) placeholder(base int, body string) {
	var chain []Ref
	offset := 0
	for _, opt := range strings.Split(body, "|") {
		ref, d := p.option(opt, base+offset)
		if d != nil {
			p.diags = append(p.diags, *d)
		}
		// A repeat of the same target with the same option reads the same value; one that
		// differs only in its option (year, then the whole date) can still render.
		if !slices.ContainsFunc(chain, func(c Ref) bool { return c.Target == ref.Target && c.Option == ref.Option }) {
			chain = append(chain, ref)
		}
		p.refs = append(p.refs, ref)
		offset += len(opt) + 1
	}
	p.top().hasPH = true
	p.add(node{kind: nodePlaceholder, chain: chain})
}

// option checks one option of a chain, in the order of the diagnostic table,
// and returns at most one diagnostic.
func (p *parser) option(opt string, start int) (Ref, *Diagnostic) {
	whole := Span{start, start + len(opt)}
	bad := func(c DiagnosticCode, s Span) (Ref, *Diagnostic) {
		return Ref{Span: whole}, &Diagnostic{c, s}
	}
	if opt == "" {
		return bad(CodeEmptyOption, Span{start, start})
	}
	if k := strings.IndexAny(opt, " \\{[]*"); k >= 0 {
		return bad(CodeBadCharacter, Span{start + k, start + k + 1})
	}
	main, optText, hasOpt := strings.Cut(opt, ":")
	optSpan := Span{start + len(main) + 1, start + len(opt)}
	if !hasOpt {
		optSpan = Span{start + len(opt), start + len(opt)}
	}
	first, rest, hasDot := strings.Cut(main, ".")
	if first == "meta" {
		field := rest
		fieldStart := start + len("meta.")
		if !hasDot {
			fieldStart = start + len(main)
		}
		fieldSpan := Span{fieldStart, fieldStart + len(field)}
		fr, ok := parseField(field)
		if !ok {
			return bad(CodeBadField, fieldSpan)
		}
		level := vocabkey.Level("")
		if p.form == FormList {
			level = ListFormLevel
		}
		r := Ref{Target: Target{Level: level, Field: fr}, Option: Option(optText), Span: whole, fieldSpan: fieldSpan}
		if hasOpt {
			return r, &Diagnostic{CodeUnknownOption, optSpan}
		}
		return r, nil
	}
	level := vocabkey.Level(first)
	if !level.Valid() {
		return bad(CodeUnknownLevel, whole)
	}
	if hasDot && (rest == "meta" || strings.HasPrefix(rest, "meta.")) {
		return bad(CodeMetaAtLevel, whole)
	}
	ref := Ref{Target: Target{Level: level}, Option: Option(optText), Span: whole}
	row, ok := builtinRow(level, rest)
	if !hasDot || !ok {
		return bad(CodeUnknownBuiltin, whole)
	}
	b := &builtins[row]
	ref.Builtin, ref.row = rest, row
	if hasOpt && !b.hasOption(Option(optText)) {
		return ref, &Diagnostic{CodeUnknownOption, optSpan}
	}
	if p.form == FormList && !ListFormAllows(level) {
		return ref, &Diagnostic{CodeNotInListForm, whole}
	}
	return ref, nil
}

// parseField reads a field token: a key, or "#" and a canonical id.
func parseField(s string) (FieldRef, bool) {
	if strings.HasPrefix(s, "#") {
		id, err := uuid.Parse(s[1:])
		if err != nil || id == uuid.Nil || id.String() != s[1:] {
			return FieldRef{}, false
		}
		return FieldRef{ID: id}, true
	}
	if s == "" {
		return FieldRef{}, false
	}
	for _, r := range s {
		if !unicode.IsLetter(r) && !unicode.IsDigit(r) && r != '_' && r != '-' {
			return FieldRef{}, false
		}
	}
	return FieldRef{Key: s}, true
}
