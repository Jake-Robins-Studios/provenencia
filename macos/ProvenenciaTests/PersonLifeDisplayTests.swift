import Foundation
import Testing
@testable import Provenencia

struct PersonLifeDisplayTests {
    private let en = Locale(identifier: "en_US")

    private func marriage(
        date: CatalogDateValueInput? = CatalogDateValueInput(kind: "point", startYear: 1841, startMonth: 6, startDay: 12),
        place: String? = "Hamburg",
        type: String = SeededEventTypeTerm.marriage
    ) -> CatalogEventSummary {
        PersonTimelinePreviewData.eventSummary(
            "m1",
            type: type,
            dating: date.map { CatalogEventDating(kind: .occurrence, low: $0) },
            place: place
        )
    }

    @Test func eventLineWordsAndSpeaksAMarriage() throws {
        let full = try #require(PersonLifeDisplay.eventLine(marriage(), locale: en))
        #expect(full.abbreviation == "m.")
        #expect(full.text == "m. 12 Jun 1841 · Hamburg")
        #expect(full.accessibilityLabel == "married 12 Jun 1841, Hamburg")
        #expect(full.missing == .omitted)

        let placeOnly = try #require(PersonLifeDisplay.eventLine(marriage(date: nil, place: "Altona"), locale: en))
        #expect(placeOnly.text == "m. Altona")
        #expect(placeOnly.accessibilityLabel == "married in Altona")

        let dateOnly = try #require(PersonLifeDisplay.eventLine(marriage(place: nil), locale: en))
        #expect(dateOnly.text == "m. 12 Jun 1841")
        #expect(dateOnly.accessibilityLabel == "married 12 Jun 1841")

        let neither = try #require(PersonLifeDisplay.eventLine(marriage(date: nil, place: nil), locale: en))
        #expect(neither.text == "m.")
        #expect(neither.accessibilityLabel == "married")
    }

    @Test func aNamedMarriageDrawsAndSpeaksTheOtherSpouse() throws {
        let heinrich = PVTitleSource.name("Heinrich Weber")
        let abt = CatalogDateValueInput(kind: "point", qualifier: "ABT", startYear: 1816)
        let named = try #require(PersonLifeDisplay.eventLine(marriage(date: abt, place: "Kiel"), partner: heinrich, locale: en))
        #expect(named.text == "m. abt 1816 · Kiel, with Heinrich Weber")
        #expect(named.trailing == ", with Heinrich Weber")
        #expect(named.accessibilityLabel == "married abt 1816, Kiel, with Heinrich Weber")

        let bare = try #require(PersonLifeDisplay.eventLine(marriage(date: nil, place: nil), partner: heinrich, locale: en))
        #expect(bare.text == "m., with Heinrich Weber")
        #expect(bare.accessibilityLabel == "married, with Heinrich Weber")
    }

    @Test func aTypeWithNoCopyOrNotTheProductsDrawsNoLine() {
        #expect(PersonLifeDisplay.eventLine(marriage(type: SeededEventTypeTerm.burial), locale: en) == nil)
        var user = marriage()
        user.eventTypeOrigin = "user"
        #expect(PersonLifeDisplay.eventLine(user, locale: en) == nil)
    }

    @Test func eventLineKeepsTheExtraPlaces() throws {
        var event = marriage()
        event.places.append(PersonTimelinePreviewData.bremen)
        let line = try #require(PersonLifeDisplay.eventLine(event, locale: en))
        #expect(line.extraPlaces == 1)
    }

    @Test func aListJoinsNamesAsTheLocaleReadsThem() {
        #expect(L10n.list(["A", "B"], locale: en) == "A and B")
        #expect(L10n.list(["A", "B", "C"], locale: en) == "A, B, and C")
        #expect(L10n.list(["A"], locale: en) == "A")
    }
}
