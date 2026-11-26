package effects

import (
	"bytes"
	"database/sql"
	"sort"
	"strings"

	"github.com/Jake-Robins-Studios/provenencia/core/database/dbsql"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
)

// SourceScopeOfChange resolves the Source scope of changes[i] alone, with every
// delete in changes as a ghost. It is visible to the external test package,
// which can run the real deletes; no production code reaches it.
func SourceScopeOfChange(q dbsql.Querier, changes []rowchange.Change, i int) ([][]byte, error) {
	table, ok := entityTable[changes[i].EntityType]
	if !ok {
		return nil, errf("effects: no entry for %s", changes[i].EntityType)
	}
	w := &walk{q: q, ch: changes[i], ghosts: ghostsFrom(changes), table: table}
	return appendPath(w, table, registry[table].SourceScope, nil)
}

// QueryLog counts the queries a walk issues, by query text and first argument.
// It is visible to the external test package.
type QueryLog struct {
	dbsql.Querier
	calls []loggedQuery
}

type loggedQuery struct {
	query string
	id    []byte
}

func (l *QueryLog) log(query string, args []any) {
	var id []byte
	if len(args) > 0 {
		id, _ = args[0].([]byte)
	}
	l.calls = append(l.calls, loggedQuery{query: query, id: id})
}

func (l *QueryLog) Query(query string, args ...any) (*sql.Rows, error) {
	l.log(query, args)
	return l.Querier.Query(query, args...)
}

func (l *QueryLog) QueryRow(query string, args ...any) *sql.Row {
	l.log(query, args)
	return l.Querier.QueryRow(query, args...)
}

// Count sums the calls whose query text contains substr and whose first
// argument is id.
func (l *QueryLog) Count(substr string, id []byte) int {
	n := 0
	for _, c := range l.calls {
		if strings.Contains(c.query, substr) && bytes.Equal(c.id, id) {
			n++
		}
	}
	return n
}

// Repeats lists the query texts called more than once with the same id.
func (l *QueryLog) Repeats() []string {
	type key struct{ query, id string }
	seen := map[key]int{}
	var out []string
	for _, c := range l.calls {
		k := key{c.query, string(c.id)}
		seen[k]++
		if seen[k] == 2 {
			out = append(out, c.query)
		}
	}
	sort.Strings(out)
	return out
}

// Total counts every call.
func (l *QueryLog) Total() int { return len(l.calls) }
