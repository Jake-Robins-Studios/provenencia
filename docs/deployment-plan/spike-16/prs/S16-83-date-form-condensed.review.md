# Review — S16-83 The date form is smaller and keyboard-first

**Verdict:** Fits with changes — Ready with changes (every round-2 finding fixed)
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet)

## To user
None. The user answered three calls while planning (2026-11-28): no autofill of the latest bound, no Reads as, and `PVButton` takes a focus handle.

## Writer's own calls
- M-1: `SourceDateEditor` is kept as the Source date block (only Reads as goes), because S16-73 D-13 and S15-42 put the marks control there. The feature doc had said the view goes; the user dropped Reads as, not the block.
- M-8: the five new keys stay in `L10n.Sources` beside the form's other date keys; S15-42's entry, which moves them all to `L10n.Dates`, now names them.
- Shift-Tab from Kind goes to the host Year handle's original `previous` (Description in Add Source), else the key loop.
- The Time zone prompt "Europe/London, +01:00…" ships (the board draws it).
- The Source date dialog's content (about 472 pt) may stack Kind and the qualifier; DF-2 allows it, so it is not a stop condition.
- The time fields narrow to 48 / 48 / 48 / 52 pt (the board drew 57) so the Time zone keeps at least 96 pt in the composer's box on a range.
- The dead `cascadeField` parameters, `DateOptionalAccessibilityIdentifier` and the cascade helpers go in this PR.

## Round 1

### M-1 · blocker · Deleting `SourceDateEditor` removes the slot S15-42 is built on
**Answer:** Fixed — D-11 keeps `SourceDateEditor` and removes only the Reads as card; Out names S15-42 into it; map scope entry, feature doc and brief inventory row corrected.

### M-2 · blocker · A skill and README rule is bent, but §5 said "None"
**Answer:** Fixed — §5 **Rules this plan bends** lists S15-50's "neighbours come only from a form's order" with the working rule "The date form's Tab starts at Year" as the user's answer; STEP-2 updates the README, skill line and doc; the DoD sweep looks for "come only from".

### M-3 · blocker · `FocusClaim.claim(_ handle:)` repeats the two-turn rule
**Answer:** Fixed — D-2: one core `claim(write:isDone:then:)`; the binding overload and the handle overload call it; T-4 tests the core.

### M-4 · blocker · D-4 writes its own Space and Return handling
**Answer:** Fixed — D-4 uses `pvActivatesOnReturn(when: focus.isActive(), action)` and leaves Space to the `Button`; the modifier order is spelled out.

### M-5 · major · The loop's replacements were prose in the view; the test covered only the straight part
**Answer:** Fixed — D-5: one pure `Field.neighbours(of:isRange:isAdvancedOpen:)` table with `Target` (`.field`, `.hostNext`, `.hostPrevious`), one `handle(for:)`; T-6 walks the whole table; precedent changed to `CitationFormFocus.order(_:)`.

### M-6 · major · `Field` and seven bindings repeat `CascadeComponent` plus a side
**Answer:** Fixed — `Field.part(CascadeComponent, start:)` and `.zone(start:)`; `CascadeComponent` is `CaseIterable`; D-9 adds `DateValueDraft.part(_:start:)` and one `partBinding`; the seven bindings are in Deletes.

### M-7 · major · Qualifier values as string literals
**Answer:** Fixed — D-8 builds the segments from `DateQualifier.*`.

### M-8 · major · New keys in the namespace S15-42 moves out of
**Answer:** Fixed — the keys stay in `L10n.Sources`; the Spike 15 map's S15-42 entry names them (writer's call, above); Out row added.

### M-9 · minor · Code left dead
**Answer:** Fixed — Deletes takes `cascadeField`'s `disabled:` and `activateOnAppear:`, `DateOptionalAccessibilityIdentifier`, and renames `applyingAMonthOptionStillCascadesTheDraft`.

### M-10 · minor · The sweep missed the maps and README:159
**Answer:** Fixed — the DoD sweep covers `docs/deployment-plan/spike-15/` and `spike-16/`; STEP-3 updates the Field focus row's list of takers.

### M-11 · minor · `PVFieldTabClaim` is not every field's claim
**Answer:** Fixed — D-3 names it the claim for fields with no key handler of their own and says `PVSelect` and `PVComboBox` keep theirs.

### M-12 · minor · The link re-does `PVDisclosureButton`'s job
**Answer:** Logged — the Out row says a second chevron-less disclosure link should give `PVDisclosureButton` a link form.

### M-13 · nit · `SourceDateDialog.width` has no type
**Answer:** Fixed with X-1.

### M-14 · minor · Facts written twice
**Answer:** Fixed — D-10 points at Deletes; the Codebase fit "Why" column no longer restates Decisions.

### X-1 · blocker · `SourceDateDialog.width` has no home
**Answer:** Fixed — D-12: `private static let width` on `SourceDateDialogModifier`, its only reader.

### X-2 · blocker · Who keeps focus on a segmented control after a choice
**Answer:** Fixed — D-6: after a keyboard choice the form re-claims Kind or the qualifier; a click does not move focus; switching Kind keeps focus on Kind. AC-2.8 and §10 cover it.

### X-3 · major · Time zone placeholder
**Answer:** Fixed — D-14 and §6 Strings add `dateTimeZonePrompt`.

### X-4 · major · Month and Calendar's Tab claim unstated
**Answer:** Fixed — D-3 says `PVSelect` keeps its own claim, so Month and Calendar need no change.

### X-5 · major · `PVButton` activation details
**Answer:** Fixed — D-4 gives the modifier order, uses `pvActivatesOnReturn`, no Space handler, `iconOnly` unaffected; §10 step 1 presses Return on the link; a stop condition covers a double fire.

### X-6 · major · The rewiring was untested
**Answer:** Fixed — with M-5: the rewiring is the pure table T-6 walks, covering AC-2.2 to AC-2.7.

### X-7 · major · End side's Shift-Tab
**Answer:** Fixed — D-5 says the end side keeps its order neighbours; AC-2.3 and T-6 check the end Year's `previous` is the start zone.

### X-8 · minor · AC-3.1 and the Month select's empty option
**Answer:** Fixed — T-1 uses the twelve month names with no empty option; §10 step 1 presses J once to reach January first.

### X-9 · minor · `SourceDateForm` after the change
**Answer:** Fixed — D-12 says its focus is unchanged; Deletes takes its "what the date reads as" doc text.

### X-10 · minor · Anchors and small gaps
**Answer:** Fixed — STEP-1 names the README tables by their headings; STEP-2 quotes the skill line. `DateValueEditorForm.swift` has no `#Preview` of its own.

## Round 2

Round 1's answers all checked out in the plan and the code (both reviewers).

### M-15 · blocker · The neighbour table re-implements `PVFieldFocus.neighbours(of:in:)` and `claims(next:previous:claim:)`
**Answer:** Fixed — D-5: `Field.order` (as `CitationFormFocus.order`), neighbours from `PVFieldFocus.neighbours(of:in:)` plus the listed exceptions, closures from `PVFieldFocus.claims`; Codebase fit and Builds on name both helpers; T-6 checks `order`.

### M-16 · blocker · `part(_:start:)` a second mapping beside `startSide` / `fieldError` / `setKind`
**Answer:** Fixed — D-9 makes `part(_:start:)` the one mapping: `fieldError`, `setKind` and `startSide` / `endSide` read it; T-5 asserts the end day's error and the end side's clearing.

### M-17 · blocker · Next adds sent S15-42's marks into the shared form's table
**Answer:** Fixed — Next adds: the marks stay in `SourceDateEditor` and join through the `yearFocus` handle; D-5 says the table never names a host's field.

### Below the bar (round 2): README Input / TextArea rows and the skill line list the fields that claim Tab; dialog width naming
**Answer:** Fixed — STEP-2 and STEP-3 add `PVSegmentedControl` and `PVButton` to those lists; D-12 is `SourceDateForm.dialogWidth`, the existing convention.

### X-11 · major · STEP-4's check cannot run alone
**Answer:** Fixed — STEP-4 says it has no check of its own; STEP-5's check runs both suites.

### X-12 · major · How handles and claims are built
**Answer:** Fixed — D-5 spells out the handles (`init(_:equals:)` then `replacingNeighbours`) and that claims resolve targets when the key is pressed; D-2 gives both signatures.

### X-13 · major · D-6's re-claim mechanism
**Answer:** Fixed — D-6 reads `wasFocused` before the choice and claims after, as `ConclusionDetailPage.choose` does; a stop condition covers focus lost after → or Space.

### X-14 · major · One row in the 520 pt dialog vs the stop condition
**Answer:** Fixed — D-7 accepts a stacked row wherever it does not fit (DF-2); the stop condition is removed.

### X-15 · minor · Where the handle wraps in `PVButton`
**Answer:** Fixed — D-4: around `control`, before the `iconOnly` / `flushLeading` branch.

### X-16 · minor · No test for D-3 / D-4
**Answer:** Fixed — the DoD names §10 steps 1, 3 and 4 as their evidence (no view-level seam beyond `claimTab`, already tested); §10 step 4 adds Subject → Property.

### X-17 · minor · Time zone width in the composer
**Answer:** Fixed — time fields 48 / 48 / 48 / 52, Time zone `minWidth` 96.

### X-18 · nit · four vs five keys
**Answer:** Fixed.

Smaller note (J, pause, J J in §10): Fixed.

## Cost
Plan: 5,546 words at round 1, 6,336 at the verdict (check-plan-docs info line).

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| 1 | maintainability | opus | 202k |
| 1 | executability | sonnet | 153k |
| 2 | maintainability | opus | 166k |
| 2 | executability | sonnet | 174k |
