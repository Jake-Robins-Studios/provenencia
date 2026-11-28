import Foundation
import Testing
@testable import Provenencia

@Suite
@MainActor
struct SourcesModelTests {
    private let projectDir = "/tmp/sources.provenencia"
    private let userID = "00000000-0000-7000-8000-000000000001"

    private func photoType(id: String = "t1") -> CatalogSourceType {
        CatalogSourceType(
            id: id, key: "photograph", origin: "provenencia", label: "Photograph",
            description: "A photographic image."
        )
    }

    private func bookType(id: String = "t2") -> CatalogSourceType {
        CatalogSourceType(
            id: id, key: "book", origin: "provenencia", label: "Book",
            description: "A published monograph."
        )
    }

    private func source(
        id: String,
        title: String,
        typeID: String,
        ref: String = "SRC-AAAAA",
        updatedRevision: Int64 = 0,
        date: CatalogDateValueInput? = nil,
        dateSortKey: Int64? = nil,
        hasArtifact: Bool = false
    ) -> CatalogSource {
        CatalogSource(
            id: id,
            ref: ref,
            sourceTypeID: typeID,
            title: title,
            description: "",
            hasArtifact: hasArtifact,
            date: date,
            dateSortKey: dateSortKey,
            updated: CatalogActivity(revision: updatedRevision)
        )
    }

    private func makeSession(store: FakeStore) -> WorkspaceSession {
        WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)
    }

    private func makeModel(
        store: FakeStore = FakeStore(),
        sources: [CatalogSource] = [],
        types: [CatalogSourceType] = [],
        settingsStore: SourcesListSettingsStore? = nil
    ) -> (SourcesModel, WorkspaceSession) {
        store.sourcesByProject[projectDir] = sources
        for source in sources where source.hasArtifact && store.artifactsBySource[source.id] == nil {
            store.artifactsBySource[source.id] = [CatalogArtifact(
                id: "a-\(source.id)", ref: "ART-AAAAA", sourceID: source.id, fileID: "", label: "Scan",
                description: "", file: nil
            )]
        }
        store.sourceTypesByProject[projectDir] = types
        if store.evidenceGraphsByProject[projectDir] == nil {
            // One Default graph per Source, linking an Artifact, with an id that is not the Source's.
            store.evidenceGraphsByProject[projectDir] = sources.map {
                CatalogEvidenceGraph(
                    id: "g-\($0.id)", ref: "GPH-1", sourceID: $0.id, name: "Default", description: "",
                    artifactIDs: ["a-\($0.id)"]
                )
            }
        }
        let session = makeSession(store: store)
        let model = SourcesModel(
            session: session,
            userID: userID,
            store: store,
            settingsStore: settingsStore
        )
        return (model, session)
    }

    private func warmLists(_ model: SourcesModel, session: WorkspaceSession) async {
        model.warmListQueries()
        if let sourcesHandle: QueryHandle<[CatalogSource]> = session.queryHandle(
            SourcesModel.sourcesListKey(for: session)
        ) {
            await waitForQuery(sourcesHandle)
        }
        if let typesHandle: QueryHandle<[CatalogSourceType]> = session.queryHandle(
            session.sourceTypesKey
        ) {
            await waitForQuery(typesHandle)
        }
        if let graphsHandle: QueryHandle<[CatalogEvidenceGraph]> = session.queryHandle(
            CatalogQueryKey.evidenceGraphsList(project: session.projectKey)
        ) {
            await waitForQuery(graphsHandle)
        }
    }

    private func warmProgress(_ model: SourcesModel, session: WorkspaceSession) async {
        if let handle: QueryHandle<[String: EvidenceGraphProgress]> = session.queryHandle(
            session.evidenceGraphProgressKey
        ) {
            await waitForQuery(handle)
        }
    }

    private func progress(
        _ id: String, subjects: Int, filed: Int
    ) -> EvidenceGraphProgress {
        EvidenceGraphProgress(
            graphId: "g-\(id)", subjectCount: subjects, observationCount: 0,
            filedCount: filed
        )
    }

    private func tempSettingsFile() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("sources-settings-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("settings.json", isDirectory: false)
    }

    @Test func openCopySetsCopyingForThatSource() {
        let s1 = source(id: "s1", title: "Obit", typeID: "t1")
        let (model, _) = makeModel(sources: [s1], types: [photoType()])
        #expect(model.copying == nil)
        model.openCopy(s1)
        #expect(model.copying?.original.id == "s1")
    }

    @Test func sessionQueryPopulatesSourcesAndTypes() async {
        let store = FakeStore()
        let (model, session) = makeModel(
            store: store,
            sources: [
                source(id: "s1", title: "Album", typeID: "t1", ref: "SRC-0001"),
                source(id: "s2", title: "Deed", typeID: "t2", ref: "SRC-0002"),
            ],
            types: [photoType(), bookType()]
        )
        await warmLists(model, session: session)
        #expect(model.sources.count == 2)
        #expect(model.types.count == 2)
        let album = model.sources.first { $0.id == "s1" }
        #expect(album != nil)
        #expect(model.typeLabel(for: album!) == "Photograph")
    }

    @Test func listSourcesFillsThumbnailFromPinnedArtifact() async {
        let store = FakeStore()
        store.artifactsBySource["s1"] = [
            CatalogArtifact(
                id: "a1", ref: "ART-1", sourceID: "s1", fileID: "f1",
                label: "Front", description: "",
                file: CatalogFileRef(
                    id: "f1", relPath: "objects/aa/bb/file", originalFilename: "front.png",
                    mediaType: "image/png", byteSize: 12
                ),
                thumbnailRelPath: "objects/aa/bb/thumb"
            ),
        ]
        var src = source(id: "s1", title: "Album", typeID: "t1")
        src.coverMode = "artifact"
        src.primaryArtifactID = "a1"
        let (model, session) = makeModel(
            store: store,
            sources: [src],
            types: [photoType()]
        )
        await warmLists(model, session: session)
        #expect(model.sources.first?.thumbnailRelPath == "objects/aa/bb/thumb")
        #expect(model.sources.first?.coverMode == "artifact")
    }

    @Test func typeFilterNarrowsTheList() async {
        let (model, session) = makeModel(
            sources: [
                source(id: "s1", title: "A", typeID: "t1"),
                source(id: "s2", title: "B", typeID: "t2"),
                source(id: "s3", title: "C", typeID: "t1"),
            ],
            types: [photoType(), bookType()]
        )
        await warmLists(model, session: session)
        model.settings.typeFilterID = "t1"
        #expect(model.visibleSources.map(\.id) == ["s3", "s1"])
    }

    /// Each column both ways over equal titles, undated rows and equal revisions.
    @Test(arguments: [
        (SourcesSort(column: .added, order: .reverse), ["s5", "s4", "s3", "s2", "s1"]),
        (SourcesSort(column: .added, order: .forward), ["s1", "s2", "s3", "s4", "s5"]),
        (SourcesSort(column: .title, order: .forward), ["s4", "s2", "s5", "s3", "s1"]),
        (SourcesSort(column: .title, order: .reverse), ["s1", "s5", "s3", "s4", "s2"]),
        (SourcesSort(column: .updated, order: .reverse), ["s4", "s2", "s5", "s3", "s1"]),
        (SourcesSort(column: .updated, order: .forward), ["s1", "s3", "s5", "s2", "s4"]),
        (SourcesSort(column: .published, order: .reverse), ["s5", "s3", "s1", "s4", "s2"]),
        (SourcesSort(column: .published, order: .forward), ["s1", "s5", "s3", "s4", "s2"]),
    ])
    func sortsByColumnAndDirection(sort: SourcesSort, expected: [String]) async {
        let (model, session) = makeModel(
            sources: [
                source(id: "s1", title: "Charlie", typeID: "t1", updatedRevision: 1, dateSortKey: 100),
                source(id: "s2", title: "Alpha", typeID: "t1", updatedRevision: 3),
                source(id: "s3", title: "Bravo", typeID: "t1", updatedRevision: 2, dateSortKey: 200),
                source(id: "s4", title: "alpha", typeID: "t1", updatedRevision: 3),
                source(id: "s5", title: "Bravo", typeID: "t1", updatedRevision: 2, dateSortKey: 200),
            ],
            types: [photoType()]
        )
        await warmLists(model, session: session)
        model.settings.sort = sort
        #expect(model.visibleSources.map(\.id) == expected)
    }

    @Test func firstVisitSortsByAddedNewestFirst() {
        let (model, _) = makeModel()
        #expect(model.settings.sort == SourcesSort(column: .added, order: .reverse))
        #expect(SourcesSort.Column.allCases.map(\.firstOrder) == [.forward, .reverse, .reverse, .reverse])
    }

    // MARK: Date sorts (S15-04)

    private func datedSources() -> [CatalogSource] {
        [
            source(id: "s1", title: "Delta", typeID: "t1", dateSortKey: 100),
            source(id: "s2", title: "Echo", typeID: "t1", dateSortKey: 200),
            source(id: "s3", title: "Foxtrot", typeID: "t1", dateSortKey: 300),
            source(id: "s4", title: "Golf", typeID: "t1", dateSortKey: 400),
            source(id: "s5", title: "Bravo", typeID: "t1"),
            source(id: "s6", title: "Alpha", typeID: "t1"),
        ]
    }

    @Test func clearedDateMovesRowToUndatedTail() async throws {
        let store = FakeStore()
        let (model, session) = makeModel(store: store, sources: datedSources(), types: [photoType()])
        await warmLists(model, session: session)
        model.settings.sort = .dateOldest

        store.nextSourceDateSortKey = nil
        let (cleared, _) = try await store.setSourceDate(
            projectDir: projectDir, userID: userID, sourceID: "s1", date: nil
        )
        session.apply(.updatedSource(cleared))
        #expect(model.visibleSources.map(\.id) == ["s2", "s3", "s4", "s6", "s5", "s1"])

        store.nextSourceDateSortKey = 450
        let (dated, _) = try await store.setSourceDate(
            projectDir: projectDir, userID: userID, sourceID: "s5",
            date: CatalogDateValueInput(kind: "point", startYear: 1880, startMonth: 6, startDay: 1)
        )
        session.apply(.updatedSource(dated))
        #expect(model.visibleSources.map(\.id) == ["s2", "s3", "s4", "s5", "s6", "s1"])
    }

    @Test func dateSortAtScaleWithFilter() async {
        var all: [CatalogSource] = []
        for n in 0..<3000 {
            let id = String(format: "s%04d", n)
            all.append(source(
                id: id, title: "Source " + String(format: "%04d", n),
                typeID: n % 2 == 0 ? "t1" : "t2",
                dateSortKey: n % 30 == 0 ? Int64(n) : nil
            ))
        }
        let (model, session) = makeModel(sources: all, types: [photoType(), bookType()])
        await warmLists(model, session: session)
        model.settings.typeFilterID = "t1"
        _ = model.visibleSources
        let before = session.derivedBuildCount(.visibleSources)
        model.settings.sort = .dateOldest
        let rows = model.visibleSources
        #expect(session.derivedBuildCount(.visibleSources) == before + 1)
        #expect(rows.count == 1500)
        let dated = (0..<100).map { String(format: "s%04d", $0 * 30) }
        #expect(rows.prefix(100).map(\.id) == dated)
        let undated = (0..<3000).filter { $0 % 2 == 0 && $0 % 30 != 0 }.map { String(format: "s%04d", $0) }
        #expect(rows.dropFirst(100).map(\.id) == undated)
    }

    @Test func createRequiresTypeAndTitle() async {
        let (model, session) = makeModel(types: [photoType(), bookType()])
        await warmLists(model, session: session)
        model.openAdd()
        #expect(model.draft.sourceTypeID.isEmpty)
        let created = await model.create()
        #expect(created == nil)
        #expect(model.typeError != nil)
        #expect(model.titleError != nil)
        #expect(model.isAdding)
    }

    @Test func draftValidation() {
        let empty = SourcesModel.Draft(sourceTypeID: "", title: "  ").validation
        #expect(empty.typeError == L10n.string(L10n.Sources.typeRequired))
        #expect(empty.titleError == L10n.string(L10n.Sources.titleRequired))
        #expect(!empty.isValid)

        let draft = SourcesModel.Draft(sourceTypeID: "t1", title: " Album ")
        #expect(draft.validation.typeError == nil)
        #expect(draft.validation.titleError == nil)
        #expect(draft.validation.isValid)
        #expect(draft.trimmedTitle == "Album")
        #expect(draft.validation.dateError == nil)

        func validation(_ edit: (inout DateValueDraft) -> Void) -> SourcesModel.SourceDraftValidation {
            var draft = SourcesModel.Draft(sourceTypeID: "t1", title: "Album")
            edit(&draft.date)
            return draft.validation
        }
        // Month 13: the form shows its own error, so there is no second line, yet the draft is not valid.
        let month13 = validation { $0.startYear = 1880; $0.startMonth = 13 }
        #expect(month13.dateError == nil)
        #expect(!month13.isValid)
        // A phrase and a time zone, no year: the line shows.
        let incomplete = validation { $0.phrase = "Spring 1880"; $0.startTZ = "America/Chicago" }
        #expect(incomplete.dateError == L10n.string(L10n.Sources.dateUnsavableZone))
        #expect(!incomplete.isValid)
        // A phrase alone is a valid date; a time zone alone is blank.
        #expect(validation { $0.phrase = "Spring 1880" }.isValid)
        #expect(validation { $0.phrase = "Spring 1880" }.dateError == nil)
        let zoneOnly = validation { $0.startTZ = "America/Chicago" }
        #expect(zoneOnly.dateError == nil)
        #expect(zoneOnly.isValid)
        // A range with only an end year has no field error and is not valid.
        let endOnly = validation { $0.setKind("range"); $0.endYear = 1880 }
        #expect(endOnly.dateError != nil)
        #expect(!endOnly.isValid)
    }

    @Test func canSubmitAddFollowsValidation() async {
        let (model, session) = makeModel(types: [photoType(), bookType()])
        await warmLists(model, session: session)
        model.openAdd()
        #expect(!model.canSubmitAdd)
        model.draft.sourceTypeID = "t1"
        model.draft.title = "Album"
        #expect(model.canSubmitAdd)
        model.draft.title = " "
        #expect(!model.canSubmitAdd)
    }

    @Test func addSheetDirtyCountsDateAndPrivate() async {
        let (model, session) = makeModel(types: [photoType(), bookType()])
        await warmLists(model, session: session)

        model.openAdd()
        #expect(!model.addSheetIsDirty)
        model.draft.isPrivate = true
        #expect(model.addSheetIsDirty)

        model.openAdd()
        model.draft.date.startYear = 1880
        #expect(model.addSheetIsDirty)

        model.openAdd()
        model.draft.date.setKind("range")
        model.draft.date.showAdvanced = true
        #expect(!model.addSheetIsDirty)
        model.draft.sourceTypeID = "t1"
        model.draft.title = "Album"
        #expect(model.canSubmitAdd)
        model.draft.sourceTypeID = ""
        #expect(!model.canSubmitAdd)
    }

    @Test func createSendsDateAndPrivate() async {
        let (model, session) = makeModel(types: [photoType()])
        await warmLists(model, session: session)

        model.openAdd()
        model.draft.sourceTypeID = "t1"
        model.draft.title = "1880 census"
        model.draft.date.startYear = 1880
        model.draft.date.startMonth = 6
        model.draft.date.startDay = 1
        model.draft.isPrivate = true
        let dated = await model.create()
        #expect(dated?.date?.startYear == 1880)
        #expect(dated?.date?.startMonth == 6)
        #expect(dated?.date?.startDay == 1)
        #expect(dated?.isPublic == false)

        model.openAdd()
        model.draft.sourceTypeID = "t1"
        model.draft.title = "Undated"
        let blank = await model.create()
        #expect(blank?.date == nil)
        #expect(blank?.isPublic == true)
    }

    @Test func createReturnsSourceAndRefreshesList() async {
        let (model, session) = makeModel(types: [photoType()])
        await warmLists(model, session: session)
        session.apply(location: .sectionRoot(.sources))

        model.openAdd()
        model.draft.sourceTypeID = "t1"
        model.draft.title = "  Family album  "
        model.draft.description = "Nan's prints"
        let created = await model.create()
        if let handle: QueryHandle<[CatalogSource]> = session.queryHandle(
            SourcesModel.sourcesListKey(for: session)
        ) {
            await waitForQuery(handle)
        }

        #expect(!model.isAdding)
        #expect(created?.title == "Family album")
        #expect(model.sources.count == 1)
        #expect(!session.toasts.cards.isEmpty)
    }

    /// The Sources list re-reads one row per Source `source_holdings` names (D-16) and leaves
    /// the other rows alone; `source_records` alone reads nothing.
    @Test func listRowsFollowSourceHoldings() async {
        let store = FakeStore()
        var s1 = source(id: "s1", title: "Census", typeID: "t1", ref: "SRC-AAAAA")
        s1.hasArtifact = true
        let (model, session) = makeModel(
            store: store,
            sources: [s1, source(id: "s2", title: "Deed", typeID: "t1", ref: "SRC-BBBBB"),
                      source(id: "s3", title: "Will", typeID: "t1", ref: "SRC-CCCCC")],
            types: [photoType()]
        )
        // The engine's rows after a move of s1's only Artifact to s2.
        store.artifactsBySource = ["s2": [catalogArtifact("a1", sourceID: "s2")]]
        await warmLists(model, session: session)
        session.apply(location: .sectionRoot(.sources))

        session.apply(CatalogWriteEffects(reads: [CatalogWriteEffectsRead(read: .sourceRecords, ids: ["s1", "s2"])]))
        await session.settleWrites()
        #expect(store.listSourcesByIDCalls.isEmpty)

        session.apply(CatalogWriteEffects(reads: [CatalogWriteEffectsRead(read: .sourceHoldings, ids: ["s1", "s2"])]))
        await session.settleWrites()

        #expect(store.listSourcesByIDCalls.sorted { $0[0] < $1[0] } == [["s1"], ["s2"]])
        let rows = Dictionary(uniqueKeysWithValues: model.sources.map { ($0.id, $0) })
        #expect(rows["s1"]?.hasArtifact == false)
        #expect(rows["s2"]?.hasArtifact == true)
        #expect(rows["s3"]?.title == "Will")
        #expect(rows.count == 3)
    }

    @Test func createInsertsTheRowThroughSession() async {
        let store = FakeStore()
        let (model, session) = makeModel(
            store: store,
            sources: [source(id: "s1", title: "Deed", typeID: "t1")],
            types: [photoType()]
        )
        await warmLists(model, session: session)
        session.apply(location: .sectionRoot(.sources))

        model.openAdd()
        model.draft.sourceTypeID = "t1"
        model.draft.title = "Family album"
        _ = await model.create()
        if let handle: QueryHandle<[CatalogSource]> = session.queryHandle(
            SourcesModel.sourcesListKey(for: session)
        ) {
            await waitForQuery(handle)
        }

        #expect(Set(model.sources.map(\.title)) == ["Deed", "Family album"])
    }

    /// T-8: Add Source puts the returned row into the cached list; it does not reload it.
    @Test func addSourceInsertsTheReturnedRow() async {
        let store = FakeStore()
        let (model, session) = makeModel(
            store: store,
            sources: [
                source(id: "s1", title: "Album", typeID: "t1"),
                source(id: "s2", title: "Will", typeID: "t1"),
            ],
            types: [photoType()]
        )
        await warmLists(model, session: session)
        let callsBefore = store.listSourcesCalls
        let key = SourcesModel.sourcesListKey(for: session)

        model.openAdd()
        model.draft.sourceTypeID = "t1"
        model.draft.title = "Deed"
        let created = await model.create()
        await session.settleWrites()

        let rows: [CatalogSource]? = session.queryHandle(key)?.value
        #expect(rows?.count == 3)
        #expect(rows?.last == created)
        #expect(store.listSourcesCalls == callsBefore)

        // The same create applied again replaces the row; it does not duplicate it.
        if let created {
            session.apply(.createdSource(created))
            #expect((session.queryHandle(key)?.value as [CatalogSource]?)?.count == 3)
        }
    }

    /// T-8: an update or type change of a row the list lacks appends nothing, and
    /// a list that was never warmed gets no handle.
    @Test func sourceRowAppendsOnlyForACreate() async {
        let store = FakeStore()
        let (model, session) = makeModel(
            store: store,
            sources: [source(id: "s1", title: "Album", typeID: "t1")],
            types: [photoType()]
        )
        let key = SourcesModel.sourcesListKey(for: session)
        let stranger = source(id: "s9", title: "Stranger", typeID: "t1")
        session.apply(.createdSource(stranger))
        let unwarmed: QueryHandle<[CatalogSource]>? = session.queryHandle(key)
        #expect(unwarmed == nil)

        await warmLists(model, session: session)
        session.apply(.updatedSource(stranger))
        session.apply(.changedSourceType(stranger))
        #expect((session.queryHandle(key)?.value as [CatalogSource]?)?.map(\.id) == ["s1"])
    }

    /// T-16: the rows are built once per change of an input, not once per read.
    @Test func visibleSourcesBuildsOncePerInputChange() async {
        let store = FakeStore()
        let (model, session) = makeModel(
            store: store,
            sources: [
                source(id: "s1", title: "Album", typeID: "t1"),
                source(id: "s2", title: "Deed", typeID: "t1"),
                source(id: "s3", title: "Will", typeID: "t1"),
            ],
            types: [photoType()]
        )
        await warmLists(model, session: session)
        model.settings.sort = .az
        #expect(model.visibleSources.map(\.title) == ["Album", "Deed", "Will"])
        #expect(session.derivedBuildCount(.visibleSources) == 1)

        model.openAdd()
        for title in ["D", "De", "Dee"] {
            model.draft.title = title
            _ = model.visibleSources
        }
        #expect(session.derivedBuildCount(.visibleSources) == 1)

        model.settings.query = "deed"
        #expect(model.visibleSources.map(\.title) == ["Deed"])
        #expect(session.derivedBuildCount(.visibleSources) == 2)

        let sourcesKey = SourcesModel.sourcesListKey(for: session)
        session.setQueryValue(sourcesKey, value: model.sources)
        _ = model.visibleSources
        #expect(session.derivedBuildCount(.visibleSources) == 3)

        // Without a status filter the progress revision is not an input.
        session.setQueryValue(session.evidenceGraphProgressKey, value: [String: EvidenceGraphProgress]())
        _ = model.visibleSources
        #expect(session.derivedBuildCount(.visibleSources) == 3)

        model.settings.query = ""
        model.settings.status = .empty
        _ = model.visibleSources
        let afterFilter = session.derivedBuildCount(.visibleSources)
        session.setQueryValue(session.evidenceGraphProgressKey, value: [String: EvidenceGraphProgress]())
        _ = model.visibleSources
        #expect(session.derivedBuildCount(.visibleSources) == afterFilter + 1)
    }

    @Test func cancelAddDoesNotCreate() async {
        let (model, session) = makeModel(types: [photoType()])
        await warmLists(model, session: session)
        model.openAdd()
        model.draft.title = "Unused"
        model.cancelAdd()
        #expect(!model.isAdding)
        #expect(model.sources.isEmpty)
    }

    @Test func refreshTypesWarmsTypesHandle() async {
        let store = FakeStore()
        let (model, session) = makeModel(store: store, types: [])
        model.warmListQueries()
        store.sourceTypesByProject[projectDir] = [photoType(), bookType()]
        session.invalidate(CatalogQueryKey.sourceTypesList(project: session.projectKey))
        model.refreshTypes()
        if let typesHandle: QueryHandle<[CatalogSourceType]> = session.queryHandle(
            session.sourceTypesKey
        ) {
            await waitForQuery(typesHandle)
        }
        #expect(model.types.map(\.id) == ["t1", "t2"])
        #expect(model.types.count == 2)
    }

    @Test func typesHandleLoadsWhenSourcesListFails() async {
        enum Boom: Error { case boom }
        let store = FakeStore()
        store.listSourcesError = Boom.boom
        let (model, session) = makeModel(store: store, types: [photoType()])
        await warmLists(model, session: session)
        #expect(model.types.map(\.id) == ["t1"])
        #expect(model.loadError != nil)
    }

    @Test func typeIconKeyResolvesFromSourceType() async {
        var photo = photoType()
        photo.iconKey = "type_photograph"
        let (model, session) = makeModel(
            sources: [source(id: "s1", title: "Album", typeID: "t1")],
            types: [photo]
        )
        await warmLists(model, session: session)
        #expect(model.typeIconKey(for: model.sources[0]) == "type_photograph")
    }

    @Test func cacheHitSkipsSecondListLoad() async {
        let store = FakeStore()
        let (model, session) = makeModel(
            store: store,
            sources: [source(id: "s1", title: "Album", typeID: "t1")],
            types: [photoType()]
        )
        await warmLists(model, session: session)
        store.sourcesByProject[projectDir] = [
            source(id: "s2", title: "Other", typeID: "t1", ref: "SRC-0002"),
        ]

        let _: QueryHandle<[CatalogSource]> = session.query(
            CatalogQueryKey.sourcesList(project: session.projectKey)
        )
        await Task.yield()
        #expect(model.sources.first?.title == "Album")
    }

    @Test func updatedSourcePatchesListRow() async {
        let store = FakeStore()
        let (model, session) = makeModel(
            store: store,
            sources: [source(id: "s1", title: "Deed", typeID: "t1")],
            types: [photoType()]
        )
        await warmLists(model, session: session)

        var updated = source(id: "s1", title: "Deed renamed", typeID: "t1")
        updated.coverMode = "type_icon"
        session.apply(.updatedSource(updated))

        #expect(model.sources.first?.title == "Deed renamed")
        #expect(model.sources.first?.coverMode == "type_icon")
    }

    /// A write's activity moves the row in the Updated sort without a reload.
    @Test func writeActivityMovesTheRowInTheUpdatedSort() async {
        let (model, session) = makeModel(
            sources: [
                source(id: "s1", title: "Deed", typeID: "t1", updatedRevision: 5),
                source(id: "s2", title: "Letter", typeID: "t1", updatedRevision: 9),
            ],
            types: [photoType()]
        )
        await warmLists(model, session: session)
        model.settings.sort = .updated
        #expect(model.visibleSources.map(\.id) == ["s2", "s1"])

        session.apply(CatalogWriteEffects(
            sourceScopes: ["s1"],
            activity: CatalogActivity(revision: 12, at: "2026-10-15T16:00:00Z")
        ))

        #expect(model.visibleSources.map(\.id) == ["s1", "s2"])
    }

    @Test func warmListQueriesLoadsGraphProgress() async {
        let store = FakeStore()
        store.graphProgressByGraph["g-s1"] = EvidenceGraphProgress(
            graphId: "g-s1", subjectCount: 4, observationCount: 0
        )
        let (model, session) = makeModel(
            store: store,
            sources: [source(id: "s1", title: "Album", typeID: "t1")],
            types: [photoType()]
        )
        await warmLists(model, session: session)
        if let progressHandle: QueryHandle<[String: EvidenceGraphProgress]> = session.queryHandle(
            session.evidenceGraphProgressKey
        ) {
            await waitForQuery(progressHandle)
        }
        #expect(session.evidenceGraphProgress(graphID: "g-s1")?.subjectCount == 4)
        #expect(model.graphCountsLoading == false)
    }

    @Test func graphProgressCopyMatchesBoard() {
        #expect(L10n.Sources.graphCountLine(subjects: 12, observations: 48) == "12 subjects · 48 observations")
        #expect(L10n.Sources.graphSubjectCount(0) == "0 subjects")

        let jones = EvidenceGraphProgress(graphId: "g1", subjectCount: 12, observationCount: 40)
        #expect(SourcesGraphCounts(progress: nil, countsLoading: true, countsError: nil) == .loading)
        #expect(SourcesGraphCounts(progress: nil, countsLoading: false, countsError: nil) == .notStarted)
        #expect(SourcesGraphCounts(progress: .zeros(graphId: "g1"), countsLoading: false, countsError: nil) == .notStarted)
        #expect(
            SourcesGraphCounts(progress: jones, countsLoading: true, countsError: nil)
                == .counts(subjects: 12, observations: 40, filed: 0)
        )
        let counts = SourcesGraphCounts(progress: jones, countsLoading: false, countsError: nil)
        #expect(counts == .counts(subjects: 12, observations: 40, filed: 0))

        #expect(L10n.Sources.graphCounts(counts, style: .full) == "12 subjects · 40 observations")
        #expect(L10n.Sources.graphCounts(.notStarted, style: .full) == "0 subjects · not started")
        #expect(L10n.Sources.graphCounts(counts, style: .spoken) == "12 subjects, 40 observations")
        #expect(L10n.Sources.graphCounts(.notStarted, style: .spoken) == "0 subjects, not started")
        let unavailable = SourcesGraphCounts.unavailable(message: "Disk is full")
        #expect(L10n.Sources.graphCounts(unavailable, style: .full) == "Counts could not load")
        #expect(L10n.Sources.graphCounts(unavailable, style: .spoken) == "Counts could not load. Disk is full")

        #expect(L10n.Sources.graphCounts(.notStarted, style: .full, notStarted: .zeroCounts) == "0 subjects · 0 observations")
        #expect(L10n.Sources.graphCounts(.notStarted, style: .spoken, notStarted: .zeroCounts) == "0 subjects, 0 observations")
        #expect(L10n.Sources.graphCounts(counts, style: .full, notStarted: .zeroCounts) == "12 subjects · 40 observations")
        #expect(L10n.Sources.graphCounts(.loading, style: .full, notStarted: .zeroCounts) == "counts loading")
        #expect(L10n.Sources.graphCounts(unavailable, style: .full, notStarted: .zeroCounts) == "Counts could not load")

        #expect(SourcesGraphCounts.notStarted.status == .empty)
        #expect(SourcesGraphCounts.counts(subjects: 5, observations: 2, filed: 0).status == .inProgress)
        #expect(SourcesGraphCounts.counts(subjects: 5, observations: 2, filed: 1).status == .promoted)
        #expect(SourcesGraphCounts.loading.status == nil)
        #expect(unavailable.status == nil)

        let notStartedText = SourcesGraphCountLine.countsText(.notStarted, style: .card)
        let zero = notStartedText.runs.first { String(notStartedText[$0.range].characters) == "0" }
        #expect(zero?[AttributeScopes.SwiftUIAttributes.FontAttribute.self] == PVFont.mono(size: PVTypeScale.micro))
        let words = notStartedText.runs.first { String(notStartedText[$0.range].characters) == "not started" }
        #expect(words?[AttributeScopes.SwiftUIAttributes.FontAttribute.self] == PVFont.body(size: PVTypeScale.micro).italic())
    }

    @Test func publishedDateTextAndSpokenRow() {
        let en = Locale(identifier: "en_US")
        let point = CatalogDateValueInput(kind: "point", startYear: 1880, startMonth: 6, startDay: 1)
        #expect(SourceDateText.line(point, locale: en) == "1 Jun 1880")
        #expect(SourceDateText.line(
            CatalogDateValueInput(kind: "point", phrase: "in the reign of Victoria"), locale: en
        ) == "in the reign of Victoria")
        #expect(SourceDateText.line(nil, locale: en) == nil)
        #expect(SourceDateText.line(CatalogDateValueInput(kind: "range", startYear: 1834), locale: en) == nil)
        #expect(SourceDateText.help(point, locale: en) == "Published 1 Jun 1880")
        #expect(SourceDateText.help(nil, locale: en) == nil)
        #expect(
            SourceDateText.spokenRow(title: "T", type: "Census", ref: "SRC-1", date: nil, locale: en)
                == "T, Census, no published date, SRC-1"
        )
    }

    @Test func listReadsEachGraphsProgress() async {
        let store = FakeStore()
        let sources = [source(id: "s1", title: "Census", typeID: "t1")]
        store.evidenceGraphsByProject[projectDir] = [
            CatalogEvidenceGraph(
                id: "g-smith", ref: "GPH-3", sourceID: "s1", name: "Smith household", description: "", artifactIDs: ["a"]
            ),
            CatalogEvidenceGraph(
                id: "g-default", ref: "GPH-1", sourceID: "s1", name: "Default", description: "", artifactIDs: ["a"]
            ),
            CatalogEvidenceGraph(
                id: "g-jones", ref: "GPH-2", sourceID: "s1", name: "Jones household", description: "", artifactIDs: ["a"]
            ),
        ]
        store.graphProgressByGraph["g-jones"] = EvidenceGraphProgress(
            graphId: "g-jones", subjectCount: 12, observationCount: 40
        )
        let (model, session) = makeModel(store: store, sources: sources, types: [photoType()])
        await warmLists(model, session: session)
        await warmProgress(model, session: session)

        guard case .loaded(let graphs) = session.evidenceGraphsRead(sourceID: "s1") else {
            Issue.record("expected the Source's graphs")
            return
        }
        #expect(graphs.map(\.name) == ["Smith household", "Default", "Jones household"])
        #expect(session.evidenceGraphProgress(graphID: "g-jones")?.subjectCount == 12)
        #expect(session.evidenceGraphProgress(graphID: "g-jones")?.observationCount == 40)
        #expect(session.evidenceGraphProgress(graphID: "g-default") == nil)
        #expect(session.evidenceGraphProgress(graphID: "g-smith") == nil)

        store.graphProgressByGraph["g-jones"] = EvidenceGraphProgress(
            graphId: "g-jones", subjectCount: 12, observationCount: 41
        )
        session.apply(CatalogWriteEffects(
            evidenceGraphs: ["g-jones"], reads: [CatalogWriteEffectsRead(read: .evidenceGraphProgress, ids: ["g-jones"])]
        ))
        await session.settleWrites()
        #expect(session.evidenceGraphProgress(graphID: "g-jones")?.observationCount == 41)
        #expect(session.evidenceGraphProgress(graphID: "g-default") == nil)
        #expect(session.evidenceGraphProgress(graphID: "g-smith") == nil)
    }

    @Test func graphRowCopyMatchesBoard() {
        #expect(L10n.Sources.openEvidenceGraphLabel(name: "Jones household") == "Open graph Jones household")
        #expect(
            L10n.DesignSystem.spokenJoin([
                "Jones household", "12 subjects, 40 observations",
                L10n.string(SourcesModel.EvidenceStatus.inProgress.label),
            ]) == "Jones household, 12 subjects, 40 observations, In progress"
        )
        #expect(
            L10n.DesignSystem.spokenJoin(["Jones household", "counts loading", ""]) == "Jones household, counts loading"
        )
        #expect(L10n.Sources.menuOpenGraph("Default") == "Open Default")
        #expect(L10n.string(L10n.Sources.menuOpen) == "Open")
        #expect(L10n.string(L10n.Sources.showGraphs) == "Show evidence graphs")
        #expect(L10n.string(L10n.Sources.hideGraphs) == "Hide evidence graphs")
        #expect(L10n.string(L10n.Sources.graphNeedsArtifactToOpen) == "Needs an artifact to open")
        #expect(L10n.string(L10n.Sources.needsArtifact) == "Needs an artifact")
        #expect(L10n.string(L10n.Sources.graphsLoading) == "Evidence graphs loading")
    }

    @Test func rowsWaitForTheGraphList() async {
        enum Boom: Error { case boom }
        let (model, session) = makeModel(
            sources: [source(id: "s1", title: "A", typeID: "t1")], types: [photoType()]
        )
        #expect(model.isAwaitingGraphList)
        let _: QueryHandle<[CatalogEvidenceGraph]> = session.query(session.evidenceGraphsKey)
        #expect(model.isAwaitingGraphList)
        await warmLists(model, session: session)
        #expect(!model.isAwaitingGraphList)

        let store = FakeStore()
        store.listEvidenceGraphsError = Boom.boom
        let (failing, failingSession) = makeModel(
            store: store, sources: [source(id: "s1", title: "A", typeID: "t1")], types: [photoType()]
        )
        await warmLists(failing, session: failingSession)
        #expect(!failing.isAwaitingGraphList)
        #expect(failing.graphListError != nil)
    }

    private func graph(
        _ id: String, source: String, hasArtifact: Bool = true
    ) -> CatalogEvidenceGraph {
        CatalogEvidenceGraph(
            id: id, ref: "GPH-\(id)", sourceID: source, name: id, description: "",
            artifactIDs: hasArtifact ? ["a"] : []
        )
    }

    /// The Source's one status over every mix of its graphs' statuses.
    @Test func oneStatusPerSource() async {
        typealias Status = SourcesModel.EvidenceStatus
        #expect(Status.aggregate([]) == nil)
        #expect(Status.aggregate([.promoted, .promoted]) == .promoted)
        #expect(Status.aggregate([.empty, .empty, .empty]) == .empty)
        #expect(Status.aggregate([.promoted, .empty]) == .inProgress)
        #expect(Status.aggregate([.inProgress]) == .inProgress)
        #expect(Status.aggregate([.inProgress] + Array(repeating: .empty, count: 7)) == .inProgress)

        let store = FakeStore()
        let sources = ["all-promoted", "all-empty", "mixed", "one-of-eight", "bare", "bare-beside", "no-artifact"]
            .map { source(id: $0, title: $0, typeID: "t1", hasArtifact: $0 != "no-artifact") }
        var graphs: [CatalogEvidenceGraph] = [
            graph("p1", source: "all-promoted"), graph("p2", source: "all-promoted"),
            graph("e1", source: "all-empty"), graph("e2", source: "all-empty"),
            graph("m1", source: "mixed"), graph("m2", source: "mixed"),
            graph("bare1", source: "bare", hasArtifact: false),
            graph("bb1", source: "bare-beside", hasArtifact: false), graph("bb2", source: "bare-beside"),
        ]
        graphs += (1 ... 8).map { graph("o\($0)", source: "one-of-eight") }
        store.evidenceGraphsByProject[projectDir] = graphs
        for id in ["p1", "p2", "bb2", "m1"] {
            store.graphProgressByGraph[id] = EvidenceGraphProgress(
                graphId: id, subjectCount: 3, observationCount: 5, filedCount: 1
            )
        }
        store.graphProgressByGraph["o4"] = EvidenceGraphProgress(graphId: "o4", subjectCount: 2, observationCount: 2)
        let (model, session) = makeModel(store: store, sources: sources, types: [photoType()])
        #expect(model.status(for: sources[0]) == nil)
        await warmLists(model, session: session)
        await warmProgress(model, session: session)

        let expected: [String: Status?] = [
            "all-promoted": .promoted, "all-empty": .empty, "mixed": .inProgress, "one-of-eight": .inProgress,
            "bare": .empty, "bare-beside": .inProgress, "no-artifact": nil,
        ]
        for source in sources {
            #expect(model.status(for: source) == expected[source.id]!, "\(source.id)")
        }
    }

    @Test func noBadgeWithoutTheGraphList() async {
        enum Boom: Error { case boom }
        let store = FakeStore()
        store.listEvidenceGraphsError = Boom.boom
        let sources = [source(id: "s1", title: "A", typeID: "t1", hasArtifact: true)]
        let (model, session) = makeModel(store: store, sources: sources, types: [photoType()])
        await warmLists(model, session: session)
        #expect(model.status(for: sources[0]) == nil)
    }

    /// While the counts load or when they failed, a Source with a graph that links an Artifact
    /// shows no badge; a Source whose only graph links none is Not started either way, and never waits.
    @Test func aGraphWithNoArtifactDoesNotWaitForCountsAndALinkedOneDoes() async {
        enum Boom: Error { case boom }
        let sources = [
            source(id: "linked", title: "Linked", typeID: "t1", hasArtifact: true),
            source(id: "bare", title: "Bare", typeID: "t1", hasArtifact: true),
        ]
        func store() -> FakeStore {
            let store = FakeStore()
            store.evidenceGraphsByProject[projectDir] = [
                graph("g-linked", source: "linked"), graph("g-bare", source: "bare", hasArtifact: false),
            ]
            return store
        }

        // The progress read has started and not answered: the counts are loading.
        let loading = store()
        loading.listEvidenceGraphProgressHold.isOn = true
        let (loadingModel, loadingSession) = makeModel(
            store: loading, sources: sources, types: [photoType()]
        )
        await warmLists(loadingModel, session: loadingSession)
        await loading.listEvidenceGraphProgressHold.untilSuspended(1)
        #expect(loadingModel.graphCountsLoading)
        #expect(loadingModel.status(for: sources[0]) == nil)
        #expect(loadingModel.status(for: sources[1]) == .empty)
        loading.listEvidenceGraphProgressHold.isOn = false
        loading.listEvidenceGraphProgressHold.release()

        // The read failed.
        let failing = store()
        failing.listEvidenceGraphProgressError = Boom.boom
        let (failedModel, failedSession) = makeModel(
            store: failing, sources: sources, types: [photoType()]
        )
        await warmLists(failedModel, session: failedSession)
        await warmProgress(failedModel, session: failedSession)
        #expect(failedModel.status(for: sources[0]) == nil)
        #expect(failedModel.status(for: sources[1]) == .empty)
    }

    /// The filter keeps what the badge shows.
    @Test func statusFilterMatchesTheBadge() async {
        let store = FakeStore()
        let sources = [
            source(id: "s1", title: "Census", typeID: "t1", hasArtifact: true),
            source(id: "s2", title: "Photo", typeID: "t1", hasArtifact: true),
        ]
        store.evidenceGraphsByProject[projectDir] = [
            graph("g-default", source: "s1"), graph("g-jones", source: "s1"), graph("g-smith", source: "s1"),
            graph("g-photo", source: "s2"),
        ]
        store.graphProgressByGraph["g-jones"] = EvidenceGraphProgress(
            graphId: "g-jones", subjectCount: 12, observationCount: 40
        )
        store.graphProgressByGraph["g-smith"] = EvidenceGraphProgress(
            graphId: "g-smith", subjectCount: 7, observationCount: 19, filedCount: 1
        )
        let (model, session) = makeModel(store: store, sources: sources, types: [photoType()])
        await warmLists(model, session: session)
        await warmProgress(model, session: session)

        #expect(model.status(for: sources[0]) == .inProgress)
        #expect(model.status(for: sources[1]) == .empty)
        model.settings.status = .empty
        #expect(model.visibleSources.map(\.id) == ["s2"])
        model.settings.status = .inProgress
        #expect(model.visibleSources.map(\.id) == ["s1"])
        model.settings.status = .promoted
        #expect(model.visibleSources.isEmpty)
    }

    @Test func statusBadgeMatchesBoard() {
        typealias Status = SourcesModel.EvidenceStatus
        #expect(L10n.string(Status.empty.label) == "Not started")
        #expect(Status.empty.badgeTone == .neutral)
        #expect(Status.empty.badgeIcon == .circleDashed)
        #expect(L10n.string(Status.inProgress.label) == "In progress")
        #expect(Status.inProgress.badgeTone == .warning)
        #expect(Status.inProgress.badgeIcon == .circleDot)
        #expect(L10n.string(Status.promoted.label) == "Promoted")
        #expect(Status.promoted.badgeTone == .success)
        #expect(Status.promoted.badgeIcon == .circleCheck)
        #expect(Status.allCases.filter(\.badgeSubtle) == [.empty])
    }

    @Test func settingsRestoreOnNewModel() async throws {
        let url = try tempSettingsFile()
        let uuid = "00000000-0000-7000-8000-0000000000aa"
        let storeA = try #require(SourcesListSettingsStore(projectUuid: uuid, userID: userID, fileURL: url))
        let (a, _) = makeModel(types: [photoType()], settingsStore: storeA)
        a.settings.sort = .az
        a.settings.typeFilterID = "t1"
        a.settings.status = .promoted
        a.settings.query = "smith"

        let storeB = try #require(SourcesListSettingsStore(projectUuid: uuid, userID: userID, fileURL: url))
        let (b, _) = makeModel(types: [photoType()], settingsStore: storeB)
        #expect(b.settings == a.settings)
        #expect(b.settings.sort == .az)
        #expect(b.settings.status == .promoted)
    }

    @Test func searchMatchesTitleAndRefIgnoringCaseAndAccents() async {
        let (model, session) = makeModel(
            sources: [
                source(id: "s1", title: "Smith family Bible", typeID: "t1", ref: "SRC-1AAAA"),
                source(id: "s2", title: "1851 census", typeID: "t1", ref: "SRC-4F2NP"),
                source(id: "s3", title: "José Ruiz letter", typeID: "t1", ref: "SRC-3CCCC"),
            ],
            types: [photoType()]
        )
        await warmLists(model, session: session)

        model.settings.query = "smith"
        #expect(model.visibleSources.map(\.id) == ["s1"])
        model.settings.query = "jose"
        #expect(model.visibleSources.map(\.id) == ["s3"])
        model.settings.query = "src-4f"
        #expect(model.visibleSources.map(\.id) == ["s2"])
        model.settings.query = "smith-family"
        #expect(model.visibleSources.map(\.id) == ["s1"])
        model.settings.query = "1851census"
        #expect(model.visibleSources.map(\.id) == ["s2"])
        model.settings.query = "  "
        #expect(model.visibleSources.count == 3)
        #expect(!model.isFiltering)
        model.settings.query = "-"
        #expect(model.visibleSources.count == 3)
        #expect(model.isFiltering)
    }

    @Test func searchSeesAnEditedTitle() async {
        let (model, session) = makeModel(
            sources: [source(id: "s1", title: "Smith family Bible", typeID: "t1", updatedRevision: 1)],
            types: [photoType()]
        )
        await warmLists(model, session: session)
        model.settings.query = "smith"
        #expect(model.visibleSources.map(\.id) == ["s1"])

        session.apply(.updatedSource(source(id: "s1", title: "Jones diary", typeID: "t1", updatedRevision: 2)))
        #expect(model.visibleSources.map(\.id) == [])
        model.settings.query = "jones"
        #expect(model.visibleSources.map(\.id) == ["s1"])
    }

    @Test func filtersCombineAndClear() async {
        let store = FakeStore()
        var sources: [CatalogSource] = []
        for index in 1 ... 8 {
            let typeID = index <= 4 ? "t1" : "t2"
            let title = index == 1 || index == 2 ? "Smith record \(index)" : "Other record \(index)"
            sources.append(source(id: "s\(index)", title: title, typeID: typeID, ref: "SRC-0000\(index)", hasArtifact: true))
        }
        for id in ["s1", "s2", "s5"] {
            store.graphProgressByGraph["g-\(id)"] = progress(id, subjects: 2, filed: 0)
        }
        store.graphProgressByGraph["g-s3"] = progress("s3", subjects: 1, filed: 1)
        let (model, session) = makeModel(
            store: store, sources: sources, types: [photoType(), bookType()]
        )
        await warmLists(model, session: session)
        await warmProgress(model, session: session)

        model.settings.sort = .az
        model.settings.typeFilterID = "t1"
        model.settings.status = .inProgress
        model.settings.query = "smith"
        #expect(model.visibleSources.map(\.id) == ["s1", "s2"])
        #expect(model.isFiltering)
        #expect(model.countLine(visibleCount: model.visibleSources.count) == "2 of 8 sources")

        model.settings.query = ""
        model.settings.typeFilterID = ""
        #expect(model.visibleSources.map(\.id).sorted() == ["s1", "s2", "s5"])
        #expect(model.countLine(visibleCount: model.visibleSources.count) == "3 of 8 sources")

        model.clearFilters()
        #expect(model.visibleSources.count == 8)
        #expect(model.settings.sort == .az)
        #expect(model.settings.typeFilterID.isEmpty)
        #expect(model.settings.status == nil)
        #expect(model.settings.query.isEmpty)
        #expect(model.countLine(visibleCount: model.visibleSources.count) == "8 sources")
    }

    @Test func restoredTypeMissingFromTypesShowsEveryRow() async {
        let (model, session) = makeModel(
            sources: [
                source(id: "s1", title: "A", typeID: "t1"),
                source(id: "s2", title: "B", typeID: "t1"),
            ],
            types: [photoType()]
        )
        await warmLists(model, session: session)
        model.settings.typeFilterID = "deleted-type"
        #expect(model.visibleSources.count == 2)
        #expect(!model.isFiltering)
        #expect(model.effectiveTypeFilterID.isEmpty)
        #expect(model.settings.typeFilterID == "deleted-type")
    }

    @Test func statusFilterWaitsForCounts() async {
        let store = FakeStore()
        store.graphProgressByGraph["g-s1"] = progress("s1", subjects: 1, filed: 0)
        let (model, session) = makeModel(
            store: store,
            sources: [
                source(id: "s1", title: "A", typeID: "t1", hasArtifact: true),
                source(id: "s2", title: "B", typeID: "t1", hasArtifact: true),
            ],
            types: [photoType()]
        )
        model.settings.status = .empty
        #expect(model.isAwaitingFilterData)
        await warmLists(model, session: session)
        await warmProgress(model, session: session)
        #expect(!model.isAwaitingFilterData)
        #expect(model.visibleSources.map(\.id) == ["s2"])

        let restored = SourcesModel(
            session: makeSession(store: FakeStore()),
            userID: userID,
            store: FakeStore()
        )
        restored.settings.typeFilterID = "t1"
        #expect(restored.isAwaitingFilterData)
        #expect(restored.countLine(visibleCount: restored.visibleSources.count) == L10n.Sources.countLine(total: 0))
    }

    @Test func statusCountsFailureSurfacesAnErrorAndUnfilteredCount() async {
        enum Boom: Error { case boom }
        let store = FakeStore()
        store.listEvidenceGraphProgressError = Boom.boom
        let (model, session) = makeModel(
            store: store,
            sources: [
                source(id: "s1", title: "A", typeID: "t1"),
                source(id: "s2", title: "B", typeID: "t1"),
            ],
            types: [photoType()]
        )
        await warmLists(model, session: session)
        await warmProgress(model, session: session)
        #expect(model.statusCountsError == nil)

        model.settings.status = .promoted
        #expect(model.statusCountsError != nil)
        #expect(model.countLine(visibleCount: model.visibleSources.count) == L10n.Sources.countLine(total: 2))
    }

    @Test func graphListFailureShowsTheStatusError() async {
        enum Boom: Error { case boom }
        let store = FakeStore()
        store.listEvidenceGraphsError = Boom.boom
        let (model, session) = makeModel(
            store: store,
            sources: [source(id: "s1", title: "A", typeID: "t1")],
            types: [photoType()]
        )
        model.warmListQueries()
        await warmProgress(model, session: session)
        if let handle: QueryHandle<[CatalogEvidenceGraph]> = session.queryHandle(
            CatalogQueryKey.evidenceGraphsList(project: session.projectKey)
        ) {
            await waitForQuery(handle)
        }
        model.settings.status = .empty
        #expect(model.statusCountsError != nil)
        #expect(!model.isAwaitingFilterData)
    }

    @Test func graphListLoadingKeepsCountsLoading() async {
        let store = FakeStore()
        let (model, session) = makeModel(
            store: store,
            sources: [source(id: "s1", title: "A", typeID: "t1")],
            types: [photoType()]
        )
        // Only the progress read starts; the graph list is still pending.
        let _: QueryHandle<[String: EvidenceGraphProgress]> = session.query(
            session.evidenceGraphProgressKey
        )
        await warmProgress(model, session: session)
        model.settings.status = .empty
        #expect(model.graphCountsLoading)
        #expect(model.isAwaitingFilterData)
    }

    @Test func outlineWaitsForTheCountsAStatusFilterNeeds() async {
        let store = FakeStore()
        store.listEvidenceGraphProgressHold.isOn = true
        let (model, session) = makeModel(
            store: store, sources: [source(id: "s1", title: "A", typeID: "t1")], types: [photoType()]
        )
        model.settings.status = .empty
        await warmLists(model, session: session)
        await store.listEvidenceGraphProgressHold.untilSuspended(1)
        #expect(model.isAwaitingFilterData)
        #expect(!model.outlineIsSettled)
        store.listEvidenceGraphProgressHold.isOn = false
        store.listEvidenceGraphProgressHold.release()
        await warmProgress(model, session: session)
        #expect(!model.isAwaitingFilterData)
        #expect(model.outlineIsSettled)
    }
}

/// Short names for the sorts the model tests set.
extension SourcesSort {
    static let az = SourcesSort(column: .title, order: .forward)
    static let za = SourcesSort(column: .title, order: .reverse)
    static let dateOldest = SourcesSort(column: .published, order: .forward)
    static let dateNewest = SourcesSort(column: .published, order: .reverse)
    static let updated = SourcesSort(column: .updated, order: .reverse)
}
