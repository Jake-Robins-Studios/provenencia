import Foundation
import Observation
import os
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

    /// F-6: `CatalogListRows.merge` is `mergeSorted` on both paths: random sorted lists with equal
    /// keys, random dropped and fresh ids (overlapping, unknown), the indexed path and the full pass
    /// each forced.
    @Test func listRowsMergeMatchesMergeSorted() {
        var random = SplitMix(seed: 0x5016_26F6)
        for _ in 0..<500 {
            let count = random.next(in: 0...200)
            var rows: [Row] = []
            for n in 0..<count { rows.append(Row("r\(n)", UInt8(random.next(in: 0...40) * 2))) }
            rows.sort { $0.listKey == $1.listKey ? $0.id < $1.id : $0.listKey < $1.listKey }
            let known = rows.map(\.id)
            var ids: [String] = []
            for _ in 0..<random.next(in: 0...20) { ids.append(Self.pickID(known, &random)) }
            var freshIDs: [String] = []
            for _ in 0..<random.next(in: 0...20) {
                let id = Self.pickID(known, &random)
                if !freshIDs.contains(id) { freshIDs.append(id) }
            }
            let fresh = freshIDs.map { Row($0, UInt8(random.next(in: 0...80)), note: "fresh") }
            var expected = rows
            expected.mergeSorted(fresh, replacing: ids)
            let list = CatalogListRows(rows)
            #expect(list.merging(fresh, replacing: ids, indexedLimit: Int.max).rows == expected)
            #expect(list.merging(fresh, replacing: ids, indexedLimit: 0).rows == expected)
            #expect(list.merging(fresh, replacing: ids).rows == expected)
            // The index follows the merge: a second merge on the result still matches.
            var again = expected
            again.mergeSorted(rows, replacing: ids)
            #expect(list.merging(fresh, replacing: ids, indexedLimit: Int.max)
                .merging(rows, replacing: ids, indexedLimit: Int.max).rows == again)
        }
    }

    private static func pickID(_ known: [String], _ random: inout SplitMix) -> String {
        let n = random.next(in: 0..<(known.count + 5))
        return n < known.count ? known[n] : "u\(n - known.count)"
    }

    /// F-6: `moveActivity` moves only the named rows with an older revision, as the array scan does.
    @Test func listRowsMoveActivityTouchesOnlyNamedRows() {
        func person(_ id: String, _ n: Int, revision: Int64) -> CatalogPersonSummary {
            var row = CatalogPersonSummary(
                entity: CatalogCanonicalEntity(id: id, ref: id, subjectTypeID: "t", label: ""),
                name: nil,
                nameValueCount: 0
            )
            row.listKey = CatalogListKey(last: false, primary: Data([UInt8(n)]), ref: id)
            row.updated = CatalogActivity(revision: revision, at: "then")
            return row
        }
        // Rows b and c share a key, so the walk over the equal run is exercised.
        let rows = [person("a", 1, revision: 1), person("b", 2, revision: 1), person("c", 2, revision: 9), person("d", 3, revision: 1)]
        let activity = CatalogActivity(revision: 5, at: "now")
        let ids: Set<String> = ["b", "c", "zz"]
        var list = CatalogListRows(rows)
        var scanned = rows
        let moved = list.moveActivity(ids: ids, activity: activity)
        let scanMoved = scanned.moveActivity(ids: ids, activity: activity)
        #expect(moved && scanMoved)
        #expect(list.rows == scanned)
        let revisions: [Int64] = list.rows.map { $0.updated.revision }
        #expect(revisions == [1, 5, 9, 1])
        let again = list.moveActivity(ids: ids, activity: activity)
        let unknown = list.moveActivity(ids: ["zz"], activity: activity)
        #expect(!again && !unknown)
    }

    /// F-6, Scale: one fresh row replacing two ids over 20,115 rows costs the rows it touched. The
    /// ceiling catches a slip back to the whole list; the 80,000-row and full-pass runs only print.
    @Test func listRowsAtScaleStaysUnderCeiling() {
        let indexed = Self.bestMilliseconds(rows: 20_115, indexed: true)
        let large = Self.bestMilliseconds(rows: 80_000, indexed: true)
        let fallback = Self.bestMilliseconds(rows: 20_115, indexed: false)
        let fallbackLarge = Self.bestMilliseconds(rows: 80_000, indexed: false)
        print("CatalogListRows.merge best of 5: indexed 20115 rows \(indexed) ms, 80000 rows \(large) ms; "
            + "fallback 20115 rows \(fallback) ms, 80000 rows \(fallbackLarge) ms")
        // decided: S16-26 F-6 (Debug measured 10 ms at 20,115 rows)
        let ceilingMilliseconds = 50.0
        #expect(indexed < ceilingMilliseconds)
    }

    /// F-9: past `indexedMergeLimit` touched ids the merge takes the one pass. Both paths are
    /// linear in the list, so a write of 200 ids (100 replaced by rows with new keys, 100 dropped)
    /// must not cost more than the one pass does.
    @Test func listRowsLargeWriteTakesTheOnePass() {
        let count = 20_115
        var random = SplitMix(seed: 0x5016_26F9)
        let list = CatalogListRows((0..<count).map { Self.personRow(UUID().uuidString, $0 * 2) } as [CatalogPersonSummary])
        let ids = (0..<200).map { list[$0 * 90 + 7].id }
        let fresh = ids.prefix(100).map { Self.personRow($0, random.next(in: 0...(count * 2))) }
        func best(_ limit: Int?) -> Double {
            var best = Double.infinity
            for _ in 0..<3 {
                var copy = list
                let elapsed = ContinuousClock().measure { copy.merge(fresh, replacing: ids, indexedLimit: limit) }
                best = min(best, Self.milliseconds(elapsed))
                #expect(copy.count == count - 100)
            }
            return best
        }
        let onePass = best(0)
        let chosen = best(nil)
        print("200-id write at 20115 rows: one pass \(onePass) ms, chosen path \(chosen) ms")
        // decided: S16-26 F-9
        #expect(chosen < onePass * 2 + 5)
    }

    /// F-8: a patch through the session works on the cached rows in place, so a write costs the
    /// rows it touched, not a copy of the list: the rows keep their buffer.
    @MainActor
    @Test func sessionPatchKeepsTheCachedRowsBuffer() {
        let session = WorkspaceSession(
            projectKey: ProjectKey(projectDir: "/tmp/list-merge-buffer.provenencia"),
            store: FakeStore()
        )
        let key = CatalogQueryKey.personsList(project: session.projectKey)
        let count = 20_115
        let dropped: [String]
        do {
            // The cached list is the only holder of its rows once this scope ends.
            let rows = (0..<count).map { Self.personRow(UUID().uuidString, $0 * 2) }
            dropped = [rows[count / 3].id, rows[count / 2].id]
            session.setQueryValue(key, value: CatalogListRows(rows))
        }
        let fresh = [Self.personRow(dropped[0], count / 2 * 2 + 1)]
        let handle: QueryHandle<CatalogListRows<CatalogPersonSummary>>? = session.queryHandle(key)
        func address() -> Int? {
            handle?.value?.rows.withUnsafeBufferPointer { Int(bitPattern: $0.baseAddress) }
        }
        let before = address()
        let started = ContinuousClock.now
        let result = session.patchCached(key, as: CatalogListRows<CatalogPersonSummary>.self) { value in
            value.merge(fresh, replacing: dropped) // two removed, one inserted: capacity holds
            return true
        }
        print("session patch at 20115 rows: \(Self.milliseconds(ContinuousClock.now - started)) ms")
        #expect(result == .applied)
        #expect(handle?.value?.count == count - 1)
        // decided: S16-26 F-8 (a copy of the cached value would move the buffer)
        #expect(before != nil && address() == before)
    }

    /// F-10: a patch that changes nothing does not tell the handle's observers; one that changes
    /// something does.
    @MainActor
    @Test func noOpPatchNotifiesNoObserver() {
        let session = WorkspaceSession(
            projectKey: ProjectKey(projectDir: "/tmp/list-noop-patch.provenencia"),
            store: FakeStore()
        )
        let key = CatalogQueryKey.personsList(project: session.projectKey)
        session.setQueryValue(key, value: CatalogListRows((0..<5).map { Self.personRow("p\($0)", $0) } as [CatalogPersonSummary]))
        let handle: QueryHandle<CatalogListRows<CatalogPersonSummary>>? = session.queryHandle(key)
        let revision = handle?.revision
        func fires(_ change: () -> Bool) -> (fired: Bool, result: CatalogPatchResult) {
            let fired = OSAllocatedUnfairLock(initialState: false)
            withObservationTracking { _ = handle?.value } onChange: { fired.withLock { $0 = true } }
            let result = session.patchCached(key, as: CatalogListRows<CatalogPersonSummary>.self) { _ in change() }
            return (fired.withLock { $0 }, result)
        }
        let noOp = fires { false }
        #expect(!noOp.fired)
        #expect(noOp.result == .unchanged)
        #expect(handle?.revision == revision)
        let changed = fires { true }
        #expect(changed.fired)
        #expect(changed.result == .applied)
    }

    private static func personRow(_ id: String, _ n: Int) -> CatalogPersonSummary {
        var bytes = [UInt8](repeating: 0x20, count: 24)
        withUnsafeBytes(of: UInt64(n).bigEndian) { bytes.replaceSubrange(0..<8, with: $0) }
        var row = CatalogPersonSummary(
            entity: CatalogCanonicalEntity(id: id, ref: "PRS-\(n)", subjectTypeID: "t", label: ""),
            name: nil,
            nameValueCount: 0
        )
        row.listKey = CatalogListKey(last: false, primary: Data(bytes), ref: "PRS-\(n)")
        return row
    }

    private static func bestMergeMilliseconds(rows count: Int) -> Double {
        let list = (0..<count).map { personRow(UUID().uuidString, $0 * 2) }
        let dropped = [list[count / 3].id, list[count / 2].id]
        let fresh = [personRow(dropped[0], count / 2 * 2 + 1)]
        var best = Double.infinity
        for _ in 0..<5 {
            var copy = list
            let elapsed = ContinuousClock().measure { copy.mergeSorted(fresh, replacing: dropped) }
            best = min(best, milliseconds(elapsed))
            #expect(copy.count == count - 1)
        }
        return best
    }

    /// The write as the session applies it: the cached value is shared with the handle, so the
    /// merge works on a copy, and the copy is timed with it.
    private static func bestMilliseconds(rows count: Int, indexed: Bool) -> Double {
        let list = CatalogListRows((0..<count).map { personRow(UUID().uuidString, $0 * 2) } as [CatalogPersonSummary])
        let dropped = [list[count / 3].id, list[count / 2].id]
        let fresh = [personRow(dropped[0], count / 2 * 2 + 1)]
        var best = Double.infinity
        for _ in 0..<5 {
            var copy = list
            let elapsed = ContinuousClock().measure {
                copy.merge(fresh, replacing: dropped, indexedLimit: indexed ? Int.max : 0)
            }
            best = min(best, milliseconds(elapsed))
            #expect(copy.count == count - 1)
        }
        return best
    }

    private static func milliseconds(_ duration: Duration) -> Double {
        Double(duration.components.attoseconds) / 1e15 + Double(duration.components.seconds) * 1e3
    }

    /// A fixed-seed generator, so the random cases repeat.
    private struct SplitMix {
        var state: UInt64
        init(seed: UInt64) { state = seed }
        mutating func next(in range: ClosedRange<Int>) -> Int {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            z ^= z >> 31
            return range.lowerBound + Int(z % UInt64(range.count))
        }
        mutating func next(in range: Range<Int>) -> Int { next(in: range.lowerBound...(range.upperBound - 1)) }
    }
}
