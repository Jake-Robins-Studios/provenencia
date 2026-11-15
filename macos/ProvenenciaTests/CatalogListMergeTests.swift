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
}
