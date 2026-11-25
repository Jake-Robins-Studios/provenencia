import SwiftUI

extension View {
    /// Back or Forward to the page entry that opened a place from one of this section's rows
    /// gives that row the keyboard (the page's own scroll view restores the y, `pvRemembersScroll`),
    /// once per mount (a page mounts per entity, a section per switch), the first time `isReady` is true and the read behind the content has
    /// settled (`conclusionReadSettled`), so a value being replaced is never resolved against. A
    /// later reload or fold change never moves the keyboard. An anchor of another part, or one `resolve` finds nothing for,
    /// leaves the page at its top. A fold is never revealed: `resolve` names its Show more.
    ///
    /// - Parameters:
    ///   - parts: The anchor parts this site restores.
    ///   - isReady: True once the stops exist to take the keyboard.
    ///   - focus: The section's focus state.
    ///   - keeper: The section's `FocusKeeper`, when it has one; the stop is handed through it.
    ///   - map: Names the stop that can take the keyboard in place of the target's (with `keeper`).
    ///   - resolve: The stop that takes the keyboard for an anchor of `parts` (a row, a tile, or the Show
    ///     more of a fold that hides it), or nil when its row is gone.
    func conclusionAnchorRestore<Stop: Hashable>(
        _ parts: Set<ConclusionSectionAnchor.Part>,
        isReady: Bool,
        focus: FocusState<Stop?>.Binding,
        keeper: Binding<FocusKeeper<Stop>>? = nil,
        map: @escaping (Stop) -> Stop = { $0 },
        resolve: @escaping (ConclusionSectionAnchor) -> Stop?
    ) -> some View {
        modifier(ConclusionAnchorRestore(
            parts: parts,
            isReady: isReady,
            focus: focus,
            keeper: keeper,
            map: map,
            resolve: resolve
        ))
    }
}

private struct ConclusionReadSettledKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    /// False while the read the drawn content came from is reloading or stale: the content is
    /// the last value, not the latest, so Back to a row waits for it. The page's read sets it
    /// for the default sections and a section host for its own; the nearer one wins.
    var conclusionReadSettled: Bool {
        get { self[ConclusionReadSettledKey.self] }
        set { self[ConclusionReadSettledKey.self] = newValue }
    }
}

private struct ConclusionAnchorRestore<Stop: Hashable>: ViewModifier {
    let parts: Set<ConclusionSectionAnchor.Part>
    let isReady: Bool
    let focus: FocusState<Stop?>.Binding
    let keeper: Binding<FocusKeeper<Stop>>?
    let map: (Stop) -> Stop
    let resolve: (ConclusionSectionAnchor) -> Stop?

    @Environment(WorkspaceNavigation.self) private var navigation
    @Environment(\.conclusionReadSettled) private var settled
    @State private var didRestore = false

    func body(content: Content) -> some View {
        content
            .onAppear(perform: restore)
            .onChange(of: isReady && settled) { restore() }
    }

    private func restore() {
        guard isReady, settled, !didRestore else { return }
        didRestore = true
        guard let anchor = navigation.currentLocation.revisit.sectionAnchor, parts.contains(anchor.part),
              let stop = resolve(anchor) else { return }
        if let keeper {
            FocusKeeper.hand(stop, keeper: keeper, focus: focus, map: map, scroll: { _ in })
        } else {
            FocusClaim.claim(focus, Optional(stop))
        }
    }
}
