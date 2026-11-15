# S16-26 — Conclusion lists merge the rows a write touched

**Status:** Draft
**Spike / slice:** Spike 16 · Slice 2e — The app's cache
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: the three lists draw the same rows in the same order; only how a write reaches them changes)
**Board:** —
**Depends on:** S14-42 (Spike 14, landed [#748](https://github.com/mendahu/provenencia/pull/748): the exact touched set), S16-25 (landed [#847](https://github.com/mendahu/provenencia/pull/847): keys as values, `CatalogQueryFollows: Hashable`)
**Blocks:** —
**Branch:** `s16-26-lists-merge-touched-rows`
**Version bump:** patch — a write re-reads only its rows of the Persons, Events and Places lists, and the list RPCs gain an optional id filter and a sort key old clients ignore; nothing new on screen ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/macos-client.mdc`, `.cursor/rules/swift-tests.mdc`, `.cursor/rules/go-tests.mdc`, `.cursor/rules/catalog-queries.mdc`
**Context:** [design § Swift](../cache-architecture.md#swift) ("Lists merge the touched rows"); [`docs/macos-client-patterns.md`](../../../macos-client-patterns.md) rule 2 and "Conclusion keys"; working rules: "(Batch 2) The point of this batch is simpler code", "(Batch 2) Swift caches one value per view, follows its inputs and shows it stale while refreshing", "(Batch 2) Orders are defined and results do not move", "(Batch 2) Measure growth"; goal bar 12 ("a write updates only the rows it touched in the Persons, Events and Places lists")
**Planned:** 2026-11-15 against `main` @ `3667125`
**Review:** — (not reviewed yet)

**Runs on macOS.** STEP-5 to STEP-7 and the Xcode half of `scripts/check-pr.sh` need Xcode. On a machine without `xcodebuild`, do STEP-1 to STEP-4 and the Go checks, then stop and report that the Swift steps need a macOS runner.

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

After a write, the Persons, Events and Places lists re-read only the rows the write touched and put each where it belongs, instead of reloading the whole list. Today a write that names any handle reloads a visible list whole (115–137 ms for the Persons list at 16,000 persons, warm) and marks a hidden one stale, so the next visit reloads it whole too. Afterwards each list asks Go for the rows of the write's touched ids (under 1.3 ms for the writes measured on the 4,000-person fixture), drops those ids from its rows, and inserts each returned row by a sort key Go sends with it. A hidden list keeps merging the same way, so Back to a list shows current rows with no reload.

Go owns list order. Today it sorts with `collate.CompareString` and a date comparator; afterwards every list order in `conclusionsummaries` sorts by one key type, `ListKey` (a title's collation key or a date's order key, then the ref), and the list RPCs send that key. The app compares keys and never computes one.

**Why now.** S14-42 made the touched set exact (`WriteEffects.handles` plus `summary_handles`): Go's own summary cache already drops exactly those rows (`graphcache.dropCommittedDisplays`). S16-25 settled the key and refresh shapes this PR declares on. Bar 12's last clause is the only one of its kind left.

**What stays.** Every list draws the same rows in the same order. A Property, term or subject type label edit (`property_vocabulary`) still reloads each list whole. The `lastUpdated` patch keeps moving a row's Updated cell for a write that names its scope and touches no summary (a note). The sidebar recount is unchanged. The per-entity keys keep S16-25's follows. Search hits, the detail reads and the Person page sections do not read the sort key.

## 2. User stories

**US-1.** As a researcher, when I make a change that alters a few people, events or places, the lists show the new rows in the right places without reloading every row.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | The Persons list on screen holds rows `p1`, `p2`, `p3` (keys in that order); a write reports `handles: ["p2"]`, `summaryHandles: ["e9"]` | The store is asked once, for `["p2", "e9"]`; the list's whole read is not called again (`listPersonSummariesEntityIDs == [nil, ["p2", "e9"]]`) |
| AC-1.2 | AC-1.1, and Go returns `p2` with a key after `p3`'s | The list reads `p1`, `p3`, `p2` |
| AC-1.3 | AC-1.1, and Go returns nothing for `p2` (deleted, merged away, or not a Person) | The list reads `p1`, `p3` |
| AC-1.4 | The list holds `p1`, `p3`; a write reports `handles: ["p2"]` and Go returns `p2` with a key between them | The list reads `p1`, `p2`, `p3` |
| AC-1.5 | The Persons, Events and Places lists are all warmed and hidden; a write reports `handles: ["p2"]` | Each list is asked for `["p2"]` and merges; none is marked stale; showing one afterwards starts no load |
| AC-1.6 | A list's re-read throws | The list reloads whole (visible) as `.merged` does today |
| AC-1.7 | A write reports `lists: [property_vocabulary]` and `handles: ["p2"]` | Each list reloads whole once; no partial read runs for it |
| AC-1.8 | A write reports only `handleScopes: ["p1"]` with a newer activity (a note) | No read; `p1`'s Updated cell moves (unchanged behavior) |

**US-2.** As a contributor, list order has one owner: Go sorts every list by the key it sends, so a merged list and a full reload cannot disagree.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | On the large fixture at 4,000 persons, each of five writes (T-9) | The previous full list of each kind, with the write's touched rows merged in by `ListKey`, equals the full list read after the write, row for row and in order, `Updated` included |
| AC-2.2 | Places titled `Montréal` (ref `PLC-B`), `Montreal` (`PLC-A`), `MONTREAL` (`PLC-C`), `Zürich` (`PLC-D`), and an untitled `PLC-0` | Order `PLC-A`, `PLC-B`, `PLC-C`, `PLC-D`, `PLC-0`: the three Montreal titles collate equal and break by ref, the untitled row is last. `TestListOrderIsByShownTitle`, `TestPlaceSort`, `TestPersonListOrder` and `TestListPersonsSortIgnoresHonorifics` pass unchanged |
| AC-2.3 | Events dated `1850`, `BEF 1850`, `AFT 1850`, `ABT 1850`, undated `EVT-A`, undated `EVT-B` | The order `TestEventOrderAtKnownEnd` and `TestListEvents` pin today; the undated rows last, by ref |
| AC-2.4 | `ListPersonSummaries` with `entity_ids` of a Person, an Event, a merged Person, an unknown id | One row: the Person's, with its `sort_key` and `updated_revision` set as in the whole list |
| AC-2.5 | `ListPersonSummaries` with a malformed id in `entity_ids` | The handler's usual bad-id error (`parseIDs`) |

## 3. Scope

| In | Covered by |
| --- | --- |
| Go: `conclusionsummaries.ListKey` *(new)*; `SortByTitle`, `sortByDateKey` and the three list sorts sort by it; list rows carry it as `SortKey`; `titleKey`, `titleKeyLess`, `dateKeyLess` go | STEP-1, AC-2.2, AC-2.3 |
| Go: `ListPersonsOf`, `ListEventsOf`, `ListPlacesOf` *(new)*, the list rows of given ids; one `fillUpdated` helper for the four-line activity loop the three lists repeat | STEP-2, AC-2.4 |
| FFI: `entity_ids` on the three list requests; `ListSortKey` *(new)* and a `sort_key` field on the three summary messages, filled by the list handlers | STEP-3, AC-2.4, AC-2.5 |
| Go: the equivalence test on the large fixture and a benchmark of the per-write read at 4,000 and 16,000 persons | STEP-4, AC-2.1 |
| Swift: `CatalogListSortKey` *(new)* on the three summary types; `GenealogyStore` list methods take `entityIDs:`; GoStore and FakeStore follow | STEP-5, AC-1.1 |
| Swift: `refreshCached` reads a batch; `CatalogQueryRefresh.mergedRows` *(new)*; `CatalogListRow` *(new)* and `[Row].mergeSorted(_:replacing:)` *(new)*; the three list descriptors merge on `.touchedHandles` and revalidate while hidden | STEP-6, AC-1.1 – AC-1.8 |
| Swift tests | STEP-7, T-10 – T-16 |
| Docs: `macos-client-patterns.md` rule 2 and "Conclusion keys", `add-workspace-place` Refresh and Mark stale, `catalog-caches.md`, the design, the map | STEP-8 |

| Out | Home |
| --- | --- |
| The lists' failure notice | [`docs/ideas/person-page-followups.md`](../../../ideas/person-page-followups.md) (map row's Not this PR) |
| A label edit merging instead of reloading the lists | not planned (D-8: a catalog-wide change, every row may move) |
| Sorting by another column in the app (birth, updated) | not planned: the lists show rows as given |
| The Sources list adopting `mergedRows` | not planned: it follows `sourceScopes` with in-place patches and `.sourceRow()`, and its order is the app's |
| Cancelling an in-flight merge when a later write names the same ids | not planned: `.merged` has the same order today and the engine queue is first in, first out (§6 Edges) |
| A name format write | not planned: no runtime write changes the profile (`name_format_profiles` reports no effects; `WorkspaceSession.loadNameFormat` runs once at open) |

## 4. Current state

Verified at `3667125`.

| Area | Where | Today |
| --- | --- | --- |
| Go order | `core/database/conclusionsummaries/order.go` `titleCollator`, `SortByTitle`, `titleKey`, `titleKeyLess`, `sortByKey`, `sortByDateKey`, `sortPersons`, `sortPlaces`, `personSortKey`, `placeTitle` | Title order compares with `titleCollator.CompareString` (root, ignore case and diacritics), untitled last, ties by lowercased ref. `SortByTitle` also orders the claims' Sources and graphs (`core/database/persondetail/claims.go`) and unlisted participants (`participants.go`) |
| Go date order | `core/database/conclusionsummaries/compose.go` `dateKey`, `dateKeyOf`, `withRef`, `sortEvents`, `dateKeyLess`, `eventKeyOf`, `birthKeyOf`; `core/valuecompare/dateorder.go` `DateKey.Compare`, `DateKey.Int64` | Dated first, by `DateKey` (day, then side), then lowercased ref. `sortByDateKey` serves `sortEvents`, the life picks (`lifeFacts`) and `SortByBirth`. `Int64` "is k as one integer whose order is Compare's" |
| Go lists | same file, `ListPersons`, `ListEvents`, `ListPlaces`, `handleActivity`, `PersonsByIDs`, `EventsByIDs`, `PlacesByIDs`, `persons`, `events`, `places`, `nodesOf` | The three lists compose every unmerged row of the kind (display cache first), sort, then fill `Updated` per row in a loop each repeats. The `ByIDs` reads compose and sort the given ids (unknown, merged, other kind absent) and leave `Updated` empty |
| Go summary rows | `core/database/conclusionsummaries/conclusionsummaries.go` `PersonSummary`, `EventSummary`, `PlaceSummary` | No sort key field |
| Display drop | `core/database/graphcache/commit.go` `dropCommittedDisplays`; `core/writes/run.go` (`set.SummaryDeps = deps`) | A commit drops the stored rows of its roots and `SummaryDeps`; the full list reads every other row from the store, so a row outside that set reads the same before and after the write |
| FFI | `api/proto/engine.proto` `ListPersonSummariesRequest`, `ListEventSummariesRequest`, `ListPlaceSummariesRequest` (field 1 `project_dir` only), `PersonSummary` (last field 10), `EventSummary` (17), `PlaceSummary` (14); `api/ffi/handlers/conclusion_summaries.go` `ListPersonSummaries`, `ListEventSummaries`, `ListPlaceSummaries`, `personSummaryProto`, `eventSummaryProto`, `placeSummaryProto`; `api/ffi/handlers/catalog.go` `parseIDs` | Each handler lists every row. The summary mappers are shared with the detail and search reads (`conclusionSummaryProto`) |
| Effects (Swift) | `macos/App/Features/Workspace/Session/CatalogMutation.swift` `CatalogWriteEffects.touchedHandles` | `handles + summaryHandles`, deduplicated, empty ids dropped |
| Merge refresh | `macos/App/Features/Workspace/Session/CatalogLastUpdated.swift` `CatalogQueryRefresh.merged(follows:as:read:merge:afterMerge:)`, the `fileprivate init(follows:run:)` ("`merged` is the only way to declare one"); `macos/App/Features/Workspace/Session/WorkspaceSession.swift` `refreshCached(_:as:ids:read:merge:afterMerge:)`, `apply(_:_:)` | `refreshCached` calls `read` once per id, in order, then merges every part in one `patchCached`; a throw reloads the key through its hidden policy. `apply` runs a `.run` refresh only for a key that would revalidate (visible, or `whenHidden: .revalidate`), holds a value and is not stale; any other warmed key it names is revalidated or marked stale instead |
| List descriptors | `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift` `.personsList`, `.eventsList`, `.placesList` arms | `whenHidden: .markStale`; patches `[.lastUpdated(Row.self, follows: .handle)]`; refreshes `[.applyHiddenPolicyOnAny(follows: .touchedHandles), .followsPropertyLabels]`; `load` calls `store.list…Summaries(projectDir:)` |
| Merge precedent | same file, `.evidenceGraphProgress` and `.evidenceGraphsList` arms | Both declare `.merged`: one store call per graph or Source id |
| Row protocols | `CatalogLastUpdated.swift` `CatalogLastUpdatedRow` (+ conformances for the three summaries and `CatalogSource`), `CatalogPageValue` | One small protocol per shared field, one empty conformance per type |
| Swift rows | `macos/App/Platform/GenealogyStore.swift` `CatalogPersonSummary`, `CatalogEventSummary`, `CatalogPlaceSummary`; protocol requirements `listPersonSummaries(projectDir:)`, `listEventSummaries(projectDir:)`, `listPlaceSummaries(projectDir:)` | No sort key. Three conformers: `GoStore`, `FakeStore`, `ThrowingStore` (`macos/ProvenenciaTests/OnboardingModelTests.swift`) |
| GoStore | `macos/App/Platform/GoStore.swift` `listPersonSummaries`, `listEventSummaries`, `listPlaceSummaries`, `mapPersonSummary`, `mapEventSummary`, `mapPlaceSummary` | One request each; the mappers are shared with the detail and search reads |
| FakeStore | `macos/App/Platform/FakeStore.swift` `listPersonSummaries` (counts `listPersonSummariesCalls`; `personSummaries()` sorts named rows by lowercased form, then unnamed by ref), `listEventSummaries` (`seededEventSummaries`), `listPlaceSummaries` (`seededPlaceSummaries`); `listEvidenceGraphsSourceIDs: [String?]` | The precedent for recording a filter argument |
| Tests (Swift) | `macos/ProvenenciaTests/WorkspaceSessionTests.swift` `hiddenListsGoStaleVisibleListReloads`, `applyPromoteMarksHiddenPersonsListStale`, `sourceWriteEffectsPatchSourcesAndLeaveListsAlone` (its AC-2.12 half), `applyLeavingPageLoadsTheNextListOnce`, helpers `personSummary`, `eventSummary`, `placeSummary`; `macos/ProvenenciaTests/CatalogQueryRegistryTests.swift` `invalidationsComeFromRegistrySpecs` (the lists' `refreshes.map(\.follows) == [.touchedHandles, .list(.propertyVocabulary)]` loop), the `hiddenPolicy(.personsList…) == .markStale` lines (near line 443), `handleScopesInvalidateNothing` | Pin today's whole reload and stale policy |
| Tests (Go) | `core/database/conclusionsummaries/conclusionsummaries_test.go` `TestListPersons`, `TestPersonListOrder`, `TestListPersonsSortIgnoresHonorifics`, `TestListOrderIsByShownTitle`, `TestPlaceSort`, `TestListEvents`, `TestEventOrderAtKnownEnd`, `TestSortByBirth`, `TestSortByTitleKeysOnce`, `TestListSummariesCarryUpdated`; `api/ffi/handlers/conclusion_summaries_test.go` `TestListPersonSummaries`, `TestListEventSummaries`, `TestListPlaceSummaries`; `core/database/promotealign/perf_test.go` `newLargeFixture`, `TestLargeSourceBudgets` | Pin today's orders and the handlers |

**Precedent.** `.evidenceGraphsList` (S14-11) is a list that re-reads part of itself by the ids a write names and merges it, with `FakeStore.listEvidenceGraphsSourceIDs` recording the filter and `graphListMergesOneSourcesReRead` testing it: copy its test shape. `sources.DateSortKey` / `SourceRecord.date_sort_key` (an order key Go computes and sends, `DateKey.Int64`) is the precedent for a sort key on the wire. `CatalogLastUpdatedRow` is the precedent for `CatalogListRow`. `TestLargeSourceBudgets` is the precedent for a test on the large fixture with named ceilings.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `type ListKey struct { Last bool; Primary []byte; Ref string }` *(new)* in `order.go`, with `func (k ListKey) Less(o ListKey) bool`: a non-`Last` key first; then `bytes.Compare(Primary)`; then `Ref < o.Ref`. Title keys: `titleListKey(title, ref string) ListKey` *(new)*: `title = strings.TrimSpace(title)`; empty → `{Last: true, Ref: strings.ToLower(ref)}`; else `Primary` is a copy of `titleCollator.KeyFromString(&buf, title)` with a local `collate.Buffer`. Date keys: `func (k dateKey) listKey() ListKey` *(new)*: not `ok` → `{Last: true, Ref: k.ref}`; else `Primary` is 8 bytes big-endian of `uint64(k.at.Int64()) ^ (1 << 63)` | One comparator for every list order; a collation key compares bytewise exactly as `CompareString` (measured: 0 disagreements over the 20,115 Person titles at 16,000 persons) and costs less (key build 3.9 ms + sort 4.1 ms vs 47.6 ms); `Int64` already carries `Compare`'s order and the sign flip keeps it bytewise | Sending a position (moves on every insert); keeping `CompareString` in Go and adding a second encoding for the wire (two comparators that must agree); a string key (a collation key is not text) |
| D-2 | `SortByTitle` sorts by `titleListKey`, and `sortByDateKey` by `key(row).listKey()`, both through `sortByKey(…, ListKey.Less)`. `titleKey`, `titleKeyLess` and `dateKeyLess` go. `sortPersons`, `sortEvents` and `sortPlaces` first set each row's `SortKey` (`titleListKey(personSortKey(h, profile), h.Entity.Ref)`, `eventKeyOf(h).listKey()`, `titleListKey(placeTitle(h), h.Entity.Ref)`), then `sortByKey(rows, func(h) ListKey { return h.SortKey }, ListKey.Less)` | The row carries the key the list was sorted by, so the wire key cannot drift from the order; `SortByBirth` and the life picks gain the one comparator too | Computing the wire key in the handler after sorting (a second call path) |
| D-3 | `PersonSummary`, `EventSummary`, `PlaceSummary` gain `SortKey ListKey` ("the key the row's list sorts by; set by the read that sorted it"). The display cache stores rows before the sort, so a stored row holds no key; `displayed` returns copies | The key depends on the name format profile and the ref, not only the composed row | Storing the key in the display cache |
| D-4 | `ListPersonsOf(c *database.Catalog, ids [][]byte) ([]PersonSummary, error)` *(new)*, `ListEventsOf`, `ListPlacesOf`: the list rows of the given ids, as the whole list gives them (composed, sorted, `SortKey` and `Updated` set); unknown, merged and other-kind ids are absent; no ids (after `database.UniqueBlobIDs`) → `nil, nil`. Each calls the kind's `PersonsByIDs`-style compose (`persons(c.Graph(), ids, false, true, nil)`) then `fillUpdated`. `fillUpdated[H any](c *database.Catalog, rows []H, at func(*H) (id []byte, updated *effects.Activity)) error` *(new)* replaces the three loops in `ListPersons`, `ListEvents`, `ListPlaces` and serves the three new reads | The id read already exists (`nodesOf` with ids); one helper for the repeated loop; an empty filter can never mean "every row" in Go's API | A variadic or nil-means-all filter on `ListPersons` (an empty slice would list everything) |
| D-5 | Proto: each list request gains `repeated string entity_ids = 2;` ("When set, only these handles' rows, in list order; an unknown, merged or other-kind id is absent (S16-26). Empty lists every row"). `message ListSortKey { bool last = 1; bytes primary = 2; string ref = 3; }` *(new)* ("A row's place in its list (`conclusionsummaries.ListKey`): rows with `last` false first, then `primary` bytewise, then `ref` bytewise. The app inserts a re-read row where its key falls"). `PersonSummary.sort_key = 11`, `EventSummary.sort_key = 18`, `PlaceSummary.sort_key = 15`, each documented "Filled on the List*Summaries responses only", as `updated_revision` is. The list handlers parse `entity_ids` with `parseIDs`, call `ListXOf` when any id was given, else `ListX`, and set `sort_key` with `listSortKeyProto(h.SortKey)` *(new)* after the shared mapper. Regenerate with `./scripts/generate-proto.sh` | Additive and old clients ignore it; one request shape for both reads; the shared mappers stay list-agnostic | A new RPC per kind (three more methods for one filter); a wrapper message for the filter (Swift never sends an empty filter, D-6) |
| D-6 | Swift: `struct CatalogListSortKey: Sendable, Equatable, Comparable { var last = false; var primary = Data(); var ref = "" }` *(new)* in `GenealogyStore.swift` beside the summaries; `<` compares `last` (false first), then `primary.lexicographicallyPrecedes`, then `Array(ref.utf8).lexicographicallyPrecedes`, the Go order. `var sortKey = CatalogListSortKey()` on the three summary types. The three protocol requirements become `listPersonSummaries(projectDir: String, entityIDs: [String]?)` (and Event, Place): nil lists every row. `GoStore` returns `[]` for an empty array without calling the engine, sets `entityIds` otherwise, and maps `sort_key` in the three list functions only (`mapListSortKey` *(new)*, private static). `ThrowingStore` takes the new signature | Same comparison as Go's; `listEvidenceGraphs(projectDir:sourceID:)`'s nil-means-all precedent; an empty filter never reaches the engine | A default argument on the protocol (hides the filter at the 3 loaders); mapping the key in the shared mappers (detail and hits would carry a meaningless key) |
| D-7 | `refreshCached` reads a batch: `read: @MainActor ([String]) async throws -> Part` once, `merge: @MainActor (inout Value, Part) -> Void`, `afterMerge: (@MainActor (Part, _ previousRevision: Int) -> Void)?`. `CatalogQueryRefresh.merged(follows:as:read:merge:afterMerge:)` keeps its per-id signature and passes `Part = [(String, Part)]`: its read loops the ids in order, its merge folds each in order, its `afterMerge` gets `Dictionary(parts, uniquingKeysWith: { _, last in last })`. `static func mergedRows<Row: CatalogListRow>(_: Row.Type, follows: CatalogQueryFollows, read: @escaping @MainActor @Sendable (WorkspaceSession, CatalogQueryKey, [String]) async throws -> [Row]) -> CatalogQueryRefresh` *(new)* calls `refreshCached(key, as: [Row].self, ids: ids, read: { try await read(session, key, $0) }, merge: { rows, fresh in rows.mergeSorted(fresh, replacing: ids) })`. The `.run` init's doc: "`merged` and `mergedRows` are the only ways to declare one" | One store call per write per list (a hub write naming 20,000 handles would otherwise be 20,000 FFI calls); one merge core with two declarations; `merged`'s two callers do not change | A per-id `merged` with `Part = Row?` (one FFI call per id); a second core beside `refreshCached` |
| D-8 | `protocol CatalogListRow: CatalogLastUpdatedRow, Identifiable where ID == String { var sortKey: CatalogListSortKey { get } }` *(new)* in `CatalogLastUpdated.swift`, empty conformances for the three summaries. `extension Array where Element: CatalogListRow { mutating func mergeSorted(_ fresh: [Element], replacing ids: [String]) }` *(new)*: drop every row whose id is in `ids` or in `fresh`; sort `fresh` by `sortKey` (stable); merge the two sorted runs in one pass, a fresh row going after kept rows with an equal key. O(n + k log k) | One pass over the list; tolerant of a fresh row that was not asked for (no duplicate) | `firstIndex` + insert per row (O(n·k)); re-sorting the whole list (the app does not own order) |
| D-9 | The three list arms: `whenHidden: .revalidate` (the default; the `whenHidden:` argument is removed), patches unchanged, refreshes `[.mergedRows(CatalogPersonSummary.self, follows: .touchedHandles) { session, key, ids in try await session.store.listPersonSummaries(projectDir: key.project.projectDir, entityIDs: ids) }, .followsPropertyLabels]` (Event, Place alike); `load` passes `entityIDs: nil`. A label write reloads a hidden list whole at once (rare: a vocabulary edit) | The map row: "revalidate while hidden"; the `.run` gate merges only a key that would revalidate, so `.markStale` would leave every hidden list to reload whole on its next visit (bar 12) | Keeping `.markStale` (bar 12 fails for hidden lists); merging on a label edit (every row may move) |
| D-10 | Test layers. Go holds the order (existing order tests, T-1) and the exactness of the touched set at Scale (T-9: five real writes on the large fixture, Go-side merge of the touched rows equals the full list after). Swift holds the merge (`mergeSorted` unit tests, T-10) and the session wiring with FakeStore (T-11 – T-15). The handler tests hold the filter and the key on the wire (T-6 – T-8) | Each half is tested where it lives, as S16-25 D-10 did; FakeStore keeps no engine rule (`swift-tests.mdc`): it gives rows keys from its own existing order | An FFI round trip per write in Swift (no engine in Swift tests) |
| D-11 | FakeStore: `listPersonSummariesEntityIDs`, `listEventSummariesEntityIDs`, `listPlaceSummariesEntityIDs: [[String]?]` *(new)*, appended on every call, as `listEvidenceGraphsSourceIDs`. A filtered call returns the rows of the whole read whose `id` is in the filter, in the whole read's order. `personSummaries()` sets each row's `sortKey` to `CatalogListSortKey(last: name == nil, primary: Data((name?.form.lowercased() ?? "").utf8), ref: entity.ref.lowercased())` and sorts by it, replacing its closure. `seededPersonSummaries: [CatalogPersonSummary]?` *(new)*: when set, the whole read returns it in place of the composed rows, as `seededEventSummaries` does for Events. Seeded rows keep the keys a test gives them | FakeStore's own order, stated once as a key; filtering keeps whatever a test seeded | FakeStore collating like Go (an engine rule in the fake) |
| D-12 | Commits: (1) STEP-1 (one key for list order, no behavior change); (2) STEP-2 and STEP-3 (the id filter and the key on the wire); (3) STEP-4 (the large-fixture test and benchmark); (4) STEP-5 to STEP-7 (the app merges); (5) STEP-8 (docs) | Each builds and passes its tests; (4) needs (2)'s generated Swift | One commit |

**Rules this plan bends.** None. The map row says this PR makes false and updates `macos-client-patterns.md` rule 2 ("One save made away from a list reloads no list") and "Conclusion keys", and `add-workspace-place` Refresh; STEP-8 does.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `conclusionsummaries.ListKey`, `titleListKey`, `dateKey.listKey` *(new)* | Go type, funcs | `titleKey`, `titleKeyLess`, `dateKeyLess` | Replaces them: one comparator for every list order |
| `PersonSummary.SortKey` (and Event, Place) *(new)* | Go field | `Updated` (set by the list read, not stored) | Same lifecycle |
| `ListPersonsOf`, `ListEventsOf`, `ListPlacesOf` *(new)* | Go funcs | `PersonsByIDs`, `EventsByIDs`, `PlacesByIDs` | Built on the same compose; the `ByIDs` reads (search, detail) leave `Updated` empty and their callers do not want the activity reads |
| `fillUpdated` *(new)* | Go generic func | the three `Updated` loops | Replaces them |
| `entity_ids`, `ListSortKey`, `sort_key` *(new)* | proto fields, message | `ListEvidenceGraphsRequest.source_id`; `SourceRecord.date_sort_key` | Same patterns |
| `listSortKeyProto` *(new)* | Go mapper | `termProto` | One mapper per message, as the file does |
| `CatalogListSortKey` *(new)* | Swift struct | none (Swift sorts no list) | Mirrors the wire |
| `CatalogListRow` *(new)* | Swift protocol | `CatalogLastUpdatedRow` | Refines it |
| `Array.mergeSorted(_:replacing:)` *(new)* | Swift func | `.evidenceGraphsList`'s merge closure (`removeAll` + `append`) | That list's order does not matter to the app; this one is ordered |
| `CatalogQueryRefresh.mergedRows` *(new)* | Swift constructor | `CatalogQueryRefresh.merged` | One batch read instead of one per id (D-7); both share `refreshCached` |
| FakeStore `list…SummariesEntityIDs`, `seededPersonSummaries`, `listPersonSummariesError` *(new)* | test hooks | `listEvidenceGraphsSourceIDs` | Same pattern |
| T-9 `TestListMergeMatchesReload`, `BenchmarkListRowsOfWrite` *(new)* | Go test, bench | `TestLargeSourceBudgets`, `BenchmarkCacheSizes` | Same fixture |

**Builds on.** S14-42's exact touched set (`touchedHandles`); the `.run` refresh path and its gate (`apply`); `refreshCached`; `parseIDs`; `nodesOf` with ids; the large fixture.
**Deletes.** `titleKey`, `titleKeyLess`, `dateKeyLess`; the three `Updated` loops in `ListPersons`, `ListEvents`, `ListPlaces`; FakeStore `personSummaries()`'s sort closure; `refreshCached`'s per-id loop (it moves into `merged`); the three lists' `.applyHiddenPolicyOnAny(follows: .touchedHandles)` and `whenHidden: .markStale`; the whole-list reload on every handle write; "a hidden list goes stale" in `macos-client-patterns.md` rule 2, its "Conclusion keys" line and `add-workspace-place`'s Mark stale list.
**Next adds.** Another ordered list keyed by handles (a Spike 15 Citations list by Source) declares `.mergedRows` and conforms its row to `CatalogListRow`; S16-29's prefetch is not affected; a later list sort column would add a second key from Go, not an app comparator.

### Reach

None — no new navigation path. One state becomes reachable: a hidden list holds a value that is current, not stale, so Back to it shows that value and starts no load. It is current exactly when the touched set is (T-9).

### Scale

At the map's Scale (Batch 2: 4,000 and 16,000 persons; 8,115 and 20,115 Person rows, 10,067 Event rows, 51 Place rows on the large fixture; planning machine, warm):

- **Today, per write that names a handle:** a visible list reloads whole — Persons 39–73 ms (4,000) and 115–137 ms (16,000), Events 28–39 ms, Places 0.2 ms — and a hidden one reloads whole on its next visit.
- **After, per write:** each warmed list makes one store call with the write's touched ids. Measured on the 4,000 fixture for the three kinds together: a new person promoted (1 id) 27 µs; a birth at the 6,000-event city promoted (3 ids) 0.43–0.55 ms; a name cited on a filed person (1 id) 41 µs; a parent filed above the city (4 ids) 1.2 ms; a toponym cited on the city (2 ids) 0.42 ms. Swift's merge is one pass over the list (20,115 rows) plus the returned rows. STEP-4's benchmark records the same writes at 16,000.
- **Crafted:** a merge of a 20,000-child hub names about 20,000 ids: one request of about 740 KB of ids, a read no costlier than the whole list (the same compose over fewer nodes), and one merge pass. No cap is needed: the read is bounded by the whole list's cost.
- **Go order:** `SortByTitle` now builds one collation key per row: at 20,115 titles 3.9 ms to build and 4.1 ms to sort, against 47.6 ms with `CompareString` today; the claims and participants orders get the same.
- **Budget (rule "Measure growth"):** T-9 asserts the three filtered reads of each write take under `ceilingListRowsOfWrite = 20 * time.Millisecond` at 4,000 persons (measured 1.3 ms at most; the ceiling catches a slip to a whole-list compose). `BenchmarkListRowsOfWrite` reports the whole lists and the filtered reads at 4,000 and 16,000; the ship log records both against today.

### Edges

- **Assumptions.** (a) A row the write did not name reads the same before and after it: Go's display cache drops exactly roots ∪ `SummaryDeps` (`dropCommittedDisplays`) and the app's `touchedHandles` is `Handles ∪ SummaryDeps`; the extra roots Go drops (association ends, a deleted node's neighbours, a merged node's neighbours) are in `SummaryDeps` because the link writes that move them report their ends (effects `SummaryDeps` doc). Held by T-9 over five writes, which found no untouched row changed at planning time. (b) Keys are total: refs are `UNIQUE NOT NULL` (`000032.sql`), lowercasing keeps them unique, so no two rows tie. (c) The list held in Swift is sorted by its keys: every row came from a list read, which Go sorted by the same key (D-2). (d) A row's key depends on its own name or title, its ref, and for Persons the name format profile; no write changes the profile at runtime (Out). (e) `collate` keys compare bytewise as `CompareString` does with the same options (measured; the existing order tests hold it).
- **Neighbors.** A write that names only non-list ids (an association): the filtered reads return nothing for them, and removing absent ids changes nothing. A write naming an Event id: the Persons read returns nothing for it, the Events read its row. A note (`handleScopes` only): no read, Updated patched (AC-1.8). A label edit: whole reloads, no partial (AC-1.7; `apply` skips a `.run` for a key it revalidates). A write while the list's first load is in flight: `apply` restarts the load, as today for `.merged`.
- **Removed inputs.** A deleted handle: its id is in `Handles` (the `canonical_entities` row), Go returns nothing, the row goes (AC-1.3). A merged-away handle: `Handles` names it, Go lists only unmerged rows, the row goes; the survivor is in `Handles` and is re-read. A row whose title changes moves to its new place (AC-1.2).
- **Real data.** None — no table-driven rule.
- **Untrusted size.** `entity_ids` comes from the app's own effects; `parseIDs` refuses a malformed id. The read composes at most the given ids; the whole list bounds its cost. Two merges for the same id from two quick writes land in the order their reads ran, since the engine serves calls first in, first out (as `.merged` today).

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/conclusionsummaries` (`order.go`) | `ListKey` *(new)* with `Less`; `titleListKey` *(new)*; `SortByTitle` sorts by it; `titleKey`, `titleKeyLess` go; `sortPersons`, `sortPlaces` set `SortKey` then sort by it. `import "bytes"` |
| `core/database/conclusionsummaries` (`compose.go`) | `dateKey.listKey` *(new)*; `sortByDateKey` sorts by it; `dateKeyLess` goes; `sortEvents` sets `SortKey` then sorts by it; `fillUpdated` *(new)*; `ListPersons`, `ListEvents`, `ListPlaces` use it; `ListPersonsOf`, `ListEventsOf`, `ListPlacesOf` *(new)* |
| `core/database/conclusionsummaries` (`conclusionsummaries.go`) | `SortKey ListKey` on the three summary types |

```go
// ListKey is a row's place in a list's order: rows with Last false first,
// then Primary bytewise, then Ref bytewise. Every list order in this package
// sorts by it, and the list reads send it, so the app can place a re-read row.
type ListKey struct {
	Last    bool
	Primary []byte
	Ref     string
}

// ListPersonsOf returns the list rows of the given Persons as ListPersons
// gives them; unknown, merged and non-Person ids are absent. No ids reads nothing.
func ListPersonsOf(c *database.Catalog, ids [][]byte) ([]PersonSummary, error)
```

### FFI

`api/proto/engine.proto`: `entity_ids = 2` on `ListPersonSummariesRequest`, `ListEventSummariesRequest`, `ListPlaceSummariesRequest`; `ListSortKey` *(new)*; `sort_key` = 11 / 18 / 15 (D-5). Each request's comment gains the filter sentence. Handlers in `api/ffi/handlers/conclusion_summaries.go`; `listSortKeyProto(k conclusionsummaries.ListKey) *engine.ListSortKey` *(new)*. Regenerate with `./scripts/generate-proto.sh`.

### macOS

No view changes. Session layer:

```swift
struct CatalogListSortKey: Sendable, Equatable, Comparable {
    var last = false
    var primary = Data()
    var ref = ""
}

protocol CatalogListRow: CatalogLastUpdatedRow, Identifiable where ID == String {
    var sortKey: CatalogListSortKey { get }
}

static func mergedRows<Row: CatalogListRow>(
    _: Row.Type,
    follows: CatalogQueryFollows,
    read: @escaping @MainActor @Sendable (WorkspaceSession, CatalogQueryKey, [String]) async throws -> [Row]
) -> CatalogQueryRefresh
```

`CatalogLastUpdatedRow` stays as it is (it does not require `Identifiable`; `CatalogListRow` adds it). States: an empty list merges returned rows in; a failed re-read reloads the list (AC-1.6). Accessibility: unchanged.

### Strings

None — no user-facing copy.

## 7. Steps

**STEP-1 — One key for list order (Go, no behavior change)**
Files: `core/database/conclusionsummaries/order.go`, `compose.go`, `conclusionsummaries.go`, `conclusionsummaries_test.go`.
Do: D-1, D-2, D-3. Add T-1 and T-2.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/conclusionsummaries/ ./core/database/persondetail/ ./core/database/promotealign/` passes with every existing order test unchanged; `rg -n "titleKeyLess|dateKeyLess|titleKey\{" core` finds nothing.

**STEP-2 — The list rows of given ids (Go)**
Files: `core/database/conclusionsummaries/compose.go`, `conclusionsummaries_test.go`.
Do: D-4. Add T-3 – T-5.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/conclusionsummaries/` passes; `TestListSummariesCarryUpdated` unchanged.

**STEP-3 — The filter and the key on the wire**
Files: `api/proto/engine.proto`, generated `api/proto/engine/engine.pb.go` and `macos/App/Platform/Generated/engine.pb.swift`, `api/ffi/handlers/conclusion_summaries.go`, `conclusion_summaries_test.go`. Skill: `add-ffi-handler`.
Do: D-5; `./scripts/generate-proto.sh`. Add T-6 – T-8.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/...` passes.

**STEP-4 — Merge equals reload on the large fixture**
Files: `core/database/promotealign/listmerge_test.go` *(new)*.
Do: T-9 and `BenchmarkListRowsOfWrite` (D-10). The test's merge helper is generic over the three row types: drop the touched ids, insert each returned row by `SortKey.Less`, then compare with `reflect.DeepEqual` against the full list read after the write.
Check: `CGO_ENABLED=1 go test -tags fts5 -run TestListMergeMatchesReload ./core/database/promotealign/` passes; `CGO_ENABLED=1 go test -tags fts5 -run '^$' -bench BenchmarkListRowsOfWrite -benchtime 3x ./core/database/promotealign/` prints figures at 4,000 and 16,000 (into the ship log).

**STEP-5 — Rows carry the key; the store takes a filter (Swift)**
Files: `macos/App/Platform/GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift`, `macos/ProvenenciaTests/OnboardingModelTests.swift` (`ThrowingStore`), `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift` (the three `load` calls pass `entityIDs: nil`).
Do: D-6, D-11.
Check: `xcodebuild build` succeeds with no new warning; `WorkspaceSessionTests` and `CatalogQueryRegistryTests` still pass.

**STEP-6 — Lists merge the touched rows (Swift)**
Files: `macos/App/Features/Workspace/Session/CatalogLastUpdated.swift`, `WorkspaceSession.swift`, `CatalogQueryRegistry.swift`. Skill: `add-workspace-place`.
Do: D-7, D-8, D-9.
Check: the `.evidenceGraphsList` and `.evidenceGraphProgress` tests (`graphListMergesOneSourcesReRead`, `graphListMergeSplicesTheIndex`, `graphListPartialReReadSetsFetching`, `graphListPartialReReadFailureReloadsTheList`) pass unchanged.

**STEP-7 — Swift tests**
Files: `macos/ProvenenciaTests/CatalogListMergeTests.swift` *(new)*, `WorkspaceSessionTests.swift`, `CatalogQueryRegistryTests.swift`. Skill: `add-swift-test`.
Do: T-10 – T-16; rewrite `hiddenListsGoStaleVisibleListReloads` as T-12, `applyPromoteMarksHiddenPersonsListStale` as T-13, and update the tests §4 names that pin `.markStale` or the lists' follows (T-15, T-16).
Check: `xcodebuild test` (as `scripts/check-pr.sh` runs it) passes with no Swift warning.

**STEP-8 — Docs**
Files: `docs/macos-client-patterns.md` (rule 2's last sentence, line 90's list of `.markStale` keys, "Conclusion keys" lists line), `.agents/skills/add-workspace-place/SKILL.md` (Refresh: `mergedRows` beside `merged`; Mark stale: the lists leave the examples), `docs/catalog-caches.md` (Swift "Per-view query results": lists merge touched rows), `docs/deployment-plan/spike-16/cache-architecture.md` (the "Lists merge" line, past tense with the PR), `deployment-plan.md` (map row), `completed.md`, this plan (status, Landed note).
Do: per the Definition of done. Rule 2 becomes: "A save made away from a list re-reads only the rows it touched in each warmed list; no list reloads whole unless a label changed."
Check: links resolve; `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-26-lists-merge-touched-rows.md` passes.

Commits: one per behavior, as D-12. The subject is one full imperative sentence that says what changed for the researcher, ending in a period ("Re-read only the rows a write touched in the Persons, Events and Places lists."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `conclusionsummaries_test.go` `TestListKeyLess` *(new)* | Table: `{Last:false}` < `{Last:true}`; `Primary` `[0x01]` < `[0x01,0x00]` < `[0x02]`; equal Primary, `Ref` `"per-a"` < `"per-b"`; equal keys → not less either way | D-1 |
| T-2 | Go | same file `TestListKeysFollowListOrder` *(new)* | Places titled `Montréal` (`PLC-B`), `Montreal` (`PLC-A`), `MONTREAL` (`PLC-C`), `Zürich`, one untitled; events dated 1850 / BEF 1850 / AFT 1850 and two undated → each list's rows are in strictly increasing `SortKey.Less` order, the untitled and undated rows have `Last`, and the three Montreal rows order `PLC-A`, `PLC-B`, `PLC-C` | AC-2.2, AC-2.3, D-2 |
| T-3 | Go | same file `TestListPersonsOf` *(new)* | ids: a Person, an Event, a merged Person, an unknown id → one row, equal (`reflect.DeepEqual`) to that Person's row in `ListPersons`, `Updated` and `SortKey` included; `nil` ids → no rows, no error | AC-2.4, D-4 |
| T-4 | Go | same file `TestListEventsOf` *(new)* | an Event and a Person id → the Event's row as in `ListEvents` | D-4 |
| T-5 | Go | same file `TestListPlacesOf` *(new)* | a Place and an Event id → the Place's row as in `ListPlaces` | D-4 |
| T-6 | Go | `api/ffi/handlers/conclusion_summaries_test.go` `TestListPersonSummaries` (new cases) | "filtered to one person": `entity_ids` = the handle id and an unknown id → one summary, `sort_key` set and equal to its key in the unfiltered response; "malformed id" → error; the existing "lists every row" case asserts every row has a `sort_key` and the keys increase | AC-2.4, AC-2.5, D-5 |
| T-7 | Go | same file `TestListEventSummaries` (new case) | filtered to one event → one summary with `sort_key` | D-5 |
| T-8 | Go | same file `TestListPlaceSummaries` (new case) | filtered to one place → one summary with `sort_key` | D-5 |
| T-9 | Go | `core/database/promotealign/listmerge_test.go` `TestListMergeMatchesReload` *(new)* | Large fixture at 4,000 persons; writes in order through `writes.Run`: promote a new person (Other Source); promote a birth at the city with a person participating (one-place Source); cite a second name on the filed person; file a `part_of` from the city to a new place; cite a second toponym on the city. For each: the three filtered reads of `Handles ∪ SummaryDeps` merged into the previous full lists equal the full lists after the write, in order, `Updated` included; the filtered reads together take under `ceilingListRowsOfWrite` | AC-2.1, D-10, Scale |
| T-10 | Swift | `macos/ProvenenciaTests/CatalogListMergeTests.swift` *(new)* `mergeSortedPlacesRowsByKey` | rows `a`(1) `b`(3) `c`(5), keys by `primary`; merge `[b'(6)]` replacing `["b"]` → `a`, `c`, `b'`; merge `[d(2)]` replacing `["d"]` → `a`, `d`, `b`, `c`; merge `[]` replacing `["b"]` → `a`, `c`; merge `[e(4)]` replacing `[]` → `a`, `b`, `e`, `c` (an unasked row is not duplicated when present: merge `[a'(1)]` replacing `[]` → one `a'`); empty list, merge `[x]` → `[x]`; `last` keys after the rest | AC-1.2 – AC-1.4, D-8 |
| T-11 | Swift | `WorkspaceSessionTests.swift` `visibleListsReReadOnlyTouchedRows` *(new)* | `seededPersonSummaries` `p1`(1), `p2`(2), `p3`(3) by `primary`; Persons list on screen and loaded; the seed's `p2` key becomes 4; `apply(handles: ["p2"], summaryHandles: ["e9"])`; `settleWrites()` → `listPersonSummariesEntityIDs == [nil, ["p2", "e9"]]`, `listPersonSummariesCalls == 2`, rows `p1`, `p3`, `p2`, `isFetching` was true while it ran | AC-1.1, AC-1.2 |
| T-12 | Swift | `WorkspaceSessionTests.swift` `hiddenListsMergeTouchedRows` (replaces `hiddenListsGoStaleVisibleListReloads`) | All three lists warmed and hidden with seeded rows; a write `handles: ["e1"]` whose FakeStore rows are gone → each store records `[nil, ["e1"]]` for its kind, each list drops `e1`, none `isStale`; `query` of each starts no load | AC-1.3, AC-1.5 |
| T-13 | Swift | `WorkspaceSessionTests.swift` `applyPromoteMergesThePromotedPerson` (replaces `applyPromoteMarksHiddenPersonsListStale`) | Hidden, loaded, empty Persons list; `seedPromotion`; `apply(handles: [promoted id], evidenceGraphs: ["g-1"])`; `settleWrites()` → the list holds the promoted row, no whole reload | AC-1.4, AC-1.5 |
| T-14 | Swift | `WorkspaceSessionTests.swift` `listReReadFailureReloadsTheList` *(new)* | Visible Persons list; FakeStore filtered read throws (`listPersonSummariesError` *(new)* set after the first load, thrown only for a filtered call) → the list reloads whole (`listPersonSummariesEntityIDs` ends `[…, ["p2"], nil]`) | AC-1.6 |
| T-15 | Swift | `WorkspaceSessionTests.swift` `labelEditReloadsListsWhole` *(new)* | Visible Persons list; `apply(handles: ["p2"], lists: [.propertyVocabulary])` → one whole read, no filtered read | AC-1.7 |
| T-16 | Swift | `CatalogQueryRegistryTests.swift` `invalidationsComeFromRegistrySpecs`, `handleScopesInvalidateNothing`, the `hiddenPolicy` lines | The lists' follows `[.touchedHandles, .list(.propertyVocabulary)]` unchanged, their first refresh is a `.run`; `hiddenPolicy(.personsList…) == .revalidate` (three lists); `revalidatedKeys(handles: ["e1"])` names `e1`'s detail and no list; `handleScopes` only → nothing | AC-1.8, D-9 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: the conclusionsummaries order tests (STEP-1), `TestListPersonsQueryCountIsConstant` (STEP-2 must not add a query per row), `sourceWriteEffectsPatchSourcesAndLeaveListsAlone` (its AC-2.12 half expects a stale list: update it to expect a merge, `listsAreQuiet()` after `settleWrites()`), `applyLeavingPageLoadsTheNextListOnce`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none expected)
- [ ] Sweep: `titleKeyLess`, `dateKeyLess`, `listPersonSummaries(projectDir:)` (old signature) `rg`'d across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none)
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New (no UI)
- [ ] Version bump: patch (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] BenchmarkListRowsOfWrite figures at 4,000 and 16,000 in the ship log, with today's whole-list figures beside them
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (no brief)
- [ ] Domain doc updated: macos-client-patterns.md rule 2 and "Conclusion keys"; add-workspace-place Refresh and Mark stale; catalog-caches.md; cache-architecture.md
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Open a project with at least a few hundred persons. Open Persons, scroll to the middle and note two rows.
2. Open a Person, add a name Observation in one of its Evidence graphs that sorts the person elsewhere, and go Back to Persons: the person sits at its new place, the rest of the list and the scroll position are as before, and no "Refreshing" state shows.
3. With Events open in another place (visit Events, then a Source), promote a new event from that Source; go to Events: the event is in date order, with no reload.
4. Rename a Property label in the Properties workspace; go to Persons: the list reloads once (expected).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A write changes a row it does not name, so a merged list drifts from a full reload | T-9 on five writes; Go's display cache already relies on the same set |
| Collation keys order differently from `CompareString` for some title | The existing order tests, T-2, and the 20,115-title measurement; Stop below |
| Hidden lists now pay a store call per write | Measured under 1.3 ms for the writes above; bounded by the whole list for a crafted write |

**Stop and report if:**

- An existing order test in `conclusionsummaries` or `persondetail` fails after STEP-1 (a collation key ordered differently from `CompareString`, or the date encoding from `dateKeyLess`).
- T-9 finds an untouched row that changed after a write: the touched set is not exact for that write (name the write and the row), which is S14-42's to fix, not this PR's.
- `TestListPersonsQueryCountIsConstant` (or the Event and Place twins) fails after STEP-2.
- The filtered reads exceed `ceilingListRowsOfWrite` at 4,000 persons, or `BenchmarkListRowsOfWrite` shows a filtered read at 16,000 slower than 10% of the whole list.
- A runtime write is found that changes the name format profile, or any write that moves every row's key without reporting `property_vocabulary`.

## 12. Open questions

None.

## 13. PR

**Title:** S16-26 — Conclusion lists merge the rows a write touched
**Body:** objective in one sentence; what shipped against each US; AC evidence; the benchmark figures; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-26-lists-merge-touched-rows.md`.
