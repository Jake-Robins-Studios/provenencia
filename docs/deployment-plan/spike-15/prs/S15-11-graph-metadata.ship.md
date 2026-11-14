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

## Result
Gate PASS · CI green · open: none · follow-ups: none · to user: — (MNT-out-2 answered: option a, fixed in F-8)

## Fix plan 2 (user, 2026-11-14: "Yes, fix it (a)" for MNT-out-2)

**F-8 — One page-wide "an owner form is open" fact, checked after every Add read** (from MNT-out-2, option a)
Files: `macos/App/Features/Sources/SourcePageContext.swift`, `SourcePageModel.swift`, `SourceGraphsSection.swift`, `SourceArtifactsSection.swift`, tests in `SourcePageModelTests.swift` (and `SourceGraphFormModelTests.swift` if the graph Add tests live there), plan Landed note.
Failing test first: `artifactPencilDuringGraphAddReadKeepsOneForm` — hold the graph Add's suggestion read open the way `anEditSheetOpenedDuringTheReadIsKept` (`SourcePageModelTests.swift` ~2335) holds the Artifact one; while it is held, `model.artifacts.openSheet(artifactID:)` opens the Artifact sheet; let the read finish → `graphs.openAdd()` answers nil, `model.graphs.form == nil`, `model.artifacts.sheet != nil`.
Do:
- `SourcePageContext` gets `var hasOpenOwnerForm: @MainActor () -> Bool = { false }` (doc: "True while any owner's form (Artifact sheet, graph form) is up; the page model supplies it"). `SourcePageModel.init` sets it once after the sections exist: `context.hasOpenOwnerForm = { [unowned self] in artifacts.sheet != nil || graphs.form != nil }` (use `weak` + `?? false` if `unowned` does not fit the file's style).
- `readSuggestionsForAdd(level:)` returns nil when `hasOpenOwnerForm()` is true before the read, and again after the await (a form opened while it ran is not replaced, whichever section opened it). Update its doc comment.
- Both sections' `openAdd()` drop their own post-await `guard form == nil` / `guard sheet == nil` and their pre-await own-form check (the helper now asks page-wide); keep `canAdd` in the graph one.
- `acceptsArtifactPageDrop` replaces `graphs.form == nil` and `artifacts.sheet == nil` with `!context.hasOpenOwnerForm()`.
- `anEditSheetOpenedDuringTheReadIsKept`, `secondAddWhileReadingOpensNothing`, `dropDuringGraphAddReadIsRefused`, `graphFormOpenRefusesDrop` keep passing unchanged.
- Plan Landed note: replace the "Artifact pencil left unguarded" wording with one line: the page model supplies `hasOpenOwnerForm`, and `readSuggestionsForAdd` checks it before and after the read, so an edit opened during any Add read is kept and the Add opens nothing. While there, fix MNT-12 (the Landed line naming `isOpeningAdd` → `SourcePageContext.isOpeningForm`).
Check: the new test fails first, then passes; `rg -n 'guard (form|sheet) == nil else \{ return nil \}' macos/App/Features/Sources` prints nothing; `rg -n 'graphs\.form == nil|artifacts\.sheet == nil' macos/App` prints only the `hasOpenOwnerForm` closure; scripts/check-pr.sh PASS.

## Fix plan 3 (user, 2026-11-14, from the manual check)
The user, looking at the Evidence graph form: the callout between the Artifact checklist and the Citation lists ("These artifacts stay linked: citations need them in this evidence graph.") is redundant with each locked row's reason ("N citations in this graph use this artifact"); remove it and put a small lock icon next to the reason text.

**F-9 — Drop the kept-linked callout; the locked row's reason carries a lock** (user)
Files: `macos/App/Features/Sources/SourceGraphFormDialog.swift`, `macos/App/DesignSystem/Components/Checkbox/PVCheckbox.swift`, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, plan Landed note. Skills: `add-ui-component`, `add-localized-string`.
Do:
- `SourceGraphForm.keptLinked`: delete the `PVCallout(tone: .neutral, icon: .lock, message: …graphFormKeptLinkedMessage…)`. Keep the `PVDeleteImpactGroupStack` of Citation lists, the `.disabled(model.isSaving)` and the `sources.graphForm.keptLinked` identifier; drop the wrapping `VStack` if only the stack is left in it.
- Delete `L10n.Sources.graphFormKeptLinkedMessage` and the `sources.graphForm.keptLinkedMessage` entry in `Localizable.xcstrings`.
- `PVCheckbox.body`: when `isLocked` and there is a description, draw the description as an `HStack(alignment: .firstTextBaseline, spacing: PVSpacing.space2)` (or the file's nearest small spacing token) of `PVIcon(.lock, size:)` sized to the micro caption (about 9pt; match how other components size an icon beside `PVTypeScale.micro` text if one does) in `PVColor.textMuted`, then the existing description text. The icon is decorative: `.accessibilityHidden(true)` (the box already speaks "Locked, <ref>"). Unlocked rows are unchanged. This is a design-system change: every locked checkbox gets it (the graph form's checklist and the Artifact sheet's graph links), which is the intent. Update the `PVCheckbox` doc comment's `isLocked` sentence to say the reason carries the lock too.
- If a Preview in `PVArtifactChecklist.swift` or `PVCheckbox.swift` shows a locked row, it needs no change beyond rendering.
- Plan Landed note: one bullet — the kept-linked callout was removed after the manual check (user, 2026-11-14); each locked row's reason carries a lock.
Check: `rg -n 'keptLinkedMessage' macos` prints nothing; `rg -n 'isLocked' macos/App/DesignSystem/Components/Checkbox/PVCheckbox.swift` shows the new branch; existing tests touching `keptLinked` still pass; scripts/check-pr.sh PASS (localizable included).

## Round 3 — fix (user request)
Head `7e14596ff`. Gate PASS (orchestrator run against `b9b4cba14`; `origin/main` unmoved). F-9 done: kept-linked `PVCallout` and its string removed (Citation lists kept); `PVCheckbox` draws a decorative 9pt muted lock before a locked box's reason, so the graph form checklist and the Artifact sheet's graph links both show it. Orchestrator read the diff. No review round (user-directed copy/visual change).

Gate PASS · CI green · open: none

## Fix plan 4 (user, 2026-11-14: board updated after the manual check)
Board: [Source Detail](https://claude.ai/artifact/443NPNYmGErAmxgV1fBsFK), `project/Source.dc.html`, frame `gf-kept` (`dGf`, "10 · Graph form, Kept linked") and the S15-D5 decision note. Read by the orchestrator at board version `1794681071-6f49`:
- No Kept linked list. A locked row whose graph Citations use the Artifact keeps its reason with the lock and gets an **"Open in citation composer"** link under it: kit link button, small, micro text, accent colour, no padding, indented to the label (`16 + space5`), its own element after the row (clicking never toggles the row). VoiceOver label "Open <artifact label> in citation composer".
- Clicking it closes the form without saving, after the standard discard confirm when the form changed, then opens this graph's citation composer with that Artifact selected.
- "The checklist scrolls in its own 352pt list (the board's one checklist cap, raised from 264pt; the Artifact sheet's graph list and Copy Source's Artifact list use it too)."
(The same decision note still mentions a one-column fallback below 960pt; that stays unbuilt, per the user on 2026-11-14.)

**F-10 — A locked row links to the citation composer; the Kept linked list goes** (user, board)
Files: `macos/App/Features/Sources/SourceGraphFormDialog.swift`, `SourceGraphFormModel.swift`, `macos/App/DesignSystem/Recipes/ArtifactChecklist/PVArtifactChecklist.swift` (and `PVChecklistRows.swift` if the row view lives there), `macos/App/Platform/L10n.swift`, `Localizable.xcstrings`, tests in `SourceGraphFormModelTests.swift`, plan Landed note. Skills: `add-ui-component`, `add-localized-string`, `add-swift-test`.
Failing test first: `composerLinkOpensTheArtifact` (model level) — a graph form on an edit with a cited, locked Artifact `a3`: `form.composerLocation(artifactID: "a3")` is `.citationComposer(sourceId: <source>, graphId: <graph>, artifactId: "a3", …)` (fill `ref`/`title`/`sourceTitle` the way other callers of `WorkspaceLocation.citationComposer` in `Features/Sources` or `Features/EvidenceGraph` do); and `form.composerLinkArtifactIDs == ["a3"]` (only locked Artifacts with Citations, the set `keptLinked` already computes; an Artifact locked for another reason gets no link).
Do:
- `SourceGraphFormModel`: replace `keptLinked` with `composerLinkArtifactIDs: Set<String>` (same predicate: a block for the Artifact with `citations.total > 0`) and add `composerLocation(artifactID:) -> WorkspaceLocation?` (nil on Add, where there is no graph). Update the three existing tests that read `keptLinked` to read `composerLinkArtifactIDs`.
- `PVArtifactChecklist`: one optional parameter for a per-row link under a locked row, e.g. `lockedLink: PVChecklistLockedLink? = nil` with `title: LocalizedStringResource`, `accessibilityLabel: (String) -> String` (artifact display title → spoken label), `shows: (String) -> Bool` (artifact id) and `action: (String) -> Void`. Render it after the locked row's checkbox, outside the checkbox's button: `PVButton(title, variant: .link, size: .sm)` at the micro size and accent tone the board shows, leading padding equal to the checkbox mark width + `PVSpacing.space5` so it lines up under the label. Rows without a link, and every existing caller (Copy Source, the Artifact sheet's graph links via `SourceArtifactGraphLinks`), are unchanged. If `PVButton` has no micro/zero-padding link style, add the smallest option to it rather than a local button.
- `SourceGraphForm`: delete the `keptLinked` view and its `if model.loadState == .ready, !model.keptLinked.isEmpty` block, and drop `onNavigate` from `SourceGraphForm` if nothing else uses it. Pass `lockedLink` with `shows: { model.composerLinkArtifactIDs.contains($0) }` and an action that reads `@Environment(\.pvSheetClose)` and calls `close(then: { navigation.go(to: location) })` with `model.composerLocation(artifactID:)`, so a dirty form asks "Discard changes?" first (this is `PVSheetClose`'s contract). Update the `SourceGraphForm` doc comment (no more "the Citations that keep some of them linked").
- Strings: `L10n.Sources.graphFormOpenInComposer` "Open in citation composer" and `graphFormOpenInComposerLabel(artifact:)` "Open %@ in citation composer", with comments.
- `PVDeleteImpactGroupList` / `PVDeleteImpactGroupStack`: the form was their only caller outside `PVDeleteImpact.swift`. Per `add-ui-component`, take them back to private views of `PVDeleteImpact.swift` if no other caller is left, and remove "for in-form refusal lists" from `macos/App/DesignSystem/README.md:208`.
- Plan Landed note: one bullet — the Kept linked list is replaced by a per-row "Open in citation composer" link (user, board, 2026-11-14).
Check: test passes after failing first; `rg -n 'keptLinked' macos/App` prints nothing; `rg -n 'PVDeleteImpactGroupList' macos/App` prints only `PVDeleteImpact.swift`; scripts/check-pr.sh PASS.

**F-11 — The checklist cap is 352pt** (user, board)
Files: `macos/App/DesignSystem/Recipes/ArtifactChecklist/PVChecklistRows.swift`.
Do: `maxRowsHeight` 264 → 352, and the doc comment's "264pt cap" → "352pt cap". This one cap serves the graph form, the Artifact sheet's graph links and Copy Source, which the board wants.
Check: `rg -n '264' macos/App/DesignSystem/Recipes/ArtifactChecklist` prints nothing; scripts/check-pr.sh PASS.

**F-12 — An unlink block carries a Citation count, not Citation rows** (user, 2026-11-14: "check for any unused code that we can clean up")
Sent to the round-4 implementer by message while it worked. Go `UnlinkBlock.Citations deleteimpact.Group` → `CitationCount int`; proto `EvidenceGraphUnlinkBlock` `citations = 2` → `int32 citation_count = 5` with `reserved 2; reserved "citations";`; Swift `CatalogEvidenceGraphUnlinkBlock.citationCount`; same hint wording through the existing resource; sweep for anything else that only served the list. Stop if any other caller reads the block's Citation rows.

## Round 4 — fix (user request, board)
Head `914f7b54d` (F-11 `4785a406a`, F-10 `e6e6b8844`, F-12 `914f7b54d`). Gate PASS; merged `origin/main` @ `3f1770056` (docs only), gate PASS again. Orchestrator read the diff.
- F-10: `PVChecklistLockedLink` on `PVArtifactChecklist`; the graph form passes it, and its action is `pvSheetClose` then `navigation.go(to:)` (discard confirm when dirty; ignored while saving). `composerLinkArtifactIDs`, `composerLocation(artifactID:)`; test `composerLinkOpensTheArtifact`. `PVDeleteImpactGroupList`/`Stack` private again; README line trimmed. Deviation: `PVControlSize.xs` (micro text) added for the link, `PVCheckboxMark.size` shared, `PVChip` handles `.xs`. Failing-test-first not run separately for F-10.
- F-11: `PVChecklistRows.maxRowsHeight` 352.
- F-12: done as sent. Removed `UnlinkVia`, `CitationsUsingArtifactTx`, `queryCitationRows`, `citationRowsExist`, a `TestMembership` block and unused handler-test fixture fields. Kept with a caller: `deleteimpact.ListedGroup` (unpromote impact), `GoStore.mapDeleteImpactGroup`, `PVDeleteImpactPreviewData.listed`, `PVDeleteImpactCopy.heading(_:)`. No other reader of the rows.
Nits (logged): `ORC-1 · core/database/evidencegraphs/evidencegraphs.go:65 · sqlCitationsUsing comment still says "The ref is selected for the order and dropped"` · `ORC-2 · Unlink's write-time check is now COUNT(*) where it was EXISTS; same index, negligible at Scale`
No review round (user-directed; no round 3 without the user).

Gate PASS · CI green · open: none

## Round 3 — review (user, 2026-11-14: "Yes, review round 4")
Scope `ea7e3184f...914f7b54d` (fix rounds 3's tail and 4: F-10, F-11, F-12). Reviewers: CON, MNT, UX (`macos/App/**`, strings), SEC+PRF (`api/ffi/**`, proto, `core/database/**` query). Skipped: none.

SEC+PRF: no findings (bound, indexed count; field 2 reserved; no new sink). UX: Clean (one minor). MNT, CON: Changes needed. Process note: the MNT reviewer briefly ran `git checkout 914f7b54d` and back; the orchestrator confirmed the branch clean at `9f4f611a2`.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | major | `docs/catalog-deletes.md:91` still says the unlink preflight returns a `DeleteImpactGroup` of Citations; `source-layer-data-model.md:466` omits the count | Fix now → F-13 | verified both lines; F-12 changed the reply |
| MNT-1 | MNT | major | `lockHint` gets its wording through a DeleteImpact via (`evidencegraphs.artifact_in_use`) that no group carries after F-12 | Fix now → F-14 | verified `SourceArtifactGraphLinks.swift:44`, `L10n.swift:8965`, `PVDeleteImpactTests.swift:208-209`; `UnlinkVia` removed in F-12 |
| UX-1, MNT-out | UX | minor | "Open in citation composer" link stays enabled while saving and does nothing | Fix now → F-15 | verified: no `.disabled(isDisabled)` on the link; the old Kept linked stack had `.disabled(model.isSaving)` |
| MNT-2 | MNT | minor | `PVControlSize.xs` is link-only but every sized control accepts it, undocumented | Fix now → F-16 | verified one caller (`PVArtifactChecklist.swift:162`); defect in code this PR adds |
| MNT-3 | MNT | minor | Link indent copies `PVCheckbox`'s mark-to-label spacing | Fix now → F-17 | verified `PVCheckbox.swift:99` vs `PVArtifactChecklist.swift:156` |

Nits (logged; MNT-4, MNT-5/CON-2/ORC-1, MNT-6, UX-2 ride along in F-16–F-18): `MNT-4 · DesignSystem/README.md:471 · ArtifactChecklist row omits PVChecklistLockedLink` · `MNT-5 · evidencegraphs.go:65-68 · stale "ref is selected" comment, unused c alias` · `CON-2 · evidencegraphs.go:64 · sqlCitationsUsing is now a count` · `MNT-6 · evidencegraphs_test.go:669 · _, _ = can be a bare call` · `UX-2 · L10n.swift:6501 · loading comment says "kept links"` · `CON-3 · S15-11 plan:37,119,143,209 · body still says 264pt / kept-linked list (Landed note covers; left as the plan's history)`

### Fix plan 5

**F-13 — The domain docs describe the count** (from CON-1)
Files: `docs/catalog-deletes.md`, `docs/source-layer-data-model.md`.
Do: `catalog-deletes.md:91` → "…returns one block per refused pair, with its graph, a reason code and, for `artifact_in_use`, how many of the graph's Citations are on the Artifact (`citation_count`; 0 for the graph's last link)." `source-layer-data-model.md:466`: in the `UnlinkImpact` clause, after "with its graph and reason", add "and, for a Citation reason, their count".
Check: `rg -n 'DeleteImpactGroup. of Citations' docs` prints nothing; scripts/check-pr.sh PASS.

**F-14 — The lock hint has its own count string** (from MNT-1)
Files: `macos/App/Features/Sources/SourceArtifactGraphLinks.swift`, `macos/App/Platform/L10n.swift`, `Localizable.xcstrings`, `macos/ProvenenciaTests/PVDeleteImpactTests.swift`, a Sources test file. Skill: `add-localized-string`.
Failing test first: `lockHintCountsCitations` (in the test file that already covers `lockHint`, or `SourcePageModelTests.swift`) — a block with `reason: .artifactInUse, citationCount: 1` → "1 citation in this graph uses this artifact"; 3 → "3 citations in this graph use this artifact". It passes today through the via table, so make it fail first by calling the new `L10n.Sources.graphLockCitations(count:)` that does not exist yet (compile failure counts).
Do: add `L10n.Sources.graphLockCitations(count: Int) -> String`, a plural resource with the same English wording, following the file's existing plural-count helpers (e.g. how `badgeMoreCount` or another `%lld` plural is built). Key: `sources.graphLock.citations` (new key in the catalog with the one/other variations copied from `deleteImpact.via.evidenceGraphsArtifactInUse`). `lockHint` calls it when `citationCount > 0`. Remove the `"evidencegraphs.artifact_in_use"` entry from `viaFormats`, its catalog key `deleteImpact.via.evidenceGraphsArtifactInUse`, and its two rows in `PVDeleteImpactTests`. Check nothing else reads that via (`rg -n 'evidencegraphs.artifact_in_use|evidenceGraphsArtifactInUse' macos` — the apperr error-code mapping for the refusal message stays).
Check: the new test passes; `rg -n 'evidenceGraphsArtifactInUse' macos` prints nothing; `rg -n 'heading\(via:' macos/App/Features` prints nothing; scripts/check-pr.sh PASS (localizable included).

**F-15 — The composer link dims while the form saves** (from UX-1)
Files: `macos/App/DesignSystem/Recipes/ArtifactChecklist/PVArtifactChecklist.swift`.
Do: add `.disabled(isDisabled)` on the locked-row link, as its neighbours are.
Check: scripts/check-pr.sh PASS.

**F-16 — `.xs` is documented as the link-only size** (from MNT-2, MNT-4)
Files: `macos/App/DesignSystem/Components/Button/PVButton.swift`, `macos/App/DesignSystem/README.md`.
Do: the `PVControlSize` doc and the `.xs` case doc say `.xs` is for the `link` variant only (micro text under a row); other controls treat it as `.sm` metrics. Add an `.xs` link to `PVButton`'s `#Preview`. README: in the control-size notes, the `.xs` rule; in the ArtifactChecklist row (line ~471), add `PVChecklistLockedLink` / `lockedLink`.
Check: `rg -n '\.xs' macos/App/DesignSystem/README.md` shows the rule; scripts/check-pr.sh PASS.

**F-17 — The checkbox publishes where its label starts** (from MNT-3)
Files: `macos/App/DesignSystem/Components/Checkbox/PVCheckbox.swift`, `PVArtifactChecklist.swift`.
Do: add `static let labelLeading: CGFloat = PVCheckboxMark.size + PVSpacing.space5` on `PVCheckbox` (doc: "Where the label starts, from the box's leading edge"); the body's mark–label `HStack` uses `PVSpacing.space5` as before (the constant states the sum, it does not replace the spacing). The link's indent becomes `Self.thumbnailSize + PVSpacing.space5 + PVCheckbox.labelLeading`; fix the comment ("Thumbnail + gap + the checkbox's label start"). If `PVCheckboxMark.size` was made non-private only for this, make it private again.
Check: `rg -n 'PVCheckboxMark.size' macos/App/DesignSystem/Recipes` prints nothing; scripts/check-pr.sh PASS.

**F-18 — Nits riding along** (MNT-5, CON-2, MNT-6, UX-2)
Files: `core/database/evidencegraphs/evidencegraphs.go`, `evidencegraphs_test.go`, `macos/App/Platform/L10n.swift`.
Do: rename `sqlCitationsUsing` → `sqlCitationCount`, comment "How many of a graph's Citations are on an Artifact, with or without Observations.", drop the `c` alias. `evidencegraphs_test.go:669`: bare call. `L10n.swift:6501` loading comment → "while the locked Artifacts are read".
Check: `rg -n 'sqlCitationsUsing' core` prints nothing; scripts/check-pr.sh PASS.

## Round 5 — fix
Head `435acceb2` (F-14 `8b13f6549`, F-13 `f86fbe018`, F-15+F-17 `977cac5ad`, F-16 `d0445f544`, F-18 `435acceb2`). Gate PASS (orchestrator run). All six done. Deviations: `PVCheckboxMark.size` is `fileprivate` (the constant's struct shares the file); `evidenceGraphsArtifactInUse` remains only as the apperr refusal message, as planned; F-14's test failed by compile error, not a separate run. CON-1 and MNT-1 **Resolved** (orchestrator read `catalog-deletes.md:91`, `lockHint`, and the removed via entry); UX-1, MNT-2, MNT-3 **Resolved**. No further review round: the user's next request follows.

## Fix plan 6 (user, 2026-11-14: Artifact sheet in the graph form's two-column format)
User: "I would like to swap the artifact one to use the same format… Can you add that scope to this PR and implement it as well? I hope we can unify some code." Then: "Just use the existing look exactly, and I'll update the board independently." No board frame; the graph form at head is the spec.

**F-19 — The Artifact sheet is the graph form's two-column form; both share one layout**
Files: `macos/App/Features/Sources/ArtifactSheet.swift`, `SourceGraphFormDialog.swift`, a new `macos/App/Features/Sources/SourceOwnerFormColumns.swift` (add it to the Xcode project the way the repo adds Swift files), plan Landed note and Scope, `completed.md` paragraph if it describes the Artifact sheet's width. Skills: `add-ui-component` (feature-private recipe with two callers).
Do:
- New `SourceOwnerFormColumns<Left: View, Right: View>`: the body both forms share. `static let dialogWidth: CGFloat = 880`. Init takes `saveError: String?`, `saveErrorTitle: LocalizedStringResource`, `saveErrorIdentifier: String`, `isSaving: Bool`, `@ViewBuilder left`, `@ViewBuilder right`. Body is exactly what `SourceGraphForm.body` draws today: `VStack(spacing: space6)` with the danger `PVCallout(announces: true)` when `saveError` is set, then `HStack(alignment: .top, spacing: space8)` of the left `VStack(spacing: space6)` (`.disabled(isSaving)`, `.frame(maxWidth: .infinity, alignment: .topLeading)`) and the right `VStack(spacing: space6)` (`.frame(maxWidth: .infinity, alignment: .topLeading)`). Doc comment: owner forms (Artifact sheet, Evidence graph form), two equal columns at every width, no fallback (user, 2026-11-14).
- New `DraftMetadataBoardField` in the same file: `PVField(label:)` around `MetadataBoardView(board:, placement: .form, accessibilityIdentifierPrefix:, onClear: { id in Task { _ = await board.requestClear(fieldID: id) } })` with the "A draft board clears with no confirm." comment. Both `SourceGraphForm.metadata` and `ArtifactSheetForm.copyDetails` use it (each keeps its own `.id(...)` and label).
- `SourceGraphForm.body` uses `SourceOwnerFormColumns` (left: fields, metadata; right: the load area and checklist) and the dialog uses `SourceOwnerFormColumns.dialogWidth`. No visible change.
- `ArtifactSheet`: `width: SourceOwnerFormColumns.dialogWidth`. Body: `SourceOwnerFormColumns(saveError: model.saveError, saveErrorTitle: L10n.Sources.artifactCardSaveErrorTitle, saveErrorIdentifier: "\(prefix).saveError", isSaving: model.isSaving)`. Left: the file field (Add only), the label/description fields, then Copy details (`DraftMetadataBoardField`). Right: `graphLinks`. Drop the per-section `.disabled(model.isSaving)` the left column now covers (graph links keep their own `isDisabled`). Keep the scroll ids: `.top` on the left column's first block (file or fields), `.graphs` on `graphLinks`, `.copyDetails` on the copy details field; `opensAt`/`scrollTarget` behave as before. The right column is drawn even when `graphLinks` shows nothing (two columns always). Keep each form's own labels, hints, markers and line limits.
- Update both forms' doc comments (the Artifact sheet's body: two columns; left file/label/description/copy details, right its Evidence graphs).
- Same-pass: if any other code path still reads the old 560 width for the Artifact sheet, or a doc names the Artifact sheet as 560pt (`rg -n '560' macos/App/Features/Sources docs/*.md .agents`), update it; report what you found.
- Plan: add the Artifact sheet layout to the Landed note as user-added scope (2026-11-14), and a Manual check line: open Add artifact and Edit on an Artifact; two columns at 880pt; Copy details "+n more" scrolls to Copy details; the pencil on the graph count scrolls to Evidence graphs.
Check: `rg -n 'width: 560' macos/App/Features/Sources` prints nothing; `rg -n 'MetadataBoardView\(' macos/App/Features/Sources` prints only `SourceOwnerFormColumns.swift` and `SourcePage*` (the Source's own live board); `rg -n 'HStack\(alignment: .top, spacing: PVSpacing.space8\)' macos/App/Features/Sources` prints only the new file; existing `ArtifactSheetModelTests`/`SourceGraphFormModelTests` pass; scripts/check-pr.sh PASS.

## Round 6 — fix
Head `69ef1cf34`. Gate PASS (implementer). F-19 done: `SourceOwnerFormColumns` and `DraftMetadataBoardField` in `SourceOwnerFormColumns.swift`; both forms use them; Artifact sheet 880pt two columns. No project edit needed (synchronized folder). Orchestrator read the diff and found two defects in it:

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| ORC-3 | UX | major | Artifact sheet's `.top` scroll id now marks only the file/fields block, below the save-error callout; `scrollToTop()` on a save stop can leave the callout above the visible area | Fix now → F-20 | `ArtifactSheet.swift`: `.id(Section.top)` on the inner left `VStack`; `ArtifactSheetModel.scrollToTop()` at lines 282–333; before F-19 the callout sat inside the `.top` block; the graph form marks the whole body |
| ORC-4 | MNT | minor | `dialogWidth` on a generic type forces `SourceOwnerFormColumns<EmptyView, EmptyView>.dialogWidth` at both callers | Fix now → F-20 | both modifiers |

### Fix plan 7
**F-20 — The Artifact sheet's top target includes its save error; the width lives on a plain type** (from ORC-3, ORC-4)
Files: `ArtifactSheet.swift`, `SourceGraphFormDialog.swift`, `SourceOwnerFormColumns.swift`.
Do: move `.id(ArtifactSheetModel.Section.top)` from the left column's inner `VStack` to the `SourceOwnerFormColumns(...)` view itself, as `SourceGraphForm` does (the inner `VStack` can go if it only existed for the id). Move the width to a non-generic home in the same file, `enum SourceOwnerForm { static let dialogWidth: CGFloat = 880 }` (doc: the width of the dialog holding owner-form columns), delete `SourceOwnerFormColumns.dialogWidth`, and both modifiers use `SourceOwnerForm.dialogWidth`.
Check: `rg -n 'EmptyView, EmptyView' macos/App` prints nothing; `rg -n 'Section.top' macos/App/Features/Sources/ArtifactSheet.swift` shows it on the columns view; scripts/check-pr.sh PASS.
