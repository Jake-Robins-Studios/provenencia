import SwiftUI
import Testing
@testable import Provenencia

@MainActor
struct SourcesTableTests {
    struct WidthCase: CustomTestStringConvertible {
        let isWide: Bool
        let tableWidth: CGFloat
        let title: CGFloat
        let fixed: [CGFloat]
        var testDescription: String { "\(isWide ? "wide" : "regular") \(tableWidth)" }
    }

    /// T-8: the board's widths. A table of 1074 pt (a 1102 pt pane less 2 × (32 − 18)) leaves Title 352;
    /// 2220 pt (2296 less 2 × (56 − 18)) leaves 1069; a narrow pane keeps Title at 240 and scrolls.
    @Test(arguments: [
        WidthCase(isWide: false, tableWidth: 1074, title: 352, fixed: [168, 128, 96, 98, 98]),
        WidthCase(isWide: true, tableWidth: 2220, title: 1069, fixed: [240, 140, 160, 120, 120]),
        WidthCase(isWide: false, tableWidth: 772, title: 240, fixed: [168, 128, 96, 98, 98]),
    ])
    func widthsFollowTheBoard(_ c: WidthCase) {
        let widths = SourcesTableWidths(isWide: c.isWide, tableWidth: c.tableWidth)
        #expect(widths.titleMaximum == c.title)
        #expect([widths.evidence, widths.status, widths.published, widths.added, widths.updated] == c.fixed)
        if c.isWide { #expect(widths.type == 220) }
    }

    @Test func theGutterPutsTheFirstHeaderOnIt() {
        #expect(PVWidthClass(paneWidth: 1102).fullPaneGutter - SourcesTableWidths.headerInset == 14)
        #expect(PVWidthClass(paneWidth: 2296).fullPaneGutter == 56)
    }

    /// T-12: a header's first click sorts A to Z for Title and newest first for the dates; the table's
    /// report becomes the page's sort, and an empty report leaves it.
    @Test func headersConvertToTheSort() {
        let current = SourcesSort(column: .added, order: .reverse)
        for column in SourcesSort.Column.allCases {
            let first = SourcesSort(column: column, order: column.firstOrder)
            #expect(SourcesTable.sort(from: [first], current: current) == first)
            let second = SourcesSort(column: column, order: column.firstOrder == .forward ? .reverse : .forward)
            #expect(SourcesTable.sort(from: [second, first], current: current) == second)
        }
        #expect(SourcesTable.sort(from: [], current: current) == current)
        #expect(SourcesSort.Column.title.firstOrder == .forward)
        #expect([SourcesSort.Column.published, .added, .updated].allSatisfy { $0.firstOrder == .reverse })
    }

    @Test func aComparatorNeverReordersRows() {
        let sort = SourcesSort(column: .title, order: .forward)
        #expect(sort.compare(.skeleton(0), .skeleton(1)) == .orderedSame)
    }

    @Test func skeletonRowsHaveStableIDs() {
        let ids = SourcesTableItem.skeletons.map(\.id)
        #expect(ids.count == 30)
        #expect(ids.first == "skeleton-0" && ids.last == "skeleton-29")
        #expect(Set(ids).count == 30)
    }

    @MainActor
    @Test func addedSpokenReadsTheTimeOrSaysItIsUnknown() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Edmonton")!
        let context = TimestampFormat.Context(
            locale: Locale(identifier: "en_US"), calendar: calendar, now: TimestampFormat.parse("2026-10-15T00:00:00Z")!
        )
        #expect(SourcesTable.addedSpoken("2026-10-13T22:40:00Z", in: context) == "added Yesterday")
        #expect(SourcesTable.addedSpoken("", in: context) == "date added unknown")
    }

    @MainActor
    @Test func updatedSpokenReadsTheTimeOrSaysItIsUnknown() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Edmonton")!
        let context = TimestampFormat.Context(
            locale: Locale(identifier: "en_US"), calendar: calendar, now: TimestampFormat.parse("2026-10-15T00:00:00Z")!
        )
        #expect(PVLastUpdated.spoken("2026-10-13T22:40:00Z", in: context) == "updated Yesterday")
        #expect(PVLastUpdated.spoken("", in: context) == "last updated unknown")
    }
}
