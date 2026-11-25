import SwiftUI

/// Keeps the keyboard's row in view in a scrolling list. When `row` changes,
/// the enclosing `ScrollView` or `List` scrolls to the row tagged `.id(row)`; with no
/// `anchor` it moves only as far as it must, so a row already on screen (the
/// one the pointer hovers, say) does not move the list.
///
/// A caller that passes `whenRequested` scrolls only when that token changes,
/// not when `row` does; callers with no token scroll on `row` as above.
///
/// Apply it to the `ScrollView` or to the rows inside one. Each row carries
/// `.id(_:)` with the value the caller passes as `row`. `PVTable`, `PVList`,
/// `PVSelect`, `PVComboBox` and the omnibar results all scroll through it.
struct PVScrollRowIntoView<ID: Hashable>: ViewModifier {
    let row: ID?
    let anchor: UnitPoint?
    let animated: Bool
    let scrollsOnAppear: Bool
    let rows: [ID]?
    let restartTop: ID?
    let restartKey: AnyHashable?
    let request: AnyHashable?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        ScrollViewReader { proxy in
            content
                .onChange(of: row, initial: scrollsOnAppear) { _, row in
                    // With a request token, the token alone scrolls: a click that
                    // changes both would scroll twice.
                    guard let row, request == nil else { return }
                    withAnimation(animated && !reduceMotion ? PVMotion.fastStandard : nil) {
                        proxy.scrollTo(row, anchor: anchor)
                    }
                }
                .onChange(of: request) {
                    // The same row again: scrolls on the next main-actor turn, so a
                    // row inserted in the same update (an unfolded list) exists.
                    guard let row else { return }
                    Task { @MainActor in
                        withAnimation(animated && !reduceMotion ? PVMotion.fastStandard : nil) {
                            proxy.scrollTo(row, anchor: anchor)
                        }
                    }
                }
                .onChange(of: rows) { _, rows in
                    // A new list starts at the top. Without this the scroller
                    // keeps the offset the last list left, hiding its first row.
                    guard let first = rows?.first else { return }
                    proxy.scrollTo(first, anchor: .top)
                }
                .onChange(of: restartKey) {
                    // A sort, a filter or an error shown starts again at the top. Never animated.
                    guard let restartTop else { return }
                    proxy.scrollTo(restartTop, anchor: .top)
                }
        }
    }
}

extension View {
    /// Scrolls `row` into view whenever it changes. See `PVScrollRowIntoView`.
    ///
    /// - Parameters:
    ///   - row: The id of the highlighted or selected row, or nil for none.
    ///   - anchor: Where the row lands; nil scrolls only as far as needed.
    ///   - animated: Animates the scroll with `PVMotion.fastStandard`, never
    ///     under Reduce Motion.
    ///   - scrollsOnAppear: Also scrolls when the list first appears, for a
    ///     menu that opens on its current choice.
    ///   - rows: When given, a change in these ids (a new query's results)
    ///     scrolls back to the first row.
    ///   - restartTop: The id of a view at the very top of the scroll content.
    ///   - restartKey: When this changes, scrolls to `restartTop` with no
    ///     animation (a list's sort or filter, a page's error shown). An
    ///     arrival is not one: `pvRemembersScroll` places it.
    ///   - request: When this token changes, scrolls to `row` on the next
    ///     main-actor turn, even if `row` did not change (a second click on the
    ///     same point). The turn lets a row inserted in the same update exist.
    ///     Passing a token turns off scrolling on a change of `row` alone.
    func pvScrollsRowIntoView<ID: Hashable>(
        _ row: ID?,
        anchor: UnitPoint? = nil,
        animated: Bool = true,
        scrollsOnAppear: Bool = false,
        startsAtTopWhenRowsChange rows: [ID]? = nil,
        restartsAt restartTop: ID? = nil,
        whenChanged restartKey: AnyHashable? = nil,
        whenRequested request: AnyHashable? = nil
    ) -> some View {
        modifier(PVScrollRowIntoView(
            row: row,
            anchor: anchor,
            animated: animated,
            scrollsOnAppear: scrollsOnAppear,
            rows: rows,
            restartTop: restartTop,
            restartKey: restartKey,
            request: request
        ))
    }
}

/// Keeps a list's selected row in view as the selection moves. A selection that changes with a new
/// arrival (Back between two entries of a mounted list) is not a move: `pvRemembersScroll` places it.
private struct PVScrollsSelectionIntoView<ID: Hashable>: ViewModifier {
    let selection: ID?
    let animated: Bool
    let restartTop: ID?
    let restartKey: AnyHashable?
    /// The row the selection moved to; nil until it moves within the visit.
    @State private var movedTo: ID?
    @Environment(\.pvScrollMemory) private var memory
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Move: Equatable {
        var selection: ID?
        var arrival: Int?
    }

    func body(content: Content) -> some View {
        ScrollViewReader { proxy in
            content
                .onChange(of: Move(selection: selection, arrival: memory?.arrival)) { old, new in
                    movedTo = old.arrival == new.arrival ? new.selection : nil
                    // Rows between here and there were never drawn: the first scroll lands on their
                    // estimated heights. Once more on the next turn, with the rows drawn, it lands whole.
                    guard let row = movedTo else { return }
                    Task { @MainActor in
                        guard movedTo == row else { return }
                        withAnimation(animated && !reduceMotion ? PVMotion.fastStandard : nil) {
                            proxy.scrollTo(row)
                        }
                    }
                }
                .pvScrollsRowIntoView(movedTo, animated: animated, restartsAt: restartTop, whenChanged: restartKey)
        }
    }
}

extension View {
    /// Scrolls the list's `selection` into view as it moves, but not when it changes with a new arrival.
    /// The parameters are `pvScrollsRowIntoView`'s.
    func pvScrollsSelectionIntoView<ID: Hashable>(
        _ selection: ID?, animated: Bool = true, restartsAt restartTop: ID? = nil, whenChanged restartKey: AnyHashable? = nil
    ) -> some View {
        modifier(PVScrollsSelectionIntoView(
            selection: selection, animated: animated, restartTop: restartTop, restartKey: restartKey
        ))
    }
}

private struct PVScrollRowIntoViewPreview: View {
    @State private var highlighted = 0
    private let rows = Array(0..<30)

    var body: some View {
        VStack(spacing: PVSpacing.space2) {
            HStack {
                Button(action: { highlighted = max(0, highlighted - 1) }) { Text(verbatim: "↑") }
                Button(action: { highlighted = min(rows.count - 1, highlighted + 1) }) { Text(verbatim: "↓") }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(rows, id: \.self) { row in
                        Text(verbatim: "Row \(row)")
                            .padding(PVSpacing.space2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(row == highlighted ? PVColor.surfaceSelected : .clear)
                            .id(row)
                    }
                }
            }
            .frame(height: 160)
            .pvScrollsRowIntoView(highlighted)
        }
        .padding()
        .frame(width: 240)
    }
}

#Preview("Scroll row into view") {
    PVScrollRowIntoViewPreview()
}
