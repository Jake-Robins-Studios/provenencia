# Review — S15-63 A type suggests fields once

**Verdict:** Fits with changes — Ready with changes; no open blocker
**Rounds:** 2. **Reviewers:** maintainability (Opus), executability (Sonnet). The brief S15-D32 was reviewed with the plan.

## To user

- **M-1** (answered 2026-11-23): the Add forms switch to `GetDraftMetadataBoard` **in S15-63** (user's choice, the writer's recommendation). Plan D-17, STEP-6, T-10.
- While planning (answered 2026-11-23): the board heading "Suggested by this type" and its dismiss label stay (D-11); no reorder (D-12).

## Writer's own calls

- D-1: the merge renumbers each type's kept rows from 0, tie-broken by `field_id`; NULL `sort_order` counts as 0.
- D-6: the seed takes the formats' first-read order. The migration's merge order (Source, Artifact, graph) applies only to projects made before this PR, so a dogfood project and a new one may order the same type's list differently.
- D-4: the proto removes the level fields (reserved) instead of ignoring them; `GetDraftMetadataBoardRequest.level` stays.
- D-10: new key names `sourceTypes.suggested.meaning`, `.empty`, `.pickerLabel`, `sourceTypes.copy.suggestions`; sentences rewritten whole under their existing keys.
- Version: minor, 0.35.0.

## Round 1

### M-1 · blocker · The Add forms build a draft board in Swift beside the engine's
**Answer:** To user → answered: do it in S15-63. D-17 *(new)*, STEP-6 *(new)*, AC-1.4, T-10; the Out row to S15-55 removed; § 4 "Engine draft board" and "Add forms" rows.

### M-2 · major · The Copy sheet's count can come from the type row's count
**Answer:** Fixed — D-19: `original.suggestedFieldCount`; the sheet reads no suggestion key; `loadState` is the formats alone; T-9.

### M-3 · major · `HoldsMetadata` / `holdsMetadata` left dead; false rationale for `metadataLevels`
**Answer:** Fixed — D-18 deletes both and their tests, fixes the two comments, and states why `metadataLevels` stays.

### M-4 · major · STEP-9 misses `macos-client-patterns.md` line 89 and `source-layer-data-model.md` § 4.3
**Answer:** Fixed — § 4 Docs row, STEP-9, sweep names ("at each chosen level", "type and level").

### M-5 · major · `typePhrase` keeps a phrase splice
**Answer:** Fixed — D-10: each sentence written whole with the type's label as data; no `typePhrase`.

### M-6 · minor · `suggestionsTypeId` becomes a one-off accessor
**Answer:** Fixed — D-7: `key.id` / `key.ownId`; accessor deleted.

### M-7 · minor · A wrapper view left over from the loop
**Answer:** Fixed — D-9 and the brief's inventory: one view, `SourceTypeSuggestedFields`.

### M-8 · minor · The brief leaves the count's place open when the kit has a precedent
**Answer:** Fixed — brief OL-1 and inventory: `PVSectionHeader` `meta`; D-9.

### M-9 · minor · Per-(type, level) list copy and a query per type
**Answer:** Fixed — D-2 `ListSuggestionsTx(tx, typeIDs)` batched; D-5 `suggestionsOf` per type, needs per level.

### X-1 · blocker · A second `GenealogyStore` conformer and two previews missed
**Answer:** Fixed — `OnboardingModelTests.swift` and `SourceTypePageView.swift` previews in § 4, D-8, STEP-5, STEP-6.

### X-2 · major · How to produce the seed lists
**Answer:** Fixed — STEP-2: a throwaway test prints `derivedSuggestions` as Go source, pasted, then deleted; T-6 is the check.

### X-3 · major · "59 entries" is false
**Answer:** Fixed — 58.

### X-4 · major · The migration SQL was a sketch
**Answer:** Fixed — § 6 Schema has the full statement, run on a sample at planning.

### X-5 · major · Existing Go tests' new expectations undecided
**Answer:** Fixed — STEP-2 (the `sourcetypes_test.go` count case rewritten to "list counts each suggested field once"), STEP-3 (`TestOwnerTables` asserts by field id), STEP-4 (handler tests assert by field id).

### X-6 · major · T-2, T-4, T-7, T-8 left choices open
**Answer:** Fixed — § 8: T-2 new test named; T-4 fixture named; T-7 named `wroteTypeSuggestionsPatchesTheListAndTheCount`; T-8 old → new name map; STEP-5 lists the registry test lines.

### X-7 · major · Swift model members described, not named
**Answer:** Fixed — D-19 (copy model names), D-20 (page model names).

### X-8 · major · D-5 left the shared list's shape open
**Answer:** Fixed — D-5 with M-9.

### X-9 · major · FFI details
**Answer:** Fixed — § 6 FFI: field 9 is free at the base; the generator's outputs and tools; helpers' new signatures; never hand-edit generated files. The untracked `api/proto/engine/engine.pb.swift` the reviewer saw is not in the checkout (`ls api/proto/engine/` lists `engine.pb.go` only).

### X-10 · minor · New L10n key strings and the phrase's argument type
**Answer:** Fixed — D-10 names every key and takes `CatalogSourceType.label`.

### X-11 · minor · Edges (stale add reply, Install twice, migration renumber)
**Answer:** Fixed in part — STEP-1 renumbers the file if `main` took `000069`; T-5 asserts a repeated assign returns the same list. `Install` runs once at create (its contract); no change.

### X-12 · minor · Docs rows incomplete; sweep scope
**Answer:** Fixed — with M-4; the sweep line now covers `macos/` and `core/`.

### X-13 · minor · STEP-2 did not compile without STEP-3
**Answer:** Fixed — the API, Copy and seed changes are one step (STEP-2); steps renumbered.

## Round 2

Fresh reviewers checked the round-1 answers against the code at `c57f2a1`. Maintainability: Fits with changes. Executability: Ready with changes. Both confirmed D-17's symbols (`GetDraftMetadataBoard`, `GoStore.mapMetadataEntry`, the Add-form callers) and that `sources.source_type_id` is NOT NULL.

### M2-1 · blocker · Two readers of the suggestion list in one package
**Answer:** Fixed — D-2: one batched `ListSuggestionsTx`; `ListSuggestions` wraps it; `sqlListSuggestions` and `listSuggestions` deleted.

### M2 · round-1 answer M-3 rested on a wrong reason
**Answer:** Fixed — D-18: Swift `Level.metadataLevels` stays under the working rule "One level type", not for owners or S15-54.

### M2 · minor points
**Answer:** Fixed — `getDraftMetadataBoard` (the `get*` convention); `readDraftBoardForAdd(level:)` and `.create(entries:)` with draft-board comments; `typeBoard` deleted for `map[typeLevel]levelNeeds`; the file renamed `SourceTypeSuggestedFields.swift`; the Edges line restated; sweep names and STEP-6/STEP-9 comment and doc lines added (`GenealogyStore.swift` 1307, 1449, 1459; `CatalogMutation.swift` 37; `seeded-vocabulary.md` 83).

### X2-1 · blocker · Add-form "one read at a time" tests wait on a hold the new read never reaches
**Answer:** Fixed — D-17 adds `draftMetadataBoardHold` and deletes `listTypeSuggestionsHold`; STEP-5 names the four tests that switch to it.

### X2-2 · major · STEP-5 could not build without STEP-6's change
**Answer:** Fixed — the Add-form step now comes first (STEP-5), then the store and cache (STEP-6).

### X2-3 · minor · `typelessSourceOpensWithNoSuggestions`
**Answer:** Fixed — deleted in STEP-5.

### X2-4 · minor · Guards and existing Add tests
**Answer:** Fixed — D-17 says the guards stay; STEP-5 maps each existing test to its rewrite; T-10 is a rename.

Stop: round 2 done, no blocker open.
