# Review — S16-50 One kit popup presenter, and the kit menus use it

**Verdict:** Fits with changes — Ready with changes
**Rounds:** 1. **Reviewers:** maintainability (Opus), executability (Sonnet)

## To user
- None.

## Writer's own calls
- **A click inside a menu no longer closes it** (D-4). Today any click inside an action menu closes it, a greyed-out row or the heading included. Enabled rows still close their menu themselves.
- **`PVSelect` closes on the release of a click outside, not the press** (D-8). Its press-closing existed only because its own opening release used to close it; the opening-press rule (D-5) removes that cause, so it takes the shared default instead of an option.
- **"Inside the popup" is any window at `.popUpMenu` level** (D-3), the test sheets already use. It assumes one kit popup open at a time.
- **No option without a caller** (D-7). Only `keysStayInField` ships; S16-51 and S16-53 add theirs.
- **The map's "closing on an app switch" is not a change.** Every `pvContextMenu` menu already closes on resign-key through its window host; the plan moves it into `.pvPopup`. The map row and scope entry are reworded to say so.
- **Patch bump** (0.29.0 → 0.29.1 at the planning base).

## Round 1

### X-1 · major · Home/End `delta` is not given when calling the shared mover
D-13 said Home/End go "through the shared mover" without the `delta` that `PVComboBoxMatch.move`'s step direction depends on; the wrong sign leaves Home at −1 on the Clear menu.
**Answer:** Fixed — D-14 gives each key's call (`delta: 1, edge: .first` for Home and ⌥↑, `delta: -1, edge: .last` for End and ⌥↓); D-13 routes all four through `PVListKeyboard.action`.

### X-2 · major · The opening-press flag for the `PVButton` trigger is stated two opposite ways
§6 Edges said no press is pending after the Clear button; §11 implied one is.
**Answer:** Fixed — §6 Edges Neighbors states the expected value (0 one main-queue turn after a mouse-up action) and why; §11 row 1 is now the unexpected case, with §10 step 4's "click empty space once" line and a Stop condition.

### X-3 · minor · `character` with empty `itemTitles`; `onKey` with no keyboard
**Answer:** Fixed — D-13: a letter with empty `itemTitles` is `.ignore`, as today; D-18: `onKey` is nil when no item is enabled, so only Escape is taken.

### X-4 · minor · Which `NSEvent` string feeds the key mapping
**Answer:** Fixed — D-10 names `event.charactersIgnoringModifiers`, as today.

### X-5 · minor · The `PVRightClickMenuModifier` rewrite was described two ways
**Answer:** Fixed — superseded by M-4: §6 macOS writes each caller's call shape against `.pvActionMenu`.

### X-6 · minor · STEP-5 did not say what to change in the README Select row
**Answer:** Fixed — STEP-5 gives the Select row's sentence (and the List row's, added for M-2).

### X-7 · minor · The map calls the app-switch close a change; Current state says it already happens
**Answer:** Fixed — §1 What stays and AC-2.6 say it is today's behaviour moving into the presenter; the map row and scope entry are reworded in the same commit as this log.

### X-8 · minor · Two quick keys before the deferred write-back act on a stale keyboard
**Answer:** Fixed — D-11 states the deferral is today's and accepts its consequence (a fast key repeat inside one main-queue turn starts from the same highlight).

### M-1 · blocker · The "skip rows you may not land on" rule stays copied in `PVSelectSession`
`PVSelectSession.moveCommitted`'s skip loop, `jumpCommitted`'s filter and `applyTypeSelect`'s blanked titles stay beside the new mover; D-14 then copied the blanking.
**Answer:** Fixed — D-16 adds `PVTypeSelectMatcher.index(…isDisabled:)` used by both the menu and `PVSelectSession`; D-17 moves `moveCommitted` and `jumpCommitted` onto the shared mover; the Out row now keeps only `PVSelectSession`'s key handling; AC-1.8 and §10 step 5 (Promote's menu-only Find…) check it in the app; `PVSelectSessionTests` must pass unchanged.

### M-2 · blocker · `PVPopupKey`, `PVPopupKeyResult` and `PVContextMenuKeyAction` add a key vocabulary beside the kit's
`PVListKeyboard.action` / `PVListKeyAction` and `KeyPress.Result` already do the job.
**Answer:** Fixed — D-10: keys are `KeyEquivalent`, `onKey` returns `KeyPress.Result`; D-11: `handle` returns `PVListKeyAction` (`.move(to: activeIndex)` for "consumed, unchanged"); D-14: `PVListKeyboard.action` takes `isDisabled` and the menu calls it with `option: false`; the three types are gone. Return keeps the menu rule in `handle` (D-13), not the list's clamp.

### M-3 · blocker · The `.popUpMenu` level test gets a second copy
**Answer:** Fixed — D-3: `PVOutsideClick.isInsideSheet` calls `PVPopupInput.isPopupWindow(level:)`; STEP-2 lists the file and runs `PVPanelFormDialogTests` unchanged.

### M-4 · major · Both action-menu callers wire the same three pieces, and a feature holds kit keyboard state
**Answer:** Fixed — D-18 adds `.pvActionMenu`, which holds the keyboard and seeds it on open; `PVRightClickMenuModifier` and the Clear menu call it; `clearKeyboard` and the planned `keyboardOnOpen:` parameter go (D-19).

### M-5 · minor · Two types for the rule where the precedent uses one
**Answer:** Fixed — D-2: `PVPopupDecision.decide`, no `PVPopupRules`.

### M-6 · minor · "Anchor to a button" was listed as a presenter option
**Answer:** Fixed — the Out row and Next adds put it in the window host (placement); only "ignore right-clicks" is a `PVPopupOptions` field for S16-53.

### M-7 · minor · After D-9 the two popup window hosts are near-copies
**Answer:** Logged — an Out row sends one child-panel host for the context menu and the combo box to S16-51, which moves the combo box's window.
