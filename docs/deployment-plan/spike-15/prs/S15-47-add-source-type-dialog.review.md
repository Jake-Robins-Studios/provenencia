# Review — S15-47 Adding a Source type opens a dialog (with brief S15-D26)

**Verdict:** round 1: Fits with changes — Ready with changes; round 2 pending
**Rounds:** 1. **Reviewers:** maintainability (strongest available model), executability (implementing model)

## To user
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
