# S15-54 — Citations hold metadata

**Status:** Planned
**Spike / slice:** Spike 15 · Slice 11 — Metadata at any level
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: no view draws a Citation board until S15-56; the field delete notice gains one heading string, drawn by its existing group row, as S15-08 added its two without a brief)
**Board:** —
**Depends on:** S15-24 (landed [#935](https://github.com/Jake-Robins-Studios/provenencia/pull/935)), S15-61 (landed [#943](https://github.com/Jake-Robins-Studios/provenencia/pull/943)), S15-62 (landed [#950](https://github.com/Jake-Robins-Studios/provenencia/pull/950)), S15-63 (landed [#955](https://github.com/Jake-Robins-Studios/provenencia/pull/955))
**Blocks:** S15-55, S15-60
**Branch:** `s15-54-citations-hold-metadata`
**Version bump:** minor, 0.37.0 (today's `VERSION`) → **0.38.0** (or the next minor after `main`'s `VERSION` when you rebase): a catalog format step, new wire fields, and every citation now reads a Citation's own values first ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-catalog-migration`](../../../../.agents/skills/add-catalog-migration/SKILL.md), [`add-catalog-model`](../../../../.agents/skills/add-catalog-model/SKILL.md), [`add-audit-scope`](../../../../.agents/skills/add-audit-scope/SKILL.md), [`add-catalog-delete`](../../../../.agents/skills/add-catalog-delete/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests), `.cursor/rules/swift-tests.mdc`
**Context:** map scope entry S15-54 ([`../deployment-plan.md`](../deployment-plan.md)); working rules "A Citation holds metadata", "Metadata lives at four levels with one vocabulary", "One level type", "A format reads a field from the nearest level that holds it", "Metadata saves with its owner's write", "The printed page is a metadata field" (the effects path to the graph), "A type suggests fields, not levels"; precedent S15-08 ([plan](S15-08-artifacts-and-graphs-hold-metadata.md), [#791](https://github.com/Jake-Robins-Studios/provenencia/pull/791)); S15-61 **Next adds** ([plan](S15-61-metadata-levels-list.md)); [`docs/source-layer-data-model.md`](../../../source-layer-data-model.md) §§ 5.4, 5.5; [`docs/citation-formats.md`](../../../citation-formats.md); [`docs/catalog-deletes.md`](../../../catalog-deletes.md)
**Planned:** 2026-11-24 against `main` @ `11c91bb`
**Review:** [`S15-54-citations-hold-metadata.review.md`](S15-54-citations-hold-metadata.review.md) — round 2: Fits / Ready with changes; every finding Fixed but X-8 (Declined with evidence); nothing open

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

A Citation (the spot cited) becomes the fourth level that holds metadata, beside the Source, the Artifact and the Evidence graph: same fields, layout, marks and audit. A format's `{meta.key}` reads the Citation's own value first, so a whole-issue newspaper PDF's two Citations in one graph can each carry their own page and column. Values save with the Citation's create and update writes, and go, audited, when the Citation or its graph is deleted.

**Why now.** S15-61 made the levels one declared list, S15-62 made formats read the nearest level, and S15-63 gave every board the type's one suggestion list, so the Citation level is one list entry, its tables, its draft on two writes, and one render owner. S15-55 (ancestors on boards), S15-60 (the seeded `page`) and S15-56 (the composer's board) build on it.

**What stays.** No view changes: the composer, the Artifact sheet and the graph form draw what they draw today, and Swift sends no Citation draft until S15-56. A Citation's board read (`GetMetadataBoard`, the write replies) treats the Source as its only ancestor until S15-55 (D-10). The locator, `{citation.page}` and the printed-page input stay (S15-58, S15-59, S15-56).

## 2. User stories

**US-1.** As the engine, when a write names a Citation as a metadata owner, I store, clear, dismiss and reorder its values exactly as for an Artifact or a graph, so that every board operation works at the fourth level.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A Citation C of Source S; `SetMetadata` owner `{level: "citation", id: C}`, the type's suggested field Provider, "FamilySearch" | The reply's board holds Provider "FamilySearch", suggested; `effects.source_scopes` holds S |
| AC-1.2 | The same Citation; `SetMetadata` an extra field Line "14", then `ReorderMetadata` [Line, Provider], `DismissMetadataSuggestion` and `ClearMetadata` as `TestMetadataOwners` runs them on a graph | Each reply equals what the graph case returns for the same calls, and each write scopes S |
| AC-1.3 | `GetMetadataBoard` owner `{citation, C}` on a type that suggests Provider | The board lists Provider, suggested, empty |
| AC-1.4 | Any `sourcemetadata` operation on `Owner{LevelCitation, id}` where `id` is 15 bytes, or (for the writes) 16 bytes that name no Citation | `sourcemetadata.ErrInvalid`; no row written in any value or layout table |

**US-2.** As a researcher, when a Citation holds a value, its citation prints that value ahead of its graph's, Artifact's and Source's, so that two Citations in one graph can differ.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | A census Citation with `line_number` "21" on the Citation and "14" on its graph | The full citation holds ", line 21" and not "line 14" |
| AC-2.2 | `line_number` marked unknown on the Citation, "14" on its graph | The full citation holds no "line" (the unknown value answers and stops the walk) |
| AC-2.3 | No `line_number` on the Citation, "14" on its graph | ", line 14" (unchanged) |
| AC-2.4 | `jurisdiction` "Elsewhere" on the Citation, "Calder County, Westmark" on the Source; render the full form and preview the list form for that Citation | The full form holds "Elsewhere"; the list form holds "Calder County, Westmark" and not "Elsewhere" (the list form reads the Source alone) |
| AC-2.5 | `TestRenderScale` at 300 and 1200 Citations, each Citation holding its `line_number` | Every result is `censusFull`; 10 and 14 SELECTs; inside today's 100 ms and 400 ms budgets |

**US-3.** As the app, when I create or update a Citation with a metadata draft, the values save in the same write and the reply carries the Citation's board, so that S15-56 needs no second write and no reload.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `CreateCitationWithObservations` with `metadata` = values {Line "21"} and one layout row {Line, 0, false} | One write; the reply's `metadata` holds Line "21"; `citation_metadata` holds one row for the new Citation; `effects.source_scopes` holds the Source |
| AC-3.2 | `CreateCitationWithObservations` with no `metadata` | No `citation_metadata` row; the reply's `metadata` is the new Citation's board (the type's suggestions, empty) |
| AC-3.3 | `UpdateCitation` with no `metadata` on a Citation holding Line "21" | Line "21" stays; the reply's `metadata` holds it |
| AC-3.4 | `UpdateCitation` with a present, empty `metadata` on the same Citation | Line is cleared; the reply's board has no Line row |
| AC-3.5 | `CreateCitationWithObservations` whose draft names a field id that is not in `source_metadata_fields` | The call fails with `sourcemetadata.invalid`; no Citation, Observation or metadata row exists afterwards |

**US-4.** As a researcher, when I delete a Citation, its graph, or a field, its Citation values go or block as every other level's do.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | `DeleteCitation` on a Citation (no Observations) holding Provider and Line, with one layout row | The changes hold two `citation_metadata` deletes and one `citation_metadata_layout` delete, before the `citation` delete; no row remains; `effects.source_scopes` holds the Source |
| AC-4.2 | `DeleteEvidenceGraph` on a graph (no Subjects) whose one Citation holds Provider | The `citation_metadata` delete is among the changes, scoped to the Source; no row remains |
| AC-4.3 | Released `citation_metadata` and `citation_metadata_layout` changes of AC-4.1, each resolved on its own with the `citation` delete change beside it | Each resolves the Source through the deleted Citation's change; without that change, none |
| AC-4.4 | Delete impact of a field one Citation C holds a value for | Refused; one group via `citation_metadata.field_id`, kind `citation`, total 1, listed C's ref; the field's Used by counts 1 |
| AC-4.5 | The Swift field delete notice for that group (via `citation_metadata.field_id`, total 2) | "2 citations record a value for this field"; total 1: "1 citation records a value for this field" |
| AC-4.6 | Delete impact of the Artifact or of the Source of a Citation holding values | Refused as today (via `citations.artifact_id`, `artifacts.source_id`); no metadata row changes |

**US-5.** As a researcher, when I move an Artifact to another Source, its Citations' values travel with it and scope the new Source.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-5.1 | Source A's bundle (Artifact A1, graph G1, Citation C on A1 and G1 holding Line "film 7") moved to Source B; then `Set` Line "film 8" on C | C still holds Line after the move; the `Set` write's source scopes are [B] |

## 3. Scope

| In | Covered by |
| --- | --- |
| Migration `000070.sql`: `citation_metadata`, `citation_metadata_layout`, their `field_id` indexes | STEP-2, AC-1.1 |
| `catalogmodel`: the level list's single `Up` becomes ordered `Ups` with one marked toward the Source; the parity test against `NearestFirst`; the Citation entry; the two tables and four FKs | STEP-1, STEP-2, T-2, T-3 |
| `vocabkey.MetadataLevels()` gains `LevelCitation`, so `NearestFirst()` reads it first | STEP-2, T-1 |
| Effects: `citation_metadata`'s `EvidenceGraph` path to its graph; Entity, SourceScope and Lists from the list | STEP-2, T-6 |
| Delete rows: the Citation's value and layout facets and the field-in-use probe, from the list | STEP-2, AC-4.1 – AC-4.4 |
| `citationrender.fillValues` reads the Citation owner | STEP-3, AC-2.1 – AC-2.5 |
| `CreateCitationWithObservations` and `UpdateCitation` take a `MetadataDraft` and reply with the Citation's board | STEP-4, AC-3.1 – AC-3.5 |
| Swift: `Level.metadataLevels` gains `.citation`; the field-delete heading for `citation_metadata.field_id` | STEP-5, AC-4.5, T-12 |
| Map and domain docs; version bump | STEP-7 |

| Out | Home |
| --- | --- |
| A Citation board's ancestors beyond the Source (its graph and Artifact) on boards and their "met above" | S15-55 |
| A Citation's draft board (`ListDraftWorkspace`, `GetDraftMetadataBoard` at the Citation level) | S15-55 |
| The composer's board; Swift's store passing a Citation draft; `citation_metadata`'s `Reads` entry for the citations-by-Artifact read | S15-56 |
| `graphfill` and `conclusiondetails` reading the Citation's `page` | S15-56 |
| The seeded `page` field | S15-60 |
| A metadata draft on `CreateCitedBridge` | not planned: a bridge's Citation takes its values through `UpdateCitation` once S15-56's composer edits it |
| A search document built from Citation values | not planned (rule "A Citation holds metadata") |
| Moving a Citation to another Artifact | not planned (refused, rule "A Citation holds metadata") |
| Copy Source carrying Citations or their values | not planned: Copy Source copies no Citation today (`core/database/sourcecopy/sourcecopy.go`) |

## 4. Current state

Verified at `11c91bb`.

| Area | Where | Today |
| --- | --- | --- |
| Level set | `core/vocabkey/vocabkey.go` `MetadataLevels`, `NearestFirst`, the `Level` doc comment | Three levels; `NearestFirst` is graph, Artifact, Source; the comment says "The first three hold metadata values; the Citation only built-ins" |
| Level list | `core/database/catalogmodel/metadata.go` `MetadataUp`, `MetadataLevelTables.Up`, `MetadataTables`, `SourcePath` | Each entry has at most one `Up *MetadataUp`; `SourcePath` follows it to `sources` |
| List tests | `core/database/catalogmodel/metadata_test.go` `TestMetadataTables`, `TestSourcePath` | The citation entry is a test fixture built with `Up:`; "missing level" asks for `LevelCitation` |
| Catalog model | `core/database/catalogmodel/model.go` `Tables`, `FKs` | Rows for the three levels' value and layout tables; none for the Citation |
| Citations table | `core/database/migrations/000059.sql` | `citations.artifact_id` (NO ACTION) and `citations.graph_id` (CASCADE); both NOT NULL. Latest migration is `000069.sql` |
| Store | `core/database/sourcemetadata/owner.go` `sourcePathIn`, `newStore`, `buildStores` | `sourcePathIn` joins each step through `path[k-1].Up.Column` |
| Store tests | `core/database/sourcemetadata/sourcemetadata_test.go` `TestSourcePathIn` (citation fixture with `Up:`), `TestOwnerLevels` (a `"citation"` owner expected `ErrInvalid` for every op), `TestOwnerTables` and `newLevelOwner` (Artifact and graph only), `TestStoresAreRegistered` | |
| Board read | `core/database/sourcemetadata/sourcemetadata.go` `listWorkspaces` | Builds each board's `CitationValues` from the owner's level and its Source only; a Citation owner gets the same |
| Draft board | `core/database/sourcemetadata/sourcemetadata.go` `ListDraftWorkspace` | Refuses every level but Artifact and graph (stays; S15-55) |
| Walker | `core/database/sourcemetadata/annotation.go` `CitationValues.Nearest` | Walks `vocabkey.NearestFirst()`; no change |
| Effects | `core/database/effects/registry.go` `metadataEffects`, `registry` | `metadataEffects` reads `e.Up` and `path[i].Up.Column`; no `citation_metadata` entry |
| Effects tests | `core/database/effects/registry_completeness_test.go` `TestSourceEvidenceIsNotActivity`; `core/database/effects/released_metadata_scope_test.go` `TestReleasedMetadataScopesThroughDeletedOwner` | Rows for the three levels only |
| Delete rows | `core/database/deleteimpact/facets.go` `metadataLevelFacets`, `releaseCitation`; `core/database/deleteimpact/register.go` `metadataFieldEdges` | Built from `MetadataTables`; `releaseCitation` runs `releaseFacets(KindCitation)` (notes today); a graph delete releases its Citations through `releaseCitation` |
| Delete order test | `core/database/deleteimpact/facet_order_test.go` `TestMetadataFacetOrder` | No `KindCitation` row; field inbound lists three metadata vias then `ViaCitationFormats` |
| Deletes that remove Citations | `core/database/deleteimpact/register.go` `inboundEdgeList` | Only `citations.Delete` and a graph delete. An Artifact delete is refused by `citations.artifact_id`, a Source delete by `artifacts.source_id`, so neither ever releases a Citation |
| Render | `core/database/citationrender/load.go` `fillValues` | Adds Source, Artifact and graph owners; `v.Rows` has no Citation level |
| Render tests | `core/database/citationrender/render_test.go` `TestRenderNearestLevel` (its `build` sets values before it cites); `core/database/citationrender/scale_test.go` `scaleValues`, `seedScale`, `TestRenderScale` (9 and 11 SELECTs) | |
| Citation writes | `api/ffi/handlers/citations.go` `CreateCitationWithObservations` (`writes.Run` returning `citations.CreateResult`, inside `withStagedDepictions`), `UpdateCitation` (`writes.Run` returning `citations.Citation`) | No draft; replies carry no board |
| Draft precedent | `api/ffi/handlers/evidence_graphs.go` `CreateEvidenceGraph`, `UpdateEvidenceGraph`; `api/ffi/handlers/artifacts.go` `CreateArtifact`, `UpdateArtifact`; `api/ffi/handlers/metadata.go` `parseDraft`, `applyDraft`, `ownerBoardProto` | The graph handlers apply the draft in the same write and reply with `ownerBoardProto` |
| Wire | `api/proto/engine.proto` `MetadataOwner` (comment lists three levels), `CreateCitationWithObservationsRequest` (fields 1 – 11), `CreateCitationWithObservationsResponse` (1 – 3), `UpdateCitationRequest` (1 – 8), `UpdateCitationResponse` (1 – 2) | |
| Handler tests | `api/ffi/handlers/metadata_test.go` `newMetadataOwners`, `TestMetadataOwners` (artifact and graph); `api/ffi/handlers/citations_test.go` `TestCreateCitationWithObservations`, `TestUpdateCitation`; `api/ffi/handlers/evidence_graphs_test.go` `newGraphFixture` (creates one Citation on `page1`, not kept in the struct) | |
| Move | `core/database/sourcemove/sourcemove.go`; test `core/database/sourcemove/sourcemove_test.go` `TestSourceKeysAreClassified` and the bundle metadata check (`world.metadata`) | A move changes only `source_id` on Artifacts, graphs and Subjects; Citations carry no `source_id` |
| Swift level | `macos/App/Platform/Level.swift` `Level.metadataLevels` (source, artifact, graph; used only by the Go parity test `api/ffi/swift_vocabulary_test.go` "metadata levels"); `macos/App/Platform/GenealogyStore.swift` `MetadataOwner` doc comment | |
| Swift headings | `macos/App/Platform/L10n.swift` `DeleteImpact.viaFormats`; `macos/App/Resources/Localizable.xcstrings` `deleteImpact.via.evidenceGraphMetadataFieldId`; `macos/ProvenenciaTests/PVDeleteImpactTests.swift` `knownViaHeadingsMatchEngineEdges`; Go parity `api/ffi/swift_vocabulary_test.go` "inbound vias" (`deleteimpact.ResourceInboundVias`) | A Go via with no Swift heading fails the parity test |
| Field comments | `core/database/metadatafields/metadatafields.go` `ErrInUse`, `Delete` | Name the three value tables and owners |

**Precedent.** S15-08 ([#791](https://github.com/Jake-Robins-Studios/provenencia/pull/791), migration `000065.sql`) added the Artifact and graph levels: copy its table pair shape, its draft on the owner's create and update RPCs (`CreateEvidenceGraph`, `UpdateEvidenceGraph`: `parseDraft` before the write, `applyDraft` inside it, `ownerBoardProto` after it), and its field-delete heading strings. Do not copy its hand-wiring of stores, facets and effects: since S15-61 the list entry gives all of them.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `MetadataUp` gains `ToSource bool`. `MetadataLevelTables.Up *MetadataUp` becomes `Ups []MetadataUp`, nearest first, empty for the Source. A method `func (e MetadataLevelTables) SourceUp() *MetadataUp` *(new)* returns a pointer to the first up with `ToSource`, nil when none. `SourcePath` follows `SourceUp()`. At each entry it visits (the asked level first, then each one it steps to), before stepping up, it errors when the entry has ups and marks none (`"catalogmodel: level %s has no up toward the Source"`) or more than one (`"catalogmodel: level %s marks %d ups toward the Source"`), naming that entry; entries off the path are not checked | The map scope and the working rule "A format reads a field from the nearest level that holds it" name ordered `Ups` with the Artifact marked as the audit-scope path, so S15-55 reads a Citation's ancestors (graph, Artifact, then the Source through each) from the list | Keeping `Up` and adding a separate `Ups`: the Artifact would be stated twice. An index field naming the marked up: a number to keep in step by hand |
| D-2 | The Citation entry is `{Level: LevelCitation, Kind: KindCitation, OwnerTable: "citations", OwnerColumn: "citation_id", Values: "citation_metadata", Layout: "citation_metadata_layout", Ups: []MetadataUp{{Level: LevelGraph, Column: "graph_id"}, {Level: LevelArtifact, Column: "artifact_id", ToSource: true}}}`, last in `MetadataTables`. Artifact and graph entries become `Ups: []MetadataUp{{Level: LevelSource, Column: "source_id", ToSource: true}}` | Rule "A Citation holds metadata": the audit scope resolves through the Citation's Artifact, as the `citations` effect does today (`up("artifact_id", "source_id")`). The type read follows the same path | The graph as the path: the graph and the Artifact share their Source by invariant, but `citations` and `citation_notes` already scope through the Artifact |
| D-3 | `TestMetadataTables` checks, for each entry: every up's column has an FK to that level's owner table; and the levels of `Ups`, in order, each sit after the entry's own level in `vocabkey.NearestFirst()`, at strictly increasing positions. It checks nothing else about `Ups` | The parity test the rule asks for: the list's parents agree with the one declared order | A second declared order: the rule says the order is declared nowhere but `MetadataLevels` |
| D-4 | `vocabkey.MetadataLevels()` returns source, artifact, graph, citation. `NearestFirst()` is then citation, graph, artifact, source with no code change; its doc comment and the `Level` doc comment name the Citation first and drop "the Citation only built-ins" | Rule "One level type"; `NearestFirst` is `MetadataLevels` reversed | — |
| D-5 | Migration `core/database/migrations/000070.sql` *(new)* creates the pair exactly as `000065.sql`'s graph pair with `citation_id BLOB NOT NULL REFERENCES citations(id) ON DELETE CASCADE`, plus `is_unknown` and `is_supplied` with `000067.sql`'s checks written inline in the CREATE, and the two `field_id` indexes. No backfill | Same shape, rules and marks as the other three (rule "Metadata lives at four levels"). `UNIQUE (citation_id, field_id)` and the layout's primary key cover the `citation_id` FK index | An `ALTER` step for the marks: the table is new |
| D-6 | `catalogmodel` registers `citation_metadata` and `citation_metadata_layout` as `BucketFacet` and four FKs exactly as the graph's four (owner FKs `CASCADE`, `BucketFacet`, `Audited: true`; value `field_id` `NO ACTION` `BucketResource`; layout `field_id` `CASCADE` `BucketFacet` `Audited: true`) | `add-catalog-model`; `TestPragmaHonesty` | — |
| D-7 | `registry` in `core/database/effects/registry.go` gains `"citation_metadata": {EvidenceGraph: from("citation_id", citationObservationGraphs)}` and no other extra: no `Search`, no `Reads` | Rule "The printed page is a metadata field": S15-54 declares the path to the graph so `graphfill`'s read in S15-56 is invalidated from the first value written. `citationObservationGraphs` is the registry's one answer to "which loaded graphs show this Citation" (the `citations` entry uses it): `graphfill` loads a graph by its Subjects, so a Citation with no Observations is in no loaded graph, and an Observation's graph is its Citation's (`observations.ErrOtherGraph`). No search document (rule "A Citation holds metadata"). The `Reads` path belongs with S15-56's reader (review M-2) | `up("citation_id", "graph_id")` (S15-61's Next adds): a second Citation-to-graph path that drops a graph that does not show the Citation. Waiting for S15-56: the rule places it here |
| D-8 | `fillValues` adds `vocabkey.LevelCitation` with `s.cited.ID` beside the Artifact and graph owners, and sets `v.Rows[vocabkey.LevelCitation]` from `byOwner`. No other render change: `CitationValues.Nearest` already walks `NearestFirst()`, and the list form parses its fields at the Source level | One batched read for all levels (rule "Citations render on demand, from SQL") | — |
| D-9 | The Citation writes take the draft in the handler, as the graph's do: `parseDraft(req.GetMetadata())` before `withStagedDepictions` / `withProjectCatalog`; inside the write, after `citations.CreateWithObservations` (or `citations.Update`), `applyDraft(tx, userID, sourcemetadata.Owner{Level: vocabkey.LevelCitation, ID: <the Citation's id>}, draft)`, its changes appended to the write's; after the write, `ownerBoardProto` for that owner fills the reply's `metadata`, with or without a draft | Rule "Metadata saves with its owner's write"; the S15-08 precedent. `core/database/citations` gains no import of `sourcemetadata` | A `MetadataDraft` on `citations.CreateInput`: the package would import `sourcemetadata`, and no other owner package does |
| D-10 | `listWorkspaces` is not changed: a Citation's board reads its own values and its Source's, so its inherited value and "met above" come from the Source alone until S15-55. No AC pins that | S15-55 owns ancestors on boards (map). No view draws a Citation board before S15-56, which lands after S15-55 | Adding the graph and Artifact here: that is S15-55's whole PR |
| D-11 | Proto: `CreateCitationWithObservationsRequest.metadata = 12` (`MetadataDraft`, "absent = no metadata"); `CreateCitationWithObservationsResponse.metadata = 4` (`repeated MetadataWorkspaceEntry`, "the new Citation's board after the write"); `UpdateCitationRequest.metadata = 9` (`MetadataDraft`, "absent = metadata unchanged; present = the stored values become these"); `UpdateCitationResponse.metadata = 3` ("the Citation's board after the write; the stored board when no draft was sent"). `MetadataOwner.level`'s comment lists "citation" | The graph messages' wording | — |
| D-12 | Swift: `Level.metadataLevels` gains `.citation` last, and the `Level` and `MetadataOwner` doc comments say the four levels hold metadata. No Swift store method changes | The Go parity test "metadata levels"; S15-56 adds the store's draft argument with its first caller | Adding the draft to Swift's `createCitation` / `updateCitation` now: no caller until S15-56 |
| D-13 | The map was corrected with this plan (2026-11-24): deleting a Citation or its graph releases its values; an Artifact or a Source that holds Citations cannot be deleted (`citations.artifact_id`, `artifacts.source_id`), so the rule's "(graph, Artifact, Source)" and the scope entry's "a Source delete releases 600 Citations' values, up to 4,800 audited rows" and its Check's "its Artifact and its Source" are wrong. The largest release is a graph delete: 10 Citations, up to 80 values | Verified in `inboundEdgeList` and `TestImpact…` "artifact blocked by citation". A factual fix, not a product change | Leaving the map as written: S15-55 and S15-56 would plan against a delete path that does not exist |

**Rules this plan bends.** None. D-13 corrects a factual line in the rule "A Citation holds metadata" and the scope entry; the rule's intent (every delete that removes Citations releases their values through the same path) holds.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `citation_metadata`, `citation_metadata_layout` *(new)* | table | `evidence_graph_metadata`, `evidence_graph_metadata_layout` (`000065.sql`) | Extends the pattern: one pair per level is the design (rule "Metadata lives at four levels") |
| `MetadataUp.ToSource`, `MetadataLevelTables.Ups`, `MetadataLevelTables.SourceUp` *(new)* | field / method | `MetadataLevelTables.Up` | Replaces it (Deletes) |
| `"citation_metadata"` registry literal *(new)* | effects entry | `"source_metadata"` literal (extras only) | Same partial-literal shape S15-61 D-9 set up for this entry |
| `deleteImpact.via.citationMetadataFieldId` *(new)* | L10n key | `deleteImpact.via.evidenceGraphMetadataFieldId` | One heading per Go via (parity test) |
| `metadata` on four citation messages *(new)* | proto fields | `CreateEvidenceGraphRequest.metadata`, `CreateEvidenceGraphResponse.metadata` | Same message types, reused |

Searched: `Up`, `.Up.`, `SourcePath(` across `core/` (three production callers: `core/database/catalogmodel/metadata.go`, `core/database/sourcemetadata/owner.go`, `core/database/effects/registry.go`; test readers `core/database/catalogmodel/metadata_test.go`, `core/database/sourcemetadata/sourcemetadata_test.go` `TestSourcePathIn`, `core/database/effects/registry_completeness_test.go` `TestMetadataEffects`); `evidence_graph_metadata` across the repo; `applyDraft`, `ownerBoardProto`; `LevelGraph` outside tests.

**Builds on.** S15-61's level list (stores, facets, probes and effects derive from one entry); S15-62's nearest-first walker; S15-08's draft-on-the-owner's-write handlers and heading strings.
**Deletes.** `MetadataLevelTables.Up` and its three readers' uses (`SourcePath`, `sourcePathIn`, `metadataEffects`); the test-only citation fixtures in `TestSourcePath` and `TestSourcePathIn` (they use the shipped entry); `TestOwnerLevels`' `"citation"` invalid owner (becomes `"short citation id"`); the sentences that say the Citation holds only built-ins (`vocabkey.go`, `Level.swift`, `citation-formats.md`) and the line anticipating moving Citations between Artifacts (`source-layer-data-model.md` § 6).
**Next adds.** S15-55 walks `Ups` for a Citation's ancestors (graph, Artifact, and the Source through `SourceUp`) and reads them in its one batched `readByOwners`. S15-56 adds `"citation_metadata"`'s `Reads` path and Swift's draft argument. S15-60 adds `page` with no level work. `fillValues` keeps its hand-paired owners (four after this PR); S15-55, which derives a Citation's ancestors from `Ups`, says whether `fillValues` takes that derivation too, so one mechanism answers "a Citation's owners at every level" (review M-5).

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A metadata owner at the `citation` level on every owner RPC (`SetMetadata`, `ClearMetadata`, `DismissMetadataSuggestion`, `ReorderMetadata`, `GetMetadataBoard`) | `api/ffi/handlers/metadata.go` `parseOwner` → `sourcemetadata` `storeFor`, `requireOwner` | A short id is `ErrInvalid` (`storeFor`); a write on a missing Citation is `ErrInvalid` (`requireOwner`); a board read of a missing Citation is `ErrInvalid` (`listWorkspaces`: no type row). AC-1.4 |
| A Citation delete and a graph delete with Citation values | `deleteimpact.releaseCitation` → `releaseFacets(KindCitation)` | The facets come from the list; `Remaining` must be zero or the delete fails (`ErrReleaseIncomplete`). AC-4.1, AC-4.2 |
| A field delete probe at the Citation level | `deleteimpact.metadataFieldEdges`; projector `projectCitation` | The listed row opens the citation composer, as a Citation's other listed rows do today. AC-4.4 |
| A render of a Citation with its own values | `citationrender.fillValues` | A Citation with none reads as today. AC-2.3 |

### Scale

At the map's Scale (a render of 300 Citations; a graph of 10 Citations with up to 8 values each; a board of 30 suggested fields):

- **Render.** `fillValues` adds the Citations to its one `ListByOwnersTx` call: one more SELECT per 500 Citations. `TestRenderScale` goes from 9 to 10 SELECTs at 300 and from 11 to 14 at 1200 (three batches), with the Citation values seeded (STEP-3), inside its existing 100 ms and 400 ms budgets.
- **Writes.** A Citation create or update with a draft runs `Apply` on at most 8 values: the same cost as a graph form's save. Its effects: the Source scope, the `metadata_field_usage` list on create or delete of a value, and `graphcache` dropping the Citation's graph (D-7). No keyed read.
- **Deletes.** A graph delete releases up to 10 Citations; each Citation runs two more facets (values, layout), each a SELECT, a DELETE per row and a `Remaining` count: about 60 statements and 80 audited value rows for the whole graph. A Source or Artifact delete never reaches a Citation (D-13).
- **Field delete probe.** One more `COUNT(*) … WHERE field_id = ?` on `citation_metadata`, served by its `field_id` index.
- **Board read.** A Citation board costs what a graph board costs (its type read joins one more table).

### Edges

- **Assumptions.** `CitationValues.Nearest` assumes `NearestFirst()` holds every level whose rows are in `Rows`, in one order: kept, `Rows[LevelCitation]` is set only by `fillValues` (T-7). `sourcePathIn` assumes each path step names the column toward the next entry: kept by `SourceUp` (T-3, T-4). `metadataEffects` assumes `path[i]` for `i < len-1` has an up toward the Source: kept by `SourcePath`'s check (T-3). `eachLevel` assumes every `MetadataLevels()` level has a store: kept by `TestStoresAreRegistered`.
- **Neighbors.** A value on the Citation and on its graph → the Citation's (AC-2.1). An unknown on the Citation → stops the walk (AC-2.2). None on the Citation → the graph's, unchanged (AC-2.3). A list-form field held only on the Citation → not read (AC-2.4). A Citation board's inherited value → the Source's, not the graph's or Artifact's (D-10; S15-55).
- **Removed inputs.** A Citation deleted → its values and layout released and audited before its row (AC-4.1). Its graph deleted → the same through `releaseCitation` (AC-4.2). Its Artifact or Source → refused while it exists (AC-4.6). Its Artifact moved → the values stay on the Citation and later writes scope the new Source (AC-5.1); history recorded before the move keeps its old scope, as every moved row's history does. A field deleted → refused while a Citation holds it (AC-4.4).
- **Real data.** The seed is unchanged; every seeded type's one suggestion list now also shows on a Citation's board (rule "A type suggests fields, not levels"). A census Citation's board lists the type's suggestions plus every head its formats read, as a graph's board does today (`TestSeedAnnotations` covers the graph case; no seeded format changes).
- **Untrusted size.** A draft from the wire is bounded as the graph's is: each field id once (`checkFieldIDs`), each id a field that exists (`requireFields`); no new list is read from data the app did not write.

### Schema

Migration `core/database/migrations/000070.sql` *(new)*:

```sql
-- S15-54: a Citation holds metadata values and layout, with the same fields,
-- marks and layout as a Source, an Artifact and an Evidence graph.

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

Registered in `catalogmodel` per D-6 and as one `MetadataTables` entry per D-2. Delete class: facets of the Citation (audited, released by `releaseCitation`); the value's `field_id` is a resource edge (a field in use). Audit: `citation_metadata` and `citation_metadata_layout` changes scope `up("citation_id", "artifact_id", "source_id")`, derived by `metadataEffects`.

### Go core

| Package | Change |
| --- | --- |
| `core/vocabkey` | `MetadataLevels()` returns four levels (D-4); doc comments on `Level` and `NearestFirst` |
| `core/database/catalogmodel` | `MetadataUp.ToSource`; `Ups`; `SourceUp()`; `SourcePath` follows `SourceUp` and errors per D-1; the Citation entry (D-2); `Tables` and `FKs` rows (D-6) |
| `core/database/sourcemetadata` | `sourcePathIn` joins on `path[k-1].SourceUp().Column`. The `Owner` doc comment names the Citation. No other change |
| `core/database/effects` | `metadataEffects`: `len(e.Ups) == 0` for the root, `p.SourceUp().Column` per step; the `"citation_metadata"` literal (D-7); the comment above the metadata literals keeps its wording |
| `core/database/deleteimpact` | No code change: the list adds the facets and the probe. `README.md`'s `ReleaseCitation` sentence names the Citation's metadata |
| `core/database/citationrender` | `fillValues` per D-8 |
| `core/database/metadatafields` | `ErrInUse` and `Delete` doc comments name the Citation (S15-61 left them for this PR) |

```go
// MetadataUp is one link from a level's owner table to the owner table of a
// level above it. ToSource marks the link SourcePath follows toward the
// Source: the type read and the audit scope.
type MetadataUp struct {
	Level    vocabkey.Level
	Column   string // owner table column pointing at Level's owner table
	ToSource bool
}

// in MetadataLevelTables:
	Ups []MetadataUp // the levels directly above, nearest first; none for the Source

// SourceUp is the up SourcePath follows, nil when none is marked.
func (e MetadataLevelTables) SourceUp() *MetadataUp
```

Errors: no new error code. A list with a bad `Ups` panics at init in `sourcemetadata` and `effects`, as a bad `Up` does today.

### FFI

`api/proto/engine.proto` per D-11. Handlers `api/ffi/handlers/citations.go` `CreateCitationWithObservations` and `UpdateCitation` per D-9. In `CreateCitationWithObservations` the `writes.Run` closure returns `res` with `append(changes, more...)`; the board read runs after `listedWritten`, on the same catalog `c`. In `UpdateCitation` the closure keeps returning `citations.Citation`. Regenerate with `./scripts/generate-proto.sh` (Go and Swift).

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Field delete heading for `citation_metadata.field_id` | existing `PVDeleteImpact` group row | `macos/App/Platform/L10n.swift` `DeleteImpact.viaFormats` | One entry after `evidence_graph_metadata.field_id` |
| `Level.metadataLevels` | — | `macos/App/Platform/Level.swift` | `.citation` last (D-12) |

States: unchanged. Accessibility: unchanged.

### Strings

L10n keys *(new)*: `deleteImpact.via.citationMetadataFieldId`, default "%lld citations record a value for this field", comment "Inbound heading for citation_metadata.field_id; argument is how many"; in `Localizable.xcstrings` a plural like `deleteImpact.via.evidenceGraphMetadataFieldId`: one "%lld citation records a value for this field", other "%lld citations record a value for this field". Removed: none. Copy that names the old scope: the field delete notice's three existing headings stay true; no copy says "three levels".

## 7. Steps

**STEP-1 — Ordered ups on the level list**
Files: `core/database/catalogmodel/metadata.go`, `core/database/catalogmodel/metadata_test.go`, `core/database/catalogmodel/README.md`, `.agents/skills/add-catalog-model/SKILL.md`, `core/database/sourcemetadata/owner.go`, `core/database/sourcemetadata/sourcemetadata_test.go` (`TestSourcePathIn` fixture), `core/database/effects/registry.go`, `core/database/effects/registry_completeness_test.go` (`TestMetadataEffects`: `e.Up == nil` becomes `len(e.Ups) == 0`). Skill: `add-catalog-model`.
Do: D-1 with the three shipped entries only (Artifact and graph get one marked up). Update the readers (`sourcePathIn`, `metadataEffects`, `TestMetadataEffects`) and the test fixtures that build entries with `Up:`; the `cycle` and `missingUp` fixtures of `TestSourcePath` mark their one up `ToSource: true`, so they keep today's messages. Add T-3's two error cases. Add one sentence to `core/database/catalogmodel/README.md` and to step 7 of `add-catalog-model`: "An entry's `Ups` are its direct parents, nearest first in `vocabkey.NearestFirst()`; exactly one is `ToSource`, the path the type read and the audit scope follow; `TestMetadataTables` checks the order." (review M-3)
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/catalogmodel/... ./core/database/sourcemetadata/... ./core/database/effects/... ./core/database/deleteimpact/...` passes; `rg '\.Up\b|\bUp:\s*&' core --type go` finds no hit.

**STEP-2 — The Citation level**
Files: `core/database/migrations/000070.sql` *(new)*, `core/database/catalogmodel/model.go`, `core/database/catalogmodel/metadata.go`, `core/database/catalogmodel/metadata_test.go`, `core/vocabkey/vocabkey.go`, `core/vocabkey/vocabkey_test.go`, `core/database/effects/registry.go`, `core/database/effects/registry_completeness_test.go`, `core/database/effects/released_metadata_scope_test.go`, `core/database/effects/evidence_graphs_test.go`, `core/database/deleteimpact/facet_order_test.go`, `core/database/sourcemetadata/sourcemetadata_test.go`, `core/database/sourcemetadata/owner.go` (`Owner` comment), `core/database/metadatafields/metadatafields.go` (comments). Skills: `add-catalog-migration`, `add-catalog-model`, `add-audit-scope`, `add-catalog-delete`.
Do: D-2, D-4, D-5, D-6, D-7. `TestSourcePath` and `TestSourcePathIn` use the shipped Citation entry instead of their fixture; "missing level" asks for `"nowhere"`. `TestOwnerLevels`' `"citation"` owner becomes `"short citation id": {Level: vocabkey.LevelCitation, ID: src.ID[:15]}`. `newLevelOwner` gains a `vocabkey.LevelCitation` case: create an Artifact with `artifactstest.Create` (a new Artifact links to every graph of its Source, `evidencegraphs.LinkArtifact`), take the Source's graph with `evidencegraphstest.SoleGraph(t, c, src.ID)`, and create the Citation with `writes.Run` around `citations.CreateWithObservations(tx, userID, citations.CreateInput{ArtifactID: a.ID, GraphID: g.ID, LocatorJSON: `{"version":1,"selectors":[{"type":"page","artifact_page":1}]}`}, nil)`. `TestOwnerTables` adds `vocabkey.LevelCitation: {"citation_metadata", "citation_metadata_layout", "citation_id"}` to `tables` and `vocabkey.LevelCitation` to its level loop. Add T-1, T-2, T-5, T-6, T-9.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/...` passes (schema hash, `TestPragmaHonesty`, delete honesty tests included).

**STEP-3 — A render reads the Citation first**
Files: `core/database/citationrender/load.go`, `core/database/citationrender/render_test.go`, `core/database/citationrender/scale_test.go`.
Do: D-8. In `TestRenderNearestLevel`, `build` cites first, then calls `set(w, src, art.ID, graph.ID, cit)` with the Citation id as a fifth parameter `cit []byte` (the four existing subtests take and ignore it), then renders that Citation. In `scale_test.go`, move `line_number` "14" from the `evidence_graph_metadata` entry of `scaleValues` to a new `citation_metadata` entry (owner column `citation_id`) that `seedScale` writes for each Citation it inserts; raise `TestRenderScale`'s `selects` to 10 and 14.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/citationrender/...` passes, `TestRenderScale` included.

**STEP-4 — Citation writes carry a draft**
Files: `api/proto/engine.proto`, generated `api/proto/engine/engine.pb.go` and `macos/App/Platform/Generated/engine.pb.swift`, `api/ffi/handlers/citations.go`, `api/ffi/handlers/citations_test.go`, `api/ffi/handlers/metadata_test.go`, `api/ffi/handlers/evidence_graphs_test.go` (keep the fixture Citation's id in `graphFixture` as `citationID` *(new)*). Skill: `add-ffi-handler`.
Do: D-9, D-11. In `TestMetadataOwners`' `bad` table, `"citation level"` becomes `"citation id that names no Citation"` (same owner, `{Level: "citation", Id: m.page1}`, same `ErrInvalid`), and the comment above it reads "a level with no owner row and a missing owner are sourcemetadata.invalid"; `TestGetDraftMetadataBoard`'s `"citation level"` case stays (the draft read refuses the Citation until S15-55). `newMetadataOwners` adds `citation: &engine.MetadataOwner{Level: "citation", Id: f.citationID}` and `TestMetadataOwners` ranges over it too. Add T-8, T-10, T-11.
Check: `./scripts/generate-proto.sh` leaves no diff on a second run; `CGO_ENABLED=1 go test -tags fts5 ./api/...` passes except the Swift parity subtests STEP-5 fixes ("metadata levels", "inbound vias").

**STEP-5 — Swift mirrors the fourth level**
Files: `macos/App/Platform/Level.swift`, `macos/App/Platform/GenealogyStore.swift` (`MetadataOwner` comment), `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `macos/ProvenenciaTests/PVDeleteImpactTests.swift`. Skills: `add-localized-string`, `add-swift-test`.
Do: D-12 and § 6 Strings; add T-12's two rows to `knownViaHeadingsMatchEngineEdges`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/ffi/ -run TestSwiftVocabularyMatchesGo` passes; `python3 scripts/check-localizable-xcstrings.py` passes; `xcodebuild test` (as `scripts/check-pr.sh` runs it) passes `PVDeleteImpactTests`.

**STEP-6 — Deletes and a move keep the values honest**
Files: `api/ffi/handlers/citations_test.go`, `api/ffi/handlers/evidence_graphs_test.go`, `core/database/deleteimpact/facets_test.go`, `core/database/deleteimpact/impact_test.go`, `core/database/sourcemove/sourcemove_test.go`.
Do: T-13, T-14, T-15, T-16, T-17; `TestImpactMetadataFieldHolders`' doc comment says "any of the four levels". No production code: if one fails, a Stop condition applies.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/... ./core/database/deleteimpact/... ./core/database/sourcemove/...` passes.

**STEP-7 — Docs, map and version**
Files: `docs/source-layer-data-model.md`, `docs/citation-formats.md`, `docs/catalog-deletes.md`, `core/database/effects/README.md`, `core/database/deleteimpact/README.md`, `docs/deployment-plan/spike-15/evidence-explained-citation-map.md` (the "(the Citation joins first with S15-54)" note), `docs/deployment-plan/spike-15/deployment-plan.md`, `docs/deployment-plan/spike-15/completed.md`, this plan, `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj`.
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-54-citations-hold-metadata.md` passes; `scripts/check-pr.sh` prints `check-pr: PASS`.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/vocabkey/vocabkey_test.go` `TestLevels` | `MetadataLevels()` = source, artifact, graph, citation; `NearestFirst()` = citation, graph, artifact, source; fresh slices (index 3 of `MetadataLevels` and 0 of `NearestFirst` are `LevelCitation` after a caller writes to a returned slice) | D-4 |
| T-2 | Go | `core/database/catalogmodel/metadata_test.go` `TestMetadataTables` | Levels equal `MetadataLevels()`; every up's FK exists (`citations.graph_id` → `evidence_graphs`, `citations.artifact_id` → `artifacts`); the order check is a test helper `upsOrderErr(list []catalogmodel.MetadataLevelTables) error` *(new)* in `core/database/catalogmodel/metadata_test.go`: nil for `MetadataTables`, and an error naming `citation` for a clone whose Citation entry has ups [artifact, graph] | D-2, D-3 |
| T-3 | Go | `core/database/catalogmodel/metadata_test.go` `TestSourcePath` | Shipped list, `LevelCitation` → [citation, artifact, source]; the shipped list with the Citation's ups cloned and neither marked, asked for `LevelCitation` → "level citation has no up toward the Source"; both marked → "level citation marks 2 ups toward the Source"; `"nowhere"` → "not in the metadata list"; the cycle and root cases as today | D-1 |
| T-4 | Go | `core/database/sourcemetadata/sourcemetadata_test.go` `TestSourcePathIn` | Shipped Citation entry → `SELECT t0.id, t2.source_type_id, t2.id FROM citations t0 JOIN artifacts t1 ON t1.id = t0.artifact_id JOIN sources t2 ON t2.id = t1.source_id WHERE t0.id IN (` | D-1, D-2 |
| T-5 | Go | `core/database/sourcemetadata/sourcemetadata_test.go` `TestOwnerLevels`, `TestOwnerTables`, `TestStoresAreRegistered` | A 15-byte Citation id → `ErrInvalid` for every op, no row; every op on a real Citation writes `citation_metadata` / `citation_metadata_layout` and no other level's tables; a store per level | AC-1.4, D-2 |
| T-6 | Go | `core/database/effects/registry_completeness_test.go` `TestSourceEvidenceIsNotActivity`; `core/database/effects/released_metadata_scope_test.go` `TestReleasedMetadataScopesThroughDeletedOwner` | Rows `{"citation_metadata", true, true}`, `{"citation_metadata_layout", false, true}`; a `"citation"` case: a Citation holding Provider deleted with `citations.Delete` → its two released changes resolve the Source through the `citation` change, and nothing without it; in `TestEvidenceGraphsResolve`, a value `Set` on a Citation with an Observation names that Citation's graph in `EvidenceGraphs`, and on a Citation with none names no graph | AC-4.3, D-7 |
| T-7 | Go | `core/database/citationrender/render_test.go` `TestRenderNearestLevel` | AC-2.1, AC-2.2 and AC-2.4 as subtests beside today's four (AC-2.4's list form through `RenderPreview` with `FormList` and the Citation target) | AC-2.1, AC-2.2, AC-2.4 |
| T-8 | Go | `core/database/citationrender/scale_test.go` `TestRenderScale` | 300 and 1200 Citations, `line_number` on each Citation → `censusFull`, 10 and 14 SELECTs, inside 100 ms and 400 ms | AC-2.3, AC-2.5 |
| T-9 | Go | `core/database/deleteimpact/facet_order_test.go` `TestMetadataFacetOrder` | `KindCitation`: `citation_notes.citation_id`, `citation_metadata.citation_id`, `citation_metadata_layout.citation_id`; `KindMetadataField` facets end with `citation_metadata_layout.field_id`; field inbound: source, artifact, graph, `citation_metadata.field_id`, `ViaCitationFormats` | AC-4.1, AC-4.4 |
| T-10 | Go | `api/ffi/handlers/metadata_test.go` `TestMetadataOwners`, `TestGetMetadataBoard` | The `"citation"` owner runs the same calls as the graph case with the same results and scopes; `GetMetadataBoard` on it lists Provider suggested and empty | AC-1.1, AC-1.2, AC-1.3 |
| T-11 | Go | `api/ffi/handlers/citations_test.go` `TestCreateCitationWithObservations`, `TestUpdateCitation` | Subtests for each AC of US-3 (AC-3.5 counts `citations` and `observations` rows before and after) | AC-3.1, AC-3.2, AC-3.3, AC-3.4, AC-3.5 |
| T-12 | Swift | `macos/ProvenenciaTests/PVDeleteImpactTests.swift` `knownViaHeadingsMatchEngineEdges` | Two rows: `("citation_metadata.field_id", "citation", 2, "2 citations record a value for this field")` and `("citation_metadata.field_id", "citation", 1, "1 citation records a value for this field")` | AC-4.5 |
| T-13 | Go | `api/ffi/handlers/citations_test.go` `TestDeleteCitationReleasesMetadata` *(new)* | On `newMetadataOwners`' fixture, a second Citation made with `CreateCitationWithObservations` on `page2` and `graphLinking(t, dir, page2)` with no Observations and a draft {Provider, Line} plus one layout row; then AC-4.1 through `DeleteCitation`, reading the revision's audit changes | AC-4.1 |
| T-14 | Go | `api/ffi/handlers/evidence_graphs_test.go` `TestDeleteEvidenceGraphReleasesCitationMetadata` *(new)* | On `newGraphFixture`: `CreateEvidenceGraph` "Empty" linking `page2` (no Subjects), a Citation on `page2` in it with no Observations and a draft {Provider}; then AC-4.2 through `DeleteEvidenceGraph` on that graph | AC-4.2 |
| T-15 | Go | `core/database/deleteimpact/facets_test.go` `TestImpactMetadataFieldHolders` | A helper `citationOwner(t, c, userID, artifact, graph sourcemetadata.Owner) sourcemetadata.Owner` *(new)* in `core/database/deleteimpact/facets_test.go` creates a Citation on `ownerFixture`'s Artifact and graph (already linked) through `citations.CreateWithObservations` with `testLocator` and no Observations. A Citation holding the field alone → one group via `citation_metadata.field_id`, kind `citation`, total 1, listed the Citation; `InboundTotal` 1; with every level holding it, four metadata groups in level order, the Citation's last | AC-4.4 |
| T-17 | Go | `core/database/deleteimpact/impact_test.go` `TestImpactKeepsCitationMetadata` *(new)* | With `ownerFixture` and `citationOwner`, impact of the Artifact and of the Source of a Citation holding a value → not allowed, gate inbound; `citation_metadata` row count unchanged | AC-4.6 |
| T-16 | Go | `core/database/sourcemove/sourcemove_test.go` (the bundle metadata test that calls `w.metadata(b)`) | `citedBundle` gains `cit []byte` *(new)*, filled in `cited()` after `w.Cite` by `SELECT id FROM citations WHERE artifact_id = ?` on `b.a1.ID`; `cited()` also sets Line "film 7" on that Citation beside its Artifact and graph values; `w.metadata` lists the Citation owner too, and `TestMove`'s row-count check becomes 3. After the move, the AC-5.1 subtest runs `writes.RunChanges` around `sourcemetadata.Set` of "film 8" on the Citation and compares the result's `Effects.SourceScopes` to [B] | AC-5.1 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `TestPragmaHonesty`, the `deleteimpact` honesty tests, `TestSwiftVocabularyMatchesGo`, `TestRenderScale`, `TestListWorkspacesAnnotationsScale` (no Citation boards: must not change).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Sweep, this PR: `rg '\.Up\.Column|e\.Up\b|\bUp:\s*&' core .agents` finds no hit; `rg 'only built-ins|three levels|three value tables|move or duplicate Citations|the Evidence graph, then the Artifact' docs/*.md core macos/App docs/deployment-plan/spike-15/evidence-explained-citation-map.md` finds no hit
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — or none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated)
- [ ] Domain doc updated if a rule in docs/*.md changed: `docs/source-layer-data-model.md` (§ 5.4: four levels; § 5.5 heading "Metadata at four levels", the Citation's pair, audit scope `up("citation_id", "artifact_id", "source_id")`, "any of the four value tables", "No search document is built from Artifact, graph or Citation metadata", a citation reads the Citation's value first; § 6 drop the line about moving Citations between Artifacts; the table list gains the pair), `docs/citation-formats.md` (`{meta.key}` row and "What each built-in reads": the Citation first; "The Citation level has only built-ins" becomes "The Citation level's built-ins are `citation.page`, `citation.image` and `citation.label`; it also holds metadata"), `docs/catalog-deletes.md` (the facet list and the field-in-use paragraph name the Citation pair), `core/database/effects/README.md` (a Citation's metadata value names the graphs of its Citation's Observations; the sentence that a metadata write drops no cached Evidence graph excepts the Citation's; `metadata_field_usage` moves on a Source, Artifact, Evidence graph or Citation value), `core/database/deleteimpact/README.md` (`ReleaseCitation`: notes and metadata first), `evidence-explained-citation-map.md` (the `{meta.key}` row's "(the Citation joins first with S15-54)" becomes the Citation first; "The Citation level has only built-ins: Citations carry no metadata (§ 6.9)" becomes "The Citation level's built-ins are above; a Citation also holds metadata (S15-54)"), `core/database/catalogmodel/README.md` and `add-catalog-model` (STEP-1)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

No view changes, so the check is the field delete notice and the engine tests.

1. Run `CGO_ENABLED=1 go test -tags fts5 ./api/ffi/handlers/ -run 'TestCreateCitationWithObservations|TestUpdateCitation|TestMetadataOwners|TestDeleteCitationReleasesMetadata|TestDeleteEvidenceGraphReleasesCitationMetadata' -v` and see each AC subtest pass.
2. In the app on a dogfood copy, open a Source with a Citation and its Artifact. The composer, the Artifact sheet and the graph form look and behave as before; create a Citation and edit it: both save as before.
3. On the Metadata page, a field used only on Sources still shows its Used by and delete notice as before (no Citation can hold a value from the app yet; the Citation heading is covered by T-12).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| The render scale budget fails with one more batched read | T-8 measures it at 300 and 1200 Citations; a failure stops the PR (below) |
| A `Ups` change breaks an init-time path derivation | `SourcePath` validates before walking; `sourcemetadata` and `effects` panic at init, so any `go test` run catches it in STEP-1 |
| `CreateCitationWithObservations` runs inside `withStagedDepictions`; a draft error must roll back the staged depictions too | The draft is applied inside the same `writes.Run`, so a draft error is a failed write like any Observation error today, which `withStagedDepictions` already cleans up; AC-3.5 counts the rows. No new staging test |

**Stop and report if:**

- `catalogmodel.MetadataLevelTables.Up` has a production reader other than `SourcePath`, `sourcePathIn` and `metadataEffects` at your base (the test readers are listed in § 6 Codebase fit).
- `TestRenderScale` exceeds 100 ms at 300 Citations or 400 ms at 1200 after STEP-3.
- `TestPragmaHonesty` or a `deleteimpact` honesty test asks for a probe, release or projector this plan does not list.
- A delete of a Citation or a graph leaves a `citation_metadata` row (`ErrReleaseIncomplete`), or its released changes do not resolve the Source through the ghost of the deleted Citation (T-6).
- `TestListWorkspacesAnnotationsScale` or `TestSeedAnnotations` changes its expected output (no board in them is a Citation's).
- An Artifact or Source delete releases a Citation at your base (D-13 would be wrong).

## 12. Open questions

None.

## 13. PR

**Title:** S15-54 — Citations hold metadata
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-54-citations-hold-metadata.md`.
