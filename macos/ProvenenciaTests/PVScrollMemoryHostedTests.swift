import AppKit
import Observation
import SwiftUI
import Testing
@testable import Provenencia

/// The kit's scroll memory in real (never shown) windows: the probe finds each container's scroll view,
/// restores its y once the content fits, and reports the y as the researcher scrolls.
@Suite(.serialized, .hostedWindows)
@MainActor
struct PVScrollMemoryHostedTests {
    private static let second = PVScrollSlot(rawValue: "second")

    /// What the workspace host would hand the page: one visit, the y each slot was left at.
    @MainActor
    @Observable
    final class Memory {
        var arrival = 1
        var offsets: [PVScrollSlot: Double] = [:]
        var tall = true
        var selection: String?
        @ObservationIgnored var noted: [Double] = []
    }

    private struct Harness<Content: View>: View {
        let memory: Memory
        let content: Content

        var body: some View {
            let arrival = memory.arrival
            content.environment(
                \.pvScrollMemory,
                PVScrollMemory(arrival: arrival, offsets: memory.offsets) { [weak memory] slot, y in
                    if slot == .page, arrival == memory?.arrival { memory?.noted.append(y) }
                }
            )
        }
    }

    private struct Row: Identifiable {
        let id: String
    }

    private func host<V: View>(_ memory: Memory, _ content: V) -> (NSWindow, NSHostingView<some View>) {
        hostInBorderlessWindow(Harness(memory: memory, content: content), windowSize: CGSize(width: 800, height: 600))
    }

    private func scrollViews(in view: NSView) -> [NSScrollView] {
        ((view as? NSScrollView).map { [$0] } ?? []) + view.subviews.flatMap { scrollViews(in: $0) }
    }

    private func y(_ scrollView: NSScrollView) -> Double {
        Double(scrollView.contentView.bounds.minY + scrollView.contentView.contentInsets.top)
    }

    private func firstScrollView(_ host: NSView) -> NSScrollView? {
        scrollViews(in: host).first
    }

    /// Lays out until `condition` holds. The 10 s are only how long a failure takes.
    private func eventually(_ host: NSView, _ condition: () -> Bool) async -> Bool {
        await waitUntil(timeout: .seconds(10)) {
            host.layoutSubtreeIfNeeded()
            return condition()
        }
    }

    private func mainQueueTurn() async {
        await withCheckedContinuation { turn in DispatchQueue.main.async { turn.resume() } }
    }

    private func scroll(_ scrollView: NSScrollView, to y: Double) {
        let clip = scrollView.contentView
        clip.scroll(to: NSPoint(x: 0, y: y - clip.contentInsets.top))
        scrollView.reflectScrolledClipView(clip)
    }

    private func column(rows: Int, rowHeight: CGFloat = 30) -> some View {
        VStack(spacing: 0) {
            ForEach(0 ..< rows, id: \.self) { index in
                Text(verbatim: "Row \(index)").frame(height: rowHeight).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func list(_ memory: Memory) -> some View {
        PVListFixture(memory: memory)
    }

    private struct PVListFixture: View {
        @Bindable var memory: Memory
        let items = (0 ..< 200).map { Row(id: "row\($0)") }

        var body: some View {
            PVList(
                items: items,
                selection: $memory.selection,
                thumbnail: { _ in Color.clear },
                label: L10n.Workspace.personsTitle,
                itemAccessibilityLabel: { $0.id },
                onActivate: { _ in },
                primary: { Text(verbatim: $0.id) },
                secondary: { _ in EmptyView() }
            )
        }
    }

    private struct TableFixture: View {
        @Bindable var memory: Memory
        let rows = (0 ..< 200).map { Row(id: "row\($0)") }

        var body: some View {
            Table(rows, selection: $memory.selection) {
                TableColumn(Text(verbatim: "Name")) { Text(verbatim: $0.id) }
            }
            .pvNativeListBehavior(
                ids: rows.map(\.id), selection: $memory.selection, minimumRowHeight: 30,
                label: L10n.Workspace.personsTitle, onActivate: { _ in }
            )
        }
    }

    /// D-1, D-5, AC-1.2: a page restores the y it was left at.
    @Test func pageColumnsRestoreTheirY() async throws {
        let memory = Memory()
        memory.offsets = [.page: 400]
        let (_, host) = host(memory, PVPageColumns(primary: { column(rows: 100) }))
        #expect(await eventually(host) { firstScrollView(host).map { y($0) } == 400 })
    }

    /// AC-1.1: a list restores its y.
    @Test func aListRestoresItsY() async throws {
        let memory = Memory()
        memory.offsets = [.page: 400]
        let (_, host) = host(memory, list(memory).frame(height: 600))
        #expect(await eventually(host) { descendant(NSTableView.self, in: host)?.enclosingScrollView.map { y($0) } == 400 })
    }

    /// D-3: a platform table's scroll view is found from its background, and its y reads 0 at the top
    /// whatever its header's inset.
    @Test func aTableRestoresItsYUnderItsHeader() async throws {
        let top = Memory()
        let (_, topHost) = host(top, TableFixture(memory: top).frame(height: 600))
        #expect(await eventually(topHost) { descendant(NSTableView.self, in: topHost)?.numberOfRows == 200 })
        let scrollView = try #require(descendant(NSTableView.self, in: topHost)?.enclosingScrollView)
        #expect(y(scrollView) == 0)

        let memory = Memory()
        memory.offsets = [.page: 400]
        let (_, tableHost) = host(memory, TableFixture(memory: memory).frame(height: 600))
        #expect(await eventually(tableHost) {
            descendant(NSTableView.self, in: tableHost)?.enclosingScrollView.map { y($0) } == 400
        })
    }

    /// AC-1.7: rows that arrive late move the list once, when they fit.
    @Test func lateRowsMoveTheListOnce() async throws {
        let memory = Memory()
        memory.offsets = [.page: 400]
        memory.tall = false
        let (_, host) = host(memory, PVPageColumns(primary: { LateRows(memory: memory) }))
        #expect(await eventually(host) { firstScrollView(host) != nil })
        await mainQueueTurn()
        #expect(firstScrollView(host).map { y($0) } == 0)
        memory.tall = true
        #expect(await eventually(host) { firstScrollView(host).map { y($0) } == 400 })
        #expect(memory.noted == [400])
    }

    private struct LateRows: View {
        @Bindable var memory: Memory

        var body: some View {
            VStack(spacing: 0) {
                ForEach(0 ..< (memory.tall ? 100 : 10), id: \.self) { index in
                    Text(verbatim: "Row \(index)").frame(height: 30).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    /// AC-1.8: a researcher who scrolls before the rows arrive is not jumped when they do.
    @Test func aScrollBeforeTheRowsArriveWins() async throws {
        let memory = Memory()
        memory.offsets = [.page: 2000]
        memory.tall = false
        // 40 rows: scrollable, but not to 2000.
        let (_, host) = host(memory, PVPageColumns(primary: { LateRows40(memory: memory) }))
        #expect(await eventually(host) { firstScrollView(host)?.documentView?.frame.height ?? 0 > 800 })
        let scrollView = try #require(firstScrollView(host))
        scroll(scrollView, to: 50)
        #expect(await eventually(host) { y(scrollView) == 50 })
        memory.tall = true
        #expect(await eventually(host) { (scrollView.documentView?.frame.height ?? 0) > 3000 })
        await mainQueueTurn()
        host.layoutSubtreeIfNeeded()
        #expect(y(scrollView) == 50)
    }

    private struct LateRows40: View {
        @Bindable var memory: Memory

        var body: some View {
            VStack(spacing: 0) {
                ForEach(0 ..< (memory.tall ? 200 : 40), id: \.self) { index in
                    Text(verbatim: "Row \(index)").frame(height: 30).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    /// D-6: a new arrival restores its own y on the mounted view.
    @Test func aNewArrivalRearms() async throws {
        let memory = Memory()
        memory.offsets = [.page: 400]
        let (_, host) = host(memory, PVPageColumns(primary: { column(rows: 100) }))
        #expect(await eventually(host) { firstScrollView(host).map { y($0) } == 400 })
        memory.arrival = 2
        memory.offsets = [.page: 250]
        #expect(await eventually(host) { firstScrollView(host).map { y($0) } == 250 })
    }

    /// AC-1.10: a view reused by a new arrival with no y returns to the top.
    @Test func aReusedScrollViewReturnsToTheTop() async throws {
        let memory = Memory()
        memory.offsets = [.page: 400]
        let (_, host) = host(memory, PVPageColumns(primary: { column(rows: 100) }))
        #expect(await eventually(host) { firstScrollView(host).map { y($0) } == 400 })
        memory.arrival = 2
        memory.offsets = [:]
        #expect(await eventually(host) { firstScrollView(host).map { y($0) } == 0 })
    }

    /// D-4: a container inside one that remembers the page does not claim the page.
    @Test func aNestedContainerIsNotClaimed() async throws {
        let memory = Memory()
        let nested = PVPageColumns(primary: {
            ScrollView { column(rows: 40) }
                .frame(height: 200)
                .pvRemembersScroll()
        })
        let (_, host) = host(memory, nested)
        #expect(await eventually(host) { scrollViews(in: host).count == 2 })
        let inner = try #require(scrollViews(in: host).first { $0.frame.height < 250 })
        scroll(inner, to: 30)
        #expect(y(inner) == 30)
        await mainQueueTurn()
        #expect(memory.noted.isEmpty)
    }

    /// D-4: a second scroll view on a page is a slot of its own.
    @Test func aSecondSlotIsRememberedApart() async throws {
        let memory = Memory()
        memory.offsets = [.page: 200, Self.second: 300]
        let (_, host) = host(memory, HStack(spacing: 0) {
            ScrollView { column(rows: 100) }.pvRemembersScroll(.page).frame(width: 400)
            ScrollView { column(rows: 100) }.pvRemembersScroll(Self.second).frame(width: 400)
        })
        #expect(await eventually(host) {
            let views = scrollViews(in: host).sorted { $0.frame.minX < $1.frame.minX }
            return views.count == 2 && y(views[0]) == 200 && y(views[1]) == 300
        })
    }

    /// D-12: a selection that changes with the arrival (Back between two entries of a mounted list) is
    /// the restore's to place; the list does not scroll to it.
    @Test func aSelectionSetByBackDoesNotScrollTheMountedList() async throws {
        let memory = Memory()
        let (_, host) = host(memory, list(memory).frame(height: 600))
        #expect(await eventually(host) { descendant(NSTableView.self, in: host)?.numberOfRows == 200 })
        memory.arrival = 2
        memory.offsets = [.page: 400]
        memory.selection = "row90"
        let scrollView = try #require(descendant(NSTableView.self, in: host)?.enclosingScrollView)
        #expect(await eventually(host) { y(scrollView) == 400 })
        await mainQueueTurn()
        await mainQueueTurn()
        host.layoutSubtreeIfNeeded()
        #expect(y(scrollView) == 400)
    }

    // MARK: A selection that is a place

    /// `PVTable` whose selected row is a place, as Metadata's and Properties' are. The selection follows
    /// the location one update late, as their models do.
    private struct PlaceTableFixture: View {
        let navigation: WorkspaceNavigation
        let rows = (0 ..< 200).map { Row(id: "row\($0)") }
        @State private var selection: String?

        var body: some View {
            PVTable(
                rows: rows,
                columns: [PVTableColumn(id: "n", title: L10n.Metadata.columnLabel) { Text(verbatim: $0.id) }],
                selection: $selection, primaryText: { $0.id },
                label: L10n.Workspace.metadataTitle, content: { EmptyView() }
            )
            .onChange(of: navigation.currentLocation) { selection = navigation.currentLocation.fieldId }
            .environment(\.pvScrollMemory, navigation.scrollMemory)
            .frame(height: 600)
        }
    }

    private func place(_ row: String) -> WorkspaceLocation {
        WorkspaceLocation(section: .metadata, fieldId: row)
    }

    /// Selecting a row that is a place keeps the table where it is; Back shows the y the other row was
    /// left at, not the row.
    @Test func selectingARowThatIsAPlaceKeepsTheTablesY() async throws {
        let navigation = WorkspaceNavigation()
        navigation.attachProject(
            uuid: UUID().uuidString,
            fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).json")
        )
        navigation.go(to: .sectionRoot(.metadata))
        let (_, host) = hostInBorderlessWindow(
            PlaceTableFixture(navigation: navigation), windowSize: CGSize(width: 800, height: 600)
        )
        #expect(await eventually(host) { (firstScrollView(host)?.documentView?.frame.height ?? 0) > 3000 })
        let table = try #require(firstScrollView(host))
        navigation.go(to: place("row30"))
        scroll(table, to: 1000)
        #expect(await eventually(host) { y(table) == 1000 })
        navigation.go(to: place("row40"))
        for _ in 0 ..< 5 {
            await mainQueueTurn()
            host.layoutSubtreeIfNeeded()
        }
        #expect(y(table) > 500)

        scroll(table, to: 3000)
        navigation.go(to: place("row90"))
        navigation.goBack()
        navigation.goBack()
        #expect(await eventually(host) { y(table) == 1000 })
        for _ in 0 ..< 5 {
            await mainQueueTurn()
            host.layoutSubtreeIfNeeded()
        }
        #expect(y(table) == 1000)
    }
}
