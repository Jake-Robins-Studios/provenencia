import SwiftUI
import Testing
@testable import Provenencia

struct PVListTests {
    private func action(_ key: KeyEquivalent, option: Bool = false, at index: Int, of count: Int = 25) -> PVListKeyAction {
        PVListKeyboard.action(for: key, option: option, index: index, count: count)
    }

    @Test func arrowsMoveOneAndClampWithoutWrapping() {
        #expect(action(.downArrow, at: 3) == .move(to: 4))
        #expect(action(.upArrow, at: 3) == .move(to: 2))
        #expect(action(.downArrow, at: 24) == .move(to: 24))
        #expect(action(.upArrow, at: 0) == .move(to: 0))
    }

    @Test func optionArrowsAndHomeEndJumpToTheEnds() {
        #expect(action(.downArrow, option: true, at: 3) == .move(to: 24))
        #expect(action(.upArrow, option: true, at: 20) == .move(to: 0))
        #expect(action(.home, at: 12) == .move(to: 0))
        #expect(action(.end, at: 12) == .move(to: 24))
    }

    @Test func pageKeysMoveByTenAndClamp() {
        #expect(action(.pageDown, at: 3) == .move(to: 13))
        #expect(action(.pageDown, at: 20) == .move(to: 24))
        #expect(action(.pageUp, at: 13) == .move(to: 3))
        #expect(action(.pageUp, at: 4) == .move(to: 0))
    }

    @Test func pageStepIsTheCallers() {
        #expect(PVListKeyboard.moveIndex(for: .pageDown, option: false, index: 0, count: 20, pageStep: 8) == 8)
        #expect(PVListKeyboard.moveIndex(for: .pageDown, option: false, index: 0, count: 20) == 10)
        #expect(action(.pageDown, at: 0, of: 20) == .move(to: 10))
    }

    @Test func moveIndexTakesOnlyMovementKeys() {
        for key in [KeyEquivalent.return, .space, .escape] {
            #expect(PVListKeyboard.moveIndex(for: key, option: false, index: 1, count: 5) == nil)
        }
        #expect(PVListKeyboard.moveIndex(for: .downArrow, option: false, index: -1, count: 0) == -1)
    }

    @Test func returnAndSpaceActivateTheFocusedRow() {
        #expect(action(.return, at: 7) == .activate(7))
        #expect(action(.space, at: 0) == .activate(0))
    }

    @Test func homeAndEndSkipDisabledRows() {
        #expect(PVListKeyboard.action(
            for: .home, option: false, index: 2, count: 4, isDisabled: { $0 == 0 }
        ) == .move(to: 1))
        #expect(PVListKeyboard.action(
            for: .end, option: false, index: 0, count: 4, isDisabled: { $0 == 3 }
        ) == .move(to: 2))
        #expect(PVListKeyboard.action(
            for: .downArrow, option: false, index: 0, count: 4, isDisabled: { $0 == 1 }
        ) == .move(to: 2))
    }

    @Test func otherKeysAndEmptyListsAreIgnored() {
        #expect(action(KeyEquivalent("a"), at: 2) == .ignore)
        #expect(action(.downArrow, at: 0, of: 0) == .ignore)
        #expect(action(.return, at: 0, of: 0) == .ignore)
    }

    /// T-11 (D-9, AC-1.3): a table that opens rows reads Return and Space through `PVListKeyboard`.
    @Test func returnAndSpaceActivateForATable() {
        #expect(action(.return, at: -1, of: 3) == .activate(0))
        #expect(action(.space, at: 1, of: 3) == .activate(1))
        #expect(action(.return, at: 2, of: 3) == .activate(2))
        #expect(action(.return, at: 0, of: 0) == .ignore)
    }

    @Test func densityPaddingMatchesTheKit() {
        #expect(PVListDensity.comfortable.vertical == 11)
        #expect(PVListDensity.comfortable.horizontal == 16)
        #expect(PVListDensity.compact.vertical == 7)
        #expect(PVListDensity.compact.horizontal == 12)
    }
}
