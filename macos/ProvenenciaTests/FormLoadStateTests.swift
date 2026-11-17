import Foundation
import Testing
@testable import Provenencia

private enum ReadBoom: Error { case boom }

struct FormLoadStateTests {
    @Test func combiningTakesTheFirstFailureThenLoadingThenReady() {
        #expect(PVFormLoadState.combining([]) == .ready)
        #expect(PVFormLoadState.combining([.ready, .ready]) == .ready)
        #expect(PVFormLoadState.combining([.ready, .loading]) == .loading)
        #expect(PVFormLoadState.combining([.loading, .failed("a"), .failed("b")]) == .failed("a"))
    }

    @Test func aReadSaysItsFormState() {
        #expect(QueryRead<Int>.loaded(1).formLoadState == .ready)
        #expect(QueryRead<Int>.loading.formLoadState == .loading)
        #expect(QueryRead<Int>.failed(ReadBoom.boom).formLoadState == .failed(L10n.Errors.message(for: ReadBoom.boom)))
    }
}
