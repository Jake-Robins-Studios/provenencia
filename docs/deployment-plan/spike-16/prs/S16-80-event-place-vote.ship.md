# Ship log — S16-80 An event's places reconcile by their records

**Plan:** [`S16-80-event-place-vote.md`](S16-80-event-place-vote.md) · **Branch:** `s16-80-event-place-vote` · **PR:** #1007
**State:** ready

## Round 0 — implement
Head `21ce48405`. Gate PASS (orchestrator run). Report deviations: version 0.48.3 (main already at 0.48.2); `eventFoldDate` takes a `valuecompare.Dating` from a new `eventDating`; `FoldLocations` takes subject values; `finishVote` takes the vocabulary; `placePrep` carries survivors, subject values and the place graph; `lifeEvents` and `placesOfEvents` deleted as dead; `ownerVerdict` leaves `GroupRank` alone for folded (D-13). Manual check not run. Unrelated: `go build ./bin/...` already fails on main (`bin/reseed-source-vocab`).

## Round 1 — review
Reviewers: CON, MNT, SEC+PRF. Skipped: UX (no `macos/App/**`, strings, or error codes).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | blocker | An outvoted place keeps matching in search after a write that changes the vote but not the association's display | Fix now → F-1 | Reviewer's overlay probe failed (England docs stay `[event person]` incremental, `[]` after RebuildAll); read `autoreconciler.go:340` (`moved` by `SameDisplayRows`) and `searchindex/inputs.go:97` ("written but neither moved nor gone adds no key"). Working rule "every cache … updates exactly". Carries a failing test |
| MNT-1 | MNT | blocker | `FoldLocations` repeats the Contains-from-broader fold predicate inline | Fix now → F-2 (same-pass cleanup) | Read `placechains.go:378`, `modules.go:87`, `names.go:129`: three copies of `Relation == Contains && Broader == SideA`; D-7 names one check |
| MNT-2 | MNT | blocker | `finishVote` hand-rebuilds the pipeline's record ranking | Fix now → F-3 | Read `placevote.go:203-213` vs `pipeline.go:99-107`: same two keys, two copies |
| SEC-1 | SEC | major | Person row prepares and loads votes for every birth/death event, uncapped, though 64 owners are kept | Fix now → F-4 | Read `compose.go:697-726`: `eventLocations`/`prepareVote` per pick, all assocs to one `g.Nodes`; `lifePicks` has no cap; `owned` cap applies only in `lifeFacts` after the work. Spike rule "Crafted fan-out is capped" |
| MNT-3 | MNT | minor | `placePrep` "finished" encoded as `len(assocs) == 0` | Fix now → F-5 | Minor in a file this PR adds; read `placevote.go:96-104,156-158` |
| MNT-4, CON-2 | MNT, CON | minor | Planned `subjectprofile.Value` comment missing | Fix now → F-6 | `git diff --stat` has no `core/subjectprofile`; STEP-4 Files names it |
| PRF-1 | PRF | minor | `memberOf` linear scan per outcome row | Fix now → F-7 | Minor in a file this PR adds; `conclusiondetails.newRecordReader` builds the map |
| CON-OML | CON→PRF | — | Every subject Property now folds pairwise in the auto-reconciler | Rejected | SEC+PRF checked: auto-reconciler subject units carry no `Within`, so `Compare` returns `Different` at once; the fold was already quadratic over distinct values, only the constant grows |
| MNT-OML | MNT→CON | — | No test pins that `FoldLocations` and `Reconcile` fold alike | Fix now, inside F-2 | One predicate removes the second copy |

Nits (logged): `MNT-5 · placevote.go:162-163 · linkOf and weigh are two maps over the same candidates` (F-3 removes `weigh`) · `MNT-6 · placevote.go:37-38 · placeVote.links comment says PropertyID not set; listOwner sets it` · `MNT-7 · compose.go:715 · prepareVote runs in map order over lives; iterate need` · `CON-3 · eventplacevote_test.go TestEventPlaceVoteCap · also assert Swift Current leads`

### Fix plan 1

**F-1 — A write to an association reprojects the rows that voted over it** (from CON-1)
Files: `core/database/searchindex/inputs.go` (`ReprojectChanged`), `core/database/conclusiondetails/placerecords_test.go`.
Failing test first: `TestOutvotedPlaceLeavesSearchOnWrite` — the reviewer's test verbatim (helper `englandDocs` querying `catalog_search_docs` for `England` among `person`/`event` kinds; three `placedBirth` calls: Register 1 Swift Current, Gazette England, Register 2 Swift Current on the same birth; expect no England docs). Run it red first.
Do: in `ReprojectChanged`, a written handle that is an association adds the rows composed from its own values (the input key `finishVote` records through `InputScope.Node`) whether or not it moved, the same way a moved handle's own values do today. Do not widen `moved` itself (it also drives which pages the app reloads), and do not change `SameDisplayRows`. Update the `ReprojectChanged` doc comment's bullet list to name the new case. If the index cannot tell an association handle from its rows, stop and report what it records.
Check: the new test passes; T-8 `TestEventPlaceVoteFollowsEvidence` still passes; `go test -tags fts5 ./core/database/searchindex/...` passes.

**F-2 — One "folds into" predicate in value compare** (from MNT-1, same-pass cleanup)
Files: `core/valuecompare/` (new exported func beside `Compare`), `core/autoreconcile/modules.go`, `core/autoreconcile/names.go`, `core/database/conclusionsummaries/placechains.go`. Skill: `add-match-rule`.
Do: add `valuecompare.FoldsInto(from, into Value, r Rules) bool` — true when `Compare(from, into, r)` is `Contains` with `from` the broader side (SideA). Doc comment says it is the one S11-06 fold-on-Contains check. `foldsOnContains` calls it (or is replaced by direct calls); `nameModule.fold`'s first case uses it (keep its `Equivalent` case as is); `FoldLocations` uses it. Add a `FoldsInto` case to `valuecompare_test.go` (a date range folding into a point inside it, and the reverse false).
Check: `git grep -nE "Broader == valuecompare\.Side" core` prints only the line inside `FoldsInto` (and tests, if any). `go test ./core/valuecompare/ ./core/autoreconcile/ ./core/database/conclusionsummaries/` passes.

**F-3 — `finishVote` reads the pipeline's own rank** (from MNT-2, MNT-5)
Files: `core/autoreconcile/autoreconcile.go`, `core/autoreconcile/pipeline.go`, `core/database/conclusionsummaries/placevote.go`.
Do: export the ordering `reconcile` uses: `autoreconcile.RanksBefore(a, b Candidate) bool` (stronger `Provenance` first, then the smaller `ObservationID`), and have `reconcile` build `order` with one `sort.SliceStable` on it (same order as the two stable sorts today). In `finishVote`, keep one map Observation id → candidate index and pick each link's best outcome with `RanksBefore`; delete `weigh` and the hand-written comparison.
Check: `rg -n "weigh\[" core/database/conclusionsummaries` prints nothing; `go test ./core/autoreconcile/ ./core/database/conclusionsummaries/ ./core/database/conclusiondetails/` passes (T-6 `TestPlaceOwnersCarryTheVote` unchanged).

**F-4 — A life row votes only the picks that can still add an owner** (from SEC-1)
Files: `core/database/conclusionsummaries/compose.go` (`composePersons`, `lifeFacts`), `core/database/conclusionsummaries/eventplaces_cap_test.go`.
Failing test first: extend `TestCraftedLifeOwners` with a "many births" case — one Person with 20 × 64 birth events, each placed at two unrelated places; the Person row composes within the existing one-second budget and keeps at most `maxLifeOwners` owners, and pick 0's places are the vote's.
Do: in `composePersons`, run `eventLocations` and `prepareVote` for pick 0 of each list always, and for later picks only while a running count of that life row's links (date owners plus location links, as `lifeFacts` counts them) is below `maxLifeOwners`; a pick past the budget gets no prep and `lifeFacts` skips its `finishVote`. What a life row shows does not change for any Person with fewer than `maxLifeOwners` links.
Check: the new case passes; every existing `TestCraftedLifeOwners`, `TestPersonDerivedRows`, `TestEventPlaceVote*` case passes.

**F-5 — `placePrep` says when it is finished** (from MNT-3)
Files: `core/database/conclusionsummaries/placevote.go`.
Do: make the state explicit: `vote *placeVote`, non-nil when `prepareVote` already decided. `finishVote` returns `*prep.vote` when set; on the many-survivors path with no listed association, fall back to the fold's survivors, each link `kept`. Fix the `placeVote.links` comment (MNT-6) while there.
Check: package tests pass.

**F-6 — Matching's conversion says why it leaves `Entity` and `Within` empty** (from MNT-4, CON-2)
Files: `core/subjectprofile/subjectprofile.go`.
Do: one doc-comment line on `Value`: it leaves `Entity` and `Within` empty until matching fills `Within` (`docs/ideas/one-bridge-cardinality.md`); do not copy them across here.
Check: `rg -n "one-bridge-cardinality" core/subjectprofile/subjectprofile.go` prints the line.

**F-7 — `finishVote` maps each node's members once** (from PRF-1)
Files: `core/database/conclusionsummaries/placevote.go`.
Do: build a Subject id → Member map once per node, as `conclusiondetails.newRecordReader` does; delete `memberOf` if nothing else calls it.
Check: package tests pass; `scripts/check-pr.sh` PASS.

Also update the plan's Landed note with the differences F-1..F-7 make. Ordering: F-1, F-2, F-3, F-4, then F-5..F-7.

## Round 1 — fix
Head `a749cd81c`. Gate PASS (orchestrator run). F-1, F-2, F-3, F-5, F-6, F-7 done; F-4 not reproduced (dropped SEC-1).
- F-1 deviation: reprojecting on every written association broke `TestFiledPartOfReprojectsEventsOnlyWhenARowMoved` (part_of chains also read association values); the rule is limited to written event place bridges (`hops.PlacesOfEvent.Bridge()`). Review 2 checks this.
- F-2 deviation: `nameModule.fold` also needs `det.Parts`, so `valuecompare.FoldsResult(res, det)` is exported beside `FoldsInto`, which wraps it.
- SEC-1 → **Rejected**: the "many births" case (one Person, 20 × 64 = 1,280 birth events, two unrelated places each, shared and unique places) passed before any change: `PersonsByIDs` 53 ms / 70 ms against the 1 s budget, owners ≤ 64, the lead event's places shown. Test removed with no code change.
- Minors read by orchestrator: MNT-3 (F-5) **Resolved** — `vote *placeVote`, many-survivors-no-association path falls back to the fold's places; MNT-6 comment fixed. PRF-1 (F-7) **Resolved** — member map per node, `memberOf` deleted. MNT-4/CON-2 (F-6) **Resolved** — `subjectprofile.go:255`.
- Implementer noted `TestListMergeMatchesReload` (`core/database/promotealign`) missed its 20 ms budget once (29 ms) under a parallel `core/database/...` run; passed in the gate. Not touched by this PR.

## Round 2 — review
Reviewers: CON (CON-1), MNT (MNT-1, MNT-2), SEC+PRF (SEC-1 was Fix now; F-1 also changes the search reprojection path). Scope `21ce48405...a749cd81c`.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | blocker | (round 1) | Resolved | Reviewer ran `TestOutvotedPlaceLeavesSearchOnWrite` red against head with the old `inputs.go`, green at head |
| MNT-1 | MNT | blocker | (round 1) | Resolved | `FoldsInto`/`FoldsResult`; grep prints only `valuecompare.go:211` and a date test |
| MNT-2 | MNT | blocker | (round 1) | Resolved | `RanksBefore`; `weigh` gone |
| SEC-1 | SEC | major | (round 1) | Rejected, confirmed | SEC+PRF probe on the product axis: 1,280 births × 20 places = 25,600 places, `PersonsByIDs` cold 868 ms < 1 s, linear (~0.68 ms/event), owners 64 |
| MNT-7 | MNT | blocker | Search index hard-codes the event place bridge as the "voted over records" signal; it also reprojects (and reloads) every row that merely followed the link | Fix now → F-8 | Verified: `graphcache/inputs.go:33-41` `FollowKeys` records `NodeKey(assoc)` for every follower, the same key `finishVote`'s `in.Node` records, so `searchindex/inputs.go:153-157` reprojects one-place Event and life rows that never vote, and returns them as pages to reload. `hops` import in `searchindex` is the only one. Next voting bridge (`one-bridge-cardinality.md` item 3) would miss it |

Nits (logged): none.

### Fix plan 2

**F-8 — The vote's record read is its own declared input** (from MNT-7)
Files: `core/database/graphcache/inputs.go`, `core/database/conclusionsummaries/placevote.go`, `core/database/searchindex/inputs.go`, `core/database/conclusiondetails/placerecords_test.go` (or `searchindex` tests).
Failing test first: `TestPlaceLinkWriteLeavesOnePlaceRowsAlone` — a Person with a one-place birth (one Source, Swift Current); file a second Source's Swift Current record on the same birth (the same association, display unchanged); `ReprojectChanged`'s returned rows do not include the Person or the Event (at head they do, because the bridge rule matches every follower). Keep `TestOutvotedPlaceLeavesSearchOnWrite` and `TestFiledPartOfReprojectsEventsOnlyWhenARowMoved` green.
Do: add `graphcache.RecordsKey(id []byte) InputKey` beside `NodeKey`: "the key a read of an association's records records, for a reader whose result depends on its records and not only its displayed rows" (for example `InputKey{ID: id, Endpoint: "records"}` with a named constant; update the `InputKey` doc). Add `InputScope.Records(id) (*Node, error)` that is `Node` and also records `RecordsKey(id)`, or have `finishVote` call `in.Add(graphcache.RecordsKey(l.Association))` after `in.Node`. In `ReprojectChanged`, for each live written handle add `RecordsKey(id)`; delete the `AssociationInputs(writtenLive)` call, the bridge comparison, and the `hops` import. Fix the doc comment ("written but neither moved nor gone adds no key, except the records key a vote read"). If the stored inputs index cannot hold a key with an empty Bridge and a set Endpoint (a constraint, or code that reads Endpoint as a hop end), stop and report it.
Check: `rg -n "hops\." core/database/searchindex/*.go | grep -v _test` prints nothing; the three tests pass; `go test -tags fts5 ./core/database/...` passes; `scripts/check-pr.sh` PASS. Add the change to the plan's Landed note and `docs/catalog-caches.md` if it lists input key kinds.

## Round 2 — fix
Head `45a9778bf`. F-8 done: `graphcache.RecordsKey` / `InputScope.Records`; `finishVote` reads through `in.Records`; `ReprojectChanged` adds `RecordsKey(id)` per live written handle; `hops` import gone from `searchindex`. `TestPlaceLinkWriteLeavesOnePlaceRowsAlone` red first, then green; `TestOutvotedPlaceLeavesSearchOnWrite` and `TestFiledPartOfReprojectsEventsOnlyWhenARowMoved` green. Deviation: the in-memory cache's `inputIndexKey` ignores `Endpoint`, so `RecordsKey` indexes there as the node's own key (a superset; `finishVote` records `NodeKey` for the same id anyway). MNT-7 **Resolved** (orchestrator read the commit; round cap reached, no round 3).

## Finish
`origin/main` had moved (S16-81/82 docs). Merged; one conflict in `deployment-plan.md` map rows (kept this PR's S16-80 row and main's S16-81, S16-82 rows). Gate after merge: FAIL xcode-test — `PromoteModelTests.donePromotesEveryRowWithATargetOnly`: `claimBySubject["a"]` nil. Pre-existing race, no Swift in this PR: `FakeStore.applyPromoteGraphAlignment` records `lastPromoteBatch` before `seedPromotionLocked` writes the claim, and the test waits only on the batch. Gate fix G-1 (one item): tests wait on the state they assert.
G-1 done (`b13d86032`, test-only: waits on `lastPromoteBatch != nil && claimBySubject["a"] != nil`; the other three `waitUntil` sites read only state written by the batch). Gate PASS on `b13d86032` (orchestrator run).

## Result
Gate PASS · CI green (Go tests, macOS tests) · open: none · follow-ups: none (both answered by the user, below) · to user: —

Follow-ups, answered by the user (2026-11-27):
- `TestListMergeMatchesReload` ceiling: raised on this PR to 30 ms (G-2, `a620718ee`); the comment records why. A whole compose at the bottom of its 28–73 ms range would now pass under it.
- `bin/reseed-source-vocab`: gitignored local one-off, never tracked, so nothing on the PR; moved to the Trash by the orchestrator. `go build ./bin/...` no longer fails.

## Cost
Plan: 6,717 words (check-plan-docs info line).

| Round | Agent | Model | Tokens |
| --- | --- | --- | --- |
| 0 | implementer | sonnet | 339k |
| 1 | CON | opus | 136k |
| 1 | MNT | opus | 101k |
| 1 | SEC+PRF | opus | 97k |
| 1 | implementer fix | sonnet | 130k |
| 2 | CON | opus | 44k |
| 2 | MNT | opus | 56k |
| 2 | SEC+PRF | opus | 52k |
| 2 | implementer fix | sonnet | 94k |
| gate | implementer G-1 | sonnet | 74k |
| | **Total** | | **1,123k** |
