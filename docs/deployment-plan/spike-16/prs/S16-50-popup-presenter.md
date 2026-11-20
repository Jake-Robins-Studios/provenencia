# S16-50 — One kit popup presenter, and the kit menus use it

**Status:** Landed in [#923](https://github.com/Jake-Robins-Studios/provenencia/pull/923) (2026-11-20)
**Spike / slice:** Spike 16 · Slice 6d — Popups
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: every menu draws as today; only its keys and its closing rules change)
**Board:** —
**Depends on:** —
**Blocks:** S16-51, S16-53
**Branch:** `s16-50-popup-presenter`
**Version bump:** patch — it changes shipped app behavior: a menu's keyboard skips disabled rows, and a click inside a menu no longer closes it ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/design-system-layers.mdc`, `.cursor/rules/swift-tests.mdc`, `.cursor/rules/macos-client.mdc`, `.cursor/rules/versioning.mdc`
**Context:** working rule "(Batch 6) One kit popup presenter, with the shared closing rules"; bar 25 in [`../deployment-plan.md`](../deployment-plan.md#goal-dogfood-bar); the S16-50 scope entry in [`../deployment-plan.md`](../deployment-plan.md#s16-50--one-kit-popup-presenter-and-the-kit-menus-use-it); the kit README rows ContextMenu, Select, List and FloatingMenuSelection ([`macos/App/DesignSystem/README.md`](../../../../macos/App/DesignSystem/README.md))
**Planned:** 2026-11-20 against `main` @ `1ed5d38`
**Review:** [`S16-50-popup-presenter.review.md`](S16-50-popup-presenter.review.md) — Fits with changes — Ready with changes, 2 rounds; no open blocker; To user: none

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

Every menu the kit floats (a right-click action menu, a button-opened action menu such as the citation composer's Clear menu, and a `PVSelect`'s list) closes by one set of rules, held in one kit presenter, `.pvPopup`. In a menu with a greyed-out row, the keyboard no longer lands on that row: type-select, ↑/↓ and Home/End skip it, and Return never closes the menu without acting. The menus look exactly as they do today.

**Why now.** Working rule "(Batch 6) One kit popup presenter" (user, 2026-11-17), from the retired shared-list-helpers idea file. Today five places each watch the event stream with their own rules (`PVContextMenuPresenter`, `PVContextMenuPopupWindow.Coordinator`, the combo box's popup window coordinator, `HistoryJumpMenuHost`, `OmnibarResultsHost`). This PR builds the presenter and moves the context-menu family onto it; S16-51 (combo box list), S16-52 (omnibar) and S16-53 (history menu) move the rest.

**What stays.** Every menu's chrome, rows, placement and window. `PVSelect`'s closed-field keys. Closing on an app switch, which every `pvContextMenu` menu already does through its window host; it moves into the presenter. The combo box, the omnibar's results and the history menu keep their own watchers until their PRs.

## 2. User stories

**US-1.** As a researcher using the keyboard, when a menu has a greyed-out row, the highlight never lands on it, so that Return always does what the highlighted row says.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Citation composer, locator with no region, Clear menu open (rows: Clear region *disabled*, Reset to entire artifact). Press ↓ | Reset to entire artifact is highlighted (index 1) |
| AC-1.2 | Same menu, nothing highlighted. Press Home; then press End; then press ↑ | Each lands on Reset to entire artifact (index 1) |
| AC-1.3 | Same menu, nothing highlighted. Type `c` | Nothing is highlighted; the key is consumed; the menu stays open |
| AC-1.4 | Same menu, nothing highlighted. Type `r` | Reset to entire artifact is highlighted |
| AC-1.5 | Same menu, nothing highlighted. Press Return | The menu stays open and nothing runs |
| AC-1.6 | Same menu, Reset to entire artifact highlighted. Press Return | The menu closes and the locator resets to the entire Artifact, as today |
| AC-1.7 | A menu whose rows are all enabled (a Sources list row's right-click menu) | ↑/↓, Home/End, type-select and Return behave as today |
| AC-1.8 | Promote, a row's target `PVSelect` (its last option, Find…, is menu-only), list closed, Skip committed, field focused. Press ↓, then End, then type `f` | The committed value stays Skip each time, as today |

**US-2.** As a researcher, every kit menu closes the same way, so that I never have to learn which menu needs which gesture.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | An action menu or a `PVSelect` is open. Press Escape | It closes |
| AC-2.2 | An action menu or a `PVSelect` is open. Click (press and release) anywhere outside the menu | It closes on the release |
| AC-2.3 | Right-click a Sources list row (or Ctrl-click it), and release | The menu opens and stays open after the release |
| AC-2.4 | Click a `PVSelect`'s field (it opens on the press), and release | The list stays open after the release |
| AC-2.5 | Click the composer's Clear button | The menu opens and stays open; clicking the Clear button again closes it |
| AC-2.6 | An action menu or a `PVSelect` is open. Switch to another app (⌘Tab) | It closes (as today, through the window host; now through `.pvPopup`) |
| AC-2.7 | An action menu is open. Click a greyed-out row, or the menu's heading | The menu stays open |
| AC-2.8 | An action menu is open. Click an enabled row | Its action runs and the menu closes, as today |
| AC-2.9 | A `PVSelect`'s field has focus with the list closed. Press ↑/↓, Home/End, Space, Return, a letter | The field handles them as today (`PVSelectSession`); the presenter does not take them |

## 3. Scope

| In | Covered by |
| --- | --- |
| `.pvPopup` *(new)*: one event watcher and the shared closing rules, decided by one pure function, with one option (`keysStayInField`) | STEP-2, AC-2.1 – AC-2.6, AC-2.9 |
| `pvContextMenu` presents through `.pvPopup`; its own monitor, key handler and the window host's click-away and resign-key watching go | STEP-4, AC-2.1 – AC-2.8 |
| `.pvActionMenu` *(new)*: one modifier for an action menu (its keyboard state, its seed on open, its panel and rows); the right-click menu and the Clear menu use it | STEP-4, AC-1.1 – AC-1.7 |
| `PVContextMenuKeyboard` knows its disabled rows; ↑/↓, Home/End and type-select skip them; Return with no enabled row highlighted keeps the menu open | STEP-3, AC-1.1 – AC-1.7 |
| One highlight mover and one type-select matcher that skip disabled rows, in `PVFloatingMenuSelection.swift`; `PVComboBoxMatch.move`, `PVListKeyboard.action` and `PVSelectSession` call them | STEP-1, AC-1.1, AC-1.2, AC-1.8 |
| `PVOutsideClick.isInsideSheet` asks the presenter's popup-window test | STEP-2 |
| Kit README rows (ContextMenu, Select, List, FloatingMenuSelection, a new Popup row) and `add-ui-component` name the presenter | STEP-5 |

| Out | Home |
| --- | --- |
| The combo box's list and its watcher (the combo box popup window coordinator's `startWatching`, `handleMouseDown`) | S16-51 |
| One child-panel host for the context menu and the combo box (`PVContextMenuPopupWindow` and the combo box's popup window are near-copies after this PR, apart from their frame math) | S16-51 (review M-7) |
| The omnibar's results and `OmnibarResultsHost.armDismissMonitor` | S16-52 |
| The history menu (`HistoryJumpMenuHost.armDismissMonitor`, `handleKeyDown`, `activeIndex`), and the kit README's "keeps its own presenter" note | S16-53 |
| Presenter options no caller in this PR uses: ignore right-clicks (S16-53), stay open on a click in the field (S16-51), close on mouse-down (S16-51 if its plan keeps it). Anchoring the history menu to its button is placement, in the window host, not a presenter option (S16-53) | S16-51, S16-53 |
| Page Up/Down in menus, and ⌥↑/⌥↓ jumping to an end | not planned: menus pass Page Up/Down on and move ⌥↑/⌥↓ one row, as today (`option: false`, D-13) |
| Sheets (`.pvSheet`, `PVOutsideClick`'s own monitor) | not planned: they already share `PVSheetDismiss` |
| `PVSelectSession`'s key handling (which keys a closed or open select takes) | not planned: a `PVSelect`'s keys belong to its field (rule); only its movers change (STEP-1) |
| A right-click on the row whose menu is already open re-opening it at the new point | not planned: it closes, as today |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Context-menu presenter | `macos/App/DesignSystem/Components/ContextMenu/PVContextMenu.swift` `PVContextMenuPresenter` (`installDismissMonitor`, `handleKeyDown`, `removeDismissMonitor`) | On open, one main-queue turn later, adds a local monitor for `.rightMouseDown`, `.otherMouseDown`, plus `.leftMouseUp` when `dismissOnMouseUp` and `.keyDown` when `stealKeys`. Any watched mouse event anywhere, inside the menu too, closes it on the next main-queue turn. Escape (53) closes. ↓/↑ (125/126) move with `PVFloatingMenuSelection.moveIndex` over every row; Home/End (115/119) jump to 0 / `itemCount - 1`; Return (36/76) with `activeIndex >= 0` closes and calls `PVContextMenuActionRegistry.activate`, which does nothing for a disabled row (it never registered); a letter or digit (from `charactersIgnoringModifiers`, no ⌘ or ⌃) runs `applyTypeSelect` over every title and is consumed when `itemTitles` is not empty. With no keyboard, only Escape is taken |
| Context-menu options | same file, `PVContextMenuInteraction` (`defaultStealKeys`, `defaultDismissOnMouseUp`, `defaultDismissOnClickAway`); `View.pvContextMenu(_:keyboard:keyboardTitles:stealKeys:dismissOnMouseUp:dismissOnClickAway:content:)` | Three Booleans per call. `PVSelect` passes `stealKeys: false, dismissOnMouseUp: false, dismissOnClickAway: true`; the composer's Clear menu passes `dismissOnClickAway: true`; `PVRightClickMenuModifier` takes the defaults |
| Window host | same file, `PVContextMenuPopupWindow` and its `Coordinator` (`startWatching`, `handleClickAway`, `stopWatching`, `dismissFromAppKit`, `onDismiss`) | Owns the child `PVContextMenuNSPanel` at `.popUpMenu` level and positions it, following the parent's move, resize and the enclosing scroll view. Also closes the menu: with `dismissOnClickAway`, a second local monitor closes on any mouse-down outside the panel and the anchor; always, the parent window's `didResignKeyNotification` closes it. So an app switch already closes every `pvContextMenu` menu today |
| Keyboard model | same file, `PVContextMenuKeyboard` (`itemCount`, `activeIndex`, `itemTitles`, `typeSelect`, `opened(titles:)`, `applyTypeSelect`) | Knows titles, not which rows are enabled. `applyTypeSelect` matches every title |
| Action menus | `macos/App/DesignSystem/Components/ContextMenu/PVActionMenu.swift` `PVActionMenuItem.keyboardTitles`, `PVActionMenuRows`, `PVRightClickMenuModifier` | `keyboardTitles` returns every title (disabled rows keep their slot) or nil when no row is enabled. `PVActionMenuRows` gives a disabled row `index: nil`. `PVRightClickMenuModifier` holds `@State menu` and `@State keyboard` and composes `.pvContextMenuTrigger`, `.pvContextMenu`, `PVContextMenuPanel` and `PVActionMenuRows` |
| Composer Clear menu | `macos/App/Features/CitationComposer/CitationComposerViewerPane.swift` `clearMenu`, `clearKeyboard`, `clearMenuButton`, `clearMenuItems`, `toggleClearMenu` | Repeats `PVRightClickMenuModifier`'s composition by hand, holding its own `clearKeyboard`. A `PVButton` (fires on mouse-up) toggles `clearMenu`. Clear region is disabled unless `model.locator.hasRegion && model.locatorCapabilities.supportsRegionLocator` |
| Row | `PVContextMenu.swift` `PVContextMenuItem` | An enabled row with an `index` registers its action during `body`; tapping it calls `pvContextMenuDismiss` then its action. A disabled row is a dimmed label with no button. Unchanged by this PR |
| Select | `macos/App/DesignSystem/Components/Select/PVSelect.swift` `PVSelect.body` (`.pvContextMenu(… stealKeys: false, dismissOnMouseUp: false, dismissOnClickAway: true)`), `presentMenu`, `PVSelectClickCatcherView.mouseDown` | Opens on the field's mouse-down (`toggleMenu`). Its keys go through `onMoveCommand` / `onKeyPress` to `PVSelectSession`. It closes on a mouse-down outside the panel and the field. It builds its `PVContextMenuKeyboard` itself (`presentMenu`) for the highlight only |
| Select session | `macos/App/DesignSystem/Components/Select/PVSelectSession.swift` `moveCommitted(delta:)`, `jumpCommitted(toFirst:)`, `applyTypeSelect(_:now:commit:)` | `moveCommitted` calls the plain mover, then its own loop steps over `isMenuOnly` rows (a copy of the combo box's skip); a step past the last row is refused by `commit(index:)`. `jumpCommitted` filters to the first/last row that is not `isMenuOnly`. `applyTypeSelect` blanks menu-only titles when it commits: `options.map { $0.isMenuOnly ? "" : $0.label }` |
| Menu-only option | `macos/App/Features/Promote/PromoteView.swift` `targetOptions` | The only `isMenuOnly: true` option: Find…, the last row of a Promote row's target select |
| Right-click menus | `ConclusionDetailPage.swift`, `SourcesListRow.swift`, `SourcePageIdentityHeader.swift`, `SourcePageArtifactRow.swift` (all under `macos/App/Features/`) — `.pvRightClickMenu` | Open on right mouse-down or Ctrl-left mouse-down (`PVRightClickCatcherView`). After a Ctrl-click opens one, the left mouse-up of that same click reaches the `.leftMouseUp` monitor, which is armed one main-queue turn after the open; the manual check (§10 step 1) records whether it closes today |
| Highlight mover | `macos/App/DesignSystem/Components/FloatingMenuSelection/PVFloatingMenuSelection.swift` `PVFloatingMenuSelection.moveIndex(from:delta:count:)`, `PVTypeSelectMatcher.index(in:prefix:fromIndex:)` | Clamped, no wrap, no notion of a disabled row. Used by `PVListKeyboard`, `CatalogSearchModel`, `HistoryJumpMenuHost`, `PVSelectSession`, `PVContextMenuPresenter` |
| Combo box mover | `macos/App/DesignSystem/Components/ComboBox/PVComboBox.swift` `PVComboBoxMatch.move(from:delta:in:to:)`, `PVComboBoxMatch.Edge` | The same clamp, plus: steps over disabled rows in the direction of travel (`step = (edge == .last \|\| delta < 0) ? -1 : 1`); an edge (`.first`/`.last`) walks inward; returns `index` unchanged when no enabled row lies that way. Its caller passes `(delta: 1, to: .first)` and `(delta: -1, to: .last)` |
| List keys | `macos/App/DesignSystem/Components/List/PVList.swift` `PVListKeyAction` (`move(to:)`, `activate(Int)`, `ignore`), `PVListKeyboard.action(for:option:index:count:)` | The kit's pure "what a key does to a highlighted list", from a SwiftUI `KeyEquivalent`: ↑/↓ through the plain mover (⌥ jumps to an end), Home/End to 0 / `count - 1`, Page Up/Down by `pageStep`, Return/Space activate the clamped index. `PVList` and `PVTable` (`PVTable.swift`) use it |
| Key result | `KeyPress.Result` (SwiftUI) | The kit's key result already: `PVSelect.handleTriggerKey`, `PVComboBox.handleKey`, `PVTable` return it |
| Opening-press precedent | `macos/App/Features/Workspace/WorkspaceToolbar.swift` `armDismissMonitor`; `macos/App/Features/Workspace/OmnibarResultsHost.swift` `armDismissMonitor` | When `NSEvent.pressedMouseButtons != 0` at arm time, wait for the next mouse-up before closing on mouse-up. Two copies; S16-52 and S16-53 delete them |
| Outside-the-sheet test | `macos/App/DesignSystem/Components/Panel/PVOutsideClick.swift` `PVOutsideClick.isInsideSheet` | Treats a window at `.popUpMenu` level or above as inside (`eventWindow.level.rawValue >= NSWindow.Level.popUpMenu.rawValue`). Tested in `macos/ProvenenciaTests/PVPanelFormDialogTests.swift` |
| Tests | `macos/ProvenenciaTests/PVContextMenuTests.swift` (`PVContextMenuStateTests`, `PVContextMenuKeyboardTests`, `PVContextMenuActionRegistryTests`, `PVContextMenuPlacementTests`, `PVActionMenuItemTests`); `PVFloatingMenuSelectionTests.swift`; `PVComboBoxTests.swift` (`movementClampsAtBothEndsRatherThanCycling`, `movementStepsOverDisabledRows`, `movementStaysPutWhenOnlyDisabledRowsRemain`, `movementOnAnEmptyListIsNegative`); `PVListTests.swift`; `PVSelectSessionTests.swift` (all under `macos/ProvenenciaTests/`) | No test covers the presenter's monitor or keys: they live in a private `ViewModifier` |

**Precedent.** `PVSheetDismiss` in `macos/App/DesignSystem/Components/Panel/PVSheetDismiss.swift` did this shape for sheets: one presenter, one pure rule as a static function on the result enum (`PVSheetDismiss.action(…)`), tested without a window. Copy that split. The watcher's lifecycle (install on `viewDidMoveToWindow`, remove in `deinit` with `nonisolated(unsafe)`) copies `PVOutsideClickView` in `PVOutsideClick.swift`. Do not copy `PVSheetChrome`'s zero-size Escape button: a popup's panel never becomes key, so a `.keyboardShortcut` there never fires.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | The presenter is `View.pvPopup(isPresented: Binding<Bool>, options: PVPopupOptions = PVPopupOptions(), onKey: @escaping (KeyEquivalent) -> KeyPress.Result = { _ in .ignored })`, in `macos/App/DesignSystem/Components/Popup/PVPopup.swift` (new). It is attached to the popup's anchor view. It watches events and closes the popup; it does not own or place the popup's window | The rule makes `.pvPopup` own the watcher and the closing rules; S16-51's rule gives the popup list its own window, so window and watcher stay apart | Moving `PVContextMenuPopupWindow` into the presenter — because S16-51 would then fork it for the combo box's placement |
| D-2 | One pure decision, on the result enum as `PVSheetDismiss.action` is: `PVPopupDecision.decide(_ input: PVPopupInput, openingPressPending: Bool, options: PVPopupOptions) -> PVPopupDecision`. The table in §6 **Edges** is the whole rule | A rule tested without a window, in the precedent's shape | A separate `PVPopupRules` namespace — because it is one name more than the precedent (review M-5) |
| D-3 | "Inside the popup" is: the event's window is at `.popUpMenu` level or above. `PVPopupInput.isPopupWindow(level: NSWindow.Level?) -> Bool` (new) answers it, and `PVOutsideClick.isInsideSheet` calls it in place of its own comparison | Every kit popup is a child panel at `.popUpMenu` (`PVContextMenuNSPanel`, the combo box's panel); the sheet test already treats that level as inside. One function holds the fact | Passing the panel `NSWindow` from `PVContextMenuPopupWindow` to the presenter — because it couples the watcher to one window host, which D-1 keeps apart; a second copy of the comparison (review M-3) |
| D-4 | The defaults, for every popup: Escape closes and is consumed; a left mouse-up outside closes; a right or other mouse-down outside closes; the parent window resigning key closes; any click inside the popup passes through and does not close it; a left mouse-down outside does not close | The working rule, plus today's right-click behaviour kept. A row closes its menu itself (`pvContextMenuDismiss`), so a click inside need not | Closing on any click inside, as today — because a click on a greyed-out row or the heading then closes the menu doing nothing (AC-2.7) |
| D-5 | The opening press: when the watcher arms, `openingPressPending = NSEvent.pressedMouseButtons != 0`. While it is true, the next mouse-up of any button only clears it and passes through | The rule "the press or click that opened it never closes it". This is the history menu's and the omnibar's `armDismissMonitor` rule, which S16-52 and S16-53 then delete | `PVSelect`'s `dismissOnMouseUp: false` — because it only works by giving up mouse-up closing |
| D-6 | The watcher arms one main-queue turn after `isPresented` turns true, as today. Every close it decides sets `isPresented = false` on the next main-queue turn (`DispatchQueue.main.async`), after the event is delivered | A `PVButton` trigger (the Clear menu) toggles on the same mouse-up the watcher sees; closing first would let the button reopen the menu. Today's code defers for the same reason | Closing synchronously in the monitor — because the Clear button would reopen its menu (AC-2.5) |
| D-7 | `PVPopupOptions` has one field: `keysStayInField: Bool = false`. When true the watcher does not watch `.keyDown` at all (not even Escape). `pvContextMenu`'s `stealKeys:` becomes `keysStayInField:`; `PVSelect` passes `true` | The rule names this difference. `PVSelect` handles Escape in its field (`PVSelectSession`) | Adding the S16-51/S16-53 options now — because no caller in this PR would use or test them |
| D-8 | `PVSelect` closes by the defaults, on mouse-up outside, instead of mouse-down. `dismissOnMouseUp` and `dismissOnClickAway` go from `pvContextMenu`, and `PVContextMenuInteraction` goes | Its mouse-down closing existed only because the opening click's mouse-up closed it (the `PVContextMenuInteraction` comment). D-5 removes that cause. One rule, no option | A `closesOnMouseDown` option for `PVSelect` — because the rule lists the real differences and this is not one |
| D-9 | `PVContextMenuPopupWindow.Coordinator` stops closing menus: `clickAwayMonitor`, `handleClickAway`, the `didResignKeyNotification` observer, `dismissFromAppKit`, `dismissOnClickAway` and the `onDismiss` property go. It keeps showing, hiding and positioning the panel (move, resize, scroll observers) | One watcher per popup (rule). The window host only follows `isPresented` | Keeping the resign-key observer in the host as a second close path — because that is the second watcher the rule forbids |
| D-10 | Keys reach the popup as SwiftUI `KeyEquivalent`, and `onKey` answers `KeyPress.Result`. `PVPopupInput.keyEquivalent(keyCode: UInt16, characters: String?, modifiers: NSEvent.ModifierFlags) -> KeyEquivalent?` (new) maps, as `handleKeyDown` does today: 53 → `.escape`; 126/125 → `.upArrow`/`.downArrow`; 115/119 → `.home`/`.end`; 36/76 → `.return`; else one letter or digit from `characters` with neither ⌘ nor ⌃ → `KeyEquivalent(character)`; anything else → nil (not taken: the event passes). `PVPopupInput.init?(_ event: NSEvent)` calls it with `event.keyCode`, `event.charactersIgnoringModifiers` and `event.modifierFlags` | `KeyEquivalent` and `KeyPress.Result` are what `PVListKeyboard`, `PVSelect`, `PVComboBox` and `PVTable` already speak; no new key vocabulary | A `PVPopupKey` enum and a `PVPopupKeyResult` — because they are a fourth key enum and a second result type (review M-2); passing `NSEvent` to `onKey` — because the keyboard tests would need made-up events for every case |
| D-11 | The menu's key logic is a pure `mutating func handle(_ key: KeyEquivalent, now: Date = Date()) -> PVListKeyAction` (new) on `PVContextMenuKeyboard`. Movement keys go through `PVListKeyboard.action` (D-13); `PVListKeyAction.move(to: activeIndex)` means "consumed, nothing changed". `PVContextMenuPresenter` applies it, because it holds the `actionRegistry` the rows register into: when it has a `keyboard` binding and `keysStayInField` is false, the `onKey` it passes to `.pvPopup` copies `keyboard.wrappedValue`, calls `handle`, and maps the result: `.ignore` → `.ignored`; `.move(to:)` → `.handled`, and on the next main-queue turn the copy (highlight and type-select buffer) is written back; `.activate(i)` → `.handled`, and on the next main-queue turn the copy is written back, `state.dismiss()` runs and `actionRegistry.activate(i)` runs. With no `keyboard` binding its `onKey` is `{ _ in .ignored }` (only Escape is taken). Today's deferral is kept, with today's consequence accepted: two key events inside one main-queue turn (a fast key repeat) both start from the same highlight | The rules live in a value type the tests drive (§8 T-5), with the list's action type; the registry stays private to the presenter (round 2, X-9) | A `PVContextMenuKeyAction` enum — because `PVListKeyAction` has the same three cases (review M-2); an `onKey` or `onActivate` parameter on `pvContextMenu` — because the registry would have to leave the presenter |
| D-12 | `PVContextMenuKeyboard` gains `var disabledRows: IndexSet = []`. Empty means every row is enabled, so `PVSelect`'s `presentMenu` keeps building it without one. `opened(titles:)` becomes `opened(titles:disabledRows: IndexSet = [])` | An `IndexSet` has no length to keep equal with `itemTitles` | A `[Bool]` parallel to the titles — because two lists of equal length is an assumption every builder must keep |
| D-13 | `handle` rules, in order. `itemCount == 0` → `.ignore` for every key. `.upArrow`, `.downArrow`, `.home`, `.end` → `PVListKeyboard.action(for: key, option: false, index: activeIndex, count: itemCount, isDisabled: { disabledRows.contains($0) })`. `.return` → `.activate(activeIndex)` when `activeIndex` is in `0..<itemCount` and not in `disabledRows`; otherwise `.move(to: activeIndex)` (the menu stays open). A letter or digit: with empty `itemTitles` → `.ignore`, as today; otherwise `applyTypeSelect` and `.move(to: activeIndex)` (after it) whether or not it matched, as today. Anything else (`.escape` included: the presenter takes it first) → `.ignore` | The working rule; AC-1.1 – AC-1.7. `option: false` keeps today's menus, which ignore ⌥ | Return on nothing passing the key on — because a sheet's default button behind the menu would then fire |
| D-14 | `PVListKeyboard.action(for:option:index:count:isDisabled:)` gains `isDisabled: (Int) -> Bool = { _ in false }`. ↓/↑ call the shared mover (D-15) with `delta: 1` / `delta: -1`; ⌥↓ and End call it with `delta: -1, edge: .last`; ⌥↑ and Home with `delta: 1, edge: .first`; Page Down/Up with `delta: ±pageStep`. With nothing disabled every result equals today's (`PVListTests` unchanged). Return/Space keep `.activate(min(max(index, 0), count - 1))` for lists; the menu never reaches that line (D-13 handles Return first) | One "key → highlight" decision for lists, tables and menus; Home/End then skip disabled rows anywhere | Copying the movement switch into `PVContextMenuKeyboard` — because it would be a second key decision beside `PVListKeyboard` |
| D-15 | One mover: `PVFloatingMenuSelection.moveIndex(from:delta:count:edge:isDisabled:)` (new overload) with exactly `PVComboBoxMatch.move`'s rules (clamp; step over disabled rows with `step = (edge == .last \|\| delta < 0) ? -1 : 1`; an edge walks inward; `index` unchanged when no enabled row lies that way; `-1` when `count == 0`). `PVFloatingMenuSelection.Edge` (new) is `first, last`. `PVComboBoxMatch.move` becomes one call to it (`moveIndex(from: index, delta: delta, count: options.count, edge: edge, isDisabled: { options[$0].isDisabled })`), and `PVComboBoxMatch.Edge` becomes `typealias Edge = PVFloatingMenuSelection.Edge`, so its caller and its tests do not change. The old `moveIndex(from:delta:count:)` becomes one call to the overload with `edge: nil, isDisabled: { _ in false }` | The kit README says "do not write another highlight mover"; this PR needs the combo box's rules and would otherwise add a third copy | Copying the loop into `PVContextMenuKeyboard` — because it would be the third mover |
| D-16 | One type-select step, on the matcher: `PVTypeSelectMatcher.advance(_ character: Character, from current: Int, in titles: [String], isDisabled: (Int) -> Bool = { _ in false }, now: Date = Date()) -> Int` (new, `mutating`). It appends to the buffer, starts at `buffer.count == 1 ? current + 1 : max(0, current)` (the single-key cycle), and returns `PVTypeSelectMatcher.index(in:prefix:fromIndex:isDisabled:)` (new overload; the old signature calls it; a disabled index never matches), or −1. `PVContextMenuKeyboard.applyTypeSelect` calls it with `disabledRows`; `PVSelectSession.applyTypeSelect` calls it over `optionTitles` with `{ commit && options[$0].isMenuOnly }` in place of its blanked title list; `PVTable`'s key handler calls it with no `isDisabled`. `static func isTypeSelectCharacter(_ c: Character) -> Bool` (new, `c.isLetter \|\| c.isNumber`) is the one letter test: `PVPopupInput.keyEquivalent` (D-10), `handle` (D-13), `PVTable`'s handler and `PVSelect.handleTriggerKey` call it | One place for the cycle rule and the skip; the blank-the-title trick and two copies of the cycle go (review M-1, M-9) | Adding `isDisabled` by hand to the three copies — because the cycle rule would stay in three places |
| D-17 | `PVSelectSession.moveCommitted(delta:)` commits `PVFloatingMenuSelection.moveIndex(from: selectedIndex, delta: delta, count: options.count, isDisabled: { options[$0].isMenuOnly })` with `close: false` when the result differs from `selectedIndex` and is not `-1`; `jumpCommitted(toFirst:)` uses the overload with `delta: 1, edge: .first` / `delta: -1, edge: .last`, and commits only when the result differs from `selectedIndex` and is neither `-1` nor a menu-only row (every row menu-only). Its key handling does not change | Its loop is a copy of the mover's skip (review M-1). `PVSelectSessionTests` pin today's behaviour | Leaving it — because the kit would hold the mover and a hand-rolled copy beside it |
| D-18 | `.pvActionMenu(_ state: Binding<PVContextMenuState>, heading: Text? = nil, accessibilityIdentifier: String?, items: [PVActionMenuItem])` (new, `PVActionMenu.swift`) is the one action-menu recipe. It holds the keyboard `@State`; in `.onChange(of: state.wrappedValue.isPresented)`, when it turns true, it sets it to `PVActionMenuItem.keyboard(items) ?? .inactive`. It calls `.pvContextMenu(state, keyboard: PVActionMenuItem.keyboard(items) == nil ? nil : $keyboard) { PVContextMenuPanel(heading: heading, accessibilityIdentifier: accessibilityIdentifier) { PVActionMenuRows(items: items) } }`: as today, a menu with no enabled item gets no keyboard, so only Escape is taken. `PVRightClickMenuModifier` keeps its `menu` state, `.accessibilityActions` and `.pvContextMenuTrigger`, then calls `.pvActionMenu`. `CitationComposerViewerPane.clearMenuButton` calls `.pvActionMenu($clearMenu, accessibilityIdentifier: "citationComposer.clearMenu.menu", items: clearMenuItems)`; `clearKeyboard` goes | Features stop holding kit keyboard state; the binding and its seed cannot disagree (review M-4) | A public `keyboardOnOpen:` parameter on `pvContextMenu` — because both callers would pass a binding and a seed that must agree |
| D-19 | `pvContextMenu`'s signature becomes `pvContextMenu(_ state: Binding<PVContextMenuState>, keyboard: Binding<PVContextMenuKeyboard>? = nil, keysStayInField: Bool = false, content:)`. `keyboard` feeds the rows' highlight (`PVContextMenuKeyboardContext`), as today, and, unless `keysStayInField`, the keys (D-11). The presenter attaches `.pvPopup(isPresented: $state.isPresented, options: PVPopupOptions(keysStayInField: keysStayInField), onKey: …)` with D-11's `onKey`. `PVSelect` passes `keyboard:` and `keysStayInField: true` | `pvContextMenu` stays the panel-and-presenter layer under both recipes, and owns the registry its rows fill | Keeping `handleKeyDown`'s `NSEvent` switch in `PVContextMenuPresenter` — because it is untestable; the switch moves to `handle` |
| D-20 | `PVActionMenuItem.keyboardTitles(_:)` is replaced by `PVActionMenuItem.keyboard(_ items: [PVActionMenuItem]) -> PVContextMenuKeyboard?`: nil when no item is enabled, else `.opened(titles:disabledRows:)` with every title and the indexes of disabled items | One call gives the keyboard everything it needs | A second parallel list beside `keyboardTitles` |
| D-21 | Tests: Swift Testing, no window. `macos/ProvenenciaTests/PVPopupTests.swift` (new) drives `PVPopupDecision.decide` with values, and `PVPopupInput.keyEquivalent` / `PVPopupInput.init?(_:)` with made-up `NSEvent`s built by `NSEvent.keyEvent(…)` / `NSEvent.mouseEvent(…)` with `windowNumber: 0`. The watcher view and the event monitor are not unit-tested; §10 covers them | S16-35's pattern: compute, do not wait on a window. `ArtifactRegionOverlayTests` builds `NSEvent.mouseEvent` already | A hosted-window test of the monitor — because a local monitor only sees events the app dispatches, which a test cannot post |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `macos/App/DesignSystem/Components/Popup/PVPopup.swift` (new) | file, kit folder | `Components/Panel/PVSheet.swift`, `PVOutsideClick.swift` | Sheets have their own rule and are not popups (the rule's "Not this PR"); `.pvOutsideClick` only sees mouse-down |
| `View.pvPopup(isPresented:options:onKey:)` *(new)* | modifier | `PVContextMenuPresenter.installDismissMonitor` | It becomes this, generalized, so S16-51 – S16-53 reuse it |
| `PVPopupDecision` with `static func decide` *(new)* | enum + pure func | `PVSheetDismiss.action` | Different inputs (events, not dirty state); same shape |
| `PVPopupInput`, `PVPopupMouseButton`, `PVPopupOptions` *(new)* | types | `PVSelectKey`, `PVListKeyAction` | Mouse buttons and window resign are not keys; keys themselves reuse `KeyEquivalent` (D-10) |
| `PVPopupInput.keyEquivalent(keyCode:characters:modifiers:)`, `PVPopupInput.isPopupWindow(level:)` *(new)* | static funcs | `PVContextMenuPresenter.handleKeyDown`'s key codes; `PVOutsideClick.isInsideSheet`'s level test | Each becomes this one function; `isInsideSheet` calls `isPopupWindow` |
| `PVPopupWatcherView` *(new, private)* | NSView | `PVOutsideClickView` | That view's monitor is for sheets and mouse-down only; this one copies its lifecycle |
| `View.pvActionMenu(_:heading:accessibilityIdentifier:items:)` *(new)* | modifier | `PVRightClickMenuModifier`, `CitationComposerViewerPane.clearMenuButton` | Their shared composition becomes this one recipe (D-18) |
| `PVContextMenuKeyboard.handle(_:now:)`, `disabledRows` *(new)* | method, field | `PVContextMenuPresenter.handleKeyDown`, `PVListKeyboard.action` | The presenter's switch moves here; movement delegates to `PVListKeyboard.action`; returns `PVListKeyAction`, which the presenter applies with its registry |
| `PVListKeyboard.action(…isDisabled:)` *(new parameter)* | parameter | `PVListKeyboard.action` | Extended, defaulting to none |
| `PVFloatingMenuSelection.moveIndex(from:delta:count:edge:isDisabled:)`, `PVFloatingMenuSelection.Edge` *(new)* | func, enum | `PVComboBoxMatch.move`, `PVComboBoxMatch.Edge` | This is that function, lifted to the kit's mover so every caller uses one |
| `PVTypeSelectMatcher.index(in:prefix:fromIndex:isDisabled:)` *(new overload)*, `PVTypeSelectMatcher.advance`, `PVTypeSelectMatcher.isTypeSelectCharacter` *(new)* | funcs | `PVTypeSelectMatcher.index(in:prefix:fromIndex:)`; the cycle in `PVContextMenuKeyboard.applyTypeSelect`, `PVSelectSession.applyTypeSelect` and `PVTable`'s key handler; their letter tests | Extended; the three cycle copies, the blanking and the letter tests go |
| `PVActionMenuItem.keyboard(_:)` *(new)* | func | `PVActionMenuItem.keyboardTitles(_:)` | Replaces it (D-20) |
| `PVPopupDecisionTests`, `PVPopupInputTests` in `macos/ProvenenciaTests/PVPopupTests.swift` (new) | tests | `PVContextMenuTests.swift` | New type, new file, as `add-swift-test` asks |

**Builds on.** `PVFloatingMenuSelection` (the README's one mover), `PVTypeSelectMatcher`, `PVListKeyboard` / `PVListKeyAction`, `KeyEquivalent` / `KeyPress.Result`, `PVContextMenuActionRegistry`, `PVContextMenuState`, the `PVSheetDismiss` split, `PVOutsideClickView`'s lifecycle.

**Deletes.**
- `PVContextMenuPresenter`: `dismissMonitor`, `installDismissMonitor`, `handleKeyDown`, `removeDismissMonitor`; properties `stealKeys`, `dismissOnMouseUp`, `dismissOnClickAway`, `keyboardTitles`, and the reset-on-open of the keyboard (it moves to `.pvActionMenu`).
- `PVContextMenuInteraction` (the whole enum) and its test `PVContextMenuStateTests.actionMenusKeepClickToOpenDefaults`.
- `pvContextMenu` parameters `keyboardTitles:`, `stealKeys:`, `dismissOnMouseUp:`, `dismissOnClickAway:`.
- `PVContextMenuPopupWindow`: `dismissOnClickAway`, `onDismiss`; its `Coordinator`'s `clickAwayMonitor`, `handleClickAway`, `dismissFromAppKit`, `onDismiss`, `dismissOnClickAway`, and the `didResignKeyNotification` observer in `startWatching`.
- `PVRightClickMenuModifier`'s `@State keyboard` and its hand-built panel (it calls `.pvActionMenu`).
- `CitationComposerViewerPane`'s `clearKeyboard` and its hand-built `.pvContextMenu` panel.
- `PVActionMenuItem.keyboardTitles(_:)` and its two tests (`keyboardTitlesKeepEverySlot`, `keyboardTitlesNilWhenNothingIsEnabled`), replaced by T-6.
- `PVComboBoxMatch.move`'s loop body (it calls the shared mover) and `PVComboBoxMatch.Edge`'s cases (a typealias).
- `PVSelectSession.moveCommitted`'s skip loop, `jumpCommitted`'s filter, and `applyTypeSelect`'s blanked title list and buffer cycle.
- The buffer cycle in `PVContextMenuKeyboard.applyTypeSelect` and in `PVTable`'s key handler; the `isLetter || isNumber` tests in `PVTable`'s handler and `PVSelect.handleTriggerKey`.
- `PVOutsideClick.isInsideSheet`'s own level comparison.
- In `PVActionMenu.swift`'s header comment, the sentences naming `keyboardTitles` and "`PVSelect` keeps using `.pvContextMenu` directly" (rewritten for `.pvActionMenu`).

**Next adds.** S16-51 adds `PVPopupOptions.staysOpenOnFieldClick` and, if its plan keeps it, a mouse-down close (one field and one row each in the §6 Edges table; the anchor view is already the watcher's own view), and folds the two child-panel hosts into one (Out). S16-53 adds `PVPopupOptions.ignoresRightClicks`; anchoring the history menu to its button is a placement origin in the window host, not a presenter option; its rows get Home/End and disabled-row skipping from `PVListKeyboard.action`. S16-52 and S16-53 delete their `armDismissMonitor` copies for `.pvPopup` and D-5.

### Reach

None — no new path into existing code. The states a menu can now be in (open with nothing highlighted after Return; open after a click on a disabled row) were already reachable by pointer and keyboard and draw as today.

### Scale

None — no write, list or loop changes. One local event monitor exists per open popup, as today; type-select and the mover are linear in the menu's rows (2 to about 40).

### Edges

The decision table (D-2, D-4, D-5, D-7). `inside` is D-3. Every row is a T-1 case.

| Input | `openingPressPending` | `keysStayInField` | Decision |
| --- | --- | --- | --- |
| `.key(.escape)` | any | false | `.close(consumesEvent: true)` |
| `.key(k)`, k ≠ `.escape` | any | false | `.toPopup(k)` |
| `.key(any)` | any | true | `.pass` |
| `.mouseUp(any, inside: any)` | true | any | `.endOpeningPress` |
| `.mouseUp(.left, inside: false)` | false | any | `.close(consumesEvent: false)` |
| `.mouseUp(.left, inside: true)` | false | any | `.pass` |
| `.mouseUp(.right` or `.other, any)` | false | any | `.pass` |
| `.mouseDown(.left, any)` | any | any | `.pass` |
| `.mouseDown(.right` or `.other, inside: false)` | any | any | `.close(consumesEvent: false)` |
| `.mouseDown(.right` or `.other, inside: true)` | any | any | `.pass` |
| `.windowResignedKey` | any | any | `.close(consumesEvent: false)` |

The watcher applies them: `.pass` returns the event; `.close(consumes)` schedules `isPresented = false` (D-6) and returns nil when `consumes`; `.endOpeningPress` sets the flag false and returns the event; `.toPopup(k)` returns nil when `onKey(k) == .handled`, else the event.

- **Assumptions.** (1) At most one kit popup is open at a time, so "a `.popUpMenu` window" means this popup. Opening a second menu closes the first: a right-click is a right mouse-down outside the first (closes it); a left press on a `PVSelect` or the Clear button is followed by its release outside the first (closes it). For the length of one press two can be open; §10 step 6 checks it. (2) Every kit popup window is at `.popUpMenu` level: `PVContextMenuNSPanel` and the combo box's panel (`created.level = .popUpMenu`). A system menu (a text field's own context menu) is also at that level and counts as inside, which keeps the kit menu open behind it; nothing in the app opens one over a kit menu. (3) `PVContextMenuItem` closes its own menu on tap (`dismiss()` then `action()`): D-4's "inside passes" depends on it. A custom `pvContextMenu` content that is not `PVContextMenuItem` would not close on a tap; the callers use only `PVContextMenuItem` (`PVActionMenuRows`, `PVSelect.menu`). (4) `PVListKeyboard.action` and `PVSelectSession`'s movers with nothing disabled (or menu-only) return exactly today's results; their existing tests hold it.
- **Neighbors.** Ctrl-click on a right-click target: the opening press is the left button, so its left mouse-up is `.endOpeningPress` (AC-2.3). The Clear button opens on a mouse-up (its action runs once the button is released), so `pressedMouseButtons` is 0 one main-queue turn later when the watcher arms; no press is pending and the next click outside closes (AC-2.5). This is the expected value; §10 step 4 confirms it and a Stop condition covers the other. A right-click on another row while a right-click menu is open: right mouse-down outside closes the first, the other row's catcher opens its own (as today). `PVSelect`'s closed-field stepping with a menu-only last row (Promote's Find option): ↓ from the row before it stays put (the mover finds no enabled row that way), as today's loop ran off the end and `commit(index:)` refused it (AC-1.8). A Return with `activeIndex` on a row that became disabled while the menu was open: `disabledRows` is set on open only (as `itemTitles` is today), so such a row is not in it; `PVContextMenuActionRegistry.activate` then finds no action and the menu closes having done nothing. The items cannot change while the menu is open today; a Stop condition covers it.
- **Removed inputs.** None — the decision reads only the event and two flags.
- **Real data.** The only action menu with a disabled row today is the composer's Clear menu (`clearMenuItems`). `rg -n "PVActionMenuItem\(" macos/App/Features -A3 | rg "isEnabled:"` finds the rest; the implementer runs it in STEP-3 and lists each hit in the PR description.
- **Untrusted size.** None — menu rows are app-written.

The mover (D-15), with `count = 2`, `disabled = {0}` (the Clear menu): `(-1, +1) → 1`; `(-1, -1) → 1`; `(1, -1) → 1` (nowhere legal: unchanged); `(-1, +1, edge .first) → 1`; `(-1, -1, edge .last) → 1`. With `disabled = {0, 1}`: every move returns `index` (and `PVActionMenuItem.keyboard` is nil, so no keyboard exists). With `count = 0`: `-1`.

### Schema

None — no catalog change.

### Go core

None — Swift only.

### FFI

None — no engine call changes.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Presenter | `View.pvPopup` *(new)* | `macos/App/DesignSystem/Components/Popup/PVPopup.swift` | Background `NSViewRepresentable` holding `PVPopupWatcherView` |
| Context menu | `PVContextMenuPresenter` | `macos/App/DesignSystem/Components/ContextMenu/PVContextMenu.swift` | Adds `.pvPopup` with D-11's `onKey`; clears the registry on close, as today |
| Window host | `PVContextMenuPopupWindow` | same file | Show, hide and position only (D-9) |
| Action menu recipe | `View.pvActionMenu` *(new)* | `macos/App/DesignSystem/Components/ContextMenu/PVActionMenu.swift` | D-18 |
| Right-click menus | `PVRightClickMenuModifier` | same file | today's `.accessibilityActions`, then `.pvContextMenuTrigger($menu).pvActionMenu($menu, heading: heading, accessibilityIdentifier: accessibilityIdentifier, items: items)` |
| Clear menu | `CitationComposerViewerPane.clearMenuButton` | `macos/App/Features/CitationComposer/CitationComposerViewerPane.swift` | `.pvActionMenu($clearMenu, accessibilityIdentifier: "citationComposer.clearMenu.menu", items: clearMenuItems)` |
| Select | `PVSelect` | `macos/App/DesignSystem/Components/Select/PVSelect.swift` | `.pvContextMenu($menuState, keyboard: options.isEmpty ? nil : $keyboard, keysStayInField: true) { menu }` |

Sketch (signatures only):

```swift
struct PVPopupOptions: Equatable { var keysStayInField = false }
enum PVPopupMouseButton: Equatable { case left, right, other }
enum PVPopupInput: Equatable {
    case key(KeyEquivalent)
    case mouseDown(PVPopupMouseButton, inside: Bool)
    case mouseUp(PVPopupMouseButton, inside: Bool)
    case windowResignedKey
    init?(_ event: NSEvent)   // nil for an event type, or a key, the watcher does not take
    static func keyEquivalent(keyCode: UInt16, characters: String?, modifiers: NSEvent.ModifierFlags) -> KeyEquivalent?
    static func isPopupWindow(level: NSWindow.Level?) -> Bool
}
enum PVPopupDecision: Equatable {
    case pass, close(consumesEvent: Bool), endOpeningPress, toPopup(KeyEquivalent)
    static func decide(_ input: PVPopupInput, openingPressPending: Bool, options: PVPopupOptions) -> PVPopupDecision
}
extension View {
    func pvPopup(isPresented: Binding<Bool>, options: PVPopupOptions = PVPopupOptions(),
                 onKey: @escaping (KeyEquivalent) -> KeyPress.Result = { _ in .ignored }) -> some View
    func pvActionMenu(_ state: Binding<PVContextMenuState>, heading: Text? = nil,
                      accessibilityIdentifier: String?, items: [PVActionMenuItem]) -> some View
}
```

`PVPopupWatcherView` (private, `@MainActor`): `updateNSView` passes it `isPresented`, `options`, `onKey` and a `close` closure. When `isPresented` turns true it arms on the next main-queue turn: sets `openingPressPending = NSEvent.pressedMouseButtons != 0`, adds one local monitor for `[.leftMouseUp, .rightMouseUp, .otherMouseUp, .rightMouseDown, .otherMouseDown]` plus `.keyDown` unless `keysStayInField`, and observes `NSWindow.didResignKeyNotification` on its own `window`. When `isPresented` turns false, when it leaves its window, and in `deinit`, it removes both. Each event goes `PVPopupInput(event)` (nil → return the event) → `PVPopupDecision.decide` → applied as in §6 Edges. For a mouse event, `inside` is `PVPopupInput.isPopupWindow(level: event.window?.level)`.

States: no new state is drawn. Accessibility: unchanged; VoiceOver's actions on right-click targets (`accessibilityActions` in `PVRightClickMenuModifier`) do not go through the menu.

### Strings

None — no copy changes.

## 7. Steps

**STEP-1 — One mover and one matcher that skip disabled rows**
Files: `macos/App/DesignSystem/Components/FloatingMenuSelection/PVFloatingMenuSelection.swift`, `macos/App/DesignSystem/Components/ComboBox/PVComboBox.swift` (`PVComboBoxMatch.move`, `PVComboBoxMatch.Edge` only), `macos/App/DesignSystem/Components/List/PVList.swift` (`PVListKeyboard.action` only), `macos/App/DesignSystem/Components/Select/PVSelectSession.swift` (`moveCommitted`, `jumpCommitted`, `applyTypeSelect` only), `macos/App/DesignSystem/Components/Select/PVSelect.swift` (`handleTriggerKey`'s letter test only), `macos/App/DesignSystem/Components/Table/PVTable.swift` (the key handler's type-select lines only), `macos/ProvenenciaTests/PVFloatingMenuSelectionTests.swift`, `macos/ProvenenciaTests/PVListTests.swift`. Skill: `add-swift-test`.
Do: add `PVFloatingMenuSelection.Edge` and `moveIndex(from:delta:count:edge:isDisabled:)` with `PVComboBoxMatch.move`'s body moved into it (D-15), and `PVTypeSelectMatcher.index(in:prefix:fromIndex:isDisabled:)`, `PVTypeSelectMatcher.advance` and `PVTypeSelectMatcher.isTypeSelectCharacter` (D-16). Make the old signatures, `PVComboBoxMatch.move`, `PVListKeyboard.action` (D-14), `PVSelectSession` (D-16, D-17), `PVTable`'s key handler and `PVSelect.handleTriggerKey` (D-16) call them. Add T-4 and T-7.
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/PVFloatingMenuSelectionTests -only-testing:ProvenenciaTests/PVComboBoxTests -only-testing:ProvenenciaTests/PVListTests -only-testing:ProvenenciaTests/PVSelectSessionTests -only-testing:ProvenenciaTests/PVTableTests` passes, with every existing test in those suites unchanged.

**STEP-2 — The presenter**
Files: `macos/App/DesignSystem/Components/Popup/PVPopup.swift` (new), `macos/App/DesignSystem/Components/Panel/PVOutsideClick.swift` (`isInsideSheet` only), `macos/ProvenenciaTests/PVPopupTests.swift` (new). Skills: `add-ui-component`, `add-swift-test`.
Do: write the types, `PVPopupDecision.decide` (the §6 Edges table, nothing more), `PVPopupInput.keyEquivalent`, `PVPopupInput.init?(_:)`, `PVPopupInput.isPopupWindow(level:)`, `PVPopupWatcherView` and `View.pvPopup` (§6 macOS). Make `isInsideSheet` call `isPopupWindow(level:)`. Nothing else calls the presenter yet. Add T-1, T-2, T-3.
Check: `xcodebuild test … -only-testing:ProvenenciaTests/PVPopupDecisionTests -only-testing:ProvenenciaTests/PVPopupInputTests -only-testing:ProvenenciaTests/PVPanelFormDialogTests` passes, the last unchanged; the build prints no Swift warning.

**STEP-3 — The menu keyboard knows its disabled rows**
Files: `macos/App/DesignSystem/Components/ContextMenu/PVContextMenu.swift` (`PVContextMenuKeyboard`), `macos/App/DesignSystem/Components/ContextMenu/PVActionMenu.swift` (`PVActionMenuItem.keyboard`), `macos/ProvenenciaTests/PVContextMenuTests.swift`. Skill: `add-swift-test`.
Do: add `disabledRows`, `opened(titles:disabledRows:)`, `handle(_:now:)` (D-11, D-13), and make `applyTypeSelect` call `PVTypeSelectMatcher.advance` with `disabledRows` (D-16). Add `PVActionMenuItem.keyboard(_:)` (D-20); keep `keyboardTitles` until STEP-4 removes its callers. Add T-5, T-6. Run the `rg` in §6 Edges **Real data** and note its hits for the PR description.
Check: `xcodebuild test … -only-testing:ProvenenciaTests/PVContextMenuKeyboardTests -only-testing:ProvenenciaTests/PVActionMenuItemTests` passes.

**STEP-4 — The context menus present through `.pvPopup` and `.pvActionMenu`**
Files: `macos/App/DesignSystem/Components/ContextMenu/PVContextMenu.swift`, `macos/App/DesignSystem/Components/ContextMenu/PVActionMenu.swift`, `macos/App/DesignSystem/Components/Select/PVSelect.swift`, `macos/App/Features/CitationComposer/CitationComposerViewerPane.swift`, `macos/ProvenenciaTests/PVContextMenuTests.swift`. Skill: `add-ui-component`.
Do: change `pvContextMenu` to D-19's signature and attach `.pvPopup` in `PVContextMenuPresenter` with D-11's `onKey` (§6 macOS). Add `.pvActionMenu` (D-18). Move `PVRightClickMenuModifier`, the Clear menu and `PVSelect` onto them (§6 macOS). Remove everything in §6 **Deletes** for these files, `keyboardTitles` and its tests included, and rewrite `PVActionMenu.swift`'s header comment to name `.pvActionMenu` and `PVActionMenuItem.keyboard`. Remove `actionMenusKeepClickToOpenDefaults`.
Check: `rg -n "addLocalMonitorForEvents|didResignKeyNotification" macos/App/DesignSystem/Components/ContextMenu macos/App/DesignSystem/Components/Select` finds nothing; `rg -n "keyboardTitles|stealKeys|dismissOnMouseUp|dismissOnClickAway|PVContextMenuInteraction|clearKeyboard" macos/App macos/ProvenenciaTests --glob '!README.md'` finds nothing (the README is STEP-5); `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS'` passes; §10 steps 1 – 7 pass in the app.

**STEP-5 — Kit README and `add-ui-component`**
Files: `macos/App/DesignSystem/README.md`, `.agents/skills/add-ui-component/SKILL.md`.
Do:
- README: add a **Popup** row (new) after ContextMenu: "`Components/Popup/PVPopup.swift` (`.pvPopup`: the one event watcher of every floating popup, attached to its anchor; Escape, a left click outside on release, a right-click outside and an app switch close it, the press that opened it never does, a click inside never does; `PVPopupDecision.decide` is the rule; a difference is a `PVPopupOptions` field, never a second watcher; the popup keeps its own window)".
- README ContextMenu row: replace "a button-opened menu draws `PVActionMenuRows` inside `.pvContextMenu`, with `keyboardTitles` from `PVActionMenuItem.keyboardTitles`" by "a button-opened menu is one `.pvActionMenu` on its button, whose keys skip disabled rows; both close through `.pvPopup`"; leave the history-menu note (S16-53).
- README Select row: after "native popup contract on `PVContextMenu`", add "; closes through `.pvPopup` with `keysStayInField`, so its keys stay with its field".
- README List row (`rg -n "^\| List " macos/App/DesignSystem/README.md`): add "`PVListKeyboard.action` takes `isDisabled`; action menus use it too".
- README FloatingMenuSelection row: add "`moveIndex(…edge:isDisabled:)` and `PVTypeSelectMatcher.index(…isDisabled:)` skip disabled rows; `PVComboBoxMatch.move`, `PVListKeyboard` and `PVSelectSession` call them".
- `add-ui-component`: after the paragraph that starts "**Every sheet presents through `.pvSheet`", add: "**Every floating popup closes through `.pvPopup`** (`Components/Popup/PVPopup.swift`, new in this PR). Do not add an `NSEvent` monitor or a `didResignKeyNotification` observer to close a popup; a popup's real difference is a `PVPopupOptions` field. An action menu is one `.pvActionMenu` (or `.pvRightClickMenu`); its keyboard skips disabled rows."
Check: `rg -n "keyboardTitles" macos .agents` finds nothing; `python3 scripts/check-guidance-names.py` passes (the new Popup folder has its README row).

**STEP-6 — Version**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj` (`MARKETING_VERSION`).
Do: the next patch after `VERSION` on `main` when the branch is cut (0.29.0 → 0.29.1 at the planning base), all three together per `docs/versioning.md`.
Check: `rg -n "0\.29\.1" VERSION core/version.go macos/Provenencia.xcodeproj/project.pbxproj` finds all three (or the bumped value).

**STEP-7 — Docs**
Files: `docs/deployment-plan/spike-16/completed.md`, `docs/deployment-plan/spike-16/deployment-plan.md` (map row), this plan (status, Landed note).
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-50-popup-presenter.md` passes; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Skip disabled rows when moving through a menu with the keyboard."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `macos/ProvenenciaTests/PVPopupTests.swift` `PVPopupDecisionTests.decidesEveryRow` *(new)*, one `@Test(arguments:)` over the §6 Edges table | each row's input, flags → its decision (11 rows; every `any` expanded to both values) | AC-2.1 – AC-2.7, AC-2.9, D-4, D-5, D-7 |
| T-2 | Swift | same file `PVPopupInputTests.mapsKeys` *(new)* | `keyEquivalent`: key codes 53, 126, 125, 115, 119, 36, 76 → `.escape`, `.upArrow`, `.downArrow`, `.home`, `.end`, `.return`, `.return`; `"c"` no modifiers → `KeyEquivalent("c")`; `"7"` → `KeyEquivalent("7")`; `"c"` with ⌘ → nil; `"c"` with ⌃ → nil; `"-"` → nil; Page Down (121) → nil. One made-up `NSEvent.keyEvent(with: .keyDown, …, characters: "\u{1b}", charactersIgnoringModifiers: "\u{1b}", isARepeat: false, keyCode: 53)` with `windowNumber: 0` through `PVPopupInput(_:)` → `.key(.escape)` | D-10 |
| T-3 | Swift | same file `PVPopupInputTests.mapsMouseEventsAndLevels` *(new)* | made-up `NSEvent.mouseEvent` (`windowNumber: 0`) of `.leftMouseUp`, `.rightMouseDown`, `.otherMouseDown`, `.rightMouseUp` → the matching case with `inside: false` (no window); `.leftMouseDown` → `.mouseDown(.left, inside: false)`; `isPopupWindow(level:)`: nil → false, `.normal` → false, `.floating` → false, `.popUpMenu` → true, `.screenSaver` → true | D-3 |
| T-4 | Swift | `macos/ProvenenciaTests/PVFloatingMenuSelectionTests.swift` `skipsDisabledRows`, `edgesWalkInward`, `staysPutWhenNoEnabledRowLiesThatWay`, `plainMoveMatchesNoDisabledRows`, `typeSelectSkipsDisabledRows` *(new)* | the §6 Edges mover cases; plain `moveIndex(from:delta:count:)` equals the overload with nothing disabled for `count` 0…4, every `from` −1…count−1, `delta` ±1; `index(in: ["Clear region", "Reset"], prefix: "c", isDisabled: { $0 == 0 })` → −1, `prefix: "r"` → 1; `advance` over ["Prefix", "Suffix", "Surname"] from 0: `s` → 1, `s` again after the reset interval → 2, `s` then `u` within it → 1; `isTypeSelectCharacter`: `a`, `7` → true, `-`, ` ` → false | D-15, D-16, AC-1.1, AC-1.2 |
| T-5 | Swift | `macos/ProvenenciaTests/PVContextMenuTests.swift` `PVContextMenuKeyboardTests` *(new tests)*: `downSkipsADisabledFirstRow`, `homeEndAndUpLandOnTheOnlyEnabledRow`, `typeSelectNeverLandsOnADisabledRow`, `typeSelectReachesAnEnabledRow`, `returnOnNothingKeepsTheMenuOpen`, `returnActivatesAnEnabledRow`, `returnOnADisabledRowKeepsTheMenuOpen`, `noRowsIgnoresEveryKey`, `lettersWithoutTitlesAreIgnored`, `allEnabledMenuMovesAsBefore` | Clear menu keyboard `opened(titles: ["Clear region", "Reset to entire artifact"], disabledRows: [0])`: ↓ → `.move(to: 1)`; Home / End / ↑ from −1 → `.move(to: 1)`; `c` → `.move(to: -1)`, active −1; `r` → active 1; Return at −1 → `.move(to: -1)`; Return at 1 → `.activate(1)`; `activeIndex = 0` then Return → `.move(to: 0)`; `itemCount 0` → `.ignore` for every key; titles `[]` with `itemCount 2`: `c` → `.ignore`; four enabled rows: ↓↓ → 1, End → 3, Home → 0 | AC-1.1 – AC-1.7, D-13 |
| T-6 | Swift | same file `PVActionMenuItemTests.keyboardMarksDisabledRows`, `keyboardIsNilWhenNothingIsEnabled` *(new, replace the two `keyboardTitles` tests)* | [Clear region *disabled*, Reset] → titles both, `disabledRows == [0]`, `activeIndex == -1`; one disabled item or `[]` → nil | D-20 |
| T-7 | Swift | `macos/ProvenenciaTests/PVListTests.swift` `homeAndEndSkipDisabledRows` *(new)* | `PVListKeyboard.action(for: .home, option: false, index: 2, count: 4, isDisabled: { $0 == 0 })` → `.move(to: 1)`; `.end` with `{ $0 == 3 }` → `.move(to: 2)`; `.downArrow` from 0 with `{ $0 == 1 }` → `.move(to: 2)` | D-14 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `PVTableTests` (type-select), `PVComboBoxTests` (the mover delegation), `PVSelectSessionTests` (its movers and matcher), `PVListTests` (the plain mover), `PVContextMenuTests`, `PVPanelFormDialogTests` (the sheet's inside test).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none expected)
- [ ] Sweep: `keyboardTitles`, `PVActionMenuItem.keyboardTitles`, `PVContextMenuInteraction`, `stealKeys`, `dismissOnMouseUp`, `dismissOnClickAway`, `clearKeyboard`, `installDismissMonitor` (in ContextMenu), `handleClickAway` `rg`'d across `.agents/`, `.cursor/rules/`, `docs/*.md`, `macos/App/DesignSystem/README.md` and `L10n.swift` with no hit left outside `docs/deployment-plan/`; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none)
- [ ] UI matches today: every menu draws as before; no new kit primitive beyond `.pvPopup` and `.pvActionMenu`
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — patch
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated) — not gated
- [ ] Domain doc updated if a rule in docs/*.md changed: none; the kit README and add-ui-component are STEP-5
- [ ] PR description: what shipped, AC evidence, deviations, manual check (§10 with step 1's "today" observation), the STEP-3 rg hits
```

## 10. Manual check

Run the app on a project with at least one Source with an Artifact (the Source page and the citation composer need one) and one Subject waiting in Promote, with Reduce Motion off.

1. **Before the change** (on `main`): Ctrl-click a Sources list row and release. Note whether the menu stays open. Record it in the PR description.
2. Sources list: right-click a row, release. The menu stays open (AC-2.3). Press ↓ ↓, Return: the second row's action runs and the menu closes (AC-1.7, AC-2.8). Right-click again, press Escape: it closes (AC-2.1). Right-click again, click empty list space: it closes on the release (AC-2.2). Ctrl-click a row: it stays open after the release (AC-2.3).
3. Right-click the row again, then ⌘Tab to another app and back: the menu is gone (AC-2.6).
4. Citation composer on an Artifact with no region: click Clear. It stays open (AC-2.5). Press ↓: Reset to entire artifact is highlighted (AC-1.1). Press Home, End, ↑: it stays there (AC-1.2). Escape, reopen, type `c`: nothing highlighted, menu open (AC-1.3); type `r`: Reset highlighted (AC-1.4). Escape, reopen, Return: the menu stays open (AC-1.5). Click Clear region (greyed out): the menu stays open (AC-2.7). Click empty space in the composer once: the menu closes on that first click (D-5 for a button trigger). Reopen, click Clear: it closes (AC-2.5). Reopen, ↓, Return: the locator resets (AC-1.6).
5. Any form with a `PVSelect` (a Source type's metadata field data type, or the Sources list's filter chip): click the field and release. The list stays open (AC-2.4). ↑/↓/Return pick as today; type a letter, it jumps as today. Click outside: it closes on the release (AC-2.2). Open it, ⌘Tab away and back: it is closed (AC-2.6). With the list closed and the field focused, ↑/↓, Home/End, Space and a letter act as today (AC-2.9). In Promote, set a row's target to Skip, keep its field focused with the list closed, press ↓, End and `f`: it stays Skip (AC-1.8).
6. Open a `PVSelect`, then right-click a Sources list row (or open one `PVSelect`, then press on another): the first closes; only one menu is open once the button is released.
7. Open a right-click menu on a Source page Artifact row near the window's bottom edge, and scroll the page with the trackpad: the menu follows the row as today.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| Expected not to happen (§6 Edges Neighbors): `pressedMouseButtons` still reporting the released button when the watcher arms after a `PVButton` trigger, so the first click outside only clears the flag | §10 step 4's "click empty space once" line, and a Stop condition |
| `PVSelect` moved from mouse-down to mouse-up closing (D-8) and a press on another control now acts while the list is still drawn | §10 steps 5 and 6 |
| A click inside the menu no longer closes it (D-4) and some content relied on it | §6 Edges Assumption 3: the callers use only `PVContextMenuItem` |
| `PVSelectSession`'s or `PVListKeyboard`'s behaviour drifts when they move onto the shared mover | Their existing tests run unchanged in STEP-1; AC-1.8 in §10 step 5 |

**Stop and report if:**

- A `pvContextMenu` caller exists that is not `PVSelect`, `CitationComposerViewerPane` or `PVRightClickMenuModifier` (`rg -n "\.pvContextMenu\(" macos/App`).
- A kit popup window is not at `.popUpMenu` level (`rg -n "\.level = " macos/App/DesignSystem`), so D-3's inside test misses it.
- `pvContextMenu` content contains a tappable row that is not `PVContextMenuItem`, so D-4 leaves its menu open after a tap.
- §10 step 4 shows the first click outside after opening the Clear menu does not close it (D-5 misreads the button).
- §10 step 5 shows a `PVSelect` closing on its own opening release, or a row in it not committing.
- An action menu's items can change while it is open (a model update reaching `clearMenuItems` or a right-click target's `items` mid-menu): `disabledRows` would be stale (§6 Edges Neighbors).
- An existing test in `PVComboBoxTests`, `PVListTests`, `PVTableTests`, `PVSelectSessionTests` or `PVPanelFormDialogTests` fails after STEP-1 or STEP-2 and would pass only by changing the test.

## 12. Open questions

None.

## 13. PR

**Title:** S16-50 — One kit popup presenter, and the kit menus use it
**Body:** objective in one sentence; what shipped against US-1 and US-2; AC evidence; deviations from the plan; manual check, with §10 step 1's observation; the STEP-3 `rg` hits; `Plan: docs/deployment-plan/spike-16/prs/S16-50-popup-presenter.md`.

## Landed

- `main` had moved from the Planned commit to `7b0bcd2a6`; no **Current state** row changed under `macos/`.
- `PVFloatingMenuSelection.moveIndex(from:delta:count:edge:isDisabled:)` gives `edge` a default of nil, so `PVSelectSession.moveCommitted` calls it without one (D-17).
- The manual check (§10), including step 1's "today" observation, was not run by the implementer; it is owed before merge.
