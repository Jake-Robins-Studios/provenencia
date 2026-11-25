package sources

import (
	"database/sql"
	"errors"
	"strings"

	"github.com/Jake-Robins-Studios/provenencia/core/database/audit"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/project"
	"github.com/google/uuid"
)

const (
	sqlInsertNote = `INSERT INTO source_notes (id, source_id, body) VALUES (?, ?, ?)`
	sqlUpdateNote = `UPDATE source_notes SET body = ? WHERE id = ?`
	sqlDeleteNote = `DELETE FROM source_notes WHERE id = ?`
	sqlGetNote    = `SELECT id, source_id, body FROM source_notes WHERE id = ?`
	// Create attribution lives in audit, not on source_notes (see source-layer-data-model §4.1);
	// the readers add it from audit.Created.
	sqlListNotes    = `SELECT id, source_id, body FROM source_notes WHERE source_id = ? ORDER BY id`
	sqlSourceExists = `SELECT 1 FROM sources WHERE id = ?`
)

// Note is one source_notes row plus create attribution from audit for UI.
type Note struct {
	ID                []byte
	SourceID          []byte
	Body              string
	AuthorDisplayName string // users.display_name from create_source_note
	CreatedAt         string // RFC3339 UTC from create audit transaction
}

// AddNote inserts a note. The caller records the returned changes.
// AuthorDisplayName stays empty; the caller fills it from the user after Run.
func AddNote(tx *database.Tx, userID, sourceID []byte, body string) (Note, []rowchange.Change, error) {
	body = strings.TrimSpace(body)
	if tx == nil || len(sourceID) != 16 || body == "" {
		return Note{}, nil, ErrInvalid
	}
	if err := database.RequireUserID(userID, ErrInvalid); err != nil {
		return Note{}, nil, err
	}
	if err := requireSource(tx.Tx, sourceID); err != nil {
		return Note{}, nil, err
	}
	id, err := uuid.NewV7()
	if err != nil {
		return Note{}, nil, err
	}
	idBytes := id[:]
	if _, err := tx.Exec(sqlInsertNote, idBytes, sourceID, body); err != nil {
		return Note{}, nil, mapConstraint(err)
	}
	return Note{
			ID:        append([]byte(nil), idBytes...),
			SourceID:  append([]byte(nil), sourceID...),
			Body:      body,
			CreatedAt: project.NowUTC(),
		}, []rowchange.Change{rowchange.Created("source_note", idBytes, map[string]any{
			"id":        id.String(),
			"source_id": database.UUIDString(sourceID),
			"body":      body,
		})}, nil
}

// UpdateNote changes body. An unchanged body returns no changes.
func UpdateNote(tx *database.Tx, userID, noteID []byte, body string) ([]rowchange.Change, error) {
	body = strings.TrimSpace(body)
	if tx == nil || len(noteID) != 16 || body == "" {
		return nil, ErrInvalid
	}
	if err := database.RequireUserID(userID, ErrInvalid); err != nil {
		return nil, err
	}
	prev, err := getNote(tx.Tx, noteID)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrInvalid
	}
	if err != nil {
		return nil, err
	}
	change := rowchange.Updated("source_note", noteID, map[string]any{"body": prev.Body}, map[string]any{"body": body})
	if change == nil {
		return nil, nil
	}
	if _, err := tx.Exec(sqlUpdateNote, body, noteID); err != nil {
		return nil, err
	}
	return []rowchange.Change{*change}, nil
}

// DeleteNote removes a note. The caller records the returned changes.
func DeleteNote(tx *database.Tx, userID, noteID []byte) ([]rowchange.Change, error) {
	if tx == nil || len(noteID) != 16 {
		return nil, ErrInvalid
	}
	if err := database.RequireUserID(userID, ErrInvalid); err != nil {
		return nil, err
	}
	prev, err := getNote(tx.Tx, noteID)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrInvalid
	}
	if err != nil {
		return nil, err
	}
	if _, err := tx.Exec(sqlDeleteNote, noteID); err != nil {
		return nil, err
	}
	return []rowchange.Change{rowchange.Deleted("source_note", noteID, map[string]any{
		"id":        database.UUIDString(noteID),
		"source_id": database.UUIDString(prev.SourceID),
		"body":      prev.Body,
	})}, nil
}

// ListNotes returns notes for a Source with create attribution, ordered by id.
func ListNotes(c *database.Catalog, sourceID []byte) ([]Note, error) {
	db, err := c.DB()
	if err != nil {
		return nil, err
	}
	if len(sourceID) != 16 {
		return nil, ErrInvalid
	}
	rows, err := db.Query(sqlListNotes, sourceID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []Note
	for rows.Next() {
		var n Note
		if err := rows.Scan(&n.ID, &n.SourceID, &n.Body); err != nil {
			return nil, err
		}
		out = append(out, n)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	// The scan is finished: the catalog has one connection.
	if err := attributeNotes(db, out); err != nil {
		return nil, err
	}
	return out, nil
}

// GetNote returns one note with create attribution.
func GetNote(c *database.Catalog, noteID []byte) (Note, error) {
	db, err := c.DB()
	if err != nil {
		return Note{}, err
	}
	if len(noteID) != 16 {
		return Note{}, ErrInvalid
	}
	n, err := getNote(db, noteID)
	if errors.Is(err, sql.ErrNoRows) {
		return Note{}, ErrInvalid
	}
	if err != nil {
		return Note{}, err
	}
	one := []Note{n}
	if err := attributeNotes(db, one); err != nil {
		return Note{}, err
	}
	return one[0], nil
}

// attributeNotes sets AuthorDisplayName and CreatedAt on each note from its
// create audit transaction (audit.Created).
func attributeNotes(q database.Querier, notes []Note) error {
	ids := make([][]byte, 0, len(notes))
	for _, n := range notes {
		ids = append(ids, n.ID)
	}
	made, err := audit.Created(q, "source_note", ids)
	if err != nil {
		return err
	}
	for i := range notes {
		c := made[string(notes[i].ID)]
		notes[i].AuthorDisplayName, notes[i].CreatedAt = c.UserDisplayName, c.At
	}
	return nil
}

func getNote(q database.Querier, id []byte) (Note, error) {
	var n Note
	err := q.QueryRow(sqlGetNote, id).Scan(&n.ID, &n.SourceID, &n.Body)
	if err != nil {
		return Note{}, err
	}
	return n, nil
}

func requireSource(tx *sql.Tx, sourceID []byte) error {
	var one int
	err := tx.QueryRow(sqlSourceExists, sourceID).Scan(&one)
	if errors.Is(err, sql.ErrNoRows) {
		return ErrInvalid
	}
	return err
}
