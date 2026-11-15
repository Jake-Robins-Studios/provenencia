# S16-26 — Conclusion lists merge the rows a write touched

**Status:** Landed in [#851](https://github.com/mendahu/provenencia/pull/851) (2026-11-15)
**Spike / slice:** Spike 16 · Slice 2e — The app's cache
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: the three lists draw the same rows in the same order; only how a write reaches them changes)
**Board:** —
**Depends on:** S14-42 (Spike 14, landed [#748](https://github.com/mendahu/provenencia/pull/748): the exact touched set), S16-25 (landed [#847](https://github.com/mendahu/provenencia/pull/847): keys as values, `CatalogQueryFollows: Hashable`)
**Blocks:** —
**Branch:** `s16-26-lists-merge-touched-rows`
**Version bump:** patch — a write re-reads only its rows of the Persons, Events and Places lists, and the list RPCs gain an optional id filter and a list key old clients ignore; nothing new on screen ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/macos-client.mdc`, `.cursor/rules/swift-tests.mdc`, `.cursor/rules/go-tests.mdc`, `.cursor/rules/catalog-queries.mdc`
**Context:** [design § Swift](../cache-architecture.md#swift) ("Lists merge the touched rows"); [`docs/macos-client-patterns.md`](../../../macos-client-patterns.md) rule 2 and "Conclusion keys"; working rules: "(Batch 2) The point of this batch is simpler code", "(Batch 2) Swift caches one value per view, follows its inputs and shows it stale while refreshing", "(Batch 2) Orders are defined and results do not move", "(Batch 2) Measure growth"; goal bar 12 ("a write updates only the rows it touched in the Persons, Events and Places lists")
**Planned:** 2026-11-15 against `main` @ `3667125`
**Review:** [`S16-26-lists-merge-touched-rows.review.md`](S16-26-lists-merge-touched-rows.review.md) — round 1: Fits with changes / Not ready; round 2: Fits with changes / Ready with changes; every finding Fixed

**Landed.** Differences from the plan: D-14's second commit landed as two (STEP-2, then STEP-3), and STEP-5 to STEP-7 landed in one commit with their tests, because the store signature change breaks every Swift test until they are rewritten; the docs commit also carries the version bump (0.15.4). `TestListKeysFollowListOrder` and `TestListKeysFile` reach the key functions through `export_test.go` (`SortEvents`, `PlaceListKey`, `EventListKey`, `TitleListKey`, `DateListKey`); `list_keys.json` also holds each row's input (`title`, `year`, `side`) so Go's test can regenerate it. Beyond T-10, `mergeSortedKeepsFreshRowsInKeyOrder` pins several fresh rows and an equal key. T-14's hidden half runs on a second session in the same test. `BenchmarkListRowsOfWrite` reports the first read after each write (not the best of three), whole lists at 4,000 and 16,000 persons beside each write's filtered reads; the figures are in the PR description. The Go filtered reads were at most 0.86 ms at 4,000 persons and 0.78 ms at 16,000. F-6 (user, 2026-11-15): the lists hold an id→key index (`CatalogListRows`); supersedes D-8's one-pass merge, which stays as the fallback past `indexedMergeLimit`.

**Tools.** STEP-1 to STEP-3 need only Go. STEP-4 needs `protoc`, `protoc-gen-go` and `protoc-gen-swift` (`scripts/generate-proto.sh`). STEP-5 to STEP-7 and the Xcode half of `scripts/check-pr.sh` need Xcode. On a machine without them, do STEP-1 to STEP-3 and the Go checks, then stop and report which tool the next step needs.

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

After a write, the Persons, Events and Places lists re-read only the rows the write touched and put each where it belongs, instead of reloading the whole list. Today a write that names any handle reloads a visible list whole (115–137 ms for the Persons list at 16,000 persons, warm) and marks a hidden one stale, so the next visit reloads it whole too. Afterwards each warmed list, on screen or not, asks Go for the rows of the write's touched ids (at most 1.3 ms for the writes measured on the 4,000-person fixture), drops those ids from its rows, and inserts each returned row by a list key Go sends with it. Back to a list shows current rows with no reload.

Go owns list order. Today it sorts with `collate.CompareString` and a date comparator; afterwards every order in `conclusionsummaries` sorts by one key type, `ListKey` (a title's collation key or a date's order key, then the ref), and the list RPCs send that key. The app compares keys and never computes one.

A partial re-read (`.run` refresh) now runs for any warmed key that holds a current value, on screen or not (user, 2026-11-15). The hidden policy (`whenHidden`) keeps deciding only what a whole reload does: the three lists stay `.markStale`, so a label edit made away from them marks them stale instead of reloading three lists at once. The Evidence graph list, the one other `.markStale` key with a partial re-read, merges while hidden too.

**Why now.** S14-42 made the touched set exact (`WriteEffects.handles` plus `summary_handles`): Go's own summary cache already drops exactly those rows (`graphcache.dropCommittedDisplays`). S16-25 settled the key and refresh shapes this PR declares on. Bar 12's last clause is the only one of its kind left.

**What stays.** Every list draws the same rows in the same order. A Property, term or subject type label edit (`property_vocabulary`) still reloads a visible list whole and marks a hidden one stale. The `lastUpdated` patch keeps moving a row's Updated cell for a write that names its scope and touches no summary (a note). The sidebar recount is unchanged. The per-entity keys keep S16-25's follows. Search hits, the detail reads and the Person page sections do not read the list key.

## 2. User stories

**US-1.** As a researcher, when I make a change that alters a few people, events or places, the lists show the new rows in the right places without reloading every row.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | The Persons list on screen holds rows `p1`, `p2`, `p3` (keys in that order); a write reports `handles: ["p2"]`, `summaryHandles: ["e9"]` | The store is asked once, for `["p2", "e9"]`; the whole read is not called again (`listPersonSummariesEntityIDs == [nil, ["p2", "e9"]]`) |
| AC-1.2 | AC-1.1, and Go returns `p2` with a key after `p3`'s | The list reads `p1`, `p3`, `p2` |
| AC-1.3 | AC-1.1, and Go returns nothing for `p2` (deleted, merged away, or not a Person) | The list reads `p1`, `p3` |
| AC-1.4 | The list holds `p1`, `p3`; a write reports `handles: ["p2"]` and Go returns `p2` with a key between them | The list reads `p1`, `p2`, `p3` |
| AC-1.5 | The Persons, Events and Places lists are all loaded and hidden; a write reports `handles: ["e1"]` | Each list is asked for `["e1"]` and merges; none is marked stale; a `query` of one afterwards starts no load |
| AC-1.6 | A list's re-read throws | The list goes through its hidden policy: reloads whole when on screen, is marked stale when hidden (as `.merged` does today) |
| AC-1.7 | A write reports `lists: [property_vocabulary]` and `handles: ["p2"]` | A visible list reloads whole once with no partial read; a hidden list is marked stale with no partial read |
| AC-1.8 | A write reports only `handleScopes: ["p1"]` with a newer activity (a note) | No read; `p1`'s Updated cell moves (unchanged behavior) |
| AC-1.9 | A hidden, loaded Evidence graph list; a graph write reports `reads: [evidence_graphs: ["S"]]` | The list re-reads Source `S` and merges it; it is not stale (today: stale, no read) |

**US-2.** As a contributor, list order has one owner: Go sorts every list by the key it sends, so a merged list and a full reload cannot disagree.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | On the large fixture at 4,000 persons, each of the five writes of T-9 | The full lists read just before the write, with the write's touched rows merged in by `ListKey`, equal the full lists read after it, row for row and in order, `Updated` included |
| AC-2.2 | Places titled `Montréal` (ref `PLC-B`), `Montreal` (`PLC-A`), `MONTREAL` (`PLC-C`), `Zürich` (`PLC-D`), and an untitled `PLC-0` | Order `PLC-A`, `PLC-B`, `PLC-C`, `PLC-D`, `PLC-0`: the three Montreal titles collate equal and break by ref, the untitled row is last. `TestListOrderIsByShownTitle`, `TestPlaceSort`, `TestPersonListOrder` and `TestListPersonsSortIgnoresHonorifics` pass unchanged |
| AC-2.3 | Events dated before 1850, in 1850, after 1850 (`datevaluetest.Before`, `YMD`, `After`), and two undated (`EVT-A`, `EVT-B`) | The order `TestEventOrderAtKnownEnd` and `TestListEvents` pin today; the undated rows last, by ref |
| AC-2.4 | `ListPersonSummaries` with `entity_ids` of a Person, a Place and an unknown id | One row: the Person's, with its `list_key` and `updated_revision` as in the whole list |
| AC-2.5 | `ListPersonSummaries` with a malformed id in `entity_ids` | The handler's bad-id error (`parseIDs`) |
| AC-2.6 | The keys in `core/database/conclusionsummaries/testdata/list_keys.json` *(new)* (Go's keys for AC-2.2's titles and AC-2.3's dates, in Go order) | Swift's `CatalogListKey.<` orders them as Go does |

## 3. Scope

| In | Covered by |
| --- | --- |
| Go: `conclusionsummaries.ListKey` *(new)*; `sortByKey` takes a `ListKey`; `SortByTitle`, `sortByDateKey` and the three list sorts sort by it through one key function per kind; `titleKey`, `titleKeyLess`, `dateKeyLess` go | STEP-1, AC-2.2, AC-2.3, AC-2.6 |
| Go: list rows carry `ListKey`, filled only by the list reads, as `Updated` is; `ListPersonsOf`, `ListEventsOf`, `ListPlacesOf` *(new)* on the `ByIDs` reads; one finisher per kind fills both fields for the whole list and the rows of given ids | STEP-2, AC-2.4 |
| Go: the equivalence test on the large fixture and a benchmark of the per-write read at 4,000 and 16,000 persons | STEP-3, AC-2.1 |
| FFI: `entity_ids` on the three list requests; `ListKey` message *(new)* and a `list_key` field on the three summary messages, filled by the list handlers | STEP-4, AC-2.4, AC-2.5 |
| Swift: `CatalogListKey` *(new)* on the three summary types; `GenealogyStore` list methods take `entityIDs:`; GoStore and FakeStore follow | STEP-5, AC-1.1, AC-2.6 |
| Swift: `refreshCached` reads a batch; `CatalogQueryRefresh.mergedRows` *(new)*; `CatalogListRow` *(new)* and `[Row].mergeSorted(_:replacing:)` *(new)*; `apply` runs a `.run` refresh for any warmed key with a current value; the three list descriptors merge on `.touchedHandles`; `applyHiddenPolicyOnAny` refuses a row slot | STEP-6, AC-1.1 – AC-1.9 |
| Swift tests | STEP-7, T-10 – T-21 |
| Docs: `macos-client-patterns.md`, `add-workspace-place`, `swift-tests.mdc`, `catalog-caches.md`, the design, the map | STEP-8 |

| Out | Home |
| --- | --- |
| The lists' failure notice | [`docs/ideas/person-page-followups.md`](../../../ideas/person-page-followups.md) (map row's Not this PR) |
| A label edit merging instead of reloading the lists | not planned (D-9: a catalog-wide change, every row may move) |
| Sorting by another column in the app (birth, updated) | not planned: the lists show rows as given |
| The Sources list adopting `mergedRows` | not planned: it follows `sourceScopes` with in-place patches and `.sourceRow()`, and the app orders it |
| Cancelling an in-flight merge when a later write names the same ids | not planned: `.merged` has the same order today, and the engine serves calls first in, first out (§6 Edges) |
| A name format write | not planned: no runtime write changes the profile (`name_format_profiles` reports no effects; `WorkspaceSession.loadNameFormat` runs once at open) |

## 4. Current state

Verified at `3667125`.

| Area | Where | Today |
| --- | --- | --- |
| Go order | `core/database/conclusionsummaries/order.go` `titleCollator`, `SortByTitle`, `titleKey`, `titleKeyLess`, `sortByKey[T, K]` (with a `less` parameter), `sortByDateKey`, `sortPersons`, `sortPlaces`, `personSortKey`, `placeTitle` | Title order compares with `titleCollator.CompareString` (root, ignore case and diacritics), untitled last, ties by lowercased ref. `SortByTitle` also orders the claims' Sources and graphs (`core/database/persondetail/claims.go`) and unlisted participants (`participants.go`). `sortByKey`'s only callers are `SortByTitle` and `sortByDateKey` |
| Go date order | `core/database/conclusionsummaries/compose.go` `dateKey` (`at`, `ok`, `ref` lowercased by `dateKeyOf` and `withRef`), `sortEvents`, `dateKeyLess`, `eventKeyOf`; `sortByDateKey`'s callers `lifeFacts` (compose.go, life picks), `sortEvents`, `SortByBirth` (order.go); `core/valuecompare/dateorder.go` `DateKey.Compare`, `DateKey.Int64` | Dated first, by `DateKey` (day, then side), then ref. `Int64` "is k as one integer whose order is Compare's" |
| Go lists | same file, `ListPersons`, `ListEvents`, `ListPlaces`, `handleActivity` (doc: "The lists fill it onto the rows they return, after composing; the finished rows never hold it"), `PersonsByIDs`, `EventsByIDs`, `PlacesByIDs` (callers: `conclusiondetails`, `api/ffi/handlers/conclusion_detail.go`, `api/ffi/handlers/promote_align.go`, `api/ffi/handlers/search_catalog.go`), `RowsForSearch` (`core/database/searchindex/handles.go`) | The lists compose every unmerged row of the kind (display cache first), sort, then fill `Updated` in a loop each repeats. `XByIDs` composes and sorts the given ids behind a `UniqueBlobIDs` guard (unknown, merged, other kind absent) and leaves `Updated` empty |
| Go summary rows | `core/database/conclusionsummaries/conclusionsummaries.go` `PersonSummary`, `EventSummary`, `PlaceSummary` | No order key field |
| Display check | `core/database/conclusionsummaries/display_register.go` `checkDisplay` (registered with `graphcache.SetDisplayCheck`; run by `graphcache.Graph.Verify` when `PROVENENCIA_GRAPH_VERIFY=1`) | Recomposes each stored row through `persons` / `events` / `places` and compares with `reflect.DeepEqual` (Places after clearing `Parents`). A field the sort writes onto the row would fail it for every stored row |
| Display drop | `core/database/graphcache/commit.go` `dropCommittedDisplays`; `core/writes/run.go` (`set.SummaryDeps = deps`) | A commit drops the stored rows of its roots and `SummaryDeps`; the full list reads every other row from the store |
| FFI | `api/proto/engine.proto` `ListPersonSummariesRequest`, `ListEventSummariesRequest`, `ListPlaceSummariesRequest` (field 1 only), `PersonSummary` (last field 10), `EventSummary` (17), `PlaceSummary` (14); `api/ffi/handlers/conclusion_summaries.go` `ListPersonSummaries`, `ListEventSummaries`, `ListPlaceSummaries`, `personSummaryProto`, `eventSummaryProto`, `placeSummaryProto`; `api/ffi/handlers/catalog.go` `parseIDs` | Each handler lists every row. The summary mappers are shared with the detail and search reads (`conclusionSummaryProto`). No proto type is named `ListKey` |
| Parity precedent | `core/database/sourcemetadata/testdata/draft_board_scenarios.json`, read by `core/database/sourcemetadata/sourcemetadata_test.go` (`draftBoardFile`) and `macos/ProvenenciaTests/MetadataDraftHostParityTests.swift` (`load()` via `#filePath`) | One JSON file both languages test against |
| Effects (Swift) | `macos/App/Features/Workspace/Session/CatalogMutation.swift` `CatalogWriteEffects.touchedHandles` | `handles + summaryHandles`, deduplicated, empty ids dropped |
| Refresh constructors | `macos/App/Features/Workspace/Session/CatalogLastUpdated.swift` `CatalogQueryRefresh.merged(follows:as:read:merge:afterMerge:)`, `fileprivate init(follows:run:)` ("`merged` is the only way to declare one"), `applyHiddenPolicyOnAny(follows:)` (doc: "the one constructor for a catalog-wide slot", no check), `requireRowIDs` | `merged` calls `requireRowIDs`. `applyHiddenPolicyOnAny`'s only row-slot callers are the three list arms |
| Session | `macos/App/Features/Workspace/Session/WorkspaceSession.swift` `refreshCached(_:as:ids:read:merge:afterMerge:)` (doc: "Called only by `CatalogQueryRefresh.merged`"), `apply(_:_:)` (doc: "gated per key: one runs only for a key that would revalidate (visible, or `whenHidden: .revalidate`)…"; code: `if effectivePolicy(for: key) == .revalidate, !handle.isStale, handle.hasValue`), `apply(_:_:leavingPage:)` | `refreshCached` calls `read` once per id, in order, then merges every part in one `patchCached`; a throw applies the hidden policy. A `.run` refresh skips a hidden `.markStale` key: it is marked stale instead |
| List descriptors | `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift` `.personsList`, `.eventsList`, `.placesList` arms; `CatalogQueryDescriptor.whenHidden` doc | `whenHidden: .markStale`; patches `[.lastUpdated(Row.self, follows: .handle)]`; refreshes `[.applyHiddenPolicyOnAny(follows: .touchedHandles), .followsPropertyLabels]`; `load` calls `store.list…Summaries(projectDir:)` |
| Merge precedent | same file, `.evidenceGraphProgress` (`whenHidden` default `.revalidate`) and `.evidenceGraphsList` (`.markStale`) arms | Both declare `.merged`: one store call per id |
| Row protocols | `CatalogLastUpdated.swift` `CatalogLastUpdatedRow`, `CatalogPageValue`; `CatalogQueryPatch.row<Row: Identifiable & Sendable> where Row.ID == String` | One small protocol per shared field |
| Swift rows | `macos/App/Platform/GenealogyStore.swift` `CatalogPersonSummary`, `CatalogEventSummary`, `CatalogPlaceSummary`; requirements `listPersonSummaries(projectDir:)`, `listEventSummaries(projectDir:)`, `listPlaceSummaries(projectDir:)` | No key. Three conformers: `GoStore`, `FakeStore`, `ThrowingStore` (`macos/ProvenenciaTests/OnboardingModelTests.swift`) |
| GoStore | `macos/App/Platform/GoStore.swift` `listPersonSummaries`, `listEventSummaries`, `listPlaceSummaries`, `mapPersonSummary`, `mapEventSummary`, `mapPlaceSummary` | The mappers are shared with the detail and search reads |
| FakeStore | `macos/App/Platform/FakeStore.swift` `listPersonSummaries` (counts `listPersonSummariesCalls`; `personSummaries()` sorts named rows by lowercased form, then by ref with `localizedCaseInsensitiveCompare`), `listEventSummaries` (`seededEventSummaries`), `listPlaceSummaries` (`seededPlaceSummaries`); `listEvidenceGraphsSourceIDs: [String?]`, `listEvidenceGraphsError` (thrown on every call) | The precedents for a filter recorder and an error hook |
| Tests (Swift) that pin today's lists | `macos/ProvenenciaTests/WorkspaceSessionTests.swift` `hiddenListsGoStaleVisibleListReloads`, `applyPromoteMarksHiddenPersonsListStale`, `applyTriggerStalesHiddenDetailPagesAndRevalidatesTheVisibleOne` (its "The list is off screen: stale" half), `effectSlotsRevalidateTheirKeys` (names the three lists), `sourceWriteEffectsPatchSourcesAndLeaveListsAlone` (its AC-2.12 half), `hiddenGraphListGoesStaleOnRead`; `macos/ProvenenciaTests/CatalogQueryRegistryTests.swift` `handleScopesInvalidateNothing` (names the three lists) | Pin the whole reload, the hidden graph list going stale, and the lists in `revalidatedKeys` |
| Tests (Swift) that stay as they are | `applyLeavingPageLoadsTheNextListOnce` (its list is invalidated, so stale, before the write: no merge, one whole read); `graphListFirstLoadInFlightGoesStaleWhenHidden` (no value yet); `PropertiesModelTests.renamingAPropertyStalesConclusionPages` (a label edit marks the hidden list stale); `CatalogQueryRegistryTests` `invalidationsComeFromRegistrySpecs` (the lists' follows `[.touchedHandles, .list(.propertyVocabulary)]`) and the `hiddenPolicy(.personsList…) == .markStale` lines | Must pass unchanged |
| Tests (Go) | `core/database/conclusionsummaries/conclusionsummaries_test.go` `TestListPersons`, `TestPersonListOrder`, `TestListPersonsSortIgnoresHonorifics`, `TestListOrderIsByShownTitle`, `TestPlaceSort`, `TestListEvents`, `TestEventOrderAtKnownEnd`, `TestSortByBirth`, `TestSortByTitleKeysOnce`, `TestListSummariesCarryUpdated`, `TestPersonsByIDs`, `TestListPersonsQueryCountIsConstant`; `api/ffi/handlers/conclusion_summaries_test.go` `TestListPersonSummaries`, `TestListEventSummaries`, `TestListPlaceSummaries`; `core/database/promotealign/perf_test.go` `newLargeFixture` (fields `other`, `otherA`, `onePlace`, `pageArt`, `citySubject`), `TestLargeSourceBudgets`; `core/database/promotealign/promotealign_test.go` `fixture` (embeds `evidencelayertest.Records`: `Person`, `Birth`, `Place`, `Participation`, `Locate`, `PlaceRel`, `Prop`) | Pin today's orders, the handlers and the fixture |

**Precedent.** `.evidenceGraphsList` (S14-11) re-reads part of itself by the ids a write names and merges it, with `FakeStore.listEvidenceGraphsSourceIDs` recording the filter and `graphListMergesOneSourcesReRead` / `graphListPartialReReadFailureReloadsTheList` testing it: copy their shape. `sources.DateSortKey` / `date_sort_key` (an order key Go computes and sends, from `DateKey.Int64`) is the precedent for a key on the wire. `draft_board_scenarios.json` is the precedent for a Go–Swift parity file. `TestLargeSourceBudgets` is the precedent for a test on the large fixture with named ceilings.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `type ListKey struct { Last bool; Primary []byte; Ref string }` *(new)* in `order.go`, with `func (k ListKey) Less(o ListKey) bool`: a key with `Last` false first; then `bytes.Compare(k.Primary, o.Primary)`; then `k.Ref < o.Ref`. `Ref` is always the lowercased ref. Title keys: `titleListKey(title, ref string) ListKey` *(new)*: `title = strings.TrimSpace(title)`, `ref = strings.ToLower(ref)`; an empty title → `{Last: true, Ref: ref}`; else `{Primary: <copy of titleCollator.KeyFromString(&buf, title)>, Ref: ref}` with a local `var buf collate.Buffer`. Date keys: `func (k dateKey) listKey() ListKey` *(new)*: not `ok` → `{Last: true, Ref: k.ref}`; else `{Primary: 8 bytes big-endian of uint64(k.at.Int64()) ^ (1 << 63), Ref: k.ref}` (`encoding/binary`) | One comparator for every order in the package. A collation key compares bytewise as `CompareString` does with the same options, and costs less: measured over the 20,115 Person titles at 16,000 persons, the same order, key build 3.9 ms + sort 4.1 ms against 47.6 ms. `Int64` already carries `Compare`'s order, and the sign flip keeps it bytewise | Sending a position (moves on every insert); keeping `CompareString` in Go and a second encoding for the wire (two comparators that must agree); one concatenated byte string (a collation key has no separator byte that is safe) |
| D-2 | `sortByKey[T any](rows []T, key func(T) ListKey)` sorts stably by `ListKey.Less` (the `K` and `less` parameters go). `SortByTitle` passes `titleListKey(title(row), ref(row))`; `sortByDateKey` passes `key(row).listKey()`. `titleKey`, `titleKeyLess` and `dateKeyLess` go. One key function per list kind *(new)*: `personListKey(h PersonSummary, profile nameformats.Profile) ListKey` = `titleListKey(personSortKey(h, profile), h.Entity.Ref)`; `eventListKey(h EventSummary) ListKey` = `eventKeyOf(h).listKey()`; `placeListKey(h PlaceSummary) ListKey` = `titleListKey(placeTitle(h), h.Entity.Ref)`. `sortPersons`, `sortEvents` and `sortPlaces` sort by them and write nothing onto the rows | One comparator; the sort and the list key are the same function, so they cannot drift; `SortByBirth`, the life picks, the claims and the participants get the same comparator | Writing the key onto the row during the sort (review M-11: `checkDisplay` would fail for every stored row, and detail, search and Promote rows would carry a list-only value) |
| D-3 | `PersonSummary`, `EventSummary`, `PlaceSummary` gain `ListKey ListKey`, documented as `Updated` is: "the key the row's list sorts by; the list reads fill it onto the rows they return, after composing; the finished rows never hold it". No other read sets it, so `checkDisplay`, the `ByIDs` rows and the search rows are unchanged | `handleActivity`'s rule for `Updated`; Go matches Swift's D-6 (only list rows carry a key) | Clearing it in `checkDisplay` (a strip every cross-path comparison would need) |
| D-4 | `ListPersonsOf(c *database.Catalog, ids [][]byte) ([]PersonSummary, error)` *(new)* is `PersonsByIDs(c, ids)` then `finishPersonList(c, rows)`; `ListPersons` is its compose then the same finisher; Events and Places alike (`finishEventList`, `finishPlaceList`). Doc: "`PersonsByIDs` with `Updated` and `ListKey`, as `ListPersons` gives each row; no ids reads nothing". `finishPersonList(c, rows) error` *(new)* loads the profile with `nameformats.LoadFor(c.Graph())`, sets each row's `ListKey = personListKey(row, profile.Profile)` and its `Updated` from `handleActivity`; the event and place finishers set `eventListKey` / `placeListKey` and `Updated`. The three `Updated` loops go into them | The guard and compose stay once per kind (review M-3); the list fields are filled in one place per kind for both reads; the extra key build costs about 4 ms at 20,115 titles | A nil-means-all filter on `ListPersons`; a second compose call per kind; a generic fill helper over three key functions with different arguments |
| D-5 | Proto: each list request gains `repeated string entity_ids = 2;` ("When set, only these handles' rows, in list order; an unknown, merged or other-kind id is absent (S16-26). Empty lists every row"). `message ListKey { bool last = 1; bytes primary = 2; string ref = 3; }` *(new)* ("A row's place in its list (`conclusionsummaries.ListKey`): rows with `last` false first, then `primary` bytewise, then `ref` bytewise. The app inserts a re-read row where its key falls"). `PersonSummary.list_key = 11`, `EventSummary.list_key = 18`, `PlaceSummary.list_key = 15`, each "Filled on the List*Summaries responses only", as `updated_revision` is. The handlers parse `entity_ids` with `parseIDs`; any id given → `ListXOf`, else `ListX`; then `p.ListKey = listKeyProto(h.ListKey)` *(new)* after the shared mapper. Regenerate with `./scripts/generate-proto.sh` | Additive and old clients ignore it; one request shape for both reads; the shared mappers stay list-agnostic; one name (`ListKey`) in Go, proto and Swift (review M-5) | A new RPC per kind; a wrapper message for the filter (Swift never sends an empty filter, D-6); "sort key" (already the name-order string `personSortKey` and `nameformats.Profile.SortKey`) |
| D-6 | Swift: `struct CatalogListKey: Sendable, Equatable, Comparable { var last = false; var primary = Data(); var ref = "" }` *(new)* in `GenealogyStore.swift` beside the summaries; `<` compares `last` (false first), then `primary.lexicographicallyPrecedes(_:)`, then `ref.utf8.lexicographicallyPrecedes(_:)`. `var listKey = CatalogListKey()` on the three summary types. The three requirements become `listPersonSummaries(projectDir: String, entityIDs: [String]?)` (Event, Place alike): nil lists every row. `GoStore` returns `[]` for an empty array without calling the engine, sets `entityIds` otherwise, and maps `list_key` in the three list functions only (`mapListKey` *(new)*, private static). `ThrowingStore` takes the new signatures | Go's comparison; `listEvidenceGraphs(projectDir:sourceID:)`'s nil-means-all precedent; an empty filter never reaches the engine | A default argument on the protocol; mapping the key in the shared mappers (detail and hits would carry a meaningless key) |
| D-7 | `refreshCached(_:as:ids:read:merge:afterMerge:)` reads a batch: `read: @MainActor ([String]) async throws -> Part` called once with `ids`, `merge: @MainActor (inout Value, Part) -> Void`, `afterMerge: (@MainActor (Part, _ previousRevision: Int) -> Void)?`. `CatalogQueryRefresh.merged` keeps its signature and passes `[(String, Part)]`: its read loops the ids in order, its merge folds each in order, its `afterMerge` gets `Dictionary(parts, uniquingKeysWith: { _, last in last })`. `static func mergedRows<Row: CatalogListRow>(_: Row.Type, follows: CatalogQueryFollows, read: @escaping @MainActor @Sendable (WorkspaceSession, CatalogQueryKey, [String]) async throws -> [Row]) -> CatalogQueryRefresh` *(new)* calls `requireRowIDs(follows)`, then declares a run that calls `session.refreshCached(key, as: [Row].self, ids: ids, read: { try await read(session, key, $0) }, merge: { rows, fresh in rows.mergeSorted(fresh, replacing: ids) })`. The `.run` init's doc: "`merged` and `mergedRows` are the only ways to declare one"; `refreshCached`'s: "Called only by `CatalogQueryRefresh.merged` and `.mergedRows`" | One store call per write per list (a write naming 20,000 handles would otherwise be 20,000 FFI calls); one merge core with two declarations; `merged`'s two callers do not change | A per-id `merged` with `Part = Row?`; a second core beside `refreshCached` |
| D-8 | `protocol CatalogListRow: Identifiable, Sendable where ID == String { var listKey: CatalogListKey { get } }` *(new)* in `CatalogLastUpdated.swift`, empty conformances for the three summaries. `extension Array where Element: CatalogListRow { mutating func mergeSorted(_ fresh: [Element], replacing ids: [String]) }` *(new)*: build one `Set` of `ids` and the ids of `fresh`, and drop every row whose id is in it (one pass, O(n)); sort `fresh` stably by `listKey`; merge the two sorted runs in one pass, a fresh row going after kept rows with an equal key | States only what the merge reads (review M-7); one pass over the list; a fresh row that was not asked for cannot duplicate | `firstIndex` + insert per row (O(n·k)); re-sorting the whole list in the app |
| D-9 | `apply(_:_:)`'s `.run` gate drops the visibility test: a `.run` refresh runs for every warmed key that holds a value and is not stale (`!handle.isStale, handle.hasValue`); any other key it names joins the dedupe pass as today. `whenHidden` decides only what a whole reload does (user, 2026-11-15, review M-1). The three list arms keep `whenHidden: .markStale` and their patches; refreshes become `[.mergedRows(CatalogPersonSummary.self, follows: .touchedHandles) { session, key, ids in try await session.store.listPersonSummaries(projectDir: key.project.projectDir, entityIDs: ids) }, .followsPropertyLabels]` (Event, Place alike); `load` passes `entityIDs: nil`. A label edit still reloads a visible list whole and marks a hidden one stale. `.evidenceGraphsList` now merges while hidden (AC-1.9) | A merge is not the costly refetch `.markStale` exists to avoid; a hidden list stays current for a few ms per write, and a label edit away from the lists does not reload three lists (about 150–180 ms of engine time at 16,000 persons) | Switching the lists to `.revalidate` (the map row's first wording: a label edit would reload three hidden lists at once) |
| D-10 | `applyHiddenPolicyOnAny(follows:)` gains `precondition(follows.isCatalogWide, "a row slot names ids; use applyHiddenPolicy(follows:ids:)")`, and its doc says "the only constructor for a catalog-wide slot" | Its last row-slot callers leave in this PR (review M-2); the mirror of `requireRowIDs` | Leaving it open to row slots |
| D-11 | Test layers. Go holds the order (existing order tests, T-1, T-2), the parity file (T-2b) and the exactness of the touched set at Scale (T-9: five real writes on the large fixture). Swift holds the key's comparison against Go's keys (T-10b), the merge (T-10) and the session wiring with FakeStore (T-11 – T-21). The handler tests hold the filter and the key on the wire (T-6 – T-8) | Each half is tested where it lives, as S16-25 D-10 did; the parity file catches a Go order change Swift does not follow (review M-6) | An FFI round trip in Swift tests |
| D-12 | FakeStore: `listPersonSummariesEntityIDs`, `listEventSummariesEntityIDs`, `listPlaceSummariesEntityIDs: [[String]?]` *(new)*, appended on every call, as `listEvidenceGraphsSourceIDs`; `listPersonSummariesCalls` keeps counting every call. A filtered call returns the rows of the whole read whose `id` is in the filter, in the whole read's order. `seededPersonSummaries: [CatalogPersonSummary]?` *(new)*: when set, the whole read returns it in place of the composed rows. `listPersonSummariesError: Error?` *(new)*: thrown on every call when set, as `listEvidenceGraphsError`. `personSummaries()` sets each composed row's `listKey` to `CatalogListKey(last: name == nil, primary: Data((name?.form.lowercased() ?? "").utf8), ref: entity.ref.lowercased())` and sorts by it, replacing its closure. Seeded rows keep the keys a test gives them | FakeStore's own order, stated once as a key; filtering keeps whatever a test seeded; one hook shape (review M-8) | FakeStore collating like Go (an engine rule in the fake) |
| D-13 | T-9's writes. A helper `runWrite[T any](t testing.TB, c *database.Catalog, action string, fn func(tx *database.Tx) (T, []rowchange.Change, error)) effects.Set` *(new, in the test file)* calls `writes.Run(c, writes.Op{Action: action, UserID: userID}, fn)`, fails the test on error, and returns `res.Effects`; each write passes its package call as `fn` directly (`promote.Save` with action `"promote_subject"`, `citations.CreateWithObservations` with `"create_citation_with_observations"`). `nameProp := lf.Prop("name").ID` and `topProp := lf.Prop("toponym").ID` are read before the first write; `locator` is the package's `const locator` (`promotealign_test.go`). Setup commits (new Subjects, bridges, through the fixture's `Records` helpers) are made first and are not measured; the measured write is the one `runWrite` call, and "before" is the full lists read right before it. Every `lf.Prop(…)` lookup happens before `runWrite`: a catalog read inside the write's transaction blocks. The five, in order: W1 setup `p := lf.Person(lf.other, lf.otherA, "Zed Newperson")`, write `promote.Save(tx, userID, promote.Input{SubjectID: p.ID})`. W2 setup `b := lf.Birth(lf.onePlace, lf.pageArt)`, `q := lf.Person(lf.onePlace, lf.pageArt, "Yan Born")`, `lf.Participation(lf.onePlace, lf.pageArt, q, b, "subject")`, `lf.Locate(lf.onePlace, lf.pageArt, b, lf.citySubject)`; write promote `b`. W3 write `citations.CreateWithObservations(tx, userID, citations.CreateInput{ArtifactID: lf.otherA.ID, GraphID: p.GraphID, LocatorJSON: locator}, []observations.Input{{SubjectID: p.ID, PropertyID: nameProp, Name: namevaluetest.Western("Aaron Newperson")}})`. W4 setup `capital := lf.Place(lf.onePlace, lf.pageArt, "Capital")`, `lf.PlaceRel(lf.onePlace, lf.pageArt, lf.citySubject, capital, "part_of")`; write promote `capital`. W5 write `citations.CreateWithObservations(tx, userID, citations.CreateInput{ArtifactID: lf.pageArt.ID, GraphID: lf.citySubject.GraphID, LocatorJSON: locator}, []observations.Input{{SubjectID: lf.citySubject.ID, PropertyID: topProp, Scalar: propertymeta.TextScalar("Aardvark City")}})` | The writes the app makes, each one commit; the shapes ran on the 4,000 fixture at planning (touched 1, 3, 1, 4 and 2 ids; no untouched row changed) | A commit listener (another hook); counting setup commits (they touch no handle) |
| D-14 | Commits: (1) STEP-1 (one key for every order, no behavior change); (2) STEP-2 and STEP-3 (the rows of given ids, and the large-fixture test); (3) STEP-4 (the filter and the key on the wire); (4) STEP-5 to STEP-7 (the app merges); (5) STEP-8 (docs) | Each builds and passes its tests; (4) needs (3)'s generated Swift | One commit |

**Rules this plan bends.** D-9 changes when a partial re-read runs: `add-workspace-place` Refresh ("A `.run` entry runs only for a key that would revalidate (visible, or `whenHidden: .revalidate`)") and `macos-client-patterns.md` rule 2 and "Conclusion keys" say a hidden `.markStale` key re-reads nothing, and the map row said the lists "revalidate while hidden". The user chose on 2026-11-15 to let a merge run for any warmed key with a current value, on screen or not, with the lists staying `.markStale` (review M-1). STEP-6 rewrites the code comments and STEP-8 the skill, the patterns doc, the map row and the design line.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `conclusionsummaries.ListKey`, `titleListKey`, `dateKey.listKey` *(new)* | Go type, funcs | `titleKey`, `titleKeyLess`, `dateKeyLess` | Replaces them |
| `PersonSummary.ListKey` (Event, Place) *(new)* | Go field | `Updated` (filled by the list reads only) | Same lifecycle and doc |
| `personListKey`, `eventListKey`, `placeListKey` *(new)* | Go funcs | the closures `sortPersons` / `sortPlaces` pass `SortByTitle` today | Named once so the sort and the list fill share them |
| `ListPersonsOf`, `ListEventsOf`, `ListPlacesOf` *(new)* | Go funcs | `PersonsByIDs`, `EventsByIDs`, `PlacesByIDs` | Built on them; the `ByIDs` callers (search, detail) do not want the activity reads |
| `finishPersonList`, `finishEventList`, `finishPlaceList` *(new)* | Go funcs | the three `Updated` loops | Replace them and add the key |
| `testdata/list_keys.json` *(new)* | parity file | `sourcemetadata/testdata/draft_board_scenarios.json` | Same pattern |
| `entity_ids`, `ListKey` message, `list_key` *(new)* | proto | `ListEvidenceGraphsRequest.source_id`; `date_sort_key` | Same patterns |
| `listKeyProto` *(new)* | Go mapper | `termProto` | One mapper per message |
| `CatalogListKey` *(new)* | Swift struct | none (the app sorts no Conclusion list) | Mirrors the wire |
| `CatalogListRow` *(new)* | Swift protocol | `CatalogQueryPatch.row`'s `Identifiable & Sendable` constraint | Adds the key the merge reads |
| `Array.mergeSorted(_:replacing:)` *(new)* | Swift func | `.evidenceGraphsList`'s merge closure (`removeAll` + `append`) | That list's order is the app's to make; this one is Go's |
| `CatalogQueryRefresh.mergedRows` *(new)* | Swift constructor | `CatalogQueryRefresh.merged` | One batch read (D-7); both share `refreshCached` |
| FakeStore `list…SummariesEntityIDs`, `seededPersonSummaries`, `listPersonSummariesError` *(new)* | test hooks | `listEvidenceGraphsSourceIDs`, `seededEventSummaries`, `listEvidenceGraphsError` | Same patterns |
| `TestListMergeMatchesReload`, `BenchmarkListRowsOfWrite`, `runWrite` *(new)* | Go test, bench, helper | `TestLargeSourceBudgets`, `BenchmarkCacheSizes` | Same fixture |
| `CatalogListMergeTests.swift` *(new)* | Swift tests | `MetadataDraftHostParityTests.swift` (parity half) | New suite for a new type |

**Builds on.** S14-42's exact touched set; the `.run` refresh path; `refreshCached`; `requireRowIDs`; `parseIDs`; the `ByIDs` reads; the large fixture; the parity-file pattern.
**Deletes.** `titleKey`, `titleKeyLess`, `dateKeyLess`; `sortByKey`'s `K` and `less` parameters; the three `Updated` loops; FakeStore `personSummaries()`'s sort closure; `refreshCached`'s per-id loop (it moves into `merged`); the visibility test in `apply`'s `.run` gate; the three lists' `.applyHiddenPolicyOnAny(follows: .touchedHandles)` (`applyHiddenPolicyOnAny` then refuses row slots); the whole-list reload on every handle write; the doc sentences in §4 that state the old gate.
**Next adds.** A new ordered list of handles declares `.mergedRows` and conforms its row to `CatalogListRow`; a later sort column would be a second key from Go, not an app comparator.

### Reach

None — no new navigation path. Two states become reachable: a hidden, loaded list (or Evidence graph list) holds a current value after a write, so Back shows it and starts no load; and a hidden key runs a partial read during `apply(_:_:leavingPage:)`. The second is a read by id that returns nothing for the deleted id and drops its row; no page or list loads whole, which is what that method's "Nothing reads the deleted id in between" protects (STEP-6 rewords it).

### Scale

At the map's Scale (Batch 2: 4,000 and 16,000 persons; 8,115 and 20,115 Person rows, 10,067 Event rows, 51 Place rows on the large fixture; planning machine, warm):

- **Today, per write that names a handle:** a visible list reloads whole (Persons 39–73 ms at 4,000 and 115–137 ms at 16,000; Events 28–39 ms; Places 0.2 ms), and a hidden one reloads whole on its next visit.
- **After, per write:** each loaded list makes one store call with the write's touched ids. Measured at 4,000, the three kinds together: W1 27 µs (1 id), W2 0.43–0.55 ms (3 ids), W3 41 µs (1 id), W4 1.2 ms (4 ids), W5 0.42 ms (2 ids). Swift's merge is one pass over the list (20,115 rows) plus the returned rows. The hidden Evidence graph list adds one call per named Source, as a visible one makes today.
- **Crafted:** a merge of a 20,000-child hub names about 20,000 ids: one request of about 740 KB of ids, a read no costlier than the whole list (the same compose over fewer nodes), and one merge pass. No cap: the whole list bounds the read. Before D-9 a hidden list cost nothing for such a write; now each loaded list, hidden or not, pays up to the whole list's cost (about 180 ms for the three at 16,000 persons) on that rare crafted write, against a whole reload on its next visit before.
- **Go order:** `SortByTitle` builds one collation key per row: at 20,115 titles 3.9 ms to build and 4.1 ms to sort, against 47.6 ms with `CompareString` today. A list read builds the keys a second time to fill `ListKey` (D-4): about 4 ms more at 20,115 titles.
- **Swift merge, per loaded list per write:** 23 ms Debug / 3.6–4.3 ms Release at 20,115 rows, 106 ms Debug / 14 ms Release at 80,000; linear in the list, now paid by hidden lists too (D-9). `mergeSortedAtScaleStaysUnderCeiling` asserts the 20,115-row Debug figure under 120 ms (`// decided: S16-26 F-4`; the ceiling catches a slip to O(n·k)).
- **Swift merge through the id→key index (F-6), per loaded list per write:** 6.5–10 ms Debug / 2.7 ms Release at 20,115 rows, 34–40 ms Debug / 18 ms Release at 80,000, against the one-pass figures above (the Release harness's row is a proxy of 832 bytes, so compare its own one-pass figures: 10.6 ms and 44 ms). The figures include the copy the session's `patchCached` makes of the cached value, so they do not fall with the rows touched alone. Past `indexedMergeLimit` the merge takes the one pass and rebuilds the index: 40–61 ms Debug / 13.8 ms Release at 20,115, 120–163 ms Debug / 77 ms Release at 80,000. `listRowsAtScaleStaysUnderCeiling` asserts the indexed 20,115-row Debug figure under 50 ms (`// decided: S16-26 F-6`).
- **Budget (rule "Measure growth"):** T-9 asserts the three filtered reads of each write take under `ceilingListRowsOfWrite = 20 * time.Millisecond` at 4,000 persons (`// decided: S16-26 D-13`; measured 1.3 ms at most; the ceiling catches a slip to a whole compose). `BenchmarkListRowsOfWrite` reports the whole lists and each write's filtered reads at 4,000 and 16,000; the ship log records both.

### Edges

- **Assumptions.** (a) A row the write did not name reads the same after it: Go's display cache drops exactly roots ∪ `SummaryDeps`, and `touchedHandles` is `Handles ∪ SummaryDeps`; the extra roots Go drops (association ends, a deleted node's neighbours, a merged node's neighbours) are in `SummaryDeps`, which holds the ends of the links that changed (`effects.Set.SummaryDeps` doc). T-9 holds it over five writes. (b) Keys are total: refs are `UNIQUE NOT NULL` (`core/database/migrations/000032.sql`) and lowercasing keeps them unique, so no two rows tie. (c) The list held in Swift is in key order: every row came from a list read, whose `ListKey` is the key function its sort used (D-2, D-4). (d) A row's key depends on its own title or date, its ref, and for Persons the name format profile, which no runtime write changes (Out). (e) Collation keys compare bytewise as `CompareString` does (measured; the existing order tests hold it). (f) The `.run` gate's other conditions stay: no partial read for a key with no value (its first load restarts) or a stale key (it reloads whole when next shown).
- **Neighbors.** A write naming only non-list ids (an association): the reads return nothing for them, and dropping absent ids changes nothing. An Event id: the Persons read returns nothing for it, the Events read its row. A note: no read (AC-1.8). A label edit: whole reload or stale, no partial (AC-1.7: `apply` starts no `.run` for a key in the dedupe pass). A hidden `.markStale` key with a `.run` that is not a list: only `.evidenceGraphsList`; it merges (AC-1.9).
- **Removed inputs.** A deleted handle: its id is in `Handles`, Go returns nothing, the row goes (AC-1.3). A merged-away handle: `Handles` names it, Go lists only unmerged rows, the row goes; the survivor is re-read. A row whose title or date changes moves to its new place (AC-1.2).
- **Real data.** None — no table-driven rule.
- **Untrusted size.** `entity_ids` comes from the app's own effects; `parseIDs` refuses a malformed id. The read composes at most the given ids. Two merges for one id from two quick writes land in the order their reads ran, since the engine serves calls first in, first out (as `.merged` today).

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/conclusionsummaries` (`order.go`) | `ListKey` *(new)* with `Less`; `titleListKey`, `personListKey`, `placeListKey` *(new)*; `sortByKey` takes a `func(T) ListKey`; `SortByTitle` sorts by `titleListKey`; `titleKey`, `titleKeyLess` go; `sortPersons`, `sortPlaces` sort by the kind's key function. Imports `bytes` |
| `core/database/conclusionsummaries` (`compose.go`) | `dateKey.listKey`, `eventListKey` *(new)*; `sortByDateKey` passes it; `dateKeyLess` goes; `sortEvents` sorts by `eventListKey`; `finishPersonList`, `finishEventList`, `finishPlaceList` *(new)* replace the three `Updated` loops; `ListPersonsOf`, `ListEventsOf`, `ListPlacesOf` *(new)*. Imports `encoding/binary` |
| `core/database/conclusionsummaries` (`conclusionsummaries.go`) | `ListKey ListKey` on the three summary types |
| `core/database/conclusionsummaries/testdata/list_keys.json` *(new)* | `{"titles": [Row], "dates": [Row]}`, each array in Go order and checked on its own (title and date keys are never compared with each other). A title row: `{"title": "Montréal", "ref": "PLC-B", "last": false, "primary": "<hex>", "key_ref": "plc-b"}` for AC-2.2's five places. A date row: `{"year": 1850, "side": "before"|"exact"|"after"|"none", "ref": "EVT-1", "last": …, "primary": …, "key_ref": …}` for AC-2.3's five events, where the test builds the date with `datevaluetest.Before(y, 0, 0)`, `YMD(y, 0, 0)`, `After(y, 0, 0)`, or none. `ref` is the input ref; `key_ref` is the key's lowercased `Ref` |

```go
// ListKey is a row's place in a list's order: rows with Last false first,
// then Primary bytewise, then Ref bytewise. Every order in this package sorts
// by it, and the list reads send it, so the app can place a re-read row.
type ListKey struct {
	Last    bool
	Primary []byte
	Ref     string
}

// ListPersonsOf is PersonsByIDs with Updated, as ListPersons gives each row.
// No ids reads nothing.
func ListPersonsOf(c *database.Catalog, ids [][]byte) ([]PersonSummary, error)
```

### FFI

`api/proto/engine.proto`: `entity_ids = 2` on the three list requests, with the filter sentence in each request's comment; `ListKey` *(new)*; `list_key` = 11 / 18 / 15 (D-5). Handlers in `api/ffi/handlers/conclusion_summaries.go`; `listKeyProto(k conclusionsummaries.ListKey) *engine.ListKey` *(new)*. Regenerate with `./scripts/generate-proto.sh`.

### macOS

No view changes. Session layer:

```swift
struct CatalogListKey: Sendable, Equatable, Comparable {
    var last = false
    var primary = Data()
    var ref = ""
}

protocol CatalogListRow: Identifiable, Sendable where ID == String {
    var listKey: CatalogListKey { get }
}

static func mergedRows<Row: CatalogListRow>(
    _: Row.Type,
    follows: CatalogQueryFollows,
    read: @escaping @MainActor @Sendable (WorkspaceSession, CatalogQueryKey, [String]) async throws -> [Row]
) -> CatalogQueryRefresh
```

`apply(_:_:)`'s `.run` gate (D-9):

```swift
if !handle.isStale, handle.hasValue {
    running.append((key, run, ids))
} else {
    fallbacks.append(key)
}
```

States: an empty list merges returned rows in; a failed re-read applies the hidden policy (AC-1.6). Accessibility: unchanged.

### Strings

None — no user-facing copy.

## 7. Steps

**STEP-1 — One key for every order (Go, no behavior change)**
Files: `core/database/conclusionsummaries/order.go`, `compose.go`, `conclusionsummaries.go`, `conclusionsummaries_test.go`, `testdata/list_keys.json` *(new)*.
Do: D-1, D-2. Add T-1, T-2 (with keys from the key functions), T-2b. T-2b only compares; on a mismatch it fails with the whole expected file in its message, which is how the file is written the first time (paste it, rerun).
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/conclusionsummaries/ ./core/database/persondetail/ ./core/database/promotealign/ ./core/database/graphcache/ ./core/database/conclusiondetails/` passes (the last two run `Verify` with `checkDisplay`) with every existing order test unchanged; `rg -n "titleKeyLess|dateKeyLess|titleKey\{" core` finds nothing.

**STEP-2 — The list rows of given ids (Go)**
Files: `core/database/conclusionsummaries/compose.go`, `conclusionsummaries_test.go`.
Do: D-3, D-4. Add T-3 – T-5.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/conclusionsummaries/ ./core/database/graphcache/ ./core/database/conclusiondetails/` passes; `checkDisplay` is unchanged; `TestListSummariesCarryUpdated` and `TestListPersonsQueryCountIsConstant` unchanged.

**STEP-3 — Merge equals reload on the large fixture (Go)**
Files: `core/database/promotealign/listmerge_test.go` *(new)*.
Do: D-13, T-9 and `BenchmarkListRowsOfWrite` (the same five writes on fresh fixtures at 4,000 and 16,000; reports `persons-ms`, `events-ms`, `places-ms` for the whole lists and `rows-us` per write for the filtered reads). The test's merge helper is generic over the three row types: drop the touched ids and the returned ids, insert each returned row by `ListKey.Less`, then compare with `reflect.DeepEqual` against the full list read after the write.
Check: `CGO_ENABLED=1 go test -tags fts5 -run TestListMergeMatchesReload ./core/database/promotealign/` passes; `CGO_ENABLED=1 go test -tags fts5 -run '^$' -bench BenchmarkListRowsOfWrite -benchtime 1x ./core/database/promotealign/` prints figures at 4,000 and 16,000 (into the ship log).

**STEP-4 — The filter and the key on the wire**
Files: `api/proto/engine.proto`, generated `api/proto/engine/engine.pb.go` and `macos/App/Platform/Generated/engine.pb.swift`, `api/ffi/handlers/conclusion_summaries.go`, `conclusion_summaries_test.go`. Skill: `add-ffi-handler`.
Do: D-5; `./scripts/generate-proto.sh` (stop and report if `protoc` or a plugin is missing). Add T-6 – T-8.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/...` passes.

**STEP-5 — Rows carry the key; the store takes a filter (Swift)**
Files: `macos/App/Platform/GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift`, `macos/ProvenenciaTests/OnboardingModelTests.swift` (`ThrowingStore`), `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift` (the three `load` calls pass `entityIDs: nil`).
Do: D-6, D-12. GoStore maps a list row as `resp.summaries.map { proto in var row = Self.mapPersonSummary(proto); row.listKey = Self.mapListKey(proto.listKey); return row }` (Event, Place alike).
Check: `xcodebuild build` succeeds with no new warning; `WorkspaceSessionTests` and `CatalogQueryRegistryTests` still pass.

**STEP-6 — Lists merge the touched rows (Swift)**
Files: `macos/App/Features/Workspace/Session/CatalogLastUpdated.swift`, `WorkspaceSession.swift`, `CatalogQueryRegistry.swift`. Skill: `add-workspace-place`.
Do: D-7 – D-10. Rewrite these comments: `CatalogQueryDescriptor.whenHidden` ("What an invalidated key that isn't on screen does when it reloads whole. The exception to cache rule 2 for lists and per-handle pages, so one trigger doesn't reload every list or page the researcher has opened. A `.run` refresh merges into a hidden key whatever this says."); the `.evidenceGraphsList` arm's "A hidden list goes stale until it is shown again." → "A hidden list merges too; a whole reload of a hidden list waits until it is shown."; `apply(_:_:)` (the sentence from "gated per key" becomes "gated per key: one runs for a key that holds a value and is not stale, on screen or not"); `apply(_:_:leavingPage:)` ("so no list loads" → "so no page or list loads whole; a hidden list may re-read the deleted id by id and drop its row"); `refreshCached` (D-7); `applyHiddenPolicyOnAny` (D-10).
Check: `graphListMergesOneSourcesReRead`, `graphListMergeSplicesTheIndex`, `graphListPartialReReadSetsFetching`, `graphListPartialReReadFailureReloadsTheList` and the graph progress tests pass unchanged.

**STEP-7 — Swift tests**
Files: `macos/ProvenenciaTests/CatalogListMergeTests.swift` *(new)*, `WorkspaceSessionTests.swift`, `CatalogQueryRegistryTests.swift`. Skill: `add-swift-test`.
Do: T-10 – T-21. Every test §4 lists under "Tests (Swift) that pin today's lists" is rewritten as its T-# says; the tests under "stay as they are" pass unchanged.
Check: `xcodebuild test` (as `scripts/check-pr.sh` runs it) passes with no Swift warning. A failure in a test §4 does not name is a Stop condition.

**STEP-8 — Docs**
Files and replacement text:
- `docs/macos-client-patterns.md` line 89: "(the graph list and graph progress re-read just those ids and merge them into the warmed value): the Evidence graph and list keys follow `evidenceGraphs` and `touchedHandles`" becomes "(the graph list and graph progress re-read just those ids, and the Persons, Events and Places lists re-read the `touchedHandles` rows by id, each merged into the warmed value): the Evidence graph keys follow `evidenceGraphs`".
- Line 90: the sentence that lists the `.markStale` keys stays, and the last sentence ("One save made away from a list reloads no list until the researcher looks at one.") becomes "A partial re-read (`.run`) merges into a warmed key on screen or not; `whenHidden` decides what a whole reload does. A save made away from a list re-reads only the rows it touched in each loaded list; a label edit marks a hidden list stale."
- "Conclusion keys" line (101): "The Persons, Events and Places lists merge the `touchedHandles` rows by id (`CatalogQueryRefresh.mergedRows`: one store call, rows placed by Go's `list_key`), on screen or not, and reload whole for `property_vocabulary`. No mutation reaches a Conclusion key." Line 103's "The three lists are `.markStale`: the visible one reloads, the others reload when shown." → "The three lists are `.markStale` for a whole reload (a label edit): the visible one reloads, the others reload when shown; a handle write merges into each, shown or not."
- `.agents/skills/add-workspace-place/SKILL.md` Refresh row: name `CatalogQueryRefresh.mergedRows(_:follows:read:)` beside `merged` (one batch read of the named ids, rows placed by `CatalogListKey`), and replace "A `.run` entry runs only for a key that would revalidate (visible, or `whenHidden: .revalidate`), holds a value and is not stale" with "A `.run` entry runs for a key that holds a value and is not stale, on screen or not". The Mark stale row: after "`apply` flags the warmed key without a refetch" add "(a `.run` refresh still merges into it while it holds a current value)".
- `.cursor/rules/swift-tests.mdc` line 23: add `seededPersonSummaries` to the seeded composers.
- `docs/catalog-caches.md` line 53, the Swift "Per-view query results" row's Updated by cell: append at the end of the cell "; the Conclusion lists merge `touchedHandles` rows (`mergedRows`)".
- `docs/deployment-plan/spike-16/cache-architecture.md` line 74: "**Lists merge the touched rows (S16-26)**: one read of the touched ids, rows placed by a list key from Go, on screen or not", followed by a link to this plan.
- `deployment-plan.md`: the S16-26 map row's scope "through the existing merged read" → "through one batch merged read (`mergedRows`)", and its status; the S16-26 scope entry's "becomes the existing `.merged` read" → "becomes one batch merged read (`mergedRows`)", and "and they revalidate while hidden" → "which runs on screen or not (user, 2026-11-15)".
- `completed.md`; this plan (status, Landed note).
Check: links resolve; `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-26-lists-merge-touched-rows.md` passes.

Commits: one per behavior, as D-14. The subject is one full imperative sentence that says what changed for the researcher, ending in a period ("Re-read only the rows a write touched in the Persons, Events and Places lists."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `conclusionsummaries_test.go` `TestListKeyLess` *(new)* | Table: `{Last:false}` < `{Last:true}`; `Primary` `[0x01]` < `[0x01,0x00]` < `[0x02]`; equal Primary, `Ref` `"per-a"` < `"per-b"`; equal keys → not less either way | D-1 |
| T-2 | Go | same file `TestListKeysFollowListOrder` *(new)* | Places titled as AC-2.2, events dated as AC-2.3 → each list's rows strictly increase under `ListKey.Less`; the untitled and undated rows have `Last`; the place order is `PLC-A`, `PLC-B`, `PLC-C`, `PLC-D`, `PLC-0` | AC-2.2, AC-2.3, D-2 |
| T-2b | Go | same file `TestListKeysFile` *(new)* | `testdata/list_keys.json`'s inputs → `titleListKey` / `dateKey.listKey` give its keys; within `titles`, and within `dates`, the rows strictly increase under `Less` | AC-2.6 |
| T-3 | Go | same file `TestListPersonsOf` *(new)* | ids: two Persons, one repeated, a Place, an unknown id (shape of `TestPersonsByIDs`) → the two Persons' rows, each `reflect.DeepEqual` to its row in `ListPersons` (`Updated`, `ListKey` included), in list order; `nil` ids → `nil, nil`; `PersonsByIDs` rows have a zero `ListKey` | AC-2.4, D-4 |
| T-4 | Go | same file `TestListEventsOf` *(new)* | an Event and a Person id → the Event's row as in `ListEvents` | D-4 |
| T-5 | Go | same file `TestListPlacesOf` *(new)* | a Place and an Event id → the Place's row as in `ListPlaces` | D-4 |
| T-6 | Go | `api/ffi/handlers/conclusion_summaries_test.go` `TestListPersonSummaries` (new cases) | "filtered to one person": `entity_ids` = the handle id and an unknown id → one summary, `list_key` equal to its key in the unfiltered response; "malformed id" → error; the unfiltered case asserts every row has a `list_key` and the keys increase | AC-2.4, AC-2.5, D-5 |
| T-7 | Go | same file `TestListEventSummaries` (new case) | filtered to one event → one summary with `list_key` | D-5 |
| T-8 | Go | same file `TestListPlaceSummaries` (new case) | filtered to one place → one summary with `list_key` | D-5 |
| T-9 | Go | `core/database/promotealign/listmerge_test.go` `TestListMergeMatchesReload` *(new)* | Large fixture at 4,000; W1–W5 of D-13 → for each, the previous full lists merged with the filtered reads of `Handles ∪ SummaryDeps` equal the full lists after, in order, `Updated` included; the three filtered reads together take under `ceilingListRowsOfWrite` | AC-2.1, D-13, Scale |
| T-10 | Swift | `macos/ProvenenciaTests/CatalogListMergeTests.swift` *(new)* `mergeSortedPlacesRowsByKey` | rows `a`(1) `b`(3) `c`(5), keys by `primary`: merge `[b'(6)]` replacing `["b"]` → `a`, `c`, `b'`; merge `[d(2)]` replacing `["d"]` → `a`, `d`, `b`, `c`; merge `[]` replacing `["b"]` → `a`, `c`; merge `[a'(1)]` replacing `[]` → one `a'`, then `b`, `c`; empty list, merge `[x]` → `[x]`; a `last` key goes after every other | AC-1.2 – AC-1.4, D-8 |
| T-10b | Swift | same file `listKeyOrderMatchesGo` *(new)* | `core/database/conclusionsummaries/testdata/list_keys.json` (via `#filePath`, as `MetadataDraftHostParityTests.load()`) → within `titles`, and within `dates`, each row's key (`last`, hex `primary`, `key_ref`) `<` the next | AC-2.6, D-6 |
| T-11 | Swift | `WorkspaceSessionTests.swift` `visibleListsReReadOnlyTouchedRows` *(new)* | `seededPersonSummaries` `p1`(1), `p2`(2), `p3`(3) by `primary`; the Persons list on screen and loaded; the seed's `p2` key becomes 4; `apply(handles: ["p2"], summaryHandles: ["e9"])`, `settleWrites()` → `listPersonSummariesEntityIDs == [nil, ["p2", "e9"]]`; rows `p1`, `p3`, `p2`; `isFetching` true right after `apply` | AC-1.1, AC-1.2 |
| T-12 | Swift | `WorkspaceSessionTests.swift` `hiddenListsMergeTouchedRows` (replaces `hiddenListsGoStaleVisibleListReloads`) | All three lists hidden, seeded with `e1` via `setQueryValue`; FakeStore has no `e1` row; `apply(handles: ["e1"])`, `settleWrites()` → each kind's recorder is `[["e1"]]`; each list is empty; none `isStale`; a `query` of each starts no load | AC-1.3, AC-1.5 |
| T-13 | Swift | `WorkspaceSessionTests.swift` `applyPromoteMergesThePromotedPerson` (replaces `applyPromoteMarksHiddenPersonsListStale`) | Its setup; after `apply`, `settleWrites()` → the hidden list holds the promoted row; `listPersonSummariesEntityIDs == [nil, [promoted id]]` | AC-1.4, AC-1.5 |
| T-14 | Swift | `WorkspaceSessionTests.swift` `listReReadFailureFollowsTheHiddenPolicy` *(new)* | Visible loaded Persons list; set `listPersonSummariesError`; `apply(handles: ["p2"])`, `settleWrites()` → the recorder ends `[…, ["p2"], nil]` and `status == .error` (copy `graphListPartialReReadFailureReloadsTheList`); hidden: the recorder ends `["p2"]` and the list `isStale` | AC-1.6 |
| T-15 | Swift | `WorkspaceSessionTests.swift` `labelEditReloadsOrStalesListsWithNoPartialRead` *(new)* | `apply(handles: ["p2"], lists: [.propertyVocabulary])`: visible Persons list → one whole read, no filtered read; hidden → stale, no read | AC-1.7 |
| T-16 | Swift | `WorkspaceSessionTests.swift` `effectSlotsRevalidateTheirKeys` (updated) | `revalidatedKeys(handles: ["e1"], evidenceGraphs: ["g1"])` → `[graph1]` only (the lists merge; they are not revalidated) | D-9 |
| T-17 | Swift | `CatalogQueryRegistryTests.swift` `handleScopesInvalidateNothing` (updated) | `revalidatedKeys(handles: ["e1"], handleScopes: ["e1", "e2"])` → `[detailKey]`; `handleScopes` only → nothing | AC-1.8 |
| T-18 | Swift | `WorkspaceSessionTests.swift` `applyTriggerStalesHiddenDetailPagesAndRevalidatesTheVisibleOne` (updated) | Its "The list is off screen" half: after `apply` and `settleWrites()` the list is not stale and its first row's name is "Jim Robins" with no `query`; the rest unchanged | AC-1.5 |
| T-19 | Swift | `WorkspaceSessionTests.swift` `sourceWriteEffectsPatchSourcesAndLeaveListsAlone` (updated) | Its AC-2.12 half: after `apply(handles: ["e1"], …)` and `settleWrites()`, `listsAreQuiet()`, the people recorder ends `["e1"]`, the hidden lists are not stale, and a `query(people)` starts no load | AC-1.5 |
| T-20 | Swift | `WorkspaceSessionTests.swift` `hiddenGraphListMergesOnRead` (replaces `hiddenGraphListGoesStaleOnRead`) | Hidden loaded graph list; `apply(graphRead("S"))`, `settleWrites()` → `listEvidenceGraphsSourceIDs == ["S"]`, not stale; a `query` starts no load | AC-1.9 |
| T-21 | Swift | `CatalogQueryRegistryTests.swift` `invalidationsComeFromRegistrySpecs` (one added line per list) | each list's first refresh's `action` is `.run` (the `follows` loop stays `[.touchedHandles, .list(.propertyVocabulary)]`). `applyHiddenPolicyOnAny`'s precondition is not tested, as `requireRowIDs`' is not | D-9, D-10 |

Must stay green: everything `scripts/check-pr.sh` runs, and the tests §4 lists under "stay as they are". Most likely to break: the `conclusionsummaries` order tests (STEP-1), `TestListPersonsQueryCountIsConstant` (STEP-2), and any test that seeds a hidden `.markStale` key with a `.run` refresh (STEP-6).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none expected)
- [ ] Sweep: `titleKeyLess`, `dateKeyLess`, `listPersonSummaries(projectDir:)` (old signature), "only way to declare one", "goes stale until it is shown again", "Called only by `CatalogQueryRefresh.merged`", "would revalidate (visible" `rg`'d across `macos/App`, `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no stale hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none)
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New (no UI)
- [ ] Version bump: patch (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] BenchmarkListRowsOfWrite figures at 4,000 and 16,000 in the ship log, the whole lists beside each write's filtered reads
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status and wording (STEP-8); completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (no brief)
- [ ] Domain doc updated: macos-client-patterns.md, add-workspace-place, swift-tests.mdc, catalog-caches.md, cache-architecture.md (STEP-8 text)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Open a project with at least a few hundred persons. Open Persons, scroll to the middle and note two rows.
2. Open a Person, add a name Observation in one of its Evidence graphs that sorts the person elsewhere, and go Back to Persons: the person sits at its new place, the rest of the list is as before, and no "Refreshing" state shows.
3. Visit Events, then a Source; promote a new event from that Source; go to Events: the event is in date order, with no reload.
4. Rename a Property label in the Properties workspace; go to Persons: the list reloads once (expected: it was marked stale).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A write changes a row it does not name, so a merged list drifts from a full reload | T-9 on five writes; Go's display cache relies on the same set |
| Collation keys order differently from `CompareString` for some title | The existing order tests, T-2, and the 20,115-title measurement |
| Hidden lists now pay a store call per write | At most 1.3 ms for the writes measured; bounded by the whole list for a crafted write |

**Stop and report if:**

- An existing order test in `conclusionsummaries` or `persondetail` fails after STEP-1.
- T-9 finds a row outside `Handles ∪ SummaryDeps` that changed after a write: name the write and the row. The touched set is S14-42's to fix, not this PR's.
- `TestListPersonsQueryCountIsConstant` (or its Event or Place twin) fails after STEP-2.
- A `Verify` run (`PROVENENCIA_GRAPH_VERIFY=1`) reports a display row mismatch.
- For any of T-9's five writes, the filtered reads exceed `ceilingListRowsOfWrite` at 4,000 persons, or at 16,000 take more than 10% of that kind's whole list in `BenchmarkListRowsOfWrite`.
- A Swift test §4 does not name fails after STEP-6.
- A runtime write is found that changes the name format profile, or any write that moves every row's key without reporting `property_vocabulary`.

## 12. Open questions

None.

## 13. PR

**Title:** S16-26 — Conclusion lists merge the rows a write touched
**Body:** objective in one sentence; what shipped against each US; AC evidence; the benchmark figures; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-26-lists-merge-touched-rows.md`.
