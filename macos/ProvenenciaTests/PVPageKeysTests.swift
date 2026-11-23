import AppKit
import Testing

@testable import Provenencia

struct PVPageKeysTests {
    @Test func pageKeysNameTheirCommand() {
        #expect(PVPageKeys.command(keyCode: 116, modifiers: []) == .pageUp)
        #expect(PVPageKeys.command(keyCode: 121, modifiers: []) == .pageDown)
        #expect(PVPageKeys.command(keyCode: 115, modifiers: []) == .top)
        #expect(PVPageKeys.command(keyCode: 119, modifiers: []) == .bottom)
        #expect(PVPageKeys.command(keyCode: 121, modifiers: [.function]) == .pageDown)
        #expect(PVPageKeys.command(keyCode: 121, modifiers: [.function, .numericPad]) == .pageDown)
        #expect(PVPageKeys.command(keyCode: 125, modifiers: []) == nil)
        #expect(PVPageKeys.command(keyCode: 49, modifiers: []) == nil)
        #expect(PVPageKeys.command(keyCode: 121, modifiers: [.shift]) == nil)
        #expect(PVPageKeys.command(keyCode: 119, modifiers: [.command]) == nil)
        #expect(PVPageKeys.command(keyCode: 115, modifiers: [.option]) == nil)
        #expect(PVPageKeys.command(keyCode: 116, modifiers: [.control]) == nil)
    }

    @Test func edgeReachedOnlyAtTheEdge() {
        let doc = CGRect(x: 0, y: 0, width: 100, height: 5000)
        let topView = CGRect(x: 0, y: 0, width: 100, height: 500)
        let bottomView = CGRect(x: 0, y: 4500, width: 100, height: 500)
        #expect(PVPageKeys.edgeReached(visible: topView, document: doc, flipped: true, top: true))
        #expect(!PVPageKeys.edgeReached(visible: topView, document: doc, flipped: true, top: false))
        #expect(PVPageKeys.edgeReached(visible: bottomView, document: doc, flipped: true, top: false))
        let grown = CGRect(x: 0, y: 0, width: 100, height: 9000)
        #expect(!PVPageKeys.edgeReached(visible: bottomView, document: grown, flipped: true, top: false))
        // Unflipped: the top is maxY.
        #expect(PVPageKeys.edgeReached(visible: bottomView, document: doc, flipped: false, top: true))
        #expect(!PVPageKeys.edgeReached(visible: bottomView, document: doc, flipped: false, top: false))
        #expect(PVPageKeys.edgeReached(visible: topView, document: doc, flipped: false, top: false))
    }

    @Test func edgePinKeepsTheEdgeUntilTheUserScrolls() {
        var fresh = PVPageEdgePinState()
        let r_2267 = fresh.documentChanged()
        #expect(r_2267)
        // Our own scroll keeps the pin, even away from the edge.
        fresh.clipMoved(bySelf: true, atEdge: false)
        #expect(fresh.isPinned)
        // A move that leaves the page at the edge keeps it.
        fresh.clipMoved(bySelf: false, atEdge: true)
        #expect(fresh.isPinned)

        var scrolled = PVPageEdgePinState()
        scrolled.clipMoved(bySelf: false, atEdge: false)
        #expect(!scrolled.isPinned)
        let r_2743 = scrolled.documentChanged()
        #expect(!r_2743)

        var quiet = PVPageEdgePinState()
        quiet.quiet(for: 0.5)
        #expect(quiet.isPinned)
        quiet.quiet(for: 0.6)
        #expect(!quiet.isPinned)

        var long = PVPageEdgePinState()
        let r_2996 = long.documentChanged()
        #expect(r_2996)
        long.elapsed(2.9)
        let r_3062 = long.documentChanged()
        #expect(r_3062)
        long.elapsed(3)
        #expect(!long.isPinned)
        let r_3158 = long.documentChanged()
        #expect(!r_3158)
    }
}
