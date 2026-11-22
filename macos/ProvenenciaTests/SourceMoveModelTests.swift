import Foundation
import Testing
@testable import Provenencia

@Suite
@MainActor
struct SourceMoveModelTests {
    private let projectDir = "/tmp/source-move.provenencia"
    private let userID = "00000000-0000-7000-8000-000000000001"

    private func graph(_ id: String, name: String? = nil, artifacts: [String] = [], sourceID: String = "s1") -> CatalogEvidenceGraph {
        CatalogEvidenceGraph(
            id: id, ref: "GPH-\(id)", sourceID: sourceID, name: name ?? id, description: "", artifactIDs: artifacts
        )
    }

    private func impact(
        artifacts: [CatalogArtifact],
        graphs: [CatalogEvidenceGraph],
        progress: [EvidenceGraphProgress]? = nil
    ) -> CatalogSourceMoveImpact {
        CatalogSourceMoveImpact(
            sourceID: "s1", artifacts: artifacts, graphs: graphs,
            progress: progress ?? graphs.map { EvidenceGraphProgress(graphId: $0.id, subjectCount: 4, observationCount: 6) },
            sourceCredibilityLabel: "", targetCredibilityLabel: "", weighedAsLabel: "",
            credibilityDiffers: false, leavesSourceEmpty: false, leavesNoGraph: false
        )
    }

    @Test
    func fakeStoreRecordsMoveCalls() async throws {
        let store = FakeStore()
        let a1 = catalogArtifact("a1")
        store.artifactsBySource["s1"] = [a1, catalogArtifact("a2")]
        store.sourceMoveImpacts["a1"] = impact(artifacts: [a1], graphs: [])

        let read = try await store.getSourceMoveImpact(projectDir: projectDir, seed: .artifact("a1"), targetSourceID: "s2")
        #expect(read.artifacts == [a1])
        let result = try await store.moveToSource(
            projectDir: projectDir, userID: userID, seed: .artifact("a1"), targetSourceID: "s2"
        )

        #expect(store.getSourceMoveImpactCalls.map(\.seed) == [.artifact("a1")])
        #expect(store.getSourceMoveImpactCalls.map(\.target) == ["s2"])
        #expect(store.moveToSourceCalls.map(\.target) == ["s2"])
        #expect(result.artifactIDs == ["a1"])
        #expect(store.artifactsBySource["s2"]?.map(\.id) == ["a1"])
        #expect(store.artifactsBySource["s2"]?.first?.sourceID == "s2")
        #expect(store.artifactsBySource["s1"]?.map(\.id) == ["a2"])
    }
}
