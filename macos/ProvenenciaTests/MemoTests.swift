import Testing
@testable import Provenencia

struct MemoTests {
    @Test func holdsTheValueOnlyForItsKey() {
        var memo = Memo<Int, String>()
        #expect(memo.value(for: 9) == nil)

        memo.store("a", for: 1)
        #expect(memo.value(for: 1) == "a")
        #expect(memo.value(for: 2) == nil)

        memo.store("b", for: 3)
        #expect(memo.value(for: 3) == "b")
        #expect(memo.value(for: 1) == nil)
    }
}
