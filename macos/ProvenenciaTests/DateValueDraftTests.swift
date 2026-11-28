import Foundation
import Testing
@testable import Provenencia

@Suite
struct DateValueDraftTests {
    @Test func pointYearABTIsValid() {
        var d = DateValueDraft.empty()
        d.qualifier = "ABT"
        d.startYear = 1890
        #expect(d.isValid)
    }

    @Test func pointFullDayIsValid() {
        var d = DateValueDraft.empty()
        d.startYear = 1985
        d.startMonth = 5
        d.startDay = 14
        #expect(d.isValid)
    }

    @Test func rangeYearsIsValid() {
        var d = DateValueDraft.empty()
        d.setKind("range")
        d.startYear = 1880
        d.endYear = 1885
        #expect(d.isValid)
        #expect(d.endError == nil)
    }

    @Test func phraseOnlyIsValid() {
        var d = DateValueDraft.empty()
        d.phrase = "Christmas"
        #expect(d.isValid)
    }

    @Test func emptyWithoutPhraseIsInvalid() {
        let d = DateValueDraft.empty()
        #expect(!d.isValid)
    }

    @Test func rangeEndBeforeStartIsInvalid() {
        var d = DateValueDraft.empty()
        d.setKind("range")
        d.startYear = 1890
        d.endYear = 1880
        #expect(!d.isValid)
        #expect(d.endError != nil)
    }

    @Test func partGapIsValid() {
        var d = DateValueDraft.empty()
        d.startYear = 1900
        d.startDay = 5
        #expect(d.isValid)
    }

    @Test func monthOnlyIsValid() {
        var d = DateValueDraft.empty()
        d.startMonth = 5
        #expect(d.isValid)
    }

    @Test func setKindRangeClearsQualifier() {
        var d = DateValueDraft.empty()
        d.qualifier = "ABT"
        d.startYear = 1900
        d.setKind("range")
        #expect(d.qualifier == "")
        d.endYear = 1901
        #expect(d.isValid)
    }

    @Test func toInputMapsPointComponents() {
        var d = DateValueDraft.empty()
        d.qualifier = "BEF"
        d.startYear = 1920
        d.startMonth = 6
        let input = d.toInput()
        #expect(input.kind == "point")
        #expect(input.qualifier == "BEF")
        #expect(input.startYear == 1920)
        #expect(input.startMonth == 6)
        #expect(input.endYear == nil)
    }

    @Test func dayOutOfRangeShowsFieldError() {
        var d = DateValueDraft.empty()
        d.startYear = 1890
        d.startMonth = 5
        d.startDay = 1890
        #expect(d.isFieldInvalid(.day, start: true))
        #expect(d.fieldError(.day, start: true) != nil)
        #expect(d.firstPartError(start: true) != nil)
        #expect(!d.isValid)
    }

    @Test func hourOutOfRangeShowsFieldError() {
        var d = DateValueDraft.empty()
        d.startYear = 1911
        d.startMonth = 3
        d.startDay = 3
        d.startHour = 30
        #expect(d.isFieldInvalid(.hour, start: true))
        #expect(!d.isValid)
    }

    @Test func shownAndIncompleteErrors() {
        var month13 = DateValueDraft.empty()
        month13.startYear = 1880
        month13.startMonth = 13
        #expect(month13.shownError(start: true) != nil)
        #expect(month13.unsavableError == nil)

        var backwards = DateValueDraft.empty()
        backwards.setKind("range")
        backwards.startYear = 1880
        backwards.endYear = 1879
        #expect(backwards.shownError(start: false) != nil)
        #expect(backwards.unsavableError == nil)

        var phraseAndZone = DateValueDraft.empty()
        phraseAndZone.phrase = "Spring 1880"
        phraseAndZone.startTZ = "America/Chicago"
        #expect(phraseAndZone.shownError(start: true) == nil)
        #expect(phraseAndZone.shownError(start: false) == nil)
        #expect(phraseAndZone.unsavableError == L10n.string(L10n.Sources.dateUnsavableZone))

        var endOnly = DateValueDraft.empty()
        endOnly.setKind("range")
        endOnly.endYear = 1880
        #expect(endOnly.shownError(start: true) == nil)
        #expect(endOnly.shownError(start: false) == nil)
        #expect(endOnly.unsavableError == L10n.string(L10n.Sources.dateUnsavableRangeStart))

        var blank = DateValueDraft.empty()
        #expect(blank.shownError(start: true) == nil)
        #expect(blank.shownError(start: false) == nil)
        #expect(blank.unsavableError == nil)
        #expect(blank.value == nil)
        blank.showAdvanced = true
        #expect(blank.value == nil)

        var year = DateValueDraft.empty()
        year.startYear = 1880
        #expect(year.value?.startYear == 1880)
    }

    @Test func unsavableErrors() {
        var both = DateValueDraft.empty()
        both.setKind("range")
        both.phrase = "Spring 1880"
        #expect(both.unsavableError == L10n.string(L10n.Sources.dateUnsavableRangeBoth))

        var startMissing = DateValueDraft.empty()
        startMissing.setKind("range")
        startMissing.endYear = 1880
        #expect(startMissing.unsavableError == L10n.string(L10n.Sources.dateUnsavableRangeStart))

        var endMissing = DateValueDraft.empty()
        endMissing.setKind("range")
        endMissing.startYear = 1880
        #expect(endMissing.unsavableError == L10n.string(L10n.Sources.dateUnsavableRangeEnd))

        var zone = DateValueDraft.empty()
        zone.startTZ = "America/Chicago"
        zone.phrase = "Spring 1880"
        #expect(zone.unsavableError == L10n.string(L10n.Sources.dateUnsavableZone))

        var millisecond = DateValueDraft.empty()
        millisecond.startMillisecond = 5
        #expect(millisecond.unsavableError == L10n.string(L10n.Sources.dateUnsavableMillisecond))

        var both2 = DateValueDraft.empty()
        both2.startMillisecond = 5
        both2.startTZ = "America/Chicago"
        #expect(both2.unsavableError == L10n.string(L10n.Sources.dateUnsavableZoneAndMillisecond))

        var other = DateValueDraft.empty()
        other.startYear = 1880
        other.qualifier = "nonsense"
        #expect(other.unsavableError == L10n.string(L10n.Sources.dateUnsavableOther))
    }

    @Test func latestOnlyMessageKeepsTheBound() {
        var d = DateValueDraft.empty()
        d.setKind("range")
        d.endYear = 1880
        #expect(d.unsavableError == L10n.string(L10n.Sources.dateUnsavableRangeStart))
        #expect(d.unsavableError?.contains("Single date") == false)
    }

    @Test func loadKeepsTimeAndNothingFillsIn() {
        var input = DateValueDraft.empty().toInput()
        input.startTZ = "Europe/London"
        let zoneOnly = DateValueDraft(from: input)
        #expect(zoneOnly.startTZ == "Europe/London")
        #expect(!zoneOnly.isValid)

        var d = DateValueDraft.empty()
        d.startYear = 1880
        d.setKind("range")
        #expect(d.endYear == nil)

        d.endMonth = 4
        #expect(d[keyPath: DateValueDraft.part(.month, start: false)] == 4)
        d[keyPath: DateValueDraft.part(.month, start: false)] = 5
        #expect(d.endMonth == 5)

        d.endDay = 32
        #expect(d.fieldError(.day, start: false) == L10n.string(L10n.Sources.dateDayOutOfRange))

        d.endYear = 1881
        d.endHour = 9
        d.endTZ = "Europe/London"
        d.setKind("point")
        for component in DateValueDraft.Part.allCases {
            #expect(d[keyPath: DateValueDraft.part(component, start: false)] == nil)
        }
        #expect(d.endTZ.isEmpty)
    }
}
