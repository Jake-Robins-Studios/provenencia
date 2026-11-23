# S15-63 — A type suggests fields once

**Status:** Blocked — on board S15-D32
**Spike / slice:** Spike 15 · Slice 11 — Metadata at any level
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D32](../design/S15-D32-one-suggestion-list.md), board not agreed yet
**Board:** — (not drawn yet). When agreed: the Claude Design link and frame names go here, and D-9 and § 6 macOS describe each frame in words for an implementer who cannot open it
**Depends on:** S15-62 (landed [#950](https://github.com/Jake-Robins-Studios/provenencia/pull/950)), S15-D32
**Blocks:** S15-64, S15-54
**Branch:** `s15-63-type-suggests-fields-once`
**Version bump:** minor, 0.34.0 (today's `VERSION`) → **0.35.0** (or the next minor after `main`'s `VERSION` when you rebase): `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj` — a catalog format step and a feature change (every board offers every suggestion; the type page has one list) ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-catalog-migration`](../../../../.agents/skills/add-catalog-migration/SKILL.md), [`add-seeded-vocabulary`](../../../../.agents/skills/add-seeded-vocabulary/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`, `.cursor/rules/swift-tests.mdc`, `.cursor/rules/macos-client.mdc`
**Context:** working rules "A type suggests fields, not levels", "Boards flag needed fields; the engine decides the rows" ("a draft board with no owner reads `GetDraftMetadataBoard`"), "One level type", "A Source type has its own page" ([map](../deployment-plan.md#working-rules)); scope entry [S15-63](../deployment-plan.md#s15-63--a-type-suggests-fields-once); what this undoes: [S15-06](S15-06-type-suggestions-have-a-level.md), [S15-12](S15-12-type-suggestions-at-each-level.md), [S15-18](S15-18-copy-source-type.md); [S15-62 ship log](S15-62-nearest-level-fields.ship.md) UX-5
**Planned:** 2026-11-23 against `main` @ `a092302`
**Review:** [`S15-63-type-suggests-fields-once.review.md`](S15-63-type-suggests-fields-once.review.md) — Fits with changes — Ready with changes, round 1; no open blocker (M-1 answered by the user, 2026-11-23)

### Implementer — read this first

1. **This file is the whole task.** Read it top to bottom before you change code. Then read every file under **Current state** and load every skill under **Skills to load**.
2. **Check the base.** Compare `main` with the **Planned** commit. If a file under **Current state** has changed so a row is no longer true, stop and report which rows.
3. **Decisions are made.** Do not reopen a **Decision** or a **Scope** line, and do not swap in a design you like better. If one cannot work, stop: say which ID it is, what you found (path, line, output), and what you would need. Do not improvise around it.
4. **Do only In.** Out stays out, even when it is one line away. Do not refactor, rename, or tidy code the plan does not name.
5. **Work the Steps in order.** Run each step's check before you start the next. A failing check is fixed in that step.
6. **Hit a Stop condition → stop.** Report it. Do not work around it.
7. **Done is the Definition of done.** Report each box with its evidence: the command and its result, the test name, or the manual check you ran.
8. **Docs-only lines in the DoD are part of the PR.** Do not skip them.

---

## 1. Objective

A Source type suggests each field once. Every board of a Source of that type (the Source's Metadata section, each Artifact's sheet, each Evidence graph's form) offers all of the type's suggestions, and the type's page shows one Suggested fields list instead of three. Copy type copies that one list with one tick. The Add Artifact and Add graph forms start from the engine's draft board (`GetDraftMetadataBoard`) instead of building their rows in Swift (user, 2026-11-23). This comes from the user's review of where metadata lives (2026-11-22, later): a field's level kept being wrong, so S15-62 made a format read a field from the nearest level, and this PR takes the level off suggestions.

**Why now.** S15-62 landed; S15-64 (inherited values on every board) and S15-54 (Citation values, no fourth list) both build on one list per type.

**What stays.** A suggestion is still optional and ordered; a new one goes last; there is no reorder (user, 2026-11-14, confirmed 2026-11-23). Dismissals stay per owner (each owner's layout). Requirements stay per level: the list form's heads still show on the Source board alone. The board's heading "Suggested by this type" and its dismiss label stay (user, 2026-11-23). `vocabkey.Level` and Swift `Level` stay for owners, built-ins and the resolution order.

## 2. User stories

**US-1.** As a researcher, when I open a census Artifact's sheet, a census graph's form or a census Source's Metadata section, I see every field the Census type suggests, so I can type a value at whichever level fits.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A new project; a census Source with one Artifact and one graph; read the three boards | Each board's suggested entries are the census list's 21 fields in the same order (`creator` first, `item_number` last); Jurisdiction, Provider and Dwelling are on all three |
| AC-1.2 | On the census Artifact's board, dismiss `jurisdiction` (not needed at the Artifact level) | The Artifact's board no longer shows it; the Source's and the graph's boards still do |
| AC-1.4 | A census Source; click Add Artifact, then Add graph | Each form starts with the census list's 21 empty rows, the rows the engine's draft board returns; the read is `GetDraftMetadataBoard` with level `artifact`, then `graph` |
| AC-1.3 | A project made before this PR whose type suggests `page` on the Source (order 0) and on each Artifact (order 3), and `provider` on each Artifact (order 0); open it | The type suggests `page` (order 0) then `provider` (order 1), each once |

**US-2.** As a researcher, on a Source type's page I edit one Suggested fields list.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Census's page | One list of 21 rows; the count reads "21 fields"; the types list's Associated fields reads 21 |
| AC-2.2 | Add Column from the picker | Column is 22nd; the count reads 22; the toast reads "Column is now suggested for Census Sources." (or the board's wording, D-9) |
| AC-2.3 | Add a field the type already suggests (by a second, stale page) | No error; the list is unchanged |
| AC-2.4 | Remove URL | URL leaves the list; the field and every typed URL value stay |

**US-3.** As a researcher, Copy type copies the suggestions with one tick.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Copy Census with every tick on | The sheet shows four ticks (Icon, Description, Citation formats, Suggested fields "21 fields"); the copy suggests the same 21 fields in the same order |
| AC-3.2 | Copy Census with Suggested fields unticked | The copy suggests nothing |
| AC-3.3 | Copy a type with no suggestions | The Suggested fields tick is unticked and disabled, "None on this type" |

## 3. Scope

| In | Covered by |
| --- | --- |
| Migration: `source_type_metadata_fields` without `level`, rows merged (D-1) | STEP-1, AC-1.3 |
| `sourcevocab` suggestion functions and `CopyType` without a level (D-2, D-3, D-16) | STEP-2, AC-2.3, AC-3.1, AC-3.2 |
| The seed: one list per type, derived in first-read order (D-6) | STEP-2, AC-1.1 |
| Boards read the type's one list at every level (D-5) | STEP-3, AC-1.1, AC-1.2 |
| Suggested-field count over one list (D-13) | STEP-3, AC-2.1 |
| FFI: the suggestion RPCs and Copy type lose their level (D-4) | STEP-4 |
| Swift store, cache key, mutation, patches without a level (D-7, D-8) | STEP-5 |
| The Add forms read the engine's draft board (D-17) | STEP-6, AC-1.4 |
| `HoldsMetadata` / `holdsMetadata` deleted; comments that name type suggestions per level fixed (D-18) | STEP-2, STEP-5 |
| Type page: one list (OL-1 – OL-6, OL-8, OL-W1) | STEP-7, AC-2.1 – AC-2.4 |
| Copy type: one tick (OL-7) | STEP-8, AC-3.1 – AC-3.3 |
| Copy (D-10) | STEP-7, STEP-8 |
| Docs and skills the rule makes false | STEP-9 |

| Out | Home |
| --- | --- |
| Inherited values on a board's rows | S15-64 |
| Citation-level suggestions and values | S15-54 (no fourth list) |
| Reordering a type's suggestions | not planned (user, 2026-11-14, 2026-11-23) |
| A dismissal shared across an owner's levels | not planned (scope entry: each owner's layout keeps its own) |
| Changing the board heading "Suggested by this type" or its dismiss label | not planned (user, 2026-11-23) |
| Re-running `Install` on dogfood projects | not planned (the migration carries them) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Table | `core/database/migrations/000064.sql` | `source_type_metadata_fields (source_type_id, field_id, level CHECK IN ('source','artifact','graph'), sort_order)`, PK `(source_type_id, field_id, level)`, index `source_type_metadata_fields_field_id_idx`. Last migration: `000068.sql` |
| Catalog model | `core/database/catalogmodel/model.go` (table row at line 111, FKs at 161 – 162) | Facet, two CASCADE FKs. No change needed: the FKs and bucket stay |
| Effects | `core/database/effects/registry.go` `"source_type_metadata_fields": {None: true}` | Not audited. Stays |
| Suggestion API | `core/database/sourcevocab/sourcevocab.go` `ensureSuggestionTx`, `AppendSuggestion`, `ListSuggestions`, `ListSuggestionsTx`, `listSuggestions`, `DeleteSuggestion`, `sqlEnsureSuggestion`, `sqlDeleteSuggestion`, `sqlAppendSuggestion`, `sqlListSuggestions` | Each takes a `vocabkey.Level` and filters or keys by it; `level.HoldsMetadata()` guards. The package comment says "per level" |
| Copy | `core/database/sourcevocab/copy.go` `CopyTypeInput.Levels`, `sqlCopySuggestions`, `CopyType` | Copies the rows at the ticked levels |
| Seed | `core/database/sourcevocab/registry_suggestions.go` `seedSuggestions`; `core/database/sourcevocab/registry.go` `seedSuggestion{TypeKey, Level, FieldKeys}`; `Install` | 58 entries, one per (type, level) |
| Seed tests | `core/database/sourcevocab/registry_test.go` `derivedSuggestions`, `TestSeedSuggestionsFollowFormats`, `TestSeededFormatsNeedOnlySuggestedFields` | `derivedSuggestions` already returns one list per type in first-read order (S15-62 D-14); the test compares it with the seed's fields over all levels **as a set** |
| Count | `core/database/sourcetypes/sourcetypes.go` `sqlSuggestedFields`, `SuggestedFields`, `Type.SuggestedFields` | `COUNT(*)` of the type's rows; comments say "at all three levels (a field at two levels counts twice)" |
| Boards | `core/database/sourcemetadata/sourcemetadata.go` `typeLevel`, `typeBoard`, `readTypeBoards`, `listWorkspaces`, `ListDraftWorkspace`, `WorkspaceEntry.Suggested` (comment) | `readTypeBoards` calls `sourcevocab.ListSuggestionsTx(tx, typeID, level)` once per distinct (type, level) and `needsAt(reqs, level)` for the needs |
| Go tests | `core/database/sourcevocab/sourcevocab_test.go` (`TestAppendSuggestion` and 40 level uses), `copy_test.go`, `core/database/sourcemetadata/sourcemetadata_test.go` (`TestOwnerTables` asserts a field suggested at another level does not reach the owner; `TestListWorkspacesExported` and 8 other `AppendSuggestion(…, level)` calls), `core/database/sourcetypes/sourcetypes_test.go` (line 232: a raw insert with `level`; the case "list counts the fields a type suggests at every level", lines 566 – 600, inserts one field at two levels), `core/database/metadatafields/metadatafields_test.go` (lines 390, 522), `core/database/sourcecopy/sourcecopy_test.go` line 89 | Name a level |
| Proto | `api/proto/engine.proto` `ListTypeSuggestionsRequest.level = 3`, `AssignTypeFieldRequest.level = 5`, `RemoveTypeFieldRequest.level = 5`, `CopySourceTypeRequest.levels = 8`; comments on `SourceType.suggested_field_count`, `TypeSuggestion`, `GetSourceWorkspaceResponse` boards (lines 483 – 487), `MetadataBoard`, `GetDraftMetadataBoardRequest`, `AssignTypeFieldResponse`, `RemoveTypeFieldResponse` | Per level |
| Handlers | `api/ffi/handlers/source_defs.go` `CopySourceType`, `ListTypeSuggestions`, `AssignTypeField`, `RemoveTypeField`, `suggestionsProto` | Pass the request's level through |
| Handler tests | `api/ffi/handlers/source_defs_test.go` `TestAssignAndRemoveTypeField`, `TestListTypeSuggestions`, `TestRemoveTypeFieldDetachesOneLevel`, `TestTypeSuggestionRefusesAnyOtherLevel`, `TestCopySourceType`, helpers `listSuggestions`, `listSuggestionLabels`, `suggestionIDs`; level uses in `metadata_test.go`, `citation_render_test.go`, `artifacts_test.go`, `evidence_graphs_test.go`, `sources_test.go` | Per level |
| Engine draft board | `core/database/sourcemetadata/sourcemetadata.go` `ListDraftWorkspace(c, sourceID, level)`; `api/ffi/handlers/metadata.go` `GetDraftMetadataBoard`; `api/proto/engine.proto` `GetDraftMetadataBoardRequest` / `GetDraftMetadataBoardResponse` (`repeated MetadataWorkspaceEntry entries = 1`) | Served and tested in Go; no Swift caller and no `GenealogyStore` method |
| Level predicate | `core/vocabkey/vocabkey.go` `Level.HoldsMetadata` (callers: `sourcevocab.go` lines 62, 74, 123, 154; `copy.go` line 47; its cases in `vocabkey_test.go`); `macos/App/Platform/Level.swift` `holdsMetadata` (callers: `FakeStore.swift` lines 1554, 1568, 1592). The comments above `type Level` in `vocabkey.go` and in `Level.swift` say the levels "hold metadata values and type suggestions" | Every caller is a suggestion guard this PR removes |
| Swift store | `macos/App/Platform/GenealogyStore.swift` `listTypeSuggestions(…level:)`, `assignTypeField(…level:)`, `removeTypeField(…level:)`, `copySourceType(…levels:)`; `GoStore.swift` (lines 737 – 747, 911 – 962); `FakeStore.swift` `suggestionsByLevel`, `listTypeSuggestionsError`, `listTypeSuggestionsErrorLevels`, `listTypeSuggestionsLevels`, the copy record's `levels` (line 97); a second conformer `macos/ProvenenciaTests/OnboardingModelTests.swift` (stubs at lines 537 – 583: `copySourceType(…levels:)`, `listTypeSuggestions(…level:)`, `assignTypeField`, `removeTypeField`) | Per level |
| Swift cache | `macos/App/Features/Workspace/Session/CatalogQueryKey.swift` `typeSuggestions(project:typeId:level:)`, `typeSuggestionsKeys`, `suggestionsLevel`; `CatalogQueryRegistry.swift` `.typeSuggestions` loader; `CatalogLastUpdated.swift` `typeSuggestions()`, `typeSuggestionCount()`; `CatalogMutation.swift` `.wroteTypeSuggestions(typeId:level:edit:)`; `PlaceRegistry.swift` `sourceTypesDetail` query keys | Three keys per type |
| Add forms | `macos/App/Features/Sources/SourcePageContext.swift` `unsavedMetadataRows(level:)`, `readSuggestionsForAdd(level:)`; callers `SourceArtifactsSection.swift` line 103, `SourceGraphsSection.swift` line 76; `macos/App/Features/Sources/MetadataDraftHost.swift` `unsavedRows(from:)`; `macos/ProvenenciaTests/MetadataDraftHostTests.swift` (line 49 builds entries with it; `unsavedRowsAreTheTypesSuggestions`) | Read the type's suggestion list and build empty rows in Swift: a second mechanism beside `GetDraftMetadataBoard`, against the rule "a draft board with no owner reads `GetDraftMetadataBoard`" |
| Type page | `macos/App/Features/SourceTypes/SourceTypePageModel.swift` (`SuggestionWrite`, `assignPicks`, `suggestionErrors` keyed by `Level`; `suggestionsHandle(at:)`, `suggestions(at:)`, `isLoaded(at:)`, `assignPool(at:)`, `pickedField(at:)`, `canAssign(at:)`, `levelPhrase`, `assignTooltip(at:)`, `assignAccessibilityLabel(at:)`, `removeLabel(for:at:)`, `assignPickedField(at:)`, `removeSuggestion(fieldID:level:)`, `rereadSuggestions(at:)`); `SourceTypeSuggestionList.swift` `SourceTypeSuggestedFields` (a `ForEach` over `Level.metadataLevels`), `SourceTypeSuggestionList(level:)`; preview data in `SourceTypesView.swift` lines 95 – 105 and `SourceTypePageView.swift` lines 286 – 300 (both seed `suggestionsByLevel`) | Three lists |
| Copy sheet | `macos/App/Features/SourceTypes/SourceTypeCopyModel.swift` `SourceTypeCopyChoices.includedLevels`, the `init`'s warm of `typeSuggestionsKeys`, `suggestionsKey(at:)`, `suggestionsHandle(at:)`, `suggestionCount(at:)`, `levelAvailable`, `levelHint`, `levelsToCopy`, `loadState` (formats plus three lists), `reload` (rereads failed lists); `SourceTypeCopyDialog.swift` `ForEach(Level.metadataLevels)` ticks, `levelBinding` | Three ticks |
| Copy | `macos/App/Platform/L10n.swift` `L10n.SourceTypes.LevelCopy`, `level(_:)` (lines 8654 – 8775), `listAccessibilityLabel`, `assignField`, `assignFieldNamed`, `assignTipField`, `removeSuggestion`, the assigned and removed toast bodies (8796 – 8895) | Each takes a level phrase |
| Swift tests | `macos/ProvenenciaTests/SourceTypePageModelTests.swift` (`warmingLoadsEachLevelsListInStoredOrder`, `aFailedLevelReadFailsOnlyThatList`, `assigningWritesAtThatLevelOnly`, `aFieldCanSitInTwoLists`, `anAssignFailureStaysInItsList`, `oneWriteAtATimeAcrossLists` and others), `SourceTypeCopyModelTests.swift`, `CatalogQueryRegistryTests.swift`, `PlaceRegistryTests.swift`, `WorkspaceSessionTests.swift`, `MetadataModelTests.swift`, `SourceGraphFormModelTests.swift`, `SourcePageModelTests.swift`, `SourceTypesModelTests.swift` | Seed `suggestionsByLevel` or name a level |
| Docs and skills | `docs/source-layer-data-model.md` § 4.3 Copy a Source type (line 204, "at each chosen level"), § 5.2 (line 259, "A type suggests fields per level") and § 5.5 ("Suggestions have a level", line 363); `docs/macos-client-patterns.md` line 89 (`.wroteTypeSuggestions(typeId:level:edit:)`, "the one `typeSuggestions` key of that type and level"); `docs/seeded-vocabulary.md` § 2.3 (lines 132, 153, 155); `.agents/skills/add-seeded-vocabulary/SKILL.md` line 38; `.agents/skills/add-workspace-place/SKILL.md` line 172 | Per level |

**Precedent.** This PR undoes three: S15-06 ([#782](https://github.com/Jake-Robins-Studios/provenencia/pull/782), migration `000064.sql`, the table rebuild with `-- migrate: foreign_keys off`), S15-12 ([#856](https://github.com/Jake-Robins-Studios/provenencia/pull/856), the three lists and the per-level key) and S15-18 ([#877](https://github.com/Jake-Robins-Studios/provenencia/pull/877), the per-level ticks). Copy `000064.sql`'s rebuild shape (new table, copy, drop, rename, recreate the `field_id` index). Copy the single-list page from before S15-12 as S15-D27 TP-7 drew it, restyled per S15-D32.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | Migration `000069.sql` *(new)* rebuilds `source_type_metadata_fields` as `(source_type_id, field_id, sort_order)`, PK `(source_type_id, field_id)`, same FKs, and recreates `source_type_metadata_fields_field_id_idx`. Each (type, field) keeps its first row in the order Source, Artifact, graph, then that level's `sort_order` (NULL as 0), then `field_id`; the kept rows are renumbered from 0 per type in that order | Working rule "A type suggests fields, not levels" names the merge; contiguous orders keep "append last" simple | Dropping the rows (a dogfood project would lose its lists); keeping old sort orders (collisions across levels) |
| D-2 | `sourcevocab`: `ensureSuggestionTx(tx, typeID, fieldID, sortOrder)`, `AppendSuggestion(c, typeID, fieldID)`, `ListSuggestions(c, typeID) ([]Suggestion, error)`, `ListSuggestionsTx(tx, typeIDs [][]byte) (map[string][]Suggestion, error)` (batched with `sqlbatch.Query` as `sourcetypes.RequirementsTx` is; keyed by `string(typeID)`; a type with none is absent; no ids runs no query), `DeleteSuggestion(c, typeID, fieldID)`; the SQL drops `level`; `Suggestion` is unchanged. The `HoldsMetadata` guards go (D-18) | The level is gone from the table; the board read is batched like its neighbours (review M-9) | A deprecated level argument kept for callers — a second meaning |
| D-3 | `CopyTypeInput.Levels` becomes `Suggestions bool`; true copies every row of the original with its `sort_order` | One tick | A level list of one element |
| D-4 | `engine.proto`: delete `level` from `ListTypeSuggestionsRequest` (reserve 3 and `"level"`), `AssignTypeFieldRequest` and `RemoveTypeFieldRequest` (reserve 5 and `"level"`); in `CopySourceTypeRequest` delete `levels` (reserve 8 and `"levels"`) and add `bool copy_suggestions = 9`. Rewrite every comment in § 4's Proto row to say one list per type, each field once. `GetDraftMetadataBoardRequest.level` stays (needs are per level; S15-55 uses it) | Repo convention for removed fields (`reserved 2; reserved "user_id"`) | Keeping `level` and ignoring it — a field that lies |
| D-5 | Boards: `typeBoard` drops `suggestions`; `readTypeBoards` returns the needs per `typeLevel` as today plus `suggestionsOf map[string][]sourcevocab.Suggestion` from one `sourcevocab.ListSuggestionsTx(tx, typeIDs)` over its distinct types. `listWorkspaces` (the `inSuggestions` loop and the `boardInput`) and `ListDraftWorkspace` read `suggestionsOf[typeID]`. `buildEntries` is unchanged | Suggestions are per type, needs per level (the list form's heads stay Source-only, rule "Boards flag needed fields") | Keeping a per-(type, level) copy of one list (review M-9) |
| D-6 | Seed: `seedSuggestion` becomes `{TypeKey, FieldKeys}`; `seedSuggestions` has one entry per seeded type that suggests anything (26), whose `FieldKeys` equal `derivedSuggestions` exactly, in order (§ 6 Edges lists them). `TestSeedSuggestionsFollowFormats` checks one entry per type and `slices.Equal` in order, and drops the "more than one level" check. `TestSeededFormatsNeedOnlySuggestedFields` keeps its type/field key | Rule: "derives it from the type's formats in first-read order" | Keeping the merge order in the seed: a new project's order would not follow its formats |
| D-7 | Swift: `CatalogQueryKey.typeSuggestions(project:typeId:)` built with one id (`.init(.typeSuggestions, project, [typeId])`); `typeSuggestionsKeys`, `suggestionsLevel` and `suggestionsTypeId` are deleted; the loader passes `key.id` and `typeSuggestions()` guards `key.ownId == typeId`, as single-id keys do (`.propertyTerms`); `.wroteTypeSuggestions(typeId:edit:)`; `PlaceRegistry`'s `sourceTypesDetail` lists the one key | One list, one key ([`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md)); review M-6 | — |
| D-8 | `GenealogyStore.listTypeSuggestions(projectDir:typeID:)`, `assignTypeField(projectDir:typeID:fieldID:)`, `removeTypeField(projectDir:typeID:fieldID:)`, and `copySourceType(…, copySuggestions: Bool)` in place of `levels:`, in `GoStore`, `FakeStore` and the conformer in `OnboardingModelTests.swift`. FakeStore: `suggestionsByType: [String: [CatalogTypeSuggestion]]`, `listTypeSuggestionsError` (every call), `listTypeSuggestionsTypeIDs: [String]` in place of `listTypeSuggestionsLevels`; `listTypeSuggestionsErrorLevels` deleted; the copy record's `levels` becomes `copySuggestions: Bool` | The level is gone | — |
| D-9 | The type page's section and the Copy sheet follow the agreed S15-D32 board (OL-1 – OL-8, OL-W1). The count is `PVSectionHeader`'s `meta` (as `ConclusionGallerySection`); no `PVSubsectionHeader` in the section. One view, `SourceTypeSuggestedFields`, holds the header, hints, rows, states and picker; `SourceTypeSuggestionList` is folded into it and deleted. Filled in when the board is agreed: any copy change | Board gate; one interaction, one kit piece (review M-7, M-8) | A wrapper view whose only job was the loop over levels |
| D-10 | Copy: `L10n.SourceTypes.LevelCopy` and `level(_:)` are deleted, with their 18 keys. Each sentence that took a level phrase is rewritten whole and takes the type's label (`CatalogSourceType.label`, a `String`) as data, under its existing key with a new default value: `assignField(type:)` "Suggest a field for %@ Sources", `assignFieldNamed(field:type:)` "Suggest %1$@ for %2$@ Sources", `assignTipField(label:type:)` "Suggest %1$@ for %2$@ Sources", `removeSuggestion(label:type:)` "Stop suggesting %1$@ for %2$@ Sources", the assigned body "%1$@ is now suggested for %2$@ Sources.", the two removed bodies with today's values clause. New *(new)*: `suggestedMeaning` key `sourceTypes.suggested.meaning` ("Offered on every Source, Artifact and Evidence graph of this type"), `suggestedEmpty` key `sourceTypes.suggested.empty` ("No suggested fields yet. Assign the fields these records usually carry."), `suggestedPickerLabel` key `sourceTypes.suggested.pickerLabel` ("Metadata field to suggest"), `copySuggestions` key `sourceTypes.copy.suggestions` ("Suggested fields"). `sectionLabel`, `hint`, `count`, the pool hints and `listLabel` stay; `listAccessibilityLabel` takes `suggestedSectionLabel` as its title. Strings as S15-D32 § 2.1 unless the board changes them (D-9) | Whole sentences with data arguments ([`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md) "Whole phrases"; review M-5) | A `typePhrase` fragment spliced into each sentence |
| D-11 | The board's empty-group heading "Suggested by this type" and "Dismiss the suggestion for %@" stay | User, 2026-11-23: a type's formats are part of the type | Renaming the heading — a second view's chrome |
| D-12 | No reorder | User, 2026-11-14, 2026-11-23 | — |
| D-13 | `sqlSuggestedFields` keeps its SQL; with one row per field it counts each field once. Its comment, `Type.SuggestedFields`' and `SuggestedFields`' say so | — | — |
| D-14 | Dogfood projects are carried by the migration; `Install` is not re-run | No users; rule in [`add-catalog-migration`](../../../../.agents/skills/add-catalog-migration/SKILL.md) "do not backfill seeds" | — |
| D-15 | Test layers: the merge is not tested directly ([`add-catalog-migration`](../../../../.agents/skills/add-catalog-migration/SKILL.md)); AC-1.3 is the manual check. Boards and API in Go table tests; the page and sheet in Swift model tests against FakeStore | Skills | A migration test — the skill forbids it |
| D-17 | The Add forms read the engine's draft board. `GenealogyStore.draftMetadataBoard(projectDir:sourceID:level:) -> [CatalogMetadataEntry]` *(new)* calls `GetDraftMetadataBoard` (`CoreMethod.getDraftMetadataBoard` *(new)* in `macos/App/Platform/CoreInvoke.swift`; each entry through `GoStore.mapMetadataEntry`). `SourcePageContext.readSuggestionsForAdd(level:)` keeps its level and returns those entries; `unsavedMetadataRows(level:)` and `MetadataDraftHost.unsavedRows(from:)` are deleted, with `unsavedRowsAreTheTypesSuggestions`, and `MetadataDraftHostTests` line 49 builds its entries as literals. FakeStore: `draftMetadataBoardEntries: [String: [CatalogMetadataEntry]]` keyed `"<sourceID>/<level rawValue>"` (absent: empty), `draftMetadataBoardError: Error?`, `draftMetadataBoardCalls: [(sourceID: String, level: Level)]`. Tests and previews that seeded suggestions for an Add form seed `draftMetadataBoardEntries` | User, 2026-11-23 (review M-1): one owner for a new owner's starting board; rule "a draft board with no owner reads `GetDraftMetadataBoard`" | Leaving the Swift copy to S15-55, whose scope is Go only |
| D-18 | `vocabkey.Level.HoldsMetadata` and its cases in `core/vocabkey/vocabkey_test.go`, and Swift `Level.holdsMetadata`, are deleted (no caller remains). `MetadataLevels()` and `Level.metadataLevels` stay: owners, the parity test `api/ffi/swift_vocabulary_test.go` and S15-54 use them. The comments above `type Level` in `vocabkey.go` and in `Level.swift` drop "and type suggestions" | Review M-3 | — |
| D-19 | The Copy sheet's Suggested fields count is `original.suggestedFieldCount` (the engine's count, D-13, already on the type row). `SourceTypeCopyModel` reads no suggestion key: its `init` warms none, `loadState` is `formatsState`, `reload()` rereads only the formats. Names: `choices.includeSuggestions` (default true), `suggestionCount`, `suggestionsAvailable` (count > 0), `suggestionsHint` (`assignedCount(count:)`) | One source for the count, the one the types list shows (review M-2); names follow `includeFormats`, `formatsAvailable`, `formatsHint` | Warming the list only to count it |
| D-20 | `SourceTypePageModel` members keep their names and lose `at:` / `level:`: `suggestionsHandle`, `suggestions`, `isLoaded`, `assignPool`, `pickedField`, `canAssign`, `assignTooltip`, `assignAccessibilityLabel`, `removeLabel(for:)`, `assignPickedField()`, `removeSuggestion(fieldID:)`, `rereadSuggestions()`; `assignPicks` becomes `assignPick: String`, `suggestionErrors` becomes `suggestionError: String?`, `SuggestionWrite` is `.assigning` / `.removing(fieldID:)`; `levelPhrase` is deleted | One list | — |
| D-16 | `sqlAppendSuggestion` computes the next order over the type's rows and ends `ON CONFLICT(source_type_id, field_id) DO NOTHING`; `sqlEnsureSuggestion` upserts on `(source_type_id, field_id)` | AC-2.3 | — |

**Rules this plan bends.** None. The map's rule "Suggestions have a level" is already marked superseded; this PR makes the docs that still state it agree (STEP-9).

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `core/database/migrations/000069.sql` *(new)* | migration | `000064.sql` | A shipped step is never edited; same rebuild shape |
| `CopyTypeInput.Suggestions` *(new)* | field | `CopyTypeInput.Formats` | Same shape as the other ticks |
| `CopySourceTypeRequest.copy_suggestions` *(new)* | proto field | `copy_formats` | Same shape |
| `L10n.SourceTypes.suggestedMeaning`, `suggestedEmpty`, `suggestedPickerLabel`, `copySuggestions` *(new)* | L10n keys | `LevelCopy` (deleted); `copyFormats` | One list needs one set |
| `FakeStore.suggestionsByType`, `listTypeSuggestionsTypeIDs` *(new)* | test fake state | `suggestionsByLevel`, `listTypeSuggestionsLevels` (deleted) | Renamed with the key |
| `GenealogyStore.draftMetadataBoard(projectDir:sourceID:level:)` *(new)*, `CoreMethod.getDraftMetadataBoard` *(new)*, FakeStore `draftMetadataBoardEntries`, `draftMetadataBoardError`, `draftMetadataBoardCalls` *(new)* | store method | `GetDraftMetadataBoard` (Go, served) and `GoStore.mapMetadataEntry` | The engine read exists; Swift had no caller. Replaces `MetadataDraftHost.unsavedRows(from:)` |

**Builds on.** `000064.sql`'s rebuild; `readTypeBoards`' one read per distinct key; the `typeSuggestions()` patch; `PVCopyPartTick`.
**Deletes.** `seedSuggestion.Level`; `vocabkey.Level.HoldsMetadata` and Swift `Level.holdsMetadata` (D-18); `SourcePageContext.unsavedMetadataRows`, `MetadataDraftHost.unsavedRows(from:)` and `unsavedRowsAreTheTypesSuggestions` (D-17); `CatalogQueryKey.suggestionsTypeId`; `SourceTypeSuggestionList` (folded into `SourceTypeSuggestedFields`, D-9); `SourceTypeCopyModel`'s `suggestionsKey(at:)`, `suggestionsHandle(at:)` and its suggestion warm (D-19); every level argument in § 4's Suggestion API row and its `HoldsMetadata` guard; `CopyTypeInput.Levels`; the proto level fields (reserved); `CatalogQueryKey.typeSuggestionsKeys`, `suggestionsLevel`; `L10n.SourceTypes.LevelCopy`, `level(_:)` and their 18 `sourceTypes.suggested.level.*` keys; `SourceTypeCopyChoices.includedLevels`, `SourceTypeCopyModel.suggestionCount(at:)`, `levelAvailable`, `levelHint`, `levelsToCopy`; `SourceTypeCopyDialog.levelBinding`; `SourceTypePageModel.levelPhrase` and every `[Level: …]` dictionary; FakeStore's `suggestionsByLevel`, `listTypeSuggestionsErrorLevels`, `listTypeSuggestionsLevels`; the tests `TestRemoveTypeFieldDetachesOneLevel`, `TestTypeSuggestionRefusesAnyOtherLevel`, `aFieldCanSitInTwoLists`, `assigningWritesAtThatLevelOnly`, `aFailedLevelReadFailsOnlyThatList` (each tests a level that no longer exists). `MetadataLevels()` / `Level.metadataLevels` stay for owners, the parity test and S15-54 (D-18).
**Next adds.** S15-64 reads `Resolve` on boards that already list every field. S15-54 adds the Citation level with no suggestion change: its board reads the same list. S15-72's seed shares formats; one list per type keeps its derivation one call.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| An Artifact or graph board now shows Source-ish fields (Jurisdiction on an Artifact) | `MetadataBoardView` suggested group | Same rows and controls as today's suggestions; a value typed there is read nearest-first (S15-62) |
| An Add form starts with up to 21 empty rows (was 10 on census Artifacts), read from `GetDraftMetadataBoard` | `DraftMetadataBoardField` | The sheet scrolls its board today (S15-D14). The entries now carry `requirement`, which the row does not draw until S15-39; on a researcher's type whose formats read a field it does not suggest, that field's empty row now shows in the Add form as it already does on the saved board (S15-62 D-10). A read failure takes the path `readSuggestionsForAdd` has today (nil, the page banner) |
| A field suggested and also valued at another level of the same owner chain | `buildEntries` | One entry per field per owner, as today |

### Scale

At the map's Scale: a census Source with 60 Artifacts and 60 graphs. `listWorkspaces` reads 121 boards; suggestions are read once per distinct type (one query instead of three). Each board carries up to 21 suggested entries instead of 5 – 10, so a Source workspace reply carries about 2,500 entries; the Artifact list and graph rows draw values only. A board lists at most 30 suggested fields (map Scale); the largest seeded list is 21. The migration rewrites at most 26 × 21 rows on a seeded project. No write fans out: a suggestion add or remove patches one key.

### Edges

- **Assumptions.** `buildEntries` assumes each suggestion's field appears once (it fills `seen`); one row per (type, field) now guarantees it, where three levels could not repeat a field within one level either. `listWorkspaces` assumes every owner's type has a `typeBoard`; D-5 keeps the key set. The Swift `MetadataDraftHost.unsavedRows` assumes distinct field ids; the PK keeps them distinct. Test: T-4.
- **Neighbors.** A field suggested and also a needed head at this level: one entry, `Suggested` true (today's rule; T-4 holds it). A field suggested and dismissed on one owner: hidden only there (AC-1.2, T-4). A list-form-only head on an Artifact board: still not emitted unless suggested (T-4 keeps S15-62's case).
- **Removed inputs.** A field deleted from the vocabulary: its suggestion row cascades as today. Removing a suggestion leaves values (AC-2.4, T-2). The merge drops a field's later-level rows; nothing reads them.
- **Real data.** The derived lists over the whole shipped seed (26 types, run at planning base): census 21, the three certificates 17 each, church_register 17, manuscript 17, record_book 16, case_file 15, government_file 14, book 13, passenger_list 12, cemetery_marker 7, newspaper_item 7, website 7, family_bible 5, dna_match_report 5, interview 5, oral_testimony 5, journal_article 5, broadcast 5, statute 5, photograph 4, gedcom_file 4, correspondence 4, private_papers 3, court_report 3. Census in order: `creator jurisdiction schedule enumeration_district piece folio schedule_number dwelling_number family_number line_number item format provider url accessed_date citing database_title film_publication roll film_number item_number`. Worth a second look: `website` interleaves `format` between `creator` and `site_name` (its format reads them so); accept as derived.
- **Untrusted size.** None — the list is the app's own table, bounded by the vocabulary.

### Schema

Migration `core/database/migrations/000069.sql` *(new)*, with `-- migrate: foreign_keys off`:

```sql
CREATE TABLE source_type_metadata_fields__new (
	source_type_id BLOB NOT NULL REFERENCES source_types(id) ON DELETE CASCADE,
	field_id       BLOB NOT NULL REFERENCES source_metadata_fields(id) ON DELETE CASCADE,
	sort_order     INTEGER,
	PRIMARY KEY (source_type_id, field_id)
) STRICT;
INSERT INTO source_type_metadata_fields__new (source_type_id, field_id, sort_order)
SELECT source_type_id, field_id,
	ROW_NUMBER() OVER (PARTITION BY source_type_id ORDER BY lr, so, field_id) - 1
FROM (
	SELECT source_type_id, field_id, lr, so,
		ROW_NUMBER() OVER (PARTITION BY source_type_id, field_id ORDER BY lr, so) AS nth
	FROM (
		SELECT source_type_id, field_id,
			CASE level WHEN 'source' THEN 0 WHEN 'artifact' THEN 1 ELSE 2 END AS lr,
			COALESCE(sort_order, 0) AS so
		FROM source_type_metadata_fields
	)
)
WHERE nth = 1;

DROP TABLE source_type_metadata_fields;
ALTER TABLE source_type_metadata_fields__new RENAME TO source_type_metadata_fields;
CREATE INDEX source_type_metadata_fields_field_id_idx ON source_type_metadata_fields(field_id);
```

This SQL was run at planning on a sample (`page` at Source 0 and Artifact 3, `provider` at Artifact 0, `x` at graph NULL) and gave `page` 0, `provider` 1, `x` 2. Use it as written, with a header comment in the style of `000064.sql`. `catalogmodel` needs no change (same FKs, same bucket). Delete class: facet, unchanged. Audit: none, unchanged.

### Go core

| Package | Change |
| --- | --- |
| `core/database/sourcevocab` | D-2, D-3, D-6, D-16; package comment "per level" goes |
| `core/vocabkey` | D-18 |
| `core/database/sourcetypes` | D-13 comments only |
| `core/database/sourcemetadata` | D-5; comments on `WorkspaceEntry.Suggested` ("the type suggests the field"), `typeBoard`, `readTypeBoards`, `ListDraftWorkspace` |

Errors: unchanged (`sourcevocab.invalid` for a bad id).

### FFI

`api/proto/engine.proto` per D-4 (`CopySourceTypeRequest` uses fields 1 – 8 at the planning base, so 9 is free); handlers in `api/ffi/handlers/source_defs.go` drop the level (`suggestionsProto(c, typeID)`), `CopySourceType` passes `Suggestions: req.GetCopySuggestions()`. Regenerate with `./scripts/generate-proto.sh`, which writes `api/proto/engine/engine.pb.go` and `macos/App/Platform/Generated/engine.pb.swift` (it needs `protoc`, `protoc-gen-go` and `protoc-gen-swift`). Never hand-edit a generated file. `GetDraftMetadataBoard` needs no proto change. Handler test helpers `listSuggestions(t, dir, typeID)`, `listSuggestionLabels(t, dir, typeID)` and `suggestionIDs(t, dir, typeID)` drop their level; every request in the handler tests that set `Level:` on a suggestion RPC drops it.

### macOS

From S15-D32's inventory; final shape per D-9.

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Suggested fields section | Snowflake (rethink) | `macos/App/Features/SourceTypes/SourceTypeSuggestionList.swift` `SourceTypeSuggestedFields` | One view: `PVSectionHeader` with the count as `meta`, the hint, the meaning, the pool hint, rows, empty, spinner, retry, error, picker; identifiers `sourceTypes.suggested.*` with no level segment (`sourceTypes.suggested.assign`, `.remove.<fieldID>`, `.empty`, `.loadError`, `.error`, `.pool`, `.poolEmpty`) |
| Rows, picker, buttons | `PVCard`, `PVDivider`, `CatalogFieldDataTypeBadge`, `PVComboBox`, `PVIconButton` | as today | — |
| States | `PVCard` sunken dashed, `ProgressView`, `PVRetryCallout`, `PVCallout` danger | as today | One of each |
| Copy ticks | `PVCopyPartTick` | `SourceTypeCopyDialog.swift` | Four ticks; Suggested fields last |
| Associated fields | Snowflake | `SourceTypesListPane.swift` | No code change; the engine's number changes |

Models: D-19 and D-20. States: empty, loading, read failure, write failure, locked, as OL-5 and OL-6. Accessibility: OL-8.

### Strings

Per D-10. Removed: `sourceTypes.suggested.level.{source,artifact,graph}.{title,meaning,empty,pickerLabel,phrase,copyTick}`. Copy that named the old scope and changes: `assignField`, `assignFieldNamed`, `assignTipField`, `removeSuggestion`, `assignedBody`, `removedBodyNoValues`, `removedBodyWithValues` (rewritten whole with the type's label; their comments drop the level phrases). `sourceTypes.copy.loading` ("Reading the original's formats and suggested fields") stays.

## 7. Steps

**STEP-1 — Migration**
Files: `core/database/migrations/000069.sql` *(new)*. Skill: `add-catalog-migration`.
Do: D-1 with § 6 Schema's SQL. If `main` has taken `000069.sql` when you rebase, renumber to the next free file.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/` passes (schema hash, honesty). Other packages under `./core/database/...` fail at run time where a test writes `level`; STEP-2 and STEP-3 fix them.

**STEP-2 — Suggestion API, Copy and the seed without a level**
Files: `core/vocabkey/vocabkey.go`, `vocabkey_test.go`; `core/database/sourcevocab/sourcevocab.go` (with `Install`), `copy.go`, `registry.go`, `registry_suggestions.go`, `registry_test.go`, `sourcevocab_test.go`, `copy_test.go`; the callers `core/database/sourcecopy/sourcecopy_test.go`, `core/database/sourcetypes/sourcetypes_test.go`, `core/database/metadatafields/metadatafields_test.go`. Skill: `add-seeded-vocabulary`.
Do: D-2, D-3, D-6, D-16, D-18 (Go half). Fill `seedSuggestions` by a throwaway test in `sourcevocab` that prints `derivedSuggestions(t, st)` for each seeded type as Go source; paste its output; delete the throwaway test. Raw test inserts drop `level`. Rewrite the `sourcetypes_test.go` case "list counts the fields a type suggests at every level" as "list counts each suggested field once": two fields suggested → `SuggestedFields` 2.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/vocabkey/ ./core/database/sourcevocab/ ./core/database/sourcetypes/ ./core/database/metadatafields/ ./core/database/sourcecopy/` passes; T-1, T-2, T-3, T-6 among them.

**STEP-3 — Every board offers the type's list**
Files: `core/database/sourcemetadata/sourcemetadata.go`, `sourcemetadata_test.go`, `core/database/sourcetypes/sourcetypes.go` (comments).
Do: D-5, D-13. In `sourcemetadata_test.go`, each `AppendSuggestion(…, level)` drops the level. `TestOwnerTables` (seeded `birth_certificate`, now 17 suggestions) asserts by field id instead of length: the board holds `doc` suggested and unset, and holds `f2` suggested (it was "must not reach this owner"). T-4.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/...` passes.

**STEP-4 — FFI**
Files: `api/proto/engine.proto`, `api/proto/engine/engine.pb.go` and `macos/App/Platform/Generated/engine.pb.swift` (generated), `api/ffi/handlers/source_defs.go`, `api/ffi/handlers/source_defs_test.go`, and the level uses in `metadata_test.go`, `citation_render_test.go`, `artifacts_test.go`, `evidence_graphs_test.go`, `sources_test.go`. Skill: `add-ffi-handler`.
Do: D-4 and § 6 FFI. Delete `TestRemoveTypeFieldDetachesOneLevel` and `TestTypeSuggestionRefusesAnyOtherLevel`. A handler test that counted a seeded type's board entries at one level asserts the fields it needs by id instead. T-5.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/...` passes.

**STEP-5 — Swift store and cache**
Files: `macos/App/Platform/GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift`, `Level.swift`; `macos/ProvenenciaTests/OnboardingModelTests.swift` (conformer); `macos/App/Features/Workspace/Session/CatalogQueryKey.swift`, `CatalogQueryRegistry.swift`, `CatalogLastUpdated.swift`, `CatalogMutation.swift`, `PlaceRegistry.swift`; the page and copy models and the two previews (`SourceTypesView.swift`, `SourceTypePageView.swift`), changed only as far as compiling against one list; the Swift tests in § 4 that seed or key suggestions (`CatalogQueryRegistryTests.swift` level keys at lines 61, 461, 464, 917 – 942, 1012, 1061, 1187, 1548, 1641; `PlaceRegistryTests.swift` line 91; the others named there). Skill: `add-workspace-place`, `add-swift-test`.
Do: D-7, D-8, D-18 (Swift half). Each test that built a per-level key builds the one key.
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS'` builds and passes; T-7.

**STEP-6 — The Add forms read the engine's draft board**
Files: `GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift`, `CoreInvoke.swift`, `OnboardingModelTests.swift` (conformer stub), `macos/App/Features/Sources/SourcePageContext.swift`, `MetadataDraftHost.swift`, `macos/ProvenenciaTests/MetadataDraftHostTests.swift`, and the tests that open an Add form (`SourcePageModelTests.swift`, `SourceGraphFormModelTests.swift`, `MetadataModelTests.swift`, wherever they seed suggestions for it).
Do: D-17. T-10.
Check: `xcodebuild test …` (as STEP-5) passes.

**STEP-7 — The type page's one list** (after the board is agreed)
Files: `macos/App/Features/SourceTypes/SourceTypePageModel.swift`, `SourceTypeSuggestionList.swift`, `SourceTypePageView.swift`, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `macos/ProvenenciaTests/SourceTypePageModelTests.swift`. Skill: `add-ui-component`, `add-localized-string`.
Do: OL-1 – OL-6, OL-8, OL-W1; D-9, D-10, D-20. T-8.
Check: T-8 passes; the page matches frames D32-1 – D32-7 and D32-10.

**STEP-8 — Copy type's one tick**
Files: `SourceTypeCopyModel.swift`, `SourceTypeCopyDialog.swift`, `L10n.swift`, `Localizable.xcstrings`, `macos/ProvenenciaTests/SourceTypeCopyModelTests.swift`.
Do: OL-7; D-19. `aFailedListReadFailsTheSheetAndReloads` becomes `aFailedFormatsReadFailsTheSheetAndReloads` (the formats are the sheet's only read). T-9.
Check: T-9 passes; the sheet matches frames D32-8 and D32-9.

**STEP-9 — Docs**
Files: `docs/source-layer-data-model.md` § 4.3 (line 204: "the suggested fields, in the original's order"), § 5.2 (no `level`; PK `(source_type_id, field_id)`; line 259's paragraph: one ordered list per type, offered on every board) and § 5.5 (line 363 becomes "A type suggests fields once; every board offers them"); `docs/seeded-vocabulary.md` § 2.3 (lines 132, 153, 155: one list per type in first-read order; the census example as one list); `docs/macos-client-patterns.md` line 89 (`.wroteTypeSuggestions(typeId:edit:)`, the one `typeSuggestions` key of that type); `.agents/skills/add-seeded-vocabulary/SKILL.md` line 38 (one entry per `type_key`); `.agents/skills/add-workspace-place/SKILL.md` line 172 (`.wroteTypeSuggestions(typeId:edit:)`, one `typeSuggestions` key per type); `completed.md`; `deployment-plan.md` map row; this plan's status; `design/S15-D32-one-suggestion-list.md` → `design/archive/`; `design/README.md`.
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py` and `python3 scripts/check-guidance-names.py` pass; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/sourcevocab/sourcevocab_test.go` `TestAppendSuggestion` (rewritten, table) | append A, B → orders 0, 1; append A again → no error, list unchanged; a 15-byte id → `ErrInvalid` | AC-2.2, AC-2.3, D-16 |
| T-2 | Go | `sourcevocab_test.go` `TestDeleteSuggestion` *(new)* | A, B suggested; delete B → [A]; delete B again → no error, [A] | AC-2.4 |
| T-3 | Go | `core/database/sourcevocab/copy_test.go` (table) | `Suggestions: true` → the same fields in the same order; false → none | AC-3.1, AC-3.2, D-3 |
| T-4 | Go | `core/database/sourcemetadata/sourcemetadata_test.go` `TestEveryBoardOffersTheTypeList` *(new)*, fixture `applyWorld` and `newLevelOwner` | a user type (`sourcetypes.Create`) suggesting [doc, f2], a Source of that type created in the test, an Artifact and a graph of it: each board's suggested entries are doc, f2 in order; dismiss f2 on the Artifact → hidden there, still on the Source and the graph | AC-1.1, AC-1.2, D-5 |
| T-5 | Go | `api/ffi/handlers/source_defs_test.go` `TestAssignAndRemoveTypeField`, `TestListTypeSuggestions`, `TestCopySourceType` (rewritten) | assign → reply list and `suggested_field_count` equal; assign again → same list; `copy_suggestions` true → copy lists the same fields, false → none | AC-2.1 – AC-2.4, AC-3.1, AC-3.2, D-4 |
| T-6 | Go | `core/database/sourcevocab/registry_test.go` `TestSeedSuggestionsFollowFormats` (ordered) | one entry per type; each list equals `derivedSuggestions` in order; census starts `creator`, ends `item_number` | AC-1.1, D-6 |
| T-7 | Swift | `macos/ProvenenciaTests/CatalogQueryRegistryTests.swift` `wroteTypeSuggestionsPatchesTheListAndTheCount` (rewritten) | `.wroteTypeSuggestions(typeId:edit:)` patches that type's one key and its list count; another type's key unchanged | D-7 |
| T-8 | Swift | `macos/ProvenenciaTests/SourceTypePageModelTests.swift`: `warmingLoadsEachLevelsListInStoredOrder` → `warmingLoadsTheListInStoredOrder`; `aFailedListOffersNoAdd` → `aFailedReadOffersNoAdd`; `anAssignFailureStaysInItsList` → `anAssignFailureKeepsThePick`; `oneWriteAtATimeAcrossLists` → `oneWriteAtATime`; `assignPoolExcludesFieldsAlreadySuggested`, `assigningAppendsTheFieldAndUpdatesTheListCount`, `fieldsColumnShowsTheEnginesCountNotTheReplyLength`, `removingASuggestionKeepsTheFieldInThePool`, `removingASuggestionNoSourceUsesOmitsTheValueCount` kept with the level removed; `aFailedLevelReadFailsOnlyThatList`, `assigningWritesAtThatLevelOnly`, `aFieldCanSitInTwoLists` deleted | the one list's load, add, failure and single-write rules; toast text names "Census Sources" | AC-2.1, AC-2.2, AC-2.4, D-20 |
| T-9 | Swift | `macos/ProvenenciaTests/SourceTypeCopyModelTests.swift` `prefillsBlankLabelAndEveryTick`, `absentPartsReadUntickedAndAreNotSent`, `unticksSkipTheirParts`, `aFailedFormatsReadFailsTheSheetAndReloads` (rewritten) | four ticks; a type with `suggestedFieldCount` 21 → hint "21 fields", `copySuggestions` true; 0 → unavailable, false sent; formats read failure → `loadState` failed, `reload` rereads formats | AC-3.1 – AC-3.3, D-19 |
| T-10 | Swift | `macos/ProvenenciaTests/SourcePageModelTests.swift` `addArtifactStartsFromTheDraftBoard` *(new)* | FakeStore `draftMetadataBoardEntries["s1/artifact"]` = two entries → the Artifact form opens with those two rows; `draftMetadataBoardCalls` = [(s1, .artifact)]; with `draftMetadataBoardError` set → no form opens, the page banner shows the error | AC-1.4, D-17 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `core/database/sourcemetadata`, `api/ffi/handlers`, `CatalogQueryRegistryTests`, `PlaceRegistryTests`, `MetadataDraftHostTests`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — or none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated)
- [ ] Domain doc updated if a rule in docs/*.md changed: source-layer-data-model.md § 5.2 and § 5.5, seeded-vocabulary.md § 2.3
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

Sweep names (also across `macos/` and `core/`): `typeSuggestionsKeys`, `suggestionsLevel`, `suggestionsTypeId`, `typeSuggestions(project:typeId:level:`, `LevelCopy`, `suggestionsByLevel`, `includedLevels`, `levelsToCopy`, `CopyTypeInput.Levels`, `HoldsMetadata`, `holdsMetadata`, `unsavedRows(from:`, `unsavedMetadataRows`, `wroteTypeSuggestions(typeId:level:`, `per (type_key, level)`, "Suggestions have a level", "at each chosen level", "type and level", "and type suggestions".

## 10. Manual check

1. Make a new project. Add a census Source. Click Add Artifact: the sheet starts with 21 empty rows (AC-1.4); save it. Add a graph the same way. Open the Artifact sheet, the graph form and the Source's Metadata section: each offers the same 21 empty fields in the same order, Jurisdiction, Provider and Dwelling among them (AC-1.1). Dismiss Jurisdiction on the Artifact; the Source and the graph still show it (AC-1.2). The empty group's heading reads "Suggested by this type" (D-11).
2. Open Source types › Census: one list, "21 fields"; the types list reads 21 (AC-2.1). Add Column with Return: 22nd, toast names Census Sources (AC-2.2). Remove URL (AC-2.4). Resize across 1600pt with a pick in progress: it survives (OL-W1). Open a plugin type: read only (OL-6).
3. Copy Census: four ticks, Suggested fields "22 fields"; the copy's page shows the same list (AC-3.1). Copy again with the tick off: empty list (AC-3.2). Copy Letter (no suggestions): the tick disabled (AC-3.3).
4. Open the dogfood project, made before this PR: a type that suggested a field at two levels lists it once, at its Source-level place (AC-1.3).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A board in a dogfood project grows long | The rule is the user's; S15-64 and later dismissals handle it |
| The window function in the migration is not available | SQLite 3.25+ has `ROW_NUMBER`; the bundled `go-sqlite3` v1.14.50 ships 3.4x |
| Another spike's PR (S16-58, S16-59) edits `SourceTypePageModel.swift` | Whichever lands second rebases (map) |

**Stop and report if:**

- `readTypeBoards`, `listWorkspaces` or `sourcevocab`'s suggestion functions no longer match § 4 at your base.
- The migration fails `PRAGMA foreign_key_check` or the schema hash check after a correct rebuild.
- `derivedSuggestions` over the shipped seed returns a list other than § 6 Edges' counts.
- The agreed board draws a part § 6 macOS or the inventory does not list (a new kit piece, a grouping inside the list, reorder).
- Any board test needs the board heading or dismiss label changed to pass (D-11).

## 12. Open questions

None. The plan is blocked only on the board (D-9).

## 13. PR

**Title:** S15-63 — A type suggests fields once
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-63-type-suggests-fields-once.md`.
