# Ship log — S15-27 The provenance table folds a page at a time

**Plan:** [`S15-27-provenance-table-fold.md`](S15-27-provenance-table-fold.md) · **Branch:** `s15-27-provenance-table-fold` · **PR:** #1006
**State:** reshape fixing 1

## Round 0 — implement
Not committed or pushed. **Stopped on** §11 "The Release test build fails". STEP-1 done in Debug (uncommitted on the local branch): `Timing.swift`, `CatalogListMergeTests` re-pointed, `PVProvenanceSheetLayoutTests`, `PVProvenancePreviewData.content(groups:summary:)` takes `String?`.
D-9's Release command fails to compile: `cannot find 'FakeStore' in scope` in `#Preview` blocks at `ConclusionPictureViewer.swift:405`, `SourcesListPreviews.swift:12,13,56`, `WorkspaceToolbar.swift:504,508`. Orchestrator confirmed `macos/App/Platform/FakeStore.swift` is wrapped in `#if DEBUG` while those previews are not. A gap on `main`, not caused by this PR.
Debug "before" figures (best of 3): 300 records 1515 ms (doc height 24,900 pt); 1,200 records 6357 ms (doc height 99,600 pt).
Deviations so far: summary param made optional; `CatalogListMergeTests` keeps its own copy-per-run loop, calls shared `milliseconds(_:)`; version bump will be 0.48.1 (main is 0.48.0).
Taken to user. User: fix the Release app build first (quick PR #1003, merged, which also adds check-patterns rule `swift-debug-only-in-release`), delete the flaky hosted reveal test (#1005, merged), then replan. The test target cannot compile in Release by design (FakeStore is `#if DEBUG`), so the plan was refreshed through plan-pr to Debug-only figures (review log "Refresh"; main @ `c1035450b`). Round-0 WIP restored on the branch, rebased onto that main.

**Resumed.** Head `64d40aff4`. Gate PASS (orchestrator, against `c1035450b`). Report: no code deviations. Debug figures, best of 3: before 300 → 1558 ms (24,900 pt), 1,200 → 6691 ms (99,600 pt); after 271 ms / 268 ms (both 4,185 pt). AC-3.x press/focus/Tab manual checks not run (need a person). Notes: the "Cap" rewrite dropped its "Assembly is O(n²)" bullet; `fold` landed in the STEP-2/3 commit.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF (route-reviewers; SEC+PRF on `CatalogListMergeTests.swift`, and the fold bounds an unbounded record list).


| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1, UX-1 | CON, UX | blocker | Return on Show more may fire Done's `.defaultAction` | Fix now → F-1 | Verified by precedent: `PVConfirm.swift:168,185` and `PVFormDialogControls.confirmShortcut` (`PVFormDialog.swift:64-67`) already drop `.defaultAction` because it beats a focused Return owner. `PVShowMoreRow` takes Return via `onKeyPress` (`PVReturnActivation.swift`). No unit seam (no key synthesis); the §10 check confirms |
| SEC-1 | SEC | major | The fold bounds runs, not the records inside them | To user → Rejected (user, 2026-11-27) | A run of more than one record needs two records behind one value from the same property and Source: a data-entry error the user calls super rare. It draws slowly, it does not crash; no cap. Recorded in the plan's Edges and §11 (F-5) |
| CON-2 | CON | major | §10 manual checks not run; AC-1.4 presses, AC-1.6, AC-3.1–3.4 have no evidence | To user (manual check) | The implementer cannot drive the preview canvas; no key synthesis in tests. Goes to the user's manual check before merge |
| MNT-1 | MNT | minor | Two `bestOfMilliseconds` loops in the test target | Fix now → F-2 (same-pass cleanup) | Supersedes the plan's Codebase fit row for `Timing.swift`, which kept the private loop |
| MNT-2 | MNT | minor | The layout test holds its own window | Fix now → F-3 | `add-swift-test` line 17; `HostedWindow.swift:69-76` registers it |
| CON-3 | CON | minor | Review log links the brief's old path | Fix now → F-4 | `S15-27-provenance-table-fold.review.md:3` |
| UX-2 | UX | minor | "Show 50 more" counts runs; the sheet counts records | Rejected | Runs are one record in real data (user, 2026-11-27), so runs counted ≈ records; D-8 is the user's wording |

Nits (logged): `MNT-3 · ProvenanceSheetTests.swift:423 · runCount repeats folded's reduce` · `MNT-4 · PVProvenanceSheetContent.swift:223-236 · comment the empty-group rule (AC-2.3)` · `CON-4 · ProvenanceSheetTests.swift · split chained #expect(a && b && c)` · `UX-3 · PVProvenanceSheet.swift:138 · one multi-record run in the 120-run preview`


Follow-up (ask the user at finish): Return on a focused citation link in this sheet may also fire Done's `.defaultAction`. That code predates this PR; F-1 frees Return only for Show more.

### Fix plan 1

**F-1 — Return on Show more does not fire Done** (from CON-1, UX-1)
Files: `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheet.swift`, `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceRecordTable.swift`, `macos/ProvenenciaTests/ProvenanceSheetTests.swift`. Skills: `add-ui-component`, `add-swift-test`.
Failing test first: `ProvenanceSheetTests/doneGivesUpReturnToShowMore`, a pure test of *(new)* `nonisolated static func doneShortcut(showMoreFocused: Bool) -> KeyboardShortcut?` on `PVProvenanceSheet`: `true` → `nil`, `false` → `.defaultAction`. Same shape as `PVFormDialogControls.confirmShortcut(innerEditOpen:)` (`PVFormDialog.swift:64-67`) and its test.
Do: the table keeps its own `@FocusState` (D-4). It reports `focus == .showMore` up through a recipe-private `PreferenceKey` *(new, in `PVProvenanceRecordTable.swift`)*, reduced with `||`, the way `PVSheet.swift`'s `PVSheetInnerEditKey` reports an inner edit. `PVProvenanceSheet` reads it with `.onPreferenceChange` into `@State private var showMoreFocused = false`, and Done uses `.keyboardShortcut(Self.doneShortcut(showMoreFocused: showMoreFocused))`. Do not use `.pvSheetInnerEdit`: it also takes Escape. Escape still closes the sheet.
Check: the test passes; scripts/check-pr.sh PASS. Note for §10: Return on Show more reveals the next page and the sheet stays open.

**F-2 — One best-of timing helper** (from MNT-1; same-pass cleanup, supersedes the plan's Codebase fit row for `Timing.swift`, which kept the private loop)
Files: `macos/ProvenenciaTests/Timing.swift`, `macos/ProvenenciaTests/CatalogListMergeTests.swift`, `macos/ProvenenciaTests/PVProvenanceSheetLayoutTests.swift` if its call changes.
Do: in `Timing.swift`, add `func bestOfMilliseconds<S>(runs: Int, prepare: () -> S, _ run: (inout S) -> Void, check: (S) -> Void = { _ in }) -> Double`. Each run calls `prepare()` outside the timed span, times `run(&state)`, then calls `check(state)` outside it. Keep `bestOfMilliseconds(runs:_:)` as a one-line wrapper over it. Point `CatalogListMergeTests`'s callers at the shared helper (`prepare: { list.rows }` or `{ list }`, `check: { #expect($0.count == expected) }`) and delete its private `bestOfMilliseconds(_:runs:expected:_:)`.
Check: `grep -rn "func bestOfMilliseconds" macos/ProvenenciaTests` prints only the two lines in `Timing.swift`; `-only-testing:ProvenenciaTests/CatalogListMergeTests` passes; scripts/check-pr.sh PASS.

**F-3 — The layout test does not hold its window** (from MNT-2)
Files: `macos/ProvenenciaTests/PVProvenanceSheetLayoutTests.swift`.
Do: bind `let (_, host) = hostInBorderlessWindow(...)`; delete the `window` var and `withExtendedLifetime`. Keep the last run's host for the height read (D-9).
Check: `-only-testing:ProvenenciaTests/PVProvenanceSheetLayoutTests` passes.

**F-4 — Review log links the archived brief** (from CON-3)
Files: `docs/deployment-plan/spike-15/prs/S15-27-provenance-table-fold.review.md` line 3 → `../design/archive/S15-D17-provenance-table-fold.md`.
Check: `rg -n "\.\./design/S15-D17" docs` prints only the plan's STEP-7 prose that names the move source.

**F-5 — Record the user's answer and the fix round in the plan**
Files: `docs/deployment-plan/spike-15/prs/S15-27-provenance-table-fold.md`.
Do: in Edges "Untrusted size" and the §11 risk row, add that several records repeating one citation under a value (runs of more than one record) are accepted as a data-entry case: they draw slowly and do not crash, with no cap (user, 2026-11-27). In the Landed note, add that Done gives up Return while Show more has focus (F-1), and that the best-of loops were merged into `Timing.swift` (F-2, superseding the Codebase fit row).
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-27-provenance-table-fold.md` 0 errors.


## Round 1 — fix
Head `504a59c14`. Gate PASS (orchestrator). F-1 to F-5 done; `doneGivesUpReturnToShowMore` red (no `doneShortcut`) then green. Deviations: `PVProvenanceShowMoreFocusKey` is internal (table and sheet are separate files); `completed.md` paragraph updated for F-1. Read by the orchestrator: MNT-1 **Resolved** (one generic `bestOfMilliseconds` in `Timing.swift`, plain form wraps it), MNT-2 **Resolved**, CON-3 **Resolved**.

## Round 2 — review
Reviewers: CON (CON-1 was a Fix-now blocker). Scope `64d40aff4...504a59c14`.


| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | blocker | (round 1) Return on Show more may fire Done | Resolved | Preference `PVProvenanceShowMoreFocusKey` → `doneShortcut(showMoreFocused:)`; key routing itself goes to the §10 manual check |

Nits (logged): `CON-5 · plan Landed note says "recipe-private"; the key is internal` · `CON-6 · completed.md:5 · split the "and … and …" sentence`

## Result
Gate PASS · CI pending at ready · open: none in code; CON-2 (§10 manual check) with the user · follow-ups: Return on a focused citation link may fire Done (pre-existing) · to user: SEC-1 answered (accepted, 2026-11-27)


## Reshape (user, 2026-11-27)
After the PR was ready, the user dropped citation runs entirely: every record is its own row, owner lines and value headings stay, and the fold counts records across the sheet; the engine's group key goes too. Replanned through plan-pr on the branch (`0459f185b`, review answered in `058bd8308`; review log "Reshape"). The loop restarts: round 0 implements the reshaped plan on top of the branch.

## Reshape round 0 — implement
Head `19750e919`. Gate PASS (orchestrator). Report: no deviations. Debug T-7 after: 266 ms at 300 and 1,200 records (4,185 pt both). AC-1.6, AC-3.1–3.4 manual (not run).

## Reshape round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF (route-reviewers), full PR `c1035450b...19750e919`.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | blocker | A second "child takes Return from the sheet's default button" mechanism beside `pvSheetInnerEdit` | Fix now → F-1 (same-pass cleanup; supersedes D-7) | `PVProvenanceRecordTable.swift:80-90` / `PVProvenanceSheet.swift:25-31,74,78` copy `PVSheet.swift:183-207` + `PVFormDialogControls.confirmShortcut` (same `||` reduce, same `nil : .defaultAction` body). No researcher-visible change, so not To user |
| UX-1 | UX | major | After a keyboard Show more, focus is on a citation link and the next Return fires Done | Fix now → F-1 (supersedes the Out line) | This PR moves focus onto the link (AC-3.2) and adds the claim that reports only `.showMore`; `PVInkLink.swift:33` handles Return; precedent `PVConfirm`/`PVFormDialog` |
| CON-1 | CON | major | Plan marked Landed with no Landed note | Fix now → F-3 | DoD §9; `8d3290ee4` had one |
| CON-2, MNT-2 | CON, MNT | minor | Stale "(S15-27 D-9)" on the layout suite; duplicate T-4 / T-8 labels | Fix now → F-2 | `PVProvenanceSheetLayoutTests.swift:6`; `ProvenanceSheetTests.swift:38,60,74,440` |

SEC+PRF: clean, no findings.

Nits (logged): `MNT-3 · render_test.go:423 · rename dropsGroup` · `MNT-4 · ProvenanceSheetTests.swift:1097 · records(_:prefix:) only forwards` · `CON-3 · S15-21's T-8 label (rides with F-2)` · `UX-2 · PVProvenanceRecordRow.swift:93 · repeated record ids can repeat an accessibility id (pre-existing)`

### Fix plan 1 (reshape)

**F-1 — One sheet-level Return claim; the provenance table claims Return while it holds focus** (from MNT-1, UX-1; supersedes D-7 and the Out line "Return on a focused citation link firing Done")
Files: `macos/App/DesignSystem/Components/Panel/PVSheet.swift`, `macos/App/DesignSystem/Components/FormDialog/PVFormDialog.swift`, `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheet.swift`, `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceRecordTable.swift`, `macos/ProvenenciaTests/PVPanelFormDialogTests.swift`, `macos/ProvenenciaTests/ProvenanceSheetTests.swift`, `macos/App/DesignSystem/README.md` (Panel row), `docs/macos-client-patterns.md` if it names the inner-edit Return rule. Skills: `add-ui-component`, `add-swift-test`.
Failing test first: `PVPanelFormDialogTests/defaultActionYieldsWhenReturnIsTaken` on *(new)* `PVSheetDefaultAction.shortcut(returnTaken:) -> KeyboardShortcut?` (`true` → `nil`, `false` → `.defaultAction`), in `PVSheet.swift`.
Do: in `PVSheet.swift`, split a Return-only claim out of the inner-edit claim: a `||`-reduced preference *(new)* raised by `func pvSheetTakesReturn(_ taken: Bool) -> some View` *(new)*, read by the sheet chrome into an environment value `\.pvSheetReturnTaken` *(new)*. `pvSheetInnerEdit(_ open:)` also raises `pvSheetTakesReturn(open)`, and keeps claiming Escape and the outside click as today. `PVFormDialog`'s Confirm and `PVProvenanceSheet`'s Done both use `.keyboardShortcut(PVSheetDefaultAction.shortcut(returnTaken: returnTaken))` with `@Environment(\.pvSheetReturnTaken)`. `PVProvenanceRecordTable` raises `.pvSheetTakesReturn(focus != nil)`, so Return goes to Show more or to the focused citation link (`PVInkLink`'s own handler). Delete `PVFormDialogControls.confirmShortcut(innerEditOpen:)` and its test, `PVProvenanceSheet.doneShortcut(showMoreFocused:)` and `doneGivesUpReturnToShowMore`, `PVProvenanceShowMoreFocusKey`, the sheet's `showMoreFocused` and `.onPreferenceChange`; delete `\.pvSheetInnerEditOpen` too if nothing reads it after. First confirm the provenance sheet is presented through `.pvSheet` (`macos/App/Features/Conclusions/ReconciledValueRow.swift`); if it is not, stop and report. Update the README Panel row to name `pvSheetTakesReturn`.
Check: the new test passes; `rg -n "confirmShortcut|doneShortcut|ShowMoreFocus" macos` prints nothing; scripts/check-pr.sh PASS. §10 gets: Return on Show more reveals the next page; a second Return opens the focused Citation; Escape still closes the sheet.

**F-2 — Test labels name the right plan and IDs** (from CON-2, MNT-2, CON-3)
Files: `macos/ProvenenciaTests/PVProvenanceSheetLayoutTests.swift` (line 6 → "(S15-27 D-14, T-7)"), `macos/ProvenenciaTests/ProvenanceSheetTests.swift` (this PR's fold tests' labels prefixed "S15-27 T-…"; S15-21's prefixed "S15-21 T-…").
Check: `rg -n "/// T-[0-9]" macos/ProvenenciaTests/ProvenanceSheetTests.swift` prints nothing.

**F-3 — The plan's Landed note** (from CON-1)
Files: `docs/deployment-plan/spike-15/prs/S15-27-provenance-table-fold.md`.
Do: add `## Landed` listing every difference from the plan: F-1 (one sheet-level Return claim, `pvSheetTakesReturn`; the table claims Return while any of its stops has focus; supersedes D-7 and the Out line on citation-link Return), the T-7 figures (266 / 266 ms), and the STEP-1 temporary `groupKey` in the preview that STEP-2 removed. Update `completed.md`'s S15-27 paragraph if F-1 changes what it says about Done and Return.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-27-provenance-table-fold.md` 0 errors.

## Cost
Plan: 5,424 words (check-plan-docs info line).

| Round | Agent | Model | Tokens |
| --- | --- | --- | --- |
| 0 | implementer | sonnet | 122k |
| 0 (resume) | implementer | sonnet | 146k |
| refresh | plan executability | opus | 121k |
| 1 | CON | opus | 111k |
| 1 | MNT | opus | 77k |
| 1 | UX | opus | 96k |
| 1 | SEC+PRF | opus | 76k |

| 1 | implementer fix | sonnet | 93k |
| 2 | CON | opus | 46k |
| | **Total** | | **888k** (largest: implementer resume, 146k) |
| reshape | planner | opus | 257k+ |
| reshape | plan maintainability | opus | 174k |
| reshape | plan executability | opus | 173k |
| reshape 0 | implementer | sonnet | 162k |
| reshape 1 | CON | opus | 105k |
| reshape 1 | MNT | opus | 109k |
| reshape 1 | UX | opus | 71k |
| reshape 1 | SEC+PRF | opus | 78k |
