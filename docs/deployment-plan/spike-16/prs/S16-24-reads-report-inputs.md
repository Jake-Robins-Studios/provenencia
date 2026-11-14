# S16-24 — Person, Event and Place reads report their inputs

**Status:** Landed in [#839](https://github.com/mendahu/provenencia/pull/839) (2026-11-14)
**Spike / slice:** Spike 16 · Slice 2e — The app's cache
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: every page draws the same values; the reads only gain a list the app does not read yet)
**Board:** —
**Depends on:** S16-16 (landed [#814](https://github.com/mendahu/provenencia/pull/814), composed kinship), S16-30 (landed [#812](https://github.com/mendahu/provenencia/pull/812), provenance from records), S16-13 (landed [#809](https://github.com/mendahu/provenencia/pull/809), records tier), S16-19 (landed [#821](https://github.com/mendahu/provenencia/pull/821), summary rows carry owners), S14-42 (landed [#748](https://github.com/mendahu/provenencia/pull/748), exact summary dependents)
**Blocks:** S16-25 (follows the inputs in Swift), S15-28 (its records read reports its inputs as these reads do)
**Branch:** `s16-24-reads-report-inputs`
**Version bump:** none — no change a researcher can see; the wire change ships inside the one app binary ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-catalog-query`](../../../../.agents/skills/add-catalog-query/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/catalog-queries.mdc`, `.cursor/rules/ffi-handlers.mdc`, `.cursor/rules/go-tests.mdc`, `.cursor/rules/swift-tests.mdc`, `.cursor/rules/macos-client.mdc`
**Context:** [design § Swift](../cache-architecture.md#swift) ("Values report their inputs"); [design § A cache a composer reads hands its inputs to the row](../cache-architecture.md#a-cache-a-composer-reads-hands-its-inputs-to-the-row); [`docs/macos-client-patterns.md`](../../../macos-client-patterns.md) "Conclusion keys"; working rules: "(Batch 2) The point of this batch is simpler code" (as clarified 2026-11-13), "(Batch 2) Swift caches one value per view, follows its inputs and shows it stale while refreshing", "(Batch 2) Every cache names the signal that updates it, and updates exactly", "(Batch 2) Orders are defined and results do not move"; goal bar 14
**Planned:** 2026-11-14 against `main` @ `43fd47e`
**Review:** [`S16-24-reads-report-inputs.review.md`](S16-24-reads-report-inputs.review.md) — round 1: Fits with changes / Ready with changes; round 2: Fits with changes / Ready with changes; every finding Fixed, nothing To user; Planned

**Landed.** Differences from the plan: since the plan's base S16-21 split a place's succession links into their own entry (`placeSuccession`), so `AttachPlaceRelationships` also records that entry's `inputs` (D-4 named the page and own entries), which AC-1.3 needs for the succession association. D-4 now records every part the page reads, not only the ones it lists, so a write to a part's dates that hides it still reaches the page (CON-1); test helpers pass `PageInputs()` where D-2 says `NoPageInputs()`, which changes no value (CON-3).

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

Each per-entity Conclusion read (the detail of a Person, Event or Place, and a Person's claims, family, timeline and record links) returns, beside its value, what it was built from: the handles it read, the Evidence graphs whose records it shows and the Sources whose words it shows, as three wire lists. The app decodes them and reads nothing from them yet. This is the engine half of rule "Swift caches one value per view, follows its inputs…": S16-25 replaces Swift's hand-written selectors (`personSection`, `personGraphsSection`, the per-kind id closures and the `.source` follows) with one follow of these lists.

**Why now.** S16-16, S16-30, S16-13 and S16-19 rewrote these reads onto the cache; the lists are recorded on the reads as they now stand. S16-25 cannot narrow Family and Timeline from "any handle write" until a read says which handles it depends on, including ones it reads but does not show (a lone marriage event, a provisional relative).

**What stays.** Every value is byte-for-byte what it is today: same rows, same order, same fields. No SQL is added: recording reads only what the read already holds. `graphcache.InputKey` keeps its one kind and the persisted input index (`catalog_search_inputs`) is untouched. Swift follows exactly what it follows today.

## 2. User stories

**US-1.** As the app, when I load a Person, Event or Place page or a Person section, I receive the handles, graphs and Sources the value was built from, so that S16-25 can reload that value exactly when a write names one of them.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A Person Ada with name Observations on graph "Baptisms" (Source "St Mary") and graph "Burials" (Source "St John"), and a likeness on "Baptisms"; `GetConclusionDetail(Ada)` | `inputs.handles` holds Ada; `inputs.evidence_graphs` holds both graphs; `inputs.sources` holds both Sources |
| AC-1.2 | A Person Pat born at event B (dated 1820) located at Place Town through link L; `GetConclusionDetail(Pat)` | `inputs.handles` holds Pat, B, L and Town (the derived rows' owners and the place they hold) |
| AC-1.3 | A Place Town `part_of` County through association P, with successor NewTown; `GetConclusionDetail(Town)` | `inputs.handles` holds Town, County, P and NewTown |
| AC-1.4 | `ListPersonClaims(Ada)` over the fixture of AC-1.1 | `inputs.handles` is exactly [Ada]; `inputs.evidence_graphs` holds both graphs; `inputs.sources` holds both Sources |
| AC-1.5 | `GetPersonRecordLinks(Ada)` | `inputs.evidence_graphs` and `inputs.sources` equal the graphs and Sources of the response's `graphs`; `inputs.handles` holds Ada |
| AC-1.6 | Pat married to Sam at M1 and to Tess; child Uma with Sam (link `patUma`), child Wren with Xan; `GetPersonFamily(Pat)` | `inputs.handles` holds Pat, Sam, Tess, Uma, Wren, Xan, M1 and `patUma` |
| AC-1.7 | Pat stands alone in a marriage event M2 with no spouse filed; `Families` for Pat | `inputs` handles hold M2, so a spouse filed at M2 later reaches the read |
| AC-1.8 | Pat's child Vic is provisional (not shown); `Families` for Pat | `inputs` handles hold Vic, so Vic turning canonical reaches the read |
| AC-1.9 | Pat attends census CS with Kid, and burial U (witness) where Ned is subject; `ListPersonEvents(Pat)` | `inputs.handles` holds Pat, CS, U, Kid, Ned and each participation association of Pat |
| AC-1.10 | Ghost is a provisional participant at U (not shown); `PersonEvents` for Pat | `inputs` handles hold Ghost |
| AC-1.11 | Any of the five reads, read twice warm | The second read issues no SQL beyond what it issues today (the file-path query of the detail), and its inputs equal the first's |
| AC-1.12 | A response's `inputs` decoded by `GoStore` | Each `Catalog…` value carries `inputs` with the same ids as sets; FakeStore values carry empty inputs |

## 3. Scope

| In | Covered by |
| --- | --- |
| `graphcache.PageInputs`: one recorder of handles (through an `InputScope`), graphs and Sources, giving three sorted distinct lists | STEP-1, T-1 |
| The detail read records its handle, its records' graphs and Sources, its derived rows' owners, and a Place's relationship inputs | STEP-2, STEP-3, AC-1.1 – AC-1.3 |
| The claims and record links reads record the person, their graphs and Sources | STEP-4, AC-1.4, AC-1.5 |
| The Timeline read records the person, its participation links, every linked event and every participant on the event rows | STEP-5, AC-1.9, AC-1.10 |
| The Family read records each node the kinship read derives from with its neighbours and links, every relative it names and every summary it reads | STEP-6, AC-1.6 – AC-1.8 |
| `PageInputs` proto message on the five responses; handlers fill it | STEP-7, T-10 |
| Swift decodes it onto each value; the claims value becomes `CatalogPersonClaims` | STEP-8, AC-1.12 |
| Warm reads stay SQL-free and within today's budgets | STEP-2 – STEP-6, AC-1.11 |

| Out | Home |
| --- | --- |
| Swift following the lists (`.followsInputs`), deleting `personSection`, `personGraphsSection`, the id closures and the `.source` follows | S16-25 |
| Session tests that a write per relation reloads or leaves a section | S16-25 |
| Cache keys as plain values | S16-25 |
| The records read by (owner, Property) pairs reporting its inputs | S15-28 |
| The Persons, Events and Places lists' touched-row merge | S16-26 |
| A cap on the inputs lists | not planned — the lists are bounded by what the read already loads (§6 Edges) |
| Bridge and endpoint on the wire (only ids are sent) | not planned — the app's write effects name ids, so ids are what it can match |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Input recording | `core/database/graphcache/inputs.go` `InputScope`, `Graph.Inputs`, `NoInputs`, `NodeKey`, `FollowKeys`, `InputScope.Add`, `InputScope.Keys` | Records `InputKey`s for summary rows (S14-40); `Inputs(nil)` records every key; `Add` and `add` are nil-safe. No page read uses it |
| Detail read | `core/database/conclusiondetails/conclusiondetails.go` `ForEntity`, `fieldsOf`, `newRecordReader`, `recordReader.outcome`, `PersonDerivedRows` | Composes fields, pictures and derived rows from the node, `graphfill.RecordsOf` and `sources.RecordsOf`; records nothing |
| Detail summary | `api/ffi/handlers/conclusion_detail.go` `GetConclusionDetail`, `attachSummary`, `attachPictures` | Reads the kind's summary row, a Person's derived rows, a Place's relationships, picture paths |
| Place relationships | `core/database/conclusionsummaries/placechains.go` `AttachPlaceRelationships`; `compose.go` `placeStep`; `placeentries.go` `placeEntry.inputs`, `placePage.inputs` | Fills PartOf, Contains, Predecessors, Successors from place entries and the place's page, both of which hold their `InputKey`s; the keys are not handed out |
| Claims read | `core/database/persondetail/claims.go` `Claims`, `claims`, `personNode`, `boundedMembers` | Groups claims by Source from the graph index, the Source records and the per-graph records; records nothing |
| Record links read | `core/database/persondetail/recordlinks.go` `RecordLinks`, `recordLinks`, `linksBetween` | Calls `claims`, then loads each graph's layer; records nothing |
| Timeline read | `core/database/persondetail/timeline.go` `PersonEvents` | `g.Follow(entityID, hops.EventsOfParticipant)`, `g.Nodes`, `EventsByIDs`, `PersonsByIDs`; records nothing |
| Family read | `core/database/persondetail/family.go` `Families`, `PersonFamily`, `shownKin` | Two `canonlinks.Reader.Relationships` calls, `KinOf`, summaries `ByIDs`; records nothing |
| Kinship reader | `core/database/canonlinks/reader.go` `Options`, `Reader.Relationships`, `deriver.loadSteps`, `stepped`, `neighborsOf` | `loadSteps` loads each id, its neighbours, its step people and theirs; `Options` holds `Siblings` only |
| Handlers | `api/ffi/handlers/person_detail.go` `ListPersonClaims`, `GetPersonFamily`, `ListPersonEvents`, `GetPersonRecordLinks`; `api/ffi/handlers/write_effects.go` `idStrings` | Map values to protos; `idStrings` maps ids to UUID strings |
| Wire | `api/proto/engine.proto` `ConclusionDetail` (fields 1–4, 7, 8; reserved 5, 6), `ListPersonClaimsResponse` (1), `GetPersonFamilyResponse` (1–3), `ListPersonEventsResponse` (1–3), `GetPersonRecordLinksResponse` (1–4) | No inputs |
| Swift values | `macos/App/Platform/GenealogyStore.swift` `CatalogConclusionDetail`, `CatalogPersonFamily`, `CatalogPersonTimeline`, `CatalogPersonRecordLinks`, `CatalogPersonClaimGroup`; protocol `listPersonClaims` returns `[CatalogPersonClaimGroup]` | No inputs; claims are a bare array |
| Swift decode | `macos/App/Platform/GoStore.swift` `listPersonClaims`, `getPersonFamily`, `listPersonEvents`, `getPersonRecordLinks`, `mapPersonRecordLinks`, `getConclusionDetail` | Map protos to values |
| Swift claims users | `macos/App/Platform/FakeStore.swift` `listPersonClaims`, `seededPersonClaims`; `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift` `.personClaims`; `macos/App/Features/Conclusions/PersonSourcesSection.swift` (host `ConclusionPageSectionHost<[CatalogPersonClaimGroup], …>`, preview `failAfterFirstAnswer`); `macos/App/Features/Conclusions/PersonSourcesPreviewData.swift` `previewSession` | Read `[CatalogPersonClaimGroup]` |
| Swift follows | `CatalogQueryRegistry.swift` `personSection`, `personGraphsSection`, `.conclusionDetail`'s `.source` closure | Unchanged by this PR (S16-25) |
| Tests | `core/database/conclusiondetails/conclusiondetails_test.go`, `export_test.go` `FieldsOf`; `core/database/persondetail/*_test.go` (`caps_test.go` `TestCraftedFamily`, `TestCraftedClaims`; `detail_budget_test.go` `TestDetailBudgets`; `claims_budget_test.go` `TestClaimsBudgets`; `recordlinks_perf_test.go` `TestRecordLinksBudgets`; `family_query_test.go` `TestPersonFamilyQueryCount`; `timeline_test.go` `TestPersonEventsQueryCount`; `claims_test.go` `TestClaimsWarmReadIssuesNoQuery`); `core/database/canonlinks/reader_test.go`; `core/database/conclusionsummaries/placechains_test.go` `TestAttachPlaceRelationships`; `api/ffi/handlers/conclusion_detail_test.go`, `person_detail_test.go`; Swift `CatalogQueryRegistryTests.swift`, `WorkspaceSessionTests.swift`, `PersonSourcesContentTests.swift`, `OnboardingModelTests.swift` (its stub store's `listPersonClaims`) | Call today's signatures |

**Precedent.** S14-40 (#746) recorded a summary row's inputs through `graphcache.InputScope` passed down the composers, reading through its `Node` and `Follow`, with `NoInputs()` for reads that record nothing; copy that whole shape (read through the recorder, `NoPageInputs()` for no recording, no SQL). S16-01 (#756) added wire fields to these same responses and their `GoStore` mapping; copy its proto comment style and its handler-test assertions. Do not copy S14-40's persisted index: nothing here is stored.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | One recorder type, `graphcache.PageInputs` *(new)* in `core/database/graphcache/pageinputs.go`, made by `(g *Graph) PageInputs() *PageInputs` (records) and `(g *Graph) NoPageInputs() *PageInputs` (reads, records nothing), as `Inputs` and `NoInputs` are for summary rows. It holds an `InputScope` (from `g.Inputs(nil)`, or `g.NoInputs()`) and two id sets. **Reads:** `Node(id []byte) (*Node, error)` and `Follow(id []byte, hop hops.Hop) ([]Link, error)` delegate to the scope, so a read that reads a handle through them records it; `Nodes(ids [][]byte) error` loads and records nothing, as `InputScope.Nodes`; `Cached(id []byte) (*Node, bool)` is `Graph.Cached` (never loads) and records the id, found or not, as `InputScope.Node` records a missing node. **Adds,** for ids taken from rows already in hand (never for a node the read looks up): `AddHandles(ids ...[]byte)` (`NodeKey` each), `AddKeys(keys ...InputKey)`, `AddEvidenceGraphs(ids ...[]byte)`, `AddSources(ids ...[]byte)`; on a recording `PageInputs` each goes through `InputScope.Add`, so a test recorder hears it; a `NoPageInputs` recorder returns before calling `Add` (whose test hook fires even on an off scope), so it records and reports nothing. `NoPageInputs` on a nil `*Graph` returns a recorder that records nothing and whose `Node` and `Follow` return what a nil graph returns; `PageInputs` is only made on an open graph. `Lists() (handles, evidenceGraphs, sources [][]byte)` returns each list distinct, in byte order, dropping any id that is not 16 bytes; `handles` are the distinct `ID`s of the scope's keys | Handles go through the one existing "record what a read read" mechanism, read-through as `.cursor/rules/catalog-queries.mdc` teaches it for composers (review M-2); place entries hold `InputKey`s and hand them in as they are; one type for every read and for S15-28; one "records nothing" convention, as `NoInputs` | Three new `InputKey` kinds — the map keeps `InputKey` one kind because the persisted index stores it (K-28); a nil recorder for "records nothing" — a second convention beside `NoInputs`, and a nil recorder cannot read; a field on each result type — `Claims` returns a slice and `Families` reads several people at once |
| D-2 | Every page read takes `in *graphcache.PageInputs` as its last parameter: `conclusiondetails.Handle`, `conclusiondetails.ForEntity`, `conclusiondetails.PersonDerivedRows`, `conclusionsummaries.AttachPlaceRelationships`, `graphfill.RecordsOf`, `persondetail.Claims`, `persondetail.RecordLinks`, `persondetail.PersonEvents`, `persondetail.Families`, `persondetail.PersonFamily`, `canonlinks.Reader.Relationships`, and the unexported `fieldsOf`, `newRecordReader`, `claims`, `recordLinks`, `personNode`, `shownKin`, `deriver.loadSteps`, `neighborsOf`. Production callers (the handlers) pass `c.Graph().PageInputs()`; every other caller, test or production, passes `c.Graph().NoPageInputs()` (or `g.NoPageInputs()`) | One shape for every read, as `InputScope` is passed down the composers; a recording read is chosen at the handler, nowhere else | A second exported function per read that records — two ways to read the same value |
| D-3 | **Record where the read reads.** A handle the read reads by id goes through `in.Node` / `in.Follow` / `in.Cached` (`conclusiondetails.Handle`'s node, `PersonDerivedRows`' owner nodes, `PersonEvents`' follow of `hops.EventsOfParticipant`, its event filter and `canonicalPerson`, `shownKin`'s check of each relative); a batch load goes through `in.Nodes`, which records nothing, so what is recorded is what is read. Evidence graphs are recorded where their records are asked for: `graphfill.RecordsOf(g, ids, in)` calls `in.AddEvidenceGraphs(ids...)`, so both of its readers and S15-28 record by construction. The kinship read records at its loads (D-7). `Add…` is used only for ids taken from rows already in memory that no lookup reads (place entries' keys, place owners' places, the ids `PersonFamily` reads summaries of, Sources looked up in the Source records). Recording reads nothing new: no SQL, no node load, no derivation | One mechanism; a new `Node`, `Follow`, `Cached` or `RecordsOf` call in these reads cannot forget its record (review M-2, M-5); `Cached`, not `Node`, where today's read uses `g.Cached`, so no lookup starts loading (AC-1.11) | Hand-written `Add…` beside each read — a checklist the next read can miss |
| D-4 | **Detail.** `Handle(c, id, in)` reads the node through `in.Node`, so every reader that starts from `Handle` (`ForEntity`, `personNode`) records the handle. `newRecordReader` passes `in` to `graphfill.RecordsOf`, which records the graphs it is asked for; `recordReader.outcome` records the Source of each outcome it composes (`in.AddSources(src.ID)`, at the `recs.Artifact` lookup). Pictures are covered: their lead rows go through the same `newRecordReader`. `PersonDerivedRows` reads each owner node through `in.Node` (every owner the summary row names, before one that is merged, gone or missing its field is dropped) and adds each place owner's `Place.Entity.ID`. `AttachPlaceRelationships` adds the place page's `inputs`, the place's own entry `inputs`, and the id of every place it lists under PartOf, Contains, Predecessors and Successors. `attachSummary`'s summary rows are covered by the handle itself: S14-42 names a row's id in `SummaryDeps` when anything the row read moves | Graphs asked is what S16-30 left for this PR (its Next adds); Sources composed are the Sources whose words the page shows; the summary row is the one stored answer whose dependents the engine already reports | Recording Sources inside `sources.RecordIndex.Artifact` / `Source` — a whole entry read by Promote and the lists too, each of which would then take a recorder for nothing; recording a summary row's own inputs from the input index — a SQL read, and `SummaryDeps` already answers |
| D-5 | **Claims and record links.** `claims` starts from `personNode(c, id, in)` (records the person), passes `in` to `graphfill.RecordsOf` (records every graph asked) and adds the Source of every group at its `recs.Source` lookup. `recordLinks` records through `claims` with the same recorder and adds nothing: its lines are drawn from those graphs' layers, and a line's other entity is not shown (the app draws graphs and arcs only) | The Sources section shows each graph's records and each Source's words; the person's own handle covers a claim gained or lost | Recording each line's entity — up to 75,000 lines name entities the page does not show |
| D-6 | **Timeline.** `PersonEvents` follows `hops.EventsOfParticipant` through `in.Follow` (records the person's participation bridge end and each participation association), loads the events through `in.Nodes`, and reads each linked event's canonical check and each participant's (`canonicalPerson`) through `in.Cached`, so every linked event and every other participant is recorded, canonical or not; the person is recorded by `personNode`. No `Add` | A participant filed at an event touches the event; a provisional event or participant turning canonical touches that id, which the read skipped and must still follow (AC-1.10) | Recording only what the Timeline shows — a provisional participant turning canonical would be missed |
| D-7 | **Family.** `Reader.Relationships(ids, opts, in)` takes the recorder as its last parameter (`Options` is unchanged) and passes it to `deriver.loadSteps(ids, event, in)`; `Reader.For` passes `r.g.NoPageInputs()`; which records at its two neighbour loads: `neighborsOf(nodes, in)` gains the recorder and, in its one walk over `n.Links`, adds each node's id, each `Neighbor` and each `Association` while it lists the neighbours to load. `deps` (the pivot entry's Apply) calls `neighborsOf(nodes, g.NoPageInputs())`. So recorded equals loaded around each stepped node and each step person, by construction. `Families` passes its recorder in both `Relationships` calls, loads `named` through `in.Nodes`, and `shownKin(in, typeID, id, kin)` reads each relative's canonical check through `in.Cached`, in both passes, so every relative `KinOf` names is recorded before `shownKin` filters it. `PersonFamily` adds every id it reads a summary of (`want`) | A pivot answer reads the stepped node's links, the links of every event it stands in (its neighbours) and the step people's links and events; siblings' parents are among the step people. Recording at `loadSteps`' loads keeps one statement of what a family read touches (review M-1). Recording only "the events behind its `atEnd` links" (S16-16's Next adds) misses an event with no implied link yet (AC-1.7); recording only shown relatives misses a provisional one (AC-1.8) | A separate `recordAround` walk after `loadSteps` — a second copy of the walk `loadSteps` owns (review M-1); a recording `nodeSource` — it would record the outermost layer's ids but not the associations of the links the derivation reads; an `Options.Inputs` field — a nil default is a second "records nothing" convention (review M-6); `Add` of `KinOf`'s relatives — a copy of `shownKin`'s walk (review M-5) |
| D-8 | **Wire.** A new message `PageInputs { repeated string handles = 1; repeated string evidence_graphs = 2; repeated string sources = 3; }` (UUID strings, each list distinct and in byte order), as field `inputs` on `ConclusionDetail` (9), `ListPersonClaimsResponse` (2), `GetPersonFamilyResponse` (4), `ListPersonEventsResponse` (4), `GetPersonRecordLinksResponse` (5). One helper `pageInputsProto(in *graphcache.PageInputs) *engine.PageInputs` *(new)* in `api/ffi/handlers/page_inputs.go` maps `Lists()` through `idStrings` | One message, one mapper, five uses; ids match what `WriteEffects` sends (`database.UUIDString`); `evidence_graphs` is `WriteEffects`' own name for the list it meets (review M-4) | Three repeated fields on each response — fifteen fields and five mappers |
| D-9 | **Swift.** `CatalogPageInputs` *(new)* in `GenealogyStore.swift`: `struct CatalogPageInputs: Sendable, Equatable { var handles: Set<String> = []; var evidenceGraphs: Set<String> = []; var sources: Set<String> = [] }`. `var inputs = CatalogPageInputs()` is added to `CatalogConclusionDetail`, `CatalogPersonFamily`, `CatalogPersonTimeline`, `CatalogPersonRecordLinks`. `CatalogPersonClaims` *(new)*: `struct CatalogPersonClaims: Sendable, Equatable { var groups: [CatalogPersonClaimGroup] = []; var inputs = CatalogPageInputs() }`, and `GenealogyStore.listPersonClaims` returns it. `GoStore.mapPageInputs(_:)` *(new)* (static) decodes. FakeStore returns empty inputs | Sets, because S16-25 tests membership; `evidenceGraphs` is `CatalogWriteEffects`' name; defaults keep every memberwise call site and preview compiling; the claims value needs a struct to carry inputs | Keeping claims a bare array and decoding its inputs in S16-25 — the map says `GoStore` decodes all five here, and S16-25 then changes no value type |
| D-10 | The `.personClaims` key's cached value becomes `CatalogPersonClaims`. Its `graphIDs` and `sourceIDs` closures read `.groups`; `PersonSourcesSection`'s host is `ConclusionPageSectionHost<CatalogPersonClaims, …>` with `make` reading `$0.groups` and `isEmpty: \.groups.isEmpty`; the preview's `failAfterFirstAnswer(key, as: CatalogPersonClaims.self, …)`. `FakeStore.seededPersonClaims` stays `[String: [CatalogPersonClaimGroup]]` and `listPersonClaims` wraps it | The smallest change that carries the value; every follow keeps today's behaviour | Changing `PersonSourcesContent` to take `CatalogPersonClaims` — it formats groups and has no use for inputs |
| D-11 | Test layer: one core test per read for what it records (T-2 – T-9), handler tests for what the response carries (T-10), the existing budget and query-count tests switched to pass a real recorder (T-12), one Swift mapping test (T-11). A write-reaches-the-read test with real write effects per relation is S16-25's Check | The map's Check is handler tests; S16-25 is the PR whose behaviour depends on soundness | A Go test that applies FFI writes per relation here — it would test S16-25's follow before it exists |

**Rules this plan bends.** None. D-7 refines S16-16's Next adds note (which named only the pivots' `atEnd` events); that note is not a working rule, and the map's scope entry ("handles, recorded through an InputScope, and the kinship pivots for the family") holds. D-3 follows `.cursor/rules/catalog-queries.mdc`'s read-through recording, and STEP-9 extends that rule to page reads. The rule "The point of this batch is simpler code" was checked: a read changes one call to record (`in.Node`, `in.Follow`, `RecordsOf(…, in)`) and adds ids only from rows it holds; the kinship recording sits in `canonlinks`' one neighbour walk; S16-25 deletes the hand-written Swift selectors this enables.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `graphcache.PageInputs`, `(g *Graph) PageInputs`, `NoPageInputs`, `Node`, `Follow`, `Nodes`, `Cached`, `AddHandles`, `AddKeys`, `AddEvidenceGraphs`, `AddSources`, `Lists` *(new)* | type / func | `graphcache.InputScope`, `Graph.Inputs`, `NoInputs` | Reused inside for handles and for reading; Evidence graphs and Sources are not `InputKey`s and must not become one (K-28); named for page reads so it does not read as a second `Inputs` (review M-4) |
| `core/database/graphcache/pageinputs.go` *(new)* | file | `core/database/graphcache/inputs.go` | `inputs.go` is the summary-row recording the persisted index stores; the page-read recorder sits beside it so `inputs.go` keeps one concern |
| Recorder parameter on `Relationships`, `loadSteps` and `neighborsOf` | param | `canonlinks.neighborsOf`, `deriver.loadSteps` | Extended, not copied: the one neighbour walk records as it lists (review M-1) |
| `engine.PageInputs` *(new)*, `inputs` fields | proto | `engine.WriteEffects` | `WriteEffects` is what a write touched; this is what a read used; separate messages keep each response's meaning plain |
| `pageInputsProto` *(new)*, `api/ffi/handlers/page_inputs.go` *(new)* | func / file | `writeEffectsProto` in `write_effects.go` | Same shape; reuses `idStrings` |
| `CatalogPageInputs`, `CatalogPersonClaims` *(new)* | Swift type | `CatalogWriteEffects` | Different meaning; `CatalogPersonClaims` is the claims value with a place for inputs |
| `GoStore.mapPageInputs` *(new)* | Swift func | `GoStore.mapPersonRecordLinks` | One decoder, called by five reads |
| `TestPageInputs`, `TestForEntityRecordsInputs`, `TestPersonDerivedRowsRecordInputs`, `TestAttachPlaceRelationshipsRecordsInputs`, `TestRecordsOfRecordsGraphs`, `TestClaimsRecordInputs`, `TestRecordLinksRecordInputs`, `TestPersonEventsRecordsInputs`, `TestPersonFamilyRecordsInputs`, `TestRelationshipsRecordInputs`, `wantInputs` *(new, handler test helper)*, `PageInputsMappingTests` *(new)* | tests | `TestListsRecordNoInputs`, `TestPersonEventsReadsParticipantsFromRows` | New behaviour; each sits in the read's existing test file except `PageInputsMappingTests.swift` |

Searched for: "inputs", "Inputs(", "InputScope", "PageInputs", "reports its inputs" across `core`, `api`, `macos/App`; no existing page-read recorder.

**Builds on.** `graphcache.InputScope` and `NodeKey` / `FollowKeys` (S14-40); place entries' and pages' recorded `inputs` (S16-18); `recordReader`'s graph set (S16-30); `canonlinks.loadSteps`' steps (S16-16); `idStrings` (`write_effects.go`); the [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md) wire pattern.
**Deletes.** None — nothing becomes dead here; the Swift selectors these lists replace go in S16-25, which this PR exists to enable.
**Next adds.** S16-25 reads `value.inputs` on the five keys and writes one `.followsInputs` refresh; S15-28's records read passes its recorder to `fieldsOf` and reports what this detail read reports; a new per-entity read adds one `inputs` field and passes `c.Graph().PageInputs()`.

### Reach

None — no new path into existing code and no new state the app can reach: the app decodes the lists and reads nothing from them.

### Scale

At the map's Scale (a person in 50 and 80 Evidence graphs; 200 events with 10 participants each; 20 children in four parent sets; the S11-21 large fixture at 4,000 and 16,000 persons):

- **Detail:** handles hold the person and its derived-row owners (under 10); graphs ≤ 80; Sources ≤ 80. Recording is one map insert per outcome already composed.
- **Claims and record links:** handles 1; graphs ≤ 80; Sources ≤ 80.
- **Timeline:** about 200 events + 200 participation associations + up to 2,000 participant ids (fewer distinct): under 2,500 ids, about 90 KB of UUID strings, beside a payload that already sends each participant's summary.
- **Family:** the person, its neighbours (about 200 events and 200 associations), each step person's neighbours (2 parents and 20 children, each with their events), the relatives named: about 1,000 ids.
- **Crafted (bar 2):** a 20,000-child hub records the hub, 20,000 children and 20,000 associations, about 40,000 ids (1.5 MB on the wire); the read already loads every one of those nodes (`loadSteps` loads all neighbours), so the list never exceeds the read's own loads. `TestCraftedFamily` (4,000 children) holds the read with a recorder under `capBudget` (1 s); the handler's proto encoding is linear in the list.
- **Writes:** none — this PR adds no write and invalidates nothing.

The budgets this PR leans on (`TestDetailBudgets`, `TestClaimsBudgets`, `TestRecordLinksBudgets`, `TestCraftedFamily`, `TestCraftedClaims`, the query-count tests) run with a real recorder after STEP-2 – STEP-6 (T-12), so recording is measured at the sizes those tests already use.

### Edges

- **Assumptions.** A write that moves a value names, in its effects, an id the read recorded: a handle's values move → the handle is in `Handles`; a link is filed, removed or retyped → its association is in `Handles` and its ends in `SummaryDeps` (`effects.Set` doc); a summary row moves → its id is in `SummaryDeps` (S14-42); a graph's rows move → `EvidenceGraphs`; a Source's words move → `SourceScopes`. The reads record ids, so the app's union `touchedHandles` (`Handles` ∪ `SummaryDeps`) meets them. T-7 – T-9 hold the reads' half; S16-25 holds the follow.
- **Neighbors.** Shown versus read-but-not-shown: a shown relative is recorded by its summary (AC-1.6); a relative `KinOf` names but `shownKin` drops (provisional) is recorded too (AC-1.8, T-8); an event with no implied link yet is recorded as the stepped node's neighbour (AC-1.7, T-8); an Event or Place page records only the handle and its records, since its summary row's own dependents come from `SummaryDeps` (T-2, T-4).
- **Removed inputs.** A deleted or merged relative, event or participant: the read recorded its id, so the write that deletes or merges it (which names it) reaches the value; after the write the read no longer records it. A graph the person loses a record on: the person's handle moves (its members), so the handle covers it. A Source deleted: its graphs and the handle move.
- **Real data.** No table, seed or configuration drives a rule here.
- **Untrusted size.** The handles list grows with the links of the nodes the read loads (Family: every neighbour of the person and of each step person; Timeline: every participation and every participant on each event row). Both are already bounded only by what the read loads, and the read loads them before recording; no cap is added (§3 Out). The crafted 20,000-child hub is the largest case (§6 Scale). Place relationship inputs are the place entries' recorded keys, bounded by the entries (S16-18). Summary rows over S14-40's input cap record no inputs (`maxInputKeysPerCall`, crafted only); a page read over such a row still records the row's id, and `SummaryDeps` inherits S14-40's crafted-only miss.

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/graphcache` | `pageinputs.go` *(new)*: `type PageInputs struct { scope *InputScope; graphs, sources map[string][]byte }`; `PageInputs`, `NoPageInputs`, `Node`, `Follow`, `Nodes`, `Cached`, `AddHandles`, `AddKeys`, `AddEvidenceGraphs`, `AddSources`, `Lists` (D-1). `Lists` sorts with `bytes.Compare` |
| `core/database/graphfill` | `RecordsOf(g, graphIDs, in)`: records `graphIDs` with `in.AddEvidenceGraphs` (D-3) |
| `core/database/conclusiondetails` | `Handle(c, entityID, in)`, `ForEntity(c, entityID, in)`, `PersonDerivedRows(c, personID, in)`, `fieldsOf(…, only, in)`, `newRecordReader(…, rows, in)`; `recordReader` gains `in *graphcache.PageInputs`; recording per D-4. `export_test.go` `FieldsOf` passes `c.Graph().NoPageInputs()`. The package comment gains one sentence: "Each read records what it was built from in the caller's `graphcache.PageInputs`." |
| `core/database/conclusionsummaries` | `AttachPlaceRelationships(c, h, in)`: adds `page.inputs`, the own entry's `inputs` and every listed place id (D-4) |
| `core/database/persondetail` | `personNode(c, id, in)`, `shownKin(in, typeID, id, kin)`, `Claims(c, id, in)`, `claims(c, n, in)`, `RecordLinks(c, id, in)`, `recordLinks(c, id, cfg, most, in)` (`RecordLinksWith` follows), `PersonEvents(c, id, in)`, `Families(c, ids, in)`, `PersonFamily(c, id, in)`; recording per D-5 – D-7 |
| `core/database/canonlinks` | `Relationships(ids, opts, in)`; `loadSteps(ids, event, in)`; `neighborsOf(nodes, in)`; `For` and `deps` pass `g.NoPageInputs()`; recording per D-7 |

Errors: none new.

### FFI

`api/proto/engine.proto`: `PageInputs` *(new message)*, comment: "PageInputs is what a page read was built from (S16-24), as UUID strings, each list distinct and in byte order: handles, the canonical handles and associations it read, its own included; evidence_graphs, the Evidence graphs whose records it shows; sources, the Sources whose words it shows." Fields `PageInputs inputs` on the five responses (D-8), each with the comment "inputs is what this value was built from." Regenerate with `./scripts/generate-proto.sh`. Handlers: `GetConclusionDetail` makes `in := c.Graph().PageInputs()`, passes it to `ForEntity` and through `attachSummary(c, d, out, in)` to `PersonDerivedRows` and `AttachPlaceRelationships`, and sets `out.Inputs = pageInputsProto(in)` after `attachSummary` and `attachPictures` (`out` is reassigned by `conclusionDetailProto` before them); `ListPersonClaims`, `GetPersonFamily`, `ListPersonEvents`, `GetPersonRecordLinks` do the same with their read. No new method.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Read inputs value | `CatalogPageInputs` *(new)* | `macos/App/Platform/GenealogyStore.swift` | D-9 |
| Claims value | `CatalogPersonClaims` *(new)* | `macos/App/Platform/GenealogyStore.swift` | D-9, D-10 |
| Decode | `GoStore.mapPageInputs` *(new)* | `macos/App/Platform/GoStore.swift` | Called by the five reads; `mapPersonRecordLinks` sets `inputs` |
| Claims key | `.personClaims` descriptor | `CatalogQueryRegistry.swift` | Closures read `.groups` (D-10) |
| Sources section host | `ConclusionPageSectionHost<CatalogPersonClaims, …>` | `PersonSourcesSection.swift` | `make` reads `$0.groups`; `isEmpty: \.groups.isEmpty` |

No view draws differently. States: unchanged.

### Strings

None — no user-facing copy.

## 7. Steps

**STEP-1 — The recorder**
Files: `core/database/graphcache/pageinputs.go` *(new)*, `core/database/graphcache/inputs_test.go`, `core/database/graphfill/records.go`, `records_test.go`, `records_bench_test.go`, and the `RecordsOf` callers named below. Skill: `add-catalog-query`.
Do: Add `PageInputs` per D-1 and §6 Go core. Then `graphfill.RecordsOf(g, ids, in)` per D-3; its callers (`core/database/conclusiondetails/conclusiondetails.go`, `core/database/persondetail/claims.go`, `core/database/graphfill/records_test.go`, `core/database/graphfill/records_bench_test.go`, `core/database/promotealign/bench_test.go`, `core/database/promotealign/memo_test.go`, `core/database/persondetail/claims_test.go`) pass `g.NoPageInputs()` for now; `records_test.go`'s nil-graph case passes `(*graphcache.Graph)(nil).NoPageInputs()` and still expects `database.ErrClosed`. Write T-1 and T-1b.
Check: `go vet -tags fts5 ./...` compiles every package; `CGO_ENABLED=1 go test -tags fts5 ./core/database/graphcache/... ./core/database/graphfill/...` passes (T-1, T-1b).

**STEP-2 — The detail read records**
Files: `core/database/conclusiondetails/conclusiondetails.go`, `core/database/persondetail/claims.go` (`personNode`'s `Handle` call), `export_test.go`, `conclusiondetails_test.go`, `placerecords_test.go`; `api/ffi/handlers/conclusion_detail.go` (`attachSummary` gains its `in` parameter here; the handler passes `c.Graph().NoPageInputs()` until STEP-7); `core/database/persondetail/detail_budget_test.go`; `core/database/autoreconciler/autoreconciler_test.go`, `core/database/conclusionsummaries/conclusionsummaries_test.go`, `core/database/conclusionsummaries/placechains_test.go` (callers that pass `NoPageInputs()`). Skill: `add-catalog-query`.
Do: Change the signatures per D-2 and record per D-4 (handle, graphs asked, Sources composed, derived-row owners and their places). `Handle`'s caller `personNode` in `core/database/persondetail/claims.go` passes `c.Graph().NoPageInputs()` until STEP-4 gives it the parameter. Existing tests pass `NoPageInputs()`; `TestDetailBudgets` and `TestForEntityQueryCountIsConstant` pass `f.C.Graph().PageInputs()` / `c.Graph().PageInputs()`. Write T-2 and T-3.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/conclusiondetails/... ./core/database/persondetail/... ./api/ffi/handlers/...` passes (T-2, T-3, `TestDetailBudgets`, `TestForEntityQueryCountIsConstant`).

**STEP-3 — Place relationships record**
Files: `core/database/conclusionsummaries/placechains.go`, `placechains_test.go`, `placeentries_test.go`, `display_cache_test.go`; `core/database/promotealign/bench_test.go`; `api/ffi/handlers/conclusion_detail.go`. Skill: `add-catalog-query`.
Do: `AttachPlaceRelationships(c, h, in)` per D-4. Existing callers pass `NoPageInputs()`. T-4 builds its own fixture (Town, County, Village, NewTown) with `graphcachetest.Canon` `PartOf` and a successor link. Write T-4.
Check: `go vet -tags fts5 ./...` compiles every package; `CGO_ENABLED=1 go test -tags fts5 ./core/database/conclusionsummaries/... ./core/database/promotealign/... ./api/ffi/handlers/...` passes (T-4, `TestAttachPlaceRelationships`, `TestListsRecordNoInputs`).

**STEP-4 — Claims and record links record**
Files: `core/database/persondetail/claims.go`, `recordlinks.go`, `timeline.go` and `family.go` (their `personNode` calls pass `c.Graph().NoPageInputs()` until STEP-5 and STEP-6), `export_test.go`, `claims_test.go`, `claims_budget_test.go`, `recordlinks_test.go`, `recordlinks_perf_test.go`, `caps_test.go`; `api/ffi/handlers/person_detail.go`.
Do: Signatures per D-2, recording per D-5. `TestClaimsBudgets`, `TestRecordLinksBudgets`, `TestCraftedClaims`, `TestClaimsWarmReadIssuesNoQuery` pass a real recorder. Write T-5 and T-6.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/persondetail/... ./api/ffi/handlers/...` passes (T-5, T-6, the four named tests).

**STEP-5 — The Timeline records**
Files: `core/database/persondetail/timeline.go`, `timeline_test.go`; `api/ffi/handlers/person_detail.go`.
Do: `PersonEvents(c, id, in)` per D-6. T-7 reuses the Ghost setup of `TestPersonEventsReadsParticipantsFromRows` (`w.k.Provisional`). `TestPersonEventsQueryCount` passes a real recorder; `TestPersonEventsReadsParticipantsFromRows` keeps its assertion (no `ParticipantsOfEvent` key is heard). Write T-7.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/persondetail/... ./api/ffi/handlers/...` passes (T-7, `TestPersonEventsQueryCount`, `TestPersonEventsReadsParticipantsFromRows`).

**STEP-6 — The Family read records**
Files: `core/database/canonlinks/reader.go`, `reader_test.go`, `core/database/promotealign/promotealign_test.go`, `core/database/promotealign/bench_test.go`; `core/database/persondetail/family.go`, `family_test.go`, `family_query_test.go`, `caps_test.go`; `api/ffi/handlers/person_detail.go`.
Do: `Relationships(…, in)`, `loadSteps(…, in)`, `neighborsOf(…, in)` and `shownKin(in, …)` per D-7 (`For` and `deps` pass `g.NoPageInputs()`; test and `promotealign` callers of `Relationships` pass `g.NoPageInputs()`); `Families` and `PersonFamily` per D-2 and D-7. `TestCraftedFamily` and `TestPersonFamilyQueryCount` pass a real recorder. Write T-8 and T-9.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/canonlinks/... ./core/database/persondetail/... ./api/ffi/handlers/...` passes (T-8, T-9, `TestCraftedFamily`, `TestPersonFamilyQueryCount`, `TestRelationshipsQueryCount`).

**STEP-7 — The wire**
Files: `api/proto/engine.proto`, generated Go and Swift (`./scripts/generate-proto.sh`), `api/ffi/handlers/page_inputs.go` *(new)*, `conclusion_detail.go`, `person_detail.go`, `conclusion_detail_test.go`, `person_detail_test.go`. Skill: `add-ffi-handler`.
Do: Add the message and fields per D-8; handlers make one recorder per read and set `inputs` (§6 FFI). Write T-10 with the helper `wantInputs(t, got *engine.PageInputs, handles, evidenceGraphs, sources []string)` *(new)*, which fails naming each id missing from each list. It checks that each list holds the given ids, not that it equals them.
Check: `./scripts/generate-proto.sh` leaves the tree building; `CGO_ENABLED=1 go test -tags fts5 ./api/...` passes (T-10).

**STEP-8 — Swift decodes**
Files: `macos/App/Platform/GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift`, `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift`, `macos/App/Features/Conclusions/PersonSourcesSection.swift`, `PersonSourcesPreviewData.swift`; tests `macos/ProvenenciaTests/CatalogQueryRegistryTests.swift`, `WorkspaceSessionTests.swift`, `OnboardingModelTests.swift`, `PageInputsMappingTests.swift` *(new)*. Skill: `add-swift-test`.
Do: D-9 and D-10. Each `[CatalogPersonClaimGroup]` used as the `.personClaims` value becomes `CatalogPersonClaims` (`groups:` for the old array); `PersonSourcesContent` and `PersonSourcesContentTests` keep taking groups. Write T-11.
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/PageInputsMappingTests -only-testing:ProvenenciaTests/CatalogQueryRegistryTests -only-testing:ProvenenciaTests/WorkspaceSessionTests -only-testing:ProvenenciaTests/PersonSourcesContentTests` passes, one run at a time, with no Swift warning.

**STEP-9 — Docs**
Files: `docs/macos-client-patterns.md` ("Conclusion keys"), `.cursor/rules/catalog-queries.mdc`, `.agents/skills/add-ffi-handler/SKILL.md`, `docs/deployment-plan/spike-16/completed.md`, `docs/deployment-plan/spike-16/deployment-plan.md` (map row), this plan (status).
Do: In "Conclusion keys", after the S16-12 bullet, add: "**Per-entity reads report their inputs** (S16-24): the detail, claims, family, timeline and record links reads return `inputs` (handles, Evidence graphs, Sources the value was built from); `GoStore` decodes them onto each value (`CatalogPageInputs`; the claims value is `CatalogPersonClaims`). S16-25 follows them." In `.cursor/rules/catalog-queries.mdc`, after the summary-composer recording sentence, add: "A per-entity page read takes the caller's `*graphcache.PageInputs`, reads the handles it reads by id through its `Node`, `Follow` and `Cached` (and batch-loads through `Nodes`), passes it to `graphfill.RecordsOf`, and adds only ids taken from rows it holds; a caller that does not report inputs passes `NoPageInputs()`." In `add-ffi-handler`, after the `writeEffectsProto` paragraph, add: "A per-entity read handler makes one `c.Graph().PageInputs()`, passes it to the read, and sets `Inputs: pageInputsProto(in)` on its response (S16-24)." Then per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-24-reads-report-inputs.md` passes; `python3 scripts/check-guidance-names.py` passes.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/graphcache/inputs_test.go` `TestPageInputs` *(new)* | Table: handles added twice and through a bridge key → one id each, byte order; `Node(id)` and `Follow(id, hop)` → the id, and the follow's associations, in `handles`; `Cached(id)` of a node not loaded → false and the id recorded, no load; `Nodes(ids)` → nothing recorded; Evidence graphs and Sources added twice → once each; a 3-byte id → dropped; `NoPageInputs()` → `Node` and `Follow` return what the graph returns, nothing is recorded, `Lists` returns three nil lists | D-1 |
| T-1b | Go | `core/database/graphfill/records_test.go` `TestRecordsOfRecordsGraphs` *(new)* | `RecordsOf(g, [a, b], in)` → `in`'s Evidence graphs are a and b; with `NoPageInputs()` → none | D-3 |
| T-2 | Go | `core/database/conclusiondetails/conclusiondetails_test.go` `TestForEntityRecordsInputs` *(new)* | Table: a Person with records on two graphs of two Sources and a likeness → handles [person], graphs both, Sources both; an Event → handles [event] and its records' graphs and Sources; `NoPageInputs()` → same Detail as with `PageInputs()` | AC-1.1, D-4 |
| T-3 | Go | `conclusiondetails_test.go` `TestPersonDerivedRowsRecordInputs` *(new)* | Pat born at B located at Town through L → handles hold B, L, Town; graphs and Sources hold those of B's and L's records | AC-1.2, D-4 |
| T-4 | Go | `core/database/conclusionsummaries/placechains_test.go` `TestAttachPlaceRelationshipsRecordsInputs` *(new)* | Town `part_of` County (association P), contains Village, successor NewTown → handles hold Town, County, P, Village, NewTown | AC-1.3, D-4 |
| T-5 | Go | `core/database/persondetail/claims_test.go` `TestClaimsRecordInputs` *(new)* | Ada on two graphs of two Sources → handles exactly [Ada], graphs both, Sources both | AC-1.4, D-5 |
| T-6 | Go | `core/database/persondetail/recordlinks_test.go` `TestRecordLinksRecordInputs` *(new)* | The four-register fixture of `TestRecordLinks` → graphs equal the result's graphs, Sources equal their Sources, handles [son] | AC-1.5, D-5 |
| T-7 | Go | `core/database/persondetail/timeline_test.go` `TestPersonEventsRecordsInputs` *(new)* | Pat at CS with Kid and at U with Ned and provisional Ghost → handles hold Pat, CS, U, Kid, Ned, Ghost and each of Pat's participation associations | AC-1.9, AC-1.10, D-6 |
| T-8 | Go | `core/database/persondetail/family_test.go` `TestPersonFamilyRecordsInputs` *(new)* | Table: shown spouses, children and co-parent with the marriage pivot and the parent link → all recorded; Pat alone in marriage M2 → M2 recorded; provisional child Vic → Vic recorded; Pat's parent Quinn married to Rhea at M3 (Rhea not Pat's parent) → M3 recorded (Quinn is a step person, so `loadSteps`' second neighbour load records M3) | AC-1.6, AC-1.7, AC-1.8, D-7 |
| T-9 | Go | `core/database/canonlinks/reader_test.go` `TestRelationshipsRecordInputs` *(new)* | `Relationships(ids, opts, g.NoPageInputs())` → the links equal today's and nothing is recorded; `Relationships(ids, opts, in)` over a person with a parent and a marriage → in holds the person, the parent, both associations, the marriage event and the parent's neighbours; links equal the unrecorded call's | D-7 |
| T-10 | Go | `api/ffi/handlers/conclusion_detail_test.go` `TestGetConclusionDetail`, `TestGetConclusionDetailCarriesDerivedRows`, `TestGetConclusionDetailCarriesItsSummary` (Place case); `api/ffi/handlers/person_detail_test.go` `TestListPersonClaims`, `TestGetPersonFamily`, `TestListPersonEvents`, `TestGetPersonRecordLinks` — each extended with `wantInputs` | Each response's `inputs` holds every entity id, relative, co-participant, event, graph id and Source id the response shows; `TestGetPersonFamily`: Pat, Sam, Tess, Uma, Wren, Xan, M1, `patUma`; `TestListPersonEvents`: Pat, CS, U, Kid, Ned, Sam, B1, Mar | AC-1.1 – AC-1.6, AC-1.9 |
| T-11 | Swift | `macos/ProvenenciaTests/PageInputsMappingTests.swift` *(new)* | `GoStore.mapPageInputs` of a proto with two handles (one repeated), one graph, one Source → sets of those; an empty proto → `CatalogPageInputs()`; `GoStore.mapPersonRecordLinks` of a response with inputs → `.inputs` equal | AC-1.12, D-9 |
| T-12 | Go | `TestDetailBudgets`, `TestClaimsBudgets`, `TestRecordLinksBudgets`, `TestCraftedFamily`, `TestCraftedClaims`, `TestPersonFamilyQueryCount`, `TestPersonEventsQueryCount`, `TestClaimsWarmReadIssuesNoQuery`, `TestForEntityQueryCountIsConstant` — switched to a real recorder | Same budgets and query counts as today; `TestPersonFamilyQueryCount` also checks the two warm reads' `Lists()` are equal | AC-1.11, D-3 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `core/database/persondetail` (every read's signature changes), `TestListsRecordNoInputs` (counts recording scopes on the summary reads; a page read must not create one inside `ByIDs`), `TestPersonEventsReadsParticipantsFromRows` (hears every key added), the Swift registry and session tests that seed `.personClaims`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none expected)
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none)
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New (no UI change)
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — none
- [ ] `rg -n "\.PageInputs\(\)" api/ffi/handlers` shows one recorder per read in each of the five handlers
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (not gated: no brief)
- [ ] Domain doc and guides updated: docs/macos-client-patterns.md "Conclusion keys", .cursor/rules/catalog-queries.mdc, .agents/skills/add-ffi-handler/SKILL.md (STEP-9)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Open a project with a Person who has a family, a timeline and records in two Sources. Open the Person page and switch through Vitals, Family, Timeline, Gallery and Sources: every section draws as it did before the PR.
2. Rename one of the person's Sources from the Sources list, return to the Person page: Vitals and Sources show the new title, as before the PR (the follow is unchanged).
3. Open an Event page and a Place page with relationships: both draw as before.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| Recording grows a warm read's time | D-3; T-12 runs the existing budgets with a real recorder |
| A read records too little, so S16-25 misses a write | D-6, D-7 record read-but-not-shown ids; T-7, T-8 pin the cases found; S16-25's session tests per relation |
| The claims value type change breaks a Swift call site the plan did not list | STEP-8 lists every file `rg "CatalogPersonClaimGroup\]\|listPersonClaims"` finds at the planning base |
| A recorder shared by `Families` over several ids mixes people's inputs | Only `PersonFamily` (one id) reaches the wire; `Families` documents that its recorder holds the union |

**Stop and report if:**

- A warm read named in T-12 issues more SQL, or misses its budget, with a recording `PageInputs()` than with `NoPageInputs()`.
- Recording a case of T-7 or T-8 needs a node or link the read does not already load (D-3 would not hold).
- `TestListsRecordNoInputs` fails: a page read made `ByIDs` create a recording scope.
- `generate-proto.sh` changes any message other than the six this plan names.
- `protoc`, its Go and Swift plugins, or `xcodebuild` are missing: STEP-7 and STEP-8 run on the researcher's Mac (the only machine with Xcode). Stop after STEP-6, push, and report; never hand-edit `engine.pb.go` or `engine.pb.swift`.
- A Swift file outside STEP-8's list needs a change for `CatalogPersonClaims`.
- Any value returned by a read differs from today's (an existing value test fails).

## 12. Open questions

None.

## 13. PR

**Title:** S16-24 — Person, Event and Place reads report their inputs
**Body:** objective in one sentence; what shipped against US-1; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-24-reads-report-inputs.md`.
