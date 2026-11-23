# Review — S16-65 Page keys belong to the page's scroll view

**Verdict:** Fits with changes — Ready with changes (re-plan, 2 rounds; no blocker open)
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet)

## To user
- M-7 (round 2): which pane takes the page keys on Metadata and Properties. Writer's recommendation: the pane under the pointer, else the detail pane. **User (2026-11-23): the pane under the pointer.** D-4 now says so.
- Earlier: (The user settled the shape on 2026-11-22: page keys on every page's scroll view, with nothing focused too; the bounce and the scroll memory in their own PR, S16-67.)

## Writer's own calls
- D-2: the keys reach the page through a responder after the window, not an event monitor, so a focused text field, table, popup or menu keeps them (spike evidence, plan §4).
- D-4: one page per window, the last registered; the sidebar and the Citation composer's columns get no page keys in this PR.
- Out: Space does not page; a focused `PVTable` keeps moving its selection by the page keys.
- M-2 is fixed in this PR rather than moved to S16-67: the reset to the top joins `PVPageScrollView` now, so S16-67 starts from one scroll path.

## Re-plan round 1

### M-1 · blocker · The table pages are left on a bare `ScrollView`
`PVTable.rowList` is the main scrolling column of the Source types, Metadata and Properties lists; S16-67 names the Source types list.
**Answer:** Fixed — `PVTable.rowList` is a seventh page site (Scope, §4 Table row, D-7, AC-1.7, AC-3.1, §10 steps 2 and 6); D-4 says which of a table and its detail pane pages; the Out row now covers only a focused table's own keys.

### M-2 · blocker · A second way to scroll a page to its top
`PVPageColumns.scroll`'s marker id and `PVScrollRowIntoView`'s `restartsAt:whenChanged:` beside D-5's edge scroll.
**Answer:** Fixed — D-1 gives `PVPageScrollView` `startsAtTopWhen:` through `PVPageScrollHandle` and the same edge scroll; D-7 and STEP-3 delete the marker, `PVPageColumnsMetrics.topAnchor` and `restartTop` / `restartKey`; AC-1.8, AC-3.3, §10 step 7, a Stop condition.

### M-3 · major · `pageKeys: Bool = true` is a parameter no caller needs
**Answer:** Fixed — D-6: `action` ignores the four page keys outright; STEP-1 moves the existing page-key tests onto `moveIndex`; T-2 rewritten; §4 caller list corrected.

### M-4 · minor · The README List row keeps false claims
**Answer:** Fixed — STEP-5 gives the row's whole keyboard text.

### M-5 · minor · The name does not follow `PVFittedScrollView`
**Answer:** Fixed — `PVPageScrollView` throughout the plan and the map; folder and file stay `PageScroll/PVPageScroll.swift`, as `FittedScroll/PVFittedScroll.swift`.

### M-6 · nit · `top, end` mixes two pairs
**Answer:** Fixed — `top, bottom`.

### X-1 · blocker · STEP-5 rewrites a `completed.md` paragraph that is not there
**Answer:** Fixed — STEP-5 adds a new section under the intro line, above `## S16-59`, with its heading and Landed form.

### X-2 · major · The probe bookkeeping is under-specified
**Answer:** Fixed — D-4 names `[WeakProbe]`, register / unregister, compaction, the probe's weak responder, `viewWillMove(toWindow:)` for a window change; D-2 names who holds the responder.

### X-3 · major · `PVListFocusStopPreview` is a bare `ScrollView`
**Answer:** Fixed — STEP-3 swaps it to `PVPageScrollView`.

### X-4 · minor · §4's `action` callers are wrong
**Answer:** Fixed — §4 Movement rule row.

### X-5 · minor · STEP-3's Properties check names `inspector`
**Answer:** Fixed — `PropertiesView.swift` joins AC-3.1's `rg` (it has one `ScrollView`, `inspectorCard`).

### X-6 · minor · Doc replacements are not exact
**Answer:** Fixed — STEP-4 replaces `PVList.swift` doc lines 17–20 with a fenced block (the `ScrollView` line becomes `PVPageScrollView`); STEP-5 gives the anti-pattern block fenced.

### X-7 · minor · Commit split not mapped to steps
**Answer:** Fixed — §7 Commits lists three.

## Re-plan round 2

Round-1 answers: M-1, M-2, M-3 Resolved (maintainability); X-1 – X-7 confirmed (executability).

### X-8 · blocker · Nothing owns the responder: `nextResponder` does not retain it
**Answer:** Fixed — D-2: `install` makes the window own the responder through `objc_setAssociatedObject`; it stays in the chain for the window's life.

### X-9 · major · The responder has no window to compare against
**Answer:** Fixed — D-2 sets `weak var window` in `install`; the sketch lists it.

### X-10 · minor · Same-pass registration order is only assumed
**Answer:** Fixed with M-7.

### M-7 · blocker · On two-pane places, which pane gets the page keys depends on mount order
**Answer:** To user → answered (pane under the pointer). Fixed — D-4's five-step choice (scrollable candidates, pointer, non-side-list, last registered, none); `PVTable` passes `isSideList: true`; Edges, AC-1.7, §10 step 2, STEP-3.

### Outside the lens · AC-3.1's `rg` matches `PVPageScrollView {`
**Answer:** Fixed — the pattern is `(^|[^A-Za-z])ScrollView \{`.

Logged: the anti-pattern block keeps today's BAD line beside the new one (STEP-5, fixed); `startsAtTopWhen:`'s doc names `startsAtTopWhenRowsChange:` as the list's first-row reset (STEP-2, fixed).

## First plan (superseded 2026-11-22)

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
