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

    private let allForms = CatalogCitationFormats(typeID: "t1", full: "{source.title}", short: "{source.title}", list: "{source.title}")

    /// A model over `original` (which suggests `suggested` fields: the type row's count); the
    /// formats are read by the test.
    private func makeModel(
        store: FakeStore = FakeStore(),
        original: CatalogSourceType? = nil,
        suggested: Int = 21,
        formats: CatalogCitationFormats? = nil
    ) async -> (SourceTypeCopyModel, WorkspaceSession) {
        var type = original ?? self.original()
        type.suggestedFieldCount = suggested
        store.sourceTypesByProject[projectDir] = [type]
        store.citationFormatsByType[type.id] = CatalogCitationFormatsReply(formats: formats ?? allForms)
        let session = WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)
        let handle: QueryHandle<[CatalogSourceType]> = session.query(session.sourceTypesKey)
        await waitForQuery(handle)
        let model = SourceTypeCopyModel(original: type, session: session, userID: userID, store: store)
        return (model, session)
    }

    private func scriptCopy(_ store: FakeStore, count: Int = 12) -> CatalogSourceType {
        var created = catalogSourceType("t9", label: "State census", origin: "user")
        created.suggestedFieldCount = count
        store.copySourceTypeResult = (created, .empty)
        return created
    }

    /// T-9: four ticks, the Suggested fields one counted from the type row.
    @Test func prefillsBlankLabelAndEveryTick() async {
        let (model, _) = await makeModel()
        await model.loadFormats()

        #expect(model.choices.draft.label == "")
        #expect(model.choices.includeIcon)
        #expect(model.choices.includeDescription)
        #expect(model.choices.includeFormats)
        #expect(model.choices.includeSuggestions)
        #expect(!model.isDirty)
        #expect(model.loadState == .ready)
        #expect(!model.canCopy)
        #expect(model.iconHint == L10n.string(PVMarkKey.typeScroll.typePickerTitle))
        #expect(model.formsPresent == [.full, .short, .list])
        #expect(model.suggestionsAvailable)
        #expect(model.suggestionsHint == L10n.SourceTypes.assignedCount(count: 21))
    }

    @Test func absentPartsReadUntickedAndAreNotSent() async {
        let store = FakeStore()
        let (model, _) = await makeModel(
            store: store, original: original(description: ""), suggested: 0,
            formats: CatalogCitationFormats(typeID: "t1", full: "", short: "", list: "")
        )
        await model.loadFormats()
        _ = scriptCopy(store, count: 0)
        model.editLabel("Letter copy")

        #expect(!model.descriptionAvailable)
        #expect(!model.formatsAvailable)
        #expect(!model.suggestionsAvailable)
        #expect(await model.copy() != nil)

        let call = store.copySourceTypeCalls.first
        #expect(call?.copyIcon == true)
        #expect(call?.copyDescription == false)
        #expect(call?.copyFormats == false)
        #expect(call?.copySuggestions == false)
    }

    @Test func copySendsTickedPartsAndPatchesTheList() async {
        let store = FakeStore()
        let (model, session) = await makeModel(store: store)
        await model.loadFormats()
        let created = scriptCopy(store)
        model.editLabel("  State census ")
        #expect(model.canCopy)
        let got = await model.copy()

        #expect(got == created)
        #expect(store.copySourceTypeCalls == [
            CopySourceTypeCall(
                projectDir: projectDir, userID: userID, typeID: "t1", label: "State census",
                copyIcon: true, copyDescription: true, copyFormats: true, copySuggestions: true
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
        #expect(call?.copySuggestions == true)
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
        model.choices.includeSuggestions = false

        #expect(await model.copy() == nil)

        #expect(model.copyError == L10n.Errors.message(for: gone))
        #expect(model.labelCheck.error == nil)
        #expect(model.choices.draft.label == "State census")
        #expect(!model.choices.includeSuggestions)
        #expect(!model.isSaving)
    }

    @Test func aFailedFormatsReadFailsTheSheetAndReloads() async {
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
        #expect(model.suggestionCount == 21)
        #expect(model.canCopy)
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
        model.choices.includeSuggestions = false
        #expect(model.isDirty)
    }
}
