# Ship log — S15-60 The seed has a page field

**Plan:** [`S15-60-seed-page-field.md`](S15-60-seed-page-field.md) · **Branch:** `s15-60-seed-page-field` · **PR:** #975
**State:** ready

## Round 0 — implement
Head `b864cd2ed`. Gate PASS (orchestrator's run). Deviations: version 0.43.0 (`main` was 0.42.0, as the header allows); map § 6.8's "entries for the 63 fields" line also edited; the version bump rides in the docs commit.

## Round 1 — review
Reviewers: CON, MNT, SEC+PRF. Skipped: UX (no `macos/App/**`, strings, or error codes).
Base `d35b4c4bc`, head `b864cd2ed`. Verdicts: CON clean (one minor); MNT changes needed; SEC+PRF clean, no findings.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT, CON (CON-1) | major | The map's lines 40, 1213 and 1216 still state or cite what § 6.9 replaced | Fix now → F-1 | Confirmed by reading; D-8 covers every doc the change makes false |
| MNT-2 | MNT, CON (CON-1) | minor | Live "63 fields" counts in `deployment-plan.md` 33 and 100 and `README.md` 16 | Fix now → F-2 | Confirmed; the rule, the Scale and the README describe today's seed. Lines 133 and 611 are S15-19's history and stay. STEP-5's "map row only" limit on `deployment-plan.md` is widened by D-8 |

Nits (logged): `MNT-3 · core/database/sourcevocab/registry_test.go:130 · build the expected unknown-text map once before the loop` · `CON · core/database/sourcemetadata/sourcemetadata_test.go:3271 · the message says "want suggested" but e.Suggested is not checked (TestSeedAnnotations covers it)` · `CON · evidence-explained-citation-map.md:1194 · two "and"s; a comma before the second part` (rides along in F-1)

### Fix plan 1
**F-1 — The citation map agrees with its § 6.9** (from MNT-1, CON-1)
Files: `docs/deployment-plan/spike-15/evidence-explained-citation-map.md`.
Failing test first: none (docs).
Do:
- § 1 levels table, Citation row, last cell → "What differs inside a graph: the printed page (the `page` field; a locator's `page_label` answers until S15-58), and any other item field set on the Citation (§ 6.9)".
- § 7 "Where the item lives" → "- ~~Where the item lives~~: at whichever level fits how the researcher filed, read nearest-first (user, 2026-11-22, § 6.9)."
- § 7 "Printed page map" → drop " (§ 6.9)".
- Status line (line 3): delete "The Citation composer gets no new fields."
- § 6.6 "Layout works as on the Source" (line 834): "The Citation composer gets none." → "The Citation composer gets one in S15-56 (§ 6.9)."
- § 6.10 `unknown_text` sentence → `("n.p." for `publication_place` and `publisher`, "unpaginated" for `page`)`.
Check: `rg -n 'composer gets no|the one item detail' docs/deployment-plan/spike-15/evidence-explained-citation-map.md` has no hit.

**F-2 — Live seed counts are not 63** (from MNT-2, CON-1)
Files: `docs/deployment-plan/spike-15/deployment-plan.md`, `docs/deployment-plan/spike-15/README.md`, the plan's Landed note.
Failing test first: none (docs).
Do: `deployment-plan.md` rule "The seed is the product default": "The 26 types, 63 fields, suggestions and formats of map § 6.8" → "The types, fields, suggestions and formats of map § 6.8". Scale: "**26 types and 63 fields**" → "**26 types and 69 fields**". `README.md`: "26 types, 63 fields and their formats" → "26 types, 64 fields and their formats". Landed note: one line naming the docs F-1 and F-2 changed beyond STEP-5.
Check: `rg -n '63 fields' docs -g '!**/prs/*'` prints only `deployment-plan.md`'s S15-19 map row and scope entry and, if it hits, S15-19's `completed.md` paragraph; scripts/check-pr.sh PASS.

## Round 1 — fix
Head `0a4a52a30`. F-1 and F-2 done in one docs commit. F-1 gained two edits mid-round (status line 3 and § 6.6), found while triaging. Gate PASS (orchestrator's run).

## Round 2 — review
MNT on `b864cd2ed...0a4a52a30`: MNT-1 Resolved, MNT-2 Resolved, no new blockers. Verdict clean.

## CI
Red on `820e15326`: `PVScrollMemoryHostedTests.anArrivalAheadOfItsLayoutDoesNotUseTheOldContent` (S16-72; this PR changed no Swift). Removed on this PR (user, 2026-11-25: it is flaky and the whole feature is going to change). The likely cause in `PVScrollMemoryCoordinator.restore()` is not proven and not fixed.

## Result
Gate PASS · CI: see the PR's checks · open: none · follow-ups: none · to user: —

## Cost
Plan: 4,415 words (check-plan-docs info line).

| Round | Agent | Model | Tokens |
| --- | --- | --- | --- |
| 0 | implementer | sonnet | 138k |
| 1 | CON | opus | 109k |
| 1 | MNT | opus | 90k |
| 1 | SEC+PRF | opus | 70k |
| 1 | implementer (fix) | sonnet | 76k |
| 2 | MNT | opus | 35k |
| | **Total** | | **518k** |
