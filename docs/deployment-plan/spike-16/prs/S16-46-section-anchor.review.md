# Review — S16-46 Back returns to the row you opened in a section

**Verdict:** Fits with changes — Ready with changes (every blocker of both rounds Fixed)
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet)

## To user
None.

## Writer's own calls
- Event and Place pages are in scope (D-14): the map row names them, and their Details share `ConclusionDetailRowsSection` with Vitals.
- Vitals is in: its field rows' open arrow opens a place, which the map's exception names.
- The Person Gallery and the provenance sheet links stay out: they leave from a sheet.
- An entry keeps its anchor until another open overwrites it (D-2); leaving by Back, the sidebar or the omnibar does not clear it.
- A card or line whose row is folded, or shown with a non-empty fold, resolves to the fold's Show more even if the person or record is gone (§ Edges): no participant ids are kept.
- Timeline restore waits for every item to be measured (D-13).
- The bump is a patch.
- The working rule's "written when leaving" is reworded to "written as a row opens another place" (X-8): the write is on the leave an open causes.
- The Place relationship row moves from `.plain` to `PVFocusRingButtonStyle()` so a restored focus is visible (X-3); nothing draws until it is focused.
- An unfold's reveal scroll now also waits until every Timeline item is measured (D-13), one gate for both.

## Round 1

### M-1 · blocker · The anchor in each content's `Inputs` defeats the session content memo
Every anchored Back would rebuild the section (one memo per key per session); the contents already answer queries from kept ids.
**Answer:** Fixed — D-5: `anchorTarget(for:)` query methods over kept ids; `Inputs` unchanged; § Edges tabulates what each content keeps; § Scale rewritten.

### M-2 · blocker · A hand-written string format inside a `Codable` location
`ConclusionPageSection` already lives in `Features/Workspace` and is stored typed.
**Answer:** Fixed — D-1: `ConclusionSectionAnchor` is a `Codable` struct beside `ConclusionPageSection` with frozen parts, decoded leniently; Sources split into `.sourceTitle` and `.sourceLine`; no parser and no `PersonSourcesFocus` anchor codec; old T-5 and T-9 parsers' tests removed, T-2 covers lenient decode.

### M-3 · major · Each site writes its own "scroll, then claim" closure
**Answer:** Fixed — D-6: the modifier resolves, scrolls and focuses, with `FocusClaim` or `FocusKeeper.hand` when a keeper is passed.

### M-4 · major · Three shapes for "open and record"; a dead Sources closure
**Answer:** Fixed — D-8: one `(WorkspaceLocation, ConclusionSectionAnchor) -> Void` for handed-down `open`; environment leaves call `go(to:from:)`; old shapes listed under Deletes.

### M-5 · minor · `stampSectionAnchor` copies `stampListScrollAnchor`
**Answer:** Fixed — D-4: shared private `stampCurrent(_:_:)`.

### M-6 · minor · What happens to an anchor already used
**Answer:** Fixed — D-2 states "kept until the next open"; T-1 covers leaving by the sidebar.

### X-1 · blocker · STEP-2 uses helpers STEP-3/4 create
**Answer:** Fixed — `moreID` and `participantsMoreID` move into STEP-2.

### X-2 · blocker · Sources open closures contradict; node has no write path
**Answer:** Fixed — with M-4 (D-8); the node writes `.recordLinks` with the graph id.

### X-3 · major · Family hidden-member enumeration undecided
**Answer:** Fixed — § Edges table gives each list kind and its fold; T-6 adds a one-parent child, a hidden unit's child, a hidden parent set's partner and a hidden sibling.

### X-4 · major · Checks a Linux session cannot run; data shapes for manual ACs
**Answer:** Fixed in part — § 8 and § 10 say the fold-sized ACs are proven by T-6 – T-8 and the manual check needs no generated data. The Xcode checks are run on macOS by the implementer, as for every Swift PR (`scripts/check-pr.sh`); not a plan change.

### X-5 · major · New `PersonSourcesFocus` cases in `focusedGraphID`
**Answer:** Fixed — D-11: nil for `.title` and `.more`.

### X-6 · major · Return activation and the focus ring on new stops
**Answer:** Fixed — D-10 adds `pvActivatesOnReturn` to the three new stops; AC-5.2 and STEP-7 check the ring; a Stop condition if it is not drawn.

### X-7 · minor · An entry keeps an old anchor
**Answer:** Fixed — same as M-6.

### X-8 · minor · Map link and STEP-6 file note
**Answer:** Fixed — the map row links the plan in this commit; the STEP-6 test file is its own new file.

### X-9 · minor · Timeline restore timing; `widthStop` and Show more
**Answer:** Fixed — D-13: wait for every item measured; the width case is stated as matching today.

## Round 2

Both reviewers confirmed the round-1 answers hold against the code, except where noted below.

### M-7 · blocker · The Show more row and the sections' scroll pairs overlap S15-30, which is not named
**Answer:** Fixed — D-6: the restore modifier owns its scroll (`pvScrollsRowIntoView` inside it); no section gains a pair; header **Blocks** names the order with S15-30; both maps say whichever lands second rebases and `PVShowMoreRow` keeps the `stop`.

### M-8 / X-1 · blocker · A second Return handler on the Source title (`PVInkLink` already has one)
**Answer:** Fixed — D-10: the title gets `.focused` only; § 4 Sources row corrected.

### M-9 · blocker · A second "scroll once placed" rule in the Timeline
**Answer:** Fixed — D-13: the restore goes through `pendingReveal`; `rebuild()`'s one gate waits for every item measured, for unfold and restore alike.

### M-10 · blocker · The empty-id rule is bypassed by the stamp
**Answer:** Fixed — D-1: `ConclusionSectionAnchor`'s failable init and decode own the rule; `WorkspaceLocation` adds none; T-2 covers an empty id and an empty row.

### X-2 · blocker · The relationship row cannot take `.focused` and Return as described
**Answer:** Fixed — the row takes `focus` and `anchorID` and applies `.id`, `.focused` and Return itself (§ macOS, Codebase fit).

### X-3 · blocker · The focus ring on the `.plain` relationship row was left to a Stop condition
**Answer:** Fixed — decided: `PVFocusRingButtonStyle()` replaces `.plain` (draws nothing until focused); the Stop condition is gone.

### X-4 · major · `Part` lacks `CaseIterable`; `row` and empty-id placement
**Answer:** Fixed — D-1.

### X-5 · major · The restore's anchor source and its "once" rule
**Answer:** Fixed — D-6: it reads `currentLocation.sectionAnchor`; `didRestore` is set on the first attempt where `isReady` is true.

### X-6 · major · D-11 said Back draws no highlight
**Answer:** Fixed — D-11: a restored `.graph` or `.node` highlights its graph as keyboard focus does today; `.title` and `.more` give nil.

### X-7 · major · Small picture tiles do not answer Return
**Answer:** Fixed — D-10 keeps today's keys (Space opens them); the Keyboard sentence says so.

### X-8 · minor · D-2 vs the rule's "written when leaving"
**Answer:** Fixed — the write happens on the leave an open causes; STEP-8 rewords the rule to "written as a row opens another place", and the map row says the same. Listed under Writer's own calls for the user.

### X-9 · minor · Timeline scroll before placement
**Answer:** Fixed — with M-9.

### X-10 · minor · `.id` placements; the Sources scroll modifier move
**Answer:** Fixed — § macOS names each `.id`'s view; the move is dropped (the proxy reaches any `.id` in the page's scroll view).

### Below the bar (noted)
- Show more ids now all read `"more.<…>"` (Family's changed from `"more-…"`).

**Result:** no open blocker after round 2; the round cap is reached, so the round-2 fixes are unreviewed plan text.
