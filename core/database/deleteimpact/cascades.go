package deleteimpact

import (
	"database/sql"

	"github.com/mendahu/provenencia/core/database/catalogmodel"
)

// Cascade vias shared with Swift DeleteImpactCascadeVia (swift_vocabulary_test).
const (
	ViaLeavesHandle     = "identity_claims.subject_id"
	ViaDeletesCitations = "citations.graph_id"
	ViaLastMember       = "canonical_entities.last_member"
)

var (
	cascadeEdgeList []inboundEdge
	lastMemberEdge  inboundEdge
)

func buildCascadeEdges() []inboundEdge {
	lastMemberEdge = inboundEdge{
		Parent: catalogmodel.KindSubject,
		Via:    ViaLastMember,
		Child:  catalogmodel.KindCanonicalEntity,
		Bucket: catalogmodel.BucketFacet,
		Count: func(tx *sql.Tx, subjectID []byte) (int, error) {
			rows, err := lastMemberRows(tx, subjectID)
			return len(rows), err
		},
		List: func(tx *sql.Tx, subjectID []byte, limit int) ([]probeRow, error) {
			rows, err := lastMemberRows(tx, subjectID)
			if err != nil || len(rows) <= limit {
				return rows, err
			}
			return rows[:limit], nil
		},
	}
	leavesHandle := inboundEdge{
		Parent: catalogmodel.KindSubject,
		Via:    ViaLeavesHandle,
		Child:  catalogmodel.KindCanonicalEntity,
		Bucket: catalogmodel.BucketFacet,
		Count: func(tx *sql.Tx, subjectID []byte) (int, error) {
			return subjectHandleCascadeCount(tx, subjectID)
		},
		List: func(tx *sql.Tx, subjectID []byte, limit int) ([]probeRow, error) {
			return subjectHandleCascadeList(tx, subjectID, limit)
		},
	}
	return []inboundEdge{lastMemberEdge, leavesHandle}
}
