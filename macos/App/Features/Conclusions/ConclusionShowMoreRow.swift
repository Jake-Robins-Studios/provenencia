import SwiftUI

/// The "Show N more" row that ends a folded list on a Conclusion page: a plain
/// borderless button that words the next page (`fold.nextPageCount`) and, after a
/// key press, moves the keyboard to the first item the page reveals. Return and
/// Space activate it; a pointer click leaves focus where it is.
struct ConclusionShowMoreRow<Focus: Hashable>: View {
    /// How many items the fold leaves out now (the total, not the page).
    let hidden: Int
    let fold: PagedFold
    /// The section's focus state, where `revealed` and `stop` are values.
    let focus: FocusState<Focus?>.Binding
    /// This row's own value in `focus`, so the section (a restore after Back) can give it the keyboard.
    let stop: Focus
    /// The focus id of the first item the page adds, read from the content that
    /// was drawn; nil when there is nothing to move focus to.
    let revealed: Focus?
    let expand: () -> Void

    var body: some View {
        Button(action: press) {
            Text(verbatim: L10n.Conclusions.showMore(fold.nextPageCount(hidden: hidden)))
        }
        .buttonStyle(.pv(.ghost, size: .sm))
        .focused(focus, equals: stop)
        .pvActivatesOnReturn(when: focus.wrappedValue == stop, press)
    }

    private func press() {
        let claims = focus.wrappedValue == stop
        expand()
        if claims, let revealed { FocusClaim.claim(focus, revealed) }
    }
}
