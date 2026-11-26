import Testing
@testable import Provenencia

struct PVShowMoreRowTests {
    @Test func pressMovesOnlyFromTheRow() {
        let key = PVShowMorePress<Int>(startedOnRow: true, revealed: 6, revealedRow: 6)
        #expect(key.focus == 6 && key.scroll == AnyHashable(6))
        let click = PVShowMorePress<Int>(startedOnRow: false, revealed: 6, revealedRow: 6)
        #expect(click.focus == nil && click.scroll == nil)
        let rowOnly = PVShowMorePress<Int>(startedOnRow: true, revealed: nil, revealedRow: 6)
        #expect(rowOnly.focus == nil && rowOnly.scroll == AnyHashable(6))
    }

    @Test func labelWordsThePage() {
        #expect(L10n.DesignSystem.showMoreRowLabel(1) == "Show 1 more")
        #expect(L10n.DesignSystem.showMoreRowLabel(50) == "Show 50 more")
    }
}
