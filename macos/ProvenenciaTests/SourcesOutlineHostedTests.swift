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
        rows: Int = 3, open: String? = nil, extraSources: Int = 0, tailSources: Int = 0, anchor: String? = nil,
        currentEvent: @escaping @MainActor @Sendable () -> NSEvent? = { nil }
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
        if let anchor { navigation.noteListAnchor(anchor) }
        let width: CGFloat = 1102
        let view = AnyView(
            SourcesListView(
                session: session, userID: "00000000-0000-7000-8000-000000000001",
                projectUuid: UUID().uuidString, store: store
            )
            .environment(session)
            .environment(navigation)
            .environment(\.pvWidthClass, PVWidthClass(paneWidth: width))
            .environment(\.sourcesCurrentEvent, SourcesEventSource(currentEvent))
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

    /// Lays out until `condition` holds. The 10 s are only how long a failure takes.
    private func eventually(_ harness: Harness, _ condition: () -> Bool) async -> Bool {
        await waitUntil(timeout: .seconds(10)) {
            harness.host.layoutSubtreeIfNeeded()
            return condition()
        }
    }

    /// The main-queue work enqueued before this call has run.
    private func mainQueueTurn() async {
        await withCheckedContinuation { turn in DispatchQueue.main.async { turn.resume() } }
    }

    private func select(
        _ anchor: String, row: Int, _ harness: Harness, sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        harness.navigation.noteListAnchor(anchor)
        #expect(await eventually(harness) { harness.table.selectedRow == row }, sourceLocation: sourceLocation)
    }

    private func isInView(_ row: Int, _ harness: Harness) -> Bool {
        harness.scroll.documentVisibleRect.contains(harness.table.rect(ofRow: row))
    }

    /// AC-1.6: the platform reuses a row's cells for a row of the other height as Sources open and close,
    /// and every row takes its own.
    @Test func everyRowTakesItsOwnHeightAsSourcesOpenAndClose() async throws {
        let harness = try await makeHarness()
        func expectHeights(_ want: [CGFloat], sourceLocation: SourceLocation = #_sourceLocation) async {
            var heights: [CGFloat] = []
            let settled = await eventually(harness) {
                heights = (0 ..< harness.table.numberOfRows).map { harness.table.rect(ofRow: $0).height }
                return heights == want
            }
            #expect(settled, "\(heights)", sourceLocation: sourceLocation)
        }
        await expectHeights([66, 66, 66])
        #expect(harness.navigation.listAnchor == nil)
        harness.session.setOpenSource("s1")
        await expectHeights([66, 66, 66] + Array(repeating: 34, count: 8))
        #expect(harness.scroll.verticalLineScroll == 34)
        harness.session.setOpenSource("s2")
        await expectHeights([66, 66, 34, 66])
        harness.session.setOpenSource(nil)
        await expectHeights([66, 66, 66])
    }

    @Test func anAnchorOnAGraphOfAClosedSourceOpensTheSourceAndSelectsTheGraph() async throws {
        let harness = try await makeHarness()
        harness.navigation.noteListAnchor("g1-2")
        #expect(await eventually(harness) { harness.table.numberOfRows == 11 && harness.table.selectedRow == 5 })
        #expect(harness.session.openSourceID == "s1")
    }

    /// The selection on Back. The scroll on Back is S16-72.
    @Test func anAnchorSetBeforeThePageIsHostedOpensTheSourceAndSelectsTheGraph() async throws {
        // 15 Source rows above s1 push its graphs past the 760 pt window.
        let harness = try await makeHarness(rows: 15 + 3 + 8, extraSources: 15, anchor: "g1-7")
        #expect(harness.session.openSourceID == "s1")
        #expect(await eventually(harness) { harness.table.selectedRow == 15 + 3 + 7 })
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
        #expect(await eventually(harness) {
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

    private func pressReturn(_ harness: Harness) { press(NSCarriageReturnCharacter, harness) }

    /// End at a large catalog reaches the last row once the rows have settled, and Home the first.
    @Test func endReachesTheLastRowAndHomeTheFirstAtAHundredSources() async throws {
        let harness = try await makeHarness(rows: 103, extraSources: 100)
        press(NSEndFunctionKey, harness)
        #expect(await eventually(harness) { isInView(102, harness) })
        press(NSHomeFunctionKey, harness)
        #expect(await eventually(harness) { isInView(0, harness) })
    }

    @Test func rightAndLeftArrowsOpenCloseAndClimb() async throws {
        let harness = try await makeHarness()
        await select("s1", row: 2, harness)
        press(NSRightArrowFunctionKey, harness)
        #expect(await eventually(harness) { harness.table.numberOfRows == 11 })
        #expect(harness.session.openSourceID == "s1")
        await select("g1-2", row: 5, harness)
        press(NSLeftArrowFunctionKey, harness)
        #expect(await eventually(harness) { harness.table.selectedRow == 2 })
        #expect(harness.session.openSourceID == "s1")
        press(NSLeftArrowFunctionKey, harness)
        #expect(await eventually(harness) { harness.table.numberOfRows == 3 })
        #expect(harness.session.openSourceID == nil)
    }

    /// Not a real mouse path (a window that is never shown is sent no events, and a table's mouse-down
    /// runs a tracking loop that would block the main thread): the click is `selectRowIndexes`, the
    /// table's own selection write, with the event the page reads standing in for the click.
    private func select(row: Int, as event: NSEvent?, _ harness: Harness, _ current: EventBox) async {
        current.event = event
        harness.table.selectRowIndexes([row], byExtendingSelection: false)
        try? await Task.sleep(for: .milliseconds(150))
        harness.host.layoutSubtreeIfNeeded()
    }

    private func mouse(
        _ type: NSEvent.EventType, _ modifiers: NSEvent.ModifierFlags = [], clickCount: Int = 1,
        at timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime
    ) -> NSEvent {
        NSEvent.mouseEvent(
            with: type, location: .zero, modifierFlags: modifiers, timestamp: timestamp,
            windowNumber: 0, context: nil, eventNumber: 0, clickCount: clickCount, pressure: 1
        )!
    }

    @MainActor
    private final class EventBox { var event: NSEvent? }

    @Test func aClickOnAClosedSourceSelectsAndOpensIt() async throws {
        let box = EventBox()
        let harness = try await makeHarness(currentEvent: { box.event })
        #expect(harness.session.openSourceID == nil)
        // Rows newest first: s3, s2, s1; s1 is row 2.
        await select(row: 2, as: mouse(.leftMouseDown), harness, box)
        #expect(await waitUntil { harness.session.openSourceID == "s1" })
        #expect(harness.navigation.listAnchor == "s1")
        #expect(await eventually(harness) { harness.table.numberOfRows == 11 })
    }

    /// T-13 (AC-4.11): the first press of a double-click on a Source opens it and closes the Source above,
    /// so it moves up and the second press lands on another row; that press changes nothing.
    @Test func theSecondPressOfADoubleClickLeavesTheAnchorAndTheOpenSource() async throws {
        let box = EventBox()
        let harness = try await makeHarness(rows: 4, open: "s2", currentEvent: { box.event })
        // Rows: s3, s2, g2-0, s1. The first press selects s1 (row 3); s2 closes and s1 opens.
        let first = mouse(.leftMouseDown)
        await select(row: 3, as: first, harness, box)
        #expect(await waitUntil { harness.session.openSourceID == "s1" })
        #expect(await eventually(harness) { harness.table.numberOfRows == 11 })
        #expect(harness.navigation.listAnchor == "s1")
        // Row 3 now draws the first graph of s1. The second press (click count 2) is ignored.
        await select(row: 3, as: mouse(.leftMouseDown, clickCount: 2), harness, box)
        #expect(harness.navigation.listAnchor == "s1")
        #expect(harness.session.openSourceID == "s1")
    }

    /// F-1 (CON-1, CON-3): a double-click whose second press lands on no row, however long after the first.
    @Test func aSecondPressOnNoRowOpensTheFirstRowOnce() async throws {
        let box = EventBox()
        let harness = try await makeHarness(currentEvent: { box.event })
        let root = harness.navigation.currentLocation
        // Rows newest first: s3, s2, s1; s1 is the last row.
        await select(row: 2, as: mouse(.leftMouseDown), harness, box)
        #expect(await waitUntil { harness.session.openSourceID == "s1" })
        #expect(harness.navigation.listAnchor == "s1")
        // A second press well after the first (no time limit between the presses), on empty space.
        try? await Task.sleep(for: .milliseconds(700))
        box.event = mouse(.leftMouseDown, clickCount: 2)
        harness.table.deselectAll(nil)
        let page = SourcesListNavigation.pageLocation(sourceId: "s1", ref: "SRC-S1", title: "Parish register, Lyon")
        #expect(await waitUntil { harness.navigation.currentLocation == page })
        #expect(harness.navigation.currentLocation == page)
        // The press is consumed: another nil write does not open again, and one Back is the list.
        harness.table.deselectAll(nil)
        try? await Task.sleep(for: .milliseconds(150))
        harness.navigation.goBack()
        #expect(harness.navigation.currentLocation == root)
        #expect(!harness.navigation.canGoBack)
    }

    /// F-1 (CON-3): the double action of a second press that landed on another row opens the first row.
    @Test func aDoubleClickOpensTheRowFirstPressedNotTheOneTheSecondLandedOn() async throws {
        let box = EventBox()
        let harness = try await makeHarness(currentEvent: { box.event })
        await select(row: 2, as: mouse(.leftMouseDown), harness, box)
        #expect(await waitUntil { harness.session.openSourceID == "s1" })
        #expect(harness.navigation.listAnchor == "s1")
        // The second press lands on s3 (row 0), well after the first: the selection is not written, and
        // Return stands in for the table's double action on the row it landed on.
        try? await Task.sleep(for: .milliseconds(700))
        box.event = mouse(.leftMouseDown, clickCount: 2)
        harness.table.selectRowIndexes([0], byExtendingSelection: false)
        pressReturn(harness)
        let page = SourcesListNavigation.pageLocation(sourceId: "s1", ref: "SRC-S1", title: "Parish register, Lyon")
        #expect(await waitUntil { harness.navigation.currentLocation == page })
        #expect(harness.navigation.currentLocation == page)
    }

    @Test func aKeyMoveOrAModifiedClickOntoAClosedSourceLeavesItClosed() async throws {
        let box = EventBox()
        let harness = try await makeHarness(currentEvent: { box.event })
        let key = NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: 0, context: nil, characters: "\u{F701}", charactersIgnoringModifiers: "\u{F701}",
            isARepeat: false, keyCode: 125
        )
        await select(row: 1, as: key, harness, box)
        #expect(harness.navigation.listAnchor == "s2")
        await select(row: 2, as: mouse(.leftMouseDown, .command), harness, box)
        #expect(harness.navigation.listAnchor == "s1")
        await select(row: 0, as: mouse(.rightMouseDown), harness, box)
        #expect(harness.navigation.listAnchor == "s3")
        #expect(harness.session.openSourceID == nil)
    }

    /// The graph with no Artifact does not open: the one entry the second Return adds is the only one.
    @Test func returnOpensAGraphThatLinksAnArtifactAndNoOther() async throws {
        let harness = try await makeHarness(rows: 11, open: "s1")
        let root = harness.navigation.currentLocation
        await select("g1-3", row: 6, harness)
        pressReturn(harness)
        await select("g1-0", row: 3, harness)
        pressReturn(harness)
        #expect(await eventually(harness) { harness.navigation.currentLocation.graphId == "g1-0" })
        harness.navigation.goBack()
        #expect(harness.navigation.currentLocation == root.withListScrollAnchor("g1-0"))
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
        #expect(await eventually(harness) { holder(harness) == "table" })
    }

    @Test func aReturningListLeavesTheSearchFieldFocused() async throws {
        let harness = try await makeHarness()
        #expect(await eventually(harness) { holder(harness) == "table" })
        let field = try #require(descendant(NSTextField.self, in: harness.host))
        harness.window.makeFirstResponder(field)
        let editor = try #require(harness.window.fieldEditor(false, for: field) as? NSTextView)
        #expect(holder(harness) == "field")
        editor.insertText("zzzz", replacementRange: NSRange(location: 0, length: 0))
        #expect(await eventually(harness) { descendant(NSTableView.self, in: harness.host) == nil })
        #expect(holder(harness) == "field")
        editor.selectAll(nil)
        editor.insertText("", replacementRange: editor.selectedRange())
        #expect(await eventually(harness) { descendant(NSTableView.self, in: harness.host)?.numberOfRows == 3 })
        // `FocusClaim` writes on the next two turns.
        await mainQueueTurn()
        await mainQueueTurn()
        #expect(holder(harness) == "field")
    }
}
