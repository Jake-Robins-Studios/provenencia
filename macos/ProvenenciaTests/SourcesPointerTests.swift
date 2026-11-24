import Foundation
import Testing
@testable import Provenencia

/// T-13 (AC-4.11, D-15): which row a second press belongs to.
struct SourcesPointerTests {
    private let interval: TimeInterval = 0.5

    @Test func aSecondPressWithinTheIntervalBelongsToTheFirstRow() {
        let pointer = SourcesPointer()
        pointer.notePress("s1", at: 100)
        #expect(pointer.rowForSecondPress(clickCount: 2, now: 100.2, interval: interval) == "s1")
        #expect(pointer.rowForSecondPress(clickCount: 3, now: 100.5, interval: interval) == "s1")
    }

    @Test func anythingElseBelongsToNoRow() {
        let pointer = SourcesPointer()
        // No press yet.
        #expect(pointer.rowForSecondPress(clickCount: 2, now: 100, interval: interval) == nil)
        pointer.notePress("s1", at: 100)
        // A first press, and a press after the interval.
        #expect(pointer.rowForSecondPress(clickCount: 1, now: 100.1, interval: interval) == nil)
        #expect(pointer.rowForSecondPress(clickCount: 0, now: 100.1, interval: interval) == nil)
        #expect(pointer.rowForSecondPress(clickCount: 2, now: 100.6, interval: interval) == nil)
    }

    @Test func aNewFirstPressReplacesTheRow() {
        let pointer = SourcesPointer()
        pointer.notePress("s1", at: 100)
        pointer.notePress("s2", at: 101)
        #expect(pointer.rowForSecondPress(clickCount: 2, now: 101.1, interval: interval) == "s2")
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
