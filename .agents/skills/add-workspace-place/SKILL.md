---
name: add-workspace-place
description: >-
  Registers a Provenencia macOS workspace place (PlaceRegistry + CatalogQueryKey +
  WorkspaceSession cache + destination view). Use when adding or changing a sidebar
  destination, list/detail split, master–detail vocabulary, CatalogQueryKey,
  PlaceRegistry, WorkspaceDestinationHost, warmListQueries, QueryHandle observation,
  or session.apply(location:) — not for navigation history alone (add-workspace-location)
  or Go SQLite queries alone (add-catalog-query).
---

# Add a workspace place (registry + session cache)

A **place** is a restoreable workspace location plus the catalog reads and SwiftUI
presentation it needs. Spike 4 centralizes this in `Features/Workspace/Session/` and
`WorkspaceDestinationHost` — do **not** copy per-view `.task { load() }` /
`reconcileNavigation` from pre-S4 patterns.

Authoritative patterns: [`docs/macos-client-patterns.md`](../../../docs/macos-client-patterns.md) § Workspace session & place registry (this skill is the how-to). Spike 4 decisions: [`docs/deployment-plan/archive/spike-4/README.md`](../../../docs/deployment-plan/archive/spike-4/README.md).

## When this applies

| Change | This skill | Also use |
| --- | --- | --- |
| New sidebar destination / list / detail page | **Yes** | [`add-workspace-location`](../add-workspace-location/SKILL.md) |
| New catalog read cached across navigation | **Yes** | descriptor arm in `CatalogQueryRegistry` (loader, `patches` / `refreshes`, invalidateOn, whenHidden) |
| Omnibar-searchable entity | Partial (location + queries) | [`add-searchable-kind`](../add-searchable-kind/SKILL.md) |
| History-only deep id on existing place | No | `add-workspace-location` |
| Go table SQL / FFI handler | No | `add-catalog-query`, `add-ffi-handler` |

## Checklist

```
- [ ] WorkspaceLocation: optional deep id (+ == ignores ref/title fluff)
- [ ] WorkspaceSection + sidebar + L10n (if new destination)
- [ ] PlaceID case + PlaceRegistry Spec (matches, queryKeys, presentation, priority)
- [ ] CatalogQueryKey case + descriptor arm (loader, invalidateOn, whenHidden)
- [ ] WorkspacePresentationID + WorkspaceDestinationHost switch arm
- [ ] View: warm queries in .task; read queryHandle in body; @Bindable QueryHandle child
- [ ] Model: warm*Queries(); mutations via session.apply / setQueryValue
- [ ] go(to:) at row / link / omnibar call sites
- [ ] PlaceRegistryTests (+ session tests for new keys)
- [ ] add-searchable-kind (if omnibar-searchable)
```

## Architecture (three layers)

```text
WorkspaceNavigation.currentLocation     ← where (history)
PlaceRegistry.resolve(location)       ← place id, presentation, query keys
WorkspaceSession QueryHandles         ← what (catalog read cache)
```

Navigation commit (`go`, Back/Forward, restore) calls `session.apply(location:)`,
which warms each key from the resolved place **non-blocking**. Views subscribe to
handles; they do not own fetch-on-appear lifecycle.

### Cache update strategy

| Mechanism | Use when |
| --- | --- |
| **Patch** (`patchCached`, `setQueryValue`, descriptor `patches`) | Overlay after a write that returned enough data. A write that reports its activity patches a list's last-updated cell through a `CatalogQueryPatch.lastUpdated` on that list's descriptor (`patches`, with its own `follows`); no refetch. A created Source type uses `.sourceTypeRow` on `.sourceTypesList`, the same generic row patch (`CatalogQueryPatch.row`). An enriched Source uses `.sourceRow` (an update, a type change, or the row a `.createdSource(source)` returns, which it appends) and `.updatedSourceShell` and `.metadataBoard` on the same slots (a board write's `.wroteMetadataBoard` puts the owner's rows on the cached Source page). `patchCached` and `setQueryValue` stay the primitives those slots call. A delete from its own page reports `Deleted` on its registry entry (`effects.Effect.Deleted`), and a list drops the row on `.deleted(entity)` through `CatalogQueryPatch.deletedRows(_:of:)`. For a change the write does not describe (a value, title, or membership), pair the patch with `apply` so the descriptor still refetches. |
| **Refresh** (descriptor `refreshes`, a list) | A key follows the ids a write reports, one entry per slot (`CatalogQueryFollows`: `.reads(…)`, `.touchedHandles`, `.evidenceGraphs`, `.source`, `.list(…)`, `.structure`). An entry either reloads some rows and merges them into a warmed value (`CatalogQueryRefresh.merged(follows:as:read:merge:)`, a `.run` entry: the graph list per Source and graph progress per graph, skipped when the value was never warmed; `CatalogQueryRefresh.mergedRows(_:follows:read:)` beside it for a list Go orders: one batch read of the named ids, rows placed by `CatalogListKey` in a `CatalogListRows` (the value such a list caches: the rows in Go's order and an id→key index, so a merge costs the rows it touched; past `indexedMergeLimit` ids it takes one pass, `Array.mergeSorted`); a failed or unmergeable re-read falls back to the key's hidden policy) or revalidates the key. A key that reloads when a write names an id declares `applyHiddenPolicy(follows:ids:)` (or `followsValue` / `followsOwnId`) there, never a block in the registry, which keeps only what a mutation names; a catalog-wide slot (`.list(…)`, `.structure`) names no row and takes only `applyHiddenPolicyOnAny(follows:)`. `ids` returns what the key depends on, read from the key (`applyHiddenPolicy(followsOwnId:)` reads `CatalogQueryKey.ownId`: the citation kinds' graph, a detail page's entity id) or from its cached value (person claims: the graphs they hold a claim on). A refresh whose ids come from the cached value uses `followsValue`, which matches any id until the value arrives. A per-entity page key (detail and the Person sections) uses `CatalogQueryDescriptor.entityPage(kind:load:)`: its value conforms to `CatalogPageValue`, and `CatalogQueryRefresh.followsInputs` declares one `followsValue` refresh per slot of the value's `inputs` (handles on `.touchedHandles`, Evidence graphs on `.evidenceGraphs`, Sources on `.reads(.sourceRecords)`); its own handle reloads it too (`followsOwnId`). A `.run` entry runs for a key that holds a value and is not stale, on screen or not, and holds `isFetching` on the handle while it runs. `WorkspaceSession.revalidatedKeys(for:_:)` names the warmed keys a write revalidates, and `apply` revalidates each once alongside the registry's invalidations. |
| **Invalidate + revalidate** (`session.apply`) | Default after a catalog write. `apply` marks keys stale and reloads any that are already warmed. Features do **not** `session.query` after `apply`. A write returns `WriteEffects` and the app calls `apply(effects)`; when a mutation still names keys the effects cannot (the Source page's own workspace), call `apply(effects, mutation)`, which applies both once and never invalidates a key twice. |
| **Mark stale** (`whenHidden: .markStale`) | A write moves a value the current screen does not show, and refetching on every write is too costly. `apply` flags the warmed key without a refetch (a `.run` refresh still merges into it while it holds a current value; `QueryHandle.isStale`: not settled until it reloads); the next `query` / place visit reloads it, showing the cached frame meanwhile. A visited graph canvas (`evidenceGraph`) and Source page (`sourceWorkspace`) are examples. `whenHidden` (`.revalidate`, `.markStale`) sets what an invalidated key does when its place is not on screen. The per-entity Conclusion keys (detail and the Person sections) are `.markStale`; a kind a deletion drops declares `deletedWith` (`.handle`, `.source` or `.sourceType`), and `apply` evicts its hidden keys when `effects.deleted` names the entity. At most `maxHiddenEntities` hidden entities keep keys. |
| **View-held key** (`WorkspaceSession.release`) | A key no place shows, read by one view while it is up (the provenance sheet's renders, `ProvenanceSheetHost`). The view warms it in `.task(id: key)`, reads it with `queryHandle(key)` in `body` (nil reads as loading), and drops it with `session.release(key)` on `onChange(of: key)` (the old key) and `onDisappear`. `release` never drops a key in `visibleKeys`, and an in-flight load of a released key never lands on a new handle. Not `whenHidden`: a policy says what an invalidated key does, not when a key no one shows goes. |
| **Stale-while-revalidate** | Navigation reads — Back, sidebar return; show cached frame, `isFetching` while reloading. Not the only refresh path after a write. A reader that shows a failed reload beside the value it kept reads `handle.reading` (loading, failed, or loaded with an optional `refreshFailure`), not `read`, and draws `PVRetryCallout(title:message:handle:id:onRetry:)` (`QueryHandle+RetryCallout.swift`), which passes the handle's `isReading` and `failureRevision` so the notice speaks again for each new failure; a recipe outside Conclusions passes `isRetrying:` and `failureRevision:` to the kit init. |

Do **not** call `session.query()` from view `body` or from model computed properties
that `body` reads every frame — that starves the MainActor and breaks observation.

Do **not** fold a shared list into a page payload (`evidenceGraph` is subjects +
positions + observations; types live on `propertiesWorkspace`). Do **not**
copy catalog lists onto a feature model — observe the handle.

## Steps

### 1. History + location ([`add-workspace-location`](../add-workspace-location/SKILL.md))

Every committed place still flows through `navigation.go(to:)`. This skill assumes
history wiring exists or is added in parallel.

### 2. `PlaceID` + `PlaceRegistry` spec

In [`PlaceRegistry.swift`](../../../macos/App/Features/Workspace/Session/PlaceRegistry.swift):

- Add `PlaceID` case (if new place kind).
- Add `Spec` with **priority** (more specific places beat section roots).
- `matches`: `WorkspaceLocation` predicate (ignore cross-section stray ids).
- `queryKeys`: `[CatalogQueryKey]` for this place (include shared pool keys, e.g. types list on source list).
- A page section declares what it reads once: `ConclusionPageSection.reads(project:entityId:)` lists `ConclusionSectionRead`s, each tagged with a `Role` in the order the place warms them. `.own` is the section's per-entity read (its host draws it); `.companion` is a second per-entity read drawn in its own region; `.supporting` is a shared key the section reads with `session.queryHandle`, so its reload never shows Refreshing. Each role's policy is a switch on `Role` (`showsRefreshing`, `warmsWithPlace`), so a new role must decide both. The `.personDetail` spec appends the warming reads of `location.openPageSection`, and the page's refreshing state follows the `showsRefreshing` ones. A section that reads a list declares it in `reads`, so the place warms the key the section reads.
- `presentation`: `WorkspacePresentationID` for the host router.
- `viewIdentity`: the id the place's view resets on. `WorkspaceDestinationHost` applies `.id(place.viewIdentity)` once for every place; a different value remounts the destination and its `@State` model. Declare the deep id a view is built from (graph, Source, entity, composer or Promote entry key); declare `nil` for list roots and for master–detail places that follow `currentLocation` themselves. Do not add `.id` in a host arm and do not rebind a model in place on an id change.

Extend [`PlaceRegistryTests`](../../../macos/ProvenenciaTests/PlaceRegistryTests.swift):
`registryCoversAllPlaceIDs`, query key table row for the new place.

### 3. `CatalogQueryKey` + descriptor arm

In `Session/`:

- Add a `Kind` case and a `CatalogQueryKey` factory (`.init(kind, project, ids)`).
- Add one arm on `CatalogQueryKey.Kind.descriptor` in [`CatalogQueryRegistry.swift`](../../../macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift): the loader (reading `key.project` and `key.id`, calling `GenealogyStore`), `whenHidden`, and, only when a mutation names the kind, `invalidateOn` with its `invalidation` (`make` requires both or neither). The switch is exhaustive, so a new kind does not compile until that arm exists.

**One cache owns each list — do not fold a shared list into a page payload.**
A deep page composes its own key plus the shared list keys it reads (see the
`sourceDetail` spec), so a vocabulary edit invalidates one list and no pages. The
held `catalogsession` makes the extra RPCs cheap, and the lists are usually already
warm from the sidebar.

**Then tag every mutation whose reply changes any *derived* part of a payload, not
just the part the write names.** A `CatalogTypeSuggestion` carries a whole field
row; `workspace.metadata` is a Go-computed join over the type's suggestions; counts
like `usedBy` / `suggestedFieldCount` move when a different table is written. If the
mutation names no single owner for an id-bearing key, the descriptor's `invalidation` returns
`.allCached(kind)` and every cached key of that kind is busted.

Add [`CatalogQueryRegistryTests`](../../../macos/ProvenenciaTests/CatalogQueryRegistryTests.swift) coverage for load + invalidation (`registry.invalidations`) and the hidden policy (`registry.hiddenPolicy`).

### 4. Presentation + host

- Add `WorkspacePresentationID` case if the host needs a distinct view family.
- Add arm in [`WorkspaceDestinationHost`](../../../macos/App/Features/Workspace/WorkspaceDestinationHost.swift). The host applies identity from the spec; an arm adds no `.id`.
- List vs detail = **two presentations**, two views (Sources pattern). Master–detail
  vocabulary = one presentation, selection from `currentLocation`'s row id (Fields/Types); their `viewIdentity` is `nil`.

### 5. View + model (observation pattern)

**Shell view** (example: list destination):

```swift
@Environment(WorkspaceSession.self) private var session

var body: some View {
    Group {
        if let handle: QueryHandle<[Row]> = session.queryHandle(listKey) {
            ListContent(handle: handle, model: model)
        } else {
            ProgressView()
        }
    }
    .task { model.warmListQueries() }  // idempotent; navigation may have warmed already
}

private struct ListContent: View {
    @Bindable var handle: QueryHandle<[Row]>
    @Bindable var model: MyModel
    // read handle.status / handle.value so Observation repaints when load completes
}
```

**Model rules:**

- `warmListQueries()` calls `session.query(key)` — **only** from `.task`, actions, or tests.
- Display arrays read `session.queryHandle(key)?.value ?? []`.
- A value derived from cached reads for display is built through `session.derived(_:inputs:extra:build:)`, which names the keys and derived values it reads and its plain extras and writes no revision token; a new one is one `DerivedValueID` case and one call (`WorkspaceSession+Derived.swift`).
- CRUD: `session.apply(effects)`, with a `CatalogMutation` only where cache rule 2 keeps one. Optional `setQueryValue` overlay; never `query` after `apply`.
- Sidebar badges: they come only from the recount (Sources, Persons, Events, Places); Configure rows have none.
- A write that changes a sidebar count reports `counts` in `WriteEffects.lists` (Go `effects.ListCounts` on its table's registry entry); `WorkspaceSession.apply` recounts, and the newest recount wins. Features never call `CatalogCounts.refreshAll()`.

**Master–detail selection** (fields): `reconcileSelection(for:)` on
`onChange(of: navigation.currentLocation)` + `onChange(of: handle.status/value)` —
sync apply from history after list is ready; `fallbackToSectionRoot()` if deep id missing.
A page whose read reports its entity gone applies `.leavesForSectionRoot(when:notice:)`, with `notice:` for the toast that says why; a write that deletes the shown entity applies its effects with `session.apply(_:_:leavingPage:)`. That is for a page the deleted entity is the whole of (the Person page, the Source page, the Source type page, whose gone read is `CatalogRowPresence` through `sourceTypePresence(id:)`); a master–detail page keeps its list on screen and applies as usual.

**Source-style detail:** `SourcePageView` pattern — the host remounts it per Source through `viewIdentity`; a plain `.task` warms the workspace key;
`@Bindable workspaceHandle` syncs into section models; fingerprint skips redundant section resets.

### 6. Mutations from section models

- Identity/cover/title: `context.applySource(updated, effects:, typeChanged:)` → `session.apply(effects, .updatedSource(source))` (patches list + workspace; the effects name the Source's graphs).
- A Source type's page applies `.updatedSourceType(type)` on Save (patch-only, the row patch `sourceTypeRow()`); Delete applies its effects with `leavingPage:`, and the types list drops the row on `.deleted(.sourceType)`, and a suggestion add or remove applies `.wroteTypeSuggestions(typeId:edit:)` (one `typeSuggestions` key per type), whose reply `typeSuggestions()` and `typeSuggestionCount()` patch into the cache with no reload while every cached Source page is marked stale.
- Source type moved: `context.applySource(updated, effects: effects, typeChanged: true)` — patches the row, then refetches the page because the engine derives suggested rows from the type.
- A Source delete applies `apply(effects, leavingPage:)`; a Promote Done applies `apply(effects)`.
- Metadata values: a live board's host applies the write's effects with `.wroteMetadataBoard(sourceId:owner:entries:)`, which patches the owner's rows into the cached Source page with no reload (`SourcePageMetadataHost.didWrite`); a draft board (`MetadataDraftHost`) writes nothing, and its owner's Save applies the write's reply rows: every Save, live or draft, on the Source page reaches the page and the cache through `SourcePageContext.applySavedMetadata(_:owner:effects:)` (the Artifact sheet through `SourceArtifactsSection.show(_:metadata:effects:)`, the graph form's Save, the Source's live board through `SourcePageMetadataHost.didWrite`); the citation composer's Citation metadata sheet applies its write's effects alone, and its `citation_boards` read reloads the Citation list that holds the board; the board's views and models live in `Features/MetadataBoard/`; a value created or released on a Source, Artifact or Evidence graph reports `metadata_field_usage`, which the field list's `usedBy` follows.
- Other page edits (notes, credibility): `context.applyWrite(effects)` → bust the `sourceWorkspace` key, and the effects move the lists. Artifact writes (the sheet's Save, create, attach) patch the page and its cache through `SourceArtifactsSection.show`, never `.mutatedSourceWorkspace`. An Artifact or an Evidence graph joining or leaving a Source (create, delete, a move), and an Artifact's file changing, report `source_holdings` for that Source: the page's `sourceWorkspace` reloads on it (a hidden page goes stale) and the Sources list re-reads that Source's row by id (`listSources(projectDir:sourceIDs:)`), so no section model re-reads the workspace by hand after an Artifact write; a label or description edit reports neither. A Source's metadata value write reports `inherited_values` for it, and the page reloads on that too, so the cached Artifact and graph boards inherit the new value (`applySavedMetadata` stays a patch of the owner's rows).
- A Save made of two writes (a new Artifact created, then its file ingested) applies `first.merged(with: second)` once, never `apply` twice: each Source's `source_holdings` then reloads once. `CatalogWriteEffects.merged(with:)` names every field, but the compiler does not enforce it (every field has a default): a new field fails `writeEffectsFieldSetIsPinned` until it is added to `merged(with:)` and `mergedWriteEffectsUnion`.
- Graph and composer writes (`createSubject`, `updateSubject`, `deleteSubject`) and Artifact ↔ graph link writes (`updateArtifact` with `graphIDs`): `session.apply(effects)`; the Evidence graph form's `createEvidenceGraph` / `updateEvidenceGraph` apply their reply rows through `applySavedMetadata`; and a delete's `property_usage` reloads Observation `usedBy` (the citation reads follow the effects).
- Any write under a Source moves its `updated` activity (engine audit scopes). Every write under a Source returns `WriteEffects` with its activity, and `apply(effects)` patches the Sources row in place; the mutations that ride along (`mutatedSourceWorkspace`, `wroteMetadataBoard`) never invalidate `sourcesList` or the Conclusion lists — the Sources row follows the effects' `sourceScopes`, each graph's rows follow `evidenceGraphs`, the keyed reads (citation counts and citations by Artifact, graph progress) follow `reads` for only the graphs named, and the Conclusion lists follow `handles`. A new Source child write returns `WriteEffects` (`writeEffectsProto(wrote)` in its handler); the one write that still reports none (the type–field join) keeps its mutation kinds. `createSource` returns `WriteEffects` and is applied with `apply(effects, .createdSource(source))`, as Copy Source is.
- A new list with a last-updated cell: conform its row to `CatalogLastUpdatedRow` and add `.lastUpdated(Rows.self, follows: …)` to its descriptor `patches` (`[Row].self` for a list the app orders, `CatalogListRows<Row>.self` for one Go orders, whose row also conforms to `CatalogListRow` in `CatalogListMerge.swift`).
- Vocabulary CRUD: apply the write's effects; a key that holds a vocabulary label follows its family list (`.list(.sourceVocabulary)` or `.list(.propertyVocabulary)`) through a `refreshes` entry. A Source type delete reports `Deleted` and `metadata_field_usage`, not `source_vocabulary`, so a key counting types follows `deleted` (a row patch) and the field list follows `metadata_field_usage`. A list patch is an
  optimization on top of the reload unless the write reported everything the patch needs (last-updated activity).

### 7. Tests

| Layer | Tests |
| --- | --- |
| Registry | `PlaceRegistryTests`, `CatalogQueryRegistryTests` |
| Session | `WorkspaceSessionTests` (apply location warms keys, cache hit) |
| Host | `WorkspaceDestinationHostTests` (presentation routing) |
| Feature model | FakeStore + `warmListQueries()` / `warmFromSession()` helpers |

[`add-swift-test`](../add-swift-test/SKILL.md) for new Swift test files.

## Do not

- Gate list vs detail on feature-model `openedSourceID` — use `PlaceRegistry` + host
- Put `session.query()` in `body` or computed properties hit every render
- Use empty `onChange` hacks instead of `@Bindable QueryHandle` observation
- Invalidate list + workspace on every title keystroke — patch synchronously
- Skip `PlaceRegistryTests.registryCoversAllPlaceIDs` when adding `PlaceID` cases

## Related

- Navigation history: [`add-workspace-location`](../add-workspace-location/SKILL.md)
- Catalog session / FFI: [`use-catalog-session`](../use-catalog-session/SKILL.md)
- Search hits → location: [`add-searchable-kind`](../add-searchable-kind/SKILL.md)
- macOS UI patterns: [`docs/macos-client-patterns.md`](../../../docs/macos-client-patterns.md) § workspace session

## Debug

- `PROVENENCIA_DEBUG_SESSION_APPLY=1` — log place + query keys on `session.apply(location:)`
- `PROVENENCIA_DEBUG_NAV_TIMING=1` — log timestamp on each `WorkspaceNavigation` commit (DEBUG builds)
