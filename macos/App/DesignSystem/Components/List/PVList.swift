import SwiftUI

/// Type text of a list row. Not on `PVList`: a generic type cannot hold a stored static.
enum PVListText {
    /// The primary line of a row; a title built outside the slot (an italicized name) matches it.
    static let titleFont = PVFont.body(size: PVTypeScale.body)
}

/// The numbers a list's rows and its pages share, on a non-generic type because a generic one
/// (`PVListRow`, `PVListBody`) cannot hold a static.
enum PVListMetrics {
    /// The platform's table lays a row's cell in 8 pt on each side of the insets.
    static let platformCellInset: CGFloat = 8

    /// A row's leading inset: the content sits `horizontalInset` from the list's edge, less the cell
    /// inset the table adds, less the `leadingHang` the row draws before its thumbnail (the leading slot).
    static func leadingInset(horizontalInset: CGFloat, leadingHang: CGFloat) -> CGFloat {
        max(0, horizontalInset - platformCellInset - leadingHang)
    }

    /// A row's trailing inset.
    static func trailingInset(horizontalInset: CGFloat) -> CGFloat {
        max(0, horizontalInset - platformCellInset)
    }

    /// How far a row's leading slot (and the gap after it) hangs before the thumbnail's leading edge;
    /// 0 with no slot.
    static func hang(leadingWidth: CGFloat) -> CGFloat {
        leadingWidth > 0 ? leadingWidth + PVSpacing.space2 : 0
    }

    /// The title's leading edge from the row's leading edge: the hang, the thumbnail and the gap after it.
    static func titleLeading(leadingWidth: CGFloat, thumbnailSize: CGFloat) -> CGFloat {
        hang(leadingWidth: leadingWidth) + thumbnailSize + PVSpacing.space6
    }
}

/// The browse list for navigation targets: the platform's own list (SwiftUI's
/// `List`, an `NSTableView`), so selection, ↑ / ↓, Page Up / Page Down and
/// scrolling come from the platform at any size. Homogeneous rows: a
/// thumbnail, a title, an optional secondary line, an optional fixed-width
/// detail column and a trailing mono ref. A click selects (the system's
/// full-width bar); a double-click or Return opens (`onActivate`). Home and
/// End scroll to the first and last row. The list takes keyboard focus when it
/// appears and is its own scroll view: give it the whole area. The caller's
/// area draws the card fill behind it (the list's own background is hidden), so
/// nothing covers the system selection. The counterpart to `PVTable` (custom
/// chrome, columns).
struct PVList<Item: Identifiable, Thumbnail: View, Primary: View, Secondary: View>: View {
    private let items: [Item]
    private let thumbnail: (Item) -> Thumbnail
    private let thumbnailSize: CGFloat
    private let primary: (Item) -> Primary
    private let secondary: (Item) -> Secondary
    private let meta: (Item) -> String?
    private let detail: PVListDetailColumn<Item>?
    private let density: PVListDensity
    private let horizontalInset: CGFloat
    private let label: LocalizedStringResource
    private let itemAccessibilityLabel: (Item) -> String
    private let itemAccessibilityIdentifier: ((Item) -> String)?
    private let selection: Binding<Item.ID?>
    private let onActivate: (Item) -> Void

    /// The thumbnail slot is a view, so a row can load an image; the list frames
    /// it to `thumbnailSize`. `horizontalInset` is the rows' inset on both sides.
    init(
        items: [Item],
        selection: Binding<Item.ID?>,
        @ViewBuilder thumbnail: @escaping (Item) -> Thumbnail,
        thumbnailSize: CGFloat = 44,
        meta: @escaping (Item) -> String? = { _ in nil },
        detail: PVListDetailColumn<Item>? = nil,
        density: PVListDensity = .comfortable,
        horizontalInset: CGFloat? = nil,
        label: LocalizedStringResource,
        itemAccessibilityLabel: @escaping (Item) -> String,
        itemAccessibilityIdentifier: ((Item) -> String)? = nil,
        onActivate: @escaping (Item) -> Void,
        @ViewBuilder primary: @escaping (Item) -> Primary,
        @ViewBuilder secondary: @escaping (Item) -> Secondary
    ) {
        self.items = items
        self.selection = selection
        self.thumbnail = thumbnail
        self.thumbnailSize = thumbnailSize
        self.primary = primary
        self.secondary = secondary
        self.meta = meta
        self.detail = detail
        self.density = density
        self.horizontalInset = horizontalInset ?? density.horizontal
        self.label = label
        self.itemAccessibilityLabel = itemAccessibilityLabel
        self.itemAccessibilityIdentifier = itemAccessibilityIdentifier
        self.onActivate = onActivate
    }

    var body: some View {
        PVListBody(
            items: items,
            selection: selection,
            minimumRowHeight: thumbnailSize + 2 * density.vertical,
            horizontalInset: horizontalInset,
            label: label,
            onActivate: onActivate
        ) { item in
            PVListRow(
                item: item, leading: { _ in EmptyView() }, leadingWidth: 0,
                thumbnail: thumbnail, thumbnailSize: thumbnailSize,
                primary: primary, secondary: secondary, meta: meta,
                details: detail.map { [$0] } ?? [], density: density,
                accessibilityLabel: itemAccessibilityLabel,
                accessibilityIdentifier: itemAccessibilityIdentifier
            )
        }
    }
}

/// One row of a `PVList` or of another `PVListBody`: an optional leading slot, a thumbnail, the title
/// over the secondary line, detail columns and a trailing mono ref. A view of its own, so the list's
/// `ForEach` builds only this value and SwiftUI builds a row's content for the rows on screen. The row
/// modifiers (insets, separator tint) are on the `ForEach`, not here and not in its closure, so a
/// selection move runs none of them for rows off screen. The row pads itself `density.vertical` top and
/// bottom, so it owns its height. With a leading slot the thumbnail sits `PVListMetrics.hang` in from
/// the row's leading edge, which the body's smaller leading inset puts back on the gutter. A nil
/// `accessibilityLabel` leaves the row's accessibility to its caller.
struct PVListRow<Item: Identifiable, Leading: View, Thumbnail: View, Primary: View, Secondary: View>: View {
    let item: Item
    let leading: (Item) -> Leading
    /// Width of the leading slot; 0 for none.
    let leadingWidth: CGFloat
    let thumbnail: (Item) -> Thumbnail
    let thumbnailSize: CGFloat
    let primary: (Item) -> Primary
    let secondary: (Item) -> Secondary
    let meta: (Item) -> String?
    let details: [PVListDetailColumn<Item>]
    var density: PVListDensity = .comfortable
    let accessibilityLabel: ((Item) -> String)?
    let accessibilityIdentifier: ((Item) -> String)?

    var body: some View {
        HStack(spacing: PVSpacing.space6) {
            thumbnailGroup
            VStack(alignment: .leading, spacing: 3) {
                primary(item)
                    .font(PVListText.titleFont)
                    .foregroundStyle(PVColor.onSelection(PVColor.textPrimary))
                    .lineLimit(1)
                    .truncationMode(.tail)
                secondary(item)
                    .font(PVFont.body(size: PVTypeScale.caption))
                    .foregroundStyle(PVColor.onSelection(PVColor.textMuted))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(Array(details.enumerated()), id: \.offset) { _, detail in
                PVListDetailCell(detail: detail.content(item), width: detail.width)
            }
            if let meta = meta(item) {
                Text(verbatim: meta)
                    .font(PVFont.mono(size: PVTypeScale.micro))
                    .foregroundStyle(PVColor.onSelection(PVColor.textMuted))
                    .lineLimit(1)
                    .fixedSize()
                    .layoutPriority(1)
            }
        }
        .frame(height: thumbnailSize)
        .padding(.vertical, density.vertical)
        .alignmentGuide(.listRowSeparatorLeading) { [hang = PVListMetrics.hang(leadingWidth: leadingWidth)] _ in hang }
        .alignmentGuide(.listRowSeparatorTrailing) { $0.width }
        .modifier(PVListRowAccessibility(item: item, label: accessibilityLabel, identifier: accessibilityIdentifier))
    }

    /// The thumbnail, after the leading slot when there is one. The slot lays out at the thumbnail's
    /// height but its hit area runs the row's full height.
    @ViewBuilder
    private var thumbnailGroup: some View {
        if leadingWidth > 0 {
            HStack(spacing: PVSpacing.space2) {
                leading(item)
                    .frame(width: leadingWidth, height: thumbnailSize + 2 * density.vertical)
                    .contentShape(Rectangle())
                    .padding(.vertical, -density.vertical)
                thumbnail(item)
                    .frame(width: thumbnailSize, height: thumbnailSize)
            }
        } else {
            thumbnail(item)
                .frame(width: thumbnailSize, height: thumbnailSize)
        }
    }
}

/// A row's accessibility element, label and identifier, when its caller gives a label.
private struct PVListRowAccessibility<Item>: ViewModifier {
    let item: Item
    let label: ((Item) -> String)?
    let identifier: ((Item) -> String)?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let label {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: label(item)))
                .accessibilityIdentifier(identifier?(item) ?? "")
        } else {
            content
        }
    }
}

/// One cell of a `PVList` detail column. `help` is hover text; `nil` attaches none.
struct PVListDetail {
    var text: String
    var help: String?
    var icon: PVSymbol?
    var faint: Bool = false
}

/// One cell of a `PVList` detail column, framed to its column width. A `nil`
/// detail leaves the cell empty at the same width. A `nil` width hugs the
/// content; a width truncates the text with a tail ellipsis. `PVListRow` draws one
/// per detail column.
struct PVListDetailCell: View {
    let detail: PVListDetail?
    let width: CGFloat?

    var body: some View {
        content
            .frame(width: width, alignment: .leading)
            .layoutPriority(1)
    }

    @ViewBuilder
    private func text(_ string: String) -> some View {
        let text = Text(verbatim: string)
            .font(PVFont.body(size: PVTypeScale.caption))
            .lineLimit(1)
        if width != nil {
            text.truncationMode(.tail)
        } else {
            text.fixedSize()
        }
    }

    @ViewBuilder
    private var content: some View {
        if let detail {
            let color = PVColor.onSelection(detail.faint ? PVColor.textFaint : PVColor.textMuted)
            let cell = HStack(spacing: 6) {
                if let icon = detail.icon {
                    PVIcon(icon, size: 14)
                }
                text(detail.text)
            }
            .foregroundStyle(color)
            if let help = detail.help {
                cell.help(help)
            } else {
                cell
            }
        } else {
            Color.clear
        }
    }
}

/// A fixed-width column before the ref. `content` returning `nil` leaves the
/// cell empty at the same width.
struct PVListDetailColumn<Item> {
    var width: CGFloat
    var content: (Item) -> PVListDetail?
}

/// Row padding: comfortable 11 / 16, compact 7 / 12 (the kit's `PAD`).
enum PVListDensity: Sendable {
    case comfortable
    case compact

    var vertical: CGFloat { self == .comfortable ? 11 : 7 }
    var horizontal: CGFloat { self == .comfortable ? PVSpacing.space6 : PVSpacing.space5 }
}

/// What a key does to the list — pure, so it is testable without a view.
enum PVListKeyAction: Equatable {
    case move(to: Int)
    case activate(Int)
    case ignore
}

enum PVListKeyboard {
    static let pageStep = 10

    /// The one list of movement keys: ↑/↓ (⌥ to an end), Home, End, Page Up and
    /// Page Down. Nil for any other key; otherwise the shared mover's index
    /// (-1 when `count` is 0).
    static func moveIndex(
        for key: KeyEquivalent,
        option: Bool,
        index: Int,
        count: Int,
        isDisabled: (Int) -> Bool = { _ in false },
        pageStep: Int = PVListKeyboard.pageStep
    ) -> Int? {
        func move(_ delta: Int, edge: PVFloatingMenuSelection.Edge? = nil) -> Int {
            PVFloatingMenuSelection.moveIndex(
                from: index, delta: delta, count: count, edge: edge, isDisabled: isDisabled
            )
        }
        switch key {
        case .downArrow:
            return option ? move(-1, edge: .last) : move(1)
        case .upArrow:
            return option ? move(1, edge: .first) : move(-1)
        case .home:
            return move(1, edge: .first)
        case .end:
            return move(-1, edge: .last)
        case .pageDown:
            return move(pageStep)
        case .pageUp:
            return move(-pageStep)
        default:
            return nil
        }
    }

    static func action(
        for key: KeyEquivalent,
        option: Bool,
        index: Int,
        count: Int,
        isDisabled: (Int) -> Bool = { _ in false }
    ) -> PVListKeyAction {
        guard count > 0 else { return .ignore }
        if let next = moveIndex(for: key, option: option, index: index, count: count, isDisabled: isDisabled) {
            return .move(to: next)
        }
        switch key {
        case .return, .space:
            return .activate(min(max(index, 0), count - 1))
        default:
            return .ignore
        }
    }
}

/// First-load placeholder in row geometry: static rule bars, a loading tile,
/// no spinner, inert. Pair it with no count in the section header.
struct PVListSkeleton: View {
    var rows: Int = 5
    var thumbnailSize: CGFloat = 44
    var density: PVListDensity = .comfortable
    /// Widths of the list's detail columns; draws a bar in each before the ref bar.
    var detailWidths: [CGFloat] = []
    /// The rows' inset on both sides, and the separators'; the density's when nil.
    var horizontalInset: CGFloat?

    private static let titleWidths: [CGFloat] = [0.46, 0.32, 0.54, 0.38, 0.42]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0 ..< rows, id: \.self) { index in
                HStack(spacing: PVSpacing.space6) {
                    PVThumbnail(PVThumbnail.Content(loading: true), size: thumbnailSize)
                    GeometryReader { geometry in
                        VStack(alignment: .leading, spacing: PVSpacing.space3) {
                            PVSkeletonBar(width: geometry.size.width * Self.titleWidths[index % Self.titleWidths.count], height: 12)
                            PVSkeletonBar(width: geometry.size.width * 0.62, height: 10)
                        }
                        .frame(maxHeight: .infinity, alignment: .center)
                    }
                    ForEach(Array(detailWidths.enumerated()), id: \.offset) { _, detailWidth in
                        PVSkeletonBar(width: min(64, detailWidth), height: 10)
                            .frame(width: detailWidth, alignment: .leading)
                    }
                    PVSkeletonBar(width: 72, height: 10)
                }
                .frame(height: thumbnailSize)
                .padding(.vertical, density.vertical)
                .padding(.horizontal, horizontalInset ?? density.horizontal)
                .overlay(alignment: .bottom) {
                    if index < rows - 1 {
                        PVDivider().padding(.horizontal, horizontalInset ?? density.horizontal)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(L10n.DesignSystem.listLoading))
    }
}

private struct PVListPreview: View {
    struct Row: Identifiable {
        let id: String
        let title: String
        let subtitle: String?
        let detail: PVListDetail?
    }

    let rows = [
        Row(id: "PER-7KD45", title: "James Robins", subtitle: "b. 14 May 1817",
            detail: PVListDetail(text: "Yesterday", help: "Last updated", icon: .history)),
        Row(id: "PER-2HT08", title: "Eliza Robins", subtitle: nil,
            detail: PVListDetail(text: "—", help: nil, icon: .history, faint: true)),
        Row(id: "PER-9ZZ02", title: "PER-9ZZ02", subtitle: nil, detail: nil),
    ]
    @State private var selection: String?

    var body: some View {
        PVList(
            items: rows,
            selection: $selection,
            thumbnail: { _ in PVThumbnail(PVThumbnail.Content(glyph: .mark(.subjectPerson))) },
            meta: { $0.id },
            detail: PVListDetailColumn(width: 136, content: { $0.detail }),
            label: L10n.Workspace.personsTitle,
            itemAccessibilityLabel: { "\($0.title), \($0.id)" },
            onActivate: { _ in },
            primary: { Text(verbatim: $0.title) },
            secondary: { row in
                if let subtitle = row.subtitle { Text(verbatim: subtitle) }
            }
        )
        .background(PVColor.surfaceCard)
    }
}

#Preview {
    VStack(spacing: PVSpacing.space8) {
        PVListPreview().frame(height: 220)
        PVListSkeleton(rows: 3, detailWidths: [136])
    }
    .padding(PVSpacing.space9)
    .frame(width: 640)
    .background(PVColor.surfacePage)
}

#Preview("Selected row ink") {
    HStack(spacing: PVSpacing.space6) {
        PVThumbnail(PVThumbnail.Content(glyph: .mark(.subjectPerson)), size: 44)
        VStack(alignment: .leading, spacing: 3) {
            PVTitleText(.name("Josephine Marchand"), extraCount: 2)
                .font(PVListText.titleFont)
                .foregroundStyle(PVColor.onSelection(PVColor.textPrimary))
            PVDatePlaceLine(date: "1851", place: "Lyon, France", accessibilityLabel: "", extraCount: 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        PVListDetailCell(
            detail: PVListDetail(text: "Yesterday", help: nil, icon: .history), width: 136
        )
        Text(verbatim: "PER-7K2QX")
            .font(PVFont.mono(size: PVTypeScale.micro))
            .foregroundStyle(PVColor.onSelection(PVColor.textMuted))
    }
    .padding(.horizontal, PVSpacing.space6)
    .padding(.vertical, 11)
    .background(Color.accentColor)
    .environment(\.backgroundProminence, .increased)
    .frame(width: 640)
}
