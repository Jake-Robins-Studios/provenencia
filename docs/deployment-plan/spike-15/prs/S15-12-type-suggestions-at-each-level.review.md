# Review — S15-12 Source types suggest fields at each level (with brief S15-D6)

**Verdict (re-plan, 2026-11-15):** Fits with changes — Ready with changes. Round 1 and round 2 findings all answered Fixed (M-5 Declined); no open blocker. The board-dependent parts (D-6, § 6 Strings) get a short re-review when S15-D6's board is agreed
**Rounds:** 2 of the re-plan. **Reviewers:** maintainability (opus), executability (sonnet)

The plan was rewritten against S15-48's landed type page (#848) and S15-49's list (#852); the brief was rewritten as an enhancement of S15-D27's page board. The side-pane plan's two rounds are kept below under "Side-pane plan (superseded)".

## To user
- M-2 option (a): a sub-level `PVSectionHeader` (smaller title, no rule) shared by this page and the citation composer's step header would be a kit change. Recommendation: not now; the plan and brief take option (b), a snowflake header matching `CitationComposerEvidenceColumn.stepper`, and S15-17 (formats in the same column, a third call site) asks the kit question.

## Writer's own calls
- D-1: the key's ids become `[typeId, level.rawValue]` with named accessors, as `citationsByArtifact`.
- D-4: per-level state as two dictionaries and one write gate on the page model, not a sub-model per list (M-5 declined).
- D-6: the list header is a micro-caps title with a trailing mono count, not a nested `PVSectionHeader` (M-2 option b).
- D-7: FakeStore's count becomes a scripted value, not a copy of the engine's rule (M-1).
- D-9: one `LevelCopy` per level; the level phrase spliced into five sentences is a complete adverbial phrase (M-4).
- D-10: Return adds through the add row's `.onSubmit`, focus returns after one yield.
- A list's count, picker and plus show only once that list has loaded; any write disables every list's write controls.
- Version bump minor, 0.16.0.

## Re-plan round 1

### X-1 · blocker · Strings for the picker label and the list's accessibility label have no key
**Answer:** Fixed — `LevelCopy.pickerLabel` per level and `listAccessibilityLabel(title:count:)` (`sourceTypes.suggested.listLabel`) in D-9 and § 6 Strings; `assignFieldLabel` removed. Brief SL-9 wording matched.

### X-2 · major · The count in a list's header while loading or failed
**Answer:** Fixed — § 6 States: the count shows only when `.loaded`.

### X-3 · major · Which controls disable during a write
**Answer:** Fixed — § 6 States names the picker's `.disabled` expression; any write disables every picker, plus and remove.

### X-4 · major · STEP-2 half-lands D-1
**Answer:** Fixed — STEP-2 keeps `warm()` on the `.source` key; STEP-3 switches it to `typeSuggestionsKeys`.

### X-5 · major · Submit needs a Task; focus can race the re-enable
**Answer:** Fixed — D-10 wraps the submit in a `Task`, yields once, then focuses; a Stop condition covers focus not sticking.

### X-6 · major · No remove hooks in the fake
**Answer:** Fixed — `removeTypeFieldError` *(new)*; T-7 covers a failed remove. No remove hold: T-9 holds an assign, and the gate is one value for both.

### X-7 · major · The list header's fallback
**Answer:** Fixed — D-6 names the default (with M-2).

### X-8 · minor · Assigning into an unloaded list
**Answer:** Fixed — `isLoaded(at:)`; `canAssign(at:)` requires it; the picker shows only when loaded; T-9 covers a failed level.

### X-9 · minor · Test and sweep wording
**Answer:** Fixed — T-2's `UpdateSourceType` case adds a graph row first; one sweep in the DoD with named old names; STEP-7 full paths and the archive link moves; generated file paths named in STEP-1.

### X-10 · nit · Duplicate defaults and Source-level wording
Logged; the board's copy settles it.

### M-1 · major · FakeStore takes over the engine's count rule
**Answer:** Fixed — D-7: the fake's count is `suggestedFieldCountOverride[typeID] ?? 0`; tests that check a count seed it. § 4 Fake row records today's copy.

### M-2 · major · The list header left as either/or; one option a near-copy
**Answer:** Fixed (option b) — brief inventory and SL-1 name one header shape, the composer stepper's; D-6 default matches. Option (a) To user.

### M-3 · minor · Next adds points S15-17 at keys and titles that do not fit it
**Answer:** Fixed — removed from Next adds and D-9's Why.

### M-4 · minor · The level phrase and "Whole phrases"
**Answer:** Fixed — D-9 states the phrase is a complete adverbial phrase owned by one entry; key comments say so.

### M-5 · minor · Dictionaries plus `(at:)` members vs one model per owner
**Answer:** Declined — the write gate, toast, store and session are page-wide; a list holds a pick and an error, so a sub-model is a class around two values with a back-reference. Recorded in Codebase fit with `MetadataBoardModel` named.

### M-6 · minor · Return mechanism and focus type
**Answer:** Fixed — Codebase fit row names `MetadataBoardAddRowView` and `pvActivatesOnReturn`; focus is a private one-case enum.

### M-7 · minor · `CatalogMetadataField.usedBy` doc is wrong
**Answer:** Fixed — § 4 Swift count docs and STEP-3 correct it.

## Re-plan round 2

### X2-1 · major · The zero-default fake count breaks tests the plan does not name
**Answer:** Fixed — D-7 names the T-8 seed (line ~1300) and the retired test at line ~339; STEP-3's check runs all five suites the fake change reaches.

### X2-2 · minor · Plural rule for `listLabel`
**Answer:** Fixed — § 6 Strings: plural variations on argument 2, as `sourceTypes.suggested.count`.

### X2-3 · nit · Line numbers, T-5's phrase, an empty pick
**Answer:** Fixed — § 4 line numbers; T-5 builds the phrase with `L10n.format`; an empty pick is `assignPicks[level, default: ""] == ""`.

### M2-1 · blocker · The M-1 fix only half in the plan
**Answer:** Fixed — STEP-3 says "scripted" and rewrites the `withSuggestedFieldCount` doc; D-7 says four hooks and seeds the `SourceTypesModelTests` fields-sort test (t2 = 1) beside T-8's seed (X2-1).

### M2-2 · blocker · The level phrase's article agrees with the type label
**Answer:** Fixed — phrases are "on each %@ Source", "on each Artifact of %@ Sources", "on each Evidence graph of %@ Sources", with no article that agrees with the label; D-9 cites "Whole phrases" accordingly; the brief's § 2.1, SL-9 and frames follow. Notes taken: `removeLabel(for:at:)` on the model; `assignedCount`'s comment updated; `listLabel` plurals (X2-2); the brief's Review line links this log.

## Side-pane plan (superseded)


**Verdict (side-pane plan):** Fits — Ready with changes (round 1: Fits with changes — Not ready; round 2: Fits — Not ready on X2-1, fixed)
**Rounds:** 2. **Reviewers:** maintainability (strongest available model), executability (implementing model)

### To user
- None. The three product calls were answered before review (user, 2026-11-14): append only, no reorder; the Associated fields column counts all three lists; the arrangement of the three lists is the board's call.

### Writer's own calls
- D-2: the two type–field mutations become one patch-only `.wroteTypeSuggestions(typeId:level:edit:)` with descriptor patches (from M-1).
- D-1: `.typeSuggestions` becomes `whenHidden: .markStale` (from M-2).
- D-8: forms keep their uncached suggestion read.
- D-9: list copy is one `L10n.SourceTypes.level(_:)` returning `LevelCopy`; toasts and labels use a level phrase ("on each Evidence graph of a Census Source").
- Version bump minor, 0.16.0.

### Round 1

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

### Round 2

### X2-1 · blocker · A patch-only mutation cannot invalidate `.sourceWorkspace`
`CatalogMutation.invalidationKind` is nil for patch-only cases, and `CatalogQueryRegistry.invalidations(by:project:)` returns `[]` for nil.
**Answer:** Fixed — verified (`CatalogMutation.swift` ~155, `CatalogQueryRegistry.swift` ~138). D-2 gives `.wroteTypeSuggestions` its own `CatalogMutationKind`, lists it in `.sourceWorkspace.invalidateOn`, and drops both `invalidateOn` and `invalidation` from `.typeSuggestions`; T-8 asserts the kind.

### X2-2 · major · STEP-2 touches tests STEP-3 owns; old-mutation test sites unnamed
**Answer:** Fixed — STEP-2 now carries the `makeModel` port and the `SourceTypesModelTests` call sites the alias removal forces, and names the five `CatalogQueryRegistryTests` sites; the 13/14 count is consistent (alias + 13 uses).

### X2-3 · minor · Type of `phrase:`
**Answer:** Fixed — D-9: `phrase: String` from one private `SourceTypesModel.levelPhrase(_:type:)`.

### Round 2 maintainability: Fits, no new blockers
Two notes below the bar, both taken:
- "Patch-only" means nil-kind in the code (`CatalogMutation.invalidationKind`); D-2 and STEP-7 now say "patch the two keys, then bust `.sourceWorkspace`". **Answer:** Fixed.
- The handle-taking `PVRetryCallout` extension uses `L10n.Conclusions.readNoticeTryAgain`. **Answer:** Fixed — § 6 States use the kit init with `sourceTypes.suggested.tryAgain`.

### Open before Planned
- Board S15-D6 agreed; D-6, § 6 macOS and § 6 Strings filled from it; a short re-review of those parts.
