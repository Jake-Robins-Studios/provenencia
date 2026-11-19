# Review — S16-46 Back returns to the row you opened in a section

**Verdict:** round 1: Fits with changes — Not ready (two blockers each); all answered Fixed. Round 2 pending.
**Rounds:** 1 so far. **Reviewers:** maintainability (opus), executability (sonnet)

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
