# Shared list helpers

**Status:** idea only — not roadmapped. "Go reads every Swift mirror" and "Fake store keys" closed by Spike 12 S12-35 (2026-10-28). Small duplication found while planning S10-41 (the Sources list filters). Each item is a cleanup, not a feature. "In-list text matching" (closed by S11-08: `TextMatch`) and "Primary Subject kinds" (S11-23) moved into Spike 11. "Properties empty search state" , "One catalog querier" and "Trimmed empty-string binder" went to Spike 16 (S16-48, S16-49), the popup dismissal, the popup list and the history menu's rows to its S16-50 – S16-53, the tiny-PNG test writer to S16-54, type-select on a disabled row into S16-50, and the section counts to S16-55 (2026-11-17). "History menu row labels" moved to its own idea file, [`history-menu-labels.md`](history-menu-labels.md) (2026-11-17).

## A failed sidebar recount is silent

`WorkspaceView` reads `lastRefreshError` only in its first `.task`, so a sidebar recount that fails after a write says nothing. Observe it with `.onChange` and show it where the counts are.

## Return adds a pick the combo box no longer shows

S15-12 review CON-1 / UX-2 (2026-11-15), deferred by the user. On a Source type page, pick Folio in a suggestion list's picker, then clear the field or type text that matches nothing, and press Return: Folio is added and the toast confirms it, though the field no longer shows it. `PVComboBox` sets `selection` only in `commit`; typing changes `query` and leaves the pick in place. Return with no highlighted row returns `.ignored`, so it reaches the list's `.onSubmit` (`SourceTypeSuggestionList.submitPick`), and `canAssign(at:)` still sees the old pick. The plus button takes the same stale pick, but its tooltip names it.

Two fixes, each past S15-12's plan:
- **Kit:** `PVComboBox`'s Return does nothing while the field holds edited text with no highlighted row, including a field cleared by hand. Every combo box gets it: such a Return no longer reaches an enclosing form or a sheet's default button. The pick is kept, so clicking away still restores its label, and the two-step Return (pick, then add) stays.
- **One-step Return:** Return on a highlighted row picks and adds at once through `onCommit` (`via: .return`), and the list drops its `.onSubmit`. No kit change, but AC-2.6's two Returns become one.
