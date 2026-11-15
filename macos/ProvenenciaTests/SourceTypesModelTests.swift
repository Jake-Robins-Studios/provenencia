import Foundation
import Testing
@testable import Provenencia

private enum AddFailure: Error { case boom }

@Suite
@MainActor
struct SourceTypesModelTests {
    private let projectDir = "/tmp/types.provenencia"
    private let userID = "00000000-0000-7000-8000-000000000001"

    private func seededType(id: String = "t1", label: String = "Book", usedBy: Int = 0) -> CatalogSourceType {
        CatalogSourceType(
            id: id, key: "book", origin: "provenencia", label: label,
            description: "A published monograph.", usedBy: usedBy
        )
    }

    private func userType(id: String = "t2", label: String = "Family scrapbook", usedBy: Int = 0) -> CatalogSourceType {
        CatalogSourceType(
            id: id, key: FieldSlug.kebab(label), origin: "user", label: label,
            description: "Nan's albums.", usedBy: usedBy
        )
    }

    private func pluginType(id: String = "t3", label: String = "Grave memorial", usedBy: Int = 5) -> CatalogSourceType {
        CatalogSourceType(
            id: id, key: "grave-memorial", origin: "plugin:findagrave", label: label,
            description: "From the plugin.", usedBy: usedBy
        )
    }

    private func field(id: String, label: String, dataType: String = "text", usedBy: Int = 0) -> CatalogMetadataField {
        CatalogMetadataField(
            id: id, key: FieldSlug.kebab(label), origin: "provenencia", label: label,
            dataType: dataType, description: "", usedBy: usedBy
        )
    }

    private func makeModel(
        store: FakeStore = FakeStore(),
        types: [CatalogSourceType] = [],
        fields: [CatalogMetadataField] = [],
        suggestions: [String: [CatalogTypeSuggestion]] = [:]
    ) -> (SourceTypesModel, WorkspaceSession) {
        store.sourceTypesByProject[projectDir] = types
        store.fieldsByProject[projectDir] = fields
        store.suggestionsByType = suggestions
        let session = WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)
        let model = SourceTypesModel(
            session: session,
            userID: userID,
            store: store
        )
        return (model, session)
    }

    private func warm(_ model: SourceTypesModel, session: WorkspaceSession) async {
        model.warmListQueries()
        if let typesHandle: QueryHandle<[CatalogSourceType]> = session.queryHandle(
            SourceTypesModel.typesListKey(for: session)
        ) {
            await waitForQuery(typesHandle)
        }
    }

    // MARK: List

    @Test func loadPopulatesTypesPool() async {
        let (model, session) = makeModel(
            types: [seededType(), userType(), pluginType()],
            fields: [field(id: "f1", label: "Author")]
        )
        await warm(model, session: session)
        #expect(model.types.count == 3)
        #expect(model.types.seededCount == 1)
        #expect(model.types.userCount == 1)
        #expect(model.types.pluginCount == 1)
    }

    @Test func sortingTogglesWithinAColumnAndResetsAcrossColumns() async {
        let store = FakeStore()
        let (model, session) = makeModel(
            store: store,
            types: [seededType(), userType()],
            fields: [field(id: "f1", label: "Author")],
            suggestions: ["t2": [CatalogTypeSuggestion(field: field(id: "f1", label: "Author"), sortOrder: 0)]]
        )
        await warm(model, session: session)
        #expect(model.visibleTypes.map(\.id) == ["t1", "t2"])

        model.sortBy("label")
        #expect(!model.sortAscending)
        #expect(model.visibleTypes.map(\.id) == ["t2", "t1"])

        // Moving to a new column starts ascending again, not carrying the
        // previous column's direction.
        model.sortBy("fields")
        #expect(model.sortColumn == .fields)
        #expect(model.sortAscending)
        #expect(model.visibleTypes.map(\.id) == ["t1", "t2"])
    }

    /// T-12 (AC-4.1): the header counts the rows the page shows.
    @Test func countLineCountsTheRowsShown() async {
        let (model, session) = makeModel(types: [
            seededType(id: "t1", label: "A"), seededType(id: "t3", label: "B"), seededType(id: "t4", label: "C"),
            userType(id: "t2", label: "D"), userType(id: "t5", label: "E"),
        ])
        await warm(model, session: session)
        #expect(model.countLine == L10n.SourceTypes.countLine(total: 5, seeded: 3, user: 2))
    }

    /// F-6: no count line until the list has a value.
    @Test func countLineIsAbsentUntilTheListLoads() async {
        let (model, session) = makeModel(types: [seededType(id: "t1", label: "A")])
        #expect(model.countLine == nil)
        await warm(model, session: session)
        #expect(model.countLine != nil)
    }

    // MARK: Add

    private func makeAddModel(_ session: WorkspaceSession, store: FakeStore) -> SourceTypeAddModel {
        SourceTypeAddModel(session: session, userID: userID, store: store)
    }

    @Test func addingMintsTheKeyFromTheLabelAndPutsTheRowInTheList() async throws {
        let store = FakeStore()
        let (model, session) = makeModel(store: store, types: [seededType()])
        await warm(model, session: session)
        let add = makeAddModel(session, store: store)
        add.draft.label = "  Parish register "
        #expect(add.key == "parish-register")
        #expect(add.canAdd)

        let created = try #require(await add.create())

        #expect(created.key == "parish-register")
        #expect(created.label == "Parish register")
        #expect(created.origin == "user")
        #expect(created.iconKey == PVMarkKey.defaultTypeMark.rawValue)
        // The declared patch put the row in the list before anything settles.
        #expect(model.types.contains { $0.id == created.id && $0.key == "parish-register" })
    }

    /// T-7 (AC-1.3): a type create reloads the Source vocabulary lists from its
    /// effects and leaves a visited Source page alone. The store holds a row the
    /// cache has not seen, so a reload shows as that row arriving.
    @Test func addingATypeReloadsFromItsEffects() async throws {
        let store = FakeStore()
        let (model, session) = makeModel(store: store, types: [seededType()])
        await warm(model, session: session)
        let project = session.projectKey
        let pageKey = CatalogQueryKey.sourceWorkspace(project: project, sourceId: "s1")
        session.setQueryValue(pageKey, value: CatalogSourceWorkspace(
            source: CatalogSource(id: "s1", ref: "SRC-1", sourceTypeID: "t1", title: "Alpha", description: ""),
            notes: [], metadata: [], artifacts: [], credibility: nil
        ))
        let fieldsHandle: QueryHandle<[CatalogMetadataField]> = session.query(
            CatalogQueryKey.metadataFieldsList(project: project)
        )
        await waitForQuery(fieldsHandle)
        let typesHandle: QueryHandle<[CatalogSourceType]> = try #require(
            session.queryHandle(SourceTypesModel.typesListKey(for: session))
        )
        store.fieldsByProject[projectDir] = [field(id: "f9", label: "Unseen")]

        store.nextWriteEffects = CatalogWriteEffects(lists: [.sourceVocabulary])
        let add = makeAddModel(session, store: store)
        add.draft.label = "Diary"
        let created = try #require(await add.create())
        await session.settleWrites()

        #expect(model.types.contains { $0.id == created.id && $0.key == "diary" })
        #expect(typesHandle.value?.contains { $0.key == "diary" } == true)
        #expect(fieldsHandle.value?.map(\.id) == ["f9"])
        let page: QueryHandle<CatalogSourceWorkspace> = try #require(session.queryHandle(pageKey))
        #expect(!page.isStale)
    }

    @Test func addingReturnsTheTypeTheDialogOpens() async throws {
        let store = FakeStore()
        let (model, session) = makeModel(store: store, types: [seededType()])
        await warm(model, session: session)
        let add = makeAddModel(session, store: store)
        add.draft.label = "Parish register"
        let created = try #require(await add.create())
        let location = WorkspaceLocation.sourceTypePage(typeId: created.id, title: created.label)
        #expect(location.section == .sourceTypes)
        #expect(location.typeId == created.id)
        #expect(location.title == "Parish register")
    }

    @Test func addingRefusesABlankLabelWithoutCallingTheStore() async {
        let store = FakeStore()
        let (model, session) = makeModel(store: store)
        await warm(model, session: session)
        let add = makeAddModel(session, store: store)
        add.draft.label = "   "

        #expect(!add.canAdd)
        #expect(await add.create() == nil)

        #expect(add.labelError == L10n.string(L10n.SourceTypes.errorLabelRequired))
        #expect(model.types.isEmpty)
    }

    @Test func addingRefusesALabelThatCannotBeSlugged() async {
        let store = FakeStore()
        let (model, session) = makeModel(store: store)
        await warm(model, session: session)
        let add = makeAddModel(session, store: store)
        add.draft.label = "—"

        #expect(await add.create() == nil)

        #expect(add.labelError == L10n.string(L10n.SourceTypes.errorUnslugifiable))
        #expect(model.types.isEmpty)
    }

    @Test func addingADuplicateUserKeySurfacesTheErrorUnderTheLabel() async {
        let store = FakeStore()
        let (model, session) = makeModel(store: store, types: [userType(id: "t2", label: "Family scrapbook")])
        await warm(model, session: session)
        let add = makeAddModel(session, store: store)
        add.draft.label = "Family scrapbook"

        #expect(await add.create() == nil)

        #expect(add.labelError == L10n.Errors.sourceTypesDuplicateKey(key: "family-scrapbook"))
        #expect(add.labelErrorFromWrite)
        #expect(add.createError == nil)
        #expect(model.types.count == 1)

        add.editLabel("x")
        #expect(!add.labelErrorFromWrite)
    }

    @Test func editingTheLabelShowsAndClearsItsError() async {
        let store = FakeStore()
        let (model, session) = makeModel(store: store, types: [userType(id: "t2", label: "Family scrapbook")])
        await warm(model, session: session)
        let add = makeAddModel(session, store: store)
        #expect(add.labelError == nil)

        add.editLabel("—")
        #expect(add.labelError == L10n.string(L10n.SourceTypes.errorUnslugifiable))

        add.editLabel("Family scrapbook")
        #expect(await add.create() == nil)
        #expect(add.labelError == L10n.Errors.sourceTypesDuplicateKey(key: "family-scrapbook"))

        add.editLabel("Diary")
        #expect(add.labelError == nil)
    }

    @Test func addingCarriesThePickedIcon() async throws {
        let store = FakeStore()
        let (model, session) = makeModel(store: store, types: [seededType()])
        await warm(model, session: session)
        let add = makeAddModel(session, store: store)
        add.draft.label = "Diary"
        add.draft.iconKey = "type_photograph"
        let created = try #require(await add.create())
        #expect(created.iconKey == "type_photograph")
    }

    @Test func anotherCreateFailureShowsInTheDialog() async {
        let store = FakeStore()
        let (model, session) = makeModel(store: store)
        await warm(model, session: session)
        store.createSourceTypeError = AddFailure.boom
        let add = makeAddModel(session, store: store)
        add.draft.label = "Diary"

        #expect(await add.create() == nil)

        #expect(add.createError != nil)
        #expect(add.labelError == nil)
    }

    @Test func addIsDirtyFollowsWhatWasTyped() {
        let store = FakeStore()
        let (_, session) = makeModel(store: store)
        let add = makeAddModel(session, store: store)
        #expect(!add.isDirty)
        add.draft.label = "  "
        #expect(!add.isDirty)
        add.draft.label = "P"
        #expect(add.isDirty)

        let other = makeAddModel(session, store: store)
        other.draft.iconKey = "type_photograph"
        #expect(other.isDirty)
    }

    /// T-12 (AC-5.4): Add opens the new type's page, and the list model keeps no toast.
    @Test func createAndDeleteCommitThroughWorkspaceNavigation() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("types-nav-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("history.json")
        let navigation = WorkspaceNavigation()
        navigation.attachProject(uuid: "00000000-0000-7000-8000-0000000000cc", fileURL: url)
        navigation.go(to: .sectionRoot(.sourceTypes))

        let store = FakeStore()
        let (model, session) = makeModel(store: store)
        await warm(model, session: session)
        let add = makeAddModel(session, store: store)
        add.draft.label = "Parish register"
        let created = try #require(await add.create())
        navigation.go(to: .sourceTypePage(typeId: created.id, title: created.label))
        #expect(navigation.currentLocation.typeId == created.id)
        #expect(model.types.contains { $0.id == created.id })

        // The page deletes the type and leaves for the list; the list model shows nothing of it.
        let page = SourceTypePageModel(typeID: created.id, session: session, userID: userID, store: store)
        page.warm()
        await page.askDelete()
        #expect(await page.confirmDelete(leaving: { navigation.fallbackToSectionRoot() }))
        #expect(navigation.currentLocation == .sectionRoot(.sourceTypes))
        #expect(navigation.currentLocation.typeId == nil)
        #expect(model.types.isEmpty)
        #expect(page.toast == nil)
    }
}
