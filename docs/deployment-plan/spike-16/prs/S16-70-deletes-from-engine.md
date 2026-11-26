# S16-70 — A Source or Source type delete is learned from the engine

**Status:** Draft
**Spike / slice:** Spike 16 · Slice 6g — Catalog query layer
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: the same pages leave and the same rows drop; only the signal that drops them changes)
**Board:** —
**Depends on:** S16-68 (landed [#976](https://github.com/Jake-Robins-Studios/provenencia/pull/976))
**Blocks:** —
**Branch:** `s16-70-deletes-from-engine`
**Version bump:** none — nothing a researcher sees changes, and the new `WriteEffects.deleted` keys and `source_type_usage` list reach only the app the core ships in, as for S16-69 ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md) (Patch, Refresh and Mark stale rows; §6 Mutations), [`add-audit-scope`](../../../../.agents/skills/add-audit-scope/SKILL.md) (the effects registry), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/macos-client.mdc`, `.cursor/rules/swift-tests.mdc`, `.cursor/rules/go-tests.mdc`
**Context:** [design § A Source delete is learned two ways](../catalog-query-layer.md#a-source-delete-is-learned-two-ways-s16-70); working rule "(Batch 6) A Source or Source type delete is learned from the engine only"; bar 40; the `property_usage` and `metadata_field_usage` lists (the usage-list precedent); S16-09's plan ([`S16-09-source-follow-and-stale-pages.md`](S16-09-source-follow-and-stale-pages.md)), which added `deletedWith`
**Planned:** 2026-11-26 against `main` @ `b42ec2c`
**Review:** — (not reviewed yet)

**Runs on macOS.** STEP-1 and STEP-2 (Go) run anywhere. STEP-3 onward need `xcodebuild`. On a machine without it, finish STEP-2, then stop and report that the rest needs a macOS runner.

### Implementer — read this first

1. **This file is the whole task.** Read it top to bottom before you change code. Then read every file under **Current state** and load every skill under **Skills to load**.
2. **Check the base.** Compare `main` with the **Planned** commit. If a file under **Current state** has changed so a row is no longer true, stop and report which rows.
3. **Decisions are made.** Do not reopen a **Decision** or a **Scope** line, and do not swap in a design you like better. If one cannot work, stop: say which ID it is, what you found (path, line, output), and what you would need. Do not improvise around it.
4. **Do only In.** Out stays out, even when it is one line away. Do not refactor, rename, or tidy code the plan does not name.
5. **Work the Steps in order.** Run each step's check before you start the next. A failing check is fixed in that step.
6. **Hit a Stop condition → stop.** Report it. Do not work around it.
7. **Done is the Definition of done.** Report each box with its evidence: the command and its result, the test name, or the manual check you ran.
8. **Docs-only lines in the DoD are part of the PR.** Do not skip them.

---

## 1. Objective

A Source delete reaches the Swift query cache twice today: the client's own `.deletedSource(id:)` mutation, and the engine's `WriteEffects`. A Source type delete reaches it only through `.deletedSourceType(id:)`. After this PR both reach it only through the engine's `WriteEffects.deleted`, as a handle delete already does, so the next delete from its own page (Spike 15's S15-70, a Citation format) is one registry line and one descriptor entry. From the catalog query layer idea (S13-37 plan).

**Why now.** S16-68 put the follow slots and patches in files of their own, so this PR's edits read as edits. S15-70 is waiting to follow this shape instead of adding a third `.deletedX` mutation.

**What stays.** What a researcher sees: the Source page and the Source type page leave as today, the Sources list and the Source types list drop the row, and the type's `usedBy` count moves by one on a Source delete or create. The other Swift mutations (`.createdSource`, which the Sources list still reads for its new row, `.changedSourceType`, `.createdSourceType`, `.updatedSourceType`, the metadata field mutations). `FakeStore.deleteSource` and `FakeStore.deleteSourceType`.

## 2. User stories

**US-1.** As the engine, when a write deletes a Source or a Source type, I report its id under `WriteEffects.deleted`, so that the app learns which rows are gone from me.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | `effects.Resolve` over `rowchange.Deleted("source", s1, …)` | `Set.Deleted == [{Entity: "source", IDs: [s1]}]` |
| AC-1.2 | `effects.Resolve` over `rowchange.Deleted("source_type", t1, …)` | `Set.Deleted == [{Entity: "source_type", IDs: [t1]}]` |
| AC-1.3 | A Source update and a Source type create | `Set.Deleted` is empty |
| AC-1.4 | A Source delete and a Source type delete in one batch, Source first | `[{source, [s1]}, {source_type, [t1]}]`, in change order |
| AC-1.5 | The `DeleteSource` RPC on a Source with its one default graph | `deletedIDs(effects, "source") == [sourceID]` |
| AC-1.6 | The `DeleteSourceType` RPC on an unused user type | `deletedIDs(effects, "source_type") == [typeID]` |
| AC-1.7 | `effects.DeletedEntities()` and Swift's `CatalogDeletedEntity` | Both are `canonical_entity`, `source`, `source_type` (`api/ffi/swift_vocabulary_test.go`, "deleted entities") |
| AC-1.8 | `effects.Resolve` over a Source create, and over a Source delete | `Set.Lists == [source_type_usage, counts]` for each |
| AC-1.9 | A Source title edit | `Set.Lists` is empty |
| AC-1.10 | `effects.Lists` and Swift's `CatalogList` | Both hold `source_type_usage` (`swift_vocabulary_test.go`, "catalog-wide lists") |

**US-2.** As the app, when a write's effects report a deleted Source or Source type, every cache key that showed it follows from those effects alone, with no client mutation.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | `.sourcesList` holds `s1`, `s2`; `apply(effects)` with `deleted: [CatalogWriteEffectsDeleted(entity: .source, ids: ["s1"])]`, revision 7 | The list holds `s2`; not stale; `store.listSourcesCalls` and `store.listSourcesByIDCalls` unchanged |
| AC-2.2 | The same write with revision 0 (no activity) | The list holds `s2` |
| AC-2.3 | The same write naming `"gone"`, an id the list lacks | The list holds `s1`, `s2`; not stale |
| AC-2.4 | `.sourceTypesList` warmed and hidden; the store's `t1` row now has `usedBy` 1 (was 2); `apply(CatalogWriteEffects(lists: [.sourceTypeUsage, .counts]))` | After `settleWrites()`, the list's `t1` row has `usedBy` 1 (the default `.revalidate` policy reloads it) |
| AC-2.5 | The same list; `apply(CatalogWriteEffects(lists: [.counts]))`, then `apply(.createdSource(row))` with no effects | The list's `t1` row keeps `usedBy` 2 after each: neither a handle write's `counts` nor the mutation reaches it |
| AC-2.6 | Hidden `.sourceWorkspace` keys for `s1` and `s2`; `apply(effects)` with `deleted: [CatalogWriteEffectsDeleted(entity: .source, ids: ["s1"])]` | `queryHandle(.sourceWorkspace(s1))` is nil; `s2`'s handle is kept and not stale |
| AC-2.7 | `.sourceTypesList` holds `t-book`, `t-census`; `apply(effects)` with `deleted: [CatalogWriteEffectsDeleted(entity: .sourceType, ids: ["t-book"])]`, twice | The list holds `t-census` after each; not stale; not fetching |
| AC-2.8 | The Source page on screen; `confirmResourceDelete(leaving:)` with `store.nextWriteEffects` naming the Source deleted | `leave` runs once; `queryHandle(.sourceWorkspace(sourceID))` is nil; `store.getSourceWorkspaceCalls` unchanged |
| AC-2.9 | The Source type page; `confirmDelete(leaving:)` with `store.nextWriteEffects` naming the type deleted | `leave` runs once; the session's types list holds the other type only |
| AC-2.10 | `CatalogQueryKey.Kind.sourceWorkspace.descriptor` and `.typeSuggestions` | `deletedWith == .source` and `.sourceType`; `isEntityPage == false` for both; `.sourcesList`'s `invalidateOn` is empty; `.sourceTypesList`'s is `[.changedSourceType]` |
| AC-2.11 | A hidden `.typeSuggestions(t1)` key; `apply(effects)` with `deleted: [CatalogWriteEffectsDeleted(entity: .sourceType, ids: ["t1"])]` | `queryHandle(.typeSuggestions(t1))` is nil |

**US-3.** As a contributor, when I look for how a delete reaches the cache, I find one way.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `rg -n "deletedSource(Type)?\b" macos/App docs/*.md .agents .cursor` | Prints nothing (bar 40) |
| AC-3.2 | `rg -n "removes:" macos/App` | Prints nothing |

## 3. Scope

| In | Covered by |
| --- | --- |
| `sources` and `source_types` registry entries declare `Deleted: onDelete(self())` | STEP-1, AC-1.1 – AC-1.7 |
| A catalog-wide list `source_type_usage`, which `sources` moves on a create or delete; Swift `CatalogList.sourceTypeUsage` | STEP-1, AC-1.8 – AC-1.10, D-4 |
| `CatalogDeletedEntity.source` and `.sourceType` | STEP-3, AC-1.7 |
| `CatalogQueryFollows.deleted(CatalogDeletedEntity)` | STEP-3, AC-2.1 |
| One row-removal patch, `CatalogQueryPatch.deletedRows(_:of:)`, on `.sourcesList` and `.sourceTypesList` | STEP-3, STEP-4, AC-2.1 – AC-2.3, AC-2.7, D-2 |
| The activity guard moves from `WorkspaceSession.applyPatches` into `CatalogQueryPatch.lastUpdated` | STEP-3, AC-2.2, D-3 |
| `.sourceTypesList` restates `usedBy` on `.list(.sourceTypeUsage)` and stops naming `.createdSource` | STEP-4, STEP-5, AC-2.4, AC-2.5, D-4, D-8 |
| `.sourceWorkspace` declares `deletedWith: .source`; `.typeSuggestions` declares `deletedWith: .sourceType` | STEP-4, AC-2.6, AC-2.10, AC-2.11 |
| `.sourcesList` names no mutation (D-5) | STEP-5, AC-2.10 |
| `SourcePageModel.confirmResourceDelete` and `SourceTypePageModel.confirmDelete` apply `apply(effects, leavingPage:)` with no mutation | STEP-5, AC-2.8, AC-2.9 |
| `.deletedSource`, `.deletedSourceType`, `CatalogMutationKind.deletedSource` and `CatalogQueryPatch.row`'s `removes:` go | STEP-5, AC-3.1, AC-3.2 |
| Docs and skill: `docs/macos-client-patterns.md`, `core/database/effects/README.md`, `add-workspace-place`, `docs/ideas/catalog-query-layer.md` | STEP-7, AC-3.1 |

| Out | Home |
| --- | --- |
| `.createdSource` as a mutation (the Sources list's new row), `.changedSourceType` (a type change moves two types' `usedBy`; `source_type_usage` on `source_type_id` updates is the later shape), `.createdSourceType`, `.updatedSourceType`, `.updatedMetadataField`, `.deletedMetadataField` | [`docs/ideas/catalog-query-layer.md`](../../../ideas/catalog-query-layer.md) |
| Deletes of other resources (Citation format) | S15-70 |
| The `engine.proto` comment on `WriteEffects.deleted`, which names `canonical_entity` as its example | not planned (still true; a comment edit regenerates `engine.pb.go` for nothing) |
| A scripted `deleted` entry in `FakeStore.deleteSource` or `.deleteSourceType` | not planned (rule: what a delete reports is the Go test's claim) |
| `CatalogWriteEffects.deletedHandles` read through the new slot | not planned (one reader, `UnpromoteFlow`; it reads the same entry) |
| `.deletedRows(…, of: .handle)` on the Persons, Events and Places lists, which drop a deleted handle's row by an empty re-read (`.mergedRows`) | [`docs/ideas/catalog-query-layer.md`](../../../ideas/catalog-query-layer.md) (STEP-7 adds the line) |
| Repointing landed plans and ship logs that name `.deletedSource` | not planned (history; `archive-docs` deletes them at spike close) |

## 4. Current state

Verified at `b42ec2c`. Swift session paths are under `macos/App/Features/Workspace/Session/`.

| Area | Where | Today |
| --- | --- | --- |
| Effects registry | `core/database/effects/registry.go` `registry["sources"]`, `registry["source_types"]` | Neither declares `Deleted`; only `canonical_entities` does (`Deleted: onDelete(self())`), so `DeletedEntities()` is `[canonical_entity]`. `sources` has `Lists: []List{ListCounts}, ListsOnCreateDelete: true` |
| Usage lists | `registry.go` `ListPropertyUsage`, `ListMetadataFieldUsage`, `Lists`; `CatalogMutation.swift` `CatalogList`; `.propertiesWorkspace` and `.metadataFieldsList` in `CatalogQueryRegistry.swift` | A `usedBy` count follows an engine usage list through `applyHiddenPolicyOnAny(follows: .list(…))`. No list says a type's Source count moved |
| Source creates | `core/database/sources/sources.go` `Create` (Copy Source calls it from `core/database/sourcecopy`); `SourcesModel.swift:472`, `SourceCopyModel.swift:143` | Return `rowchange.Created("source", …)`; both app callers apply `apply(effects, .createdSource(…))`, so the new list reaches the types list on a create |
| Go deletes | `core/database/sources/sources.go` `Delete`, `core/database/sourcetypes/sourcetypes.go` `Delete` | Already return `rowchange.Deleted("source", …)` and `rowchange.Deleted("source_type", …)`; the handlers run them through `writes.Run` / `writes.RunChanges`, which calls `effects.Resolve`. No Go code change beyond the registry |
| Wire | `api/ffi/handlers/write_effects.go` `deletedProtos`; `macos/App/Platform/GoStore.swift` (the `deleted:` decode) | Pass every entity through; Swift drops an entity `CatalogDeletedEntity` lacks. No change |
| Go tests | `core/database/effects/deleted_handles_test.go` `TestResolveReportsDeleted`; `core/database/effects/lists_test.go` `TestResolveLists` ("source create", "source delete" rows expect `[counts]`); `api/ffi/handlers/source_write_effects_test.go` `TestDeleteSourceReturnsEffects`; `api/ffi/handlers/source_defs_test.go` `TestDeleteSourceType` ("deletes unused user type"); `api/ffi/swift_vocabulary_test.go` ("deleted entities") | The first is a table whose `want [][]byte` is hard-wired to `canonical_entity`; the two handler tests check no `deleted` entry; the vocabulary test pins `CatalogDeletedEntity` to `DeletedEntities()`, so Go and Swift change in one commit |
| Deleted entity | `CatalogMutation.swift` `CatalogDeletedEntity` | One case, `handle = "canonical_entity"` |
| Mutations | `CatalogMutation.swift` `CatalogMutation.deletedSource(id:)`, `.deletedSourceType(id:)`, `CatalogMutationKind.deletedSource`, `invalidationKind` | The client's delete signals this PR removes |
| Follow slots | `CatalogQueryFollows.swift` `CatalogQueryFollows` | No slot reads `CatalogWriteEffects.deleted` |
| Patches | `CatalogQueryPatch.swift` `CatalogQueryPatch.lastUpdated`, `.sourceTypeRow()`, `.row(_:patched:appendsOn:removes:)` | `row`'s `removes:` closure has one user, `sourceTypeRow()`'s `.deletedSourceType` arm |
| Patch runner | `WorkspaceSession.swift` `applyPatches(_:_:)` | Skips every patch with `follows` when `effects.activity.revision == 0` (`guard effects.activity.revision > 0 else { continue }`); `lastUpdated` is the only such patch today |
| Descriptors | `CatalogQueryRegistry.swift` `.sourcesList`, `.sourceTypesList`, `.sourceWorkspace` arms | `.sourcesList` reloads whole on `.deletedSource` (its only `invalidateOn`); `.sourceTypesList` reloads on `.createdSource`, `.deletedSource` and `.changedSourceType` and patches on `.deletedSourceType`; `.typeSuggestions` declares no `deletedWith`; `.sourceWorkspace` invalidates the deleted Source's page on `.deletedSource` and declares no `deletedWith` |
| Eviction | `WorkspaceSession.swift` `evict(_:ids:)`, `warmedKeys(deletedWith:)`, `trimHiddenEntities(keeping:)`; `CatalogQueryDescriptor.isEntityPage` | Generic over the entity; the hidden-entity cap reads `.handle` only. No change |
| Leaving | `WorkspaceSession.swift` `apply(_:_:leavingPage:)` | Hides every key, applies, then leaves. No change |
| Source page | `macos/App/Features/Sources/SourcePageModel.swift` `confirmResourceDelete(leaving:)` | `apply(effects, .deletedSource(id: target.id), leavingPage: leave)`. The only `deleteSource` caller in the app |
| Source type page | `macos/App/Features/SourceTypes/SourceTypePageModel.swift` `confirmDelete(leaving:)`; the type's doc comment (line 8) | `apply(effects, .deletedSourceType(id: target.id), leavingPage: leave)`. The only `deleteSourceType` caller; the doc comment names `.deletedSourceType` |
| FakeStore | `macos/App/Platform/FakeStore.swift` `deleteSource`, `deleteSourceType`, `nextWriteEffects` | Return `nextWriteEffects`, `.empty` unless a test scripts it. No change |
| Swift tests | `macos/ProvenenciaTests/CatalogQueryRegistryTests.swift` `ownIdNamesTheKeysOneRow` (expects `sourceWorkspace.descriptor.deletedWith == nil`), `evidenceGraphEffectsReloadOnlyThatGraph`, `invalidationsComeFromRegistrySpecs` (expects `.createdSource` to name `.sourceTypesList`), `createdSourceInvalidatesTypesList`, `updatedAndDeletedSourceTypePatchTheTypesList`, `noMutationReachesAConclusionKey`; `WorkspaceSessionTests.swift` `staleKeyIsNotSettled`, `setQueryValueClearsStaleAndPatchKeepsIt`, `staleKeyQueriedDuringLoadReloads`, `deletedSourceDropsItsGraphs`; `SourcePageModelTests.swift` `resourceDeleteDoesNotReloadTheDeletedSource`; `SourceTypePageModelTests.swift` `goneTypeNamesItselfInTheNotice`, `deletingLeavesAndDropsTheRow` | Each names `.deletedSource` or `.deletedSourceType`, or relies on it; §8 says what each becomes |

**Precedent.** The usage list copies `metadata_field_usage` (`ListMetadataFieldUsage` with `ListsOnCreateDelete` on its entries, `.metadataFieldsList`'s `.applyHiddenPolicyOnAny(follows: .list(.metadataFieldUsage))`). S16-09 ([#780](https://github.com/Jake-Robins-Studios/provenencia/pull/780)) added `CatalogQueryDescriptor.deletedWith` and the eviction for handles; its plan's Next adds names this one ("one `CatalogDeletedEntity` case, `deletedWith: .source` on `.sourceWorkspace`"). Copy its eviction test shape (`WorkspaceSessionTests.applyLeavingPageLoadsTheNextListOnce`: warm, apply effects with `deleted`, `#expect(session.queryHandle(key) == nil)`). The registry line copies `canonical_entities`.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `.deleted(CatalogDeletedEntity)` is a row slot: `isCatalogWide` is false, and `ids(in:)` returns the entity's entry of `effects.deleted`, or none | The removal patch needs the ids; a row slot keeps `requireRowIDs()` true for it | A catalog-wide slot — the patch could not name the row |
| D-2 | The removal patch takes the entity, not a slot: `deletedRows(_:of:)` follows `.deleted(entity)` and calls `follows.requireRowIDs()` (its sixth caller). It runs first in each list's `patches` | A delete patch on any other slot would drop live rows; first, so the row patches after it never touch a gone row | `deletedRows(_:follows:)` — takes any slot; keeping `row`'s `removes:` and adding a mutation per delete — the shape the rule retires |
| D-3 | `applyPatches` runs every `follows` patch whatever the revision; `lastUpdated`'s closure returns `.unchanged` when `activity.revision == 0`, before it calls `patchCached` | A deletion is a fact with or without activity; only the last-updated cell needs a revision. The behavior of `lastUpdated` is the same | Keeping the runner's guard — a removal would silently depend on a revision, and every test would have to script one |
| D-4 | The engine reports `source_type_usage` (`ListSourceTypeUsage`, after `ListMetadataFieldUsage` in `Lists`): `sources` declares `Lists: []List{ListCounts, ListSourceTypeUsage}` and keeps `ListsOnCreateDelete`, so a Source create or delete moves it and an update never does. `.sourceTypesList` follows it with `.applyHiddenPolicyOnAny(follows: .list(.sourceTypeUsage))` and keeps the default `.revalidate` policy (user, 2026-11-26) | One mechanism for a `usedBy` count, owned by the engine, as `property_usage` and `metadata_field_usage` are | A client refresh on any `.deleted(.source)` id — a second mechanism that cannot cover a create; `.list(.counts)` — fires on every handle write |
| D-5 | `.sourcesList` loses `invalidateOn` and `invalidation`: no mutation names it | Its one kind was `.deletedSource`; the `make` precondition requires both empty | — |
| D-6 | Go lands first (STEP-1, STEP-2), Swift after (STEP-3 – STEP-5). STEP-1 adds the two `CatalogDeletedEntity` cases with the registry lines, since `swift_vocabulary_test.go` pins the Swift enum to `DeletedEntities()` | Each commit builds and passes `go test`; the Swift cases are inert until a slot reads them | The Swift cases in STEP-3 — the vocabulary test fails on STEP-1's commit |
| D-7 | Tests that used `.deletedSource` only to mark `.sourcesList` stale (`staleKeyIsNotSettled`, `setQueryValueClearsStaleAndPatchKeepsIt`) call `session.invalidate(key)` instead | After D-5 no mutation marks the list stale; `invalidate` is the primitive `applyHiddenPolicy(to:)` calls for a hidden `.markStale` key, and `applyLeavingPageLoadsTheNextListOnce` already calls it | Rewriting them around another key — they test the handle's stale flag, not the list |
| D-8 | `.sourceTypesList`'s `invalidateOn` becomes `[.changedSourceType]`: a create reaches it through `source_type_usage`. `.createdSource` stays a mutation for the Sources list's row (user, 2026-11-26) | `apply` reaches the key once either way; the mutation no longer says what the engine reports | Keeping it until `.createdSource` retires — a second signal for the same count |

**Rules this plan bends.** D-4 against the working rule "(Batch 6) A Source or Source type delete is learned from the engine only" ("`.sourceTypesList` restates `usedBy` on any `.deleted(.source)` id") → the engine's usage list keeps one mechanism for counts and covers a create → the user chose the usage list and dropping `.createdSource` from the types list (2026-11-26) → the rule, the S16-70 scope entry and the slice design were reworded at planning.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `CatalogDeletedEntity.source = "source"`, `.sourceType = "source_type"` *(new cases)* | enum case | `.handle = "canonical_entity"` | Extends it; raw values are Go's `Effect.Entity` |
| `CatalogQueryFollows.deleted(CatalogDeletedEntity)` *(new case)* | enum case | `.reads(CatalogRead)` (a slot keyed by a wire enum) | Extends the enum (D-1) |
| `CatalogQueryPatch.deletedRows<Row: Identifiable & Sendable>(_: Row.Type, of entity: CatalogDeletedEntity) -> Self where Row.ID == String` *(new)* | func | `row(_:patched:appendsOn:removes:)`'s removal branch | It moves here from `row`, reading the effects instead of a mutation (D-2) |
| `effects.ListSourceTypeUsage` (`"source_type_usage"`) *(new)*, `CatalogList.sourceTypeUsage` *(new case)* | const, enum case | `ListMetadataFieldUsage`, `CatalogList.metadataFieldUsage` | A new list per the effects README recipe (D-4) |

Searched: `rg -n "deleted" macos/App/Features/Workspace/Session/CatalogQuery*.swift` (no slot or patch reads `deleted`); `rg -n "_usage" core/database/effects/registry.go` (the two usage lists); `rg -n "removeAll \{ \$0.id" macos/App/Features/Workspace/Session` (only `row`'s removal branch and `.sourcesList`'s `merge`).

**Builds on.** The effects registry's `Deleted` field and `DeletedEntities()` (wire keys); its `Lists` and `ListsOnCreateDelete`; `CatalogQueryDescriptor.deletedWith` and `WorkspaceSession.evict(_:ids:)` (S16-09); `requireRowIDs()` (S16-68).
**Deletes.** `CatalogMutation.deletedSource(id:)` and `.deletedSourceType(id:)`; `CatalogMutationKind.deletedSource` and its `invalidationKind` arm; `row`'s `removes:` parameter, its default, and its removal branch; `sourceTypeRow()`'s `removes:` argument; `.sourcesList`'s `invalidateOn` and `invalidation`; `.deletedSource` and `.createdSource` in `.sourceTypesList`'s `invalidateOn`, `.deletedSource` in `.sourceWorkspace`'s `invalidateOn` and in `.sourceWorkspace`'s `invalidation` switch; the revision guard in `applyPatches` (moved, D-3).
**Next adds.** Retiring `.changedSourceType` from the types list: `source_type_usage` on a `source_type_id` update of `sources`. S15-70's format delete: `Deleted: onDelete(self())` on its table's entry, one `CatalogDeletedEntity` case, and `.deletedRows(Row.self, of: .citationFormat)` on the list that shows it (or `deletedWith:` on its page key).

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A hidden `.sourceWorkspace` key is evicted on a Source delete (was: marked stale) | `WorkspaceSession.evict(_:ids:)` | Generic over the entity; skips visible keys; `shownOrder` is touched for `.handle` only. The next `query` for that id starts fresh and reads gone |
| A visible `.sourceWorkspace` for a deleted Source is no longer invalidated | `SourcePageModel` | The one delete caller applies through `leavingPage:`, which hides every key first, so the page's key is evicted, not shown. Stop condition if another caller exists |
| `.sourcesList` drops a row on a delete while its first load is in flight | `WorkspaceSession.patchCached` | Returns `.awaitingFirstValue`; `apply` revalidates the key, as for `lastUpdated` |

### Scale

At the map's Scale (Batch 2: 3,000 Sources): a Source delete today hides every key, marks `.sourcesList` stale, and the Sources list it leaves to reloads all 3,000 rows. After: one `removeAll` over the cached rows, no store call. `.sourceTypesList` reloads as today on a Source delete or create (one row per type, tens), and not on a handle write. A Source type delete: one `removeAll`, as `.deletedSourceType` does today. One id per delete.

### Edges

- **Assumptions.** `applyPatches` ran `follows` patches only with activity (D-3 moves that to the one patch that needs it; T-8 holds `lastUpdated` with revision 0). `evict` assumes `ownId` is the entity's id: `.sourceWorkspace`'s `ownId` is its Source id (`ownIdNamesTheKeysOneRow`). `isEntityPage` reads `deletedWith == .handle`, so `.source` and `.sourceType` keys stay out of the hidden-entity cap (AC-2.10); `deletedWith`'s doc says so.
- **Neighbors.** A write that reports `sourceScopes` for a Source but no deletion leaves the row alone; a handle write's `counts` leaves the types list alone (AC-2.5); a Source title edit reports no usage list (AC-1.9); an unknown deleted id changes nothing (AC-2.3); a second identical delete changes nothing (AC-2.7). A Source delete also reports `evidence_graphs` for its default graph, which `.evidenceGraphsList` follows unchanged (`deletedSourceDropsItsGraphs`).
- **Removed inputs.** The deleted Source's `usedBy` share is restated by reload, not computed (D-4). A deleted type's hidden `typeSuggestions` key is evicted (AC-2.11).
- **Real data.** None — no table, seed or configuration drives a rule here.
- **Untrusted size.** None — the ids come from the engine's report of this write: one per delete.

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/effects` | `registry["sources"]` and `registry["source_types"]` gain `Deleted: onDelete(self())`, as `canonical_entities` has it. `DeletedEntities()` becomes `[canonical_entity, source, source_type]`; `Effect.validate` already checks the path ends at the entry's own table. `ListSourceTypeUsage` *(new)* with the doc "a Source was created or deleted, so a Source type's `usedBy` count changed", in `Lists` after `ListMetadataFieldUsage`; `sources` declares it beside `ListCounts` (D-4); its comment "A rename or cover change moves no sidebar count." adds "or usage count" |

### FFI

None — `WriteEffects.deleted` already carries any entity; no proto change.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Deleted entities | `CatalogDeletedEntity` | `CatalogMutation.swift` | `.source`, `.sourceType` with one doc line each |
| Usage list | `CatalogList.sourceTypeUsage = "source_type_usage"` | same | After `.metadataFieldUsage`, with Go's doc line |
| Delete eviction | `CatalogQueryDescriptor.deletedWith`, `isEntityPage` | `CatalogQueryRegistry.swift` | `deletedWith`'s doc adds "Only `.handle` keys count toward `maxHiddenEntities`." |
| Follow slot | `CatalogQueryFollows.deleted` | `CatalogQueryFollows.swift` | Doc: "`CatalogWriteEffects.deleted`: the ids of one entity a write deleted." Cases in `isCatalogWide` and `ids(in:)` (D-1) |
| Removal patch | `CatalogQueryPatch.deletedRows(_:of:)` | `CatalogQueryPatch.swift` | `patchCached(key, as: [Row].self)`, `removeAll { ids.contains($0.id) }`, returns whether the count changed; leaves any stale flag |
| Row patch | `CatalogQueryPatch.row(_:patched:appendsOn:)` | same | Doc drops its removal sentence; `sourceTypeRow()`'s doc drops "a `.deletedSourceType` removes its row" |
| Last-updated patch | `CatalogQueryPatch.lastUpdated` | same | D-3 guard; its doc comment adds "A write with no activity moves nothing." |
| Sources list | `.sourcesList` arm | `CatalogQueryRegistry.swift` | `patches: [.deletedRows(CatalogSource.self, of: .source), .lastUpdated(...), .sourceRow()]`; no `invalidateOn`/`invalidation`; the arm comment adds "A Source delete reports the id in `deleted`, and the row drops with no reload." |
| Source types list | `.sourceTypesList` arm | same | `invalidateOn: [.changedSourceType]` (D-8); `patches: [.deletedRows(CatalogSourceType.self, of: .sourceType), .sourceTypeRow(), .typeSuggestionCount()]`; `refreshes` gains `.applyHiddenPolicyOnAny(follows: .list(.sourceTypeUsage))` after the `source_vocabulary` entry; the arm comment says a Source create or delete reports `source_type_usage`, which restates `usedBy`, and a type delete drops its row |
| Suggestions key | `.typeSuggestions` arm | same | `deletedWith: .sourceType` |
| Source page key | `.sourceWorkspace` arm | same | `deletedWith: .source`; `.deletedSource` leaves `invalidateOn` and the `invalidation` switch's first case (`case .mutatedSourceWorkspace(let sourceId):`) |
| Patch runner | `WorkspaceSession.applyPatches(_:_:)` | `WorkspaceSession.swift` | Drops the revision guard (D-3); its doc drops "and only when the write reported activity" |
| Page deletes | `SourcePageModel.confirmResourceDelete`, `SourceTypePageModel.confirmDelete` | `Features/Sources/`, `Features/SourceTypes/` | `apply(effects, leavingPage: leave)`; the type page's doc comment names `the engine's WriteEffects.deleted` in place of `.deletedSourceType` |

States: none change. Accessibility: none changes.

### Strings

None — no copy, and no action changes what it covers.

## 7. Steps

**STEP-1 — The engine reports deleted Sources and Source types**
Files: `core/database/effects/registry.go`, `core/database/effects/lists_test.go`, `macos/App/Features/Workspace/Session/CatalogMutation.swift` (the `CatalogDeletedEntity` and `CatalogList` cases only, D-6). Skill: `add-audit-scope`.
Do: per Go core and the Deleted entities and Usage list rows; T-16.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/effects/ ./api/ffi/` passes (the "deleted entities" vocabulary case included).
Commit: "Report a deleted Source or Source type, and a Source type's usage, in the write's effects."

**STEP-2 — Go tests**
Files: `core/database/effects/deleted_handles_test.go`, `api/ffi/handlers/source_write_effects_test.go`, `api/ffi/handlers/source_defs_test.go`. Rule: `go-tests.mdc`.
Do: T-1 – T-3.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/effects/ ./api/ffi/handlers/` passes.
Commit: "Test the deleted ids a Source and a Source type delete report."

**STEP-3 — The slot and the patch**
Files: `CatalogQueryFollows.swift`, `CatalogQueryPatch.swift`, `WorkspaceSession.swift`. Skill: `add-workspace-place`.
Do: per the macOS rows for the slot, `deletedRows`, `lastUpdated` and `applyPatches` (D-3). Leave `row`'s `removes:` for STEP-5.
Check: `xcodebuild` builds; the Swift tests pass unchanged.

**STEP-4 — The descriptors follow the effects**
Files: `CatalogQueryRegistry.swift`, `CatalogQueryRegistryTests.swift`, `WorkspaceSessionTests.swift`.
Do: per the Sources list, Source types list and Source page key rows, and the Suggestions key and Delete eviction rows: `deletedRows`, the `source_type_usage` refresh, `deletedWith: .source` and `.sourceType`. Every `.deletedSource`, `.deletedSourceType` and `.createdSource` entry stays until STEP-5, `.sourcesList`'s `invalidateOn` and `invalidation` included. Write T-4, T-6, T-8, and T-9 without its two `invalidateOn` lines, which STEP-5 adds.
Check: build; T-4, T-6, T-8, T-9 and every other Swift test pass.
Commit (STEP-3 and STEP-4): "Drop a deleted Source or Source type from the lists by the write's effects."

**STEP-5 — The pages apply effects alone; the mutations go**
Files: `SourcePageModel.swift`, `SourceTypePageModel.swift`, `CatalogMutation.swift`, `CatalogQueryPatch.swift`, `CatalogQueryRegistry.swift`, and the test files of T-7 and T-10 – T-13.
Do: per the Page deletes row and **Deletes** (D-5, D-8 included); write T-5, rewrite T-7 and T-10 – T-13, and add T-9's two `invalidateOn` lines.
Check: `rg -n "deletedSource(Type)?\b|removes:" macos/App` prints nothing; the Swift tests pass.
Commit: "Learn a Source or Source type delete from the engine only."

**STEP-6 — Whole check**
Files: none.
Do: run `scripts/check-pr.sh`.
Check: it prints `check-pr: PASS` with no Swift warning.

**STEP-7 — Docs**
Files: `docs/macos-client-patterns.md`, `core/database/effects/README.md`, `.agents/skills/add-workspace-place/SKILL.md`, then `docs/deployment-plan/spike-16/deployment-plan.md`, `completed.md`, this plan.
Do:
- `macos-client-patterns.md` line 89: the `deleted` clause names `source` and `source_type` beside `canonical_entity`, and says `.sourcesList` and `.sourceTypesList` drop the row through `CatalogQueryPatch.deletedRows(_:of:)` and `.sourceWorkspace` declares `deletedWith: .source`; strike `.deletedSource` from the kept Source-row mutations, `.deletedSourceType` and "and `.deletedSourceType`" from the patch-only list, and "`deleteSource` applies `.deletedSource(id:)`;" (the Source page's delete applies its effects with `apply(_:leavingPage:)`). Line 92: the clause "and also removes the row a `removes` mutation (`.deletedSourceType`) names" becomes: a delete drops its row through `deletedRows(_:of:)` on the `.deleted(entity)` slot. Line 116: the naming example `(.deletedSource)` becomes `(.createdSource)`.
- `core/database/effects/README.md` line 9: after "so `canonical_entity` lists the handles" add "and `source` and `source_type` the Sources and Source types a delete erased". Line 17: after the `metadata_field_usage` clause add "`source_type_usage` (a Source was created or deleted, so a Source type's `usedBy` changed: `sources` sets `ListsOnCreateDelete`)".
- `add-workspace-place`: Patch row (line 62): add "A delete from its own page reports `Deleted` on its registry entry (`effects.Effect.Deleted`), and a list drops the row on `.deleted(entity)` through `CatalogQueryPatch.deletedRows(_:of:)`." Mark stale row (line 65): "a kind a deletion drops declares `deletedWith`" names `.handle` and `.source`. Line 172: "`.updatedSourceType(type)` on Save and `.deletedSourceType(id:)` on Delete (both patch-only, the row patch `sourceTypeRow()`; a delete leaves with `leavingPage:`)" becomes "`.updatedSourceType(type)` on Save (patch-only, the row patch `sourceTypeRow()`); Delete applies its effects with `leavingPage:`, and the types list drops the row on `.deleted(.sourceType)`". Line 174: "A Source delete applies `apply(effects, leavingPage:)`; a Promote Done applies `apply(effects)`."
- `docs/ideas/catalog-query-layer.md`: `.createdSource` no longer reaches the Source types list (only the Sources list's row); a line that the Persons, Events and Places lists could drop a deleted handle's row through `deletedRows(_:of: .handle)` instead of an empty re-read.
- After the PR is open: the S16-70 map row Status `Landed [#N](https://github.com/Jake-Robins-Studios/provenencia/pull/N)`; `completed.md` a new entry at the top in S16-69's shape (nothing a researcher sees changes; a Source or Source type delete reaches the cache through `WriteEffects.deleted`, the list drops one row with no reload, `.deletedSource` and `.deletedSourceType` are gone); this plan's Status and a **Landed.** line.
Check: AC-3.1 prints nothing; `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-70-deletes-from-engine.md` reports no errors; `python3 scripts/check-guidance-names.py` passes.
Commits: "Document that a delete from its own page reports its ids." and "Record S16-70 as landed."

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/effects/deleted_handles_test.go` `TestResolveReportsDeleted` | Its `want` becomes `[]effects.DeletedIDs` (the handle rows wrap their ids in `{canonical_entity, …}`), and it gains rows: Source delete → `[{source,[s1]}]`; Source type delete → `[{source_type,[t1]}]`; Source update and type create → none; Source then type delete → both, in change order. Changes: `rowchange.Deleted("source", s1, map[string]any{"title": "a"})`, `rowchange.Deleted("source_type", t1, map[string]any{"label": "Deed"})`, `*rowchange.Updated("source", s1, map[string]any{"title": "a"}, map[string]any{"title": "b"})` (it returns a pointer), `rowchange.Created("source_type", t1, map[string]any{"label": "Deed"})`. The inline `database.Create` setups across the package stay | AC-1.1, AC-1.2, AC-1.3, AC-1.4 |
| T-2 | Go | `api/ffi/handlers/source_write_effects_test.go` `TestDeleteSourceReturnsEffects` | Adds `deletedIDs(eff, "source") == []string{sourceID}` | AC-1.5 |
| T-3 | Go | `api/ffi/handlers/source_defs_test.go` `TestDeleteSourceType` "deletes unused user type" | Its `after` unmarshals the response and checks `deletedIDs(resp.GetEffects(), "source_type") == []string{typeID}` | AC-1.6 |
| T-4 | Swift | `CatalogQueryRegistryTests.swift` `deletedSourceDropsTheListRowWithoutReloading` *(new)* | AC-2.1, then AC-2.3; then AC-2.2 on a fresh session | AC-2.1, AC-2.2, AC-2.3, D-2, D-3 |
| T-5 | Swift | same, `createdSourceInvalidatesTypesList` becomes `sourceTypeUsageRestatesTheTypesList` | AC-2.4, then AC-2.5 | AC-2.4, AC-2.5, D-4, D-8 |
| T-6 | Swift | `WorkspaceSessionTests.swift` `sourceDeleteEvictsItsHiddenPage` *(new)* | AC-2.6, then AC-2.11 | AC-2.6, AC-2.11 |
| T-7 | Swift | `CatalogQueryRegistryTests.swift` `updatedAndDeletedSourceTypePatchTheTypesList` | Its delete half applies `CatalogWriteEffects(deleted: [CatalogWriteEffectsDeleted(entity: .sourceType, ids: ["t-book"])])` twice; the last `invalidations(by: .deletedSourceType …)` line goes | AC-2.7 |
| T-8 | Swift | `WorkspaceSessionTests.swift` `lastUpdatedMovesNothingWithoutActivity` *(new)* | A cached Sources list; `apply(CatalogWriteEffects(sourceScopes: ["s1"]))` with revision 0 → the row's `updated` unchanged, key not stale | D-3 |
| T-9 | Swift | `CatalogQueryRegistryTests.swift` `ownIdNamesTheKeysOneRow` | Last line expects `deletedWith == .source`, and `.typeSuggestions` `.sourceType`, each `isEntityPage == false`; adds `.sourcesList` `invalidateOn.isEmpty` and `.sourceTypesList` `invalidateOn == [.changedSourceType]`, and `CatalogQueryFollows.deleted(.source)`: `isCatalogWide == false`, `ids(in:)` reads only its entity | AC-2.10, D-1, D-5, D-8 |
| T-10 | Swift | `SourcePageModelTests.swift` `resourceDeleteDoesNotReloadTheDeletedSource` | Scripts `store.nextWriteEffects` with `deleted: [CatalogWriteEffectsDeleted(entity: .source, ids: [sourceID])]`; adds `queryHandle(.sourceWorkspace(sourceID)) == nil` | AC-2.8 |
| T-11 | Swift | `SourceTypePageModelTests.swift` `deletingLeavesAndDropsTheRow`, `goneTypeNamesItselfInTheNotice` | The first scripts `nextWriteEffects` with `deleted: [CatalogWriteEffectsDeleted(entity: .sourceType, ids: ["t2"])]`; the second applies those effects for `t1` instead of the mutation | AC-2.9 |
| T-12 | Swift | `WorkspaceSessionTests.swift` `staleKeyIsNotSettled`, `setQueryValueClearsStaleAndPatchKeepsIt` | `session.invalidate(key)` in place of `apply(.deletedSource(id: "gone"))` | D-7 |
| T-13 | Swift | `WorkspaceSessionTests.swift` `staleKeyQueriedDuringLoadReloads`, `deletedSourceDropsItsGraphs`; `CatalogQueryRegistryTests.swift` `evidenceGraphEffectsReloadOnlyThatGraph`, `invalidationsComeFromRegistrySpecs`, `noMutationReachesAConclusionKey` | The first two apply their effects with no mutation (`staleKeyQueriedDuringLoadReloads` stays stale through its `reads(.evidenceGraphs)` refresh: the key's first load is in flight, so `apply` adds it to `fallbacks` and marks it stale; if it does not, stop and report; `deletedSourceDropsItsGraphs` adds `deleted: [CatalogWriteEffectsDeleted(entity: .source, ids: ["S"])]`); the other three drop their `.deletedSource` lines and entries; `invalidationsComeFromRegistrySpecs`'s `.deletedSource` expectation goes and its `.createdSource` one expects no invalidation | AC-3.1 |
| T-14 | Go | `api/ffi/swift_vocabulary_test.go` "deleted entities" (unchanged) | `CatalogDeletedEntity`'s raw values → `effects.DeletedEntities()` | AC-1.7, D-6 |
| T-16 | Go | `core/database/effects/lists_test.go` `TestResolveLists` | "source create" and "source delete" → `[ListSourceTypeUsage, ListCounts]`; "source title edit" → none (unchanged); "source type then source keeps list order" → `[ListSourceVocabulary, ListSourceTypeUsage, ListCounts]` | AC-1.8, AC-1.9 |
| T-17 | Go | `api/ffi/swift_vocabulary_test.go` "catalog-wide lists" (unchanged) | `CatalogList`'s raw values → `effects.Lists` | AC-1.10 |
| T-15 | Shell | AC-3.1 and AC-3.2 commands, and `rg -n "\.deletedSource(Type)?\b" macos/ProvenenciaTests` | the tree after STEP-7 → no output | AC-3.1, AC-3.2 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `api/ffi/swift_vocabulary_test.go` (Go and Swift enum out of step) and the Sources list tests in `WorkspaceSessionTests.swift` that assume `.sourcesList` reloads on a delete.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none added)
- [ ] Sweep: `.deletedSource`, `.deletedSourceType`, `CatalogMutationKind.deletedSource` and `removes:` `rg`'d across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left (AC-3.1); `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (D-4: updated at planning)
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New (no UI)
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated) (not gated)
- [ ] Domain doc updated if a rule in docs/*.md changed: docs/macos-client-patterns.md (STEP-7)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

Makes bar 40 true.

1. Open a project with two Sources of the type Book and nothing filed under one of them. Note Book's count on the Source types list.
2. Open the empty Source, choose Delete, confirm. The page leaves to the Sources list with today's notice, and the Source is not in the list.
3. Open Source types: Book's count is one less.
4. Add a Source of the type Book: Book's count is one more.
5. Add a Source type "Deed" with no Sources, open it, choose Delete, confirm. The page leaves to the Source types list, and Deed is not in it.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A test still relies on `.sourcesList` reloading after a delete | STEP-4's run lists every Swift failure before STEP-5 removes the mutation |
| A real delete reports no `deleted` entry (a handler skips `writes.Run`) | T-2 and T-3 run the RPCs end to end |

**Stop and report if:**

- `rg -n "\.deleteSource\(|\.deleteSourceType\(" macos/App --glob '!Platform/*'` finds a caller other than `SourcePageModel` and `SourceTypePageModel`.
- `sources.Delete` or `sourcetypes.Delete` at your base no longer returns `rowchange.Deleted` with entity `source` / `source_type`.
- A `CatalogQueryPatch` other than `lastUpdated` has `follows` set at your base (D-3 assumes `lastUpdated` is the only one).
- A descriptor other than `.sourceWorkspace` and `.typeSuggestions` keys by a Source or Source type id.
- A Source is created in Go other than through `sources.Create`.
- T-4 cannot pass without `.sourcesList` reloading.

## 12. Open questions

None.

## 13. PR

**Title:** S16-70 — A Source or Source type delete is learned from the engine
**Body:** objective in one sentence; what shipped against US-1 – US-3; AC evidence (test names, the AC-3.1 `rg`); deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-70-deletes-from-engine.md`.
