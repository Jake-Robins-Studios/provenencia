import Testing
@testable import Provenencia

@MainActor
struct PVToastListTests {
    private func make(_ timer: ManualSleep) -> PVToastList {
        PVToastList(sleep: { await timer.sleep($0) })
    }

    private func titles(_ list: PVToastList) -> [String?] { list.entries.map(\.title) }

    /// T-1 (AC-1.1, D-4).
    @Test func addPutsNewestFirst() async {
        let timer = ManualSleep()
        let list = make(timer)
        list.add(tone: .success, title: "A", message: nil)
        list.add(tone: .success, title: "B", message: nil)
        await timer.settle()
        #expect(titles(list) == ["B", "A"])
        #expect(timer.sleeps == 2)
    }

    /// T-2 (AC-1.3, D-3).
    @Test func eachEntryLeavesOnItsOwnTimer() async {
        let timer = ManualSleep()
        let list = make(timer)
        list.add(tone: .success, title: "A", message: nil)
        list.add(tone: .success, title: "B", message: nil)
        await timer.settle()
        await timer.fire(0)
        #expect(titles(list) == ["B"])
        await timer.fire(1)
        #expect(list.entries.isEmpty)
    }

    /// T-3 (AC-2.1, D-4).
    @Test func replacingMovesToTopKeepsIdAndRestartsTimer() async {
        let timer = ManualSleep()
        let list = make(timer)
        let a = list.add(tone: .success, title: "A", message: "x")
        list.add(tone: .success, title: "B", message: nil)
        list.add(tone: .success, title: "C", message: "z", replacing: a)
        await timer.settle()
        #expect(titles(list) == ["C", "B"])
        #expect(list.entries[0].id == a)
        #expect(timer.sleeps == 3)
        await timer.fire(0)
        #expect(titles(list) == ["C", "B"])
        await timer.fire(2)
        #expect(titles(list) == ["B"])
    }

    /// Equal adds are two cards: the list never compares text.
    @Test func equalAddsMakeTwoCards() async {
        let timer = ManualSleep()
        let list = make(timer)
        let first = list.add(tone: .success, title: "Portrait updated", message: "Register")
        let second = list.add(tone: .success, title: "Portrait updated", message: "Register")
        await timer.settle()
        #expect(list.entries.count == 2)
        #expect(first != second)
        #expect(timer.sleeps == 2)
    }

    /// T-4 (AC-1.2, D-3).
    @Test func dismissKeepsTheOtherTimer() async {
        let timer = ManualSleep()
        let list = make(timer)
        list.add(tone: .success, title: "A", message: nil)
        list.add(tone: .success, title: "B", message: nil)
        await timer.settle()
        list.dismiss(list.entries[0].id)
        #expect(titles(list) == ["A"])
        #expect(timer.sleeps == 2)
        await timer.fire(1)
        #expect(titles(list) == ["A"])
        await timer.fire(0)
        #expect(list.entries.isEmpty)
        list.add(tone: .success, title: "C", message: nil)
        let before = list.entries
        list.dismiss(.init())
        #expect(list.entries == before)
    }

    /// T-5 (AC-2.2, D-4).
    @Test func replacingAGoneIdAddsANewCard() {
        let list = make(ManualSleep())
        let a = list.add(tone: .success, title: "A", message: nil)
        list.dismiss(a)
        let b = list.add(tone: .success, title: "A", message: nil, replacing: a)
        #expect(list.entries.count == 1)
        #expect(b != a)
        #expect(list.entries[0].id == b)
    }

    /// T-6 (D-4).
    @Test func emptyTitleOrMessageIsNone() {
        let list = make(ManualSleep())
        list.add(tone: .info, title: "Filed", message: "")
        #expect(list.entries[0].message == nil)
        list.add(tone: .info, title: "", message: "Body")
        #expect(list.entries[0].title == nil)
    }
}
