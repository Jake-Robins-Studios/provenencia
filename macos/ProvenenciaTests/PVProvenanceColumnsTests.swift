import Testing
@testable import Provenencia

struct PVProvenanceColumnsTests {
    @Test func columnsFollowTheWidthClass() {
        let regular = PVProvenanceColumns()
        #expect(regular.readAsWidth == 104 && regular.outcomeWidth == 128 && regular.panelWidth == 880)
        let wide = PVProvenanceColumns(widthClass: .wide)
        #expect(wide.readAsWidth == 160 && wide.outcomeWidth == 200 && wide.panelWidth == 1280)
        #expect(PVProvenanceColumns.recordWidth == 72 && PVProvenanceColumns.actionWidth == 88)
        #expect(PVProvenanceColumns.copyTrackWidth == 72 && PVProvenanceColumns.copyTrackSpacing == 8)
        #expect(regular.showsReadAs && !PVProvenanceColumns(showsReadAs: false).showsReadAs)
    }
}
