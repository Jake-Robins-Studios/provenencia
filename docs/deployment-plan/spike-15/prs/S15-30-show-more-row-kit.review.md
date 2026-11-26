# Review — S15-30 The paged fold moves to the kit

**Verdict:** Fits with changes — Ready with changes
**Rounds:** 1. **Reviewers:** maintainability (opus), executability (sonnet)

Round 2 not run: the one blocker class (M-1, M-2) was answered Fixed and To user, and the fixes add no new mechanism beyond what round 1 asked for.

## To user
- **M-2: should a pointer click on the Timeline's Show more stop scrolling, with the Timeline using the kit's one reveal route?** Recommended yes. **Answered (user, 2026-11-26): yes, the same rule.** Written as D-7, AC-2.4, AC-3.1; the map's S15-30 scope entry now says so.

## Writer's own calls
- Names `PagedFold`, `PagedFoldState`, `PVShowMorePress`, `PVShowMoreReveal`, `pvScrollsShowMoreReveals()`.
- Patch bump: the pointer click no longer scrolling is a fix.
- The map's first wording (a `ScrollViewReader` in the row) changed to a provider above the row, because the row leaves the tree when it reveals the last page.
- `PVShowMoreReveal` compares always equal (D-4).

## Round 1

### M-1 · blocker · The kit row's promised scroll behavior has no test
The plan said scroll and focus were manual only; `add-ui-component` asks for a test of each promised behavior, and `HostedWindow.swift` and `PVScrollMemoryHostedTests` show hosted scroll tests exist.
**Answer:** Fixed — D-3 adds the pure rule `PVShowMorePress` (T-3); T-4 is a hosted test that the provider scrolls after its caller leaves the tree; the false §8 line is gone.

### M-2 · blocker · The Timeline keeps a second Show more scroll path
`PersonTimelineList.unfold(_:)` sets `pendingReveal` on every press, pointer included.
**Answer:** To user, answered yes — D-7: the Timeline sets its own `PVShowMoreReveal`; `unfold(_:)` goes; the Out row's reason is corrected.

### M-3 · major · Model the environment action on `PVSheetClose`
**Answer:** Fixed — D-4: non-optional, no-op default, `@MainActor callAsFunction`, `Equatable` like `PVScrollMemory`.

### M-4 · minor · The fold rule could live in the row's folder
**Answer:** Declined — the map's working rule "The provenance table folds a page at a time" puts the rule and state in `Platform/`, and `Features/` content types (`PersonTimelineContent`, `PersonSourcesContent`, `PersonFamilyContent`, `ReconciledValueRowModel`) use them as pure rules with no view.

### M-5 · minor · STEP-6 rewrites a map sentence that already says this
**Answer:** Fixed — the map edit is done in the planning commit; the plan no longer asks for it.

### M-6 · nit · L10n member name
**Answer:** Fixed — `showMoreRowLabel(_:)`, key `designSystem.showMoreRow.label` (D-9).

### X-1 · blocker · Swift checks need macOS
**Answer:** Fixed — **Host** line in the header with the exact `xcodebuild test` command; Steps name `-only-testing` suites; the implementer runs §10.

### X-2 · major · README row arrives after the guidance check
**Answer:** Fixed — the README row moved into STEP-2.

### X-3 · major · File counts wrong
**Answer:** Fixed — §4 and STEP-1 use the `rg -l "ConclusionFold" macos` list.

### X-4 · major · Preview underspecified
**Answer:** Fixed — D-10 gives the fold, focus type, stop, ids and sizes.

### X-5 · major · Modifier only a signature
**Answer:** Fixed — D-4 and D-5 give the type and the modifier body.

### X-6 · minor · Conversions and plumbing
**Answer:** Fixed — `.map(AnyHashable.init)` (D-2), D-6 builds both values from the claim id, `unfold(_:)` deletion is definite.

### X-7 · minor · Placement of new entries
**Answer:** Fixed — D-9 and STEP-2 name where the member, key and README row go.

### X-8 · nit · Header and DoD mismatches
**Answer:** Fixed — Depends on lists S16-07 only, as the map does; the DoD rules line says "(none)".

## Cost
Plan: 3,722 words at round 1, 4,090 at the verdict (check-plan-docs info line).

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| 1 | maintainability | opus | 153k |
| 1 | executability | sonnet | 124k |
