# Review — S16-67 The Persons, Events and Places lists are native lists

**Verdict:** (round 2 pending)
**Rounds:** 1. **Reviewers:** maintainability (Opus), executability (Sonnet)

## To user
- None.

## Writer's own calls
- **No `go(to:)` overload.** The map's scope entry named one to stamp the opened row; the opened row is always the selected row (Return and double-click act on the selection), so the existing stamp on leaving already writes it (D-7). The map entry is updated to match.
- **The Sources header loses 4 pt** under it (`space7` → `space6`) to share `VocabularyHeader`'s metrics, which CL-1 names (D-3).
- **The failure Callout is capped at `PVSpacing.measureForm` (560 pt)** on the three Conclusion pages, not the board's 640 pt, which is no token (D-11). The other four list pages keep an uncapped Callout.
- **A second click on the open list's sidebar item clears the selection** (AC-4.7), because that visit writes a nil anchor to history today, and the selection follows history (M-2).
- **On-selection ink is the system's `alternateSelectedControlTextColor`**, not `PVColor.textInverse`, which is near-black in dark appearance (D-4).
- **Version: minor, 0.35.0**, for the changed interaction on three pages.

## Round 1

### M-1 · blocker · Back-restore by selection is a second anchor mechanism, built in the feature view
`ListScrollAnchorModifier` already resolves, re-resolves on row changes, waits for load and reports; the plan's `ConclusionListSelection.restored` was a third copy of the resolve rule and did not wait for a settled read. Proposed a `ListSelectionAnchorModifier` beside it with a shared resolve rule.
**Answer:** Fixed — D-7 now adds `ListSelectionAnchorModifier` and `ListAnchor.resolved` in `WorkspaceNavigation.swift`; `ListScrollAnchorModifier`'s two copies call it; the restore waits for `handle.isSettled`; `ConclusionListSelection` is gone; T-3 tests `ListAnchor.resolved`; STEP-5.

### M-2 · blocker · The selected row is kept in two places, and a visit to the same list desyncs them
A coalesced sidebar visit writes a nil anchor; the plan's once-only restore would leave the row drawn selected while history held nil.
**Answer:** Fixed — D-7 (2): the modifier re-resolves on every anchor change; Reach row added; AC-4.7, T-4, §10 step 4.

### M-3 · blocker · The focus claim on arrival is hand-rolled beside `FocusClaim`
**Answer:** Fixed — D-6 uses `FocusClaim.claim($isFocused, true)`.

### M-4 · major · The on-selection ink rule is in the wrong home and has four environment reads; `textInverse` is near-black in dark
**Answer:** Fixed — D-4: one `ShapeStyle`, `PVColor.onSelection`, in Tokens, resolving `backgroundProminence`; no view adds an `@Environment`; the ink is `alternateSelectedControlTextColor` (white in both appearances), not `textInverse`; Current state's `PVTitleText` row corrected (only `.ref` sets its own ink in rows); T-1.

### M-5 · major · The failure Callout's placement becomes a fifth copy
**Answer:** Fixed — D-11: `.pvListPageMessage(gutter:maxWidth:)` in the ListPageHeader folder; the four existing sites move onto it with no cap (no visual change); the Conclusion pages pass `measureForm`. STEP-1, STEP-6.

### M-6 · minor · The width-class to page-gutter mapping is computed per page
**Answer:** Fixed — `PVWidthClass.pageGutter` (D-10).

### M-7 · minor · `PVListKeyboard.edgeIndex` only forwards to `moveIndex`
**Answer:** Fixed — D-5 calls `moveIndex` directly; T-2 extends the existing test.

### M-8 · minor · The rename stops halfway
**Answer:** Fixed — D-8 renames `pendingListScrollAnchor`, `normalizedScrollAnchor`, `stampListScrollAnchor` too; the persisted `listScrollAnchor` keeps its name with fixed docs; STEP-5 files and the DoD sweep list them.

### M-9 · minor · The rebuild carries over initializers and knobs with no app caller
**Answer:** Fixed — D-1 keeps one initializer with a required thumbnail; the two `EmptyView` initializers and `optionalThumbnail` are deleted.

### M-10 · minor · The sweep misses the ScrollRowIntoView docs
**Answer:** Fixed — STEP-9 adds the README ScrollRowIntoView row and the `PVScrollRowIntoView` doc comment.

### X-1 · major · "the modifier's two calls" is three
**Answer:** Fixed — Current state names lines 305, 316, 334; STEP-5's check `rg`s every old name.

### X-2 · major · Step checks that cannot pass as written
**Answer:** Fixed — STEP-1 uses `rg -nF` literals; STEP-3 scopes `PVListRowStyle` to Swift files and `chevron:` to the List and Conclusions folders.

### X-3 · blocker · Who reads the width class and where the gutter comes from
**Answer:** Fixed — D-10: `ConclusionListFrame`, a view that reads `pvWidthClass` once, replaces the static `page(meta:body:)` and serves both callers.

### X-4 · major · Preview "Failed"/"Empty" cannot show what the manual check expects
**Answer:** Fixed — D-11: `loadingArea`, `emptyArea`, `failureArea` are static builders the body and the previews share; STEP-6's previews draw `ConclusionListFrame` over them at both widths.

### X-5 · major · Names and state the Home/End steps leave open
**Answer:** Fixed — D-5 names `edgeRow`, `edgeAnchor`, `edgeRequest` (incremented every press), when the key is ignored, and that the selection scroll (D-7) is a second modifier without a token.

### X-6 · major · Restore: where and when "first `.rows`" is detected
**Answer:** Fixed — by M-1: the modifier restores once per mount when `isSettled` first holds, re-resolves on anchor change, and clears a vanished id after the first restore.

### X-7 · major · `ConclusionListSelection.restored` has no signature or home
**Answer:** Fixed — replaced by `ListAnchor.resolved(_ anchor: String?, in ids: [String]) -> String?` in `WorkspaceNavigation.swift`.

### X-8 · major · Which inks go through the rule; no way to see `.increased` in a preview
**Answer:** Fixed — D-4 lists each ink, including `PVDatePlaceLine`'s `dateTone`; STEP-2 adds a `#Preview("Selected row ink")` with `.environment(\.backgroundProminence, .increased)`.

### X-9 · minor · Empty and loading area geometry
**Answer:** Fixed — D-9 and D-10 name the frame modifiers.

### X-10 · minor · Header identifiers for the Conclusion pages
**Answer:** Fixed — D-3: `identifierPrefix: Kind.identifierRoot` (`persons.countLine`).

### X-11 · minor · T-4 passes before the change
**Answer:** Fixed — T-4's first case (the coalesced visit) is new behavior through the modifier; its second case is labeled a regression check.

### X-12 · minor · Smaller choices
**Answer:** Fixed — a Stop condition for row animation; D-2 says a single-selection list hands at most one id and opens the first; STEP-8 gives a five-line format including the separator branch; `completed.md` paths made full. The Sources header's 4 pt stays a manual check (§10 step 5).
