import Foundation

/// A duration in milliseconds, for the timings tests print.
func milliseconds(_ duration: Duration) -> Double {
    Double(duration.components.attoseconds) / 1e15 + Double(duration.components.seconds) * 1e3
}

/// The fastest of `runs` timed calls of `run`, in milliseconds.
func bestOfMilliseconds(runs: Int, _ run: () -> Void) -> Double {
    var best = Double.infinity
    for _ in 0..<runs {
        best = min(best, milliseconds(ContinuousClock().measure(run)))
    }
    return best
}
