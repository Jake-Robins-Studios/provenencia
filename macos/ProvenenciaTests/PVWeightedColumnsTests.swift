import SwiftUI
import Testing
@testable import Provenencia

/// `PVWeightedColumns`: the width rule and the placement rule, driven without a view.
@Suite
struct PVWeightedColumnsTests {
    @Test func flexibleColumnsShareTheFreeWidthByWeight() {
        #expect(PVWeightedColumns.widths(fixed: [nil, nil, 100], weights: [1, 2, 1], total: 1000, spacing: 0) == [300, 600, 100])
        // Spacing between three columns takes 20 of the free width.
        let spaced = PVWeightedColumns.widths(fixed: [nil, nil, 100], weights: [1, 2, 1], total: 1000, spacing: 10)
        #expect(abs(spaced[0] - 880.0 / 3) < 0.001)
        #expect(abs(spaced[1] - 1760.0 / 3) < 0.001)
        #expect(spaced[2] == 100)
        #expect(PVWeightedColumns.widths(fixed: [50, 60], weights: [1, 1], total: 1000, spacing: 10) == [50, 60])
    }

    @Test func aWeightAtOrBelowZeroOrNotFiniteCountsAsOne() {
        #expect(PVWeightedColumns.widths(fixed: [nil, nil], weights: [0, 1], total: 100, spacing: 0) == [50, 50])
        #expect(PVWeightedColumns.widths(fixed: [nil, nil], weights: [-3, 1], total: 100, spacing: 0) == [50, 50])
        #expect(PVWeightedColumns.widths(fixed: [nil, nil], weights: [.nan, 1], total: 100, spacing: 0) == [50, 50])
        #expect(PVWeightedColumns.widths(fixed: [nil, nil], weights: [.infinity, 1], total: 100, spacing: 0) == [50, 50])
    }

    @Test func aColumnBeyondTheArraysIsFlexibleWithWeightOne() {
        #expect(PVWeightedColumns.widths(fixed: [], weights: [1, 1, 2], total: 400, spacing: 0) == [100, 100, 200])
        #expect(PVWeightedColumns.widths(fixed: [100, nil, nil], weights: [1], total: 300, spacing: 0) == [100, 100, 100])
    }

    @Test func shorterCellsCenterInTheRow() {
        #expect(PVWeightedColumns.cellY(height: 18, rowHeight: 30, alignment: .center) == 6)
        #expect(PVWeightedColumns.cellY(height: 18, rowHeight: 30, alignment: .top) == 0)
        #expect(PVWeightedColumns.cellY(height: 40, rowHeight: 30, alignment: .center) == 0)
    }

    @Test func withNoProposedWidthTheTotalIsFixedWidthsIdealsAndGaps() {
        // Column 0 is fixed at 50 (its measured 80 is ignored); 1 and 2 use their ideals; two gaps of 10.
        #expect(PVWeightedColumns.idealTotal(fixed: [50], idealWidths: [80, 30, 20], spacing: 10) == 120)
        #expect(PVWeightedColumns.idealTotal(fixed: [], idealWidths: [], spacing: 10) == 0)
    }
}
