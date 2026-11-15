# S15-48 — Source types open on their own page

**Status:** Planned
**Spike / slice:** Spike 15 · Slice 2 — Metadata at three levels
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D27](../design/S15-D27-source-type-page.md), board agreed 2026-11-15 (user)
**Board:** [Claude Design — Source Type Page](https://claude.ai/artifact/42ZuWus4ynyz7xUDwcF6zG): artboard *S15-D27 · Source type page board* (frames 2, 2b, 3 – 13 and its decision notes), the component *Source type page · component* (`Source-Type-Page.dc.html`) and *Source type icon grid* (`Source-Type-Icon-Grid.dc.html`). Board decisions: TP-4 is today's Change icon button opening the "Choose an icon" sheet; TP-3 is a new `SourceTypePageHeader`; TP-W1 is one layout at every width (Details 560pt beside Suggested fields, the pair centred). Agreed without Wide, failure or list frames (user, 2026-11-15): Wide is the same centred pair; failures use the existing field error, Callouts and retry callout; the list is today's minus its side pane. Open the link in a browser; if you cannot, D-11, D-13, D-15, D-16 and § 6 macOS describe each frame
**Depends on:** S15-47 (landed [#843](https://github.com/mendahu/provenencia/pull/843)), S15-D27
**Blocks:** S15-49, S15-12, S15-17, S15-18 (`SourceTypeDraft`)
**Branch:** `s15-48-source-type-page`
**Version bump:** patch, 0.15.1 (today's `VERSION`) → **0.15.2** (or the next patch after `main`'s `VERSION` when you rebase): `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj` — a Mac UI change to an existing destination, no new capability and no wire change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md), [`add-workspace-location`](../../../../.agents/skills/add-workspace-location/SKILL.md), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/swift-tests.mdc`, `.cursor/rules/macos-client.mdc`
**Context:** working rules "A Source type has its own page" and "No engineering for two windows editing the same data" ([map](../deployment-plan.md#working-rules)); [`docs/macos-client-patterns.md`](../../../macos-client-patterns.md) (cache rule 2, the mutation list, cache rule 4); [`S15-12`](S15-12-type-suggestions-at-each-level.md) D-1 (`markStale`), D-2 and D-5, which this PR lands at the Source level (user, 2026-11-15); [`docs/design-system-layers.md`](../../../design-system-layers.md)
**Planned:** 2026-11-15 against `main` @ `bb94086` (macOS unchanged since; docs only)
**Review:** [`S15-48-source-type-page.review.md`](S15-48-source-type-page.review.md) — Fits with changes — Ready with changes: rounds 1 – 2; no open blocker or To user item

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

A Source type opens on its own page instead of in a 380pt side pane beside the list. A click on a row in the Source types list (or Return on the highlighted row) opens the type's page, a deep place under Source types with the crumb "Source types › Census", reached the same way from the omnibar, Back and Forward, a relaunch and a delete-impact link. The page holds what the side pane held: its own header with delete, the Details form (Label, Icon, Description, Save, Revert), the locked note on a plugin's type and the Source-level suggested fields. Leaving the page with unsaved details asks first (user, 2026-11-15). A suggestion add or remove patches the cache from its reply instead of reloading (S15-12's D-2, pulled forward; user, 2026-11-15).

**Why now.** The side pane has no room for S15-12's three suggestion lists and S15-17's three formats (working rule "A Source type has its own page", user 2026-11-14). S15-47 already moved Add into a dialog, so the side pane holds nothing the page cannot take.

**What stays.** Every rule of today's side pane: the key never changes, Save and Revert are disabled until something changed, a plugin's type is read-only, Delete is always enabled and DeleteImpact decides, the suggestion picker, the "Type updated", "Field assigned" and "Suggestion removed" toasts. The list's header, Add type dialog, columns and sort (S15-49 redraws the list). The Metadata page and its side pane.

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
| AC-1.7 | A location with `typeId` of a type that no longer exists | The page leaves for the list (`.leavesForSectionRoot`) |
| AC-1.8 | A metadata field's delete-impact notice names Census | Its link opens Census's page |

**US-2.** As a researcher, on a type's page I edit its label, icon and description, and the list and the crumb follow at once.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Census's page, nothing changed | Save changes and Revert are disabled |
| AC-2.2 | Label "Census" → "Population census"; Save changes | One `updateSourceType` write; "Type updated" toast; the header, the crumb and the list row read "Population census"; the key stays `census` |
| AC-2.3 | Label cleared; submit | No store call; "A label is required — it is how the type reads on a source." under Label |
| AC-2.4 | Label changed; Revert | The saved values come back; Save and Revert are disabled |
| AC-2.5 | Grave memorial (origin `plugin:findagrave`) | The locked note and the read-only description; no form; suggested fields read only; Delete shown |
| AC-2.6 | The types list reloads while the details are edited | The draft is kept (D-4) |

**US-3.** As a researcher, I add and remove the fields a type suggests on its page, with no reload.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Book suggests Author; pick Publisher; add | One `assignTypeField` write; Publisher is row 2; "Field assigned" toast; the list's Fields column for Book reads 2; no reload of Book's suggestions |
| AC-3.2 | Remove Author | One `removeTypeField` write; Author is gone; "Suggestion removed" toast; the Fields column reads 1 |
| AC-3.3 | A Source page of a Book Source is cached | It is marked stale by the write (its suggested rows derive from the type) |

**US-4.** As a researcher, leaving a page with unsaved details asks before dropping them (user, 2026-11-15).

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | Label changed, not saved; Back (or the sidebar, a crumb, the omnibar, the history menu, Forward) | The kit's discard confirm shows; the place does not change yet |
| AC-4.2 | AC-4.1, then Discard | The navigation runs; Census is unchanged |
| AC-4.3 | AC-4.1, then Keep editing | The page stays with the edit; history does not move |
| AC-4.4 | Nothing changed, or the change saved | Leaving asks nothing |
| AC-4.5 | A suggestion added, details untouched | Leaving asks nothing |

**US-5.** As a researcher, deleting a type from its page returns me to the list.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-5.1 | Parish register (unused); Delete; confirm | One `deleteSourceType` write; the list shows without Parish register; no toast (user, 2026-11-15) |
| AC-5.2 | Census (used by 41 Sources); Delete | The DeleteImpact blocked notice lists what uses it; the page stays |
| AC-5.3 | Unsaved details; Delete; confirm | The list shows; no discard confirm |
| AC-5.4 | Add type "Parish register" in the dialog | The new type's page opens; no toast (user, 2026-11-15) |

## 3. Scope

| In | Covered by |
| --- | --- |
| The page as a place: `.sourceTypePage` presentation, `viewIdentity` per type (TP-2, TP-10) | STEP-1, AC-1.1, AC-1.5, AC-1.6, AC-1.8 |
| `WorkspaceSession+SourceTypes.swift`: a type by id and its presence; the gone page leaves (TP-10) | STEP-1, AC-1.7 |
| The crumb and history menu read the type's live label | STEP-1, AC-2.2 |
| Type row writes on the declared row patch; `patchTypesList` deleted | STEP-2, AC-2.2, AC-5.1 |
| Suggestion writes on one mutation and two descriptor patches; `.typeSuggestions` marks stale when hidden (S15-12 D-1 half, D-2, D-5 at the Source level; user, 2026-11-15) | STEP-3, AC-3.1, AC-3.2, AC-3.3 |
| The model split: `SourceTypesModel` (list), `SourceTypePageModel` *(new)*, `SourceTypeDraft` hoisted | STEP-4 |
| The leave guard, with one install modifier shared with the composer and Promote (TP-8) | STEP-5, STEP-7, AC-4.1 – AC-4.5 |
| `PVColumnSplit`: the page container takes its column widths and wrapping as parameters (user, 2026-11-15) | STEP-6, T-13 |
| The page view on Page columns: its header, Details, locked note, one suggestion list (TP-3 – TP-7, TP-W1) | STEP-7, AC-2.1, AC-2.5, AC-3.1 |
| Delete from the page (TP-9) | STEP-4, STEP-7, AC-5.1 – AC-5.3 |
| The list without its side pane; rows open on click or Return; scroll on Back (TP-1, TP-W2) | STEP-8, AC-1.1 – AC-1.4 |
| No "Type added" / "Type deleted" toasts (user, 2026-11-15) | STEP-4, STEP-8, AC-5.1, AC-5.4 |
| `VocabularyPanelHeader` loses its Source-type-only parameters; `VocabularyPaneMode` moves to Metadata | STEP-9 |
| Strings, docs, version | STEP-7, STEP-10 |

| Out | Home |
| --- | --- |
| The list's columns, maximum width and Wide layout | S15-49 (S15-D28) |
| `macos-client-patterns.md` § 9's row for Source types ("List with a side pane" → "List → detail page") | S15-49 (its scope entry owns it) |
| Artifact and Evidence graph suggestion lists; the `level` on the suggestion key and mutation; the count across levels | S15-12 |
| Citation formats on the page | S15-17 |
| Copy from in the Add dialog | S15-18 |
| The Metadata page's list and side pane | not planned (working rule "A Source type has its own page") |
| Routing `PVTable`'s arrow keys through `PVListKeyboard` (only Return / Space are, D-9) | not planned (the clamping rules differ; `PVTableSelectionTests` pin today's) |
| Guarding window close, sign-out or a project switch with unsaved details | not planned (no page guards them) |
| Moving `SourcePageOverviewLayout` and `ConclusionPinnedSideColumn` onto `PVColumnSplit` | not planned here; offered to the user as a separate task (2026-11-15) |
| Reordering suggestions | not planned (map S15-12) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Place | `macos/App/Features/Workspace/Session/PlaceRegistry.swift` spec `.sourceTypesDetail` | `section == .sourceTypes && typeId != nil`; presentation `.sourceTypes` (the list view, which shows the side pane); `viewIdentity` nil; keys `sourceTypesList`, `metadataFieldsList`, `typeSuggestions(typeId)` |
| Place | same file, spec `.sourceTypes` | The list root; keys `sourceTypesList`, `metadataFieldsList` |
| Presentation | `macos/App/Features/Workspace/Session/WorkspacePresentationID.swift` | No case for a type page |
| Host | `macos/App/Features/Workspace/WorkspaceDestinationHost.swift` `destination(for:)`, `destinationKind(for:)` | `.sourceTypes` → `SourceTypesView` |
| Location | `macos/App/Features/Workspace/WorkspaceLocation.swift` `sourceTypePage(typeId:title:)`, `isListRoot` | Added by S15-47 ("selected on the Source types page"); `isListRoot` is `false` for `.sourceTypes` |
| Crumb | `macos/App/Features/Workspace/WorkspaceToolbar.swift` `breadcrumbItems(for:names:goTo:)` | A `typeId` location's leaf is `location.ref ?? location.title ?? "…"`, stale after a rename |
| Names | `macos/App/Features/Workspace/WorkspaceLocationLabels.swift` `LocationNames`, `WorkspaceLocationLabels.labels(for:names:)`, `sourceTitle(live:carried:)` | Source titles and graph names only; `sourceTitle(live:carried:)` is the one "live, else carried" rule (also called by `PromoteModel`) |
| Session | `macos/App/Features/Workspace/Session/WorkspaceSession+EvidenceGraphs.swift` `evidenceGraph(id:)`, `evidenceGraphPresence(id:)`, `EvidenceGraphPresence` | The presence read a page uses to leave when its entity is gone |
| Gone page | `macos/App/Features/Workspace/WorkspaceNavigation.swift` `leavesForSectionRoot(when:notice:)` | Used by `SourcePageView`, `ConclusionDetailPage`, `EvidenceGraphView` |
| Leave guard | same file, `WorkspaceLeaveGuard`, `leaveGuard`, `hold`, `resumeHeldNavigation`, `cancelHeldNavigation`, `fallbackToSectionRoot` | `go(to:)`, Back, Forward, `go(toIndex:)` ask the guard; `fallbackToSectionRoot` does not. `CitationComposerView` and `PromoteView` each install the guard with the same lines in `onAppear` / `onDisappear` and set `model.navigation` |
| View | `macos/App/Features/SourceTypes/SourceTypesView.swift` `SourceTypesView`, `SourceTypesContent` | Header, then the list beside `SourceTypesDetailPane` (`detailPaneWidth` 380); `reconcileSelection(for:)`; toast overlay; `sourceTypeAddDialog($model.adding) { model.showAdded($0) }`; `pvDeleteImpact` |
| List | `macos/App/Features/SourceTypes/SourceTypesListPane.swift` `selection` | Get `model.selectedType?.id`; set navigates, so an arrow key changes the place |
| Side pane | `macos/App/Features/SourceTypes/SourceTypesDetailPane.swift` | Header (`VocabularyPanelHeader`), delete error, locked note, form (`PVInput` description; `iconFieldButton(selection:)` + the "Choose an icon" `pvFormDialog`), suggested fields (`suggestedFields(isLocked:)`, `emptySuggestions`, `suggestionRows`, `assignControl`, `poolRow`, `poolOptions`, `assignListMaxHeight`) |
| Model | `macos/App/Features/SourceTypes/SourceTypesModel.swift` | One model for list and pane (`mode: VocabularyPaneMode`, draft, save, toast, suggestions, delete, `syncSelection`, `showAdded`, `patchTypesList`, `patchSuggestions`); `Draft` nested, also used by `SourceTypeAddModel.swift` |
| Suggestion writes | same file, `assignPickedField()`, `removeSuggestion(fieldID:)` | `session.apply(.assignedTypeSuggestion…)` invalidates the visible key, then `patchSuggestions` (`setQueryValue`) restarts the load; the count goes through `patchTypesList` |
| Mutations | `macos/App/Features/Workspace/Session/CatalogMutation.swift` | `.createdSourceType` (patch-only), `.assignedTypeSuggestion`, `.removedTypeSuggestion` (kinds of the same name, in `.sourceWorkspace`'s and `.typeSuggestions`' `invalidateOn`) |
| Patches | `macos/App/Features/Workspace/Session/CatalogLastUpdated.swift` `row(_:patched:appendsOn:)`, `sourceTypeRow()`, `metadataBoard()` | `row` replaces or appends; nothing removes |
| Registry | `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift` `.sourceTypesList`, `.typeSuggestions`, `.sourceWorkspace` | Lists follow `source_vocabulary` with the default `.revalidate` |
| Store reply | `macos/App/Platform/GenealogyStore.swift` `CatalogTypeSuggestionEdit`, `assignTypeField`, `removeTypeField`, `[CatalogSourceType].label(forTypeID:)` | The reply carries the level's list and the type's count |
| Table | `macos/App/DesignSystem/Components/Table/PVTable.swift` `PVTable`, `handleKey`, `PVTableSelection` | Selection only; Return ignored; no `scrollTargetLayout` |
| List keys | `macos/App/DesignSystem/Components/List/PVList.swift` `PVListKeyboard.action(for:option:index:count:)` | Return / Space → `.activate` |
| Header chrome | `macos/App/Features/CatalogVocabulary/VocabularyChrome.swift` `VocabularyPanelHeader` | `iconKey` and `usageLine` exist for Source types only; `MetadataDetailPane` passes neither |
| Tests | `macos/ProvenenciaTests/SourceTypesModelTests.swift`; `PlaceRegistryTests.swift` `resolvesSourceTypesWithSelection`; `WorkspaceDestinationHostTests.swift` `presentationSourceTypesRootAndRow`; `CatalogQueryRegistryTests.swift` `createdSourceTypePatchesTheTypesList`; `WorkspaceToolbarBreadcrumbTests.swift`; `PVListTests.swift` | Expect today's shape |

**Precedent.** The Sources list → Source page: `PlaceRegistry` `.sourceDetail` (`.sourcePage`, `viewIdentity: { $0.sourceId }`), `SourcePageView` (`.task` warms; `SourcePageLoadingShell`; `.leavesForSectionRoot`), `SourcePageModel.confirmResourceDelete(leaving:)`, `SourcesListView`'s `ListScrollAnchorModifier`. A patch-only write: `.wroteMetadataBoard` + `CatalogQueryPatch.metadataBoard()`. The presence read: `evidenceGraphPresence(id:)`. The leave guard: `CitationComposerView` / `CitationComposerModel`. The suggestion fix: S15-12's D-2 and D-5, copied at the Source level.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | **The place.** `WorkspacePresentationID.sourceTypePage` *(new)*. The `.sourceTypesDetail` spec keeps its id, match and query keys; presentation `.sourceTypePage`, `viewIdentity` `{ $0.typeId }`. The `.sourceTypes` (list) spec's keys become `[.sourceTypesList]`. `WorkspaceDestinationHost`: `.sourceTypePage` → `SourceTypePageView(typeID:session:userID:store:)` *(new)* when `currentLocation.typeId` is set; `destinationKind(.sourceTypePage) == .sourceTypes`. `sourceTypePage(typeId:title:)`'s doc: "One Source type's page." | Map Shape; the Source page; one mount per type resets the draft | A second place id |
| D-2 | **The split.** `SourceTypesModel` keeps `SortColumn`, sort state, `adding`, `openAdd()`, `isAdding`, `types`, `isLoading`, `loadError` (types only), `visibleTypes`, `countLine`, `sortBy`, `compare`, `typesListKey`, `warmListQueries()` (types only). `SourceTypePageModel` *(new)*, `macos/App/Features/SourceTypes/SourceTypePageModel.swift` *(new)*, `@MainActor @Observable final class`, `init(typeID:session:userID:store:)`: `type` (`session.sourceType(id:)`), `isGone` (`session.sourceTypePresence(id:) == .gone`), `isLocked`, `draft: SourceTypeDraft?`, `isSaving`, `formError`, `toast`, `suggestionsHandle: QueryHandle<[CatalogTypeSuggestion]>?`, `suggestions`, `fields`, `assignPick`, `isAssigning`, `removingFieldID`, `suggestionError`, `assignPool`, `canAssign`, `pickedField`, `assignTooltip`, `assignAccessibilityLabel`, `canEditAssociations`, `rereadSuggestions()`, `rereadTypes()`, `typesHandle`, `applyDraftIconKey(_:)`, `deleteImpact`, `pendingImpact`, `isDeleting`, `deleteError`, `deleteTooltip`, `deleteAccessibilityLabel`, `pendingDeleteType`, `cancelDelete()`, `isDirty`, `canSubmit`, `syncDraft()`, `revertEdit()`, `submit()`, `assignPickedField()`, `removeSuggestion(fieldID:)`, `askDelete()`, `confirmDelete(leaving:) -> Bool`, `warm()` (`session.query` on `sourceTypesList`, `metadataFieldsList`, `typeSuggestions`; the view's `.task` calls it, as `SourcePageView`). `suggestionsHandle` and `typesHandle` are `session.queryHandle(…)`, nil until warmed. `SourceTypesModel.Draft` moves to `SourceTypeDraft` *(new)* in `macos/App/Features/SourceTypes/SourceTypeDraft.swift` *(new)*, unchanged; `SourceTypeAddModel` uses it | Map Shape; review M-10: the list model no longer edits; S15-18 finds the draft beside the forms | Keeping `Draft` on the list model |
| D-3 | **Type row writes on the declared row patch; `patchTypesList` goes.** `CatalogMutation.updatedSourceType(CatalogSourceType)` *(new)* and `.deletedSourceType(id: String)` *(new)*, both patch-only. `patchedSourceType` returns the row of `.createdSourceType` and `.updatedSourceType`. `CatalogQueryPatch.row(_:patched:appendsOn:)` gains `removes: @escaping @Sendable (CatalogMutation) -> String? = { _ in nil }`: checked before the `patched` guard (a delete carries no row): when it returns an id, the row with that id is removed and the patch reports a change. `invalidationKind` returns nil for both new cases. `sourceTypeRow()` passes `removes` for `.deletedSourceType`. Save applies `session.apply(effects, .updatedSourceType(updated))`; delete `session.apply(effects, .deletedSourceType(id:), leavingPage: leave)` | S15-47 review M-4 (user, 2026-11-14); one row-patch function for list membership (review M-8); keeps today's instant row drop | A separate removal patch; invalidating the list on delete — the row would show until the reload |
| D-4 | **The draft.** `syncDraft()` sets `draft` from `type` only while `draft == nil`; the view calls it in `.onChange(of: model.type?.id, initial: true)`. Save sets it from the reply; Revert from `type`. A list reload never touches it | Rule "No engineering for two windows"; today's `applySelection` reset it on every list change | Following the cache while clean — a second rule with no case |
| D-5 | **A gone type leaves through the page mechanism.** `WorkspaceSession+SourceTypes.swift` *(new)* in `macos/App/Features/Workspace/Session/`: `sourceTypesHandle`, `sourceType(id:)` and `sourceTypePresence(id:) -> CatalogRowPresence<CatalogSourceType>`. `CatalogRowPresence<Row>` *(new generic enum: `.unknown`, `.present(Row)`, `.gone`)*, in `macos/App/Features/Workspace/Session/CatalogRowPresence.swift` *(new)*, with `static func of(_ row: Row?, in handle: QueryHandle<[Row]>?) -> Self` (`.gone` only once the handle `isSettled` with a value). `EvidenceGraphPresence` becomes `typealias EvidenceGraphPresence = CatalogRowPresence<CatalogEvidenceGraph>`; `evidenceGraphPresence(id:)` returns `.of(evidenceGraph(id:), in: evidenceGraphsHandle)`. The page applies `.leavesForSectionRoot(when: model.isGone)` | `add-workspace-place` § 5 names it for a page (review M-2, brief M-3); the list's `.missingDeepId` reconcile goes with the side pane | `reconcile() -> .missingDeepId` on the page — the master–detail path |
| D-6 | **Live labels.** `LocationNames` gains `sourceTypeLabel: @MainActor (String) -> String?` *(new)*, a defaulted init parameter (`{ _ in nil }`), set from `session.sourceType(id:)?.label`. `WorkspaceLocationLabels.sourceTitle(live:carried:)` is renamed `liveLabel(live:carried:)` (one rule for any record: live, else carried, blank counts as none); `sourceTitle(sourceID:carried:names:)` and `PromoteModel` call it. `labels(for:names:)` returns `liveLabel(live: names.sourceTypeLabel(typeId), carried: location.title)` as the leaf of a `typeId` location; `breadcrumbItems` gains a `typeId` branch before its final `else` that takes the leaf from `labels(for: location, names: names)` (passing `names`, unlike the `entityId` branch) | Review M-9: one rule, not a third copy; crumbs and history menu share it | A `sourceTypeLabel(typeID:carried:names:)` beside `sourceTitle` |
| D-7 | **Suggestion writes** (S15-12 D-2, D-5 and D-1's `markStale` half, at the Source level; user, 2026-11-15). `CatalogMutation.wroteTypeSuggestions(typeId: String, edit: CatalogTypeSuggestionEdit)` *(new)* replaces `.assignedTypeSuggestion` and `.removedTypeSuggestion`; `CatalogMutationKind.wroteTypeSuggestions` *(new)* replaces their two kinds, and `.sourceWorkspace`'s `invalidateOn` lists it (its `default:` arm keeps `.allCached(.sourceWorkspace)`, AC-3.3). `CatalogQueryPatch.typeSuggestions()` *(new)* writes `edit.suggestions` into the cached `.typeSuggestions(project, typeId)` (on that descriptor's `patches`); `CatalogQueryPatch.typeSuggestionCount()` *(new)* sets the row's `suggestedFieldCount` in `.sourceTypesList` (on its `patches`). `.typeSuggestions` drops `invalidateOn` and `invalidation` and gains `whenHidden: .markStale`. The page applies only `session.apply(.wroteTypeSuggestions(typeId:edit:))`. S15-12 adds `level` to the key, the mutation and the patch | Today every write reloads the list its reply carried; one mechanism; S15-12 extends this instead of undoing it (review M-1) | A row patch for the count — a third path S15-12 deletes |
| D-8 | **The leave guard** (user, 2026-11-15). `WorkspaceLeaveGuard` gains `var navigation: WorkspaceNavigation? { get set }` (both conformers already have `weak var navigation`). `View.workspaceLeaveGuard(_ leaveGuard: some WorkspaceLeaveGuard)` *(new)* in `WorkspaceNavigation.swift` beside `leavesForSectionRoot`: on appear sets `leaveGuard.navigation` and `navigation.leaveGuard`; on disappear clears `navigation.leaveGuard` when it is still `leaveGuard`. `CitationComposerView` and `PromoteView` use it in place of their lines. `SourceTypePageModel: WorkspaceLeaveGuard`: `shouldHoldNavigation(_:)` is false unless `isDirty && !isSaving`, then sets `pendingLeave = PendingLeave()` (nested `Identifiable` struct) and returns true; `discardAndLeave()` reverts, clears `pendingLeave`, `navigation?.resumeHeldNavigation()`; `keepEditing()` clears it, `navigation?.cancelHeldNavigation()`. The view: `pvConfirm(item: leaveBinding, copy: { _ in .discardChanges }, tone: .danger, accessibilityIdentifierPrefix: "sourceTypes.page.leave", onConfirm: { model.discardAndLeave() }, detail: { _ in EmptyView() })`, where `leaveBinding` is a `Binding` whose get is `model.pendingLeave` and whose set calls `model.keepEditing()` when the new value is nil (Cancel, Escape), as `CitationComposerView.leaveBinding`. A `go(to:)` to the location already shown is never held (`go(to:)` coalesces before `hold`) | Review M-4: the third copy of the install; `PVConfirmCopy.discardChanges` is the kit copy | Silent drop (user chose ask) |
| D-9 | **Rows open on click or Return.** `PVTable` gains `onActivate: ((Row.ID) -> Void)? = nil` *(new)*. When set: a click selects, then activates; in `handleKey`, `.return` and `.space` go through `PVListKeyboard.action(for:option:index:count:)` and its `.activate(index)` activates `rows[index]` (with nothing selected that is the first row, as `PVList`); every other key behaves as today. When nil, nothing changes (Metadata, Properties). `VocabularyListPane` gains `onActivate` *(new, default nil)*. `SourceTypesListPane` holds the highlight in `@State private var highlighted: String?` and passes `onActivate: { id in navigation.go(to: .sourceTypePage(typeId: id, title: model.types.label(forTypeID: id))) }` | AC-1.2; one keyboard contract (review M-3) | `PVTableSelection.activationIndex` — a second Return rule |
| D-10 | **Scroll on Back.** `isListRoot` is `typeId == nil` for `.sourceTypes`. `PVTable`'s row `LazyVStack` gains `.scrollTargetLayout()`. `SourceTypesListPane` applies `ListScrollAnchorModifier(anchor: navigation.currentLocation.listScrollAnchor, rowIDs: model.visibleTypes.map(\.id), isLoaded: !model.isLoading)` | Map Shape; the one anchor mechanism | A table-specific anchor |
| D-11 | **Chrome.** The page header is `SourceTypePageHeader` *(new snowflake)* in `macos/App/Features/SourceTypes/SourceTypePageHeader.swift` *(new)*, as the board: the eyebrow "Source type" with the trash `PVIconButton` trailing; the saved mark in `PVThumbnail(.init(glyph: .mark(PVMarkKey(catalogKey: type.iconKey))), size: 52)` (the board hand-draws the same tile) beside the saved label in `PVFont.display(size: PVTypeScale.display3)`, one line, truncated at the tail; the origin `PVBadge`-style `OriginBadge`, the mono key, "·", the usage line; the key hint; the delete-failure `PVCallout` under it. The header shows saved values; the draft shows only in Details. With no type yet it draws its loading state, as the board's frame 13: `PVSkeletonBar`s in the trash, mark (52 × 52), label (280 × 30) and meta places, in the same `PVPageColumns` header slot `VocabularyPanelHeader` loses `iconKey` and `usageLine` and their doc lines (only Metadata calls it). `VocabularyPaneMode` moves from `VocabularyPane.swift` into `macos/App/Features/Metadata/MetadataModel.swift` unchanged. The page reuses `VocabularyFormActions` and `VocabularyLabeledSection`. Doc comments in `VocabularyPane.swift` and `VocabularyChrome.swift` stop naming the Source types pane | Brief TP-3, review M-6 / brief M-6 | Reusing `VocabularyPanelHeader` at page width |
| D-12 | **One suggestion list.** `SourceTypeSuggestionList` *(new)*, `macos/App/Features/SourceTypes/SourceTypeSuggestionList.swift` *(new)*, taking `model: SourceTypePageModel` and `isLocked`: `PVSectionHeader(title: L10n.SourceTypes.suggestedSectionLabel, meta: L10n.SourceTypes.assignedCount(count:))`, then the hint (editable only), rows, empty card, picker. Today's `suggestedFields(isLocked:)`, `emptySuggestions`, `suggestionRows`, `assignControl`, `poolRow`, `poolOptions`, `assignListMaxHeight` move into it. Loading and failure come from `model.suggestionsHandle?.reading` (`.loading` → spinner; `.failed` → `PVRetryCallout(title: L10n.SourceTypes.suggestionsLoadErrorTitle, message: L10n.Errors.message(for:), handle:, id: "sourceTypes.suggested.loadError", onRetry: model.rereadSuggestions)`); `isLoadingSuggestions` goes. S15-12 adds `level` | Brief TP-6; S15-12 D-6 names this file; review M-5 | Moving the section into the page view and again in S15-12 |
| D-13 | **Details form** (board, TP-4). Label `PVInput`; Icon a row (the draft's mark in `PVThumbnail(.init(glyph: .mark(PVMarkKey(catalogKey: draft.iconKey))))` (its 44pt default), its name over its mono key, then `PVButton("Change icon", variant: .secondary, size: .sm)`) that opens today's "Choose an icon" `pvFormDialog` (width 660, `SourceTypeIconGrid(columns: 6)`, Use icon / Cancel) with `@State pendingIconKey`; Use icon calls `model.applyDraftIconKey(_:)`, so the icon is a draft like Label (Save, Revert and the leave confirm cover it); Description `PVTextArea(text:, lineLimit: 4...8, prompt: L10n.SourceTypes.formDescriptionPlaceholder)` (no focus pair). While `model.isSaving` the form is `.disabled(true)` (TP-4). The Change icon button keeps `formIconChangeAccessibility(name:)` as its accessibility label. Details is one column, 560pt at most. Identifiers keep `sourceTypes.form.*` and `sourceTypes.iconPicker` | Brief TP-4, brief M-9; the board's TP-4 decision | The grid inline — the board chose the sheet |
| D-14 | **Toasts** (user, 2026-11-15). The page owns "Type updated", "Field assigned", "Suggestion removed" (`vocabularyToastOverlay(_, identifier: "sourceTypes.page.toast")`). Delete sets none. `SourceTypesModel.showAdded` goes; `sourceTypeAddDialog(_:onAdded:)` becomes `sourceTypeAddDialog(_:)` | Sources precedent | Carrying toasts across places |
| D-15 | **Loading and errors.** Before the types handle has a value the page draws `PVPageColumns(headerPinned: true)` with a spinner, as `SourcePageLoadingShell`. A types-list failure with no value shows `PVRetryCallout(title: L10n.SourceTypes.pageLoadErrorTitle, message: L10n.Errors.message(for:), handle: typesHandle, id: "sourceTypes.page.loadError", onRetry: model.rereadTypes)` in the primary column. Delete: `pvDeleteImpact`'s `onConfirm` is `{ Task { await model.confirmDelete(leaving: navigation.fallbackToSectionRoot) } }`. Page layout: `PVPageColumns(headerPinned: true, scrollResetKey: typeID, split: .sourceTypePage, header:primary:secondary:)` (D-16); primary Details, secondary `SourceTypeSuggestionList` | Brief TP-7, TP-10; the board's TP-W1 | A plain `PVCallout` |
| D-16 | **A two-column split the page sets** (user, 2026-11-15: a general kit container; the page passes its widths and when it wraps). `PVColumnSplit` *(new)*, a `Sendable, Equatable` struct in `macos/App/DesignSystem/Components/PageColumns/PVPageColumns.swift`: `mainMin`, `mainMax`, `sideMin`, `sideMax: CGFloat`, `stacking: Stacking` (`enum Stacking: Sendable { case belowWide, whenNarrow }`), and `func stacks(available: CGFloat, widthClass: PVWidthClass) -> Bool` (`.belowWide`: `widthClass != .wide`; `.whenNarrow`: `available < mainMin + PVSpacing.space9 + sideMin`). `static let standard = PVColumnSplit(mainMin: 0, mainMax: PVSpacing.widthContentMax, sideMin: PVSpacing.widthInspector, sideMax: PVSpacing.widthSecondaryMax, stacking: .belowWide)`. **One widths rule** in `PVPageColumnsMetrics`: `widths(available: CGFloat, widthClass: PVWidthClass, split: PVColumnSplit) -> PVPageSideColumnWidths` *(new)*. Beside: `room = available − space9`, `main = max(0, min(mainMax, room − sideMin))`, `side = min(sideMax, max(sideMin, room − main))`, `group = main + space9 + side`. Stacked: each mode keeps today's stacked widths — `.belowWide` both columns `max(0, min(mainMax, available))` (today's `columnWidths` at Regular); `.whenNarrow` main `available`, side `min(available, sideMax)` (today's `sideColumnWidths`). `split(available:sideMax:)` stays, a one-line wrapper over the beside rule with `.standard`'s `mainMax` and `sideMin`, so `SourcePageOverviewLayout` and `fillSplitSideMax` are untouched. `sideColumnWidths(available:mainMin:)` becomes `widths(available:widthClass: .regular, split: PVColumnSplit(mainMin: mainMin, mainMax: PVSpacing.widthContentMax, sideMin: PVSpacing.widthInspector, sideMax: PVSpacing.widthSideColumnMax, stacking: .whenNarrow))`. `columnWidths(pane:widthClass:hasSecondary:primaryFill:fillSplitSideMax:split:)` and `columnWidths(proposal:…split:)` gain `split: PVColumnSplit = .standard`; with a secondary and not in fill mode they return `widths(available: pane − 2·gutterPage, …)`'s main, side and group (band = group). `layoutWidths(…split:)` takes `stacked` from `split.stacks(available:widthClass:)` when there is a secondary. `PVPageColumns` (both inits) and `PVPageColumnsBandLayout` gain and pass `split: PVColumnSplit = .standard`. `extension PVColumnSplit { static let sourceTypePage = PVColumnSplit(mainMin: 440, mainMax: 560, sideMin: 340, sideMax: 480, stacking: .whenNarrow) }` lives in `SourceTypePageView.swift`. At the board's panes: 1102 → main 560, side 446, group 1038; 2296 → 560 + 32 + 480 = 1072, centred; 840 (available 776) → stacked | The board's one layout; one wrap rule in the kit instead of two (round-2 M2-1); every caller that passes nothing keeps its widths | A page-local `Layout`; a Source-type flag on `PVPageColumns`; renaming `split(available:sideMax:)` (three callers) |

**Rules this plan bends.** None. D-5 and D-8 follow `add-workspace-place` and `add-workspace-location`; D-7 is S15-12's decision moved forward (user, 2026-11-15; the map's S15-12 scope entry says so).

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `SourceTypePageModel`, `SourceTypePageView` *(new)* | types / files | `SourcePageModel`, `SourcePageView`; `SourceTypesModel`, `SourceTypesDetailPane` | The split (D-2); bodies move |
| `SourceTypeDraft` *(new name)* | type / file | `SourceTypesModel.Draft` | A move (D-2) |
| `SourceTypePageHeader` *(new)* | view / file | `VocabularyPanelHeader`, `SourcePageIdentityHeader` | A page header for one page (D-11) |
| `SourceTypeSuggestionList` *(new)* | view / file | `SourceTypesDetailPane.suggestedFields(isLocked:)` | Moved; S15-12's D-6 file (D-12) |
| `WorkspacePresentationID.sourceTypePage` *(new)* | case | `.sourcePage` | One per destination view |
| `WorkspaceSession+SourceTypes.swift`, `sourceType(id:)`, `sourceTypePresence(id:)`; `CatalogRowPresence<Row>` *(new)* | file / funcs / enum | `WorkspaceSession+EvidenceGraphs.swift` `EvidenceGraphPresence`, `evidenceGraphPresence(id:)` | The graph's enum becomes the generic one's typealias (round-2 M2-3) |
| `CatalogMutation.updatedSourceType`, `.deletedSourceType`, `.wroteTypeSuggestions`; `CatalogMutationKind.wroteTypeSuggestions` *(new)* | cases | `.createdSourceType`, `.wroteMetadataBoard` | D-3, D-7 |
| `row(…removes:)` *(new parameter)* | parameter | `row(_:patched:appendsOn:)` | Extends it (D-3) |
| `CatalogQueryPatch.typeSuggestions()`, `typeSuggestionCount()` *(new)* | funcs | `metadataBoard()` | S15-12 D-2 |
| `LocationNames.sourceTypeLabel` *(new)*; `liveLabel(live:carried:)` *(renamed)* | member / func | `sourceTitle(live:carried:)` | D-6 |
| `View.workspaceLeaveGuard(_:)` *(new)*; `WorkspaceLeaveGuard.navigation` *(new requirement)* | modifier | the composer's and Promote's `onAppear` / `onDisappear` lines | D-8 replaces both copies |
| `PVColumnSplit` *(new)*; `PVPageColumns(split:)` *(new parameter)* | type / parameter | `PVPageColumnsMetrics.split(available:sideMax:)`, `sideColumnWidths(available:mainMin:)`; `SourcePageOverviewLayout`, `ConclusionPinnedSideColumn` | D-16: the page container takes its split as data; the two feature layouts are not moved here (Out) |
| `PVTable(onActivate:)`, `VocabularyListPane(onActivate:)` *(new parameters)* | parameters | `PVList(onActivate:)`, `PVListKeyboard` | D-9 |
| `SourceTypePageModelTests.swift` *(new)* | tests | `SourceTypesModelTests.swift` | The page's tests move with its model |

**Builds on.** `add-workspace-place` (place registry, `viewIdentity`, declared patches, cache rule 2, the page's gone mechanism), `add-workspace-location` (deep id, crumbs, `isListRoot`, leave guard), S15-47's `.sourceTypeRow()` and `sourceTypePage(typeId:title:)`, S15-12's D-2.
**Deletes.** `SourceTypesDetailPane.swift`; from `SourceTypesModel` every member D-2 does not keep (`mode`, `draft`, the save, suggestion and delete members, `selectedTypeID`, `selectedType`, `isSelectedTypeLocked`, `syncSelection`, `select`, `applySelection`, `clearHistorySelection`, `showAdded`, `patchTypesList`, `patchSuggestions`, `fieldsListKey`, `suggestionsKey`, `warmSuggestions`, `fields`, `Draft`); `SourceTypesContent.reconcileSelection(for:)` and its `onChange` hooks; `SourceTypesView.detailPaneWidth`; `sourceTypeAddDialog`'s `onAdded`; `CatalogMutation.assignedTypeSuggestion`, `.removedTypeSuggestion` and their kinds; `.typeSuggestions`' `invalidation` closure; `isLoadingSuggestions`; `VocabularyPanelHeader.iconKey`, `usageLine`; the composer's and Promote's guard install lines; `WorkspaceLocationLabels.sourceTitle(live:carried:)` (renamed). `iconFieldButton(selection:)`'s hand-drawn field (the Change icon row and `PVThumbnail` replace it; the sheet and `pendingIconKey` move to the page view). Strings: `L10n.SourceTypes.panelEmptyTitle`, `panelEmptyBody`, `toastAddedTitle`, `toastAddedBody`, `toastDeletedTitle`, `toastDeletedBody`. Tests that move or go: § 8 "Existing tests".
**Next adds.** S15-12 adds `level` to `.typeSuggestions`, `.wroteTypeSuggestions` and `typeSuggestions()`, two more `SourceTypeSuggestionList` instances in the page's secondary column, and the per-level state on `SourceTypePageModel`. S15-17 adds the formats section to the primary column. S15-18 adds Copy from to `SourceTypeAddModel` with `SourceTypeDraft`. S15-49 changes only `SourceTypesListPane`'s columns. A later list → page vocabulary passes `onActivate` and `.workspaceLeaveGuard`.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| Row click / Return → page | `SourceTypePageView` | New mount per `typeId` (D-1) · D-5 · loading shell (D-15) |
| Omnibar `source_type` hit, delete-impact link, history restore → `typeId` | same | same; the engine's locations already carry `typeId` (`GoStore`'s `WorkspaceLocation` mapping) |
| Add dialog → page of a type just created | same | The row is in the list before `go(to:)` (`.createdSourceType` patch) |
| Page → list on delete | `SourceTypesView` | `leavingPage` hides keys first; the row patch removes the row (D-3) |
| Navigation while dirty | `WorkspaceNavigation.hold` | D-8; `fallbackToSectionRoot` and `.leavesForSectionRoot` are not held |
| The composer and Promote on the new modifier | `CitationComposerView`, `PromoteView` | Same set / clear as today (T-9) |

### Scale

At the map's Scale: about 30 types, 63 fields, a type used by 500 Sources (one `usedBy` number). A type Save or Delete reports `source_vocabulary` (`core/database/effects/registry.go`, the `source_types` entry), which `.sourceTypesList`, `.metadataFieldsList` and `.typeSuggestions` follow: the visible types and fields lists reload once each (2 RPCs) on top of the row patch, as today; each visited type's hidden `typeSuggestions` key is now marked stale instead of reloading (D-7: at most one RPC per type visited, paid when its page is next shown). A suggestion write is one write and two patches with no RPC, plus `.allCached(.sourceWorkspace)` marking visited Source pages stale (`markStale`, no RPC). The list's table holds about 30 rows.

### Edges

- **Assumptions.** `sourceTypePresence` says `.gone` only for a settled list with a value: a type created in another window is gone until the list reloads, so its page leaves for the list (rule "No engineering for two windows"; T-6). The leave guard is one at a time: the modifier clears it only when it is still the page's (T-9). `typeSuggestionCount()` patches only a row the list holds.
- **Neighbors.** Dirty details + a suggestion write: the suggestion saves, the draft stays dirty, leaving still asks (T-9). A save in flight + Back: not held (T-9). A label changed and changed back: clean. Return with no row highlighted: opens the first row, as `PVList` (T-11). An omnibar hit on the type already shown is not held (`go(to:)` coalesces first).
- **Removed inputs.** A deleted type's `typeSuggestions` key is marked stale by the delete's `source_vocabulary` and never read again. A type deleted elsewhere while its page is open: the next list reload drops the row and the page leaves (D-5).
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
| Page layout | `PVPageColumns(headerPinned:scrollResetKey:split:header:primary:secondary:)` | `SourceTypePageView` | D-15, D-16; side by side at every width while both fit |
| Header | `SourceTypePageHeader` + `PVThumbnail` (mark) + `PVIconButton` (trash) | `SourceTypePageHeader.swift` | D-11; the board's layout |
| Section titles | `PVSectionHeader` | page view, suggestion list | "Details" (`L10n.SourceTypes.detailsSectionLabel` *(new)*), "Suggested fields" |
| Details | `PVField` + `PVInput` / `PVTextArea`; icon row + "Choose an icon" `pvFormDialog` with `SourceTypeIconGrid`; `VocabularyFormActions` | page view | D-13 |
| Locked note | `PVCallout(tone: .neutral, icon: .lock)` + `VocabularyLabeledSection` | page view | Today's |
| Suggested fields | `SourceTypeSuggestionList` | its file | D-12 |
| Delete | `pvDeleteImpact(flow:accessibilityIdentifierPrefix:onConfirm:onNavigate:)` | page view | `onConfirm` awaits `model.confirmDelete(leaving: navigation.fallbackToSectionRoot)` |
| Leave confirm | `pvConfirm(item:copy:)` + `.workspaceLeaveGuard(model)` | page view | D-8 |
| Gone | `.leavesForSectionRoot(when: model.isGone)` | page view | D-5 |
| Toast | `vocabularyToastOverlay` | page view | D-14 |
| List | `VocabularyListPane(onActivate:)` + `ListScrollAnchorModifier` | `SourceTypesListPane` | D-9, D-10 |

States: loading and list failure (D-15), gone (D-5), suggestions loading and failure (D-12), suggestion write error (Callout), save error (under Label), delete error (Callout under the header). Accessibility: page root `accessibilityIdentifier("sourceTypes.page")`; delete reads "Delete Census"; rows activate by Return and by VoiceOver's default action when `onActivate` is set.

### Strings

L10n keys *(new)*: `L10n.SourceTypes.detailsSectionLabel` = "Details" (`sourceTypes.detail.detailsSection`); `pageLoadErrorTitle` = "The source type could not be loaded" (`sourceTypes.page.loadErrorTitle`); `suggestionsLoadErrorTitle` = "Suggested fields could not be loaded" (`sourceTypes.suggested.loadErrorTitle`). Changed: `L10n.SourceTypes.formIconChange` "Change" → "Change icon" (its one caller is this row); `iconPickerSubtitle` → "The mark that stands for this type wherever a source of it is listed. Each mark names a kind of record, not a file format." (the board; today's says "Twenty-one", which no longer matches the marks). The leave confirm uses `PVConfirmCopy.discardChanges`. Removed: § 6 Deletes' strings and their `Localizable.xcstrings` entries.

## 7. Steps

**STEP-1 — The place, presence and live crumbs**
Files: `PlaceRegistry.swift`, `WorkspacePresentationID.swift`, `WorkspaceDestinationHost.swift`, `WorkspaceLocation.swift`, `WorkspaceLocationLabels.swift`, `WorkspaceToolbar.swift`, `WorkspaceSession+SourceTypes.swift` *(new)*, `CatalogRowPresence.swift` *(new)*, `WorkspaceSession+EvidenceGraphs.swift`, `PromoteModel.swift` (the rename), tests `PlaceRegistryTests.swift`, `WorkspaceDestinationHostTests.swift`, `WorkspaceToolbarBreadcrumbTests.swift`, `WorkspaceNavigationTests.swift`, `WorkspaceSessionTests.swift`. Skills: `add-workspace-place`, `add-workspace-location`.
Do: D-1 (the host's `.sourceTypePage` arm mounts `SourceTypesView` until STEP-7), D-5's session half, D-6, D-10's `isListRoot`.
Check: `xcodebuild test` passes T-1 – T-4, T-6's presence cases, `registryPresentationsAreKnown` and `registryCoversAllPlaceIDs` (each gains the `.sourceTypePage` row), and every `EvidenceGraphModel` test.

**STEP-2 — Type row writes on the row patch**
Files: `CatalogMutation.swift`, `CatalogLastUpdated.swift`, `CatalogQueryRegistryTests.swift`. Skill: `add-workspace-place`.
Do: D-3's mutations and `row(…removes:)`.
Check: T-5 passes.

**STEP-3 — Suggestion writes on one mutation**
Files: `CatalogMutation.swift`, `CatalogLastUpdated.swift`, `CatalogQueryRegistry.swift`, `SourceTypesModel.swift` (its two writes apply the new mutation until STEP-4 moves them), `CatalogQueryRegistryTests.swift`. Skill: `add-workspace-place`.
Do: D-7. The two writes in `SourceTypesModel` apply only `session.apply(.wroteTypeSuggestions(typeId:edit:))`; their `patchSuggestions` call and the count branch of `patchTypesList` go now. Rewrite `CatalogQueryRegistryTests.applySuggestionMutationsInvalidateTypeKey` as `wroteTypeSuggestionsInvalidatesOnlySourcePages` (the `.typeSuggestions` key is patched, not invalidated), the `invalidations(by: .assignedTypeSuggestion…)` assertion to `.wroteTypeSuggestions` (→ `[.allCached(.sourceWorkspace)]`), and the `everyMutation` array (one `.wroteTypeSuggestions` with an empty edit in place of the two).
Check: T-7 passes; `rg "assignedTypeSuggestion|removedTypeSuggestion" macos` finds nothing.

**STEP-4 — `SourceTypePageModel` and the list model**
Files: `SourceTypePageModel.swift` *(new)*, `SourceTypeDraft.swift` *(new)*, `SourceTypesModel.swift`, `SourceTypeAddModel.swift`, `SourceTypeAddDialog.swift`, `SourceTypesView.swift`, `SourceTypesDetailPane.swift` (deleted), `SourceTypePageModelTests.swift` *(new)*, `SourceTypesModelTests.swift`. Skill: `add-swift-test`.
Do: D-2, D-3's model writes, D-4, D-5's `isGone`, D-14. `SourceTypesView` shows the header and the list only. `SourceTypesListPane.selection` becomes D-9's `@State highlighted` binding (get `highlighted`; set stores the id and still navigates) until STEP-8 moves navigation onto `onActivate`. Existing tests per § 8 "Existing tests".
Check: T-6, T-8, T-10, T-12 pass.

**STEP-5 — The leave guard**
Files: `WorkspaceNavigation.swift`, `CitationComposerView.swift`, `PromoteView.swift`, `SourceTypePageModel.swift`, `SourceTypePageModelTests.swift`, `WorkspaceNavigationTests.swift`.
Do: D-8's protocol, modifier, both callers moved, the page model's conformance.
Check: T-9 passes; `CitationComposerModelTests` and `PromoteModelTests` pass.

**STEP-6 — The column split in the kit**
Files: `macos/App/DesignSystem/Components/PageColumns/PVPageColumns.swift`, `macos/ProvenenciaTests/PVPageColumnsTests.swift`. Skill: `add-ui-component`.
Do: D-16.
Check: T-13 passes; every existing `PVPageColumnsTests` case and the Person page's tests pass unchanged.

**STEP-7 — The page view**
Files: `SourceTypePageView.swift` *(new)*, `SourceTypePageHeader.swift` *(new)*, `SourceTypeSuggestionList.swift` *(new)*, `WorkspaceDestinationHost.swift`, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`. Skills: `add-ui-component`, `add-localized-string`.
Do: § 6 macOS and the board's frames; D-8's view half, D-11's header, D-12, D-13, D-14, D-15; § 6 Strings.
Check: build passes; the page matches frames 2 – 13 at pane 1102 and at 2296 (the same pair, centred); `rg "SourceTypes\.(panelEmpty|toastAdded|toastDeleted)" macos` finds nothing; `L10nResolutionTests` passes.

**STEP-8 — The list opens pages**
Files: `PVTable.swift`, `PVListTests.swift`, `VocabularyListPane.swift`, `SourceTypesListPane.swift`, `SourceTypesView.swift`. Skill: `add-ui-component`.
Do: D-9, D-10.
Check: T-11 passes; in the app ↓ moves the highlight without leaving, Return opens, Back restores the scroll.

**STEP-9 — Vocabulary chrome**
Files: `VocabularyChrome.swift`, `VocabularyPane.swift`, `MetadataModel.swift`, `MetadataDetailPane.swift`.
Do: D-11's `VocabularyPanelHeader` and `VocabularyPaneMode` lines.
Check: build passes; `MetadataModelTests` passes.

**STEP-10 — Docs and version**
Files: `.agents/skills/add-workspace-place/SKILL.md` (§ 5 "Master–detail selection (fields/types)" → "(fields)"; the leaving-page sentence names the Source type page; § 6's type-suggestion writes), `.agents/skills/add-workspace-location/SKILL.md` (the "fields/types pattern" row → "fields pattern"; "(Metadata, Source types, Properties)" → "(Metadata, Properties)"; the `syncSelection(from:)` citation; the leave guard names `.workspaceLeaveGuard`), `docs/macos-client-patterns.md` (the mutation list: `.updatedSourceType`, `.deletedSourceType`, `.wroteTypeSuggestions` in place of the two suggestion mutations; drop the clause that `patchTypesList` still serves update, assign, remove and delete; cache rule 4: `row` also removes), `macos/App/DesignSystem/README.md` ("The table tradeoff": the activate contract; "table → detail pane"), `docs/design-system-layers.md` (the icon grid's callers), `macos/App/DesignSystem/README.md`'s Page columns row (`split:` and `PVColumnSplit`), `docs/macos-client-patterns.md` § 9's `PVPageColumns` paragraph ("stacked at Regular, side by side at Wide" becomes: by default; a page may pass a `PVColumnSplit` that keeps its columns side by side while both fit), `.agents/skills/add-design-brief/SKILL.md`'s kit reach-for list ("Page columns, with the page's own column widths and wrap rule"), `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj`; `completed.md`, `deployment-plan.md` (map row), this plan, `design/` (brief → `design/archive/`, `design/README.md`).
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-48-source-type-page.md` and `scripts/check-guidance-names.py` pass; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Open each Source type on its own page."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `PlaceRegistryTests.swift` `resolvesSourceTypesWithSelection` (changed), the table row for `.sectionRoot(.sourceTypes)` (changed) | `typeId: "typ-1"` → `.sourceTypesDetail`, `.sourceTypePage`, `viewIdentity == "typ-1"`, keys unchanged; the root → `[.sourceTypesList]` | D-1 |
| T-2 | Swift | `WorkspaceDestinationHostTests.swift` `presentationSourceTypesRootAndRow` (changed) | root → `.sourceTypes`; `typeId` → `.sourceTypePage`; `destinationKind(.sourceTypePage) == .sourceTypes` | D-1, AC-1.1, AC-1.5, AC-1.6, AC-1.8 |
| T-3 | Swift | `WorkspaceToolbarBreadcrumbTests.swift` `sourceTypeLeafReadsTheLiveLabel` *(new)* | names `{ "typ-1" → "Population census" }`, carried "Census" → leaf "Population census"; `.none` → "Census"; blank live → carried; `labels(for:names:)` the same | D-6, AC-2.2 |
| T-4 | Swift | `WorkspaceNavigationTests.swift` `sourceTypesListIsAListRoot` *(new)* | root `isListRoot`; with `typeId` not; `.metadata` not; a noted scroll survives page and Back | D-10, AC-1.4 |
| T-5 | Swift | `CatalogQueryRegistryTests.swift` `updatedAndDeletedSourceTypePatchTheTypesList` *(new)* | cached [Book, Census]; `.updatedSourceType(Census')` → replaced, an unknown id not appended; `.deletedSourceType(id: Book)` → [Census']; no invalidation | D-3 |
| T-6 | Swift | `WorkspaceSessionTests.swift` `sourceTypePresenceWaitsForASettledList` *(new)*; `SourceTypePageModelTests.swift` `aGoneTypeIsGone` *(new)* | loading → `.unknown`; settled with the type → `.present`; without → `.gone`; the model's `isGone` follows | D-5, AC-1.7 |
| T-7 | Swift | `CatalogQueryRegistryTests.swift` `wroteTypeSuggestionsPatchesTheListAndTheCount` *(new)* | cached Book suggestions [Author], list row count 1; `.wroteTypeSuggestions(typeId: Book, edit: [Author, Publisher], 2)` → suggestions patched, row count 2, no load started; a cached Book Source page marked stale | D-7, AC-3.1, AC-3.3 |
| T-8 | Swift | `SourceTypePageModelTests.swift` `saveUpdatesTheRowAndKeepsTheKey` *(new)*, `revertRestoresTheSavedValues`, `aListReloadKeepsTheDraft` *(new)*, `pluginTypeIsLocked` *(new)*, `blankLabelRefusesSave` *(new)*, and the moved suggestion tests (§ 8 Existing tests) | Save → one store call, row label patched, key `census`, toast "Type updated"; Revert → draft equals type; a new list value leaves a dirty draft; plugin → `isLocked`; blank → required message, no store call; assign → suggestions [Author, Publisher], count 2, toast "Field assigned", the store's list called once; remove → count 1, toast "Suggestion removed" | AC-2.1, AC-2.2, AC-2.3, AC-2.4, AC-2.5, AC-2.6, AC-3.1, AC-3.2, D-4 |
| T-9 | Swift | `SourceTypePageModelTests.swift` `leavingAsksOnlyWhileDirty` *(new)*; `WorkspaceNavigationTests.swift` `leaveGuardModifierInstallsAndClears` *(new)* | clean → not held; dirty → held, `pendingLeave` set; `keepEditing()` → cleared, place unchanged; `discardAndLeave()` → reverted, Back performed; saving → not held; a suggestion write keeps a clean draft clean; the modifier sets `leaveGuard` and `navigation`, and leaves another guard in place on disappear | D-8, AC-4.1, AC-4.2, AC-4.3, AC-4.4, AC-4.5 |
| T-10 | Swift | `SourceTypePageModelTests.swift` `deletingLeavesAndDropsTheRow` *(new)*, `typeUsedByTwoSourcesShowsInboundNotice` (moved) | unused → `confirmDelete(leaving:)` true, `leave` once, row gone, `toast == nil`; with a dirty draft the same, no `pendingLeave`; used → inbound rows | AC-5.1, AC-5.2, AC-5.3, D-14 |
| T-11 | Swift | `PVListTests.swift` `returnAndSpaceActivateForATable` *(new)* | `PVListKeyboard.action(for: .return, option: false, index: -1, count: 3)` → `.activate(0)`; `.space` at 1 → `.activate(1)`; count 0 → `.ignore` | D-9, AC-1.3 |
| T-12 | Swift | `SourceTypesModelTests.swift` `createAndDeleteCommitThroughWorkspaceNavigation` (changed) | add → `go(to: .sourceTypePage(typeId:title:))` → current `typeId` is the new id; the list model has no toast | AC-5.4 |
| T-13 | Swift | `PVPageColumnsTests.swift` `columnSplitSetsTheColumnsBesideOrStacked` *(new)* | `.standard` at Regular and Wide → today's widths; `.sourceTypePage` through `layoutWidths(…split:)`: pane 1102 → main 560, side 446, `stacked == false`; pane 2296 Wide → 560 / 480, group 1072; pane 840 → `stacked == true`, main 776, side 480; `sideColumnWidths(available:mainMin:)` gives today's values for its existing cases | D-16 |

**Existing tests.** In `SourceTypesModelTests.swift`, these stay on the list model (helpers `makeModel`, `warm`, `makeAddModel` stay; `warmSuggestions` moves): `loadPopulatesTypesPool` (drops its `fields` line), `sortingTogglesWithinAColumnAndResetsAcrossColumns`, `countLineCountsTheRowsShown`, `countLineIsAbsentUntilTheListLoads`, every `adding…` test, `editingTheLabelShowsAndClearsItsError`, `addIsDirtyFollowsWhatWasTyped`, `anotherCreateFailureShowsInTheDialog`, `addingCarriesThePickedIconAndToasts` (renamed `addingCarriesThePickedIcon`, its `showAdded` and toast lines dropped), `createAndDeleteCommitThroughWorkspaceNavigation` (T-12). These move to `SourceTypePageModelTests.swift` on a `makePageModel(typeID:…)` helper, each `select(_:)` call replaced by building the page model for that id: `selectingSeededOrUserTypeEditsAndPluginTypeLocks`, `selectingLoadsThatTypesSuggestionsInStoredOrder`, `assignPoolExcludesFieldsAlreadySuggested`, `assigningAppendsTheFieldAndUpdatesTheListCount`, `selectingShowsOnlySourceLevelSuggestions`, `assigningWritesAtSourceLevelOnly`, `fieldsColumnShowsTheEnginesCountNotTheReplyLength`, `removingASuggestionKeepsTheFieldInThePool`, `removingASuggestionNoSourceUsesOmitsTheValueCount`, `editingASeededTypeIsAllowedAndTheKeyStays`, `changingIconMarksDirtyAndPersists`, `applyDraftIconKeyUpdatesPendingPickerSelection`, `revertingDiscardsUnsavedEdits` (T-8's `revertRestoresTheSavedValues`), `trashIsOfferedWhenUsedByOrPlugin`, `unusedUserTypeConfirmDeletes`, `unusedSeededTypeConfirmDeletes`, `typeUsedByTwoSourcesShowsInboundNotice`, `pluginTypeOriginLockedTrashStillOffered`; `confirmingDeleteDropsTheTypeAndItsSuggestions` is replaced by T-10's `deletingLeavesAndDropsTheRow`. These are deleted, the master–detail selection they pin being gone: `syncSelectionAppliesTypeAfterWarm`, `syncSelectionMissingDeepId`, `syncSelectionFromSectionRootClearsSelection`, `syncSelectionFollowsTheLocationWhileAdding`, `openingAndCancellingAddKeepsTheSelectionAndEdit` (T-6 covers the gone case). `CatalogQueryRegistryTests`: STEP-3. `PlaceRegistryTests.queryKeysMatchDesignTable`: the root row's keys become `[.sourceTypesList]`; the `typeId` row's presentation `.sourceTypePage`.

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `SourceTypesModelTests`, `PlaceRegistryTests`, `WorkspaceDestinationHostTests`, `CatalogQueryRegistryTests`, `CitationComposerModelTests`, `PromoteModelTests`, `MetadataModelTests`, `PVTableTests`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md`, `macos/App/DesignSystem/README.md` and `L10n.swift` with no hit left (`SourceTypesDetailPane`, `patchTypesList`, `patchSuggestions`, `assignedTypeSuggestion`, `removedTypeSuggestion`, `SourceTypesModel.Draft`, `sourceTitle(live:`, `showAdded`, `SourceTypePresence`, `fields/types`, "side pane's `.pvFormDialog`", "table → detail pane"); `scripts/check-guidance-names.py` passes
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches the brief inventory and the board's frames at Regular and Wide; no new kit primitive (`PVTable` gains `onActivate`; `PVPageColumns` gains `split:` and its `PVColumnSplit` value, D-16)
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief S15-D27 moved to design/archive/ and design/README.md updated
- [ ] Domain docs and skills updated per STEP-10
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

Use a project with the seed's types, Census used by Sources, and the plugin fixture's Grave memorial if present.

1. Source types: no side pane. ↓ twice: the highlight moves, the crumb stays "Source types". Return: the page opens (AC-1.2, AC-1.3).
2. Scroll the list down, click Census: "Source types › Census"; Back: the same scroll, nothing highlighted (AC-1.1, AC-1.4).
3. Rename Census to "Population census", Save: toast; crumb, header and list row follow; key `census` (AC-2.2). Clear the label: Save disabled (AC-2.3). Change it, Revert (AC-2.4).
4. Change the description, press Back: the discard confirm; Keep editing stays; Back, Discard: the list, the description unchanged (AC-4.1 – AC-4.3). Repeat with the sidebar and the omnibar.
5. Add Publisher to Book's suggestions, then Back: no confirm (AC-4.5); Book's Fields column moved (AC-3.1); remove it (AC-3.2).
6. Open Grave memorial: read only, Delete shown (AC-2.5).
7. Omnibar "census" → the page (AC-1.5). Quit and relaunch on the page → restored (AC-1.6).
8. Add type "Parish register" → its page, no toast (AC-5.4). Change its label, Delete → the list without it, no toast, no discard confirm (AC-5.1, AC-5.3). Delete on Census → blocked notice (AC-5.2).
9. Metadata page: delete a field a type suggests → its impact link opens the type's page (AC-1.8).
10. Resize Census's page from 900pt to 2300pt with an unsaved edit: Details and Suggested fields stay side by side and centred, stacking only when the pane is too narrow for both; the edit is kept (D-16). Open the composer and leave it with unsaved work: its own confirm still shows (D-8).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| `ListScrollAnchorModifier` does not reach `PVTable`'s internal `ScrollView` | D-10 adds `scrollTargetLayout`; Stop condition below |
| Moving the composer and Promote onto the modifier changes when their guard is set | T-9; `CitationComposerModelTests`, `PromoteModelTests` |
| `onActivate` changes Metadata or Properties | Default nil keeps the old path |
| S15-12's plan names `.assignedTypeSuggestion` and today's key | The map's S15-12 entry and its plan's status say D-1's `markStale`, D-2 and D-5 land here; S15-12's refresh adds only `level` |

**Stop and report if:**

- A **Current state** row is no longer true at your base.
- The agreed board draws something D-1 – D-16 contradict (a side pane, an inspector, toasts after Add or Delete, the side pane's header reused).
- `ListScrollAnchorModifier` on `SourceTypesListPane` does not restore the scroll with `scrollTargetLayout` on `PVTable`'s rows: do not add a second anchor mechanism.
- `WorkspaceNavigation.hold` does not see a sidebar or omnibar move: report the path.
- `.allCached(.sourceWorkspace)` does not mark a visited Source page stale after `.wroteTypeSuggestions` (T-7).
- Moving `VocabularyPaneMode` breaks a caller outside `Features/Metadata/`.

## 12. Open questions

None.

## 13. PR

**Title:** S15-48 — Source types open on their own page
**Body:** objective in one sentence; what shipped against US-1 – US-5; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-48-source-type-page.md`.
