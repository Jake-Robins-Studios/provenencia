package audit

import (
	"database/sql"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sqlbatch"
)

// Creation is who made a row and when: the create audit transaction's time
// (RFC3339 UTC) and its user's display name, empty when the transaction has no
// user.
type Creation struct {
	At              string
	UserDisplayName string
}

// Binds: entity type, then ids, in sqlbatch batches. The lowest revision comes
// first for an id, so the first row read for it is its first create.
const sqlCreated = `SELECT c.entity_id, t.created_at, COALESCE(u.display_name, '')
	FROM audit_changes c
	JOIN audit_transactions t ON t.id = c.audit_transaction_id
	LEFT JOIN users u ON u.id = t.user_id
	WHERE c.action = 'create' AND c.entity_type = ? AND c.entity_id IN (`

const sqlCreatedTail = `) ORDER BY t.revision ASC`

// Created reads when and by whom each row of entityType was created, keyed by
// string(id). The lowest revision's create wins when an id has several; an id
// with no create is absent. It is the one rule for a row's creation, so a list
// read costs one indexed batch per 500 ids.
func Created(q database.Querier, entityType string, ids [][]byte) (map[string]Creation, error) {
	ids = database.UniqueBlobIDs(ids)
	out := make(map[string]Creation, len(ids))
	err := sqlbatch.Query(q, sqlCreated, sqlCreatedTail, []any{entityType}, ids, func(rows *sql.Rows) error {
		var id []byte
		var c Creation
		if err := rows.Scan(&id, &c.At, &c.UserDisplayName); err != nil {
			return err
		}
		if _, seen := out[string(id)]; !seen {
			out[string(id)] = c
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}
