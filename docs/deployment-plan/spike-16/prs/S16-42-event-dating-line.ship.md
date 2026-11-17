# Ship log — S16-42 Every event date line reads the engine's dating

**Plan:** [`S16-42-event-dating-line.md`](S16-42-event-dating-line.md) · **Branch:** `s16-42-event-dating-line` · **PR:** #876
**State:** ready

## Round 0 — implement
Base `main` @ `09f7398`.
Head `e0779888f` (local, not pushed; no PR). Gate not run. STEP-1 – STEP-9 done, each step check passing; STEP-10 – STEP-13, the version bump and the PR not done.

**Stopped on:** §11 "AC-4.3 is not met". `BenchmarkLargeSourcePropose`, warm-ms, median of 3, Apple M1; base = `dbc946c` + the D-13 shape commit, branch = `e0779888f` with D-12.

| persons | asof=0.3 overhead, base | branch | run spread base / branch |
| --- | --- | --- | --- |
| 4000 | +2.48 ms | +3.25 ms | 0.46 / 0.17 ms |
| 16000 | +3.98 ms | +2.71 ms | 8.26 / 2.88 ms |

Implementer's reading: D-12 only narrows the lookup of as-of-only probes (about 6 in Source A at 30%); the added cost is as-of-only catalog events filed as one open reach and compared as candidates, which D-12 keeps on purpose (index keys stay open, D-9's pairs). Profile at 4,000: growth spread over `graphalign.Candidates` / `promotealign.rankCandidates`, `subjectcompare.Compare`, `mallocgc`; no single top function. Raw runs: scratchpad `base-bench.txt`, `branch-bench.txt`.

Plan ambiguities raised (for plan-pr):
1. T-1 / §6 Edges "as-of 2020 + end 2015 → High the as-of" vs D-4: both sides pick the same sample, so D-4 gives `High` nil (`as of 2020`, open both). Test pins D-4's result.
2. T-1 tied-Hi row asserts Low only; split into `TestDatingOfTiedHiTakesLowestLo`.
3. T-10: indexed strings are ISO (`1990-01-10`), from `CompactDisplay`.
4. T-7: `TestEventDatingProto` unit test plus an OCCURRENCE assertion in `TestListEventSummaries`, not a new RPC fixture.
5. `eventPlaces` keeps its unused `v vocab` parameter, as D-7 states it.

Taken to the user 2026-11-17.

**User, 2026-11-17:** relax AC-4.3, resume. Plan amended in `b0e0cab0c` and the next commit: the branch's overhead must not exceed the base's by more than the widest spread among that size's four rows of runs; T-1 / Edges "as-of 2020 + end 2015" read as D-4 gives it (ambiguity 1). Ambiguities 2–5 accepted as deviations. Against the round-0 runs: 4,000 → +0.77 ms vs widest spread 0.97 ms (branch `asof=0`); 16,000 → −1.27 ms. The final benchmark is re-run on the finished branch for the PR body.

## Round 0 — resume
Head `b994dadf2`. Gate PASS (run by the orchestrator: all nine checks, xcode-test 87s). STEP-10 – STEP-13, version 0.20.0, Landed lines done; draft PR #876.
AC-4.3 re-run on the finished branch: 4,000 → overhead +0.09 ms over base (widest spread 5.34); 16,000 → −0.69 ms (widest spread 10.51). Met.
Report deviations: the four accepted ones; T-6 `TestEventDatingManyAsOfs` measured 69 ms once under the full parallel `go test ./...` (17 ms alone; later full runs pass) — the stop condition says 50 ms, the implementer judged it load; DoD sweep for `vocabkey.Property(StartDate|EndDate|AsOf)` in `conclusionsummaries` still finds 4 non-test hits (`placeShell`, `assocDatesOf`, `oneEvent`'s `h.StartDate` / `h.EndDate` for S16-44's fields); §10 manual check not run; STEP-10 – STEP-12 commits lack the Co-Authored-By line.

## Round 1 — review
Base `09f739825`. Head `b994dadf2`.
Reviewers: CON, MNT, UX (`macos/App/**`, `Localizable.xcstrings`), SEC+PRF (`core/valuecompare`, `core/shortlist`, `core/subjectcompare`, `api/ffi/**`, `core/database/**`, `core/search`, `macos/App/Features/**` models). Skipped: none.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 (+ SEC outside-lens, MNT-3 in part) | CON | major | The dating depends on the order of the as-ofs | Fix now → F-1 | Carries a failing test; read `pickSamples` (`dating.go:118-131`): the post-scan breaks a tie on the picked end by the same end's other side only, then by index, so `[bet 1990 and 1991, 1991]` and its reverse give different `High`. Breaks §6 Edges "Picks never depend on row order". D-3's "equal in both ends → lower index" stays for samples equal in all four bounds |
| MNT-3 | MNT | major | Two tie-break passes on top of `SampleExtremes` | Fix now → F-1 (comment half) | The two picks read dates differently on purpose (D-3: `DateEnds` for display, `samplesAgainst` the matching reading with key order); moving dating's tie into `SampleExtremes` would change matching. F-1 states each tie rule and why it differs in both doc comments |
| SEC-1 | SEC | minor | `DatingOf` has no fuzz or random probe | Fix now → F-1 | New code ranking catalog values; the reviewer's 300k-input probe found the CON-1 order dependence |
| CON-2 | CON | major | T-6 asserts a wall-clock bound that flaked in the gate; AC-2.8 "each as-of once" unproven | Fix now → F-2 | Ship log round 0: 69 ms under full `go test ./...` vs 17 ms alone; the test passes on a double read under 50 ms. AC-2.8 is the once-read; the 50 ms is T-6's stand-in |
| MNT-2 / CON-3 | MNT, CON | major | `EventDetailTests.dated` derives a dating in Swift, against D-15 | Fix now → F-3 | Read `EventDetailTests.swift:52-57`: date → occurrence, else span with open flags; D-15 names this convenience as rejected |
| MNT-1 | MNT | major | `subjectcompare.Samples` is dead and its doc false | Fix now → F-4 | `rg '\bSamples\(' core api` finds only the definition at `pairs.go:44` |
| CON-4 | CON | minor | A start-and-end row overlapping the birth now sorts after it on the Timeline | Fix now → F-5 | Follows from D-5's `Days = EndsWindow(first, last)` and the user's "one dating for every event" (2026-11-17); pin it with a row and name it in the Landed differences. Raised in the report so the user can overturn it |
| MNT-4 / CON-5 | MNT, CON | minor | `datingSample.original` is never read | Fix now → F-6 | `dating.go:107` sets it; no reader |
| MNT-5 | MNT | minor | `placeDating` keeps two names for the same values | Fix now → F-6 | Reviewer's trace; a file this PR adds to |
| UX-1 | UX | minor | Event page header says "as of …" while the Date row says "No date recorded" | Later PR (S16-44) | Written into S16-44's map scope entry, **Check** line |

Nits (logged): `UX-2 / MNT-8 · DateRowDisplay.swift line(dating:) · say the empty-side fallbacks are defensive` · `MNT-6 · conclusionsummaries/events.go:35-38 · EventSummary doc still folds at "the event's date"` · `MNT-7 · subjectcompare/pairs.go samplesAgainst · p.Samples == "" redundant` · `MNT-9 · grapheventtitles.FromStored · dates map collects every Subject's` · `MNT-10 · promotealign/perf_test.go newLargeFixtureAsOf · as-of death built by hand beside EventOn` · `CON-6 · dating.go:45-49 · DatingOf doc "never on the order" (goes with F-1)`

### Fix plan 1

**F-1 — The dating never depends on the order of the as-ofs** (from CON-1, MNT-3, SEC-1, CON-6)
Files: `core/valuecompare/dating.go`, `dating_test.go`, `core/valuecompare/fuzz_test.go` (or beside the existing comparer fuzz), `core/subjectcompare/pairs.go` (comment only). Skill: `add-match-rule`.
Failing test first: `TestDatingOfOrderFreeWhenOnlyOneSideTies` — as-ofs `bet 1990 and 1991` and `1991`, given and reversed, must give the same `High == nil` and the same `DateEnds` of Low and High (today: nil vs 1991); also `1990` with `bet 1990 and 1995`.
Do: in `pickSamples`, rank every sample by values before index. Low pick: lowest `lo.Hi`, then lowest `lo.Lo`, then lowest `hi.Lo`, then lowest `hi.Hi`. High pick: highest `hi.Lo`, then highest `hi.Hi`, then the low pick's sample when it is tied on all of these, then highest `lo.Hi`, then highest `lo.Lo`. Index only for samples equal in all four bounds (D-3's "equal in both ends"). Keep `SampleExtremes` unchanged (matching reads it). Rewrite `DatingOf`'s doc to say exactly that. Add `FuzzDatingOf`, seeded in the shape of `core/subjectcompare/fuzz_test.go` `FuzzCompareProperty`: no panic, and a permutation of the samples gives the same `DateEnds` of Low and High and the same `High == nil`. In `samplesAgainst`'s doc, one sentence on why its tie (lowest `KeyCompare`) differs from the dating's.
Check: the new test and fuzz seed corpus pass; `go test -fuzz FuzzDatingOf -fuzztime 30s ./core/valuecompare/` finds nothing; T-1 still passes; scripts/check-pr.sh PASS.

**F-2 — T-6 proves "each as-of once" without a wall-clock gate** (from CON-2)
Files: `core/database/conclusionsummaries/conclusionsummaries_test.go`, and a test hook or counter only if the code already has a seam for it.
Failing test first: a version of `TestEventDatingManyAsOfs` that fails when the as-ofs are read twice (for example, temporarily call the read twice and see it go red; say how you showed it).
Do: assert the once-read structurally, e.g. `testing.AllocsPerRun` on `valuecompare.DatingOf` over 10,000 samples against a constant bound, or a count of date unmarshals through an existing seam. Keep the time check only as a generous bound (500 ms) or drop it. Keep the two-dates assertion.
Check: the test passes in a full parallel `go test ./...`; scripts/check-pr.sh PASS.

**F-3 — Swift tests state the dating Go sends** (from MNT-2, CON-3)
Files: `macos/ProvenenciaTests/EventDetailTests.swift`.
Do: `dated(…)` takes `dating: CatalogEventDating = CatalogEventDating()` and no longer derives one; every caller passes the literal dating it means with the memberwise initializer, as `PersonsListTests.eventsRowSecondLine` does. Expectations unchanged.
Check: `grep -n "openLow: start == nil" macos/ProvenenciaTests` prints nothing; xcode-test passes.

**F-4 — Delete the dead `subjectcompare.Samples`** (from MNT-1)
Files: `core/subjectcompare/pairs.go`.
Do: delete `Samples`; move the "one reading of a side's samples" line onto `PeriodSamples`. Drop `samplesAgainst`'s now-redundant `p.Samples == ""` check only if `PeriodSamples` already returns nil for it (MNT-7).
Check: `rg -n '\bSamples\(' core api --type go | grep -v 'PeriodSamples\|CountSamples\|SamplesAgainst'` prints nothing; go test passes.

**F-5 — Pin where a span over the birth sorts** (from CON-4)
Files: `core/database/persondetail/` the `TestPersonEvents` table.
Failing test first: none (pins today's branch behavior). Add a row: born 1955, residence start 1950 end 1970 → the residence sorts just after the birth; and an as-of residence 1950/1970 → the same.
Do: add the rows; add one line to the plan's Landed differences: "a span whose dates overlap the birth now sorts after the birth (its `Days` cover the span)".
Check: the rows pass; scripts/check-pr.sh PASS.

**F-6 — Tidy the new dating code** (from MNT-4, CON-5, MNT-5, MNT-6)
Files: `core/valuecompare/dating.go`, `core/database/conclusionsummaries/compose.go`, `events.go`.
Do: drop `datingSample.original`. In `placeDating`, borrow once (`if !lowOK { low = high }; if !highOK { high = low }`) and use `low.span.From` / `high.span.To`. Fix `EventSummary`'s doc: places fold at `Dating.Low`, else `High`.
Check: go test passes; scripts/check-pr.sh PASS.

## Round 1 — fix
Head `8b149ac82`. Gate PASS (orchestrator run; xcode-test 68s). F-1 – F-6 done. Deviations: F-1 adds `key.Side` as the last value rank before index (the fuzz found `bef 1` vs `1`, equal in four bounds, open on different sides); `FuzzDatingOf` lives in its own `fuzz_dating_test.go`; F-2's allocation bound is on `DatingOf` (no unmarshal seam; `keptDates` not covered); a stray `sed` edit in F-2 was caught by go-test and reverted in `8b149ac82`.
SEC-1 (minor): **Resolved** — read `core/valuecompare/fuzz_dating_test.go`: no-panic over odd kinds, qualifiers and int32 extremes, plus a shuffle check on Low/High ends and nil High; 30 s fuzz found nothing.

## Round 2 — review
Scope `b994dadf2...8b149ac82`. Reviewers: CON (CON-1, CON-2 majors), MNT (MNT-1, MNT-2, MNT-3 majors). Not sent: UX (only a minor, Later PR), SEC+PRF (only SEC-1 minor, resolved above).

Round-1 majors: CON-1 **Resolved** (CON's own 300,000-case shuffle probe, bad=0; `TestDatingOfOrderFreeWhenOnlyOneSideTies`, `FuzzDatingOf`). CON-2 **Resolved** (one `DatingOf` = 20 allocs, two = 40 > 30). MNT-1, MNT-2 **Resolved**. MNT-3 **Resolved as written**, but its fix is MNT-11.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-11 | MNT | blocker | The dating has its own extreme-sample picker beside `SampleExtremes` | Fix now → F-7 | Verified: `dating.go` `pickSamples` / `endsFirstBefore` / `startsLastAfter` no longer call `SampleExtremes`; their first keys are `SampleExtremes`' (`lo.Hi` lowest, `hi.Lo` highest); `rg 'SampleExtremes\('` finds only `pairs.go:114`. D-3 and the batch rule "reusing `SampleExtremes`" (map line 185, `event-as-of.md`) no longer describe the code |

Nits (logged): `CON-7 · conclusionsummaries_test.go:1885-1886 · "would pass" means "would exceed"`

### Fix plan 2

**F-7 — One extreme-sample picker, each caller supplying its tie** (from MNT-11)
Files: `core/valuecompare/datewindow.go`, `core/valuecompare/dating.go`, `core/subjectcompare/pairs.go`, their tests; doc lines in `docs/matching-model.md` or `docs/deployment-plan/spike-16/event-as-of.md` only if they describe `SampleExtremes`' signature. Skill: `add-match-rule`.
Failing test first: none new (a refactor); `FuzzDatingOf`, `TestDatingOfOrderFreeWhenOnlyOneSideTies`, `TestDatingOf`, `TestCompareSamples` and the graphalign goldens are the guard and must stay green unchanged.
Do: give `SampleExtremes` the tie rule as parameters, e.g. `SampleExtremes(firsts, lasts []DateEnd, endsTie func(i, j int) int, startsTie func(i, j, endsFirst int) int)`: among closed samples tied on the primary key (equal `lasts[].Hi` for endsFirst, equal `firsts[].Lo` for startsLast), `i` replaces the current pick when its tie result is < 0; nil or 0 keeps the lower index. endsFirst is chosen first and passed to startsTie. Then:
- `pickSamples` calls `SampleExtremes(his, los, …)` with ties that carry the rest of today's chain (ends first: `lo.Lo`, `hi.Lo`, `hi.Hi`, `key.Side`; starts last: `hi.Hi`, the low pick's class, `lo.Hi`, `lo.Lo`, `key.Side`, as `endsFirstBefore` / `startsLastAfter` rank today). Delete `endsFirstBefore` / `startsLastAfter` as separate pickers if they become tie functions only.
- `samplesAgainst` passes `propertycompare.KeyCompare` as its tie for both picks; delete `lowestKey`.
- Update `SampleExtremes`' doc (its callers, `DateEnds` for display and `AboutEnds` for compare, and the tie parameters). Add one line to the plan's Landed differences: "`SampleExtremes` takes each caller's tie rule (S16-42 review MNT-11)".
Check: `rg -n 'SampleExtremes\(' core` shows the two callers (`dating.go`, `pairs.go`) and tests; `rg -n 'func lowestKey|func endsFirstBefore|func startsLastAfter' core` prints nothing (or only tie helpers passed into `SampleExtremes`, not scans of their own); `go test -fuzz FuzzDatingOf -fuzztime 30s ./core/valuecompare/` finds nothing; scripts/check-pr.sh PASS.

## Round 2 — fix
Head `c2c014a6c`. Gate PASS (orchestrator run). F-7 done, no deviations.
MNT-11: **Resolved** — read the diff: `SampleExtremes(firsts, lasts, endsTie, startsTie)` is the one picker; `pickSamples` passes the dating's value chain (same ranks as the deleted `endsFirstBefore` / `startsLastAfter`); `samplesAgainst` passes `KeyCompare` for both (same picks as the deleted `lowestKey`); `TestDatingOf`, `TestCompareSamples`, graphalign goldens unchanged and green; 30 s fuzz 2.57M execs clean.

## Finish
Merged `origin/main` @ `f12ff7633` (docs only, clean); head `0e1b1e430`; gate PASS against `f12ff7633`. PR body updated.

## Result
Gate PASS · CI see PR #876 · open: none · follow-ups: none · to user: CON-4 (span over the birth sorts after it) — kept (user, 2026-11-17)
