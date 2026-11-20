import SwiftUI

/// A micro-caps title row with an optional mono meta string trailing (`metaLabel` is how it is spoken),
/// and a content slot below it. Use it to head a group inside a section: a stepper's
/// picker, or a list's meaning line. Call sites own `.accessibilityIdentifier` and the
/// accessibility label of the group.
struct PVSubsectionHeader<Title: PVCopy, Content: View>: View {
    /// How the meta string reads: muted by default; `danger` for a count over its limit.
    enum MetaTone {
        case muted
        case danger
    }

    private let title: Title
    private let meta: String?
    private let metaTone: MetaTone
    private let metaLabel: String?
    private let metaIdentifier: String?
    private let content: Content

    init(
        title: Title,
        meta: String? = nil,
        metaTone: MetaTone = .muted,
        metaLabel: String? = nil,
        metaIdentifier: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.meta = meta
        self.metaTone = metaTone
        self.metaLabel = metaLabel
        self.metaIdentifier = metaIdentifier
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space2) {
            HStack(spacing: PVSpacing.space4) {
                title.pvText
                    .pvMicroCaps()
                    .foregroundStyle(PVColor.textSecondary)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                if let meta {
                    Text(verbatim: meta)
                        .font(PVFont.mono(size: 11))
                        .foregroundStyle(metaTone == .danger ? PVColor.danger : PVColor.textMuted)
                        .accessibilityLabel(metaLabel ?? meta)
                        .accessibilityIdentifier(metaIdentifier ?? "")
                }
            }
            .frame(height: 20)
            content
        }
    }
}

#Preview("Title, meta and content") {
    PVSubsectionHeader(title: "Evidence graph" as String, meta: "3 fields") {
        Text("What the engine suggests for this level.")
            .font(PVFont.body(size: PVTypeScale.micro, italic: true))
            .foregroundStyle(PVColor.textMuted)
    }
    .padding(PVSpacing.space9)
    .background(PVColor.surfacePage)
}

#Preview("Meta over its limit") {
    PVSubsectionHeader(title: "Full note" as String, meta: "4,012 / 4,000", metaTone: .danger) {
        PVDivider()
    }
    .padding(PVSpacing.space9)
    .background(PVColor.surfacePage)
}

#Preview("Title only") {
    PVSubsectionHeader(title: "Artifact" as String) {
        PVDivider()
    }
    .padding(PVSpacing.space9)
    .background(PVColor.surfacePage)
}
