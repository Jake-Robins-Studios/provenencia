package deleteimpact

import (
	"database/sql"
	"maps"
	"slices"

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
// graph. Count uses SELECT COUNT(*) + soleLinkFrom; list uses SELECT a.id,
// a.ref FROM artifacts a WHERE a.id IN (SELECT l.artifact_id + soleLinkFrom).
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
		Count: countSQLFn(`SELECT COUNT(*) ` + soleLinkFrom),
		List:  listSQLFn(`SELECT a.id, a.ref FROM artifacts a WHERE a.id IN (SELECT l.artifact_id ` + soleLinkFrom + `) ORDER BY a.ref COLLATE NOCASE LIMIT ?`),
	}
	return []inboundEdge{lastMemberEdge, leavesHandle, leavesNoGraph}
}

// cascadeEdges returns every cascade edge: Named facet releases converted to
// inboundEdge (facets first), then cascadeEdgeList. Used by cascadesFor and
// CascadeVias to share one edge set.
func cascadeEdges() []inboundEdge {
	var out []inboundEdge
	for _, f := range facetReleases() {
		if !f.Named {
			continue
		}
		out = append(out, inboundEdge{
			Parent: f.Parent, Via: f.Via, Child: f.Child, Bucket: catalogmodel.BucketFacet,
			Count: f.Count, List: f.List,
		})
	}
	out = append(out, cascadeEdgeList...)
	return out
}

// CascadeVias returns the Via of every cascade edge, sorted. TestSwiftVocabularyMatchesGo
// reads it for the "cascade vias" row: a new cascade fails the parity test until Swift
// has its case.
func CascadeVias() []string {
	vias := map[string]bool{}
	for _, e := range cascadeEdges() {
		vias[e.Via] = true
	}
	return slices.Sorted(maps.Keys(vias))
}
