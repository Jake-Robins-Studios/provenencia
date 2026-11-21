# Review — S16-51 The combo box's list becomes a kit popup list

**Verdict:** (round 2 pending)
**Rounds:** 2. **Reviewers:** maintainability (Opus), executability (Sonnet)

## To user
- None.

## Writer's own calls
- **A click away closes the list on the release, not the press** (D-3). The map row's condition holds: rows commit on the release, inside the panel, which the presenter passes. Visible differences: holding the button outside keeps the list up until release; a click on the list's empty line or padding no longer closes it; a button pressed while the field shows typed text runs its action before the label comes back (it acts on the same pick as today).
- **⌘↑ lands on the first enabled row**, like Home (D-8). Today it stays put when the first row is disabled; no shipped combo box has a disabled option.
- **Return stays each field's** (D-5). Rule "(Batch 6) One kit popup list" lists Return among the list's keys; the plan reads it with the same rule's omnibar sentence and S16-57's rule: the list owns the highlight and its movement, each field keeps its Return.
- **The two window hosts fold into one** (D-14), from S16-50's Out (review M-7), though the map's scope entry did not name it; the scope entry now does.
- **Tests move with their subjects** (D-10, D-11): movement, landing and placement cases go to `PVPopupListTests` with the same inputs and results. The map Check is reworded from "pass unchanged" to say so.
- **Patch bump** (0.30.1 → 0.30.2 at the planning base).

## Round 1

### M-1 · blocker · The list's highlight rule is still split; `firstEnabledIndex` is a second first-row finder
`PVComboBoxMatch.firstEnabledIndex` hand-writes what the shared mover gives from −1; the completion and S16-52 reach into `PVComboBoxMatch` for it.
**Answer:** Fixed — D-5 adds `PVPopupListKeyboard.firstEnabled(count:isDisabled:)` on the shared mover; D-7, D-9 move both landings onto it; D-10 deletes `firstEnabledIndex` and moves its two tests (T-2b); Deletes, STEP-2 and the DoD sweep name it.

### M-2 · major · `PVPopupListKeyboard.move` would be a third list of movement keys
`PVListKeyboard.action` and `PVContextMenuKeyboard.handle` already list them.
**Answer:** Fixed — D-6 adds `PVListKeyboard.moveIndex(for:option:index:count:isDisabled:pageStep:) -> Int?`; `action`, `PVContextMenuKeyboard.handle` and `PVPopupListKeyboard.move` call it. T-5 covers it; Codebase fit has the row.

### M-3 · major · Next adds sends the history menu to a third window owner
**Answer:** Fixed — Next adds: S16-53 presents through `.pvContextMenu` / `.pvActionMenu` on `PVPopupWindowHost`, with an origin at its button; the host keeps two owners.

### M-4 · major · The popup list goes into the presenter's folder
`.cursor/rules/design-system-layers.mdc`: one folder per component.
**Answer:** Fixed — D-12 moves it to `Components/PopupList/`; the window host stays in `Popup/` as shared plumbing; STEP-5 adds a PopupList README row; AC paths follow.

### M-5 · minor · STEP-5 misses the FloatingMenuSelection row
**Answer:** Fixed — STEP-5 rewrites the FloatingMenuSelection and List rows.

### M-6 · minor · The host's autoclosure `hostingView`; repeated representable shell
**Answer:** Fixed (API) — D-14/D-15: the hosting view is made in `init`, with `rootView` and `fittingSize`. The shell fold is logged: two owners, the difference is their frame and re-frame rules.

### M-7 · minor · `inside` and `onAnchor` carried in two places
**Answer:** Declined — D-1: a hit enum would rewrite every `decidesEveryRow` row and `PVPopupInput.init?` for a fact only one option reads.

### M-8 · nit · The completion converts a delta to a key and back
**Answer:** Logged — the router and `PVTextAreaCompletionTests` stay as they are.

### M-9 · minor · `PVTable` and `PVSelectSession.jumpHighlight` keep their own movers
**Answer:** Fixed as an Out row (not planned; neither file is in this PR).

### X-1 · blocker · AC-3.2's `NSPanel` check hits comments
**Answer:** Fixed — AC-3.2 and STEP-4 search `: NSPanel\b|NSPanel\(` (a subclass or a construction); comments stay.

### X-2 · blocker · STEP-5's sweep fails on the FloatingMenuSelection row
**Answer:** Fixed — see M-5.

### X-3 · blocker · The Checks need `xcodebuild` and a Mac
**Answer:** Fixed — a Stop condition: without `xcodebuild`, report the `rg` and lint checks run and each Xcode or manual check as not run.

### X-4 · major · `PVListTests` both unchanged and edited
**Answer:** Fixed — STEP-2's Check and §8 say no existing case changes; T-5 is added.

### X-5 · major · `show(at:)` against today's `position`
**Answer:** Fixed — D-14: each coordinator gets `frame() -> CGRect?`, called from `show()` and `position()`.

### X-6 · major · Threading `onAnchor` through `apply`
**Answer:** Fixed — STEP-1: `apply` gains `onAnchor: Bool = false`; nil-safe `===` comparison; the resign call keeps the default.

### X-7 · minor · Small open choices
**Answer:** Fixed — `move` returns `moveIndex`'s result (nil for a non-movement key, D-5/D-6); `completionPresented` is a `fileprivate var` beside `completionPopup`, which stays (D-17); the README `wantsPresented` sentence is reworded (STEP-5); `PVPopupListTests` gets its own `option` helper and `pool` (D-10); STEP-6 bumps all four `MARKETING_VERSION` lines.
