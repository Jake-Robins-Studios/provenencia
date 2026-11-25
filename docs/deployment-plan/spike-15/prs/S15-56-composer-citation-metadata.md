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
**Skills to load:** [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md) (the citations-by-Artifact descriptor and its patch), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`
**Context:** working rules "One metadata board", "A board shows what its owner inherits", "The printed page is a metadata field", "Metadata saves with its owner's write", "A board adds a field in an inline row", "One window"; [`source-layer-data-model.md` § 5](../../../source-layer-data-model.md); [`catalog-caches.md` § Swift caches](../../../catalog-caches.md#swift-caches)
**Planned:** 2026-11-25 against `main` @ `620ddaa`
**Review:** [`S15-56-composer-citation-metadata.review.md`](S15-56-composer-citation-metadata.review.md)

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
| AC-1.3 | A new Citation, no Save yet; an Observation added first (the composer creates the Citation through `ensureCitationID`) with Page "3" typed on the board | The create carries Page "3"; the board is then saved (Save not enabled by the board) |
| AC-1.4 | A Citation whose graph holds Page "2" and which holds none | Its Page row shows "2" with "From Evidence graph"; its citation prints "p. 2" |
| AC-1.5 | An unsaved board change (a value typed and confirmed), then the Citation menu's pick of another Citation | The composer's discard confirm shows, as for an unsaved Label; Discard drops the change |
| AC-1.6 | **New citation** on an Artifact whose graph was deleted after the composer opened | The board's place shows `L10n.CitationComposer.metadataBoardUnavailable`; Label and the transcription save as today |
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
| The Citation's board in both form arrangements (CB-1, CB-W1, CB-W2) | STEP-8 |
| A new Citation's draft board; a saved Citation's board from the cached list (CB-2, CB-3) | STEP-4, STEP-7 |
| Values save in the Citation's create and update; one Save; leave confirm (CB-4) | STEP-5, STEP-7 |
| The draft read's failure copy (CB-5; S15-55 review UX-1) | STEP-7, STEP-9 |
| Menu row reads the own Page (CB-6) | STEP-4, STEP-8 |
| Tab order, VoiceOver (CB-7, CB-8) | STEP-8 |
| `graphfill` reads the Citation's own `page` (and so the Conclusion detail, `CitationLineDisplay` and the likeness and depiction viewers) | STEP-1, STEP-2 |
| Value writes at every level refresh the citations-by-Artifact read | STEP-3, STEP-6 |
| Printed page input, its strings and capability removed | STEP-8, STEP-9 |
| `sourceTypes.suggested.meaning` and § 5.2's board list name the Citation; the inherited-row translator comments name every level (S15-54 ship UX-1, S15-55 review UX-2) | STEP-9, STEP-10 |

| Out | Home |
| --- | --- |
| Needed and used flags on the composer's board | S15-39 |
| The Unknown and Supplied control | S15-41 |
| `{citation.page}`, `Board.Page`, `page_requirement` | S15-58 |
| The locator's `page_label` keys and `CitationLocatorDraft.pageLabel` | S15-59 |
| Moving existing locator `page_label`s into `page` values | not planned (user, 2026-11-25: the product owner updates dogfood projects by hand) |
| A board that refreshes while its Citation stays open in the composer | not planned (rule "One window": no other view edits while the composer shows) |
| A field's unknown-text edit refreshing loaded graphs | S15-46 |
| A metadata draft on `CreateCitedBridge` | not planned (S15-54: a bridge's Citation takes values through `UpdateCitation`) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Field keys | `core/vocabkey/vocabkey.go` | No metadata-field key; S15-60 D-4 left `page` to its first reader |
| Key resolution | `core/database/metadatafields/metadatafields.go` `ResolveKeysTx` (:297), `ListByIDsTx` (:250), `MapByIDsTx` (:272) | Take `*sql.Tx`; `graphfill` reads through `graphcache.Graph`, a `database.Querier` |
| Values read | `core/database/sourcemetadata/sourcemetadata.go` `ListByOwnersTx` (:694) → `readByOwners(q database.Querier, …)` (:713); `annotation.go` `CitationValue` (:49); `core/citationformat/render.go` `Display` (:219) | The read and the display text exist; no reader resolves a field by key |
| Graph page | `core/database/graphfill/load.go` `loadGraphObservations` (:169), `citationWords` (:162) | Sets `EvidenceObservation.PageLabel` from `locator.Page(...).Label` (:218–224), dropping the mark |
| Carriers | `graphcache.EvidenceObservation.PageLabel`; `conclusiondetails.Outcome.PageLabel` (:95, copied :576); `api/ffi/handlers/conclusion_detail.go` `reconcilerOutcomeProto` (:170) → `ReconcilerOutcomeDetail.page_label = 24` | Unchanged by this PR; they carry whatever `graphfill` sets |
| Reads | `core/database/effects/registry.go` `"citation_metadata"` (:378), `"source_metadata"` (:364), `metadataEffects` (:532); `reads_test.go` `TestReadsDeclare` | No metadata table reports `citations`; the composer's cached Citation boards would never refresh |
| List RPC | `api/ffi/handlers/citations.go` `ListCitationsByArtifact` (:213); `engine.proto` `ListedCitation` (:2718) | No board, no page |
| Citation writes | `citations.go` `CreateCitationWithObservations` (:15), `UpdateCitation` (:159); proto `metadata` 12/4 and 9/3 | Take a draft and answer the board since S15-54; Swift sends none |
| Swift store | `macos/App/Platform/GenealogyStore.swift` `createCitationWithObservations` (:2129), `updateCitation` (:2149), `listCitationsByArtifact` (:2185), `CatalogListedCitation` (:425); `GoStore.swift` (:2345); `FakeStore.swift` (and its own caller :2750); `macos/ProvenenciaTests/OnboardingModelTests.swift` stub | No metadata argument or rows |
| Cache | `Features/Workspace/Session/CatalogQueryRegistry.swift` `.citationsByArtifact` (:367); `CatalogLastUpdated.swift` `CatalogQueryPatch.metadataBoard()` (:242) | The patch writes `.sourceWorkspace` keys only |
| Composer writes | `Features/CitationComposer/CitationComposerContext.swift` `createCitationIfNeeded` (:121), `applyWrite` (:81); `CitationFieldsDraft.swift` `saveCitation` | No metadata |
| Composer state | `CitationComposerModel.swift` `hasUnsavedDocumentWork` (:350), `:392`, `:541`, `canSaveCitation` (:744), `pageLabel` (:309), `loadCitation`, `openBlankCitation`, `resetComposerIdentity`, `selectArtifactAndLoad`, `fetchOpenCitation` | Dirty is `fields.isDirty` alone |
| Composer form | `CitationComposerEvidenceColumn.swift` `CitationFormFocus`, `labelAndPrintedPage`, `printedPageField`, `CitationStepMenuRow.locatorText`; `CitationComposerView.swift` `composeSplit` (:303); `Features/ArtifactViewer/ArtifactViewerKind.swift` `supportsPrintedPage` | Draws Printed page from the locator |
| Board | `Features/Sources/SourceOwnerForm.swift` `DraftMetadataBoardField`; `MetadataDraftHost.swift`; `MetadataBoardModel.swift`; `SourcePageContext.swift` `readDraftBoardForAdd`, `fields` | The form board and its host, as the Artifact sheet uses them |
| Tests | `core/database/graphfill/records_test.go` `TestGraphRecordsCarryCitationWords`, `TestLoadParsesEachCitationOnce`; `conclusiondetails_test.go` `TestForEntityCitationParts`; `api/ffi/handlers/conclusion_detail_test.go` `TestConclusionDetailProtoCarriesVoteArtifactAndMembers`; `macos/ProvenenciaTests/CitationComposerModelTests.swift`, `MetadataDraftHostTests.swift` | The three Go tests assert the locator's label |

**Precedent.** S15-34 (#819) and S15-10 (#829) put a draft board on the Artifact sheet: `ArtifactSheetModel` builds `MetadataDraftHost` from the cached rows (edit) or the draft read (add), sends `host.draft` in its one write, calls `host.markSaved()`, and applies the reply rows with `.wroteMetadataBoard`. Copy that shape; the composer's cache is the citations-by-Artifact list instead of the Source workspace.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `vocabkey.FieldPage = "page"` *(new)* in `core/vocabkey/vocabkey.go`, with a doc comment naming the seed field | Rule "The printed page is a metadata field": the key is declared once | A literal in each reader |
| D-2 | One Go reader of the printed page, `sourcemetadata.CitationPages` (Codebase fit): resolves `FieldPage` with `metadatafields.ResolveKeysTx(q, …, vocabkey.OriginProvenencia)`; an Unknown or Ambiguous key answers an empty map; reads the Citations' own rows with `readByOwners` (what `ListByOwnersTx` reads) at `LevelCitation` only; the text is `citationformat.Display(CitationValue(row, field))`, the field from `metadatafields.MapByIDsTx`. A Citation with no own value is absent | The rule: own value only, marks as a citation prints them, one lookup path; `graphfill` and the list RPC share it | A walk up the levels (the rule forbids it); Swift picking the `page` row out of the board (a second resolution) |
| D-3 | `metadatafields.ResolveKeysTx`, `ListByIDsTx` and `MapByIDsTx` take `q database.Querier` instead of `tx *sql.Tx`; names and behavior unchanged; every caller compiles as is | `graphfill` reads through `graphcache.Graph`; `*sql.Tx` and `*sql.DB` are Queriers | Querier copies beside them; renaming the `Tx` functions (churn outside this PR) |
| D-4 | `graphfill` keeps parsing the locator for `ArtifactPage` and stops reading its `Label`; after the scan it calls `CitationPages` once over the graph's Citation ids and sets each Observation's `PageLabel`. `CitationLineDisplay` and the proto are unchanged: "p. unpaginated" and "p. [14]" read as the seeded formats print them | One batched read per graph load; S15-54 D-7 already invalidates loaded graphs on `citation_metadata` | A per-Citation read; a new proto mark field (the text already carries it) |
| D-5 | Each metadata values table reports `effects.ReadCitations` for the graphs whose Citations' boards it moves: `citation_metadata` `up("citation_id", "graph_id")`; `evidence_graph_metadata` `field("graph_id")`; `artifact_metadata` `from("artifact_id", chain(inbound("citations", "artifact_id"), field("graph_id")))`; `source_metadata` adds `graphsOfSource(field("source_id"))` beside its `ReadInheritedValues`. Declared as `Reads` extras in `registry`, beside the entries `metadataEffects` fills | The composer's board rides the citations-by-Artifact read, whose key follows `citations` by graph; an own or inherited value move must reach it (S15-54 Out, S15-64 Next adds) | A new `Read` kind for Citation boards (a second key on the same list); `inherited_values` (keyed by Source; the list key holds no Source) |
| D-6 | `ListedCitation` gains `repeated MetadataWorkspaceEntry metadata = 4` (the Citation's board) and `string page_text = 5` (`CitationPages`' text, "" none). `ListCitationsByArtifact` makes one `sourcemetadata.ListWorkspaces` call over the listed Citations and one `CitationPages` call over `c.DB()` | Rule "One window": the composer opens a Citation from the cached list with no fresh read; one batched read per Artifact (Scale) | A `GetMetadataBoard` per Citation opened |
| D-7 | Swift `createCitationWithObservations` gains `metadata: CatalogMetadataDraft?` and returns `(CatalogCitation, [CatalogObservation], [CatalogMetadataEntry], CatalogWriteEffects)`; `updateCitation` gains `metadata:` and returns `(CatalogCitation, [CatalogMetadataEntry], CatalogWriteEffects)`; rows map with `Self.mapMetadataEntry` as `updateArtifact` maps them. `FakeStore`'s own caller and the test stub pass `nil` | S15-54 D-12: the store gains the draft with its first caller | A separate metadata write after the Citation's (rule "Metadata saves with its owner's write") |
| D-8 | `CatalogListedCitation` gains `metadata: [CatalogMetadataEntry] = []` and `pageText: String = ""` | The list carries what D-6 sends | — |
| D-9 | The open Citation's board lives on `CitationComposerContext` as `metadataHost: MetadataDraftHost?` and `metadataBoard: MetadataBoardModel?` *(new)*, built each time a Citation opens: a saved Citation from its cached `CatalogListedCitation.metadata` (`loadCitation`); a new one (`openBlankCitation`, `resetComposerIdentity`, `selectArtifactAndLoad`) from `store.getDraftMetadataBoard(projectDir:parents: [graph, Artifact], level: .citation)`, nil while it reads; a Citation read through `getCitation` because it is not in the cached list: nil. The field list is the `.metadataFieldsList` query, as `SourcePageContext.fields` reads it. A cache reload while the Citation stays open does not rebuild it | The context is what the four `ensureCitationID` callers share, so every create carries the draft; "One window" bounds staleness to the next open | The host on `CitationFieldsDraft` (`ensureCitationID` takes only its values) |
| D-10 | Writes: `createCitationIfNeeded` sends `metadataHost?.draft`; `saveCitation` sends it on update. On success `metadataHost?.markSaved()`, then, when a draft was sent, `session.apply(effects, .wroteMetadataBoard(sourceId: sourceID, owner: MetadataOwner(level: .citation, id:), entries: rows))`, else `applyWrite(effects)` as today | The Artifact sheet's shape (Precedent) | A reload of the list for the rows |
| D-11 | `CatalogQueryPatch.metadataBoard()` also patches `.citationsByArtifact` keys: for an owner at `.citation`, the cached listed Citation with that id gets `metadata = entries`; any other key is `.unchanged`. The `.citationsByArtifact` descriptor lists `patches: [.metadataBoard()]` | One patch path for every owner's board (map scope entry); the list's `citations` reload still follows | A composer-only patch |
| D-12 | Board-dependent: the board sits in a `DraftMetadataBoardField` labelled `L10n.CitationComposer.metadataLabel` under Label in both arrangements; in the side form, before or after the transcription as the board decides (CB-W1). Filled from the board before `Planned` | Brief CB-1, CB-W1 | A composer-only board view |
| D-13 | `CitationComposerModel.citationDirty` *(new)* is `fields.isDirty || (context.metadataHost?.isChanged ?? false)`; `hasUnsavedDocumentWork`, `canSaveCitation` and the reads at `:392` and `:541` use it. Discard rebuilds the host as D-9 opens it | CB-4: one Save, one leave confirm | A board Save button |
| D-14 | A failed draft read sets `metadataBoardError` *(new, on the context)*: `L10n.CitationComposer.metadataBoardUnavailable` when the error's code is `sourcemetadata.invalid`, else `L10n.Errors.message(for:)`. The board's place shows it with `PVErrorText`; the host stays nil, so the create sends no metadata | CB-5; S15-55 D-6 answers `sourcemetadata.invalid` for a deleted parent | Showing the engine's save-worded sentence |
| D-15 | `CitationStepMenuRow.locatorText(pageText:locator:)` takes the listed Citation's `pageText` for "p. 14" and the locator for "image 37" and "region" | User, 2026-11-25: the row shows the Citation's own Page value | Dropping the printed page from the row |
| D-16 | `CitationFormFocus` keeps `.label` and `.transcription`; its `order(_:)` takes no printed-page argument | CB-7: the Tab list names text fields only, as the Artifact sheet's | Adding the board to the Tab list |
| D-17 | No migration of locator `page_label`s (Out) | User, 2026-11-25 | — |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `vocabkey.FieldPage` | const | `vocabkey.PropertyToponym` | Same shape, a new key family |
| `sourcemetadata.CitationPages(q database.Querier, citationIDs [][]byte) (map[string]string, error)` | func | `citationrender.fillValues` (reads all levels for a render) | The rule bans the walk; this is the own-value read both readers need |
| `ListedCitation.metadata`, `.page_text` | proto fields | `CreateCitationWithObservationsResponse.metadata` | Extends the list message |
| `CatalogListedCitation.metadata`, `.pageText` | Swift fields | — | Mirror D-6 |
| `CitationComposerContext.metadataHost`, `.metadataBoard`, `.metadataBoardError` | properties | `ArtifactSheetModel.host`, `.board` | The same types, held where the composer's writes are |
| `CitationComposerModel.citationDirty` | property | `fields.isDirty` | Adds the board |
| `L10n.CitationComposer.metadataLabel` ("Citation metadata"), `.metadataBoardUnavailable` | keys | `L10n.Sources.artifactCopyDetailsLabel` | Composer namespace, as its other copy |

**Builds on.** `MetadataDraftHost`, `MetadataBoardModel`, `DraftMetadataBoardField` (rule "One metadata board"); the effects registry's `Reads`; `.wroteMetadataBoard` and `CatalogQueryPatch.metadataBoard()`.
**Deletes.** `ArtifactLocatorCapabilities.supportsPrintedPage` and its four values; `CitationComposerModel.pageLabel`; `CitationFormFocus.printedPage` and `order`'s `printedPageOffered:`; `labelAndPrintedPage`, `printedPageField`; `L10n.CitationComposer.printedPageLabel`, `printedPagePrompt`, `printedPageHelp` and their catalog keys; `citationWords.pageLabel` in `graphfill`.
**Next adds.** S15-39 and S15-41 draw flags and marks on this board with no composer change. S15-58 deletes `{citation.page}`; S15-59 deletes `CitationLocatorDraft.pageLabel`, now read by nothing but the locator codec.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A Citation board in the composer | `MetadataBoardView` via `DraftMetadataBoardField` | Rebuilt per opened Citation (D-9); a deleted parent shows D-14; nil host shows no board |
| `.wroteMetadataBoard` with a `.citation` owner | `CatalogQueryPatch.metadataBoard()`, `CatalogLastUpdated` (:244) | A Source-workspace key does not hold a Citation owner: `setMetadataRows` on an unknown owner leaves it unchanged (T-9) |
| Metadata values tables reporting `citations` | `.citationsByArtifact` refresh | Hidden keys mark stale (descriptor `whenHidden: .markStale`) |

### Scale

At the map's Scale (a Source of 600 Citations, up to 8 values each, read one Artifact at a time; an Artifact of up to 60 Citations):

- `ListCitationsByArtifact`: one `ListWorkspaces` over up to 60 owners (S15-55's one batched read) and one `CitationPages` read (one key lookup, one `readByOwners` over 60 owners). T-6 measures 60 Citations of 8 values each under 100 ms.
- `graphfill`: one `CitationPages` over a graph's Citations (up to 10).
- A Source value write names every graph of the Source for `citations`: a revalidation per cached key, no read for hidden keys.

### Edges

- **Assumptions.** `ResolveKeysTx` prefers the seed's field when a researcher made another `page`; T-1 pins it.
- **Neighbors.** Own Page vs inherited Page (AC-2.4); marked unknown vs supplied (AC-2.2, AC-2.3); a project without the field (AC-2.5).
- **Removed inputs.** A deleted `page` field releases its values (S15-54's delete path), which reports `citations` and the graphs (D-5, S15-54 D-7): the page disappears from both readers (T-3).
- **Real data.** None — no table-driven rule changes.
- **Untrusted size.** A value is capped by `citationformat.Display` (`MaxDisplayBytes`).

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/vocabkey` | `FieldPage` (D-1) |
| `core/database/metadatafields` | D-3 |
| `core/database/sourcemetadata` | `CitationPages` (D-2), in `annotation.go` beside `CitationValue` |
| `core/database/graphfill` | D-4 |
| `core/database/effects` | D-5 |

### FFI

`api/proto/engine.proto`: `ListedCitation` fields 4 and 5 (D-6). Handler `api/ffi/handlers/citations.go` `ListCitationsByArtifact`, board entries through `metadataEntriesProto` as `CreateCitationWithObservations` maps its board. Regenerate with `./scripts/generate-proto.sh`.

### macOS

From the brief's inventory (completed from the board, D-12):

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Citation form | snowflake | `CitationComposerEvidenceColumn.swift` `sideForm`, `panelForm` | Label, then the board, in place of `labelAndPrintedPage` |
| Board | `DraftMetadataBoardField` → `MetadataBoardView(.form)` | `Features/Sources/SourceOwnerForm.swift` | Prefix `citationComposer.metadata`; shown when `context.metadataBoard` is not nil |
| Read failure | `PVErrorText` | as `citationLoadErrorLine` | D-14 |
| Menu row | `CitationStepMenuRow` | same file | D-15 |

States: reading a new Citation's board → no board (the read is local); failure → D-14; a board of 30 rows scrolls with the form. Accessibility: CB-8, from the shared rows.

### Strings

L10n keys *(new)*: `L10n.CitationComposer.metadataLabel` = "Citation metadata"; `L10n.CitationComposer.metadataBoardUnavailable` = "The Citation's metadata can't be shown: its Evidence graph or Artifact was deleted. Close the composer and open it again from the Source." Removed: `citationComposer.printedPageLabel`, `.printedPagePrompt`, `.printedPageHelp`. Changed: `sourceTypes.suggested.meaning` → "Offered on every Source, Artifact, Evidence graph and Citation of this type"; the translator comments of `sources.page.metadataInheritedFrom`, `metadataInheritedAccessibility` and `metadataOverrides` name the level as "(Source, Artifact or Evidence graph)".

## 7. Steps

**STEP-1 — The page key and its one reader**
Files: `core/vocabkey/vocabkey.go`, `core/database/metadatafields/metadatafields.go`, `core/database/sourcemetadata/annotation.go`.
Do: D-1, D-3, D-2.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/metadatafields/... ./core/database/sourcemetadata/...` passes with T-1.

**STEP-2 — The graph reads the Citation's own page**
Files: `core/database/graphfill/load.go`, `records_test.go`, `conclusiondetails_test.go`, `api/ffi/handlers/conclusion_detail_test.go`.
Do: D-4; rewrite the three tests' page assertions to seed Page values.
Check: `go test -tags fts5 ./core/database/graphfill/... ./core/database/conclusiondetails/... ./api/ffi/handlers/...` passes with T-2, T-3.

**STEP-3 — Value writes refresh the Citation lists**
Files: `core/database/effects/registry.go`, `reads_test.go`, `reads_resolve_test.go`.
Do: D-5.
Check: `go test -tags fts5 ./core/database/effects/...` passes with T-4.

**STEP-4 — The list carries each Citation's board and page**
Files: `api/proto/engine.proto`, `api/ffi/handlers/citations.go`, `citations_test.go`. Skill: `add-ffi-handler`.
Do: D-6; `./scripts/generate-proto.sh`.
Check: `go test -tags fts5 ./api/ffi/handlers/...` passes with T-5, T-6.

**STEP-5 — Swift store**
Files: `Platform/GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift`, `macos/ProvenenciaTests/OnboardingModelTests.swift`.
Do: D-7, D-8; FakeStore stores and returns Citation boards and `pageText` as it does Artifact boards.
Check: `xcodebuild test` builds; existing composer tests pass.

**STEP-6 — The cache patch**
Files: `Features/Workspace/Session/CatalogLastUpdated.swift`, `CatalogQueryRegistry.swift`. Skill: `add-workspace-place`.
Do: D-11.
Check: T-9 passes.

**STEP-7 — The composer holds and saves the board**
Files: `CitationComposerContext.swift`, `CitationFieldsDraft.swift`, `CitationComposerModel.swift`.
Do: D-9, D-10, D-13, D-14.
Check: T-7, T-8 pass.

**STEP-8 — The form draws it; Printed page goes**
Files: `CitationComposerEvidenceColumn.swift`, `CitationComposerView.swift`, `Features/ArtifactViewer/ArtifactViewerKind.swift`. Skill: `add-ui-component`.
Do: D-12, D-15, D-16; the Deletes.
Check: the app builds; T-10 passes; the manual check's steps 1–3.

**STEP-9 — Strings**
Files: `Platform/L10n.swift`, `Resources/Localizable.xcstrings`. Skill: `add-localized-string`.
Do: § 6 Strings.
Check: no `printedPage` hit under `macos/App` (`rg printedPage macos/App`).

**STEP-10 — Docs**
Files: `completed.md`, `deployment-plan.md` (map row), this plan, `design/S15-D29-citation-composer-metadata.md` → `design/archive/`, `design/README.md`, `docs/source-layer-data-model.md` § 5.2 (the boards list names the composer's Citation board).
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py` passes; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `sourcemetadata/annotation_test.go` `TestCitationPages` *(new)*, table | own "14" → "14"; unknown → "unpaginated"; supplied "14" → "[14]"; graph holds "2", Citation none → absent; no `page` field → empty; a researcher field also keyed `page` holding "99" beside the seed's "14" → "14" | AC-2.1, AC-2.2, AC-2.3, AC-2.4, AC-2.5, D-2 |
| T-2 | Go | `core/database/graphfill/records_test.go` `TestGraphRecordsCarryCitationWords` | Page "14" on the Citation, locator `page_label` "9" → `PageLabel` "14", `ArtifactPage` 37; none on the Citation → "" | AC-2.1, AC-2.4, D-4 |
| T-3 | Go | `api/ffi/handlers/conclusion_detail_test.go` `TestConclusionDetailProtoCarriesVoteArtifactAndMembers` | Page "23" → `GetPageLabel()` "23"; after the `page` field is deleted → "" | AC-2.1, Edges |
| T-4 | Go | `effects/reads_test.go` `TestReadsDeclare`; `reads_resolve_test.go` `TestMetadataValuesNameCitationGraphs` *(new)* | `ReadCitations` lists the four values tables; a value set on a Citation, its graph, its Artifact and its Source each names the Citation's graph | D-5 |
| T-5 | Go | `handlers/citations_test.go` `TestListCitationsByArtifactBoards` *(new)* | Two Citations, one with Page "2" → its `metadata` holds the saved Page row, `page_text` "2"; the other's Page entry carries `inherited` from the graph and `page_text` "" | AC-2.6, D-6 |
| T-6 | Go | same file `TestListCitationsByArtifactScale` *(new)* | 60 Citations, 8 values each → one call under 100 ms | D-6, Scale |
| T-7 | Swift | `CitationComposerModelTests.swift` `newCitationSavesBoard` *(new)* | New citation, Page "2" set on the host, Save → FakeStore's create received the draft; host unchanged after; `citationDirty` false. Same through `ensuredCitationID` | AC-1.1, AC-1.3, D-10 |
| T-8 | Swift | same file `boardChangeIsUnsaved`, `draftReadFailure` *(new)* | A host change → `canSaveCitation`, `hasUnsavedDocumentWork` true; update sends only the draft; a draft read failing `sourcemetadata.invalid` → `metadataBoardError` is the new string, host nil | AC-1.2, AC-1.5, AC-1.6, D-13, D-14 |
| T-9 | Swift | `CatalogQueryRegistryTests.swift` `citationBoardPatchesItsList` *(new)* | `.wroteMetadataBoard` for a `.citation` owner → the cached list's Citation has the rows; a Source workspace key unchanged | D-11 |
| T-10 | Swift | `CitationComposerModelTests.swift` `menuRowReadsOwnPage` *(new)* | `locatorText(pageText: "2", locator: page 2)` → "p. 2 · image 2"; `pageText: ""`, page 40 → "image 40" | AC-2.6, D-15 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `MetadataDraftHostParityTests`, `TestDraftBoardScenarios`, the composer's focus tests (`CitationFormFocus.order`).

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
- [ ] Domain doc updated if a rule in docs/*.md changed: source-layer-data-model.md § 5.2 (the boards list)
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
| Building the host in `loadCitation` races a fast Citation switch | Built inside the same task after `fetchOpenCitation`, which checks `Task.isCancelled` |

**Stop and report if:**

- A D-5 path fails `validate` or names no graph in T-4.
- `CitationPages` cannot run on `graphcache.Graph` after D-3 (a `*sql.Tx`-only call underneath).
- T-6 exceeds 100 ms.
- The agreed board places the board away from Label, or adds a control the inventory does not list.
- `ensureCitationID`'s callers cannot reach `context.metadataHost` without changing their signatures.

## 12. Open questions

- The board's placement in the side form, before or after the transcription (D-12). Recommended: after Label, before the transcription, as the brief draws first. Answered by the board.

## 13. PR

**Title:** S15-56 — The composer edits a Citation's metadata
**Body:** objective in one sentence; what shipped against US-1 and US-2; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-56-composer-citation-metadata.md`.
