import Foundation
import os
import Testing
@testable import Provenencia

/// Counts loader calls. Loaders run off the main actor and can overlap, so the
/// count is guarded by a lock.
private final class Counter: Sendable {
    private let value = OSAllocatedUnfairLock(initialState: 0)

    var count: Int { value.withLock { $0 } }

    func increment() { value.withLock { $0 += 1 } }
}

@Suite(.serialized)
@MainActor
struct WorkspaceSessionTests {
    private let projectDir = "/tmp/workspace-session.provenencia"

    private func makeSession(store: FakeStore = FakeStore()) -> WorkspaceSession {
        WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)
    }

    @Test func evidenceGraphIndexFollowsTheListRevision() {
        let session = makeSession()
        let key = session.evidenceGraphsKey
        #expect(session.evidenceGraphs(sourceID: "s1") == nil)
        #expect(session.evidenceGraphsBySource.isEmpty)

        session.setQueryValue(key, value: [
            evidenceGraph("g1", sourceID: "s1", name: "Default"),
            evidenceGraph("g2", sourceID: "s2", name: "Default"),
            evidenceGraph("g3", sourceID: "s1", name: "Jones"),
        ])
        #expect(session.evidenceGraph(id: "g3")?.name == "Jones")
        #expect(session.evidenceGraphs(sourceID: "s1")?.map(\.id) == ["g1", "g3"])
        #expect(session.evidenceGraphs(sourceID: "s2")?.map(\.id) == ["g2"])
        #expect(session.evidenceGraphs(sourceID: "s9")?.isEmpty == true)
        #expect(session.evidenceGraphsBySource.keys.sorted() == ["s1", "s2"])

        session.setQueryValue(key, value: [
            evidenceGraph("g1", sourceID: "s1", name: "Default"),
        ])
        #expect(session.evidenceGraph(id: "g3") == nil)
        #expect(session.evidenceGraphs(sourceID: "s1")?.map(\.id) == ["g1"])
        #expect(session.evidenceGraphsBySource.keys.sorted() == ["s1"])
    }

    /// T-6 (D-5, AC-1.7): a type is gone only once a settled list lacks it.
    @Test func sourceTypePresenceWaitsForASettledList() {
        let session = makeSession()
        let census = CatalogSourceType(id: "typ-1", key: "census", origin: "user", label: "Census", description: "")
        let book = CatalogSourceType(id: "typ-2", key: "book", origin: "user", label: "Book", description: "")
        if case .unknown = session.sourceTypePresence(id: "typ-1") {} else {
            Issue.record("expected .unknown before the list is warmed")
        }
        session.setQueryValue(session.sourceTypesKey, value: [census, book])
        if case .present(let row) = session.sourceTypePresence(id: "typ-1") {
            #expect(row == census)
        } else {
            Issue.record("expected .present")
        }
        session.setQueryValue(session.sourceTypesKey, value: [book])
        if case .gone = session.sourceTypePresence(id: "typ-1") {} else {
            Issue.record("expected .gone once the settled list lacks the type")
        }
        #expect(session.sourceType(id: "typ-1") == nil)
        #expect(session.sourceType(id: "typ-2") == book)
        session.sourceTypesHandle?.markStale()
        if case .unknown = session.sourceTypePresence(id: "typ-1") {} else {
            Issue.record("expected .unknown while the list is stale")
        }
    }

    @Test func evidenceGraphSnapshotReadsTheThreeKeys() async throws {
        let store = FakeStore()
        store.subjectTypesByProject[projectDir] = [
            CatalogSubjectType(
                id: "t-person", key: "person", origin: "provenencia", label: "Person", description: "",
                refPrefix: "PER", candidateRefPrefix: "CPR"
            ),
        ]
        store.subjectsByGraph["g1"] = [
            CatalogSubject(id: "s1", ref: "CPR-1", sourceID: "src", subjectTypeID: "t-person", label: "Ada", description: ""),
        ]
        for (index, id) in ["s1", "s2"].enumerated() {
            store.subjectPositionsBySubject[id] = CatalogSubjectPosition(subjectID: id, gridX: Int64(index * 3), gridY: 0)
        }
        let session = makeSession(store: store)

        let snapshot = try #require(await session.evidenceGraphSnapshot(graphID: "g1"))
        #expect(snapshot.subjects.map(\.id) == ["s1"])

        // A stale graph key is read again.
        store.subjectsByGraph["g1"] = [
            CatalogSubject(id: "s1", ref: "CPR-1", sourceID: "src", subjectTypeID: "t-person", label: "Ada", description: ""),
            CatalogSubject(id: "s2", ref: "CPR-2", sourceID: "src", subjectTypeID: "t-person", label: "Bea", description: ""),
        ]
        let graphKey = CatalogQueryKey.evidenceGraph(project: session.projectKey, graphId: "g1")
        (session.queryHandle(graphKey) as QueryHandle<EvidenceGraphRows>?)?.markStale()
        let reloaded = try #require(await session.evidenceGraphSnapshot(graphID: "g1"))
        #expect(Set(reloaded.subjects.map(\.id)) == ["s1", "s2"])

        // Rows that cannot be read give nothing.
        struct Boom: Error {}
        let failing = FakeStore()
        failing.listSubjectsError = Boom()
        #expect(await makeSession(store: failing).evidenceGraphSnapshot(graphID: "g1") == nil)
    }

    @Test func evidenceGraphsReadFollowsTheHandle() async {
        struct TestFailure: Error {}
        let session = makeSession()
        func isLoading(_ read: QueryRead<[CatalogEvidenceGraph]>) -> Bool { read.isLoading }

        // No handle yet.
        #expect(isLoading(session.evidenceGraphsRead(sourceID: "s1")))

        // A handle that has not loaded yet.
        let pending: QueryHandle<[CatalogEvidenceGraph]> = session.query(session.evidenceGraphsKey)
        #expect(isLoading(session.evidenceGraphsRead(sourceID: "s1")))
        await waitForQuery(pending)

        // A failure with no value.
        let failedSession = makeSession()
        let failing = failedSession.ensureQuery(failedSession.evidenceGraphsKey) { () async throws -> [CatalogEvidenceGraph] in
            throw TestFailure()
        }
        await waitForQuery(failing)
        guard case .failed(let error) = failedSession.evidenceGraphsRead(sourceID: "s1") else {
            Issue.record("expected .failed")
            return
        }
        #expect(error is TestFailure)

        // Loaded: the Source's graphs, or loading when the list has none for it.
        let loadedSession = makeSession()
        loadedSession.setQueryValue(loadedSession.evidenceGraphsKey, value: [
            evidenceGraph("g1", sourceID: "s1", name: "Default"),
            evidenceGraph("g3", sourceID: "s1", name: "Jones"),
        ])
        guard case .loaded(let graphs) = loadedSession.evidenceGraphsRead(sourceID: "s1") else {
            Issue.record("expected .loaded")
            return
        }
        #expect(graphs.map(\.id) == ["g1", "g3"])
        #expect(isLoading(loadedSession.evidenceGraphsRead(sourceID: "s9")))
    }

    @Test func artifactIDsInNoGraphReadsTheIndex() {
        let session = makeSession()
        #expect(session.artifactIDsInNoGraph(sourceID: "s1", artifactIDs: ["a1"]) == nil)

        session.setQueryValue(session.evidenceGraphsKey, value: [
            evidenceGraph("g1", sourceID: "s1", name: "Default", artifactIDs: ["a1"]),
            evidenceGraph("g3", sourceID: "s1", name: "Jones", artifactIDs: ["a1", "a2"]),
            evidenceGraph("g2", sourceID: "s2", name: "Default", artifactIDs: ["a3"]),
        ])
        #expect(session.artifactIDsInNoGraph(sourceID: "s1", artifactIDs: ["a1", "a2", "a3"]) == ["a3"])
        #expect(session.artifactIDsInNoGraph(sourceID: "s1", artifactIDs: []) == [])
        // A list with no graph for the Source is a list not yet refreshed.
        #expect(session.artifactIDsInNoGraph(sourceID: "s9", artifactIDs: ["a1"]) == nil)
    }

    @Test func artifactIDsInNoGraphIsNilWhileTheListRefetches() async {
        let session = makeSession()
        let rows = [evidenceGraph("g1", sourceID: "s1", name: "Default", artifactIDs: ["a1"])]
        session.setQueryValue(session.evidenceGraphsKey, value: rows)
        #expect(session.artifactIDsInNoGraph(sourceID: "s1", artifactIDs: ["a1", "a2"]) == ["a2"])

        // A refetch of the loaded list: the old value stays readable, but it
        // may lack a link just saved, so nothing is marked until it settles.
        let hold = FakeHold()
        hold.isOn = true
        session.invalidate(session.evidenceGraphsKey)
        let handle = session.ensureQuery(session.evidenceGraphsKey) { () async throws -> [CatalogEvidenceGraph] in
            await hold.wait()
            return [evidenceGraph("g1", sourceID: "s1", name: "Default", artifactIDs: ["a1", "a2"])]
        }
        #expect(handle.isFetching)
        #expect(session.artifactIDsInNoGraph(sourceID: "s1", artifactIDs: ["a1", "a2"]) == nil)

        _ = await waitUntil { hold.count == 1 }
        hold.release()
        await waitForQuery(handle)
        #expect(session.artifactIDsInNoGraph(sourceID: "s1", artifactIDs: ["a1", "a2"]) == [])
    }

    @Test func queryReadAndProgressReads() async {
        struct TestFailure: Error {}
        let handle = QueryHandle<Int>()
        #expect(handle.read.isLoading)
        handle.applySuccess(3)
        guard case .loaded(let value) = handle.read else {
            Issue.record("expected .loaded")
            return
        }
        #expect(value == 3)
        handle.applyFailure(TestFailure(), clearValue: true)
        guard case .failed(let error) = handle.read else {
            Issue.record("expected .failed")
            return
        }
        #expect(error is TestFailure)
        handle.applySuccess(4)
        handle.applyFailure(TestFailure(), clearValue: false)
        guard case .loaded(let kept) = handle.read else {
            Issue.record("expected .loaded with the kept value")
            return
        }
        #expect(kept == 4)

        let store = FakeStore()
        store.graphProgressByGraph["g-1"] = EvidenceGraphProgress(
            graphId: "g-1", subjectCount: 3, observationCount: 5
        )
        store.evidenceGraphsByProject[projectDir] = [evidenceGraph("g-1", sourceID: "s1", name: "Default")]
        let session = makeSession(store: store)
        #expect(session.evidenceGraphCountsLoading)
        #expect(session.evidenceGraphProgress(graphID: "g-1") == nil)
        let progress: QueryHandle<[String: EvidenceGraphProgress]> = session.query(session.evidenceGraphProgressKey)
        let graphs: QueryHandle<[CatalogEvidenceGraph]> = session.query(session.evidenceGraphsKey)
        await waitForQuery(progress)
        await waitForQuery(graphs)
        #expect(session.evidenceGraphCountsLoading == false)
        #expect(session.evidenceGraphProgress(graphID: "g-1")?.subjectCount == 3)
    }

    @Test func queryReadingCarriesARefreshFailure() {
        struct TestFailure: Error {}
        let handle = QueryHandle<Int>()
        /// `reading` and `read` after each step: `reading` is .loading, .failed or .loaded with the
        /// value and whether a refresh failure sits beside it; `read` is .loading, .failed or .loaded.
        func expectReading(_ expected: Expected) {
            switch (handle.reading, expected) {
            case (.loading, .loading), (.failed, .failed): break
            case (.loaded(let value, let refreshFailure), .loaded(let wanted, let failed)):
                #expect(value == wanted)
                #expect((refreshFailure != nil) == failed)
            default: Issue.record("reading is not \(expected)")
            }
            switch (handle.read, expected) {
            case (.loading, .loading), (.failed, .failed): break
            case (.loaded(let value), .loaded(let wanted, _)): #expect(value == wanted)
            default: Issue.record("read is not \(expected)")
            }
        }
        expectReading(.loading)
        #expect(handle.failureRevision == 0)
        #expect(handle.isReading == false)

        handle.applyFailure(TestFailure(), clearValue: true)
        expectReading(.failed)
        guard case .failed(let error) = handle.reading else { return }
        #expect(error is TestFailure)
        #expect(handle.failureRevision == 1)

        // A retry after a first-load failure: `reading` holds the failure, `read` is loading.
        handle.beginLoading(keepingValue: false)
        guard case .failed = handle.reading else {
            Issue.record("expected .failed to hold during the retry")
            return
        }
        #expect(handle.read.isLoading)
        #expect(handle.isReading)

        handle.applySuccess(3)
        expectReading(.loaded(3, failed: false))
        #expect(handle.isReading == false)

        handle.applyFailure(TestFailure(), clearValue: false)
        handle.applyFailure(TestFailure(), clearValue: false)
        expectReading(.loaded(3, failed: true))
        #expect(handle.failureRevision == 3)

        // A retry behind a value keeps the value and the failure beside it.
        handle.beginLoading(keepingValue: true)
        expectReading(.loaded(3, failed: true))
        #expect(handle.isReading)

        handle.applySuccess(4)
        expectReading(.loaded(4, failed: false))

        handle.resetForInvalidation()
        expectReading(.loading)
    }

    private enum Expected {
        case loading
        case failed
        case loaded(Int, failed: Bool)
    }

    private struct ReloadFailure: Error {}

    /// The Sources section of `per-1` read, then a write moves it and its reload fails behind the
    /// rows it kept: the seeded rows, the session, the key and the handle.
    private func sourcesWithAFailedReload() async -> (
        seeded: [CatalogPersonClaimGroup], session: WorkspaceSession, key: CatalogQueryKey,
        handle: QueryHandle<CatalogPersonClaims>
    ) {
        let store = FakeStore()
        let seeded = claims(onGraph: "g1")
        store.seededPersonClaims["per-1"] = seeded
        store.seededConclusionDetails["per-1"] = detail("per-1")
        let session = makeSession(store: store)
        session.apply(location: .personDetail(entityId: "per-1", ref: "PER-1", title: nil).withPageSection(.sources))
        let key = CatalogQueryKey.personClaims(project: session.projectKey, entityId: "per-1")
        let handle: QueryHandle<CatalogPersonClaims> = session.query(key)
        await waitForQuery(handle)
        if case .loaded(_, let clean) = handle.reading {
            #expect(clean == nil)
        } else {
            Issue.record("expected .loaded before the write")
        }

        store.listPersonClaimsError = ReloadFailure()
        session.apply(CatalogWriteEffects(handles: ["per-1"]))
        await session.settleWrites()
        return (seeded, session, key, handle)
    }

    /// P-5 (AC-1.1, AC-1.2): a section's reload that fails after a write keeps its rows and is
    /// read beside them; Try again reads it back to a clean value.
    @Test func aFailedSectionReloadIsReadBesideItsRows() async throws {
        let (seeded, session, key, handle) = await sourcesWithAFailedReload()
        guard case .loaded(let rows, let refreshFailure) = handle.reading else {
            Issue.record("expected the rows to stay")
            return
        }
        #expect(rows.groups == seeded)
        #expect(refreshFailure is ReloadFailure)
        #expect(handle.failureRevision == 1)

        (session.store as? FakeStore)?.listPersonClaimsError = nil
        let _: QueryHandle<CatalogPersonClaims> = session.reread(key)
        await session.settleWrites()
        guard case .loaded(_, let after) = handle.reading else {
            Issue.record("expected .loaded after Try again")
            return
        }
        #expect(after == nil)
    }

    /// AC-1.3, D-2: a second failure of the same read is a new failure, so the notice speaks again.
    @Test func aSecondFailureBumpsTheFailureRevision() async throws {
        let (seeded, session, key, handle) = await sourcesWithAFailedReload()
        #expect(handle.failureRevision == 1)

        let _: QueryHandle<CatalogPersonClaims> = session.reread(key)
        await session.settleWrites()
        #expect(handle.failureRevision == 2)
        guard case .loaded(let rows, let refreshFailure) = handle.reading else {
            Issue.record("expected the rows to stay")
            return
        }
        #expect(rows.groups == seeded)
        #expect(refreshFailure != nil)
    }

    @Test func progressFailureReadsUnavailable() {
        struct TestFailure: Error {}
        let session = makeSession()
        let progress: QueryHandle<[String: EvidenceGraphProgress]> = session.query(session.evidenceGraphProgressKey)
        progress.applyFailure(TestFailure(), clearValue: true)
        let error = session.evidenceGraphCountsError
        #expect(error is TestFailure)
        #expect(
            SourcesGraphCounts(progress: nil, countsLoading: false, countsError: error)
                == .unavailable(message: L10n.Errors.message(for: TestFailure()))
        )

        let kept = EvidenceGraphProgress(graphId: "g-1", subjectCount: 3, observationCount: 5)
        progress.applySuccess(["g-1": kept])
        progress.applyFailure(TestFailure(), clearValue: false)
        #expect(
            SourcesGraphCounts(
                progress: session.evidenceGraphProgress(graphID: "g-1"),
                countsLoading: false,
                countsError: session.evidenceGraphCountsError
            ) == .counts(subjects: 3, observations: 5, filed: 0)
        )
    }

    @Test func loadsAndCachesValue() async {
        let session = makeSession()
        let key = CatalogQueryKey.sourcesList(project: session.projectKey)
        let counter = Counter()

        let handle = session.ensureQuery(key) {
            counter.increment()
            return ["alpha"]
        }
        await waitForQuery(handle)
        #expect(handle.status == .ready)
        #expect(handle.value == ["alpha"])
        #expect(counter.count == 1)

        _ = session.ensureQuery(key) {
            counter.increment()
            return ["beta"]
        }
        await Task.yield()
        #expect(counter.count == 1)
        #expect(handle.value == ["alpha"])
    }

    @Test func dedupesConcurrentLoads() async {
        let session = makeSession()
        let key = CatalogQueryKey.metadataFieldsList(project: session.projectKey)
        let counter = Counter()
        let gate = Gate()

        let loads = (0..<2).map { _ in
            Task {
                _ = session.ensureQuery(key) {
                    counter.increment()
                    await gate.waitForOpen()
                    return ["shared"]
                }
            }
        }
        gate.open()
        for load in loads { await load.value }

        let handle: QueryHandle<[String]> = session.queryHandle(key)!
        await waitForQuery(handle)
        #expect(counter.count == 1)
        #expect(handle.status == .ready)
        #expect(handle.value == ["shared"])
    }

    @Test func invalidateTriggersReload() async {
        let session = makeSession()
        let key = CatalogQueryKey.sourceTypesList(project: session.projectKey)
        let counter = Counter()

        let handle = session.ensureQuery(key) {
            counter.increment()
            return ["first"]
        }
        await waitForQuery(handle)
        #expect(counter.count == 1)

        session.invalidate(key)
        _ = session.ensureQuery(key) {
            counter.increment()
            return ["second"]
        }
        await waitForQuery(handle)
        #expect(counter.count == 2)
        #expect(handle.value == ["second"])
    }

    @Test func invalidateAllMatching() async {
        let session = makeSession()
        let otherProject = ProjectKey(projectDir: "/tmp/other.provenencia")
        let keyA = CatalogQueryKey.sourcesList(project: session.projectKey)
        let keyB = CatalogQueryKey.sourceTypesList(project: session.projectKey)
        let keyOther = CatalogQueryKey.sourcesList(project: otherProject)
        let counter = Counter()

        let handleA = session.ensureQuery(keyA) {
            counter.increment()
            return ["a"]
        }
        let handleB = session.ensureQuery(keyB) {
            counter.increment()
            return ["b"]
        }
        let handleOther = session.ensureQuery(keyOther) {
            counter.increment()
            return ["other"]
        }
        await waitForQuery(handleA)
        await waitForQuery(handleB)
        await waitForQuery(handleOther)
        #expect(counter.count == 3)

        session.invalidateAll { $0.project == session.projectKey }

        _ = session.ensureQuery(keyA) {
            counter.increment()
            return ["a2"]
        }
        _ = session.ensureQuery(keyB) {
            counter.increment()
            return ["b2"]
        }
        _ = session.ensureQuery(keyOther) {
            counter.increment()
            return ["other2"]
        }
        await waitForQuery(handleA)
        await waitForQuery(handleB)
        await waitForQuery(handleOther)
        #expect(counter.count == 5)
        #expect(handleOther.value == ["other"])
    }

    @Test func staleWhileRevalidate() async {
        let session = makeSession()
        let key = CatalogQueryKey.typeSuggestions(project: session.projectKey, typeId: "t1")
        let counter = Counter()
        let gate = Gate()

        let handle = session.ensureQuery(key) {
            counter.increment()
            return ["first"]
        }
        await waitForQuery(handle)

        session.invalidate(key)
        _ = session.ensureQuery(key) {
            counter.increment()
            await gate.waitForOpen()
            return ["second"]
        }

        #expect(handle.value == ["first"])
        #expect(handle.isFetching)
        gate.open()
        await waitForQuery(handle)
        #expect(handle.value == ["second"])
        #expect(handle.isFetching == false)
        #expect(counter.count == 2)
    }

    @Test func propagatesLoaderError() async {
        let session = makeSession()
        let key = CatalogQueryKey.sourceWorkspace(project: session.projectKey, sourceId: "missing")
        struct TestFailure: Error {}

        let handle = session.ensureQuery(key) {
            throw TestFailure()
        }
        await waitForQuery(handle)
        #expect(handle.status == .error)
        #expect(handle.error is TestFailure)
        #expect(handle.value == nil)
    }

    private func seedStore(_ store: FakeStore) {
        store.sourcesByProject[projectDir] = [
            CatalogSource(id: "s1", ref: "SRC-1", sourceTypeID: "t1", title: "Alpha", description: ""),
        ]
        store.sourceTypesByProject[projectDir] = [
            CatalogSourceType(id: "t1", key: "book", origin: "user", label: "Book", description: ""),
        ]
        store.fieldsByProject[projectDir] = [
            CatalogMetadataField(
                id: "f1", key: "author", origin: "user", label: "Author", dataType: "text", description: ""
            ),
        ]
        store.suggestionsByType["t1"] = [
            CatalogTypeSuggestion(
                field: CatalogMetadataField(
                    id: "f1", key: "author", origin: "user", label: "Author", dataType: "text", description: ""
                ),
                sortOrder: 0
            ),
        ]
    }

    @Test func applyLocationSourcesRoot() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let project = session.projectKey

        session.apply(location: .sectionRoot(.sources))

        let sourcesHandle: QueryHandle<[CatalogSource]>? = session.queryHandle(
            CatalogQueryKey.sourcesList(project: project)
        )
        let typesHandle: QueryHandle<[CatalogSourceType]>? = session.queryHandle(
            CatalogQueryKey.sourceTypesList(project: project)
        )
        let progressHandle: QueryHandle<[String: EvidenceGraphProgress]>? = session.queryHandle(
            CatalogQueryKey.evidenceGraphProgress(project: project)
        )
        let fieldsHandle: QueryHandle<[CatalogMetadataField]>? = session.queryHandle(
            CatalogQueryKey.metadataFieldsList(project: project)
        )
        #expect(sourcesHandle != nil)
        #expect(typesHandle != nil)
        #expect(progressHandle != nil)
        #expect(fieldsHandle == nil)

        await waitForQuery(sourcesHandle!)
        await waitForQuery(typesHandle!)
        await waitForQuery(progressHandle!)
        #expect(sourcesHandle?.value?.first?.title == "Alpha")
        #expect(typesHandle?.value?.first?.label == "Book")
    }

    @Test func applyLocationSourceDetail() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let project = session.projectKey

        session.apply(location: WorkspaceLocation(section: .sources, sourceId: "s1", title: "Alpha"))

        let listHandle: QueryHandle<[CatalogSource]>? = session.queryHandle(
            CatalogQueryKey.sourcesList(project: project)
        )
        #expect(listHandle == nil)
        let workspaceHandle: QueryHandle<CatalogSourceWorkspace>? = session.queryHandle(
            CatalogQueryKey.sourceWorkspace(project: project, sourceId: "s1")
        )
        #expect(workspaceHandle != nil)
        await waitForQuery(workspaceHandle!)
        #expect(workspaceHandle?.value?.source.id == "s1")
    }

    @Test func applyLocationSourceTypesWithSelection() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let project = session.projectKey

        session.apply(location: WorkspaceLocation(section: .sourceTypes, typeId: "t1", title: "Book"))

        let typesHandle: QueryHandle<[CatalogSourceType]>? = session.queryHandle(
            CatalogQueryKey.sourceTypesList(project: project)
        )
        let fieldsHandle: QueryHandle<[CatalogMetadataField]>? = session.queryHandle(
            CatalogQueryKey.metadataFieldsList(project: project)
        )
        let suggestionsHandle: QueryHandle<[CatalogTypeSuggestion]>? = session.queryHandle(
            CatalogQueryKey.typeSuggestions(project: project, typeId: "t1")
        )
        #expect(typesHandle != nil)
        #expect(fieldsHandle != nil)
        #expect(suggestionsHandle != nil)

        await waitForQuery(typesHandle!)
        await waitForQuery(fieldsHandle!)
        await waitForQuery(suggestionsHandle!)
        #expect(suggestionsHandle?.value?.count == 1)
    }

    @Test func applyLocationIsNonBlocking() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let project = session.projectKey

        session.apply(location: .sectionRoot(.sources))
        let handle: QueryHandle<[CatalogSource]>? = session.queryHandle(
            CatalogQueryKey.sourcesList(project: project)
        )
        #expect(handle?.status == .loading)

        await waitForQuery(handle!)
        #expect(handle?.status == .ready)
    }

    @Test func applyLocationCacheHit() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let location = WorkspaceLocation(section: .sources, sourceId: "s1")

        session.apply(location: location)
        let workspaceHandle: QueryHandle<CatalogSourceWorkspace>? = session.queryHandle(
            CatalogQueryKey.sourceWorkspace(project: session.projectKey, sourceId: "s1")
        )
        await waitForQuery(workspaceHandle!)

        store.sourcesByProject[projectDir] = [
            CatalogSource(id: "s2", ref: "SRC-2", sourceTypeID: "", title: "Beta", description: ""),
        ]

        session.apply(location: location)
        await Task.yield()
        #expect(workspaceHandle?.value?.source.id == "s1")
    }

    @Test func loadsSourcesListViaFakeStore() async throws {
        let store = FakeStore()
        store.sourcesByProject[projectDir] = [
            CatalogSource(id: "1", ref: "SRC-1", sourceTypeID: "", title: "A", description: ""),
        ]
        let session = makeSession(store: store)
        let key = CatalogQueryKey.sourcesList(project: session.projectKey)

        let handle = session.ensureQuery(key) {
            try await store.listSources(projectDir: projectDir)
        }
        await waitForQuery(handle)
        #expect(handle.status == .ready)
        #expect(handle.value?.count == 1)
        #expect(handle.value?.first?.ref == "SRC-1")
        #expect(store.heldCatalogProjectDir == projectDir)
    }

    @Test func applyCitationMutationReloadsGraphWithoutASecondQuery() async {
        let store = FakeStore()
        seedStore(store)
        store.subjectTypesByProject[projectDir] = [
            CatalogSubjectType(
                id: "type-person",
                key: "person",
                origin: "provenencia",
                label: "Person",
                description: "",
                refPrefix: "PER",
                candidateRefPrefix: "CPR"
            ),
        ]
        store.subjectsByGraph["g-1"] = [
            CatalogSubject(
                id: "sub-1",
                ref: "CPR-1",
                sourceID: "s1",
                subjectTypeID: "type-person",
                label: "Alice",
                description: ""
            ),
        ]
        store.subjectPositionsBySubject["sub-1"] = CatalogSubjectPosition(
            subjectID: "sub-1",
            gridX: 0,
            gridY: 0
        )
        let session = makeSession(store: store)
        let key = CatalogQueryKey.evidenceGraph(project: session.projectKey, graphId: "g-1")
        session.apply(location: WorkspaceLocation(
            section: .sources, sourceId: "s1", graphId: "g-1", sourceSurface: .graph
        ))
        let handle: QueryHandle<EvidenceGraphRows> = session.query(key)
        await waitForQuery(handle)
        #expect(handle.value?.observations.isEmpty == true)

        store.observationsByGraph["g-1"] = [
            CatalogObservation(
                id: "obs-1",
                ref: "OBS-1",
                citationID: "cit-1",
                subjectID: "sub-1",
                propertyID: "prop-name",
                polarity: "positive",
                valueText: "Alice",
                valueInteger: nil,
                valueDateID: "",
                valueNameID: "",
                valueSubjectID: "",
                valueTermID: "",
                propertyKey: "name",
                propertyLabel: "Name",
                propertyValueType: "name"
            ),
        ]
        session.apply(CatalogWriteEffects(evidenceGraphs: ["g-1"]))
        await waitForQuery(handle)
        #expect(handle.value?.observations.count == 1)
    }

    /// A Promote's effects reach a Persons list that isn't on screen as one read of the promoted
    /// handle, merged in: the list holds the new row, current, with no whole reload (AC-1.4, AC-1.5).
    @Test func applyPromoteMergesThePromotedPerson() async throws {
        let store = FakeStore()
        seedStore(store)
        store.subjectTypesByProject[projectDir] = [
            CatalogSubjectType(
                id: "type-person", key: "person", origin: "provenencia", label: "Person",
                description: "", refPrefix: "PER", candidateRefPrefix: "CPR"
            ),
        ]
        store.subjectsByGraph["g-1"] = [
            CatalogSubject(id: "sub-1", ref: "CPR-1", sourceID: "s1", subjectTypeID: "type-person", label: "Alice", description: ""),
        ]
        let session = makeSession(store: store)
        let handle: QueryHandle<CatalogListRows<CatalogPersonSummary>> = session.query(.personsList(project: session.projectKey))
        await waitForQuery(handle)
        #expect(handle.value?.isEmpty == true)

        let promoted = store.seedPromotion(projectDir: projectDir, subjectID: "sub-1")
        session.apply(CatalogWriteEffects(handles: [promoted.entity.id], evidenceGraphs: ["g-1"]))
        await session.settleWrites()
        #expect(handle.value?.map(\.entity.ref) == [promoted.entity.ref])
        #expect(!handle.isStale)
        #expect(store.listPersonSummariesEntityIDs == [nil, [promoted.entity.id]])
    }

    /// The open section's reads stay visible, so a write revalidates them instead of marking
    /// them stale while they are on screen; the first section, stored as nil, reads nothing yet.
    /// While the first section (Vitals) reads nothing, the stored-nil case passes whether the
    /// place resolves `openPageSection` or the raw `pageSection`; the first PR that gives the
    /// first section a read must add that case's own key to this test's expectation, which then
    /// fails against the raw `pageSection`.
    @Test func applyPersonPageKeepsTheOpenSectionsReadsVisible() {
        let session = makeSession(store: FakeStore())
        let detail = CatalogQueryKey.conclusionDetail(project: session.projectKey, entityId: "per-1")
        let person = WorkspaceLocation.personDetail(entityId: "per-1", ref: "PER-1", title: nil)
        session.apply(location: person.withPageSection(.family))
        #expect(session.visibleKeys.contains(.personFamily(project: session.projectKey, entityId: "per-1")))
        session.apply(location: person)
        #expect(session.visibleKeys == [detail])
    }

    /// A trigger marks Conclusion detail pages that aren't on screen stale,
    /// revalidates the one that is, and merges the touched rows into the Persons list (also off
    /// screen), which stays current.
    @Test func applyTriggerStalesHiddenDetailPagesAndRevalidatesTheVisibleOne() async throws {
        let store = FakeStore()
        seedStore(store)
        store.subjectTypesByProject[projectDir] = [
            CatalogSubjectType(
                id: "type-person", key: "person", origin: "provenencia", label: "Person",
                description: "", refPrefix: "PER", candidateRefPrefix: "CPR"
            ),
        ]
        store.subjectsByGraph["g-1"] = [
            CatalogSubject(id: "sub-1", ref: "CPR-1", sourceID: "s1", subjectTypeID: "type-person", label: "", description: ""),
            CatalogSubject(id: "sub-2", ref: "CPR-2", sourceID: "s1", subjectTypeID: "type-person", label: "", description: ""),
        ]
        let first = store.seedPromotion(projectDir: projectDir, subjectID: "sub-1")
        let second = store.seedPromotion(projectDir: projectDir, subjectID: "sub-2")
        let session = makeSession(store: store)
        let firstKey = CatalogQueryKey.conclusionDetail(project: session.projectKey, entityId: first.entity.id)
        let secondKey = CatalogQueryKey.conclusionDetail(project: session.projectKey, entityId: second.entity.id)
        let list: QueryHandle<CatalogListRows<CatalogPersonSummary>> = session.query(.personsList(project: session.projectKey))
        await waitForQuery(list)

        session.apply(location: .personDetail(entityId: first.entity.id, ref: first.entity.ref, title: nil))
        let firstHandle: QueryHandle<CatalogConclusionDetail> = try #require(session.queryHandle(firstKey))
        await waitForQuery(firstHandle)
        session.apply(location: .personDetail(entityId: second.entity.id, ref: second.entity.ref, title: nil))
        #expect(session.visibleKeys == [secondKey])
        let secondHandle: QueryHandle<CatalogConclusionDetail> = try #require(session.queryHandle(secondKey))
        await waitForQuery(secondHandle)
        #expect(secondHandle.value?.fields.first?.state == .empty)

        store.observationsByGraph["g-1"] = [
            CatalogObservation(
                id: "o1", ref: "OBS-1", citationID: "c1", subjectID: "sub-2", propertyID: "p-name",
                polarity: "positive", valueText: "Jim Robins", valueInteger: nil, valueDateID: "",
                valueNameID: "n-1", nameForm: "Jim Robins",
                nameParts: [
                    CatalogNameValuePart(value: "Jim", type: "given"),
                    CatalogNameValuePart(value: "Robins", type: "surname"),
                ],
                valueSubjectID: "", valueTermID: "",
                propertyKey: "name", propertyLabel: "Name", propertyValueType: "name"
            ),
        ]
        session.apply(CatalogWriteEffects(handles: [first.entity.id, second.entity.id], evidenceGraphs: ["g-1"]))

        // Off screen: stale with its value kept, so it reloads only when next visited.
        let stale: QueryHandle<CatalogConclusionDetail>? = session.queryHandle(firstKey)
        #expect(stale?.value != nil && stale?.isStale == true && stale?.isFetching == false)
        // On screen: revalidated in place.
        await waitForQuery(secondHandle)
        #expect(secondHandle.value?.fields.first?.state == .single)
        // The list is off screen: it merged the touched rows, so it is current and not stale.
        await session.settleWrites()
        #expect(!list.isStale)
        #expect(list.value?.first?.name?.form == "Jim Robins")
        let _: QueryHandle<CatalogListRows<CatalogPersonSummary>> = session.query(.personsList(project: session.projectKey))
        #expect(!list.isFetching)

        // Leaving for the list hides the second page too.
        session.apply(location: .sectionRoot(.persons))
        session.apply(CatalogWriteEffects(handles: [first.entity.id, second.entity.id], evidenceGraphs: ["g-1"]))
        let hidden: QueryHandle<CatalogConclusionDetail>? = session.queryHandle(secondKey)
        #expect(hidden?.isStale == true && hidden?.isFetching == false)
        await waitForQuery(list)
        #expect(list.status == .ready)

        // Revisiting reloads behind the old value.
        session.apply(location: .personDetail(entityId: first.entity.id, ref: first.entity.ref, title: nil))
        let reloaded: QueryHandle<CatalogConclusionDetail> = try #require(session.queryHandle(firstKey))
        await waitForQuery(reloaded)
        #expect(reloaded.value?.entity == first.entity)
    }

    private func personSummary(_ id: String, revision: Int64, at: String = "") -> CatalogPersonSummary {
        CatalogPersonSummary(
            entity: CatalogCanonicalEntity(id: id, ref: "PER-\(id)", subjectTypeID: "t", label: ""),
            name: nil,
            nameValueCount: 0,
            updated: CatalogActivity(revision: revision, at: at)
        )
    }

    /// A Person row whose list key is `position` (Go's order, which the fake's reads keep).
    private func keyedPerson(_ id: String, _ position: UInt8) -> CatalogPersonSummary {
        var row = personSummary(id, revision: 1)
        row.listKey = CatalogListKey(last: false, primary: Data([position]), ref: id)
        return row
    }

    private func eventSummary(_ id: String) -> CatalogEventSummary {
        CatalogEventSummary(
            entity: CatalogCanonicalEntity(id: id, ref: "EVT-\(id)", subjectTypeID: "t", label: ""),
            title: CatalogEventTitle(rule: .ref, ref: "EVT-\(id)")
        )
    }

    private func placeSummary(_ id: String) -> CatalogPlaceSummary {
        CatalogPlaceSummary(
            entity: CatalogCanonicalEntity(id: id, ref: "PLC-\(id)", subjectTypeID: "t", label: "")
        )
    }

    /// A write that reports its activity moves the cached rows it names, in
    /// place: no list load starts, an older or empty activity moves nothing, and
    /// a load already in flight is restarted so its old answer cannot win.
    @Test func applyEffectsPatchesLastUpdatedInPlace() async throws {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let people = CatalogQueryKey.personsList(project: session.projectKey)
        let sources = CatalogQueryKey.sourcesList(project: session.projectKey)
        let at = "2026-10-15T16:00:00Z"
        session.setQueryValue(people, value: CatalogListRows([personSummary("e1", revision: 10), personSummary("e2", revision: 9)]))
        session.setQueryValue(sources, value: [
            CatalogSource(id: "s1", ref: "SRC-1", sourceTypeID: "t1", title: "Alpha", description: "",
                          updated: CatalogActivity(revision: 5)),
        ])
        let list: QueryHandle<CatalogListRows<CatalogPersonSummary>> = try #require(session.queryHandle(people))
        let sourceList: QueryHandle<[CatalogSource]> = try #require(session.queryHandle(sources))

        // AC-2.5: only e1 moves, and nothing loads.
        session.apply(CatalogWriteEffects(handleScopes: ["e1"], activity: CatalogActivity(revision: 12, at: at)))
        #expect(list.value?.map(\.updated) == [CatalogActivity(revision: 12, at: at), CatalogActivity(revision: 9)])
        #expect(!list.isFetching)
        // An older revision, and revision 0, change nothing.
        session.apply(CatalogWriteEffects(handleScopes: ["e1"], activity: CatalogActivity(revision: 11, at: "x")))
        session.apply(CatalogWriteEffects(handleScopes: ["e1", "e2"], activity: CatalogActivity()))
        #expect(list.value?.map(\.updated) == [CatalogActivity(revision: 12, at: at), CatalogActivity(revision: 9)])

        // AC-2.5b: a Source moves and the Sources list is neither loaded nor marked stale.
        session.apply(CatalogWriteEffects(sourceScopes: ["s1"], activity: CatalogActivity(revision: 12, at: at)))
        #expect(sourceList.value?.first?.updated == CatalogActivity(revision: 12, at: at))
        #expect(!sourceList.isFetching)
        let _: QueryHandle<[CatalogSource]> = session.query(sources)
        await Task.yield()
        #expect(!sourceList.isFetching)
        #expect(sourceList.value?.first?.updated.revision == 12)

        // AC-2.5c: a load in flight is cancelled and restarted.
        session.invalidate(people)
        let oldRows = CatalogListRows([personSummary("e1", revision: 10)])
        let slow = session.ensureQuery(people) {
            try await Task.sleep(nanoseconds: 200_000_000)
            return oldRows
        }
        #expect(slow.isFetching)
        session.apply(CatalogWriteEffects(handleScopes: ["e2"], activity: CatalogActivity(revision: 20, at: at)))
        #expect(list.value?.last?.updated == CatalogActivity(revision: 20, at: at))
        #expect(list.isFetching)
        try await Task.sleep(nanoseconds: 300_000_000)
        await waitForQuery(list)
        // The restarted load answered from the store (empty), not the slow loader's old rows.
        #expect(list.value?.isEmpty == true)
    }

    /// A write that deletes the shown entity applies with every key hidden and then leaves the
    /// page, so the next place's list loads once and the entity's own keys are dropped.
    @Test func applyLeavingPageLoadsTheNextListOnce() async throws {
        let store = FakeStore()
        let session = makeSession(store: store)
        let people = CatalogQueryKey.personsList(project: session.projectKey)
        let detail = CatalogQueryKey.conclusionDetail(project: session.projectKey, entityId: "h-maria")
        session.apply(location: .personDetail(entityId: "h-maria", ref: "PER-8JD2L", title: "Maria"))
        session.setQueryValue(people, value: CatalogListRows([personSummary("h-maria", revision: 10)]))
        session.invalidate(people)
        let warmed: QueryHandle<CatalogConclusionDetail>? = session.queryHandle(detail)
        #expect(warmed != nil)

        var left = false
        session.apply(
            CatalogWriteEffects(
                handles: ["h-maria"], deleted: [CatalogWriteEffectsDeleted(entity: .handle, ids: ["h-maria"])]
            ),
            leavingPage: {
                left = true
                session.apply(location: .sectionRoot(.persons))
            }
        )
        #expect(left)
        let list: QueryHandle<CatalogListRows<CatalogPersonSummary>> = try #require(session.queryHandle(people))
        await waitForQuery(list)
        #expect(store.listPersonSummariesEntityIDs == [nil])
        let evicted: QueryHandle<CatalogConclusionDetail>? = session.queryHandle(detail)
        #expect(evicted == nil)
    }

    /// A write that names a handle re-reads just that row in each loaded list, on screen or not
    /// (AC-1.3, AC-1.5): the lists merge it in, are not marked stale, and a `query` starts no load.
    @Test func hiddenListsMergeTouchedRows() async throws {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let project = session.projectKey
        let people = CatalogQueryKey.personsList(project: project)
        let events = CatalogQueryKey.eventsList(project: project)
        let places = CatalogQueryKey.placesList(project: project)
        session.setQueryValue(people, value: CatalogListRows([personSummary("e1", revision: 1)]))
        session.setQueryValue(events, value: CatalogListRows([eventSummary("e1")]))
        session.setQueryValue(places, value: CatalogListRows([placeSummary("e1")]))
        let peopleHandle: QueryHandle<CatalogListRows<CatalogPersonSummary>> = try #require(session.queryHandle(people))
        let eventsHandle: QueryHandle<CatalogListRows<CatalogEventSummary>> = try #require(session.queryHandle(events))
        let placesHandle: QueryHandle<CatalogListRows<CatalogPlaceSummary>> = try #require(session.queryHandle(places))

        // The store has no `e1` row, so each list drops it.
        session.apply(CatalogWriteEffects(handles: ["e1"]))
        await session.settleWrites()
        #expect(store.listPersonSummariesEntityIDs == [["e1"]])
        #expect(store.listEventSummariesEntityIDs == [["e1"]])
        #expect(store.listPlaceSummariesEntityIDs == [["e1"]])
        #expect(peopleHandle.value?.isEmpty == true && eventsHandle.value?.isEmpty == true && placesHandle.value?.isEmpty == true)
        #expect(!peopleHandle.isStale && !eventsHandle.isStale && !placesHandle.isStale)
        let _: QueryHandle<CatalogListRows<CatalogPersonSummary>> = session.query(people)
        let _: QueryHandle<CatalogListRows<CatalogEventSummary>> = session.query(events)
        let _: QueryHandle<CatalogListRows<CatalogPlaceSummary>> = session.query(places)
        #expect(!peopleHandle.isFetching && !eventsHandle.isFetching && !placesHandle.isFetching)
        #expect(store.listPersonSummariesEntityIDs == [["e1"]])
    }

    /// A list key puts a re-read row where Go says (AC-1.1, AC-1.2): the visible list asks the
    /// store once, for the write's touched ids, and the moved row lands after its new neighbour.
    @Test func visibleListsReReadOnlyTouchedRows() async throws {
        let store = FakeStore()
        seedStore(store)
        store.seededPersonSummaries = [keyedPerson("p1", 1), keyedPerson("p2", 2), keyedPerson("p3", 3)]
        let session = makeSession(store: store)
        let people = CatalogQueryKey.personsList(project: session.projectKey)
        session.apply(location: .sectionRoot(.persons))
        let handle: QueryHandle<CatalogListRows<CatalogPersonSummary>> = try #require(session.queryHandle(people))
        await waitForQuery(handle)
        #expect(handle.value?.map(\.id) == ["p1", "p2", "p3"])

        store.seededPersonSummaries = [keyedPerson("p1", 1), keyedPerson("p2", 4), keyedPerson("p3", 3)]
        session.apply(CatalogWriteEffects(handles: ["p2"], summaryHandles: ["e9"]))
        #expect(handle.isFetching)
        await session.settleWrites()
        #expect(store.listPersonSummariesEntityIDs == [nil, ["p2", "e9"]])
        #expect(handle.value?.map(\.id) == ["p1", "p3", "p2"])
        #expect(!handle.isFetching && !handle.isStale)
    }

    /// AC-1.6: a failed re-read goes through the hidden policy, as a failed `.merged` does.
    @Test func listReReadFailureFollowsTheHiddenPolicy() async throws {
        struct Boom: Error {}
        // On screen: the list reloads whole, and that read fails too.
        let store = FakeStore()
        seedStore(store)
        store.seededPersonSummaries = [keyedPerson("p1", 1), keyedPerson("p2", 2)]
        let session = makeSession(store: store)
        let people = CatalogQueryKey.personsList(project: session.projectKey)
        session.apply(location: .sectionRoot(.persons))
        let handle: QueryHandle<CatalogListRows<CatalogPersonSummary>> = try #require(session.queryHandle(people))
        await waitForQuery(handle)
        store.listPersonSummariesError = Boom()
        session.apply(CatalogWriteEffects(handles: ["p2"]))
        await session.settleWrites()
        #expect(store.listPersonSummariesEntityIDs == [nil, ["p2"], nil])
        #expect(handle.status == .error)
        #expect(handle.value?.map(\.id) == ["p1", "p2"])

        // Off screen: the list is marked stale and reloads on its next showing.
        let hiddenStore = FakeStore()
        seedStore(hiddenStore)
        hiddenStore.listPersonSummariesError = Boom()
        let hiddenSession = makeSession(store: hiddenStore)
        let hiddenKey = CatalogQueryKey.personsList(project: hiddenSession.projectKey)
        hiddenSession.setQueryValue(hiddenKey, value: CatalogListRows([keyedPerson("p1", 1), keyedPerson("p2", 2)]))
        let hidden: QueryHandle<CatalogListRows<CatalogPersonSummary>> = try #require(hiddenSession.queryHandle(hiddenKey))
        hiddenSession.apply(CatalogWriteEffects(handles: ["p2"]))
        await hiddenSession.settleWrites()
        #expect(hiddenStore.listPersonSummariesEntityIDs == [["p2"]])
        #expect(hidden.isStale)
        #expect(hidden.value?.map(\.id) == ["p1", "p2"])
    }

    /// AC-1.7: a label edit reloads a visible list whole and marks a hidden one stale; neither
    /// makes a partial read.
    @Test func labelEditReloadsOrStalesListsWithNoPartialRead() async throws {
        let store = FakeStore()
        seedStore(store)
        store.seededPersonSummaries = [keyedPerson("p1", 1), keyedPerson("p2", 2)]
        let session = makeSession(store: store)
        let people = CatalogQueryKey.personsList(project: session.projectKey)
        let events = CatalogQueryKey.eventsList(project: session.projectKey)
        session.apply(location: .sectionRoot(.persons))
        let handle: QueryHandle<CatalogListRows<CatalogPersonSummary>> = try #require(session.queryHandle(people))
        await waitForQuery(handle)
        session.setQueryValue(events, value: CatalogListRows([eventSummary("e1")]))
        let hidden: QueryHandle<CatalogListRows<CatalogEventSummary>> = try #require(session.queryHandle(events))

        session.apply(CatalogWriteEffects(handles: ["p2"], lists: [.propertyVocabulary]))
        await session.settleWrites()
        #expect(store.listPersonSummariesEntityIDs == [nil, nil])
        #expect(store.listEventSummariesEntityIDs.isEmpty)
        #expect(hidden.isStale)
    }

    /// A Source-page write reports its effects: the Sources row is patched in
    /// place, the three conclusion lists are neither reloaded nor re-read unless
    /// the write reports handles (then each merges just those rows), and the
    /// page's own workspace follows the mutation.
    @Test func sourceWriteEffectsPatchSourcesAndMergeOnlyTouchedListRows() async throws {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let project = session.projectKey
        let sources = CatalogQueryKey.sourcesList(project: project)
        let people = CatalogQueryKey.personsList(project: project)
        let events = CatalogQueryKey.eventsList(project: project)
        let places = CatalogQueryKey.placesList(project: project)
        let workspaceKey = CatalogQueryKey.sourceWorkspace(project: project, sourceId: "s1")
        session.apply(location: WorkspaceLocation(section: .sources, sourceId: "s1", title: "Alpha"))
        let workspace: QueryHandle<CatalogSourceWorkspace> = try #require(session.queryHandle(workspaceKey))
        await waitForQuery(workspace)
        session.setQueryValue(sources, value: [
            CatalogSource(id: "s1", ref: "SRC-1", sourceTypeID: "t1", title: "Alpha", description: ""),
        ])
        session.setQueryValue(people, value: CatalogListRows([personSummary("e1", revision: 1)]))
        session.setQueryValue(events, value: CatalogListRows([eventSummary("e1")]))
        session.setQueryValue(places, value: CatalogListRows([placeSummary("e1")]))
        let sourcesHandle: QueryHandle<[CatalogSource]> = try #require(session.queryHandle(sources))
        let peopleHandle: QueryHandle<CatalogListRows<CatalogPersonSummary>> = try #require(session.queryHandle(people))
        let eventsHandle: QueryHandle<CatalogListRows<CatalogEventSummary>> = try #require(session.queryHandle(events))
        let placesHandle: QueryHandle<CatalogListRows<CatalogPlaceSummary>> = try #require(session.queryHandle(places))
        func listsAreQuiet() -> Bool {
            !sourcesHandle.isFetching && !peopleHandle.isFetching && !eventsHandle.isFetching
                && !placesHandle.isFetching
        }

        // AC-2.11: a note. Sources row patched; the conclusion lists untouched
        // and not stale; the page's workspace invalidated once.
        let first = CatalogActivity(revision: 12, at: "2026-10-15T16:00:00Z")
        session.apply(CatalogWriteEffects(sourceScopes: ["s1"], activity: first), .mutatedSourceWorkspace(sourceId: "s1"))
        #expect(sourcesHandle.value?.first?.updated == first)
        #expect(listsAreQuiet())
        let _: QueryHandle<CatalogListRows<CatalogPersonSummary>> = session.query(people)
        let _: QueryHandle<CatalogListRows<CatalogEventSummary>> = session.query(events)
        let _: QueryHandle<CatalogListRows<CatalogPlaceSummary>> = session.query(places)
        let _: QueryHandle<[CatalogSource]> = session.query(sources)
        #expect(listsAreQuiet())
        #expect(workspace.isFetching)
        await waitForQuery(workspace)

        // AC-2.12: a credibility change reports the handle. Each hidden list re-reads just that row
        // (the fake has none, so it is dropped) and stays current; the Sources row still patches.
        let second = CatalogActivity(revision: 13, at: "2026-10-15T16:05:00Z")
        session.apply(
            CatalogWriteEffects(handles: ["e1"], sourceScopes: ["s1"], activity: second),
            .mutatedSourceWorkspace(sourceId: "s1")
        )
        #expect(sourcesHandle.value?.first?.updated == second)
        await session.settleWrites()
        #expect(listsAreQuiet())
        #expect(store.listPersonSummariesEntityIDs.last == .some(["e1"]))
        #expect(store.listEventSummariesEntityIDs.last == .some(["e1"]))
        #expect(store.listPlaceSummariesEntityIDs.last == .some(["e1"]))
        #expect(!peopleHandle.isStale && !eventsHandle.isStale && !placesHandle.isStale)
        let _: QueryHandle<CatalogListRows<CatalogPersonSummary>> = session.query(people)
        #expect(!peopleHandle.isFetching)
        let _: QueryHandle<[CatalogSource]> = session.query(sources)
        #expect(!sourcesHandle.isFetching)

        // AC-2.12, on screen: a Conclusion page showing the reported handle reloads.
        session.apply(location: .personDetail(entityId: "e1", ref: "PER-e1", title: nil))
        let detailKey = CatalogQueryKey.conclusionDetail(project: project, entityId: "e1")
        let detail: QueryHandle<CatalogConclusionDetail> = try #require(session.queryHandle(detailKey))
        await waitForQuery(detail)
        session.apply(
            CatalogWriteEffects(handles: ["e1"], sourceScopes: ["s1"], activity: CatalogActivity(revision: 14, at: "2026-10-15T16:10:00Z")),
            .mutatedSourceWorkspace(sourceId: "s1")
        )
        // The page has no value in the fake, so a reload shows as loading.
        #expect(detail.status == .loading)
        await waitForQuery(detail)
    }

    /// A note moves the Source's last activity and nothing it reads as
    /// evidence: the Properties workspace, the Source graph, and the citations
    /// stay warm and current (D-25, D-26).
    @Test func sourceNoteLeavesEvidenceReadsAlone() async throws {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let project = session.projectKey
        let sources = CatalogQueryKey.sourcesList(project: project)
        let propertiesKey = CatalogQueryKey.propertiesWorkspace(project: project)
        let graphKey = CatalogQueryKey.evidenceGraph(project: project, graphId: "g-1")
        let citationsKey = CatalogQueryKey.citationsByArtifact(project: project, graphId: "g-1", artifactId: "a1")
        session.setQueryValue(sources, value: [
            CatalogSource(id: "s1", ref: "SRC-1", sourceTypeID: "t1", title: "Alpha", description: ""),
        ])
        session.setQueryValue(propertiesKey, value: PropertiesSnapshot.empty)
        session.setQueryValue(graphKey, value: EvidenceGraphRows(graphId: "g-1"))
        session.setQueryValue(citationsKey, value: [CatalogListedCitation]())
        let activity = CatalogActivity(revision: 12, at: "2026-10-15T16:00:00Z")

        session.apply(
            CatalogWriteEffects(sourceScopes: ["s1"], activity: activity),
            .mutatedSourceWorkspace(sourceId: "s1")
        )

        let list: QueryHandle<[CatalogSource]> = try #require(session.queryHandle(sources))
        #expect(list.value?.first?.updated == activity)
        // Nothing is fetching, and a `query` finds nothing stale to reload.
        let properties: QueryHandle<PropertiesSnapshot> = session.query(propertiesKey)
        let graph: QueryHandle<EvidenceGraphRows> = session.query(graphKey)
        let citations: QueryHandle<[CatalogListedCitation]> = session.query(citationsKey)
        #expect(!properties.isFetching && !graph.isFetching && !citations.isFetching)
    }

    private func detail(_ id: String) -> CatalogConclusionDetail {
        CatalogConclusionDetail(
            entity: CatalogCanonicalEntity(id: id, ref: "PER-\(id)", subjectTypeID: "t", label: ""),
            fields: []
        )
    }

    private func claims(onGraph graphID: String) -> [CatalogPersonClaimGroup] {
        [CatalogPersonClaimGroup(
            sourceID: "s1", sourceRef: "SRC-1", title: "Alpha", sourceTypeID: "t1",
            claims: [CatalogPersonClaim(
                claimID: "c1", graphID: graphID, graphRef: "EG-1", graphName: "Default",
                subject: CatalogSubject(
                    id: "sub1", ref: "SUB-1", sourceID: "s1", subjectTypeID: "t", label: "Ada", description: ""
                ),
                observations: []
            )]
        )]
    }

    /// T-7 (AC-2.1): a write's touched handles revalidate only their own detail
    /// pages. A visible page reloads; a hidden one goes stale.
    @Test func touchedHandlesRevalidateOnlyTheirDetailPages() async {
        let store = FakeStore()
        seedStore(store)
        store.seededConclusionDetails = ["e1": detail("e1"), "e3": detail("e3")]
        let session = makeSession(store: store)
        let project = session.projectKey
        session.apply(location: .personDetail(entityId: "e1", ref: "PER-e1", title: "One"))
        let first = CatalogQueryKey.conclusionDetail(project: project, entityId: "e1")
        let third = CatalogQueryKey.conclusionDetail(project: project, entityId: "e3")
        let visible: QueryHandle<CatalogConclusionDetail> = session.query(first)
        let hidden: QueryHandle<CatalogConclusionDetail> = session.query(third)
        await waitForQuery(visible)
        await waitForQuery(hidden)

        let effects = CatalogWriteEffects(handles: ["e1", "e2"])
        #expect(session.revalidatedKeys(for: effects) == [first])
        session.apply(effects)
        #expect(visible.isFetching)
        await session.settleWrites()
        #expect(session.queryHandle(third) as QueryHandle<CatalogConclusionDetail>? != nil)

        session.apply(CatalogWriteEffects(handles: ["e3"]))
        let stale: QueryHandle<CatalogConclusionDetail>? = session.queryHandle(third)
        #expect(stale?.isStale == true && stale?.isFetching == false)
    }

    /// A Promote's effects name the handles it filed: those handles' keys reload and the
    /// other people's cached pages are neither reloaded nor marked stale.
    @Test func promoteRevalidatesOnlyItsPeople() async throws {
        let store = FakeStore()
        seedStore(store)
        store.subjectTypesByProject[projectDir] = [
            CatalogSubjectType(
                id: "type-person", key: "person", origin: "provenencia", label: "Person",
                description: "", refPrefix: "PER", candidateRefPrefix: "CPR"
            ),
        ]
        store.subjectsByGraph["g-1"] = [
            CatalogSubject(id: "sub-1", ref: "CPR-1", sourceID: "s1", subjectTypeID: "type-person", label: "", description: ""),
            CatalogSubject(id: "sub-2", ref: "CPR-2", sourceID: "s1", subjectTypeID: "type-person", label: "", description: ""),
        ]
        let a = store.seedPromotion(projectDir: projectDir, subjectID: "sub-1").entity
        let b = store.seedPromotion(projectDir: projectDir, subjectID: "sub-2").entity
        store.seededPersonClaims = [a.id: [], b.id: []]
        let session = makeSession(store: store)
        let aDetail = CatalogQueryKey.conclusionDetail(project: session.projectKey, entityId: a.id)
        let bDetail = CatalogQueryKey.conclusionDetail(project: session.projectKey, entityId: b.id)
        let aClaims = CatalogQueryKey.personClaims(project: session.projectKey, entityId: a.id)
        let bClaims = CatalogQueryKey.personClaims(project: session.projectKey, entityId: b.id)

        let bDetailHandle: QueryHandle<CatalogConclusionDetail> = session.query(bDetail)
        let bClaimsHandle: QueryHandle<CatalogPersonClaims> = session.query(bClaims)
        await waitForQuery(bDetailHandle)
        await waitForQuery(bClaimsHandle)
        session.apply(location: .personDetail(entityId: a.id, ref: a.ref, title: nil))
        let aDetailHandle: QueryHandle<CatalogConclusionDetail> = try #require(session.queryHandle(aDetail))
        await waitForQuery(aDetailHandle)
        let aClaimsHandle: QueryHandle<CatalogPersonClaims> = session.query(aClaims)
        await waitForQuery(aClaimsHandle)

        let effects = CatalogWriteEffects(handles: [a.id])
        #expect(Set(session.revalidatedKeys(for: effects)).isSuperset(of: [aDetail, aClaims]))
        #expect(Set(session.revalidatedKeys(for: effects)).isDisjoint(with: [bDetail, bClaims]))
        session.apply(effects)
        #expect(aDetailHandle.isFetching)
        await session.settleWrites()

        #expect(bDetailHandle.value != nil && !bDetailHandle.isStale && !bDetailHandle.isFetching)
        #expect(bClaimsHandle.value != nil && !bClaimsHandle.isStale && !bClaimsHandle.isFetching)
        #expect(session.queryHandle(bDetail) as QueryHandle<CatalogConclusionDetail>? != nil)
        #expect(session.queryHandle(bClaims) as QueryHandle<CatalogPersonClaims>? != nil)
    }

    /// T-8 (AC-2.6): a key that two refreshes and a mutation all name is
    /// revalidated once. A hidden `.personClaims` key is marked stale by the pass
    /// that names it, and nothing loads it.
    @Test func aKeyInvalidatedAndRefreshedRevalidatesOnce() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let project = session.projectKey
        let key = CatalogQueryKey.personClaims(project: project, entityId: "e1")
        session.setQueryValue(key, value: CatalogPersonClaims(
            groups: claims(onGraph: "g1"), inputs: CatalogPageInputs(handles: ["e1"], evidenceGraphs: ["g1"])
        ))
        let effects = CatalogWriteEffects(handles: ["e1"], evidenceGraphs: ["g1"], lists: [.propertyVocabulary])

        #expect(session.revalidatedKeys(for: effects) == [key])
        session.apply(effects)
        await session.settleWrites()
        let hidden: QueryHandle<CatalogPersonClaims>? = session.queryHandle(key)
        #expect(hidden?.value != nil && hidden?.isStale == true && hidden?.isFetching == false)
    }

    /// T-9 (AC-1.5): person claims follow their handle and the graphs their
    /// value was built from; the detail follows the handle.
    @Test func personClaimsFollowHandlesAndGraphs() {
        let session = makeSession()
        let project = session.projectKey
        let claimsKey = CatalogQueryKey.personClaims(project: project, entityId: "e1")
        let detailKey = CatalogQueryKey.conclusionDetail(project: project, entityId: "e1")
        session.setQueryValue(claimsKey, value: CatalogPersonClaims(
            groups: claims(onGraph: "g1"), inputs: CatalogPageInputs(evidenceGraphs: ["g1"], sources: ["s1"])
        ))
        session.setQueryValue(detailKey, value: detail("e1"))

        #expect(session.revalidatedKeys(for: CatalogWriteEffects(evidenceGraphs: ["g1"])) == [claimsKey])
        #expect(session.revalidatedKeys(for: CatalogWriteEffects(evidenceGraphs: ["g9"])).isEmpty)
        #expect(Set(session.revalidatedKeys(for: CatalogWriteEffects(handles: ["e1"]))) == [claimsKey, detailKey])
    }

    /// T-7 (AC-3.1, AC-3.2): a write that deleted a handle drops that handle's
    /// hidden keys of the kinds that declare it, and leaves a visible key to
    /// reload.
    @Test func deletedEntitiesLoseTheirHiddenKeys() async {
        let store = FakeStore()
        store.seededConclusionDetails = ["e1": detail("e1"), "e3": detail("e3")]
        let session = makeSession(store: store)
        let project = session.projectKey
        let detail1 = CatalogQueryKey.conclusionDetail(project: project, entityId: "e1")
        let family1 = CatalogQueryKey.personFamily(project: project, entityId: "e1")
        let claims1 = CatalogQueryKey.personClaims(project: project, entityId: "e1")
        let detail3 = CatalogQueryKey.conclusionDetail(project: project, entityId: "e3")
        let sourceKey = CatalogQueryKey.sourceWorkspace(project: project, sourceId: "e1")
        session.setQueryValue(detail1, value: detail("e1"))
        session.setQueryValue(family1, value: CatalogPersonFamily(units: []))
        session.setQueryValue(claims1, value: CatalogPersonClaims(groups: claims(onGraph: "g1")))
        session.setQueryValue(detail3, value: detail("e3"))
        session.setQueryValue(sourceKey, value: CatalogSourceWorkspace(
            source: CatalogSource(id: "e1", ref: "SRC-1", sourceTypeID: "t1", title: "Alpha", description: ""),
            notes: [], metadata: [], artifacts: [], credibility: nil
        ))
        session.apply(location: .sectionRoot(.persons))

        session.apply(CatalogWriteEffects(deleted: [CatalogWriteEffectsDeleted(entity: .handle, ids: ["e1"])]))
        #expect(session.queryHandle(detail1) as QueryHandle<CatalogConclusionDetail>? == nil)
        #expect(session.queryHandle(family1) as QueryHandle<CatalogPersonFamily>? == nil)
        #expect(session.queryHandle(claims1) as QueryHandle<CatalogPersonClaims>? == nil)
        let untouched: QueryHandle<CatalogConclusionDetail>? = session.queryHandle(detail3)
        #expect(untouched != nil && untouched?.isStale == false)
        #expect(session.queryHandle(sourceKey) as QueryHandle<CatalogSourceWorkspace>? != nil)

        session.apply(location: .personDetail(entityId: "e3", ref: "PER-e3", title: nil))
        await session.settleWrites()
        store.seededConclusionDetails["e3"] = nil
        session.apply(CatalogWriteEffects(
            handles: ["e3"], deleted: [CatalogWriteEffectsDeleted(entity: .handle, ids: ["e3"])]
        ))
        let visible: QueryHandle<CatalogConclusionDetail>? = session.queryHandle(detail3)
        #expect(visible != nil && visible?.isFetching == true)
        await session.settleWrites()
        #expect(ConclusionDetailPresentation(visible!.reading, isFetching: false) { $0.entity.id } == .gone)
    }

    /// T-3 (AC-2.1, AC-2.2): a page visited and then hidden goes stale on a write
    /// naming it; going Back shows its old value while it reloads.
    @Test func backToAStalePageShowsItsValueWhileItRefreshes() async throws {
        let store = FakeStore()
        store.seededConclusionDetails = ["e1": detail("e1"), "e3": detail("e3")]
        store.seededPersonFamilies = ["e1": CatalogPersonFamily(units: [])]
        let session = makeSession(store: store)
        let project = session.projectKey
        let detailKey = CatalogQueryKey.conclusionDetail(project: project, entityId: "e1")
        let familyKey = CatalogQueryKey.personFamily(project: project, entityId: "e1")
        let e1 = WorkspaceLocation.personDetail(entityId: "e1", ref: "PER-e1", title: nil)

        session.apply(location: e1.withPageSection(.family))
        await session.settleWrites()
        session.apply(location: e1)
        await session.settleWrites()
        session.apply(location: .personDetail(entityId: "e3", ref: "PER-e3", title: nil))
        await session.settleWrites()
        session.apply(CatalogWriteEffects(handles: ["e1"]))

        let detailHandle: QueryHandle<CatalogConclusionDetail> = try #require(session.queryHandle(detailKey))
        let familyHandle: QueryHandle<CatalogPersonFamily> = try #require(session.queryHandle(familyKey))
        #expect(detailHandle.isStale && !detailHandle.isFetching)
        #expect(familyHandle.isStale && !familyHandle.isFetching)

        var updated = detail("e1")
        updated.memberCount = 2
        store.seededConclusionDetails["e1"] = updated
        session.apply(location: e1)
        #expect(detailHandle.value == detail("e1"))
        #expect(detailHandle.isFetching)
        await session.settleWrites()
        #expect(detailHandle.value == updated)
        #expect(!detailHandle.isStale)
    }

    /// T-8 (AC-3.3): a stale page of an entity that is gone reloads into S16-04's
    /// reading, which the page presents as gone.
    @Test func aStaleReloadOfAGoneEntityReadsAsGone() async throws {
        let store = FakeStore()
        store.seededConclusionDetails = ["e1": detail("e1")]
        let session = makeSession(store: store)
        let key = CatalogQueryKey.conclusionDetail(project: session.projectKey, entityId: "e1")
        session.apply(location: .personDetail(entityId: "e1", ref: "PER-e1", title: nil))
        await session.settleWrites()
        session.apply(location: .sectionRoot(.persons))
        session.apply(CatalogWriteEffects(handles: ["e1"]))

        store.seededConclusionDetails = [:]
        session.apply(location: .personDetail(entityId: "e1", ref: "PER-e1", title: nil))
        await session.settleWrites()

        let handle: QueryHandle<CatalogConclusionDetail> = try #require(session.queryHandle(key))
        guard case .loaded(_, let refreshFailure) = handle.reading else {
            Issue.record("expected a loaded reading, got \(handle.reading)")
            return
        }
        #expect(refreshFailure != nil)
        #expect(ConclusionDetailPresentation(handle.reading, isFetching: false) { $0.entity.id } == .gone)
    }

    /// T-9 (AC-4.1 - AC-4.4): at most 50 hidden entities keep their keys, the
    /// least recently shown go first, and the entity on screen keeps all of its
    /// keys, a section key its place does not warm included.
    @Test func hiddenConclusionPagesAreCappedAtFifty() async throws {
        let store = FakeStore()
        for index in 0...52 {
            store.seededConclusionDetails["e\(index)"] = detail("e\(index)")
        }
        store.seededPersonFamilies = ["e0": CatalogPersonFamily(units: []), "e1": CatalogPersonFamily(units: [])]
        let session = makeSession(store: store)
        let project = session.projectKey
        func detailKey(_ id: String) -> CatalogQueryKey { .conclusionDetail(project: project, entityId: id) }
        func familyKey(_ id: String) -> CatalogQueryKey { .personFamily(project: project, entityId: id) }
        func holds(_ key: CatalogQueryKey) -> Bool {
            (session.queryHandle(key) as QueryHandle<CatalogConclusionDetail>?) != nil
                || (session.queryHandle(key) as QueryHandle<CatalogPersonFamily>?) != nil
        }
        func show(_ id: String, _ section: ConclusionPageSection? = nil) async {
            session.apply(location: .personDetail(entityId: id, ref: "PER-\(id)", title: nil).withPageSection(section))
            await session.settleWrites()
            #expect(holds(detailKey(id)))
        }

        session.setQueryValue(detailKey("never"), value: detail("never"))
        await show("e0", .family)
        for index in 1...50 {
            await show("e\(index)")
        }
        #expect(!holds(detailKey("never")))
        #expect(holds(detailKey("e0")) && holds(familyKey("e0")))

        await show("e51")
        #expect(!holds(detailKey("e0")) && !holds(familyKey("e0")))
        for index in 1...50 {
            #expect(holds(detailKey("e\(index)")), "e\(index)")
        }

        session.setQueryValue(familyKey("e1"), value: CatalogPersonFamily(units: []))
        session.setQueryValue(detailKey("extra"), value: detail("extra"))
        await show("e1")
        #expect(!holds(detailKey("extra")))
        #expect(holds(familyKey("e1")))
        #expect(holds(detailKey("e2")))

        await show("e52")
        #expect(!holds(detailKey("e2")))
        #expect(holds(detailKey("e1")) && holds(familyKey("e1")))
        #expect(holds(detailKey("e3")))
    }

    /// The keys that a write with these `effects` revalidates.
    private func named(_ session: WorkspaceSession, _ effects: CatalogWriteEffects) -> Set<CatalogQueryKey> {
        Set(session.revalidatedKeys(for: effects))
    }

    /// T-6 (AC-1.1, AC-2.1): the Family section follows each relation its value
    /// was built from, and no other handle.
    @Test func familyFollowsEachRelationItWasBuiltFrom() {
        let session = makeSession()
        let key = CatalogQueryKey.personFamily(project: session.projectKey, entityId: "e1")
        // parent, implied sibling, partner, child and the pivot event
        let relations = ["p1", "s1", "w1", "c1", "m1"]
        session.setQueryValue(key, value: CatalogPersonFamily(
            units: [], inputs: CatalogPageInputs(handles: Set(relations))
        ))
        for id in relations {
            #expect(named(session, CatalogWriteEffects(handles: [id])) == [key], "\(id)")
        }
        #expect(named(session, CatalogWriteEffects(handles: ["x9"])).isEmpty)
        #expect(named(session, CatalogWriteEffects.empty).isEmpty)
    }

    /// T-7 (AC-1.2, AC-2.1): the Timeline section follows its events and
    /// co-participants, a summary change of an event included.
    @Test func timelineFollowsItsEventsAndCoParticipants() {
        let session = makeSession()
        let key = CatalogQueryKey.personEvents(project: session.projectKey, entityId: "e1")
        session.setQueryValue(key, value: CatalogPersonTimeline(inputs: CatalogPageInputs(handles: ["ev1", "q1"])))

        #expect(named(session, CatalogWriteEffects(handles: ["q1"])) == [key])
        #expect(named(session, CatalogWriteEffects(summaryHandles: ["ev1"])) == [key])
        #expect(named(session, CatalogWriteEffects(handles: ["x9"])).isEmpty)
    }

    /// The detail for `id`, built from its own handle, graph "g1" and Source "src1".
    private func detailWithInputs(_ id: String) -> CatalogConclusionDetail {
        var built = detail(id)
        built.inputs = CatalogPageInputs(handles: [id], evidenceGraphs: ["g1"], sources: ["src1"])
        return built
    }

    /// T-8 (AC-1.3, AC-1.4, AC-2.2, AC-2.3): a Source's words reload the claims,
    /// record links and detail that show them; a Source's activity, and an edit
    /// inside another graph of the Source, do not.
    @Test func sourceWordsNotSourceActivityReloadThePage() async {
        let store = FakeStore()
        store.seededConclusionDetails = ["e1": detailWithInputs("e1")]
        let session = makeSession(store: store)
        let project = session.projectKey
        let claimsKey = CatalogQueryKey.personClaims(project: project, entityId: "e1")
        let linksKey = CatalogQueryKey.personRecordLinks(project: project, entityId: "e1")
        let detailKey = CatalogQueryKey.conclusionDetail(project: project, entityId: "e1")
        let inputs = CatalogPageInputs(evidenceGraphs: ["g1"], sources: ["src1"])
        session.setQueryValue(claimsKey, value: CatalogPersonClaims(groups: claims(onGraph: "g1"), inputs: inputs))
        session.setQueryValue(linksKey, value: CatalogPersonRecordLinks(inputs: inputs))
        session.setQueryValue(detailKey, value: detailWithInputs("e1"))
        let all: Set = [claimsKey, linksKey, detailKey]

        let words = CatalogWriteEffects(reads: [CatalogWriteEffectsRead(read: .sourceRecords, ids: ["src1"])])
        #expect(named(session, words) == all)
        #expect(named(session, CatalogWriteEffects(evidenceGraphs: ["g1"])) == all)
        // A Subject, Observation, Citation or note edit in another graph of the Source.
        let elsewhere = CatalogWriteEffects(
            evidenceGraphs: ["g2"],
            reads: [CatalogWriteEffectsRead(read: .citations, ids: ["g2"])],
            sourceScopes: ["src1"]
        )
        #expect(named(session, elsewhere).isEmpty)
        #expect(named(session, CatalogWriteEffects(sourceScopes: ["src1"])).isEmpty)

        session.apply(location: .personDetail(entityId: "e1", ref: "PER-e1", title: nil))
        await session.settleWrites()
        let handle: QueryHandle<CatalogConclusionDetail> = session.query(detailKey)
        var renamed = detailWithInputs("e1")
        renamed.memberCount = 2
        store.seededConclusionDetails = ["e1": renamed]
        session.apply(words)
        #expect(handle.isFetching)
        await session.settleWrites()
        #expect(handle.value == renamed)
        #expect(!handle.isStale)

        session.apply(location: .sectionRoot(.persons))
        session.apply(words)
        #expect(handle.isStale)
        #expect(!handle.isFetching)
        #expect(handle.value == renamed)
    }

    /// T-9 (AC-1.5, AC-1.7): a per-entity key always follows its own handle, and
    /// follows any handle, graph and Source until its first load lands.
    @Test func anEntityKeyFollowsItsOwnIdAndAnyIdUntilLoaded() {
        let session = makeSession()
        let project = session.projectKey
        let anyHandle = CatalogWriteEffects(handles: ["x9"])
        let anyGraph = CatalogWriteEffects(evidenceGraphs: ["g9"])
        let anySource = CatalogWriteEffects(reads: [CatalogWriteEffectsRead(read: .sourceRecords, ids: ["s9"])])
        func check<Value: Sendable>(_ key: CatalogQueryKey, empty: Value) {
            // Still loading: its inputs are not known, so it follows any id.
            let _: QueryHandle<Value> = session.query(key)
            #expect((session.queryHandle(key) as QueryHandle<Value>?)?.value == nil)
            for effects in [anyHandle, anyGraph, anySource] {
                #expect(named(session, effects).contains(key), "\(key.kind) loading")
            }
            // Loaded with empty inputs: only its own handle.
            session.setQueryValue(key, value: empty)
            #expect(named(session, CatalogWriteEffects(handles: ["e1"])).contains(key), "\(key.kind) own id")
            for effects in [anyHandle, anyGraph, anySource] {
                #expect(!named(session, effects).contains(key), "\(key.kind) loaded")
            }
        }
        check(.conclusionDetail(project: project, entityId: "e1"), empty: detail("e1"))
        check(.personClaims(project: project, entityId: "e1"), empty: CatalogPersonClaims())
        check(.personFamily(project: project, entityId: "e1"), empty: CatalogPersonFamily(units: []))
        check(.personEvents(project: project, entityId: "e1"), empty: CatalogPersonTimeline())
        check(.personRecordLinks(project: project, entityId: "e1"), empty: CatalogPersonRecordLinks())
    }

    /// T-9 (AC-1.6): a visible Family reloads when a relative is written; a
    /// hidden one is marked stale and loads nothing.
    @Test func familyReloadsWhenVisibleAndStalesWhenHidden() async {
        let store = FakeStore()
        store.seededPersonFamilies = ["e1": CatalogPersonFamily(
            units: [], inputs: CatalogPageInputs(handles: ["e1", "w1"])
        )]
        let session = makeSession(store: store)
        let key = CatalogQueryKey.personFamily(project: session.projectKey, entityId: "e1")
        session.apply(location: .personDetail(entityId: "e1", ref: "PER-e1", title: nil, pageSection: .family))
        await session.settleWrites()
        let handle: QueryHandle<CatalogPersonFamily> = session.query(key)
        #expect(handle.value?.units.isEmpty == true)

        let entity = CatalogCanonicalEntity(id: "w1", ref: "PER-w1", subjectTypeID: "t", label: "")
        let partner = CatalogFamilyUnit(
            kind: .partner,
            partners: [CatalogFamilyMember(
                person: CatalogPersonSummary(entity: entity, name: nil, nameValueCount: 0),
                link: CatalogFamilyLink(recorded: false, associationIDs: ["a1"], implied: [])
            )],
            children: []
        )
        store.seededPersonFamilies = ["e1": CatalogPersonFamily(
            units: [partner], inputs: CatalogPageInputs(handles: ["e1", "w1"])
        )]
        session.apply(CatalogWriteEffects(handles: ["w1"]))
        #expect(handle.isFetching)
        await session.settleWrites()
        #expect(handle.value?.units.count == 1)

        session.apply(location: .sectionRoot(.persons))
        session.apply(CatalogWriteEffects(handles: ["w1"]))
        #expect(handle.isStale)
        #expect(!handle.isFetching)
    }

    /// T-12 (AC-2.7): the Evidence graph keys declare the slots they follow, so a write reloads
    /// the graphs it names; the lists merge the rows it touches instead.
    @Test func effectSlotsRevalidateTheirKeys() {
        let session = makeSession()
        let project = session.projectKey
        let graph1 = CatalogQueryKey.evidenceGraph(project: project, graphId: "g1")
        let graph2 = CatalogQueryKey.evidenceGraph(project: project, graphId: "g2")
        session.setQueryValue(graph1, value: EvidenceGraphRows(graphId: "g1"))
        session.setQueryValue(graph2, value: EvidenceGraphRows(graphId: "g2"))
        session.setQueryValue(CatalogQueryKey.personsList(project: project), value: CatalogListRows<CatalogPersonSummary>())
        session.setQueryValue(CatalogQueryKey.eventsList(project: project), value: CatalogListRows<CatalogEventSummary>())
        session.setQueryValue(CatalogQueryKey.placesList(project: project), value: CatalogListRows<CatalogPlaceSummary>())

        // The lists merge the touched rows (`.run`); only the graph is revalidated.
        let named = session.revalidatedKeys(for: CatalogWriteEffects(handles: ["e1"], evidenceGraphs: ["g1"]))
        #expect(named == [graph1])
        #expect(session.revalidatedKeys(for: CatalogWriteEffects(handleScopes: ["e1"])).isEmpty)
    }

    private func citation(_ id: String, artifactID: String) -> CatalogCitation {
        CatalogCitation(
            id: id, ref: "CIT-\(id)", artifactID: artifactID, locatorJSON: "{}", transcription: "",
            description: "", transcriptionUncertain: false, transcriptionNote: ""
        )
    }

    /// Each read follows only what feeds it (D-27): with the graph on screen, a
    /// Subject create reloads the graph and nothing else, and an Observation
    /// create also reloads the citation counts and the Properties `usedBy`.
    @Test func eachReadFollowsOnlyWhatFeedsIt() async throws {
        let store = FakeStore()
        seedStore(store)
        store.evidenceGraphsByProject[projectDir] = [evidenceGraph("g-1", sourceID: "s1", artifactIDs: ["a1"])]
        store.citationsByID["c1"] = citation("c1", artifactID: "a1")
        let session = makeSession(store: store)
        let project = session.projectKey
        session.apply(location: WorkspaceLocation(
            section: .sources, sourceId: "s1", graphId: "g-1", sourceSurface: .graph, title: "Alpha"
        ))
        let propertiesKey = CatalogQueryKey.propertiesWorkspace(project: project)
        let countsKey = CatalogQueryKey.citationCounts(project: project, graphId: "g-1")
        #expect(session.visibleKeys.contains(propertiesKey))
        #expect(session.visibleKeys.contains(countsKey))
        let properties: QueryHandle<PropertiesSnapshot> = session.query(propertiesKey)
        let counts: QueryHandle<[String: Int]> = session.query(countsKey)
        await waitForQuery(properties)
        await waitForQuery(counts)
        #expect(counts.value == ["a1": 1])

        store.citationsByID["c2"] = citation("c2", artifactID: "a1")
        session.apply(CatalogWriteEffects(evidenceGraphs: ["g-1"]))
        #expect(!properties.isFetching && !counts.isFetching)
        try? await Task.sleep(nanoseconds: 50_000_000)
        #expect(counts.value == ["a1": 1])

        session.apply(CatalogWriteEffects(
            evidenceGraphs: ["g-1"],
            reads: [CatalogWriteEffectsRead(read: .citations, ids: ["g-1"])],
            lists: [.propertyUsage]
        ))
        #expect(properties.isFetching)
        #expect(await waitUntil { counts.value == ["a1": 2] })
    }

    /// T-7: a `citations` read for one graph reloads that graph's visible
    /// counts and leaves another graph's warmed counts alone. The fake counts every
    /// seeded Citation on its Artifact for any graph, so the reload shows in which
    /// graph the store was asked, not in the values.
    @Test func citationReadsRefreshOnlyTheirGraph() async throws {
        let store = FakeStore()
        seedStore(store)
        store.evidenceGraphsByProject[projectDir] = [
            evidenceGraph("g-1", sourceID: "s1", artifactIDs: ["a1"]),
            evidenceGraph("g-2", sourceID: "s1", artifactIDs: ["a2"]),
        ]
        store.citationsByID["c1"] = citation("c1", artifactID: "a1")
        store.citationsByID["c2"] = citation("c2", artifactID: "a2")
        let session = makeSession(store: store)
        let project = session.projectKey
        session.apply(location: WorkspaceLocation(
            section: .sources, sourceId: "s1", graphId: "g-1", sourceSurface: .graph, title: "Alpha"
        ))
        let first: QueryHandle<[String: Int]> = session.query(.citationCounts(project: project, graphId: "g-1"))
        let second: QueryHandle<[String: Int]> = session.query(.citationCounts(project: project, graphId: "g-2"))
        await waitForQuery(first)
        await waitForQuery(second)
        #expect(first.value == ["a1": 1, "a2": 1] && second.value == ["a1": 1, "a2": 1])
        let loaded = store.citationCountsGraphIDs
        #expect(loaded.filter { $0 == "g-1" }.count == 1 && loaded.filter { $0 == "g-2" }.count == 1)

        store.citationsByID["c3"] = citation("c3", artifactID: "a1")
        session.apply(CatalogWriteEffects(reads: [CatalogWriteEffectsRead(read: .citations, ids: ["g-1"])]))

        await session.settleWrites()
        #expect(first.value == ["a1": 2, "a2": 1])
        #expect(store.citationCountsGraphIDs.filter { $0 == "g-1" }.count == 2)
        #expect(store.citationCountsGraphIDs.filter { $0 == "g-2" }.count == 1)
        #expect(second.value == ["a1": 1, "a2": 1])
    }

    /// T-8: the composer's location names its Artifact, so the Artifact's
    /// citations key is visible and `applyWrite` is `apply` alone; the key
    /// revalidates from the write's `citations` read, with no `query` after.
    @Test func composerWriteReloadsTheArtifactListItShows() async throws {
        let store = FakeStore()
        seedStore(store)
        store.evidenceGraphsByProject[projectDir] = [evidenceGraph("g-1", sourceID: "s1", artifactIDs: ["a1"])]
        store.citationsByID["c1"] = citation("c1", artifactID: "a1")
        let session = makeSession(store: store)
        let project = session.projectKey
        let key = CatalogQueryKey.citationsByArtifact(project: project, graphId: "g-1", artifactId: "a1")
        session.apply(location: WorkspaceLocation(
            section: .sources, sourceId: "s1", graphId: "g-1", citationId: "c1", artifactId: "a1",
            sourceSurface: .citationComposer, title: "Alpha"
        ))
        #expect(session.visibleKeys.contains(key))
        let handle: QueryHandle<[CatalogListedCitation]> = session.query(key)
        await waitForQuery(handle)
        #expect(handle.value?.count == 1)
        let context = CitationComposerContext(
            store: store, session: session, userID: "u1", sourceID: "s1", graphID: "g-1"
        )
        context.artifactID = "a1"

        store.citationsByID["c2"] = citation("c2", artifactID: "a1")
        context.applyWrite(CatalogWriteEffects(
            evidenceGraphs: ["g-1"], reads: [CatalogWriteEffectsRead(read: .citations, ids: ["g-1"])]
        ))

        #expect(await waitUntil { handle.value?.count == 2 })
    }

    /// `usedBy` on the Properties inspector counts Observations, and it
    /// moves whenever a citation save creates or deletes one.
    @Test func applySavedCitationInvalidatesPropertiesUsedBy() async {
        let store = FakeStore()
        seedStore(store)
        store.propertiesByProject[projectDir] = [
            CatalogProperty(
                id: "prop-name",
                key: "name",
                origin: "provenencia",
                label: "Name",
                description: "",
                valueType: "name",
                usedBy: 2
            ),
        ]
        let session = makeSession(store: store)
        let fieldsKey = CatalogQueryKey.propertiesWorkspace(project: session.projectKey)
        let fields: QueryHandle<PropertiesSnapshot> = session.query(fieldsKey)
        await waitForQuery(fields)
        #expect(fields.value?.properties.first?.usedBy == 2)

        store.propertiesByProject[projectDir]?[0].usedBy = 1
        session.apply(CatalogWriteEffects(evidenceGraphs: ["g-1"], lists: [.propertyUsage]))

        let _: QueryHandle<PropertiesSnapshot> = session.query(fieldsKey)
        await waitForQuery(fields)
        #expect(fields.value?.properties.first?.usedBy == 1)
    }

    @Test func readyValueIgnoresStaleCache() async {
        let session = makeSession()
        let key = CatalogQueryKey.sourcesList(project: session.projectKey)
        let handle = session.ensureQuery(key) { ["alpha"] }
        await waitForQuery(handle)
        session.invalidate(key)
        let ready: [String]? = await session.readyValue(key)
        #expect(ready == nil)
    }

    @Test func staleOlderLoadDoesNotOverwriteNewer() async {
        let session = makeSession()
        let key = CatalogQueryKey.sourcesList(project: session.projectKey)
        let olderGate = Gate()
        let handle = session.ensureQuery(key) {
            await olderGate.waitForOpen()
            return ["old"]
        }
        session.invalidate(key)
        _ = session.ensureQuery(key) { ["new"] }
        await waitForQuery(handle)
        #expect(handle.value == ["new"])
        olderGate.open()
        await Task.yield()
        #expect(handle.value == ["new"])
        #expect(handle.isFetching == false)
    }

    @Test func setQueryValueWinsOverInFlightLoad() async {
        let session = makeSession()
        let key = CatalogQueryKey.sourcesList(project: session.projectKey)
        let gate = Gate()
        let stale = CatalogSource(
            id: "stale",
            ref: "SRC-S",
            sourceTypeID: "t",
            title: "Stale",
            description: ""
        )
        let patched = CatalogSource(
            id: "patched",
            ref: "SRC-P",
            sourceTypeID: "t",
            title: "Patched",
            description: ""
        )
        let handle = session.ensureQuery(key) {
            await gate.waitForOpen()
            return [stale]
        }
        session.setQueryValue(key, value: [patched])
        #expect(handle.value?.first?.id == "patched")
        gate.open()
        await Task.yield()
        #expect(handle.value?.first?.id != "stale")
    }

    @Test func setQueryValueRestartsInFlightLoad() async {
        let store = FakeStore()
        store.sourcesByProject[projectDir] = [
            CatalogSource(
                id: "s1",
                ref: "SRC-1",
                sourceTypeID: "t",
                title: "Census",
                description: ""
            ),
        ]
        let session = makeSession(store: store)
        let key = CatalogQueryKey.sourcesList(project: session.projectKey)
        let gate = Gate()
        let handle = session.ensureQuery(key) {
            await gate.waitForOpen()
            return [CatalogSource]()
        }
        session.setQueryValue(
            key,
            value: [
                CatalogSource(
                    id: "patched",
                    ref: "SRC-P",
                    sourceTypeID: "t",
                    title: "Patched",
                    description: ""
                ),
            ]
        )
        #expect(handle.value?.first?.id == "patched")
        await waitForQuery(handle)
        #expect(handle.value?.first?.id == "s1")
    }

    /// T-15: a write's effects name the graphs whose progress to patch; the
    /// other graph of the same Source keeps its entry and is not fetched.
    @Test func applyGraphEffectsPatchProgressOnly() async {
        let store = FakeStore()
        seedStore(store)
        store.graphProgressByGraph["g-1"] = EvidenceGraphProgress(
            graphId: "g-1", subjectCount: 12, observationCount: 48
        )
        store.graphProgressByGraph["g-2"] = EvidenceGraphProgress(
            graphId: "g-2", subjectCount: 4, observationCount: 0
        )
        let session = makeSession(store: store)
        let listKey = CatalogQueryKey.sourcesList(project: session.projectKey)
        let progressKey = CatalogQueryKey.evidenceGraphProgress(project: session.projectKey)
        let listHandle: QueryHandle<[CatalogSource]> = session.query(listKey)
        let progressHandle: QueryHandle<[String: EvidenceGraphProgress]> = session.query(progressKey)
        await waitForQuery(listHandle)
        await waitForQuery(progressHandle)
        #expect(progressHandle.value?["g-1"]?.subjectCount == 12)
        #expect(progressHandle.value?["g-2"]?.subjectCount == 4)
        let listCallsBefore = store.listEvidenceGraphProgressCalls
        let getCallsBefore = store.getEvidenceGraphProgressCalls
        let sourcesAtLoad = listHandle.value

        store.graphProgressByGraph["g-1"] = EvidenceGraphProgress(
            graphId: "g-1", subjectCount: 99, observationCount: 48
        )
        store.graphProgressByGraph["g-2"] = EvidenceGraphProgress(
            graphId: "g-2", subjectCount: 5, observationCount: 0
        )
        session.apply(CatalogWriteEffects(
            evidenceGraphs: ["g-2"], reads: [CatalogWriteEffectsRead(read: .evidenceGraphProgress, ids: ["g-2"])]
        ))
        var waited: UInt64 = 0
        while waited < 2_000_000_000 {
            if progressHandle.value?["g-2"]?.subjectCount == 5 { break }
            await Task.yield()
            try? await Task.sleep(nanoseconds: 10_000_000)
            waited += 10_000_000
        }
        #expect(progressHandle.value?["g-2"]?.subjectCount == 5)
        #expect(progressHandle.value?["g-1"]?.subjectCount == 12)
        #expect(listHandle.value == sourcesAtLoad)
        #expect(listHandle.isFetching == false)
        #expect(store.listEvidenceGraphProgressCalls == listCallsBefore)
        #expect(store.getEvidenceGraphProgressCalls == getCallsBefore + 1)
    }

    @Test func applyPromotedSubjectPatchesProgress() async {
        let store = FakeStore()
        seedStore(store)
        store.graphProgressByGraph["g-1"] = EvidenceGraphProgress(
            graphId: "g-1", subjectCount: 2, observationCount: 1, filedCount: 0
        )
        let session = makeSession(store: store)
        let progressHandle: QueryHandle<[String: EvidenceGraphProgress]> = session.query(
            CatalogQueryKey.evidenceGraphProgress(project: session.projectKey)
        )
        await waitForQuery(progressHandle)
        #expect(progressHandle.value?["g-1"]?.filedCount == 0)
        let callsBefore = store.getEvidenceGraphProgressCalls

        store.graphProgressByGraph["g-1"] = EvidenceGraphProgress(
            graphId: "g-1", subjectCount: 2, observationCount: 1, filedCount: 2
        )
        session.apply(CatalogWriteEffects(
            evidenceGraphs: ["g-1"],
            reads: [CatalogWriteEffectsRead(read: .evidenceGraphProgress, ids: ["g-1"])]
        ))
        var waited: UInt64 = 0
        while waited < 2_000_000_000 {
            if progressHandle.value?["g-1"]?.filedCount == 2 { break }
            await Task.yield()
            try? await Task.sleep(nanoseconds: 10_000_000)
            waited += 10_000_000
        }
        #expect(store.getEvidenceGraphProgressCalls == callsBefore + 1)
        #expect(progressHandle.value?["g-1"]?.filedCount == 2)
    }

    @Test func applySourceEffectsDoesNotRefetchSourcesList() async {
        let store = FakeStore()
        seedStore(store)
        store.graphProgressByGraph["g-1"] = EvidenceGraphProgress(
            graphId: "g-1", subjectCount: 1, observationCount: 1
        )
        let session = makeSession(store: store)
        let listHandle: QueryHandle<[CatalogSource]> = session.query(
            CatalogQueryKey.sourcesList(project: session.projectKey)
        )
        let progressHandle: QueryHandle<[String: EvidenceGraphProgress]> = session.query(
            CatalogQueryKey.evidenceGraphProgress(project: session.projectKey)
        )
        await waitForQuery(listHandle)
        await waitForQuery(progressHandle)
        let sourcesAtLoad = listHandle.value
        store.graphProgressByGraph["g-1"] = EvidenceGraphProgress(
            graphId: "g-1", subjectCount: 1, observationCount: 2
        )
        session.apply(CatalogWriteEffects(
            evidenceGraphs: ["g-1"], reads: [CatalogWriteEffectsRead(read: .evidenceGraphProgress, ids: ["g-1"])]
        ))
        var waited: UInt64 = 0
        while waited < 2_000_000_000 {
            if progressHandle.value?["g-1"]?.observationCount == 2 { break }
            await Task.yield()
            try? await Task.sleep(nanoseconds: 10_000_000)
            waited += 10_000_000
        }
        #expect(progressHandle.value?["g-1"]?.observationCount == 2)
        #expect(listHandle.value == sourcesAtLoad)
        #expect(listHandle.isFetching == false)
    }

    @Test func graphCameraIsPerGraph() {
        let session = makeSession()
        let first = GraphCanvasCamera(
            magnification: 0.5,
            contentOffset: CGPoint(x: 120, y: 80)
        )
        session.setGraphCamera(first, for: "g-1")
        #expect(session.graphCamera(for: "g-1") == first)
        #expect(session.graphCamera(for: "g-2") == nil)

        let second = GraphCanvasCamera(
            magnification: 1.25,
            contentOffset: CGPoint(x: 10, y: 20)
        )
        session.setGraphCamera(second, for: "g-2")
        #expect(session.graphCamera(for: "g-1") == first)
        #expect(session.graphCamera(for: "g-2") == second)
        #expect(session.graphCamera(for: "g-1") != session.graphCamera(for: "g-2"))
    }

    /// The sidebar recounts once for effects that report `counts`, and for nothing else.
    @Test func countsListRecounts() async {
        let store = FakeStore()
        let session = makeSession(store: store)
        let propertiesKey = CatalogQueryKey.propertiesWorkspace(project: session.projectKey)
        session.setQueryValue(propertiesKey, value: PropertiesSnapshot.empty)
        let propertiesCalls = store.getPropertiesWorkspaceCalls
        var calls = 0
        session.onNavCountsMoved = { calls += 1 }
        session.apply(CatalogWriteEffects(lists: [.counts]))
        await session.settleWrites()
        #expect(calls == 1)
        #expect(store.getPropertiesWorkspaceCalls == propertiesCalls)
        let handle: QueryHandle<PropertiesSnapshot>? = session.queryHandle(propertiesKey)
        #expect(handle?.isStale == false)

        session.apply(.empty, .createdSource(CatalogSource(id: "s2", ref: "SRC-2", sourceTypeID: "", title: "New Row", description: "")))
        session.apply(CatalogWriteEffects(lists: [.propertyVocabulary]))
        session.apply(.mutatedSourceWorkspace(sourceId: "s1"))
        session.apply(CatalogWriteEffects(sourceScopes: ["s1"], activity: CatalogActivity(revision: 1)))
        await session.settleWrites()
        #expect(calls == 1)
    }

    /// T-10: a key marked stale while hidden keeps its value but is not settled
    /// until it reloads.
    @Test func staleKeyIsNotSettled() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let key = CatalogQueryKey.sourcesList(project: session.projectKey)
        let handle: QueryHandle<[CatalogSource]> = session.query(key)
        await waitForQuery(handle)
        #expect(handle.isSettled)

        session.apply(.deletedSource(id: "gone"))
        #expect(handle.isStale)
        #expect(!handle.isSettled)
        #expect(handle.status == .ready)
        #expect(!handle.isFetching)

        let again: QueryHandle<[CatalogSource]> = session.query(key)
        await waitForQuery(again)
        #expect(!handle.isStale)
        #expect(handle.isSettled)
    }

    /// T-11: a whole-value write makes a stale key current; a partial patch does not.
    @Test func setQueryValueClearsStaleAndPatchKeepsIt() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let key = CatalogQueryKey.sourcesList(project: session.projectKey)
        let handle: QueryHandle<[CatalogSource]> = session.query(key)
        await waitForQuery(handle)
        session.apply(.deletedSource(id: "gone"))
        #expect(handle.isStale)

        let result = session.patchCached(key, as: [CatalogSource].self) { rows in
            rows[0].title = "Patched"
            return true
        }
        #expect(result == .applied)
        #expect(handle.isStale)

        session.setQueryValue(key, value: handle.value ?? [])
        #expect(!handle.isStale)
    }

    /// T-18 (a): a key marked stale while its first load is in flight restarts
    /// that load when it is queried, instead of keeping an answer that may be older.
    @Test func staleKeyQueriedDuringLoadReloads() async {
        let store = FakeStore()
        store.evidenceGraphsByProject[projectDir] = [evidenceGraph("g1", sourceID: "s1")]
        store.listEvidenceGraphsHold.isOn = true
        let session = makeSession(store: store)
        let key = session.evidenceGraphsKey
        let handle: QueryHandle<[CatalogEvidenceGraph]> = session.query(key)
        await store.listEvidenceGraphsHold.untilSuspended(1)

        session.apply(
            CatalogWriteEffects(reads: [CatalogWriteEffectsRead(read: .evidenceGraphs, ids: ["s9"])]),
            .deletedSource(id: "s9")
        )
        #expect(handle.isStale)
        store.evidenceGraphsByProject[projectDir] = [evidenceGraph("g2", sourceID: "s1")]
        let _: QueryHandle<[CatalogEvidenceGraph]> = session.query(key)
        await store.listEvidenceGraphsHold.untilSuspended(2)
        store.listEvidenceGraphsHold.isOn = false
        store.listEvidenceGraphsHold.release()
        store.listEvidenceGraphsHold.release()
        await session.settleWrites()
        #expect(handle.isSettled)
        #expect(!handle.isStale)
        #expect(handle.value?.map(\.id) == ["g2"])
    }

    /// T-18 (b): a patch that finds the key's first load in flight restarts the load.
    @Test func patchDuringFirstLoadFallsBack() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        session.apply(location: .sectionRoot(.sources))
        let handle: QueryHandle<[CatalogSource]>? = session.queryHandle(
            CatalogQueryKey.sourcesList(project: session.projectKey)
        )
        #expect(handle?.value == nil)

        session.apply(CatalogWriteEffects(
            sourceScopes: ["s1"], activity: CatalogActivity(revision: 5, at: "2026-01-01T00:00:00Z")
        ))
        await session.settleWrites()
        #expect(await waitUntil { store.listSourcesCalls == 2 })
        #expect(handle?.value?.first?.id == "s1")
    }

    /// T-8: a created Source applied while the visible list's first load is in
    /// flight restarts that load, and the row is held once.
    @Test func createdSourceDuringFirstLoadRestartsTheLoad() async {
        let store = FakeStore()
        seedStore(store)
        let row = CatalogSource(id: "s2", ref: "SRC-2", sourceTypeID: "t1", title: "Deed", description: "")
        store.sourcesByProject[projectDir]?.append(row)
        let session = makeSession(store: store)
        session.apply(location: .sectionRoot(.sources))

        session.apply(.createdSource(row))
        await session.settleWrites()
        #expect(await waitUntil { store.listSourcesCalls == 2 })
        let handle: QueryHandle<[CatalogSource]>? = session.queryHandle(
            CatalogQueryKey.sourcesList(project: session.projectKey)
        )
        #expect(handle?.value?.filter { $0.id == "s2" }.count == 1)
    }

    /// T-15: a hidden graph key goes stale on a write that names it and
    /// reloads when its canvas is shown again.
    @Test func hiddenGraphReloadsOnlyWhenRevisited() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let project = session.projectKey
        let graphLocation = { (graphId: String) in
            WorkspaceLocation(section: .sources, sourceId: "s1", graphId: graphId, sourceSurface: .graph)
        }
        session.apply(location: graphLocation("G"))
        await session.settleWrites()
        session.apply(location: graphLocation("H"))
        await session.settleWrites()
        let graphG: QueryHandle<EvidenceGraphRows>? = session.queryHandle(.evidenceGraph(project: project, graphId: "G"))
        #expect(graphG?.isSettled == true)
        let before = store.listSubjectsGraphIDs

        session.apply(CatalogWriteEffects(evidenceGraphs: ["G", "H"]))
        await session.settleWrites()
        #expect(Array(store.listSubjectsGraphIDs.dropFirst(before.count)) == ["H"])
        #expect(graphG?.isStale == true)

        session.apply(location: graphLocation("G"))
        await session.settleWrites()
        #expect(Array(store.listSubjectsGraphIDs.dropFirst(before.count)) == ["H", "G"])
        #expect(graphG?.isStale == false)
    }

    /// T-17: a hidden Source page goes stale on a write and reloads when shown again.
    @Test func hiddenSourcePageReloadsOnlyWhenRevisited() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        session.apply(location: .sourcePage(sourceId: "s1"))
        await session.settleWrites()
        session.apply(location: .sectionRoot(.persons))
        await session.settleWrites()
        let page: QueryHandle<CatalogSourceWorkspace>? = session.queryHandle(
            .sourceWorkspace(project: session.projectKey, sourceId: "s1")
        )
        let callsBefore = store.getSourceWorkspaceCalls

        session.apply(.mutatedSourceWorkspace(sourceId: "s1"))
        await session.settleWrites()
        #expect(store.getSourceWorkspaceCalls == callsBefore)
        #expect(page?.isStale == true)

        session.apply(location: .sourcePage(sourceId: "s1"))
        await session.settleWrites()
        #expect(store.getSourceWorkspaceCalls == callsBefore + 1)
        #expect(page?.isStale == false)
    }

    /// T-7b: a failed progress re-read reloads the whole map.
    @Test func progressReReadFailureReloadsTheMap() async {
        struct Boom: Error {}
        let store = FakeStore()
        seedStore(store)
        store.graphProgressByGraph["g-1"] = EvidenceGraphProgress(
            graphId: "g-1", subjectCount: 1, observationCount: 1
        )
        let session = makeSession(store: store)
        let progressHandle: QueryHandle<[String: EvidenceGraphProgress]> = session.query(
            CatalogQueryKey.evidenceGraphProgress(project: session.projectKey)
        )
        await waitForQuery(progressHandle)
        let listCalls = store.listEvidenceGraphProgressCalls

        store.getEvidenceGraphProgressError = Boom()
        session.apply(CatalogWriteEffects(
            reads: [CatalogWriteEffectsRead(read: .evidenceGraphProgress, ids: ["g-1"])]
        ))
        await session.settleWrites()
        #expect(store.listEvidenceGraphProgressCalls == listCalls + 1)
        #expect(!progressHandle.isFetching)
    }

    // MARK: Graph list re-reads (S14-11)

    private func graphRead(_ sourceIDs: String...) -> CatalogWriteEffects {
        CatalogWriteEffects(reads: [CatalogWriteEffectsRead(read: .evidenceGraphs, ids: sourceIDs)])
    }

    /// A session whose graph list holds `rows` (set without a load) and whose
    /// place shows it when `visible`.
    private func graphListSession(
        store: FakeStore,
        rows: [CatalogEvidenceGraph],
        visible: Bool
    ) -> (WorkspaceSession, QueryHandle<[CatalogEvidenceGraph]>) {
        let session = makeSession(store: store)
        session.setQueryValue(session.evidenceGraphsKey, value: rows)
        if visible {
            session.apply(location: .sourcePage(sourceId: "S"))
        }
        let handle: QueryHandle<[CatalogEvidenceGraph]> = session.query(session.evidenceGraphsKey)
        return (session, handle)
    }

    /// T-6: a graph write names one Source, so only that Source's graphs are
    /// asked for and merged; the other Source's rows are untouched.
    @Test func graphListMergesOneSourcesReRead() async {
        let store = FakeStore()
        let (session, handle) = graphListSession(
            store: store,
            rows: [
                evidenceGraph("s-default", sourceID: "S", name: "Default"),
                evidenceGraph("s-jones", sourceID: "S", name: "Jones"),
                evidenceGraph("t-default", sourceID: "T", name: "Default"),
            ],
            visible: true
        )
        store.evidenceGraphsByProject[projectDir] = [
            evidenceGraph("s-default", sourceID: "S", name: "Default"),
            evidenceGraph("s-jones", sourceID: "S", name: "Jones", artifactIDs: ["page2"]),
            evidenceGraph("s-smith", sourceID: "S", name: "Smith"),
            evidenceGraph("t-default", sourceID: "T", name: "Default", artifactIDs: ["other"]),
        ]
        session.apply(graphRead("S"))
        #expect(handle.isFetching)
        await session.settleWrites()
        #expect(!handle.isFetching)
        #expect(store.listEvidenceGraphsSourceIDs == ["S"])
        #expect(session.evidenceGraphs(sourceID: "S")?.map(\.id) == ["s-default", "s-jones", "s-smith"])
        #expect(session.evidenceGraph(id: "s-jones")?.artifactIDs == ["page2"])
        #expect(session.evidenceGraphs(sourceID: "T") == [evidenceGraph("t-default", sourceID: "T", name: "Default")])
    }

    /// F-1: a merged re-read of one Source splices the index; it does not
    /// rebuild the maps of every other Source.
    @Test func graphListMergeSplicesTheIndex() async {
        let store = FakeStore()
        let (session, _) = graphListSession(
            store: store,
            rows: [
                evidenceGraph("s-default", sourceID: "S", name: "Default"),
                evidenceGraph("s-jones", sourceID: "S", name: "Jones"),
                evidenceGraph("t-default", sourceID: "T", name: "Default", artifactIDs: ["t-page"]),
            ],
            visible: true
        )
        #expect(session.evidenceGraph(id: "s-jones") != nil)
        let builds = session.evidenceGraphIndexBuildCount
        store.evidenceGraphsByProject[projectDir] = [
            evidenceGraph("s-default", sourceID: "S", name: "Default"),
            evidenceGraph("s-smith", sourceID: "S", name: "Smith", artifactIDs: ["s-page"]),
            evidenceGraph("s-wyatt", sourceID: "S", name: "Wyatt"),
            evidenceGraph("t-default", sourceID: "T", name: "Default", artifactIDs: ["t-page"]),
        ]
        session.apply(graphRead("S"))
        await session.settleWrites()
        #expect(session.evidenceGraphs(sourceID: "S")?.map(\.id) == ["s-default", "s-smith", "s-wyatt"])
        #expect(session.evidenceGraph(id: "s-smith") != nil)
        #expect(session.evidenceGraph(id: "s-jones") == nil)
        #expect(session.evidenceGraphs(sourceID: "T")?.map(\.id) == ["t-default"])
        #expect(session.artifactIDsInNoGraph(sourceID: "T", artifactIDs: ["t-page", "x"]) == ["x"])
        #expect(session.artifactIDsInNoGraph(sourceID: "S", artifactIDs: ["s-page", "x"]) == ["x"])
        #expect(session.evidenceGraphIndexBuildCount == builds)
    }

    /// T-7 (a): while the re-read waits the list reads as refetching, and a
    /// waiter on `readyValue` gets the merged rows.
    @Test func graphListPartialReReadSetsFetching() async {
        let store = FakeStore()
        let (session, handle) = graphListSession(
            store: store,
            rows: [evidenceGraph("s-default", sourceID: "S", name: "Default")],
            visible: true
        )
        store.evidenceGraphsByProject[projectDir] = [
            evidenceGraph("s-default", sourceID: "S", name: "Default"),
            evidenceGraph("s-new", sourceID: "S", name: "New"),
        ]
        store.listEvidenceGraphsHold.isOn = true
        session.apply(graphRead("S"))
        await store.listEvidenceGraphsHold.untilSuspended(1)
        #expect(handle.isFetching)
        if case .unknown = session.evidenceGraphPresence(id: "s-new") {} else {
            Issue.record("expected .unknown while the re-read runs")
        }
        #expect(session.artifactIDsInNoGraph(sourceID: "S", artifactIDs: ["a"]) == nil)

        let returned = Flag()
        let waiter = Task { @MainActor in
            let rows: [CatalogEvidenceGraph]? = await session.readyValue(session.evidenceGraphsKey)
            returned.isSet = true
            return rows
        }
        await Task.yield()
        #expect(!returned.isSet)
        store.listEvidenceGraphsHold.release()
        let rows = await waiter.value
        #expect(rows?.map(\.id) == ["s-default", "s-new"])
        #expect(!handle.isFetching)
    }

    /// T-7 (b): a failed re-read reloads the whole list through the key's policy.
    @Test func graphListPartialReReadFailureReloadsTheList() async {
        struct Boom: Error {}
        let store = FakeStore()
        let (session, handle) = graphListSession(
            store: store,
            rows: [evidenceGraph("s-default", sourceID: "S", name: "Default")],
            visible: true
        )
        store.listEvidenceGraphsError = Boom()
        session.apply(graphRead("S"))
        await session.settleWrites()
        #expect(store.listEvidenceGraphsSourceIDs.count == 2)
        #expect(store.listEvidenceGraphsSourceIDs.first == .some("S"))
        #expect(store.listEvidenceGraphsSourceIDs.last == .some(nil))
        #expect(handle.status == .error)
        #expect(handle.value?.map(\.id) == ["s-default"])
        #expect(!handle.isFetching)
    }

    /// T-7 (c): a visible list whose first load is in flight restarts that load
    /// instead of re-reading one Source.
    @Test func graphListFirstLoadInFlightRestartsWhenVisible() async {
        let store = FakeStore()
        store.listEvidenceGraphsHold.isOn = true
        let session = makeSession(store: store)
        session.apply(location: .sourcePage(sourceId: "S"))
        await store.listEvidenceGraphsHold.untilSuspended(1)

        session.apply(graphRead("S"))
        await store.listEvidenceGraphsHold.untilSuspended(2)
        store.listEvidenceGraphsHold.isOn = false
        store.listEvidenceGraphsHold.release()
        store.listEvidenceGraphsHold.release()
        await session.settleWrites()
        #expect(store.listEvidenceGraphsSourceIDs == [nil, nil])
    }

    /// T-7 (d): the same with the list hidden: no new call, and the list is
    /// stale once the first load lands.
    @Test func graphListFirstLoadInFlightGoesStaleWhenHidden() async {
        let store = FakeStore()
        store.listEvidenceGraphsHold.isOn = true
        let session = makeSession(store: store)
        let handle: QueryHandle<[CatalogEvidenceGraph]> = session.query(session.evidenceGraphsKey)
        await store.listEvidenceGraphsHold.untilSuspended(1)

        session.apply(graphRead("S"))
        #expect(handle.isStale)
        store.listEvidenceGraphsHold.isOn = false
        store.listEvidenceGraphsHold.release()
        await session.settleWrites()
        #expect(store.listEvidenceGraphsSourceIDs == [nil])
        #expect(handle.isStale)
        #expect(!handle.isSettled)
    }

    /// T-7 (e): overlapping re-reads of two Sources keep `isFetching` true
    /// until the last one ends, and both merge.
    @Test func overlappingGraphReReadsKeepFetchingUntilTheLastEnds() async {
        let store = FakeStore()
        let (session, handle) = graphListSession(
            store: store,
            rows: [
                evidenceGraph("s-default", sourceID: "S", name: "Default"),
                evidenceGraph("t-default", sourceID: "T", name: "Default"),
            ],
            visible: true
        )
        store.evidenceGraphsByProject[projectDir] = [
            evidenceGraph("s-default", sourceID: "S", name: "Default"),
            evidenceGraph("s-new", sourceID: "S", name: "New"),
            evidenceGraph("t-default", sourceID: "T", name: "Default"),
            evidenceGraph("t-new", sourceID: "T", name: "New"),
        ]
        store.listEvidenceGraphsHold.isOn = true
        session.apply(graphRead("S"))
        session.apply(graphRead("T"))
        await store.listEvidenceGraphsHold.untilSuspended(2)

        store.listEvidenceGraphsHold.release()
        #expect(await waitUntil { handle.value?.count == 3 })
        #expect(handle.isFetching)
        store.listEvidenceGraphsHold.release()
        await session.settleWrites()
        #expect(!handle.isFetching)
        #expect(session.evidenceGraphs(sourceID: "S")?.map(\.id) == ["s-default", "s-new"])
        #expect(session.evidenceGraphs(sourceID: "T")?.map(\.id) == ["t-default", "t-new"])
    }

    /// AC-1.9: a hidden graph list merges the read's Source too: it re-reads it, is not stale,
    /// and a `query` starts no load.
    @Test func hiddenGraphListMergesOnRead() async {
        let store = FakeStore()
        let (session, handle) = graphListSession(
            store: store,
            rows: [evidenceGraph("s-default", sourceID: "S", name: "Default")],
            visible: false
        )
        store.evidenceGraphsByProject[projectDir] = [
            evidenceGraph("s-default", sourceID: "S", name: "Default"),
            evidenceGraph("s-new", sourceID: "S", name: "New"),
        ]
        session.apply(graphRead("S"))
        await session.settleWrites()
        #expect(store.listEvidenceGraphsSourceIDs == ["S"])
        #expect(handle.value?.map(\.id) == ["s-default", "s-new"])
        #expect(!handle.isStale)

        let again: QueryHandle<[CatalogEvidenceGraph]> = session.query(session.evidenceGraphsKey)
        #expect(!again.isFetching)
        await session.settleWrites()
        #expect(store.listEvidenceGraphsSourceIDs == ["S"])
    }

    /// T-13: deleting a Source drops its graphs through the same re-read.
    @Test func deletedSourceDropsItsGraphs() async {
        let store = FakeStore()
        let (session, handle) = graphListSession(
            store: store,
            rows: [
                evidenceGraph("s-default", sourceID: "S", name: "Default"),
                evidenceGraph("t-default", sourceID: "T", name: "Default"),
            ],
            visible: true
        )
        store.evidenceGraphsByProject[projectDir] = [evidenceGraph("t-default", sourceID: "T", name: "Default")]
        session.apply(
            CatalogWriteEffects(
                evidenceGraphs: ["s-default"],
                reads: [CatalogWriteEffectsRead(read: .evidenceGraphs, ids: ["S"])],
                lists: [.counts]
            ),
            .deletedSource(id: "S")
        )
        await session.settleWrites()
        #expect(store.listEvidenceGraphsSourceIDs == ["S"])
        #expect(handle.value?.map(\.id) == ["t-default"])
        #expect(session.evidenceGraphs(sourceID: "S")?.isEmpty == true)
    }
}

/// A flag a test task sets once it returns.
@MainActor
private final class Flag {
    var isSet = false
}

/// One-shot gate so concurrent loaders block until tests observe stale data.
@MainActor
private final class Gate {
    private var continuations: [CheckedContinuation<Void, Never>] = []
    private var isOpen = false

    func waitForOpen() async {
        if isOpen { return }
        await withCheckedContinuation { continuation in
            if isOpen {
                continuation.resume()
            } else {
                continuations.append(continuation)
            }
        }
    }

    func open() {
        isOpen = true
        for continuation in continuations {
            continuation.resume()
        }
        continuations.removeAll()
    }
}
