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

/// A per-entity page value that reports what it was built from (S16-24), so a
/// key holding one follows those ids (`CatalogQueryRefresh.followsInputs`).
protocol CatalogPageValue: Sendable {
    var inputs: CatalogPageInputs { get }
}

extension CatalogConclusionDetail: CatalogPageValue {}
extension CatalogPersonClaims: CatalogPageValue {}
extension CatalogPersonFamily: CatalogPageValue {}
extension CatalogPersonTimeline: CatalogPageValue {}
extension CatalogPersonRecordLinks: CatalogPageValue {}

/// Which ids of a write a patch or refresh follows: row or key ids, or one
/// token for a catalog-wide slot. Each slot carries its own.
enum CatalogQueryFollows: Sendable, Hashable {
    /// `CatalogWriteEffects.handleScopes`: Person, Event, and Place handles.
    case handle
    /// `CatalogWriteEffects.sourceScopes`.
    case source
    /// The key ids of one entry of `CatalogWriteEffects.reads`.
    case reads(CatalogRead)
    /// `CatalogWriteEffects.touchedHandles`: every handle a write changed or
    /// whose summary it changed.
    case touchedHandles
    /// `CatalogWriteEffects.evidenceGraphs`.
    case evidenceGraphs
    /// One catalog-wide list of `CatalogWriteEffects.lists`. A catalog-wide slot
    /// names no row, so it reports one token when the write moved it and is
    /// used only with `applyHiddenPolicyOnAny(follows:)`.
    case list(CatalogList)
    /// `CatalogWriteEffects.structure`. Catalog-wide, as `list(_:)`.
    case structure

    /// Whether the slot names no row: it reports one token when the write moved
    /// it. The constructors that read a slot as row or key ids refuse one.
    var isCatalogWide: Bool {
        switch self {
        case .list, .structure:
            return true
        case .handle, .source, .reads, .touchedHandles, .evidenceGraphs:
            return false
        }
    }

    /// The ids of a write that this slot follows.
    func ids(in effects: CatalogWriteEffects) -> [String] {
        switch self {
        case .handle:
            return effects.handleScopes
        case .source:
            return effects.sourceScopes
        case .reads(let read):
            return effects.reads.first { $0.read == read }?.ids ?? []
        case .touchedHandles:
            return effects.touchedHandles
        case .evidenceGraphs:
            return effects.evidenceGraphs
        case .list(let list):
            return effects.lists.contains(list) ? [list.rawValue] : []
        case .structure:
            return effects.structure ? ["structure"] : []
        }
    }
}

/// Row-id slots name ids; a catalog-wide slot names none.
fileprivate func requireRowIDs(_ follows: CatalogQueryFollows) {
    precondition(!follows.isCatalogWide, "a catalog-wide slot names no ids; use applyHiddenPolicyOnAny(follows:)")
}

/// One in-place update of a warmed cache key. `follows == nil` means the patch
/// reads the mutation (an enriched Source); otherwise the session passes the
/// ids that `follows` names. Array order on a descriptor is composition order.
struct CatalogQueryPatch: Sendable {
    var follows: CatalogQueryFollows?
    let apply: @MainActor @Sendable (
        WorkspaceSession, CatalogQueryKey, Set<String>, CatalogActivity, CatalogMutation?
    ) -> CatalogPatchResult

    /// Moves each row whose id is in the set and whose revision is older than
    /// the write's. A row only moves forward; nothing is fetched.
    static func lastUpdated<Rows: CatalogLastUpdatedRows>(
        _: Rows.Type,
        follows: CatalogQueryFollows
    ) -> Self {
        requireRowIDs(follows)
        return Self(follows: follows) { session, key, ids, activity, _ in
            session.patchCached(key, as: Rows.self) { rows in
                rows.moveActivity(ids: ids, activity: activity)
            }
        }
    }

    /// Puts the mutation's Source into the Sources list: it replaces the row
    /// with the same id, and a `.createdSource(source)` appends its row when the list
    /// lacks it (the list sorts for display). An update or type change of a
    /// row the list lacks adds nothing. Leaves any stale flag: other rows may
    /// still owe a reload.
    static func sourceRow() -> Self {
        row(
            CatalogSource.self,
            patched: { $0.patchedSource },
            appendsOn: { if case .createdSource(_) = $0 { return true } else { return false } }
        )
    }

    /// Writes the mutation's Source type onto the cached types list: replaces the row with the
    /// same id (`.createdSourceType`, `.updatedSourceType`), a `.createdSourceType` appends its
    /// row when the list lacks it (the list sorts for display), and a `.deletedSourceType` removes
    /// its row. Leaves any stale flag.
    static func sourceTypeRow() -> Self {
        row(
            CatalogSourceType.self,
            patched: { $0.patchedSourceType },
            appendsOn: { if case .createdSourceType(_) = $0 { return true } else { return false } },
            removes: { if case .deletedSourceType(let id) = $0 { return id } else { return nil } }
        )
    }

    /// The row patch of a cached list: replaces the row with the same id, and appends the
    /// mutation's row when the list lacks it only if `appendsOn` says the mutation creates it;
    /// otherwise a row the list lacks adds nothing. A mutation `removes` names the id of a row to
    /// drop; it carries no row, so it is checked first.
    static func row<Row: Identifiable & Sendable>(
        _: Row.Type,
        patched: @escaping @Sendable (CatalogMutation) -> Row?,
        appendsOn: @escaping @Sendable (CatalogMutation) -> Bool,
        removes: @escaping @Sendable (CatalogMutation) -> String? = { _ in nil }
    ) -> Self where Row.ID == String {
        Self(follows: nil) { session, key, _, _, mutation in
            guard let mutation else { return .unchanged }
            if let removedID = removes(mutation) {
                return session.patchCached(key, as: [Row].self) { rows in
                    let before = rows.count
                    rows.removeAll { $0.id == removedID }
                    return rows.count != before
                }
            }
            guard let row = patched(mutation) else { return .unchanged }
            let appends = appendsOn(mutation)
            return session.patchCached(key, as: [Row].self) { rows in
                if let index = rows.firstIndex(where: { $0.id == row.id }) {
                    rows[index] = row
                    return true
                }
                guard appends else { return false }
                rows.append(row)
                return true
            }
        }
    }

    /// Writes the mutation's Source onto the cached page shell. A partial
    /// patch: a page marked stale stays stale and reloads on its next visit.
    static func updatedSourceShell() -> Self {
        Self(follows: nil) { session, key, _, _, mutation in
            guard let source = mutation?.patchedSource else { return .unchanged }
            guard key.kind == .sourceWorkspace, key.ownId == source.id else { return .unchanged }
            return session.patchCached(key, as: CatalogSourceWorkspace.self) { workspace in
                workspace.source = source
                return true
            }
        }
    }

    /// Writes a suggestion write's reply onto the cached suggestions of the type it names (S15-12 D-2).
    /// A key of another type or level, or one with no value, is left alone.
    static func typeSuggestions() -> Self {
        Self(follows: nil) { session, key, _, _, mutation in
            guard case .wroteTypeSuggestions(let typeId, let level, let edit)? = mutation else { return .unchanged }
            guard key.kind == .typeSuggestions, key.suggestionsTypeId == typeId, key.suggestionsLevel == level
            else { return .unchanged }
            return session.patchCached(key, as: [CatalogTypeSuggestion].self) { suggestions in
                guard suggestions != edit.suggestions else { return false }
                suggestions = edit.suggestions
                return true
            }
        }
    }

    /// Writes a suggestion write's count onto the type's row of the cached types list, so the
    /// list's Fields column follows with no reload. A type the list lacks adds nothing.
    static func typeSuggestionCount() -> Self {
        Self(follows: nil) { session, key, _, _, mutation in
            guard case .wroteTypeSuggestions(let typeId, _, let edit)? = mutation else { return .unchanged }
            return session.patchCached(key, as: [CatalogSourceType].self) { rows in
                guard let index = rows.firstIndex(where: { $0.id == typeId }),
                      rows[index].suggestedFieldCount != edit.suggestedFieldCount
                else { return false }
                rows[index].suggestedFieldCount = edit.suggestedFieldCount
                return true
            }
        }
    }

    /// Writes a board write's rows onto the cached Source page, for the owner
    /// the write named. A partial patch like `updatedSourceShell()`: an owner the
    /// page cannot place leaves it unchanged.
    static func metadataBoard() -> Self {
        Self(follows: nil) { session, key, _, _, mutation in
            guard case .wroteMetadataBoard(let sourceId, let owner, let entries)? = mutation else { return .unchanged }
            guard key.kind == .sourceWorkspace, key.ownId == sourceId else { return .unchanged }
            return session.patchCached(key, as: CatalogSourceWorkspace.self) { workspace in
                workspace.setMetadataRows(entries, for: owner)
            }
        }
    }
}

/// What a warmed key does when a write reports ids its `follows` slot names.
/// The session reads a descriptor's list in order.
struct CatalogQueryRefresh: Sendable {
    typealias Run = @MainActor @Sendable (WorkspaceSession, CatalogQueryKey, [String]) async -> Void

    enum Action: Sendable {
        /// Re-applies the hidden policy to the key, synchronously and at most
        /// once per `apply`, when the write names an id the key depends on.
        /// The closure returns those ids, read from the key or its cached
        /// value; `nil` means any id the slot names.
        case revalidate(@MainActor @Sendable (WorkspaceSession, CatalogQueryKey) -> Set<String>?)
        /// A partial reload merged into the cached value, run in a task with
        /// the ids `follows` names.
        case run(Run)
    }

    var follows: CatalogQueryFollows
    var action: Action

    fileprivate init(follows: CatalogQueryFollows, action: Action) {
        self.follows = follows
        self.action = action
    }

    /// A partial reload (`.run`). `merged` and `mergedRows` are the only ways to declare one.
    fileprivate init(follows: CatalogQueryFollows, run: @escaping Run) {
        self.init(follows: follows, action: .run(run))
    }

    /// A partial reload of a warmed value: `read` fetches one id's part and
    /// `merge` folds it into the cached value (`WorkspaceSession.refreshCached`).
    /// The key's `isFetching` stays true while it runs; a failed read reloads
    /// the key through its hidden policy. `afterMerge`, when given, runs once
    /// the merge landed, with the parts read (by id) and the handle's revision
    /// from just before the merge, so a derived index can follow the merge
    /// instead of rebuilding.
    static func merged<Value: Sendable, Part: Sendable>(
        follows: CatalogQueryFollows,
        as _: Value.Type,
        read: @escaping @MainActor @Sendable (WorkspaceSession, CatalogQueryKey, String) async throws -> Part,
        merge: @escaping @MainActor @Sendable (inout Value, String, Part) -> Void,
        afterMerge: (@MainActor @Sendable (
            WorkspaceSession, CatalogQueryKey, _ parts: [String: Part], _ previousRevision: Int
        ) -> Void)? = nil
    ) -> CatalogQueryRefresh {
        requireRowIDs(follows)
        return CatalogQueryRefresh(follows: follows, run: { session, key, ids in
            await session.refreshCached(
                key,
                as: Value.self,
                ids: ids,
                read: { ids in
                    var parts: [(String, Part)] = []
                    for id in ids {
                        parts.append((id, try await read(session, key, id)))
                    }
                    return parts
                },
                merge: { value, parts in
                    for (id, part) in parts {
                        merge(&value, id, part)
                    }
                },
                afterMerge: afterMerge.map { after in
                    { parts, previous in
                        after(session, key, Dictionary(parts, uniquingKeysWith: { _, last in last }), previous)
                    }
                }
            )
        })
    }

    /// A partial reload of a list that Go orders (S16-26): `read` fetches the rows of the named ids
    /// in one store call, and the rows are put where their `listKey` falls, the ids it returned
    /// no row for dropped (`CatalogListRows.merge`). The key's `isFetching` stays true while it runs;
    /// a failed read reloads the key through its hidden policy.
    static func mergedRows<Row: CatalogListRow>(
        _: Row.Type,
        follows: CatalogQueryFollows,
        read: @escaping @MainActor @Sendable (WorkspaceSession, CatalogQueryKey, [String]) async throws -> [Row]
    ) -> CatalogQueryRefresh {
        requireRowIDs(follows)
        return CatalogQueryRefresh(follows: follows, run: { session, key, ids in
            await session.refreshCached(
                key,
                as: CatalogListRows<Row>.self,
                ids: ids,
                read: { try await read(session, key, $0) },
                merge: { rows, fresh in rows.merge(fresh, replacing: ids) }
            )
        })
    }

    /// A refresh that re-applies the hidden policy to a warmed key when the
    /// write names one of the `ids` the key depends on.
    static func applyHiddenPolicy(
        follows: CatalogQueryFollows,
        ids: @escaping @MainActor @Sendable (WorkspaceSession, CatalogQueryKey) -> Set<String>
    ) -> CatalogQueryRefresh {
        requireRowIDs(follows)
        return CatalogQueryRefresh(follows: follows, action: .revalidate { session, key in ids(session, key) })
    }

    /// `applyHiddenPolicy(follows:ids:)` for a key whose id is the one row it
    /// names (`CatalogQueryKey.ownId`).
    static func applyHiddenPolicy(followsOwnId follows: CatalogQueryFollows) -> CatalogQueryRefresh {
        .applyHiddenPolicy(follows: follows) { _, key in key.ownId.map { [$0] } ?? [] }
    }

    /// A refresh whose ids come from the key's cached `Value`. Until the key
    /// holds a value its first load is in flight and its ids are unknown, so
    /// the refresh matches any id the slot names.
    static func applyHiddenPolicy<Value>(
        followsValue follows: CatalogQueryFollows,
        ids: @escaping @Sendable (Value) -> Set<String>
    ) -> CatalogQueryRefresh {
        requireRowIDs(follows)
        return CatalogQueryRefresh(follows: follows, action: .revalidate { session, key in
            let value: Value? = session.queryHandle(key)?.value
            return value.map(ids)
        })
    }

    /// The refreshes of a key whose cached value reports its inputs: one per
    /// slot of `inputs` (handles on `.touchedHandles`, Evidence graphs on
    /// `.evidenceGraphs`, Sources on `.reads(.sourceRecords)`). Until the key
    /// holds a value its inputs are unknown, so each follows any id of its slot.
    static func followsInputs<Value: CatalogPageValue>(_: Value.Type) -> [CatalogQueryRefresh] {
        [
            .applyHiddenPolicy(followsValue: .touchedHandles) { (value: Value) in value.inputs.handles },
            .applyHiddenPolicy(followsValue: .evidenceGraphs) { (value: Value) in value.inputs.evidenceGraphs },
            .applyHiddenPolicy(followsValue: .reads(.sourceRecords)) { (value: Value) in value.inputs.sources },
        ]
    }

    /// A refresh that re-applies the hidden policy to a warmed key whenever the
    /// write reports the catalog-wide slot. It is the only constructor for a catalog-wide slot
    /// (`.list(_:)`, `.structure`).
    static func applyHiddenPolicyOnAny(follows: CatalogQueryFollows) -> CatalogQueryRefresh {
        precondition(follows.isCatalogWide, "a row slot names ids; use applyHiddenPolicy(follows:ids:)")
        return CatalogQueryRefresh(follows: follows, action: .revalidate { _, _ in nil })
    }

    /// A key whose rows carry a Property, term or Subject type label.
    static let followsPropertyLabels: CatalogQueryRefresh = .applyHiddenPolicyOnAny(follows: .list(.propertyVocabulary))
}
