# Ship log — S15-31 Event and Place rows open the provenance sheet

**Plan:** [`S15-31-event-and-place-provenance-sheet.md`](S15-31-event-and-place-provenance-sheet.md) · **Branch:** `s15-31-event-and-place-provenance-sheet` · **PR:** #1010
**State:** ready

## Round 0 — implement
Head `b0a01f4a4`. Gate PASS (orchestrator run: all ten checks). Report deviations: `main` was at 0.48.3, so the bump is 0.48.3 → 0.49.0; a third Why sentence in `conclusion-reconciliation.md` (landed after planning) reworded to satisfy STEP-6; the `nick`/`nicked` fixture in `PersonDetailTests.aMergedNameRowCarriesItsStateAndProvenance` deleted (unused after `whyTitle` went; failed swift-warnings). §10 manual check not run.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF (route-reviewers: UX on `macos/App/**` and strings; SEC+PRF on `conclusiondetails.go`, `ReconciledValueRowModel.swift`).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1, CON-2 | MNT, CON | minor | Six `PersonDetailTests` comments still name the Why | Fix now → F-1 | verified: `grep -n Why` at head prints 102, 477, 501, 680, 683, 756; minor in a file this PR changes |
| CON-1 | CON | minor | §9 sweep prints `SourceMoveModel.showsWhy`; Landed note silent | Fix now → F-2 | verified: Landed note (plan lines 32–36) has no line for it; STEP-1 keeps the name |
| UX-out (→ CON) | CON | minor | Event Place-row tests assert `records.isEmpty`, not `hasRecords` | Fix now → F-3 | verified: `EventDetailTests.swift:497`, `placeRowIsEmpty`; the control is decided by `hasRecords`, nothing asserts it |
| UX-1 | UX | minor | §10 keyboard/VoiceOver/visual check not run | Rejected | ship-pr step 8: the user runs the manual check; it goes in the report with "record focus after Done on Event, Place, Person" |
| PRF-1 | PRF | minor | A row past 2,000 distinct Citations opens a sheet with no records | Later PR (S15-29) | written into the S15-29 map scope entry's **Check** (deployment-plan.md); the host and `citationrender` cap are untouched here, Person rows already behave so, past Scale (1,200); S15-29 rebuilds the on-open call |

Nits (logged): `MNT-2 · EventDetailContent.swift:5, :116; conclusiondetails.go:5; PVProvenanceSheetContent.swift:4; ReconciledValueRow.swift:245 · rewrap long reworded comments` · `CON-3 · same as MNT-2` (rides along in F-1, comment-only)

### Fix plan 1
**F-1 — Reword the leftover Why comments; rewrap the long reworded comments** (from MNT-1, CON-2; nits MNT-2, CON-3)
Files: `macos/ProvenenciaTests/PersonDetailTests.swift` (lines 102, 477, 501, 680, 683, 756); `macos/App/Features/Conclusions/EventDetailContent.swift:5, :116`; `core/database/conclusiondetails/conclusiondetails.go:5`; `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheetContent.swift:4`; `macos/App/Features/Conclusions/ReconciledValueRow.swift:245`.
Failing test first: none (comments only).
Do: replace "Why" with "sheet" or "records" in each test comment, as STEP-5 did in the app (e.g. "No death event: no records.", "stated empty, with its records in the sheet."). Rewrap the five reworded doc comments to the neighboring lines' width; no wording change.
Check: `rg -nw Why macos/ProvenenciaTests` prints only `PVDisclosureButtonTests.swift:16`; STEP-5's `rg -nw "Why"` prints the same two lines as before; scripts/check-pr.sh PASS.

**F-2 — Landed note for the sweep's `showsWhy` hits** (from CON-1)
Files: the plan's **Landed** section.
Do: add one bullet: the §9 sweep's only hits are `SourceMoveModel.showsWhy` (`SourceMoveModel.swift`, `SourceMoveDialog.swift`, `SourceMoveModelTests.swift`), unrelated to the Conclusions Why, which STEP-1 keeps.
Check: scripts/check-pr.sh PASS (plan-docs).

**F-3 — Assert the Event Place row has no records control** (from UX outside-lens note)
Files: `macos/ProvenenciaTests/EventDetailTests.swift` (the derived Place-row test near line 497, and `placeRowIsEmpty`).
Do: add `!row.hasRecords` (and `recordCount == 0`) to each, beside the existing `provenanceContent().records.isEmpty`.
Check: `-only-testing:ProvenenciaTests/EventDetailTests` passes; scripts/check-pr.sh PASS.

## Round 1 — fix
Head `4778c40d7`. Gate PASS (orchestrator run). F-1 done (`457be37d6`; line 477 reads "owns their records"; the fix plan's line numbers for two long comments were stale, the implementer found them by diff: `EventDetailContent.swift` header and :100, `ReconciledValueRow.swift:63`, `conclusiondetails.go:5`, `PVProvenanceSheetContent.swift:4`). F-2 done (`e74a29699`). F-3 done (`4778c40d7`).
Orchestrator read of the fix commits: MNT-1/CON-2 **Resolved** (`rg -nw Why macos/ProvenenciaTests` → only `PVDisclosureButtonTests.swift:16`); CON-1 **Resolved** (Landed bullet); F-3 **Resolved** (`!hasRecords && recordCount == 0` in both tests).

## Round 2 — review
Not run: no reviewer had a Fix-now blocker or major in round 1.

## Result
Gate PASS · CI pending at time of writing · open: none · follow-ups: none · later PR: PRF-1 → S15-29 map Check · to user: — (§10 manual check is the user's)

## Cost
Plan: 5,355 words (check-plan-docs info line).

| Round | Agent | Model | Tokens |
| --- | --- | --- | --- |
| 0 | implementer | sonnet | 146k |
| 1 | CON | opus | 78k |
| 1 | MNT | opus | 77k |
| 1 | UX | opus | 67k |
| 1 | SEC+PRF | opus | 82k |
| 1 fix | implementer | sonnet | 76k |
| | **Total** | | **604k** |
