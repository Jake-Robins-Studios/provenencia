import Foundation

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
        follows.requireRowIDs()
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
        follows.requireRowIDs()
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
        follows.requireRowIDs()
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
        follows.requireRowIDs()
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

    /// A refresh that re-applies the hidden policy to a warmed key when the write
    /// deleted any id of the row slot (`.deleted(_:)`), whichever the key holds.
    static func applyHiddenPolicyOnAnyID(follows: CatalogQueryFollows) -> CatalogQueryRefresh {
        follows.requireRowIDs()
        return CatalogQueryRefresh(follows: follows, action: .revalidate { _, _ in nil })
    }

    /// A key whose rows carry a Property, term or Subject type label.
    static let followsPropertyLabels: CatalogQueryRefresh = .applyHiddenPolicyOnAny(follows: .list(.propertyVocabulary))
}
