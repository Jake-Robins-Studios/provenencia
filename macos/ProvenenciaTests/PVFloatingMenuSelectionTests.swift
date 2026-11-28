import Foundation
import Testing
@testable import Provenencia

@Suite
struct PVFloatingMenuSelectionTests {
    @Test func emptyCountReturnsNone() {
        #expect(PVFloatingMenuSelection.moveIndex(from: 0, delta: 1, count: 0) == -1)
        #expect(PVFloatingMenuSelection.moveIndex(from: -1, delta: -1, count: 0) == -1)
    }

    @Test func fromNoneOpensAtEndMatchingDelta() {
        #expect(PVFloatingMenuSelection.moveIndex(from: -1, delta: 1, count: 5) == 0)
        #expect(PVFloatingMenuSelection.moveIndex(from: -1, delta: -1, count: 5) == 4)
    }

    @Test func clampsAtEnds() {
        #expect(PVFloatingMenuSelection.moveIndex(from: 0, delta: -1, count: 5) == 0)
        #expect(PVFloatingMenuSelection.moveIndex(from: 4, delta: 1, count: 5) == 4)
    }

    @Test func stepsByDelta() {
        #expect(PVFloatingMenuSelection.moveIndex(from: 2, delta: 1, count: 5) == 3)
        #expect(PVFloatingMenuSelection.moveIndex(from: 2, delta: -1, count: 5) == 1)
    }

    // MARK: Disabled rows

    /// The composer's Clear menu: Clear region (disabled), Reset to entire artifact.
    private static func clearMenu(_ row: Int) -> Bool { row == 0 }

    @Test func skipsDisabledRows() {
        func move(_ index: Int, _ delta: Int, edge: PVFloatingMenuSelection.Edge? = nil) -> Int {
            PVFloatingMenuSelection.moveIndex(
                from: index, delta: delta, count: 2, edge: edge, isDisabled: { Self.clearMenu($0) }
            )
        }
        #expect(move(-1, 1) == 1)
        #expect(move(-1, -1) == 1)
        #expect(move(1, -1) == 1)
        #expect(
            PVFloatingMenuSelection.moveIndex(from: 4, delta: 1, count: 6, edge: nil, isDisabled: { $0 == 5 }) == 4
        )
        #expect(
            PVFloatingMenuSelection.moveIndex(from: 1, delta: 1, count: 4, edge: nil, isDisabled: { $0 == 2 }) == 3
        )
    }

    @Test func edgesWalkInward() {
        #expect(PVFloatingMenuSelection.moveIndex(
            from: -1, delta: 1, count: 2, edge: .first, isDisabled: { Self.clearMenu($0) }
        ) == 1)
        #expect(PVFloatingMenuSelection.moveIndex(
            from: -1, delta: -1, count: 2, edge: .last, isDisabled: { Self.clearMenu($0) }
        ) == 1)
        #expect(PVFloatingMenuSelection.moveIndex(
            from: 0, delta: -1, count: 4, edge: .last, isDisabled: { $0 == 3 }
        ) == 2)
    }

    @Test func staysPutWhenNoEnabledRowLiesThatWay() {
        #expect(PVFloatingMenuSelection.moveIndex(
            from: -1, delta: 1, count: 2, edge: nil, isDisabled: { _ in true }
        ) == -1)
        #expect(PVFloatingMenuSelection.moveIndex(
            from: 1, delta: 1, count: 2, edge: .first, isDisabled: { _ in true }
        ) == 1)
        #expect(PVFloatingMenuSelection.moveIndex(
            from: 0, delta: 1, count: 0, edge: nil, isDisabled: { Self.clearMenu($0) }
        ) == -1)
    }

    @Test func plainMoveMatchesNoDisabledRows() {
        for count in 0...4 {
            for from in -1..<max(count, 0) {
                for delta in [-1, 1] {
                    #expect(
                        PVFloatingMenuSelection.moveIndex(from: from, delta: delta, count: count)
                            == PVFloatingMenuSelection.moveIndex(
                                from: from, delta: delta, count: count, edge: nil, isDisabled: { _ in false }
                            )
                    )
                }
            }
        }
    }

    @Test func typeSelectSkipsDisabledRows() {
        let titles = ["Clear region", "Reset"]
        #expect(PVTypeSelectMatcher.index(in: titles, prefix: "c", isDisabled: { Self.clearMenu($0) }) == -1)
        #expect(PVTypeSelectMatcher.index(in: titles, prefix: "r", isDisabled: { Self.clearMenu($0) }) == 1)

        let names = ["Prefix", "Suffix", "Surname"]
        var matcher = PVTypeSelectMatcher()
        let start = Date(timeIntervalSince1970: 1_000)
        #expect(matcher.advance("s", from: 0, in: names, now: start) == 1)
        let later = start.addingTimeInterval(PVTypeSelectMatcher.resetInterval + 1)
        #expect(matcher.advance("s", from: 1, in: names, now: later) == 2)
        var typed = PVTypeSelectMatcher()
        #expect(typed.advance("s", from: 0, in: names, now: start) == 1)
        #expect(typed.advance("u", from: 1, in: names, now: start.addingTimeInterval(0.1)) == 1)
    }

    @Test func repeatedLetterWalksItsMatches() {
        let months = [
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December",
        ]
        let start = Date(timeIntervalSince1970: 1_000)
        var matcher = PVTypeSelectMatcher()
        var current = 0
        var hits: [Int] = []
        for step in 0..<4 {
            current = matcher.advance("j", from: current, in: months, now: start.addingTimeInterval(Double(step) * 0.1))
            hits.append(current)
        }
        #expect(hits == [5, 6, 0, 5])

        let names = ["Aaron", "Abel", "Adam"]
        var named = PVTypeSelectMatcher()
        let first = named.advance("a", from: -1, in: names, now: start)
        let second = named.advance("a", from: first, in: names, now: start.addingTimeInterval(0.1))
        #expect(first == 0)
        #expect(second == 1)

        let numbers = ["10", "11", "12"]
        var numeric = PVTypeSelectMatcher()
        let one = numeric.advance("1", from: 0, in: numbers, now: start)
        let two = numeric.advance("1", from: one, in: numbers, now: start.addingTimeInterval(0.1))
        #expect(one == 1)
        #expect(two == 2)
    }

    @Test func mixedLettersStayAPrefixSearch() {
        let start = Date(timeIntervalSince1970: 1_000)
        var matcher = PVTypeSelectMatcher()
        let titles = ["January", "June", "July"]
        var current = matcher.advance("j", from: -1, in: titles, now: start)
        current = matcher.advance("j", from: current, in: titles, now: start.addingTimeInterval(0.1))
        #expect(matcher.advance("o", from: current, in: titles, now: start.addingTimeInterval(0.2)) == -1)

        var names = PVTypeSelectMatcher()
        let people = ["Jane", "Jones"]
        let first = names.advance("j", from: -1, in: people, now: start)
        #expect(first == 0)
        #expect(names.advance("o", from: first, in: people, now: start.addingTimeInterval(0.1)) == 1)
    }

    @Test func typeSelectCharacters() {
        #expect(PVTypeSelectMatcher.isTypeSelectCharacter("a"))
        #expect(PVTypeSelectMatcher.isTypeSelectCharacter("7"))
        #expect(!PVTypeSelectMatcher.isTypeSelectCharacter("-"))
        #expect(!PVTypeSelectMatcher.isTypeSelectCharacter(" "))
    }

    @Test func typeSelectCharacterFromAKeyPress() {
        #expect(PVTypeSelectMatcher.typeSelectCharacter("a", command: false, control: false) == "a")
        #expect(PVTypeSelectMatcher.typeSelectCharacter("a", command: true, control: false) == nil)
        #expect(PVTypeSelectMatcher.typeSelectCharacter("a", command: false, control: true) == nil)
        #expect(PVTypeSelectMatcher.typeSelectCharacter("ab", command: false, control: false) == nil)
        #expect(PVTypeSelectMatcher.typeSelectCharacter("", command: false, control: false) == nil)
        #expect(PVTypeSelectMatcher.typeSelectCharacter(nil, command: false, control: false) == nil)
        #expect(PVTypeSelectMatcher.typeSelectCharacter(" ", command: false, control: false) == nil)
    }
}
