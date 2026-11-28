import Foundation
import SwiftUI

/// A Person's birth and death as one secondary line: dates, then places.
/// A birth with no death keeps the dash after it; a death with no birth gets
/// the dash (or the arrow) before it, so it never reads as a birth.
enum PersonLifeDisplay {
    static func line(_ summary: CatalogPersonSummary, locale: Locale = .autoupdatingCurrent) -> String {
        let dates = dateSpan(birth: summary.birth.date, death: summary.death.date, locale: locale, precision: .full)
        let places = placeSpan(birth: summary.birth.places, death: summary.death.places)
        return PVDatePlaceLine.text(date: dates, place: places)
    }

    /// One life line: *b. 14 May 1817 · York*, *m. 12 Jun 1841 · Hamburg*. Date and place come already
    /// worded; nil when that half is not recorded.
    struct LifeLine: Equatable {
        var abbreviation: String
        var date: String?
        var place: String?
        /// Kept places beyond `place`. The list's +N.
        var extraPlaces: Int = 0
        /// Drawn after the place and never cut: ", with Heinrich Weber" on a marriage that names the
        /// other spouse.
        var trailing: String?
        /// How a missing half was built, so every drawer passes it on.
        var missing: PVDatePlaceLine.Missing
        var accessibilityLabel: String

        /// The line as plain text: the abbreviation, then date, place and `trailing`; a missing half is
        /// left out ("b. 3 May 1790 · Bremen", "d. 1851", "m., with Heinrich Weber").
        var text: String {
            let rest = PVDatePlaceLine.text(date: date, place: place)
            let tail = trailing ?? ""
            if rest.isEmpty { return abbreviation + tail }
            return L10n.LifeLine.text(abbreviation: abbreviation, rest: rest + tail)
        }
    }

    /// A Person's life span at year precision, for a compact card: "1790 – 1851",
    /// "1820 –", "– 1851". Empty when neither date has a year or a phrase.
    static func years(_ summary: CatalogPersonSummary?, locale: Locale = .autoupdatingCurrent) -> String {
        dateSpan(birth: summary?.birth.date, death: summary?.death.date, locale: locale, precision: .year)
    }

    /// The *b.* and *d.* lines of a Person.
    ///
    /// `missing` is how a half that is not recorded reads. `.stated` is the
    /// header: both lines always, the half "unknown", spoken in full ("Born 3
    /// May 1790, Bremen"). `.omitted` is a tile: only lines with a date or a
    /// place, the half left out, spoken mid-sentence in lowercase ("born 3 May
    /// 1790, Bremen"; "died 1851").
    static func lifeLines(
        _ summary: CatalogPersonSummary?,
        locale: Locale = .autoupdatingCurrent,
        missing: PVDatePlaceLine.Missing
    ) -> [LifeLine] {
        func line(_ copy: L10n.LifeLine.Copy, _ facts: CatalogLifeFacts?) -> LifeLine? {
            lifeLine(
                copy,
                date: dateText(facts?.date, locale: locale),
                place: DerivedPlace.name(facts?.places ?? []),
                extraPlaces: DerivedPlace.extra(facts?.places ?? []),
                missing: missing
            )
        }
        return [line(L10n.LifeLine.birth, summary?.birth), line(L10n.LifeLine.death, summary?.death)].compactMap { $0 }
    }

    /// One life line from a copy and its worded halves (nil or empty is not recorded).
    ///
    /// `.stated` speaks `copy.stated` with "unknown" for a missing half, and is nil for a copy with none.
    /// `.omitted` speaks the phrase for the halves present; with neither it speaks `copy.bare`, and is nil
    /// for a copy with none, so a person's missing b. or d. is left out and a marriage with neither half is
    /// kept. A `partner` is the other spouse of a copy that names one: spoken in the label, drawn as
    /// `trailing`.
    static func lifeLine(
        _ copy: L10n.LifeLine.Copy,
        date: String?,
        place: String?,
        extraPlaces: Int = 0,
        missing: PVDatePlaceLine.Missing,
        partner: PVTitleSource? = nil
    ) -> LifeLine? {
        let date = date.flatMap { $0.isEmpty ? nil : $0 }
        let place = place.flatMap { $0.isEmpty ? nil : $0 }
        let label: String
        var trailing: String?
        switch missing {
        case .stated:
            guard let stated = copy.stated else { return nil }
            label = L10n.format(stated, PVDatePlaceLine.spokenDate(date), PVDatePlaceLine.spokenPlace(place))
        case .omitted:
            if let partner, let spouse = copy.withSpouse {
                let name = partner.spokenText
                switch (date, place) {
                case let (date?, place?): label = L10n.format(spouse.dateAndPlace, date, place, name)
                case let (date?, nil): label = L10n.format(spouse.dateOnly, date, name)
                case let (nil, place?): label = L10n.format(spouse.placeOnly, place, name)
                case (nil, nil): label = L10n.format(spouse.bare, name)
                }
                trailing = L10n.format(spouse.drawn, partner.text)
            } else {
                switch (date, place) {
                case let (date?, place?): label = L10n.format(copy.dateAndPlace, date, place)
                case let (date?, nil): label = L10n.format(copy.dateOnly, date)
                case let (nil, place?): label = L10n.format(copy.placeOnly, place)
                case (nil, nil):
                    guard let bare = copy.bare else { return nil }
                    label = L10n.string(bare)
                }
            }
        }
        return LifeLine(
            abbreviation: L10n.string(copy.abbreviation),
            date: date,
            place: place,
            extraPlaces: extraPlaces,
            trailing: trailing,
            missing: missing,
            accessibilityLabel: label
        )
    }

    /// A couple's marriage (or any event type with life-line copy) as one line, always `.omitted`: the
    /// halves it has, or the bare phrase when it has neither. Nil for an event type with no copy, or one
    /// the product does not seed. `partner` is the other spouse, named when the line stands where the
    /// tile before it does not say so.
    static func eventLine(
        _ event: CatalogEventSummary,
        partner: PVTitleSource? = nil,
        locale: Locale = .autoupdatingCurrent
    ) -> LifeLine? {
        guard let copy = L10n.LifeLine.copy(eventTypeKey: event.eventTypeKey, origin: event.eventTypeOrigin) else {
            return nil
        }
        let content = EventSecondaryDisplay.content(event, locale: locale)
        return lifeLine(
            copy,
            date: content.date,
            place: content.place,
            extraPlaces: content.extraPlaces,
            missing: .omitted,
            partner: partner
        )
    }

    /// The date a life row shows. Empty when none is recorded.
    static func dateText(
        _ date: CatalogDateValueInput?,
        locale: Locale = .autoupdatingCurrent,
        precision: DateRowDisplay.Precision = .full
    ) -> String {
        guard let date else { return "" }
        return DateRowDisplay.line(date: date, precision: precision, locale: locale)
    }

    private static func dateSpan(
        birth: CatalogDateValueInput?,
        death: CatalogDateValueInput?,
        locale: Locale,
        precision: DateRowDisplay.Precision = .full
    ) -> String {
        let born = dateText(birth, locale: locale, precision: precision)
        let died = dateText(death, locale: locale, precision: precision)
        switch (born.isEmpty, died.isEmpty) {
        case (true, true):
            return ""
        case (false, true):
            return L10n.Conclusions.lifeSpanOpen(born: born)
        case (true, false):
            return L10n.Conclusions.lifeSpanDeathOnly(died: died)
        case (false, false):
            return L10n.Conclusions.lifeSpan(born: born, died: died)
        }
    }

    private static func placeSpan(birth: [CatalogChainedPlace], death: [CatalogChainedPlace]) -> String {
        let born = DerivedPlace.name(birth)
        let died = DerivedPlace.name(death)
        switch (born.isEmpty, died.isEmpty) {
        case (true, true):
            return ""
        case (false, true):
            return born
        case (true, false):
            return L10n.Conclusions.lifePlaceDeathOnly(died: died)
        case (false, false):
            return L10n.Conclusions.lifePlaces(born: born, died: died)
        }
    }
}

extension PVDatePlaceLine {
    /// A life line drawn as it was built: its abbreviation, date, place and `trailing`, with the
    /// `missing` it was built with. `showsExtraPlaces` adds the list's "+N" for its other places.
    init(_ line: PersonLifeDisplay.LifeLine, dateTone: Color = PVColor.textPrimary, showsExtraPlaces: Bool = false) {
        self.init(
            leading: line.abbreviation,
            date: line.date,
            place: line.place,
            accessibilityLabel: line.accessibilityLabel,
            missing: line.missing,
            dateTone: dateTone,
            extraCount: showsExtraPlaces ? line.extraPlaces : 0,
            trailing: line.trailing
        )
    }
}
