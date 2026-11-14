# S15-12 — Source types suggest fields at each level

**Status:** Blocked — on board S15-D6
**Spike / slice:** Spike 15 · Slice 2 — Metadata at three levels
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D6](../design/S15-D6-source-type-suggestion-levels.md), board not drawn yet
**Board:** — (record the link and the frame names here when the board is agreed; then fill the arrangement into D-6 and § 6 macOS)
**Depends on:** S15-06 (landed), S15-08 (landed [#791](https://github.com/mendahu/provenencia/pull/791)), S15-10 (landed [#829](https://github.com/mendahu/provenencia/pull/829)), S15-11 (landed [#834](https://github.com/mendahu/provenencia/pull/834)), S15-D6
**Blocks:** S15-17
**Branch:** `s15-12-type-suggestions-at-each-level`
**Version bump:** minor, 0.15.0 → **0.16.0** (or the next minor after `main`'s `VERSION` when you rebase): `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj` — a backward-compatible feature (the type page edits Artifact and graph suggestions); no wire shape changes ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-seeded-vocabulary`](../../../../.agents/skills/add-seeded-vocabulary/SKILL.md) (the suggestion join's owner), [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md) (a key gains a level), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`
**Context:** [map § 6.6](../evidence-explained-citation-map.md), working rules: "Metadata lives at three levels with one vocabulary", "Suggestions have a level", "One level type"; [`S15-06` plan](S15-06-type-suggestions-have-a-level.md) D-8, D-9, D-11, D-12 and its Out rows (each names S15-12)
**Planned:** 2026-11-14 against `main` @ `43fd47e`
**Review:** [`S15-12-type-suggestions-at-each-level.review.md`](S15-12-type-suggestions-at-each-level.review.md) — round 1 answered; round 2 pending; reruns on the board-dependent parts once the board is agreed

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

The Source types page edits three suggestion lists for the selected type, one per level: the Source (the record), each Artifact (the copy used) and each Evidence graph (the item cited). Since S15-08 – S15-11 the Artifact sheet and the Evidence graph form show their type's suggestions at their level, but nothing in the app can set them, so every type suggests nothing there. After this PR a researcher adds Line to Census's Evidence graph list and every Census graph's form offers Line. The types list's Associated fields column counts all three lists.

**Why now.** Working rule "Suggestions have a level" binds S15-12; S15-06 left the key, the mutations, the count and the fake for this PR (its Out rows). S15-17's format editor lists fields by level and depends on it.

**What stays.** Each list's rows, picker and remove look and behave as today's one list (append only, no reorder: user, 2026-11-14). The engine's suggestion RPCs (`ListTypeSuggestions`, `AssignTypeField`, `RemoveTypeField`) already take a level and do not change shape. The type form, the locked note, the add-type note, the delete flow, the Source page and the forms that read suggestions are unchanged.

## 2. User stories

**US-1.** As a researcher, on a type's detail pane, I see its Source, Artifact and Evidence graph suggestions as three lists, so I know what each level offers.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Census suggests Jurisdiction, Schedule (source); Provider, URL (artifact); Item, Line (graph). Select Census | Three lists in the order Source, Artifact, Evidence graph, each in its stored order with its own count: "2 fields", "2 fields", "2 fields" (SL-1, SL-2) |
| AC-1.2 | Letter suggests Author (source) only | The Artifact and Evidence graph lists show their own empty copy; the Source list shows Author (SL-5) |
| AC-1.3 | The graph list's read fails (store error) | A danger Callout with the error's message inside the graph list only; the Source and Artifact lists show their rows (SL-5) |
| AC-1.4 | A plugin type with Cemetery (source) and Photographer (artifact) | Three read-only lists: rows, counts and empty copy; no picker, plus or remove (SL-6) |

**US-2.** As a researcher, I add a field to one list and remove one from one list, and only that list changes.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Census graph list Item, Line. Pick Folio in the graph list's picker, press plus | `assignTypeField(level: .graph)` is called once; Folio is third in the graph list; the graph list's pick clears; the Source and Artifact lists and their picks are unchanged; toast "Folio is now suggested on each Evidence graph of a Census Source." (SL-3) |
| AC-2.2 | Page is in Census's Source list | The Artifact list's picker offers Page; the Source list's picker does not (SL-3) |
| AC-2.3 | Page is in the Source and the Artifact lists. Remove Page from the Artifact list | `removeTypeField(level: .artifact)` once; Page leaves the Artifact list and stays in the Source list (SL-4) |
| AC-2.4 | An assign fails at the Artifact level | The error shows in the Artifact list's Callout; the pick stays; no other list shows an error (SL-5) |
| AC-2.5 | Add Line to Census's graph list, then open the Source page of a Census Source and Add evidence graph | The form's board offers Line (slice Check) |

**US-3.** As a researcher, the types list's Associated fields column counts a type's suggestions at all three levels.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Census with 2 + 2 + 2 suggestions | Its row shows 6; sorting by the column orders by 6 (SL-8) |
| AC-3.2 | Add Folio to the graph list | The row shows 7 from the reply's count, with no list reload (SL-8, D-5) |
| AC-3.3 | The engine: a type with one `source` and one `graph` row of the same field | `sourcetypes.List` and `sourcetypes.SuggestedFields` both answer 2 (D-5) |

## 3. Scope

| In | Covered by |
| --- | --- |
| Three lists on an editable type, each with its own rows, count, picker, plus, remove, empty, loading and failure (SL-1 – SL-5, SL-9, SL-10) | STEP-3 – STEP-5, AC-1.1 – AC-1.3, AC-2.1 – AC-2.4 |
| Read-only lists on a plugin type (SL-6); the add-type note unchanged (SL-7) | STEP-5, AC-1.4 |
| The board's arrangement and Wide answer (SL-1, SL-W1) | STEP-5 |
| `CatalogQueryKey.typeSuggestions` and the two type–field mutations gain a level (S15-06 D-11 Out row) | STEP-2, D-1, D-2 |
| The Associated fields count over all three levels in Go, the fake and the docs (S15-06 D-9 Out row; SL-8) | STEP-1, STEP-2, AC-3.1 – AC-3.3 |
| `FakeStore.suggestionsByType` alias dropped; its call sites use `suggestionsByLevel[.source]` (S15-06 D-12 Out row) | STEP-2, D-7 |
| Copy that names a list (toasts, tooltips, spoken labels, empty lists, titles) | STEP-4 |

| Out | Home |
| --- | --- |
| Reordering suggestions | not planned (user, 2026-11-14) |
| Citation formats and Insert field | S15-17 |
| Copy from another type when adding a type | S15-18 |
| Seeding the shipped types' Artifact and graph suggestions | S15-19 |
| `SourcePageContext.unsavedMetadataRows` reading through the cached key | not planned (D-8) |
| Needed and used marks | S15-39 |
| The types list's own Wide layout | [`docs/ideas/wide-layout.md`](../../../ideas/wide-layout.md) (Source types row) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Engine count | `core/database/sourcetypes/sourcetypes.go` `sqlSuggestedFields`, `sqlList`, `List`, `SuggestedFields`, `Type.SuggestedFields` | Counts rows with `j.level = ?`, bound to `vocabkey.LevelSource` in `List` and `SuggestedFields`. Wrong for SL-8: only the Source list counts |
| Engine count test | `core/database/sourcetypes/sourcetypes_test.go` case "list counts the fields a type suggests" | Inserts one field at `source` and `graph`; expects 1 |
| Suggestion RPCs | `api/ffi/handlers/source_defs.go` `ListTypeSuggestions`, `AssignTypeField`, `RemoveTypeField`, `suggestionsProto`, `UpdateSourceType` | Take a level; reply that level's list and `sourcetypes.SuggestedFields`. Right as they are |
| Handler tests | `api/ffi/handlers/source_defs_test.go` `TestAssignAndRemoveTypeField` (its case "the reply counts the engine's source suggestions after the write" assigns Folio, Officiant at `source`, Witness at `graph`, then Parish at `source`, and expects 3, then 1 after two source removes); the `UpdateSourceType` case at line ~533 comparing `suggested_field_count` with `len(list.Suggestions)` | Both assume the count is the source list's length; under D-3 the case expects 4 then 2, and the `UpdateSourceType` case compares with the sum over levels |
| Proto docs | `api/proto/engine.proto` `SourceType.suggested_field_count` (= 7), `AssignTypeFieldResponse` / `RemoveTypeFieldResponse.suggested_field_count` | Comment says "at the Source level" |
| Swift count docs | `macos/App/Platform/GenealogyStore.swift` `CatalogSourceType.suggestedFieldCount`, `CatalogTypeSuggestionEdit` | Doc says "at the Source level" |
| Cache key | `macos/App/Features/Workspace/Session/CatalogQueryKey.swift` `case typeSuggestions(project:typeId:)` | No level; doc says it is the `source` list until S15-12 |
| Key descriptor | `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift` `case .typeSuggestions` | Loads `listTypeSuggestions(level: .source)`; invalidation names `.key(.typeSuggestions(project:typeId:))` |
| Mutations | `macos/App/Features/Workspace/Session/CatalogMutation.swift` `assignedTypeSuggestion(typeId:)`, `removedTypeSuggestion(typeId:)` and their `Kind` arms | No level. `.sourceWorkspace` invalidates `.allCached(.sourceWorkspace)` on both (its `default:` arm), which is what makes AC-2.5 true; it stays |
| Place | `macos/App/Features/Workspace/Session/PlaceRegistry.swift` spec `.sourceTypesDetail` `queryKeys` | Warms one `typeSuggestions` key |
| Model | `macos/App/Features/SourceTypes/SourceTypesModel.swift` `suggestionsKey(for:typeID:)`, `warmSuggestions(for:)`, `suggestions`, `isLoadingSuggestions`, `suggestionError`, `assignPick`, `isAssigning`, `removingFieldID`, `assignPool`, `canAssign`, `pickedField`, `assignTooltip`, `assignAccessibilityLabel`, `assignPickedField()`, `removeSuggestion(fieldID:)`, `patchSuggestions(_:typeID:)`, `applySelection`, `clearHistorySelection`, `openAdd` | One list, every call `level: .source`; one pick, one error |
| View | `macos/App/Features/SourceTypes/SourceTypesDetailPane.swift` `suggestedFields(isLocked:)`, `emptySuggestions`, `suggestionRows(isLocked:)`, `assignControl`, `assignListMaxHeight`, `poolRow`, `poolOptions` | One section; a failed read shows nothing |
| List column | `macos/App/Features/SourceTypes/SourceTypesListPane.swift` (column `L10n.SourceTypes.columnFields`) | Shows `suggestedFieldCount`; no change needed |
| Preview | `macos/App/Features/SourceTypes/SourceTypesView.swift` `#Preview` | Seeds `store.suggestionsByType["t2"]`, `["t4"]` |
| Fake | `macos/App/Platform/FakeStore.swift` `suggestionsByLevel`, `suggestionsByType` (alias), `suggestedFieldCount(typeID:)`, `suggestedFieldCountOverride` | Count reads the `.source` level only |
| Copy | `macos/App/Platform/L10n.swift` `L10n.SourceTypes` `suggestedHint`, `assignedCount`, `noAssignedBody`, `assignFieldNamed`, `assignTipField`, `removeSuggestion`, `toastAssignedBody`, `removedBodyNoValues`, `removedBodyWithValues`, `columnFields` | Copy says "this type" / "for <type>"; none names a level |
| Forms reading suggestions | `macos/App/Features/Sources/SourcePageContext.swift` `unsavedMetadataRows(level:)` | An uncached read per form open (S15-10 D-2); stays |
| Swift tests | `macos/ProvenenciaTests/SourceTypesModelTests.swift` (`makeModel(suggestions:)`, `warmSuggestions`, `selectingShowsOnlySourceLevelSuggestions`, `assigningWritesAtSourceLevelOnly`, `fieldsColumnShowsTheEnginesCountNotTheReplyLength`, `removingASuggestion…`, `assignPoolExcludesFieldsAlreadySuggested`); `CatalogQueryRegistryTests.swift`, `WorkspaceSessionTests.swift`, `MetadataModelTests.swift`, `PlaceRegistryTests.swift` (lines ~93, ~203: `queryKeys` expectations) — the key and 13 `suggestionsByType` uses | Build on the one-level key and alias |
| Docs | `docs/macos-client-patterns.md` rule 2 paragraph (`.assignedTypeSuggestion`, `.removedTypeSuggestion`); `.agents/skills/add-catalog-delete/SKILL.md` line 115 ("type erase busts `typeSuggestions`") | Name the mutations without a level; stay true |

**Precedent.** S15-06 (its plan D-8 – D-12) threaded a level through the same three RPCs, the store and the fake: copy how it passes `Level` and how `CatalogTypeSuggestionEdit` patches the Fields column. S15-11's `MetadataDetailsColumn` (one view taking an owner, drawn for Artifacts and graphs) is the precedent for one list view drawn per level instead of copies.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `CatalogQueryKey.typeSuggestions(project: ProjectKey, typeId: String, level: Level)`. The loader passes `level`. `Kind` is unchanged. One `static func typeSuggestionsKeys(project: ProjectKey, typeId: String) -> [CatalogQueryKey]` *(new)* on `CatalogQueryKey` maps `Level.metadataLevels` in order; the `.sourceTypesDetail` place's `queryKeys` and `SourceTypesModel.warmSuggestions(for:)` both call it. The descriptor gains `whenHidden: .markStale` | S15-06 D-11 and its Next adds; each list reads, fails and patches on its own (SL-5). `.markStale`: the key follows `source_vocabulary`, so with the default `.revalidate` every type or field write would reload every visited type's three keys (about 90 RPCs at Scale); hidden lists now reload when next shown, as `sourcesList` and `sourceWorkspace` do (review M-2). One helper lists the keys once (review M-8) | One key holding all three levels — one failure would blank three lists, and the RPC replies one level (S15-06 D-8); keeping `.revalidate` — triples today's fan-out |
| D-2 | **One patch-only mutation.** `CatalogMutation.assignedTypeSuggestion(typeId:)` and `.removedTypeSuggestion(typeId:)` are replaced by `.wroteTypeSuggestions(typeId: String, level: Level, edit: CatalogTypeSuggestionEdit)` *(new)*, with one `Kind` arm. Its only invalidation is `.sourceWorkspace`'s `.allCached(.sourceWorkspace)` (AC-2.5). Two descriptor patches *(new)* in `CatalogLastUpdated.swift` beside `metadataBoard()`: `CatalogQueryPatch.typeSuggestions()` writes `edit.suggestions` into `.typeSuggestions(project, typeId, level)` (`patchCached`, only when that key is cached), on the `.typeSuggestions` descriptor's `patches`; `CatalogQueryPatch.typeSuggestionCount()` sets the row's `suggestedFieldCount` to `edit.suggestedFieldCount` in `.sourceTypesList`, on that descriptor's `patches`. `.typeSuggestions` drops `invalidateOn` for the old cases | Today apply invalidates the visible key and `setQueryValue` then restarts the load (`WorkspaceSession.replaceValue`), so every write re-reads the list its reply carried; `.wroteMetadataBoard` + `CatalogQueryPatch.metadataBoard()` is the codebase's pattern for a write that returns its rows (`docs/macos-client-patterns.md` rule 4; review M-1). S15-18's Copy from reuses the same patch | Two mutations plus model-side `setQueryValue` patches — a second mechanism and a reload per write |
| D-3 | The engine's count is the type's rows at every level: `sqlSuggestedFields` becomes `SELECT COUNT(*) FROM source_type_metadata_fields j WHERE j.source_type_id = ` (no level); `List` and `SuggestedFields` bind no level. A field at two levels counts twice. Doc comments on `Type.SuggestedFields`, `SuggestedFields`, `sqlSuggestedFields`, the three proto fields and the two Swift types say "at all three levels" | User, 2026-11-14 ("All three levels"); S15-06 D-9 kept the rule in one place for this change; the table's `CHECK` admits only metadata levels, so no filter is needed | Distinct fields — the user chose the sum; the column would disagree with the three counts added up |
| D-4 | Per-level state in `SourceTypesModel`: `var assignPicks: [Level: String]` *(replaces `assignPick`)*; `private(set) var suggestionWrite: SuggestionWrite?` *(new; replaces `isAssigning` and `removingFieldID`, the latter read only as non-nil by `SourceTypesDetailPane` line ~404)*, `enum SuggestionWrite: Equatable { case assigning(Level), removing(Level) }` nested in the model; `var suggestionErrors: [Level: String]` *(replaces `suggestionError`; write failures only)*. Each per-list member takes `level`: `suggestions(at:)` (the loaded value or `[]`), `suggestionsHandle(at:) -> QueryHandle<[CatalogTypeSuggestion]>?` *(new; the view switches on its `reading`)*, `rereadSuggestions(at:)` *(new; `session.reread` of that key, for Try again)*, `assignPool(at:)` (fields not in **that** level's list), `pickedField(at:)`, `canAssign(at:)` (`pickedField(at:) != nil`, `suggestionWrite == nil`, `canEditAssociations`), `assignTooltip(at:)`, `assignAccessibilityLabel(at:)`, `assignPickedField(at:) async`, `removeSuggestion(fieldID:level:) async`, `static suggestionsKey(for:typeID:level:)`. Removes and the plus are disabled while `suggestionWrite != nil`. `applySelection`, `clearHistorySelection`, `openAdd` and `confirmPendingImpact` clear `assignPicks` and `suggestionErrors`. A write still running when the selection changes patches its own type's key through D-2 and toasts as today | SL-3 – SL-5: a pick and a write error belong to one list; "one write at a time" is one value, not two flags (review M-4, lens Q9, precedent `CitationComposerModel.Phase`); read state comes from `QueryHandle.reading`, not hand-derived accessors (`add-workspace-place` "Stale-while-revalidate" row; review M-3) | `isLoadingSuggestions(at:)` + `suggestionsFailure(at:)` — re-derive `reading`; a per-level sub-model class — three objects sharing one store, session and toast |
| D-5 | Assign and remove apply only `session.apply(.wroteTypeSuggestions(typeId:level:edit:))` with the reply; the descriptor patches (D-2) write the level's list and the row's count. `SourceTypesModel.patchSuggestions` and the count branch of `patchTypesList` go. No reload follows | D-2; the reply carries everything the two keys show | Model-side patches — the cache rule would live in a feature |
| D-6 | **View.** `SourceTypeSuggestionList` *(new)*, `macos/App/Features/SourceTypes/SourceTypeSuggestionList.swift`: one level's list (title, meaning, count, rows, empty, loading, failure Callout, picker and plus when editable), taking `model` and `level` and `isLocked`. Today's `suggestionRows`, `emptySuggestions`, `assignControl`, `poolRow`, `poolOptions` and `assignListMaxHeight` move into it with `level` threaded through; the pane's `suggestedFields(isLocked:)` keeps the section label and hint and composes one list per `Level.metadataLevels`. **The arrangement (stacked, segmented, folded) and the Wide answer are the agreed board's (SL-1, SL-W1); this row is completed from the board before status Planned.** If the board shows one list at a time, the chosen level is `@State` on the pane (it survives a type switch because the pane's `.id(panelIdentity)` sits on `panel`, below it). If the board widens the pane at Wide, the width-by-class rule goes into `macos/App/Features/CatalogVocabulary/` as one shared value that `SourceTypesView` uses and `MetadataView` keeps at 380pt (they are near-copy shells; `docs/ideas/wide-layout.md`), not a constant in `SourceTypesView` (review M-5) | One view per level, not three copies (brief inventory); the pane file stays under its size | Three copies of today's section; a kit list component — one call site |
| D-7 | Drop `FakeStore.suggestionsByType` (the alias and its 13 uses); the uses write `suggestionsByLevel[.source]` (the preview, `CatalogQueryRegistryTests`, `WorkspaceSessionTests`, `MetadataModelTests`). `SourceTypesModelTests.makeModel(suggestions:)` changes its parameter to `[Level: [String: [CatalogTypeSuggestion]]]` and assigns `store.suggestionsByLevel`; existing callers pass `[.source: …]`. The `SourceTypesView` `#Preview` adds Artifact rows (Provider, URL) and graph rows (Item, Line) to `t2`, so the preview shows all three lists. `FakeStore.suggestedFieldCount(typeID:)` sums every level's list for the type (override first, as today), so fixtures look like the engine; the rule itself is tested in Go only (T-1, T-2; `swift-tests.mdc`) | S15-06 D-12 and its Out row; the fake mirrors D-3 | Keeping the alias — it names a one-level world |
| D-8 | `SourcePageContext.unsavedMetadataRows(level:)` keeps its uncached read | S15-10 D-2: a form's rows live as long as the form; the Next adds "only switches to the cache" was an option, not a need; a key warmed from the Source page would need its own invalidation for nothing the researcher sees | Reading through `.typeSuggestions(…level:)` |
| D-9 | **Copy.** One `L10n.SourceTypes.level(_ level: Level) -> LevelCopy` *(new)* with one switch (`.citation` is unreachable: `preconditionFailure`) returns `struct LevelCopy { let title, meaning, emptyBody: LocalizedStringResource; let phrase: LocalizedStringResource }` (`phrase` is a format resource taking the type label, read through `L10n.format`). Toasts, tooltips and spoken labels build on `phrase` (§ 6 Strings). The final wording is the board's; § 6 Strings is updated to it before Planned | SL-9 and the brief's § 2.1; one switch over `Level` instead of four that must stay in step (review M-9); S15-17's Insert field groups can reuse the titles | Four `level…(_:)` functions, each with its own switch; a sentence per (level × use): 15 keys for one idea |
| D-10 | No reorder, no new RPC, no proto shape change. Proto comment edits regenerate with `./scripts/generate-proto.sh` | User, 2026-11-14 ("Append only") | A `ReorderTypeFields` RPC |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `SourceTypeSuggestionList` *(new)* | view / file | `SourceTypesDetailPane.suggestedFields(isLocked:)` | It is that code, moved and given a level (D-6); searched `Features/Metadata`, `Features/CatalogVocabulary` for a join-list view: none |
| `SourceTypesModel.suggestionsHandle(at:)`, `rereadSuggestions(at:)` *(new)*; `SuggestionWrite` *(new)* | func / enum | `QueryHandle.reading`, `PVRetryCallout(title:message:handle:id:onRetry:)`; `CitationComposerModel.Phase` | They expose the existing reading and retry; the enum replaces two flags (D-4) |
| `CatalogMutation.wroteTypeSuggestions(typeId:level:edit:)`, `CatalogQueryPatch.typeSuggestions()`, `.typeSuggestionCount()` *(new)*; `CatalogQueryKey.typeSuggestionsKeys(project:typeId:)` *(new)* | mutation / patches / helper | `.wroteMetadataBoard` + `CatalogQueryPatch.metadataBoard()` | Same pattern, a new key kind (D-1, D-2) |
| `assignPicks`, `suggestionErrors` | properties (replace) | `assignPick`, `isAssigning`, `removingFieldID`, `suggestionError` | Same state, per level (D-4) |
| `L10n.SourceTypes.level(_:)`, `LevelCopy` *(new)* | L10n | `L10n.Sources` "Artifact metadata" / "Evidence graph metadata" field labels; `L10n.Promote.duplicateBody(_:)` (a switch per use) | Those label a board in a form; these name a list on a type. Searched `L10n.swift` for a `Level` display name: none |
| `CatalogQueryKey.typeSuggestions(…, level:)`; mutations with `level:` | key / mutation (extend) | themselves | D-1, D-2 |
| `FakeStore.listTypeSuggestionsErrorLevels: Set<Level>?` *(new; gates the existing `listTypeSuggestionsError`: nil means every level, today's behavior for its two callers)*, `assignTypeFieldError: Error?` *(new)* | test hooks | `FakeStore.listTypeSuggestionsError` | One error hook per method (`swift-tests.mdc`; review M-6). `assignTypeFieldError` throws before any write, at every level; `removeTypeField` does not read it |

**Builds on.** S15-06's level-taking RPCs and `CatalogTypeSuggestionEdit`; the `add-workspace-place` key / descriptor / place pattern; the `Level.metadataLevels` subset.
**Deletes.** `FakeStore.suggestionsByType`; `CatalogMutation.assignedTypeSuggestion`, `.removedTypeSuggestion` and their `Kind` arms; `SourceTypesModel.patchSuggestions`, the count branch of `patchTypesList`; `SourceTypesModel.assignPick`, `isAssigning`, `removingFieldID`, `suggestionError`, the level-less `suggestions`, `isLoadingSuggestions`, `assignPool`, `canAssign`, `pickedField`, `assignTooltip`, `assignAccessibilityLabel`, `assignPickedField()`, `removeSuggestion(fieldID:)`, `suggestionsKey(for:typeID:)`; `SourceTypesDetailPane.emptySuggestions`, `suggestionRows`, `assignControl`, `poolRow`, `poolOptions`, `assignListMaxHeight` (moved); `L10n.SourceTypes.noAssignedBody` (replaced by `levelEmptyBody`); the "until S15-12" doc on `CatalogQueryKey.typeSuggestions`; the tests `selectingShowsOnlySourceLevelSuggestions` and `assigningWritesAtSourceLevelOnly` (replaced by T-3, T-5).
**Next adds.** S15-17's Insert field reads a type's fields by level from the same three keys (`suggestionsKey(for:typeID:level:)`). S15-18's Copy from copies rows at every level and applies `.wroteTypeSuggestions` per level, or invalidates; the count needs no change. S15-19 seeds rows that show here with no code change.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| Artifact and graph lists on a type page | `SourceTypesModel` per-level members | Picks and errors clear on select, add, history clear and delete (D-4); a type delete reaches every cached `.typeSuggestions` key through the descriptor's `source_vocabulary` follow, as today, whatever the level; a failed read shows (SL-5, T-4) |
| Writes at `artifact` / `graph` | `.sourceWorkspace` (every cached Source page) | Already invalidated `.allCached` on both mutations; an open Artifact sheet or graph form keeps its opened rows (brief § 2) |
| A field at two levels | the pool, the count | Pool is per level (T-6); the count sums (T-1, T-7) |

### Scale

At the map's Scale (about 30 types, about 60 fields, up to about 12 suggestions per list): selecting a type warms three keys (three `ListTypeSuggestions` calls, each a few rows). An assign or remove is one write, two descriptor patches (one list, one row) and today's `.allCached(.sourceWorkspace)` stale-mark, with no read. A vocabulary write (a type or field create, relabel or delete) follows `source_vocabulary`: with `.markStale` (D-1) it reloads only the visible type's three keys and marks the other visited types' keys stale (today, with `.revalidate`, every visited type's one key reloads; without D-1 it would be about 90 reads). `assignPool(at:)` is O(fields) per list, three per render. No budget is set or leaned on.

### Edges

- **Assumptions.** `sqlAppendSuggestion` computes `MAX(sort_order)` per (type, level) (S15-06 D-4), so the lists' ordinals stay independent; T-3 holds it on the Swift side.
- **Neighbors.** The same field in two lists: adding to one leaves the other (AC-2.2, T-6); removing from one leaves the other (AC-2.3, T-6). The count: one field at two levels counts 2 (T-1).
- **Removed inputs.** A removed suggestion never deletes the field or its values (today's toast clause, kept, T-6).
- **Real data.** None — the seeded suggestions are all `source` until S15-19; the count for every shipped type is unchanged on a fresh project.
- **Untrusted size.** None — lists come from the project's own catalog.

### Schema

None — no catalog change (`source_type_metadata_fields.level` exists since S15-06).

### Go core

| Package | Change |
| --- | --- |
| `core/database/sourcetypes` | `sqlSuggestedFields` drops `j.level = ? AND`; `List` runs `tx.Query(sqlList)` with no argument; `SuggestedFields` binds the type id only; doc comments per D-3 |

### FFI

`api/proto/engine.proto`: comments on `SourceType.suggested_field_count`, `AssignTypeFieldResponse.suggested_field_count`, `RemoveTypeFieldResponse.suggested_field_count` say the count is over all three levels. No shape change. Regenerate with `./scripts/generate-proto.sh`. Handlers unchanged.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Detail pane | snowflake | `SourceTypesDetailPane.swift` | Section label, hint, then the three lists in the board's arrangement (D-6) |
| One level's list | snowflake *(new file)* | `SourceTypeSuggestionList.swift` | Title (`pvMicroCaps`), meaning (micro italic, muted), count (mono micro, faint); rows in `PVCard` as today; `PVCallout(tone: .danger)` for `suggestionErrors[level]`; `PVRetryCallout` for a failed read (States below); dashed sunken `PVCard` with `levelEmptyBody`; `ProgressView` while loading; `PVComboBox` + `PVIconButton(.plus)` when editable. Group a11y label "<title>, <count>"; ids `sourceTypes.suggested.<level>`, `.<level>.empty`, `.<level>.count`, `.<level>.pool`, `.<level>.assign`, `.<level>.remove.<fieldId>` |
| Chooser (only if the board shows one list at a time) | `PVSegmentedControl` | `macos/App/DesignSystem/Components/Chip/PVSegmentedControl.swift` | Board decides |
| Fold (only if the board folds lists) | `PVDisclosureButton` | `macos/App/DesignSystem/Components/Disclosure/PVDisclosureButton.swift` | Board decides |
| Associated fields column | — | `SourceTypesListPane.swift` | Unchanged code; the number is the engine's total |

States, per list, switching on `suggestionsHandle(at:)?.reading` (nil → as `.loading`): a write error `suggestionErrors[level]` shows as a danger `PVCallout` above the list whatever the read state; `.loading` → `ProgressView`; `.failed` → `PVRetryCallout(title: L10n.SourceTypes.suggestionsReadFailedTitle, message: L10n.Errors.message(for:), handle:, id: "sourceTypes.suggested.<level>.readFailed", onRetry: { model.rereadSuggestions(at: level) })` **in place of** the rows; `.loaded(rows, refreshFailure)` → the rows (or the dashed empty card when empty), with the same `PVRetryCallout` above them when `refreshFailure` is set. Locked plugin type read-only; adding a type shows today's note.

The section header keeps its label and hint and **drops** its count (`sourceTypes.suggested.count`): each list carries its own. The old ids `sourceTypes.suggested.empty`, `.count`, `.pool`, `.assign`, `.remove.<fieldId>` become the per-level ids above; `sourceTypes.suggested` stays on the section. No UI test reads the old ids.

Accessibility: the list group's label is `"\(level(_:).title), \(assignedCount)"`, built from existing pieces (no new key). The picker's `label:` is `assignFieldLabel` followed by the level title ("Metadata field to assign, On each Evidence graph"), so the three pickers read apart; `assignPlaceholder`, `assignNoMatch`, `poolHint`, `assignTipChoose` and `assignField` stay as today. Accessibility per SL-9. Wide per the board (SL-W1).

### Strings

New (`L10n.SourceTypes`, final wording from the board):

| Key | Default |
| --- | --- |
| `sourceTypes.suggested.level.source.title` / `.artifact.title` / `.graph.title` | "On the Source" / "On each Artifact" / "On each Evidence graph" |
| `sourceTypes.suggested.level.source.meaning` / `.artifact.meaning` / `.graph.meaning` | "The record as a whole" / "The copy you used: an image, a scan, a transcript" / "One item in the record: a household, an entry" |
| `sourceTypes.suggested.level.source.empty` / `.artifact.empty` / `.graph.empty` | "No Source fields yet. Assign the fields these records usually carry." / "No Artifact fields yet. Assign what you note about each copy, such as its provider or URL." / "No Evidence graph fields yet. Assign what you note about each item, such as its line or household." |
| `sourceTypes.suggested.readFailedTitle` | "These suggestions couldn’t be read" |
| `sourceTypes.suggested.level.source.phrase` / `.artifact.phrase` / `.graph.phrase` | "on each %@ Source" / "on each Artifact of a %@ Source" / "on each Evidence graph of a %@ Source" (argument: the type label) |

Changed (same keys, new default and arguments; comments say the second argument is a level phrase):

| Key | Default |
| --- | --- |
| `sourceTypes.suggested.hint` | "Suggestions, not a schema — a record may leave any of them blank" |
| `sourceTypes.suggested.assignTipField` → `assignTipField(label:phrase:)` | "Suggest %1$@ %2$@" |
| `sourceTypes.suggested.assignFieldNamed` → `assignFieldNamed(field:phrase:)` | "Suggest %1$@ %2$@" |
| `sourceTypes.suggested.remove` → `removeSuggestion(label:phrase:)` | "Stop suggesting %1$@ %2$@" |
| `sourceTypes.toast.assignedBody` → `toastAssignedBody(field:phrase:)` | "%1$@ is now suggested %2$@." |
| `sourceTypes.toast.removedBodyNoValues` / `removedBodyWithValues` → `toastRemovedBody(field:phrase:valueCount:)` | "%1$@ is no longer suggested %2$@. The field stays in this project’s vocabulary." / "%1$@ is no longer suggested %2$@. The field stays in this project’s vocabulary, and the %3$lld Sources, Artifacts and graphs already carrying a value keep it." |
| `sourceTypes.list.columnFields` comment | "how many metadata fields the type suggests at all three levels" (default unchanged) |

Removed: `sourceTypes.suggested.noneBody`. Old-scope copy checked: `assignTipPoolEmpty` ("Every field is already assigned") and `poolHintEmpty` ("Every field in the vocabulary is already suggested for this type") become per list: `poolHintEmpty` changes to "Every field in the vocabulary is already in this list"; `assignTipPoolEmpty` to "Every field is already in this list".

## 7. Steps

**STEP-1 — The count covers every level**
Files: `core/database/sourcetypes/sourcetypes.go`, `core/database/sourcetypes/sourcetypes_test.go`, `api/ffi/handlers/source_defs_test.go`, `api/proto/engine.proto`, generated code. Skill: `add-seeded-vocabulary`.
Do: D-3; T-1, T-2; proto comments; `./scripts/generate-proto.sh`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcetypes/... ./api/ffi/...` passes.

**STEP-2 — The key, the mutations and the fake take a level**
Files: `CatalogQueryKey.swift`, `CatalogQueryRegistry.swift`, `CatalogMutation.swift`, `CatalogLastUpdated.swift`, `PlaceRegistry.swift`, `FakeStore.swift`, `GenealogyStore.swift` (docs), `SourceTypesModel.swift` (keys and calls only, `.source` for now), `SourceTypesView.swift` preview, the 14 test sites. Skill: `add-workspace-place`.
Do: D-1, D-2 (the mutation, the two patches, `whenHidden`), D-5's model change at the `.source` level, and D-7's alias removal (the fake's count still reads `.source` in this step); the `typeSuggestions` doc comment loses "until S15-12"; port `PlaceRegistryTests` (two `queryKeys` expectations now list the three keys in `Level.metadataLevels` order) and the key's other test sites; T-8, T-10.
Check: `xcodebuild test` for `CatalogQueryRegistryTests`, `WorkspaceSessionTests`, `MetadataModelTests`, `SourceTypesModelTests` passes.

**STEP-3 — The model holds three lists**
Files: `SourceTypesModel.swift`, `SourceTypesModelTests.swift`. Skill: `add-swift-test`.
Do: D-4, D-5; D-7's summing `suggestedFieldCount(typeID:)` and the two `FakeStore` hooks (§ 6 Codebase fit); T-3 – T-7; retire `selectingShowsOnlySourceLevelSuggestions` and `assigningWritesAtSourceLevelOnly`.
Check: `SourceTypesModelTests` passes.

**STEP-4 — Copy names the list**
Files: `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`. Skill: `add-localized-string`.
Do: § 6 Strings, D-9.
Check: `python3 scripts/check-localizable-xcstrings.py` passes.

**STEP-5 — The pane draws three lists**
Files: `SourceTypeSuggestionList.swift` *(new)*, `SourceTypesDetailPane.swift`. Skill: `add-ui-component`.
Do: D-6 in the board's arrangement and Wide answer; SL-9 labels; § 6 macOS ids.
Check: the app builds with no Swift warning; the manual check's steps 1–4 match the board's frames at Regular and Wide.

**STEP-6 — Version**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj`.
Do: the header's bump.
Check: the three agree.

**STEP-7 — Docs**
Files: `completed.md`, `deployment-plan.md` (map row and design track link), this plan (status), `design/S15-D6-source-type-suggestion-levels.md` → `design/archive/` (fix its relative links), `design/README.md`, `docs/macos-client-patterns.md`, `.agents/skills/add-workspace-place/SKILL.md`.
Do: per the Definition of done; `docs/macos-client-patterns.md` rule 2 names `.wroteTypeSuggestions` (a patch-only type–field mutation) in place of the two old ones; `.agents/skills/add-workspace-place/SKILL.md` lists `CatalogQueryPatch.typeSuggestions()` beside `.metadataBoard` in the Patch row.
Check: `python3 scripts/check-plan-docs.py` passes; links resolve; `rg 'assignedTypeSuggestion|removedTypeSuggestion'` finds nothing outside `docs/deployment-plan/`.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/sourcetypes/sourcetypes_test.go` case "list counts the fields a type suggests at every level" (renamed) | One field at `source` and `graph` on Book; none on Letter → `List` Book 2, Letter 0; `SuggestedFields(Book)` 2 | AC-3.3, D-3 |
| T-2 | Go | `api/ffi/handlers/source_defs_test.go` `TestAssignAndRemoveTypeField` case renamed "the reply counts the engine's suggestions at every level after the write", and the `UpdateSourceType` count case | The existing data (Folio, Officiant, Parish at `source`; Witness at `graph`) → 4 after the assigns, 2 after the two source removes; `UpdateSourceType` count equals the sum of the three `ListTypeSuggestions` lengths | AC-3.2, D-3 |
| T-3 | Swift | `SourceTypesModelTests.selectingLoadsEachLevelsListInStoredOrder` *(new; replaces `selectingShowsOnlySourceLevelSuggestions`)* | Rows at three levels → `suggestions(at:)` per level in stored order; `Set(listTypeSuggestionsLevels) == [.source, .artifact, .graph]` (the loads run concurrently; the test awaits each level's handle through a `warmSuggestions(_:session:typeID:)` helper that waits on all three keys) | AC-1.1, D-1 |
| T-4 | Swift | `SourceTypesModelTests.aFailedLevelReadFailsOnlyThatList` *(new)* | `listTypeSuggestionsError = StoreBoom.boom`, `listTypeSuggestionsErrorLevels = [.graph]` → `suggestionsHandle(at: .graph)?.reading` is `.failed`; source and artifact are `.loaded` with their rows; clear the error, `rereadSuggestions(at: .graph)` → `.loaded` | AC-1.3, D-4 |
| T-5 | Swift | `SourceTypesModelTests.assigningWritesAtThatLevelOnly` *(new; replaces `assigningWritesAtSourceLevelOnly`)* | Pick f3 at `.graph`, assign → fake graph list ends with f3; source and artifact lists unchanged; `assignPicks[.graph]` empty, `assignPicks[.source]` kept; toast body equals `toastAssignedBody(field:phrase:)` with the graph phrase | AC-2.1, D-4 |
| T-6 | Swift | `SourceTypesModelTests.aFieldCanSitInTwoLists` *(new)* | Page at `.source` → `assignPool(at: .artifact)` has Page, `assignPool(at: .source)` does not; assign at `.artifact`, remove at `.artifact` → source list still holds Page; remove toast keeps the values clause when `usedBy > 0` | AC-2.2, AC-2.3 |
| T-7 | Swift | `SourceTypesModelTests.anAssignFailureStaysInItsList` *(new)* and `fieldsColumnShowsTheEnginesCountNotTheReplyLength` (ported to a level) | `assignTypeFieldError` set, assign at `.artifact` → `suggestionErrors[.artifact]` set, others nil, pick kept. Count override 7 → row shows 7 | AC-2.4, AC-3.2 |
| T-8 | Swift | `CatalogQueryRegistryTests` (ported) | `.wroteTypeSuggestions(typeId: "t1", level: .graph, edit:)` → invalidations `[.allCached(.sourceWorkspace)]` only; with t1's three keys and the types list warmed, applying it writes `edit.suggestions` into the `.graph` key and `edit.suggestedFieldCount` into t1's row, leaves the `.source` and `.artifact` keys unchanged, and starts no `listTypeSuggestions` or `listSourceTypes` call | D-2, D-5, AC-2.5, AC-3.2 |
| T-10 | Swift | `CatalogQueryRegistryTests` hidden-policy case *(new)* | `.typeSuggestions` warmed then hidden; a `source_vocabulary` write → the key is stale, no `listTypeSuggestions` call; shown again → it reloads | D-1 |

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
- [ ] Domain doc updated if a rule in docs/*.md changed: docs/macos-client-patterns.md (the type–field mutations carry a level)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

Run on a Mac with the app built (the `run` skill), at Regular and with the window stretched to a Wide pane.

1. Open a dogfood project; Source types; select Census. See three lists in the board's arrangement; the Source list holds today's seeded fields; the Artifact and Evidence graph lists show their empty copy (AC-1.2).
2. In the Evidence graph list add Item, then Line. Each lands last; the count reads 2; the toast names "each Evidence graph of a Census Source"; the types list's Associated fields for Census grows by 2 and equals the three lists' counts added up; sort by the column (AC-3.1).
3. In the Artifact list add Page (also in the Source list if seeded there). Remove it from the Artifact list; the Source list keeps it.
4. Select a plugin type (the app's FakeStore preview `SourceTypesView` `#Preview` has one, t5 Grave memorial; a dogfood project may have none): read-only lists with counts and empty copy, no picker, plus or remove (AC-1.4). Add a type: the note shows instead of the lists. Stretch the window past 1600pt of pane: the board's Wide arrangement; a pick in progress survives.
5. Slice Check: open a Census Source, Add evidence graph — Item and Line are offered on the form's board. Open an existing graph's Edit — Line shows as a suggestion.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| The board draws something the model cannot hold (a draft of a list, a reorder) | Stop: brief § 2.2 and D-10 rule them out |
| A test reads the count as the Source list's length | T-2 ports that comparison to the sum |

**Stop and report if:**

- `sqlAppendSuggestion` no longer takes `MAX(sort_order)` per (type, level).
- `.sourceWorkspace`'s invalidation no longer marks every cached Source page stale on a type–field mutation (AC-2.5 would need a new path).
- The agreed board's arrangement needs a kit component the brief's inventory does not list.
- The board's copy needs a sentence per (level × use) that `LevelCopy.phrase` cannot build.

## 12. Open questions

- Board S15-D6: the three lists' arrangement and the Wide answer (SL-1, SL-W1), and any copy change. Recommended: whatever the board agrees; D-6, § 6 macOS and § 6 Strings are filled from it, then review-plan runs and the status moves to Planned.

## 13. PR

**Title:** S15-12 — Source types suggest fields at each level
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-12-type-suggestions-at-each-level.md`.
