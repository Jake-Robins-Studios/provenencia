package sourcetypes

import (
	"bytes"
	"database/sql"
	"errors"
	"slices"
	"strings"

	"github.com/google/uuid"
	"github.com/mendahu/provenencia/core/citationformat"
	"github.com/mendahu/provenencia/core/database"
	"github.com/mendahu/provenencia/core/database/metadatafields"
	"github.com/mendahu/provenencia/core/database/rowchange"
	"github.com/mendahu/provenencia/core/database/sqlbatch"
)

const (
	sqlStoredFormatsIn = `SELECT id, citation_full, citation_short, citation_list FROM source_types WHERE id IN (`
	sqlUpdateFormats   = `UPDATE source_types SET citation_full = ?, citation_short = ?, citation_list = ? WHERE id = ?`
)

// formColumns pairs each form with the source_types column that stores it.
var formColumns = []struct {
	form   citationformat.Form
	column string
}{
	{citationformat.FormFull, "citation_full"},
	{citationformat.FormShort, "citation_short"},
	{citationformat.FormList, "citation_list"},
}

// Formats are a type's three citation formats, one text per form. An empty
// text is no format. Read from the catalog they name fields by id; on the wire
// they name fields by key (see FormatsView).
type Formats struct{ Full, Short, List string }

// text returns the text of one form.
func (f Formats) text(form citationformat.Form) string {
	switch form {
	case citationformat.FormFull:
		return f.Full
	case citationformat.FormShort:
		return f.Short
	case citationformat.FormList:
		return f.List
	}
	panic("sourcetypes: unknown citation form " + string(form))
}

// with returns f with one form's text replaced.
func (f Formats) with(form citationformat.Form, text string) Formats {
	switch form {
	case citationformat.FormFull:
		f.Full = text
	case citationformat.FormShort:
		f.Short = text
	case citationformat.FormList:
		f.List = text
	default:
		panic("sourcetypes: unknown citation form " + string(form))
	}
	return f
}

// FieldChoice says which field a key means when more than one field holds it.
type FieldChoice struct {
	Key     string
	FieldID []byte
}

// FormatsView is a type's formats as the editor shows them: fields by key, the
// field each shared key means, and the mistakes in the text.
type FormatsView struct {
	Formats
	Choices     []FieldChoice                   // sorted by key
	Diagnostics []citationformat.FormDiagnostic // full, short, list; each form's sorted by position
}

// StoredFormatsTx reads the formats of the given types as stored (fields by
// id), keyed by string(id). A NULL column reads as "" and a type with no row is
// absent.
func StoredFormatsTx(tx *sql.Tx, typeIDs [][]byte) (map[string]Formats, error) {
	out := map[string]Formats{}
	err := sqlbatch.Query(tx, sqlStoredFormatsIn, ")", nil, database.UniqueBlobIDs(typeIDs), func(rows *sql.Rows) error {
		var id []byte
		var full, short, list sql.NullString
		if err := rows.Scan(&id, &full, &short, &list); err != nil {
			return err
		}
		out[string(id)] = Formats{Full: full.String, Short: short.String, List: list.String}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}

// GetFormats returns a type's formats as the editor shows them. A stored text
// that does not parse comes back as stored, with its diagnostics. A type that
// does not exist is ErrInvalid.
func GetFormats(c *database.Catalog, typeID []byte) (FormatsView, error) {
	db, err := c.DB()
	if err != nil {
		return FormatsView{}, err
	}
	if len(typeID) != 16 {
		return FormatsView{}, ErrInvalid
	}
	tx, err := db.Begin()
	if err != nil {
		return FormatsView{}, err
	}
	defer func() { _ = tx.Rollback() }()
	return viewTx(tx, typeID)
}

// viewTx reads a type's stored formats and shows them by key (the read half of
// the round trip). Every by-id field is shown by its key, except an id with no
// field and an id whose key a different id already took in this type's formats
// (scanned full, short, list, in Fields order); both stay as their #id token.
func viewTx(tx *sql.Tx, typeID []byte) (FormatsView, error) {
	all, err := StoredFormatsTx(tx, [][]byte{typeID})
	if err != nil {
		return FormatsView{}, err
	}
	in, ok := all[string(typeID)]
	if !ok {
		return FormatsView{}, ErrInvalid
	}

	view := FormatsView{}
	templates := map[citationformat.Form]*citationformat.Template{}
	var ids [][]byte
	for _, form := range citationformat.Forms() {
		text := in.text(form)
		view.Formats = view.Formats.with(form, text)
		if text == "" {
			continue
		}
		tpl, diags := citationformat.Parse(text, form)
		for _, d := range diags {
			view.Diagnostics = append(view.Diagnostics, citationformat.FormDiagnostic{Form: form, Diagnostic: d})
		}
		if tpl == nil {
			continue
		}
		templates[form] = tpl
		for _, f := range tpl.Fields() {
			if f.ByID() {
				ids = append(ids, f.ID[:])
			}
		}
	}
	fields, err := metadatafields.ListByIDsTx(tx, ids)
	if err != nil {
		return FormatsView{}, err
	}
	byID := map[uuid.UUID]metadatafields.Field{}
	for _, f := range fields {
		id, err := uuid.FromBytes(f.ID)
		if err != nil {
			return FormatsView{}, err
		}
		byID[id] = f
	}

	// Which id took each shown key, in scan order.
	shown := map[uuid.UUID]string{}
	owner := map[string]uuid.UUID{}
	for _, form := range citationformat.Forms() {
		for _, f := range templates[form].Fields() {
			field, known := byID[f.ID]
			if !f.ByID() || !known {
				continue
			}
			if _, done := shown[f.ID]; done {
				continue
			}
			if taken, ok := owner[field.Key]; ok && taken != f.ID {
				continue
			}
			owner[field.Key] = f.ID
			shown[f.ID] = field.Key
		}
	}
	for _, form := range citationformat.Forms() {
		tpl := templates[form]
		if tpl == nil {
			continue
		}
		text, err := tpl.RewriteFields(func(f citationformat.FieldRef) (citationformat.FieldRef, error) {
			if key, ok := shown[f.ID]; f.ByID() && ok {
				return citationformat.FieldRef{Key: key}, nil
			}
			return f, nil
		})
		if err != nil {
			return FormatsView{}, err
		}
		view.Formats = view.Formats.with(form, text)
	}

	// A shown key more than one field holds is a choice the editor sends back.
	keys := make([]string, 0, len(owner))
	for key := range owner {
		keys = append(keys, key)
	}
	res, err := metadatafields.ResolveKeysTx(tx, keys, "")
	if err != nil {
		return FormatsView{}, err
	}
	for _, key := range res.Ambiguous {
		id := owner[key]
		view.Choices = append(view.Choices, FieldChoice{Key: key, FieldID: slices.Clone(id[:])})
	}
	return view, nil
}

// ToStored turns formats written with keys into formats written with ids, the
// one storage step for the editor's write and for seeding. Every choice is
// checked first (an empty key, an id that is not a field with exactly that
// key, or two choices for one key is ErrInvalid). A blank form becomes "". Every
// other form is parsed; on the forms that parsed, each key resolves through a
// choice, else through metadatafields.ResolveKeysTx with preferOrigin, and
// each typed #id must name a field. With any diagnostic the returned Formats is
// empty and the diagnostics come in form order, each form's sorted by position;
// only forms that parsed get resolution diagnostics.
func ToStored(tx *sql.Tx, in Formats, choices []FieldChoice, preferOrigin string) (Formats, []citationformat.FormDiagnostic, error) {
	chosen, err := checkChoices(tx, choices)
	if err != nil {
		return Formats{}, nil, err
	}
	var diags []citationformat.FormDiagnostic
	parsed := map[citationformat.Form]*citationformat.Template{}
	var out Formats
	var keys []string
	var ids [][]byte
	for _, form := range citationformat.Forms() {
		text := in.text(form)
		if strings.TrimSpace(text) == "" {
			continue
		}
		tpl, ds := citationformat.Parse(text, form)
		for _, d := range ds {
			diags = append(diags, citationformat.FormDiagnostic{Form: form, Diagnostic: d})
		}
		if tpl == nil {
			continue
		}
		parsed[form] = tpl
		for _, f := range tpl.Fields() {
			if f.ByID() {
				ids = append(ids, f.ID[:])
			} else if _, ok := chosen[f.Key]; !ok {
				keys = append(keys, f.Key)
			}
		}
	}
	res, err := metadatafields.ResolveKeysTx(tx, keys, preferOrigin)
	if err != nil {
		return Formats{}, nil, err
	}
	typed, err := metadatafields.ListByIDsTx(tx, ids)
	if err != nil {
		return Formats{}, nil, err
	}
	typedIDs := map[string]bool{}
	for _, f := range typed {
		typedIDs[string(f.ID)] = true
	}
	code := func(f citationformat.FieldRef) (citationformat.DiagnosticCode, bool) {
		switch {
		case f.ByID():
			return citationformat.CodeUnknownField, !typedIDs[string(f.ID[:])]
		case chosen[f.Key] != nil:
			return "", false
		case slices.Contains(res.Unknown, f.Key):
			return citationformat.CodeUnknownField, true
		case slices.Contains(res.Ambiguous, f.Key):
			return citationformat.CodeAmbiguousField, true
		}
		return "", false
	}
	for _, form := range citationformat.Forms() {
		tpl := parsed[form]
		var found []citationformat.FormDiagnostic
		for _, f := range tpl.Fields() {
			c, bad := code(f)
			if !bad {
				continue
			}
			for _, span := range tpl.FieldSpans(f) {
				found = append(found, citationformat.FormDiagnostic{
					Form: form, Diagnostic: citationformat.Diagnostic{Code: c, Span: span}})
			}
		}
		slices.SortStableFunc(found, func(a, b citationformat.FormDiagnostic) int { return a.Span.Start - b.Span.Start })
		diags = append(diags, found...)
	}
	if len(diags) > 0 {
		sortByForm(diags)
		return Formats{}, diags, nil
	}
	for _, form := range citationformat.Forms() {
		tpl := parsed[form]
		if tpl == nil {
			continue
		}
		text, err := tpl.RewriteFields(func(f citationformat.FieldRef) (citationformat.FieldRef, error) {
			if f.ByID() {
				return f, nil
			}
			id := chosen[f.Key]
			if id == nil {
				id = res.IDs[f.Key]
			}
			u, err := uuid.FromBytes(id)
			if err != nil {
				return citationformat.FieldRef{}, err
			}
			return citationformat.FieldRef{ID: u}, nil
		})
		if err != nil {
			return Formats{}, nil, err
		}
		out = out.with(form, text)
	}
	return out, nil, nil
}

// sortByForm orders diagnostics full, short, list, keeping each form's order.
func sortByForm(diags []citationformat.FormDiagnostic) {
	rank := func(f citationformat.Form) int { return slices.Index(citationformat.Forms(), f) }
	slices.SortStableFunc(diags, func(a, b citationformat.FormDiagnostic) int { return rank(a.Form) - rank(b.Form) })
}

// checkChoices returns the chosen field id of each key, or ErrInvalid.
func checkChoices(tx *sql.Tx, choices []FieldChoice) (map[string][]byte, error) {
	chosen := map[string][]byte{}
	var ids [][]byte
	for _, c := range choices {
		if c.Key == "" || len(c.FieldID) != 16 {
			return nil, ErrInvalid
		}
		if _, dup := chosen[c.Key]; dup {
			return nil, ErrInvalid
		}
		chosen[c.Key] = c.FieldID
		ids = append(ids, c.FieldID)
	}
	fields, err := metadatafields.ListByIDsTx(tx, ids)
	if err != nil {
		return nil, err
	}
	keyOf := map[string]string{}
	for _, f := range fields {
		keyOf[string(f.ID)] = f.Key
	}
	for key, id := range chosen {
		if got, ok := keyOf[string(id)]; !ok || got != key {
			return nil, ErrInvalid
		}
	}
	return chosen, nil
}

// UpdateFormats replaces all three of a type's formats with in, whose fields
// are named by key (or by typed #id), and returns the formats as read after the
// call. With any diagnostic nothing is saved, the changes are nil and the view
// holds what the type stores plus only this write's diagnostics. A write that
// changes nothing returns nil changes. A missing type is ErrInvalid and a
// plugin type ErrLocked. The caller records the returned changes.
func UpdateFormats(tx *database.Tx, typeID []byte, in Formats, choices []FieldChoice) (FormatsView, []rowchange.Change, error) {
	if tx == nil || len(typeID) != 16 {
		return FormatsView{}, nil, ErrInvalid
	}
	// Update reports a missing type as sql.ErrNoRows; a formats write names the
	// type by id alone, so a missing one is a bad argument (D-13).
	if _, err := editableTx(tx.Tx, typeID); errors.Is(err, sql.ErrNoRows) {
		return FormatsView{}, nil, ErrInvalid
	} else if err != nil {
		return FormatsView{}, nil, err
	}
	stored, err := StoredFormatsTx(tx.Tx, [][]byte{typeID})
	if err != nil {
		return FormatsView{}, nil, err
	}
	before := stored[string(typeID)]
	next, diags, err := ToStored(tx.Tx, in, choices, "")
	if err != nil {
		return FormatsView{}, nil, err
	}
	if len(diags) > 0 {
		view, err := viewTx(tx.Tx, typeID)
		if err != nil {
			return FormatsView{}, nil, err
		}
		view.Diagnostics = diags
		return view, nil, nil
	}
	fields := map[string]rowchange.FieldDiff{}
	for _, fc := range formColumns {
		form, column := fc.form, fc.column
		if before.text(form) != next.text(form) {
			fields[column] = rowchange.FieldDiff{Old: database.NullString(before.text(form)), New: database.NullString(next.text(form))}
		}
	}
	if len(fields) > 0 {
		if _, err := tx.Exec(sqlUpdateFormats,
			database.NullString(next.Full), database.NullString(next.Short), database.NullString(next.List), typeID); err != nil {
			return FormatsView{}, nil, err
		}
	}
	view, err := viewTx(tx.Tx, typeID)
	if err != nil {
		return FormatsView{}, nil, err
	}
	if len(fields) == 0 {
		return view, nil, nil
	}
	return view, []rowchange.Change{{
		EntityType: "source_type",
		EntityID:   bytes.Clone(typeID),
		Action:     rowchange.ActionUpdate,
		Fields:     fields,
	}}, nil
}
