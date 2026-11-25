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

    @MainActor
    @Test func datePlaceLineTakesTheOnSelectionInk() throws {
        func png(_ prominence: BackgroundProminence) throws -> Data {
            let view = PVDatePlaceLine(
                date: "1851", place: "Lyon, France", accessibilityLabel: "",
                missing: .omitted, dateTone: PVColor.textMuted
            )
            .padding(4).background(Color.blue)
            .environment(\.backgroundProminence, prominence)
            let image = try #require(ImageRenderer(content: view).nsImage)
            return try #require(image.tiffRepresentation)
        }
        #expect(try png(.increased) != png(.standard))
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

    /// AC-1.3: a table that opens rows reads Return and Space through `PVListKeyboard`.
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

    private struct PlainRow: Identifiable { let id: String }

    /// A mouse wheel moves the list by `verticalLineScroll`, which the table takes from its row
    /// height: a minimum row height of 1 pt made one wheel step 1 pt.
    @Test(.hostedWindows) @MainActor func aWheelStepScrollsOneRow() throws {
        let rows = (0 ..< 5).map { PlainRow(id: "PER-0000\($0)") }
        let list = PVList(
            items: rows,
            selection: .constant(nil),
            thumbnail: { _ in Color.red },
            label: L10n.Workspace.personsTitle,
            itemAccessibilityLabel: { $0.id },
            onActivate: { _ in },
            primary: { Text(verbatim: $0.id) },
            secondary: { _ in Text(verbatim: "second") }
        )
        let (_, host) = hostInBorderlessWindow(list, windowSize: CGSize(width: 600, height: 400))
        host.layoutSubtreeIfNeeded()
        let scroll = try #require(descendant(NSScrollView.self, in: host))
        #expect(scroll.verticalLineScroll == 66)
    }

    /// The x-extent of the hairline drawn under a row: the first and last column where a pixel is drawn
    /// across most of a one-pixel band inside the row's rect. Nil when the row draws no rule.
    @MainActor
    private func ruleExtent(row: Int, in table: NSTableView) -> ClosedRange<Int>? {
        // Only the row's lower band is drawn and read: a whole-table bitmap read pixel by pixel blocks the
        // main thread for seconds on a slow runner.
        let row = table.rect(ofRow: row)
        let band = NSRect(x: 0, y: row.minY + row.height * 0.6, width: table.bounds.width, height: row.height * 0.4)
        guard let rep = table.bitmapImageRepForCachingDisplay(in: band), let data = rep.bitmapData else { return nil }
        table.cacheDisplay(in: band, to: rep)
        let scale = CGFloat(rep.pixelsWide) / band.width
        let alphaOffset = rep.bitmapFormat.contains(.alphaFirst) ? 0 : rep.samplesPerPixel - 1
        var best: ClosedRange<Int>?
        for y in 0 ..< rep.pixelsHigh {
            var first: Int?
            var last = 0
            var count = 0
            let line = data + y * rep.bytesPerRow
            for x in 0 ..< rep.pixelsWide where line[x * rep.samplesPerPixel + alphaOffset] > 13 {
                if first == nil { first = x }
                last = x
                count += 1
            }
            if let first, count > rep.pixelsWide / 2, count >= (last - first) * 9 / 10 {
                best = first ... last
            }
        }
        return best.map { Int(CGFloat($0.lowerBound) / scale) ... Int(CGFloat($0.upperBound) / scale) }
    }

    /// A plain list (the Persons list's shape): its rules run gutter to gutter.
    @Test(.hostedWindows) @MainActor func aPlainListsRulesRunGutterToGutter() async throws {
        let list = PVList(
            items: (0 ..< 3).map { PlainRow(id: "r\($0)") },
            selection: .constant(nil),
            thumbnail: { _ in PVThumbnail(PVThumbnail.Content(glyph: .mark(.subjectPerson))) },
            horizontalInset: 32,
            label: L10n.Workspace.personsTitle,
            itemAccessibilityLabel: { $0.id },
            onActivate: { _ in },
            primary: { Text(verbatim: $0.id) },
            secondary: { _ in EmptyView() }
        )
        let (_, host) = hostInBorderlessWindow(list, windowSize: CGSize(width: 800, height: 400))
        var extent: ClosedRange<Int>?
        var width = 0
        #expect(await waitUntil(timeout: .seconds(10)) {
            host.layoutSubtreeIfNeeded()
            guard let table = descendant(NSTableView.self, in: host), table.numberOfRows == 3 else { return false }
            extent = ruleExtent(row: 0, in: table)
            width = Int(table.bounds.width)
            return extent != nil
        })
        // A rule starts at the gutter and ends within the platform's few points of the trailing one.
        let rule = try #require(extent)
        #expect(rule.lowerBound == 32)
        #expect((width - 36 ... width - 32).contains(rule.upperBound))
    }

    /// A row's inset on each side is the list's inset less the cell inset the table adds.
    @Test func rowInsetLeavesTheCellInset() {
        #expect(PVListMetrics.rowInset(horizontalInset: 32) == 24)
        #expect(PVListMetrics.rowInset(horizontalInset: 56) == 48)
        #expect(PVListMetrics.rowInset(horizontalInset: 4) == 0)
    }

    @Test func outlineChevronPointsRightThenDown() {
        #expect(PVExpandedState.outlineChevron(isExpanded: false) == .chevronForward)
        #expect(PVExpandedState.outlineChevron(isExpanded: true) == .chevronDown)
    }

    /// The list's menu draws `Text(verbatim: L10n.string(entry.title))`: the string path keeps a graph
    /// named `**a**` as typed (the hosted menu is the platform's, so the string is what is tested).
    @Test func aMenuTitleKeepsItsAsterisks() {
        let item = PVActionMenuItem(title: LocalizedStringResource(stringLiteral: "Open **a**"))
        #expect(L10n.string(item.title) == "Open **a**")
    }
}
