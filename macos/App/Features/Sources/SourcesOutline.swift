import SwiftUI

/// Whether a Source row has a triangle, and which way it points.
enum SourcesDisclosure: Equatable {
    /// No triangle: no Artifact, or its graph list failed.
    case none
    case collapsed
    case expanded
}

/// One row of the Sources list: a Source, an Evidence graph under an open Source, or the placeholder
/// of an open Source whose graphs are not in the graph list yet. `id` is the Source's or the graph's own
/// id (a history anchor from before the outline still resolves), or `"<sourceID>#graphs"` for the
/// placeholder.
struct SourcesOutlineRow: Identifiable, Equatable {
    enum Kind: Equatable {
        case source(CatalogSource, disclosure: SourcesDisclosure)
        case graph(CatalogEvidenceGraph, source: CatalogSource)
        case pendingGraph(source: CatalogSource)
    }

    let id: String
    let kind: Kind
    /// The row closes its Source's group: the list draws a rule under it.
    var endsGroup: Bool

    static func pendingID(sourceID: String) -> String { "\(sourceID)#graphs" }

    var source: CatalogSource {
        switch kind {
        case .source(let source, _), .graph(_, let source), .pendingGraph(let source): source
        }
    }

    var disclosure: SourcesDisclosure? {
        if case .source(_, let disclosure) = kind { return disclosure }
        return nil
    }
}

/// What → or ← does at the selected row.
enum SourcesOutlineKeyAction: Equatable {
    case expand(String)
    case collapse(String)
    case select(String)
    case ignore
}

/// The Sources list as one flat array of rows: each visible Source, and under an open one its Evidence
/// graphs in the graph list's order. Pure, so it is tested without a view. Built once per change of the
/// visible Sources, the graph list or the open set (`SourcesModel.outline`).
struct SourcesOutline {
    let rows: [SourcesOutlineRow]
    /// Every graph of a visible Source in the loaded graph list, open or closed, to its Source.
    let ownerByGraphID: [String: CatalogSource]
    /// The Sources with a triangle, in row order.
    let togglableSourceIDs: [String]
    private let disclosureBySourceID: [String: SourcesDisclosure]

    /// Sources, closed unless `expanded` holds their id. A Source with no Artifact has no triangle and
    /// no graph rows; one whose graph read failed has none either. A Source whose graphs are not in the
    /// list yet always gets a triangle (every Source has a graph), and a placeholder row when open.
    init(
        sources: [CatalogSource],
        graphs: (String) -> QueryRead<[CatalogEvidenceGraph]>,
        expanded: Set<String>
    ) {
        var rows: [SourcesOutlineRow] = []
        var owners: [String: CatalogSource] = [:]
        var togglable: [String] = []
        var disclosures: [String: SourcesDisclosure] = [:]
        rows.reserveCapacity(sources.count)
        for source in sources {
            var disclosure = SourcesDisclosure.none
            var children: [SourcesOutlineRow] = []
            if source.hasArtifact {
                let isOpen = expanded.contains(source.id)
                switch graphs(source.id) {
                case .failed:
                    break
                case .loaded(let list):
                    disclosure = isOpen ? .expanded : .collapsed
                    for graph in list { owners[graph.id] = source }
                    if isOpen {
                        children = list.map { SourcesOutlineRow(id: $0.id, kind: .graph($0, source: source), endsGroup: false) }
                    }
                case .loading:
                    disclosure = isOpen ? .expanded : .collapsed
                    if isOpen {
                        children = [SourcesOutlineRow(
                            id: SourcesOutlineRow.pendingID(sourceID: source.id),
                            kind: .pendingGraph(source: source), endsGroup: false
                        )]
                    }
                }
            }
            if disclosure != .none { togglable.append(source.id) }
            disclosures[source.id] = disclosure
            rows.append(SourcesOutlineRow(
                id: source.id, kind: .source(source, disclosure: disclosure),
                endsGroup: children.isEmpty
            ))
            if !children.isEmpty {
                children[children.count - 1].endsGroup = true
                rows.append(contentsOf: children)
            }
        }
        self.rows = rows
        ownerByGraphID = owners
        togglableSourceIDs = togglable
        disclosureBySourceID = disclosures
    }

    func row(id: String?) -> SourcesOutlineRow? {
        guard let id else { return nil }
        return rows.first { $0.id == id }
    }

    /// The Source to open so the row `anchor` is drawn: the owner of a graph whose Source is closed.
    /// Nil for a Source row, a row already drawn, a graph of a Source not listed.
    func sourceToReveal(_ anchor: String) -> String? {
        guard let owner = ownerByGraphID[anchor], disclosureBySourceID[owner.id] == .collapsed else { return nil }
        return owner.id
    }

    /// The selection after the Sources in `collapsing` close: a graph or placeholder row of one of them
    /// selects its Source instead of a row that is going away; any other selection is unchanged.
    func selectionAfterCollapsing(_ collapsing: Set<String>, selection: String?) -> String? {
        guard let selection, let row = row(id: selection) else { return selection }
        if case .source = row.kind { return selection }
        return collapsing.contains(row.source.id) ? row.source.id : selection
    }

    /// Opens or closes `sources`. Closing a Source whose graph is selected selects the Source first.
    @MainActor
    func setExpanded(
        _ sources: [String], _ expanding: Bool, session: WorkspaceSession, navigation: WorkspaceNavigation
    ) {
        if !expanding {
            let selection = selectionAfterCollapsing(Set(sources), selection: navigation.listAnchor)
            if selection != navigation.listAnchor { navigation.noteListAnchor(selection) }
        }
        session.setSourcesExpanded(sources, expanding)
    }

    /// What → and ← do at `selected`: → opens a closed Source, ← closes an open one or climbs from a
    /// graph row to its Source. Anything else does nothing.
    static func keyAction(_ key: KeyEquivalent, selected: SourcesOutlineRow?) -> SourcesOutlineKeyAction {
        guard let selected else { return .ignore }
        switch (key, selected.kind) {
        case (.rightArrow, .source(let source, .collapsed)): return .expand(source.id)
        case (.leftArrow, .source(let source, .expanded)): return .collapse(source.id)
        case (.leftArrow, .graph(_, let source)), (.leftArrow, .pendingGraph(let source)): return .select(source.id)
        default: return .ignore
        }
    }

    /// The parts of a Source row's secondary line, in order. At Wide the type and the date are columns,
    /// so only the tail stays.
    static func secondaryParts(
        type: String, date: CatalogDateValueInput?, tail: String?, isWide: Bool
    ) -> [SourcesSecondaryPart] {
        var parts: [SourcesSecondaryPart] = []
        if !isWide {
            if !type.isEmpty { parts.append(.type(type)) }
            if let date, SourceDateText.line(date) != nil { parts.append(.date(date)) }
        }
        if let tail { parts.append(.tail(tail)) }
        return parts
    }
}

/// One part of a Source row's secondary line (`SourcesOutline.secondaryParts`).
enum SourcesSecondaryPart: Equatable {
    case type(String)
    case date(CatalogDateValueInput)
    case tail(String)
}

/// The columns a Source row adds before its ref: Regular keeps the updated column; Wide adds Type and
/// Published before it.
@MainActor
enum SourcesRowColumns {
    static let typeWidth: CGFloat = 180
    static let publishedWidth: CGFloat = 140

    /// The columns' widths, in order: what a skeleton row draws bars for.
    static func widths(isWide: Bool) -> [CGFloat] {
        isWide ? [typeWidth, publishedWidth, PVLastUpdated.columnWidth] : [PVLastUpdated.columnWidth]
    }

    static func details(
        isWide: Bool, typeLabel: @escaping (CatalogSource) -> String
    ) -> [PVListDetailColumn<CatalogSource>] {
        let updated = PVLastUpdated.column { (source: CatalogSource) in source.updated.at }
        guard isWide else { return [updated] }
        let type = PVListDetailColumn<CatalogSource>(width: typeWidth) {
            PVListDetail(text: typeLabel($0), help: typeLabel($0))
        }
        return [type, PVPublishedDate.column(width: publishedWidth) { (source: CatalogSource) in source.date }, updated]
    }
}

/// A closed Source's summary of its graphs: `1 graph · In progress`, `8 graphs · 3 in progress`,
/// `8 graphs · 5 promoted`, or `8 graphs` while the counts load or failed.
enum SourcesGraphSummary {
    static func text(_ counts: [SourcesGraphCounts]) -> String {
        let count = L10n.Sources.graphSummaryCount(counts.count)
        let statuses = counts.compactMap(\.status)
        guard statuses.count == counts.count, let first = statuses.first else { return count }
        if statuses.allSatisfy({ $0 == first }) {
            return L10n.Sources.graphSummary(count: count, detail: L10n.string(first.label))
        }
        let inProgress = statuses.filter { $0 == .inProgress }.count
        if inProgress > 0 {
            return L10n.Sources.graphSummary(count: count, detail: L10n.Sources.graphSummaryInProgress(inProgress))
        }
        let promoted = statuses.filter { $0 == .promoted }.count
        return L10n.Sources.graphSummary(count: count, detail: L10n.Sources.graphSummaryPromoted(promoted))
    }
}

/// The right-click menus of the Sources list, as the kit's action-menu sections.
enum SourcesRowMenu {
    /// What a menu entry does; the page selects the row first.
    struct Actions {
        var open: (SourcesOutlineRow) -> Void
        var openGraph: (CatalogEvidenceGraph, CatalogSource) -> Void
        var copy: (CatalogSource) -> Void
    }

    /// A Source: Open and Copy…, then (closed, its graphs read) an `Open <name>` per graph. A graph:
    /// Open, disabled when it links no Artifact. A placeholder: none.
    static func items(
        for row: SourcesOutlineRow,
        graphs: QueryRead<[CatalogEvidenceGraph]>,
        actions: Actions
    ) -> [[PVActionMenuItem]] {
        switch row.kind {
        case .source(let source, let disclosure):
            let prefix = "sources.row.\(source.id)"
            var sections = [[
                PVActionMenuItem(
                    title: L10n.Sources.menuOpen, accessibilityIdentifier: "\(prefix).menu.open",
                    action: { actions.open(row) }
                ),
                PVActionMenuItem(
                    title: L10n.Sources.copySourceEntry, accessibilityIdentifier: "\(prefix).menu.copy",
                    action: { actions.copy(source) }
                ),
            ]]
            if disclosure == .collapsed, case .loaded(let list) = graphs, !list.isEmpty {
                sections.append(list.map { graph in
                    PVActionMenuItem(
                        title: LocalizedStringResource(stringLiteral: L10n.Sources.menuOpenGraph(graph.name)),
                        isEnabled: SourcesListNavigation.graphBlockedReason(for: graph) == nil,
                        accessibilityIdentifier: "\(prefix).menu.openGraph.\(graph.ref)",
                        action: { actions.openGraph(graph, source) }
                    )
                })
            }
            return sections
        case .graph(let graph, let source):
            return [[PVActionMenuItem(
                title: L10n.Sources.menuOpen,
                isEnabled: SourcesListNavigation.graphBlockedReason(for: graph) == nil,
                accessibilityIdentifier: "sources.row.\(source.id).graph.\(graph.ref).menu.open",
                action: { actions.open(row) }
            )]]
        case .pendingGraph:
            return []
        }
    }
}
