import AppKit
import SwiftUI
import Testing
@testable import Provenencia

@MainActor
private final class BreakpointsBox {
    var seen: Bool?
}

private struct BreakpointsProbe: View {
    let met: PVBreakpointsMet
    let box: BreakpointsBox

    var body: some View {
        Text(verbatim: "probe")
            .onAppear { box.seen = met.isAtLeast(1200) }
            .onChange(of: met) { _, new in box.seen = new.isAtLeast(1200) }
    }
}

@Suite
struct PVBreakpointsMetTests {
    @Test(arguments: [
        (0, false, false), (879.5, false, false), (880, true, false),
        (1199, true, false), (1200, true, true), (5000, true, true),
    ] as [(CGFloat, Bool, Bool)])
    func meetsABreakpointFromItsWidth(width: CGFloat, at880: Bool, at1200: Bool) {
        let met = PVBreakpointsMet(breakpoints: [880, 1200], width: width)
        #expect(met.isAtLeast(880) == at880)
        #expect(met.isAtLeast(1200) == at1200)
    }

    @Test func readingsBetweenTwoBreakpointsAreEqual() {
        #expect(PVBreakpointsMet(breakpoints: [880], width: 900) == PVBreakpointsMet(breakpoints: [880], width: 1100))
        #expect(PVBreakpointsMet(breakpoints: [880], width: 870) != PVBreakpointsMet(breakpoints: [880], width: 900))
        #expect(
            PVBreakpointsMet(breakpoints: [1200, 880, 1200], width: 1000)
                == PVBreakpointsMet(breakpoints: [880, 1200], width: 1000)
        )
        #expect(PVBreakpointsMet(breakpoints: [], width: 0) == PVBreakpointsMet(breakpoints: [], width: 5000))
    }
}

@MainActor @Suite(.hostedWindows)
struct PVWidthBreakpointsTests {
    @Test func contentIsBuiltForTheWidthAfterOneLayout() {
        let box = BreakpointsBox()
        let view = PVWidthBreakpoints([1200]) { BreakpointsProbe(met: $0, box: box) }
        let (window, host) = hostInBorderlessWindow(view, windowSize: CGSize(width: 1300, height: 400))
        host.layoutSubtreeIfNeeded()
        #expect(box.seen == true)

        window.setContentSize(NSSize(width: 1100, height: 400))
        host.layoutSubtreeIfNeeded()
        #expect(box.seen == false)
    }

    @Test func measuresTheWidthItFillsNotItsContent() {
        let box = BreakpointsBox()
        let view = PVWidthBreakpoints([1200]) { BreakpointsProbe(met: $0, box: box) }
        let (_, host) = hostInBorderlessWindow(view, windowSize: CGSize(width: 2000, height: 400))
        host.layoutSubtreeIfNeeded()
        #expect(box.seen == true)
    }
}
