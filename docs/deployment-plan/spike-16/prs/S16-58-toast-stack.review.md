# Review — S16-58 Toasts stack in one list per window

**Verdict:** — (round 1 running)
**Rounds:** 1. **Reviewers:** maintainability (Opus), executability (Sonnet). Plan and brief S16-D10 reviewed together.

## To user

- **How the agreed board reaches the implementer.** Recommendation: the board's artifact link and turn on the **Board** line, as S16-D8 and S16-D9 did.

## Writer's own calls

- D-1, D-2: the list is a kit type (`PVToastList`) owned by `WorkspaceSession` (`session.toasts`), so S16-59's models reach it through the session they already hold.
- D-3: expiry lives in the list with an injected sleep (the `PVClipboardCopyState` pattern), not in each card's view.
- D-5: `PVSheetChrome` clears the list for every sheet, not only the likeness viewer.
- D-8 / TS-2: the stack sits over the content pane under the toolbar, not over the whole window as the window's toasts do today.
- D-10: `CatalogCounts.lastRefreshError` and `clearRefreshError()` go; the model adds the toast itself (QCK-1).
- Edges: a page toast already in the stack when the likeness viewer opens stays until its timer.

## Round 1

Pending.
