# Review — S16-53 The history menu uses the kit presenter and a kit menu row

**Verdict:** Fits with changes — Ready with changes
**Rounds:** 1. **Reviewers:** maintainability (Opus), executability (Sonnet)

## To user

- **M-1** (blocker): a new kit row `PVContextMenuPathItem` with one caller, against `add-design-brief`'s "a second call site is already known", while the map named a kit row. Recommendation: a feature-private label on `PVContextMenuItem`. **Answered 2026-11-21: feature-private label.** The map's scope entry and row were reworded in the same commit.

## Writer's own calls

- `PVPopupOptions.ignoresRightClicks` passes right-clicks only; a Ctrl-click stays a left press and still closes an open menu, as today (D-1).
- `pvContextMenu` takes `options: PVPopupOptions` in place of `keysStayInField:` (D-3).
- One `.pvContextMenu` per history button, with an origin under the button (D-2, D-6).
- `HistoryJumpMenuModel` goes; the toolbar holds the open side as one optional (D-10).
- No type-select in the history menu (map Out); Home/End come with the kit keyboard.
- The user accepted the kit menu's padding, corner and shadow without a brief (2026-11-21).

## Round 1

### M-1 · blocker · A new kit row with one caller, against `add-design-brief`
**Answer:** To user → answered: feature-private `HistoryJumpRowLabel` inside `PVContextMenuItem` (D-4); kit path row Out until a second caller; map reworded.

### M-2 · major · `HistoryJumpMenuModel.keyboard(rowCount:)` and T-2 re-test kit behavior
**Answer:** Fixed — D-5 seeds `PVContextMenuKeyboard(itemCount:activeIndex:)` inline; T-2 now cites the existing `PVContextMenuTests`; the kit seed for a no-titles keyboard is an Out line for the third caller.

### M-3 · major · Without the overlay, `HistoryJumpMenuModel` reduces to one optional
**Answer:** Fixed — D-10 deletes the model; the toolbar holds `jumpMenuSide`; D-6's host measures its own button; stale comments in Deletes.

### M-4 · major · The sweep misses docs this PR makes false
**Answer:** Fixed — STEP-5 updates the idea file, the `PVActionMenu.swift` header; the S16-D11 map row was corrected in this commit; the DoD sweep covers `docs/**/*.md`.

### M-5 · minor · D-1's mouse-up branch does nothing
**Answer:** Fixed — D-1 adds code in `.mouseDown` only; mouse-up rows are regression rows.

### M-6 · minor · D-2's setter repeats `menuPresented`'s guard
**Answer:** Fixed — D-2 builds the menu state from the one `menuPresented` binding.

### M-7 · minor · T-3 adds a second `fittedWidth` test named for a caller
**Answer:** Fixed — D-8 / T-3 fold the cases into a parameterized `fittedWidthStaysInTheColumn`.

### X-1 · major · Most checks need a Mac
**Answer:** Fixed — §8 "Where checks run" says what to report when a check cannot run.

### X-2 · minor · D-1's mouse-up row already holds
**Answer:** Fixed — as M-5.

### X-3 · minor · Choices left open (missing anchor, seed count, modifier placement, `menuPresented`)
**Answer:** Fixed — D-6 draws `EmptyView()` without an anchor, seeds from `rows(…).count`, accepts the one-render gap, applies the host directly on `HistoryNavControl`; D-2 / D-10 keep `menuPresented`'s logic.

### X-4 · minor · Version bump and `completed.md` not in a Step
**Answer:** Fixed — STEP-5 names the version files and the `completed.md` heading.

### X-5 · minor · README Popup-row edit has no named spot
**Answer:** Fixed — STEP-5 gives the sentence and where it goes.

### X-6 · nit · Header and checker items
Logged. The map's Depends on now lists S16-50, S16-51, S16-52.

Round 2 follows: round 1 had a blocker.
