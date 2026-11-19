# Review — S16-61 Nothing in the app waits on a second window

**Verdict:** Fits with changes — Ready with changes
**Rounds:** 2. **Reviewers:** maintainability (Claude Fable 5 thinking), executability (Claude Opus 5.5)

## To user
- D-3 removes S15-10's AC-3.4 ("a graph made while the sheet is open starts linked"), which the map's first cut kept as harmless. Recommendation: remove it, as asked on 2026-11-18 ("remove what only a second window reaches"). The map's S16-61 entry now says so.

## Writer's own calls
- D-10: `deletedSourceDuringACoverRefreshLeaves` goes (found by M-1), with the production not-found handling kept.
- D-11: no guard on `openSheet` for an in-flight delete read; a manual check confirms the confirm cannot show over the sheet.
- D-5: the notice keeps its key and only its English changes.

## Round 1
### M-1 · major · A seventh second-window test is missed
`SourcePageModelTests.deletedSourceDuringACoverRefreshLeaves` (2788) deletes the Source between the page's own successful Artifact delete and the refresh that follows it; only another window does that.
**Answer:** Fixed — D-10; STEP-1 deletes it; AC-1.3, §4, Deletes and T-6 count seven.

### M-2 · minor · Test comments are outside the sweep
**Answer:** Fixed — STEP-5 names `SourcePageModelTests.swift` 2584 and `SourceTypePageModelTests.swift` 155; its `rg` covers `macos`.

### M-3 · major · STEP-5's own check would fail
`SourcePageContext.swift` 60–61 and `SourceDateFormModel.swift` 50–51 say "deleted elsewhere" across two lines.
**Answer:** Fixed — both named with their new text.

### M-4 / X-3 · major · `openedLabel` goes dead
Only `workspaceChanged()`'s toast reads it.
**Answer:** Fixed — STEP-1 deletes it and its three assignments; listed in Deletes and §4.

### M-5 · minor · Map row contradicts D-7
`deployment-plan.md` 163 listed the lock re-reads as second-window code; line 30 said the Add row loses its notice.
**Answer:** Fixed — both map lines now match D-5 and D-7.

### M-6 · minor · Capture values instead of ids in the sheet
Optional: the sheet could capture graph values at open instead of looking ids up.
**Answer:** Declined — `graphs` reads names the page may have renamed through its own patches; D-4 keeps the lookup and the PR stays a removal.

### X-1 · blocker · T-1 cannot reach `resetDrafts`
`makeModel(store:)` hides its session and the workspace key is not visible, so the type change only marks it stale and nothing calls `model.sync(from:)`.
**Answer:** Fixed — STEP-4 builds the session, applies `.sourcePage(sourceId:)`, seeds with `catalogMetadataEntry(…, suggested: true)`, settles, and calls `model.sync(from:)` on the workspace handle, as `privateSwitchSavesRevertsAndKeepsEdits` does.

### X-2 · major · The AC `rg` patterns could not fail
`\|` inside the table read as a literal pipe.
**Answer:** Fixed — the ACs point at the step checks, which use plain `|` outside tables.

### X-4 · major · AC-3.1 and AC-3.2 lost their tests
**Answer:** Fixed — they now cite surviving tests: `sheetCitationsLockHoldsUntilTheLinkIsSaved` and `addArtifactOnOneGraphShowsTheGroup`.

### X-5 · major · Delete read in flight, then the sheet opens
**Answer:** Fixed — D-11: the confirm is presented by the page beneath the modal sheet and cannot be confirmed while it is open. Manual check step 3 and a stop condition cover it.

### X-6 · minor · Elided `xcodebuild` command; ingest test lines
**Answer:** Fixed — steps use `scripts/check-pr.sh`; lines are 522–628.

## Round 2
Executability (fresh, with this log): no new blockers or majors; verdict Ready. It confirmed T-1 compiles against the real helpers and reaches `resetDrafts` through `.changedSourceType` on a visible key. Precision fixes applied: `ArtifactSheetModel.swift` comment range 329–330 (line 331's re-read stays), `sources.go` 29–30, ingest tests 522–628 in §6 Edges, the location apply cited from `resourceDeleteDoesNotReloadTheDeletedSource`, and the idea file's point 7 now names what this PR removes.
