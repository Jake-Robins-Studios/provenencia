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
        @State private var selection: String? = "s2"

        var body: some View {
            let widthClass = PVWidthClass(paneWidth: pane.value)
            SourcesTable(
                items: model.outline.items, selection: $selection, model: model,
                gutter: widthClass.fullPaneGutter
            )
            .frame(width: pane.value, height: 760)
            .environment(session)
            .environment(\.pvWidthClass, widthClass)
        }
    }

    private struct Harness {
        let host: NSHostingView<AnyView>
        let table: NSTableView
        let model: SourcesModel
        let pane: PaneWidth
    }

    private func makeHarness() async throws -> Harness {
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
        let view = AnyView(Probe(model: model, session: session, pane: pane))
        let (_, host) = hostInBorderlessWindow(view, windowSize: CGSize(width: 2400, height: 760))
        host.layoutSubtreeIfNeeded()
        var table: NSTableView?
        let found = await waitUntil(timeout: .seconds(10)) {
            host.layoutSubtreeIfNeeded()
            table = descendant(NSTableView.self, in: host)
            return table?.numberOfRows == 3
        }
        #expect(found)
        return Harness(host: host, table: try #require(table), model: model, pane: pane)
    }

    private func shown(_ table: NSTableView) -> [(title: String, width: CGFloat)] {
        table.tableColumns.filter { !$0.isHidden }.map { ($0.headerCell.stringValue, $0.width) }
    }

    /// The table at `width`, once its shown columns are `want` and it scrolls sideways or not.
    private func expectColumns(
        _ harness: Harness, at width: CGFloat, _ want: [(String, CGFloat)], overflows: Bool = false,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        harness.pane.value = width
        let table = harness.table
        let settled = await waitUntil(timeout: .seconds(10)) {
            harness.host.layoutSubtreeIfNeeded()
            let columns = shown(table)
            return columns.map(\.title) == want.map(\.0)
                && zip(columns, want).allSatisfy { abs($0.width - $1.1) <= 1 }
                && overflowsSideways(table) == overflows
        }
        #expect(
            settled, "\(shown(table)), sideways \(overflowsSideways(table))", sourceLocation: sourceLocation
        )
        #expect(table.selectedRow == 1, sourceLocation: sourceLocation)
        #expect(descendant(NSTableView.self, in: harness.host) === table, sourceLocation: sourceLocation)
    }

    private func overflowsSideways(_ table: NSTableView) -> Bool {
        guard let scroll = table.enclosingScrollView else { return false }
        return table.frame.width > scroll.contentView.bounds.width + 1
    }

    /// AC-1.1, AC-1.2, AC-1.3, AC-1.8: the columns' titles and widths at each width, across the Wide
    /// breakpoint and back, on one table with its selection.
    @Test func columnsFitTheirWidths() async throws {
        let harness = try await makeHarness()
        let regular: [(String, CGFloat)] = [
            ("TITLE", 352), ("EVIDENCE", 168), ("STATUS", 128), ("PUBLISHED", 96), ("ADDED", 98), ("UPDATED", 98),
        ]
        await expectColumns(harness, at: 1102, regular)
        await expectColumns(harness, at: 2296, [
            ("TITLE", 1069), ("EVIDENCE", 240), ("STATUS", 140), ("TYPE", 220), ("PUBLISHED", 160), ("ADDED", 120),
            ("UPDATED", 120),
        ])
        await expectColumns(harness, at: 1102, regular)
        // Type is hidden below Wide; every other column keeps its width and the table scrolls sideways.
        await expectColumns(harness, at: 800, [("TITLE", 240)] + regular.dropFirst(), overflows: true)
    }

    private func headerColor(_ table: NSTableView, _ title: String) -> NSColor? {
        guard let column = table.tableColumns.first(where: { $0.headerCell.stringValue == title }) else { return nil }
        let text = column.headerCell.attributedStringValue
        guard text.length > 0 else { return nil }
        return (text.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor)?.usingColorSpace(.sRGB)
    }

    /// AC-2.1: the sorted column's header text is one step brighter than the others', and the
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
        let moved = await waitUntil(timeout: .seconds(10)) {
            harness.host.layoutSubtreeIfNeeded()
            return brightest() == ["TITLE"]
        }
        #expect(moved)
        #expect(headerColor(table, "ADDED") == headerColor(table, "UPDATED"))
    }

    /// AC-2.2: a header click writes the sort; Evidence and Status are not sortable.
    @Test func aHeaderClickSortsAndEvidenceStatusAndTypeDoNot() async throws {
        let harness = try await makeHarness()
        let title = try #require(harness.table.tableColumns.first { $0.headerCell.stringValue == "TITLE" })
        harness.table.sortDescriptors = [try #require(title.sortDescriptorPrototype)]
        #expect(await waitUntil(timeout: .seconds(10)) {
            harness.model.settings.sort == SourcesSort(column: .title, order: .forward)
        })
        for name in ["EVIDENCE", "STATUS"] {
            #expect(harness.table.tableColumns.first { $0.headerCell.stringValue == name }?.sortDescriptorPrototype == nil)
        }
    }
}
