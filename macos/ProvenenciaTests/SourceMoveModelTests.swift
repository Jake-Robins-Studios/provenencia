import Foundation
import Testing
@testable import Provenencia

@Suite
@MainActor
struct SourceMoveModelTests {
    private let projectDir = "/tmp/source-move.provenencia"
    private let userID = "00000000-0000-7000-8000-000000000001"

    private func graph(_ id: String, name: String? = nil, artifacts: [String] = [], sourceID: String = "s1") -> CatalogEvidenceGraph {
        CatalogEvidenceGraph(
            id: id, ref: "GPH-\(id)", sourceID: sourceID, name: name ?? id, description: "", artifactIDs: artifacts
        )
    }

    private func source(_ id: String, _ title: String, revision: Int64 = 0) -> CatalogSource {
        CatalogSource(
            id: id, ref: "SRC-\(id)", sourceTypeID: "t1", title: title, description: "",
            updated: CatalogActivity(revision: revision)
        )
    }

    private func impact(
        artifacts: [CatalogArtifact],
        graphs: [CatalogEvidenceGraph],
        progress: [EvidenceGraphProgress]? = nil,
        leavesEmpty: Bool = false,
        leavesNoGraph: Bool = false
    ) -> CatalogSourceMoveImpact {
        CatalogSourceMoveImpact(
            sourceID: "s1", artifacts: artifacts, graphs: graphs,
            progress: progress ?? graphs.map { EvidenceGraphProgress(graphId: $0.id, subjectCount: 4, observationCount: 6) },
            sourceCredibilityLabel: "", targetCredibilityLabel: "", weighedAsLabel: "",
            credibilityDiffers: false, leavesSourceEmpty: leavesEmpty, leavesNoGraph: leavesNoGraph
        )
    }

    /// S1 (the origin), S2 updated at revision 9, S3 at revision 2; A1 and A2 in graphs G1 and G2.
    private func makeStore(sources: [CatalogSource]? = nil) -> FakeStore {
        let store = FakeStore()
        store.sourcesByProject[projectDir] = sources ?? [source("s1", "Census"), source("s2", "Deed", revision: 9), source("s3", "Will", revision: 2)]
        store.sourceTypesByProject[projectDir] = [
            CatalogSourceType(id: "t1", key: "census", origin: "provenencia", label: "Census", description: ""),
        ]
        let a1 = catalogArtifact("a1", ref: "ART-7QK2M", label: "Sheet 14 (image 1)")
        let a2 = catalogArtifact("a2", label: "Sheet 14 (image 2)")
        store.artifactsBySource["s1"] = [a1, a2, catalogArtifact("a3", label: "Sheet 20")]
        store.evidenceGraphsByProject[projectDir] = [
            graph("g1", name: "Hale household", artifacts: ["a1", "a2"]),
            graph("g2", name: "Robins household", artifacts: ["a2"]),
            graph("g0", name: "Default"),
        ]
        store.sourceMoveImpacts["a1"] = impact(artifacts: [a1, a2], graphs: [graph("g1", name: "Hale household"), graph("g2", name: "Robins household")])
        store.sourceMoveImpacts["a2"] = impact(artifacts: [a1, a2], graphs: [graph("g1"), graph("g2")])
        store.sourceMoveImpacts["g0"] = impact(artifacts: [], graphs: [graph("g0", name: "Default")])
        return store
    }

    private func makeModel(
        store: FakeStore,
        seed: CatalogSourceMoveSeed = .artifact("a1"),
        session: WorkspaceSession? = nil
    ) -> (SourceMoveModel, WorkspaceSession) {
        let session = session ?? WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)
        let model = SourceMoveModel(
            seed: seed, origin: source("s1", "Census"), seedTitle: "Sheet 14 (image 1)", seedRef: "ART-7QK2M",
            sourceTypeIconKey: nil, session: session, userID: userID, store: store
        )
        return (model, session)
    }

    /// The model once the Sources list has loaded and the open read has answered.
    private func openedModel(
        store: FakeStore,
        seed: CatalogSourceMoveSeed = .artifact("a1")
    ) async -> (SourceMoveModel, WorkspaceSession) {
        let (model, session) = makeModel(store: store, seed: seed)
        let list: QueryHandle<[CatalogSource]>? = session.queryHandle(SourcesModel.sourcesListKey(for: session))
        if let list { await waitForQuery(list) }
        await model.settleReads()
        return (model, session)
    }

    private func failure() -> Error {
        CoreInvokeError.coded(status: 1, code: "sourcemove.invalid", kind: .user, params: [])
    }

    private func pageModel(store: FakeStore) async -> (SourcePageModel, WorkspaceSession) {
        let session = WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)
        let page = SourcePageModel(
            sourceID: "s1", session: session, userID: userID, sessionDisplayName: "Jake", store: store
        )
        return (page, session)
    }

    @Test
    func fakeStoreRecordsMoveCalls() async throws {
        let store = FakeStore()
        let a1 = catalogArtifact("a1")
        store.artifactsBySource["s1"] = [a1, catalogArtifact("a2")]
        store.sourceMoveImpacts["a1"] = impact(artifacts: [a1], graphs: [])

        let read = try await store.getSourceMoveImpact(projectDir: projectDir, seed: .artifact("a1"), targetSourceID: "s2")
        #expect(read.artifacts == [a1])
        let result = try await store.moveToSource(
            projectDir: projectDir, userID: userID, seed: .artifact("a1"), targetSourceID: "s2"
        )

        #expect(store.getSourceMoveImpactCalls.map(\.seed) == [.artifact("a1")])
        #expect(store.getSourceMoveImpactCalls.map(\.target) == ["s2"])
        #expect(store.moveToSourceCalls.map(\.target) == ["s2"])
        #expect(result.artifactIDs == ["a1"])
        #expect(store.artifactsBySource["s2"]?.map(\.id) == ["a1"])
        #expect(store.artifactsBySource["s2"]?.first?.sourceID == "s2")
        #expect(store.artifactsBySource["s1"]?.map(\.id) == ["a2"])
    }

    // MARK: Opening

    @Test
    func opensWithTheBundle() async {
        let store = makeStore()
        let (page, session) = await pageModel(store: store)
        await page.warmFromSession()
        await waitForQuery(session.query(session.evidenceGraphsKey) as QueryHandle<[CatalogEvidenceGraph]>)
        page.openMove(artifactID: "nope")
        #expect(page.moving == nil)

        page.openMove(artifactID: "a1")
        // The page's own artifacts come from its workspace, which the fake holds for s1.
        let model = page.moving
        #expect(model?.seedTitle == "Sheet 14 (image 1)")
        #expect(model?.seedRef == "ART-7QK2M")
        #expect(model?.readState == .loading)
        #expect(model?.canMove == false)
        await model?.settleReads()
        #expect(store.getSourceMoveImpactCalls.count == 1)
        #expect(store.getSourceMoveImpactCalls.first?.target == nil)
        #expect(model?.readState == .ready)
        #expect(model?.impact == store.sourceMoveImpacts["a1"])
        #expect(model?.canMove == false)
    }

    @Test
    func opensFromAGraph() async {
        let store = makeStore()
        let (page, session) = await pageModel(store: store)
        await page.warmFromSession()
        await waitForQuery(session.query(session.evidenceGraphsKey) as QueryHandle<[CatalogEvidenceGraph]>)

        page.openMove(graphID: "g0")
        let model = page.moving
        await model?.settleReads()
        #expect(store.getSourceMoveImpactCalls.first?.seed == .graph("g0"))
        #expect(model?.seedTitle == "Default")
        #expect(model?.seedRef == "GPH-g0")
        #expect(model?.bundleGraphs.count == 1)
        #expect(model?.bundleArtifacts.isEmpty == true)
        #expect(model?.showsWhy == false)

        // No Source on the page yet: nothing opens.
        let empty = makeStore(sources: [])
        let (bare, _) = await pageModel(store: empty)
        bare.openMove(graphID: "g0")
        #expect(bare.moving == nil)
    }

    // MARK: The bundle

    @Test
    func bundleRowsAndWhyLine() async {
        let a1 = catalogArtifact("a1")
        let a2 = catalogArtifact("a2")
        let store = makeStore()

        func model(_ seed: CatalogSourceMoveSeed, _ reply: CatalogSourceMoveImpact) async -> SourceMoveModel {
            store.sourceMoveImpacts[seed.id] = reply
            let (model, _) = await openedModel(store: store, seed: seed)
            return model
        }

        #expect(await model(.artifact("a3"), impact(artifacts: [catalogArtifact("a3")], graphs: [])).showsWhy == false)
        #expect(await model(.graph("g0"), impact(artifacts: [], graphs: [graph("g0")])).showsWhy == false)
        #expect(await model(.artifact("a9"), impact(artifacts: [catalogArtifact("a9")], graphs: [graph("g9")])).showsWhy == false)
        let wide = await model(.artifact("a1"), impact(artifacts: [a1, a2], graphs: [graph("g1"), graph("g2")]))
        #expect(wide.showsWhy)

        // The seed first in its group, the rest in the reply's order.
        let second = await model(.artifact("a2"), impact(artifacts: [a1, a2], graphs: [graph("g1"), graph("g2")]))
        #expect(second.bundleArtifacts.map(\.id) == ["a2", "a1"])
        let seedGraph = await model(.graph("g2"), impact(artifacts: [a1, a2], graphs: [graph("g1"), graph("g2")]))
        #expect(seedGraph.bundleGraphs.map(\.graph.id) == ["g2", "g1"])

        // A reply whose progress lacks G2 and lists G1 last: each graph keeps its own row.
        let reordered = await model(
            .artifact("a1"),
            impact(
                artifacts: [a1, a2], graphs: [graph("g1"), graph("g2")],
                progress: [EvidenceGraphProgress(graphId: "g1", subjectCount: 3, observationCount: 5)]
            )
        )
        let rows = reordered.bundleGraphs
        #expect(rows.map(\.graph.id) == ["g1", "g2"])
        #expect(rows[0].progress?.subjectCount == 3)
        #expect(rows[1].progress == nil)
    }

    @Test
    func leftBehindNotes() async {
        let store = makeStore()
        store.sourceMoveImpacts["a1"] = impact(artifacts: [catalogArtifact("a1")], graphs: [], leavesEmpty: true, leavesNoGraph: true)
        let (both, _) = await openedModel(store: store)
        #expect(both.leavesEmptyNote == L10n.Sources.moveLeavesEmpty("Census"))
        #expect(both.leavesNoGraphNote == L10n.Sources.moveLeavesNoGraph("Census"))

        store.sourceMoveImpacts["a1"] = impact(artifacts: [catalogArtifact("a1")], graphs: [])
        let (neither, _) = await openedModel(store: store)
        #expect(neither.leavesEmptyNote == nil)
        #expect(neither.leavesNoGraphNote == nil)
    }

    // MARK: Targets

    @Test
    func targetsExcludeOriginRecentFirst() async {
        let (model, _) = await openedModel(store: makeStore())
        #expect(model.targets?.map(\.id) == ["s2", "s3"])

        let alone = makeStore(sources: [source("s1", "Census")])
        let (nowhere, _) = await openedModel(store: alone)
        #expect(nowhere.targets?.isEmpty == true)

        let unread = makeStore()
        unread.listSourcesError = CoreInvokeError.coded(status: 1, code: "x", kind: .internal, params: [])
        let (blind, _) = await openedModel(store: unread)
        #expect(blind.targets == nil)
        guard case .failed = blind.targetsLoadState else {
            Issue.record("list failure: \(blind.targetsLoadState)")
            return
        }

        // Read again re-reads the Sources list; the field's state follows it.
        unread.listSourcesError = nil
        blind.readTargetsAgain()
        for _ in 0 ..< 200 where blind.targets == nil {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        #expect(blind.targets?.map(\.id) == ["s2", "s3"])
        #expect(blind.targetsLoadState == .ready)
        #expect(model.targetsLoadState == .ready)
    }

    // MARK: Picking

    @Test
    func pickReadsAgainAndDropsStaleReplies() async {
        let store = makeStore()
        let (model, _) = await openedModel(store: store)
        #expect(model.impact != nil)

        store.getSourceMoveImpactHold.isOn = true
        model.pick(targetID: "s2")
        await store.getSourceMoveImpactHold.untilSuspended(1)
        model.pick(targetID: "s3")
        #expect(model.canMove == false)
        await store.getSourceMoveImpactHold.untilSuspended(2)
        #expect(model.impact != nil)

        // The newer read (S3) answers first and lands; S2's late reply must then be dropped, not
        // replace it.
        store.getSourceMoveImpactHold.releaseNewest()
        await model.settleReads()
        #expect(model.impactTarget == "s3")
        store.getSourceMoveImpactHold.release()
        await store.getSourceMoveImpactHold.untilSuspended(0)
        for _ in 0 ..< 10 { await Task.yield() }
        #expect(model.impactTarget == "s3")
        await model.settleReads()

        #expect(store.getSourceMoveImpactCalls.map(\.target) == [nil, "s2", "s3"])
        #expect(model.impactTarget == "s3")
        #expect(model.canMove)
        #expect(model.impact?.artifacts.isEmpty == false)
    }

    @Test
    func credibilityNote() async {
        let store = makeStore()
        var reply = impact(artifacts: [catalogArtifact("a1")], graphs: [])
        reply.sourceCredibilityLabel = "Low trust"
        store.sourceMoveImpacts["a1"] = reply
        store.sourceMoveTargetCredibility["s2"] = (label: "", weighedAs: "Standard", differs: true)
        let (model, _) = await openedModel(store: store)
        #expect(model.credibilityNote == nil)

        model.pick(targetID: "s2")
        await model.settleReads()
        let note = model.credibilityNote
        #expect(note?.title == L10n.string(L10n.Sources.moveCredibilityTitle))
        #expect(note?.message.contains("“Census” is assessed Low trust") == true)
        #expect(note?.message.contains("“Deed” is not assessed") == true)
        #expect(note?.message.contains("assessed not assessed") == false)
        #expect(note?.message.contains("weighed as Standard") == true)

        store.sourceMoveTargetCredibility["s3"] = (label: "", weighedAs: "", differs: false)
        model.pick(targetID: "s3")
        await model.settleReads()
        #expect(model.credibilityNote == nil)

        // An unassessed origin reads in the same shape: "is not assessed", never "is assessed not assessed".
        reply.sourceCredibilityLabel = ""
        store.sourceMoveImpacts["a1"] = reply
        store.sourceMoveTargetCredibility["s3"] = (label: "High trust", weighedAs: "High trust", differs: true)
        model.pick(targetID: "")
        model.pick(targetID: "s3")
        await model.settleReads()
        let unassessed = model.credibilityNote?.message
        #expect(unassessed?.contains("“Census” is not assessed") == true)
        #expect(unassessed?.contains("“Will” is assessed High trust") == true)
        #expect(unassessed?.contains("assessed not assessed") == false)
    }

    @Test
    func readFailureAndReadAgain() async {
        let store = makeStore()
        store.getSourceMoveImpactError = failure()
        let (model, _) = await openedModel(store: store)
        guard case .failed = model.readState else {
            Issue.record("open read: \(model.readState)")
            return
        }
        #expect(!model.canMove)

        store.getSourceMoveImpactError = nil
        model.readAgain()
        await model.settleReads()
        #expect(model.readState == .ready)

        store.getSourceMoveImpactError = failure()
        model.pick(targetID: "s2")
        await model.settleReads()
        guard case .failed = model.readState else {
            Issue.record("pick read: \(model.readState)")
            return
        }
        #expect(!model.canMove)

        store.getSourceMoveImpactError = nil
        let callsBefore = store.getSourceMoveImpactCalls.count
        model.readAgain()
        // Read again shows progress before the reply, though the bundle is still held.
        #expect(model.readState == .loading)
        await model.settleReads()
        #expect(store.getSourceMoveImpactCalls.count == callsBefore + 1)
        #expect(store.getSourceMoveImpactCalls.last?.target == "s2")
        #expect(model.readState == .ready)
        #expect(model.canMove)

        // Clearing the ComboBox reads nothing and dims Move.
        model.pick(targetID: "")
        #expect(store.getSourceMoveImpactCalls.count == callsBefore + 1)
        #expect(!model.canMove)
        #expect(model.credibilityNote == nil)

        // The same pick twice is one read.
        model.pick(targetID: "s2")
        model.pick(targetID: "s2")
        await model.settleReads()
        #expect(store.getSourceMoveImpactCalls.count == callsBefore + 2)
    }

    // MARK: Moving

    @Test
    func moveAppliesBothSourcesAndToasts() async {
        let store = makeStore()
        let (model, session) = await openedModel(store: store)
        // Both Sources' pages are cached, as a Back visit would find them.
        let s1Page: QueryHandle<CatalogSourceWorkspace> = session.query(.sourceWorkspace(project: session.projectKey, sourceId: "s1"))
        let s2Page: QueryHandle<CatalogSourceWorkspace> = session.query(.sourceWorkspace(project: session.projectKey, sourceId: "s2"))
        await waitForQuery(s1Page)
        await waitForQuery(s2Page)
        // The origin's page is the place shown, as it is when Move is clicked: only
        // `apply(_:leavingPage:)` keeps it from reloading before the page is left.
        session.apply(location: .sourcePage(sourceId: "s1"))
        await waitForQuery(s1Page)
        let reads = store.getSourceWorkspaceCalls

        model.pick(targetID: "s2")
        await model.settleReads()
        var left: [String] = []
        let moved = await model.move(leavingPage: { left.append($0.id) })
        await session.settleWrites()

        #expect(moved)
        #expect(left == ["s2"])
        #expect(store.moveToSourceCalls.count == 1)
        #expect(store.moveToSourceCalls.first?.target == "s2")
        #expect(s1Page.isStale)
        #expect(s2Page.isStale)
        #expect(store.getSourceWorkspaceCalls == reads)
        #expect(session.toasts.cards == [ToastCard(
            .success,
            L10n.Sources.moveDoneTitle(target: "Deed"),
            SourceMoveModel.doneBody(artifacts: 2, graphs: 2)
        )])
        #expect(!model.isMoving)
    }

    @Test
    func doneBodyCounts() {
        #expect(SourceMoveModel.doneBody(artifacts: 2, graphs: 2) == "2 Artifacts and 2 graphs")
        #expect(SourceMoveModel.doneBody(artifacts: 1, graphs: 1) == "1 Artifact and 1 graph")
        #expect(SourceMoveModel.doneBody(artifacts: 1, graphs: 0) == "1 Artifact")
        #expect(SourceMoveModel.doneBody(artifacts: 0, graphs: 1) == "1 graph")
    }

    @Test
    func moveFailureKeepsTheDialog() async {
        let store = makeStore()
        let (model, session) = await openedModel(store: store)
        model.pick(targetID: "s2")
        await model.settleReads()
        store.moveToSourceError = failure()
        var left = 0
        let moved = await model.move(leavingPage: { _ in left += 1 })

        #expect(!moved)
        #expect(left == 0)
        #expect(model.moveError == L10n.Errors.message(for: failure()))
        #expect(L10n.Sources.moveFailedMessage(model.moveError ?? "").hasPrefix("Nothing was moved."))
        #expect(model.targetID == "s2")
        #expect(model.impact != nil)
        #expect(session.toasts.cards.isEmpty)
        #expect(model.canMove)
    }
}
