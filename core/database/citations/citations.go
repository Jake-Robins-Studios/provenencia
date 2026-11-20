// Package citations stores Interpretation Citation rows and orchestrates
// first-submit create with Observations.
package citations

import (
	"database/sql"
	"errors"
	"strings"

	"github.com/Jake-Robins-Studios/provenencia/core/database/catalogmodel"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sqlbatch"

	"github.com/Jake-Robins-Studios/provenencia/core/apperr"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/deleteimpact"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencegraphs"
	"github.com/Jake-Robins-Studios/provenencia/core/database/observations"
	"github.com/Jake-Robins-Studios/provenencia/core/locator"
	"github.com/Jake-Robins-Studios/provenencia/core/ref"
	"github.com/google/uuid"
)

var (
	ErrInvalid = apperr.New(apperr.CodeCitationsInvalid, apperr.KindUser)
	// ErrNotFound is a Citation that is not in the catalog, where the caller
	// named it by id and ErrInvalid would say the id itself is wrong.
	ErrNotFound = apperr.New(apperr.CodeCitationsNotFound, apperr.KindNotFound)
	ErrInUse    = apperr.New(apperr.CodeCitationsInUse, apperr.KindConflict)
)

const (
	sqlInsert = `INSERT INTO citations (
		id, ref, artifact_id, graph_id, locator_json, transcription, label,
		transcription_uncertain, transcription_note
	) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`

	sqlInsertNote = `INSERT INTO citation_notes (id, citation_id, body) VALUES (?, ?, ?)`

	sqlUpdate = `UPDATE citations SET
		artifact_id = ?, locator_json = ?, transcription = ?, label = ?,
		transcription_uncertain = ?, transcription_note = ?
		WHERE id = ?`

	sqlListNotes = `SELECT body FROM citation_notes WHERE citation_id = ? ORDER BY rowid`

	// A graph's Citations on an Artifact, each with its Observation count.
	// Binds: artifact, graph.
	// People a Citation names within one graph: the Observation's subject, or
	// the subject an edge points at. Earliest Observation id wins. The caller
	// caps the list. The graph filters the Subjects the Observations name, so it
	// is a join here. Binds per branch: graph, artifact.
	sqlPersonNamesByArtifact = `
WITH named AS (
	SELECT o.citation_id AS cid, s.id AS sid, s.label AS label, o.id AS oid
	FROM observations o
	INNER JOIN citations c ON c.id = o.citation_id
	INNER JOIN subjects s ON s.id = o.subject_id AND s.graph_id = ?
	INNER JOIN subject_types t ON t.id = s.subject_type_id
	WHERE c.artifact_id = ? AND t.key = 'person'
		AND TRIM(COALESCE(s.label, '')) <> ''
	UNION ALL
	SELECT o.citation_id, s.id, s.label, o.id
	FROM observations o
	INNER JOIN citations c ON c.id = o.citation_id
	INNER JOIN subjects so ON so.id = o.subject_id AND so.graph_id = ?
	INNER JOIN subjects s ON s.id = o.value_subject_id
	INNER JOIN subject_types t ON t.id = s.subject_type_id
	WHERE c.artifact_id = ? AND t.key = 'person'
		AND TRIM(COALESCE(s.label, '')) <> ''
)
SELECT cid, sid, label FROM named
GROUP BY cid, sid
ORDER BY cid, MIN(oid)`

	// Binds: graph.
	sqlCountByEvidenceGraph = `SELECT artifact_id, COUNT(*)
		FROM citations WHERE graph_id = ? GROUP BY artifact_id`

	sqlArtifactExists = `SELECT 1 FROM artifacts WHERE id = ?`
)

// The by-id reads below build their column list once, columns, and scan it
// once, scanRow.
var (
	sqlGet = `SELECT ` + columns("") + ` FROM citations WHERE id = ?`

	// A graph's Citations on an Artifact, each with its Observation count.
	// Binds: artifact, graph.
	sqlListByArtifact = `SELECT ` + columns("c") + `,
		(SELECT COUNT(*) FROM observations o WHERE o.citation_id = c.id)
		FROM citations c WHERE c.artifact_id = ? AND c.graph_id = ?
		ORDER BY c.ref COLLATE NOCASE`

	// Binds: ids, in sqlbatch batches.
	sqlListCitedIn = `SELECT ` + columns("c") + `,
		COALESCE(a.label, ''), COALESCE(g.name, ''), g.source_id
		FROM citations c
		LEFT JOIN artifacts a ON a.id = c.artifact_id
		LEFT JOIN evidence_graphs g ON g.id = c.graph_id
		WHERE c.id IN (`
)

// columns is the nine citations columns scanRow reads, each prefixed with
// alias and a dot when alias is not empty.
func columns(alias string) string {
	return database.Columns(alias, "id", "ref", "artifact_id", "graph_id", "locator_json",
		"transcription|COALESCE(%s, '')", "label|COALESCE(%s, '')",
		"transcription_uncertain", "transcription_note|COALESCE(%s, '')")
}

// Citation is one citations row.
type Citation struct {
	ID                     []byte
	Ref                    string
	ArtifactID             []byte
	GraphID                []byte
	LocatorJSON            string
	Transcription          string
	Label                  string
	TranscriptionUncertain bool
	TranscriptionNote      string
}

// Cited is a Citation with what a citation renders from beside it: its
// Artifact's label, its Evidence graph's name and that graph's Source, which is
// the Citation's Source (a Citation never leaves its graph). A missing row
// reads as empty.
type Cited struct {
	Citation
	ArtifactLabel string
	GraphName     string
	SourceID      []byte
}

// ListedCitation is a Citation plus its Observation count and the people it names.
type ListedCitation struct {
	Citation
	ObservationCount int32
	// Person labels, earliest Observation first, capped. Empty when the
	// Citation names nobody.
	SubjectNames []string
}

const subjectNameCap = 6

// CreateInput is the Citation side of first-submit create.
type CreateInput struct {
	ArtifactID []byte
	// GraphID is the Evidence graph the Citation is made in; it never changes.
	// Required, and linked to ArtifactID.
	GraphID                []byte
	LocatorJSON            string
	Transcription          string
	Label                  string
	TranscriptionUncertain bool
	TranscriptionNote      string
	Notes                  []string
}

// CreateResult is the Citation plus Observations created in one transaction.
type CreateResult struct {
	Citation     Citation
	Observations []observations.Observation
}

// CreateWithObservations mints a Citation and any Observations on tx.
// Zero Observations is allowed — a transcription-first reading. The caller
// records the returned changes.
func CreateWithObservations(
	tx *database.Tx,
	userID []byte,
	in CreateInput,
	obsInputs []observations.Input,
) (CreateResult, []rowchange.Change, error) {
	if tx == nil {
		return CreateResult{}, nil, ErrInvalid
	}
	if err := normalizeCreateInput(&in); err != nil {
		return CreateResult{}, nil, err
	}
	if err := database.RequireUserID(userID, ErrInvalid); err != nil {
		return CreateResult{}, nil, err
	}
	return InsertWithObservationsTx(tx.Tx, in, obsInputs, observations.InsertOptions{AllowEdgeRows: false})
}

// NormalizeCreateInput trims citation fields and validates the locator.
func NormalizeCreateInput(in *CreateInput) error {
	return normalizeCreateInput(in)
}

func normalizeCreateInput(in *CreateInput) error {
	in.LocatorJSON = strings.TrimSpace(in.LocatorJSON)
	in.Transcription = strings.TrimSpace(in.Transcription)
	in.Label = strings.TrimSpace(in.Label)
	in.TranscriptionNote = strings.TrimSpace(in.TranscriptionNote)
	if len(in.ArtifactID) != 16 || len(in.GraphID) != 16 {
		return ErrInvalid
	}
	return locator.Validate(in.LocatorJSON)
}

// InsertWithObservationsTx writes a Citation + Observations on an open transaction (no revision).
func InsertWithObservationsTx(
	tx *sql.Tx,
	in CreateInput,
	obsInputs []observations.Input,
	opts observations.InsertOptions,
) (CreateResult, []rowchange.Change, error) {
	if err := normalizeCreateInput(&in); err != nil {
		return CreateResult{}, nil, err
	}

	var one int
	if err := tx.QueryRow(sqlArtifactExists, in.ArtifactID).Scan(&one); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return CreateResult{}, nil, ErrInvalid
		}
		return CreateResult{}, nil, err
	}

	linked, err := evidencegraphs.IsLinkedTx(tx, in.GraphID, in.ArtifactID)
	if err != nil {
		return CreateResult{}, nil, err
	}
	if !linked {
		return CreateResult{}, nil, ErrInvalid
	}

	id, err := uuid.NewV7()
	if err != nil {
		return CreateResult{}, nil, err
	}
	idBytes := id[:]

	uncertain := 0
	if in.TranscriptionUncertain {
		uncertain = 1
	}

	citRef, err := database.InsertWithRef(database.Minter(ref.PrefixCitation), func(storedRef string) error {
		_, err := tx.Exec(
			sqlInsert,
			idBytes,
			storedRef,
			in.ArtifactID,
			in.GraphID,
			in.LocatorJSON,
			database.NullString(in.Transcription),
			database.NullString(in.Label),
			uncertain,
			database.NullString(in.TranscriptionNote),
		)
		return err
	})
	if errors.Is(err, database.ErrRefsExhausted) {
		return CreateResult{}, nil, ErrInvalid
	}
	if err != nil {
		return CreateResult{}, nil, mapConstraint(err)
	}

	changes := []rowchange.Change{{
		EntityType: "citation",
		EntityID:   idBytes,
		Action:     rowchange.ActionCreate,
		Fields: rowchange.FullRow(map[string]any{
			"id":                      id.String(),
			"ref":                     citRef,
			"artifact_id":             database.UUIDJSON(in.ArtifactID),
			"graph_id":                database.UUIDJSON(in.GraphID),
			"locator_json":            in.LocatorJSON,
			"transcription":           database.NullString(in.Transcription),
			"label":                   database.NullString(in.Label),
			"transcription_uncertain": in.TranscriptionUncertain,
			"transcription_note":      database.NullString(in.TranscriptionNote),
		}),
	}}

	for _, body := range in.Notes {
		body = strings.TrimSpace(body)
		if body == "" {
			continue
		}
		noteID, err := uuid.NewV7()
		if err != nil {
			return CreateResult{}, nil, err
		}
		if _, err := tx.Exec(sqlInsertNote, noteID[:], idBytes, body); err != nil {
			return CreateResult{}, nil, err
		}
		changes = append(changes, rowchange.Change{
			EntityType: "citation_note",
			EntityID:   noteID[:],
			Action:     rowchange.ActionCreate,
			Fields: rowchange.FullRow(map[string]any{
				"id":          noteID.String(),
				"citation_id": id.String(),
				"body":        body,
			}),
		})
	}

	var obsOut []observations.Observation
	if len(obsInputs) > 0 {
		var obsChanges []rowchange.Change
		obsOut, obsChanges, err = observations.InsertManyTx(tx, idBytes, obsInputs, opts)
		if err != nil {
			return CreateResult{}, nil, err
		}
		changes = append(changes, obsChanges...)
	}

	return CreateResult{
		Citation: Citation{
			ID:                     append([]byte(nil), idBytes...),
			Ref:                    citRef,
			ArtifactID:             append([]byte(nil), in.ArtifactID...),
			GraphID:                append([]byte(nil), in.GraphID...),
			LocatorJSON:            in.LocatorJSON,
			Transcription:          in.Transcription,
			Label:                  in.Label,
			TranscriptionUncertain: in.TranscriptionUncertain,
			TranscriptionNote:      in.TranscriptionNote,
		},
		Observations: obsOut,
	}, changes, nil
}

// CitationFieldsInput is the citation-row fields Update may change.
type CitationFieldsInput struct {
	LocatorJSON            string
	Transcription          string
	Label                  string
	TranscriptionUncertain bool
	TranscriptionNote      string
}

// Update changes citation columns only. An unchanged row returns no changes.
// It never touches notes or observations. The caller records the returned changes.
func Update(tx *database.Tx, userID, citationID []byte, in CitationFieldsInput) (Citation, []rowchange.Change, error) {
	if tx == nil {
		return Citation{}, nil, ErrInvalid
	}
	in.LocatorJSON = strings.TrimSpace(in.LocatorJSON)
	in.Transcription = strings.TrimSpace(in.Transcription)
	in.Label = strings.TrimSpace(in.Label)
	in.TranscriptionNote = strings.TrimSpace(in.TranscriptionNote)
	if len(citationID) != 16 {
		return Citation{}, nil, ErrInvalid
	}
	if err := locator.Validate(in.LocatorJSON); err != nil {
		return Citation{}, nil, err
	}
	if err := database.RequireUserID(userID, ErrInvalid); err != nil {
		return Citation{}, nil, err
	}

	prev, err := scanOne(tx.QueryRow(sqlGet, citationID))
	if errors.Is(err, sql.ErrNoRows) {
		return Citation{}, nil, ErrInvalid
	}
	if err != nil {
		return Citation{}, nil, err
	}

	fields := map[string]rowchange.FieldDiff{}
	if prev.LocatorJSON != in.LocatorJSON {
		fields["locator_json"] = rowchange.FieldDiff{Old: prev.LocatorJSON, New: in.LocatorJSON}
	}
	if prev.Transcription != in.Transcription {
		fields["transcription"] = rowchange.FieldDiff{Old: database.NullString(prev.Transcription), New: database.NullString(in.Transcription)}
	}
	if prev.Label != in.Label {
		fields["label"] = rowchange.FieldDiff{Old: database.NullString(prev.Label), New: database.NullString(in.Label)}
	}
	if prev.TranscriptionUncertain != in.TranscriptionUncertain {
		fields["transcription_uncertain"] = rowchange.FieldDiff{
			Old: prev.TranscriptionUncertain,
			New: in.TranscriptionUncertain,
		}
	}
	if prev.TranscriptionNote != in.TranscriptionNote {
		fields["transcription_note"] = rowchange.FieldDiff{
			Old: database.NullString(prev.TranscriptionNote),
			New: database.NullString(in.TranscriptionNote),
		}
	}
	if len(fields) == 0 {
		return prev, nil, nil
	}

	uncertain := 0
	if in.TranscriptionUncertain {
		uncertain = 1
	}
	if _, err := tx.Exec(
		sqlUpdate,
		prev.ArtifactID,
		in.LocatorJSON,
		database.NullString(in.Transcription),
		database.NullString(in.Label),
		uncertain,
		database.NullString(in.TranscriptionNote),
		citationID,
	); err != nil {
		return Citation{}, nil, err
	}
	return Citation{
			ID:                     append([]byte(nil), citationID...),
			Ref:                    prev.Ref,
			ArtifactID:             append([]byte(nil), prev.ArtifactID...),
			GraphID:                append([]byte(nil), prev.GraphID...),
			LocatorJSON:            in.LocatorJSON,
			Transcription:          in.Transcription,
			Label:                  in.Label,
			TranscriptionUncertain: in.TranscriptionUncertain,
			TranscriptionNote:      in.TranscriptionNote,
		}, []rowchange.Change{{
			EntityType: "citation",
			EntityID:   append([]byte(nil), citationID...),
			Action:     rowchange.ActionUpdate,
			Fields:     fields,
		}}, nil
}

// Delete erases a Citation when no Observation remains. Its notes are
// released, audited, through deleteimpact.ReleaseCitation.
// The caller records the returned changes.
func Delete(tx *database.Tx, userID, id []byte) ([]rowchange.Change, error) {
	if tx == nil || len(id) != 16 {
		return nil, ErrInvalid
	}
	if err := database.RequireUserID(userID, ErrInvalid); err != nil {
		return nil, err
	}
	var one int
	if err := tx.QueryRow(`SELECT 1 FROM citations WHERE id = ?`, id).Scan(&one); errors.Is(err, sql.ErrNoRows) {
		return nil, ErrInvalid
	} else if err != nil {
		return nil, err
	}

	report, err := deleteimpact.Impact(tx.Tx, catalogmodel.KindCitation, id)
	if err != nil {
		return nil, err
	}
	if err := deleteimpact.Refuse(report, deleteimpact.Codes{
		InUse: ErrInUse, NotFound: ErrInvalid,
	}); err != nil {
		return nil, err
	}
	return deleteimpact.ReleaseCitation(tx, id)
}

// ListNotes returns citation_notes bodies for a citation.
func ListNotes(c *database.Catalog, citationID []byte) ([]string, error) {
	db, err := c.DB()
	if err != nil {
		return nil, err
	}
	if len(citationID) != 16 {
		return nil, ErrInvalid
	}
	rows, err := db.Query(sqlListNotes, citationID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []string
	for rows.Next() {
		var body string
		if err := rows.Scan(&body); err != nil {
			return nil, err
		}
		out = append(out, body)
	}
	return out, rows.Err()
}

// Get returns a Citation by id.
func Get(c *database.Catalog, id []byte) (Citation, error) {
	db, err := c.DB()
	if err != nil {
		return Citation{}, err
	}
	if len(id) != 16 {
		return Citation{}, ErrInvalid
	}
	return scanOne(db.QueryRow(sqlGet, id))
}

// GetTx returns a Citation by id on an open transaction.
func GetTx(tx *sql.Tx, id []byte) (Citation, error) {
	if len(id) != 16 {
		return Citation{}, ErrInvalid
	}
	return scanOne(tx.QueryRow(sqlGet, id))
}

// ListCitedTx returns the Citations with the given ids, each with its
// Artifact's label, its graph's name and the graph's Source id, keyed by
// string(id). A repeated id counts once and an id with no Citation is absent;
// no ids returns an empty map and runs no query.
func ListCitedTx(tx *sql.Tx, ids [][]byte) (map[string]Cited, error) {
	ids = database.UniqueBlobIDs(ids)
	out := make(map[string]Cited, len(ids))
	if len(ids) == 0 {
		return out, nil
	}
	err := sqlbatch.Query(tx, sqlListCitedIn, ")", nil, ids, func(rows *sql.Rows) error {
		var cited Cited
		c, err := scanRow(rows, &cited.ArtifactLabel, &cited.GraphName, &cited.SourceID)
		if err != nil {
			return err
		}
		cited.Citation = c
		out[string(c.ID)] = cited
		return nil
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}

// ListByArtifact returns an Artifact's Citations made in one Evidence graph,
// each with the count of its Observations.
func ListByArtifact(c *database.Catalog, graphID, artifactID []byte) ([]ListedCitation, error) {
	db, err := c.DB()
	if err != nil {
		return nil, err
	}
	if len(graphID) != 16 || len(artifactID) != 16 {
		return nil, ErrInvalid
	}
	rows, err := db.Query(sqlListByArtifact, artifactID, graphID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []ListedCitation
	for rows.Next() {
		var n int32
		c, err := scanRow(rows, &n)
		if err != nil {
			return nil, err
		}
		out = append(out, ListedCitation{Citation: c, ObservationCount: n})
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	if err := attachPersonNames(db, graphID, artifactID, out); err != nil {
		return nil, err
	}
	return out, nil
}

func attachPersonNames(db *sql.DB, graphID, artifactID []byte, list []ListedCitation) error {
	rows, err := db.Query(sqlPersonNamesByArtifact, graphID, artifactID, graphID, artifactID)
	if err != nil {
		return err
	}
	defer rows.Close()
	byCitation := map[string][]string{}
	for rows.Next() {
		var citationID, subjectID []byte
		var label string
		if err := rows.Scan(&citationID, &subjectID, &label); err != nil {
			return err
		}
		_ = subjectID
		key := string(citationID)
		if len(byCitation[key]) >= subjectNameCap {
			continue
		}
		byCitation[key] = append(byCitation[key], strings.TrimSpace(label))
	}
	if err := rows.Err(); err != nil {
		return err
	}
	for i := range list {
		list[i].SubjectNames = byCitation[string(list[i].ID)]
	}
	return nil
}

// CountByEvidenceGraph returns the graph's Citation counts keyed by artifact
// UUID string.
func CountByEvidenceGraph(c *database.Catalog, graphID []byte) (map[string]int32, error) {
	db, err := c.DB()
	if err != nil {
		return nil, err
	}
	if len(graphID) != 16 {
		return nil, ErrInvalid
	}
	rows, err := db.Query(sqlCountByEvidenceGraph, graphID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := map[string]int32{}
	for rows.Next() {
		var artifactID []byte
		var n int32
		if err := rows.Scan(&artifactID, &n); err != nil {
			return nil, err
		}
		u, err := uuid.FromBytes(artifactID)
		if err != nil {
			return nil, err
		}
		out[u.String()] = n
	}
	return out, rows.Err()
}

func scanOne(row database.Scanner) (Citation, error) {
	cit, err := scanRow(row)
	if errors.Is(err, sql.ErrNoRows) {
		return Citation{}, err
	}
	return cit, err
}

// scanRow scans the columns list, then extra destinations.
func scanRow(row database.Scanner, extra ...any) (Citation, error) {
	var (
		c         Citation
		uncertain int
	)
	dest := append([]any{
		&c.ID, &c.Ref, &c.ArtifactID, &c.GraphID, &c.LocatorJSON,
		&c.Transcription, &c.Label, &uncertain, &c.TranscriptionNote,
	}, extra...)
	if err := row.Scan(dest...); err != nil {
		return Citation{}, err
	}
	c.TranscriptionUncertain = uncertain != 0
	return c, nil
}

func mapConstraint(err error) error {
	if database.IsConstraintViolation(err) {
		return ErrInvalid
	}
	return err
}
