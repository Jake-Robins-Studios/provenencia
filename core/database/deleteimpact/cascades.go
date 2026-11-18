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
	// ViaLeavesNoGraph lists the Artifacts a graph delete leaves in no evidence
	// graph — Artifacts linked to that graph and to no other.
	ViaLeavesNoGraph = "evidence_graph_artifacts.last_graph"
)

// soleLinkFrom is the predicate fragment shared by the count and list queries
// for ViaLeavesNoGraph: Artifact links of a graph whose Artifact has no other
// graph. Count uses SELECT COUNT(*) + soleLinkFrom; list joins artifacts and
// appends ORDER BY a.ref COLLATE NOCASE LIMIT ?.
const soleLinkFrom = `FROM evidence_graph_artifacts l WHERE l.graph_id = ? AND NOT EXISTS (SELECT 1 FROM evidence_graph_artifacts o WHERE o.artifact_id = l.artifact_id AND o.graph_id != l.graph_id)`

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
	leavesNoGraph := inboundEdge{
		Parent: catalogmodel.KindEvidenceGraph,
		Via:    ViaLeavesNoGraph,
		Child:  catalogmodel.KindArtifact,
		Bucket: catalogmodel.BucketFacet,
		Count:  countSQLFn(`SELECT COUNT(*) ` + soleLinkFrom),
		List: listSQLFn(`SELECT a.id, a.ref` +
			` FROM evidence_graph_artifacts l JOIN artifacts a ON a.id = l.artifact_id` +
			` WHERE l.graph_id = ? AND NOT EXISTS` +
			` (SELECT 1 FROM evidence_graph_artifacts o WHERE o.artifact_id = l.artifact_id AND o.graph_id != l.graph_id)` +
			` ORDER BY a.ref COLLATE NOCASE LIMIT ?`),
	}
	return []inboundEdge{lastMemberEdge, leavesHandle, leavesNoGraph}
}

// CascadeVias returns the Via of every Named facet release and every
// cascadeEdgeList entry. TestSwiftVocabularyMatchesGo reads it for the
// "cascade vias" row: a new cascade fails the parity test until Swift has its
// case (D-9).
func CascadeVias() []string {
	seen := map[string]bool{}
	var out []string
	for _, f := range facetReleases() {
		if f.Named && !seen[f.Via] {
			seen[f.Via] = true
			out = append(out, f.Via)
		}
	}
	for _, e := range cascadeEdgeList {
		if !seen[e.Via] {
			seen[e.Via] = true
			out = append(out, e.Via)
		}
	}
	return out
}
