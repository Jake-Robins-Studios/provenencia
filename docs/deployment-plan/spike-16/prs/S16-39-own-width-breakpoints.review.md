# Review — S16-39 One container measures its own width and tells its content which layout fits

**Verdict:** Fits with changes — Ready with changes
**Rounds:** 2 (round 1 had two blockers, both Fixed; round 2 found no new blocker). **Reviewers:** maintainability (Opus), executability (Sonnet)

## To user
- M-1 (answered 2026-11-16): rebuild `pvMeasuresWidthClass` on the container. The user chose "Rebuild it on the container" → D-10; the map's Not this PR line now keeps only the class, where it is measured and its 1600pt value.

## Writer's own calls
- D-1: a closure container (`PVWidthBreakpoints`), not the environment modifier the map first named; the map row and scope entry were reworded with the plan.
- D-7: the Evidence graph header's icon-only switch stays (a fit to content, the `ViewThatFits` shape the map rules out).
- D-8: the Citation composer's 1400pt split moves onto the container (the map's survey clause).
- D-3: before the first measure, no breakpoint is met (the Sources list started all-met before).

## Round 1

### M-1 · blocker · `pvMeasuresWidthClass` stays as a second copy of the same measuring job
**Answer:** To user → answered: rebuild it. Fixed — D-10, AC-2.6, T-8, STEP-1, Scope In row; `init(paneWidth:)` goes; AC-2.5 no longer allow-lists `PVWidthClass.swift`; the map's Not this PR line changed.

### M-2 · major · § 9 teaches the container for "a split", which the kit decides with a `Layout`
**Answer:** Fixed — STEP-6's § 9 paragraph drops "a split", lists content choices only, and states the boundary (placing the same subviews beside or stacked is `PVPageColumnsLayout` / `PVColumnSplit` `.whenNarrow` or a page `Layout`); D-7's `ConclusionPinnedSideColumn` and `PVPageColumns` cells name the `Layout`'s choice.

### M-3 · major · D-8 leaves `docs/ideas/wide-layout.md` false and the next add unnamed
**Answer:** Fixed — STEP-6 rewrites the Citation composer row and the Narrow panes bullet; Next adds names the Person page Sources rows; the DoD sweeps `docs/ideas/` and checks `composeSplit|1400pt`.

### M-4 · minor · D-4's fixed-breakpoints rule is an unwritten contract on `PVTable`
**Answer:** Fixed — D-4: the container asserts in debug when its breakpoint set changes; STEP-2 adds "fixed for the table's life" to `minTableWidth`'s doc.

### M-5 · minor · `PVBreakpointWidth` and `PVWidthBreakpoints` are near-anagrams
**Answer:** Fixed — the reading is `PVBreakpointsMet` with `Set` storage (`breakpoints`, `met`); `isAtLeast` is `met.contains` after an assert; closure parameters are `met`; the sweep includes the old name.

### X-1 · blocker · No Swift check can run in a Linux session; no fallback
**Answer:** Fixed — Stop condition: with no macOS machine with Xcode, stop before STEP-1. The implementer (ship-pr's) runs where `scripts/check-pr.sh` runs Xcode.

### X-2 · major · `PVBreakpointsMet` storage and `isAtLeast` rule left open
**Answer:** Fixed — D-2 names the stored fields, the rule, equality, the empty list and the container's `@State` seed.

### X-3 · major · Sources list: which modifiers go inside the container
**Answer:** Fixed — D-6: the `ScrollView`'s anchor and accessibility modifiers stay on it, inside the closure.

### X-4 · major · `PVTable` helper signatures; the other two table callers unchecked
**Answer:** Fixed — D-5 gives `header(_:)`, `rowList(_:)`, `rowView(_:shown:)`, `breakpoints(_:)`; Current state adds `VocabularyListPane.table` and `PropertiesView.propertyTable` (both fill); manual check step 5.

### X-5 · minor · Composer panel branch: modifier placement; `threeUpFrom` access
**Answer:** Fixed — D-8: the `VStack`'s frame, accessibility and divider overlay move onto the `GeometryReader` in order; `threeUpFrom` is internal with a doc comment.

### X-6 · minor · AC-2.5 cites "§ 6's survey table"
**Answer:** Fixed — it cites D-7.

### X-7 · minor · Where the `add-ui-component` example goes; `textCap`
**Answer:** Fixed — appended after the last Anti-patterns block; STEP-4 says `textCap` and `minimumTextWidth` stay.

### X-8 · minor · The Sources list's first frame changes from all-met to none-met
**Answer:** Fixed — manual check step 2 reopens at both sizes and looks for a wrong first frame; the Stop condition on T-3 stands.

## Round 2

Both reviewers checked every round-1 answer against the code and found it holds; no new blocker.

### M2-1 · minor · The Regular/Wide rule stays hand-copied in four previews once `init(paneWidth:)` goes
**Answer:** Fixed — D-10 keeps `init(paneWidth:)` as a one-line wrapper over the reading and moves the four previews onto it; STEP-1's check `rg`s the copied expression; T-8 runs the existing tests unchanged.

### M2-2 / X-9 · major · `shownColumns` and `stacksPeople` still label the reading `width`
**Answer:** Fixed — D-5 and STEP-4 use `met`.

### M2-3 / X-13 · minor · The map's Ships and Check lines still name the pane measure as separate
**Answer:** Fixed — the scope entry says `pvMeasuresWidthClass` is rebuilt on the container, and the Check's `rg` allows only the container and D-7's geometry.

### M2-4 · nit · `add-design-brief`'s Paste-block copy of rule 3 never got S15-49's `minTableWidth` sentence
**Answer:** Logged, not this PR — older than this plan; STEP-6 changes only the code name in the engineers' copy, which is not in the Paste block, so the gap does not widen.

### X-10 · minor · How T-3 and T-4 record what the content was built for
**Answer:** Fixed — T-3 names a `BreakpointsProbe` with `.onAppear` and `.onChange(of: met)` writing into a `@MainActor` box, copying `WidthClassProbe`; the host is the bare container.

### X-11 · minor · The container's `#Preview` is unspecified
**Answer:** Fixed — two previews at 800 and 1300pt with the exact `Text`.

### X-12 · minor · The `add-ui-component` boundary comment is not worded
**Answer:** Fixed — STEP-6 gives the exact comment line and puts it inside the GOOD code block.

## Refresh — 2026-11-16 (after the round-0 stop)

The implementer stopped on the base check: S15-13 (#863) had replaced the composer's `threeUp = width >= 1400` with `CitationComposerColumnLayout(widthClass)`, so §4's Composer row, D-8, STEP-5, AC-1.4, T-4's composer wording and manual check step 4 described code that was gone. User, 2026-11-16: drop the composer. The plan now moves three views; D-8 records the composer as out, D-7 names its `GeometryReader` as geometry, STEP-5 is a no-op check, and the map row and scope entry say the same. Every other §4 row was rechecked at `eb7ee08e9` (no change in the touched files). The change only removes scope and adds no Decision, so no reviewer round was run; `check-plan-docs.py` reports no errors.
