import Foundation
import Testing
@testable import Provenencia

@MainActor
struct PVPublishedDateTests {
    @Test func detailReadsTheLineOrUndated() {
        let en = Locale(identifier: "en_US")
        let point = CatalogDateValueInput(kind: "point", startYear: 1880, startMonth: 6, startDay: 1)
        let dated = PVPublishedDate.detail(point, locale: en)
        #expect(dated.text == "1 Jun 1880")
        #expect(dated.help == "Published 1 Jun 1880")
        #expect(!dated.faint)
        let undated = PVPublishedDate.detail(nil, locale: en)
        #expect(undated.text == "Undated")
        #expect(undated.help == nil)
        #expect(undated.faint)
        let column = PVPublishedDate.column(width: 140) { (value: CatalogDateValueInput?) in value }
        #expect(column.width == 140)
        #expect(column.content(nil)?.text == "Undated")
    }
}
