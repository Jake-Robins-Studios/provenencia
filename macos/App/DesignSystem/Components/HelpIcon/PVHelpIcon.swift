import SwiftUI

/// A small muted icon that explains itself. Tab reaches it; Space or a click
/// opens `help` in a small card below it, Escape or a click outside closes it;
/// hover shows the same text as a tooltip; VoiceOver reads it as the hint.
/// Beside a section heading or a control that needs a sentence of help. Call
/// sites own `.accessibilityIdentifier`.
struct PVHelpIcon: View {
    private let icon: PVSymbol
    private let label: LocalizedStringResource
    private let help: LocalizedStringResource
    private let cardEdge: HorizontalEdge

    @State private var card = PVContextMenuState()
    @FocusState private var isFocused: Bool

    /// The icon's side (`PVIcon` size).
    private static let iconSize: CGFloat = 15
    /// Padding around the glyph so the focus ring circles it.
    private static let ringPadding = PVSpacing.space2
    /// The padded icon's side, which the card hangs below.
    private static let iconFrame = iconSize + 2 * ringPadding
    /// The board's tooltip width.
    private static let cardWidth: CGFloat = 260

    /// `cardEdge` is the icon edge the card's matching edge lines up with:
    /// `.leading` opens the card rightward, `.trailing` leftward.
    init(
        icon: PVSymbol,
        label: LocalizedStringResource,
        help: LocalizedStringResource,
        cardEdge: HorizontalEdge = .leading
    ) {
        self.cardEdge = cardEdge
        self.icon = icon
        self.label = label
        self.help = help
    }

    var body: some View {
        PVIcon(icon, size: Self.iconSize)
            .foregroundStyle(PVColor.textMuted)
            .padding(Self.ringPadding)
            .contentShape(Circle())
            .pvFocusRing(isFocused, cornerRadius: PVRadius.pill)
            .focusable()
            .focusEffectDisabled()
            .focused($isFocused)
            .onTapGesture { toggle() }
            .onKeyPress(.space) {
                toggle()
                return .handled
            }
            .onChange(of: isFocused) { _, focused in
                if !focused { card.dismiss() }
            }
            .help(card.isPresented ? "" : L10n.string(help))
            .pvContextMenu($card) {
                PVContextMenuPanel(width: Self.cardWidth) {
                    Text(help)
                        .font(PVFont.body(size: PVTypeScale.bodySmall))
                        .foregroundStyle(PVColor.textSecondary)
                        .padding(PVSpacing.space4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .accessibilityElement()
            .accessibilityLabel(L10n.string(label))
            .accessibilityHint(L10n.string(help))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { toggle() }
            .pvExpandedState(card.isPresented)
    }

    private func toggle() {
        if card.isPresented {
            card.dismiss()
        } else {
            let x = cardEdge == .leading ? 0 : Self.iconFrame - Self.cardWidth
            card.present(at: CGPoint(x: x, y: Self.iconFrame + PVSpacing.space1))
        }
    }
}

#if DEBUG
#Preview("Help icon") {
    PVHelpIcon(icon: .info, label: LocalizedStringResource("Help"), help: LocalizedStringResource("Space, a click or hover shows this sentence."))
        .padding(PVSpacing.space8)
}
#endif
