# S16-52 — The omnibar's results use the kit popup list

**Status:** Landed in [#932](https://github.com/Jake-Robins-Studios/provenencia/pull/932) (2026-11-21)
**Spike / slice:** Spike 16 · Slice 6d — Popups
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S16-D9](../design/archive/S16-D9-omnibar-results.md), board agreed 2026-11-21; kit pieces from [S16-D11](../design/S16-D11-web-kit-popup-list.md), agreed 2026-11-21
**Board:** [S16-D9 board](https://claude.ai/artifact/1UzGb9TQCd7ZQrmuAN5AY8), page "S3-01 Omnibar Results", frames R1a, R2, R1b, R3, R4 (open the link; the implementer reads the frames there). The web kit's components the board instances: [design system](https://claude.ai/artifact/7AZ8cscWF3f5Wz7gQ39cMe), PopupList and SearchHitRow. The board's card shadow is the web's stand-in: the app keeps the window's own shadow and adds no `.pvShadow`
**Depends on:** S16-51 (landed [#928](https://github.com/Jake-Robins-Studios/provenencia/pull/928)), S16-D9 (agreed), S16-D11 (agreed)
**Blocks:** —
**Branch:** `s16-52-omnibar-popup-list`
**Version bump:** patch — it changes shipped app behavior: the results draw on the kit card, take Home/End, ⌘↑/⌘↓ and Page Up/Down, stay open on a click in the field and stay inside the content column ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md)
**Rules that bind:** `.cursor/rules/design-system-layers.mdc`, `.cursor/rules/swift-tests.mdc`, `.cursor/rules/macos-client.mdc`, `.cursor/rules/macos-l10n.mdc`, `.cursor/rules/versioning.mdc`
**Context:** working rules "(Batch 6) One kit popup list under the combo box and the omnibar" and "(Batch 6) One kit popup presenter, with the shared closing rules"; bars 25 and 26 in [`../deployment-plan.md`](../deployment-plan.md#goal-dogfood-bar); the S16-52 scope entry in [`../deployment-plan.md`](../deployment-plan.md#s16-52--the-omnibars-results-use-the-kit-popup-list); the S16-51 plan's Out, Next adds and Landed note ([`S16-51-popup-list.md`](S16-51-popup-list.md)); the kit README's Popup, PopupList, ComboBox and OmnibarHitRow rows and "The combo box subset" ([`macos/App/DesignSystem/README.md`](../../../../macos/App/DesignSystem/README.md)); [`omnibar-search.md`](../../archive/spike-3/omnibar-search.md)
**Planned:** 2026-11-21 against `main` @ `b57c98a`
**Review:** [`S16-52-omnibar-popup-list.review.md`](S16-52-omnibar-popup-list.review.md) — Fits with changes — Not ready → fixed, 1 round; no open blocker; To user: none open; board agreed 2026-11-21

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

**What stays.** The omnibar field, its placeholder, ⌘K and its width. The search: its 2-character floor, its 180 ms debounce, its ranking and its 50-hit cap. Each hit row's content and its own inset. Return opens the highlighted hit and clears the field; Escape closes the list and keeps the query; typing searches again and reopens the list; opening the history menu closes the results. Hits on screen stay while the next search runs. The no-match copy. Promote's record picker, which draws the same hit row, looks and works as today.

## 2. User stories

**US-1.** As a researcher, when I type in the omnibar, I see the hits in the same list a combo box shows, under the field and inside the window's content column, so the app has one kind of floating list.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | The default window (1366 pt), query `ilmin` with hits | The list is its own window 4 pt under the field, its trailing edge on the field's trailing edge, 640 pt wide, drawn with the kit card (OR-1) and full-width row highlights (OR-2) |
| AC-1.2 | The narrowest window (700 pt), the same query | The list is narrower than 640 pt and its leading edge is 16 pt inside the content column's left edge; it never covers the sidebar (OR-3) |
| AC-1.3 | The window dragged so the field is near the screen's left or bottom edge | The list stays on screen: it moves right to the screen's edge, or trims its height and scrolls |
| AC-1.4 | Query `il` while the search runs with no hits yet; then `zzz` with no hits; then a failing search | The kit searching line (spinner, `Searching…`); the no-match line; the danger Callout with the failure's mapped message (OR-6 – OR-8) |
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

**US-4.** As a contributor, the omnibar uses the kit's list, highlight, searching line, row measuring and width rule, and keeps no watcher of its own.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | `rg -n -e keyCode -e addLocalMonitorForEvents -e armDismissMonitor macos/App/Features/Workspace/OmnibarResultsHost.swift` | No hit |
| AC-4.2 | `rg -n -e selectedIndex -e moveSelection -e selectedHit -e showsLoadingState -e showsEmptyState -e showsErrorState macos/App/Features` | No hit |
| AC-4.3 | `rg -n -e comboBoxSearching -e omnibarSearching -e omnibarSearchFailed -e 'PVComboBoxMatch.ListLine' -e 'enum ListLine' -e 'listLine(' -e OmnibarFieldAnchorKey -e OmnibarResultsPanel -e 'HistoryJumpMenuModel.contentCoordinateSpace' macos` | No hit |
| AC-4.4 | `rg -n -e PVOmnibarHitRow -e 'OmnibarHitRow/' macos docs/*.md .agents .cursor` | No hit |

## 3. Scope

| In | Covered by |
| --- | --- |
| The kit list's line decision (`PVComboBoxMatch.ListLine`, `listLine`) moves into the kit as `PVPopupListLineKind`; the searching line becomes `PVPopupListSearchingLine`; `L10n.DesignSystem.comboBoxSearching` is renamed `popupListSearching` (OR-6) | STEP-1, AC-4.3 |
| The hidden measuring copy of a list's rows becomes the kit's `PVPopupListMeasure`; `PVComboBox` and the omnibar use it | STEP-2, STEP-5 |
| `.pvPopupList` aligns a list wider than its field on the field's trailing edge and re-frames when its width changes; one width rule, `PVPopupListPlacement.fittedWidth`, keeps the omnibar's list and the history menu inside the content column (OR-3) | STEP-3, AC-1.1 – AC-1.3 |
| `CatalogSearchModel.line` is the one decision of what a search shows (rows, searching, no match, failure) for the omnibar and Promote's picker; the three `shows…State` properties go | STEP-4, AC-1.4, AC-4.2 |
| `OmnibarResultsModel` holds the highlight and the keys; `CatalogSearchModel` loses `selectedIndex`, `moveSelection`, `selectedHit` (OR-5) | STEP-5, AC-2.1 – AC-2.7, AC-4.2 |
| `OmnibarResultsHost` draws the kit list on the omnibar field; the overlay, its watcher, `OmnibarResultsPanel`, `OmnibarFieldAnchorKey`, `omnibarSearching` and `omnibarSearchFailed` go (OR-1, OR-2, OR-4, OR-6 – OR-9, OR-W1) | STEP-5, AC-1.1, AC-1.5, AC-3.1 – AC-3.4, AC-4.1, AC-4.3 |
| `PVOmnibarHitRow` moves to the kit's components as `PVSearchHitRow` | STEP-6, AC-4.4 |
| The kit README, `design-system-layers.md`, `add-searchable-kind` and `ideas/kit-layering.md` say where the list and the row live and what is left | STEP-7 |

| Out | Home |
| --- | --- |
| Reopening the list after Escape with ↓ or a click in the field, without typing | not planned: the list comes back when the query changes, as today (brief §3) |
| Search ranking, the hit kinds, the 50-hit cap, the match line's wording | not planned (map: "Not this PR") |
| The omnibar field's own chrome, width or placeholder | not planned (map: "Not this PR") |
| The history menu's `armDismissMonitor`, `activeIndex` and `PVFloatingMenuSelection.moveIndex(from:delta:count:)`, its last caller | S16-53 |
| `PVMenuRowButtonStyle`, which `PVContextMenu`, `PVDeleteImpact` and the history menu still use | not planned: it keeps three callers |
| Grouping hits by kind, a footer, a "show all" row | not planned (brief §2.1) |
| Closing the results when the field loses focus by Tab | not planned: Tab away leaves them open, as today |
| Promote's record picker pads each hit row twice (the combo box's row padding and the hit row's own) | [`ideas/kit-layering.md`](../../../ideas/kit-layering.md) (added in STEP-7) |
| A remote combo box (Promote's picker) lands its highlight before its results arrive, so its first hit is not highlighted | [`ideas/kit-layering.md`](../../../ideas/kit-layering.md) (added in STEP-7) |
| Editing the archived [`omnibar-search.md`](../../archive/spike-3/omnibar-search.md) ("~640px widen-left" still holds) | not planned: archive, not edited |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Results host | `macos/App/Features/Workspace/OmnibarResultsHost.swift` `OmnibarResultsHost` | A `View` in `WorkspaceContent`'s overlay. While `results.isPresented` and `results.fieldFrame != .zero`, it offsets `OmnibarResultsPanel` to `fieldFrame.maxX - OmnibarResultsModel.panelWidth`, `fieldFrame.maxY + 8`. `armDismissMonitor()` installs an `NSEvent` local monitor: it waits out a held button, then on key codes 53 (Escape → `closePanel`), 125/126 (↓/↑ → `search.moveSelection`), 36/76 (Return → `onActivate(search.selectedHit())`) and on any `leftMouseUp` (→ `closePanel`, a click in the field included). `onDisappear` calls `results.dismiss()`. Wrong for this PR: a second watcher beside `.pvPopup`, raw key codes, an overlay clipped to the window |
| Results panel | same file, `private struct OmnibarResultsPanel` | Error (`PVCallout` danger, `searchError ?? L10n.Workspace.omnibarSearchFailed`) → empty (two `Text`s) → loading (`ProgressView` + `L10n.Workspace.omnibarSearching`) → a `ScrollView` of `Button`s with `PVMenuRowButtonStyle(isSelected:cornerRadius: PVRadius.xs, onHoverChange:)`, max 420 pt, `.pvScrollsRowIntoView`; `padding(space2)`, 640 pt wide, `PVRadius.sm`, `borderSubtle`, `pvShadow(PVElevation.overlay)`. Accessibility identifiers `workspace.toolbar.omnibar.results`, `.hit.<id>`, `.loading`, `.error`, `.noMatches` |
| Anchor key | same file, `OmnibarFieldAnchorKey` | A preference the toolbar sets from the field's frame in `HistoryJumpMenuModel.contentCoordinateSpace` |
| Results model | `macos/App/Features/Workspace/OmnibarResultsModel.swift` `OmnibarResultsModel` | `static let panelWidth: CGFloat = 640`; `let search = CatalogSearchModel()`; `userDismissed`; `fieldFrame`; `isPresented` = `!userDismissed && search.showsResults`; `closePanel()` (dismissed, `search.cancel()`); `dismiss()`; `clearAfterNavigate()`; `activate(_:navigation:)`; `scheduleSearch(projectDir:location:store:)` |
| Search model | `macos/App/Features/Catalog/Search/CatalogSearchModel.swift` `CatalogSearchModel` | Shared with Promote's record picker. Holds `selectedIndex` (reset to 0 in `dismiss()` and in `scheduleSearch`'s `apply`), `moveSelection(delta:)` (`PVFloatingMenuSelection.moveIndex(from:delta:count:)`), `selectedHit()`, and `showsLoadingState` / `showsEmptyState` / `showsErrorState`. `scheduleSearch`'s failure sets `searchError = L10n.Errors.message(for: error)`, never nil, so the omnibar's `omnibarSearchFailed` fallback is unreachable |
| Promote picker | `macos/App/Features/Promote/PromoteView.swift` `PromoteRecordSearch` | A `PVComboBox(onQueryChange:isLoading:row:empty:)` over `CatalogSearchModel(kinds:)`; its `row:` draws `CatalogSearchHitRow`; `emptyLine(_:)` returns `searchError` when `showsErrorState`, else `L10n.Promote.searchHint` when `isBelowMinimumQuery`, else `L10n.Promote.searchNoMatches` |
| Toolbar | `macos/App/Features/Workspace/WorkspaceToolbar.swift` `WorkspaceToolbar` | `omnibarField` is `PVInput(text:size: .sm, prompt:icon: .search, suffix: "⌘K", focused:)`, then a `GeometryReader` `.background` setting `OmnibarFieldAnchorKey`, then `.accessibilityLabel` and `.accessibilityIdentifier`; the call site adds `.frame(minWidth: 200, maxWidth: 420)`. `body` has `.onPreferenceChange(OmnibarFieldAnchorKey.self) { omnibarResults.fieldFrame = $0 }` and `.onChange(of: omnibarResults.search.query)` → `scheduleSearch`. `historyButton`'s binding calls `omnibarResults.closePanel()` when the history menu opens, and its anchor reads `.named(HistoryJumpMenuModel.contentCoordinateSpace)`. A `#Preview` builds `WorkspaceToolbar(jumpMenu:omnibarResults:projectDir:store:)` |
| History width | same file, `HistoryJumpMenuModel.contentCoordinateSpace`, `panelWidth` (600), `fittedPanelWidth(contentWidth:anchorMinX:)` = `min(panelWidth, contentWidth - anchorMinX - PVSpacing.space6)`, 0 width → `panelWidth`; called from `HistoryJumpMenuHost` | The same "stay 16 pt inside the column" rule, for a menu that hangs rightward. Tested in `macos/ProvenenciaTests/HistoryJumpMenuModelTests.swift` |
| Content host | `macos/App/Features/Workspace/WorkspaceContent.swift` `WorkspaceContent` | Owns `@State omnibarResults` and `@State contentWidth`; overlays `HistoryJumpMenuHost(jumpMenu:contentWidth:)` and `OmnibarResultsHost(results:projectDir:onActivate:)` with `onActivate` = `omnibarResults.activate(hit, navigation: navigation)`; names the coordinate space `HistoryJumpMenuModel.contentCoordinateSpace` |
| Hit row | `macos/App/DesignSystem/Recipes/OmnibarHitRow/PVOmnibarHitRow.swift` `PVOmnibarHitRow` | Content-agnostic row (lead, title, kind badge, secondary, ref, match context) with its own `.padding(.horizontal, 9)`, `.padding(.vertical, 7)`. One construction site, `CatalogSearchHitRow`, which draws in the omnibar and in Promote's picker |
| Hit content | `macos/App/Features/Catalog/Search/CatalogSearchHitRow.swift` `CatalogSearchHitRow` | Fills the row from a hit; reads `@Environment(WorkspaceSession.self)` |
| Kit list | `macos/App/DesignSystem/Components/PopupList/PVPopupList.swift` | `.pvPopupList(isPresented:isMeasured:maxHeight:contentHeight:optionCount:width:anchorRect:content:)` (its doc names two callers); `PVPopupListWindow.contentHeight`'s doc points at `PVComboBox.measuringRows`; `Coordinator.widened(to:)`'s doc says "exactly as wide as the field"; `Coordinator.frame()` sets `anchorOnScreen.size.width = width` (the list grows rightward); `applyPresentation()` re-frames only when `contentHeight` or `optionCount` changed (`shownHeight`, `shownCount`); `PVPopupListCard` (doc: "both callers"); `PVPopupListRow`; `PVPopupListLine(gutter:minHeight:content:)`; `PVPopupListHighlight`; `PVPopupListPlacement.popupFrame(anchor:contentHeight:visibleFrame:gap:)` |
| Combo box | `macos/App/DesignSystem/Components/ComboBox/PVComboBox.swift` | `PVComboBoxMatch.ListLine` and `listLine(optionCount:isLoading:)`; `rowsStack` draws the searching line itself (`ProgressView` + `L10n.DesignSystem.comboBoxSearching`) in `PVPopupListLine(gutter: Self.checkGutter)` with `identifier("loading")`; `measuringRows` is the hidden measuring copy |
| Strings | `macos/App/Platform/L10n.swift`: `L10n.DesignSystem.comboBoxSearching` (`designSystem.comboBox.searching`), `L10n.Workspace.omnibarSearching` (`workspace.omnibar.searching`), both "Searching…"; `L10n.Workspace.omnibarSearchFailed` (`workspace.omnibar.searchFailed`); `macos/App/Resources/Localizable.xcstrings` | Two keys for one line, and an unreachable fallback |
| Tests | `macos/ProvenenciaTests/OmnibarResultsModelTests.swift`; `CatalogSearchTests.swift` (`CatalogSearchModelTests`) `moveSelectionClampsAndSelectedHit`, `emptyStateRequiresCompletedSearchWithoutError`; `PVComboBoxTests.swift` `searchingLineShowsOnlyWhileLoadingWithNothingIn`, `optionsAlreadyInStayWhileANewSearchRuns`, `noOptionsAndNoSearchShowsTheEmptyLine`; `PVPopupListTests.swift` `PVPopupListPlacementTests`; `HistoryJumpMenuModelTests.swift` | `OmnibarResultsModelTests` `loadingPresentsBeforeHitsArrive` and `searchFailureSurfacesMappedErrorNotEmpty` read the `shows…State` properties |
| Docs | `macos/App/DesignSystem/README.md` rows Popup, PopupList, ComboBox, OmnibarHitRow (Recipes table), "The combo box subset" and "Sizing is the caller's job"; `docs/design-system-layers.md` folder tree (`Recipes/OmnibarHitRow/`); `.agents/skills/add-searchable-kind/SKILL.md` (Swift callers line) | Name the omnibar's own panel and the recipe folder |

**Precedent.** [#928](https://github.com/Jake-Robins-Studios/provenencia/pull/928) (S16-51) moved `PVTextArea`'s completion onto `.pvPopupList`: copy how `PVTextArea.completionPopup` attaches `.pvPopupList` to its anchor with a `Binding` whose setter closes the session, and how `PVComboBox` builds `PVPopupListCard` from one `rowsStack` shared with its measuring copy and forwards movement keys to its `PVPopupListHighlight` from `onKeyPress`. `PVTitleText` moved from `Features/Conclusions` to `DesignSystem/Components/TitleText/` (S13-34): copy the folder move and its README row. Do not copy `PVComboBox`'s open-on-a-click or open-on-a-movement-key behavior (Out).

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `OmnibarResultsHost` becomes `struct OmnibarResultsHost: ViewModifier` in the same file, with `results: OmnibarResultsModel`, `projectDir: String`, `contentWidth: CGFloat`, `onActivate: (CatalogSearchHit) -> Void`. `WorkspaceToolbar.omnibarField` applies it directly after `PVInput(...)`, in place of the removed `GeometryReader` `.background`, before `.accessibilityLabel`: the anchor and the frame read are the `PVInput` itself. `onActivate` is `{ omnibarResults.activate($0, navigation: navigation) }`. `WorkspaceToolbar` gains `let contentWidth: CGFloat`, which `WorkspaceContent` passes (its `contentWidth` state) and the `#Preview` passes as `900`. `body(content:)` adds, in this order: the frame read (D-6), the measuring `.background` (D-11), `.pvPopupList` (D-7, D-12), `.onKeyPress(action:)` (D-4), `.onDisappear { results.dismiss() }`. `WorkspaceContent`'s `OmnibarResultsHost` overlay goes | `.pvPopupList` anchors to the `NSView` behind the view it modifies, and the presenter's "a click on the field keeps it open" reads that view (S16-51 D-4); the field is that view | A host left in `WorkspaceContent` with `anchorRect` — because it has no `NSView` of the field to convert to screen coordinates |
| D-2 | The highlight moves to `OmnibarResultsModel` as `private(set) var highlight = PVPopupListHighlight()`, with `var highlightedHit: CatalogSearchHit?` (the hit at `highlight.current(count: search.hits.count)`) and `func hover(at row: Int)` (`highlight.hover(at:count:isDisabled:)`). No hit is disabled: every `isDisabled` closure is `{ _ in false }`. `CatalogSearchModel.selectedIndex`, `moveSelection(delta:)` and `selectedHit()` go | Working rule "(Batch 6) One kit popup list under the combo box and the omnibar": the omnibar's highlight moves to `OmnibarResultsModel`, and each field holds one `PVPopupListHighlight` (S16-51 D-5). Promote's picker never reads the selection | Keeping the index on `CatalogSearchModel` — because the rule moves it |
| D-3 | The landing: `CatalogSearchModel.scheduleSearch(projectDir:location:store:onResults:)` gains `onResults: @escaping @MainActor () -> Void = {}`, called last in `apply`, after `hits`, `searchError`, `hasSearched` and `isLoading` are set, on success and failure. `OmnibarResultsModel.scheduleSearch` passes `{ [weak self] in self?.landHighlight() }`, where `private func landHighlight()` is `highlight.land(count: search.hits.count, isDisabled: { _ in false })`; and when `search.isBelowMinimumQuery` after the call, it calls `highlight.clear()`. `OmnibarResultsModel.dismiss()` calls `highlight.clear()` | The first hit is highlighted when results arrive (AC-2.1), and a short query or a dismissal leaves no stale highlight. A per-call closure keeps the omnibar's state off the shared model | A stored callback property on `CatalogSearchModel` — because one caller wants it, per search. An `.onChange(of: hits)` in the view — because it cannot be tested without a window |
| D-4 | One activation path. `OmnibarResultsModel.handleKey(_ key: KeyEquivalent, command: Bool, activate: (CatalogSearchHit) -> Void) -> KeyPress.Result`: when `!isPresented`, every key is `.ignored` and nothing changes (AC-2.6). When presented: a key for which `PVPopupListHighlight.isMovementKey` is true calls `highlight.move(key, command: command, count: search.hits.count, isDisabled: { _ in false })` and is `.handled`; `.return` and keypad Enter (`KeyEquivalent("\u{3}")`) call `activate(hit)` with `highlightedHit` when there is one, and are `.handled` either way (AC-2.4: today's monitor swallowed Return); `.escape` calls `closePanel()` and is `.handled`; any other key is `.ignored`. The modifier calls `results.handleKey(press.key, command: press.modifiers.contains(.command), activate: onActivate)`, and a click calls `onActivate(hit)`: both go through `OmnibarResultsModel.activate(_:navigation:)`. `OmnibarResultsModel` imports SwiftUI for `KeyEquivalent` and `KeyPress.Result` | Return is the field's (the same rule, reworded 2026-11-21): "Return opens and clears; Escape keeps the query". A model method tests every key without a window, as `PVComboBoxMatch.returnAction` does | A key handler on the list — because the kit list takes no keys (S16-51 D-5). A `navigation` parameter on `handleKey` beside `onActivate` — because that is two ways to open a hit |
| D-5 | The search's line lives on the shared search model. `enum CatalogSearchLine: Equatable` *(new, in `CatalogSearchModel.swift`)* with `case rows, searching, noMatches, failed(message: String)`, and `var line: CatalogSearchLine` on `CatalogSearchModel`: `if let message = searchError, !isLoading { return .failed(message: message) }`; then `PVPopupListLineKind.of(rowCount: hits.count, isLoading: isLoading)`: `.rows` → `.rows`, `.loading` → `.searching`, `.empty` → `.noMatches`. `showsLoadingState`, `showsEmptyState` and `showsErrorState` go. `PromoteRecordSearch.emptyLine(_:)` starts with `if case .failed(let message) = search.line { return message }`, then its hint and no-match lines as today. The omnibar's card switches on `results.search.line`. The kit's `PVPopupListLineKind` keeps three cases: a failure is the caller's empty line, as the kit README's "The combo box subset" says | One tested order for every surface that searches the catalog ("a failure is never drawn as no match"; hits on screen stay while a search runs). The loading line's decision joins the kit, as the working rule says | An omnibar-only line enum — because Promote's picker already decides the same order over the same model (review M-2). A `.failed` case in the kit enum — because the combo box's failure is its caller's empty line today |
| D-6 | One width rule. `PVPopupListPlacement.fittedWidth(preferred: CGFloat, hangsFrom edgeX: CGFloat, alignment: HorizontalEdge, columnWidth: CGFloat, minimum: CGFloat = 0, inset: CGFloat = PVSpacing.space6) -> CGFloat` *(new)*: `columnWidth <= 0` → `preferred`; the room is `edgeX - inset` for `.trailing` (the list hangs leftward from `edgeX`) and `columnWidth - edgeX - inset` for `.leading`; the result is `max(minimum, min(preferred, room))`. `HistoryJumpMenuModel.fittedPanelWidth(contentWidth:anchorMinX:)` becomes `PVPopupListPlacement.fittedWidth(preferred: panelWidth, hangsFrom: anchorMinX, alignment: .leading, columnWidth: contentWidth)` and keeps its tests. `OmnibarResultsModel.panelWidth` becomes `static let listWidth: CGFloat = 640` (OR-3). The omnibar's width is `PVPopupListPlacement.fittedWidth(preferred: OmnibarResultsModel.listWidth, hangsFrom: results.fieldFrame.maxX, alignment: .trailing, columnWidth: contentWidth, minimum: results.fieldFrame.width)`. `fieldFrame` is the `PVInput`'s frame in the content column's space, written by `.onGeometryChange(for: CGRect.self) { $0.frame(in: .named(WorkspaceContent.coordinateSpace)) } action: { results.fieldFrame = $0 }`. `HistoryJumpMenuModel.contentCoordinateSpace` moves to `WorkspaceContent.coordinateSpace` *(new name, same string)* and its readers follow. `OmnibarFieldAnchorKey`, the field's `GeometryReader` background and the toolbar's `.onPreferenceChange(OmnibarFieldAnchorKey.self)` go | The map's structural-debt line asks for the cap "as the history menu's is". One function keyed by the alignment D-7 adds, so S16-53 and a third popup call it instead of copying it (review M-1). The space is the content column's, not the history menu's (review M-8). At the 700 pt window the field ends at about 404 pt and the list is about 388 pt | A second, mirrored formula on `OmnibarResultsModel` — because the two would drift |
| D-7 | The kit list takes an alignment. `.pvPopupList` gains `alignment: HorizontalEdge = .leading`, passed to `PVPopupListWindow` and stored on its `Coordinator`. `PVPopupListPlacement.anchorFrame(_ anchor: CGRect, width: CGFloat?, alignment: HorizontalEdge) -> CGRect` *(new)*: nil `width` returns `anchor`; `.leading` keeps `minX` and sets the width; `.trailing` sets `minX = anchor.maxX - width` and the width. `Coordinator.frame()` replaces `if let width { anchorOnScreen.size.width = width }` with `anchorOnScreen = PVPopupListPlacement.anchorFrame(anchorOnScreen, width: width, alignment: alignment)`; `popupFrame` then clamps to the screen as today. The coordinator's `shownHeight` and `shownCount` become one `private var framed: Framed?` with `private struct Framed: Equatable { let height: CGFloat; let count: Int; let width: CGFloat? }`: `applyPresentation()` shows when it is nil and re-frames when the current value differs; `hide()` sets it nil. The omnibar passes `width:` (D-6), `alignment: .trailing`, `maxHeight: OmnibarResultsModel.maxListHeight` (`420`, *(new)* constant), `contentHeight: measuredHeight + PVSpacing.space2 * 2`, `optionCount: results.search.hits.count`, `isMeasured: rowsMeasured` | OR-3: the list's trailing edge is the field's, and a resize changes the width without changing the rows. One compared value instead of three fields (review M-10) | A caller-built `anchorRect` — because the caller has no `NSView`. A list as wide as the field — because the rows need about 640 pt (OR-3, as the agreed board draws it) |
| D-8 | `PVOmnibarHitRow` moves with `git mv` to `macos/App/DesignSystem/Components/SearchHitRow/PVSearchHitRow.swift` *(new)* and is renamed `PVSearchHitRow`; its init, content, padding (9 pt at the sides, 7 pt top and bottom) and preview are unchanged apart from the name. `CatalogSearchHitRow` constructs `PVSearchHitRow` | A Component is content-agnostic and named for what it is; the row draws in the omnibar and in Promote's picker, as `PVTitleText` took a generic name when it moved (S13-34; review M-4). Its padding stays, so Promote's picker does not change (review M-3; brief OR-2) | Keeping the omnibar's name in the kit — because a second surface draws it. Moving the padding to the omnibar's list — because Promote's picker would change, a view this PR has no brief for |
| D-9 | The card: `PVPopupListCard(rowIDs: hits.map(\.id), activeID: results.highlightedHit?.id, verticalPadding: PVSpacing.space2) { rowsStack }` with `.accessibilityElement(children: .contain)`, `.accessibilityLabel(Text(L10n.Workspace.omnibarResultsAccessibilityLabel))`, `.accessibilityIdentifier("workspace.toolbar.omnibar.results")`. `rowsStack` is a `VStack(spacing: 0)` switching on `results.search.line`: `.rows` draws each hit as `PVPopupListRow(isActive: index == results.highlight.index, onHighlight: { results.hover(at: index) }, onCommit: { onActivate(hit) }) { CatalogSearchHitRow(hit: hit, projectDir: projectDir) }` with `.id(hit.id)` and `.accessibilityIdentifier("workspace.toolbar.omnibar.hit.\(hit.id)")`; `.searching` draws `PVPopupListSearchingLine()` with identifier `workspace.toolbar.omnibar.loading`; `.noMatches` draws `PVPopupListLine { VStack(alignment: .leading, spacing: PVSpacing.space3) { title; hint } }` with today's two `Text`s and fonts and the title's `.fixedSize(horizontal: false, vertical: true)`, identifier `workspace.toolbar.omnibar.noMatches`; `.failed(let message)` draws `PVPopupListLine { PVCallout(tone: .danger, message: message) }`, identifier `workspace.toolbar.omnibar.error` | OR-1, OR-2, OR-6 – OR-8. The identifiers stay | `PVComboBox` with `onQueryChange` — because its field is a picker that restores a committed label; the omnibar's field is a command field (rule) |
| D-10 | The kit line pieces, in `PVPopupList.swift`: `enum PVPopupListLineKind: Equatable { case rows, loading, empty; static func of(rowCount: Int, isLoading: Bool) -> PVPopupListLineKind }` *(new)*, the body of today's `listLine`; `struct PVPopupListSearchingLine: View { var gutter: CGFloat = 0 }` *(new)*, today's combo box searching line (`PVPopupListLine(gutter:)` holding an `HStack(spacing: PVSpacing.space3)` of `ProgressView().controlSize(.small)` and `Text(L10n.DesignSystem.popupListSearching)` in `PVFont.body(size: PVTypeScale.bodySmall)`, `PVColor.textMuted`, with `.accessibilityElement(children: .combine)`). `PVComboBoxMatch.ListLine` and `listLine` go; `PVComboBox.rowsStack` switches on `PVPopupListLineKind.of(rowCount:isLoading:)` and draws `PVPopupListSearchingLine(gutter: Self.checkGutter)` with its `identifier("loading")`. `L10n.DesignSystem.comboBoxSearching` is renamed `popupListSearching` (key `designSystem.popupList.searching`, comment "Kit popup list line while a remote search runs and no results are in yet") | The list owns its lines, and the loading line's decision joins the kit with its second caller (rule). S16-51 Out sent the rename here "if the omnibar draws the same line"; both strings read the same English text | Two strings for one line |
| D-11 | The measuring copy, in `PVPopupList.swift`: `struct PVPopupListMeasure<Rows: View>: View` *(new)* with `let isActive: Bool`, `var width: CGFloat? = nil`, `let onHeight: (CGFloat) -> Void`, `@ViewBuilder let rows: Rows`. Its body is `PVComboBox.measuringRows`'s: the rows with `.frame(width: width)` when `width` is set, `.fixedSize(horizontal: false, vertical: true)`, `.hidden()`, `.allowsHitTesting(false)`, `.accessibilityHidden(true)`, and a `GeometryReader` background whose `.onChange(of: proxy.size.height, initial: true)` calls `onHeight(height)` when `isActive` and `height > 0`. `PVComboBox.measuringRows` becomes `PVPopupListMeasure(isActive: isOpen, onHeight: { measuredRowsHeight = $0; rowsMeasured = true }) { rowsStack }`. The omnibar measures at its fitted width (D-6) into `@State measuredHeight: CGFloat` and `@State rowsMeasured: Bool` on the modifier, reset to `0` / `false` by `.onChange(of: results.isPresented)` when it turns false | Hit rows differ in height, so the window needs a measured height before it shows; the no-match and failure lines wrap at the list's width, wider than the field. Two callers; the caller keeps the height (kit README "Sizing is the caller's job") | A second copy of `measuringRows` in the omnibar. A fixed row height — because rows with and without a match line differ |
| D-12 | Presenting: `.pvPopupList(isPresented: Binding(get: { results.isPresented }, set: { if !$0 { results.closePanel() } }), …)`. A close from the presenter (a click outside, an app switch) is `closePanel()`: the query stays. `historyButton`'s `omnibarResults.closePanel()` stays | AC-3.1 – AC-3.3: the presenter's rules with `keysStayInField` and `staysOpenOnFieldClick`, which `.pvPopupList` always passes (S16-51 D-4) | `dismiss()` on a click outside — because today a click away keeps the query |
| D-13 | `L10n.Workspace.omnibarSearchFailed` and `workspace.omnibar.searchFailed` go: `searchError` is never nil on a failure (`L10n.Errors.message(for:)` falls back to `L10n.Errors.unknown`), and D-5 builds `.failed` only from it | No orphan string (review M-5) | Keeping it as a fallback — because nothing can reach it |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

Searched for: `selectedIndex`, `moveSelection`, `selectedHit`, `showsLoadingState`, `showsEmptyState`, `showsErrorState`, `listLine`, `comboBoxSearching`, `omnibarSearching`, `omnibarSearchFailed`, `measuringRows`, `fittedPanelWidth`, `contentCoordinateSpace`, `onGeometryChange`, `OmnibarFieldAnchorKey`, `PVOmnibarHitRow`, `CatalogSearchHitRow`, `PVMenuRowButtonStyle(`, `PVFloatingMenuSelection.moveIndex(` across `macos/App` and `macos/ProvenenciaTests`.

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `PVPopupListLineKind` *(new)* | type | `PVComboBoxMatch.ListLine` / `listLine` | It is that type, moved into the kit for its second caller (D-10) |
| `PVPopupListSearchingLine` *(new)* | component | the searching line inside `PVComboBox.rowsStack` | It is that view, moved (D-10) |
| `PVPopupListMeasure` *(new)* | component | `PVComboBox.measuringRows` | It is that view, moved, with a `width` (D-11) |
| `PVPopupListPlacement.anchorFrame` *(new)* | func | the `if let width` line in `Coordinator.frame()` | That line plus the trailing case, made pure (D-7) |
| `PVPopupListPlacement.fittedWidth` *(new)* | func | `HistoryJumpMenuModel.fittedPanelWidth` | That rule, keyed by alignment; the history menu calls it (D-6) |
| `.pvPopupList(alignment:)` *(new parameter)* | param | `.pvPopupList(width:)` | A real difference of one popup, as `width` and `anchorRect` are |
| `CatalogSearchLine`, `CatalogSearchModel.line` *(new)* | type, property | `showsLoadingState`, `showsEmptyState`, `showsErrorState`; `PromoteRecordSearch.emptyLine` | Replaces the three with one ordered value both surfaces read (D-5) |
| `OmnibarResultsModel.handleKey`, `hover(at:)`, `highlightedHit`, `highlight`, `listWidth`, `maxListHeight` *(new)* | func, property | `CatalogSearchModel.moveSelection`, `selectedHit`, `selectedIndex`; `OmnibarResultsHost.armDismissMonitor`; `panelWidth`; the panel's `frame(maxHeight: 420)` | They move here per the working rule, onto `PVPopupListHighlight` (D-2, D-4); the constants are renamed or named |
| `CatalogSearchModel.scheduleSearch(onResults:)` *(new parameter)* | param | `LatestCall.start(apply:)` | The search's own completion, exposed for the caller that lands a highlight (D-3) |
| `WorkspaceContent.coordinateSpace` *(renamed)* | constant | `HistoryJumpMenuModel.contentCoordinateSpace` | The same string on its owner (D-6) |
| `PVSearchHitRow` *(renamed)* | component | `PVOmnibarHitRow` | The same row under a kit name (D-8) |
| `L10n.DesignSystem.popupListSearching` *(renamed)* | key | `comboBoxSearching`, `omnibarSearching` | One key for the one line (D-10) |

**Builds on.** `.pvPopupList` and `.pvPopup` (S16-50, S16-51); `PVPopupListHighlight` and `PVListKeyboard.moveIndex`; `PVPopupListCard`, `PVPopupListRow`, `PVPopupListLine`; `PVPopupListPlacement`; the folder move of `PVTitleText`.
**Deletes.** `OmnibarResultsHost.armDismissMonitor`, `removeDismissMonitor`, `dismissMonitor`; `OmnibarResultsPanel` (its `loadingState`, `errorState`, `emptyState`); `OmnibarFieldAnchorKey`, the field's `GeometryReader` background and the toolbar's `.onPreferenceChange(OmnibarFieldAnchorKey.self)`; `WorkspaceContent`'s `OmnibarResultsHost` overlay; `OmnibarResultsModel.panelWidth`; `CatalogSearchModel.selectedIndex`, `moveSelection(delta:)`, `selectedHit()`, `showsLoadingState`, `showsEmptyState`, `showsErrorState`; `PVComboBoxMatch.ListLine` and `listLine`; `PVComboBox.measuringRows`'s body; `fittedPanelWidth`'s own formula; `HistoryJumpMenuModel.contentCoordinateSpace`; `PVPopupListWindow.Coordinator.shownHeight` and `shownCount`; `L10n.Workspace.omnibarSearching`, `omnibarSearchFailed` and their keys; the `designSystem.comboBox.searching` key (renamed); `CatalogSearchModelTests.moveSelectionClampsAndSelectedHit`; the three `listLine` tests in `PVComboBoxTests` (moved); the name `PVOmnibarHitRow` and the `Recipes/OmnibarHitRow/` folder. `PVFloatingMenuSelection.moveIndex(from:delta:count:)` loses this caller and keeps the history menu's (S16-53).
**Next adds.** S16-53 moves the history menu onto `.pvPopup` and keeps calling `PVPopupListPlacement.fittedWidth`; a third popup list wider than its field passes `width:` and `alignment:`; a third remote list uses `PVPopupListLineKind`, `PVPopupListSearchingLine` and, over a catalog search, `CatalogSearchModel.line`.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| Home, End, ⌘↑/⌘↓, Page Up/Down reach the highlight | `OmnibarResultsModel.handleKey` | On 0 hits `highlight.move` leaves −1 (`PVListKeyboard.moveIndex` returns −1 for `count` 0); `highlightedHit` is nil; Return does nothing (AC-2.4, T-8) |
| A click in the field while the list is open passes through the presenter | `PVPopupDecision.decide` with `staysOpenOnFieldClick` | The list stays open; the caret moves (AC-3.2) |
| The list as its own window over the sidebar or off the window | `PVPopupListPlacement.popupFrame` | Clamped to the screen's visible frame; the width rule keeps it in the content column (AC-1.2, AC-1.3) |
| The window resized while the list is open | `PVPopupListWindow.Coordinator.applyPresentation` | Re-frames on the new width (D-7); the follow observer moves it with the field |
| Promote's picker reads `CatalogSearchModel.line` | `PromoteRecordSearch.emptyLine` | A failure still shows its message first; the hint and no-match lines as today (T-12, §10 step 9) |
| The history menu's width through `fittedWidth` | `HistoryJumpMenuHost` | `HistoryJumpMenuModelTests` pass unchanged |

### Scale

At the map's Scale: a search returns at most `DefaultHitLimit` (50, `core/search/search.go`) hits. The list builds 50 `CatalogSearchHitRow`s twice (the card and the measuring copy), as `PVComboBox` builds its rows twice; thumbnails come through `ThumbnailCache.shared`, so the second copy does not read a file again. No write, no catalog read and no cache key change (map: "no new read").

### Edges

- **Assumptions.** `PVPopupListHighlight` assumes the field calls `land` when the rows change; D-3 calls it after every applied search (T-4). `highlightedHit` assumes `index < hits.count`; `current(count:)` checks it (T-6, T-8). `PVPopupListWindow.Coordinator` assumed the width only changes with the rows; D-7 compares the width too. `fittedWidth` assumes `edgeX` is in the column's space, where x = 0 is the column's left edge (T-13).
- **Neighbors.** A query of exactly 2 characters searches and presents; 1 does not and clears the highlight (T-11). Hits on screen with a new search running: `.rows` (T-12). A search that fails after hits were shown: `hits = []`, `.failed` (T-12). Escape, then typing: `scheduleSearch` clears `userDismissed` and the list returns (unchanged). Escape, then ↓: `.ignored` (T-6). The history menu's widths: unchanged (`HistoryJumpMenuModelTests`).
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
| Card and scroller | `PVPopupListCard` | same | D-9 |
| Row shell | `PVPopupListRow` | same | D-9 |
| Searching line | `PVPopupListSearchingLine` *(new)* | same | D-10 |
| No-match and failure lines | `PVPopupListLine` + `Text` / `PVCallout` | same; `PVCallout` | D-9 |
| Measuring copy | `PVPopupListMeasure` *(new)* | same | D-11 |
| Width rule | `PVPopupListPlacement.fittedWidth` *(new)* | same | D-6 |
| Hit row | `PVSearchHitRow` | `macos/App/DesignSystem/Components/SearchHitRow/PVSearchHitRow.swift` *(new)* | D-8 |
| Hit content | `CatalogSearchHitRow` | `macos/App/Features/Catalog/Search/CatalogSearchHitRow.swift` | Constructs `PVSearchHitRow` |
| Host | `OmnibarResultsHost` (`ViewModifier`) | `macos/App/Features/Workspace/OmnibarResultsHost.swift` | D-1 |
| Models | `OmnibarResultsModel`, `CatalogSearchModel` | `macos/App/Features/Workspace/OmnibarResultsModel.swift`, `macos/App/Features/Catalog/Search/CatalogSearchModel.swift` | D-2 – D-6 |

States: searching with no hits → the searching line; hits with a search running → the hits; no hits → the no-match line; failure → the danger Callout with the mapped message; more than 420 pt of rows → the card scrolls. Accessibility: the card is a container labelled `L10n.Workspace.omnibarResultsAccessibilityLabel`; each row speaks `CatalogSearchHitRow`'s label and takes VoiceOver's default action (`PVPopupListRow`); the searching line is one element. The field keeps keyboard focus throughout.

### Strings

L10n: `L10n.DesignSystem.comboBoxSearching` renamed `L10n.DesignSystem.popupListSearching` (key `designSystem.comboBox.searching` → `designSystem.popupList.searching`, English text unchanged). Removed: `L10n.Workspace.omnibarSearching` (`workspace.omnibar.searching`), `L10n.Workspace.omnibarSearchFailed` (`workspace.omnibar.searchFailed`). Unchanged: `omnibarNoMatchesTitle`, `omnibarNoMatchesHint`, `omnibarResultsAccessibilityLabel`. No action changes what it covers.

## 7. Steps

Every `xcodebuild` check and every in-app check runs on macOS only. On a host without Xcode, run each step's `rg` lines and `python3 scripts/check-guidance-names.py`, and report the macOS checks as not run.

**STEP-1 — The kit list owns its line decision and its searching line**
Files: `macos/App/DesignSystem/Components/PopupList/PVPopupList.swift`, `macos/App/DesignSystem/Components/ComboBox/PVComboBox.swift`, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `macos/ProvenenciaTests/PVComboBoxTests.swift`, `macos/ProvenenciaTests/PVPopupListTests.swift`. Skill: `add-ui-component`, `add-localized-string`, `add-swift-test`.
Do: D-10. Add `PVPopupListLineKind` and `PVPopupListSearchingLine`; switch `PVComboBox.rowsStack` onto them; delete `PVComboBoxMatch.ListLine` and `listLine`; rename the string and its catalog key. In the `PVComboBox` type doc's "Remote results" paragraph, `PVComboBoxMatch.listLine` becomes `PVPopupListLineKind`. Move the three `listLine` tests into `PVPopupListTests` as T-1.
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/PVPopupListTests -only-testing:ProvenenciaTests/PVComboBoxTests` passes; `rg -n -e comboBoxSearching -e 'PVComboBoxMatch.ListLine' -e 'enum ListLine' -e 'listLine(' macos` finds nothing.

**STEP-2 — The kit measures a list's rows**
Files: `PVPopupList.swift`, `PVComboBox.swift`. Skill: `add-ui-component`.
Do: D-11. Add `PVPopupListMeasure`; `PVComboBox.measuringRows` uses it. Move the explanation in `measuringRows`'s doc comment to `PVPopupListMeasure`'s. In `PVPopupList.swift`, `PVPopupListWindow.contentHeight`'s doc ("see `PVComboBox.measuringRows`") becomes "see `PVPopupListMeasure`".
Check: the build passes; `PVComboBoxTests` passes; the Source type picker on a Source type page opens at its rows' height, as before (macOS).

**STEP-3 — A popup list can hang from its field's trailing edge, inside the column**
Files: `PVPopupList.swift`, `macos/App/Features/Workspace/WorkspaceToolbar.swift` (`HistoryJumpMenuModel.fittedPanelWidth` only), `macos/ProvenenciaTests/PVPopupListTests.swift`. Skill: `add-ui-component`, `add-swift-test`.
Do: D-7's kit half (`alignment:`, `anchorFrame`, `Framed`) and D-6's `fittedWidth`, with `fittedPanelWidth` calling it. In `PVPopupList.swift`, the `.pvPopupList` doc names its three callers (`PVComboBox`, `PVTextArea`'s completion, the omnibar's results) and `alignment`; `Coordinator.widened(to:)`'s doc says the content is widened to the popup's width (the field's, or `width`); `PVPopupListCard`'s doc says "every caller of `.pvPopupList`" instead of "both callers". Add T-2, T-3 and T-13.
Check: `-only-testing:ProvenenciaTests/PVPopupListPlacementTests -only-testing:ProvenenciaTests/HistoryJumpMenuModelTests` passes; the citation format editor's `{` completion still opens at the caret (macOS).

**STEP-4 — One line for what a catalog search shows**
Files: `macos/App/Features/Catalog/Search/CatalogSearchModel.swift`, `macos/App/Features/Promote/PromoteView.swift` (`PromoteRecordSearch.emptyLine` only), `macos/App/Features/Workspace/OmnibarResultsHost.swift`, `macos/ProvenenciaTests/CatalogSearchTests.swift`, `macos/ProvenenciaTests/OmnibarResultsModelTests.swift`. Skill: `add-swift-test`.
Do: D-5. Add `CatalogSearchLine` and `line`; delete the three `shows…State` properties; change `PromoteRecordSearch.emptyLine`'s first line; in today's `OmnibarResultsPanel`, replace the `if` chain on `shows…State` with a `switch results.search.line` drawing today's three states (this panel is deleted in STEP-5). Delete `emptyStateRequiresCompletedSearchWithoutError` (T-12 replaces it); rewrite `loadingPresentsBeforeHitsArrive` and `searchFailureSurfacesMappedErrorNotEmpty` on `search.line`.
Check: `-only-testing:ProvenenciaTests/CatalogSearchModelTests -only-testing:ProvenenciaTests/OmnibarResultsModelTests` passes; `rg -n -e showsLoadingState -e showsEmptyState -e showsErrorState macos` finds nothing.

**STEP-5 — The omnibar draws the kit popup list and holds its own highlight**
Files: `macos/App/Features/Workspace/OmnibarResultsModel.swift`, `macos/App/Features/Workspace/OmnibarResultsHost.swift`, `macos/App/Features/Workspace/WorkspaceToolbar.swift`, `macos/App/Features/Workspace/WorkspaceContent.swift`, `macos/App/Features/Catalog/Search/CatalogSearchModel.swift`, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `macos/ProvenenciaTests/OmnibarResultsModelTests.swift`, `macos/ProvenenciaTests/CatalogSearchTests.swift`. Skill: `add-ui-component`, `add-localized-string`, `add-swift-test`.
Do, in this order: (a) the models: D-2, D-3, D-4, `listWidth`, `maxListHeight`; delete `selectedIndex`, `moveSelection(delta:)`, `selectedHit()` and `moveSelectionClampsAndSelectedHit`; add T-4 – T-11. (b) The view: D-1, D-6 (the frame read and the coordinate space move), D-7 (the omnibar's call), D-9, D-11 (the omnibar's measuring), D-12; delete `OmnibarResultsPanel`, the monitor and `OmnibarFieldAnchorKey`; remove the overlay from `WorkspaceContent` and change its "Hosted here" comment to name only the jump menu. (c) D-13 and `omnibarSearching`: delete both strings and their catalog entries. Update `OmnibarResultsModel`'s doc comment to "The toolbar omnibar's results: the highlight, the keys and the width around a shared `CatalogSearchModel`".
Check: after (a), `-only-testing:ProvenenciaTests/OmnibarResultsModelTests -only-testing:ProvenenciaTests/CatalogSearchModelTests` passes. After (b), before (c): in the app (macOS), type `ilmin` in the omnibar and press ↓, End, Home, Page Down, ⌘↑ and Return; each moves the highlight or opens the hit, and the caret does not move (§10 step 2). If a key moves the caret instead, stop (§11). After (c): the build passes with no Swift warning; the AC-4.1, AC-4.2 and AC-4.3 `rg` lines find nothing; in the app, §10 steps 1 – 8.

**STEP-6 — The hit row joins the kit's components**
Files: `macos/App/DesignSystem/Recipes/OmnibarHitRow/PVOmnibarHitRow.swift` → `macos/App/DesignSystem/Components/SearchHitRow/PVSearchHitRow.swift` *(new)*, `macos/App/Features/Catalog/Search/CatalogSearchHitRow.swift`. Skill: `add-ui-component`.
Do: D-8 with `git mv`, then rename the type and its doc's first line ("The kit's search hit row: one layout for every hit kind"). No `project.pbxproj` edit: `App/DesignSystem` is a synchronized folder (kit README "Xcode project registration").
Check: the build passes; `rg -n PVOmnibarHitRow macos` finds nothing.

**STEP-7 — The kit's docs, skills and ideas say where the list and the row live**
Files: `macos/App/DesignSystem/README.md`, `docs/design-system-layers.md`, `.agents/skills/add-searchable-kind/SKILL.md`, `docs/ideas/kit-layering.md`. Skill: —.
Do: README: the Popup row's `.pvPopupList` sentence names its three callers, `alignment:`, `PVPopupListPlacement.fittedWidth`, `PVPopupListLineKind`, `PVPopupListSearchingLine` and `PVPopupListMeasure`; the ComboBox row says the searching line and the measuring copy are the kit list's; the OmnibarHitRow row leaves the Recipes table and a SearchHitRow row joins the Components table: `Components/SearchHitRow/PVSearchHitRow.swift` (a catalog search hit's row: lead, title, kind badge, secondary line, ref, match line; drawn by the omnibar's popup list and Promote's record picker through `CatalogSearchHitRow`); "The combo box subset" names `PVPopupListLineKind` where it names the searching line; "Sizing is the caller's job" says the caller holds the height and lays the rows out through `PVPopupListMeasure`. `design-system-layers.md`: the folder tree's `OmnibarHitRow/` and `PVOmnibarHitRow.swift` lines under `Recipes/` become `PersonCard/` and `PVPersonCard.swift`. `add-searchable-kind`: the Swift callers line adds that the omnibar draws hits on the kit popup list (`OmnibarResultsHost`), holds its highlight in `OmnibarResultsModel`, and that both surfaces read `CatalogSearchModel.line`. `ideas/kit-layering.md`: two sections, "Promote's record picker pads its hit rows twice" (the combo box's row padding and `PVSearchHitRow`'s own; S16-52 review M-3) and "A remote combo box highlights nothing when its results arrive" (`PVComboBox.resetActiveRow` lands before remote options exist; the omnibar lands on arrival through `scheduleSearch(onResults:)`; S16-52 review M-9).
Check: the AC-4.4 `rg` line finds nothing; `python3 scripts/check-guidance-names.py` passes.

**STEP-8 — Docs**
Files: `docs/deployment-plan/spike-16/completed.md`, `docs/deployment-plan/spike-16/deployment-plan.md` (map row), this plan (status, Landed note), `docs/deployment-plan/spike-16/design/S16-D9-omnibar-results.md` → `design/archive/`, `docs/deployment-plan/spike-16/design/README.md`; `VERSION`, `core/version.go`, `MARKETING_VERSION`.
Do: per the Definition of done; patch bump.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-52-omnibar-popup-list.md` reports no errors; `scripts/check-pr.sh` prints `check-pr: PASS` (macOS).

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `macos/ProvenenciaTests/PVPopupListTests.swift` `searchingLineShowsOnlyWhileLoadingWithNothingIn`, `rowsAlreadyInStayWhileANewSearchRuns`, `noRowsAndNoSearchShowsTheEmptyLine` *(moved from `PVComboBoxTests`)* | `PVPopupListLineKind.of(rowCount: 0, isLoading: true)` → `.loading`; `(3, true)` → `.rows`; `(0, false)` → `.empty`; `(2, false)` → `.rows` | D-10, AC-1.4 |
| T-2 | Swift | `PVPopupListTests.swift` `PVPopupListPlacementTests.anchorFrameAlignsTheWidthToAnEdge` *(new)* | anchor `(600, 100, 300, 24)`: width nil → the anchor; width 640 `.leading` → `(600, 100, 640, 24)`; width 640 `.trailing` → `(260, 100, 640, 24)` | D-7, AC-1.1 |
| T-3 | Swift | same, `trailingListStaysOnScreen` *(new)* | anchor `(100, 500, 300, 24)`, width 640, `.trailing` → `anchorFrame` minX −240; `popupFrame(anchor:contentHeight: 200, visibleFrame: (0, 0, 1440, 900))` → minX 0, width 640, maxY 496 | D-7, AC-1.3 |
| T-4 | Swift | `macos/ProvenenciaTests/OmnibarResultsModelTests.swift` `resultsLandOnTheFirstHit` *(new)* | FakeStore seeds hits a, b, c; query `abc`; `scheduleSearch`; `await waitForSearch` → `highlightedHit?.id == "a"`; ↓↓ then a second search with the same seed → `highlightedHit?.id == "a"` | D-3, AC-2.1 |
| T-5 | Swift | same, `movementKeysMoveTheHighlight` *(new)* | three hits landed on a: ↓ → b, End → c, Home → a, Page Down → c, ⌘↑ → a, ↑ → a; each returns `.handled` | D-4, AC-2.2 |
| T-6 | Swift | same, `keysPassWhileTheListIsClosed` *(new)* | three hits landed, `closePanel()`: ↓, `.return`, `.escape` → `.ignored`; `highlight.index` unchanged; the `activate` closure is not called | D-4, AC-2.6 |
| T-7 | Swift | same, `returnOpensTheHighlightedHitAndClears` *(new)* | three hits with locations, `activate: { model.activate($0, navigation: navigation) }`: ↓ then `.return` → `.handled`, navigation at b's location, `search.query` empty, `!isPresented`; the same with `KeyEquivalent("\u{3}")` | D-4, AC-2.3 |
| T-8 | Swift | same, `returnWithNoHitIsTakenAndOpensNothing` *(new)* | query `il`, `search.isLoading = true`, no hits: `.return` → `.handled`, the `activate` closure is not called, query `il` | D-4, AC-2.4 |
| T-9 | Swift | same, `escapeClosesAndKeepsTheQuery` *(new)* | hits landed, `.escape` → `.handled`, `!isPresented`, query unchanged, `userDismissed` | D-4, AC-2.5 |
| T-10 | Swift | same, `hoverMovesTheHighlight` *(new)* | three hits: `hover(at: 2)` → c; `hover(at: 9)` → still c | D-2, AC-2.7 |
| T-11 | Swift | same, `dismissAndAShortQueryClearTheHighlight` *(new)* | hits landed, `dismiss()` → `highlight.index == -1`, `highlightedHit == nil`; landed again, query `I`, `scheduleSearch` → `highlight.index == -1` | D-3 |
| T-12 | Swift | `macos/ProvenenciaTests/CatalogSearchTests.swift` `CatalogSearchModelTests.lineFollowsTheSearch` *(new)*; `OmnibarResultsModelTests` `loadingPresentsBeforeHitsArrive` and `searchFailureSurfacesMappedErrorNotEmpty` *(rewritten on `search.line`)* | query `il`, loading, no hits → `.searching`; loading with one hit → `.rows`; searched, not loading, no hits, no error → `.noMatches`; `searchError = "boom"`, not loading → `.failed(message: "boom")`; FakeStore `searchCatalogError` `catalog.closed` → `.failed(message: L10n.Errors.message(code: "catalog.closed"))` | D-5, AC-1.4 |
| T-13 | Swift | `PVPopupListTests.swift` `PVPopupListPlacementTests.fittedWidthStaysInTheColumn` *(new)* | `fittedWidth(preferred: 640, hangsFrom:alignment: .trailing, columnWidth:minimum:)`: column 0 → 640; edge 1070, column 1102, minimum 420 → 640; edge 404, column 436, minimum 200 → 388; edge 210, column 436, minimum 200 → 200; `.leading` with `preferred: 600`, edge 60, column 436, minimum 0 → 360 | D-6, AC-1.2 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `PVComboBoxTests`, `PVPopupListTests`, `PVTextAreaCompletionTests`, `HistoryJumpMenuModelTests`, `OmnibarResultsModelTests`, `CatalogSearchModelTests`, and the Promote tests that use `CatalogSearchModel`.

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

Use a project with at least 20 Persons named Smith, a Source titled "Ilminster parish register", and a note on another Source containing "Ilminster". Every step runs on macOS.

1. Window at 1366 pt. Type `ilmin` in the omnibar. The list opens 4 pt under the field, its right edge on the field's right edge, 640 pt wide, with the combo box's card (compare the Source type picker's list) and full-width row highlights; the first hit is highlighted (AC-1.1, AC-2.1).
2. Press ↓, End, Home, Page Down, ⌘↑, ↑; the highlight moves as AC-2.2 says and the caret stays in the field. Hover the third hit; it highlights. Press Return: its place opens and the field empties (AC-2.3, AC-2.7). With a keypad, keypad Enter does the same.
3. Type `smith`: twenty hits, the list is 420 pt tall and scrolls; End keeps the last row in view (AC-1.5).
4. Type `ilmin`, click in the field to move the caret: the list stays open. Click the page below: it closes on the release and the field keeps `ilmin` (AC-3.1, AC-3.2). Press ↓ and Return: nothing opens (AC-2.6). Type a letter: the list returns.
5. With the list open, ⌘-Tab to another app: it closes (AC-3.3). Reopen and click a hit: it opens (AC-3.4). Reopen and press Escape: it closes and the query stays (AC-2.5).
6. Type `il` and watch the searching line before the hits arrive; type `zzzz`: the no-match line; type 120 characters of `z`: the title wraps inside the card (AC-1.4).
7. Resize the window to its 700 pt minimum with `ilmin` typed: the list narrows and its left edge stays 16 pt inside the content column, never over the sidebar (AC-1.2). Drag the window so the field is near the screen's left edge: the list stays on screen (AC-1.3).
8. Open the history menu (hold Back) with the results open: the results close; the history menu is as wide as before. A combo box (Source type picker) and the citation format editor's `{` completion open, move and close as before.
9. On a Promote page, open a row's record search and type a name: the picker's rows, its searching line and its no-match line look as before.
10. Run the `rg` lines of AC-4.1, AC-4.2, AC-4.3 and AC-4.4 from §2: each finds nothing.
11. VoiceOver: with `ilmin` typed, VO lands in "Search results" and reads a row's title, kind and ref; VO-Space on a row opens it.

The failure line (AC-1.4) is checked by T-12; the app has no switch to fail a search on demand.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| `onKeyPress` on `PVInput` does not receive ↑/↓ because the field editor takes them first | `PVComboBox` attaches `onKeyPress` the same way around its `TextField` and receives them; STEP-5 checks the keys in the app before it deletes anything else |
| The measuring copy behind a 200 pt field reports a different height from the 640 pt card | D-11 measures at the fitted width, the card's width |
| The window shows at a stale width after a resize | D-7 re-frames on a width change; §10 step 7 |
| Rows lose `WorkspaceSession` in the popup window | `PVPopupListWindow.updateNSView` passes the host's environment into the window (S16-51); `CatalogSearchHitRow` reads it there |

**Stop and report if:**

- The agreed board shows a value (width, gap, inset, copy) that a Decision here contradicts.
- `onKeyPress` on the omnibar's `PVInput` does not receive ↑, ↓, Home, End, Page Up or Page Down with the field focused (STEP-5's in-app check shows the caret moving instead).
- `PVTextAreaCompletionTests`, `PVComboBoxTests`, `PVPopupListTests` or `HistoryJumpMenuModelTests` need an expected value changed to pass.
- Keypad Enter does not reach `onKeyPress` as `KeyEquivalent("\u{3}")` or as `.return`.
- A Current state row is no longer true at the base (S16-53 landing first changes `WorkspaceToolbar.swift`).

## 12. Open questions

None.

## 13. PR

**Title:** S16-52 — The omnibar's results use the kit popup list
**Body:** objective in one sentence; what shipped against US-1 – US-4; AC evidence; the `rg` output of AC-4.1, AC-4.2, AC-4.3 and AC-4.4; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-52-omnibar-popup-list.md`.

## Landed

- `main` had moved from the Planned commit to `496ffa9c2`; no **Current state** row changed under `macos/`.
- `PromoteModelTests` read `showsErrorState` (not named in STEP-4); it reads `search.line`.
- `WorkspaceContent` lost its `@Environment(WorkspaceNavigation.self)`, whose only use was the removed overlay, and `WorkspaceContent.coordinateSpace` is `nonisolated` so the field's geometry closure can read it.
- One test beyond §8: `CatalogSearchModelTests.aFailedSearchIsTheMappedMessageNotNoMatches` (T-12's FakeStore case at the model level).
- STEP-2 and STEP-3 are one commit.
- The in-app passes (STEP-5's key check, STEP-2 and STEP-3's macOS checks, and §10) were not run by the implementer; they are owed before merge. Whether `onKeyPress` on the omnibar's `PVInput` receives ↑/↓/Home/End/Page and keypad Enter is therefore unverified (§11 stop condition).
