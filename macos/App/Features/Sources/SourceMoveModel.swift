import Foundation
import Observation

/// State of the Move to another Source dialog: the bundle the engine says moves
/// with the picked Artifact or graph, the target the researcher picks, the notes
/// the move earns (credibility, a Source left with no Artifacts or no graph), and
/// the move itself. The Source page presents it through `View.sourceMoveDialog`.
@MainActor
@Observable
final class SourceMoveModel {
    let seed: CatalogSourceMoveSeed
    /// The Source the bundle leaves: the page's own.
    let origin: CatalogSource
    /// The picked Artifact's or graph's name and ref, the dialog's subtitle.
    let seedTitle: String
    let seedRef: String
    /// The origin's type icon, for the Artifact thumbnails that have no file.
    let sourceTypeIconKey: String?

    private(set) var targetID: String?
    /// The picked row, kept from the pick.
    private(set) var target: CatalogSource?
    private(set) var impact: CatalogSourceMoveImpact?
    /// The target the held reply answered; nil for the read with no target.
    private(set) var impactTarget: String?
    private(set) var readState: PVFormLoadState = .loading
    private(set) var isReading = false
    private(set) var isMoving = false
    var moveError: String?

    private let session: WorkspaceSession
    private let userID: String
    private let store: any GenealogyStore
    private let listHandle: QueryHandle<[CatalogSource]>
    @ObservationIgnored private let preflight = LatestCall()

    init(
        seed: CatalogSourceMoveSeed,
        origin: CatalogSource,
        seedTitle: String,
        seedRef: String,
        sourceTypeIconKey: String?,
        session: WorkspaceSession,
        userID: String,
        store: any GenealogyStore
    ) {
        self.seed = seed
        self.origin = origin
        self.seedTitle = seedTitle
        self.seedRef = seedRef
        self.sourceTypeIconKey = sourceTypeIconKey
        self.session = session
        self.userID = userID
        self.store = store
        listHandle = session.query(SourcesModel.sourcesListKey(for: session))
        read(target: nil)
    }

    /// Project folder for resolving `objects/…` thumbnail paths.
    var projectDir: String { session.projectKey.projectDir }

    // MARK: Targets

    /// Every other Source, most recently changed first; nil while the Sources list is unread.
    var targets: [CatalogSource]? {
        guard listHandle.value != nil else { return nil }
        return session.sourcesByUpdated.filter { $0.id != origin.id }
    }

    /// The target ComboBox's options, built once per change of the Sources list: the dialog redraws
    /// on every keystroke and read, and the list can hold thousands of rows.
    var targetOptions: [PVComboBoxOption] {
        let sources = session.sourcesByUpdated
        let originID = origin.id
        return session.derived(.sourceMoveTargets(originID: originID), inputs: [.derived(.sourcesByUpdated)]) {
            sources.filter { $0.id != originID }
                .map { PVComboBoxOption(value: $0.id, label: $0.title, subtext: $0.ref) }
        }
    }

    /// The Sources list's own state, for the field's place in the dialog. A value wins: a failed
    /// refetch keeps the stale list and stays `.ready`.
    var targetsLoadState: PVFormLoadState { listHandle.read.formLoadState }

    /// Reads the Sources list again, after a failed read.
    func readTargetsAgain() {
        let _: QueryHandle<[CatalogSource]> = session.reread(SourcesModel.sourcesListKey(for: session))
    }

    // MARK: Reads

    /// The picked target changed; `""` is the ComboBox cleared. A pick reads the bundle again with
    /// the target, and the newest read is the only one that lands.
    func pick(targetID id: String) {
        if id == (targetID ?? "") { return }
        if id.isEmpty {
            targetID = nil
            target = nil
            return
        }
        guard let row = targets?.first(where: { $0.id == id }) else { return }
        targetID = id
        target = row
        if impact != nil { readState = .ready }
        read(target: id)
    }

    /// Reads again for the current pick (or none), after a failed read.
    func readAgain() {
        readState = .loading
        read(target: targetID)
    }

    /// Returns once the newest read has finished (tests).
    func settleReads() async {
        await preflight.settle()
    }

    private func read(target: String?) {
        isReading = true
        if impact == nil { readState = .loading }
        let store = store
        let projectDir = projectDir
        let seed = seed
        preflight.start({
            try await store.getSourceMoveImpact(projectDir: projectDir, seed: seed, targetSourceID: target)
        }, apply: { [weak self] result in
            guard let self else { return }
            self.isReading = false
            switch result {
            case .success(let reply):
                self.impact = reply
                self.impactTarget = target
                self.readState = .ready
            case .failure(let error):
                self.readState = .failed(L10n.Errors.message(for: error))
            }
        })
    }

    var canMove: Bool {
        impact != nil && target != nil && impactTarget == targetID
            && readState == .ready && !isReading && !isMoving
    }

    // MARK: The bundle

    /// The Artifacts that move: the seed first, then the rest in the reply's order.
    var bundleArtifacts: [CatalogArtifact] {
        guard let impact else { return [] }
        guard case .artifact(let id) = seed, let index = impact.artifacts.firstIndex(where: { $0.id == id }) else {
            return impact.artifacts
        }
        var rest = impact.artifacts
        let first = rest.remove(at: index)
        return [first] + rest
    }

    /// The graphs that move, the seed first, each with its counts matched by graph id.
    var bundleGraphs: [(graph: CatalogEvidenceGraph, progress: EvidenceGraphProgress?)] {
        guard let impact else { return [] }
        var graphs = impact.graphs
        if case .graph(let id) = seed, let index = graphs.firstIndex(where: { $0.id == id }) {
            graphs.insert(graphs.remove(at: index), at: 0)
        }
        return graphs.map { graph in (graph, impact.progress.first { $0.graphId == graph.id }) }
    }

    /// The "why" line explains a pulled-in Artifact, so it shows only when more than one moves.
    var showsWhy: Bool { bundleArtifacts.count > 1 }

    // MARK: Notes

    /// The credibility note for the target the held reply answered, when the two grades differ.
    var credibilityNote: (title: String, message: String)? {
        guard let impact, impact.credibilityDiffers, let target, impactTarget == targetID else { return nil }
        func grade(_ label: String) -> String {
            label.isEmpty ? L10n.string(L10n.Sources.moveNotAssessed) : L10n.Sources.moveAssessedAs(label)
        }
        return (
            L10n.string(L10n.Sources.moveCredibilityTitle),
            L10n.Sources.moveCredibilityMessage(
                origin: origin.title,
                originGrade: grade(impact.sourceCredibilityLabel),
                target: target.title,
                targetGrade: grade(impact.targetCredibilityLabel),
                weighedAs: impact.weighedAsLabel
            )
        )
    }

    var leavesEmptyNote: String? {
        impact?.leavesSourceEmpty == true ? L10n.Sources.moveLeavesEmpty(origin.title) : nil
    }

    var leavesNoGraphNote: String? {
        impact?.leavesNoGraph == true ? L10n.Sources.moveLeavesNoGraph(origin.title) : nil
    }

    // MARK: The move

    /// Moves the bundle, then leaves the page for the target Source's. Both Sources' pages follow
    /// the write's `source_holdings`, so nothing else is named. False leaves the dialog open on
    /// `moveError`.
    func move(leavingPage leave: @escaping (CatalogSource) -> Void) async -> Bool {
        guard canMove, let target else { return false }
        isMoving = true
        defer { isMoving = false }
        moveError = nil
        do {
            let result = try await store.moveToSource(
                projectDir: projectDir,
                userID: userID,
                seed: seed,
                targetSourceID: target.id
            )
            session.noticeToast = VocabularyToast(
                title: L10n.Sources.moveDoneTitle(target: target.title),
                body: Self.doneBody(artifacts: result.artifactIDs.count, graphs: result.graphIDs.count),
                tone: .success
            )
            session.apply(result.effects, leavingPage: { leave(target) })
            return true
        } catch {
            moveError = L10n.Errors.message(for: error)
            return false
        }
    }

    /// The Toast body: which of the three sentence shapes the counts need; the plural form
    /// inside each is the catalog's.
    static func doneBody(artifacts: Int, graphs: Int) -> String {
        if artifacts > 0, graphs > 0 { return L10n.Sources.moveDoneBody(artifacts: artifacts, graphs: graphs) }
        if artifacts == 0, graphs > 0 { return L10n.Sources.moveDoneGraphs(graphs) }
        return L10n.Sources.moveDoneArtifacts(artifacts)
    }
}
