import Testing
@testable import Provenencia

@MainActor @Suite
struct SourceTypeIconGridTests {
    private let keys = ["a", "b", "c", "d", "e", "f", "g"]

    private func target(_ from: String, _ move: SourceTypeIconGrid.Move) -> String? {
        SourceTypeIconGrid.arrowTarget(keys: keys, selection: from, columns: 5, move: move)
    }

    @Test func arrowTargetMovesByOneAndByARow() {
        #expect(target("a", .right) == "b")
        #expect(target("a", .left) == nil)
        #expect(target("a", .down) == "f")
        #expect(target("a", .up) == nil)
        #expect(target("c", .down) == nil)
        #expect(target("g", .right) == nil)
        #expect(target("g", .up) == "b")
        for move in [SourceTypeIconGrid.Move.left, .right, .up, .down] {
            #expect(target("zz", move) == nil)
        }
    }
}
