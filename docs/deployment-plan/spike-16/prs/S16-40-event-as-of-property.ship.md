# Ship log — S16-40 An event records As of dates, and matching reads them as bounds

**Plan:** [`S16-40-event-as-of-property.md`](S16-40-event-as-of-property.md) · **Branch:** `s16-40-event-as-of-property` · **PR:** #869
**State:** ready

## Round 0 — implement
Base `754d8f6c2` (plan written at `14fbfca`; base check passed). Head `51ff5742f`, PR #869 (draft). Gate PASS (orchestrator, against `754d8f6c2`). Report: no stop; deviations: `LifeEventOf` reads `p.Samples` from the event's values rather than calling `subjectcompare.Samples` (that takes a `Rules` map; D-10 gives it a `Period`); added test helpers `sampled`, `TestCompareSamples`, `permutationsOf`. §10 manual check not run. Goldens unchanged.

## Round 1 — review
Reviewers: CON, MNT, SEC+PRF (matching layers `core/subjectcompare`, `core/shortlist`, `core/propertycompare`, `core/matchregistry`, `core/subjectprofile`, `core/valuecompare`; as-ofs are a `multiple` list loaded from the catalog). Skipped: UX (no `macos/App/**`, strings, or error codes; the pbxproj change is the version bump only).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| SEC-1 (PRF) | SEC, PRF | major | `samplesAgainst` copies, keys and sorts every as-of again for each compared pair, with no bound | Fix now → F-1 | verified: `pairs.go:69-110`; `Samples` runs before the `other[key]` early return; sort + `Key` per sample per pair; reviewer measured 14.6 ms/pair at 10,000 as-ofs, 74.6 ms at 40,000 (Scale crafted: 10,000 "only has to stay bounded") |
| MNT-2 | MNT | blocker→major | `samplesAgainst` copies propertycompare's `keyed` and `keyBefore` ordering | Fix now → F-1 (same-pass cleanup) | verified: `pairs.go:96-106` vs `propertycompare.go:261-266`; `pairOf` repeats `split`'s keying. Rated major: one ordering in two places, not a defect today |
| MNT-1, CON (outside lens) | MNT, CON | blocker→major | `LifeEventOf` re-implements `Samples`' positive-sample read | Fix now → F-2 (same-pass cleanup, within D-10's signature) | verified: `subjectprofile.go:57-63` vs `pairs.go:43-55`. The reviewer's fix changes D-10's signature; F-2 keeps D-10's `Period` parameter and shares the body instead, so no Decision moves |
| PRF-1 | PRF | major→minor | An as-of-only event is an open reach: shortlisted by every probe of its type and vice versa | Rejected (D-9 stands); narrower keying → Follow-up | verifier measured `BenchmarkLargeSourcePropose` (rank of all 100 Source A Subjects, memo cleared) at Batch 2 Scale: base 289/567 ms (4k/16k), head 308/600, head with 30% of town deaths as-of-only 329/610 (+7%, +16% event candidates, ≈14.6 extra compares per as-of event, linear in as-of events not catalog size). D-9's rejected alternative (samples' years ±MaxYears) exceeds `MaxBuckets` and gives identical keys. Unexplained: `warm-ms` +3.5 ms once any death is as-of-only, flat with share. Results: scratchpad `results.txt` |
| CON-1, MNT-5 | CON, MNT | major | Plan marked Landed with no Landed note; §10 not run | Fix now → F-3 | verified: plan line 3 is the only plan change |
| MNT-3 | MNT | minor | `samplesAgainst` re-derives the stand-in's open end that `period` knew | Fix now → F-1 | verified: `pairs.go:83-89` |
| CON-2 | CON | minor | The invariants' `as_of` pool never yields a sample-made conflict | Fix now → F-4 | reviewer probe: 0 sample-made conflicts in 200,000 draws; pool `invariants_test.go:71` |
| SEC-2 | SEC | minor | No fuzz target over the new compare path | Fix now → F-4 | new code comparing catalog values; reviewer's 200,000-case probe found no panic, guard missing |
| CON-3 | CON | minor | `matching-model.md` says an as-of inside a closed period "agrees"; it is partial | Fix now → F-5 | verified: AC-3.4 test asserts partial |
| MNT-9 | MNT | nit→minor | `matching-model.md` lifespan row omits closed as-ofs | Fix now → F-5 | stale doc line in a file this PR changes |
| MNT-4, CON-4 | MNT, CON | minor | `ev`'s doc comment now sits on `sampled` | Fix now → F-6 | verified `helpers_test.go:103-111` |

Nits (logged): `MNT-6 · core/subjectprofile/subjectprofile.go:209-213 · closed-ends check written in both lifespan loops` · `MNT-7 · subjectcompare.go Meta doc, subjectprofile.go lifespan doc · rewrap long lines` · `MNT-8 · core/shortlist/shortlist.go:112-113 · lo, hi, open only unpack rc` · `CON-5 · core/valuecompare/datewindow_test.go:438 · "none closed" uses an empty list; add [BEF 1995] → 0, -1`

### Fix plan 1
**F-1 — Pick a side's extreme samples in one linear pass, cheap checks first, one high cap; one Same-key ordering** (from SEC-1, MNT-2, MNT-3)
Files: `core/subjectcompare/pairs.go`, `core/propertycompare/propertycompare.go`, tests beside them. Skill: `add-match-rule`.
Failing test first: `TestCompareSamples/many as-ofs` (or a `TestSamplesAgainstBounded`) — 10,000 as-ofs against a 1985–2000 period; assert the result equals the 20-as-of extremes' result and that `samplesAgainst` does no `Samples` copy when `other[key]` has a positive value (e.g. an allocation count with `testing.AllocsPerRun`); and a row with more positive samples than the cap returns `base` unchanged whatever the input order.
Do:
- In `samplesAgainst`, check `other[key]` for a positive value and build `period(...)` **before** calling `Samples`.
- Have `period` return whether the stand-in has an open end (MNT-3); `Side`, its other caller, ignores it. Drop the `DateEnds` re-read.
- One order-free cap, named and documented in the package (e.g. `maxSamples = 1000`, well above the Scale's 20): when a side has more positive samples than the cap, the sample check for that side is skipped (returns nil, so `base` stands). Never keep the first k. Per working rule "caps for adversarial-only costs": one high total cap, not a design.
- Replace the per-sample `Key` + sort with one pass: read each sample's `AboutEnds`, find the extremes through `valuecompare.SampleExtremes` (keep it the one selection rule D-6 names, S16-42 reuses it), then break a tie on the extreme `Hi` / `Lo` by the lowest Same key, computing `valuecompare.Key(propertycompare.Typed(v, meta).Value, ...)` only for the tied samples. The pick must not depend on input order (T-4's every-order rows stay green).
- MNT-2: in `propertycompare`, add one `keyOf(v Value, rules valuecompare.Rules) keyed` used by `split` and `pairOf`, and export the ordering once (e.g. `KeyCompare(x, y Value, rules valuecompare.Rules) int` built on `keyBefore`, or a typed-key helper). `samplesAgainst`'s tie-break uses it; remove the `sample.key`/`hasKey` fields and the local comparator.
Check: `rg -n "hasKey" core/subjectcompare` prints nothing; `rg -n "strings.Compare" core/subjectcompare/pairs.go` prints nothing; T-4 / `TestCompareSamples` / `TestInvariants` / goldens pass; scripts/check-pr.sh PASS.

**F-2 — One reading of a period's samples** (from MNT-1)
Files: `core/subjectcompare/pairs.go`, `core/subjectprofile/subjectprofile.go`.
Failing test first: none (refactor; `TestLifeEventOf` and `TestLifespanFromEvents` stay green).
Do: keep D-10's signature `LifeEventOf(event Values, role, lead, p subjectcompare.Period)`. Split `Samples` so its body is an exported `PeriodSamples(v Values, p Period) []propertycompare.Value` (positive values of `v[p.Samples]`, nil when `p.Samples` is empty); `Samples` looks up the period and calls it; `LifeEventOf` calls it and takes each `.Date` that is non-nil. Update the `Samples` doc ("the one reading … for compare, the shortlist and the lifespan").
Check: `rg -n "event\[p.Samples\]" core` prints nothing; `rg -n "\.Samples\]" core --type go | grep -v _test` prints only `PeriodSamples`; check-pr PASS.

**F-3 — Landed note** (from CON-1, MNT-5)
Files: the plan.
Do: under the header add a `**Landed.**` note (S16-37 style) listing every difference: F-1's linear pick and cap (supersedes D-6's "sorts them"; same picks, order-free), F-2's `PeriodSamples` (D-10's signature kept), T-4's order rows in `TestCompareSamples` with `permutationsOf`, the `sampled` helper, T-7's "none closed" case, F-4's fuzz target, and that the §10 manual check was not run, so AC-1.2, AC-1.3, AC-1.4 and AC-2.3 are unverified until the user runs it.

**F-4 — Invariants reach the conflict branch; a fuzz guard** (from CON-2, SEC-2)
Files: `core/subjectcompare/invariants_test.go`, a new `FuzzCompareProperty` in `core/subjectcompare` (or beside the invariants).
Do: add as-ofs outside every period the pools can build (e.g. `year(1805)`, `year(1830)`) to the `as_of` pool, and confirm at least one sample-made conflict is drawn (a counter in the test). Add `FuzzCompareProperty` over event pairs carrying as_of / start / end / date with extreme years (0, ±1, MaxInt32, MinInt32), inverted ranges, unknown qualifiers and kinds: no panic, `Compare(a,b)` mirrors `Compare(b,a)`, shuffled values give the same result. Seed corpus in the test; it runs as a unit test under `go test`.
Check: `go test ./core/subjectcompare/...` passes; check-pr PASS.

**F-5 — matching-model.md** (from CON-3, MNT-9)
Files: `docs/matching-model.md`.
Do: line ~76: "one inside a period closed on both ends matches (usually partial: contains); a half-open period bounds but never matches." Line ~79 lifespan row: add "and closed as-ofs, which never fix a start or an end".

**F-6 — `ev`'s doc comment** (from MNT-4, CON-4)
Files: `core/subjectprofile/helpers_test.go`. Do: move `sampled` and its comment below `ev`.

## Round 1 — fix
Head `67e353501`. Gate PASS (orchestrator, against `754d8f6c2`). F-1 – F-6 done. Deviations: the cap is a registry knob `Period.MaxSamples` = 1000 (`core/matchregistry/subject.go`, knob-inventory row in `matching-model.md`) because `TestLayerPackages` forbids numeric literals in `core/subjectcompare`; the cap tests check a side at the cap (equals the extremes' result) and one over it in two orders (skipped, `base` stands), since F-1's 10,000-as-of row contradicted the cap; `export_test.go` exposes `samplesAgainst` for the alloc test; F-1's code was written before its test, then the tests were confirmed red against the old `pairs.go`; one added clause in `completed.md`.

## Round 2 — review
Reviewers: CON (CON-1), MNT (MNT-1, MNT-2), SEC+PRF (SEC-1). Scope `51ff5742f...67e353501`.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | major | Landed note | Resolved | Landed note lists every difference and the unverified ACs |
| MNT-1 | MNT | major | `LifeEventOf` sample read | Resolved | `PeriodSamples` is the one reader; `rg "\.Samples\]"` prints only it |
| MNT-2 | MNT | major | Same-key ordering copy | Resolved | `propertycompare.keyOf` / `KeyCompare`; `rg "hasKey\|strings.Compare" core/subjectcompare` empty |
| SEC-1 | SEC, PRF | major | Per-pair sample work unbounded | Resolved | reviewer re-measured per pair: 20 → 11 µs, 1,000 → 0.29 ms, 10,000 → 0.84 ms (was 14.6 ms), 40,000 → 3.7 ms (was 74.6 ms); 200,000-case probe: no panic, swap- and shuffle-free |
| MNT-3, CON-2, CON-3, SEC-2, MNT-4, MNT-9 | — | minor | round-1 minors | Resolved (orchestrator read F-1, F-4 – F-6 commits) | `period` returns `open`; pool gains 1805/1830 and `TestInvariantsReachSampleConflicts`; `FuzzCompareProperty`; doc rows reworded; `ev` comment restored |
| SEC-3 | SEC, PRF, MNT/CON (outside lens) | minor | `PeriodSamples` copies every positive sample before the `MaxSamples` check, in `samplesAgainst` (≈5.6 MB per pair at 10,000) and in shortlist `Keys` (once per Subject) | Follow-up | linear and bounded; round 2 raises only blockers. Fix: count positives before copying |

Nits (logged): none.

## Result
Gate PASS (`67e353501`, against `754d8f6c2`; `origin/main` unmoved) · CI green (test ×2, localizable) · open: none · follow-ups: SEC-3 (count before copy), PRF-1 narrower keying for as-of-only events (unexplained +3.5 ms warm), round-1 nits MNT-6–8, CON-5 · to user: — · §10 manual check not run (AC-1.2, AC-1.3, AC-1.4, AC-2.3 unverified)
