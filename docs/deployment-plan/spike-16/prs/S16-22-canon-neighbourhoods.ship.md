# Ship log — S16-22 Promote reads each handle's neighbourhood instead of walking the catalog

**Plan:** [`S16-22-canon-neighbourhoods.md`](S16-22-canon-neighbourhoods.md) · **Branch:** `s16-22-canon-neighbourhoods` · **PR:** #844
**State:** ready

## Round 0 — implement
Head `83773987f`. Gate PASS (orchestrator run, against `bb94086cf`). PR #844 (draft).
Report deviations: base benchmark run on this checkout at the base commit instead of a second worktree (memory: ask before any worktree); figures from an Apple M1, not the plan's Xeon (budget comment and `promote-ranking.md` keep the plan's Xeon text per D-13, D-15); STEP-4's `Canon\{` grep also matches the unrelated `graphcachetest.Canon`; manual check (§10) not run in the app; `canonView` sets a Subject's `ranked` entry only when it has candidate ids.

## Round 1 — review
Reviewers: CON, MNT, SEC+PRF (`core/database/**`, `core/kinship`, `core/graphalign`, `core/database/canonlinks`). Skipped: UX (no `macos/App/**`, strings, `core/apperr`, or error codes).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1, MNT-1 | CON, MNT | major | `CanonView` doc lacks D-6's error-holding sentence | Fix now → F-1 | verified: `core/graphalign/types.go:27-39` unchanged; `rg "first error\|serves nothing" core/graphalign` empty |
| CON-2 | CON | minor | No test reaches the held read error in `alignRows` | Fix now → F-2 | code this PR adds (`canon.go` `v.err`, `promotealign.go:83`); no test names it |
| MNT-2 | MNT | minor | `edgeOf` has one caller, `deriver.edge`, which passes its own fields | Fix now → F-3 | verified: `canonlinks.go:51`, only call `reader.go:166`; same-pass, files this PR changes |
| MNT-3 | MNT | minor | `relationshipEdges` repeats `filedEdges` with a filter | Fix now → F-4 | verified: `reader.go:174-204`, bodies differ only by the bridge filter |
| CON-3 | CON | nit→minor | Package doc not D-9's text | Fix now → F-1 | stale comment in a file this PR changes; `types.go:3` still names S9-42 |
| CON-5 | CON | nit→minor | `completed.md` calls 0.7 MB "kinship pivots" | Fix now → F-5 | `catalog-caches.md:13` says 0.68 MB is with the proposal's other caches |

Nits (logged): `MNT-4 · perf_test.go:833 · bytes.Equal for Edge.A/B` · `MNT-5 · canon.go canonView.Links · a link whose From is not ok is dropped silently` · `CON-4 · perf_test.go budgetWarm comment · (2026-11-15) is the planning date` · `CON-6 · promote-ranking.md:23 · quotes the planning Xeon figures; D-15 dictated that text`

SEC+PRF: no findings (warm 16.5 / 18.2 ms at 4,000 / 16,000; base 110 ms at 4,000).

### Fix plan 1
**F-1 — State D-6's error rule on `CanonView` and D-9's package doc** (from CON-1, MNT-1, CON-3)
Files: `core/graphalign/types.go`.
Do: add D-6's sentence word for word to the `CanonView` doc: "A view that reads lazily and can fail holds its first error for its caller and serves nothing after it; Align does not see errors." Replace the package doc's "S9-42 loads a Layer and serves a CanonView, then calls Align" with D-9's "Promote loads a Layer and serves a CanonView, then calls Align".
Check: `rg -n "first error" core/graphalign/types.go` prints the line; scripts/check-pr.sh PASS.

**F-2 — Test the held read error** (from CON-2)
Files: `core/database/promotealign/promotealign_test.go` or `export_test.go`.
Failing test first: a table row where the view's `canonlinks.Reader` fails (a node source or graph that returns an error on a link read); assert `alignRows` (or `Propose`) returns that error and an empty proposal. Prove it red by temporarily removing the `view.err` check at `promotealign.go:83`, then restore.
Do: reuse an existing error-injecting graph or node-source seam if one exists; add only a test seam in `export_test.go` if needed. If no failure can be injected without a production seam, stop and report rather than adding one.
Check: the test passes; scripts/check-pr.sh PASS.

**F-3 — Fold `edgeOf` into `deriver`** (from MNT-2)
Files: `core/database/canonlinks/canonlinks.go`, `core/database/canonlinks/reader.go`.
Do: make `edgeOf` a `deriver` method (or inline it into `deriver.edge`) that reads `d.eventTypeProp` and `d.terms` itself; drop the "neighbor nil is allowed otherwise" caveat (D-2 removed it). No behavior change.
Check: `rg -n "edgeOf\(" core` shows no free-function call taking `eventTypeProp, terms`; canonlinks and persondetail tests pass; scripts/check-pr.sh PASS.

**F-4 — One filed-link loop** (from MNT-3)
Files: `core/database/canonlinks/reader.go`.
Do: one loop over `n.Links` that takes the bridge filter (empty key = every bridge); `filedEdges` and `relationshipEdges` become one-line calls to it.
Check: `TestLinks`, `TestRelationships` pass; scripts/check-pr.sh PASS.

**F-5 — Correct the memory sentence** (from CON-5)
Files: `docs/deployment-plan/spike-16/completed.md`.
Do: "A proposal fills 0.7 MB of kinship pivots instead of 7.8 MB" → say 0.7 MB is the proposal's caches with the pivots it reads (`BenchmarkCacheSizes` `evidence-B`), against 7.8 MB before, matching `docs/catalog-caches.md:13`.
Check: plan-docs PASS.

## Round 1 — fix
Head `fd128d102`. Gate PASS (orchestrator run). F-1 done (`ff18f4558`); F-3, F-4 done in one commit (`35cde227a`); F-5 done (`fd128d102`).
F-2 not done: the implementer found no way to fail a link read after the match index is warm without a new test hook (every handle's node and event neighbour is loaded when the index is built; a corrupted row fails in the index build instead, and a draft test still passed with the `view.err` check removed). F-2 forbade a new seam. CON-2 → **Follow-up** (a failing-reader test hook on `canonView`, so the held-error path gets a test), as the finding itself allowed when injection costs too much.

## Round 2 — review
Reviewers: CON, MNT (both had the Fix-now major CON-1 / MNT-1). Scope `83773987f...fd128d102`. SEC+PRF not sent: no Fix-now finding. Minor riders read by the orchestrator: CON-3 **Resolved** (`types.go:3` now names Promote), CON-5 **Resolved** (`completed.md` names the proposal's caches).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1, MNT-1 | CON, MNT | major | (round 1) `CanonView` error rule | Resolved | both reviewers: D-6's sentence on `CanonView` word for word (`types.go:27-30`) |
| MNT-2, MNT-3 | MNT | minor | (round 1) `edgeOf` fold, one loop | Resolved | MNT round 2: `canonlinks.go:52` method; `reader.go:173-200` `edgesOf` |

No new findings from either reviewer.

Nits (logged): `CON-7 · canonlinks.go:48-51 · edgeOf doc "neighbor is the link's other end"; it is the event neighbour, nil otherwise`

## Result
Gate PASS · `origin/main` unmoved since the branch was cut (`bb94086cf`) · CI see PR · open: none · follow-ups: CON-2 dropped (user, 2026-11-15: the held-error path is unreachable on a warm index) · to user: —
