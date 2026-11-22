# S15-25 — Move from an Artifact or a graph

**Status:** Planned
**Spike / slice:** Spike 15 · Slice 7 — Move
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D10](../design/S15-D10-move-confirm.md), board agreed 2026-11-22. S15-D1 SD-14 and S15-D14 SA-5 had placed Move in a menu; S15-D10's board replaces that with a button
**Board:** [agreed 2026-11-22](https://claude.ai/artifact/443NPNYmGErAmxgV1fBsFK): page *Move*, rows "Move: the buttons" (`mv-art-menu`, `mv-graph-menu`, each with a Wide frame), "Move dialog" (`mv-open` … `mv-failed`) and "After the move" (`mv-after`, `mv-after-wide`); decisions panel "S15-D10". Read it with the Artifact tool's `read` on that link, `path` "project/Source.dc.html" (search `S15-D10` and `mv-`). Board decision (user, 2026-11-22): **no right-click menu** on Artifact rows or graph cards; Move is a visible icon button, and the Artifact row's existing menu goes
**Depends on:** S15-24 (landed [#935](https://github.com/Jake-Robins-Studios/provenencia/pull/935)), S15-35 (landed [#824](https://github.com/Jake-Robins-Studios/provenencia/pull/824)), S16-61 (landed [#886](https://github.com/Jake-Robins-Studios/provenencia/pull/886)), S15-D10, S15-D1, S15-D14
**Blocks:** —
**Branch:** `s15-25-move-from-artifact-or-graph`
**Version bump:** minor, 0.32.0 → **0.33.0** (if `main`'s `VERSION` is no longer 0.32.0 when you rebase, the next minor after it): a new feature in the app ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-audit-scope`](../../../../.agents/skills/add-audit-scope/SKILL.md) (the effects registry's `Reads`), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md), [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md) (§ 6, applying a write's effects), [`add-workspace-location`](../../../../.agents/skills/add-workspace-location/SKILL.md) (landing goes through `navigation.go(to:)`)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests), `.cursor/rules/ffi-handlers.mdc`, `.cursor/rules/macos-l10n.mdc`, `.cursor/rules/versioning.mdc`
**Context:** [`docs/macos-client-patterns.md`](../../../macos-client-patterns.md) (rule 2: writes apply their effects; `LatestCall`), [`docs/catalog-caches.md`](../../../catalog-caches.md), [`core/database/effects/README.md`](../../../../core/database/effects/README.md) (adding a keyed read); working rules "A move is the whole bundle", "One window; nothing is built for a second", "An Artifact is added and edited in one sheet" ([`../deployment-plan.md`](../deployment-plan.md#working-rules)); [`../move-artifact-between-sources.md`](../move-artifact-between-sources.md) ("Which graphs move", "Side effects to name in the confirm", "Engine notes"); the landed plan [`S15-24-move-bundle.md`](S15-24-move-bundle.md) (§ 6 FFI, D-11, D-12, D-13; its Landed note); [`S15-35-artifact-list-rows.md`](S15-35-artifact-list-rows.md) D-6, D-13 (the row's action enum and `verbatimTitle`, both left for this PR)
**Planned:** 2026-11-22 against `main` @ `8d74bd8` (the S15-D10 board copied in)
**Review:** [`S15-25-move-from-artifact-or-graph.review.md`](S15-25-move-from-artifact-or-graph.review.md) — round 1: Reshape / Not ready, every finding answered; round 2 after the board

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

A researcher can re-file an Artifact, or an Evidence graph, under another Source from the Source page. A **Move to another Source** button on each Artifact row and each graph card opens a dialog that reads the bundle (everything that must move with it), asks for the target Source, names the side effects (credibility, a Source left with no Artifacts or no graph), and moves it in one write. The app then opens the target Source's page and a Toast says what moved. This is the app half of bar 8 ("An Artifact moves with its graphs"); S15-24 built the engine.

Two engine-side additions ride with it (user, 2026-11-21). (1) A narrow keyed read, `source_artifacts`, that the engine reports for a Source only when an Artifact joins or leaves it (create, delete, a move), which the Source page's cache follows; so the move, and today's Artifact create and delete, need no hand-written cache code, and every field edit keeps patching the page in place. (2) The preflight sends the credibility grade labels, including the grade the moved records will be weighed as, so the engine's "not assessed weighs as Standard" rule is not copied into Swift. A third fix rides too: a history entry for a moved graph's canvas, composer or Promote is corrected to the graph's new Source when shown.

**Why now.** The engine's `GetSourceMoveImpact` and `MoveToSource` landed in S15-24 (#935) with no caller; the Artifact row has a menu with a slot for Move (S15-35); S16-61 removed the second-window paths, so the move needs no "the Source vanished meanwhile" handling.

**What stays.** The rows' and cards' visible buttons, the Artifact sheet and the graph form (no Move in either), the canvas's drawing, `MoveToSource` and the bundle rules. Every Source page edit that patches the page in place today (title, date, type, metadata, an Artifact's label or file) keeps patching it, with no extra reload. No undo.

## 2. User stories

**US-1.** As a researcher, on the Source page I see a Move button on each Artifact row and each Evidence graph card, so I can re-file it from where I see it.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Source S1's Artifact "Sheet 14 (image 2)" (an image that is not the cover) | Its row's buttons, in order: Set cover, Edit (pencil), Move (folder-input glyph), Delete (red trash). Right-clicking the row opens nothing |
| AC-1.2 | S1's cover Artifact "Sheet 14 (image 1)" | Set cover's space is kept and hidden, then Edit, Move, Delete, so the buttons line up with other rows |
| AC-1.3 | S1's graph "Hale household, dwelling 113" | Its card's buttons: Open, Edit, Move, Delete. Right-clicking the card opens nothing |
| AC-1.4 | S1's graph "Default", with no Artifacts | Open is disabled with its tooltip as today; Move is enabled |
| AC-1.5 | VoiceOver on the two Move buttons | "Move Sheet 14 (image 2) to another Source"; "Move Hale household, dwelling 113 to another Source"; each also its tooltip |

**US-2.** As a researcher, when the Move dialog opens, I see everything that moves together and can pick where it goes, so nothing moves that I did not see.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | S1: graph G1 "Hale household" links A1 "Sheet 14 (image 1)" and A2 "Sheet 14 (image 2)"; G2 "Robins household" links A2; A3 "Sheet 20" and graph "Default" link nothing else. Move on A1 | The dialog opens at once, titled "Move to another Source", subtitle "Sheet 14 (image 1) · ART-7QK2M"; the bundle area shows the load area while `getSourceMoveImpact(seed: .artifact(A1), target: nil)` answers, then "Moves together", the line "A graph moves with all its Artifacts, so these move together.", Artifacts A1, A2 (the seed first, then the reply's order), graphs G1, G2 each with its count line; no Callout; Move disabled |
| AC-2.1b | AC-2.1's Source; Move on A2 | Artifacts A2, then A1 (the seed first in its group, the rest in the reply's order); graphs G1, G2 |
| AC-2.1c | A Source whose only Artifact A9 is linked to its only graph G9; Move on A9 | One Artifact row and one graph row, separated by a hairline; no "why" line (it shows only when more than one Artifact moves); both left-behind Callouts |
| AC-2.2 | Move on A3, which is in no graph | One Artifact row, no graph group, no "why" line |
| AC-2.3 | Move on the "Default" graph, which links no Artifact | One graph row, no Artifact group, no "why" line |
| AC-2.4 | The reply has `leaves_source_empty` true and `leaves_no_graph` true | Both neutral Callouts show, naming S1's title, before any target is picked |
| AC-2.5 | The project's Sources: S1 (current), S2 updated today, S3 updated last week | The "Move to" ComboBox offers S2 then S3 (most recently changed first), each title with its ref as subtext; S1 is not offered; typing "ED 2" keeps options whose title or ref contains it |
| AC-2.6 | The project holds only S1 | The neutral "There is no other Source to move to…" Callout replaces the field; the bundle still loads; Move disabled |
| AC-2.7 | The preflight fails | The kit's load-area failure "What moves could not be read." with Read again; Read again calls the preflight again; Move disabled |

**US-3.** As a researcher, when I pick a target, the dialog tells me if the move changes how the records are weighed, so I am not surprised by re-ranked conclusions.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | AC-2.1's dialog; pick S2 | The preflight is called again with target S2; the bundle stays drawn; Move stays disabled until it answers, then is enabled |
| AC-3.2 | S1 assessed `low_trust` ("Low trust"), S2 not assessed; pick S2 | The engine's reply: `source_credibility_label` "Low trust", `target_credibility_label` "", `weighed_as_label` "Standard", `credibility_differs` true. The warning Callout "Credibility changes" names "Low trust" for S1, "not assessed" for S2 and "weighed as Standard" |
| AC-3.3 | `credibility_differs` false | No credibility Callout |
| AC-3.4 | Pick S2, then S3 before S2's reply arrives; S2's reply arrives after S3's | The S2 reply is dropped; the note and Move follow S3's reply only |
| AC-3.5 | The bundle is drawn; pick S2 and its read fails | The load-area failure replaces the bundle; Move dims; Read again reads with target S2 and, on success, draws the bundle and the note. Clearing the ComboBox afterwards hides the note and dims Move with no read |

**US-4.** As a researcher, when I press Move, the bundle moves and I land on the target Source, so I can carry on filing there.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | AC-3.1's dialog with S2's reply in; press Move | `moveToSource(seed: .artifact(A1), target: S2)` is called once; Move shows running and the dialog cannot close until it answers |
| AC-4.2 | The move succeeds with 2 Artifacts and 2 graphs | The dialog closes; the app goes to S2's Source page (a new history entry; Back returns to S1); the workspace notice Toast reads "Moved to “{S2 title}”" / "2 Artifacts and 2 graphs", success tone |
| AC-4.3 | A move of 1 Artifact in no graph; of 1 graph with no Artifacts | Toast bodies "1 Artifact" and "1 graph" |
| AC-4.4 | After AC-4.2 | The move's effects report `source_artifacts` [S1, S2]; they are applied once with `apply(_:leavingPage:)` and no mutation: S1's cached workspace is stale (not reloaded while leaving), S2's is reloaded when its page shows; going Back to S1 shows neither A1 nor A2 nor G1 nor G2; S2's page lists them |
| AC-4.5 | The move fails (any error) | The dialog stays open with the pick and the bundle; a danger Callout "Couldn’t move" / "Nothing was moved. {message}" at the top of the body; Move can be pressed again; no navigation, no Toast |

**US-5.** As a researcher, when an Artifact joins or leaves a Source (made, deleted or moved), the Source's page shows it without the page reloading on every other edit.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-5.1 | Engine: create an Artifact on S1; delete it; move A1 from S1 to S2; update A1's label; attach a file to A1 | `WriteEffects.reads` has `source_artifacts` [S1]; [S1]; [S1, S2]; none; none |
| AC-5.2 | The S1 page is on screen; a write's effects report `source_artifacts` [S1] | The page's `sourceWorkspace` key reloads; with S1 hidden it is marked stale. A write that reports only `source_records` [S1] (a title edit) neither reloads nor stales it |
| AC-5.3 | Delete A3 from S1's page | The row leaves and the cover and "has Artifact" follow from the reload; `SourcePageModel` no longer removes the row by hand or calls `refreshCoverFromStore()` |
| AC-5.4 | Add a fileless Artifact in the sheet | The page lists it through the reload; `refreshCoverFromStore()` runs only after a file ingest |

**US-6.** As a researcher, when I go Back to a graph I had open before moving it, it opens under its new Source.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-6.1 | History holds the canvas of G1 with `sourceId` S1; G1 is moved to S2; Back to that entry | The entry is rewritten in place to `sourceId` S2 (no new history entry); the canvas's breadcrumb, Source reads and composer links name S2 |
| AC-6.2 | The same for a citation composer or Promote entry of G1 | Rewritten to S2 the same way |
| AC-6.3 | A graph location whose `sourceId` matches the graph row, or whose graph is not in the cached list | Unchanged |

## 3. Scope

| In | Covered by |
| --- | --- |
| A Move icon button on the Artifact row; the row's right-click menu removed (MV-1) | STEP-6, AC-1.1, AC-1.2, AC-1.5 |
| A Move icon button on the graph card (MV-2) | STEP-7, AC-1.3, AC-1.4, AC-1.5 |
| Engine: the `source_artifacts` read; the preflight's three credibility labels (proto fields 10 – 12) | STEP-1, AC-5.1, AC-3.2 |
| Store: `getSourceMoveImpact`, `moveToSource` on `GenealogyStore`, `GoStore`, `FakeStore`; their Swift types | STEP-2 |
| The Source page cache follows `source_artifacts`; Artifact create and delete drop their hand-written cache code | STEP-3, US-5 |
| `SourceMoveModel`: preflight on open and on pick, stale-reply drop, targets, notes, move, effects, Toast (MV-3 – MV-13) | STEP-4, STEP-5, US-2, US-3, US-4 |
| The dialog view on the Source page (MV-3 – MV-13, MV-W1) | STEP-8 |
| A graph place's history entry follows its graph's Source | STEP-9, US-6 |
| Landing on the target page with the notice Toast (MV-14) | STEP-5, STEP-8, AC-4.2 |
| Copy (L10n keys and String Catalog) | each step that shows it; checked in STEP-10 |
| Version, docs | STEP-10, STEP-11 |

| Out | Home |
| --- | --- |
| Undo; Merge Sources; Move to a new Source | not planned (rule "Refused in this spike") |
| Move from the Artifact sheet, the graph form, the canvas, the Sources list, the Person page | not planned (S15-D10 § 2.1; the map scope names rows and graphs on the Source page) |
| Scrolling the target page to the moved Artifact | not planned (user, 2026-11-21: land at the page's top) |
| A target-specific message when the target Source is deleted while the dialog is open (S15-24 ship log UX-1) | not planned (user, 2026-11-21: only a second window can do it; rule "One window") |
| Mapping `sourcemove.*` into `EngineErrorCode` and its row in `api/ffi/swift_vocabulary_test.go` (S15-24 Out named this PR) | not planned (D-9: no branch reads them; the generic message shows) |
| A note about the old Source's cover reverting, about metadata, or about a reification Subject | not planned (S15-D10 § 2.1; `move-artifact-between-sources.md` names two side effects) |
| A right-click menu on Artifact rows or graph cards | not planned (board, user 2026-11-22: every action is a visible button; a menu may come back if rows get cramped) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Artifact row | `macos/App/Features/Sources/SourcePageArtifactRow.swift` `ArtifactRowAction` (`edit, setCover, delete`; `menuActions(canSetCover:)`, `title`, `idSuffix`), `SourcePageArtifactRow.perform(_:)`, `actions(canSetCover:)` (Set cover ghost button kept in place when hidden, pencil, trash), `.pvRightClickMenu(verbatimTitle: art.ref, …)` | A right-click menu mirrors the buttons through `ArtifactRowAction`; no Move |
| Graph card | `macos/App/Features/Sources/SourcePageGraphsView.swift` private `SourcePageGraphRow` | A `PVCard` with Open (`navigation.go(to: location)`, disabled when `model.graphs.location(for:)` is nil), pencil (`model.graphs.openEdit(id:)`), trash (`model.askDeleteGraph(id:)`); no Move |
| Kit menu and icons | `macos/App/DesignSystem/Components/ContextMenu/PVActionMenu.swift` `pvRightClickMenu(verbatimTitle:accessibilityIdentifier:items:)` (line 72), `PVContextMenu.swift` `PVContextMenuPanel.init(verbatimTitle:…)` (line 132), both added by S15-35 D-13 for the Artifact row and used nowhere else; `macos/App/DesignSystem/README.md` ContextMenu row names them; `macos/App/DesignSystem/Components/Icon/PVIcon.swift` `PVSymbol` (custom `pv.image.up` drawn in `PVIcon`), `macos/ProvenenciaTests/PVSymbolTests.swift` (every case resolves) | No folder-input symbol |
| Page model | `macos/App/Features/Sources/SourcePageModel.swift` `SourcePageModel` (`copying: SourceCopyModel?`, `openCopy()`, `source`, `graphs.ownGraph(id:)`, `artifacts.items`), `SourcePageContext` (`sourceID`, `projectDir`, `userID`, `store`, `session`, `sourceTypeIconKey`) | Hosts Copy Source as an optional model; nothing for Move |
| Page view | `macos/App/Features/Sources/SourcePageView.swift` `SourcePageContent` | Chains `.sourceCopyDialog($model.copying)`, `.sourceGraphFormDialog`, `.artifactSheet`, … |
| Copy Source (the precedent) | `macos/App/Features/Sources/SourceCopyModel.swift` `SourceCopyModel`; `SourceCopyDialog.swift` `View.sourceCopyDialog(_:)`, `SourceCopyDialogModifier` | `pvFormDialog(item:…)` whose `onConfirm` awaits the write, then `navigation.go(to: SourcesListNavigation.pageLocation(for:))`; `PVFormLoadArea` for its read; `copyError` Callout at the top |
| Source picker (the precedent) | `macos/App/Features/SourceTypes/SourceTypeFormatsSection.swift` `SourceTypeFormatsPreviewPicker`; `SourceTypeFormatsModel.previewSources`, `sourcesAreRead` | `PVComboBox` over `SourcesModel.sourcesListKey(for:)` rows, `PVComboBoxOption(value: id, label: title, subtext: ref)`, sorted by `SourcesModel.updatedOrder`; hidden while the list is unread |
| Store | `macos/App/Platform/GenealogyStore.swift` protocol; `GoStore.swift` `getEvidenceGraphUnlinkImpact`, `copySource`, private `mapArtifact`, `mapEvidenceGraph`, `mapEvidenceGraphProgress`, `mapWriteEffects`; `FakeStore.swift` `getEvidenceGraphUnlinkImpact` (`…Calls`, `…Error`, scripted `unlinkImpactBlocks`) | No move methods. `CoreMethod.getSourceMoveImpact` and `.moveToSource` exist in `macos/App/Platform/Generated/engine.pb.swift` (S15-24) |
| Effects reads | `core/database/effects/registry.go` `Read`, `KeyTable`, `Reads`, entry `"artifacts"` (`Reads: {ReadSourceRecords, field("source_id")}`); `path.go` `onField`, `field`; `reads_test.go` `TestReadsDeclare`; `core/database/artifacts/artifacts.go` `Create` (its `Created` change carries `source_id`), `Delete` (`Deleted` carries `source_id`), `Update` (`Updated` carries only `file_id`, `label`, `description` when they change); Swift `CatalogRead` in `macos/App/Features/Workspace/Session/CatalogMutation.swift`, parity row "catalog reads" in `api/ffi/swift_vocabulary_test.go` (`want: effects.Reads`) | No read means "a Source's Artifacts changed": `source_records` fires on every Source, Artifact and credibility write |
| Preflight (Go) | `core/database/sourcemove/sourcemove.go` `Report`, `Impact`; `api/ffi/handlers/source_move.go`; `core/database/sourcecredibilitygrades` `List(c)`, `Grade.Label`, `DefaultKey` | `Report` carries the two grade keys and `CredibilityDiffers`, no labels |
| Wire | `api/proto/engine.proto` `GetSourceMoveImpactRequest` (`artifact_id`, `graph_id`, `target_source_id`), `GetSourceMoveImpactResponse` (`source_id`, `artifacts`, `graphs`, `progress`, `source_credibility_key`, `target_credibility_key`, `credibility_differs`, `leaves_source_empty`, `leaves_no_graph`), `MoveToSourceRequest` (`user_id`, `artifact_id`, `graph_id`, `target_source_id`), `MoveToSourceResponse` (`artifact_ids`, `graph_ids`, `default_graph_id`, `effects`) | Landed in S15-24; this PR adds three response fields |
| Source workspace cache | `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift` `.sourceWorkspace`; `CatalogQueryRefresh.applyHiddenPolicy(followsOwnId:)` (`CatalogLastUpdated.swift`), used by `.evidenceGraph` | Follows mutations only (`.mutatedSourceWorkspace(sourceId:)`); no `refreshes`. The Artifact delete (`SourcePageModel.confirmResourceDelete`, case "artifact") removes the row by hand, then `context.refreshCoverFromStore()` re-reads the whole workspace; the sheet's create (`ArtifactSheetModel.saveCreate`) patches through `SourceArtifactsSection.show`, then always calls `refreshCoverFromStore()`; attach (`SourceArtifactsSection.confirmAttach`) does the same |
| Leaving a page after a write | `WorkspaceSession.apply(_:_:leavingPage:)` | Hides every key, applies, then leaves; used by the Source delete and Unpromote |
| Superseding calls | `macos/App/Platform/LatestCall.swift` `LatestCall` (`start`, `settle`); used by `SourceTypeFormatsModel`, `UnpromoteFlow` | `docs/macos-client-patterns.md`: no hand-rolled generation counters |
| Derived values | `WorkspaceSession+Derived.swift` `DerivedValueID` (`.visibleSources`, `.sourcesOfType(typeID:)`), `session.derived(_:inputs:)` | `previewSources` sorts its type's Sources inside `.sourcesOfType` |
| Graph places | `macos/App/Features/Workspace/WorkspaceDestinationHost.swift` (`.sourceGraph`, `.sourceCitationComposer`, `.sourcePromote` take `sourceId` from the location); `EvidenceGraphModel.sourceID` (keys, `sourceRow`, breadcrumb, composer locations); `WorkspaceNavigation.replaceCurrent(with:)`; `WorkspaceSession.evidenceGraph(id:)` (the cached graph list, which the move's `evidence_graphs` read refreshes) | A history entry made before a move keeps the old `sourceId`; nothing corrects it |
| Session | `WorkspaceSession.apply(_ effects:_ mutation:)`, `apply(_ mutation:)`, `noticeToast` ("Transient notice after leaving a place"), drawn in `WorkspaceView` | Promote sets `noticeToast` then navigates (`PromoteModel.promote()`) |
| Graph counts | `SourcesGraphCountLine(counts: SourcesGraphCounts(progress:countsLoading:countsError:), style: .card)` | The count line the graph cards draw |
| Thumbnails | `macos/App/Platform/CachedThumbnail.swift` `CachedThumbnail`; `CatalogArtifact.thumbnailTypeIconKey(sourceTypeIconKey:)` | The row's 64pt thumbnail draws through it |
| Errors | `macos/App/Platform/L10n.swift` `L10n.Errors.message(for:)` (has `sourceMoveInvalid`, `sourceMoveNotFound` copy from S15-24); `ConclusionVocabulary.swift` `EngineErrorCode` | No `sourcemove` case in `EngineErrorCode` |
| Tests | `macos/ProvenenciaTests/SourcePageModelTests.swift` (line 2524: `ArtifactRowAction.menuActions` and titles); `SourceCopyModelTests.swift` `makeStore`, `makeModel` | The row test pins today's three actions |

**Precedent.** The keyed read: `source_records` and `evidence_graphs` in `core/database/effects/registry.go`, and `.evidenceGraph`'s `refreshes: [.applyHiddenPolicy(followsOwnId: .evidenceGraphs)]`. Copy Source (`SourceCopyModel`, `SourceCopyDialog.swift`, tests `SourceCopyModelTests.swift`) is the same shape: an optional model on `SourcePageModel`, a `pvFormDialog(item:)` modifier that navigates on success, a load area for the dialog's read, an error Callout. Copy that. Take the picker from `SourceTypeFormatsPreviewPicker` and the success notice from `PromoteModel.promote()` (`session.apply(effects)`, `session.noticeToast = …`, then navigate). Take the store method shape from `getEvidenceGraphUnlinkImpact` (GoStore and FakeStore). Do not copy Copy Source's dirty tracking (D-7).

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | The Artifact row's actions are buttons only (board, 2026-11-22). In `SourcePageArtifactRow.actions(canSetCover:)` a `PVIconButton(.folderInput, label: L10n.Sources.moveArtifactLabel(name: art.displayTitle), size: .sm) { model.openMove(artifactID: art.id) }` *(new)* sits between the pencil and the trash, id `sources.page.artifact.<id>.move`, with `.help(Text(L10n.Sources.moveArtifactLabel(name:)))`. The row's `.pvRightClickMenu` goes, and with it what only the menu needed: `ArtifactRowAction` (enum, `menuActions`, `title`, `idSuffix`), `perform(_:)` (each button calls the model directly, as its action reads today), and the keys `L10n.Sources.artifactMenuEdit` and `artifactMenuDelete` with their catalog entries | MV-1; replace, not beside: the menu existed to mirror the buttons | Keeping the enum for the buttons alone — one switch for four closures |
| D-2 | The graph card gains `PVIconButton(.folderInput, label: L10n.Sources.moveGraphLabel(name: graph.name), size: .sm) { model.openMove(graphID: graph.id) }` *(new)* between the pencil and the trash, `.disabled(model.source == nil)` as the pencil, id `sources.page.graph.move.<ref>`, `.help` its label. Open's disabled rule and tooltip are unchanged (a graph with no Artifact cannot open; Move still can). No menu. `PVSymbol.folderInput` *(new)*: Lucide `folder-input`, SF Symbol `"arrow.forward.folder"` (not confirmed on the deployment target when planned; `PVSymbolTests` is the check); if it finds it does not resolve on the deployment target, it becomes a custom `"pv.folder.input"` drawn in `PVIcon` as `imageUp` is (a folder with an inward arrow), never another glyph. The custom drawing is the implementer's: the folder outline of SF `folder` with a right arrow entering its left edge, at `PVIcon`'s stroke weight | MV-2; the board's glyph | A shared action enum for the card — no menu needs it |
| D-3 | Store: `enum CatalogSourceMoveSeed: Sendable, Equatable { case artifact(String), graph(String) }` with `var id: String`; `struct CatalogSourceMoveImpact: Sendable, Equatable { sourceID: String; artifacts: [CatalogArtifact]; graphs: [CatalogEvidenceGraph]; progress: [EvidenceGraphProgress]; sourceCredibilityLabel: String; targetCredibilityLabel: String; weighedAsLabel: String; credibilityDiffers: Bool; leavesSourceEmpty: Bool; leavesNoGraph: Bool }`; `struct CatalogSourceMoveResult: Sendable, Equatable { artifactIDs: [String]; graphIDs: [String]; defaultGraphID: String?; effects: CatalogWriteEffects }` *(all new, in `GenealogyStore.swift` beside `CatalogEvidenceGraphUnlinkBlock`)*. Methods `getSourceMoveImpact(projectDir: String, seed: CatalogSourceMoveSeed, targetSourceID: String?) async throws -> CatalogSourceMoveImpact` and `moveToSource(projectDir: String, userID: String, seed: CatalogSourceMoveSeed, targetSourceID: String) async throws -> CatalogSourceMoveResult` *(new)*. GoStore sets exactly one of `artifactID`/`graphID` from the seed, `targetSourceID ?? ""`, and maps with the existing `mapArtifact`, `mapEvidenceGraph`, `mapEvidenceGraphProgress`, `mapWriteEffects`; an empty `default_graph_id` maps to nil | The wire's "exactly one of" is a Swift enum, so the app cannot send both; reuses every existing mapper | Two optional strings in Swift — the invalid state stays expressible |
| D-4 | FakeStore: `sourceMoveImpacts: [String: CatalogSourceMoveImpact]` keyed by the seed's id (a seed with no entry is a test bug: `preconditionFailure("no scripted move impact for <id>")`); `sourceMoveTargetCredibility: [String: (label: String, weighedAs: String, differs: Bool)]` keyed by target id, copied into the reply's `targetCredibilityLabel`, `weighedAsLabel` and `credibilityDiffers` when a target is given (an absent target id gives "", "" and false); `getSourceMoveImpactCalls: [(seed: CatalogSourceMoveSeed, target: String?)]`, `getSourceMoveImpactError`, `getSourceMoveImpactHold: FakeHold` (the file's existing pause; `release()` resumes the oldest call, which is all T-8 needs: `LatestCall` drops a superseded reply whenever it arrives); `moveToSourceCalls`, `moveToSourceError`. A successful `moveToSource` reads the seed's scripted impact and re-buckets: each of its Artifacts leaves `artifactsBySource[impact.sourceID]` and is appended to `artifactsBySource[target]` with `sourceID` set to the target; each of its graphs in `evidenceGraphsByProject[projectDir]` gets `sourceID` = target. It returns those ids, `defaultGraphID` nil (or `"default-<origin>"` when `leavesNoGraph`, with that graph appended to the origin), and `effects` whose `sourceScopes` holds both Source ids and whose `reads` holds `source_artifacts` and `evidence_graphs` [origin, target] | Scripted, as `unlinkImpactBlocks`; the bundle closure is Go's (S15-24), not the fake's to reimplement; re-bucketing keeps the fake's workspace reads true after a move | A Swift closure walk in FakeStore — a second derivation of the bundle |
| D-5 | `SourceMoveModel` *(new, `macos/App/Features/Sources/SourceMoveModel.swift`)*, `@MainActor @Observable final class`, built by `SourcePageModel.openMove(artifactID:)` / `openMove(graphID:)` *(new)* into `SourcePageModel.moving: SourceMoveModel?` *(new)*; each guards `source != nil` (as `openCopy()` does) and an id found in `artifacts.items` / `graphs.ownGraph(id:)`, else opens nothing. It holds `seed`, `origin: CatalogSource` (the page's `source`), `seedTitle` and `seedRef` (the Artifact's `displayTitle` and `ref`, or the graph's `name` and `ref`, read from `artifacts.items` / `graphs.ownGraph(id:)`; an id not found opens nothing), a handle on `SourcesModel.sourcesListKey(for:)` (taken with `session.query`, as `SourceCopyModel` takes its handles), `sourceTypeIconKey: String?` (the page context's `sourceTypeIconKey`, for the bundle's thumbnails), `targetID: String?`, `target: CatalogSource?` (the picked row, kept from the pick), `impact: CatalogSourceMoveImpact?`, `impactTarget: String?` (the target the held reply answered), `readState: PVFormLoadState`, `isReading`, `isMoving`, `moveError: String?` | Copy Source's shape; the page already owns the rows the seed comes from | A `CatalogQueryKey` for the preflight — a dialog-local read held only while open, as `getDeleteImpact` and `getEvidenceGraphUnlinkImpact` are read |
| D-6 | Reads. `init` starts `read(target: nil)`. `pick(targetID:)`: the same id as `targetID` does nothing; `""` (the ComboBox cleared) sets `targetID` and `target` to nil and starts no read (the credibility note hides; Move dims); any other id sets `targetID`, sets `target` to that row of `targets` (D-10), and starts `read(target:)`. Reads go through `private let preflight = LatestCall()` (`preflight.start({ try await store.getSourceMoveImpact(…) }, apply: { result in … })`), so a newer read cancels and drops an older one; `read` sets `isReading`, and only the latest call's `apply` clears it. `settleReads() async` *(internal, for tests)* awaits `preflight.settle()`. A reply sets `impact`, `impactTarget` (its target, nil for the open read) and `readState = .ready`. An error of the latest read sets `readState = .failed(L10n.Errors.message(for: error))` whether or not it had a target: the load area then shows the failure in place of the bundle, with Read again. `readState` is `.loading` only while `impact` is nil and a read runs (the first read, or a pick made before the first reply, which supersedes it); a pick's read with a bundle already drawn keeps `.ready` and the bundle. `readAgain()` reads again for the current `targetID` (nil or the pick). `canMove` = `impact != nil && target != nil && impactTarget == targetID && !isReading && !isMoving` | AC-3.1, AC-3.4, AC-3.5; S15-24 D-12 ("ask again with it, through one RPC") | A hand-rolled sequence number — `docs/macos-client-patterns.md` names `LatestCall` the one supersede rule (review M-1); debouncing the pick — a pick is one click, not typing; keeping the bundle under a failed pick read with no message — Move would be dimmed with no reason given |
| D-7 | Cancel and Escape close the dialog without asking: `isDirty` is not passed (false). `pvFormDialog`'s `isRunning: model.isMoving` blocks closing during the write | MV-3: nothing is typed; the kit's running rule covers MV-12 | Copy Source's `isDirty` — a pick is not work to lose |
| D-8 | `move(leavingPage leave: @escaping (CatalogSource) -> Void) async -> Bool`: guards `canMove` and `target`; sets `isMoving`; calls `moveToSource`; on success sets `session.noticeToast = VocabularyToast(title: L10n.Sources.moveDoneTitle(target: target.title), body: Self.doneBody(artifacts: result.artifactIDs.count, graphs: result.graphIDs.count), tone: .success)`, then `session.apply(result.effects, leavingPage: { leave(target) })` with no mutation, and returns true. The modifier's `onConfirm` passes `{ navigation.go(to: SourcesListNavigation.pageLocation(for: $0)) }` and returns `await current.move(leavingPage:)`. On error: `moveError = L10n.Errors.message(for: error)`, returns false (the dialog stays) | Both Sources' pages follow the effects' `source_artifacts` read (D-16), so no hand-named cache update (working rule "A move is the whole bundle"; review M-2); `leavingPage` hides the old page's keys first so it is marked stale, not refetched as it leaves (review M-4; the Source delete's path); the notice Toast outlives the page change (Promote's precedent); landing at the top is the user's call (2026-11-21) | Naming both Sources with `.mutatedSourceWorkspace` — a hand-written cache update the working rule refuses; a plain `apply` then `navigate` — the old page refetches while it leaves |
| D-9 | No `EngineErrorCode` case for `sourcemove.*`, and no parity row: no code branches on them. Every refusal shows `L10n.Errors.message(for:)` (S15-24 added the copy) in the load-area failure or the "Couldn’t move" Callout | One window: the seed and the target cannot vanish while the modal dialog is open; `sourcemove.invalid` is a client bug. The S15-24 plan's Out line named this PR for the mapping; this Decision retires it | Mapping them for parity — a case no `switch` reads |
| D-10 | Targets: `DerivedValueID.sourcesByUpdated` *(new)*: every Source of the Sources list, sorted by `SourcesModel.updatedOrder`, built with `session.derived(.sourcesByUpdated, inputs: [.key(SourcesModel.sourcesListKey(for: session))])`; `.sourcesOfType(typeID:)` filters from it instead of sorting again, declaring it as its input: `session.derived(.sourcesOfType(typeID:), inputs: [.derived(.sourcesByUpdated)]) { sourcesByUpdated.filter { $0.sourceTypeID == typeID } }` (no direct key read inside the build, so the debug undeclared-read check stays quiet). `targets: [CatalogSource]?` = `sourcesByUpdated` minus `origin.id`; nil while the list is unread (no field and no Callout, as the format editor's picker). Read and empty → the "nowhere to move" Callout (MV-11). `PVComboBox` options `PVComboBoxOption(value: id, label: title, subtext: ref)`; the kit's own filter matches the typed text | The user's order (2026-11-21); one sorted list per list change, shared with the format editor's picker (review M-5) | A plain computed property — re-sorts up to 3,000 rows on each read; a target read over FFI — the list is the session's cached Sources list |
| D-11 | The engine names the grades. `sourcemove.Report` gains `SourceCredibilityLabel`, `TargetCredibilityLabel` ("" when not assessed, or no target) and `WeighedAsLabel` (the target's grade label; the label of `sourcecredibilitygrades.DefaultKey` when the target is not assessed; "" with no target), filled in `Impact` from one `sourcecredibilitygrades.List(c)` keyed by grade key, only when a target is given. Proto `GetSourceMoveImpactResponse` gains `string source_credibility_label = 10; string target_credibility_label = 11; string weighed_as_label = 12;` *(new)*, mapped in `api/ffi/handlers/source_move.go`. The two key fields stay on the wire (S15-24's tests read them); Swift does not map them. Swift shows the note when `impact.credibilityDiffers && impactTarget == targetID`; a label "" prints `L10n.Sources.moveNotAssessed` *(new)* "not assessed"; "weighed as" prints `weighedAsLabel` | The "not assessed weighs as Standard" rule is the engine's (`DefaultKey`, `sourcemove` comment); a Swift copy would be a third (review M-3; user, 2026-11-21: the engine sends it). Additive fields: old clients ignore them | A Swift grade lookup with a Standard fallback (a copy of the engine rule); a shared Swift helper (still a copy) |
| D-12 | Toast body: `doneBody(artifacts:graphs:)` *(static, testable)* picks one of three sentence shapes by which counts are zero (the plural form inside each is the catalog's, never a Swift `== 1` test): both > 0 → `L10n.Sources.moveDoneBody(artifacts:graphs:)` "%#@artifacts@ and %#@graphs@"; graphs 0 → `moveDoneArtifacts(count)` "%lld Artifacts"; artifacts 0 → `moveDoneGraphs(count)` "%lld graphs", each with plural variations. (0, 0) cannot occur (a bundle holds its seed) and returns `moveDoneArtifacts(0)`. The two-count key's catalog entry has two plural substitutions, laid out as `provenanceSheet.recordsFromPlaces` | MV-14; `add-localized-string`: counts are plural keys | Labels joined in the body — up to ten names in a Toast |
| D-13 | Bundle rows are private views in `SourceMoveDialog.swift` *(new)*: an Artifact row = `CachedThumbnail(…, typeIconKey: art.thumbnailTypeIconKey(sourceTypeIconKey: model.sourceTypeIconKey), size: 32)`, `displayTitle` (body, semibold), `ref` (mono caption, muted); a graph row = `PVIcon(.gitBranch, size: 13)`, `name`, `ref`, `SourcesGraphCountLine(counts: SourcesGraphCounts(progress: impact.progress[i], countsLoading: false, countsError: nil), style: .card)`. The model's `bundleArtifacts: [CatalogArtifact]` and `bundleGraphs: [(graph: CatalogEvidenceGraph, progress: EvidenceGraphProgress?)]` put the seed first in its group, then the rest in the reply's order (MV-5); each graph's progress is matched by `graphId` (`impact.progress.first { $0.graphId == graph.id }`), never by position, and a graph with no progress row draws no count line. The seed carries no mark. The "why" line shows only when `bundleArtifacts.count > 1` (board decision: it explains a pulled-in Artifact); the model exposes it as `var showsWhy: Bool`. Layout, as the board draws it: `PVSubsectionHeader(title: L10n.Sources.moveTogether)` holding the why line (`PVFont.body(size: PVTypeScale.bodySmall)`, `PVColor.textSecondary`) and one list: the Artifact rows, a `PVDivider()` when both groups are present, then the graph rows. Each row is an `HStack(spacing: PVSpacing.space5)` at least 40pt tall: a 32pt lead (the Artifact's `CachedThumbnail` cropped to fill, or for a graph `PVIcon(.gitBranch, size: 16)` in `PVColor.textMuted` centred in 32×32), then the title (`PVTypeScale.bodySmall`, `PVColor.textPrimary`, one line, truncating) with the ref beside it on the baseline (`PVFont.mono(size: PVTypeScale.micro)`, `PVColor.textMuted`), and for a graph the count line under them (`SourcesGraphCountLine(…, style: .card)`, the graph card's own words, "4 subjects · 6 observations"; the board's "4 people · 6 citations" is not taken, so the dialog and the card read alike). Rows are `.accessibilityElement(children: .combine)` with ids `sources.move.bundle.artifact.<ref>` / `sources.move.bundle.graph.<ref>` | MV-5; reuses the page's count line and thumbnail; one call site, so a snowflake | `PVArtifactChecklist` — its rows can be unticked; the page's `SourcePageArtifactRow` — it carries actions and copy details |
| D-14 | The dialog: `View.sourceMoveDialog(_ model: Binding<SourceMoveModel?>)` *(new)* → `pvFormDialog(item:copy:width: 520, isRunning:confirmDisabled: !canMove, accessibilityIdentifierPrefix: "sources.move", scrollsBody: true, onConfirm:form:)`, `PVFormDialogCopy(title: L10n.Sources.moveDialogTitle, verbatimSubtitle: "\(seedTitle) · \(seedRef)", confirm: L10n.Sources.moveConfirm, cancel: L10n.Sources.cancelAction)`. Body: `VStack(alignment: .leading, spacing: PVSpacing.space6)`, as `SourceCopyForm`: (1) `moveError` → `PVCallout(tone: .danger, title: L10n.Sources.moveFailedTitle, message: L10n.Sources.moveFailedMessage(moveError), announces: true)` id `sources.move.error`; (2) `targets == nil` → nothing; empty → `PVCallout(tone: .neutral, message: L10n.string(L10n.Sources.moveNowhere), compact: true)` id `sources.move.nowhere`; else `PVField(label: L10n.Sources.moveTargetLabel) { PVComboBox(selection: Binding(get: { targetID ?? "" }, set: { pick(targetID: $0) }), options:, placeholder: L10n.Sources.moveTargetPlaceholder, emptyLabel: L10n.Sources.moveTargetNoMatch, label: L10n.Sources.moveTargetLabel, accessibilityIdentifierPrefix: "sources.move.target") }`; (3) `PVFormLoadArea(state: readState, loadingText: L10n.Sources.moveLoading, errorTitle: L10n.Sources.moveLoadErrorTitle, errorMessage: L10n.Sources.moveLoadErrorMessage, onReadAgain: readAgain, accessibilityIdentifierPrefix: "sources.move.bundle")` holding the bundle (D-13); (4) the credibility note `PVCallout(tone: .warning, title:, message:, compact: true)` id `sources.move.credibility`; (5) `leavesEmptyNote`, `leavesNoGraphNote` as `PVCallout(tone: .neutral, message:, compact: true)` ids `sources.move.leavesEmpty`, `sources.move.leavesNoGraph`. The ComboBox's spoken label is `moveTargetLabel`. Chained in `SourcePageContent` after `.sourceCopyDialog` | MV-3 – MV-13, MV-W1 (one width at both classes; 520 as Copy Source, the other Source page dialog that holds a list, review M-10) | `pvConfirm` — it has no field slot |

| D-15 | `effects.ReadSourceArtifacts Read = "source_artifacts"` *(new)*: "the Artifacts a Source holds; moved when an Artifact joins or leaves it"; `KeyTable` "sources"; placed in `Reads` before `ReadSourceRecords`, keeping the list alphabetical (`registry.go:70`); the "catalog reads" parity row sorts both sides, so the order is the wire's only. The `"artifacts"` registry entry gains `{ReadSourceArtifacts, onField("source_id", field("source_id"))}` beside its `source_records` path: a create and a delete carry `source_id` (artifacts.go `Create`, `Delete`), and an update carries it only when the Source changes (S15-24's `SetSourceTx`), so a label, description or file write never reports it. Swift `CatalogRead.sourceArtifacts = "source_artifacts"` *(new)*; the "catalog reads" parity row picks it up from `effects.Reads`. `TestReadsDeclare` (`core/database/effects/reads_test.go`) gains `ReadSourceArtifacts: {"artifacts"}` in its `want` map, and its `artifacts` assertion (line 47) becomes: no graphs, exactly two reads, `ReadSourceRecords` and `ReadSourceArtifacts`. `registry_completeness_test.go` needs no change (its `artifacts` row checks activity and graphs) | A narrow signal for "a Source's Artifacts changed" (user, 2026-11-21); `source_records` stays as it is for Go's Source records and the page inputs. Reuses `onField` and the keyed-read vocabulary (`effects/README.md`: a new read is a constant, a `KeyTable` case, an entry in `Reads` and `Reads:` paths) | Following `source_records` — reloads the visible page on every title, date and metadata edit; a Swift mutation per Source — hand-written cache code (review M-2) |
| D-16 | `.sourceWorkspace`'s descriptor gains `refreshes: [.applyHiddenPolicy(followsOwnId: .reads(.sourceArtifacts))]`: the page on screen reloads, a hidden one is marked stale (`whenHidden: .markStale`). Its patches and mutations stay. What becomes dead goes: in `SourcePageModel.confirmResourceDelete` case "artifact", the `workspace.artifacts.removeAll` patch, its `setWorkspace`, and `refreshCoverFromStore()` (the Toast and `session.apply(effects)` stay); in `ArtifactSheetModel.saveCreate`, `refreshCoverFromStore()` runs only after a file ingest (an ingest moves the cover, which `source_artifacts` does not report). `SourceArtifactsSection.confirmAttach` is unchanged | One declared follow replaces hand-written reloads, and a later Merge Sources needs nothing (`docs/catalog-caches.md`: every cache names its signal) | A merged partial re-read of the Artifacts alone — the cover and "has Artifact" live on the Source row of the same value; whole-workspace reloads already follow these writes by hand today, so the cost is unchanged |
| D-17 | A graph place follows its graph's Source. `WorkspaceLocation.correctingGraphSource(_ graph: CatalogEvidenceGraph?) -> WorkspaceLocation?` *(new, in `WorkspaceLocation.swift`)*: nil unless the location has a `graphId`, `graph?.id == graphId`, and `graph.sourceID != sourceId`; else a copy with `sourceId = graph.sourceID` and `sourceTitle = nil`. `WorkspaceDestinationHost`'s body gains one `.onChange(of: graphSourceID, initial: true)` on the view that holds the `switch` (not inside a case), which acts only when `presentation` is `.sourceGraph`, `.sourceCitationComposer` or `.sourcePromote`; where `graphSourceID = navigation.currentLocation.graphId.flatMap { session.evidenceGraph(id: $0)?.sourceID }`, calling `navigation.replaceCurrent(with:)` with the corrected location when it is non-nil | The canvas, composer and Promote then read every Source key, crumb and link from a correct location, with no change inside `EvidenceGraphModel`; `replaceCurrent` is how a place already rewrites its entry (`fallbackToSectionRoot`, the composer); the graph list follows the move's `evidence_graphs` read (review M-6; user, 2026-11-21: fix in this PR) | `EvidenceGraphModel` reading its Source from the graph row — six call sites, and the composer and Promote would each need it too |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `PVSymbol.folderInput` | symbol | `PVSymbol.imageUp` (a custom fallback) | The board's Move glyph (D-2) |
| `CatalogSourceMoveSeed`, `CatalogSourceMoveImpact`, `CatalogSourceMoveResult` | types | `CatalogEvidenceGraphUnlinkBlock`, `CatalogDeleteImpact` | A different reply |
| `getSourceMoveImpact`, `moveToSource` (protocol, GoStore, FakeStore) | store methods | `getEvidenceGraphUnlinkImpact`, `copySource` | New RPCs (S15-24) |
| `SourceMoveModel` | model | `SourceCopyModel` | Same shape, another write; nothing to share beyond the pattern (searched `rg "final class Source.*Model" macos/App/Features/Sources`) |
| `SourceMoveDialog.swift` (`sourceMoveDialog`, the form, bundle rows) | view | `SourceCopyDialog.swift` | Same shape; the rows are D-13 |
| `SourcePageModel.moving`, `openMove(artifactID:)`, `openMove(graphID:)` | state / funcs | `copying`, `openCopy()` | Extends the page model |
| `effects.ReadSourceArtifacts`, `CatalogRead.sourceArtifacts` | keyed read | `ReadSourceRecords`, `ReadEvidenceGraphs` | A narrower signal than `source_records` (D-15) |
| `sourcemove.Report` label fields; proto fields 10 – 12 | fields | `CredibilityAssessment.grade_label` (a label already sent beside a key) | Extends the S15-24 reply (D-11) |
| `DerivedValueID.sourcesByUpdated` | derived value | `.sourcesOfType`, `.visibleSources` | `.sourcesOfType` now filters from it (D-10) |
| `WorkspaceLocation.correctingGraphSource(_:)` | func | `WorkspaceNavigation.fallbackToSectionRoot` | Same "rewrite the entry in place" shape for a moved graph (D-17) |
| `L10n.Sources.move*` keys | keys | `copySource*`, `artifactMenu*` | New copy |
| `SourceMoveModelTests.swift` | tests | `SourceCopyModelTests.swift` | New model |

**Builds on.** The effects registry's keyed reads and `onField`; the descriptor `refreshes`; `LatestCall`; `apply(_:_:leavingPage:)`; `replaceCurrent(with:)`; the kit's FormDialog, ComboBox, FormLoadArea, Callout, ContextMenu (`verbatimTitle`); `WorkspaceSession.apply` and `noticeToast`; `SourcesModel.sourcesListKey` and `updatedOrder`; `SourcesGraphCountLine`; `CachedThumbnail`; the Copy Source dialog shape.
**Deletes.** The Artifact row's right-click menu, `ArtifactRowAction`, `SourcePageArtifactRow.perform(_:)`, `L10n.Sources.artifactMenuEdit` and `artifactMenuDelete` with their catalog entries, and the test of them at `SourcePageModelTests.swift:2524` (D-1); `pvRightClickMenu(verbatimTitle:…)` and `PVContextMenuPanel.init(verbatimTitle:…)`, whose only caller was that menu, and the README ContextMenu row's `verbatimTitle:` clause; `SourcePageGraphsView`'s doc comment "one card per graph with Open and Delete" becomes "one card per graph with Open, Edit, Move and Delete". The Artifact delete's hand patch and whole-workspace re-read, and the fileless create's re-read, go (D-16). Nothing else becomes dead.
**Next adds.** Merge Sources (refused this spike) would be moves, and both pages would follow with no client code. Undo (refused this spike) would be a second `moveToSource` from the Toast. Move from the canvas or the Artifact sheet would call `SourcePageModel.openMove` from their hosts.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| The Source page after a move took some or all of its Artifacts and graphs | `SourcePageModel.apply`, `SourceArtifactsSection`, `SourceGraphsSection` | Back to S1 reloads its workspace (invalidated, D-8); an empty Artifacts list and a page with only the new Default graph are states the page already draws (every Artifact deleted; a new Source) |
| A Source whose cover Artifact moved | Sources list row thumbnail, the page header | The engine reset the cover (S15-24 D-7); the Sources list follows `sourceScopes`, the workspace is invalidated |
| The target page opened with Artifacts and graphs that were elsewhere | `SourcePageView` via `navigation.go(to:)` | A normal page open; its workspace key was invalidated so a cached copy reloads |
| The canvas, composer or Promote of a moved graph, in history | `WorkspaceDestinationHost` graph cases | D-17 rewrites the entry to the graph's Source before its keys read; T-16 and manual check step 5 |
| A Source page reload after an Artifact create or delete | `.sourceWorkspace` refresh (D-16) | The same whole read those writes already ran by hand (`refreshCoverFromStore`); T-15 |

### Scale

At the map's Scale (a bundle of 5 Artifacts and 5 graphs with up to 100 Subjects; 3,000 Sources): the preflight runs twice per dialog (open, pick) plus once per later pick; each is S15-24's three-query closure and cache reads. The ComboBox holds up to 2,999 options filtered by the kit. The dialog draws at most 10 bundle rows, each one thumbnail from the cache. The move is one write; `apply(_:leavingPage:)` marks both Sources' workspaces stale, and the target's reloads once when its page shows. The new read adds one `onField` check per Artifact change in `effects.Resolve`; a create or delete reloads the visible page once, as the hand-written `refreshCoverFromStore` did, and a field edit reloads nothing new. `.sourcesByUpdated` sorts up to 3,000 Sources once per Sources-list change. No budget is set.

### Edges

- **Assumptions.** (1) The reply's `progress` has one row per graph; D-13 matches by `graphId`, so a missing or reordered row draws no count line for that graph and nothing else changes (T-5). (2) The target `CatalogSource` is kept at the pick (D-6). (3) `onField("source_id", …)` fires on create and delete because `Created`/`Deleted` carry every column (artifacts.go), and on update only when `source_id` changed; T-0 pins all five cases (AC-5.1). (4) `correctingGraphSource` only rewrites a location whose graph row is cached; an uncached graph keeps its entry (AC-6.3).
- **Neighbors.** A bundle of one row draws no "why" line (AC-2.2, AC-2.3); two rows draw it. Credibility "" vs "standard" shows no note because the engine says they do not differ (AC-3.3).
- **Removed inputs.** The old page loses the moved rows on reload (AC-4.4).
- **Real data.** None — no table or seed drives a rule here.
- **Untrusted size.** None — every input is the app's own catalog read.

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/effects` | `ReadSourceArtifacts` *(new)*, its `KeyTable` case, `Reads` entry, the `"artifacts"` entry's second `ReadPath` (D-15); `reads_test.go` row; `README.md` names the read |
| `core/database/sourcemove` | `Report` label fields filled in `Impact` (D-11); `sourcemove_test.go` rows |

### FFI

`api/proto/engine.proto` `GetSourceMoveImpactResponse`: `source_credibility_label = 10`, `target_credibility_label = 11`, `weighed_as_label = 12` *(new)*; `api/ffi/handlers/source_move.go` maps them; regenerate with `./scripts/generate-proto.sh`. `WriteEffects.reads` carries `source_artifacts` with no proto change (the read is a string key). Swift calls the RPCs through `CoreMethod.getSourceMoveImpact` and `.moveToSource`.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Artifact row Move | `PVIconButton(.folderInput)` | `SourcePageArtifactRow.swift` | D-1, MV-1; the menu goes |
| Graph card Move | `PVIconButton(.folderInput)` | `SourcePageGraphsView.swift` `SourcePageGraphRow` | D-2, MV-2 |
| Move dialog | `pvFormDialog(item:)` | `SourceMoveDialog.swift` *(new)* | 520pt, scrolls its body (D-14, MV-3, MV-6) |
| Target picker | `PVField` + `PVComboBox` | same | D-10, MV-4 |
| Bundle | `PVFormLoadArea`, `PVSubsectionHeader`, `CachedThumbnail`, `PVIcon`, `SourcesGraphCountLine` | same | D-13, MV-5, MV-9, MV-10 |
| Notes | `PVCallout` (warning, neutral, danger) | same | MV-7, MV-8, MV-11, MV-13 |
| Notice | `WorkspaceSession.noticeToast` | `SourceMoveModel.move()` | MV-14 |

**The board.** [agreed 2026-11-22](https://claude.ai/artifact/443NPNYmGErAmxgV1fBsFK): page *Move*, rows "Move: the buttons" (`mv-art-menu`, `mv-graph-menu`, each with a Wide frame), "Move dialog" (`mv-open` … `mv-failed`) and "After the move" (`mv-after`, `mv-after-wide`); decisions panel "S15-D10". Read it with the Artifact tool's `read` on that link, `path` "project/Source.dc.html" (search `S15-D10` and `mv-`). Board decision (user, 2026-11-22): **no right-click menu** on Artifact rows or graph cards; Move is a visible icon button, and the Artifact row's existing menu goes. Frames: `mv-art-menu` / `mv-graph-menu` (+ Wide) the buttons; `mv-open` (+ Wide) opened from image 1, Move dimmed; `mv-combo` "ED 2" typed; `mv-picked` the credibility Callout; `mv-whole` ED 12, one Artifact and one graph, both left-behind notes, no why line; `mv-default` from the Default graph; `mv-loading`; `mv-read-failed`; `mv-nowhere`; `mv-running`; `mv-failed`; `mv-after` (+ Wide) the target page at its top with the Toast bottom right. The copy in § 6 Strings is the board's.

States: loading (MV-9), read failed (MV-10), nowhere to move (MV-11), running (MV-12), failed (MV-13). Accessibility: the Move buttons carry their labels (AC-1.5); the bundle rows are combined elements reading "Sheet 14 (image 1), ART-7QK2M" and "Hale household, dwelling 113, GPH-3RX8W, 4 people, 6 citations"; identifiers `sources.move.*`, `sources.page.artifact.<id>.move`, `sources.page.graph.move.<ref>`.

### Strings

L10n keys *(new)*, in `L10n.Sources`, each in `Localizable.xcstrings`:

| Key | English |
| --- | --- |
| `moveArtifactLabel(name:)` / `moveGraphLabel(name:)` | "Move %@ to another Source" (each, with its own comment) |
| Removed | `artifactMenuEdit` "Edit…", `artifactMenuDelete` "Delete…" (D-1) |
| `moveDialogTitle` | "Move to another Source" |
| `moveConfirm` | "Move" |
| `moveTargetLabel` / `moveTargetPlaceholder` / `moveTargetNoMatch` | "Move to" / "Choose a Source" / "No Source matches" |
| `moveNowhere` | "There is no other Source to move to. Add a Source first, or copy this one." |
| `moveTogether` / `moveTogetherWhy` | "Moves together" / "A graph moves with all its Artifacts, so these move together." |
| `moveLoading` / `moveLoadErrorTitle` / `moveLoadErrorMessage(_:)` | "Reading what moves with it" / "What moves could not be read." / "Nothing was moved. Try reading it again. %@" |
| `moveCredibilityTitle` / `moveCredibilityMessage(origin:originGrade:target:targetGrade:weighedAs:)` | "Credibility changes" / "“%1$@” is assessed %2$@; “%3$@” is %4$@. The moved records will be weighed as %5$@, so conclusions that rest on them can change." |
| `moveNotAssessed` | "not assessed" |
| `moveLeavesEmpty(_:)` / `moveLeavesNoGraph(_:)` | "“%@” will have no Artifacts left. It is not deleted." / "“%@” gets a new empty graph named Default, so it keeps one." |
| `moveFailedTitle` / `moveFailedMessage(_:)` | "Couldn’t move" / "Nothing was moved. %@" |
| `moveDoneTitle(target:)` | "Moved to “%@”" |
| `moveDoneBody(artifacts:graphs:)`, `moveDoneArtifacts(_:)`, `moveDoneGraphs(_:)` | plural keys, D-12 |

These are the board's words. No existing copy names the old scope of an action.

## 7. Steps

**STEP-1 — Engine: the `source_artifacts` read and the credibility labels**
Files: `core/database/effects/registry.go`, `reads_test.go`, `README.md`; `core/database/sourcemove/sourcemove.go`, `sourcemove_test.go`; `api/proto/engine.proto`; `api/ffi/handlers/source_move.go` and its test; regenerated `macos/App/Platform/Generated/engine.pb.swift` and Go bindings; `macos/App/Features/Workspace/Session/CatalogMutation.swift` (`CatalogRead.sourceArtifacts`). Skills: `add-audit-scope`, `add-ffi-handler`.
Do: D-15, D-11. Tests first: T-0, T-0b.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/effects/... ./core/database/sourcemove/... ./api/ffi/...` passes (the "catalog reads" parity row included).

**STEP-2 — Store methods**
Files: `macos/App/Platform/GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift`, `macos/ProvenenciaTests/SourceMoveModelTests.swift` *(new)*. Skill: `add-swift-test`.
Do: D-3, D-4. Create the test file with T-1 first, red until the fake exists. GoStore's two methods get no Swift test, like their precedent `getEvidenceGraphUnlinkImpact`; manual check steps 3–4 run them.
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/SourceMoveModelTests` passes.

**STEP-3 — The Source page follows `source_artifacts`**
Files: `CatalogQueryRegistry.swift` (`.sourceWorkspace`), `SourcePageModel.swift` (`confirmResourceDelete`), `ArtifactSheetModel.swift` (`saveCreate`), `macos/ProvenenciaTests/SourcePageModelTests.swift`, `docs/catalog-caches.md` (the "Per-view query results" row), `docs/macos-client-patterns.md` (rule 2's list of reads), `.agents/skills/add-workspace-place/SKILL.md` § 6 (Artifact create and delete follow `source_artifacts`). Skill: `add-workspace-place`.
Do: D-16.
Check: T-15 passes; the existing Artifact delete and create tests in `SourcePageModelTests` pass unchanged in what they assert.

**STEP-4 — `SourceMoveModel`: reads and targets**
Files: `macos/App/Features/Sources/SourceMoveModel.swift` *(new)*, `SourcePageModel.swift` (`moving`, `openMove(artifactID:)`, `openMove(graphID:)`), `WorkspaceSession+Derived.swift` (`.sourcesByUpdated`; `.sourcesOfType` filters from it), `SourceMoveModelTests.swift`. Skills: `add-swift-test`, `add-localized-string`.
Do: D-5, D-6, D-10, D-11 (Swift side), D-13's `bundleArtifacts`, `bundleGraphs`, `showsWhy`; the notes as computed properties (`credibilityNote: (title: String, message: String)?`, `leavesEmptyNote: String?`, `leavesNoGraphNote: String?`).
Check: T-4 – T-10 and T-14 pass; the format editor's preview tests still pass.

**STEP-5 — `SourceMoveModel`: move and land**
Files: `SourceMoveModel.swift`, `SourceMoveModelTests.swift`.
Do: D-8, D-12.
Check: T-11 – T-13 pass.

**STEP-6 — Move on the Artifact row; its menu goes**
Files: `SourcePageArtifactRow.swift`, `macos/App/DesignSystem/Components/Icon/PVIcon.swift`, `macos/App/DesignSystem/Components/ContextMenu/PVActionMenu.swift`, `PVContextMenu.swift`, `macos/App/DesignSystem/README.md`, `L10n.swift`, `Localizable.xcstrings`, `SourcePageModelTests.swift`. Skills: `add-ui-component`, `add-localized-string`.
Do: D-1, `PVSymbol.folderInput` (D-2); the deletes in § 6 Deletes that belong to the row and the menu.
Also edit the doc comments that name the text-title form: `PVContextMenu.swift` lines 105 – 110 ("or data such as a ref, drawn as given (`init(verbatimTitle:…)`)") and the `pvRightClickMenu` comment in `PVActionMenu.swift`; the README ContextMenu row loses "or data, a ref, as `verbatimTitle:`".
Check: `PVSymbolTests` and T-2 pass; `rg "ArtifactRowAction|artifactMenuEdit|artifactMenuDelete" macos .agents docs/*.md` prints nothing (plans and review logs under `docs/deployment-plan/` keep their history); `rg "artifact\.menu" macos/App/Resources/Localizable.xcstrings` prints nothing; `rg verbatimTitle macos/App/DesignSystem/Components/ContextMenu macos/App/DesignSystem/README.md` prints nothing.

**STEP-7 — Move on the graph card**
Files: `SourcePageGraphsView.swift`. Skill: `add-ui-component`.
Do: D-2.
Check: the app builds; manual check step 2.

**STEP-8 — The dialog**
Files: `macos/App/Features/Sources/SourceMoveDialog.swift` *(new)*, `SourcePageView.swift` (`.sourceMoveDialog($model.moving)`). Skill: `add-ui-component`.
Do: D-13, D-14, and the board's frames, which are binding (the Board line says where to read them).
Check: the app builds; manual check steps 2–4 show the frames.

**STEP-9 — A graph place follows its graph's Source**
Files: `macos/App/Features/Workspace/WorkspaceLocation.swift`, `WorkspaceDestinationHost.swift`, `macos/ProvenenciaTests/WorkspaceNavigationTests.swift` (T-16). Skill: `add-workspace-location`.
Do: D-17.
Check: T-16 passes; manual check step 5.

**STEP-10 — Copy and version**
Files: `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`; `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj`. Skill: `add-localized-string`.
Do: § 6 Strings (written as each step needs it; this step checks the catalog); the header's bump.
Check: `python3 scripts/check-localizable-xcstrings.py` passes; `rg 'Text\("' macos/App/Features/Sources/SourceMoveDialog.swift` prints nothing; `scripts/check-pr.sh` prints `check-pr: PASS`.

**STEP-11 — Docs**
Files: `docs/deployment-plan/spike-15/completed.md`; `deployment-plan.md` (map row status); this plan (status, Landed note); `move-artifact-between-sources.md` (Status: built in S15-24 and S15-25; "Navigation" engine note: lands at the target page's top, user 2026-11-21; "Search and caches": both pages follow `source_artifacts`); the archive moves below.
Do:
1. `git mv` into `docs/deployment-plan/spike-15/design/archive/`: `S15-D10-move-confirm.md`, `S15-D1-source-page.md`, `S15-D14-source-page-artifacts.md` and `S15-D14-source-page-artifacts.review.md` (S15-25 is the last PR each brief gates; review logs move with their brief, as `archive/S15-D5-…review.md` did). Also `S15-25-move-from-artifact-or-graph.review.md` stays in `prs/`.
2. Rewrite every inbound link: `rg -l "S15-D1-source-page.md|S15-D14-source-page-artifacts|S15-D10-move-confirm.md" docs .agents` and change each `design/<file>` to `design/archive/<file>` (`../design/` → `../design/archive/` in `prs/`); inside the moved files, add one `../` to each relative link that leaves `design/`. `scripts/check-plan-docs.py`'s `multi_pr_ok` matches by file name, so it needs no change.
3. `design/README.md`: the three rows move from Scheduled to Archived, each with its link into `archive/`; **Board** = the Board line each brief carries; **Built by** = the PRs each gated with numbers, S15-25 written as "S15-25 (#N)" with N filled in once the PR is open.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/*.md docs/deployment-plan/spike-15/design/*.md docs/deployment-plan/spike-15/design/archive/*.md docs/deployment-plan/spike-15/deployment-plan.md` reports no `broken link` error; `rg "design/S15-D(1|10|14)-" docs .agents` prints only `archive/` paths.

Commits: one per behavior, a full imperative sentence ending in a period: STEP-1 "Report when a Source's Artifacts change, and name the move's credibility grades."; STEP-2 "Add the move preflight and write to the app's store."; STEP-3 "Refresh the Source page when its Artifacts change."; STEP-4 and STEP-5 "Add the Move dialog's model."; STEP-6 "Offer Move on Artifact rows, which keep only their buttons."; STEP-7 "Offer Move on Evidence graph cards."; STEP-8 "Show the Move to another Source dialog."; STEP-9 "Open a moved graph under its new Source from history."; STEP-10 "Bump the version to 0.33.0."; STEP-11 "Record S15-25 and archive its briefs." Eleven steps, past the usual ten: the user folded the cache signal into this PR (2026-11-21). No WIP commits.

## 8. Tests

Swift Testing, `FakeStore`, built like `SourceCopyModelTests.makeStore` / `makeModel`.

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-0 | Go | `core/database/effects/reads_test.go` `TestReadsDeclare` (row) and `TestSourceArtifactsRead` *(new, in `core/database/sourcemove/sourcemove_test.go`, on its fixtures)* | create on S1 → `source_artifacts` [S1]; delete → [S1]; move A1 S1→S2 → [S1, S2]; label update → absent; file attach → absent | AC-5.1, D-15 |
| T-0b | Go | `core/database/sourcemove/sourcemove_test.go` `TestImpact` (rows) | S1 `low_trust`, S2 unassessed, target S2 → labels "Low trust", "", weighed "Standard"; S2 `high_trust` → weighed "High trust"; no target → all three "" | AC-3.2, D-11 |
| T-1 | Swift | `macos/ProvenenciaTests/SourceMoveModelTests.swift` `fakeStoreRecordsMoveCalls` *(new)* | A scripted impact for A1; call both methods → calls recorded with the seed and target; the fake's A1 now has the target's `sourceID` | D-3, D-4 |
| T-2 | Swift | `SourcePageModelTests.swift`: in `artifactRowActionsAndWidths` (line 2523) delete the five `ArtifactRowAction` lines, keep the two `MetadataDetailsColumn.width` lines, rename it `metadataColumnWidths`; add `moveButtonLabels` *(new)* | `moveArtifactLabel(name: "Sheet 14 (image 2)")` → "Move Sheet 14 (image 2) to another Source"; `moveGraphLabel(name: "Hale household, dwelling 113")` → "Move Hale household, dwelling 113 to another Source" | AC-1.5, D-1, D-2 |
| T-3 | Swift | `macos/ProvenenciaTests/PVSymbolTests.swift` (existing, every case) | `.folderInput` resolves | D-2. AC-1.1 – AC-1.4 (which buttons show, Open dimmed with Move enabled) are checked by eye in manual check step 2: the row and card are views with no model rule to test |
| T-4 | Swift | `SourceMoveModelTests` `opensWithTheBundle` *(new)* | `openMove(artifactID: A1)` → one preflight with target nil; `readState` `.loading` then `.ready`; `impact` the scripted one; `canMove` false; subtitle parts "Sheet 14 (image 1)", "ART-7QK2M"; an unknown id opens nothing | AC-2.1, D-5, D-6 |
| T-5 | Swift | `SourceMoveModelTests` `bundleRowsAndWhyLine` *(new)* | 1 Artifact → why false; 1 graph → false; 1 Artifact + 1 graph → false; 2 Artifacts + 2 graphs → true; seed A2 with reply order A1, A2 → `bundleArtifacts` A2, A1; a reply whose `progress` lacks G2 and lists G1 last → G1 paired with its row, G2 with nil | AC-2.1, AC-2.1b, AC-2.1c, AC-2.2, AC-2.3, D-13 |
| T-6 | Swift | `SourceMoveModelTests` `leftBehindNotes` *(new)* | `leavesSourceEmpty`/`leavesNoGraph` each true and false → each note present or nil, naming the origin's title | AC-2.4 |
| T-7 | Swift | `SourceMoveModelTests` `targetsExcludeOriginRecentFirst` *(new)* | Sources S1 (origin), S2 (updated today), S3 (last week) → `targets` S2, S3; only S1 → `targets` empty and the nowhere state; list unread (`listSourcesError` set before the session reads it) → nil | AC-2.5, AC-2.6, D-10 |
| T-8 | Swift | `SourceMoveModelTests` `pickReadsAgainAndDropsStaleReplies` *(new)* | With `getSourceMoveImpactHold` on: pick S2, pick S3, release twice (oldest first), `settleReads()` → `impactTarget` S3; `canMove` true only after S3's reply; the bundle (`impact.artifacts`) stays non-nil throughout | AC-3.1, AC-3.4, D-6 |
| T-9 | Swift | `SourceMoveModelTests` `credibilityNote` *(new)* | Reply labels "Low trust" / "" / weighed "Standard", differs true → message names "Low trust", "not assessed", "Standard"; differs false → nil | AC-3.2, AC-3.3, D-11 |
| T-10 | Swift | `SourceMoveModelTests` `readFailureAndReadAgain` *(new)* | Open read fails → `.failed(message)`, `canMove` false; clear the error, `readAgain()` → `.ready`. Then pick S2 with the error set → `.failed`; clear it, `readAgain()` → a call with target S2, `.ready`, `canMove` true; `pick("")` → no call, `canMove` false, no credibility note; `pick(S2)` twice → one call | AC-2.7, AC-3.5, D-6 |
| T-11 | Swift | `SourceMoveModelTests` `moveAppliesBothSourcesAndToasts` *(new)* | Move 2 Artifacts + 2 graphs → returns true; `leave` called once with S2; one `moveToSource` call; after `session.settleWrites()`, S1's and S2's cached `sourceWorkspace` handles are stale and no `.mutatedSourceWorkspace` was applied; `session.noticeToast` title "Moved to “{S2}”", body "2 Artifacts and 2 graphs", tone success | AC-4.1, AC-4.2, AC-4.4, D-8 |
| T-12 | Swift | `SourceMoveModelTests` `doneBodyCounts` *(new)* | (2,2) → "2 Artifacts and 2 graphs"; (1,1) → "1 Artifact and 1 graph"; (1,0) → "1 Artifact"; (0,1) → "1 graph" | AC-4.3, D-12 |
| T-13 | Swift | `SourceMoveModelTests` `moveFailureKeepsTheDialog` *(new)* | `moveToSourceError` set → returns false, `leave` not called; `moveError` "Nothing was moved. …"; `targetID` and `impact` kept; no `noticeToast` | AC-4.5 |
| T-15 | Swift | `SourcePageModelTests.swift` `workspaceFollowsSourceArtifacts` *(new)* | S1's page shown: apply effects with `source_artifacts` [S1] → the workspace reloads (one more `getSourceWorkspace` call); with `source_records` [S1] only → no reload; S1 hidden + `source_artifacts` [S1] → stale; delete an Artifact → its row gone after the reload, one `getSourceWorkspace` call for it, not two | AC-5.2, AC-5.3, AC-5.4, D-16 |
| T-16 | Swift | `macos/ProvenenciaTests/WorkspaceNavigationTests.swift` `correctingGraphSource` *(new)* | graph location S1/G1 + row G1 on S2 → S2, `sourceTitle` nil; same Source → nil; row nil or another id → nil; a `.page` location → nil; composer and Promote surfaces → corrected alike | AC-6.3, D-17 (AC-6.1 and AC-6.2's host wiring: manual check step 5) |
| T-14 | Swift | `SourceMoveModelTests` `opensFromAGraph` *(new)* | `openMove(graphID: Default)` → preflight seed `.graph`; subtitle parts "Default", its ref; `bundleGraphs` one row, `bundleArtifacts` empty; `openMove` with `source == nil` → `moving` nil | AC-2.3, D-5 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `SourcePageModelTests` (the row's actions; Artifact delete and create counting `getSourceWorkspace` calls), `TestReadsDeclare`, the "catalog reads" parity test, any test that asserts the graph card's accessibility tree.

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
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated) — S15-D10, S15-D1 and S15-D14 all move (S15-25 is the last PR each gates)
- [ ] Domain doc updated if a rule in docs/*.md changed: docs/catalog-caches.md, docs/macos-client-patterns.md (rule 2's reads), core/database/effects/README.md (the new read), add-workspace-place § 6; move-artifact-between-sources.md Status, "Navigation" and "Search and caches" notes
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

Makes bar 8 true: "**Move to another Source…** from an Artifact or a graph shows everything that moves together, keeps every ref, and the moved Citations then read the target Source."

1. In a dogfood project copy, open a census Source with two images whose household graphs share one image (or make one: link a graph to two images). Note the refs of both images and graphs, and a Citation on one of them. Make a second census Source.
2. Each image row shows Set cover (when offered), Edit, Move, Delete; each graph card Open, Edit, Move, Delete, Open dimmed on a Default graph with no Artifact (AC-1.1, AC-1.2, AC-1.3, AC-1.4). Right-clicking a row or a card opens nothing. Each button does its action. With VoiceOver on, the Move buttons read "Move … to another Source" (AC-1.5).
3. Choose Move on the image: the dialog lists both images and both graphs with "Moves together" and the why line. Pick the second Source; if the two credibility grades differ, the note names both.
4. Press Move: the second Source's page opens at its top; the Toast says "Moved to “…”" and "2 Artifacts and 2 graphs". The rows are there with the same refs.
5. Open the Person page of someone in a moved graph; open a value's provenance sheet: the moved Citation's citation reads the second Source's title. Go Back to the first Source: it lists neither image nor graph; if both were all it had, it shows "Default" and no Artifacts. Before step 3, open the moved graph's canvas once and return; after the move, go Back through history to that canvas entry: it opens the graph with the second Source in its breadcrumb (AC-6.1).
6. Window at 1366 and at 2560 wide: the buttons and the dialog look the same (MV-W1).
7. On a Source page, edit the title, the date and a metadata value: the page does not flash or reload. Add a fileless Artifact and delete it: the list updates (AC-5.2 – AC-5.4).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A create or delete reloads the page twice (the effects and a leftover hand re-read) | D-16 deletes the hand re-reads; T-15 counts the reads |
| The graph list is not cached when an old graph entry opens | D-17 corrects as soon as the list loads (`onChange(initial:)`); AC-6.3 covers the uncached case |
| The board draws something the Decisions do not cover | The Decisions win where they are explicit; anything else follows the board, and a disagreement is a Stop condition |

**Stop and report if:**

- Removing the row's menu leaves a UI test or accessibility test that opens it (`sources.page.artifact.<id>.menu`): report it rather than keep the menu.

- `SourcePageArtifactRow`, `SourcePageGraphRow` or `SourceCopyDialog.swift` no longer read as § 4 says.
- `WorkspaceSession.apply(_:_:)` or `noticeToast` no longer exist or no longer survive `navigation.go(to:)`.
- Another write path already reports a read named `source_artifacts`, or `onField("source_id", …)` does not fire on an Artifact create or delete (T-0 red): D-15 would be wrong.
- `apply(_:_:leavingPage:)` no longer hides the leaving page's keys before applying.
- `replaceCurrent(with:)` pushes a history entry or re-mounts the place in a loop when called from the destination host.
- After D-17 the canvas visibly draws the old Source's title before the correction lands: report it with what you saw; do not add a second correction inside `EvidenceGraphModel`.
- The kit's `PVComboBox` cannot hold 3,000 options without a visible stall when opened (Scale).
- A test needs `EngineErrorCode` to branch on a `sourcemove.*` code (D-9 would be wrong).

## 12. Open questions

None.

## 13. PR

**Title:** S15-25 — Move from an Artifact or a graph
**Body:** objective in one sentence; what shipped against US-1 – US-4; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-25-move-from-artifact-or-graph.md`.
