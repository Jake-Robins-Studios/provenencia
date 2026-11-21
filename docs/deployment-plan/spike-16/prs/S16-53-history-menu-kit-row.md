# S16-53 — The history menu uses the kit presenter and a kit menu row

**Status:** Draft
**Spike / slice:** Spike 16 · Slice 6d — Popups
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no brief: the rows keep their content and order. The menu takes the kit menu's padding, corner and window, as every action menu draws. The user accepted that look without a brief, 2026-11-21)
**Board:** —
**Depends on:** S16-50 (landed [#923](https://github.com/Jake-Robins-Studios/provenencia/pull/923)), S16-51 (landed [#928](https://github.com/Jake-Robins-Studios/provenencia/pull/928)), S16-52 (landed [#932](https://github.com/Jake-Robins-Studios/provenencia/pull/932))
**Blocks:** —
**Branch:** `s16-53-history-menu-kit-row`
**Version bump:** patch — it changes shipped app behavior: the history menu closes on an app switch and a click outside through the kit presenter, takes Home/End, and draws in the kit menu window ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/design-system-layers.mdc`, `.cursor/rules/swift-tests.mdc`, `.cursor/rules/macos-client.mdc`, `.cursor/rules/versioning.mdc`
**Context:** working rule "(Batch 6) One kit popup presenter, with the shared closing rules"; bars 25 and 27 in [`../deployment-plan.md`](../deployment-plan.md#goal-dogfood-bar); the S16-53 scope entry in [`../deployment-plan.md`](../deployment-plan.md#s16-53--the-history-menu-uses-the-kit-presenter-and-a-kit-menu-row); the Next adds of [`S16-50-popup-presenter.md`](S16-50-popup-presenter.md), [`S16-51-popup-list.md`](S16-51-popup-list.md) and [`S16-52-omnibar-popup-list.md`](S16-52-omnibar-popup-list.md); the S16-52 ship log's MNT-8 ([`S16-52-omnibar-popup-list.ship.md`](S16-52-omnibar-popup-list.ship.md)); the kit README's ContextMenu and Popup rows ([`macos/App/DesignSystem/README.md`](../../../../macos/App/DesignSystem/README.md)); [`navigation-history.md`](../../archive/spike-3/navigation-history.md) § Toolbar; [history-menu-labels.md](../../../ideas/history-menu-labels.md)
**Planned:** 2026-11-21 against `main` @ `eef680b`
**Review:** [`S16-53-history-menu-kit-row.review.md`](S16-53-history-menu-kit-row.review.md)

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

The Back/Forward history menu is the last floating popup with its own event watcher (`HistoryJumpMenuHost.armDismissMonitor`) and its own hand-built rows. This PR moves it onto the kit: it opens through `.pvContextMenu`, in the kit menu's child window, closes through `.pvPopup` with one new option (right-clicks pass, since they switch between Back and Forward), and draws each row with a new kit menu row, `PVContextMenuPathItem`. The researcher sees the same rows and keys, plus Home/End, and the menu now closes when they switch to another app. The watcher, the hand-built rows, the anchor preference key and the content-column overlay go.

**Why now.** Working rule "(Batch 6) One kit popup presenter" binds S16-50 – S16-53; this is the last of the four. S16-50, S16-51 and S16-52 each sent the history menu's watcher, `activeIndex` and its last `PVFloatingMenuSelection.moveIndex(from:delta:count:)` call here. The S16-52 ship log's nit MNT-8 sends the inlining of `HistoryJumpMenuModel.fittedPanelWidth` here.

**What stays.** Which rows the menu lists (the nearest 15 in that direction, `WorkspaceNavigation.backJumpItems` / `forwardJumpItems`), their content (glyph, muted section root, `›`, the leaf with its help tooltip, the trailing mono ref), their order, the menu's width rule (600 pt preferred, kept inside the content column), and how it opens (a 0.4 s long press or a right-click / Ctrl-click on Back or Forward). Row labels, truncation and wording stay as they are ([history-menu-labels.md](../../../ideas/history-menu-labels.md)).

## 2. User stories

**US-1.** As a researcher, when I hold Back or Forward, I get the same history rows as today, and move and open them with the keys every other kit menu takes.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Three earlier places in history (Sources list, a Source page, a Person page); long-press Back | The menu lists the three rows, newest first, each with its glyph, section root, `›`, leaf and ref, under the Back button, 600 pt wide in a wide window |
| AC-1.2 | The menu is open with nothing highlighted; press ↓ | The first row is highlighted. ↓ again: the second. ↑ from the first row: stays on the first |
| AC-1.3 | The menu is open; press End, then Home | The last row is highlighted, then the first |
| AC-1.4 | A row is highlighted; press Return (or keypad Enter) | The menu closes and the workspace goes to that history entry (`navigation.go(toIndex:)`) |
| AC-1.5 | The menu is open with nothing highlighted; press Return | Nothing happens; the menu stays open |
| AC-1.6 | The menu is open; type `s` | Nothing is highlighted (no type-select in the history menu, scope Out); the key is not swallowed by the menu |
| AC-1.7 | Click a row | The menu closes and the workspace goes to that entry |

**US-2.** As a researcher, the history menu closes the way every other popup does, and Back/Forward switching still works.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | The menu is open; press Escape | It closes; the Escape does not reach the page |
| AC-2.2 | The menu is open; click the page outside the menu (press and release outside) | It closes on the release |
| AC-2.3 | The menu is open; switch to another app (⌘Tab) | It closes |
| AC-2.4 | Long-press Back; release the button over Back | The menu stays open (the opening press never closes it), and Back does not step |
| AC-2.5 | Right-click Back | The Back menu opens and stays open after the right button is released |
| AC-2.6 | The Back menu is open; right-click Forward | The Back menu closes and the Forward menu opens |
| AC-2.7 | The Back menu is open; right-click Back again, or right-click the page | The Back menu stays open (right-clicks pass, as today) |
| AC-2.8 | `PVPopupDecision.decide` with `ignoresRightClicks: true` | A right mouse-down or mouse-up, inside or outside, is `.pass`; a pending opening right mouse-up is `.endOpeningPress`; left and other buttons decide as without the option |

## 3. Scope

| In | Covered by |
| --- | --- |
| `PVPopupOptions.ignoresRightClicks` and its row in `PVPopupDecision.decide` | STEP-1, AC-2.5 – AC-2.8 |
| `pvContextMenu` takes `options: PVPopupOptions` in place of `keysStayInField: Bool`; `PVSelect` passes `PVPopupOptions(keysStayInField: true)` | STEP-2, D-3 |
| Kit menu row `PVContextMenuPathItem` (glyph, root › leaf with help, trailing mono ref) on `PVContextMenuItem` | STEP-3, AC-1.1, AC-1.7 |
| The history menu presents through `.pvContextMenu` on each history button, in the kit menu window, with an origin under the button and today's width rule | STEP-4, AC-1.1 – AC-1.7, AC-2.1 – AC-2.7 |
| Its keyboard: ↑/↓, Home/End, Return through `PVContextMenuKeyboard` with no titles | STEP-4, AC-1.2 – AC-1.6 |
| Deletes: `HistoryJumpMenuHost`'s watcher, `handleKeyDown`, `activeIndex`, overlay; `HistoryJumpMenuPanel`'s hand-built rows; `HistoryJumpMenuAnchorKey`; `HistoryJumpMenuModel.fittedPanelWidth`; `PVFloatingMenuSelection.moveIndex(from:delta:count:)` | STEP-4, STEP-5 |
| Kit README ContextMenu row, `add-ui-component` popup paragraph, map wording | STEP-6 |

| Out | Home |
| --- | --- |
| Row labels' truncation and wording; the Source title on graph rows | [history-menu-labels.md](../../../ideas/history-menu-labels.md) |
| Type-select in the history menu | not planned (map scope entry, "Not this PR") |
| Treating a Ctrl-click (a left press with Control) as a right-click in `.pvPopup`. It closes an open history menu on its release today and still does (§6 Edges) | not planned |
| The kit menu window's shadow (`PVContextMenuPopupWindow` keeps `hasShadow: false`; the card's `pvShadow` draws as every action menu's does) | not planned (user, 2026-11-21: accept the kit look) |
| Opening the menu from the keyboard or VoiceOver (no such path today) | not planned |
| Release-to-pick after a long press (drag onto a row and release) | not planned |

## 4. Current state

Verified at `eef680b`.

| Area | Where | Today |
| --- | --- | --- |
| Model | `macos/App/Features/Workspace/WorkspaceToolbar.swift` `HistoryJumpMenuModel` | `@Observable`: `side: HistoryJumpMenuSide?`, `anchors: [HistoryJumpMenuSide: CGRect]` (each button's frame in `WorkspaceContent.coordinateSpace`), `present(_:)`, `dismiss()`, `isPresented`, `static let panelWidth: CGFloat = 600`, `static func fittedPanelWidth(contentWidth:anchorMinX:)`, a one-line wrapper over `PVPopupListPlacement.fittedWidth(preferred: panelWidth, hangsFrom: anchorMinX, alignment: .leading, columnWidth: contentWidth)` |
| Model owner | `macos/App/Features/Workspace/WorkspaceContent.swift` `WorkspaceContent` | `@State private var jumpMenu = HistoryJumpMenuModel()`, passed to `WorkspaceToolbar(jumpMenu:)`; `.overlay(alignment: .topLeading) { HistoryJumpMenuHost(jumpMenu:contentWidth:) }` over the content column. Its comment says it is hosted here "so the jump menu can paint and receive hits over the page below" |
| Toolbar | `WorkspaceToolbar.swift` `WorkspaceToolbar` | `var jumpMenu: HistoryJumpMenuModel`; `.onPreferenceChange(HistoryJumpMenuAnchorKey.self) { jumpMenu.anchors = $0 }`; `.onChange(of: navigation.currentLocation) { jumpMenu.dismiss() }`; `historyButton(side:…)` builds `HistoryNavControl` with a `menuPresented` binding (presenting closes the omnibar's results) and a `.background { GeometryReader … HistoryJumpMenuAnchorKey }`; already has `contentWidth` (for the omnibar) |
| Host | `WorkspaceToolbar.swift` `HistoryJumpMenuHost` | A `View` overlay. Builds rows with `static rows(for:navigation:names:)` (`WorkspaceLocationLabels.labels`, leaf joined to its section with `L10n.Conclusions.pageSectionLeaf`); draws `HistoryJumpMenuPanel` at `.offset(x: anchor.minX, y: anchor.maxY + 4)`; on open resets `activeIndex = -1` and arms `armDismissMonitor` one turn later. The monitor waits for any mouse-up while a button is held, then watches `.leftMouseUp` (closes, anywhere, including on a row) and `.keyDown` (`handleKeyDown`: Escape closes; 125/126 move with `PVFloatingMenuSelection.moveIndex(from:delta:count:)`; 36/76 open the highlighted row; other keys pass). Right-clicks are not watched. It does not close on an app switch. `.onDisappear` dismisses |
| Rows | `WorkspaceToolbar.swift` `HistoryJumpMenuPanel`, `HistoryJumpRow` | `PVContextMenuPanel(width:accessibilityIdentifier: "workspace.toolbar.jumpMenu")`, `.accessibilityLabel(L10n.Workspace.jumpMenuAccessibilityLabel)`; each row a `Button` with `PVGlyphView(item.glyph, size: 15)` (`textSecondary`, 15 pt frame), root `Text` (caption, `textMuted`, priority 0), `›` (caption, `textFaint`), leaf `Text(verbatim:)` (bodySmall medium, `textPrimary`, tail truncation, priority 1, `.help`), ref `Text` (mono micro, `textFaint`, fixed size); padding 9 / 6; `PVMenuRowButtonStyle(isSelected: offset == activeIndex, cornerRadius: PVRadius.xs)` |
| Button | `WorkspaceToolbar.swift` `HistoryNavControl` | Plain `Button` (step unless `suppressStep`), `LongPressGesture(minimumDuration: 0.4)` sets `suppressStep` and `menuPresented = true`; overlay `PVRightClickCatcher` sets `menuPresented = true`. Frame 26 pt tall |
| Presenter | `macos/App/DesignSystem/Components/Popup/PVPopup.swift` `PVPopupOptions`, `PVPopupDecision.decide`, `PVPopupWatcherView` | Options `keysStayInField`, `staysOpenOnFieldClick`. `decide`: `.mouseUp` pending → `.endOpeningPress`; a left release outside whose press began outside closes; `.mouseDown` of a right or other button outside closes; Escape closes; other keys `.toPopup`. The watcher records `NSApp.currentEvent` when presented (`PVPopupOpeningPress`) |
| Kit menu | `macos/App/DesignSystem/Components/ContextMenu/PVContextMenu.swift` `pvContextMenu(_:keyboard:keysStayInField:content:)`, `PVContextMenuPresenter`, `PVContextMenuPopupWindow`, `PVContextMenuItem`, `PVContextMenuKeyboard`, `PVContextMenuPlacement.panelFrame` | Child panel at `.popUpMenu` via `PVPopupWindowHost(hasShadow: false)`, framed at `state.origin` inside the anchor from the content's fitted size; closes through `.pvPopup(options: PVPopupOptions(keysStayInField:))`; `PVContextMenuItem(index:isEnabled:…action:label:)` owns the row button, `PVMenuRowButtonStyle(isSelected:)` (corner `PVRadius.sm`), label padding `space5` / `space3`, dismiss-then-action, and Return registration. `PVContextMenuKeyboard.handle` moves with ↑/↓/Home/End via `PVListKeyboard.moveIndex`, Return on nothing returns `.move`, and letters are `.ignore` when `itemTitles` is empty |
| Select | `macos/App/DesignSystem/Components/Select/PVSelect.swift:183` | `.pvContextMenu(…, keysStayInField: true)`: the only caller of that parameter |
| Mover | `macos/App/DesignSystem/Components/FloatingMenuSelection/PVFloatingMenuSelection.swift` `moveIndex(from:delta:count:)` | The no-`isDisabled` overload. Its only app caller is `HistoryJumpMenuHost.handleKeyDown`; `PVPopupList.swift:438` uses the `isDisabled:` form. Doc comment names "(context, select, history)" |
| Tests | `macos/ProvenenciaTests/PVPopupTests.swift` `PVPopupDecisionTests` | The decision table (`rows`, `fieldRows`) |
| Tests | `macos/ProvenenciaTests/HistoryJumpMenuModelTests.swift` `panelWidthFitsTheColumn` | Seven `fittedPanelWidth` cases |
| Tests | `macos/ProvenenciaTests/PVFloatingMenuSelectionTests.swift` `emptyCountReturnsNone`, `fromNoneOpensAtEndMatchingDelta`, `clampsAtEnds`, `stepsByDelta`, `plainMoveMatchesNoDisabledRows` | Call the no-`isDisabled` overload |
| Tests | `macos/ProvenenciaTests/PVContextMenuTests.swift` `lettersWithoutTitlesAreIgnored`, `allEnabledMenuMovesAsBefore`, `returnOnNothingKeepsTheMenuOpen` | The keyboard the history menu now uses, already covered |
| Docs | `macos/App/DesignSystem/README.md` ContextMenu row | "(the toolbar's Back/Forward history menu anchors to its button and keeps its own presenter)" |

**Precedent.** S16-50 ([#923](https://github.com/Jake-Robins-Studios/provenencia/pull/923)) moved the action menus onto `.pvPopup` through `pvContextMenu` and added a `PVPopupOptions` field with one row in the decision table; copy its option shape and its table test. S16-52 ([#932](https://github.com/Jake-Robins-Studios/provenencia/pull/932)) replaced the omnibar's `GeometryReader` preference with `.onGeometryChange(for: CGRect.self) { $0.frame(in: .named(WorkspaceContent.coordinateSpace)) }`; copy that for the button frames. `PVSelect` (`PVSelect.swift`) is the precedent for a menu with its own keyboard state on `.pvContextMenu` directly.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `PVPopupOptions` gains `var ignoresRightClicks = false`. In `decide`'s `.mouseDown` branch, first: a `.mouseDown(.right, _)` with the option is `.pass`. The `.mouseUp` branch needs no code: after the pending check a right release already passes (`guard button == .left …`), so T-1's mouse-up rows are regression rows that pass before the change. `.other` and `.left` are untouched. `PVPopupInput` is unchanged (a Ctrl-click stays a left press) | Working rule: "the history menu ignores right-clicks (they switch between Back and Forward)". A right-click on the open side would otherwise close it while its catcher reopens it, and close-then-reopen races | A history-only watcher — forbidden by the rule; mapping Ctrl-click to right — `PVPopupInput` reads event types, and today's menu closes on that release too |
| D-2 | One `.pvContextMenu` per history button, attached in `WorkspaceToolbar.historyButton` to `HistoryNavControl`. Its state is a `Binding<PVContextMenuState>` derived from the model: get `PVContextMenuState(isPresented: jumpMenu.side == side, origin: CGPoint(x: 0, y: anchorHeight + PVSpacing.space2))`; set: when `!newValue.isPresented && jumpMenu.side == side`, `jumpMenu.dismiss()`. `anchorHeight` is `jumpMenu.anchors[side]?.height ?? 0`. With no anchor frame yet the menu content is `EmptyView()` (today's host draws nothing without an anchor). `.onGeometryChange` (D-9) and `.modifier(HistoryJumpMenuHost…)` are applied directly on `HistoryNavControl`, in that order, in place of today's `.background { GeometryReader … }`, so the menu's anchor view has the button's frame. The `menuPresented` binding (presenting closes the omnibar's results) is unchanged | The kit menu frames at an origin inside its anchor (S16-50 Next adds: "an origin at its button"). Switching sides flips one binding off and the other on; the off side's late close does nothing because the guard checks the side | One shared presenter on the toolbar row — its origin would need per-side math, and its watcher's anchor would be the whole row |
| D-3 | `pvContextMenu(_:keyboard:keysStayInField:content:)` becomes `pvContextMenu(_:keyboard:options: PVPopupOptions = PVPopupOptions(), content:)`; `PVContextMenuPresenter.keysStayInField` becomes `options` and is passed to `.pvPopup` as is. `PVSelect` passes `options: PVPopupOptions(keysStayInField: true)` | One parameter per presenter difference would grow with each option; the presenter already speaks `PVPopupOptions` | A second `ignoresRightClicks: Bool` parameter — because the next option would add a third |
| D-4 | Kit row `struct PVContextMenuPathItem: View` *(new)* in `macos/App/DesignSystem/Components/ContextMenu/PVContextMenuPathItem.swift` *(new)*. `init(glyph: PVGlyph, root: String, leaf: String?, ref: String?, index: Int?, accessibilityIdentifier: String? = nil, action: @escaping () -> Void)`. Its body is `PVContextMenuItem(index:accessibilityIdentifier:action:label:)` whose label is today's row content: `PVGlyphView(glyph, size: 15)` in `textSecondary`, 15 pt wide; root, `›`, leaf (with `.help(Text(verbatim: leaf))`) with today's fonts, colors, line limits and layout priorities; the ref when non-empty, mono micro, `textFaint`, fixed size; `HStack` spacing `space5`, inner spacing `space3`, `.firstTextBaseline`. No own padding, button style or corner: `PVContextMenuItem` supplies them | Map: "a kit menu row (in `ContextMenu/`, beside `PVContextMenuItem`)". Composing the item gives the dismiss, highlight and Return registration for free. Components already take `PVGlyph` (`PVEmptyState`, `PVChip`, `PVThumbnail`). The user accepted the kit padding (12 / 6) and corner (`PVRadius.sm`) in place of 9 / 6 and `PVRadius.xs` (2026-11-21) | A `HistoryJumpRow`-specific row in `Features/` — the map puts it in the kit; a padding parameter on `PVContextMenuItem` — the user chose the kit look |
| D-5 | The history menu's keyboard: `@State private var keyboard = PVContextMenuKeyboard.inactive` in the modifier of D-6, seeded on open to `HistoryJumpMenuModel.keyboard(rowCount:)` *(new)*, `static func keyboard(rowCount: Int) -> PVContextMenuKeyboard` returning `PVContextMenuKeyboard(itemCount: rowCount, activeIndex: -1)` (no titles) | No titles turns type-select off (Out) while ↑/↓, Home/End and Return come from the kit; a named function makes "no type-select" testable | `PVContextMenuKeyboard.opened(titles:)` — it type-selects |
| D-6 | `HistoryJumpMenuHost` becomes `private struct HistoryJumpMenuHost: ViewModifier` in `WorkspaceToolbar.swift`, applied in `historyButton` as `.modifier(HistoryJumpMenuHost(side:jumpMenu:contentWidth:))`. It reads `WorkspaceNavigation` and `WorkspaceSession` from the environment, keeps `static rows(for:navigation:names:)` unchanged, holds D-5's keyboard (seeded in `.onChange(of: jumpMenu.side == side)` when it turns true, with `rowCount: Self.rows(for: side, navigation: navigation, names: LocationNames(session: session)).count`; a key pressed in the render before the seed passes through, accepted), and applies `.pvContextMenu(state, keyboard: $keyboard, options: PVPopupOptions(ignoresRightClicks: true)) { HistoryJumpMenuPanel(…) }` with D-2's state | It keeps the type name and its row builder, so the diff is the presenter change. Rows are built only while the side is open: `HistoryJumpMenuPanel` is built from `rows(…)` inside the menu content closure | Keeping a content-column overlay — the kit window floats above the page by itself |
| D-7 | `HistoryJumpMenuPanel` keeps `PVContextMenuPanel(width:accessibilityIdentifier: "workspace.toolbar.jumpMenu")` and its accessibility label, and draws `ForEach(Array(items.enumerated()), id: \.element.id) { offset, item in PVContextMenuPathItem(glyph: item.glyph, root: item.rootLabel, leaf: item.leafLabel, ref: item.refLabel, index: offset, action: { onSelect(item.index) }) }`. `activeIndex` goes. `onSelect` is `navigation.go(toIndex:)` (the item has already dismissed) | `index: offset` registers Return and draws the keyboard highlight | — |
| D-8 | Width: `PVPopupListPlacement.fittedWidth(preferred: HistoryJumpMenuModel.panelWidth, hangsFrom: anchor.minX, alignment: .leading, columnWidth: contentWidth)`, inlined in the modifier. `HistoryJumpMenuModel.fittedPanelWidth` goes and `HistoryJumpMenuModelTests.panelWidthFitsTheColumn`'s seven cases move to `PVPopupListTests` as `fittedWidthKeepsTheHistoryMenuInTheColumn` *(new)*, on `fittedWidth` with `preferred: 600, alignment: .leading` and the same expected values | S16-52 ship log MNT-8. The rule is the kit's; the wrapper only names the preferred width | Keeping the wrapper — one caller, one line |
| D-9 | Anchor frames: `historyButton` replaces its `.background { GeometryReader … }` with `.onGeometryChange(for: CGRect.self) { $0.frame(in: .named(WorkspaceContent.coordinateSpace)) } action: { jumpMenu.anchors[side] = $0 }`. `HistoryJumpMenuAnchorKey` and `.onPreferenceChange(HistoryJumpMenuAnchorKey.self)` go | S16-52's precedent for the omnibar's field frame | — |
| D-10 | The model moves from `WorkspaceContent` into `WorkspaceToolbar` as `@State private var jumpMenu = HistoryJumpMenuModel()`. `WorkspaceToolbar`'s `jumpMenu` init parameter, `WorkspaceContent`'s `jumpMenu` state, its overlay and its "Hosted here" comment go; the `#Preview` drops `jumpMenu:` | With no overlay, the toolbar is its only reader | Keeping it in `WorkspaceContent` — an owner with no reader |
| D-11 | `PVFloatingMenuSelection.moveIndex(from:delta:count:)` goes with its last caller. The four plain tests (`emptyCountReturnsNone`, `fromNoneOpensAtEndMatchingDelta`, `clampsAtEnds`, `stepsByDelta`) call the full form with `isDisabled: { _ in false }` and keep their expected values; `plainMoveMatchesNoDisabledRows` goes. The type's doc comment reads "Clamped ↑/↓ movement for floating menus and lists." | Map "Deletes" from S16-52 | Keeping the overload — dead code |

**Rules this plan bends.** None. The brief rule ("anything that changes how a page looks") is met by the user's answer of 2026-11-21: the kit look is accepted without a brief, as the Brief line says.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `PVPopupOptions.ignoresRightClicks` *(new)* | field | `PVPopupOptions.staysOpenOnFieldClick` | It is a new field on the same type, as the rule asks |
| `PVContextMenuPathItem` *(new)* | component | `PVContextMenuItem` (label init) | It composes it; it adds only the path label layout, which no kit view draws (searched `›`, `pageSectionLeaf`, `PVGlyphView(` in `DesignSystem/`) |
| `PVContextMenuPathItem.swift` *(new)* | file | `ContextMenu/PVActionMenu.swift` | One file per kit view in the folder, as `PVActionMenu.swift` |
| `HistoryJumpMenuModel.keyboard(rowCount:)` *(new)* | func | `PVActionMenuItem.keyboard(_:)` | That one takes titled action items and type-selects |
| `fittedWidthKeepsTheHistoryMenuInTheColumn` *(new)* | test | `PVPopupListTests.fittedWidthStaysInTheColumn` | Moved cases from a deleted file; kept as their own parameterized test so each case reports |

**Builds on.** `.pvPopup` and `PVPopupOptions` (S16-50), `.pvContextMenu` and `PVContextMenuPopupWindow` on `PVPopupWindowHost` (S16-51), `PVPopupListPlacement.fittedWidth` (S16-52), `PVContextMenuKeyboard` and `PVListKeyboard`.
**Deletes.** `HistoryJumpMenuHost.armDismissMonitor`, `handleKeyDown`, `removeDismissMonitor`, `dismissMonitor`, `activeIndex`, its `body` overlay; `HistoryJumpMenuPanel`'s `Button` rows and `activeIndex`; `HistoryJumpMenuAnchorKey`; `HistoryJumpMenuModel.fittedPanelWidth`; `WorkspaceContent`'s `jumpMenu` state, overlay and comment; `WorkspaceToolbar`'s `jumpMenu` parameter; `PVFloatingMenuSelection.moveIndex(from:delta:count:)`; `PVFloatingMenuSelectionTests.plainMoveMatchesNoDisabledRows`; `macos/ProvenenciaTests/HistoryJumpMenuModelTests.swift` (its cases move, D-8); the `keysStayInField:` parameter of `pvContextMenu`; the README's "keeps its own presenter" note. After this PR, `rg -n "addLocalMonitorForEvents" macos/App` finds no popup watcher outside `PVPopup.swift` (STEP-5 names the four that remain).
**Next adds.** [history-menu-labels.md](../../../ideas/history-menu-labels.md) changes the row in one kit view (`PVContextMenuPathItem`) or in `HistoryJumpMenuHost.rows`. A breadcrumb or path menu elsewhere uses `PVContextMenuPathItem`. A popup option is one more `PVPopupOptions` field passed through `pvContextMenu(options:)`.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| The menu now closes on an app switch (`.windowResignedKey`) | `jumpMenu.dismiss()` via D-2's setter | The setter clears `side`; reopening reseeds the keyboard (D-5) |
| The menu now draws in a child window above the page, not a clipped overlay | `PVContextMenuPopupWindow` | It follows window moves and resizes (`PVPopupWindowHost.onFollow`); a location change still dismisses (`onChange(of: navigation.currentLocation)`) |
| Home / End keys | `PVContextMenuKeyboard.handle` | Covered by `PVContextMenuTests.allEnabledMenuMovesAsBefore` |

### Scale

None — at most 15 rows (`backJumpItems(limit: 15)`), built only while the menu is open.

### Edges

- **Assumptions.** `PVPopupDecision.decide` checks the pending opening press before anything else, so a right-click that opened the menu still ends its own press (T-1). `PVPopupInput.init` maps a Ctrl-click to `.mouseDown(.left)`; with D-1 it still closes the open menu on its release when it is outside, and on Forward its catcher presents Forward first, so the Back side's late close finds `side == .forward` and does nothing (D-2's guard).
- **Neighbors.** With `ignoresRightClicks`: right down/up inside or outside → `.pass`; other-button down outside → still `.close`; left release outside → still `.close`; Escape → still `.close(consumesEvent: true)`. Without the option, every existing row decides as before (T-1 keeps the old table).
- **Removed inputs.** A history entry removed while the menu is open: `rows` is rebuilt on every content update; a navigation dismisses the menu first.
- **Real data.** None — no table or seed drives the rule.
- **Untrusted size.** None — the list is capped at 15 by `NavigationHistoryStore`.

### Schema

None — no catalog change.

### Go core

None — Swift only.

### FFI

None — no engine call.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Presenter option | `PVPopupOptions.ignoresRightClicks` | `DesignSystem/Components/Popup/PVPopup.swift` | D-1 |
| Menu presenter | `.pvContextMenu(options:)` | `DesignSystem/Components/ContextMenu/PVContextMenu.swift` | D-3 |
| Path row | `PVContextMenuPathItem` *(new)* | `DesignSystem/Components/ContextMenu/PVContextMenuPathItem.swift` | D-4 |
| Panel | `PVContextMenuPanel` | unchanged | D-7 |
| History host | `HistoryJumpMenuHost` (ViewModifier) | `Features/Workspace/WorkspaceToolbar.swift` | D-6 |

```swift
// PVPopup.swift
struct PVPopupOptions: Equatable {
    var keysStayInField = false
    var staysOpenOnFieldClick = false
    /// Right-clicks pass, inside or outside (the history menu: they switch sides).
    var ignoresRightClicks = false
}
// decide(_:…), first line of the .mouseDown case (the .mouseUp case already passes a right release):
//   if options.ignoresRightClicks, button == .right { return .pass }
```

States: empty — a side with no rows never opens (`hasJumpItems` guards both openers, as today). Accessibility: identifier `workspace.toolbar.jumpMenu` and label `L10n.Workspace.jumpMenuAccessibilityLabel` stay on the panel; each row is a button whose label is its texts.

### Strings

None — no copy changes. `L10n.Workspace.jumpMenuAccessibilityLabel` stays.

## 7. Steps

**STEP-1 — The presenter lets right-clicks pass.**
Files: `macos/App/DesignSystem/Components/Popup/PVPopup.swift`, `macos/ProvenenciaTests/PVPopupTests.swift`. Skill: `add-swift-test`.
Do: D-1. Update `.pvPopup`'s doc comment to name the option. Add T-1.
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/PVPopupDecisionTests` passes.

**STEP-2 — `pvContextMenu` takes presenter options.**
Files: `macos/App/DesignSystem/Components/ContextMenu/PVContextMenu.swift`, `macos/App/DesignSystem/Components/Select/PVSelect.swift`.
Do: D-3. Update `pvContextMenu`'s doc comment ("unless `options.keysStayInField`").
Check: the app builds; `rg -n "keysStayInField:" macos/App` finds only `PVPopupOptions(keysStayInField:` forms; `PVSelectSessionTests`, `PVSelectPlacementTests` and `PVContextMenuTests` pass.

**STEP-3 — Kit path row.**
Files: `macos/App/DesignSystem/Components/ContextMenu/PVContextMenuPathItem.swift` *(new)*. Skill: `add-ui-component`.
Do: D-4, with a `#Preview` of three rows in a `PVContextMenuPanel(width: 600)`: one with a long leaf, one with no leaf, one with no ref.
Check: the app builds; the preview shows the three rows.

**STEP-4 — The history menu moves onto the kit.**
Files: `macos/App/Features/Workspace/WorkspaceToolbar.swift`, `macos/App/Features/Workspace/WorkspaceContent.swift`, `macos/ProvenenciaTests/HistoryJumpMenuModelTests.swift`.
Do: D-2, D-5, D-6, D-7, D-9, D-10. Add `HistoryJumpMenuModel.keyboard(rowCount:)` and T-2 in `HistoryJumpMenuModelTests` (replacing `panelWidthFitsTheColumn`, whose cases move in STEP-5).
Check: the app builds; `rg -n "armDismissMonitor|HistoryJumpMenuAnchorKey|activeIndex" macos/App/Features/Workspace` finds nothing; T-2 passes; in the app, AC-1.1 – AC-2.7 hold.

**STEP-5 — Delete what the move made dead.**
Files: `WorkspaceToolbar.swift`, `macos/App/DesignSystem/Components/FloatingMenuSelection/PVFloatingMenuSelection.swift`, `macos/ProvenenciaTests/PVFloatingMenuSelectionTests.swift`, `macos/ProvenenciaTests/PVPopupListTests.swift`, `macos/ProvenenciaTests/HistoryJumpMenuModelTests.swift`.
Do: D-8, D-11. Move `panelWidthFitsTheColumn`'s seven cases to T-3. Keep T-2 in `HistoryJumpMenuModelTests.swift`.
Check: `rg -n "fittedPanelWidth|moveIndex\(from: [^,]+, delta: [^,]+, count: [^,)]+\)" macos` finds nothing; `rg -n "addLocalMonitorForEvents" macos/App` finds only `PVPopup.swift`, `PVOutsideClick.swift` (sheets), `GraphCanvasDocumentView.swift` (modifier keys) and `WindowDragRegion.swift` (window drag); the three test files pass.

**STEP-6 — Docs and version.**
Files: `VERSION`, `core/version.go`, `MARKETING_VERSION` in `macos/Provenencia.xcodeproj/project.pbxproj` (one patch bump, [`docs/versioning.md`](../../../versioning.md)), `macos/App/DesignSystem/README.md`, `.agents/skills/add-ui-component/SKILL.md`, `docs/deployment-plan/spike-16/deployment-plan.md`, `docs/deployment-plan/spike-16/completed.md`, this plan.
Do: README ContextMenu row: replace "(the toolbar's Back/Forward history menu anchors to its button and keeps its own presenter)" with "(the toolbar's Back/Forward history menu is a `.pvContextMenu` on each button, with `PVPopupOptions.ignoresRightClicks`, drawing `PVContextMenuPathItem` rows: a glyph, root › leaf and a trailing ref)"; README Popup row: after "a difference is a `PVPopupOptions` field, never a second watcher;" insert "`ignoresRightClicks` lets right-clicks pass (the history menu, whose right-clicks switch between Back and Forward);". `completed.md`: a `## S16-53 — The history menu uses the kit presenter and a kit menu row` paragraph, as `## S16-52 — …`. `add-ui-component` line 95 paragraph: add "A path row (glyph, root › leaf, ref) is `PVContextMenuPathItem`." Map row status, `completed.md` paragraph and this plan's status per the DoD. In the map's S16-53 scope entry, replace "Rows look as today" with "Rows keep their content and take the kit menu's padding and corner (user, 2026-11-21)".
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-53-history-menu-kit-row.md` reports no errors; `scripts/check-guidance-names.py` passes; `scripts/check-pr.sh` prints `check-pr: PASS`.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `macos/ProvenenciaTests/PVPopupTests.swift` `PVPopupDecisionTests.rightClicksPassWhenIgnored` *(new)* | With `ignoresRightClicks: true`: `.mouseDown(.right, inside: false)` → `.pass`; `.mouseDown(.right, inside: true)` → `.pass`; `.mouseUp(.right, inside: false)` not pending → `.pass`; `.mouseUp(.right, inside: false)` pending → `.endOpeningPress`; `.mouseDown(.other, inside: false)` → `.close(consumesEvent: false)`; `.mouseUp(.left, inside: false)` → `.close(consumesEvent: false)`; `.key(.escape)` → `.close(consumesEvent: true)`. `decidesEveryRow` stays green unchanged | AC-2.5 – AC-2.8, D-1 |
| T-2 | Swift | `macos/ProvenenciaTests/HistoryJumpMenuModelTests.swift` `keyboardMovesWithoutTypeSelect` *(new)* | `var k = HistoryJumpMenuModel.keyboard(rowCount: 3)`: `k.activeIndex == -1`; `handle("s")` → `.ignore`; `handle(.return)` → `.move(to: -1)`; `handle(.downArrow)` → `.move(to: 0)`; `handle(.end)` → `.move(to: 2)`; `handle(.home)` → `.move(to: 0)`; `handle(.upArrow)` → `.move(to: 0)`; `handle(.return)` → `.activate(0)` | AC-1.2 – AC-1.6, D-5 |
| T-3 | Swift | `macos/ProvenenciaTests/PVPopupListTests.swift` `fittedWidthKeepsTheHistoryMenuInTheColumn` *(new, moved)* | `fittedWidth(preferred: 600, hangsFrom: x, alignment: .leading, columnWidth: w)` for (w, x) → expected: (1102, 12) → 600; (436, 12) → 408; (0, 12) → 600; (628, 12) → 600; (627, 12) → 599; (436, 32) → 388; (436, 82) → 338 | AC-1.1, D-8 |
| T-4 | Swift | `macos/ProvenenciaTests/PVFloatingMenuSelectionTests.swift` four plain tests *(changed)* | Same inputs and expected values on the `isDisabled: { _ in false }` form | D-11 |

**Where checks run.** `rg`, `python3` and `go` checks run anywhere. `xcodebuild`, the `#Preview`, the in-app ACs (AC-1.1, AC-1.7, AC-2.1 – AC-2.7) and §10 need a Mac. Without one, report each as not run, with the reason, and the PR body says so; the ship-pr orchestrator runs them before merge. Unit-tested ACs (AC-1.2 – AC-1.6 by T-2, AC-2.8 by T-1) count as met when the tests pass on CI.

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `PVPopupDecisionTests`, `PVContextMenuTests`, `PVSelectSessionTests`, `WorkspaceToolbarBreadcrumbTests` (it builds `WorkspaceToolbar` statics only; the init change must not touch it).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — or none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated)
- [ ] Domain doc updated if a rule in docs/*.md changed: none (navigation-history.md's toolbar table still holds)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

No brief: the "brief inventory" line is met by D-4's row being the only new kit view. No new copy.

## 10. Manual check

1. Open a project. Visit the Sources list, a Source page, a Person page, then the Persons list.
2. Long-press Back for half a second and release over it: the menu opens under Back with three rows (Person, Source, Sources), stays open, and Back did not step (AC-1.1, AC-2.4).
3. Press ↓ ↓ ↑, End, Home, then `s`: the highlight moves first, second, first, last, first; `s` does nothing (AC-1.2, AC-1.3, AC-1.6). Press Escape: it closes (AC-2.1).
4. Right-click Back: it opens and stays open after release (AC-2.5). Right-click Back again and right-click the page: it stays open (AC-2.7). Go back once with ⌘[ first so Forward has rows, then open Back and right-click Forward: Back closes, Forward opens (AC-2.6).
5. Open Back; click the page: it closes on release (AC-2.2). Open it; ⌘Tab away: it closes (AC-2.3).
6. Open Back; press Return with nothing highlighted: it stays open (AC-1.5). Highlight the Source row and press Return: the Source page opens (AC-1.4). Open it again and click the Sources row: the list opens (AC-1.7).
7. Narrow the window to its minimum and open Back: the menu stays inside the content column. Move the window while it is open: the menu follows.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| The long-press opening event is not a mouse-down when `.pvPopup` records it, so its release closes the menu | `PVPopupOpeningPress` falls back to the held buttons; manual check 2 |
| The derived binding of D-2 closes the wrong side during a switch | The setter checks `jumpMenu.side == side`; manual check 4 |
| The menu, now `.fixedSize()` in the kit window, ignores its width and grows to the leaf's full length | The panel's own `.frame(width:)` proposes the width, as `PVSelect` does; manual check 7 with a long-named person |

**Stop and report if:**

- `HistoryJumpMenuHost`, `HistoryJumpMenuPanel` or `PVContextMenuPresenter` no longer does what §4 says at your base.
- A right-click on Forward while Back is open leaves both menus closed, or both open, after D-2 is in place.
- Long-pressing Back and releasing over it closes the menu (AC-2.4) with D-1 in place.
- The leaf's help tooltip or the row's click no longer works inside `PVContextMenuItem`'s button (D-4): say which, with what you tried.
- Making AC-1.6 true needs titles in the keyboard (type-select is Out).

## 12. Open questions

None.

## 13. PR

**Title:** S16-53 — The history menu uses the kit presenter and a kit menu row
**Body:** objective in one sentence; what shipped against US-1 and US-2; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-53-history-menu-kit-row.md`.
