// Package dbsql holds the database/sql surface the catalog packages share: the
// read and write connection interfaces, the row scanner, and the IN-list
// builders. It imports nothing from the catalog, so sqlbatch, graphcache and
// effects, which core/database imports, can use it. Everything else takes the
// core/database aliases of these types.
package dbsql

import (
	"database/sql"
	"strings"
)

// Querier is the read surface that *sql.DB and *sql.Tx share.
type Querier interface {
	Query(query string, args ...any) (*sql.Rows, error)
	QueryRow(query string, args ...any) *sql.Row
}

// Execer is Querier plus Exec: the surface a write takes.
type Execer interface {
	Querier
	Exec(query string, args ...any) (sql.Result, error)
}

// Scanner is *sql.Row or *sql.Rows.
type Scanner interface {
	Scan(dest ...any) error
}

var (
	_ Execer  = (*sql.DB)(nil)
	_ Execer  = (*sql.Tx)(nil)
	_ Scanner = (*sql.Row)(nil)
	_ Scanner = (*sql.Rows)(nil)
)

// SQLInPlaceholders is n SQLite bind markers joined by commas.
func SQLInPlaceholders(n int) string {
	if n <= 0 {
		return ""
	}
	return strings.Repeat("?,", n-1) + "?"
}

// BlobArgs copies 16-byte ids into a Query/Exec args slice.
func BlobArgs(ids [][]byte) []any {
	args := make([]any, len(ids))
	for i, id := range ids {
		args[i] = id
	}
	return args
}
