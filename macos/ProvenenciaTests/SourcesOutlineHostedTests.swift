import AppKit
import SwiftUI
import Testing
@testable import Provenencia

/// The Sources list in a real (never shown) window: rows of two heights, the wheel step, the selection
/// and the keys that only the platform's table can answer.
@Suite(.hostedWindows)
@MainActor
struct SourcesOutlineHostedTests {
    private let projectDir = "/tmp/outline-hosted.provenencia"

    private struct Harness {
        let window: NSWindow
        let host: NSHostingView<AnyView>
        let session: WorkspaceSession
        let navigation: WorkspaceNavigation
        let table: NSTableView
        let scroll: NSScrollView
    }

    private func descendant<V: NSView>(_ type: V.Type, in view: NSView) -> V? {
        if let match = view as? V { return match }
        return view.subviews.lazy.compactMap { descendant(type, in: $0) }.first
    }

    private func makeHarness(width: CGFloat = 1102, expanded: [String] = []) async throws -> Harness {
        let store = FakeStore()
        store.sourceTypesByProject[projectDir] = [
            CatalogSourceType(id: "t1", key: "census", origin: "provenencia", label: "Census", description: "")
        ]
        func source(_ id: String, _ title: String, artifact: Bool) -> CatalogSource {
            CatalogSource(
                id: id, ref: "SRC-\(id.uppercased())", sourceTypeID: "t1", title: title, description: "",
                date: CatalogDateValueInput(kind: "point", startYear: 1851),
                updated: CatalogActivity(revision: 1, at: "2026-11-21T10:00:00Z")
            )
        }
        store.sourcesByProject[projectDir] = [
            source("s3", "Passport of J. Robins", artifact: false),
            source("s2", "1851 Census, Robins household", artifact: true),
            source("s1", "Parish register, Lyon", artifact: true),
        ]
        for id in ["s1", "s2"] {
            store.artifactsBySource[id] = [CatalogArtifact(
                id: "a-\(id)", ref: "ART-AAAAA", sourceID: id, fileID: "", label: "Scan", description: "", file: nil
            )]
        }
        store.evidenceGraphsByProject[projectDir] = (0 ..< 8).map { index in
            CatalogEvidenceGraph(
                id: "g1-\(index)", ref: "GPH-\(index)", sourceID: "s1", name: "Graph \(index)", description: "",
                artifactIDs: index == 3 ? [] : ["a-s1"]
            )
        } + [CatalogEvidenceGraph(
            id: "g2-0", ref: "GPH-20", sourceID: "s2", name: "Default", description: "", artifactIDs: ["a-s2"]
        )]
        store.graphProgressByGraph["g1-0"] = EvidenceGraphProgress(graphId: "g1-0", subjectCount: 12, observationCount: 40)
        let session = WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)
        session.setSourcesExpanded(expanded, true)
        let navigation = WorkspaceNavigation()
        let view = AnyView(
            SourcesListView(
                session: session, userID: "00000000-0000-7000-8000-000000000001",
                projectUuid: UUID().uuidString, store: store
            )
            .environment(session)
            .environment(navigation)
            .environment(\.pvWidthClass, PVWidthClass(paneWidth: width))
        )
        let (window, host) = hostInBorderlessWindow(view, windowSize: CGSize(width: width, height: 760))
        host.layoutSubtreeIfNeeded()
        var table: NSTableView?
        let found = await waitUntil(timeout: .seconds(10)) {
            host.layoutSubtreeIfNeeded()
            table = descendant(NSTableView.self, in: host)
            return (table?.numberOfRows ?? 0) > 0
        }
        #expect(found)
        let tableView = try #require(table)
        let scroll = try #require(tableView.enclosingScrollView)
        return Harness(window: window, host: host, session: session, navigation: navigation, table: tableView, scroll: scroll)
    }

    private func settle(_ harness: Harness, rows: Int) async -> Bool {
        await waitUntil(timeout: .seconds(10)) {
            harness.host.layoutSubtreeIfNeeded()
            return harness.table.numberOfRows == rows
        }
    }

    private func heights(_ table: NSTableView) -> [CGFloat] {
        (0 ..< table.numberOfRows).map { table.rect(ofRow: $0).height }
    }

    @Test func closedSourcesAreOneRowEach() async throws {
        let harness = try await makeHarness()
        #expect(harness.table.numberOfRows == 3)
        #expect(heights(harness.table) == [66, 66, 66])
        #expect(harness.navigation.listAnchor == nil)
    }

    @Test func openSourceDrawsItsGraphsAtTheirOwnHeightAndTheWheelStepIsOneGraphRow() async throws {
        let harness = try await makeHarness()
        harness.session.setSourcesExpanded(["s1"], true)
        #expect(await settle(harness, rows: 11))
        // The newest-added order: s3, s2, s1 are ids descending; s1 is last with its 8 graphs under it.
        #expect(heights(harness.table) == [66, 66, 66] + Array(repeating: 34, count: 8))
        let rects = (0 ..< harness.table.numberOfRows).map { harness.table.rect(ofRow: $0) }
        for (above, below) in zip(rects, rects.dropFirst()) {
            #expect(above.maxY <= below.minY + 0.5)
        }
        #expect(harness.scroll.verticalLineScroll == 34)
    }

    @Test func aSelectedGraphRowStaysSelectedAndClosingItsSourceSelectsTheSource() async throws {
        let harness = try await makeHarness(expanded: ["s1"])
        #expect(await settle(harness, rows: 11))
        harness.navigation.noteListAnchor("g1-2")
        #expect(await waitUntil { harness.host.layoutSubtreeIfNeeded(); return harness.table.selectedRow == 5 })
        #expect(harness.table.selectedRow == 5)
    }

    private func keyEvent(_ key: Int, in window: NSWindow) -> NSEvent {
        let character = String(Character(UnicodeScalar(key)!))
        return NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [.numericPad, .function], timestamp: 0,
            windowNumber: window.windowNumber, context: nil, characters: character,
            charactersIgnoringModifiers: character, isARepeat: false, keyCode: key == NSRightArrowFunctionKey ? 124 : 123
        )!
    }

    private func press(_ key: Int, _ harness: Harness) async {
        harness.window.makeFirstResponder(harness.table)
        harness.window.sendEvent(keyEvent(key, in: harness.window))
        try? await Task.sleep(for: .milliseconds(100))
        harness.host.layoutSubtreeIfNeeded()
    }

    @Test func rightAndLeftArrowsOpenCloseAndClimb() async throws {
        let harness = try await makeHarness()
        harness.navigation.noteListAnchor("s1")
        _ = await waitUntil { harness.host.layoutSubtreeIfNeeded(); return harness.table.selectedRow == 2 }
        await press(NSRightArrowFunctionKey, harness)
        #expect(harness.session.expandedSourceIDs == ["s1"])
        #expect(await settle(harness, rows: 11))
        harness.navigation.noteListAnchor("g1-2")
        _ = await waitUntil { harness.host.layoutSubtreeIfNeeded(); return harness.table.selectedRow == 5 }
        await press(NSLeftArrowFunctionKey, harness)
        #expect(harness.navigation.listAnchor == "s1")
        #expect(harness.session.expandedSourceIDs == ["s1"])
        await press(NSLeftArrowFunctionKey, harness)
        #expect(harness.session.expandedSourceIDs.isEmpty)
        #expect(await settle(harness, rows: 3))
    }

    @Test func returnOpensASourceAndAGraphThatLinksAnArtifactAndNothingElse() async throws {
        let harness = try await makeHarness(expanded: ["s1"])
        #expect(await settle(harness, rows: 11))
        func returnKey() -> NSEvent {
            NSEvent.keyEvent(
                with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0,
                windowNumber: harness.window.windowNumber, context: nil, characters: "\r",
                charactersIgnoringModifiers: "\r", isARepeat: false, keyCode: 36
            )!
        }
        func pressReturn() async {
            harness.window.makeFirstResponder(harness.table)
            harness.window.sendEvent(returnKey())
            try? await Task.sleep(for: .milliseconds(100))
        }
        let root = harness.navigation.currentLocation
        harness.navigation.noteListAnchor("g1-3")
        _ = await waitUntil { harness.host.layoutSubtreeIfNeeded(); return harness.table.selectedRow == 6 }
        await pressReturn()
        #expect(harness.navigation.currentLocation == root)

        harness.navigation.noteListAnchor("g1-0")
        _ = await waitUntil { harness.host.layoutSubtreeIfNeeded(); return harness.table.selectedRow == 3 }
        await pressReturn()
        #expect(harness.navigation.currentLocation.graphId == "g1-0")
    }

    /// The responder that holds the keyboard: the search field's editor, the table, or neither.
    private func holder(_ harness: Harness) -> String {
        guard let responder = harness.window.firstResponder else { return "none" }
        if let text = responder as? NSTextView, text.isFieldEditor { return "field" }
        if responder === harness.table || (responder as? NSView)?.isDescendant(of: harness.table) == true { return "table" }
        return String(describing: type(of: responder))
    }

    @Test func theListTakesFocusOnArrival() async throws {
        let harness = try await makeHarness()
        #expect(await waitUntil { harness.host.layoutSubtreeIfNeeded(); return holder(harness) == "table" })
        #expect(holder(harness) == "table")
    }

    @Test func aReturningListLeavesTheSearchFieldFocused() async throws {
        let harness = try await makeHarness()
        _ = await waitUntil { harness.host.layoutSubtreeIfNeeded(); return holder(harness) == "table" }
        let field = try #require(descendant(NSTextField.self, in: harness.host))
        harness.window.makeFirstResponder(field)
        let editor = try #require(harness.window.fieldEditor(false, for: field) as? NSTextView)
        #expect(holder(harness) == "field")
        editor.insertText("zzzz", replacementRange: NSRange(location: 0, length: 0))
        #expect(await waitUntil { harness.host.layoutSubtreeIfNeeded(); return descendant(NSTableView.self, in: harness.host) == nil })
        #expect(holder(harness) == "field")
        editor.selectAll(nil)
        editor.insertText("", replacementRange: editor.selectedRange())
        #expect(await waitUntil { harness.host.layoutSubtreeIfNeeded(); return (descendant(NSTableView.self, in: harness.host)?.numberOfRows ?? 0) == 3 })
        try? await Task.sleep(for: .milliseconds(300))
        #expect(holder(harness) == "field")
    }

    /// The x-extent of the hairline drawn under a row: the first and last column where a pixel is drawn
    /// across most of a one-pixel band inside the row's rect. Nil when the row draws no rule.
    private func ruleExtent(row: Int, in table: NSTableView) -> ClosedRange<Int>? {
        guard let rep = table.bitmapImageRepForCachingDisplay(in: table.bounds) else { return nil }
        table.cacheDisplay(in: table.bounds, to: rep)
        let scale = CGFloat(rep.pixelsWide) / table.bounds.width
        let rect = table.rect(ofRow: row)
        let yRange = Int((rect.minY + rect.height * 0.6) * scale) ..< Int(rect.maxY * scale)
        var best: ClosedRange<Int>?
        for y in yRange {
            var first: Int?
            var last = 0
            var count = 0
            for x in 0 ..< rep.pixelsWide {
                guard let color = rep.colorAt(x: x, y: y), color.alphaComponent > 0.05 else { continue }
                if first == nil { first = x }
                last = x
                count += 1
            }
            if let first, count > rep.pixelsWide / 2, count >= (last - first) * 9 / 10 {
                best = first ... last
            }
        }
        return best.map { Int(CGFloat($0.lowerBound) / scale) ... Int(CGFloat($0.upperBound) / scale) }
    }

    /// A rule starts at the gutter and ends within the platform's few points of the trailing gutter.
    private func expectGutterToGutter(_ extent: ClosedRange<Int>?, gutter: Int, width: Int) {
        #expect(extent?.lowerBound == gutter)
        #expect((extent?.upperBound ?? 0) >= width - gutter - 4 && (extent?.upperBound ?? 0) <= width - gutter)
    }

    private struct PlainRow: Identifiable {
        let id: String
    }

    @Test func theRulesRunGutterToGutter() async throws {
        let harness = try await makeHarness(expanded: ["s2"])
        #expect(await settle(harness, rows: 4))
        try? await Task.sleep(for: .milliseconds(300))
        let gutter = Int(PVWidthClass(paneWidth: 1102).fullPaneGutter)
        let width = Int(harness.table.bounds.width)
        // Rows: a Source with no triangle, an open Source, its last graph.
        expectGutterToGutter(ruleExtent(row: 0, in: harness.table), gutter: gutter, width: width)
        #expect(ruleExtent(row: 1, in: harness.table) == nil)
        expectGutterToGutter(ruleExtent(row: 2, in: harness.table), gutter: gutter, width: width)
    }

    /// A list with no leading slot (the Persons list's shape): its rules also run gutter to gutter.
    @Test func aPlainListsRulesRunGutterToGutter() async throws {
        var selection: String?
        let rows = (0 ..< 3).map { PlainRow(id: "r\($0)") }
        let view = AnyView(
            PVList(
                items: rows,
                selection: Binding(get: { selection }, set: { selection = $0 }),
                thumbnail: { _ in PVThumbnail(PVThumbnail.Content(glyph: .mark(.subjectPerson))) },
                horizontalInset: 32,
                label: L10n.Workspace.personsTitle,
                itemAccessibilityLabel: { $0.id },
                onActivate: { _ in },
                primary: { Text(verbatim: $0.id) },
                secondary: { _ in EmptyView() }
            )
        )
        let (_, host) = hostInBorderlessWindow(view, windowSize: CGSize(width: 800, height: 400))
        var table: NSTableView?
        _ = await waitUntil(timeout: .seconds(10)) {
            host.layoutSubtreeIfNeeded()
            table = descendant(NSTableView.self, in: host)
            return (table?.numberOfRows ?? 0) == 3
        }
        let tableView = try #require(table)
        try? await Task.sleep(for: .milliseconds(300))
        expectGutterToGutter(ruleExtent(row: 0, in: tableView), gutter: 32, width: Int(tableView.bounds.width))
    }
}
