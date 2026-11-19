package deleteimpact

import (
	"database/sql"
	"strings"

	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/catalogmodel"
	"github.com/google/uuid"
)

// ViaCitationFormats is the inbound via of a Source type naming a metadata
// field in a citation format. It is a text reference, not a foreign key, and
// is shared with the Swift via headings (swift_vocabulary_test).
const ViaCitationFormats = "source_types.citation_formats"

// formatText reads one format column as nothing when it is longer than
// citationformat.MaxFormatBytes: such a text never parses (D-6), so it names no
// field, and a crafted catalog cannot make the scan read it.
func formatText(column string) string {
	return "CASE WHEN length(CAST(" + column + " AS BLOB)) <= ? THEN " + column + " END"
}

var (
	sqlFormatTexts = `SELECT ` + formatText("citation_full") + `, ` + formatText("citation_short") + `, ` + formatText("citation_list") + ` FROM source_types
		WHERE citation_full IS NOT NULL OR citation_short IS NOT NULL OR citation_list IS NOT NULL`
	sqlFormatTypesNaming = `SELECT id, key FROM source_types
		WHERE instr(COALESCE(` + formatText("citation_full") + `, ''), ?) > 0
			OR instr(COALESCE(` + formatText("citation_short") + `, ''), ?) > 0
			OR instr(COALESCE(` + formatText("citation_list") + `, ''), ?) > 0
		ORDER BY label COLLATE NOCASE, key LIMIT ?`
)

// citationFormatEdge is the edge from a metadata field to the Source types
// whose citation formats name it. A format stores a field as the token "#"
// and its canonical id, so the edge matches that token as text in any of the
// three columns; a type counts once however many times it names the field. A
// token inside a literal over-refuses, the safe direction. Count and Totals
// agree by construction: Count is Totals of one id.
func citationFormatEdge() inboundEdge {
	totals := func(tx *sql.Tx, ids [][]byte) (map[string]int, error) {
		ids = database.UniqueBlobIDs(ids)
		tokens := make([]string, len(ids))
		for i, id := range ids {
			t, err := formatToken(id)
			if err != nil {
				return nil, err
			}
			tokens[i] = t
		}
		out := map[string]int{}
		if len(ids) == 0 {
			return out, nil
		}
		rows, err := tx.Query(sqlFormatTexts, citationformat.MaxFormatBytes, citationformat.MaxFormatBytes, citationformat.MaxFormatBytes)
		if err != nil {
			return nil, err
		}
		defer rows.Close()
		for rows.Next() {
			var texts [3]sql.NullString
			if err := rows.Scan(&texts[0], &texts[1], &texts[2]); err != nil {
				return nil, err
			}
			for i, token := range tokens {
				for _, text := range texts {
					if text.Valid && strings.Contains(text.String, token) {
						out[string(ids[i])]++
						break
					}
				}
			}
		}
		return out, rows.Err()
	}
	return inboundEdge{
		Parent: catalogmodel.KindMetadataField,
		Via:    ViaCitationFormats,
		Child:  catalogmodel.KindSourceType,
		Bucket: catalogmodel.BucketResource,
		Count: func(tx *sql.Tx, id []byte) (int, error) {
			got, err := totals(tx, [][]byte{id})
			return got[string(id)], err
		},
		Totals: totals,
		List: func(tx *sql.Tx, id []byte, limit int) ([]probeRow, error) {
			token, err := formatToken(id)
			if err != nil {
				return nil, err
			}
			rows, err := tx.Query(sqlFormatTypesNaming,
				citationformat.MaxFormatBytes, token, citationformat.MaxFormatBytes, token, citationformat.MaxFormatBytes, token, limit)
			if err != nil {
				return nil, err
			}
			defer rows.Close()
			var out []probeRow
			for rows.Next() {
				r := probeRow{}
				if err := rows.Scan(&r.ID, &r.Ref); err != nil {
					return nil, err
				}
				out = append(out, r)
			}
			return out, rows.Err()
		},
	}
}

// formatToken is how a stored format writes the field with this id.
func formatToken(id []byte) (string, error) {
	u, err := uuid.FromBytes(id)
	if err != nil {
		return "", ErrInvalid
	}
	return citationformat.FieldRef{ID: u}.Token(), nil
}
