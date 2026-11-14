# Ship log — S16-32 Promote re-ranks only the Subjects a write moved

**Plan:** [`S16-32-narrow-candidate-rerank.md`](S16-32-narrow-candidate-rerank.md) · **Branch:** `s16-32-narrow-candidate-rerank` · **PR:** #832
**State:** ready

## Round 0 — implement
Head `5a418def7`. Implementer gate PASS on its second full run (first run: `TestLargeSourceBudgets` "warm at open" 5.2 s and "cold" 2.8 s over budget while the Xcode build ran in parallel; both pass alone). Orchestrator gate PASS at `5a418def7`.

Report deviations:
- `main` moved `36d6ec2` → `08d03b04f`; no Current state row changed.
- `Filed` doc reworded ("A Find in kind finds a handle when one of the keys asked for is among the keys the handle is Filed under in that kind") because `Lookup` is gone.
- `TestCandidatesFollowMovedKeys` does not assert the T-1 cells marked "—".
- `catalog-caches.md` `evidencelayer.layers` size column now holds the `evidence-B` pair (7.7 / 7.8 MB), replacing 34.5 / 45.0 MB that covered three entries together (per STEP-8).
- STEP-1's no-gate state and STEP-7's gate are separate commits.
- Manual check (plan §10) not run; no chrome.

Figures (Apple M1, Verify unset, `BenchmarkLargeSourcePropose` / `BenchmarkCacheSizes`, benchtime 1x):

| | persons | warm-ms | after-commit-ms | after-commit-x | evidence-B |
| --- | --- | --- | --- | --- | --- |
| before | 4,000 | 225.8 | 643.4 | 2.849 | 7,747,072 |
| before | 16,000 | 233.1 | 1057 | 4.533 | 7,723,568 |
| after | 4,000 | 157.2 | 160.2 | 1.019 | 7,747,760 |
| after | 16,000 | 179.6 | 244.8 | 1.363 | 7,806,528 |

Note: the untracked ship log created before round 0 did not survive into the implementer's checkout; recreated here.

## Round 1 — review
Reviewers: CON, MNT, SEC+PRF. Skipped: UX (no `macos/App/**`, `Localizable.xcstrings`, `core/apperr`, or new error codes).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | blocker | `evidencegraphs.Index` and `sources.Records` patch in place but still call `Set`, so the new `Whole.Patched` rule is false in two places | Fix now → F-1 | verified: `evidencegraphs/index.go:159` and `sources/records.go:109` call `w.Set(g, idx)` on the pointer `w.Get` returned; `graphcache/cache.go:642-660`: `Set` re-puts and empties readers, `Patched` empties non-narrowing readers. Same-pass cleanup (two ways to say "patched in place"); grep over the shape finds only these two |
| MNT-2, CON-2 | MNT, CON | minor | `loadCandidatesMemo` doc still says the memo is held "until the match index changes" | Fix now → F-2 | verified `canon.go:249`; stale comment in a file this PR changes |
| MNT-3 | MNT | minor | `ceilingForgetCandidates` decided comment cites the 64×10,000 cost (≈200 ms) for the 1×10,000 + 63×100 shape it tests (≈5 ms) | Fix now → F-3 | plan §4 vs §6; minor in a file this PR adds |
| CON-1 | CON | minor | T-4 checks the `Find`/`Filed`/`LookupKeys` property over two probes, not `TestLookup`'s cases | Fix now → F-4 | `TestLookupKeys` has 2 probes; `TestLookup` has 20 cases; the forget's exactness rests on this property |
| SEC+PRF | SEC, PRF | — | No findings | — | forget timed at 3.45 ms vs 100 ms ceiling; stored keys bounded by `shortlist.Keys` caps |

Nits (logged): `MNT-4 · core/shortlist/shortlist_test.go:99,185,191,296,300 · TestLookup / TestLookupCopiesAndSorts and "Lookup =" messages name a removed method (rides along in F-4)` · `MNT-5 · promotealign/index.go:747 · name the moved-keys map type` · `MNT-6 · promotealign/perf_test.go:572 · test re-derives HoldCandidatesForTest's Subject-id scheme`

### Fix plan 1

**F-1 — In-place whole patches report with `Patched`** (from MNT-1)
Files: `core/database/evidencegraphs/index.go`, `core/database/sources/records.go`. Skill: `use-catalog-session`.
Failing test first: none — no reader narrows today, so behavior is unchanged (`Patched(g, nil)` empties the same non-narrowing readers `Set` did, and the held pointer is already stored by `Get`). Confirm with the existing `derivedFromIndex` reader test in `evidencegraphs/index_test.go` still passing.
Do: replace each `w.Set(g, idx)` in those Applies with `w.Patched(g, nil)`; say in each Apply's doc that it patches the held index in place and reports with `Patched`. Supersedes the plan's Codebase fit, which named only `applyMatchIndex`; note in the plan's Landed note.
Check: `rg -nE '\.Set\(g, [a-zA-Z]+\)' core -g '!*_test.go'` prints nothing; `PROVENENCIA_GRAPH_VERIFY=1 go test ./core/database/evidencegraphs ./core/database/sources ./core/database/promotealign` passes; scripts/check-pr.sh PASS.

**F-2 — Fix the `loadCandidatesMemo` doc** (from MNT-2, CON-2)
Files: `core/database/promotealign/canon.go`.
Do: replace "held in the candidates entry until the match index changes" with wording that says a commit forgets the Subjects whose lookup keys it moved (`forgetCandidates`) and a dropped match index empties the entry.
Check: `rg -n "until the match index changes" core` prints nothing.

**F-3 — Fix the `ceilingForgetCandidates` decided comment** (from MNT-3)
Files: `core/database/promotealign/perf_test.go`.
Do: state the tested shape's cost (63 graphs of 100 Subjects and one of 10,000, 7 keys each, about 5 ms at the planning machine's rate; 64 of 10,000 would be about 200 ms) and that the ceiling catches a slip to a scan per moved key. Ceiling value unchanged.
Check: comment matches plan §6.

**F-4 — Check `Find` against `Filed`/`LookupKeys` over every `TestLookup` case** (from CON-1; MNT-4 rides along)
Files: `core/shortlist/shortlist_test.go`.
Failing test first: not applicable (the property holds today); the test widens coverage.
Do: inside `TestLookup`'s loop, for every filed entry assert it is in `Find(...)` exactly when one of the probe's `LookupKeys` is among its `Filed` keys. Rename `TestLookup` / `TestLookupCopiesAndSorts` and their "Lookup =" messages to name `Find`. `TestLookupKeys` may stay or fold in.
Check: `go test ./core/shortlist` passes; `rg -n "Lookup =" core/shortlist` prints nothing; scripts/check-pr.sh PASS.

## Round 1 — fix
Head `c4b634d40`. Gate PASS (orchestrator run). F-1 to F-4 done. Deviations: no failing test first for F-1/F-4 (as the fix plan said); plan lines 119 and 300 and S16-20's plan still name `TestLookup` / `TestLookupCopiesAndSorts` (history, left as is).
Minors checked by the orchestrator from the fix diff: F-2 (MNT-2, CON-2) **Resolved** — `canon.go:249` reworded; F-3 (MNT-3) **Resolved** — comment gives the tested shape, ceiling unchanged; F-4 (CON-1, MNT-4) **Resolved** — `TestFind` asserts `Find(LookupKeys)` ⇔ a key among `Filed` for every entry of every case; renames done.

## Round 2 — review
Reviewers: MNT (had a Fix-now blocker). Not sent: CON (minor only, resolved above), SEC+PRF (no findings). Scope `5a418def7...c4b634d40`.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 (round 2) | MNT | blocker | Code resolved; `docs/catalog-caches.md` rows `evidencegraphs.index` (line 16) and `sources.records` (line 24) still say "then `Set`" | Fix now → F-5 | verified: both cells read "then `Set`"; the `promotealign.matchindex` row (line 23) already says "reports … with `Patched`" |

No new findings.

### Fix plan 2

**F-5 — Name `Patched` in the cache map for the two entries F-1 moved** (from MNT-1, round 2)
Files: `docs/catalog-caches.md`.
Do: in the Updated-by cell of `evidencegraphs.index` and of `sources.records`, replace "then `Set`" with "then reports the in-place patch to its readers with `Patched`", worded like the `promotealign.matchindex` row.
Check: `rg -n 'then \`Set\`' docs/catalog-caches.md` prints nothing; scripts/check-pr.sh PASS.

## Round 2 — fix
Head `aa121c169`. Gate PASS (orchestrator run). F-5 done: `rg -n 'then \`Set\`' docs/catalog-caches.md` prints nothing. MNT-1 **Resolved**. Branch current with `origin/main` (`08d03b04f`).

## Result
Gate PASS · CI <pending> · open: none · follow-ups: none · to user: —
