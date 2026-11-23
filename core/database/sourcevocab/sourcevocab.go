// Package sourcevocab owns type↔field suggestions (one ordered list per type) and provenencia create-time seed.
//
// Install upserts the shipped vocabulary registry (origin=provenencia) once at
// catalog create. It composes on the caller's transaction and never calls
// writes.Run: onboarding.createCatalog runs it in one writes.Call, so the seed
// is one revision and a failed install leaves nothing. Call it only from there
// — not on open. It does not heal deleted rows on later opens; a second run
// over unchanged rows records nothing.
//
// CopyType also lives here: it copies a type with its suggested fields inside
// the caller's writes.Run and never calls it.
package sourcevocab

import (
	"database/sql"
	"errors"
	"fmt"

	"github.com/Jake-Robins-Studios/provenencia/core/apperr"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sqlbatch"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

var ErrInvalid = apperr.New(apperr.CodeSourceVocabInvalid, apperr.KindUser)

// ActionInstall is the audit action of the create-time seed revision.
const ActionInstall = "install_source_vocabulary"

const (
	sqlEnsureSuggestion = `INSERT INTO source_type_metadata_fields (source_type_id, field_id, sort_order)
		VALUES (?, ?, ?)
		ON CONFLICT(source_type_id, field_id) DO UPDATE SET sort_order = excluded.sort_order`
	sqlDeleteSuggestion = `DELETE FROM source_type_metadata_fields
		WHERE source_type_id = ? AND field_id = ?`
	// The next sort_order is computed inside the INSERT so concurrent
	// appends cannot read the same MAX and share a slot. (The WHERE clause
	// is also what lets SQLite parse INSERT…SELECT with an upsert clause.)
	sqlAppendSuggestion = `INSERT INTO source_type_metadata_fields (source_type_id, field_id, sort_order)
		SELECT ?, ?, COALESCE(MAX(sort_order), -1) + 1
		FROM source_type_metadata_fields WHERE source_type_id = ?
		ON CONFLICT(source_type_id, field_id) DO NOTHING`
)

// sqlListSuggestionsIn reads the suggestions of the types in the IN list the
// caller closes with sqlListSuggestionsTail. The order is one type's order, so
// a type's rows (always in one batch) come back in it.
var sqlListSuggestionsIn = `SELECT ` + metadatafields.Columns("f") + `, j.sort_order, j.source_type_id
	FROM source_type_metadata_fields j
	JOIN source_metadata_fields f ON f.id = j.field_id
	WHERE j.source_type_id IN (`

const sqlListSuggestionsTail = `) ORDER BY j.sort_order ASC, f.label COLLATE NOCASE, f.key`

// Suggestion is one ordered field a source type suggests.
type Suggestion struct {
	Field     metadatafields.Field
	SortOrder int
}

// ensureSuggestionTx inserts or updates the join row's sort_order on tx.
func ensureSuggestionTx(tx *database.Tx, typeID, fieldID []byte, sortOrder int) error {
	if len(typeID) != 16 || len(fieldID) != 16 {
		return ErrInvalid
	}
	_, err := tx.Exec(sqlEnsureSuggestion, typeID, fieldID, sortOrder)
	return err
}

// AppendSuggestion attaches a field to a type at the end of its existing
// order. Re-attaching a field the type already suggests leaves its place
// alone — the join is a set, so assigning twice is not an error.
func AppendSuggestion(c *database.Catalog, typeID, fieldID []byte) error {
	db, err := c.DB()
	if err != nil {
		return err
	}
	if len(typeID) != 16 || len(fieldID) != 16 {
		return ErrInvalid
	}
	// Verify both join sides name real rows. Without this a stale id dies
	// on the FK constraint, which the FFI layer can only report as an
	// internal error rather than a user one.
	if _, err := sourcetypes.GetByID(c, typeID); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return ErrInvalid
		}
		return err
	}
	if _, err := metadatafields.GetByID(c, fieldID); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return ErrInvalid
		}
		return err
	}
	_, err = db.Exec(sqlAppendSuggestion, typeID, fieldID, typeID)
	return err
}

// ListSuggestions returns a type's suggested fields, ordered by sort_order. An
// id that is not 16 bytes is ErrInvalid.
func ListSuggestions(c *database.Catalog, typeID []byte) ([]Suggestion, error) {
	if len(typeID) != 16 {
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
	byType, err := ListSuggestionsTx(tx, [][]byte{typeID})
	if err != nil {
		return nil, err
	}
	return byType[string(typeID)], nil
}

// ListSuggestionsTx reads the suggestions of the given types on an open
// transaction in one batched query, keyed by string(type id), each list in the
// type's order (sort_order, then label, then key). A type with none is absent;
// no ids runs no query. A nil tx is ErrInvalid.
func ListSuggestionsTx(tx *sql.Tx, typeIDs [][]byte) (map[string][]Suggestion, error) {
	if tx == nil {
		return nil, ErrInvalid
	}
	out := map[string][]Suggestion{}
	err := sqlbatch.Query(tx, sqlListSuggestionsIn, sqlListSuggestionsTail, nil, database.UniqueBlobIDs(typeIDs), func(rows *sql.Rows) error {
		var typeID []byte
		var sort sql.NullInt64
		f, err := metadatafields.ScanField(rows, &sort, &typeID)
		if err != nil {
			return err
		}
		s := Suggestion{Field: f}
		if sort.Valid {
			s.SortOrder = int(sort.Int64)
		}
		out[string(typeID)] = append(out[string(typeID)], s)
		return nil
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}

// DeleteSuggestion removes one join row — the detach behind the RemoveTypeField
// RPC. The field itself stays in the vocabulary.
func DeleteSuggestion(c *database.Catalog, typeID, fieldID []byte) error {
	db, err := c.DB()
	if err != nil {
		return err
	}
	if len(typeID) != 16 || len(fieldID) != 16 {
		return ErrInvalid
	}
	_, err = db.Exec(sqlDeleteSuggestion, typeID, fieldID)
	return err
}

// Install writes the provenencia seed registry into a new catalog on tx and
// returns the type and field changes (the suggestion rows are written and are
// not changes). Call only at create time, inside writes.Call
// (onboarding.createCatalog); never call writes.Run here.
func Install(tx *database.Tx) ([]rowchange.Change, error) {
	if tx == nil {
		return nil, ErrInvalid
	}
	var changes []rowchange.Change
	fieldIDs := make(map[string][]byte, len(seedFields))
	for _, f := range seedFields {
		id, cs, err := metadatafields.UpsertTx(tx, metadatafields.Field{
			Key:         f.Key,
			Origin:      vocabkey.OriginProvenencia,
			Label:       f.Label,
			DataType:    f.DataType,
			Description: f.Description,
			UnknownText: f.UnknownText,
		})
		if err != nil {
			return nil, err
		}
		changes = append(changes, cs...)
		fieldIDs[f.Key] = id
	}
	typeIDs := make(map[string][]byte, len(seedTypes))
	for _, t := range seedTypes {
		// The one storage step: keys become the product fields' ids, so a
		// researcher's field with the same key never captures a seeded format.
		stored, diags, err := sourcetypes.ToStored(tx.Tx, t.Formats, nil, vocabkey.OriginProvenencia)
		if err != nil {
			return nil, err
		}
		if len(diags) > 0 {
			return nil, fmt.Errorf("sourcevocab: seed type %s: %v: %w", t.Key, diags, ErrInvalid)
		}
		id, cs, err := sourcetypes.UpsertTx(tx, sourcetypes.Type{
			Key:         t.Key,
			Origin:      vocabkey.OriginProvenencia,
			Label:       t.Label,
			Description: t.Description,
			IconKey:     t.IconKey,
		}, &stored)
		if err != nil {
			return nil, err
		}
		changes = append(changes, cs...)
		typeIDs[t.Key] = id
	}
	for _, s := range seedSuggestions {
		typeID := typeIDs[s.TypeKey]
		if len(typeID) == 0 {
			return nil, ErrInvalid
		}
		for order, key := range s.FieldKeys {
			fieldID := fieldIDs[key]
			if len(fieldID) == 0 {
				return nil, ErrInvalid
			}
			if err := ensureSuggestionTx(tx, typeID, fieldID, order); err != nil {
				return nil, err
			}
		}
	}
	return changes, nil
}
