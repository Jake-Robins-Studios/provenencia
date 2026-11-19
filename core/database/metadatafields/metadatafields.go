// Package metadatafields accesses the source_metadata_fields vocabulary table.
// Create, Update, Delete, and UpsertTx run inside writes.Run and return the row
// changes that Run records. UpsertTx is the seed's write, run inside writes.Run.
package metadatafields

import (
	"database/sql"
	"errors"
	"slices"
	"strings"

	"github.com/Jake-Robins-Studios/provenencia/core/apperr"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/catalogmodel"
	"github.com/Jake-Robins-Studios/provenencia/core/database/deleteimpact"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sqlbatch"
	"github.com/Jake-Robins-Studios/provenencia/core/slug"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/google/uuid"
)

var ErrInvalid = apperr.New(apperr.CodeMetadataFieldsInvalid, apperr.KindUser)

// ErrDuplicateKey is returned by Create when the label-derived key already
// names a user-origin field. Carries the colliding key as a param.
var ErrDuplicateKey = apperr.New(apperr.CodeMetadataFieldsDuplicateKey, apperr.KindConflict)

// ErrLocked is returned by Update when the target field is plugin-origin
// (project fields — user and provenencia starters — are editable).
var ErrLocked = apperr.New(apperr.CodeMetadataFieldsInvalid, apperr.KindUser)

// ErrInUse is returned by Delete when a value in source_metadata,
// artifact_metadata or evidence_graph_metadata still references the field.
var ErrInUse = apperr.New(apperr.CodeMetadataFieldsInUse, apperr.KindConflict)

// ErrOriginLocked is returned by Delete when the field is plugin-origin.
var ErrOriginLocked = apperr.New(apperr.CodeMetadataFieldsOriginLocked, apperr.KindConflict)

const (
	DataTypeText = "text"
	DataTypeURL  = "url"

	sqlInsert = `INSERT INTO source_metadata_fields (id, key, origin, label, data_type, description, unknown_text)
		VALUES (?, ?, ?, ?, ?, ?, ?)`
	sqlKeysIn = `SELECT id, key, origin FROM source_metadata_fields WHERE key IN (`
	sqlUpdate = `UPDATE source_metadata_fields SET label = ?, data_type = ?, description = ?, unknown_text = ? WHERE id = ?`
	sqlDelete = `DELETE FROM source_metadata_fields WHERE id = ?`
)

// The field reads, each selecting Columns("") for ScanField.
var (
	sqlLookup = `SELECT ` + Columns("") + `
		FROM source_metadata_fields WHERE key = ? AND origin = ?`
	sqlGetByID = `SELECT ` + Columns("") + `
		FROM source_metadata_fields WHERE id = ?`
	sqlGetByIDsIn = `SELECT ` + Columns("") + `
		FROM source_metadata_fields WHERE id IN (`
	sqlList = `SELECT ` + Columns("") + `
		FROM source_metadata_fields ORDER BY label COLLATE NOCASE, origin, key`
)

// Field is one source_metadata_fields row.
type Field struct {
	ID          []byte
	Key         string
	Origin      string
	Label       string
	DataType    string
	Description string
	// UnknownText is what a value of this field marked unknown prints ("n.p."),
	// or "" when the field names none.
	UnknownText string
	// UsedBy is how many Sources, Artifacts and Evidence graphs hold a value
	// for this field plus how many Source types name it in a citation format:
	// the total that blocks its delete. List and Update populate
	// it; the other readers leave it 0.
	UsedBy int
}

// rowFields is the audit view of a field: the one column list that create,
// update and delete changes are built from. Description and unknown_text are
// present only when not empty.
func rowFields(f Field) map[string]any {
	fields := map[string]any{
		"id":        database.UUIDString(f.ID),
		"key":       f.Key,
		"origin":    f.Origin,
		"label":     f.Label,
		"data_type": f.DataType,
	}
	if f.Description != "" {
		fields["description"] = f.Description
	}
	if f.UnknownText != "" {
		fields["unknown_text"] = f.UnknownText
	}
	return fields
}

// updateChange is the update change from prev to next, naming only the columns
// that differ (a missing key reads nil); nil when none does. id, key and
// origin are never compared.
func updateChange(prev, next Field) *rowchange.Change {
	old, now := rowFields(prev), rowFields(next)
	fields := rowchange.UpdatedRow(old, now, "id", "key", "origin")
	if len(fields) == 0 {
		return nil
	}
	return &rowchange.Change{
		EntityType: "metadata_field",
		EntityID:   append([]byte(nil), prev.ID...),
		Action:     rowchange.ActionUpdate,
		Fields:     fields,
	}
}

// createChange is the create change of a new field row: every column.
func createChange(f Field) rowchange.Change {
	return rowchange.Change{
		EntityType: "metadata_field",
		EntityID:   append([]byte(nil), f.ID...),
		Action:     rowchange.ActionCreate,
		Fields:     rowchange.FullRow(rowFields(f)),
	}
}

// UpsertTx inserts or updates by (key, origin) on tx and returns the id and
// the row changes. It writes every column the input carries: label, data type,
// description and unknown text ("" is NULL). Missing: one create change.
// Present: one update change names what differs; nothing differing writes
// nothing and returns no change. A non-empty f.ID is ErrInvalid. The caller
// records the changes.
func UpsertTx(tx *database.Tx, f Field) ([]byte, []rowchange.Change, error) {
	if tx == nil || len(f.ID) != 0 {
		return nil, nil, ErrInvalid
	}
	f.Key = strings.TrimSpace(f.Key)
	f.Origin = strings.TrimSpace(f.Origin)
	f.Label = strings.TrimSpace(f.Label)
	f.DataType = strings.TrimSpace(f.DataType)
	f.Description = strings.TrimSpace(f.Description)
	f.UnknownText = strings.TrimSpace(f.UnknownText)
	if f.Key == "" || f.Label == "" || !vocabkey.ValidOrigin(f.Origin) || !dataTypeOK(f.DataType) {
		return nil, nil, ErrInvalid
	}
	existing, err := lookupTx(tx.Tx, f.Key, f.Origin)
	if errors.Is(err, sql.ErrNoRows) {
		uid, err := uuid.NewV7()
		if err != nil {
			return nil, nil, err
		}
		f.ID = uid[:]
		if _, err := tx.Exec(sqlInsert, f.ID, f.Key, f.Origin, f.Label, f.DataType, database.NullString(f.Description), database.NullString(f.UnknownText)); err != nil {
			return nil, nil, err
		}
		return append([]byte(nil), f.ID...), []rowchange.Change{createChange(f)}, nil
	}
	if err != nil {
		return nil, nil, err
	}
	next := existing
	next.Label, next.DataType, next.Description, next.UnknownText = f.Label, f.DataType, f.Description, f.UnknownText
	change := updateChange(existing, next)
	if change == nil {
		return append([]byte(nil), existing.ID...), nil, nil
	}
	if _, err := tx.Exec(sqlUpdate, next.Label, next.DataType, database.NullString(next.Description), database.NullString(next.UnknownText), existing.ID); err != nil {
		return nil, nil, err
	}
	return append([]byte(nil), existing.ID...), []rowchange.Change{*change}, nil
}

// Create mints a kebab-case key from label (see core/slug.Kebab) and
// inserts a new user-origin field on tx. Returns ErrInvalid if the label cannot
// form a key or the data type is unknown, or ErrDuplicateKey (params: the
// colliding key) if a user-origin field with that key already exists.
// The caller records the returned changes.
func Create(tx *database.Tx, label, dataType, description string) (Field, []rowchange.Change, error) {
	if tx == nil {
		return Field{}, nil, ErrInvalid
	}
	key := slug.Kebab(label)
	if key == "" {
		return Field{}, nil, ErrInvalid
	}
	if _, err := lookupTx(tx.Tx, key, vocabkey.OriginUser); err == nil {
		return Field{}, nil, ErrDuplicateKey.WithParams(key)
	} else if !errors.Is(err, sql.ErrNoRows) {
		return Field{}, nil, err
	}
	label = strings.TrimSpace(label)
	dataType = strings.TrimSpace(dataType)
	description = strings.TrimSpace(description)
	if label == "" || !dataTypeOK(dataType) {
		return Field{}, nil, ErrInvalid
	}
	uid, err := uuid.NewV7()
	if err != nil {
		return Field{}, nil, err
	}
	id := uid[:]
	if _, err := tx.Exec(sqlInsert, id, key, vocabkey.OriginUser, label, dataType, database.NullString(description), nil); err != nil {
		return Field{}, nil, err
	}
	created := Field{ID: id, Key: key, Origin: vocabkey.OriginUser, Label: label, DataType: dataType, Description: description}
	got, err := getByID(tx.Tx, id)
	if err != nil {
		return Field{}, nil, err
	}
	return got, []rowchange.Change{createChange(created)}, nil
}

// Update patches label, description and unknown text for a project field (user
// or provenencia) by id. Key, origin, and data_type are immutable after create.
// dataType must match the existing value (callers still pass it for clarity).
// A nil unknownText keeps the stored one; otherwise it is trimmed and "" clears
// it. Returns ErrLocked for plugin-origin fields. An unchanged label,
// description and unknown text returns the existing field and no changes. The
// caller records the returned changes.
func Update(tx *database.Tx, id []byte, label, dataType, description string, unknownText *string) (Field, []rowchange.Change, error) {
	if tx == nil {
		return Field{}, nil, ErrInvalid
	}
	label = strings.TrimSpace(label)
	dataType = strings.TrimSpace(dataType)
	description = strings.TrimSpace(description)
	if len(id) != 16 || label == "" || !dataTypeOK(dataType) {
		return Field{}, nil, ErrInvalid
	}
	existing, err := getByID(tx.Tx, id)
	if err != nil {
		return Field{}, nil, err
	}
	if !vocabkey.Editable(existing.Origin) {
		return Field{}, nil, ErrLocked
	}
	if dataType != existing.DataType {
		return Field{}, nil, ErrInvalid
	}
	unknown := existing.UnknownText
	if unknownText != nil {
		unknown = strings.TrimSpace(*unknownText)
	}
	next := existing
	next.Label, next.Description, next.UnknownText = label, description, unknown
	change := updateChange(existing, next)
	if change == nil {
		return existing, nil, nil
	}
	if _, err := tx.Exec(sqlUpdate, label, existing.DataType, database.NullString(description), database.NullString(unknown), id); err != nil {
		return Field{}, nil, err
	}
	got, err := getByID(tx.Tx, id)
	if err != nil {
		return Field{}, nil, err
	}
	return got, []rowchange.Change{*change}, nil
}

// GetByID returns the field with the given id, or sql.ErrNoRows.
func GetByID(c *database.Catalog, id []byte) (Field, error) {
	db, err := c.DB()
	if err != nil {
		return Field{}, err
	}
	if len(id) != 16 {
		return Field{}, ErrInvalid
	}
	return getByID(db, id)
}

// ListByIDsTx returns the fields with the given ids on an open transaction, in
// no set order. A repeated id counts once and an id with no field is left out;
// no ids returns nil.
func ListByIDsTx(tx *sql.Tx, ids [][]byte) ([]Field, error) {
	ids = database.UniqueBlobIDs(ids)
	if len(ids) == 0 {
		return nil, nil
	}
	var out []Field
	err := sqlbatch.Query(tx, sqlGetByIDsIn, ")", nil, ids, func(rows *sql.Rows) error {
		f, err := ScanField(rows)
		if err != nil {
			return err
		}
		out = append(out, f)
		return nil
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}

// KeyResolution is what ResolveKeysTx found: the id of each key one field
// answers for, and the keys no field or more than one field holds (sorted).
type KeyResolution struct {
	IDs       map[string][]byte
	Unknown   []string
	Ambiguous []string
}

// ResolveKeysTx finds the field each key names, across origins. A key held by
// one field resolves to it. A key held by several resolves to the one of
// preferOrigin when preferOrigin is not empty and one of them has it, and is
// Ambiguous otherwise. A key no field holds is Unknown. Keys match exactly. A
// repeated key counts once; no keys returns the zero value without a query.
func ResolveKeysTx(tx *sql.Tx, keys []string, preferOrigin string) (KeyResolution, error) {
	keys = slices.Compact(slices.Sorted(slices.Values(keys)))
	if len(keys) == 0 {
		return KeyResolution{}, nil
	}
	type holder struct {
		id     []byte
		origin string
	}
	held := map[string][]holder{}
	err := sqlbatch.Query(tx, sqlKeysIn, ")", nil, keys, func(rows *sql.Rows) error {
		var h holder
		var key string
		if err := rows.Scan(&h.id, &key, &h.origin); err != nil {
			return err
		}
		held[key] = append(held[key], h)
		return nil
	})
	if err != nil {
		return KeyResolution{}, err
	}
	out := KeyResolution{IDs: map[string][]byte{}}
	for _, key := range keys {
		hs := held[key]
		switch {
		case len(hs) == 0:
			out.Unknown = append(out.Unknown, key)
		case len(hs) == 1:
			out.IDs[key] = hs[0].id
		default:
			i := -1
			if preferOrigin != "" {
				i = slices.IndexFunc(hs, func(h holder) bool { return h.origin == preferOrigin })
			}
			if i < 0 {
				out.Ambiguous = append(out.Ambiguous, key)
			} else {
				out.IDs[key] = hs[i].id
			}
		}
	}
	return out, nil
}

// Lookup returns the field for (key, origin), or sql.ErrNoRows.
func Lookup(c *database.Catalog, key, origin string) (Field, error) {
	db, err := c.DB()
	if err != nil {
		return Field{}, err
	}
	key = strings.TrimSpace(key)
	origin = strings.TrimSpace(origin)
	if key == "" || origin == "" {
		return Field{}, ErrInvalid
	}
	return ScanField(db.QueryRow(sqlLookup, key, origin))
}

// List returns all source_metadata_fields rows, each with its UsedBy total,
// read in one transaction.
func List(c *database.Catalog) ([]Field, error) {
	db, err := c.DB()
	if err != nil {
		return nil, err
	}
	tx, err := db.Begin()
	if err != nil {
		return nil, err
	}
	defer func() { _ = tx.Rollback() }()
	rows, err := tx.Query(sqlList)
	if err != nil {
		return nil, err
	}
	var out []Field
	for rows.Next() {
		f, err := ScanField(rows)
		if err != nil {
			rows.Close()
			return nil, err
		}
		out = append(out, f)
	}
	if err := rows.Close(); err != nil {
		return nil, err
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	err = deleteimpact.FillUsedBy(tx, catalogmodel.KindMetadataField, out,
		func(f Field) []byte { return f.ID }, func(f *Field, n int) { f.UsedBy = n })
	if err != nil {
		return nil, err
	}
	return out, nil
}

// Delete erases a field when no Source, Artifact or Evidence graph stores a value for it. Suggestion
// and layout joins CASCADE. Plugin-origin fields are origin_locked even
// when unused. The caller records the returned changes, including layout
// rows released before the field itself.
func Delete(tx *database.Tx, userID, id []byte) ([]rowchange.Change, error) {
	if err := database.RequireUserID(userID, ErrInvalid); err != nil {
		return nil, err
	}
	if tx == nil || len(id) != 16 {
		return nil, ErrInvalid
	}
	prev, err := getByID(tx.Tx, id)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrInvalid
	}
	if err != nil {
		return nil, err
	}

	report, err := deleteimpact.Impact(tx.Tx, catalogmodel.KindMetadataField, id)
	if err != nil {
		return nil, err
	}
	if err := deleteimpact.Refuse(report, deleteimpact.Codes{
		InUse: ErrInUse, OriginLocked: ErrOriginLocked, NotFound: ErrInvalid,
	}); err != nil {
		return nil, err
	}
	// Per-Source layout rows (order, dismissed suggestions) are released and audited.
	released, err := deleteimpact.ReleaseFacets(tx, catalogmodel.KindMetadataField, id)
	if err != nil {
		return nil, err
	}
	if _, err := tx.Exec(sqlDelete, id); err != nil {
		return nil, err
	}
	fields := rowchange.DeletedRow(rowFields(prev))
	return append(released, rowchange.Change{
		EntityType: "metadata_field",
		EntityID:   append([]byte(nil), id...),
		Action:     rowchange.ActionDelete,
		Fields:     fields,
	}), nil
}

func dataTypeOK(dt string) bool {
	return dt == DataTypeText || dt == DataTypeURL
}

func getByID(q database.Querier, id []byte) (Field, error) {
	return ScanField(q.QueryRow(sqlGetByID, id))
}

func lookupTx(tx *sql.Tx, key, origin string) (Field, error) {
	return ScanField(tx.QueryRow(sqlLookup, key, origin))
}

// Columns is the SELECT list ScanField reads, each column prefixed "alias." when
// alias is not empty.
func Columns(alias string) string {
	p := ""
	if alias != "" {
		p = alias + "."
	}
	return p + "id, " + p + "key, " + p + "origin, " + p + "label, " + p + "data_type, COALESCE(" + p + "description, ''), COALESCE(" + p + "unknown_text, '')"
}

// ScanField scans a row of Columns, in that order, then any trailing columns
// into extra.
func ScanField(row database.Scanner, extra ...any) (Field, error) {
	var f Field
	err := row.Scan(append([]any{&f.ID, &f.Key, &f.Origin, &f.Label, &f.DataType, &f.Description, &f.UnknownText}, extra...)...)
	return f, err
}
