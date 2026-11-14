# S16-36 — A link from a record to itself is refused where links are read

**Status:** Landed in [#841](https://github.com/mendahu/provenencia/pull/841) (2026-11-14)
**Spike / slice:** Spike 16 · Slice 2d — Promote
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: a hand-edited catalog's self-loop stops being read; no view the app can reach looks different)
**Board:** —
**Depends on:** S16-21 (landed [#836](https://github.com/mendahu/provenencia/pull/836))
**Blocks:** S16-22 (its session-graph view reads links through `kinship.Edge.From` and handles no self-loop)
**Branch:** `s16-36-refuse-self-loops`
**Version bump:** none — no change a researcher can reach through the app, and no wire or catalog change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`use-catalog-session`](../../../../.agents/skills/use-catalog-session/SKILL.md) (the graph cache, its loads and Verify), [`add-match-rule`](../../../../.agents/skills/add-match-rule/SKILL.md) (the layer packages `core/kinship`, `core/graphalign`, `core/recordlinks`)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table-driven tests), `.cursor/rules/match-rules.mdc` (`core/kinship`, `core/graphalign`, `core/recordlinks` and `core/connectrules` stay pure: no catalog I/O)
**Context:** working rules "(Batch 2) A link with one record at both ends is crafted data, refused where links are read" (user, 2026-11-14) and "(Batch 2) The point of this batch is simpler code"; [S16-21 plan](S16-21-canon-view-place-links.md) D-1, D-3, D-14, D-16 (the self-loop readings this PR removes); [S16-21 ship log](S16-21-canon-view-place-links.ship.md) MNT-2b; [`promote-graph-alignment.md`](../../../promote-graph-alignment.md) line 198
**Planned:** 2026-11-14 against `main` @ `1255b24`
**Review:** [`S16-36-refuse-self-loops.review.md`](S16-36-refuse-self-loops.review.md) — Fits — Ready with changes, 2 rounds, no open blocker

**Landed.** Differences from the plan: T-1 commits `k.Commit(loop, town, city, self, part)` with the association ids; T-3 sits inside `TestCreateCitedBridge` because `countBridges` is a closure there; `TestPlaceEntryInputsMatchReads` reads `reads(id, hops.PartsOfPlace)` inline and the `pageReads` helper is gone. T-11 to T-13 came from the two plan amendments.

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

No genealogical link joins a record to itself, and the app never writes one: `connect.CreateCitedBridge` refuses a Source bridge whose two ends are one Subject, and filing refuses a canonical link whose two ends are one handle (`connectrules.DecisionSelfLink`); a claim cannot move to another handle without Unpromote, which unfiles its bridges. So a stored self-loop only comes from a hand-edited catalog. This PR makes the graph cache drop such a link at the two places it reads the catalog's links, and removes every reader downstream that handled one: `kinship.Edge.Readings` and `Ends`, `kinship`'s equal-ends check, `graphalign`'s view and layer reading, `recordlinks.NewGraph`'s loop over ends, and the place pages' `selfOnly` hop, with their tests.

**Why now.** S16-22 writes a session-graph `CanonView` that serves each handle's links. If self-loops are still read, that view inherits D-1's "a self-loop is listed once" contract and `Readings`' "read twice" rule, one more reader of a case the app never produces (map scope entry: "Lands before S16-22, so the session-graph view does not add another self-loop reader"). It also closes S16-21 MNT-2b.

**What stays.** Every result on a catalog the app wrote: Promote's goldens and `TestAlignInvariants` (minus the self-loop fixture), the place entries, pages and successions, Family, record links, Verify. `connectrules.DecisionSelfLink` and its filing path: two Source records claimed onto one handle are real data, and filing keeps refusing their link. `kinship`'s pattern guards that keep one person out of both ends of an implied link (`eventLinks`' `x.person == y.person`, `eachChain`'s `upStep.g == down.m`, `Siblings`' `c == person`): those are about one person in two roles, not a stored link.

## 2. User stories

**US-1.** As the engine, when the catalog holds a canonical link whose two ends are one handle, the graph cache does not read it, so no reader above it has a self-loop case.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A catalog with places Loop, Town, City; a hand-written `part_of` link Loop → Loop (`graphcachetest.Canon.PartOf(loop, loop)`) and Town → City; committed, cache dropped; `g.Node(loop)` | `Links` is empty |
| AC-1.2 | Same catalog; `g.Node(town)` and `g.NodesOnBridges([loop], "place_relationship")` | Town has one link (to City); Loop's node from `NodesOnBridges` has no link |
| AC-1.3 | Same catalog; `g.Verify()` after reading both nodes | nil |

**US-2.** As the engine, when an Evidence graph holds a bridge whose two endpoint values are one Subject, the Evidence graph walk does not return it.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | The walk fixture with places York and Hull; a `part_of` place relationship York → Hull; a second one York → Hull whose `to` Observation is then set to York (SQL `UPDATE`); `WalkEvidenceGraph(eg, hops.ParentsOfPlace, [york])` | One edge: (York, the York → Hull bridge, Hull) |
| AC-2.2 | Same fixture; `WalkEvidenceGraph(eg, hops.PartsOfPlace, [york])` | No edge |

**US-3.** As a contributor, the refusal that keeps the app from writing a Source self-loop is held by a test.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `connect.CreateCitedBridge` with the input of the "person person relationship" subtest, `s.personB` replaced by `s.person` (`ToSubjectID` and the `related_to` Observation) | `errors.Is(err, connect.ErrInvalid)`; the count of `relationship` bridges is unchanged |

**US-4.** As a contributor, no reader above the graph cache handles a self-loop.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | Search 1 in §10 | Hits only: the two guard comments (`core/database/graphcache/load.go`, `core/database/graphcache/evidence_graph.go`), their tests (`graph_test.go` `TestLinkFromARecordToItselfIsNotRead`, `evidence_graph_walk_test.go` case "a link from a place to itself is not walked"), the `DecisionSelfLink` filing test row `core/connectrules/filing_test.go` "a link to itself" (D-8), and three lines that are not about a stored link: `core/kinship/kinship_test.go` "joins a Subject to itself" (`TestDeriveInvariants`: no implied link has one person at both ends), `core/segmentcompare/segmentcompare_test.go` "a link does not correspond to itself" (a key corresponds to itself), `core/database/conclusionsummaries/placechains_test.go` "Toronto itself" |
| AC-4.2 | Search 2 in §10 | No hit |
| AC-4.3 | The goldens in `core/graphalign/align_test.go`, `TestAlignInvariants`, `TestProposeReportsEachConnection`, the place entry tests, `core/recordlinks` tests | Pass with no expected value changed, except the rows §8 T-6 – T-10 delete or rewrite |

## 3. Scope

| In | Covered by |
| --- | --- |
| Guard in `graphcache` where canonical links are read (`linkRaws`) | STEP-1, AC-1.1 – AC-1.3 |
| Guard in `graphcache` where Evidence graph bridges are read (`WalkEvidenceGraph`) | STEP-1, AC-2.1, AC-2.2 |
| `connect.CreateCitedBridge`'s equal-ends refusal gets its test | STEP-2, AC-3.1 |
| `graphalign` reads links through `Edge.From`: `Canon.View`, `newState`'s layer loop, `corresponding`; `CanonView` doc | STEP-3, AC-4.2, AC-4.3 |
| `recordlinks.NewGraph` files each link under `A` and `B` (closes S16-21 MNT-2b) | STEP-4, AC-4.2 |
| `kinship.Edge.Readings` and `Edge.Ends` deleted; `readsTerm`'s equal-ends check and its doc lines go | STEP-5, AC-4.1, AC-4.2 |
| Place pages lose the `selfOnly` hop; `followHop` goes; `FiledPlaceLinks` doc | STEP-6, AC-4.1, AC-4.2 |
| Self-loop tests deleted or rewritten (§8 T-6 – T-10) | STEP-3 – STEP-6 |
| `promote-graph-alignment.md` names the read-time drop | STEP-7 |

| Out | Home |
| --- | --- |
| `connectrules.DecisionSelfLink`, the filer's and the proposal's self-link outcome | not planned — real data (two Source records claimed onto one handle); map scope entry "Not this PR" |
| A refusal in `observations.Update` when an edit sets a bridge's two endpoint values to one Subject | not planned — the Citation composer edits no endpoint value of an existing bridge; if it did, the read-time drop reads the bridge as no link, and the Promote page lists it as a refused self-link (§6 Edges) |
| Logging or counting dropped self-loops, or a Verify finding for them | not planned — D-2: crafted data reads as nothing, as an unregistered bridge does today |
| The session-graph `CanonView` and the walk's removal | S16-22 |
| Rewording the three unrelated `rg` hits in AC-4.1 | not planned — they are not about a stored link |

## 4. Current state

Verified at `1255b24`.

| Area | Where | Today |
| --- | --- | --- |
| Canonical link read | `core/database/graphcache/load.go` `(*Graph).linkRaws` | Runs `linkLoadSQL` and keeps each row whose bridge is registered (`connectrules.LookupBridge`, `bridgeEndpoints`); drops the rest with `continue`. A self-loop association yields two rows for one handle (one per endpoint), both with `neighbor` = `self`. Callers: `loadLinks` (every `Node`/`Kind`/`NodesOnBridges` load, and `Verify`'s fresh load at `verify.go:126`) and `commit.go` `mergedNeighbors` |
| Canonical link finish | `core/database/graphcache/load.go` `(*Graph).finishLinks` | Dedupes rows on `self|assoc|neighbor`, so a self-loop keeps the first of its two rows: one `Link` whose `FromEnd` depends on row order |
| Evidence graph walk | `core/database/graphcache/evidence_graph.go` `(*Graph).WalkEvidenceGraph` | Pairs each bridge Subject's positive `from`-property Observation (a wanted Subject) with each of its `to`-property values on the graph and returns one `EvidenceEdge` per pair; a bridge whose two values name one Subject yields an edge with `From` = `To`. Callers: `evidencelayer.links` (every bridge, endpoint 0 → 1), `core/database/graphfill/load.go` (participation and location hops) |
| Source bridge write | `core/database/connect/connect.go` `CreateCitedBridge` line 72 | `bytes.Equal(from.ID, to.ID)` → `ErrInvalid`. No test covers it (`connect_test.go` `TestCreateCitedBridge` has no equal-ends subtest) |
| Edge readings | `core/kinship/kinship.go` `Edge.Readings`, `Edge.Ends` | Added by S16-21 (D-14) only for the self-loop: `Readings(id)` yields both ends' readings when `A` = `B` = `id`; `Ends` yields `A` once when `A` = `B`. For a link with two different ends, `Readings(id)` is `From(id)` and `Ends` is `A`, `B` |
| Relationship read | `core/kinship/kinship.go` `readsTerm`, `ParentStep` (doc lines 354, 369) | `readsTerm` returns false when the two ends read are equal ("a link that joins a Subject to itself"). `ParentStep` and `families.go` `KinOf` read through it |
| Canon view | `core/graphalign/types.go` `CanonView` (doc lines 33–35), `Canon.View` | `Links` doc: "A link from a handle to itself is listed once. Read a link from id through kinship.Edge.Readings." `View` files each edge under each of `e.Ends()` |
| Align layer and canon reads | `core/graphalign/align.go` `newState` (lines 124–130), `(*state).corresponding` (lines 303–316) | `newState`: `for end := range b.Ends() { for other, key := range b.Readings(end) { layerAdj[end] = append(…) } }`. `corresponding`: `for other, key := range l.Readings(hid)` |
| Record links | `core/recordlinks/recordlinks.go` `NewGraph` line 124, `addLink` | `for end := range l.Ends() { g.addLink(l, end) }`; `addLink` reads `l.Edge.From(end)` (MNT-2b: a self-loop's second reading is never read here) |
| Place follow | `core/database/conclusionsummaries/placeentries.go` `followHop{hop, selfOnly}`, `followPlaces`, `entryHops`, `fillPlacePages` (`pageHops` line 221), `fillPlaceSuccessions` (`succHops`), `placeInputs` | The page follows `PartsOfPlace` and, with `selfOnly`, `ParentsOfPlace` for the one link from the place to itself (the cache holds a self-loop from one end only); `partTo` is `dedupePlaceLinks(append(f.oriented[0], f.oriented[1]...))`; the page's inputs include the `ParentsOfPlace` keys |
| Filed place links doc | `core/database/conclusionsummaries/placeentries.go` `FiledPlaceLinks` doc line 325 | "A place that is part of itself leads to itself." |
| Tests | `core/kinship/kinship_test.go` `TestEdgeEnds`, `TestEdgeReadings`, `TestParentStep` row "self link", `TestDeriveInvariants` (`rel(person(), person(), …)` can draw one person twice) | Hold the self-loop readings |
| Tests | `core/graphalign/align_test.go` `TestCanonView` row "a link from a handle to itself is listed once", subtest "readings of the stored links" (reads through `Readings`, asserts a self-loop's two readings) | Hold D-1 / D-14 |
| Tests | `core/graphalign/invariants_test.go` `placePartOfItself`, `TestPlacePartOfItselfPlaces`, `TestAlignInvariants` row "a place part of itself on both sides" | Hold D-16 |
| Tests | `core/database/conclusionsummaries/placeentries_test.go` `TestPlaceEntries` case "self-loop"; `TestPlaceEntryInputsMatchReads` `pageReads` (adds the `ParentsOfPlace` from-end key); `TestFiledPlaceLinks` row "a place part of itself" | Hold the `selfOnly` hop and the loop's chain |

**Precedent.** The drop sits beside the existing one in `linkRaws`: a row whose bridge is not registered is skipped with `continue`, and `WalkEvidenceGraph` returns nothing past `maxWalkEdges` (crafted data reads as nothing). The reader removals undo S16-21 ([#836](https://github.com/mendahu/provenencia/pull/836)) D-14 and D-16: for a link with two different ends, `newState`'s layer loop reads `From` from `A` then from `B`, the readings and order `Ends`/`Readings` give today. Copy the walk test's SQL `UPDATE` of an endpoint Observation (`evidence_graph_walk_test.go`, "A to-end on another Source") to make the Evidence self-loop.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | Two guards, both in `core/database/graphcache`, one per way the catalog's links are read. **Canon:** in `(*Graph).linkRaws`, after the registered-bridge check, `if bytes.Equal(r.self, r.neighbor) { continue }`, with the comment `// A link from a record to itself is crafted data: the app never files one (connectrules.DecisionSelfLink), so it is not read.` **Evidence:** in `(*Graph).WalkEvidenceGraph`'s output loop, before the `seen` check, `if bytes.Equal(r.from, to) { continue }`, with the comment `// A bridge from a Subject to itself is crafted data: connect.CreateCitedBridge refuses one, so it is not read.` | The working rule covers both the canon (filing) and the Source layer (`CreateCitedBridge`; S16-21 D-16's "layer self-loop"). `linkRaws` is the one function every canonical link read goes through (`loadLinks` → `Node`, `Kind`, `NodesOnBridges`, `Verify`; and `mergedNeighbors`); `WalkEvidenceGraph` is the one reader that turns Evidence graph bridges into links (`evidencelayer.links`, `graphfill`). Two other readers take a bridge's endpoint Observations directly, `promotealign` `pageBridges` and the filer's `bridgeHeads` (`core/database/identityclaims/bridgefile.go`); they decide a self-link through `connectrules.DecisionSelfLink` (D-8) and never read it as a link, so they need no guard. Two code paths read two stores; no single function sees both | One guard in `kinship.LinkSet` or `canonlinks` — `graphcache.Node.Links` would still hold the loop for `Follow` and the place entries; an SQL predicate in `linkLoadSQL` — the bridge filter that drops rows already lives in Go in `linkRaws`, and `TestLoadLinksUsesTheEdgeIndex` stays untouched |
| D-2 | The guards drop the link; the read does not fail, and nothing is logged | A failed read would fail every page and every Promote proposal that reaches the handle, and Verify, on a project whose only fault is one hand-written row. `linkRaws` already drops unregistered bridges and `WalkEvidenceGraph` drops a walk past its cap: crafted data reads as nothing. Verify compares the cache with `loadLinks`, which goes through the same guard, so it agrees | An error (`graphcache.ErrSelfLink`) — one bad row makes the whole catalog unreadable; a log line — graphcache has no logger, and there is no reader for it |
| D-3 | `kinship.Edge.Readings` and `kinship.Edge.Ends` are deleted. Every caller reads a link from an end with `Edge.From`. `Canon.View`: `ix.links[string(e.A)] = append(…, e)` then `ix.links[string(e.B)] = append(…, e)`. `newState`'s layer loop: `for _, end := range [][]byte{b.A, b.B} { other, key, _ := b.From(end); st.layerAdj[string(end)] = append(st.layerAdj[string(end)], adjLink{neighbor: other, key: key, Recording: b.Recording}) }`. `corresponding`: `other, key, ok := l.From(hid); if !ok { continue }`, then the same `ce` and checks. `recordlinks.NewGraph`: `g.addLink(l, l.A)` then `g.addLink(l, l.B)` | Both methods exist only for the self-loop (S16-21 D-14); for a link with two ends they equal `From` and `{A, B}`, so the order of every list is unchanged. One end-reading rule, `From`, which `addLink`, `families.go` and S16-22 already use. Batch rule "simpler code": two methods and their tests go | Keeping `Ends`/`Readings` with the self-loop branch removed — two names for `{A, B}` and `From` |
| D-4 | `readsTerm` loses `|| bytes.Equal(first, second)`; its doc and `ParentStep`'s doc lose "and for a link that joins a Subject to itself". `TestParentStep` loses its "self link" row. `TestDeriveInvariants` draws the two ends of a `rel` edge distinct: `a := person(); b := person(); for b == a { b = person() }`, then `rel(a, b, …)` | No link with equal ends reaches `kinship`: the guards drop recorded ones, and the patterns imply none (`eventLinks`, `eachChain`, `Siblings` keep their own guards, D-8). The random test must hold the input contract the guards now give | Keeping the check "for safety" — the working rule says no reader handles it |
| D-5 | `CanonView.Links` doc becomes: `Links is every link with id at an end, as stored (not turned to face id), in the view's link order. Read a link from id through kinship.Edge.From.` | The contract S16-22 implements; no self-loop clause | — |
| D-6 | `followHop` is deleted. `followPlaces(g, v, ids, hopList ...hops.Hop)`; the loop reads `n.Follow(h)` with no `selfOnly` filter. `placeInputs(id, f, hopList []hops.Hop)` calls `graphcache.FollowKeys(id, h, f.links[i])`. `entryHops = []hops.Hop{hops.ParentsOfPlace}`; `fillPlacePages` uses `pageHops := []hops.Hop{hops.PartsOfPlace}` and `partTo: f.oriented[0]`, and its comment about a place part of itself goes; `succHops := []hops.Hop{hops.SuccessorsOfPlace, hops.PredecessorsOfPlace}`. `FiledPlaceLinks`' doc loses "A place that is part of itself leads to itself." `dedupePlaceLinks` is deleted: `partFrom`, `partTo`, `succFrom` and `succTo` take `f.oriented[0]` or `f.oriented[1]` as they are | With no self-loop in `Node.Links`, the `selfOnly` hop reads nothing; the struct has no other field. `dedupePlaceLinks` came with the self hop (666da56) to merge two hops' lists; each list is now one hop's, and a hop's links are already one per association and neighbor (`graphcache.finishLinks` dedupes on `self|assoc|neighbor`; `Node.Follow` keeps one `FromEnd`), so it drops nothing. A page's inputs lose the `ParentsOfPlace` keys: a commit that changes only a place's wholes no longer drops its page, which reads only its parts | Keeping `followHop` with one field — a wrapper over `hops.Hop` |
| D-7 | Tests: `TestEdgeEnds` and `TestEdgeReadings` deleted. `TestCanonView` loses its self-loop row; its subtest "readings of the stored links" reads each link through `l.From(at)` and keeps the York and Ontario assertions; the self-loop assertion goes. `placePartOfItself`, `TestPlacePartOfItselfPlaces` and the `TestAlignInvariants` row go. `TestPlaceEntries` case "self-loop" goes (AC-1.1 – AC-1.3 hold the canonical loop at the guard). `TestPlaceEntryInputsMatchReads`' `pageReads` becomes `reads(id, hops.PartsOfPlace)` (its helper comment goes). `TestFiledPlaceLinks` loses `loop`, its `k.PartOf(loop, loop)` and its row | Each holds a reading this PR removes; the guard tests hold the one behaviour left | Rewriting them to assert "no link" — a second test of the guard in each package |
| D-8 | Stays: `connectrules.DecisionSelfLink`; `kinship` `eventLinks`' `bytes.Equal(x.person, y.person)`, `eachChain`'s `bytes.Equal(upStep.g, down.m)`, `Siblings`' `bytes.Equal(c, person)`, `families.go`'s person checks; `TestDeriveInvariants`' "joins a Subject to itself" assertion | Each guards one person standing in two roles of real data, not a stored self-loop | — |
| D-9 | `conclusion-layer-data-model.md` §2.7 (line 106) gains one sentence after the sentence ending "never blocks the repair that rewrites it.": `A stored link from a record to itself, which only a hand-edited catalog holds, reads as absent: the graph cache drops it where it reads the catalog's links and an Evidence graph's bridges.` `promote-graph-alignment.md`'s bullet "A link from a handle to itself" (line 198) gains at its end: `A stored one, from a hand-edited catalog, is not read at all (conclusion-layer-data-model.md §2.7, linked as `conclusion-layer-data-model.md#27-the-auto-reconciler-cache`).` | §2.7 is where the graph cache's read rules live, beside the same precedent (a bad stored value reads as absent); the drop changes what Family, place pages and record links read, not only Promote | Only Promote's doc — the rule covers every reader |

**Rules this plan bends.** Working rule "(Batch 2) A link with one record at both ends is crafted data, refused where links are read" said "refused once" → D-1 places one guard on each of `graphcache`'s two link reads (canon links, Evidence graph bridges), because the rule's readers include `graphalign`'s layer, which reads Evidence graph bridges (review M-1) → the user chose two guards (2026-11-14) → the rule, the S16-36 map row, scope entry and Check were reworded in the planning commit; nothing left for a Step.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| The `bytes.Equal(r.self, r.neighbor)` drop in `linkRaws` | guard | the registered-bridge `continue` in the same loop | Extends that loop: a second reason to skip a row, beside the first |
| The `bytes.Equal(r.from, to)` drop in `WalkEvidenceGraph` | guard | the `seen` skip in the same loop | Extends that loop |
| `TestLinkFromARecordToItselfIsNotRead` *(new)* | test | `TestNodesOnBridges`, `TestNodeAndKindAndVerify` in `graph_test.go` | A new behaviour of the load; uses `graphcachetest.Canon` as `TestFiledPlaceLinks` does |
| Walk case "a link from a place to itself is not walked" *(new row)* | test | `TestWalkEvidenceGraphEdges` | A row in the existing table |
| `TestCreateCitedBridge` subtest "equal ends" *(new)* | test | the "attach with citation fields invalid" subtest | Same seed and assertion shape |

**Builds on.** `graphcache`'s read-time filtering of rows it does not read (unregistered bridges, the walk cap); `kinship.Edge.From` as the one end-reading rule.
**Deletes.** `kinship.Edge.Readings`, `kinship.Edge.Ends` (last callers in `graphalign` and `recordlinks` move to `From`); `readsTerm`'s equal-ends check; `conclusionsummaries.followHop` and its `selfOnly` filter; `conclusionsummaries.dedupePlaceLinks` (D-6); the page's `ParentsOfPlace` hop; the self-loop clauses in the docs of `CanonView.Links`, `Edge`'s methods, `readsTerm`, `ParentStep`, `FiledPlaceLinks`, `fillPlacePages`; the tests in D-7.
**Next adds.** S16-22's session-graph `CanonView` serves `Links(id)` from the kinship pivots and the node and states no self-loop rule; `Align` reads them through `From`.

### Reach

None — no new path into existing code. The one state that changes is a hand-edited catalog's self-loop, which now reaches no reader: a place part of itself shows no "Part of" or "Contains" row of itself on its Place page (before: one of each), and Promote reads the handle with no link.

### Scale

At the map's Scale (large fixture, 18,000 and 37,000 handles): each guard is one `bytes.Equal` per link row read or per walked edge, beside work already done per row. No cache, list or commit fan-out changes. A page's inputs shrink by its `ParentsOfPlace` keys, so a commit drops fewer pages. Promote's budgets (`TestLargeSourceBudgets`) stay as they are; nothing here is measured.

### Edges

- **Assumptions.** After this PR, `kinship`, `graphalign` and `recordlinks` assume every link has two different ends; the guards make it true for links read from the catalog (T-1, T-2), and the patterns make it true for implied links (D-8; `TestDeriveInvariants` asserts it, with inputs that hold it). A hand-built `kinship.Link{A: x, B: x}` in a test reaches `newState` as two appends on `x` and `Canon.View` as two entries on `x`; no test or golden builds one after D-7 (AC-4.1).
- **Neighbors.** A Source bridge whose two ends are one Subject is still listed on the Promote page as a connection, refused as a self-link (`DecisionSelfLink`, "has both ends on one record", `promote-graph-alignment.md` line 53), through `pageBridges`; the alignment no longer reads it as a link. A link between two different handles: unchanged (AC-1.2, AC-2.1; goldens, AC-4.3). Two Source records claimed onto one handle: filing still refuses their link (`DecisionSelfLink`, unchanged; `connectrules` filing tests). One person at two roles of one event: no implied self-link (D-8, unchanged).
- **Removed inputs.** A dropped self-loop contributes nothing anywhere: no place chain hop (it already read none: `TestPlaceEntries` "self-loop" asserted no parents at a date), no page row, no Promote link, no record line, no kinship step. A commit to the loop's association still reloads its one end (`OnCommit` reloads association ends from the commit's roots), which then reads no link: `Verify` agrees (AC-1.3).
- **Real data.** None — the rule is read-time, and the app writes no self-loop (`CreateCitedBridge` line 72, `DecisionSelfLink`, Promote refuses a second claim: `promote.Save` → `identityclaims.ErrAlreadyMember`).
- **Untrusted size.** None — the guards drop rows; they add no list or loop.

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/graphcache` | `load.go` `linkRaws`: the self-loop drop (D-1). `evidence_graph.go` `WalkEvidenceGraph`: the self-loop drop (D-1) |
| `core/kinship` | `kinship.go`: `Edge.Readings`, `Edge.Ends` deleted (D-3); `readsTerm`'s equal-ends check and the doc clauses go (D-4) |
| `core/graphalign` | `types.go`: `CanonView.Links` doc (D-5), `Canon.View` (D-3). `align.go`: `newState` layer loop, `corresponding` (D-3) |
| `core/recordlinks` | `recordlinks.go` `NewGraph` (D-3) |
| `core/database/conclusionsummaries` | `placeentries.go`: `followHop` gone, `followPlaces`, `placeInputs`, `entryHops`, `fillPlacePages`, `fillPlaceSuccessions`, `FiledPlaceLinks` doc (D-6) |

Errors: none new.

### FFI

None — no wire change.

### macOS

None — no Swift change.

### Strings

None — no user-facing copy.

## 7. Steps

**STEP-1 — Drop a self-loop where links are read**
Files: `core/database/graphcache/load.go`, `core/database/graphcache/evidence_graph.go`, `core/database/graphcache/graph_test.go`, `core/database/graphcache/evidence_graph_walk_test.go`, `core/database/conclusionsummaries/placeentries_test.go`. Skill: `use-catalog-session`.
Do: write T-1 and T-2 first and see them fail; add the two guards (D-1, D-2). The guard makes two catalog-backed self-loop tests fail, so their deletions ride in this step: `TestPlaceEntries` case "self-loop" and `TestFiledPlaceLinks`' `loop` (T-9's and T-10's deletions; the rest of T-9 stays in STEP-6). The Evidence guard also drops 223 accidental self-loops in `TestWalkEvidenceGraphEdgeCap`'s fixture, so T-11 rides in this step too.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/graphcache/... ./core/database/conclusionsummaries/... ./core/database/promotealign/...` passes.

**STEP-2 — Test the Source bridge's equal-ends refusal**
Files: `core/database/connect/connect_test.go`.
Do: add T-3.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/connect/ -run TestCreateCitedBridge` passes.

**STEP-3 — `graphalign` reads links through `From`**
Files: `core/graphalign/types.go`, `core/graphalign/align.go`, `core/graphalign/align_test.go`, `core/graphalign/invariants_test.go`. Skill: `add-match-rule`.
Do: D-3 (`Canon.View`, `newState`, `corresponding`), D-5, and the `graphalign` part of D-7 (T-7, T-8).
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/graphalign/... ./core/database/promotealign/...` passes with no golden changed.

**STEP-4 — Record links file each link under both ends**
Files: `core/recordlinks/recordlinks.go`.
Do: D-3's `NewGraph` change.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/recordlinks/...` passes.

**STEP-5 — Delete `Edge.Readings`, `Edge.Ends` and the equal-ends check**
Files: `core/kinship/kinship.go`, `core/kinship/kinship_test.go`, `core/kinship/families_test.go`, `core/database/canonlinks/reader_test.go`. Skill: `add-match-rule`.
Do: D-3's deletions (with them the doc lines `kinship.go` 64–67 and 79–80, and the now unused `iter` import), D-4 (doc lines 354 and 369), T-6, T-12 and T-13.
Check: `rg -n "\.Readings\(|\.Ends\(\)" core` finds nothing; `CGO_ENABLED=1 go test -tags fts5 ./core/kinship/... ./core/database/canonlinks/... ./core/database/evidencelayer/...` passes.

**STEP-6 — Place pages follow only their parts**
Files: `core/database/conclusionsummaries/placeentries.go`, `core/database/conclusionsummaries/placeentries_test.go`.
Do: D-6 (the comment at `placeentries.go` 218–220, the doc sentence at 325, and the now unused `bytes` import) and the rest of T-9: `pageReads` and its comment at `placeentries_test.go` 496–499.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/conclusionsummaries/...` passes; `rg -n "selfOnly|followHop|dedupePlaceLinks" core` finds nothing.

**STEP-7 — Docs**
Files: `docs/conclusion-layer-data-model.md`, `docs/promote-graph-alignment.md` (D-9), `docs/deployment-plan/spike-16/completed.md`, `docs/deployment-plan/spike-16/deployment-plan.md` (map row), this plan (status, Landed note).
Do: per the Definition of done; run search 1 and search 2 (§10) and compare with AC-4.1 and AC-4.2.
Check: `scripts/check-pr.sh` prints `check-pr: PASS`.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/graphcache/graph_test.go` `TestLinkFromARecordToItselfIsNotRead` *(new)* | `graphcachetest.OpenCatalog`, `NewCanon`; places `loop`, `town`, `city`; `k.PartOf(loop, loop)`, `k.PartOf(town, city)`; `k.Commit(loop, town, city)`; `g := c.Graph(); g.Drop()`. Subtests: "a self-loop is not read" → `g.Node(loop).Links` empty; "a link between two places is read" → `g.Node(town).Links` has one link with `Neighbor` = `city`; "NodesOnBridges" → `g.NodesOnBridges([][]byte{loop}, "place_relationship")[string(loop)].Links` empty; "Verify agrees" → `g.Verify()` nil | AC-1.1, AC-1.2, AC-1.3, D-1, D-2 |
| T-2 | Go | `core/database/graphcache/evidence_graph_walk_test.go` `TestWalkEvidenceGraphEdges`, new rows | Setup goes after the "A to-end on another Source" `UPDATE` and before `g := f.C.Graph()`, so `eg` is built after it. In the fixture: `f.name["york-hull"] = f.PlaceRel(f.Source, f.Artifact, york, hull, "part_of")`; `f.name["york-york"] = f.PlaceRel(f.Source, f.Artifact, york, hull, "part_of")`, then `f.exec("UPDATE observations SET value_subject_id = ? WHERE subject_id = ? AND property_id = ?", york.ID, f.name["york-york"].ID, f.Prop("to").ID)`. Rows use names, as the table does (`from: []string{"york"}`, `want: [][3]string{…}`). Row "a link from a place to itself is not walked": `hops.ParentsOfPlace` from `york` → `{"york", "york-hull", "hull"}` only. Row "a self-loop has no far end": `hops.PartsOfPlace` from `york` → no edge. Existing rows unchanged | AC-2.1, AC-2.2, D-1 |
| T-3 | Go | `core/database/connect/connect_test.go` `TestCreateCitedBridge` subtest "equal ends" *(new)*, placed after "person person relationship" | `s := mustSeed(t)`; `before := countBridges(t, s.c, "relationship")`; `writes.Call` of `CreateCitedBridge` with the "person person relationship" input, `ToSubjectID: s.person.ID` and `{PropertyID: s.related.ID, ValueSubjectID: s.person.ID}` (both ends one person; `BridgeTypeKey: "relationship"`, `personProp`, `relType`/`relTerm` and the Citation as in that subtest) → `errors.Is(err, ErrInvalid)` and `countBridges(t, s.c, "relationship") == before`. Person-to-person is a `relationship` rule (`subjectvocab.Connect`), so no later check refuses this input: deleting `connect.go` line 72 makes the subtest fail | AC-3.1 |
| T-4 | Go | `core/graphalign/align_test.go` goldens, `core/graphalign/invariants_test.go` `TestAlignInvariants`, `core/database/promotealign` `TestProposeReportsEachConnection` | Unchanged expected values | AC-4.3, D-3 |
| T-5 | Go | `core/recordlinks/*_test.go` | Unchanged | AC-4.3, D-3 |
| T-6 | Go | `core/kinship/kinship_test.go` | `TestEdgeEnds`, `TestEdgeReadings` deleted; `TestParentStep` row "self link" deleted; `TestDeriveInvariants` draws distinct `rel` ends (D-4) and keeps its "joins a Subject to itself" assertion | D-3, D-4, D-8 |
| T-7 | Go | `core/graphalign/align_test.go` `TestCanonView` | Row "a link from a handle to itself is listed once" deleted; subtest "readings of the stored links" reads `l.From(at)`: York → `(Ontario, sig.a)`, Ontario → `(York, sig.b)`; the self-loop assertion deleted | D-3, D-5, D-7 |
| T-8 | Go | `core/graphalign/invariants_test.go` | `placePartOfItself`, `TestPlacePartOfItselfPlaces` and the `TestAlignInvariants` row "a place part of itself on both sides" deleted | D-7 |
| T-9 | Go | `core/database/conclusionsummaries/placeentries_test.go` `TestPlaceEntries`, `TestPlaceEntryInputsMatchReads` | Case "self-loop" deleted; `pageReads(id)` = `reads(id, hops.PartsOfPlace)`; page inputs of town, city, region and unknown match it | D-6, D-7 |
| T-10 | Go | `core/database/conclusionsummaries/placeentries_test.go` `TestFiledPlaceLinks` | `loop`, `k.PartOf(loop, loop)` and row "a place part of itself" deleted; other rows unchanged | D-6, D-7 |
| T-11 | Go | `core/database/graphcache/evidence_graph_walk_test.go` `TestWalkEvidenceGraphEdgeCap` *(amended 2026-11-14, ship round 0)* | The from-Subjects keep `id(i + 1)`; the to-Subjects (their `EvidenceSubject` and their `event` observation) take `id(1000 + i + 1)`, so no pair has one Subject at both ends. Expected values unchanged: under the cap `223*224` edges, over the cap none | D-1 |
| T-12 | Go | `core/database/canonlinks/reader_test.go` `TestRelationshipsOptionsSiblings` "AC-1.9" *(amended 2026-11-14, ship round 0)* | Last case kept: `w.sibling("BB", bea, bea)` then `check(t, read(w, bea))` with no wanted entry (STEP-1's canon guard seen through `Relationships`); the earlier cases unchanged | D-1 |
| T-13 | Go | `core/kinship/families_test.go` `TestKinOf` *(amended 2026-11-14, ship round 0)* | Subtest "a link to self" deleted; other subtests unchanged | D-4 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `TestPlaceEntryInputsMatchReads` (page inputs), the `graphalign` goldens (adjacency order), `TestDeriveInvariants` (its random stream changes with D-4).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left — none
- [ ] Sweep: `rg -n "Edge.Readings|Edge.Ends|\.Readings\(|\.Ends\(\)|followHop|selfOnly" .agents .cursor/rules docs/*.md core` has no hit, and search 1 (§10) matches AC-4.1; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated — none
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New — no UI
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated) — not gated
- [ ] Domain doc updated if a rule in docs/*.md changed: docs/conclusion-layer-data-model.md §2.7 and docs/promote-graph-alignment.md line 198 (D-9)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

None in the app — no view the app can reach changes (§6 Reach). The reviewer runs the two searches and reads their output against AC-4.1 and AC-4.2, then runs the guard tests.

Search 1 (AC-4.1):

```bash
rg -n -i "self-loop|selfOnly|to itself|part of itself" core
```

Search 2 (AC-4.2):

```bash
rg -n "\.Readings\(|\.Ends\(\)|selfOnly|followHop" core
```

Guard tests:

```bash
CGO_ENABLED=1 go test -tags fts5 ./core/database/graphcache/ -run 'TestLinkFromARecordToItselfIsNotRead|TestWalkEvidenceGraphEdges' -v
```

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A golden or invariant moves because the adjacency order changes | D-3 keeps `Ends`' `A`, `B` order and `Readings`' single reading for two different ends; STEP-3's check runs the goldens before anything is deleted |
| A test fixture outside the ones in §4 builds a self-loop and starts failing | STEP-5's and STEP-6's `rg` checks; Stop condition below |
| `TestDeriveInvariants`' new random stream finds a real invariant break | The invariant is unchanged; a failure is a real `kinship` bug — Stop condition below |

**Stop and report if:**

- A test not named in §4 or §8 builds a link with equal ends (`A: x, B: x`, `PartOf(x, x)`, `Link(…, x, x)`) and fails after STEP-1 or STEP-5.
- A `graphalign` golden or `TestAlignInvariants` row changes its expected value in STEP-3.
- `TestDeriveInvariants` fails after D-4 with an implied link whose two ends are one person.
- A place entry, page or succession test changes its expected links after `dedupePlaceLinks` goes (D-6 assumes a hop's links are already unique).
- `Verify` reports a link mismatch in any test after STEP-1 (D-2 assumes `Verify` reads through the guard).
- The AC-4.1 search finds a hit not in its list.
- `graphcachetest.Canon.PartOf(loop, loop)` or `k.Commit` fails in T-1 (`Canon.Link` writes one Observation per endpoint property, `from` and `to`, so it is expected to succeed).

## 12. Open questions

None.

## 13. PR

**Title:** S16-36 — A link from a record to itself is refused where links are read
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-36-refuse-self-loops.md`.
