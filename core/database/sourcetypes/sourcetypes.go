// Package sourcetypes accesses the source_types vocabulary table.
// Create, Update, Delete, and UpsertTx run inside writes.Run and return the row
// changes that Run records. UpsertTx is the seed's write, run inside writes.Run.
package sourcetypes

import (
	"database/sql"
	"errors"
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

var ErrInvalid = apperr.New(apperr.CodeSourceTypesInvalid, apperr.KindUser)

// ErrDuplicateKey is returned by Create when the label-derived key already
// names a user-origin type. Carries the colliding key as a param.
var ErrDuplicateKey = apperr.New(apperr.CodeSourceTypesDuplicateKey, apperr.KindConflict)

// ErrLocked is returned by Update when the target type is plugin-origin
// (project types — user and provenencia starters — are editable).
var ErrLocked = apperr.New(apperr.CodeSourceTypesInvalid, apperr.KindUser)

// ErrInUse is returned by Delete when sources still reference the type.
var ErrInUse = apperr.New(apperr.CodeSourceTypesInUse, apperr.KindConflict)

// ErrOriginLocked is returned by Delete when the type is plugin-origin.
var ErrOriginLocked = apperr.New(apperr.CodeSourceTypesOriginLocked, apperr.KindConflict)

// The type reads build their column list once, columns, and scan it once,
// scanType.
var (
	sqlList = `SELECT ` + columns("t") + `,
			(` + sqlSuggestedFields + `t.id)
		FROM source_types t ORDER BY t.label COLLATE NOCASE, t.origin, t.key`
	sqlLookup  = `SELECT ` + columns("") + ` FROM source_types WHERE key = ? AND origin = ?`
	sqlGetByID = `SELECT ` + columns("") + ` FROM source_types WHERE id = ?`
	// Binds: ids, in sqlbatch batches.
	sqlGetIn = `SELECT ` + columns("") + ` FROM source_types WHERE id IN (`
)

// columns is the six source_types columns scanType reads, each prefixed with
// alias and a dot when alias is not empty.
func columns(alias string) string {
	return database.Columns(alias, "id", "key", "origin", "label", "description|COALESCE(%s, '')", "icon_key")
}

// scanType scans the columns list, then extra destinations.
func scanType(row database.Scanner, extra ...any) (Type, error) {
	var t Type
	dest := append([]any{&t.ID, &t.Key, &t.Origin, &t.Label, &t.Description, &t.IconKey}, extra...)
	if err := row.Scan(dest...); err != nil {
		return Type{}, err
	}
	return t, nil
}

const (
	// sqlInsert is the one insert of a new type with its citation formats.
	sqlInsert = `INSERT INTO source_types (id, key, origin, label, description, icon_key, citation_full, citation_short, citation_list)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
	// sqlSuggestedFields counts the fields a type suggests at all three
	// levels (a field at two levels counts twice); the type id follows it. It
	// is the one place the rule for which suggestions count lives.
	sqlSuggestedFields = `SELECT COUNT(*) FROM source_type_metadata_fields j WHERE j.source_type_id = `
	sqlUpdate          = `UPDATE source_types SET label = ?, description = ?, icon_key = ? WHERE id = ?`
	sqlDelete          = `DELETE FROM source_types WHERE id = ?`
)

// Type is one source_types row.
type Type struct {
	ID          []byte
	Key         string
	Origin      string
	Label       string
	Description string
	// IconKey references the closed design-system type_* set.
	IconKey string
	// UsedBy is how many sources reference this type. Only List and
	// Update populate it; the other readers leave it 0.
	UsedBy int
	// SuggestedFields is how many fields this type suggests at all three
	// levels. Only List and Update populate it; the other readers leave it 0.
	SuggestedFields int
}

// rowFields is the audit view of a type: the one column list that create,
// update and delete changes are built from. Description is present only when
// not empty.
func rowFields(t Type) map[string]any {
	fields := map[string]any{
		"id":       database.UUIDString(t.ID),
		"key":      t.Key,
		"origin":   t.Origin,
		"label":    t.Label,
		"icon_key": t.IconKey,
	}
	if t.Description != "" {
		fields["description"] = t.Description
	}
	return fields
}

// updateChange is the update change from prev to next, naming only the columns
// that differ (a missing key reads nil), plus formats, the diffs of the format
// columns that changed (nil for none); nil when nothing differs. id, key and
// origin are never compared.
func updateChange(prev, next Type, formats map[string]rowchange.FieldDiff) *rowchange.Change {
	old, now := rowFields(prev), rowFields(next)
	for column, diff := range formats {
		old[column], now[column] = diff.Old, diff.New
	}
	return rowchange.Updated("source_type", prev.ID, old, now, "id", "key", "origin")
}

// createChange is the create change of a new type row: every column, plus the
// format columns that carry text.
func createChange(t Type, formats Formats) rowchange.Change {
	ch := rowchange.Created("source_type", t.ID, rowFields(t))
	for column, diff := range formatFieldDiffs(Formats{}, formats) {
		ch.Fields[column] = diff
	}
	return ch
}

// UpsertTx inserts or updates by (key, origin) on tx and returns the id and
// the row changes. formats are stored (fields by id, as ToStored returns
// them): nil keeps what is stored, non-nil sets all three. Missing: a new type,
// one create change. Present: label, description and icon are written (an
// empty icon is the default mark), the formats through the one format write,
// and one update change names what differs; nothing differing writes nothing
// and returns no change. A non-empty t.ID is ErrInvalid. The caller records
// the changes.
func UpsertTx(tx *database.Tx, t Type, formats *Formats) ([]byte, []rowchange.Change, error) {
	if tx == nil || len(t.ID) != 0 {
		return nil, nil, ErrInvalid
	}
	t.Key = strings.TrimSpace(t.Key)
	t.Origin = strings.TrimSpace(t.Origin)
	t.Label = strings.TrimSpace(t.Label)
	t.Description = strings.TrimSpace(t.Description)
	iconKey, err := NormalizeIconKey(t.IconKey)
	if err != nil {
		return nil, nil, err
	}
	t.IconKey = iconKey
	if t.Key == "" || t.Label == "" || !vocabkey.ValidOrigin(t.Origin) {
		return nil, nil, ErrInvalid
	}
	existing, err := lookupTx(tx.Tx, t.Key, t.Origin)
	if errors.Is(err, sql.ErrNoRows) {
		uid, err := uuid.NewV7()
		if err != nil {
			return nil, nil, err
		}
		t.ID = uid[:]
		var in Formats
		if formats != nil {
			in = *formats
		}
		if _, err := tx.Exec(sqlInsert, t.ID, t.Key, t.Origin, t.Label, database.NullString(t.Description), t.IconKey,
			database.NullString(in.Full), database.NullString(in.Short), database.NullString(in.List)); err != nil {
			return nil, nil, err
		}
		return append([]byte(nil), t.ID...), []rowchange.Change{createChange(t, in)}, nil
	}
	if err != nil {
		return nil, nil, err
	}
	next := existing
	next.Label, next.Description, next.IconKey = t.Label, t.Description, t.IconKey
	var diffs map[string]rowchange.FieldDiff
	if formats != nil {
		if diffs, err = writeStoredTx(tx, existing.ID, *formats); err != nil {
			return nil, nil, err
		}
	}
	rowDiff := updateChange(existing, next, nil)
	change := updateChange(existing, next, diffs)
	if change == nil {
		return append([]byte(nil), existing.ID...), nil, nil
	}
	if rowDiff != nil {
		if _, err := tx.Exec(sqlUpdate, next.Label, database.NullString(next.Description), next.IconKey, existing.ID); err != nil {
			return nil, nil, err
		}
	}
	return append([]byte(nil), existing.ID...), []rowchange.Change{*change}, nil
}

// Lookup returns the type for (key, origin), or sql.ErrNoRows.
func Lookup(c *database.Catalog, key, origin string) (Type, error) {
	db, err := c.DB()
	if err != nil {
		return Type{}, err
	}
	key = strings.TrimSpace(key)
	origin = strings.TrimSpace(origin)
	if key == "" || origin == "" {
		return Type{}, ErrInvalid
	}
	return scanType(db.QueryRow(sqlLookup, key, origin))
}

// List returns all source_types rows, each with its UsedBy total, read in one
// transaction.
func List(c *database.Catalog) ([]Type, error) {
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
	var out []Type
	for rows.Next() {
		var suggested int
		t, err := scanType(rows, &suggested)
		if err != nil {
			rows.Close()
			return nil, err
		}
		t.SuggestedFields = suggested
		out = append(out, t)
	}
	if err := rows.Close(); err != nil {
		return nil, err
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	err = deleteimpact.FillUsedBy(tx, catalogmodel.KindSourceType, out,
		func(t Type) []byte { return t.ID }, func(t *Type, n int) { t.UsedBy = n })
	if err != nil {
		return nil, err
	}
	return out, nil
}

// CreateInput is what a new user-origin type starts with.
type CreateInput struct {
	Label       string
	Description string
	// IconKey is empty for the default mark.
	IconKey string
	// Formats are stored (fields by id, as StoredFormatsTx returns them); the
	// zero value is no formats. The text is stored as is, without citationformat
	// parsing: callers pass text already in stored form (StoredFormatsTx output),
	// and fresh researcher text goes through UpdateFormats.
	Formats Formats
}

// Create mints a kebab-case key from in.Label (see core/slug.Kebab) and
// inserts a new user-origin type on tx, with its formats. Returns ErrInvalid
// if the label cannot form a key or the icon key is unknown, or
// ErrDuplicateKey (params: the colliding key) if a user-origin type with that
// key already exists. The caller records the returned changes.
func Create(tx *database.Tx, in CreateInput) (Type, []rowchange.Change, error) {
	if tx == nil {
		return Type{}, nil, ErrInvalid
	}
	key := slug.Kebab(in.Label)
	if key == "" {
		return Type{}, nil, ErrInvalid
	}
	if _, err := lookupTx(tx.Tx, key, vocabkey.OriginUser); err == nil {
		return Type{}, nil, ErrDuplicateKey.WithParams(key)
	} else if !errors.Is(err, sql.ErrNoRows) {
		return Type{}, nil, err
	}
	label := strings.TrimSpace(in.Label)
	description := strings.TrimSpace(in.Description)
	iconKey, err := NormalizeIconKey(in.IconKey)
	if err != nil {
		return Type{}, nil, err
	}
	if label == "" {
		return Type{}, nil, ErrInvalid
	}
	uid, err := uuid.NewV7()
	if err != nil {
		return Type{}, nil, err
	}
	id := uid[:]
	if _, err := tx.Exec(sqlInsert, id, key, vocabkey.OriginUser, label, database.NullString(description), iconKey,
		database.NullString(in.Formats.Full), database.NullString(in.Formats.Short), database.NullString(in.Formats.List)); err != nil {
		return Type{}, nil, err
	}
	got, err := getByIDTx(tx.Tx, id)
	if err != nil {
		return Type{}, nil, err
	}
	created := Type{ID: id, Key: key, Origin: vocabkey.OriginUser, Label: label, Description: description, IconKey: iconKey}
	return got, []rowchange.Change{createChange(created, in.Formats)}, nil
}

// Update patches label, description, and icon_key for a project type (user
// or provenencia) by id. Key and origin are immutable after create, so a
// rename keeps existing sources attached. Empty icon_key keeps the row's
// current icon. Returns ErrLocked for plugin-origin types. An unchanged
// label, description, and icon returns the existing type and no changes.
// The caller records the returned changes.
func Update(tx *database.Tx, id []byte, label, description, iconKey string) (Type, []rowchange.Change, error) {
	if tx == nil {
		return Type{}, nil, ErrInvalid
	}
	label = strings.TrimSpace(label)
	description = strings.TrimSpace(description)
	if label == "" {
		return Type{}, nil, ErrInvalid
	}
	existing, err := editableTx(tx.Tx, id)
	if err != nil {
		return Type{}, nil, err
	}
	normalizedIcon := existing.IconKey
	if strings.TrimSpace(iconKey) != "" {
		normalizedIcon, err = NormalizeIconKey(iconKey)
		if err != nil {
			return Type{}, nil, err
		}
	} else if normalizedIcon == "" {
		normalizedIcon = DefaultIconKey
	}
	next := existing
	next.Label, next.Description, next.IconKey = label, description, normalizedIcon
	change := updateChange(existing, next, nil)
	if change == nil {
		return existing, nil, nil
	}
	if _, err := tx.Exec(sqlUpdate, label, database.NullString(description), normalizedIcon, id); err != nil {
		return Type{}, nil, err
	}
	got, err := getByIDTx(tx.Tx, id)
	if err != nil {
		return Type{}, nil, err
	}
	return got, []rowchange.Change{*change}, nil
}

// GetByID returns the type with the given id, or sql.ErrNoRows.
func GetByID(c *database.Catalog, id []byte) (Type, error) {
	db, err := c.DB()
	if err != nil {
		return Type{}, err
	}
	if len(id) != 16 {
		return Type{}, ErrInvalid
	}
	return scanType(db.QueryRow(sqlGetByID, id))
}

// SuggestedFields reports how many fields the type suggests at all three
// levels, the number List returns in Type.SuggestedFields.
func SuggestedFields(c *database.Catalog, typeID []byte) (int, error) {
	db, err := c.DB()
	if err != nil {
		return 0, err
	}
	var n int
	if err := db.QueryRow(sqlSuggestedFields+`?`, typeID).Scan(&n); err != nil {
		return 0, err
	}
	return n, nil
}

// Delete erases a type when no sources reference it. Suggestion joins CASCADE.
// Plugin-origin types are origin_locked even when unused. The caller records
// the returned changes.
func Delete(tx *database.Tx, userID, id []byte) ([]rowchange.Change, error) {
	if err := database.RequireUserID(userID, ErrInvalid); err != nil {
		return nil, err
	}
	if tx == nil || len(id) != 16 {
		return nil, ErrInvalid
	}
	prev, err := getByIDTx(tx.Tx, id)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrInvalid
	}
	if err != nil {
		return nil, err
	}

	report, err := deleteimpact.Impact(tx.Tx, catalogmodel.KindSourceType, id)
	if err != nil {
		return nil, err
	}
	if err := deleteimpact.Refuse(report, deleteimpact.Codes{
		InUse: ErrInUse, OriginLocked: ErrOriginLocked, NotFound: ErrInvalid,
	}); err != nil {
		return nil, err
	}
	formats, err := StoredFormatsTx(tx.Tx, [][]byte{id})
	if err != nil {
		return nil, err
	}
	if _, err := tx.Exec(sqlDelete, id); err != nil {
		return nil, err
	}
	ch := rowchange.Deleted("source_type", id, rowFields(prev))
	// A deleted type's formats stay in the revision.
	for column, diff := range formatFieldDiffs(formats[string(id)], Formats{}) {
		ch.Fields[column] = diff
	}
	return []rowchange.Change{ch}, nil
}

// editableTx returns the type with the given id once its origin allows a
// write: ErrInvalid for an id that is not 16 bytes, sql.ErrNoRows for a type
// that is not there, ErrLocked for a plugin's.
func editableTx(tx *sql.Tx, id []byte) (Type, error) {
	if len(id) != 16 {
		return Type{}, ErrInvalid
	}
	t, err := getByIDTx(tx, id)
	if err != nil {
		return Type{}, err
	}
	if !vocabkey.Editable(t.Origin) {
		return Type{}, ErrLocked
	}
	return t, nil
}

// GetByIDTx returns the type with the given id read on tx: ErrInvalid for an
// id that is not 16 bytes, sql.ErrNoRows for a type that is not there.
func GetByIDTx(tx *sql.Tx, id []byte) (Type, error) {
	if len(id) != 16 {
		return Type{}, ErrInvalid
	}
	return getByIDTx(tx, id)
}

func getByIDTx(tx *sql.Tx, id []byte) (Type, error) {
	return scanType(tx.QueryRow(sqlGetByID, id))
}

// GetManyTx returns the types with the given ids, keyed by string(id). A
// repeated id counts once and an id with no type is absent; no ids returns an
// empty map and runs no query. UsedBy and SuggestedFields are left 0.
func GetManyTx(tx *sql.Tx, ids [][]byte) (map[string]Type, error) {
	ids = database.UniqueBlobIDs(ids)
	out := make(map[string]Type, len(ids))
	if len(ids) == 0 {
		return out, nil
	}
	err := sqlbatch.Query(tx, sqlGetIn, ")", nil, ids, func(rows *sql.Rows) error {
		t, err := scanType(rows)
		if err != nil {
			return err
		}
		out[string(t.ID)] = t
		return nil
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}

func lookupTx(tx *sql.Tx, key, origin string) (Type, error) {
	return scanType(tx.QueryRow(sqlLookup, key, origin))
}
