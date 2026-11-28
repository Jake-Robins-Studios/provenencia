import Foundation
import Testing
@testable import Provenencia

@Suite
@MainActor
struct CatalogSessionStoreTests {
    private let projectDir = "/tmp/session.provenencia"

    @Test func workspaceNavCountsMarksSessionHeld() async throws {
        let store = FakeStore()
        _ = try await store.workspaceNavCounts(projectDir: projectDir)
        #expect(store.heldCatalogProjectDir == projectDir)
    }

    @Test func listSourcesMarksSessionHeld() async throws {
        let store = FakeStore()
        _ = try await store.listSources(projectDir: projectDir)
        #expect(store.heldCatalogProjectDir == projectDir)
    }

    @Test func provenanceRecordsAnswersTheAskedRequest() async throws {
        let store = FakeStore()
        let asked = CatalogProvenanceRequest.fields([CatalogProvenancePair(ownerID: "P", propertyID: "p-name")])
        store.provenanceRecordsReplies = [
            asked: CatalogProvenanceSheetRead(
                owners: [CatalogOwnerField(entity: CatalogCanonicalEntity(id: "P", ref: "PER-1", subjectTypeID: "t", label: "James"), field: sampleField())],
                citations: ["a": renderedCitation("a", full: "")]
            )
        ]
        let reply = try await store.getProvenanceRecords(projectDir: projectDir, request: asked)
        #expect(reply.owners.map(\.entity.id) == ["P"])
        #expect(reply.citations.keys.sorted() == ["a"])
        #expect(store.provenanceRecordsCalls == [asked])
        let unlisted = try await store.getProvenanceRecords(projectDir: projectDir, request: .derived(personID: "P", kind: .birthDate))
        #expect(unlisted.owners.isEmpty && unlisted.citations.isEmpty && unlisted.inputs == .init())
        #expect(store.provenanceRecordsCalls.count == 2)
    }

    private func sampleField() -> CatalogConclusionField {
        CatalogConclusionField(
            propertyID: "p-name", propertyKey: "name", label: "Name", valueType: .name,
            state: .single, values: [], outcomes: []
        )
    }

    @Test func closeCatalogSessionClearsHeldAndRecordsDir() async throws {
        let store = FakeStore()
        _ = try await store.workspaceNavCounts(projectDir: projectDir)
        #expect(store.heldCatalogProjectDir == projectDir)

        try await store.closeCatalogSession(projectDir: projectDir)
        #expect(store.lastClosedCatalogProjectDir == projectDir)
        #expect(store.heldCatalogProjectDir == nil)
    }

    @Test func closeOtherProjectLeavesHeldUntouched() async throws {
        let store = FakeStore()
        _ = try await store.workspaceNavCounts(projectDir: projectDir)
        try await store.closeCatalogSession(projectDir: "/tmp/other.provenencia")
        #expect(store.lastClosedCatalogProjectDir == "/tmp/other.provenencia")
        #expect(store.heldCatalogProjectDir == projectDir)
    }

    @Test func signOutClearsHeldSession() async throws {
        let store = FakeStore(identity: InstallIdentity(userID: "u", displayName: "Jake", ref: "USR-1"))
        store.activeProjectDir = projectDir
        _ = try await store.listSources(projectDir: projectDir)
        try await store.signOut(identityDir: "/tmp/ident")
        #expect(store.heldCatalogProjectDir == nil)
        #expect(store.identity == nil)
    }

    @Test func refreshAllHoldsSessionViaStore() async {
        let store = FakeStore()
        let counts = CatalogCounts(projectDir: projectDir, store: store, toasts: PVToastList())
        await counts.refreshAll()
        #expect(store.heldCatalogProjectDir == projectDir)
    }

    @Test func concurrentCatalogReadsMarkSessionHeld() async throws {
        let store = FakeStore()
        store.sourcesByProject[projectDir] = [
            CatalogSource(id: "1", ref: "SRC-1", sourceTypeID: "", title: "A", description: ""),
        ]
        store.sourceTypesByProject[projectDir] = [
            CatalogSourceType(id: "1", key: "book", origin: "provenencia", label: "Book", description: ""),
        ]
        store.fieldsByProject[projectDir] = [
            CatalogMetadataField(id: "1", key: "date", origin: "user", label: "Date", dataType: "date", description: ""),
        ]

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                _ = try await store.workspaceNavCounts(projectDir: projectDir)
            }
            group.addTask {
                _ = try await store.listSources(projectDir: projectDir)
            }
            group.addTask {
                _ = try await store.listSourceTypes(projectDir: projectDir)
            }
            group.addTask {
                _ = try await store.listMetadataFields(projectDir: projectDir)
            }
            try await group.waitForAll()
        }

        #expect(store.heldCatalogProjectDir == projectDir)

        try await store.closeCatalogSession(projectDir: projectDir)
        #expect(store.heldCatalogProjectDir == nil)
        #expect(store.lastClosedCatalogProjectDir == projectDir)
    }

    @Test func getSourceWorkspaceMarksSessionHeld() async throws {
        let store = FakeStore()
        _ = try await store.getSourceWorkspace(projectDir: projectDir, sourceID: "missing")
        #expect(store.heldCatalogProjectDir == projectDir)
    }
}
