# S16-21 — Promote's alignment reads a canon view and the place entries

**Status:** Landed in [#836](https://github.com/Jake-Robins-Studios/provenencia/pull/836) (2026-11-14)
**Spike / slice:** Spike 16 · Slice 2d — Promote
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: an engine refactor; every Promote row, connection subrow and footer count reads as today)
**Board:** —
**Depends on:** S16-18 (landed [#817](https://github.com/Jake-Robins-Studios/provenencia/pull/817))
**Blocks:** S16-22 (serves the `CanonView` from the session graph and removes `loadCanon`'s walk)
**Branch:** `s16-21-canon-view-place-links`
**Version bump:** none — no change a researcher can see, and no wire or catalog change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`use-catalog-session`](../../../../.agents/skills/use-catalog-session/SKILL.md) (the graph cache, its registry and Verify), [`add-match-rule`](../../../../.agents/skills/add-match-rule/SKILL.md) (the layer package `core/graphalign` and the `core/kinship` types it reads)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table-driven tests), `.cursor/rules/catalog-queries.mdc` (a derived cache registers a typed handle from `init()`, reads only through `Get` / `GetMany` / `Peek`, adds its row to `docs/catalog-caches.md`, its fill to `BenchmarkCacheSizes`), `.cursor/rules/match-rules.mdc` (`core/graphalign` and `core/connectrules` stay pure: no catalog I/O)
**Context:** [design § Promote](../cache-architecture.md#promote) ("Neighbourhoods instead of the whole canon"), [`docs/catalog-caches.md`](../../../catalog-caches.md), [`promote-graph-alignment.md`](../../../promote-graph-alignment.md) §5, §7 and the filing rule (line 199), [S16-18 plan](S16-18-place-entries.md) (its **Landed** note, D-1's round 1 split, **Next adds**), [S16-20 plan](S16-20-match-index-apply.md) (its Out row on the event-type lookup), S14-22 plan D-1 and D-7 (in git history since Spike 14 closed: `git show baa25e76a^:docs/deployment-plan/spike-14/prs/S14-22-promote-wire-says-what-go-decided.md`), working rules: "The point of this batch is simpler code", "Cache entities and results per key; compose answers", "One cache registry, two ways to fill", "Every cache names the signal that updates it, and updates exactly", "Apply states its fan-out", "Orders are defined and results do not move", "Memory is budgeted", "Measure growth"
**Planned:** 2026-11-14 against `main` @ `ba2d35a`
**Review:** [`S16-21-canon-view-place-links.review.md`](S16-21-canon-view-place-links.review.md) — Fits with changes / Ready with changes, two rounds; no open blocker

**Landed.** Differences from the plan: a link at a place drops both its page entry and its succession entry, because an input key names a bridge end and not a term (the predecessor end a succession entry follows is the whole end a page follows), so `TestPlaceEntriesFollowLinkMoves` and the Scale line "a part filed under a hub drops the hub's page entry, not its succession entry" read the other way; the page's inputs also hold the place's `from` end key (its self `part_of` read), so `TestPlaceEntryInputsMatchReads` compares the page as a set; `rg "canon\.Edges\)" core` still hits `invariants_test.go` (`slices.Clone(canon.Edges)`, unrelated).

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

Promote's alignment reads the canonical graph through one small interface, `graphalign.CanonView` (a handle's profile, the links at a handle, a Subject's shortlisted candidates), served for now by today's `Canon` through an adapter. Its links are `kinship.Link`s, the type the Source side and every other link reader already use, so `graphalign.CanonEdge` goes. The proposal's connection check stops reading the canon's edges: a place link's loop check reads the filed `part_of` links from the place entries (S16-18) and the filed `succeeded_by` links from a new place-succession entry, one level at a time, only as far as the loop can reach. Nothing a researcher sees changes.

**Why now.** S16-22 replaces `loadCanon`'s walk of the whole component with a view that serves one handle's neighbourhood at a time (bar 10). Two things stand in its way: `Align` reads the canon as two flat lists and builds its own adjacency from them, and `Connections`' loop check reads every filed link from that walk (S14-22 D-7: "the canon already holds every link the loop check needs"). This PR moves both onto reads S16-22 can serve, while the walk still runs, so the goldens prove the move changes no answer. It absorbs S16-33 (map, 2026-11-08).

**What stays.** Every row, score, band, alternative, move and connection outcome of every proposal, in today's order (`TestAlignInvariants`, the goldens in `core/graphalign/align_test.go`, `TestProposeReportsEachConnection`). `loadCanon`'s walk, its `kinship.LinkSet` merge and `PlaceImplied` (S16-22 removes them). The filer's own loop check in `core/database/identityclaims/bridgefile.go` (`filedLinks`, which reads its own transaction). The place chain entries (`conclusionsummaries.places`), their inputs and every summary row's recorded inputs. Promote's budgets (`TestLargeSourceBudgets`, `TestProposeWarmIssuesNoQuery`, `TestProposeQueryCountStaysFlatWhenWarm`).

## 2. User stories

**US-1.** As a researcher, when a Source records a place link that would close a loop with places already in my tree, the Promote page still says "Not promoted · these places would form a loop", and a link that does not close one still promotes, so that the page says what Done does.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Tree: York `part_of` Ontario (filed). Source B records Ontario `part_of` York, both ends on the tree's records | The connection's outcome is `cycle`; Done files nothing (`TestProposeReportsEachConnection` "a loop with a filed link is refused", unchanged) |
| AC-1.2 | The same tree; Source B records Ontario `succeeded_by` York | The connection files: each term is checked apart (`TestProposeReportsEachConnection` "another term over the same places files", unchanged) |
| AC-1.3 | Tree: Toronto `part_of` York `part_of` Ontario `part_of` Canada (filed). Source B records Canada `part_of` Toronto, both ends on the tree's records | `cycle`: the check reaches Canada from Toronto through three filed links read from the place entries |
| AC-1.4 | Tree: Upper Canada `succeeded_by` Canada West `succeeded_by` Ontario (filed). Source B records Ontario `succeeded_by` Upper Canada | `cycle`, read from the succession entries |
| AC-1.5 | City has a part (Hill `part_of` City) whose link has an unreadable start date, and a `succeeded_by` link | Reading City's successors returns no error: the succession read decodes no part link of City (T-7, through `FiledPlaceLinks`, the reader `Propose` uses) |

**US-2.** As the engine, `Align` reads the canonical graph through `CanonView` and `Connections` reads filed links through a reader, so that S16-22 can serve a handle's neighbourhood without walking the catalog.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Every Align test, golden and invariant, each passing `Canon{…}.View()` | Each `Proposal` equals today's (`go test ./core/graphalign/...` passes with the assertions unchanged) |
| AC-2.2 | `Canon{Edges: [York→Ontario part_of, X→X part_of]}.View()` | `Links(York)` and `Links(Ontario)` = the one stored link; `Readings(York)` yields (Ontario, `from` key), `Readings(Ontario)` yields (York, `to` key); `Links(X)` = the one self-loop, whose `Readings(X)` yield the `from` key, then the `to` key; `Handle` of an id the canon does not hold is nil |
| AC-2.3 | A page of 200 place bridges between New records and one between two handles, under a reader that counts its calls | The reader is called only for the handles the loop check reaches from that one bridge's `to` end, one call per level, each handle once |
| AC-2.4 | A proposal on a graph with a place connection between two handles | `graphalign.Connections` takes no canon edge (it has no parameter for one); after the proposal, `g.KeyCounts()["conclusionsummaries.places"]` holds the reached places |
| AC-2.5 | `rg -n "CanonEdge|canonLinks|canonAdj" core .agents docs/*.md` | No hit |

## 3. Scope

| In | Covered by |
| --- | --- |
| `graphalign.CanonView` *(new)*; `Align`, `run`, `newState`, `corresponding`, `place`, `segments`, `seed`, `anchor`, `rescore` and the rows read the canon through it | STEP-4, AC-2.1 |
| `graphalign.Canon.Edges` becomes `[]kinship.Link`; `CanonEdge` goes; `Canon.View()` *(new)* is the adapter tests and today's loader use | STEP-4, STEP-6, AC-2.2, AC-2.5 |
| `connectrules.Links` reads filed links on demand, a level at a time; `ClosesCycle` returns an error; `connectrules.Filed` holds a pass's sets for the filer and the proposal | STEP-1, AC-2.3 |
| `kinship.Edge.Readings` *(new)* | STEP-4, AC-2.2 |
| `graphalign.Connections` reads filed links through `graphalign.FiledLinks` *(new)* instead of canon edges; `canonLinks` goes | STEP-5, AC-2.3, AC-2.4 |
| Place succession links move from the place page entry to their own keyed entry `conclusionsummaries.placeSuccession` *(new)*; the place page reads both | STEP-2, AC-1.5 |
| `conclusionsummaries.FiledPlaceLinks` *(new)*: the filed `part_of` (chain entries) and `succeeded_by` (succession entries) links of places | STEP-3, AC-1.3, AC-1.4 |
| `promotealign.Propose` passes `canon.View()` to `Align` and a place-link reader to `Connections`; `loadCanon` builds `kinship.Link`s | STEP-6, AC-1.1 – AC-1.5, AC-2.4 |
| Docs: `add-match-rule` line 33, `promote-graph-alignment.md` (`Align` signature, the inputs table, §5 `Canon.Candidates`, the filing rule), `docs/catalog-caches.md` | STEP-8 |

| Out | Home |
| --- | --- |
| A session-graph `CanonView` from the match index and the kinship pivots; removing `loadCanon`'s walk, its `LinkSet` and `PlaceImplied` | S16-22 |
| `canonlinks` owning the event-type property lookup that `newDeriver` and `loadCanon` each make (S16-20 Out row): `loadCanon`'s `EdgeOf` call goes with the walk in S16-22, leaving one | S16-22 |
| The bridge filer reading filed links from the place entries (`identityclaims.filedLinks` reads its own transaction) | Not planned (map: "must read its own transaction") |
| A two-term bridge filed mid-Done missing from an already-opened set for its other term | `structural-debt.md` (retired 2026-11-17; split into topic idea files) (the S14-22 row, kept without its link-key half) |
| Folding `graphalign`'s private `adjLink` onto `kinship.Link` for the layer side | Not planned: `adjLink` is one end's view, used only inside `align.go` |
| `canonlinks.kinship` declaring `Inputs` instead of `deps` | `structural-debt.md` (retired 2026-11-17; split into topic idea files) (S16-18 MNT-1 row) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Canon types | `core/graphalign/types.go` `CanonEdge`, `Canon{Handles, Edges, Candidates}` | `CanonEdge{From, To, KeyFrom, KeyTo, kinship.Recording}` is a second spelling of `kinship.Link` (`Edge{A, B, KeyA, KeyB, Associations}` + `Recording`, `core/kinship/links.go`) |
| Align state | `core/graphalign/align.go` `Align`, `run`, `state`, `newState` | `newState` copies `canon.Handles` into `st.handles` and turns `canon.Edges` into `st.canonAdj` (per handle, in edge order, From's end first: `adjLink{neighbor: To, key: KeyFrom}` on From, `adjLink{neighbor: From, key: KeyTo}` on To; a self-loop gets both in its one list); a fixed pair whose handle is absent from `st.handles` is dropped |
| Align readers | `align.go` `anchor`, `seed` (`st.canon.Candidates[sk]`), `rescore`, `corresponding` (`st.canonAdj[string(hid)]`), `place`, `segments`, `supports`; `rows.go` `HandleRef = st.handles[...].Ref` | Every read is a map lookup on `st.handles` or `st.canonAdj` |
| Connections | `core/graphalign/connections.go` `Connections(bridges, ends, canon []CanonEdge)`, `canonLinks`, `linkKey`, `endValue` | `canonLinks` scans every canon edge once and groups the registered bridge types' links by type and term as `connectrules.Link{From: "h:"+…, To: …}`, oriented from the rule's first endpoint; `filed` builds `connectrules.NewLinks(canonByKey[key])` once per type and term; a filed decision `Add`s its link |
| Filing rule | `core/connectrules/filing.go` `Links`, `NewLinks`, `Add`, `ClosesCycle(from, to) bool`, `Decide(b, terms, ends, filed func() (*Links, error))` | `Links` holds a full adjacency; `ClosesCycle` is a BFS from `to` looking for `from`; `Decide` calls `filed` only for an acyclic term (`place_relationship`'s `part_of`, `succeeded_by`) |
| Filer | `core/database/identityclaims/bridgefile.go` `fileBridge` (`connectrules.NewLinks(filed)`), `filedLinks(tx, rule, termKey)` | One SQL read of every filed link of the term; calls `NewLinks` and `Add`, never `ClosesCycle` |
| Loader | `core/database/promotealign/canon.go` `loadCanon` | Walks the component from the seeds, merges recorded links in a `kinship.LinkSet`, then copies each `kinship.Link` field by field into a `CanonEdge`; `PlaceImplied` merges implied links into `edges[at].Recording` or appends a `CanonEdge` |
| Propose | `core/database/promotealign/promotealign.go` `Propose` | `graphalign.Align(layer, canon, anchors, cfg)`, then `graphalign.Connections(pageBridges(…), pageEnds(…), canon.Edges)` |
| Place chain entry | `core/database/conclusionsummaries/placeentries.go` `placeEntries`, `placeEntry{found, shell, period, partFrom, inputs}`, `placeEntriesOf`, `fillPlaceEntries`, `followPlaces`, `orientPlaceLink`, `checkPlaceEntry` | `partFrom` is each filed `part_of` link where the place is the part, oriented part → whole, with its association's decoded dates; a self-loop is in it |
| Place page entry | `placeentries.go` `placePages`, `placePage{partTo, succFrom, succTo, inputs}`, `placePagesOf`, `fillPlacePages` (hops `PartsOfPlace`, `SuccessorsOfPlace`, `PredecessorsOfPlace`, `ParentsOfPlace` self only), `checkPlacePage` | One fill reads every part link of the place with its dates and both succession hops; filled only by `placeStep` |
| Place step | `core/database/conclusionsummaries/compose.go` `placeStep`; `placechains.go` `placeGraph{places, pages}`, `ImmediateParts`, `Successors`, `Predecessors`, `succNeighbors`, `AttachPlaceRelationships` | `succNeighbors` reads `g.pages[id].succFrom` / `succTo` |
| Cache doc | `docs/catalog-caches.md` rows `conclusionsummaries.places`, `conclusionsummaries.placePages`; `core/catalogsession/cache_doc_test.go` `TestCacheDocListsEveryEntry` | Every registered entry has a row |
| Tests | `core/graphalign/align_test.go` (`edge`, `canonOf`, `withCandidates`, `alignWith`, two direct `graphalign.Align` calls at lines 2105 and 2132), `invariants_test.go` `TestAlignInvariants`, `export_test.go` `NominatedForTest`, `connections_test.go` `TestConnections`, `TestConnectionsGrowsWithThePageNotPageTimesCanon`; `core/connectrules/filing_test.go` `TestLinksClosesCycle`, `TestDecide`; `core/database/conclusionsummaries/placeentries_test.go` `TestPlaceEntries` ("bad succession date", "chain fills no page"), `TestPlaceEntriesFollowLinkMoves`, `TestPlaceEntryInputsMatchReads`; `export_test.go` `PlacePageForTest`, `FillPlacePagesForTest`; `core/database/promotealign/promotealign_test.go` `TestProposeReportsEachConnection`, `TestProposePlacePartOfChain`, `TestProposeQueryCountStaysFlatWhenWarm`; `memo_test.go` `TestProposeWarmIssuesNoQuery`; `perf_test.go` `TestLargeSourceBudgets`; `bench_test.go` `BenchmarkCacheSizes` (`placePages` measure), `BenchmarkLargeSourcePropose` | |

**Precedent.**
- [#827](https://github.com/Jake-Robins-Studios/provenencia/pull/827) (S16-20) folded `graphalign.Handle` onto `subjectcompare.Subject`: copy its shape for `CanonEdge` → `kinship.Link` (the type goes, every reader uses the shared one, tests change only their literals).
- [#817](https://github.com/Jake-Robins-Studios/provenencia/pull/817) (S16-18), round 1 fix F-1, split the chain entry from the page entry so a read takes only the links it needs (ship log `S16-18-place-entries.ship.md`, "Fix plan 1"): copy it for the succession entry (its registration, fill through `followPlaces`, `Inputs` from the followed links, `Check` by rebuild, test hooks, `BenchmarkCacheSizes` measure, cache-doc row).
- S14-22 D-1 made `Decide`'s `filed` a callback "to keep the filer's SQL read lazy": the on-demand set extends the same laziness to each record.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `core/graphalign/types.go` gains `type CanonView interface` *(new)* with three methods. `Handle(id []byte) *Handle`: the handle's profile, nil when the view does not hold it. `Links(id []byte) []kinship.Link`: every link with `id` at an end, as stored (not turned to face `id`), in the view's link order; a link from a handle to itself is listed once. A reader reads a link from `id` through `kinship.Edge.Readings` (D-14). `Candidates(subjectID []byte) [][]byte`: the Subject's shortlisted candidate handle ids, in `Candidates` order. Results are the view's own and read-only | The three things `Align` reads of the catalog today, named for what S16-22 serves (profile from the match index, links from the pivots, candidates from their entry); unturned links are what `canonlinks.Reader.Relationships` returns (merged through `kinship.LinkSet`), so S16-22 passes them as they are (review M-1) | A method per field of today's `Canon` (`Handles()`, `Edges()`) — S16-22 cannot serve the whole canon; links turned to face `id`, a self-loop listed twice (round 0 draft) — a turning rule every view repeats beside `Edge.From` (review M-1) |
| D-2 | `Align(layer Layer, canon CanonView, fixed []Fixed, cfg Config) Proposal`; `run` and `newState` take the same `CanonView`; `NominatedForTest(layer, canon CanonView, …)`. No second entry point | One way in; S16-22 passes its own view | Keeping `Align(…, Canon, …)` beside an `AlignView` — two entry points for one procedure |
| D-3 | `Canon` stays as the loader's and the tests' value: `Canon{Handles []Handle; Edges []kinship.Link; Candidates map[string][][]byte}`. `CanonEdge` is deleted. `func (c Canon) View() CanonView` *(new)* builds an unexported `canonIndex` *(new)* once: handles by id (`&c.Handles[i]`, last one wins as today), links per handle in `Edges` order (each edge on `A`'s list and, when `B` differs from `A`, on `B`'s list), and `Candidates[string(subjectID)]`. Each `Edges` entry's `Associations` are ignored | The adapter the map names ("Tests keep `Canon{Handles, Edges}` through an adapter"); with D-14's readings (`A`'s end first) each handle reads its links in the order `canonAdj` held them today, a self-loop's two readings included, so the goldens hold | A `*Canon` with lazy maps implementing the interface — mutable state on a value tests copy; converting the 91 test literals to a fake view — churn with no reader gain |
| D-4 | `state` loses `handles` and `canonAdj`; `canon` becomes `CanonView`. Every `st.handles[string(x)]` becomes `st.canon.Handle(x)` (nil checks unchanged). `corresponding(link, hid)` loops `st.canon.Links(hid)` and, for each `other, key := range l.Readings(hid)`, builds the candidate `adjLink{neighbor: other, key: key, Recording: l.Recording}` before `segmentcompare.Corresponds` and `kinship.CountedOnce`. `seed` reads `st.canon.Candidates(s.ID)`. `newState`'s fixed check becomes `st.canon.Handle(f.HandleID) == nil`. `adjLink` stays for the layer side and `corresponding`'s output | Smallest change that leaves every map read a view call; `corresponding` already builds its `out` slice, so no new allocation | Returning `[]adjLink` from the view — exports a private type into S16-22's contract |
| D-5 | `loadCanon` builds `edges := slices.Clone(set.Links())` (type `[]kinship.Link`); an implied link that merges does `edges[at].Recording.Merge(rec)` as today; one that does not is appended as `kinship.Link{Edge: kinship.Edge{A: bytes.Clone(imp.A), B: bytes.Clone(imp.B), KeyA: imp.KeyA, KeyB: imp.KeyB}, Recording: rec.Clone()}`. `Propose` calls `graphalign.Align(layer, canon.View(), anchors, cfg)` | The field-by-field copy goes; ends and keys are the same values in the same order, and the merged `Recording` shares the set's `Shapes` exactly as today's copy did | Building the view inside `loadCanon` — S16-22 replaces `loadCanon` and keeps `Propose`'s call |
| D-6 | `connectrules` gains `func NewLinksReading(read func(records []string) (map[string][]string, error)) *Links` *(new)*: a set whose filed links are read on demand. `Links` gains the `read` func and a `readDone map[string]bool`. `ClosesCycle(from, to string) (bool, error)` walks level by level from `to`: for each level it first tests whether `from` is in the level (true ends the walk before the level is read), then calls `read` once with the level's records it has not read yet, sorted, adds the result to the adjacency (after any links `Add` put there), marks them read, then expands the level; it returns true as soon as `from` is reached, and an error from `read` as is. `NewLinks(links)` keeps a set with no reader; on it `ClosesCycle` never errors. `Decide` returns the error from `ClosesCycle`. `connectrules` also gains `type Filed struct` *(new)*, the filed-link sets of one filing pass: `func NewFiled(open func(b Bridge, term vocabkey.BridgeTerm) (*Links, error)) *Filed` *(new)* and `func (f *Filed) Decide(b Bridge, terms []vocabkey.BridgeTerm, ends [][]Value) (Result, error)` *(new)*, which keys a set by `b.BridgeTypeKey + "|" + string(Term(terms))`, calls `open` the first time `Decide` asks for that key, and `Add`s `Result.Link` after a `files` decision. Both callers use it: the filer's `fileBridge` with `open` returning `NewLinks(filedLinks(tx, rule, term))` (its `p.links` map and `linkKey` go), and `graphalign.Connections` (D-7). The package `Decide` becomes unexported `decide`, the rule `Filed.Decide` calls, so `Filed.Decide` is the one entry point; `TestDecide` (package `connectrules`) calls `decide` | One loop rule in `connectrules`, now able to read only what it reaches; per level, so a chain of depth d costs d reads | A BFS in `graphalign` beside `ClosesCycle` — a second loop rule; each caller keeping its own map of sets (today's two copies, review M-2); one `read` call per record — a cold chain costs one fill per place instead of per level |
| D-7 | `graphalign` gains `type FiledLinks func(typeKey vocabkey.SubjectType, term vocabkey.BridgeTerm, handles [][]byte) (map[string][][]byte, error)` *(new)*: for each handle, the handles its filed links of that bridge type and term lead to, from the rule's first endpoint to its second. `Connections(bridges []PageBridge, ends map[string]EndTarget, filed FiledLinks) ([]Connection, error)`. It decides each bridge through one `connectrules.NewFiled(open)`, whose `open(rule, term)` returns `connectrules.NewLinksReading(read)` where `read` strips `"h:"` records to handle ids, calls `filed(typeKey, term, ids)` and maps the answer back to `"h:"` keys; a `"n:"` record reads no link (absent from the answer); a level with no `"h:"` record returns an empty map without calling `filed`. An error from `Decide` stops `Connections` and is returned. `canonLinks`, the `rules` lookup in it, `linkKey`, the `links` map and the `Add` after a filing go (`Filed` owns them) | The loop check reads the catalog's filed links, not the canon walk's; `graphalign` stays pure (a function in, no catalog import) | A method on `CanonView` — Connections is not part of `Align`, and S16-22's view serves no place links; passing the place entries' Go type — `graphalign` would import a database package |
| D-8 | `conclusionsummaries` gains `func FiledPlaceLinks(g *graphcache.Graph, term vocabkey.BridgeTerm, ids [][]byte) (map[string][][]byte, error)` *(new)* in `placeentries.go`; it gets `v` from `vocabulary(g)` as `checkPlaceEntry` does and returns its error: `vocabkey.TermPartOf` → each place's chain entry (`placeEntries.of`) `partFrom` links' `to`; `vocabkey.TermSucceededBy` → each place's succession entry (`placeSuccessions.of`, D-9) `succFrom` links' `to`; each list in link order, a repeated `to` kept once; a place with no entity row maps to no links; any other term is an error `conclusionsummaries: no filed place links of term %q`. A self-loop is returned as a link to itself | The package that owns the place entries owns their one exported reader (S16-18 **Next adds**); ids only, because the loop check reads no date | A reader in `promotealign` over unexported types — not reachable; returning `placeLink`s — exports dates no caller reads |
| D-9 | The place page entry splits: `placePage` keeps `partTo` and `inputs` (fill hops `PartsOfPlace` and `ParentsOfPlace` self only). A keyed entry `conclusionsummaries.placeSuccession` *(new)*, handle `placeSuccessions graphcache.Keyed[placeSuccession]` *(new)*, `placeSuccession{succFrom, succTo []placeLink; inputs []graphcache.InputKey}` *(new)*, registered through D-15's helper. `fillPlaceSuccessions(g, v, ids)` *(new)* follows `SuccessorsOfPlace` and `PredecessorsOfPlace` through `followPlaces`; `inputs` = `NodeKey(id)` plus `FollowKeys` of both hops over the followed links, through `UniqueInputKeys`; a place with no node gets `[NodeKey(id)]`. `placeSuccessions.of(g, v, ids)` reads it. `placeGraph` gains `succession map[string]placeSuccession`; `placeStep` reads it for its own id right after the page, before the early return on a missing page, and adds its links' ends to the neighbours; `succNeighbors` reads `g.succession[id]`. No summary row records a page or succession key (rows record only chain entries' inputs, S16-18 D-4), so no row's inputs change; the page entry's own `inputs` lose the two succession hops' keys, which move to the succession entry | Promote's `succeeded_by` check needs a place's successors, not its parts: reading the page would fill a 20,000-part hub's page on a proposal and fail it on one unreadable part date, the cost and the failure the user split the entry to avoid (S16-18 round 1, 2026-11-13) | Reading `placePages` — the hub fill and the shared failure above; adding successors to the chain entry — every summary row would record succession keys (S16-18 D-4) |
| D-10 | `promotealign/connections.go` gains `func placeLinks(g *graphcache.Graph) graphalign.FiledLinks` *(new)*: for `vocabkey.BridgePlaceRelationship` it returns `conclusionsummaries.FiledPlaceLinks(g, term, handles)`; any other type is an error `promotealign: no filed-link reader for bridge %q`. `Propose` calls `graphalign.Connections(pageBridges(…), pageEnds(…), placeLinks(c.Graph()))` and on error returns `graphalign.Proposal{}, 0, err`, as its other error returns do. `promotealign` imports `conclusionsummaries` in production | Only `place_relationship` has acyclic terms (`connectrules` `AcyclicTerms`); a new acyclic registration fails loudly instead of reading nothing. The import is already a transitive dependency (`go list -deps ./core/database/promotealign`), so no cycle; this answers S16-18 review M-8 | A reader in `canonlinks` — it owns kinship links, not place chains |
| D-11 | A `part_of` link whose association date cannot be read, on a place the loop check reaches, fails the proposal with that error, as it already fails that place's chain in `ListPlaces` and every summary through it. A `succeeded_by` link's bad date fails a proposal only when its loop check reaches that place on `succeeded_by` | The chain entry decodes dates; such a place is broken on every page already; data the app never writes | A dateless second read of the same links — a second cache of `part_of` links |
| D-12 | Test literals: `edge(…)` and `canonOf(…)` in `align_test.go` return `kinship.Link`; `alignWith`, the two direct `graphalign.Align` calls (lines 2105, 2132), the `NominatedForTest` call (line 2310, after `withCandidates`, so `withCandidates(…).View()`) and `TestAlignInvariants` pass `canon.View()`; the `Canon` literal in `invariants_test.go` uses `[]kinship.Link`; `connections_test.go` passes a fake `FiledLinks`. `TestConnectionsGrowsWithThePageNotPageTimesCanon` is replaced by T-5: there is no canon to read per bridge | Tests change only how they hand the canon in; assertions stay | A test-only `Align` overload taking `Canon` |
| D-14 | `core/kinship/kinship.go` gains `func (e Edge) Readings(id []byte) iter.Seq2[[]byte, vocabkey.BridgeKey]` *(new)*: yields `(B, KeyA)` when `A` is `id`, then `(A, KeyB)` when `B` is `id`; a link from `id` to itself yields both, `A`'s end first. `Edge.From` and its callers stay | One rule for reading a link from an end, in the package that owns links; the self-loop rule is tested once (review M-1) | Turning links in each view — see D-1 |
| D-16 | `newState`'s layer loop reads through the same rule: for each bridge, `b.Readings(b.A)` appends to `layerAdj[A]` and, when `B` differs from `A`, `b.Readings(b.B)` to `layerAdj[B]` (today's `b.From(end)` over `{A, B}` reads a layer self-loop's `KeyA` twice). For a link between two Subjects the readings and their order are today's. A layer self-loop (a Source place `part_of` itself) now reads both keys, as the canon side does | One end-reading rule in `graphalign`; no golden or invariant holds a layer self-loop (review M-7: searched `core/graphalign/*_test.go`, `core/database/promotealign/*_test.go`) | Leaving the layer on `From` beside `Readings` — two rules in one file that disagree on self-loops |
| D-15 | `placeentries.go` gains `type placeKeyed[T any] struct{ k graphcache.Keyed[T]; fill func(g *graphcache.Graph, v vocab, ids [][]byte) (map[string]T, error) }` *(new)*, `func registerPlaceKeyed[T any](name, noun string, fill func(*graphcache.Graph, vocab, [][]byte) (map[string]T, error), inputs func(T) []graphcache.InputKey) placeKeyed[T]` *(new)* (registers `Name`, `DerivedFrom` vocabulary, `Inputs`, `Check` by rebuild through `fill` and `reflect.DeepEqual` with the error `conclusionsummaries: stored <noun> %x does not match a fresh load`, `Cap: maxPlaceEntries`) and `func (p placeKeyed[T]) of(g, v, ids) (map[string]T, error)` *(new)* over `GetMany`. `placeEntries` (noun `place entry`), `placePages` (`place page`) and `placeSuccessions` (`place succession`) are declared through it, assigned in `init()` as today (`catalog-queries.mdc`); `placeEntriesOf`, `placePagesOf`, `checkPlaceEntry` and `checkPlacePage` go, their callers call `.of`; test hooks read `.k` | One declaration per place entry instead of three copies of registration, getter and check; the existing error strings are kept (review M-3) | A third hand copy (round 0 draft) |
| D-13 | Measurement: `BenchmarkLargeSourcePropose` and `BenchmarkProposeWarmCity` at base and head, three runs each, recorded in the ship log; `BenchmarkCacheSizes` gains a `placeSuccession` measure before `placePages` | Rule "Measure growth": the PR claims no speed, but the interface call sits in `Align`'s hot loop | — |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `graphalign.CanonView` *(new)* | interface | `graphalign.Canon` | `Canon` is two whole lists; S16-22 serves one handle at a time. `Canon` stays, as the adapter's input |
| `Canon.View`, `canonIndex` *(new)* | func, type | `newState`'s `canonAdj` loop | Moved, not copied: the loop leaves `newState` |
| `graphalign.FiledLinks` *(new)* | func type | `connectrules.Decide`'s `filed func() (*Links, error)` | That callback hands over a whole set; this one reads per handle and keeps `graphalign` free of catalog types |
| `connectrules.NewLinksReading` *(new)* | func | `connectrules.NewLinks` | Extends `Links` with an on-demand source; `NewLinks` stays the filer's eager set |
| `conclusionsummaries.FiledPlaceLinks` *(new)* | func | `placeEntriesOf`, `placePagesOf` (unexported) | The exported reader S16-18 named; it reads the entries, adds no cache |
| `conclusionsummaries.placeSuccession`, `placeSuccessions`, `fillPlaceSuccessions` *(new)* | keyed entry | `placePages` | Split out of `placePage` (D-9), declared through D-15 |
| `placeKeyed`, `registerPlaceKeyed` *(new)* | generic helper | `placeEntries` / `placePages` registrations, getters and checks | Replaces the two hand copies (D-15) |
| `connectrules.Filed`, `NewFiled`, `Filed.Decide` *(new)* | type, funcs | `graphalign.Connections`' `links` map; `identityclaims` `fileBridge`'s `p.links` | Replaces both copies (D-6) |
| `kinship.Edge.Readings` *(new)* | method | `kinship.Edge.From` | `From` returns one reading; a self-loop has two (D-14) |
| `PlaceSuccessionForTest`, `FillPlaceSuccessionsForTest` *(new)* | test hooks | `PlacePageForTest`, `FillPlacePagesForTest` | Same shape for the new entry |
| `promotealign.placeLinks` *(new)* | func | `canonlinks.Reader` | Kinship links, not filed place links |

Searched for: `CanonEdge`, `canonAdj`, `ClosesCycle`, `NewLinks`, `filedLinks`, `succFrom`, `placePagesOf`, `FiledLinks`, `CanonView`.

**Builds on.** `kinship.Link` (the one link type of the matching layers), the graph cache's keyed registry with declared `Inputs` (S16-18), `connectrules.Decide`'s lazy `filed` (S14-22 D-1), `followPlaces` and `orientPlaceLink`.
**Deletes.** `graphalign.CanonEdge`; the exported name `connectrules.Decide` (now `decide`, D-6); `graphalign.canonLinks`, `graphalign.linkKey` and `Connections`' `links` map; `identityclaims` `fileBridge`'s `p.links` map and its `linkKey`; `placeEntriesOf`, `placePagesOf`, `checkPlaceEntry`, `checkPlacePage` (D-15); `state.handles`, `state.canonAdj` and their build in `newState`; `loadCanon`'s field-by-field `CanonEdge` copy; `placePage.succFrom`, `placePage.succTo` and their hops in `fillPlacePages`; `placeGraph.succNeighbors`' read of `pages`; `TestConnectionsGrowsWithThePageNotPageTimesCanon`. `Connections`' `canon` parameter.
**Next adds.** S16-22 writes a session-graph type that implements `CanonView` (profiles from the match index, `Links` from the kinship pivots and the node, `Candidates` from the candidates entry) and passes it to `Align`; `Canon.View` then serves only tests. A later acyclic term on another bridge adds one case to `placeLinks` or its own reader.

### Reach

None — no new path into existing code. The loop check now reaches places through the entries instead of through the canon walk; the canon walk only held primary, unmerged handles, the entries hold every filed `part_of` / `succeeded_by` link, as the filer's SQL does. Checked: a place with no entity row reads no links (D-8).

### Scale

At the map's Scale (Batch 2: the large fixture at 4,000 and 16,000 persons; one place with 6,000 events; crafted: a 20,000-part hub):

- **Align.** Each `st.handles` / `st.canonAdj` map read becomes one interface call on `canonIndex` over the same maps; the adjacency is built once per proposal as today, and `Links` returns the stored slice. No new allocation per call. Measured with D-13; `TestLargeSourceBudgets` holds.
- **Connections.** Per proposal, per page connection whose term is acyclic and whose ends are both records: one `ClosesCycle`, which reads one level per call, only records not read yet in this `Connections` call. Real data: a chain of at most `summaryChainDepth` (8) levels; warm, the entries are held and the read issues no SQL (`TestProposeWarmIssuesNoQuery`). Cold: one `GetMany` fill per level, of the places on that level only, reading `place_relationship` links and their associations (S16-18's narrow load), never a city's location links. Today the canon walk loaded every node of the component instead.
- **Succession entry.** One per place whose page or succession is read; a write drops it only through its `Inputs` (its values, its succession links, a new succession link at it). A part filed under a hub drops the hub's page entry, not its succession entry.
- **Memory.** `placeSuccession` holds two short lists per read place; `BenchmarkCacheSizes` records it (D-13); the page entry shrinks by the same lists.

### Edges

- **Assumptions.** `ClosesCycle` is reachability: the order a level is read in changes no answer (T-3 cases "closing a chain" through a reader equal the eager set's). `Align`'s answer depends on each handle's link order: `canonIndex` builds it in `Canon.Edges` order, `A` end first, as `newState` did (T-1, AC-2.1). A self-loop is listed once and read twice, `A`'s end first (T-1, T-11).
- **Neighbors.** `part_of` and `succeeded_by` keep separate sets (one `Filed` key each; AC-1.2). A filed link reads part → whole whichever end the graph lists it from: `orientPlaceLink` orients by `FromEnd`, which S16-18's `TestPlaceEntries` holds; T-6 reads it through `FiledPlaceLinks`. A page's own earlier filed connection still blocks a later one (`Add` before the read: T-3 "an added link counts", T-4 "two page bridges loop").
- **Removed inputs.** A place deleted or merged since the proposal's last read: the entry is dropped by its `Inputs` (S16-18) and refilled; a deleted place reads no links. A link removed: its association's `NodeKey` is in the entry's inputs, so the next proposal reads it gone (T-6 "a removed link reads gone").
- **Real data.** No table or seed drives a new rule.
- **Untrusted size.** A crafted chain or fan of `part_of` links: the check walks every place reachable from `to`, unbounded, as the filer's check does (S14-22 D-7 rejected a bound: it would miss a long chain); each place is read once per `Connections` call; per level one `GetMany`. The entries' cap (65,536) evicts least recently used keys; `GetMany` returns every asked id even when it evicts, and the set keeps its own adjacency, so a walk past the cap still ends.

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/connectrules` | `func NewLinksReading(read func(records []string) (map[string][]string, error)) *Links` *(new)*; `func (s *Links) ClosesCycle(from, to string) (bool, error)` (was `bool`); `Decide` returns `ClosesCycle`'s error; `type Filed`, `NewFiled`, `(*Filed).Decide` *(new)* |
| `core/kinship` | `func (e Edge) Readings(id []byte) iter.Seq2[[]byte, vocabkey.BridgeKey]` *(new)* |
| `core/database/identityclaims` | `fileBridge` decides through `connectrules.Filed` |
| `core/graphalign` | `type CanonView interface { Handle(id []byte) *Handle; Links(id []byte) []kinship.Link; Candidates(subjectID []byte) [][]byte }` *(new)*; `Canon.Edges []kinship.Link`; `func (c Canon) View() CanonView` *(new)*; `CanonEdge` deleted; `func Align(layer Layer, canon CanonView, fixed []Fixed, cfg Config) Proposal`; `type FiledLinks func(typeKey vocabkey.SubjectType, term vocabkey.BridgeTerm, handles [][]byte) (map[string][][]byte, error)` *(new)*; `func Connections(bridges []PageBridge, ends map[string]EndTarget, filed FiledLinks) ([]Connection, error)` |
| `core/database/conclusionsummaries` | `func FiledPlaceLinks(g *graphcache.Graph, term vocabkey.BridgeTerm, ids [][]byte) (map[string][][]byte, error)` *(new)*; keyed entry `conclusionsummaries.placeSuccession` *(new)* (D-9) |
| `core/database/promotealign` | `placeLinks(g) graphalign.FiledLinks` *(new)*; `loadCanon` returns `Canon` with `[]kinship.Link`; `Propose` uses `canon.View()` and `placeLinks` |

Errors: `conclusionsummaries: no filed place links of term %q`; `promotealign: no filed-link reader for bridge %q`; a fill error (an association missing, a date that cannot be read) as `fillPlaceEntries` returns it today.

### FFI

None — the proposal's wire is unchanged.

### macOS

None — no Swift change.

### Strings

None — no copy changes.

## 7. Steps

**STEP-1 — The loop check reads filed links on demand**
Files: `core/connectrules/filing.go`, `core/connectrules/filing_test.go`, `core/database/identityclaims/bridgefile.go`.
Do: D-6. `Links` gains `read` and `readDone`; `NewLinksReading` *(new)*; `ClosesCycle` returns `(bool, error)` and walks level by level; `Decide` returns its error; `Filed` *(new)*; `Decide` becomes `decide`; `fileBridge` decides through `NewFiled` and loses `p.links` and its key. Add T-3.
Check: `go test ./core/connectrules/... ./core/database/identityclaims/...` passes (`CGO_ENABLED=1 go test -tags fts5` for the second).

**STEP-2 — Place succession gets its own entry**
Files: `core/database/conclusionsummaries/placeentries.go`, `compose.go` (`placeStep`), `placechains.go` (`placeGraph`, `newPlaceGraph`, `succNeighbors`), `export_test.go`, `placeentries_test.go`, `core/database/promotealign/bench_test.go` (`BenchmarkCacheSizes`), `docs/catalog-caches.md`. Skill: `use-catalog-session`.
Do: D-15 first (move `placeEntries` and `placePages` onto `registerPlaceKeyed`, tests green), then D-9 through it, as the round 1 split in the S16-18 ship log's F-1 did. Add `PlaceSuccessionForTest(g, id) (held bool, inputs []graphcache.InputKey)` and `FillPlaceSuccessionsForTest(g, ids...)` beside the page hooks. Update `TestPlaceEntryInputsMatchReads`: the page's inputs against a scope following `PartsOfPlace` and the self `part_of` link; the succession entry's against a scope following `SuccessorsOfPlace` and `PredecessorsOfPlace`, each with `in.Node` of every link's association. Add T-7. Add the `conclusionsummaries.placeSuccession` row to `docs/catalog-caches.md` (copy `placePages`' row; fill: the place's `place_relationship` links as predecessor and successor and their associations' values) and edit `placePages`' row to name only links as whole; its size column reads `measured in STEP-7` until STEP-7 fills it.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/conclusionsummaries/... ./core/catalogsession/... ./api/...` passes, and again with `PROVENENCIA_GRAPH_VERIFY=1`; `rg -n "page\.succ|pages\[.*\]\.succ" core/database/conclusionsummaries --glob '!*_test.go'` finds nothing.

**STEP-3 — One reader of filed place links**
Files: `core/database/conclusionsummaries/placeentries.go`, `placeentries_test.go`, `core/database/promotealign/bench_test.go`.
Do: D-8. Add T-6 and T-7's STEP-3 cases. Add a `placeSuccession` measure to `BenchmarkCacheSizes` before `placePages`: `FiledPlaceLinks(g, vocabkey.TermSucceededBy, ids)` over the listed places.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/conclusionsummaries/...` passes, and with `PROVENENCIA_GRAPH_VERIFY=1`.

**STEP-4 — Align reads a canon view**
Files: `core/kinship/kinship.go`, `kinship_test.go`, `core/graphalign/types.go`, `align.go`, `rows.go`, `export_test.go`, `align_test.go`, `invariants_test.go`, `connections_test.go` (its `CanonEdge` literals become `kinship.Link` literals; nothing else changes until STEP-5), `core/database/promotealign/canon.go`, `promotealign.go`. Skill: `add-match-rule`.
Do: D-14, then D-1 – D-5, D-12, D-16. Delete `CanonEdge`. `loadCanon` and `Propose` change only as D-5 says, so the tree builds; `Connections` still gets `canon.Edges` (now `[]kinship.Link`) until STEP-5, with `canonLinks` reading `e.A`, `e.B`, `e.KeyA` for one step. Fix the comment at `align_test.go:92` ("(Link.A, CanonEdge.From)"). Add T-1, T-11.
Check: `go test ./core/kinship/... ./core/graphalign/...` passes with no `graphalign` assertion changed (only canon construction and the `Align` argument); `CGO_ENABLED=1 go test -tags fts5 ./core/database/promotealign/...` passes.

**STEP-5 — Connections read filed links through a reader**
Files: `core/graphalign/connections.go`, `connections_test.go`, `core/database/promotealign/connections.go`, `promotealign.go`.
Do: D-7, D-10. Delete `canonLinks` and `TestConnectionsGrowsWithThePageNotPageTimesCanon`. Rewrite `TestConnections`' `canon` field as a `filed` map of type and term to links (York → Ontario `part_of`); drop the "stored the other way" canon case (orientation is the reader's job: T-6 covers it). Add T-4, T-5.
Check: `go test ./core/graphalign/... ./core/connectrules/...` and `CGO_ENABLED=1 go test -tags fts5 ./core/database/promotealign/... ./api/...` pass; `rg -n "canonLinks|CanonEdge|canon\.Edges\)" core` finds nothing.

**STEP-6 — Promote's loop tests through the entries**
Files: `core/database/promotealign/promotealign_test.go`.
Do: Add T-10. Add T-8 (AC-1.3, AC-1.4, AC-2.4) as subtests of `TestProposeReportsEachConnection`. Each builds its own tree the way `build` does: `f.Place` per place and `f.PlaceRel` per link on `f.source`, `f.promote` of every place (the tree), then on `f.NewSource` the Source-B places and the one closing link, fixed onto the tree's handles; it checks with `agree`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/promotealign/... -run 'TestProposeReportsEachConnection|TestProposePlace'` passes, and with `PROVENENCIA_GRAPH_VERIFY=1`.

**STEP-7 — Budgets and measurements**
Files: none changed unless a budget fails (then stop).
Do: D-13. Run `BenchmarkLargeSourcePropose`, `BenchmarkProposeWarmCity` and `BenchmarkCacheSizes` (`-benchtime 1x`, three runs) at `ba2d35a` (a `git worktree add ../base ba2d35a` checkout) and at head; record the medians in the ship log and `placeSuccession-B` in `docs/catalog-caches.md`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/promotealign/... -run 'TestLargeSourceBudgets|TestProposeWarmIssuesNoQuery|TestProposeQueryCountStaysFlatWhenWarm|TestProposeQueryCountDoesNotGrowWithTheLayer'` passes; `scripts/check-pr.sh` prints `check-pr: PASS`.

**STEP-8 — Docs**
Files: `.agents/skills/add-match-rule/SKILL.md` (line 33: "into `kinship.Link` and `CanonEdge`" → "into `kinship.Link`, which the canon reaches `Align` as through `graphalign.CanonView`"), `docs/promote-graph-alignment.md` (line 77 `Align` signature; line 83 the `canon` row names `CanonView`: a handle's profile, the links at it, each Subject's candidates, served today by `Canon.View()` over the walk; lines 105 and 154 `Canon.Candidates` → `CanonView.Candidates`; line 199 adds that the proposal's loop check reads the filed links from the place entries, as far as the loop reaches), `docs/catalog-caches.md` (STEP-2, STEP-7), `docs/ideas/structural-debt.md` (the S14-22 row loses "and `bridgefile.go` repeats `graphalign`'s link key. One keyed set in `connectrules` would serve both."), `docs/deployment-plan/spike-16/completed.md`, `deployment-plan.md` (map row), this plan (status, **Landed** note).
Do: per the Definition of done.
Check: links resolve; `python3 scripts/check-guidance-names.py` passes.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/graphalign/align_test.go` `TestCanonView` *(new)* | Table: (a) York → Ontario `part_of` → `Links(York)` and `Links(Ontario)` each the one stored link (`A` York, `B` Ontario); (b) X → X → `Links(X)` the one stored link; (c) three edges at one handle → its links in edge order; (d) `Handle(unknown)` nil, `Handle(York)` the York profile; (e) `Candidates(s)` = `Canon.Candidates[string(s)]` | AC-2.2, D-1, D-3 |
| T-2 | Go | `core/graphalign/align_test.go` (every test), `invariants_test.go` `TestAlignInvariants` | Unchanged assertions over `canon.View()` → pass | AC-2.1, D-2, D-4, D-12 |
| T-3 | Go | `core/connectrules/filing_test.go` `TestLinksClosesCycle` | Add a reader variant of each existing case (same answers); "reads a level at a time": chain a→b→c→d, `ClosesCycle("d","a")` → true, reader called with `[a]`, `[b]`, `[c]`; "reads each record once": a second `ClosesCycle` on the same set reads only new records; "an added link counts" with a reader; "a reader error": `read` returns `boom` → `(false, boom)`; `TestFiled` *(new)*: `open` is called once per type and term, a `files` decision's link is in the set for the next bridge, an `open` error is returned; `TestDecide` "loop check error": `filed` set whose reader fails → `Decide` returns the error | D-6, AC-2.3, M-2 |
| T-4 | Go | `core/graphalign/connections_test.go` `TestConnections` | Existing cases over a fake `FiledLinks` → same outcomes; "a succeeded_by loop" → `cycle`; "two page bridges loop" (both New) → first files, second `cycle`; "reader error" → `Connections` returns it; "reader is asked by type and term" → called with `place_relationship` and `part_of` | D-7, AC-1.1, AC-1.2 |
| T-5 | Go | `core/graphalign/connections_test.go` `TestConnectionsReadOnlyWhatTheLoopReaches` *(new)* | 200 New–New `part_of` bridges plus one between handles H1 → H2 over a reader holding H2 → H3 → H4 and 1,000 unrelated links; the reader is called with `[H2]`, `[H3]`, `[H4]` only | AC-2.3, D-7 |
| T-6 | Go | `core/database/conclusionsummaries/placeentries_test.go` `TestFiledPlaceLinks` *(new)* | Table on a fixture world: `part_of` of Town → [City]; of City → [Region]; self-loop X → [X]; `succeeded_by` of Upper Canada → [Canada West]; a place with no entity row → none; "a removed link reads gone" (remove Town → City, commit) → Town → none; unknown term → error | D-8, AC-1.3, AC-1.4 |
| T-7 | Go | `core/database/conclusionsummaries/placeentries_test.go` `TestPlaceEntries` | STEP-2 adds: "succession fills no page": `FillPlaceSuccessionsForTest(g, City)` holds City's succession entry and no page (`KeyCounts`); "bad part date leaves succession": Hill `part_of` City with a start date, Beta `succeeded_by` City with no date, `f.breakDates()`, `g.Drop()` → `FillPlaceSuccessionsForTest(g, City)` returns no error, `AttachPlaceRelationships` of City errors; "bad succession date" unchanged. STEP-3 adds to the last two cases: `FiledPlaceLinks(succeeded_by, [City])` returns no error, and `FiledPlaceLinks(succeeded_by, [Alpha])` errors; `TestPlaceEntriesFollowLinkMoves`: a part filed under City drops City's page, not its succession entry; a succession link added at City drops its succession entry | D-9, D-11, AC-1.5 (STEP-2 and STEP-3) |
| T-8 | Go | `core/database/promotealign/promotealign_test.go` `TestProposeReportsEachConnection` | Add "a loop through a filed chain" (AC-1.3) → `cycle`, Done mints none; "a succession loop" (AC-1.4) → `cycle`; "the check reads the entries" (AC-2.4) → after the proposal `g.KeyCounts()["conclusionsummaries.places"]` ≥ the chain's places | AC-1.3, AC-1.4, AC-2.4, D-10 |
| T-10 | Go | `core/database/promotealign/promotealign_test.go` `TestPlaceLinksServeEveryAcyclicTerm` *(new)* | For every `connectrules.Bridges()` entry with `AcyclicTerms`, for each term: `placeLinks(g)(type, term, nil)` returns no error | D-10 (review M-4) |
| T-11 | Go | `core/kinship/kinship_test.go` `TestEdgeReadings` *(new)* | A→B from A → (B, KeyA); from B → (A, KeyB); from C → nothing; X→X from X → (X, KeyA) then (X, KeyB) | D-14 |
| T-12 | Go | `core/graphalign/invariants_test.go` `TestAlignInvariants` | Add a case "a place part of itself on both sides": a layer place with a `part_of` self-loop and a canon place with the same self-loop → the invariants hold and the Subject places on that handle | D-16 |
| T-9 | Go | `perf_test.go` `TestLargeSourceBudgets`, `memo_test.go` `TestProposeWarmIssuesNoQuery`, `promotealign_test.go` `TestProposeQueryCountStaysFlatWhenWarm` | Unchanged → pass | Scale, D-13 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: the `graphalign` goldens (adjacency order), `TestPlaceEntryInputsMatchReads` (the page's inputs), `TestCacheDocListsEveryEntry` (the new entry's row).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] PROVENENCIA_GRAPH_VERIFY=1 CGO_ENABLED=1 go test -tags fts5 ./core/database/conclusionsummaries/... ./core/database/promotealign/... passes
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none expected)
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left (`CanonEdge`, `canonLinks`, `canonAdj`, `placePage.succFrom`, `placePage.succTo`, `Canon.Candidates` in prose); `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none)
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New (no UI)
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — none
- [ ] Ship log: D-13's base and head medians; docs/catalog-caches.md: placeSuccession row with its measured size
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated) — not gated
- [ ] Domain doc updated: docs/promote-graph-alignment.md (Align's signature and inputs, the filing rule's loop check), add-match-rule line 33
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Open a project with York `part_of` Ontario promoted from one Source. Make a second Source recording York and Ontario and an Ontario `part_of` York link. Open Promote on it and put both rows on the tree's records: the connection subrow reads "Not promoted · these places would form a loop" and the footer counts 0 connections, as before.
2. On the same Source, change the link's type to `succeeded_by` and repropose: it reads "Promotes on Done"; Done files it.
3. Promote a Source of 40 people on the large fixture before and after the branch: the rows, their bands and their order are the same.
4. AC-2.5: `rg -n "CanonEdge|canonLinks|canonAdj" core .agents docs/*.md` prints nothing.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| The adapter lists a handle's links in another order than `canonAdj` did, moving a golden | D-3 spells the order; T-1 (c) and every golden (T-2) |
| A loop the canon walk found is missed through the entries (a link the walk read that the entries do not) | T-8 and the S14-22 cases in `TestProposeReportsEachConnection` run Done after each proposal and compare |
| The interface call slows `Align`'s hot loop | D-13's medians; `TestLargeSourceBudgets` |
| The split changes the place page | `TestAttachPlaceRelationships`, `TestIrelandUKDatedMembershipDropsAfter1922`, `TestSuccessionNeverBuildsChain` stay green |

**Stop and report if:**

- Any `graphalign` golden, `TestAlignInvariants` or `TestProposeReportsEachConnection` assertion fails after STEP-4 or STEP-5: the plan's claim that the moves change no answer is wrong.
- A loop the filer refuses (Done mints nothing) reads `files` on the page, or the reverse, in any T-8 case: the entries and the filer's SQL disagree on what is filed (for example a link at a merged place).
- `TestProposeWarmIssuesNoQuery` or `TestProposeQueryCountStaysFlatWhenWarm` fails: the warm proposal now issues SQL for the loop check.
- `BenchmarkLargeSourcePropose`'s head median is more than 10% above base.
- `TestPlaceEntryInputsMatchReads` cannot hold for the page and succession entries with the hops D-9 names.
- `promotealign` importing `conclusionsummaries` makes an import cycle.

## 12. Open questions

None.

## 13. PR

**Title:** S16-21 — Promote's alignment reads a canon view and the place entries
**Body:** objective in one sentence; what shipped against US-1 and US-2; AC evidence; D-13's medians; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-21-canon-view-place-links.md`.
