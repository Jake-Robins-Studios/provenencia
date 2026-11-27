import Foundation
import Testing
@testable import Provenencia

struct PersonLifeDisplayTests {
    private let en = Locale(identifier: "en_US")

    private typealias Data = PersonFamilyPreviewData
    private let june1841 = PersonFamilyPreviewData.day(1841, 6, 12)

    @Test func eventLineWordsAndSpeaksAMarriage() throws {
        let full = try #require(PersonLifeDisplay.eventLine(Data.marriage("m1", june1841, place: "Hamburg"), locale: en))
        #expect(full.abbreviation == "m.")
        #expect(full.text == "m. 12 Jun 1841 · Hamburg")
        #expect(full.accessibilityLabel == "married 12 Jun 1841, Hamburg")
        #expect(full.missing == .omitted)

        let placeOnly = try #require(PersonLifeDisplay.eventLine(Data.marriage("m1", nil, place: "Altona"), locale: en))
        #expect(placeOnly.text == "m. Altona")
        #expect(placeOnly.accessibilityLabel == "married in Altona")

        let dateOnly = try #require(PersonLifeDisplay.eventLine(Data.marriage("m1", june1841, place: nil), locale: en))
        #expect(dateOnly.text == "m. 12 Jun 1841")
        #expect(dateOnly.accessibilityLabel == "married 12 Jun 1841")

        let neither = try #require(PersonLifeDisplay.eventLine(Data.marriage("m1", nil, place: nil), locale: en))
        #expect(neither.text == "m.")
        #expect(neither.accessibilityLabel == "married")
    }

    @Test func aNamedMarriageDrawsAndSpeaksTheOtherSpouse() throws {
        let heinrich = PVTitleSource.name("Heinrich Weber")
        let abt = CatalogDateValueInput(kind: "point", qualifier: "ABT", startYear: 1816)
        let named = try #require(PersonLifeDisplay.eventLine(Data.marriage("m1", abt, place: "Kiel"), partner: heinrich, locale: en))
        #expect(named.text == "m. abt 1816 · Kiel, with Heinrich Weber")
        #expect(named.trailing == ", with Heinrich Weber")
        #expect(named.accessibilityLabel == "married abt 1816, Kiel, with Heinrich Weber")

        let bare = try #require(PersonLifeDisplay.eventLine(Data.marriage("m1", nil, place: nil), partner: heinrich, locale: en))
        #expect(bare.text == "m., with Heinrich Weber")
        #expect(bare.accessibilityLabel == "married, with Heinrich Weber")
    }

    @Test func aTypeWithNoCopyOrNotTheProductsDrawsNoLine() {
        #expect(PersonLifeDisplay.eventLine(Data.marriage("m1", june1841, place: "Hamburg", type: SeededEventTypeTerm.burial), locale: en) == nil)
        var user = Data.marriage("m1", june1841, place: "Hamburg")
        user.eventTypeOrigin = "user"
        #expect(PersonLifeDisplay.eventLine(user, locale: en) == nil)
    }

    @Test func eventLineKeepsTheExtraPlaces() throws {
        var event = Data.marriage("m1", june1841, place: "Hamburg")
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
