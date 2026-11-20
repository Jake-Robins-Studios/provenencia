// Package citationformat is the one engine for a Source type's citation
// formats: text in a small syntax of our own, with {level.meta.key} and
// {level.builtin} placeholders, [optional groups] and *italics*. It parses a
// format into a tree with positioned diagnostics, renders it through a
// Resolver into styled runs, derives the fields a type's formats need or use,
// and rewrites a format's field references between keys and ids.
//
// The package is pure: it imports no database package, and nothing in it reads
// the catalog. The syntax, the built-in placeholders and the diagnostics are
// written in docs/citation-formats.md.
package citationformat

import "slices"

// Form is which citation a format writes: the first note, a later note, or the
// source-list entry.
type Form string

const (
	FormFull  Form = "full"
	FormShort Form = "short"
	FormList  Form = "list"
)

// Forms returns every form, a new slice in order on each call.
func Forms() []Form { return []Form{FormFull, FormShort, FormList} }

// Valid reports whether f is one of Forms. The match is exact.
func (f Form) Valid() bool { return slices.Contains(Forms(), f) }

// FormDiagnostic is a Diagnostic in one form's text.
type FormDiagnostic struct {
	Form Form
	Diagnostic
}

// Option is what follows the colon of a placeholder: how a date is written.
type Option string

const (
	OptionYear Option = "year"
	OptionFull Option = "full"
)

// Options returns every option, a new slice in order on each call.
func Options() []Option { return []Option{OptionYear, OptionFull} }
