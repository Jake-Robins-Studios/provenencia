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

    @MainActor @Observable
    final class PaneWidth { var value: CGFloat = 1102 }

    /// The page at a pane width a test changes: the width class follows it, as the workspace's pane does.
    private struct ResizingPane: View {
        let pane: PaneWidth
        let content: (PVWidthClass) -> AnyView

        var body: some View {
            content(PVWidthClass(paneWidth: pane.value))
                .frame(width: pane.value, height: 760)
        }
    }

    private struct Harness {
        let window: NSWindow
        let host: NSHostingView<AnyView>
        let session: WorkspaceSession
        let navigation: WorkspaceNavigation
        let table: NSTableView
        let scroll: NSScrollView
        let store: FakeStore
    }

    private func descendant<V: NSView>(_ type: V.Type, in view: NSView) -> V? {
        if let match = view as? V { return match }
        return view.subviews.lazy.compactMap { descendant(type, in: $0) }.first
    }

    private func makeHarness(
        width: CGFloat = 1102, expanded: [String] = [], extraSources: Int = 0, tailSources: Int = 0, mixedGraphs: Bool = false,
        anchor: String? = nil, height: CGFloat = 760,
        currentEvent: @escaping @MainActor @Sendable () -> NSEvent? = { nil }, withHistory: Bool = false,
        pane: PaneWidth? = nil, configure: (FakeStore) -> Void = { _ in }
    ) async throws -> Harness {
        let store = FakeStore()
        configure(store)
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
        // Ids sort before "s": they list after s1 and its graphs, newest first.
        let tail = (0 ..< tailSources).map { source("a\(String(format: "%02d", $0))", "Tail \($0)", artifact: true) }
        store.sourcesByProject[projectDir] = extras.reversed() + tail.reversed() + [
            source("s3", "Passport of J. Robins", artifact: false),
            source("s2", "1851 Census, Robins household", artifact: true),
            source("s1", "Parish register, Lyon", artifact: true),
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
        } + [CatalogEvidenceGraph(
            id: "g2-0", ref: "GPH-20", sourceID: "s2", name: "Default", description: "", artifactIDs: ["a-s2"]
        )] + tail.enumerated().flatMap { index, owner in
            (0 ..< (mixedGraphs ? Self.graphCount(tail: index) : 1)).map { graph in
                CatalogEvidenceGraph(
                    id: "gt-\(owner.id)-\(graph)", ref: "GPT-\(owner.id)-\(graph)", sourceID: owner.id,
                    name: "Default", description: "", artifactIDs: ["a-\(owner.id)"]
                )
            }
        }
        store.graphProgressByGraph["g1-0"] = EvidenceGraphProgress(graphId: "g1-0", subjectCount: 12, observationCount: 40)
        let session = WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)
        session.setOpenSource(expanded.first)
        let navigation = WorkspaceNavigation()
        if withHistory {
            navigation.attachProject(
                uuid: UUID().uuidString,
                fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).json")
            )
        }
        if let anchor { navigation.noteListAnchor(anchor) }
        let page: (PVWidthClass) -> AnyView = { widthClass in
            AnyView(
                SourcesListView(
                    session: session, userID: "00000000-0000-7000-8000-000000000001",
                    projectUuid: UUID().uuidString, store: store
                )
                .environment(session)
                .environment(navigation)
                .environment(\.pvWidthClass, widthClass)
                .environment(\.sourcesCurrentEvent, SourcesEventSource(currentEvent))
            )
        }
        let view: AnyView
        let windowSize: CGSize
        if let pane {
            pane.value = width
            view = AnyView(ResizingPane(pane: pane, content: page))
            windowSize = CGSize(width: 2400, height: 760)
        } else {
            view = page(PVWidthClass(paneWidth: width))
            windowSize = CGSize(width: width, height: height)
        }
        let (window, host) = hostInBorderlessWindow(view, windowSize: windowSize)
        host.layoutSubtreeIfNeeded()
        var table: NSTableView?
        // The skeleton table has rows too: the loaded one is the one with this many.
        let loaded = 3 + extraSources + tailSources + (expanded.first == "s1" ? 8 : expanded.first == "s2" ? 1 : 0)
            + (anchor?.hasPrefix("g1-") == true ? 8 : 0)
        let found = await waitUntil(timeout: .seconds(10)) {
            host.layoutSubtreeIfNeeded()
            table = descendant(NSTableView.self, in: host)
            return (table?.numberOfRows ?? 0) == loaded
        }
        #expect(found)
        let tableView = try #require(table)
        let scroll = try #require(tableView.enclosingScrollView)
        return Harness(
            window: window, host: host, session: session, navigation: navigation, table: tableView, scroll: scroll, store: store
        )
    }

    /// How many graphs a tail Source has in a `mixedGraphs` harness.
    private static func graphCount(tail index: Int) -> Int { [1, 8, 3, 5, 2][index % 5] }

    /// The table has `rows` rows, and a turn has passed for each cell to take its height
    /// (`SourcesRowHeight`).
    private func settle(_ harness: Harness, rows: Int) async -> Bool {
        let arrived = await waitUntil(timeout: .seconds(10)) {
            harness.host.layoutSubtreeIfNeeded()
            return harness.table.numberOfRows == rows
        }
        try? await Task.sleep(for: .milliseconds(50))
        harness.host.layoutSubtreeIfNeeded()
        return arrived
    }

    private func heights(_ table: NSTableView) -> [CGFloat] {
        (0 ..< table.numberOfRows).map { table.rect(ofRow: $0).height }
    }

    @Test func closedSourcesAreOneRowEach() async throws {
        let harness = try await makeHarness()
        #expect(await settle(harness, rows: 3))
        #expect(heights(harness.table) == [66, 66, 66])
        #expect(harness.navigation.listAnchor == nil)
    }

    @Test func openSourceDrawsItsGraphsAtTheirOwnHeightAndTheWheelStepIsAGraphRow() async throws {
        let harness = try await makeHarness()
        harness.session.setOpenSource("s1")
        #expect(await settle(harness, rows: 11))
        // The newest-added order: s3, s2, s1 are ids descending; s1 is last with its 8 graphs under it.
        #expect(heights(harness.table) == [66, 66, 66] + Array(repeating: 34, count: 8))
        let rects = (0 ..< harness.table.numberOfRows).map { harness.table.rect(ofRow: $0) }
        for (above, below) in zip(rects, rects.dropFirst()) {
            #expect(above.maxY <= below.minY + 0.5)
        }
        #expect(harness.scroll.verticalLineScroll == 34)
    }

    /// What is wrong with the rows the table has drawn: each Source is 66 pt and each row under the open one
    /// 34 pt, as the table places it and as it and its cells are drawn. `sources` are the listed Sources in
    /// order, `under` the rows under the open one.
    private func wrongRows(_ harness: Harness, sources: [String], under: Int) -> [String] {
        let table = harness.table
        let open = harness.session.openSourceID.flatMap { sources.firstIndex(of: $0) }
        let lower = open.map { $0 + 1 } ?? 0
        guard table.numberOfRows == sources.count + under else { return ["\(table.numberOfRows) rows"] }
        var drawn = 0
        var wrong: [String] = []
        for row in 0 ..< table.numberOfRows {
            let isUnder = row >= lower && row < lower + under
            // A row scrolled out and never drawn has no measured height: the platform estimates it.
            guard let view = table.rowView(atRow: row, makeIfNecessary: false) else { continue }
            drawn += 1
            let want: CGFloat = isUnder ? 34 : 66
            var heights = [table.rect(ofRow: row).height, view.frame.height]
            for column in 0 ..< table.numberOfColumns {
                if let cell = view.view(atColumn: column) as? NSView { heights.append(cell.frame.height) }
            }
            if heights.contains(where: { abs($0 - want) > 0.5 }) { wrong.append("row \(row) wants \(want): \(heights)") }
        }
        // The window is taller than 10 Sources: a table that draws nothing proves nothing.
        return drawn >= 10 || drawn == table.numberOfRows ? wrong : wrong + ["only \(drawn) rows drawn"]
    }

    /// The slowest `expectRowHeights` settle of the run, and its step: a passing CI log shows how late the
    /// platform's rows are.
    private static var slowestSettle: (step: String, seconds: Double) = ("", 0)

    /// Every row the table has drawn takes its height: each turn lays out and reads `wrongRows`, until none
    /// is wrong (at most 5 s), and the result is read again one turn later. A failure says which rows, how
    /// late, and whether a scroll away and back, or `noteHeightOfRows`, would have corrected them.
    private func expectRowHeights(
        _ harness: Harness, _ step: String, sources: [String], under: Int,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        let clock = ContinuousClock()
        let start = clock.now
        func elapsed() -> Double {
            let parts = (clock.now - start).components
            return Double(parts.seconds) + Double(parts.attoseconds) / 1e18
        }
        func read() -> [String] {
            harness.host.layoutSubtreeIfNeeded()
            return wrongRows(harness, sources: sources, under: under)
        }
        var wrong = read()
        while !wrong.isEmpty, elapsed() < 5 {
            try? await Task.sleep(for: .milliseconds(10))
            wrong = read()
        }
        let took = elapsed()
        if wrong.isEmpty {
            // Right now: is it right one turn later?
            try? await Task.sleep(for: .milliseconds(50))
            wrong = read()
        }
        if took > Self.slowestSettle.seconds { Self.slowestSettle = (step, took) }
        print("expectRowHeights slowest settle so far: \(Self.slowestSettle.step) \(Self.slowestSettle.seconds) s")
        guard !wrong.isEmpty || took > 0.2 else { return }
        let report = "\(step): settled in \(took) s (\(wrong.isEmpty ? "right" : "still wrong")); each row lists rect(ofRow:), the row view, then every cell height: \(wrong)"
        if !wrong.isEmpty {
            let table = harness.table
            let rows = wrong.compactMap { line -> Int? in
                line.hasPrefix("row ") ? Int(line.dropFirst(4).prefix { $0.isNumber }) : nil
            }
            // Diagnosis only, after the failure is recorded below.
            Issue.record(Comment(rawValue: report), sourceLocation: sourceLocation)
            let origin = harness.scroll.contentView.bounds.origin
            harness.scroll.contentView.scroll(to: NSPoint(x: 0, y: origin.y + 1500))
            harness.scroll.reflectScrolledClipView(harness.scroll.contentView)
            harness.host.layoutSubtreeIfNeeded()
            harness.scroll.contentView.scroll(to: origin)
            harness.scroll.reflectScrolledClipView(harness.scroll.contentView)
            harness.host.layoutSubtreeIfNeeded()
            try? await Task.sleep(for: .milliseconds(100))
            let afterScroll = read()
            table.noteHeightOfRows(withIndexesChanged: IndexSet(rows))
            try? await Task.sleep(for: .milliseconds(100))
            let afterNote = read()
            let scrolled = afterScroll.isEmpty ? "corrected" : "still wrong \(afterScroll)"
            let noted = afterNote.isEmpty ? "corrected" : "still wrong \(afterNote)"
            Issue.record(
                Comment(rawValue: "\(step) diagnosis: after a scroll away and back \(scrolled); after noteHeightOfRows \(noted)"),
                sourceLocation: sourceLocation
            )
            return
        }
        // Settled right, but over 200 ms: a passing run names the step.
        print("expectRowHeights late: \(report)")
    }

    /// U-1 (AC-1.6): the platform reuses a row's cells for a row of the other height as Sources open and
    /// close, and every row still draws at its own.
    @Test func everyRowIsItsOwnHeightHoweverTheRowsMove() async throws {
        let harness = try await makeHarness(
            extraSources: 5, tailSources: 30, mixedGraphs: true, height: 1300,
            configure: { $0.listEvidenceGraphProgressHold.isOn = true }
        )
        let table = harness.table
        // Newest added first: the Sources with no Artifact, s3 (none either), s2 (1 graph), s1 (8), the tail.
        let tail = (0 ..< 30).reversed().map { "a\(String(format: "%02d", $0))" }
        let newest = (0 ..< 5).reversed().map { "x0\($0)" } + ["s3", "s2", "s1"] + tail
        func under(_ id: String) -> Int {
            if id == "s1" { return 8 }
            if id == "s2" { return 1 }
            return Self.graphCount(tail: Int(id.dropFirst()) ?? 0)
        }
        func open(_ id: String, _ step: String, _ sources: [String]) async {
            harness.session.setOpenSource(id)
            await expectRowHeights(harness, "\(step) \(id)", sources: sources, under: under(id))
        }
        await expectRowHeights(harness, "closed", sources: newest, under: 0)

        // The graph list is late, then the counts.
        let project = projectDir
        let all = try #require(harness.store.evidenceGraphsByProject[project])
        func readGraphs(_ graphs: [CatalogEvidenceGraph]) {
            harness.store.evidenceGraphsByProject[project] = graphs
            harness.session.invalidate(harness.session.evidenceGraphsKey)
            let _: QueryHandle<[CatalogEvidenceGraph]> = harness.session.query(harness.session.evidenceGraphsKey)
        }
        readGraphs(all.filter { $0.sourceID != "a26" })
        harness.session.setOpenSource("a26")
        await expectRowHeights(harness, "graphs pending", sources: newest, under: 1)
        readGraphs(all)
        await expectRowHeights(harness, "late graphs", sources: newest, under: under("a26"))
        harness.store.listEvidenceGraphProgressHold.isOn = false
        while harness.store.listEvidenceGraphProgressHold.count > 0 { harness.store.listEvidenceGraphProgressHold.release() }
        await expectRowHeights(harness, "late counts", sources: newest, under: under("a26"))

        for id in ["a29", "a28", "a27", "a26", "s1", "a24", "s2", "a25", "a21", "a26"] { await open(id, "open", newest) }
        // With the list scrolled, and the open Source off the top and off the bottom.
        harness.scroll.contentView.scroll(to: NSPoint(x: 0, y: 500))
        harness.scroll.reflectScrolledClipView(harness.scroll.contentView)
        for id in ["a21", "a24", "s1", "a22", "a26", "a11", "a21"] { await open(id, "scrolled", newest) }

        // Sorted by title, as a header click writes it: the list is back at its top, the Source still open.
        let byTitle = ["s2"] + (0 ..< 5).map { "x0\($0)" } + ["s1", "s3"]
            + (0 ..< 30).sorted { "\($0)" < "\($1)" }.map { "a\(String(format: "%02d", $0))" }
        let title = try #require(table.tableColumns.first { $0.headerCell.stringValue == "TITLE" })
        table.sortDescriptors = [try #require(title.sortDescriptorPrototype)]
        await expectRowHeights(harness, "sorted", sources: byTitle, under: under("a21"))
        for id in ["a01", "s1", "a03", "a00", "a01"] { await open(id, "sorted", byTitle) }

        // Filtered, and the filter cleared.
        let field = try #require(descendant(NSTextField.self, in: harness.host))
        harness.window.makeFirstResponder(field)
        let editor = try #require(harness.window.fieldEditor(false, for: field) as? NSTextView)
        editor.insertText("Tail 1", replacementRange: NSRange(location: 0, length: 0))
        let filtered = ["a01"] + (10 ..< 20).map { "a\($0)" }
        await expectRowHeights(harness, "filtered", sources: filtered, under: under("a01"))
        for id in ["a11", "a16", "a11"] { await open(id, "filtered", filtered) }
        editor.selectAll(nil)
        editor.insertText("", replacementRange: editor.selectedRange())
        await expectRowHeights(harness, "filter cleared", sources: byTitle, under: under("a11"))

        // Every row of the list, as it is drawn on the way down and back.
        let frame = harness.scroll.contentView.bounds.height
        for y in [0, 1, 2, 1, 0].map({ CGFloat($0) * frame }) {
            harness.scroll.contentView.scroll(to: NSPoint(x: 0, y: y))
            harness.scroll.reflectScrolledClipView(harness.scroll.contentView)
            await expectRowHeights(harness, "scrolled to \(y)", sources: byTitle, under: under("a11"))
        }
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

    /// Where the viewport stands on Back is the Spike 16 PR that records a scroll offset in history
    /// (AC-4.7 and AC-4.8 "in view", moved by the user, 2026-11-24).
    @Test func anAnchorSetBeforeThePageIsHostedOpensTheSourceAndSelectsTheGraph() async throws {
        // 15 Source rows above s1 push its graphs past the 760 pt window.
        let harness = try await makeHarness(extraSources: 15, anchor: "g1-7")
        #expect(await settle(harness, rows: 15 + 3 + 8))
        #expect(harness.session.openSourceID == "s1")
        let graphRow = 15 + 3 + 7
        #expect(await waitUntil { harness.host.layoutSubtreeIfNeeded(); return harness.table.selectedRow == graphRow })
        #expect(harness.table.selectedRow == graphRow)
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

    /// F-2 (UX-1): the Source above closes as this one opens, the rows move up, and the opened row is
    /// scrolled back into view. (The triangle's open runs the same `apply(.expand)` line.)
    @Test func aSourceThatOpensStaysInView() async throws {
        // s3, s2, s1 and its 8 graphs, then the tail: its first row, a09, lies just under the graphs.
        let harness = try await makeHarness(expanded: ["s1"], tailSources: 10)
        #expect(await settle(harness, rows: 3 + 8 + 10))
        let graphsEnd = harness.table.rect(ofRow: 10).maxY
        // The list scrolled so the graphs are partly above the viewport and a09 is just under them.
        harness.scroll.contentView.scroll(to: NSPoint(x: 0, y: graphsEnd - 170))
        harness.scroll.reflectScrolledClipView(harness.scroll.contentView)
        harness.navigation.noteListAnchor("a09")
        #expect(await waitUntil { harness.host.layoutSubtreeIfNeeded(); return harness.table.selectedRow == 11 })
        try? await Task.sleep(for: .milliseconds(400))
        harness.host.layoutSubtreeIfNeeded()
        #expect(harness.scroll.documentVisibleRect.intersects(harness.table.rect(ofRow: 11)))
        await press(NSRightArrowFunctionKey, harness)
        #expect(harness.session.openSourceID == "a09")
        #expect(await settle(harness, rows: 3 + 1 + 10))
        let row = 3
        #expect(harness.table.selectedRow == row)
        #expect(await waitUntil {
            harness.host.layoutSubtreeIfNeeded()
            let rect = harness.table.rect(ofRow: row)
            return harness.scroll.documentVisibleRect.contains(rect)
        })
        #expect(harness.scroll.documentVisibleRect.contains(harness.table.rect(ofRow: row)))
    }

    /// F-8 (CON-6): across the Wide breakpoint and back, with a Source open and a row selected mid-list,
    /// the platform keeps the scroll position (within a row), the keyboard, the selection and the open Source.
    @Test func resizingAcrossTheWideBreakpointKeepsTheScrollTheSelectionAndTheOpenSource() async throws {
        let pane = PaneWidth()
        let harness = try await makeHarness(expanded: ["s1"], extraSources: 15, pane: pane)
        #expect(await settle(harness, rows: 15 + 3 + 8))
        // Newest first: x14 ... x00 are rows 0 to 14; x07 is row 7.
        harness.navigation.noteListAnchor("x07")
        #expect(await waitUntil { harness.host.layoutSubtreeIfNeeded(); return harness.table.selectedRow == 7 })
        harness.window.makeFirstResponder(harness.table)
        harness.scroll.contentView.scroll(to: NSPoint(x: 0, y: 300))
        harness.scroll.reflectScrolledClipView(harness.scroll.contentView)
        try? await Task.sleep(for: .milliseconds(300))
        let before = harness.scroll.contentView.bounds.minY
        #expect(before == 300)

        for width in [1800, 1102] as [CGFloat] {
            pane.value = width
            try? await Task.sleep(for: .milliseconds(400))
            harness.host.layoutSubtreeIfNeeded()
            #expect(abs(harness.scroll.contentView.bounds.minY - before) <= SourcesTable.sourceRowHeight + 8, "scroll at \(width)")
            #expect(harness.table.selectedRow == 7, "selection at \(width)")
            #expect(harness.navigation.listAnchor == "x07")
            #expect(harness.session.openSourceID == "s1")
            #expect(holder(harness) == "table", "keyboard at \(width)")
        }
        #expect(descendant(NSTableView.self, in: harness.host) === harness.table)
    }

    private func keyEvent(_ key: Int, in window: NSWindow) -> NSEvent {
        let character = String(Character(UnicodeScalar(key)!))
        return NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [.numericPad, .function], timestamp: 0,
            windowNumber: window.windowNumber, context: nil, characters: character,
            charactersIgnoringModifiers: character, isARepeat: false,
            keyCode: key == NSRightArrowFunctionKey ? 124 : key == NSEndFunctionKey ? 119 : key == NSHomeFunctionKey ? 115 : 123
        )!
    }

    private func press(_ key: Int, _ harness: Harness) async {
        harness.window.makeFirstResponder(harness.table)
        harness.window.sendEvent(keyEvent(key, in: harness.window))
        try? await Task.sleep(for: .milliseconds(100))
        harness.host.layoutSubtreeIfNeeded()
    }

    /// U-3 (QCK-1, QCK-4): End at a large catalog reaches the last row once the rows have settled, and
    /// Home the first. The scroll repeats once after `settleDelay`, since the first can stop short while
    /// the rows below are undrawn.
    @Test func endReachesTheLastRowAndHomeTheFirstAtAHundredSources() async throws {
        let harness = try await makeHarness(extraSources: 100)
        let last = 102
        #expect(await settle(harness, rows: 103))
        await press(NSEndFunctionKey, harness)
        #expect(await waitUntil(timeout: .seconds(3)) {
            harness.host.layoutSubtreeIfNeeded()
            return harness.scroll.documentVisibleRect.contains(harness.table.rect(ofRow: last))
        })
        try? await Task.sleep(for: .milliseconds(500))
        harness.host.layoutSubtreeIfNeeded()
        #expect(harness.scroll.documentVisibleRect.contains(harness.table.rect(ofRow: last)))
        await press(NSHomeFunctionKey, harness)
        try? await Task.sleep(for: .milliseconds(500))
        harness.host.layoutSubtreeIfNeeded()
        #expect(harness.scroll.documentVisibleRect.contains(harness.table.rect(ofRow: 0)))
    }

    /// U-4: a selection that moves after End, before the repeat, wins: the repeat does not pull the
    /// list back to the last row.
    @Test func aSelectionMoveAfterEndCancelsTheRepeat() async throws {
        let harness = try await makeHarness(extraSources: 100)
        #expect(await settle(harness, rows: 103))
        harness.window.makeFirstResponder(harness.table)
        harness.window.sendEvent(keyEvent(NSEndFunctionKey, in: harness.window))
        // The first scroll lands; the selection moves before `settleDelay` (as an arrow key does) and the
        // table scrolls to it.
        try? await Task.sleep(for: .milliseconds(50))
        harness.navigation.noteListAnchor("x95")
        #expect(await waitUntil { harness.host.layoutSubtreeIfNeeded(); return harness.table.selectedRow >= 0 })
        let row = harness.table.selectedRow
        harness.table.scrollRowToVisible(row)
        try? await Task.sleep(for: .milliseconds(600))
        harness.host.layoutSubtreeIfNeeded()
        #expect(harness.table.selectedRow == row)
        #expect(harness.scroll.documentVisibleRect.contains(harness.table.rect(ofRow: row)))
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
        await select(row: 3, as: mouse(.leftMouseDown, clickCount: 2), harness, box)
        #expect(harness.navigation.listAnchor == "s1")
        #expect(harness.session.openSourceID == "s1")
    }

    /// F-1 (CON-1, CON-3): a double-click whose second press lands on no row, however long after the first.
    @Test func aSecondPressOnNoRowOpensTheFirstRowOnce() async throws {
        let box = EventBox()
        let harness = try await makeHarness(currentEvent: { box.event }, withHistory: true)
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
        harness.window.makeFirstResponder(harness.table)
        let returnKey = NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0,
            windowNumber: harness.window.windowNumber, context: nil, characters: "\r",
            charactersIgnoringModifiers: "\r", isARepeat: false, keyCode: 36
        )!
        harness.window.sendEvent(returnKey)
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
