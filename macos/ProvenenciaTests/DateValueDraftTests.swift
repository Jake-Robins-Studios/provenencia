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

    @Test func cascadeGapIsValid() {
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

    @Test func applyStartCascadeDoesNotWipeIndependentFields() {
        var d = DateValueDraft.empty()
        d.startYear = 2000
        d.startMonth = 4
        d.startDay = 10
        d.startHour = 8
        d.startDay = nil
        d.applyStartCascade()
        #expect(d.startMonth == 4)
        #expect(d.startHour == 8)
    }

    @Test func dayOutOfRangeShowsFieldError() {
        var d = DateValueDraft.empty()
        d.startYear = 1890
        d.startMonth = 5
        d.startDay = 1890
        #expect(d.isFieldInvalid(.day, start: true))
        #expect(d.fieldError(.day, start: true) != nil)
        #expect(d.cascadeFieldError(start: true) != nil)
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
        #expect(month13.incompleteError == nil)

        var backwards = DateValueDraft.empty()
        backwards.setKind("range")
        backwards.startYear = 1880
        backwards.endYear = 1879
        #expect(backwards.shownError(start: false) != nil)
        #expect(backwards.incompleteError == nil)

        var phraseAndZone = DateValueDraft.empty()
        phraseAndZone.phrase = "Spring 1880"
        phraseAndZone.startTZ = "America/Chicago"
        #expect(phraseAndZone.shownError(start: true) == nil)
        #expect(phraseAndZone.shownError(start: false) == nil)
        #expect(phraseAndZone.incompleteError == L10n.string(L10n.Sources.dateIncompleteError))

        var endOnly = DateValueDraft.empty()
        endOnly.setKind("range")
        endOnly.endYear = 1880
        #expect(endOnly.shownError(start: true) == nil)
        #expect(endOnly.shownError(start: false) == nil)
        #expect(endOnly.incompleteError == L10n.string(L10n.Sources.dateIncompleteError))

        var blank = DateValueDraft.empty()
        #expect(blank.shownError(start: true) == nil)
        #expect(blank.shownError(start: false) == nil)
        #expect(blank.incompleteError == nil)
        #expect(blank.value == nil)
        blank.showAdvanced = true
        #expect(blank.value == nil)

        var year = DateValueDraft.empty()
        year.startYear = 1880
        #expect(year.value?.startYear == 1880)
    }
}
