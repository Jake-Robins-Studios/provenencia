# Review — S16-21 Promote's alignment reads a canon view and the place entries

**Verdict:** Fits with changes — Ready with changes (two rounds; no open blocker)
**Rounds:** 2. **Reviewers:** maintainability (Opus), executability (Sonnet)

## To user
- None.

## Writer's own calls
- D-9: a third place keyed entry, `conclusionsummaries.placeSuccession`, split out of the place page entry, instead of Promote reading the page (a 20,000-part hub's page fill on a proposal, and one bad part date failing it) or the map's literal "from the place entries" (which no longer hold succession since S16-18's round 1 split).
- D-11: a `part_of` link with an unreadable date that the loop check reaches fails the proposal, as it fails that place's chain everywhere else.
- D-10: `promotealign` imports `conclusionsummaries` in production (S16-18 review M-8).
- The event-type property lookup S16-20 deferred to this PR goes to S16-22, whose walk removal deletes one of the two lookups.
- D-16: a layer self-loop (a Source place `part_of` itself) now reads both keys in Align, as the canon side does; no test held the old reading.
- M-2's fix widens the PR into the filer (`identityclaims.fileBridge`): it keeps reading its own transaction, but decides through `connectrules.Filed`.

## Round 1

### M-1 · blocker · `CanonView.Links` invents a second way to read a link from one end
`Edge.From` is the one end-reading rule; turned links with a self-loop listed twice would be a contract every view (S16-22) repeats; `canonlinks.Reader.Relationships` returns unturned links.
**Answer:** Fixed — D-1 returns unturned links; D-14 adds `kinship.Edge.Readings` (A's end first, both for a self-loop); D-3 lists a self-loop once; D-4 reads through `Readings`; T-11; the layer side's self-loop reading is an Out row (`structural-debt.md`), since it can move a golden.

### M-2 · blocker · Two copies of the per-(type, term) filed-link sets, made more different
`graphalign.Connections` and `identityclaims.fileBridge` each keep a keyed map of `connectrules.Links` with lazy creation and `Add`; `structural-debt.md:32` names it.
**Answer:** Fixed — D-6 adds `connectrules.Filed` (`NewFiled(open)`, `Filed.Decide`) owning the key, lazy open and `Add`; both callers use it; both private key copies go; the Out row is withdrawn and the debt row loses that half (STEP-8); `TestFiled` in T-3.

### M-3 · major · `placeSuccession` is the third copy of the place keyed-entry scaffolding
**Answer:** Fixed — D-15 `registerPlaceKeyed[T]` / `placeKeyed[T].of`; all three entries declared through it; STEP-2 moves the two existing entries first.

### M-4 · minor · A missing filed-link reader fails a proposal instead of CI
**Answer:** Fixed — T-10 `TestPlaceLinksServeEveryAcyclicTerm`.

### M-5 · nit · Benchmark measure written in STEP-2, rewritten in STEP-3
**Answer:** Fixed — written once, in STEP-3.

### X-1 · major · `ClosesCycle` test-before-read order undecided
**Answer:** Fixed — D-6: `from` is tested in a level before the level is read.

### X-2 · major · `n:` records and empty levels undecided
**Answer:** Fixed — D-7: a level with no `h:` record returns an empty map without calling `filed`; `n:` records are absent from the answer.

### X-3 · major · `NominatedForTest` caller and `invariants_test.go` literal missed
**Answer:** Fixed — D-12 names line 2310 (`withCandidates(…).View()`) and the invariants literal.

### X-4 · minor · STEP-2's `rg` check cannot show what it claims
**Answer:** Fixed — `rg "page\.succ|pages\[.*\]\.succ"` expecting no hit.

### X-5 · minor · Cache-doc size before it is measured
**Answer:** Fixed — placeholder `measured in STEP-7`.

### X-6 · minor · Where `FiledPlaceLinks` gets `vocab`
**Answer:** Fixed — D-8: `vocabulary(g)`, error returned.

### X-7 · minor · `placeStep` order and row inputs
**Answer:** Fixed — D-9: read right after the page, before the early return; no summary row records page or succession keys.

### X-8 · minor · `Propose`'s error return
**Answer:** Fixed — D-10: `graphalign.Proposal{}, 0, err`.

Also: the base checkout for D-13 is a `git worktree add` at `ba2d35a`.

## Round 2

### X-9 · blocker · T-1 contradicts D-1, D-3 and AC-2.2 on what `Links` returns
**Answer:** Fixed — T-1 (a) and (b) expect the stored link, once; the Edges assumption reads "listed once and read twice, `A`'s end first".

### X-10 · blocker · STEP-4's check cannot pass with `connections_test.go` still on `CanonEdge`
**Answer:** Fixed — STEP-4 converts its literals to `kinship.Link` and changes nothing else there until STEP-5.

### X-11 · major · STEP-2's T-7 cases call `FiledPlaceLinks`, which STEP-3 adds
**Answer:** Fixed — STEP-2 tests through `FillPlaceSuccessionsForTest` and `AttachPlaceRelationships`; STEP-3 adds the `FiledPlaceLinks` calls.

### X-12 · major · Fixtures for the bad-date and chain cases
**Answer:** Fixed — the bad part date uses `breakDates` over a dated part link and an undated succession link (S16-18's "bad succession date" shape); AC-1.5 is held at the reader `Propose` uses (T-7), and the 2,000-part Promote case is dropped; T-8's trees are built with `f.Place`, `f.PlaceRel` and `f.promote` as `build` does.

### X-13 · minor · Where registration runs
**Answer:** Fixed — D-15: assigned in `init()`.

### X-14 · nit · Stale comment at `align_test.go:92`
**Answer:** Fixed — STEP-4's Do.

### M-6 · blocker · T-1 and §6 Edges still pin the rejected turned-link contract
**Answer:** Fixed — same fix as X-9.

### M-7 · blocker · `newState` keeps a second end-reading rule, deferred on an unchecked premise
The reviewer searched the `graphalign` and `promotealign` tests: no golden or invariant holds a layer self-loop.
**Answer:** Fixed — D-16 moves the layer loop onto `Edge.Readings`; T-12 adds a self-loop case to `TestAlignInvariants`; the Out row and the planned debt row are withdrawn. A Source place `part_of` itself now reads both keys, as the canon side does (listed under Writer's own calls).

### Below blocker (taken)
- The exported `connectrules.Decide` would have no caller beside `Filed.Decide`: D-6 unexports it.
- §6 Neighbors' "one `linkKey` each" → "one `Filed` key each".
- Not taken: deleting `align_test.go`'s `edge` and `canonOf` helpers (test tidying the plan does not need).
