import SwiftUI

/// An owner's saved metadata values on its Source page row, read-only: the first four rows with
/// a value as field name and value, and "+n more" past them, which opens the owner's form at
/// its metadata. An owner with none draws nothing inside its column. One view for an Artifact
/// row and an Evidence graph row; the owner decides only its ids.
struct MetadataDetailsColumn: View {
    static let shownCount = 4
    /// The field-name column.
    static let labelWidth: CGFloat = 96

    /// The column's width: 320pt at Regular, 440pt at Wide.
    static func width(_ widthClass: PVWidthClass) -> CGFloat {
        switch widthClass {
        case .regular: 320
        case .wide: 440
        }
    }

    let rows: [CatalogMetadataEntry]
    let owner: MetadataOwner
    let ref: String
    let onMore: () -> Void

    /// The rows with a value, in saved order: the first four and how many follow.
    static func shown(_ rows: [CatalogMetadataEntry]) -> (shown: [CatalogMetadataEntry], more: Int) {
        let valued = rows.filter(\.hasValue)
        return (Array(valued.prefix(shownCount)), max(0, valued.count - shownCount))
    }

    @Environment(\.pvWidthClass) private var widthClass

    private var idPrefix: String { "sources.page.\(owner.level.rawValue).\(owner.id).details" }

    var body: some View {
        let (shown, more) = Self.shown(rows)
        // The wrapper keeps the column when the values draw nothing; a bare empty view has nothing to size.
        VStack(alignment: .leading, spacing: 0) {
            if !shown.isEmpty { content(shown: shown, more: more) }
        }
        .frame(minWidth: 0, maxWidth: Self.width(widthClass), alignment: .topLeading)
    }

    private func content(shown: [CatalogMetadataEntry], more: Int) -> some View {
        VStack(alignment: .leading, spacing: PVSpacing.space2) {
                Grid(alignment: .topLeading, horizontalSpacing: PVSpacing.space5, verticalSpacing: PVSpacing.space1) {
                    ForEach(shown) { entry in
                        GridRow {
                            Text(verbatim: entry.field.label)
                                .font(PVFont.body(size: PVTypeScale.caption))
                                .foregroundStyle(PVColor.textMuted)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .help(entry.field.label)
                                .frame(width: Self.labelWidth, alignment: .leading)
                                .gridColumnAlignment(.leading)
                            MetadataValueText(
                                entry: entry,
                                accessibilityIdentifier: "\(idPrefix).\(entry.field.id)",
                                lineLimit: 1,
                                chrome: false
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(Text(verbatim: "\(entry.field.label), \(entry.valueText)"))
                    }
                }
                if more > 0 {
                    PVButton(L10n.Sources.metadataDetailsMore(count: more), variant: .link, size: .sm) {
                        onMore()
                    }
                    .accessibilityLabel(L10n.Sources.metadataDetailsMoreLabel(count: more, ref: ref))
                    .accessibilityIdentifier("\(idPrefix).more")
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(idPrefix)
    }
}
