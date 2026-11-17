# Keyboard reorder

**Status:** pulled into Spike 15 as S15-51 (2026-11-17). Parked 2026-11-12 from the S15-09 review (UX-4, a nit).

## Problem

A metadata board's saved rows can only be reordered by dragging the handle. A researcher who uses the keyboard or VoiceOver cannot change their order at all. Every board has this problem: the Source's Metadata section, the Artifact sheet in edit and add mode (S15-34, S15-10) and the Evidence graph form (S15-11). They all draw `MetadataBoardView`.

## Shape

- **Fix it in the kit, not the board.** `PVReorderableList` (`macos/App/DesignSystem/Components/ReorderableList/`) is the only reorderable list in the app, and `MetadataBoardView` is its only caller. Today it supplies `List` + `onMove` and nothing else. Once it supports keyboard and VoiceOver moves, every board gets them.
- **One move path.** A keyboard or VoiceOver move calls the list's existing `onMove(IndexSet, Int)`, the same closure a drag calls. `MetadataBoardModel.moveSaved(from:to:)` already does the optimistic move, the write and the revert on a live board, and the local move on a draft board (`MetadataDraftHost.reorder`). The board model gets no second move path.
- **The handle takes focus** (user, 2026-11-17). `PVReorderHandle` becomes focusable, so Tab reaches each saved row's grip. The row's value keeps its click-to-edit behaviour unchanged. The handle is drawn by the feature row (`MetadataBoardView.savedRow`), so the list hands each row its move actions (for example through the environment), and the handle reads them. The feature passes nothing extra.
- **Keyboard: ⌥↑ / ⌥↓** (user, 2026-11-17). This is the same shortcut as the name editor's part rows (`NameValueEditorForm`), so the app has one reorder shortcut. With the handle focused, ⌥↑ / ⌥↓ moves that row by one. Nothing happens at the ends. Focus stays on the moved row's handle. The shortcut is bound to the focused handle, not window-wide, so it cannot fire on another row or another board. Back and Forward (⌘[ / ⌘]) do not clash.
- **VoiceOver.** Each saved row carries the accessibility actions "Move up" and "Move down", which are hidden at the ends. A move announces the row's new position, named by its label ("Provider, 1 of 3"), through `AccessibilityAnnouncement`. The caller gives the list each row's label for that announcement. The strings are `L10n.DesignSystem` strings, because the kit owns them.
- **No highlight** (user, 2026-11-17). The confirmation is that focus stays on the moved row, plus the announcement. Nothing on the board looks different apart from the platform's focus ring on a focused handle, so the PR needs no brief.
- **One write per move, in order.** Each keypress is one reorder write on a live board. A board holds at most a few dozen saved rows, so a write per move is cheap. Moves must not race: today a second `moveSaved` can start while the first write is in flight, and the first reply (or its revert) then undoes the second move on screen. A move waits for the previous reorder write on that board. Held arrows are not batched into one write.

## Stays later

- The name editor's part rows keep their own move buttons and strings. Moving them onto the kit list is not this work.
- Reordering suggestions (only saved rows reorder, as with dragging today).
