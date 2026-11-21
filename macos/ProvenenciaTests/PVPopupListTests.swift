import Foundation
import SwiftUI
import Testing
@testable import Provenencia

@Suite
struct PVPopupListHighlightTests {
    private func option(_ value: String, _ label: String, disabled: Bool = false) -> PVComboBoxOption {
        PVComboBoxOption(value: value, label: label, isDisabled: disabled)
    }

    private var pool: [PVComboBoxOption] {
        [option("f1", "Author"), option("f2", "Publication date"), option("f3", "Publisher")]
    }

    /// One key from `index` over `rows`, and where the highlight lands.
    private func moved(
        from index: Int, _ key: KeyEquivalent, command: Bool = false, in rows: [PVComboBoxOption]
    ) -> Int {
        var highlight = PVPopupListHighlight(index: index)
        highlight.move(key, command: command, count: rows.count, isDisabled: { rows[$0].isDisabled })
        return highlight.index
    }

    private func landed(in rows: [PVComboBoxOption]) -> Int {
        var highlight = PVPopupListHighlight(index: 1)
        highlight.land(count: rows.count, isDisabled: { rows[$0].isDisabled })
        return highlight.index
    }

    // MARK: Spotlight landing

    @Test func firstEnabledSkipsDisabledLeadingRows() {
        #expect(landed(in: [option("a", "A", disabled: true), option("b", "B")]) == 1)
    }

    @Test func firstEnabledIsNegativeWhenEveryRowIsDisabled() {
        #expect(landed(in: [option("a", "A", disabled: true), option("b", "B", disabled: true)]) == -1)
        #expect(landed(in: []) == -1)
    }

    @Test func hoverTakesOnlyAnEnabledRowInRange() {
        let rows = [option("a", "A"), option("b", "B", disabled: true), option("c", "C")]
        var highlight = PVPopupListHighlight(index: 0)
        highlight.hover(at: 1, count: rows.count, isDisabled: { rows[$0].isDisabled })
        #expect(highlight.index == 0)
        highlight.hover(at: 2, count: rows.count, isDisabled: { rows[$0].isDisabled })
        #expect(highlight.index == 2)
        highlight.hover(at: 5, count: rows.count, isDisabled: { rows[$0].isDisabled })
        #expect(highlight.index == 2)
    }

    @Test func currentIsNilOutOfRangeAndClearGoesToNone() {
        var highlight = PVPopupListHighlight(index: 2)
        #expect(highlight.current(count: 2) == nil)
        #expect(highlight.current(count: 3) == 2)
        highlight.clear()
        #expect(highlight.index == -1)
    }

    // MARK: Movement

    @Test func movingFromNothingActiveLandsOnTheNearEnd() {
        #expect(moved(from: -1, .downArrow, in: pool) == 0)
        #expect(moved(from: -1, .upArrow, in: pool) == 2)
    }

    @Test func movementClampsAtBothEndsRatherThanCycling() {
        #expect(moved(from: 2, .downArrow, in: pool) == 2)
        #expect(moved(from: 0, .upArrow, in: pool) == 0)
        // A page jump past the end stops at the end, it does not wrap.
        #expect(moved(from: 0, .pageDown, in: pool) == 2)
    }

    @Test func edgeJumpsGoToFirstAndLast() {
        #expect(moved(from: 1, .end, in: pool) == 2)
        #expect(moved(from: 1, .home, in: pool) == 0)
    }

    @Test func movementStepsOverDisabledRows() {
        let rows = [option("a", "A"), option("b", "B", disabled: true), option("c", "C")]
        #expect(moved(from: 0, .downArrow, in: rows) == 2)
        #expect(moved(from: 2, .upArrow, in: rows) == 0)
    }

    @Test func movementStaysPutWhenOnlyDisabledRowsRemain() {
        let rows = [option("a", "A"), option("b", "B", disabled: true)]
        #expect(moved(from: 0, .downArrow, in: rows) == 0)
    }

    @Test func movementOnAnEmptyListIsNegative() {
        #expect(moved(from: -1, .downArrow, in: []) == -1)
    }

    @Test func commandJumpsAndOtherKeys() {
        #expect(moved(from: 0, .downArrow, command: true, in: pool) == 2)
        #expect(moved(from: 2, .upArrow, command: true, in: pool) == 0)
        #expect(moved(from: 2, .pageUp, in: pool) == 0)
        let twelve = (0..<12).map { option("o\($0)", "Option \($0)") }
        #expect(moved(from: 0, .pageDown, in: twelve) == 8)

        let leadingDisabled = [option("a", "A", disabled: true), option("b", "B"), option("c", "C")]
        #expect(moved(from: -1, .upArrow, command: true, in: leadingDisabled) == 1)
        #expect(moved(from: -1, .home, in: leadingDisabled) == 1)

        for key in [KeyEquivalent.return, .escape, .tab, .space, KeyEquivalent("a")] {
            #expect(!PVPopupListHighlight.isMovementKey(key))
            #expect(moved(from: 1, key, in: pool) == 1)
        }
        for key in [KeyEquivalent.upArrow, .downArrow, .home, .end, .pageUp, .pageDown] {
            #expect(PVPopupListHighlight.isMovementKey(key))
        }
    }
}
