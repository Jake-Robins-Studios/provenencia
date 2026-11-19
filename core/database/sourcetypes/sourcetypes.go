// Package sourcetypes accesses the source_types vocabulary table.
// Create, Update, Delete, and UpsertTx run inside writes.Run and return the row
// changes that Run records. UpsertTx is the seed's write, run inside writes.Run.
package sourcetypes

import (
	"database/sql"
	"errors"
	"strings"

	"github.com/google/uuid"
	"github.com/mendahu/provenencia/core/apperr"
	"github.com/mendahu/provenencia/core/database"
	"github.com/mendahu/provenencia/core/database/catalogmodel"
	"github.com/mendahu/provenencia/core/database/deleteimpact"
	"github.com/mendahu/provenencia/core/database/rowchange"
	"github.com/mendahu/provenencia/core/slug"
	"github.com/mendahu/provenencia/core/vocabkey"
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

const (
	// sqlInsert is the one insert of a new type with its citation formats.
	sqlInsert = `INSERT INTO source_types (id, key, origin, label, description, icon_key, citation_full, citation_short, citation_list)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
	sqlLookup = `SELECT id, key, origin, label, COALESCE(description, ''), icon_key
		FROM source_types WHERE key = ? AND origin = ?`
	sqlGetByID = `SELECT id, key, origin, label, COALESCE(description, ''), icon_key
		FROM source_types WHERE id = ?`
	// sqlSuggestedFields counts the fields a type suggests at all three
	// levels (a field at two levels counts twice); the type id follows it. It
	// is the one place the rule for which suggestions count lives.
	sqlSuggestedFields = `SELECT COUNT(*) FROM source_type_metadata_fields j WHERE j.source_type_id = `
	sqlList            = `SELECT t.id, t.key, t.origin, t.label, COALESCE(t.description, ''), t.icon_key,
			(` + sqlSuggestedFields + `t.id)
		FROM source_types t ORDER BY t.label COLLATE NOCASE, t.origin, t.key`
	sqlUpdate = `UPDATE source_types SET label = ?, description = ?, icon_key = ? WHERE id = ?`
	sqlDelete = `DELETE FROM source_types WHERE id = ?`
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
// that differ (a missing key reads nil); nil when none does. id, key and
// origin are never compared.
func updateChange(prev, next Type) *rowchange.Change {
	old, now := rowFields(prev), rowFields(next)
	fields := rowchange.UpdatedRow(old, now, "id", "key", "origin")
	if len(fields) == 0 {
		return nil
	}
	return &rowchange.Change{
		EntityType: "source_type",
		EntityID:   append([]byte(nil), prev.ID...),
		Action:     rowchange.ActionUpdate,
		Fields:     fields,
	}
}

// createChange is the create change of a new type row: every column, plus the
// format columns that carry text.
func createChange(t Type, formats Formats) rowchange.Change {
	fields := rowchange.FullRow(rowFields(t))
	for column, diff := range formatFieldDiffs(Formats{}, formats) {
		fields[column] = diff
	}
	return rowchange.Change{
		EntityType: "source_type",
		EntityID:   append([]byte(nil), t.ID...),
		Action:     rowchange.ActionCreate,
		Fields:     fields,
	}
}

// UpsertTx inserts or updates by (key, origin) on tx and returns the id and
// the row changes. Missing: a new type with no formats, one create change.
// Present: label, description and icon are written (an empty icon is the
// default mark) and one update change names what differs; nothing differing
// writes nothing and returns no change. A non-empty t.ID is ErrInvalid. The
// caller records the changes.
func UpsertTx(tx *database.Tx, t Type) ([]byte, []rowchange.Change, error) {
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
		if _, err := tx.Exec(sqlInsert, t.ID, t.Key, t.Origin, t.Label, database.NullString(t.Description), t.IconKey, nil, nil, nil); err != nil {
			return nil, nil, err
		}
		return append([]byte(nil), t.ID...), []rowchange.Change{createChange(t, Formats{})}, nil
	}
	if err != nil {
		return nil, nil, err
	}
	next := existing
	next.Label, next.Description, next.IconKey = t.Label, t.Description, t.IconKey
	change := updateChange(existing, next)
	if change == nil {
		return append([]byte(nil), existing.ID...), nil, nil
	}
	if _, err := tx.Exec(sqlUpdate, next.Label, database.NullString(next.Description), next.IconKey, existing.ID); err != nil {
		return nil, nil, err
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
	var t Type
	err = db.QueryRow(sqlLookup, key, origin).Scan(
		&t.ID, &t.Key, &t.Origin, &t.Label, &t.Description, &t.IconKey,
	)
	if err != nil {
		return Type{}, err
	}
	return t, nil
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
		var t Type
		if err := rows.Scan(
			&t.ID, &t.Key, &t.Origin, &t.Label, &t.Description, &t.IconKey,
			&t.SuggestedFields,
		); err != nil {
			rows.Close()
			return nil, err
		}
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
	change := updateChange(existing, next)
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
	var t Type
	err = db.QueryRow(sqlGetByID, id).Scan(
		&t.ID, &t.Key, &t.Origin, &t.Label, &t.Description, &t.IconKey,
	)
	if err != nil {
		return Type{}, err
	}
	return t, nil
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
	fields := rowchange.DeletedRow(rowFields(prev))
	// A deleted type's formats stay in the revision.
	for column, diff := range formatFieldDiffs(formats[string(id)], Formats{}) {
		fields[column] = diff
	}
	return []rowchange.Change{{
		EntityType: "source_type",
		EntityID:   append([]byte(nil), id...),
		Action:     rowchange.ActionDelete,
		Fields:     fields,
	}}, nil
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
	var t Type
	err := tx.QueryRow(sqlGetByID, id).Scan(
		&t.ID, &t.Key, &t.Origin, &t.Label, &t.Description, &t.IconKey,
	)
	return t, err
}

func lookupTx(tx *sql.Tx, key, origin string) (Type, error) {
	var t Type
	err := tx.QueryRow(sqlLookup, key, origin).Scan(
		&t.ID, &t.Key, &t.Origin, &t.Label, &t.Description, &t.IconKey,
	)
	return t, err
}
