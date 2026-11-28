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

    @State private var card = PVContextMenuState()
    @FocusState private var isFocused: Bool

    /// The icon's side (`PVIcon` size), which the card hangs below.
    private static let iconSize: CGFloat = 15
    /// The board's tooltip width.
    private static let cardWidth: CGFloat = 260

    init(icon: PVSymbol, label: LocalizedStringResource, help: LocalizedStringResource) {
        self.icon = icon
        self.label = label
        self.help = help
    }

    var body: some View {
        PVIcon(icon, size: Self.iconSize)
            .foregroundStyle(PVColor.textMuted)
            .contentShape(Circle())
            .pvFocusRing(isFocused, cornerRadius: PVRadius.pill)
            .focusable()
            .focused($isFocused)
            .onTapGesture { toggle() }
            .onKeyPress(.space) {
                toggle()
                return .handled
            }
            .onChange(of: isFocused) { _, focused in
                if !focused { card.dismiss() }
            }
            .help(L10n.string(help))
            .pvContextMenu($card) {
                PVContextMenuPanel(width: Self.cardWidth) {
                    Text(help)
                        .font(PVFont.body(size: PVTypeScale.bodySmall))
                        .foregroundStyle(PVColor.textSecondary)
                        .padding(PVSpacing.space4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .pvSheetInnerEdit(card.isPresented)
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
            card.present(at: CGPoint(x: 0, y: Self.iconSize + PVSpacing.space2))
        }
    }
}

#if DEBUG
#Preview("Help icon") {
    PVHelpIcon(icon: .info, label: LocalizedStringResource("Help"), help: LocalizedStringResource("Space, a click or hover shows this sentence."))
        .padding(PVSpacing.space8)
}
#endif
