import Foundation
import Testing
@testable import Provenencia

/// `EvidenceGraphIndex.replacing(sources:)` after a graph moves from one Source
/// to another: the merged re-read reports both Sources, in either order.
struct EvidenceGraphIndexTests {
    private let moved = evidenceGraph("g-moved", sourceID: "src-a", name: "Census", artifactIDs: ["art-1"])
    private let originDefault = evidenceGraph("g-a-default", sourceID: "src-a")
    private let targetDefault = evidenceGraph("g-b-default", sourceID: "src-b")

    private var before: EvidenceGraphIndex {
        EvidenceGraphIndex(rows: [moved, originDefault, targetDefault])
    }

    private var movedAfter: CatalogEvidenceGraph {
        var graph = moved
        graph.sourceID = "src-b"
        return graph
    }

    /// The target's re-read lands before the origin's: the order that dropped the graph.
    @Test func keepsMovedGraphWhenTargetIsReplacedFirst() {
        let index = before
            .replacing(sources: ["src-b": [movedAfter, targetDefault]])
            .replacing(sources: ["src-a": [originDefault]])
        #expect(index.byID["g-moved"] == movedAfter)
        #expect(index.bySource["src-b"]?.map(\.id) == ["g-moved", "g-b-default"])
        #expect(index.bySource["src-a"]?.map(\.id) == ["g-a-default"])
    }

    @Test func keepsMovedGraphWhenOriginIsReplacedFirst() {
        let index = before
            .replacing(sources: ["src-a": [originDefault]])
            .replacing(sources: ["src-b": [movedAfter, targetDefault]])
        #expect(index.byID["g-moved"] == movedAfter)
        #expect(index.linkedArtifactIDsBySource["src-b"] == ["art-1"])
        #expect(index.linkedArtifactIDsBySource["src-a"] == [])
    }

    @Test func keepsMovedGraphWhenBothSourcesAreReplacedTogether() {
        let index = before.replacing(sources: [
            "src-a": [originDefault],
            "src-b": [movedAfter, targetDefault],
        ])
        #expect(index.byID["g-moved"] == movedAfter)
        #expect(index.byID["g-a-default"] == originDefault)
        #expect(index.byID["g-b-default"] == targetDefault)
    }

    @Test func dropsGraphsTheReReadNoLongerLists() {
        let index = before.replacing(sources: ["src-a": [originDefault]])
        #expect(index.byID["g-moved"] == nil)
        #expect(index.bySource["src-a"]?.map(\.id) == ["g-a-default"])
    }
}
