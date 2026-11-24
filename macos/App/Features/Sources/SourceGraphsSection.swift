import Foundation
import Observation

/// The Source page's Evidence graphs: one row per graph of the page's Source,
/// read from the session's graph list. A snapshot of the list, so the rows
/// follow a create, rename or delete without a page-local copy.
@MainActor
@Observable
final class SourceGraphsSection {
    private let context: SourcePageContext

    /// The Add / Edit form while it is open.
    var form: SourceGraphFormModel?

    @ObservationIgnored
    private var formLoad: Task<Void, Never>?

    init(context: SourcePageContext) {
        self.context = context
    }

    /// The Source's graphs in list order (sorted by name); `nil` while the
    /// graph list has no value.
    var rows: [CatalogEvidenceGraph]? { context.evidenceGraphs }

    /// The section header's count; nil while the list has no value and when the Source has no graph.
    var countLabel: String? {
        rows.flatMap { $0.isEmpty ? nil : L10n.Sources.graphsCount($0.count) }
    }

    /// The graph list's error while it has no value to show.
    var loadError: Error? {
        guard case .failed(let error) = context.session.evidenceGraphsRead(sourceID: context.sourceID) else { return nil }
        return error
    }

    /// The counts of one graph, as the Sources list reads them.
    func counts(for graph: CatalogEvidenceGraph) -> SourcesGraphCounts {
        context.session.graphCounts(graphID: graph.id)
    }

    /// Where Open goes: the graph's canvas while it links an Artifact.
    func location(for graph: CatalogEvidenceGraph) -> WorkspaceLocation? {
        guard let source = context.source else { return nil }
        return SourcesListNavigation.graphLocation(for: source, graph: graph)
    }

    /// Why Open is blocked; nil when it opens.
    func blockedReason(for graph: CatalogEvidenceGraph) -> String? {
        SourcesListNavigation.graphBlockedReason(for: graph)
    }

    // MARK: Add and edit

    /// A new graph needs an Artifact to link.
    var canAdd: Bool { !(context.workspace?.artifacts.isEmpty ?? true) }

    /// Why Add is disabled; nil when it is enabled, and while the page loads.
    var addBlockedReason: String? {
        guard let workspace = context.workspace, workspace.artifacts.isEmpty else { return nil }
        return L10n.string(L10n.Sources.addEvidenceGraphNeedsArtifact)
    }

    /// Opens the Add form, its metadata board starting as the draft board (the Source type's
    /// suggestions, empty). Answers the form, or nil when none opened: one is open or opening, or
    /// the draft board read failed (the page banner shows the message).
    @discardableResult
    func openAdd() async -> SourceGraphFormModel? {
        guard canAdd, let entries = await context.readDraftBoardForAdd(level: .graph) else { return nil }
        let model = SourceGraphFormModel(context: context, mode: .create(entries: entries))
        form = model
        return model
    }

    /// The graph with `id` when it belongs to this page's Source.
    func ownGraph(id: String) -> CatalogEvidenceGraph? {
        guard let graph = context.session.evidenceGraph(id: id), graph.sourceID == context.sourceID else { return nil }
        return graph
    }

    func openEdit(id: String, at section: SourceGraphFormModel.Section = .top) {
        guard !context.isOpeningForm, context.workspace != nil, let graph = ownGraph(id: id) else { return }
        let model = SourceGraphFormModel(context: context, mode: .edit(graph), opensAt: section)
        form = model
        formLoad = Task { await model.loadKeptLinks() }
    }

    /// Returns once the open edit form's kept-links load has finished. Tests
    /// await this instead of polling against a deadline, which a busy main
    /// actor can outlast.
    func settleFormLoad() async {
        await formLoad?.value
    }
}
