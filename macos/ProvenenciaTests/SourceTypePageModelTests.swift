import Foundation
import Testing
@testable import Provenencia

@Suite
@MainActor
struct SourceTypePageModelTests {
    private let projectDir = "/tmp/type-page.provenencia"
    private let userID = "00000000-0000-7000-8000-000000000001"

    /// The page model of `typeID`, its three reads warmed and settled and its draft synced, as the
    /// view's `.task` and `.onChange` leave it.
    private func makePageModel(
        typeID: String,
        store: FakeStore = FakeStore(),
        types: [CatalogSourceType] = [],
        fields: [CatalogMetadataField] = [],
        suggestions: [Level: [String: [CatalogTypeSuggestion]]] = [:]
    ) async -> (SourceTypePageModel, WorkspaceSession) {
        store.sourceTypesByProject[projectDir] = types
        store.fieldsByProject[projectDir] = fields
        store.suggestionsByLevel = suggestions
        let session = WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)
        let model = SourceTypePageModel(typeID: typeID, session: session, userID: userID, store: store)
        model.warm()
        if let handle = model.typesHandle { await waitForQuery(handle) }
        let fieldsHandle: QueryHandle<[CatalogMetadataField]>? = session.queryHandle(
            .metadataFieldsList(project: session.projectKey)
        )
        if let fieldsHandle { await waitForQuery(fieldsHandle) }
        if let handle = model.suggestionsHandle { await waitForQuery(handle) }
        model.syncDraft()
        return (model, session)
    }

    // MARK: Details

    @Test func seededOrUserTypeEditsAndPluginTypeLocks() async {
        let types = [seededSourceType(), userSourceType(), pluginSourceType()]
        let (book, _) = await makePageModel(typeID: "t1", types: types)
        #expect(!book.isLocked)
        #expect(book.canEditAssociations)

        let (grave, _) = await makePageModel(typeID: "t3", types: types)
        #expect(grave.isLocked)
        #expect(!grave.canEditAssociations)
        #expect(grave.type != nil)
    }

    /// T-8 (AC-2.5): a plugin's type is locked, has nothing to save, and can still be deleted.
    @Test func pluginTypeIsLocked() async {
        let (model, _) = await makePageModel(typeID: "t3", types: [pluginSourceType()])
        #expect(model.isLocked)
        #expect(!model.isDirty)
        model.draft?.label = "Edited"
        #expect(!model.isDirty)
        #expect(!model.canSubmit)
        await model.submit()
        #expect(model.type?.label == "Grave memorial")
        #expect(model.deleteAccessibilityLabel == L10n.SourceTypes.deleteTypeAccessibility(label: "Grave memorial"))
    }

    /// AC-2.1: nothing changed, nothing to save or revert.
    @Test func aCleanDraftCannotBeSaved() async {
        let (model, _) = await makePageModel(typeID: "t1", types: [seededSourceType()])
        #expect(model.draft?.label == "Book")
        #expect(!model.isDirty)
        #expect(!model.canSubmit)
    }

    /// T-8 (AC-2.2): Save patches the row, keeps the key and toasts.
    @Test func saveUpdatesTheRowAndKeepsTheKey() async {
        let store = FakeStore()
        let (model, session) = await makePageModel(typeID: "t1", store: store, types: [seededSourceType()])
        model.draft?.label = "Population census"
        #expect(model.isDirty)
        #expect(model.canSubmit)
        await model.submit()

        #expect(model.type?.label == "Population census")
        #expect(model.type?.key == "book")
        #expect(session.sourceType(id: "t1")?.label == "Population census")
        #expect(store.sourceTypesByProject[projectDir]?.first?.label == "Population census")
        #expect(model.draft?.label == "Population census")
        #expect(!model.isDirty)
        #expect(model.toast?.title == L10n.string(L10n.SourceTypes.toastUpdatedTitle))
    }

    /// T-8 (AC-2.3): a blank label shows the required message and writes nothing.
    @Test func blankLabelRefusesSave() async {
        let store = FakeStore()
        let (model, _) = await makePageModel(typeID: "t1", store: store, types: [seededSourceType()])
        model.editLabel("   ")
        #expect(!model.canSubmit)
        await model.submit()

        #expect(model.labelError == L10n.string(L10n.SourceTypes.errorLabelRequired))
        #expect(model.saveError == nil)
        #expect(store.sourceTypesByProject[projectDir]?.first?.label == "Book")
        #expect(model.toast == nil)
    }

    /// UX-1: clearing the label shows the required message as the researcher edits, and typing a
    /// label clears it.
    @Test func clearingTheLabelShowsTheRequiredMessage() async {
        let (model, _) = await makePageModel(typeID: "t1", types: [seededSourceType()])
        model.editLabel("")
        #expect(model.labelError == L10n.string(L10n.SourceTypes.errorLabelRequired))
        #expect(!model.canSubmit)

        model.editLabel("Tome")
        #expect(model.labelError == nil)
        #expect(model.canSubmit)
    }

    /// UX-2: a failed write is a save error, not a Label error.
    @Test func aStoreFailureOnSaveIsNotALabelError() async {
        let store = FakeStore()
        let (model, _) = await makePageModel(typeID: "t1", store: store, types: [seededSourceType()])
        store.sourceTypesByProject[projectDir] = []
        model.editLabel("Tome")
        await model.submit()

        #expect(model.labelError == nil)
        #expect(model.saveError != nil)
        #expect(model.toast == nil)

        model.revertEdit()
        #expect(model.saveError == nil)
    }

    /// UX-3: a type deleted elsewhere leaves with a notice that names it.
    @Test func goneTypeNamesItselfInTheNotice() async {
        let (model, session) = await makePageModel(typeID: "t1", types: [seededSourceType()])
        model.noteLabel(model.type?.label)
        #expect(model.goneNotice == nil)

        session.apply(.deletedSourceType(id: "t1"))
        model.noteLabel(model.type?.label)
        #expect(model.isGone)
        #expect(model.goneNotice == L10n.SourceTypes.goneNotice(label: "Book"))
    }

    /// UX-8: a type gone before the page ever named it gets a notice without an empty label.
    @Test func aTypeGoneBeforeItWasShownGetsAnUnnamedNotice() async {
        let (model, _) = await makePageModel(typeID: "missing", types: [seededSourceType()])
        model.noteLabel(model.type?.label)
        #expect(model.isGone)
        #expect(model.goneNotice == L10n.string(L10n.SourceTypes.goneNoticeUnnamed))
        #expect(model.goneNotice?.contains("“”") == false)
    }

    @Test func changingIconMarksDirtyAndPersists() async {
        let (model, _) = await makePageModel(typeID: "t2", types: [userSourceType()])
        #expect(model.draft?.iconKey == PVMarkKey.defaultTypeMark.rawValue)

        model.draft?.iconKey = "type_scrapbook"
        #expect(model.isDirty)
        await model.submit()

        #expect(model.type?.iconKey == "type_scrapbook")
        #expect(!model.isDirty)
    }

    @Test func applyDraftIconKeyUpdatesPendingPickerSelection() async {
        let (model, _) = await makePageModel(typeID: "t2", types: [userSourceType()])
        let before = model.draft?.iconKey
        #expect(before == PVMarkKey.defaultTypeMark.rawValue)

        model.applyDraftIconKey("type_photograph")
        #expect(model.draft?.iconKey == "type_photograph")
        #expect(model.isDirty)

        // Cancel path: caller simply discards pending UI state; draft unchanged
        // until applyDraftIconKey. Reverting restores the saved icon.
        model.revertEdit()
        #expect(model.draft?.iconKey == before)
        #expect(!model.isDirty)
    }

    /// T-8 (AC-2.4): Revert brings the saved values back.
    @Test func revertRestoresTheSavedValues() async {
        let (model, _) = await makePageModel(typeID: "t2", types: [userSourceType()])
        model.draft?.description = "Changed"
        #expect(model.isDirty)
        model.revertEdit()

        #expect(!model.isDirty)
        #expect(model.draft == SourceTypeDraft(label: "Family scrapbook", description: "Nan's albums."))
    }

    /// T-8 (AC-2.6, D-4): a list reload leaves a dirty draft alone.
    @Test func aListReloadKeepsTheDraft() async {
        let store = FakeStore()
        let (model, session) = await makePageModel(typeID: "t2", store: store, types: [userSourceType()])
        model.draft?.description = "Changed"

        var renamed = userSourceType()
        renamed.label = "Scrapbook"
        store.sourceTypesByProject[projectDir] = [renamed]
        session.apply(CatalogWriteEffects(lists: [.sourceVocabulary]))
        await session.settleWrites()
        model.syncDraft()

        #expect(model.type?.label == "Scrapbook")
        #expect(model.draft?.description == "Changed")
        #expect(model.draft?.label == "Family scrapbook")
    }

    /// A Save that reports no effects reloads no list, and one that reports the vocabulary
    /// reloads each list once.
    @Test func aSaveWithNoEffectsReloadsNothing() async {
        let store = FakeStore()
        let (model, session) = await makePageModel(
            typeID: "t1", store: store, types: [seededSourceType()], fields: [catalogMetadataField("f1", label: "Author")]
        )
        let fieldsHandle: QueryHandle<[CatalogMetadataField]>? = session.queryHandle(
            .metadataFieldsList(project: session.projectKey)
        )
        store.fieldsByProject[projectDir] = [catalogMetadataField("f9", label: "Later")]
        store.nextWriteEffects = .empty
        model.draft?.description = "edited"
        await model.submit()
        await session.settleWrites()
        #expect(fieldsHandle?.value?.map(\.id) == ["f1"])

        store.nextWriteEffects = CatalogWriteEffects(lists: [.sourceVocabulary])
        model.draft?.description = "edited again"
        await model.submit()
        await session.settleWrites()
        #expect(fieldsHandle?.value?.map(\.id) == ["f9"])
    }

    // MARK: Presence

    /// T-6 (AC-1.7): the model reads gone only once a settled list lacks its type.
    @Test func aGoneTypeIsGone() async {
        let store = FakeStore()
        store.sourceTypesByProject[projectDir] = [seededSourceType()]
        let session = WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)
        let model = SourceTypePageModel(typeID: "missing", session: session, userID: userID, store: store)
        #expect(!model.isGone)
        model.warm()
        #expect(!model.isGone)
        if let handle = model.typesHandle { await waitForQuery(handle) }
        #expect(model.isGone)

        let present = SourceTypePageModel(typeID: "t1", session: session, userID: userID, store: store)
        #expect(!present.isGone)
        #expect(present.type?.label == "Book")
    }

    // MARK: Suggestions

    @Test func warmingLoadsThatTypesSuggestionsInStoredOrder() async {
        let author = catalogMetadataField("f1", label: "Author")
        let publisher = catalogMetadataField("f2", label: "Publisher")
        let (model, _) = await makePageModel(
            typeID: "t1",
            types: [seededSourceType()],
            fields: [author, publisher],
            // Publisher was assigned first, so stored order and label order disagree.
            suggestions: [.source: ["t1": [
                CatalogTypeSuggestion(field: publisher, sortOrder: 0),
                CatalogTypeSuggestion(field: author, sortOrder: 1),
            ]]]
        )
        #expect(model.suggestions.map(\.field.label) == ["Publisher", "Author"])
    }

    @Test func assignPoolExcludesFieldsAlreadySuggested() async {
        let author = catalogMetadataField("f1", label: "Author")
        let (model, _) = await makePageModel(
            typeID: "t1",
            types: [seededSourceType()],
            fields: [author, catalogMetadataField("f2", label: "Publisher")],
            suggestions: [.source: ["t1": [CatalogTypeSuggestion(field: author, sortOrder: 0)]]]
        )
        #expect(model.assignPool.map(\.id) == ["f2"])
    }

    /// T-8 (AC-3.1): assigning patches the cache and reloads nothing.
    @Test func assigningAppendsTheFieldAndUpdatesTheListCount() async {
        let store = FakeStore()
        let (model, session) = await makePageModel(
            typeID: "t1",
            store: store,
            types: [seededSourceType()],
            fields: [catalogMetadataField("f1", label: "Author"), catalogMetadataField("f2", label: "Publisher")]
        )
        let loads = store.listTypeSuggestionsLevels.count

        model.assignPick = "f2"
        await model.assignPickedField()
        model.assignPick = "f1"
        await model.assignPickedField()
        await session.settleWrites()

        #expect(model.suggestions.map(\.field.id) == ["f2", "f1"])
        #expect(model.assignPick.isEmpty)
        #expect(session.sourceType(id: "t1")?.suggestedFieldCount == 2)
        #expect(model.toast?.title == L10n.string(L10n.SourceTypes.toastAssignedTitle))
        #expect(store.listTypeSuggestionsLevels.count == loads)
    }

    @Test func warmingShowsOnlySourceLevelSuggestions() async {
        let author = catalogMetadataField("f1", label: "Author")
        let publisher = catalogMetadataField("f2", label: "Publisher")
        let store = FakeStore()
        store.suggestionsByLevel[.graph] = ["t1": [CatalogTypeSuggestion(field: publisher, sortOrder: 0)]]
        let (model, _) = await makePageModel(
            typeID: "t1",
            store: store,
            types: [seededSourceType()],
            fields: [author, publisher],
            suggestions: [.source: ["t1": [CatalogTypeSuggestion(field: author, sortOrder: 0)]]]
        )
        #expect(model.suggestions.map(\.field.id) == ["f1"])
    }

    @Test func assigningWritesAtSourceLevelOnly() async {
        let author = catalogMetadataField("f1", label: "Author")
        let publisher = catalogMetadataField("f2", label: "Publisher")
        let store = FakeStore()
        let graphRow = CatalogTypeSuggestion(field: publisher, sortOrder: 0)
        let (model, session) = await makePageModel(
            typeID: "t1",
            store: store,
            types: [seededSourceType()],
            fields: [author, publisher]
        )
        store.suggestionsByLevel[.graph] = ["t1": [graphRow]]

        model.assignPick = "f1"
        await model.assignPickedField()

        #expect(store.suggestionsByLevel[.source]?["t1"]?.map(\.field.id) == ["f1"])
        #expect(store.suggestionsByLevel[.graph]?["t1"] == [graphRow])
        #expect(session.sourceType(id: "t1")?.suggestedFieldCount == 1)
    }

    @Test func fieldsColumnShowsTheEnginesCountNotTheReplyLength() async {
        let author = catalogMetadataField("f1", label: "Author")
        let store = FakeStore()
        store.suggestedFieldCountOverride["t1"] = 7
        let (model, session) = await makePageModel(
            typeID: "t1",
            store: store,
            types: [seededSourceType()],
            fields: [author]
        )

        model.assignPick = "f1"
        await model.assignPickedField()

        #expect(model.suggestions.count == 1)
        #expect(session.sourceType(id: "t1")?.suggestedFieldCount == 7)
    }

    /// T-8 (AC-3.2): removing patches the cache; the field stays in the pool.
    @Test func removingASuggestionKeepsTheFieldInThePool() async {
        let author = catalogMetadataField("f1", label: "Author", usedBy: 3)
        let (model, session) = await makePageModel(
            typeID: "t1",
            types: [seededSourceType()],
            fields: [author],
            suggestions: [.source: ["t1": [CatalogTypeSuggestion(field: author, sortOrder: 0)]]]
        )

        await model.removeSuggestion(fieldID: "f1")

        #expect(model.suggestions.isEmpty)
        #expect(session.sourceType(id: "t1")?.suggestedFieldCount == 0)
        // The vocabulary row survives, so the field is assignable again.
        #expect(model.assignPool.map(\.id) == ["f1"])
        #expect(model.toast?.title == L10n.string(L10n.SourceTypes.toastRemovedTitle))
        // T-20: the copy must not imply the existing values went with it.
        #expect(model.toast?.body.contains("3") == true)
    }

    @Test func removingASuggestionNoSourceUsesOmitsTheValueCount() async {
        let author = catalogMetadataField("f1", label: "Author")
        let (model, _) = await makePageModel(
            typeID: "t1",
            types: [seededSourceType()],
            fields: [author],
            suggestions: [.source: ["t1": [CatalogTypeSuggestion(field: author, sortOrder: 0)]]]
        )

        await model.removeSuggestion(fieldID: "f1")
        #expect(model.toast?.body == L10n.SourceTypes.toastRemovedBody(field: "Author", type: "Book", valueCount: 0))
    }

    // MARK: Delete

    @Test func deleteIsOfferedForEveryOrigin() async {
        let types = [
            userSourceType(id: "t2", label: "Family scrapbook", usedBy: 0),
            seededSourceType(id: "t1", label: "Book", usedBy: 26),
            pluginSourceType(),
        ]
        for (id, label) in [("t2", "Family scrapbook"), ("t1", "Book"), ("t3", "Grave memorial")] {
            let (model, _) = await makePageModel(typeID: id, types: types)
            #expect(model.type != nil)
            #expect(model.deleteTooltip == L10n.SourceTypes.deleteType)
            #expect(model.deleteAccessibilityLabel == L10n.SourceTypes.deleteTypeAccessibility(label: label))
        }
    }

    @Test func unusedUserTypeConfirmDeletes() async {
        let store = FakeStore()
        let (model, _) = await makePageModel(typeID: "t2", store: store, types: [userSourceType()])
        await model.askDelete()

        #expect(model.pendingImpact?.report.allowed == true)
        #expect(model.pendingImpact?.target.kind == "source_type")
        #expect(await model.confirmDelete(leaving: {}))
        #expect(store.sourceTypesByProject[projectDir]?.isEmpty == true)
    }

    @Test func unusedSeededTypeConfirmDeletes() async {
        let store = FakeStore()
        let (model, _) = await makePageModel(typeID: "t1", store: store, types: [seededSourceType()])
        await model.askDelete()

        #expect(model.pendingImpact?.report.allowed == true)
        #expect(await model.confirmDelete(leaving: {}))
        #expect(store.sourceTypesByProject[projectDir]?.isEmpty == true)
    }

    @Test func typeUsedByTwoSourcesShowsInboundNotice() async {
        let store = FakeStore()
        store.sourcesByProject[projectDir] = [
            CatalogSource(id: "s1", ref: "SRC-AAAAA", sourceTypeID: "t1", title: "Parish", description: ""),
            CatalogSource(id: "s2", ref: "SRC-BBBBB", sourceTypeID: "t1", title: "Census", description: ""),
        ]
        let (model, session) = await makePageModel(typeID: "t1", store: store, types: [seededSourceType(usedBy: 2)])
        await model.askDelete()

        let report = model.pendingImpact?.report
        #expect(report?.allowed == false)
        #expect(report?.gate == .inbound)
        #expect(report?.groups.first?.via == "sources.source_type_id")
        #expect(report?.groups.first?.total == 2)
        #expect(report?.groups.first?.total == model.type?.usedBy)
        #expect(report?.groups.first?.listed.map(\.ref) == ["SRC-AAAAA", "SRC-BBBBB"])
        var left = 0
        #expect(await model.confirmDelete(leaving: { left += 1 }) == false)
        #expect(left == 0)
        #expect(store.sourceTypesByProject[projectDir]?.map(\.id) == ["t1"])
        #expect(session.sourceType(id: "t1") != nil)
    }

    @Test func pluginTypeOriginLockedTrashStillOffered() async {
        let store = FakeStore()
        let (model, _) = await makePageModel(typeID: "t3", store: store, types: [pluginSourceType(usedBy: 0)])
        await model.askDelete()

        #expect(model.pendingImpact?.report.allowed == false)
        #expect(model.pendingImpact?.report.gate == .originLocked)
        #expect(await model.confirmDelete(leaving: {}) == false)
        #expect(store.sourceTypesByProject[projectDir]?.map(\.id) == ["t3"])
    }

    /// T-10 (AC-5.1, AC-5.3): Delete drops the row, leaves once and toasts nothing, with or
    /// without unsaved details.
    @Test func deletingLeavesAndDropsTheRow() async {
        for dirty in [false, true] {
            let author = catalogMetadataField("f1", label: "Author")
            let store = FakeStore()
            let (model, session) = await makePageModel(
                typeID: "t2",
                store: store,
                types: [userSourceType(), seededSourceType()],
                fields: [author],
                suggestions: [.source: ["t2": [CatalogTypeSuggestion(field: author, sortOrder: 0)]]]
            )
            if dirty { model.draft?.description = "Changed" }
            await model.askDelete()
            #expect(model.pendingDeleteType?.id == "t2")

            var left = 0
            #expect(await model.confirmDelete(leaving: { left += 1 }))

            #expect(left == 1)
            #expect(session.sourceTypesHandle?.value?.map(\.id) == ["t1"])
            #expect(model.toast == nil)
            #expect(model.pendingLeave == nil)
            #expect(model.pendingDeleteType == nil)
            // The suggestion join cascades; the field vocabulary row does not.
            #expect(store.fieldsByProject[projectDir]?.map(\.id) == ["f1"])
        }
    }

    // MARK: Leaving

    /// T-9 (AC-4.1 – AC-4.5): leaving asks only while Details are dirty and no Save runs.
    @Test func leavingAsksOnlyWhileDirty() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("type-page-nav-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let navigation = WorkspaceNavigation()
        navigation.attachProject(
            uuid: "00000000-0000-7000-8000-0000000000cc", fileURL: dir.appendingPathComponent("history.json")
        )
        navigation.go(to: .sectionRoot(.sourceTypes))
        navigation.go(to: .sourceTypePage(typeId: "t1", title: "Book"))

        let author = catalogMetadataField("f1", label: "Author")
        let (model, session) = await makePageModel(
            typeID: "t1", types: [seededSourceType()], fields: [author]
        )
        model.navigation = navigation
        navigation.leaveGuard = model

        // Clean: not held (AC-4.4).
        #expect(!model.shouldHoldNavigation(.back))
        #expect(model.pendingLeave == nil)

        // A suggestion write keeps a clean draft clean (AC-4.5).
        model.assignPick = "f1"
        await model.assignPickedField()
        #expect(!model.isDirty)
        navigation.goBack()
        #expect(navigation.currentLocation == .sectionRoot(.sourceTypes))
        navigation.goForward()
        #expect(navigation.currentLocation.typeId == "t1")

        // Dirty: held, place unchanged (AC-4.1); Keep editing keeps the edit (AC-4.3).
        model.draft?.description = "Changed"
        navigation.goBack()
        #expect(model.pendingLeave != nil)
        #expect(navigation.currentLocation.typeId == "t1")
        model.keepEditing()
        #expect(model.pendingLeave == nil)
        #expect(model.draft?.description == "Changed")
        #expect(navigation.currentLocation.typeId == "t1")
        #expect(navigation.heldNavigation == nil)

        // Discard: reverted, and Back runs (AC-4.2).
        navigation.goBack()
        #expect(model.pendingLeave != nil)
        model.discardAndLeave()
        #expect(model.pendingLeave == nil)
        #expect(model.draft?.description == "A published monograph.")
        #expect(navigation.currentLocation == .sectionRoot(.sourceTypes))
        _ = session
    }

    /// T-9: a move is not held while a Save runs, since the draft is about to be the saved row.
    @Test func aSaveInFlightIsNotHeld() async {
        let store = FakeStore()
        let (model, _) = await makePageModel(typeID: "t1", store: store, types: [seededSourceType()])
        model.draft?.label = "Changed"
        #expect(model.shouldHoldNavigation(.back))
        model.pendingLeave = nil

        store.updateSourceTypeHold.isOn = true
        let save = Task { await model.submit() }
        await store.updateSourceTypeHold.untilSuspended(1)
        #expect(model.isSaving)
        #expect(!model.shouldHoldNavigation(.back))
        #expect(model.pendingLeave == nil)

        store.updateSourceTypeHold.release()
        await save.value
        #expect(!model.isSaving)
        #expect(!model.shouldHoldNavigation(.back))
    }
}
