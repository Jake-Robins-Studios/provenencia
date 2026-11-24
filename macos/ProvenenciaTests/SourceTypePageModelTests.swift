import Foundation
import Testing
@testable import Provenencia

private enum PageBoom: Error { case boom }

@Suite
@MainActor
struct SourceTypePageModelTests {
    private let projectDir = "/tmp/type-page.provenencia"
    private let userID = "00000000-0000-7000-8000-000000000001"

    /// The page model of `typeID`, its reads warmed and settled and its draft synced, as the
    /// view's `.task` and `.onChange` leave it.
    private func makePageModel(
        typeID: String,
        store: FakeStore = FakeStore(),
        types: [CatalogSourceType] = [],
        fields: [CatalogMetadataField] = [],
        suggestions: [String: [CatalogTypeSuggestion]] = [:]
    ) async -> (SourceTypePageModel, WorkspaceSession) {
        store.sourceTypesByProject[projectDir] = types
        store.fieldsByProject[projectDir] = fields
        store.suggestionsByType = suggestions
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

    // MARK: Copy

    /// T-5 (AC-1.5): Copy opens once the type is loaded, on a plugin's type too, over the saved row.
    @Test func openCopyOnLoadedTypeOnly() async {
        let store = FakeStore()
        let (missing, _) = await makePageModel(typeID: "t3", store: store, types: [])
        #expect(!missing.canOpenCopy)
        missing.openCopy()
        #expect(missing.copying == nil)

        let (model, _) = await makePageModel(typeID: "t3", store: store, types: [pluginSourceType()])
        #expect(model.isLocked)
        #expect(model.canOpenCopy)
        model.draft?.label = "Unsaved edit"
        model.openCopy()
        #expect(model.copying?.original.id == "t3")
        #expect(model.copying?.original.label == "Grave memorial")
    }

    /// F-1: the page counts the engine's `suggestedFieldCount`, as the types column and Copy sheet do,
    /// not the length of the list it loaded.
    @Test func suggestionCountComesFromTheEngine() async {
        let store = FakeStore()
        store.suggestedFieldCounts["t1"] = 5
        let (model, _) = await makePageModel(
            typeID: "t1", store: store, types: [seededSourceType()]
        )
        #expect(model.suggestions.isEmpty)
        #expect(model.suggestionCount == 5)
        let (missing, _) = await makePageModel(typeID: "t9", types: [])
        #expect(missing.suggestionCount == 0)
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
        #expect(session.toasts.cards == [ToastCard(
            .success,
            L10n.string(L10n.SourceTypes.toastUpdatedTitle),
            L10n.SourceTypes.toastUpdatedBody(label: "Population census", key: "book")
        )])
    }

    /// T-8 (AC-2.3): a blank label shows the required message and writes nothing.
    @Test func blankLabelRefusesSave() async {
        let store = FakeStore()
        let (model, session) = await makePageModel(typeID: "t1", store: store, types: [seededSourceType()])
        model.editLabel("   ")
        #expect(!model.canSubmit)
        await model.submit()

        #expect(model.labelCheck.error == L10n.string(L10n.SourceTypes.errorLabelRequired))
        #expect(model.saveError == nil)
        #expect(store.sourceTypesByProject[projectDir]?.first?.label == "Book")
        #expect(session.toasts.cards.isEmpty)
    }

    /// UX-1: clearing the label shows the required message as the researcher edits, and typing a
    /// label clears it.
    @Test func clearingTheLabelShowsTheRequiredMessage() async {
        let (model, _) = await makePageModel(typeID: "t1", types: [seededSourceType()])
        model.editLabel("")
        #expect(model.labelCheck.error == L10n.string(L10n.SourceTypes.errorLabelRequired))
        #expect(!model.canSubmit)

        model.editLabel("Tome")
        #expect(model.labelCheck.error == nil)
        #expect(model.canSubmit)
    }

    /// UX-2: a failed write is a save error, not a Label error.
    @Test func aStoreFailureOnSaveIsNotALabelError() async {
        let store = FakeStore()
        let (model, session) = await makePageModel(typeID: "t1", store: store, types: [seededSourceType()])
        store.sourceTypesByProject[projectDir] = []
        model.editLabel("Tome")
        await model.submit()

        #expect(model.labelCheck.error == nil)
        #expect(model.saveError != nil)
        #expect(session.toasts.cards.isEmpty)

        model.revertEdit()
        #expect(model.saveError == nil)
    }

    /// UX-3: a deleted type leaves with a notice that names it.
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
        // The fields list is read on this page, so it is visible and reloads at once.
        session.apply(location: WorkspaceLocation(section: .sourceTypes, typeId: "t1"))
        let fieldsHandle: QueryHandle<[CatalogMetadataField]>? = session.queryHandle(
            .metadataFieldsList(project: session.projectKey)
        )
        if let fieldsHandle { await waitForQuery(fieldsHandle) }
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

    /// T-8 (AC-2.1, D-20): the one list loads in stored order.
    @Test func warmingLoadsTheListInStoredOrder() async {
        let author = catalogMetadataField("f1", label: "Author")
        let publisher = catalogMetadataField("f2", label: "Publisher")
        let store = FakeStore()
        let (model, _) = await makePageModel(
            typeID: "t1",
            store: store,
            types: [seededSourceType()],
            fields: [author, publisher],
            // Publisher was assigned first, so stored order and label order disagree.
            suggestions: ["t1": [
                CatalogTypeSuggestion(field: publisher, sortOrder: 0),
                CatalogTypeSuggestion(field: author, sortOrder: 1),
            ]]
        )
        #expect(model.suggestions.map(\.field.label) == ["Publisher", "Author"])
        #expect(store.listTypeSuggestionsTypeIDs == ["t1"])
    }

    @Test func assignPoolExcludesFieldsAlreadySuggested() async {
        let author = catalogMetadataField("f1", label: "Author")
        let (model, _) = await makePageModel(
            typeID: "t1",
            types: [seededSourceType()],
            fields: [author, catalogMetadataField("f2", label: "Publisher")],
            suggestions: ["t1": [CatalogTypeSuggestion(field: author, sortOrder: 0)]]
        )
        #expect(model.assignPool.map(\.id) == ["f2"])
    }

    /// A failed read offers no add, and Try again reads the list again.
    @Test func aFailedReadOffersNoAdd() async {
        let author = catalogMetadataField("f1", label: "Author")
        let store = FakeStore()
        store.listTypeSuggestionsError = PageBoom.boom
        let (model, _) = await makePageModel(
            typeID: "t1",
            store: store,
            types: [seededSourceType()],
            fields: [author],
            suggestions: ["t1": [CatalogTypeSuggestion(field: author, sortOrder: 0)]]
        )
        #expect(model.suggestionsHandle?.reading.noticeError != nil)
        #expect(!model.isLoaded)
        model.assignPick = "f1"
        #expect(!model.canAssign)

        store.listTypeSuggestionsError = nil
        model.rereadSuggestions()
        if let handle = model.suggestionsHandle { await waitForQuery(handle) }
        #expect(model.isLoaded)
        #expect(model.suggestions.map(\.field.id) == ["f1"])
    }

    /// T-8 (AC-2.2): assigning patches the cache and reloads nothing; the toast names the type.
    @Test func assigningAppendsTheFieldAndUpdatesTheListCount() async {
        let store = FakeStore()
        store.suggestedFieldCounts["t1"] = 0
        let (model, session) = await makePageModel(
            typeID: "t1",
            store: store,
            types: [seededSourceType()],
            fields: [catalogMetadataField("f1", label: "Author"), catalogMetadataField("f2", label: "Publisher")]
        )
        let loads = store.listTypeSuggestionsTypeIDs.count
        #expect(session.sourceType(id: "t1")?.suggestedFieldCount == 0)
        // The engine's count after the writes: the reply carries it and the row takes it.
        store.suggestedFieldCounts["t1"] = 2

        model.assignPick = "f2"
        await model.assignPickedField()
        model.assignPick = "f1"
        await model.assignPickedField()
        await session.settleWrites()

        #expect(model.suggestions.map(\.field.id) == ["f2", "f1"])
        #expect(model.assignPick.isEmpty)
        #expect(session.sourceType(id: "t1")?.suggestedFieldCount == 2)
        let assignedTitle = L10n.string(L10n.SourceTypes.toastAssignedTitle)
        #expect(session.toasts.cards == [
            ToastCard(.success, assignedTitle, L10n.SourceTypes.toastAssignedBody(field: "Author", type: "Book")),
            ToastCard(.success, assignedTitle, L10n.SourceTypes.toastAssignedBody(field: "Publisher", type: "Book")),
        ])
        #expect(store.listTypeSuggestionsTypeIDs.count == loads)
    }

    /// The spoken label and tooltip name the type, not a level.
    @Test func assignLabelsNameTheType() async {
        let author = catalogMetadataField("f1", label: "Author")
        let (model, _) = await makePageModel(
            typeID: "t1",
            types: [seededSourceType(label: "Census")],
            fields: [author]
        )
        #expect(model.assignAccessibilityLabel == L10n.SourceTypes.assignField(type: "Census"))
        #expect(model.assignTooltip == L10n.string(L10n.SourceTypes.assignTipChoose))
        model.assignPick = "f1"
        #expect(model.assignAccessibilityLabel == L10n.SourceTypes.assignFieldNamed(field: "Author", type: "Census"))
        #expect(model.assignTooltip == L10n.SourceTypes.assignTipField(label: "Author", type: "Census"))
        #expect(model.removeLabel(for: author) == L10n.SourceTypes.removeSuggestion(label: "Author", type: "Census"))
    }

    /// T-8: a failed write shows once and keeps its pick.
    @Test func anAssignFailureKeepsThePick() async {
        let author = catalogMetadataField("f1", label: "Author")
        let store = FakeStore()
        let (model, _) = await makePageModel(
            typeID: "t1",
            store: store,
            types: [seededSourceType()],
            fields: [author, catalogMetadataField("f2", label: "Publisher")],
            suggestions: ["t1": [CatalogTypeSuggestion(field: author, sortOrder: 0)]]
        )
        store.assignTypeFieldError = PageBoom.boom
        model.assignPick = "f2"
        await model.assignPickedField()
        #expect(model.suggestionError != nil)
        #expect(model.assignPick == "f2")
        #expect(model.suggestionWrite == nil)

        store.removeTypeFieldError = PageBoom.boom
        await model.removeSuggestion(fieldID: "f1")
        #expect(model.suggestionError != nil)
        #expect(model.suggestions.map(\.field.id) == ["f1"])
    }

    /// T-8 (D-20): one write at a time, and nothing is added with no pick or against a list that
    /// has not read.
    @Test func oneWriteAtATime() async {
        let author = catalogMetadataField("f1", label: "Author")
        let publisher = catalogMetadataField("f2", label: "Publisher")
        let store = FakeStore()
        let (model, _) = await makePageModel(
            typeID: "t1",
            store: store,
            types: [seededSourceType()],
            fields: [author, publisher]
        )
        #expect(!model.canAssign)
        model.assignPick = "f1"
        #expect(model.canAssign && model.canRemove)

        store.assignTypeFieldHold.isOn = true
        let write = Task { await model.assignPickedField() }
        await store.assignTypeFieldHold.untilSuspended(1)
        #expect(model.suggestionWrite == .assigning)
        #expect(!model.canAssign)
        #expect(!model.canRemove)

        store.assignTypeFieldHold.isOn = false
        store.assignTypeFieldHold.release()
        await write.value
        #expect(model.suggestionWrite == nil)
        #expect(model.canRemove)
    }

    @Test func fieldsColumnShowsTheEnginesCountNotTheReplyLength() async {
        let author = catalogMetadataField("f1", label: "Author")
        let store = FakeStore()
        store.suggestedFieldCounts["t1"] = 3
        let (model, session) = await makePageModel(
            typeID: "t1",
            store: store,
            types: [seededSourceType()],
            fields: [author]
        )
        #expect(session.sourceType(id: "t1")?.suggestedFieldCount == 3)
        store.suggestedFieldCounts["t1"] = 7

        model.assignPick = "f1"
        await model.assignPickedField()

        #expect(model.suggestions.count == 1)
        #expect(session.sourceType(id: "t1")?.suggestedFieldCount == 7)
    }

    /// T-8 (AC-2.4): removing patches the cache; the field stays in the pool.
    @Test func removingASuggestionKeepsTheFieldInThePool() async {
        let author = catalogMetadataField("f1", label: "Author", usedBy: 3)
        let store = FakeStore()
        store.suggestedFieldCounts["t1"] = 1
        let (model, session) = await makePageModel(
            typeID: "t1",
            store: store,
            types: [seededSourceType()],
            fields: [author],
            suggestions: ["t1": [CatalogTypeSuggestion(field: author, sortOrder: 0)]]
        )
        #expect(session.sourceType(id: "t1")?.suggestedFieldCount == 1)
        store.suggestedFieldCounts["t1"] = 0

        await model.removeSuggestion(fieldID: "f1")

        #expect(model.suggestions.isEmpty)
        #expect(session.sourceType(id: "t1")?.suggestedFieldCount == 0)
        // The vocabulary row survives, so the field is assignable again.
        #expect(model.assignPool.map(\.id) == ["f1"])
        #expect(session.toasts.cards.first?.title == L10n.string(L10n.SourceTypes.toastRemovedTitle))
        // The copy must not imply the existing values went with it.
        #expect(session.toasts.cards.first?.message?.contains("3") == true)
    }

    @Test func removingASuggestionNoSourceUsesOmitsTheValueCount() async {
        let author = catalogMetadataField("f1", label: "Author")
        let (model, session) = await makePageModel(
            typeID: "t1",
            types: [seededSourceType()],
            fields: [author],
            suggestions: ["t1": [CatalogTypeSuggestion(field: author, sortOrder: 0)]]
        )

        await model.removeSuggestion(fieldID: "f1")
        #expect(session.toasts.cards.first?.message == L10n.SourceTypes.toastRemovedBody(field: "Author", type: "Book", valueCount: 0))
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
                suggestions: ["t2": [CatalogTypeSuggestion(field: author, sortOrder: 0)]]
            )
            if dirty { model.draft?.description = "Changed" }
            await model.askDelete()
            #expect(model.pendingDeleteType?.id == "t2")

            var left = 0
            #expect(await model.confirmDelete(leaving: { left += 1 }))

            #expect(left == 1)
            #expect(session.sourceTypesHandle?.value?.map(\.id) == ["t1"])
            #expect(session.toasts.cards.isEmpty)
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

    /// A copy whose move to the new page is held says it was made once the researcher keeps
    /// editing; a move that goes through (not held, or held then Discard) says nothing.
    @Test func copyMadeWhileMoveHeldIsToastedOnKeepEditing() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("type-page-copy-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let navigation = WorkspaceNavigation()
        navigation.attachProject(
            uuid: "00000000-0000-7000-8000-0000000000cd", fileURL: dir.appendingPathComponent("history.json")
        )
        navigation.go(to: .sourceTypePage(typeId: "t1", title: "Book"))
        let (model, session) = await makePageModel(typeID: "t1", types: [seededSourceType()])
        model.navigation = navigation
        navigation.leaveGuard = model
        let copy = userSourceType(id: "t9", label: "State census")

        // Not held: the new page opens and there is no toast.
        model.open(copy: copy)
        #expect(navigation.currentLocation.typeId == "t9")
        #expect(session.toasts.cards.isEmpty)

        // Held, then Keep editing: the toast names the copy.
        navigation.go(to: .sourceTypePage(typeId: "t1", title: "Book"))
        model.draft?.description = "Changed"
        model.open(copy: copy)
        #expect(navigation.currentLocation.typeId == "t1")
        #expect(session.toasts.cards.isEmpty)
        model.keepEditing()
        #expect(session.toasts.cards.count == 1)
        #expect(session.toasts.cards.first?.title?.contains("State census") == true)

        // Held, then Discard: the move goes through and adds no card.
        let cardsBefore = session.toasts.entries.count
        model.open(copy: copy)
        model.discardAndLeave()
        #expect(navigation.currentLocation.typeId == "t9")
        #expect(session.toasts.entries.count == cardsBefore)

        // A later, unrelated Keep editing does not repeat it.
        navigation.go(to: .sourceTypePage(typeId: "t1", title: "Book"))
        model.draft?.description = "Changed again"
        navigation.goBack()
        model.keepEditing()
        #expect(session.toasts.entries.count == cardsBefore)
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

    // MARK: One Save, Details and formats (T-10)

    private func makeFormatsPage(store: FakeStore = FakeStore()) async -> (SourceTypePageModel, WorkspaceSession) {
        store.citationFormatsByType["t1"] = CatalogCitationFormatsReply(
            formats: CatalogCitationFormats(typeID: "t1", full: "{source.title}", short: "{source.title}", list: "")
        )
        store.sourcesByProject[projectDir] = [CatalogSource(id: "s1", ref: "SRC-1", sourceTypeID: "t1", title: "Alpha", description: "")]
        let (model, session) = await makePageModel(typeID: "t1", store: store, types: [seededSourceType()])
        await model.formats.load()
        return (model, session)
    }

    @Test func aFormatEditAloneSavesFormatsWithTheSavedDetailsAndMarksSourcePagesStale() async {
        let store = FakeStore()
        let (model, session) = await makeFormatsPage(store: store)
        let workspace: QueryHandle<CatalogSourceWorkspace> = session.query(.sourceWorkspace(project: session.projectKey, sourceId: "s1"))
        await waitForQuery(workspace)
        #expect(!model.isDirty && !model.canSubmit)
        model.formats.edit(.full, text: "{source.title} Test.")
        #expect(model.isDirty && model.canSubmit)

        await model.submit()
        #expect(store.updateSourceTypeCalls.count == 1)
        let call = store.updateSourceTypeCalls[0]
        #expect(call.label == "Book" && call.formats?.full == "{source.title} Test." && call.formats?.short == "{source.title}")
        #expect(session.toasts.cards == [ToastCard(.success, L10n.string(L10n.SourceTypes.Formats.toastSavedTitle), L10n.SourceTypes.Formats.toastSavedBody(label: "Book"))])
        #expect(workspace.isStale)
        #expect(!model.isDirty)
    }

    @Test func detailsAndFormatsTogetherAreOneCallWithTheBothToast() async {
        let store = FakeStore()
        let (model, session) = await makeFormatsPage(store: store)
        model.editLabel("Book (US)")
        model.formats.edit(.short, text: "{source.title}.")
        await model.submit()
        #expect(store.updateSourceTypeCalls.count == 1)
        #expect(store.updateSourceTypeCalls[0].label == "Book (US)" && store.updateSourceTypeCalls[0].formats != nil)
        #expect(session.toasts.cards == [ToastCard(.success, L10n.string(L10n.SourceTypes.toastUpdatedTitle), L10n.SourceTypes.Formats.toastBothBody(label: "Book (US)"))])
    }

    @Test func detailsAloneSendNoFormatsAndApplyNoFormatsSignal() async {
        let store = FakeStore()
        let (model, session) = await makeFormatsPage(store: store)
        let workspace: QueryHandle<CatalogSourceWorkspace> = session.query(.sourceWorkspace(project: session.projectKey, sourceId: "s1"))
        await waitForQuery(workspace)
        model.editLabel("Book (US)")
        await model.submit()
        #expect(store.updateSourceTypeCalls[0].formats == nil)
        #expect(session.toasts.cards == [ToastCard(.success, L10n.string(L10n.SourceTypes.toastUpdatedTitle), L10n.SourceTypes.toastUpdatedBody(label: "Book (US)", key: "book"))])
        #expect(!workspace.isStale)
    }

    @Test func aRefusedFormatSavesNothingAndKeepsEveryEdit() async {
        let store = FakeStore()
        let (model, session) = await makeFormatsPage(store: store)
        let workspace: QueryHandle<CatalogSourceWorkspace> = session.query(.sourceWorkspace(project: session.projectKey, sourceId: "s1"))
        await waitForQuery(workspace)
        store.updateSourceTypeFormatsReply = CatalogCitationFormatsReply(
            formats: CatalogCitationFormats(typeID: "t1", full: "{source.title}", short: "[x", list: ""),
            diagnostics: [CatalogCitationDiagnostic(form: .short, code: "unclosed_group", utf8Start: 0, utf8End: 1)]
        )
        model.editLabel("Renamed")
        model.formats.edit(.short, text: "[x")
        await model.submit()
        #expect(model.saveError == L10n.string(L10n.SourceTypes.Formats.saveRefused))
        #expect(session.toasts.cards.isEmpty)
        #expect(model.draft?.label == "Renamed" && model.formats.draft(.short) == "[x")
        #expect(model.formats.shownDiagnostics(.short).count == 1)
        #expect(model.type?.label == "Book")
        #expect(model.isDirty)
        // Nothing changed, so no page that reads the formats is marked stale.
        #expect(!workspace.isStale)
        #expect(store.updateSourceTypeCalls.count == 1)
    }

    @Test func aFormatEditAloneHoldsNavigationAndRevertRestoresIt() async {
        let (model, _) = await makeFormatsPage()
        model.formats.edit(.list, text: "{source.title}")
        #expect(model.isDirty)
        model.revertEdit()
        #expect(!model.isDirty && model.formats.draft(.list).isEmpty)
    }
}
