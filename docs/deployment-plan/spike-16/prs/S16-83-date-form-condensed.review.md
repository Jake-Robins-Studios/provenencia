# Review — S16-83 The date form is smaller and keyboard-first

**Verdict:** pending round 2
**Rounds:** 1 so far. **Reviewers:** maintainability (opus), executability (sonnet)

## To user
None. The user answered three calls while planning (2026-11-28): no autofill of the latest bound, no Reads as, and `PVButton` takes a focus handle.

## Writer's own calls
- M-1: `SourceDateEditor` is kept as the Source date block (only Reads as goes), because S16-73 D-13 and S15-42 put the marks control there. The feature doc had said the view goes; the user dropped Reads as, not the block.
- M-8: the five new keys stay in `L10n.Sources` beside the form's other date keys; S15-42's entry, which moves them all to `L10n.Dates`, now names them.
- Shift-Tab from Kind goes to the host Year handle's original `previous` (Description in Add Source), else the key loop.
- The Time zone prompt "Europe/London, +01:00…" ships (the board draws it).
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

## Cost
Plan: 5,546 words at round 1, about 6,000 after round 1 (check-plan-docs info line).

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| 1 | maintainability | opus | 202k |
| 1 | executability | sonnet | 153k |
