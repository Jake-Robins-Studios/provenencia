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
}
