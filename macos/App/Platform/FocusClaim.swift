import SwiftUI

/// Moves keyboard focus to a field that may not be ready to take it yet.
enum FocusClaim {
    /// The one two-turn write: runs `write` on the next main-queue turn, runs
    /// `then`, and runs `write` again a turn later unless `isDone()`. The write
    /// happens twice because the target may not be in the view hierarchy until
    /// the following turn (a field inserted by the same commit), and a sheet
    /// that is still dismissing can swallow the first.
    @MainActor
    static func claim(
        write: @escaping @MainActor () -> Void,
        isDone: @escaping @MainActor () -> Bool,
        then: @escaping @MainActor () -> Void = {}
    ) {
        DispatchQueue.main.async {
            write()
            then()
            DispatchQueue.main.async {
                if !isDone() { write() }
            }
        }
    }

    /// Writes `value` to `binding` through the two-turn write.
    @MainActor
    static func claim<V: Hashable>(
        _ binding: FocusState<V>.Binding,
        _ value: V,
        then: @escaping @MainActor () -> Void = {}
    ) {
        claim(
            write: { binding.wrappedValue = value },
            isDone: { binding.wrappedValue == value },
            then: then
        )
    }

    /// Focuses a field through its kit handle with the two-turn write.
    @MainActor
    static func claim(_ handle: PVFieldFocus) {
        claim(write: { handle.focus() }, isDone: { handle.isActive() })
    }
}
