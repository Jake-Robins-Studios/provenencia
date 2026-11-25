import SwiftUI

/// Whether a Source row has a triangle, and which way it points.
enum SourcesDisclosure: Equatable {
    /// No triangle: no Artifact, or its graph list failed.
    case none
    case collapsed
    case expanded
}

/// One row of the Sources list: a Source, an Evidence graph under the open Source, or the placeholder
/// of the open Source whose graphs are not in the graph list yet. `id` is the Source's or the graph's own
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

/// What a key or a click does to the open Source and the selection.
enum SourcesOutlineAction: Equatable {
    case expand(String)
    case collapse
    case select(String)
    case ignore
}

/// The Sources list as one flat array of rows: each visible Source, and under an open one its Evidence
/// graphs in the graph list's order. Pure, so it is tested without a view. Built once per change of the
/// visible Sources, the graph list or the open Source (`SourcesModel.outline`).
struct SourcesOutline {
    let rows: [SourcesOutlineRow]
    /// `rows` as the table's items, built once with the outline.
    let items: [SourcesTableItem]
    /// The rows' ids, in order.
    let ids: [String]
    /// The open Source's id, as the session holds it; it may name no listed Source.
    let open: String?

    /// Sources, closed unless `open` is their id (an id with no Source in `sources` draws nothing). A
    /// Source with no Artifact has no triangle and no graph rows; one whose graph read failed has none
    /// either. A Source whose graphs are not in the list yet always gets a triangle (every Source has a
    /// graph), and a placeholder row when open.
    init(
        sources: [CatalogSource],
        graphs: (String) -> QueryRead<[CatalogEvidenceGraph]>,
        open: String?
    ) {
        var rows: [SourcesOutlineRow] = []
        rows.reserveCapacity(sources.count)
        for source in sources {
            var disclosure = SourcesDisclosure.none
            var children: [SourcesOutlineRow] = []
            if source.hasArtifact {
                let isOpen = source.id == open
                switch graphs(source.id) {
                case .failed:
                    break
                case .loaded(let list):
                    disclosure = isOpen ? .expanded : .collapsed
                    if isOpen {
                        children = list.map { SourcesOutlineRow(id: $0.id, kind: .graph($0, source: source)) }
                    }
                case .loading:
                    disclosure = isOpen ? .expanded : .collapsed
                    if isOpen {
                        children = [SourcesOutlineRow(
                            id: SourcesOutlineRow.pendingID(sourceID: source.id),
                            kind: .pendingGraph(source: source)
                        )]
                    }
                }
            }
            rows.append(SourcesOutlineRow(id: source.id, kind: .source(source, disclosure: disclosure)))
            rows.append(contentsOf: children)
        }
        self.rows = rows
        items = rows.map(SourcesTableItem.row)
        ids = rows.map(\.id)
        self.open = open
    }

    func row(id: String?) -> SourcesOutlineRow? {
        guard let id else { return nil }
        return rows.first { $0.id == id }
    }

    /// The selection after `id` becomes the open Source (nil closes the open one), when the move named
    /// `selecting` selects that row, whatever it is. With none named, a selected graph or placeholder row
    /// of a Source that closes selects its Source instead of a row that is going away; any other
    /// selection is unchanged.
    func selection(afterOpening id: String?, selecting: String?, current: String?) -> String? {
        if let selecting { return selecting }
        guard let current, let row = row(id: current) else { return current }
        if case .source = row.kind { return current }
        return row.source.id == id ? current : row.source.id
    }

    /// What a plain click does when it moves the selection to `new`: the click (a left press with no
    /// modifier, not the keyboard, Back, a reveal, a right-click or a menu) not on a triangle (the button
    /// toggles it itself) and landing on a Source row that is not the open one. A Source with a triangle
    /// opens (and the open one closes); one with none closes the open one, unless it is the open one itself.
    /// A graph, the selected row, a Source already open and anything else do nothing.
    func clickAction(selecting new: String?, from old: String?, isPlainClick: Bool, onTriangle: Bool) -> SourcesOutlineAction {
        guard isPlainClick, !onTriangle, let new, new != old,
              let row = row(id: new), case .source(let source, let disclosure) = row.kind,
              disclosure != .expanded else { return .ignore }
        if disclosure == .collapsed { return .expand(source.id) }
        guard open != nil, open != source.id else { return .ignore }
        return .collapse
    }

    /// Makes `id` the one open Source (nil closes the open one) and moves the selection as
    /// `selection(afterOpening:selecting:current:)` says. The triangle, → and ←, a click, the reveal
    /// and the menu's Open of a graph all come here.
    @MainActor
    func setOpen(
        _ id: String?, selecting: String? = nil, session: WorkspaceSession, navigation: WorkspaceNavigation
    ) {
        let selection = selection(afterOpening: id, selecting: selecting, current: navigation.listSelection)
        if selection != navigation.listSelection { navigation.noteListSelection(selection) }
        session.setOpenSource(id)
    }

    /// What → and ← do at `selected`: → opens a closed Source, ← closes an open one or climbs from a
    /// graph row to its Source. Anything else does nothing.
    static func keyAction(_ key: KeyEquivalent, selected: SourcesOutlineRow?) -> SourcesOutlineAction {
        guard let selected else { return .ignore }
        switch (key, selected.kind) {
        case (.rightArrow, .source(let source, .collapsed)): return .expand(source.id)
        case (.leftArrow, .source(_, .expanded)): return .collapse
        case (.leftArrow, .graph(_, let source)), (.leftArrow, .pendingGraph(let source)): return .select(source.id)
        default: return .ignore
        }
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
