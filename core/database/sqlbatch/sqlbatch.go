// Package sqlbatch reads a list of ids of any length in fixed-size IN lists.
// SQLite binds at most 32,766 values per statement, so every by-id read goes
// through here. It imports nothing from the catalog, so the graph cache, which
// the database package depends on, can use it too.
package sqlbatch

import (
	"database/sql"

	"github.com/Jake-Robins-Studios/provenencia/core/database/dbsql"
)

// Size bounds one IN list. A batch stays far under SQLite's bind limit, with
// room for a query's other arguments, so a read of any size is one query per
// batch.
const Size = 500

// Each calls fn with consecutive slices of ids (blob ids, or text keys: the
// element type is bound as it is), each at most Size long. It
// stops at fn's first error.
func Each[T any](ids []T, fn func(batch []T) error) error {
	for start := 0; start < len(ids); start += Size {
		if err := fn(ids[start:min(start+Size, len(ids))]); err != nil {
			return err
		}
	}
	return nil
}

// Query runs head + placeholders + tail once per batch of ids, binding args
// first and the batch after them, and calls scan for each row. head ends
// inside the IN list ("… IN (") and tail closes it (")", or ") ORDER BY …").
// Rows arrive batch by batch, so a caller that needs one order across
// batches sorts afterwards.
func Query[T any](q dbsql.Querier, head, tail string, args []any, ids []T, scan func(rows *sql.Rows) error) error {
	return Each(ids, func(batch []T) error {
		bound := make([]any, 0, len(args)+len(batch))
		bound = append(bound, args...)
		for _, id := range batch {
			bound = append(bound, id)
		}
		return Scan(q, head+dbsql.SQLInPlaceholders(len(batch))+tail, bound, scan)
	})
}

// Scan runs one query and calls scan for each row.
func Scan(q dbsql.Querier, query string, args []any, scan func(rows *sql.Rows) error) error {
	rows, err := q.Query(query, args...)
	if err != nil {
		return err
	}
	defer rows.Close()
	for rows.Next() {
		if err := scan(rows); err != nil {
			return err
		}
	}
	return rows.Err()
}
