import SwiftUI

/// A Source's expanded state and its Show / Hide action, for a row with a triangle.
struct SourcesExpandedState: ViewModifier {
    let disclosure: SourcesDisclosure
    let toggle: () -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        if disclosure == .none {
            content
        } else {
            let expanded = disclosure == .expanded
            content
                .pvExpandedState(expanded)
                .accessibilityAction(named: Text(expanded ? L10n.Sources.hideGraphs : L10n.Sources.showGraphs)) {
                    toggle()
                }
        }
    }
}

/// The disclosure triangle: a plain button in the row's leading slot, right when closed and down when
/// open, its target the slot by the row's height. Not animated.
struct SourcesDisclosureTriangle: View {
    let sourceID: String
    let disclosure: SourcesDisclosure
    let toggle: () -> Void
    let hover: (_ sourceID: String, _ inside: Bool) -> Void

    var body: some View {
        if disclosure == .none {
            Color.clear
        } else {
            Button(action: toggle) {
                PVIcon(PVExpandedState.outlineChevron(isExpanded: disclosure == .expanded), size: 12)
                    .foregroundStyle(PVColor.onSelection(PVColor.textMuted))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable(false)
            .onHover { hover(sourceID, $0) }
            .onDisappear { hover(sourceID, false) }
            .accessibilityIdentifier("sources.row.\(sourceID).disclosure")
        }
    }
}
