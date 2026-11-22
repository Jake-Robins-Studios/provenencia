import Testing
@testable import Provenencia

@MainActor
struct VocabularyToastTests {
    /// T-7 (D-6).
    @Test func addingAVocabularyToastForwardsItsFields() {
        let list = PVToastList(sleep: { _ in })
        list.add(VocabularyToast(title: "Filed", body: "", tone: .info))
        #expect(list.entries.count == 1)
        #expect(list.entries[0].title == "Filed")
        #expect(list.entries[0].message == nil)
        #expect(list.entries[0].tone == .info)
    }
}
