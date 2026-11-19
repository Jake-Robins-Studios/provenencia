import SwiftUI

/// Where Back puts the scroll and the keyboard for a `ConclusionSectionAnchor`: the stop that
/// takes the keyboard (a row, a tile, or the Show more of a fold that hides it) and the id of
/// the view to scroll to. A section's content answers this from the ids its build keeps.
struct ConclusionAnchorTarget<Stop: Hashable>: Equatable {
    var stop: Stop
    var scrollID: String
}

extension View {
    /// Back or Forward to the page entry that opened a place from one of this section's rows
    /// scrolls to that row and gives it the keyboard, once per mount (a page mounts per entity,
    /// a section per switch), the first time `isReady` is true. A later reload or fold change
    /// never moves the keyboard. An anchor of another part, or one `resolve` finds nothing for,
    /// leaves the page at its top. A fold is never revealed: `resolve` names its Show more.
    ///
    /// - Parameters:
    ///   - parts: The anchor parts this site restores.
    ///   - isReady: True once the stops exist to take the keyboard.
    ///   - focus: The section's focus state.
    ///   - keeper: The section's `FocusKeeper`, when it has one; the stop is handed through it.
    ///   - map: Names the stop that can take the keyboard in place of the target's (with `keeper`).
    ///   - scrollAnchor: Where the row lands; nil scrolls only as far as needed.
    ///   - scroll: Replaces the modifier's own scroll (a section that scrolls once placed).
    ///   - resolve: The target for an anchor of `parts`, or nil when its row is gone.
    func conclusionAnchorRestore<Stop: Hashable>(
        _ parts: Set<ConclusionSectionAnchor.Part>,
        isReady: Bool,
        focus: FocusState<Stop?>.Binding,
        keeper: Binding<FocusKeeper<Stop>>? = nil,
        map: @escaping (Stop) -> Stop = { $0 },
        scrollAnchor: UnitPoint? = nil,
        scroll: ((String) -> Void)? = nil,
        resolve: @escaping (ConclusionSectionAnchor) -> ConclusionAnchorTarget<Stop>?
    ) -> some View {
        modifier(ConclusionAnchorRestore(
            parts: parts,
            isReady: isReady,
            focus: focus,
            keeper: keeper,
            map: map,
            scrollAnchor: scrollAnchor,
            scroll: scroll,
            resolve: resolve
        ))
    }
}

private struct ConclusionAnchorRestore<Stop: Hashable>: ViewModifier {
    let parts: Set<ConclusionSectionAnchor.Part>
    let isReady: Bool
    let focus: FocusState<Stop?>.Binding
    let keeper: Binding<FocusKeeper<Stop>>?
    let map: (Stop) -> Stop
    let scrollAnchor: UnitPoint?
    let scroll: ((String) -> Void)?
    let resolve: (ConclusionSectionAnchor) -> ConclusionAnchorTarget<Stop>?

    @Environment(WorkspaceNavigation.self) private var navigation
    @State private var didRestore = false
    @State private var scrollTarget: String?
    @State private var scrollRequest = 0

    func body(content: Content) -> some View {
        content
            .pvScrollsRowIntoView(scrollTarget, anchor: scrollAnchor, animated: false, whenRequested: scrollRequest)
            .onAppear(perform: restore)
            .onChange(of: isReady) { restore() }
    }

    private func restore() {
        guard isReady, !didRestore else { return }
        didRestore = true
        guard let anchor = navigation.currentLocation.sectionAnchor, parts.contains(anchor.part),
              let target = resolve(anchor) else { return }
        if let scroll {
            scroll(target.scrollID)
        } else {
            scrollTarget = target.scrollID
            scrollRequest += 1
        }
        if let keeper {
            FocusKeeper.hand(target.stop, keeper: keeper, focus: focus, map: map, scroll: { _ in })
        } else {
            FocusClaim.claim(focus, Optional(target.stop))
        }
    }
}
