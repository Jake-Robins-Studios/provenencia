import SwiftUI

/// The kit's behavior around a platform list or table (SwiftUI's `List` or `Table`, an `NSTableView`).
/// Selection, ↑ / ↓, Page Up / Page Down and scrolling come from the platform. A click selects (the
/// system's full-width bar); a double-click or Return opens (`onActivate`). Home and End scroll to the
/// first and last row. The list takes keyboard focus when it appears (unless `claimsFocus` is false: a
/// page that mounts its list again while the researcher is typing in a field above it keeps that field)
/// and scrolls a selected row into view when it appears and when its row arrives after the selection was
/// set. A right-click offers `menu(id)` as the platform's own context menu: one native button per
/// `PVActionMenuItem`, a divider between sections. The list is its own scroll view and draws no
/// background (the caller hides the platform's): its area draws the card fill, so nothing covers the
/// system selection.
///
/// `ids` are the rows in order; `onActivate` and `menu` are called only with an id in `ids`, so a caller
/// maps an id to its item. `minimumRowHeight` is the mouse wheel's step. A change of `restartKey` scrolls
/// the list to its first row, with no animation. Apply it with `pvNativeListBehavior`.
struct PVNativeListBehavior<ID: Hashable>: ViewModifier {
    let ids: [ID]
    let selection: Binding<ID?>
    let minimumRowHeight: CGFloat
    let label: LocalizedStringResource
    let onActivate: (ID) -> Void
    let menu: (ID) -> [[PVActionMenuItem]]
    let restartKey: AnyHashable?
    let claimsFocus: Bool

    /// How long after a request the list scrolls once more: a table's first scroll to a row far from the
    /// drawn ones can stop short while the rows between are undrawn, and the second one lands it.
    static var settleDelay: TimeInterval { 0.15 }

    /// Runs `again` once, `settleDelay` after now, when `stillWanted` is still true then (the request was
    /// not replaced by another).
    static func repeatOnce(stillWanted: @escaping () -> Bool, _ again: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + settleDelay) {
            if stillWanted() { again() }
        }
    }

    @FocusState private var isFocused: Bool
    @State private var edgeRow: ID?
    @State private var edgeAnchor: UnitPoint = .top
    @State private var edgeRequest = 0
    @State private var selectionRequest = 0

    func body(content: Content) -> some View {
        content
            // The table's row height sets the mouse wheel's step.
            .environment(\.defaultMinListRowHeight, minimumRowHeight)
            .focusEffectDisabled()
            .focused($isFocused)
            .onAppear {
                if claimsFocus { FocusClaim.claim($isFocused, true) }
                requestSelectionScroll()
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
                edgeRow = ids[index]
                edgeAnchor = press.key == .home ? .top : .bottom
                edgeRequest += 1
                requestEdgeScroll()
                return .handled
            }
            .pvScrollsRowIntoView(edgeRow, anchor: edgeAnchor, animated: false, whenRequested: edgeRequest)
            .pvScrollsRowIntoView(
                selection.wrappedValue, animated: false, scrollsOnAppear: true,
                restartsAt: ids.first, whenChanged: restartKey
            )
            // A selection set before its row exists (Back to a row inside a closed group) scrolls a turn
            // after the row appears.
            .onChange(of: ids) { old, new in
                guard let id = selection.wrappedValue, new.contains(id), !old.contains(id) else { return }
                requestSelectionScroll()
            }
            .pvScrollsRowIntoView(selection.wrappedValue, animated: false, whenRequested: selectionRequest)
    }

    /// Asks for the selection to be scrolled into view a turn later, and once more after `settleDelay`
    /// when the selection is still the one requested. A row already in view does not move.
    private func requestSelectionScroll() {
        guard let requested = selection.wrappedValue else { return }
        selectionRequest += 1
        let binding = selection
        Self.repeatOnce(stillWanted: { binding.wrappedValue == requested }) {
            selectionRequest += 1
        }
    }

    /// Scrolls to the Home or End row once more after `settleDelay`, when no other Home or End press
    /// came and the selection has not moved since. A first scroll to the last row of a long list stops
    /// short.
    private func requestEdgeScroll() {
        guard let requested = edgeRow else { return }
        let request = edgeRequest
        let binding = selection
        let selected = binding.wrappedValue
        Self.repeatOnce(stillWanted: {
            edgeRow == requested && edgeRequest == request && binding.wrappedValue == selected
        }) {
            edgeRequest += 1
        }
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
        claimsFocus: Bool = true
    ) -> some View {
        modifier(PVNativeListBehavior(
            ids: ids, selection: selection, minimumRowHeight: minimumRowHeight, label: label,
            onActivate: onActivate, menu: menu, restartKey: restartKey, claimsFocus: claimsFocus
        ))
        .accessibilityLabel(Text(label))
    }
}
