import AppKit
import Testing
@testable import Provenencia

@MainActor
struct PVClipboardButtonTests {
    /// A sleep the test releases by hand, so the timer needs no real wait.
    @MainActor
    private final class Timer {
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

    private final class Pasteboard {
        var written: [PVClipboardPayload] = []
    }

    private func state(_ pasteboard: Pasteboard, _ timer: Timer) -> PVClipboardCopyState {
        PVClipboardCopyState(write: { pasteboard.written.append($0) }, sleep: { await timer.sleep($0) })
    }

    @Test func copyingWritesExactlyTheTextAndShowsCopied() async {
        let pasteboard = Pasteboard()
        let timer = Timer()
        let state = state(pasteboard, timer)
        #expect(!state.copied)
        state.copy("Parish register, p. 12")
        await timer.settle()
        #expect(pasteboard.written.map(\.plain) == ["Parish register, p. 12"])
        #expect(state.copied)
    }

    /// T-6 (D-11, AC-2.1, AC-2.4).
    @Test func copyWritesRichAndPlain() async {
        let pasteboard = Pasteboard()
        let state = state(pasteboard, Timer())
        let rich = AttributedString("x")
        state.copy("x", rich: rich)
        state.copy("x")
        #expect(pasteboard.written == [PVClipboardPayload(plain: "x", rich: rich), PVClipboardPayload(plain: "x", rich: nil)])
    }

    /// T-7b (D-11, AC-2.1): the italic trait survives the RTF round trip.
    @Test func rtfKeepsEmphasisAsItalic() throws {
        var rich = AttributedString("a")
        var emphasized = AttributedString("b")
        emphasized[AttributeScopes.FoundationAttributes.InlinePresentationIntentAttribute.self] = .emphasized
        rich += emphasized
        let data = try #require(PVClipboardCopyState.rtfData(rich))
        let read = try #require(NSAttributedString(rtf: data, documentAttributes: nil))
        #expect(read.string == "ab")
        func isItalic(_ at: Int) -> Bool {
            let font = read.attribute(.font, at: at, effectiveRange: nil) as? NSFont
            return font?.fontDescriptor.symbolicTraits.contains(.italic) == true
        }
        #expect(!isItalic(0))
        #expect(isItalic(1))
    }

    @Test func theStateReturnsToIdleAfterTheInterval() async {
        let timer = Timer()
        let state = state(Pasteboard(), timer)
        state.copy("a")
        await timer.settle()
        #expect(timer.sleeps == 1)
        await timer.fire(0)
        #expect(!state.copied)
        #expect(PVClipboardCopyState.copiedInterval == .milliseconds(1600))
    }

    @Test func aSecondCopyRestartsTheTimer() async {
        let pasteboard = Pasteboard()
        let timer = Timer()
        let state = state(pasteboard, timer)
        state.copy("a")
        await timer.settle()
        state.copy("b")
        await timer.settle()
        #expect(pasteboard.written.map(\.plain) == ["a", "b"])
        await timer.fire(0)
        #expect(state.copied, "the first timer was replaced, so it must not clear the check")
        await timer.fire(1)
        #expect(!state.copied)
    }

    @Test func leavingStopsTheTimerAndClearsTheCheck() async {
        let timer = Timer()
        let state = state(Pasteboard(), timer)
        state.copy("a")
        await timer.settle()
        state.cancel()
        #expect(!state.copied)
        await timer.fire(0)
        #expect(!state.copied)
    }
}
