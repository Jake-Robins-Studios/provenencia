import SwiftUI

/// The native list body behind `PVList` and any list of rows that own their height: the platform's own
/// list (SwiftUI's `List`, an `NSTableView`) with the kit's behavior around it. Selection, ↑ / ↓, Page Up
/// / Page Down and scrolling come from the platform. A click selects (the system's full-width bar); a
/// double-click or Return opens (`onActivate`). Home and End scroll to the first and last row. The list
/// takes keyboard focus when it appears (unless `claimsFocus` is false: a page that mounts its list again
/// while the researcher is typing in a field above it keeps that field) and scrolls a selected row into view when it appears and when
/// its row arrives after the selection was set. A right-click offers `menu(item)` as the platform's own
/// context menu: one native button per `PVActionMenuItem`, a divider between sections. The list is its
/// own scroll view and draws no background: its area draws the card fill, so nothing covers the system
/// selection.
///
/// A row builder returns the row's view, which pads itself and applies its own accessibility; the body
/// sets only the horizontal insets (`PVListMetrics`), so rows of different heights share one list.
/// `minimumRowHeight` is the mouse wheel's step. `leadingHang` is how far the rows draw before their
/// thumbnails (`PVListMetrics.hang`), so the thumbnails sit `horizontalInset` from the list's edge.
/// A change of `restartKey` scrolls the list to its first row, with no animation.
struct PVListBody<Item: Identifiable, Row: View>: View {
    private let items: [Item]
    private let selection: Binding<Item.ID?>
    private let minimumRowHeight: CGFloat
    private let horizontalInset: CGFloat
    private let leadingHang: CGFloat
    private let label: LocalizedStringResource
    private let onActivate: (Item) -> Void
    private let menu: (Item) -> [[PVActionMenuItem]]
    private let separator: (Item) -> Visibility
    private let restartKey: AnyHashable?
    private let claimsFocus: Bool
    private let row: (Item) -> Row

    @FocusState private var isFocused: Bool
    @State private var edgeRow: Item.ID?
    @State private var edgeAnchor: UnitPoint = .top
    @State private var edgeRequest = 0
    @State private var selectionRequest = 0

    init(
        items: [Item],
        selection: Binding<Item.ID?>,
        minimumRowHeight: CGFloat,
        horizontalInset: CGFloat,
        leadingHang: CGFloat = 0,
        label: LocalizedStringResource,
        onActivate: @escaping (Item) -> Void,
        menu: @escaping (Item) -> [[PVActionMenuItem]] = { _ in [] },
        separator: @escaping (Item) -> Visibility = { _ in .visible },
        restartKey: AnyHashable? = nil,
        claimsFocus: Bool = true,
        @ViewBuilder row: @escaping (Item) -> Row
    ) {
        self.items = items
        self.selection = selection
        self.minimumRowHeight = minimumRowHeight
        self.horizontalInset = horizontalInset
        self.leadingHang = leadingHang
        self.label = label
        self.onActivate = onActivate
        self.menu = menu
        self.separator = separator
        self.restartKey = restartKey
        self.claimsFocus = claimsFocus
        self.row = row
    }

    var body: some View {
        List(selection: selection) {
            ForEach(items) { item in
                PVListBodyRow(item: item, separator: separator, row: row)
            }
            // On the `ForEach`, not in its closure: a selection move re-runs the closure for every
            // row, so a modifier inside it runs for rows far off screen. The insets are horizontal
            // only: a row pads itself, so rows of different heights share the list.
            .listRowInsets(EdgeInsets(
                top: 0,
                leading: PVListMetrics.leadingInset(horizontalInset: horizontalInset, leadingHang: leadingHang),
                bottom: 0,
                trailing: PVListMetrics.trailingInset(horizontalInset: horizontalInset)
            ))
            .listRowSeparatorTint(PVColor.borderSubtle)
            .transaction { $0.animation = nil }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        // The table's row height sets the mouse wheel's step.
        .environment(\.defaultMinListRowHeight, minimumRowHeight)
        .focusEffectDisabled()
        .focused($isFocused)
        .onAppear {
            if claimsFocus { FocusClaim.claim($isFocused, true) }
        }
        .contextMenu(forSelectionType: Item.ID.self, menu: { ids in
            menuContent(for: ids)
        }, primaryAction: { ids in
            open(ids.first)
        })
        .onKeyPress(keys: [.home, .end]) { press in
            guard let index = PVListKeyboard.moveIndex(
                for: press.key, option: false, index: 0, count: items.count
            ), items.indices.contains(index) else { return .ignored }
            edgeRow = items[index].id
            edgeAnchor = press.key == .home ? .top : .bottom
            edgeRequest += 1
            return .handled
        }
        .pvScrollsRowIntoView(edgeRow, anchor: edgeAnchor, animated: false, whenRequested: edgeRequest)
        .pvScrollsRowIntoView(
            selection.wrappedValue, animated: false, scrollsOnAppear: true,
            restartsAt: items.first?.id, whenChanged: restartKey
        )
        // A selection set before its row exists (Back to a row inside a closed group) scrolls a turn
        // after the row appears.
        .onChange(of: items.map(\.id)) { old, new in
            guard let id = selection.wrappedValue, new.contains(id), !old.contains(id) else { return }
            selectionRequest += 1
        }
        .pvScrollsRowIntoView(selection.wrappedValue, animated: false, whenRequested: selectionRequest)
        .accessibilityLabel(Text(label))
    }

    /// Opens the item with `id`; nothing when a reload has removed it.
    private func open(_ id: Item.ID?) {
        guard let item = item(id) else { return }
        onActivate(item)
    }

    private func item(_ id: Item.ID?) -> Item? {
        guard let id else { return nil }
        return items.first { $0.id == id }
    }

    /// The right-clicked row's menu: nothing for no row, a row the list no longer has, or no entries.
    @ViewBuilder
    private func menuContent(for ids: Set<Item.ID>) -> some View {
        if let item = ids.lazy.compactMap({ self.item($0) }).first {
            let sections = menu(item).filter { !$0.isEmpty }
            ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                if index > 0 { Divider() }
                ForEach(Array(section.enumerated()), id: \.offset) { _, entry in
                    // Verbatim: a title built from a name (`Open **a**`) is not Markdown.
                    Button { entry.action() } label: { Text(verbatim: L10n.string(entry.title)) }
                        .disabled(!entry.isEnabled)
                        .accessibilityIdentifier(entry.accessibilityIdentifier ?? "")
                }
            }
        }
    }
}

/// One row of a `PVListBody`: the caller's row, and whether its separator shows. A view of its own, so
/// a selection move evaluates the separator only for the rows on screen.
private struct PVListBodyRow<Item: Identifiable, Row: View>: View {
    let item: Item
    let separator: (Item) -> Visibility
    let row: (Item) -> Row

    var body: some View {
        row(item)
            .listRowSeparator(separator(item))
    }
}
