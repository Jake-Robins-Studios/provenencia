# Ship log — S16-69 A commit runs each effects lookup once

**Plan:** [`S16-69-effects-lookup-once.md`](S16-69-effects-lookup-once.md) · **Branch:** `s16-69-effects-lookup-once` · **PR:** #979
**State:** ready

## Round 0 — implement
Head `458302a11`. Report: no deviations. Noted outside the plan: `go build ./...` fails in `bin/reseed-source-vocab` (`vocabkey.MetadataLevels` undefined), same on `main`; `promotealign` `TestListMergeMatchesReload` W4 read 23ms against a 20ms wall-clock budget once in a broad run (not rerun).
Orchestrator gate on `458302a11`: PASS.

## Round 1 — review
Reviewers: CON, MNT, SEC+PRF. Skipped: UX (no `macos/App/**`, strings, or error codes).
CON: clean (mutation check run on an archive copy: memo bypass fails all three T-1 cases at the plan's counts). SEC+PRF: no findings in either lens. CON notes `bin/reseed-source-vocab` is untracked, so its build failure is a local leftover, not on `main`.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | minor | Stale "No write calls Handles yet" comment in a touched test file | Fix now → F-1 | verified: `handle_paths_test.go:37-38`; file changed by this PR |

Nits (logged): `MNT-2 · core/database/effects/resolve.go:67 · error text "effects: nil tx" vs Querier param (D-4 kept it)` · `MNT-3 / CON-2 · core/database/deleteimpact/facets.go:34 · rewrap the reworded comment line` · `CON-1 · core/database/effects/lookup_once_test.go:21 · T-1 is three t.Run blocks, not table-driven; acceptable`

### Fix plan 1
**F-1 — Name what TestHandlePaths resolves** (from MNT-1)
Files: `core/database/effects/handle_paths_test.go`.
Failing test first: none (comment only).
Do: replace lines 37-38 with "TestHandlePaths resolves `Effect.Handles` through `Resolve` (`Set.Handles`) against a catalog; these checks are the rules the registry states." Drop "No write calls Handles yet". While in the area, rewrap `core/database/deleteimpact/facets.go:34` to the surrounding width (MNT-3 / CON-2 nit, comment only).
Check: scripts/check-pr.sh PASS.

## Round 1 — fix
Head `84fa1e75d`. Gate PASS. F-1 done (comment only). MNT-1 **Resolved**: read the fix commit; the comment names `Effect.Handles` through `Resolve` (`Set.Handles`) and the stale line is gone; `facets.go:34` rewrapped.
No round 2: no Fix-now blocker or major in round 1.

## Result
Gate PASS · CI pending · open: none · follow-ups: none · to user: —

## Cost
Plan: 3,766 words (check-plan-docs info line).

| Round | Agent | Model | Tokens |
| --- | --- | --- | --- |
| 0 | implementer | sonnet | 139k |
| 1 | CON | opus | 58k |
| 1 | MNT | opus | 56k |
| 1 | SEC+PRF | opus | 55k |
| 1 | implementer (fix) | sonnet | 68k |
| | **Total** | | **376k** |
