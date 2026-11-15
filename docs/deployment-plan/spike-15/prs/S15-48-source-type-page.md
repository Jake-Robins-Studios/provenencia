# S15-48 — Source types open on their own page

**Status:** Blocked — on board S15-D27 (OQ-1, OQ-2 are answered by the board)
**Spike / slice:** Spike 15 · Slice 2 — Metadata at three levels
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D27](../design/S15-D27-source-type-page.md), board not drawn yet
**Board:** — (to be drawn on [Claude Design — Source Types](https://claude.ai/artifact/R94Wfp97eC9cBLaSNBQEga), page *S2-03 Source Types Board*, section 06 "A type's own page"; filled in when the board is agreed)
**Depends on:** S15-47 (landed [#843](https://github.com/mendahu/provenencia/pull/843)), S15-D27
**Blocks:** S15-49, S15-12, S15-17
**Branch:** `s15-48-source-type-page`
**Version bump:** patch, 0.15.1 → **0.15.2** (or the next patch after `main`'s `VERSION` when you rebase): `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj` — a Mac UI change to an existing destination, no new capability and no wire change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md), [`add-workspace-location`](../../../../.agents/skills/add-workspace-location/SKILL.md), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/swift-tests.mdc`, `.cursor/rules/macos-client.mdc`
**Context:** working rules "A Source type has its own page" and "No engineering for two windows editing the same data" ([map](../deployment-plan.md#working-rules)); [`docs/macos-client-patterns.md`](../../../macos-client-patterns.md) (cache rule 2, the mutation list); [`docs/design-system-layers.md`](../../../design-system-layers.md)
**Planned:** 2026-11-15 against `main` @ `bb94086` (draft; step 4 is rechecked when the board is agreed)
**Review:** — (not reviewed yet; review-plan runs once the board is agreed and OQ-1, OQ-2 are closed)

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

A Source type opens on its own page instead of in a 380pt side pane beside the list. A click on a row in the Source types list (or Return on the highlighted row) opens the type's page, a deep place under Source types with the crumb "Source types › Census", reached the same way from the omnibar, Back and Forward, a relaunch and a delete-impact link. The page holds what the side pane held: the header with delete, the details form (Label, Icon, Description, Save, Revert), the locked note on a plugin's type and the Source-level suggested fields. Leaving the page with unsaved details asks first (user, 2026-11-15).

**Why now.** The side pane has no room for S15-12's three suggestion lists and S15-17's three formats (working rule "A Source type has its own page", user 2026-11-14). S15-47 already moved Add into a dialog, so the side pane holds nothing the page cannot take.

**What stays.** Every rule and word of today's side pane: the key never changes, Save is disabled until something changed, a plugin's type is read-only, the delete check, the suggestion picker, the "Type updated", "Field assigned" and "Suggestion removed" toasts. The list's header, Add type dialog, columns and sort (S15-49 redraws the list). The Metadata page and its side pane.

## 2. User stories

**US-1.** As a researcher, when I click a Source type in the list, its own page opens, so I can read and edit everything about the type in one place.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | The list with Census; click the Census row | The page for Census shows; the crumb reads "Source types › Census"; the list's side pane is gone |
| AC-1.2 | The list focused, Book highlighted; press ↓ | The highlight moves to the next row; the place stays the list |
| AC-1.3 | The highlight on Census; press Return | Census's page opens |
| AC-1.4 | Census's page; Back | The list shows, scrolled where it was, no row highlighted |
| AC-1.5 | An omnibar hit "Census" (kind `source_type`) | Census's page opens |
| AC-1.6 | Census's page open; relaunch | Census's page is restored |
| AC-1.7 | A location with `typeId` of a type that no longer exists | The list shows; the history entry becomes the list (`fallbackToSectionRoot`) |
| AC-1.8 | A metadata field's delete-impact notice names Census | Its link opens Census's page |

**US-2.** As a researcher, on a type's page I edit its label, icon and description, and the list and the crumb follow at once.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Census's page, nothing changed | Save changes and Revert are disabled |
| AC-2.2 | Label "Census" → "Population census"; Save changes | One `updateSourceType` write; "Type updated" toast; the header, the crumb and the list row read "Population census"; the key stays `census` |
| AC-2.3 | Label cleared | Save is disabled; Save attempted programmatically shows "A label is required — it is how the type reads on a source." under Label |
| AC-2.4 | Label changed; Revert | The saved values come back; Save and Revert are disabled |
| AC-2.5 | Grave memorial (origin `plugin:findagrave`) | The locked note and the read-only description; no form; suggested fields read only |
| AC-2.6 | The types list reloads while the details are edited (another write, a refresh) | The draft is kept (D-4) |

**US-3.** As a researcher, I add and remove the fields a type suggests on its page, as I did in the side pane.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Book suggests Author; pick Publisher; add | Publisher is row 2; "Field assigned" toast; the list's Fields column for Book reads 2 |
| AC-3.2 | Remove Author | Author is gone; "Suggestion removed" toast; the Fields column reads 1 |

**US-4.** As a researcher, leaving a page with unsaved details asks before dropping them (user, 2026-11-15).

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | Label changed, not saved; Back (or the sidebar, a crumb, the omnibar, the history menu, Forward) | The discard confirm shows: "Discard changes?" / "Your changes will be lost." / Discard / Keep editing; the place does not change yet |
| AC-4.2 | AC-4.1, then Discard | The navigation runs; Census is unchanged |
| AC-4.3 | AC-4.1, then Keep editing | The page stays with the edit; history does not move |
| AC-4.4 | Nothing changed, or the change saved | Leaving asks nothing |
| AC-4.5 | A suggestion added, details untouched | Leaving asks nothing (suggestion writes save at once) |

**US-5.** As a researcher, deleting a type from its page returns me to the list.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-5.1 | Parish register (unused); Delete; confirm | One `deleteSourceType` write; the list shows without Parish register; no toast (user, 2026-11-15) |
| AC-5.2 | Census (used by 41 Sources); Delete | The DeleteImpact blocked notice lists what uses it; the page stays |
| AC-5.3 | Unsaved details; Delete; confirm | The list shows; no discard confirm (the type is gone) |
| AC-5.4 | Add type "Parish register" in the dialog | The new type's page opens; no toast (user, 2026-11-15) |

## 3. Scope

| In | Covered by |
| --- | --- |
| The page as a place: `.sourceTypePage` presentation, `viewIdentity` per type (TP-2, TP-10) | STEP-1, AC-1.1, AC-1.5 – AC-1.8 |
| The model split: `SourceTypesModel` (list) and `SourceTypePageModel` *(new)* | STEP-2, STEP-3 |
| Update, delete and the suggestion count on the declared row patch; `patchTypesList` deleted | STEP-2, AC-2.2, AC-3.1, AC-5.1 |
| The page view on Page columns: header, Details, locked note, Suggested fields (TP-3 – TP-7, TP-W1) | STEP-5, AC-2.1 – AC-2.5, AC-3.1, AC-3.2 |
| The leave guard (TP-8) | STEP-4, STEP-5, AC-4.1 – AC-4.5 |
| Delete from the page (TP-9) | STEP-3, STEP-5, AC-5.1 – AC-5.3 |
| The list without its side pane; rows open on click or Return (TP-1, TP-W2) | STEP-6, AC-1.1 – AC-1.4 |
| The crumb and history menu read the type's live label | STEP-1, AC-2.2 |
| The list restores its scroll on Back (`isListRoot`) | STEP-6, AC-1.4 |
| No "Type added" / "Type deleted" toasts (user, 2026-11-15) | STEP-3, STEP-6, AC-5.1, AC-5.4 |
| Docs: skills, `macos-client-patterns.md` mutation list | STEP-9 |

| Out | Home |
| --- | --- |
| The list's columns, maximum width and Wide layout | S15-49 (S15-D28) |
| `macos-client-patterns.md` § 9's row for Source types ("List with a side pane" → "List → detail page") | S15-49 (its scope entry owns it) |
| Artifact and Evidence graph suggestion lists; the Fields count across levels | S15-12 |
| Citation formats on the page | S15-17 |
| Copy from in the Add dialog | S15-18 |
| The Metadata page's list and side pane | not planned (working rule "A Source type has its own page") |
| Evicting a deleted type's cached `typeSuggestions` key (it reloads as an empty list, as today) | not planned (Edges) |
| Guarding window close, sign-out or a project switch with unsaved details | not planned (no page guards them; the composer does not either) |
| Reordering suggestions | not planned (map S15-12) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Place | `macos/App/Features/Workspace/Session/PlaceRegistry.swift` spec `.sourceTypesDetail` | `section == .sourceTypes && typeId != nil`; presentation `.sourceTypes` (the list view, which shows the side pane); `viewIdentity` nil; keys `sourceTypesList`, `metadataFieldsList`, `typeSuggestions(typeId)` |
| Place | same file, spec `.sourceTypes` | The list root; keys `sourceTypesList`, `metadataFieldsList` |
| Presentation | `macos/App/Features/Workspace/Session/WorkspacePresentationID.swift` | No case for a type page |
| Host | `macos/App/Features/Workspace/WorkspaceDestinationHost.swift` `destination(for:)`, `destinationKind(for:)` | `.sourceTypes` → `SourceTypesView` |
| Location | `macos/App/Features/Workspace/WorkspaceLocation.swift` `sourceTypePage(typeId:title:)` | Added by S15-47; its doc comment says "selected on the Source types page" |
| Location | same file, `isListRoot` | `false` for `.sourceTypes`, so the list never stamps or restores a scroll anchor |
| Crumb | `macos/App/Features/Workspace/WorkspaceToolbar.swift` `breadcrumbItems(for:names:goTo:)` | A `typeId` location's leaf is `location.ref ?? location.title ?? "…"`: the label carried when the location was made, stale after a rename |
| Names | `macos/App/Features/Workspace/WorkspaceLocationLabels.swift` `LocationNames`, `WorkspaceLocationLabels.labels(for:names:)` | Resolves Source titles and graph names only; the history menu uses `labels` |
| Session | `macos/App/Features/Workspace/Session/WorkspaceSession+Sources.swift` `source(id:)` | The one place a Source is read by id from the cached list; no type equivalent |
| View | `macos/App/Features/SourceTypes/SourceTypesView.swift` `SourceTypesView`, `SourceTypesContent` | Header, then the list beside `SourceTypesDetailPane` (380pt); `reconcileSelection(for:)` on location and list changes; toast overlay; Add dialog with `showAdded`; `pvDeleteImpact` with `fallbackToSectionRoot` |
| List | `macos/App/Features/SourceTypes/SourceTypesListPane.swift` `selection` | The table's selection binding: get `model.selectedType?.id`; set navigates (`go(to: .sourceTypePage…)`). An arrow key therefore changes the place |
| Side pane | `macos/App/Features/SourceTypes/SourceTypesDetailPane.swift` `SourceTypesDetailPane` | Header (`VocabularyPanelHeader`), delete error, locked note, form (`iconFieldButton(selection:)` + the "Choose an icon" `pvFormDialog` with `SourceTypeIconGrid`), suggested fields (`suggestionRows`, `assignControl`, `poolRow`, `poolOptions`), empty state when nothing is selected |
| Model | `macos/App/Features/SourceTypes/SourceTypesModel.swift` `SourceTypesModel` | One model for list and pane: sort, `mode: VocabularyPaneMode`, `adding`, `draft`, save, toast, suggestions, delete, `syncSelection`, `applySelection`, `clearHistorySelection`, `showAdded`, `patchTypesList` (update, assign, remove, delete), `patchSuggestions` |
| Draft | same file, `SourceTypesModel.Draft` | Label, description, icon key, `labelError`; also used by `SourceTypeAddModel` |
| Add | `macos/App/Features/SourceTypes/SourceTypeAddDialog.swift` `sourceTypeAddDialog(_:onAdded:)` | After create calls `onAdded` (the toast) then `go(to: .sourceTypePage…)` |
| Mutations | `macos/App/Features/Workspace/Session/CatalogMutation.swift` `CatalogMutation`, `invalidationKind`, `patchedSourceType` | `.createdSourceType` is the only type-row mutation; patch-only |
| Patch | `macos/App/Features/Workspace/Session/CatalogLastUpdated.swift` `CatalogQueryPatch.sourceTypeRow()`, `row(_:patched:appendsOn:)` | Replaces or appends a row; nothing removes one |
| Registry | `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift` `.sourceTypesList` | `patches: [.sourceTypeRow()]`; follows `source_vocabulary` |
| Leave guard | `macos/App/Features/Workspace/WorkspaceNavigation.swift` `WorkspaceLeaveGuard`, `leaveGuard`, `hold`, `resumeHeldNavigation`, `cancelHeldNavigation`, `fallbackToSectionRoot` | `go(to:)`, Back, Forward, `go(toIndex:)` ask the guard; `fallbackToSectionRoot` (`replaceCurrent`) does not |
| Table | `macos/App/DesignSystem/Components/Table/PVTable.swift` `PVTable` | Selection only: a click and the arrows set `selection`; no activate; Return ignored; its `LazyVStack` has no `scrollTargetLayout` |
| Vocabulary chrome | `macos/App/Features/CatalogVocabulary/VocabularyChrome.swift`, `VocabularyPane.swift` (`VocabularyPaneMode`), `VocabularyListPane.swift` | Shared by Metadata and Source types; `VocabularyPaneMode` is used by `MetadataModel` and `SourceTypesModel` only |
| Tests | `macos/ProvenenciaTests/SourceTypesModelTests.swift` | List, selection, edit, suggestions, delete, add and navigation tests on one model |
| Tests | `macos/ProvenenciaTests/PlaceRegistryTests.swift` `resolvesSourceTypesWithSelection` and the table row for `.sectionRoot(.sourceTypes)`; `WorkspaceDestinationHostTests.swift` `presentationSourceTypesRootAndRow`; `WorkspaceSessionTests.swift` `applyLocationSourceTypesWithSelection`; `CatalogQueryRegistryTests.swift` `createdSourceTypePatchesTheTypesList`; `WorkspaceToolbarBreadcrumbTests.swift` | Expect the type location on `.sourceTypes` and the list root's two keys |

**Precedent.** The Sources list → Source page: `PlaceRegistry` spec `.sourceDetail` (presentation `.sourcePage`, `viewIdentity: { $0.sourceId }`), `SourcePageView` (`.task` warms; a loading shell on `PVPageColumns(headerPinned:)`), `SourcePageModel.confirmResourceDelete(leaving:)` with `session.apply(effects, .deletedSource(id:), leavingPage: leave)`, `SourcesListView`'s `ListScrollAnchorModifier`. The leave guard: `CitationComposerView` sets `navigation.leaveGuard = model` on appear and clears it on disappear; `CitationComposerModel` conforms to `WorkspaceLeaveGuard` and answers with `resumeHeldNavigation` / `cancelHeldNavigation`; its confirm is `pvConfirm(item:)`. Copy the guard's shape, not its `PVDiscardGate` (the page holds no second step). Keyboard activation: `PVList` (`PVListKeyboard.action`, Return / Space activate).

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | **The place.** `WorkspacePresentationID.sourceTypePage` *(new)*. The `.sourceTypesDetail` spec keeps its id, match and query keys; its presentation becomes `.sourceTypePage` and `viewIdentity` `{ $0.typeId }`. The `.sourceTypes` (list) spec's keys become `[.sourceTypesList]` only (the list no longer reads fields). `WorkspaceDestinationHost.destination(for:)`: `.sourceTypePage` → `SourceTypePageView(typeID:session:userID:store:)` *(new)* when `currentLocation.typeId` is set; `destinationKind(for:)` maps `.sourceTypePage` to `.sourceTypes`. `WorkspaceLocation.sourceTypePage` doc comment: "One Source type's page." | Map Shape; the Source page precedent; one mount per type resets the draft | A second place id — the map keeps `.sourceTypesDetail` |
| D-2 | **The split.** `SourceTypesModel` keeps: `Draft`, `SortColumn`, sort state, `adding`, `openAdd()`, `isAdding`, `types`, `isLoading`, `loadError` (types handle only), `visibleTypes`, `countLine`, `sortBy`, `compare`, `typesListKey`, `warmListQueries()` (types only). Everything else leaves it (Deletes). `SourceTypePageModel` *(new)* in `macos/App/Features/SourceTypes/SourceTypePageModel.swift` *(new)*: `@MainActor @Observable final class`, `init(typeID:session:userID:store:)`; reads `type: CatalogSourceType?` through `session.sourceType(id:)` (D-6); `isLocked` (`CatalogOrigin.isPlugin(type.origin)`); `draft: SourceTypesModel.Draft?`; `isSaving`, `formError`, `toast`; the suggestion state and members today's model has (`suggestions`, `isLoadingSuggestions`, `fields`, `assignPick`, `isAssigning`, `removingFieldID`, `suggestionError`, `assignPool`, `canAssign`, `pickedField`, `assignTooltip`, `assignAccessibilityLabel`, `canEditAssociations`); `deleteImpact` and its accessors; `isDirty`, `canSubmit`, `applyDraftIconKey(_:)`, `revertEdit()`, `submit()`, `assignPickedField()`, `removeSuggestion(fieldID:)`, `askDelete()`, `confirmDelete(leaving:) -> Bool`; `warm()` queries `sourceTypesList`, `metadataFieldsList`, `typeSuggestions(typeID)`; `reconcile() -> WorkspaceLocationReconcile` (D-5) | Map Shape (`SourcesModel` / `SourcePageModel`); the bodies move, they are not rewritten | Keeping one model with a page mode — the map's K-1 answer split it |
| D-3 | **Row writes on the declared patch; `patchTypesList` goes.** `CatalogMutation.updatedSourceType(CatalogSourceType)` *(new)* and `.deletedSourceType(id: String)` *(new)*, both patch-only (`invalidationKind` nil). `patchedSourceType` returns the row of `.createdSourceType` and `.updatedSourceType`. `CatalogQueryPatch.removedSourceTypeRow()` *(new)* beside `sourceTypeRow()`: on `.deletedSourceType(id)` removes that row from the cached list (`patchCached`), else `.unchanged`; `.sourceTypesList`'s `patches` become `[.sourceTypeRow(), .removedSourceTypeRow()]`. Save applies `session.apply(effects, .updatedSourceType(updated))`. Assign and remove apply their mutation as today, then `session.apply(.empty, .updatedSourceType(row))` where `row` is the cached type with `suggestedFieldCount` set from the reply. Delete applies `session.apply(effects, .deletedSourceType(id:), leavingPage: leave)` | S15-47 review M-4 (user, 2026-11-14: update and delete here); one mechanism for list rows; the removal keeps today's instant row drop | Invalidating the list on delete, as `.deletedSource` does — the deleted row would show until the reload and today's pane drops it at once; leaving the count on `patchTypesList` until S15-12 — the map deletes `patchTypesList` here |
| D-4 | **The draft.** `SourceTypePageModel.syncDraft()` sets `draft` from `type` only while `draft == nil`; Save sets it from the reply; Revert from `type`. A later reload of the list never touches it | Rule "No engineering for two windows editing the same data"; today's `applySelection` reset the draft on every list change, which a page must not do while the researcher types | Following the cache while not dirty — no case needs it, and it adds a second rule |
| D-5 | **A missing type.** `reconcile()` returns `.ignored` until the types handle is `.ready` or has a value, `.missingDeepId` when the list has no row with `typeID`, else `.applied` (and calls `syncDraft()`). The view calls it on appear and on the handle's `status` and `value` changes; `.missingDeepId` runs `navigation.fallbackToSectionRoot()` | Today's `syncSelection` rule, on the page | Showing an empty page with an error — the list is the known fallback (AC-1.7) |
| D-6 | **One read of a type by id.** `WorkspaceSession.sourceType(id:)` *(new)* in `macos/App/Features/Workspace/Session/WorkspaceSession+Sources.swift` beside `source(id:)`. `LocationNames` gains `sourceTypeLabel: @MainActor (String) -> String?` *(new)*, a defaulted init parameter (`{ _ in nil }`), set from `session.sourceType(id:)?.label` in `init(session:)`. `WorkspaceLocationLabels.sourceTypeLabel(typeID:carried:names:)` *(new)*: live label, else the carried title, blank counts as none. `labels(for:names:)` returns it as the leaf for a `typeId` location; `breadcrumbItems` takes its leaf from `labels(for:names:)` for a `typeId` location | Map Shape; one home for crumbs and the history menu; the Source title rule | Re-stamping the location's title on rename — history entries would still hold old labels |
| D-7 | **The leave guard** (user, 2026-11-15). `SourceTypePageModel: WorkspaceLeaveGuard`: `shouldHoldNavigation(_:)` returns false unless `isDirty && !isSaving`; then sets `pendingLeave = PendingLeave()` *(new nested `Identifiable` struct)* and returns true. `discardAndLeave()` reverts the draft, clears `pendingLeave`, calls `navigation?.resumeHeldNavigation()`. `keepEditing()` clears `pendingLeave`, calls `navigation?.cancelHeldNavigation()`. `weak var navigation: WorkspaceNavigation?` is set by the view on appear, with `navigation.leaveGuard = model`, cleared on disappear when it is still the guard. The view shows `pvConfirm(item:)` with `L10n.DesignSystem.formDialogDiscardTitle`, `formDialogDiscardMessage`, `formDialogDiscardConfirm`, `formDialogDiscardKeep`, tone `.danger`, prefix `sourceTypes.page.leave` | The composer precedent; the kit's discard copy is the brief's; a delete leaves through `fallbackToSectionRoot`, which no guard holds (AC-5.3) | Silent drop (user chose ask); `PVDiscardGate` — one step, no chain |
| D-8 | **Toasts** (user, 2026-11-15). The page model owns "Type updated", "Field assigned", "Suggestion removed", drawn with `vocabularyToastOverlay(_, identifier: "sourceTypes.page.toast")`. Delete sets no toast. `SourceTypesModel.showAdded` goes and `sourceTypeAddDialog(_:onAdded:)` loses `onAdded` (`sourceTypeAddDialog(_:)`): after create it only navigates | Sources precedent: Add source and a Source delete change place with no toast | Carrying toasts across places — no mechanism, user declined |
| D-9 | **Rows open on click or Return.** `PVTable` gains `onActivate: ((Row.ID) -> Void)? = nil` *(new)*. When set: a click selects and then activates the row; Return or Space activates the selected row (`PVTableSelection.activationIndex(selected:count:) -> Int?` *(new)*, nil when nothing is selected or the table is empty); the arrows, Home, End, Page keys and type-select only move the selection. When nil, behavior is unchanged (Metadata, Properties). `VocabularyListPane` passes an `onActivate` parameter *(new, default nil)* through. `SourceTypesListPane` holds the highlight in `@State private var highlighted: String?` and passes `onActivate: { id in navigation.go(to: .sourceTypePage(typeId: id, title: model.types.first { $0.id == id }?.label)) }` | AC-1.2: an arrow must not leave the list; `PVList` has the same Return / Space contract | Navigating from the selection setter (today) — every arrow press changes place; a new list component — `PVTable` is the list S15-49 keeps |
| D-10 | **Scroll on Back.** `WorkspaceLocation.isListRoot` is `typeId == nil` for `.sourceTypes` (`.metadata`, `.properties` stay false). `PVTable`'s row `LazyVStack` gains `.scrollTargetLayout()`. `SourceTypesListPane` applies `.modifier(ListScrollAnchorModifier(anchor: navigation.currentLocation.listScrollAnchor, rowIDs: model.visibleTypes.map(\.id), isLoaded: !model.isLoading))` to its `VocabularyListPane` | Map Shape; the one scroll-anchor mechanism | A table-specific anchor — a second mechanism |
| D-11 | **Vocabulary chrome after the split.** The page reuses `VocabularyFormActions` (Save / Revert) and `VocabularyLabeledSection` (locked description). `VocabularyPaneMode` moves from `VocabularyPane.swift` into `macos/App/Features/Metadata/MetadataModel.swift` unchanged (Metadata is its only user), and `VocabularyPane.swift`'s and `VocabularyChrome.swift`'s doc comments stop naming Source types' pane. The header follows OQ-1 | Map Shape | Leaving a Metadata-only type in shared chrome |
| D-12 | **The icon field.** Follows OQ-2. Either way the grid is `SourceTypeIconGrid` and no second picker is added; the sheet path keeps today's `iconFieldButton` body and "Choose an icon" `pvFormDialog`, moved onto the page view | S15-47 Out line; one grid | — |
| D-13 | **Loading and errors.** Before the types handle exists the page draws `PVPageColumns(headerPinned: true)` with a spinner, as `SourcePageLoadingShell`. A types-list failure with no value shows a danger `PVCallout` (`L10n.Errors.message(for:)`) with identifier `sourceTypes.page.loadError` | The Source page and today's list | — |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `SourceTypePageModel` *(new)* | type / file | `SourceTypesModel` | The split itself (D-2); its members move from there |
| `SourceTypePageView` *(new)* in `macos/App/Features/SourceTypes/SourceTypePageView.swift` *(new)* | view / file | `SourcePageView`; `SourceTypesDetailPane` | A page per type; the pane's sections move in, the pane file goes |
| `WorkspacePresentationID.sourceTypePage` *(new)* | case | `.sourcePage` | One presentation per destination view |
| `CatalogMutation.updatedSourceType`, `.deletedSourceType` *(new)* | cases | `.createdSourceType`, `.updatedSource` | Extends the S15-47 patch path (D-3) |
| `CatalogQueryPatch.removedSourceTypeRow()` *(new)* | func | `sourceTypeRow()`, `row(_:patched:appendsOn:)` | `row` never removes; searched `removeAll` in `CatalogLastUpdated.swift`: no removal patch exists |
| `WorkspaceSession.sourceType(id:)` *(new)* | func | `source(id:)` | Same shape for types |
| `LocationNames.sourceTypeLabel`, `WorkspaceLocationLabels.sourceTypeLabel(typeID:carried:names:)` *(new)* | member / func | `sourceTitle`, `sourceTitle(sourceID:carried:names:)` | Same rule for types |
| `PVTable(onActivate:)`, `PVTableSelection.activationIndex(selected:count:)` *(new)* | parameter / func | `PVList(onActivate:)`, `PVListKeyboard.action` | Extends the kit table with the list's activate contract; default nil keeps every caller |
| `VocabularyListPane(onActivate:)` *(new)* | parameter | — | Pass-through |
| `SourceTypePageModel.PendingLeave` *(new)* | type | `CitationComposerModel.PendingLeave` | Feature-private, as the composer's |
| `macos/ProvenenciaTests/SourceTypePageModelTests.swift` *(new)* | tests | `SourceTypesModelTests.swift` | The page's tests move with its model |

**Builds on.** `add-workspace-place` (place registry, `viewIdentity`, cache patches, cache rule 2), `add-workspace-location` (deep id, crumbs, `isListRoot`, leave guard), S15-47's `.sourceTypeRow()` and `sourceTypePage(typeId:title:)`, the Source page.
**Deletes.** `SourceTypesDetailPane.swift` (whole file; its parts move to the page view); from `SourceTypesModel`: `mode`, `draft`, `isSaving`, `formError`, `toast`, every suggestion member, `deleteImpact` and its accessors, `selectedTypeID`, `selectedType`, `isSelectedTypeLocked`, `applyDraftIconKey`, `isDirty`, `canSubmit`, `showsDelete`, `canDeleteSelectedType`, `deleteTooltip`, `deleteAccessibilityLabel`, `pendingDeleteType`, `syncSelection`, `select`, `applySelection`, `clearHistorySelection`, `showAdded`, `revertEdit`, `submit`, `assignPickedField`, `removeSuggestion`, `askDelete`, `cancelDelete`, `confirmPendingImpact`, `patchTypesList`, `patchSuggestions`, `fieldsListKey`, `suggestionsKey`, `warmSuggestions`, `fields`; `SourceTypesContent.reconcileSelection(for:)` and its `onChange` hooks; `SourceTypesView.detailPaneWidth`; `sourceTypeAddDialog`'s `onAdded`. Strings whose last caller goes: `L10n.SourceTypes.panelEmptyTitle`, `panelEmptyBody`, `toastAddedTitle`, `toastAddedBody`, `toastDeletedTitle`, `toastDeletedBody` (and their catalog entries). Tests: `SourceTypesModelTests` `syncSelection*`, `selecting*`, `openingAndCancellingAddKeepsTheSelectionAndEdit`, `addingCarriesThePickedIconAndToasts`'s toast line, and the edit, suggestion and delete tests move to `SourceTypePageModelTests` (T-# below) rather than being deleted. Docs: the "fields/types" master–detail examples (STEP-9).
**Next adds.** S15-12 adds two lists to `SourceTypePageModel` (its D-4 per-level state) and the page's secondary column; the count patch goes through `.updatedSourceType`. S15-17 adds the formats section to the primary column. S15-49 changes only `SourceTypesListPane` columns. A later list → page vocabulary reuses `PVTable(onActivate:)`.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| Row click / Return → page | `SourceTypePageView` | New mount per `typeId` (D-1) · D-5 · loading shell (D-13) |
| Omnibar `source_type` hit, delete-impact link, history restore → `typeId` | same | same; the engine's locations already carry `typeId` (`GoStore` `WorkspaceLocation` mapping) |
| Add dialog → page of a type just created | same | The row is in the list before `go(to:)` (`.createdSourceType` patch, S15-47 Edges) |
| Page → list on delete | `SourceTypesView` | `leavingPage` hides keys first; the removal patch drops the row (D-3) |
| A plugin's type on a page | `SourceTypePageView` locked branch | AC-2.5 |
| Navigation while the page is dirty | `WorkspaceNavigation.hold` | D-7; `fallbackToSectionRoot` is not held (delete, missing type) |

### Scale

At the map's Scale: the seed's 26 types (about 30 in a project) and 63 fields. Opening a page reads the cached types list and fields list (usually warm) and one `typeSuggestions` key. Save is one write and one row patch; assign or remove is one write, one suggestions patch, one row patch; delete is one write, one row removal. Nothing loops over Sources: a type used by 500 Sources is one `usedBy` number. The list's table holds about 30 rows.

### Edges

- **Assumptions.** `reconcile()` assumes a ready types list holds every live type: a type created in another window is absent until the list reloads, so its page falls back to the list (rule "No engineering for two windows"); T-6 pins the fallback. The leave guard assumes one guard at a time: the page sets it on appear and clears it only when it is still the guard (T-9).
- **Neighbors.** Dirty details + a suggestion write: the suggestion saves, the draft stays dirty, leaving still asks (T-9). Saving in flight + Back: not held (`!isSaving`); the write finishes and patches the cache (T-9). A label edited to the same text: not dirty, no confirm.
- **Removed inputs.** A deleted type's `typeSuggestions` key follows `source_vocabulary` and reloads as an empty list for an id nothing shows (today's behavior, Out). A type deleted elsewhere while its page is open: the next list reload drops the row; D-5 sends the page to the list.
- **Real data.** None — no table-driven rule.
- **Untrusted size.** None — the app wrote every row.

### Schema

None — no catalog change.

### Go core

None — no engine change.

### FFI

None — the page uses today's `updateSourceType`, `deleteSourceType`, `assignTypeField`, `removeTypeField`, `listTypeSuggestions`, `getDeleteImpact`.

### macOS

From the brief's inventory (S15-D27 § 6); frames are filled in from the board.

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Page layout | `PVPageColumns(headerPinned: true, scrollResetKey: typeID)` | `SourceTypePageView` | Regular: Details then Suggested fields in the primary; Wide: Suggested fields in `secondary` (TP-W1) |
| Header | OQ-1 | `SourceTypePageView` | Eyebrow, delete, mark, label, origin, key, usage, key hint |
| Section titles | `PVSectionHeader` | same | "Details", "Suggested fields" (OQ-3 for the "Details" string) |
| Details | `PVField` + `PVInput`; icon field (OQ-2); `VocabularyFormActions` | same | Identifiers keep `sourceTypes.form.*` |
| Locked note | `PVCallout(tone: .neutral, icon: .lock)` + `VocabularyLabeledSection` | same | Today's |
| Suggested fields | today's rows, empty card, picker, hints | same | Moved from the pane; identifiers keep `sourceTypes.suggested.*` |
| Delete | `PVIconButton` + `pvDeleteImpact(flow:accessibilityIdentifierPrefix:onConfirm:onNavigate:)` | same | `onConfirm` awaits `model.confirmDelete(leaving: navigation.fallbackToSectionRoot)` |
| Leave confirm | `pvConfirm(item:)` | same | D-7 |
| Toast | `vocabularyToastOverlay` | same | D-8 |
| List | `VocabularyListPane` + `PVTable(onActivate:)` | `SourceTypesListPane` | D-9, D-10; `SourceTypesView` drops the `HStack` and the pane |

States: loading (D-13), list failure (D-13), missing type (D-5), suggestions loading (spinner, today's), suggestion error (Callout), save error (under Label), delete error (Callout under the header). Accessibility: the page root `accessibilityIdentifier("sourceTypes.page")`; the header's delete reads "Delete Census"; the list rows keep `.isButton` and gain activation by Return; VoiceOver's default action on a row activates when `onActivate` is set.

### Strings

L10n keys *(new)*: OQ-3 (a "Details" section title, if the board draws one; else none). The leave confirm reuses `L10n.DesignSystem.formDialogDiscard*`. Removed: `L10n.SourceTypes.panelEmptyTitle`, `panelEmptyBody`, `toastAddedTitle`, `toastAddedBody`, `toastDeletedTitle`, `toastDeletedBody` and their `Localizable.xcstrings` entries. Old-scope copy to check: `L10n.SourceTypes.description` (the list's header line) and `keyHintEdit` name no side pane; no change.

## 7. Steps

**STEP-1 — The place, the presentation and live crumbs**
Files: `PlaceRegistry.swift`, `WorkspacePresentationID.swift`, `WorkspaceDestinationHost.swift`, `WorkspaceLocation.swift`, `WorkspaceLocationLabels.swift`, `WorkspaceToolbar.swift`, `WorkspaceSession+Sources.swift`, tests `PlaceRegistryTests.swift`, `WorkspaceDestinationHostTests.swift`, `WorkspaceToolbarBreadcrumbTests.swift`, `WorkspaceNavigationTests.swift`. Skills: `add-workspace-place`, `add-workspace-location`.
Do: D-1 (the host's `.sourceTypePage` arm mounts a placeholder `SourceTypesView` until STEP-5 replaces it), D-6, D-10's `isListRoot` line.
Check: `xcodebuild test` passes T-1, T-2, T-3, T-4.

**STEP-2 — Row writes on the declared patch**
Files: `CatalogMutation.swift`, `CatalogLastUpdated.swift`, `CatalogQueryRegistry.swift`, `CatalogQueryRegistryTests.swift`. Skill: `add-workspace-place` (Patch).
Do: D-3's mutations, `patchedSourceType`, `removedSourceTypeRow()`, the registry's `patches`.
Check: T-5 passes.

**STEP-3 — `SourceTypePageModel`**
Files: `SourceTypePageModel.swift` *(new)*, `SourceTypesModel.swift`, `SourceTypeAddDialog.swift`, `SourceTypePageModelTests.swift` *(new)*, `SourceTypesModelTests.swift`. Skill: `add-swift-test`.
Do: D-2, D-3 (the model's writes), D-4, D-5, D-8; move the edit, suggestion and delete tests. `SourceTypesModel` keeps only D-2's list. The side pane still compiles against what is left only until STEP-5: delete `SourceTypesDetailPane.swift` in this step and drop it from `SourceTypesView` (the list shows alone; rows still navigate through today's binding).
Check: T-6, T-7, T-8, T-10 pass; `SourceTypesModelTests` passes.

**STEP-4 — The leave guard**
Files: `SourceTypePageModel.swift`, `SourceTypePageModelTests.swift`.
Do: D-7's model half.
Check: T-9 passes.

**STEP-5 — The page view**
Files: `SourceTypePageView.swift` *(new)*, `WorkspaceDestinationHost.swift`. Skills: `add-ui-component`, `add-localized-string`.
Do: the page per § 6 macOS and the board's frames 2 – 13; D-7's view half, D-8, D-11 (reuse), D-12, D-13; the host's arm mounts `SourceTypePageView`.
Check: build passes; the page matches frames 2a / 2b, 7a / 7b at Regular and Wide in the app.

**STEP-6 — The list opens pages**
Files: `PVTable.swift`, `PVTableTests.swift`, `VocabularyListPane.swift`, `SourceTypesListPane.swift`, `SourceTypesView.swift`. Skill: `add-ui-component`.
Do: D-9, D-10 (the modifier and `scrollTargetLayout`). `SourceTypesView` is the header and the list only; its toast overlay, `pvDeleteImpact` and reconcile hooks go; `sourceTypeAddDialog($model.adding)`.
Check: T-11 passes; in the app, ↓ moves the highlight without leaving the list; Return opens the page; Back returns to the scroll.

**STEP-7 — Vocabulary chrome**
Files: `VocabularyPane.swift`, `VocabularyChrome.swift`, `MetadataModel.swift`.
Do: D-11 (move `VocabularyPaneMode`, fix doc comments; the header per OQ-1).
Check: build passes; `MetadataModelTests` passes.

**STEP-8 — Strings**
Files: `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`. Skill: `add-localized-string`.
Do: § 6 Strings.
Check: `rg "SourceTypes\.(panelEmpty|toastAdded|toastDeleted)" macos` finds nothing; `L10nResolutionTests` passes.

**STEP-9 — Docs and version**
Files: `.agents/skills/add-workspace-place/SKILL.md` (§ 5 "Master–detail selection (fields/types)" → "(fields)"; the leaving-page sentence: Source types is now a page whose delete leaves with `apply(_:_:leavingPage:)`), `.agents/skills/add-workspace-location/SKILL.md` (the "fields/types pattern" row → "fields pattern"; § "a master–detail page (Metadata, Source types, Properties)" → "(Metadata, Properties)"; the leave guard names the Source type page beside the composer), `docs/macos-client-patterns.md` (the mutation list: `.updatedSourceType` and `.deletedSourceType` beside `.createdSourceType`; drop the clause that `patchTypesList` still serves update, assign, remove and delete), `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj`; `completed.md`, `deployment-plan.md` (map row), this plan, `design/` (brief → `design/archive/`, `design/README.md`).
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-48-source-type-page.md` and `scripts/check-guidance-names.py` pass; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Open each Source type on its own page."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `PlaceRegistryTests.swift` `resolvesSourceTypesWithSelection` (changed), the table row for `.sectionRoot(.sourceTypes)` (changed) | `typeId: "typ-1"` → `.sourceTypesDetail`, presentation `.sourceTypePage`, `viewIdentity == "typ-1"`, keys unchanged; the root → keys `[.sourceTypesList]` | D-1 |
| T-2 | Swift | `WorkspaceDestinationHostTests.swift` `presentationSourceTypesRootAndRow` (changed) | root → `.sourceTypes`; `typeId` → `.sourceTypePage`; `destinationKind(.sourceTypePage) == .sourceTypes` | D-1, AC-1.1 |
| T-3 | Swift | `WorkspaceToolbarBreadcrumbTests.swift` `sourceTypeLeafReadsTheLiveLabel` *(new)* | names `{ "typ-1" → "Population census" }`, location title "Census" → leaf "Population census"; `.none` → "Census"; blank live → carried; `labels(for:names:)` gives the same leaf | D-6, AC-2.2 |
| T-4 | Swift | `WorkspaceNavigationTests.swift` `sourceTypesListIsAListRoot` *(new)* | `.sectionRoot(.sourceTypes).isListRoot == true`; with `typeId` false; `.metadata` false; noting a scroll on the root, going to a page and Back restores the anchor | D-10, AC-1.4 |
| T-5 | Swift | `CatalogQueryRegistryTests.swift` `updatedAndDeletedSourceTypePatchTheTypesList` *(new)* | cached [Book, Census]; `.updatedSourceType(Census')` → row replaced, no append for an unknown id; `.deletedSourceType(id: Book)` → [Census']; neither invalidates | D-3 |
| T-6 | Swift | `SourceTypePageModelTests.swift` `reconcileWaitsForTheListThenAppliesOrFallsBack` *(new)* | handle loading → `.ignored`; ready with the type → `.applied`, draft set; ready without → `.missingDeepId` | D-5, AC-1.7 |
| T-7 | Swift | same, `saveUpdatesTheRowAndKeepsTheKey` *(new)*; `revertRestoresTheSavedValues` *(moved)*; `aListReloadKeepsTheDraft` *(new)*; `pluginTypeIsLocked` *(moved)*; `blankLabelRefusesSave` *(moved)* | label → "Population census", submit → store called once, cached row label updated, key `census`, toast "Type updated"; Revert → draft equals type; replacing the cached list value leaves a dirty draft; plugin → `isLocked`, `canEditAssociations == false`; blank → `formError` = the required message, no store call | AC-2.1, AC-2.2, AC-2.3, AC-2.4, AC-2.5, AC-2.6, D-4 |
| T-8 | Swift | same, `assigningAndRemovingPatchTheFieldsCount` *(moved from `assigningAppendsTheFieldAndUpdatesTheListCount` and the remove tests)* | assign Publisher → suggestions [Author, Publisher], cached row `suggestedFieldCount == 2`, toast "Field assigned"; remove Author → count 1, toast "Suggestion removed" | AC-3.1, AC-3.2, D-3 |
| T-9 | Swift | same, `leavingAsksOnlyWhileDirty` *(new)* | clean → `shouldHoldNavigation(.back) == false`; dirty → true and `pendingLeave != nil`; `keepEditing()` → `pendingLeave == nil`, navigation unchanged; `discardAndLeave()` → draft reverted, held Back performed; dirty while saving → false; a suggestion write leaves a clean draft clean | D-7, AC-4.1, AC-4.2, AC-4.3, AC-4.4, AC-4.5 |
| T-10 | Swift | same, `deletingLeavesAndDropsTheRow` *(moved from `confirmingDeleteDropsTheTypeAndItsSuggestions`)*; `typeUsedByTwoSourcesShowsInboundNotice` *(moved)* | unused → `confirmDelete(leaving:)` returns true, `leave` ran once, cached list lacks the row, `toast == nil`; the same with a dirty draft → `leave` ran, no `pendingLeave`; used → the request shows inbound rows | AC-5.1, AC-5.2, AC-5.3, D-8 |
| T-11 | Swift | `PVTableTests.swift` `activationIndexNeedsASelection` *(new)* | (selected −1, count 3) → nil; (1, 3) → 1; (0, 0) → nil | D-9, AC-1.3 |
| T-12 | Swift | `SourceTypesModelTests.swift` `createAndDeleteCommitThroughWorkspaceNavigation` (changed) | add → `go(to: .sourceTypePage(typeId:title:))` → current location's `typeId` is the new id; no `toast` on the list model | AC-5.4 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `SourceTypesModelTests`, `PlaceRegistryTests`, `WorkspaceDestinationHostTests`, `CatalogQueryRegistryTests`, `MetadataModelTests` (D-11), `PVTableTests`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left (`SourceTypesDetailPane`, `patchTypesList`, `syncSelection` on Source types, `showAdded`, `fields/types`); `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches the brief inventory and the board's frames at Regular and Wide; no new kit primitive (PVTable gains a parameter only)
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief S15-D27 moved to design/archive/ and design/README.md updated
- [ ] Domain doc updated: docs/macos-client-patterns.md mutation list; add-workspace-place and add-workspace-location (STEP-9)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

Use a project with the seed's types, Census used by Sources, and the plugin fixture's Grave memorial if present.

1. Source types: no side pane. ↓ twice: the highlight moves, the crumb stays "Source types". Return: the highlighted type's page opens (AC-1.2, AC-1.3).
2. Scroll the list down, click Census: "Source types › Census"; Back: the list at the same scroll, nothing highlighted (AC-1.1, AC-1.4).
3. On Census, rename to "Population census", Save: toast; crumb, header and list row follow; key `census` (AC-2.2).
4. Change the description, press Back: the discard confirm; Keep editing stays; Back again, Discard: the list, the description unchanged (AC-4.1 – AC-4.3). Repeat with the sidebar and the omnibar.
5. Add Publisher to a type's suggestions, then Back: no confirm (AC-4.5); the list's Fields column moved (AC-3.1).
6. Omnibar "census" → the page (AC-1.5). Quit and relaunch on the page → restored (AC-1.6).
7. Add type "Parish register" → its page, no toast (AC-5.4). Delete it → the list without it, no toast (AC-5.1). Delete on Census → blocked notice (AC-5.2).
8. Metadata page: delete a field a type suggests → its impact link opens the type's page (AC-1.8).
9. Resize across 1600pt on Census with an unsaved edit: Regular one column, Wide two columns, the edit kept (TP-W1).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| `ListScrollAnchorModifier` does not reach `PVTable`'s internal `ScrollView` | D-10 adds `scrollTargetLayout`; Stop condition below |
| A second leave guard (composer) left installed | The page sets its own on appear; the composer clears its own on disappear (precedent) |
| `onActivate` changes Metadata or Properties | Default nil keeps the old path (T-11, `MetadataModelTests`) |

**Stop and report if:**

- A **Current state** row is no longer true at your base.
- The agreed board draws something D-1 – D-13 contradict (a side pane, an inspector, toasts after Add or Delete, a header slot the plan does not name).
- `ListScrollAnchorModifier` on `SourceTypesListPane` does not restore the scroll with `scrollTargetLayout` on `PVTable`'s rows: report; do not add a second anchor mechanism.
- `WorkspaceNavigation.hold` does not see a sidebar or omnibar move (it bypasses `go(to:)`): report the path.
- Moving `VocabularyPaneMode` breaks a caller outside `Features/Metadata/`.

## 12. Open questions

- **OQ-1 — The header (board).** Reuse `VocabularyPanelHeader` at page width, or a page header in `Features/SourceTypes/` (then `VocabularyPanelHeader` moves into `Features/Metadata/`, map Shape). Recommendation: reuse, if the board's header is the same content. Answered by the agreed board.
- **OQ-2 — The icon field (board, TP-4).** Today's button + "Choose an icon" sheet, or the grid inline. Recommendation: the button + sheet, which keeps the Details form short. Answered by the agreed board.
- **OQ-3 — A "Details" section title (board).** If the board draws one, `L10n.SourceTypes.detailsSectionLabel` *(new)* = "Details". Answered by the agreed board.

## 13. PR

**Title:** S15-48 — Source types open on their own page
**Body:** objective in one sentence; what shipped against US-1 – US-5; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-48-source-type-page.md`.
