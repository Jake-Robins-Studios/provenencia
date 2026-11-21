# Ship log — S15-21 The provenance sheet shows formatted citations

**Plan:** [`S15-21-provenance-sheet-citations.md`](S15-21-provenance-sheet-citations.md) · **Branch:** `s15-21-provenance-sheet-citations` · **PR:** #930
**State:** ready

## Round 0 — implement
Head `f8aa0967d`. Gate PASS (orchestrator re-run against `b57c98a70`). Report deviations: STEP-8 also changed `PersonDetailTests.likenessesBecomeTilesEarliestFirst` and `aRecordNamesItsCitation` (they asserted the removed empty-title-to-ref fallback); the load area's `space5` top padding applies only while loading or failed; `PVProvenanceRecordRow.copies(for:)` is `nonisolated`; commits grouped by file, not per behavior, because intermediate commits would not build; manual check (§10) not run (no GUI). Version 0.30.2 → 0.31.0.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. Skipped: none. UX for `macos/App/**` and `Localizable.xcstrings`; SEC+PRF for the query-cache code in `Features/Workspace/Session`, a catalog-sized citation batch, and RTF built from catalog text.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | major | Manual check not run; AC-3.3 rules and the host's environment read in a sheet have no other proof | Fix now → F-1 (AC-3.3 test, host test); rest stays on § 10 for the user | verified: `PVProvenanceRecordTable.swift:31-33` rule test is inline in `body`, no test reaches it. The sheet's environment: `pvSheet` is a plain SwiftUI `.sheet` (`PVSheet.swift:205`) under `WorkspaceView`'s `.environment(session)` (`WorkspaceView.swift:70`); SwiftUI sheets inherit the presenter's environment, but no test shows it, so § 10 step 1 stays the proof (user's manual check) |
| MNT-1 | MNT | major | View-held key lifetime (`WorkspaceSession.release`) not in `add-workspace-place` or `macos-client-patterns.md` (also CON outside-lens) | Fix now → F-2 | verified: `rg release\( .agents/skills/add-workspace-place/SKILL.md` empty; `macos-client-patterns.md:90` names only `whenHidden` |
| MNT-3 | MNT | minor | `CatalogRenderedCitation` test fixture in four copies; shared one in a suite's file | Fix now → F-3 (same-pass cleanup) | verified: `CatalogQueryRegistryTests.swift:1885`, `ProvenanceSheetTests` `render`, `CatalogSessionStoreTests` `rendered` |
| MNT-2 | MNT | minor | Emphasis test written two ways (`contains` vs `==`) | Fix now → F-4 | verified: `PVClipboardButton.swift:67`, `PVTitleText.swift:170` |
| MNT-5 | MNT | minor | `copies(for:)` decides, `copyButton` re-unwraps | Fix now → F-5 | verified: `PVProvenanceRecordRow.swift:68-71, 117-148` |
| CON-2 | CON | minor | T-3 in-flight case can't fail if the released load lands on the new handle | Fix now → F-6 | verified: both loads answer the same reply; no `revision` check |
| MNT-4 | MNT | minor | `CitationLineDisplay` doc comment says it will be replaced | Fix now → F-7 | verified: `CitationLineDisplay.swift:18-20` |
| CON-3 | CON | minor | Review log links the brief at its old path | Fix now → F-7 | verified: `S15-21-…review.md:4` → `../design/S15-D9-…md` missing |
| UX-1 | UX | minor | Past 2,000 ids the failure reads "That citation isn't valid" and Read again can't help | Rejected | D-5 decides this case is the failed state; past the map's Scale (1,200 records per value), and a value with more than 2,000 distinct Citations needs more than 2,000 records on one value |
| MNT outside-lens (PRF) | MNT→PRF | — | Host's `key` sorts every id on each `body` | Rejected | SEC+PRF reviewer checked it: O(records) per body, bounded by the sheet's records (Scale 1,200), body re-runs only on handle add/remove or row change |

Nits (logged): `MNT-6 · CatalogQueryRegistryTests.swift:1884, WorkspaceSessionTests.swift:2517 · double blank line` · `MNT-7 · PVButton.swift:171 · iconTint: Color? beside PVIconButtonTone` · `MNT-8 · PVClipboardButton.swift:67 · keep typed subscript, share per MNT-2` · `UX-2 · PVProvenanceColumns.swift:43 · 72pt copy track has ~1.3pt spare for "Short"` · `CON-4 · design/archive/S15-D9-…md:9 · link text still shows the old relative paths`

SEC+PRF: no findings.

### Fix plan 1

**F-1 — Prove the run rules and the host's read** (from CON-1)
Files: `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceRecordTable.swift`, `macos/ProvenenciaTests/ProvenanceSheetTests.swift`. Skill: `add-swift-test`.
Failing test first: `ProvenanceSheetTests.ruleFallsBeforeEachRunButTheFirstAfterALine` — for a value run with heading and citations `[a, a]`, `[b]`: no rule before the first run, a rule before `b`, never inside a run; a run with no heading and no owner line draws a rule before its first run.
Do: lift the inline test at `PVProvenanceRecordTable.swift:31-33` into a pure `static func drawsRule(runIndex: Int, followsLine: Bool) -> Bool` (and the `followsLine` computation into a static taking the run and value index, if it reads cleanly) and call it from `body`; behaviour unchanged. Add `ProvenanceSheetSessionTests.hostReadsTheSessionAndRendersOnTask` (`.hostedWindows`): host `ProvenanceSheetHost` in `hostInBorderlessWindow` with `.environment(session)` over a `FakeStore`, wait for the query, expect one `renderCitations` call with the records' sorted ids and the key's handle holding a value. Do not try to present a real sheet.
Check: both tests pass; scripts/check-pr.sh PASS.

**F-2 — Write the view-held key lifetime into the guidance** (from MNT-1)
Files: `.agents/skills/add-workspace-place/SKILL.md`, `docs/macos-client-patterns.md`.
Do: in the skill's Refresh / Mark stale table add a row: a key no place shows, held by one view, is warmed in `.task(id: key)`, read with `queryHandle` in `body`, and released with `session.release` on `onChange(of: key)` and `onDisappear`; `release` never drops a key in `visibleKeys`; example `ProvenanceSheetHost`; not `whenHidden`. Add a matching clause to `macos-client-patterns.md` at the `whenHidden` sentence (line 90).
Check: `rg -n "release" .agents/skills/add-workspace-place/SKILL.md docs/macos-client-patterns.md` shows both; plan-docs check passes.

**F-3 — One rendered-citation fixture** (from MNT-3)
Files: `macos/ProvenenciaTests/CatalogFixtures.swift`, `CatalogQueryRegistryTests.swift`, `WorkspaceSessionTests.swift`, `ProvenanceSheetTests.swift`, `CatalogSessionStoreTests.swift`.
Do: move `renderedCitation(_:key:full:)` into `CatalogFixtures.swift` with whatever optional parameters (`full` empty, `short`) the local copies need, delete the local `render(_:key:full:)` and `rendered` helpers and call it. The `#Preview` copy in `PVProvenanceRecordTable.swift` stays (app target cannot see test fixtures). Fix MNT-6's double blank lines while there.
Check: `rg -n "func (render|rendered|renderedCitation)\(" macos/ProvenenciaTests` prints only the `CatalogFixtures.swift` line; tests pass.

**F-4 — One emphasis predicate** (from MNT-2, MNT-8)
Files: `macos/App/DesignSystem/Components/TitleText/PVTitleText.swift`, `macos/App/DesignSystem/Components/ClipboardButton/PVClipboardButton.swift`.
Do: add `nonisolated static func isEmphasized(_ run: AttributedString.Runs.Run) -> Bool` beside `italicizingEmphasis` (keep the typed `InlinePresentationIntentAttribute` subscript, use `contains(.emphasized)`), and use it in both `italicizingEmphasis` and `rtfData`.
Check: `rg -n "InlinePresentationIntentAttribute" macos/App/DesignSystem` shows only the predicate; T-7/T-7b pass.

**F-5 — The copy list carries its payload** (from MNT-5)
Files: `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceRecordRow.swift`, `macos/ProvenenciaTests/ProvenanceSheetTests.swift`.
Do: make `copies(for:)` return values that carry what the button needs (cases with their `CatalogCitationRender`, or a small struct with text, rich, word, label, announcement, id suffix) so `copyButton` is one `PVClipboardButton` call with no `if let` and no empty branch. Keep `copies(for:)` pure and `nonisolated`; adjust T-8 to compare the new values.
Check: T-8 passes; no `if let` on `record.rendered` in `copyButton`.

**F-6 — T-3 in-flight case can fail** (from CON-2)
Files: `macos/ProvenenciaTests/WorkspaceSessionTests.swift`.
Failing test first: make the released load answer a different reply from the second (or count successes) and assert `store.renderCitationsCalls.count == 2` and `second.revision == 1` after both settle. Prove it can fail by temporarily removing the generation guard locally (do not commit that).
Check: test passes on the branch.

**F-7 — Two stale docs lines** (from MNT-4, CON-3, CON-4)
Files: `macos/App/Platform/CitationLineDisplay.swift`, `docs/deployment-plan/spike-15/prs/S15-21-provenance-sheet-citations.review.md`, `docs/deployment-plan/spike-15/design/archive/S15-D9-provenance-sheet-citations.md`.
Do: the doc comment says this is today's line, the fallback for a Source type with no full format, and its other callers (rule "Today's line stays the fallback, in Swift"). Point the review log at `../design/archive/S15-D9-provenance-sheet-citations.md`. Fix the archived brief's link text to match its targets.
Check: scripts/check-pr.sh PASS.

Order: F-1, F-2 (majors), then F-3 – F-7.

## Round 1 — fix
Head `f6fcfcd7e`. Gate PASS (orchestrator re-run). F-1 – F-7 done. Deviations: commits grouped by file (F-1, F-3, F-5, F-6 share test files); F-1's test did not compile before the lift, so no red run; F-6 proven able to fail by removing the generation guard locally (restored).

## Round 2 — review
Reviewers: CON (CON-1 major), MNT (MNT-1 major). Scope: `f8aa0967d...f6fcfcd7e`. UX and SEC+PRF not sent: no Fix-now blocker or major.
CON-1: **Resolved** — rule logic lifted into `followsLine` / `drawsRule`, called from `body`, tested by `ruleFallsBeforeEachRunButTheFirstAfterALine`; `hostReadsTheSessionAndRendersOnTask` proves the host reads the session; a real sheet's environment stays on § 10 step 1. CON-2, CON-3, CON-4 checked in the fix commits: Resolved.
MNT-1: **Resolved** — `add-workspace-place/SKILL.md:66` and `macos-client-patterns.md:90` match `ProvenanceSheetHost` and `WorkspaceSession.release`. MNT-2 – MNT-6, MNT-8 checked in the fix commits: Resolved.
New blockers: none.

Nits (logged): `CON-5 · ProvenanceSheetTests.swift · ruleFallsBeforeEachRunButTheFirstAfterALine's grouped/runKeys check re-proves T-5; a comment would say why`

## Result
Gate PASS at `f6fcfcd7e` (`origin/main` unmoved, `b57c98a70`) · CI see PR · open: none · follow-ups: none · to user: — · manual check (§ 10) not run: the user's
