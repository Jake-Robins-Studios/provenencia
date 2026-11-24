import AppKit
import SwiftUI
import Testing
@testable import Provenencia

/// The Sources table in a real (never shown) window: the columns the platform lays out, and their headers.
@Suite(.serialized, .hostedWindows)
@MainActor
struct SourcesTableHostedTests {
    private let projectDir = "/tmp/table-hosted.provenencia"

    @MainActor @Observable
    final class PaneWidth { var value: CGFloat = 1102 }

    private struct Probe: View {
        let model: SourcesModel
        let session: WorkspaceSession
        let pane: PaneWidth
        @Binding var selection: String?

        var body: some View {
            let widthClass = PVWidthClass(paneWidth: pane.value)
            SourcesTable(
                items: model.outline.items, selection: $selection, model: model,
                isWide: widthClass == .wide, gutter: widthClass.fullPaneGutter
            )
            .frame(width: pane.value, height: 760)
            .environment(session)
            .environment(\.pvWidthClass, widthClass)
        }
    }

    private final class Selection {
        var id: String?
    }

    private struct Harness {
        let window: NSWindow
        let host: NSHostingView<AnyView>
        let table: NSTableView
        let session: WorkspaceSession
        let model: SourcesModel
        let pane: PaneWidth
        let selection: Selection
    }

    private func descendant<V: NSView>(_ type: V.Type, in view: NSView) -> V? {
        if let match = view as? V { return match }
        return view.subviews.lazy.compactMap { descendant(type, in: $0) }.first
    }

    private func makeHarness(width: CGFloat = 1102, selected: String? = nil) async throws -> Harness {
        let store = FakeStore()
        store.sourceTypesByProject[projectDir] = [
            CatalogSourceType(id: "t1", key: "census", origin: "provenencia", label: "Census", description: "")
        ]
        store.sourcesByProject[projectDir] = ["s3", "s2", "s1"].map { id in
            CatalogSource(
                id: id, ref: "SRC-\(id.uppercased())", sourceTypeID: "t1", title: "Source \(id)", description: "",
                date: CatalogDateValueInput(kind: "point", startYear: 1851),
                updated: CatalogActivity(revision: 1, at: "2026-11-21T10:00:00Z"),
                createdAt: "2026-11-19T10:00:00Z"
            )
        }
        let session = WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)
        let model = SourcesModel(session: session, userID: "00000000-0000-7000-8000-000000000001", store: store)
        model.warmListQueries()
        _ = await waitUntil(timeout: .seconds(10)) { model.sources.count == 3 && !model.isAwaitingGraphList }
        let pane = PaneWidth()
        pane.value = width
        let selection = Selection()
        selection.id = selected
        let binding = Binding(get: { selection.id }, set: { selection.id = $0 })
        let view = AnyView(Probe(model: model, session: session, pane: pane, selection: binding))
        let (window, host) = hostInBorderlessWindow(view, windowSize: CGSize(width: 2400, height: 760))
        host.layoutSubtreeIfNeeded()
        var table: NSTableView?
        let found = await waitUntil(timeout: .seconds(10)) {
            host.layoutSubtreeIfNeeded()
            table = descendant(NSTableView.self, in: host)
            return table?.numberOfRows == 3
        }
        #expect(found)
        return Harness(
            window: window, host: host, table: try #require(table), session: session, model: model, pane: pane,
            selection: selection
        )
    }

    private func shown(_ table: NSTableView) -> [(title: String, width: CGFloat)] {
        table.tableColumns.filter { !$0.isHidden }.map { ($0.headerCell.stringValue, $0.width) }
    }

    private func resize(_ harness: Harness, to width: CGFloat) async {
        harness.pane.value = width
        try? await Task.sleep(for: .milliseconds(300))
        harness.host.layoutSubtreeIfNeeded()
    }

    private func expect(
        _ columns: [(title: String, width: CGFloat)], _ want: [(String, CGFloat)],
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(columns.map(\.title) == want.map(\.0), sourceLocation: sourceLocation)
        for (column, expected) in zip(columns, want) {
            #expect(abs(column.width - expected.1) <= 1, "\(column.title) \(column.width)", sourceLocation: sourceLocation)
        }
    }

    private func overflowsSideways(_ table: NSTableView) -> Bool {
        guard let scroll = table.enclosingScrollView else { return false }
        return table.frame.width > scroll.contentView.bounds.width + 1
    }

    /// T-11 (AC-1.1, AC-1.2, AC-1.3, AC-1.8): the columns' titles and widths at each width, across the Wide
    /// breakpoint and back, on one table with its selection.
    @Test func columnsFitTheirWidths() async throws {
        let harness = try await makeHarness(width: 1102, selected: "s2")
        let table = harness.table
        harness.table.selectRowIndexes([1], byExtendingSelection: false)
        let regular: [(String, CGFloat)] = [
            ("TITLE", 364), ("EVIDENCE", 168), ("STATUS", 128), ("PUBLISHED", 96), ("ADDED", 92), ("UPDATED", 92),
        ]
        expect(shown(table), regular)
        #expect(!overflowsSideways(table))

        await resize(harness, to: 2296)
        expect(shown(table), [
            ("TITLE", 1069), ("EVIDENCE", 240), ("STATUS", 140), ("TYPE", 220), ("PUBLISHED", 160), ("ADDED", 120),
            ("UPDATED", 120),
        ])
        #expect(!overflowsSideways(table))
        #expect(table.selectedRow == 1)

        await resize(harness, to: 1102)
        expect(shown(table), regular)
        #expect(!overflowsSideways(table))
        #expect(table.selectedRow == 1)

        await resize(harness, to: 800)
        let narrow = shown(table)
        #expect(narrow.first?.title == "TITLE")
        #expect(abs((narrow.first?.width ?? 0) - 240) <= 1)
        #expect(overflowsSideways(table))
        #expect(descendant(NSTableView.self, in: harness.host) === table)
    }

    private func headerColor(_ table: NSTableView, _ title: String) -> NSColor? {
        guard let column = table.tableColumns.first(where: { $0.headerCell.stringValue == title }) else { return nil }
        let text = column.headerCell.attributedStringValue
        guard text.length > 0 else { return nil }
        return (text.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor)?.usingColorSpace(.sRGB)
    }

    /// T-12 (AC-2.1): the sorted column's header text is one step brighter than the others', and the
    /// brightness moves with the sort.
    @Test func theSortedHeaderIsBrighter() async throws {
        let harness = try await makeHarness()
        let table = harness.table
        func brightest() -> [String] {
            let colors = ["TITLE", "EVIDENCE", "STATUS", "PUBLISHED", "ADDED", "UPDATED"].map { ($0, headerColor(table, $0)) }
            let common = colors.first { $0.0 == "EVIDENCE" }?.1
            return colors.filter { $0.1 != common }.map(\.0)
        }
        // Added, newest first, is the first visit's sort.
        #expect(brightest() == ["ADDED"])
        harness.model.settings.sort = SourcesSort(column: .title, order: .forward)
        let moved = await waitUntil(timeout: .seconds(5)) {
            harness.host.layoutSubtreeIfNeeded()
            return brightest() == ["TITLE"]
        }
        #expect(moved)
        #expect(headerColor(table, "ADDED") == headerColor(table, "UPDATED"))
    }
}
