# Shared list helpers

**Status:** idea only — not roadmapped. "Go reads every Swift mirror" and "Fake store keys" closed by Spike 12 S12-35 (2026-10-28). Small duplication found while planning S10-41 (the Sources list filters). Each item is a cleanup, not a feature. "In-list text matching" (closed by S11-08: `TextMatch`) and "Primary Subject kinds" (S11-23) moved into Spike 11. "Properties empty search state" , "One catalog querier" and "Trimmed empty-string binder" went to Spike 16 (S16-48, S16-49; 2026-11-17).

## One popup dismissal

Sheets share one dismissal now (`.pvSheet`: Escape, a click outside, the discard question; S11-33). Menus and popups each dismiss their own way: `pvContextMenu`, `HistoryJumpMenuHost`, `OmnibarResultsHost` and `PVComboBox` each carry their own Escape and outside-click handling. One kit presenter for a popup, as `.pvSheet` is for a sheet, would give them the same rules; move each onto it when its host is next touched.

## One popup list under the combo box and the omnibar

`PVComboBox` and the omnibar results (`OmnibarResultsHost`) are the same popup list built twice. Both have a field that drives a popup of rows, ↑/↓ that stop at the ends, Return on the highlighted row, a highlight shared by the pointer and the keyboard, closing on Escape or a click outside, and the card behind the rows. Each draws them its own way:
- **Keys.** The omnibar watches raw key codes through an `NSEvent` monitor. The combo box uses `onKeyPress` and also has Home/End, ⌘↑/⌘↓ and Page Up/Down.
- **Highlight movement.** The omnibar moves through `PVFloatingMenuSelection.moveIndex`. The combo box moves through `PVComboBoxMatch.move`, which also skips disabled rows.
- **Popup.** The combo box opens its own window, sized to the field and placed against the screen edges by `PVComboBoxPlacement`. The omnibar draws a 640 pt overlay in the content column.
- **Card.** The two cards use different border and corner tokens.
- **Scrolling** to the highlighted row is already shared (`.pvScrollsRowIntoView`).

The fields are not the same, so the omnibar cannot simply become a combo box. The combo box picks a value and keeps it: `@Binding selection`, the field shows the picked label, and only typed text filters. Its Escape has two steps, and a click outside also takes focus off the field. The omnibar has no picked value: Return opens the record and clears the field, Escape keeps the query, and it has an error state of its own. The shared piece is the layer underneath: a kit popup list that owns the window and its placement, the keys, the highlight, the scrolling, closing, and the loading, empty and error lines. `PVComboBox` would add the picked-value field on top, and the omnibar the command field. It folds in the popup dismissal above.

`CatalogSearchModel.selectedIndex`, `moveSelection` and `selectedHit` are the omnibar's highlight; they move onto `OmnibarResultsModel` with that list, since the combo box keeps its own.

## One tiny-PNG test writer

`writeTinyPNG` is copied in `core/database/sourcecopy/sourcecopy_test.go` and `core/database/sources/sources_test.go`; one shared catalog test fixture would serve both (S12-01 ship log).

## The history menu on the shared rows

The toolbar's Back / Forward history menu builds its own rows and presenter (`HistoryJumpMenuModel`, `PVContextMenuPanel`) instead of `PVActionMenuRows` (S12-17 ship log). Pairs with "One popup dismissal" above.

## History menu row labels

Dogfood 2026-10-29; S14-35 widened the panel to 600pt and left these.

> "The drop-down menu for the navigation bar's back and forward needs to be wider because they're truncating the last part of the breadcrumb and so all the entries look the same."

- **Truncation mode.** Keep the distinguishing suffix of a long leaf with head or middle truncation on the row leaf in `HistoryJumpMenuPanel` (and on the mono ref when it is the unique part).
- **Richer or reordered labels.** The row leaf is `WorkspaceLocationLabels.labels(for:names:)` joined to its section by `L10n.Conclusions.pageSectionLeaf`, at a width from `HistoryJumpMenuModel.fittedPanelWidth`. Build it from the full `WorkspaceToolbar.breadcrumbItems` (Source title before graph name), or leaf-first, and drop the section prefix when the leaf already carries it.
- **Multi-line rows.** Allow two lines for long composer and entity labels, trading vertical space against scan speed.

## Type-select can land on a disabled menu row

S12-17 ship log; dogfood 2026-10-29. Typing a letter in an action menu can highlight a disabled row (`keyboardTitles` keeps disabled titles), and Return on it closes the menu with no action. Seen on Sources list Clear and other `PVActionMenuItem` menus. Type-select and Return should skip or refuse disabled rows the same way pointer activation does.

## Source page section counts differ

S12-11 review M-8; dogfood 2026-10-25. Source page section counts: Notes shows a bare number, Artifacts and Evidence graphs a localized count. One count presentation for every Source page section.

## A failed sidebar recount is silent

`WorkspaceView` reads `lastRefreshError` only in its first `.task`, so a sidebar recount that fails after a write says nothing. Observe it with `.onChange` and show it where the counts are.

## Return adds a pick the combo box no longer shows

S15-12 review CON-1 / UX-2 (2026-11-15), deferred by the user. On a Source type page, pick Folio in a suggestion list's picker, then clear the field or type text that matches nothing, and press Return: Folio is added and the toast confirms it, though the field no longer shows it. `PVComboBox` sets `selection` only in `commit`; typing changes `query` and leaves the pick in place. Return with no highlighted row returns `.ignored`, so it reaches the list's `.onSubmit` (`SourceTypeSuggestionList.submitPick`), and `canAssign(at:)` still sees the old pick. The plus button takes the same stale pick, but its tooltip names it.

Two fixes, each past S15-12's plan:
- **Kit:** `PVComboBox`'s Return does nothing while the field holds edited text with no highlighted row, including a field cleared by hand. Every combo box gets it: such a Return no longer reaches an enclosing form or a sheet's default button. The pick is kept, so clicking away still restores its label, and the two-step Return (pick, then add) stays.
- **One-step Return:** Return on a highlighted row picks and adds at once through `onCommit` (`via: .return`), and the list drops its `.onSubmit`. No kit change, but AC-2.6's two Returns become one.
