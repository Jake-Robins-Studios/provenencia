import Foundation
import Testing
@testable import Provenencia

/// T-13 (AC-4.11, D-15): which row a second press belongs to.
struct SourcesPointerTests {
    @Test func aSecondPressBelongsToTheFirstRowWhileItIsTheSelection() {
        let pointer = SourcesPointer()
        pointer.notePress("s1")
        #expect(pointer.rowForSecondPress(clickCount: 2, selected: "s1", age: 0.2) == "s1")
        #expect(pointer.rowForSecondPress(clickCount: 3, selected: "s1", age: 0) == "s1")
        // No time limit between the presses: a slow double-click is the first row's too.
        #expect(pointer.rowForSecondPress(clickCount: 2, selected: "s1", age: 0.99) == "s1")
    }

    @Test func anythingElseBelongsToNoRow() {
        let pointer = SourcesPointer()
        // No press yet.
        #expect(pointer.rowForSecondPress(clickCount: 2, selected: "s1", age: 0) == nil)
        pointer.notePress("s1")
        // Another row is the selection, or none is.
        #expect(pointer.rowForSecondPress(clickCount: 2, selected: "s2", age: 0) == nil)
        #expect(pointer.rowForSecondPress(clickCount: 2, selected: nil, age: 0) == nil)
        // A first press, and an event a second old or more.
        #expect(pointer.rowForSecondPress(clickCount: 1, selected: "s1", age: 0) == nil)
        #expect(pointer.rowForSecondPress(clickCount: 0, selected: "s1", age: 0) == nil)
        #expect(pointer.rowForSecondPress(clickCount: 2, selected: "s1", age: 1) == nil)
        #expect(pointer.rowForSecondPress(clickCount: 2, selected: "s1", age: 10) == nil)
    }

    @Test func aConsumedPressBelongsToNoRow() {
        let pointer = SourcesPointer()
        pointer.notePress("s1")
        pointer.consumePress()
        #expect(pointer.rowForSecondPress(clickCount: 2, selected: "s1", age: 0) == nil)
    }

    @Test func aNewFirstPressReplacesTheRow() {
        let pointer = SourcesPointer()
        pointer.notePress("s1")
        pointer.notePress("s2")
        #expect(pointer.rowForSecondPress(clickCount: 2, selected: "s2", age: 0.1) == "s2")
        #expect(pointer.rowForSecondPress(clickCount: 2, selected: "s1", age: 0.1) == nil)
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
