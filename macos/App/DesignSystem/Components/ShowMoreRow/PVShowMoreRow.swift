import SwiftUI

/// The "Show N more" row that ends a list folded by `PagedFold`: a plain borderless
/// button that words the next page (`fold.nextPageCount`) and, after a key press,
/// moves the keyboard to the first item the page reveals and asks `\.pvShowMoreReveal`
/// to scroll it into view. Return and Space activate it; a pointer click neither moves
/// focus nor scrolls. Moved out of `Features/Conclusions` (S15-30).
struct PVShowMoreRow<Focus: Hashable>: View {
    /// How many items the fold leaves out now (the total, not the page).
    let hidden: Int
    let fold: PagedFold
    /// The caller's focus state, where `revealed` and `stop` are values.
    let focus: FocusState<Focus?>.Binding
    /// This row's own value in `focus`, so a restore after Back can give it the keyboard.
    let stop: Focus
    /// The focus value of the first item the page adds, read from the content that
    /// was drawn; nil when there is nothing to move focus to.
    let revealed: Focus?
    /// The `.id` of the first item the page adds, which the reveal scrolls to; nil for no scroll.
    var revealedRow: AnyHashable?
    let expand: () -> Void
    @Environment(\.pvShowMoreReveal) private var reveal

    init(
        hidden: Int,
        fold: PagedFold,
        focus: FocusState<Focus?>.Binding,
        stop: Focus,
        revealed: Focus?,
        revealedRow: AnyHashable? = nil,
        expand: @escaping () -> Void
    ) {
        self.hidden = hidden
        self.fold = fold
        self.focus = focus
        self.stop = stop
        self.revealed = revealed
        self.revealedRow = revealedRow
        self.expand = expand
    }

    var body: some View {
        Button(action: press) {
            Text(verbatim: L10n.DesignSystem.showMoreRowLabel(fold.nextPageCount(hidden: hidden)))
        }
        .buttonStyle(.pv(.ghost, size: .sm))
        .focused(focus, equals: stop)
        .pvActivatesOnReturn(when: focus.wrappedValue == stop, press)
    }

    private func press() {
        let decision = PVShowMorePress(
            startedOnRow: focus.wrappedValue == stop,
            revealed: revealed,
            revealedRow: revealedRow
        )
        expand()
        if let target = decision.focus { FocusClaim.claim(focus, target) }
        if let scroll = decision.scroll { reveal(scroll) }
    }
}

/// What one press of a Show more does: only a press that began with the row focused
/// (a key) moves focus to `revealed` and asks for a scroll to `revealedRow`; a pointer
/// click does neither.
struct PVShowMorePress<Focus: Hashable>: Equatable {
    let focus: Focus?
    let scroll: AnyHashable?

    init(startedOnRow: Bool, revealed: Focus?, revealedRow: AnyHashable?) {
        focus = startedOnRow ? revealed : nil
        scroll = startedOnRow ? revealedRow : nil
    }
}

/// What a Show more calls to scroll its first revealed item into view. The provider
/// above the list owns the scroll, so it outlives the row, which leaves the tree when
/// it reveals the last page. With no provider nothing scrolls.
struct PVShowMoreReveal: Equatable {
    let scroll: @MainActor (AnyHashable) -> Void

    @MainActor
    func callAsFunction(_ row: AnyHashable) {
        scroll(row)
    }

    /// Always equal: a new copy writes to the same provider's state, so an equal value
    /// does not rebuild the rows under it.
    static func == (lhs: PVShowMoreReveal, rhs: PVShowMoreReveal) -> Bool { true }
}

private struct PVShowMoreRevealKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue = PVShowMoreReveal(scroll: { _ in })
}

extension EnvironmentValues {
    var pvShowMoreReveal: PVShowMoreReveal {
        get { self[PVShowMoreRevealKey.self] }
        set { self[PVShowMoreRevealKey.self] = newValue }
    }
}

/// The default provider of `\.pvShowMoreReveal`: scrolls the revealed row into view
/// through `pvScrollsRowIntoView`. Rows carry `.id(_:)` with the value the Show more passes.
private struct PVScrollsShowMoreReveals: ViewModifier {
    @State private var target: AnyHashable?
    @State private var request = 0

    func body(content: Content) -> some View {
        content
            .environment(\.pvShowMoreReveal, PVShowMoreReveal { target = $0; request += 1 })
            .pvScrollsRowIntoView(target, whenRequested: request)
    }
}

extension View {
    /// Scrolls the first item a keyboard Show more reveals into view. Apply it to the
    /// scroll view or the rows inside one. See `PVShowMoreRow`.
    func pvScrollsShowMoreReveals() -> some View {
        modifier(PVScrollsShowMoreReveals())
    }
}

#Preview("Show more row") {
    struct Demo: View {
        @State private var folds = PagedFoldState<Int>()
        @FocusState private var focus: Int?
        private let fold = PagedFold(limit: 5, minimumHidden: 2)
        private let rows = Array(0 ..< 12)

        var body: some View {
            let page = fold.shown(rows, pages: folds.pages(0))
            let first = fold.firstRevealed(rows, pages: folds.pages(0))
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(page.shown, id: \.self) { index in
                        Text(verbatim: "Row \(index)").frame(height: 60).id(index)
                    }
                    if page.hidden > 0 {
                        PVShowMoreRow(
                            hidden: page.hidden, fold: fold, focus: $focus, stop: -1,
                            revealed: first, revealedRow: first.map(AnyHashable.init)
                        ) { folds.revealPage(0) }
                    }
                }
            }
            .pvScrollsShowMoreReveals()
            .frame(width: 300, height: 200)
        }
    }
    return Demo()
}
