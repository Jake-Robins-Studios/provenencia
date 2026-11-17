import Foundation

/// The Event page, worded from one `CatalogConclusionDetail` and the Event
/// summary it carries (S9-24, board S9-D6). The summary supplies the title, the
/// kept date or span (the band) and the places. The date's Why stays on this page's date row.
struct EventDetailContent: ConclusionDetailBody {
    var title: PVTitleSource
    var ref: String
    var showsRef: Bool { if case .ref = title { false } else { true } }
    var members: String
    /// Compact date under the title, from the summary's kept date or span. Nil when it has none.
    var secondaryDate: String?
    /// First place name under the title, from the summary's places. Nil when it has none.
    var secondaryPlace: String?
    var rows: [ReconciledValueRowModel]
    /// The pictures recorded for the Event, earliest first.
    var gallery: ConclusionDetailGallery
    /// Leads with the gallery's lead picture.
    var thumbnail: ConclusionDetailThumbnail

    init(
        detail: CatalogConclusionDetail,
        locale: Locale = .autoupdatingCurrent,
        orders: NameFormatOrders = NameFormatOrders()
    ) {
        let summary = detail.summary?.event
        title = summary.map { EventTitleDisplay.titleSource($0, locale: locale, orders: orders) }
            ?? EventTitleDisplay.untitled(detail.entity)
        ref = detail.entity.ref
        members = L10n.Conclusions.memberCount(detail.memberCount)
        let line = summary.map { EventSecondaryDisplay.content($0, locale: locale) }
        secondaryDate = line.flatMap { $0.date.isEmpty ? nil : $0.date }
        secondaryPlace = line.flatMap { $0.place.isEmpty ? nil : $0.place }
        rows = [Self.dateRow(detail.fields, summary: summary, locale: locale), Self.placeRow(summary)]
        gallery = .pictures(from: detail, fallbackMark: .subjectEvent, choose: .eventThumbnail)
        thumbnail = .leading(
            gallery: gallery,
            noImage: L10n.Conclusions.eventNoImage,
            withImage: L10n.Conclusions.eventPictureThumb,
            leadLabel: L10n.Conclusions.pictureFrom
        )
    }

    /// The Date row, following the dating Go chose and the Properties it names
    /// behind it (`datingProperties`); Swift picks no key. An as-of dating lists
    /// the start, each kept as-of and the end as lines, and its Why holds every
    /// record behind them. Any other dating is one field's row, or, over several
    /// fields, one row whose lead is the dating and whose Why holds their records.
    /// Stated empty when nothing is recorded.
    static func dateRow(
        _ fields: [CatalogConclusionField],
        summary: CatalogEventSummary?,
        locale: Locale
    ) -> ReconciledValueRowModel {
        let label = L10n.string(L10n.Conclusions.eventDate)
        let empty = L10n.string(L10n.Conclusions.emptyEventDate)
        guard let summary else {
            return .empty(id: "date", label: label, face: .date, emptyText: empty)
        }
        let behind: [(property: CatalogEventDatingProperty, field: CatalogConclusionField)] =
            summary.datingProperties.compactMap { property in
                fields.first { $0.propertyKey == property.key && !$0.outcomes.isEmpty }
                    .map { (property, $0) }
            }
        let lead = DateRowDisplay.line(dating: summary.dating, locale: locale)
        if summary.dating.kind == .asOf {
            return .spanning(
                id: "date", label: label, lead: lead, emptyText: empty, fields: behind.map(\.field),
                listed: behind.flatMap { lines($0.field, role: $0.property.role, locale: locale) },
                locale: locale
            )
        }
        if behind.count == 1, let only = behind.first {
            return ReconciledValueRowModel(field: only.field, locale: locale).relabeled(label, field: only.field)
        }
        if behind.isEmpty, lead.isEmpty {
            return .empty(id: "date", label: label, face: .date, emptyText: empty)
        }
        return .spanning(id: "date", label: label, lead: lead, emptyText: empty, fields: behind.map(\.field), locale: locale)
    }

    /// A field's lines on the Date row: every displayed value of a multiple field, else the first
    /// displayed value (a start or an end, even when mixed), each worded by the field's role.
    private static func lines(
        _ field: CatalogConclusionField,
        role: CatalogEventDatingProperty.Role,
        locale: Locale
    ) -> [PVProvenanceSheetContent.Value] {
        let words: DateRowDisplay.Role
        switch role {
        case .occurrence: words = .plain
        case .start: words = .from
        case .asOf: words = .asOf
        case .end: words = .until
        }
        let shown = field.state == .multiple ? field.displayedValues : Array(field.displayedValues.prefix(1))
        return PVProvenanceSheetContent.listed(shown, propertyKey: field.propertyKey, role: words, locale: locale)
    }

    /// The Place row. The first kept name, mixed when more survived. No Why:
    /// that stays on the Place, which the row opens.
    static func placeRow(_ summary: CatalogEventSummary?) -> ReconciledValueRowModel {
        let label = L10n.string(L10n.Conclusions.eventPlace)
        let empty = L10n.string(L10n.Conclusions.emptyEventPlace)
        let places = summary?.places ?? []
        return .derived(
            id: "place", label: label, face: .place, lead: DerivedPlace.name(places),
            emptyText: empty, mixed: DerivedPlace.extra(places) > 0,
            opens: places.first.map(ReconciledValueRowModel.Opens.place)
        )
    }
}
