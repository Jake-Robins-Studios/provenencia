import Foundation
import Testing
@testable import Provenencia

@Suite
struct DateRowDisplayTests {
    private let en = Locale(identifier: "en_US")

    @Test func spanIsTheStartAndEndOrTheOneSideRecorded() {
        let start = CatalogDateValueInput(kind: "point", startYear: 1849)
        let end = CatalogDateValueInput(kind: "point", startYear: 1851)
        #expect(DateRowDisplay.span(start: start, end: end, locale: en) == "1849–1851")
        #expect(DateRowDisplay.span(start: start, end: nil, locale: en) == "1849")
        #expect(DateRowDisplay.span(start: nil, end: end, locale: en) == "1851")
        #expect(DateRowDisplay.span(start: nil, end: nil, locale: en) == "")
        #expect(DateRowDisplay.line(date: nil, locale: en) == "")
    }

    private func point(_ year: Int32, _ month: Int32? = nil, _ day: Int32? = nil, qualifier: String = "") -> CatalogDateValueInput {
        CatalogDateValueInput(kind: "point", qualifier: qualifier, startYear: year, startMonth: month, startDay: day)
    }

    @Test func lineWordsADatesRole() throws {
        let from = DateRowDisplay.line(date: point(1985), role: .from, locale: en)
        #expect(from.text == "from 1985")
        let styled = try #require(from.styled)
        let dateText = styled.runs.filter { $0.attributes[DateRowDisplay.DateRun.self] == true }.map { String(styled[$0.range].characters) }
        #expect(dateText == ["1985"])
        #expect(DateRowDisplay.line(date: point(1990, qualifier: "ABT"), role: .asOf, locale: en).text == "as of abt 1990")
        #expect(DateRowDisplay.line(date: point(2015), role: .until, locale: en).text == "until 2015")
        let plain = DateRowDisplay.line(date: point(1985), role: .plain, locale: en)
        #expect(plain.text == "1985" && plain.styled == nil)
        let none = DateRowDisplay.line(date: nil, role: .from, locale: en)
        #expect(none.text == "" && none.styled == nil)
    }

    @Test func datingLinesKeepTheStringsEveryEventWithADateHadBefore() {
        func line(_ dating: CatalogEventDating) -> String { DateRowDisplay.line(dating: dating, locale: en) }
        #expect(line(CatalogEventDating(kind: .occurrence, low: point(1817, 5, 14))) == "14 May 1817")
        #expect(line(CatalogEventDating(kind: .span, low: point(1985), high: point(2015))) == "1985–2015")
        #expect(line(CatalogEventDating(kind: .span, low: point(1985), high: point(1985))) == "1985–1985")
        #expect(line(CatalogEventDating(kind: .span, low: point(1985), openHigh: true)) == "1985")
        #expect(line(CatalogEventDating(kind: .span, high: point(2015), openLow: true)) == "2015")
        #expect(line(CatalogEventDating()) == "")
    }

    @Test func anAsOfDatingSaysWhichSidesAreOpen() {
        func line(_ dating: CatalogEventDating) -> String { DateRowDisplay.line(dating: dating, locale: en) }
        #expect(line(CatalogEventDating(kind: .asOf, low: point(1990, 1, 10), high: point(2015, 2, 10), openLow: true, openHigh: true))
            == "as of 10 Jan 1990–10 Feb 2015")
        #expect(line(CatalogEventDating(kind: .asOf, low: point(1990, 1, 10), openLow: true, openHigh: true)) == "as of 10 Jan 1990")
        #expect(line(CatalogEventDating(kind: .asOf, low: point(1985), high: point(2015, 2, 10), openHigh: true))
            == "from 1985, as of 10 Feb 2015")
        #expect(line(CatalogEventDating(kind: .asOf, low: point(1990), high: point(2015), openLow: true)) == "as of 1990, until 2015")
        #expect(line(CatalogEventDating(
            kind: .asOf, low: point(1990, qualifier: "ABT"), high: point(2015, qualifier: "BEF"), openLow: true, openHigh: true
        )) == "as of abt 1990–bef 2015")
        var range = CatalogDateValueInput(kind: "range", startYear: 1985)
        range.endYear = 1995
        #expect(line(CatalogEventDating(kind: .asOf, low: range, openLow: true, openHigh: true)) == "as of bet 1985 and 1995")
    }

    @Test func dateLineCanLeaveOffThePhrase() {
        var spring = CatalogDateValueInput(kind: "point", startYear: 1842)
        spring.phrase = "in the spring"
        #expect(DateRowDisplay.line(date: spring, locale: en).contains("in the spring"))
        #expect(DateRowDisplay.line(date: spring, includesPhrase: false, locale: en) == "1842")
    }

    @Test func dateLineKeepsQualifiersAndRanges() {
        let about = CatalogDateValueInput(kind: "point", qualifier: "ABT", startYear: 1810)
        let before = CatalogDateValueInput(kind: "point", qualifier: "BEF", startYear: 1790, startMonth: 3)
        let after = CatalogDateValueInput(kind: "point", qualifier: "AFT", startYear: 1880)
        var range = CatalogDateValueInput(kind: "range", startYear: 1803)
        range.endYear = 1806
        #expect(DateRowDisplay.line(date: about, locale: en) == "abt 1810")
        #expect(DateRowDisplay.line(date: before, locale: en) == "bef Mar 1790")
        #expect(DateRowDisplay.line(date: after, locale: en) == "aft 1880")
        #expect(DateRowDisplay.line(date: range, locale: en) == "bet 1803 and 1806")
    }

    @Test func yearPrecision() {
        func year(_ input: CatalogDateValueInput) -> String {
            DateRowDisplay.line(date: input, precision: .year, locale: en)
        }
        let day = CatalogDateValueInput(kind: "point", startYear: 1790, startMonth: 5, startDay: 3)
        #expect(year(day) == "1790")
        #expect(DateRowDisplay.line(date: day, precision: .full, locale: en) == "3 May 1790")
        #expect(DateRowDisplay.line(date: day, locale: en) == "3 May 1790")
        var about = day
        about.qualifier = "ABT"
        #expect(year(about) == "abt 1790")
        #expect(year(CatalogDateValueInput(kind: "point", qualifier: "BEF", startYear: 1790)) == "bef 1790")
        var range = CatalogDateValueInput(kind: "range", startYear: 1790)
        range.endYear = 1795
        #expect(year(range) == "bet 1790 and 1795")
        range.endYear = 1790
        #expect(year(range) == "1790")
        #expect(year(CatalogDateValueInput(kind: "point", startYear: 1790, startMonth: 5)) == "1790")
        #expect(year(CatalogDateValueInput(kind: "point", startMonth: 5)) == "")
        var phraseOnly = CatalogDateValueInput(kind: "point")
        phraseOnly.phrase = "in the spring"
        #expect(year(phraseOnly) == "in the spring")
    }
}
