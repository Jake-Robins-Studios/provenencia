// Package propertyterms accesses the property_terms vocabulary table.
// Create, Update, Delete, and UpsertTx run inside writes.Run and return the row
// changes that Run records. UpsertTx is the seed's write, run inside writes.Run.
package propertyterms

import (
	"bytes"
	"database/sql"
	"errors"
	"strings"

	"github.com/Jake-Robins-Studios/provenencia/core/database/catalogmodel"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/matchregistry"
	"github.com/Jake-Robins-Studios/provenencia/core/valuecompare"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"

	"github.com/Jake-Robins-Studios/provenencia/core/apperr"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/deleteimpact"
	"github.com/Jake-Robins-Studios/provenencia/core/slug"
	"github.com/google/uuid"
)

var ErrInvalid = apperr.New(apperr.CodePropertyTermsInvalid, apperr.KindUser)

// ErrDuplicateKey is returned by Create and Update when a term of the Property
// already reads the same as the label. Its param is that term's label.
var ErrDuplicateKey = apperr.New(apperr.CodePropertyTermsDuplicateKey, apperr.KindConflict)

// ErrLocked is returned when mutating a proveniencia or plugin-origin term.
var ErrLocked = apperr.New(apperr.CodePropertyTermsLocked, apperr.KindUser)

// ErrInUse is returned by Delete when Observations still reference the term.
var ErrInUse = apperr.New(apperr.CodePropertyTermsInUse, apperr.KindConflict)

const (
	// KeyPlaceRelationshipType is product-only: researchers cannot mint terms.
	KeyPlaceRelationshipType = "place_relationship_type"
	// Locked place_relationship_type keys (part_of = containment;
	// succeeded_by = succession). Which of them may not loop is
	// connectrules.Bridge.AcyclicTerms.
	KeyPartOf      = string(vocabkey.TermPartOf)
	KeySucceededBy = string(vocabkey.TermSucceededBy)

	// sqlInsert is the one insert of a new term.
	sqlInsert = `INSERT INTO property_terms (id, property_id, key, origin, label, description, directed, inverse_key, neutral)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
	sqlTermCols = `id, property_id, key, origin, label, COALESCE(description, ''), directed, COALESCE(inverse_key, ''), neutral`
	sqlLookup   = `SELECT ` + sqlTermCols + `
		FROM property_terms WHERE property_id = ? AND key = ? AND origin = ?`
	sqlGetByID = `SELECT ` + sqlTermCols + `
		FROM property_terms WHERE id = ?`
	sqlListByProperty = `SELECT ` + sqlTermCols + `
		FROM property_terms WHERE property_id = ?
		ORDER BY label COLLATE NOCASE, origin, key`
	sqlUpdate      = `UPDATE property_terms SET label = ?, description = ?, directed = ?, inverse_key = ?, neutral = ? WHERE id = ?`
	sqlDelete      = `DELETE FROM property_terms WHERE id = ?`
	sqlPropertyKey = `SELECT key FROM properties WHERE id = ? AND origin = ?`
)

// Term is one property_terms row.
type Term struct {
	ID          []byte
	PropertyID  []byte
	Key         string
	Origin      string
	Label       string
	Description string
	Directed    bool // kinship / place-relationship: order is part of the key
	// InverseKey names the term (same Property and origin) that reads the
	// same relationship from the other end: parent ↔ child. Empty when none.
	InverseKey string
	// Neutral terms are no evidence either way ("unknown" sex at birth):
	// reconciliation never lets one win, and matching never compares one.
	Neutral bool
}

// rowFields is the audit view of a term: the one column list that create,
// update and delete changes are built from. description and inverse_key are
// present only when not empty, directed and neutral only when set, so a
// researcher's term (never directed, neutral or inverted) records the same keys
// as before the seed shared this list.
func rowFields(t Term) map[string]any {
	fields := map[string]any{
		"id":          database.UUIDString(t.ID),
		"property_id": database.UUIDString(t.PropertyID),
		"key":         t.Key,
		"origin":      t.Origin,
		"label":       t.Label,
	}
	if t.Description != "" {
		fields["description"] = t.Description
	}
	if t.Directed {
		fields["directed"] = true
	}
	if t.InverseKey != "" {
		fields["inverse_key"] = t.InverseKey
	}
	if t.Neutral {
		fields["neutral"] = true
	}
	return fields
}

// createChange is the create change of a new term row: every column that holds
// a value.
func createChange(t Term) rowchange.Change {
	return rowchange.Change{
		EntityType: "property_term",
		EntityID:   append([]byte(nil), t.ID...),
		Action:     rowchange.ActionCreate,
		Fields:     rowchange.FullRow(rowFields(t)),
	}
}

// updateChange is the update change from prev to next, naming only the columns
// that differ (a missing key reads nil); nil when nothing differs. id,
// property_id, key and origin are never compared.
func updateChange(prev, next Term) *rowchange.Change {
	fields := rowchange.UpdatedRow(rowFields(prev), rowFields(next), "id", "property_id", "key", "origin")
	if len(fields) == 0 {
		return nil
	}
	return &rowchange.Change{
		EntityType: "property_term",
		EntityID:   append([]byte(nil), prev.ID...),
		Action:     rowchange.ActionUpdate,
		Fields:     fields,
	}
}

// UpsertTx inserts or updates by (property_id, key, origin) on tx and returns
// the id and the row changes. Missing: a new term, one create change. Present:
// label, description, directed, inverse_key and neutral are written and one
// update change names what differs; nothing differing writes nothing and
// returns no change. A non-empty t.ID is ErrInvalid. The caller records the
// changes.
func UpsertTx(tx *database.Tx, t Term) ([]byte, []rowchange.Change, error) {
	if tx == nil || len(t.ID) != 0 {
		return nil, nil, ErrInvalid
	}
	t.Key = strings.TrimSpace(t.Key)
	t.Origin = strings.TrimSpace(t.Origin)
	t.Label = strings.TrimSpace(t.Label)
	t.Description = strings.TrimSpace(t.Description)
	t.InverseKey = strings.TrimSpace(t.InverseKey)
	if len(t.PropertyID) != 16 || t.Key == "" || t.Label == "" || !vocabkey.ValidOrigin(t.Origin) {
		return nil, nil, ErrInvalid
	}
	existing, err := lookupTx(tx, t.PropertyID, t.Key, t.Origin)
	if errors.Is(err, sql.ErrNoRows) {
		uid, err := uuid.NewV7()
		if err != nil {
			return nil, nil, err
		}
		t.ID = uid[:]
		if _, err := tx.Exec(sqlInsert, t.ID, t.PropertyID, t.Key, t.Origin, t.Label, database.NullString(t.Description), directedBit(t.Directed), database.NullString(t.InverseKey), directedBit(t.Neutral)); err != nil {
			return nil, nil, err
		}
		return append([]byte(nil), t.ID...), []rowchange.Change{createChange(t)}, nil
	}
	if err != nil {
		return nil, nil, err
	}
	next := existing
	next.Label, next.Description = t.Label, t.Description
	next.Directed, next.InverseKey, next.Neutral = t.Directed, t.InverseKey, t.Neutral
	change := updateChange(existing, next)
	if change == nil {
		return append([]byte(nil), existing.ID...), nil, nil
	}
	if _, err := tx.Exec(sqlUpdate, next.Label, database.NullString(next.Description), directedBit(next.Directed), database.NullString(next.InverseKey), directedBit(next.Neutral), existing.ID); err != nil {
		return nil, nil, err
	}
	return append([]byte(nil), existing.ID...), []rowchange.Change{*change}, nil
}

// Create mints a kebab-case key from label and inserts a user-origin term.
// Refuses place_relationship_type (product-locked vocabulary). The caller
// records the returned changes.
func Create(tx *database.Tx, userID, propertyID []byte, label, description string) (Term, []rowchange.Change, error) {
	if err := database.RequireUserID(userID, ErrInvalid); err != nil {
		return Term{}, nil, err
	}
	if tx == nil || len(propertyID) != 16 {
		return Term{}, nil, ErrInvalid
	}
	if locked, err := propertyTermsLocked(tx.Tx, propertyID); err != nil {
		return Term{}, nil, err
	} else if locked {
		return Term{}, nil, ErrLocked
	}
	key := slug.Kebab(label)
	if key == "" {
		return Term{}, nil, ErrInvalid
	}
	if dup, found, err := conflictingTerm(tx, propertyID, nil, label, key); err != nil {
		return Term{}, nil, err
	} else if found {
		return Term{}, nil, ErrDuplicateKey.WithParams(dup.Label)
	}

	uid, err := uuid.NewV7()
	if err != nil {
		return Term{}, nil, err
	}
	id := uid[:]
	label = strings.TrimSpace(label)
	description = strings.TrimSpace(description)
	if label == "" {
		return Term{}, nil, ErrInvalid
	}
	if _, err := tx.Exec(sqlInsert, id, propertyID, key, vocabkey.OriginUser, label, database.NullString(description), 0, nil, 0); err != nil {
		return Term{}, nil, err
	}
	term, err := scanTerm(tx.QueryRow(sqlGetByID, id))
	if err != nil {
		return Term{}, nil, err
	}
	return term, []rowchange.Change{createChange(term)}, nil
}

// Update patches label and description for a user-origin term.
// Key, origin, and property_id are immutable. Returns ErrLocked for product/plugin terms.
// An unchanged label and description returns the existing term and no changes.
func Update(tx *database.Tx, userID, id []byte, label, description string) (Term, []rowchange.Change, error) {
	if err := database.RequireUserID(userID, ErrInvalid); err != nil {
		return Term{}, nil, err
	}
	if tx == nil {
		return Term{}, nil, ErrInvalid
	}
	label = strings.TrimSpace(label)
	description = strings.TrimSpace(description)
	if len(id) != 16 || label == "" {
		return Term{}, nil, ErrInvalid
	}
	existing, err := scanTerm(tx.QueryRow(sqlGetByID, id))
	if err != nil {
		return Term{}, nil, err
	}
	if existing.Origin != vocabkey.OriginUser {
		return Term{}, nil, ErrLocked
	}

	if existing.Label != label {
		if dup, found, err := conflictingTerm(tx, existing.PropertyID, id, label, ""); err != nil {
			return Term{}, nil, err
		} else if found {
			return Term{}, nil, ErrDuplicateKey.WithParams(dup.Label)
		}
	}

	next := existing
	next.Label, next.Description = label, description
	change := updateChange(existing, next)
	if change == nil {
		return existing, nil, nil
	}
	if _, err := tx.Exec(sqlUpdate, label, database.NullString(description), directedBit(existing.Directed), database.NullString(existing.InverseKey), directedBit(existing.Neutral), id); err != nil {
		return Term{}, nil, err
	}
	term, err := scanTerm(tx.QueryRow(sqlGetByID, id))
	if err != nil {
		return Term{}, nil, err
	}
	return term, []rowchange.Change{*change}, nil
}

// valueWords are the shipped registry's word rules, never catalog data: a text
// key reads nothing else.
var valueWords = matchregistry.Default().Value.Words

// conflictingTerm is the first term of the Property, other than selfID, that
// reads the same as label (the same text key at Equivalent, any origin) or,
// when slugKey is set, is a user term with that key: the upsert would
// overwrite it. A label with no text key is ErrInvalid.
func conflictingTerm(tx *database.Tx, propertyID, selfID []byte, label, slugKey string) (Term, bool, error) {
	want, ok := valuecompare.TextKey(label, valuecompare.Equivalent, valueWords)
	if !ok {
		return Term{}, false, ErrInvalid
	}
	rows, err := tx.Query(sqlListByProperty, propertyID)
	if err != nil {
		return Term{}, false, err
	}
	defer rows.Close()
	for rows.Next() {
		t, err := scanTermRows(rows)
		if err != nil {
			return Term{}, false, err
		}
		if bytes.Equal(t.ID, selfID) {
			continue
		}
		if k, ok := valuecompare.TextKey(t.Label, valuecompare.Equivalent, valueWords); (ok && k == want) ||
			(slugKey != "" && t.Origin == vocabkey.OriginUser && t.Key == slugKey) {
			return t, true, nil
		}
	}
	return Term{}, false, rows.Err()
}

// Delete removes a user-origin term when unused. Product/plugin terms are locked.
// The caller records the returned changes.
func Delete(tx *database.Tx, userID, id []byte) ([]rowchange.Change, error) {
	if err := database.RequireUserID(userID, ErrInvalid); err != nil {
		return nil, err
	}
	if tx == nil || len(id) != 16 {
		return nil, ErrInvalid
	}
	existing, err := scanTerm(tx.QueryRow(sqlGetByID, id))
	if err != nil {
		return nil, err
	}

	report, err := deleteimpact.Impact(tx.Tx, catalogmodel.KindPropertyTerm, id)
	if err != nil {
		return nil, err
	}
	if err := deleteimpact.Refuse(report, deleteimpact.Codes{
		InUse: ErrInUse, OriginLocked: ErrLocked, NotFound: ErrInvalid,
	}); err != nil {
		return nil, err
	}

	if _, err := tx.Exec(sqlDelete, id); err != nil {
		return nil, err
	}
	return []rowchange.Change{{
		EntityType: "property_term",
		EntityID:   append([]byte(nil), id...),
		Action:     rowchange.ActionDelete,
		Fields:     rowchange.DeletedRow(rowFields(existing)),
	}}, nil
}

// Lookup returns the term for (propertyID, key, origin).
func Lookup(c *database.Catalog, propertyID []byte, key, origin string) (Term, error) {
	db, err := c.DB()
	if err != nil {
		return Term{}, err
	}
	return lookupTx(db, propertyID, key, origin)
}

// lookupTx is Lookup on any reader: the one scan of a (property, key, origin)
// term.
func lookupTx(q database.Querier, propertyID []byte, key, origin string) (Term, error) {
	return scanTerm(q.QueryRow(sqlLookup, propertyID, strings.TrimSpace(key), strings.TrimSpace(origin)))
}

// GetByID returns the term by primary key.
func GetByID(c *database.Catalog, id []byte) (Term, error) {
	db, err := c.DB()
	if err != nil {
		return Term{}, err
	}
	if len(id) != 16 {
		return Term{}, ErrInvalid
	}
	return scanTerm(db.QueryRow(sqlGetByID, id))
}

// ListByProperty returns all terms for a Property, label order.
func ListByProperty(c *database.Catalog, propertyID []byte) ([]Term, error) {
	db, err := c.DB()
	if err != nil {
		return nil, err
	}
	if len(propertyID) != 16 {
		return nil, ErrInvalid
	}
	rows, err := db.Query(sqlListByProperty, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []Term
	for rows.Next() {
		t, err := scanTermRows(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, t)
	}
	return out, rows.Err()
}

func scanTerm(row *sql.Row) (Term, error) {
	var t Term
	var directed, neutral int
	err := row.Scan(&t.ID, &t.PropertyID, &t.Key, &t.Origin, &t.Label, &t.Description, &directed, &t.InverseKey, &neutral)
	if err != nil {
		return Term{}, err
	}
	t.Directed = directed != 0
	t.Neutral = neutral != 0
	return t, nil
}

func scanTermRows(rows *sql.Rows) (Term, error) {
	var t Term
	var directed, neutral int
	err := rows.Scan(&t.ID, &t.PropertyID, &t.Key, &t.Origin, &t.Label, &t.Description, &directed, &t.InverseKey, &neutral)
	if err != nil {
		return Term{}, err
	}
	t.Directed = directed != 0
	t.Neutral = neutral != 0
	return t, nil
}

func directedBit(on bool) int {
	if on {
		return 1
	}
	return 0
}

func propertyTermsLocked(tx *sql.Tx, propertyID []byte) (bool, error) {
	var key string
	err := tx.QueryRow(sqlPropertyKey, propertyID, vocabkey.OriginProvenencia).Scan(&key)
	if errors.Is(err, sql.ErrNoRows) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	return key == KeyPlaceRelationshipType, nil
}
