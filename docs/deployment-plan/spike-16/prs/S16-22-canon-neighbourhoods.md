# S16-22 — Promote reads each handle's neighbourhood instead of walking the catalog

**Status:** Landed in [#844](https://github.com/Jake-Robins-Studios/provenencia/pull/844) (2026-11-14)
**Spike / slice:** Spike 16 · Slice 2d — Promote
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: an engine change; Promote's suggestions read the same as today)
**Board:** —
**Depends on:** S16-16 (landed [#814](https://github.com/Jake-Robins-Studios/provenencia/pull/814)), S16-20 (landed [#827](https://github.com/Jake-Robins-Studios/provenencia/pull/827)), S16-21 (landed [#836](https://github.com/Jake-Robins-Studios/provenencia/pull/836)), S16-36 (landed [#841](https://github.com/Jake-Robins-Studios/provenencia/pull/841))
**Blocks:** —
**Branch:** `s16-22-canon-neighbourhoods`
**Version bump:** none — no change a researcher can see but speed, and no wire or catalog change ([`docs/versioning.md`](../../../versioning.md); S16-32 precedent)
**Skills to load:** [`use-catalog-session`](../../../../.agents/skills/use-catalog-session/SKILL.md) (the graph cache, its registry and Verify), [`add-match-rule`](../../../../.agents/skills/add-match-rule/SKILL.md) (the layer packages `core/kinship` and `core/graphalign`; its line 33 changes)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table-driven tests), `.cursor/rules/match-rules.mdc` (`core/graphalign` and `core/kinship` stay pure; no numbers outside `core/matchregistry`), `.cursor/rules/catalog-queries.mdc` (a derived cache is read only through its registry handle: the view reads the pivots only through `canonlinks.Reader`)
**Context:** [design § Promote](../cache-architecture.md#promote) ("Neighbourhoods instead of the whole canon"), [`docs/catalog-caches.md`](../../../catalog-caches.md), [`promote-graph-alignment.md`](../../../promote-graph-alignment.md) §4 (the `canon` input), §7 and §12, [`matching-model.md`](../../../matching-model.md) line 31, [`promote-ranking.md`](../../../ideas/promote-ranking.md) ("Memoise a person's composed kinship"), [S16-21 plan](S16-21-canon-view-place-links.md) (D-1 `CanonView`, its Out row on the event-type lookup), [S16-36 plan](S16-36-refuse-self-loops.md) (D-5 `CanonView.Links` contract), [S16-16 plan](S16-16-composed-kinship.md) (D-8 `BenchmarkLargeSourcePropose`, **Next adds**), [S16-20 plan](S16-20-match-index-apply.md) (**Next adds**), working rules: "The point of this batch is simpler code", "Cache entities and results per key; compose answers", "Every cache names the signal that updates it, and updates exactly", "Warm only what every proposal needs; no background re-warm", "Orders are defined and results do not move", "Memory is budgeted", "No new persisted projections, and no stored answer without a measurement", "A link with one record at both ends is crafted data, refused where links are read", "Measure growth"
**Planned:** 2026-11-15 against `main` @ `292b421`
**Review:** [`S16-22-canon-neighbourhoods.review.md`](S16-22-canon-neighbourhoods.review.md) — Fits with changes / Ready with changes after two rounds; no open blocker

**Landed.** Differences from the plan: STEP-1's base figures were taken on the branch's base checkout before the first change, not in a second worktree, and on an Apple M1, so the figures in the PR and `completed.md` are M1 figures (`budgetWarm`'s comment keeps the plan's Xeon text). `rg -n "Canon\{" core --glob '!*_test.go'` also matches `graphcachetest.Canon`, an unrelated test-kit type.

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

Every Promote proposal walks the whole connected canon from its seed handles before `Align` reads a single handle (`loadCanon`). On the large fixture that is 18,233 handles and 30,347 links at 4,000 persons, and 21,566 handles at 16,000, of which `Align` reads the links of about 550. This PR replaces the walk with a view that serves one handle's profile and links when `Align` asks for them, read from the match index (S16-20), the handle's node and the kinship pivots (S16-16). The proposal's cost then follows the Source, not the catalog (bar 10), and Promote's suggestions stay what they are. It is "Narrower canon walk" from [`promote-ranking.md`](../../../ideas/promote-ranking.md).

**Why now.** Bar 10 ("Promote's cost follows the Source, not the catalog") is the last Promote outcome of Batch 2. S16-21 put `Align` behind `CanonView`, S16-36 removed the self-loop case that view would otherwise inherit, S16-20 holds every handle's profile, and S16-16 composes a person's implied links from the pivots without a catalog-wide drop: every input the view reads already exists.

**What stays.** Every row, score, band, alternative, move and connection of every proposal (the goldens in `core/graphalign/align_test.go`, `TestAlignInvariants`, the `promotealign` suite, and STEP-3's equivalence run on the large fixture). `Align` and `CanonView` as they are. The candidates entry (`promotealign.candidates`) and the match index, unchanged. `Connections` and its place links (S16-21). The warm proposal's single `SELECT` (`TestLargeSourceBudgets` "warm queries", `TestProposeWarmIssuesNoQuery`).

**Measured at planning** (a scratch prototype of D-3 to D-6, removed; Xeon 2.1 GHz, 4 cores, 2026-11-15, `main` @ `292b421`): warm proposal of Source A 170 → 25 ms at 4,000 persons and 207 → 27 ms at 16,000; after a handle commit 180 → 25 ms and 207 → 27 ms; one warm proposal allocates 169 → 18 MB at 4,000 and 173 → 20 MB at 16,000. Every row of Source A (100 rows) and the one-place Source (61 rows) was equal at both sizes, and the whole `promotealign` suite passed with the view.

## 2. User stories

**US-1.** As a researcher promoting a Source on a large project, I get suggestions as quickly at 16,000 persons as at 4,000, and they are the same suggestions as before, so a bigger tree does not slow my work.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Large fixture at 16,000 persons, warm proposal of Source A, `BenchmarkLargeSourcePropose` on the base and on the branch, same machine | `warm-ms` on the branch is at most a third of the base's (planning: 207 → 27 ms) |
| AC-1.2 | Large fixture at 4,000 and 16,000 persons, warm proposal of Source A | The 16,000 figure is within `budgetWarm` (150 ms) and at most twice the 4,000 figure |
| AC-1.3 | Large fixture at 16,000 persons, a Person promoted on the other Source, then a proposal of Source A | It takes at most 1.5 times a warm proposal |
| AC-1.4 | Large fixture at 4,000 and 16,000 persons; Source A and the one-place Source proposed through the view and through today's walk | `Proposal.Rows` are equal (`reflect.DeepEqual`): 100 rows and 61 rows |
| AC-1.5 | The `graphalign` goldens, `TestAlignInvariants` and every `promotealign` test | Pass unchanged |

**US-2.** As the engine, a Promote proposal reads only the handles `Align` asks for, so its work does not grow with the catalog.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Large fixture at 4,000 persons (18,233 handles), one proposal of Source A | The view reads the links of fewer than 1,500 handles (planning: 543) |
| AC-2.2 | The same proposal | Every link the view serves has a match-index handle at its far end, and a link served at both of its ends is the same link at each (`A`, `B`, `KeyA`, `KeyB`, `Recording`) |
| AC-2.3 | A warm proposal on the large fixture | 0 graph queries and 1 `SELECT` (`MAX(revision)`), as today |
| AC-2.4 | `canonlinks.Reader.Links(ann)`, Ann the subject of birth B1 with Bob as father | The filed link Ann–B1 first, then the implied parent link Bob–Ann; `Links(b1)` is the event's two filed links and derives no pivot; an id that is no node has no links |
| AC-2.5 | `rg -n "loadCanon\|PlaceImplied\|EdgeOf\|walkedPeople" core .agents docs/*.md` | Prints nothing |

## 3. Scope

| In | Covered by |
| --- | --- |
| `canonlinks.Reader.Links` *(new)*: one node's filed links as edges, then a person's `For` links, merged through `kinship.LinkSet` (D-1, D-2) | STEP-2, AC-2.4 |
| `promotealign.canonView` *(new)* serves `Align`: profiles from the match index, links from `Reader.Links` kept when the far end is a handle, candidates from the candidates entry (D-3 – D-7) | STEP-3, AC-1.4, AC-2.1, AC-2.2, AC-2.3 |
| Equivalence run of the view against today's walk on the large fixture at 4,000 and 16,000 persons, before the walk goes (D-8) | STEP-3, AC-1.4 |
| `loadCanon`'s walk, its `LinkSet` merge and `PlaceImplied` loop go; `kinship.LinkSet.PlaceImplied`, `canonlinks.EdgeOf`'s export, `inputs.terms` go; `graphalign.Canon` moves to the tests (D-9 – D-12) | STEP-4, AC-2.5 |
| Bar 10's budget: `budgetWarm` 950 → 150 ms and a 16,000-person subtest (D-13) | STEP-5, AC-1.1 – AC-1.3 |
| Docs: `promote-graph-alignment.md` §4, §7, §12; `matching-model.md` line 31; `add-match-rule` line 33; `catalog-caches.md`; `promote-ranking.md`; the map's scope entry (D-15) | STEP-6 |

| Out | Home |
| --- | --- |
| Ranking on Evidence graph scoring | [`promote-ranking.md`](../../../ideas/promote-ranking.md) ("The direction") |
| Memoising a person's composed kinship across proposals | [`promote-ranking.md`](../../../ideas/promote-ranking.md#memoise-a-persons-composed-kinship); STEP-6 records this PR's figures there |
| Per-graph compare and alike-pair memos (audit 2 B-11) | [`promote-ranking.md`](../../../ideas/promote-ranking.md) (Inventory) |
| A batched `Reader.Links` over many ids for a cold proposal | not planned: `promotealign.Warm` loads every person, event and place node at open, so the view reads cached nodes (D-6) |
| Tightening `budgetAfterCommit` (2.5 s) | not planned: AC-1.3's 1.5-times-warm ratio already gates it |
| The bridge filer's `filedLinks` (`core/database/identityclaims/bridgefile.go`) | not planned: it reads its own transaction (S16-21 Out) |

## 4. Current state

Verified at `292b421`.

| Area | Where | Today |
| --- | --- | --- |
| Promote's entry | `core/database/promotealign/promotealign.go` `Propose` | Loads inputs, `mergeFixed`, `matchIndexOf`, then `loadCanon(c.Graph(), in.graphID, m, layer, anchors, cfg, terms)` and `graphalign.Align(layer, canon.View(), anchors, cfg)`; then `Connections` |
| Inputs | `promotealign.go` `inputs`, `loadInputs` | `inputs.terms` comes from `canonlinks.LoadTerms`; its only reader is `loadCanon` |
| The walk | `core/database/promotealign/canon.go` `loadCanon` | Seeds: fixed handles, then each unfixed weighted Subject's ranked candidates (`loadCandidatesMemo`), `add`ed when the node is unmerged and in `m.handles`; seeds sorted by ref. Breadth-first over `n.Links` of every reached handle with `g.Nodes(prefetch)` per wave; each link whose neighbor is an unmerged match-index handle goes through `canonlinks.EdgeOf` (with its own `eventTypeProp` lookup) into one global `kinship.LinkSet`. Then `reader.For` for every walked person, each implied link kept at its `A` end when both ends were walked, placed with `set.PlaceImplied`. Returns `graphalign.Canon{Handles, Edges, Candidates}` over the whole component |
| Candidates | `canon.go` `loadCandidatesMemo`, `rankCandidates`, `forgetCandidates`, `checkCandidates`, var `candidates` | The candidates entry; unchanged by this PR |
| Match index | `core/database/promotealign/index.go` `matchIndex.handles` (`map[string]subjectcompare.Subject`), `matchIndexOf`, `Warm` | Every unmerged person, event and place profile (`profiler.holds`: non-nil, not merged, primary kind); `Warm` loads every such node through `g.Kind` at open |
| The view interface | `core/graphalign/types.go` `CanonView` | `Handle(id) *Handle` (nil when not held), `Links(id) []kinship.Link` (every link with id at an end, as stored, in the view's order; read through `kinship.Edge.From`), `Candidates(subjectID) [][]byte` |
| Today's view | `types.go` `Canon`, `Canon.View`, `canonIndex` | An index built once over `Canon.Edges`; its last production caller is `Propose`. Tests: 55 `graphalign.Canon{…}` literals in `core/graphalign/align_test.go`, one in `invariants_test.go` |
| `Align`'s reads | `core/graphalign/align.go` `newState`, `anchor`, `seed`, `corresponding`, `place`, `segments` | `Handle` for fixed handles, candidates and far ends; `Links(hid)` (in `corresponding`) for every handle it scores; `Candidates` in `seed`. `newState` builds only the layer's adjacency (`layerAdj`) since S16-21 |
| Link reader | `core/database/canonlinks/reader.go` `Reader`, `deriver`, `newDeriver`, `deriver.edge` | `edge(n, l)` calls `EdgeOf(n.ID, n, l, nil, …)`: correct only where `n` is the event end or the link has no event end (its callers `relationshipEdges` and `eventLinks`). `For(id)` composes a person's implied links from the pivots. `Relationships(ids, opts, in)` returns relationship-bridge links and `For`'s, batched, recording page inputs |
| Edge reader | `core/database/canonlinks/canonlinks.go` `EdgeOf` | Exported; callers: `deriver.edge`, `loadCanon`, and the internal test helper `world.edgesOf` (`reader_test.go`) |
| Merge | `core/kinship/links.go` `LinkSet.PlaceImplied` | Only caller `loadCanon`; tested by `TestLinkSet` "PlaceImplied places without growing the set" (`core/kinship/links_test.go`) |
| Node links | `core/database/graphcache/load.go` `finishLinks` | A node's `Links` are sorted by association ref, then neighbor ref; a link from a record to itself is dropped (S16-36) |
| Budgets | `core/database/promotealign/perf_test.go` `budgetWarm` (950 ms), `TestLargeSourceBudgets` "warm", "after a handle commit", "warm queries"; `largeFixture.warmProposal`, `proposalAfterCommit` | Gated at 4,000 persons only. The "warm" subtest's comment says the cost is S16-22's to narrow |
| Benchmark | `core/database/promotealign/bench_test.go` `BenchmarkLargeSourcePropose` | Reports `warm-ms`, `after-commit-ms` at 4,000 and 16,000; not gated |
| Tests | `promotealign_test.go`, `memo_test.go` (`TestProposeWarmIssuesNoQuery`, `TestMemoIsNotMutated`), `core/graphalign/align_test.go`, `invariants_test.go`, `core/database/canonlinks/reader_test.go` | Cover today's behavior; all must pass unchanged except where §8 names a change |

**Precedent.** S16-21 ([#836](https://github.com/Jake-Robins-Studios/provenencia/pull/836)) moved `Align` onto `CanonView` while the walk still ran, so the goldens proved the move changed no answer: copy that order (the view and its equivalence run first, the deletions after). S16-16 D-8 (`BenchmarkLargeSourcePropose`, `warmProposal`, `proposalAfterCommit`) and S16-32 (figures before and after at 4,000 and 16,000, with `hostname`, in the PR description): copy how figures are recorded. Do not copy `Relationships`' batching or page inputs: the view reads one handle at a time from cached nodes.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `core/database/canonlinks/reader.go` gains `func (r *Reader) Links(id []byte) ([]kinship.Link, error)` *(new)*. Doc: "Links returns every link at id the canon reads: each link filed on id as an edge between its two ends with the key it has from each, then, when id is a person, For's links, merged through one kinship.LinkSet, in that order. An id that is no node has no links. Nothing is filtered: a link to a merged node is returned. The caller owns the slice." Body: `n, err := r.d.src.node(id)`; nil node → `nil, nil`. When `n.Is(r.d.personType)` (`graphcache.Node.Is`; a vocabulary with no person type has a nil id, which no node has): `implied, err := r.For(id)`. Then `filed, err := r.d.filedEdges(n)` *(new)*: `d.edge` of every link in `n.Links` order. Return `composeLinks(filed, implied)`. A filed link carries its association in `Associations`, as `Relationships`' do; the walk set none. `Align` and `Connections` never read a canon link's `Associations`, so they stay. `composeLinks(filed []kinship.Edge, implied ...[]kinship.Implied) []kinship.Link` *(new, unexported)* is the one "filed first, then implied, merged through one `kinship.LinkSet`" rule: `Add(kinship.Link{Edge: e})` for each filed edge, then `AddImplied` for each list in order, returning `set.Links()`. `Relationships` reads `edges, err := r.d.relationshipEdges(s.node)` per step, then `composeLinks(edges, implied, siblings[string(s.node.ID)])` (review M-1) | `canonlinks` already owns `EdgeOf`, the event-type lookup and `For`; the S16-21 Out row puts the lookup in one place. A person's implied links are the pivots S16-16 composes, read by calling `For`, so a later memo of `For` reaches Promote with no change here (review M-9); places and events imply nothing, and `For` on a city would read the pivots of its 6,000 events for nothing, so it runs only for a person | Extending `Relationships` with an every-bridge option — it is relationship bridges by name and contract, batched and recording page inputs for the Family read, and S16-16's "no new API" note assumed relationship links were all the canon needs (participation, location and place links are not); a second `LinkSet` loop in `Links` beside `Relationships`' (review M-1); the view calling `EdgeOf` itself — a second event-type lookup beside the deriver's |
| D-2 | `deriver.edge` becomes `edge(n *graphcache.Node, l graphcache.Link) (kinship.Edge, bool, error)`: when `l.NeighborTypeKey == vocabkey.Event` it reads `nb, err := d.src.node(l.Neighbor)` (a nil `nb` returns `ok == false`) and passes it to `EdgeOf(n.ID, n, l, nb, …)`; otherwise it passes nil. `EdgeOf` keeps its exported six-argument signature through STEP-3, because `loadCanon` still calls it; STEP-4 makes it `edgeOf` without `self` (D-10). `relationshipEdges` becomes `([]kinship.Edge, error)` and `eventLinks` returns `edge`'s error; `kinEdges` becomes `([]kinship.Edge, error)` and `parentEdges` returns its error (their neighbors are people and places, so they never read; their output is unchanged, and under Check's `cachedNodes` nothing loads). `filedEdges(n *graphcache.Node) ([]kinship.Edge, error)` *(new)* is `edge` over every `n.Links`.  `deriver` gains `personType []byte` *(new field)*, set in `newDeriver` from `v.TypeIDsByKey()[string(vocabkey.Person)]`. `world.edgesOf` in `reader_test.go` becomes `w.r.d.filedEdges(n)` per node, keeping its one-per-association dedupe | One edge reader for every caller, with no precondition on what the caller passes; the neighbor read follows the deriver's one load policy (review M-2) | A caller-supplied neighbor — correct only for some callers, and repeated in `Links` and `world.edgesOf` (review M-2) |
| D-3 | `core/database/promotealign/canon.go`: `loadCanon` is replaced by `type canonView struct { m *matchIndex; reader *canonlinks.Reader; ranked map[string][][]byte; handles map[string]*graphalign.Handle; links map[string][]kinship.Link; err error }` *(new)* and `func newCanonView(g *graphcache.Graph, graphID []byte, m *matchIndex, layer graphalign.Layer, fixed []graphalign.Fixed, cfg graphalign.Config) (*canonView, error)` *(new)*. `newCanonView` builds `todo` from the layer's Subjects not in `fixed` (no weights check: `evidencelayer.Load` keeps only Subjects of a kind in `rules.Subject.Weights`, the same registry `cfg` comes from, and `Align`'s `seed` checks again; review M-7), calls `loadCandidatesMemo` when `todo` is not empty, sets `ranked[string(s.ID)] = known[string(s.ID)].ids` for each `s` in `todo` with ids (unfiltered, as today), and builds the reader with `canonlinks.NewReader(g)`. `Candidates(subjectID)` returns `v.ranked[string(subjectID)]` (the field is not `candidates`, the package's registry entry) | The three reads `Align` makes, each served from what already holds it; a fixed pair's handle needs no seeding (`newState` reads it through `Handle`) | A registry entry for the view or its links — no reader outside one proposal reads them, and rule "No stored answer without a measurement" |
| D-4 | `Handle(id)`: the memo `v.handles[string(id)]` when set; else when `m.handles` holds `id`, a copy `h := s` stored as `&h` and returned; else nil | `Align` reads a handle by pointer many times per run; the match index's map values are not addressable, and `Align` never writes a handle. The match index holds only unmerged primary handles, so a merged or unknown fixed handle reads nil as today | `matchIndex.handles` as pointers — changes Apply, Check and the profiler for one reader |
| D-5 | `Links(id)`: nil once `v.err` is set; the memo `v.links[string(id)]` when present; nil, not memoised, when `m.handles` does not hold `id` (the memo holds handles only); else `ls, err := v.reader.Links(id)` and keep each `l` whose `other, _, ok := l.From(id)` is `ok` and `m.handles` holds `other`, in `Reader.Links` order, memoised. The order is the handle's own: its filed links in node order (association ref, then neighbor ref), merged by ends and keys, then `For`'s links | Seed-independent and defined (rule "Orders are defined and results do not move"); a link's far end must be a handle exactly as the walk required (unmerged, primary). Measured: the link set of every handle read equals today's; the order differs for 17 of 313 and 22 of 543 handles at 4,000 persons (11 of 466 and 6 of 579 at 16,000), and no row moved (AC-1.4) | Reproducing the walk's order — it depends on which seeds the proposal had and needs the walk |
| D-6 | `CanonView`'s doc gains: "A view that reads lazily and can fail holds its first error for its caller and serves nothing after it; Align does not see errors." (review M-8). A read error in `Links` is held: the first one sets `v.err`, and every later `Links` returns nil. `Propose` checks `view.err` right after `Align` and returns `graphalign.Proposal{}, 0, view.err`. The view reads nodes through `g.Node` (via the reader), so a node not cached loads; warm, every handle's node is cached since `Warm` and Apply keep the match index's nodes loaded | `CanonView` has no error return and `Align` is pure; the `bufio.Scanner` / `sql.Rows.Err` shape. Loading on a miss keeps a cold catalog correct | An `error` on `CanonView.Links` — threads errors through `Align`; reading with `g.Cached` only — a node missing from the cache would silently drop links |
| D-7 | The view lives for one proposal: `Propose` builds it, `Align` reads it, nothing keeps it. No registry entry, no Apply, no `docs/catalog-caches.md` row | It holds no answer past the call, as `Align`'s own `pairs` memo; every input it reads is a registry entry that already updates exactly | — |
| D-8 | STEP-3 adds `WalkRowsForTest(c *database.Catalog, graphID []byte) ([]graphalign.Row, error)` *(new, temporary)* in `core/database/promotealign/export_test.go`: `loadInputs`, `mergeFixed(…, nil)`, `matchIndexOf`, `loadCanon`, `graphalign.Align(layer, canon.View(), anchors, cfg).Rows`, or nil rows for an empty layer: the walk branch only, beside `alignRows` (D-16). `TestViewProposesAsTheWalk` *(new, temporary)* in `perf_test.go` builds the large fixture at 4,000 and then 16,000 persons and requires `reflect.DeepEqual(lf.propose(g, nil).Rows, walk)` for Source A and the one-place Source. Its output goes in the PR description; STEP-4 deletes both with the walk | The map's Check: an equivalence test that runs today's walk and the view. The walk cannot stay beside its replacement (rule "The point of this batch is simpler code"), so the run happens while both exist, as S16-21's goldens did | Keeping `loadCanon` in a test file as a reference — an old path alive beside the new one, and it keeps `PlaceImplied` alive; a stored golden of the large fixture's rows — Subject ids are minted per run |
| D-9 | `Canon`, `Canon.View` and `canonIndex` move unchanged from `core/graphalign/types.go` to `core/graphalign/export_test.go` (package `graphalign`), so the goldens keep writing `graphalign.Canon{Handles, Edges, Candidates}`. The package doc's "S9-42 loads Layer / Canon and calls Align" becomes "Promote loads a Layer and serves a CanonView, then calls Align" | After STEP-4 no production code builds a `Canon`; tests still need a fixed canon | Rewriting 56 test literals onto another adapter — churn with no reader gained |
| D-10 | In STEP-4, `canonlinks.EdgeOf` becomes unexported `edgeOf` and drops its `self` parameter (always `n.ID` once `loadCanon` is gone; `deriver.edge` calls `edgeOf(n, l, nb, …)`). `Reader.For` stays exported though `loadCanon` was its last caller outside the package | `EdgeOf`'s last caller outside the package was `loadCanon`, and no doc names it as an entry point. `For` is the documented name of a person's composed implied links in `matching-model.md`, `add-match-rule`, `catalog-caches.md` and the memo idea; unexporting it is a five-file sweep for no reader gained (review M-5) | Keeping the export with no outside caller |
| D-11 | `inputs.terms` and `loadInputs`' `canonlinks.LoadTerms` call go; `Propose` reads `cfg, layer := in.cfg, in.layer` | The terms' only reader was `loadCanon`; the reader loads its own | — |
| D-12 | `kinship.LinkSet.PlaceImplied` and its `TestLinkSet` subtest go | Its only caller was `loadCanon` | — |
| D-13 | `budgetWarm` drops from 950 ms to 150 ms; in its comment, the last two sentences (from "Warm history: 250, 350, 375, 500, 950 ms." to the end) are replaced by "Lowered to 150 ms by S16-22 (2026-11-15), when Promote stopped walking the component: 25 ms measured at 4,000 persons on a 4-core Xeon; 150 ms keeps six times headroom and fails the walk (170 ms on the same machine). Warm history: 250, 350, 375, 500, 950, 150 ms. A proposal that creeps toward 150 ms is a real slowdown to investigate, not a reason to raise it." `TestLargeSourceBudgets` gains a subtest "at 16,000 persons", run after "after a handle commit": `warm4 := lf.warmProposal()`; `big := newLargeFixture(t, 16000)`; `warm := big.warmProposal()`; `n := 0`; `after := big.proposalAfterCommit(&n)`; `WithinBudget` of `warm` against `budgetWarm`, of `warm` against `2*warm4` ("warm proposal at 16,000 persons, against twice the one at 4,000"), and of `after` against `warm*3/2`. The "warm" subtest's comment becomes: "A warm proposal reads the links of the handles Align asks for (S16-22), about 18 MB of short-lived allocations." | Rule "Measure growth" and S16-16 D-8 ("bar 10's budget is S16-22's to set"); one 16,000 fixture inside the test that already holds the 4,000 one | A separate test with its own 4,000 fixture — builds it twice; gating only through the benchmark — the rule asks for a budget |
| D-14 | No `docs/catalog-caches.md` row is added or removed; after STEP-5, `BenchmarkCacheSizes` is run and the figures in the `canonlinks.kinship` row (keys, `evidence-B`) and in the `evidencelayer.layers` row are replaced by the new ones, and the `canonlinks.kinship` row's reader list reads "`Reader.pivot`, read by `For`, `Links` and `Relationships`, which compose their answers from it" | A proposal now fills only the pivots of the people it reads (rule "Memory is budgeted": figures before and after) | — |
| D-15 | Docs (STEP-6): `promote-graph-alignment.md` §4 `canon` row ("Promote's `canonView` serves it one handle at a time: the profile from the match index, the handle's filed links and, for a person, the links the kinship pivots imply, kept when the far end is a handle"); §4.1's "The catalog adapter (`core/database/promotealign`) builds `Layer` and `Canon` and calls `Align`" becomes "builds the `Layer` and a `CanonView` and calls `Align`"; §7 step 3 and the line after it ("`Align` asks the view for a handle's links when it scores the handle; the view reads the handle's cached node and the kinship pivots, so a proposal reads the Source's neighbourhood, not the component"; title "Loading: prefetch, then read in memory"); §12 the "Query count" item's last sentence ("Cold, `Warm` has loaded every person, event and place node at open, so the view reads cached nodes") and the "Kinship shapes" item (`AddImplied` only; "the canon view reads them through `canonlinks.Reader.Links`"); `matching-model.md` line 31 (drop "or `PlaceImplied` in `loadCanon`"; "the canon side is read through `canonlinks.Reader.Links`"); `add-match-rule` line 33 (the reader list becomes `LoadTerms`, `Reader.Links`, `Reader.For`, `Reader.Relationships`; drop "or `PlaceImplied` in `loadCanon`"); `canonlinks.go` package doc names `Links` instead of `EdgeOf`; `Propose`'s doc comment "walks the catalog's canonical graph from the fixed anchors and each unfixed kind's top property matches, and runs graphalign.Align" becomes "runs graphalign.Align over a canon view that reads each handle's links when Align asks for them"; `promote-ranking.md` "Memoise a person's composed kinship": its "Pick it up when" sentence "Measure first: S16-22 reads each handle's links from the pivots instead of walking the component, which may shrink the walked set enough to settle it." becomes "S16-22 replaced the walk: a warm proposal composes about 550 handles' links, 25 ms at 4,000 persons and 27 ms at 16,000 (Xeon 2.1 GHz); measure again before memoising." (line 3's and B-11's "went to Spike 16 S16-22" are history and stay); §7 of `promote-graph-alignment.md` also: the opening "There are no database calls during the walk. Everything it reads is loaded first:" becomes "On a warm catalog there are no database calls while `Align` runs: every node is cached since `Warm`, and a cold read loads on a miss. It reads:", and "so the query count follows the waves of the walk, not the size of the layer or the catalog" becomes "so the query count does not follow the size of the layer or the catalog", and the paragraph "Canonical adjacency without S9-28" has "so the view reads them in memory" in place of "so the walk reads them in memory"; the map's S16-22 scope entry (done at planning, see §12) | The scope entry names these lines; the sweep rule | — |
| D-16 | `Propose`'s middle becomes `func alignRows(c *database.Catalog, in inputs, fixed []graphalign.Fixed) (graphalign.Proposal, map[string][]byte, *canonView, error)` *(new)*: `mergeFixed`, `matchIndexOf`, `newCanonView`, `graphalign.Align`, then `view.err`; it returns the proposal, `promoted` and the view. `Propose` keeps `MAX(revision)`, `loadInputs`, the empty-layer return and `Connections` (which reads the anchors' `fixed` and `promoted`, so `alignRows` returns `promoted`; `pageEnds` takes the caller's `fixed` as today). `ViewLinksForTest` *(new)* in `export_test.go` is `loadInputs(c, graphID)` then `alignRows(c, in, nil)` and returns a copy of the view's `links` memo: one entry for each handle `Align` asked `Links` for, whatever its length | One sequence that T-4 tests, so a step `Propose` gains reaches the test (review M-3) | A test helper that copies `Propose`'s steps (review M-3) |

**Rules this plan bends.** None. The map's scope entry said "`newState`'s adjacency build go"; S16-21 already moved the canon's index out of `newState` into `Canon.View`, which D-9 moves to the tests. The scope entry was corrected at planning (§12).

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `canonlinks.Reader.Links` *(new)* | func | `Reader.Relationships`, `Reader.For` | `Relationships` is relationship bridges only, batched, with page inputs and siblings for the Family read; `For` is implied links only. `Links` is their composition for one node over every bridge: it calls `edge` and `For` (D-1) |
| `deriver.personType` *(new field)* | field | `deriver.eventTypeProp` | Same shape: a vocabulary id read once in `newDeriver` |
| `composeLinks`, `deriver.filedEdges` *(new)* | func | `Relationships`' per-step `LinkSet` loop; `relationshipEdges` | `composeLinks` is that loop moved out so `Relationships` and `Links` share it; `filedEdges` is `relationshipEdges` without the bridge filter (both call `edge`) |
| `alignRows` *(new)* | func | `Propose` | `Propose`'s middle, split so `ViewLinksForTest` runs the same sequence (D-16) |
| `promotealign.canonView`, `newCanonView` *(new)* | type, func | `graphalign.Canon.View` / `canonIndex`; `loadCanon` | `canonIndex` indexes a walked list; the view replaces the walk itself and moves `canonIndex` to the tests (D-3, D-9) |
| `WalkRowsForTest`, `TestViewProposesAsTheWalk` *(new, temporary)* | test helper, test | `PlaceLinksForTest` in `export_test.go` | Deleted in STEP-4 with the walk (D-8) |
| `ViewLinksForTest` *(new)* | test helper | `HandleForTest`, `PlaceLinksForTest` (`export_test.go`) | Same file; reads the view through `alignRows`, copying no step of `Propose` (D-16) |
| `TestLinks` *(new)*, `world.links` *(new)* | test, test helper | `TestRelationships` and `world.relationships`, `TestFor` and `world.for_` (`reader_test.go`) | Same `world` helper and `relShapes`; a new method needs its own table and its one-line reader, as each existing method has |
| `TestLargeSourceBudgets` "the view reads the Source's neighbourhood", "at 16,000 persons" *(new subtests)* | test | `TestLargeSourceBudgets` "warm queries", "after a handle commit" | Same fixture and helpers |

**Builds on.** The match index (S16-20) for profiles; the kinship pivots through `canonlinks.Reader.For` (S16-16); `CanonView` and its `Edge.From` contract (S16-21, S16-36); the candidates entry (S16-32); `largeFixture.warmProposal` / `proposalAfterCommit` (S16-16 D-8).
**Deletes.** `Relationships`' own `LinkSet` loop (onto `composeLinks`); `edgeOf`'s `self` parameter; `loadCanon` and its walk (`seeds`, the wave loop, `walkedPeople`, the global `LinkSet`, the implied placement); `kinship.LinkSet.PlaceImplied` and its subtest; `canonlinks.EdgeOf`'s export; `inputs.terms` and `loadInputs`' `LoadTerms` call; the `segmentcompare` import in `promotealign.go` (and in `canon.go` if nothing else uses it); `graphalign.Canon`, `View` and `canonIndex` from production code (to `export_test.go`); `WalkRowsForTest` and `TestViewProposesAsTheWalk` (temporary, STEP-4); the doc lines D-15 rewrites.
**Next adds.** "Memoise a person's composed kinship" now measures against a proposal that composes about 550 handles' links, not 18,000; a later reader of a handle's canon links (an Evidence graph comparison) calls `Reader.Links` with no new API.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| `Handle(id)` answers any match-index handle, not only the walked component | `core/graphalign/align.go` `newState`, `anchor`, `seed`, `place`, `segments` | `Align` asks only for fixed handles, candidates and the far ends of links it read; each of those was in today's component, so the answers are the same (AC-1.4). A merged or unknown id reads nil as today (D-4) |
| A read error mid-`Align` | `promotealign.Propose` | Today the error came from `loadCanon` before `Align`; now `Align` finishes on partial links and `Propose` discards the proposal and returns the error (D-6) |

### Scale

At the map's Scale (large fixture at 4,000 and 16,000 persons: 18,233 and 30,233 person, event and place handles) and bar 2's crafted sizes:

- **Warm proposal.** Today walks 18,233 handles and 30,347 links at 4,000 persons for Source A. The view reads the links of 543 handles (313 for the one-place Source) and, for the people among them, `For` from the pivots. Measured 170 → 25 ms and 207 → 27 ms at 4,000 and 16,000; 169 → 18 MB and 173 → 20 MB allocated per proposal.
- **After a handle commit.** No change to Apply: the match index, pivots and candidates update as today. Measured 180 → 25 ms and 207 → 27 ms.
- **Crafted sizes.** A city with 6,000 events: `Links(city)` reads 6,000 filed links once per proposal, only when `Align` scores the city (today the walk read them on every proposal whose component held the city). A person with 20,000 children: `Links(hub)` reads 20,000 filed links and the `For` links the pivots allow (`Rules.MaxPivotEnd`, `Rules.MaxPairSteps`), once per proposal, only when `Align` scores the hub. Each handle's links are read at most once per proposal (the memo, D-5).
- **Memory held.** None: the view dies with the proposal. The pivots a proposal fills are fewer (D-14 records the figures).

### Edges

- **Assumptions.** `Align` relies on `Links(id)` holding every link at `id` whose far end is a handle, each pair of ends and keys once, and on a link read from either end being the same link (its `Recording` counts in `kinship.CountedOnce`). `Reader.Links` gives each pair of ends and keys once through `LinkSet`; a filed link is on both nodes with the same association, and an implied link between two people is in both people's `For` (an event pattern names both participants; a chain through P is in `For` of both the grandparent and the grandchild). T-4 holds both ends equal on the large fixture.
- **Neighbors.** A link whose far end is merged or not a primary kind is dropped, as the walk dropped it. An implied link whose far end is a handle the recorded links do not reach (only through a merged event or parent the pivots still read) was dropped by the walk and is kept by the view; the planning run found none on the large fixture, and T-3 would show one as a moved row (Stop condition).
- **Removed inputs.** A handle merged or deleted by a commit leaves the match index in Apply; a view is built per proposal, so it never serves one. A Subject whose candidate was merged reads nil through `Handle` and is skipped by `seed`, as today.
- **Real data.** None — no table or seed drives the view.
- **Untrusted size.** Links per handle are unbounded, as today (the crafted city and hub above); the view reads a handle's links once per proposal and only for the handles `Align` scores, so its work is at most the walk's. `For` keeps the kinship bounds. No new bound.

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/canonlinks` | `func (r *Reader) Links(id []byte) ([]kinship.Link, error)` *(new)* (D-1); `deriver.edge` takes `neighbor` (D-2); `deriver.personType` *(new)*; `EdgeOf` → `edgeOf` (D-10); package doc (D-15) |
| `core/database/promotealign` | `canonView`, `newCanonView`, `Handle`, `Links`, `Candidates` *(new)* replace `loadCanon` (D-3 – D-7); `Propose` builds the view and returns `view.err` (D-6); `inputs.terms` goes (D-11) |
| `core/graphalign` | `Canon`, `View`, `canonIndex` move to `export_test.go` (D-9); package doc |
| `core/kinship` | `LinkSet.PlaceImplied` goes (D-12) |

`alignRows` after this PR (D-16); `Propose` calls `prop, promoted, _, err := alignRows(c, in, fixed)` in place of its `mergeFixed`, `matchIndexOf`, `loadCanon` and `Align` calls, then `Connections` as today:

```go
func alignRows(c *database.Catalog, in inputs, fixed []graphalign.Fixed) (graphalign.Proposal, map[string][]byte, *canonView, error) {
	anchors, promoted, err := mergeFixed(c.Graph(), in.graphID, in.evidence, fixed)
	if err != nil {
		return graphalign.Proposal{}, nil, nil, err
	}
	m, err := matchIndexOf(c.Graph())
	if err != nil {
		return graphalign.Proposal{}, nil, nil, err
	}
	view, err := newCanonView(c.Graph(), in.graphID, m, in.layer, anchors, in.cfg)
	if err != nil {
		return graphalign.Proposal{}, nil, nil, err
	}
	prop := graphalign.Align(in.layer, view, anchors, in.cfg)
	if view.err != nil {
		return graphalign.Proposal{}, nil, nil, view.err
	}
	return prop, promoted, view, nil
}
```

Errors: no new code; a graph read error is returned as today.

### FFI

None — no wire change.

### macOS

None — no Swift change.

### Strings

None — no copy.

## 7. Steps

**STEP-1 — Record today's figures**
Files: none changed.
Do: in a second worktree of the branch's base (`git worktree add ../s16-22-base <base>`, `<base>` the commit the branch was cut from), run `CGO_ENABLED=1 go test -tags fts5 -run '^$' -bench 'BenchmarkLargeSourcePropose|BenchmarkCacheSizes' -benchtime 1x ./core/database/promotealign/` with `PROVENENCIA_GRAPH_VERIFY` unset, and `hostname`. Keep the output for the PR description; STEP-5 runs the same command in the branch on the same machine, and the worktree is removed after it.
Check: the output has `warm-ms` and `after-commit-ms` for `persons=4000` and `persons=16000`.

**STEP-2 — `Reader.Links`**
Files: `core/database/canonlinks/reader.go`, `core/database/canonlinks/reader_test.go`. Skill: `add-match-rule` (line 33 is read now, changed in STEP-6).
Do: D-2, then D-1 (`composeLinks` with `Relationships` moved onto it). Add T-1.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/canonlinks/ ./core/database/persondetail/` passes (`TestRelationships` and the Family read unchanged).

**STEP-3 — The view, and its equivalence with the walk**
Files: `core/database/promotealign/canon.go`, `promotealign.go`, `export_test.go`, `perf_test.go`. Skill: `use-catalog-session`.
Do: D-3 – D-7 (the view beside `loadCanon`, which stays for this step only); `Propose` reads through `alignRows` (D-16) and no longer reads `in.terms`; `inputs.terms` and `loadInputs`' `LoadTerms` call stay until STEP-4, for `WalkRowsForTest`. D-16 (`alignRows`, `ViewLinksForTest`). D-8's `WalkRowsForTest` and `TestViewProposesAsTheWalk`. Add T-4.
Check: `CGO_ENABLED=1 go test -tags fts5 -run 'TestViewProposesAsTheWalk' -v ./core/database/promotealign/` passes at both sizes (keep its output for the PR description); `CGO_ENABLED=1 go test -tags fts5 ./core/database/promotealign/ ./core/graphalign/` passes.

**STEP-4 — The walk goes**
Files: `core/database/promotealign/canon.go`, `promotealign.go`, `export_test.go`, `perf_test.go`, `core/database/canonlinks/canonlinks.go`, `reader.go`, `reader_test.go`, `core/kinship/links.go`, `links_test.go`, `core/graphalign/types.go`, `export_test.go`.
Do: delete `loadCanon`, `WalkRowsForTest` and `TestViewProposesAsTheWalk` (D-8); D-9, D-10, D-11, D-12. Fix imports.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/...` passes; `rg -n "loadCanon|PlaceImplied|EdgeOf|walkedPeople|WalkRowsForTest" core` prints nothing; `rg -n "Canon\{|func \(c Canon\)" core --glob '!*_test.go'` prints nothing.

**STEP-5 — Bar 10's budget**
Files: `core/database/promotealign/perf_test.go`.
Do: D-13 (T-5). Rerun STEP-1's command on the branch, same machine.
Check: `CGO_ENABLED=1 go test -tags fts5 -run TestLargeSourceBudgets -v ./core/database/promotealign/` passes and logs the 16,000 figures; `PROVENENCIA_GRAPH_VERIFY=1 CGO_ENABLED=1 go test -tags fts5 ./core/database/promotealign/ ./core/database/canonlinks/` passes; branch `warm-ms` at `persons=16000` is at most a third of STEP-1's (AC-1.1).

**STEP-6 — Docs**
Files: `docs/promote-graph-alignment.md`, `docs/matching-model.md`, `.agents/skills/add-match-rule/SKILL.md`, `docs/catalog-caches.md`, `docs/ideas/promote-ranking.md`, `docs/deployment-plan/spike-16/completed.md`, `docs/deployment-plan/spike-16/deployment-plan.md` (map row), this plan (status, Landed note).
Do: D-14, D-15, and the Definition of done.
Check: `scripts/check-pr.sh` prints `check-pr: PASS`; AC-2.5's `rg` prints nothing.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/canonlinks/reader_test.go` `TestLinks` *(new)*, table-driven over `world`; each row compares `lesserFirst(w.relShapes(w.links(id)))` with its `want` after sorting both by `A`, `B`, then `Assoc` (link order is `LinkSet`'s and refs come from the kit, so the test does not pin it; D-5's order is held by T-3) | "a person's birth": `ann, bob := w.person("Ann"), w.person("Bob")`; `b1 := w.event("B1", vocabkey.EventBirth)`; `w.join("B1/Ann", ann, b1, "subject")`; `w.join("B1/Bob", bob, b1, "father")` → `w.links(ann)` (`world.links` *(new)*: `w.r.Links(id)`, failing the test on an error) has 2 links: the filed Ann–B1 link, `Assoc` `{"B1/Ann"}`, `OnlyImplied` false, with `KeyA`/`KeyB` equal to that association's edge in `w.edgesOf()`; and the implied Ann–Bob parent link, `Assoc` `{"B1/Ann", "B1/Bob"}`, `Shapes` `{"birth_parents/B1"}`, `OnlyImplied` true, keys from `w.keys(vocabkey.BridgeRelationship, vocabkey.TermParent)` with Bob as the parent end. "a filed parent link merges with the implied one": the same setup plus `w.parent("BA", bob, ann)` → 2 links: the filed Ann–B1 link as above, and one Ann–Bob parent link with `Assoc` `{"B1/Ann", "B1/Bob", "BA"}`, `OnlyImplied` false. "an event implies nothing": a fresh world with the first row's setup, `w.links(b1)` → 2 links, B1–Ann (`{"B1/Ann"}`) and B1–Bob (`{"B1/Bob"}`), and `w.hasPivot(b1)` is false after the call. "no node": `w.r.Links(make([]byte, 16))` → nil, nil | AC-2.4, D-1, D-2 |
| T-2 | Go | `core/database/canonlinks/reader_test.go` `TestForMatchesDerive`, `TestRelationships`, `TestRelationshipsOptionsSiblings` and the other existing tests | `world.edgesOf` reads through `filedEdges`; `Relationships` reads through `composeLinks`; unchanged results | D-1, D-2, D-10 |
| T-3 | Go | `core/database/promotealign/perf_test.go` `TestViewProposesAsTheWalk` *(new, temporary: STEP-3, deleted in STEP-4)* | For persons 4,000 then 16,000: `lf := newLargeFixture(t, persons)`; for Source A and the one-place Source, `lf.propose(g, nil).Rows` equals `promotealign.WalkRowsForTest(lf.c, g)` → 100 and 61 equal rows | AC-1.4, D-5, D-8 |
| T-4 | Go | `perf_test.go` `TestLargeSourceBudgets` subtest "the view reads the Source's neighbourhood" *(new)*, after "warm queries" | `links, err := promotealign.ViewLinksForTest(f.c, aGraph)` → `len(links) < 1500`; for every id and link, `l.From(id)`'s far end `b` has `promotealign.HandleForTest(g, b)` ok; when `links[string(b)]` is present it holds a link with equal `A`, `B`, `KeyA`, `KeyB` and `Recording` (`reflect.DeepEqual` on those fields) | AC-2.1, AC-2.2, D-5 |
| T-5 | Go | `perf_test.go` `TestLargeSourceBudgets` "warm" (budget 150 ms) and "at 16,000 persons" *(new)* | D-13 → within budget; 16,000 warm ≤ 2 × 4,000 warm; after-commit ≤ 1.5 × warm | AC-1.2, AC-1.3, D-13 |
| T-6 | Go | `core/kinship/links_test.go` `TestLinkSet` | The "PlaceImplied places without growing the set" subtest is deleted; the rest pass | D-12 |
| T-7 | Go | `core/graphalign/align_test.go`, `invariants_test.go`, `candidates_test.go`, `connections_test.go` | Pass unchanged with `Canon` in `export_test.go` | AC-1.5, D-9 |
| T-8 | Go | `perf_test.go` `TestLargeSourceBudgets` "warm queries"; `memo_test.go` `TestProposeWarmIssuesNoQuery`, `TestMemoIsNotMutated`; `promotealign_test.go` (every test) | Pass unchanged | AC-1.5, AC-2.3, D-4, D-6 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `core/database/promotealign` (budgets, warm queries), `core/graphalign` (goldens), `core/database/canonlinks`. Also run `PROVENENCIA_GRAPH_VERIFY=1 CGO_ENABLED=1 go test -tags fts5 ./core/database/promotealign/ ./core/database/canonlinks/` once.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: AC-1.1 STEP-1/STEP-5 figures; AC-1.2, AC-1.3 T-5; AC-1.4 T-3 output; AC-1.5 T-7, T-8; AC-2.1, AC-2.2 T-4; AC-2.3 T-8; AC-2.4 T-1; AC-2.5 the rg line
- [ ] Every T-# in §8 exists and passes (T-3 ran in STEP-3 and is deleted in STEP-4)
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] The Verify run in §8 passes
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left — none in this PR
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left (`loadCanon`, `PlaceImplied`, `EdgeOf`, `graphalign.Canon`), and `rg -nw Canon docs/promote-graph-alignment.md` shows no line that describes production code building a `Canon`; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated — none
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New — no UI
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated) — not gated
- [ ] Domain doc updated: docs/promote-graph-alignment.md §4, §7, §12; docs/matching-model.md line 31; add-match-rule line 33; docs/catalog-caches.md (D-14); docs/ideas/promote-ranking.md (D-15)
- [ ] PR description: what shipped, AC evidence (STEP-1 and STEP-5 figures with `hostname`, T-3's output), deviations, manual check
```

## 10. Manual check

1. On the large fixture (or a dogfood project of several thousand people), open Promote on a Source of about 40 people before and after the branch: the rows, their bands, their alternatives and their order are the same.
2. Decide one row (put it on a record) and watch the re-proposal: it returns without the pause the branch base shows.
3. AC-1.1: compare `warm-ms` at `persons=16000` from STEP-1 (the base) and STEP-5 (the branch), same machine: the branch figure is at most a third of the base's.
4. AC-2.5: `rg -n "loadCanon|PlaceImplied|EdgeOf|walkedPeople" core .agents docs/*.md` prints nothing.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A tie-break moves because a handle's link order is its own, not the walk's (D-5) | T-3 at both sizes, the goldens and the `promotealign` suite; measured equal at planning |
| A warm proposal loads a node the walk had prefetched (an event neighbor that is merged) | T-8 "warm queries" counts graph queries; measured 0 at planning |
| CI's runner is slower than the planning machine | 150 ms is six times the planning figure; the 16,000 checks are ratios of figures on the same runner |

**Stop and report if:**

- T-3 finds a differing row: report the Source, the Subject, both rows and the handles whose links differ. Do not change the order or the filter.
- STEP-5's `warm-ms` at 16,000 persons is more than a third of STEP-1's on the same machine.
- T-8 "warm queries" counts a graph query, or T-4 finds 1,500 handles or more read, or a link that differs at its two ends.
- `kinship.Edge.From` returns `ok == false` for a link `Reader.Links(id)` returned for `id`.
- A production file outside `core/graphalign` needs `graphalign.Canon` after STEP-4.
- `Reader.Links` on a place or event fills a kinship pivot (T-1 "an event implies nothing").

## 12. Open questions

None. The map's S16-22 scope entry was corrected at planning ("and `newState`'s adjacency build go" → "and `graphalign.Canon` with its index moves to the tests"; S16-21 had already moved the canon's adjacency out of `newState`).

## 13. PR

**Title:** S16-22 — Promote reads each handle's neighbourhood instead of walking the catalog
**Body:** objective in one sentence; what shipped against US-1 and US-2; AC evidence (STEP-1 and STEP-5 `BenchmarkLargeSourcePropose` and `BenchmarkCacheSizes` figures with `hostname`, T-3's output at 4,000 and 16,000); deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-22-canon-neighbourhoods.md`.
