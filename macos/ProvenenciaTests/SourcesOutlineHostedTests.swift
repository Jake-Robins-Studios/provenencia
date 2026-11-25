import AppKit
import SwiftUI
import Testing
@testable import Provenencia

/// The Sources list in a real (never shown) window: rows of two heights, the wheel step, the selection
/// and the keys that only the platform's table can answer.
@Suite(.serialized, .hostedWindows)
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

    /// The page over three Sources (s3, s2, s1 as listed) and any extra ones above or below them, once its
    /// table has `rows` rows.
    private func makeHarness(
        rows: Int = 3, open: String? = nil, extraSources: Int = 0, tailSources: Int = 0, anchor: String? = nil
    ) async throws -> Harness {
        let store = FakeStore()
        store.sourceTypesByProject[projectDir] = [
            CatalogSourceType(id: "t1", key: "census", origin: "provenencia", label: "Census", description: "")
        ]
        func source(_ id: String, _ title: String) -> CatalogSource {
            CatalogSource(
                id: id, ref: "SRC-\(id.uppercased())", sourceTypeID: "t1", title: title, description: "",
                date: CatalogDateValueInput(kind: "point", startYear: 1851),
                updated: CatalogActivity(revision: 1, at: "2026-11-21T10:00:00Z")
            )
        }
        // Ids sort after "s": they list before the three below in the newest-added order.
        let extras = (0 ..< extraSources).map { source("x\(String(format: "%02d", $0))", "Extra \($0)") }
        // Ids sort before "s": they list after s1 and its graphs, newest first.
        let tail = (0 ..< tailSources).map { source("a\(String(format: "%02d", $0))", "Tail \($0)") }
        store.sourcesByProject[projectDir] = extras + tail + [
            source("s3", "Passport of J. Robins"),
            source("s2", "1851 Census, Robins household"),
            source("s1", "Parish register, Lyon"),
        ]
        for id in ["s1", "s2"] + tail.map(\.id) {
            store.artifactsBySource[id] = [CatalogArtifact(
                id: "a-\(id)", ref: "ART-AAAAA", sourceID: id, fileID: "", label: "Scan", description: "", file: nil
            )]
        }
        store.evidenceGraphsByProject[projectDir] = (0 ..< 8).map { index in
            CatalogEvidenceGraph(
                id: "g1-\(index)", ref: "GPH-\(index)", sourceID: "s1", name: "Graph \(index)", description: "",
                artifactIDs: index == 3 ? [] : ["a-s1"]
            )
        } + (["s2"] + tail.map(\.id)).map { owner in
            CatalogEvidenceGraph(
                id: "g-\(owner)", ref: "GPH-\(owner)", sourceID: owner, name: "Default", description: "",
                artifactIDs: ["a-\(owner)"]
            )
        }
        let session = WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)
        session.setOpenSource(open)
        let navigation = WorkspaceNavigation()
        navigation.attachProject(
            uuid: UUID().uuidString,
            fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).json")
        )
        navigation.connect(to: session)
        if let anchor { navigation.noteListSelection(anchor) }
        let width: CGFloat = 1102
        let view = AnyView(
            WorkspaceDestinationHost(
                userID: "00000000-0000-7000-8000-000000000001", sessionDisplayName: "", store: store
            )
            .environment(session)
            .environment(navigation)
            .environment(\.pvWidthClass, PVWidthClass(paneWidth: width))
        )
        let (window, host) = hostInBorderlessWindow(view, windowSize: CGSize(width: width, height: 760))
        // The skeleton table has rows too: the loaded one is the one with this many.
        var table: NSTableView?
        #expect(await waitUntil(timeout: .seconds(10)) {
            host.layoutSubtreeIfNeeded()
            table = descendant(NSTableView.self, in: host)
            return table?.numberOfRows == rows
        })
        let tableView = try #require(table)
        return Harness(
            window: window, host: host, session: session, navigation: navigation, table: tableView,
            scroll: try #require(tableView.enclosingScrollView)
        )
    }

    /// The main-queue work enqueued before this call has run.
    private func mainQueueTurn() async {
        await withCheckedContinuation { turn in DispatchQueue.main.async { turn.resume() } }
    }

    private func select(
        _ anchor: String, row: Int, _ harness: Harness, sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        harness.navigation.noteListSelection(anchor)
        #expect(await eventually(harness.host) { harness.table.selectedRow == row }, sourceLocation: sourceLocation)
    }

    private func isInView(_ row: Int, _ harness: Harness) -> Bool {
        harness.scroll.documentVisibleRect.contains(harness.table.rect(ofRow: row))
    }

    /// AC-1.6: the platform reuses a row's cells for a row of the other height as Sources open and close,
    /// and every row drawn takes its own (one never drawn keeps the platform's estimate). The rows arrive
    /// with no layout forced here: one forced in the turn a Source opens hides a cell that kept its height.
    @Test func everyRowTakesItsOwnHeightAsSourcesOpenAndClose() async throws {
        let harness = try await makeHarness(rows: 33, tailSources: 30)
        let table = harness.table
        let sources = ["s3", "s2", "s1"] + (0 ..< 30).reversed().map { "a\(String(format: "%02d", $0))" }
        // No two neighbours have the same number of child rows: the rows reused change height each step.
        for open in ["s1", "a29", nil, "a26", "s1", "s2", "s1", nil] {
            harness.session.setOpenSource(open)
            let want = sources.flatMap { id -> [CGFloat] in
                [66] + Array(repeating: 34, count: id != open ? 0 : id == "s1" ? 8 : 1)
            }
            #expect(await waitUntil(timeout: .seconds(10)) { table.numberOfRows == want.count })
            var heights: [CGFloat] = []
            let settled = await eventually(harness.host) {
                heights = want.indices.map { table.rect(ofRow: $0).height }
                return want.indices.allSatisfy {
                    heights[$0] == want[$0] || table.rowView(atRow: $0, makeIfNecessary: false) == nil
                }
            }
            #expect(settled, "open \(open ?? "none"): \(heights)")
            #expect(table.rowView(atRow: 0, makeIfNecessary: false) != nil, "row 0 is drawn")
        }
        #expect(harness.scroll.verticalLineScroll == 34)
    }

    /// AC-4.2: a selection the table makes itself, not one navigation wrote, becomes the list anchor.
    @Test func theTablesOwnSelectionBecomesTheAnchor() async throws {
        let harness = try await makeHarness()
        harness.table.selectRowIndexes([1], byExtendingSelection: false)
        #expect(await eventually(harness.host) { harness.navigation.listSelection == "s2" })
    }

    /// AC-2.1, AC-2.2: Back to the Sources list opens the Source it was left with open, selects the
    /// row, and puts the list at the y it was left at. The graph is in the first screenful: the platform
    /// table selects a row only once it is drawn.
    @Test func backRestoresTheOpenSourceTheSelectionAndTheY() async throws {
        let harness = try await makeHarness(rows: 4 + 3 + 8, open: "s1", extraSources: 4)
        let graphRow = 4 + 3 + 2
        // The rows are measured: before, the table's document is too short for the y.
        #expect(await eventually(harness.host) { (harness.scroll.documentView?.frame.height ?? 0) > 700 })
        scroll(harness.scroll, to: 100)
        await select("g1-2", row: graphRow, harness)
        #expect(y(harness.scroll) == 100)
        let restored = try await leaveAndGoBack(harness)
        #expect(await eventually(harness.host) { self.y(restored) == 100 && (restored.documentView as? NSTableView)?.selectedRow == graphRow })
        #expect(harness.session.openSourceID == "s1")
    }

    /// A y past the height the table reports on arrival opens at the top, and stays on the entry.
    @Test func backToAYPastTheTablesHeightOpensAtTheTop() async throws {
        let harness = try await makeHarness(rows: 4 + 3 + 8 + 90, open: "s1", extraSources: 4, tailSources: 90)
        harness.navigation.noteScrollOffset(9000, arrival: harness.navigation.arrival)
        let restored = try await leaveAndGoBack(harness)
        await mainQueueTurn()
        harness.host.layoutSubtreeIfNeeded()
        #expect(y(restored) == 0)
        harness.navigation.goForward()
        harness.navigation.goBack()
        #expect(harness.navigation.currentLocation.revisit.scrollOffset == 9000)
    }

    private func y(_ scroll: NSScrollView) -> Double {
        Double(scroll.contentView.bounds.minY + scroll.contentView.contentInsets.top)
    }

    private func scroll(_ scroll: NSScrollView, to y: Double) {
        scroll.contentView.scroll(to: NSPoint(x: 0, y: y - scroll.contentView.contentInsets.top))
        scroll.reflectScrolledClipView(scroll.contentView)
        #expect(self.y(scroll) == y)
    }

    /// Opens s1's page, closes every Source, and goes Back: the list's new scroll view, its rows arrived.
    private func leaveAndGoBack(_ harness: Harness) async throws -> NSScrollView {
        let rows = harness.table.numberOfRows
        harness.navigation.go(to: .sourcePage(sourceId: "s1"))
        #expect(await eventually(harness.host) { descendant(NSTableView.self, in: harness.host) == nil })
        harness.session.setOpenSource(nil)
        harness.navigation.goBack()
        #expect(await eventually(harness.host) { descendant(NSTableView.self, in: harness.host)?.numberOfRows == rows })
        return try #require(descendant(NSTableView.self, in: harness.host)?.enclosingScrollView)
    }

    /// The Source above closes as this one opens, the rows move up, and the opened row is scrolled back
    /// into view. (The triangle's open runs the same `apply(.expand)` line.)
    @Test func aSourceThatOpensStaysInView() async throws {
        // s3, s2, s1 and its 8 graphs, then the tail: its first row, a09, lies just under the graphs.
        let harness = try await makeHarness(rows: 3 + 8 + 10, open: "s1", tailSources: 10)
        // The list scrolled so the graphs are partly above the viewport and a09 is just under them.
        harness.scroll.contentView.scroll(to: NSPoint(x: 0, y: harness.table.rect(ofRow: 10).maxY - 170))
        harness.scroll.reflectScrolledClipView(harness.scroll.contentView)
        await select("a09", row: 11, harness)
        #expect(harness.scroll.documentVisibleRect.intersects(harness.table.rect(ofRow: 11)))
        press(NSRightArrowFunctionKey, harness)
        #expect(await eventually(harness.host) {
            harness.table.numberOfRows == 3 + 1 + 10 && harness.table.selectedRow == 3 && isInView(3, harness)
        })
        #expect(harness.session.openSourceID == "a09")
    }

    private func press(_ key: Int, _ harness: Harness) {
        let codes = [NSRightArrowFunctionKey: 124, NSLeftArrowFunctionKey: 123, NSEndFunctionKey: 119, NSHomeFunctionKey: 115]
        let character = String(Character(UnicodeScalar(key)!))
        harness.window.makeFirstResponder(harness.table)
        harness.window.sendEvent(NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: codes[key] == nil ? [] : [.numericPad, .function],
            timestamp: 0, windowNumber: harness.window.windowNumber, context: nil, characters: character,
            charactersIgnoringModifiers: character, isARepeat: false, keyCode: UInt16(codes[key] ?? 36)
        )!)
    }

    /// End at a large catalog reaches the last row once the rows have settled, and Home the first.
    @Test func endReachesTheLastRowAndHomeTheFirstAtAHundredSources() async throws {
        let harness = try await makeHarness(rows: 103, extraSources: 100)
        press(NSEndFunctionKey, harness)
        #expect(await eventually(harness.host) { isInView(102, harness) })
        press(NSHomeFunctionKey, harness)
        #expect(await eventually(harness.host) { isInView(0, harness) })
    }

    @Test func rightAndLeftArrowsOpenCloseAndClimb() async throws {
        let harness = try await makeHarness()
        await select("s1", row: 2, harness)
        press(NSRightArrowFunctionKey, harness)
        #expect(await eventually(harness.host) { harness.table.numberOfRows == 11 })
        #expect(harness.session.openSourceID == "s1")
        await select("g1-2", row: 5, harness)
        press(NSLeftArrowFunctionKey, harness)
        #expect(await eventually(harness.host) { harness.table.selectedRow == 2 })
        #expect(harness.session.openSourceID == "s1")
        press(NSLeftArrowFunctionKey, harness)
        #expect(await eventually(harness.host) { harness.table.numberOfRows == 3 })
        #expect(harness.session.openSourceID == nil)
    }

    /// The graph with no Artifact does not open: the one entry the second Return adds is the only one.
    @Test func returnOpensAGraphThatLinksAnArtifactAndNoOther() async throws {
        let harness = try await makeHarness(rows: 11, open: "s1")
        let root = harness.navigation.currentLocation
        await select("g1-3", row: 6, harness)
        press(NSCarriageReturnCharacter, harness)
        await select("g1-0", row: 3, harness)
        press(NSCarriageReturnCharacter, harness)
        #expect(await eventually(harness.host) { harness.navigation.currentLocation.graphId == "g1-0" })
        harness.navigation.goBack()
        #expect(harness.navigation.currentLocation == root.withListSelection("g1-0"))
        #expect(!harness.navigation.canGoBack)
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
        #expect(await eventually(harness.host) { holder(harness) == "table" })
    }

    @Test func aReturningListLeavesTheSearchFieldFocused() async throws {
        let harness = try await makeHarness()
        #expect(await eventually(harness.host) { holder(harness) == "table" })
        let field = try #require(descendant(NSTextField.self, in: harness.host))
        harness.window.makeFirstResponder(field)
        let editor = try #require(harness.window.fieldEditor(false, for: field) as? NSTextView)
        #expect(holder(harness) == "field")
        editor.insertText("zzzz", replacementRange: NSRange(location: 0, length: 0))
        #expect(await eventually(harness.host) { descendant(NSTableView.self, in: harness.host) == nil })
        #expect(holder(harness) == "field")
        editor.selectAll(nil)
        editor.insertText("", replacementRange: editor.selectedRange())
        #expect(await eventually(harness.host) { descendant(NSTableView.self, in: harness.host)?.numberOfRows == 3 })
        // `FocusClaim` writes on the next two turns.
        await mainQueueTurn()
        await mainQueueTurn()
        #expect(holder(harness) == "field")
    }
}
