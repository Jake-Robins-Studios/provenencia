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
    @Test func repeatMovesToTopKeepsIdAndRestartsTimer() async {
        let timer = ManualSleep()
        let list = make(timer)
        list.add(tone: .success, title: "A", message: "x")
        let id = list.entries[0].id
        list.add(tone: .success, title: "B", message: nil)
        list.add(tone: .success, title: "A", message: "x")
        await timer.settle()
        #expect(titles(list) == ["A", "B"])
        #expect(list.entries[0].id == id)
        #expect(timer.sleeps == 3)
        await timer.fire(0)
        #expect(titles(list) == ["A", "B"])
        await timer.fire(2)
        #expect(titles(list) == ["B"])
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
    @Test func differentToneOrMessageAddsACard() {
        let list = make(ManualSleep())
        list.add(tone: .success, title: "Saved", message: "x")
        list.add(tone: .danger, title: "Saved", message: "x")
        #expect(list.entries.count == 2)
        list.add(tone: .success, title: "Saved", message: "y")
        #expect(list.entries.count == 3)
    }

    /// T-6 (D-4).
    @Test func titleOnlyRepeatRefreshes() {
        let list = make(ManualSleep())
        list.add(tone: .info, title: "Filed", message: nil)
        list.add(tone: .info, title: "Filed", message: "")
        #expect(list.entries.count == 1)
        #expect(list.entries[0].message == nil)
    }
}
