import Foundation
import Testing
@testable import Provenencia

/// The app's half of Go's list order (S16-26): `CatalogListKey` compares as Go's
/// `conclusionsummaries.ListKey` does, and `Array.mergeSorted` puts a re-read row where its key
/// falls without moving the others.
@Suite
struct CatalogListMergeTests {
    private struct Row: CatalogListRow, Equatable {
        var id: String
        var listKey: CatalogListKey
        var note = ""

        init(_ id: String, _ position: UInt8, last: Bool = false, note: String = "") {
            self.id = id
            listKey = CatalogListKey(last: last, primary: Data([position]), ref: id)
            self.note = note
        }
    }

    private func ids(_ rows: [Row]) -> [String] { rows.map(\.id) }

    /// AC-1.2 - AC-1.4, D-8.
    @Test func mergeSortedPlacesRowsByKey() {
        let list = [Row("a", 1), Row("b", 3), Row("c", 5)]

        var moved = list
        moved.mergeSorted([Row("b", 6)], replacing: ["b"])
        #expect(ids(moved) == ["a", "c", "b"])

        var inserted = list
        inserted.mergeSorted([Row("d", 2)], replacing: ["d"])
        #expect(ids(inserted) == ["a", "d", "b", "c"])

        var removed = list
        removed.mergeSorted([], replacing: ["b"])
        #expect(ids(removed) == ["a", "c"])

        var replaced = list
        replaced.mergeSorted([Row("a", 1, note: "new")], replacing: [])
        #expect(ids(replaced) == ["a", "b", "c"])
        #expect(replaced.first?.note == "new")

        var empty: [Row] = []
        empty.mergeSorted([Row("x", 9)], replacing: ["x"])
        #expect(ids(empty) == ["x"])

        var last = list
        last.mergeSorted([Row("z", 0, last: true), Row("y", 7)], replacing: ["z", "y"])
        #expect(ids(last) == ["a", "b", "c", "y", "z"])
    }

    /// Several fresh rows keep their key order, and a fresh row goes after a kept row with an equal key.
    @Test func mergeSortedKeepsFreshRowsInKeyOrder() {
        var list = [Row("a", 1), Row("c", 5)]
        list.mergeSorted([Row("e", 5), Row("b", 3), Row("d", 5)], replacing: ["b", "d", "e"])
        #expect(ids(list) == ["a", "b", "c", "d", "e"])
    }

    private struct KeyRow: Decodable {
        var last: Bool
        var primary: String
        var keyRef: String

        enum CodingKeys: String, CodingKey {
            case last, primary
            case keyRef = "key_ref"
        }

        var key: CatalogListKey {
            var bytes = Data()
            var index = primary.startIndex
            while index < primary.endIndex {
                let next = primary.index(index, offsetBy: 2)
                bytes.append(UInt8(primary[index..<next], radix: 16) ?? 0)
                index = next
            }
            return CatalogListKey(last: last, primary: bytes, ref: keyRef)
        }
    }

    private struct KeysFile: Decodable {
        var titles: [KeyRow]
        var dates: [KeyRow]
    }

    /// AC-2.6, D-6: the keys Go gives for AC-2.2's titles and AC-2.3's dates, in Go's order
    /// (`core/database/conclusionsummaries/testdata/list_keys.json`, which Go's `TestListKeysFile`
    /// holds), order the same here.
    @Test func listKeyOrderMatchesGo() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let url = root.appendingPathComponent("core/database/conclusionsummaries/testdata/list_keys.json")
        let file = try JSONDecoder().decode(KeysFile.self, from: Data(contentsOf: url))
        #expect(file.titles.count == 5 && file.dates.count == 5)
        for rows in [file.titles, file.dates] {
            let keys = rows.map(\.key)
            for (earlier, later) in zip(keys, keys.dropFirst()) {
                #expect(earlier < later)
                #expect(!(later < earlier))
            }
        }
    }

    /// F-3: `==` agrees with `<`: refs that Swift's `String` calls equal but whose bytes differ
    /// are different keys, and exactly one is less.
    @Test func listKeyEqualityIsByteWise() {
        let a = CatalogListKey(last: false, primary: Data(), ref: "\u{e9}")
        let b = CatalogListKey(last: false, primary: Data(), ref: "e\u{301}")
        #expect(!(a == b))
        #expect((a < b) != (b < a))
    }

    /// F-4, Scale: one merge of one fresh row replacing two ids over a Person list as large as the
    /// large fixture's (20,115 rows) stays linear. The rule "Measure growth": the ceiling catches a
    /// slip to O(n * k); the 80,000-row run only prints.
    @Test func mergeSortedAtScaleStaysUnderCeiling() {
        let small = Self.bestMergeMilliseconds(rows: 20_115)
        let large = Self.bestMergeMilliseconds(rows: 80_000)
        print("mergeSorted best of 5: 20115 rows \(small) ms, 80000 rows \(large) ms")
        // decided: S16-26 F-4 (Debug measured 23 ms at 20,115 rows)
        let ceilingMilliseconds = 120.0
        #expect(small < ceilingMilliseconds)
    }

    private static func bestMergeMilliseconds(rows count: Int) -> Double {
        func key(_ n: Int) -> CatalogListKey {
            var bytes = [UInt8](repeating: 0x20, count: 24)
            withUnsafeBytes(of: UInt64(n).bigEndian) { bytes.replaceSubrange(0..<8, with: $0) }
            return CatalogListKey(last: false, primary: Data(bytes), ref: "PRS-\(n)")
        }
        func person(_ id: String, _ n: Int) -> CatalogPersonSummary {
            var row = CatalogPersonSummary(
                entity: CatalogCanonicalEntity(id: id, ref: "PRS-\(n)", subjectTypeID: "t", label: ""),
                name: nil,
                nameValueCount: 0
            )
            row.listKey = key(n)
            return row
        }
        let list = (0..<count).map { person(UUID().uuidString, $0 * 2) }
        let dropped = [list[count / 3].id, list[count / 2].id]
        let fresh = [person(dropped[0], count / 2 * 2 + 1)]
        var best = Double.infinity
        for _ in 0..<5 {
            var copy = list
            let elapsed = ContinuousClock().measure { copy.mergeSorted(fresh, replacing: dropped) }
            best = min(best, Double(elapsed.components.attoseconds) / 1e15 + Double(elapsed.components.seconds) * 1e3)
            #expect(copy.count == count - 1)
        }
        return best
    }
}
