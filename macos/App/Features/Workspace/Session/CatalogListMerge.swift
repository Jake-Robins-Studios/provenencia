import Foundation

/// A cached list row that Go placed with a list key (S16-26): what `CatalogQueryRefresh.mergedRows`
/// reads to put a re-read row where its key falls.
protocol CatalogListRow: Identifiable, Sendable where ID == String {
    var listKey: CatalogListKey { get }
}

extension CatalogPersonSummary: CatalogListRow {}
extension CatalogEventSummary: CatalogListRow {}
extension CatalogPlaceSummary: CatalogListRow {}

/// `rows` in key order; rows with an equal key keep their given order.
fileprivate func sortedByListKey<Row: CatalogListRow>(_ rows: [Row]) -> [Row] {
    rows.enumerated()
        .sorted { a, b in
            a.element.listKey == b.element.listKey ? a.offset < b.offset : a.element.listKey < b.element.listKey
        }
        .map(\.element)
}

extension Array where Element: CatalogListRow {
    /// Drops the rows of `ids` and of `fresh`, then puts each `fresh` row where its key falls. The
    /// list was in key order and stays so: one pass drops, `fresh` is sorted (stably) by key, and
    /// one pass merges the two runs, a fresh row going after kept rows with an equal key.
    mutating func mergeSorted(_ fresh: [Element], replacing ids: [String]) {
        var dropped = Set(ids)
        for row in fresh { dropped.insert(row.id) }
        let kept = filter { !dropped.contains($0.id) }
        let added = sortedByListKey(fresh)
        var merged: [Element] = []
        merged.reserveCapacity(kept.count + added.count)
        var k = 0
        var a = 0
        while k < kept.count, a < added.count {
            if added[a].listKey < kept[k].listKey {
                merged.append(added[a])
                a += 1
            } else {
                merged.append(kept[k])
                k += 1
            }
        }
        merged.append(contentsOf: kept[k...])
        merged.append(contentsOf: added[a...])
        self = merged
    }
}

/// The rows of a Conclusion list in Go's key order, and each row's current key by id (S16-26 F-6),
/// so a write costs the rows it touched, not the list: `merge` finds a row by binary search on its
/// key instead of reading every row. Every change goes through `init`, `merge` and
/// `moveActivity`, which keep `keys` in step with `rows`.
struct CatalogListRows<Row: CatalogListRow>: Sendable, RandomAccessCollection, ExpressibleByArrayLiteral {
    /// The most ids a write may touch for `merge` to go row by row; past it, the one pass of
    /// `Array.mergeSorted`. Both paths are linear in the list (a removal is a binary search plus a
    /// memmove of the rows after it, the one pass reads every row), so the break-even is a fixed
    /// count, not a share of the list. Measured with the real row type, optimized build, best of 9:
    /// indexed against one pass is 13.5 / 20.2 ms at k = 16 and 29.0 / 20.7 ms at k = 32 over
    /// 20,115 rows, 77.8 / 86.1 ms and 130.2 / 87.8 ms over 80,000 rows.
    static var indexedMergeLimit: Int { 16 } // decided: S16-26 F-9

    private(set) var rows: [Row]
    private var keys: [String: CatalogListKey]

    /// `rows` arrive in Go's key order; the init does not sort.
    init(_ rows: [Row] = []) {
        self.rows = rows
        keys = Dictionary(uniqueKeysWithValues: rows.map { ($0.id, $0.listKey) })
    }

    init(arrayLiteral elements: Row...) {
        self.init(elements)
    }

    var startIndex: Int { rows.startIndex }
    var endIndex: Int { rows.endIndex }
    subscript(position: Int) -> Row { rows[position] }

    /// `merging(_:replacing:)` on a copy.
    func merging(_ fresh: [Row], replacing ids: [String], indexedLimit: Int? = nil) -> Self {
        var copy = self
        copy.merge(fresh, replacing: ids, indexedLimit: indexedLimit)
        return copy
    }

    /// The same result as `rows.mergeSorted(fresh, replacing: ids)`. When the write touched at most
    /// `indexedMergeLimit` ids, each is found by its key, removed, and each fresh
    /// row inserted where its key falls; past that, one pass over the list (`mergeSorted`).
    /// `indexedLimit` is for tests that force one path.
    mutating func merge(_ fresh: [Row], replacing ids: [String], indexedLimit: Int? = nil) {
        var touched = Set(ids)
        for row in fresh { touched.insert(row.id) }
        var indexed = touched.count <= (indexedLimit ?? Self.indexedMergeLimit)
        if indexed {
            for id in touched {
                guard let key = keys.removeValue(forKey: id) else { continue }
                guard let at = position(of: id, key: key) else {
                    indexed = false // `keys` and `rows` disagree: take the full pass
                    break
                }
                rows.remove(at: at)
            }
        }
        guard indexed else {
            rows.mergeSorted(fresh, replacing: ids)
            keys = Dictionary(rows.map { ($0.id, $0.listKey) }, uniquingKeysWith: { _, last in last })
            return
        }
        let added = sortedByListKey(fresh)
        for row in added {
            let key = row.listKey
            rows.insert(row, at: upperBound(of: key))
            keys[row.id] = key
        }
    }

    /// The index of the row `id` with key `key`: the first row whose key is not less than `key`, then
    /// the run of equal keys.
    private func position(of id: String, key: CatalogListKey) -> Int? {
        var index = lowerBound(of: key)
        while index < rows.count, !(key < rows[index].listKey) {
            if rows[index].id == id { return index }
            index += 1
        }
        return nil
    }

    /// The first index whose key is not less than `key`.
    private func lowerBound(of key: CatalogListKey) -> Int {
        var low = 0
        var high = rows.count
        while low < high {
            let mid = (low + high) / 2
            if rows[mid].listKey < key { low = mid + 1 } else { high = mid }
        }
        return low
    }

    /// The first index whose key is greater than `key`: a row goes after the rows with an equal key.
    private func upperBound(of key: CatalogListKey) -> Int {
        var low = 0
        var high = rows.count
        while low < high {
            let mid = (low + high) / 2
            if key < rows[mid].listKey { high = mid } else { low = mid + 1 }
        }
        return low
    }
}

extension CatalogListRows: Equatable where Row: Equatable {
    static func == (a: Self, b: Self) -> Bool { a.rows == b.rows }
}

extension CatalogListRows: CatalogLastUpdatedRows where Row: CatalogLastUpdatedRow {
    mutating func moveActivity(ids: Set<String>, activity: CatalogActivity) -> Bool {
        var moved = false
        for id in ids {
            guard let key = keys[id], let at = position(of: id, key: key),
                  rows[at].updated.revision < activity.revision
            else { continue }
            rows[at].updated = activity
            moved = true
        }
        return moved
    }
}
