package autoreconcile

import (
	"github.com/Jake-Robins-Studios/provenencia/core/propertymeta"
	"github.com/Jake-Robins-Studios/provenencia/core/valuecompare"
)

// A module is what one value type supplies to the shared pipeline
// (conclusion-reconciliation.md §7): when two values are the same, what folds
// into what, and how a group becomes one displayed value. Everything else —
// denial, majority, confidence, ordering, reasons — is the pipeline's.

// unit is one comparable piece of a value. A simple module splits a value
// into one unit; a structured one (names, S9-13b) into one per part type, and
// the pipeline votes on each unit separately.
type unit struct {
	key  string // equal keys are the same value
	data any    // the module's own payload, for fold and assemble
}

type module interface {
	// split reads a value's units by unit name. ok is false when the value
	// carries nothing to compare (no evidence).
	split(v Value) (units map[string]unit, ok bool)
	// fold reports whether from, a less specific value, folds into into, a
	// fuller one, both units of name. nickClass is true when the fold is
	// nickname-class (names only); other modules always return false.
	fold(name string, from, into unit) (folds, nickClass bool)
	// outvotes reports whether majority may crowd other out when winner wins
	// unit name. Simple modules let majority outvote anything; names only
	// outvote spelling variants of the winner.
	outvotes(name string, winner, other unit) bool
	// oneValue reports whether every displayed candidate forms a single
	// value (names: one structure, several values per part type), rather
	// than one value per agreeing group.
	oneValue() bool
	// assemble builds a value's displayed form from its supporting members
	// in rank order and, per unit name, the values it settled on (best
	// supported first). folded holds each unit's folded attaches for modules
	// that re-tag folded values (names). A module without oneValue gets one
	// value per name.
	assemble(members []Candidate, settled map[string][]unit, folded map[string][]foldAttach) Value
}

// wholeValue is the unit name of a module with one unit per value.
const wholeValue = ""

// moduleFor is valueType's module under rules, nil for an unknown type.
// Values are the same, and fold, by value compare's relations: Same groups,
// Contains folds, and no other relation does (D-2 of S11-06).
func moduleFor(rules valuecompare.Rules, valueType string) module {
	switch valueType {
	case propertymeta.ValueTypeText, propertymeta.ValueTypeInteger, propertymeta.ValueTypeBoolean, propertymeta.ValueTypeDepiction:
		return keyModule{keyOf: func(v Value) (string, bool) {
			return valuecompare.Key(v.compareValue(valueType), valuecompare.Same, rules)
		}}
	case propertymeta.ValueTypeTerm:
		return keyModule{keyOf: termKey}
	case propertymeta.ValueTypeSubject:
		// The accepted handle. The loader fills EntityID; an unpromoted or
		// missing end has none and is no evidence. A value that carries Within
		// folds into a narrower one it contains, as a date does.
		return keyModule{
			keyOf: func(v Value) (string, bool) { return idKey(v.EntityID) },
			folds: true, valueType: valueType, rules: rules,
		}
	case propertymeta.ValueTypeName:
		return nameModule{rules: rules}
	case propertymeta.ValueTypeDate:
		return dateModule{rules: rules}
	}
	return nil
}

// compareValue is v in the shape value compare reads: the text, integer, boolean, date,
// depiction or subject of a value of valueType. Names go through nameUnit.compareValue.
func (v Value) compareValue(valueType string) valuecompare.Value {
	return valuecompare.Value{Type: valueType, Text: v.Text, Integer: v.Integer, Boolean: v.Boolean, Date: v.Date, Depiction: v.Depiction,
		Entity: v.EntityID, Within: v.Within}
}

// foldsOnContains is the one "fold on Contains" check (S11-06): from, a less
// specific value, folds into into when value compare reads from as the broader
// side of a Contains. Both units carry their value compare value as data.
func foldsOnContains(rules valuecompare.Rules, from, into unit) bool {
	return valuecompare.FoldsInto(from.data.(valuecompare.Value), into.data.(valuecompare.Value), rules)
}

// keyModule is a value type whose values are the same exactly when their
// keys are equal: one unit, and the best-ranked member's value displayed. It
// folds on Contains only when folds is set (subjects); the unit then keeps the
// value compare value of valueType as data.
type keyModule struct {
	keyOf     func(Value) (key string, ok bool)
	folds     bool
	valueType string
	rules     valuecompare.Rules
}

func (m keyModule) split(v Value) (map[string]unit, bool) {
	k, ok := m.keyOf(v)
	if !ok {
		return nil, false
	}
	u := unit{key: k}
	if m.folds {
		u.data = v.compareValue(m.valueType)
	}
	return map[string]unit{wholeValue: u}, true
}

func (m keyModule) fold(_ string, from, into unit) (bool, bool) {
	return m.folds && foldsOnContains(m.rules, from, into), false
}

func (keyModule) outvotes(string, unit, unit) bool { return true }

func (keyModule) oneValue() bool { return false }

func (keyModule) assemble(members []Candidate, _ map[string][]unit, _ map[string][]foldAttach) Value {
	return members[0].Value
}

// termKey: the same term. A neutral term is no evidence: an "unknown" sex at
// birth never wins or outvotes a recorded one.
func termKey(v Value) (string, bool) {
	if v.Neutral {
		return "", false
	}
	return string(v.TermID), true
}

// idKey: an id is its own key; no id is no evidence.
func idKey(id []byte) (string, bool) { return string(id), len(id) > 0 }
