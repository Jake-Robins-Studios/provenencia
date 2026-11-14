import CoreGraphics
import Testing
@testable import Provenencia

@Suite
struct FittedScrollHeightTests {
    @Test func checklistHeightFitsItsRows() {
        #expect(PVFittedScrollHeight.height(content: 180, cap: 352) == 180)
        #expect(PVFittedScrollHeight.height(content: 500, cap: 352) == 352)
        #expect(PVFittedScrollHeight.height(content: 0, cap: 352) == 0)
    }
}
