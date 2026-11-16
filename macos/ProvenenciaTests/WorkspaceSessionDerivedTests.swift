import Foundation
import Testing
@testable import Provenencia

/// `WorkspaceSession.derived`: a value built once per change of the reads it
/// names and of its `extra`. The builds are counters, not real content.
@Suite(.serialized)
@MainActor
struct WorkspaceSessionDerivedTests {
    private let projectDir = "/tmp/workspace-session-derived.provenencia"

    private func makeSession(store: FakeStore = FakeStore()) -> WorkspaceSession {
        WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)
    }

    private func detailKey(_ session: WorkspaceSession, _ id: String) -> CatalogQueryKey {
        .conclusionDetail(project: session.projectKey, entityId: id)
    }

    /// T-1 (AC-1.1, D-1): three reads of one value build once.
    @Test func aValueBuildsOncePerInputRevision() {
        let session = makeSession()
        let key = session.sourceTypesKey
        session.setQueryValue(key, value: [CatalogSourceType]())
        var builds = 0
        for _ in 0..<3 {
            let value = session.derived(.visibleSources, inputs: [.key(key)]) {
                builds += 1
                return builds
            }
            #expect(value == 1)
        }
        #expect(builds == 1)
        #expect(session.derivedBuildCount(.visibleSources) == 1)
    }

    /// T-2 (AC-1.2, AC-1.3, AC-1.4, D-5): a write that refreshes an input builds
    /// again, one that refreshes another key does not, and a new `extra` builds.
    @Test func anApplyThatRefreshesAnInputBuildsAgain() async {
        let store = FakeStore()
        store.seededConclusionDetails = ["e1": catalogConclusionDetail("e1"), "e2": catalogConclusionDetail("e2")]
        let session = makeSession(store: store)
        let key1 = detailKey(session, "e1")
        let id = DerivedValueID.conclusionContent(key1, ObjectIdentifier(Int.self))
        session.apply(location: .personDetail(entityId: "e1", ref: "PER-e1", title: nil))
        await session.settleWrites()
        session.setQueryValue(detailKey(session, "e2"), value: catalogConclusionDetail("e2"))

        func read(extra: Int) -> Int {
            session.derived(id, inputs: [.key(key1)], extra: extra) { extra }
        }
        _ = read(extra: 0)
        _ = read(extra: 0)
        _ = read(extra: 0)
        #expect(session.derivedBuildCount(id) == 1)

        session.apply(CatalogWriteEffects(handles: ["e1"]))
        await session.settleWrites()
        _ = read(extra: 0)
        #expect(session.derivedBuildCount(id) == 2)

        let otherKey = detailKey(session, "e2")
        let otherRevision = session.inputRevision(otherKey)
        session.setQueryValue(otherKey, value: catalogConclusionDetail("e2"))
        #expect(session.inputRevision(otherKey) != otherRevision)
        _ = read(extra: 0)
        #expect(session.derivedBuildCount(id) == 2)

        _ = read(extra: 1)
        #expect(session.derivedBuildCount(id) == 3)
        _ = read(extra: 1)
        #expect(session.derivedBuildCount(id) == 3)
    }

    /// T-3 (AC-1.5, D-3, D-6): a deleted handle's hidden key drops the entry and
    /// the entry built from it; the next read builds.
    @Test func aDeletedInputDropsTheValue() {
        let session = makeSession()
        let key = detailKey(session, "e1")
        let content = DerivedValueID.conclusionContent(key, ObjectIdentifier(Int.self))
        let text = DerivedValueID.evidenceGraphText(graphID: "g1")
        session.setQueryValue(key, value: catalogConclusionDetail("e1"))
        session.apply(location: .sectionRoot(.persons))
        _ = session.derived(content, inputs: [.key(key)]) { 1 }
        _ = session.derived(text, inputs: [.derived(content)]) {
            session.derived(content, inputs: [.key(key)]) { 1 }
        }
        #expect(session.derivedEntries[content] != nil && session.derivedEntries[text] != nil)

        session.apply(CatalogWriteEffects(deleted: [CatalogWriteEffectsDeleted(entity: .handle, ids: ["e1"])]))
        #expect(session.derivedEntries[content] == nil)
        #expect(session.derivedEntries[text] == nil)

        session.setQueryValue(key, value: catalogConclusionDetail("e1"))
        _ = session.derived(content, inputs: [.key(key)]) { 1 }
        #expect(session.derivedBuildCount(content) == 2)
    }

    /// T-4 (D-11): a carry stores the changed value with no build, but only when
    /// the carried key alone moved.
    @Test func aCarryMovesTheValueOnlyWhenItsKeyAloneMoved() {
        let session = makeSession()
        let keyA = session.evidenceGraphsKey
        let keyB = session.sourceTypesKey
        let id = DerivedValueID.evidenceGraphIndex
        session.setQueryValue(keyA, value: [CatalogEvidenceGraph]())
        session.setQueryValue(keyB, value: [CatalogSourceType]())
        func read() -> Int {
            session.derived(id, inputs: [.key(keyA), .key(keyB)]) { 10 }
        }
        #expect(read() == 10)

        var previous = session.inputRevision(keyA)
        session.setQueryValue(keyA, value: [CatalogEvidenceGraph]())
        session.carryDerived(id, across: keyA, from: previous) { (old: Int) in old + 5 }
        #expect(read() == 15)
        #expect(session.derivedBuildCount(id) == 1)

        previous = session.inputRevision(keyA)
        session.setQueryValue(keyA, value: [CatalogEvidenceGraph]())
        session.setQueryValue(keyB, value: [CatalogSourceType]())
        session.carryDerived(id, across: keyA, from: previous) { (old: Int) in old + 5 }
        #expect(read() == 10)
        #expect(session.derivedBuildCount(id) == 2)
    }

    /// T-5 (AC-1.5, D-6): the hidden-entity cap drops the evicted entity's
    /// entry and what is built from it.
    @Test func theHiddenEntityCapDropsValuesAndTheirDependants() async {
        let store = FakeStore()
        for index in 0...51 {
            store.seededConclusionDetails["e\(index)"] = catalogConclusionDetail("e\(index)")
        }
        let session = makeSession(store: store)
        let key0 = detailKey(session, "e0")
        let content = DerivedValueID.conclusionContent(key0, ObjectIdentifier(Int.self))
        let text = DerivedValueID.evidenceGraphText(graphID: "g1")
        for index in 0...51 {
            session.apply(location: .personDetail(entityId: "e\(index)", ref: "PER-e\(index)", title: nil))
            await session.settleWrites()
            if index == 0 {
                _ = session.derived(content, inputs: [.key(key0)]) { 1 }
                _ = session.derived(text, inputs: [.derived(content)]) {
                    session.derived(content, inputs: [.key(key0)]) { 1 }
                }
                #expect(session.derivedEntries[content] != nil)
                #expect(session.derivedEntries[text] != nil)
            }
        }
        #expect(session.derivedEntries[content] == nil)
        #expect(session.derivedEntries[text] == nil)
    }

    /// T-6 (AC-1.6, D-2): a value that reads another follows the other's inputs.
    @Test func aDerivedInputFollowsItsOwnInputs() {
        let session = makeSession()
        let graphKey = CatalogQueryKey.evidenceGraph(project: session.projectKey, graphId: "g1")
        let snapshot = DerivedValueID.evidenceGraphSnapshot(graphID: "g1")
        let text = DerivedValueID.evidenceGraphText(graphID: "g1")
        session.setQueryValue(graphKey, value: EvidenceGraphRows(graphId: "g1"))
        func readText() -> Int {
            session.derived(text, inputs: [.derived(snapshot)]) {
                session.derived(snapshot, inputs: [.key(graphKey)]) { 7 }
            }
        }
        _ = readText()
        _ = readText()
        #expect(session.derivedBuildCount(snapshot) == 1)
        #expect(session.derivedBuildCount(text) == 1)

        session.setQueryValue(graphKey, value: EvidenceGraphRows(graphId: "g1"))
        _ = readText()
        #expect(session.derivedBuildCount(snapshot) == 2)
        #expect(session.derivedBuildCount(text) == 2)
    }

    /// F-1 (SEC-1): one key opened as two page kinds holds one value per
    /// content type, each built once.
    @Test func oneKeyHoldsOneValuePerContentType() {
        let session = makeSession()
        let key = detailKey(session, "e1")
        session.setQueryValue(key, value: catalogConclusionDetail("e1"))
        var builds = 0
        for _ in 0..<2 {
            let text = session.conclusionContent(key, inputs: [key], extra: 0, value: 1) { _, _ in
                builds += 1
                return "a"
            }
            let number = session.conclusionContent(key, inputs: [key], extra: 0, value: 1) { _, _ in
                builds += 1
                return 7
            }
            #expect(text == "a")
            #expect(number == 7)
        }
        #expect(builds == 2)
    }

    /// F-2 (CON-1, AC-1.7, D-10): a build that reads a key its inputs do not name
    /// is recorded under its id.
    @Test func aBuildThatReadsAnUndeclaredKeyIsReported() {
        let session = makeSession()
        session.derivedAssertsUndeclaredReads = false
        let declared = session.sourceTypesKey
        let undeclared = session.evidenceGraphsKey
        session.setQueryValue(declared, value: [CatalogSourceType]())
        session.setQueryValue(undeclared, value: [CatalogEvidenceGraph]())
        _ = session.derived(.visibleSources, inputs: [.key(declared)]) {
            let sourceTypes: QueryHandle<[CatalogSourceType]>? = session.queryHandle(declared)
            let graphs: QueryHandle<[CatalogEvidenceGraph]>? = session.queryHandle(undeclared)
            return (sourceTypes?.value?.count ?? 0) + (graphs?.value?.count ?? 0)
        }
        #expect(session.derivedUndeclaredReads[.visibleSources] == [undeclared])
    }
}
