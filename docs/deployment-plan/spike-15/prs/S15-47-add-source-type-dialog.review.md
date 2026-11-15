# Review — S15-47 Adding a Source type opens a dialog (with brief S15-D26)

**Verdict:** Fits — Ready with changes (round 4 on the redrawn board, two passes, no open blocker). Earlier: Fits — Ready with changes (round 1: Fits with changes — Ready with changes; round 2: Fits — Ready with changes, both majors fixed)
**Rounds:** 2, then round 3 (AT-3 as a sheet, superseded by the redraw) and round 4 (the redrawn board, two passes). **Reviewers:** maintainability (strongest available model), executability (implementing model)

## To user
- Round 3 M-1: stacked-sheet outside click. **Answered** (user, 2026-11-14): the board was redrawn with no sheet over the dialog; moot.
- Round 4 (redrawn board): one two-column body or two? **Answered** (user, 2026-11-14): one component, the right column's width a parameter (D-11). Return in Description? **Answered**: a new line, as today; AT-9's Shift-Return is not built.
- M-3: the dialog gets its own model, like Copy Source. **Answered** (user, 2026-11-14): own dialog model; the map's S15-47 line reworded.
- M-4: move Source types' list writes onto a declared cache patch. **Answered** (user, 2026-11-14): create now (S15-47), update and delete in S15-48, the suggestion count in S15-12.

## Writer's own calls
- D-2: the label rule lives on `SourceTypesModel.Draft.labelError`; edit now also refuses an unslugifiable label in the client (the engine already refuses it).
- D-3: a duplicate key shows under Label, other failures in a top Callout.
- D-7: `WorkspaceLocation.sourceTypePage(typeId:title:)` lands here; S15-48 reuses it.
- D-9: a successful Add replaces an unsaved side-pane edit, as selecting another type does.
- No explicit initial focus in the dialog (no other form dialog sets one).
- Version patch 0.15.1.

## Round 1

### M-1 · blocker · Duplicate key matched by string literal
**Answer:** Fixed — D-5 adds `EngineErrorCode.sourceTypeDuplicateKey` and the Go parity row (T-11); D-3 reads `engineCode`.

### M-2 · blocker · `create()` writes side-pane state `applySelection` already sets
**Answer:** Fixed — D-3: `create()` returns the type and writes nothing on `SourceTypesModel`; selection follows navigation.

### M-3 · major · The dialog should be an item-bound model
**Answer:** To user → own model (D-1, D-8); map scope entry reworded.

### M-4 · blocker · Create patches the types list by hand
**Answer:** To user → create now: D-4 adds `.createdSourceType` and `CatalogQueryPatch.sourceTypeRow()` (T-10); S15-48's scope entry moves update and delete.

### M-5 · major · Add S15-48's location factory now
**Answer:** Fixed — D-7; the map's S15-48 line now says it reuses it.

### M-6 · major · Unlisted `isAdding` uses
**Answer:** Fixed — D-9 covers `SourceTypesListPane.selection`, `submit()`'s slug check, `isSecondaryDisabled` and the pane's doc comment.

### M-7 · major · Show the key as the Create Property dialog does
**Answer:** Fixed — D-8 and the brief: a read-only mono `PVInput` in a "Key" field; `addKeyPreview(key:)` and the custom spoken label dropped.

### M-8 · major · The label rule four times
**Answer:** Fixed — D-2 `Draft.labelError`.

### M-9 · minor · Precedent names
**Answer:** Fixed — `labelError`, `createError`, `isDirty`, `canAdd` on the add model.

### M-10 · minor · Icon field id hard-coded
**Answer:** Fixed — D-6 takes `accessibilityIdentifierPrefix`.

### X-1 · blocker · Steps cannot compile in order
**Answer:** Fixed — STEP-4 adds strings only; removals and the pane's add branches land together in STEP-5; STEP-3 builds the add model beside the old path.

### X-2 · major · The list pane's `isAdding` and "scrolled into view"
**Answer:** Fixed — D-9 (the list keeps its highlight); "scrolled into view" removed from AT-7 (no scroll code exists; not in scope).

### X-3 · major · Accessibility copy
**Answer:** Fixed — with M-7 the Key field reads by its label; the icon keeps `formIconChangeAccessibility`; brief AT-9 aligned.

### X-4 · major · `create()` details
**Answer:** Fixed — D-3: `guard !isSaving`, label and description trimmed, the key slugs the trimmed label, no `Draft(created)` (selection is navigation's job).

### X-5 · major · String-literal code
**Answer:** Fixed — same as M-1.

### X-6 · major · Fields disabled while saving
**Answer:** Fixed — D-8 `.disabled(model.isSaving)` on the form, the icon field included.

### X-7 · major · Form shape
**Answer:** Fixed — D-8 gives the body top to bottom; D-6 says the icon field brings its own `PVField` with no required marker.

### X-8 · minor · `StoreBoom` is private
**Answer:** Fixed — STEP-3: a file-private `AddFailure` in the test file.

### X-9 · minor · An unsaved edit lost on Add
**Answer:** Fixed — accepted and stated in D-9 and brief AT-7.

### X-10 · minor · Keys and comments
**Answer:** Fixed — D-10 lists keys under `sourceTypes.add.*`.

### X-11 · minor · STEP-1 / STEP-4 overlap
**Answer:** Fixed — STEP-1 deletes `iconFieldButton`; D-6 notes `.id(panelIdentity)` resets the field.

### X-12 · minor · Tests not writable from their rows
**Answer:** Fixed — T-6 asserts the list unchanged; T-9 ported in STEP-5; T-2 states the edit path.

### X-13 · nit · Mac-only boxes
**Answer:** Fixed — § 10 says the evidence comes from a Mac run.

## Round 2 (both lenses, one reviewer): no new blocker

### R2-1 · major · STEP-3 writes T-6, which needs `adding` from STEP-5
**Answer:** Fixed — STEP-3 writes T-1 – T-5 and T-7; T-6 lands in STEP-5.

### R2-2 · major · `sourceTypePage`'s `title` should be optional
**Answer:** Fixed — D-7 `title: String? = nil`, as `sourcePage`.

Below the bar, all taken: T-10 asserts `!handle.isFetching` (FakeStore has no list counter); STEP-7's map edit was already made; D-9's `canSubmit` guards a nil draft.

## Round 3 — AT-3 as agreed (2026-11-14), scoped to D-6, STEP-1, § 6 macOS, § 10, § 11

Board S15-D26 agreed by the user: AT-3 is today's "Choose an icon" picker as a sheet over the dialog. Reviewers: maintainability (strongest model), executability (implementing model), fresh, scoped to the parts that carry AT-3.

### X-1 · major · Picker ids split between the field's prefix and the moved form's literal ids
`SourceTypeIconPickerForm` hard-codes `sourceTypes.iconPicker` and `sourceTypes.iconPicker.<key>`; D-6 gave the picker chrome `"\(prefix).iconPicker"`.
**Answer:** Fixed — D-6: the picker keeps today's ids in every host (chrome prefix the literal `sourceTypes.iconPicker`, the form unchanged); only the field's button takes `prefix`; the modifier sits on the field's outer `PVField`.

### M-1 · major · A click outside both sheets reaches both
`PVOutsideClickView.handle` (`macos/App/DesignSystem/Components/Panel/PVOutsideClick.swift`) has no guard for an attached child sheet: each chrome's local monitor runs, so the picker and the Add type dialog both dismiss (or the dirty dialog swaps in its discard question, dropping the picker and its pick). Verified by reading `handle`; `PVFormDialogClickTests.aSheetOnASheetIsInside` asserts the workspace click is outside the parent. The Name form (`NameValueEditorForm`'s `.pvConfirm` inside `nameValueFormDialog`) has the same gap today. Option A: the kit ignores a click while `sheet.attachedSheet != nil` (one guard, one test beside `aSheetOnASheetIsInside`; changes the Name form too). Option B: the field reports `.pvSheetInnerEdit(pickerOpen)`.
**Answer:** To user — Option A recommended. **Superseded** (user, 2026-11-14): the board was redrawn with the grid inline (round 4); no sheet sits over the dialog. The Name form's own stacked confirm keeps the gap; not raised by this PR.

## Round 4 — the redrawn board (2026-11-14), scoped to the grid, the two-column body and their checks

The user redrew board S15-D26: the dialog is two columns at 840pt, the icon grid inline on the right; the side pane's sheet draws the same grid. User answers: one two-column component with the right column's width a parameter (D-11); Return in Description stays a new line. Reviewers fresh, scoped to the changed parts.

### X-1 · major · § 10 check 2 names Book as the default mark
`PVMarkKey.defaultTypeMark` is `.typeEvidence`.
**Answer:** Fixed — check 2 says Evidence.

### X-2 · major · The grid's focus handling leaves choices
**Answer:** Fixed — D-6 follows `PVList` (`.focusable()`, `.focusEffectDisabled()`, `.focused`, `.onKeyPress`), passes `focused` to `iconCell`; AC-1.5 and check 2 run with Full Keyboard Access on, as the app's lists are reached.

### X-3 · major · `arrowTarget`'s `move:` type unnamed
**Answer:** Fixed — D-6 names `SourceTypeIconGrid.Move { left, right, up, down }` and the return `String?`.

### X-4 · major · `rightWidth` geometry
**Answer:** Fixed — D-11: the width includes the rule and padding; the `HStack` spacing stays `space8` (the board's gap on both sides of the rule).

### X-5 · minor · Focus when saving disables the grid
**Answer:** Declined — SwiftUI moves focus off a disabled view; nothing to decide, and the dialog closes or re-enables right after.

### M-1 · blocker · Label, Key and Description not in `PVTabPair`
`PVTabPair` (`DesignSystem/Components/Input/PVTabPair.swift`) exists because the key loop skips a text area after a text field; the Create Property form and both owner forms use it; `add-ui-component`'s checklist requires it.
**Answer:** Fixed — D-8 wraps the left column in `PVTabPair`, Label and Description take the handles, Key none; check 2 tabs Label → Description → grid.

### M-2 · major · The column rule should be `PVDivider(axis: .vertical)`
**Answer:** Fixed — D-11 draws it with `PVDivider(axis: .vertical)` in an `HStack(spacing: space8)`.

### Round 4, pass 2 (fresh reviewer, both lenses): no new blocker
Every round-4 answer checked against the code and holds.

### X-6 · major · A bare `PVDivider` in an `HStack` does not span the columns' height
The body sizes to content, so the rule gets no height to fill; `SourcesListRow.swift` ~45 draws a row-spanning rule as a leading overlay with `.frame(maxHeight: .infinity, alignment: .top)`.
**Answer:** Fixed — D-11: the rule is a leading overlay on the right column; both columns take `.frame(maxHeight: .infinity, alignment: .top)` and the `HStack` `.fixedSize(horizontal: false, vertical: true)`; check 2 looks at the rule's height.
