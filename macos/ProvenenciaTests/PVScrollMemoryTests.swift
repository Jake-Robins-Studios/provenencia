import Testing
@testable import Provenencia

/// The restore rule as a value: when it scrolls, and what it notes.
struct PVScrollMemoryTests {
    @Test func withNoYAViewGoesToTheTopAndIsDone() {
        for offset in [nil, 0] as [Double?] {
            var restore = PVScrollRestore(offset: offset)
            #expect(restore.arm(currentY: 300) == 0)
            #expect(restore.isDone)
            #expect(restore.arm(currentY: 0) == nil)
            #expect(restore.layout(reach: 2000) == nil)
        }
    }

    @Test func aReusedViewWaitsAtTheTop() {
        var restore = PVScrollRestore(offset: 1200)
        #expect(restore.arm(currentY: 900) == 0)
        #expect(!restore.isDone)
    }

    @Test func aRestoreAsksAgainAsTheReachGrowsAndIsDoneAtTheY() {
        var restore = PVScrollRestore(offset: 1200)
        #expect(restore.arm(currentY: 0) == nil)
        #expect(restore.layout(reach: 0) == nil)
        #expect(restore.layout(reach: 600) == 600)
        restore.landed(600)
        #expect(!restore.isDone)
        // No farther, or only back to where it reached before: nothing to ask.
        #expect(restore.layout(reach: 600) == nil)
        #expect(restore.layout(reach: 300) == nil)
        #expect(restore.layout(reach: 600) == nil)
        #expect(restore.layout(reach: 4000) == 1200)
        restore.landed(1200)
        #expect(restore.isDone)
        #expect(restore.layout(reach: 8000) == nil)
    }

    @Test func nothingIsNotedWhileArmed() {
        var restore = PVScrollRestore(offset: 1200)
        _ = restore.arm(currentY: 0)
        #expect(restore.bounds(0) == nil)
        #expect(restore.bounds(250) == nil)
        #expect(!restore.isDone)
        restore.input()
        #expect(restore.bounds(250) == 250)
        #expect(restore.bounds(0) == 0)
        #expect(restore.layout(reach: 4000) == nil)
    }
}
