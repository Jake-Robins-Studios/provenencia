import SwiftUI

/// A small muted icon that explains itself: hover or focus shows `help` as a
/// tooltip, and VoiceOver speaks `label` then `help` as one element. Beside a
/// section heading or a control that needs a sentence of help. Call sites own
/// `.accessibilityIdentifier`.
struct PVHelpIcon: View {
    private let icon: PVSymbol
    private let label: LocalizedStringResource
    private let help: LocalizedStringResource

    init(icon: PVSymbol, label: LocalizedStringResource, help: LocalizedStringResource) {
        self.icon = icon
        self.label = label
        self.help = help
    }

    var body: some View {
        PVIcon(icon, size: 15)
            .foregroundStyle(PVColor.textMuted)
            .help(L10n.string(help))
            .accessibilityElement()
            .accessibilityLabel(L10n.string(label))
            .accessibilityHint(L10n.string(help))
    }
}

#if DEBUG
#Preview("Help icon") {
    PVHelpIcon(icon: .info, label: L10n.Sources.privateHelpLabel, help: L10n.Sources.privateSwitchHelp)
        .padding(PVSpacing.space8)
}
#endif
