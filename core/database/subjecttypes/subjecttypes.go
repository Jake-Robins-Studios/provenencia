// Package subjecttypes accesses the subject_types vocabulary table.
//
// Subject types are product-seeded (and later plugin-seeded), not researcher-
// authored. UpsertTx is for create-time Install and plugin Install, run inside
// writes.Run — there is no user-origin Create/Update/Delete path.
package subjecttypes

import (
	"database/sql"
	"errors"
	"strings"

	"github.com/Jake-Robins-Studios/provenencia/core/apperr"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/ref"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/google/uuid"
)

var ErrInvalid = apperr.New(apperr.CodeSubjectTypesInvalid, apperr.KindUser)

// ErrDuplicatePrefix is returned when a ref_prefix or candidate_ref_prefix
// collides with any existing value in either column (shared namespace).
var ErrDuplicatePrefix = apperr.New(apperr.CodeSubjectTypesDuplicatePrefix, apperr.KindConflict)

const (
	// sqlInsert is the one insert of a new type.
	sqlInsert = `INSERT INTO subject_types (
			id, key, origin, label, description, ref_prefix, candidate_ref_prefix
		) VALUES (?, ?, ?, ?, ?, ?, ?)`
	sqlUpdate = `UPDATE subject_types SET label = ?, description = ?, ref_prefix = ?, candidate_ref_prefix = ? WHERE id = ?`
	sqlLookup = `SELECT id, key, origin, label, COALESCE(description, ''),
			ref_prefix, candidate_ref_prefix
		FROM subject_types WHERE key = ? AND origin = ?`
	sqlGetByID = `SELECT id, key, origin, label, COALESCE(description, ''),
			ref_prefix, candidate_ref_prefix
		FROM subject_types WHERE id = ?`
	sqlList = `SELECT id, key, origin, label, COALESCE(description, ''),
			ref_prefix, candidate_ref_prefix
		FROM subject_types
		ORDER BY label COLLATE NOCASE, origin, key`
	// Shared three-letter namespace across both prefix columns, excluding this row.
	sqlPrefixTaken = `SELECT 1 FROM subject_types
		WHERE (ref_prefix = ? OR candidate_ref_prefix = ? OR ref_prefix = ? OR candidate_ref_prefix = ?)
			AND id != ?
		LIMIT 1`
)

// Type is one subject_types row.
type Type struct {
	ID                 []byte
	Key                string
	Origin             string
	Label              string
	Description        string
	RefPrefix          string
	CandidateRefPrefix string
}

// rowFields is the audit view of a type: the one column list that create and
// update changes are built from. Description is present only when not empty.
func rowFields(t Type) map[string]any {
	fields := map[string]any{
		"id":                   database.UUIDString(t.ID),
		"key":                  t.Key,
		"origin":               t.Origin,
		"label":                t.Label,
		"ref_prefix":           t.RefPrefix,
		"candidate_ref_prefix": t.CandidateRefPrefix,
	}
	if t.Description != "" {
		fields["description"] = t.Description
	}
	return fields
}

// createChange is the create change of a new type row: every column.
func createChange(t Type) rowchange.Change {
	return rowchange.Change{
		EntityType: "subject_type",
		EntityID:   append([]byte(nil), t.ID...),
		Action:     rowchange.ActionCreate,
		Fields:     rowchange.FullRow(rowFields(t)),
	}
}

// updateChange is the update change from prev to next, naming only the columns
// that differ (a missing key reads nil); nil when nothing differs. id, key and
// origin are never compared.
func updateChange(prev, next Type) *rowchange.Change {
	fields := rowchange.UpdatedRow(rowFields(prev), rowFields(next), "id", "key", "origin")
	if len(fields) == 0 {
		return nil
	}
	return &rowchange.Change{
		EntityType: "subject_type",
		EntityID:   append([]byte(nil), prev.ID...),
		Action:     rowchange.ActionUpdate,
		Fields:     fields,
	}
}

// UpsertTx inserts or updates by (key, origin) on tx and returns the id and the
// row changes. Origin must be provenencia or plugin:<id>. Validates both
// prefixes via ref.ValidatePrefix and enforces cross-column uniqueness.
// Missing: a new type, one create change. Present: label, description and both
// prefixes are written and one update change names what differs; nothing
// differing writes nothing and returns no change. A non-empty t.ID is
// ErrInvalid. The caller records the changes.
func UpsertTx(tx *database.Tx, t Type) ([]byte, []rowchange.Change, error) {
	if tx == nil || len(t.ID) != 0 {
		return nil, nil, ErrInvalid
	}
	t.Key = strings.TrimSpace(t.Key)
	t.Origin = strings.TrimSpace(t.Origin)
	t.Label = strings.TrimSpace(t.Label)
	t.Description = strings.TrimSpace(t.Description)
	if t.Key == "" || t.Label == "" || !originOK(t.Origin) {
		return nil, nil, ErrInvalid
	}

	refPrefix, err := ref.ValidatePrefix(t.RefPrefix)
	if err != nil {
		return nil, nil, err
	}
	candPrefix, err := ref.ValidatePrefix(t.CandidateRefPrefix)
	if err != nil {
		return nil, nil, err
	}
	if refPrefix == candPrefix {
		return nil, nil, ErrDuplicatePrefix.WithParams(refPrefix)
	}
	t.RefPrefix = refPrefix
	t.CandidateRefPrefix = candPrefix

	existing, err := LookupTx(tx.Tx, t.Key, t.Origin)
	missing := errors.Is(err, sql.ErrNoRows)
	if err != nil && !missing {
		return nil, nil, err
	}
	if missing {
		uid, err := uuid.NewV7()
		if err != nil {
			return nil, nil, err
		}
		existing.ID = uid[:]
	}

	var taken int
	err = tx.QueryRow(sqlPrefixTaken, refPrefix, refPrefix, candPrefix, candPrefix, existing.ID).Scan(&taken)
	if err == nil {
		return nil, nil, ErrDuplicatePrefix.WithParams(refPrefix)
	}
	if !errors.Is(err, sql.ErrNoRows) {
		return nil, nil, err
	}

	if missing {
		t.ID = existing.ID
		if _, err := tx.Exec(sqlInsert, t.ID, t.Key, t.Origin, t.Label, database.NullString(t.Description), t.RefPrefix, t.CandidateRefPrefix); err != nil {
			return nil, nil, err
		}
		return append([]byte(nil), t.ID...), []rowchange.Change{createChange(t)}, nil
	}
	next := existing
	next.Label, next.Description = t.Label, t.Description
	next.RefPrefix, next.CandidateRefPrefix = t.RefPrefix, t.CandidateRefPrefix
	change := updateChange(existing, next)
	if change == nil {
		return append([]byte(nil), existing.ID...), nil, nil
	}
	if _, err := tx.Exec(sqlUpdate, next.Label, database.NullString(next.Description), next.RefPrefix, next.CandidateRefPrefix, existing.ID); err != nil {
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
	return LookupTx(db, key, origin)
}

// LookupTx returns the type for (key, origin) on an open transaction.
func LookupTx(q database.Querier, key, origin string) (Type, error) {
	key = strings.TrimSpace(key)
	origin = strings.TrimSpace(origin)
	if key == "" || origin == "" {
		return Type{}, ErrInvalid
	}
	return scanType(q.QueryRow(sqlLookup, key, origin))
}

// GetByID returns a type by id, or sql.ErrNoRows.
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

// GetByIDTx returns a type by id on an open transaction.
func GetByIDTx(tx *sql.Tx, id []byte) (Type, error) {
	if len(id) != 16 {
		return Type{}, ErrInvalid
	}
	return scanType(tx.QueryRow(sqlGetByID, id))
}

// List returns all subject_types rows.
func List(c *database.Catalog) ([]Type, error) {
	db, err := c.DB()
	if err != nil {
		return nil, err
	}
	rows, err := db.Query(sqlList)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []Type
	for rows.Next() {
		t, err := scanType(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, t)
	}
	return out, rows.Err()
}

func scanType(row database.Scanner) (Type, error) {
	var t Type
	if err := row.Scan(
		&t.ID, &t.Key, &t.Origin, &t.Label, &t.Description,
		&t.RefPrefix, &t.CandidateRefPrefix,
	); err != nil {
		return Type{}, err
	}
	return t, nil
}

func originOK(origin string) bool {
	return origin == vocabkey.OriginProvenencia || vocabkey.IsPluginOrigin(origin)
}
