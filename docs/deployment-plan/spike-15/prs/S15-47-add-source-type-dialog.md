# S15-47 — Adding a Source type opens a dialog

**Status:** Blocked — on board S15-D26
**Spike / slice:** Spike 15 · Slice 2 — Metadata at three levels
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D26](../design/S15-D26-add-source-type-dialog.md), board not drawn yet
**Board:** — (record the link and frame names here when the board is agreed; then fill D-5 from its AT-3 answer)
**Depends on:** S15-D26
**Blocks:** S15-48, S15-18
**Branch:** `s15-47-add-source-type-dialog`
**Version bump:** patch, 0.15.0 → **0.15.1** (or the next patch after `main`'s `VERSION` when you rebase): `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj` — a Mac UI change to an existing flow, no new capability and no wire change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/swift-tests.mdc`
**Context:** working rule "A Source type has its own page" ([map](../deployment-plan.md#working-rules)); [`docs/design-system-layers.md`](../../../design-system-layers.md) (the icon grid is its snowflake example)
**Planned:** 2026-11-14 against `main` @ `43fd47e`
**Review:** — (not reviewed yet)

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
| AC-1.1 | Census selected. Click Add type | A dialog titled "Add source type" opens; the side pane still shows Census; Add type in the header is disabled (AT-1, AT-8) |
| AC-1.2 | Type "Parish register" | The key preview reads "Key: parish-register"; "Add type" is enabled (AT-2, AT-4) |
| AC-1.3 | Press Add type | One `createSourceType(label: "Parish register", description: "", iconKey: <default>)`; the dialog closes; the location is the new type's (`section: .sourceTypes`, its `typeId`, title "Parish register"); the side pane shows it in edit mode; toast "Type added" (AT-7) |
| AC-1.4 | Pick an icon other than the default, then Add | The created type carries that icon key (AT-3) |

**US-2.** As a researcher, the dialog refuses a bad label and keeps what I typed.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Label "   " | "Add type" is disabled; calling `create()` sets the label error "A label is required — it is how the type reads on a source." and calls no store (AT-4, AT-5) |
| AC-2.2 | Label "—" | Label error "That label cannot be turned into a key. Use at least one letter or number."; no store call (AT-5) |
| AC-2.3 | "Family scrapbook" exists as yours; add "Family scrapbook" | The engine's duplicate-key message under Label; the dialog stays open with the label (AT-5) |
| AC-2.4 | The store fails with any other error | A danger Callout at the top of the dialog; the label error is nil; the dialog stays open (AT-5) |

**US-3.** As a researcher, leaving the dialog behaves like every dialog.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Nothing typed, default icon | `addIsDirty` false; Escape closes with no confirm (AT-6) |
| AC-3.2 | Label typed, or a non-default icon picked | `addIsDirty` true; Escape asks the kit's discard confirm; Cancel closes at once (AT-6) |
| AC-3.3 | Census selected; open the dialog, Cancel | Census is still selected; nothing was written (AT-8) |

## 3. Scope

| In | Covered by |
| --- | --- |
| The Add type dialog with Label, key preview, Icon, Description (AT-1 – AT-4, AT-9, AT-W1) | STEP-3, STEP-4, AC-1.1 – AC-1.4 |
| Errors and leaving (AT-5, AT-6) | STEP-2, STEP-4, AC-2.1 – AC-2.4, AC-3.1 – AC-3.3 |
| After Add: the new type selected and shown, toast (AT-7) | STEP-2, STEP-4, AC-1.3 |
| The side pane loses its add mode (AT-8) | STEP-4 |
| One icon field shared by the dialog and the side pane's edit form, in its own file | STEP-1, D-5 |

| Out | Home |
| --- | --- |
| The Source type page; removing the side pane; splitting `SourceTypesModel` into list and page models; deleting `VocabularyPaneMode` use | S15-48 |
| The list's columns and Wide | S15-49 |
| Copy from | S15-18 |
| Suggestions and formats on the type | S15-12, S15-17 |
| The Metadata page's Add field (still a side pane form) | not planned (working rule "A Source type has its own page") |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Header button | `macos/App/Features/SourceTypes/SourceTypesView.swift` `SourceTypesContent.header` → `VocabularyHeader(addLabel: L10n.SourceTypes.addType, isAddDisabled: model.isAdding, onAdd: { model.openAdd() })` | Opens add mode in the side pane |
| Add mode in the model | `macos/App/Features/SourceTypes/SourceTypesModel.swift` `openAdd()` (sets `mode = .adding(resumeID:)` and `draft`), `cancelAdd()` (re-selects `resumeID`), `isAdding` (computed from `mode`), `draftKey`, `canSubmit` (`isAdding \|\| isDirty`), `submit()` `.adding` arm (`createSourceType`, `session.apply(effects)`, `patchTypesList` append, `mode = .editing(created.id)`, toast, returns `WorkspaceLocation(section: .sourceTypes, typeId:, title:)`), `syncSelection` (`if isAdding { return .ignored }`), `clearHistorySelection` (`guard !isAdding`), `showsDelete` (`!isAdding && …`), `formError` (every add failure, shown under Label) | One `draft` and one `formError` serve add and edit; add replaces the selection |
| Icon in the model | `SourceTypesModel.applyDraftIconKey(_:)` | Writes the picker's pick into the edit `draft` |
| Add mode in the pane | `macos/App/Features/SourceTypes/SourceTypesDetailPane.swift` `content` (`if model.isAdding`), `panel` (`addSuggestionsNote`), `panelHeader` / `panelIconKey` / `panelTitle` / `panelKey` (add branches), `form` (add placeholders), `primaryLabel`, `secondaryLabel`, `secondaryAction`, `addSuggestionsNote`, `panelIdentity` (`.adding` → "adding") | Draws the "New type" form |
| Icon field and picker | `SourceTypesDetailPane` `iconPickerOpen`, `pendingIconKey`, `.pvFormDialog(… width: 660 …)` with `SourceTypeIconPickerForm` (private struct), `commitPendingIconKey()`, `iconFieldButton(selection:)` (private), `SelectedIconShadow` (private) | Private to the pane; S15-48 deletes the pane |
| Precedent | `macos/App/Features/Sources/SourcesListView.swift` `.pvFormDialog(isPresented: addPresented, copy:, isRunning: model.isSaving, isDirty: model.addSheetIsDirty, confirmDisabled: !model.canSubmitAdd, accessibilityIdentifierPrefix: "sources.add", onConfirm:)`, `addPresented`, `addForm`; `macos/App/Features/Sources/SourcesModel.swift` `isAdding`, `draft`, `titleError`, `createError`, `canSubmitAdd`, `addSheetIsDirty`, `openAdd()`, `cancelAdd()`, `create()` | The shape to copy: a stored `isAdding`, a separate add draft, field errors and a create error, `create()` returning what the view navigates to |
| Error code | `macos/App/Platform/CoreInvoke.swift` `CoreInvokeError.code`; `FakeStore.createSourceType` throws `CoreInvokeError.coded(code: "sourcetypes.duplicate_key", …)`; `FakeStore.createSourceTypeError` | The duplicate key is a coded error the model can tell apart |
| Copy | `macos/App/Platform/L10n.swift` `L10n.SourceTypes` `addType`, `cancel`, `formLabel`, `formLabelPlaceholder`, `formIcon`, `formIconHint`, `formDescription`, `formDescriptionHint`, `formDescriptionPlaceholder`, `keyHintAdd`, `detailEyebrowNewType`, `addSuggestionsNote`, `errorLabelRequired`, `errorUnslugifiable`, `toastAddedTitle`, `toastAddedBody`, `iconPickerTitle`, `iconPickerSubtitle`, `iconPickerConfirm`, `iconPickerCancel` | |
| Tests | `macos/ProvenenciaTests/SourceTypesModelTests.swift` `addingMintsTheKeyFromTheLabelAndLandsOnTheNewType`, `addingATypeReloadsFromItsEffects`, `addingReturnsLocationForWorkspaceNavigation`, `addingRefusesABlankLabelWithoutCallingTheStore`, `addingRefusesALabelThatCannotBeSlugged`, `addingADuplicateUserKeySurfacesTheErrorAndKeepsTheForm`, `cancellingAddRestoresThePreviouslySelectedType`, `applyDraftIconKeyUpdatesPendingPickerSelection`, `syncSelectionIgnoredWhileAdding`, `createAndDeleteCommitThroughWorkspaceNavigation` | Drive add through `openAdd` / `draft` / `submit` |
| Docs | `docs/design-system-layers.md` line ~162 "Source Types icon grid — snowflake form body inside `.pvFormDialog`" | True today; changes only if the board puts the grid inline (D-5) |

**Precedent.** The Sources list's Add source dialog (`SourcesListView` + `SourcesModel`, above): copy the stored `isAdding`, the separate draft, the dirty rule, the field error vs create error split and `create()` returning the place to `go(to:)`.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | **Add state on the model, apart from the edit state.** `SourceTypesModel` gains `private(set) var isAdding = false` *(stored; replaces the computed one)*, `var addDraft = Draft(label: "", description: "")` *(new; `Draft` as today, `iconKey` defaulting to `PVMarkKey.defaultTypeMark.rawValue`)*, `var addLabelError: String?` *(new)*, `var addError: String?` *(new)*, `var addDraftKey: String` *(replaces `draftKey`: `FieldSlug.kebab(addDraft.label)`)*, `var canSubmitAdd: Bool` *(new: `!isSaving` and a non-blank trimmed label)*, `var addIsDirty: Bool` *(new: trimmed label or description non-empty, or `iconKey` not the default)*. `isSaving` is shared (the dialog is modal). `mode`, `draft` and `formError` keep serving the side pane's edit mode only | The Sources list precedent; the side pane keeps its selection under the dialog (AT-8) | Reusing `draft` / `formError` for both — the dialog would wipe an edit in progress |
| D-2 | **Open, cancel, create.** `openAdd()` resets `addDraft`, `addLabelError`, `addError` and sets `isAdding = true`; it does not touch `mode`, `draft` or `formError`. `cancelAdd()` sets `isAdding = false` unless `isSaving`. `create() async -> WorkspaceLocation?` *(new)*: blank trimmed label → `addLabelError = errorLabelRequired`, nil; empty `addDraftKey` → `addLabelError = errorUnslugifiable`, nil; else `isSaving`, `createSourceType(label:, description:, iconKey:)` from `addDraft`; on success today's `.adding` arm body (`session.apply(effects)`, `patchTypesList` append, `mode = .editing(id: created.id)`, `draft = Draft(created)`, `formError = nil`, `suggestionError = nil`, toast `toastAddedTitle` / `toastAddedBody`), `isAdding = false`, and returns `WorkspaceLocation(section: .sourceTypes, typeId: created.id, title: created.label)`. On failure: `(error as? CoreInvokeError)?.code == "sourcetypes.duplicate_key"` → `addLabelError = L10n.Errors.message(for: error)`; any other → `addError = L10n.Errors.message(for: error)`; `isAdding` stays true | AT-5, AT-7; one create path | Every failure under Label (today) — an engine failure is not the label's fault (AT-5) |
| D-3 | **`submit()` is edit-only.** Its `.adding` arm goes; `canSubmit` drops `isAdding \|\|`. `syncSelection` drops `if isAdding { return .ignored }` and `clearHistorySelection` drops `guard !isAdding`: the dialog is modal and the pane behind it follows the location as it does without it. `showsDelete` becomes `selectedType != nil`. `cancelAdd`'s resume logic goes. `mode` is never set to `.adding`; its `.adding` arms stay for exhaustiveness (`VocabularyPaneMode` is shared with Metadata) until S15-48 removes `mode` from Source types | AT-8 | Keeping the guards — they protected an add form that no longer lives in the pane |
| D-4 | **The dialog view.** `SourceTypesContent` (in `SourceTypesView.swift`) presents `.pvFormDialog(isPresented: addPresented, copy: PVFormDialogCopy(title: L10n.SourceTypes.addDialogTitle, subtitle: L10n.SourceTypes.addDialogSubtitle, confirm: L10n.SourceTypes.addType, cancel: L10n.SourceTypes.cancel), isRunning: model.isSaving, isDirty: model.addIsDirty, confirmDisabled: !model.canSubmitAdd, accessibilityIdentifierPrefix: "sourceTypes.add", onConfirm: { Task { if let location = await model.create() { navigation.go(to: location) } } })` with `addPresented` bound as `SourcesListView.addPresented` is. The body is `SourceTypeAddForm(model:)` *(new)* in `macos/App/Features/SourceTypes/SourceTypeAddForm.swift` (new): `addError` Callout (`sourceTypes.add.error`), Label (`PVField` `.required`, `error: addLabelError`, placeholder `formLabelPlaceholder`, id `sourceTypes.add.label`), the key preview (`L10n.SourceTypes.addKeyPreview(key:)` in mono, hint `keyHintAdd`, id `sourceTypes.add.key`), `SourceTypeIconField(selection: $model.addDraft.iconKey)` (id `sourceTypes.add.icon`), Description (`PVInput`, hint and placeholder as today, id `sourceTypes.add.description`). Width: the kit default, as Add source | The precedent; S15-18 adds Copy from in `SourceTypeAddForm` | The form inline in `SourceTypesView` — S15-18 would grow the shell file |
| D-5 | **One icon field.** `SourceTypeIconField` *(new)* in `macos/App/Features/SourceTypes/SourceTypeIconField.swift` (new): `@Binding var selection: String`; draws today's `iconFieldButton` look and owns the picker; `SourceTypeIconPickerForm` and `SelectedIconShadow` move into this file unchanged. The side pane's edit form uses `SourceTypeIconField(selection: draft.iconKey)`; the pane's `iconPickerOpen`, `pendingIconKey`, `commitPendingIconKey()`, its `.pvFormDialog` for the picker, its `.onChange(of: panelIdentity)` and `SourceTypesModel.applyDraftIconKey(_:)` go. **How the picker opens is AT-3's board answer, filled here before Planned:** a sheet (`.pvFormDialog` with the field's own `@State` pending key, 660pt, today's copy, confirm writes `selection`) or inline (the grid under a `PVDisclosureButton`, writing `selection` on tap). If inline, `docs/design-system-layers.md`'s example sentence is updated to say so | Brief inventory; map review K-6: S15-48's page reuses it | Copying the button into the dialog — two icon fields when S15-48 lands |
| D-6 | **Copy.** New: `L10n.SourceTypes.addDialogTitle` = "Add source type", `addDialogSubtitle` = "A kind of record. Suggested fields and citation formats are added on the type afterwards.", `addKeyPreview(key:)` = "Key: %@" (the view passes "—" when `addDraftKey` is empty). Removed: `addSuggestionsNote`, `detailEyebrowNewType`. Final wording from the board | Brief § 2.1 | — |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `SourceTypesModel.addDraft`, `addLabelError`, `addError`, `addDraftKey`, `canSubmitAdd`, `addIsDirty`, `create()`; stored `isAdding` | model members | `SourcesModel.draft`, `titleError`, `createError`, `canSubmitAdd`, `addSheetIsDirty`, `create()` | The same shape on this feature's model (D-1, D-2); a shared add-dialog model for two lists would be a second abstraction for two callers with different fields |
| `SourceTypeAddForm` *(new file)* | view | `SourcesListView.addForm` | Private to the Sources list; this one holds different fields and gains Copy from in S15-18 |
| `SourceTypeIconField` *(new file)* | view | `SourceTypesDetailPane.iconFieldButton(selection:)`, `SourceTypeIconPickerForm` | Moved, not copied (D-5) |
| `L10n.SourceTypes.addDialogTitle`, `addDialogSubtitle`, `addKeyPreview(key:)` | L10n | `L10n.Sources.addDialogTitle`, `addDialogSubtitle` | Their copy names Sources |

**Builds on.** `pvFormDialog` and its discard confirm; `VocabularyHeader`'s Add button; today's create write and toast.
**Deletes.** `SourceTypesModel` `draftKey`, `applyDraftIconKey(_:)`, `submit()`'s `.adding` arm, `cancelAdd`'s resume logic, the `isAdding` guards in `syncSelection` and `clearHistorySelection`; `SourceTypesDetailPane` add branches in `content`, `panel`, `panelHeader`, `panelIconKey`, `panelTitle`, `panelKey`, `form` (add placeholders), `primaryLabel`, `secondaryLabel`, `secondaryAction`, `addSuggestionsNote`, the `.adding` case's own `panelIdentity` string, `iconPickerOpen`, `pendingIconKey`, `commitPendingIconKey()`, the picker's `.pvFormDialog`, `iconFieldButton(selection:)`; strings `sourceTypes.form.addSuggestionsNote`, `sourceTypes.detail.eyebrowNewType`; tests `cancellingAddRestoresThePreviouslySelectedType`, `applyDraftIconKeyUpdatesPendingPickerSelection`, `syncSelectionIgnoredWhileAdding` (replaced by T-6, T-8).
**Next adds.** S15-18 adds a Copy from field to `SourceTypeAddForm` and a source type id to `create()`. S15-48 reuses `SourceTypeIconField` on the type page and changes `create()`'s returned location to the page's factory; the `.adding` arms go with `mode`.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A location change while the dialog is open (a menu Back) | `SourceTypesModel.syncSelection` | The pane follows the location; the dialog keeps `addDraft` (D-3); T-8 |
| The created type's location | `navigation.go(to:)` → `syncSelection` → `applySelection` | `mode` is already `.editing(created.id)`; `applySelection` resets `draft` from the list row, which `patchTypesList` already holds; T-1 |

### Scale

None — one create per Add, as today; no list or loop changes.

### Edges

- **Assumptions.** `syncSelection` after `create()` finds the new row because `patchTypesList` appended it before `navigation.go` (today's order); T-1 holds it.
- **Neighbors.** A label of spaces (AT-4), a label of symbols (unslugifiable), a duplicate key, another failure: AC-2.1 – AC-2.4.
- **Removed inputs.** None — nothing is deleted.
- **Real data.** None — no table-driven rule.
- **Untrusted size.** None.

### Schema

None — no catalog change.

### Go core

None — today's `CreateSourceType`.

### FFI

None — today's `createSourceType`.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Add type dialog | `pvFormDialog` | `SourceTypesView.swift` `SourceTypesContent` | D-4 |
| Form body | snowflake | `SourceTypeAddForm.swift` *(new)* | D-4 |
| Icon field | snowflake | `SourceTypeIconField.swift` *(new)* | D-5; AT-3 from the board |
| Errors | `PVField` error; `PVCallout` danger | `SourceTypeAddForm` | D-2 |
| Side pane | snowflake | `SourceTypesDetailPane.swift` | Add mode removed; edit form uses `SourceTypeIconField` |

States: empty dialog; typing; saving (`isRunning`); label error; create error; discard confirm. Accessibility: AT-9 (the key preview's label is "Key, \(key)"; the icon field's is today's `formIconChangeAccessibility(name:)`).

### Strings

New and removed: D-6. Old-scope copy: `L10n.SourceTypes.addType` keeps "Add type" as the header button and the dialog's confirm; `keyHintAdd` ("Provenencia mints the key from the label when the type is added") moves to the dialog unchanged.

## 7. Steps

**STEP-1 — One icon field**
Files: `SourceTypeIconField.swift` *(new)*, `SourceTypesDetailPane.swift`, `SourceTypesModel.swift`, `SourceTypesModelTests.swift`. Skill: `add-ui-component`.
Do: D-5 in the board's AT-3 form; the pane's edit form uses it; delete `applyDraftIconKey` and the pane's picker state; delete `applyDraftIconKeyUpdatesPendingPickerSelection` (`changingIconMarksDirtyAndPersists` already covers the draft).
Check: `SourceTypesModelTests` passes; editing a type's icon in the side pane works as before (manual check 5).

**STEP-2 — The model adds apart from editing**
Files: `SourceTypesModel.swift`, `SourceTypesModelTests.swift`. Skill: `add-swift-test`.
Do: D-1, D-2, D-3; port the add tests (T-1 – T-8).
Check: `SourceTypesModelTests` passes.

**STEP-3 — Copy**
Files: `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`. Skill: `add-localized-string`.
Do: D-6.
Check: `python3 scripts/check-localizable-xcstrings.py` passes.

**STEP-4 — The dialog, and the pane without add mode**
Files: `SourceTypeAddForm.swift` *(new)*, `SourceTypesView.swift`, `SourceTypesDetailPane.swift`. Skill: `add-ui-component`.
Do: D-4; remove the pane's add branches (§ 6 Deletes).
Check: the app builds with no Swift warning; manual check 1–4.

**STEP-5 — Version**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj`.
Do: the header's bump.
Check: the three agree.

**STEP-6 — Docs**
Files: `completed.md`, `deployment-plan.md` (map row), this plan (status), `design/S15-D26-add-source-type-dialog.md` → `design/archive/` (fix its relative links), `design/README.md`, `docs/design-system-layers.md` (only if D-5 is inline).
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py` passes; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `SourceTypesModelTests.addingMintsTheKeyFromTheLabelAndLandsOnTheNewType` (ported) | `openAdd()`, `addDraft.label = "Parish register"` → `addDraftKey == "parish-register"`; `create()` → `!isAdding`, `selectedType?.key == "parish-register"`, origin user, default icon, `mode == .editing(id:)` of it, toast title `toastAddedTitle` | AC-1.2, AC-1.3, D-2 |
| T-2 | Swift | `addingATypeReloadsFromItsEffects` (ported to `create()`; its second half keeps `submit()` on the edit path) | as today | AC-1.3 |
| T-3 | Swift | `addingReturnsLocationForWorkspaceNavigation` (ported) | `create()` → `section == .sourceTypes`, `typeId == selectedType?.id`, title "Parish register" | AC-1.3 |
| T-4 | Swift | `addingRefusesABlankLabelWithoutCallingTheStore`, `addingRefusesALabelThatCannotBeSlugged` (ported) | "   " → `!canSubmitAdd`; `create()` nil, `addLabelError == errorLabelRequired`, types empty. "—" → `addLabelError == errorUnslugifiable` | AC-2.1, AC-2.2 |
| T-5 | Swift | `addingADuplicateUserKeySurfacesTheErrorUnderTheLabel` (renamed) and `anotherCreateFailureShowsInTheDialog` *(new)* | Duplicate → `isAdding`, `addLabelError == L10n.Errors.sourceTypesDuplicateKey(key: "family-scrapbook")`, `addError == nil`. `createSourceTypeError = StoreBoom.boom` → `addError != nil`, `addLabelError == nil`, `isAdding` | AC-2.3, AC-2.4, D-2 |
| T-6 | Swift | `openingAndCancellingAddKeepsTheSelection` *(new; replaces `cancellingAddRestoresThePreviouslySelectedType`)* | Select t2, `openAdd()` → `selectedType?.id == "t2"`, `draft` unchanged; `cancelAdd()` → `!isAdding`, still t2, no create call | AC-1.1, AC-3.3, D-1 |
| T-7 | Swift | `addIsDirtyFollowsWhatWasTyped` *(new)* | Fresh → false; label "  " → false; label "P" → true; reset, `iconKey = "type_photograph"` → true | AC-3.1, AC-3.2 |
| T-8 | Swift | `syncSelectionFollowsTheLocationWhileAdding` *(new; replaces `syncSelectionIgnoredWhileAdding`)* | `openAdd()`, `addDraft.label = "Diary"`, `syncSelection(t1)` → `.applied`, `selectedType?.id == "t1"`, `isAdding`, `addDraft.label == "Diary"` | D-3 |
| T-9 | Swift | `createAndDeleteCommitThroughWorkspaceNavigation` (ported to `create()`) | as today | AC-1.3 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `SourceTypesModelTests`.

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
- [ ] Domain doc updated if a rule in docs/*.md changed: docs/design-system-layers.md, only if the icon grid went inline (D-5)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

Run on a Mac with the app built (the `run` skill), at Regular and with the window stretched to a Wide pane.

1. Source types; select Census. Click Add type: the dialog opens over the page, Census stays in the side pane, the header's Add type is disabled (AC-1.1).
2. Type "Parish register": the key preview reads "Key: parish-register". Pick another icon (AT-3's way). Click Add type: the dialog closes, Parish register is selected and shown in edit mode with its icon, the toast shows (AC-1.2 – AC-1.4).
3. Add type again; type "Parish register": the duplicate-key message under Label; the dialog stays (AC-2.3). Clear the label: Add is disabled (AC-2.1).
4. Type something, press Escape: the discard confirm; Cancel instead closes at once and Census-or-Parish-register selection is unchanged (AC-3.2, AC-3.3). Open and Escape with nothing typed: closes at once (AC-3.1).
5. Select a type of yours, change its icon in the side pane, Save: it keeps the icon (STEP-1).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A sheet over a sheet misbehaves on macOS (AT-3 sheet answer) | Stop condition below |
| `navigation.go` runs before the list holds the new row | T-1 / T-9 hold today's order |

**Stop and report if:**

- The board's AT-3 answer is a sheet and presenting `.pvFormDialog` from inside the Add type dialog does not show it (or dismisses the dialog).
- `FakeStore.createSourceType` or the engine no longer reports a duplicate as `sourcetypes.duplicate_key`.
- The board draws a field this plan does not list (Copy from, a key that can be typed, suggestions).

## 12. Open questions

- Board S15-D26 and its AT-3 answer (sheet or inline icon grid). Recommended: whatever the board agrees; D-5 and § 6 macOS are filled from it, then review-plan reruns on those parts and the status moves to Planned.

## 13. PR

**Title:** S15-47 — Adding a Source type opens a dialog
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-47-add-source-type-dialog.md`.
