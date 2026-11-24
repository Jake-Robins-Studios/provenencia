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
                PVListBodyRow(item: item, leadingHang: leadingHang, separator: separator, row: row)
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
        .pvNativeListBehavior(
            ids: items.map(\.id), selection: selection, minimumRowHeight: minimumRowHeight, label: label,
            onActivate: { id in
                if let item = items.first(where: { $0.id == id }) { onActivate(item) }
            },
            menu: { id in
                items.first(where: { $0.id == id }).map(menu) ?? []
            },
            restartKey: restartKey, claimsFocus: claimsFocus
        )
    }
}

/// One row of a `PVListBody`: the caller's row, whether its separator shows, and where it runs: from the
/// `leadingHang` the row draws before its thumbnail to the row's trailing edge, so the rules run gutter to
/// gutter at every row height. A view of its own, so a selection move evaluates the separator only for the
/// rows on screen.
private struct PVListBodyRow<Item: Identifiable, Row: View>: View {
    let item: Item
    let leadingHang: CGFloat
    let separator: (Item) -> Visibility
    let row: (Item) -> Row

    var body: some View {
        row(item)
            .listRowSeparator(separator(item))
            .alignmentGuide(.listRowSeparatorLeading) { [leadingHang] _ in leadingHang }
            .alignmentGuide(.listRowSeparatorTrailing) { $0.width }
    }
}
