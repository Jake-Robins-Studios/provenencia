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

    private func makeHarness(
        width: CGFloat = 1102, expanded: [String] = [], extraSources: Int = 0, anchor: String? = nil,
        currentEvent: @escaping @MainActor @Sendable () -> NSEvent? = { nil }
    ) async throws -> Harness {
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
        // Ids sort after "s": they list before the three below in the newest-added order.
        let extras = (0 ..< extraSources).map { source("x\(String(format: "%02d", $0))", "Extra \($0)", artifact: false) }
        store.sourcesByProject[projectDir] = extras.reversed() + [
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
        session.setOpenSource(expanded.first)
        let navigation = WorkspaceNavigation()
        if let anchor { navigation.noteListAnchor(anchor) }
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
        host.layoutSubtreeIfNeeded()
        var table: NSTableView?
        // The skeleton table has rows too: the loaded one is the one with this many.
        let loaded = 3 + extraSources + (expanded.first == "s1" ? 8 : expanded.first == "s2" ? 1 : 0)
            + (anchor?.hasPrefix("g1-") == true ? 8 : 0)
        let found = await waitUntil(timeout: .seconds(10)) {
            host.layoutSubtreeIfNeeded()
            table = descendant(NSTableView.self, in: host)
            return (table?.numberOfRows ?? 0) == loaded
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
        harness.session.setOpenSource("s1")
        #expect(await settle(harness, rows: 11))
        // The newest-added order: s3, s2, s1 are ids descending; s1 is last with its 8 graphs under it.
        #expect(heights(harness.table) == [66, 66, 66] + Array(repeating: 34, count: 8))
        let rects = (0 ..< harness.table.numberOfRows).map { harness.table.rect(ofRow: $0) }
        for (above, below) in zip(rects, rects.dropFirst()) {
            #expect(above.maxY <= below.minY + 0.5)
        }
        // The table adds its padding to the least row height it is given: the step is the graph row's
        // 26 pt of content.
        #expect(harness.scroll.verticalLineScroll == SourcesTable.graphRowHeight)
    }

    @Test func aSelectedGraphRowIsSelectedInItsOpenSource() async throws {
        let harness = try await makeHarness(expanded: ["s1"])
        #expect(await settle(harness, rows: 11))
        harness.navigation.noteListAnchor("g1-2")
        #expect(await waitUntil { harness.host.layoutSubtreeIfNeeded(); return harness.table.selectedRow == 5 })
        #expect(harness.table.selectedRow == 5)
    }

    @Test func anAnchorOnAGraphOfAClosedSourceOpensTheSourceAndSelectsTheGraph() async throws {
        let harness = try await makeHarness()
        #expect(harness.session.openSourceID == nil)
        harness.navigation.noteListAnchor("g1-2")
        #expect(await settle(harness, rows: 11))
        #expect(harness.session.openSourceID == "s1")
        #expect(await waitUntil { harness.host.layoutSubtreeIfNeeded(); return harness.table.selectedRow == 5 })
        #expect(harness.table.selectedRow == 5)
    }

    @Test func anAnchorSetBeforeThePageIsHostedOpensTheSourceAndScrollsTheGraphIntoView() async throws {
        // 15 Source rows above s1 push its graphs past the 760 pt window.
        let harness = try await makeHarness(extraSources: 15, anchor: "g1-7")
        #expect(await settle(harness, rows: 15 + 3 + 8))
        #expect(harness.session.openSourceID == "s1")
        let graphRow = 15 + 3 + 7
        #expect(await waitUntil {
            harness.host.layoutSubtreeIfNeeded()
            return harness.table.selectedRow == graphRow
                && harness.table.visibleRect.intersects(harness.table.rect(ofRow: graphRow))
        })
        #expect(harness.table.selectedRow == graphRow)
        #expect(harness.table.visibleRect.intersects(harness.table.rect(ofRow: graphRow)))
        // Off screen before the reveal: the top of the list is not what is shown.
        #expect(harness.scroll.contentView.bounds.minY > 0)
    }

    /// The page's one path for closing a Source (the triangle, the keys and the VoiceOver action
    /// all call it): a selected graph of the Source gives way to the Source itself.
    @Test func closingTheSourceOfASelectedGraphSelectsTheSource() async throws {
        let harness = try await makeHarness(expanded: ["s1"])
        #expect(await settle(harness, rows: 11))
        harness.navigation.noteListAnchor("g1-2")
        #expect(await waitUntil { harness.host.layoutSubtreeIfNeeded(); return harness.table.selectedRow == 5 })
        var s1 = CatalogSource(
            id: "s1", ref: "SRC-S1", sourceTypeID: "t1", title: "Parish register, Lyon", description: "",
            date: CatalogDateValueInput(kind: "point", startYear: 1851),
            updated: CatalogActivity(revision: 1, at: "2026-11-21T10:00:00Z")
        )
        s1.hasArtifact = true
        let outline = SourcesOutline(
            sources: [s1], graphs: { harness.session.evidenceGraphsRead(sourceID: $0) }, open: "s1"
        )
        outline.setOpen(nil, session: harness.session, navigation: harness.navigation)
        #expect(await settle(harness, rows: 3))
        #expect(harness.session.openSourceID == nil)
        #expect(harness.navigation.listAnchor == "s1")
        #expect(await waitUntil { harness.host.layoutSubtreeIfNeeded(); return harness.table.selectedRow == 2 })
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
        #expect(harness.session.openSourceID == "s1")
        #expect(await settle(harness, rows: 11))
        harness.navigation.noteListAnchor("g1-2")
        _ = await waitUntil { harness.host.layoutSubtreeIfNeeded(); return harness.table.selectedRow == 5 }
        await press(NSLeftArrowFunctionKey, harness)
        #expect(harness.navigation.listAnchor == "s1")
        #expect(harness.session.openSourceID == "s1")
        await press(NSLeftArrowFunctionKey, harness)
        #expect(harness.session.openSourceID == nil)
        #expect(await settle(harness, rows: 3))
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
        #expect(await settle(harness, rows: 11))
    }

    /// T-13 (AC-4.11): the first press of a double-click on a Source opens it and closes the Source above,
    /// so it moves up and the second press lands on another row; that press changes nothing.
    @Test func theSecondPressOfADoubleClickLeavesTheAnchorAndTheOpenSource() async throws {
        let box = EventBox()
        let harness = try await makeHarness(expanded: ["s2"], currentEvent: { box.event })
        // Rows: s3, s2, g2-0, s1. The first press selects s1 (row 3); s2 closes and s1 opens.
        let first = mouse(.leftMouseDown)
        await select(row: 3, as: first, harness, box)
        #expect(await waitUntil { harness.session.openSourceID == "s1" })
        #expect(await settle(harness, rows: 3 + 8))
        #expect(harness.navigation.listAnchor == "s1")
        // Row 3 now draws the first graph of s1. The second press (click count 2) is ignored.
        // (Its time is set 0.2 s after the first press: the waits above take longer than a double-click.)
        await select(row: 3, as: mouse(.leftMouseDown, clickCount: 2, at: first.timestamp + 0.2), harness, box)
        #expect(harness.navigation.listAnchor == "s1")
        #expect(harness.session.openSourceID == "s1")
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
        // Only the row's lower band is drawn and read: a whole-table bitmap read pixel by pixel blocks the
        // main thread for seconds on a slow runner.
        let row = table.rect(ofRow: row)
        let band = NSRect(x: 0, y: row.minY + row.height * 0.6, width: table.bounds.width, height: row.height * 0.4)
        guard let rep = table.bitmapImageRepForCachingDisplay(in: band), let data = rep.bitmapData else { return nil }
        table.cacheDisplay(in: band, to: rep)
        let scale = CGFloat(rep.pixelsWide) / band.width
        let alphaOffset = rep.bitmapFormat.contains(.alphaFirst) ? 0 : rep.samplesPerPixel - 1
        var best: ClosedRange<Int>?
        for y in 0 ..< rep.pixelsHigh {
            var first: Int?
            var last = 0
            var count = 0
            let line = data + y * rep.bytesPerRow
            for x in 0 ..< rep.pixelsWide where line[x * rep.samplesPerPixel + alphaOffset] > 13 {
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

    /// A plain list (the Persons list's shape): its rules run gutter to gutter.
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
