# Ship log — S16-83 The date form is smaller and keyboard-first

**Plan:** [`S16-83-date-form-condensed.md`](S16-83-date-form-condensed.md) · **Branch:** `s16-83-date-form-condensed` · **PR:** #1027
**State:** fixing — manual check 3

## Round 0 — implement
Head `f49196396`. Gate PASS (orchestrator run, xcode-test included). Report deviations: manual check (§10) and the view-level keyboard evidence (D-3, D-4, D-6, D-13) not run — needs the user's Mac; version 0.53.1 (main already 0.53.0); `monthAndDayCanBeSetWithoutAYear` lost its `applyStartCascade()` call (method deleted); `Field.neighbours` is `@MainActor`; `DateValueDraft.part(_:start:)` is static; old names (`PVInputTabClaim`, `sourceDateReadsAs`, `.date.readsAs`, `hideTime`) left in landed/historical plans and map rows, not rewritten.

## Round 1 — review
Reviewers: CON, MNT, UX. Skipped: SEC+PRF (no security or performance path, no added SQL or URL code; diff read: UI focus and draft code only, no stored-data loops).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| UX-1 | UX | blocker | Return on the focused Calendar and phrase link saves the sheet | Fix now → F-1 | verified: `PVButton.focused(_:)` (PVButton.swift:231-238) adds `pvActivatesOnReturn` but never `pvSheetTakesReturn`; `PVFormDialog` keeps `.defaultAction` unless that preference is raised; its one caller is `PVProvenanceRecordTable.swift:81` for exactly this case |
| CON-1 | CON | major | View-level ACs unchecked; Landed note says "As planned" | Fix now → F-2 (Landed note); §10 goes to the user | verified: ship log Round 0. The §10 run is the user's by the ship-pr loop; the PR body gives each view AC its §10 line and flags the `ViewThatFits` Kind/qualifier duplication for steps 1 and 4 |
| CON-2 | CON | minor | Host-edge → key-loop rule untested | Fix now → F-3 | code this PR adds; `reachable` is private and has no test |
| UX-2 | UX | minor | VoiceOver reads the side name twice | Fix now → F-4 | `sideLabel(start:)` Texts not hidden inside a `.contain` group already labelled |
| MNT-1 | MNT | minor | "Cascade" and "part" name one thing | Fix now → F-5 | files touched; the cascade behaviour is deleted in this diff |
| MNT-2 | MNT | minor | `claim(_:)` special-cases start Year needlessly | Fix now → F-6 | `ownHandle` already returns the right handle for every field |
| MNT-3 | MNT | minor | `PVInkLink` has no `focus:` | Follow-up → S16-84 (user, 2026-11-28) | PR does not add, change or copy `PVInkLink` or the record row's `apply(AnyView…)` |
| UX-3, UX-4 | UX | nit | Stale translator comments in L10n.swift | Fix now → F-4 | stale comments in a file this PR changes |
| CON-3, CON-4 | CON | nit | Neighbour table asserts are partial | Fix now → F-3 (rides along) | same test file as F-3 |

Nits (logged): `MNT-4 · PVButton.swift:228 · rename private focused(_:) → withFocusHandle(_:)` · `MNT-5 · DateValueEditorForm.swift:265-267,280-282 · use fieldCaption for Calendar/Phrase captions` · `MNT-6 · DateValueEditorForm.swift:76-80,112-116 · one reclaiming(_:_:) for the Kind/qualifier select closures` · `MNT-7 · DateValueEditorForm.swift:436-446 · String raw value instead of identifierName switch`

### Fix plan 1

**F-1 — A focused kit button takes Return from the sheet's default button** (from UX-1)
Files: `macos/App/DesignSystem/Components/Button/PVButton.swift`, `macos/App/DesignSystem/README.md` (Button row). Skill: `add-ui-component`.
Failing test first: none reachable (view preference); evidence is §10 step 1 / AC-2.9 on a dated Source.
Do: in `PVButton.focused(_:)` add `.pvSheetTakesReturn(focus.isActive())` beside `.pvActivatesOnReturn(when:…)`. Update the PVButton doc (lines 148-149) and the README Button row to say that inside a kit sheet the focused button takes Return from Confirm/Done.
Check: `rg -n pvSheetTakesReturn macos/App` shows the new PVButton hit; scripts/check-pr.sh PASS.

**F-2 — The Landed note names the unrun manual check** (from CON-1)
Files: `docs/deployment-plan/spike-16/prs/S16-83-date-form-condensed.md` (Landed line).
Do: add to the Landed note's exceptions: "§10's manual check (and the view-level evidence for D-3, D-4, D-6, D-13) is the user's, run before merge."
Check: check-plan-docs 0 errors.

**F-3 — Test the host-edge resolution** (from CON-2, CON-3, CON-4)
Files: `macos/App/Features/Dates/DateValueEditorForm.swift`, `macos/ProvenenciaTests/DateValueEditorFormTests.swift`. Skill: `add-swift-test`.
Failing test first: `DateValueEditorFormTests/hostEdgeWithNoNeighbourGoesToTheKeyLoop` — `.hostPrevious` with no host previous resolves to nil; with one, `.hostPrevious`; same for `.hostNext`.
Do: move the logic of the private `reachable` into a pure static on `Field` (e.g. `Field.resolve(_ target:, hostHasNext:, hostHasPrevious:) -> Target?`) and have `reachable`/`claim` call it. In `neighbourTable`, assert the full range Tab sequence (not only `.last`) and add the range case for `kind.previous == .hostPrevious`.
Check: the new test passes; scripts/check-pr.sh PASS.

**F-4 — Side labels hidden from VoiceOver; stale translator comments** (from UX-2, UX-3, UX-4)
Files: `macos/App/Features/Dates/DateValueEditorForm.swift`, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings` (comments only, if the catalog mirrors them). Skill: `add-localized-string`.
Do: `.accessibilityHidden(true)` on what `sideLabel(start:)` returns. Rewrite the comments of `dateEarliestHeading` / `dateLatestHeading` (spoken name of a range side's group, not drawn) and `dateLeaveEmptyHint` (hint on the Calendar and phrase link's line).
Check: scripts/check-pr.sh PASS (localizable included).

**F-5 — "Part" is the one word** (from MNT-1)
Files: `macos/App/Platform/DateValueDraft.swift`, `macos/App/Features/Dates/DateValueEditorForm.swift`, tests that name them.
Do: rename `CascadeComponent` → `Part`, `cascadeField` → `partField`, `cascadeFieldError` → `firstPartError`; fix the "cascade field" doc lines.
Check: `rg -n -i cascade macos/App macos/ProvenenciaTests` prints nothing; scripts/check-pr.sh PASS.

**F-6 — One claim path for every field** (from MNT-2)
Files: `macos/App/Features/Dates/DateValueEditorForm.swift`.
Do: `case .field(let field): FocusClaim.claim(ownHandle(field))`; drop the `f == .startYear` branch.
Check: scripts/check-pr.sh PASS.

## Round 1 — fix
Head `2ccc5fe70`. Gate PASS (orchestrator run). F-1 to F-6 done. F-5's check as worded was too wide (unrelated delete-impact "cascade" code elsewhere in `macos/App`); over the date files it prints nothing. The F-5 rename is split over two commits; the head compiles.
MNT read by orchestrator (minors only, no re-review): MNT-1 **Resolved** (`rg -i cascade` over DateValueDraft, Features/Dates and DateValue* tests: no hit); MNT-2 **Resolved** (`DateValueEditorForm.swift:326-327`).

## Round 2 — review
Reviewers: CON (CON-1 major), UX (UX-1 blocker). Scope `f49196396...2ccc5fe70`.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | major | (round 1) | Resolved | Landed note names the unrun §10 (aa9437433) |
| UX-1 | UX | blocker | (round 1) | Resolved | `PVButton.swift:240` `.pvSheetTakesReturn(focus.isActive())`; OR-combined preference read by `PVFormDialog.swift:155`; only `focus:` caller is the date form's link |

No new findings from either reviewer. No Fix plan 2.

## Manual check — user feedback (2026-11-28)

The user, running §10 step 1 (screenshot of a Single date, 25 October 1937): the Day input's right edge should line up with the Ms input's right edge; the gaps between Year, Month and Day are uneven; the Month select is not aligned with its caption. Asked to check the design again.

Checked against the agreed board (template "DateValue editor", `DateValueEditor.dc.html` lines 112–124). The board draws both rows as one grid width: Year 64 / Month 124 / Day 48 with 8 pt column gaps (252 pt), and Hour / Min / Sec / Ms at 57 pt each with 8 pt gaps (252 pt), so Day's right edge is Ms's right edge; the Month select fills its 124 pt column (`fillsWidth: true`); captions sit 2 pt over their controls; Time zone is `minmax(0, 160px)`. The code drifted:
- `dateRow` / `timeRow` use `PVSpacing.space3` (6 pt), not 8 pt.
- Time fields are 48 / 48 / 48 / 52, not 57 each.
- `monthSelect` passes `fillsWidth: false` inside `.frame(width: 124)`, so the select draws at its own width, centered in the slot: the uneven gaps and the caption misalignment.
- `zoneField` is `minWidth: 96, maxWidth: .infinity`, not capped at 160.
- Caption-to-control spacing is `space2` (4 pt), not 2 pt.

### Fix plan M

**F-7 — The date form's two rows share the board's grid** (user, manual check)
Files: `macos/App/Features/Dates/DateValueEditorForm.swift`, `macos/ProvenenciaTests/DateValueEditorFormTests.swift`. Skill: `add-ui-component`, `add-swift-test`.
Failing test first: `DateValueEditorFormTests/dayAndMsShareARightEdge` — with the widths and gap as named constants, `year + month + day + 2 × gap == 4 × timePart + 3 × gap` (252).
Do: name the widths once (e.g. `private enum Layout { static let gap: CGFloat = PVSpacing.space4; year 64; month 124; day 48; timePart 57; zoneMax 160 }`, internal enough for the test) and use them in `dateRow`, `timeRow`, `partField` and `monthSelect`; both rows `HStack(alignment: .bottom, spacing: Layout.gap)`. `monthSelect`: `fillsWidth: true` so the select fills its 124 pt column, flush with its caption. `zoneField`: `.frame(minWidth: 0, maxWidth: Layout.zoneMax, alignment: .leading)` (board `minmax(0,160px)`); in the composer's range (about 440 pt box, 86 pt side column) Time zone keeps about 94 pt. Caption-to-control spacing `PVSpacing.space1` (2 pt) in `partField`, `zoneField` and `monthSelect`. Keep `sideLabelWidth` 86 (board 76 + 10 gap). Update the plan's Landed note: "the rows follow the board's grid (S16-D20): fields 57 pt, gaps 8 pt, Month fills its column, Time zone capped at 160 pt; the round-0 widths drifted from the board (user's manual check)".
Check: the test passes; scripts/check-pr.sh PASS; the user re-runs §10 step 1 and step 4 (composer range: Time zone readable).

## Manual check — fix
Head `65feca208`. Gate PASS (orchestrator run). F-7 done: `DateValueEditorForm.Layout` (gap 8, year 64, month 124, day 48, time parts 57, zone max 160); Month `fillsWidth: true`; captions 2 pt over their controls; `dayAndMsShareARightEdge` added red first (did not compile), green at head. Diff read by orchestrator against Fix plan M: matches. On screen: the user's §10 steps 1 and 4.

## Manual check 2 — user feedback (2026-11-28)

The user, with Calendar and phrase… open: Calendar and Phrase stack on two rows, and the Calendar select sits indented from its caption; the board puts them on one row.

Board (`DateValueEditor.dc.html` lines 138–140): one row, `align-items: flex-start`, gap 10: Calendar is a `PVField` labelled "Calendar" in a fixed 148 pt column holding a `PVSelect` size sm with `fillsWidth: true`; Phrase is a `PVField` labelled "Phrase" with the hint "A short gloss carried on the date itself — not the source's wording", filling the rest of the row, holding a `PVInput` size sm. The code (`advancedSection`) is a `VStack` of two hand-built caption stacks, and the Calendar select is `fillsWidth: false` in a 220 pt frame (centered, the Month bug again).

### Fix plan M2

**F-8 — Calendar and Phrase on one row, as the board draws them** (user, manual check 2)
Files: `macos/App/Features/Dates/DateValueEditorForm.swift`. Skill: `add-ui-component`.
Failing test first: none (layout only); evidence is the user's look at the open section.
Do: `advancedSection` becomes `HStack(alignment: .top, spacing: Layout.gap)` (8 pt, the kit token nearest the board's 10; no new token). Calendar: `PVField(label: L10n.Sources.dateCalendar) { PVSelect(…, size: .sm, menuWidth: 220, fillsWidth: true, …) }` framed `width: Layout.calendar` (new constant, 148). Phrase: `PVField(label: L10n.Sources.datePhrase, hint: L10n.Sources.datePhraseHint) { PVInput(… size: .sm …) }` with `.frame(maxWidth: .infinity, alignment: .leading)`. Keep every focus handle, accessibility label, `pvFieldLabel` and identifier as they are. If `PVField`'s caption style differs from the form's `fieldCaption`, use `PVField` anyway (the board draws `PVField`); say so in the report. This also settles MNT-5 (the hand-built Calendar/Phrase captions). Extend the plan's Landed note's F-7 sentence with: "and Calendar and Phrase share one row of `PVField`s, Calendar 148 pt".
Check: scripts/check-pr.sh PASS; the user opens Calendar and phrase… in the Source date dialog and in the composer.

## Manual check 2 — fix
Head `fc49ff9aa`. Gate PASS (orchestrator run). F-8 done: `advancedSection` is one `HStack(alignment: .top, spacing: Layout.gap)` of two `PVField`s, Calendar 148 pt (`Layout.calendar`) with its select `size: .sm`, `fillsWidth: true`; Phrase fills the rest with its hint. Diff read by orchestrator: matches. Deviation: `PVField`'s caption style (body, medium) is larger than the date parts' `fieldCaption` (micro), as the plan allowed; the hand-set `pvFieldLabel` on Phrase went (PVField sets it). On screen: the user's look.

## Manual check 3 — user feedback (2026-11-28)

The user: Kind (Single date / Between two bounds) and the qualifier (As stated / About / Before / After) stack on two rows, each stretched across the form; the board puts them on one row.

Board (`DateValueEditor.dc.html` lines 93–101): one row, `flex-wrap: wrap`, gap 12 pt; Kind is a segmented `PVChipGroup` 220 pt wide, the qualifier one 240 pt wide, chips `expands`; 220 + 12 + 240 = 472 pt inside the dialog's 480 pt content (520 − 2 × `PVPanelMetrics.bodyInset` 20). The code (`kindRow`) wraps an `HStack(spacing: space4)` and a stacked `VStack` in `ViewThatFits(in: .horizontal)`, with no width on either control; the controls' ideal widths sum past the 480 pt, so the stacked branch wins and each control stretches to the form's width.

### Fix plan M3

**F-9 — Kind and the qualifier on one row at the board's widths** (user, manual check 3)
Files: `macos/App/Features/Dates/DateValueEditorForm.swift`, `macos/ProvenenciaTests/DateValueEditorFormTests.swift`. Skill: `add-ui-component`, `add-swift-test`.
Failing test first: `DateValueEditorFormTests/kindAndQualifierFitOneRow` — `Layout.kind + Layout.kindGap + Layout.qualifier <= 480` (the Source date dialog's content width; name it from `SourceDateForm.dialogWidth - 2 * PVPanelMetrics.bodyInset` if both are reachable from the test target), and each control's label fits its share without truncation: host each `PVSegmentedControl` (the form's real items and `.sm` size) in an `NSHostingView` with no width proposal and assert its `fittingSize.width <= Layout.kind` / `<= Layout.qualifier`. If the fitting widths exceed 220 / 240, **stop** and report the measured widths: the board's widths do not fit the app's type, and that is the user's call.
Do: add `Layout.kind` 220, `Layout.qualifier` 240, `Layout.kindGap` = `PVSpacing.space5` (12). In `kindRow`'s horizontal branch, `HStack(spacing: Layout.kindGap)` with `kindControl.frame(width: Layout.kind)` and `qualifierControl.frame(width: Layout.qualifier)`. Keep the `ViewThatFits` stacked fallback (the composer's ~440 pt value box is narrower than 472 and stacks, per DF-2 "when the form's width allows"); in the stacked branch keep the controls at the same fixed widths, leading-aligned, not stretched. On a range the Kind control alone keeps 220 pt. Keep the existing focus handling and the `ViewThatFits` duplication exactly as is (D-6). Extend the plan's Landed note's F-7 sentence with: "and Kind and the qualifier sit on one row at 220 and 240 pt".
Check: the test passes; scripts/check-pr.sh PASS; the user opens the Source date dialog (one row) and the composer (stacked, not stretched).

## Result
Gate PASS (head `2ccc5fe70`, origin/main unchanged at `6a6854119`) · CI see PR · open: none · follow-ups: MNT-3 → S16-84 on the Spike 16 map (user) · to user: §10 manual check before merge (the only proof of UX-1 in the running app, AC-1.1/1.2/1.6, AC-2.1/2.8/2.9, D-3/D-4/D-6/D-13; watch steps 1 and 4 for the `ViewThatFits` Kind/qualifier focus).

## Cost
Plan: 6,346 words (check-plan-docs info line).

| Round | Agent | Model | Tokens |
| --- | --- | --- | --- |
| 0 | implementer | sonnet | 215k |
| 1 | MNT | opus | 118k |
| 1 | UX | opus | 91k |
| 1 | CON | opus | 120k |
| 1 | implementer (fix) | sonnet | 89k |
| 2 | CON | opus | 39k |
| 2 | UX | opus | 39k |
| M | implementer (fix) | sonnet | 80k |
| M2 | implementer (no plan found) | sonnet | 74k |
| M2 | implementer (fix) | sonnet | 76k |
| | **Total** | | **941k** |
