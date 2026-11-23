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
}
