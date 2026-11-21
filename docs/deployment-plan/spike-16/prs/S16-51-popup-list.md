# S16-51 — The combo box's list becomes a kit popup list

**Status:** Draft
**Spike / slice:** Spike 16 · Slice 6d — Popups
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: every combo box list and the format editor's completion draw as today; only the code that holds them and the moment a click away closes them change)
**Board:** —
**Depends on:** S16-50 (landed [#923](https://github.com/Jake-Robins-Studios/provenencia/pull/923)), S16-57 (landed [#925](https://github.com/Jake-Robins-Studios/provenencia/pull/925))
**Blocks:** S16-52
**Branch:** `s16-51-popup-list`
**Version bump:** patch — it changes shipped app behavior: a click away closes a combo box's list and the completion list on the release instead of the press, and ⌘↑ in a combo box lands on its first enabled row ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/design-system-layers.mdc`, `.cursor/rules/swift-tests.mdc`, `.cursor/rules/macos-client.mdc`, `.cursor/rules/versioning.mdc`
**Context:** working rules "(Batch 6) One kit popup presenter, with the shared closing rules", "(Batch 6) One kit popup list under the combo box and the omnibar" and "(Batch 6) A combo box passes Return on only when its field shows its pick"; bars 25 and 26 in [`../deployment-plan.md`](../deployment-plan.md#goal-dogfood-bar); the S16-51 scope entry in [`../deployment-plan.md`](../deployment-plan.md#s16-51--the-combo-boxs-list-becomes-a-kit-popup-list); the S16-50 plan's Out and Next adds ([`S16-50-popup-presenter.md`](S16-50-popup-presenter.md)); the kit README's Popup, ComboBox and TextArea rows and "The combo box subset" ([`macos/App/DesignSystem/README.md`](../../../../macos/App/DesignSystem/README.md))
**Planned:** 2026-11-21 against `main` @ `3b417f9`
**Review:** — (not reviewed yet)

### Implementer — read this first

1. **This file is the whole task.** Read it top to bottom before you change code. Then read every file under **Current state** and load every skill under **Skills to load**.
2. **Check the base.** Compare `main` with the **Planned** commit. If a file under **Current state** has changed so a row is no longer true, stop and report which rows.
3. **Decisions are made.** Do not reopen a **Decision** or a **Scope** line, and do not swap in a design you like better. If one cannot work, stop: say which ID it is, what you found (path, line, output), and what you would need. Do not improvise around it.
4. **Do only In.** Out stays out, even when it is one line away. Do not refactor, rename, or tidy code the plan does not name.
5. **Work the Steps in order.** Run each step's check before you start the next. A failing check is fixed in that step.
6. **Hit a Stop condition → stop.** Report it. Do not work around it.
7. **Done is the Definition of done.** Report each box with its evidence: the command and its result, the test name, or the manual check you ran.
8. **Docs-only lines in the DoD are part of the PR.** Do not skip them.

---

## 1. Objective

A combo box's list and the format editor's `{` completion are one kit popup list, `.pvPopupList`: its own window under the field (or at the caret), placed by one placement rule, closed through the kit presenter `.pvPopup`, and moved by one key rule. The popup list's own mouse-down monitor and app-switch observer go, so every floating popup in the kit closes the same way (bar 25). The context menu and the popup list show their windows through one window host. Every combo box and the completion look and work as today, except that a click away closes the list when the button is released, as every other kit menu does.

**Why now.** Working rule "(Batch 6) One kit popup list" (user, 2026-11-17). S16-50 built `.pvPopup` and moved the menus onto it, and sent the combo box's watcher and the one child-panel host here (its Out, review M-7). S16-52 draws the omnibar's results with this list, so the list must be a kit component first.

**What stays.** Every list's rows, card, width, height, placement and scrolling. `PVComboBox`'s field, its picked value, its query, its Spotlight highlight, its two-step Escape, its Tab and its Return rule exactly as S16-57 left it (`PVComboBoxMatch.returnAction`). The completion's keys (↑/↓, Return, Tab, Escape through the text view's commands) and its announcements. The context menu's look, placement and keys.

## 2. User stories

**US-1.** As a researcher picking from a combo box, the list behaves as it does today and closes the way every other kit menu closes, so that I never learn a second set of gestures.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A Source page, the Source type picker focused with Folio picked. Click the field | The list opens and stays open after the release |
| AC-1.2 | The list is open. Click the field again, or right-click it | The list stays open; the caret moves |
| AC-1.3 | The list is open. Press the mouse on the page outside the field and the list, hold, then release | The list stays open while the button is held, and closes on the release; the field loses focus and shows Folio |
| AC-1.4 | The list is open. Right-click outside the field and the list | The list closes; the field loses focus and shows Folio |
| AC-1.5 | The list is open. Switch to another app (⌘Tab) | The list closes; the field loses focus |
| AC-1.6 | The list is open. Press Escape; then Escape again | The first closes the list; the second, with typed text, puts Folio back; a third reaches the sheet or page, as today |
| AC-1.7 | The list is open. Click a row | That row is picked, the list closes, the field keeps focus, as today |
| AC-1.8 | The list is open, typed `zzz`, so the empty line shows. Click the empty line | The list stays open |
| AC-1.9 | Type `fo`. Press ↓, ↑, Home, End, Page Down, Page Up, ⌘↓, ⌘↑ | The highlight moves as today: clamped, no wrap, Page by 8, ⌘ to an end; Return then commits the highlighted row |
| AC-1.10 | Options [A *disabled*, B, C], list open, nothing highlighted. Press ⌘↑ | B is highlighted (today it stays where it was, as Home already does not) |
| AC-1.11 | Field cleared by hand with Folio picked, no row highlighted. Press Return | Nothing is added; the field keeps its text (S16-57, unchanged) |
| AC-1.12 | A combo box near the bottom of the window, or of the screen | The list opens above the field when there is more room there, as today; it follows the field when the window moves or the page scrolls |

**US-2.** As a researcher writing a citation format, the `{` completion works as today and closes the way every kit popup closes.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | A Source type's format editor. Type `{` | The list opens at the caret with every field |
| AC-2.2 | The list is open. Press ↓, then Return | The second row is written in and the list closes (`PVTextAreaCompletionTests.downThenReturnTakesTheSecondRowAndWritesItIn`) |
| AC-2.3 | The list is open. Click a row | It is written in and the list closes |
| AC-2.4 | The list is open. Click in the format text, away from the `{` | The list stays open while the caret is still in the placeholder, and closes when the caret leaves it, as today |
| AC-2.5 | The list is open. Click outside the text area and the list, and release | The list closes on the release |
| AC-2.6 | The list is open. Switch to another app | The list closes |
| AC-2.7 | The list is open. Press Escape | The list closes and stays closed until the next typed character (`escapeClosesTheListAndLeavesTheText`) |

**US-3.** As a contributor, the kit has one popup list, one popup window host and one key rule for a list's highlight, so that S16-52 draws the omnibar's results with them and adds no fourth copy.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `rg -n "addLocalMonitorForEvents\|didResignKeyNotification" macos/App/DesignSystem/Components/ComboBox macos/App/DesignSystem/Components/TextArea macos/App/DesignSystem/Components/PopupList macos/App/DesignSystem/Components/Popup/PVPopupWindowHost.swift` | No hit |
| AC-3.2 | `rg -n ": NSPanel\b|NSPanel\(" macos/App/DesignSystem` | One hit, in `PVPopupWindowHost.swift`; comments that name an `NSPanel` stay |
| AC-3.3 | `rg -n "PVComboBoxMatch\.(move\|Edge\|firstEnabledIndex)\|PVComboBoxPlacement\|Components/ComboBox/PVPopupList" macos .agents docs/*.md` | No hit |

## 3. Scope

| In | Covered by |
| --- | --- |
| `PVPopupOptions.staysOpenOnFieldClick` *(new)*: a mouse event on the anchor passes | STEP-1, AC-1.2, AC-2.4 |
| `PVPopupListKeyboard.move` *(new)*: the one highlight rule for a popup list's movement keys; `PVComboBox` and `PVTextAreaCompletionSession` call it; `PVComboBoxMatch.move` and `PVComboBoxMatch.Edge` go | STEP-2, AC-1.9, AC-1.10, AC-2.2 |
| `PVPopupWindowHost` *(new)*: one child-panel host; `PVContextMenuPopupWindow` and the popup list's window use it | STEP-4, AC-3.2 |
| `PVPopupList.swift` moves to its own folder, `Components/PopupList/`; `PVComboBoxPlacement` becomes `PVPopupListPlacement`; `View.pvPopupList` *(new)* composes the window and `.pvPopup`; the window's own monitor, app-switch observer and dismissal go | STEP-3, AC-1.1 – AC-1.8, AC-1.12, AC-3.1, AC-3.3 |
| `PVComboBox` and `PVTextArea` present through `.pvPopupList` | STEP-3, AC-1.1 – AC-1.8, AC-2.1 – AC-2.7 |
| Kit README (Popup, ComboBox, TextArea rows; "The combo box subset"), `add-ui-component`, and the S16-51 map Check | STEP-5 |

| Out | Home |
| --- | --- |
| The omnibar's results and `OmnibarResultsHost` | S16-52 |
| `PVComboBoxMatch.listLine` and `ListLine` moving into the kit list | S16-52, when the omnibar's searching line is the second caller; it stays on `PVComboBoxMatch` here |
| `PVComboBoxOption` renamed for the list (`PVTextAreaCompletion` and S16-52 also use it) | not planned: the name is used across features; a rename buys nothing this PR needs |
| The history menu and its window | S16-53 |
| Home/End, Page Up/Down or ⌘↑/⌘↓ in the completion list | not planned: in a text view those keys move the caret or scroll, as today |
| Settling ⌘ (combo box) against ⌥ (`PVTable`, `PVList`) as the jump-to-end modifier | not planned: the README's note on it stays; this PR keeps each as today |
| Renaming `L10n.DesignSystem.comboBoxSearching` | S16-52, if the omnibar draws the same line |
| `PVTable`'s own mover (`PVTableSelection.moveIndex`, its page step of 10) and `PVSelectSession.jumpHighlight` not skipping disabled rows (review M-9) | not planned: neither file is in this PR; the kit README's "do not write another highlight mover" stands for the next PR that touches them |
| A mouse-down close option for the presenter | not planned: rows commit on the release (D-4), so the combo box takes the presenter's defaults |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Popup list window | `macos/App/DesignSystem/Components/ComboBox/PVPopupList.swift` `PVPopupList` (an `NSViewRepresentable`) and its `Coordinator` (`applyPresentation`, `show`, `hide`, `tearDown`, `position`, `startWatching`, `stopWatching`, `handleMouseDown`, `dismiss`, `onDismiss`) | Shows `content` in a child `PVPopupPanel` (`.popUpMenu` level, `hasShadow = true`, never key) of the anchor's window, framed by `PVComboBoxPlacement.popupFrame` at the anchor's width (or `width`) and `min(contentHeight, maxHeight)`. Re-frames only when `contentHeight` or `optionCount` change. Follows the parent's move and resize and the enclosing scroll view. **Also closes itself:** a local monitor on `.leftMouseDown`, `.rightMouseDown`, `.otherMouseDown` calls `dismiss()` for any press that is neither in the panel nor inside the anchor's bounds; a `didResignKeyNotification` observer on the parent calls `dismiss()`. `dismiss()` sets `wantsPresented = false`, hides, and calls `onDismiss`. This is the second watcher rule "(Batch 6) One kit popup presenter" forbids |
| Panel and hosting classes | same file, `PVPopupPanel`, `PVPopupHostingView` | `canBecomeKey` / `canBecomeMain` false; `acceptsFirstMouse` true |
| List view | same file, `PVPopupListCard`, `PVPopupListRow`, `PVPopupListLine` | The card, scroller (`.pvScrollsRowIntoView`), row shell (highlight fill, `.onHover` highlights an enabled row, `.onTapGesture` commits on the release) and empty/searching line. Unchanged by this PR except for the file's folder |
| Placement | `macos/App/DesignSystem/Components/ComboBox/PVComboBox.swift` `PVComboBoxPlacement.popupFrame(anchor:contentHeight:visibleFrame:gap:)`, `PVComboBoxPlacement.gap` | Opens below, flips above when it does not fit and there is more room above, trimmed to the room, clamped to the screen's horizontal edges. Called only by `PVPopupList.Coordinator.position` |
| Combo box present | same file, `PVComboBox.body` | `.background(PVPopupList(isPresented: isOpen && rowsMeasured, maxHeight: maxListHeight, contentHeight: desiredPopupHeight, optionCount: visibleOptions.count, onDismiss: dismissAndBlur, content: openList))`. `dismissAndBlur` = `closeAndRestore()` then `focus.resign(own: $isFocused)` |
| Combo box keys | same file, `PVComboBox.handleKey`, `moveActive(delta:to:)` | ↓/↑ move by ±1 (⌘: `delta` ±1 with edge `.last` / `.first`); Home → `(1, .first)`; End → `(-1, .last)`; Page Down/Up → ±8; each opens a closed list first (`open()` resets the highlight), then `PVComboBoxMatch.move`. Return → `PVComboBoxMatch.returnAction`. Escape two-stage. Tab / Shift-Tab |
| ⌘↑ with a disabled first row | same, `handleKey` `.upArrow` with ⌘ → `moveActive(delta: -1, to: .first)` | `moveIndex` starts at 0 with `step = -1` (since `delta < 0`), cannot walk inward, and returns `index` unchanged. Home uses `delta: 1` and lands on the first enabled row. No shipped combo box passes a disabled option today (`rg -n "isDisabled: true" macos/App/Features` finds none for `PVComboBoxOption`) |
| Combo mover | same file, `PVComboBoxMatch.move(from:delta:in:to:)`, `PVComboBoxMatch.Edge` (a typealias for `PVFloatingMenuSelection.Edge`) | One call to `PVFloatingMenuSelection.moveIndex(from:delta:count:edge:isDisabled:)` (S16-50). Callers: `PVComboBox.moveActive`, `PVTextAreaCompletionSession.move` |
| Kit mover and list keys | `macos/App/DesignSystem/Components/FloatingMenuSelection/PVFloatingMenuSelection.swift` `moveIndex(from:delta:count:edge:isDisabled:)`; `macos/App/DesignSystem/Components/List/PVList.swift` `PVListKeyboard.action(for:option:index:count:isDisabled:)`, `PVListKeyboard.pageStep` (10) | `PVListKeyboard.action`: ↓/↑ (⌥ to an end, `(-1, .last)` / `(1, .first)`), Home `(1, .first)`, End `(-1, .last)`, Page ±`pageStep`, Return/Space activate, else `.ignore`; `.ignore` for every key when `count == 0` |
| Completion present | `macos/App/DesignSystem/Components/TextArea/PVTextArea.swift` `PVTextArea.completionPopup` | When `completion` is set: `PVPopupList(isPresented: completionSession.isOpen, maxHeight: PVTextAreaCompletionList.maxHeight, contentHeight: PVTextAreaCompletionList.height(rows:), optionCount:, width: PVTextAreaCompletionList.width, anchorRect: { session.caretRect() }, onDismiss: { session.close() }, content: PVTextAreaCompletionRows(…))`, attached as `.background(completionPopup)` to the editor stack, so the anchor is the whole area |
| Completion keys | same file, `PVTextAreaCompletionSession.handle(_:)`, `move(_:)`, `highlight(at:)`, `accept(at:)`, `close()`; `PVTextAreaTabRouter.textView(_:doCommandBy:)`, `textDidEndEditing` | Keys arrive as text-view commands. `moveUp:` / `moveDown:` → `move(∓1)` through `PVComboBoxMatch.move`; `insertNewline:` / `insertTab:` accept the highlighted row (or pass); `cancelOperation:` sets `escaped` and closes. Ending editing closes |
| Presenter | `macos/App/DesignSystem/Components/Popup/PVPopup.swift` `PVPopupOptions` (`keysStayInField`), `PVPopupInput`, `PVPopupDecision.decide(_:openingPressPending:options:)`, `PVPopupOpeningPress`, `PVPopupWatcherView` (private), `View.pvPopup(isPresented:options:onKey:)` | The one watcher (S16-50). A left mouse-up outside the popup closes; left mouse-down passes; right/other mouse-down outside closes; a click in a `.popUpMenu`-level window passes; the opening press's release ends it; resign key closes; Escape closes unless `keysStayInField`. It has no notion of the anchor: a click on the field itself is "outside". Closing writes `isPresented = false` one main-queue turn later |
| Context-menu window | `macos/App/DesignSystem/Components/ContextMenu/PVContextMenu.swift` `PVContextMenuPopupWindow` and its `Coordinator`; `PVContextMenuNSPanel`, `PVContextMenuHostingView` | The same panel plumbing as the popup list (create, attach as child above, follow move / resize / scroll, hide, tear down), with `hasShadow = false`, its frame from `hosting.fittingSize` and `PVContextMenuPlacement.panelFrame`, set only when it differs. S16-50 already removed its closing (it follows `isPresented` only) |
| Tests | `macos/ProvenenciaTests/PVComboBoxTests.swift` (movement: `movingFromNothingActiveLandsOnTheNearEnd`, `movementClampsAtBothEndsRatherThanCycling`, `edgeJumpsGoToFirstAndLast`, `movementStepsOverDisabledRows`, `movementStaysPutWhenOnlyDisabledRowsRemain`, `movementOnAnEmptyListIsNegative`; placement: `popupHangsBelowTheFieldWhenThereIsRoom`, `popupFlipsAboveTheFieldWhenItWillNotFitBelow`, `popupNeverOverlapsTheField`, `popupStaysInsideTheVisibleFrame`, `popupTrimsItsHeightToTheRoomAvailable`, `popupIsClampedToTheScreensHorizontalEdges`); `macos/ProvenenciaTests/PVTextAreaCompletionTests.swift` (`theListFlipsAboveTheCaretWhenTheScreenHasNoRoomBelow` calls `PVComboBoxPlacement.popupFrame`); `macos/ProvenenciaTests/PVPopupTests.swift` (`PVPopupDecisionTests.decidesEveryRow`, `PVPopupInputTests`, `PVPopupOpeningPressTests`); `macos/ProvenenciaTests/PVListTests.swift` | No test covers the popup list's monitor (it lives in a coordinator) |
| Xcode project | `macos/Provenencia.xcodeproj/project.pbxproj` | `App/DesignSystem` is a synchronized folder: moving a Swift file within it needs no project edit (kit README "Xcode project registration") |

**Precedent.** S16-50 ([#923](https://github.com/Jake-Robins-Studios/provenencia/pull/923), `cf80b8a`) moved the context menu and `PVSelect` onto `.pvPopup`: the window host stopped closing (its click monitor and resign-key observer went) and the presenter was attached beside it on the same anchor. Copy that split: the window follows `isPresented`, the presenter writes it. S15-17's `2729f59` moved the list view into `PVPopupList.swift` so both callers draw one card; copy its "no behavior change, tests pass unchanged" discipline. Do not copy S16-50's `.pvActionMenu` keyboard state: a popup list's keys stay in its field (D-5).

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `PVPopupOptions` gains `staysOpenOnFieldClick: Bool = false`. `PVPopupDecision.decide` gains a parameter `onAnchor: Bool = false` before `options:`. When `options.staysOpenOnFieldClick && onAnchor`, every mouse input decides `.pass`, except a mouse-up while `openingPressPending`, which stays `.endOpeningPress`. Every other row of S16-50's table is unchanged | The rule names "the combo box stays open on a click in its own field" as an option on the presenter; S16-50's Next adds named the field. A defaulted parameter leaves `decidesEveryRow` and every existing call unchanged | A third associated value on `PVPopupInput.mouseDown` / `.mouseUp` — because every existing test row and `init?(_:)` would change for a fact only one option reads |
| D-2 | The watcher computes `onAnchor` for a mouse event as: `event.window === window` and `bounds.contains(convert(event.locationInWindow, from: nil))`, where `window` and `bounds` are the watcher view's own. The watcher is a `.background` of its anchor, so its bounds are the anchor's | The anchor view is already the watcher's own view (S16-50 Next adds); the popup list's monitor made the same test against its anchor | Passing the anchor's frame in from the caller — because the watcher already is the anchor's background |
| D-3 | The popup list's click-away moves from mouse-down to the presenter's defaults: a left click outside closes on the release; a right or other press outside closes on the press; a click in the popup passes | The map row: "moves to the presenter's mouse-up only if the plan shows a row still commits". A row commits through `PVPopupListRow`'s `.onTapGesture`, which fires on the release, inside the `.popUpMenu` panel, which the presenter passes (D-3 of S16-50). So a row still commits, and a click on the empty line or the card's padding no longer closes the list (AC-1.8) | Keeping mouse-down as a presenter option — because the map row keeps it only if rows could not commit |
| D-4 | `.pvPopupList` always presents with `PVPopupOptions(keysStayInField: true, staysOpenOnFieldClick: true)`; neither is a parameter | Both callers' fields keep focus and take their own keys (the combo's two-step Escape; the completion's Escape sets `escaped`, which a presenter close would skip), and both stay open on a click in their own field or area. S16-52's omnibar has a focused command field too | Parameters for them — because no caller would pass a value other than true |
| D-5 | The keys stay in the field. The list's part is its highlight rule, `enum PVPopupListKeyboard` *(new, in `PVPopupList.swift`)*: `static let pageStep = 8`; `static func move(_ key: KeyEquivalent, command: Bool, from index: Int, count: Int, isDisabled: (Int) -> Bool) -> Int?`, which returns `PVListKeyboard.moveIndex(for: key, option: command, index: index, count: count, isDisabled: isDisabled, pageStep: pageStep)` (D-6); and `static func firstEnabled(count: Int, isDisabled: (Int) -> Bool) -> Int`, the Spotlight landing, which returns `PVFloatingMenuSelection.moveIndex(from: -1, delta: 1, count: count, isDisabled: isDisabled)` (the first enabled row; −1 when every row is disabled or there are none). Return stays the field's: the combo box's `PVComboBoxMatch.returnAction` (S16-57), the completion's `insertNewline:` branch, S16-52's omnibar's "Return opens and clears" | The rule gives the list the keys and the highlight (skipping disabled rows), and gives each field its own Return (the omnibar's command field; S16-57's rule). The popup window never becomes key, so every key reaches the field first; the field forwards movement to the list's rule. The highlight's landing, its movement and its page step live in one namespace on the one mover (review M-1) | A key handler on the list that takes Return too — because Return with no highlighted row does a different thing in each field, and with one each field commits a different thing; the handler would be a switch on its caller. Copying `PVListKeyboard.action`'s movement switch with ⌘ and 8 — because it would be a third list of movement keys (review M-2) |
| D-6 | One list of movement keys: `PVListKeyboard.moveIndex(for key: KeyEquivalent, option: Bool, index: Int, count: Int, isDisabled: (Int) -> Bool = { _ in false }, pageStep: Int = PVListKeyboard.pageStep) -> Int?` *(new, `PVList.swift`)*. It returns nil for a key other than ↑, ↓, Home, End, Page Up and Page Down; otherwise the shared mover's index with today's movement rules (↓/↑, ⌥ to an end, Home `(1, .first)`, End `(−1, .last)`, Page ±`pageStep`), which is −1 when `count == 0`. `PVListKeyboard.action` gains the same `pageStep:` parameter, keeps its `count > 0` guard, and maps a non-nil `moveIndex` to `.move(to:)`, Return/Space to `.activate` as today, else `.ignore`. `PVContextMenuKeyboard.handle`'s `.upArrow, .downArrow, .home, .end` branch calls `moveIndex` instead of `action` and unwrapping `.move` (its `itemCount == 0` guard comes first, as today; Page keys never reach a menu, `PVPopupInput.keyEquivalent` maps none) | The movement keys were listed in `PVListKeyboard.action` and filtered again in `PVContextMenuKeyboard.handle`; the popup list would have been a third copy (review M-2). With nothing passed, every result equals today's (`PVListTests`, `PVContextMenuTests` keep every case) | A second `action` overload — because it would repeat the body |
| D-7 | `PVComboBox.handleKey` sends every key to `PVPopupListKeyboard.move` first. When it is non-nil: open a closed list (`open()`), then set `activeIndex` to `PVPopupListKeyboard.move` computed from the post-open `activeIndex` over `visibleOptions`, and return `.handled`. Return, Escape, Tab and Shift-Tab keep their cases unchanged. `moveActive(delta:to:)` goes. `resetActiveRow` lands with `PVPopupListKeyboard.firstEnabled(count: visibleOptions.count, isDisabled: { visibleOptions[$0].isDisabled })` | Today's order: open first (which resets the highlight), then move from there | Moving from the pre-open index — because a closed list's index is −1 and `open()` may pre-highlight the top hit |
| D-8 | ⌘↑ takes `PVListKeyboard.action`'s jump, `(1, .first)`, like Home, so with a disabled first row it lands on the first enabled row (AC-1.10). ⌘↓, Home, End, ↑, ↓, Page Up and Page Down give today's index for every input | One rule for "jump to the first row"; today's ⌘↑ is the only key that cannot walk inward. No shipped combo box has a disabled option, so no researcher sees a change today | Keeping ⌘↑'s `(-1, .first)` — because it would need its own case beside `PVListKeyboard.action` for a result no one wants |
| D-9 | `PVTextAreaCompletionSession.move(_ delta:)` asks `PVPopupListKeyboard.move(delta > 0 ? .downArrow : .upArrow, command: false, from: activeIndex, count: options.count, isDisabled: { options[$0].isDisabled })` and otherwise works as today (it keeps its guard and its announcement). `evaluate` lands with `PVPopupListKeyboard.firstEnabled(count: rows.count, isDisabled: { rows[$0].isDisabled })` | One highlight rule for both callers | Leaving it on `PVComboBoxMatch.move` — because that wrapper then has one caller and the kit two rules |
| D-10 | `PVComboBoxMatch.move`, `PVComboBoxMatch.Edge` and `PVComboBoxMatch.firstEnabledIndex` go. The two `firstEnabledIndex` tests (`firstEnabledIndexSkipsDisabledLeadingRows`, `firstEnabledIndexIsNegativeWhenEveryRowIsDisabled`) move to `PVPopupListKeyboardTests` as `firstEnabled` cases with the same inputs and results. The six movement tests move to `PVPopupListTests` as `PVPopupListKeyboard.move` cases with the same inputs and expected results: `(from, +1)` → `.downArrow`, `(from, −1)` → `.upArrow`, `(from, +8)` → `.pageDown`, `to: .last` → `.end`, `to: .first` → `.home`. `PVPopupListTests.swift` gets its own private `option(_:_:disabled:)` helper and `pool` (three rows), copied from `PVComboBoxTests` | Their last callers move (D-5, D-7, D-9). The map Check "the combo box and `PVTextAreaCompletionTests` pass unchanged" holds for every case's input and expected result; a case whose subject moves to the kit moves with it (STEP-5 rewords the map Check to say so) | Keeping `PVComboBoxMatch.move` for its tests — because it would be code with no caller |
| D-11 | `PVComboBoxPlacement` becomes `PVPopupListPlacement` (same members: `gap`, `popupFrame(anchor:contentHeight:visibleFrame:gap:)`, same body), in the moved `PVPopupList.swift` (new path under `Components/PopupList/`). Its six tests move to `PVPopupListTests` unchanged but for the type name; `PVTextAreaCompletionTests.theListFlipsAboveTheCaretWhenTheScreenHasNoRoomBelow` changes only the type name | The rule: the list owns its placement. Both callers' placement is the list's, not the combo box's | A `typealias PVComboBoxPlacement` — because it keeps a name for one test file |
| D-12 | `ComboBox/PVPopupList.swift` moves to `Components/PopupList/PVPopupList.swift` with `git mv`. The `NSViewRepresentable` `PVPopupList` becomes `private struct PVPopupListWindow`; the public surface is the modifier `View.pvPopupList(isPresented: Binding<Bool>, isMeasured: Bool = true, maxHeight: CGFloat, contentHeight: CGFloat, optionCount: Int, width: CGFloat? = nil, anchorRect: (() -> CGRect?)? = nil, @ViewBuilder content: () -> Content)` *(new)*. It attaches `.background(PVPopupListWindow(isPresented: isPresented.wrappedValue && isMeasured, …))` and then `.pvPopup(isPresented: isPresented, options: PVPopupOptions(keysStayInField: true, staysOpenOnFieldClick: true))`. `PVPopupListCard`, `PVPopupListRow` and `PVPopupListLine` move with the file unchanged | One modifier attaches the window and its watcher together, so no caller can show the window without the closing rules. One folder per component (`.cursor/rules/design-system-layers.mdc`): the list has its own modifier, placement, keyboard, views and tests; the window host is shared popup plumbing and sits in `Popup/` beside the presenter | Callers attaching `PVPopupList` and `.pvPopup` side by side — because a caller could then attach one without the other |
| D-13 | `PVPopupListWindow`'s coordinator loses `clickMonitor`, `handleMouseDown`, the `didResignKeyNotification` observer, `dismiss()`, `onDismiss` and the `onDismiss` property of the representable. It keeps `wantsPresented`, re-framing only on a change of `contentHeight` or `optionCount`, the widening of the content to the panel's width, the environment hand-over, and the follow observers (through D-14) | One watcher per popup (rule); S16-50 D-9 did the same to the context menu's window | Keeping the resign-key observer as a second close path — because the rule forbids a second watcher |
| D-14 | One window host: `@MainActor final class PVPopupWindowHost` *(new) file `macos/App/DesignSystem/Components/Popup/PVPopupWindowHost.swift`)*. It owns one borderless, non-activating child panel at `.popUpMenu` level that never becomes key or main, with a clear background, `animationBehavior = .none` and `hasShadow` from its init; one `NSHostingView<AnyView>`, made in `init`, whose `acceptsFirstMouse` is true; adding the panel as a child above the anchor's window and removing it; and the follow observers (parent `didMoveNotification`, `didResizeNotification`, the anchor's enclosing clip view's `boundsDidChangeNotification`), which call `onFollow`. `PVContextMenuPopupWindow.Coordinator` (with `hasShadow: false`) and `PVPopupListWindow.Coordinator` (with `hasShadow: true`) each hold one and keep their own frame math and their own "when to re-frame" rule. Each coordinator gets `private func frame() -> CGRect?` (today's frame computation of its `position`, which returns nil without an anchor window), called from its `show()` (`host.show(at:)`) and its `position()` (`host.setFrame`); each keeps `wantsPresented`, `applyPresentation` and `setContent`. The shared representable shell (anchor, update hop, dismantle) stays per owner: the host has two owners (review M-6, logged) `PVPopupPanel`, `PVPopupHostingView`, `PVContextMenuNSPanel` and `PVContextMenuHostingView` go | S16-50 review M-7: the two coordinators are near-copies apart from their frame math, and S16-50 sent the fold here. S16-52's list and S16-53's history menu then need no third copy | Folding the frame math in too — because the menu frames at a point from its fitted size and the list frames against an anchor rect from a measured height; a strategy parameter would be a switch on the caller |
| D-15 | `PVPopupWindowHost`'s surface (signatures only, §6 macOS): `init(hasShadow: Bool)`, `weak var anchor: NSView?`, `var onFollow: () -> Void`, `var isShown: Bool { get }`, `var rootView: AnyView` (the hosting view's root), `var fittingSize: CGSize { get }` (the hosting view's), `func show(at frame: CGRect)` (makes the panel on first call; no-op when shown or the anchor has no window; frames, adds the child, starts following), `func setFrame(_ frame: CGRect)` (no-op when equal to the panel's frame; then `invalidateShadow()` when `hasShadow`), `func hide()`, `func tearDown()` | Each owner keeps reading its own fields when it frames, as both do today; the host holds only what is identical | A host that takes a frame closure and calls it — because both owners already decide when to frame and from which values |
| D-16 | `PVComboBox` presents with `.pvPopupList(isPresented: popupPresented, isMeasured: rowsMeasured, maxHeight: maxListHeight, contentHeight: desiredPopupHeight, optionCount: visibleOptions.count) { openList }` where `popupPresented` is `Binding(get: { isOpen }, set: { open in if !open, isOpen { dismissAndBlur() } })`. Its own closes (a commit, Escape, Tab, focus loss) keep setting `isOpen` directly, so they do not blur | The presenter's close is today's `onDismiss: dismissAndBlur` (a click away, an app switch). The `isOpen` guard keeps a close queued behind another close from blurring a field that already closed | An `.onChange(of: isOpen)` that blurs — because it cannot tell the presenter's close from Escape's |
| D-17 | `PVTextArea.completionPopup` becomes `.background { if let completion { Color.clear.pvPopupList(isPresented: completionPresented, maxHeight: PVTextAreaCompletionList.maxHeight, contentHeight: PVTextAreaCompletionList.height(rows: completionSession.options.count), optionCount: completionSession.options.count, width: PVTextAreaCompletionList.width, anchorRect: { [session = completionSession] in session.caretRect() }) { PVTextAreaCompletionRows(session: completionSession, completion: completion) } } }`, at the same place in the chain, where `completionPresented` is a `fileprivate var` in the same `PVTextArea` extension as `completionPopup` (which stays, rewritten), `Binding(get: { completionSession.isOpen }, set: { open in if !open { completionSession.close() } })` | The `Color.clear` background has the area's frame, so the anchor and "on the field" are the whole area, as today's anchor; a text area with no completion builds nothing, as today | Applying `.pvPopupList` to every text area with a constant false binding — because every `PVTextArea` in the app would then hold a watcher and a window host |
| D-18 | Tests: Swift Testing, no window. `PVPopupDecisionTests.staysOpenOnFieldClickRows` *(new)* drives `decide` with `onAnchor`; `macos/ProvenenciaTests/PVPopupListTests.swift` *(new)* holds `PVPopupListKeyboardTests` and `PVPopupListPlacementTests`. The window host, the watcher's `onAnchor` geometry and the event monitor are not unit-tested; §10 covers them | S16-50 D-21: a local monitor only sees events the app dispatches, which a test cannot post | A hosted-window test of the host — because `.hostedWindows` tests show no window (Batch 3) and the panel's frame is already `popupFrame`'s, which is tested |

**Rules this plan bends.** None. Rule "(Batch 6) One kit popup list" lists Return among the list's keys; D-5 reads it with the same rule's own sentence that the omnibar keeps its command field ("Return opens and clears") and with rule "(Batch 6) A combo box passes Return on only when its field shows its pick", so the list holds the highlight Return reads and each field keeps its Return.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `PVPopupOptions.staysOpenOnFieldClick` *(new)* | field | `PVPopupOptions.keysStayInField` | Extends the presenter's options, as S16-50 planned |
| `decide(…onAnchor:…)` *(new parameter)* | parameter | `PVPopupDecision.decide` | Extended, defaulting to false |
| `macos/App/DesignSystem/Components/Popup/PVPopupWindowHost.swift` *(new)*, `PVPopupWindowHost` *(new)* | file, class | `PVPopupList.Coordinator`, `PVContextMenuPopupWindow.Coordinator` | Their shared panel plumbing becomes this one class (D-14) |
| `macos/App/DesignSystem/Components/PopupList/PVPopupList.swift` *(new)* (the moved file) | file | `macos/App/DesignSystem/Components/ComboBox/PVPopupList.swift` | The same file, moved (D-12) |
| `View.pvPopupList(…)` *(new)* | modifier | `PVPopupList` (representable), `View.pvPopup` | Composes them (D-12) |
| `PVPopupListWindow` *(new name, private)* | representable | `PVPopupList` | The same type, renamed, minus its watcher (D-13) |
| `PVPopupListPlacement` *(new name)* | enum | `PVComboBoxPlacement` | The same type, renamed (D-11) |
| `PVPopupListKeyboard.move`, `PVPopupListKeyboard.firstEnabled`, `PVPopupListKeyboard.pageStep` *(new)* | funcs, constant | `PVComboBoxMatch.move`, `PVComboBoxMatch.firstEnabledIndex`, `PVListKeyboard.action` | Forward to `PVListKeyboard.moveIndex` and the shared mover (D-5); replace the two `PVComboBoxMatch` helpers (D-10) |
| `PVListKeyboard.moveIndex(for:option:index:count:isDisabled:pageStep:)` *(new)* | func | `PVListKeyboard.action`'s movement cases, `PVContextMenuKeyboard.handle`'s movement branch | The one list of movement keys; both call it (D-6) |
| `PVListKeyboard.action(…pageStep:)` *(new parameter)* | parameter | `PVListKeyboard.action` | Extended, defaulting to `PVListKeyboard.pageStep` (D-6) |
| `macos/App/DesignSystem/Components/PopupList/` *(new)* folder | folder | `Components/Popup/`, `Components/ComboBox/` | One folder per component (D-12) |
| `macos/ProvenenciaTests/PVPopupListTests.swift` *(new)*: `PVPopupListKeyboardTests`, `PVPopupListPlacementTests` *(new)* | tests | `PVComboBoxTests` (movement, placement) | The subjects moved to the kit; `add-swift-test` puts a type's tests in its own file |
| `PVPopupDecisionTests.staysOpenOnFieldClickRows` *(new)* | test | `PVPopupDecisionTests.decidesEveryRow` | A second argument list for the new parameter, so the existing rows stay as they are |

Searched for: `NSPanel`, `addChildWindow`, `addLocalMonitorForEvents`, `didResignKeyNotification`, `popupFrame`, `moveIndex`, `firstEnabledIndex`, `PVListKeyboard.action`, `case .upArrow, .downArrow` across `macos/App`. The only other popup window is the history menu's (`WorkspaceToolbar.swift`, S16-53) and the omnibar's overlay (S16-52).

**Builds on.** `.pvPopup` and `PVPopupDecision` (S16-50), `PVListKeyboard.action` and `PVFloatingMenuSelection.moveIndex` (the kit's one mover, S16-50), `PVPopupListCard` / `PVPopupListRow` / `PVPopupListLine` (S15-17), `PVComboBoxMatch.returnAction` (S16-57), `PVComboBoxMatch.firstEnabledIndex`.

**Deletes.**
- `PVPopupList.Coordinator`: `clickMonitor`, `handleMouseDown`, `dismiss()`, `onDismiss`, the `didResignKeyNotification` observer, and the panel plumbing that moves to the host (`panel`, `hosting`, `observers`, panel creation in `show`, `startWatching`, `stopWatching`); the representable's `onDismiss` property.
- `PVPopupPanel`, `PVPopupHostingView`, `PVContextMenuNSPanel`, `PVContextMenuHostingView`.
- `PVContextMenuPopupWindow.Coordinator`'s `panel`, `hosting`, `observers`, panel creation, `startWatching`, `stopWatching` (to the host).
- `PVComboBoxMatch.move`, `PVComboBoxMatch.Edge`, `PVComboBoxMatch.firstEnabledIndex`; `PVContextMenuKeyboard.handle`'s `PVListKeyboard.action` call and `.move` unwrap in its movement branch; `PVComboBox.moveActive(delta:to:)` and the separate ↓/↑, Home, End, Page cases of `handleKey`.
- `PVComboBoxPlacement` (renamed).
- The path `macos/App/DesignSystem/Components/ComboBox/PVPopupList.swift`.
- In `PVComboBox.swift`'s comments: the `onChange(of: fieldIsFocused)` sentence "The popup's mouse monitor still catches clicks on things that take no focus" and the type doc's "`PVComboBoxPlacement` positions it" (rewritten for `.pvPopupList` and `.pvPopup`). In `PVContextMenu.swift`: "Mirrors `PVPopupList`" (rewritten for `PVPopupWindowHost`).
- README "The combo box subset": the "Dismissal converges on focus" bullet's local mouse-down monitor and resign-key sentences, the "mouse monitor passes panel clicks through" clause, and the pure-parts paragraph's `PVComboBoxPlacement` (STEP-5).

**Next adds.** S16-52 draws the omnibar's results with `.pvPopupList` (its field keeps Return and Escape; its movement keys go through `PVPopupListKeyboard.move`), lifts `PVComboBoxMatch.listLine` into the list when its searching line is the second caller, and deletes `OmnibarResultsHost.armDismissMonitor`. S16-53's history menu presents through `.pvContextMenu` / `.pvActionMenu`, whose window is `PVContextMenuPopupWindow` on `PVPopupWindowHost`, with an origin at its button (S16-50 Next adds), and adds `PVPopupOptions.ignoresRightClicks`; the host keeps two owners.

### Reach

None — no new path into existing code. The new state, a popup list open while a left button is held outside it (AC-1.3), draws the same list; a click on the list's empty line or padding, which used to close it, now leaves it open (AC-1.8) and does nothing.

### Scale

None — no write, list or loop changes. One watcher and one window host per open list, as today; `PVPopupListKeyboard.move` is linear in the visible rows (the Properties picker: about 60).

### Edges

The decision table gains one rule (D-1). `F` is `options.staysOpenOnFieldClick && onAnchor`. Every row is a T-1 case:

| Input | `openingPressPending` | `F` | Decision |
| --- | --- | --- | --- |
| `.mouseUp(any, inside: any)` | true | any | `.endOpeningPress` (unchanged) |
| `.mouseUp(.left, inside: false)` | false | true | `.pass` |
| `.mouseUp(.left, inside: false)` | false | false | `.close(consumesEvent: false)` (unchanged) |
| `.mouseDown(.right` or `.other, inside: false)` | any | true | `.pass` |
| `.mouseDown(.right` or `.other, inside: false)` | any | false | `.close(consumesEvent: false)` (unchanged) |
| `.mouseDown(.left, any)` | any | any | `.pass` (unchanged) |
| `.key(any)`, `.windowResignedKey` | any | any | unchanged: `onAnchor` is only computed for mouse events |

- **Assumptions.** (1) The watcher's bounds are the anchor's: `.pvPopup` and the window are both `.background`s of the same anchor (D-2, D-12). (2) A row's commit is `PVPopupListRow`'s `.onTapGesture`, on the release, in the panel; the presenter passes it (D-3). The completion's rows and the combo's rows both use `PVPopupListRow`. (3) Every key reaches the field: the panel never becomes key (`canBecomeKey` false, D-14); the presenter watches no keys (D-4). (4) With nothing disabled, `PVPopupListKeyboard.move` returns today's `PVComboBoxMatch.move` result for every key the combo box and the completion send: ↓ `(+1)`, ↑ `(−1)`, Home `(1, .first)`, End `(−1, .last)`, ⌘↓ `(−1, .last)` (today `(1, .last)`, which starts at the last row and steps by −1 because of `edge == .last`: the same), Page ±8; T-3 holds each against the moved cases. With a disabled first row only ⌘↑ changes (D-8).
- **Neighbors.** A click on the field while the list is open: on the anchor, passes (AC-1.2); a click on the field while it is closed opens it through the field's `TapGesture` on the release; the watcher arms one turn later with no press pending, so nothing closes. A press outside held over a moment: the list stays until the release (AC-1.3); during the hold the page may scroll (a scroll-bar drag) and the list follows it (`onFollow`). A click on another focusable field: its press takes focus, `onChange(of: fieldIsFocused)` closes and restores at the press, as today; the release then finds the presenter already disarmed. A click on a button outside while the field shows typed text over a pick: the button's action runs on the release, then the presenter's deferred close restores the label and blurs; today the label was restored at the press. The button acts on the same pick either way (it reads `selection`, never the field's text); only the moment the label comes back moves. A click in the completion's text area away from the placeholder: on the anchor, passes; the caret move re-evaluates and closes the list if the context is gone (AC-2.4), as today. A right-click in the text area opens the text view's own menu, a `.popUpMenu`-level window: clicks in it pass, as in S16-50's Assumptions (2).
- **Removed inputs.** None — the decision reads only the event and its flags.
- **Real data.** The callers: `rg -n "PVComboBox\(" macos/App/Features` lists eight files (`PropertiesView.swift`, `SourceTitleTypeFields.swift`, `MetadataBoardView.swift`, `SourcePageIdentityHeader.swift`, `SourceTypeFormatsSection.swift`, `SourceTypeSuggestionList.swift`, `CitationComposerAuthoringBox.swift`, `PromoteView.swift`); none changes. `rg -n "completion:" macos/App/Features --glob '*.swift'` lists the text areas with a completion (the format editor); none changes.
- **Untrusted size.** None — rows are the caller's.

### Schema

None — no catalog change.

### Go core

None — Swift only.

### FFI

None — no engine call changes.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Presenter option | `PVPopupOptions.staysOpenOnFieldClick`, `decide(…onAnchor:…)` | `macos/App/DesignSystem/Components/Popup/PVPopup.swift` | D-1, D-2; the watcher passes `onAnchor` for mouse events |
| Window host | `PVPopupWindowHost` *(new)* | `macos/App/DesignSystem/Components/Popup/PVPopupWindowHost.swift` | D-14, D-15 |
| Popup list | `View.pvPopupList` *(new)*, `PVPopupListWindow` (private), `PVPopupListPlacement`, `PVPopupListKeyboard`, `PVPopupListCard`, `PVPopupListRow`, `PVPopupListLine` | `macos/App/DesignSystem/Components/PopupList/PVPopupList.swift` | D-5, D-11 – D-13 |
| Context-menu window | `PVContextMenuPopupWindow` | `macos/App/DesignSystem/Components/ContextMenu/PVContextMenu.swift` | Holds a `PVPopupWindowHost(hasShadow: false)`; keeps `position(reframeIfSizeChanged:)`'s frame math and `shownSize` |
| Combo box | `PVComboBox` | `macos/App/DesignSystem/Components/ComboBox/PVComboBox.swift` | D-7, D-16 |
| Completion | `PVTextArea.completionPopup`, `PVTextAreaCompletionSession.move` | `macos/App/DesignSystem/Components/TextArea/PVTextArea.swift` | D-9, D-17 |

Sketch (signatures only):

```swift
struct PVPopupOptions: Equatable {
    var keysStayInField = false
    var staysOpenOnFieldClick = false
}
enum PVPopupDecision: Equatable {
    static func decide(_ input: PVPopupInput, openingPressPending: Bool,
                       onAnchor: Bool = false, options: PVPopupOptions) -> PVPopupDecision
}
@MainActor final class PVPopupWindowHost {
    init(hasShadow: Bool)
    weak var anchor: NSView?
    var onFollow: () -> Void
    var isShown: Bool { get }
    var rootView: AnyView
    var fittingSize: CGSize { get }
    func show(at frame: CGRect)
    func setFrame(_ frame: CGRect)
    func hide()
    func tearDown()
}
enum PVPopupListPlacement {
    static let gap: CGFloat
    static func popupFrame(anchor: CGRect, contentHeight: CGFloat, visibleFrame: CGRect, gap: CGFloat = gap) -> CGRect
}
enum PVPopupListKeyboard {
    static let pageStep = 8
    static func move(_ key: KeyEquivalent, command: Bool, from index: Int, count: Int,
                     isDisabled: (Int) -> Bool) -> Int?
}
extension View {
    func pvPopupList<Content: View>(
        isPresented: Binding<Bool>, isMeasured: Bool = true,
        maxHeight: CGFloat, contentHeight: CGFloat, optionCount: Int,
        width: CGFloat? = nil, anchorRect: (() -> CGRect?)? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View
}
```

`PVPopupListWindow.Coordinator.position()` keeps today's body: read the anchor rect (or `anchorRect()`), apply `width`, set `host.rootView` to the content widened to that width, compute `PVPopupListPlacement.popupFrame` against the screen's visible frame, and return it from `frame()`; `position()` calls `host.setFrame(frame)`. `show()` sets `host.rootView`, gets `frame()`, and calls `host.show(at:)`. `host.onFollow` is `position()`. `PVContextMenuPopupWindow.Coordinator` does the same: its `frame()` reads `host.fittingSize`, keeps `shownSize` and returns `PVContextMenuPlacement.panelFrame`.

States: no new state is drawn. Accessibility: unchanged; the list keeps its label and identifiers (`identifier("list")`, `identifier("option.…")`, `identifier("empty")`, `identifier("loading")`).

### Strings

None — no copy changes.

## 7. Steps

**STEP-1 — The presenter stays open on a click in its field**
Files: `macos/App/DesignSystem/Components/Popup/PVPopup.swift`, `macos/ProvenenciaTests/PVPopupTests.swift`. Skill: `add-swift-test`.
Do: add `PVPopupOptions.staysOpenOnFieldClick` and `decide`'s `onAnchor` parameter with the §6 Edges rows (D-1). In `PVPopupWatcherView`, `apply(_:openingPressPending:)` gains `onAnchor: Bool = false` and passes it to `decide`; `handle(_:)` computes `onAnchor` for a mouse input as D-2 says (false when `event.window` or the view's `window` is nil, compared with `===`) and passes it; the resign observer's call keeps the default. Add T-1. Leave `decidesEveryRow` and its rows as they are.
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/PVPopupDecisionTests -only-testing:ProvenenciaTests/PVPopupInputTests -only-testing:ProvenenciaTests/PVPopupOpeningPressTests` passes; the build prints no Swift warning.

**STEP-2 — One highlight rule for a popup list's keys**
Files: `macos/App/DesignSystem/Components/List/PVList.swift` (`PVListKeyboard` only), `macos/App/DesignSystem/Components/ContextMenu/PVContextMenu.swift` (`PVContextMenuKeyboard.handle`'s movement branch only), `macos/App/DesignSystem/Components/ComboBox/PVPopupList.swift` (add `PVPopupListKeyboard` at the end; the file moves in STEP-4), `macos/App/DesignSystem/Components/ComboBox/PVComboBox.swift` (`PVComboBoxMatch.move`, `PVComboBoxMatch.Edge`, `PVComboBoxMatch.firstEnabledIndex`, `handleKey`, `moveActive`, `resetActiveRow`), `macos/App/DesignSystem/Components/TextArea/PVTextArea.swift` (`PVTextAreaCompletionSession.move` and `evaluate`'s landing only), `macos/ProvenenciaTests/PVPopupListTests.swift` (new), `macos/ProvenenciaTests/PVComboBoxTests.swift` (the six movement and two `firstEnabledIndex` tests), `macos/ProvenenciaTests/PVListTests.swift`. Skill: `add-swift-test`.
Do: add `PVListKeyboard.moveIndex` and `pageStep:` on `action`, and move `PVContextMenuKeyboard.handle`'s movement branch onto `moveIndex` (D-6). Add `PVPopupListKeyboard` (D-5). Move `PVComboBox`'s movement keys and landing onto it (D-7, D-8) and the completion's `move` and landing (D-9). Remove `PVComboBoxMatch.move`, `PVComboBoxMatch.Edge` and `PVComboBoxMatch.firstEnabledIndex`, and move their eight tests into `PVPopupListKeyboardTests` with the same inputs and expected results (D-10). Add T-2, T-3, T-5.
Check: `xcodebuild test … -only-testing:ProvenenciaTests/PVPopupListKeyboardTests -only-testing:ProvenenciaTests/PVComboBoxTests -only-testing:ProvenenciaTests/PVListTests -only-testing:ProvenenciaTests/PVTableTests -only-testing:ProvenenciaTests/PVTextAreaCompletionTests -only-testing:ProvenenciaTests/PVContextMenuTests` passes; no existing case in `PVListTests`, `PVTableTests`, `PVContextMenuTests` or `PVTextAreaCompletionTests` changes (T-5 is added to `PVListTests`); `rg -n "PVComboBoxMatch\.(move|Edge|firstEnabledIndex)" macos` finds nothing.

**STEP-3 — The kit popup list, closed through `.pvPopup`**
Files ((new): the moved file, and `macos/ProvenenciaTests/PVPopupListTests.swift` from STEP-2): `macos/App/DesignSystem/Components/ComboBox/PVPopupList.swift` → `macos/App/DesignSystem/Components/PopupList/PVPopupList.swift` (`git mv`), `macos/App/DesignSystem/Components/ComboBox/PVComboBox.swift` (`PVComboBoxPlacement`, `body`, the comments named in §6 **Deletes**), `macos/App/DesignSystem/Components/TextArea/PVTextArea.swift` (`completionPopup`), `macos/ProvenenciaTests/PVPopupListTests.swift`, `macos/ProvenenciaTests/PVComboBoxTests.swift` (the six placement tests), `macos/ProvenenciaTests/PVTextAreaCompletionTests.swift` (one type name). Skills: `add-ui-component`, `add-swift-test`.
Do: move the file (D-12). Rename `PVComboBoxPlacement` to `PVPopupListPlacement` and move it into the moved file; move its six tests into `PVPopupListPlacementTests` and change the type name in the completion's flip test (D-11). Make `PVPopupList` the private `PVPopupListWindow`, remove its watcher and dismissal (D-13), and add `View.pvPopupList` (D-12). Present `PVComboBox` (D-16) and `PVTextArea`'s completion (D-17) through it. Rewrite the comments named in §6 **Deletes** for `PVComboBox.swift`: the type doc says the list is the kit's `.pvPopupList`, closed through `.pvPopup`; the focus comment says a click away on anything that takes no focus closes through the presenter, which calls `dismissAndBlur`.
Check: AC-3.1's `rg` without the `PVPopupWindowHost.swift` path (that file is STEP-4's) and AC-3.3's `rg` with `--glob '!macos/App/DesignSystem/README.md'` (the README is STEP-5) find nothing; `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS'` passes; §10 steps 1 – 9 pass in the app.

**STEP-4 — One window host for the context menu and the popup list**
Files: `macos/App/DesignSystem/Components/Popup/PVPopupWindowHost.swift` (new), `macos/App/DesignSystem/Components/ContextMenu/PVContextMenu.swift` (`PVContextMenuPopupWindow`, `PVContextMenuNSPanel`, `PVContextMenuHostingView` only), `macos/App/DesignSystem/Components/PopupList/PVPopupList.swift` (`PVPopupListWindow.Coordinator`'s panel plumbing, `PVPopupPanel`, `PVPopupHostingView`). Skill: `add-ui-component`.
Do: write `PVPopupWindowHost` (D-14, D-15). Make both coordinators hold one and keep their own frame math and re-frame rules (§6 macOS). Remove the four panel and hosting classes and the moved plumbing. Rewrite `PVContextMenuPopupWindow`'s doc comment to name the host.
Check: AC-3.2's `rg` finds one hit, in `PVPopupWindowHost.swift`; `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS'` passes; §10 steps 1 – 10 pass in the app again (the menus, the lists and the completion open, place and follow the window as after STEP-3).

**STEP-5 — Kit README and `add-ui-component`**
Files: `macos/App/DesignSystem/README.md`, `.agents/skills/add-ui-component/SKILL.md`.
Do:
- README Popup row: after "the popup keeps its own window", add "; the kit popup list, `.pvPopupList` (`Components/PopupList/PVPopupList.swift`), is: its window under the anchor (or at `anchorRect`), placed by `PVPopupListPlacement`, closed through `.pvPopup` with `keysStayInField` and `staysOpenOnFieldClick`; its field keeps its keys and calls `PVPopupListKeyboard.move` for the highlight, and keeps its own Return; `PVPopupWindowHost.swift` is the one child-panel host the list and the context menu show their windows through".
- README ComboBox row: replace "The popup window is `PVPopupList` (its file under `ComboBox/`), and the list in it is" with "The list is the kit popup list, `.pvPopupList` (README Popup row), and the list view in it is".
- README TextArea row: replace "drawn through `PVPopupList`" with "drawn through `.pvPopupList`".
- README "The combo box subset": in "Clicking away blurs", say a click outside closes on the release, as every kit popup does, and a click on the field keeps the list open. Replace the "Dismissal converges on focus" bullet's monitor sentences with: the presenter `.pvPopup` decides a click away or an app switch and writes the list closed; the combo box then restores the label and resigns the field's focus (`dismissAndBlur`), the one close path a click away funnels into. Its `wantsPresented` sentence becomes: the window mirrors a `wantsPresented` flag that SwiftUI state writes synchronously on each update, so a deferred show can never re-open a list the presenter closed. Keep its follow sentence. In "Clicks on rows are ordinary tap gestures", replace "the mouse monitor passes panel clicks through untouched" with "the presenter passes clicks in the panel". In "The list is a child window" and the pure-parts paragraph, replace `PVComboBoxPlacement` with `PVPopupListPlacement` and "movement" with "movement (`PVPopupListKeyboard`)".
- README FloatingMenuSelection row: replace "`PVComboBoxMatch.move`, `PVListKeyboard` and `PVSelectSession` call them" with "`PVListKeyboard`, `PVPopupListKeyboard` and `PVSelectSession` call them".
- README List row: after "`PVListKeyboard.action` takes `isDisabled`", add "; `PVListKeyboard.moveIndex` is the one list of movement keys, with the caller's `pageStep`, which `action`, action menus and the popup list call".
- README Popup row: also add a **PopupList** row after it: "`Components/PopupList/PVPopupList.swift` (`.pvPopupList`, the kit popup list; see the Popup row)".
- `add-ui-component`: after the sentence that starts "**Every floating popup closes through `.pvPopup`**", add: "A floating list under a field is one `.pvPopupList`; its field keeps its keys and asks `PVPopupListKeyboard.move` for the highlight."
Check: `rg -n "PVComboBoxPlacement|ComboBox/PVPopupList|mouse-down monitor|PVComboBoxMatch\.(move|Edge|firstEnabledIndex)" macos .agents docs/*.md` finds nothing; `python3 scripts/check-guidance-names.py` passes.

**STEP-6 — Version**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj` (all four `MARKETING_VERSION` lines).
Do: the next patch after `VERSION` on `main` when the branch is cut (0.30.1 → 0.30.2 at the planning base), all three together per `docs/versioning.md`.
Check: `rg -n "0\.30\.2" VERSION core/version.go macos/Provenencia.xcodeproj/project.pbxproj` finds six lines: one, one and four (or the bumped value).

**STEP-7 — Docs**
Files: `docs/deployment-plan/spike-16/completed.md`, `docs/deployment-plan/spike-16/deployment-plan.md` (map row), this plan (status, Landed note).
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-51-popup-list.md` passes; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Close a combo box's list through the kit presenter, on the release of a click away."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `macos/ProvenenciaTests/PVPopupTests.swift` `PVPopupDecisionTests.staysOpenOnFieldClickRows` *(new)*, one `@Test(arguments:)` over the §6 Edges rows | `.mouseUp(.left, inside: false)`, pending false, `onAnchor` true, option true → `.pass`; same with option false → `.close(consumesEvent: false)`; same with `onAnchor` false, option true → `.close(consumesEvent: false)`; `.mouseUp(.left, inside: false)`, pending true, `onAnchor` true, option true → `.endOpeningPress`; `.mouseDown(.right, inside: false)` and `.mouseDown(.other, inside: false)`, `onAnchor` true, option true → `.pass`; same with option false → `.close(consumesEvent: false)`; `.key(.escape)`, `onAnchor` true, option true, `keysStayInField` false → `.close(consumesEvent: true)`; `.windowResignedKey`, `onAnchor` true, option true → `.close(consumesEvent: false)` | D-1, AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-2.4, AC-2.5, AC-2.6 |
| T-2 | Swift | `macos/ProvenenciaTests/PVPopupListTests.swift` `PVPopupListKeyboardTests` *(new)*: the six moved cases (`movingFromNothingActiveLandsOnTheNearEnd`, `movementClampsAtBothEndsRatherThanCycling`, `edgeJumpsGoToFirstAndLast`, `movementStepsOverDisabledRows`, `movementStaysPutWhenOnlyDisabledRowsRemain`, `movementOnAnEmptyListIsNegative`) | over 3 rows: ↓ from −1 → 0; ↑ from −1 → 2; ↓ from 2 → 2; ↑ from 0 → 0; Page Down from 0 → 2; End from 1 → 2; Home from 1 → 0; rows [A, B *disabled*, C]: ↓ from 0 → 2, ↑ from 2 → 0; rows [A, B *disabled*]: ↓ from 0 → 0; no rows: ↓ from −1 → −1 | D-5, D-10, AC-1.9, AC-2.2 |
| T-2b | Swift | same file, `PVPopupListKeyboardTests` *(new)*: the two moved landing cases (`firstEnabledIndexSkipsDisabledLeadingRows`, `firstEnabledIndexIsNegativeWhenEveryRowIsDisabled`) | today's inputs and results through `PVPopupListKeyboard.firstEnabled`; plus no rows → −1 | D-5, D-10, AC-1.9 |
| T-3 | Swift | same file, `PVPopupListKeyboardTests.commandJumpsAndOtherKeys` *(new)* | over 3 rows: ⌘↓ from 0 → 2; ⌘↑ from 2 → 0; Page Up from 2 → 0; over 12 rows Page Down from 0 → 8 (not 10); rows [A *disabled*, B, C]: ⌘↑ from −1 → 1, Home from −1 → 1; `.return`, `.escape`, `.tab`, `.space`, `KeyEquivalent("a")` → nil; ↓ with no rows → −1 | D-5, D-6, D-8, AC-1.9, AC-1.10 |
| T-4 | Swift | same file, `PVPopupListPlacementTests` *(new)*: the six moved placement cases (`popupHangsBelowTheFieldWhenThereIsRoom`, `popupFlipsAboveTheFieldWhenItWillNotFitBelow`, `popupNeverOverlapsTheField`, `popupStaysInsideTheVisibleFrame`, `popupTrimsItsHeightToTheRoomAvailable`, `popupIsClampedToTheScreensHorizontalEdges`) | today's inputs and expected frames, through `PVPopupListPlacement.popupFrame` | D-11, AC-1.12 |
| T-5 | Swift | `macos/ProvenenciaTests/PVListTests.swift` `pageStepIsTheCallers`, `moveIndexTakesOnlyMovementKeys` *(new)* | `PVListKeyboard.action(for: .pageDown, option: false, index: 0, count: 20, pageStep: 8)` → `.move(to: 8)`; with no `pageStep` → `.move(to: 10)`; `moveIndex(for: .return / .space / .escape, …)` → nil; `moveIndex(for: .downArrow, …, count: 0)` → −1 | D-6 |

Must stay green: everything `scripts/check-pr.sh` runs, with no existing case changed in `PVComboBoxTests` (its remaining cases), `PVTextAreaCompletionTests` (one type name changed), `PVContextMenuTests`, `PVPopupTests`, `PVListTests`, `PVTableTests` and `PVSelectSessionTests`. Most likely to break: `PVTextAreaCompletionTests` (the completion's presentation and its `move`), `PVContextMenuTests` (the window host).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none expected)
- [ ] Sweep: `PVComboBoxPlacement`, `PVComboBoxMatch.move`, `PVComboBoxMatch.Edge`, `PVComboBoxMatch.firstEnabledIndex`, `PVPopupPanel`, `PVPopupHostingView`, `PVContextMenuNSPanel`, `PVContextMenuHostingView`, `ComboBox/PVPopupList.swift`, `handleMouseDown` (in Popup and ComboBox) `rg`'d across `.agents/`, `.cursor/rules/`, `docs/*.md`, `macos/App/DesignSystem/README.md` and `L10n.swift` with no hit left outside `docs/deployment-plan/`; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none)
- [ ] UI matches today: every combo box list and the completion draw as before; no new kit primitive beyond `.pvPopupList` and `PVPopupWindowHost`
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — patch
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated) — not gated
- [ ] Domain doc updated if a rule in docs/*.md changed: none; the kit README and add-ui-component are STEP-5
- [ ] PR description: what shipped, AC evidence, deviations, manual check (§10), the AC-3.1 – AC-3.3 rg output
```

## 10. Manual check

Run the app on a project with a Source whose type has a citation format, a Source type page with a suggestion picker, at least 15 Properties, and one Subject waiting in Promote.

1. **Source type picker** (a Source page's identity header, Folio picked). Click the field: the list opens and stays open after the release (AC-1.1). Click the field again, then right-click it: the list stays open (AC-1.2). Press the mouse on empty page space, hold one second, release: the list stays up while held and closes on the release; the field shows Folio and has no focus ring (AC-1.3).
2. Reopen. Right-click empty page space: the list closes and the field blurs (AC-1.4). Reopen, ⌘Tab away and back: the list is gone and the field blurred (AC-1.5).
3. Reopen, type `zzz`: the empty line shows. Click the empty line: the list stays open (AC-1.8). Press Escape: the list closes; Escape again: Folio is back; Escape again: the key reaches the page as on `main` (AC-1.6).
4. Type `fo`. Press ↓, ↑, Home, End, Page Down, Page Up, ⌘↓, ⌘↑: the highlight moves as on `main` (AC-1.9). Return: the highlighted row is picked. Click the field, click a row: it is picked and the field keeps focus (AC-1.7).
5. **Type suggestions picker** on a Source type page, Folio picked. Clear the field, press Return: nothing is added; the field stays empty (AC-1.11). Click away: Folio is back.
6. **Metadata board's Add field row** near the bottom of a short window: the list opens above the field when there is no room below (AC-1.12). Scroll the board with the list open: the list follows the field. Move the window: it follows.
7. **Properties** picker and a **Promote** row's picker: open, filter, ↓, Return, and click away behave as steps 1 – 4.
8. **Format editor.** In the Source type's format text, type `{`: the list opens at the caret (AC-2.1). ↓, Return: the second field is written in (AC-2.2). Type `{` again, click a row: it is written in (AC-2.3). Type `{`, click in the text right after it: the list stays; click elsewhere in the text, out of the placeholder: it closes (AC-2.4). Type `{`, click the page outside the editor and release: it closes on the release (AC-2.5). Type `{`, ⌘Tab away: it closes (AC-2.6). Type `{`, Escape: it closes and a caret move does not reopen it (AC-2.7).
9. **Menus still work.** Right-click a Sources list row: the menu opens where it did, ↓ Return runs the row, a click away closes it. Open a `PVSelect` (a Promote row's target): it opens, moves and closes as on `main`.
10. **One popup list.** Run AC-3.1, AC-3.2 and AC-3.3's `rg` commands: each finds what its AC says. Paste the output in the PR description.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| The presenter's deferred close blurs a combo box that a commit already closed | D-16's `isOpen` guard; §10 step 4 |
| Moving the panel plumbing changes when the context menu's panel frames | The menu keeps its own `position(reframeIfSizeChanged:)` and `shownSize`; STEP-4 reruns the whole manual check after STEP-3 has passed it |
| The completion's `Color.clear` anchor sits at a different frame than today's anchor | It is a background of the same view the old `.background(completionPopup)` was; §10 step 8 |
| A button acted on while the field shows typed text now acts before the label is restored | The action reads `selection`, as today; §6 Edges Neighbors |

**Stop and report if:**

- `xcodebuild` is not on the machine (a Linux container): the Xcode and manual checks run on the user's Mac. Report every `rg` and `check-plan-docs.py` check you ran, and each Xcode or manual check as not run; do not mark them done.

- `PVPopupList.Coordinator` or `PVContextMenuPopupWindow.Coordinator` no longer does what §4 says.
- A row click no longer commits once the list closes through `.pvPopup` (D-3 is then wrong: the map's fallback is a mouse-down option).
- `PVTextAreaCompletionTests` or any `PVComboBoxTests` case needs a different input or expected value to pass (other than the type renames D-10 and D-11 name).
- The watcher's bounds are not the anchor's (a click on the field closes the list, or a click beside it keeps it open).
- `PVPopupListKeyboard.move` gives a result other than today's for any key in §6 Edges Assumptions (4) other than ⌘↑ with a disabled first row.
- A shipped combo box passes a disabled option (D-8 then changes what a researcher sees: report the caller).

## 12. Open questions

None.

## 13. PR

**Title:** S16-51 — The combo box's list becomes a kit popup list
**Body:** objective in one sentence; what shipped against US-1, US-2 and US-3; AC evidence; deviations from the plan; manual check; the AC-3.1 – AC-3.3 `rg` output; `Plan: docs/deployment-plan/spike-16/prs/S16-51-popup-list.md`.
