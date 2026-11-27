import Foundation

/// A duration in milliseconds, for the timings tests print.
func milliseconds(_ duration: Duration) -> Double {
    Double(duration.components.attoseconds) / 1e15 + Double(duration.components.seconds) * 1e3
}

/// The fastest of `runs` timed calls of `run`, in milliseconds. Each run gets a fresh state from
/// `prepare()`, made outside the timed span, and `check` reads the state after it, also outside it.
func bestOfMilliseconds<S>(
    runs: Int, prepare: () -> S, _ run: (inout S) -> Void, check: (S) -> Void = { _ in }
) -> Double {
    var best = Double.infinity
    for _ in 0..<runs {
        var state = prepare()
        best = min(best, milliseconds(ContinuousClock().measure { run(&state) }))
        check(state)
    }
    return best
}

/// The fastest of `runs` timed calls of `run`, in milliseconds.
func bestOfMilliseconds(runs: Int, _ run: () -> Void) -> Double {
    bestOfMilliseconds(runs: runs, prepare: {}, { _ in run() })
}
