// Package datevalues stores shared genealogical DateValue rows. The value
// type, its kinds and qualifiers, validation and display live in the pure
// package core/datevalue; this package holds the queries.
package datevalues

import (
	"database/sql"
	"strings"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sqlbatch"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue"
	"github.com/google/uuid"
)

const (
	sqlInsert = `INSERT INTO date_values (
		id, kind, qualifier, calendar,
		start_year, start_month, start_day,
		start_hour, start_minute, start_second, start_millisecond, start_tz,
		end_year, end_month, end_day,
		end_hour, end_minute, end_second, end_millisecond, end_tz,
		phrase
	) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`

	sqlUpdate = `UPDATE date_values SET
		kind = ?, qualifier = ?, calendar = ?,
		start_year = ?, start_month = ?, start_day = ?,
		start_hour = ?, start_minute = ?, start_second = ?, start_millisecond = ?, start_tz = ?,
		end_year = ?, end_month = ?, end_day = ?,
		end_hour = ?, end_minute = ?, end_second = ?, end_millisecond = ?, end_tz = ?,
		phrase = ?
		WHERE id = ?`

	sqlExists = `SELECT 1 FROM date_values WHERE id = ?`

	sqlLookup = `SELECT kind, qualifier, calendar,
		start_year, start_month, start_day,
		start_hour, start_minute, start_second, start_millisecond, start_tz,
		end_year, end_month, end_day,
		end_hour, end_minute, end_second, end_millisecond, end_tz,
		phrase
		FROM date_values WHERE id = ?`

	sqlLookupMany = `SELECT id, kind, qualifier, calendar,
		start_year, start_month, start_day,
		start_hour, start_minute, start_second, start_millisecond, start_tz,
		end_year, end_month, end_day,
		end_hour, end_minute, end_second, end_millisecond, end_tz,
		phrase
		FROM date_values WHERE id IN (`
)

// Insert mints a UUIDv7 id, validates, inserts, and returns the id.
func Insert(c *database.Catalog, v datevalue.Value) ([]byte, error) {
	db, err := c.DB()
	if err != nil {
		return nil, err
	}
	return InsertTx(db, v)
}

// InsertTx validates and inserts on an existing connection or transaction.
func InsertTx(q database.Execer, v datevalue.Value) ([]byte, error) {
	v = normalize(v)
	if err := datevalue.Validate(v); err != nil {
		return nil, err
	}
	return insert(q, v)
}

// insert stores a value already normalized and validated.
func insert(q database.Execer, v datevalue.Value) ([]byte, error) {
	id, err := uuid.NewV7()
	if err != nil {
		return nil, err
	}
	_, err = q.Exec(
		sqlInsert,
		id[:],
		v.Kind,
		database.NullTrimmed(v.Qualifier),
		database.NullTrimmed(v.Calendar),
		database.NullInt(v.StartYear),
		database.NullInt(v.StartMonth),
		database.NullInt(v.StartDay),
		database.NullInt(v.StartHour),
		database.NullInt(v.StartMinute),
		database.NullInt(v.StartSecond),
		database.NullInt(v.StartMillisecond),
		database.NullTrimmed(v.StartTZ),
		database.NullInt(v.EndYear),
		database.NullInt(v.EndMonth),
		database.NullInt(v.EndDay),
		database.NullInt(v.EndHour),
		database.NullInt(v.EndMinute),
		database.NullInt(v.EndSecond),
		database.NullInt(v.EndMillisecond),
		database.NullTrimmed(v.EndTZ),
		database.NullTrimmed(v.Phrase),
	)
	if err != nil {
		return nil, err
	}
	return id[:], nil
}

// UpdateTx rewrites the date_values row id. The id stays the same.
func UpdateTx(tx *sql.Tx, id []byte, v datevalue.Value) error {
	if tx == nil || len(id) != 16 {
		return datevalue.ErrInvalid
	}
	v = normalize(v)
	if err := datevalue.Validate(v); err != nil {
		return err
	}
	return update(tx, id, v)
}

// update rewrites row id with a value already normalized and validated.
func update(tx *sql.Tx, id []byte, v datevalue.Value) error {
	var one int
	if err := tx.QueryRow(sqlExists, id).Scan(&one); err != nil {
		if err == sql.ErrNoRows {
			return datevalue.ErrInvalid
		}
		return err
	}
	_, err := tx.Exec(
		sqlUpdate,
		v.Kind,
		database.NullTrimmed(v.Qualifier),
		database.NullTrimmed(v.Calendar),
		database.NullInt(v.StartYear),
		database.NullInt(v.StartMonth),
		database.NullInt(v.StartDay),
		database.NullInt(v.StartHour),
		database.NullInt(v.StartMinute),
		database.NullInt(v.StartSecond),
		database.NullInt(v.StartMillisecond),
		database.NullTrimmed(v.StartTZ),
		database.NullInt(v.EndYear),
		database.NullInt(v.EndMonth),
		database.NullInt(v.EndDay),
		database.NullInt(v.EndHour),
		database.NullInt(v.EndMinute),
		database.NullInt(v.EndSecond),
		database.NullInt(v.EndMillisecond),
		database.NullTrimmed(v.EndTZ),
		database.NullTrimmed(v.Phrase),
		id,
	)
	return err
}

// normalize trims the six string fields: the form every write stores, compares
// and audits.
func normalize(v datevalue.Value) datevalue.Value {
	v.Kind = strings.TrimSpace(v.Kind)
	v.Qualifier = strings.TrimSpace(v.Qualifier)
	v.Calendar = strings.TrimSpace(v.Calendar)
	v.Phrase = strings.TrimSpace(v.Phrase)
	v.StartTZ = strings.TrimSpace(v.StartTZ)
	v.EndTZ = strings.TrimSpace(v.EndTZ)
	return v
}

// PutTx stores v for an owner. With a 16-byte prevID (the date the owner holds)
// it rewrites that row in place, so the id stays, and returns prevID with an
// update change naming the fields that differ; when none differs it writes
// nothing and returns a nil change. With no prevID it inserts a new row and
// returns its id with the create change. v is normalized before it is compared
// and audited, so the audit row equals the stored row. An invalid v is
// datevalue.ErrInvalid and nothing is written.
func PutTx(tx *sql.Tx, prevID []byte, v datevalue.Value) (id []byte, ch *rowchange.Change, err error) {
	if tx == nil {
		return nil, nil, datevalue.ErrInvalid
	}
	v = normalize(v)
	if err := datevalue.Validate(v); err != nil {
		return nil, nil, err
	}
	if len(prevID) != 16 {
		id, err := insert(tx, v)
		if err != nil {
			return nil, nil, err
		}
		c := CreateChange(id, v)
		return id, &c, nil
	}
	prev, err := LookupTx(tx, prevID)
	if err != nil {
		return nil, nil, err
	}
	next := v
	next.ID = append([]byte(nil), prevID...)
	ch = UpdateChange(prev, next)
	if ch == nil {
		return append([]byte(nil), prevID...), nil, nil
	}
	if err := update(tx, prevID, v); err != nil {
		return nil, nil, err
	}
	return append([]byte(nil), prevID...), ch, nil
}

// RowMap is the audit row of a date_values row: every column, keyed by name.
func RowMap(id []byte, v datevalue.Value) map[string]any {
	return map[string]any{
		"id":                database.UUIDJSON(id),
		"kind":              database.NullString(v.Kind),
		"qualifier":         database.NullString(v.Qualifier),
		"calendar":          database.NullString(v.Calendar),
		"start_year":        database.NullInt(v.StartYear),
		"start_month":       database.NullInt(v.StartMonth),
		"start_day":         database.NullInt(v.StartDay),
		"start_hour":        database.NullInt(v.StartHour),
		"start_minute":      database.NullInt(v.StartMinute),
		"start_second":      database.NullInt(v.StartSecond),
		"start_millisecond": database.NullInt(v.StartMillisecond),
		"start_tz":          database.NullString(v.StartTZ),
		"end_year":          database.NullInt(v.EndYear),
		"end_month":         database.NullInt(v.EndMonth),
		"end_day":           database.NullInt(v.EndDay),
		"end_hour":          database.NullInt(v.EndHour),
		"end_minute":        database.NullInt(v.EndMinute),
		"end_second":        database.NullInt(v.EndSecond),
		"end_millisecond":   database.NullInt(v.EndMillisecond),
		"end_tz":            database.NullString(v.EndTZ),
		"phrase":            database.NullString(v.Phrase),
	}
}

// CreateChange is the audit change of a new date_values row.
func CreateChange(id []byte, v datevalue.Value) rowchange.Change {
	return rowchange.Change{
		EntityType: "date_value",
		EntityID:   append([]byte(nil), id...),
		Action:     rowchange.ActionCreate,
		Fields:     rowchange.FullRow(RowMap(id, v)),
	}
}

// UpdateChange is the audit change from prev to next, naming only the fields
// that differ; nil when none does.
func UpdateChange(prev, next datevalue.Value) *rowchange.Change {
	old, now := RowMap(prev.ID, prev), RowMap(next.ID, next)
	fields := rowchange.UpdatedRow(old, now, "id")
	if len(fields) == 0 {
		return nil
	}
	id := prev.ID
	if len(id) != 16 {
		id = next.ID
	}
	return &rowchange.Change{
		EntityType: "date_value",
		EntityID:   append([]byte(nil), id...),
		Action:     rowchange.ActionUpdate,
		Fields:     fields,
	}
}

// Lookup returns the date_values row for id, or sql.ErrNoRows.
func Lookup(c *database.Catalog, id []byte) (datevalue.Value, error) {
	db, err := c.DB()
	if err != nil {
		return datevalue.Value{}, err
	}
	return LookupTx(db, id)
}

// LookupManyTx returns date_values rows for the given ids, one query per
// sqlbatch.Size ids, keyed by string(id). Missing ids are omitted.
func LookupManyTx(q database.Querier, ids [][]byte) (map[string]datevalue.Value, error) {
	ids = database.UniqueBlobIDs(ids)
	out := make(map[string]datevalue.Value, len(ids))
	if len(ids) == 0 {
		return out, nil
	}
	err := sqlbatch.Query(q, sqlLookupMany, `)`, nil, ids, func(rows *sql.Rows) error {
		var id []byte
		v, err := scanValue(rows, &id)
		if err != nil {
			return err
		}
		v.ID = append([]byte(nil), id...)
		out[string(v.ID)] = v
		return nil
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}

// LookupTx returns the date_values row for id on an existing connection or transaction.
func LookupTx(q database.Querier, id []byte) (datevalue.Value, error) {
	if q == nil || len(id) != 16 {
		return datevalue.Value{}, datevalue.ErrInvalid
	}
	v, err := scanValue(q.QueryRow(sqlLookup, id))
	if err != nil {
		return datevalue.Value{}, err
	}
	v.ID = append([]byte(nil), id...)
	return v, nil
}

func intPtr(n sql.NullInt64) *int {
	if !n.Valid {
		return nil
	}
	v := int(n.Int64)
	return &v
}

// scanValue reads the sqlLookup column list, after any leading columns.
func scanValue(row database.Scanner, lead ...any) (datevalue.Value, error) {
	var (
		v                                                         datevalue.Value
		qual, cal, phrase, startTZ, endTZ                         sql.NullString
		startY, startM, startD, startH, startMin, startS, startMs sql.NullInt64
		endY, endM, endD, endH, endMin, endS, endMs               sql.NullInt64
	)
	dest := append(lead,
		&v.Kind,
		&qual,
		&cal,
		&startY, &startM, &startD,
		&startH, &startMin, &startS, &startMs, &startTZ,
		&endY, &endM, &endD,
		&endH, &endMin, &endS, &endMs, &endTZ,
		&phrase,
	)
	if err := row.Scan(dest...); err != nil {
		return datevalue.Value{}, err
	}
	v.Qualifier = qual.String
	v.Calendar = cal.String
	v.Phrase = phrase.String
	v.StartTZ = startTZ.String
	v.EndTZ = endTZ.String
	v.StartYear = intPtr(startY)
	v.StartMonth = intPtr(startM)
	v.StartDay = intPtr(startD)
	v.StartHour = intPtr(startH)
	v.StartMinute = intPtr(startMin)
	v.StartSecond = intPtr(startS)
	v.StartMillisecond = intPtr(startMs)
	v.EndYear = intPtr(endY)
	v.EndMonth = intPtr(endM)
	v.EndDay = intPtr(endD)
	v.EndHour = intPtr(endH)
	v.EndMinute = intPtr(endMin)
	v.EndSecond = intPtr(endS)
	v.EndMillisecond = intPtr(endMs)
	return v, nil
}

// RowMapTx is the release row-map of the date_values row id for
// deleteimpact.ReleaseReplaced: it looks the row up when called, then returns
// its audit row.
func RowMapTx(tx *sql.Tx, id []byte) func() (map[string]any, error) {
	return func() (map[string]any, error) {
		v, err := LookupTx(tx, id)
		return RowMap(id, v), err
	}
}
