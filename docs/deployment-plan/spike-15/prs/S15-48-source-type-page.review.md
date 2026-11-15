# Review — S15-48 Source types open on their own page

**Verdict:** Fits with changes — Ready with changes; every finding answered
**Rounds:** 2. **Reviewers:** maintainability (Opus), executability (Sonnet)

## To user
- M-1: pull S15-12's suggestion-write fix (D-2, D-5, D-1's `markStale`) into S15-48 at the Source level. **Answered** (user, 2026-11-15): pull it in. The map's S15-12 entry and its plan's status record the move.

## Writer's own calls
- D-9: Return with no row highlighted opens the first row, as `PVList` does; the arrow keys keep `PVTableSelection`'s clamping (Out row).
- D-11: the page gets `SourceTypePageHeader`; `VocabularyPanelHeader` loses its two Source-type-only parameters.
- D-16's `.sourceTypePage` split numbers (main 440–560pt, side 340–480pt) come from the board's notes; 440 is my floor before the columns stack.
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

## Board agreed (2026-11-15)

The user agreed the S15-D27 board ([link](https://claude.ai/artifact/42ZuWus4ynyz7xUDwcF6zG)) without Wide, failure or list frames, and asked for a general kit container for the two columns, the page passing its widths and wrap rule. That became D-16 (`PVColumnSplit` as a parameter of `PVPageColumns`), with D-11 and D-13 filled from the board and OQ-1 closed (the sheet).

## Round 2

**Reviewers:** maintainability (Opus), executability (Sonnet). Verdicts: Fits with changes; Ready with changes.

### M2-1 · blocker · D-16 adds a second "beside, else stacked" rule and its rename breaks callers
**Answer:** Fixed — D-16: one `widths(available:widthClass:split:)` rule; `sideColumnWidths(available:mainMin:)` calls it with `.whenNarrow`; each stacking mode keeps today's stacked widths; `split(available:sideMax:)` stays as a wrapper, so `SourcePageOverviewLayout` and its test are untouched. `fillSplitSideMax` stays (retiring it is not this PR's).

### M2-2 · major · D-16 makes guidance false; the DoD contradicts it
**Answer:** Fixed — STEP-10 adds `macos-client-patterns.md` § 9's `PVPageColumns` paragraph and `add-design-brief`'s reach-for line; the DoD names `split:` and sweeps "stacked at Regular, side by side at Wide".

### M2-3 · major · D-5 adds a second copy of the presence enum
**Answer:** Fixed — D-5: `CatalogRowPresence<Row>`; `EvidenceGraphPresence` becomes its typealias.

### M2-4 · major · Step cross-references are stale
**Answer:** Fixed — STEP-1 "until STEP-7", STEP-4 "until STEP-8"; T-12 before T-13.

### X-1 · blocker · The `split` rename breaks callers; `stacked` has no source
**Answer:** Fixed — see M2-1; `PVColumnSplit.stacks(available:widthClass:)` feeds `layoutWidths`; `max(0, …)` stays; T-13 reads `layoutWidths(…).stacked`.

### X-2 · blocker · Step order leaves the tree not building
**Answer:** Fixed — STEP-4 turns the list's binding into D-9's `highlighted` state (still navigating until STEP-8); STEP-3 drops `patchSuggestions` and the count branch with the new mutation.

### X-3 · major · Fallout on existing tests
**Answer:** Fixed — § 8 "Existing tests" gives every `SourceTypesModelTests` case a home (stays, moves, deleted); STEP-3 names the three `CatalogQueryRegistryTests` rewrites; STEP-1 the two registry coverage tests; `queryKeysMatchDesignTable` is named.

### X-4 · major · The leave confirm cannot be written from the plan
**Answer:** Fixed — D-8: `leaveBinding` (nil → `keepEditing()`), `detail: { _ in EmptyView() }`, parameter `leaveGuard`.

### X-5 · major · Copy and layout choices left open
**Answer:** Fixed — two retry-callout titles in § 6 Strings; the header's loading skeleton (D-11); the form disabled while saving, the text area's arguments and the Change icon accessibility label (D-13); the Suggested fields header with the count as `meta` (D-12).

### X-6 · major · The brief contradicts the plan
**Answer:** Fixed — brief TP-4, TP-7, TP-W1, § 4.1 and the inventory's Page layout and Icon rows follow the agreed board.

### X-7 · minor · Members not listed in D-2
**Answer:** Fixed — D-2 lists them; `warm()` from `.task`; D-4 names `.onChange(of:initial:)`; D-15 the `Task` wrapper.

### X-8 · minor · Smaller gaps
**Answer:** Fixed — D-3 checks `removes` before the row guard; D-6 passes `names`; the same-location move in Edges; the coverage tests in STEP-1; STEP-5's files trimmed; the version line names today's value.

### X-9 · nit
Logged; the stop condition stays.

**Verdict after round 2:** no open blocker, no To user item. Planned.
