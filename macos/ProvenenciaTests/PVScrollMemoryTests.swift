import Testing
@testable import Provenencia

/// D-6 as a value: when a restore scrolls, and what it notes.
struct PVScrollMemoryTests {
    private let visible = 700.0

    /// T-1 (D-6, AC-1.5 – AC-1.8).
    @Test func aRestoreLandsOnceTheContentFits() {
        // Armed with no y: a view at the top stays, a view elsewhere goes to the top, and it is done.
        var none = PVScrollRestore(offset: nil)
        #expect(none.arm(currentY: 0) == nil)
        #expect(none.isDone)
        var reused = PVScrollRestore(offset: nil)
        #expect(reused.arm(currentY: 300) == 0)
        #expect(reused.isDone)
        var zero = PVScrollRestore(offset: 0)
        #expect(zero.arm(currentY: 300) == 0)
        var unreadable = PVScrollRestore(offset: -4)
        #expect(unreadable.arm(currentY: 0) == nil && unreadable.isDone)

        // A y waits until the document is tall enough, then scrolls once.
        var late = PVScrollRestore(offset: 1200)
        #expect(late.arm(currentY: 0) == nil)
        #expect(!late.isDone)
        #expect(late.layout(currentY: 0, documentHeight: 900, visibleHeight: visible, topInset: 0) == nil)
        #expect(late.layout(currentY: 0, documentHeight: 2000, visibleHeight: visible, topInset: 0) == 1200)
        #expect(late.isDone)
        #expect(late.layout(currentY: 0, documentHeight: 4000, visibleHeight: visible, topInset: 0) == nil)

        // The last y that fits is the document height less the visible part; one more does not.
        var exact = PVScrollRestore(offset: 1300)
        _ = exact.arm(currentY: 0)
        #expect(exact.layout(currentY: 0, documentHeight: 2000, visibleHeight: visible, topInset: 0) == 1300)
        var over = PVScrollRestore(offset: 1301)
        _ = over.arm(currentY: 0)
        #expect(over.layout(currentY: 0, documentHeight: 2000, visibleHeight: visible, topInset: 0) == nil)
        // A header inset is not part of the visible rows.
        var inset = PVScrollRestore(offset: 1330)
        _ = inset.arm(currentY: 0)
        #expect(inset.layout(currentY: 0, documentHeight: 2000, visibleHeight: visible, topInset: 30) == 1330)

        // While armed, the top is not noted and any other y is the researcher's, and disarms.
        var armedAtTop = PVScrollRestore(offset: 1200)
        _ = armedAtTop.arm(currentY: 0)
        #expect(armedAtTop.bounds(0) == nil)
        #expect(!armedAtTop.isDone)
        var scrolled = PVScrollRestore(offset: 1200)
        _ = scrolled.arm(currentY: 0)
        #expect(scrolled.bounds(1) == 1)
        #expect(scrolled.isDone)
        #expect(scrolled.layout(currentY: 1, documentHeight: 4000, visibleHeight: visible, topInset: 0) == nil)

        // Once done, every change is noted.
        var done = PVScrollRestore(offset: nil)
        _ = done.arm(currentY: 0)
        #expect(done.bounds(40) == 40)
        #expect(done.bounds(0) == 0)
    }
}
