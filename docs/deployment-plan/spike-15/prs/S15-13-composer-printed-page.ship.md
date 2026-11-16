# Ship log — S15-13 The composer records the printed page

**Plan:** [`S15-13-composer-printed-page.md`](S15-13-composer-printed-page.md) · **Branch:** `s15-13-composer-printed-page` (stacked on `s15-50-forms-list-their-tab-order`, PR #862) · **PR:** #863 (base `s15-50-forms-list-their-tab-order`)
**State:** ready

## Round 0 — implement
Plan refreshed by the orchestrator against S15-50's head `a4ce91c61` (Status Blocked → Planned; no Decision or Step changed). Base for review: `a4ce91c61`.
Head `d59a74a4f`. Gate PASS (orchestrator run, `--base a4ce91c61`). Report deviations: `CitationStepMenu` also takes `model` and `ordered`; `CitationComposerEvidenceColumn` takes `formFocus: FocusState<CitationFormFocus?>.Binding`; field, layout, focus and menu share commit `e5294cdf7`. Not run in the app: manual check § 10 and board frames (1a, 1b, 7 `ViewThatFits` stacking; focus across 1600pt).

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. Skipped: none. SEC: `core/locator` (locator code, stored locator JSON). PRF: `core/database/graphfill`.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| UX-1 | UX | minor | "No page" depiction warnings contradict a typed printed page | Fix now → F-2 | verified: `depictionNeedsPage` / `depictionCaptionNeedsPage` unchanged; `depictionPageCheck` reads `locator.page`, nil for label-only (plan Reach row). New state from this PR; plan's Strings sweep named only `locatorPage` |
| MNT-1 | MNT | minor | Tab order worked out in two places (view `isShown` and column forms) | Fix now → F-1 | verified: `CitationComposerView.composeSplit` and `CitationComposerEvidenceColumn` each call `CitationFormFocus.order`; code this PR adds; S15-45 extends it |
| CON-2 | CON | minor | Menu-row test compares English literals | Fix now → F-3 | verified: `CitationComposerModelTests.swift:827-836` |
| CON-1 | CON | minor | AC-3.3 and D-16 frames (1a, 1b, 7) unproven | To user | manual check § 10 steps 5, 6 before merge; not provable in code |
| UX-2 | UX | minor | Printed page help says the file page never goes in the citation, but the line prints it when the field is empty | To user → F-4 | user 2026-11-16: help becomes "Used in the reference citation" |
| UX-3 | UX | minor | Prompt "As printed, such as 14 or iv" likely cut off at 140pt | To user → F-4 | user 2026-11-16: prompt becomes "14 or iv" |
| UX-4 | UX | minor | Moving a Citation to another file page keeps the old printed page with no cue | Dropped | user 2026-11-16 |
| CON-out | CON→UX | minor | Panel `ViewThatFits` row/stack switch at ~1398pt drops focus; `FocusKeeper` reacts only to width class | Dropped | user 2026-11-16; not a regression |

No SEC or PRF findings (random probe of 200k locator docs: no panic, no negative page).

Nits (logged): `MNT-2 · CitationStepMenu takes model and ordered; take one` · `MNT-3 · CitationLineDisplay.printedPage/filePage are pass-throughs (D-10 asked)` · `MNT-4 · depiction.go regionDocPages could return (page, ok)` · `MNT-5 · graphfill/load.go citationWords could hold a locator.PageRef` · `MNT-6 · CitationLocatorDraft.swift:8 doc note: region drafts never carry pageLabel` · `UX-5 · spaces-only Printed page dirties the form (as Label does)` · `UX-6 · strip says "Page 37", menu says "image 37"` · `CON-3 · T-6 could also save a label-only image locator`

### Fix plan 1

**F-1 — Work out the form's Tab order once** (from MNT-1)
Files: `macos/App/Features/CitationComposer/CitationComposerView.swift`, `CitationComposerEvidenceColumn.swift`.
Failing test first: none (structure; T-8 still covers `CitationFormFocus.order`).
Do: `composeSplit` computes `order` once (as today, for `isShown`) and passes it to `CitationComposerEvidenceColumn` beside `formFocus`. Drop the column's `printedPageOffered` and its two `CitationFormFocus.order(...)` calls; `sideForm` / `panelForm` use the passed `order`; `labelAndPrintedPage` tests `order.contains(.printedPage)`. Note: `sideForm` needs the `.side` order and `panelForm` the `.panel` order; the view already knows `layout`, so the one `order` it passes is the current layout's.
Check: `rg -n "CitationFormFocus.order\(" macos/App` prints only the one call in `CitationComposerView.swift`; scripts/check-pr.sh PASS.

**F-2 — The needs-page warnings name the page in the file** (from UX-1)
Files: `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`. Skill: `add-localized-string`.
Do: `depictionNeedsPage` → "This citation has no page in the file yet. Save the viewer's page to it to draw a region."; `depictionCaptionNeedsPage` → "Draw and the region buttons wait until the citation has a page in the file". Keep keys; update both the L10n default and the catalog entry.
Check: tests that compare these via `L10n.string` still pass; scripts/check-pr.sh PASS (localizable).

**F-3 — The menu-row test builds its expectations from the shared words** (from CON-2)
Files: `macos/ProvenenciaTests/CitationComposerModelTests.swift`.
Do: in `menuRowNamesPrintedAndFilePage`, build each expected value from `CitationLineDisplay.printedPage(_:)`, `CitationLineDisplay.filePage(_:)` and `L10n.string(L10n.CitationComposer.menuRegion)` joined with " · ", as lines 978 and 1036 do.
Check: the test passes; scripts/check-pr.sh PASS.

## Round 1 — fix
Head `43bf763d0`. Implementer gate PASS. F-1 `bc98f5f58`, F-2 `64902ebc3`, F-3 `43bf763d0`. Deviation: `composeSplit`'s `evidence(...)` gained an `order` parameter.

### Fix plan 1b (user answers on UX-2, UX-3)

**F-4 — The Printed page help and prompt take the user's copy** (from UX-2, UX-3; user 2026-11-16, supersedes D-14's board copy for these two strings)
Files: `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, the plan's Landed note (one line). Skill: `add-localized-string`.
Do: `printedPageHelp` → "Used in the reference citation"; `printedPagePrompt` → "14 or iv". Keep keys. Update any test that compares these literals. Add a Landed-note line: "Printed page help and prompt changed from the board copy after review (UX-2, UX-3; user 2026-11-16)."
Check: scripts/check-pr.sh --base a4ce91c61 PASS.

## Round 1b — fix
Head `b22d45613`. Gate PASS (orchestrator run, `--base a4ce91c61`). F-4 done; plan Landed note records the copy change. D-14 and § Strings still quote the board copy (history; the Landed note supersedes).
Resolved (orchestrator read): MNT-1 (`rg "CitationFormFocus.order\("` → one call, `CitationComposerView.swift:301`), UX-1 (both strings say "page in the file"), CON-2 (test builds from `CitationLineDisplay` and `L10n`), UX-2 / UX-3 (F-4).

## Round 2 — review
Not run: no Fix-now blocker or major in round 1.

## Finish
`origin/main` @ `7ed654520` and base branch `s15-50-forms-list-their-tab-order` @ `a4ce91c61` unchanged; no merge needed.

## Result
Gate PASS · CI pending · open: CON-1 (manual check § 10 steps 5, 6 and frames 1a, 1b, 3, 7, before merge) · follow-ups: none (UX-4, CON-out dropped by user) · to user: answered (UX-2, UX-3, UX-4, CON-out)
