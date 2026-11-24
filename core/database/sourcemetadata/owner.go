package sourcemetadata

import (
	"database/sql"
	"errors"
	"fmt"
	"strings"

	"github.com/Jake-Robins-Studios/provenencia/core/database/catalogmodel"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

// Owner is the record metadata hangs off: a Source, an Artifact, an Evidence
// graph or a Citation. Level names which store holds its values, and ID is the
// owner row's id.
type Owner struct {
	Level vocabkey.Level
	ID    []byte
}

// key names the owner in a map: the level strings differ and ids are 16 bytes,
// so two owners never share a key.
func (o Owner) key() string { return string(o.Level) + string(o.ID) }

// OwnerRows is stored rows grouped by their owner.
type OwnerRows map[string][]Row

// GroupByOwner groups rows by owner, in the order given.
func GroupByOwner(rows []Row) OwnerRows {
	g := make(OwnerRows)
	for _, r := range rows {
		g[r.Owner.key()] = append(g[r.Owner.key()], r)
	}
	return g
}

// Of keys one owner's rows by field id; an owner with no rows gives an empty map.
func (g OwnerRows) Of(o Owner) map[string]Row { return rowsByField(g[o.key()]) }

// store is one level's tables and the SQL over them, built once by newStore
// from constant names. Every function that reads or writes metadata starts at
// storeFor, so a level with no entry is refused before any query.
type store struct {
	level vocabkey.Level

	// Names that also appear in change rows.
	ownerColumn string
	values      string
	layout      string

	// typeIn and typeSuffix bracket the IN list of sqlbatch.Query. They read
	// the owners' ids, their Source type ids and their Source ids.
	typeIn     string
	typeSuffix string

	ownerExists string
	insert      string
	update      string
	delete      string
	getPair     string

	// listIn and layoutListIn are heads for sqlbatch.Query, closed by the
	// suffix their order needs (listSuffix and layoutListSuffix).
	listIn       string
	listSuffix   string
	layoutListIn string
	// layoutListSuffix orders layout rows within an owner.
	layoutListSuffix string

	layoutAppend  string
	layoutDismiss string
	layoutOrder   string
	layoutInsert  string
	layoutUpdate  string
	layoutGet     string
}

// sourcePathIn is the type read of a level, up to its IN list: the owner's id,
// its Source's type id and its Source's id. path is catalogmodel.SourcePath.
// The owner is t0 and each step up is the next alias; the last is the Source.
func sourcePathIn(path []catalogmodel.MetadataLevelTables) string {
	n := len(path) - 1
	var b strings.Builder
	fmt.Fprintf(&b, "SELECT t0.id, t%[1]d.source_type_id, t%[1]d.id FROM %[2]s t0", n, path[0].OwnerTable)
	for k := 1; k <= n; k++ {
		fmt.Fprintf(&b, " JOIN %s t%d ON t%d.id = t%d.%s", path[k].OwnerTable, k, k, k-1, path[k-1].SourceUp().Column)
	}
	b.WriteString(" WHERE t0.id IN (")
	return b.String()
}

// newStore builds a level's SQL from its constant names, as deleteimpact's
// rowFacet does. path is the level's catalogmodel.SourcePath; its first entry
// is the level itself. No argument comes from a caller.
func newStore(path []catalogmodel.MetadataLevelTables) *store {
	f := func(format string, a ...any) string { return fmt.Sprintf(format, a...) }
	level, ownerTable, ownerColumn, values, layout := path[0].Level, path[0].OwnerTable, path[0].OwnerColumn, path[0].Values, path[0].Layout
	return &store{
		level:       level,
		ownerColumn: ownerColumn,
		values:      values,
		layout:      layout,
		typeIn:      sourcePathIn(path),
		typeSuffix:  `)`,
		ownerExists: f(`SELECT 1 FROM %s WHERE id = ?`, ownerTable),
		insert: f(`INSERT INTO %s (id, %s, field_id, value_text, is_unknown, is_supplied)
			VALUES (?, ?, ?, ?, ?, ?)`, values, ownerColumn),
		update:  f(`UPDATE %s SET value_text = ?, is_unknown = ?, is_supplied = ? WHERE id = ?`, values),
		delete:  f(`DELETE FROM %s WHERE %s = ? AND field_id = ?`, values, ownerColumn),
		getPair: f(`SELECT id, %[2]s, field_id, COALESCE(value_text, ''), is_unknown, is_supplied FROM %[1]s WHERE %[2]s = ? AND field_id = ?`, values, ownerColumn),
		listIn: f(`SELECT id, %[2]s, field_id, COALESCE(value_text, ''), is_unknown, is_supplied
			FROM %[1]s WHERE %[2]s IN (`, values, ownerColumn),
		listSuffix: f(`) ORDER BY %s, field_id`, ownerColumn),
		layoutListIn: f(`SELECT %[2]s, field_id, sort_order, dismissed
			FROM %[1]s WHERE %[2]s IN (`, layout, ownerColumn),
		layoutListSuffix: f(`) ORDER BY %s, sort_order, field_id`, ownerColumn),

		// Layout rows append at the end of the owner's existing order. The next
		// sort_order is computed inside the INSERT so two appends cannot read the
		// same MAX and share a slot; the WHERE clause is also what lets SQLite
		// parse INSERT…SELECT with an upsert clause.
		layoutAppend: f(`INSERT INTO %[1]s (%[2]s, field_id, sort_order, dismissed)
			SELECT ?, ?, COALESCE(MAX(sort_order), -1) + 1, 0
			FROM %[1]s WHERE %[2]s = ?
			ON CONFLICT(%[2]s, field_id) DO NOTHING`, layout, ownerColumn),
		layoutDismiss: f(`INSERT INTO %[1]s (%[2]s, field_id, sort_order, dismissed)
			SELECT ?, ?, COALESCE(MAX(sort_order), -1) + 1, 1
			FROM %[1]s WHERE %[2]s = ?
			ON CONFLICT(%[2]s, field_id) DO UPDATE SET dismissed = 1`, layout, ownerColumn),
		// Reorder must not disturb dismissed, so the upsert touches sort_order only.
		layoutOrder: f(`INSERT INTO %[1]s (%[2]s, field_id, sort_order)
			VALUES (?, ?, ?)
			ON CONFLICT(%[2]s, field_id) DO UPDATE SET sort_order = excluded.sort_order`, layout, ownerColumn),
		layoutInsert: f(`INSERT INTO %[1]s (%[2]s, field_id, sort_order, dismissed)
			VALUES (?, ?, ?, ?)`, layout, ownerColumn),
		layoutUpdate: f(`UPDATE %[1]s SET sort_order = ?, dismissed = ? WHERE %[2]s = ? AND field_id = ?`, layout, ownerColumn),
		layoutGet:    f(`SELECT field_id, sort_order, dismissed FROM %[1]s WHERE %[2]s = ? AND field_id = ?`, layout, ownerColumn),
	}
}

// buildStores makes one store per list entry. A bad list panics at init.
func buildStores(list []catalogmodel.MetadataLevelTables) map[vocabkey.Level]*store {
	m := make(map[vocabkey.Level]*store, len(list))
	for _, e := range list {
		path, err := catalogmodel.SourcePath(list, e.Level)
		if err != nil {
			panic(err)
		}
		m[e.Level] = newStore(path)
	}
	return m
}

// stores holds one entry per level that keeps metadata, built from
// catalogmodel.MetadataTables. A level with no entry is ErrInvalid everywhere.
var stores = buildStores(catalogmodel.MetadataTables)

// storeFor is the first check of every exported function: the owner's level
// has a store and its id is 16 bytes.
func storeFor(o Owner) (*store, error) {
	st, ok := stores[o.Level]
	if !ok || len(o.ID) != 16 {
		return nil, ErrInvalid
	}
	return st, nil
}

// requireOwner is ErrInvalid when the owner row does not exist.
func requireOwner(tx *sql.Tx, st *store, o Owner) error {
	var one int
	err := tx.QueryRow(st.ownerExists, o.ID).Scan(&one)
	if errors.Is(err, sql.ErrNoRows) {
		return ErrInvalid
	}
	return err
}
