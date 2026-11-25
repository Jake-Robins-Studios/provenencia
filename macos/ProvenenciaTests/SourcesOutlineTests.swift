import Foundation
import SwiftUI
import Testing
@testable import Provenencia

/// The Sources list's outline: its rows, its open Source, its keys, its clicks and its menus. Pure
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

    private func outline(open: String?) -> SourcesOutline {
        SourcesOutline(
            sources: [s1, s2, s3],
            graphs: reads(["s1": .loaded([g1a, g1b]), "s2": .loaded([g2])]),
            open: open
        )
    }

    private func disclosure(_ outline: SourcesOutline, _ id: String) -> SourcesDisclosure? {
        outline.row(id: id)?.disclosure
    }

    /// T-6: AC-4.1; one Source open at a time; an open id no Source has draws nothing.
    @Test func oneSourceOpens() {
        #expect(outline(open: nil).rows.map(\.id) == ["s1", "s2", "s3"])
        let first = outline(open: "s1")
        #expect(first.rows.map(\.id) == ["s1", "g1a", "g1b", "s2", "s3"])
        #expect(disclosure(first, "s1") == .expanded)
        #expect(disclosure(first, "s2") == .collapsed)
        #expect(disclosure(first, "s3") == SourcesDisclosure.none)
        let second = outline(open: "s2")
        #expect(second.rows.map(\.id) == ["s1", "s2", "g2", "s3"])
        #expect(disclosure(second, "s1") == .collapsed)
        // The open id of a filtered-out or deleted Source costs one string and draws nothing.
        #expect(outline(open: "s9").rows.map(\.id) == ["s1", "s2", "s3"])
        // A Source with no Artifact never opens.
        #expect(outline(open: "s3").rows.map(\.id) == ["s1", "s2", "s3"])
    }

    @Test func aFailedGraphListDropsTheTriangles() {
        enum Boom: Error { case boom }
        let failed = SourcesOutline(
            sources: [s1, s2, s3], graphs: { _ in .failed(Boom.boom) }, open: "s1"
        )
        #expect(failed.rows.map(\.id) == ["s1", "s2", "s3"])
        for id in ["s1", "s2", "s3"] { #expect(disclosure(failed, id) == SourcesDisclosure.none) }
    }

    @Test func aSourceNotInTheGraphListYetIsPending() {
        let s4 = source("s4")
        let open = SourcesOutline(sources: [s4], graphs: reads([:]), open: "s4")
        #expect(open.rows.map(\.id) == ["s4", "s4#graphs"])
        #expect(disclosure(open, "s4") == .expanded)
        let closed = SourcesOutline(sources: [s4], graphs: reads([:]), open: nil)
        #expect(closed.rows.map(\.id) == ["s4"])
        #expect(disclosure(closed, "s4") == .collapsed)
    }

    @Test func backRevealsAGraphsClosedSource() {
        let closed = outline(open: nil)
        #expect(closed.sourceToReveal("g1a") == "s1")
        #expect(outline(open: "s1").sourceToReveal("g1a") == nil)
        // A Source that is not the open one is closed, so its graph is revealed.
        #expect(outline(open: "s2").sourceToReveal("g1a") == "s1")
        #expect(closed.sourceToReveal("s2") == nil)
        #expect(closed.sourceToReveal("g9") == nil)
    }

    /// T-6: AC-4.5, AC-4.6, AC-4.7 and AC-4.8: what the selection becomes when a Source opens or closes.
    struct OpeningCase: CustomTestStringConvertible {
        let before: String?
        let after: String?
        let selecting: String?
        let current: String?
        let expected: String?
        var testDescription: String {
            "\(before ?? "-") -> \(after ?? "-"), selecting \(selecting ?? "-"), current \(current ?? "-")"
        }
    }

    @Test(arguments: [
        // Close A with its graph selected: A is selected.
        OpeningCase(before: "s1", after: nil, selecting: nil, current: "g1a", expected: "s1"),
        // Open B with A's graph selected: A closes and is selected.
        OpeningCase(before: "s1", after: "s2", selecting: nil, current: "g1a", expected: "s1"),
        // A Source row stays selected; a graph of the Source that stays open stays selected.
        OpeningCase(before: "s1", after: "s2", selecting: nil, current: "s1", expected: "s1"),
        OpeningCase(before: "s1", after: "s1", selecting: nil, current: "g1a", expected: "g1a"),
        OpeningCase(before: "s2", after: "s1", selecting: nil, current: "g2", expected: "s2"),
        // `selecting` wins: Open a graph from the menu, or Back to it, or a click.
        OpeningCase(before: "s2", after: "s1", selecting: "g1a", current: "g2", expected: "g1a"),
        OpeningCase(before: "s1", after: nil, selecting: "s2", current: "g1a", expected: "s2"),
        // No selection, and a selection no row draws, are left alone.
        OpeningCase(before: "s1", after: "s2", selecting: nil, current: nil, expected: nil),
        OpeningCase(before: "s1", after: "s2", selecting: nil, current: "gone", expected: "gone"),
    ])
    func openingMovesASelectionOffTheClosedGroup(_ c: OpeningCase) {
        let outline = outline(open: c.before)
        #expect(outline.selection(afterOpening: c.after, selecting: c.selecting, current: c.current) == c.expected)
    }

    /// The page's one path for closing a Source (the triangle, the keys and the VoiceOver action).
    @Test func closingTheSourceOfASelectedGraphSelectsTheSource() {
        let session = WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: FakeStore())
        let navigation = WorkspaceNavigation()
        session.setOpenSource("s1")
        navigation.noteListAnchor("g1a")
        outline(open: "s1").setOpen(nil, session: session, navigation: navigation)
        #expect(session.openSourceID == nil)
        #expect(navigation.listAnchor == "s1")
    }

    @Test func aPendingRowSelectsItsSourceWhenItCloses() {
        let pending = SourcesOutline(sources: [source("s4")], graphs: reads([:]), open: "s4")
        let placeholder = SourcesOutlineRow.pendingID(sourceID: "s4")
        #expect(pending.selection(afterOpening: nil, selecting: nil, current: placeholder) == "s4")
    }

    /// T-7: every line of D-14.
    @Test func aPlainClickOpensOneSource() {
        let closed = outline(open: nil)
        let mixed = outline(open: "s1")
        func action(
            _ outline: SourcesOutline, _ new: String?, from old: String? = nil, click: Bool = true,
            triangle: Bool = false
        ) -> SourcesOutlineAction {
            outline.clickAction(selecting: new, from: old, isPlainClick: click, onTriangle: triangle)
        }
        #expect(action(closed, "s2") == .expand("s2"))
        #expect(action(closed, "s2", from: "s1") == .expand("s2"))
        // Another Source opens while one is open: the page closes the first.
        #expect(action(mixed, "s2") == .expand("s2"))
        // Not a plain left click: the keyboard, Back, a reveal, a menu, a right-click, a modified click
        // (⌥-click included: it only selects).
        #expect(action(closed, "s2", click: false) == .ignore)
        // A press on the triangle: the button toggles it itself.
        #expect(action(closed, "s2", triangle: true) == .ignore)
        // The selection did not move.
        #expect(action(closed, "s2", from: "s2") == .ignore)
        #expect(action(closed, nil, from: "s2") == .ignore)
        // The open Source and a graph row of it: A stays open.
        #expect(action(mixed, "s1") == .ignore)
        #expect(action(mixed, "g1a") == .ignore)
        // A Source with no triangle closes the open one; with none open there is nothing to do.
        #expect(action(mixed, "s3") == .collapse)
        #expect(action(closed, "s3") == .ignore)
        #expect(action(closed, "missing") == .ignore)
    }

    /// F-8 (CON-5): the open Source that has no triangle (its graph read failed, say) stays open when it
    /// is clicked: closing "the open one" would close the very Source clicked.
    @Test func clickingTheOpenSourceWithNoTriangleLeavesItOpen() {
        let open = outline(open: "s3")
        #expect(disclosure(open, "s3") == SourcesDisclosure.none)
        #expect(open.clickAction(selecting: "s3", from: "s1", isPlainClick: true, onTriangle: false) == .ignore)
        // Another Source with no triangle still closes it.
        let other = SourcesOutline(
            sources: [s1, s3, source("s4", artifact: false)], graphs: reads([:]), open: "s3"
        )
        #expect(other.clickAction(selecting: "s4", from: "s1", isPlainClick: true, onTriangle: false) == .collapse)
    }

    @Test func arrowKeysExpandCollapseAndClimb() {
        let closed = outline(open: nil)
        let open = outline(open: "s1")
        func action(_ key: KeyEquivalent, _ outline: SourcesOutline, _ id: String?) -> SourcesOutlineAction {
            SourcesOutline.keyAction(key, selected: outline.row(id: id))
        }
        #expect(action(.rightArrow, closed, "s1") == .expand("s1"))
        #expect(action(.leftArrow, open, "s1") == .collapse)
        #expect(action(.leftArrow, open, "g1a") == .select("s1"))
        #expect(action(.rightArrow, open, "s1") == .ignore)
        #expect(action(.rightArrow, open, "g1a") == .ignore)
        #expect(action(.leftArrow, closed, "s1") == .ignore)
        #expect(action(.rightArrow, closed, "s3") == .ignore)
        #expect(action(.leftArrow, closed, "s3") == .ignore)
        #expect(action(.rightArrow, closed, nil) == .ignore)
        #expect(action(.downArrow, closed, "s1") == .ignore)
        let pending = SourcesOutline(sources: [source("s4")], graphs: reads([:]), open: "s4")
        #expect(action(.leftArrow, pending, "s4#graphs") == .select("s4"))
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
        let closed = try #require(outline(open: nil).row(id: "s1"))
        let open = try #require(outline(open: "s1").row(id: "s1"))
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
        let expanded = outline(open: "s1")
        let linked = try #require(expanded.row(id: "g1a"))
        let bare = try #require(expanded.row(id: "g1b"))
        #expect(titles(SourcesRowMenu.items(for: linked, graphs: list, actions: actions)) == [["Open|true"]])
        #expect(titles(SourcesRowMenu.items(for: bare, graphs: list, actions: actions)) == [["Open|false"]])
        let pending = SourcesOutline(sources: [source("s4")], graphs: reads([:]), open: "s4")
        let placeholder = try #require(pending.row(id: "s4#graphs"))
        #expect(SourcesRowMenu.items(for: placeholder, graphs: .loading, actions: actions).isEmpty)
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

        // Opening one Source adds its graphs only: opening every Source is no longer possible.
        session.setOpenSource(sources[0].id)
        #expect(model.outline.rows.count == 3_004)
        _ = model.outline
        #expect(session.derivedBuildCount(.sourcesOutline) == 2)

        // A graph's counts are read by its row as it draws: they are not an input.
        _ = session.evidenceGraphProgress(graphID: "gs00000-0")
        session.setQueryValue(session.evidenceGraphProgressKey, value: [String: EvidenceGraphProgress]())
        _ = model.outline
        #expect(session.derivedBuildCount(.sourcesOutline) == 2)

        session.setOpenSource(nil)
        #expect(model.outline.rows.count == 3_000)
        #expect(session.derivedBuildCount(.sourcesOutline) == 3)
    }

    @Test func theOpenSourceOutlivesTheModel() async throws {
        let store = makeStore(sources: [source("src-open-1")], graphs: [graph("g1", source: "src-open-1")])
        let (model, session) = makeModel(store)
        session.setOpenSource("src-open-1")
        await warm(model, session)
        #expect(model.outline.rows.map(\.id) == ["src-open-1", "g1"])

        let again = SourcesModel(session: session, userID: userID, store: store)
        #expect(again.outline.rows.map(\.id) == ["src-open-1", "g1"])

        let (fresh, freshSession) = makeModel(store)
        await warm(fresh, freshSession)
        #expect(freshSession.openSourceID == nil)
        #expect(fresh.outline.rows.map(\.id) == ["src-open-1"])

        let saved = try JSONEncoder().encode(model.settings)
        #expect(!String(decoding: saved, as: UTF8.self).contains("src-open-1"))
    }

    @Test func settingsChangesKeepTheOpenSource() async {
        let store = makeStore(sources: [source("s1"), source("s2")], graphs: [graph("g1", source: "s1"), graph("g2", source: "s2")])
        let (model, session) = makeModel(store)
        await warm(model, session)
        session.setOpenSource("s1")
        model.settings.sort = .az
        #expect(session.openSourceID == "s1")
        #expect(model.outline.rows.map(\.id).contains("g1"))
    }
}
