# S16-27 — One primitive for values derived from cached data

**Status:** Planned
**Spike / slice:** Spike 16 · Slice 2e — The app's cache
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: every view draws the same content; only how often the app builds it changes)
**Board:** —
**Depends on:** S16-03 (landed [#769](https://github.com/mendahu/provenencia/pull/769): one list of section reads), S16-07 (landed [#761](https://github.com/mendahu/provenencia/pull/761): `ConclusionFoldState`, one fold state per section)
**Blocks:** —
**Branch:** `s16-27-derived-values`
**Version bump:** patch, 0.15.4 → 0.15.5 — the app builds what it derives for display once per change of its inputs; nothing new on screen ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/macos-client.mdc`, `.cursor/rules/swift-tests.mdc`
**Context:** [design § Swift](../cache-architecture.md#swift) ("One primitive for derived values"); [`docs/macos-client-patterns.md`](../../../macos-client-patterns.md) "Cache contract" rule 5; [`docs/catalog-caches.md`](../../../catalog-caches.md) "Swift caches"; working rules: "(Batch 2) The point of this batch is simpler code", "(Batch 2) Swift caches one value per view, follows its inputs and shows it stale while refreshing", "(Batch 1) Refused: memoising and re-shaping for speed" (its Batch 2 clause names this PR), "(Batch 2) No new persisted projections, and no stored answer without a measurement"; goal bar 15's last clause
**Planned:** 2026-11-15 against `main` @ `1f52b60`
**Review:** [`S16-27-derived-values.review.md`](S16-27-derived-values.review.md) — round 1: Fits with changes / Ready with changes; round 2: Fits with changes / Not ready, every finding Fixed; To user answered (2026-11-15); Planned

**Base.** Compare against `origin/main` (fetch it first); `1f52b60` is the planned commit.

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

The app derives display values from cached reads in four hand-written ways (the Evidence graph index's revision bookkeeping, `EvidenceGraphModel`'s tuple memo, which compares whole row arrays on every read, `CitationComposerContext`'s `MemoToken`, `SourcesModel`'s `VisibleRowsToken`) and, for the rest, with no memo at all: Promote and Unpromote build the Evidence graph snapshot on every call, and a Conclusion page's detail content and each Person section's content are built on every pass of their host's body. This PR gives `WorkspaceSession` one primitive, `derived`, that builds a value once per change of the reads it names and of the plain values it is given (fold state, name orders, width class, locale), and moves every one of those onto it. A reader then names its inputs and its build, and nothing else.

**Why now.** Bar 15's last clause ("every value the app derives from cached data is built once per change of its inputs") and the map row. S16-03 gave each section one list of reads and S16-07 one `Equatable` fold state, so a section's inputs can now be named.

**What stays.** Every view draws what it draws today. The query cache, its keys, `followsInputs` and the hidden-entity cap are unchanged. `Memo` stays as the one-slot store the primitive is built on.

## 2. User stories

**US-1.** As a contributor, when a view derives a value from cached reads, I name its inputs and its build in one call, so that it is built once per change of those inputs and I write no revision bookkeeping.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A key holds a value; `derived(.visibleSources, inputs: [.key(key)])` is read three times | the build ran once; `derivedBuildCount(.visibleSources) == 1` |
| AC-1.2 | Then `session.apply(effects)` refreshes that key and the value is read again | two builds in all |
| AC-1.3 | Then a write refreshes another key that is not an input, and the value is read again | still two builds |
| AC-1.4 | Then the same read passes a different `extra` (another `Int`) | three builds; reading again with that `extra` keeps three |
| AC-1.5 | A key read by an entry is evicted (a deleted handle), then loaded again | the entry is gone with the key; the next read builds |
| AC-1.6 | Value B names `.derived(A)` as an input; A's key moves; B is read | A and B each build once more |
| AC-1.7 | In a debug build, a build reads a key through `queryHandle` that its inputs do not name | `assertionFailure` names the id and the key |

**US-2.** As a researcher, every view that moved draws the same thing it drew before.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | The Evidence graph list merges one Source's re-read | the index takes that Source's graphs in place; no full build (`derivedBuildCount(.evidenceGraphIndex)` unchanged); lookups by id, by Source and the linked Artifacts are right |
| AC-2.2 | `evidenceGraphSnapshot(graphID: "g1")` awaited twice with no write between | one build of `.evidenceGraphSnapshot(graphID: "g1")`; after the graph's rows reload, the next call builds once more and shows the new rows |
| AC-2.3 | Promote loads, then reproposes after a decision, the graph unchanged | the graph snapshot was built once |
| AC-2.4 | The Evidence graph canvas: a Subject relabelled from "Wm Robins" to "William Robins" (rows set again) | `displayText` names "William Robins"; reading `displayText` twice between writes builds it once |
| AC-2.5 | The citation composer: a term added to a term-valued Property (its `propertyTerms` key reloads) | the vocabulary rebuilds once and offers the new term; a write to an unrelated key rebuilds nothing |
| AC-2.6 | The Sources list: sort changed from A–Z to date oldest | one build; the rows are in date order as today |
| AC-2.7 | A Person's Timeline section: its content read three times between writes, then one Show more | one build, then one more for the new fold state; a reload of the person's events builds once more |
| AC-2.8 | A Person page's detail content read three times between writes, then the name format changes | one build, then one more |

## 3. Scope

| In | Covered by |
| --- | --- |
| `WorkspaceSession.derived(_:inputs:extra:build:)`, `carryDerived`, `derivedBuildCount`, `DerivedValueID`, `DerivedInput`, `DerivedStamp` *(new)*; entries drop with an evicted key; a debug check that a build reads only its declared keys | STEP-1, AC-1.1 – AC-1.7 |
| The Evidence graph index moves onto it (the splice through `carryDerived`); `evidenceGraphIndex`, `evidenceGraphIndexBuildCount` and `EvidenceGraphIndex.revision` go | STEP-2, AC-2.1 |
| One graph snapshot per graph (`cachedEvidenceGraphSnapshot(graphID:)`), read by `evidenceGraphSnapshot(graphID:)` (Promote, Unpromote), `EvidenceGraphModel` and the composer; `EvidenceGraphModel.snapshotMemo` goes | STEP-3, AC-2.2 – AC-2.4 |
| The composer's vocabulary moves onto it; `MemoToken`, `memo`, `built` and `termRevisions` go | STEP-4, AC-2.5 |
| The visible Sources move onto it; `visibleRowsMemo`, `visibleSourcesBuildCount` and `VisibleRowsToken` go | STEP-5, AC-2.6 |
| The detail page and the section host build content through one `conclusionContent` call; the four section sites and the three detail sites pass their extras | STEP-6, AC-2.7, AC-2.8 |
| `catalog-caches.md`, `macos-client-patterns.md` rule 5 and `add-workspace-place` teach it | STEP-7 |

| Out | Home |
| --- | --- |
| Engine-side memos | not planned (map scope entry: "Not this PR") |
| `PropertiesModel.visibleProperties`, `SourceTypesModel.visibleTypes`, `MetadataModel.visibleFields` (sort a vocabulary list on each read; no memo today) | not planned: each list holds tens of rows in practice (user, 2026-11-15) |
| `SourcesModel.searchKeyCache` (per-row keys by row revision) | not planned: a per-row cache, not a derived value of whole reads |
| Prefetching sections | S16-29 |
| Lazy Timeline cards, participants sent once (P-7, P-8) | [person page performance idea](../../../ideas/person-page-performance.md) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Handle revision | `macos/App/Features/Workspace/Session/QueryHandle.swift` `QueryHandle.revision`, `markReplaced`, `applyFailure`, `resetForInvalidation` | Bumps on every replace or clear of `value`; a new handle starts at 0 |
| Erased handle | same file, `protocol AnyQueryHandle` (line 203) | `isStale`, `hasValue`, `isFetching`, stale and refresh calls; no revision |
| Handles map | `macos/App/Features/Workspace/Session/WorkspaceSession.swift` `private var handles` (line 16), `queryHandle(_:)` (line 72), `typedHandle` (line 561) | Private to the file; a handle is created only for a key with none |
| Eviction | same file, `evict(_ key:)` (line 533); `trimHiddenEntities`, `evict(_:ids:)` | The one place a handle leaves the map; the hidden-entity cap and deletes both go through it |
| Index storage | same file, `evidenceGraphIndex`, `evidenceGraphIndexBuildCount` (lines 34–42) | Two `@ObservationIgnored` stored properties for one memo |
| Index | `macos/App/Features/Workspace/Session/WorkspaceSession+EvidenceGraphs.swift` `EvidenceGraphIndex` (carries `revision`; its doc says "Valid for one handle revision"), `currentEvidenceGraphIndex` (returns `EvidenceGraphIndex?`), `spliceEvidenceGraphIndex(_:previousRevision:)` | Hand revision check; a merged re-read splices when the merge was the only revision move |
| Splice caller | `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift` `.evidenceGraphsList` `afterMerge` (line 406) | Calls `spliceEvidenceGraphIndex(parts, previousRevision:)` |
| Snapshot (async) | `WorkspaceSession+EvidenceGraphs.swift` `evidenceGraphSnapshot(graphID:)` | Awaits the graph, properties and rules keys, then builds `EvidenceGraphSnapshot.build` every call; nil when the rows are nil, empty types or rules when theirs are |
| Promote | `macos/App/Features/Promote/PromoteModel.swift` `load()` (line 157), the propose loop (line 269) | Builds the snapshot on every load and every repropose |
| Unpromote | `macos/App/Features/Catalog/Unpromote/UnpromoteFlow.swift` `open` (line 131) | Builds the snapshot on each open with bridges |
| Canvas snapshot | `macos/App/Features/EvidenceGraph/EvidenceGraphModel.swift` `snapshotMemo` (line 50), `displaySnapshot(rows:types:)`, `displayText(rows:types:)` (lines 241–266), `currentSnapshot()` (line 1371); `graphKey`, `fieldsKey` are private | A tuple memo compared by whole `rows`, `types` and `rules` equality and the name orders on every read; text formatted with it |
| Canvas callers | `macos/App/Features/EvidenceGraph/EvidenceGraphView.swift` lines 112, 777, 790; doc link in `macos/App/Features/EvidenceGraph/EvidenceCardText.swift` line 9 | Pass `graphHandle.value` and `fieldsHandle.value?.types` in |
| Composer | `macos/App/Features/CitationComposer/CitationComposerContext.swift` `MemoToken`, `memo`, `built`, `termRevisions(in:)`, `graphSnapshot`, `vocabulary` | A `Memo` over a revision token of graph, fields, rules and each term list; builds its own snapshot beside the canvas's |
| Visible Sources | `macos/App/Features/Sources/SourcesModel.swift` `VisibleRowsToken`, `visibleRowsMemo`, `visibleSourcesBuildCount`, `visibleSources` (lines 259–294); `graphsHandle` is private | A `Memo` over a revision token of sources, types and (under a status filter) graphs and progress, plus settings and locale |
| Memo | `macos/App/Platform/Memo.swift` `Memo` | One-slot memo with `value(for:)`, `store(_:for:)`; used by the composer, the visible Sources and `CitationComposerModel.depictionPreviewMemo` |
| Detail page | `macos/App/Features/Conclusions/ConclusionDetailPage.swift` `ConclusionDetailPage.make`, `ConclusionDetailLoaded.presentation` (line 279) | `ConclusionDetailPresentation(handle.reading, …, content: make)` calls `make` on every body pass |
| Detail sites | `PersonDetailView.swift` line 18, `EventDetailView.swift` line 19 (`make` captures `session.nameFormat`), `PlaceDetailView.swift` line 18 (captures nothing) | Each builds a content value per pass |
| Section host | `macos/App/Features/Conclusions/ConclusionPageSectionHost.swift` `loaded(_:)` | Same presentation call: `make` on every body pass |
| Section sites | `PersonTimelineSection.swift` (`make` captures folds, orders, width class and reads `.autoupdatingCurrent` inside the closure), `PersonFamilySection.swift` (folds, orders, `.autoupdatingCurrent` inside the closure), `PersonSourcesSection.swift` line 36 (claims groups, the supporting Source types handle, orders, folds) and line 201 (record links with `content.graphLocations`, which depends on the claims groups only) | Each builds a content value per pass |
| Section reads | `macos/App/Features/Workspace/ConclusionPageSection.swift` `reads(project:entityId:)` | One list per section: own, companion, supporting |
| Tests | `macos/ProvenenciaTests/WorkspaceSessionTests.swift` `evidenceGraphIndexFollowsTheListRevision`, `evidenceGraphSnapshotReadsTheThreeKeys`, `graphListMergeSplicesTheIndex`, `deletedEntitiesLoseTheirHiddenKeys` (line 1353), `hiddenConclusionPagesAreCappedAtFifty` (line 1457); `EvidenceGraphModelTests.swift` `displayTextFollowsTheSnapshot`, `makeModel`; `SourcesModelTests.swift` (two tests read `visibleSourcesBuildCount`: lines 295–318 and 455–497); `PromoteModelTests.swift`; `UnpromoteFlowTests.swift`; `CitationComposerModelTests.swift` | Cover today's memos and their behavior |

**Precedent.** `SourcesModel.visibleSources` is the shape to copy for a call: handle revisions plus plain values, built in a closure, a build counter for tests. `spliceEvidenceGraphIndex` (S16-12, [#800](https://github.com/mendahu/provenencia/pull/800)) is the shape `carryDerived` keeps. Go's `graphcache` `DerivedFrom` (an entry derived from another entry) is the shape `DerivedInput.derived` copies. Do not copy `EvidenceGraphModel.snapshotMemo`'s comparison of whole values.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | One primitive, in `macos/App/Features/Workspace/Session/WorkspaceSession+Derived.swift` *(new)*: `func derived<Value>(_ id: DerivedValueID, inputs: [DerivedInput], extra: (any Equatable)? = nil, build: () -> Value) -> Value`. On a read it validates the entry (D-2); on a hit it returns the stored value; on a miss it runs `build`, then takes the stamp (after the build, so a child the build created is stamped at its new version), stores the value, bumps the entry's version and counts a build. One signature; `extra` is one value | Map row; one way for every reader. A site with several plain inputs passes one small `Equatable` struct, as `SourcesListSettings` already is | A variadic or array `extra` (a second list per site, compared pairwise) |
| D-2 | `enum DerivedInput: Equatable { case key(CatalogQueryKey); case derived(DerivedValueID) }` *(new)*. Validating an entry stamps each input now: a `.key` is its handle's `revision`, or -1 when the key has no handle; a `.derived(child)` is the child's `version` when the child entry exists and is itself valid (recursively), else the parent misses. The entry is valid when that stamp and `extra` equal the stored ones. Worked example (T-6): B reads `.derived(A)`, A reads key K. First read of B: no entry → B builds, its build calls `derived(A)` → A builds (A version 1) → B stamps A at 1. Second read: A valid, version 1 → B hits (A 1 build, B 1). `setQueryValue(K)`: A invalid → B misses → B builds, calls A → A builds (version 2) → B stamps 2 (A 2, B 2) | One input list per value: the text and the vocabulary name the snapshot, as Go's `DerivedFrom` names another entry | Copying the snapshot's keys into each dependant; recording reads as the only input source (the hosts get their value from outside the build) |
| D-3 | No handle serial. A stale match across a dropped and re-created handle cannot happen: `evict(_ key:)` is the only place a handle leaves the map, and it drops every entry that reads the key (D-6). `typedHandle` replacing a handle bound to another value type is a programming error (it asserts in Debug) and is not such a place | One rule instead of two | `QueryHandle.serial` (a global counter guarding a case D-6 already removes) |
| D-4 | `AnyQueryHandle` gains `var revision: Int { get }`. `WorkspaceSession.swift` gains an internal `func inputRevision(_ key: CatalogQueryKey) -> Int` (`handles[key]?.revision ?? -1`), so `handles` stays private; it reads `handles`, so a view that reads a derived value observes its inputs | `handles` is private (line 16) and cannot be reached from the new file | Widening `handles` |
| D-5 | `struct DerivedStamp: Equatable` *(new)* holds `inputs: [Int]` and `extra: (any Equatable)?`; its `==` compares `inputs`, then `extra` (both nil, or both set and equal through one opened-existential compare: `(rhs as? T) == lhs`). Each entry keeps its value in a `Memo<DerivedStamp, Any>` (D-9) | `Memo` is already the one-slot store with `value(for:)` and `store(_:for:)`; reuse it | A new one-slot type; `AnyHashable` extras (conformances on several types for no reader) |
| D-6 | An entry lives as long as its inputs: `dropDerived(reading key: CatalogQueryKey)` *(new, internal, in `WorkspaceSession+Derived.swift`)* removes every entry whose `inputs` contain `.key(key)`, then, repeated until nothing more is removed, every entry whose `inputs` contain `.derived` of a removed id. `evict(_ key:)` calls it after `handles[key] = nil`. No cap of its own | The per-entity keys' 50-entity cap and deletes bound the content entries; the others are one per graph or catalog-wide | A separate cap |
| D-7 | `DerivedValueID` *(new)* is one closed enum beside the primitive: `evidenceGraphIndex`, `evidenceGraphSnapshot(graphID:)`, `evidenceGraphText(graphID:)`, `citationComposerVocabulary(graphID:)`, `visibleSources`, `conclusionContent(CatalogQueryKey)`. Nothing switches on it | One registry names every derived value. A content value is keyed by the read its host draws: each host draws one key, so the detail page and each section host have distinct ids | An open `String` name; a struct of kind and ids as `CatalogQueryKey` became in S16-25 (that shape served the registry's switches; nothing switches here) |
| D-8 | A stored value whose type is not the caller's `Value` fails `preconditionFailure("DerivedValueID \(id) holds \(type(of: stored)), not \(Value.self)")` | Each id has one value type, as `query(_:)` treats a key | Silent rebuild |
| D-9 | `WorkspaceSession.swift` gains, in the class body: `@ObservationIgnored var derivedEntries: [DerivedValueID: DerivedEntry] = [:]`, with `struct DerivedEntry { var memo: Memo<DerivedStamp, Any>; var inputs: [DerivedInput]; var version: Int }` *(new, in `WorkspaceSession+Derived.swift`)*; `@ObservationIgnored var derivedBuilds: [DerivedValueID: Int] = [:]`; `@ObservationIgnored var derivedReads: [Set<CatalogQueryKey>] = []`. All three are internal with an internal setter (no `private(set)`), so `WorkspaceSession+Derived.swift` writes them. `derivedBuildCount(_:)` returns `derivedBuilds[id] ?? 0`; `dropDerived` does not reset it. `derived` reads the entry, releases it, runs `build`, then writes: a build may call `derived` for another id | One record per entry, removed in one place; filling while a view reads must not invalidate the view (as `evidenceGraphIndex` today); nested builds must not hold the dictionary | Parallel dictionaries per field (they can fall out of step); observed storage |
| D-10 | Debug check: in `#if DEBUG`, `derived` pushes an empty set on `derivedReads` before `build` and pops it after; `queryHandle(_:)` inserts its key into the top set when one is pushed. After the build, a key in the set that is not a `.key` input fails `assertionFailure("DerivedValueID \(id) read \(key), which its inputs do not name")`. A nested `derived` call has its own set. Every content builder reads its handles inside `make` (D-19), so the check sees them | A build that reads an undeclared key shows stale data; the check finds it | Leaving it to review |
| D-11 | `carryDerived<Value>(_ id:, across key:, from previousRevision: Int, _ change: (Value) -> Value)` *(new)*. It does nothing when there is no entry. It carries when the entry's stamp for `.key(key)` is `previousRevision`, the handle now stands at `previousRevision + 1`, and every other input's stamp is unchanged (none, for the index). It ignores `extra` and keeps the stored one. It stores `change(old)` under the new stamp and bumps the version; a carry is not a build | Keeps S16-12's splice (AC-2.1) with no bookkeeping in the reader | Dropping the splice (a full index build over 10,000 graphs on each graph write) |
| D-12 | `EvidenceGraphIndex` loses `revision`; `replacing(sources:)` loses its `revision:` argument; its doc says it is built from one value of the graph list. `currentEvidenceGraphIndex` returns nil while the list handle has no value, else `derived(.evidenceGraphIndex, inputs: [.key(evidenceGraphsKey)]) { EvidenceGraphIndex(rows: rows) }` with `Value == EvidenceGraphIndex` (not optional). `spliceEvidenceGraphIndex` becomes `carryDerived(.evidenceGraphIndex, across: evidenceGraphsKey, from: previousRevision) { (index: EvidenceGraphIndex) in index.replacing(sources: parts) }`; the registry's `afterMerge` call is unchanged | Map row; the optional stays outside the primitive, so the carry and the read agree on the type | Storing `EvidenceGraphIndex?` |
| D-13 | `evidenceGraphSnapshotKeys(graphID:) -> [CatalogQueryKey]` *(new, private to `WorkspaceSession+EvidenceGraphs.swift`)*: the graph, `propertiesWorkspace` and `connectRules` keys. `cachedEvidenceGraphSnapshot(graphID:) -> EvidenceGraphSnapshot` *(new)*: `derived(.evidenceGraphSnapshot(graphID:), inputs: evidenceGraphSnapshotKeys(graphID:).map(DerivedInput.key))` building from each handle's value (missing rows → `EvidenceGraphRows(graphId:)`, missing types or rules → empty; nothing is warmed). `evidenceGraphSnapshot(graphID:) async` warms and awaits the same three keys, returns nil when the rows' `readyValue` is nil, else `cachedEvidenceGraphSnapshot(graphID:)` | One build per graph per change, shared by Promote, Unpromote, the canvas and the composer; the key list written once in its file. The `cached` prefix says it neither loads nor waits | One snapshot per reader (today) |
| D-14 | Behavior change: when the types or rules key failed or stayed stale behind a value, `evidenceGraphSnapshot` now builds with that held value where it built with empty lists | The canvas and the composer already build with the held value; one snapshot cannot hold two answers. No test asserts the empty case (`evidenceGraphSnapshotReadsTheThreeKeys` fails the whole store, so the rows are nil) | Keeping two snapshots |
| D-15 | `EvidenceGraphModel`: `displaySnapshot` and `displayText` become computed properties with no arguments. `displaySnapshot` is `session.cachedEvidenceGraphSnapshot(graphID:)`: with no graph handle it is the empty snapshot, as `displaySnapshot(rows: nil, …)` is today. `displayText` is `derived(.evidenceGraphText(graphID:), inputs: [.derived(.evidenceGraphSnapshot(graphID:))], extra: session.nameFormat) { EvidenceGraphText(snapshot: displaySnapshot, orders: session.nameFormat) }`. `currentSnapshot()` keeps its `guard` returning nil when the graph handle is missing, then returns `displaySnapshot`. `snapshotMemo` goes; the three view sites read the properties; the model's `connectRules` and `fieldsSnapshot` stay for their other readers; `EvidenceCardText.swift`'s doc link names ``EvidenceGraphModel/displayText`` | Its arguments were always the same handles' values (§4) | Keeping the arguments |
| D-16 | Composer: `vocabulary` is `derived(.citationComposerVocabulary(graphID:), inputs: [.derived(.evidenceGraphSnapshot(graphID:)), .key(fieldsKey), .key(connectRulesKey)] + termKeys(in: fields).map(DerivedInput.key))` building `CitationComposerVocabulary.make` from `session.cachedEvidenceGraphSnapshot(graphID:)`, the fields, the rules and each term key's value. `fields` is read before the call, from `fieldsKey`'s handle. `termRevisions(in:)` becomes `termKeys(in:) -> [CatalogQueryKey]`: the term-valued Property ids sorted as strings, each mapped to `.propertyTerms(project:propertyId:)`. `graphSnapshot` returns `session.cachedEvidenceGraphSnapshot(graphID:)`. `MemoToken`, `memo` and `built` go | Same inputs as today's token, one mechanism | — |
| D-17 | Sources: `visibleSources` is `derived(.visibleSources, inputs: [.key(Self.sourcesListKey(for: session)), .key(session.sourceTypesKey)] + (filtersByStatus ? [.key(session.evidenceGraphsKey), .key(session.evidenceGraphProgressKey)] : []), extra: VisibleRowsInputs(settings: settings, locale: Locale.autoupdatingCurrent.identifier)) { buildVisibleSources() }`. `VisibleRowsToken` becomes `VisibleRowsInputs` (its two non-revision fields only); `visibleRowsMemo` and `visibleSourcesBuildCount` go; both tests that read the counter read `session.derivedBuildCount(.visibleSources)` with their expected counts unchanged | The same shape as the others; leaving it is a second way (working rule "simpler code"). Added to the map's scope entry with this plan | Leaving it on its own token |
| D-18 | Content: `func conclusionContent<Value, Extra: Equatable, Content>(_ key: CatalogQueryKey, inputs: [CatalogQueryKey], extra: Extra, value: Value, make: (Value, Extra) -> Content) -> Content` *(new)* in `WorkspaceSession+Derived.swift` is `derived(.conclusionContent(key), inputs: inputs.map(DerivedInput.key), extra: extra) { make(value, extra) }`. The section host calls it with its existing `key` (`section.read(read, …)`) and `inputs: section.reads(project: session.projectKey, entityId: entityId).map(\.key)`; `ConclusionDetailLoaded.presentation` calls it with its existing `key` and `inputs: [key]` | One path for both hosts, which share `ConclusionDetailPresentation`; testable without drawing a view (T-8). A section's inputs are its whole read list, so a builder may read any of them | Per-role input lists; leaving the detail page out (bar 15) |
| D-19 | `make` reads nothing but its two arguments and handles it fetches with `session.queryHandle` inside the closure. `ConclusionPageSectionHost` gains a generic `Extra: Equatable`, `extra: Extra` and `make: (Value, Extra) -> Content`. `ConclusionDetailPage` and `ConclusionDetailLoaded` take `make: (CatalogConclusionDetail, NameFormatOrders) -> Content` and pass `session.nameFormat` themselves (Place ignores it). Section extras: Timeline `PersonTimelineContent.Inputs(folds:orders:widthClass:locale:)` *(new)*, Family `PersonFamilyContent.Inputs(folds:orders:locale:)` *(new)*, Sources rows `PersonSourcesContent.Inputs(folds:orders:)` *(new)* (its `make` reads the Source types with `session.queryHandle` on the section's supporting key), record links `content.graphLocations` (`[String: WorkspaceLocation]`). `locale` is a `Locale` read from `Locale.autoupdatingCurrent` in `body` | One list per site: what `make` uses is what the stamp compares, and D-10 sees the handles. A later Event or Place section cannot leave an input out | Hand-listing captured values beside the closure (two lists that drift) |
| D-20 | Tests for the primitive go in `macos/ProvenenciaTests/WorkspaceSessionDerivedTests.swift` *(new)*, with its own `makeSession`. They borrow real ids: T-1, T-2 `.conclusionContent(detailKey("e1"))`; T-3, T-5 `.conclusionContent(detailKey("e1"))` (and `"e0"`) with `.evidenceGraphText(graphID: "g1")` as the `.derived` dependant; T-4 `.evidenceGraphIndex` over two keys (`evidenceGraphsKey` and `sourceTypesKey`); T-6 `.evidenceGraphSnapshot(graphID: "g1")` as A over `.evidenceGraph(project:graphId: "g1")` as K, `.evidenceGraphText(graphID: "g1")` as B. Builds are trivial closures returning a counter value | `WorkspaceSession`'s storage is reachable only through the session; the enum is closed | Appending to `WorkspaceSessionTests.swift` (past 2,300 lines); a test-only id case |

**Rules this plan bends.** None. "(Batch 1) Refused: memoising and re-shaping for speed" and "(Batch 2) No new persisted projections, and no stored answer without a measurement" (its clause "A composed answer is memoised only after it measures slow") name this PR as the user's exception: Batch 2 builds every section's content once per value through one primitive, as cache architecture, not as a speed fix (user, 2026-11-08). The PR claims no speed, so "(Batch 2) Measure growth" sets no budget.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `WorkspaceSession+Derived.swift` *(new)*: `derived`, `carryDerived`, `derivedBuildCount`, `conclusionContent` | file / func | `macos/App/Platform/Memo.swift` `Memo` | Reused as the store (D-5); `derived` builds the key from the inputs, so a reader names inputs only |
| `DerivedValueID`, `DerivedInput` *(new)* | type | `CatalogQueryKey.Kind`; Go `graphcache` `DerivedFrom` | `Kind` names reads the registry loads; these name values built from them and what each is built from |
| `DerivedStamp`, `DerivedEntry` *(new)* | type | `CitationComposerContext.MemoToken`, `SourcesModel.VisibleRowsToken`; `WorkspaceSession.evidenceGraphIndex` + `evidenceGraphIndexBuildCount` | One stamp and one record for every id |
| `PersonTimelineContent.Inputs`, `PersonFamilyContent.Inputs`, `PersonSourcesContent.Inputs` *(new)* | type | `SourcesListSettings` (one `Equatable` value of a view's plain inputs) | Each content type names what its builder takes beside the read |
| `WorkspaceSession.inputRevision(_:)` *(new)* | func | `queryHandle(_:)` | `queryHandle` needs the value type; a stamp needs only the revision |
| `WorkspaceSession.cachedEvidenceGraphSnapshot(graphID:)` *(new)* | func | `evidenceGraphSnapshot(graphID:) async` | The async call awaits loads; the canvas and composer read synchronously in a body. The async call now returns this |
| `CitationComposerContext.termKeys(in:)` | func (replaces `termRevisions(in:)`) | — | Returns keys, not revisions |
| `WorkspaceSessionDerivedTests` *(new)* | test file | `WorkspaceSessionTests` | D-20 |

**Builds on.** `WorkspaceSession`'s handles and `evict(_ key:)`; `Memo`; the section read list (S16-03); `ConclusionFoldState` (S16-07); the splice of S16-12; `graphcache`'s `DerivedFrom` idea.
**Deletes.** `WorkspaceSession.evidenceGraphIndex`, `evidenceGraphIndexBuildCount`; `EvidenceGraphIndex.revision`; `EvidenceGraphModel.snapshotMemo` and the `rows:types:` arguments of `displaySnapshot` and `displayText`; `CitationComposerContext.MemoToken`, `memo`, `built`, `termRevisions(in:)`; `SourcesModel.VisibleRowsToken` (becomes `VisibleRowsInputs`), `visibleRowsMemo`, `visibleSourcesBuildCount`; the four memo rows of `docs/catalog-caches.md`'s Swift table (Evidence-graph index, Visible Sources, Citation composer snapshot, Evidence-graph snapshot), replaced by one "Derived values" row.
**Next adds.** A new derived value is one `DerivedValueID` case and one `derived` call that names its keys and the derived values it reads. S16-29's prefetch warms keys; a prefetched section's content is built on first draw and kept while its keys are held. A later Event or Place section gets content once per change through the same host.

### Reach

None — no new path into existing code. A new state: a derived value outlives a view remount while its keys stay; a remounted section starts its folds empty, so its `extra` differs and it builds again, as today.

### Scale

At the map's Batch 2 Scale: a stamp is one dictionary lookup and one `Int` compare per input; the widest input list is the composer's (three inputs plus one per term-valued Property, about 10 on the shipped vocabulary); a `.derived` input re-stamps its entry's three keys. `evict(_ key:)` scans the entries: at most four content entries per entity (51 entities kept: the detail page and three section hosts, the Sources section having two), one snapshot, text and vocabulary per opened graph, and two catalog-wide entries — a few hundred compares per eviction. Memory: a content entry holds the value already built today, now kept while its keys are held (50 hidden entities); a Timeline content holds only its shown rows (S16-02). The snapshot is shared by four readers where the canvas and the composer each held one. No write changes what it invalidates.

### Edges

- **Assumptions.** A handle's `revision` moves on every change of `value` (`markReplaced`, `applyFailure(clearValue: true)`, `resetForInvalidation`); `modifyValue` returning false changes nothing and moves nothing. T-2 holds an `apply` that refreshes an input. A build reads only its declared keys, its `.derived` inputs and `extra`; D-10 checks every read through `queryHandle` in debug builds. The hosts' builds take their value as an argument and declare that value's key. `buildVisibleSources` reads `searchKeys`, a per-row cache keyed by row revision, which is not a session read.
- **Neighbors.** Same stamps and same `extra` → stored value (AC-1.1); one input moved → build (AC-1.2); a non-input moved → stored (AC-1.3); `extra` moved → build (AC-1.4); a `.derived` input whose own key moved → both build (AC-1.6). A carry when another input also moved → no carry, the next read builds (T-4).
- **Removed inputs.** An evicted key drops every entry built from it and every entry built from those (AC-1.5, T-3, T-5). A host whose read goes to `.gone` or `.failed` never calls `conclusionContent`; the entry stays until its key is evicted. A deleted graph's snapshot, text and vocabulary drop when its `evidenceGraph` key is evicted.
- **Real data.** None — no table- or seed-driven rule.
- **Untrusted size.** None — the primitive adds no fan-out over data; each build costs what it costs today, at most once per change. `.derived` chains are one level deep (text and vocabulary on the snapshot).

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
    case conclusionContent(CatalogQueryKey)
}

enum DerivedInput: Equatable {
    case key(CatalogQueryKey)
    case derived(DerivedValueID)
}

struct DerivedStamp: Equatable {
    let inputs: [Int]
    let extra: (any Equatable)?
    static func == (lhs: Self, rhs: Self) -> Bool // inputs, then one opened compare of extra
}

struct DerivedEntry {
    var memo: Memo<DerivedStamp, Any>
    var inputs: [DerivedInput]
    var version: Int
}

extension WorkspaceSession {
    func derived<Value>(_ id: DerivedValueID, inputs: [DerivedInput], extra: (any Equatable)? = nil, build: () -> Value) -> Value
    func carryDerived<Value>(_ id: DerivedValueID, across key: CatalogQueryKey, from previousRevision: Int, _ change: (Value) -> Value)
    func derivedBuildCount(_ id: DerivedValueID) -> Int
    func dropDerived(reading key: CatalogQueryKey)
    func conclusionContent<Value, Extra: Equatable, Content>(_ key: CatalogQueryKey, inputs: [CatalogQueryKey], extra: Extra, value: Value, make: (Value, Extra) -> Content) -> Content
}
```

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Detail content | `ConclusionDetailPage` (existing) | `macos/App/Features/Conclusions/ConclusionDetailPage.swift` | `make` takes the name orders; draws as today |
| Section content | `ConclusionPageSectionHost` (existing) | `macos/App/Features/Conclusions/ConclusionPageSectionHost.swift` | Gains `Extra`; draws as today |

States: unchanged in every view. Accessibility: unchanged.

### Strings

None — no copy changes.

## 7. Steps

`XT` below is `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO`, the command `scripts/check-pr.sh` runs, narrowed with `-only-testing:`.

**STEP-1 — The primitive**
Files: `macos/App/Features/Workspace/Session/WorkspaceSession+Derived.swift` *(new)*, `QueryHandle.swift` (`AnyQueryHandle.revision`), `WorkspaceSession.swift` (D-4, D-9 storage, `queryHandle` recording, `evict` drop), `macos/ProvenenciaTests/WorkspaceSessionDerivedTests.swift` *(new)*. Skill: `add-swift-test`.
Do: D-1 – D-11. Write T-1 – T-6.
Check: `XT -only-testing:ProvenenciaTests/WorkspaceSessionDerivedTests` passes.

**STEP-2 — The Evidence graph index**
Files: `WorkspaceSession+EvidenceGraphs.swift`, `WorkspaceSession.swift`, `WorkspaceSessionTests.swift`.
Do: D-12. Remove `evidenceGraphIndex` and `evidenceGraphIndexBuildCount`; `graphListMergeSplicesTheIndex` reads `derivedBuildCount(.evidenceGraphIndex)`.
Check: `XT -only-testing:ProvenenciaTests/WorkspaceSessionTests` passes, `evidenceGraphIndexFollowsTheListRevision` and `graphListMergeSplicesTheIndex` included; `rg 'evidenceGraphIndexBuildCount|var evidenceGraphIndex|Valid for one handle revision' macos` finds nothing.

**STEP-3 — One graph snapshot**
Files: `WorkspaceSession+EvidenceGraphs.swift`, `EvidenceGraphModel.swift`, `EvidenceGraphView.swift`, `EvidenceCardText.swift` (doc link), `WorkspaceSessionTests.swift`, `EvidenceGraphModelTests.swift`, `PromoteModelTests.swift`.
Do: D-13 – D-15. T-6, T-7, T-9.
Check: `XT -only-testing:ProvenenciaTests/WorkspaceSessionTests -only-testing:ProvenenciaTests/EvidenceGraphModelTests -only-testing:ProvenenciaTests/PromoteModelTests -only-testing:ProvenenciaTests/UnpromoteFlowTests` pass; `rg 'snapshotMemo|displayText\(rows|displaySnapshot\(rows' macos` finds nothing.

**STEP-4 — The composer's vocabulary**
Files: `CitationComposerContext.swift`, `CitationComposerModelTests.swift`.
Do: D-16. T-10.
Check: `XT -only-testing:ProvenenciaTests/CitationComposerModelTests -only-testing:ProvenenciaTests/CitationComposerDepictionTests` pass; `rg 'MemoToken|termRevisions' macos` finds nothing.

**STEP-5 — Visible Sources**
Files: `SourcesModel.swift`, `SourcesModelTests.swift`.
Do: D-17; T-11.
Check: `XT -only-testing:ProvenenciaTests/SourcesModelTests` passes; `rg 'visibleRowsMemo|visibleSourcesBuildCount|VisibleRowsToken' macos` finds nothing.

**STEP-6 — Detail and section content**
Files: `ConclusionDetailPage.swift`, `PersonTimelineContent.swift`, `PersonFamilyContent.swift`, `PersonSourcesContent.swift`, `PersonDetailView.swift`, `EventDetailView.swift`, `PlaceDetailView.swift`, `ConclusionPageSectionHost.swift`, `PersonTimelineSection.swift`, `PersonFamilySection.swift`, `PersonSourcesSection.swift`, `macos/ProvenenciaTests/ConclusionContentTests.swift` *(new)*.
Do: D-18, D-19: the hosts' new `make` shapes, the three `Inputs` structs, the seven sites. T-8, T-12.
Check: `XT -only-testing:ProvenenciaTests/ConclusionContentTests` passes, and `PersonTimelineContentTests`, `PersonFamilyContentTests`, `PersonSourcesContentTests`, `PersonRecordLinksContentTests` pass unchanged.

**STEP-7 — Docs**
Files: `docs/catalog-caches.md` (Swift caches: one "Derived values" row — owner `WorkspaceSession+Derived.swift` · `derived`, key `DerivedValueID`, fill the caller's build, updated by its inputs (key revisions, the versions of the derived values it reads) and its `extra`, lifetime its inputs' handles, cap none of its own; the four memo rows go; the Depiction preview row stays), `docs/macos-client-patterns.md` (Cache contract rule 5: replace "that join is not a third cache key" with "that join is a `derived` value (`cachedEvidenceGraphSnapshot`), not a `CatalogQueryKey`", and add: a view derives display values with `session.derived`, naming its input keys, the derived values it reads and its extras, and writes no token), `.agents/skills/add-workspace-place/SKILL.md` (step 5 "Model rules": one line on `derived`, one on adding a `DerivedValueID` case), `completed.md`, `deployment-plan.md` (map row), this plan.
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-27-derived-values.md` reports no errors; `python3 scripts/check-guidance-names.py` passes.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

`deletedEntitiesLoseTheirHiddenKeys` (line 1353) is the template for a deleted handle: `session.apply(CatalogWriteEffects(deleted: [CatalogWriteEffectsDeleted(entity: .handle, ids: ["e1"])]))` with `apply(location: .sectionRoot(.persons))` so the keys are hidden. `hiddenConclusionPagesAreCappedAtFifty` (line 1457) is the template for the cap: its `show(_:)` helper and 51 `FakeStore.seededConclusionDetails`.

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `WorkspaceSessionDerivedTests.swift` `aValueBuildsOncePerInputRevision` *(new)* | `setQueryValue(.sourceTypesList(project:), …)`; three reads of `derived(.visibleSources, inputs: [.key(that)])` → 1 build | AC-1.1, D-1 |
| T-2 | Swift | same file, `anApplyThatRefreshesAnInputBuildsAgain` *(new)* | `.conclusionDetail` key for "e1" on screen (`apply(location: .personDetail(entityId: "e1", ref: "PER-e1", title: nil))`, `FakeStore.seededConclusionDetails`), `settleWrites`; read → 1; `apply(CatalogWriteEffects(handles: ["e1"]))` and `settleWrites` → read → 2; same for "e2" (not an input) → 2; `extra: 1` → 3, again → 3 | AC-1.2, AC-1.3, AC-1.4, D-5 |
| T-3 | Swift | same file, `aDeletedInputDropsTheValue` *(new)* | Entry over the hidden `.conclusionDetail` key for "e1"; `apply` with `deleted` "e1" (template above) → the entry is gone; `setQueryValue` the key again; read → builds | AC-1.5, D-3, D-6 |
| T-4 | Swift | same file, `aCarryMovesTheValueOnlyWhenItsKeyAloneMoved` *(new)* | Entry over keys A and B; `setQueryValue(A)`; `carryDerived(across: A, from: previous)` → no build, the changed value; then `setQueryValue(A)` and `setQueryValue(B)`, carry across A → no carry, the next read builds | D-11 |
| T-5 | Swift | same file, `theHiddenEntityCapDropsValuesAndTheirDependants` *(new)* | Entries over "e0"'s detail key and a `.derived` dependant; the cap evicts "e0" (template above) → both gone | AC-1.5, D-6 |
| T-6 | Swift | same file, `aDerivedInputFollowsItsOwnInputs` *(new)* | B reads `.derived(A)`, A reads key K; `setQueryValue(K)`; read B → A and B each 2 builds | AC-1.6, D-2 |
| T-7 | Swift | `EvidenceGraphModelTests.swift` `displayTextFollowsTheSnapshot` (rewritten) | The test builds `CatalogQueryKey.evidenceGraph(project:graphId:)` and `.propertiesWorkspace(project:)` itself and sets the rows and a `PropertiesSnapshot` carrying today's `types` with `setQueryValue`; "Wm Robins" → "William Robins" after the rows are set again; two reads between writes → `derivedBuildCount(.evidenceGraphText(graphID:)) == 1` | AC-2.4, D-15 |
| T-8 | Swift | `ConclusionContentTests.swift` `sectionContentBuildsOncePerReadAndFold` *(new)* | `.personEvents` key for "e1" set; `conclusionContent` with the Timeline's reads and a `PersonTimelineContent.Inputs` read three times → 1 `make`; `folds.revealPage(.dated)` → 2; `apply(CatalogWriteEffects(handles: ["e1"]))` with the key on screen, `settleWrites` → 3; the same for "e2" → 3 | AC-2.7, D-18, D-19 |
| T-9 | Swift | `PromoteModelTests.swift` `reproposingReusesTheGraphSnapshot` *(new)* | `load()`, then one decision that reproposes (as `oneDecisionProposesOnce`) → `derivedBuildCount(.evidenceGraphSnapshot(graphID:)) == 1` | AC-2.3, D-13 |
| T-10 | Swift | `CitationComposerModelTests.swift` `aTermWriteRebuildsTheVocabularyOnce` *(new)* | A term added through `apply` reporting the `property_terms` read → vocabulary builds once more and offers the term; an unrelated write → no build | AC-2.5, D-16 |
| T-11 | Swift | `SourcesModelTests.swift`, both tests that read the build count (lines 295–318 and 455–497) | Their counts read `session.derivedBuildCount(.visibleSources)`; expected counts unchanged | AC-2.6, D-17 |
| T-12 | Swift | `ConclusionContentTests.swift` `detailContentFollowsTheNameFormat` *(new)* | `.conclusionDetail` key set; `conclusionContent` with `orders` read three times → 1; another `NameFormatOrders` → 2 | AC-2.8, D-18 |
| T-13 | Swift | `WorkspaceSessionTests.swift` `evidenceGraphSnapshotReadsTheThreeKeys` (extended) | An added second await before the reload, no write → 1 build; after the reload → 2 and the new rows | AC-2.2, D-13 |
| T-14 | Swift | `WorkspaceSessionTests.swift` `graphListMergeSplicesTheIndex` (count read changed) | Merge → `derivedBuildCount(.evidenceGraphIndex)` unchanged; lookups right | AC-2.1, D-12 |
| T-15 | Manual | §10 step 8 | AC-1.7's assertion stops a test process, so it is checked by hand | AC-1.7, D-10 |

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

Run a Debug build (D-10's check is on).

1. Open a project with a person in at least 50 events. Open the person on Timeline, press Show more twice, resize across 1600 pt: rows and lifeline as before each unfold and at each width. No assertion fires (AC-1.7).
2. Same person: Family, then Sources. Hover a graph on the record links diagram: its line lights as before. Rename a Source in another window: the Sources row shows the new title.
3. Change the name format in Settings: the Person page header and an Event page title follow it.
4. Open an Evidence graph, rename a Subject: the card shows the new name. Drag a card: it moves as before.
5. Open the citation composer on that graph and add a term to a term-valued Property in Properties: the composer offers it.
6. Promote a Subject, decide one row: the proposal updates. Unpromote a record with a bridge: the confirm lists the connection.
7. Sources list: change sort, filter by type and by status, type in search: rows as before.
8. In a Debug build, remove `.key(connectRules)` from `evidenceGraphSnapshotKeys(graphID:)`, open an Evidence graph: the assertion names `evidenceGraphSnapshot` and the `connectRules` key (AC-1.7). Put the key back.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A build reads a handle it does not declare, so it shows stale data | D-10's debug check; the manual check runs Debug |
| SwiftUI reports "Modifying state during view update" | The storage is `@ObservationIgnored` (D-9) |
| A nested `derived` call corrupts the store | D-9's read-release-build-write order; T-6 and T-10 run nested builds |

**Stop and report if:**

- A `QueryHandle` path changes `value` without moving `revision` (any setter of `storedValue` other than those §4 names).
- A handle leaves `handles` anywhere but `evict(_ key:)`, other than `typedHandle`'s replacement of a handle bound to another type (D-3 depends on it).
- A host's `make` needs a value that is neither its read's value, its `Extra`, nor a handle it fetches inside the closure.
- `graphListMergeSplicesTheIndex` cannot pass with `carryDerived` as D-11 states it.
- D-10's check fires on a build in the moved code: name the id and the key.
- An existing behavior test (not a build-count read) has to change its expected result, other than through D-14.
- Swift rejects the opened-existential compare of D-5 on the project's toolchain.

## 12. Open questions

None.

## 13. PR

**Title:** S16-27 — One primitive for values derived from cached data
**Body:** objective in one sentence; what shipped against US-1 and US-2; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-27-derived-values.md`.
