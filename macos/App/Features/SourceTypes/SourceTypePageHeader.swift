import SwiftUI

/// The Source type page's pinned header (S15-D27 TP-3): the eyebrow with Delete at its trailing
/// edge, the saved mark beside the saved label, the origin, the mono key and the usage line, the
/// key hint, and a failed delete's callout. It shows saved values; the draft shows only in
/// Details. Before the type is known it draws the same places as skeleton bars. The page's
/// `PVPageColumns` draws the band's width and the rule under it.
struct SourceTypePageHeader: View {
    @Bindable var model: SourceTypePageModel

    var body: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space5) {
            if let type = model.type {
                loaded(type)
            } else {
                loading
            }
        }
        .padding(.top, PVSpacing.space5)
        .padding(.bottom, PVSpacing.space6)
    }

    private func loaded(_ type: CatalogSourceType) -> some View {
        VStack(alignment: .leading, spacing: PVSpacing.space5) {
            HStack(alignment: .top, spacing: PVSpacing.space5) {
                eyebrow
                PVIconButton(.trash, label: model.deleteTooltip, size: .sm, tone: .danger) {
                    Task { await model.askDelete() }
                }
                .accessibilityLabel(Text(verbatim: model.deleteAccessibilityLabel))
                .accessibilityIdentifier("sourceTypes.delete")
            }
            HStack(alignment: .center, spacing: PVSpacing.space6) {
                PVThumbnail(.init(glyph: .mark(PVMarkKey(catalogKey: type.iconKey))), size: 52)
                    .accessibilityIdentifier("sourceTypes.detail.icon")
                Text(type.label)
                    .font(PVFont.display(size: PVTypeScale.display3))
                    .foregroundStyle(PVColor.textDisplay)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
            }
            HStack(spacing: PVSpacing.space5) {
                OriginBadge(origin: type.origin)
                Text(type.key)
                    .font(PVFont.mono(size: PVTypeScale.micro))
                    .foregroundStyle(PVColor.textSecondary)
                    .accessibilityIdentifier("sourceTypes.detail.key")
                Text(verbatim: "·")
                    .font(PVFont.mono(size: PVTypeScale.micro))
                    .foregroundStyle(PVColor.textFaint)
                    .accessibilityHidden(true)
                Text(L10n.SourceTypes.usage(count: type.usedBy))
                    .font(PVFont.mono(size: PVTypeScale.micro))
                    .foregroundStyle(PVColor.textFaint)
                    .accessibilityIdentifier("sourceTypes.detail.usage")
            }
            Text(L10n.SourceTypes.keyHintEdit)
                .font(PVFont.body(size: PVTypeScale.micro, italic: true))
                .foregroundStyle(PVColor.textMuted)
            if model.deleteImpact.request == nil, let deleteError = model.deleteError {
                PVCallout(tone: .danger, message: deleteError)
                    .accessibilityIdentifier("sourceTypes.deleteError")
            }
        }
    }

    private var eyebrow: some View {
        Text(L10n.SourceTypes.detailEyebrowType)
            .pvMicroCaps()
            .foregroundStyle(PVColor.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The board's frame 13: the trash, the mark, the label and the meta line as skeleton bars.
    private var loading: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space5) {
            HStack(alignment: .top, spacing: PVSpacing.space5) {
                eyebrow
                PVSkeletonBar(width: 28, height: 28)
            }
            HStack(alignment: .center, spacing: PVSpacing.space6) {
                PVSkeletonBar(width: 52, height: 52)
                PVSkeletonBar(width: 280, height: 30)
                Spacer(minLength: 0)
            }
            PVSkeletonBar(width: 220, height: 12)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(L10n.SourceTypes.detailEyebrowType))
        .accessibilityIdentifier("sourceTypes.page.loading")
    }
}
