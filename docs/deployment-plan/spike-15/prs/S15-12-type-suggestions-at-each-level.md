# S15-12 — Source types suggest fields at each level

**Status:** Blocked — on board S15-D6. Re-planned 2026-11-15 against S15-48's landed type page (#848) and S15-49's list (#852); the brief S15-D6 was rewritten the same day as an enhancement of S15-D27's page board. Everything that does not depend on frames is decided; D-6's list header, the section's count and the pool hint's place, and § 6 Strings' final wording, are filled from the agreed board
**Spike / slice:** Spike 15 · Slice 2 — Metadata at three levels
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D6](../design/S15-D6-source-type-suggestion-levels.md), board not drawn yet
**Board:** — (record the link, the section and its frame names here when the board is agreed; it is drawn on S15-D27's board, [Claude Design — Source Type Page](https://claude.ai/artifact/42ZuWus4ynyz7xUDwcF6zG). Then fill D-6 and § 6 from it, and describe each frame in words in § 6 macOS for an implementer who cannot open the link)
**Depends on:** S15-48 (landed [#848](https://github.com/mendahu/provenencia/pull/848)), S15-49 (landed [#852](https://github.com/mendahu/provenencia/pull/852)), S15-06 (landed #782), S15-08 (landed [#791](https://github.com/mendahu/provenencia/pull/791)), S15-10 (landed [#829](https://github.com/mendahu/provenencia/pull/829)), S15-11 (landed [#834](https://github.com/mendahu/provenencia/pull/834)), S15-D6
**Blocks:** S15-17, S15-18
**Branch:** `s15-12-type-suggestions-at-each-level`
**Version bump:** minor, 0.15.5 (today's `VERSION`) → **0.16.0** (or the next minor after `main`'s `VERSION` when you rebase): `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj` — a backward-compatible feature (the type page edits Artifact and Evidence graph suggestions); no wire shape change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-seeded-vocabulary`](../../../../.agents/skills/add-seeded-vocabulary/SKILL.md) (the suggestion join's owner), [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md) (a key gains a level), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`, `.cursor/rules/swift-tests.mdc`, `.cursor/rules/macos-client.mdc`
**Context:** [map § 6.6](../evidence-explained-citation-map.md), working rules: "Metadata lives at three levels with one vocabulary", "Suggestions have a level", "A Source type has its own page"; [`S15-06` plan](S15-06-type-suggestions-have-a-level.md) D-8 – D-12 and its Out rows (each names S15-12); [`S15-48` plan](S15-48-source-type-page.md) D-12 and its **Landed** note (the mutation, patches and list it left for this PR)
**Planned:** 2026-11-15 against `main` @ `180ab72`
**Review:** [`S15-12-type-suggestions-at-each-level.review.md`](S15-12-type-suggestions-at-each-level.review.md) — re-plan round 1 pending (rounds 1 – 2 of the side-pane plan are kept in the log). The board-dependent parts (D-6, § 6 Strings) get a short re-review when the board is agreed

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

A Source type's page edits three suggestion lists, one per level: the Source (the record), each Artifact (the copy used) and each Evidence graph (the item cited). Since S15-08 – S15-11 the Artifact sheet and the Evidence graph form show their type's suggestions at their level, but the page edits only the Source list, so every type suggests nothing on Artifacts and graphs. After this PR a researcher adds Line to Census's Evidence graph list and every Census graph's form offers Line. Return in a list's picker adds the picked field. The types list's Associated fields column counts all three lists.

**Why now.** Working rule "Suggestions have a level" binds S15-12. S15-06 left the key's level, the count and the fake's alias for this PR (its Out rows); S15-48 landed the page, the patch-carrying mutation `.wroteTypeSuggestions` and `SourceTypeSuggestionList` at the Source level for this PR to give a level. S15-17's format editor and S15-18's Copy from depend on it.

**What stays.** Each list's rows, picker and remove look and behave as today's one list (append only, no reorder: user, 2026-11-14). The engine's suggestion RPCs (`ListTypeSuggestions`, `AssignTypeField`, `RemoveTypeField`) already take a level and do not change shape. The page header, Details, the locked note, Delete, the leave confirm, the types list's layout, the Source page and the forms that read suggestions are unchanged.

## 2. User stories

**US-1.** As a researcher, on a type's page, I see its Source, Artifact and Evidence graph suggestions as three lists, so I know what each level offers.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Census suggests Jurisdiction, Schedule (source); Provider, URL (artifact); Item, Line (graph). Open Census's page | Under "Suggested fields", three lists in the order Source, Artifact, Evidence graph, each with its title, meaning and its own count "2 fields", rows in stored order (SL-1, SL-2) |
| AC-1.2 | Letter suggests Author (source) only | The Artifact and Evidence graph lists show their own empty copy; the Source list shows Author (SL-6) |
| AC-1.3 | The graph list's read fails (store error) | The retry Callout in place of the graph list's rows only; the Source and Artifact lists show their rows; Try again reads the graph list again (SL-6) |
| AC-1.4 | A plugin type with Cemetery (source) and Photographer (artifact) | Three read-only lists with titles, counts and empty copy; no hint, picker, plus or remove (SL-7) |

**US-2.** As a researcher, I add a field to one list and remove one from one list, and only that list changes.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Census graph list Item, Line. Pick Folio in the graph list's picker, press plus | `assignTypeField(level: .graph)` is called once; Folio is third in the graph list; the graph list's pick clears; the Source and Artifact lists and their picks are unchanged; toast body "Folio is now suggested on each Evidence graph of a Census Source." (SL-3) |
| AC-2.2 | Page is in Census's Source list | The Artifact list's picker offers Page; the Source list's picker does not (SL-3) |
| AC-2.3 | Page is in the Source and the Artifact lists. Remove Page from the Artifact list | `removeTypeField(level: .artifact)` once; Page leaves the Artifact list and stays in the Source list (SL-5) |
| AC-2.4 | An assign fails at the Artifact level | The error shows in a danger Callout above the Artifact list's rows; the Artifact pick stays; no other list shows an error (SL-6) |
| AC-2.5 | Add Line to Census's graph list, then open a Census Source's page and Add evidence graph | The form's board offers Line (slice Check) |
| AC-2.6 | Focus the graph list's picker. Type "fol", press Return, press Return again; then type "ent", press Return twice | The first Return picks Folio (the combo box's own behaviour); the second adds Folio, as plus does. Focus is back in the same picker, now empty; "ent" and two Returns add Entry. Return in the empty picker adds nothing (SL-4; user, 2026-11-15) |
| AC-2.7 | An add runs in the Source list | Every list's plus and remove buttons are disabled until it ends (SL-5) |

**US-3.** As a researcher, the types list's Associated fields column counts a type's suggestions at all three levels.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Census with 2 + 2 + 2 suggestions | Its row shows 6; sorting by the column orders by 6 (SL-8) |
| AC-3.2 | Add Folio to the graph list | The row shows 7 from the reply's count, with no list reload (SL-8, D-2) |
| AC-3.3 | The engine: a type with one `source` and one `graph` row of the same field | `sourcetypes.List` and `sourcetypes.SuggestedFields` both answer 2 (D-3) |

## 3. Scope

| In | Covered by |
| --- | --- |
| Three lists on an editable type, each with its own title, meaning, count, rows, picker, plus, remove, empty, loading, read failure and write failure (SL-1 – SL-3, SL-5, SL-6, SL-9, SL-10) | STEP-3 – STEP-5, AC-1.1 – AC-1.3, AC-2.1 – AC-2.4, AC-2.7 |
| Return adds the picked field and leaves focus in that list's empty picker; the picker and plus act as a small form whose submit handles Return, so `PVComboBox` gains no key handling (SL-4; user, 2026-11-15) | STEP-5, AC-2.6 |
| Read-only lists on a plugin's type (SL-7) | STEP-5, AC-1.4 |
| `CatalogQueryKey.typeSuggestions` and `.wroteTypeSuggestions` gain a level (S15-06 D-11 Out row; S15-48 D-12 "S15-12 adds `level`") | STEP-2, D-1, D-2 |
| The Associated fields count over all three levels in Go, the fake and the docs (S15-06 D-9 Out row; SL-8) | STEP-1, STEP-3, AC-3.1 – AC-3.3 |
| `FakeStore.suggestionsByType` alias dropped; its uses write `suggestionsByLevel[.source]` (S15-06 D-12 Out row) | STEP-2, D-7 |
| Copy that names a list (titles, meanings, empty copy, toasts, tooltips, spoken labels, pool hints, the section hint) | STEP-4, D-9 |
| The board's arrangement of a list's header and the pool hint; Wide unchanged (SL-1, SL-W1) | STEP-5, D-6 |

| Out | Home |
| --- | --- |
| Reordering suggestions | not planned (user, 2026-11-14) |
| Citation formats and Insert field | S15-17 |
| Copy from another type when adding a type | S15-18 |
| Seeding the shipped types' Artifact and graph suggestions | S15-19 |
| `SourcePageContext.unsavedMetadataRows` reading through the cached key | not planned (D-8) |
| Needed and used marks | S15-39 |
| Return-to-commit as a `PVComboBox` behaviour for every caller | not planned (D-10: the form's submit owns it) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Engine count | `core/database/sourcetypes/sourcetypes.go` `sqlSuggestedFields` (line ~52), `sqlList`, `List` (binds `vocabkey.LevelSource`, line ~154), `SuggestedFields` (line ~321), `Type.SuggestedFields` | Counts rows with `j.level = ?`, bound to `source`. Wrong for SL-8: only the Source list counts |
| Engine count test | `core/database/sourcetypes/sourcetypes_test.go` case "list counts the fields a type suggests" (line ~481) | Inserts one field at `source` and at `graph`; expects 1 |
| Suggestion RPCs | `api/ffi/handlers/source_defs.go` `ListTypeSuggestions`, `AssignTypeField`, `RemoveTypeField`, `UpdateSourceType` | Take a level; reply that level's list and `sourcetypes.SuggestedFields`. Right as they are |
| Handler tests | `api/ffi/handlers/source_defs_test.go`: the `UpdateSourceType` case (line ~531) compares `suggested_field_count` with the `source` list's length; `TestAssignAndRemoveTypeField` case "the reply counts the engine's source suggestions after the write" (line ~665) assigns three at `source` and one at `graph`, expects 3, then 1 after two source removes | Both assume the count is the source list's length; under D-3 they expect the sum (4, then 2) |
| Proto docs | `api/proto/engine.proto` `SourceType.suggested_field_count` (= 7, line ~341: "at the Source level"); `AssignTypeFieldResponse` / `RemoveTypeFieldResponse.suggested_field_count` | Say "at the Source level" or point at it |
| Swift count docs | `macos/App/Platform/GenealogyStore.swift` `CatalogSourceType.suggestedFieldCount` (line ~1228: "at the Source level — the list's third column") | Wrong after D-3 |
| Cache key | `macos/App/Features/Workspace/Session/CatalogQueryKey.swift` `static func typeSuggestions(project:typeId:)` (line ~83), ids `[typeId]`; doc "at the `source` level; the type page draws one list until it edits all three levels" | No level |
| Key descriptor | `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift` `case .typeSuggestions` (line ~279) | `whenHidden: .markStale`, `patches: [.typeSuggestions()]`, follows `source_vocabulary`; the loader passes `key.id` and `level: .source` |
| Mutation | `macos/App/Features/Workspace/Session/CatalogMutation.swift` `case wroteTypeSuggestions(typeId:edit:)` (line ~40) and `CatalogMutationKind.wroteTypeSuggestions` | No level. `.sourceWorkspace`'s `invalidateOn` lists the kind, so every cached Source page is marked stale (what makes AC-2.5 true); stays |
| Patches | `macos/App/Features/Workspace/Session/CatalogLastUpdated.swift` `CatalogQueryPatch.typeSuggestions()` (line ~378: matches `key.ownId == typeId`), `.typeSuggestionCount()` (line ~392) | The list patch has no level; the count patch is right as it is |
| Generic key users | `WorkspaceSession.swift` `apply(location:)` (`ownId` for entity pages only), `warmedKeys(deletedWith:)` (`ownId` for `deletedWith` kinds); `CatalogQueryPatch.applyHiddenPolicy(follows:)` | None reads `.typeSuggestions`' `ownId`: the kind is not an entity page and has no `deletedWith`, so a two-id key is safe (precedent `citationsByArtifact`) |
| Place | `macos/App/Features/Workspace/Session/PlaceRegistry.swift` spec `.sourceTypesDetail` `queryKeys` (line ~126) | Warms the types list, the fields list and one `typeSuggestions` key |
| Page model | `macos/App/Features/SourceTypes/SourceTypePageModel.swift` `suggestionsKey`, `warm()`, `suggestionsHandle`, `rereadSuggestions()`, `suggestions`, `suggestionError`, `assignPick`, `isAssigning`, `removingFieldID`, `canEditAssociations`, `assignPool`, `canAssign`, `pickedField`, `assignTooltip`, `assignAccessibilityLabel`, `assignPickedField()`, `removeSuggestion(fieldID:)` | One list, every write `level: .source`; one pick, one error, two write flags. Writes apply `.wroteTypeSuggestions(typeId:edit:)` and patch, with no reload |
| Suggestion view | `macos/App/Features/SourceTypes/SourceTypeSuggestionList.swift` `SourceTypeSuggestionList` (`body`, `content`, `spinner`, `emptySuggestions`, `suggestionRows`, `assignControl`, `assignListMaxHeight`, `poolRow`, `poolOptions`) | The whole Suggested fields section for one level: `PVSectionHeader(title: suggestedSectionLabel, meta: assignedCount)`, hint, write error, rows or empty or spinner or `PVRetryCallout(…, handle:, id: "sourceTypes.suggested.loadError", onRetry:)`, picker; ids `sourceTypes.suggested`, `.error`, `.loadError`, `.empty`, `.pool`, `.assign`, `.remove.<fieldId>` |
| Page view | `macos/App/Features/SourceTypes/SourceTypePageView.swift` `SourceTypePageContent` `secondary:` (line ~86) and its `#Preview` (`store.suggestionsByType["t1"]`) | Shows `SourceTypeSuggestionList(model:)` once the type is known |
| List column | `macos/App/Features/SourceTypes/SourceTypesListPane.swift` (column `L10n.SourceTypes.columnFields`) | Shows `suggestedFieldCount`; no code change |
| List preview | `macos/App/Features/SourceTypes/SourceTypesView.swift` `#Preview` (lines ~99 – 104, `store.suggestionsByType`) | Seeds `.source` rows through the alias |
| Combo box | `macos/App/DesignSystem/Components/ComboBox/PVComboBox.swift` `handleKey` (`.return` arm, line ~683): commits the highlighted row and returns `.handled`, else `.ignored`; `focus: PVFieldFocus?`; no `.onSubmit` of its own; the `selectedLabel` `onChange` clears the field when the selection is cleared | An ignored Return reaches the text field's submit, which an enclosing `.onSubmit` receives |
| Fake | `macos/App/Platform/FakeStore.swift` `suggestionsByLevel` (line ~156), `suggestionsByType` alias (line ~163), `listTypeSuggestionsError` (line ~233, every level), `listTypeSuggestionsLevels`, `suggestedFieldCount(typeID:)` (line ~1176: reads `.source` only), `suggestedFieldCountOverride`, `assignTypeField`, `removeTypeField` | Count reads one level; no level-scoped read error; no assign error hook |
| Copy | `macos/App/Platform/L10n.swift` `L10n.SourceTypes` `suggestedSectionLabel`, `suggestedHint`, `assignedCount`, `noAssignedBody`, `assignFieldLabel`, `assignField`, `assignFieldNamed(field:type:)`, `assignTipPoolEmpty`, `assignTipChoose`, `assignTipField(label:)`, `poolHint`, `poolHintEmpty`, `removeSuggestion(label:)`, `toastAssignedBody(field:type:)`, `toastRemovedBody(field:type:valueCount:)` (`removedBodyNoValues`, `removedBodyWithValues`), `suggestionsLoadErrorTitle`, `columnFields` (lines ~8018 – 8420) | No string names a level |
| Forms reading suggestions | `macos/App/Features/Sources/SourcePageContext.swift` `unsavedMetadataRows(level:)` (line ~153) | An uncached read per form open (S15-10 D-2); stays |
| Swift tests | `macos/ProvenenciaTests/SourceTypePageModelTests.swift` (`makePageModel(…suggestions:)` through the alias; `warmingLoadsThatTypesSuggestionsInStoredOrder`, `assignPoolExcludesFieldsAlreadySuggested`, `assigningAppendsTheFieldAndUpdatesTheListCount`, `warmingShowsOnlySourceLevelSuggestions`, `assigningWritesAtSourceLevelOnly`, `fieldsColumnShowsTheEnginesCountNotTheReplyLength`, `removingASuggestionKeepsTheFieldInThePool`, `removingASuggestionNoSourceUsesOmitsTheValueCount`); `CatalogQueryRegistryTests.swift` (lines ~27, ~61, ~461 `ownId == "t1"`, `wroteTypeSuggestionsInvalidatesOnlySourcePages` ~914, ~982, ~1031, `fieldRelabelInvalidatesEveryCachedSuggestionList` ~1150, `wroteTypeSuggestionsPatchesTheListAndTheCount` ~1279, ~1505, ~1598); `WorkspaceSessionTests.swift` (~504, ~556, ~633); `PlaceRegistryTests.swift` (~91, ~201); `MetadataModelTests.swift` (~212 – 225); `SourceTypesModelTests.swift` (~21) | Build on the one-level key, mutation and alias |
| Docs | `docs/macos-client-patterns.md` rule 2 (line ~89: `.wroteTypeSuggestions(typeId:edit:)`); `.agents/skills/add-workspace-place/SKILL.md` line ~170 (same) | Name the mutation without a level |

**Precedent.** S15-48 (#848) landed this PR's mutation, patches and view at one level: copy their shape and add `level`. `CatalogQueryKey.citationsByArtifact` is the two-id key with named accessors (`citationGraphId`, `citationArtifactId`) to copy for D-1. S15-06 (#782, its plan D-8 – D-12) threaded `Level` through the three RPCs, the store and the fake. S15-11's `MetadataDetailsColumn` is the precedent for one view drawn per owner instead of copies.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | **The key takes a level.** `CatalogQueryKey.typeSuggestions(project: ProjectKey, typeId: String, level: Level)` builds ids `[typeId, level.rawValue]`. Two accessors *(new)*, as `citationGraphId` and `citationArtifactId`: `var suggestionsTypeId: String` (`ids[0]`) and `var suggestionsLevel: Level` (`Level(rawValue: ids[1])!`), each with `precondition(kind == .typeSuggestions)`. One `static func typeSuggestionsKeys(project: ProjectKey, typeId: String) -> [CatalogQueryKey]` *(new)* maps `Level.metadataLevels` in order; the `.sourceTypesDetail` place's `queryKeys` and `SourceTypePageModel.warm()` both call it. The loader passes `key.suggestionsTypeId` and `key.suggestionsLevel`. The descriptor keeps `whenHidden: .markStale`, its patch and its `source_vocabulary` follow. The key's doc loses "until it edits all three levels" | S15-06 D-11 and its Next adds; each list reads, fails and patches on its own (SL-6), and the RPC replies one level (S15-06 D-8). `ownId` becomes nil for this kind, which nothing reads (§ 4 Generic key users) | One key holding all three levels — one failure blanks three lists and needs three RPCs per load; a `[typeId]` key with the level in a separate field — `CatalogQueryKey` has no such field, and ids are its identity |
| D-2 | **The mutation takes a level.** `CatalogMutation.wroteTypeSuggestions(typeId: String, level: Level, edit: CatalogTypeSuggestionEdit)`; its kind stays `.wroteTypeSuggestions`. `CatalogQueryPatch.typeSuggestions()` patches only the key whose `suggestionsTypeId == typeId` and `suggestionsLevel == level`; `typeSuggestionCount()` ignores the level (the count is the type's) | One mutation per write, as S15-48 D-12 left it; the reply carries one level's list and the type's count | A mutation per level; patching every level's key from one reply |
| D-3 | **The engine's count is the type's rows at every level.** `sqlSuggestedFields` becomes `SELECT COUNT(*) FROM source_type_metadata_fields j WHERE j.source_type_id = ` (no level); `List` runs `tx.Query(sqlList)` with no argument; `SuggestedFields` binds the type id only. A field at two levels counts twice. Doc comments on `Type.SuggestedFields`, `SuggestedFields`, `sqlSuggestedFields`, the three proto fields and `CatalogSourceType.suggestedFieldCount` say "at all three levels" | User, 2026-11-14 ("All three levels"); S15-06 D-9 kept the rule in one place for this change; the table's `CHECK` admits only metadata levels, so no filter is needed | Distinct fields — the user chose the sum; the column would disagree with the three counts added up |
| D-4 | **Per-level state on `SourceTypePageModel`.** `var assignPicks: [Level: String]` *(replaces `assignPick`)*; `private(set) var suggestionWrite: SuggestionWrite?` *(new; replaces `isAssigning` and `removingFieldID`)* with `enum SuggestionWrite: Equatable { case assigning(Level), removing(Level, fieldID: String) }` nested in the model; `private(set) var suggestionErrors: [Level: String]` *(replaces `suggestionError`; write failures only)*. Each per-list member takes a level: `suggestions(at:)` (the loaded value or `[]`), `suggestionsHandle(at:)`, `rereadSuggestions(at:)`, `assignPool(at:)` (fields not in **that** level's list), `pickedField(at:)`, `canAssign(at:)` (`pickedField(at:) != nil && suggestionWrite == nil && canEditAssociations`), `assignTooltip(at:)`, `assignAccessibilityLabel(at:)`, `assignPickedField(at:) async`, `removeSuggestion(fieldID:level:) async`. `canRemove: Bool` *(new)* is `suggestionWrite == nil && canEditAssociations`. A write clears only its own level's error; on success it clears its own level's pick | SL-3 – SL-6: a pick and a write error belong to one list; one write at a time is one value, not two flags (precedent `CitationComposerModel.Phase`); read state comes from `QueryHandle.reading`. The page mounts once per type (`viewIdentity`), so nothing clears on a type switch | A per-level sub-model class — three objects sharing one store, session and toast; three copies of today's members |
| D-5 | **Writes apply only the mutation.** Assign and remove call the store with their level and apply `session.apply(.wroteTypeSuggestions(typeId:level:edit:))` with the reply; no reload follows, as today | D-2; the reply carries everything the two keys show | A model-side patch |
| D-6 | **View.** `SourceTypeSuggestionList.swift` holds two views. `SourceTypeSuggestedFields` *(new)*, the section: `PVSectionHeader(title: L10n.SourceTypes.suggestedSectionLabel)`, the hint (editable type only), then one `SourceTypeSuggestionList` per `Level.metadataLevels`, stacked with `PVSpacing.space8` between them. `SourceTypeSuggestionList` takes `model` and `level` and draws one list: its header, meaning, the write error `PVCallout(tone: .danger, announces: true)`, the rows or empty card or spinner or `PVRetryCallout` (today's `content`, per level), and the picker. Today's members move into it with `level` threaded through. `SourceTypePageContent`'s `secondary:` shows `SourceTypeSuggestedFields(model:)`. **From the board, before Planned:** how a list's title, meaning and count sit (the recommended default is `PVSectionHeader(title: level title, meta: assignedCount)` with the meaning under it in micro italic muted, as today's hint); whether the section header keeps a count (default: none, each list has its own); whether the pool hint shows per list or once under the section (default: per list, as today). Wide is unchanged (SL-W1) | One view per level, not three copies (brief inventory); the section keeps its hint once | Three copies of the list; a kit list component — one call site; a segmented chooser — the brief rules it out (SL-1) |
| D-7 | **The fake.** Drop `FakeStore.suggestionsByType`; its uses write `suggestionsByLevel[.source]` (the two previews, `CatalogQueryRegistryTests`, `WorkspaceSessionTests`, `MetadataModelTests`, `SourceTypesModelTests`). `SourceTypePageModelTests.makePageModel(…suggestions:)` takes `[Level: [String: [CatalogTypeSuggestion]]]` and assigns `store.suggestionsByLevel`; existing callers pass `[.source: …]`. `FakeStore.suggestedFieldCount(typeID:)` sums every level's list for the type (override first, as today), so fixtures look like the engine; the rule itself is tested in Go (T-1, T-2). Three hooks *(new)*: `listTypeSuggestionsErrorLevels: Set<Level>?` gates `listTypeSuggestionsError` (nil means every level, today's behaviour for its callers); `assignTypeFieldError: Error?` throws before any write, at every level; `assignTypeFieldHold = FakeHold()` suspends `assignTypeField` before it writes, as `updateSourceTypeHold` does for `updateSourceType`. The page preview seeds Artifact rows (Provider, URL) and graph rows (Item, Line) on t1 so it shows all three lists | S15-06 D-12 and its Out row; the fake mirrors D-3; one error hook per method (`swift-tests.mdc`) | Keeping the alias — it names a one-level world |
| D-8 | `SourcePageContext.unsavedMetadataRows(level:)` keeps its uncached read | S15-10 D-2: a form's rows live as long as the form; a key warmed from the Source page would need its own invalidation for nothing the researcher sees | Reading through `.typeSuggestions(…level:)` |
| D-9 | **Copy.** One `static func level(_ level: Level) -> LevelCopy` *(new)* on `L10n.SourceTypes` with one switch (`.citation` is unreachable: `preconditionFailure`) returns `struct LevelCopy { let title, meaning, emptyBody, phrase: LocalizedStringResource }` (`phrase` is a format resource taking the type label). A private `SourceTypePageModel.levelPhrase(_ level: Level, type: CatalogSourceType) -> String` *(new)* builds `L10n.format(L10n.SourceTypes.level(level).phrase, type.label)` once; toasts, tooltips and spoken labels take `phrase:`. The section hint, the pool hints and the read-failure title stay as § 6 Strings says. Final wording is the board's | SL-9 and the brief's § 2.1; one switch over `Level`, not four that must stay in step; S15-17's Insert field groups can reuse the titles | A sentence per (level × use): 15 keys for one idea; a switch per string |
| D-10 | **Return adds through the form's submit.** In `SourceTypeSuggestionList`, the `HStack` holding the `PVComboBox` and the plus carries `.onSubmit { submitPick() }`. `submitPick()` does nothing unless `model.canAssign(at: level)`; else it runs `await model.assignPickedField(at: level)` and then sets `focusedPicker = level`. `@FocusState private var focusedPicker: Level?` is bound into the combo box with `focus: PVFieldFocus($focusedPicker, equals: level)`. The plus button keeps today's action and does not move focus. `PVComboBox` is not changed: its `.return` arm already returns `.ignored` when no row is highlighted, so the second Return reaches the field's submit | User, 2026-11-15 (S15-48 review): Return submits the small form, and the combo box stays an input. Re-focusing after the await is needed because the picker is disabled while the write runs, which drops focus | An `onCommit(via: .return)` that adds on the first Return — the researcher cannot check the pick first; key handling inside `PVComboBox` — every caller would gain a behaviour only this one wants |
| D-11 | No reorder, no new RPC, no proto shape change. Proto comment edits regenerate with `./scripts/generate-proto.sh` | User, 2026-11-14 ("Append only") | A `ReorderTypeFields` RPC |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `SourceTypeSuggestedFields` *(new)* | view | `SourceTypeSuggestionList.body` (today the section and the list in one) | It is the section part of that view, split so the list repeats per level (D-6) |
| `SourceTypeSuggestionList(model:level:)` | view (extend) | itself | Gains a level (S15-48 D-12 named this) |
| `CatalogQueryKey.suggestionsTypeId`, `.suggestionsLevel`, `.typeSuggestionsKeys(project:typeId:)` *(new)* | key accessors / helper | `citationGraphId`, `citationArtifactId` | Same pattern for a two-id key (D-1) |
| `SourceTypePageModel.SuggestionWrite` *(new)*, `assignPicks`, `suggestionErrors`, `canRemove` | enum / state (replace) | `assignPick`, `isAssigning`, `removingFieldID`, `suggestionError`; `CitationComposerModel.Phase` | Same state, per level; one value for the one write (D-4) |
| `L10n.SourceTypes.level(_:)`, `LevelCopy` *(new)* | L10n | `L10n.Sources` board labels ("Artifact metadata", "Evidence graph metadata"); searched `L10n.swift` for a `Level` display name: none | Those label a board in a form; these name a list on a type |
| `FakeStore.listTypeSuggestionsErrorLevels`, `assignTypeFieldError`, `assignTypeFieldHold` *(new)* | test hooks | `FakeStore.listTypeSuggestionsError`, `updateSourceTypeHold` | One error hook and one hold per method (D-7) |

**Builds on.** S15-48's `.wroteTypeSuggestions`, `typeSuggestions()`, `typeSuggestionCount()` and `SourceTypeSuggestionList`; S15-06's level-taking RPCs and `CatalogTypeSuggestionEdit`; `Level.metadataLevels`; `PVFieldFocus` and `PVComboBox`'s ignored Return.
**Deletes.** `FakeStore.suggestionsByType`; `SourceTypePageModel.assignPick`, `isAssigning`, `removingFieldID`, `suggestionError`, `suggestionsKey`, and the level-less `suggestionsHandle`, `rereadSuggestions()`, `suggestions`, `assignPool`, `canAssign`, `pickedField`, `assignTooltip`, `assignAccessibilityLabel`, `assignPickedField()`, `removeSuggestion(fieldID:)`; `L10n.SourceTypes.noAssignedBody` (`sourceTypes.suggested.noneBody`, replaced by the per-level empty copy); the tests `warmingShowsOnlySourceLevelSuggestions` and `assigningWritesAtSourceLevelOnly` (replaced by T-3 and T-5); the "until it edits all three levels" doc on the key.
**Next adds.** S15-17's Insert field reads a type's fields by level from the same three keys (`typeSuggestionsKeys`) and titles its groups with `L10n.SourceTypes.level(_:).title`. S15-18's Copy from applies `.wroteTypeSuggestions` once per level, or invalidates. S15-19 seeds rows that show here with no code change.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| Artifact and graph lists on a type page | `SourceTypePageModel` per-level members | The page mounts per type, so picks and errors are fresh; a type deleted elsewhere leaves the page (S15-48), and its three keys follow `source_vocabulary` as the one key did; a failed read shows per list (T-4) |
| Writes at `artifact` / `graph` | `.sourceWorkspace` (every cached Source page) | Already marked stale on `.wroteTypeSuggestions`; an open Artifact sheet or graph form keeps the rows it opened with (brief § 2) |
| A field at two levels | the pool, the count | Pool is per level (T-6); the count sums (T-1, T-2) |
| Return in the picker | `submitPick()` | Empty pick adds nothing; a write in flight disables the picker (T-9 covers the model gate; the manual check covers focus) |

### Scale

At the map's Scale (about 30 types, about 60 fields, up to about 12 suggestions per list): opening a type's page warms three suggestion keys (three `ListTypeSuggestions` calls, each a few rows) where today it warms one. An assign or remove is one write, two descriptor patches (one list, one row) and today's stale-mark of cached Source pages, with no read. A vocabulary write (a type or field create, relabel or delete) follows `source_vocabulary`: with `.markStale` it reloads the visible type's three keys and marks hidden ones stale. `assignPool(at:)` is O(fields) per list, three per render. No budget is set or leaned on.

### Edges

- **Assumptions.** `sqlAppendSuggestion` computes `MAX(sort_order)` per (type, level) (S15-06 D-4), so each list's order is its own; T-3 holds it on the Swift side.
- **Neighbors.** The same field in two lists: adding to one leaves the other (AC-2.2, T-6); removing from one leaves the other (AC-2.3, T-6). The count: one field at two levels counts 2 (T-1).
- **Removed inputs.** A removed suggestion never deletes the field or its values (today's toast clause, kept, T-6).
- **Real data.** The seed's suggestions are all `source` until S15-19, so every shipped type's count is unchanged on a fresh project. A project that assigned graph rows through no UI (none exists) has none.
- **Untrusted size.** None — lists come from the project's own catalog.

### Schema

None — no catalog change (`source_type_metadata_fields.level` exists since S15-06).

### Go core

| Package | Change |
| --- | --- |
| `core/database/sourcetypes` | `sqlSuggestedFields` drops `j.level = ? AND`; `List` runs `tx.Query(sqlList)` with no argument; `SuggestedFields` binds the type id only; doc comments per D-3. `vocabkey` stays imported if another use remains; else the import goes |

### FFI

`api/proto/engine.proto`: comments on `SourceType.suggested_field_count`, `AssignTypeFieldResponse.suggested_field_count` and `RemoveTypeFieldResponse.suggested_field_count` say the count is over all three levels. No shape change. Regenerate with `./scripts/generate-proto.sh`. Handlers unchanged.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Page columns | `PVPageColumns`, `PVColumnSplit.sourceTypePage` | `SourceTypePageView.swift` | Unchanged; the side column shows `SourceTypeSuggestedFields` |
| Suggested fields section | snowflake *(new view, same file)* | `SourceTypeSuggestionList.swift` `SourceTypeSuggestedFields` | `PVSectionHeader` "Suggested fields" (count per the board, D-6), the hint when editable, three lists. Id `sourceTypes.suggested` |
| One level's list | snowflake (extend) | `SourceTypeSuggestionList.swift` `SourceTypeSuggestionList(model:level:)` | Header per the board (D-6); meaning (micro italic, muted); write error `PVCallout(tone: .danger, announces: true)`; rows in `PVCard` as today; dashed sunken `PVCard` with `level(_:).emptyBody`; `ProgressView` while loading; `PVRetryCallout(title: suggestionsLoadErrorTitle, message:, handle:, id: "sourceTypes.suggested.<level>.loadError", onRetry: { model.rereadSuggestions(at: level) })`; `PVComboBox` + `PVIconButton(.plus)` when editable, with D-10's submit and focus. `.accessibilityElement(children: .contain)` with label "<title>, <count>". Ids `sourceTypes.suggested.<level>`, `.<level>.error`, `.<level>.loadError`, `.<level>.empty`, `.<level>.pool`, `.<level>.assign`, `.<level>.remove.<fieldId>` (`<level>` is `Level.rawValue`) |
| Associated fields column | — | `SourceTypesListPane.swift` | Unchanged code; the number is the engine's total |

States, per list, switching on `model.suggestionsHandle(at: level)?.reading` (nil → spinner): `.loading` → spinner; `.failed` → the retry Callout **in place of** the rows; `.loaded` → the rows, or the dashed empty card when empty. A write error `suggestionErrors[level]` shows above the rows whatever the read state. A plugin's type: no hint, no picker, no plus, no remove.

Accessibility: each picker's `label:` is "\(assignFieldLabel), \(level title)" ("Metadata field to assign, On each Evidence graph"), so the three read apart; the plus's spoken label is `assignAccessibilityLabel(at:)`; a row's remove reads `removeSuggestion(label:phrase:)`.

No UI test reads the old ids (`rg 'sourceTypes\.suggested' macos` finds only the view).

### Strings

New (`L10n.SourceTypes`, final wording from the board):

| Key | Default |
| --- | --- |
| `sourceTypes.suggested.level.source.title` / `.artifact.title` / `.graph.title` | "On the Source" / "On each Artifact" / "On each Evidence graph" |
| `sourceTypes.suggested.level.source.meaning` / `.artifact.meaning` / `.graph.meaning` | "The record as a whole" / "The copy you used: an image, a scan, a transcript" / "One item in the record: a household, an entry" |
| `sourceTypes.suggested.level.source.empty` / `.artifact.empty` / `.graph.empty` | "No Source fields yet. Assign the fields these records usually carry." / "No Artifact fields yet. Assign what you note about each copy, such as its provider or URL." / "No Evidence graph fields yet. Assign what you note about each item, such as its line or household." |
| `sourceTypes.suggested.level.source.phrase` / `.artifact.phrase` / `.graph.phrase` | "on each %@ Source" / "on each Artifact of a %@ Source" / "on each Evidence graph of a %@ Source" (argument: the type label) |

Changed (same keys; new default and arguments; comments say the last argument is a level phrase):

| Key | Default |
| --- | --- |
| `sourceTypes.suggested.hint` | "Suggestions, not a schema — a record may leave any of them blank" |
| `sourceTypes.suggested.assignTipField` → `assignTipField(label:phrase:)` | "Suggest %1$@ %2$@" |
| `sourceTypes.suggested.assignFieldNamed` → `assignFieldNamed(field:phrase:)` | "Suggest %1$@ %2$@" |
| `sourceTypes.suggested.remove` → `removeSuggestion(label:phrase:)` | "Stop suggesting %1$@ %2$@" |
| `sourceTypes.toast.assignedBody` → `toastAssignedBody(field:phrase:)` | "%1$@ is now suggested %2$@." |
| `sourceTypes.toast.removedBodyNoValues` / `removedBodyWithValues` → `toastRemovedBody(field:phrase:valueCount:)` | "%1$@ is no longer suggested %2$@. The field stays in this project’s vocabulary." / "%1$@ is no longer suggested %2$@. The field stays in this project’s vocabulary, and the %3$lld Sources, Artifacts and graphs already carrying a value keep it." |
| `sourceTypes.suggested.poolHintEmpty` | "Every field in the vocabulary is already in this list" |
| `sourceTypes.suggested.assignTipPoolEmpty` | "Every field is already in this list" |
| `sourceTypes.list.columnFields` comment | "how many metadata fields the type suggests at all three levels" (default unchanged) |

Unchanged and reused per list: `suggestedSectionLabel`, `assignedCount(count:)`, `assignPlaceholder`, `assignNoMatch`, `assignFieldLabel`, `assignField`, `assignTipChoose`, `poolHint`, `suggestionsLoadErrorTitle`, the toast titles. Removed: `sourceTypes.suggested.noneBody`. Old-scope copy checked: every string above that said "this type" or "for <type>" now names the list.

## 7. Steps

**STEP-1 — The count covers every level**
Files: `core/database/sourcetypes/sourcetypes.go`, `core/database/sourcetypes/sourcetypes_test.go`, `api/ffi/handlers/source_defs_test.go`, `api/proto/engine.proto`, generated code. Skill: `add-seeded-vocabulary`.
Do: D-3; T-1, T-2; proto comments; `./scripts/generate-proto.sh`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcetypes/... ./api/ffi/...` passes.

**STEP-2 — The key, the mutation and the fake take a level**
Files: `CatalogQueryKey.swift`, `CatalogQueryRegistry.swift`, `CatalogMutation.swift`, `CatalogLastUpdated.swift`, `PlaceRegistry.swift`, `FakeStore.swift` (alias only), `SourceTypePageModel.swift` (keys and calls only, every call still `.source`), `SourceTypePageView.swift` and `SourceTypesView.swift` previews, and the test sites in § 4. Skill: `add-workspace-place`.
Do: D-1, D-2, D-7's alias removal and `makePageModel` signature. Port `CatalogQueryRegistryTests` line ~461 to `suggestionsTypeId` / `suggestionsLevel` (and `ownId == nil`), `wroteTypeSuggestionsInvalidatesOnlySourcePages`, `wroteTypeSuggestionsPatchesTheListAndTheCount` (as T-8), `fieldRelabelInvalidatesEveryCachedSuggestionList`, and the `PlaceRegistryTests` `queryKeys` expectations (three keys in `Level.metadataLevels` order).
Check: `xcodebuild test` for `CatalogQueryRegistryTests`, `WorkspaceSessionTests`, `PlaceRegistryTests`, `MetadataModelTests`, `SourceTypePageModelTests`, `SourceTypesModelTests` passes.

**STEP-3 — The page model holds three lists**
Files: `SourceTypePageModel.swift`, `FakeStore.swift`, `SourceTypePageModelTests.swift`. Skill: `add-swift-test`.
Do: D-4, D-5; D-7's summing `suggestedFieldCount(typeID:)` and the three hooks; T-3 – T-7, T-9; retire `warmingShowsOnlySourceLevelSuggestions` and `assigningWritesAtSourceLevelOnly`; port the other suggestion tests to `at: .source`.
Check: `SourceTypePageModelTests` passes.

**STEP-4 — Copy names the list**
Files: `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`. Skill: `add-localized-string`.
Do: § 6 Strings, D-9.
Check: `python3 scripts/check-localizable-xcstrings.py` passes.

**STEP-5 — The page draws three lists**
Files: `SourceTypeSuggestionList.swift`, `SourceTypePageView.swift`. Skill: `add-ui-component`.
Do: D-6 in the board's arrangement; D-10; § 6 macOS ids and labels.
Check: the app builds with no Swift warning; the manual check's steps 1 – 6 match the board's frames at Regular and Wide.

**STEP-6 — Version**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj`.
Do: the header's bump.
Check: the three agree.

**STEP-7 — Docs**
Files: `completed.md`, `deployment-plan.md` (map row, design track link), this plan (status, Landed note), `design/S15-D6-source-type-suggestion-levels.md` → `design/archive/` (fix its relative links), `design/README.md`, `docs/macos-client-patterns.md`, `.agents/skills/add-workspace-place/SKILL.md`.
Do: per the Definition of done; `docs/macos-client-patterns.md` rule 2 and `add-workspace-place` line ~170 name `.wroteTypeSuggestions(typeId:level:edit:)`.
Check: `python3 scripts/check-plan-docs.py` passes; links resolve; `rg 'wroteTypeSuggestions\(typeId:edit:\)|suggestionsByType'` finds nothing outside `docs/deployment-plan/`.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/sourcetypes/sourcetypes_test.go` case "list counts the fields a type suggests at every level" (renamed) | One field at `source` and `graph` on Book; none on Letter → `List` Book 2, Letter 0; `SuggestedFields(Book)` 2 | AC-3.3, D-3 |
| T-2 | Go | `api/ffi/handlers/source_defs_test.go` `TestAssignAndRemoveTypeField` case renamed "the reply counts the engine's suggestions at every level after the write", and the `UpdateSourceType` count case | The existing data (three at `source`, Witness at `graph`) → 4 after the assigns, 2 after the two source removes; `UpdateSourceType`'s count equals the sum of the three `ListTypeSuggestions` lengths | AC-3.2, D-3 |
| T-3 | Swift | `SourceTypePageModelTests.warmingLoadsEachLevelsListInStoredOrder` *(new; replaces `warmingShowsOnlySourceLevelSuggestions`)* | Rows at three levels, stored order unlike label order → `suggestions(at:)` per level in stored order; `Set(store.listTypeSuggestionsLevels) == [.source, .artifact, .graph]` | AC-1.1, D-1 |
| T-4 | Swift | `SourceTypePageModelTests.aFailedLevelReadFailsOnlyThatList` *(new)* | `listTypeSuggestionsError = StoreBoom.boom`, `listTypeSuggestionsErrorLevels = [.graph]` → `suggestionsHandle(at: .graph)?.reading` is `.failed`; `.source` and `.artifact` are loaded with their rows; clear the error, `rereadSuggestions(at: .graph)` → loaded | AC-1.3, D-4 |
| T-5 | Swift | `SourceTypePageModelTests.assigningWritesAtThatLevelOnly` *(new; replaces `assigningWritesAtSourceLevelOnly`)* | Picks at `.source` and `.graph`; assign at `.graph` → the fake's graph list ends with the field; source and artifact lists unchanged; `assignPicks[.graph]` empty, `assignPicks[.source]` kept; toast body equals `toastAssignedBody(field:phrase:)` with the graph phrase | AC-2.1, D-4 |
| T-6 | Swift | `SourceTypePageModelTests.aFieldCanSitInTwoLists` *(new)* | Page at `.source` → `assignPool(at: .artifact)` has Page, `assignPool(at: .source)` does not; assign at `.artifact`, remove at `.artifact` → the source list still holds Page; the remove toast keeps the values clause when `usedBy > 0` | AC-2.2, AC-2.3 |
| T-7 | Swift | `SourceTypePageModelTests.anAssignFailureStaysInItsList` *(new)* and `fieldsColumnShowsTheEnginesCountNotTheReplyLength` (ported to a level) | `assignTypeFieldError` set, assign at `.artifact` → `suggestionErrors[.artifact]` set, others nil, pick kept. Count override 7 → the row shows 7 | AC-2.4, AC-3.2 |
| T-8 | Swift | `CatalogQueryRegistryTests.wroteTypeSuggestionsPatchesTheListAndTheCount` (ported) | t1's three keys and the types list warmed; apply `.wroteTypeSuggestions(typeId: "t1", level: .graph, edit:)` → the `.graph` key holds `edit.suggestions`, the `.source` and `.artifact` keys are unchanged, t1's row holds `edit.suggestedFieldCount`; no `listTypeSuggestions` or `listSourceTypes` call | D-1, D-2, D-5, AC-3.2 |
| T-9 | Swift | `SourceTypePageModelTests.oneWriteAtATimeAcrossLists` *(new)* | `store.assignTypeFieldHold.isOn = true` (D-7) → while an assign at `.source` is held, `canAssign(at: .graph)` and `canRemove` are false; after it ends both are true again; with an empty pick `canAssign(at:)` is false, so D-10's submit adds nothing | AC-2.6 (model gate), AC-2.7, D-4, D-10 |
| T-10 | Swift | `PlaceRegistryTests` (ported) | `.sourceTypesDetail`'s `queryKeys` for `typ-1` → the types list, the fields list, then `.typeSuggestions` at `.source`, `.artifact`, `.graph` | D-1 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `CatalogQueryRegistryTests` (key shape), `WorkspaceSessionTests`, `MetadataModelTests`.

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
- [ ] Domain doc updated if a rule in docs/*.md changed: docs/macos-client-patterns.md rule 2 and add-workspace-place (the mutation carries a level)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

Run on a Mac with the app built (the `run` skill), at Regular and with the window stretched past 1600pt of pane.

1. Open a dogfood project; Source types; open Census. Under Suggested fields, three lists in the board's arrangement; the Source list holds today's seeded fields; the Artifact and Evidence graph lists show their empty copy (AC-1.1, AC-1.2).
2. In the Evidence graph list add Item, then Line, with plus. Each lands last; the list's count reads 2; the toast names "each Evidence graph of a Census Source"; Back to the list: Census's Associated fields equals the three lists' counts added up; sort by the column (AC-3.1).
3. In the Artifact list add Page (also in the Source list if seeded there). Remove it from the Artifact list; the Source list keeps it (AC-2.2, AC-2.3).
4. In the Evidence graph list's picker type "fol", press Return, then Return again: Folio is added and focus is back in the empty picker. Type "ent", press Return twice: Entry is added. Press Return in the empty picker: nothing is added (AC-2.6).
5. Open a plugin type's page (the `SourceTypePageView` `#Preview` with a plugin row, or a project with a plugin type): read-only lists with counts and empty copy, no picker, plus or remove (AC-1.4). Stretch the window across 1600pt of pane: the same centred pair; a pick in progress survives.
6. Slice Check: open a Census Source, Add evidence graph: Item and Line are offered on the form's board. Open an existing graph's Edit: Line shows as a suggestion (AC-2.5).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| The board draws something the model cannot hold (a draft of a list, a reorder, a chooser) | Stop: the brief's § 2.2, SL-1 and D-11 rule them out |
| A test reads the count as the Source list's length | T-2 ports that comparison to the sum |
| Re-focusing after the write lands before the picker is enabled again | D-10 sets focus after the `await`, when `suggestionWrite` is nil; the manual check step 4 confirms it |

**Stop and report if:**

- `sqlAppendSuggestion` no longer takes `MAX(sort_order)` per (type, level).
- `.sourceWorkspace`'s `invalidateOn` no longer lists `.wroteTypeSuggestions` (AC-2.5 would need a new path).
- A generic session path reads `ownId` of a `.typeSuggestions` key (D-1 assumes none does).
- `PVComboBox` consumes Return when no row is highlighted, or an enclosing `.onSubmit` never fires from its field (D-10 would need a change to the kit component).
- The agreed board's arrangement needs a kit component the brief's inventory does not list.
- The board's copy needs a sentence per (level × use) that `LevelCopy.phrase` cannot build.

## 12. Open questions

- Board S15-D6: how a list's title, meaning and count sit; whether the section header keeps a count; where the pool hint sits; any copy change (D-6, § 6 Strings). Recommended: D-6's defaults unless the board draws otherwise; then the plan's review re-runs on D-6 and § 6, and the status moves to Planned.

## 13. PR

**Title:** S15-12 — Source types suggest fields at each level
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-12-type-suggestions-at-each-level.md`.
