# S16-27 — One primitive for values derived from cached data

**Status:** Draft
**Spike / slice:** Spike 16 · Slice 2e — The app's cache
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: every view draws the same content; only how often the app builds it changes)
**Board:** —
**Depends on:** S16-03 (landed [#769](https://github.com/mendahu/provenencia/pull/769): one list of section reads), S16-07 (landed [#761](https://github.com/mendahu/provenencia/pull/761): `ConclusionFoldState`, one fold state per section)
**Blocks:** —
**Branch:** `s16-27-derived-values`
**Version bump:** patch — the app builds what it derives for display once per change of its inputs; nothing new on screen ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/macos-client.mdc`, `.cursor/rules/swift-tests.mdc`
**Context:** [design § Swift](../cache-architecture.md#swift) ("One primitive for derived values"); [`docs/macos-client-patterns.md`](../../../macos-client-patterns.md) "Cache contract" rule 5; [`docs/catalog-caches.md`](../../../catalog-caches.md) "Swift caches"; working rules: "(Batch 2) The point of this batch is simpler code", "(Batch 2) Swift caches one value per view, follows its inputs and shows it stale while refreshing", "(Batch 1) Refused: memoising and re-shaping for speed" (its Batch 2 clause names this PR), "(Batch 2) No new persisted projections, and no stored answer without a measurement"; goal bar 15's last clause
**Planned:** 2026-11-15 against `main` @ `1f52b60`
**Review:** — (not reviewed yet)

**Runs on macOS.** Every step is Swift. On a machine without `xcodebuild`, stop after reading and report that the steps need a macOS runner.

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

The app derives display values from cached reads in five hand-written ways: the Evidence graph index's revision bookkeeping, `EvidenceGraphModel`'s tuple memo (which compares whole row arrays on every read), `CitationComposerContext`'s `MemoToken`, `SourcesModel`'s `VisibleRowsToken`, and no memo at all for the Evidence graph snapshot Promote and Unpromote build and for a Person section's content, which `ConclusionPageSectionHost` builds on every pass of its body. This PR gives `WorkspaceSession` one primitive, `derived`, that builds a value once per change of the handles it reads and of the plain values it names (fold state, name orders, width class, locale), and moves every one of those onto it. A reader then names its inputs and its build, and nothing else.

**Why now.** Bar 15's last clause ("every value the app derives from cached data is built once per change of its inputs") and the map row. S16-03 gave each section one list of reads and S16-07 one `Equatable` fold state, so a section's inputs can now be named.

**What stays.** Every view draws what it draws today. The query cache, its keys, `followsInputs` and the hidden-entity cap are unchanged. `Memo` stays for the depiction preview, which derives from a draft, not from cached data.

## 2. User stories

**US-1.** As a contributor, when a view derives a value from cached reads, I name its inputs and its build in one call, so that it is built once per change of those inputs and I write no revision bookkeeping.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A key holds a value at revision 1; `derived(.visibleSources, inputs: [key])` is read three times | the build ran once; `derivedBuildCount(.visibleSources) == 1` |
| AC-1.2 | Then `session.apply(effects)` refreshes that key (revision 2) and the value is read again | the build ran twice in all |
| AC-1.3 | Then a write refreshes another key that is not an input, and the value is read again | still two builds |
| AC-1.4 | Then the same read passes a different `extra` (fold state with one page revealed) | three builds; reading again with that `extra` keeps three |
| AC-1.5 | A key evicted (a deleted handle) and loaded again so its new handle is back at revision 1 | the next read builds again: an input whose handle was replaced never matches the old entry |
| AC-1.6 | An entry built from a key, then that key evicted | the entry is gone (`derivedBuildCount` unchanged, the next read builds) |

**US-2.** As a researcher, every view that moved draws the same thing it drew before.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | The Evidence graph list merges one Source's re-read | the index takes that Source's graphs in place; no full build (`derivedBuildCount(.evidenceGraphIndex)` unchanged); lookups by id, by Source and the linked Artifacts are right |
| AC-2.2 | `evidenceGraphSnapshot(graphID: "g1")` awaited twice with no write between | one build of `.evidenceGraphSnapshot(graphID: "g1")`; after the graph's rows reload, the third call builds once more and shows the new rows |
| AC-2.3 | Promote loads, then reproposes after a decision, the graph unchanged | the graph snapshot was built once |
| AC-2.4 | The Evidence graph canvas: a Subject relabelled from "Wm Robins" to "William Robins" (rows reload) | `displayText` names "William Robins"; reading `displayText` twice between writes builds it once |
| AC-2.5 | The citation composer: a term added to a term-valued Property (its `propertyTerms` key reloads) | the vocabulary rebuilds once and offers the new term; a write to an unrelated key rebuilds nothing |
| AC-2.6 | The Sources list: sort changed from A–Z to date oldest | one build; the rows are in date order as today |
| AC-2.7 | A Person's Timeline section: its content read three times between writes, then one Show more | one build, then one more for the new fold state; a reload of the person's events builds once more |

## 3. Scope

| In | Covered by |
| --- | --- |
| `WorkspaceSession.derived(_:inputs:extra:build:)`, `carryDerived`, `derivedBuildCount`, `DerivedValueID` *(new)*; `QueryHandle.serial` *(new)*; entries drop with an evicted input | STEP-1, AC-1.1 – AC-1.6 |
| The Evidence graph index moves onto it (the splice through `carryDerived`); `evidenceGraphIndex`, `evidenceGraphIndexBuildCount` and `EvidenceGraphIndex.revision` go | STEP-2, AC-2.1 |
| One graph snapshot per graph (`graphSnapshot(graphID:)`), read by `evidenceGraphSnapshot(graphID:)` (Promote, Unpromote), `EvidenceGraphModel` and the composer; `EvidenceGraphModel.snapshotMemo` goes | STEP-3, AC-2.2 – AC-2.4 |
| The composer's vocabulary moves onto it; `MemoToken`, `memo` and `termRevisions` go | STEP-4, AC-2.5 |
| The visible Sources move onto it; `visibleRowsMemo`, `visibleSourcesBuildCount` and `VisibleRowsToken` go | STEP-5, AC-2.6 |
| `ConclusionPageSectionHost` builds content through it, keyed by the section's reads; the four section sites pass their extras | STEP-6, AC-2.7 |
| `catalog-caches.md`, `macos-client-patterns.md` rule 5 and `add-workspace-place` teach it | STEP-7 |

| Out | Home |
| --- | --- |
| Engine-side memos | not planned (map scope entry: "Not this PR") |
| The depiction preview's `Memo` (derived from a draft, filled asynchronously) | not planned: not cached data |
| `SourcesModel.searchKeyCache` (per-row keys by row revision) | not planned: a per-row cache, not a derived value of whole reads |
| Prefetching sections | S16-29 |
| Lazy Timeline cards, participants sent once (P-7, P-8) | [person page performance idea](../../../ideas/person-page-performance.md) |
| A debug check that a build reads only its declared inputs | not planned: the Edges below and review hold it |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Handle revision | `macos/App/Features/Workspace/Session/QueryHandle.swift` `QueryHandle.revision`, `markReplaced`, `applyFailure`, `resetForInvalidation` | Bumps on every replace or clear of `value`; starts at 0 on a new handle, so a key evicted and loaded again reuses revision 1 |
| Erased handle | same file, `protocol AnyQueryHandle` (line 203) | `isStale`, `hasValue`, `isFetching`, stale and refresh calls; no revision |
| Eviction | `macos/App/Features/Workspace/Session/WorkspaceSession.swift` `evict(_ key:)` (line 533); `trimHiddenEntities`, `evict(_:ids:)` | Drops a key's handle; the hidden-entity cap and deletes both go through it |
| Index storage | same file, `evidenceGraphIndex`, `evidenceGraphIndexBuildCount` (lines 34–42) | Two `@ObservationIgnored` stored properties for one memo |
| Index | `macos/App/Features/Workspace/Session/WorkspaceSession+EvidenceGraphs.swift` `EvidenceGraphIndex` (carries `revision`), `currentEvidenceGraphIndex`, `spliceEvidenceGraphIndex(_:previousRevision:)` | Hand revision check; a merged re-read splices when the merge was the only revision move |
| Splice caller | `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift` `.evidenceGraphsList` `afterMerge` (line 405) | Calls `spliceEvidenceGraphIndex(parts, previousRevision:)` |
| Snapshot (async) | `WorkspaceSession+EvidenceGraphs.swift` `evidenceGraphSnapshot(graphID:)` | Awaits the graph, properties and rules keys, then builds `EvidenceGraphSnapshot.build` every call; nil when the rows are nil, empty types or rules when theirs are |
| Promote | `macos/App/Features/Promote/PromoteModel.swift` `load()` (line 157), the propose loop (line 269) | Builds the snapshot on every load and every repropose |
| Unpromote | `macos/App/Features/Catalog/Unpromote/UnpromoteFlow.swift` `open` (line 131) | Builds the snapshot on each open with bridges |
| Canvas snapshot | `macos/App/Features/EvidenceGraph/EvidenceGraphModel.swift` `snapshotMemo` (line 50), `displaySnapshot(rows:types:)`, `displayText(rows:types:)` (lines 241–266), `currentSnapshot()` (line 1371) | A tuple memo compared by whole `rows`, `types` and `rules` equality and the name orders on every read; text formatted with it |
| Canvas callers | `macos/App/Features/EvidenceGraph/EvidenceGraphView.swift` lines 112, 777, 790 | Pass `graphHandle.value` and `fieldsHandle.value?.types` in |
| Composer | `macos/App/Features/CitationComposer/CitationComposerContext.swift` `MemoToken`, `memo`, `built`, `termRevisions(in:)`, `graphSnapshot`, `vocabulary` | A revision token over graph, fields, rules and each term list; builds its own snapshot beside the canvas's |
| Visible Sources | `macos/App/Features/Sources/SourcesModel.swift` `VisibleRowsToken`, `visibleRowsMemo`, `visibleSourcesBuildCount`, `visibleSources` (lines 259–294) | A revision token over sources, types and (under a status filter) graphs and progress, plus settings and locale |
| Memo | `macos/App/Platform/Memo.swift` `Memo` | One-slot memo; used by the three above and `CitationComposerModel.depictionPreviewMemo` |
| Section host | `macos/App/Features/Conclusions/ConclusionPageSectionHost.swift` `loaded(_:)` | `ConclusionDetailPresentation(handle.reading, …, content: make)` calls `make` on every body pass |
| Section sites | `PersonTimelineSection.swift` (`make` captures folds, orders, width class, locale), `PersonFamilySection.swift` (folds, orders, locale), `PersonSourcesSection.swift` line 36 (claims groups, the supporting Source types handle, orders, folds) and line 201 (record links with `content.graphLocations`, from the claims) | Each builds a content value per pass |
| Section reads | `macos/App/Features/Workspace/ConclusionPageSection.swift` `reads(project:entityId:)` | One list per section: own, companion, supporting |
| Tests | `macos/ProvenenciaTests/WorkspaceSessionTests.swift` `evidenceGraphIndexFollowsTheListRevision`, `evidenceGraphSnapshotReadsTheThreeKeys`, `graphListMergeSplicesTheIndex`; `EvidenceGraphModelTests.swift` `displayTextFollowsTheSnapshot`; `SourcesModelTests.swift` (line 295, reads `visibleSourcesBuildCount`); `PromoteModelTests.swift`; `UnpromoteFlowTests.swift`; `CitationComposerModelTests.swift` | Cover today's memos and their behavior |

**Precedent.** `SourcesModel.visibleSources` is the shape to copy for the key: handle revisions plus plain values, built in a closure, a build counter for tests. `spliceEvidenceGraphIndex` (S16-12, [#800](https://github.com/mendahu/provenencia/pull/800)) is the shape `carryDerived` keeps: move the stored value forward only when the one merge was the only move. Do not copy `EvidenceGraphModel.snapshotMemo`'s comparison of whole values.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | One primitive on `WorkspaceSession`: `func derived<Value>(_ id: DerivedValueID, inputs: [CatalogQueryKey], extra: any Equatable..., build: () -> Value) -> Value`, in `macos/App/Features/Workspace/Session/WorkspaceSession+Derived.swift` *(new)*. It stamps each input key's handle, compares the stamps and `extra` with the stored entry's, returns the stored value on a match, else builds, stores and counts | Map row; one way for every reader; variadic `extra` lets a site pass its fold state, orders and width class with no per-site struct | A per-view `@State` memo (does not survive a remount, and is a second mechanism); `Hashable` extras (would add conformances to `NameFormatOrders`, `NameFormatPart`, `PVWidthClass`, `SourcesListSettings` for no reader) |
| D-2 | An input's stamp is its handle's `serial` and `revision`; a key with no handle stamps as serial 0. `QueryHandle` gains `let serial: Int` *(new)*, assigned from one main-actor counter at init (a private non-generic `enum QueryHandleSerials` in `QueryHandle.swift`; a generic class cannot hold a static stored property); `AnyQueryHandle` gains `serial` and `revision` | Revision alone matches a stale entry after an evict and reload (AC-1.5); a serial is a plain `Int`, so the entry holds no reference to a handle | Comparing values (O(rows) on every read, today's canvas memo); `ObjectIdentifier` (reused once the old handle is freed) |
| D-3 | `extra` compares pairwise through an opened existential (`(rhs as? T) == lhs`), and a different count is a miss | Equatable is all the extras have | `AnyHashable` (D-1) |
| D-4 | One slot per id: an entry keeps the latest stamps, `extra` and value | Every reader asks for one current value; two windows on one id stay correct and rebuild in turn | A least-recently-used set per id |
| D-5 | An entry lives as long as its inputs: `evict(_ key:)` drops every entry that lists the key. No cap of its own | The per-entity keys' 50-entity cap and deletes then bound the section entries; the catalog-wide entries are one each | A separate cap (a second rule to keep in step with `maxHiddenEntities`) |
| D-6 | `DerivedValueID` *(new)* is one closed enum beside the primitive: `evidenceGraphIndex`, `evidenceGraphSnapshot(graphID:)`, `evidenceGraphText(graphID:)`, `citationComposerVocabulary(graphID:)`, `visibleSources`, `sectionContent(ConclusionPageSection, ConclusionSectionRead.Role, entityId:)`. `ConclusionSectionRead.Role` becomes `Hashable` | One registry names every derived value, as `CatalogQueryKey.Kind` names every read; a typo cannot collide two values | An open `String` name; a generic typed key |
| D-7 | Entries are stored as `Any`; a stored value of another type than the caller's `Value` fails `preconditionFailure("DerivedValueID \(id) holds \(type) not \(Value.self)")` | Each id has one value type; the enum makes a mix-up a programmer error, as `query(_:)` treats a key | Silent rebuild on a type mismatch |
| D-8 | The store is one `@ObservationIgnored var derivedValues = DerivedValueStore()` *(new, `struct`)* on `WorkspaceSession`, and `derivedBuildCount(_ id:) -> Int` reads its counter. `derived` reads an entry, releases it, runs `build`, then writes: a build may call `derived` for another id (the composer's vocabulary reads the graph snapshot) | Filling while a view reads must not invalidate the view (as `evidenceGraphIndex` today); nested builds must not hold the dictionary | Observed storage (a view would invalidate itself while drawing) |
| D-9 | `carryDerived<Value>(_ id:, across key:, from previousRevision: Int, _ change: (Value) -> Value)` *(new)*: when the entry's stamp for `key` is the current handle's serial at `previousRevision`, the handle now stands at `previousRevision + 1`, and every other stamp and the stored `extra` still match, it stores `change(old)` stamped current; otherwise it does nothing and the next read builds. A carry is not a build | Keeps S16-12's splice (AC-2.1, `graphListMergeSplicesTheIndex`) with no bookkeeping in the reader | Dropping the splice (a full index build over 10,000 graphs on each graph write) |
| D-10 | `EvidenceGraphIndex` loses `revision`; `replacing(sources:)` loses its `revision:` argument. `currentEvidenceGraphIndex` becomes `derived(.evidenceGraphIndex, inputs: [evidenceGraphsKey])` building from the handle's rows, and returns nil while the handle has no value. `spliceEvidenceGraphIndex` becomes a `carryDerived` call; the registry's `afterMerge` calls it unchanged | Map row | — |
| D-11 | `graphSnapshot(graphID:) -> EvidenceGraphSnapshot` *(new)* on the session: `derived(.evidenceGraphSnapshot(graphID:), inputs: [graph, propertiesWorkspace, connectRules])` building from each handle's value (missing rows → `EvidenceGraphRows(graphId:)`, missing types or rules → empty). `evidenceGraphSnapshot(graphID:) async` keeps its three warms and awaits, returns nil when the rows' `readyValue` is nil, else returns `graphSnapshot(graphID:)`. The canvas and the composer read `graphSnapshot` | One build per graph per change, shared by Promote, Unpromote, the canvas and the composer | One snapshot per reader (today) |
| D-12 | Behavior change: when the types or rules key failed or stayed stale behind a value, `evidenceGraphSnapshot` now builds with that held value where it built with empty lists | The canvas and the composer already build with the held value; one snapshot cannot hold two answers. No test asserts the empty case (`evidenceGraphSnapshotReadsTheThreeKeys` fails the whole store, so the rows are nil) | Keeping two snapshots |
| D-13 | `EvidenceGraphModel`: `displaySnapshot` and `displayText` become computed properties with no arguments. `displaySnapshot` is `session.graphSnapshot(graphID:)`; `displayText` is `derived(.evidenceGraphText(graphID:), inputs: [graph, propertiesWorkspace, connectRules], extra: session.nameFormat)` building `EvidenceGraphText(snapshot: displaySnapshot, orders: session.nameFormat)`. `snapshotMemo` goes; the three view sites and `currentSnapshot()` read the properties | Its arguments were always the same handles' values (§4) | Keeping the arguments (they would be ignored) |
| D-14 | Composer: `vocabulary` is `derived(.citationComposerVocabulary(graphID:), inputs: [graphKey, fieldsKey, connectRulesKey] + termKeys(in: fields))` building `CitationComposerVocabulary.make` from `session.graphSnapshot(graphID:)`, the fields, the rules and each term key's value. `termRevisions(in:)` becomes `termKeys(in:) -> [CatalogQueryKey]` sorted by Property id (a stable input order). `graphSnapshot` reads the session's. `MemoToken`, `memo` and `built` go | Same inputs as today's token, one mechanism | — |
| D-15 | Sources: `visibleSources` is `derived(.visibleSources, inputs: [sources, types] + (filtersByStatus ? [graphs, progress] : []), extra: settings, Locale.autoupdatingCurrent.identifier)` building `buildVisibleSources()`. `VisibleRowsToken`, `visibleRowsMemo` and `visibleSourcesBuildCount` go; the test reads `session.derivedBuildCount(.visibleSources)` | A fifth hand memo of the same shape; leaving it is a second way (working rule "simpler code"). Added to the map's scope entry in this plan's commit | Leaving it on `Memo` |
| D-16 | `ConclusionPageSection.content<Value, Content>(_ role:, entityId:, session:, value:, extra: any Equatable..., make: (Value) -> Content) -> Content` *(new)* in `ConclusionPageSectionHost.swift`: `session.derived(.sectionContent(self, role, entityId:), inputs: reads(project:entityId:).map(\.key), extra:…) { make(value) }`. The host's `loaded(_:)` passes `{ section.content(read, entityId:, session:, value: $0, extra: extra, make: make) }` to the presentation | Testable without drawing the host (T-8); the inputs are the section's whole read list, so a builder may read any of them (Sources reads the supporting types; the record links read the claims' `graphLocations`) | Per-role input lists (a new switch for one extra rebuild when a companion reloads) |
| D-17 | The host gains `extra: [any Equatable] = []` in its init. Timeline passes `[folds, orders, widthClass, locale.identifier]`, Family `[folds, orders, locale.identifier]`, Sources rows `[folds, orders]`, record links `[]`. `locale` is `Locale.autoupdatingCurrent`, read once in the section's `body` and passed to `make` as today | These are every non-handle value each `make` captures (§4) | Leaving a captured value out (the content would not follow it) |
| D-18 | Tests for the primitive go in `macos/ProvenenciaTests/WorkspaceSessionDerivedTests.swift` *(new)* | `WorkspaceSessionTests.swift` is past 2,300 lines | Appending there |

**Rules this plan bends.** None. "(Batch 1) Refused: memoising and re-shaping for speed" and "(Batch 2) No new persisted projections, and no stored answer without a measurement" (its clause "A composed answer is memoised only after it measures slow") name this PR as the user's exception: Batch 2 builds every section's content once per value through one primitive, as cache architecture, not as a speed fix (user, 2026-11-08). The PR claims no speed, so "(Batch 2) Measure growth" sets no budget.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `WorkspaceSession+Derived.swift` *(new)*: `derived`, `carryDerived`, `derivedBuildCount` | file / func | `macos/App/Platform/Memo.swift` `Memo` | `Memo` holds one key per owner and leaves the key to each reader; the four readers each wrote a token. `derived` builds the key from the handles, so a reader names inputs only |
| `DerivedValueID` *(new)* | type | `CatalogQueryKey.Kind` | That enum names reads the registry loads; these are values built from them, with no loader |
| `DerivedValueStore` *(new)* | type | `WorkspaceSession.evidenceGraphIndex` + `evidenceGraphIndexBuildCount` | Replaces both with one store for every id |
| `QueryHandle.serial` *(new)* | property | `QueryHandle.revision` | Revision restarts on a new handle (D-2) |
| `WorkspaceSession.graphSnapshot(graphID:)` *(new)* | func | `evidenceGraphSnapshot(graphID:) async` | The async call awaits loads; the canvas and composer read synchronously in a body. The async call now returns this |
| `ConclusionPageSection.content(…)` *(new)* | func | `ConclusionPageSectionHost.make` | The host keeps `make`; this wraps it once |
| `CitationComposerContext.termKeys(in:)` | func (rename of `termRevisions(in:)`) | — | Returns keys, not revisions |
| `WorkspaceSessionDerivedTests` *(new)* | test file | `WorkspaceSessionTests` | D-18 |

**Builds on.** `WorkspaceSession`'s handles and `evict(_ key:)`; the section read list (S16-03); `ConclusionFoldState` (S16-07); the splice of S16-12.
**Deletes.** `WorkspaceSession.evidenceGraphIndex`, `evidenceGraphIndexBuildCount`; `EvidenceGraphIndex.revision`; `EvidenceGraphModel.snapshotMemo` and the `rows:types:` arguments of `displaySnapshot` and `displayText`; `CitationComposerContext.MemoToken`, `memo`, `built`; `SourcesModel.VisibleRowsToken`, `visibleRowsMemo`, `visibleSourcesBuildCount`; the four memo rows of `docs/catalog-caches.md`'s Swift table (Evidence-graph index, Visible Sources, Citation composer snapshot, Evidence-graph snapshot), replaced by one "Derived values" row.
**Next adds.** A new derived value is one `DerivedValueID` case and one `derived` call. S16-29's prefetch warms keys; a prefetched section's content is built on first draw and kept for the entity's lifetime. A later Event or Place section gets content once per change through the same host.

### Reach

None — no new path into existing code. A new state: a derived value outlives a view remount while its keys stay; a remounted section starts its folds empty, so its `extra` differs and it builds again, as today.

### Scale

At the map's Batch 2 Scale: the stamps are one dictionary lookup and two `Int` compares per input; the widest input list is the composer's (three keys plus one per term-valued Property, about 10 on the shipped vocabulary). `evict(_ key:)` scans the entries: at most four section entries per entity (51 entities kept), one snapshot, text and vocabulary per opened graph, and two catalog-wide entries — a few hundred compares per eviction. Memory: a section entry holds the content value already built today, now kept while its keys are held (50 hidden entities); a Timeline content holds only its shown rows (S16-02). The snapshot is shared by four readers where the canvas and the composer each held one. No write changes what it invalidates.

### Edges

- **Assumptions.** A handle's `revision` moves on every change of `value` (`markReplaced`, `applyFailure(clearValue: true)`, `resetForInvalidation`); `modifyValue` returning false changes nothing and moves nothing. T-2 holds an `apply` that refreshes an input. A build reads only its declared inputs and `extra`: the section builds read the value passed in, the section's supporting key and the captured extras (D-17); the composer reads its term keys; `buildVisibleSources` reads `sources`, the types, graph statuses (only under a status filter, as today's token) and `searchKeys`, a per-row cache keyed by row revision.
- **Neighbors.** Same stamps and same `extra` → stored value (AC-1.1); one input moved → build (AC-1.2); a non-input moved → stored (AC-1.3); `extra` moved → build (AC-1.4); handle replaced at the same revision → build (AC-1.5, T-3). A carry when another input also moved → no carry, the next read builds (T-4).
- **Removed inputs.** An evicted key drops every entry built from it (AC-1.6, T-5). A section whose read goes to `.gone` or `.failed` never calls `content`; the entry stays until its key is evicted. A deleted graph's snapshot entries drop when its `evidenceGraph` key is evicted.
- **Real data.** None — no table- or seed-driven rule.
- **Untrusted size.** None — the primitive adds no fan-out over data; each build costs what it costs today, at most once per change.

### Schema

None — no catalog change.

### Go core

None — Swift only.

### FFI

None — Swift only.

### macOS

```swift
// WorkspaceSession+Derived.swift (new)
enum DerivedValueID: Hashable {
    case evidenceGraphIndex
    case evidenceGraphSnapshot(graphID: String)
    case evidenceGraphText(graphID: String)
    case citationComposerVocabulary(graphID: String)
    case visibleSources
    case sectionContent(ConclusionPageSection, ConclusionSectionRead.Role, entityId: String)
}

struct DerivedValueStore {
    struct Stamp: Equatable { let key: CatalogQueryKey; let serial: Int; let revision: Int }
    struct Entry { var stamps: [Stamp]; var extra: [any Equatable]; var value: Any }
    var entries: [DerivedValueID: Entry] = [:]
    var builds: [DerivedValueID: Int] = [:]
    mutating func drop(reading key: CatalogQueryKey)
}

extension WorkspaceSession {
    func derived<Value>(_ id: DerivedValueID, inputs: [CatalogQueryKey], extra: any Equatable..., build: () -> Value) -> Value
    func carryDerived<Value>(_ id: DerivedValueID, across key: CatalogQueryKey, from previousRevision: Int, _ change: (Value) -> Value)
    func derivedBuildCount(_ id: DerivedValueID) -> Int
}
```

`derived` reads each input's handle through `handles[key]` (observed, so a view that reads a derived value observes its handles' revisions). A `derived` overload taking `extra: [any Equatable]` serves the host, which holds its extras as an array; the variadic form forwards to it.

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Section content | `ConclusionPageSectionHost` (existing) | `macos/App/Features/Conclusions/ConclusionPageSectionHost.swift` | Gains `extra`; draws as today |

States: unchanged in every view. Accessibility: unchanged.

### Strings

None — no copy changes.

## 7. Steps

`XT` below is `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO`, the command `scripts/check-pr.sh` runs, narrowed with `-only-testing:`.

**STEP-1 — The primitive**
Files: `macos/App/Features/Workspace/Session/WorkspaceSession+Derived.swift` *(new)*, `QueryHandle.swift`, `WorkspaceSession.swift`, `macos/App/Features/Workspace/ConclusionPageSection.swift` (`Role: Hashable`), `macos/ProvenenciaTests/WorkspaceSessionDerivedTests.swift` *(new)*. Skill: `add-swift-test`.
Do: D-1 – D-9: `serial`, the protocol members, the store on the session, `derived`, `carryDerived`, `derivedBuildCount`; `evict(_ key:)` calls `derivedValues.drop(reading: key)`. Write T-1 – T-5.
Check: `XT -only-testing:ProvenenciaTests/WorkspaceSessionDerivedTests` passes.

**STEP-2 — The Evidence graph index**
Files: `WorkspaceSession+EvidenceGraphs.swift`, `WorkspaceSession.swift`, `CatalogQueryRegistry.swift` (only if the splice call's signature moves), `WorkspaceSessionTests.swift`.
Do: D-10. Remove `evidenceGraphIndex` and `evidenceGraphIndexBuildCount`; `graphListMergeSplicesTheIndex` reads `derivedBuildCount(.evidenceGraphIndex)`.
Check: `XT -only-testing:ProvenenciaTests/WorkspaceSessionTests` passes, `evidenceGraphIndexFollowsTheListRevision` and `graphListMergeSplicesTheIndex` included; `rg 'evidenceGraphIndexBuildCount|evidenceGraphIndex\b' macos` finds nothing.

**STEP-3 — One graph snapshot**
Files: `WorkspaceSession+EvidenceGraphs.swift`, `EvidenceGraphModel.swift`, `EvidenceGraphView.swift`, `WorkspaceSessionTests.swift`, `EvidenceGraphModelTests.swift`, `PromoteModelTests.swift`.
Do: D-11 – D-13. Rewrite `displayTextFollowsTheSnapshot` to set the rows with `session.setQueryValue(graphKey, value:)` (T-7). Extend `evidenceGraphSnapshotReadsTheThreeKeys` (T-6); add T-9.
Check: `XT -only-testing:ProvenenciaTests/WorkspaceSessionTests -only-testing:ProvenenciaTests/EvidenceGraphModelTests -only-testing:ProvenenciaTests/PromoteModelTests -only-testing:ProvenenciaTests/UnpromoteFlowTests` pass; `rg snapshotMemo macos` finds nothing.

**STEP-4 — The composer's vocabulary**
Files: `CitationComposerContext.swift`, `CitationComposerModelTests.swift`.
Do: D-14. Add T-10.
Check: `XT -only-testing:ProvenenciaTests/CitationComposerModelTests -only-testing:ProvenenciaTests/CitationComposerDepictionTests` pass; `rg MemoToken macos` finds nothing.

**STEP-5 — Visible Sources**
Files: `SourcesModel.swift`, `SourcesModelTests.swift`.
Do: D-15; the test at line 295 reads `session.derivedBuildCount(.visibleSources)` (T-11).
Check: `XT -only-testing:ProvenenciaTests/SourcesModelTests` passes; `rg 'visibleRowsMemo|visibleSourcesBuildCount|VisibleRowsToken' macos` finds nothing.

**STEP-6 — Section content**
Files: `ConclusionPageSectionHost.swift`, `PersonTimelineSection.swift`, `PersonFamilySection.swift`, `PersonSourcesSection.swift`, `macos/ProvenenciaTests/ConclusionPageSectionContentTests.swift` *(new)*.
Do: D-16, D-17. Add T-8.
Check: `XT -only-testing:ProvenenciaTests/ConclusionPageSectionContentTests` passes, and the Person content tests (`PersonTimelineContentTests`, `PersonFamilyContentTests`, `PersonSourcesContentTests`, `PersonRecordLinksContentTests`) pass unchanged.

**STEP-7 — Docs**
Files: `docs/catalog-caches.md` (Swift caches: one "Derived values" row — owner `WorkspaceSession+Derived.swift` · `derived`, key `DerivedValueID`, fill the caller's build, updated by its inputs' handle serial and revision and its `extra`, lifetime its inputs' handles, cap none of its own; the four memo rows go; the Depiction preview row stays), `docs/macos-client-patterns.md` (Cache contract rule 5: a view derives display values with `session.derived`, naming its input keys and extras, and writes no token), `.agents/skills/add-workspace-place/SKILL.md` (step 5 "Model rules": one line on `derived`, one on adding a `DerivedValueID` case), `completed.md`, `deployment-plan.md` (map row), this plan.
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-27-derived-values.md` reports no errors; `scripts/check-guidance-names.py` passes.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `WorkspaceSessionDerivedTests.swift` `aValueBuildsOncePerInputRevision` *(new)* | `setQueryValue(key)`; three reads → 1 build | AC-1.1, D-1 |
| T-2 | Swift | same file, `anApplyThatRefreshesAnInputBuildsAgain` *(new)* | A FakeStore-backed key refreshed by `session.apply(effects)` → 2 builds; a write refreshing another key → still 2; a different `extra` → 3, again → 3 | AC-1.2, AC-1.3, AC-1.4, D-3 |
| T-3 | Swift | same file, `aReplacedHandleNeverMatches` *(new)* | A per-entity key evicted by `apply` with its id in `deleted`, loaded again to revision 1 → the next read builds | AC-1.5, D-2 |
| T-4 | Swift | same file, `aCarryMovesTheValueOnlyWhenItsKeyAloneMoved` *(new)* | Carry across key A from its previous revision → no build and the changed value; carry when key B also moved → no carry, next read builds | D-9 |
| T-5 | Swift | same file, `anEvictedInputDropsTheValue` *(new)* | Entry built from a per-entity key; the hidden-entity cap evicts it → the next read builds | AC-1.6, D-5 |
| T-6 | Swift | `WorkspaceSessionTests.swift` `evidenceGraphSnapshotReadsTheThreeKeys` (extended) | Two awaits, no write → `derivedBuildCount(.evidenceGraphSnapshot(graphID: "g1")) == 1`; after the reload → 2 and the new rows | AC-2.2, D-11 |
| T-7 | Swift | `EvidenceGraphModelTests.swift` `displayTextFollowsTheSnapshot` (rewritten) | Rows set on the session; "Wm Robins" → "William Robins" after the rows change; two reads between writes → one text build | AC-2.4, D-13 |
| T-8 | Swift | `ConclusionPageSectionContentTests.swift` `contentBuildsOncePerReadAndFold` *(new)* | Timeline section, `personEvents` key set; `content` read three times → 1 `make`; `folds.revealPage` → 2; `apply` refreshing the person's events → 3; a write to another person → 3 | AC-2.7, D-16, D-17 |
| T-9 | Swift | `PromoteModelTests.swift` `reproposingReusesTheGraphSnapshot` *(new)* | `load()`, then one decision that reproposes → `derivedBuildCount(.evidenceGraphSnapshot(graphID:)) == 1` | AC-2.3, D-11 |
| T-10 | Swift | `CitationComposerModelTests.swift` `aTermWriteRebuildsTheVocabularyOnce` *(new)* | A term added through `apply` → vocabulary builds once more and offers the term; an unrelated write → no build | AC-2.5, D-14 |
| T-11 | Swift | `SourcesModelTests.swift` (the test at line 295, its build count read changed) | Sort changed → one build; rows in date order | AC-2.6, D-15 |
| T-12 | Swift | `WorkspaceSessionTests.swift` `graphListMergeSplicesTheIndex` (count read changed) | Merge → `derivedBuildCount(.evidenceGraphIndex)` unchanged; lookups right | AC-2.1, D-10 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `WorkspaceSessionTests`, `EvidenceGraphModelTests`, `CitationComposerModelTests`, `UnpromoteFlowTests`, `PromoteModelTests`, `SourcesModelTests`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — or none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated)
- [ ] Domain doc updated if a rule in docs/*.md changed: docs/catalog-caches.md Swift table, docs/macos-client-patterns.md Cache contract rule 5
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Open a project with a person in at least 50 events. Open the person on Timeline, press Show more twice, resize across 1600 pt: rows and lifeline as before each unfold and at each width.
2. Same person: Family, then Sources. Hover a graph on the record links diagram: its line lights as before. Rename a Source in another window: the Sources row shows the new title.
3. Open an Evidence graph, rename a Subject: the card shows the new name. Drag a card: it moves as before.
4. Open the citation composer on that graph and add a term to a term-valued Property in Properties: the composer offers it.
5. Promote a Subject, decide one row: the proposal updates. Unpromote a record with a bridge: the confirm lists the connection.
6. Sources list: change sort, filter by type and by status, type in search: rows as before.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A build reads a handle it does not declare, so it shows stale data | Edges lists every read; the reviewer checks each `build` against its `inputs` |
| SwiftUI reports "Modifying state during view update" | The store is `@ObservationIgnored` (D-8) |
| A nested `derived` call corrupts the store | D-8's read-release-build-write order; T-10 runs a nested build |

**Stop and report if:**

- A `QueryHandle` path changes `value` without moving `revision` (any setter of `storedValue` other than those §4 names).
- A section's `make` captures a value §4 and D-17 do not list.
- `graphListMergeSplicesTheIndex` cannot pass with `carryDerived` as D-9 states it.
- An existing behavior test (not a build-count read) has to change its expected result, other than through D-12.
- Swift rejects the opened-existential compare of D-3 on the project's toolchain.

## 12. Open questions

None.

## 13. PR

**Title:** S16-27 — One primitive for values derived from cached data
**Body:** objective in one sentence; what shipped against US-1 and US-2; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-27-derived-values.md`.
