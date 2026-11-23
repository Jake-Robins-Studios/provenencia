import Foundation
import Testing
@testable import Provenencia

@Suite
@MainActor
struct SourceGraphFormModelTests {
    private let projectDir = "/tmp/source-graph-form.provenencia"
    private let userID = "00000000-0000-7000-8000-000000000001"
    private let sourceID = "src-1"

    private struct Boom: Error {}

    /// `a1` – `a<count>` on Source `src-1`, in that page order.
    private func artifacts(_ count: Int) -> [CatalogArtifact] {
        (1...max(count, 1)).prefix(count).map { catalogArtifact("a\($0)", sourceID: "src-1", label: "Page \($0)") }
    }

    private func makeStore(artifactCount: Int, graphs: [CatalogEvidenceGraph]) -> FakeStore {
        let store = FakeStore()
        store.sourcesByProject[projectDir] = [
            CatalogSource(
                id: sourceID, ref: "SRC-AAAAA", sourceTypeID: "t1",
                title: "1851 census", description: ""
            ),
        ]
        store.sourceTypesByProject[projectDir] = [
            CatalogSourceType(
                id: "t1", key: "census", origin: "provenencia", label: "Census", description: ""
            ),
        ]
        store.artifactsBySource[sourceID] = artifacts(artifactCount)
        store.evidenceGraphsByProject[projectDir] = graphs
        store.nextWriteEffects = CatalogWriteEffects(reads: [CatalogWriteEffectsRead(read: .evidenceGraphs, ids: [sourceID])])
        return store
    }

    /// The Source page with its location applied, so the graph list is a
    /// visible key and a graph write's effects refresh it.
    private func makeModel(
        artifactCount: Int = 6,
        graphs: [CatalogEvidenceGraph] = []
    ) async -> (model: SourcePageModel, store: FakeStore, session: WorkspaceSession) {
        let store = makeStore(artifactCount: artifactCount, graphs: graphs)
        let session = WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)
        let model = SourcePageModel(
            sourceID: sourceID, session: session, userID: userID,
            sessionDisplayName: "Jake Robins", store: store
        )
        session.apply(location: WorkspaceLocation.sourcePage(sourceId: sourceID))
        await model.warmFromSession()
        await waitForQuery(session.evidenceGraphsHandle!)
        return (model, store, session)
    }

    /// `g-smith` linked to a3 and a4, with a3 in use by two Citations; the edit form open and loaded.
    private func openSmithEdit(
        store: FakeStore,
        model: SourcePageModel,
        blocks: [CatalogEvidenceGraphUnlinkBlock]? = nil
    ) async -> SourceGraphFormModel? {
        store.unlinkImpactBlocks = blocks ?? [unlinkBlock("a3", graphID: "g-smith", citations: 2)]
        model.graphs.openEdit(id: "g-smith")
        guard let form = model.graphs.form else { return nil }
        await model.graphs.settleFormLoad()
        return form
    }

    private func smith() -> CatalogEvidenceGraph {
        evidenceGraph("g-smith", name: "Smith household", description: "Household 9", artifactIDs: ["a3", "a4"])
    }

    @Test func createPrefillsEveryArtifactChecked() async throws {
        let (model, _, _) = await makeModel()
        await model.graphs.openAdd()
        let form = try #require(model.graphs.form)
        #expect(form.graph == nil)
        #expect(form.draft.name == "")
        #expect(form.checkedArtifactIDs == ["a1", "a2", "a3", "a4", "a5", "a6"])
        #expect(form.loadState == .ready)
        #expect(!form.isDirty)
    }

    @Test func createSavesOneGraphAndToasts() async throws {
        let (model, store, session) = await makeModel()
        await model.graphs.openAdd()
        let form = try #require(model.graphs.form)
        form.draft.name = "Jones household"
        form.draft.description = " Household 14, page 3 "
        form.draft.excludedArtifactIDs = ["a1", "a2", "a4", "a5", "a6"]
        let saved = await form.save()
        #expect(saved)
        #expect(store.createEvidenceGraphCalls == 1)
        #expect(await waitUntil { model.graphs.rows?.contains { $0.name == "Jones household" } == true })
        let created = try #require(model.graphs.rows?.first { $0.name == "Jones household" })
        #expect(created.sourceID == "src-1")
        #expect(created.description == "Household 14, page 3")
        #expect(created.artifactIDs == ["a3"])
        #expect(session.toasts.cards == [ToastCard(
            .success,
            "Evidence graph added",
            "\(created.ref) is ready to open."
        )])
    }

    enum Blocked: CaseIterable, Sendable {
        case blankName
        case noArtifact
    }

    @Test(arguments: Blocked.allCases)
    func blankNameAndNoArtifactBlockSave(_ blocked: Blocked) async throws {
        let (model, store, _) = await makeModel()
        await model.graphs.openAdd()
        let form = try #require(model.graphs.form)
        switch blocked {
        case .blankName:
            form.draft.name = "  "
            let saved = await form.save()
            #expect(!saved)
            #expect(form.nameError == "Give the evidence graph a name.")
            #expect(store.createEvidenceGraphCalls == 0)
        case .noArtifact:
            form.draft.name = "Jones household"
            form.draft.excludedArtifactIDs = Set(["a1", "a2", "a3", "a4", "a5", "a6"])
            #expect(form.needsArtifact)
            #expect(!form.canSave)
            let saved = await form.save()
            #expect(!saved)
            #expect(store.createEvidenceGraphCalls == 0)
        }
    }

    @Test(arguments: [false, true])
    func saveFailureKeepsChoices(edit: Bool) async throws {
        let (model, store, _) = await makeModel(graphs: [smith()])
        let form: SourceGraphFormModel
        if edit {
            store.updateEvidenceGraphError = Boom()
            form = try #require(await openSmithEdit(store: store, model: model, blocks: []))
        } else {
            store.createEvidenceGraphError = Boom()
            await model.graphs.openAdd()
            form = try #require(model.graphs.form)
        }
        form.draft.name = "Renamed"
        form.draft.excludedArtifactIDs.insert("a1")
        let before = form.draft
        let saved = await form.save()
        #expect(!saved)
        #expect(form.saveError != nil)
        #expect(form.draft == before)
    }

    @Test func editPrefillsAndLocksInUseArtifacts() async throws {
        let (model, store, _) = await makeModel(graphs: [smith()])
        let form = try #require(await openSmithEdit(store: store, model: model))
        #expect(store.getEvidenceGraphUnlinkImpactCalls == 1)
        #expect(form.graph?.ref == "GPH-G-SMITH")
        #expect(form.draft.name == "Smith household")
        #expect(form.draft.description == "Household 9")
        #expect(form.draft.excludedArtifactIDs == ["a1", "a2", "a5", "a6"])
        #expect(form.locked == ["a3": "2 citations in this graph use this artifact"])
        #expect(form.blocks.count == 1)
        #expect(form.composerLinkArtifactIDs == ["a3"])
        #expect(form.loadState == .ready)
    }

    @Test func composerLinkOpensTheArtifact() async throws {
        let (model, store, _) = await makeModel(graphs: [smith()])
        let form = try #require(await openSmithEdit(store: store, model: model))
        #expect(form.composerLinkArtifactIDs == ["a3"])
        let location = try #require(form.composerLocation(artifactID: "a3"))
        #expect(location == .citationComposer(
            sourceId: sourceID,
            graphId: "g-smith",
            artifactId: "a3",
            sourceTitle: "1851 census"
        ))

        let (other, _, _) = await makeModel(graphs: [smith()])
        await other.graphs.openAdd()
        let add = try #require(other.graphs.form)
        #expect(add.composerLocation(artifactID: "a3") == nil)
    }

    @Test func editLocksEveryBlock() async throws {
        let (model, store, _) = await makeModel(graphs: [smith()])
        let form = try #require(await openSmithEdit(store: store, model: model, blocks: [
            unlinkBlock("a3", graphID: "g-smith", citations: 1, reason: .artifactInUse),
            unlinkBlock("a4", graphID: "g-smith", citations: 0, reason: .lastArtifact),
        ]))
        #expect(form.locked == [
            "a3": "1 citation in this graph uses this artifact",
            "a4": "An evidence graph needs at least one artifact.",
        ])
        #expect(form.composerLinkArtifactIDs == ["a3"])
        #expect(form.checkedArtifactIDs == ["a3", "a4"])

        let (other, otherStore, _) = await makeModel(graphs: [smith()])
        let lastOnly = try #require(await openSmithEdit(store: otherStore, model: other, blocks: [
            unlinkBlock("a4", graphID: "g-smith", citations: 0, reason: .lastArtifact),
        ]))
        #expect(lastOnly.locked.keys.sorted() == ["a4"])
        #expect(lastOnly.composerLinkArtifactIDs.isEmpty)
    }

    @Test func lockHintCountsCitations() {
        #expect(L10n.Sources.graphLockCitations(count: 1) == "1 citation in this graph uses this artifact")
        #expect(L10n.Sources.graphLockCitations(count: 3) == "3 citations in this graph use this artifact")
        #expect(unlinkBlock("a1", graphID: "g1", citations: 1).lockHint == L10n.Sources.graphLockCitations(count: 1))
        #expect(unlinkBlock("a1", graphID: "g1", citations: 3).lockHint == L10n.Sources.graphLockCitations(count: 3))
    }

    @Test func createPrefillsTheArtifactsInNoGraph() async throws {
        let (model, _, _) = await makeModel(graphs: [
            evidenceGraph("g-default", name: "Default", artifactIDs: ["a1", "a2", "a3", "a4"]),
        ])
        await model.graphs.openAdd()
        let form = try #require(model.graphs.form)
        #expect(form.checkedArtifactIDs == ["a5", "a6"])
        #expect(!form.isDirty)

        let (full, _, _) = await makeModel(graphs: [
            evidenceGraph("g-default", name: "Default", artifactIDs: ["a1", "a2", "a3", "a4", "a5", "a6"]),
        ])
        await full.graphs.openAdd()
        let fullForm = try #require(full.graphs.form)
        #expect(fullForm.checkedArtifactIDs == ["a1", "a2", "a3", "a4", "a5", "a6"])
        #expect(!fullForm.isDirty)
    }

    @Test func editSavesNameAndFullLinkSet() async throws {
        let (model, store, session) = await makeModel(graphs: [smith()])
        let form = try #require(await openSmithEdit(store: store, model: model))
        form.draft.name = "Smith family"
        form.draft.excludedArtifactIDs.insert("a4")
        form.draft.excludedArtifactIDs.remove("a5")
        let saved = await form.save()
        #expect(saved)
        #expect(store.updateEvidenceGraphCalls == 1)
        #expect(await waitUntil { model.graphs.rows?.contains { $0.name == "Smith family" } == true })
        let updated = try #require(model.graphs.rows?.first { $0.id == "g-smith" })
        #expect(updated.artifactIDs == ["a3", "a5"])
        #expect(session.toasts.cards.isEmpty)
    }

    @Test func editRefusedInUseRereadsKeptLinks() async throws {
        let linked = evidenceGraph("g-pair", name: "Pair", artifactIDs: ["a2", "a3"])
        let (model, store, _) = await makeModel(graphs: [linked])
        store.unlinkImpactBlocks = []
        model.graphs.openEdit(id: "g-pair")
        let form = try #require(model.graphs.form)
        await model.graphs.settleFormLoad()
        #expect(form.locked.isEmpty)
        form.draft.excludedArtifactIDs.insert("a2")
        store.updateEvidenceGraphError = CoreInvokeError.coded(
            status: 1, code: "evidencegraphs.artifact_in_use", kind: .conflict, params: []
        )
        store.unlinkImpactBlocks = [unlinkBlock("a2", graphID: "g-pair", citations: 1)]
        let before = form.draft
        let saved = await form.save()
        #expect(!saved)
        #expect(form.saveError != nil)
        #expect(form.draft == before)
        #expect(form.locked.keys.contains("a2"))
        #expect(form.checkedArtifactIDs.contains("a2"))
    }

    @Test func editRefusedArtifactInUseRereadsKeptLinks() async throws {
        let linked = evidenceGraph("g-pair", name: "Pair", artifactIDs: ["a2", "a3"])
        let (model, store, _) = await makeModel(graphs: [linked])
        store.unlinkImpactBlocks = []
        model.graphs.openEdit(id: "g-pair")
        let form = try #require(model.graphs.form)
        await model.graphs.settleFormLoad()
        form.draft.excludedArtifactIDs.insert("a2")
        store.updateEvidenceGraphError = CoreInvokeError.coded(
            status: 1, code: "evidencegraphs.artifact_in_use", kind: .conflict, params: []
        )
        store.unlinkImpactBlocks = [unlinkBlock("a2", graphID: "g-pair", citations: 1, reason: .artifactInUse)]
        let calls = store.getEvidenceGraphUnlinkImpactCalls
        let saved = await form.save()
        #expect(!saved)
        #expect(store.getEvidenceGraphUnlinkImpactCalls == calls + 1)
        #expect(form.saveError != nil)
        #expect(form.locked["a2"] == "1 citation in this graph uses this artifact")
        #expect(form.checkedArtifactIDs.contains("a2"))

        // A refusal with no code re-reads too and keeps the refusal in view.
        store.updateEvidenceGraphError = CoreInvokeError.failed(status: 3)
        let again = store.getEvidenceGraphUnlinkImpactCalls
        let savedAgain = await form.save()
        #expect(!savedAgain)
        #expect(store.getEvidenceGraphUnlinkImpactCalls == again + 1)
        #expect(form.saveError != nil)
    }

    @Test func editPreflightFailureThenReadAgain() async throws {
        let (model, store, _) = await makeModel(graphs: [smith()])
        store.getEvidenceGraphUnlinkImpactError = Boom()
        store.unlinkImpactBlocks = [unlinkBlock("a3", graphID: "g-smith", citations: 2)]
        model.graphs.openEdit(id: "g-smith")
        let form = try #require(model.graphs.form)
        await model.graphs.settleFormLoad()
        guard case .failed = form.loadState else {
            Issue.record("expected a failed load, got \(form.loadState)")
            return
        }
        #expect(!form.canSave)
        store.getEvidenceGraphUnlinkImpactError = nil
        await form.loadKeptLinks()
        #expect(form.loadState == .ready)
        #expect(store.getEvidenceGraphUnlinkImpactCalls == 2)
    }

    @Test func editDefaultWithNoArtifactsKeepsLinks() async throws {
        let (model, store, _) = await makeModel(
            artifactCount: 0,
            graphs: [evidenceGraph("g-default", name: "Default")]
        )
        model.graphs.openEdit(id: "g-default")
        let form = try #require(model.graphs.form)
        #expect(store.getEvidenceGraphUnlinkImpactCalls == 0)
        #expect(form.canSave)
        form.draft.name = "Whole census"
        let saved = await form.save()
        #expect(saved)
        #expect(await waitUntil { model.graphs.rows?.first?.name == "Whole census" })
        #expect(model.graphs.rows?.first?.artifactIDs == [])
    }

    // MARK: Metadata (S15-11)

    private let itemField = catalogMetadataField("item", label: "Item")
    private let lineField = catalogMetadataField("line", label: "Line")
    private let dwellingField = catalogMetadataField("dwelling", label: "Dwelling")
    private let familyField = catalogMetadataField("family", label: "Family")
    private let folioField = catalogMetadataField("folio", label: "Folio")

    private var graphOwner: MetadataOwner { MetadataOwner(level: .graph, id: "g-smith") }

    /// A page whose draft board for a new graph is Item, Line, Dwelling and Family, empty and suggested.
    private func makeSuggestingModel(
        graphs: [CatalogEvidenceGraph] = []
    ) async -> (model: SourcePageModel, store: FakeStore, session: WorkspaceSession) {
        let store = makeStore(artifactCount: 6, graphs: graphs)
        store.fieldsByProject[projectDir] = [itemField, lineField, dwellingField, familyField, folioField]
        store.draftMetadataBoardEntries["\(sourceID)/graph"] = [itemField, lineField, dwellingField, familyField]
            .enumerated().map { catalogMetadataEntry($1, suggested: true, order: Int32($0)) }
        let session = WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)
        let model = SourcePageModel(
            sourceID: sourceID, session: session, userID: userID,
            sessionDisplayName: "Jake Robins", store: store
        )
        session.apply(location: WorkspaceLocation.sourcePage(sourceId: sourceID))
        await model.warmFromSession()
        await waitForQuery(session.evidenceGraphsHandle!)
        return (model, store, session)
    }

    /// Smith's board as the engine answers it: three values and Family suggested.
    private func smithRows(line: String = "14") -> [CatalogMetadataEntry] {
        [
            catalogMetadataEntry(itemField, "3", suggested: true, order: 0),
            catalogMetadataEntry(lineField, line, suggested: true, order: 1),
            catalogMetadataEntry(dwellingField, "112", suggested: true, order: 2),
            catalogMetadataEntry(familyField, suggested: true, order: 3),
        ]
    }

    @Test func openAddReadsTheDraftBoard() async throws {
        let (model, store, _) = await makeSuggestingModel()
        let form = try #require(await model.graphs.openAdd())
        #expect(model.graphs.form === form)
        #expect(form.board.entries.map(\.field.id) == ["item", "line", "dwelling", "family"])
        #expect(form.board.entries.allSatisfy { $0.suggested && !$0.hasValue })
        #expect(store.draftMetadataBoardCalls.map(\.level) == [.graph])
        #expect(store.draftMetadataBoardCalls.map(\.sourceID) == [sourceID])
        #expect(form.scrollTarget == nil)
        #expect(!form.isDirty)
    }

    @Test func openAddFailureShowsBanner() async {
        let (model, store, _) = await makeSuggestingModel()
        let error = CoreInvokeError.failed(status: 3)
        store.draftMetadataBoardError = error
        let opened = await model.graphs.openAdd()
        #expect(opened == nil)
        #expect(model.graphs.form == nil)
        #expect(model.pageError?.message == L10n.Errors.message(for: error))
    }

    @Test func secondAddWhileReadingOpensNothing() async throws {
        let (model, store, _) = await makeSuggestingModel()
        store.draftMetadataBoardHold.isOn = true
        let first = Task { await model.graphs.openAdd() }
        await store.draftMetadataBoardHold.untilSuspended(1)
        let second = Task { await model.graphs.openAdd() }
        #expect(!(await waitUntil(timeout: .milliseconds(300)) { store.draftMetadataBoardHold.count == 2 }))
        store.draftMetadataBoardHold.release()
        store.draftMetadataBoardHold.release()
        #expect(await second.value == nil)
        #expect(await first.value != nil)
        #expect(store.draftMetadataBoardCalls.map(\.level) == [.graph])
    }

    @Test func dropDuringGraphAddReadIsRefused() async throws {
        let (model, store, _) = await makeSuggestingModel()
        store.draftMetadataBoardHold.isOn = true
        let first = Task { await model.graphs.openAdd() }
        await store.draftMetadataBoardHold.untilSuspended(1)
        #expect(!model.acceptsArtifactPageDrop)
        store.draftMetadataBoardHold.release()
        #expect(await first.value != nil)
    }

    @Test func graphFormOpenRefusesDrop() async throws {
        let (model, store, _) = await makeSuggestingModel(graphs: [smith()])
        store.unlinkImpactBlocks = []
        #expect(model.acceptsArtifactPageDrop)
        model.graphs.openEdit(id: "g-smith")
        #expect(model.graphs.form != nil)
        #expect(!model.acceptsArtifactPageDrop)
    }

    @Test func createSendsTheDraft() async throws {
        let (model, store, session) = await makeSuggestingModel()
        let form = try #require(await model.graphs.openAdd())
        form.draft.name = "Jones household"
        form.board.drafts["line"] = "14"
        await form.board.save(fieldID: "line")
        form.board.drafts["dwelling"] = "112"
        await form.board.save(fieldID: "dwelling")
        let rows = [
            catalogMetadataEntry(lineField, "14", suggested: true, order: 1),
            catalogMetadataEntry(dwellingField, "112", suggested: true, order: 2),
        ]
        store.nextEvidenceGraphID = "g-made"
        store.metadataWriteResults[MetadataOwner(level: .graph, id: "g-made")] = rows
        let getBefore = store.getSourceWorkspaceCalls
        #expect(form.isDirty)

        #expect(await form.save())

        let sent = try #require(store.createEvidenceGraphMetadata.last ?? nil)
        #expect(sent.values.map(\.fieldID) == ["line", "dwelling"])
        #expect(sent.layout.count == 4)
        let made = try #require(store.evidenceGraphsByProject[projectDir]?.last)
        let owner = MetadataOwner(level: .graph, id: made.id)
        #expect(model.metadataRows(for: MetadataOwner(level: .graph, id: made.id)) == rows)
        let key = CatalogQueryKey.sourceWorkspace(project: session.projectKey, sourceId: sourceID)
        let cached: QueryHandle<CatalogSourceWorkspace>? = session.queryHandle(key)
        #expect(cached?.value?.metadataRows(for: owner) == rows)
        #expect(store.getSourceWorkspaceCalls == getBefore)
    }

    @Test func editSavesTheDraft() async throws {
        let smith = smith()
        let (model, store, _) = await makeSuggestingModel(graphs: [smith])
        store.metadataByOwner[graphOwner] = smithRows()
        await model.warmFromSession()
        store.unlinkImpactBlocks = []
        model.graphs.openEdit(id: "g-smith")
        let form = try #require(model.graphs.form)
        await model.graphs.settleFormLoad()
        #expect(form.host.entries.map(\.field.id) == ["item", "line", "dwelling", "family"])
        #expect(form.host.entries.filter(\.hasValue).map(\.field.id) == ["item", "line", "dwelling"])
        #expect(!form.isDirty)

        form.board.drafts["line"] = "15"
        await form.board.save(fieldID: "line")
        form.board.openAddRow()
        form.board.pickAddRowField("folio")
        form.board.setAddRowValue("236")
        await form.board.confirmAddRow()
        var written = smithRows(line: "15")
        written.append(catalogMetadataEntry(folioField, "236", order: 4))
        store.metadataWriteResults[graphOwner] = written
        let getBefore = store.getSourceWorkspaceCalls
        #expect(form.isDirty)

        #expect(await form.save())

        #expect(store.updateEvidenceGraphCalls == 1)
        let sent = try #require(store.updateEvidenceGraphMetadata.last ?? nil)
        #expect(sent.values.map(\.fieldID).contains("folio"))
        #expect(model.metadataRows(for: MetadataOwner(level: .graph, id: "g-smith")) == written)
        #expect(store.getSourceWorkspaceCalls == getBefore)
    }

    @Test func nameOnlyEditSendsNoMetadata() async throws {
        let (model, store, _) = await makeSuggestingModel(graphs: [smith()])
        store.metadataByOwner[graphOwner] = smithRows()
        await model.warmFromSession()
        store.unlinkImpactBlocks = []
        model.graphs.openEdit(id: "g-smith")
        let form = try #require(model.graphs.form)
        await model.graphs.settleFormLoad()
        form.draft.name = "Smith family"
        let reply = smithRows(line: "99")
        store.metadataWriteResults[graphOwner] = reply

        #expect(await form.save())

        #expect(store.updateEvidenceGraphMetadata.count == 1)
        #expect(store.updateEvidenceGraphMetadata[0] == nil)
        #expect(model.metadataRows(for: MetadataOwner(level: .graph, id: "g-smith")) == reply)
    }

    @Test func openFieldBlocksSave() async throws {
        let (model, store, _) = await makeSuggestingModel(graphs: [smith()])
        store.unlinkImpactBlocks = []
        model.graphs.openEdit(id: "g-smith")
        let form = try #require(model.graphs.form)
        await model.graphs.settleFormLoad()
        form.board.openAddRow()
        form.board.pickAddRowField("folio")
        form.board.setAddRowValue("236")
        let opened = form.scrollRequest
        #expect(form.isDirty)

        #expect(await form.save() == false)

        #expect(form.saveError == L10n.string(L10n.Sources.metadataFinishOpenField))
        #expect(form.scrollTarget == .top)
        #expect(form.scrollRequest != opened)
        #expect(store.updateEvidenceGraphCalls == 0)
    }

    @Test func nameStopClearsAnOldOpenFieldMessage() async throws {
        let (model, store, _) = await makeSuggestingModel(graphs: [smith()])
        store.unlinkImpactBlocks = []
        model.graphs.openEdit(id: "g-smith")
        let form = try #require(model.graphs.form)
        await model.graphs.settleFormLoad()
        form.board.openAddRow()
        form.board.pickAddRowField("folio")
        form.board.setAddRowValue("236")
        #expect(await form.save() == false)
        #expect(form.saveError != nil)

        form.board.closeAddRow()
        form.draft.name = " "
        #expect(await form.save() == false)

        #expect(form.nameError != nil)
        #expect(form.saveError == nil)
    }

    @Test func refusedValueLandsOnItsRow() async throws {
        let (model, store, _) = await makeSuggestingModel(graphs: [smith()])
        store.metadataByOwner[graphOwner] = smithRows()
        await model.warmFromSession()
        store.unlinkImpactBlocks = []
        model.graphs.openEdit(id: "g-smith")
        let form = try #require(model.graphs.form)
        await model.graphs.settleFormLoad()
        form.board.drafts["line"] = "fourteen"
        await form.board.save(fieldID: "line")
        store.updateEvidenceGraphError = catalogMetadataRefusal(params: ["line"])

        #expect(await form.save() == false)

        #expect(model.graphs.form === form)
        #expect(form.board.fieldErrorID == "line")
        #expect(form.board.fieldError != nil)
        #expect(form.saveError == nil)
        #expect(form.host.entries.first { $0.field.id == "line" }?.valueText == "fourteen")
    }

    @Test func moreOpensAtMetadata() async throws {
        let (model, store, _) = await makeSuggestingModel(graphs: [smith()])
        store.unlinkImpactBlocks = []
        model.graphs.openEdit(id: "g-smith", at: .metadata)
        let form = try #require(model.graphs.form)
        #expect(form.opensAt == .metadata)
        #expect(form.scrollTarget == .metadata)
        model.graphs.form = nil
        model.graphs.openEdit(id: "g-smith")
        #expect(model.graphs.form?.scrollTarget == nil)
        // A graph gone since the row drew opens nothing.
        model.graphs.form = nil
        model.graphs.openEdit(id: "g-gone", at: .metadata)
        #expect(model.graphs.form == nil)
    }

    @Test func dirtyFormAsksOnOutsideClick() async throws {
        let (model, store, _) = await makeSuggestingModel(graphs: [smith()])
        store.metadataByOwner[graphOwner] = smithRows()
        await model.warmFromSession()
        store.unlinkImpactBlocks = []
        model.graphs.openEdit(id: "g-smith")
        let form = try #require(model.graphs.form)
        await model.graphs.settleFormLoad()
        #expect(PVSheetDismiss.action(isRunning: false, isDirty: form.isDirty, isConfirmingDiscard: false) == .close)
        form.board.drafts["line"] = "15"
        await form.board.save(fieldID: "line")
        #expect(PVSheetDismiss.action(isRunning: false, isDirty: form.isDirty, isConfirmingDiscard: false) == .confirmDiscard)
        // Cancel drops the form with nothing written.
        model.graphs.form = nil
        #expect(store.updateEvidenceGraphCalls == 0)
    }
}
