# S15-11 — Evidence graphs show their metadata

**Status:** Blocked — on board S15-D5
**Spike / slice:** Spike 15 · Slice 2 — Metadata at three levels
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D5](../design/S15-D5-evidence-graph-form.md) (reviewed, [log](../design/S15-D5-evidence-graph-form.review.md)), board agreed 2026-11-14
**Board:** [Claude Design — Source Detail](https://claude.ai/artifact/443NPNYmGErAmxgV1fBsFK), page *Source page*, rows "Evidence graphs" (g-values, g-values-wide, g-read-failed) and "Evidence graph form" (gf-meta-*). Frame map: brief 1a/1b → g-values/g-values-wide; 2 → gf-meta-add; 3a → gf-meta-edit; 3b → gf-meta-addrow; 4 → gf-meta-nosugg; 5 → gf-meta-discard; 6 → gf-meta-saving, gf-meta-refused, gf-meta-openfield; 7a → gf-meta-sixty; 7b → gf-meta-long; 7c → gf-meta-narrow; 8 → g-read-failed. Open the link in a browser; if you cannot, §6 macOS and D-9 describe every frame
**Depends on:** S15-08 (landed [#791](https://github.com/mendahu/provenencia/pull/791)), S15-36 (landed #810), S15-34 (landed [#819](https://github.com/mendahu/provenencia/pull/819)), S15-35 (landed [#824](https://github.com/mendahu/provenencia/pull/824)), S15-10 (landed [#829](https://github.com/mendahu/provenencia/pull/829)), S15-D5
**Blocks:** S15-39
**Branch:** `s15-11-graph-metadata`
**Version bump:** minor, 0.14.0 → **0.15.0** (or the next minor after `main`'s `VERSION` when you rebase): `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj` — a backward-compatible feature (the graph form saves metadata; graph rows show it) with additive proto fields old clients ignore ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`
**Context:** [map § 6.6, § 6.9](../evidence-explained-citation-map.md), working rules: "Metadata lives at three levels with one vocabulary", "One metadata board", "A board adds a field in an inline row", "Metadata saves with its owner's write", "The item is a graph field"
**Planned:** 2026-11-14 against `main` @ `08d03b0`
**Review:** — (not reviewed yet; reviewed after the board is agreed)

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

A researcher who files a census page as one Source makes one Evidence graph per household, and each household has its own item details: the item, line, dwelling and family. Today the graph form has nowhere to type them, though the engine stores them since S15-08. After this PR the graph form, now the app's first two-column form, holds them on the same draft metadata board the Artifact sheet uses, beside the Artifacts checklist, saved with the form's one write, and each graph row on the Source page shows them read-only, as each Artifact row shows its copy details. It makes bar 3's graph half true.

**Why now.** S15-36 (the draft board), S15-34 (the inline Add field row, the kit's scrolling body and key order) and S15-35 (the Artifact row's read-only column) have landed; S15-39 flags needed fields on every board, the graph form's included, and waits on this one.

**What stays.** The form's title, subtitle, Name, Description, Artifacts checklist with its 264pt cap, locks and kept-linked list (rearranged into two columns); the graph row's name, ref, counts, description and actions; the Artifact sheet's behavior; the Source's own Metadata section.

## 2. User stories

**US-1.** As a researcher adding an Evidence graph, I fill the type's graph fields in the form, so that the item's numbers save with the graph.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A Census Source whose type suggests Item, Line, Dwelling, Family at `graph` level; Add evidence graph on a 1102pt pane | The 880pt two-column form opens: Name, Description and the four suggestions empty under "Evidence graph metadata" on the left; the checklist on the right (EG-1, EG-2, EG-7) |
| AC-1.5 | The same on a 900pt pane | The 560pt one-column form, in EG-1's fallback order (frame 7c) |
| AC-1.2 | Fill Line "14" and Dwelling "112", Add | One `createEvidenceGraph` call carrying a draft with both values and the four rows' layout; the form closes; the new graph's row shows "Line 14", "Dwelling 112" with no workspace reload (EG-5, EG-8) |
| AC-1.3 | The type's suggestion read fails | No form opens; the page banner shows the error (EG-10, frame 8) |
| AC-1.4 | A Source with no type | The form opens; the board shows only Add field (frame 4) |

**US-2.** As a researcher editing a graph, I change its values in the form and nothing saves until Save.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | A graph with Item, Line, Dwelling saved; Edit | The form opens with those three rows and Family suggested, read from the engine before it opens (D-4) |
| AC-2.2 | Change Line to "15", add Folio "236" inline, Save | One `updateEvidenceGraph` with the draft; the row shows the new values; no workspace reload |
| AC-2.3 | Change Line, then Escape | The kit's discard confirm; Cancel closes with no confirm and writes nothing (EG-3) |
| AC-2.4 | Save while the Add field row holds a picked field and typed text | No write; the top Callout reads "Finish the open field first: save its value or clear it." (EG-5) |
| AC-2.5 | The engine refuses Line's value | "This metadata change can't be saved." under the Line row; the form stays open with every value (EG-5) |
| AC-2.6 | The board read fails when Edit is clicked | No form opens; the page banner shows the error |
| AC-2.7 | Only the name changed | `updateEvidenceGraph` with `metadata: nil` (the stored values stay) |

**US-3.** As a researcher reading the Source page, I see each graph's saved values on its row.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Graphs with 0, 4 and 7 values | No column content; four rows; four rows and "+3 more" (EG-8) |
| AC-3.2 | "+3 more" | Opens the graph's edit form (D-4 read first) scrolled to Evidence graph metadata when the body scrolls |
| AC-3.3 | A suggested field with no value | Not shown on the row |
| AC-3.4 | Pane at Wide | The values column is 440pt; at Regular 320pt (EG-W1) |

**US-4.** As the engine, the Source page read carries every graph's board and a graph write answers the graph's rows.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | `GetSourceWorkspace` on a Source with three graphs, one valued | `graph_metadata` has three boards in graph list order, each with its suggestions; the valued one carries its values |
| AC-4.2 | `CreateEvidenceGraph` with a draft | The reply's `metadata` is the graph's board after the write |
| AC-4.3 | `UpdateEvidenceGraph` without a draft | The reply's `metadata` is the stored board, unchanged |

## 3. Scope

| In | Covered by |
| --- | --- |
| `graph_metadata` on the Source page read (D-1) | STEP-1, AC-4.1 |
| Rows on the graph create and update replies (D-2) | STEP-2, AC-4.2, AC-4.3 |
| Swift store: the workspace's graph boards, the graph writes' rows, `getMetadataBoard` (D-3, D-4) | STEP-3 |
| One page helper for a Save's rows (D-6) | STEP-4 |
| Owner-neutral read-only values view and its width; the open-field message key (D-7, D-8) | STEP-5 |
| The board in the graph form, both modes; two columns at 880pt, one-column fallback; scrolling body; opening reads (EG-1 – EG-7, EG-10) | STEP-6, STEP-7, US-1, US-2 |
| Values on each graph row (EG-8, EG-9, EG-W1) | STEP-8, US-3 |

| Out | Home |
| --- | --- |
| Needed and used marks on the graph board | S15-39 |
| Unknown and Supplied on a graph row | S15-41 |
| The type page's graph suggestion list | S15-12 |
| Closing the form when another window deletes its graph | not planned (the form reports the failed Save, as today; brief § 2.2) |
| A fresh board read when the Artifact sheet opens (its page cache can be stale across windows, D-4) | [`structural-debt.md`](../../../ideas/structural-debt.md) (a row this PR adds) |
| Two columns on the other form sheets; a kit two-column FormDialog layout | [`wide-layout.md`](../../../ideas/wide-layout.md) "Two-column form sheets" |
| Metadata on the evidence graph canvas | not planned |
| Nudging toward one graph per household | map § 7 |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Page read | `api/ffi/handlers/sources.go` `GetSourceWorkspace` | Returns the Source's board, Artifacts and `ArtifactMetadata` (one board per Artifact via `artifactBoardsProto`); no graph boards |
| Board batch | `api/ffi/handlers/metadata.go` `artifactBoardsProto(c, ids)` | Hard-codes `vocabkey.LevelArtifact` around `sourcemetadata.ListWorkspaces` (batched per level) |
| One board | `api/ffi/handlers/metadata.go` `ownerBoardProto`, `GetMetadataBoard` | Exist; `GetMetadataBoard` has no Swift caller |
| Graph writes | `api/ffi/handlers/evidence_graphs.go` `CreateEvidenceGraph`, `UpdateEvidenceGraph` | Apply a draft through `applyDraft`; replies carry the graph / effects, no rows |
| Proto | `api/proto/engine.proto` `GetSourceWorkspaceResponse` (9 fields used), `CreateEvidenceGraphResponse` (1, 2), `UpdateEvidenceGraphResponse` (1) | — |
| Graph list | `core/database/evidencegraphs/evidencegraphs.go` `List(c, sourceID)` | Reads the in-memory `GraphIndex`; graphs in list order |
| Swift workspace | `macos/App/Platform/GenealogyStore.swift` `CatalogSourceWorkspace.metadataRows(for:)`, `setMetadataRows(_:for:)` | `.graph` answers nil / false |
| Store | `GenealogyStore.createEvidenceGraph` → `(CatalogEvidenceGraph, CatalogWriteEffects)`; `updateEvidenceGraph` → `CatalogWriteEffects`; no `getMetadataBoard` | `GoStore.swift`, `FakeStore.swift` implement them |
| Cache patch | `macos/App/Features/Workspace/Session/CatalogLastUpdated.swift` `CatalogQueryPatch.metadataBoard()` | Patches any owner through `setMetadataRows`; `.sourceWorkspace` declares it |
| Artifact Save | `macos/App/Features/Sources/SourceArtifactsSection.swift` `show(_:metadata:effects:)` | Sets the page's rows, then `session.apply(effects, .wroteMetadataBoard(…))` |
| Graph form | `macos/App/Features/Sources/SourceGraphFormDialog.swift` `SourceGraphFormDialogModifier` (520pt, no `scrollsBody`), `SourceGraphForm` | Name, Description, divider, checklist, kept-linked |
| Graph model | `macos/App/Features/Sources/SourceGraphFormModel.swift` `SourceGraphFormModel` | `Mode.create` / `.edit(graph)`; `save()` sends `metadata: nil`; `session.apply(effects)` |
| Opening | `macos/App/Features/Sources/SourceGraphsSection.swift` `openAdd()`, `openEdit(id:)` | Synchronous |
| Graph row | `macos/App/Features/Sources/SourcePageGraphsView.swift` `SourcePageGraphRow` | Card: name block, actions; no values |
| Read-only view | `macos/App/Features/Sources/ArtifactCopyDetailsView.swift` `ArtifactCopyDetailsView(rows:ref:artifactID:onMore:)`; width `SourcePageArtifactRow.copyDetailsWidth(_:)` | Artifact-named ids and keys `L10n.Sources.artifactCopyDetailsMore`, `artifactCopyDetailsMoreLabel` |
| Open-field copy | `L10n.Sources.artifactSheetFinishOpenField` (`sources.page.artifactSheetFinishOpenField`) | Used by `ArtifactSheetModel.save()` |
| Suggestion read | `macos/App/Features/Sources/SourcePageContext.swift` `unsavedMetadataRows(level:)`, `showFailure(_:)` | S15-10's add-mode read |
| Tests | `api/ffi/handlers/sources_test.go` `TestGetSourceWorkspace` ("artifact boards"); `evidence_graphs_test.go` `TestCreateEvidenceGraph`, `TestUpdateEvidenceGraph`; `macos/ProvenenciaTests/SourceGraphFormModelTests.swift`; `SourcePageModelTests.swift` (graph form, `ArtifactCopyDetailsView.shown`); `EvidenceGraphStoreTests.swift` | Green at the base |

**Precedent.** S15-33 ([`S15-33-artifact-update-saves-metadata.md`](S15-33-artifact-update-saves-metadata.md)) put `metadata` on the Artifact replies through `ownerBoardProto`; copy its handler shape. S15-34 / S15-10 built the Artifact sheet's model on `MetadataDraftHost` and opened add mode through `unsavedMetadataRows`; copy `ArtifactSheetModel`'s `host`, `board`, `isDirty`, `save()` checks and `SourceArtifactsSection.openAdd()`'s guard.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `GetSourceWorkspaceResponse` gains `repeated MetadataBoard graph_metadata = 10;` — one board per graph of the Source in `evidencegraphs.List(c, sourceID)` order. `artifactBoardsProto(c, ids)` becomes `ownerBoardsProto(c, level vocabkey.Level, ids [][]byte)` *(renamed)*, called with `LevelArtifact` and `LevelGraph` | Graph rows need every graph's values in one read (60 graphs at Scale); the Artifact boards ride the same read (brief review M-1) | A metadata field on the graph list read (`ListEvidenceGraphs` serves the whole project); a read per graph row |
| D-2 | `CreateEvidenceGraphResponse` gains `repeated MetadataWorkspaceEntry metadata = 3;` and `UpdateEvidenceGraphResponse` `metadata = 2;`: the graph's board after the write, from `ownerBoardProto`, with or without a draft | A Save patches the page with `.wroteMetadataBoard` and never reloads the workspace, as the Artifact writes since S15-33 (S15-33 review M-6 settled) | Reloading the workspace on a graph Save (60 Artifact and 60 graph boards per Save) |
| D-3 | `CatalogSourceWorkspace.graphMetadata: [String: [CatalogMetadataEntry]]` *(new)*. `metadataRows(for:)` answers `graphMetadata[owner.id]` for `.graph` (nil when absent); `setMetadataRows` for `.graph` always writes and answers true (a graph made after the read gets its board; the patch slot already matches the key's Source). Which graphs the Source has stays with the graph list key; the workspace holds values keyed by graph only | The workspace does not list graphs (`SourceGraphsSection.rows` reads `context.evidenceGraphs`); copying membership into it is the duplication `GetSourceWorkspaceResponse`'s comment warns against (brief review M2-1) | Checking membership against `context.evidenceGraphs` inside a value type; a graph list in the workspace |
| D-4 | Edit reads the graph's board fresh before the form opens: `GenealogyStore.getMetadataBoard(projectDir:owner:) async throws -> [CatalogMetadataEntry]` *(new)* over the existing RPC. Add reads `context.unsavedMetadataRows(level: .graph)`. `SourceGraphsSection.openAdd()` and `openEdit(id:at:)` (`at: SourceGraphFormModel.Section? = nil`, D-9) become `async`, share one `isOpening` guard (a second click while a read runs opens nothing), re-check `form == nil` after the read, and on a failure open nothing and call `context.showFailure(error)` | `sourcemetadata.Apply` deletes every value the draft leaves out, and each window has its own `WorkspaceSession` (`WorkspaceView.swift`), so a form built from a stale page cache would erase values another window saved. S15-08 D-13 built `GetMetadataBoard` for this read | Reading the page's rows (the Artifact sheet's way; its staleness goes to `structural-debt.md`, Out); a loading state inside the form |
| D-5 | `SourceGraphFormModel.Mode` becomes `.create(suggestions: [CatalogMetadataEntry])` and `.edit(CatalogEvidenceGraph, rows: [CatalogMetadataEntry])`. The model holds `let host: MetadataDraftHost` and `let board: MetadataBoardModel`, built as `ArtifactSheetModel` builds them. `isDirty = draft != prefill || board.hasUnsavedChanges`. `save()`: when `board.hasUnconfirmedInput`, sets `saveError` to the open-field message and writes nothing; sends `metadata: host.draft`; on a refusal, `board.showRefusal(error)` answers first, as in `ArtifactSheetModel.save()`; on success applies the reply rows through D-6 | One board for every form (rule "One metadata board"); the Artifact sheet is the precedent | A graph-specific board model |
| D-6 | `SourcePageContext.applySavedMetadata(_ rows: [CatalogMetadataEntry], owner: MetadataOwner, effects: CatalogWriteEffects)` *(new)*: sets the page's rows, then `session.apply(effects, .wroteMetadataBoard(sourceId:owner:entries:))`. `SourceArtifactsSection.show` calls it in place of its two lines; the graph form calls it. `MetadataBoardHost.didWrite` stays (its board owns its rows) | Two Save paths share one apply (brief review M-3) | A copy in the graph model |
| D-7 | `ArtifactCopyDetailsView` becomes `MetadataDetailsColumn` *(renamed file and type)*: `init(rows:, owner: MetadataOwner, ref: String, onMore:)`; ids `sources.page.\(owner.level.rawValue).\(owner.id).details…`; `static func width(_ widthClass: PVWidthClass) -> CGFloat` (320 / 440) moves from `SourcePageArtifactRow.copyDetailsWidth`. Keys `sources.page.artifactCopyDetailsMore` → `sources.page.metadataDetailsMore` ("+%lld more"); `artifactCopyDetailsMoreLabel` → `metadataDetailsMoreLabel`, whose plural changes from "%arg more copy detail(s)" to "%arg more detail(s)", "of %2$@" kept, so both rows read "3 more details of <ref>" (EG-9) | One read-only view for two owners, with no switch on owner kind (brief review M-2, M2-3) | A graph copy of the view; a label passed by each caller |
| D-8 | `L10n.Sources.artifactSheetFinishOpenField` → `L10n.Sources.metadataFinishOpenField` (`sources.page.metadataFinishOpenField`, same English); the comment says any form holding a board | One string for one board rule (brief review M-4) | A second key |
| D-9 | **Two columns.** `SourceGraphFormDialogModifier` measures the content it modifies (the Source page pane) with `.onGeometryChange(for: CGFloat.self) { $0.size.width }` into `@State paneWidth`, and when `model` goes from nil to a model sets `@State twoColumns = paneWidth >= 960`, kept while that model is open. Two columns: `width: 880`; `SourceGraphForm` draws the save-error Callout full width, then `HStack(alignment: .top, spacing: PVSpacing.space8)` of a left `VStack` (Name, Description, the board) and a right `VStack` (the checklist area and kept-linked list), each `.frame(maxWidth: .infinity, alignment: .topLeading)` so the two share the width equally, no divider. One column: `width: 560`, today's order with the board after Description and before `PVDivider()`. Both: `scrollsBody: true`; `scrollTarget` is `SourceGraphFormModel.Section.metadata` *(new)* when opened from "+n more", nil otherwise, and the board's `PVField` carries `.id(Section.metadata)`. The board: `PVField(label: L10n.Sources.graphFormMetadataLabel)` *(new key, "Evidence graph metadata")* holding `MetadataBoardView(board:, placement: .form, accessibilityIdentifierPrefix: "sources.graphForm.metadata", onClear:)`, clearing with no confirm as the Artifact sheet | EG-1, EG-6, EG-7, EG-8; user 2026-11-14 (two columns; the body may scroll when a column is too tall). | A kit two-column FormDialog for one caller (brief non-goal); a window-relative scroll cap (a kit change the user did not take) |
| D-10 | The graph row places `MetadataDetailsColumn` between the name block and the actions in a `VStack` framed `minWidth: 0, maxWidth: MetadataDetailsColumn.width(widthClass)`, reading `@Environment(\.pvWidthClass)`, as `SourcePageArtifactRow`. Rows: `context.workspace?.metadataRows(for: graph owner) ?? []`, exposed as `SourceGraphsSection.details(for:)` *(new)*. "+n more" calls `openEdit(id:, at: .metadata)`; the pencil calls `openEdit(id:)` (top) | EG-8, EG-W1 | — |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `graph_metadata = 10` | proto field | `artifact_metadata = 9` | Extends the same message, same shape |
| `metadata` on two graph replies | proto fields | `UpdateArtifactResponse.metadata` | Same field, same helper |
| `ownerBoardsProto` *(renamed)* | func | `artifactBoardsProto` | Renamed with a level parameter, not copied |
| `graphMetadata` | Swift field | `artifactMetadata` | A second key space; the switch keeps one accessor pair |
| `getMetadataBoard` | store method | `GetMetadataBoard` RPC (exists) | First Swift caller (D-4) |
| `applySavedMetadata` | func | `SourceArtifactsSection.show` lines | Extracted (D-6) |
| `MetadataDetailsColumn` *(renamed)* | view | `ArtifactCopyDetailsView` | Renamed, not copied (D-7) |
| `SourceGraphsSection.details(for:)` | func | `SourceArtifactsSection.copyDetails(for:)` | The graph section's own reader, same one line |
| `graphFormMetadataLabel` | L10n key | `artifactCopyDetailsLabel` ("Artifact metadata") | A different label |

**Builds on.** `MetadataDraftHost`, `MetadataBoardModel`, `MetadataBoardView` `.form`, `pvFormDialog(scrollsBody:)`, `CatalogQueryPatch.metadataBoard()`, `unsavedMetadataRows(level:)`, `showFailure`.
**Deletes.** `artifactBoardsProto` (renamed); `ArtifactCopyDetailsView` and its file (renamed); `SourcePageArtifactRow.copyDetailsWidth` (moved); keys `sources.page.artifactCopyDetailsMore`, `artifactCopyDetailsMoreLabel`, `artifactSheetFinishOpenField` (renamed); the two duplicated lines in `SourceArtifactsSection.show`.
**Next adds.** S15-39 annotates every `MetadataWorkspaceEntry`; the graph rows and form get it through the same reads with no graph code. S15-41's marks reach `MetadataDetailsColumn` once.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| "+n more" on a graph row → edit form | `SourceGraphsSection.openEdit(id:)` | Same as the pencil; a graph gone since the row drew: `ownGraph(id:)` answers nil, nothing opens |
| A graph made after the page read | `CatalogSourceWorkspace.metadataRows(for:)` nil → row shows nothing; its Save inserts the board (D-3) | AC-1.2 |
| A graph deleted while its edit read runs | `openEdit` re-checks `ownGraph(id:)` after the read and opens nothing | T-9 |

### Scale

At 60 graphs and 60 Artifacts: the page read adds one `evidencegraphs.List` (in memory) and one batched `ListWorkspaces` over 60 graph owners (one query set per level, `sqlbatch`). A graph Save is one write and one patch; no reload. Opening the form is one RPC for one owner.

### Edges

- **Assumptions.** `metadataBoard()` patches only keys whose Source matches the mutation's `sourceId`; D-3's unconditional write relies on that. `MetadataDraftHost.draft` is nil when nothing changed, so a name-only Save leaves stored values (AC-2.7, T-7).
- **Neighbors.** A graph with only empty suggestions: its row shows nothing (`MetadataDetailsColumn.shown` filters `hasValue`; T-10). A typeless Source: Add opens with no suggestions (AC-1.4).
- **Removed inputs.** A deleted graph's stale entry in `graphMetadata` is never read (rows are keyed by the graph list); no cleanup.
- **Real data.** None — no table-driven rule.
- **Untrusted size.** Rows per graph are bounded by the project's field list; no new loop over user data.

### Schema

None — S15-08 made the tables.

### Go core

None — `api/ffi/handlers` only.

### FFI

`api/proto/engine.proto`: the three fields of D-1, D-2. Handlers `sources.go` `GetSourceWorkspace`, `evidence_graphs.go` `CreateEvidenceGraph`, `UpdateEvidenceGraph`, `metadata.go` `ownerBoardsProto`. Regenerate with `./scripts/generate-proto.sh`.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Graph form | `pvFormDialog` 880pt two columns (560pt one column), `scrollsBody: true` | `SourceGraphFormDialog.swift` | D-9 |
| Board | `MetadataBoardView` `.form` in `PVField` | `MetadataBoardView.swift` | D-9 |
| Checklist | `PVArtifactChecklist` | unchanged | 264pt cap |
| Graph row values | `MetadataDetailsColumn` | `SourcePageGraphsView.swift` | D-10 |
| Banner | `SourcePageContext.showFailure` | — | AC-1.3, AC-2.6 |

States: no suggestions (Add field only); refused value under its row; open field at Save (top Callout); read failure on open (page banner). Accessibility: the row's values read as "Line, 14"; "+n more" reads "3 more details of GPH-7QD2K".

### Strings

New: `L10n.Sources.graphFormMetadataLabel` = "Evidence graph metadata". Renamed (D-7, D-8): `sources.page.artifactCopyDetailsMore` → `sources.page.metadataDetailsMore`; `sources.page.artifactCopyDetailsMoreLabel` → `sources.page.metadataDetailsMoreLabel`; `sources.page.artifactSheetFinishOpenField` → `sources.page.metadataFinishOpenField`. No copy names an old scope.

## 7. Steps

**STEP-1 — The page read carries graph boards.**
Files: `api/proto/engine.proto`, `api/ffi/handlers/metadata.go`, `api/ffi/handlers/sources.go`, `api/ffi/handlers/sources_test.go`. Skill: `add-ffi-handler`.
Do: D-1; regenerate.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/ffi/handlers/ -run 'TestGetSourceWorkspace'` passes with T-1.

**STEP-2 — Graph writes answer their rows.**
Files: `api/proto/engine.proto`, `api/ffi/handlers/evidence_graphs.go`, `evidence_graphs_test.go`.
Do: D-2; regenerate.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/ffi/handlers/ -run 'TestCreateEvidenceGraph|TestUpdateEvidenceGraph'` passes with T-2, T-3.

**STEP-3 — Swift store.**
Files: `GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift` (graph boards from `metadataByOwner` in `getSourceWorkspace`; `getMetadataBoard` with a `getMetadataBoardError` hook; graph writes answer `scriptedMetadataRows`), `SourceGraphFormModel.swift` and tests updated for the new tuples. Skill: `add-swift-test`.
Do: D-3, D-4's store method; createEvidenceGraph → `(graph:, metadata:, effects:)`, updateEvidenceGraph → `(metadata:, effects:)`.
Check: `xcodebuild test` passes with T-4.

**STEP-4 — One apply for a Save's rows.**
Files: `SourcePageContext.swift`, `SourceArtifactsSection.swift`.
Do: D-6.
Check: Artifact sheet tests in `SourcePageModelTests.swift` pass unchanged.

**STEP-5 — Owner-neutral names.**
Files: `ArtifactCopyDetailsView.swift` → `MetadataDetailsColumn.swift`, `SourcePageArtifactRow.swift`, `ArtifactSheetModel.swift`, `L10n.swift`, `Localizable.xcstrings`, tests naming them. Skill: `add-localized-string`.
Do: D-7, D-8.
Check: `rg -n 'ArtifactCopyDetailsView|artifactCopyDetailsMore|artifactSheetFinishOpenField|copyDetailsWidth' macos .agents docs/*.md` prints nothing; tests pass.

**STEP-6 — The graph model holds a draft board.**
Files: `SourceGraphFormModel.swift`, `SourceGraphFormModelTests.swift`.
Do: D-5.
Check: T-5 – T-8 pass.

**STEP-7 — Opening and drawing the form.**
Files: `SourceGraphsSection.swift`, `SourceGraphFormDialog.swift`, `SourcePageGraphsView.swift` (call sites in `Task {}`), `L10n.swift`, `Localizable.xcstrings`, tests calling `openAdd` / `openEdit` (`await`). Skills: `add-ui-component`, `add-localized-string`.
Do: D-4's opening, D-9.
Check: T-9 and T-11 pass; the form matches frames 2, 3a, 3b, 4, 5, 7a – 7c.

**STEP-8 — Values on graph rows.**
Files: `SourcePageGraphsView.swift`, `SourceGraphsSection.swift`.
Do: D-10.
Check: T-10 passes; frames 1a, 1b.

**STEP-9 — Version.**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj`.
Check: the three agree on 0.15.0.

**STEP-10 — Docs.**
Files: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py` passes; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `sources_test.go` `TestGetSourceWorkspace` case "graph boards" *(new)* | Three graphs, one with a value, type with two graph suggestions → three boards in list order, owner ids match, suggestions on each, the value on one | AC-4.1, D-1 |
| T-2 | Go | `evidence_graphs_test.go` `TestCreateEvidenceGraph` case "answers its board" *(new)* | Create with a draft of one value → reply `metadata` holds it and the suggestions | AC-4.2, D-2 |
| T-3 | Go | `TestUpdateEvidenceGraph` cases "answers its board", "no draft answers the stored board" *(new)* | → reply rows | AC-4.3, D-2 |
| T-4 | Swift | `SourcePageModelTests.swift` `graphBoardPatchesWorkspace` *(new)* | `setMetadataRows` for a graph absent from `graphMetadata` → true and stored; `metadataRows` for an unknown graph → nil | D-3 |
| T-5 | Swift | `SourceGraphFormModelTests.swift` `createSendsTheDraft` *(new)* | Add with four suggestions, fill two, save → `createEvidenceGraphMetadata.last` has two values and four layout rows; workspace `graphMetadata` holds the reply rows; `getSourceWorkspaceCalls` unchanged | AC-1.2, D-5, D-6 |
| T-6 | Swift | `editSavesTheDraft` *(new)* | Edit, change a value, save → `updateEvidenceGraphMetadata.last` non-nil; rows patched | AC-2.2 |
| T-7 | Swift | `nameOnlyEditSendsNoMetadata` *(new)* | → `updateEvidenceGraphMetadata.last == nil` (as `Optional<CatalogMetadataDraft>.none`) | AC-2.7 |
| T-8 | Swift | `openFieldBlocksSave`, `refusedValueLandsOnItsRow` *(new)* | → no store call and the open-field message; the refusal on the board row and the form open | AC-2.4, AC-2.5 |
| T-9 | Swift | `openAddReadsSuggestions`, `openEditReadsTheBoard`, `openFailureShowsBanner`, `secondClickWhileOpeningOpensNothing`, `graphGoneDuringReadOpensNothing` *(new)* | per name | AC-1.1, AC-1.3, AC-2.1, AC-2.6, D-4 |
| T-11 | Swift | `SourceGraphFormModelTests.swift` `typelessSourceOpensWithNoSuggestions`, `escapeAsksCancelDoesNot` *(new; the second through `PVSheetDismiss.action` and the dialog's cancel path as S15-34's sheet tests drive them)*, `moreOpensAtMetadata` *(new)* | → empty board; dirty Escape answers the discard question and Cancel closes with no store call; `openEdit(id:at: .metadata)` sets the form's scroll target | AC-1.4, AC-2.3, AC-3.2 |
| T-10 | Swift | `SourcePageModelTests.swift` `graphRowDetails` *(new)*; `MetadataDetailsColumn.shown` tests (renamed) | 0 / 4 / 7 values and an empty suggestion → shown counts 0 / 4 / 4+3; suggestion hidden | AC-3.1, AC-3.3 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `SourceGraphFormModelTests`, the graph tests in `SourcePageModelTests`, `EvidenceGraphStoreTests` (new tuples), the Artifact sheet tests (renamed keys).

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
- [ ] Domain doc updated: `.agents/skills/add-workspace-place/SKILL.md` "Metadata values" names the graph form's Save beside the Artifact sheet's, through `SourcePageContext.applySavedMetadata`
- [ ] `docs/ideas/structural-debt.md`: a row for the Artifact sheet's page-cache rows (D-4)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. On a census Source with 12 Artifacts and a type with graph suggestions (add them on the Source type page's data or through `sourcevocab` test data), Add evidence graph: the four suggestions show after Description; fill Line, Dwelling, Family; Add. The new graph's row shows the three values.
2. Edit the graph, add Folio inline, change Line, Escape: the discard confirm. Keep editing, Save: the row shows the new values; the page does not flash a reload.
3. On a Source with 60 Artifacts, open the form: the checklist scrolls in its box; the body does not scroll. Add eight values: the body scrolls between the fixed title and buttons.
4. Resize the window across 1600pt: the values column is 320pt, then 440pt (AC-3.4).
5. Narrow the window so the pane is under 960pt and open the form: one 560pt column (AC-1.5).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| Tests that call `openEdit` synchronously break | STEP-7 updates them to `await` |
| The renamed keys miss a caller | STEP-5's `rg` check |

**Stop and report if:**

- `GetMetadataBoard` no longer exists or answers something other than one owner's board.
- `CatalogQueryPatch.metadataBoard()` no longer matches on the key's Source id (D-3 would then write another Source's page).
- `pvFormDialog`'s `scrollsBody` scrolls the body when it fits (frame 7a).
- The agreed board contradicts EG-1 – EG-10 or D-9.
- The sheet cannot be 880pt wide over a 1102pt pane (it clips or the system narrows it).

## 12. Open questions

None.

## 13. PR

**Title:** S15-11 — Evidence graphs show their metadata
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-11-graph-metadata.md`.
