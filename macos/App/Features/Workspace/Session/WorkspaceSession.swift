import Foundation
import Observation

/// Project-scoped catalog query cache. Each kind's loader, policies, patches,
/// and refresh live on `CatalogQueryKey.Kind.descriptor`.
@MainActor
@Observable
final class WorkspaceSession {
    let projectKey: ProjectKey
    let store: any GenealogyStore
    let registry: CatalogQueryRegistry
    /// The window's toasts, newest first. Every toast the workspace raises outside a sheet joins
    /// this one list (`CatalogCounts` adds its recount failure here); `WorkspaceContent` draws it.
    /// A sheet draws its own (`PVSheetChrome`).
    let toasts: PVToastList
    /// Default name-format orders. Empty until the catalog read finishes,
    /// which keeps stored part order.
    var nameFormat = NameFormatOrders()

    private var handles: [CatalogQueryKey: any AnyQueryHandle] = [:]
    private var valueTypes: [CatalogQueryKey: ObjectIdentifier] = [:]
    private var generations: [CatalogQueryKey: Int] = [:]
    private var inFlight: [CatalogQueryKey: (generation: Int, task: Task<Void, Never>)] = [:]
    /// Keys of the place on screen, from the last `apply(location:)`.
    private(set) var visibleKeys: Set<CatalogQueryKey> = []
    /// The entities whose pages were shown, least recently shown first (D-5).
    private var shownOrder: [String] = []
    /// Hidden entities whose per-entity keys stay cached.
    static let maxHiddenEntities = 50 // decided: user, 2026-11-08
    /// Recounts the sidebar after a write whose effects report the `counts` list (`WriteEffects.lists`). Set by `WorkspaceView`.
    @ObservationIgnored
    var onNavCountsMoved: (@MainActor () async -> Void)?
    /// Evidence-graph pan and zoom, keyed by graph id. Not catalog data; quit drops it.
    @ObservationIgnored
    private var graphCameras: [String: GraphCanvasCamera] = [:]
    /// Derived values, their build counts and, in debug builds, the keys each
    /// running build reads (`WorkspaceSession+Derived.swift`). Not observed:
    /// filling them while a view reads must not invalidate that view.
    @ObservationIgnored
    var derivedEntries: [DerivedValueID: DerivedEntry] = [:]
    @ObservationIgnored
    var derivedBuilds: [DerivedValueID: Int] = [:]
    @ObservationIgnored
    var derivedReads: [Set<CatalogQueryKey>] = []
    #if DEBUG
    /// The keys each id's last build read without naming them in its inputs,
    /// and whether such a read stops the build (a test turns that off to read
    /// the record).
    @ObservationIgnored
    var derivedUndeclaredReads: [DerivedValueID: Set<CatalogQueryKey>] = [:]
    @ObservationIgnored
    var derivedAssertsUndeclaredReads = true
    #endif

    init(
        projectKey: ProjectKey,
        store: any GenealogyStore,
        registry: CatalogQueryRegistry = .standard,
        toasts: PVToastList = PVToastList()
    ) {
        self.projectKey = projectKey
        self.store = store
        self.registry = registry
        self.toasts = toasts
    }

    func loadNameFormat() async {
        do {
            nameFormat = try await store.nameFormat(projectDir: projectKey.projectDir)
        } catch {
            nameFormat = NameFormatOrders()
        }
    }

    func graphCamera(for graphID: String) -> GraphCanvasCamera? {
        graphCameras[graphID]
    }

    func setGraphCamera(_ camera: GraphCanvasCamera, for graphID: String) {
        guard graphCameras[graphID] != camera else { return }
        graphCameras[graphID] = camera
    }

    /// Returns an existing handle without starting a load.
    func queryHandle<Value>(_ key: CatalogQueryKey) -> QueryHandle<Value>? {
        #if DEBUG
        if !derivedReads.isEmpty { derivedReads[derivedReads.count - 1].insert(key) }
        #endif
        return handles[key] as? QueryHandle<Value>
    }

    /// The key's handle revision, or -1 when it has no handle: what a derived
    /// value stamps for an input. Reads `handles`, so a view that reads a
    /// derived value observes its inputs.
    func inputRevision(_ key: CatalogQueryKey) -> Int {
        handles[key]?.revision ?? -1
    }

    /// True while the key's handle holds a value and is reloading it behind
    /// that value: "refreshing" for a section whose first load is its own spinner.
    func isRefreshing(_ key: CatalogQueryKey) -> Bool {
        handles[key].map { $0.hasValue && $0.isFetching } ?? false
    }

    /// Waits out an in-flight load and every partial re-read a write started
    /// for the key, then returns the cached value.
    /// Does not start a load. Nil when the key was never warmed, is stale, or the load failed.
    func readyValue<Value>(_ key: CatalogQueryKey) async -> Value? {
        while true {
            var pending: [Task<Void, Never>] = []
            if let task = inFlight[key]?.task { pending.append(task) }
            pending += writeRefreshes.values.filter { $0.key == key }.map(\.task)
            if pending.isEmpty { break }
            for task in pending {
                await task.value
            }
        }
        if handles[key]?.isStale == true {
            return nil
        }
        return queryHandle(key)?.value
    }

    /// Registry-backed get-or-load.
    @discardableResult
    func query<Value>(_ key: CatalogQueryKey) -> QueryHandle<Value> {
        key.kind.descriptor.warm(self, key)
        guard let handle: QueryHandle<Value> = queryHandle(key) else {
            preconditionFailure("CatalogQueryKey \(key) warmed a different value type than \(Value.self)")
        }
        return handle
    }

    /// Invalidates the key, then queries it: the read-it-again path. Keeps any
    /// stale value on the handle while the new read runs.
    @discardableResult
    func reread<Value>(_ key: CatalogQueryKey) -> QueryHandle<Value> {
        invalidate(key)
        return query(key)
    }

    /// Synchronous cache write. Clears stale flag without calling the loader.
    /// If a load was in flight, the patch wins immediately and that load is
    /// restarted so a later refetch is not dropped.
    func setQueryValue<Value>(_ key: CatalogQueryKey, value: Value) {
        replaceValue(key, clearStale: true) { (handle: QueryHandle<Value>) in
            handle.applySuccess(value)
            return true
        }
    }

    /// The one patch primitive: replaces the cached value now. An in-flight
    /// load is cancelled and restarted, so an older response cannot overwrite
    /// the patch. `clearStale` says whether the patch makes the key current.
    @discardableResult
    private func replaceValue<Value>(
        _ key: CatalogQueryKey,
        clearStale: Bool,
        install: (QueryHandle<Value>) -> Bool
    ) -> Bool {
        let handle = typedHandle(for: key, as: Value.self)
        let hadInFlight = inFlight[key] != nil
        guard install(handle) else { return false }
        bumpGeneration(key)
        inFlight[key]?.task.cancel()
        inFlight[key] = nil
        if clearStale {
            handle.clearStale()
        }
        if hadInFlight {
            handle.markStale()
            revalidate(key)
        }
        return true
    }

    /// Edits the cached value in place. `change` returns whether it changed
    /// anything; nothing happens when it did not or the key has no value. The
    /// stale flag is left as it was: a partial patch does not make the key current.
    /// A key whose first load is in flight has no value to patch and that load
    /// may have read before the write: the result says so (`.awaitingFirstValue`)
    /// and `apply` restarts or stales the key.
    @discardableResult
    func patchCached<Value>(
        _ key: CatalogQueryKey,
        as _: Value.Type,
        _ change: (inout Value) -> Bool
    ) -> CatalogPatchResult {
        if awaitsFirstValue(key) { return .awaitingFirstValue }
        guard let existing: QueryHandle<Value> = queryHandle(key), existing.hasValue else { return .unchanged }
        let changed = replaceValue(key, clearStale: false) { (handle: QueryHandle<Value>) in
            handle.modifyValue(change)
        }
        return changed ? .applied : .unchanged
    }

    /// Re-reads part of a warmed value and merges it in: `read` runs once with every id, and its
    /// part is merged in one `patchCached`. A failed read falls back to the key's hidden policy (a
    /// reload) and merges nothing. Nothing happens for a key evicted before it starts. `apply`
    /// holds the handle's `isFetching` count for the whole run. After an applied merge,
    /// `afterMerge` gets the part and the handle revision from just before the patch.
    ///
    /// Called only by `CatalogQueryRefresh.merged` and `.mergedRows`, inside `apply`'s gate and
    /// count; it is not a feature API.
    func refreshCached<Value, Part>(
        _ key: CatalogQueryKey,
        as _: Value.Type,
        ids: [String],
        read: @MainActor ([String]) async throws -> Part,
        merge: @MainActor (inout Value, Part) -> Void,
        afterMerge: (@MainActor (Part, _ previousRevision: Int) -> Void)? = nil
    ) async {
        guard let _: QueryHandle<Value> = queryHandle(key) else { return }
        let part: Part
        do {
            part = try await read(ids)
        } catch {
            applyHiddenPolicy(to: key)
            return
        }
        let previousRevision = queryHandle(key).map { (handle: QueryHandle<Value>) in handle.revision }
        let result = patchCached(key, as: Value.self) { value in
            merge(&value, part)
            return true
        }
        // Any other result (awaiting a first value, unchanged) is `apply`'s to settle.
        if case .applied = result, let previousRevision, let afterMerge {
            afterMerge(part, previousRevision)
        }
    }

    /// What a key does when a write reaches it: a visible one revalidates, a
    /// hidden one follows its descriptor's `whenHidden`.
    private func effectivePolicy(for key: CatalogQueryKey) -> CatalogHiddenPolicy {
        visibleKeys.contains(key) ? .revalidate : registry.hiddenPolicy(key)
    }

    /// The key has no value yet and its first load is in flight; that load
    /// may have read before the write that is being applied.
    private func awaitsFirstValue(_ key: CatalogQueryKey) -> Bool {
        handles[key].map { !$0.hasValue } == true && inFlight[key] != nil
    }

    /// Resolves the place for `location` and starts loading its query keys (non-blocking).
    func apply(
        location: WorkspaceLocation,
        placeRegistry: PlaceRegistry = .standard
    ) {
        guard let place = placeRegistry.resolve(location, project: projectKey) else {
            visibleKeys = []
            return
        }
        visibleKeys = Set(place.queryKeys)
        #if DEBUG
        if ProcessInfo.processInfo.environment["PROVENENCIA_DEBUG_SESSION_APPLY"] == "1" {
            print("WorkspaceSession.apply location=\(location) place=\(place.placeID) keys=\(place.queryKeys)")
        }
        #endif
        for key in place.queryKeys {
            key.kind.descriptor.warm(self, key)
        }
        var onScreen = Set<String>()
        for key in place.queryKeys where key.kind.descriptor.isEntityPage {
            guard let id = key.ownId else { continue }
            onScreen.insert(id)
            shownOrder.removeAll { $0 == id }
            shownOrder.append(id)
        }
        trimHiddenEntities(keeping: onScreen)
    }

    /// Keeps at most `maxHiddenEntities` hidden entities' per-entity keys: past
    /// that, the least recently shown go, every key of an entity at once. An
    /// entity no place showed counts as least recently shown. The entities on
    /// screen are never hidden, whichever of their keys the place warms.
    private func trimHiddenEntities(keeping onScreen: Set<String>) {
        let hidden = Set(warmedKeys(deletedWith: .handle).map(\.id).filter { !onScreen.contains($0) })
        guard hidden.count > Self.maxHiddenEntities else { return }
        let ordered = hidden.subtracting(shownOrder).sorted() + shownOrder.filter(hidden.contains)
        evict(.handle, ids: Set(ordered.prefix(hidden.count - Self.maxHiddenEntities)))
    }

    /// The one application of a write. First it evicts the hidden keys of the
    /// entities the effects deleted (`evict(_:ids:)`; a visible key is left to
    /// the pass below, which reloads it and reads gone). Then it patches in place, with no load:
    /// each warmed key runs its descriptor `patches` in order (last-updated
    /// cells from the effects, then an enriched Source row and page shell).
    /// Then it revalidates, once per key through one dedupe set, the union of
    /// what the registry invalidates for the mutation (the Source page's own
    /// workspace, the metadata field list), the warmed keys whose descriptor
    /// `refreshes` follow what the effects reported (`revalidatedKeys`: ids, the
    /// catalog-wide lists, structure), the keys a patch
    /// found with their first load still in flight, and the keys a `.run`
    /// refresh cannot run for. Keys the registry marks stale when
    /// hidden are not loaded unless on screen. Last, it starts each warmed
    /// key's `.run` refreshes for the ids the effects reported (graph
    /// progress per graph, the graph list per Source, the Persons, Events and
    /// Places lists' touched rows, only the ids named), gated per key: one
    /// runs for a key that holds a value and is not stale, on screen or not,
    /// and holds a count on the handle's `isFetching` until it ends. Any other
    /// warmed key such an entry names joins the dedupe pass instead (reloaded
    /// when visible, marked stale when hidden), and a key in that pass starts
    /// no `.run`. It also runs `onNavCountsMoved`
    /// once when the effects report the `counts` list. Features only
    /// call `apply`; they do not query afterward or tell sibling views to
    /// refresh.
    func apply(_ effects: CatalogWriteEffects = .empty, _ mutation: CatalogMutation? = nil) {
        for deleted in effects.deleted {
            evict(deleted.entity, ids: Set(deleted.ids))
        }
        let awaiting = applyPatches(effects, mutation)
        let invalidated = mutation.map { cachedKeys(for: registry.invalidations(by: $0, project: projectKey)) } ?? []
        let refreshed = revalidatedKeys(for: effects)
        var running: [(key: CatalogQueryKey, run: CatalogQueryRefresh.Run, ids: [String])] = []
        var fallbacks: [CatalogQueryKey] = []
        for key in Array(handles.keys) where key.project == projectKey {
            guard let handle = handles[key] else { continue }
            for refresh in key.kind.descriptor.refreshes {
                guard case .run(let run) = refresh.action else { continue }
                let ids = refresh.follows.ids(in: effects)
                if ids.isEmpty { continue }
                if !handle.isStale, handle.hasValue {
                    running.append((key, run, ids))
                } else {
                    fallbacks.append(key)
                }
            }
        }
        var seen = Set<CatalogQueryKey>()
        for key in invalidated + refreshed + awaiting + fallbacks where seen.insert(key).inserted {
            applyHiddenPolicy(to: key)
        }
        for entry in running where !seen.contains(entry.key) {
            guard let handle = handles[entry.key] else { continue }
            handle.beginRefresh()
            trackWrite(for: entry.key) {
                await entry.run(self, entry.key, entry.ids)
                handle.endRefresh()
            }
        }
        if effects.lists.contains(.counts), let recount = onNavCountsMoved {
            trackWrite { await recount() }
        }
    }

    /// A write that deleted the entity the page shows. Every key is hidden first so no page or list loads whole;
    /// each leaving key then follows `apply` (evicted when `effects.deleted` names its entity for
    /// its kind, else its hidden policy), then `leave` runs, which moves to the next place and
    /// loads its keys once. Nothing reads the deleted id whole in between; a hidden list may re-read it by id and drop its row.
    func apply(
        _ effects: CatalogWriteEffects,
        _ mutation: CatalogMutation? = nil,
        leavingPage leave: () -> Void
    ) {
        visibleKeys = []
        apply(effects, mutation)
        leave()
    }

    /// The warmed keys of this project that a write revalidates through their
    /// descriptor `refreshes`: a `.revalidate` refresh names a key once when the
    /// ids its `follows` slot reports meet the ids the key depends on, or, for a
    /// key that depends on any id, when the slot reports one. Each slot's
    /// reported ids are read once per write. Synchronous, so a key declared here is
    /// revalidated in the same pass as the registry's invalidations.
    func revalidatedKeys(for effects: CatalogWriteEffects) -> [CatalogQueryKey] {
        var named: [CatalogQueryKey] = []
        var seen = Set<CatalogQueryKey>()
        var reportedBySlot: [CatalogQueryFollows: Set<String>] = [:]
        for key in Array(handles.keys) where key.project == projectKey {
            for refresh in key.kind.descriptor.refreshes {
                guard case .revalidate(let dependsOn) = refresh.action else { continue }
                let reported: Set<String>
                if let known = reportedBySlot[refresh.follows] {
                    reported = known
                } else {
                    reported = Set(refresh.follows.ids(in: effects))
                    reportedBySlot[refresh.follows] = reported
                }
                if reported.isEmpty { continue }
                let meets = dependsOn(self, key).map { !$0.isDisjoint(with: reported) } ?? true
                if meets, seen.insert(key).inserted {
                    named.append(key)
                }
            }
        }
        return named
    }

    /// The refresh and recount tasks `apply` has started and not yet finished.
    /// Each removes itself when it ends, so the list does not grow.
    /// A refresh names its key so `readyValue` can wait for the rows it merges.
    private var writeRefreshes: [UUID: (key: CatalogQueryKey?, task: Task<Void, Never>)] = [:]

    private func trackWrite(for key: CatalogQueryKey? = nil, _ work: @escaping @MainActor () async -> Void) {
        let id = UUID()
        writeRefreshes[id] = (key, Task { @MainActor [weak self] in
            await work()
            self?.writeRefreshes[id] = nil
        })
    }

    /// Returns once every refresh and recount `apply` started and every query
    /// load in flight have finished, following any started while it waited.
    /// Tests await this instead of polling against a deadline, which a busy
    /// main actor can outlast. Each task is awaited once, so a load that
    /// finished under a superseded generation cannot keep it spinning.
    func settleWrites() async {
        var awaited = Set<Task<Void, Never>>()
        while true {
            let pending = writeRefreshes.values.map(\.task) + inFlight.values.map(\.task)
            let next = pending.filter { !awaited.contains($0) }
            if next.isEmpty { return }
            for task in next {
                awaited.insert(task)
                await task.value
            }
            await Task.yield()
        }
    }

    /// A mutation with no reported effects.
    func apply(_ mutation: CatalogMutation) {
        apply(.empty, mutation)
    }

    /// Runs each warmed key's descriptor patches. A patch with `follows` gets
    /// the ids that slot names, and only when the write reported activity.
    /// A patch with no `follows` reads the mutation. Returns the keys a patch
    /// could not write because their first load is still in flight.
    private func applyPatches(_ effects: CatalogWriteEffects, _ mutation: CatalogMutation?) -> [CatalogQueryKey] {
        var awaiting: [CatalogQueryKey] = []
        for key in Array(handles.keys) where key.project == projectKey {
            for patch in key.kind.descriptor.patches {
                let result: CatalogPatchResult
                if let follows = patch.follows {
                    guard effects.activity.revision > 0 else { continue }
                    let ids = Set(follows.ids(in: effects))
                    if ids.isEmpty { continue }
                    result = patch.apply(self, key, ids, effects.activity, mutation)
                } else {
                    result = patch.apply(self, key, [], effects.activity, mutation)
                }
                if result == .awaitingFirstValue { awaiting.append(key) }
            }
        }
        return awaiting
    }

    /// What an invalidated key does: a visible one reloads, a hidden one
    /// follows its descriptor's `whenHidden` (mark stale, or reload).
    /// The one path for a registry invalidation and for a descriptor
    /// `refreshes` entry that revalidates a key rather than patching it.
    func applyHiddenPolicy(to key: CatalogQueryKey) {
        switch effectivePolicy(for: key) {
        case .markStale:
            // The old value stays; the next `query` reloads it.
            handles[key]?.markStale()
        case .revalidate:
            invalidate(key)
            revalidate(key)
        }
    }

    private func cachedKeys(for invalidations: [CatalogQueryInvalidation]) -> [CatalogQueryKey] {
        var keys: [CatalogQueryKey] = []
        for invalidation in invalidations {
            switch invalidation {
            case .key(let key):
                keys.append(key)
            case .allCached(let kind):
                keys.append(contentsOf: handles.keys.filter {
                    $0.kind == kind && $0.project == projectKey
                })
            }
        }
        return keys
    }

    /// Get-or-load with in-flight dedupe. Reuses cached `.ready` data until invalidated.
    @discardableResult
    func ensureQuery<Value>(
        _ key: CatalogQueryKey,
        loader: @Sendable @escaping () async throws -> Value
    ) -> QueryHandle<Value> {
        let handle = typedHandle(for: key, as: Value.self)

        if handle.status == .ready, !handle.isStale, inFlight[key] == nil {
            return handle
        }
        if inFlight[key] != nil {
            if !handle.isStale { return handle }
            // A write marked the key while its load was in flight: that load
            // may have read before the write, so start over.
            bumpGeneration(key)
            inFlight[key]?.task.cancel()
            inFlight[key] = nil
        }

        let captured = bumpGeneration(key)
        let hadStaleValue = handle.value != nil
        handle.beginLoading(keepingValue: hadStaleValue)

        let task = Task { @MainActor in
            let outcome: Result<Value, Error>
            do {
                outcome = .success(try await loader())
            } catch {
                outcome = .failure(error)
            }
            if self.generations[key] != captured {
                return
            }
            switch outcome {
            case .success(let result):
                handle.applySuccess(result)
            case .failure(let error):
                handle.applyFailure(error, clearValue: !hadStaleValue)
            }
            if self.inFlight[key]?.generation == captured {
                self.inFlight[key] = nil
            }
        }
        inFlight[key] = (captured, task)
        return handle
    }

    func invalidate(_ key: CatalogQueryKey) {
        bumpGeneration(key)
        inFlight[key]?.task.cancel()
        inFlight[key] = nil
        handles[key]?.markStale()
    }

    /// This project's warmed keys whose descriptor's `deletedWith` is `entity`,
    /// each with its `ownId`.
    private func warmedKeys(deletedWith entity: CatalogDeletedEntity) -> [(key: CatalogQueryKey, id: String)] {
        handles.keys.compactMap { key in
            guard key.project == projectKey, key.kind.descriptor.deletedWith == entity, let id = key.ownId else { return nil }
            return (key, id)
        }
    }

    /// Drops the hidden keys of `entity` whose `ownId` is in `ids`. It works key
    /// by key (a visible key stays: its page holds no handle across an
    /// eviction), where the cap works entity by entity.
    private func evict(_ entity: CatalogDeletedEntity, ids: Set<String>) {
        for (key, id) in warmedKeys(deletedWith: entity) where ids.contains(id) && !visibleKeys.contains(key) {
            evict(key)
        }
        if entity == .handle { shownOrder.removeAll { ids.contains($0) } }
    }

    /// Drops a key the view that queried it no longer shows. A released kind has
    /// exactly one holder, that view (the provenance sheet). A key a place shows
    /// stays, as in `evict(_:ids:)`, so a release never pulls a page's live handle.
    func release(_ key: CatalogQueryKey) {
        guard !visibleKeys.contains(key) else { return }
        evict(key)
    }

    /// Drops a key: its in-flight load is cancelled and its handle forgotten,
    /// so the next `query` starts fresh.
    private func evict(_ key: CatalogQueryKey) {
        bumpGeneration(key)
        inFlight[key]?.task.cancel()
        inFlight[key] = nil
        handles[key] = nil
        valueTypes[key] = nil
        dropDerived(reading: key)
    }

    @discardableResult
    private func bumpGeneration(_ key: CatalogQueryKey) -> Int {
        let next = (generations[key] ?? 0) + 1
        generations[key] = next
        return next
    }

    /// Starts the registry loader when this key is already cached.
    /// Unwarmed keys load on the next `apply(location:)` / `query`.
    private func revalidate(_ key: CatalogQueryKey) {
        guard handles[key] != nil else { return }
        key.kind.descriptor.warm(self, key)
    }

    func invalidateAll(matching predicate: (CatalogQueryKey) -> Bool) {
        for key in handles.keys where predicate(key) {
            invalidate(key)
        }
    }

    private func typedHandle<Value>(for key: CatalogQueryKey, as type: Value.Type) -> QueryHandle<Value> {
        let typeID = ObjectIdentifier(type)
        if let existing = valueTypes[key], existing != typeID {
            #if DEBUG
            assertionFailure("CatalogQueryKey \(key) already bound to a different Value type")
            #endif
        }
        valueTypes[key] = typeID

        if let existing = handles[key] as? QueryHandle<Value> {
            return existing
        }
        let handle = QueryHandle<Value>()
        handles[key] = handle
        return handle
    }
}

/// What `WorkspaceSession.patchCached` did.
enum CatalogPatchResult: Sendable, Equatable {
    /// The cached value changed.
    case applied
    /// Nothing to change: no handle, no value, or the patch changed nothing.
    case unchanged
    /// The key's first load is in flight and may have read before the write.
    case awaitingFirstValue
}
