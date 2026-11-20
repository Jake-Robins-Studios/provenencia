package database

import (
	"bytes"
	"slices"
	"strings"

	"github.com/Jake-Robins-Studios/provenencia/core/database/dbsql"
)

// UniqueBlobIDs returns distinct 16-byte identifiers in first-seen order.
func UniqueBlobIDs(ids [][]byte) [][]byte {
	seen := make(map[string]struct{}, len(ids))
	out := make([][]byte, 0, len(ids))
	for _, id := range ids {
		if len(id) != 16 {
			continue
		}
		k := string(id)
		if _, ok := seen[k]; ok {
			continue
		}
		seen[k] = struct{}{}
		out = append(out, append([]byte(nil), id...))
	}
	return out
}

// Columns is a SELECT list over cols, each column prefixed "alias." when alias
// is not empty. A col is a bare column name, or "name|expr" where expr holds %s
// where the prefixed name goes: "description|COALESCE(%s, ”)".
func Columns(alias string, cols ...string) string {
	p := ""
	if alias != "" {
		p = alias + "."
	}
	out := make([]string, len(cols))
	for i, c := range cols {
		if name, expr, ok := strings.Cut(c, "|"); ok {
			out[i] = strings.Replace(expr, "%s", p+name, 1)
		} else {
			out[i] = p + c
		}
	}
	return strings.Join(out, ", ")
}

// SQLInPlaceholders is n SQLite bind markers joined by commas.
func SQLInPlaceholders(n int) string {
	return dbsql.SQLInPlaceholders(n)
}

// BlobArgs copies 16-byte ids into a Query/Exec args slice.
func BlobArgs(ids [][]byte) []any {
	return dbsql.BlobArgs(ids)
}

// ContainsBlobID reports whether ids holds id.
func ContainsBlobID(ids [][]byte, id []byte) bool {
	return slices.ContainsFunc(ids, func(x []byte) bool { return bytes.Equal(x, id) })
}

// QueryIDs runs a query that selects one id column and returns each row's
// value in order.
var QueryIDs = dbsql.QueryIDs
