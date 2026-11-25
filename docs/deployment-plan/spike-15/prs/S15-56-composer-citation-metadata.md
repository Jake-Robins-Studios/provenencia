# S15-56 — The composer edits a Citation's metadata

**Status:** Blocked — on board S15-D29
**Spike / slice:** Spike 15 · Slice 11 — Metadata at any level
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D29](../design/S15-D29-citation-composer-metadata.md), written 2026-11-25, board not drawn
**Board:** — (filled when the board is agreed: link, frames, and whether the board sits before or after the transcription in the side form)
**Depends on:** S15-55 (landed [#970](https://github.com/Jake-Robins-Studios/provenencia/pull/970)), S15-60 (landed [#975](https://github.com/Jake-Robins-Studios/provenencia/pull/975)), S15-64 (landed [#959](https://github.com/Jake-Robins-Studios/provenencia/pull/959)), S15-D29
**Blocks:** S15-58, S15-39, S15-41
**Branch:** `s15-56-composer-citation-metadata`
**Version bump:** minor, 0.43.0 (today's `VERSION`) → **0.44.0** (or the next minor after `main`'s `VERSION` when you rebase): the composer gains a board and the wire gains `ListedCitation` fields ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md) (the composer place's keys, the citations-by-Artifact refreshes), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`, `.cursor/rules/swift-tests.mdc` (FakeStore seeds what Go composes)
**Context:** working rules "One metadata board", "A board shows what its owner inherits", "The printed page is a metadata field", "Metadata saves with its owner's write", "A board adds a field in an inline row", "One window"; [`source-layer-data-model.md` § 5](../../../source-layer-data-model.md); [`catalog-caches.md` § Swift caches](../../../catalog-caches.md#swift-caches)
**Planned:** 2026-11-25 against `main` @ `620ddaa`
**Review:** [`S15-56-composer-citation-metadata.review.md`](S15-56-composer-citation-metadata.review.md) — Fits with changes; Ready with changes; two rounds, no blocker open; two answers from the user (2026-11-25)

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

A researcher edits a Citation's metadata in the citation composer, on the same board every other owner has: the type's suggestions, the values the Citation inherits from its graph, Artifact or Source, its own values, and Add field. The values save with the Citation's Save. The Printed page input goes: the printed page is the board's **Page** row, and the Conclusion detail, the composer's Citation menu and the citation line read the Citation's own Page value.

**Why now.** S15-54 made a Citation hold values and its writes take a draft; S15-55 gave a new Citation a draft board under its graph and Artifact; S15-64 drew inherited rows; S15-60 seeded `page`. Nothing draws a Citation board yet, and the composer's Printed page writes a locator key no format will read once S15-58 lands.

**What stays.** The locator strip, the viewer, the Observations column, the authoring box and the composer's split. Rendered citations keep `{meta.page|citation.page}` until S15-58, and the locator keeps `page_label` until S15-59. No flags or marks on the board (S15-39, S15-41).

## 2. User stories

**US-1.** As a researcher, when I make or edit a Citation in the composer, I fill its metadata on its board so that its citation prints its page and column.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A newspaper Source (type Newspaper item, seeded); **New citation** on its PDF Artifact; Page "2" and Column "4" typed on the board; Save | One `CreateCitationWithObservations` carries both values; the Citation reopens with Page "2" and Column "4" saved rows; its rendered citation reads "…, p. 2, col. 4; …" |
| AC-1.2 | That Citation open; Column changed to "5"; Save | One `UpdateCitation` carries the change; Label and transcription unchanged; the board shows "5" |
| AC-1.3 | A new Citation, no Save yet; an Observation added first (the composer creates the Citation through `ensureCitationID`) with Page "3" typed on the board | The board change enables Save, as a Label change does; the ensure-create carries Page "3"; after it the host is saved (`citationDirty` false); a later Column "4" and Save sends an `UpdateCitation` whose draft holds Column alone |
| AC-1.4 | A Citation whose graph holds Page "2" and which holds none | Its Page row shows "2" with "From Evidence graph"; its citation prints "p. 2" |
| AC-1.5 | An unsaved board change (a value typed and confirmed), then the Citation menu's pick of another Citation | The composer's discard confirm shows, as for an unsaved Label; Discard drops the change |
| AC-1.6 | **New citation** on an Artifact whose graph was deleted after the composer opened | The board's place shows `L10n.CitationComposer.metadataBoardUnavailable`; Label and the transcription save as today, and the create sends no metadata |
| AC-1.7 | Any Artifact kind (image, PDF, audio, video, unsupported) | The board shows; there is no Printed page field |

**US-2.** As a researcher reading a Conclusion or picking a Citation, I see the Citation's own printed page.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | A Citation with own Page "14", locator file page 37, an Observation feeding a Conclusion | `GetConclusionDetail`'s outcome `page_label` is "14"; the citation line reads "p. 14" |
| AC-2.2 | Own Page marked unknown (field unknown text "unpaginated") | `page_label` is "unpaginated" |
| AC-2.3 | Own Page "14" marked supplied | `page_label` is "[14]" |
| AC-2.4 | No own Page; its graph holds Page "2"; locator `page_label` "9" and file page 37 | `page_label` is "" (no chain; the locator label is not read); the line reads "image 37" |
| AC-2.5 | A project with no field keyed `page` | `page_label` is ""; no error |
| AC-2.6 | The composer's Citation menu over an Artifact with CIT-A (own Page "2", file page 2) and CIT-B (Page inherited, file page 40) | Rows read "p. 2 · image 2" and "image 40" |

## 3. Scope

| In | Covered by |
| --- | --- |
| The Citation's board in both form arrangements (CB-1, CB-W1, CB-W2), Tab order and VoiceOver (CB-7, CB-8) | STEP-9 |
| A new Citation's draft board; a saved Citation's board from the cached list (CB-2, CB-3) | STEP-4, STEP-8 |
| Values save in the Citation's create and update; one Save; leave confirm (CB-4) | STEP-5, STEP-8 |
| The board's read failure copy (CB-5; S15-55 review UX-1) | STEP-7, STEP-8 |
| Menu row reads the own Page (CB-6) | STEP-4, STEP-9 |
| `graphfill` reads the Citation's own `page` (and so the Conclusion detail, `CitationLineDisplay` and the likeness and depiction viewers) | STEP-1, STEP-2 |
| Value writes at every level refresh the composer's Citation list | STEP-3, STEP-6 |
| The board's files move to their own folder (user, 2026-11-25) | STEP-6 |
| Printed page input, its strings and capability removed | STEP-9, STEP-10 |
| Copy and docs that name the old boards or the Printed page field (S15-54 ship UX-1, S15-55 review UX-2) | STEP-7, STEP-11 |

| Out | Home |
| --- | --- |
| Needed and used flags on the composer's board | S15-39 |
| The Unknown and Supplied control | S15-41 |
| `{citation.page}`, `Board.Page`, `page_requirement` | S15-58 |
| The locator's `page_label` keys and `CitationLocatorDraft.pageLabel` | S15-59 |
| Renaming `page_label` on `ReconcilerOutcomeDetail` and its carriers | not planned (the name stays the display page's; S15-59 retires only the locator key) |
| An engine error code for "a parent of the draft board is gone" | not planned (map scope entry: the client copy) |
| Renaming the board's `L10n.Sources` keys after the move | not planned |
| Moving existing locator `page_label`s into `page` values | not planned (user, 2026-11-25: the product owner updates dogfood projects by hand) |
| A board that refreshes while its Citation stays open in the composer | not planned (rule "One window": no other view edits while the composer shows) |
| A field's unknown-text edit refreshing loaded graphs | S15-46 |
| A metadata draft on `CreateCitedBridge` | not planned (S15-54: a bridge's Citation takes values through `UpdateCitation`) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Field keys | `core/vocabkey/vocabkey.go`; seed `core/database/sourcevocab/registry_fields.go` (`{Key: "page", …}`, :143) | No metadata-field key; S15-60 D-4 left `page` to its first reader; no seed parity test for field keys |
| Key resolution | `core/database/metadatafields/metadatafields.go` `ResolveKeysTx` (:297), `ListByIDsTx` (:250), `MapByIDsTx` (:272) | Take `*sql.Tx`; `graphfill` reads through `graphcache.Graph`, a `database.Querier` |
| Values read | `core/database/sourcemetadata/sourcemetadata.go` `ListByOwnersTx` (:694) → `readByOwners(q database.Querier, …)` (:713); `ListWorkspaces` (:821); `annotation.go` `CitationValue` (:49); `core/citationformat/render.go` `Display` (:219) | The reads and the display text exist; no reader resolves a field by key |
| Graph page | `core/database/graphfill/load.go` `loadGraphObservations` (:169), `citationWords` (:162) | Sets `EvidenceObservation.PageLabel` from `locator.Page(...).Label` (:217–224), dropping the mark |
| Carriers | `graphcache.EvidenceObservation.PageLabel`; `conclusiondetails.Outcome.PageLabel` (:95, copied :576); `api/ffi/handlers/conclusion_detail.go` `reconcilerOutcomeProto` (:170) → `ReconcilerOutcomeDetail.page_label = 24` | Unchanged; they carry what `graphfill` sets |
| Reads | `core/database/effects/registry.go` `type Read`, `ReadCitations` (:37, "the citation counts and the citations by Artifact of a graph"), `KeyTable`, `"citation_metadata"` (:379), `"source_metadata"` (:364), `metadataEffects` (:532); `reads_test.go` `TestReadsDeclare`; Swift `Features/Workspace/Session/CatalogMutation.swift` `CatalogRead` (:83) | No metadata table moves a read the composer's list follows |
| List RPC | `api/ffi/handlers/citations.go` `ListCitationsByArtifact` (:213); `engine.proto` `ListedCitation` (:2718) | No board, no page |
| Citation writes | `citations.go` `CreateCitationWithObservations` (:15), `UpdateCitation` (:159); proto `metadata` 12/4 and 9/3 | Take a draft and answer the board since S15-54; Swift sends none. Both report `citations` for the graph, so the composer's list reloads after each |
| Swift store | `macos/App/Platform/GenealogyStore.swift` `createCitationWithObservations` (:2129), `updateCitation` (:2149), `listCitationsByArtifact` (:2185), `CatalogListedCitation` (:425); `GoStore.swift` (:2345); `FakeStore.swift` (Artifact draft recorders :263–269, `metadataByOwner`, its own create caller :2750); `macos/ProvenenciaTests/OnboardingModelTests.swift` stub | No metadata argument or rows |
| Cache | `Features/Workspace/Session/CatalogQueryRegistry.swift` `.citationsByArtifact` (:367), `.citationCounts` (:301); `PlaceRegistry.swift` the `.citationComposer` spec (:55–72) | The list follows `.reads(.citations)`; the composer place does not warm `.metadataFieldsList` |
| Board files | `Features/Sources/MetadataBoardView.swift`, `MetadataBoardModel.swift`, `MetadataBoardHost.swift` (protocol + `SourcePageMetadataHost`), `MetadataDraftHost.swift`, `MetadataBoardDialogs.swift`; `SourceOwnerForm.swift` `DraftMetadataBoardField` | Sources-only snowflakes; the composer would be their first caller elsewhere |
| Composer writes | `Features/CitationComposer/CitationComposerContext.swift` `createCitationIfNeeded` (:121), `applyWrite` (:81), `citationsKey(artifactID:)` (:86), `fieldsKey` (Properties); `CitationFieldsDraft.swift` `saveCitation` | No metadata |
| Composer state | `CitationComposerModel.swift` `hasUnsavedDocumentWork` (:350), `:392`, `:541`, `canSaveCitation` (:744), `pageLabel` (:309), `loadCitation`, `openBlankCitation`, `resetComposerIdentity`, `selectArtifactAndLoad`, `fetchOpenCitation`, `cachedCitation` | Dirty is `fields.isDirty` alone |
| Composer form | `CitationComposerEvidenceColumn.swift` `CitationFormFocus`, `labelAndPrintedPage`, `printedPageField`, `CitationStepMenuRow.locatorText`; `CitationComposerView.swift` `composeSplit` (:299); `Features/ArtifactViewer/ArtifactViewerKind.swift` `supportsPrintedPage` | Draws Printed page from the locator |
| Go tests | `core/database/graphfill/records_test.go` `TestGraphRecordsCarryCitationWords` (:238), `TestLoadParsesEachCitationOnce` (:327); `core/database/conclusiondetails/conclusiondetails_test.go` `TestForEntityCitationParts` (:218); `api/ffi/handlers/conclusion_detail_test.go` `TestConclusionDetailProtoCarriesVoteArtifactAndMembers` (:201) | The first three assert the locator's label; the last builds an `Outcome` by hand and stays as is |
| Swift tests | `macos/ProvenenciaTests/ArtifactViewerModelTests.swift` (:65–69, `supportsPrintedPage`); `CitationComposerModelTests.swift` (:827–830 `order(…printedPageOffered:)`, :835–857 `locatorText` with `pageLabel`); `CatalogQueryRegistryTests.swift` | Use the APIs this PR deletes |
| Docs that go false | `docs/interpretation-layer-data-model.md` :253 ("The composer writes `page_label` from its Printed page field"); `.agents/skills/add-workspace-place/SKILL.md` :175 (every board Save goes through `SourcePageContext.applySavedMetadata`); `docs/macos-client-patterns.md` :89 (the `reads` list); `docs/source-layer-data-model.md` § 5.5 (the boards list) | Name the old shape |

**Precedent.** S15-34 (#819) and S15-10 (#829) put a draft board on the Artifact sheet: `ArtifactSheetModel.init` builds `MetadataDraftHost` and then `MetadataBoardModel(host:)` in one switch (cached rows for edit, the draft read for add), sends `host.draft` in its one write and calls `host.markSaved()`. Copy that; the composer's rows come from its cached Citation list, and its write's own `citations` read reloads that list, so no patch is added.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `vocabkey.FieldPage = "page"` in `core/vocabkey/vocabkey.go`; `sourcevocab` gains a parity test that every metadata-field key `vocabkey` declares is a seeded field key | Rule "The printed page is a metadata field": the key is declared once, and a seed rename fails CI instead of blanking every page | A literal in each reader |
| D-2 | The printed page is read in two exported steps in `sourcemetadata` `annotation.go` (signatures in Codebase fit): `PageFieldID` resolves `vocabkey.FieldPage` with `metadatafields.ResolveKeysTx(q, …, vocabkey.OriginProvenencia)` (Unknown or Ambiguous → nil, no error); `PageText(row Row, f metadatafields.Field) string` is `citationformat.Display(CitationValue(row, f))`. `CitationPages` composes them for a list of Citations: owners are `Owner{Level: vocabkey.LevelCitation, ID: id}` per id, read with `readByOwners` (what `ListByOwnersTx` reads), the field from `metadatafields.MapByIDsTx`; the map is keyed `string(id)` (raw bytes, as `graphfill`'s `words`); a Citation with no own row, or whose `PageText` is "", is absent | The rule: own value only, marks as a citation prints them, one lookup and one formatter for both readers | A walk up the levels (the rule forbids it); Swift picking the row out of the board (a second resolution) |
| D-3 | `metadatafields.ResolveKeysTx`, `ListByIDsTx` and `MapByIDsTx` take `q database.Querier` instead of `tx *sql.Tx`; names and behavior unchanged; every caller compiles as is | `graphfill` reads through `graphcache.Graph`; `*sql.Tx` is a Querier | Querier copies beside them; renaming the `Tx` functions |
| D-4 | `graphfill` keeps parsing the locator for `ArtifactPage` and stops reading its `Label` (`citationWords.pageLabel` goes); after the scan it calls `CitationPages` once over the graph's Citation ids and sets each Observation's `PageLabel` from it. `CitationLineDisplay` and the proto are unchanged: "p. unpaginated" and "p. [14]" read as the seeded formats print them | One batched read per graph load; S15-54 D-7 already invalidates loaded graphs on `citation_metadata` | A per-Citation read; a proto mark field (the text carries it) |
| D-5 | A new read `effects.ReadCitationBoards = "citation_boards"` ("the Citation boards of a graph's Citations: their own and inherited metadata values"), key table `evidence_graphs`. The four values tables report it, as `Reads` extras in `registry` (`evidence_graph_metadata` and `artifact_metadata` gain partial literals that `metadataEffects` fills, as S15-61 D-9 lets an entry declare extras): `citation_metadata` `up("citation_id", "graph_id")`; `evidence_graph_metadata` `field("graph_id")`; `artifact_metadata` `from("artifact_id", chain(inbound("citations", "artifact_id"), field("graph_id")))`; `source_metadata` `graphsOfSource(field("source_id"))`, beside its `ReadInheritedValues`. Swift `CatalogRead.citationBoards`; `.citationsByArtifact` follows it as it follows `.citations`; `.citationCounts` does not | Each own or inherited value move reaches the composer's list (S15-54 Out, S15-64 Next adds), and count keys do not reload on metadata edits | Reusing `ReadCitations` (its counts would reload on every value write); deriving the paths from `MetadataTables.Ups` (they point up; this path points down from an owner to the graphs of the Citations under it, which no table declares) |
| D-6 | `ListedCitation` gains `repeated MetadataWorkspaceEntry metadata = 4` (the Citation's board) and `string page_label = 5` (the own Page's `PageText`, "" none), named as `ReconcilerOutcomeDetail.page_label`. `ListCitationsByArtifact` makes one `sourcemetadata.ListWorkspaces` call over the listed Citations, resolves `PageFieldID` once on `c.DB()`, and takes each `page_label` from that board's entry whose `Field.ID` is the page field and whose `Value` is set, through `PageText`: the page and the board come from the same rows | Rule "One window": the composer opens a Citation from the cached list with no fresh read; one read per Artifact (Scale) | A `GetMetadataBoard` per Citation opened; a second `readByOwners` beside the boards |
| D-7 | Swift `createCitationWithObservations` gains `metadata: CatalogMetadataDraft?` and returns `(CatalogCitation, [CatalogObservation], [CatalogMetadataEntry], CatalogWriteEffects)`; `updateCitation` gains `metadata:` and returns `(CatalogCitation, [CatalogMetadataEntry], CatalogWriteEffects)`; rows map with `Self.mapMetadataEntry` as `updateArtifact` maps them. `CatalogListedCitation` gains `metadata: [CatalogMetadataEntry] = []` and `pageLabel: String = ""`. FakeStore records each draft in `createCitationMetadata` and `updateCitationMetadata` arrays and applies none, as its Artifact recorders do; its listed Citations carry seeded `metadata` and `pageLabel`, never computed from entries; its own caller and the test stub pass `nil` | S15-54 D-12: the store gains the draft with its first caller; `swift-tests.mdc` | A metadata write after the Citation's (rule "Metadata saves with its owner's write") |
| D-8 | The open Citation's board lives on `CitationComposerContext` (the context every `ensureCitationID` caller already shares): `metadataHost: MetadataDraftHost?`, `metadataBoard: MetadataBoardModel?`, `metadataBoardError: String?`, set only by `openMetadataBoard(for listed: CatalogListedCitation?) async`. It clears the error, then: a listed Citation → host from `listed.metadata`; nil (a new Citation) → host from `store.getDraftMetadataBoard(projectDir:parents: [graph, Artifact], level: .citation)`, nil while it reads; then the board model from the host, as `ArtifactSheetModel.init` does. The fields are `metadataFields`, the `.metadataFieldsList(project:)` query, which the `.citationComposer` place now warms. Callers: `loadCitation` (the listed row from `citationsKey(artifactID:)`'s cached value; a Citation read through `getCitation` because it is not there gets the error line, D-14), `openBlankCitation`, `resetComposerIdentity`, `selectArtifactAndLoad`, and `discardLeaveChanges`' revert branch (it rebuilds the open Citation's board as opening it does; the `keepDraft` branch leaves the board as it is). `cachedCitation(id:)` returns the `CatalogListedCitation`, and `FetchedCitation` gains `listed: CatalogListedCitation?`, nil on the `store.getCitation` fallback, which stays for the Citation's own fields. After a create, the host is kept and marked saved (D-9), so a later update sends only the changes since. A cache reload while the Citation stays open does not rebuild it | One place builds the board, as the Artifact sheet's init does; "One window" bounds staleness to the next open | The host on `CitationFieldsDraft` (`ensureCitationID` takes only its values) |
| D-9 | Writes: `createCitationIfNeeded` sends `metadataHost?.draft`; `saveCitation` sends it on update. On success `metadataHost?.markSaved()`, then `applyWrite(effects)` as today; the write's `citations` read reloads the list with the saved board and page (user, 2026-11-25: no `.wroteMetadataBoard` patch on the list) | One mechanism per write | Patching the cached list (a second path; its page would stay stale until the reload) |
| D-10 | Board-dependent: the board sits in a `DraftMetadataBoardField` labelled `L10n.CitationComposer.metadataLabel` under Label in both arrangements; in the side form, before or after the transcription as the board decides (CB-W1). Filled from the board before `Planned` | Brief CB-1, CB-W1 | A composer-only board view |
| D-11 | `CitationComposerModel.citationDirty` is `fields.isDirty || (context.metadataHost?.isChanged ?? false)`; `hasUnsavedDocumentWork`, `canSaveCitation` and the reads at `:392` and `:541` use it | CB-4: one Save, one leave confirm | A board Save button |
| D-12 | `metadataBoardError` is `L10n.CitationComposer.metadataBoardUnavailable` when `(error as? CoreInvokeError)?.engineCode == .sourceMetadataInvalid` (as `MetadataBoardModel.swift:307` checks), and for a Citation missing from the cached list; else `L10n.Errors.message(for:)`. The host stays nil, so a create sends no metadata | CB-5; S15-55 D-6 | The engine's save-worded sentence; a raw code string |
| D-13 | `CitationStepMenuRow.locatorText(pageLabel:locator:)` takes the listed Citation's `pageLabel` for "p. 14" and the locator for "image 37" and "region" | User, 2026-11-25: the row shows the Citation's own Page value | Dropping the printed page from the row |
| D-14 | `CitationFormFocus` keeps `.label` and `.transcription`; `order(_:)` takes the layout alone and answers `[.label, .transcription]` for `.side`, `[.transcription, .label]` for `.panel` | CB-7: the Tab list names text fields only, as the Artifact sheet's | Adding the board to the Tab list |
| D-15 | The board's six types move, unchanged, to `macos/App/Features/MetadataBoard/` *(new)* (Codebase fit): `MetadataBoardView.swift`, `MetadataBoardModel.swift`, `MetadataBoardHost.swift` without `SourcePageMetadataHost` (which moves to `Features/Sources/SourcePageMetadataHost.swift` *(new)*), `MetadataDraftHost.swift`, `MetadataBoardDialogs.swift`, and `DraftMetadataBoardField` out of `SourceOwnerForm.swift` into `DraftMetadataBoardField.swift`. Synchronized folders: no project-file edit | User, 2026-11-25: the board gains a second feature (`design-system-layers.md`: a snowflake is called from one feature) | Leaving them under Sources |
| D-16 | No migration of locator `page_label`s (Out) | User, 2026-11-25 | — |
| D-17 | `CatalogMutationKind.boardVocabulary: Set<CatalogMutationKind>` = `[.changedSourceType, .updatedMetadataField, .deletedMetadataField, .wroteTypeSuggestions, .changedCitationFormats]`, the edits that change a board's labels, suggestions or annotations. `.sourceWorkspace`'s `invalidateOn` is its own kinds unioned with it (unchanged in effect); `.citationsByArtifact` gains `invalidateOn: CatalogMutationKind.boardVocabulary` with `.allCached(.citationsByArtifact)`, marked stale while hidden | Every cache that holds a board follows one declared set (`docs/catalog-caches.md`: every cache names the signal that updates it); S15-39's flags then read current annotations | A second hand-written list on the Citation key |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `vocabkey.FieldPage` | const | `vocabkey.PropertyToponym` | Same shape, a new key family |
| `sourcevocab` `TestFieldKeysMatchSeed` | test | `subjectvocab` `TestVocabKeysMatchSeed` | Same guard for field keys |
| `sourcemetadata.PageFieldID(q database.Querier) ([]byte, error)`, `PageText(r Row, f metadatafields.Field) string`, `CitationPages(q database.Querier, citationIDs [][]byte) (map[string]string, error)` | funcs | `citationrender.fillValues` | It walks every level for a render; the rule bans the walk here |
| `effects.ReadCitationBoards`; Swift `CatalogRead.citationBoards` | read | `ReadInheritedValues` | Keyed by Source; the list key holds a graph |
| `ListedCitation.metadata`, `.page_label` | proto | `CreateCitationWithObservationsResponse.metadata` | Extends the list message |
| `CatalogListedCitation.metadata`, `.pageLabel` | Swift | — | Mirror D-6 |
| `CitationComposerContext.metadataHost`, `.metadataBoard`, `.metadataBoardError`, `.metadataFields`, `openMetadataBoard(for:)` | members | `ArtifactSheetModel.host`, `.board`, `init` | Same types, built once where the composer's writes are |
| `CatalogMutationKind.boardVocabulary` | set | `.sourceWorkspace`'s `invalidateOn` list | Shared by both board caches (D-17) |
| `CitationComposerModel.citationDirty` | property | `fields.isDirty` | Adds the board |
| FakeStore `createCitationMetadata`, `updateCitationMetadata` | test recorders | `createArtifactMetadata` | Same shape |
| `L10n.CitationComposer.metadataLabel` ("Citation metadata"), `.metadataBoardUnavailable` | keys | `L10n.Sources.artifactCopyDetailsLabel` | The composer's namespace |
| `macos/App/Features/MetadataBoard/` *(new)* | folder | `Features/Sources` | D-15 |

**Builds on.** `MetadataDraftHost`, `MetadataBoardModel`, `DraftMetadataBoardField` (rule "One metadata board"); the effects registry's `Reads`; the composer's `applyWrite` reload.
**Deletes.** `ArtifactLocatorCapabilities.supportsPrintedPage` and its four values; `CitationComposerModel.pageLabel`; `CitationFormFocus.printedPage` and `order`'s `printedPageOffered:`; `labelAndPrintedPage`, `printedPageField`; `L10n.CitationComposer.printedPageLabel`, `printedPagePrompt`, `printedPageHelp` and their catalog keys; `citationWords.pageLabel` in `graphfill`.
**Next adds.** S15-39 and S15-41 draw flags and marks on this board, in its new folder, with no composer change. S15-58 deletes `{citation.page}`; S15-59 deletes `CitationLocatorDraft.pageLabel`, then read only by the locator codec.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A Citation board in the composer | `MetadataBoardView` via `DraftMetadataBoardField` | Rebuilt per opened Citation (D-8); a deleted parent or an unlisted Citation shows D-12's line |
| A cold composer (restore, deep link) | the board's field list | The place warms `.metadataFieldsList` (D-8) |
| Metadata values tables reporting `citation_boards` | `.citationsByArtifact` refresh | Hidden keys mark stale (descriptor `whenHidden: .markStale`) |
| A type change, field relabel or delete, suggestion or format edit while the composer is closed | the cached Citation boards | D-17 marks every cached list stale |

### Scale

At the map's Scale (a Source of 600 Citations, up to 8 values each, read one Artifact at a time; an Artifact of up to 60 Citations):

- `ListCitationsByArtifact`: one `ListWorkspaces` over up to 60 owners (S15-55's one batched read) and one key lookup. T-6 reads 60 Citations of 8 values each and logs the time; the board read's batching is S15-55's, tested there.
- `graphfill`: one key lookup, one `readByOwners` and one field read per graph load (a graph shows up to 10 Citations).
- A Source value write names every graph of the Source for `citation_boards`: a revalidation per cached list key, nothing read for hidden keys.

### Edges

- **Assumptions.** `ResolveKeysTx` prefers the seed's field when a researcher made another `page` (T-1).
- **Neighbors.** Own Page vs inherited Page (AC-2.4); unknown vs supplied (AC-2.2, AC-2.3); no field (AC-2.5).
- **Removed inputs.** Deleting the `page` field releases its values (S15-54's delete path), which reports `citation_boards` and the graphs (D-5, S15-54 D-7): the page leaves both readers (T-3).
- **Real data.** None — no table-driven rule changes.
- **Untrusted size.** A value is capped by `citationformat.Display` (`MaxDisplayBytes`).

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/vocabkey` | D-1 |
| `core/database/metadatafields` | D-3 |
| `core/database/sourcemetadata` | D-2 |
| `core/database/graphfill` | D-4 |
| `core/database/effects` | D-5 |

### FFI

`api/proto/engine.proto`: `ListedCitation` fields 4 and 5 (D-6). Handler `api/ffi/handlers/citations.go` `ListCitationsByArtifact`, entries through `metadataEntriesProto` as `CreateCitationWithObservations` maps its board. Regenerate with `./scripts/generate-proto.sh`.

### macOS

The brief's inventory (completed from the board, D-10): the citation form (`sideForm`, `panelForm`) holds Label, then `DraftMetadataBoardField` with prefix `citationComposer.metadata`, shown when `context.metadataBoard` is not nil, else D-12's line through `PVErrorText` as `citationLoadErrorLine` draws its own; the menu row per D-13. States: a new Citation's board appears when its read answers (no loading state); a 30-row board scrolls with the form. Accessibility: CB-8, from the shared rows.

### Strings

New: `L10n.CitationComposer.metadataLabel` = "Citation metadata"; `L10n.CitationComposer.metadataBoardUnavailable` = "The Citation's metadata can't be shown. Close the composer and open it again from the Source." Changed: `sourceTypes.suggested.meaning` → "Offered on every Source, Artifact, Evidence graph and Citation of this type"; the translator comments of `sources.page.metadataInheritedFrom`, `metadataInheritedAccessibility` and `metadataOverrides` name the level as "(Source, Artifact or Evidence graph)". Removed: the keys in **Deletes**.

## 7. Steps

**STEP-1 — The page key and its reader**
Files: `core/vocabkey/vocabkey.go`, `core/database/sourcevocab/registry_test.go`, `core/database/metadatafields/metadatafields.go`, `core/database/sourcemetadata/annotation.go`, `annotation_test.go`.
Do: D-1, D-3, D-2.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/metadatafields/... ./core/database/sourcemetadata/... ./core/database/sourcevocab/...` passes with T-1, T-11.

**STEP-2 — The graph reads the Citation's own page**
Files: `core/database/graphfill/load.go`, `records_test.go`, `core/database/conclusiondetails/conclusiondetails_test.go`.
Do: D-4. In both `records_test.go` tests and in `TestForEntityCitationParts`, install the seed with `sourcevocabtest.Install(c)` and set Page values instead of locator labels. `TestLoadParsesEachCitationOnce` keeps its one-parse checks for the locator and drops its `PageLabel` value and shared-string assertions.
Check: `go test -tags fts5 ./core/database/graphfill/... ./core/database/conclusiondetails/...` passes with T-2, T-3.

**STEP-3 — Value writes move the Citation boards' read**
Files: `core/database/effects/registry.go`, `reads_test.go` (`want` gains `ReadCitationBoards` with the four values tables), `reads_resolve_test.go` (`readsFixture` holds a value at each level).
Do: D-5's Go half.
Check: `go test -tags fts5 ./core/database/effects/...` passes with T-4.

**STEP-4 — The list carries each Citation's board and page**
Files: `api/proto/engine.proto`, `api/ffi/handlers/citations.go`, `citations_test.go` (`citationFixture` installs the seed with `sourcevocabtest.Install`). Skill: `add-ffi-handler`.
Do: D-6; `./scripts/generate-proto.sh`.
Check: `go test -tags fts5 ./api/ffi/handlers/...` passes with T-5, T-6.

**STEP-5 — Swift store and reads**
Files: `Platform/GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift`, `macos/ProvenenciaTests/OnboardingModelTests.swift`, `Features/Workspace/Session/CatalogMutation.swift`, `CatalogQueryRegistry.swift`.
Do: D-7; D-5's Swift half; D-17.
Check: `xcodebuild test` builds; existing composer tests pass.

**STEP-6 — The board gets its own folder; the composer place warms its fields**
Files: D-15's files; `Features/Workspace/Session/PlaceRegistry.swift`. Skill: `add-workspace-place`.
Do: D-15 (moves only); add `.metadataFieldsList(project:)` to the `.citationComposer` spec's `queryKeys`.
Check: the app builds; `MetadataBoardModelTests`, `MetadataDraftHostTests` pass unchanged; T-10.

**STEP-7 — New strings**
Files: `Platform/L10n.swift`, `Resources/Localizable.xcstrings`. Skill: `add-localized-string`.
Do: § 6 Strings, all but the removals.
Check: the app builds.

**STEP-8 — The composer holds and saves the board**
Files: `CitationComposerContext.swift`, `CitationFieldsDraft.swift`, `CitationComposerModel.swift`, `CitationComposerModelTests.swift`.
Do: D-8, D-9, D-11, D-12.
Check: T-7, T-8 pass.

**STEP-9 — The form draws it; Printed page goes**
Files: `CitationComposerEvidenceColumn.swift`, `CitationComposerView.swift`, `Features/ArtifactViewer/ArtifactViewerKind.swift`, `ArtifactViewerModelTests.swift` (drop the `supportsPrintedPage` lines), `CitationComposerModelTests.swift` (the focus-order test asserts D-14's two orders; the `locatorText` test becomes T-9). Skill: `add-ui-component`.
Do: D-10, D-13, D-14; the Deletes but the strings.
Check: the app builds; T-9 passes; manual check steps 1–4.

**STEP-10 — Old strings go**
Files: `Platform/L10n.swift`, `Resources/Localizable.xcstrings`.
Do: the string removals in **Deletes**.
Check: `rg 'printedPageLabel|printedPagePrompt|printedPageHelp|supportsPrintedPage|printedPageField|printedPageOffered|labelAndPrintedPage' macos docs .agents` has no hit.

**STEP-11 — Docs**
Files: `completed.md`, `deployment-plan.md` (map row), this plan, `design/S15-D29-citation-composer-metadata.md` → `design/archive/`, `design/README.md`, `docs/source-layer-data-model.md` § 5.5 (the boards list names the composer's Citation board), `docs/interpretation-layer-data-model.md` § 3.2 (:253: the printed page is the Citation's Page value), `.agents/skills/add-workspace-place/SKILL.md` (:175: the composer's Save goes through its write's reload, not `applySavedMetadata`; the board's new folder), `docs/macos-client-patterns.md` (:89: `citation_boards` in the `reads` list).
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py` passes; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/sourcemetadata/annotation_test.go` `TestCitationPages` *(new)*, table, seed from `sourcevocabtest.Install` | own "14" → "14"; unknown → "unpaginated"; supplied "14" → "[14]"; graph holds "2", Citation none → absent; no seed (no `page` field) → empty map, no error; a researcher field made with `metadatafields.Create(tx, "Page", …)` holding "99" beside the seed's "14" → "14" | AC-2.1, AC-2.2, AC-2.3, AC-2.4, AC-2.5, D-2 |
| T-2 | Go | `core/database/graphfill/records_test.go` `TestGraphRecordsCarryCitationWords` | own Page "14", locator `page_label` "9", file page 37 → `PageLabel` "14", `ArtifactPage` 37; no own Page → "" | AC-2.1, AC-2.4, D-4 |
| T-3 | Go | `core/database/conclusiondetails/conclusiondetails_test.go` `TestForEntityCitationParts` | own Page "23" → `Outcome.PageLabel` "23"; after the `page` field is deleted → "" | AC-2.1, Edges |
| T-4 | Go | `core/database/effects/reads_test.go` `TestReadsDeclare`; `reads_resolve_test.go` `TestMetadataValuesNameCitationGraphs` *(new)* | `ReadCitationBoards` lists the four values tables, and `ReadCitations` does not; a value set on a Citation, its graph, its Artifact and its Source each names the Citation's graph | D-5 |
| T-5 | Go | `api/ffi/handlers/citations_test.go` `TestListCitationsByArtifactBoards` *(new)* | two Citations, one with own Page "2" → its `metadata` holds the saved Page row and `page_label` "2"; the other's Page entry carries `inherited` from the graph and `page_label` "" | AC-2.6, D-6 |
| T-6 | Go | same file `TestListCitationsByArtifactScale` *(new)* | 60 Citations, 8 values each → every board holds its 8 rows and every `page_label` is right; the time logged with `t.Logf` | D-6, Scale |
| T-7 | Swift | `CitationComposerModelTests.swift` `newCitationSavesBoard` *(new)* | New citation, Page "2" set on the host, Save → `createCitationMetadata` holds the draft; `citationDirty` false; then Column "4" and Save → `updateCitationMetadata` holds Column alone. The same create through `ensuredCitationID` | AC-1.1, AC-1.3, D-9 |
| T-8 | Swift | same file `boardChangeIsUnsaved`, `draftReadFailure` *(new)* | a host change → `canSaveCitation` and `hasUnsavedDocumentWork` true; Save → `updateCitationMetadata` holds only the draft; a draft read failing with `sourcemetadata.invalid` → `metadataBoardError` is the new string, host nil | AC-1.2, AC-1.5, AC-1.6, D-11, D-12 |
| T-9 | Swift | same file `menuRowReadsOwnPage` (the `locatorText` test, rewritten) | `locatorText(pageLabel: "2", locator: page 2)` → "p. 2 · image 2"; `pageLabel: ""`, page 40 → "image 40" | AC-2.6, D-13 |
| T-10 | Swift | `CatalogQueryRegistryTests.swift` `composerWarmsMetadataFields` *(new)*; `citationBoardsReloadCitationList` *(new)* | the `.citationComposer` spec lists `.metadataFieldsList`; a `citation_boards` read for a graph revalidates that graph's `.citationsByArtifact` key and no `.citationCounts` key; `.changedSourceType` and `.updatedMetadataField` each mark a hidden `.citationsByArtifact` key stale (`boardVocabularyStalesCitationLists` *(new)*) | D-5, D-8, D-17 |
| T-11 | Go | `core/database/sourcevocab/registry_test.go` `TestFieldKeysMatchSeed` *(new)* | `vocabkey.FieldPage` is a seeded field's key | D-1 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `MetadataDraftHostParityTests`, `TestDraftBoardScenarios`, `TestSeedCitations`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; the board's old paths (`Features/Sources/MetadataBoard`, `SourceOwnerForm.swift` `DraftMetadataBoardField`) too; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — or none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated)
- [ ] Domain docs and skill updated: the four files in STEP-11
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

Bar 13, on a new project (the seed has `page`):

1. Add Source **Calder Gazette** of type Newspaper item with a PDF Artifact and a graph. Open the composer; **New citation**: the Citation metadata board shows Page and Column empty, Published in inherited if set on the Source; no Printed page field.
2. Type Page "2" and Column "4", Save. Reopen the Citation from the Citation menu: both are saved rows; the menu row reads "p. 2 · image …"; the provenance sheet's citation reads "…, p. 2, col. 4…".
3. Give the graph Page "7" on its form. A second **New citation** on the same graph shows Page "7" "From Evidence graph" (AC-1.4); save it with a Label only; its citation prints "p. 7".
4. Open a Citation on an image Artifact and one on an audio Artifact: each shows the board and no Printed page field (AC-1.7).
5. Promote an Observation of the first Citation to a Conclusion: the Conclusion detail's line reads "p. 2".
6. Type a value, then pick another Citation: the discard confirm shows. Resize across 1600pt with an override open: the text stays.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| `from("artifact_id", chain(inbound(…), field(…)))` does not check against `evidence_graphs` | T-4; Stop condition |
| Opening the board races a fast Citation switch | `openMetadataBoard` runs inside the open task, after its `Task.isCancelled` checks |

**Stop and report if:**

- A D-5 path fails `validate` or names no graph in T-4.
- `CitationPages` cannot run on `graphcache.Graph` after D-3 (a `*sql.Tx`-only call underneath).
- `ListCitationsByArtifact` calls a board or page read per Citation.
- The agreed board places the board away from Label, or adds a control the inventory does not list.
- A moved board file needs a code change to build in its new folder (D-15 moves only).

## 12. Open questions

- The board's placement in the side form, before or after the transcription (D-10). Recommended: after Label, before the transcription, as the brief draws first. Answered by the board.

## 13. PR

**Title:** S15-56 — The composer edits a Citation's metadata
**Body:** objective in one sentence; what shipped against US-1 and US-2; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-56-composer-citation-metadata.md`.
