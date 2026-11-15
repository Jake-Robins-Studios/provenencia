# S16-25 — Swift keys become plain values and follow their inputs

**Status:** Draft
**Spike / slice:** Spike 16 · Slice 2e — The app's cache
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: every page draws the same values; only when a cached value reloads changes)
**Board:** —
**Depends on:** S16-24 (landed [#839](https://github.com/mendahu/provenencia/pull/839), reads report their inputs), S16-03 (landed [#769](https://github.com/mendahu/provenencia/pull/769)), S16-09 (landed [#780](https://github.com/mendahu/provenencia/pull/780), `.source` follow and stale pages), S16-12 (landed [#800](https://github.com/mendahu/provenencia/pull/800), Source records)
**Blocks:** S16-29 (prefetch, once a write no longer throws the warmed sections away)
**Branch:** `s16-25-keys-follow-inputs`
**Version bump:** patch — the app reloads fewer pages after a write and the engine reports a new keyed read; nothing new on screen ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md), [`add-audit-scope`](../../../../.agents/skills/add-audit-scope/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/macos-client.mdc`, `.cursor/rules/swift-tests.mdc`, `.cursor/rules/go-tests.mdc`, `.cursor/rules/catalog-queries.mdc`
**Context:** [design § Swift](../cache-architecture.md#swift) ("Values report their inputs"); [`docs/macos-client-patterns.md`](../../../macos-client-patterns.md) "Conclusion keys"; [`core/database/effects/README.md`](../../../../core/database/effects/README.md) (`Set.Reads`); working rules: "(Batch 2) Swift caches one value per view, follows its inputs and shows it stale while refreshing", "(Batch 2) The point of this batch is simpler code", "(Batch 2) A Source's words live once", "(Batch 2) Every cache names the signal that updates it, and updates exactly", "(Batch 1) A cached detail follows the Sources its records cite"; goal bar 14; S16-12 ship log PRF-1
**Planned:** 2026-11-15 against `main` @ `2848675`
**Review:** — (not reviewed yet)

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

A Person, Event or Place page reloads after a write only when the write names something the page was built from: a person, event, place or link it read, an Evidence graph whose records it shows, or a Source whose words it shows. Today the Family and Timeline sections reload on any write that names any handle, and the claims, record links and detail keys reload on any write anywhere inside a Source they cite (S16-12 PRF-1: 31 ms per write at 50 graphs while visible). The app reads the inputs S16-24 put on each value and follows them with one refresh. The engine gains one narrow signal, the `source_records` keyed read, which names a Source only when its words move (its row, an Artifact, its credibility), and the Go Source records entry follows it too.

The cache keys become plain values (kind, project, ids) so that the one refresh, every loader and every patch read the key without a `switch` or a `guard case`.

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
| AC-1.5 | Any of the five keys of `e1` holds a value whose inputs are empty (FakeStore); a write reports `handles: ["e1"]` | The key is named (the key's own id always counts) |
| AC-1.6 | The family key of `e1` is on screen with a value whose inputs hold `w1`; a write reports `handles: ["w1"]` through `apply` | The key reloads (`isFetching`, then the new value). With the page hidden, the same write marks it stale and loads nothing |
| AC-1.7 | A per-entity key whose first load is in flight (no value yet); a write reports `handles: ["x9"]` | The key is named (its inputs are not known yet) |

**US-2.** As a researcher, when I edit something a cached page was not built from, the page is left alone: no reload, no stale mark.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | The family and timeline keys of `e1` with the values of AC-1.1 and AC-1.2; a write reports `handles: ["x9"]` | Neither key is named (today both are) |
| AC-2.2 | The record links and claims keys of AC-1.3; a Subject, Observation, Citation or note edit in graph `g2` of Source `src1`, reported as `evidenceGraphs: ["g2"], sourceScopes: ["src1"], reads: [citations: ["g2"]]` | Neither key is named (S16-12 PRF-1; today both are) |
| AC-2.3 | The detail key of AC-1.4; a write reports `sourceScopes: ["src1"]` only | The detail key is not named |
| AC-2.4 | The engine resolves a Source title edit, an Artifact label edit and a credibility assessment edit | Each `Set.Reads` holds `source_records` with the Source's id |
| AC-2.5 | The engine resolves a Subject create, an Observation edit, a Citation create and a Source note add in that Source | No `Set.Reads` holds `source_records`; `SourceScopes` still holds the Source |

**US-3.** As the engine, the Source records entry reloads a Source's record only when its words moved.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | The records are held; a commit whose `Set.Reads` holds `source_records: [src]` after the title changed | The record of `src` has the new title |
| AC-3.2 | The records are held; a commit with `SourceScopes: [src]` and no `source_records` read | The held index is untouched and no query runs |

**US-4.** As a contributor, a cache key is a value with the same factory spelling, and a new per-entity page key declares one line to follow its inputs.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | `CatalogQueryKey.citationsByArtifact(project: p, graphId: "g1", artifactId: "a1")` | `kind == .citationsByArtifact`, `project == p`, `ids == ["g1", "a1"]`, `ownId == nil`; two calls with the same arguments are equal and hash equal |
| AC-4.2 | `CatalogQueryKey.sourceWorkspace(project: p, sourceId: "s1")` | `ownId == "s1"` |
| AC-4.3 | The five per-entity kinds' descriptors | `refreshes.map(\.follows) == [.inputs, .list(.propertyVocabulary)]`, `whenHidden == .markStale`, `deletedWith == .handle` |
| AC-4.4 | `rg 'guard case|mismatchedCatalogKey|personSection|personGraphsSection|followsValue' macos/App/Features/Workspace/Session` | No hit |

## 3. Scope

| In | Covered by |
| --- | --- |
| Go: `effects.ReadSourceRecords` keyed read (key table `sources`), moved by `sources`, `artifacts`, `source_credibility_assessments` | STEP-1, AC-2.4, AC-2.5 |
| Go: `sources.Records` Apply follows `source_records` instead of `SourceScopes` | STEP-2, AC-3.1, AC-3.2 |
| Swift: `CatalogRead.sourceRecords` | STEP-3 |
| Swift: `CatalogQueryKey` a struct of kind, project and ids with the same static factories; the case list, the `kind`, `project` and `ownId` switches, `mismatchedCatalogKey` and every `guard case` on a key go | STEP-4, AC-4.1, AC-4.2, AC-4.4 |
| Swift: one `.followsInputs` refresh (`CatalogQueryFollows.inputs`, `CatalogPageValue`), and one descriptor helper for the five per-entity kinds | STEP-5, AC-1.1 – AC-1.7, AC-2.1 – AC-2.3, AC-4.3 |
| Swift: `personSection`, `personGraphsSection`, `applyHiddenPolicy(followsValue:ids:)` and the detail's inline `.source` closure go | STEP-5, AC-4.4 |
| Session tests per relation (parent, implied sibling, partner, child, co-participant, cited Source) and the PRF-1 case | STEP-6, T-7 – T-10 |
| Docs: `add-workspace-place`, `add-audit-scope`, `macos-client-patterns.md`, `catalog-caches.md`, effects README, the map's rules | STEP-7 |

| Out | Home |
| --- | --- |
| The Persons, Events and Places lists merging touched rows | S16-26 |
| One primitive for derived values | S16-27 |
| Prefetch of other sections and a hovered person | S16-29 |
| An end-to-end Go test that runs each relation's real FFI write and meets the read's inputs | not planned (D-11) |
| Narrowing `sources`' `source_records` path to the record's columns (`onField`): a date, cover or public flag write also names it | not planned (D-3) |
| `.evidenceGraph`, `.citationCounts`, `.propertyTerms` and the other non-entity kinds following anything new | not planned: they keep their follows |
| FakeStore computing inputs for its values | not planned (D-10) |

## 4. Current state

Verified at `2848675`.

| Area | Where | Today |
| --- | --- | --- |
| Key | `macos/App/Features/Workspace/Session/CatalogQueryKey.swift` `CatalogQueryKey` | An `enum` of 22 cases with associated `project` and ids, a parallel `Kind` enum (`CaseIterable`), and three switches: `kind`, `project`, `ownId` (`ownId` is nil for `sourceWorkspace`, `typeSuggestions`, `citationsByArtifact` and the catalog-wide kinds) |
| Descriptors | `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift` `CatalogQueryKey.Kind.descriptor` | One arm per kind. Every `load` starts with `guard case .x(let project, …) = key else { mismatchedCatalogKey(key, .x) }` (22 times). `citationsByArtifact`'s refresh closure is a `guard case` |
| Per-entity follows | same file, `CatalogQueryDescriptor.personSection`, `.personGraphsSection`, the `.conclusionDetail` arm | Family and Timeline: `applyHiddenPolicyOnAny(follows: .touchedHandles)`, so any handle reloads them. Claims and record links: own id on `.touchedHandles`, graphs from the value on `.evidenceGraphs`, Sources from the value on `.source` (`sourceScopes`). Detail: own id on `.touchedHandles`, an inline closure of every outcome's, owner's and picture's `sourceID` on `.source`. All five add `.followsPropertyLabels` |
| Follow slots and refreshes | `macos/App/Features/Workspace/Session/CatalogLastUpdated.swift` `CatalogQueryFollows`, `CatalogQueryRefresh` (`Action.revalidate`, `.run`; `applyHiddenPolicy(follows:ids:)`, `(followsOwnId:)`, `(followsValue:ids:)`, `applyHiddenPolicyOnAny`) | `followsValue` is used only by the three per-entity arms above. `updatedSourceShell()` and `metadataBoard()` `guard case .sourceWorkspace` on the key |
| Session | `macos/App/Features/Workspace/Session/WorkspaceSession.swift` `revalidatedKeys(for:)` | For each warmed key, each `.revalidate` refresh: reported ids of its slot ∩ the closure's ids, nil meaning any. No other Action is matched there |
| Effects | `macos/App/Features/Workspace/Session/CatalogMutation.swift` `CatalogRead`, `CatalogWriteEffects` | `CatalogRead` has `citations`, `evidenceGraphProgress`, `evidenceGraphs`, `propertyTerms`; a read key this build does not know is dropped by `GoStore.mapWriteEffects`. `touchedHandles` = `handles` ∪ `summaryHandles`. The `sourceScopes` doc says detail keys follow it through `.source` |
| Inputs | `macos/App/Platform/GenealogyStore.swift` `CatalogPageInputs`; `inputs` on `CatalogConclusionDetail`, `CatalogPersonClaims`, `CatalogPersonFamily`, `CatalogPersonTimeline`, `CatalogPersonRecordLinks` | Decoded by `GoStore.mapPageInputs`; doc says "Nothing reads it yet". `FakeStore` returns empty inputs |
| Go reads | `core/database/effects/registry.go` `Read`, `KeyTable`, `Reads`, the `sources`, `artifacts`, `source_credibility_assessments` entries | Four reads. The three Source-word tables set `SourceScope` only; `artifacts` has no `Reads` |
| Go Source records | `core/database/sources/records.go` `Records` Apply | Reloads the Sources in `set.SourceScopes`, so every Observation, Subject, Citation or note edit inside a Source reloads its record and its whole Artifact list (S16-12 §6 Scale: crafted 10,000 Artifacts) |
| Go inputs recorded | `core/database/persondetail/claims.go` `claims` (`in.AddSources`), `recordlinks.go` (calls `claims`), `core/database/conclusiondetails/conclusiondetails.go` `newRecordReader` (`graphfill.RecordsOf(…, in)`), `recordReader` (`r.in.AddSources`) | Claims and record links record their graphs and their groups' Sources; the detail records the graphs of its records and the Source of each record's Artifact |
| Tests | `macos/ProvenenciaTests/WorkspaceSessionTests.swift` `personClaimsFollowHandlesAndGraphs`, `detailFollowsTheSourcesItsRecordsCite`, `personFamilyFollowsEveryTouchedHandle`, `personEventsFollowEveryTouchedHandle`, `personClaimsFollowEveryGraphUntilLoaded`, `personRecordLinksFollowEveryGraphUntilLoaded`, `aKeyInvalidatedAndRefreshedRevalidatesOnce`, `promoteRevalidatesOnlyItsPeople` | Pin today's follows, reading ids from the value's groups and graphs |
| Tests | `macos/ProvenenciaTests/CatalogQueryRegistryTests.swift` `ownIdNamesTheKeysOneRow`, `invalidationsComeFromRegistrySpecs`, `personRecordLinksRevalidate` | Pin `ownId` per kind and each kind's `refreshes.map(\.follows)` |
| Tests | `core/database/effects/reads_test.go` `TestReadsDeclare`; `core/database/sources/records_test.go` `TestRecordsApply`, `TestRecordsApplySwap`; `core/database/sources/records_bench_test.go` `BenchmarkSourceRecords` | Pin the four reads' tables (and that `artifacts` names no read); drive Apply with `effects.Set{SourceScopes: …}` |

**Precedent.** The keyed read `evidence_graphs` (keyed by Source, moved by `evidence_graphs` and `evidence_graph_artifacts`, read by the Go graph index `evidencegraphs.Index` Apply and by the Swift `.evidenceGraphsList` refresh) is the same shape as `source_records`: copy its constant, `KeyTable` arm, `Reads` entry, registry `Reads:` lines and the `for _, r := range set.Reads` loop in `core/database/evidencegraphs/index.go`. `CatalogLastUpdatedRow` (a small protocol in `CatalogLastUpdated.swift` with one empty conformance per value type) is the precedent for `CatalogPageValue`.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `CatalogQueryKey` is `struct CatalogQueryKey: Hashable, Sendable { let kind: Kind; let project: ProjectKey; let ids: [String] }` with a `private init(_ kind: Kind, _ project: ProjectKey, _ ids: [String] = [])` and one `static func` per kind with today's name and labels (for example `sourceWorkspace(project:sourceId:)` and `citationsByArtifact(project:graphId:artifactId:)`), each carrying the doc comment its case has today. `ids` holds the factory's id arguments in order. `Kind` stays the one list of kinds (`CaseIterable`, the descriptor switch). `ownId` is `ids.count == 1 ? ids[0] : nil` | The map row; call sites (`.sourcesList(project:)` and `CatalogQueryKey.x(…)` in tests) compile unchanged; one list of kinds instead of two | Keeping the enum and adding a `value` view (two shapes); named stored fields per id (a field that is nil for most kinds) |
| D-2 | Loaders read `key.project` and `key.ids[0]` (`citationsByArtifact`: `key.ids[0]`, `key.ids[1]`); `updatedSourceShell()` and `metadataBoard()` compare `key.ownId` with the Source id; `citationsByArtifact`'s refresh returns `[key.ids[0]]`. `mismatchedCatalogKey` goes | A descriptor runs only for its own kind (`key.kind.descriptor`), so the `guard case` checked nothing; the factory fixes how many ids a kind has | An accessor per id name — 22 one-line properties for what the factory already documents |
| D-3 | Go `effects.ReadSourceRecords Read = "source_records"`, key table `sources`, appended last to `Reads`. Paths: `sources` `self()`, `artifacts` `field("source_id")`, `source_credibility_assessments` `field("source_id")`. No `onField` narrowing on `sources` | These three tables are exactly what `sources.loadRecords` reads (`sqlRecordSources`, `sqlRecordArtifacts`); one signal for "a Source's words moved" (user, 2026-11-15, option 2); a date, cover or public write is rare and S15-05 adds the date to the record | `SourceScopes` (fires on every write in a Source: PRF-1); an `onField` list (breaks the day the record gains a column) |
| D-4 | `sources.Records` Apply collects the ids of every `set.Reads` entry whose `Read` is `ReadSourceRecords` and reloads those, as it reloads `SourceScopes` today; with none it returns at once | One signal for both readers of Source words (user, 2026-11-15); an Observation edit stops reloading a Source record | Leaving Apply on `SourceScopes` (two signals for one set of words) |
| D-5 | Swift `CatalogRead.sourceRecords = "source_records"`. No proto change: `WriteEffects.reads` carries read keys as strings | `GoStore.mapWriteEffects` already maps any known key | A new `WriteEffects` field — a second way to carry a keyed read |
| D-6 | `CatalogQueryFollows.inputs` *(new)*: a write's `touchedHandles`, `evidenceGraphs` and the ids of `reads(.sourceRecords)`. Its `ids(in:)` returns the three concatenated; `revalidatedKeys` uses that only to skip a write that names none of them. `isCatalogWide` is false | One slot names everything a page value can be built from; the existing skip-empty gate keeps working | Three refreshes per kind (the map asks for one; three closures read the same value) |
| D-7 | `CatalogQueryRefresh.Action.revalidateOnInputs(@MainActor @Sendable (WorkspaceSession, CatalogQueryKey) -> CatalogPageInputs?)` *(new)*, built only by `static func followsInputs<Value: CatalogPageValue>(_: Value.Type) -> CatalogQueryRefresh` *(new)* with `follows: .inputs`. The closure returns the cached value's `inputs` with `key.ownId` inserted into `handles`, or nil while the key holds no value. `revalidatedKeys` names the key when the closure returns nil, or when `CatalogPageInputs.isMet(by: effects)` *(new)* is true: some id of `effects.touchedHandles` is in `handles`, some of `effects.evidenceGraphs` is in `evidenceGraphs`, or some id of the `.sourceRecords` read is in `sources`. Each test loops over the write's ids and looks each up in the value's set | Typed: a graph id is only ever compared with graphs; nil keeps `followsValue`'s "any id until loaded" (AC-1.7); the own id makes a value whose inputs are empty (FakeStore, or an engine that recorded nothing) still follow its own handle (AC-1.5) | Comparing one union of all ids (correct only because ids are unique UUIDs; reads wrong); `applyHiddenPolicy(followsValue:)` with the `.source` slot (cannot express three slots) |
| D-8 | `protocol CatalogPageValue: Sendable { var inputs: CatalogPageInputs { get } }` *(new)* in `CatalogLastUpdated.swift`, with empty conformances for the five value types, as `CatalogLastUpdatedRow` is declared | The refresh is generic over the value; one line per type | A key path argument — `KeyPath` is not `Sendable` under the project's strict concurrency |
| D-9 | `CatalogQueryDescriptor.entityPage<Value: CatalogPageValue>(kind:load:)` *(new)* replaces `personSection` and `personGraphsSection`: `.make(kind:, whenHidden: .markStale, deletedWith: .handle, refreshes: [.followsInputs(Value.self), .followsPropertyLabels], load:)`. All five per-entity arms (`conclusionDetail`, `personClaims`, `personFamily`, `personEvents`, `personRecordLinks`) use it. `applyHiddenPolicy(followsValue:ids:)` goes (no caller left) | The five keys are now declared the same way; the name matches `isEntityPage` | Keeping the two helpers with new bodies — they would differ in name only |
| D-10 | `FakeStore` keeps returning empty inputs. Swift tests that need inputs seed values with `setQueryValue` or set `inputs` on the seeded values | D-7's own id keeps a FakeStore page following its own handle; `swift-tests.mdc` and S12-08's review keep engine rules out of FakeStore | FakeStore computing kin and co-participants — a copy of Go's rules |
| D-11 | Test layers: Go resolve tests for which writes name `source_records` (T-1, T-2), Go Apply tests (T-3); Swift registry tests for the key value and the declared follows (T-4, T-5); Swift session tests, one per relation, seeding values whose inputs hold the ids S16-24's handler tests pin for that relation (`TestGetPersonFamily`: spouse, implied pivot, child; `TestListPersonEvents`: event, co-participant; `TestListPersonClaims`, `TestGetPersonRecordLinks`: graphs and Source), and the PRF-1 case (T-7 – T-10). No end-to-end FFI write per relation | The meeting rule has two halves, each held where it lives: Go records the ids (S16-24's handler tests), the engine's write names them (S16-24 §6 Edges "Assumptions"; the effects tests), and Swift meets them (this PR). An FFI fixture per relation would build six canon fixtures through Promote for a check the three halves already make | An FFI test per relation (S16-24 D-11 named it; a fixture cost that buys no new failure mode) |
| D-12 | Commits: (1) Go read and Apply (STEP-1, STEP-2); (2) the key as a value (STEP-4); (3) the inputs follow and its tests (STEP-3, STEP-5, STEP-6); (4) docs (STEP-7) | Each commit builds and passes its tests; the key change is mechanical and reviews apart from the behavior | One commit |

**Rules this plan bends.** The working rule "(Batch 1) A cached detail follows the Sources its records cite" says the detail key follows the Sources its records cite through `applyHiddenPolicy(followsValue: .source, ids:)` and that any write inside a cited Source revalidates a visible detail. D-7 replaces that with the detail's reported Sources on `source_records`, and S16-12's Out line "A narrower update signal than `SourceScopes`" (not planned, user 2026-11-12) is reversed by D-3 and D-4. The user chose this on 2026-11-15 (option 2: a `source_records` read, followed by the app and by the Go Source records entry). STEP-7 rewrites the rule's mechanism sentence and adds the signal to the rule "(Batch 2) A Source's words live once". The Batch 2 rule "Swift caches one value per view, follows its inputs and shows it stale while refreshing" is followed as written.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `effects.ReadSourceRecords` *(new)* | Go const + registry paths | `effects.ReadEvidenceGraphs` (keyed by Source) | Extends the existing keyed-read registry; `evidence_graphs` names graph-list changes, not Source words |
| `CatalogRead.sourceRecords` *(new)* | Swift enum case | `CatalogRead.evidenceGraphs` | Mirrors the Go constant, as every read does |
| `CatalogQueryKey` as struct, `private init` *(new)* | type | today's enum | Replaces it |
| `CatalogQueryFollows.inputs` *(new)* | enum case | `.touchedHandles`, `.evidenceGraphs`, `.source` | A page value is built from three slots at once; D-6 |
| `CatalogQueryRefresh.Action.revalidateOnInputs` *(new)*, `followsInputs(_:)` *(new)* | Action case, constructor | `.revalidate`, `applyHiddenPolicy(followsValue:ids:)` | `.revalidate` compares one id set with one slot; D-7. `followsValue` goes |
| `CatalogPageInputs.isMet(by:)` *(new)* | method | `revalidatedKeys`' `isDisjoint` | The three typed comparisons in one place, beside the type |
| `CatalogPageValue` *(new)* | protocol | `CatalogLastUpdatedRow` | Same pattern, different field |
| `CatalogQueryDescriptor.entityPage` *(new)* | func | `personSection`, `personGraphsSection` | Replaces both |
| Swift tests T-7 – T-10 *(new)* | tests | `personFamilyFollowsEveryTouchedHandle` and the follows tests in §4 | Rewritten in place where they pin the old follow |

**Builds on.** The S16-24 inputs and `CatalogPageInputs`; the keyed-read registry (`effects.Reads`, `Set.Reads`, `CatalogRead`); S16-09's descriptor `refreshes` and stale policy; `add-workspace-place`'s cache update strategy.
**Deletes.** `mismatchedCatalogKey`; the enum case list and the `kind`, `project` and `ownId` switches in `CatalogQueryKey.swift`; the 22 loader `guard case`s, the two in `CatalogLastUpdated.swift` patches and the one in `citationsByArtifact`'s refresh; `CatalogQueryDescriptor.personSection` and `.personGraphsSection`; `CatalogQueryRefresh.applyHiddenPolicy(followsValue:ids:)`; the `.conclusionDetail` arm's inline Source closure; the claims and record links `graphIDs`/`sourceIDs` closures; `sources.Records` Apply's use of `SourceScopes`; "Nothing reads it yet" in `CatalogPageInputs`' doc; the `.source` wording in `CatalogWriteEffects.sourceScopes`' doc and in `macos-client-patterns.md`. `CatalogQueryFollows.source` stays (the Sources list's `lastUpdated` patch).
**Next adds.** A new per-entity read (S15-28's records, S15-21's sheet key) declares `.entityPage(kind:load:)` or `refreshes: [.followsInputs(Value.self)]` and conforms its value to `CatalogPageValue`; S16-29's prefetch warms keys that a write now leaves alone; a Spike 15 key is a new `Kind` case, one factory and one descriptor arm.

### Reach

None — no new navigation path or entry point. One state becomes reachable: a hidden per-entity key that a write no longer marks stale keeps its value; the next `query` returns it as current, which is correct exactly when the inputs are complete (S16-24's handler tests; §11).

### Scale

At the map's Scale (Batch 2): up to 50 hidden entities × 5 keys plus about 20 others, about 270 warmed keys. Per write, `revalidatedKeys` runs `isMet(by:)` for each of the up to 255 per-entity keys: one set lookup per id the write names in each slot. A real write names a few handles, a graph and a Source: under 3,000 lookups. A crafted write naming 20,000 handles (a hub merge) costs 255 × 20,000 = 5.1 M lookups, about 50 ms on the main actor once; the hidden keys it meets are only flagged. The keys this stops reloading: a visible Family or Timeline on every unrelated handle write, and a visible record links (31 ms at 50 graphs), claims and detail on every write in a cited Source. Go: `sources.Records` Apply now runs only on Source, Artifact and credibility writes, so the crafted 10,000-Artifact Source no longer reloads its Artifacts on an Observation edit; `BenchmarkSourceRecords`' Apply figure is unchanged for the writes that still name it. No budget changes: the claim is "no reload", held by T-8 and T-9, not a time.

### Edges

- **Assumptions.** (a) A write that moves a value names an id the read recorded (S16-24 §6 Edges): handle values → `Handles`; a link filed, removed or retyped → the association in `Handles` and its ends in `SummaryDeps` (so the Person's own id); a graph's rows → `EvidenceGraphs`; a Source's words → now `source_records`. A Citation's label or page lives in the graph's records and moves `EvidenceGraphs` (effects README: a Citation names the graphs of its Observations), so it reaches the detail through its graphs, not its Source (AC-1.4). (b) Ids are compared only within their slot (D-7). (c) `Set.Reads` keeps the order of `effects.Reads`; a new last entry changes no existing index (T-1).
- **Neighbors.** A newly filed relative: the link names the Person, so the own id meets (AC-1.5 holds this with empty inputs). A write to a relative of a relative that the Family read did not read (cousin): no reload, as intended. A Source note edit: `SourceScopes` only → no page reload, Sources list Updated cell still patched (AC-2.5, `sourceWriteEffectsPatchSourcesAndLeaveListsAlone` stays green). A Source date, cover or public flag edit names `source_records` (D-3): pages that show that Source reload once. A Source type change: a `sources` row write → `source_records`; the claims group's type label reloads.
- **Removed inputs.** A deleted relative: its id is in `Handles` (the delete moves its links) and the page reloads; a deleted page entity is evicted (S16-09, unchanged). A deleted Artifact: `field("source_id")` on the old row names the Source, so the record and its readers drop the label. A merge: the merged handles are in `Handles` as today.
- **Real data.** None — no table-driven rule.
- **Untrusted size.** The inputs lists come from the engine's read of the catalog: Timeline at Scale about 2,200 handles (200 events × 10 participants + events), crafted bounded by S16-01's caps (100 kin per role; 20 places per event) and S16-19's 64 owners. Sets are built once at decode (`GoStore.mapPageInputs`); per write the cost follows the write's ids, not the list's size (Scale).

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/effects` (`registry.go`) | `ReadSourceRecords Read = "source_records"` *(new)*: "the words of a Source: its row, its Artifacts' labels, its credibility (the Source records entry and the app's page inputs)". `KeyTable`: `case ReadSourceRecords: return "sources"`. `Reads` appends it. `sources`: `Reads: []ReadPath{{ReadSourceRecords, self()}}`; `artifacts`: `Reads: []ReadPath{{ReadSourceRecords, field("source_id")}}`; `source_credibility_assessments`: `Reads: []ReadPath{{ReadSourceRecords, field("source_id")}}` |
| `core/database/sources` (`records.go`) | `Records` Apply: `var ids [][]byte; for _, r := range set.Reads { if r.Read == effects.ReadSourceRecords { ids = append(ids, r.IDs...) } }`; `if len(ids) == 0 { return nil }`; the rest reads `ids` where it read `set.SourceScopes`. Doc: "patched from the `source_records` read" |

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
    var ownId: String? { ids.count == 1 ? ids[0] : nil }
    enum Kind: Hashable, Sendable, CaseIterable { /* the 22 cases, unchanged */ }
    static func sourcesList(project: ProjectKey) -> CatalogQueryKey { .init(.sourcesList, project) }
    static func sourceWorkspace(project: ProjectKey, sourceId: String) -> CatalogQueryKey { .init(.sourceWorkspace, project, [sourceId]) }
    static func citationsByArtifact(project: ProjectKey, graphId: String, artifactId: String) -> CatalogQueryKey { .init(.citationsByArtifact, project, [graphId, artifactId]) }
    // and one factory for each other kind
}

// CatalogLastUpdated.swift
protocol CatalogPageValue: Sendable { var inputs: CatalogPageInputs { get } }
extension CatalogConclusionDetail: CatalogPageValue {}   // and the other four
enum CatalogQueryFollows { /* today's cases */ case inputs }
extension CatalogPageInputs { func isMet(by effects: CatalogWriteEffects) -> Bool }
struct CatalogQueryRefresh { enum Action { /* .revalidate, .run */ case revalidateOnInputs(@MainActor @Sendable (WorkspaceSession, CatalogQueryKey) -> CatalogPageInputs?) }
    static func followsInputs<Value: CatalogPageValue>(_: Value.Type) -> CatalogQueryRefresh }

// CatalogQueryRegistry.swift
static func entityPage<Value: CatalogPageValue>(kind:load:) -> CatalogQueryDescriptor
```

`WorkspaceSession.revalidatedKeys(for:)` switches on the action: `.revalidate` as today, `.revalidateOnInputs(inputs)` per D-7, `.run` skipped. `apply`'s `.run` loop is unchanged. States: a per-entity key with no value follows any id (AC-1.7). Accessibility: none.

### Strings

None — no copy changes.

## 7. Steps

**STEP-1 — The `source_records` read**
Files: `core/database/effects/registry.go`, `core/database/effects/reads_test.go`, `core/database/effects/reads_resolve_test.go`. Skill: `add-audit-scope` (the `SourceScope` paths stay).
Do: D-3. Update `TestReadsDeclare` per T-1 (its `artifacts` check becomes: `artifacts` names no graph and only `source_records`). Add T-2. Any other Resolve test that pins `Reads` for a Source, Artifact or credibility write gains the `source_records` entry.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/effects/...` passes.

**STEP-2 — Source records follow the read**
Files: `core/database/sources/records.go`, `core/database/sources/records_test.go`, `core/database/sources/records_bench_test.go`.
Do: D-4. `TestRecordsApply`, `TestRecordsApplySwap` and the bench build `effects.Set{Reads: []effects.ReadIDs{{Read: effects.ReadSourceRecords, IDs: ids}}}` where they build `SourceScopes`. Add T-3.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sources/... ./core/database/graphcache/... ./core/database/persondetail/... ./core/database/conclusiondetails/... ./api/ffi/handlers/...` passes; `PROVENENCIA_GRAPH_VERIFY=1` on the same packages passes.

**STEP-3 — The read in Swift**
Files: `macos/App/Features/Workspace/Session/CatalogMutation.swift`.
Do: D-5: `case sourceRecords = "source_records"` with a doc line ("A Source's words: its row, its Artifacts' labels, its credibility"). Rewrite `sourceScopes`' doc: it patches the Sources list's Updated cell; pages follow a Source's words through `reads(.sourceRecords)`.
Check: the app builds (`xcodebuild build -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO`).

**STEP-4 — Keys are plain values**
Files: `macos/App/Features/Workspace/Session/CatalogQueryKey.swift`, `CatalogQueryRegistry.swift`, `CatalogLastUpdated.swift`, `macos/ProvenenciaTests/CatalogQueryRegistryTests.swift`. Skill: `add-workspace-place`.
Do: D-1, D-2. Move each case's doc comment onto its factory; keep the type's doc but say "New workspace places add a `Kind` case, a factory and an arm on `CatalogQueryKey.Kind.descriptor`". Update `ownIdNamesTheKeysOneRow` per T-4 and add T-5's key value cases there. No other file changes: if a call site outside these four files fails to compile, that is a Stop.
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests CODE_SIGNING_ALLOWED=NO` passes; `rg 'guard case|mismatchedCatalogKey' macos/App/Features/Workspace/Session` finds nothing.

**STEP-5 — One follow of the inputs**
Files: `macos/App/Features/Workspace/Session/CatalogLastUpdated.swift`, `CatalogQueryRegistry.swift`, `WorkspaceSession.swift`, `macos/App/Platform/GenealogyStore.swift` (the `CatalogPageInputs` doc only).
Do: D-6 – D-9. `CatalogPageInputs`' doc: replace its last sentence "Nothing reads it yet." with "The session follows them (`CatalogQueryRefresh.followsInputs`)." Delete per §6 Deletes. Update the per-entity arms' comments to say they follow their inputs.
Check: the app builds; `rg 'personSection|personGraphsSection|followsValue' macos` finds nothing.

**STEP-6 — Tests of the follow**
Files: `macos/ProvenenciaTests/WorkspaceSessionTests.swift`, `macos/ProvenenciaTests/CatalogQueryRegistryTests.swift`. Skill: `add-swift-test`.
Do: T-6 – T-10. Rewrite the tests §4 lists so seeded values carry `inputs` and writes name the slots D-6 follows; a test whose point was "any handle reloads Family/Timeline" becomes T-8's opposite.
Check: the same `xcodebuild test` passes with no Swift warning.

**STEP-7 — Docs**
Files: `.agents/skills/add-workspace-place/SKILL.md`, `.agents/skills/add-audit-scope/SKILL.md`, `core/database/effects/README.md`, `docs/macos-client-patterns.md`, `docs/catalog-caches.md`, `docs/deployment-plan/spike-16/deployment-plan.md`, `docs/deployment-plan/spike-16/cache-architecture.md`, `docs/deployment-plan/spike-16/completed.md`, this plan.
Do:
- `add-workspace-place`: in "Refresh", replace the sentences from "A refresh whose ids come from the cached value uses `followsValue`" through the end of the sentence that ends "(its own handle, and the graphs its value holds)." with: "A per-entity page key (detail and the Person sections) uses `CatalogQueryDescriptor.entityPage(kind:load:)`: its value conforms to `CatalogPageValue`, and `followsInputs` reloads it when a write names a handle, Evidence graph or Source (`reads(.sourceRecords)`) in the value's `inputs`, or the key's own id; until the value arrives it follows any." In step 3, replace "Add `CatalogQueryKey` case (project-scoped payload as needed) and a `Kind` case." with "Add a `Kind` case and a `CatalogQueryKey` factory (`.init(kind, project, ids)`)" and "(`guard case` on the key, calling `GenealogyStore`)" with "(reading `key.project` and `key.ids`, calling `GenealogyStore`)". Add `.inputs` to the slot list.
- `add-audit-scope` line 46 and `core/database/effects/README.md`'s matching sentence: the Source records entry reads the `source_records` read, not `SourceScopes`; `sources`, `artifacts` and `source_credibility_assessments` keep their `SourceScope` paths for the audit and their `source_records` paths for the records. Add `source_records` to the README's list of reads.
- `macos-client-patterns.md` "Conclusion keys": replace the S16-12 `.source` bullet and the S16-24 bullet with one: "**Per-entity keys follow their inputs** (S16-24, S16-25): the detail and the Person section keys reload when a write names a handle, Evidence graph or Source (`source_records`) their value was built from, or their own id; the Persons, Events and Places lists still follow every touched handle." In "Per-entity keys while hidden", replace "The detail key follows its own handle, property labels and the Sources its records cite (`.source`)." with "Each follows its inputs and property labels."
- `catalog-caches.md`: the `sources.records` row's update signal is the `source_records` read; the per-view row names `followsInputs` for the per-entity kinds.
- Map: S16-25 row Scope starts "Go and Swift: a `source_records` keyed read names a Source when its words move, and the Source records entry and the app follow it;" then today's text; Plan link; status. Scope entry **Ships** gains that sentence. Working rule "(Batch 1) A cached detail follows the Sources its records cite": replace its second and third sentences (from "`.conclusionDetail` refreshes when" through "(one read, `GetConclusionDetail`)") with "`.conclusionDetail` refreshes when a write names a Source that one of its field records, derived-row owners or pictures cites, through its inputs on the `source_records` read (S16-25), so only a write to that Source's words, its Artifacts or its credibility reloads a visible detail; a Citation fix arrives through the detail's Evidence graphs." Working rule "(Batch 2) A Source's words live once": append "A Source's words move on one keyed read, `source_records` (its row, its Artifacts, its credibility), which the Source records entry and the app's page inputs follow; `SourceScopes` stays the audit activity scope (user, 2026-11-15, reversing S16-12's 2026-11-12 'not planned')." Binds line adds S16-25.
- `cache-architecture.md` § Swift "Values report their inputs": add "Sources on the `source_records` read (S16-25)".
- `completed.md`, this plan: per the Definition of done.
Check: links resolve; `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-25-keys-follow-inputs.md`; `scripts/check-guidance-names.py` passes.

Commits: one per behavior (D-12). The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Reload a Person page only when a write names what it was built from."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/effects/reads_test.go` `TestReadsDeclare` (updated) | `want[ReadSourceRecords] = {"artifacts", "source_credibility_assessments", "sources"}`, each path ends at `sources`; `artifacts` names no graph and `[]ReadPath{{ReadSourceRecords, field("source_id")}}` only | D-3 |
| T-2 | Go | `core/database/effects/reads_resolve_test.go` `TestSourceRecordsReadNamesOnlySourceWords` *(new)*, table-driven on `readsFixture` | `sources.Update` (title) → `source_records` = [src]; `artifacts.Update` (label) → [src]; `subjects.Create` in Jones, `observations.Update`, `citations.CreateWithObservations`, `sources.AddNote` → no `source_records` entry and `SourceScopes` = [src] | AC-2.4, AC-2.5 |
| T-3 | Go | `core/database/sources/records_test.go` `TestRecordsApplyFollowsSourceRecords` *(new)* | Records held; rename `src` in the transaction; `OnCommit` with `SourceScopes: [src]` only → the held record keeps the old title; then with `Reads: [{source_records, [src]}]` → new title | AC-3.1, AC-3.2 |
| T-4 | Swift | `CatalogQueryRegistryTests.ownIdNamesTheKeysOneRow` (updated) | `sourceWorkspace` and `typeSuggestions` `ownId` == their id; `citationsByArtifact` nil; lists nil; the five per-entity kinds' `deletedWith == .handle` | AC-4.2, D-1 |
| T-5 | Swift | `CatalogQueryRegistryTests.keysAreValues` *(new)* | AC-4.1's key: `kind`, `project`, `ids`, `ownId`; equal to a second call, `hashValue` equal; differs from the same with `artifactId: "a2"` | AC-4.1 |
| T-6 | Swift | `CatalogQueryRegistryTests.invalidationsComeFromRegistrySpecs`, `personRecordLinksRevalidate` (updated) | The five per-entity kinds: `refreshes.map(\.follows) == [.inputs, .list(.propertyVocabulary)]`; record links follows graph `g1`, Source `src1` on `source_records`, not on `sourceScopes` | AC-4.3 |
| T-7 | Swift | `WorkspaceSessionTests.familyFollowsEachRelationItWasBuiltFrom` *(new; replaces `personFamilyFollowsEveryTouchedHandle`)*, table-driven over parent `p1`, implied sibling `s1`, partner `w1`, child `c1`, pivot `m1` | Value inputs hold all five; `handles: [id]` → `[familyKey]`; `handles: ["x9"]` → `[]` | AC-1.1, AC-2.1 |
| T-8 | Swift | `WorkspaceSessionTests.timelineFollowsItsEventsAndCoParticipants` *(new; replaces `personEventsFollowEveryTouchedHandle`)* | Inputs `{ev1, q1}`; `handles: ["q1"]` → named; `summaryHandles: ["ev1"]` → named; `handles: ["x9"]` → `[]` | AC-1.2, AC-2.1 |
| T-9 | Swift | `WorkspaceSessionTests.sourceWordsNotSourceActivityReloadThePage` *(new; replaces `detailFollowsTheSourcesItsRecordsCite` and the `.source` half of `personClaimsFollowHandlesAndGraphs`)* | Claims, record links and detail of `e1` with inputs `{graphs: [g1], sources: [src1]}`: `reads: [source_records: [src1]]` → all three; `evidenceGraphs: ["g1"]` → all three; the AC-2.2 write → `[]`; `sourceScopes: ["src1"]` → `[]`. Then with the detail on screen: `apply(reads: [source_records: [src1]])` reloads it to the new value; hidden, it is stale and not fetching | AC-1.3, AC-1.4, AC-2.2, AC-2.3 |
| T-10 | Swift | `WorkspaceSessionTests.anEntityKeyFollowsItsOwnIdAndAnyIdUntilLoaded` *(new; replaces `personClaimsFollowEveryGraphUntilLoaded`, `personRecordLinksFollowEveryGraphUntilLoaded`)*; `familyReloadsWhenVisibleAndStalesWhenHidden` *(new)* | Each of the five kinds: a value with empty inputs follows `handles: ["e1"]` and not `["x9"]`; a key in its first load follows `handles: ["x9"]`. Family on screen with inputs `{w1}`: `apply(handles: ["w1"])` → fetching then the FakeStore's new value; on the Persons list: stale, not fetching | AC-1.5, AC-1.6, AC-1.7 |

Updated, same intent: `personClaimsFollowHandlesAndGraphs` (graphs from inputs), `aKeyInvalidatedAndRefreshedRevalidatesOnce` (the claims value's inputs hold `g1`), `promoteRevalidatesOnlyItsPeople` (unchanged expectations; own id).

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `WorkspaceSessionTests`, `CatalogQueryRegistryTests`, `PersonDetailTests`, `UnpromoteFlowTests`, `core/database/effects`, `core/database/sources`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none expected)
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left: `personSection`, `personGraphsSection`, `followsValue`, `mismatchedCatalogKey`, "`CatalogQueryKey` case", `Set.SourceScopes` as the Source records signal; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (STEP-7)
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New (no UI change)
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together): the next patch over main at merge
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated): not gated
- [ ] Domain doc updated: core/database/effects/README.md, docs/macos-client-patterns.md, docs/catalog-caches.md (STEP-7)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Open a project with a person who has a spouse, a child and two Evidence graphs in one Source (the large fixture, or a dogfood project). Open the person on Family. In another window, rename a person who is not their relative (a Person page elsewhere, edit a name Observation). The Family section shows no "Refreshing".
2. Rename the spouse the same way. Family shows "Refreshing" and then the new name.
3. Open the person on Sources. In the Source's other graph (one that holds a different person), edit an Observation. The Sources section and the record links diagram show no "Refreshing".
4. Rename the Source. The Sources section and the diagram show the new title; open Vitals and its provenance sheet: the new title.
5. Fix a Citation's page on one of the person's records. Vitals' provenance sheet shows the new page.
6. In the branch, `rg 'guard case|mismatchedCatalogKey|personSection|personGraphsSection|followsValue' macos/App/Features/Workspace/Session` finds nothing (AC-4.4).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A read records too little, so a write it depends on no longer reloads it (Family and Timeline lose today's "any handle" safety net) | S16-24's handler tests pin each relation's ids; T-7 – T-10 hold the follow; manual check 2; D-7's own id; a hidden key still reloads on its next visit only if stale, so a missed id shows an old value until the next write that meets it |
| A write that changes a Source's words does not name `source_records` | T-1 pins the three tables against `sources.loadRecords`' queries; T-2 runs the writes; `PROVENENCIA_GRAPH_VERIFY=1` checks the records against SQL (STEP-2) |
| `KeyPath`-free generic refresh does not type-check under strict concurrency | D-8 uses a protocol; compile in STEP-5 |

**Stop and report if:**

- A file under §4 no longer matches its row (a Spike 15 key landed in `CatalogQueryKey`: convert it as D-1 says and report it; any other change: stop).
- A call site outside `CatalogQueryKey.swift`, `CatalogQueryRegistry.swift`, `CatalogLastUpdated.swift` and the tests pattern-matches a key case and fails to compile after STEP-4.
- `sources.loadRecords` reads a table other than `sources`, `artifacts` and the grades joined through `source_credibility_assessments` (D-3 would miss it).
- `PROVENENCIA_GRAPH_VERIFY=1` reports `sources: the stored Source records do not match` in any package after STEP-2.
- A Go test outside `core/database/effects` and `core/database/sources` changes its expectations because of the new read.
- An existing Swift test outside §4's list must change its expected reloads to pass.

## 12. Open questions

None.

## 13. PR

**Title:** S16-25 — Swift keys become plain values and follow their inputs
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-25-keys-follow-inputs.md`.
