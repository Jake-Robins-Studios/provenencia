import Foundation
import SwiftUI
import Testing
@testable import Provenencia

@Suite
@MainActor
struct OmnibarResultsModelTests {
    private let projectDir = "/tmp/omnibar-results.provenencia"

    @Test func shortQueryDoesNotPresent() async {
        let store = FakeStore()
        store.sourcesByProject[projectDir] = [
            CatalogSource(id: "s1", ref: "SRC-AAAAA", sourceTypeID: "", title: "Ilminster", description: ""),
        ]
        let model = OmnibarResultsModel()
        model.search.query = "I"
        model.scheduleSearch(
            projectDir: projectDir,
            location: .sectionRoot(.sources),
            store: store
        )
        try? await Task.sleep(nanoseconds: 250_000_000)
        #expect(!model.isPresented)
        #expect(model.search.hits.isEmpty)
    }

    @Test func debouncedSearchReturnsHits() async {
        let store = FakeStore()
        store.seededSearchHits = [
            CatalogSearchHit.fixture(
                kind: "source", id: "s1", ref: "SRC-ILMIN", title: "Ilminster parish", subtitle: "Parish",
                matchReason: "title", location: WorkspaceLocation(section: .sources, sourceId: "s1"),
                iconKey: "type_certificate"
            ),
        ]
        let model = OmnibarResultsModel()
        model.search.query = "Ilminster"
        model.scheduleSearch(
            projectDir: projectDir,
            location: .sectionRoot(.sources),
            store: store
        )
        await waitForSearch(model.search)
        #expect(model.isPresented)
        #expect(model.search.hits.first?.id == "s1")
        #expect(model.search.hits.first?.subtitle == "Parish")
        #expect(model.search.hits.first?.iconKey == "type_certificate")
    }

    @Test func clearAfterNavigateResetsQuery() async {
        let model = OmnibarResultsModel()
        model.search.query = "abc"
        model.search.hasSearched = true
        model.search.hits = [
            CatalogSearchHit.fixture(
                kind: "source",
                id: "s1",
                ref: "SRC-AAAAA",
                title: "A",
                subtitle: "",
                matchReason: "title",
                location: .sectionRoot(.sources)
            ),
        ]
        model.clearAfterNavigate()
        #expect(model.search.query.isEmpty)
        #expect(!model.isPresented)
        #expect(model.search.hits.isEmpty)
    }

    @Test func activateCommitsNavigationAndClearsResults() {
        let hit = CatalogSearchHit.fixture(
            kind: "source",
            id: "s1",
            ref: "SRC-AAAAA",
            title: "Deed",
            subtitle: "Photograph",
            matchReason: "title",
            location: WorkspaceLocation(section: .sources, sourceId: "s1", ref: "SRC-AAAAA", title: "Deed")
        )
        let navigation = WorkspaceNavigation()
        let model = OmnibarResultsModel()
        model.search.query = "Deed"
        model.search.hits = [hit]
        model.search.hasSearched = true

        model.activate(hit, navigation: navigation)

        #expect(navigation.currentLocation.sourceId == "s1")
        #expect(navigation.selectedSection == .sources)
        #expect(model.search.query.isEmpty)
        #expect(model.search.hits.isEmpty)
        #expect(!model.search.hasSearched)
    }

    @Test func activateFieldHitFromSearch() async {
        let store = FakeStore()
        let projectDir = "/tmp/omnibar-activate.provenencia"
        store.seededSearchHits = [
            CatalogSearchHit.fixture(
                kind: "metadata_field", id: "f9", ref: "", title: "Author", subtitle: "author",
                matchReason: "title", location: WorkspaceLocation(section: .metadata, fieldId: "f9", title: "Author")
            ),
        ]
        let model = OmnibarResultsModel()
        model.search.query = "Author"
        model.scheduleSearch(
            projectDir: projectDir,
            location: .sectionRoot(.metadata),
            store: store
        )
        await waitForSearch(model.search)
        guard let hit = model.search.hits.first(where: { $0.id == "f9" }) else {
            Issue.record("no f9 hit")
            return
        }

        let navigation = WorkspaceNavigation()
        model.activate(hit, navigation: navigation)

        #expect(navigation.currentLocation.fieldId == "f9")
        #expect(navigation.selectedSection == .metadata)
        #expect(model.search.query.isEmpty)
    }

    @Test func activateEvidenceGraphHitOpensTheGraph() async {
        let store = FakeStore()
        let projectDir = "/tmp/omnibar-graph.provenencia"
        let source = CatalogSource(
            id: "src-w3", ref: "SRC-W3CEN", sourceTypeID: "", title: "1881 Census, Ward 3", description: ""
        )
        let graph = CatalogEvidenceGraph(
            id: "g-jones", ref: "GPH-J0NES", sourceID: "src-w3", name: "Jones household",
            description: "", artifactIDs: []
        )
        store.seededSearchHits = [
            CatalogSearchHit.fixture(
                kind: "evidence_graph", id: "g-jones", ref: "GPH-J0NES", title: "Jones household",
                subtitle: "1881 Census, Ward 3", matchReason: "title",
                location: SourcesListNavigation.canvasLocation(for: source, graph: graph)
            ),
        ]
        let model = OmnibarResultsModel()
        model.search.query = "jones"
        model.scheduleSearch(projectDir: projectDir, location: .sectionRoot(.sources), store: store)
        await waitForSearch(model.search)
        guard let hit = model.search.hits.first(where: { $0.kind == "evidence_graph" }) else {
            Issue.record("no graph hit")
            return
        }

        let navigation = WorkspaceNavigation()
        model.activate(hit, navigation: navigation)

        #expect(navigation.currentLocation.graphId == "g-jones")
        #expect(navigation.currentLocation.sourceId == "src-w3")
        #expect(navigation.currentLocation.sourceSurface == .graph)
        #expect(navigation.selectedSection == .sources)
        #expect(model.search.query.isEmpty)
    }

    @Test func closePanelSetsUserDismissedWithoutClearingQuery() {
        let model = OmnibarResultsModel()
        model.search.query = "Ilminster"
        model.search.hasSearched = true
        model.search.isLoading = true
        model.closePanel()
        #expect(model.userDismissed)
        #expect(!model.isPresented)
        #expect(model.search.query == "Ilminster")
        #expect(!model.search.isLoading)
    }

    @Test func loadingPresentsBeforeHitsArrive() {
        let model = OmnibarResultsModel()
        model.search.query = "Il"
        model.search.isLoading = true
        #expect(model.isPresented)
        #expect(model.search.line == .searching)
    }

    @Test func aFailedSearchKeepsTheListOpen() async {
        let store = FakeStore()
        store.searchCatalogError = CoreInvokeError.coded(
            status: 1,
            code: "catalog.closed",
            kind: .user,
            params: []
        )
        let model = OmnibarResultsModel()
        model.search.query = "Ilminster"
        model.scheduleSearch(
            projectDir: projectDir,
            location: .sectionRoot(.sources),
            store: store
        )
        await waitForSearch(model.search)
        #expect(model.isPresented)
    }

    // MARK: Highlight and keys

    /// A model with hits a, b, c landed through a real search, so the first is highlighted.
    private func landed(query: String = "abc") async -> (OmnibarResultsModel, FakeStore) {
        let store = FakeStore()
        store.seededSearchHits = ["a", "b", "c"].map {
            CatalogSearchHit.fixture(
                id: $0, title: $0.uppercased(), location: WorkspaceLocation(section: .sources, sourceId: $0)
            )
        }
        let model = OmnibarResultsModel()
        model.search.query = query
        model.scheduleSearch(projectDir: projectDir, location: .sectionRoot(.sources), store: store)
        await waitForSearch(model.search)
        return (model, store)
    }

    @Test func resultsLandOnTheFirstHit() async {
        let (model, store) = await landed()
        #expect(model.highlightedHit?.id == "a")
        _ = model.handleKey(.downArrow, command: false) { _ in }
        _ = model.handleKey(.downArrow, command: false) { _ in }
        #expect(model.highlightedHit?.id == "c")
        model.search.query = "abcd"
        model.scheduleSearch(projectDir: projectDir, location: .sectionRoot(.sources), store: store)
        await waitForSearch(model.search)
        #expect(model.highlightedHit?.id == "a")
    }

    @Test func movementKeysMoveTheHighlight() async {
        let (model, _) = await landed()
        let steps: [(KeyEquivalent, Bool, String)] = [
            (.downArrow, false, "b"), (.end, false, "c"), (.home, false, "a"),
            (.pageDown, false, "c"), (.upArrow, true, "a"), (.upArrow, false, "a"),
        ]
        for (key, command, expected) in steps {
            let result = model.handleKey(key, command: command) { _ in }
            #expect(result == .handled)
            #expect(model.highlightedHit?.id == expected)
        }
    }

    @Test func keysPassWhileTheListIsClosed() async {
        let (model, _) = await landed()
        model.closePanel()
        let before = model.highlight.index
        var opened = false
        for key in [KeyEquivalent.downArrow, .return, .escape] {
            #expect(model.handleKey(key, command: false) { _ in opened = true } == .ignored)
        }
        #expect(model.highlight.index == before)
        #expect(!opened)
    }

    @Test func returnOpensTheHighlightedHitAndClears() async {
        for key in [KeyEquivalent.return, KeyEquivalent("\u{3}")] {
            let (model, _) = await landed()
            let navigation = WorkspaceNavigation()
            _ = model.handleKey(.downArrow, command: false) { _ in }
            let result = model.handleKey(key, command: false) { model.activate($0, navigation: navigation) }
            #expect(result == .handled)
            #expect(navigation.currentLocation.sourceId == "b")
            #expect(model.search.query.isEmpty)
            #expect(!model.isPresented)
        }
    }

    @Test func returnWithNoHitIsTakenAndOpensNothing() {
        let model = OmnibarResultsModel()
        model.search.query = "il"
        model.search.isLoading = true
        var opened = false
        #expect(model.handleKey(.return, command: false) { _ in opened = true } == .handled)
        #expect(!opened)
        #expect(model.search.query == "il")
    }

    @Test func escapeClosesAndKeepsTheQuery() async {
        let (model, _) = await landed()
        #expect(model.handleKey(.escape, command: false) { _ in } == .handled)
        #expect(!model.isPresented)
        #expect(model.search.query == "abc")
        #expect(model.userDismissed)
    }

    @Test func hoverMovesTheHighlight() async {
        let (model, _) = await landed()
        model.hover(at: 2)
        #expect(model.highlightedHit?.id == "c")
        model.hover(at: 9)
        #expect(model.highlightedHit?.id == "c")
    }

    @Test func dismissAndAShortQueryClearTheHighlight() async {
        let (model, store) = await landed()
        model.dismiss()
        #expect(model.highlight.index == -1)
        #expect(model.highlightedHit == nil)
        model.search.query = "abc"
        model.scheduleSearch(projectDir: projectDir, location: .sectionRoot(.sources), store: store)
        await waitForSearch(model.search)
        #expect(model.highlight.index == 0)
        model.search.query = "I"
        model.scheduleSearch(projectDir: projectDir, location: .sectionRoot(.sources), store: store)
        #expect(model.highlight.index == -1)
    }
}
