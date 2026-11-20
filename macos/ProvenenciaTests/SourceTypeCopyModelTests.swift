import Foundation
import Testing
@testable import Provenencia

private enum CopyBoom: Error { case boom }

@Suite
@MainActor
struct SourceTypeCopyModelTests {
    private let projectDir = "/tmp/type-copy.provenencia"
    private let userID = "00000000-0000-7000-8000-000000000001"

    private func original(description: String = "A government enumeration.") -> CatalogSourceType {
        var type = catalogSourceType("t1", label: "Census", origin: "user", description: description)
        type.iconKey = "type_scroll"
        return type
    }

    private func suggestions(_ count: Int) -> [CatalogTypeSuggestion] {
        (0..<count).map {
            CatalogTypeSuggestion(field: catalogMetadataField("f\($0)", label: "Field \($0)"), sortOrder: $0)
        }
    }

    private let allForms = CatalogCitationFormats(typeID: "t1", full: "{source.title}", short: "{source.title}", list: "{source.title}")

    /// A model over `original` with the three lists read; the formats are read by the test.
    private func makeModel(
        store: FakeStore = FakeStore(),
        original: CatalogSourceType? = nil,
        source: Int = 4,
        artifact: Int = 3,
        graph: Int = 5,
        formats: CatalogCitationFormats? = nil
    ) async -> (SourceTypeCopyModel, WorkspaceSession) {
        let type = original ?? self.original()
        store.sourceTypesByProject[projectDir] = [type]
        store.suggestionsByLevel = [
            .source: [type.id: suggestions(source)],
            .artifact: [type.id: suggestions(artifact)],
            .graph: [type.id: suggestions(graph)],
        ]
        store.citationFormatsByType[type.id] = CatalogCitationFormatsReply(formats: formats ?? allForms)
        let session = WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)
        let handle: QueryHandle<[CatalogSourceType]> = session.query(session.sourceTypesKey)
        await waitForQuery(handle)
        let model = SourceTypeCopyModel(original: type, session: session, userID: userID, store: store)
        for level in Level.metadataLevels {
            let key = CatalogQueryKey.typeSuggestions(project: session.projectKey, typeId: type.id, level: level)
            if let levelHandle: QueryHandle<[CatalogTypeSuggestion]> = session.queryHandle(key) {
                await waitForQuery(levelHandle)
            }
        }
        return (model, session)
    }

    private func scriptCopy(_ store: FakeStore, count: Int = 12) -> CatalogSourceType {
        var created = catalogSourceType("t9", label: "State census", origin: "user")
        created.suggestedFieldCount = count
        store.copySourceTypeResult = (created, .empty)
        return created
    }

    @Test func prefillsBlankLabelAndEveryTick() async {
        let (model, _) = await makeModel()
        await model.loadFormats()

        #expect(model.choices.draft.label == "")
        #expect(model.choices.includeIcon)
        #expect(model.choices.includeDescription)
        #expect(model.choices.includeFormats)
        #expect(model.choices.includedLevels == Set(Level.metadataLevels))
        #expect(!model.isDirty)
        #expect(model.loadState == .ready)
        #expect(!model.canCopy)
        #expect(model.iconHint == L10n.string(PVMarkKey.typeScroll.typePickerTitle))
        #expect(model.formsPresent == [.full, .short, .list])
        #expect(model.levelHint(.artifact) == L10n.SourceTypes.assignedCount(count: 3))
    }

    @Test func absentPartsReadUntickedAndAreNotSent() async {
        let store = FakeStore()
        let (model, _) = await makeModel(
            store: store, original: original(description: ""), source: 2, artifact: 0, graph: 0,
            formats: CatalogCitationFormats(typeID: "t1", full: "", short: "", list: "")
        )
        await model.loadFormats()
        _ = scriptCopy(store, count: 2)
        model.editLabel("Letter copy")

        #expect(!model.descriptionAvailable)
        #expect(!model.formatsAvailable)
        #expect(model.levelsToCopy == [.source])
        #expect(await model.copy() != nil)

        let call = store.copySourceTypeCalls.first
        #expect(call?.copyIcon == true)
        #expect(call?.copyDescription == false)
        #expect(call?.copyFormats == false)
        #expect(call?.levels == [.source])
    }

    @Test func copySendsTickedPartsAndPatchesTheList() async {
        let store = FakeStore()
        let (model, session) = await makeModel(store: store)
        await model.loadFormats()
        let created = scriptCopy(store)
        model.editLabel("  State census ")
        model.choices.includedLevels.remove(.artifact)

        #expect(model.canCopy)
        let got = await model.copy()

        #expect(got == created)
        #expect(store.copySourceTypeCalls == [
            CopySourceTypeCall(
                projectDir: projectDir, userID: userID, typeID: "t1", label: "State census",
                copyIcon: true, copyDescription: true, copyFormats: true, levels: [.source, .graph]
            ),
        ])
        #expect(session.sourceType(id: "t9")?.suggestedFieldCount == 12)
    }

    @Test func unticksSkipTheirParts() async {
        let store = FakeStore()
        let (model, _) = await makeModel(store: store)
        await model.loadFormats()
        _ = scriptCopy(store)
        model.editLabel("State census")
        model.choices.includeIcon = false
        model.choices.includeDescription = false
        model.choices.includeFormats = false

        #expect(await model.copy() != nil)

        let call = store.copySourceTypeCalls.first
        #expect(call?.copyIcon == false)
        #expect(call?.copyDescription == false)
        #expect(call?.copyFormats == false)
        #expect(call?.levels == Level.metadataLevels)
    }

    @Test func aBlankOrUnslugifiableLabelCannotBeCopied() async {
        let store = FakeStore()
        let (model, _) = await makeModel(store: store)
        await model.loadFormats()

        #expect(await model.copy() == nil)
        #expect(model.labelCheck.error == L10n.string(L10n.SourceTypes.errorLabelRequired))
        model.editLabel("...")
        #expect(model.labelCheck.error == L10n.string(L10n.SourceTypes.errorUnslugifiable))
        #expect(!model.canCopy)
        #expect(await model.copy() == nil)
        #expect(store.copySourceTypeCalls.isEmpty)
    }

    @Test func duplicateKeyShowsUnderLabel() async {
        let store = FakeStore()
        let (model, _) = await makeModel(store: store)
        await model.loadFormats()
        store.copySourceTypeError = CoreInvokeError.coded(
            status: 1, code: "sourcetypes.duplicate_key", kind: .conflict, params: ["census"]
        )
        model.editLabel("Census")

        #expect(await model.copy() == nil)

        #expect(model.labelCheck.error == L10n.Errors.sourceTypesDuplicateKey(key: "census"))
        #expect(model.labelCheck.announces)
        #expect(model.copyError == nil)
        #expect(model.choices.draft.label == "Census")
    }

    @Test func otherFailureKeepsChoices() async {
        let store = FakeStore()
        let (model, _) = await makeModel(store: store)
        await model.loadFormats()
        let gone = CoreInvokeError.coded(status: 1, code: "sourcetypes.invalid", kind: .user, params: [])
        store.copySourceTypeError = gone
        model.editLabel("State census")
        model.choices.includedLevels.remove(.graph)

        #expect(await model.copy() == nil)

        #expect(model.copyError == L10n.Errors.message(for: gone))
        #expect(model.labelCheck.error == nil)
        #expect(model.choices.draft.label == "State census")
        #expect(model.choices.includedLevels == [.source, .artifact])
        #expect(!model.isSaving)
    }

    @Test func formatsReadFailureThenReadAgain() async {
        let store = FakeStore()
        let (model, _) = await makeModel(store: store)
        store.citationFormatsError = CopyBoom.boom
        await model.loadFormats()

        guard case .failed = model.loadState else {
            Issue.record("expected a failed read, got \(model.loadState)")
            return
        }
        model.editLabel("State census")
        #expect(!model.canCopy)

        store.citationFormatsError = nil
        model.reload()
        #expect(model.loadState == .loading)
        await model.loadFormats()
        _ = await waitUntil { model.loadState == .ready }

        #expect(model.loadState == .ready)
        #expect(model.formatsAvailable)
        #expect(model.canCopy)
    }

    @Test func aFailedListReadFailsTheSheetAndReloads() async {
        let store = FakeStore()
        store.listTypeSuggestionsError = CopyBoom.boom
        store.listTypeSuggestionsErrorLevels = [.artifact]
        let (model, session) = await makeModel(store: store)
        await model.loadFormats()

        guard case .failed = model.loadState else {
            Issue.record("expected a failed read, got \(model.loadState)")
            return
        }

        store.listTypeSuggestionsError = nil
        model.reload()
        let key = CatalogQueryKey.typeSuggestions(project: session.projectKey, typeId: "t1", level: .artifact)
        if let handle: QueryHandle<[CatalogTypeSuggestion]> = session.queryHandle(key) { await waitForQuery(handle) }

        #expect(model.loadState == .ready)
        #expect(model.suggestionCount(at: .artifact) == 3)
    }

    @Test func cannotCopyWhileReading() async {
        let store = FakeStore()
        let (model, _) = await makeModel(store: store)
        _ = scriptCopy(store)
        model.editLabel("State census")

        #expect(model.loadState == .loading)
        #expect(!model.canCopy)
        #expect(await model.copy() == nil)
        #expect(store.copySourceTypeCalls.isEmpty)
    }

    @Test func dirtyAfterLabelOrTick() async {
        let (model, _) = await makeModel()
        await model.loadFormats()
        #expect(!model.isDirty)

        model.editLabel("S")
        #expect(model.isDirty)
        model.editLabel("")
        #expect(!model.isDirty)

        model.choices.includeIcon = false
        #expect(model.isDirty)
        model.choices.includeIcon = true
        model.choices.includedLevels.remove(.source)
        #expect(model.isDirty)
    }
}
