// Package sourcecredibilitygrades accesses source_credibility_grades vocabulary.
package sourcecredibilitygrades

import (
	"database/sql"
	"errors"
	"strings"

	"github.com/Jake-Robins-Studios/provenencia/core/apperr"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/google/uuid"
)

var ErrInvalid = apperr.New(apperr.CodeSourceCredibilityInvalid, apperr.KindUser)

const (
	// sqlInsert is the one insert of a new grade.
	sqlInsert = `INSERT INTO source_credibility_grades (id, key, origin, label, sort_order)
		VALUES (?, ?, ?, ?, ?)`
	sqlUpdate = `UPDATE source_credibility_grades SET label = ?, sort_order = ? WHERE id = ?`
	sqlLookup = `SELECT id, key, origin, label, sort_order
		FROM source_credibility_grades WHERE key = ? AND origin = ?`
	sqlGetByID = `SELECT id, key, origin, label, sort_order
		FROM source_credibility_grades WHERE id = ?`
	sqlList = `SELECT id, key, origin, label, sort_order
		FROM source_credibility_grades
		ORDER BY sort_order ASC, label COLLATE NOCASE, key`
)

// Grade is one source_credibility_grades row.
type Grade struct {
	ID        []byte
	Key       string
	Origin    string
	Label     string
	SortOrder int
}

// rowFields is the audit view of a grade: the one column list that create and
// update changes are built from.
func rowFields(g Grade) map[string]any {
	return map[string]any{
		"id":         database.UUIDString(g.ID),
		"key":        g.Key,
		"origin":     g.Origin,
		"label":      g.Label,
		"sort_order": g.SortOrder,
	}
}

// UpsertTx inserts or updates by (key, origin) on tx and returns the id and the
// row changes. Missing: a new grade, one create change. Present: label and
// sort_order are written and one update change names what differs; nothing
// differing writes nothing and returns no change. A non-empty g.ID is
// ErrInvalid. The caller records the changes.
func UpsertTx(tx *database.Tx, g Grade) ([]byte, []rowchange.Change, error) {
	if tx == nil || len(g.ID) != 0 {
		return nil, nil, ErrInvalid
	}
	g.Key = strings.TrimSpace(g.Key)
	g.Origin = strings.TrimSpace(g.Origin)
	g.Label = strings.TrimSpace(g.Label)
	if g.Key == "" || g.Label == "" || !vocabkey.ValidOrigin(g.Origin) {
		return nil, nil, ErrInvalid
	}
	existing, err := lookupTx(tx, g.Key, g.Origin)
	if errors.Is(err, sql.ErrNoRows) {
		uid, err := uuid.NewV7()
		if err != nil {
			return nil, nil, err
		}
		g.ID = uid[:]
		if _, err := tx.Exec(sqlInsert, g.ID, g.Key, g.Origin, g.Label, g.SortOrder); err != nil {
			return nil, nil, err
		}
		return append([]byte(nil), g.ID...), []rowchange.Change{rowchange.Created("source_credibility_grade", g.ID, rowFields(g))}, nil
	}
	if err != nil {
		return nil, nil, err
	}
	next := existing
	next.Label, next.SortOrder = g.Label, g.SortOrder
	change := rowchange.Updated("source_credibility_grade", existing.ID, rowFields(existing), rowFields(next), "id", "key", "origin")
	if change == nil {
		return append([]byte(nil), existing.ID...), nil, nil
	}
	if _, err := tx.Exec(sqlUpdate, next.Label, next.SortOrder, existing.ID); err != nil {
		return nil, nil, err
	}
	return append([]byte(nil), existing.ID...), []rowchange.Change{*change}, nil
}

// Lookup returns the grade for (key, origin), or sql.ErrNoRows.
func Lookup(c *database.Catalog, key, origin string) (Grade, error) {
	db, err := c.DB()
	if err != nil {
		return Grade{}, err
	}
	return lookupTx(db, key, origin)
}

// lookupTx is Lookup on any reader: the one scan of a (key, origin) grade.
func lookupTx(q database.Querier, key, origin string) (Grade, error) {
	key = strings.TrimSpace(key)
	origin = strings.TrimSpace(origin)
	if key == "" || origin == "" {
		return Grade{}, ErrInvalid
	}
	return scanGrade(q.QueryRow(sqlLookup, key, origin))
}

// GetByID returns a grade by id, or sql.ErrNoRows.
func GetByID(c *database.Catalog, id []byte) (Grade, error) {
	db, err := c.DB()
	if err != nil {
		return Grade{}, err
	}
	if len(id) != 16 {
		return Grade{}, ErrInvalid
	}
	return scanGrade(db.QueryRow(sqlGetByID, id))
}

// List returns all grades ordered by sort_order.
func List(c *database.Catalog) ([]Grade, error) {
	db, err := c.DB()
	if err != nil {
		return nil, err
	}
	rows, err := db.Query(sqlList)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []Grade
	for rows.Next() {
		g, err := scanGrade(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, g)
	}
	return out, rows.Err()
}

func scanGrade(row database.Scanner) (Grade, error) {
	var g Grade
	if err := row.Scan(&g.ID, &g.Key, &g.Origin, &g.Label, &g.SortOrder); err != nil {
		return Grade{}, err
	}
	return g, nil
}
