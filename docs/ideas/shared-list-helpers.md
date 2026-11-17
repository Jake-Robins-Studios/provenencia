# Shared list helpers

**Status:** idea only — not roadmapped. "Go reads every Swift mirror" and "Fake store keys" closed by Spike 12 S12-35 (2026-10-28). Small duplication found while planning S10-41 (the Sources list filters). Each item is a cleanup, not a feature. "In-list text matching" (closed by S11-08: `TextMatch`) and "Primary Subject kinds" (S11-23) moved into Spike 11. "Properties empty search state" , "One catalog querier" and "Trimmed empty-string binder" went to Spike 16 (S16-48, S16-49), the popup dismissal, the popup list and the history menu's rows to its S16-50 – S16-53, and the tiny-PNG test writer to S16-54 (2026-11-17).

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
