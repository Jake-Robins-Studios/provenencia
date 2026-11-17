import Foundation
import Observation

/// What the Evidence graph form lets the researcher choose. One value, so
/// "did anything change" is one comparison against the prefill. State is the
/// unchecked Artifacts, so an Artifact added while the form is open starts
/// checked.
struct SourceGraphFormDraft: Equatable {
    var name = ""
    var description = ""
    var excludedArtifactIDs: Set<String> = []
}

/// State of the Evidence graph form, for one new graph or one existing one:
/// the draft, its metadata board, the Artifacts the engine says the graph must
/// keep linked (read when an edit opens), and the one write that saves it. The Source page presents
/// it through `View.sourceGraphFormDialog`.
@MainActor
@Observable
final class SourceGraphFormModel {
    enum Mode {
        /// A new graph; `suggestions` are the Source type's `graph`-level rows, empty.
        case create(suggestions: [CatalogMetadataEntry])
        case edit(CatalogEvidenceGraph)
    }

    /// Which part of the form its scrolling body opens at the top of.
    enum Section: Hashable {
        case top
        case metadata
    }

    let mode: Mode
    let opensAt: Section
    var draft: SourceGraphFormDraft
    let prefill: SourceGraphFormDraft
    var nameError: String?
    var saveError: String?
    private(set) var isSaving = false
    /// The section the scrolling body is asked to scroll to: where the form
    /// opened (nil at the top), then the top when a Save stops with a message.
    private(set) var scrollTarget: Section?
    /// Changes each time a Save asks the body to scroll to `scrollTarget` again.
    private(set) var scrollRequest = 0
    /// The graph's metadata draft and the board that edits it.
    let host: MetadataDraftHost
    let board: MetadataBoardModel
    /// The linked Artifacts the engine refuses to unlink, with why.
    private let locks: UnlinkLocks
    var loadState: PVFormLoadState { locks.state }
    var blocks: [CatalogEvidenceGraphUnlinkBlock] { locks.blocks }

    private let context: SourcePageContext

    init(context: SourcePageContext, mode: Mode, opensAt: Section = .top) {
        self.context = context
        self.mode = mode
        self.opensAt = opensAt
        scrollTarget = opensAt == .top ? nil : opensAt
        let artifactIDs = (context.workspace?.artifacts ?? []).map(\.id)
        switch mode {
        case .create(let suggestions):
            host = MetadataDraftHost(entries: suggestions, fields: context.fields)
            // A new graph starts with the Artifacts in no graph checked; when
            // the session cannot say, or every Artifact is in a graph, all are.
            var excluded: Set<String> = []
            if let none = context.session.artifactIDsInNoGraph(
                sourceID: context.sourceID, artifactIDs: artifactIDs
            ), !none.isEmpty {
                excluded = Set(artifactIDs.filter { !none.contains($0) })
            }
            prefill = SourceGraphFormDraft(excludedArtifactIDs: excluded)
            locks = UnlinkLocks(state: .ready)
        case .edit(let graph):
            let linked = Set(graph.artifactIDs)
            prefill = SourceGraphFormDraft(
                name: graph.name,
                description: graph.description,
                excludedArtifactIDs: Set(artifactIDs.filter { !linked.contains($0) })
            )
            locks = UnlinkLocks(state: graph.hasArtifact ? .loading : .ready)
            host = MetadataDraftHost(
                entries: context.metadataRows(for: MetadataOwner(level: .graph, id: graph.id)),
                fields: context.fields
            )
        }
        draft = prefill
        board = MetadataBoardModel(host: host)
    }

    // MARK: Reads

    var graph: CatalogEvidenceGraph? {
        if case .edit(let graph) = mode { return graph }
        return nil
    }

    /// The Source's Artifacts in page order.
    var artifacts: [CatalogArtifact] { context.workspace?.artifacts ?? [] }

    var projectDir: String { context.projectDir }

    /// The Source's type icon, for Artifact thumbnails that have no file.
    var sourceTypeIconKey: String? {
        context.sourceTypeIconKey
    }

    /// Artifact id to the hint under its locked row; see `lockHints(by:)` in
    /// `SourceArtifactGraphLinks.swift`.
    var locked: [String: String] { locks.locked(by: \.artifactID) }

    /// The locked Artifacts that Citations need: each gets an "Open in citation
    /// composer" link under its row. A lock with none (the graph's last
    /// Artifact) shows only its reason.
    var composerLinkArtifactIDs: Set<String> {
        Set(blocks.filter { $0.citationCount > 0 }.map(\.artifactID))
            .intersection(artifacts.map(\.id))
    }

    /// This graph's citation composer with the Artifact selected. Nil on Add: no graph yet.
    func composerLocation(artifactID: String) -> WorkspaceLocation? {
        guard let graph else { return nil }
        return .citationComposer(
            sourceId: context.sourceID,
            graphId: graph.id,
            artifactId: artifactID,
            sourceTitle: context.source?.title
        )
    }

    /// The ids a save sends: the checked Artifacts in page order.
    var checkedArtifactIDs: [String] {
        PVChecklistState.checkedIDs(
            ids: artifacts.map(\.id),
            excluded: draft.excludedArtifactIDs,
            locked: Set(locked.keys)
        )
    }

    /// Every Artifact is unchecked on a Source that has some.
    var needsArtifact: Bool { !artifacts.isEmpty && checkedArtifactIDs.isEmpty }

    var canSave: Bool { loadState == .ready && !isSaving && !needsArtifact }

    var isDirty: Bool { draft != prefill || board.hasUnsavedChanges }

    // MARK: Actions

    /// Asks the engine which of the graph's linked Artifacts it will not
    /// unlink. One call covers the whole form. A graph with no links has nothing
    /// to read. Read again calls this too.
    func loadKeptLinks() async {
        guard let graph, graph.hasArtifact else { return }
        await locks.load(
            store: context.store,
            projectDir: context.projectDir,
            pairs: graph.artifactIDs.map {
                CatalogEvidenceGraphArtifactPair(graphID: graph.id, artifactID: $0)
            },
            onError: { L10n.Errors.message(for: $0) }
        )
    }

    /// A message sits at the top of the body (the save error, the name's error): ask for it.
    private func scrollToTop() {
        scrollTarget = .top
        scrollRequest += 1
    }

    /// One write: the name, description, links and the metadata draft together. On success
    /// returns true for the host to close the form; on failure the form keeps every choice.
    func save() async -> Bool {
        guard !isSaving else { return false }
        saveError = nil
        nameError = nil
        if let message = board.unconfirmedInputMessage {
            saveError = message
            scrollToTop()
            return false
        }
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            nameError = L10n.string(L10n.Sources.graphFormNameRequired)
            scrollToTop()
            return false
        }
        guard canSave else { return false }

        isSaving = true
        defer { isSaving = false }
        let description = draft.description.trimmingCharacters(in: .whitespacesAndNewlines)
        let metadata = host.draft
        do {
            switch mode {
            case .create:
                let (graph, rows, effects) = try await context.store.createEvidenceGraph(
                    projectDir: context.projectDir,
                    userID: context.userID,
                    sourceID: context.sourceID,
                    name: name,
                    description: description,
                    artifactIDs: checkedArtifactIDs,
                    metadata: metadata
                )
                context.applySavedMetadata(rows, owner: MetadataOwner(level: .graph, id: graph.id), effects: effects)
                context.toast = VocabularyToast(
                    title: L10n.string(L10n.Sources.toastGraphAddedTitle),
                    body: L10n.Sources.toastGraphAddedBody(ref: graph.ref),
                    tone: .success
                )
            case .edit(let graph):
                // Empty ids (a Source with no Artifacts) leave the links unchanged.
                let (rows, effects) = try await context.store.updateEvidenceGraph(
                    projectDir: context.projectDir,
                    userID: context.userID,
                    graphID: graph.id,
                    name: name,
                    description: description,
                    artifactIDs: checkedArtifactIDs,
                    metadata: metadata
                )
                context.applySavedMetadata(rows, owner: MetadataOwner(level: .graph, id: graph.id), effects: effects)
            }
            host.markSaved()
            return true
        } catch {
            if board.showRefusal(error) { return false }
            let message = L10n.Sources.graphFormSaveErrorMessage(L10n.Errors.message(for: error))
            saveError = message
            scrollToTop()
            // Any refusal of an edit: the engine's locks may have moved since
            // the form opened (a Citation took an Artifact), so read them again
            // and keep the refusal in view.
            if let graph, graph.hasArtifact {
                await loadKeptLinks()
                saveError = message
            }
            return false
        }
    }
}
