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

    @Test func backTabIsTheShiftTabKey() {
        #expect(KeyEquivalent.backTab.character == "\u{19}")
    }
}
