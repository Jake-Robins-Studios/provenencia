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
        // Home and End on a list with no rows: -1 is not an index, so `PVList` ignores the key.
        #expect(PVListKeyboard.moveIndex(for: .end, option: false, index: 0, count: 0) == -1)
        #expect(PVListKeyboard.moveIndex(for: .home, option: false, index: 0, count: 16_000) == 0)
        #expect(PVListKeyboard.moveIndex(for: .end, option: false, index: 0, count: 16_000) == 15_999)
    }

    /// The color as drawn under `scheme`, as sRGB components.
    @MainActor
    private func drawn(_ color: Color, in scheme: ColorScheme) -> [CGFloat] {
        var components: [CGFloat] = []
        let appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)!
        appearance.performAsCurrentDrawingAppearance {
            let ns = NSColor(color).usingColorSpace(.sRGB)!
            components = [ns.redComponent, ns.greenComponent, ns.blueComponent, ns.alphaComponent]
        }
        return components
    }

    @MainActor
    @Test func onSelectionInkIsTheSystemsOnlyWhenProminent() {
        for scheme in [ColorScheme.light, .dark] {
            var selected = EnvironmentValues()
            selected.backgroundProminence = .increased
            var resting = EnvironmentValues()
            resting.backgroundProminence = .standard

            let style = PVColor.onSelection(PVColor.textMuted)
            #expect(
                drawn(style.resolve(in: selected), in: scheme)
                    == drawn(Color(nsColor: .alternateSelectedControlTextColor), in: scheme)
            )
            #expect(drawn(style.resolve(in: resting), in: scheme) == drawn(PVColor.textMuted, in: scheme))
        }
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
