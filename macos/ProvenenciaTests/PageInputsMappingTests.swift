import Testing
@testable import Provenencia

/// S16-24: the engine's page-read inputs decode onto each value as sets of ids.
struct PageInputsMappingTests {
    @Test func decodesEachListAsASet() {
        var wire = Provenencia_Engine_V1_PageInputs()
        wire.handles = ["h1", "h2", "h1"]
        wire.evidenceGraphs = ["g1"]
        wire.sources = ["s1"]
        #expect(
            GoStore.mapPageInputs(wire)
                == CatalogPageInputs(handles: ["h1", "h2"], evidenceGraphs: ["g1"], sources: ["s1"])
        )
    }

    @Test func anEmptyMessageDecodesToNoInputs() {
        #expect(GoStore.mapPageInputs(Provenencia_Engine_V1_PageInputs()) == CatalogPageInputs())
    }

    @Test func recordLinksCarryTheirInputs() {
        var resp = Provenencia_Engine_V1_GetPersonRecordLinksResponse()
        resp.inputs.handles = ["per-1"]
        resp.inputs.evidenceGraphs = ["g1", "g2"]
        resp.inputs.sources = ["s1"]
        let links = GoStore.mapPersonRecordLinks(resp)
        #expect(links.inputs == CatalogPageInputs(handles: ["per-1"], evidenceGraphs: ["g1", "g2"], sources: ["s1"]))
    }

    @Test func aFakeStoreValueCarriesNoInputs() async throws {
        let store = FakeStore()
        store.seededPersonClaims["per-1"] = []
        let claims = try await store.listPersonClaims(projectDir: "/tmp/p", entityID: "per-1")
        #expect(claims.inputs == CatalogPageInputs())
    }
}
