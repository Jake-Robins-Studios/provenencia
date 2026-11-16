import SwiftUI

/// The width class of the workspace pane: Regular below
/// `PVSpacing.widthWideBreakpoint`, Wide at or above it. Measured once by
/// `pvMeasuresWidthClass()` at `WorkspaceDestinationHost`; pages read
/// `@Environment(\.pvWidthClass)`. See
/// [§ 9 of macos-client-patterns.md](../../../../../docs/macos-client-patterns.md#9-window-widths-regular-and-wide).
enum PVWidthClass: Equatable, Sendable {
    case regular
    case wide

    /// The pane's one breakpoint, for `PVWidthBreakpoints`.
    static let breakpoints: [CGFloat] = [PVSpacing.widthWideBreakpoint]

    init(_ met: PVBreakpointsMet) {
        self = met.isAtLeast(PVSpacing.widthWideBreakpoint) ? .wide : .regular
    }

    init(paneWidth: CGFloat) {
        self.init(PVBreakpointsMet(breakpoints: Self.breakpoints, width: paneWidth))
    }
}

private struct PVWidthClassKey: EnvironmentKey {
    static let defaultValue: PVWidthClass = .regular
}

extension EnvironmentValues {
    var pvWidthClass: PVWidthClass {
        get { self[PVWidthClassKey.self] }
        set { self[PVWidthClassKey.self] = newValue }
    }
}

private struct PVMeasuresWidthClass: ViewModifier {
    func body(content: Content) -> some View {
        PVWidthBreakpoints(PVWidthClass.breakpoints) { met in
            content.environment(\.pvWidthClass, PVWidthClass(met))
        }
    }
}

extension View {
    /// Measures the width this view is given (through `PVWidthBreakpoints`,
    /// which fills it) and gives that width class to the view's content.
    /// Applied once, by `WorkspaceDestinationHost`; pages read `\.pvWidthClass`
    /// and do not re-measure (§ 9 of macos-client-patterns.md).
    func pvMeasuresWidthClass() -> some View {
        modifier(PVMeasuresWidthClass())
    }
}
