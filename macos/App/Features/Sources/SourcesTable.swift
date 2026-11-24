import SwiftUI

/// One row of the Sources table: a row of the outline, or one of the skeleton rows the first load draws
/// under the header.
enum SourcesTableItem: Identifiable, Equatable {
    case row(SourcesOutlineRow)
    case skeleton(Int)

    /// Rows of skeleton that fill the table's area.
    static let skeletonCount = 30

    var id: String {
        switch self {
        case .row(let row): row.id
        case .skeleton(let index): "skeleton-\(index)"
        }
    }

    static var skeletons: [SourcesTableItem] { (0 ..< skeletonCount).map(SourcesTableItem.skeleton) }
}

/// The table's headers report a click as a sort: the model sorts, and the comparator never reorders rows,
/// so a Source's graphs stay under it.
extension SourcesSort: SortComparator {
    typealias Compared = SourcesTableItem

    func compare(_ lhs: SourcesTableItem, _ rhs: SourcesTableItem) -> ComparisonResult { .orderedSame }
}

/// The widths of the Sources table's columns. Every column but Title is fixed at one width a width class
/// has; Title takes the rest, up to what is left of the table. Pure, so a test reads the board's numbers.
///
/// The five platform numbers below were measured offscreen on macOS 27.2 (the probe in the S16-71 plan): a
/// native table puts 17 pt between columns, 18 pt before the first header's text, 8 pt of cell padding
/// above and below a row's content, and 49 pt of its own insets and a legacy scroller around the columns.
struct SourcesTableWidths: Equatable {
    static let columnGap: CGFloat = 17
    static let headerInset: CGFloat = 18
    static let cellPadding: CGFloat = 8
    static let tableInsets: CGFloat = 49
    static let titleMinimum: CGFloat = 240

    let evidence: CGFloat
    let status: CGFloat
    let type: CGFloat
    let published: CGFloat
    let added: CGFloat
    let updated: CGFloat
    /// The widest Title may grow: the table's width less the other columns, their gaps and the table's
    /// insets, never under `titleMinimum` (a narrow pane scrolls sideways).
    let titleMaximum: CGFloat

    /// `tableWidth` is the table's own width, inside the page's padding (`SourcesTable`). Type shows at
    /// Wide only.
    init(isWide: Bool, tableWidth: CGFloat) {
        let widths: [CGFloat] = isWide ? [240, 140, 220, 160, 120, 120] : [168, 128, 220, 96, 92, 92]
        evidence = widths[0]
        status = widths[1]
        type = widths[2]
        published = widths[3]
        added = widths[4]
        updated = widths[5]
        let shown = isWide ? widths : widths.enumerated().filter { $0.offset != 2 }.map(\.element)
        let others = shown.reduce(0, +) + Self.columnGap * CGFloat(shown.count) + Self.tableInsets
        titleMaximum = max(Self.titleMinimum, tableWidth - others)
    }
}

/// The Sources list's rows as the platform's table: named columns, headers that sort, the outline's rows
/// (a Source, and under the open one its graphs) in them. It draws what it is given: the page owns the
/// selection and applies the kit's native list behavior around it (`pvNativeListBehavior`). Loading draws
/// the same table with skeleton rows, inert.
///
/// The widths are fixed, not the platform's to resize: no drag, reorder or hide (`SourcesTableWidths`).
/// Title's cell is the row's one accessibility element: its other cells read their text under their
/// column's name.
struct SourcesTable: View {
    @Environment(WorkspaceSession.self) private var session

    let items: [SourcesTableItem]
    let selection: Binding<String?>
    let model: SourcesModel
    let isWide: Bool
    let gutter: CGFloat
    /// Opens a closed Source, or closes the open one: the triangle's action.
    let toggle: (CatalogSource, SourcesDisclosure) -> Void
    /// Notes whether the pointer is on a Source's triangle (the page reads it when a click selects).
    let hoverTriangle: (_ sourceID: String, _ inside: Bool) -> Void
    /// Skeleton rows: inert, and out of the accessibility tree.
    let isLoading: Bool

    @State private var columns: TableColumnCustomization<SourcesTableItem>

    static let sourceRowHeight: CGFloat = 58
    static let graphRowHeight: CGFloat = 26
    static let triangleWidth: CGFloat = 16
    static let coverSize: CGFloat = 44
    /// The Title cell's leading edge to a Source's title: the triangle slot, a gap, the cover, a gap.
    static let titleIndent: CGFloat = triangleWidth + PVSpacing.space2 + coverSize + PVSpacing.space5

    init(
        items: [SourcesTableItem],
        selection: Binding<String?>,
        model: SourcesModel,
        isWide: Bool,
        gutter: CGFloat,
        toggle: @escaping (CatalogSource, SourcesDisclosure) -> Void = { _, _ in },
        hoverTriangle: @escaping (String, Bool) -> Void = { _, _ in },
        isLoading: Bool = false
    ) {
        self.items = items
        self.selection = selection
        self.model = model
        self.isWide = isWide
        self.gutter = gutter
        self.toggle = toggle
        self.hoverTriangle = hoverTriangle
        self.isLoading = isLoading
        // The hidden column's width stays out of the first layout when the state starts right.
        var columns = TableColumnCustomization<SourcesTableItem>()
        columns[visibility: "type"] = isWide ? .visible : .hidden
        _columns = State(initialValue: columns)
    }

    var body: some View {
        GeometryReader { proxy in
            table(SourcesTableWidths(isWide: isWide, tableWidth: proxy.size.width))
        }
        // The inset table draws its first column 18 pt in: its first header's text lands on the gutter.
        .padding(.horizontal, gutter - SourcesTableWidths.headerInset)
    }

    /// The page's sort as the table's header order, and a header click as the page's sort.
    private var sortOrder: Binding<[SourcesSort]> {
        Binding(
            get: { [model.settings.sort] },
            set: { order in
                guard !isLoading else { return }
                model.settings.sort = Self.sort(from: order, current: model.settings.sort)
            }
        )
    }

    private func table(_ widths: SourcesTableWidths) -> some View {
        Table(of: SourcesTableItem.self, selection: selection, sortOrder: sortOrder, columnCustomization: $columns) {
            TableColumn(
                header(L10n.Sources.columnTitle, sorted: .title), sortUsing: sort(.title)
            ) { (item: SourcesTableItem) in
                titleCell(item)
            }
            .width(min: SourcesTableWidths.titleMinimum, ideal: SourcesTableWidths.titleMinimum, max: widths.titleMaximum)
            .customizationID("title")
            .disabledCustomizationBehavior(.all)

            TableColumn(header(L10n.Sources.columnEvidence, sorted: nil)) { (item: SourcesTableItem) in
                evidenceCell(item)
            }
            .width(widths.evidence)
            .customizationID("evidence")
            .disabledCustomizationBehavior(.all)

            TableColumn(header(L10n.Sources.columnStatus, sorted: nil)) { (item: SourcesTableItem) in
                statusCell(item)
            }
            .width(widths.status)
            .customizationID("status")
            .disabledCustomizationBehavior(.all)

            TableColumn(header(L10n.Sources.columnType, sorted: nil)) { (item: SourcesTableItem) in
                typeCell(item)
            }
            .width(widths.type)
            .customizationID("type")
            .disabledCustomizationBehavior(.all)

            TableColumn(
                header(L10n.Sources.columnPublished, sorted: .published), sortUsing: sort(.published)
            ) { (item: SourcesTableItem) in
                publishedCell(item)
            }
            .width(widths.published)
            .customizationID("published")
            .disabledCustomizationBehavior(.all)

            TableColumn(
                header(L10n.Sources.columnAdded, sorted: .added), sortUsing: sort(.added)
            ) { (item: SourcesTableItem) in
                addedCell(item)
            }
            .width(widths.added)
            .customizationID("added")
            .disabledCustomizationBehavior(.all)

            TableColumn(
                header(L10n.Sources.columnUpdated, sorted: .updated), sortUsing: sort(.updated)
            ) { (item: SourcesTableItem) in
                updatedCell(item)
            }
            .width(widths.updated)
            .customizationID("updated")
            .disabledCustomizationBehavior(.all)
        } rows: {
            ForEach(items) { TableRow($0) }
        }
        .tableStyle(.inset(alternatesRowBackgrounds: false))
        .scrollContentBackground(.hidden)
        .transaction { $0.animation = nil }
        .onChange(of: isWide) { _, wide in
            columns[visibility: "type"] = wide ? .visible : .hidden
        }
        .scrollDisabled(isLoading)
        .allowsHitTesting(!isLoading)
        .accessibilityHidden(isLoading)
    }

    // MARK: Headers

    /// The sort a header click leaves: the first of the order the table reports, or the current one when it
    /// reports none.
    static func sort(from order: [SourcesSort], current: SourcesSort) -> SourcesSort {
        order.first ?? current
    }

    private func sort(_ column: SourcesSort.Column) -> SourcesSort {
        SourcesSort(column: column, order: column.firstOrder)
    }

    /// The column's title in the kit's micro caps, one step brighter on the sorted column.
    private func header(_ title: LocalizedStringResource, sorted column: SourcesSort.Column?) -> Text {
        let isSorted = column != nil && column == model.settings.sort.column
        return PVMicroCaps.text(title).foregroundStyle(isSorted ? PVColor.textSecondary : PVColor.textMuted)
    }

    // MARK: Cells

    private func caption(_ string: String, ink: Color = PVColor.textSecondary) -> some View {
        Text(verbatim: string)
            .font(PVFont.body(size: PVTypeScale.caption))
            .foregroundStyle(PVColor.onSelection(ink))
            .lineLimit(1)
            .truncationMode(.tail)
    }

    private func skeleton(_ width: CGFloat, height: CGFloat = 6) -> some View {
        PVSkeletonBar(width: width, height: height)
    }

    @ViewBuilder
    private func titleCell(_ item: SourcesTableItem) -> some View {
        switch item {
        case .skeleton:
            HStack(spacing: 0) {
                Color.clear.frame(width: Self.triangleWidth + PVSpacing.space2)
                PVThumbnail(PVThumbnail.Content(loading: true), size: Self.coverSize)
                VStack(alignment: .leading, spacing: PVSpacing.space3) {
                    skeleton(240, height: 8)
                    skeleton(140)
                }
                .padding(.leading, PVSpacing.space5)
            }
            .frame(height: Self.sourceRowHeight)
        case .row(let row):
            switch row.kind {
            case .source(let source, let disclosure):
                sourceTitle(source, disclosure: disclosure)
            case .graph(let graph, let source):
                graphTitle(graph, source: source)
            case .pendingGraph(let source):
                graphLine(opens: false) { skeleton(72) }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(L10n.Sources.graphsLoading))
                    .accessibilityIdentifier("sources.row.\(source.id).graphsPending")
            }
        }
    }

    private func sourceTitle(_ source: CatalogSource, disclosure: SourcesDisclosure) -> some View {
        let typeLabel = model.typeLabel(for: source)
        return HStack(spacing: 0) {
            SourcesDisclosureTriangle(
                sourceID: source.id, disclosure: disclosure,
                toggle: { toggle(source, disclosure) }, hover: hoverTriangle
            )
            .frame(width: Self.triangleWidth)
            CachedThumbnail(
                projectDir: model.pageProjectDir,
                relPath: source.thumbnailRelPath,
                typeIconKey: model.typeIconKey(for: source),
                size: Self.coverSize
            )
            .padding(.leading, PVSpacing.space2)
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: source.title)
                    .font(PVListText.titleFont)
                    .foregroundStyle(PVColor.onSelection(PVColor.textPrimary))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .help(source.title)
                HStack(spacing: PVSpacing.space2) {
                    Text(verbatim: source.ref)
                        .font(PVFont.mono(size: PVTypeScale.micro))
                        .foregroundStyle(PVColor.onSelection(PVColor.textMuted))
                        .lineLimit(1)
                        .fixedSize()
                        .layoutPriority(1)
                    if !isWide, !typeLabel.isEmpty {
                        Text(verbatim: "·")
                            .foregroundStyle(PVColor.onSelection(PVColor.textFaint))
                            .fixedSize()
                        caption(typeLabel, ink: PVColor.textMuted).help(typeLabel)
                    }
                }
            }
            .padding(.leading, PVSpacing.space5)
        }
        .frame(height: Self.sourceRowHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: L10n.DesignSystem.spokenJoin([source.title, source.ref, typeLabel]) ?? source.title))
        .accessibilityIdentifier("sources.row.\(source.id)")
        .modifier(SourcesExpandedState(disclosure: disclosure, toggle: { toggle(source, disclosure) }))
    }

    private func graphTitle(_ graph: CatalogEvidenceGraph, source: CatalogSource) -> some View {
        let reason = SourcesListNavigation.graphBlockedReason(for: graph)
        let opens = reason == nil
        let hint = reason ?? ""
        return graphLine(opens: opens) {
            Text(verbatim: graph.name)
                .font(PVFont.body(size: PVTypeScale.bodySmall))
                .foregroundStyle(PVColor.onSelection(opens ? PVColor.textPrimary : PVColor.textFaint))
                .lineLimit(1)
                .truncationMode(.tail)
                .help(graph.name)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: graph.name))
        .accessibilityHint(Text(verbatim: hint))
        .accessibilityIdentifier("sources.row.\(source.id).graph.\(graph.ref)")
    }

    /// A graph's line in the Title cell: the glyph and its label under the Source's title.
    private func graphLine(opens: Bool, @ViewBuilder _ label: () -> some View) -> some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: Self.titleIndent, height: 1)
            PVIcon(.network, size: 14)
                .foregroundStyle(PVColor.onSelection(opens ? PVColor.textMuted : PVColor.textFaint))
                .padding(.trailing, 10)
            label()
        }
        .frame(height: Self.graphRowHeight)
    }

    @ViewBuilder
    private func evidenceCell(_ item: SourcesTableItem) -> some View {
        switch item {
        case .skeleton:
            skeleton(56)
        case .row(let row):
            switch row.kind {
            case .source(let source, _):
                if !source.hasArtifact {
                    Text(L10n.Sources.needsArtifact)
                        .font(PVFont.body(size: PVTypeScale.caption))
                        .italic()
                        .foregroundStyle(PVColor.onSelection(PVColor.textMuted))
                        .lineLimit(1)
                } else {
                    switch session.evidenceGraphsRead(sourceID: source.id) {
                    case .loaded(let graphs): caption(L10n.Sources.graphSummaryCount(graphs.count))
                    case .failed: caption("—", ink: PVColor.textFaint)
                    case .loading: EmptyView()
                    }
                }
            case .graph(let graph, _):
                if let reason = SourcesListNavigation.graphBlockedReason(for: graph) {
                    Text(L10n.Sources.graphNeedsArtifactToOpen)
                        .font(PVFont.body(size: PVTypeScale.micro))
                        .italic()
                        .foregroundStyle(PVColor.onSelection(PVColor.textMuted))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .help(reason)
                } else {
                    SourcesGraphCountLine(counts: session.graphCounts(graphID: graph.id), style: .row)
                }
            case .pendingGraph:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func statusCell(_ item: SourcesTableItem) -> some View {
        switch item {
        case .skeleton:
            skeleton(72)
        case .row(let row):
            switch row.kind {
            case .source(let source, _):
                if let status = model.status(for: source) { badge(status) }
            case .graph(let graph, _):
                if SourcesListNavigation.graphBlockedReason(for: graph) == nil {
                    let counts = session.graphCounts(graphID: graph.id)
                    if let status = counts.status {
                        badge(status)
                    } else if counts == .loading {
                        skeleton(72).accessibilityHidden(true)
                    }
                }
            case .pendingGraph:
                EmptyView()
            }
        }
    }

    /// The status badge, read as the status words: the badge itself is hidden from VoiceOver.
    private func badge(_ status: SourcesModel.EvidenceStatus) -> some View {
        HStack(spacing: 0) { status.badge }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(status.label))
    }

    @ViewBuilder
    private func typeCell(_ item: SourcesTableItem) -> some View {
        switch item {
        case .skeleton:
            skeleton(80)
        case .row(let row):
            if case .source(let source, _) = row.kind {
                let label = model.typeLabel(for: source)
                caption(label).help(label)
            }
        }
    }

    @ViewBuilder
    private func publishedCell(_ item: SourcesTableItem) -> some View {
        switch item {
        case .skeleton:
            skeleton(40)
        case .row(let row):
            if case .source(let source, _) = row.kind { PVPublishedDate(date: source.date) }
        }
    }

    @ViewBuilder
    private func addedCell(_ item: SourcesTableItem) -> some View {
        switch item {
        case .skeleton:
            skeleton(60)
        case .row(let row):
            if case .source(let source, _) = row.kind {
                PVListDetailCell(
                    detail: PVListDetail.relative(source.createdAt, in: .current, help: L10n.Sources.addedHelp(stamp:)),
                    width: nil
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: Self.addedSpoken(source.createdAt)))
            }
        }
    }

    /// How VoiceOver reads the Added cell: `added Yesterday`, or that the date is unknown.
    static func addedSpoken(_ createdAt: String, in context: TimestampFormat.Context = .current) -> String {
        TimestampFormat.string(createdAt, .spoken, in: context).map(L10n.Sources.addedSpoken)
            ?? L10n.Sources.addedUnknown
    }

    @ViewBuilder
    private func updatedCell(_ item: SourcesTableItem) -> some View {
        switch item {
        case .skeleton:
            skeleton(60)
        case .row(let row):
            if case .source(let source, _) = row.kind {
                PVListDetailCell(
                    detail: PVListDetail.relative(source.updated.at, in: .current, help: L10n.LastUpdated.help(stamp:)),
                    width: nil
                )
            }
        }
    }
}
