import SwiftUI
import Testing
@testable import Provenencia

struct PVListTests {
    private func action(_ key: KeyEquivalent, option: Bool = false, at index: Int, of count: Int = 25) -> PVListKeyAction {
        PVListKeyboard.action(for: key, option: option, index: index, count: count)
    }

    @Test func clampedIndexStaysInTheList() {
        #expect(PVListKeyboard.clampedIndex(7, count: 3) == 2)
        #expect(PVListKeyboard.clampedIndex(2, count: 3) == 2)
        #expect(PVListKeyboard.clampedIndex(0, count: 3) == 0)
        #expect(PVListKeyboard.clampedIndex(0, count: 0) == 0)
        #expect(PVListKeyboard.clampedIndex(5, count: 0) == 0)
        #expect(PVListKeyboard.clampedIndex(-1, count: 3) == 0)
    }

    @Test func isFocusedRowIsTheClampedRowWhileFocused() {
        #expect(PVListKeyboard.isFocusedRow(2, focusIndex: 2, count: 3, listFocused: true))
        #expect(PVListKeyboard.isFocusedRow(2, focusIndex: 7, count: 3, listFocused: true))
        #expect(!PVListKeyboard.isFocusedRow(1, focusIndex: 7, count: 3, listFocused: true))
        #expect(!PVListKeyboard.isFocusedRow(2, focusIndex: 2, count: 3, listFocused: false))
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
        #expect(PVListKeyboard.moveIndex(for: .home, option: false, index: 12, count: 25) == 0)
        #expect(PVListKeyboard.moveIndex(for: .end, option: false, index: 12, count: 25) == 24)
    }

    @Test func pageKeysMoveByTenAndClamp() {
        #expect(PVListKeyboard.moveIndex(for: .pageDown, option: false, index: 3, count: 25) == 13)
        #expect(PVListKeyboard.moveIndex(for: .pageDown, option: false, index: 20, count: 25) == 24)
        #expect(PVListKeyboard.moveIndex(for: .pageUp, option: false, index: 13, count: 25) == 3)
        #expect(PVListKeyboard.moveIndex(for: .pageUp, option: false, index: 4, count: 25) == 0)
    }

    @Test func pageStepIsTheCallers() {
        #expect(PVListKeyboard.moveIndex(for: .pageDown, option: false, index: 0, count: 20, pageStep: 8) == 8)
        #expect(PVListKeyboard.moveIndex(for: .pageDown, option: false, index: 0, count: 20) == 10)
    }

    @Test func moveIndexTakesOnlyMovementKeys() {
        for key in [KeyEquivalent.return, .space, .escape] {
            #expect(PVListKeyboard.moveIndex(for: key, option: false, index: 1, count: 5) == nil)
        }
        #expect(PVListKeyboard.moveIndex(for: .downArrow, option: false, index: -1, count: 0) == -1)
    }

    @Test func aListHandsThePageKeysOn() {
        for key in [KeyEquivalent.home, .end, .pageUp, .pageDown] {
            #expect(action(key, at: 3) == .ignore)
        }
        #expect(action(.downArrow, at: 3) == .move(to: 4))
        #expect(action(.return, at: 3) == .activate(3))
    }

    @Test func returnAndSpaceActivateTheFocusedRow() {
        #expect(action(.return, at: 7) == .activate(7))
        #expect(action(.space, at: 0) == .activate(0))
    }

    @Test func homeAndEndSkipDisabledRows() {
        #expect(PVListKeyboard.moveIndex(
            for: .home, option: false, index: 2, count: 4, isDisabled: { $0 == 0 }
        ) == 1)
        #expect(PVListKeyboard.moveIndex(
            for: .end, option: false, index: 0, count: 4, isDisabled: { $0 == 3 }
        ) == 2)
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
