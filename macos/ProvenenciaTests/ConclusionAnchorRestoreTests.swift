import Foundation
import Testing
@testable import Provenencia

@MainActor
struct ConclusionAnchorRestoreTests {
    /// T-9 (D-1): the part names are written to history files, so they are frozen.
    @Test func anchorPartsAreFrozen() {
        #expect(ConclusionSectionAnchor.Part.allCases.map(\.rawValue) == [
            "family", "timeline", "sourceTitle", "sourceLine", "recordLinks", "detailRow", "picture", "related",
        ])
    }

    /// T-10 (AC-4.1, AC-4.2, D-12): only a row that leads somewhere is an anchor.
    @Test func detailRowAnchorNeedsAnOpensRow() {
        var birth = ReconciledValueRowModel.empty(id: "birth", label: "Birth", face: .date, emptyText: "")
        birth.opens = ReconciledValueRowModel.Opens(
            location: .eventDetail(entityId: "e1", ref: "EVT-1", title: nil), label: "Open event"
        )
        let name = ReconciledValueRowModel.empty(id: "name", label: "Name", face: .text, emptyText: "")
        let rows = [birth, name]
        func target(_ part: ConclusionSectionAnchor.Part, _ id: String) -> String? {
            ConclusionDetailRowsSection.anchorTarget(rows: rows, anchor: ConclusionSectionAnchor(part: part, id: id)!)
        }
        #expect(target(.detailRow, "birth") == "birth")
        #expect(target(.detailRow, "name") == nil)
        #expect(target(.detailRow, "unknown") == nil)
        #expect(target(.family, "birth") == nil)
    }

    /// S16-72 D-11, D-12, AC-1.3: an anchor names the stop that takes the keyboard and nothing to scroll
    /// to: the page's own y restores the scroll.
    @Test func anAnchorTakesTheKeyboardAndDoesNotScroll() {
        var birth = ReconciledValueRowModel.empty(id: "birth", label: "Birth", face: .date, emptyText: "")
        birth.opens = ReconciledValueRowModel.Opens(
            location: .eventDetail(entityId: "e1", ref: "EVT-1", title: nil), label: "Open event"
        )
        let stop: String? = ConclusionDetailRowsSection.anchorTarget(
            rows: [birth], anchor: ConclusionSectionAnchor(part: .detailRow, id: "birth")!
        )
        #expect(stop == "birth")
    }
}
