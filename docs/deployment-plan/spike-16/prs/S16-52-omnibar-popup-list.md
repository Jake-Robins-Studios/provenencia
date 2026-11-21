# S16-52 — The omnibar's results use the kit popup list

**Status:** Blocked — on board S16-D9
**Spike / slice:** Spike 16 · Slice 6d — Popups
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S16-D9](../design/S16-D9-omnibar-results.md), board not agreed yet
**Board:** — (the brief's Handoff records the turn and its frames once agreed)
**Depends on:** S16-51 (landed [#928](https://github.com/Jake-Robins-Studios/provenencia/pull/928)), S16-D9
**Blocks:** —
**Branch:** `s16-52-omnibar-popup-list`
**Version bump:** patch — it changes shipped app behavior: the results draw on the kit card, take Home/End, ⌘↑/⌘↓ and Page Up/Down, stay open on a click in the field and stay inside the content column ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md)
**Rules that bind:** `.cursor/rules/design-system-layers.mdc`, `.cursor/rules/swift-tests.mdc`, `.cursor/rules/macos-client.mdc`, `.cursor/rules/macos-l10n.mdc`, `.cursor/rules/versioning.mdc`
**Context:** working rules "(Batch 6) One kit popup list under the combo box and the omnibar" and "(Batch 6) One kit popup presenter, with the shared closing rules"; bars 25 and 26 in [`../deployment-plan.md`](../deployment-plan.md#goal-dogfood-bar); the S16-52 scope entry in [`../deployment-plan.md`](../deployment-plan.md#s16-52--the-omnibars-results-use-the-kit-popup-list); the S16-51 plan's Out, Next adds and Landed note ([`S16-51-popup-list.md`](S16-51-popup-list.md)); the kit README's Popup, PopupList, ComboBox and OmnibarHitRow rows and "The combo box subset" ([`macos/App/DesignSystem/README.md`](../../../../macos/App/DesignSystem/README.md)); [`omnibar-search.md`](../../archive/spike-3/omnibar-search.md)
**Planned:** 2026-11-21 against `main` @ `b57c98a`
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

The omnibar's results are the kit popup list, the one a combo box shows: its own window under the field, the kit card and row highlight, the kit searching line, and the kit's movement keys (↑/↓, Home/End, ⌘↑/⌘↓, Page Up/Down). The list stays inside the content column at a narrow window instead of running over the sidebar, and it closes through the kit presenter like every other popup (bar 25, bar 26). The omnibar's own key-code watcher and its overlay panel go, and the highlight moves from the shared search model to the omnibar's own model.

**Why now.** Working rule "(Batch 6) One kit popup list under the combo box and the omnibar" (user, 2026-11-17; reworded 2026-11-21). S16-51 made the list a kit component and sent the omnibar here (its Out and Next adds): `.pvPopupList`, one `PVPopupListHighlight` held by the field, and the loading line's decision joining the kit with its second caller.

**What stays.** The omnibar field, its placeholder, ⌘K and its width. The search: its 2-character floor, its 180 ms debounce, its ranking and its 50-hit cap. Each hit row's content. Return opens the highlighted hit and clears the field; Escape closes the list and keeps the query; typing searches again and reopens the list; opening the history menu closes the results. Hits on screen stay while the next search runs. The no-match and failure copy.

## 2. User stories

**US-1.** As a researcher, when I type in the omnibar, I see the hits in the same list a combo box shows, under the field and inside the window's content column, so the app has one kind of floating list.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | The default window (1366 pt), query `ilmin` with hits | The list is its own window 4 pt under the field, its trailing edge on the field's trailing edge, 640 pt wide, drawn with the kit card (OR-1) and full-width row highlights (OR-2) |
| AC-1.2 | The narrowest window (700 pt), the same query | The list is narrower than 640 pt and its leading edge is 16 pt inside the content column's left edge; it never covers the sidebar (OR-3) |
| AC-1.3 | The window dragged so the field is near the screen's left or bottom edge | The list stays on screen: it moves right to the screen's edge, or trims its height and scrolls |
| AC-1.4 | Query `il` while the search runs with no hits yet; then `zzz` with no hits; then a failing search | The kit searching line (spinner, `Searching…`); the no-match line; the danger Callout with the failure's message (OR-6 – OR-8) |
| AC-1.5 | Twenty hits | The list is 420 pt tall and scrolls; the highlighted row stays in view (OR-4) |

**US-2.** As a researcher, I move through the hits with the keys a combo box takes, and the field keeps my typing.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Results arrive for `ilmin` | The first hit is highlighted |
| AC-2.2 | Three hits, the first highlighted: ↓, End, Home, Page Down, ⌘↑, ↑ | The highlight is on hit 2, 3, 1, 3, 1, 1; each key is taken |
| AC-2.3 | The second hit highlighted, Return (or keypad Enter) | That hit's place opens; the field empties; the list closes |
| AC-2.4 | The list showing the searching line with no hits, Return | Nothing opens; the key is taken |
| AC-2.5 | The list open, Escape | The list closes; the field keeps `ilmin` and its focus |
| AC-2.6 | The list closed by Escape: ↓, Return, Escape | Each key goes to the field; nothing opens; the list stays closed until the query changes |
| AC-2.7 | The pointer over the third hit | The third hit is highlighted; Return opens it |

**US-3.** As a researcher, the results close the way every popup closes.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | The list open, a click on the page below | The list closes on the release; the query stays |
| AC-3.2 | The list open, a click in the field to move the caret | The list stays open |
| AC-3.3 | The list open, ⌘-Tab to another app | The list closes |
| AC-3.4 | The list open, a click on a hit | That hit's place opens; the field empties |

**US-4.** As a contributor, the omnibar uses the kit's list, highlight, searching line and row measuring, and keeps no watcher of its own.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | `rg -n "keyCode\|addLocalMonitorForEvents\|armDismissMonitor" macos/App/Features/Workspace/OmnibarResultsHost.swift` | No hit |
| AC-4.2 | `rg -n "selectedIndex\|moveSelection\|selectedHit" macos/App/Features/Catalog/Search` | No hit |
| AC-4.3 | `rg -n "comboBoxSearching\|omnibarSearching\|ListLine\b\|listLine\|OmnibarFieldAnchorKey\|OmnibarResultsPanel" macos` | No hit |
| AC-4.4 | `rg -n "Recipes/OmnibarHitRow" macos docs .agents .cursor --glob '!docs/deployment-plan/spike-16/prs/**' --glob '!docs/deployment-plan/spike-16/design/**'` | No hit |

## 3. Scope

| In | Covered by |
| --- | --- |
| The kit list's line decision (`PVComboBoxMatch.ListLine`, `listLine`) moves into the kit as `PVPopupListLineKind`; the searching line becomes `PVPopupListSearchingLine`; `L10n.DesignSystem.comboBoxSearching` is renamed `popupListSearching` and `L10n.Workspace.omnibarSearching` goes (OR-6) | STEP-1, AC-4.3 |
| The hidden measuring copy of a list's rows becomes the kit's `PVPopupListMeasure`; `PVComboBox` and the omnibar use it | STEP-2 |
| `.pvPopupList` aligns a list wider than its field on the field's trailing edge, and re-frames when its width changes (OR-3) | STEP-3, AC-1.1, AC-1.3 |
| `OmnibarResultsModel` holds the highlight, the keys, the line and the fitted width; `CatalogSearchModel` loses `selectedIndex`, `moveSelection`, `selectedHit`, `showsLoadingState` and `showsEmptyState` (OR-3, OR-5, OR-6 – OR-8) | STEP-4, AC-1.2, AC-1.4, AC-2.1 – AC-2.7, AC-4.2 |
| `PVOmnibarHitRow` moves to `macos/App/DesignSystem/Components/OmnibarHitRow/` *(new)* and takes the board's inset (OR-2) | STEP-5, AC-4.4 |
| `OmnibarResultsHost` draws the kit list on the omnibar field; the overlay, its watcher, `OmnibarResultsPanel` and `OmnibarFieldAnchorKey` go (OR-1, OR-2, OR-4, OR-9, OR-W1) | STEP-6, AC-1.1, AC-1.5, AC-3.1 – AC-3.4, AC-4.1 |
| The kit README, `design-system-layers.md` and `add-searchable-kind` say where the omnibar's list and row live | STEP-7 |

| Out | Home |
| --- | --- |
| Reopening the list after Escape with ↓ or a click in the field, without typing | not planned: the list comes back when the query changes, as today (brief §3) |
| Search ranking, the hit kinds, the 50-hit cap, the match line's wording | not planned (map: "Not this PR") |
| The omnibar field's own chrome, width or placeholder | not planned (map: "Not this PR") |
| The history menu's `armDismissMonitor`, `activeIndex`, `HistoryJumpMenuModel.fittedPanelWidth` and `PVFloatingMenuSelection.moveIndex(from:delta:count:)`, its last caller | S16-53 |
| `PVMenuRowButtonStyle`, which `PVContextMenu`, `PVDeleteImpact` and the history menu still use | not planned: it keeps three callers |
| Grouping hits by kind, a footer, a "show all" row | not planned (brief §2.1) |
| Closing the results when the field loses focus by Tab | not planned: Tab away leaves them open, as today; a click away or an app switch closes them |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Results host | `macos/App/Features/Workspace/OmnibarResultsHost.swift` `OmnibarResultsHost` | A `View` in `WorkspaceContent`'s overlay. While `results.isPresented` and `results.fieldFrame != .zero`, it offsets `OmnibarResultsPanel` to `fieldFrame.maxX - OmnibarResultsModel.panelWidth`, `fieldFrame.maxY + 8`. `armDismissMonitor()` installs an `NSEvent` local monitor: it waits out a held button, then on key codes 53 (Escape → `closePanel`), 125/126 (↓/↑ → `search.moveSelection`), 36/76 (Return → `onActivate(search.selectedHit())`) and on any `leftMouseUp` (→ `closePanel`, a click in the field included). `onDisappear` calls `results.dismiss()`. Wrong for this PR: a second watcher beside `.pvPopup`, raw key codes, an overlay clipped to the window |
| Results panel | same file, `private struct OmnibarResultsPanel` | Error (`PVCallout` danger) → empty (two `Text`s) → loading (`ProgressView` + `L10n.Workspace.omnibarSearching`) → a `ScrollView` of `Button`s with `PVMenuRowButtonStyle(isSelected:cornerRadius: PVRadius.xs, onHoverChange:)`, max 420 pt, `.pvScrollsRowIntoView`; `padding(space2)`, 640 pt wide, `PVRadius.sm`, `borderSubtle`, `pvShadow(PVElevation.overlay)`. Accessibility identifiers `workspace.toolbar.omnibar.results`, `.hit.<id>`, `.loading`, `.error`, `.noMatches` |
| Anchor key | same file, `OmnibarFieldAnchorKey` | A preference the toolbar sets from the field's frame in `HistoryJumpMenuModel.contentCoordinateSpace` |
| Results model | `macos/App/Features/Workspace/OmnibarResultsModel.swift` `OmnibarResultsModel` | `static let panelWidth: CGFloat = 640`; `let search = CatalogSearchModel()`; `userDismissed`; `fieldFrame`; `isPresented` = `!userDismissed && search.showsResults`; `closePanel()` (dismissed, `search.cancel()`); `dismiss()`; `clearAfterNavigate()`; `activate(_:navigation:)`; `scheduleSearch(projectDir:location:store:)` |
| Search model | `macos/App/Features/Catalog/Search/CatalogSearchModel.swift` `CatalogSearchModel` | Shared with Promote's record picker. Holds `selectedIndex` (reset to 0 in `dismiss()` and in `scheduleSearch`'s `apply`), `moveSelection(delta:)` (`PVFloatingMenuSelection.moveIndex(from:delta:count:)`), `selectedHit()`, and `showsLoadingState` / `showsEmptyState` / `showsErrorState`. Only the omnibar reads the selection, `showsLoadingState` and `showsEmptyState`; `PromoteView.swift` `emptyLine(_:)` reads `showsErrorState` and `searchError` |
| Toolbar | `macos/App/Features/Workspace/WorkspaceToolbar.swift` `WorkspaceToolbar` | `omnibarField` is a `PVInput(text:size: .sm, prompt:icon: .search, suffix: "⌘K", focused:)` with a `GeometryReader` background setting `OmnibarFieldAnchorKey`; `body` has `.onPreferenceChange(OmnibarFieldAnchorKey.self) { omnibarResults.fieldFrame = $0 }` and `.onChange(of: omnibarResults.search.query)` → `scheduleSearch`. `historyButton`'s binding calls `omnibarResults.closePanel()` when the history menu opens. A `#Preview` builds `OmnibarResultsModel()` |
| Content host | `macos/App/Features/Workspace/WorkspaceContent.swift` `WorkspaceContent` | Owns `@State omnibarResults`; overlays `OmnibarResultsHost(results:projectDir:onActivate:)` with `onActivate` = `omnibarResults.activate(hit, navigation: navigation)`. Names the coordinate space `HistoryJumpMenuModel.contentCoordinateSpace` |
| Hit row | `macos/App/DesignSystem/Recipes/OmnibarHitRow/PVOmnibarHitRow.swift` `PVOmnibarHitRow` | Content-agnostic row (lead, title, kind badge, secondary, ref, match context), `.padding(.horizontal, 9)`, `.padding(.vertical, 7)`, `.contentShape(Rectangle())`, `.clipShape(RoundedRectangle(cornerRadius: PVRadius.xs…))`. One caller, `CatalogSearchHitRow` |
| Hit content | `macos/App/Features/Catalog/Search/CatalogSearchHitRow.swift` `CatalogSearchHitRow` | Fills the row from a hit; reads `@Environment(WorkspaceSession.self)`. Unchanged |
| Kit list | `macos/App/DesignSystem/Components/PopupList/PVPopupList.swift` | `.pvPopupList(isPresented:isMeasured:maxHeight:contentHeight:optionCount:width:anchorRect:content:)`; `PVPopupListWindow.Coordinator.frame()` sets `anchorOnScreen.size.width = width` (the list grows rightward from the field's leading edge) and `applyPresentation()` re-frames only when `contentHeight` or `optionCount` changed; `PVPopupListCard(rowIDs:activeID:verticalPadding:stack:)`; `PVPopupListRow(isActive:isSelected:isDisabled:onHighlight:onCommit:content:)`; `PVPopupListLine(gutter:minHeight:content:)`; `PVPopupListHighlight` (`isMovementKey`, `move`, `land`, `hover`, `clear`, `current`); `PVPopupListPlacement.popupFrame(anchor:contentHeight:visibleFrame:gap:)` |
| Combo box | `macos/App/DesignSystem/Components/ComboBox/PVComboBox.swift` | `PVComboBoxMatch.ListLine` and `listLine(optionCount:isLoading:)`; `rowsStack` draws the searching line itself (`ProgressView` + `L10n.DesignSystem.comboBoxSearching`) in `PVPopupListLine(gutter: Self.checkGutter)` with identifier `identifier("loading")`; `measuringRows` is the hidden measuring copy (`fixedSize`, `hidden`, a `GeometryReader` writing `measuredRowsHeight` and `rowsMeasured` while `isOpen`) |
| Strings | `macos/App/Platform/L10n.swift` `L10n.DesignSystem.comboBoxSearching` (`designSystem.comboBox.searching`), `L10n.Workspace.omnibarSearching` (`workspace.omnibar.searching`), both "Searching…"; `macos/App/Resources/Localizable.xcstrings` | Two keys for one line |
| Tests | `macos/ProvenenciaTests/OmnibarResultsModelTests.swift`; `CatalogSearchTests.swift` `moveSelectionClampsAndSelectedHit`, `emptyStateRequiresCompletedSearchWithoutError`; `PVComboBoxTests.swift` `searchingLineShowsOnlyWhileLoadingWithNothingIn`, `optionsAlreadyInStayWhileANewSearchRuns`, `noOptionsAndNoSearchShowsTheEmptyLine`; `PVPopupListTests.swift` `PVPopupListPlacementTests` | `OmnibarResultsModelTests` `loadingPresentsBeforeHitsArrive` reads `showsLoadingState` / `showsEmptyState` / `showsErrorState`; `searchFailureSurfacesMappedErrorNotEmpty` reads `showsErrorState` / `showsEmptyState` |
| Docs | `macos/App/DesignSystem/README.md` rows Popup, PopupList, ComboBox, ScrollRowIntoView ("the omnibar results"), OmnibarHitRow (Recipes table), "The combo box subset" and "Sizing is the caller's job"; `docs/design-system-layers.md` folder tree (`Recipes/OmnibarHitRow/`); `.agents/skills/add-searchable-kind/SKILL.md` (Swift callers line) | Name the omnibar's own panel and the recipe folder |

**Precedent.** [#928](https://github.com/Jake-Robins-Studios/provenencia/pull/928) (S16-51) moved `PVTextArea`'s completion onto `.pvPopupList`: copy how `PVTextArea.completionPopup` attaches `.pvPopupList` to its anchor with a `Binding` whose setter closes the session, and how `PVComboBox` builds `PVPopupListCard` from one `rowsStack` shared with its measuring copy and forwards movement keys to its `PVPopupListHighlight` from `onKeyPress`. `PVTitleText` moved from `Features/Conclusions` to `DesignSystem/Components/TitleText/` (S13-34): copy the folder move and its README row. Do not copy `PVComboBox`'s open-on-a-click or open-on-a-movement-key behavior (Out).

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `OmnibarResultsHost` becomes `struct OmnibarResultsHost: ViewModifier` in the same file, applied to the field in `WorkspaceToolbar.omnibarField` as `.modifier(OmnibarResultsHost(results: omnibarResults, projectDir: projectDir, onActivate: { omnibarResults.activate($0, navigation: navigation) }))`. Its `body(content:)` adds, in this order: the field's frame read (D-6), `.background` with the measuring copy (D-11) while `results.isPresented`, `.pvPopupList` (D-7), `.onKeyPress(action:)` calling `results.handleKey` (D-4), and `.onDisappear { results.dismiss() }`. `WorkspaceContent`'s `OmnibarResultsHost` overlay goes; `WorkspaceContent` keeps owning `omnibarResults` and passing it to the toolbar | `.pvPopupList` anchors to the `NSView` behind the view it modifies, and the presenter's "a click on the field keeps it open" reads that same view (S16-51 D-4); the field is that view. Keeping the name keeps the file and the map's wording | A host that stays in `WorkspaceContent` and passes `anchorRect` — because it has no `NSView` of the field to convert to screen coordinates |
| D-2 | The highlight moves to `OmnibarResultsModel` as `private(set) var highlight = PVPopupListHighlight()`. New on the model: `var highlightedHit: CatalogSearchHit?` (`search.hits[i]` for `highlight.current(count: search.hits.count)`), `func hover(at row: Int)` (`highlight.hover(at:count:isDisabled:)`), `func handleKey(_ key: KeyEquivalent, command: Bool, navigation: WorkspaceNavigation) -> KeyPress.Result` (D-4). No hit is disabled: every `isDisabled` closure is `{ _ in false }`. `CatalogSearchModel.selectedIndex`, `moveSelection(delta:)` and `selectedHit()` go | Working rule "(Batch 6) One kit popup list under the combo box and the omnibar": "the omnibar's highlight (`CatalogSearchModel.selectedIndex`, `moveSelection`, `selectedHit`) moves to `OmnibarResultsModel`", and each field holds one `PVPopupListHighlight` (S16-51 D-5). Promote's picker shares `CatalogSearchModel` and never reads the selection | Keeping the index on `CatalogSearchModel` — because the rule moves it and the picker has its own highlight inside `PVComboBox` |
| D-3 | The landing: `CatalogSearchModel.scheduleSearch(projectDir:location:store:onResults:)` gains `onResults: @escaping @MainActor () -> Void = {}`, called last in `apply`, after `hits`, `searchError`, `hasSearched` and `isLoading` are set, for a success and a failure. `OmnibarResultsModel.scheduleSearch` passes `{ [weak self] in self?.landHighlight() }`, where `private func landHighlight()` is `highlight.land(count: search.hits.count, isDisabled: { _ in false })`. `OmnibarResultsModel.dismiss()` calls `highlight.clear()`. `CatalogSearchModel.dismiss()` and `apply` no longer touch a selection | The first hit is highlighted when results arrive, as `selectedIndex = 0` does today (AC-2.1). A per-call closure keeps the search model free of the omnibar's state and runs exactly when the hits change | A stored callback property on `CatalogSearchModel` — because only one caller wants it, per search. An `.onChange(of: hits)` in the view — because it cannot be tested without a window |
| D-4 | `handleKey`: when `!isPresented`, every key is `.ignored` and nothing changes (AC-2.6). When presented: a key for which `PVPopupListHighlight.isMovementKey` is true calls `highlight.move(key, command: command, count: search.hits.count, isDisabled: { _ in false })` and is `.handled`; `.return` and keypad Enter (`KeyEquivalent("\u{3}")`) activate `highlightedHit` through `activate(_:navigation:)` when there is one, and are `.handled` either way (AC-2.4, as today's monitor swallowed Return); `.escape` calls `closePanel()` and is `.handled`; any other key is `.ignored`. The modifier calls it as `results.handleKey(press.key, command: press.modifiers.contains(.command), navigation: navigation)` with `navigation` from `@Environment(WorkspaceNavigation.self)` | Return is the field's (rule "(Batch 6) One kit popup list under the combo box and the omnibar", reworded 2026-11-21): "Return opens and clears; Escape keeps the query". A model method tests every key without a window, as `PVComboBoxMatch.returnAction` does | A key handler on the list — because the kit list takes no keys (S16-51 D-5). Opening a closed list on a movement key, as `PVComboBox` does — Out |
| D-5 | The line: `enum OmnibarResultsLine: Equatable` *(new, in `OmnibarResultsModel.swift`)* with `case rows, searching, noMatches, failed(message: String)`, and `var line: OmnibarResultsLine` on the model: `PVPopupListLineKind.of(rowCount: search.hits.count, isLoading: search.isLoading)` gives `.rows` → `.rows`, `.loading` → `.searching`, `.empty` → `.failed(message: search.searchError!)` when `searchError` is non-nil, else `.noMatches`. Write the failure case as `if let message = search.searchError { return .failed(message: message) }`. `CatalogSearchModel.showsLoadingState` and `showsEmptyState` go; `showsErrorState` stays for `PromoteView.emptyLine` | One decision for what the card shows, tested without a view, built on the kit's line decision (rule: "the loading line's decision joins the kit in S16-52, its second caller"). It keeps today's order: a failure is never drawn as no match, and hits on screen stay while a search runs (`.rows`) | Three `shows…` booleans read in order by the view — because the order is a rule and belongs in one tested value |
| D-6 | The width: `OmnibarResultsModel.panelWidth` becomes `static let listWidth: CGFloat = 640` (OR-3) and `static func fittedListWidth(fieldFrame: CGRect) -> CGFloat` *(new)*: `fieldFrame == .zero` → `listWidth`; else `max(fieldFrame.width, min(listWidth, fieldFrame.maxX - PVSpacing.space6))`. `fieldFrame` is the field's frame in `HistoryJumpMenuModel.contentCoordinateSpace`, whose x = 0 is the content column's left edge. The modifier writes it with `.onGeometryChange(for: CGRect.self) { $0.frame(in: .named(HistoryJumpMenuModel.contentCoordinateSpace)) } action: { results.fieldFrame = $0 }`; `OmnibarFieldAnchorKey`, the field's `GeometryReader` background and the toolbar's `.onPreferenceChange(OmnibarFieldAnchorKey.self)` go | The map's structural-debt line: cap to the content column as the history menu is. The list hangs leftward from the field, so the room is the field's `maxX`; the 16 pt is the history menu's inset (`fittedPanelWidth`). At the 700 pt window the field ends at about 404 pt and the list is about 388 pt | `HistoryJumpMenuModel.fittedPanelWidth` — because it measures the room to the right of a menu that hangs rightward, and S16-53 reworks it. Keeping the preference key — because the modifier sits on the field and reads its frame directly |
| D-7 | The kit list takes an alignment. `.pvPopupList` gains `alignment: HorizontalEdge = .leading`, passed to `PVPopupListWindow` and stored on its `Coordinator`. `PVPopupListPlacement.anchorFrame(_ anchor: CGRect, width: CGFloat?, alignment: HorizontalEdge) -> CGRect` *(new)*: nil `width` returns `anchor`; `.leading` keeps `minX` and sets the width; `.trailing` sets `minX = anchor.maxX - width` and the width. `Coordinator.frame()` replaces `if let width { anchorOnScreen.size.width = width }` with `anchorOnScreen = PVPopupListPlacement.anchorFrame(anchorOnScreen, width: width, alignment: alignment)`; `popupFrame` then clamps to the screen as today. `applyPresentation()` also re-frames when `width` differs from the width it last framed for (`private var framedWidth: CGFloat?`, set in `show()`'s branch and the re-frame branch with `shownHeight`, cleared in `hide()`). The omnibar passes `width: OmnibarResultsModel.fittedListWidth(fieldFrame: results.fieldFrame)`, `alignment: .trailing`, `maxHeight: OmnibarResultsModel.maxListHeight` (`420`, *(new)* constant), `contentHeight: measuredHeight + PVSpacing.space2 * 2`, `optionCount: search.hits.count`, `isMeasured: rowsMeasured` | OR-3: the list's trailing edge is the field's, and a resize changes the width without changing the rows. A placement function keeps the rule pure and tested beside `popupFrame` | Measuring the field's screen rect in the caller and passing `anchorRect` — because the caller has no `NSView`. A list as wide as the field — because the rows need about 640 pt (OR-3; if the board chooses the field's width, D-6 and D-7 change at refresh) |
| D-8 | `PVOmnibarHitRow` moves with `git mv` to `macos/App/DesignSystem/Components/OmnibarHitRow/PVOmnibarHitRow.swift` *(new)*; the type keeps its name and init. Its `.padding(.horizontal, 9)` becomes `.padding(.horizontal, PVSpacing.space5)`; `.padding(.vertical, 7)` stays; its `.clipShape(RoundedRectangle(cornerRadius: PVRadius.xs, style: .continuous))` and `.contentShape(Rectangle())` go, since `PVPopupListRow` draws the highlight and the hit area. The `#Preview`'s `.padding(PVSpacing.space2)` goes. These are the brief's OR-2 recommendation and are fixed to the board at refresh | Map: "content-agnostic and titled with a `String`", moved as `PVTitleText` was (S13-34). The row shell owns the highlight now | Renaming it — because the name says what it draws and one caller uses it |
| D-9 | The card: `PVPopupListCard(rowIDs: search.hits.map(\.id), activeID: highlightedHit?.id, verticalPadding: PVSpacing.space2) { rowsStack }` with `.accessibilityElement(children: .contain)`, `.accessibilityLabel(Text(L10n.Workspace.omnibarResultsAccessibilityLabel))` and `.accessibilityIdentifier("workspace.toolbar.omnibar.results")`. `rowsStack` is a `VStack(spacing: 0)`: `.rows` draws each hit as `PVPopupListRow(isActive: index == highlight.index, onHighlight: { results.hover(at: index) }, onCommit: { onActivate(hit) }) { CatalogSearchHitRow(hit: hit, projectDir: projectDir) }` with `.id(hit.id)` and `.accessibilityIdentifier("workspace.toolbar.omnibar.hit.\(hit.id)")`; `.searching` draws `PVPopupListSearchingLine()` with identifier `workspace.toolbar.omnibar.loading`; `.noMatches` draws `PVPopupListLine { VStack(alignment: .leading, spacing: PVSpacing.space3) { title; hint } }` with today's two `Text`s and fonts, identifier `workspace.toolbar.omnibar.noMatches`; `.failed(message)` draws `PVPopupListLine { PVCallout(tone: .danger, message: message) }`, identifier `workspace.toolbar.omnibar.error`. The no-match title gets `.fixedSize(horizontal: false, vertical: true)` so a long query wraps (OR-7) | OR-1, OR-2, OR-6 – OR-8. The identifiers stay so a later UI test finds the same names | `PVComboBox` with `onQueryChange` — because its field is a picker that restores a committed label; the omnibar's field is a command field (rule) |
| D-10 | The kit line pieces, in `PVPopupList.swift`: `enum PVPopupListLineKind: Equatable { case rows, loading, empty; static func of(rowCount: Int, isLoading: Bool) -> PVPopupListLineKind }` *(new)*, the body of today's `PVComboBoxMatch.listLine` (rows when any; else loading while loading; else empty); `struct PVPopupListSearchingLine: View { var gutter: CGFloat = 0 }` *(new)*, today's combo box searching line (`PVPopupListLine(gutter:)` holding an `HStack(spacing: PVSpacing.space3)` of `ProgressView().controlSize(.small)` and `Text(L10n.DesignSystem.popupListSearching)` in `PVFont.body(size: PVTypeScale.bodySmall)`, `PVColor.textMuted`, with `.accessibilityElement(children: .combine)`). `PVComboBoxMatch.ListLine` and `listLine` go; `PVComboBox.rowsStack` switches on `PVPopupListLineKind.of(rowCount:isLoading:)` and draws `PVPopupListSearchingLine(gutter: Self.checkGutter)` with its `identifier("loading")`. `L10n.DesignSystem.comboBoxSearching` is renamed `popupListSearching` (key `designSystem.popupList.searching`, comment "Kit popup list line while a remote search runs and no results are in yet"); `L10n.Workspace.omnibarSearching` and `workspace.omnibar.searching` go | Working rule: the list owns "the loading, empty and error lines", and the loading line's decision joins the kit with its second caller. S16-51 Out sent the rename here "if the omnibar draws the same line"; both strings read the same English text | Keeping two strings — because they are one line |
| D-11 | The measuring copy, in `PVPopupList.swift`: `struct PVPopupListMeasure<Rows: View>: View` *(new)* with `let isActive: Bool`, `var width: CGFloat? = nil`, `let onHeight: (CGFloat) -> Void`, `@ViewBuilder let rows: Rows`. Its body is `PVComboBox.measuringRows`'s: the rows with `.frame(width: width)` when `width` is set, `.fixedSize(horizontal: false, vertical: true)`, `.hidden()`, `.allowsHitTesting(false)`, `.accessibilityHidden(true)`, and a `GeometryReader` background whose `.onChange(of: proxy.size.height, initial: true)` calls `onHeight(height)` when `isActive` and `height > 0`. `PVComboBox.measuringRows` becomes `PVPopupListMeasure(isActive: isOpen, onHeight: { measuredRowsHeight = $0; rowsMeasured = true }) { rowsStack }`. The omnibar measures at `fittedListWidth`, into `@State measuredHeight` and `@State rowsMeasured` on the modifier, both reset to `0` / `false` when `results.isPresented` turns false | Hit rows differ in height (a match line or none), so the window needs a measured height before it shows; the no-match and failure lines wrap at the list's width, which is wider than the field. Two callers now: the kit README's "Sizing is the caller's job" keeps the caller holding the height, and the kit holds the measuring view | A copy of `measuringRows` in the omnibar — because it is the second copy of the same twenty lines. A fixed row height — because rows with and without a match line differ |
| D-12 | Presenting: `.pvPopupList(isPresented: Binding(get: { results.isPresented }, set: { if !$0 { results.closePanel() } }), …)`. A close from the presenter (a click outside, an app switch) is `closePanel()`: the query stays. `historyButton`'s `omnibarResults.closePanel()` stays | AC-3.1 – AC-3.3: the presenter's rules with `keysStayInField` and `staysOpenOnFieldClick`, which `.pvPopupList` always passes (S16-51 D-4) | `dismiss()` on a click outside — because today a click away keeps the query |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

Searched for: `selectedIndex`, `moveSelection`, `selectedHit`, `showsLoadingState`, `showsEmptyState`, `listLine`, `comboBoxSearching`, `omnibarSearching`, `measuringRows`, `fittedPanelWidth`, `onGeometryChange`, `OmnibarFieldAnchorKey`, `PVMenuRowButtonStyle(`, `PVFloatingMenuSelection.moveIndex(` across `macos/App` and `macos/ProvenenciaTests`.

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `PVPopupListLineKind` *(new)* | type | `PVComboBoxMatch.ListLine` / `listLine` | It is that type, moved into the kit for its second caller (D-10) |
| `PVPopupListSearchingLine` *(new)* | component | the searching line inside `PVComboBox.rowsStack` | It is that view, moved (D-10) |
| `PVPopupListMeasure` *(new)* | component | `PVComboBox.measuringRows` | It is that view, moved, with a `width` for a list wider than its field (D-11) |
| `PVPopupListPlacement.anchorFrame` *(new)* | func | the `if let width` line in `PVPopupListWindow.Coordinator.frame()` | It is that line, plus the trailing case, made pure (D-7) |
| `.pvPopupList(alignment:)` *(new parameter)* | param | `.pvPopupList(width:)` | A real difference of one popup, as `width` and `anchorRect` are |
| `OmnibarResultsLine`, `OmnibarResultsModel.line` *(new)* | type, property | `CatalogSearchModel.showsLoadingState` / `showsEmptyState` / `showsErrorState` | Replaces the two the omnibar alone reads with one ordered value (D-5) |
| `OmnibarResultsModel.handleKey`, `hover(at:)`, `highlightedHit`, `highlight` *(new)* | func, property | `CatalogSearchModel.moveSelection`, `selectedHit`, `selectedIndex`; `OmnibarResultsHost.armDismissMonitor` | They move here per the working rule, onto `PVPopupListHighlight` (D-2, D-4) |
| `OmnibarResultsModel.fittedListWidth`, `listWidth`, `maxListHeight` *(new)* | func, constants | `HistoryJumpMenuModel.fittedPanelWidth`; `OmnibarResultsModel.panelWidth`; the panel's `frame(maxHeight: 420)` | The history menu hangs the other way (D-6); `panelWidth` is renamed; 420 becomes a named constant |
| `CatalogSearchModel.scheduleSearch(onResults:)` *(new parameter)* | param | `LatestCall.start(apply:)` | The search's own completion, exposed once for the caller that lands a highlight (D-3) |
| `L10n.DesignSystem.popupListSearching` *(renamed)* | key | `comboBoxSearching`, `omnibarSearching` | One key for the one line (D-10) |

**Builds on.** `.pvPopupList` and `.pvPopup` (S16-50, S16-51); `PVPopupListHighlight` and `PVListKeyboard.moveIndex`; `PVPopupListCard`, `PVPopupListRow`, `PVPopupListLine`; `PVPopupListPlacement`; the folder move of `PVTitleText`.
**Deletes.** `OmnibarResultsHost.armDismissMonitor`, `removeDismissMonitor` and `dismissMonitor`; `OmnibarResultsPanel` (its `loadingState`, `errorState`, `emptyState`); `OmnibarFieldAnchorKey`, the field's `GeometryReader` background and the toolbar's `.onPreferenceChange(OmnibarFieldAnchorKey.self)`; `WorkspaceContent`'s `OmnibarResultsHost` overlay; `OmnibarResultsModel.panelWidth`; `CatalogSearchModel.selectedIndex`, `moveSelection(delta:)`, `selectedHit()`, `showsLoadingState`, `showsEmptyState`; `PVComboBoxMatch.ListLine` and `listLine`; `PVComboBox.measuringRows`'s body; `L10n.Workspace.omnibarSearching` and `workspace.omnibar.searching`; the `designSystem.comboBox.searching` key (renamed); `CatalogSearchTests.moveSelectionClampsAndSelectedHit`; the three `listLine` tests in `PVComboBoxTests` (moved); `PVOmnibarHitRow`'s rounded clip and the `macos/App/DesignSystem/Recipes/OmnibarHitRow/` folder. `PVFloatingMenuSelection.moveIndex(from:delta:count:)` loses this caller and keeps the history menu's (S16-53).
**Next adds.** S16-53 moves the history menu onto `.pvPopup` and retires `PVFloatingMenuSelection.moveIndex(from:delta:count:)` and `HistoryJumpMenuModel.fittedPanelWidth`'s hand-placed overlay; a third popup list that is wider than its field passes `width:` and `alignment:`; a third list with remote rows uses `PVPopupListLineKind` and `PVPopupListSearchingLine`.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| Home, End, ⌘↑/⌘↓, Page Up/Down reach the highlight | `OmnibarResultsModel.handleKey` | On 0 hits `highlight.move` leaves −1 (`PVListKeyboard.moveIndex` returns −1 for `count` 0); `highlightedHit` is nil; Return does nothing (AC-2.4, T-8) |
| A click in the field while the list is open passes through the presenter | `PVPopupDecision.decide` with `staysOpenOnFieldClick` | The list stays open; the caret moves (AC-3.2) |
| The list as its own window over the sidebar or off the window | `PVPopupListPlacement.popupFrame` | Clamped to the screen's visible frame; the width cap keeps it in the content column (AC-1.2, AC-1.3) |
| The window resized while the list is open | `PVPopupListWindow.Coordinator.applyPresentation` | Re-frames on the new width (D-7); the follow observer moves it with the field |

### Scale

At the map's Scale: a search returns at most `DefaultHitLimit` (50, `core/search/search.go`) hits. The list builds 50 `CatalogSearchHitRow`s twice (the card and the measuring copy), as `PVComboBox` builds its rows twice; thumbnails come through `ThumbnailCache.shared`, so the second copy does not read a file again. No write, no catalog read and no cache key change: the hits the search already returns (map: "no new read").

### Edges

- **Assumptions.** `PVPopupListHighlight` assumes the field calls `land` when the rows change; D-3 calls it after every applied search, success or failure (T-4, T-12). `highlightedHit` assumes `index < hits.count`; `current(count:)` checks it (T-6, T-8). `PVPopupListWindow.Coordinator` assumes the width only changes with the rows; D-7 re-frames on a width change.
- **Neighbors.** A query of exactly 2 characters searches and presents; 1 does not (`isBelowMinimumQuery`, unchanged, `shortQueryDoesNotPresent`). Hits on screen with a new search running: `.rows`, no searching line (T-12). A search that fails after hits were shown: `hits = []`, `.failed` (T-12). Escape, then typing: `scheduleSearch` clears `userDismissed` and the list returns (unchanged). Escape, then ↓: `.ignored` (T-6).
- **Removed inputs.** `dismiss()` (a navigation, the host disappearing) clears the hits and the highlight (T-11); a highlight never points past a shorter new list because each apply lands it again.
- **Real data.** None — no table or seed drives a rule here.
- **Untrusted size.** The hit list is capped at 50 by the engine before it reaches Swift; a 120-character query wraps the no-match title inside the card (OR-7, D-9).

### Schema

None — no catalog change.

### Go core

None — no engine change.

### FFI

None — no RPC change.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| The list and its window | `.pvPopupList` | `macos/App/DesignSystem/Components/PopupList/PVPopupList.swift` | D-7, D-12 |
| Card and scroller | `PVPopupListCard` | same | D-9; keeps the highlighted row in view, a new list starts at its top |
| Row shell | `PVPopupListRow` | same | D-9 |
| Searching line | `PVPopupListSearchingLine` *(new)* | same | D-10 |
| No-match and failure lines | `PVPopupListLine` + `Text` / `PVCallout` | same; `PVCallout` | D-9 |
| Measuring copy | `PVPopupListMeasure` *(new)* | same | D-11 |
| Hit row | `PVOmnibarHitRow` | `macos/App/DesignSystem/Components/OmnibarHitRow/PVOmnibarHitRow.swift` *(new)* | D-8 |
| Hit content | `CatalogSearchHitRow` | `macos/App/Features/Catalog/Search/CatalogSearchHitRow.swift` | Unchanged |
| Host | `OmnibarResultsHost` (`ViewModifier`) | `macos/App/Features/Workspace/OmnibarResultsHost.swift` | D-1 |
| Model | `OmnibarResultsModel` | `macos/App/Features/Workspace/OmnibarResultsModel.swift` | D-2 – D-6 |

States: searching with no hits → the searching line; hits with a search running → the hits; no hits → the no-match line; failure → the danger Callout; more than 420 pt of rows → the card scrolls. Accessibility: the card is a container labelled `L10n.Workspace.omnibarResultsAccessibilityLabel`; each row speaks `CatalogSearchHitRow`'s label and takes VoiceOver's default action (`PVPopupListRow`); the searching line is one element. The field keeps keyboard focus throughout.

### Strings

L10n: `L10n.DesignSystem.comboBoxSearching` renamed `L10n.DesignSystem.popupListSearching` (key `designSystem.comboBox.searching` → `designSystem.popupList.searching`, English text unchanged). Removed: `L10n.Workspace.omnibarSearching` (`workspace.omnibar.searching`). Unchanged: `omnibarNoMatchesTitle`, `omnibarNoMatchesHint`, `omnibarSearchFailed`, `omnibarResultsAccessibilityLabel`. No action changes what it covers.

## 7. Steps

**STEP-1 — The kit list owns its line decision and its searching line**
Files: `macos/App/DesignSystem/Components/PopupList/PVPopupList.swift`, `macos/App/DesignSystem/Components/ComboBox/PVComboBox.swift`, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `macos/ProvenenciaTests/PVComboBoxTests.swift`, `macos/ProvenenciaTests/PVPopupListTests.swift`. Skill: `add-ui-component`, `add-localized-string`, `add-swift-test`.
Do: D-10. Add `PVPopupListLineKind` and `PVPopupListSearchingLine`; switch `PVComboBox.rowsStack` onto them; delete `PVComboBoxMatch.ListLine` and `listLine`; rename the string and its catalog key. Update the `PVComboBox` doc comment's "Remote results" paragraph to name `PVPopupListLineKind`. Move the three `listLine` tests into `PVPopupListTests` as T-1.
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/PVPopupListTests -only-testing:ProvenenciaTests/PVComboBoxTests` passes; `rg -n "comboBoxSearching|ListLine\b|listLine" macos` finds nothing.

**STEP-2 — The kit measures a list's rows**
Files: `PVPopupList.swift`, `PVComboBox.swift`. Skill: `add-ui-component`.
Do: D-11. Add `PVPopupListMeasure`; `PVComboBox.measuringRows` uses it. Move the "measuring" explanation from `measuringRows`'s doc comment to `PVPopupListMeasure`'s.
Check: the build passes; `PVComboBoxTests` passes; the Source type picker on a Source type page opens at its rows' height, as before.

**STEP-3 — A popup list can hang from its field's trailing edge**
Files: `PVPopupList.swift`, `macos/ProvenenciaTests/PVPopupListTests.swift`. Skill: `add-ui-component`, `add-swift-test`.
Do: D-7's kit half: `alignment:` on `.pvPopupList` and `PVPopupListWindow`, `PVPopupListPlacement.anchorFrame`, `Coordinator.frame()` calling it, and the re-frame on a width change. Add T-2 and T-3 to `PVPopupListPlacementTests`.
Check: `-only-testing:ProvenenciaTests/PVPopupListPlacementTests` passes; `PVTextArea`'s `{` completion in the citation format editor still opens at the caret.

**STEP-4 — The omnibar's model holds its highlight, keys, line and width**
Files: `macos/App/Features/Workspace/OmnibarResultsModel.swift`, `macos/App/Features/Catalog/Search/CatalogSearchModel.swift`, `macos/ProvenenciaTests/OmnibarResultsModelTests.swift`, `macos/ProvenenciaTests/CatalogSearchTests.swift`. Skill: `add-swift-test`.
Do: D-2 – D-6 on the models (not the view). `OmnibarResultsModel` imports SwiftUI for `KeyEquivalent` and `KeyPress.Result`. Delete `moveSelectionClampsAndSelectedHit`; in `emptyStateRequiresCompletedSearchWithoutError` keep only the `showsErrorState` expectations and rename it `errorStateNeedsAFailure`; rewrite `loadingPresentsBeforeHitsArrive` and `searchFailureSurfacesMappedErrorNotEmpty` on `line`; add T-4 – T-13. `OmnibarResultsHost.swift` still compiles against the old panel until STEP-6: in this step it reads `results.line` instead of the deleted `shows…` properties, `results.highlightedHit` instead of `selectedHit()`, `results.highlight.index` instead of `selectedIndex`, `results.hover(at:)` on hover, and `results.handleKey` for ↓/↑ (`.downArrow` / `.upArrow`) and Return; it still uses `OmnibarResultsModel.listWidth` for its frame.
Check: `-only-testing:ProvenenciaTests/OmnibarResultsModelTests -only-testing:ProvenenciaTests/CatalogSearchModelTests` passes; `rg -n "selectedIndex|moveSelection|selectedHit|showsLoadingState|showsEmptyState" macos/App/Features/Catalog/Search` finds nothing.

**STEP-5 — The hit row joins the kit's components**
Files: `macos/App/DesignSystem/Recipes/OmnibarHitRow/PVOmnibarHitRow.swift` → `macos/App/DesignSystem/Components/OmnibarHitRow/PVOmnibarHitRow.swift` *(new)*. Skill: `add-ui-component`.
Do: D-8 with `git mv`. No `project.pbxproj` edit: `App/DesignSystem` is a synchronized folder (kit README "Xcode project registration").
Check: the build passes; `ls macos/App/DesignSystem/Recipes/OmnibarHitRow` fails (no such folder).

**STEP-6 — The omnibar draws the kit popup list**
Files: `macos/App/Features/Workspace/OmnibarResultsHost.swift`, `macos/App/Features/Workspace/WorkspaceToolbar.swift`, `macos/App/Features/Workspace/WorkspaceContent.swift`, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`. Skill: `add-ui-component`, `add-localized-string`.
Do: D-1, D-6 (the frame read), D-7 (the omnibar's call), D-9, D-11 (the omnibar's measuring), D-12. Rewrite `OmnibarResultsHost` as the modifier; delete `OmnibarResultsPanel`, the monitor, `OmnibarFieldAnchorKey`; apply the modifier in `omnibarField` and remove the field's `GeometryReader` background and the toolbar's preference read; remove the overlay from `WorkspaceContent` and update its doc comment (its "Hosted here" comment names only the jump menu now). Delete `L10n.Workspace.omnibarSearching` and its catalog entry. Update `OmnibarResultsModel`'s doc comment to "The toolbar omnibar's results: the highlight, the keys, the line and the width around a shared `CatalogSearchModel`".
Check: the build passes with no Swift warning; AC-4.1 and AC-4.3 `rg` lines find nothing; in the app, §10 steps 1–8.

**STEP-7 — The kit's docs and skills say where the list lives**
Files: `macos/App/DesignSystem/README.md`, `docs/design-system-layers.md`, `.agents/skills/add-searchable-kind/SKILL.md`. Skill: —.
Do: README: the Popup row's `.pvPopupList` sentence names its three callers (combo box, completion, omnibar), `alignment:`, `PVPopupListLineKind`, `PVPopupListSearchingLine` and `PVPopupListMeasure`; the ComboBox row says the searching line and the measuring copy are the kit list's; the OmnibarHitRow row moves from the Recipes table to the Components table as `Components/OmnibarHitRow/PVOmnibarHitRow.swift` (the row the omnibar's popup list draws for each hit; content-agnostic, titled with a `String`); "The combo box subset" names `PVPopupListLineKind` where it names the searching line; "Sizing is the caller's job" says the caller holds the height and lays the rows out through `PVPopupListMeasure`. `design-system-layers.md`: the folder tree's `Recipes/OmnibarHitRow/PVOmnibarHitRow.swift` example becomes `Recipes/PersonCard/PVPersonCard.swift`. `add-searchable-kind`: the Swift callers line adds that the omnibar draws hits on the kit popup list (`OmnibarResultsHost`) and holds its highlight in `OmnibarResultsModel`.
Check: AC-4.4 `rg` finds nothing; `python3 scripts/check-guidance-names.py` passes.

**STEP-8 — Docs**
Files: `docs/deployment-plan/spike-16/completed.md`, `docs/deployment-plan/spike-16/deployment-plan.md` (map row), this plan (status, Landed note), `docs/deployment-plan/spike-16/design/S16-D9-omnibar-results.md` → `design/archive/`, `docs/deployment-plan/spike-16/design/README.md`; `VERSION`, `core/version.go`, `MARKETING_VERSION`.
Do: per the Definition of done; patch bump.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-52-omnibar-popup-list.md` reports no errors; `scripts/check-pr.sh` prints `check-pr: PASS`.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `macos/ProvenenciaTests/PVPopupListTests.swift` `searchingLineShowsOnlyWhileLoadingWithNothingIn`, `rowsAlreadyInStayWhileANewSearchRuns`, `noRowsAndNoSearchShowsTheEmptyLine` *(moved from `PVComboBoxTests`)* | `PVPopupListLineKind.of(rowCount: 0, isLoading: true)` → `.loading`; `(3, true)` → `.rows`; `(0, false)` → `.empty`; `(2, false)` → `.rows` | D-10, AC-1.4 |
| T-2 | Swift | `PVPopupListTests.swift` `PVPopupListPlacementTests.anchorFrameAlignsTheWidthToAnEdge` *(new)* | anchor `(600, 100, 300, 24)`: width nil → the anchor; width 640 `.leading` → `(600, 100, 640, 24)`; width 640 `.trailing` → `(260, 100, 640, 24)` | D-7, AC-1.1 |
| T-3 | Swift | same, `trailingListStaysOnScreen` *(new)* | anchor `(100, 500, 300, 24)`, width 640, `.trailing` → `anchorFrame` minX −240; `popupFrame(anchor:contentHeight: 200, visibleFrame: (0, 0, 1440, 900))` → minX 0, width 640, maxY 496 | D-7, AC-1.3 |
| T-4 | Swift | `macos/ProvenenciaTests/OmnibarResultsModelTests.swift` `resultsLandOnTheFirstHit` *(new)* | FakeStore seeds hits a, b, c; query `abc`; `scheduleSearch`; `await waitForSearch` → `highlightedHit?.id == "a"`; a second search seeded b, c after ↓↓ → `highlightedHit?.id == "b"` | D-3, AC-2.1 |
| T-5 | Swift | same, `movementKeysMoveTheHighlight` *(new)* | three hits landed on a: ↓ → b, End → c, Home → a, Page Down → c, ⌘↑ → a, ↑ → a; each returns `.handled` | D-4, AC-2.2 |
| T-6 | Swift | same, `keysPassWhileTheListIsClosed` *(new)* | three hits landed, `closePanel()`: ↓, `.return`, `.escape` → `.ignored`; `highlight.index` unchanged; `navigation.currentLocation` unchanged | D-4, AC-2.6 |
| T-7 | Swift | same, `returnOpensTheHighlightedHitAndClears` *(new)* | three hits with locations, ↓ then `.return` → `.handled`, navigation at b's location, `search.query` empty, `!isPresented`; the same with `KeyEquivalent("\u{3}")` | D-4, AC-2.3 |
| T-8 | Swift | same, `returnWithNoHitIsTakenAndOpensNothing` *(new)* | query `il`, `search.isLoading = true`, no hits: `.return` → `.handled`, navigation unchanged, query `il` | D-4, AC-2.4 |
| T-9 | Swift | same, `escapeClosesAndKeepsTheQuery` *(new)* | hits landed, `.escape` → `.handled`, `!isPresented`, query unchanged, `userDismissed` | D-4, AC-2.5 |
| T-10 | Swift | same, `hoverMovesTheHighlight` *(new)* | three hits: `hover(at: 2)` → c; `hover(at: 9)` → still c | D-2, AC-2.7 |
| T-11 | Swift | same, `dismissClearsTheHighlight` *(new)* | hits landed, `dismiss()` → `highlight.index == -1`, `highlightedHit == nil` | D-3 |
| T-12 | Swift | same, `lineFollowsTheSearch` *(new)*; `loadingPresentsBeforeHitsArrive` and `searchFailureSurfacesMappedErrorNotEmpty` *(rewritten)* | query `il`, loading, no hits → `.searching`; loading with one hit → `.rows`; searched, not loading, no hits, no error → `.noMatches`; `searchCatalogError` `catalog.closed` → `.failed(message: L10n.Errors.message(code: "catalog.closed"))` | D-5, AC-1.4 |
| T-13 | Swift | same, `fittedListWidthStaysInTheColumn` *(new)* | `fittedListWidth(fieldFrame:)`: `.zero` → 640; `(650, 10, 420, 28)` → 640; `(204, 10, 200, 28)` → 388; `(10, 10, 200, 28)` → 200 | D-6, AC-1.2 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `PVComboBoxTests`, `PVPopupListTests`, `PVTextAreaCompletionTests`, `OmnibarResultsModelTests`, `CatalogSearchModelTests`, and the Promote picker tests that use `CatalogSearchModel`.

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
- [ ] Domain doc updated if a rule in docs/*.md changed: none — `design-system-layers.md`'s example tree only (STEP-7)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

Use a project with at least 20 Persons named Smith, a Source titled "Ilminster parish register" with ref `SRC-…`, and a note on another Source containing "Ilminster".

1. Window at 1366 pt. Type `ilmin` in the omnibar. The list opens 4 pt under the field, its right edge on the field's right edge, 640 pt wide, with the combo box's card (compare the Source type picker's list) and full-width row highlights; the first hit is highlighted (AC-1.1, AC-2.1).
2. Press ↓, End, Home, Page Down, ⌘↑, ↑; the highlight moves as AC-2.2 says and the caret stays in the field. Hover the third hit; it highlights. Press Return: its place opens and the field empties (AC-2.3, AC-2.7).
3. Type `smith`: twenty hits, the list is 420 pt tall and scrolls; End keeps the last row in view (AC-1.5).
4. Type `ilmin`, click in the field to move the caret: the list stays open. Click the page below: it closes on the release and the field keeps `ilmin` (AC-3.1, AC-3.2). Press ↓ and Return: nothing opens (AC-2.6). Type a letter: the list returns.
5. With the list open, ⌘-Tab to another app: it closes (AC-3.3). Reopen and click a hit: it opens (AC-3.4). Reopen and press Escape: it closes and the query stays (AC-2.5).
6. Type `il` and watch the searching line before the hits arrive; type `zzzz`: the no-match line; type 120 characters of `z`: the title wraps inside the card (AC-1.4).
7. Resize the window to its 700 pt minimum with `ilmin` typed: the list narrows and its left edge stays 16 pt inside the content column, never over the sidebar (AC-1.2). Drag the window so the field is near the screen's left edge: the list stays on screen (AC-1.3).
8. Open the history menu (hold Back) with the results open: the results close. A combo box (Source type picker) and the citation format editor's `{` completion open, move and close as before.
9. Run the `rg` lines of AC-4.1, AC-4.2, AC-4.3 and AC-4.4 from §2: each finds nothing.
10. VoiceOver: with `ilmin` typed, VO lands in "Search results" and reads a row's title, kind and ref; VO-Space on a row opens it.

The failure line (AC-1.4) is checked by T-12; the app has no switch to fail a search on demand.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| `onKeyPress` on `PVInput` does not receive ↑/↓ because the field editor takes them first | `PVComboBox` attaches `onKeyPress` the same way around its `TextField` and receives them; T-5 tests the model, §10 step 2 the field |
| The measuring copy behind a 200 pt field reports a different height from the 640 pt card | D-11 measures at `fittedListWidth`, the card's width |
| The window shows at a stale width after a resize | D-7 re-frames on a width change; §10 step 7 |
| Rows lose `WorkspaceSession` in the popup window | `PVPopupListWindow.updateNSView` passes the host's environment into the window (S16-51); `CatalogSearchHitRow` reads it there |

**Stop and report if:**

- The board (S16-D9) chooses a list width or alignment other than OR-3's recommendation: D-6, D-7 and T-2, T-3, T-13 change before work starts.
- `onKeyPress` on the omnibar's `PVInput` does not receive ↑, ↓, Home, End, Page Up or Page Down with the field focused (§10 step 2 shows the caret moving instead).
- `PVTextAreaCompletionTests`, `PVComboBoxTests` or `PVPopupListTests` need an expected value changed to pass.
- Keypad Enter does not reach `onKeyPress` as `KeyEquivalent("\u{3}")` or as `.return`.
- A Current state row is no longer true at the base (S16-53 landing first changes `WorkspaceToolbar.swift`).

## 12. Open questions

None.

## 13. PR

**Title:** S16-52 — The omnibar's results use the kit popup list
**Body:** objective in one sentence; what shipped against US-1 – US-4; AC evidence; the AC-4.1 – AC-4.4 `rg` output; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-52-omnibar-popup-list.md`.
