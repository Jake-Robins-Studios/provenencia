import Foundation
@testable import Provenencia

/// An Evidence graph row for tests. `ref` defaults to `GPH-` plus the uppercased `id`.
func evidenceGraph(
    _ id: String,
    ref: String? = nil,
    sourceID: String = "src-1",
    name: String = "Default",
    description: String = "",
    artifactIDs: [String] = []
) -> CatalogEvidenceGraph {
    CatalogEvidenceGraph(
        id: id, ref: ref ?? "GPH-\(id.uppercased())", sourceID: sourceID, name: name,
        description: description, artifactIDs: artifactIDs
    )
}

/// An unlink block for tests: `artifactID` is refused in `graphID` for `reason`.
/// For `.artifactInUse` it counts `citations` Citations; `.lastArtifact` counts none,
/// what `GoStore` maps from an unset `citation_count`.
func unlinkBlock(
    _ artifactID: String,
    graphID: String,
    citations: Int,
    reason: EvidenceGraphUnlinkReason = .artifactInUse
) -> CatalogEvidenceGraphUnlinkBlock {
    CatalogEvidenceGraphUnlinkBlock(
        graphID: graphID,
        artifactID: artifactID,
        reason: reason,
        citationCount: reason == .lastArtifact ? 0 : citations
    )
}
