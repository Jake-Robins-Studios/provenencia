import Foundation

/// Whether a cached list has a row: `unknown` while the list cannot say (no
/// value yet, refetching after a write, or failed), `gone` only once a settled
/// list lacks it. A page that shows one row leaves when it reads `gone`.
enum CatalogRowPresence<Row> {
    case unknown
    case present(Row)
    case gone

    /// True only for `.gone`.
    var isGone: Bool {
        if case .gone = self { return true }
        return false
    }

    /// `row`, the list's row for the id, as a presence: `.present` when the list
    /// has it, `.gone` only once the handle has settled with a value, else `.unknown`.
    @MainActor
    static func of(_ row: Row?, in handle: QueryHandle<[Row]>?) -> Self {
        if let row { return .present(row) }
        if let handle, handle.isSettled, handle.value != nil { return .gone }
        return .unknown
    }
}
