import AppKit
import SwiftUI
import Testing
@testable import Provenencia

/// How long the provenance sheet takes to lay out its record table (S15-27 D-9).
@Suite(.serialized, .hostedWindows)
@MainActor
struct PVProvenanceSheetLayoutTests {
    /// One record in a run of its own, with an italic run in its full citation, all rows alike.
    private func records(_ count: Int) -> [PVProvenanceSheetContent.Record] {
        let full = [
            CatalogCitationRun(text: "1880 U.S. census, Ontario, Canada; digital image, ", italic: false),
            CatalogCitationRun(text: "Ancestry", italic: true),
            CatalogCitationRun(text: " (accessed 12 March 2025)", italic: false),
        ]
        return (0..<count).map { index in
            var record = PVProvenancePreviewData.record(
                "r\(index)", readAs: "14 May 1817", title: "Parish register \(index)", detail: "p. \(index)")
            record.rendered = CatalogRenderedCitation(
                citationID: "cit-r\(index)",
                full: .init(runs: full, plain: full.map(\.text).joined()),
                short: .init(runs: [CatalogCitationRun(text: "1880 U.S. census", italic: false)], plain: "1880 U.S. census"),
                groupKey: "full:\(index)")
            return record
        }
    }

    /// A fresh sheet of `count` records at `.ready`, laid out once: the best of 3 times to build and lay
    /// it out, and the height of the scroll area's document, read from the last run's host after the timing.
    private func firstLayout(records count: Int) -> (milliseconds: Double, documentHeight: CGFloat) {
        let content = PVProvenancePreviewData.content(
            groups: [PVProvenanceSheetContent.Group(owner: nil, records: records(count))], summary: nil)
        var last: NSHostingView<PVProvenanceSheet>?
        var window: NSWindow?
        let best = bestOfMilliseconds(runs: 3) {
            let (hostWindow, host) = hostInBorderlessWindow(
                PVProvenanceSheet(content: content, idPrefix: "timing", open: { _, _ in }),
                windowSize: CGSize(width: 880, height: 900))
            host.layoutSubtreeIfNeeded()
            window = hostWindow
            last = host
        }
        withExtendedLifetime(window) {}
        let height = last.flatMap { descendant(NSScrollView.self, in: $0)?.documentView?.frame.height } ?? -1
        return (best, height)
    }

    @Test func firstLayoutAt300And1200Records() {
        var heights: [CGFloat] = []
        for count in [300, 1200] {
            let layout = firstLayout(records: count)
            heights.append(layout.documentHeight)
            print("provenance sheet first layout at \(count) records: \(layout.milliseconds) ms")
            print("provenance sheet document height at \(count) records: \(layout.documentHeight) pt")
        }
        // The fold bounds what draws: the same height at both counts.
        #expect(heights[0] > 0)
        #expect(heights[0] == heights[1])
    }
}
