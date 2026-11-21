package database

import (
	"bytes"
	"database/sql"
	"errors"
	"slices"

	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sqlbatch"
)

// SetSource is the body of every table's SetSourceTx: it moves the rows the
// keys select to sourceID and returns one update change per row that changed,
// in ascending id order. selectHead reads "id, source_id" of the rows the keys
// name and ends inside the IN list; updateHead is the UPDATE that sets
// source_id = ? WHERE source_id != ? AND <key> IN (, binding sourceID twice.
// A key with no row, a repeated key and a row already on sourceID change
// nothing, and no keys run no statement. The SQL stays in the calling package;
// entity is the audited EntityType of the changes.
func SetSource(tx *sql.Tx, entity, selectHead, updateHead string, keys [][]byte, sourceID []byte) ([]rowchange.Change, error) {
	if len(sourceID) != 16 {
		return nil, errors.New("database.SetSource: sourceID is not 16 bytes")
	}
	keys = UniqueBlobIDs(keys)
	var changes []rowchange.Change
	err := sqlbatch.Query(tx, selectHead, `)`, nil, keys, func(rows *sql.Rows) error {
		var id, old []byte
		if err := rows.Scan(&id, &old); err != nil {
			return err
		}
		if bytes.Equal(old, sourceID) {
			return nil
		}
		changes = append(changes, *rowchange.Updated(entity, id,
			map[string]any{"source_id": UUIDJSON(old)},
			map[string]any{"source_id": UUIDJSON(sourceID)}))
		return nil
	})
	if err != nil {
		return nil, err
	}
	if len(changes) == 0 {
		return nil, nil
	}
	slices.SortFunc(changes, func(a, b rowchange.Change) int { return bytes.Compare(a.EntityID, b.EntityID) })
	if err := sqlbatch.Exec(tx, updateHead, `)`, []any{sourceID, sourceID}, keys); err != nil {
		return nil, err
	}
	return changes, nil
}
