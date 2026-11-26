# Ship log — S15-30 The paged fold moves to the kit

**Plan:** [`S15-30-show-more-row-kit.md`](S15-30-show-more-row-kit.md) · **Branch:** `s15-30-show-more-row-kit` · **PR:** #996
**State:** ready

## Round 0 — implement
Head `59ef684cb`. Report: implementer's gate PASS; deviations: kit commit `98d25b8ce` does not build alone (strings land in the next commit); extra commit `d333cc4f2` waits for layout in T-4 after one failure; implementer re-ran a gate past a `CatalogListMergeTests.listRowsLargeWriteTakesTheOnePass` timing failure (outside this PR).
Orchestrator gate 1: **FAIL** — `PVShowMoreRowHostedTests.revealScrollsAfterTheCallerLeaves` (`PVShowMoreRowTests.swift:78`, `visible` false after 10.7 s under the full parallel run). Second T-4 failure: the test is timing-dependent. Sent back as gate-fix 1: make it deterministic, no repeat runs.

### Gate fix 1
**F-0 — T-4 passes by construction, not by timing** (gate 1 failure)
Files: `macos/ProvenenciaTests/PVShowMoreRowTests.swift`, and `PVShowMoreRow`'s reveal provider (`pvScrollsShowMoreReveals`) only if the test cannot observe the held request otherwise. Skill: `add-swift-test`.
Failure: `PVShowMoreRowTests.swift:78` `Expectation failed: visible` after 10.7 s in the full parallel `xcodebuild test` (it passed when run alone and in the implementer's last gate). The test depends on a `DispatchQueue.main.async` hop, SwiftUI's scroll animation, and an `eventually` poll racing a loaded machine.
Do: find why the scroll did not land under load (no animation disabled? the async leave racing the provider's onChange? `eventually`'s budget?) and remove the timing dependency: drive the updates explicitly (e.g. pump layout / await the provider's held request between steps, disable animation in the harness with a `Transaction`), so the outcome does not depend on scheduler speed. Do not re-run the suite to "see if it passes"; do not raise a timeout as the fix. Keep what T-4 proves: a caller that asks and leaves the tree in the same update still gets the scroll.
Check: the test passes; scripts/check-pr.sh PASS once.

Gate fix 1: head `f5a15cc5c`. Not reproduced alone; fixed by inspection — the reveal's `withAnimation(PVMotion.fastStandard)` scroll has no display link in a never-shown window, so the harness now disables animations (`.transaction { $0.disablesAnimations = true }`). No production code changed. Orchestrator gate 2: **PASS**.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF (route-reviewers: all RUN). Base `4f0806f6c`, head `f5a15cc5c`.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | major | Plan has Landed status but no Landed note | Fix now → F-1 | verified: plan ends at `## 13. PR`; DoD line 253 asks for the note; S15-59 precedent |
| CON-2 | CON | major | T-4 leaves via `DispatchQueue.main.async`, not the same update; still timing-dependent and does not pin D-5 | Fix now → F-2 | verified: `PVShowMoreRowTests.swift` harness `onChange` queues `probing = false` async; its own comment says "next update" |
| CON-3, UX-1 | CON, UX | nit → minor | Timeline `.more` comment names only the dated list | Fix now → F-3 | stale comment in a changed file (`PersonTimelineSection.swift:112`) |
| MNT-1 | MNT | nit → minor | `pendingReveal` doc still says "an unfold added" | Fix now → F-3 | stale comment in a changed file (`PersonTimelineSection.swift:72`) |

SEC+PRF: clean, no findings.

Nits (logged): `MNT-2 · PersonTimelineSection.swift:114 · comment that the .more row passes String ids for "$0.base as? String"` · `MNT-3 · PVShowMoreRow.swift:20 · revealedRow var → let` · `MNT-4 · PVShowMoreRow.swift:104 · provider keeps target + Int request; PVListScroll (PVNativeListBehavior.swift:4) is one value for both`

### Fix plan 1
**F-2 — T-4 asks and leaves in one action** (from CON-2)
Files: `macos/ProvenenciaTests/PVShowMoreRowTests.swift`. Skill: `add-swift-test`.
Failing test first: temporarily move the provider's target/request state into the caller (the design D-5 rejects) and show the reworked T-4 fails; then revert that.
Do: show the probe from the start; on `trigger.fired` the probe runs `reveal(AnyHashable(11))` then a `leave()` closure from `Harness` that sets `probing = false` synchronously, in the same action, as `PVShowMoreRow.press` does on the last page. Drop the `DispatchQueue.main.async` and fix the comment. Keep the animation-off transaction from gate fix 1.
Check: T-4 passes; scripts/check-pr.sh PASS.

**F-3 — Timeline comments say what the code does now** (from CON-3, UX-1, MNT-1)
Files: `macos/App/Features/Conclusions/PersonTimelineSection.swift`.
Do: line ~72 `pendingReveal` doc → the first item a keyboard Show more revealed, scrolled into view once placed. Line ~112 → "A keyboard Show more of the dated or undated list…". Optionally fold MNT-2's one-line note that the `.more` row passes `String` ids.
Check: scripts/check-pr.sh PASS.

**F-1 — Landed note in the plan** (from CON-1)
Files: `docs/deployment-plan/spike-15/prs/S15-30-show-more-row-kit.md`.
Do: after `## 13. PR`, add `## Landed` in the shape of `S15-59-locator-file-page-only.md`'s section, listing every difference from the plan: the kit commit `98d25b8ce` does not build alone (strings land in `9a003305f`); the extra T-4 layout-wait commit `d333cc4f2`; the T-4 harness turns animations off (gate fix 1) and, after F-2, how the probe asks and leaves; the Timeline's `.environment(\.pvShowMoreReveal, …)` sits on the `PVWidthBreakpoints` list beside `pvScrollsRowIntoView`; the §10 manual check was not run by the implementer. Do this last so it covers F-2.
Check: `python3 scripts/check-plan-docs.py <plan>` clean; scripts/check-pr.sh PASS.

## Round 1 — fix
Head `87a3ee755`. Gate PASS (orchestrator). F-2 done (`a1ed16eea`): probe shown from the start, asks and leaves in one action; red first against the D-5-rejected design (state in the probe), green after revert. F-3 done (`29bd09e0a`): **Resolved** (CON-3, UX-1, MNT-1) — read by the orchestrator; also carries MNT-2's String-id note. F-1 done (`87a3ee755`): `## Landed` added.

## Round 2 — review
Reviewers: CON only (the only lens with a Fix-now major). Scope `f5a15cc5c...87a3ee755`. Verdict: clean. CON-1 **Resolved** (`## Landed` at plan line 293, check-plan-docs clean). CON-2 **Resolved** (probe asks and leaves in one action on appear; no async hop; animation off; still pins D-5).

Nits (logged): `CON-4 · PVShowMoreRowTests.swift:62 and plan ## Landed · the layout-wait comment says the list is laid out before the probe asks; since F-2 the probe asks inside the first layout pass, so the d333cc4f2 wait now only confirms the rows exist`

## Finish
`origin/main` moved (`70f8a08fa`, docs only: S16-79 plan); merged into the branch. Gate PASS against `70f8a08fa`.

## Result
Gate PASS · CI see PR #996 · open: none · follow-ups: `CatalogListMergeTests.listRowsLargeWriteTakesTheOnePass` timing assertion failed once under load in the implementer's round-0 gate (outside this PR; home to ask the user) · to user: —

## Cost
Plan: 4,091 words (check-plan-docs info line).

| Round | Agent | Model | Tokens |
| --- | --- | --- | --- |
| 0 | implementer | sonnet | 144k |
| gate fix 1 | implementer | sonnet | 78k |
| 1 | CON | opus | 87k |
| 1 | MNT | opus | 69k |
| 1 | UX | opus | 65k |
| 1 | SEC+PRF | opus | 55k |
| 1 fix | implementer | sonnet | 86k |
| 2 | CON | opus | 42k |
| | **Total** | | **627k** |
