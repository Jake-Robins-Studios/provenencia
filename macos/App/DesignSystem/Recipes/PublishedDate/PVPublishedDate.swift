import SwiftUI

/// A Source's published date on a row: the Sources list (under the type, on the
/// record line and in its Published column) and the Person page's Sources
/// section. `.labeled` reads "Published" then the date, or "No published date";
/// `.bare` reads the date alone, or "Undated". The text is `SourceDateText`.
struct PVPublishedDate: View {
    enum Style { case labeled, bare }

    let date: CatalogDateValueInput?
    let style: Style

    init(date: CatalogDateValueInput?, style: Style) {
        self.date = date
        self.style = style
    }

    var body: some View {
        if let line = SourceDateText.line(date) {
            dated(line)
        } else {
            undated
        }
    }

    @ViewBuilder
    private func dated(_ line: String) -> some View {
        switch style {
        case .labeled:
            HStack(spacing: PVSpacing.space2) {
                Text(L10n.PublishedDate.label)
                    .foregroundStyle(PVColor.textMuted)
                    .fixedSize()
                value(line)
            }
            .font(PVFont.body(size: PVTypeScale.caption))
            .help(L10n.PublishedDate.help(date: line))
        case .bare:
            value(line)
                .font(PVFont.body(size: PVTypeScale.caption))
                .help(L10n.PublishedDate.help(date: line))
        }
    }

    private func value(_ line: String) -> some View {
        Text(verbatim: line)
            .foregroundStyle(PVColor.textSecondary)
            .lineLimit(1)
            .truncationMode(.tail)
    }

    private var undated: some View {
        Group {
            switch style {
            case .labeled: Text(L10n.PublishedDate.none)
            case .bare: Text(L10n.Dates.rowUndated)
            }
        }
        .font(PVFont.body(size: PVTypeScale.caption))
        .italic()
        .foregroundStyle(PVColor.textSecondary)
        .lineLimit(1)
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
            PVPublishedDate(date: date, style: .labeled)
            PVPublishedDate(date: date, style: .bare)
        }
    }
    .padding()
    .frame(width: 280, alignment: .leading)
}
