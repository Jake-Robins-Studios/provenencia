# S15-54 — Citations hold metadata

**Status:** Blocked — on board S15-D30
**Spike / slice:** Spike 15 · Slice 11 — Citation metadata
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D30](../design/S15-D30-source-type-page-citation-level.md), board not drawn yet
**Board:** — (to be drawn on the Source Type Page board, frames "S15-D30 · …"; the agreed board's link and its decisions are copied here and into D-15 when the user agrees it)
**Depends on:** S15-24 (landed [#935](https://github.com/Jake-Robins-Studios/provenencia/pull/935)), S15-61 (landed [#943](https://github.com/Jake-Robins-Studios/provenencia/pull/943)), S15-D30
**Blocks:** S15-55
**Branch:** `s15-54-citations-hold-metadata`
**Version bump:** minor — a catalog step that old apps refuse, new RPC fields, and a fourth suggestion list a researcher can use ([`docs/versioning.md`](../../../versioning.md)): 0.33.1 → 0.34.0
**Skills to load:** [`add-catalog-migration`](../../../../.agents/skills/add-catalog-migration/SKILL.md), [`add-catalog-model`](../../../../.agents/skills/add-catalog-model/SKILL.md), [`add-audit-scope`](../../../../.agents/skills/add-audit-scope/SKILL.md), [`add-catalog-delete`](../../../../.agents/skills/add-catalog-delete/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests), `.cursor/rules/catalog-migrations.mdc`, `.cursor/rules/catalog-model.mdc`, `.cursor/rules/catalog-audit.mdc`, `.cursor/rules/ffi-handlers.mdc`, `.cursor/rules/macos-l10n.mdc`, `.cursor/rules/swift-tests.mdc`, `.cursor/rules/versioning.mdc`
**Context:** map scope entry S15-54 ([`../deployment-plan.md`](../deployment-plan.md#s15-54--citations-hold-metadata)); working rules "Metadata lives at four levels with one vocabulary", "One level type", "Suggestions have a level", "A Citation holds metadata", "Metadata saves with its owner's write", "The printed page is a metadata field" (its effects sentence); S15-61's **Next adds** ([`S15-61-metadata-levels-list.md`](S15-61-metadata-levels-list.md)); [`docs/source-layer-data-model.md`](../../../source-layer-data-model.md) §§ 5.4, 5.5; [`docs/citation-formats.md`](../../../citation-formats.md); [`docs/catalog-deletes.md`](../../../catalog-deletes.md)
**Planned:** 2026-11-22 against `main` @ `8436190` (compare with `origin/main` after `git fetch origin main`)
**Review:** [`S15-54-citations-hold-metadata.review.md`](S15-54-citations-hold-metadata.review.md) — not reviewed yet

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

A Citation is the spot cited in a record: a page, a line, an entry. Today only the Source, its Artifacts and its Evidence graphs hold metadata, so a value that belongs to one spot (the line on a census page, the column of a newspaper) has to sit on a whole graph or Artifact. After this PR the Citation is the fourth metadata level (user, 2026-11-22): it holds values and a layout from the same field vocabulary, a Source type suggests fields for its Citations in a fourth list on its page, Copy type copies that list, the format editor completes `{citation.meta.<key>}`, and a citation renders the Citation's own values. The Citation writes carry its values, so S15-56's composer can save them with the Citation.

**Why now.** S15-61 made the metadata levels one declared list, so the engine half of this PR is one list entry, one migration and one render owner. Slice 11's later PRs (S15-55 chains, S15-60 seeded page fields, S15-56 the composer's board) all read Citation values.

**What stays.** No board shows a Citation's values yet (S15-56). The three existing levels behave as today. The seed suggests nothing at the Citation level (S15-60). `{citation.page}` stays a built-in (S15-58). The locator is unchanged (S15-59). Copy Source never copies Citations, and a move carries an Artifact's Citations with it, so their values follow with no change to either.

## 2. User stories

**US-1.** As a researcher, on a Source type's page, I list the fields each Citation of that type carries, so that every Citation of a census can hold its line and column.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Census's page | Suggested fields shows four lists: On the Source, On each Artifact, On each Evidence graph, On each Citation (CL-1), in that order |
| AC-1.2 | Line picked in the Citation list's picker, Return twice | Line is last in the Citation list; the other three lists are unchanged; the toast reads "Line is now suggested on each Citation of Census Sources." (CL-2, CL-3) |
| AC-1.3 | Line in the Evidence graph list | The Citation list's picker still offers Line (CL-2) |
| AC-1.4 | A plugin type | The Citation list is read only (CL-2) |
| AC-1.5 | Line removed from the Citation list while 6 Sources, Artifacts, graphs, Citations and Source types use it | The toast ends "…and the 6 Sources, Artifacts, graphs, Citations and Source types that use it are unchanged." (CL-3) |
| AC-1.6 | The engine, `AppendSuggestion(c, census, line, vocabkey.LevelCitation)` | One row at level `citation`; `ListTypeSuggestions` at `citation` returns it; the type's `SuggestedFields` (`sourcetypes.Type`) counts it |

**US-2.** As a researcher, I copy a type with its Citation list.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Copy type on Census (Citation list Page, Column, Line), every tick on | The sheet shows a seventh tick "Suggested fields on each Citation", hint "3 fields"; the copy's Citation list is Page, Column, Line in that order (CL-4) |
| AC-2.2 | Copy type on Letter (no Citation fields) | The Citation tick is unticked, disabled, "None on this type" (CL-4) |
| AC-2.3 | The engine, `CopyType` with `Levels: [citation]` | Only the Citation rows are copied, with their `sort_order` |

**US-3.** As a researcher editing a format, I complete a Citation's field and see it render.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `ListCitationPlaceholders` for the full form | After the Citation built-ins (`citation.page`, `citation.image`, `citation.label`), one row per project field at `citation` with placeholder `{citation.meta.<key>}`, in `metadatafields.List` order; the source list form has no Citation row (CL-5) |
| AC-3.2 | Parse `{citation.meta.line_number}` in the full form | No diagnostic |
| AC-3.3 | Parse `{citation.meta.x}` in the list form | `not_in_list_form` over bytes 1–16 (CL-6) |
| AC-3.4 | Parse `{meta.page}` | `unprefixed_meta`; the app shows "Name a level before meta: source, artifact, graph or citation" (CL-6) |
| AC-3.5 | A full note `{citation.meta.line_number}` and a Citation holding Line "14"; `Render` of that Citation | Plain text "14" |
| AC-3.6 | The same Citation's Line marked unknown, the field's unknown text "n.l." | Renders "n.l."; marked supplied "14" renders "[14]" |

**US-4.** As the engine, a Citation holds metadata exactly as the other three levels do.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | `SetMetadata` on owner `{citation, <id>}` | Writes `citation_metadata`; the reply's board lists the value; `effects.source_scopes` holds the Citation's Artifact's Source; `effects.evidence_graphs` holds the Citation's graph |
| AC-4.2 | `ClearMetadata`, `DismissMetadataSuggestion`, `ReorderMetadata`, `GetMetadataBoard` on a Citation owner | Each works as on a graph owner; a Citation's board lists its type's `citation` suggestions |
| AC-4.3 | `CreateCitationWithObservations` with `metadata` {Line "14"} | The Citation, its Observations and its value in one revision; the reply's `metadata` is the Citation's board after the write, Line "14" in it |
| AC-4.4 | `CreateCitationWithObservations` without `metadata` | No metadata row; the reply's `metadata` lists the type's Citation suggestions, empty |
| AC-4.5 | `UpdateCitation` with `metadata` {Line "15"} over a stored Line "14" and Column "2" | Line "15", Column gone (the stored values become the draft's); one revision; the reply's `metadata` is the board |
| AC-4.6 | `UpdateCitation` without `metadata` | Stored values unchanged; the reply's `metadata` is the stored board |
| AC-4.7 | `citations.Delete` of a Citation holding two values and a layout row | The values and the layout row are released, audited, before the Citation's own delete change; each released change scopes the Source |
| AC-4.8 | `evidencegraphs.Delete` of a graph whose two Citations each hold a value | Both Citations' values released, audited, through `releaseCitation` |
| AC-4.9 | A field held only by a Citation; delete the field | Refused, `metadatafields.in_use`; the impact's group is `citation_metadata.field_id`, kind `citation`, total 1; the Metadata page's notice reads "1 citation records a value for this field" (CL-7) |
| AC-4.10 | `deleteimpact.UsedBy(KindMetadataField, line)` with 2 Sources and 3 Citations holding Line | 5 |
| AC-4.11 | A move (`sourcemove`) of an Artifact whose Citation holds Line | The value stays on the Citation; the move's revision scopes both Sources |
| AC-4.12 | An owner `{citation, <graph id>}` (an id that is no Citation) | `sourcemetadata.invalid`, nothing written |

## 3. Scope

| In | Covered by |
| --- | --- |
| Migration `000069`: `citation_metadata`, `citation_metadata_layout`, the suggestion level `CHECK` taking `citation` | STEP-1, AC-1.6 |
| `catalogmodel`: the two tables, their four FKs, the `MetadataTables` entry | STEP-1, AC-4.7 – AC-4.10 |
| `vocabkey.MetadataLevels()` and Swift `Level.metadataLevels` gain the Citation | STEP-1, STEP-7, AC-1.1, AC-2.3 |
| The `meta_not_at_level` diagnostic goes; `unprefixed_meta`'s copy names four levels | STEP-2, STEP-8, AC-3.2 – AC-3.4 |
| The effects registry's `citation_metadata` extra: `EvidenceGraph` | STEP-3, AC-4.1 |
| `citationrender.fillValues` reads the Citation's values | STEP-4, AC-3.5, AC-3.6 |
| `CreateCitationWithObservations` and `UpdateCitation` take a `MetadataDraft` and reply with the board | STEP-5, AC-4.3 – AC-4.6 |
| Board RPCs and deletes on a Citation owner (tests; no new code beyond the list entry) | STEP-6, AC-4.1, AC-4.2, AC-4.7 – AC-4.12 |
| Swift: the Citation list's copy (CL-1 – CL-3), Copy type's tick (CL-4), completion rows (CL-5), the toast copy naming Citations, the delete notice's heading (CL-7), CL-W1 | STEP-7, STEP-8, AC-1.1 – AC-1.5, AC-2.1, AC-2.2, AC-4.9 |
| Docs: `source-layer-data-model.md` §§ 5.4, 5.5, the moving-Citations line; `citation-formats.md`; `metadatafields` doc comments | STEP-9 |

| Out | Home |
| --- | --- |
| A board meeting a chain at the Citation's graph, Artifact and Source; `GetDraftMetadataBoard` at the Citation level; requirements at the Citation level | S15-55 |
| The composer's Citation board; the Swift store's `metadata` parameter on `createCitationWithObservations` and `updateCitation` and decoding the reply's rows; `graphfill` and `conclusiondetails` reading the Citation's page | S15-56 |
| Seeded Citation suggestions and the page chain | S15-60 |
| `{citation.page}`, `Board.Page`, the locator's page keys | S15-58, S15-59 |
| A `metadata` draft on `CreateCitedBridge` | not planned (D-9: the composer creates its Citation through `CreateCitationWithObservations` first) |
| A search document from Citation values | not planned (rule "A Citation holds metadata") |
| Moving a Citation to another Artifact | not planned (refused, rule "A Citation holds metadata") |
| Removing `Level.HoldsMetadata` / `holdsMetadata` now that every level holds metadata | not planned (D-4: the working rule "One level type" keeps `MetadataLevels` as the set metadata code uses) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Level list | `core/vocabkey/vocabkey.go` `MetadataLevels`, `HoldsMetadata`, the `Level` doc comment | `MetadataLevels` returns Source, Artifact, Graph. The doc comment says "the Citation only built-ins" |
| Level list test | `core/vocabkey/vocabkey_test.go` `TestLevels` | Pins `MetadataLevels()` to three |
| Metadata list | `core/database/catalogmodel/metadata.go` `MetadataTables` | Three entries. S15-61's **Next adds** names the Citation entry verbatim |
| Catalog model | `core/database/catalogmodel/model.go` `Tables` (lines 107–110), `FKs` (lines 153–160) | The graph's two tables and four FKs; none for the Citation |
| Suggestion table | `core/database/migrations/000064.sql` | `source_type_metadata_fields.level` `CHECK (level IN ('source', 'artifact', 'graph'))`, PK `(source_type_id, field_id, level)`, index `source_type_metadata_fields_field_id_idx` |
| Graph tables | `core/database/migrations/000065.sql`, `000067.sql` | The shape the Citation's pair copies, with the mark columns 000067 added |
| Citations | `core/database/migrations/000059.sql` | `citations(id, ref, artifact_id NO ACTION, graph_id ON DELETE CASCADE, …)` |
| Last migration | `core/database/migrations/000068.sql` | The next step is `000069.sql` |
| Stores | `core/database/sourcemetadata/owner.go` `stores = buildStores(catalogmodel.MetadataTables)`, `storeFor` | A Citation owner is `ErrInvalid` (no store). With the entry, `newStore` derives the Citation's type read through `citations → artifacts → sources` (pinned by `TestSourcePathIn`'s `citation` case) |
| Owner tests | `core/database/sourcemetadata/sourcemetadata_test.go` `TestOwnerLevels` (owner `"citation"` expects `ErrInvalid`), `TestOwnerTables`, `newLevelOwner` | Artifact and graph only |
| Draft board | `core/database/sourcemetadata/sourcemetadata.go` `ListDraftWorkspace` | Refuses every level but Artifact and graph. Unchanged here (S15-55) |
| Boards | `sourcemetadata.listWorkspaces` | Generic over owners; annotates against the owner's own values and its Source's. A Citation board works with no code change |
| Parser | `core/citationformat/parse.go` `CodeMetaNotAtLevel`, `DiagnosticCodes`, the `if !level.HoldsMetadata()` branch (line 392) | `{citation.meta.x}` is `meta_not_at_level` |
| Parser tests | `core/citationformat/parse_test.go` cases "three in order" and "meta in list" | Expect `meta_not_at_level` |
| Placeholders | `core/database/citationrender/placeholders.go` `Placeholders` | Lists fields at each level that `HoldsMetadata`; Citation rows follow with no code change |
| Placeholder test | `core/database/citationrender/placeholders_test.go` `TestPlaceholders` | Pins the rows at three levels |
| Render values | `core/database/citationrender/load.go` `fillValues` | Adds Source, Artifact and graph owners; never the Citation |
| Render scale | `core/database/citationrender/scale_test.go` `TestRenderScale` | Seeds `scaleValues` for three tables; pins 9 SELECTs for 300 Citations and 11 for 1,200 |
| Effects | `core/database/effects/registry.go` `registry` (the `source_metadata` comment block), `metadataEffects` | Metadata entries come from the list; extras are partial literals. No `citation_metadata` literal |
| Effects tests | `core/database/effects/registry_completeness_test.go` `TestMetadataEffects`, `TestEvidenceGraphPathsEndAtGraphs`; `released_metadata_scope_test.go` `TestReleasedMetadataScopesThroughDeletedOwner`; `evidence_graphs_test.go` `TestEvidenceGraphsResolve` | Artifact and graph cases |
| Deletes | `core/database/deleteimpact/facets.go` `releaseCitation` → `releaseRow(KindCitation, …)` → `releaseFacets`; `metadataLevelFacets`; the graph's `ViaDeletesCitations` facet | A Citation delete and a graph delete release a Citation's facets (today `citation_notes` only); the list adds the Citation's two metadata facets with no code |
| Deletes that never reach a Citation | `core/database/deleteimpact/register.go` `fkEdge(KindArtifact, "citations.artifact_id", …)`, `fkEdge(KindSource, "artifacts.source_id", …)` | An Artifact with Citations, and a Source with Artifacts, are refused before any release |
| Delete tests | `core/database/deleteimpact/facet_order_test.go` `TestMetadataFacetOrder`; `facets_test.go` `TestImpactMetadataFieldHolders`, `TestMetadataValueAuditParity` | Three levels |
| Field delete copy | `core/database/metadatafields/metadatafields.go` `ErrInUse`, `Delete` doc comments | Name three value tables / three holders |
| Citation writes | `api/ffi/handlers/citations.go` `CreateCitationWithObservations` (inside `withStagedDepictions` → `writes.Run`), `UpdateCitation` | No metadata |
| Draft helpers | `api/ffi/handlers/metadata.go` `parseOwner`, `parseDraft`, `applyDraft`, `ownerBoardProto` | Used by the Artifact and graph writes (`artifacts.go` lines 41–70, 103–142; `evidence_graphs.go` lines 75–98, 128–150) |
| Wire | `api/proto/engine.proto` `CreateCitationWithObservationsRequest` (fields 1–11), `…Response` (1–3), `UpdateCitationRequest` (1–8), `UpdateCitationResponse` (1–2); level comments at lines 354, 755, 1183, 1202, 1209, 1223, 1230 | No `metadata`; comments name three levels |
| Handler tests | `api/ffi/handlers/metadata_test.go` `newMetadataOwners`, `TestMetadataOwners` (bad case `"citation level"`); `citations_test.go` `TestCreateCitationWithObservations`, `TestUpdateCitation` | Artifact and graph owners; Citation level refused |
| Swift level | `macos/App/Platform/Level.swift` `Level.metadataLevels` | Three cases; the doc comment says the Citation has only built-ins |
| Swift parity | `api/ffi/swift_vocabulary_test.go` "metadata levels" (line 580), "inbound vias" (line 642), diagnostic codes | Fails until Swift matches Go |
| Swift copy | `macos/App/Platform/L10n.swift` `L10n.SourceTypes.level(_:)` (`case .citation: preconditionFailure`), `removedBodyNoValues`, `removedBodyWithValues`, `fieldsColumn…` comment "at all three levels" (line 8273), `DeleteImpact.viaFormats` (line 9558), `CitationFormats.diagUnprefixedMeta`, `diagMetaNotAtLevel` | Three levels; a Citation list traps |
| Swift diagnostics | `macos/App/Platform/CitationFormatVocabulary.swift` `CitationDiagnosticCode.metaNotAtLevel`; `L10n.swift` line 13044 | Mirrors Go's codes |
| Swift page | `macos/App/Features/SourceTypes/SourceTypeSuggestionList.swift` (`ForEach(Level.metadataLevels…)`), `SourceTypeCopyDialog.swift` (line 116), `SourceTypeCopyModel.swift`, `Features/Workspace/Session/CatalogQueryKey.swift` (line 106), `SourceTypeFormatsModel.completionOptions` | Driven by `Level.metadataLevels` and the engine's placeholders; a fourth level draws a fourth list and tick with no view code |
| Swift workspace | `macos/App/Platform/GenealogyStore.swift` `SourceWorkspace.metadataRows(for:)` / `setMetadataRows` (`case .citation`) | Returns nil / false. Unchanged here (S15-56) |
| Swift tests | `macos/ProvenenciaTests/SourceTypePageModelTests.swift`, `SourceTypeCopyModelTests.swift`, `CitationFormatsCopyTests.swift`, `PVDeleteImpactTests.swift` (line 291) | Loop `Level.metadataLevels`; the diagnostic copy test loops `CitationDiagnosticCode.allCases` |
| Docs | `docs/source-layer-data-model.md` lines 291, 332, 334 (heading; anchor used at line 455), 361, 365, 366, 428; `docs/citation-formats.md` lines 43, 71, 101, 103 | Three levels; "The Citation level has only built-ins"; line 428 anticipates moving Citations between Artifacts |

**Precedent.** S15-08 ([#791](https://github.com/Jake-Robins-Studios/provenencia/pull/791), plan [`S15-08-artifacts-and-graphs-hold-metadata.md`](S15-08-artifacts-and-graphs-hold-metadata.md)) added the Artifact and graph levels: copy its migration shape (`000065.sql` plus `000067.sql`'s mark columns, folded into the `CREATE TABLE`), its `catalogmodel` rows, and its draft-on-the-owner's-write handlers (`CreateEvidenceGraph` / `UpdateEvidenceGraph`: `parseDraft` before the write, `applyDraft` inside the `writes.Run` closure after the owner's own write, `ownerBoardProto` after). Do not copy its hand-wired delete facets, probes or effects entries: S15-61 builds those from the list. S15-06 (`000064.sql`) is the precedent for rebuilding `source_type_metadata_fields` with a wider `CHECK`.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | Migration `000069.sql` *(new)*, with `-- migrate: foreign_keys off`: rebuild `source_type_metadata_fields` exactly as `000064.sql` with `CHECK (level IN ('source', 'artifact', 'graph', 'citation'))`, copying every row, and recreate `source_type_metadata_fields_field_id_idx`; then `CREATE TABLE citation_metadata` and `citation_metadata_layout` as the graph's pair with `citation_id REFERENCES citations(id) ON DELETE CASCADE`, the mark columns and their `CHECK`s written into the `CREATE TABLE` (the text of `000067.sql`), and `citation_metadata_field_id_idx`, `citation_metadata_layout_field_id_idx` | One step for one PR; `000064` is the shipped shape of the rebuild. The owner column needs no extra index: `UNIQUE (citation_id, field_id)` and the layout PK lead with it (honesty test) | Two steps (the rebuild and the tables apart): no reader needs them apart. `ALTER` for the `CHECK`: SQLite cannot |
| D-2 | `catalogmodel`: `Tables` gains `{Name: "citation_metadata", Bucket: BucketFacet}` and `{Name: "citation_metadata_layout", Bucket: BucketFacet}` after the graph's pair; `FKs` gains, after the graph's four: `citation_metadata.citation_id → citations CASCADE BucketFacet Audited`, `citation_metadata.field_id → source_metadata_fields NO ACTION BucketResource`, `citation_metadata_layout.citation_id → citations CASCADE BucketFacet Audited`, `citation_metadata_layout.field_id → source_metadata_fields CASCADE BucketFacet Audited`. `MetadataTables` gains `{Level: vocabkey.LevelCitation, Kind: KindCitation, OwnerTable: "citations", OwnerColumn: "citation_id", Values: "citation_metadata", Layout: "citation_metadata_layout", Up: &MetadataUp{Level: vocabkey.LevelArtifact, Column: "artifact_id"}}` last | The graph's rows, renamed. S15-61's **Next adds**, verbatim. Up is the Artifact, not the graph: the audit scope resolves through the Artifact (rule "A Citation holds metadata"), and the graph's `source_id` would equal it | Up through `graph_id`: two equal paths, and the rule names the Artifact |
| D-3 | `vocabkey.MetadataLevels()` returns all four levels in `Levels()` order. Swift `Level.metadataLevels` gains `.citation`. Both doc comments say every level holds metadata and the Citation also has built-ins | Rule "One level type": "All four hold metadata from S15-54" | — |
| D-4 | `HoldsMetadata` / `holdsMetadata` stay, and every guard that calls them stays (`sourcevocab`, `citationrender.Placeholders`, `FakeStore`). The parser's `if !level.HoldsMetadata()` branch after `level.Valid()` goes, with `CodeMetaNotAtLevel`, its `DiagnosticCodes` entry, Swift's `CitationDiagnosticCode.metaNotAtLevel`, `L10n.CitationFormats.diagMetaNotAtLevel`, its `Localizable.xcstrings` entry and the `docs/citation-formats.md` row | The branch can no longer run, and its message ("A citation has no metadata fields") becomes false: a dead mechanism the PR replaces. The guards validate wire input and read as the rule; the rule names the set | Keeping the code for a future level with no metadata: none is planned. Deleting `HoldsMetadata`: the rule keeps the set, and wire validation reads it |
| D-5 | The effects registry gets one partial literal, beside the `source_metadata` ones under the comment block: `"citation_metadata": {EvidenceGraph: up("citation_id", "graph_id")}`, with the comment "graphfill reads a Citation's own page from S15-56, so a value write drops its graph". The layout table gets no extra | Map rule "The printed page is a metadata field" (map review K-1); S15-61 D-9 left this slot. The graph cache loads values, not layout | Declaring it in S15-56: the rule puts it here, and S15-56 then needs no effects change |
| D-6 | `citationrender.fillValues` adds `add(vocabkey.LevelCitation, s.cited.ID)` with the Artifact and graph owners, and sets `v.Rows[vocabkey.LevelCitation] = byOwner.Of(sourcemetadata.Owner{Level: vocabkey.LevelCitation, ID: c.ID})` | One batched read for every level (rule "Citations render on demand, from SQL"; map Scale "a render of 300 Citations reading their Citation values in one batched read"). `CitationValues.Resolve` is generic over levels | A second read for Citations: a second batching path |
| D-7 | Wire: `CreateCitationWithObservationsRequest.metadata = 12` (`MetadataDraft`, "absent = no metadata"), `CreateCitationWithObservationsResponse.metadata = 4` (`repeated MetadataWorkspaceEntry`, "the Citation's board after the write, in display order"), `UpdateCitationRequest.metadata = 9` ("absent = metadata unchanged; present = the stored values become these"), `UpdateCitationResponse.metadata = 3` ("the Citation's board after the write; the stored board when no draft was sent"). The comments copy `CreateArtifactRequest` / `UpdateEvidenceGraphResponse` word for word | The Artifact and graph messages' shape and words (rule "Metadata saves with its owner's write") | A `MetadataBoard` reply: the Artifact and graph replies carry entries |
| D-8 | Handlers: `CreateCitationWithObservations` calls `parseDraft(req.GetMetadata())` after `observationDraftsToInputs`, before `withStagedDepictions`; inside the `writes.Run` closure, after `citations.CreateWithObservations` succeeds, `more, err := applyDraft(tx, userID, sourcemetadata.Owner{Level: vocabkey.LevelCitation, ID: res.Citation.ID}, draft)` and returns `append(changes, more...)`; after the write, `ownerBoardProto(c, owner)` fills `Metadata`. `UpdateCitation` does the same around `citations.Update`, with the owner from `citationID` | `evidence_graphs.go`'s create and update, line for line | A `MetadataDraft` on `citations.CreateInput`: the Artifact and graph writes keep metadata in the handler |
| D-9 | `CreateCitedBridge` takes no `metadata` | The composer creates its Citation through `CreateCitationWithObservations` (`ensuredCitationID`) and passes `citation_id` to the bridge (`CitationComposerModel+Authoring.swift` line 636) | A draft on the bridge: no caller would send it |
| D-10 | The Swift store is unchanged: `GenealogyStore`, `GoStore` and `FakeStore` `createCitationWithObservations` / `updateCitation` send no draft and ignore the reply's rows | No Swift caller has a Citation board until S15-56, which adds the parameter with its first caller. An absent draft changes nothing (D-7) | Adding the parameter now: an unused parameter on three stores |
| D-11 | Deletes need no hand code: `releaseCitation` → `releaseRow(KindCitation)` → `releaseFacets` runs the list's two Citation facets after `citation_notes`; the field's inbound probe and field-layout facet follow the list. An Artifact or Source delete never reaches a Citation: each is refused first while a Citation (`citations.artifact_id`) or an Artifact (`artifacts.source_id`) remains. So a graph delete is the largest release: at Scale a graph of 10 Citations with up to 8 values each, 80 value rows plus layout | S15-61 D-8. The map's scope entry said "a Source delete releases 600 Citations' values"; that delete is refused, so planning corrected the entry (2026-11-22) | — |
| D-12 | A move needs no change. `sourcemove` keeps a moved Artifact's Citations on it, and `citation_metadata` scopes through `artifact_id`, so its values follow (rule "A Citation holds metadata") | S15-24 | — |
| D-13 | Swift copy for the Citation list, the tick, the toasts, the warning and the delete heading is § 6 **Strings**, from S15-D30 § 2.1, until the board is agreed; the agreed board's wording replaces it there (D-15) | The brief gates the copy | — |
| D-14 | `ListDraftWorkspace` still refuses the Citation level, and `SourceWorkspace.metadataRows(for: .citation)` still returns nil | The draft read's parents and the composer's board are S15-55 and S15-56 | — |
| D-15 | The view decisions are S15-D30's agreed frames: CL-1 – CL-7, CL-W1 and the inventory. No view code changes for CL-1, CL-2, CL-4, CL-5, CL-W1: `Level.metadataLevels` and the engine's placeholders draw them. If the board changes a layout (not only copy) of the lists, the tick or the completion row, that is a Stop condition | S15-D6, S15-D7 and S15-D16 built the views over the level list | — |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `citation_metadata`, `citation_metadata_layout` *(new)* | table | `evidence_graph_metadata`, `evidence_graph_metadata_layout` | One pair per level is the shape (§ 5.5); this is the fourth |
| `MetadataTables` Citation entry *(new)* | registry entry | the three entries | Extends the registry; no new code path |
| `citation_metadata` effects literal *(new)* | registry entry | `"source_metadata": {Search: …}` | The partial-literal slot S15-61 D-9 made for it |
| `metadata` fields on four citation messages *(new)* | proto field | `CreateArtifactRequest.metadata`, `UpdateEvidenceGraphResponse.metadata` | Same message types; no new message |
| `L10n.SourceTypes.level(.citation)` *(new case body)* | L10n | the three `LevelCopy` cases | Replaces the `preconditionFailure` |
| `deleteImpact.via.citationMetadataFieldId` *(new)* | L10n key | `deleteImpact.via.evidenceGraphMetadataFieldId` | One heading per inbound via (parity test) |

Searched: `rg 'MetadataTables|HoldsMetadata|metadataLevels'` (every reader iterates the list), `rg 'parseDraft|applyDraft'` (the two Artifact and two graph writes), `rg 'metadataEffects'`, `rg 'case \.citation'` in Swift.

**Builds on.** `catalogmodel.MetadataTables` (S15-61), `sourcemetadata` owners (S15-07), `applyDraft` / `ownerBoardProto` (S15-08), the level-driven Source type page (S15-12, S15-18, S15-17).

**Deletes.** `citationformat.CodeMetaNotAtLevel` and the parser branch that returns it; its `DiagnosticCodes` entry; `CitationDiagnosticCode.metaNotAtLevel`; `L10n.CitationFormats.diagMetaNotAtLevel` and its `case`; the `citationFormats.diagnostic.meta_not_at_level` xcstrings entry; the `docs/citation-formats.md` table row; `L10n.SourceTypes.level`'s `preconditionFailure`; `TestOwnerLevels`' `"citation"` bad owner and `TestMetadataOwners`' `"citation level"` bad case (each replaced, T-2, T-10).

**Next adds.** S15-55 reads ancestors with `catalogmodel.SourcePath(MetadataTables, LevelCitation)` (Citation → Artifact → Source) and adds the graph as a Citation's further ancestor; S15-56 adds the Swift store's `metadata` parameter and reads `CreateCitationWithObservationsResponse.metadata`; S15-60 seeds rows at `vocabkey.LevelCitation` through `sourcevocab`'s registry, which the widened `CHECK` takes.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A Citation owner on every board RPC | `sourcemetadata` via `storeFor` | `requireOwner` refuses an id that is no Citation (AC-4.12); a deleted Citation's board is `ErrInvalid` as a deleted graph's |
| A fourth suggestion list on the type page | `SourceTypeSuggestionList(level: .citation)` | Its own `CatalogQueryKey.typeSuggestions(…, level: .citation)` read, its own failure (CL-2); `L10n.SourceTypes.level(.citation)` no longer traps |
| A fourth tick in Copy type | `SourceTypeCopyModel` over `Level.metadataLevels` | Absent when the list is empty (AC-2.2); `CopyType` accepts `citation` once `HoldsMetadata` does (AC-2.3) |
| Citation rows in completion | `SourceTypeFormatsModel.completionOptions` | Rows come from the engine; the level Chip uses `L10n.CitationFormats.levelName(.citation)`, which exists |
| A Citation group in the field delete notice | `pvDeleteImpact` on the Metadata page | Projector `projectCitation` exists; the heading is the new key (AC-4.9) |
| Citation values in a render | `citationrender.fillValues` | A Citation with no values resolves the zero value, as an empty graph does |

### Scale

At the map's Scale:

- **Render.** 300 Citations add one batch of Citation owners to `ListByOwnersTx`: one more SELECT (9 → 10); 1,200 Citations add three batches of 500 (11 → 14). Budgets stay 100 ms and 400 ms; `TestRenderScale` seeds a Citation value on every Citation (T-6).
- **A Citation write.** `CreateCitationWithObservations` / `UpdateCitation` with a draft of up to 8 values: one `Apply` and one board read (`ListWorkspace` over one owner), as an Artifact write. Effects: the Source scope, the graph (`EvidenceGraph`), `metadata_field_usage` on a create or release; `citations` is moved by the Citation row as today.
- **Deletes.** A graph delete releases at most 10 Citations × (8 values + 8 layout rows) at Scale, two more facet probes per Citation. A Source delete and an Artifact delete release no Citation (D-11).
- **Type page.** One more `typeSuggestions` read per page open and per Copy sheet (4 instead of 3), each a keyed partial read of at most about 12 rows.
- **Field delete impact.** One more probe (`citation_metadata.field_id`), indexed by `citation_metadata_field_id_idx`.

### Edges

- **Assumptions.**
  - `SourcePath` walks Citation → Artifact → Source; `TestSourcePathIn`'s `citation` case already pins the type read.
  - `metadataEffects` builds `up("citation_id", "artifact_id", "source_id")`; a released Citation value resolves its Source through the Citation's delete change in the same batch, which carries `artifact_id` (`releaseCitation`'s columns). T-5 holds it with a Citation case.
  - `up("citation_id", "graph_id")` resolves a released value through the deleted Citation's change, which carries `graph_id`. T-5.
  - `releaseFacets` runs a kind's facets in list order; the Citation's notes facet is first, then its two metadata facets, then the row. No facet depends on another.
  - `TestRenderScale` counts SELECTs exactly; T-6 changes the counts with this PR's reason.
  - The `source_type_metadata_fields` rebuild keeps every row: the old `CHECK` is a subset of the new.
- **Neighbors.**
  - An owner at level `citation` with an Artifact's id: `ErrInvalid`, nothing written (AC-4.12).
  - `{citation.page}` (a built-in) and `{citation.meta.page}` (a field) are different targets; both parse in the full form, and the list form refuses both (`not_in_list_form`).
  - A Source type whose Citation list is empty: the page shows the empty copy; Copy type's tick is absent; nothing else reads it.
  - `GetDraftMetadataBoard` with `level: "citation"`: still `ErrInvalid` (D-14).
- **Removed inputs.** A Citation deleted: its values and layout are released and audited (AC-4.7), the field's Used by drops (`metadata_field_usage`), and the graph's cache entry drops (`EvidenceGraph`). A field deleted: refused while a Citation holds it (AC-4.9); its Citation layout rows are released with it. A type's Citation suggestion removed: stored Citation values stay.
- **Real data.** The seed has no Citation suggestions (`sourcevocab` registry). `TestSeedCitations` and `TestSeededFormatsNeedOnlySuggestedFields` run unchanged over the 26 types.
- **Untrusted size.** None new: a `MetadataDraft` is bounded by `checkFieldIDs` as for the other owners.

### Schema

Migration `core/database/migrations/000069.sql` *(new)*:

```sql
-- S15-54: a Citation holds metadata values and layout, the fourth level
-- (rule "A Citation holds metadata"); a Source type may suggest fields for
-- its Citations.
-- migrate: foreign_keys off

CREATE TABLE source_type_metadata_fields__new (
	source_type_id  BLOB NOT NULL REFERENCES source_types(id) ON DELETE CASCADE,
	field_id        BLOB NOT NULL REFERENCES source_metadata_fields(id) ON DELETE CASCADE,
	level           TEXT NOT NULL CHECK (level IN ('source', 'artifact', 'graph', 'citation')),
	sort_order      INTEGER,

	PRIMARY KEY (source_type_id, field_id, level)
) STRICT;
INSERT INTO source_type_metadata_fields__new (source_type_id, field_id, level, sort_order)
SELECT source_type_id, field_id, level, sort_order FROM source_type_metadata_fields;
DROP TABLE source_type_metadata_fields;
ALTER TABLE source_type_metadata_fields__new RENAME TO source_type_metadata_fields;
CREATE INDEX source_type_metadata_fields_field_id_idx ON source_type_metadata_fields(field_id);

CREATE TABLE citation_metadata (
	id          BLOB PRIMARY KEY,
	citation_id BLOB NOT NULL REFERENCES citations(id) ON DELETE CASCADE,
	field_id    BLOB NOT NULL REFERENCES source_metadata_fields(id),
	value_text  TEXT,
	is_unknown  INTEGER NOT NULL DEFAULT 0
		CHECK (is_unknown IN (0, 1) AND (is_unknown = 0 OR value_text IS NULL)),
	is_supplied INTEGER NOT NULL DEFAULT 0
		CHECK (is_supplied IN (0, 1) AND NOT (is_unknown = 1 AND is_supplied = 1)
			AND (is_supplied = 0 OR value_text IS NOT NULL)),
	UNIQUE (citation_id, field_id)
) STRICT;

CREATE TABLE citation_metadata_layout (
	citation_id BLOB NOT NULL REFERENCES citations(id) ON DELETE CASCADE,
	field_id    BLOB NOT NULL REFERENCES source_metadata_fields(id) ON DELETE CASCADE,
	sort_order  INTEGER NOT NULL,
	dismissed   INTEGER NOT NULL DEFAULT 0 CHECK (dismissed IN (0, 1)),
	PRIMARY KEY (citation_id, field_id)
) STRICT;

CREATE INDEX citation_metadata_field_id_idx ON citation_metadata(field_id);
CREATE INDEX citation_metadata_layout_field_id_idx ON citation_metadata_layout(field_id);
```

Registered in `catalogmodel` as D-2. Delete class: facet → parent (`citations`), CASCADE as backstop, `Audited` (Go releases them). Audit: entity `citation_metadata` / `citation_metadata_layout`, scope `up("citation_id", "artifact_id", "source_id")` from `metadataEffects`.

### Go core

| Package | Change |
| --- | --- |
| `core/vocabkey` | `MetadataLevels` returns four levels (D-3); `Level` doc comment |
| `core/database/catalogmodel` | D-2 |
| `core/citationformat` | D-4: remove `CodeMetaNotAtLevel`, its `DiagnosticCodes` entry and the parser branch |
| `core/database/effects` | D-5 |
| `core/database/citationrender` | D-6 |
| `core/database/metadatafields` | `ErrInUse` doc: "ErrInUse is returned by Delete when a value in source_metadata, artifact_metadata, evidence_graph_metadata or citation_metadata still references the field."; `Delete` doc, first sentence: "Delete erases a field when no Source, Artifact, Evidence graph or Citation stores a value for it." |
| `core/database/effects/registry.go` line 123 comment | "Source, Artifact, Evidence graph or Citation" |

Errors: none new. A Citation owner that does not exist is `sourcemetadata.invalid`.

### FFI

`api/proto/engine.proto`: D-7's four fields; the level comments at lines 755, 1183, 1202, 1223 read `"source", "artifact", "graph" or "citation" (vocabkey.MetadataLevels)`; lines 354, 1209, 1230 read "at every level" for "at all three levels" / "over all three levels". Handlers `api/ffi/handlers/citations.go` per D-8. Regenerate with `./scripts/generate-proto.sh`.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Citation list (CL-1 – CL-3) | `SourceTypeSuggestionList` | `macos/App/Features/SourceTypes/SourceTypeSuggestionList.swift` | No view change; drawn from `Level.metadataLevels` |
| Copy tick (CL-4) | `PVCheckbox` in `SourceTypeCopyDialog` | `macos/App/Features/SourceTypes/SourceTypeCopyDialog.swift` | No view change |
| Completion rows (CL-5) | `PVTextArea` completion | `macos/App/Features/SourceTypes/SourceTypeFormatsSection.swift` | No view change; rows from the engine |
| Warning (CL-6) | warning line | same | Copy only |
| Delete notice (CL-7) | `pvDeleteImpact` | `macos/App/Features/Metadata/MetadataView.swift` | One heading key |
| Level | `Level.metadataLevels` | `macos/App/Platform/Level.swift` | D-3 |

States: the Citation list's empty, loading, failed and read-only states are the list view's (CL-2). Accessibility: the list group label, picker label and button labels come from `LevelCopy` (§ Strings). Wide: unchanged (CL-W1).

### Strings

New, in `L10n.SourceTypes.level(.citation)` (replacing `preconditionFailure`), from S15-D30 § 2.1:

| Key | Default value |
| --- | --- |
| `sourceTypes.suggested.level.citation.title` | "On each Citation" |
| `sourceTypes.suggested.level.citation.meaning` | "The spot you cite: a page, a line, an entry" |
| `sourceTypes.suggested.level.citation.empty` | "No Citation fields yet. Assign what you note about each spot you cite, such as its page or line." |
| `sourceTypes.suggested.level.citation.pickerLabel` | "Metadata field to assign on each Citation" |
| `sourceTypes.suggested.level.citation.phrase` | "on each Citation of %@ Sources" |
| `sourceTypes.suggested.level.citation.copyTick` | "Suggested fields on each Citation" |
| `deleteImpact.via.citationMetadataFieldId` (key `"citation_metadata.field_id"` in `viaFormats`) | "%lld citations record a value for this field" |

Changed (old scope named):

| Key | New default value |
| --- | --- |
| `sourceTypes.toast.removedBodyWithValues` | "%1$@ is no longer suggested %2$@. The field stays in this project’s vocabulary, and the %3$lld Sources, Artifacts, graphs, Citations and Source types that use it are unchanged." (comment: "Toast body after detaching a field that Sources, Artifacts, graphs, Citations or Source types still use; arguments are the field label, the list's level phrase (see sourceTypes.suggested.level.*.phrase), then how many Sources, Artifacts, graphs and Citations hold a value plus how many Source types name it in a citation format") |
| `sourceTypes.toast.removedBodyNoValues` | Value unchanged; comment: "Toast body after detaching a field no Source, Artifact, graph, Citation or Source type uses; arguments are the field label then the list's level phrase (see sourceTypes.suggested.level.*.phrase)" |
| `citationFormats.diagnostic.unprefixed_meta` | "Name a level before meta: source, artifact, graph or citation" |
| The Associated fields column comment (L10n line 8273) | "Source types list column header: how many metadata fields the type suggests at every level" |
| `toastRemovedBody`'s doc comment | "`valueCount` is the field's `usedBy`: Sources, Artifacts, graphs and Citations holding a value, plus Source types that name the field in a format." |

Removed: `citationFormats.diagnostic.meta_not_at_level`.

Copy that names three levels and stays true: none left after the sweep (DoD).

## 7. Steps

**STEP-1 — The Citation level in the catalog**
Files: `core/database/migrations/000069.sql` *(new)*, `core/database/catalogmodel/model.go`, `core/database/catalogmodel/metadata.go`, `core/vocabkey/vocabkey.go`, `core/vocabkey/vocabkey_test.go`, `core/database/sourcemetadata/sourcemetadata_test.go`, `core/database/deleteimpact/facet_order_test.go`. Skills: `add-catalog-migration`, `add-catalog-model`.
Do: D-1, D-2, D-3 (Go). Update `TestLevels` (four), `TestOwnerLevels` (T-2), `TestMetadataFacetOrder` (T-4).
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/...` passes except the parser tests STEP-2 changes; `TestPragmaHonesty`, `TestStoresAreRegistered`, `TestMetadataEffects` pass.

**STEP-2 — `{citation.meta.…}` parses**
Files: `core/citationformat/parse.go`, `core/citationformat/parse_test.go`, `core/database/citationrender/placeholders_test.go`, `core/database/sourcevocab/copy_test.go`, `core/database/sourcevocab/sourcevocab_test.go`. Skill: —.
Do: D-4 in Go. T-3, T-7, T-8.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/citationformat/... ./core/database/citationrender/... ./core/database/sourcevocab/...` passes.

**STEP-3 — Effects and audit**
Files: `core/database/effects/registry.go`, `core/database/effects/released_metadata_scope_test.go`, `core/database/effects/evidence_graphs_test.go`. Skill: `add-audit-scope`.
Do: D-5; the comment edit of § 6 Go core. T-5.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/effects/...` passes.

**STEP-4 — A Citation's values render**
Files: `core/database/citationrender/load.go`, `core/database/citationrender/render_test.go`, `core/database/citationrender/scale_test.go`. Skill: —.
Do: D-6. T-6.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/citationrender/...` passes with the new SELECT counts.

**STEP-5 — The Citation writes carry a draft**
Files: `api/proto/engine.proto`, generated `api/proto/engine/engine.pb.go` and `macos/App/Platform/Generated/engine.pb.swift`, `api/ffi/handlers/citations.go`, `api/ffi/handlers/citations_test.go`. Skill: `add-ffi-handler`. The handlers keep `withStagedDepictions` / `withProjectCatalog` as they are.
Do: D-7, D-8, the proto comments of § 6 FFI. T-9.
Check: `./scripts/generate-proto.sh` leaves no diff on a second run; `CGO_ENABLED=1 go test -tags fts5 ./api/...` passes.

**STEP-6 — Board RPCs, deletes and the move on a Citation**
Files: `api/ffi/handlers/metadata_test.go`, `core/database/sourcemetadata/sourcemetadata_test.go`, `core/database/deleteimpact/facets_test.go`, `core/database/sourcemove/sourcemove_test.go`, `core/database/metadatafields/metadatafields.go`. Skill: `add-catalog-delete` (read: no new facet or probe is hand-written).
Do: T-1, T-10, T-11, T-12; the doc comments of § 6 Go core.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/... ./api/...` passes.

**STEP-7 — Swift: the Citation list and tick**
Files: `macos/App/Platform/Level.swift`, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `macos/ProvenenciaTests/SourceTypePageModelTests.swift`, `macos/ProvenenciaTests/SourceTypeCopyModelTests.swift`. Skills: `add-localized-string`, `add-swift-test`.
Do: D-3 (Swift), § Strings' level copy, the two toast strings, the column comment. T-13, T-14.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/ffi/ -run TestSwiftVocabularyMatchesGo` passes (metadata levels); `xcodebuild test` passes the two suites.

**STEP-8 — Swift: the warning and the delete heading**
Files: `macos/App/Platform/CitationFormatVocabulary.swift`, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `macos/ProvenenciaTests/PVDeleteImpactTests.swift`, `macos/ProvenenciaTests/CitationFormatsCopyTests.swift`. Skill: `add-localized-string`.
Do: D-4 (Swift), the `unprefixed_meta` copy, the `citation_metadata.field_id` heading. T-15.
Check: `TestSwiftVocabularyMatchesGo` passes (diagnostic codes, inbound vias); `python3 scripts/check-localizable-xcstrings.py` passes; `xcodebuild test` passes.

**STEP-9 — Docs**
Files: `docs/source-layer-data-model.md`, `docs/citation-formats.md`, `docs/deployment-plan/spike-15/deployment-plan.md` (map row), `docs/deployment-plan/spike-15/completed.md`, this plan, `docs/deployment-plan/spike-15/design/S15-D30-source-type-page-citation-level.md` (moved to `docs/deployment-plan/spike-15/design/archive/`), `docs/deployment-plan/spike-15/design/README.md`, `VERSION`, `core/version.go`, `MARKETING_VERSION`.
Do: per the Definition of done. In `source-layer-data-model.md`: line 291 names `citation_metadata`; line 332 "at the four levels that hold metadata: a Source, an Artifact, an Evidence graph and a Citation"; § 5.5's heading "Metadata at four levels" and the anchor at line 455 (`#55-metadata-at-four-levels`); line 336 names the Citation (the spot cited); line 361 adds `citation_metadata` and `citation_metadata_layout` with `citation_id REFERENCES citations(id)`; line 365 "A field is in use while any of the four value tables holds it, and `deleteimpact.UsedBy` counts all four"; line 366 "No search document is built from Artifact, graph or Citation metadata. A citation reads the levels its format names, in the order its chain writes them"; line 428's sentence on moving Citations between Artifacts is replaced by "A Citation is bound to its Artifact: it does not move to another Artifact (spike 15)". In `citation-formats.md`: line 43 "The Citation level has built-ins and metadata, like the other three"; line 71 "then, at every level, every field of the project in `metadatafields.List` order"; remove the `meta_not_at_level` row; the `unprefixed_meta` row's meaning is unchanged.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/` passes; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/sourcemetadata/sourcemetadata_test.go` `TestOwnerTables` | Add `vocabkey.LevelCitation` to the levels and `tables` (`citation_metadata`, `citation_metadata_layout`, `citation_id`); `newLevelOwner` gains a `LevelCitation` case that creates a Citation on the Source's first Artifact and graph through `citations.CreateWithObservations` with no Observations → every operation writes only the Citation's tables; a field suggested at another level does not reach it | AC-4.2, D-2 |
| T-2 | Go | same file, `TestOwnerLevels` | Replace owner `"citation"` with `"short citation id"` (`{LevelCitation, src.ID[:15]}`) and add `"citation with a source id"` (`{LevelCitation, src.ID}`) → `ErrInvalid`, no rows | AC-4.12 |
| T-3 | Go | `core/citationformat/parse_test.go` | "three in order": `{source.foo} and {citation.meta.x} and {parish.title}` → `unknown_builtin` 1–11, `unknown_level` 40–52; "meta in list": `{citation.meta.x}` list → `not_in_list_form` 1–16; new "citation meta": `{citation.meta.line_number}` full → none | AC-3.2, AC-3.3, D-4 |
| T-4 | Go | `core/database/deleteimpact/facet_order_test.go` `TestMetadataFacetOrder` | `KindCitation` → `citation_notes.citation_id`, `citation_metadata.citation_id`, `citation_metadata_layout.citation_id`; `KindMetadataField` facets end with `citation_metadata_layout.field_id`; field inbound → `…, evidence_graph_metadata.field_id, citation_metadata.field_id, ViaCitationFormats` | D-11 |
| T-5 | Go | `core/database/effects/released_metadata_scope_test.go` `TestReleasedMetadataScopesThroughDeletedOwner` | New case `citation`: a Citation holding one value, `citations.Delete` → each released `citation_metadata*` change resolves the Source with the Citation's delete change and not without it; the `citation_metadata` change also resolves `EvidenceGraphs` to the Citation's graph. `evidence_graphs_test.go` `TestEvidenceGraphsResolve`: a `sourcemetadata.Set` on a Citation → `EvidenceGraphs` = its graph | AC-4.1, AC-4.7, D-5 |
| T-6 | Go | `core/database/citationrender/render_test.go` `TestRender`; `scale_test.go` `TestRenderScale` | `TestRender` new rows: full `{citation.meta.line_number}`, the Citation holds "14" → "14"; unknown with unknown text "n.l." → "n.l."; supplied "14" → "[14]". `TestRenderScale`: `scaleValues` gains `{"citation_metadata", "citation_id", {"column": "2"}}` seeded on every Citation; SELECTs 10 for 300 and 14 for 1,200; budgets unchanged | AC-3.5, AC-3.6, D-6 |
| T-7 | Go | `core/database/citationrender/placeholders_test.go` `TestPlaceholders` | Full form: Citation built-ins, then one `{citation.meta.<key>}` row per field in `metadatafields.List` order; list form: no Citation row | AC-3.1 |
| T-8 | Go | `core/database/sourcevocab/sourcevocab_test.go` `TestAppendSuggestion`; `copy_test.go` `TestCopyType` | Append at `citation` → one row, listed at `citation`, counted in `sourcetypes.Type.SuggestedFields`; `CopyType` with `Levels: [citation]` → only Citation rows, `sort_order` kept; `[citation, citation]` → `ErrInvalid` | AC-1.6, AC-2.3 |
| T-9 | Go | `api/ffi/handlers/citations_test.go` `TestCreateCitationWithObservations`, `TestUpdateCitation` | New table rows: create with a draft {Line "14"} → one revision (one more `audit_transactions` row), a `citation_metadata` row, reply `metadata` holds Line "14"; create without → no row, reply lists the type's `citation` suggestions empty; update with {Line "15"} over {Line "14", Column "2"} → Line "15", no Column, one revision; update without → unchanged, reply is the stored board; a draft naming a malformed field id → `request.invalid_id` and no Citation written | AC-4.3, AC-4.4, AC-4.5, AC-4.6 |
| T-10 | Go | `api/ffi/handlers/metadata_test.go` `TestMetadataOwners` | `newMetadataOwners` gains `citation` (a Citation made with `CreateCitationWithObservations` on `page1` and the default graph) and assigns `suggested` at `citation` too; the loop runs `"citation"` → every assertion as for a graph, plus `effects.evidence_graphs` holds the graph on Set. The bad case `"citation level"` becomes `"citation level, artifact id"` (`{citation, page1}`) → `sourcemetadata.invalid` | AC-4.1, AC-4.2, AC-4.12 |
| T-11 | Go | `core/database/deleteimpact/facets_test.go` `TestImpactMetadataFieldHolders`, `TestMetadataValueAuditParity`; a new subtest in `TestImpactMetadataFieldHolders` | A field held by one Citation only → one group `citation_metadata.field_id`, kind `citation`, total 1; with 2 Sources and 3 Citations, `UsedBy` = 5; `TestMetadataValueAuditParity` runs `LevelCitation` (its release by `evidencegraphs.Delete` of a graph with no Subjects) → cleared and released changes read alike | AC-4.8, AC-4.9, AC-4.10 |
| T-12 | Go | `core/database/sourcemove/sourcemove_test.go` `TestMove` | The bundle's Citation holds Line; after the move it still holds Line and the revision scopes both Sources | AC-4.11, D-12 |
| T-13 | Swift | `macos/ProvenenciaTests/SourceTypePageModelTests.swift` `assigningWritesAtTheCitationLevelOnly` *(new)* | Assign Line at `.citation` → `store.suggestionsByLevel[.citation]["t1"]` = [Line]; the other three unchanged; toast body = `toastAssignedBody(field: "Line", phrase: "on each Citation of Book Sources")`; then remove it with `usedBy` 6 → toast body ends "…and the 6 Sources, Artifacts, graphs, Citations and Source types that use it are unchanged." | AC-1.1, AC-1.2, AC-1.5 |
| T-14 | Swift | `macos/ProvenenciaTests/SourceTypeCopyModelTests.swift` (existing loops over `Level.metadataLevels`) | The loops now cover `.citation`; `includedLevels` and `copyType`'s `levels` equal the four levels | AC-2.1, AC-2.2 |
| T-15 | Swift | `macos/ProvenenciaTests/PVDeleteImpactTests.swift` (line 291's table) | Adds `("citation_metadata.field_id", "citation", 3, "3 citations record a value for this field")` | AC-4.9 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `TestRenderScale` (SELECT counts), `TestSwiftVocabularyMatchesGo` (levels, codes, vias), `TestPragmaHonesty`, `CitationFormatsCopyTests` (the code list).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: `rg -n 'meta_not_at_level|CodeMetaNotAtLevel|metaNotAtLevel|diagMetaNotAtLevel'` across the repo finds no hit outside `docs/deployment-plan/`; `rg -n -i 'three levels|three value tables|all three levels|"source", "artifact" or "graph"|has only built-ins|metadata-at-three-levels'` across `core/`, `api/proto/engine.proto`, `macos/App/`, `.agents/`, `.cursor/rules/`, `docs/*.md` finds no hit about metadata levels; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none)
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New
- [ ] Version bump 0.33.1 → 0.34.0 (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief S15-D30 moved to design/archive/ and design/README.md updated
- [ ] Domain docs updated: docs/source-layer-data-model.md and docs/citation-formats.md per STEP-9
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Open a project with the seeded Census type. Open Source types › Census. See four lists under Suggested fields; the fourth, "On each Citation", is empty with its copy (AC-1.1).
2. On a plugin type's page the Citation list shows no picker, plus or remove (AC-1.4). On Census, in the Citation list's picker type "line", Return, Return. Line is in the Citation list; the toast names "each Citation of Census Sources" (AC-1.2). The Evidence graph list's picker still offers Line if it is not there (AC-1.3).
3. Copy the type: the sheet has "Suggested fields on each Citation" with "1 field"; Copy type; the new type's Citation list holds Line (AC-2.1).
4. In the full note, type `{cit li`: the completion list shows Line at the Citation; Return puts `{citation.meta.line_number}`; no warning shows (AC-3.1, AC-3.2). Type `{meta.page}`: the warning names four levels (AC-3.4).
5. With a fixture Citation holding Line "14" (set through `SetMetadata` in a Go test project, or the CLI if one exists), the preview of a Source whose first Citation is that one shows "14" where the format places Line (AC-3.5).
6. On the Metadata page, delete Line while that Citation holds it: the notice lists "1 citation records a value for this field" (AC-4.9).
7. Repeat 1 at a pane of 1600pt and wider: the lists stay stacked in the side column (CL-W1).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| The `source_type_metadata_fields` rebuild loses a row or an index | `migrate` runs `foreign_key_check`; the schema hash and `TestPragmaHonesty` check the index; `TestInstall` reads the seeded rows back |
| `TestRenderScale` SELECT counts differ from 10 / 14 | Stop condition below |
| A Citation's graph path resolves nothing for a released row | T-5 holds it; stop condition below |
| Swift parity tests fail mid-PR | STEP-7 and STEP-8 each end on `TestSwiftVocabularyMatchesGo` |

**Stop and report if:**

- `catalogmodel.SourcePath(MetadataTables, LevelCitation)` errors, or `TestSourcePathIn`'s `citation` case no longer matches `sourcePathIn` once the entry is in the real list.
- `metadataEffects` panics on the `citation_metadata` literal (it sets a field the builder owns), or `init` refuses `up("citation_id", "graph_id")` as an `EvidenceGraph` path.
- A released `citation_metadata` change does not resolve its Source or its graph through the deleted Citation's change (T-5).
- `TestRenderScale` needs a SELECT count other than 10 (300) or 14 (1,200), or misses its budget.
- `TestPragmaHonesty` asks for an index D-1 does not create.
- Any view under §4's Swift page row needs a code change beyond `Level.metadataLevels` and L10n to draw the fourth list, tick or completion rows.
- The agreed S15-D30 board changes a layout, not only copy (D-15).
- `GetDraftMetadataBoard` or `SourceWorkspace.metadataRows` must change to make a test pass (D-14).

## 12. Open questions

None.

## 13. PR

**Title:** S15-54 — Citations hold metadata
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-54-citations-hold-metadata.md`.
