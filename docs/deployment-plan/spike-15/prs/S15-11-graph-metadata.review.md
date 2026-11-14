# Review — S15-11 Evidence graphs show their metadata

**Verdict:** Fits with changes — Not ready → Ready after round 1's fixes
**Rounds:** 1. **Reviewers:** maintainability (Opus), executability (Sonnet)

Round 2 was not run: the two blockers that were the user's (M-1, M-2) were settled by the user and removed code rather than adding it; every other blocker was a missing specification, now written as a Decision.

## To user

- **M-1, a second breakpoint (960pt one-column fallback).** **Answered (user, 2026-11-14):** no fallback; the form is two columns at every width. The bend of `docs/macos-client-patterns.md` § 9 is gone with it.
- **M-2, the Artifact sheet's stale-cache erase.** **Answered (user, 2026-11-14):** not engineered for; two windows editing the same owner is accepted as long as the app does not crash. Recorded as the map's working rule "No engineering for two windows editing the same data". The plan's fresh `getMetadataBoard` read on Edit is dropped too.

## Writer's own calls

- A graph Save always applies the reply's rows, with or without a draft (D-5); the Artifact sheet applies them only with a draft.
- The page read builds one owner list and splits the boards by index (D-1).
- `metadataRows(for:)` answers `[]` for any graph id (D-3).

## Round 1

### M-1 · blocker · A second pane breakpoint
**Answer:** To user, answered — D-9: two columns always; Out row for the fallback.

### M-2 · blocker · The Artifact sheet keeps the stale-cache path
**Answer:** To user, answered — working rule; Out row; D-10 opens Edit from the page.

### M-3 · major · Three `ListWorkspaces` transactions per page read
**Answer:** Fixed — D-1: `ownerBoardsProto(c, owners)` once over Source, Artifacts and graphs.

### M-4 · major · The draft-board Save rule copied into a second model
**Answer:** Fixed — D-11: `MetadataBoardModel.unconfirmedInputMessage`; both forms read it.

### M-5 · minor · `graphMetadata` semantics and stale doc comments
**Answer:** Fixed — D-3 rewrites the guard and both comments.

### M-6 · minor · A copied row reader
**Answer:** Fixed — D-6: `SourcePageContext.metadataRows(for:)`; `copyDetails(for:)` goes.

### M-7 · minor · The live host outside the apply helper
**Answer:** Fixed — D-6: `SourcePageMetadataHost.didWrite` calls `applySavedMetadata`.

### X-1 · blocker · `ThrowingStore` conforms to `GenealogyStore`
**Answer:** Fixed — STEP-3 files, D-4.

### X-2 · blocker · Name-only Save: apply the reply rows or not
**Answer:** Fixed — D-5: always apply; AC-2.6, T-7.

### X-3 · major · Test hooks for the read guards
**Answer:** Fixed — Edit no longer reads (M-2); T-9 uses the existing `listTypeSuggestionsHold`.

### X-4 · major · Scroll target names
**Answer:** Fixed — D-5 (`Section`, `opensAt`, `scrollTarget`, `scrollRequest`), D-9.

### X-5 · major · How the dialog picks columns
**Answer:** Fixed — moot: no fallback (M-1).

### X-6 · major · Form layout details
**Answer:** Fixed — D-9: no marker or hint; inside `.disabled`; `PVTabPair` unchanged; right column named; tab order.

### X-7 · major · FakeStore graph boards
**Answer:** Fixed — D-4; T-5 scripts `metadataWriteResults`.

### X-8 · minor · The `setMetadataRows` guard
**Answer:** Fixed — D-3.

### X-9 · minor · Graph row layout
**Answer:** Fixed — D-12.

### X-10 · minor · Fixtures
**Answer:** Fixed — T-1 and T-5 name their setup.

### X-11 · minor · Header, field count, test order, structural-debt row
**Answer:** Fixed — status Planned; §4 proto row; T-10 before T-11; the structural-debt row is gone (M-2).

### X-12 · minor · Opening edges
**Answer:** Fixed — D-10: `openEdit` returns while `isOpeningAdd`; Edit has no read, so no graph-gone-during-read case.
