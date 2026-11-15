# Review — S15-48 Source types open on their own page

**Verdict:** Fits with changes — executability not run yet (the plan is Blocked on board S15-D27)
**Rounds:** 1 (maintainability only). **Reviewers:** maintainability (Opus). The executability dry run and any round 2 run when the board is agreed and OQ-1 is closed.

## To user
- M-1: pull S15-12's suggestion-write fix (D-2, D-5, D-1's `markStale`) into S15-48 at the Source level. **Answered** (user, 2026-11-15): pull it in. The map's S15-12 entry and its plan's status record the move.

## Writer's own calls
- D-9: Return with no row highlighted opens the first row, as `PVList` does; the arrow keys keep `PVTableSelection`'s clamping (Out row).
- D-11: the page gets `SourceTypePageHeader`; `VocabularyPanelHeader` loses its two Source-type-only parameters.
- D-14 and D-8 follow the user's two answers of 2026-11-15 (ask before leaving; no toast after Add or Delete).

## Round 1

### M-1 · blocker · Suggestion writes take a second cache path that S15-12 has already replaced
**Answer:** To user → pull it in (user, 2026-11-15). Fixed — D-7, STEP-3, T-7; the count no longer goes through `.updatedSourceType`.

### M-2 · blocker · A missing type uses the list's selection-reconcile pattern
**Answer:** Fixed — D-5: `WorkspaceSession+SourceTypes.swift` with `sourceType(id:)` and `sourceTypePresence(id:)`, mirroring `evidenceGraphPresence(id:)`; the page applies `.leavesForSectionRoot(when: model.isGone)`; `reconcile()` is gone; T-6.

### M-3 · blocker · `PVTable` gets its own activation rule beside `PVListKeyboard`
**Answer:** Fixed — D-9 routes Return and Space through `PVListKeyboard.action`; `activationIndex` is gone; T-11 tests `PVListKeyboard`. The arrows stay on `PVTableSelection` (Out: different clamping, pinned by `PVTableSelectionTests`).

### M-4 · major · Third verbatim copy of the leave-guard install
**Answer:** Fixed — D-8: `.workspaceLeaveGuard(_:)` and a `navigation` requirement on `WorkspaceLeaveGuard`; the composer and Promote move onto it; the confirm uses `PVConfirmCopy.discardChanges`.

### M-5 · major · The page view absorbs the suggestion section that S15-12 then extracts
**Answer:** Fixed — D-12: `SourceTypeSuggestionList` now, reading `suggestionsHandle.reading`; `isLoadingSuggestions` goes.

### M-6 · major · The Scale line misses the vocabulary reload
**Answer:** Fixed — § 6 Scale states the reload of the two visible lists on a type write and takes S15-12 D-1's `markStale` for `.typeSuggestions` (part of M-1's answer).

### M-7 · major · Guidance this PR makes false is missing
**Answer:** Fixed — STEP-10 adds `macos/App/DesignSystem/README.md`, `docs/design-system-layers.md`, the `syncSelection(from:)` citation and cache rule 4; the DoD sweep lists their old phrases.

### M-8 · minor · `removedSourceTypeRow()` beside `row()`
**Answer:** Fixed — D-3: `row` gains `removes:`.

### M-9 · minor · A third copy of "live label, else carried"
**Answer:** Fixed — D-6 renames `sourceTitle(live:carried:)` to `liveLabel(live:carried:)` and uses it for types.

### M-10 · minor · `Draft` stays nested in the list model
**Answer:** Fixed — D-2: `SourceTypeDraft` in its own file.
