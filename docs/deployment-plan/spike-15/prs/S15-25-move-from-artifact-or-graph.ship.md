# Ship log — S15-25 Move from an Artifact or a graph

**Plan:** [`S15-25-move-from-artifact-or-graph.md`](S15-25-move-from-artifact-or-graph.md) · **Branch:** `s15-25-move-from-artifact-or-graph` · **PR:** #940
**State:** ready

## Round 0 — implement
Base `main` @ `4ca4a236a`.
Head `8c41d6a29`. Gate PASS (orchestrator run). Draft PR #940. Report deviations:
- No `.help` on the Move buttons: `PVIconButton` already makes its label the tooltip.
- Added `CoreMethod.getSourceMoveImpact` / `.moveToSource` to `CoreInvoke.swift` (only the generated enum had them).
- AC-5.4: a new Artifact saved with a file reported `source_holdings` twice (create, then ingest); `ArtifactSheetModel.saveCreate` now holds the create's effects and applies them merged with the ingest's (`CatalogWriteEffects.merged(with:)`, test `mergedWriteEffectsUnion`). Own commit `cfc251f94`.
- `listSources(projectDir:sourceIDs:)` added as a second protocol requirement; onboarding `ThrowingStore` updated.
- `SourceMoveModel`: a pick's read clears a stale failure when a bundle is held; `canMove` also needs `readState == .ready`; `.sourcesByUpdated` read via a `WorkspaceSession` accessor.
- Existing tests changed: three Artifact delete tests in `SourcePageModelTests`; pinned identity strings in `PlaceRegistryTests`, `EvidenceGraphModelTests`.
- STEP-6's `rg verbatimTitle` still matches `PVFormDialogCopy(verbatimTitle:)` in `DesignSystem/README.md` — a different form the plan did not remove.
- Version 0.32.1 → 0.33.0. Manual check (§ 10) not run.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. UX on `macos/App/**` and `Localizable.xcstrings`; SEC+PRF on `api/ffi/**`, `core/database/**`, `macos/App/Features/**` models, and the preflight reading stored credibility grades.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | blocker | A second history entry for a moved graph keeps the old Source; never corrected | Fix now → F-1 | verified: `WorkspaceDestinationHost.swift:23` observes `graphSourceID` (the graph row's Source), which stays S2 between two stale G1 entries (canvas → composer → canvas), so `onChange` does not fire. D-17's outcome (AC-6.1/6.2) stands; only the observed value changes, noted in the Landed note |
| MNT-4 | MNT | minor | Which places follow their graph's Source is a hand switch in the host, not a `PlaceRegistry` fact | Fix now → F-1 | Same place as CON-1; code this PR adds |
| UX-1 | UX | major | Credibility note reads "is assessed not assessed" when the origin is unassessed | Fix now → F-2 | verified: `sources.move.credibility.message` hard-codes "is assessed %2$@"; `sourcemove.go` gives "" for an unassessed origin with `CredibilityDiffers` true |
| UX-2 | UX | major | Target field hidden with no message or retry while the Sources list is loading or failed | Fix now → F-3 (user) | Contradicts D-10 ("no field and no Callout"); user, 2026-11-22: "Fix in this PR" — show the list's load state, failure Callout with Read again |
| MNT-1 | MNT | major | `CatalogWriteEffects.merged(with:)` reassigns fields by hand; a new field silently drops; pattern undocumented | Fix now → F-4 | verified: `CatalogMutation.swift:156` starts `var out = self`; test covers 5 of 10 fields |
| MNT-2 | MNT | major | `docs/ideas/source-page-followups.md` still names the deleted `refreshCoverFromStore` as open debt | Fix now → F-5 | verified: section at lines 17-19; `rg refreshCoverFromStore macos` is empty |
| MNT-3 | MNT | minor | `listSources` two protocol requirements with near-identical bodies in each conformer | Fix now → F-6 | Code this PR adds |
| PRF-1 | PRF | minor | Move dialog rebuilds ~3,000 ComboBox options on every redraw | Fix now → F-7 | Code this PR adds; neighbor `SourceTypeFormatsSection.swift:99` (untouched) → Follow-up |
| UX-3 | UX | minor | Read again after a failed pick read shows no progress | Fix now → F-8 | `readAgain` keeps `.failed` while `impact != nil` |
| UX-4 | UX | minor | Long bundle title truncated with no tooltip | Fix now → F-8 | File this PR adds |
| CON-2 | CON | minor | T-8 passes with the stale-reply drop removed | Fix now → F-9 | Releases S2 before S3 |
| CON-3 | CON | minor | T-11 cannot tell `apply(_:leavingPage:)` from `apply` + leave | Fix now → F-9 | No page shown before the move |

Follow-ups: PRF-1 neighbor — `SourceTypeFormatsSection.swift:99` builds its ComboBox options in `body` (code this PR does not touch).

Nits (logged): `UX-5 · SourceMoveModel.swift:74 · clear moveError on pick` · `UX-6 · SourcePageArtifactRow.swift:163 · Move lacks .disabled(model.source == nil)` · `MNT-5 · GoStore.swift:947,979 · seed→request switch twice` · `MNT-6 · CatalogQueryRegistry.swift:158 · say ListSources-by-id is called per id` · `MNT-7 · sourcemove.go:163-175 · comment why labels are not in Record` · `CON-4 · S15-25 plan:53 · "What stays" contradicts D-15/D-16 reload on file_id`

### Fix plan 1

**F-1 — Correct every stale graph entry, and let the registry say which places follow their graph** (from CON-1, MNT-4)
Files: `macos/App/Features/Workspace/WorkspaceDestinationHost.swift`, `macos/App/Features/Workspace/Session/PlaceRegistry.swift`, `macos/ProvenenciaTests/WorkspaceNavigationTests.swift`. Skill: `add-workspace-place`, `add-workspace-location`.
Failing test first: `WorkspaceNavigationTests` — two consecutive entries for G1 that both name S1 (canvas, then composer) after G1's row moves to S2: the correction for the second entry is non-nil (today the host's trigger value is the same S2 for both, so it never fires).
Do: add `followsGraphSource: Bool` (default false) to `PlaceRegistry.Spec`; set it on the `.sourceGraph`, `.sourceCitationComposer` and `.sourcePromote` specs. Add one static function (on `PlaceRegistry` or `WorkspaceLocation`) `pendingGraphSourceCorrection(location:, presentation:/spec:, graph:) -> WorkspaceLocation?` that returns `location.correctingGraphSource(graph)` only when the place's spec follows its graph's Source. The host observes that value: `.onChange(of: pendingCorrection, initial: true) { _, c in if let c { navigation.replaceCurrent(with: c) } }`, and its presentation `switch` goes. D-17's outcome stands; note in the plan's Landed note that the host observes the pending correction, not the graph's Source (CON-1).
Check: the new test passes; T-16 still passes; scripts/check-pr.sh PASS.

**F-2 — The credibility note states each Source's grade in the same shape** (from UX-1)
Files: `SourceMoveModel.swift`, `L10n.swift`, `Localizable.xcstrings`, `SourceMoveModelTests.swift`. Skill: `add-localized-string`.
Failing test first: `SourceMoveModelTests.credibilityNote` — a new row: origin unassessed, target High trust → the note contains "“Census” is not assessed" and "“Deed” is assessed High trust", and never "assessed not assessed".
Do: template `"“%1$@” is %2$@; “%3$@” is %4$@. …"` (keep the rest of the sentence); each grade argument is `L10n.Sources.moveAssessedAs(label)` ("assessed %@") or `moveNotAssessed`. Update the catalog entry and comments.
Check: test passes; check-pr PASS.

**F-3 — Show the Sources list's load state where the target field goes** (from UX-2; user decision 2026-11-22, supersedes D-10's "no field and no Callout")
Files: `SourceMoveModel.swift`, `SourceMoveDialog.swift`, `SourceMoveModelTests.swift`, `L10n.swift`/`Localizable.xcstrings` only if a new string is needed (prefer the existing load-area copy).
Failing test first: `SourceMoveModelTests` — with `listSourcesError` set, the model exposes a failed list state (not just `targets == nil`); after clearing the error and `readTargetsAgain()`, `targets` is non-nil. Update T-7's "list unread → nil" case to also assert the list state.
Do: expose the list's state from `listHandle.read.formLoadState`, as `SourceCopyModel.loadState` does (`SourceCopyModel.swift:77`). In the dialog, draw it in place of the field through `PVFormLoadArea` (compact loading; failure with Read again calling `session.reread(SourcesModel.sourcesListKey(for:))`). Keep the empty-list "nowhere to move" Callout as is. Record the D-10 supersession in the plan's Landed note.
Check: test passes; check-pr PASS.

**F-4 — `merged(with:)` names every field, and the two-write Save is documented** (from MNT-1)
Files: `CatalogMutation.swift`, `SourcePageModelTests.swift` (`mergedWriteEffectsUnion`), `docs/macos-client-patterns.md` rule 2, `.agents/skills/add-workspace-place/SKILL.md` § 6.
Failing test first: extend `mergedWriteEffectsUnion` to assert handles, structure, summaryHandles, handleScopes and deleted too.
Do: build the result with `CatalogWriteEffects(handles: …, evidenceGraphs: …, reads: …, lists: …, structure: …, summaryHandles: …, handleScopes: …, sourceScopes: …, deleted: …, activity: …)` so a new stored property fails to compile until merged. One sentence in rule 2 and § 6: a Save made of two writes applies `first.merged(with: second)` once.
Check: test passes; check-pr PASS.

**F-5 — Drop the stale idea section** (from MNT-2)
Files: `docs/ideas/source-page-followups.md`.
Do: delete "Artifact writes reload the whole workspace for the cover" and trim the header's "and what it reloads after an Artifact write".
Check: `rg refreshCoverFromStore docs .agents --glob '!docs/deployment-plan/**'` prints nothing; check-pr PASS.

**F-6 — One `listSources` requirement** (from MNT-3)
Files: `GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift`, `OnboardingModelTests.swift` (`ThrowingStore`).
Do: `listSources(projectDir:sourceIDs:)` is the only protocol requirement; a protocol extension `listSources(projectDir:)` forwards `[]`. GoStore keeps one body; FakeStore branches on empty ids inside one method and keeps `listSourcesCalls` / `listSourcesByIDCalls` counting as today.
Check: `rg -n "func listSources\(projectDir: String\) async" macos` prints only the protocol extension; existing tests pass; check-pr PASS.

**F-7 — Build the Move target options once per Sources-list change** (from PRF-1)
Files: `SourceMoveModel.swift`, `SourceMoveDialog.swift`, `WorkspaceSession+Derived.swift` if a derived value is used.
Do: the dialog's `body` reads a prebuilt `[PVComboBoxOption]`; build it from `targets` once per list revision (a `session.derived` entry with input `.derived(.sourcesByUpdated)`, or a model value recomputed only when the list handle's value changes). `pick` still resolves the row from `targets`.
Check: existing `SourceMoveModelTests` pass; check-pr PASS.

**F-8 — Read again shows progress; long bundle titles get a tooltip** (from UX-3, UX-4)
Files: `SourceMoveModel.swift`, `SourceMoveDialog.swift`, `SourceMoveModelTests.swift`.
Failing test first: `readFailureAndReadAgain` — after a failed pick read with a bundle held, `readAgain()` sets `readState == .loading` (or `isReading` drives `isRetrying`) before the reply.
Do: `readAgain()` sets `readState = .loading`; `SourceMoveRow` gets `.help(Text(verbatim: title))`.
Check: test passes; check-pr PASS.

**F-9 — T-8 and T-11 prove their rules** (from CON-2, CON-3)
Files: `SourceMoveModelTests.swift`, `FakeStore.swift` (only if `FakeHold` needs to resume a chosen call).
Do: T-8 releases S3's reply first, then S2's late reply, and asserts `impactTarget == "s3"` after it. T-11 applies `.sourcePage(sourceId: "s1")` before the move and asserts no extra `getSourceWorkspace` call and `s1Page.isStale`.
Check: both tests pass and would fail without the supersede / `apply(_:leavingPage:)` (say how you checked); check-pr PASS.

## Round 1 — fix
Head `16baf721d`. Gate PASS (orchestrator run). F-1 … F-9 done. Deviations: F-1 and F-3 tests did not compile before the fix (no separate red run); F-4's extended assertions pass on the old code too (the item is a compile-time guard); F-1 also edits `ResolvedPlace.swift`; F-3 adds `sources.move.targets.loading` and `sources.move.targets.loadError.title` (the existing load-area title names the bundle, not the list); F-9 adds `FakeHold.releaseNewest()`. F-9 mutation-checked: removing `LatestCall`'s generation guard fails T-8; `apply` + `leave` fails T-11.
PRF-1: **Resolved** — `SourceMoveModel.targetOptions` reads `session.derived(.sourceMoveTargets(originID:), inputs: [.derived(.sourcesByUpdated)])`; the dialog reads it.

## Round 2 — review
Reviewers: CON (CON-1 blocker), MNT (MNT-1, MNT-2 majors), UX (UX-1, UX-2 majors). Not sent: SEC+PRF (minor only; PRF-1 checked above). Scope `8c41d6a29...16baf721d`.

Round-1 items: CON-1 **Resolved** (CON round 2). UX-1, UX-2 **Resolved**; UX-3, UX-4 addressed (UX round 2). MNT-2 **Resolved**; MNT-3, MNT-4 addressed (MNT round 2). CON-2, CON-3 **Resolved** (orchestrator: implementer's mutation checks fail T-8 without `LatestCall`'s generation guard and T-11 with `apply` + `leave`). MNT-1 **Not resolved** → MNT-8.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-8 (MNT-1) | MNT | blocker | `merged(with:)`'s "fails to compile on a new field" guard does not exist; a new field now drops both writes' values, and rule 2 and `add-workspace-place` § 6 teach the false guard | Fix now → F-10 | verified: all ten `CatalogWriteEffects` properties have defaults and there is no explicit init (`CatalogMutation.swift:123-150`), so the synthesized memberwise init defaults every argument; reviewer's `swiftc` probe printed `[]` for an unnamed field. Re-rated from major: the fix made the drop worse and put the false claim in two guidance docs |

Nits (logged): `CON-5 · S15-25 plan:201 · D-17 row still describes onChange(of: graphSourceID); point it at the Landed note`

### Fix plan 2

**F-10 — Make the merge's field guard real and say what it is** (from MNT-8, MNT-1)
Files: `macos/ProvenenciaTests/SourcePageModelTests.swift` (`mergedWriteEffectsUnion`), `macos/App/Features/Workspace/Session/CatalogMutation.swift` (the comment in `merged(with:)`), `docs/macos-client-patterns.md` rule 2, `.agents/skills/add-workspace-place/SKILL.md` § 6.
Failing test first: in `mergedWriteEffectsUnion` (or a sibling test), pin the stored field set: `Mirror(reflecting: CatalogWriteEffects()).children.compactMap(\.label)` equals the ten names in declaration order, with a failure message telling the reader to add the new field to `merged(with:)` and to this test's merge assertions. Show it red by temporarily adding an eleventh defaulted property (revert it).
Do: keep the memberwise-init build in `merged(with:)` (it is clearer than `var out = self`), but reword its comment, rule 2's sentence and § 6's sentence to name the real guard: the field-set test in `mergedWriteEffectsUnion`, not the compiler. Do not remove the properties' defaults.
Check: the test passes; with a temporary eleventh field it fails with the message; `rg -n "fails to compile|must say how it merges" macos docs .agents` prints no claim of a compile-time guard for `merged`; scripts/check-pr.sh PASS.

## Round 2 — fix
Head `52c7508c0`. Gate PASS. F-10 done: `SourcePageModelTests.writeEffectsFieldSetIsPinned` pins the ten stored fields with `Mirror`; shown red with a temporary eleventh field. The code comment, rule 2 and `add-workspace-place` § 6 name the test as the guard. MNT-8 **Resolved** (orchestrator read the test and the three lines).
Orchestrator docs commit: the plan's Landed note no longer claims a compile-time guard for `merged(with:)` (it named one at line 33), and the D-17 row points at its landed form (CON-5). Head `102bbccf9`. `origin/main` had not moved since `4ca4a236a`; gate PASS.

## Result
Gate PASS · CI green · open: none · follow-ups: PRF-1 neighbor (`SourceTypeFormatsSection.swift:99` builds ComboBox options in `body`) → `docs/ideas/performance-possibilities.md` (user, 2026-11-22) · to user: UX-2 (answered 2026-11-22: fix in this PR, supersedes D-10's "no Callout")
