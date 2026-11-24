import SwiftUI

/// A Source's row in the Sources list: the Persons row's geometry (a 44 pt cover, the title over a
/// secondary line, the updated column, the mono ref) with the disclosure triangle in a leading slot on
/// the gutter. The row is one accessibility element; the triangle's toggle is its action.
struct SourcesSourceRow: View {
    @Environment(WorkspaceSession.self) private var session
    let source: CatalogSource
    let disclosure: SourcesDisclosure
    let model: SourcesModel
    let isWide: Bool
    /// Opens or closes the Source, or every Source when `all` (⌥-click).
    let toggle: (_ all: Bool) -> Void

    static let coverSize: CGFloat = 44
    static let triangleWidth: CGFloat = 16

    var body: some View {
        let typeLabel = model.typeLabel(for: source)
        let summary = tail
        PVListRow(
            item: source,
            leading: { source in
                SourcesDisclosureTriangle(sourceID: source.id, disclosure: disclosure, toggle: toggle)
            },
            leadingWidth: Self.triangleWidth,
            thumbnail: { source in
                CachedThumbnail(
                    projectDir: model.pageProjectDir,
                    relPath: source.thumbnailRelPath,
                    typeIconKey: model.typeIconKey(for: source),
                    size: Self.coverSize
                )
            },
            thumbnailSize: Self.coverSize,
            primary: { Text(verbatim: $0.title) },
            secondary: { source in
                SourcesSecondaryLine(parts: SourcesOutline.secondaryParts(
                    type: typeLabel, date: source.date, tail: summary, isWide: isWide
                ))
            },
            meta: { $0.ref },
            details: SourcesRowColumns.details(isWide: isWide, typeLabel: { model.typeLabel(for: $0) }),
            accessibilityLabel: nil,
            accessibilityIdentifier: nil
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: spokenLabel(typeLabel: typeLabel, tail: summary)))
        .accessibilityIdentifier("sources.row.\(source.id)")
        .modifier(SourcesExpandedState(disclosure: disclosure, toggle: { toggle(false) }))
    }

    /// The end of the secondary line: `Needs an artifact`, or a closed Source's summary of its graphs.
    private var tail: String? {
        if !source.hasArtifact { return L10n.string(L10n.Sources.needsArtifact) }
        guard disclosure == .collapsed, case .loaded(let graphs) = session.evidenceGraphsRead(sourceID: source.id)
        else { return nil }
        let loading = session.evidenceGraphCountsLoading
        let error = session.evidenceGraphCountsError
        return SourcesGraphSummary.text(graphs.map {
            SourcesGraphCounts(
                progress: session.evidenceGraphProgress(graphID: $0.id), countsLoading: loading, countsError: error
            )
        })
    }

    private func spokenLabel(typeLabel: String, tail: String?) -> String {
        let row = SourceDateText.spokenRow(
            title: source.title, type: typeLabel, ref: source.ref, date: source.date
        )
        return PVLastUpdated.label(
            L10n.DesignSystem.spokenJoin([row, tail ?? ""]) ?? row, updatedAt: source.updated.at, in: .current
        )
    }
}

/// A Source row's expanded state and its Show / Hide action, for a row with a triangle.
private struct SourcesExpandedState: ViewModifier {
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
/// open, its target the slot by the row's height. ⌥ opens or closes every Source. Not animated.
private struct SourcesDisclosureTriangle: View {
    let sourceID: String
    let disclosure: SourcesDisclosure
    let toggle: (_ all: Bool) -> Void

    var body: some View {
        if disclosure == .none {
            Color.clear
        } else {
            Button {
                toggle(NSEvent.modifierFlags.contains(.option))
            } label: {
                PVIcon(PVExpandedState.outlineChevron(isExpanded: disclosure == .expanded), size: 12)
                    .foregroundStyle(PVColor.onSelection(PVColor.textMuted))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable(false)
            .accessibilityIdentifier("sources.row.\(sourceID).disclosure")
        }
    }
}

/// A Source row's secondary line: its parts with a dot between neighbours. The type truncates first;
/// the date and the tail never do.
private struct SourcesSecondaryLine: View {
    let parts: [SourcesSecondaryPart]

    var body: some View {
        if !parts.isEmpty {
            HStack(spacing: PVSpacing.space3) {
                ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                    if index > 0 {
                        Text(verbatim: "·")
                            .foregroundStyle(PVColor.onSelection(PVColor.textFaint))
                            .fixedSize()
                            .accessibilityHidden(true)
                    }
                    switch part {
                    case .type(let type):
                        Text(verbatim: type)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .layoutPriority(0)
                            .help(type)
                    case .date(let date):
                        PVPublishedDate(date: date)
                            .fixedSize()
                            .layoutPriority(1)
                    case .tail(let tail):
                        Text(verbatim: tail)
                            .fixedSize()
                            .layoutPriority(2)
                    }
                }
            }
        }
    }
}

/// An Evidence graph under an open Source: its glyph under the Source's title, its name, its counts and
/// its status badge in columns shared by every graph row, or the placeholder of a graph list that has
/// not reached a new Source. One thin line, no button, no border, no hover: the list selects and opens it.
struct SourcesGraphRow: View {
    enum Content {
        case graph(CatalogEvidenceGraph)
        case pending
    }

    @Environment(WorkspaceSession.self) private var session
    let content: Content
    let source: CatalogSource

    static let height: CGFloat = 34
    /// The line's width from the title edge, so the counts and the badge stay beside the name at Wide.
    static let maxContentWidth: CGFloat = 760
    static let countsSlotWidth: CGFloat = 210
    /// The status column, so the badges share a right edge down the list.
    static let statusSlotWidth: CGFloat = 112

    var body: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: PVListMetrics.titleLeading(
                leadingWidth: SourcesSourceRow.triangleWidth, thumbnailSize: SourcesSourceRow.coverSize
            ))
            line
                .frame(maxWidth: Self.maxContentWidth, alignment: .leading)
            Spacer(minLength: 0)
        }
        .frame(height: Self.height)
        .alignmentGuide(.listRowSeparatorLeading) { [hang = PVListMetrics.hang(leadingWidth: SourcesSourceRow.triangleWidth)] _ in hang }
        .alignmentGuide(.listRowSeparatorTrailing) { $0.width }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: spokenLabel))
        .accessibilityHint(Text(verbatim: hint))
        .accessibilityIdentifier(identifier)
    }

    @ViewBuilder
    private var line: some View {
        switch content {
        case .pending:
            HStack(spacing: 10) {
                PVIcon(.network, size: 14)
                    .foregroundStyle(PVColor.onSelection(PVColor.textFaint))
                    .frame(width: 16)
                PVSkeletonBar(width: 72, height: 6)
                Spacer(minLength: 0)
            }
        case .graph(let graph):
            let counts = self.counts(for: graph)
            let opens = graph.hasArtifact
            HStack(spacing: 10) {
                PVIcon(.network, size: 14)
                    .foregroundStyle(PVColor.onSelection(opens ? PVColor.textMuted : PVColor.textFaint))
                    .frame(width: 16)
                Text(verbatim: graph.name)
                    .font(PVFont.body(size: PVTypeScale.bodySmall))
                    .foregroundStyle(PVColor.onSelection(opens ? PVColor.textPrimary : PVColor.textFaint))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ZStack(alignment: .leading) {
                    Color.clear
                    if opens {
                        SourcesGraphCountLine(counts: counts, style: .row)
                    } else {
                        Text(L10n.Sources.graphNeedsArtifactToOpen)
                            .font(PVFont.body(size: PVTypeScale.micro))
                            .italic()
                            .foregroundStyle(PVColor.onSelection(PVColor.textMuted))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .frame(width: Self.countsSlotWidth)
                statusSlot(counts: counts, opens: opens)
            }
            .help(opens ? "" : L10n.string(L10n.Sources.graphNeedsArtifactTooltip))
        }
    }

    /// The graph's status badge, a rule while its counts load, or nothing. Held at its width either way.
    private func statusSlot(counts: SourcesGraphCounts, opens: Bool) -> some View {
        ZStack(alignment: .trailing) {
            Color.clear
            if opens, let status = counts.status {
                status.badge
            } else if opens, counts == .loading {
                PVSkeletonBar(width: 72, height: 6)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: Self.statusSlotWidth)
    }

    private func counts(for graph: CatalogEvidenceGraph) -> SourcesGraphCounts {
        SourcesGraphCounts(
            progress: session.evidenceGraphProgress(graphID: graph.id),
            countsLoading: session.evidenceGraphCountsLoading,
            countsError: session.evidenceGraphCountsError
        )
    }

    private var spokenLabel: String {
        switch content {
        case .pending:
            return L10n.string(L10n.Sources.graphsLoading)
        case .graph(let graph):
            guard graph.hasArtifact else { return graph.name }
            let counts = self.counts(for: graph)
            return L10n.Sources.graphRowLabel(
                name: graph.name,
                counts: L10n.Sources.graphCounts(counts, style: .spoken, notStarted: .zeroCounts),
                status: counts.status.map { L10n.string($0.label) }
            )
        }
    }

    private var hint: String {
        if case .graph(let graph) = content, !graph.hasArtifact {
            return L10n.string(L10n.Sources.graphNeedsArtifactTooltip)
        }
        return ""
    }

    private var identifier: String {
        switch content {
        case .pending: "sources.row.\(source.id).graphsPending"
        case .graph(let graph): "sources.row.\(source.id).graph.\(graph.ref)"
        }
    }
}
