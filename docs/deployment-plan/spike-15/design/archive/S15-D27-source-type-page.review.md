# Review — S15-D27 Source types: each type opens on its own page

**Verdict:** Fits with changes — Ready with changes
**Rounds:** 1. **Reviewers:** maintainability (Opus), executability (Sonnet). No round 2: every blocker was a local fix to the brief's text, checked against the code by the writer.

## To user
- None. The two product calls (leaving with unsaved details asks; no toast after Add or Delete) were asked before the brief was written (user, 2026-11-15).

## Writer's own calls
- TP-4 recommends the icon grid inline (the Add dialog's composition) and leaves the sheet as the board's fallback, because S15-47's plan gave this choice to the D27 board.
- TP-3 gives the page its own header and leaves `VocabularyPanelHeader` to the Metadata pane.
- The Description becomes a text area, as in the Add dialog.

## Round 1

### M-1 · blocker · Suggested fields is drawn as one hard-wired section; S15-12 needs it three times
**Answer:** Fixed — TP-6 draws one list block that S15-12 repeats; inventory row "Suggestion list" (moved out of the side pane, its level an input), as S15-12's D-6 file.

### M-2 · blocker · TP-7's order cannot be built on PVPageColumns once S15-17 adds formats
**Answer:** Fixed — TP-7 is written in Page columns' terms (primary: Details then formats; secondary: the suggestion lists; Regular stacks the secondary below), and TP-W1 follows it.

### M-3 · blocker · A gone type should leave through the pages' mechanism
**Answer:** Fixed — TP-10 "leaves for the list, as a deleted Source's page does"; inventory row "Gone type" → `.leavesForSectionRoot(when:)`.

### M-4 · major · Leave confirm: name the kit's discard copy, extract the third guard install
**Answer:** Fixed — inventory names `PVConfirmCopy.discardChanges` over `WorkspaceLeaveGuard`. The install modifier is the plan's (S15-48 D-8).

### M-5 · major · Return-to-open should reuse PVListKeyboard
**Answer:** Fixed — TP-1 uses `PVList`'s keys; inventory row "Table" extends `PVTable` through `PVListKeyboard.action`.

### M-6 · major · The header row contradicts itself
**Answer:** Fixed — TP-3 is a page header of its own with the mark in a Thumbnail; `VocabularyPanelHeader` keeps the Metadata pane and loses `iconKey` and `usageLine`.

### M-7 · major · Icon field: say what dies on each branch; prefer the dialog's composition
**Answer:** Fixed — TP-4 recommends inline; the inventory row says what goes on each branch. The board keeps the final say (S15-47 Out row).

### M-8 · minor · The Page layout precedent is the wrong page; load failure has a kit piece
**Answer:** Fixed — inventory row "Page layout" (first caller of `secondary:`, the Source page's loading shell only); row "Load failure" `PVRetryCallout`; frame 13b.

### M-9 · minor · The Description editor drifts between the dialog and the page
**Answer:** Fixed — `PVTextArea`, as the Add dialog.

### M-10 · minor · Copy and inventory gaps
**Answer:** Fixed — "Details" *(new)*; `VocabularyLabeledSection` in the Locked row; the Delete row cites `SourcePageModel.confirmResourceDelete(leaving:)`.

### X-1 · blocker · TP-1 needs a table behavior the kit lacks
**Answer:** Fixed — inventory row "Table": Extend, an optional activate action with `PVList`'s key contract; Non-goals say a parameter is not a new primitive.

### X-2 · blocker · TP-9 contradicts today's header
**Answer:** Fixed (wording). Today's Source types pane passes `canDelete: model.canDeleteSelectedType`, which is `selectedType != nil` (`SourceTypesModel.swift`), so the trash is always enabled; `SourceTypesModelTests.pluginTypeOriginLockedTrashStillOffered` pins it. TP-9 and TP-5 now say Delete is always enabled and DeleteImpact decides.

### X-3 · major · TP-8 depends on a mechanism the inventory never names
**Answer:** Fixed — inventory "Leave confirm" names `WorkspaceLeaveGuard`; § 1 defines dirty (exact comparison of Label, Icon, Description); TP-8: a save in flight is not held; quitting is not asked about.

### X-4 · major · "Saving…" does not match today's copy
**Answer:** Fixed — "Saving".

### X-5 · major · "Details" is a new string
**Answer:** Fixed — marked *(new)*.

### X-6 · major · The icon count is wrong
**Answer:** Fixed — the brief no longer gives a number.

### X-7 · major · TP-4 leaves the icon choice open
**Answer:** Partly — TP-4 recommends inline and frame 4 draws whichever the board picks; the choice stays the board's (S15-47 plan, Out row "The type page's icon field … S15-48 (D27 board)").

### X-8 · major · TP-W1 and TP-7 conflict
**Answer:** Fixed — see M-2.

### X-9 · major · Page columns' fill mode is not chosen
**Answer:** Fixed — inventory: no `primaryFill`, the `secondary:` slot, header pinned in the header slot.

### X-10 · major · Header reuse is open
**Answer:** Fixed — see M-6.

### X-11 · major · The dead toast code is not named
**Answer:** Fixed — § 2.1 "Removed" and inventory row "Removed copy".

### X-12 · minor · Crumb while loading; gone mechanism
**Answer:** Fixed — § 2.1 Breadcrumb (the carried label while loading); TP-10 and inventory "Gone type".

### X-13 · minor · Frame 8 versus loading after Add
**Answer:** Fixed — TP-10: the created row is already in the list (S15-47's `.createdSourceType` patch), so the page opens on its values.

### X-14 · minor · Frame list gaps
**Answer:** Fixed — frames 5b, 9b, 11b, 13b; 6 and 10 at both widths; TP-5 says Delete stays on a plugin's type (as today).

### X-15 · minor · Quote the locked note and empty text
**Answer:** Fixed — § 2.1 quotes both in full.

### X-16 · minor · Dirty is unspecified
**Answer:** Fixed — § 1 "What stays".

### X-17 · nit
Logged. The side pane's width and empty-state strings are in the Remove rows.
