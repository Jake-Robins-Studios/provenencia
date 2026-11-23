// Package sourcemetadata stores descriptive metadata values for an owner (a
// Source, an Artifact or an Evidence graph, which share the same functions),
// plus the per-owner layout (dismissed suggestions and field order)
// that the metadata editor reads back through ListWorkspace. Every function
// takes an Owner, a vocabkey.Level and an id; a level with no store entry is
// ErrInvalid. Set, Clear, DismissSuggestion, Reorder, CreateAll, and Apply run
// inside writes.Run and return the row changes that Run records.
package sourcemetadata

import (
	"bytes"
	"database/sql"
	"errors"
	"slices"
	"sort"
	"strings"

	"github.com/Jake-Robins-Studios/provenencia/core/apperr"
	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sources"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcevocab"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sqlbatch"
	"github.com/Jake-Robins-Studios/provenencia/core/urlshape"
	"github.com/Jake-Robins-Studios/provenencia/core/valuemark"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/google/uuid"
)

// ErrInvalid is a refused metadata request. A refused value carries its field's
// wire id as params[0], for the client to place the message on its row; it is
// never shown.
var ErrInvalid = apperr.New(apperr.CodeSourceMetadataInvalid, apperr.KindUser)

// Row is one stored metadata value.
type Row struct {
	ID        []byte
	Owner     Owner
	FieldID   []byte
	ValueText string
	// Mark says whether the value is unknown (ValueText is "") or supplied.
	Mark valuemark.Mark
}

// Input is one value of a Set or a Draft.
type Input struct {
	FieldID   []byte
	ValueText string
	Mark      valuemark.Mark
}

// Draft is what an owner's metadata form or copy holds: one value per field,
// and layout rows written as given.
type Draft struct {
	Values []Input     // one per field
	Layout []LayoutRow // written verbatim
}

// WorkspaceEntry is a suggested, headed or extra field for the owner's edit UI:
// a field the type suggests, one its citation formats head, or a stored value.
type WorkspaceEntry struct {
	Field metadatafields.Field
	Value *Row // nil when suggested or headed but unset
	// Suggested is true when the type suggests the field; a
	// field only its formats head is not suggested.
	Suggested bool
	// Annotation is what the type's citation formats ask of the field.
	Annotation Annotation
	// SortOrder is the position ListWorkspace returned the entry in: the
	// layout order once the owner has any layout row, otherwise the type's
	// suggestion order (0 for extras).
	SortOrder int
	// Inherited is the row of the nearest level above the owner that holds the
	// field (CitationValues.Nearest), whether or not the entry has a value of
	// its own; nil when nothing above holds it.
	Inherited *Row
	// StaysWithoutValue is true when the board keeps the entry with no value of
	// its own: the type suggests the field, or its formats head it.
	StaysWithoutValue bool
}

// OpenHref is the web link to open for this entry's own value: the
// browser-ready form of a url-typed value (urlshape.OpenHref), or "" when the
// entry has no value, is not a url field, or holds a value that is not a web
// address (a damaged row).
func (e WorkspaceEntry) OpenHref() string {
	return openHref(e.Field, e.Value)
}

// InheritedOpenHref is OpenHref for the inherited value.
func (e WorkspaceEntry) InheritedOpenHref() string {
	return openHref(e.Field, e.Inherited)
}

func openHref(f metadatafields.Field, r *Row) string {
	if r == nil || f.DataType != metadatafields.DataTypeURL {
		return ""
	}
	href, err := urlshape.OpenHref(r.ValueText)
	if err != nil {
		return ""
	}
	return href
}

// LayoutRow is one layout row for a field.
type LayoutRow struct {
	FieldID   []byte
	SortOrder int
	Dismissed bool
}

// Set upserts a metadata value for (owner, field). The caller records the
// returned changes. An unchanged value returns the existing row and no changes.
// A refused mark is valuemark.ErrInvalid and any other refused value is
// ErrInvalid, each naming its field.
func Set(tx *database.Tx, userID []byte, owner Owner, in Input) (Row, []rowchange.Change, error) {
	st, err := storeFor(owner)
	if err != nil {
		return Row{}, nil, err
	}
	if tx == nil || len(in.FieldID) != 16 {
		return Row{}, nil, ErrInvalid
	}
	if err := database.RequireUserID(userID, ErrInvalid); err != nil {
		return Row{}, nil, err
	}

	if err := requireOwner(tx.Tx, st, owner); err != nil {
		return Row{}, nil, err
	}
	fields, err := loadFields(tx.Tx, [][]byte{in.FieldID})
	if err != nil {
		return Row{}, nil, err
	}
	field := fields[string(in.FieldID)]

	normalized, err := normalizeFor(field, in.ValueText, in.Mark)
	if err != nil {
		return Row{}, nil, err
	}

	prev, err := getPairTx(tx.Tx, st, owner, in.FieldID)
	creating := errors.Is(err, sql.ErrNoRows)
	if err != nil && !creating {
		return Row{}, nil, err
	}
	var prevRow *Row
	if !creating {
		prevRow = &prev
	}

	row, change, err := putValueTx(tx.Tx, st, owner, prevRow, field.ID, normalized, in.Mark)
	if err != nil {
		return Row{}, nil, err
	}
	if change == nil {
		return row, nil, nil
	}
	if creating {
		// A field the researcher just filled needs a place in the owner's
		// order; appending keeps an existing hand-sorted layout intact.
		if _, err := tx.Exec(st.layoutAppend, owner.ID, in.FieldID, owner.ID); err != nil {
			return Row{}, nil, mapConstraint(err)
		}
	}
	return row, []rowchange.Change{*change}, nil
}

// putValueTx writes the already normalized text and mark as the owner's value
// for the field: an insert when prev is nil, nothing (prev and a nil change)
// when the text and mark are equal, an update otherwise. It writes no layout
// row; Set appends one and CreateAll writes the caller's.
func putValueTx(tx *sql.Tx, st *store, owner Owner, prev *Row, fieldID []byte, normalized string, mark valuemark.Mark) (Row, *rowchange.Change, error) {
	if prev == nil {
		row, change, err := insertValueTx(tx, st, owner, fieldID, normalized, mark)
		if err != nil {
			return Row{}, nil, err
		}
		return row, &change, nil
	}
	if prev.ValueText == normalized && prev.Mark == mark {
		return *prev, nil, nil
	}
	return updateValueTx(tx, st, *prev, normalized, mark)
}

// auditFields is a value row as change columns: every column, so a create, a
// delete here and a facet release of the row (deleteimpact) read alike. An
// unknown row's value_text is nil.
func auditFields(st *store, r Row) map[string]any {
	return map[string]any{
		"id":           database.UUIDString(r.ID),
		st.ownerColumn: database.UUIDString(r.Owner.ID),
		"field_id":     database.UUIDString(r.FieldID),
		"value_text":   database.NullString(r.ValueText),
		"is_unknown":   r.Mark.Unknown,
		"is_supplied":  r.Mark.Supplied,
	}
}

// insertValueTx inserts the already normalized text and mark as the owner's
// value for the field and returns the row with its create change.
func insertValueTx(tx *sql.Tx, st *store, owner Owner, fieldID []byte, normalized string, mark valuemark.Mark) (Row, rowchange.Change, error) {
	id, err := uuid.NewV7()
	if err != nil {
		return Row{}, rowchange.Change{}, err
	}
	idBytes := id[:]
	if _, err := tx.Exec(st.insert, idBytes, owner.ID, fieldID, database.NullString(normalized), boolInt(mark.Unknown), boolInt(mark.Supplied)); err != nil {
		return Row{}, rowchange.Change{}, mapConstraint(err)
	}
	row := Row{
		ID:        append([]byte(nil), idBytes...),
		Owner:     Owner{Level: owner.Level, ID: append([]byte(nil), owner.ID...)},
		FieldID:   append([]byte(nil), fieldID...),
		ValueText: normalized,
		Mark:      mark,
	}
	return row, rowchange.Created(st.values, row.ID, auditFields(st, row)), nil
}

// updateValueTx writes the new, already normalized text and mark over prev's
// row. Its change carries only the columns that differ.
func updateValueTx(tx *sql.Tx, st *store, prev Row, normalized string, mark valuemark.Mark) (Row, *rowchange.Change, error) {
	if _, err := tx.Exec(st.update, database.NullString(normalized), boolInt(mark.Unknown), boolInt(mark.Supplied), prev.ID); err != nil {
		return Row{}, nil, mapConstraint(err)
	}
	row := Row{
		ID:        append([]byte(nil), prev.ID...),
		Owner:     Owner{Level: prev.Owner.Level, ID: append([]byte(nil), prev.Owner.ID...)},
		FieldID:   append([]byte(nil), prev.FieldID...),
		ValueText: normalized,
		Mark:      mark,
	}
	return row, rowchange.Updated(st.values, row.ID, auditFields(st, prev), auditFields(st, row)), nil
}

// deleteValueTx deletes prev's row and returns its delete change.
func deleteValueTx(tx *sql.Tx, st *store, prev Row) (rowchange.Change, error) {
	if _, err := tx.Exec(st.delete, prev.Owner.ID, prev.FieldID); err != nil {
		return rowchange.Change{}, err
	}
	return rowchange.Deleted(st.values, prev.ID, auditFields(st, prev)), nil
}

// layoutChange builds every layout row change: the owner column and field_id
// are always written ({nil, id} on a create, {id, id} on an update, the shape
// effects scopes by), with diffs beside them. EntityID is the field id.
func layoutChange(st *store, owner Owner, fieldID []byte, action string, diffs map[string]rowchange.FieldDiff) rowchange.Change {
	ownerID, field := database.UUIDString(owner.ID), database.UUIDString(fieldID)
	fields := make(map[string]rowchange.FieldDiff, len(diffs)+2)
	if action == rowchange.ActionCreate {
		fields[st.ownerColumn] = rowchange.FieldDiff{Old: nil, New: ownerID}
		fields["field_id"] = rowchange.FieldDiff{Old: nil, New: field}
	} else {
		fields[st.ownerColumn] = rowchange.FieldDiff{Old: ownerID, New: ownerID}
		fields["field_id"] = rowchange.FieldDiff{Old: field, New: field}
	}
	for k, v := range diffs {
		fields[k] = v
	}
	return rowchange.Change{
		EntityType: st.layout,
		EntityID:   append([]byte(nil), fieldID...),
		Action:     action,
		Fields:     fields,
	}
}

// insertLayoutTx writes a layout row as given and returns its create change.
func insertLayoutTx(tx *sql.Tx, st *store, owner Owner, l LayoutRow) (rowchange.Change, error) {
	if _, err := tx.Exec(st.layoutInsert, owner.ID, l.FieldID, l.SortOrder, boolInt(l.Dismissed)); err != nil {
		return rowchange.Change{}, mapConstraint(err)
	}
	return layoutChange(st, owner, l.FieldID, rowchange.ActionCreate, map[string]rowchange.FieldDiff{
		"sort_order": {Old: nil, New: l.SortOrder},
		"dismissed":  {Old: nil, New: l.Dismissed},
	}), nil
}

// updateLayoutTx writes next over prev's layout row and returns its update
// change, which carries only the columns that differ.
func updateLayoutTx(tx *sql.Tx, st *store, owner Owner, prev, next LayoutRow) (rowchange.Change, error) {
	if _, err := tx.Exec(st.layoutUpdate, next.SortOrder, boolInt(next.Dismissed), owner.ID, next.FieldID); err != nil {
		return rowchange.Change{}, mapConstraint(err)
	}
	diffs := map[string]rowchange.FieldDiff{}
	if prev.SortOrder != next.SortOrder {
		diffs["sort_order"] = rowchange.FieldDiff{Old: prev.SortOrder, New: next.SortOrder}
	}
	if prev.Dismissed != next.Dismissed {
		diffs["dismissed"] = rowchange.FieldDiff{Old: prev.Dismissed, New: next.Dismissed}
	}
	return layoutChange(st, owner, next.FieldID, rowchange.ActionUpdate, diffs), nil
}

// CreateAll writes values and layout rows verbatim onto an owner that has
// neither, so a copy reads back in the original's order with the original's
// dismissed flags. Unlike Set it appends no layout row of its own. It is Apply
// on an empty owner: changes are the value changes in input order, then the
// layout changes in input order. The caller records them.
func CreateAll(tx *database.Tx, userID []byte, owner Owner, d Draft) ([]rowchange.Change, error) {
	st, err := storeFor(owner)
	if err != nil {
		return nil, err
	}
	if tx == nil {
		return nil, ErrInvalid
	}
	if err := database.RequireUserID(userID, ErrInvalid); err != nil {
		return nil, err
	}
	if len(d.Values) == 0 && len(d.Layout) == 0 {
		return nil, nil
	}
	have, err := readOwnerTx(tx.Tx, st, owner)
	if err != nil {
		return nil, err
	}
	if len(have.values) > 0 || len(have.layout) > 0 {
		return nil, ErrInvalid
	}
	return apply(tx, userID, st, owner, have, d)
}

// Apply saves a draft: it makes the owner's stored values equal d.Values and
// makes each layout row d.Layout lists equal that row, as given. A value the
// draft leaves out is deleted (an empty draft clears every value); a layout row
// the draft leaves out stays, so a draft never undoes a dismiss by omission.
// Apply appends no layout row for a new value: a caller with a board sends the
// whole order as d.Layout. Only differing rows are written. The caller records
// the returned changes. A refused mark is valuemark.ErrInvalid and any other
// refused value is ErrInvalid, each naming its field (the first in draft
// order); any other refusal is a bare ErrInvalid.
func Apply(tx *database.Tx, userID []byte, owner Owner, d Draft) ([]rowchange.Change, error) {
	st, err := storeFor(owner)
	if err != nil {
		return nil, err
	}
	if tx == nil {
		return nil, ErrInvalid
	}
	have, err := readOwnerTx(tx.Tx, st, owner)
	if err != nil {
		return nil, err
	}
	return apply(tx, userID, st, owner, have, d)
}

// checkFieldIDs is ErrInvalid unless every id is 16 bytes and listed once. It
// returns the set of ids.
func checkFieldIDs(ids [][]byte) (map[string]struct{}, error) {
	seen := make(map[string]struct{}, len(ids))
	for _, id := range ids {
		if len(id) != 16 {
			return nil, ErrInvalid
		}
		if _, dup := seen[string(id)]; dup {
			return nil, ErrInvalid
		}
		seen[string(id)] = struct{}{}
	}
	return seen, nil
}

// apply checks the whole draft before it writes anything, then writes the
// value changes (deletes in field-id order, then inserts and updates in draft
// order) and the layout changes (inserts and updates in draft order).
func apply(tx *database.Tx, userID []byte, st *store, owner Owner, have stored, d Draft) ([]rowchange.Change, error) {
	if tx == nil {
		return nil, ErrInvalid
	}
	if err := database.RequireUserID(userID, ErrInvalid); err != nil {
		return nil, err
	}
	if err := requireOwner(tx.Tx, st, owner); err != nil {
		return nil, err
	}

	valueIDs := make([][]byte, len(d.Values))
	for i, in := range d.Values {
		valueIDs[i] = in.FieldID
	}
	inValues, err := checkFieldIDs(valueIDs)
	if err != nil {
		return nil, err
	}
	layoutIDs := make([][]byte, len(d.Layout))
	for i, l := range d.Layout {
		layoutIDs[i] = l.FieldID
	}
	if _, err := checkFieldIDs(layoutIDs); err != nil {
		return nil, err
	}
	ids := append(valueIDs, layoutIDs...)
	var fields map[string]metadatafields.Field
	if len(ids) > 0 {
		if fields, err = loadFields(tx.Tx, ids); err != nil {
			return nil, err
		}
	}
	normalized := make([]string, len(d.Values))
	for i, in := range d.Values {
		n, err := normalizeFor(fields[string(in.FieldID)], in.ValueText, in.Mark)
		if err != nil {
			return nil, err
		}
		normalized[i] = n
	}

	haveValue := make(map[string]Row, len(have.values))
	for _, r := range have.values {
		haveValue[string(r.FieldID)] = r
	}
	haveLayout := make(map[string]LayoutRow, len(have.layout))
	for _, l := range have.layout {
		haveLayout[string(l.FieldID)] = l
	}

	var changes []rowchange.Change
	for _, prev := range have.values {
		if _, kept := inValues[string(prev.FieldID)]; kept {
			continue
		}
		change, err := deleteValueTx(tx.Tx, st, prev)
		if err != nil {
			return nil, err
		}
		changes = append(changes, change)
	}
	for i, in := range d.Values {
		var prevRow *Row
		if prev, ok := haveValue[string(in.FieldID)]; ok {
			prevRow = &prev
		}
		_, change, err := putValueTx(tx.Tx, st, owner, prevRow, in.FieldID, normalized[i], in.Mark)
		if err != nil {
			return nil, err
		}
		if change != nil {
			changes = append(changes, *change)
		}
	}
	for _, l := range d.Layout {
		prev, ok := haveLayout[string(l.FieldID)]
		switch {
		case !ok:
			change, err := insertLayoutTx(tx.Tx, st, owner, l)
			if err != nil {
				return nil, err
			}
			changes = append(changes, change)
		case prev.SortOrder != l.SortOrder || prev.Dismissed != l.Dismissed:
			change, err := updateLayoutTx(tx.Tx, st, owner, prev, l)
			if err != nil {
				return nil, err
			}
			changes = append(changes, change)
		}
	}
	return changes, nil
}

// Clear deletes the metadata row for (owner, field) when one exists. A missing
// row, or a missing owner, returns no changes. The caller records the returned
// changes.
func Clear(tx *database.Tx, userID []byte, owner Owner, fieldID []byte) ([]rowchange.Change, error) {
	st, err := storeFor(owner)
	if err != nil {
		return nil, err
	}
	if tx == nil || len(fieldID) != 16 {
		return nil, ErrInvalid
	}
	if err := database.RequireUserID(userID, ErrInvalid); err != nil {
		return nil, err
	}

	prev, err := getPairTx(tx.Tx, st, owner, fieldID)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	change, err := deleteValueTx(tx.Tx, st, prev)
	if err != nil {
		return nil, err
	}
	return []rowchange.Change{change}, nil
}

// DismissSuggestion hides one empty field of an owner's board for that owner:
// a suggestion, or a field the type's citation formats read. The caller records
// the returned changes.
//
// A field the formats need is refused (ErrInvalid, with the field's wire id as
// params[0]): a needed field always shows. A field that already holds a value
// stays visible, so the call is a no-op rather than an error, and so is an
// already-dismissed field; both return no changes. Any other empty field is
// dismissed.
func DismissSuggestion(tx *database.Tx, userID []byte, owner Owner, fieldID []byte) ([]rowchange.Change, error) {
	st, err := storeFor(owner)
	if err != nil {
		return nil, err
	}
	if tx == nil || len(fieldID) != 16 {
		return nil, ErrInvalid
	}
	if err := database.RequireUserID(userID, ErrInvalid); err != nil {
		return nil, err
	}

	if err := requireOwner(tx.Tx, st, owner); err != nil {
		return nil, err
	}
	if _, err := loadFields(tx.Tx, [][]byte{fieldID}); err != nil {
		return nil, err
	}

	_, err = getPairTx(tx.Tx, st, owner, fieldID)
	switch {
	case err == nil:
		return nil, nil
	case !errors.Is(err, sql.ErrNoRows):
		return nil, err
	}

	need, err := needOfTx(tx.Tx, st, owner, fieldID)
	if err != nil {
		return nil, err
	}
	if need == citationformat.NeedNeeded {
		return nil, ErrInvalid.WithParams(database.UUIDString(fieldID))
	}

	prev, err := getLayoutTx(tx.Tx, st, owner, fieldID)
	had := true
	if errors.Is(err, sql.ErrNoRows) {
		had = false
	} else if err != nil {
		return nil, err
	}
	if had && prev.Dismissed {
		return nil, nil
	}

	if _, err := tx.Exec(st.layoutDismiss, owner.ID, fieldID, owner.ID); err != nil {
		return nil, mapConstraint(err)
	}
	action := rowchange.ActionCreate
	var oldDismissed any
	if had {
		action = rowchange.ActionUpdate
		oldDismissed = false
	}
	return []rowchange.Change{layoutChange(st, owner, fieldID, action, map[string]rowchange.FieldDiff{
		"dismissed": {Old: oldDismissed, New: true},
	})}, nil
}

// Reorder rewrites the owner's field order as 0..n-1 over fieldIDs. The caller
// records the returned changes. Fields left out of the list keep their rows and
// sort after the listed ones in ListWorkspace. Dismissed flags are preserved.
// An order that already matches returns no changes.
func Reorder(tx *database.Tx, userID []byte, owner Owner, fieldIDs [][]byte) ([]rowchange.Change, error) {
	st, err := storeFor(owner)
	if err != nil {
		return nil, err
	}
	if tx == nil || len(fieldIDs) == 0 {
		return nil, ErrInvalid
	}
	if err := database.RequireUserID(userID, ErrInvalid); err != nil {
		return nil, err
	}
	if _, err := checkFieldIDs(fieldIDs); err != nil {
		return nil, err
	}

	if err := requireOwner(tx.Tx, st, owner); err != nil {
		return nil, err
	}
	if _, err := loadFields(tx.Tx, fieldIDs); err != nil {
		return nil, err
	}

	var changes []rowchange.Change
	for i, fieldID := range fieldIDs {
		prev, err := getLayoutTx(tx.Tx, st, owner, fieldID)
		had := true
		if errors.Is(err, sql.ErrNoRows) {
			had = false
		} else if err != nil {
			return nil, err
		}
		if had && prev.SortOrder == i {
			continue
		}
		if _, err := tx.Exec(st.layoutOrder, owner.ID, fieldID, i); err != nil {
			return nil, mapConstraint(err)
		}
		action := rowchange.ActionCreate
		var oldOrder any
		if had {
			action = rowchange.ActionUpdate
			oldOrder = prev.SortOrder
		}
		changes = append(changes, layoutChange(st, owner, fieldID, action, map[string]rowchange.FieldDiff{
			"sort_order": {Old: oldOrder, New: i},
		}))
	}
	return changes, nil
}

// stored is what an owner holds, with the row ids and old text the change rows
// need: values by field id, layout by sort_order then field id.
type stored struct {
	values []Row
	layout []LayoutRow
}

// readOwnerTx reads what the owner holds. It reads rows, not the owner, so a
// missing owner holds nothing.
func readOwnerTx(tx *sql.Tx, st *store, owner Owner) (stored, error) {
	owners := []Owner{owner}
	values, err := listByOwners(tx, owners)
	if err != nil {
		return stored{}, err
	}
	layout, err := listLayoutByOwners(tx, owners)
	if err != nil {
		return stored{}, err
	}
	return stored{values: values, layout: layout[owner.key()]}, nil
}

// ReadDraftTx returns what the owner holds as a Draft: its values in field-id
// order and its layout rows by sort_order then field id. An owner with no row
// holds nothing, so the Draft is empty and there is no error.
func ReadDraftTx(tx *sql.Tx, owner Owner) (Draft, error) {
	drafts, err := ReadDraftsTx(tx, []Owner{owner})
	if err != nil {
		return Draft{}, err
	}
	return drafts[0], nil
}

// ReadDraftsTx is ReadDraftTx over many owners in one read of values and one of
// layout per level: the draft at index i is owners[i]'s, and a repeated owner
// gets the same draft. No owners returns nil without a query. An owner at a
// level with no store is ErrInvalid before any query.
func ReadDraftsTx(tx *sql.Tx, owners []Owner) ([]Draft, error) {
	for _, o := range owners {
		if _, err := storeFor(o); err != nil {
			return nil, err
		}
	}
	if tx == nil {
		return nil, ErrInvalid
	}
	if len(owners) == 0 {
		return nil, nil
	}
	values, err := readByOwners(tx, owners)
	if err != nil {
		return nil, err
	}
	layout, err := listLayoutByOwners(tx, owners)
	if err != nil {
		return nil, err
	}
	held := make(map[string][]Input, len(owners))
	for _, v := range values {
		held[v.Owner.key()] = append(held[v.Owner.key()], Input{FieldID: v.FieldID, ValueText: v.ValueText, Mark: v.Mark})
	}
	out := make([]Draft, len(owners))
	for i, o := range owners {
		out[i] = Draft{Values: held[o.key()], Layout: layout[o.key()]}
	}
	return out, nil
}

// ListByOwnersTx returns the values of many owners on an open transaction,
// each mark settled for its text (readByOwners), one query per level: each
// owner's rows by field id, the owners in the order of their ids within a
// level, each row carrying its Owner. A repeated owner counts once. No owners
// returns nil without a query. An owner at a level with no store is ErrInvalid
// before any query.
func ListByOwnersTx(tx *sql.Tx, owners []Owner) ([]Row, error) {
	for _, o := range owners {
		if _, err := storeFor(o); err != nil {
			return nil, err
		}
	}
	if tx == nil {
		return nil, ErrInvalid
	}
	if len(owners) == 0 {
		return nil, nil
	}
	return readByOwners(tx, owners)
}

// readByOwners is listByOwners as a read returns it: each row's mark settled
// for its text (valuemark.Settle), blank text counting as none, as normalizeFor
// counts it. The writes read listByOwners, so their changes diff against the
// stored pair.
func readByOwners(q database.Querier, owners []Owner) ([]Row, error) {
	rows, err := listByOwners(q, owners)
	for i := range rows {
		rows[i].Mark = valuemark.Settle(rows[i].Mark, strings.TrimSpace(rows[i].ValueText) != "")
	}
	return rows, err
}

// listByOwners reads the stored values of the owners, one query per level, each
// owner's rows by field id. The owners must already have passed storeFor.
func listByOwners(q database.Querier, owners []Owner) ([]Row, error) {
	var out []Row
	err := eachLevel(owners, func(st *store, ids [][]byte) error {
		return sqlbatch.Query(q, st.listIn, st.listSuffix, nil, ids, func(rows *sql.Rows) error {
			r, err := scanRow(rows, st)
			if err != nil {
				return err
			}
			out = append(out, r)
			return nil
		})
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}

// listLayoutByOwners reads the layout rows of the owners, one query per level
// and batch, keyed by Owner.key and ordered by sort_order then field id. The
// owners must already have passed storeFor.
func listLayoutByOwners(q database.Querier, owners []Owner) (map[string][]LayoutRow, error) {
	out := make(map[string][]LayoutRow)
	err := eachLevel(owners, func(st *store, ids [][]byte) error {
		return sqlbatch.Query(q, st.layoutListIn, st.layoutListSuffix, nil, ids, func(rows *sql.Rows) error {
			var ownerID []byte
			var l LayoutRow
			var dismissed int
			if err := rows.Scan(&ownerID, &l.FieldID, &l.SortOrder, &dismissed); err != nil {
				return err
			}
			l.Dismissed = dismissed == 1
			k := Owner{Level: st.level, ID: ownerID}.key()
			out[k] = append(out[k], l)
			return nil
		})
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}

// eachLevel calls fn for each level that keeps metadata and has owners, with
// the level's store and its distinct owner ids in byte order. SQLite orders
// BLOBs by memcmp, so a query that orders by owner id, run batch by batch over
// these ids, returns rows in one order across the batches.
func eachLevel(owners []Owner, fn func(st *store, ids [][]byte) error) error {
	for _, level := range vocabkey.MetadataLevels() {
		st := stores[level]
		if st == nil {
			continue
		}
		ids := idsAt(owners, level)
		if len(ids) == 0 {
			continue
		}
		sort.Slice(ids, func(i, j int) bool { return bytes.Compare(ids[i], ids[j]) < 0 })
		if err := fn(st, ids); err != nil {
			return err
		}
	}
	return nil
}

// idsAt is the distinct ids of the owners at one level.
func idsAt(owners []Owner, level vocabkey.Level) [][]byte {
	var ids [][]byte
	for _, o := range owners {
		if o.Level == level {
			ids = append(ids, o.ID)
		}
	}
	return database.UniqueBlobIDs(ids)
}

// ListWorkspace returns the owner's board entries: the type's suggestions, the
// fields its citation formats head, and any extra stored values, filtered and
// ordered by the owner's layout. A missing owner is ErrInvalid.
//
// A dismissed field is omitted while it holds no value, unless its formats need
// it. Once the owner has any layout row the entries come back in layout order,
// with fields that have no row yet sorting after them in suggestion, head, then
// extra order; an owner with no layout at all keeps that original order. Each
// entry carries what the formats ask of it (Annotation).
func ListWorkspace(c *database.Catalog, owner Owner) ([]WorkspaceEntry, error) {
	boards, err := ListWorkspaces(c, []Owner{owner})
	if err != nil {
		return nil, err
	}
	return boards[0].Entries, nil
}

// ListWorkspaces is ListWorkspace over many owners in one read transaction: the
// board at index i is owners[i]'s, and a repeated owner gets the same board. A
// Source owner's board also carries what its type asks of the Source date and
// the printed page. No owners returns nil without opening a transaction. An
// owner at a level with no store, or one that does not exist, is ErrInvalid.
func ListWorkspaces(c *database.Catalog, owners []Owner) ([]Board, error) {
	for _, o := range owners {
		if _, err := storeFor(o); err != nil {
			return nil, err
		}
	}
	if len(owners) == 0 {
		return nil, nil
	}
	db, err := c.DB()
	if err != nil {
		return nil, err
	}
	tx, err := db.Begin()
	if err != nil {
		return nil, err
	}
	defer func() { _ = tx.Rollback() }()
	byOwner, err := listWorkspaces(tx, owners)
	if err != nil {
		return nil, err
	}
	out := make([]Board, len(owners))
	for i, o := range owners {
		out[i] = byOwner[o.key()]
	}
	return out, nil
}

// ListDraftWorkspace is the board a new Artifact or graph starts with on the
// Source: the type's suggestions, empty, then the fields its formats
// head there, each annotated against the Source's values and date. Any other
// level, or a Source that does not exist, is ErrInvalid.
func ListDraftWorkspace(c *database.Catalog, sourceID []byte, level vocabkey.Level) ([]WorkspaceEntry, error) {
	if level != vocabkey.LevelArtifact && level != vocabkey.LevelGraph {
		return nil, ErrInvalid
	}
	if len(sourceID) != 16 {
		return nil, ErrInvalid
	}
	db, err := c.DB()
	if err != nil {
		return nil, err
	}
	tx, err := db.Begin()
	if err != nil {
		return nil, err
	}
	defer func() { _ = tx.Rollback() }()

	src, err := sources.Lookup(tx, sourceID)
	if errors.Is(err, sources.ErrNotFound) {
		return nil, ErrInvalid
	} else if err != nil {
		return nil, err
	}
	rows, err := readByOwners(tx, []Owner{{Level: vocabkey.LevelSource, ID: sourceID}})
	if err != nil {
		return nil, err
	}
	k := typeLevel{string(src.SourceTypeID), level}
	needs, suggestionsOf, err := readTypeNeedsAndSuggestions(tx, []typeLevel{k})
	if err != nil {
		return nil, err
	}
	ln := needs[k]
	fields, err := metadatafields.MapByIDsTx(tx, ln.fieldIDs())
	if err != nil {
		return nil, err
	}
	// The draft owner has no rows, so what is above it is everything there is.
	r := CitationValues{
		Rows:     map[vocabkey.Level]map[string]Row{vocabkey.LevelSource: rowsByField(rows)},
		Fields:   fields,
		Builtins: map[citationformat.Target]citationformat.Value{citationformat.SourceDate: sources.CitationDate(src)},
	}
	return buildEntries(boardInput{
		suggestions: suggestionsOf[k.typeID],
		needs:       ln,
		fields:      fields,
		resolver:    r,
		above:       r,
	}), nil
}

// typeLevel keys what is read once per Source type and level.
type typeLevel struct {
	typeID string
	level  vocabkey.Level
}

// readTypeNeedsAndSuggestions reads the formats' requirements of every distinct type once,
// the needs of each distinct (type, level), and the suggestions of every
// distinct type in one read: a type's one list is every board's suggestions at
// every level, keyed by string(type id), a type with none absent.
func readTypeNeedsAndSuggestions(tx *sql.Tx, keys []typeLevel) (map[typeLevel]levelNeeds, map[string][]sourcevocab.Suggestion, error) {
	var typeIDs [][]byte
	seenType := make(map[string]struct{}, len(keys))
	for _, k := range keys {
		if _, dup := seenType[k.typeID]; !dup {
			seenType[k.typeID] = struct{}{}
			typeIDs = append(typeIDs, []byte(k.typeID))
		}
	}
	reqs, err := sourcetypes.RequirementsTx(tx, typeIDs)
	if err != nil {
		return nil, nil, err
	}
	suggestionsOf, err := sourcevocab.ListSuggestionsTx(tx, typeIDs)
	if err != nil {
		return nil, nil, err
	}
	needs := make(map[typeLevel]levelNeeds, len(keys))
	for _, k := range keys {
		if _, ok := needs[k]; !ok {
			needs[k] = needsAt(reqs[k.typeID], k.level)
		}
	}
	return needs, suggestionsOf, nil
}

// listWorkspaces is ListWorkspace over many owners, keyed by Owner.key: each
// level's types and Sources in one query, the suggestions once per distinct
// type, the formats' requirements and their heads once per distinct
// (type, level), the values of the owners and of their Sources, the layout,
// each distinct Source, and every field a board names in one read each.
func listWorkspaces(tx *sql.Tx, owners []Owner) (map[string]Board, error) {
	var uniq []Owner
	seenOwner := make(map[string]struct{}, len(owners))
	for _, o := range owners {
		if _, err := storeFor(o); err != nil {
			return nil, err
		}
		if _, dup := seenOwner[o.key()]; dup {
			continue
		}
		seenOwner[o.key()] = struct{}{}
		uniq = append(uniq, o)
	}

	typeOf := make(map[string][]byte, len(uniq))
	sourceOf := make(map[string][]byte, len(uniq))
	err := eachLevel(uniq, func(st *store, ids [][]byte) error {
		return typesIn(tx, st, ids, func(id, typeID, sourceID []byte) {
			k := Owner{Level: st.level, ID: id}.key()
			typeOf[k] = typeID
			sourceOf[k] = sourceID
		})
	})
	if err != nil {
		return nil, err
	}

	keys := make([]typeLevel, 0, len(uniq))
	for _, o := range uniq {
		typeID, ok := typeOf[o.key()]
		if !ok {
			return nil, ErrInvalid
		}
		keys = append(keys, typeLevel{string(typeID), o.Level})
	}
	needsOf, suggestionsOf, err := readTypeNeedsAndSuggestions(tx, keys)
	if err != nil {
		return nil, err
	}

	// The Sources' values answer a graph's or an Artifact's chains, so each
	// distinct Source joins the one values read unless a board already asks.
	all := slices.Clone(uniq)
	for _, o := range uniq {
		so := Owner{Level: vocabkey.LevelSource, ID: sourceOf[o.key()]}
		if _, dup := seenOwner[so.key()]; !dup {
			seenOwner[so.key()] = struct{}{}
			all = append(all, so)
		}
	}
	valueRows, err := readByOwners(tx, all)
	if err != nil {
		return nil, err
	}
	valuesOf := GroupByOwner(valueRows)
	var sourceIDs [][]byte
	for _, o := range uniq {
		sourceIDs = append(sourceIDs, sourceOf[o.key()])
	}
	srcs, err := sources.GetManyTx(tx, sourceIDs)
	if err != nil {
		return nil, err
	}
	dateOf := make(map[string]citationformat.Value, len(srcs))
	for _, o := range uniq {
		id := sourceOf[o.key()]
		src, ok := srcs[string(id)]
		if !ok {
			return nil, sources.ErrNotFound
		}
		dateOf[string(id)] = sources.CitationDate(src)
	}
	layoutOf, err := listLayoutByOwners(tx, uniq)
	if err != nil {
		return nil, err
	}

	var extraIDs [][]byte
	for _, o := range uniq {
		inSuggestions := make(map[string]struct{})
		for _, s := range suggestionsOf[string(typeOf[o.key()])] {
			inSuggestions[string(s.Field.ID)] = struct{}{}
		}
		for _, v := range valuesOf[o.key()] {
			if _, ok := inSuggestions[string(v.FieldID)]; !ok {
				extraIDs = append(extraIDs, v.FieldID)
			}
		}
	}
	wanted := slices.Clone(extraIDs)
	for _, ln := range needsOf {
		wanted = append(wanted, ln.fieldIDs()...)
	}
	fields, err := metadatafields.MapByIDsTx(tx, wanted)
	if err != nil {
		return nil, err
	}
	if err := requireFields(fields, extraIDs); err != nil {
		return nil, err
	}

	out := make(map[string]Board, len(uniq))
	for _, o := range uniq {
		k := typeLevel{string(typeOf[o.key()]), o.Level}
		ln := needsOf[k]
		r := CitationValues{
			Rows: map[vocabkey.Level]map[string]Row{
				o.Level:              valuesOf.Of(o),
				vocabkey.LevelSource: valuesOf.Of(Owner{Level: vocabkey.LevelSource, ID: sourceOf[o.key()]}),
			},
			Fields:   fields,
			Builtins: map[citationformat.Target]citationformat.Value{citationformat.SourceDate: dateOf[string(sourceOf[o.key()])]},
		}
		above := r.Without(o.Level)
		board := Board{Entries: buildEntries(boardInput{
			suggestions: suggestionsOf[k.typeID],
			values:      valuesOf[o.key()],
			layout:      layoutOf[o.key()],
			needs:       ln,
			fields:      fields,
			resolver:    r,
			above:       above,
		})}
		if o.Level == vocabkey.LevelSource {
			board.Date = annotate(ln, citationformat.SourceDate, r, above, fields)
			board.Page = annotate(ln, citationformat.CitationPage, r, above, fields)
		}
		out[o.key()] = board
	}
	return out, nil
}

// boardInput is what one owner's board is built from.
type boardInput struct {
	suggestions []sourcevocab.Suggestion
	values      []Row
	layout      []LayoutRow
	needs       levelNeeds
	// fields holds the rows of the extras' fields and of the heads and
	// alternatives the formats name; a head with no row is dropped.
	fields   map[string]metadatafields.Field
	resolver citationformat.Resolver
	// above answers as the resolver does with the owner's own level left out:
	// what the owner's ancestors hold.
	above CitationValues
}

// buildEntries is the owner's board at one level: the type's suggestions, then
// each field the formats head that is neither suggested nor valued (empty), then
// the valued extras, each once and each annotated; a dismissed field with no
// value is left out unless its formats need it; then the layout's order.
func buildEntries(in boardInput) []WorkspaceEntry {
	layoutRows := make(map[string]LayoutRow, len(in.layout))
	maxOrder := -1
	for _, l := range in.layout {
		layoutRows[string(l.FieldID)] = l
		if l.SortOrder > maxOrder {
			maxOrder = l.SortOrder
		}
	}
	byField := rowsByField(in.values)
	annotation := func(fieldID []byte) Annotation {
		id, err := uuid.FromBytes(fieldID)
		if err != nil {
			return Annotation{}
		}
		return annotate(in.needs, citationformat.Target{Field: citationformat.FieldRef{ID: id}}, in.resolver, in.above, in.fields)
	}
	// place sets what every emitted entry carries beside its own value.
	place := func(e WorkspaceEntry) WorkspaceEntry {
		id, err := uuid.FromBytes(e.Field.ID)
		if err != nil {
			return e
		}
		if row, ok := in.above.Nearest(id); ok {
			e.Inherited = &row
		}
		_, head := in.needs.heads[id]
		e.StaysWithoutValue = e.Suggested || head
		return e
	}
	hidden := func(key string, note Annotation) bool {
		return note.Need != citationformat.NeedNeeded && layoutRows[key].Dismissed
	}

	entries := make([]WorkspaceEntry, 0, len(in.suggestions)+len(in.values))
	seen := make(map[string]struct{}, len(in.suggestions))
	for _, s := range in.suggestions {
		key := string(s.Field.ID)
		seen[key] = struct{}{}
		entry := WorkspaceEntry{Field: s.Field, Suggested: true, SortOrder: s.SortOrder, Annotation: annotation(s.Field.ID)}
		if v, ok := byField[key]; ok {
			entry.Value = &v
		}
		if entry.Value == nil && hidden(key, entry.Annotation) {
			continue
		}
		entries = append(entries, place(entry))
	}
	for _, id := range in.needs.order {
		key := string(id[:])
		field, ok := in.fields[key]
		if _, done := seen[key]; done || !ok {
			continue
		}
		if _, valued := byField[key]; valued {
			continue
		}
		seen[key] = struct{}{}
		entry := WorkspaceEntry{Field: field, Annotation: annotation(field.ID)}
		if hidden(key, entry.Annotation) {
			continue
		}
		entries = append(entries, place(entry))
	}
	for _, v := range in.values {
		if _, ok := seen[string(v.FieldID)]; ok {
			continue
		}
		v := v
		entries = append(entries, place(WorkspaceEntry{
			Field:      in.fields[string(v.FieldID)],
			Value:      &v,
			Suggested:  false,
			SortOrder:  0,
			Annotation: annotation(v.FieldID),
		}))
	}

	if len(layoutRows) > 0 {
		fallback := maxOrder + 1
		for i := range entries {
			if l, ok := layoutRows[string(entries[i].Field.ID)]; ok {
				entries[i].SortOrder = l.SortOrder
				continue
			}
			entries[i].SortOrder = fallback + i
		}
		sort.SliceStable(entries, func(i, j int) bool { return entries[i].SortOrder < entries[j].SortOrder })
	}
	return entries
}

// normalizeFor trims text, checks it against the mark, and normalizes it for
// the field's type. An unknown value has no text, so it returns "". A bad mark
// is valuemark.ErrInvalid and any other refused value is ErrInvalid, each with
// the field's wire id as its param.
func normalizeFor(field metadatafields.Field, text string, mark valuemark.Mark) (string, error) {
	trimmed := strings.TrimSpace(text)
	id := database.UUIDString(field.ID)
	if err := valuemark.Validate(mark, trimmed != ""); err != nil {
		return "", valuemark.ErrInvalid.WithParams(id)
	}
	if mark.Unknown {
		return "", nil
	}
	n, err := normalizeValue(field.DataType, trimmed)
	if err != nil {
		return "", ErrInvalid.WithParams(id)
	}
	return n, nil
}

func normalizeValue(dataType, valueText string) (string, error) {
	if valueText == "" {
		return "", ErrInvalid
	}
	switch dataType {
	case metadatafields.DataTypeText:
		return valueText, nil
	case metadatafields.DataTypeURL:
		canon, err := urlshape.Canonical(valueText)
		if err != nil {
			return "", ErrInvalid
		}
		return canon, nil
	default:
		return "", ErrInvalid
	}
}

func scanRow(row database.Scanner, st *store) (Row, error) {
	var r Row
	var ownerID []byte
	var unknown, supplied int
	if err := row.Scan(&r.ID, &ownerID, &r.FieldID, &r.ValueText, &unknown, &supplied); err != nil {
		return Row{}, err
	}
	r.Mark = valuemark.Mark{Unknown: unknown == 1, Supplied: supplied == 1}
	r.Owner = Owner{Level: st.level, ID: ownerID}
	return r, nil
}

func getPairTx(tx *sql.Tx, st *store, owner Owner, fieldID []byte) (Row, error) {
	return scanRow(tx.QueryRow(st.getPair, owner.ID, fieldID), st)
}

func scanLayoutRow(row database.Scanner) (LayoutRow, error) {
	var l LayoutRow
	var dismissed int
	if err := row.Scan(&l.FieldID, &l.SortOrder, &dismissed); err != nil {
		return LayoutRow{}, err
	}
	l.Dismissed = dismissed == 1
	return l, nil
}

func getLayoutTx(tx *sql.Tx, st *store, owner Owner, fieldID []byte) (LayoutRow, error) {
	return scanLayoutRow(tx.QueryRow(st.layoutGet, owner.ID, fieldID))
}

// loadFields reads the fields with the given ids in one query, keyed by id; an
// id with no field is ErrInvalid.
func loadFields(tx *sql.Tx, ids [][]byte) (map[string]metadatafields.Field, error) {
	out, err := metadatafields.MapByIDsTx(tx, ids)
	if err != nil {
		return nil, err
	}
	if err := requireFields(out, ids); err != nil {
		return nil, err
	}
	return out, nil
}

// requireFields is ErrInvalid when an id has no field in the map.
func requireFields(fields map[string]metadatafields.Field, ids [][]byte) error {
	for _, id := range ids {
		if _, ok := fields[string(id)]; !ok {
			return ErrInvalid
		}
	}
	return nil
}

func boolInt(b bool) int {
	if b {
		return 1
	}
	return 0
}

func mapConstraint(err error) error {
	if database.IsConstraintViolation(err) {
		return ErrInvalid
	}
	return err
}
