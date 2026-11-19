// Package dbtest holds shared test helpers for the catalog database, so query
// tests do not each spell the same boilerplate.
package dbtest

import (
	"context"
	"database/sql"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database/dbsql"
)

// QueryPlan runs EXPLAIN QUERY PLAN on query with args and returns the detail
// line of each plan row. It fails the test on error.
func QueryPlan(t testing.TB, db *sql.DB, query string, args ...any) []string {
	t.Helper()
	rows, err := db.Query("EXPLAIN QUERY PLAN "+query, args...)
	if err != nil {
		t.Fatal(err)
	}
	defer rows.Close()
	var details []string
	for rows.Next() {
		var id, parent, notUsed int
		var detail string
		if err := rows.Scan(&id, &parent, &notUsed, &detail); err != nil {
			t.Fatal(err)
		}
		details = append(details, detail)
	}
	if err := rows.Err(); err != nil {
		t.Fatal(err)
	}
	return details
}

// Count runs a single-integer query (SELECT COUNT(*) …) on a *sql.DB or *sql.Tx.
func Count(t testing.TB, q dbsql.Querier, query string, args ...any) int {
	t.Helper()
	var n int
	if err := q.QueryRow(query, args...).Scan(&n); err != nil {
		t.Fatal(err)
	}
	return n
}

// MustDB opens c's *sql.DB, failing the test on error.
func MustDB(t testing.TB, c interface{ DB() (*sql.DB, error) }) *sql.DB {
	t.Helper()
	db, err := c.DB()
	if err != nil {
		t.Fatal(err)
	}
	return db
}

// Damage runs one statement the schema would refuse, as a crafted or damaged
// catalog holds it. It pins one connection, turns foreign keys off and check
// constraints off for the statement, restores both, and closes the connection
// before returning, because the catalog holds one connection.
func Damage(t testing.TB, db *sql.DB, query string, args ...any) {
	t.Helper()
	ctx := context.Background()
	conn, err := db.Conn(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer func() {
		if err := conn.Close(); err != nil {
			t.Fatal(err)
		}
	}()
	for _, pragma := range []string{`PRAGMA foreign_keys=OFF`, `PRAGMA ignore_check_constraints=ON`} {
		if _, err := conn.ExecContext(ctx, pragma); err != nil {
			t.Fatal(err)
		}
	}
	_, execErr := conn.ExecContext(ctx, query, args...)
	for _, pragma := range []string{`PRAGMA ignore_check_constraints=OFF`, `PRAGMA foreign_keys=ON`} {
		if _, err := conn.ExecContext(ctx, pragma); err != nil {
			t.Fatal(err)
		}
	}
	if execErr != nil {
		t.Fatal(execErr)
	}
}
