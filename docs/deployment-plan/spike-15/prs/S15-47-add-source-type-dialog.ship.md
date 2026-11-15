# Ship log — S15-47 Adding a Source type opens a dialog

**Plan:** [`S15-47-add-source-type-dialog.md`](S15-47-add-source-type-dialog.md) · **Branch:** `s15-47-add-source-type-dialog` · **PR:** #843
**State:** fixing 1

Base: `origin/main` @ `44944d6`. The branch was cut before round 0 and carries the plan commit `2230bce` (the plan docs ride on the PR branch); the implementer switches to it instead of creating it.

## Round 0 — implement
Head `0c6e183`. Gate PASS (run by the orchestrator: diff-check, gofmt, go-vet, go-test, localizable, guidance-names, plan-docs, xcode-test, swift-warnings). Report deviations: `SourceTypeIconGridTests` is `@MainActor` (the static `arrowTarget` is main-actor-isolated; a plain suite raised a Swift warning). § 10 manual check not run (no Mac UI session): AC-1.5's Tab order and focus ring, AC-2.5's saving state, Wide, and the two UI stop conditions (the grid's Tab reach, Return in the side pane's sheet) are unverified. The plan's § 4 still names `SourceOwnerFormColumns.swift`; plan-docs passes because the plan is Landed.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. UX: `macos/App/**`, `Localizable.xcstrings`. SEC+PRF: performance paths (`macos/App/Features/**` models: `SourceTypeAddModel`, `SourceTypesModel`; cache code: `CatalogQueryRegistry`, `CatalogLastUpdated` row patch); no security path touched, it rides with performance.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | blocker | `sourceTypeRow()` copies `sourceRow()` and drops its create-only append | Fix now → F-1 | verified: `CatalogLastUpdated.swift` 116 vs 136; the copy appends on any `patchedSourceType`, against its own doc comment; S15-48 adds `.updatedSourceType`. Same-pass cleanup |
| CON-1 | CON | major | AC-1.3 toast and AC-1.4 picked icon lost their tests | Fix now → F-2 | verified: no SourceTypes test calls `showAdded` or creates with a non-default icon |
| UX-2 | UX | major | Label errors never show ("—" just disables Add) and the duplicate message goes stale | Fix now → F-3 | verified: `labelError` is written only in `create()`; `canAdd` blocks `create()`; `SourceTitleTypeFields.showErrors()` is the live precedent |
| UX-3 | UX | major | The duplicate-key refusal is silent to VoiceOver | Fix now → F-4 | verified: `PVField` draws `PVErrorText(error)` with `announces: false` |
| UX-1 | UX | major | The dialog opens with no field focused | Fix now → F-5 (user, 2026-11-14) | verified: Label has no `activateOnAppear`; contradicted D-8's "no other form dialog sets one", which is false (`SourceTitleTypeFields.swift:33`, `ArtifactSheet.swift:114`). User: focus Label |
| MNT-2 | MNT | major | `submit()` returns a location that is always nil; the pane still navigates on it | Fix now → F-6 | verified: every return in `submit()` is nil after the `.adding` arm went |
| MNT-3 | MNT | major | Cache guidance does not list `.createdSourceType` / the row patch | Fix now → F-7 | verified: `docs/macos-client-patterns.md` ~89, ~92 and `add-workspace-place` Patch row |
| CON-2 | CON | major | § 10 manual check not run; view-only ACs and stop condition 1 unproven | Rejected (to the user's manual check) | the loop hands § 10 to the user at finish (ship-pr step 8); the report lists every unproven AC and the two UI stop conditions |
| MNT-4 | MNT | minor | Label trim and key computed in five places | Fix now → F-8 | minor in files this PR adds; `SourcesModel.Draft.trimmedTitle` precedent |
| UX-4 | UX | minor | Key placeholder never drawn (`PVInput` read-only ignores `prompt`) | Fix now → F-9 | verified: `PVInput.swift` ~134 read-only branch draws only `Text(text)`; fixes Create Property's key too |
| MNT-5 | MNT | minor | `PVFormColumns` has no `#Preview` | Fix now → F-10 | `add-ui-component` checklist |
| UX-5 | UX | minor | Subtitle promises citation formats before S15-17 | To user → keep board copy (user, 2026-11-14) | formats arrive in S15-17 |
| SEC/PRF | SEC+PRF | — | No findings | — | — |

Nits (logged): `CON-3 · SourceTypesModelTests.swift:310 · test the trimmed description on create` · `MNT-6 · PVFormColumns.swift:59-82 · build the right column once` · `MNT-7 · L10n.swift · translator comments still say "add-type form"` · `MNT-8 · SourceTypesDetailPane.swift:90 · Deletes names the .adding panelIdentity string D-9 keeps` · `UX-6 · SourceTypeIconGrid.swift:303 · the meaning line is not announced on arrow moves`

### Fix plan 1

**F-1 — One generic row patch for cached lists** (from MNT-1)
Files: `macos/App/Features/Workspace/Session/CatalogLastUpdated.swift`, `CatalogMutation.swift`, `macos/ProvenenciaTests/CatalogQueryRegistryTests.swift`. Skill: `add-workspace-place`.
Failing test first: `CatalogQueryRegistryTests.aNonCreateSourceTypeMutationForAMissingRowAddsNothing` — `.sourceTypeRow()` today appends for any `patchedSourceType`. The test drives the patch closure directly or through a test-only mutation; if no non-create case of `patchedSourceType` exists, the test calls the new generic `row` patch with `appendsOn` false and asserts the list is unchanged.
Do: add one private generic `CatalogQueryPatch.row<Row: Identifiable & Sendable>(_: Row.Type, patched: @escaping (CatalogMutation) -> Row?, appendsOn: @escaping (CatalogMutation) -> Bool) -> Self where Row.ID == String` holding `sourceRow()`'s body (replace the row with the same id; append only when `appendsOn`; otherwise `false`). `sourceRow()` and `sourceTypeRow()` become one-line calls: `appendsOn` is `.createdSource` / `.createdSourceType`. Keep both doc comments, now true. Move `patchedSourceType` into the `extension CatalogMutation` beside `patchedSource`.
Check: T-10 and the new test pass; the Sources patch tests unchanged and green; `rg -n "sources.append\(|types.append\(" macos/App/Features/Workspace/Session` prints nothing (the appends live only in the generic); scripts/check-pr.sh PASS.

**F-2 — Test the toast and the picked icon** (from CON-1)
Files: `macos/ProvenenciaTests/SourceTypesModelTests.swift`. Skill: `add-swift-test`.
Test: `addingCarriesThePickedIconAndToasts` — `draft.label = "Diary"`, `draft.iconKey = "type_photograph"`, `create()` → `created.iconKey == "type_photograph"`; `model.showAdded(created)` → `model.toast?.title == L10n.string(L10n.SourceTypes.toastAddedTitle)`.
Check: passes.

**F-3 — Live label errors after the first edit** (from UX-2)
Files: `SourceTypeAddModel.swift`, `SourceTypeAddDialog.swift`, `SourceTypesModelTests.swift`.
Failing test first: `editingTheLabelShowsAndClearsItsError` — on a fresh model `labelError == nil`; `editLabel("—")` → `labelError == errorUnslugifiable`; after a duplicate refusal from `create()`, `editLabel("Diary")` → `labelError == nil`.
Do: copy `SourceTitleTypeFields`' rule. `SourceTypeAddModel.editLabel(_ new: String)` *(new)*: guard `new != draft.label`; `draft.label = new`; `labelError = draft.labelError`. The Label `PVInput` binds through it (`get: { model.draft.label }`, `set: { model.editLabel($0) }`). Nothing shows on open. `canAdd` stays as is (Add stays disabled while the rule fails; the reason now shows). `create()` keeps setting `labelError` from the engine's duplicate code.
Check: the test passes; T-4 and T-5 still pass.

**F-4 — Announce the write's label error** (from UX-3)
Files: `macos/App/DesignSystem/Components/Field/PVField.swift`, `SourceTypeAddModel.swift`, `SourceTypeAddDialog.swift`, `SourceTypesModelTests.swift`.
Do: `PVField` gains `announcesError: Bool = false` *(new)*, passed to `PVErrorText(error, announces: announcesError)`; every existing call site compiles unchanged. `SourceTypeAddModel` gains `private(set) var labelErrorFromWrite = false` *(new)*: `create()` sets it true when it sets `labelError` from the engine (the duplicate), false otherwise; `editLabel` sets it false. The Label `PVField` passes `announcesError: model.labelErrorFromWrite`, so typing never announces and a refused Add does.
Check: extend T-5 — after the duplicate, `labelErrorFromWrite == true`; after `editLabel("x")`, false.

**F-5 — Focus Label on open** (from UX-1; user, 2026-11-14)
Files: `SourceTypeAddDialog.swift`, the plan's D-8 Landed note.
Do: `activateOnAppear: true` on the Label `PVInput`, as `SourceTitleTypeFields.swift:33`. Add a line to the plan's Landed note: D-8's "no explicit initial focus" was reversed in review (UX-1, user 2026-11-14).
Check: build; manual (the user's § 10 check 1).

**F-6 — `submit()` returns nothing** (from MNT-2)
Files: `SourceTypesModel.swift`, `SourceTypesDetailPane.swift`, `SourceTypesModelTests.swift`.
Do: `submit()` returns `Void` (drop `@discardableResult` and every `return nil` → `return`); the pane's `onPrimary` calls `Task { await model.submit() }`; remove the pane's `@Environment(WorkspaceNavigation.self) private var navigation` if no other use remains.
Check: `rg -n "navigation" macos/App/Features/SourceTypes/SourceTypesDetailPane.swift` prints nothing; tests build and pass with no Swift warning.

**F-7 — Cache guidance names the new patch** (from MNT-3)
Files: `docs/macos-client-patterns.md` (~89, ~92), `.agents/skills/add-workspace-place/SKILL.md` (~62).
Do: add `.createdSourceType` (patch-only, `.sourceTypeRow()` on `.sourceTypesList`) to the kept-mutations sentence; name `sourceTypeRow()` beside `sourceRow()` for a create that returns its row, and say both are the generic row patch (F-1); name it in the skill's Patch row; one clause that `patchTypesList` still serves update, assign, remove and delete until S15-48 / S15-12.
Check: `rg -n "sourceTypeRow|createdSourceType" docs/macos-client-patterns.md .agents/skills/add-workspace-place/SKILL.md` prints the new lines; `scripts/check-guidance-names.py` passes.

**F-8 — One trimmed label and key on the draft** (from MNT-4)
Files: `SourceTypesModel.swift` (`Draft`), `SourceTypeAddModel.swift`.
Do: `Draft.trimmedLabel` and `Draft.key` *(new, computed)*, as `SourcesModel.Draft.trimmedTitle`; `labelError`, `SourceTypeAddModel.key`, `isDirty`, `create()` and `submit()` read them.
Check: `rg -n "trimmingCharacters" macos/App/Features/SourceTypes/SourceTypeAddModel.swift` prints at most the description's trim; tests pass.

**F-9 — A read-only input shows its prompt when empty** (from UX-4)
Files: `macos/App/DesignSystem/Components/Input/PVInput.swift`.
Do: in the read-only branch, when `text` is empty and `prompt` is set, draw `Text(prompt)` in the same placeholder colour the editable `TextField` prompt uses (`PVColor.textMuted` unless the file names another token), with an empty `accessibilityValue`. Fixes the Add type and Create Property key fields.
Check: build; `PVInput`'s `#Preview` (or a new one) shows a read-only empty input with its prompt.

**F-10 — `PVFormColumns` preview** (from MNT-5)
Files: `PVFormColumns.swift`.
Do: a `#Preview` with static text: equal columns with a save error, and `rightWidth: 432`.
Check: builds.
