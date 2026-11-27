import Foundation

/// Date, place, and how many other places an Event row counts. Not a view,
/// so the list and Promote can share it off the main actor.
enum EventSecondaryDisplay {
    struct Content: Equatable, Sendable {
        var date: String
        var place: String
        var extraPlaces: Int
    }

    static func content(_ summary: CatalogEventSummary, locale: Locale = .autoupdatingCurrent) -> Content {
        Content(
            date: DateRowDisplay.line(dating: summary.dating, locale: locale),
            place: DerivedPlace.name(summary.places),
            extraPlaces: DerivedPlace.extra(summary.places)
        )
    }

    /// The same date and place on one line. Empty when the event has neither.
    static func line(_ summary: CatalogEventSummary, locale: Locale = .autoupdatingCurrent) -> String {
        line(content(summary, locale: locale))
    }

    /// The date and place of an already-built `Content` on one line.
    static func line(_ content: Content) -> String {
        PVDatePlaceLine.text(date: content.date, place: content.place)
    }
}
