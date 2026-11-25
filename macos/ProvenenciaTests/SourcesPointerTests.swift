import AppKit
import Testing
@testable import Provenencia

/// Which events are a click, and what a press on the Sources list means (AC-4.2, AC-4.11).
@MainActor
struct SourcesPointerTests {
    private func mouse(
        _ type: NSEvent.EventType, _ modifiers: NSEvent.ModifierFlags = [], count: Int = 1
    ) -> NSEvent? {
        NSEvent.mouseEvent(
            with: type, location: .zero, modifierFlags: modifiers, timestamp: 100, windowNumber: 0, context: nil,
            eventNumber: 0, clickCount: count, pressure: 1
        )
    }

    @Test func aClickIsALeftPressOrReleaseUnderASecondOld() {
        #expect(SourcesClick(mouse(.leftMouseDown, count: 2), now: 100) == SourcesClick(count: 2, isPlain: true))
        #expect(SourcesClick(mouse(.leftMouseUp), now: 100.99) == SourcesClick(count: 1, isPlain: true))
        #expect(SourcesClick(mouse(.leftMouseDown), now: 101) == nil)
        #expect(SourcesClick(mouse(.rightMouseDown), now: 100) == nil)
        #expect(SourcesClick(nil, now: 100) == nil)
        let key = NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [], timestamp: 100, windowNumber: 0, context: nil,
            characters: "\u{F701}", charactersIgnoringModifiers: "\u{F701}", isARepeat: false, keyCode: 125
        )
        #expect(SourcesClick(key, now: 100) == nil)
    }

    @Test func aModifiedClickIsNotPlain() {
        #expect(SourcesClick(mouse(.leftMouseDown, .capsLock), now: 100)?.isPlain == true)
        for modifier: NSEvent.ModifierFlags in [.command, .shift, .option, .control] {
            #expect(SourcesClick(mouse(.leftMouseDown, modifier), now: 100)?.isPlain == false)
        }
    }

    struct PressCase: CustomTestStringConvertible {
        var id: String?
        var old: String?
        var click: SourcesClick?
        var pressed: String?
        var triangle: String?
        let want: SourcesPress
        var testDescription: String {
            "\(old ?? "-") to \(id ?? "-"), pressed \(pressed ?? "-"), triangle \(triangle ?? "-"), \(String(describing: click))"
        }
    }

    private static let once = SourcesClick(count: 1, isPlain: true)
    private static let twice = SourcesClick(count: 2, isPlain: true)

    /// s1 (open, with graph g1), s2 (closed).
    @Test(arguments: [
        // A plain first press on a closed Source opens it; a key, a modified click or the triangle does not.
        PressCase(id: "s2", old: "s1", click: once, want: .select(.expand("s2"))),
        PressCase(id: "s2", old: "s1", want: .select(.ignore)),
        PressCase(id: "s2", old: "s1", click: SourcesClick(count: 1, isPlain: false), want: .select(.ignore)),
        PressCase(id: "s2", old: "s1", click: once, triangle: "s2", want: .select(.ignore)),
        PressCase(id: "s2", old: "s1", click: once, triangle: "s1", want: .select(.expand("s2"))),
        // A second press belongs to the first row while that is the selection, on whatever row it lands.
        PressCase(id: "s2", old: "s1", click: twice, pressed: "s1", want: .second(opens: nil)),
        PressCase(id: "g1", old: "s1", click: SourcesClick(count: 3, isPlain: true), pressed: "s1", want: .second(opens: nil)),
        // On no row it opens the first one, if the outline still has it.
        PressCase(id: nil, old: "s1", click: twice, pressed: "s1", want: .second(opens: "s1")),
        PressCase(id: nil, old: "gone", click: twice, pressed: "gone", want: .second(opens: nil)),
        // Another selection since, no first press, or a first press: not a second one.
        PressCase(id: "s2", old: "g1", click: twice, pressed: "s1", want: .select(.expand("s2"))),
        PressCase(id: nil, old: nil, click: twice, pressed: "s1", want: .select(.ignore)),
        PressCase(id: nil, old: nil, click: twice, want: .select(.ignore)),
        PressCase(id: "g1", old: "s1", click: twice, want: .select(.ignore)),
        PressCase(id: "s2", old: "s1", click: once, pressed: "s1", want: .select(.expand("s2"))),
        PressCase(id: "s2", old: "s1", pressed: "s1", want: .select(.ignore)),
    ])
    func aPressMeansOneThing(_ c: PressCase) {
        func source(_ id: String) -> CatalogSource {
            CatalogSource(id: id, ref: id, sourceTypeID: "t1", title: id, description: "", hasArtifact: true)
        }
        let graph = CatalogEvidenceGraph(
            id: "g1", ref: "GPH-1", sourceID: "s1", name: "Default", description: "", artifactIDs: ["a"]
        )
        let outline = SourcesOutline(
            sources: [source("s1"), source("s2")], graphs: { .loaded($0 == "s1" ? [graph] : []) }, open: "s1"
        )
        let pointer = SourcesPointer()
        pointer.pressed = c.pressed
        if let triangle = c.triangle { pointer.note(triangle, inside: true) }
        #expect(pointer.press(selecting: c.id, from: c.old, click: c.click, outline: outline) == c.want)
    }

    @Test func theTriangleHoverIsNotedAndCleared() {
        let pointer = SourcesPointer()
        pointer.note("s1", inside: true)
        #expect(pointer.sourceID == "s1")
        pointer.note("s2", inside: false)
        #expect(pointer.sourceID == "s1")
        pointer.note("s1", inside: false)
        #expect(pointer.sourceID == nil)
    }
}
