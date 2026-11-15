# Ship log — S15-48 Source types open on their own page

**Plan:** [`S15-48-source-type-page.md`](S15-48-source-type-page.md) · **Branch:** `s15-48-source-type-page` · **PR:** #848
**State:** ready

## Round 0 — implement
Head `df13d1b11`. Gate PASS (orchestrator, against `36671255e`). Report deviations: base moved (S16 cache-key refactor; version is 0.15.3, patches check `key.kind`/`key.ownId`); `MetadataModelTests.renamingAFieldReloadsItsDependents` now expects hidden type suggestions stale-then-reload (D-7 `.markStale`); small additions (`FakeStore.updateSourceTypeHold`, `WorkspaceSession.sourceTypesKey`, `CatalogRowPresence.of` `@MainActor`, `WorkspaceLeaveGuardInstallTests` suite, `aSaveWithNoEffectsReloadsNothing`); `PromoteView` dropped its unused `navigation` property. Not run: manual check, board comparison in a browser, AC-1.4 scroll restore in the running app.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. Skipped: none. UX: `macos/App/**` and `Localizable.xcstrings`. SEC+PRF: performance paths (`macos/App/Features/**` models, `CatalogQueryRegistry` cache code); no security path, the combined reviewer covers both.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| UX-2 | UX | major | Save, suggestion and delete failures not announced; a store failure on Save shows under Label | Fix now → F-1 | verified: `SourceTypePageModel.submit()` catch sets `formError` (line ~170), `PVField` without `announcesError`; callouts default `announces: false` |
| UX-1 | UX | major | Blank-label message unreachable; only a disabled Save | Fix now → F-2 | verified: `canSubmit` needs `labelError == nil`; `formError` set only in `submit()` |
| MNT-1 | MNT | major | Leave-confirm ask state, binding and confirm copied a third time | Fix now → F-3 (same-pass cleanup) | verified: `struct PendingLeave` + `leaveBinding` in CitationComposer, Promote, SourceTypePage; this PR changes all three views. Supersedes D-8's per-page `PendingLeave`/`leaveBinding` shape; no researcher-visible change |
| MNT-2 | MNT | major | List model keeps a private types-list key beside `session.sourceTypesKey` | Fix now → F-4 (same-pass cleanup) | verified: `rg "\.sourceTypesList\(project: session"` → SourceTypesModel:39, PromoteModel:111, CitationComposerModel:436, SourcesModel:124, SourceCopyModel:50, SourcePageModel:117, SourcePageContext:112. Supersedes D-2's keep of `typesListKey` |
| MNT-3 | MNT | major | Type and field fixtures copied into two test suites | Fix now → F-5 (same-pass cleanup) | verified: identical blocks in `SourceTypePageModelTests.swift:11-37`, `SourceTypesModelTests.swift:13-39`; `CatalogFixtures.swift:44` exists |
| CON-1 | CON | major | § 10 manual check not run; list-side ACs and AC-1.4 scroll stop condition unproven | Rejected (as a code finding) → To user in the report | ship-pr step 8: the user runs § 10. Report flags step 2 (scroll restore on Back) as the plan's Stop condition |
| CON-2 | CON | minor | T-11 passes with `onActivate` deleted | Fix now → F-6 | verified: `PVList.swift` unchanged; test calls only `PVListKeyboard.action` |
| MNT-4 | MNT | minor | `PVPageColumns` written four times, loading shell twice | Fix now → F-7 | file this PR adds |
| MNT-5 | MNT | minor | Unused `navigation` in `SourceTypesContent` | Fix now → F-7 | file this PR changes |
| MNT-6 | MNT | minor | `layoutWidths` recomputes `available` and the stacking rule | Fix now → F-8 | file this PR changes |
| UX-3 | UX | minor | Gone type leaves with no notice | Fix now → F-9 | `SourcePageView.swift:203-206` passes `notice:` |
| UX-5 | UX | minor | Long header label truncates with no `.help` | Fix now → F-9 | file this PR adds |
| UX-4 | UX | minor | Leaving during a Save drops its result | To user | contradicts D-8 "saving → not held"; asked at finish, does not block |

Nits (logged): `MNT-7 · SourceTypesListPane.swift:98-99 · use $highlighted` · `MNT-8 · PVPageColumns.swift:179 · copy .standard and set sideMax` · `MNT-9 · SourceTypePageModel.swift:97, EvidenceGraphModel.swift:131 · CatalogRowPresence.isGone` · `MNT-10 · SourceTypeSuggestionList.swift:9 · isLocked passed beside model` · `UX-6 · L10n.swift:8055,8085,8270 · comments say panel` · `UX-7 · PVTable.swift:381 · Space opens the row mid type-to-select (D-9 named Space)` · `CON-3 · SourceTypePageModel.swift:309 · name the parameter _`

### Fix plan 1

Nits ride along when the file is open: MNT-7, MNT-8, MNT-9, MNT-10, UX-6, CON-3.

**F-1 — Write failures on the type page are announced, and a Save failure is not a Label error** (from UX-2)
Files: `macos/App/Features/SourceTypes/SourceTypePageModel.swift`, `SourceTypePageView.swift`, `SourceTypeSuggestionList.swift`, `SourceTypePageHeader.swift`. Skill: `add-localized-string` if copy is needed (reuse `L10n.Errors.message(for:)`, no new strings expected).
Failing test first: `SourceTypePageModelTests.aStoreFailureOnSaveIsNotALabelError` — a FakeStore failure on `updateSourceType` leaves `labelError` nil and sets `saveError`.
Do: split the model's `formError` into `labelError` (validation only) and `saveError` (write failure), as `SourceTypeAddModel` splits `labelError`/`createError`. Show `saveError` as `PVCallout(tone: .danger, …, announces: true)` beside `VocabularyFormActions`. Pass `announces: true` on the suggestion-error and delete-error callouts.
Check: test passes; `rg "PVCallout\(tone: \.danger" macos/App/Features/SourceTypes` shows every hit with `announces: true`; scripts/check-pr.sh PASS.

**F-2 — The blank-label message shows as the researcher edits** (from UX-1)
Files: `SourceTypePageModel.swift`, `SourceTypePageView.swift`.
Failing test first: `SourceTypePageModelTests.clearingTheLabelShowsTheRequiredMessage` — `editLabel("")` sets `labelError` to the required message while `canSubmit` stays false.
Do: add `editLabel(_:)` to the page model following `SourceTypeAddModel.editLabel(_:)`; bind the Label `PVInput` through it. Keep Save disabled. Update `blankLabelRefusesSave` if it no longer needs to call `submit()`.
Check: test passes; scripts/check-pr.sh PASS.

**F-3 — One leave-confirm for every guarded page** (from MNT-1; same-pass cleanup)
Files: `macos/App/Features/Workspace/WorkspaceNavigation.swift` (beside `.workspaceLeaveGuard`), `SourceTypePageModel.swift`/`SourceTypePageView.swift`, `CitationComposer/CitationComposerModel.swift`/`CitationComposerView.swift`, `Promote/PromoteModel.swift`/`PromoteView.swift`, tests that reference `PendingLeave`.
Failing test first: `WorkspaceLeaveGuardInstallTests.confirmCancelKeepsEditing` (or the nearest existing T-9 case extended) — clearing the shared confirm's item calls the guard's keep-editing answer.
Do: move the ask state and its two answers into the shared guard API so `.workspaceLeaveGuard` (or one sibling modifier) presents the `pvConfirm` itself and callers pass only the copy and the accessibility prefix. The composer's `keepDraft` and Promote's navigation payload may stay as their item types (generic item). Delete the three `leaveBinding`s and the per-model `PendingLeave` structs that become identical. Supersedes D-8's per-page `PendingLeave`/`leaveBinding` shape: note it in the plan's Landed note. Accessibility identifiers and copy stay as they are today.
Check: `rg -n "leaveBinding|struct PendingLeave" macos/App` prints nothing (or only a payload type the composer/Promote still need — name it in the report); `CitationComposerModelTests`, `PromoteModelTests`, `SourceTypePageModelTests` pass; scripts/check-pr.sh PASS.

**F-4 — One Source types list key, on the session** (from MNT-2; same-pass cleanup)
Files: `SourceTypesModel.swift`, `SourceTypesView.swift`, `Promote/PromoteModel.swift` (+ `PromoteView.swift:57`), `CitationComposer/CitationComposerModel.swift`, `Sources/SourcesModel.swift`, `Sources/SourceCopyModel.swift`, `Sources/SourcePageModel.swift`, `Sources/SourcePageContext.swift`.
Failing test first: none (refactor); existing suites cover it.
Do: delete `SourceTypesModel.typesListKey(for:)` and the `sourceTypesKey` properties on Promote and the composer; read `session.sourceTypesKey` / `session.sourceTypesHandle`. Leave `PlaceRegistry.swift` and `ConclusionPageSection.swift`, which build from a `project` parameter, not a session.
Check: `rg -n "\.sourceTypesList\(project: session" macos/App` prints only `WorkspaceSession+SourceTypes.swift:6`; `rg -n "typesListKey" macos` prints nothing; scripts/check-pr.sh PASS.

**F-5 — Shared Source type and field fixtures** (from MNT-3; same-pass cleanup)
Files: `macos/ProvenenciaTests/CatalogFixtures.swift`, `SourceTypePageModelTests.swift`, `SourceTypesModelTests.swift`. Skill: `add-swift-test`.
Do: add `catalogSourceType(…)` (or seeded/user/plugin helpers) and extend `catalogMetadataField` with `dataType` and `usedBy` defaults; both suites call them; delete the private copies. Search the other test files for the same body shape (`CatalogSourceType(` built inline with seeded/user/plugin origins) and move any copy this PR touches.
Check: `rg -n "seededType|userType|pluginType" macos/ProvenenciaTests` hits only call sites or `CatalogFixtures.swift`; scripts/check-pr.sh PASS.

**F-6 — T-11 fails when `PVTable` loses activation** (from CON-2)
Files: `macos/App/DesignSystem/Components/Table/PVTable.swift`, `macos/ProvenenciaTests/PVListTests.swift` (or `PVTableSelectionTests`).
Failing test first: `PVTableSelectionTests.returnActivatesOnlyWithOnActivate` — the pure helper returns the row for Return/Space when an activate handler exists, and nil without one.
Do: pull `handleKey`'s Return/Space step into a small pure helper beside `PVTableSelection` and call it from `handleKey`.
Check: test passes; scripts/check-pr.sh PASS.

**F-7 — One page frame in the type page view; drop the unused environment** (from MNT-4, MNT-5)
Files: `SourceTypePageView.swift`, `SourceTypesView.swift`.
Do: build one `PVPageColumns(headerPinned:scrollResetKey:split:header:)` and switch only primary/secondary on loaded / failed / loading; reuse one loading view. Delete `@Environment(WorkspaceNavigation.self) private var navigation` in `SourceTypesContent`.
Check: `rg -c "PVPageColumns\(" macos/App/Features/SourceTypes/SourceTypePageView.swift` prints 1; scripts/check-pr.sh PASS.

**F-8 — `layoutWidths` reads the stacking decision once** (from MNT-6)
Files: `macos/App/DesignSystem/Components/PageColumns/PVPageColumns.swift`.
Do: have `columnWidths(pane:…)` return `stacked` (or `PVPageSideColumnWidths`) from `widths(…)`; `layoutWidths` reads it instead of recomputing `available` and calling `split.stacks` again.
Check: `PVPageColumnsTests` pass; scripts/check-pr.sh PASS.

**F-9 — Gone notice and full-label help on the type page** (from UX-3, UX-5)
Files: `SourceTypePageView.swift`, `SourceTypePageHeader.swift`, `L10n.swift`, `Localizable.xcstrings`. Skill: `add-localized-string`.
Do: pass `notice:` to `.leavesForSectionRoot` with a new `L10n.SourceTypes.goneNotice(label:)` built as `SourcePageView.swift:203-206` builds the Source's; add `.help(type.label)` to the header title as `SourcePageIdentityHeader.swift:216-220` does.
Check: `L10nResolutionTests` and the xcstrings lint pass; scripts/check-pr.sh PASS.

## Round 1 — fix
Head `662fb2801`. Gate PASS (orchestrator). F-1 – F-9 done, nits MNT-7 – MNT-10, UX-6, CON-3 done. Deviations: tests and fixes written in one batch (new symbols do not compile alone), not run red one by one; F-7 makes the loading and failed states reserve the Suggested fields column (visible layout change, in the Landed note); composer's and Promote's `PendingLeave` payload types stay, as allowed; F-4 also removed `SourcesModel.sourceTypesListKey`.
CON-2 (minor, no round 2 for CON): **Resolved** — `PVTableSelection.activationTarget(…canActivate:)` called from `handleKey`; `PVTableSelectionTests.returnActivatesOnlyWithOnActivate` fails if `onActivate` is dropped from the guard.

## Round 2 — review
Reviewers: UX (UX-1, UX-2), MNT (MNT-1 – MNT-3). Not sent: CON (CON-1 rejected, CON-2 minor resolved above), SEC+PRF (no findings).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| UX-1 | UX | major | (round 1) blank-label message unreachable | Resolved | `editLabel(_:)`; `clearingTheLabelShowsTheRequiredMessage` |
| UX-2 | UX | major | (round 1) write failures silent; Save failure under Label | Resolved | `labelError`/`saveError` split; four danger callouts `announces: true`; `aStoreFailureOnSaveIsNotALabelError` |
| MNT-1 | MNT | major | (round 1) leave confirm copied | Resolved | `.workspaceLeaveConfirm`; `rg leaveBinding macos/App` empty |
| MNT-2 | MNT | major | (round 1) types-list key copies | Resolved | `rg "\.sourceTypesList\(project: session\|typesListKey\|sourceTypesListKey" macos/App` empty |
| MNT-3 | MNT | major | (round 1) fixture copies | Resolved | `CatalogFixtures.swift:43-81` |
| UX-8 | UX | minor | A page opened on an already-deleted type leaves with `“” was deleted.` | To user (open) | verified: `SourceTypePageModel.lastLabel = ""` (line 99) until `noteLabel` sees a label; F-9 introduced it. Minor, so no Fix plan 2 under the round cap |

Nits (logged): `MNT-11 · SourcesModel.swift:139,190 · use session.sourceTypesHandle` · `MNT-12 · SourcesModelTests.swift:517 · use session.sourceTypesKey`

## Result
Gate PASS at `baa6aab6d` (main unmoved since branch cut) · CI green at `676d87bfe` after one CI fix (F-10) · open: UX-8 (minor, to user) · to user: UX-4 (leave during Save, contradicts D-8), UX-8, CON-1 (§ 10 manual check incl. AC-1.4 scroll restore Stop condition) · follow-ups: none

## CI — gate failure 1
Head `3e0177e26`. Go tests PASS. macOS tests FAIL on CI (passed locally in check-pr): `WorkspaceLeaveGuardInstallTests.leaveGuardModifierInstallsAndClears` — `WorkspaceNavigationTests.swift:964` expected `navigation.leaveGuard == nil` after `shown.isShown = false; host.layoutSubtreeIfNeeded()`. Timing in a hosted window: the `onDisappear` had not run on the CI runner. One fix round (F-10).

**F-10 — The T-9 install test waits for the page to go before it checks** (CI)
Files: `macos/ProvenenciaTests/WorkspaceNavigationTests.swift` (and the modifier only if the test shows a real defect). Skill: `add-swift-test`.
Do: find how the other `.hostedWindows` suites settle a view change (a run-loop pump or helper in `HostedWindow.swift` or neighbouring tests) and use it after hiding the page, in both `leaveGuardModifierInstallsAndClears` and `leaveGuardModifierLeavesAnotherGuardInPlace`. No sleeps with fixed long waits; no weakening the assertion.
Check: the suite passes locally repeated (`-test-iterations 20` or a loop); scripts/check-pr.sh PASS; CI macOS tests green.

## CI — fix
Head `baa6aab6d`. Gate PASS (orchestrator). F-10 done: both install tests wait with `waitUntil` for the page's `onDisappear` before asserting; assertions unchanged; 20 local iterations pass. Not reproduced locally (timing hardening).

## After round 2 — UX-8 (user, 2026-11-15: "Yes, fix UX-8")
UX-8 moves from To user to **Fix now → F-11**. A minor after the round cap, fixed at the user's word; no review round 3. The orchestrator reads the fix.

**F-11 — A gone type the page never named gets a label-free notice** (from UX-8)
Files: `macos/App/Features/SourceTypes/SourceTypePageModel.swift`, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `macos/ProvenenciaTests/SourceTypePageModelTests.swift`. Skill: `add-localized-string`.
Failing test first: `SourceTypePageModelTests.aTypeGoneBeforeItWasShownGetsAnUnnamedNotice`. Open the page on a type id that is not in a settled list, so `noteLabel` never saw a label. `goneNotice` must equal the new unnamed string and must not contain `“”`.
Do: add `L10n.SourceTypes.goneNoticeUnnamed`, defaultValue "This source type no longer exists.", key `sourceTypes.page.goneNoticeUnnamed`, beside `goneNotice(label:)`. Word it like `conclusions.person.gone`. In `goneNotice`, use it when `lastLabel` is empty after trimming. Otherwise keep `goneNotice(label:)`. `goneTypeNamesItselfInTheNotice` still passes.
Check: both tests pass; `L10nResolutionTests` and the xcstrings lint pass; scripts/check-pr.sh PASS.

## UX-8 — fix
Head `a90d675e9`. Gate PASS (orchestrator). CI macOS green. F-11 done: red first (`aTypeGoneBeforeItWasShownGetsAnUnnamedNotice` failed on both expectations), then `goneNotice` falls back to `L10n.SourceTypes.goneNoticeUnnamed` when no label was seen. Orchestrator read the diff: **Resolved**.
Result update: open: none · to user: UX-4 (leave during Save, D-8), CON-1 (§ 10 manual check).
