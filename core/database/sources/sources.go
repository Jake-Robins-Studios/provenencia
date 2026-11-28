// Package sources accesses the sources catalog table with audited mutations.
package sources

import (
	"bytes"
	"database/sql"
	"errors"
	"slices"
	"strings"

	"github.com/Jake-Robins-Studios/provenencia/core/database/catalogmodel"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"

	"github.com/Jake-Robins-Studios/provenencia/core/apperr"
	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/artifacts"
	"github.com/Jake-Robins-Studios/provenencia/core/database/audit"
	"github.com/Jake-Robins-Studios/provenencia/core/database/datevalues"
	"github.com/Jake-Robins-Studios/provenencia/core/database/deleteimpact"
	"github.com/Jake-Robins-Studios/provenencia/core/database/effects"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencegraphs"
	"github.com/Jake-Robins-Studios/provenencia/core/database/filederivatives"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sqlbatch"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue"
	"github.com/Jake-Robins-Studios/provenencia/core/ref"
	"github.com/Jake-Robins-Studios/provenencia/core/valuecompare"
	"github.com/Jake-Robins-Studios/provenencia/core/valuemark"
	"github.com/google/uuid"
)

var ErrInvalid = apperr.New(apperr.CodeSourcesInvalid, apperr.KindUser)

// ErrNotFound is returned when no Source has the id: a read or write of a deleted Source.
// A malformed id or user stays ErrInvalid.
var ErrNotFound = apperr.New(apperr.CodeSourcesNotFound, apperr.KindNotFound)

// ErrInUse is returned by Delete when Artifacts or Subjects still belong to the Source.
var ErrInUse = apperr.New(apperr.CodeSourcesInUse, apperr.KindConflict)

// Cover modes persisted on sources.cover_mode.
const (
	CoverModeTypeIcon = "type_icon"
	CoverModeArtifact = "artifact"
)

const (
	sqlInsert = `INSERT INTO sources (id, ref, source_type_id, title, description, is_public)
		VALUES (?, ?, ?, ?, ?, ?)`
	sqlUpdate = `UPDATE sources SET source_type_id = ?, title = ?, description = ?
		WHERE id = ?`
	sqlSetCover = `UPDATE sources SET cover_mode = ?, primary_artifact_id = ?
		WHERE id = ?`
	sqlSetDate = `UPDATE sources SET date_value_id = ?, date_unknown = ?, date_supplied = ?
		WHERE id = ?`
	sqlSetPublic = `UPDATE sources SET is_public = ? WHERE id = ?`
	// sqlColumns is the one column list scanSource reads. It is unqualified:
	// sqlList's outer query has one table.
	sqlColumns = `id, ref, source_type_id, title, COALESCE(description, ''),
		cover_mode, primary_artifact_id, date_value_id, is_public, date_unknown, date_supplied`
	sqlGet = `SELECT ` + sqlColumns + ` FROM sources WHERE id = ?`
	// Binds: ids, in sqlbatch batches.
	sqlGetIn    = `SELECT ` + sqlColumns + ` FROM sources WHERE id IN (`
	sqlGetByRef = `SELECT ` + sqlColumns + ` FROM sources WHERE ref = ?`
	// Newest-first by UUIDv7 id (create time). The Source's last activity is not
	// here: List reads it from the display cache (Graph.Activity), and the
	// create time is one batch seeking the partial index of creates
	// (audit_changes_created_idx, audit.Created), so no list load scans or
	// walks the audit history.
	// has_artifact gates the Evidence graph zone without a per-row query.
	sqlListHead = `SELECT ` + sqlColumns + `,
		EXISTS (SELECT 1 FROM artifacts a WHERE a.source_id = s.id)
		FROM sources s`
	sqlList = sqlListHead + `
		ORDER BY s.id DESC`
	// Binds: ids, in sqlbatch batches.
	sqlListIn     = sqlListHead + ` WHERE s.id IN (`
	sqlCount      = `SELECT COUNT(*) FROM sources`
	sqlDelete     = `DELETE FROM sources WHERE id = ?`
	sqlTypeExists = `SELECT 1 FROM source_types WHERE id = ?`
)

// Source is one sources row.
type Source struct {
	ID                []byte
	Ref               string
	SourceTypeID      []byte
	Title             string
	Description       string
	CoverMode         string
	PrimaryArtifactID []byte // nil when CoverModeTypeIcon
	// DateValueID and Date are the Source's own date (the original publication,
	// or when the record was made); nil when undated. Date carries its ID. Every
	// read fills them. DateMark is the date's unknown or supplied fact: unknown
	// has no date, supplied has one. Readers use DateMark; writes and audits use
	// storedDateMark, the columns as stored.
	DateValueID    []byte
	Date           *datevalue.Value
	DateMark       valuemark.Mark
	storedDateMark valuemark.Mark
	// IsPublic is false when the researcher marked the Source not public. It is
	// stored and read back; nothing else in the engine acts on it.
	IsPublic bool
	// Updated is the latest audit revision of any work scoped to this Source
	// (its row, children, and evidence graph) and when it was recorded.
	// Filled by List, ListByIDs and AttachCreatedAndUpdated; zero means unset.
	Updated effects.Activity
	// CreatedAt is when the Source was made (RFC3339 UTC), from its create audit
	// transaction. Filled by List, ListByIDs and AttachCreatedAndUpdated; empty means
	// unset or unknown.
	CreatedAt string
	// HasArtifact is true when at least one artifacts row exists for this Source.
	// Filled by List only; other reads leave it false and callers query separately.
	HasArtifact bool
}

// CreateInput is the mutable fields for a new Source.
type CreateInput struct {
	SourceTypeID []byte
	Title        string
	Description  string
	// Private creates the Source not public. The zero value is public, as the
	// column default is.
	Private bool
}

// Create inserts a Source and mints SRC-…. The caller records the returned changes.
func Create(tx *database.Tx, userID []byte, in CreateInput) (Source, []rowchange.Change, error) {
	in.Title = strings.TrimSpace(in.Title)
	in.Description = strings.TrimSpace(in.Description)
	if tx == nil || len(in.SourceTypeID) != 16 || in.Title == "" {
		return Source{}, nil, ErrInvalid
	}
	if err := database.RequireUserID(userID, ErrInvalid); err != nil {
		return Source{}, nil, err
	}
	if err := requireType(tx.Tx, in.SourceTypeID); err != nil {
		return Source{}, nil, err
	}

	id, err := uuid.NewV7()
	if err != nil {
		return Source{}, nil, err
	}
	idBytes := id[:]

	sourceRef, err := database.InsertWithRef(database.Minter(ref.PrefixSource), func(storedRef string) error {
		_, err := tx.Exec(sqlInsert, idBytes, storedRef, in.SourceTypeID, in.Title, database.NullString(in.Description), boolInt(!in.Private))
		return err
	})
	if errors.Is(err, database.ErrRefsExhausted) {
		return Source{}, nil, ErrInvalid
	}
	if err != nil {
		return Source{}, nil, mapConstraint(err)
	}

	fields := map[string]any{
		"id":             id.String(),
		"ref":            sourceRef,
		"source_type_id": database.UUIDString(in.SourceTypeID),
		"title":          in.Title,
	}
	if in.Description != "" {
		fields["description"] = in.Description
	}
	if in.Private {
		fields["is_public"] = 0
	}
	_, graphChanges, err := evidencegraphs.CreateDefault(tx, idBytes)
	if err != nil {
		return Source{}, nil, err
	}
	changes := append([]rowchange.Change{rowchange.Created("source", idBytes, fields)}, graphChanges...)
	return Source{
		ID:           append([]byte(nil), idBytes...),
		Ref:          sourceRef,
		SourceTypeID: append([]byte(nil), in.SourceTypeID...),
		Title:        in.Title,
		Description:  in.Description,
		CoverMode:    CoverModeTypeIcon,
		IsPublic:     !in.Private,
	}, changes, nil
}

// normalizeCoverMode is the one parse of a cover mode string.
func normalizeCoverMode(mode string) string { return strings.TrimSpace(mode) }

// CoverArtifactID reports whether a cover choice pins an Artifact: the mode is
// CoverModeArtifact and the id is a 16-byte id. It is the one test the
// handlers use to tell an Artifact cover from the type icon.
func CoverArtifactID(mode string, primaryArtifactID []byte) ([]byte, bool) {
	if normalizeCoverMode(mode) != CoverModeArtifact || len(primaryArtifactID) != 16 {
		return nil, false
	}
	return primaryArtifactID, true
}

// NormalizeCover checks a cover choice. Artifact mode needs the cover's
// thumbnail to exist already (SetSourceCover makes it before its session), so
// call this before SetCover's Run.
func NormalizeCover(c *database.Catalog, sourceID []byte, mode string, primaryArtifactID []byte) (string, []byte, error) {
	if c == nil || len(sourceID) != 16 {
		return "", nil, ErrInvalid
	}
	mode = normalizeCoverMode(mode)
	switch mode {
	case CoverModeTypeIcon:
		return mode, nil, nil
	case CoverModeArtifact:
		if len(primaryArtifactID) != 16 {
			return "", nil, ErrInvalid
		}
		if err := requireRasterCoverArtifact(c, sourceID, primaryArtifactID); err != nil {
			return "", nil, err
		}
		return mode, append([]byte(nil), primaryArtifactID...), nil
	default:
		return "", nil, ErrInvalid
	}
}

// loadForWrite reads the Source a write targets: ErrInvalid for a missing
// transaction, a malformed id or a bad user, ErrNotFound for a Source that does
// not exist.
func loadForWrite(tx *database.Tx, userID, id []byte) (Source, error) {
	if tx == nil || len(id) != 16 {
		return Source{}, ErrInvalid
	}
	if err := database.RequireUserID(userID, ErrInvalid); err != nil {
		return Source{}, err
	}
	return Lookup(tx.Tx, id)
}

// SetCover pins an Artifact as cover or reverts to the Source type icon.
// Call NormalizeCover first when mode is CoverModeArtifact. An unchanged cover
// returns the existing Source and no changes.
func SetCover(tx *database.Tx, userID, sourceID []byte, mode string, primaryArtifactID []byte) (Source, []rowchange.Change, error) {
	mode = normalizeCoverMode(mode)
	switch mode {
	case CoverModeTypeIcon:
		primaryArtifactID = nil
	case CoverModeArtifact:
		if len(primaryArtifactID) != 16 {
			return Source{}, nil, ErrInvalid
		}
	default:
		return Source{}, nil, ErrInvalid
	}

	prev, err := loadForWrite(tx, userID, sourceID)
	if err != nil {
		return Source{}, nil, err
	}
	if prev.CoverMode == mode && bytes.Equal(prev.PrimaryArtifactID, primaryArtifactID) {
		return prev, nil, nil
	}
	if _, err := tx.Exec(sqlSetCover, mode, database.NullBlob(primaryArtifactID), sourceID); err != nil {
		return Source{}, nil, mapConstraint(err)
	}
	fields := map[string]rowchange.FieldDiff{
		"cover_mode": {Old: prev.CoverMode, New: mode},
	}
	if !bytes.Equal(prev.PrimaryArtifactID, primaryArtifactID) {
		fields["primary_artifact_id"] = rowchange.FieldDiff{
			Old: database.UUIDJSON(prev.PrimaryArtifactID),
			New: database.UUIDJSON(primaryArtifactID),
		}
	}
	prev.CoverMode = mode
	if len(primaryArtifactID) == 16 {
		prev.PrimaryArtifactID = append([]byte(nil), primaryArtifactID...)
	} else {
		prev.PrimaryArtifactID = nil
	}
	return prev, []rowchange.Change{{
		EntityType: "source",
		EntityID:   append([]byte(nil), sourceID...),
		Action:     rowchange.ActionUpdate,
		Fields:     fields,
	}}, nil
}

// SetDate gives the Source a date, edits the one it has in place (its id stays),
// or clears it when date is nil, releasing the date_values row. mark is the
// date's unknown or supplied fact: unknown goes with no date, supplied with a
// date, and no mark is a date typed as the record gives it. A write without a
// mark clears the stored one. The same date and mark return the Source and no
// changes. An invalid date is datevalue.ErrInvalid and a bad mark is
// valuemark.ErrInvalid; nothing is written.
func SetDate(tx *database.Tx, userID, sourceID []byte, date *datevalue.Value, mark valuemark.Mark) (Source, []rowchange.Change, error) {
	prev, err := loadForWrite(tx, userID, sourceID)
	if err != nil {
		return Source{}, nil, err
	}
	if err := valuemark.Validate(mark, date != nil); err != nil {
		return Source{}, nil, err
	}
	// held is the date row the Source owns; a stored id with no row is none.
	var held []byte
	if prev.Date != nil {
		held = prev.DateValueID
	}
	var changes []rowchange.Change
	var nextID []byte
	if date != nil {
		id, ch, err := datevalues.PutTx(tx.Tx, held, *date)
		if err != nil {
			return Source{}, nil, err
		}
		if ch != nil {
			changes = append(changes, *ch)
		}
		nextID = id
	}
	if !bytes.Equal(nextID, prev.DateValueID) || mark != prev.storedDateMark {
		if _, err := tx.Exec(sqlSetDate, database.NullBlob(nextID), boolInt(mark.Unknown), boolInt(mark.Supplied), sourceID); err != nil {
			return Source{}, nil, mapConstraint(err)
		}
		if ch := dateChange(sourceID, prev.DateValueID, nextID, prev.storedDateMark, mark); ch != nil {
			changes = append(changes, *ch)
		}
	}
	if date == nil && len(held) == 16 {
		ch, err := deleteimpact.ReleaseReplaced(tx, "sources.date_value_id", "date_value", held, nil,
			datevalues.RowMapTx(tx.Tx, held))
		if err != nil {
			return Source{}, nil, err
		}
		if ch != nil {
			changes = append(changes, *ch)
		}
	}
	if len(changes) == 0 {
		return prev, nil, nil
	}
	next, err := Lookup(tx.Tx, sourceID)
	if err != nil {
		return Source{}, nil, err
	}
	return next, changes, nil
}

// dateChange is the source update change for the date columns: date_value_id
// from one date row to another (nil for none), and each of date_unknown and
// date_supplied that differs, as a bool. It is nil when nothing differs.
func dateChange(sourceID, prevID, nextID []byte, prevMark, nextMark valuemark.Mark) *rowchange.Change {
	return rowchange.Updated("source", sourceID,
		map[string]any{"date_value_id": database.UUIDJSON(prevID), "date_unknown": prevMark.Unknown, "date_supplied": prevMark.Supplied},
		map[string]any{"date_value_id": database.UUIDJSON(nextID), "date_unknown": nextMark.Unknown, "date_supplied": nextMark.Supplied})
}

// SetPublic marks the Source public or not public. An unchanged flag returns
// the Source and no changes.
func SetPublic(tx *database.Tx, userID, sourceID []byte, isPublic bool) (Source, []rowchange.Change, error) {
	prev, err := loadForWrite(tx, userID, sourceID)
	if err != nil {
		return Source{}, nil, err
	}
	if prev.IsPublic == isPublic {
		return prev, nil, nil
	}
	if _, err := tx.Exec(sqlSetPublic, boolInt(isPublic), sourceID); err != nil {
		return Source{}, nil, mapConstraint(err)
	}
	prev.IsPublic = isPublic
	change := rowchange.Updated("source", sourceID, map[string]any{"is_public": boolInt(!isPublic)}, map[string]any{"is_public": boolInt(isPublic)})
	return prev, []rowchange.Change{*change}, nil
}

func boolInt(b bool) int {
	if b {
		return 1
	}
	return 0
}

// DateSortKey is the Source's place in date order as one integer, ascending
// (valuecompare.DateKey.Int64). ok is false when the Source is undated or its
// date has no place (a phrase with no year).
func DateSortKey(s Source) (key int64, ok bool) {
	if s.Date == nil {
		return 0, false
	}
	k, _, _, ok := valuecompare.DateKeyOf(*s.Date)
	if !ok {
		return 0, false
	}
	return k.Int64(), true
}

// Update patches title, description, and source_type_id. An unchanged row
// returns no changes.
func Update(tx *database.Tx, userID []byte, s Source) ([]rowchange.Change, error) {
	if tx == nil {
		return nil, ErrInvalid
	}
	s.Title = strings.TrimSpace(s.Title)
	s.Description = strings.TrimSpace(s.Description)
	if len(s.ID) != 16 || len(s.SourceTypeID) != 16 || s.Title == "" {
		return nil, ErrInvalid
	}
	prev, err := loadForWrite(tx, userID, s.ID)
	if err != nil {
		return nil, err
	}
	if err := requireType(tx.Tx, s.SourceTypeID); err != nil {
		return nil, err
	}

	change := rowchange.Updated("source", s.ID,
		map[string]any{"source_type_id": database.UUIDString(prev.SourceTypeID), "title": prev.Title, "description": database.NullString(prev.Description)},
		map[string]any{"source_type_id": database.UUIDString(s.SourceTypeID), "title": s.Title, "description": database.NullString(s.Description)})
	if change == nil {
		return nil, nil
	}
	if _, err := tx.Exec(sqlUpdate, s.SourceTypeID, s.Title, database.NullString(s.Description), s.ID); err != nil {
		return nil, mapConstraint(err)
	}
	return []rowchange.Change{*change}, nil
}

// Delete erases a Source when inbound resources are empty. Notes, metadata,
// credibility, and layout CASCADE. Artifacts or Subjects block with ErrInUse.
// The returned changes include the released facet rows.
func Delete(tx *database.Tx, userID, id []byte) ([]rowchange.Change, error) {
	existing, err := loadForWrite(tx, userID, id)
	if err != nil {
		return nil, err
	}

	report, err := deleteimpact.Impact(tx.Tx, catalogmodel.KindSource, id)
	if err != nil {
		return nil, err
	}
	if err := deleteimpact.Refuse(report, deleteimpact.Codes{
		InUse: ErrInUse, NotFound: ErrNotFound,
	}); err != nil {
		return nil, err
	}
	released, err := deleteimpact.ReleaseFacets(tx, catalogmodel.KindSource, id)
	if err != nil {
		return nil, err
	}
	owned, err := deleteimpact.SnapshotOwned(tx.Tx, catalogmodel.KindSource, id)
	if err != nil {
		return nil, err
	}
	if _, err := tx.Exec(sqlDelete, id); err != nil {
		return nil, err
	}
	if err := deleteimpact.ReleaseSnapshot(tx, owned); err != nil {
		return nil, err
	}

	fields := map[string]any{
		"id":             database.UUIDString(id),
		"ref":            existing.Ref,
		"source_type_id": database.UUIDString(existing.SourceTypeID),
		"title":          existing.Title,
		"is_public":      boolInt(existing.IsPublic),
	}
	if existing.Description != "" {
		fields["description"] = existing.Description
	}
	if len(existing.DateValueID) == 16 {
		fields["date_value_id"] = database.UUIDJSON(existing.DateValueID)
	}
	if existing.storedDateMark.Unknown {
		fields["date_unknown"] = true
	}
	if existing.storedDateMark.Supplied {
		fields["date_supplied"] = true
	}
	return append(released, rowchange.Deleted("source", id, fields)), nil
}

// Get returns a Source by id, or ErrNotFound.
func Get(c *database.Catalog, id []byte) (Source, error) {
	db, err := c.DB()
	if err != nil {
		return Source{}, err
	}
	return Lookup(db, id)
}

// Lookup returns a Source by id on any Querier: ErrInvalid for a malformed
// id, ErrNotFound when there is none.
func Lookup(q database.Querier, id []byte) (Source, error) {
	if len(id) != 16 {
		return Source{}, ErrInvalid
	}
	return getOne(q, sqlGet, id)
}

// getByRef returns a Source by SRC-… ref, or ErrNotFound.
func getByRef(c *database.Catalog, sourceRef string) (Source, error) {
	db, err := c.DB()
	if err != nil {
		return Source{}, err
	}
	sourceRef = strings.TrimSpace(sourceRef)
	if ref.Validate(sourceRef) != nil {
		return Source{}, ErrInvalid
	}
	return getOne(db, sqlGetByRef, sourceRef)
}

// List returns Sources newest-first by UUIDv7 id, with HasArtifact filled from
// a single list query and Updated read from the display cache.
func List(c *database.Catalog) ([]Source, error) {
	db, err := c.DB()
	if err != nil {
		return nil, err
	}
	rows, err := db.Query(sqlList)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []Source
	for rows.Next() {
		s, err := scanListed(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, s)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	// The scan is finished: the catalog has one connection, so the cache's
	// first load cannot run while rows is open.
	if err := fillListed(c, db, out); err != nil {
		return nil, err
	}
	return out, nil
}

// ListByIDs is List for the given Sources only, newest-first, with the same
// fields filled. An id that is not a Source adds no row.
func ListByIDs(c *database.Catalog, ids [][]byte) ([]Source, error) {
	db, err := c.DB()
	if err != nil {
		return nil, err
	}
	var out []Source
	err = sqlbatch.Query(db, sqlListIn, ")", nil, database.UniqueBlobIDs(ids), func(rows *sql.Rows) error {
		s, err := scanListed(rows)
		if err != nil {
			return err
		}
		out = append(out, s)
		return nil
	})
	if err != nil {
		return nil, err
	}
	// Batches arrive one after another; List's order is by id, newest first.
	slices.SortFunc(out, func(a, b Source) int { return bytes.Compare(b.ID, a.ID) })
	if err := fillListed(c, db, out); err != nil {
		return nil, err
	}
	return out, nil
}

// scanListed reads one row of the sqlListHead query.
func scanListed(rows database.Scanner) (Source, error) {
	var hasArtifact bool
	s, err := scanSource(rows, &hasArtifact)
	if err != nil {
		return Source{}, err
	}
	s.HasArtifact = hasArtifact
	return s, nil
}

// fillListed fills each listed Source's date, create time and last activity.
func fillListed(c *database.Catalog, q database.Querier, out []Source) error {
	if err := fillDates(q, out); err != nil {
		return err
	}
	return fillCreatedAndUpdated(c, q, out)
}

// fillCreatedAndUpdated sets CreatedAt on each Source from one batched audit read, and
// Updated from the display cache's last activity.
func fillCreatedAndUpdated(c *database.Catalog, q database.Querier, out []Source) error {
	ids := make([][]byte, 0, len(out))
	for _, s := range out {
		ids = append(ids, s.ID)
	}
	made, err := audit.Created(q, "source", ids)
	if err != nil {
		return err
	}
	for i := range out {
		out[i].CreatedAt = made[string(out[i].ID)].At
		if out[i].Updated, err = c.Graph().Activity(effects.ScopeSource, out[i].ID); err != nil {
			return err
		}
	}
	return nil
}

// AttachCreatedAndUpdated sets CreatedAt and Updated on a Source not read by a list.
func AttachCreatedAndUpdated(c *database.Catalog, s *Source) error {
	if s == nil || len(s.ID) != 16 {
		return ErrInvalid
	}
	db, err := c.DB()
	if err != nil {
		return err
	}
	one := []Source{*s}
	if err := fillCreatedAndUpdated(c, db, one); err != nil {
		return err
	}
	*s = one[0]
	return nil
}

// Count returns how many Sources are in the catalog — used by the workspace
// sidebar badge, not the Sources list itself.
func Count(c *database.Catalog) (int, error) {
	db, err := c.DB()
	if err != nil {
		return 0, err
	}
	var n int
	if err := db.QueryRow(sqlCount).Scan(&n); err != nil {
		return 0, err
	}
	return n, nil
}

// scanSource reads the sqlColumns, then extra. Date and DateMark are left for
// fillDates.
func scanSource(row database.Scanner, extra ...any) (Source, error) {
	var s Source
	var isPublic, unknown, supplied int64
	dest := append([]any{
		&s.ID, &s.Ref, &s.SourceTypeID, &s.Title, &s.Description, &s.CoverMode,
		&s.PrimaryArtifactID, &s.DateValueID, &isPublic, &unknown, &supplied,
	}, extra...)
	if err := row.Scan(dest...); err != nil {
		return Source{}, err
	}
	s.IsPublic = isPublic != 0
	s.storedDateMark = valuemark.Mark{Unknown: unknown != 0, Supplied: supplied != 0}
	if s.CoverMode == "" {
		s.CoverMode = CoverModeTypeIcon
	}
	return s, nil
}

// settleDate is the one place a read decides a Source's date and mark. The date
// is the row for id in dates, nil when id is not 16 bytes or its row is gone, so
// a date that is gone reads as undated. The read mark is the stored one settled
// for what the read found (valuemark.Settle).
func settleDate(dates map[string]datevalue.Value, id []byte, stored valuemark.Mark) (*datevalue.Value, valuemark.Mark) {
	if len(id) == 16 {
		if d, ok := dates[string(id)]; ok {
			return &d, valuemark.Settle(stored, true)
		}
	}
	return nil, valuemark.Settle(stored, false)
}

// lookupDates reads the date rows of the 16-byte ids among ids in one batched
// query (none for an empty set), keyed by id.
func lookupDates(q database.Querier, ids [][]byte) (map[string]datevalue.Value, error) {
	var held [][]byte
	for _, id := range ids {
		if len(id) == 16 {
			held = append(held, id)
		}
	}
	return datevalues.LookupManyTx(q, held)
}

// fillDates sets Date and DateMark on each Source from one batched read of its
// date rows.
func fillDates(q database.Querier, out []Source) error {
	ids := make([][]byte, 0, len(out))
	for _, s := range out {
		ids = append(ids, s.DateValueID)
	}
	dates, err := lookupDates(q, ids)
	if err != nil {
		return err
	}
	for i := range out {
		out[i].Date, out[i].DateMark = settleDate(dates, out[i].DateValueID, out[i].storedDateMark)
	}
	return nil
}

// CitationDate is what the Source's date gives a citation: its date and its
// unknown or supplied mark, as the built-in {source.date} reads them. Every
// resolver of a citation's values (the boards' and the renderer's) builds the
// Source date from this one function.
func CitationDate(s Source) citationformat.Value {
	return citationformat.Value{Date: s.Date, Mark: s.DateMark}
}

// GetManyTx returns the Sources with the given ids with their settled dates,
// keyed by string(id). A repeated id counts once and an id with no Source is
// absent; no ids returns an empty map and runs no query.
func GetManyTx(tx *sql.Tx, ids [][]byte) (map[string]Source, error) {
	ids = database.UniqueBlobIDs(ids)
	out := make(map[string]Source, len(ids))
	if len(ids) == 0 {
		return out, nil
	}
	var found []Source
	err := sqlbatch.Query(tx, sqlGetIn, ")", nil, ids, func(rows *sql.Rows) error {
		s, err := scanSource(rows)
		if err != nil {
			return err
		}
		found = append(found, s)
		return nil
	})
	if err != nil {
		return nil, err
	}
	if err := fillDates(tx, found); err != nil {
		return nil, err
	}
	for _, s := range found {
		out[string(s.ID)] = s
	}
	return out, nil
}

// getOne reads one Source by the query's key and fills its date. A missing
// Source is ErrNotFound, mapped here once for every reader.
func getOne(q database.Querier, query string, key any) (Source, error) {
	s, err := scanSource(q.QueryRow(query, key))
	if errors.Is(err, sql.ErrNoRows) {
		return Source{}, ErrNotFound
	}
	if err != nil {
		return Source{}, err
	}
	one := []Source{s}
	if err := fillDates(q, one); err != nil {
		return Source{}, err
	}
	return one[0], nil
}

func requireType(tx *sql.Tx, typeID []byte) error {
	var one int
	err := tx.QueryRow(sqlTypeExists, typeID).Scan(&one)
	if errors.Is(err, sql.ErrNoRows) {
		return ErrInvalid
	}
	return err
}

// CoverArtifactFile returns the File id of the Artifact a cover would pin: the
// Artifact must exist, belong to the Source and hold a File, else ErrInvalid.
// It decodes nothing; it is the one place the cover rule lives, for
// SetSourceCover's stage and NormalizeCover alike.
func CoverArtifactFile(c *database.Catalog, sourceID, artifactID []byte) ([]byte, error) {
	art, err := artifacts.Get(c, artifactID)
	if errors.Is(err, sql.ErrNoRows) || errors.Is(err, artifacts.ErrInvalid) {
		return nil, ErrInvalid
	}
	if err != nil {
		return nil, err
	}
	if !bytes.Equal(art.SourceID, sourceID) || len(art.FileID) != 16 {
		return nil, ErrInvalid
	}
	return art.FileID, nil
}

// requireRasterCoverArtifact accepts a cover Artifact whose File already has a
// thumbnail. It never decodes: the thumbnail is made before, outside the
// session, so an Artifact with no thumbnail (a PDF, an image that failed to
// decode, one deleted meanwhile) is ErrInvalid.
func requireRasterCoverArtifact(c *database.Catalog, sourceID, artifactID []byte) error {
	fileID, err := CoverArtifactFile(c, sourceID, artifactID)
	if err != nil {
		return err
	}
	link, err := filederivatives.Lookup(c, fileID, filederivatives.TypeThumbnail)
	if errors.Is(err, sql.ErrNoRows) {
		return ErrInvalid
	}
	if err != nil {
		return err
	}
	if len(link.DerivedFileID) != 16 {
		return ErrInvalid
	}
	return nil
}

func mapConstraint(err error) error {
	if database.IsConstraintViolation(err) {
		return ErrInvalid
	}
	return err
}
