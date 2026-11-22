import Foundation

/// A sleep a test releases by hand, so a timer needs no real wait.
@MainActor
final class ManualSleep {
    private var waiting: [CheckedContinuation<Void, Never>] = []

    func sleep(_ duration: Duration) async {
        await withCheckedContinuation { waiting.append($0) }
    }

    func settle() async {
        for _ in 0..<5 { await Task.yield() }
    }

    func fire(_ index: Int) async {
        waiting[index].resume()
        await settle()
    }

    var sleeps: Int { waiting.count }
}
