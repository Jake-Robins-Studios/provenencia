# S16-25 — Swift keys become plain values and follow their inputs

**Status:** Landed in [#847](https://github.com/Jake-Robins-Studios/provenencia/pull/847) (2026-11-15)
**Spike / slice:** Spike 16 · Slice 2e — The app's cache
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: every page draws the same values; only when a cached value reloads changes)
**Board:** —
**Depends on:** S16-24 (landed [#839](https://github.com/Jake-Robins-Studios/provenencia/pull/839), reads report their inputs), S16-03 (landed [#769](https://github.com/Jake-Robins-Studios/provenencia/pull/769)), S16-09 (landed [#780](https://github.com/Jake-Robins-Studios/provenencia/pull/780), `.source` follow and stale pages), S16-12 (landed [#800](https://github.com/Jake-Robins-Studios/provenencia/pull/800), Source records)
**Blocks:** S16-29 (prefetch, once a write no longer throws the warmed sections away)
**Branch:** `s16-25-keys-follow-inputs`
**Version bump:** patch — the app reloads fewer pages after a write and the engine reports a new keyed read; nothing new on screen ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md), [`add-audit-scope`](../../../../.agents/skills/add-audit-scope/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/macos-client.mdc`, `.cursor/rules/swift-tests.mdc`, `.cursor/rules/go-tests.mdc`, `.cursor/rules/catalog-queries.mdc`
**Context:** [design § Swift](../cache-architecture.md#swift) ("Values report their inputs"); [`docs/macos-client-patterns.md`](../../../macos-client-patterns.md) "Conclusion keys"; [`core/database/effects/README.md`](../../../../core/database/effects/README.md) (`Set.Reads`); working rules: "(Batch 2) Swift caches one value per view, follows its inputs and shows it stale while refreshing", "(Batch 2) The point of this batch is simpler code", "(Batch 2) A Source's words live once", "(Batch 2) Every cache names the signal that updates it, and updates exactly", "(Batch 1) A cached detail follows the Sources its records cite"; goal bar 14; S16-12 ship log PRF-1
**Planned:** 2026-11-15 against `main` @ `2848675`
**Review:** [`S16-25-keys-follow-inputs.review.md`](S16-25-keys-follow-inputs.review.md) — round 1: Fits with changes / Not ready; round 2: Fits with changes / Ready with changes; every finding Fixed; Planned

**Runs on macOS.** STEP-3 to STEP-5 and the Xcode half of `scripts/check-pr.sh` need Xcode. On a machine without `xcodebuild`, do STEP-1 and STEP-2 and the Go checks, then stop and report that the Swift steps need a macOS runner.

**Landed.** Differences from the plan: D-11's STEP-3 to STEP-6 landed in one commit (`b88d0b651`) because the registry, `CatalogLastUpdated.swift` and `WorkspaceSession.swift` edits interleave. D-7's smaller-set swap is dropped: `Set.isDisjoint` already iterates the smaller set, so `revalidatedKeys` calls it once (user, 2026-11-15). `core/database/effects/evidence_graphs_test.go` now expects an Artifact label edit to move `source_records`. The `CatalogQueryRegistryTests` `personFamilyRevalidateOnTouchedHandle` and `personEventsRevalidateOnTouchedHandle` declared-follows lists are updated (their reload expectations are unchanged). The five old follow tests are replaced by T-6 to T-9, and `personClaimsFollowHandlesAndGraphs` is rewritten without its `.source` half. T-8's final assertions compare the whole refreshed value (`handle.value == renamed`).

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

A Person, Event or Place page reloads after a write only when the write names something the page was built from: a person, event, place or link it read, an Evidence graph whose records it shows, or a Source whose words it shows. Today the Family and Timeline sections reload on any write that names any handle, and the claims, record links and detail keys reload on any write anywhere inside a Source they cite (S16-12 PRF-1: 31 ms per write at 50 graphs while visible). The app reads the inputs S16-24 put on each value and follows them, declared once for the five per-entity keys. The engine gains one narrow signal, the `source_records` keyed read, which names a Source only when its words move (its row, an Artifact, its credibility), and the Go Source records entry follows it too (user, 2026-11-15).

The cache keys become plain values (kind, project, ids) so that the refreshes, every loader and every patch read the key without a `switch` or a `guard case`.

**Why now.** S16-24 landed the inputs; nothing reads them. S16-09 and S16-12 added `.source` follows that this PR replaces (map, "Shared files"). S16-29's prefetch is worth nothing while any write throws the warmed sections away.

**What stays.** Every page draws the same values. The three Conclusion lists keep following every touched handle (S16-26). The stale-while-refreshing policy, the deleted-entity eviction and the 50 hidden entity cap stay as S16-09 left them. `SourceScopes` stays the audit "last activity" scope and still patches the Sources list's Updated cell. No Spike 15 key exists yet ([Spike 15 map](../../spike-15/deployment-plan.md): S15-11, S15-17, S15-21, S15-23 are Scoped), so there is nothing of Spike 15's to convert.

## 2. User stories

**US-1.** As a researcher, when I edit something that a cached Person, Event or Place page or section was built from, that page shows the change: the visible one reloads, a hidden one is marked stale.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A Family value of Person `e1` whose inputs hold its parent `p1`, implied sibling `s1`, partner `w1`, child `c1` and the pivot event `m1`; a write reports `handles: [id]` for each of those ids in turn | `revalidatedKeys` names the family key each time |
| AC-1.2 | A Timeline value of `e1` whose inputs hold the event `ev1` and the co-participant `q1`; a write reports `handles: ["q1"]`, then `summaryHandles: ["ev1"]` | `revalidatedKeys` names the timeline key both times |
| AC-1.3 | A claims value and a record links value of `e1` whose inputs hold graph `g1` and Source `src1`; a write reports `evidenceGraphs: ["g1"]`, then `reads: [source_records: ["src1"]]` | Both keys are named both times |
| AC-1.4 | A detail value of `e1` whose inputs hold graph `g1` and Source `src1`; a Citation fix reports `evidenceGraphs: ["g1"]`; a Source rename reports `reads: [source_records: ["src1"]]` | The detail key is named both times |
| AC-1.5 | Any of the five keys of `e1` holds a value whose inputs are empty (FakeStore); a write reports `handles: ["e1"]` | The key is named (the key's own handle always counts) |
| AC-1.6 | The family key of `e1` is on screen with a value whose inputs hold `w1`; a write reports `handles: ["w1"]` through `apply` | The key reloads (`isFetching`, then the new value). With the page hidden, the same write marks it stale and loads nothing |
| AC-1.7 | A per-entity key whose first load is in flight (no value yet); a write reports `handles: ["x9"]` | The key is named (its inputs are not known yet) |

**US-2.** As a researcher, when I edit something a cached page was not built from, the page is left alone: no reload, no stale mark.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | The family and timeline keys of `e1` with the values of AC-1.1 and AC-1.2; a write reports `handles: ["x9"]` | Neither key is named (today both are) |
| AC-2.2 | The record links and claims keys of AC-1.3; a Subject, Observation, Citation or note edit in graph `g2` of Source `src1`, reported as `evidenceGraphs: ["g2"], sourceScopes: ["src1"], reads: [citations: ["g2"]]` | Neither key is named (S16-12 PRF-1; today both are) |
| AC-2.3 | The detail key of AC-1.4; a write reports `sourceScopes: ["src1"]` only | The detail key is not named |
| AC-2.4 | The engine applies a Source rename, a type change, an Artifact create, relabel and delete, a credibility assessment and a Source delete | Each names its Source in `Set.IDsOf(ReadSourceRecords)`, and the Source records entry reloads it |
| AC-2.5 | The engine applies an Observation write inside the Source | No `source_records` id; the Source records entry and its derived readers are left as they were |

**US-3.** As a contributor, a cache key is a value with the same factory spelling, and a new per-entity page key is declared with one helper.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `CatalogQueryKey.citationsByArtifact(project: p, graphId: "g1", artifactId: "a1")` | `kind == .citationsByArtifact`, `project == p`, `ids == ["g1", "a1"]`, `ownId == nil`; two calls with the same arguments are equal and hash equal |
| AC-3.2 | `CatalogQueryKey.sourceWorkspace(project: p, sourceId: "s1")` | `ownId == "s1"` |
| AC-3.3 | The five per-entity kinds' descriptors | `refreshes.map(\.follows) == [.touchedHandles, .evidenceGraphs, .reads(.sourceRecords), .touchedHandles, .list(.propertyVocabulary)]`, `whenHidden == .markStale`, `deletedWith == .handle` |
| AC-3.4 | `rg 'case \.[a-zA-Z]+(\(.*\))? = key|mismatchedCatalogKey|personSection|personGraphsSection' macos/App` | No hit |

## 3. Scope

| In | Covered by |
| --- | --- |
| Go: `effects.ReadSourceRecords` keyed read (key table `sources`), moved by `sources`, `artifacts`, `source_credibility_assessments`; `effects.Set.IDsOf`; Swift `CatalogRead.sourceRecords` | STEP-1, AC-2.4, AC-2.5 |
| Go: `sources.Records` Apply follows `source_records` instead of `SourceScopes`; `evidencegraphs.Index` Apply reads through `IDsOf` | STEP-2, AC-2.4, AC-2.5 |
| Swift: `CatalogQueryKey` a struct of kind, project and ids with the same static factories; the case list, the `kind`, `project` and `ownId` switches, `mismatchedCatalogKey` and every `guard case` on a key go | STEP-3, AC-3.1, AC-3.2, AC-3.4 |
| Swift: `followsInputs`, the three per-slot `followsValue` refreshes of a value's inputs, declared once in `entityPage` for the five per-entity kinds; `revalidatedKeys` reads each slot's ids once per write | STEP-4, AC-1.1 – AC-1.7, AC-2.1 – AC-2.3, AC-3.3 |
| Swift: `personSection`, `personGraphsSection`, the detail's inline Source closure and the claims and record links id closures go | STEP-4, AC-3.4 |
| Session tests per relation (parent, implied sibling, partner, child, co-participant, cited Source) and the PRF-1 case | STEP-5, T-6 – T-9 |
| Docs: `add-workspace-place`, `add-audit-scope`, `macos-client-patterns.md`, `catalog-caches.md`, the effects README, `cache-architecture.md`, the map's rules and row | STEP-6 |

| Out | Home |
| --- | --- |
| The Persons, Events and Places lists merging touched rows | S16-26 |
| One primitive for derived values | S16-27 |
| Prefetch of other sections and a hovered person | S16-29 |
| The Source date's `date_values` path on `source_records` | S15-05, which adds the date to the Source record and with it the path (D-3; the effects README says so after STEP-6) |
| An end-to-end Go test that runs each relation's real FFI write and meets the read's inputs | not planned (D-10) |
| Narrowing `sources`' `source_records` path to the record's columns (`onField`) | not planned (D-3) |
| `.evidenceGraph`, `.citationCounts`, `.propertyTerms` and the other non-entity kinds following anything new | not planned: they keep their follows |
| FakeStore computing inputs for its values | not planned (D-8) |
| The `set.Reads` loop in `core/database/evidencegraphs/evidencegraphs_test.go` (a "names no citations read" check, not a lookup) | not planned |

## 4. Current state

Verified at `2848675`.

| Area | Where | Today |
| --- | --- | --- |
| Key | `macos/App/Features/Workspace/Session/CatalogQueryKey.swift` `CatalogQueryKey` | An `enum` of 22 cases with associated `project` and ids, a parallel `Kind` enum (`CaseIterable`), and three switches: `kind`, `project`, `ownId`. `ownId` is nil for `sourceWorkspace`, `typeSuggestions` (one id each, deliberately: "for the kinds whose descriptor reads it"), `citationsByArtifact` and the catalog-wide kinds |
| Descriptors | `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift` `CatalogQueryKey.Kind.descriptor`, `CatalogQueryDescriptor.make` | One arm per kind. Every `load` starts with `guard case .x(let project, …) = key else { mismatchedCatalogKey(key, .x) }` (22 times); `make`'s doc says "`load` `guard case`s the key; a mismatch is unreachable". `citationsByArtifact`'s refresh closure is a `guard case` |
| Per-entity follows | same file, `CatalogQueryDescriptor.personSection`, `.personGraphsSection`, the `.conclusionDetail` arm | Family and Timeline: `applyHiddenPolicyOnAny(follows: .touchedHandles)`, so any handle reloads them. Claims and record links: `applyHiddenPolicy(followsOwnId: .touchedHandles)`, graphs from the value on `.evidenceGraphs`, Sources from the value on `.source` (`sourceScopes`). Detail: own id on `.touchedHandles`, an inline closure of every outcome's, owner's and picture's `sourceID` on `.source`. All five add `.followsPropertyLabels` |
| Follow slots and refreshes | `macos/App/Features/Workspace/Session/CatalogLastUpdated.swift` `CatalogQueryFollows` (`Equatable`), `requireRowIDs`, `CatalogQueryRefresh` (`Action.revalidate(… -> Set<String>?)`, `.run`; `applyHiddenPolicy(follows:ids:)`, `(followsOwnId:)`, `(followsValue:ids:)`, `applyHiddenPolicyOnAny`) | `followsValue` matches any id of its slot until the key holds a value; used only by the claims, record links and detail arms. `updatedSourceShell()` and `metadataBoard()` `guard case .sourceWorkspace` on the key |
| Session | `macos/App/Features/Workspace/Session/WorkspaceSession.swift` `revalidatedKeys(for:)` | For each warmed key and each `.revalidate` refresh it builds `Set(refresh.follows.ids(in: effects))` again (per key per refresh), skips when empty, and meets it with the closure's ids (nil = any) through `isDisjoint` |
| Effects (Swift) | `macos/App/Features/Workspace/Session/CatalogMutation.swift` `CatalogRead`, `CatalogWriteEffects` | `CatalogRead` has four reads; its doc lists their key tables. `touchedHandles` is computed (it builds a set and an array on each call). Docs of `evidenceGraphs` ("a … credibility change is only in `sourceScopes`"), `reads` ("citation counts, citations by Artifact and graph progress") and `sourceScopes` ("the detail keys … follow it through `.source`") |
| Inputs | `macos/App/Platform/GenealogyStore.swift` `CatalogPageInputs`; `var inputs = CatalogPageInputs()` on `CatalogConclusionDetail`, `CatalogPersonClaims`, `CatalogPersonFamily`, `CatalogPersonTimeline`, `CatalogPersonRecordLinks` | Decoded by `GoStore.mapPageInputs`; doc ends "Nothing reads it yet." `FakeStore` returns empty inputs; `FakeStore.listPersonClaims` builds `CatalogPersonClaims(groups:)` from `seededPersonClaims`, so a seeded claims value carries no inputs |
| Go reads | `core/database/effects/registry.go` `Read`, `KeyTable`, `Reads`, `ReadIDs` (struct), `Set.Has`; entries `sources`, `artifacts`, `source_credibility_assessments`, `date_values` | Four reads. The three Source-word tables set `SourceScope` only; `artifacts` has no `Reads`. A Source's date is a `date_values` row reaching the Source only through `SourceScope` (`inbound("sources", "date_value_id")`) |
| Go read lookups | `core/database/evidencegraphs/index.go` `Index` Apply; `core/database/effects/reads_resolve_test.go` `citationReads`; `core/database/effects/evidence_graphs_test.go` `readIDs` | Three copies of "the ids of one read in a `Set`" |
| Go Source records | `core/database/sources/records.go` `Records` Apply | Reloads the Sources in `set.SourceScopes`, so every Observation, Subject, Citation or note edit inside a Source reloads its record and its whole Artifact list (S16-12 §6 Scale: crafted 10,000 Artifacts) |
| Go inputs recorded | `core/database/persondetail/claims.go` `claims` (`in.AddSources`), `core/database/persondetail/recordlinks.go` (calls `claims`), `core/database/conclusiondetails/conclusiondetails.go` `newRecordReader` (`graphfill.RecordsOf(…, in)`), `recordReader` (`r.in.AddSources`); `core/database/graphcache/pageinputs.go` `PageInputs.Node` | Claims and record links record their graphs and their groups' Sources; the detail records the graphs of its records and the Source of each record's Artifact; every read records its own node |
| Go vocabulary parity | `api/ffi/swift_vocabulary_test.go` "catalog reads" | Fails when `CatalogRead` and `effects.Reads` differ |
| Navigation | `macos/App/Features/Workspace/WorkspaceLocation.swift` `personDetail(entityId:ref:title:pageSection:)` | Without `pageSection` the place warms only the first section's reads; `.family` makes the family key visible |
| Tests (Swift) | `macos/ProvenenciaTests/WorkspaceSessionTests.swift` `personClaimsFollowHandlesAndGraphs`, `detailFollowsTheSourcesItsRecordsCite` (and its helper `citedDetail`), `personFamilyFollowsEveryTouchedHandle`, `personEventsFollowEveryTouchedHandle`, `personClaimsFollowEveryGraphUntilLoaded`, `personRecordLinksFollowEveryGraphUntilLoaded`, `aKeyInvalidatedAndRefreshedRevalidatesOnce`, `promoteRevalidatesOnlyItsPeople`; `macos/ProvenenciaTests/CatalogQueryRegistryTests.swift` `ownIdNamesTheKeysOneRow`, `invalidationsComeFromRegistrySpecs`, `personRecordLinksRevalidate` | Pin today's follows, reading ids from the value's groups and graphs, and `ownId` per kind |
| Tests (Go) | `core/database/effects/reads_test.go` `TestReadsDeclare` (its `artifacts` check is `len(eff.Reads) != 0`); `core/database/sources/records_test.go` `TestRecordsApply` (real writes through `r.Run`; its `check` requires the derived entry to be dropped, including in the "observation edit" subtest), `TestRecordsApplySwap` (`effects.Set{SourceScopes: …}`); `core/database/sources/records_bench_test.go` `BenchmarkSourceRecords` (`SourceScopes`) | Pin the four reads' tables and today's Apply signal |

**Precedent.** The keyed read `evidence_graphs` (keyed by Source, moved by `evidence_graphs` and `evidence_graph_artifacts`, read by the Go graph index `evidencegraphs.Index` Apply and by the Swift `.evidenceGraphsList` refresh) is the same shape as `source_records`: copy its constant, `KeyTable` arm, `Reads` entry and registry `Reads:` lines. `effects.Set.Has` is the precedent for a lookup method on `Set`. `applyHiddenPolicy(followsValue:ids:)` on the claims key today (`.evidenceGraphs` from the value's graphs) is the precedent for each of the three input refreshes. `CatalogLastUpdatedRow` (a small protocol in `CatalogLastUpdated.swift` with one empty conformance per value type) is the precedent for `CatalogPageValue`.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `CatalogQueryKey` is `struct CatalogQueryKey: Hashable, Sendable { let kind: Kind; let project: ProjectKey; let ids: [String] }` with a `private init(_ kind: Kind, _ project: ProjectKey, _ ids: [String] = [])` and one `static func` per kind with today's name and labels (for example `sourceWorkspace(project:sourceId:)` and `citationsByArtifact(project:graphId:artifactId:)`), each carrying the doc comment its case has today. `ids` holds the factory's id arguments in order. `Kind` stays the one list of kinds (`CaseIterable`, the descriptor switch). `ownId` is `ids.count == 1 ? ids[0] : nil`, documented as "The key's single id, when it has exactly one". This gives `sourceWorkspace` and `typeSuggestions` an `ownId`; no reader reaches them (`warmedKeys(deletedWith:)` and `apply(location:)` are gated on `deletedWith`, `followsOwnId` on the kinds that declare it), and D-2 reads it | The map row; call sites compile unchanged; one list of kinds instead of two | Keeping the enum and adding a `value` view (two shapes); named stored fields per id |
| D-2 | One non-optional accessor, `var id: String` ("`ownId`, for a loader of a kind that always has exactly one id; a programming error otherwise", `precondition(ids.count == 1)`), read by every single-id loader; `citationsByArtifact`'s loader and refresh read `key.citationGraphId` and `key.citationArtifactId` *(new)*, two computed properties beside its factory. Catalog-wide loaders read only `key.project`. `updatedSourceShell()` and `metadataBoard()` check `key.kind == .sourceWorkspace && key.ownId == <the Source id>`. `mismatchedCatalogKey` goes; `make`'s doc says the loader reads `key.project` and the key's ids | A descriptor runs only for its own kind (`key.kind.descriptor`), so the loader `guard case` checked nothing; the patches keep their kind check; no bare index in the registry | `key.ids[0]` everywhere (positional); one accessor per id name for every kind |
| D-3 | Go `effects.ReadSourceRecords Read = "source_records"`, key table `sources`, appended last to `Reads`. Paths: `sources` `self()`, `artifacts` `field("source_id")`, `source_credibility_assessments` `field("source_id")`. No `onField` narrowing on `sources`. A table the Source record gains (S15-05's date: `date_values`, `inbound("sources", "date_value_id")`) adds its `source_records` path in the PR that adds the column | These three tables are what `sources.loadRecords` reads (`sqlRecordSources`, `sqlRecordArtifacts`; `source_credibility_grades` is seeded only and has no runtime write, S16-12 D-4); one signal for "a Source's words moved" (user, 2026-11-15); a cover or public flag write is rare | `SourceScopes` (fires on every write in a Source: PRF-1); an `onField` list (breaks the day the record gains a column); the `date_values` path now (nothing reads the date from the record yet; rule "updates exactly") |
| D-4 | `func (s Set) IDsOf(r Read) [][]byte` *(new)* beside `Set.Has`: the ids of every entry whose `Read` is `r`, in order. `sources.Records` Apply reloads `set.IDsOf(ReadSourceRecords)` where it reloads `set.SourceScopes` today; with none it returns at once. `evidencegraphs.Index` Apply, `citationReads` and `evidence_graphs_test.go`'s `readIDs` use it | One signal for both readers of Source words (user, 2026-11-15); the lookup's fourth copy becomes one method; the name differs from the existing struct `effects.ReadIDs` | A fourth hand loop; naming it `ReadIDs` (the struct's name) |
| D-5 | Swift `CatalogRead.sourceRecords = "source_records"`, in STEP-1 with the Go constant. No proto change: `WriteEffects.reads` carries read keys as strings | `api/ffi/swift_vocabulary_test.go` compares the two lists, so both land in one commit; `GoStore.mapWriteEffects` already maps any known key | A new `WriteEffects` field |
| D-6 | `static func followsInputs<Value: CatalogPageValue>(_: Value.Type) -> [CatalogQueryRefresh]` *(new)* on `CatalogQueryRefresh` returns three existing refreshes: `.applyHiddenPolicy(followsValue: .touchedHandles) { (v: Value) in v.inputs.handles }`, `.applyHiddenPolicy(followsValue: .evidenceGraphs) { (v: Value) in v.inputs.evidenceGraphs }`, `.applyHiddenPolicy(followsValue: .reads(.sourceRecords)) { (v: Value) in v.inputs.sources }`. No new slot, Action or matcher: each is typed to its slot, and `followsValue` already follows any id of its slot until the value arrives (AC-1.7) | The map's "one `.followsInputs`" is one declaration; reuses `followsValue` (round-2 review M-9); each closure returns the value's stored set, with no copy | A new `.inputs` slot with a widened `.revalidate` and an `isMet` matcher (a slot that names no ids; three new concepts for what `followsValue` does) |
| D-7 | `revalidatedKeys(for:)` builds each distinct slot's reported `Set` once per write: a local `[CatalogQueryFollows: Set<String>]` filled on first use, so `touchedHandles` and the reads are computed once. `CatalogQueryFollows` gains `Hashable` (`CatalogRead` and `CatalogList` are `String` raw-value enums). The `.revalidate` closure type does not change; the meeting test iterates the smaller of the two sets: `deps.count <= reported.count ? !deps.isDisjoint(with: reported) : !reported.isDisjoint(with: deps)` | Today the set is rebuilt per key per refresh; with five refreshes per entity key that is up to about 1,300 rebuilds per write. One build per slot per write, and per-key cost bounded by the smaller set | Leaving the per-key rebuild (a 20,000-handle write would build 20,000-entry sets about 1,300 times) |
| D-8 | `protocol CatalogPageValue: Sendable { var inputs: CatalogPageInputs { get } }` *(new)* in `CatalogLastUpdated.swift`, with empty conformances for the five value types. `FakeStore` keeps returning empty inputs; tests that need inputs seed values with `setQueryValue` (claims always, since `FakeStore.listPersonClaims` drops them) or pass `inputs:` to the memberwise initializers of the seeded family, timeline, record links and detail values (each has `var inputs = CatalogPageInputs()`) | One line per type, as `CatalogLastUpdatedRow`; `swift-tests.mdc` keeps engine rules out of FakeStore | A key path argument (`KeyPath` is not `Sendable` under strict concurrency); FakeStore computing kin and co-participants |
| D-9 | `CatalogQueryDescriptor.entityPage<Value: CatalogPageValue>(kind:load:)` *(new)* replaces `personSection` and `personGraphsSection`: `.make(kind:, whenHidden: .markStale, deletedWith: .handle, refreshes: CatalogQueryRefresh.followsInputs(Value.self) + [.applyHiddenPolicy(followsOwnId: .touchedHandles), .followsPropertyLabels], load:)`. All five per-entity arms use it. A key that follows inputs but is not a per-handle page (S15-21's sheet key, `whenHidden: .evict`) adds `followsInputs(Value.self)` to its own `.make` | The own-id follow is the existing constructor and sits with the one helper whose keys are handles; AC-1.5 holds for a value with empty inputs | Keeping the two helpers with new bodies; folding the own id into the inputs closure (a copy per key per write) |
| D-10 | Test layers: Go `TestReadsDeclare` (which tables carry the read, exhaustive) and `TestRecordsApply` with real writes (which writes reload the record, and that an Observation write leaves it) hold the engine; Swift registry tests hold the key value and the declared follows; Swift session tests, one per relation, seed values whose inputs hold the ids S16-24's handler tests pin for that relation (`TestGetPersonFamily`: spouse, pivot, child; `TestListPersonEvents`: event, co-participant; `TestListPersonClaims`, `TestGetPersonRecordLinks`: graphs and Source), plus the PRF-1 case. No end-to-end FFI write per relation | The meeting rule has three halves, each held where it lives: Go records the ids (S16-24), the write names them (S16-24 §6 Edges "Assumptions" and the effects tests), Swift meets them (this PR) | An FFI fixture per relation (six canon fixtures through Promote for a check the three halves make) |
| D-11 | Commits: (1) STEP-1 and STEP-2 (the read in Go and Swift, Apply, `IDsOf`); (2) STEP-3 (keys as values); (3) STEP-4 and STEP-5 (the inputs follow and its tests); (4) STEP-6 (docs) | Each commit builds and passes its tests, the vocabulary parity test included | One commit |

**Rules this plan bends.** The working rule "(Batch 1) A cached detail follows the Sources its records cite" says the detail key follows the Sources its records cite through `applyHiddenPolicy(followsValue: .source, ids:)` and that any write inside a cited Source revalidates a visible detail; S16-12's Out line "A narrower update signal than `SourceScopes`" (not planned, user 2026-11-12) said no narrower signal would come. The user chose on 2026-11-15 to add the `source_records` read, followed by the app and by the Go Source records entry (D-3, D-4, D-6). STEP-6 rewrites the Batch 1 rule's mechanism and the Batch 2 rule "A Source's words live once". The Batch 2 rule "Swift caches one value per view, follows its inputs and shows it stale while refreshing" is followed: its "one `.followsInputs` refresh" is one `followsInputs` declaration (D-6), and STEP-6 says so in the rule.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `effects.ReadSourceRecords` *(new)* | Go const + registry paths | `effects.ReadEvidenceGraphs` (keyed by Source) | Extends the keyed-read registry; `evidence_graphs` names graph-list changes, not Source words |
| `effects.Set.IDsOf` *(new)* | Go method | `Set.Has`; the loops in `index.go`, `citationReads`, `readIDs` | Replaces the three copies |
| `CatalogRead.sourceRecords` *(new)* | Swift enum case | `CatalogRead.evidenceGraphs` | Mirrors the Go constant |
| `CatalogQueryKey` as struct; `id`, `citationGraphId`, `citationArtifactId` *(new)* | type, accessors | today's enum | Replaces it |
| `CatalogQueryRefresh.followsInputs(_:)` *(new)* | constructor returning three refreshes | `applyHiddenPolicy(followsValue:ids:)` | Built from it, one per slot |
| `CatalogQueryFollows: Hashable` (changed) | conformance | `Equatable` today | D-7's per-write memo |
| `CatalogPageValue` *(new)* | protocol | `CatalogLastUpdatedRow` | Same pattern, different field |
| `CatalogQueryDescriptor.entityPage` *(new)* | func | `personSection`, `personGraphsSection` | Replaces both |
| Swift tests T-6 – T-9 *(new)* | tests | the follows tests in §4 | Rewritten in place where they pin the old follow |

**Builds on.** The S16-24 inputs and `CatalogPageInputs`; the keyed-read registry (`effects.Reads`, `Set.Reads`, `CatalogRead`); `applyHiddenPolicy(followsValue:ids:)` and `(followsOwnId:)`; S16-09's descriptor `refreshes` and stale policy; `add-workspace-place`'s cache update strategy.
**Deletes.** `mismatchedCatalogKey`; the enum case list and the `kind`, `project` and `ownId` switches in `CatalogQueryKey.swift`; the 22 loader `guard case`s, the two in `CatalogLastUpdated.swift` patches and the one in `citationsByArtifact`'s refresh; `CatalogQueryDescriptor.personSection` and `.personGraphsSection`; the `.conclusionDetail` arm's inline Source closure; the claims and record links `graphIDs`/`sourceIDs` closures; the per-key rebuild of a slot's reported set in `revalidatedKeys`; `sources.Records` Apply's use of `SourceScopes`; the three hand lookups of a read's ids (D-4); "Nothing reads it yet." in `CatalogPageInputs`' doc; the `.source` wording in `CatalogWriteEffects` docs, `macos-client-patterns.md` and the map's rules. `CatalogQueryFollows.source` stays (the Sources list's `lastUpdated` patch); `followsValue` stays (D-6 builds on it).
**Next adds.** A new per-entity read (S15-28's records) declares `.entityPage(kind:load:)` and conforms its value to `CatalogPageValue`; S15-21's sheet key (`whenHidden: .evict`, keyed by owner and Property, not a per-handle page) adds `followsInputs(Value.self)` to its own `.make`; S15-05 adds the `date_values` `source_records` path with the date; a Source key that a deletion should evict needs only `deletedWith: .source` now that `sourceWorkspace` has an `ownId`; S16-29's prefetch warms keys that a write now leaves alone, and D-7 keeps the per-write cost flat as it warms more; a Spike 15 key is a new `Kind` case, one factory and one descriptor arm.

### Reach

None — no new navigation path or entry point. One state becomes reachable: a hidden per-entity key that a write no longer marks stale keeps its value; the next `query` returns it as current, which is correct exactly when the inputs are complete (S16-24's handler tests; §11).

### Scale

At the map's Scale (Batch 2): up to 50 hidden entities × 5 keys plus about 20 others, about 270 warmed keys, about 1,300 revalidate refreshes. Per write, `revalidatedKeys` builds each slot's reported set once (D-7): for a real write a few handles, a graph and a Source. Per refresh it runs one `isDisjoint` over the smaller of the value's set and the reported set: a real write costs under 3,000 lookups in all. A crafted write naming 20,000 handles (a hub merge) builds one 20,000-entry set, then for each of the 255 per-entity keys looks up at most the value's handles (Timeline about 2,200 at Scale; bounded by S16-01's caps): under 600,000 lookups, a few ms; the hidden keys it meets are only flagged. The keys this stops reloading: a visible Family or Timeline on every unrelated handle write, and a visible record links (31 ms at 50 graphs), claims and detail on every write in a cited Source. Go: `sources.Records` Apply now runs only on Source, Artifact and credibility writes, so the crafted 10,000-Artifact Source no longer reloads its Artifacts on an Observation edit; `BenchmarkSourceRecords`' Apply figure is unchanged for the writes that still name it. No budget changes: the claim is "no reload", held by T-2, T-6, T-7 and T-8, not a time.

### Edges

- **Assumptions.** (a) A write that moves a value names an id the read recorded (S16-24 §6 Edges): handle values → `Handles`; a link filed, removed or retyped → the association in `Handles` and its ends in `SummaryDeps` (so the Person's own id); a graph's rows → `EvidenceGraphs`; a Source's words → now `source_records`. A Citation's label or page lives in the graph's records and moves `EvidenceGraphs` (effects README: a Citation names the graphs of its Observations), so it reaches the detail through its graphs, not its Source (AC-1.4). (b) Ids are compared only within their slot (D-6). (c) `Set.Reads` keeps the order of `effects.Reads`; a new last entry changes no existing index (T-1). (d) `source_credibility_grades` rows change only at install (S16-12 D-4), so a grade's key or order never moves at runtime; a runtime grade write is a Stop. (e) D-7's memo is local to one `revalidatedKeys` call, so it cannot go stale.
- **Neighbors.** A newly filed relative: the link names the Person, so the own id meets (AC-1.5 holds this with empty inputs). A write to a relative of a relative that the Family read did not read (a cousin): no reload, as intended. A Source note edit: `SourceScopes` only → no page reload, Sources list Updated cell still patched (`sourceWriteEffectsPatchSourcesAndLeaveListsAlone` stays green). A Source date edit: `date_values` → `SourceScopes` only, which is right while no page shows the date from the record (S15-05 adds the path). A Source cover or public flag edit: a `sources` row write names `source_records`; pages that show that Source reload once. A Source type change: a `sources` row write → `source_records`; the claims group's type label reloads. A `reads` entry for `source_records` with no ids: the slot reports nothing and nothing meets.
- **Removed inputs.** A deleted relative: its id is in `Handles` (the delete moves its links) and the page reloads; a deleted page entity is evicted (S16-09, unchanged). A deleted Artifact: `field("source_id")` on the old row names the Source, so the record and its readers drop the label (T-2 "artifact delete"). A deleted Source: `self()` on the old row (T-2 "source delete"). A merge: the merged handles are in `Handles` as today.
- **Real data.** None — no table-driven rule.
- **Untrusted size.** The inputs lists come from the engine's read of the catalog: Timeline at Scale about 2,200 handles (200 events × 10 participants + events), crafted bounded by S16-01's caps (100 kin per role; 20 places per event) and S16-19's 64 owners. Sets are built once at decode (`GoStore.mapPageInputs`); per write the cost is bounded by the smaller of the value's set and the write's ids (Scale).

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/effects` (`registry.go`) | `ReadSourceRecords Read = "source_records"` *(new)*: "the words of a Source: its row, its Artifacts' labels, its credibility (the Source records entry and the app's page inputs). A table the record gains adds its path here." `KeyTable`: `case ReadSourceRecords: return "sources"` (its doc lists it). `Reads` appends it. `sources`: `Reads: []ReadPath{{ReadSourceRecords, self()}}`; `artifacts`: `Reads: []ReadPath{{ReadSourceRecords, field("source_id")}}`; `source_credibility_assessments`: `Reads: []ReadPath{{ReadSourceRecords, field("source_id")}}`. `func (s Set) IDsOf(r Read) [][]byte` *(new)* after `Has` |
| `core/database/sources` (`records.go`) | `Records` Apply: `ids := set.IDsOf(effects.ReadSourceRecords)`; `if len(ids) == 0 { return nil }`; the rest reads `ids` where it read `set.SourceScopes`. `Records`' doc: "patched from the `source_records` read" |
| `core/database/evidencegraphs` (`index.go`) | `Index` Apply: `sourceIDs := set.IDsOf(effects.ReadEvidenceGraphs)`, `graphIDs := set.IDsOf(effects.ReadEvidenceGraphProgress)` in place of the loop |

### FFI

None — `WriteEffects.reads` already carries any read key (`api/proto/engine.proto`); no message changes, no regeneration.

### macOS

No view changes. Session layer:

```swift
// CatalogQueryKey.swift
struct CatalogQueryKey: Hashable, Sendable {
    let kind: Kind
    let project: ProjectKey
    /// The ids the read takes, in its factory's argument order; empty for a catalog-wide read.
    let ids: [String]
    private init(_ kind: Kind, _ project: ProjectKey, _ ids: [String] = []) { self.kind = kind; self.project = project; self.ids = ids }
    /// The key's single id, when it has exactly one.
    var ownId: String? { ids.count == 1 ? ids[0] : nil }
    /// `ownId`, for a loader of a kind that always has exactly one id; a programming error otherwise.
    var id: String { precondition(ids.count == 1, "\(kind) has \(ids.count) ids"); return ids[0] }
    enum Kind: Hashable, Sendable, CaseIterable { /* the 22 cases, unchanged */ }
    static func sourcesList(project: ProjectKey) -> CatalogQueryKey { .init(.sourcesList, project) }
    static func sourceWorkspace(project: ProjectKey, sourceId: String) -> CatalogQueryKey { .init(.sourceWorkspace, project, [sourceId]) }
    static func citationsByArtifact(project: ProjectKey, graphId: String, artifactId: String) -> CatalogQueryKey { .init(.citationsByArtifact, project, [graphId, artifactId]) }
    var citationGraphId: String { ids[0] }      // citationsByArtifact only
    var citationArtifactId: String { ids[1] }   // citationsByArtifact only
    // and one factory for each other kind
}

// CatalogLastUpdated.swift
protocol CatalogPageValue: Sendable { var inputs: CatalogPageInputs { get } }
extension CatalogConclusionDetail: CatalogPageValue {}   // and the other four
enum CatalogQueryFollows: Sendable, Hashable { /* today's cases, unchanged */ }
extension CatalogQueryRefresh {
    static func followsInputs<Value: CatalogPageValue>(_: Value.Type) -> [CatalogQueryRefresh]
}

// CatalogQueryRegistry.swift
static func entityPage<Value: CatalogPageValue>(kind:load:) -> CatalogQueryDescriptor
```

`WorkspaceSession.revalidatedKeys(for:)`: D-7's memo; otherwise as today. `apply`'s `.run` loop is unchanged. States: a per-entity key with no value follows any id of each of its slots (AC-1.7). Accessibility: none.

### Strings

None — no copy changes.

## 7. Steps

**STEP-1 — The `source_records` read**
Files: `core/database/effects/registry.go`, `core/database/effects/reads_test.go`, `core/database/effects/reads_resolve_test.go`, `core/database/effects/evidence_graphs_test.go`, `macos/App/Features/Workspace/Session/CatalogMutation.swift`. Skill: `add-audit-scope` (the `SourceScope` paths stay).
Do: D-3, D-4's `IDsOf`, D-5. `citationReads` returns `set.IDsOf(effects.ReadCitations)`; `evidence_graphs_test.go`'s `readIDs` closure goes and its callers call `set.IDsOf`. Update `TestReadsDeclare` per T-1. In `CatalogMutation.swift`: add `case sourceRecords = "source_records"` ("A Source's words: its row, its Artifacts' labels, its credibility."); the `CatalogRead` doc's key-table list says "Sources for `evidence_graphs` and `source_records`"; the `evidenceGraphs` doc's "A note, metadata, or credibility change is only in `sourceScopes`." becomes "A note, metadata, or credibility change is not in it; a credibility change names its Source in `reads` (`source_records`)."; the `reads` doc lists "citation counts, citations by Artifact, graph progress, the graph list, Property terms and Source words"; the `sourceScopes` doc's clause about detail keys following `.source` becomes "pages follow a Source's words through `reads` (`source_records`), not this scope."
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/effects/... ./api/ffi/...` passes (the vocabulary parity test included).

**STEP-2 — Source records and the graph index read through `IDsOf`**
Files: `core/database/sources/records.go`, `core/database/sources/records_test.go`, `core/database/sources/records_bench_test.go`, `core/database/evidencegraphs/index.go`.
Do: §6 Go core. In `TestRecordsApply`, `check` takes `moves bool`: when true it requires the derived entry dropped (today), when false it requires it kept; the "observation edit" subtest passes `false`, every other subtest `true` (T-2). `TestRecordsApplySwap` and the bench build `effects.Set{Reads: []effects.ReadIDs{{Read: effects.ReadSourceRecords, IDs: ids}}}` where they build `SourceScopes`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/...` passes; `PROVENENCIA_GRAPH_VERIFY=1 CGO_ENABLED=1 go test -tags fts5 ./core/database/sources/... ./core/database/evidencegraphs/... ./core/database/persondetail/... ./core/database/conclusiondetails/...` passes.

**STEP-3 — Keys are plain values**
Files: `macos/App/Features/Workspace/Session/CatalogQueryKey.swift`, `CatalogQueryRegistry.swift`, `CatalogLastUpdated.swift`, `macos/ProvenenciaTests/CatalogQueryRegistryTests.swift`. Skill: `add-workspace-place`.
Do: D-1, D-2. Move each case's doc comment onto its factory; the type's doc says "New workspace places add a `Kind` case, a factory and an arm on `CatalogQueryKey.Kind.descriptor`". Update `ownIdNamesTheKeysOneRow` per T-3 and add T-4. No other file changes: if a call site outside these four files fails to compile, that is a Stop.
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests CODE_SIGNING_ALLOWED=NO` passes; `rg 'case \.[a-zA-Z]+(\(.*\))? = key|mismatchedCatalogKey' macos/App` finds nothing.

**STEP-4 — The per-entity keys follow their inputs**
Files: `macos/App/Features/Workspace/Session/CatalogLastUpdated.swift`, `CatalogQueryRegistry.swift`, `WorkspaceSession.swift`, `macos/App/Platform/GenealogyStore.swift` (the `CatalogPageInputs` doc only).
Do: D-6 – D-9. In `CatalogPageInputs`' doc replace "Nothing reads it yet." with "The session follows them (`CatalogQueryRefresh.followsInputs`)." Delete per §6 Deletes. The per-entity arms' comments say each follows its inputs and its own handle. `revalidatedKeys`' doc adds that each slot's ids are read once per write.
Check: the app builds (`xcodebuild build -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO`); `rg 'personSection|personGraphsSection' macos` finds nothing.

**STEP-5 — Tests of the follow**
Files: `macos/ProvenenciaTests/WorkspaceSessionTests.swift`, `macos/ProvenenciaTests/CatalogQueryRegistryTests.swift`. Skill: `add-swift-test`.
Do: T-5 – T-9. Rewrite the tests §4 lists so seeded values carry `inputs` (D-8: `setQueryValue` for claims; `inputs:` in the memberwise initializers otherwise, including `citedDetail`) and writes name the slots D-6 follows; a test whose point was "any handle reloads Family/Timeline" becomes T-6's or T-7's opposite.
Check: the STEP-3 `xcodebuild test` command passes with no Swift warning.

**STEP-6 — Docs**
Files: `.agents/skills/add-workspace-place/SKILL.md`, `.agents/skills/add-audit-scope/SKILL.md`, `core/database/effects/README.md`, `docs/macos-client-patterns.md`, `docs/catalog-caches.md`, `docs/deployment-plan/spike-16/deployment-plan.md`, `docs/deployment-plan/spike-16/cache-architecture.md`, `docs/deployment-plan/spike-16/completed.md`, this plan.
Do:
- `add-workspace-place`, "Refresh" row: replace the sentence that begins "A per-person section key uses `CatalogQueryDescriptor.personSection`" (ending "(its own handle, and the graphs its value holds).") with: "A per-entity page key (detail and the Person sections) uses `CatalogQueryDescriptor.entityPage(kind:load:)`: its value conforms to `CatalogPageValue`, and `CatalogQueryRefresh.followsInputs` declares one `followsValue` refresh per slot of the value's `inputs` (handles on `.touchedHandles`, Evidence graphs on `.evidenceGraphs`, Sources on `.reads(.sourceRecords)`); its own handle reloads it too (`followsOwnId`)." Step 3: replace "Add `CatalogQueryKey` case (project-scoped payload as needed) and a `Kind` case." with "Add a `Kind` case and a `CatalogQueryKey` factory (`.init(kind, project, ids)`)." and "(`guard case` on the key, calling `GenealogyStore`)" with "(reading `key.project` and `key.id`, calling `GenealogyStore`)".
- In `add-audit-scope` the sentence "The Source records entry (`sources.Records`) reloads the Sources in `Set.SourceScopes`, so `sources`, `artifacts` and `source_credibility_assessments` must keep their `SourceScope` paths; dropping one leaves the records stale." and in the effects README the sentence "The Source records entry (`sources.Records`) reads `SourceScopes` too, to reload the Sources a write names, so `sources`, `artifacts` and `source_credibility_assessments` must keep their `SourceScope` paths." both become: "The Source records entry (`sources.Records`) and the app's page inputs read the `source_records` read, which `sources`, `artifacts` and `source_credibility_assessments` set; a table the Source record gains (S15-05's `date_values`) adds its `source_records` path. Those tables keep their `SourceScope` paths for the audit." The README's list of reads gains "`source_records` (a Source's words: its row, its Artifacts, its credibility; moved only by those three tables, so an Observation or note edit never reloads a Source record)"; its sentence on the Source row ending "updated from `SourceScopes`" ends "updated from the `source_records` read"; its `Set.Reads` sentence names `Set.IDsOf` as the lookup.
- `macos-client-patterns.md`: in rule 2 replace "(activity: patches the Sources row, and the detail keys whose records cite the Source follow it through `.source`)" with "(activity: patches the Sources row)"; the `reads` list gains "`source_records` per Source"; replace "the Evidence graph, list, detail and person-claims keys follow `evidenceGraphs` and `touchedHandles`" with "the Evidence graph and list keys follow `evidenceGraphs` and `touchedHandles`, and the per-entity keys follow their inputs". In "Conclusion keys", the first bullet's "Every Conclusion key (the Persons, Events, and Places lists, `conclusionDetail` and the Person page's reads) follows `touchedHandles`" becomes "The Persons, Events and Places lists follow every `touchedHandles` id"; replace the S16-12 `.source` bullet and the S16-24 bullet with one: "**Per-entity keys follow their inputs** (S16-24, S16-25): the detail and the Person section keys reload when a write names a handle, Evidence graph or Source (`source_records`) their value was built from, or their own id." In "Per-entity keys while hidden", replace "The detail key follows its own handle, property labels and the Sources its records cite (`.source`)." with "Each follows its inputs, its own handle and property labels."
- `catalog-caches.md`: the `sources.records` row's update cell becomes "Apply reloads the Sources in the `source_records` read, then reports the in-place patch to its readers with `Patched`"; the "Per-view query results" row's update cell becomes "the descriptor's `invalidateOn` mutation kinds and `refreshes`; per-entity keys `followsInputs`".
- Map: the S16-25 row's status per the DoD. The row's Scope and Plan link, the scope entry's **Ships**, and the working rules "(Batch 1) A cached detail follows the Sources its records cite", "(Batch 2) Swift caches one value per view, follows its inputs and shows it stale while refreshing", "(Batch 2) A Source's words live once" and "Shared with Spike 15" were updated when this plan was written (2026-11-15); check they still read as this plan says and fix only a difference.
- `cache-architecture.md` § Swift "Values report their inputs": replace "Swift has one `.followsInputs` refresh" with "Swift has one `followsInputs` declaration (a `followsValue` refresh per slot; Sources on the `source_records` read, S16-25)".
- `completed.md`, this plan: per the Definition of done.
Check: links resolve; `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-25-keys-follow-inputs.md` reports no errors; `python3 scripts/check-guidance-names.py` passes.

Commits: one per behavior (D-11). The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Reload a Person page only when a write names what it was built from."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/effects/reads_test.go` `TestReadsDeclare` (updated) | `want[ReadSourceRecords] = {"artifacts", "source_credibility_assessments", "sources"}` with a comment that these are the tables `sources.loadRecords` reads; each path ends at `sources` (the existing loop); the `artifacts` check becomes `eff.EvidenceGraph.zero() && len(eff.Reads) == 1 && eff.Reads[0].Read == ReadSourceRecords`. The map is exhaustive, so no Subject, Observation, Citation or note table carries the read | AC-2.5, D-3 |
| T-2 | Go | `core/database/sources/records_test.go` `TestRecordsApply` (updated) | Real writes through `r.Run`: rename, type change, Artifact create, relabel and delete, credibility, Source delete → the derived entry is dropped and the record has the new words; "observation edit" (`r.Person(src, r.Artifact, "Ada")`) → the derived entry is kept and `Verify` passes | AC-2.4, AC-2.5 |
| T-3 | Swift | `CatalogQueryRegistryTests.ownIdNamesTheKeysOneRow` (updated) | `sourceWorkspace` and `typeSuggestions` `ownId` == their id; `citationsByArtifact` nil; lists nil; the five per-entity kinds' `deletedWith == .handle` | AC-3.2, D-1 |
| T-4 | Swift | `CatalogQueryRegistryTests.keysAreValues` *(new)* | AC-3.1's key: `kind`, `project`, `ids`, `ownId`, `citationGraphId`, `citationArtifactId`; equal to a second call, `hashValue` equal; differs from the same with `artifactId: "a2"`; `.conclusionDetail(project: p, entityId: "e1").id == "e1"` | AC-3.1, D-2 |
| T-5 | Swift | `CatalogQueryRegistryTests.invalidationsComeFromRegistrySpecs`, `personRecordLinksRevalidate` (updated) | The five per-entity kinds: `refreshes.map(\.follows) == [.touchedHandles, .evidenceGraphs, .reads(.sourceRecords), .touchedHandles, .list(.propertyVocabulary)]`; record links with inputs `{graphs: [g1], sources: [src1]}` follows `evidenceGraphs: ["g1"]` and `source_records` `["src1"]`, not `sourceScopes: ["src1"]` | AC-3.3 |
| T-6 | Swift | `WorkspaceSessionTests.familyFollowsEachRelationItWasBuiltFrom` *(new; replaces `personFamilyFollowsEveryTouchedHandle`)*, a table over parent `p1`, implied sibling `s1`, partner `w1`, child `c1`, pivot `m1` | Value inputs hold all five; `handles: [id]` → `[familyKey]`; `handles: ["x9"]` → `[]` | AC-1.1, AC-2.1 |
| T-7 | Swift | `WorkspaceSessionTests.timelineFollowsItsEventsAndCoParticipants` *(new; replaces `personEventsFollowEveryTouchedHandle`)* | Inputs `{ev1, q1}`; `handles: ["q1"]` → named; `summaryHandles: ["ev1"]` → named; `handles: ["x9"]` → `[]` | AC-1.2, AC-2.1 |
| T-8 | Swift | `WorkspaceSessionTests.sourceWordsNotSourceActivityReloadThePage` *(new; replaces `detailFollowsTheSourcesItsRecordsCite` and the `.source` half of `personClaimsFollowHandlesAndGraphs`)* | Claims, record links and detail of `e1` set with `setQueryValue`, inputs `{graphs: [g1], sources: [src1]}`: `reads: [source_records: [src1]]` → all three; `evidenceGraphs: ["g1"]` → all three; the AC-2.2 write → `[]`; `sourceScopes: ["src1"]` → `[]`. Then with FakeStore `seededConclusionDetails["e1"]` = `citedDetail("e1")` with those inputs and the location `.personDetail(entityId: "e1", ref: "PER-e1", title: nil)`: re-seed it with `memberCount = 2`, `apply(reads: [source_records: [src1]])` → fetching, then `memberCount == 2`; after `apply(location: .sectionRoot(.persons))` the same write leaves it stale and not fetching | AC-1.3, AC-1.4, AC-2.2, AC-2.3 |
| T-9 | Swift | `WorkspaceSessionTests.anEntityKeyFollowsItsOwnIdAndAnyIdUntilLoaded` *(new; replaces `personClaimsFollowEveryGraphUntilLoaded`, `personRecordLinksFollowEveryGraphUntilLoaded`)*; `familyReloadsWhenVisibleAndStalesWhenHidden` *(new)* | Each of the five kinds: a value with empty inputs follows `handles: ["e1"]` and not `["x9"]`; a key in its first load follows `handles: ["x9"]`. Family: FakeStore `seededPersonFamilies["e1"]` = no units with inputs `{handles: [w1]}`; `apply(location: .personDetail(entityId: "e1", ref: "PER-e1", title: nil, pageSection: .family))`, settle; re-seed with one partner unit; `apply(handles: ["w1"])` → fetching, then the value has one unit; `apply(location: .sectionRoot(.persons))`, then `apply(handles: ["w1"])` → stale, not fetching | AC-1.5, AC-1.6, AC-1.7 |

Updated, same intent: `personClaimsFollowHandlesAndGraphs` (graphs from inputs), `aKeyInvalidatedAndRefreshedRevalidatesOnce` (the claims value's inputs hold `g1`), `promoteRevalidatesOnlyItsPeople` (unchanged expectations: own id).

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `WorkspaceSessionTests`, `CatalogQueryRegistryTests`, `PersonDetailTests`, `UnpromoteFlowTests`, `core/database/effects`, `core/database/sources`, `core/database/evidencegraphs`, `api/ffi` (vocabulary parity).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none expected)
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md`, `core/database/effects/README.md` and `L10n.swift` with no hit left: `personSection`, `personGraphsSection`, `mismatchedCatalogKey`, "`CatalogQueryKey` case", "through `.source`", "`guard case`s the key", "`.followsInputs` refresh", `SourceScopes` as the Source records signal; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (STEP-6)
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New (no UI change)
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together): the next patch over main at merge
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated): not gated
- [ ] Domain doc updated: core/database/effects/README.md, docs/macos-client-patterns.md, docs/catalog-caches.md (STEP-6)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Open a project with a person who has a spouse, a child and two Evidence graphs in one Source (the large fixture, or a dogfood project). Open the person on Family. In another window, rename a person who is not their relative (a Person page elsewhere, edit a name Observation). The Family section shows no "Refreshing".
2. Rename the spouse the same way. Family shows "Refreshing" and then the new name.
3. Open the person on Sources. In the Source's other graph (one that holds a different person), edit an Observation. The Sources section and the record links diagram show no "Refreshing".
4. Rename the Source. The Sources section and the diagram show the new title; open Vitals and its provenance sheet: the new title.
5. Fix a Citation's page on one of the person's records. Vitals' provenance sheet shows the new page.
6. In the branch, `rg 'case \.[a-zA-Z]+(\(.*\))? = key|mismatchedCatalogKey|personSection|personGraphsSection' macos/App` finds nothing (AC-3.4).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A read records too little, so a write it depends on no longer reloads it (Family and Timeline lose today's "any handle" safety net) | S16-24's handler tests pin each relation's ids; T-6 – T-9 hold the follow; manual check 2; the own-id follow; a hidden key missed by one write shows its old value only until a write meets it or the page reloads |
| A write that changes a Source's words does not name `source_records` | T-1 pins the three tables against `sources.loadRecords`' queries; T-2 runs the writes; `PROVENENCIA_GRAPH_VERIFY=1` checks the records against SQL (STEP-2) |

**Stop and report if:**

- A file under §4 no longer matches its row (a Spike 15 key landed in `CatalogQueryKey`: convert it as D-1 says and report it; any other change: stop).
- A call site outside `CatalogQueryKey.swift`, `CatalogQueryRegistry.swift`, `CatalogLastUpdated.swift` and the tests pattern-matches a key case and fails to compile after STEP-3.
- `entityPage`'s generic `load`, or `followsInputs`' generic `followsValue` closures, do not compile under the project's strict concurrency settings.
- `sources.loadRecords` reads a table other than `sources`, `artifacts`, `source_credibility_assessments` and the seeded `source_credibility_grades` (D-3 would miss it), or any code writes `source_credibility_grades` outside install.
- `PROVENENCIA_GRAPH_VERIFY=1` reports `sources: the stored Source records do not match` in any package after STEP-2.
- A Go test outside `core/database/effects`, `core/database/sources`, `core/database/evidencegraphs` and `api/ffi` changes its expectations because of the new read.
- An existing Swift test outside §4's list must change its expected reloads to pass.

## 12. Open questions

None.

## 13. PR

**Title:** S16-25 — Swift keys become plain values and follow their inputs
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-25-keys-follow-inputs.md`.
