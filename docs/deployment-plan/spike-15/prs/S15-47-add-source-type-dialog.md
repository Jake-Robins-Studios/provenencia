# S15-47 — Adding a Source type opens a dialog

**Status:** Planned
**Spike / slice:** Spike 15 · Slice 2 — Metadata at three levels
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D26](../design/S15-D26-add-source-type-dialog.md), board redrawn and agreed 2026-11-14 (user)
**Board:** [Claude Design — Source Types](https://claude.ai/artifact/R94Wfp97eC9cBLaSNBQEga), page *S2-03 Source Types Board*, section 05 "Add a type — a dialog, not a pane mode": frames 1a (Regular, empty dialog), 1b (Wide, the same 840pt sheet), 2 (key minted live), 3 (icon picked inline, its meaning under the grid), 4 (duplicate key under Label), 4b (danger Callout "The type was not added"), 5 (saving), 6 (discard confirm), 7 (after Add); the dialog's markup is in the component page *Source Types Pane*. Board decision AT-3 (redrawn and agreed 2026-11-14): a two-column sheet, 840pt, Label, Key and Description on the left, the icon grid always open on the right (5 columns), picking live with no second confirm; the side pane's "Choose an icon" sheet keeps its picker and draws the same grid (6 columns). Two board lines are not built (user, 2026-11-14): Return in Description is a new line, not Add (AT-9's Shift-Return), and the dialog does not wrap its grid under the fields below 790pt (AT-W1; two columns at every width, as the owner forms). Open the link in a browser; if you cannot, D-6, D-8, D-11 and § 6 macOS describe every frame
**Depends on:** S15-D26
**Blocks:** S15-48, S15-18
**Branch:** `s15-47-add-source-type-dialog`
**Version bump:** patch, 0.15.0 → **0.15.1** (or the next patch after `main`'s `VERSION` when you rebase): `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj` — a Mac UI change to an existing flow, no new capability and no wire change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md) (a cache patch), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md) (a component moves into the kit), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/swift-tests.mdc`, `.cursor/rules/macos-client.mdc` (wire vocabulary spelled once), `.cursor/rules/go-tests.mdc`
**Context:** working rule "A Source type has its own page" ([map](../deployment-plan.md#working-rules)); [`docs/design-system-layers.md`](../../../design-system-layers.md) (the icon grid is its snowflake example); [`macos/App/DesignSystem/README.md`](../../../../macos/App/DesignSystem/README.md) (the FormDialog row)
**Planned:** 2026-11-14 against `main` @ `43fd47e`; rechecked 2026-11-14 against `292b421` (no § 4 row changed)
**Review:** [`S15-47-add-source-type-dialog.review.md`](S15-47-add-source-type-dialog.review.md) — Fits — Ready with changes: rounds 1–2, and round 4 on the redrawn board (two passes); no open blocker or To user item

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

Add type on the Source types page opens a short form dialog (Label, Icon, Description), as Add source does on the Sources list, instead of turning the side pane into a "New type" form. Add creates the type and shows it; suggestions and formats are added on the type afterwards. This is the first of three PRs that move Source types to their own page (working rule "A Source type has its own page", user 2026-11-14): the side pane goes in S15-48, and Add needs its new home first.

**Why now.** S15-48 deletes the side pane, which holds today's add mode. S15-18's Copy from goes into this dialog.

**What stays.** The engine's create write (`createSourceType`), the minted key, the duplicate-key refusal, the "Type added" toast, the list, the side pane's view and edit modes, and the Add type button's place.

## 2. User stories

**US-1.** As a researcher, I add a Source type in a dialog and land on it.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Census selected. Click Add type | A dialog titled "Add source type" opens; Census stays selected in the list and shown in the side pane; Add type in the header is disabled (AT-1, AT-8) |
| AC-1.2 | Type "  Parish register " | The Key field reads "parish-register"; "Add type" is enabled (AT-2, AT-4) |
| AC-1.3 | Press Add type | One `createSourceType(label: "Parish register", description: "", iconKey: <default>)`; the dialog closes; navigation goes to `WorkspaceLocation.sourceTypePage(typeId: <new>, title: "Parish register")`; the list holds the new row before that navigation; the side pane shows it in edit mode; toast "Type added" (AT-7) |
| AC-1.4 | Click a mark other than the default in the grid, then Add | The grid shows it chosen and its meaning under the grid at once, with no second confirm; the created type carries that icon key (AT-3) |
| AC-1.5 | Full Keyboard Access on (as the app's lists, `PVList`, are reached by Tab); Tab from Description, then → and ↓ | Focus lands on the grid at the chosen mark; → chooses the next mark; ↓ chooses the mark five places on (one row of 5); → on the last mark does nothing (AT-9) |

**US-2.** As a researcher, the dialog refuses a bad label and keeps what I typed.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Label "   " | "Add type" is disabled; calling `create()` sets `labelError` "A label is required — it is how the type reads on a source." and calls no store (AT-4, AT-5) |
| AC-2.2 | Label "—" | `labelError` "That label cannot be turned into a key. Use at least one letter or number."; no store call (AT-5) |
| AC-2.3 | "Family scrapbook" exists as yours; add "Family scrapbook" | The engine's duplicate-key message under Label; the dialog stays open with the label (AT-5) |
| AC-2.4 | The store fails with any other error | A danger Callout at the top of the dialog; `labelError` nil; the dialog stays open (AT-5) |
| AC-2.5 | While saving | Every field in the dialog, the icon grid included, is disabled (AT-4) |

**US-3.** As a researcher, leaving the dialog behaves like every dialog.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Nothing typed, default icon | `isDirty` false; Escape closes with no confirm (AT-6) |
| AC-3.2 | Label typed, or a non-default icon picked | `isDirty` true; Escape asks the kit's discard confirm; Cancel closes at once (AT-6) |
| AC-3.3 | Census selected and its description edited, unsaved; open the dialog, Cancel | Census is still selected with the unsaved edit; nothing was written (AT-8) |

## 3. Scope

| In | Covered by |
| --- | --- |
| The Add type dialog: two columns at 840pt, Label, Key and Description left, the icon grid right (AT-1 – AT-4, AT-9, AT-W1) | STEP-4, STEP-6, AC-1.1 – AC-1.5, AC-2.5 |
| Errors and leaving (AT-5, AT-6) | STEP-4, STEP-6, AC-2.1 – AC-2.4, AC-3.1 – AC-3.3 |
| After Add: the new type selected and shown, toast (AT-7) | STEP-3, STEP-4, STEP-6, AC-1.3 |
| The side pane and list lose add mode (AT-8) | STEP-6 |
| One icon grid shared by the dialog and the side pane's "Choose an icon" sheet, with arrow keys | STEP-1, D-6, AC-1.5 |
| A created type reaches the types list through a declared cache patch (user, 2026-11-14) | STEP-3, D-4 |
| The duplicate-key code in the typed engine-code list | STEP-3, D-5 |
| The type page's location factory | STEP-3, D-7 |
| One two-column dialog body, its right column's width a parameter, shared with the Artifact sheet and the Evidence graph form (user, 2026-11-14) | STEP-2, D-11 |

| Out | Home |
| --- | --- |
| The Source type page; removing the side pane; the list / page model split; `mode` and `VocabularyPaneMode` out of Source types | S15-48 |
| Moving the type's update and delete writes off `patchTypesList` onto the cache patch, and deleting `patchTypesList` | S15-48 (user, 2026-11-14) |
| The suggestion count patch | S15-12 (`CatalogQueryPatch.typeSuggestionCount()`) |
| The list's columns and Wide | S15-49 |
| Copy from | S15-18 |
| Suggestions and formats on the type | S15-12, S15-17 |
| Return in Description adds (board AT-9's Shift-Return) | not planned (user, 2026-11-14: Return in a text area is a new line, as every dialog) |
| The grid wrapping under the fields below 790pt of pane (board AT-W1) | not planned (two columns at every width, as `SourceOwnerFormColumns`, user 2026-11-14) |
| The type page's icon field (a button and the sheet, or the grid inline) | S15-48 (D27 board) |
| The Metadata page's Add field (still a side pane form); `metadatafields.duplicate_key` in the engine-code list | not planned (working rule "A Source type has its own page") |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Header button | `macos/App/Features/SourceTypes/SourceTypesView.swift` `SourceTypesContent.header` → `VocabularyHeader(addLabel: L10n.SourceTypes.addType, isAddDisabled: model.isAdding, onAdd: { model.openAdd() })` | Opens add mode in the side pane |
| Add mode in the model | `macos/App/Features/SourceTypes/SourceTypesModel.swift` `openAdd()` (sets `mode = .adding(resumeID:)` and `draft`), `cancelAdd()` (re-selects `resumeID`), `isAdding` (computed from `mode`), `draftKey`, `canSubmit` (`isAdding \|\| isDirty`), `submit()` (the `.adding` arm: `createSourceType`, `session.apply(effects)`, `patchTypesList` append, `mode = .editing`, toast, returns `WorkspaceLocation(section: .sourceTypes, typeId:, title:)`; and `if isAdding && FieldSlug.kebab(label).isEmpty` before the switch), `syncSelection` (`if isAdding { return .ignored }`), `clearHistorySelection` (`guard !isAdding`), `showsDelete` (`!isAdding && …`), `formError` | One `draft` and one `formError` serve add and edit; add replaces the selection |
| Label rule | `SourceTypesModel.canSubmit`, `submit()` | Trimmed-blank check written in each; unslugifiable check in `submit()` |
| Icon in the model | `SourceTypesModel.applyDraftIconKey(_:)` | Writes the picker's pick into the edit `draft` |
| List selection | `macos/App/Features/SourceTypes/SourceTypesListPane.swift` line ~90 `selection` (`get: { model.isAdding ? nil : model.selectedType?.id }`, set builds `WorkspaceLocation(section: .sourceTypes, typeId:, title:)` inline at ~95) | Drops the highlight while adding |
| Add mode in the pane | `macos/App/Features/SourceTypes/SourceTypesDetailPane.swift` `content` (`if model.isAdding`), `panel` (`addSuggestionsNote`), `panelHeader` / `panelIconKey` / `panelTitle` / `panelKey` (add branches), `form` (add placeholders; `VocabularyFormActions(isSecondaryDisabled: … (!model.isAdding && !model.isDirty))` at ~206), `primaryLabel`, `secondaryLabel`, `secondaryAction`, `addSuggestionsNote`, `panelIdentity` (`.adding` → "adding"); its doc comment names "the add-type form" | Draws the "New type" form |
| Icon field and picker | `SourceTypesDetailPane` `iconPickerOpen`, `pendingIconKey`, `.pvFormDialog(… width: 660 …)` with `SourceTypeIconPickerForm` (private; `GridItem(.adaptive(minimum: 108))`, `PVMark` size 40, every mark its own `Button`, group label `L10n.SourceTypes.iconPickerGroupLabel`, ids `sourceTypes.iconPicker` and `sourceTypes.iconPicker.<key>`, the chosen mark's `typeMetaphor` under the grid), `commitPendingIconKey()`, `.onChange(of: panelIdentity)` closing it, `iconFieldButton(selection:)` (private, id `sourceTypes.form.icon`), `SelectedIconShadow` (private) | The grid is private to the pane; no arrow keys; each mark a Tab stop under Full Keyboard Access |
| Types list cache | `SourceTypesModel.patchTypesList(_:)` (private `setQueryValue`; used by create, update, assign, remove, delete); `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift` `.sourceTypesList` (no `patches`; follows `.list(.sourceVocabulary)`) | A hand patch beside the declared mechanism |
| Declared row patch precedent | `CatalogMutation.createdSource(CatalogSource)` (`CatalogMutation.swift`; `patchedSource`), `CatalogQueryPatch.sourceRow()` (`CatalogLastUpdated.swift` ~116), on `.sourcesList`'s `patches` | The shape to copy for a type row |
| Dialog-model precedent | `macos/App/Features/Sources/SourceCopyModel.swift` (`draft`, `titleError`, `copyError`, `isSaving`, `isDirty`, `canCopy`, `copy() async -> CatalogSource?`, `session.apply(effects, .createdSource(copy))`); `macos/App/Features/Sources/SourceCopyDialog.swift` (`View.sourceCopyDialog(_:)` → `pvFormDialog(item:copy:width:isRunning:isDirty:confirmDisabled:accessibilityIdentifierPrefix:onConfirm:form:)`, private `SourceCopyForm`); host `SourcesModel.copying: SourceCopyModel?` | A fresh model per open, held as one optional |
| Two-column dialog body | `macos/App/Features/Sources/SourceOwnerFormColumns.swift` `SourceOwnerFormColumns<Left, Right>(saveError:saveErrorTitle:saveErrorIdentifier:isSaving:left:right:)` (the save-error `PVCallout` with `announces: true` across the top, then two equal columns in an `HStack(spacing: space8)`, the left disabled while saving), used by `ArtifactSheet.swift` and `SourceGraphFormDialog.swift` at `SourceOwnerForm.dialogWidth` (880); same file `SourceOwnerForm`, `DraftMetadataBoardField` | Content-agnostic but filed under Sources; equal columns only |
| Arrow-key precedent | `macos/App/DesignSystem/Components/Chip/PVSegmentedControl.swift` `static func arrowTarget(items:selection:forward:)` (pure, tested) and `.onKeyPress(.leftArrow)` / `.rightArrow` | The shape to copy for the grid's keys |
| Draft validation precedent | `SourcesModel.Draft.validation` → `SourceDraftValidation` | One rule shared by add and copy |
| Minted key precedent | `macos/App/Features/Properties/PropertiesView.swift` create form (~840): `PVField(label: createKey, hint: createKeyHint) { PVInput(text: <minted>, mono: true, isReadOnly: true, prompt: createKeyPlaceholder) }`, id `properties.create.key` | A read-only mono Input, not a custom Text |
| Engine codes | `macos/App/Platform/ConclusionVocabulary.swift` `EngineErrorCode` (`init?(wire:)`), `macos/App/Platform/CoreInvoke.swift` `CoreInvokeError.engineCode`; `api/ffi/swift_vocabulary_test.go` row "engine error codes" (~499); `core/apperr/apperr.go` `CodeSourceTypesDuplicateKey`; `.cursor/rules/macos-client.mdc` (wire vocabulary is spelled once in Swift) | No case for a duplicate type key |
| Location precedent | `WorkspaceLocation.sourcePage(…)` in `macos/App/Features/Workspace/WorkspaceLocation.swift`; `SourcesListNavigation.pageLocation(for:)` | No type factory; the type location is built inline twice |
| Fake | `macos/App/Platform/FakeStore.swift` `createSourceType` (throws coded `sourcetypes.duplicate_key`), `createSourceTypeError` | |
| Copy | `L10n.SourceTypes` `addType`, `cancel`, `formLabel`, `formLabelPlaceholder`, `formIcon`, `formIconHint`, `formIconChangeAccessibility(name:)`, `formDescription`, `formDescriptionHint`, `formDescriptionPlaceholder`, `keyHintAdd`, `detailEyebrowNewType`, `addSuggestionsNote`, `errorLabelRequired`, `errorUnslugifiable`, `toastAddedTitle`, `toastAddedBody`, `iconPicker*` | |
| Tests | `macos/ProvenenciaTests/SourceTypesModelTests.swift` `addingMintsTheKeyFromTheLabelAndLandsOnTheNewType`, `addingATypeReloadsFromItsEffects`, `addingReturnsLocationForWorkspaceNavigation`, `addingRefusesABlankLabelWithoutCallingTheStore`, `addingRefusesALabelThatCannotBeSlugged`, `addingADuplicateUserKeySurfacesTheErrorAndKeepsTheForm`, `cancellingAddRestoresThePreviouslySelectedType`, `applyDraftIconKeyUpdatesPendingPickerSelection`, `syncSelectionIgnoredWhileAdding`, `createAndDeleteCommitThroughWorkspaceNavigation`, `changingIconMarksDirtyAndPersists`; `CatalogQueryRegistryTests` | Drive add through `openAdd` / `draft` / `submit` |
| Docs | `docs/design-system-layers.md` ~105 (names `SourceTypeIconPickerForm`) and ~162 "Source Types icon grid — snowflake form body inside `.pvFormDialog`"; `.agents/skills/evaluate-ui-component/SKILL.md` ~159 (names `SourceTypeIconPickerForm`); `macos/App/DesignSystem/README.md` ~183 FormDialog row | Name the old type; the grid is only in a sheet |

**Precedent.** Copy Source (`SourceCopyModel` + `SourceCopyDialog`): a model per open, the form beside it, `create` returning the row, `session.apply(effects, .createdSource(…))` with a declared row patch, the host navigating. Copy that shape whole.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | **A dialog model of its own** (user, 2026-11-14). `SourceTypeAddModel` *(new)* in `macos/App/Features/SourceTypes/SourceTypeAddModel.swift` (new): `@MainActor @Observable final class`, `init(session:userID:store:)`; `var draft = SourceTypesModel.Draft(label: "", description: "")`; `var labelError: String?`; `var createError: String?`; `private(set) var isSaving = false`; `var key: String` (`FieldSlug.kebab` of the trimmed label); `var isDirty: Bool` (trimmed label or description non-empty, or `draft.iconKey != PVMarkKey.defaultTypeMark.rawValue`); `var canAdd: Bool` (`!isSaving && draft.labelError == nil`); `func create() async -> CatalogSourceType?`. `SourceTypesModel` holds `var adding: SourceTypeAddModel?` *(new)*, `func openAdd()` sets it to a fresh model, `var isAdding: Bool { adding != nil }`, and `func showAdded(_ type: CatalogSourceType)` *(new)* sets today's "Type added" toast. `cancelAdd()` goes (the dialog clears `adding`) | Map review answer and user (2026-11-14): the Copy Source, graph form, Artifact sheet and Source date dialogs are item-bound models; nothing to reset on open; the edit draft cannot be touched; S15-48's split leaves it alone; S15-18 extends one file | Add fields on `SourceTypesModel` (the older Add Source shape) — about eight members and a shared `isSaving` on a model S15-48 splits |
| D-2 | **One label rule.** `SourceTypesModel.Draft` gains `var labelError: String?` *(new)*: trimmed label empty → `L10n.string(errorLabelRequired)`; `FieldSlug.kebab(trimmed)` empty → `L10n.string(errorUnslugifiable)`; else nil. `SourceTypeAddModel.canAdd` and `create()` read it; `SourceTypesModel.canSubmit` reads it in place of its trimmed-blank check, and `submit()` sets `formError = draft.labelError` and returns when non-nil, replacing its own two checks (the unslugifiable check now runs on edit too, which today's engine refuses anyway) | `SourcesModel.Draft.validation` precedent; one place for the rule (review M-8) | Four copies of the blank check |
| D-3 | **`create()`.** `guard !isSaving`; `labelError = draft.labelError`; return nil when set. `isSaving = true` (deferred false), `createError = nil`; `createSourceType(projectDir:, userID:, label: <trimmed>, description: <trimmed>, iconKey: draft.iconKey)`; on success `session.apply(effects, .createdSourceType(created))` (D-4) and return `created`. On failure: `(error as? CoreInvokeError)?.engineCode == .sourceTypeDuplicateKey` (D-5) → `labelError = L10n.Errors.message(for: error)`; any other → `createError = L10n.Errors.message(for: error)`; return nil. It writes nothing on `SourceTypesModel`: selection follows the navigation, as a row click does (`applySelection` sets `mode`, `draft`, `formError`, `suggestionError` and warms suggestions) | Copy Source precedent; review M-2: selection state set in one place | Today's `.adding` arm writing `mode` and `draft` — a list-model method writing page state |
| D-4 | **A declared row patch for a created type** (user, 2026-11-14: create now, the rest in S15-48). `CatalogMutation.createdSourceType(CatalogSourceType)` *(new)*, patch-only (`invalidationKind` nil, as `.updatedSource`); `var patchedSourceType: CatalogSourceType?` *(new)* on `CatalogMutation`; `CatalogQueryPatch.sourceTypeRow()` *(new)* in `CatalogLastUpdated.swift` beside `sourceRow()`: replaces the row with the same id, appends it on `.createdSourceType` when missing; added to `.sourceTypesList`'s `patches` in `CatalogQueryRegistry.swift`. `patchTypesList` stays for update, assign, remove and delete until S15-48 / S15-12 move them | Review M-4; one mechanism for list rows; the row must be in the list before `navigation.go` runs `syncSelection` (Edges) | All five writes now — S15-47 grows; a preparatory PR — the user chose create now |
| D-5 | **Typed duplicate code.** `EngineErrorCode.sourceTypeDuplicateKey` *(new)*, wire `"sourcetypes.duplicate_key"` in `init?(wire:)`, its doc comment updated; `api/ffi/swift_vocabulary_test.go` "engine error codes" row gains `apperr.CodeSourceTypesDuplicateKey` | `.cursor/rules/macos-client.mdc`: wire vocabulary is spelled once in Swift; the parity test fails if the code is renamed (review M-1) | A string literal in the model |
| D-6 | **One icon grid** (board AT-3, redrawn and agreed 2026-11-14: the grid inline in the dialog; the side pane's "Choose an icon" sheet keeps its picker). `SourceTypeIconPickerForm` is renamed `SourceTypeIconGrid` *(new name)* and moves, with `SelectedIconShadow`, to `macos/App/Features/SourceTypes/SourceTypeIconGrid.swift` (new), a snowflake: `init(selection: Binding<String>, columns: Int, groupLabel: LocalizedStringResource)`. Changes from today, all drawn on the board: `columns` × `GridItem(.flexible(), spacing: PVSpacing.space4)` replaces `.adaptive(minimum: 108)`; `PVMark` size 32 (today 40); the container's accessibility label is `groupLabel`. **Keys** (AT-9): the grid is one Tab stop. The `LazyVGrid` takes, in this order, `.focusable()`, `.focusEffectDisabled()`, `.focused($isFocused)` (a private `@FocusState var isFocused: Bool`) and `.onKeyPress`, as `PVList` does (`macos/App/DesignSystem/Components/List/PVList.swift` ~112); `iconCell(_:focused:)` takes `focused: isFocused && key.rawValue == selection` and that cell draws `.pvFocusRing(focused, cornerRadius: PVRadius.sm)`; every cell's `Button` takes `.focusable(false)` (a click still picks). The keys ←, →, ↑, ↓ map to `SourceTypeIconGrid.Move` *(new, nested: `enum Move { case left, right, up, down }`)* and set `selection` to `Self.arrowTarget(keys: PVMarkKey.typeKeys.map(\.rawValue), selection: selection, columns: columns, move:) -> String?` *(new, `static`, pure, as `PVSegmentedControl.arrowTarget`)*, returning `.handled`, or `.ignored` when it is nil: ← / → one place back or on, ↑ / ↓ `columns` places, nil (the key `.ignored`) past either end or when `selection` is not in the list; no wrap. The ids stay today's in every host (round 3 X-1): `sourceTypes.iconPicker` on the grid, `sourceTypes.iconPicker.<key>` on each cell. The chosen mark's `typeMetaphor` line stays under the grid. **Hosts.** The side pane keeps today's icon field (`iconFieldButton(selection:)`), its sheet (`iconPickerOpen`, `pendingIconKey`, `commitPendingIconKey()`, the 660pt `.pvFormDialog`, `.onChange(of: panelIdentity)`) and `SourceTypesModel.applyDraftIconKey(_:)`, and draws `SourceTypeIconGrid(selection: $pendingIconKey, columns: 6, groupLabel: L10n.SourceTypes.iconPickerGroupLabel)` in it. The dialog draws it inline (D-8) with `columns: 5` and `addIconGroupLabel`, bound straight to `draft.iconKey`: a pick is live and the dialog's Add type or Cancel keeps or drops it | Board AT-3 and its component *Source Type Icon Grid* (one grid, `columns` and a group label its props); map review K-6; the arrow rule is pure so it is tested without a view (T-12) | A second grid in the dialog; a sheet over the dialog (round 3 M-1: a click outside reaches both sheets); a disclosure (the board: it doubles the sheet's height) |
| D-7 | **The type page's location factory now.** `static func sourceTypePage(typeId: String, title: String? = nil) -> WorkspaceLocation` *(new)* beside `sourcePage` (whose `title` is `String? = nil` too; the list's setter passes `type?.label`) in `WorkspaceLocation.swift`, returning today's `WorkspaceLocation(section: .sourceTypes, typeId:, title:)`. The dialog's confirm and `SourceTypesListPane`'s `selection` setter use it. The map's S15-48 line changes from "adds" to "reuses" | Review M-5; one builder; S15-48 changes the place registry only | Inline locations in three places |
| D-8 | **The dialog view.** `View.sourceTypeAddDialog(_ model: Binding<SourceTypeAddModel?>, onAdded: @escaping (CatalogSourceType) -> Void)` *(new)* in `macos/App/Features/SourceTypes/SourceTypeAddDialog.swift` (new), shaped as `sourceCopyDialog`: `pvFormDialog(item:, copy: PVFormDialogCopy(title: addDialogTitle, subtitle: addDialogSubtitle, confirm: addType, cancel: cancel), width: SourceTypeAddForm.dialogWidth, isRunning: model?.isSaving ?? false, isDirty: model?.isDirty ?? false, confirmDisabled: !(model?.canAdd ?? false), accessibilityIdentifierPrefix: "sourceTypes.add", onConfirm: { guard let created = await $0.create() else { return false }; onAdded(created); navigation.go(to: .sourceTypePage(typeId: created.id, title: created.label)); return true }, form: { SourceTypeAddForm(model: $0) })`. `SourceTypesContent` adds `.sourceTypeAddDialog($model.adding) { model.showAdded($0) }`. **Form body** (private `SourceTypeAddForm`, with `static let dialogWidth: CGFloat = 840` and `static let iconColumnWidth: CGFloat = 432`, board frame 1a): `PVFormColumns(saveError: model.createError, saveErrorTitle: L10n.SourceTypes.addErrorTitle, saveErrorIdentifier: "sourceTypes.add.error", isSaving: model.isSaving, rightWidth: Self.iconColumnWidth)` (D-11; the board's frame 4b Callout is the shared body's, which announces). **Left**, top to bottom, all three inside `PVTabPair { label, description in … }` as the Create Property form (`PropertiesView.swift` ~823; the AppKit key loop skips a text area that follows a text field; `add-ui-component`'s checklist): `PVField(label: formLabel, error: labelError, marker: .required) { PVInput(text: $model.draft.label, prompt: formLabelPlaceholder, isInvalid: labelError != nil, focus: label) }` id `sourceTypes.add.label` (no explicit initial focus: no other form dialog sets one); `PVField(label: addKey, hint: keyHintAdd) { PVInput(text: .constant(model.key), mono: true, isReadOnly: true, prompt: addKeyPlaceholder) }` id `sourceTypes.add.key` (no handle: Tab skips it, as in Properties); `PVField(label: formDescription, hint: formDescriptionHint) { PVTextArea(text: $model.draft.description, lineLimit: 4...8, prompt: formDescriptionPlaceholder, focus: description) }` id `sourceTypes.add.description` (board: 4 to 8 rows; Return in it is a new line, user 2026-11-14, so Return adds only from Label). **Right:** `PVField(label: formIcon, hint: formIconHint) { SourceTypeIconGrid(selection: $model.draft.iconKey, columns: 5, groupLabel: L10n.SourceTypes.addIconGroupLabel) }` with `.disabled(model.isSaving)` (`PVFormColumns` disables only its left column). No required marker on Icon: a type always has one | Copy Source shape; the Create Property key field (review M-7); `PVFormDialog` disables only its buttons, so the form disables itself (AT-4); the owner forms' two-column body (D-11) | `pvFormDialog(isPresented:)` with model fields; a one-column form with an icon field button |
| D-9 | **The list and pane without add mode.** `SourceTypesListPane` `selection` get is `model.selectedType?.id`; its set uses D-7. `SourceTypesModel`: `submit()` loses its `.adding` arm and its `isAdding` slug check (D-2 covers it); `canSubmit` becomes `guard let draft` then `draft.labelError == nil && !isSaving && isDirty` (false with no draft); `syncSelection` and `clearHistorySelection` lose their `isAdding` guards; `showsDelete` becomes `selectedType != nil`; `draftKey` goes. `mode` is never `.adding`; its `.adding` arms stay for exhaustiveness (`VocabularyPaneMode` is shared with Metadata) until S15-48. `SourceTypesDetailPane` loses every add branch (§ 4 row), `isSecondaryDisabled` becomes `model.isSaving \|\| !model.isDirty`, and its doc comment drops "the add-type form". A successful Add replaces an unsaved edit in the side pane, as selecting another type does today | AT-8; reviews M-6, X-2, X-9 | Keeping the guards — they protected an add form no longer in the pane |
| D-10 | **Copy** (keys under `sourceTypes.add.*`, each with a comment). New: `addDialogTitle` (`sourceTypes.add.title`) = "Add source type"; `addDialogSubtitle` (`sourceTypes.add.subtitle`) = "A kind of record. Suggested fields and citation formats are added on the type afterwards."; `addKey` (`sourceTypes.add.key`) = "Key"; `addKeyPlaceholder` (`sourceTypes.add.keyPlaceholder`) = "Minted from the label"; `addErrorTitle` (`sourceTypes.add.errorTitle`) = "The type was not added" (board frame 4b); `addIconGroupLabel` (`sourceTypes.add.iconGroup`) = "Icon for the new source type" (board AT-9, the grid's VoiceOver group). Removed: `addSuggestionsNote`, `detailEyebrowNewType` | Brief § 2.1 as the agreed board draws it, with the key as a read-only field (review M-7) | A "Key: %@" sentence and a custom spoken label |

| D-11 | **One two-column dialog body, the right column's width a parameter** (user, 2026-11-14: the same component, the column width adjustable). `SourceOwnerFormColumns` moves out of `macos/App/Features/Sources/SourceOwnerFormColumns.swift` to `macos/App/DesignSystem/Components/FormDialog/PVFormColumns.swift` (new) as `PVFormColumns` *(new name)*, a design-system component: it names no `Features/` type. It gains `rightWidth: CGFloat? = nil`. Nil draws today's two equal columns, unchanged (the Artifact sheet and the Evidence graph form pass nothing). A value fixes the right column at that width (`.frame(width:)`), the left takes the rest, and the rule is a leading overlay on the right column, as `SourcesListRow.swift` ~45 draws its: the right column's content takes `.padding(.leading, PVSpacing.space8)`, `.frame(width: rightWidth, alignment: .topLeading)`, `.frame(maxHeight: .infinity, alignment: .top)` and `.overlay(alignment: .leading) { PVDivider(axis: .vertical) }`; the left column takes `.frame(maxHeight: .infinity, alignment: .top)` too, and the columns' `HStack` takes `.fixedSize(horizontal: false, vertical: true)`, so both columns are as tall as the taller and the rule runs its full height (board frame 1a). With `rightWidth` nil nothing changes. The width includes the rule and the padding, so the grid gets 432 − 1 − `space8`; the `HStack`'s `space8` spacing stays, so the rule sits `space8` from each column's content, as the board draws it. `SourceOwnerForm.dialogWidth` and `DraftMetadataBoardField` stay in Sources, in that file renamed `SourceOwnerForm.swift`; `ArtifactSheet.swift` and `SourceGraphFormDialog.swift` call `PVFormColumns` and their doc comments name it. `macos/App/DesignSystem/README.md`'s FormDialog row lists it | User, 2026-11-14; one two-column body in the app; content-agnostic, so the kit (`docs/design-system-layers.md` § 1) | A second two-column body in Source types (a copy of the owner forms' shape); a style modifier (the divider and the width belong to the column, which the component lays out) |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `SourceTypeAddModel` *(new file)* | model | `SourceCopyModel` | The same shape for this feature's fields (D-1) |
| `SourceTypeAddDialog.swift` *(new)*: `View.sourceTypeAddDialog(_:onAdded:)`, private `SourceTypeAddForm` | view | `SourceCopyDialog.swift` `sourceCopyDialog(_:)`, `SourceCopyForm` | Same shape; different fields; S15-18 adds Copy from here |
| `SourceTypeIconGrid` *(renamed, new file)* | view | `SourceTypeIconPickerForm` | The same grid moved and renamed, with `columns`, a group label and arrow keys (D-6) |
| `PVFormColumns` *(moved, renamed)*, `rightWidth` | component | `SourceOwnerFormColumns` | The same body moved to the kit with one parameter (D-11) |
| `SourceTypesModel.Draft.labelError` | func | `SourcesModel.Draft.validation` | Same idea for this draft (D-2) |
| `CatalogMutation.createdSourceType`, `patchedSourceType`; `CatalogQueryPatch.sourceTypeRow()` | mutation / patch | `.createdSource`, `patchedSource`, `CatalogQueryPatch.sourceRow()` | A different row type and list key (D-4) |
| `EngineErrorCode.sourceTypeDuplicateKey` | enum case | `EngineErrorCode` | Extends the one list (D-5) |
| `WorkspaceLocation.sourceTypePage(typeId:title:)` | factory | `WorkspaceLocation.sourcePage(…)` | Same pattern (D-7) |
| `L10n.SourceTypes.addDialogTitle`, `addDialogSubtitle`, `addKey`, `addKeyPlaceholder`, `addErrorTitle`, `addIconGroupLabel` | L10n | `L10n.Sources.addDialogTitle`, `L10n.Properties.createKey`, `createKeyPlaceholder` | Their copy names Sources and Properties |

**Builds on.** `PVFormColumns` (today's owner-form body); `pvFormDialog(item:)` and its discard confirm; the declared cache patches; `EngineErrorCode` and its Go parity row; today's create write and toast.
**Deletes.** `SourceTypesModel` `draftKey`, `cancelAdd()`, `submit()`'s `.adding` arm and `isAdding` slug check, the `isAdding` guards in `syncSelection` and `clearHistorySelection`, the stored-in-`mode` add path of `openAdd()`; `SourceTypesListPane`'s `isAdding ? nil` and its inline location; `SourceTypesDetailPane` add branches in `content`, `panel`, `panelHeader`, `panelIconKey`, `panelTitle`, `panelKey`, `form` (add placeholders and the `isAdding` part of `isSecondaryDisabled`), `primaryLabel`, `secondaryLabel`, `secondaryAction`, `addSuggestionsNote`, the `.adding` string in `panelIdentity`; the names `SourceTypeIconPickerForm` and `SourceOwnerFormColumns` (renamed, not copied) and the file `SourceOwnerFormColumns.swift` (renamed `SourceOwnerForm.swift`); strings `sourceTypes.form.addSuggestionsNote`, `sourceTypes.detail.eyebrowNewType`; tests `cancellingAddRestoresThePreviouslySelectedType`, `syncSelectionIgnoredWhileAdding` (replaced by T-6, T-8).
**Next adds.** S15-18 adds a Copy from field above Label in `SourceTypeAddForm`'s left column (the board keeps room) and a source type to `SourceTypeAddModel.create()`. S15-48 moves update and delete onto `.sourceTypeRow()` (an `.updatedSourceType` case), deletes `patchTypesList`, reuses `SourceTypeIconGrid` and `sourceTypePage(typeId:title:)` on the type page (its board S15-D27 decides inline or a sheet), and removes `mode` and its `.adding` arms. A third two-column dialog passes `rightWidth` or nothing to `PVFormColumns`.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A location change while the dialog is open (a menu Back) | `SourceTypesModel.syncSelection` | The pane follows; the dialog keeps its model (D-9); T-8 |
| The created type's location | `navigation.go(to:)` → `syncSelection` → `applySelection` | `.sourceTypeRow()` put the row in the list in `create()`'s `apply`, before `onConfirm` navigates; T-1, T-9 |

### Scale

None — one create per Add, as today; one row patch; no list or loop changes.

### Edges

- **Assumptions.** `syncSelection` after `create()` finds the new row because `session.apply(effects, .createdSourceType(created))` patched the warmed list synchronously before `navigation.go` (D-4); a list never warmed is warmed by the place and its load includes the row. T-1 and T-9 hold it.
- **Neighbors.** A label of spaces, a label of symbols, a duplicate key, another failure: AC-2.1 – AC-2.4. A label with outer spaces is trimmed: AC-1.2, T-1.
- **Removed inputs.** None — nothing is deleted.
- **Real data.** None — no table-driven rule.
- **Untrusted size.** None.

### Schema

None — no catalog change.

### Go core

None — today's `CreateSourceType`. The parity test row (D-5) is a test change.

### FFI

None — today's `createSourceType`.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Add type dialog | `pvFormDialog(item:)` | `SourceTypeAddDialog.swift` | D-8 |
| Dialog model | — | `SourceTypeAddModel.swift` | D-1, D-3 |
| Key | `PVField` + read-only mono `PVInput` | `SourceTypeAddForm` | D-8 |
| Icon grid | snowflake | `SourceTypeIconGrid.swift` | D-6; inline in the dialog's right column (5 columns, frame 3) and in the side pane's "Choose an icon" sheet (6 columns) |
| Two columns | `PVFormColumns` (`rightWidth: 432`) | `PVFormColumns.swift` *(new)* | D-11; the dialog 840pt (frames 1a, 1b) |
| Errors | `PVField` error; `PVFormColumns`'s danger `PVCallout` | `SourceTypeAddForm` | D-3, D-11 |
| List row patch | `CatalogQueryPatch.sourceTypeRow()` | `CatalogLastUpdated.swift`, `CatalogQueryRegistry.swift` | D-4 |
| Side pane, list | snowflakes | `SourceTypesDetailPane.swift`, `SourceTypesListPane.swift` | Add mode removed (D-9) |

States (board frames): empty dialog (1a, 1b); typing, key minted (2); a mark other than the default picked in the grid, its meaning under it (3); label error (4); create error Callout (4b); saving (5); discard confirm (6); after Add (7). While saving, the buttons follow `isRunning`, the left column `PVFormColumns`' `isSaving`, the grid its own `.disabled`. Accessibility: AT-9; the Key field reads by its label "Key" and value; the grid is one group, "Icon for the new source type", each mark read by its name with the selected trait on the chosen one, ← → ↑ ↓ choose (D-6).

### Strings

D-10. Old-scope copy: `addType` stays "Add type" as the header button and the dialog's confirm; `keyHintAdd` ("Provenencia mints the key from the label when the type is added") becomes the Key field's hint unchanged; `formLabelPlaceholder` and `formDescriptionPlaceholder` move from the pane's add mode to the dialog.

## 7. Steps

**STEP-1 — One icon grid**
Files: `SourceTypeIconGrid.swift` *(new)*, `SourceTypesDetailPane.swift`, `macos/ProvenenciaTests/SourceTypeIconGridTests.swift` *(new)*, `docs/design-system-layers.md`, `.agents/skills/evaluate-ui-component/SKILL.md`. Skills: `add-ui-component`, `add-swift-test`.
Do: D-6: move and rename the grid, add `columns`, `groupLabel`, size 32 and the keys; the side pane's sheet draws it with 6 columns; T-12. Rename `SourceTypeIconPickerForm` in `docs/design-system-layers.md` ~105 and `.agents/skills/evaluate-ui-component/SKILL.md` ~159, and make ~162 read "Source Types icon grid (`SourceTypeIconGrid`) — snowflake grid, inline in the Add type dialog and the body of the side pane's `.pvFormDialog` (chrome via FormDialog → `PVPanel`)".
Check: `SourceTypeIconGridTests` and `SourceTypesModelTests` pass; editing a type's icon in the side pane works (manual check 5).

**STEP-2 — One two-column dialog body**
Files: `PVFormColumns.swift` *(new)*, `SourceOwnerFormColumns.swift` → `SourceOwnerForm.swift`, `ArtifactSheet.swift`, `SourceGraphFormDialog.swift`, `macos/App/DesignSystem/README.md`. Skill: `add-ui-component`.
Do: D-11. `git mv` the file, then move the struct; `rightWidth` nil changes nothing in the two owner forms.
Check: the app builds with no Swift warning; `scripts/check-guidance-names.py` passes; the Artifact sheet and the Evidence graph form look as before (manual check 6).

**STEP-3 — The cache patch, the typed code, the location factory**
Files: `CatalogMutation.swift`, `CatalogLastUpdated.swift`, `CatalogQueryRegistry.swift`, `ConclusionVocabulary.swift`, `api/ffi/swift_vocabulary_test.go`, `WorkspaceLocation.swift`, `SourceTypesModel.swift` (today's add arm applies `.createdSourceType` instead of `patchTypesList`), `SourceTypesListPane.swift` (setter uses D-7), `CatalogQueryRegistryTests.swift`. Skills: `add-workspace-place`.
Do: D-4, D-5, D-7; T-10.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/ffi/...` passes; `CatalogQueryRegistryTests`, `SourceTypesModelTests` pass.

**STEP-4 — The add model**
Files: `SourceTypeAddModel.swift` *(new)*, `SourceTypesModel.swift` (`Draft.labelError`, `canSubmit`, `submit()` use it — D-2), `SourceTypesModelTests.swift`. Skill: `add-swift-test`.
Do: D-1 (the model only; `SourceTypesModel.adding` comes in STEP-6), D-2, D-3; T-1 – T-5 and T-7 against `SourceTypeAddModel` (T-6 needs `adding` and lands in STEP-6). Add a file-private `enum AddFailure: Error { case boom }` in the test file for T-5.
Check: `SourceTypesModelTests` passes.

**STEP-5 — Copy**
Files: `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`. Skill: `add-localized-string`.
Do: D-10's new keys only (the removals land in STEP-6 with their last readers).
Check: `python3 scripts/check-localizable-xcstrings.py` passes.

**STEP-6 — The dialog; the pane and list without add mode**
Files: `SourceTypeAddDialog.swift` *(new)*, `SourceTypesView.swift`, `SourceTypesModel.swift`, `SourceTypesDetailPane.swift`, `SourceTypesListPane.swift`, `L10n.swift`, `Localizable.xcstrings`, `SourceTypesModelTests.swift`. Skill: `add-ui-component`.
Do: D-8 (with STEP-1's grid and STEP-2's `PVFormColumns`), D-9, D-1's `adding` / `openAdd` / `showAdded`; delete `cancelAdd` and the add branches together with D-10's removed strings, in one compile unit; T-6, T-8, T-9.
Check: the app and tests build with no Swift warning; `SourceTypesModelTests` passes; manual check 1–4.

**STEP-7 — Version**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj`.
Do: the header's bump.
Check: the three agree.

**STEP-8 — Docs**
Files: `completed.md`, `deployment-plan.md` (map row), this plan (status), `design/S15-D26-add-source-type-dialog.md` → `design/archive/` (fix its relative links), `design/README.md`.
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py` passes; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `SourceTypesModelTests.addingMintsTheKeyFromTheLabelAndLandsOnTheNewType` (ported) | `SourceTypeAddModel`, `draft.label = "  Parish register "` → `key == "parish-register"`, `canAdd`; `create()` → a type with key `parish-register`, label "Parish register", origin user, default icon; the warmed types list holds it immediately after `create()` returns (before any `settleWrites`) | AC-1.2, AC-1.3, D-3, D-4 |
| T-2 | Swift | `addingATypeReloadsFromItsEffects` (ported) | First half through `SourceTypeAddModel.create()`; its second half keeps `SourceTypesModel.submit()` on the edit path (mode `.editing` after `syncSelection` to the new type), which calls `updateSourceType` | AC-1.3 |
| T-3 | Swift | `addingReturnsTheTypeTheDialogOpens` (renamed from `addingReturnsLocationForWorkspaceNavigation`) | `create()` returns the type; `WorkspaceLocation.sourceTypePage(typeId:title:)` of it has `section == .sourceTypes`, its `typeId`, title "Parish register" | AC-1.3, D-7 |
| T-4 | Swift | `addingRefusesABlankLabelWithoutCallingTheStore`, `addingRefusesALabelThatCannotBeSlugged` (ported) | "   " → `!canAdd`; `create()` nil, `labelError == errorLabelRequired`, the list unchanged. "—" → `labelError == errorUnslugifiable` | AC-2.1, AC-2.2, D-2 |
| T-5 | Swift | `addingADuplicateUserKeySurfacesTheErrorUnderTheLabel` (renamed) and `anotherCreateFailureShowsInTheDialog` *(new)* | Duplicate → nil, `labelError == L10n.Errors.sourceTypesDuplicateKey(key: "family-scrapbook")`, `createError == nil`. `createSourceTypeError = AddFailure.boom` → `createError != nil`, `labelError == nil` | AC-2.3, AC-2.4, D-3, D-5 |
| T-6 | Swift | `openingAndCancellingAddKeepsTheSelectionAndEdit` *(new; replaces `cancellingAddRestoresThePreviouslySelectedType`)* | Select t2, `draft?.description = "edited"`; `openAdd()` → `adding != nil`, `selectedType?.id == "t2"`, `draft?.description == "edited"`; `adding = nil` → `!isAdding`, same selection and draft; the types list unchanged | AC-1.1, AC-3.3, D-1 |
| T-7 | Swift | `addIsDirtyFollowsWhatWasTyped` *(new)* | Fresh → false; label "  " → false; label "P" → true; fresh, `iconKey = "type_photograph"` → true | AC-3.1, AC-3.2 |
| T-8 | Swift | `syncSelectionFollowsTheLocationWhileAdding` *(new; replaces `syncSelectionIgnoredWhileAdding`)* | `openAdd()`, `adding?.draft.label = "Diary"`, `syncSelection(.sourceTypePage(t1))` → `.applied`, `selectedType?.id == "t1"`, `adding?.draft.label == "Diary"` | D-9 |
| T-9 | Swift | `createAndDeleteCommitThroughWorkspaceNavigation` (ported) | `SourceTypeAddModel.create()`, `navigation.go(to: .sourceTypePage(…))`, `syncSelection` → the model's `selectedType` is the new one; delete as today | AC-1.3 |
| T-10 | Swift | `CatalogQueryRegistryTests.createdSourceTypePatchesTheTypesList` *(new)* | Warmed `.sourceTypesList`; `apply(.empty, .createdSourceType(row))` → the list ends with `row` and the handle is not fetching (`!handle.isFetching`, as the registry tests assert elsewhere); applied again → still one row | D-4 |
| T-12 | Swift | `SourceTypeIconGridTests.arrowTargetMovesByOneAndByARow` in `macos/ProvenenciaTests/SourceTypeIconGridTests.swift` *(new)* | keys `["a","b","c","d","e","f","g"]`, columns 5: from "a" → `.right` "b", `.left` nil, `.down` "f", `.up` nil; from "c" → `.down` nil (past the end); from "g" → `.right` nil, `.up` "b"; selection "zz" → nil for every move | AC-1.5, D-6 |
| T-11 | Go | `api/ffi/swift_vocabulary_test.go` "engine error codes" row | `apperr.CodeSourceTypesDuplicateKey` in `want` → passes with D-5's case | D-5 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `SourceTypesModelTests`, `CatalogQueryRegistryTests`.

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
- [ ] Domain doc updated: docs/design-system-layers.md ~105 and ~162 and .agents/skills/evaluate-ui-component/SKILL.md ~159 name `SourceTypeIconGrid`; macos/App/DesignSystem/README.md's FormDialog row lists `PVFormColumns` (STEP-1, STEP-2)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

Run on a Mac with the app built (the `run` skill), at Regular and with the window stretched to a Wide pane. Evidence for this section and for check-pr's Xcode leg comes from a Mac run.

1. Source types; select Census and change its description without saving. Click Add type: the dialog opens; Census stays selected in the list and in the side pane with the edit; the header's Add type is disabled (AC-1.1).
2. Type "Parish register": the Key field reads "parish-register". The dialog is two columns, the grid on the right with Evidence (the default mark) chosen, the rule between the columns running their full height, and its meaning under it. Click another mark: it is chosen and its meaning shows, with no other sheet. With Full Keyboard Access on (System Settings › Keyboard › Keyboard navigation), Tab from Label: focus goes to Description (the Key is skipped); Tab from Description: focus lands on the grid, the chosen mark ringed; → and ↓ move the choice by one and by a row (AC-1.5). Click Add type: the dialog closes, Parish register is selected and shown with its icon, the toast shows (AC-1.2 – AC-1.4). While it saves, the fields and the grid are disabled (AC-2.5).
3. Add type again; type "Parish register": the duplicate-key message under Label; the dialog stays (AC-2.3). Clear the label: Add is disabled (AC-2.1).
4. Type something, press Escape: the discard confirm; Cancel closes at once, selection and the unsaved edit unchanged (AC-3.2, AC-3.3). Open and Escape with nothing typed: closes at once (AC-3.1).
5. Select a type of yours, click its icon's Change: the "Choose an icon" sheet shows the same grid in 6 columns; pick a mark, Use icon, Save: it keeps the icon (STEP-1).
6. Open a Source's Artifact sheet and an Evidence graph's form: both are two equal columns at 880pt, as before (STEP-2).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| The focusable grid breaks the dialog's Tab order or the side pane sheet's Return | Stop condition below; manual checks 2 and 5 |
| `navigation.go` runs before the list holds the new row | D-4's patch runs inside `create()`; T-1 checks the list right after it |

**Stop and report if:**

- With `.focusable()` on the grid, Tab from Description does not reach it, or Tab from the grid does not reach the dialog's buttons, or Return on the focused grid no longer confirms the side pane's sheet.
- `PVFormColumns` needs a `Features/` type to compile in `DesignSystem/Components/` (check-guidance-names fails).
- `CatalogQueryPatch` patches do not run for a nil-kind mutation applied with `session.apply(_:_:)` (T-10 fails as written).
- The engine no longer reports a duplicate type key as `sourcetypes.duplicate_key`.
- The board draws a field this plan does not list (Copy from, an editable key, suggestions).

## 12. Open questions

None.

## 13. PR

**Title:** S15-47 — Adding a Source type opens a dialog
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-47-add-source-type-dialog.md`.
