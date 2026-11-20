import Foundation
import Testing

@testable import Provenencia

@MainActor
struct LatestCallTests {
    /// A gate a test opens to let a call's work finish.
    @MainActor
    private final class Gate {
        private var continuation: CheckedContinuation<Void, Never>?
        private var opened = false

        func wait() async {
            if opened { return }
            await withCheckedContinuation { continuation = $0 }
        }

        func open() {
            opened = true
            continuation?.resume()
            continuation = nil
        }
    }

    @MainActor
    private final class Applied {
        var values: [Int] = []
    }

    @Test func onlyTheNewestOfTwoRunsApplies() async {
        let latest = LatestCall()
        let applied = Applied()
        let slow = Gate()
        latest.start({ await slow.wait(); return 1 }, apply: { if case .success(let v) = $0 { applied.values.append(v) } })
        let second = Task { @MainActor in
            await latest.run({ 2 }, apply: { if case .success(let v) = $0 { applied.values.append(v) } })
        }
        await second.value
        slow.open()
        await latest.settle()
        #expect(applied.values == [2])
    }

    @Test func cancelDropsThePendingCall() async {
        let latest = LatestCall()
        let applied = Applied()
        let gate = Gate()
        latest.start({ await gate.wait(); return 1 }, apply: { if case .success(let v) = $0 { applied.values.append(v) } })
        latest.cancel()
        gate.open()
        await latest.settle()
        #expect(applied.values.isEmpty)
    }

    @Test func aDelayWithARunInsideItIsOneCall() async {
        let latest = LatestCall()
        let applied = Applied()
        var worked = 0
        for value in [1, 2, 3] {
            latest.start(after: .milliseconds(30), { worked += 1; return value }, apply: {
                if case .success(let v) = $0 { applied.values.append(v) }
            })
        }
        await latest.settle()
        #expect(worked == 1)
        #expect(applied.values == [3])
    }

    @Test func aFailureAppliesAsAFailure() async {
        struct Boom: Error {}
        let latest = LatestCall()
        var failed = false
        await latest.run({ () async throws -> Int in throw Boom() }, apply: { if case .failure = $0 { failed = true } })
        #expect(failed)
    }
}
