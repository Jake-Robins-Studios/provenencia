import Foundation
import SwiftUI
import Testing
@testable import Provenencia

/// The Sources list's outline: its rows, its open set, its keys, its menus and its summary. Pure
/// functions are tested without a view; the model's build count at Scale uses a `FakeStore`.
@Suite
@MainActor
struct SourcesOutlineTests {
    private let projectDir = "/tmp/outline.provenencia"
    private let userID = "00000000-0000-7000-8000-000000000001"

    private func source(_ id: String, title: String = "Census", artifact: Bool = true) -> CatalogSource {
        CatalogSource(
            id: id, ref: "SRC-\(id.uppercased())", sourceTypeID: "t1", title: title, description: "",
            hasArtifact: artifact
        )
    }

    private func graph(
        _ id: String, source: String, name: String = "Default", linked: Bool = true
    ) -> CatalogEvidenceGraph {
        CatalogEvidenceGraph(
            id: id, ref: "GPH-\(id.uppercased())", sourceID: source, name: name, description: "",
            artifactIDs: linked ? ["a-\(id)"] : []
        )
    }

    private var s1: CatalogSource { source("s1") }
    private var s2: CatalogSource { source("s2") }
    private var s3: CatalogSource { source("s3", artifact: false) }
    private var g1a: CatalogEvidenceGraph { graph("g1a", source: "s1", name: "Default") }
    private var g1b: CatalogEvidenceGraph { graph("g1b", source: "s1", name: "Jones household", linked: false) }
    private var g2: CatalogEvidenceGraph { graph("g2", source: "s2") }

    private func reads(_ table: [String: QueryRead<[CatalogEvidenceGraph]>]) -> (String) -> QueryRead<[CatalogEvidenceGraph]> {
        { table[$0] ?? .loading }
    }

    private func outline(expanded: Set<String>) -> SourcesOutline {
        SourcesOutline(
            sources: [s1, s2, s3],
            graphs: reads(["s1": .loaded([g1a, g1b]), "s2": .loaded([g2])]),
            expanded: expanded
        )
    }

    private func disclosure(_ outline: SourcesOutline, _ id: String) -> SourcesDisclosure? {
        outline.row(id: id)?.disclosure
    }

    @Test func rowsFollowTheExpandedSet() {
        let outline = outline(expanded: ["s1", "s9"])
        #expect(outline.rows.map(\.id) == ["s1", "g1a", "g1b", "s2", "s3"])
        #expect(disclosure(outline, "s1") == .expanded)
        #expect(disclosure(outline, "s2") == .collapsed)
        #expect(disclosure(outline, "s3") == SourcesDisclosure.none)
        #expect(outline.togglableSourceIDs == ["s1", "s2"])
        #expect(self.outline(expanded: []).rows.map(\.id) == ["s1", "s2", "s3"])
    }

    @Test func aFailedGraphListDropsTheTriangles() {
        enum Boom: Error { case boom }
        let failed = SourcesOutline(
            sources: [s1, s2, s3], graphs: { _ in .failed(Boom.boom) }, expanded: ["s1"]
        )
        #expect(failed.rows.map(\.id) == ["s1", "s2", "s3"])
        for id in ["s1", "s2", "s3"] { #expect(disclosure(failed, id) == SourcesDisclosure.none) }
        #expect(failed.togglableSourceIDs.isEmpty)
    }

    @Test func aSourceNotInTheGraphListYetIsPending() {
        let s4 = source("s4")
        let open = SourcesOutline(sources: [s4], graphs: reads([:]), expanded: ["s4"])
        #expect(open.rows.map(\.id) == ["s4", "s4#graphs"])
        #expect(disclosure(open, "s4") == .expanded)
        let closed = SourcesOutline(sources: [s4], graphs: reads([:]), expanded: [])
        #expect(closed.rows.map(\.id) == ["s4"])
        #expect(disclosure(closed, "s4") == .collapsed)
    }

    @Test func ownersCoverCollapsedGraphs() {
        let outline = outline(expanded: [])
        #expect(outline.ownerByGraphID.mapValues(\.id) == ["g1a": "s1", "g1b": "s1", "g2": "s2"])
    }

    @Test func backRevealsAGraphsClosedSource() {
        let closed = outline(expanded: [])
        #expect(closed.sourceToReveal("g1a") == "s1")
        #expect(outline(expanded: ["s1"]).sourceToReveal("g1a") == nil)
        #expect(closed.sourceToReveal("s2") == nil)
        #expect(closed.sourceToReveal("g9") == nil)
    }

    @Test func collapsingASourceSelectsItInsteadOfItsGraph() {
        let outline = outline(expanded: ["s1", "s2"])
        let collapsing: Set<String> = ["s1"]
        #expect(outline.selectionAfterCollapsing(collapsing, selection: "g1a") == "s1")
        #expect(outline.selectionAfterCollapsing(collapsing, selection: "s1#graphs") == "s1")
        #expect(outline.selectionAfterCollapsing(collapsing, selection: "g2") == "g2")
        #expect(outline.selectionAfterCollapsing(collapsing, selection: "s1") == "s1")
        #expect(outline.selectionAfterCollapsing(collapsing, selection: nil) == nil)
    }

    @Test func arrowKeysExpandCollapseAndClimb() {
        let closed = outline(expanded: [])
        let open = outline(expanded: ["s1"])
        func action(_ key: KeyEquivalent, _ outline: SourcesOutline, _ id: String?) -> SourcesOutlineKeyAction {
            SourcesOutline.keyAction(key, selected: outline.row(id: id))
        }
        #expect(action(.rightArrow, closed, "s1") == .expand("s1"))
        #expect(action(.leftArrow, open, "s1") == .collapse("s1"))
        #expect(action(.leftArrow, open, "g1a") == .select("s1"))
        #expect(action(.rightArrow, open, "s1") == .ignore)
        #expect(action(.rightArrow, open, "g1a") == .ignore)
        #expect(action(.leftArrow, closed, "s1") == .ignore)
        #expect(action(.rightArrow, closed, "s3") == .ignore)
        #expect(action(.leftArrow, closed, "s3") == .ignore)
        #expect(action(.rightArrow, closed, nil) == .ignore)
        #expect(action(.downArrow, closed, "s1") == .ignore)
        let pending = SourcesOutline(sources: [source("s4")], graphs: reads([:]), expanded: ["s4"])
        #expect(action(.leftArrow, pending, "s4#graphs") == .select("s4"))
    }

    @Test func aRuleEndsEachSourcesGroup() {
        let outline = outline(expanded: ["s1"])
        let ends = Dictionary(uniqueKeysWithValues: outline.rows.map { ($0.id, $0.endsGroup) })
        #expect(ends == ["s1": false, "g1a": false, "g1b": true, "s2": true, "s3": true])
        let pending = SourcesOutline(sources: [source("s4")], graphs: reads([:]), expanded: ["s4"])
        #expect(pending.rows.map(\.endsGroup) == [false, true])
    }

    @Test func summaryNamesTheGraphsStatuses() {
        let inProgress = SourcesGraphCounts.counts(subjects: 3, observations: 5, filed: 0)
        let promoted = SourcesGraphCounts.counts(subjects: 3, observations: 5, filed: 2)
        let none = SourcesGraphCounts.notStarted
        #expect(SourcesGraphSummary.text([inProgress]) == "1 graph · In progress")
        #expect(SourcesGraphSummary.text(Array(repeating: inProgress, count: 3) + Array(repeating: none, count: 5))
            == "8 graphs · 3 in progress")
        #expect(SourcesGraphSummary.text(Array(repeating: none, count: 8)) == "8 graphs · Not started")
        #expect(SourcesGraphSummary.text(Array(repeating: promoted, count: 5) + Array(repeating: none, count: 3))
            == "8 graphs · 5 promoted")
        #expect(SourcesGraphSummary.text(Array(repeating: none, count: 7) + [.loading]) == "8 graphs")
        #expect(SourcesGraphSummary.text(Array(repeating: none, count: 7) + [.unavailable(message: "x")]) == "8 graphs")
    }

    private func titles(_ sections: [[PVActionMenuItem]]) -> [[String]] {
        sections.map { $0.map { "\(L10n.string($0.title))|\($0.isEnabled)" } }
    }

    @Test func menusOfferWhatARowCanDo() throws {
        var openedGraph: (String, String)?
        let actions = SourcesRowMenu.Actions(
            open: { _ in }, openGraph: { openedGraph = ($0.id, $1.id) }, copy: { _ in }
        )
        let list: QueryRead<[CatalogEvidenceGraph]> = .loaded([g1a, g1b])
        let closed = try #require(outline(expanded: []).row(id: "s1"))
        let open = try #require(outline(expanded: ["s1"]).row(id: "s1"))
        #expect(titles(SourcesRowMenu.items(for: open, graphs: list, actions: actions))
            == [["Open|true", "Copy…|true"]])
        let menu = SourcesRowMenu.items(for: closed, graphs: list, actions: actions)
        #expect(titles(menu) == [["Open|true", "Copy…|true"], ["Open Default|true", "Open Jones household|false"]])
        menu[1][0].action()
        #expect(openedGraph?.0 == "g1a" && openedGraph?.1 == "s1")
        #expect(titles(SourcesRowMenu.items(for: closed, graphs: .loading, actions: actions))
            == [["Open|true", "Copy…|true"]])
        enum Boom: Error { case boom }
        #expect(titles(SourcesRowMenu.items(for: closed, graphs: .failed(Boom.boom), actions: actions))
            == [["Open|true", "Copy…|true"]])
        let expanded = outline(expanded: ["s1"])
        let linked = try #require(expanded.row(id: "g1a"))
        let bare = try #require(expanded.row(id: "g1b"))
        #expect(titles(SourcesRowMenu.items(for: linked, graphs: list, actions: actions)) == [["Open|true"]])
        #expect(titles(SourcesRowMenu.items(for: bare, graphs: list, actions: actions)) == [["Open|false"]])
        let pending = SourcesOutline(sources: [source("s4")], graphs: reads([:]), expanded: ["s4"])
        let placeholder = try #require(pending.row(id: "s4#graphs"))
        #expect(SourcesRowMenu.items(for: placeholder, graphs: .loading, actions: actions).isEmpty)
    }

    @Test func wideMovesTypeAndDateIntoColumns() {
        let date = CatalogDateValueInput(kind: "point", startYear: 1851)
        let tail = "1 graph · In progress"
        #expect(SourcesOutline.secondaryParts(type: "Census", date: date, tail: tail, isWide: false)
            == [.type("Census"), .date(date), .tail(tail)])
        #expect(SourcesOutline.secondaryParts(type: "Census", date: date, tail: tail, isWide: true) == [.tail(tail)])
        #expect(SourcesOutline.secondaryParts(type: "Census", date: nil, tail: nil, isWide: false) == [.type("Census")])
        #expect(SourcesOutline.secondaryParts(type: "Census", date: nil, tail: nil, isWide: true).isEmpty)
        #expect(SourcesOutline.secondaryParts(type: "", date: date, tail: nil, isWide: false) == [.date(date)])
        let regular = SourcesRowColumns.details(isWide: false, typeLabel: { _ in "Census" })
        #expect(regular.map(\.width) == [136])
        let wide = SourcesRowColumns.details(isWide: true, typeLabel: { _ in "Census" })
        #expect(wide.map(\.width) == [180, 140, 136])
        #expect(wide[0].content(s1)?.text == "Census")
    }

    // MARK: The session

    private func makeStore(sources: [CatalogSource], graphs: [CatalogEvidenceGraph]) -> FakeStore {
        let store = FakeStore()
        store.sourcesByProject[projectDir] = sources
        store.sourceTypesByProject[projectDir] = [
            CatalogSourceType(id: "t1", key: "census", origin: "provenencia", label: "Census", description: "")
        ]
        store.evidenceGraphsByProject[projectDir] = graphs
        // The fake store derives `hasArtifact` from the Artifacts a Source holds.
        for source in sources where source.hasArtifact {
            store.artifactsBySource[source.id] = [CatalogArtifact(
                id: "a-\(source.id)", ref: "ART-AAAAA", sourceID: source.id, fileID: "", label: "Scan",
                description: "", file: nil
            )]
        }
        return store
    }

    private func warm(_ model: SourcesModel, _ session: WorkspaceSession) async {
        model.warmListQueries()
        if let handle: QueryHandle<[CatalogSource]> = session.queryHandle(SourcesModel.sourcesListKey(for: session)) {
            await waitForQuery(handle)
        }
        if let handle: QueryHandle<[CatalogEvidenceGraph]> = session.queryHandle(session.evidenceGraphsKey) {
            await waitForQuery(handle)
        }
    }

    private func makeModel(_ store: FakeStore) -> (SourcesModel, WorkspaceSession) {
        let session = WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)
        return (SourcesModel(session: session, userID: userID, store: store), session)
    }

    @Test func outlineBuildsOncePerChangeAtScale() async {
        var sources: [CatalogSource] = []
        var graphs: [CatalogEvidenceGraph] = []
        for index in 0 ..< 3_000 {
            let id = String(format: "s%05d", index)
            sources.append(source(id))
            for slot in 0 ..< (index < 1_000 ? 4 : 3) {
                graphs.append(graph("g\(id)-\(slot)", source: id, name: "Graph \(slot)"))
            }
        }
        #expect(graphs.count == 10_000)
        let (model, session) = makeModel(makeStore(sources: sources, graphs: graphs))
        await warm(model, session)

        #expect(model.outline.rows.count == 3_000)
        _ = model.outline
        #expect(session.derivedBuildCount(.sourcesOutline) == 1)

        session.setSourcesExpanded(sources.map(\.id), true)
        #expect(model.outline.rows.count == 13_000)
        _ = model.outline
        #expect(session.derivedBuildCount(.sourcesOutline) == 2)

        // A graph's counts are read by its row as it draws: they are not an input.
        _ = session.evidenceGraphProgress(graphID: "gs00000-0")
        session.setQueryValue(session.evidenceGraphProgressKey, value: [String: EvidenceGraphProgress]())
        _ = model.outline
        #expect(session.derivedBuildCount(.sourcesOutline) == 2)

        session.setSourcesExpanded(sources.map(\.id), false)
        #expect(model.outline.rows.count == 3_000)
        #expect(session.derivedBuildCount(.sourcesOutline) == 3)
    }

    @Test func expandedSourcesOutliveTheModel() async throws {
        let store = makeStore(sources: [source("src-open-1")], graphs: [graph("g1", source: "src-open-1")])
        let (model, session) = makeModel(store)
        session.setSourcesExpanded(["src-open-1"], true)
        await warm(model, session)
        #expect(model.outline.rows.map(\.id) == ["src-open-1", "g1"])

        let again = SourcesModel(session: session, userID: userID, store: store)
        #expect(again.outline.rows.map(\.id) == ["src-open-1", "g1"])

        let (fresh, freshSession) = makeModel(store)
        await warm(fresh, freshSession)
        #expect(freshSession.expandedSourceIDs.isEmpty)
        #expect(fresh.outline.rows.map(\.id) == ["src-open-1"])

        let saved = try JSONEncoder().encode(model.settings)
        #expect(!String(decoding: saved, as: UTF8.self).contains("src-open-1"))
    }

    @Test func settingsChangesKeepTheOpenSources() async {
        let store = makeStore(sources: [source("s1"), source("s2")], graphs: [graph("g1", source: "s1"), graph("g2", source: "s2")])
        let (model, session) = makeModel(store)
        await warm(model, session)
        session.setSourcesExpanded(["s1"], true)
        model.settings.sort = .az
        #expect(session.expandedSourceIDs == ["s1"])
        #expect(model.outline.rows.map(\.id).contains("g1"))
    }
}
