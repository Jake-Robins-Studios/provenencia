# Review — S16-52 The omnibar's results use the kit popup list

Covers the plan [`S16-52-omnibar-popup-list.md`](S16-52-omnibar-popup-list.md) and its brief [`S16-D9-omnibar-results.md`](../design/archive/S16-D9-omnibar-results.md).

**Verdict:** Fits with changes — Not ready → every finding answered; no open blocker. The plan stayed `Blocked — on board S16-D9` until the board and the kit were agreed on 2026-11-21; it is now `Planned`.
**Rounds:** 1. **Reviewers:** maintainability (opus), executability (sonnet). No round 2: every blocker was a local fix (a shared function, a moved enum, a merged step, a corrected `rg`), with no reshape.

## To user
- None open. The plan waits on the S16-D9 board; when it is agreed, the board's width (OR-3) fixes D-6 and D-7 at refresh.

## Writer's own calls
- The omnibar's list is 640 pt, trailing-aligned to the field, capped 16 pt inside the content column (brief OR-3, a recommendation the board confirms).
- A hit row keeps its own 9/7 inset, so Promote's picker does not change (M-3). An inset change would need a brief for Promote's view.
- After Escape, ↓ or a click does not reopen the list; typing does (as today).
- Return with no highlighted hit is taken and does nothing (as today).
- The row is renamed `PVSearchHitRow` in `Components/SearchHitRow/` (M-4).
- A catalog search's failure, searching and no-match decision lives on `CatalogSearchModel.line`, not in the kit; the kit's `PVPopupListLineKind` keeps three cases, a failure being the caller's empty line (M-2).
- Two pre-existing Promote picker issues go to `ideas/kit-layering.md` (M-3, M-9).

## Round 1 — maintainability

### M-1 · blocker · `fittedListWidth` mirrors `fittedPanelWidth`
**Answer:** Fixed — D-6: one `PVPopupListPlacement.fittedWidth(preferred:hangsFrom:alignment:columnWidth:minimum:inset:)`; `HistoryJumpMenuModel.fittedPanelWidth` calls it and keeps its tests; T-13 tests both alignments; the toolbar takes `contentWidth`.

### M-2 · blocker · `OmnibarResultsLine` is a second failure/no-match/searching decision
**Answer:** Fixed — D-5: `CatalogSearchLine` and `CatalogSearchModel.line`; the omnibar and `PromoteRecordSearch.emptyLine` read it; all three `shows…State` properties go; T-12 moves to `CatalogSearchModelTests`. A `.failed` case in the kit enum was not taken: the kit README's "The combo box subset" makes a failed search the caller's empty line, and the rule's "error lines" are drawn in the kit's `PVPopupListLine`; no rule is bent.

### M-3 · major · The hit row has a second host; D-8's inset change reached Promote
**Answer:** Fixed — §4 gains the Promote picker row; D-8 keeps the row's padding unchanged; Reach and §10 step 9 check Promote; brief OR-2 states the inset stays. The pre-existing double padding is an Out line to `ideas/kit-layering.md` (STEP-7).

### M-4 · major · A kit component named for one feature
**Answer:** Fixed — D-8 renames it `PVSearchHitRow` in `Components/SearchHitRow/`; AC-4.4 sweeps the old name; the brief's inventory row matches.

### M-5 · major · `omnibarSearchFailed` becomes dead; the brief drew copy the app never shows
**Answer:** Fixed — D-13 deletes it and its key; AC-4.3 sweeps it; brief §2 and OR-8 draw a mapped message (`Catalog closed.`).

### M-6 · minor · Kit doc comments go stale
**Answer:** Fixed — STEP-2 and STEP-3 name the four comments.

### M-7 · minor · The brief's inventory omits the kit extensions
**Answer:** Fixed — two rows added (the list's window and placement, Extend; measured height, New with `PVComboBox` as its second call site); §2.1 and Non-goals say "visible".

### M-8 · minor · The omnibar reads a coordinate space owned by the history menu's model
**Answer:** Fixed — D-6 moves the constant to `WorkspaceContent.coordinateSpace`; AC-4.3 sweeps the old name.

### M-9 · minor · The two remote-row fields land the highlight differently
**Answer:** Fixed as an Out line — `ideas/kit-layering.md` gains "A remote combo box highlights nothing when its results arrive" (STEP-7).

### M-10 · nit · A third "last framed" field
**Answer:** Fixed — D-7's `Framed` value replaces `shownHeight` and `shownCount`.

## Round 1 — executability

### X-1 · blocker · The board is not agreed
**Answer:** Declined — that is the plan's stated status (`Blocked — on board S16-D9`), which `plan-pr` step 3 prescribes; the plan is not handed to an implementer until the board is agreed and the plan refreshed.

### X-2 · blocker · `ListLine\b` matches `PVPopupListLine`
**Answer:** Fixed — AC-4.3 and STEP-1 search `PVComboBoxMatch.ListLine`, `enum ListLine` and `listLine(`.

### X-3 · blocker · STEP-4's compile bridge is unspecified
**Answer:** Fixed — the model and view changes are one step (STEP-5, parts a, b, c); STEP-4 is now the shared line, which only swaps the old panel's `if` chain for a `switch` until STEP-5 deletes it.

### X-4 · major · Two activation paths
**Answer:** Fixed — D-4: `handleKey(_:command:activate:)` takes the host's `onActivate`; the click calls the same closure; T-6 – T-8 use it.

### X-5 · major · Stale doc comments in `PVPopupList.swift`
**Answer:** Fixed — same as M-6.

### X-6 · major · Checks that need macOS
**Answer:** Fixed — §7 opens with the macOS-only note and the Linux checks to run in their place; §10 says every step runs on macOS.

### X-7 · major · Where the modifier goes on the field
**Answer:** Fixed — D-1: directly after `PVInput(...)`, in place of the removed background, before `.accessibilityLabel`; the anchor and the frame read are the `PVInput`.

### X-8 · major · The key check comes after the deletions
**Answer:** Fixed — STEP-5's Check runs the in-app key check after the view is wired (b) and before the strings go (c).

### X-9 · minor · `\|` in the `rg` lines
**Answer:** Fixed — the AC lines use `-e` patterns.

### X-10 · minor · A short query leaves a stale highlight
**Answer:** Fixed — D-3 clears it when the query is below the floor; T-11 covers it.

### X-11 · minor · `omnibar-search.md` in Context, no step
**Answer:** Fixed — an Out line: archive, not edited.

### X-12 · major · `main` does not contain the Planned commit
**Answer:** Declined — `git merge-base --is-ancestor b57c98a origin/main` succeeds: `origin/main` is at `b57c98a` (#928 merged). The reviewer's local `main` was stale.

### X-13 · nit · Current state rows checked
**Answer:** Logged.

### X-14 · major · "Throw away the old frames" versus "the hit row stays"
**Answer:** Fixed — the brief keeps one instance of the hit row and the toolbar before clearing the old frames.

### X-15 · major · The Wide toolbar is not described
**Answer:** Fixed — OR-W1 describes the toolbar at 2296 pt; §2 says the field's place holds at both widths.

### X-16 · minor · The searching line's 12 pt is not the combo box's
**Answer:** Fixed — OR-6 says the omnibar's line has no check gutter.

### X-17 · minor · The inventory names Swift symbols, not kit pieces
**Answer:** Fixed — a "Kit piece to instance" column.

### X-18 · minor · Small drawing choices in R1 – R4
**Answer:** Fixed — §2 gives the row height (about 54 pt); R1 draws the likeness as a photo; R3 states the row height.

### X-19 · nit · Brief consistency checks pass
**Answer:** Logged.
