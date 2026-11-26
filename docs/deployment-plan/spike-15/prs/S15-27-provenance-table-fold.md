# S15-27 — The provenance table folds a page at a time

**Status:** Blocked — on board S15-D17
**Spike / slice:** Spike 15 · Slice 8 — Provenance loading
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D17](../design/S15-D17-provenance-table-fold.md), board not agreed yet
**Board:** the [Person page board](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ), page *Vitals*, the S15-D17 turn (user, 2026-11-26). The turn and agreed frames are recorded here when the board is agreed; **§ 6 macOS** describes each frame in words
**Depends on:** S15-30 (landed [#996](https://github.com/Jake-Robins-Studios/provenencia/pull/996)), S15-21 (landed [#930](https://github.com/Jake-Robins-Studios/provenencia/pull/930)), S15-D17
**Blocks:** —
**Branch:** `s15-27-provenance-table-fold`
**Version bump:** patch, 0.47.0 (today's `VERSION`) → **0.47.1** (or the next patch after `main`'s `VERSION` when you rebase): a long provenance table no longer freezes the sheet, a fix to an existing view ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/design-system-layers.mdc` (a recipe names no `Features/` type)
**Context:** map scope entry S15-27 ([`../deployment-plan.md`](../deployment-plan.md)); working rule "The provenance table folds a page at a time"; [`../provenance-loading.md`](../provenance-loading.md) "Cap the records a provenance table draws"; [`docs/design-system-layers.md`](../../../design-system-layers.md); [`docs/macos-client-patterns.md`](../../../macos-client-patterns.md) "One sectioned detail page" (the paged fold) and "Detail pages share their rows"
**Host:** macOS with Xcode. Tests: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS'`, narrowed with `-only-testing:ProvenenciaTests/<Suite>` where a Step says so. The implementer runs the manual check in §10.
**Planned:** 2026-11-26 against `main` @ `d96d26c`
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

A value with hundreds or thousands of records opens its provenance sheet quickly. The sheet's record table draws its first 50 citation runs (a run is the records whose full citations read the same, or one record alone) and ends with the kit's "Show 50 more" row; each press reveals the next 50, never splitting a run. Today the table draws every record at once on the main thread: 1,200 records took 8.7 – 12.2 s to lay out in a Debug build ([`provenance-loading.md`](../provenance-loading.md) "Cap").

**Why now.** S15-30 moved the paged fold and `PVShowMoreRow` into the kit so a recipe can name them; this is the slice's next PR, and S15-31 will open this sheet from Event and Place rows, where a Place's name row grows with the catalog.

**What stays.** A table of 50 runs or fewer draws exactly as today. The header's summary counts every record. Records still arrive with the page (S15-29 moves them). The Why accordion on Event and Place pages is untouched (S15-31 removes it).

## 2. User stories

**US-1.** As a researcher, when I open the provenance sheet of a value with 1,200 records, it draws its first 50 citations at once, so that I can read the strongest records without waiting seconds.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | 120 runs of one record each, sheet opens | 50 runs draw, then "Show 50 more" |
| AC-1.2 | 50 runs; or 0 records | Every run draws, no Show more row |
| AC-1.3 | The 50th run holds 6 records | All 6 draw; the 51st run is the first hidden |
| AC-1.4 | 120 runs, Show more pressed twice | 100 runs after one press ("Show 20 more"), all 120 and no row after the second |
| AC-1.5 | 1,200 records, first layout timed (T-7) | The scroll area's height equals the height at 300 records: the fold bounds what draws |
| AC-1.6 | Summary of a value with 1,200 records | "… 1,200 records", unchanged by the fold |

**US-2.** As a researcher reading a sheet with owner lines and value headings, the fold keeps each run under its own line, so that I still see which owner and value a record counted for.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Owner A with 50 runs, owner B with 3 | Only A's line and runs draw, then the row; after a press, B's line and its 3 runs |
| AC-2.2 | One owner, value 1 with 60 runs, value 2 with 5 | Value 1's heading and 50 runs, then the row; after a press, value 1's other 10 runs with no second heading, then value 2's heading and its 5 runs |
| AC-2.3 | An owner group with no records, before the cut | Its owner line draws, as today |

**US-3.** As a keyboard user, Show more moves me to what it revealed, so that I keep my place.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Tab past the last shown row's links | Focus reaches "Show 50 more", then Done |
| AC-3.2 | Return on Show more | The page reveals; focus is on run 51's first record's citation link, scrolled into view |
| AC-3.3 | A pointer click on Show more | The page reveals; focus and scroll stay where they were |
| AC-3.4 | Close the sheet after two presses, open it again | 50 runs and "Show 50 more" |

## 3. Scope

| In | Covered by |
| --- | --- |
| The fold rule over the table's runs (RF-1, RF-2, RF-3, RF-8) | STEP-2, AC-1.1 – AC-1.4, AC-1.6, AC-2.1 – AC-2.3 |
| The Show more row ending the table, its press and reset (RF-4, RF-5, RF-W1) | STEP-3, AC-1.4, AC-3.4 |
| Keyboard focus and scroll after a press (RF-6, RF-7) | STEP-3, STEP-4, AC-3.1 – AC-3.3 |
| First layout measured at 300 and 1,200 records, before and after | STEP-1, STEP-5, AC-1.5 |

| Out | Home |
| --- | --- |
| Records loading when the sheet opens | S15-29 |
| A linear assembly (the denial facts from the engine) | S15-28, S15-29 |
| The Why accordion's own table (`ReconciliationRecordRows`) on Event and Place pages | S15-31 (removed; those rows then open this sheet and get the fold) |
| A fold inside one citation run | not planned (user, 2026-11-26: a run is never split; see §11) |
| A sheet-specific Show more wording | not planned (user, 2026-11-26: the kit's "Show N more") |
| Lazy rows (`LazyVStack`) in the table | not planned (the working rule chose the fold) |
| The likeness viewer's single record row (`ConclusionPictureViewer`) | not planned (one row, nothing to fold) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Table | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceRecordTable.swift` `PVProvenanceRecordTable.body` | Draws every group, value run and citation run in one `VStack`; no fold, no focus state, rows carry no `.id`. `ForEach(groups)` is not enumerated |
| Rule placement | same file `followsLine(hasHeading:valueIndex:hasOwner:)`, `drawsRule(runIndex:followsLine:)` | Pure; unchanged by the fold (a shown prefix keeps every index) |
| Sheet | `…/ProvenanceSheet/PVProvenanceSheet.swift` `PVProvenanceSheet.body` | The table sits in a `ScrollView` capped at `recordsMaxHeight` (560) inside `PVFormLoadArea`; no Show more reveal provider |
| Row | `…/ProvenanceSheet/PVProvenanceRecordRow.swift` `PVProvenanceRecordRow.citation` | The citation `PVInkLink` takes no `.focused`; nothing can claim it |
| Content | `…/ProvenanceSheet/PVProvenanceSheetContent.swift` `Group`, `Group.ValueGroup`, `Group.ValueGroup.CitationRun`, `grouped(by:)` | Runs are built per value run; nothing counts runs across the table |
| Host | `macos/App/Features/Conclusions/ProvenanceSheetHost.swift` `ProvenanceSheetHost` | Passes the grouped content; the table only draws at `.ready`, so a key change (loading) drops the table and its state |
| Kit fold | `macos/App/Platform/PagedFold.swift` `PagedFold`, `PagedFoldState`; `macos/App/DesignSystem/Components/ShowMoreRow/PVShowMoreRow.swift` `PVShowMoreRow`, `pvScrollsShowMoreReveals(animated:)` | Landed in S15-30; used by the Person page's sections |
| Focus claim | `macos/App/Platform/FocusClaim.swift` `FocusClaim.claim` | Used by `PVShowMoreRow.press` |
| Previews | `PVProvenanceRecordTable.swift` `PVProvenancePreviewData`; `PVProvenanceSheet.swift` `#Preview("Thirty records")` | No preview past 50 runs |
| Tests | `macos/ProvenenciaTests/ProvenanceSheetTests.swift` (`groupedGathersByEngineKeyWithinARun`, `ruleFallsBeforeEachRunButTheFirstAfterALine`); `macos/ProvenenciaTests/PVShowMoreRowTests.swift` (`PVShowMoreRowHostedTests`); `macos/ProvenenciaTests/PagedFoldTests.swift`; `macos/ProvenenciaTests/HostedWindow.swift` `hostInBorderlessWindow`, `descendant`, `eventually` | No fold test for the table; no layout timing |

**Precedent.** S16-07 ([#761](https://github.com/Jake-Robins-Studios/provenencia/pull/761)) and S15-30 ([#996](https://github.com/Jake-Robins-Studios/provenencia/pull/996)) fold the Person page's Sources rows: copy `PersonSourcesContent.rowFold` (`PagedFold(limit: 50, minimumHidden: 1)`), the `PVShowMoreRow(hidden:fold:focus:stop:revealed:revealedRow:expand:)` call and `.pvScrollsShowMoreReveals()` in `PersonSourcesSection`; copy `PVShowMoreRowHostedTests` for the hosted test. Do not copy `PersonSourcesContent`'s per-fold dictionaries: this table has one fold. The optional focus binding copies `PVRetryCallout`'s `retryFocused` (`macos/App/DesignSystem/Components/Callout/PVRetryCallout.swift`).

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | The fold counts citation runs (`CitationRun`) across the whole table, in table order (groups, then value runs, then runs), with `PVProvenanceRecordTable.fold` = `PagedFold(limit: 50, minimumHidden: 1)`; pages of `PagedFold.pageSize` (50) | Working rule; S16-07's Next adds names these numbers; runs are what the table draws as one unit | Counting records — splits a run, against the rule; a fold per owner group — a table of 30 owners would still draw 1,500 runs |
| D-2 | The fold is a pure function on the groups, `Group.folded(_:by:pages:)` (Codebase fit). It keeps every run whose table index is below `fold.shownCount(count:pages:)`; an owner group or value run is kept when it holds a kept run, or holds no runs and no run before it is hidden. A kept value run keeps its heading; a kept group keeps its owner line. It returns the groups, the hidden run count, and the position of the first hidden run | Pure and testable like `grouped(by:)`; reuses `PagedFold`'s rule instead of a second count; a shown prefix leaves every group, value and run index unchanged, so `followsLine` and `drawsRule` need no change | `PagedFold.shown(_:pages:)` over a flattened list rebuilt into groups — two passes and a rebuild for the same result; folding in `ProvenanceSheetHost` — the recipe would draw an unfolded table for any other caller |
| D-3 | A run is addressed by its position in the whole table, `RunPosition(group:value:run:)`. Focus and scroll use it: the table's focus enum is `PVProvenanceFocus` (`.citation(RunPosition)`, `.showMore`); each run's rows sit in one `VStack(alignment: .leading, spacing: 0)` with `.id(position)`; the first record of each run gets `.citation(position)` on its citation link | Record ids (`observationID`) are unique only within a run; positions are unique and match between the folded and the whole table (D-2) | Record id as focus value — a spanning row can hold one Observation twice; a focus value on every record — only a run's first record is ever claimed |
| D-4 | The table owns its fold state as `@State private var pages = 0` and its `@FocusState private var focus: PVProvenanceFocus?`. The state lives as long as the table: closing the sheet, a key change (the load area's loading state) or Read again starts over at 0 pages; a refresh that keeps the table keeps its pages, and `shownCount` clamps past the end | One fold, so a count is the state; the sheet's view tree already scopes it | `PagedFoldState<Key>` with a one-case key — a dictionary for one integer; state in `PVProvenanceSheet` — the table would need a binding and a focus binding from every caller |
| D-5 | `PVShowMoreRow` is the table's last child, after a `PVDivider()`, at the table's leading edge, with `stop: .showMore`, `revealed: firstRevealed.map(PVProvenanceFocus.citation)`, `revealedRow: firstRevealed.map(AnyHashable.init)`, `expand: { pages += 1 }`, padded vertically by `PVSpacing.space3` like a record row; the board's frames 1a and 2 may change only the padding | RF-4; the kit row as the Person page sections use it | Inside the last owner group or value run — RF-4 says never indented |
| D-6 | `PVProvenanceSheet` applies `.pvScrollsShowMoreReveals()` to the table inside its `ScrollView` | S15-30's Next adds; the provider outlives the row on the last page | The table applying it — the scroll view is the sheet's |
| D-7 | `PVProvenanceRecordRow` gains `citationFocus: CitationFocus? = nil` (Codebase fit); when set, the citation link is `.focused(citationFocus.binding, equals: citationFocus.value)`; when nil the row is as today, so the likeness viewer is unchanged | `PVRetryCallout`'s optional binding precedent; the row stays usable alone | Applying `.focused` to the row from the table — the row is not focusable, the link is |
| D-8 | No new string: the row reads `L10n.DesignSystem.showMoreRowLabel` (user, 2026-11-26) | RF-4, RF-7 | "Show N more citations" — a kit parameter for one caller |
| D-9 | The layout timing is a hosted test that prints, not a budget: it hosts `PVProvenanceSheet` at `.ready` in `hostInBorderlessWindow` with 300 and 1,200 formatted records, one record per run, all rows alike, and times `layoutSubtreeIfNeeded()` with `ContinuousClock`, best of 3. After the fold it asserts the scroll view's document height is the same at both counts. The Release figure comes from `-configuration Release ENABLE_TESTABILITY=YES` | The Check asks for figures, and a wall-clock budget fails on CI runners; equal heights prove the fold bounds the drawing; `CatalogListMergeTests` prints its timings the same way | A `#expect` on milliseconds — flaky; a manual Instruments run — not repeatable |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `PVProvenanceRecordTable.fold` *(new)*: `static let fold = PagedFold(limit: 50, minimumHidden: 1)` | constant | `PersonSourcesContent.rowFold` | Same value, declared where its content lives, as each content does |
| `PVProvenanceSheetContent.RunPosition` *(new)*: `struct RunPosition: Hashable { var group: Int; var value: Int; var run: Int }` | type | `PersonSourcesFocus` (ids, not positions) | Runs have no unique id (D-3) |
| `PVProvenanceSheetContent.Group.Folded` *(new)*: `struct Folded: Equatable { var groups: [Group]; var hidden: Int; var firstRevealed: RunPosition? }` | type | `PersonSourcesContent` fold outputs (`hiddenCount`, `firstRevealed(by:)`) | Those are per-section dictionaries over Sources; this is one fold over nested groups |
| `PVProvenanceSheetContent.Group.folded(_ groups: [Group], by fold: PagedFold, pages: Int) -> Folded` *(new, static, pure)* | func | `PagedFold.shown(_:pages:)`, `PagedFold.firstRevealed(_:pages:)` | Flat lists only; this walks groups → values → runs and calls `fold.shownCount(count:pages:)` once |
| `PVProvenanceFocus` *(new)*: `enum PVProvenanceFocus: Hashable { case citation(PVProvenanceSheetContent.RunPosition); case showMore }`, in `PVProvenanceRecordTable.swift` | type | `PersonSourcesFocus` | A `Features/` type; a recipe cannot name it |
| `PVProvenanceRecordRow.CitationFocus` *(new)*: `struct CitationFocus { let binding: FocusState<PVProvenanceFocus?>.Binding; let value: PVProvenanceFocus }`; `var citationFocus: CitationFocus? = nil` on the row | type + property | `PVRetryCallout.retryFocused` | That binds a `Bool`; the table's focus is an enum with one value per run |
| `macos/ProvenenciaTests/PVProvenanceSheetLayoutTests.swift` *(new)*: `PVProvenanceSheetLayoutTests` | test file | `PVShowMoreRowHostedTests` in `PVShowMoreRowTests.swift` | A sheet-sized fixture and a timing; the Show more tests are about the row |
| `#Preview("Folded, 120 runs")` *(new)* in `PVProvenanceSheet.swift` | preview | `#Preview("Thirty records")` | Thirty records never fold |

**Builds on.** `PagedFold` and `PVShowMoreRow` (S15-30), `FocusClaim` (through the row), `pvScrollsShowMoreReveals`, the run model of S15-21's `grouped(by:)`.
**Deletes.** None — nothing becomes dead: the table's draw loop changes, `followsLine` and `drawsRule` stay.
**Next adds.** S15-29 fills the same groups from the on-open read; the fold applies unchanged. S15-31 opens this sheet from Event and Place rows; those tables fold with no further change.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A table drawn past its first 50 runs (pages > 0) | `PVProvenanceRecordTable` | Resets: a new table (sheet reopened, key change) starts at 0 (D-4) · Missing: a refresh that drops runs clamps (`shownCount`), and `firstRevealed` is recomputed from the new groups · State: the row words the remainder |
| Keyboard focus on a run's citation link by position | `PVProvenanceRecordRow` citation link | Resets: the focus value names a position that exists in the folded groups the press revealed · Missing: a position past the end is never produced (`firstRevealed` is nil when nothing is hidden) · State: the link's existing focus ring |

### Scale

At the map's Scale (a value of up to 1,200 records; the Check measures 300 and 1,200): `Group.folded` walks every run once per table body, O(runs), no allocation beyond the kept prefix; `grouped(by:)` stays cached per revision by `conclusionContent` in `ProvenanceSheetHost`. The draw is bounded at 50 runs per page revealed. T-7 measures first layout at both counts, before (STEP-1) and after (STEP-5). No write, key or cache changes.

### Edges

- **Assumptions.** `followsLine` and `drawsRule` read indices within a group and value run; a kept prefix keeps them (T-5). `ForEach(groups)` is keyed by `Group.id` (`owner?.id ?? ""`), so the table enumerates groups by offset to build positions, as it already does for values.
- **Neighbors.** 50 runs: no row (T-4). 51 runs: "Show 1 more" (T-1). A 50th run of 6 records: all 6 show (T-2). The cut on a value boundary: the next value's heading waits for the press (T-3).
- **Removed inputs.** A refresh while the sheet is open that removes runs: the shown count clamps and `hidden` shrinks; a refresh that changes the Citation ids is a new key, and the table starts over (D-4). Focus on a run that the refresh removed falls to the system, as it does today.
- **Real data.** None — no table, seed or configuration drives the fold.
- **Untrusted size.** Runs are bounded at 50 per page. A single run is not bounded: a catalog whose 1,200 Citations render the same full citation draws 1,200 rows in one run. Accepted (user, 2026-11-26), §11.

### Schema

None — no catalog change.

### Go core

None — Swift only.

### FFI

None — no RPC changes.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Record table | Recipe, Extend | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceRecordTable.swift` | Draws `Group.folded(groups, by: Self.fold, pages: pages).groups`; each run's rows in a `VStack` with `.id(position)`; the first record's `citationFocus`; ends with the rule and the Show more row when `hidden > 0` |
| Provenance sheet | Recipe, Ship | `…/ProvenanceSheet/PVProvenanceSheet.swift` | `.pvScrollsShowMoreReveals()` on the table in its `ScrollView` (D-6) |
| Record row | Recipe, Ship | `…/ProvenanceSheet/PVProvenanceRecordRow.swift` | `citationFocus` (D-7); nothing else changes |
| Show more row | Component, Ship | `macos/App/DesignSystem/Components/ShowMoreRow/PVShowMoreRow.swift` | As the Person page sections use it; unchanged |
| Rule before the row | Component, Ship | `PVDivider` | A normal row rule |

**The frames in words** (S15-D17 § 5, until the board is agreed). Frame 1a: the table scrolled to its foot shows runs 48 – 50, a rule, then "Show 50 more" at the leading edge under the Read as column. Frame 2: after Return, runs 51 onward follow run 50 with no change above, the first revealed citation link carries its focus ring and is scrolled into view, and the row now ends run 100. Frame 3: the last smaller page reads "Show 20 more" and the table ends with no row after it. Frames 4 and 5: a value heading or owner line past the cut draws only when its first run is revealed; the heading over a split value is not repeated. Frame 6: 12 runs, no row. Wide (frame 1b): the same at 1280pt.

States: a table of 50 runs or fewer, no row; loading and failed as S15-21 (the table is not drawn). Accessibility: the row is the button "Show 50 more"; Tab order is the shown rows' controls, the row, then Done; a keyboard press claims `.citation(firstRevealed)`.

### Strings

None — no new or changed copy (D-8).

## 7. Steps

**STEP-1 — Measure today's first layout**
Files: `macos/ProvenenciaTests/PVProvenanceSheetLayoutTests.swift` *(new)*. Skill: `add-swift-test`.
Do: add `@Suite(.serialized, .hostedWindows) @MainActor struct PVProvenanceSheetLayoutTests` with `firstLayoutAt300And1200Records` per D-9 (records built with `PVProvenancePreviewData.record` and a `CatalogRenderedCitation` with an italic run and a distinct `groupKey` per record, so each record is its own run). It prints `provenance sheet first layout at <n> records: <ms> ms` for each count. Run it in Debug and with `-configuration Release ENABLE_TESTABILITY=YES`.
Check: `xcodebuild test … -only-testing:ProvenenciaTests/PVProvenanceSheetLayoutTests` passes in both configurations; the four "before" figures are noted for the PR description.

**STEP-2 — The fold rule**
Files: `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheetContent.swift`, `macos/ProvenenciaTests/ProvenanceSheetTests.swift`. Skill: `add-swift-test`.
Do: add `RunPosition`, `Group.Folded` and `Group.folded(_:by:pages:)` per D-2 and Codebase fit; add T-1 – T-6.
Check: `-only-testing:ProvenenciaTests/ProvenanceSheetTests` passes.

**STEP-3 — The table folds**
Files: `…/ProvenanceSheet/PVProvenanceRecordTable.swift`, `…/ProvenanceSheet/PVProvenanceRecordRow.swift`. Skill: `add-ui-component`.
Do: add `PVProvenanceFocus`, `PVProvenanceRecordTable.fold`, the table's `pages` and `focus` (D-4); draw the folded groups, enumerating groups by offset; wrap each run's rows in a `VStack` with `.id(position)`; give the first record of each run `citationFocus` (D-3, D-7); end with the rule and `PVShowMoreRow` (D-5).
Check: the app builds with no Swift warning; the `#Preview("Formatted, fallback and a same-citation run")` draws as before; `ProvenanceSheetTests` passes.

**STEP-4 — The sheet scrolls a keyboard reveal**
Files: `…/ProvenanceSheet/PVProvenanceSheet.swift`.
Do: apply `.pvScrollsShowMoreReveals()` (D-6); add `#Preview("Folded, 120 runs")` with 120 records in 120 runs.
Check: the preview shows 50 runs and "Show 50 more"; pressing it in the preview's live mode shows 100 runs and "Show 20 more".

**STEP-5 — Measure after the fold**
Files: `macos/ProvenenciaTests/PVProvenanceSheetLayoutTests.swift` *(new)* (written in STEP-1).
Do: add the equal-height `#expect` (D-9); rerun in Debug and Release.
Check: the test passes in both; the four "after" figures are noted.

**STEP-6 — Version**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj` (`MARKETING_VERSION`).
Do: bump per the header.
Check: the three agree.

**STEP-7 — Docs**
Files: `docs/deployment-plan/spike-15/completed.md`, `docs/deployment-plan/spike-15/deployment-plan.md` (map row), this plan (status), `docs/deployment-plan/spike-15/design/S15-D17-provenance-table-fold.md` → `design/archive/`, `docs/deployment-plan/spike-15/design/README.md`, `macos/App/DesignSystem/README.md` (the ProvenanceSheet row: the table folds 50 citation runs at a time with `PagedFold` and `PVShowMoreRow`), `docs/macos-client-patterns.md` ("Detail pages share their rows": the sheet's table folds), `docs/deployment-plan/spike-15/provenance-loading.md` ("Cap": the cap shipped in S15-27, with the after figures).
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-27-provenance-table-fold.md` reports no errors; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Fold the provenance table fifty citations at a time."). No WIP commits.

## 8. Tests

Records in T-1 – T-6 are built with `PVProvenancePreviewData.record`; a run of n records is `CitationRun(key: "full:<i>", records: …)`.

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `ProvenanceSheetTests.swift` `foldShowsFiftyRunsThenAPageAtATime` *(new)* | One group, one value, 120 one-record runs: pages 0 → 50 runs, hidden 70, `firstRevealed` (0, 0, 50); pages 1 → 100, hidden 20; pages 2 → 120, hidden 0, nil. 51 runs, pages 0 → 50, hidden 1 | AC-1.1, AC-1.4, D-1, D-2 |
| T-2 | Swift | `foldNeverSplitsARun` *(new)* | 60 runs, the 50th (index 49) of 6 records: pages 0 → 50 runs, 55 records, hidden 10, `firstRevealed` (0, 0, 50) | AC-1.3 |
| T-3 | Swift | `foldKeepsLinesOverShownRunsOnly` *(new)* | Owner A 50 runs, owner B 3: pages 0 → one group (A), hidden 3, `firstRevealed` (1, 0, 0); pages 1 → both. One owner, value 1 with 60 runs and value 2 with 5, both with headings: pages 0 → one value run (heading 1, 50 runs); pages 1 → two value runs (value 1's 60 runs, value 2's heading and 5) | AC-2.1, AC-2.2 |
| T-4 | Swift | `foldLeavesASmallTableWhole` *(new)* | 50 runs → `groups` equals the input, hidden 0, nil; no groups → empty, hidden 0; an owner group with no values before a group of 60 runs → kept at pages 0; one after the cut → dropped until the last page | AC-1.2, AC-2.3 |
| T-5 | Swift | `foldKeepsEveryShownPosition` *(new)* | Three owners with mixed value runs, 130 runs: for pages 0 – 3, every run in the folded groups has the same (group, value, run) and records as in the input, and `firstRevealed` names the first input run not shown | D-2, D-3 |
| T-6 | Swift | `foldClampsPastTheEnd` *(new)* | 60 runs, pages 9 → 60 runs, hidden 0, nil | D-4 |
| T-7 | Swift (hosted) | `PVProvenanceSheetLayoutTests.swift` `firstLayoutAt300And1200Records` *(new)* | 300 and 1,200 one-record runs at `.ready`: prints first-layout ms (best of 3); the scroll view's document height is equal at both | AC-1.5, D-9 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `ProvenanceSheetTests` (the table's rule tests), `PVShowMoreRowTests`, `ConclusionPictureViewer` previews (the row's new parameter).

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
- [ ] Domain doc updated if a rule in docs/*.md changed: docs/macos-client-patterns.md ("Detail pages share their rows"), macos/App/DesignSystem/README.md (ProvenanceSheet row), provenance-loading.md ("Cap")
- [ ] PR description: what shipped, AC evidence, the before and after first-layout figures (Debug and Release, 300 and 1,200), deviations, manual check
```

## 10. Manual check

1. Run the app in Release from Xcode on a project with a Person whose Vitals value has more than 50 records (a crafted test project, or a Place-derived row on a large catalog). Open the value's provenance sheet. See 50 runs and "Show 50 more" at the table's foot; the summary counts every record (AC-1.1, AC-1.6).
2. Tab through the last rows: focus reaches "Show 50 more", then Done (AC-3.1). Press Return: the next page draws, focus is on the first revealed citation link and it is in view (AC-3.2).
3. Click Show more with the pointer: the page draws, focus and scroll stay (AC-3.3). Press until the row goes (AC-1.4).
4. Close the sheet, open it again: 50 runs and the row (AC-3.4).
5. Open a sheet with owner lines (a derived Birth date) and one with value headings past 50 runs, if the project has them; check AC-2.1 and AC-2.2 against frames 4 and 5. Otherwise T-3 is the evidence.
6. Repeat step 1 at Wide (window over 1600pt): the same, at 1280pt (RF-W1).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| One citation run holds most of the records (crafted catalog, or many Citations rendering one full citation), so the first page still draws them all | Accepted (user, 2026-11-26): a run is never split. The sheet opens on a click, never on page load |
| `-configuration Release ENABLE_TESTABILITY=YES` does not build the test target | Stop condition below |
| A table that loads again (Read again, a key change) forgets the pages revealed | Accepted by D-4: a reload is a new read |

**Stop and report if:**

- `PVProvenanceRecordTable` no longer draws `Group.ValueGroup.citations` runs, or `followsLine` / `drawsRule` changed shape.
- A row inside a run needs focus or scroll by record (a test or the board asks to land on a record other than the run's first).
- The Release test build fails; report the error and the Debug figures, and do not change build settings in the project.
- The board places the Show more row anywhere but the table's foot, or asks for a new string or a fold inside a run.
- T-7's document heights differ after the fold.

## 12. Open questions

None.

## 13. PR

**Title:** S15-27 — The provenance table folds a page at a time
**Body:** objective in one sentence; what shipped against each US; AC evidence; the before and after first-layout figures; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-27-provenance-table-fold.md`.
