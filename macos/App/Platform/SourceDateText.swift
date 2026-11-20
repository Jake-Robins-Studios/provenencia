import Foundation

/// The text a row says about a Source's published date, in one place: a date
/// whose line is empty counts as undated. `PVPublishedDate` draws it; the Source
/// page header and the Copy Source form read the line.
enum SourceDateText {
    static func line(_ date: CatalogDateValueInput?, locale: Locale = .autoupdatingCurrent) -> String? {
        guard let date else { return nil }
        let line = DateRowDisplay.line(date: date, locale: locale)
        return line.isEmpty ? nil : line
    }

    static func help(_ date: CatalogDateValueInput?, locale: Locale = .autoupdatingCurrent) -> String? {
        line(date, locale: locale).map(L10n.PublishedDate.help(date:))
    }

    static func spoken(_ date: CatalogDateValueInput?, locale: Locale = .autoupdatingCurrent) -> String {
        line(date, locale: locale).map(L10n.PublishedDate.spoken(date:))
            ?? L10n.string(L10n.PublishedDate.noneSpoken)
    }

    /// What VoiceOver reads for a Source's row: the record's facts, then its ref.
    static func spokenRow(
        title: String, type: String, ref: String, date: CatalogDateValueInput?,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        L10n.DesignSystem.spokenJoin([title, type, spoken(date, locale: locale), ref]) ?? title
    }
}
