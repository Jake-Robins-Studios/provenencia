package sourcemetadata

import (
	"database/sql"

	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sqlbatch"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/google/uuid"
)

// Annotation is what the owner's Source type's citation formats ask of one
// head on a board: a metadata field, or the Source date or the printed page.
// The zero Annotation is none: the formats do not read the head.
type Annotation struct {
	// Need is needed or used; "" is none.
	Need citationformat.Need
	// MetElsewhere is set only on a needed head: every needed chain it heads
	// already answers at the owner or above (the Source's value standing in
	// for an empty graph value), or at a later option of the chain. A
	// marked-unknown value answers.
	MetElsewhere bool
	// Alternatives are the later options of the needed chains the head
	// heads, in chain order, without repeats. Set only on a needed head.
	Alternatives []Alternative
}

// Alternative is one option of a chain: exactly one of Field (a metadata
// field, whose row loaded) and Builtin (the bare name, "date") is set, at Level.
type Alternative struct {
	Level   vocabkey.Level
	Field   *metadatafields.Field
	Builtin string
}

// Board is one owner's entries. A Source owner's board also carries what its
// type asks of the Source date and of the printed page; every other owner's are
// none.
type Board struct {
	Entries    []WorkspaceEntry
	Date, Page Annotation
}

// CitationValue is what a stored metadata value gives a citation: its text and
// settled mark, and the unknown text its field prints. The boards' resolver and
// the renderer's both build a field's value from it.
func CitationValue(r Row, f metadatafields.Field) citationformat.Value {
	return citationformat.Value{Text: r.ValueText, Mark: r.Mark, UnknownText: f.UnknownText}
}

// CitationValues answers a format's targets from what one render or board
// loaded: a field named by id from the rows of the nearest level that holds it
// (or, when the target names a level, from that level's rows alone), and a
// built-in from Builtins. Any other target answers the zero Value: a field
// named by key (stored formats name fields by id), a built-in nothing set, a
// level with no rows. A board and a render both build it, so they cannot
// disagree about what answers. Nearest is the one place the levels are walked;
// Resolve and the boards' inherited values read it: nothing else reads Rows by
// level.
type CitationValues struct {
	// Rows holds the stored values per level, keyed by field id.
	Rows map[vocabkey.Level]map[string]Row
	// Fields holds the field rows that loaded; a value whose field row did not
	// load still answers, with no unknown text.
	Fields map[string]metadatafields.Field
	// Builtins holds the value of each built-in the caller can answer.
	Builtins map[citationformat.Target]citationformat.Value
}

// Resolve implements citationformat.Resolver.
func (v CitationValues) Resolve(t citationformat.Target) citationformat.Value {
	if t.Builtin != "" {
		return v.Builtins[t]
	}
	if !t.Field.ByID() {
		return citationformat.Value{}
	}
	id := string(t.Field.ID[:])
	if t.Level != "" {
		if row, ok := v.Rows[t.Level][id]; ok {
			return CitationValue(row, v.Fields[id])
		}
		return citationformat.Value{}
	}
	if row, ok := v.Nearest(t.Field.ID); ok {
		return CitationValue(row, v.Fields[id])
	}
	return citationformat.Value{}
}

// Nearest is the row of the nearest level that holds field id, and false when
// no level does. The first row found answers, whatever its text: a value marked
// unknown at a nearer level stops the walk. Its Owner.Level says which level
// answered.
func (v CitationValues) Nearest(id uuid.UUID) (Row, bool) {
	for _, l := range vocabkey.NearestFirst() {
		if row, ok := v.Rows[l][string(id[:])]; ok {
			return row, true
		}
	}
	return Row{}, false
}

// Without is the values as if level l held nothing: a copy whose Rows lack l
// and whose Builtins lack every target at l. It shares Fields. A board asks it
// what the levels above the owner answer.
func (v CitationValues) Without(l vocabkey.Level) CitationValues {
	out := CitationValues{
		Rows:     make(map[vocabkey.Level]map[string]Row, len(v.Rows)),
		Fields:   v.Fields,
		Builtins: make(map[citationformat.Target]citationformat.Value, len(v.Builtins)),
	}
	for level, rows := range v.Rows {
		if level != l {
			out.Rows[level] = rows
		}
	}
	for t, val := range v.Builtins {
		if t.Level != l {
			out.Builtins[t] = val
		}
	}
	return out
}

// AppendOptions appends to dst the options of a chain's targets that can be
// shown, in order, each target once across calls sharing seen: a built-in, and
// a field named by id whose row is in fields. A field named by key, and one
// whose row did not load, is skipped.
func AppendOptions(dst []Alternative, seen map[citationformat.Target]bool, targets []citationformat.Target, fields map[string]metadatafields.Field) []Alternative {
	for _, t := range targets {
		if seen[t] {
			continue
		}
		seen[t] = true
		switch {
		case t.Builtin != "":
			dst = append(dst, Alternative{Level: t.Level, Builtin: t.Builtin})
		case t.Field.ByID():
			if f, ok := fields[string(t.Field.ID[:])]; ok {
				dst = append(dst, Alternative{Level: t.Level, Field: &f})
			}
		}
	}
	return dst
}

// rowsByField keys rows by field id.
func rowsByField(rows []Row) map[string]Row {
	out := make(map[string]Row, len(rows))
	for _, r := range rows {
		out[string(r.FieldID)] = r
	}
	return out
}

// levelNeeds is what a type's formats ask at one level: each field's need, the
// fields that head a chain in order of first appearance, and the chains each
// heads. A chain is flagged on its first option (its head): empty everywhere,
// that is where the researcher fills it. Its later options are only used.
type levelNeeds struct {
	need  map[uuid.UUID]citationformat.Need
	order []uuid.UUID
	heads map[uuid.UUID][]citationformat.Requirement
	// builtinHeads holds the chains headed by the Source date and the printed
	// page, keyed by that head. It is filled only for the source level.
	builtinHeads map[citationformat.Target][]citationformat.Requirement
}

// fieldAt is the id of t when it is a field, named by id, at level: one read
// nearest-first (no level) is at every level, one the list form reads at the
// Source alone.
func fieldAt(t citationformat.Target, level vocabkey.Level) (uuid.UUID, bool) {
	if t.Builtin != "" || (t.Level != "" && t.Level != level) || !t.Field.ByID() {
		return uuid.Nil, false
	}
	return t.Field.ID, true
}

// needsAt reads the chains of one type at one level. The first option of a chain
// is its head and takes the chain's need; every later option that is a field at
// level is used. A field's need is the strongest over its chains. At the source
// level it also keeps the chains headed by the Source date and the printed page.
func needsAt(chains []citationformat.Requirement, level vocabkey.Level) levelNeeds {
	ln := levelNeeds{
		need:  map[uuid.UUID]citationformat.Need{},
		heads: map[uuid.UUID][]citationformat.Requirement{},
	}
	if level == vocabkey.LevelSource {
		ln.builtinHeads = map[citationformat.Target][]citationformat.Requirement{}
	}
	for _, ch := range chains {
		for i, t := range ch.Targets {
			id, isField := fieldAt(t, level)
			switch {
			case i > 0 && isField:
				ln.need[id] = ln.need[id].Max(citationformat.NeedUsed)
			case i > 0:
			case isField:
				if _, seen := ln.heads[id]; !seen {
					ln.order = append(ln.order, id)
				}
				ln.heads[id] = append(ln.heads[id], ch)
				ln.need[id] = ln.need[id].Max(ch.Need)
			case ln.builtinHeads != nil && (t == citationformat.SourceDate || t == citationformat.CitationPage):
				ln.builtinHeads[t] = append(ln.builtinHeads[t], ch)
			}
		}
	}
	return ln
}

// fieldIDs is every field id annotating this level can name: the heads and the
// field options after them, at any level.
func (ln levelNeeds) fieldIDs() [][]byte {
	var out [][]byte
	for _, id := range ln.order {
		out = append(out, id[:])
	}
	each := func(chains []citationformat.Requirement) {
		for _, ch := range chains {
			for _, t := range ch.Targets[1:] {
				if t.Builtin == "" && t.Field.ByID() {
					out = append(out, t.Field.ID[:])
				}
			}
		}
	}
	for _, chains := range ln.heads {
		each(chains)
	}
	for _, chains := range ln.builtinHeads {
		each(chains)
	}
	return out
}

// annotate is what the formats ask of one head. A field head (a target with no
// level) reads its need from the board's level; a built-in head from the chains
// it heads. A needed head is met elsewhere when every needed chain it heads is
// met: its own first option answers in above (the owner's levels left out), or
// it has a later option that answers in r (citationformat.Missing on the
// chain's tail, built needed because Missing skips the others). The head's own
// value at the owner is not elsewhere. The alternatives are the tails' options,
// a field only when its row loaded.
func annotate(ln levelNeeds, head citationformat.Target, r, above citationformat.Resolver, fields map[string]metadatafields.Field) Annotation {
	var need citationformat.Need
	var chains []citationformat.Requirement
	if head.Builtin != "" {
		chains = ln.builtinHeads[head]
		for _, ch := range chains {
			need = need.Max(ch.Need)
		}
	} else {
		need = ln.need[head.Field.ID]
		chains = ln.heads[head.Field.ID]
	}
	a := Annotation{Need: need}
	if need != citationformat.NeedNeeded {
		return a
	}
	a.MetElsewhere = true
	seen := map[citationformat.Target]bool{}
	for _, ch := range chains {
		if ch.Need != citationformat.NeedNeeded {
			continue
		}
		tail := ch.Targets[1:]
		first := citationformat.Missing([]citationformat.Requirement{{Targets: ch.Targets[:1], Need: citationformat.NeedNeeded}}, above)
		unmet := citationformat.Missing([]citationformat.Requirement{{Targets: tail, Need: citationformat.NeedNeeded}}, r)
		if len(first) > 0 && (len(tail) == 0 || len(unmet) > 0) {
			a.MetElsewhere = false
		}
		a.Alternatives = AppendOptions(a.Alternatives, seen, tail, fields)
	}
	return a
}

// typesIn reads the owners' Source type and Source ids at one level, calling
// fn per owner. ids are bounded by the caller as sqlbatch.Query batches them.
func typesIn(tx *sql.Tx, st *store, ids [][]byte, fn func(id, typeID, sourceID []byte)) error {
	return sqlbatch.Query(tx, st.typeIn, st.typeSuffix, nil, ids, func(rows *sql.Rows) error {
		var id, typeID, sourceID []byte
		if err := rows.Scan(&id, &typeID, &sourceID); err != nil {
			return err
		}
		fn(id, typeID, sourceID)
		return nil
	})
}

// needOfTx is how much the owner's type's formats need the field on a board at
// the owner's level. An owner that does not exist is ErrInvalid.
func needOfTx(tx *sql.Tx, st *store, owner Owner, fieldID []byte) (citationformat.Need, error) {
	var typeID []byte
	if err := typesIn(tx, st, [][]byte{owner.ID}, func(_, t, _ []byte) { typeID = t }); err != nil {
		return "", err
	}
	if typeID == nil {
		return "", ErrInvalid
	}
	reqs, err := sourcetypes.RequirementsTx(tx, [][]byte{typeID})
	if err != nil {
		return "", err
	}
	id, err := uuid.FromBytes(fieldID)
	if err != nil {
		return "", ErrInvalid
	}
	return needsAt(reqs[string(typeID)], owner.Level).need[id], nil
}
