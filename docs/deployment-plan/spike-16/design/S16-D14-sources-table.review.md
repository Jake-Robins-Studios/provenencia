# Review — S16-D14 The Sources list as a native table

**Verdict:** Fits with changes — Ready with changes
**Rounds:** 1. **Reviewers:** maintainability (Opus), executability (Sonnet)

## To user
- None open. Status filter matches the badge (user, 2026-11-24). TB-7 and TB-W1 are picked on the board.

## Writer's own calls
- A click on a Source with no triangle also closes the open Source.
- A Source's badge shows open as well as closed, so it does not come and go.
- A graph with no Artifact counts as Not started in its Source's badge.
- The header word is "Added", the sort menu's word, for the created date.
- ⌥-click goes, since only one Source opens.
- Added comes from the engine's create record (M-2), not the id.

## Round 1

| ID | Severity | Title | Answer |
| --- | --- | --- | --- |
| M-1 | blocker | The table re-implements `PVListBody`'s behaviors in a feature file | Fixed — inventory "Native list behavior"; map Ships extracts one kit modifier |
| M-2 | blocker | Date added decodes a UUIDv7 in Swift | Fixed — § 2 Date added; map Ships: Go sends `created_at` |
| M-3 | major | Sort grows a flat enum of column and direction pairs | Fixed — map Ships: a column and a direction |
| M-4 | major | `PVLastUpdated` reused for Added says "Last updated" | Fixed — TB-5 hover words; inventory splits Updated and Added |
| M-5 | major | Deletes incomplete | Fixed — map Deletes lists them; the plan settles `PVListBody` and the spoken labels |
| M-6 | major | Docs list incomplete; old rule and bar 41 not amended | Fixed — map Docs and skills, the rule and bar 41 |
| M-7 | minor | One owner for the one-open rule | Fixed — map Ships, inventory |
| M-8 | minor | Header `Text` and `pvMicroCaps` share one definition | Fixed — inventory Header text |
| X-1 | blocker | Lint: New with one call site | Fixed — "Table rows and columns", Rethink of `SourcesListView`'s rows; no new primitive |
| X-2 | blocker | TB-7 and TB-W1 frames undefined; TB-2 and TB-3 contradict (b) | Fixed — T1a, T1b name four frames; TB-2, TB-3 say what (b) changes |
| X-3 | blocker | Widths: no minimums, 800 pt, what the title counts | Fixed — TB-7 minimum / ideal / maximum; the table scrolls sideways at 800 |
| X-4 | major | Badge and date choices | Fixed — § 2.1 Selection (no new Badge); TB-5 cites `TimestampFormat` |
| X-5 | major | Header text form unnamed | Fixed with M-8; the name is the plan's |
| X-6 | major | Updated and Added form | Fixed with M-4 |
| X-7 | major | Sort mapping at the model | Fixed with M-3, in the map entry the plan starts from |
| X-8 | minor | Triangle's and columns' homes | Fixed — map Deletes; the plan names homes |
| X-9 | minor | "Taking the selection"; Wide widths | Fixed — § 2; TB-W1 uses the maximums |
