# Review — S15-12 Source types suggest fields at each level (with brief S15-D6)

**Verdict:** round 1: Fits with changes — Not ready; round 2: see below
**Rounds:** 1 (round 2 pending). **Reviewers:** maintainability (strongest available model), executability (implementing model)

## To user
- None. The three product calls were answered before review (user, 2026-11-14): append only, no reorder; the Associated fields column counts all three lists; the arrangement of the three lists is the board's call.

## Writer's own calls
- D-2: the two type–field mutations become one patch-only `.wroteTypeSuggestions(typeId:level:edit:)` with descriptor patches (from M-1).
- D-1: `.typeSuggestions` becomes `whenHidden: .markStale` (from M-2).
- D-8: forms keep their uncached suggestion read.
- D-9: list copy is one `L10n.SourceTypes.level(_:)` returning `LevelCopy`; toasts and labels use a level phrase ("on each Evidence graph of a Census Source").
- Version bump minor, 0.16.0.

## Round 1

### M-1 · blocker · Each assign or remove reloads the list the reply already returned
Apply invalidates the visible key; `setQueryValue` → `WorkspaceSession.replaceValue` restarts the in-flight load. Use a patch-only mutation with descriptor patches, as `.wroteMetadataBoard` / `CatalogQueryPatch.metadataBoard()`.
**Answer:** Fixed — verified `replaceValue` at `WorkspaceSession.swift` ~126–141. D-2 now replaces both mutations with `.wroteTypeSuggestions(typeId:level:edit:)` and two descriptor patches (`CatalogQueryPatch.typeSuggestions()`, `.typeSuggestionCount()`); D-5 drops the model's patches; T-8 asserts no read; STEP-7 updates `docs/macos-client-patterns.md` and `add-workspace-place`.

### M-2 · blocker · Three keys per type triple the vocabulary-write fan-out
`.typeSuggestions` defaults to `whenHidden: .revalidate` and follows `.list(.sourceVocabulary)`.
**Answer:** Fixed — D-1 sets `whenHidden: .markStale`; § 6 Scale states the fan-out; T-10 *(new)* pins the hidden policy.

### M-3 · blocker · A second read-state mechanism and no retry (plan and brief)
`QueryHandle.reading` and `PVRetryCallout` exist; `add-workspace-place` "Stale-while-revalidate" row says to use them.
**Answer:** Fixed — D-4 exposes `suggestionsHandle(at:)` and `rereadSuggestions(at:)` in place of `isLoadingSuggestions(at:)` / `suggestionsFailure(at:)`; § 6 macOS States switch on `reading` and draw `PVRetryCallout`; new string `sourceTypes.suggested.readFailedTitle`; brief SL-5, copy and inventory updated (read vs write failure rows).

### M-4 · major · Two flags hold one "a write is running" state
**Answer:** Fixed — D-4 `suggestionWrite: SuggestionWrite?` (`assigning(Level)`, `removing(Level)`).

### M-5 · major · A widened Wide pane would deepen the Metadata / Source types near-copy
**Answer:** Fixed (conditional on the board) — D-6 and the brief's inventory put the width rule in `Features/CatalogVocabulary/` if the board widens the pane.

### M-6 · minor · A second failure hook for one FakeStore method
**Answer:** Fixed — `listTypeSuggestionsErrorLevels: Set<Level>?` gates the existing `listTypeSuggestionsError`.

### M-7 · minor · T-9 tests FakeStore's copy of the engine count
**Answer:** Fixed — T-9 dropped; D-7 says the fake's sum is fixture realism; the rule is tested in Go (T-1, T-2).

### M-8 · minor · Two places list the warmed keys
**Answer:** Fixed — `CatalogQueryKey.typeSuggestionsKeys(project:typeId:)` (D-1).

### M-9 · minor · Four parallel switches on `Level`
**Answer:** Fixed — D-9 `L10n.SourceTypes.level(_:) -> LevelCopy`.

### X-1 · blocker · STEP-1 / T-2 miss the existing handler count case
**Answer:** Fixed — § 4 Handler tests row and T-2 name the case "the reply counts the engine's source suggestions after the write", renamed, expecting 4 then 2.

### X-2 · blocker · STEP-2's check cannot pass when the fake's count changes there
**Answer:** Fixed — the fake's summing moves to STEP-3 with the tests it breaks.

### X-3 · major · D-5 order vs today's code; reload unverified
**Answer:** Fixed — superseded by M-1: one `apply` of a patch-only mutation, no model patch.

### X-4 · major · `removingFieldID` "no caller read" is false
**Answer:** Fixed — D-4 says it is read only as non-nil at `SourceTypesDetailPane` ~404; replaced by `suggestionWrite`.

### X-5 · major · Failure / empty / stale presentation per list undecided
**Answer:** Fixed — § 6 macOS States switch on `reading`, with the write Callout above and retry via Try again.

### X-6 · major · The section header's count
**Answer:** Fixed — the header drops its count; old ids listed as renamed; no UI test reads them.

### X-7 · major · `makeModel(suggestions:)` and the preview data
**Answer:** Fixed — D-7 gives `makeModel` a `[Level: …]` parameter; the preview seeds Artifact and graph rows on `t2`.

### X-8 · major · Site count and `PlaceRegistryTests`
**Answer:** Fixed — alias plus 13 uses; `PlaceRegistryTests` (~93, ~203) in § 4 and STEP-2.

### X-9 · major · Fake hooks unspecified
**Answer:** Fixed — precedence and scope in § 6 Codebase fit (with M-6).

### X-10 · major · T-3's order assertion
**Answer:** Fixed — set comparison; a helper awaits all three keys.

### X-11 · major · Group label and picker labels
**Answer:** Fixed — § 6 macOS Accessibility: group label from the title and `assignedCount`; picker label appends the title; the rest unchanged.

### X-12 · major · Checks not runnable here
**Answer:** Declined as a plan change — the sandbox lacks Xcode; the plan's checks are the repo's real ones. § 10 now says the manual check runs on a Mac with the `run` skill, at Regular and Wide.

### X-13 · minor · Brief inventory has no row for the pane widening
**Answer:** Fixed — the Detail pane row says where the width lives (with M-5).

### X-14 · minor · Frames missing for write failure, disabled state, pick surviving resize, the dash
**Answer:** Fixed — frame 7b added; 1a / 1b show the dash and a pick across the resize.

### X-15 · minor · Two Census datasets
**Answer:** Logged — the plan's ACs and the brief's frames use separate fixtures by design.

### X-16 · minor · Board lines in STEP-7
**Answer:** Fixed — STEP-7 lists the map's design-track link and the archived brief's links; the Board lines are filled at board agreement, before Planned (§ 12).

### X-17 · minor · Selection change during a write; a deleted picked field
**Answer:** Fixed — D-4: a running write patches its own type's key and toasts; `canAssign(at:)` requires `pickedField(at:) != nil`.

### X-18 · nit · Rows verified true
Logged.
