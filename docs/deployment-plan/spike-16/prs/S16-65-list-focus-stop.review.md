# Review — S16-65 One kit focus stop for a list of rows

**Verdict:** Fits with changes — Ready with changes
**Rounds:** 1 (no blocker, so no round 2). **Reviewers:** maintainability (opus), executability (sonnet)

## To user
None.

## Writer's own calls
- D-1: a modifier (`.pvListFocusStop`) in the List folder, not a generic row-list container: the Sources list keeps its own stack and pinned caption band.
- D-2, D-3, D-4: the caller owns `focusIndex` and the `FocusState`; the modifier takes a row count and an id-by-index closure (no id array per render at the 16,000-person Scale) and reports activation by index.
- D-5 (from X-3): the scroll row keeps today's rule (nil when the index is out of range), so the PR has no visible change.
- D-8 (from M-4): focus stays an index, as today; S16-66 decides whether the Sources list's focus follows its Source.
- Version bump none, as S16-59 and S16-64.

## Round 1

### M-1 · major · The stored index and the ringed row can differ; every reader clamps
Suggested the modifier write the clamp back to the binding on a count change, or a shared "is focused row" helper.
**Answer:** Declined the write-back: the scroll follows the written row, so a shrinking list would jump to its end (the same visible change as X-3), in a PR that promises none. The shared rule is `PVListKeyboard.clampedIndex`, called once per reader; `currentIndex` goes (M-2), so `PVList` and S16-66 each write one comparison against the kit rule. D-5, D-7 say so.

### M-2 · major · Deletes drops `currentIndex`, the Steps keep it
**Answer:** Fixed — D-7 and STEP-3 delete `currentIndex`; the row style reads `clampedIndex` inline; the DoD sweep expects no `currentIndex` hit.

### M-3 · major · `PVTable` writes its own movement keys; the plan's reason was wrong
**Answer:** Fixed — the Codebase fit row's reason is corrected; the Out row's reason is the table's selection, type-select and Escape; STEP-4's README wording names `PVTable` as the exception. The move onto `PVListKeyboard.moveIndex` is logged in `docs/ideas/kit-layering.md` "The table writes its own movement keys" (the Out row's home).

### M-4 · minor · Edges silent on re-sorts and inserts above the focused row
**Answer:** Fixed — D-8 and the Neighbors line; S16-66's scope entry hands the Sources list's choice to its plan.

### X-1 · major · The Anti-patterns section has no bullets
**Answer:** Fixed — STEP-4 adds a BAD/GOOD `swift` block, with its text and place.

### X-2 · major · The preview cannot declare focus state in a `#Preview` closure
**Answer:** Fixed — STEP-2 names `PVListFocusStopPreview`, its state, rows, modifier call and frame; no list chrome.

### X-3 · major · A clamped scroll row is a visible change
**Answer:** Fixed — option (a): D-5 keeps today's scroll row; AC-2.1 says so.

### X-4 · minor · The `currentIndex` sweep was ambiguous
**Answer:** Fixed with M-2: it prints nothing.

### X-5 · minor · `.activate` and the row click not spelled out
**Answer:** Fixed — D-5 gives each case and its result; STEP-3 keeps the click.

### X-6 · minor · Housekeeping wording
**Answer:** Fixed — STEP-4 gives the `completed.md`, map and plan status forms and the README placement; STEP-3 gives the doc comment's sentence. The `FocusState` binding check stays with §10 and the Stop condition: it needs a Mac.
