import Foundation

/// A scope's newest audit revision and when it was recorded (RFC3339 UTC).
/// Mirrors the engine's `effects.Activity`: revision 0 means none. Ordered
/// by revision, never by the time string (the wall clock is not monotonic).
struct CatalogActivity: Sendable, Equatable {
    var revision: Int64 = 0
    var at: String = ""
}

/// A cached list row that carries its handle's or Source's last activity.
/// `Sendable` so `CatalogQueryPatch.lastUpdated` can capture `Row.Type` in its
/// `@Sendable` closure.
protocol CatalogLastUpdatedRow: Sendable {
    var id: String { get }
    var updated: CatalogActivity { get set }
}

extension CatalogPersonSummary: CatalogLastUpdatedRow {}
extension CatalogEventSummary: CatalogLastUpdatedRow {}
extension CatalogPlaceSummary: CatalogLastUpdatedRow {}
extension CatalogSource: CatalogLastUpdatedRow {}

/// A cached list value whose rows carry last activity: what `CatalogQueryPatch.lastUpdated` moves
/// forward. The Sources list is a plain array scanned in full; the Conclusion lists are
/// `CatalogListRows`, which find each named row by its key.
protocol CatalogLastUpdatedRows: Sendable {
    /// Moves `updated` to `activity` on each row whose id is in `ids` and whose revision is older
    /// than the write's; a row only moves forward. Returns whether any row moved.
    mutating func moveActivity(ids: Set<String>, activity: CatalogActivity) -> Bool
}

extension Array: CatalogLastUpdatedRows where Element: CatalogLastUpdatedRow {
    mutating func moveActivity(ids: Set<String>, activity: CatalogActivity) -> Bool {
        var moved = false
        for index in indices where ids.contains(self[index].id) && self[index].updated.revision < activity.revision {
            self[index].updated = activity
            moved = true
        }
        return moved
    }
}
