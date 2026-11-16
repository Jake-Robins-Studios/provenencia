import SwiftUI

/// Which of a container's breakpoints its width meets. Two widths with no
/// breakpoint between them give equal readings, so a resize that crosses none
/// reports nothing. Order and duplicates in the caller's list do not matter.
struct PVBreakpointsMet: Equatable, Sendable {
    private let breakpoints: Set<CGFloat>
    private let met: Set<CGFloat>

    init(breakpoints: [CGFloat], width: CGFloat) {
        let all = Set(breakpoints)
        self.breakpoints = all
        met = all.filter { $0 <= width }
    }

    /// Whether the width is at least `breakpoint`, which must be one this reading was built with.
    func isAtLeast(_ breakpoint: CGFloat) -> Bool {
        assert(breakpoints.contains(breakpoint), "PVBreakpointsMet: \(breakpoint) is not one of the container's breakpoints")
        return met.contains(breakpoint)
    }
}

/// Fills the width it is given, measures it, and builds its content for the
/// breakpoints that width meets; the content is rebuilt only when one is crossed.
///
/// The container's own `.frame(maxWidth: .infinity)` makes it fill, so the
/// layout the content builds cannot change the width that chose it (§ 9 of
/// macos-client-patterns.md). Breakpoints are fixed for the container's life:
/// a choice that depends on the width class lists one breakpoint per class.
/// Before the first measure no breakpoint is met; the first layout pass
/// corrects that before the frame is drawn.
struct PVWidthBreakpoints<Content: View>: View {
    private let breakpoints: [CGFloat]
    private let content: (PVBreakpointsMet) -> Content
    @State private var reading: PVBreakpointsMet?

    init(_ breakpoints: [CGFloat], @ViewBuilder content: @escaping (PVBreakpointsMet) -> Content) {
        self.breakpoints = breakpoints
        self.content = content
    }

    var body: some View {
        content(reading ?? PVBreakpointsMet(breakpoints: breakpoints, width: 0))
            .frame(maxWidth: .infinity, alignment: .leading)
            .onGeometryChange(for: PVBreakpointsMet.self) { [breakpoints] proxy in
                PVBreakpointsMet(breakpoints: breakpoints, width: proxy.size.width)
            } action: {
                reading = $0
            }
            .onChange(of: Set(breakpoints)) {
                assertionFailure("PVWidthBreakpoints: breakpoints changed")
            }
    }
}

#Preview("800pt") {
    PVWidthBreakpoints([1200]) { met in
        Text(verbatim: "≥ 1200: \(met.isAtLeast(1200))")
    }
    .frame(width: 800)
}

#Preview("1300pt") {
    PVWidthBreakpoints([1200]) { met in
        Text(verbatim: "≥ 1200: \(met.isAtLeast(1200))")
    }
    .frame(width: 1300)
}
