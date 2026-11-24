import SwiftUI

/// A Source's published date on a row: the Sources table's Published column and the Person page's Sources
/// section. Reads the date alone, or "Undated" in faint italics; the text is `SourceDateText`. Its ink goes
/// through `PVColor.onSelection`, so a selected row draws it on the system bar. `detail` gives the same
/// words to a `PVList` column.
struct PVPublishedDate: View {
    let date: CatalogDateValueInput?

    /// The words and hover text of a published date: the line, or `Undated` (faint, no hover text).
    static func detail(_ date: CatalogDateValueInput?, locale: Locale = .autoupdatingCurrent) -> PVListDetail {
        if let line = SourceDateText.line(date, locale: locale) {
            return PVListDetail(text: line, help: SourceDateText.help(date, locale: locale))
        }
        return PVListDetail(text: L10n.string(L10n.Dates.rowUndated), help: nil, faint: true)
    }

    var body: some View {
        let detail = Self.detail(date)
        let text = Text(verbatim: detail.text)
            .font(PVFont.body(size: PVTypeScale.caption))
            .foregroundStyle(PVColor.onSelection(detail.faint ? PVColor.textFaint : PVColor.textSecondary))
            .lineLimit(1)
            .truncationMode(.tail)
        if let help = detail.help {
            text.help(help)
        } else {
            text.italic()
        }
    }
}

#Preview("Published date") {
    let dates: [CatalogDateValueInput?] = [
        CatalogDateValueInput(kind: "point", startYear: 1880, startMonth: 6, startDay: 1),
        CatalogDateValueInput(kind: "point", phrase: "in the reign of Victoria"),
        nil,
    ]
    VStack(alignment: .leading, spacing: PVSpacing.space3) {
        ForEach(Array(dates.enumerated()), id: \.offset) { _, date in
            PVPublishedDate(date: date)
        }
    }
    .padding()
    .frame(width: 280, alignment: .leading)
}
