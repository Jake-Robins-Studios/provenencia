import Testing
@testable import Provenencia

struct PVProvenanceColumnsTests {
    @Test func columnsFollowTheWidthClass() {
        let regular = PVProvenanceColumns()
        #expect(regular.readAsWidth == 104 && regular.outcomeWidth == 128 && regular.panelWidth == 880)
        let wide = PVProvenanceColumns(widthClass: .wide)
        #expect(wide.readAsWidth == 160 && wide.outcomeWidth == 200 && wide.panelWidth == 1280)
        #expect(PVProvenanceColumns.recordWidth == 72)
        #expect(PVProvenanceColumns.copyTrackWidth == 84 && PVProvenanceColumns.copyTrackSpacing == 8)
        #expect(PVProvenanceColumns.scrollBarInset == PVSpacing.space5)
        #expect(regular.showsReadAs && !PVProvenanceColumns(showsReadAs: false).showsReadAs)
    }
}
