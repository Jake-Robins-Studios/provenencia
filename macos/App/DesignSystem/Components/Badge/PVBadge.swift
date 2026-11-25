import SwiftUI

/// Tone for `PVBadge` — mirrors `components/core/Badge.jsx`'s `tone` prop.
enum PVBadgeTone {
    case neutral, accent, success, warning, danger, info

    fileprivate var colors: (background: Color, foreground: Color, line: Color) {
        switch self {
        case .neutral: (PVColor.surfaceInset, PVColor.textSecondary, PVColor.borderDefault)
        case .accent: (PVColor.accentSoft, PVColor.accentSoftForeground, PVColor.accentLine)
        case .success: (PVColor.successSoft, PVColor.successForeground, PVColor.success)
        case .warning: (PVColor.warningSoft, PVColor.warningForeground, PVColor.warning)
        case .danger: (PVColor.dangerSoft, PVColor.dangerForeground, PVColor.danger)
        case .info: (PVColor.infoSoft, PVColor.infoForeground, PVColor.info)
        }
    }
}

/// A small status/label pill — mirrors `components/core/Badge.jsx` (tone
/// fill, optional leading icon, uppercase micro caption). `subtle` swaps
/// the filled background for a bordered outline, same as the web prop.
struct PVBadge: View {
    private let label: Text?
    private let tone: PVBadgeTone
    private let icon: PVSymbol?
    private let subtle: Bool
    /// Only set for the icon-only badge, which has no text to read out.
    private let iconLabel: Text?
    /// Text / glyph colour override; the tone still owns fill and outline.
    private var foreground: Color?
    /// The badge's least width: its content sits leading inside it, so badges of one column share a width.
    private var minWidth: CGFloat?

    /// For fixed UI copy (e.g. "provenencia", "you"). A `minWidth` holds the badge at least that wide,
    /// its icon and label leading.
    init(
        _ titleKey: LocalizedStringResource,
        tone: PVBadgeTone = .neutral,
        icon: PVSymbol? = nil,
        subtle: Bool = false,
        minWidth: CGFloat? = nil
    ) {
        label = Text(titleKey)
        self.tone = tone
        self.icon = icon
        self.subtle = subtle
        self.minWidth = minWidth
        iconLabel = nil
    }

    /// For badge content that is data, not UI copy (e.g. a raw `plugin:…` origin id).
    /// `foreground` recolours the text and glyph only (a graph card's kind ink on a
    /// neutral outline), leaving the tone's fill and line.
    init(
        text: String,
        tone: PVBadgeTone = .neutral,
        icon: PVSymbol? = nil,
        subtle: Bool = false,
        foreground: Color? = nil
    ) {
        label = Text(text)
        self.tone = tone
        self.icon = icon
        self.subtle = subtle
        iconLabel = nil
        self.foreground = foreground
    }

    /// Glyph-only pill — `PVIcon` is `accessibilityHidden`, so `label` carries
    /// the meaning for VoiceOver and doubles as the hover tooltip.
    init(icon: PVSymbol, label: some PVCopy, tone: PVBadgeTone = .neutral, subtle: Bool = false) {
        self.label = nil
        self.tone = tone
        self.icon = icon
        self.subtle = subtle
        iconLabel = label.pvText
    }

    var body: some View {
        let colors = tone.colors
        HStack(spacing: 5) {
            if let icon {
                PVIcon(icon, size: 11)
            }
            label?
                .tracking(PVMicroCaps.tracking)
                .textCase(.uppercase)
        }
        .font(PVMicroCaps.font)
        .foregroundStyle(ink(foreground ?? colors.foreground))
        .padding(.horizontal, label == nil ? PVSpacing.space2 : PVSpacing.space4)
        .frame(minWidth: minWidth, alignment: .leading)
        .padding(.vertical, PVSpacing.space1)
        .background(subtle ? Color.clear : colors.background)
        .overlay(
            RoundedRectangle(cornerRadius: PVRadius.xs, style: .continuous)
                .stroke(subtle ? ink(colors.line) : AnyShapeStyle(Color.clear), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: PVRadius.xs, style: .continuous))
        .fixedSize()
        .modifier(PVBadgeIconLabel(label: iconLabel))
    }
}

extension PVBadge {
    /// A badge with no fill draws on whatever is behind it, so its ink and outline take the on-selection
    /// ink on a selected native row; a filled badge keeps its own colors.
    private func ink(_ color: Color) -> AnyShapeStyle {
        subtle ? AnyShapeStyle(PVColor.onSelection(color)) : AnyShapeStyle(color)
    }

    /// The "+N" after a title or line when more names or places survived. Hidden
    /// from VoiceOver: the row or line it sits in already speaks the count.
    static func moreCount(_ count: Int) -> some View {
        PVBadge(text: L10n.DesignSystem.badgeMoreCount(count), tone: .neutral, subtle: true)
            .accessibilityHidden(true)
    }
}

/// Applies the VoiceOver label + tooltip a glyph-only badge needs, and is a
/// no-op for the text badges (which read out their own label).
private struct PVBadgeIconLabel: ViewModifier {
    let label: Text?

    func body(content: Content) -> some View {
        if let label {
            content
                .accessibilityElement()
                .accessibilityLabel(label)
                .help(label)
        } else {
            content
        }
    }
}

#Preview {
    HStack(spacing: PVSpacing.space5) {
        PVBadge("text", tone: .neutral, icon: .textType, subtle: true)
        PVBadge("date", tone: .info, icon: .calendar, subtle: true)
        PVBadge("provenencia", tone: .accent)
        PVBadge("you", tone: .warning)
        PVBadge(text: "plugin:findagrave", tone: .info)
        PVBadge(icon: .shieldCheck, label: "Seeded by Provenencia", tone: .accent, subtle: true)
    }
    .padding(PVSpacing.space9)
    .background(PVColor.surfacePage)
}
