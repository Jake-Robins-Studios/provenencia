import SwiftUI
import Testing
@testable import Provenencia

@Suite
@MainActor
struct PVFieldFocusTests {
    private func handle(
        next: (@MainActor () -> Void)?,
        previous: (@MainActor () -> Void)?
    ) -> PVFieldFocus {
        PVFieldFocus(
            isActive: { false },
            focus: {},
            resign: {},
            apply: { $0 },
            next: next,
            previous: previous
        )
    }

    @Test func tabClaimPicksTheNeighbour() {
        var nextCalls = 0
        var previousCalls = 0
        let both = handle(next: { nextCalls += 1 }, previous: { previousCalls += 1 })

        both.tabClaim(shift: false)?()
        #expect(nextCalls == 1)
        #expect(previousCalls == 0)
        both.tabClaim(shift: true)?()
        #expect(nextCalls == 1)
        #expect(previousCalls == 1)

        let onlyNext = handle(next: { nextCalls += 1 }, previous: nil)
        #expect(onlyNext.tabClaim(shift: false) != nil)
        #expect(onlyNext.tabClaim(shift: true) == nil)

        let none = handle(next: nil, previous: nil)
        #expect(none.tabClaim(shift: false) == nil)
        #expect(none.tabClaim(shift: true) == nil)
    }

    @Test func neighboursFollowTheFormsOrder() {
        let middle = PVFieldFocus.neighbours(of: "b", in: ["a", "b", "c"])
        #expect(middle.next == "c")
        #expect(middle.previous == "a")
        let first = PVFieldFocus.neighbours(of: "a", in: ["a", "b", "c"])
        #expect(first.next == "b")
        #expect(first.previous == nil)
        let last = PVFieldFocus.neighbours(of: "c", in: ["a", "b", "c"])
        #expect(last.next == nil)
        #expect(last.previous == "b")
        for lone in [
            PVFieldFocus.neighbours(of: "a", in: ["a"]),
            PVFieldFocus.neighbours(of: "d", in: ["a", "b"]),
            PVFieldFocus.neighbours(of: "a", in: [String]()),
        ] {
            #expect(lone.next == nil)
            #expect(lone.previous == nil)
        }
    }

    @Test func claimsRunTheNeighbour() {
        var claimed: [String] = []
        let both = PVFieldFocus.claims(next: "c", previous: "a") { claimed.append($0) }
        both.next?()
        both.previous?()
        #expect(claimed == ["c", "a"])

        let none = PVFieldFocus.claims(next: String?.none, previous: String?.none) { _ in }
        #expect(none.next == nil)
        #expect(none.previous == nil)
    }

    @Test func optionalHandleFallsBackToOwn() {
        let none: PVFieldFocus? = nil
        #expect(none.isActive(own: true))
        #expect(!none.isActive(own: false))

        let active = PVFieldFocus(
            isActive: { true }, focus: {}, resign: {}, apply: { $0 }
        )
        let idle = PVFieldFocus(
            isActive: { false }, focus: {}, resign: {}, apply: { $0 }
        )
        let someActive: PVFieldFocus? = active
        let someIdle: PVFieldFocus? = idle
        #expect(someActive.isActive(own: false))
        #expect(!someIdle.isActive(own: true))
    }

    @Test func claimTabRunsTheNeighbourAndReportsHandled() {
        var nextCalls = 0
        var previousCalls = 0
        let both = handle(next: { nextCalls += 1 }, previous: { previousCalls += 1 })
        #expect(both.claimTab(shift: false) == .handled)
        #expect(nextCalls == 1)
        #expect(previousCalls == 0)
        #expect(both.claimTab(shift: true) == .handled)
        #expect(previousCalls == 1)
        #expect(both.hasNeighbour)

        let none = handle(next: nil, previous: nil)
        #expect(none.claimTab(shift: false) == .ignored)
        #expect(none.claimTab(shift: true) == .ignored)
        #expect(!none.hasNeighbour)
    }

    @Test func replacingNeighboursSwapsBothClaims() {
        var original = 0
        var replacedNext = 0
        let source = handle(next: { original += 1 }, previous: { original += 1 })
        let swapped = source.replacingNeighbours(next: { replacedNext += 1 }, previous: nil)

        #expect(swapped.claimTab(shift: false) == .handled)
        #expect(replacedNext == 1)
        #expect(swapped.claimTab(shift: true) == .ignored)
        #expect(original == 0)

        #expect(source.claimTab(shift: false) == .handled)
        #expect(source.claimTab(shift: true) == .handled)
        #expect(original == 2)
        #expect(replacedNext == 1)
    }

    /// The writes seen after the first main-queue turn and after the second.
    /// Each reading is a main-queue block queued behind the claim's own, so no
    /// task-resume timing is involved.
    private func writesAfterTwoTurns(_ writes: @escaping @MainActor () -> Int) async -> (first: Int, second: Int) {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let first = MainActor.assumeIsolated { writes() }
                DispatchQueue.main.async {
                    continuation.resume(returning: (first, MainActor.assumeIsolated { writes() }))
                }
            }
        }
    }

    @Test func focusClaimWritesOnTheNextTurn() async {
        var writes = 0
        FocusClaim.claim(write: { writes += 1 }, isDone: { false })
        #expect(writes == 0)
        let pending = await writesAfterTwoTurns { writes }
        #expect(pending.first == 1)
        #expect(pending.second == 2)

        var settled = 0
        FocusClaim.claim(write: { settled += 1 }, isDone: { true })
        let done = await writesAfterTwoTurns { settled }
        #expect(done.first == 1)
        #expect(done.second == 1)

        var focused = 0
        let target = PVFieldFocus(isActive: { false }, focus: { focused += 1 }, resign: {}, apply: { $0 })
        FocusClaim.claim(target)
        #expect(focused == 0)
        let handle = await writesAfterTwoTurns { focused }
        #expect(handle.first == 1)
        #expect(handle.second == 2)
    }

    @Test func backTabIsTheShiftTabKey() {
        #expect(KeyEquivalent.backTab.character == "\u{19}")
    }
}
