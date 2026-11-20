import AppKit
import SwiftUI
import Testing
@testable import Provenencia

@Suite
struct PVPopupDecisionTests {
    fileprivate struct Row: CustomTestStringConvertible, Sendable {
        let input: PVPopupInput
        let pending: Bool
        let keysStayInField: Bool
        let decision: PVPopupDecision
        var testDescription: String {
            "\(input) pending=\(pending) keysStayInField=\(keysStayInField)"
        }
    }

    /// The §6 Edges table, every `any` expanded to both values.
    fileprivate static let rows: [Row] = {
        var rows: [Row] = []
        let bools = [false, true]
        func add(_ input: PVPopupInput, pending: [Bool], stay: [Bool], _ decision: PVPopupDecision) {
            for p in pending {
                for s in stay {
                    rows.append(Row(input: input, pending: p, keysStayInField: s, decision: decision))
                }
            }
        }
        add(.key(.escape), pending: bools, stay: [false], .close(consumesEvent: true))
        for key in [KeyEquivalent.downArrow, KeyEquivalent("c")] {
            add(.key(key), pending: bools, stay: [false], .toPopup(key))
        }
        add(.key(.escape), pending: bools, stay: [true], .pass)
        add(.key(.downArrow), pending: bools, stay: [true], .pass)
        for button in [PVPopupMouseButton.left, .right, .other] {
            for inside in bools {
                add(.mouseUp(button, inside: inside), pending: [true], stay: bools, .endOpeningPress)
            }
        }
        add(.mouseUp(.left, inside: false), pending: [false], stay: bools, .close(consumesEvent: false))
        add(.mouseUp(.left, inside: true), pending: [false], stay: bools, .pass)
        for button in [PVPopupMouseButton.right, .other] {
            for inside in bools {
                add(.mouseUp(button, inside: inside), pending: [false], stay: bools, .pass)
            }
        }
        for inside in bools {
            add(.mouseDown(.left, inside: inside), pending: bools, stay: bools, .pass)
        }
        for button in [PVPopupMouseButton.right, .other] {
            add(.mouseDown(button, inside: false), pending: bools, stay: bools, .close(consumesEvent: false))
            add(.mouseDown(button, inside: true), pending: bools, stay: bools, .pass)
        }
        add(.windowResignedKey, pending: bools, stay: bools, .close(consumesEvent: false))
        return rows
    }()

    @Test(arguments: rows)
    fileprivate func decidesEveryRow(_ row: Row) {
        let decision = PVPopupDecision.decide(
            row.input,
            openingPressPending: row.pending,
            options: PVPopupOptions(keysStayInField: row.keysStayInField)
        )
        #expect(decision == row.decision)
    }
}

@Suite
struct PVPopupInputTests {
    @MainActor @Test func mapsKeys() {
        let none: NSEvent.ModifierFlags = []
        #expect(PVPopupInput.keyEquivalent(keyCode: 53, characters: nil, modifiers: none) == .escape)
        #expect(PVPopupInput.keyEquivalent(keyCode: 126, characters: nil, modifiers: none) == .upArrow)
        #expect(PVPopupInput.keyEquivalent(keyCode: 125, characters: nil, modifiers: none) == .downArrow)
        #expect(PVPopupInput.keyEquivalent(keyCode: 115, characters: nil, modifiers: none) == .home)
        #expect(PVPopupInput.keyEquivalent(keyCode: 119, characters: nil, modifiers: none) == .end)
        #expect(PVPopupInput.keyEquivalent(keyCode: 36, characters: "\r", modifiers: none) == .return)
        #expect(PVPopupInput.keyEquivalent(keyCode: 76, characters: "\r", modifiers: none) == .return)
        #expect(PVPopupInput.keyEquivalent(keyCode: 8, characters: "c", modifiers: none) == KeyEquivalent("c"))
        #expect(PVPopupInput.keyEquivalent(keyCode: 26, characters: "7", modifiers: none) == KeyEquivalent("7"))
        #expect(PVPopupInput.keyEquivalent(keyCode: 8, characters: "c", modifiers: .command) == nil)
        #expect(PVPopupInput.keyEquivalent(keyCode: 8, characters: "c", modifiers: .control) == nil)
        #expect(PVPopupInput.keyEquivalent(keyCode: 27, characters: "-", modifiers: none) == nil)
        #expect(PVPopupInput.keyEquivalent(keyCode: 121, characters: nil, modifiers: none) == nil)

        let escape = NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0,
            context: nil, characters: "\u{1b}", charactersIgnoringModifiers: "\u{1b}",
            isARepeat: false, keyCode: 53
        )
        #expect(escape.flatMap(PVPopupInput.init) == .key(.escape))
    }

    @MainActor @Test func mapsMouseEventsAndLevels() {
        func input(_ type: NSEvent.EventType) -> PVPopupInput? {
            NSEvent.mouseEvent(
                with: type, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0,
                context: nil, eventNumber: 0, clickCount: 1, pressure: 1
            ).flatMap(PVPopupInput.init)
        }
        #expect(input(.leftMouseUp) == .mouseUp(.left, inside: false))
        #expect(input(.rightMouseUp) == .mouseUp(.right, inside: false))
        #expect(input(.rightMouseDown) == .mouseDown(.right, inside: false))
        #expect(input(.otherMouseDown) == .mouseDown(.other, inside: false))
        #expect(input(.leftMouseDown) == .mouseDown(.left, inside: false))

        #expect(!PVPopupInput.isPopupWindow(level: nil))
        #expect(!PVPopupInput.isPopupWindow(level: .normal))
        #expect(!PVPopupInput.isPopupWindow(level: .floating))
        #expect(PVPopupInput.isPopupWindow(level: .popUpMenu))
        #expect(PVPopupInput.isPopupWindow(level: .screenSaver))
    }
}
