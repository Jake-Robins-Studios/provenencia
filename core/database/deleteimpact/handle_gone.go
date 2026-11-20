package deleteimpact

import (
	"database/sql"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/catalogmodel"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sqlbatch"
)

const claimStatusAccepted = "accepted"

func lastMemberRows(tx *sql.Tx, subjectID []byte) ([]probeRow, error) {
	var entityID []byte
	err := tx.QueryRow(`SELECT entity_id FROM identity_claims WHERE subject_id = ? AND status = ?`,
		subjectID, claimStatusAccepted).Scan(&entityID)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	goes, err := handleGoesWithout(tx, entityID, [][]byte{subjectID})
	if err != nil || !goes {
		return nil, err
	}
	var ref string
	if err := tx.QueryRow(`SELECT ref FROM canonical_entities WHERE id = ?`, entityID).Scan(&ref); err != nil {
		return nil, err
	}
	return []probeRow{{ID: append([]byte(nil), entityID...), Ref: ref}}, nil
}

func subjectHandleCascadeExclude(tx *sql.Tx, subjectID []byte) ([]byte, error) {
	last, err := lastMemberRows(tx, subjectID)
	if err != nil || len(last) != 1 {
		return nil, err
	}
	return last[0].ID, nil
}

func subjectHandleCascadeCount(tx *sql.Tx, subjectID []byte) (int, error) {
	exclude, err := subjectHandleCascadeExclude(tx, subjectID)
	if err != nil {
		return 0, err
	}
	var n int
	if len(exclude) == 16 {
		err = tx.QueryRow(`SELECT COUNT(DISTINCT e.id) FROM identity_claims ic
			JOIN canonical_entities e ON e.id = ic.entity_id
			WHERE ic.subject_id = ? AND e.id != ?`, subjectID, exclude).Scan(&n)
	} else {
		err = tx.QueryRow(`SELECT COUNT(DISTINCT e.id) FROM identity_claims ic
			JOIN canonical_entities e ON e.id = ic.entity_id
			WHERE ic.subject_id = ?`, subjectID).Scan(&n)
	}
	return n, err
}

func subjectHandleCascadeList(tx *sql.Tx, subjectID []byte, limit int) ([]probeRow, error) {
	exclude, err := subjectHandleCascadeExclude(tx, subjectID)
	if err != nil {
		return nil, err
	}
	var rows *sql.Rows
	if len(exclude) == 16 {
		rows, err = tx.Query(`SELECT DISTINCT e.id, e.ref FROM identity_claims ic
			JOIN canonical_entities e ON e.id = ic.entity_id
			WHERE ic.subject_id = ? AND e.id != ?
			ORDER BY e.ref COLLATE NOCASE LIMIT ?`, subjectID, exclude, limit)
	} else {
		rows, err = tx.Query(`SELECT DISTINCT e.id, e.ref FROM identity_claims ic
			JOIN canonical_entities e ON e.id = ic.entity_id
			WHERE ic.subject_id = ?
			ORDER BY e.ref COLLATE NOCASE LIMIT ?`, subjectID, limit)
	}
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []probeRow
	for rows.Next() {
		var id []byte
		var ref string
		if err := rows.Scan(&id, &ref); err != nil {
			return nil, err
		}
		out = append(out, probeRow{ID: append([]byte(nil), id...), Ref: ref})
	}
	return out, rows.Err()
}

// handleGoesWithout reports whether entityID would be deleted when the claims
// of the Subjects leaving on it are removed: the handle exists, no other
// Subject holds an accepted claim on it, and Impact allows deleting it.
func handleGoesWithout(tx *sql.Tx, entityID []byte, leaving [][]byte) (bool, error) {
	var one int
	err := tx.QueryRow(`SELECT 1 FROM canonical_entities WHERE id = ?`, entityID).Scan(&one)
	if err == sql.ErrNoRows {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	// A Subject holds at most one accepted claim, so the handle keeps a member
	// unless every accepted claim on it belongs to a leaving Subject. leaving
	// has no bound, so it is read in batches and counted as a set.
	var accepted int
	if err := tx.QueryRow(`SELECT COUNT(*) FROM identity_claims WHERE entity_id = ? AND status = ?`,
		entityID, claimStatusAccepted).Scan(&accepted); err != nil {
		return false, err
	}
	left := map[string]struct{}{}
	err = sqlbatch.Query(tx, `SELECT subject_id FROM identity_claims
		WHERE entity_id = ? AND status = ? AND subject_id IN (`, `)`,
		[]any{entityID, claimStatusAccepted}, leaving, func(rows *sql.Rows) error {
			var id []byte
			if err := rows.Scan(&id); err != nil {
				return err
			}
			left[string(id)] = struct{}{}
			return nil
		})
	if err != nil {
		return false, err
	}
	if len(left) < accepted {
		return false, nil
	}
	report, err := Impact(tx, catalogmodel.KindCanonicalEntity, entityID)
	if err != nil {
		return false, err
	}
	return report.Allowed, nil
}

func releaseHandleIfGone(tx *sql.Tx, entityID, subjectID []byte) (released, error) {
	goes, err := handleGoesWithout(tx, entityID, [][]byte{subjectID})
	if err != nil || !goes {
		return released{}, err
	}
	out, err := releaseFacets(tx, catalogmodel.KindCanonicalEntity, entityID)
	if err != nil {
		return released{}, err
	}
	var (
		typeID, mergedID, likenessID []byte
		ref                          string
		argument, label              sql.NullString
	)
	if err := tx.QueryRow(`SELECT subject_type_id, ref, argument, label, merged_into_id, preferred_likeness_observation_id
		FROM canonical_entities WHERE id = ?`, entityID).
		Scan(&typeID, &ref, &argument, &label, &mergedID, &likenessID); err != nil {
		return released{}, err
	}
	if _, err := tx.Exec(`DELETE FROM canonical_entities WHERE id = ?`, entityID); err != nil {
		return released{}, err
	}
	out.Changes = append(out.Changes, rowchange.Deleted("canonical_entity", entityID, map[string]any{
		"id":                                database.UUIDJSON(entityID),
		"subject_type_id":                   database.UUIDJSON(typeID),
		"ref":                               ref,
		"argument":                          nullStringJSON(argument),
		"label":                             nullStringJSON(label),
		"merged_into_id":                    database.UUIDJSON(mergedID),
		"preferred_likeness_observation_id": database.UUIDJSON(likenessID),
	}))
	return out, nil
}

// LastMemberGroup is the canonical_entities.last_member cascade for one Subject.
func LastMemberGroup(tx *sql.Tx, subjectID []byte) (Group, error) {
	groups, err := collectGroups(tx, []inboundEdge{lastMemberEdge}, subjectID)
	if err != nil || len(groups) == 0 {
		return Group{}, err
	}
	return groups[0], nil
}

// HandleGoesWithout reports whether entityID would be deleted when the accepted
// claims of every Subject in leaving on it are removed.
func HandleGoesWithout(tx *sql.Tx, entityID []byte, leaving [][]byte) (bool, error) {
	return handleGoesWithout(tx, entityID, leaving)
}
