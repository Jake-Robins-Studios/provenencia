import SwiftUI

/// A request to scroll a native list to a row. Each is its own value: asking for a row again scrolls again.
struct PVListScroll<ID: Hashable>: Hashable {
    let row: ID
    var anchor: UnitPoint?
    var isRepeat = false
    private let token = UUID()
}

/// The kit's behavior around a platform list or table (SwiftUI's `List` or `Table`, an `NSTableView`).
/// Selection, ↑ / ↓, Page Up / Page Down and scrolling come from the platform. A click selects (the
/// system's full-width bar); a double-click or Return opens (`onActivate`). Home and End scroll to the
/// first and last row. The list takes keyboard focus when it appears (unless `claimsFocus` is false: a
/// page that mounts its list again while the researcher is typing in a field above it keeps that field)
/// and keeps the selected row in view as it moves (it does not scroll on arrival: a page's scroll view
/// restores its remembered y, `pvRemembersScroll`). A right-click offers `menu(id)` as the platform's own context menu: one native button per
/// `PVActionMenuItem`, a divider between sections. The list is its own scroll view and draws no
/// background (the caller hides the platform's): its area draws the card fill, so nothing covers the
/// system selection. Nothing may pad between the list and this behavior: its scroll memory finds the
/// list's scroll view by its frame.
///
/// `ids` are the rows in order; `onActivate` and `menu` are called only with an id in `ids`, so a caller
/// maps an id to its item. `minimumRowHeight` is the mouse wheel's step. A change of `restartKey` scrolls
/// the list to its first row, with no animation; a new `reveal` scrolls to its row. Apply it with
/// `pvNativeListBehavior`.
struct PVNativeListBehavior<ID: Hashable>: ViewModifier {
    let ids: [ID]
    let selection: Binding<ID?>
    let minimumRowHeight: CGFloat
    let label: LocalizedStringResource
    let onActivate: (ID) -> Void
    let menu: (ID) -> [[PVActionMenuItem]]
    let restartKey: AnyHashable?
    let claimsFocus: Bool
    let reveal: PVListScroll<ID>?

    @FocusState private var isFocused: Bool
    /// The last scroll asked for: Home or End, or `reveal`.
    @State private var scroll: PVListScroll<ID>?

    func body(content: Content) -> some View {
        content
            .pvRemembersScroll()
            // The table's row height sets the mouse wheel's step.
            .environment(\.defaultMinListRowHeight, minimumRowHeight)
            .focusEffectDisabled()
            .focused($isFocused)
            .onAppear {
                if claimsFocus { FocusClaim.claim($isFocused, true) }
            }
            .contextMenu(forSelectionType: ID.self, menu: { chosen in
                menuContent(for: chosen)
            }, primaryAction: { chosen in
                if let id = chosen.first, ids.contains(id) { onActivate(id) }
            })
            .onKeyPress(keys: [.home, .end]) { press in
                guard let index = PVListKeyboard.moveIndex(
                    for: press.key, option: false, index: 0, count: ids.count
                ), ids.indices.contains(index) else { return .ignored }
                scroll = PVListScroll(row: ids[index], anchor: press.key == .home ? .top : .bottom)
                return .handled
            }
            .pvScrollsSelectionIntoView(
                selection.wrappedValue, animated: false, restartsAt: ids.first, whenChanged: restartKey
            )
            .onChange(of: reveal) { scroll = reveal }
            .pvScrollsRowIntoView(scroll?.row, anchor: scroll?.anchor, animated: false, whenRequested: scroll)
            .task(id: scroll) { await repeatScroll() }
    }

    /// Scrolls once more, unless another scroll was asked for (it cancels this one) or the selection
    /// moved: a table's first scroll to a row far from the drawn ones can stop short while the rows between
    /// are undrawn.
    private func repeatScroll() async {
        guard let scroll, !scroll.isRepeat else { return }
        let selected = selection.wrappedValue
        try? await Task.sleep(for: .milliseconds(150))
        guard !Task.isCancelled, selection.wrappedValue == selected else { return }
        self.scroll?.isRepeat = true
    }

    /// The right-clicked row's menu: nothing for no row, a row the list no longer has, or no entries.
    @ViewBuilder
    private func menuContent(for chosen: Set<ID>) -> some View {
        if let id = chosen.first(where: { ids.contains($0) }) {
            let sections = menu(id).filter { !$0.isEmpty }
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

extension View {
    /// The kit's native list behavior around a `List` or `Table`. See `PVNativeListBehavior`.
    func pvNativeListBehavior<ID: Hashable>(
        ids: [ID],
        selection: Binding<ID?>,
        minimumRowHeight: CGFloat,
        label: LocalizedStringResource,
        onActivate: @escaping (ID) -> Void,
        menu: @escaping (ID) -> [[PVActionMenuItem]] = { _ in [] },
        restartKey: AnyHashable? = nil,
        claimsFocus: Bool = true,
        reveal: PVListScroll<ID>? = nil
    ) -> some View {
        modifier(PVNativeListBehavior(
            ids: ids, selection: selection, minimumRowHeight: minimumRowHeight, label: label,
            onActivate: onActivate, menu: menu, restartKey: restartKey, claimsFocus: claimsFocus, reveal: reveal
        ))
        .accessibilityLabel(Text(label))
    }
}
