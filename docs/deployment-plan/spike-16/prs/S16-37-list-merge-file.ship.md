# Ship log — S16-37 The list merge has a file of its own and no test-only parameters

**Plan:** [`S16-37-list-merge-file.md`](S16-37-list-merge-file.md) · **Branch:** `s16-37-list-merge-file` · **PR:** #858
**State:** ready

## Round 0 — implement
Head `3e49bc83f`. Gate PASS (orchestrator, against `0a90a171a`). Report: `main` had moved past the Planned commit (`04e76c4` → `0a90a171a`, S15-12's edits sit after the moved block, so no stop); `listRowsLargeWriteTakesTheOnePass`'s `best` now takes a closure; no Landed note (code matches the plan); manual check §10 steps 2–3 not run by the implementer. Figures: one pass 42.6 ms vs chosen 56.2 ms (200 ids, 20,115 rows); indexed 7.0 / 27.9 ms, fallback 34.4 / 113.9 ms (20,115 / 80,000 rows).

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. UX: the diff touches `macos/App/**` (no copy or views; dispatched on the path rule). SEC+PRF: list and cache code under `macos/App/Features/**` (performance paths); no security path touched.
The first conformance reviewer was interrupted before it read the diff; a fresh one ran in its place.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | major | The new one-pass timing loop is a fourth best-of-N copy beside a closure-taking `best` with one caller | Fix now → F-1 | verified: `CatalogListMergeTests.swift` has four `ContinuousClock().measure` loops of the same shape (lines 235, 244, 336, 354); this PR adds the 244 copy and reshapes 235 and 354, so it is a same-pass cleanup |
| CON-1 | CON | major | The plan has no Landed note, though the work differs from the plan (also MNT's Outside my lens note) | Fix now → F-2 | verified: `rg '\*\*Landed\.'` on the plan finds nothing; DoD line requires it; S16-26's plan line 18 is the shape |
| UX | UX | — | No findings | — | — |
| SEC/PRF | SEC+PRF | — | No findings | — | — |

Nits (logged): `MNT-2 · macos/ProvenenciaTests/CatalogListMergeTests.swift:357 · count - dropped.count + 1 differs from D-7's count - 16; equivalent, record it in the Landed note`

### Fix plan 1

**F-1 — One best-of-N timing helper in `CatalogListMergeTests`** (from MNT-1)
Files: `macos/ProvenenciaTests/CatalogListMergeTests.swift`. Skill: `add-swift-test`.
Failing test first: none (test-code refactor; the claims and bounds stay).
Do: add one `private static func bestMilliseconds<V>(_ start: V, runs: Int, _ run: (inout V) -> Void, count: (V) -> Int, expected: Int) -> Double` (or an equivalent shape: copy `start` outside `ContinuousClock().measure`, run inside, keep the min over `runs`, `#expect(count(copy) == expected)` each run) beside `milliseconds`. Route all four loops through it: `listRowsLargeWriteTakesTheOnePass` calls it twice, once on `list.rows` with `$0.mergeSorted(fresh, replacing: ids)` and once on `list` with `$0.merge(fresh, replacing: ids)`, each 3 runs, expected `count - 100`; delete the local `best`, `onePassBest` and the `onePass` alias. `bestMergeMilliseconds(rows:)` and `bestMilliseconds(rows:indexed:)` keep their names, inputs and 5 runs but call the helper for the loop (rename the new helper if its name clashes). Keep every test name, seed, row count, bound, `print` and `// decided:` comment.
Check: `grep -nE "ContinuousClock\(\)\.measure" macos/ProvenenciaTests/CatalogListMergeTests.swift` prints exactly one line (inside the new helper); `-only-testing:ProvenenciaTests/CatalogListMergeTests` passes, figures in the report; scripts/check-pr.sh PASS.
Commit: "Time the list merge tests through one best-of-N helper."

**F-2 — Landed note on the plan** (from CON-1, MNT-2)
Files: `docs/deployment-plan/spike-16/prs/S16-37-list-merge-file.md`.
Do: after F-1, add a `**Landed.** Differences from the plan: …` line directly under the header block (S16-26's plan line 18 is the shape). List: base moved from `04e76c4` to `0a90a171a` (S15-12's edits sit after the moved block; no stop); the timing loops in `CatalogListMergeTests` share one best-of-N helper (S16-37 review MNT-1), so `listRowsLargeWriteTakesTheOnePass` times both paths through it rather than D-7's `best` and an inline loop; `bestMilliseconds(rows:indexed:)` checks `count - dropped.count + 1` (equal to D-7's `count - 16` on the fallback and `count - 1` indexed); the `add-workspace-place` line 178 wording is ", whose row also conforms to `CatalogListRow` in `CatalogListMerge.swift`" rather than D-9's exact text. Do not list the manual check (the user runs it).
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-37-list-merge-file.md` reports no errors; scripts/check-pr.sh PASS.
Commit: "Record S16-37's differences from its plan."

## Round 1 — fix
Head `470bb2ad1`. Gate PASS (orchestrator). F-1 done (`08e166e92`: `bestOfMilliseconds<V: Collection>(_:runs:expected:_:)`, named so to avoid `bestMilliseconds(rows:indexed:)`; one `ContinuousClock().measure` left, line 342). F-2 done (`470bb2ad1`). Figures: one pass 37.0 ms vs chosen 42.8 ms (200 ids, 20,115 rows); `mergeSorted` 26.3 / 72.5 ms; indexed 6.7 / 25.9 ms; fallback 32.4 / 113.0 ms (20,115 / 80,000 rows).

## Round 2 — review
Reviewers: CON (CON-1 major), MNT (MNT-1 major). Scope `3e49bc83f...470bb2ad1`. UX and SEC+PRF had no findings, so they do not return.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | major | Landed note | Resolved | plan line 18 lists the four differences; checked against code and skill line 178 |
| MNT-1 | MNT | major | Fourth best-of-N copy | Resolved | one `ContinuousClock().measure` left, line 342, inside `bestOfMilliseconds`; all four loops call it |

No new blockers. No Fix plan 2.

## Result
Gate PASS at `470bb2ad1` · `origin/main` unmoved since the branch was cut (`0a90a171a`) · CI pending · open: none · follow-ups: none · to user: none
