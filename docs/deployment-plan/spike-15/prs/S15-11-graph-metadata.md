# S15-11 — Evidence graphs show their metadata

**Status:** Landed in [#834](https://github.com/mendahu/provenencia/pull/834) (2026-11-14)
**Spike / slice:** Spike 15 · Slice 2 — Metadata at three levels
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D5](../design/archive/S15-D5-evidence-graph-form.md) (reviewed, [log](../design/archive/S15-D5-evidence-graph-form.review.md)), board agreed 2026-11-14
**Board:** [Claude Design — Source Detail](https://claude.ai/artifact/443NPNYmGErAmxgV1fBsFK), page *Source page*, rows "Evidence graphs" (g-values, g-values-wide, g-read-failed) and "Evidence graph form" (gf-meta-*). Frame map: brief 1a/1b → g-values/g-values-wide; 2 → gf-meta-add; 3a → gf-meta-edit; 3b → gf-meta-addrow; 4 → gf-meta-nosugg; 5 → gf-meta-discard; 6 → gf-meta-saving, gf-meta-refused, gf-meta-openfield; 7a → gf-meta-sixty; 7b → gf-meta-long; 8 → g-read-failed. **gf-meta-narrow is not built** (no one-column fallback, user 2026-11-14). Open the link in a browser; if you cannot, §6 macOS and D-9 describe every frame
**Depends on:** S15-08 (landed [#791](https://github.com/mendahu/provenencia/pull/791)), S15-36 (landed #810), S15-34 (landed [#819](https://github.com/mendahu/provenencia/pull/819)), S15-35 (landed [#824](https://github.com/mendahu/provenencia/pull/824)), S15-10 (landed [#829](https://github.com/mendahu/provenencia/pull/829)), S15-D5
**Blocks:** S15-39
**Branch:** `s15-11-graph-metadata`
**Version bump:** minor, 0.14.0 → **0.15.0** (or the next minor after `main`'s `VERSION` when you rebase): `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj` — a backward-compatible feature (the graph form saves metadata; graph rows show it) with additive proto fields old clients ignore ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`
**Context:** [map § 6.6, § 6.9](../evidence-explained-citation-map.md), working rules: "Metadata lives at three levels with one vocabulary", "One metadata board", "A board adds a field in an inline row", "Metadata saves with its owner's write", "The item is a graph field", "No engineering for two windows editing the same data"
**Planned:** 2026-11-14 against `main` @ `08d03b0`
**Review:** [`S15-11-graph-metadata.review.md`](S15-11-graph-metadata.review.md) — Fits with changes — Not ready → Ready after fixes, 1 round; no open blocker

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
| AC-1.1 | A Census Source whose type suggests Item, Line, Dwelling, Family at `graph` level; Add evidence graph | The 880pt two-column form opens: Name, Description and the four suggestions empty under "Evidence graph metadata" on the left; the checklist on the right (EG-1, EG-2, EG-7) |
| AC-1.2 | Fill Line "14" and Dwelling "112", Add | One `createEvidenceGraph` call carrying a draft with both values and the four rows' layout; the form closes; the new graph's row shows "Line 14", "Dwelling 112" with no workspace reload (EG-5, EG-8) |
| AC-1.3 | The type's suggestion read fails | No form opens; the page banner shows the error (EG-10, frame 8) |
| AC-1.4 | A Source with no type | The form opens; the board shows only Add field (frame 4) |
| AC-1.5 | A second click on Add evidence graph while the suggestion read runs | Nothing more opens (EG-10) |

**US-2.** As a researcher editing a graph, I change its values in the form and nothing saves until Save.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | A graph with Item, Line, Dwelling saved; Edit | The form opens at once with those three rows and Family suggested, from the page's values |
| AC-2.2 | Change Line to "15", add Folio "236" inline, Save | One `updateEvidenceGraph` with the draft; the row shows the new values; no workspace reload |
| AC-2.3 | Change Line, then a click outside | The kit's discard confirm; Cancel closes with no confirm and writes nothing (EG-3) |
| AC-2.4 | Save while the Add field row holds a picked field and typed text | No write; the top Callout reads "Finish the open field first: save its value or clear it." (EG-5) |
| AC-2.5 | The engine refuses Line's value | "This metadata change can't be saved." under the Line row; the form stays open with every value (EG-5) |
| AC-2.6 | Only the name changed | `updateEvidenceGraph` with `metadata: nil`; the reply's rows still replace the page's rows for that graph (D-5) |

**US-3.** As a researcher reading the Source page, I see each graph's saved values on its row.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Graphs with 0, 4 and 7 values | No column content; four rows; four rows and "+3 more" (EG-8) |
| AC-3.2 | "+3 more" | Opens the graph's edit form with its scroll target on Evidence graph metadata |
| AC-3.3 | A suggested field with no value | Not shown on the row |
| AC-3.4 | Pane at Wide | The values column is 440pt; at Regular 320pt (EG-W1) |

**US-4.** As the engine, the Source page read carries every graph's board and a graph write answers the graph's rows.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | `GetSourceWorkspace` on a Source with three graphs, one valued | `graph_metadata` has three boards in graph list order, each with its suggestions; the valued one carries its value; `metadata` and `artifact_metadata` are as before |
| AC-4.2 | `CreateEvidenceGraph` with a draft | The reply's `metadata` is the graph's board after the write |
| AC-4.3 | `UpdateEvidenceGraph` without a draft | The reply's `metadata` is the stored board, unchanged |

## 3. Scope

| In | Covered by |
| --- | --- |
| One batched board read for the whole page, with `graph_metadata` (D-1) | STEP-1, AC-4.1 |
| Rows on the graph create and update replies (D-2) | STEP-2, AC-4.2, AC-4.3 |
| Swift store and workspace: graph boards, the graph writes' rows (D-3) | STEP-3 |
| One page reader and one page apply for owner rows; the board owns its open-field rule (D-6, D-11) | STEP-4 |
| Owner-neutral read-only values view and its width; owner-neutral keys (D-7, D-8) | STEP-5 |
| The board in the graph form, both modes; two columns at 880pt; scrolling body; Add reads first (EG-1 – EG-7, EG-10) | STEP-6, STEP-7, US-1, US-2 |
| Values on each graph row (EG-8, EG-9, EG-W1) | STEP-8, US-3 |

| Out | Home |
| --- | --- |
| Needed and used marks on the graph board | S15-39 |
| Unknown and Supplied on a graph row | S15-41 |
| The type page's graph suggestion list | S15-12 |
| A one-column form for narrow windows (board frame gf-meta-narrow) | not planned (user, 2026-11-14: one breakpoint stays the app's rule) |
| A fresh board read before a form opens, for two windows editing one owner | not planned (working rule "No engineering for two windows editing the same data") |
| Closing the form when another window deletes its graph | not planned (the form reports the failed Save, as today; brief § 2.2) |
| Two columns on the other form sheets; a kit two-column FormDialog layout | [`wide-layout.md`](../../../ideas/wide-layout.md) "Two-column form sheets" |
| Metadata on the evidence graph canvas | not planned |
| Nudging toward one graph per household | map § 7 |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Page read | `api/ffi/handlers/sources.go` `GetSourceWorkspace` | Two board reads: `ownerBoardProto(c, owner)` for the Source and `artifactBoardsProto(c, artIDs)` for the Artifacts; no graph boards |
| Board batch | `api/ffi/handlers/metadata.go` `artifactBoardsProto(c, ids)` | Hard-codes `vocabkey.LevelArtifact` around `sourcemetadata.ListWorkspaces(c, owners)`, which already takes owners of mixed levels in one transaction (`listWorkspaces` → `eachLevel`) |
| One board | `api/ffi/handlers/metadata.go` `ownerBoardProto`, `metadataEntriesProto` | Used by the Artifact replies and the metadata RPCs |
| Graph writes | `api/ffi/handlers/evidence_graphs.go` `CreateEvidenceGraph`, `UpdateEvidenceGraph` | Apply a draft through `applyDraft`; replies carry the graph / effects, no rows |
| Proto | `api/proto/engine.proto` `GetSourceWorkspaceResponse` (fields 1 – 5 and 9; 6 – 8 reserved), `CreateEvidenceGraphResponse` (1, 2), `UpdateEvidenceGraphResponse` (1) | — |
| Graph list | `core/database/evidencegraphs/evidencegraphs.go` `List(c, sourceID)` | Reads the in-memory `GraphIndex`; graphs in list order |
| Swift workspace | `macos/App/Platform/GenealogyStore.swift` `CatalogSourceWorkspace.metadataRows(for:)`, `setMetadataRows(_:for:)` | `.graph` answers nil / false; `setMetadataRows` starts `guard metadataRows(for: owner) != nil`; both doc comments name "an Evidence graph" as holding no board |
| Store | `GenealogyStore.createEvidenceGraph` → `(CatalogEvidenceGraph, CatalogWriteEffects)`; `updateEvidenceGraph` → `CatalogWriteEffects` | Conformers: `GoStore.swift`, `FakeStore.swift`, and `ThrowingStore` in `macos/ProvenenciaTests/OnboardingModelTests.swift` |
| Cache patch | `macos/App/Features/Workspace/Session/CatalogLastUpdated.swift` `CatalogQueryPatch.metadataBoard()` | Patches any owner through `setMetadataRows` on keys whose Source matches the mutation's `sourceId` |
| Artifact Save | `macos/App/Features/Sources/SourceArtifactsSection.swift` `show(_:metadata:effects:)` | Sets the page's rows, then `session.apply(effects, .wroteMetadataBoard(…))` |
| Live host | `macos/App/Features/Sources/MetadataBoardHost.swift` `SourcePageMetadataHost` | `entries` reads and sets `context.workspace` rows; `didWrite` applies `.wroteMetadataBoard` |
| Row reader | `SourceArtifactsSection.copyDetails(for:)` | `context.workspace?.metadataRows(for:) ?? []` |
| Graph form | `macos/App/Features/Sources/SourceGraphFormDialog.swift` `SourceGraphFormDialogModifier` (520pt, no `scrollsBody`), `SourceGraphForm` (`PVTabPair` of Name and Description; `PVDivider`; `SourceFormLoadArea` around `checklist`; `keptLinked`) | One column |
| Graph model | `macos/App/Features/Sources/SourceGraphFormModel.swift` `SourceGraphFormModel` | `Mode.create` / `.edit(graph)`; `save()` sends `metadata: nil`, then `session.apply(effects)` |
| Opening | `macos/App/Features/Sources/SourceGraphsSection.swift` `openAdd()`, `openEdit(id:)` | Synchronous; `openEdit` starts `formLoad` (`loadKeptLinks`) |
| Graph row | `macos/App/Features/Sources/SourcePageGraphsView.swift` `SourcePageGraphRow` | `PVCard { HStack { name VStack (.accessibilityElement(children: .combine)); Spacer; actions } }` |
| Artifact row | `macos/App/Features/Sources/SourcePageArtifactRow.swift` | `textColumn.frame(maxWidth: .infinity)`, then a `VStack` holding `ArtifactCopyDetailsView` framed `maxWidth: copyDetailsWidth(widthClass)`, then actions |
| Read-only view | `macos/App/Features/Sources/ArtifactCopyDetailsView.swift` `ArtifactCopyDetailsView(rows:ref:artifactID:onMore:)` | Ids `sources.page.artifact.<id>.copyDetails…`; keys `L10n.Sources.artifactCopyDetailsMore`, `artifactCopyDetailsMoreLabel` ("%arg more copy details" of ref) |
| Open-field rule | `ArtifactSheetModel.save()` | Checks `board.hasUnconfirmedInput`, sets `L10n.Sources.artifactSheetFinishOpenField` |
| Suggestion read | `macos/App/Features/Sources/SourcePageContext.swift` `unsavedMetadataRows(level:)`, `showFailure(_:)`; `SourceArtifactsSection.openAdd()` (`isOpeningAdd` guard) | S15-10's add-mode read |
| Tests | `api/ffi/handlers/sources_test.go` `TestGetSourceWorkspace` ("artifact boards"); `metadata_test.go` `newMetadataOwners`; `evidence_graphs_test.go` `TestCreateEvidenceGraph`, `TestUpdateEvidenceGraph`, `graphFixture.createGraph`; `macos/ProvenenciaTests/SourceGraphFormModelTests.swift`; `SourcePageModelTests.swift` (graph form, `ArtifactCopyDetailsView.shown`, open-field message); `EvidenceGraphStoreTests.swift` | Green at the base |

**Precedent.** S15-33 ([`S15-33-artifact-update-saves-metadata.md`](S15-33-artifact-update-saves-metadata.md)) put `metadata` on the Artifact replies through `ownerBoardProto`; copy its handler shape. S15-10 opened add mode through `unsavedMetadataRows` with `isOpeningAdd`; copy `SourceArtifactsSection.openAdd()`. `ArtifactSheetModel` holds `host` and `board` and passes `opensAt` / `scrollTarget` / `scrollRequest` to the dialog; the graph model mirrors those names.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `GetSourceWorkspaceResponse` gains `repeated MetadataBoard graph_metadata = 10;`. `artifactBoardsProto` becomes `ownerBoardsProto(c *database.Catalog, owners []sourcemetadata.Owner) ([]*engine.MetadataBoard, error)` *(renamed; no level parameter, `Owner` carries it)*. `GetSourceWorkspace` builds one owner list, `[source] + artifacts (page order) + graphs (evidencegraphs.List order)`, calls it once, and splits by index: board 0's entries → `metadata`, the next `len(artifacts)` → `artifact_metadata`, the rest → `graph_metadata`. `ownerBoardProto` stays for single-owner replies | One read snapshot per page; S15-38's requirement merge inside `listWorkspaces` then runs once per page read (plan review M-3) | One call per level (three transactions) |
| D-2 | `CreateEvidenceGraphResponse` gains `repeated MetadataWorkspaceEntry metadata = 3;` and `UpdateEvidenceGraphResponse` `metadata = 2;`: the graph's board after the write, from `ownerBoardProto`, with or without a draft | A Save patches the page with `.wroteMetadataBoard` and never reloads the workspace, as the Artifact writes since S15-33 | Reloading the workspace on a graph Save |
| D-3 | `CatalogSourceWorkspace.graphMetadata: [String: [CatalogMetadataEntry]]` *(new)*. `metadataRows(for:)`: `.graph` answers `graphMetadata[owner.id] ?? []` (the workspace does not list graphs, so every graph id has a board, empty when the read predates it). `setMetadataRows`: the opening guard moves into the `.source` and `.artifact` cases; `.graph` sets `graphMetadata[owner.id]` and answers true. Both doc comments are rewritten per level. Which graphs the Source has stays with the graph list key | The workspace does not list graphs (`SourceGraphsSection.rows` reads `context.evidenceGraphs`); copying membership is what `GetSourceWorkspaceResponse`'s comment warns against (brief review M2-1; plan review M-5, X-8) | One `boards` map for all levels (a larger change than this PR needs) |
| D-4 | The store: `createEvidenceGraph` returns `(graph: CatalogEvidenceGraph, metadata: [CatalogMetadataEntry], effects: CatalogWriteEffects)`; `updateEvidenceGraph` returns `(metadata: [CatalogMetadataEntry], effects: CatalogWriteEffects)`. `GoStore` maps `resp.metadata`; `getSourceWorkspace` maps `resp.graphMetadata` as it maps `artifactMetadata`. `FakeStore.getSourceWorkspace` fills `graphMetadata` for the graphs of that Source in `evidenceGraphsByProject[projectDir]` from `metadataByOwner`; its graph writes answer `scriptedMetadataRows(MetadataOwner(level: .graph, id:))`. `ThrowingStore` throws | Same shape as the Artifact writes | — |
| D-5 | `SourceGraphFormModel.Mode` becomes `.create(suggestions: [CatalogMetadataEntry])` and `.edit(CatalogEvidenceGraph)`; init gains `opensAt: Section = .top`. `enum Section: Hashable { case top, metadata }` *(new)*; `private(set) var scrollTarget: Section?` (nil for `.top`) and `private(set) var scrollRequest = 0`, bumped when a Save stops with a message, as `ArtifactSheetModel.scrollToTop()`. The init builds `let host = MetadataDraftHost(entries:, fields: context.fields)` (create: the suggestions; edit: `context.metadataRows(for: graph owner)`) and `let board = MetadataBoardModel(host: host)`. `isDirty = draft != prefill || board.hasUnsavedChanges`. `save()`: if `let message = board.unconfirmedInputMessage` sets `saveError = message`, scrolls to top, writes nothing; then name and Artifact checks as today; sends `metadata: host.draft`; on a refusal `board.showRefusal(error)` answers first; on success **always** calls `context.applySavedMetadata(reply.metadata, owner:, effects:)` (create: the new graph's id), whether or not a draft was sent, then `host.markSaved()` | One board for every form; applying the reply always keeps the row current after any write (plan review X-2) | Applying only when a draft was sent (the Artifact sheet's way): a name-only Save could leave a stale row |
| D-6 | `SourcePageContext.metadataRows(for owner: MetadataOwner) -> [CatalogMetadataEntry]` *(new)*: `workspace?.metadataRows(for:) ?? []`; `SourceArtifactsSection.copyDetails(for:)` goes and its callers use it; `SourcePageMetadataHost.entries`'s getter uses it. `SourcePageContext.applySavedMetadata(_ rows:, owner:, effects:)` *(new)*: sets the page's rows, then `session.apply(effects, .wroteMetadataBoard(sourceId:owner:entries:))`; `SourceArtifactsSection.show`, `SourcePageMetadataHost.didWrite` (with its `entries`) and the graph form call it | One reader and one apply for every owner's rows (plan review M-6, M-7; brief review M-3) | A reader per section |
| D-7 | `ArtifactCopyDetailsView` becomes `MetadataDetailsColumn` *(renamed file and type)*: `init(rows:, owner: MetadataOwner, ref: String, onMore:)`; ids `sources.page.\(owner.level.rawValue).\(owner.id).details` and `.details.\(fieldID)`, `.details.more`; `static func width(_ widthClass: PVWidthClass) -> CGFloat` (320 / 440) moves from `SourcePageArtifactRow.copyDetailsWidth`. Keys `sources.page.artifactCopyDetailsMore` → `sources.page.metadataDetailsMore` ("+%lld more"); `artifactCopyDetailsMoreLabel` → `metadataDetailsMoreLabel`, plural "%arg more detail" / "%arg more details", "of %2$@" kept | One read-only view for two owners, no switch on owner kind (brief review M-2, M2-3) | A graph copy; a caller-passed label |
| D-8 | `L10n.Sources.artifactSheetFinishOpenField` → `L10n.Sources.metadataFinishOpenField` (`sources.page.metadataFinishOpenField`, same English; comment: any form that holds a draft board) | One string for one board rule | — |
| D-9 | **The form.** `SourceGraphFormDialogModifier` passes `width: 880`, `scrollsBody: true`, `scrollTarget: model?.scrollTarget.map { AnyHashable($0) }`, `scrollRequest: model.map { AnyHashable($0.scrollRequest) }`. `SourceGraphForm`: the save-error Callout full width; then `HStack(alignment: .top, spacing: PVSpacing.space8)` of two `VStack(alignment: .leading, spacing: PVSpacing.space6)`, each `.frame(maxWidth: .infinity, alignment: .topLeading)`. **Left:** `fields` (today's `PVTabPair` of Name and Description, unchanged) and the board, both inside `.disabled(model.isSaving)`; the board is `PVField(label: L10n.Sources.graphFormMetadataLabel)` *(new key, "Evidence graph metadata"; no marker, no hint)* holding `MetadataBoardView(board: model.board, placement: .form, accessibilityIdentifierPrefix: "sources.graphForm.metadata", onClear: { id in Task { _ = await model.board.requestClear(fieldID: id) } })`, with `.id(SourceGraphFormModel.Section.metadata)`. **Right:** today's `SourceFormLoadArea { checklist }` and `keptLinked`, as they are. `PVDivider()` goes. Tab order: Name, Description (the `PVTabPair`), then the board's controls, then the checklist | EG-1, EG-6, EG-7; user 2026-11-14: two columns at every width, the body may scroll when a column is too tall | A one-column fallback (user declined); a kit two-column layout for one caller (brief non-goal) |
| D-10 | **Opening.** `SourceGraphsSection.openAdd() async -> SourceGraphFormModel?` *(was sync; `@discardableResult`)* with `private(set) var isOpeningAdd` as `SourceArtifactsSection.openAdd()`: guard `form == nil, !isOpeningAdd`; read `context.unsavedMetadataRows(level: .graph)`; on a failure `context.showFailure(error)` and nil; re-check `form == nil`; open `.create(suggestions:)`. `openEdit(id:at: Section = .top)` stays synchronous and also returns when `isOpeningAdd`; it passes `opensAt`. `SourcePageGraphsView` calls `Task { await model.graphs.openAdd() }` | EG-10; the read-first precedent | A read on Edit (rule "No engineering for two windows editing the same data") |
| D-11 | `MetadataBoardModel.unconfirmedInputMessage: String?` *(new)*: `hasUnconfirmedInput ? L10n.string(L10n.Sources.metadataFinishOpenField) : nil`. `ArtifactSheetModel.save()` and the graph form read it | The board owns its Save rule; S15-39 and S15-41 change it once (plan review M-4) | The check copied into each form |
| D-12 | **Graph row.** `SourcePageGraphRow`: the name `VStack` takes `.frame(maxWidth: .infinity, alignment: .leading)` in place of the `Spacer`; then `VStack(alignment: .leading, spacing: 0) { MetadataDetailsColumn(rows: context rows for the graph, owner:, ref: graph.ref, onMore: { model.graphs.openEdit(id: graph.id, at: .metadata) }) }.frame(minWidth: 0, maxWidth: MetadataDetailsColumn.width(widthClass), alignment: .topLeading)`, reading `@Environment(\.pvWidthClass)`; then the actions. The name block keeps its `.accessibilityElement(children: .combine)`; the column is its own element after it. Rows come from `model.graphs.details(for: graph.id)`, a one-line pass to `context.metadataRows(for:)` | EG-8, EG-9, EG-W1; the Artifact row's layout | — |

**Rules this plan bends.** None. (The 960pt fallback that would have bent `docs/macos-client-patterns.md` § 9 "One breakpoint" was dropped by the user, 2026-11-14.)

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `graph_metadata = 10` | proto field | `artifact_metadata = 9` | Extends the same message, same shape |
| `metadata` on two graph replies | proto fields | `UpdateArtifactResponse.metadata` | Same field, same helper |
| `ownerBoardsProto` *(renamed)* | func | `artifactBoardsProto` | Renamed to take owners, not copied |
| `graphMetadata` | Swift field | `artifactMetadata` | A second key space behind the same accessor pair |
| `SourcePageContext.metadataRows(for:)`, `applySavedMetadata` | funcs | `SourceArtifactsSection.copyDetails(for:)`, `show` lines, `SourcePageMetadataHost` | Replace them (D-6) |
| `MetadataDetailsColumn` *(renamed)* | view | `ArtifactCopyDetailsView` | Renamed, not copied (D-7) |
| `MetadataBoardModel.unconfirmedInputMessage` | property | `ArtifactSheetModel.save()` check | Moved onto the board (D-11) |
| `SourceGraphFormModel.Section` | enum | `ArtifactSheetModel.Section` | The graph form's own sections |
| `SourceGraphsSection.details(for:)` | func | — | One-line pass to the context reader |
| `graphFormMetadataLabel` | L10n key | `artifactCopyDetailsLabel` | A different label |

**Builds on.** `MetadataDraftHost`, `MetadataBoardModel`, `MetadataBoardView` `.form`, `pvFormDialog(scrollsBody:scrollTarget:scrollRequest:)`, `CatalogQueryPatch.metadataBoard()`, `unsavedMetadataRows(level:)`, `showFailure`.
**Deletes.** `artifactBoardsProto` (renamed); the second board read in `GetSourceWorkspace`; `ArtifactCopyDetailsView` and its file (renamed); `SourcePageArtifactRow.copyDetailsWidth` (moved); `SourceArtifactsSection.copyDetails(for:)`; keys `sources.page.artifactCopyDetailsMore`, `artifactCopyDetailsMoreLabel`, `artifactSheetFinishOpenField` (renamed); the open-field check in `ArtifactSheetModel.save()` (moved); the duplicated apply lines in `SourceArtifactsSection.show` and `SourcePageMetadataHost.didWrite`; the graph form's `PVDivider`.
**Next adds.** S15-39 annotates every `MetadataWorkspaceEntry` inside `listWorkspaces`, now read once per page; the graph rows and form get it with no graph code. S15-41's marks reach `MetadataDetailsColumn` once and the board's Save rule in `MetadataBoardModel`.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| "+n more" on a graph row → edit form at its metadata | `SourceGraphsSection.openEdit(id:at:)` | Same as the pencil; a graph gone since the row drew: `ownGraph(id:)` answers nil, nothing opens |
| A graph made after the page read | `metadataRows(for:)` answers `[]`; its row shows nothing until a Save inserts its board (D-3) | T-4 |

### Scale

At 60 graphs and 60 Artifacts: the page read makes one `evidencegraphs.List` (in memory) and one `ListWorkspaces` over 121 owners in one transaction, batched per level (`sqlbatch`), one fewer transaction than today. A graph Save is one write and one patch; no reload. Opening Add is one suggestion read; Edit reads nothing.

### Edges

- **Assumptions.** `metadataBoard()` patches only keys whose Source matches the mutation's `sourceId`; D-3's unconditional graph write relies on that. `MetadataDraftHost.draft` is nil when nothing changed, so a name-only Save leaves stored values (AC-2.6, T-7). The split in D-1 relies on `ListWorkspaces` answering one list per owner in input order (its doc says so; T-1 checks owner ids).
- **Neighbors.** A graph with only empty suggestions: its row shows nothing (`MetadataDetailsColumn.shown` filters `hasValue`; T-10). A typeless Source: Add opens with no suggestions (AC-1.4).
- **Removed inputs.** A deleted graph's entry in `graphMetadata` is never read (rows are keyed by the graph list's ids, never reused); no cleanup.
- **Real data.** None — no table-driven rule.
- **Untrusted size.** Rows per owner are bounded by the project's field list; no new loop over user data.

### Schema

None — S15-08 made the tables.

### Go core

None — `api/ffi/handlers` only.

### FFI

`api/proto/engine.proto`: the three fields of D-1, D-2. Handlers `sources.go` `GetSourceWorkspace`, `evidence_graphs.go` `CreateEvidenceGraph`, `UpdateEvidenceGraph`, `metadata.go` `ownerBoardsProto`. Regenerate with `./scripts/generate-proto.sh`.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Graph form | `pvFormDialog` 880pt, `scrollsBody: true` | `SourceGraphFormDialog.swift` | D-9 |
| Two columns | `HStack` of two `VStack`s | `SourceGraphForm` | Snowflake, D-9 |
| Board | `MetadataBoardView` `.form` in `PVField` | `MetadataBoardView.swift` | D-9 |
| Checklist, kept-linked | `PVArtifactChecklist`, `PVDeleteImpactGroupStack` | unchanged | Right column |
| Graph row values | `MetadataDetailsColumn` | `SourcePageGraphsView.swift` | D-12 |
| Banner | `SourcePageContext.showFailure` | — | AC-1.3 |

Frames in words: **gf-meta-add** — the two-column form, Name and Description at the top left, the board below them with Item, Line, Dwelling, Family empty and Add field; the checklist at the right with its All row and twelve Artifacts. **gf-meta-edit / gf-meta-addrow** — the same in edit with three saved rows and Family suggested; one has the Line row in edit, the other the Add field row open on Folio. **gf-meta-sixty** — the right column's list scrolled mid-way, the body still. **gf-meta-long** — eight values with the Add field row open and the kept-linked list under the checklist; the body scrolled, both columns moving together. **g-values** — graph cards with the values column between the name block and Open / Edit / Delete.

States: no suggestions (Add field only); refused value under its row; open field at Save (top Callout); suggestion read failure (page banner). Accessibility: the row's values read as "Line, 14"; "+n more" reads "3 more details of GPH-7QD2K".

### Strings

New: `L10n.Sources.graphFormMetadataLabel` = "Evidence graph metadata". Renamed (D-7, D-8): `sources.page.artifactCopyDetailsMore` → `sources.page.metadataDetailsMore`; `sources.page.artifactCopyDetailsMoreLabel` → `sources.page.metadataDetailsMoreLabel` ("copy details" → "details"); `sources.page.artifactSheetFinishOpenField` → `sources.page.metadataFinishOpenField`.

## 7. Steps

**STEP-1 — One board read for the page, with graph boards.**
Files: `api/proto/engine.proto`, `api/ffi/handlers/metadata.go`, `api/ffi/handlers/sources.go`, `api/ffi/handlers/sources_test.go`. Skill: `add-ffi-handler`.
Do: D-1; regenerate.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/ffi/handlers/ -run 'TestGetSourceWorkspace|TestMetadata'` passes with T-1.

**STEP-2 — Graph writes answer their rows.**
Files: `api/proto/engine.proto`, `api/ffi/handlers/evidence_graphs.go`, `evidence_graphs_test.go`.
Do: D-2; regenerate.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/ffi/handlers/ -run 'TestCreateEvidenceGraph|TestUpdateEvidenceGraph'` passes with T-2, T-3.

**STEP-3 — Swift store and workspace.**
Files: `GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift`, `macos/ProvenenciaTests/OnboardingModelTests.swift` (`ThrowingStore`), `SourceGraphFormModel.swift` (new tuples only), `EvidenceGraphStoreTests.swift`, `SourcePageModelTests.swift` callers. Skill: `add-swift-test`.
Do: D-3, D-4.
Check: `xcodebuild test` passes with T-4.

**STEP-4 — One reader, one apply, the board's open-field rule.**
Files: `SourcePageContext.swift`, `SourceArtifactsSection.swift`, `MetadataBoardHost.swift`, `MetadataBoardModel.swift`, `ArtifactSheetModel.swift`.
Do: D-6, D-11.
Check: the Artifact sheet tests and Source metadata tests in `SourcePageModelTests.swift` pass unchanged.

**STEP-5 — Owner-neutral names.**
Files: `ArtifactCopyDetailsView.swift` → `MetadataDetailsColumn.swift`, `SourcePageArtifactRow.swift`, `L10n.swift`, `Localizable.xcstrings`, tests naming them. Skill: `add-localized-string`.
Do: D-7, D-8.
Check: `rg -n 'ArtifactCopyDetailsView|artifactCopyDetailsMore|artifactSheetFinishOpenField|copyDetailsWidth|copyDetails\(for' macos .agents docs/*.md` prints nothing; tests pass.

**STEP-6 — The graph model holds a draft board.**
Files: `SourceGraphFormModel.swift`, `SourceGraphFormModelTests.swift`.
Do: D-5.
Check: T-5 – T-8 pass.

**STEP-7 — Opening and drawing the form.**
Files: `SourceGraphsSection.swift`, `SourceGraphFormDialog.swift`, `SourcePageGraphsView.swift`, `L10n.swift`, `Localizable.xcstrings`, tests calling `openAdd` (`await`). Skills: `add-ui-component`, `add-localized-string`.
Do: D-9, D-10.
Check: T-9, T-11 pass; the form matches gf-meta-add, gf-meta-edit, gf-meta-addrow, gf-meta-nosugg, gf-meta-discard, gf-meta-sixty, gf-meta-long.

**STEP-8 — Values on graph rows.**
Files: `SourcePageGraphsView.swift`, `SourceGraphsSection.swift`.
Do: D-12.
Check: T-10 passes; g-values, g-values-wide.

**STEP-9 — Version.**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj` (four `MARKETING_VERSION` lines).
Check: all agree on 0.15.0.

**STEP-10 — Docs.**
Files: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py` passes; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `sources_test.go` `TestGetSourceWorkspace` case "graph boards" *(new)* | `newMetadataOwners` (one graph-level suggestion "Provider", the default graph), one more graph-level suggestion assigned with `AssignTypeField`, two more graphs from `graphFixture.createGraph`, a `SetMetadata` value on the default graph → `graph_metadata` has three boards whose owner ids follow `ListEvidenceGraphs` order, each with both suggestions, the value on the default graph's; `metadata` and `artifact_metadata` unchanged from the existing cases | AC-4.1, D-1 |
| T-2 | Go | `evidence_graphs_test.go` `TestCreateEvidenceGraph` case "answers its board" *(new)* | Create with a draft of one value → reply `metadata` holds it | AC-4.2, D-2 |
| T-3 | Go | `TestUpdateEvidenceGraph` cases "answers its board", "no draft answers the stored board" *(new)* | → reply rows | AC-4.3, D-2 |
| T-4 | Swift | `SourcePageModelTests.swift` `graphBoardsInWorkspace` *(new)* | `metadataRows(for:)` of an unknown graph → `[]`; `setMetadataRows` for it → true and stored; for an unknown Artifact → false | D-3 |
| T-5 | Swift | `SourceGraphFormModelTests.swift` `createSendsTheDraft` *(new)* | `store.suggestionsByLevel[.graph] = ["t1": four suggestions]`; open Add, fill two, save; `store.metadataWriteResults[graph owner]` scripted with the saved rows → `createEvidenceGraphMetadata.last` has two values and four layout rows; workspace `graphMetadata` holds the scripted rows; `getSourceWorkspaceCalls` unchanged | AC-1.2, D-5, D-6 |
| T-6 | Swift | `editSavesTheDraft` *(new)* | Seed `metadataByOwner` for `g-smith`; edit, change a value, save → `updateEvidenceGraphMetadata.last` non-nil; rows patched | AC-2.1, AC-2.2 |
| T-7 | Swift | `nameOnlyEditSendsNoMetadata` *(new)* | → `updateEvidenceGraphMetadata.last` is `.some(nil)`; the reply rows are applied | AC-2.6 |
| T-8 | Swift | `openFieldBlocksSave`, `refusedValueLandsOnItsRow` *(new)* | → no store call and the open-field message; the refusal on its row and the form open | AC-2.4, AC-2.5, D-11 |
| T-9 | Swift | `openAddReadsSuggestions`, `openAddFailureShowsBanner`, `secondAddWhileReadingOpensNothing` (`listTypeSuggestionsHold`), `typelessSourceOpensWithNoSuggestions` *(new)* | per name | AC-1.1, AC-1.3, AC-1.4, AC-1.5 |
| T-10 | Swift | `SourcePageModelTests.swift` `graphRowDetails` *(new)*; the `MetadataDetailsColumn.shown` tests (renamed) | 0 / 4 / 7 values and an empty suggestion → 0 / 4 / 4 + 3; suggestion hidden | AC-3.1, AC-3.3 |
| T-11 | Swift | `SourceGraphFormModelTests.swift` `moreOpensAtMetadata`, `dirtyFormAsksOnOutsideClick` *(new; the second through `PVSheetDismiss.action` as S15-34's sheet tests drive it)* | `openEdit(id:at: .metadata)` → `scrollTarget == .metadata`; a dirty form answers the discard question; Cancel closes with no store call | AC-3.2, AC-2.3 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `SourceGraphFormModelTests`, the graph and Artifact sheet tests in `SourcePageModelTests`, `EvidenceGraphStoreTests`, `OnboardingModelTests` (new conformance).

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
- [ ] Domain doc updated: `.agents/skills/add-workspace-place/SKILL.md` "Metadata values" says every Save, live or draft, reaches the cache through `SourcePageContext.applySavedMetadata` (the Artifact sheet, the graph form, the Source's live board)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. On a census Source with 12 Artifacts and a type with graph suggestions, Add evidence graph: the two-column form; the four suggestions under Description at the left, the checklist at the right. Fill Line, Dwelling, Family; Add. The new graph's row shows the three values.
2. Edit the graph, add Folio inline, change Line, click outside: the discard confirm. Keep editing, Save: the row shows the new values; the page does not flash a reload.
3. On a Source with 60 Artifacts, open the form: the checklist scrolls in its box; the body does not scroll. Add eight values: the body scrolls between the fixed title and buttons, both columns together.
4. Resize the window across 1600pt: the values column is 320pt, then 440pt (AC-3.4).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| Tests that call `openAdd` synchronously break | STEP-7 updates them to `await` |
| The renamed keys miss a caller | STEP-5's `rg` check |

**Stop and report if:**

- `ListWorkspaces` no longer answers one list per owner in input order (D-1's split).
- `CatalogQueryPatch.metadataBoard()` no longer matches on the key's Source id (D-3 would then write another Source's page).
- `pvFormDialog`'s `scrollsBody` scrolls the body when it fits (gf-meta-sixty).
- The sheet cannot be 880pt wide over a 1102pt pane (it clips or the system narrows it).
- The agreed board contradicts EG-1 – EG-10 or D-9 beyond the dropped gf-meta-narrow.

## 12. Open questions

None.

## 13. PR

**Title:** S15-11 — Evidence graphs show their metadata
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-11-graph-metadata.md`.

## Landed

- `CatalogQueryRegistryTests.metadataBoardPatchIgnoresOwnersItCannotPlace` listed a graph owner as one the page cannot place, which D-3 reverses (a graph's rows are always stored). The test now lists an unknown Artifact and a Citation owner, and `metadataBoardPatchStoresAGraphsRows` pins D-3's graph case.
- `SourcePageModel.metadataRows(for:)` is a one-line pass to `SourcePageContext.metadataRows(for:)`, so the Artifact row can read its rows now that `SourceArtifactsSection.copyDetails(for:)` is gone (the section's context is private); both rows read `SourcePageModel.metadataRows(for:)`; this supersedes D-12's `model.graphs.details(for:)` (same-pass cleanup, MNT-1). D-12's row-side wrapper and width frame now live in `MetadataDetailsColumn`, which both rows place bare (MNT-2).
- `FakeStore.nextEvidenceGraphID` (new, as `nextArtifactID`) names the next created graph, so a test scripts `metadataWriteResults` for its reply rows (T-5).
- `SourcePageContext.readSuggestionsForAdd(level:)` and `isOpeningForm` are the one read-first open for the Artifact and graph Add; a page drop is refused while it runs or any owner form is open. The page model supplies `hasOpenOwnerForm`, and `readSuggestionsForAdd` checks it before and after the read, so an edit opened during any Add read is kept and the Add opens nothing.
- The graph form's name-required stop also asks the body to scroll to the top (D-5 names only the save-error stops).
- `SourceGraphsSection.openEdit(id:at:)` returns while `SourcePageContext.isOpeningForm`, as D-10 says; `SourceGraphsSection.openAdd()` also returns nil when the Source has no Artifact (`canAdd`).
- The brief's review log moved to `design/archive/` with the brief; the links inside both files were rebased.
- The manual check (section 10) was not run by the implementer; the Swift and Go checks and `scripts/check-pr.sh` pass.
- The kept-linked callout above the graph form's Citation lists was removed after the manual check (user, 2026-11-14); each locked row's reason carries a lock.
