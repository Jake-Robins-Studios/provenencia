# S15-56 — The composer edits a Citation's metadata

**Status:** Planned
**Spike / slice:** Spike 15 · Slice 11 — Metadata at any level
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D29](../design/S15-D29-citation-composer-metadata.md), board agreed 2026-11-26
**Board:** [Claude Design — Citation Composer](https://claude.ai/artifact/3GSFQZjqdQjL8v2rpgMiDc), page *Citation Composer*, section "S15-D29 · The Citation's metadata", frames 1a – 10 (drawn by the *Citation Header* component's `metaFieldNode` and `sheetNode`). The implementer can open the link; the brief's CB rows and § 6 macOS say what it draws
**Depends on:** S15-55 (landed [#970](https://github.com/Jake-Robins-Studios/provenencia/pull/970)), S15-60 (landed [#975](https://github.com/Jake-Robins-Studios/provenencia/pull/975)), S15-64 (landed [#959](https://github.com/Jake-Robins-Studios/provenencia/pull/959)), S15-D29
**Blocks:** S15-58, S15-39, S15-41
**Branch:** `s15-56-composer-citation-metadata`
**Version bump:** minor, 0.43.0 (today's `VERSION`) → **0.44.0** (or the next minor after `main`'s `VERSION` when you rebase): the composer gains a metadata sheet and the wire gains `ListedCitation` fields ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md) (the composer place's keys, the citations-by-Artifact refreshes), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`, `.cursor/rules/swift-tests.mdc` (FakeStore seeds what Go composes)
**Context:** working rules "One metadata board", "A board shows what its owner inherits", "The printed page is a metadata field", "Metadata saves with its owner's write", "A board adds a field in an inline row", "One window"; [`source-layer-data-model.md` § 5](../../../source-layer-data-model.md); [`catalog-caches.md` § Swift caches](../../../catalog-caches.md#swift-caches)
**Planned:** 2026-11-25 against `main` @ `620ddaa`; reworked for the agreed board 2026-11-26
**Review:** [`S15-56-composer-citation-metadata.review.md`](S15-56-composer-citation-metadata.review.md) — Fits with changes; Ready with changes; two rounds and a check of the rework for the agreed board, no blocker open

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

A researcher edits a Citation's metadata from the citation composer: a Metadata line under Label (**Edit metadata…** and a count) opens a **Citation metadata** sheet holding the same board every other owner has: the Citation's own values, the type's suggestions, what it inherits from its graph, Artifact or Source, and Add field. The sheet saves on its own (board S15-D29, 2026-11-26). The Printed page input goes: the printed page is the board's **Page** row, and the Conclusion detail, the composer's Citation menu and the citation line read the Citation's own Page value.

**Why now.** S15-54 made a Citation hold values and its writes take a draft; S15-55 gave a new Citation a draft board under its graph and Artifact; S15-64 drew inherited rows; S15-60 seeded `page`. Nothing draws a Citation board yet, and the composer's Printed page writes a locator key no format will read once S15-58 lands.

**What stays.** The locator strip, the viewer, the Observations column, the authoring box and the composer's split. Rendered citations keep `{meta.page|citation.page}` until S15-58, and the locator keeps `page_label` until S15-59. No flags or marks on the board (S15-39, S15-41).

## 2. User stories

**US-1.** As a researcher, when I edit a Citation in the composer, I fill its metadata in its sheet so that its citation prints its page and column.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A saved Citation on a newspaper Source (type Newspaper item, seeded) with no own values; Edit metadata…; Page "2" and Column "4" typed in the sheet; Save metadata | One `UpdateCitation` with the Citation's stored columns and a draft of both values, which writes nothing for the Citation itself; the sheet closes; the line reads "2 own · 2 inherited" once the list reloads; its rendered citation reads "…, p. 2, col. 4; …" |
| AC-1.2 | Label edited and not saved, then Edit metadata…, Column changed to "5", Save metadata | The `UpdateCitation` carries the saved Label, not the typed one; the form still shows the typed Label and its Save stays enabled |
| AC-1.3 | **New citation**, not saved yet, on a graph holding Page "2" and Column "4" and a Source holding Published in and Provider | The button reads "Metadata" and is off; the count reads "Inherits 4 values. Add its own after the first save"; after the first Save the line reads "4 inherited" and the button is on |
| AC-1.4 | A Citation whose graph holds Page "2" and which holds none; the sheet open | Its Page row shows "2" with "From Evidence graph"; its citation prints "p. 2" |
| AC-1.5 | A value typed in the sheet, then Cancel, or a sidebar navigation | The discard confirm asks (the kit's on Cancel, the composer's leave confirm on navigation, which returns to the sheet); Discard closes it and stores nothing |
| AC-1.6 | **New citation** on an Artifact whose graph was deleted after the composer opened | The line shows `L10n.CitationComposer.metadataBoardUnavailable` and no button; Label and the transcription save as today |
| AC-1.7 | Any Artifact kind (image, PDF, audio, video, unsupported) | The Metadata line shows; there is no Printed page field |

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
| The Metadata line and its count in both form arrangements (CB-1, CB-2, CB-W1), Tab order and VoiceOver (CB-8, CB-9) | STEP-9 |
| The Citation metadata sheet over a saved Citation's board from the cached list (CB-3); a new Citation's inherited count from the draft board read (CB-5) | STEP-4, STEP-8 |
| The sheet saves on its own through `UpdateCitation`; Cancel asks when something was typed (CB-4) | STEP-5, STEP-8 |
| The read failure line (CB-6; S15-55 review UX-1) | STEP-7, STEP-8 |
| Menu row reads the own Page (CB-7) | STEP-4, STEP-9 |
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
| Metadata on a Citation not yet saved | not planned (board S15-D29 frame 6: off until the first save) |
| A metadata draft on `CreateCitationWithObservations` from Swift | not planned (a new Citation has no sheet) |
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
| Citation writes | `citations.go` `UpdateCitation` (:159), proto `metadata` 9/3; `core/database/citations/citations.go` `Update` (:336) | Takes a draft and answers the board since S15-54; Swift sends none. `citations.Update` writes and audits nothing when the fields equal the stored ones (`change == nil`), so an update carrying the stored columns verbatim is a metadata-only write; its only changes are `citation_metadata` rows, which today report no read the composer's list follows |
| Swift store | `macos/App/Platform/GenealogyStore.swift` `createCitationWithObservations` (:2129), `updateCitation` (:2149), `listCitationsByArtifact` (:2185), `CatalogListedCitation` (:425); `GoStore.swift` (:2345); `FakeStore.swift` (Artifact draft recorders :263–269, `metadataByOwner`, its own create caller :2750); `macos/ProvenenciaTests/OnboardingModelTests.swift` stub | No metadata argument or rows |
| Cache | `Features/Workspace/Session/CatalogQueryRegistry.swift` `.citationsByArtifact` (:367), `.citationCounts` (:301); `PlaceRegistry.swift` the `.citationComposer` spec (:55–72) | The list follows `.reads(.citations)`; the composer place does not warm `.metadataFieldsList` |
| Board files | `Features/Sources/MetadataBoardView.swift`, `MetadataBoardModel.swift`, `MetadataBoardHost.swift` (protocol + `SourcePageMetadataHost`), `MetadataDraftHost.swift`, `MetadataBoardDialogs.swift`; `SourceOwnerForm.swift` `DraftMetadataBoardField` | Sources-only snowflakes; the composer would be their first caller elsewhere |
| Composer writes | `Features/CitationComposer/CitationComposerContext.swift` `applyWrite` (:81), `citationsKey(artifactID:)` (:86), `fieldsKey` (Properties) | No metadata |
| Composer state | `CitationComposerModel.swift` `pageLabel` (:309), `activeCitationID`, `selectedArtifactID`, `openBlankCitation`, `resetComposerIdentity`, `selectArtifactAndLoad`, `isTranscribing`, `isDrawingDepiction`, `presented` (`ComposerPresented`), `show(_:)`, `suspendedDialog()`, `restorePresented(_:)`, `hasUnsavedDocumentWork` | No metadata |
| Composer form | `CitationComposerEvidenceColumn.swift` `CitationFormFocus`, `labelAndPrintedPage`, `printedPageField`, `CitationStepMenuRow.locatorText`; `CitationComposerView.swift` `composeSplit` (:299); `Features/ArtifactViewer/ArtifactViewerKind.swift` `supportsPrintedPage` | Draws Printed page from the locator |
| Go tests | `core/database/graphfill/records_test.go` `TestGraphRecordsCarryCitationWords` (:238), `TestLoadParsesEachCitationOnce` (:327); `core/database/conclusiondetails/conclusiondetails_test.go` `TestForEntityCitationParts` (:218); `api/ffi/handlers/conclusion_detail_test.go` `TestConclusionDetailProtoCarriesVoteArtifactAndMembers` (:201) | The first three assert the locator's label; the last builds an `Outcome` by hand and stays as is |
| Swift tests | `macos/ProvenenciaTests/ArtifactViewerModelTests.swift` (:65–69, `supportsPrintedPage`); `CitationComposerModelTests.swift` (:827–830 `order(…printedPageOffered:)`, :835–857 `locatorText` with `pageLabel`); `CatalogQueryRegistryTests.swift` | Use the APIs this PR deletes |
| Docs that go false | `docs/interpretation-layer-data-model.md` :253 ("The composer writes `page_label` from its Printed page field"); `.agents/skills/add-workspace-place/SKILL.md` :175 (every board Save goes through `SourcePageContext.applySavedMetadata`); `docs/macos-client-patterns.md` :89 (the `reads` list); `docs/source-layer-data-model.md` § 5.5 (the boards list) | Name the old shape |

**Precedent.** S15-34 (#819) put a draft board in a sheet: `ArtifactSheet` presents `ArtifactSheetModel` with `pvFormDialog(item:copy:width:isRunning:isDirty:confirmDisabled:…)`, the model builds `MetadataDraftHost` from the cached rows and then `MetadataBoardModel(host:)`, sends `host.draft` in its one write and calls `host.markSaved()`. Copy that shape for the sheet; its rows come from the composer's cached Citation list, and the write's `citation_boards` read (D-5) reloads that list, so no patch is added. The presentation follows the composer's own dialogs (`ComposerPresented`, `newSubjectBinding`), not the Source page's optional sheet model.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `vocabkey.FieldPage = "page"` in `core/vocabkey/vocabkey.go`; `sourcevocab` gains a parity test that every metadata-field key `vocabkey` declares is a seeded field key | Rule "The printed page is a metadata field": the key is declared once, and a seed rename fails CI instead of blanking every page | A literal in each reader |
| D-2 | The printed page is read in two exported steps in `sourcemetadata` `annotation.go` (signatures in Codebase fit): `PageFieldID` resolves `vocabkey.FieldPage` with `metadatafields.ResolveKeysTx(q, …, vocabkey.OriginProvenencia)` (Unknown or Ambiguous → nil, no error); `PageText(row Row, f metadatafields.Field) string` is `citationformat.Display(CitationValue(row, f))`. `CitationPages` composes them for a list of Citations: owners are `Owner{Level: vocabkey.LevelCitation, ID: id}` per id, read with `readByOwners` (what `ListByOwnersTx` reads), the field from `metadatafields.MapByIDsTx`; the map is keyed `string(id)` (raw bytes, as `graphfill`'s `words`); a Citation with no own row, or whose `PageText` is "", is absent | The rule: own value only, marks as a citation prints them, one lookup and one formatter for both readers | A walk up the levels (the rule forbids it); Swift picking the row out of the board (a second resolution) |
| D-3 | `metadatafields.ResolveKeysTx`, `ListByIDsTx` and `MapByIDsTx` take `q database.Querier` instead of `tx *sql.Tx`; names and behavior unchanged; every caller compiles as is | `graphfill` reads through `graphcache.Graph`; `*sql.Tx` is a Querier | Querier copies beside them; renaming the `Tx` functions |
| D-4 | `graphfill` keeps parsing the locator for `ArtifactPage` and stops reading its `Label` (`citationWords.pageLabel` goes); after the scan it calls `CitationPages` once over the graph's Citation ids and sets each Observation's `PageLabel` from it. `CitationLineDisplay` and the proto are unchanged: "p. unpaginated" and "p. [14]" read as the seeded formats print them | One batched read per graph load; S15-54 D-7 already invalidates loaded graphs on `citation_metadata` | A per-Citation read; a proto mark field (the text carries it) |
| D-5 | A new read `effects.ReadCitationBoards = "citation_boards"` ("the Citation boards of a graph's Citations: their own and inherited metadata values"), key table `evidence_graphs`. The four values tables report it, as `Reads` extras in `registry` (`evidence_graph_metadata` and `artifact_metadata` gain partial literals that `metadataEffects` fills, as S15-61 D-9 lets an entry declare extras): `citation_metadata` `up("citation_id", "graph_id")`; `evidence_graph_metadata` `field("graph_id")`; `artifact_metadata` `from("artifact_id", chain(inbound("citations", "artifact_id"), field("graph_id")))`; `source_metadata` `graphsOfSource(field("source_id"))`, beside its `ReadInheritedValues`. Swift `CatalogRead.citationBoards`; `.citationsByArtifact` follows it as it follows `.citations`; `.citationCounts` does not | Each own or inherited value move reaches the composer's list (S15-54 Out, S15-64 Next adds), and count keys do not reload on metadata edits | Reusing `ReadCitations` (its counts would reload on every value write); deriving the paths from `MetadataTables.Ups` (they point up; this path points down from an owner to the graphs of the Citations under it, which no table declares) |
| D-6 | `ListedCitation` gains `repeated MetadataWorkspaceEntry metadata = 4` (the Citation's board) and `string page_label = 5` (the own Page's `PageText`, "" none), named as `ReconcilerOutcomeDetail.page_label`. `ListCitationsByArtifact` makes one `sourcemetadata.ListWorkspaces` call over the listed Citations, resolves `PageFieldID` once on `c.DB()`, and takes each `page_label` from that board's entry whose `Field.ID` is the page field and whose `Value` is set, through `PageText`: the page and the board come from the same rows | Rule "One window": the composer opens a Citation from the cached list with no fresh read; one read per Artifact (Scale) | A `GetMetadataBoard` per Citation opened; a second `readByOwners` beside the boards |
| D-7 | Swift `updateCitation` gains `metadata: CatalogMetadataDraft?` and returns `(CatalogCitation, [CatalogMetadataEntry], CatalogWriteEffects)`; rows map with `Self.mapMetadataEntry` as `updateArtifact` maps them; `CitationFieldsDraft.saveCitation` passes `nil`. `createCitationWithObservations` is unchanged. `CatalogListedCitation` gains `metadata: [CatalogMetadataEntry] = []` and `pageLabel: String = ""`. FakeStore records each update draft in `updateCitationMetadata` and applies none, as its Artifact recorders do; `listCitationsByArtifact` fills each row's `metadata` from `metadataByOwner[MetadataOwner(level: .citation, id:)]` and its `pageLabel` from `listedPageLabels[citationID]` *(new)*, seeded, never computed from entries; a test scripts the rows after a save through `metadataWriteResults`; the test stub follows the new signature | S15-54 D-12: the store gains the draft with its first caller; `swift-tests.mdc` | A draft on the create (a new Citation has no sheet) |
| D-8 | The composer reads the open Citation's rows, never stores them: `CitationComposerModel.metadataRows` *(new)* is the `metadata` of the `CatalogListedCitation` with `activeCitationID` in the cached `citationsKey(artifactID: selectedArtifactID)` value, so it follows every reload of that list (a sheet save, a Citation create, D-5 and D-17). A new Citation (no `activeCitationID`) reads `draftMetadataRows` *(new)*, set from `store.getDraftMetadataBoard(projectDir:parents: [graph, Artifact], level: .citation)` by `openBlankCitation`, `resetComposerIdentity` and `selectArtifactAndLoad`, and cleared when a Citation opens. `metadataLineError` *(new)* is D-12's. The field list is `metadataFields`, the `.metadataFieldsList(project:)` query, which the `.citationComposer` place now warms | One source of truth for the line and the sheet: the cached list | A host built per Citation open on the context (no board in the form any more) |
| D-9 | The sheet is `CitationMetadataSheetModel` *(new, `Features/CitationComposer/`)*, shown as `ComposerPresented.metadata(CitationMetadataSheetModel)` *(new case; equal when the Citation ids are equal)* through `show(_:)`, and presented by `CitationMetadataSheet` *(new)* with `pvFormDialog(item:)` over a binding derived from `presented`, as `newSubjectBinding` derives its own: width 600, `scrollsBody: true`, `isDirty: host.isChanged`, `confirmDisabled: !host.isChanged`, `isRunning: isSaving`. `suspendedDialog()` and `base(of:)` treat it as `.newSubject` is treated, `restorePresented` shows it again, and `hasUnsavedDocumentWork` also counts a shown sheet whose host `isChanged`, so the composer's leave confirm asks and returns to the sheet. `requestEditMetadata()` builds the model from `metadataRows`, `metadataFields` and the open Citation's cached `CatalogListedCitation.citation` (`MetadataDraftHost`, then `MetadataBoardModel(host:)`). Its `save()` calls `store.updateCitation` with that cached row's stored columns verbatim (`locatorJSON`, `transcription`, `description`, `transcriptionUncertain`, `transcriptionNote`) and `metadata: host.draft`; on success `host.markSaved()`, `context.applyWrite(effects)`, and `show(nil)`; on failure `board.showRefusal(error)` places a refusal on its row, else the sheet's save error shows, as `ArtifactSheetModel.save` does. The citation form's fields are not touched | Board S15-D29: the sheet saves on its own; `citations.Update` writes nothing for byte-equal columns (rule "Metadata saves with its owner's write", no new RPC); one presentation state for every composer dialog | A metadata-only RPC (a second write path); re-encoding `fields.baseline` (its locator does not round-trip: `CitationLocatorDraft.decode` drops page marks, `encodeJSON` key order is unstable); an optional `metadataSheet` beside `presented` (outside the leave guard) |
| D-10 | The Metadata line (`CitationComposerEvidenceColumn.metadataLine` *(new)*) sits under Label in both `sideForm` and `panelForm`, in place of `labelAndPrintedPage`: `PVField(label: L10n.CitationComposer.metadataLabel)` holding `PVButton(.secondary, size: .sm, icon: .list)` and a `PVFont.body(size: PVTypeScale.caption)` `PVColor.textMuted` count (italic on a new Citation), wrapping as the board's flex row does. The button is `editMetadata` ("Edit metadata…") on a saved Citation and `metadataNew` ("Metadata"), disabled, on a new one; it is disabled while `isTranscribing || isDrawingDepiction`; its accessibility hint is the count. With `metadataLineError` the field holds only `PVErrorText(error, announces: true)` | Board S15-D29 frames 1a, 1b, 6, 7, 9 (`metaFieldNode`) | Values drawn in the form (the board removed them) |
| D-11 | The count (`CitationComposerModel.metadataCount` *(new)*): own = rows with `hasValue`; inherited = rows without `hasValue` and with `inherited`; `L10n.CitationComposer.metadataCount(own:inherited:)` joins the non-zero parts with " · ", `metadataNone` when both are zero; a new Citation reads `metadataInheritsNew(count:)` over `draftMetadataRows`' inherited rows | Board S15-D29 `metaFieldNode` | Counting in Go (the rows already carry both facts) |
| D-12 | `metadataLineError` is `L10n.CitationComposer.metadataBoardUnavailable` when the draft read fails with `(error as? CoreInvokeError)?.engineCode == .sourceMetadataInvalid` (as `MetadataBoardModel.swift:307` checks), and when the cached list has a value that lacks `activeCitationID` while `context.isCreatingCitation` (now `private(set)`) is false: a Citation read through `store.getCitation`. Any other draft read error is `L10n.Errors.message(for:)`. While the list key has no value yet, or a create and its list reload are in flight, the line shows the button off and no count | CB-6; S15-55 D-6; `createCitationIfNeeded` sets the id before its list reload ends | The engine's save-worded sentence; a raw code string; showing the error during the first save |
| D-13 | `CitationStepMenuRow.locatorText(pageLabel:locator:)` takes the listed Citation's `pageLabel` for "p. 14" and the locator for "image 37" and "region" | User, 2026-11-25: the row shows the Citation's own Page value | Dropping the printed page from the row |
| D-14 | `CitationFormFocus` keeps `.label` and `.transcription`; `order(_:)` takes the layout alone and answers `[.label, .transcription]` for `.side`, `[.transcription, .label]` for `.panel` | CB-8: the Tab list names text fields only, as the Artifact sheet's | Adding the button to the Tab list |
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
| `CitationMetadataSheetModel`, `CitationMetadataSheet` | type, view | `ArtifactSheetModel`, `ArtifactSheet` | Same shape over the Citation; the Artifact sheet also edits Label, file and graphs |
| `CitationComposerModel.metadataRows`, `.draftMetadataRows`, `.metadataLineError`, `.metadataCount`, `.metadataSheet`, `requestEditMetadata()`; `CitationComposerContext.metadataFields` | members | `SourcePageContext.metadataRows(for:)`, `.fields` | The composer's own reads of its cached list |
| `CitationComposerEvidenceColumn.metadataLine` | view | `labelField` | The board's line |
| `CatalogMutationKind.boardVocabulary` | set | `.sourceWorkspace`'s `invalidateOn` list | Shared by both board caches (D-17) |
| FakeStore `updateCitationMetadata` | test recorder | `updateArtifactMetadata` | Same shape |
| The § 6 Strings keys | keys | `L10n.Sources.artifactCopyDetailsLabel` | The composer's namespace |
| `macos/App/Features/MetadataBoard/` *(new)* | folder | `Features/Sources` | D-15 |

**Builds on.** `MetadataDraftHost`, `MetadataBoardModel`, `MetadataBoardView` (rule "One metadata board"); `pvFormDialog(item:)`; the effects registry's `Reads`; the composer's `applyWrite` reload.
**Deletes.** `ArtifactLocatorCapabilities.supportsPrintedPage` and its four values; `CitationComposerModel.pageLabel`; `CitationFormFocus.printedPage` and `order`'s `printedPageOffered:`; `labelAndPrintedPage`, `printedPageField`; `L10n.CitationComposer.printedPageLabel`, `printedPagePrompt`, `printedPageHelp` and their catalog keys; `citationWords.pageLabel` in `graphfill`.
**Next adds.** S15-39 and S15-41 draw flags and marks on this board, in its new folder, with no composer change (the sheet shows them). S15-58 deletes `{citation.page}`; S15-59 deletes `CitationLocatorDraft.pageLabel`, then read only by the locator codec.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| The Citation metadata sheet over the composer | `MetadataBoardView` in `CitationMetadataSheet` | Built from the cached rows each time it opens (D-9); a deleted parent or an unlisted Citation shows D-12's line and no button |
| `UpdateCitation` with the stored columns from the sheet | `citations.Update` | Byte-equal columns write nothing (`change == nil`, T-12); an unsaved Label stays unsaved (AC-1.2) |
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

From the brief's inventory: the Metadata line (D-10) under Label in both arrangements; the sheet (D-9) over the composer, 600pt at both widths, its body the shared board in `.form` placement with prefix `citationComposer.metadata`; the menu row per D-13. States: a new Citation's line waits for the draft read with the button off; a 30-row board scrolls inside the sheet; a failed read shows D-12's line. Accessibility: CB-9; the sheet's rows read as on the Artifact sheet.

### Strings

New, under `L10n.CitationComposer`: `metadataLabel` = "Metadata"; `editMetadata` = "Edit metadata…"; `metadataNew` = "Metadata"; `metadataCount(own:inherited:)` = "%1$lld own · %2$lld inherited", with "%lld own" and "%lld inherited" when one part is zero (`metadataCountOwn`, `metadataCountInherited`); `metadataNone` = "None yet"; `metadataInheritsNew(count:)` = "Inherits %lld values. Add its own after the first save" (plural: "Inherits 1 value. …"); `metadataSheetTitle` = "Citation metadata"; `metadataSheetSubtitle(ref:label:)` = "%1$@ · %2$@. Saves on its own; the rest of the citation is not resaved", the label `metadataNoLabel` = "no label" when empty; `saveMetadata` = "Save metadata"; the sheet's Cancel reuses `L10n.Sources.cancelAction`; `metadataBoardUnavailable` = "The Citation's metadata can't be shown. Close the composer and open it again from the Source." Changed: `sourceTypes.suggested.meaning` → "Offered on every Source, Artifact, Evidence graph and Citation of this type"; the translator comments of `sources.page.metadataInheritedFrom`, `metadataInheritedAccessibility` and `metadataOverrides` name the level as "(Source, Artifact or Evidence graph)". Removed: the keys in **Deletes**.

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
Check: `go test -tags fts5 ./api/ffi/handlers/...` passes with T-5, T-6, T-12.

**STEP-5 — Swift store and reads**
Files: `Platform/GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift`, `Features/CitationComposer/CitationFieldsDraft.swift` (`metadata: nil`, effects at `.2`), `macos/ProvenenciaTests/OnboardingModelTests.swift`, `Features/Workspace/Session/CatalogMutation.swift`, `CatalogQueryRegistry.swift`.
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

**STEP-8 — The composer reads the rows; the sheet saves them**
Files: `CitationComposerContext.swift` (`isCreatingCitation` `private(set)`; `applyWrite`'s comment names the `citations` and `citation_boards` reads), `CitationComposerModel.swift`, `CitationMetadataSheetModel.swift` *(new)*, `CitationMetadataSheet.swift` *(new)*, `CitationComposerView.swift` (presents the sheet), `CitationComposerModelTests.swift`.
Do: D-8, D-9, D-11, D-12.
Check: T-7, T-8 pass.

**STEP-9 — The form draws the line; Printed page goes**
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
| T-7 | Swift | `CitationComposerModelTests.swift` `metadataSheetSavesOnItsOwn` *(new)* | a saved Citation with listed rows; a Label typed and not saved; `requestEditMetadata()`; Page "2" set on the host; `save()` → `updateCitationMetadata` holds the draft and the update carries the cached row's `locatorJSON` and `description`, not the typed Label; `presented` nil after; the effects carry a `citation_boards` read, and FakeStore's reloaded row (`metadataWriteResults`) gives `metadataCount` "2 own · 2 inherited"; with the sheet changed, `hasUnsavedDocumentWork` is true and a leave returns to `.metadata` | AC-1.1, AC-1.2, D-9, D-11 |
| T-8 | Swift | same file `newCitationMetadataLine`, `metadataLineFailure` *(new)* | a new Citation with a seeded draft board of 4 inherited rows → `metadataCount` is "Inherits 4 values…", the button off; during its first save (create in flight) → no error, the button off; a draft read failing with `sourcemetadata.invalid` → `metadataLineError` is the new string; a loaded list without the open Citation → the same; a host change → `host.isChanged` true | AC-1.3, AC-1.5, AC-1.6, D-8, D-12 |
| T-9 | Swift | same file `menuRowReadsOwnPage` (the `locatorText` test, rewritten) | `locatorText(pageLabel: "2", locator: page 2)` → "p. 2 · image 2"; `pageLabel: ""`, page 40 → "image 40" | AC-2.6, D-13 |
| T-10 | Swift | `CatalogQueryRegistryTests.swift` `composerWarmsMetadataFields` *(new)*; `citationBoardsReloadCitationList` *(new)* | the `.citationComposer` spec lists `.metadataFieldsList`; a `citation_boards` read for a graph revalidates that graph's `.citationsByArtifact` key and no `.citationCounts` key; `.changedSourceType` and `.updatedMetadataField` each mark a hidden `.citationsByArtifact` key stale (`boardVocabularyStalesCitationLists` *(new)*) | D-5, D-8, D-17 |
| T-11 | Go | `core/database/sourcevocab/registry_test.go` `TestFieldKeysMatchSeed` *(new)* | `vocabkey.FieldPage` is a seeded field's key | D-1 |
| T-12 | Go | `api/ffi/handlers/citations_test.go` `TestUpdateCitationMetadataOnly` *(new)* | `UpdateCitation` with the row's own stored columns (from `ListCitationsByArtifact`) and a draft of Page "2" → no `citation` audit row, a `citation_boards` read and no `citations` read; the reply's board holds Page "2" | D-9, D-5 |

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

1. Add Source **Calder Gazette** of type Newspaper item with a PDF Artifact and a graph; give the Source Published in and Provider. Open the composer; **New citation**: no Printed page field; the Metadata button is off and reads "Inherits 2 values. Add its own after the first save".
2. Save the Citation with a Label. Edit metadata… opens the 600pt sheet: Published in and Provider "From Source", Page and Column empty. Type Page "2" and Column "4", Save metadata: the sheet closes, the line reads "2 own · 2 inherited", the Citation menu row reads "p. 2 · image …", the provenance sheet's citation reads "…, p. 2, col. 4…".
3. Give the graph Page "7" on its form. Save a second **New citation** on the same graph with a Label only; its sheet shows Page "7" "From Evidence graph" (AC-1.4); its citation prints "p. 7".
4. Open a Citation on an image Artifact and one on an audio Artifact: each has the Metadata line and no Printed page field (AC-1.7).
5. Promote an Observation of the first Citation to a Conclusion: the Conclusion detail's line reads "p. 2".
6. Type a Label without saving, then change a value in the sheet and Save metadata: the typed Label stays unsaved. Type in the sheet and Cancel: the discard confirm asks. Resize across 1600pt with the sheet open: it stays 600pt and keeps its text.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| `from("artifact_id", chain(inbound(…), field(…)))` does not check against `evidence_graphs` | T-4; Stop condition |
| The draft read for a new Citation races a fast Artifact switch | `draftMetadataRows` is set only when the read's Artifact is still `selectedArtifactID` |

**Stop and report if:**

- A D-5 path fails `validate` or names no graph in T-4.
- `CitationPages` cannot run on `graphcache.Graph` after D-3 (a `*sql.Tx`-only call underneath).
- `ListCitationsByArtifact` calls a board or page read per Citation.
- An `UpdateCitation` with the cached row's stored columns writes an audit row for the Citation itself (T-12).
- A moved board file needs a code change to build in its new folder (D-15 moves only).

## 12. Open questions

None.

## 13. PR

**Title:** S15-56 — The composer edits a Citation's metadata
**Body:** objective in one sentence; what shipped against US-1 and US-2; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-56-composer-citation-metadata.md`.
