// Package valuemark is the pure mark a value can carry beside its text: the
// researcher answered that the record does not give it (unknown), or took it
// from elsewhere (supplied). It imports no database package. The stores that
// keep a mark call Validate before they write: the Source's metadata values
// and date, and a Citation's printed page (core/locator). The citation format
// engine (core/citationformat) prints a mark.
package valuemark

import "github.com/Jake-Robins-Studios/provenencia/core/apperr"

// ErrInvalid is the one refusal of a bad mark, passed through by every store
// that checks one, as datevalue.ErrInvalid is.
var ErrInvalid = apperr.New(apperr.CodeValueMarkInvalid, apperr.KindUser)

// Mark is a value's unknown and supplied facts. Neither is set for a value
// typed as the record gives it.
type Mark struct {
	// Unknown: the record does not give the value. It has no text.
	Unknown bool
	// Supplied: the value is not on the record. It has text.
	Supplied bool
}

// Validate reports ErrInvalid when m cannot go with a value: both facts set,
// Unknown with a value, or Supplied with none. hasValue says whether the value
// has any text (or, for a date, any part).
func Validate(m Mark, hasValue bool) error {
	switch {
	case m.Unknown && m.Supplied:
		return ErrInvalid
	case m.Unknown && hasValue:
		return ErrInvalid
	case m.Supplied && !hasValue:
		return ErrInvalid
	}
	return nil
}
