import Foundation

/// A date as a list row or page summary shows it: compact genealogical form
/// (`14 May 1817`, `abt 1810`, `bet 1803 and 1806`): one date, a start–end span,
/// or an event's dating. Editors keep `DateValueDisplay`.
enum DateRowDisplay {
    /// How much of a date a line shows. `.year` is a life span's: only the year of each
    /// side, with its qualifier ("abt 1790", "bet 1790 and 1795"); a side with no year
    /// shows nothing, and a date with only its phrase shows the phrase.
    enum Precision: Equatable, Sendable { case full, year }

    /// One date. Empty when nil. `includesPhrase: false` leaves off the words the source gave for the
    /// date ("in the spring"), for a place where the date sits inside a sentence.
    static func line(
        date: CatalogDateValueInput?,
        includesPhrase: Bool = true,
        precision: Precision = .full,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        guard let date else { return "" }
        return rowDate(date, includesPhrase: includesPhrase, precision: precision, locale: locale)
    }

    /// A start and an end as one span (`1849–1851`), or the one side recorded. Empty when neither is set.
    static func span(
        start: CatalogDateValueInput?,
        end: CatalogDateValueInput?,
        includesPhrase: Bool = true,
        precision: Precision = .full,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        let startText = line(date: start, includesPhrase: includesPhrase, precision: precision, locale: locale)
        let endText = line(date: end, includesPhrase: includesPhrase, precision: precision, locale: locale)
        switch (startText.isEmpty, endText.isEmpty) {
        case (true, true):
            return ""
        case (false, true):
            return startText
        case (true, false):
            return endText
        case (false, false):
            return L10n.Dates.rowSpan(start: startText, end: endText, locale: locale)
        }
    }

    /// An event's dating as Go chose it, in words: an occurrence is its date, a span its start and
    /// end, and an as-of dating says "as of" for each side that only an as-of date bounds. Empty
    /// when the event has no dating. The open sides are the engine's; this never picks a key.
    static func line(
        dating: CatalogEventDating,
        includesPhrase: Bool = true,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        switch dating.kind {
        case .none:
            return ""
        case .occurrence:
            return line(date: dating.low, includesPhrase: includesPhrase, locale: locale)
        case .span:
            return span(start: dating.low, end: dating.high, includesPhrase: includesPhrase, locale: locale)
        case .asOf:
            let low = line(date: dating.low, includesPhrase: includesPhrase, locale: locale)
            let high = line(date: dating.high, includesPhrase: includesPhrase, locale: locale)
            switch (dating.openLow, dating.openHigh) {
            case (true, true):
                if high.isEmpty { return low.isEmpty ? "" : L10n.Dates.rowAsOf(low, locale: locale) }
                if low.isEmpty { return L10n.Dates.rowAsOf(high, locale: locale) }
                return L10n.Dates.rowAsOfRange(start: low, end: high, locale: locale)
            case (false, true):
                if high.isEmpty { return low }
                return L10n.Dates.rowFromAsOf(start: low, asOf: high, locale: locale)
            case (true, false):
                if low.isEmpty { return high }
                return L10n.Dates.rowAsOfUntil(asOf: low, end: high, locale: locale)
            case (false, false):
                return span(start: dating.low, end: dating.high, includesPhrase: includesPhrase, locale: locale)
            }
        }
    }

    /// One date as the list shows it: day–month–year, qualifier abbreviations,
    /// and `bet … and …` for a range. At `.year` each side is only its year.
    private static func rowDate(
        _ input: CatalogDateValueInput,
        includesPhrase: Bool,
        precision: Precision,
        locale: Locale
    ) -> String {
        let draft = DateValueDraft(from: input)
        let phrase = includesPhrase ? draft.phrase : ""
        if draft.isRange {
            guard
                let start = side(year: draft.startYear, month: draft.startMonth, day: draft.startDay, precision: precision, locale: locale),
                let end = side(year: draft.endYear, month: draft.endMonth, day: draft.endDay, precision: precision, locale: locale)
            else {
                return ""
            }
            if precision == .year, start == end {
                return appendPhrase(start, phrase: phrase, locale: locale)
            }
            return appendPhrase(L10n.Dates.rowBetween(start: start, end: end, locale: locale), phrase: phrase, locale: locale)
        }
        guard let point = side(
            year: draft.startYear, month: draft.startMonth, day: draft.startDay, precision: precision, locale: locale
        ) else {
            switch precision {
            case .full: return DateValueDisplay.string(for: input, locale: locale)
            case .year: return appendPhrase("", phrase: phrase, locale: locale)
            }
        }
        return appendPhrase(applyQualifier(draft.qualifier, to: point, locale: locale), phrase: phrase, locale: locale)
    }

    /// One side of a date at `precision`; nil when it has nothing to show.
    private static func side(year: Int32?, month: Int32?, day: Int32?, precision: Precision, locale: Locale) -> String? {
        switch precision {
        case .full: civil(year: year, month: month, day: day, locale: locale)
        case .year: civil(year: year, month: nil, day: nil, locale: locale)
        }
    }

    private static func applyQualifier(_ raw: String, to point: String, locale: Locale) -> String {
        switch raw.trimmingCharacters(in: .whitespacesAndNewlines) {
        case DateQualifier.about:
            return L10n.Dates.rowAbout(point, locale: locale)
        case DateQualifier.before:
            return L10n.Dates.rowBefore(point, locale: locale)
        case DateQualifier.after:
            return L10n.Dates.rowAfter(point, locale: locale)
        default:
            return point
        }
    }

    /// Day, then the locale's abbreviated month, then the year. A missing
    /// piece is left out (`14 May 1817`, `Mar 1790`, `1851`).
    private static func civil(year: Int32?, month: Int32?, day: Int32?, locale: Locale) -> String? {
        let monthName: String? = {
            guard let month, (1...12).contains(month) else { return nil }
            var calendar = Calendar(identifier: .gregorian)
            calendar.locale = locale
            let symbols = calendar.shortMonthSymbols
            let index = Int(month) - 1
            guard symbols.indices.contains(index) else { return nil }
            return symbols[index]
        }()
        switch (day, monthName, year) {
        case let (day?, month?, year?):
            return L10n.Dates.rowDayMonthYear(day: day, month: month, year: year, locale: locale)
        case let (nil, month?, year?):
            return L10n.Dates.rowMonthYear(month: month, year: year, locale: locale)
        case let (day?, nil, year?):
            return L10n.Dates.rowDayYear(day: day, year: year, locale: locale)
        case let (nil, nil, year?):
            return "\(year)"
        case let (day?, month?, nil):
            return L10n.Dates.rowDayMonth(day: day, month: month, locale: locale)
        case let (nil, month?, nil):
            return month
        case let (day?, nil, nil):
            return "\(day)"
        case (nil, nil, nil):
            return nil
        }
    }

    private static func appendPhrase(_ structured: String, phrase: String, locale: Locale) -> String {
        let trimmed = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return structured }
        if structured.isEmpty { return trimmed }
        return L10n.Dates.rowWithPhrase(structured, phrase: trimmed, locale: locale)
    }
}
