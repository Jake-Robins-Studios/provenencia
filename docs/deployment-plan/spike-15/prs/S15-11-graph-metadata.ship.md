# Ship log — S15-11 Evidence graphs show their metadata

**Plan:** [`S15-11-graph-metadata.md`](S15-11-graph-metadata.md) · **Branch:** `s15-11-graph-metadata` · **PR:** #834
**State:** ready

## Round 0 — implement
Head `6e37e9e1a`. Gate PASS (orchestrator run against `91fe2d7f7`). Implementer's own run 1 failed twice: a `promotealign` budget timing flake (passed on rerun, package untouched) and `CatalogQueryRegistryTests.metadataBoardPatchIgnoresOwnersItCannotPlace` (fixed in `babc12b43`). Report deviations (all in the plan's Landed note):
1. `metadataBoardPatchIgnoresOwnersItCannotPlace` reworked (graph owners are now placeable per D-3); `metadataBoardPatchStoresAGraphsRows` added.
2. New `SourcePageModel.metadataRows(for:)` pass-through for the Artifact row.
3. New `FakeStore.createEvidenceGraphRows`.
4. Name-required stop also bumps `scrollRequest`.
5. Version bump shares the Swift commit `946ce6a12`.
6. PR body deviations point to the Landed note.
Left for the orchestrator: `docs/ideas/wide-layout.md:20` still describes the dropped 560pt narrow fallback.
Manual check (§10) and board visual match not run by the implementer.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. Skipped: none (UX: `macos/App/**`, `Localizable.xcstrings`; SEC: `api/ffi/**`; PRF: `macos/App/Features/**` models).

SEC+PRF: no findings, no nits. CON: verdict Clean (two minors). MNT, UX: Changes needed.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| UX-1, MNT-4 | UX, MNT | major | Graph form ignores `opensAt`; Name takes focus when "+n more" opens at metadata | Fix now → F-1 | verified: `SourceGraphFormDialog.swift` passes `activateOnAppear: true`; `ArtifactSheet.swift:117` uses `model.opensAt == .top` |
| UX-2, CON-1 | UX, CON | major | Stale open-field callout survives a later name-required stop | Fix now → F-2 | verified: `SourceGraphFormModel.save()` clears `saveError` only after the name and `canSave` guards; `ArtifactSheetModel.save()` clears first. CON-1 carries the failing test |
| MNT-1 | MNT | major | Two pass-through readers for row metadata (`SourcePageModel.metadataRows(for:)` and `SourceGraphsSection.details(for:)`) | Fix now → F-3 | verified both one-liners; same-pass cleanup per D-6 "One reader"; supersedes D-12's `model.graphs.details(for:)` wording (note in Landed) |
| MNT-2 | MNT | major | Width wrapper, env read and frame copied into both rows | Fix now → F-4 | verified: `rg 'wrapper keeps the column'` → 2 hits; same-pass cleanup (this PR adds the second copy); supersedes D-12's row-side wrapper wording |
| MNT-3 | MNT | major | `FakeStore.createEvidenceGraphRows` is a second way to script reply rows | Fix now → F-5 | verified: `createArtifact` uses `nextArtifactID`; `appendGraph` has no id hook; same-pass cleanup |
| MNT-5 | MNT | minor | Read-first `openAdd` copied in two sections | Fix now → F-6 | same-pass cleanup: this PR adds the second copy (reviewer's Fit "follow-up" overridden by the rule) |
| MNT-out-1 | CON | minor | `acceptsArtifactPageDrop` ignores `graphs.isOpeningAdd` and `graphs.form`; a drop during a graph Add read starts an Artifact sheet | Fix now → F-6 | verified `SourcePageModel.swift:100-107`; the `isOpeningAdd` window is new in this PR |
| MNT-out-2 | CON | minor | Graph and Artifact open paths do not exclude each other's in-flight Add read | Fix now → F-6 | verified `SourceGraphsSection.swift:79,103` check only their own flag; folded into the shared helper's page-wide flag |
| CON-2 | CON | minor | Brief move broke `docs/ideas/wide-layout.md:20` link; line still describes the dropped 560pt fallback | Fix now → F-7 | verified: only non-archive hit of `S15-D5-evidence-graph-form`; also the implementer's flagged leftover |
| CON-out-1 | PRF/SEC | — | Graph ids from in-memory index vs DB read could disagree → `ErrInvalid` | Rejected | the graph cache updates on commit (`Graph().OnCommit`) and the catalog is held exclusively by `core/catalogsession`, so ops serialize; same shape as the Artifact read already shipped; SEC+PRF reviewer checked the same path and found it holds |

Nits (logged): `MNT-6 · SourcePageArtifactRow.swift:53-54 · bind MetadataOwner once` (moot after F-3/F-4 if the row is rewritten) · `MNT-7 · SourceGraphFormModel.swift:15-17 · doc comment wraps wide` · `UX-3 · SourcePageGraphsView.swift · values ids use graph id, buttons use ref (D-7)` · `UX-4 · MetadataDetailsColumn.swift · "+n more" label says ref not name (D-7)` · `CON-3 · SourceGraphFormModelTests dirtyFormAsksOnOutsideClick · Cancel half sets form = nil by hand`

### Fix plan 1

**F-1 — Graph form focuses Name only when it opens at the top** (from UX-1, MNT-4)
Files: `macos/App/Features/Sources/SourceGraphFormDialog.swift`, `macos/ProvenenciaTests/SourceGraphFormModelTests.swift`.
Do: on the Name `PVInput`, pass `activateOnAppear: model.opensAt == .top`, exactly as `ArtifactSheet.swift:117` does. No model test can see focus; keep `moreOpensAtMetadata` asserting `opensAt == .metadata`.
Check: builds; scripts/check-pr.sh PASS. Manual check covers the focus.

**F-2 — `save()` clears its old errors before any stop** (from UX-2, CON-1)
Files: `macos/App/Features/Sources/SourceGraphFormModel.swift`, `macos/ProvenenciaTests/SourceGraphFormModelTests.swift`.
Failing test first: `nameStopClearsAnOldOpenFieldMessage` — CON-1's test (save with an open Add field row → false; clear the row; set name to " "; save → false; expect `nameError != nil`, `saveError == nil`).
Do: move `saveError = nil` (and `nameError = nil` if the model has it) to right after `guard !isSaving`, as `ArtifactSheetModel.save()` lines 278–279 do.
Check: the test passes; scripts/check-pr.sh PASS.

**F-3 — One reader for a row's metadata** (from MNT-1)
Files: `SourceGraphsSection.swift`, `SourcePageGraphsView.swift`, `SourcePageModelTests.swift`, `SourceGraphFormModelTests.swift`, plan Landed note.
Do: delete `SourceGraphsSection.details(for:)`. The graph row reads `model.metadataRows(for: MetadataOwner(level: .graph, id: graph.id))`. Move its test callers (`SourcePageModelTests.swift` ~2487-2491; `SourceGraphFormModelTests.swift` ~413, 450, 470) to `model.metadataRows(for:)`. In the plan's Landed note, replace deviation 2's wording: both rows read `SourcePageModel.metadataRows(for:)`; this supersedes D-12's `model.graphs.details(for:)` (same-pass cleanup, MNT-1).
Check: `rg -n 'graphs\.details\(for|func details\(for' macos` prints nothing; scripts/check-pr.sh PASS.

**F-4 — `MetadataDetailsColumn` owns its wrapper and width** (from MNT-2)
Files: `MetadataDetailsColumn.swift`, `SourcePageGraphsView.swift`, `SourcePageArtifactRow.swift`, plan Landed note.
Do: `MetadataDetailsColumn` reads `@Environment(\.pvWidthClass)` and its body always returns `VStack(alignment: .leading, spacing: 0) { if !shown.isEmpty { …grid… } }.frame(minWidth: 0, maxWidth: Self.width(widthClass), alignment: .topLeading)` with the single "wrapper keeps the column" comment. Keep `static func width(_:)` (tested by `artifactRowActionsAndWidths`). Both rows place `MetadataDetailsColumn(...)` bare; drop their wrapper, frame, comment and `pvWidthClass` env read if nothing else in that view reads it. While in the Artifact row, bind the owner once (MNT-6). Landed note: D-12's row-side wrapper now lives in the column (MNT-2).
Check: `rg -n 'wrapper keeps the column' macos/App` prints exactly one line, in `MetadataDetailsColumn.swift`; `rg -n 'MetadataDetailsColumn.width' macos/App` prints only lines inside `MetadataDetailsColumn.swift`; scripts/check-pr.sh PASS.

**F-5 — The fake scripts a new graph's rows the way it scripts an Artifact's** (from MNT-3)
Files: `macos/App/Platform/FakeStore.swift`, `macos/ProvenenciaTests/SourceGraphFormModelTests.swift`, plan Landed note.
Do: add `var nextEvidenceGraphID: String?` with a doc mirroring `nextArtifactID`'s; `appendGraph` (or `createEvidenceGraph`) uses `nextEvidenceGraphID ?? UUID()…` and clears it, as `createArtifact` does at ~line 833. Delete `createEvidenceGraphRows` and its branch. In `createSendsTheDraft`, set `store.nextEvidenceGraphID` and script `store.metadataWriteResults[MetadataOwner(level: .graph, id:)]`. Rewrite Landed deviation 3 accordingly.
Check: `rg -n createEvidenceGraphRows macos` prints nothing; `createSendsTheDraft` passes; scripts/check-pr.sh PASS.

**F-6 — One read-first open for owner forms, with a page-wide opening flag** (from MNT-5, MNT-out-1, MNT-out-2)
Files: `SourcePageContext.swift`, `SourceGraphsSection.swift`, `SourceArtifactsSection.swift`, `SourcePageModel.swift`, tests in `SourcePageModelTests.swift` / `SourceGraphFormModelTests.swift`.
Failing test first: `dropDuringGraphAddReadIsRefused` — hold the graph suggestion read open (use the fake's existing suspension/gate for `unsavedMetadataRows` if one exists; otherwise assert after opening the graph form) and expect `model.acceptsArtifactPageDrop == false`; and `graphFormOpenRefusesDrop` — with `model.graphs.form != nil`, `acceptsArtifactPageDrop == false`.
Do: move the shared sequence into `SourcePageContext`: a `private(set) var isOpeningForm` flag and one `func readSuggestionsForAdd(level:) async -> [suggestions]?` that returns nil when already opening, sets/defers the flag, runs `unsavedMetadataRows(level:)`, and on error calls `showFailure(error)` and returns nil. Both sections' `openAdd()` call it (each keeps its own "no form of mine is open" guards before and after the await). Replace each section's `isOpeningAdd` with a read of `context.isOpeningForm` (keep the name `isOpeningAdd` as a computed pass-through only if tests or views need it; otherwise update callers). `SourceGraphsSection.openEdit` and `SourceArtifactsSection`'s edit/drop entry points check `context.isOpeningForm`. `acceptsArtifactPageDrop` adds `graphs.form == nil` and uses `context.isOpeningForm`. Existing tests `secondAddWhileReadingOpensNothing` and the Artifact equivalents must keep passing.
Check: `rg -n 'isOpeningAdd = ' macos/App` prints nothing outside `SourcePageContext.swift` (flag now named `isOpeningForm`); `rg -n 'unsavedMetadataRows\(level' macos/App/Features/Sources` prints only the helper; new tests pass; scripts/check-pr.sh PASS.

**F-7 — Fix the wide-layout idea's link and stale fallback** (from CON-2)
Files: `docs/ideas/wide-layout.md`.
Do: line 20 — link to `../deployment-plan/spike-15/design/archive/S15-D5-evidence-graph-form.md`; replace "(880pt; one 560pt column below a 960pt pane)" with "(880pt at every width)".
Check: `rg -n 'S15-D5-evidence-graph-form' --glob '!**/archive/**' .` shows only the archive-path link; scripts/check-pr.sh PASS.

## Round 1 — fix
Head `7d24150dd` (commits `2c89d1232` F-1, `2e003da5a` F-7, `7d24150dd` F-2–F-6). Gate PASS (orchestrator run). F-1 to F-7 done; F-2 failing test ran red first. Deviations: F-6 left the Artifact pencil (`SourceArtifactsSection.openSheet`) unguarded because the existing `anEditSheetOpenedDuringTheReadIsKept` opens an edit sheet during an Add read; F-2–F-6 share one commit.

Minor resolutions read by the orchestrator (no round-2 reviewer):
- CON-2 (F-7): **Resolved** — `docs/ideas/wide-layout.md:20` links the archive path and says "880pt at every width".
- MNT-out-1 (F-6): **Resolved** — `acceptsArtifactPageDrop` checks `context.isOpeningForm` and `graphs.form == nil`; tests `dropDuringGraphAddReadIsRefused`, `graphFormOpenRefusesDrop`.
- MNT-out-2 (F-6): **Partly resolved** — graph `openEdit` and Artifact drop check the page-wide flag; the Artifact pencil does not (see deviation). Left to the round-2 MNT reviewer, which reads the same code.

## Round 2 — review
Reviewers: MNT, UX (each had a Fix-now major). Not re-sent: CON (minors only, read above), SEC+PRF (no findings). Scope `6e37e9e1a...7d24150dd`.

UX: **Clean.** UX-1 Resolved (`SourceGraphFormDialog.swift:130`), UX-2 Resolved (`SourceGraphFormModel.swift:165-166`, test `nameStopClearsAnOldOpenFieldMessage`). No new blocker.

MNT: **Clean (no blocker or major).** MNT-1 to MNT-5 Resolved. MNT-out-2 **Not resolved** for one path:

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-out-2 | CON | minor | The Artifact pencil (or its "+n more") during a graph Add read leaves an Artifact sheet and the graph form both bound; `SourceGraphsSection.openAdd`'s post-await re-check asks only about its own form | To user → user chose (a) → F-8 | round 2 adds blockers only, so no Fix plan 2; the window is a local suggestion read. Fix options: (a) a page-wide "owner form open" fact read by both post-await re-checks and `acceptsArtifactPageDrop` (keeps S15-10's tested edit-during-read behavior); (b) guard `openSheet` on `isOpeningForm`, reversing `anEditSheetOpenedDuringTheReadIsKept` |

Nits (logged): `MNT-8 · MetadataDetailsColumn.swift:46-77 · content(shown:more:) over-indented` · `MNT-9 · FakeStore.swift:3385 · nextEvidenceGraphID consumed in appendGraph, which insertSource also calls` · `MNT-10 · SourcePageGraphsView.swift:68-69 · double blank line` · `MNT-11 · SourcePageGraphsView.swift:104-105 · graph MetadataOwner built twice` · `MNT-12 · S15-11 plan:348 · Landed line still names isOpeningAdd`

## Finish
Merged `origin/main` @ `b9b4cba14` (S16-21 plan docs only). Gate PASS against `b9b4cba14`.

## Round 2 — fix (user-approved)
Head `b4148fecb`. Gate PASS (orchestrator run against `b9b4cba14`; `origin/main` unmoved). F-8 done: `artifactPencilDuringGraphAddReadKeepsOneForm` failed first (graph form opened beside the Artifact sheet), passes now. Orchestrator read the diff: `SourcePageContext.hasOpenOwnerForm` (supplied by `SourcePageModel.init`) is checked by `readSuggestionsForAdd` before and after the read; both `openAdd`s dropped their own form checks; `acceptsArtifactPageDrop` reads it. MNT-out-2 **Resolved**. MNT-12 nit fixed in the Landed note. No review round 3 (user approved the fix only).

## Fix plan 8 (user, 2026-11-14, manual check with screenshot)
User: "The big container is vertically larger than the space that the 5 rows take up… The height of the container should be the height of its content, up to the maximum." Cause, read by the orchestrator: `PVChecklistFrame` (`PVChecklistRows.swift`) wraps its rows in a `ScrollView` with `.frame(maxHeight: 352)`; a `ScrollView` takes all the height offered, so every checklist (graph form Artifacts, Artifact sheet graphs, Copy Source) is 352pt tall whatever its row count. `PVFormDialog.formBody` (`PVFormDialog.swift:187-193`) already sizes its scroll view to its measured content with a cap.

**F-21 — A checklist's box is as tall as its rows, up to 352pt** (user)
Files: `macos/App/DesignSystem/Recipes/ArtifactChecklist/PVChecklistRows.swift`, `macos/App/DesignSystem/Components/FormDialog/PVFormDialog.swift`, one new small file under `macos/App/DesignSystem/` for the shared modifier (place it beside the closest existing scroll helper, e.g. where `pvScrollsRowIntoView` lives), README line for it, a test file. Skills: `add-ui-component`, `add-swift-test`.
Failing test first: `checklistHeightFitsItsRows` — a pure function the frame uses, `PVFittedScrollHeight.height(content: CGFloat, cap: CGFloat) -> CGFloat` (or the helper's own name): content 180 / cap 352 → 180; 500 / 352 → 352; 0 / 352 → 0.
Do:
- Extract the dialog body's sizing into one modifier, e.g. `View.pvScrollFittingContent(maxHeight:)` applied to a `ScrollView` whose content reports its height: it measures the content with `.onGeometryChange(for: CGFloat.self) { $0.size.height }` and sets `.frame(height: min(measured, maxHeight))`. Because the measurement sits on the content inside the ScrollView, shape the API so the caller hands it the content (e.g. a `PVFittedScrollView(maxHeight:) { content }` view that returns the ScrollView, plus a binding or callback for callers that need the measured height). `PVFormDialog.formBody` keeps its `bodyHeight` (its first-scroll gate reads it), so it may need the variant that reports the height out; keep its behaviour identical.
- `PVChecklistFrame`: its rows use the shared piece with `maxHeight: Self.maxRowsHeight`. The rows' `LazyVStack` becomes a `VStack` if a lazy stack does not report its full height (a checklist is at most a Source's Artifacts or graphs; at Scale 60 rows, cheap). Add `.scrollBounceBehavior(.basedOnSize)` so a list that fits does not bounce.
- Same-pass: search for other `ScrollView` + measured-height + `min(` caps by body (`rg -n 'onGeometryChange\(for: CGFloat.self\) \{ \$0.size.height \}' macos/App`) and move each that matches the shape onto the shared piece; report each hit and whether it moved.
- No visible change to the dialog body. Every checklist is now as tall as its rows up to 352pt.
Check: the test passes; `rg -n 'frame\(maxHeight: Self.maxRowsHeight\)' macos/App` prints nothing; scripts/check-pr.sh PASS. Manual: the Artifact sheet with five graphs shows a box that ends under the fifth row.

## Round 8 — fix
Head `4bd647b52`. Gate PASS (orchestrator run; `origin/main` unmoved). F-21 done: new `DesignSystem/Components/FittedScroll/PVFittedScroll.swift` (`PVFittedScrollHeight.height(content:cap:)`, `PVFittedScrollView(maxHeight:onContentHeight:content:)`); `PVChecklistFrame` and `PVFormDialog.formBody` both use it; rows `VStack`; test `FittedScrollHeightTests.checklistHeightFitsItsRows`; README row. Same-pass search: three other height measurements (pinned column offset, timeline item heights, record-links header) are not capped scroll views; none moved. Orchestrator read the diff. Note: the dialog body now also has `.scrollBounceBehavior(.basedOnSize)` (a body that fits no longer bounces). Nit (logged): `ORC-5 · PVChecklistRows.swift:3-4 · re-wrapped doc comment runs past its neighbours' width`. Manual check of the five-graph box not run.

## Result
Gate PASS · CI pending · open: none · follow-ups: none · to user: —
