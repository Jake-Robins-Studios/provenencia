import AppKit
import SwiftUI
import Testing
@testable import Provenencia

/// How long the provenance sheet takes to lay out its record table (S15-27 D-9).
@Suite(.serialized, .hostedWindows)
@MainActor
struct PVProvenanceSheetLayoutTests {
    /// A fresh sheet of `count` records at `.ready`, laid out once: the best of 3 times to build and lay
    /// it out, and the height of the scroll area's document, read from the last run's host after the timing.
    private func firstLayout(records count: Int) -> (milliseconds: Double, documentHeight: CGFloat) {
        let content = PVProvenancePreviewData.content(
            groups: [PVProvenanceSheetContent.Group(owner: nil, records: PVProvenancePreviewData.records(count, formatted: true))], summary: nil)
        var last: NSHostingView<PVProvenanceSheet>?
        let best = bestOfMilliseconds(runs: 3) {
            let (_, host) = hostInBorderlessWindow(
                PVProvenanceSheet(content: content, idPrefix: "timing", open: { _, _ in }),
                windowSize: CGSize(width: 880, height: 900))
            host.layoutSubtreeIfNeeded()
            last = host
        }
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
