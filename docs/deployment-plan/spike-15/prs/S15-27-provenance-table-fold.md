# S15-27 — The provenance table folds a page at a time

**Status:** Landed in [#1006](https://github.com/Jake-Robins-Studios/provenencia/pull/1006) (2026-11-26)
**Spike / slice:** Spike 15 · Slice 8 — Provenance loading
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D17](../design/archive/S15-D17-provenance-table-fold.md), board agreed 2026-11-26
**Board:** agreed 2026-11-26 (user) — the [Person page board](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ), page *Vitals*, turn 21 "S15-D17 · Provenance sheet — the record table's fold": frames 21a – 21g, 21i, 21j and the decision notes Kit, RF-4, RF-3, RF-6, Scroll area. The frames are live (press Show more). No frame draws owner groups past the fold; T-3 holds AC-2.1. **§ 6 macOS** says where the app departs from a board note
**Depends on:** S15-30 (landed [#996](https://github.com/Jake-Robins-Studios/provenencia/pull/996)), S15-21 (landed [#930](https://github.com/Jake-Robins-Studios/provenencia/pull/930)), S15-D17
**Blocks:** —
**Branch:** `s15-27-provenance-table-fold`
**Version bump:** patch, 0.48.1 (today's `VERSION`) → **0.48.2** (or the next patch after `main`'s `VERSION` when you rebase): a long provenance table no longer freezes the sheet, a fix to an existing view ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/design-system-layers.mdc` (a recipe names no `Features/` type)
**Context:** map scope entry S15-27 ([`../deployment-plan.md`](../deployment-plan.md)); working rule "The provenance table folds a page at a time"; [`../provenance-loading.md`](../provenance-loading.md) "Cap the records a provenance table draws"; [`docs/design-system-layers.md`](../../../design-system-layers.md); [`docs/macos-client-patterns.md`](../../../macos-client-patterns.md) "One sectioned detail page" (the paged fold) and "Detail pages share their rows"
**Host:** macOS with Xcode. Tests: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS'`, narrowed with `-only-testing:ProvenenciaTests/<Suite>` where a Step says so. The implementer runs the manual check in §10.
**Planned:** 2026-11-26 against `main` @ `c1035450b`
**Review:** [`S15-27-provenance-table-fold.review.md`](S15-27-provenance-table-fold.review.md) — Fits with changes / Ready with changes, one round; every finding Fixed or Declined

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

A value with hundreds or thousands of records opens its provenance sheet quickly. The sheet's record table draws its first 50 citation runs (a run is the records whose full citations read the same, or one record alone) and ends with the kit's "Show 50 more" row; each press reveals the next 50, never splitting a run. A run is what the working rule calls a citation group; the plan says run, after the type `CitationRun`. Today the table draws every record at once on the main thread: 1,200 records took 8.7 – 12.2 s to lay out in a Debug build ([`provenance-loading.md`](../provenance-loading.md) "Cap").

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
| Kit fold | `macos/App/Platform/PagedFold.swift` `PagedFold`, `PagedFoldState`; `macos/App/DesignSystem/Components/ShowMoreRow/PVShowMoreRow.swift` `PVShowMoreRow`, `pvScrollsShowMoreReveals()` | Landed in S15-30; used by the Person page's sections |
| Focus claim | `macos/App/Platform/FocusClaim.swift` `FocusClaim.claim` | Used by `PVShowMoreRow.press` |
| Previews | `PVProvenanceRecordTable.swift` `PVProvenancePreviewData`; `PVProvenanceSheet.swift` `#Preview("Thirty records")` | No preview past 50 runs; `content(groups:summary:)` takes `summary: String`, so a caller cannot leave the summary out, though `PVProvenanceSheetContent.summary` is `String?` |
| Tests | `macos/ProvenenciaTests/ProvenanceSheetTests.swift` (`groupedGathersByEngineKeyWithinARun`, `ruleFallsBeforeEachRunButTheFirstAfterALine`); `macos/ProvenenciaTests/PVShowMoreRowTests.swift` (pure tests only: `pressMovesOnlyFromTheRow`, `labelWordsThePage`); `macos/ProvenenciaTests/PVScrollMemoryHostedTests.swift` (a `.serialized, .hostedWindows` suite that reads a hosted scroll view's `documentView`); `macos/ProvenenciaTests/PagedFoldTests.swift`; `macos/ProvenenciaTests/HostedWindow.swift` `hostInBorderlessWindow`, `descendant`, `eventually` | No fold test for the table; no layout timing |

**Precedent.** S16-07 ([#761](https://github.com/Jake-Robins-Studios/provenencia/pull/761)) and S15-30 ([#996](https://github.com/Jake-Robins-Studios/provenencia/pull/996)) fold the Person page's Sources rows (`PersonSourcesContent`, `PersonSourcesSection`): copy the `PVShowMoreRow` call and the reveal provider; do not copy `PersonSourcesContent`'s per-fold dictionaries, since this table has one fold. `CircularLinkDiagram` (`macos/App/Features/Conclusions/CircularLinkDiagram/CircularLinkDiagram.swift`) applies an optional `PVFieldFocus` to a button per item: copy that for the citation link.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | The fold counts citation runs (`CitationRun`) across the whole table, in table order (groups, then value runs, then runs), with `PVProvenanceRecordTable.fold` = `PagedFold(limit: 50, minimumHidden: 1)`; pages of `PagedFold.pageSize` (50) | Working rule; S16-07's Next adds names these numbers; runs are what the table draws as one unit | Counting records — splits a run, against the rule; a fold per owner group — a table of 30 owners would still draw 1,500 runs |
| D-2 | The fold is a pure function on the groups, `PVProvenanceSheetContent.folded(_:by:pages:)` (Codebase fit), beside `grouped(by:)`. It keeps every run whose table index is below `fold.shownCount(count:pages:)`; an owner group or value run is kept when it holds a kept run, or holds no runs and no run before it is hidden. A kept value run keeps its heading; a kept group keeps its owner line. It returns the groups, the hidden run count, and the position of the first hidden run | Pure and testable like `grouped(by:)`; reuses `PagedFold`'s rule instead of a second count; a shown prefix leaves every group, value and run index unchanged, so `followsLine` and `drawsRule` need no change | `PagedFold.shown(_:pages:)` over a flattened list rebuilt into groups — two passes and a rebuild for the same result; folding in `ProvenanceSheetHost` — the recipe would draw an unfolded table for any other caller |
| D-3 | A run is addressed by its position in the whole table, `RunPosition(group:value:run:)`. Focus and scroll use it: the table's focus enum is `PVProvenanceFocus` (`.citation(RunPosition)`, `.showMore`); the table's loops are `ForEach(Array(folded.groups.enumerated()), id: \.offset)` for groups (group ids can repeat), the existing `id: \.offset` for values and `id: \.element.key` for runs; a run's rule stays before it, outside the run, and the run's rows sit in one `VStack(alignment: .leading, spacing: 0)` with `.id(position)`; the first record of each run gets `PVFieldFocus($focus, equals: .citation(position))` on its citation link | Record ids (`observationID`) are unique only within a run; positions are unique and match between the folded and the whole table (D-2) | Record id as focus value — a spanning row can hold one Observation twice; a focus value on every record — only a run's first record is ever claimed |
| D-4 | The table owns its fold state as `@State private var folds = PagedFoldState<PVProvenanceRecordTable.Fold>()` (a one-case `enum Fold: Hashable { case runs }`, read with `folds.pages(.runs)`) and its `@FocusState private var focus: PVProvenanceFocus?`. The state lives as long as the table: closing the sheet, a key change (the load area's loading state) or Read again starts over at 0 pages; a refresh that keeps the table keeps its pages, and `shownCount` clamps past the end | Every fold holds its pages in a `PagedFoldState` (`macos-client-patterns.md` "One sectioned detail page"), the single-fold `ReconciledValueRow` included; the sheet's view tree scopes it | A bare `Int` — a second fold-state shape; state in `PVProvenanceSheet` — the table would need a binding and a focus binding from every caller |
| D-5 | `PVShowMoreRow` is the table's last child, after a `PVDivider()`, at the table's leading edge, with `stop: .showMore`, `revealed: firstRevealed.map(PVProvenanceFocus.citation)`, `revealedRow: firstRevealed.map(AnyHashable.init)`, `expand: { folds.revealPage(.runs) }`, padded vertically by `PVSpacing.space3` like a record row, with no horizontal padding (its leading edge is the table's), as board frame 21a places it | RF-4; the kit row as the Person page sections use it | Inside the last owner group or value run — RF-4 says never indented |
| D-6 | `PVProvenanceSheet` applies `.pvScrollsShowMoreReveals()` to the table inside its `ScrollView`, after its `.padding(.trailing, PVProvenanceColumns.scrollBarInset)` | S15-30's Next adds; the provider outlives the row on the last page | The table applying it — the scroll view is the sheet's |
| D-7 | `PVProvenanceRecordRow` gains `var citationFocus: PVFieldFocus? = nil`; when set, the citation link is drawn through `citationFocus.apply(AnyView(link))`, as `CircularLinkDiagram` applies its node handles; when nil the row is as today, so the likeness viewer is unchanged | `PVFieldFocus` is the kit's one host-focus handle; the row names no table type | A row-specific focus struct — a second handle; `.focused` on the row from the table — the row is not focusable, the link is |
| D-8 | No new string: the row reads `L10n.DesignSystem.showMoreRowLabel` (user, 2026-11-26) | RF-4, RF-7 | "Show N more citations" — a kit parameter for one caller |
| D-9 | The layout timing is a hosted test that prints, not a budget. Each of 3 runs per count builds a fresh `hostInBorderlessWindow(_, windowSize: CGSize(width: 880, height: 900))` of `PVProvenanceSheet` at `.ready` (`content: PVProvenancePreviewData.content(groups: [Group(owner: nil, records: records)], summary: nil)`, `idPrefix: "timing"`, `open: { _, _ in }`), where each record has `rendered` set to a `CatalogRenderedCitation` with one italic run and its own `groupKey`, all rows alike; it times the host's creation plus one `layoutSubtreeIfNeeded()` and keeps the best, through the shared timing helper (Codebase fit). After the fold it reads the scroll view's `documentView` height right after that layout (`add-swift-test`: lay out once, assert at once) and asserts it is greater than 0 and the same at both counts. The figures are Debug only: the test target builds only in Debug, because `FakeStore`, which test files across the target use, is `#if DEBUG` by design | The Check asks for figures, and a wall-clock budget fails on CI runners; equal heights prove the fold bounds the drawing; `CatalogListMergeTests` prints its timings the same way | A `#expect` on milliseconds — flaky; a manual Instruments run — not repeatable; a Release test run — the test target does not compile in Release (`FakeStore` is Debug-only) |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `PVProvenanceRecordTable.fold` *(new)*: `nonisolated static let fold = PagedFold(limit: 50, minimumHidden: 1)`; `PVProvenanceRecordTable.Fold` *(new)*: `enum Fold: Hashable { case runs }` | constant + key | `PersonSourcesContent.rowFold`, `PersonSourcesContent.Fold` | Same value and key shape, declared where the table lives, as each content does |
| `PVProvenanceSheetContent.RunPosition` *(new)*: `struct RunPosition: Hashable { var group: Int; var value: Int; var run: Int }` | type | `CitationRun.key`; `PersonSourcesFocus` (ids) | A run's `key` is unique only within its value run; the same Citation can recur under another value or owner (D-3) |
| `PVProvenanceSheetContent.Folded` *(new)*: `struct Folded: Equatable { var groups: [Group]; var hidden: Int; var firstRevealed: RunPosition? }` | type | `PersonSourcesContent` fold outputs (`hiddenCount`, `firstRevealed(by:)`) | Those are per-section dictionaries over Sources; this is one fold over nested groups |
| `PVProvenanceSheetContent.folded(_ groups: [Group], by fold: PagedFold, pages: Int) -> Folded` *(new, `nonisolated static`, pure)* | func | `PagedFold.shown(_:pages:)`, `PagedFold.firstRevealed(_:pages:)` | Flat lists only; this walks groups → values → runs and calls `fold.shownCount(count:pages:)` once |
| `PVProvenanceFocus` *(new)*: `enum PVProvenanceFocus: Hashable { case citation(PVProvenanceSheetContent.RunPosition); case showMore }`, in `PVProvenanceRecordTable.swift` | type | `PersonSourcesFocus` | A `Features/` type; a recipe cannot name it |
| `PVProvenanceRecordRow.citationFocus` *(new)*: `var citationFocus: PVFieldFocus? = nil` | property | `PVFieldFocus`, `CircularLinkDiagram.focus` | Reused: the kit's host-focus handle (D-7) |
| `macos/ProvenenciaTests/Timing.swift` *(new)*: `func milliseconds(_ duration: Duration) -> Double` and `func bestOfMilliseconds(runs: Int, _ run: () -> Void) -> Double` | test helper | `CatalogListMergeTests.milliseconds(_:)`, `bestOfMilliseconds(_:runs:expected:_:)` (private) | Moved, not copied: `CatalogListMergeTests` calls the shared `milliseconds(_:)` and keeps its own private best-of loop, which copies its input before each run outside the timed span; the shared `bestOfMilliseconds` would time that copy |
| `macos/ProvenenciaTests/PVProvenanceSheetLayoutTests.swift` *(new)*: `PVProvenanceSheetLayoutTests` | test file | `PVScrollMemoryHostedTests` (hosting and the `documentView` read) | A sheet-sized fixture and a timing; that suite is about scroll memory |
| `#Preview("Folded, 120 runs")` *(new)* in `PVProvenanceSheet.swift` | preview | `#Preview("Thirty records")` | Thirty records never fold |

**Builds on.** `PagedFold` and `PVShowMoreRow` (S15-30), `FocusClaim` (through the row), `pvScrollsShowMoreReveals`, the run model of S15-21's `grouped(by:)`.
**Deletes.** `CatalogListMergeTests`'s private `milliseconds(_:)` (moved to `Timing.swift`). Nothing else becomes dead: the table's draw loop changes, `followsLine` and `drawsRule` stay.
**Next adds.** S15-29 fills the same groups from the on-open read; the fold applies unchanged. S15-31 opens this sheet from Event and Place rows; those tables fold with no further change.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A table drawn past its first 50 runs (pages > 0) | `PVProvenanceRecordTable` | Resets: a new table (sheet reopened, key change) starts at 0 (D-4) · Missing: a refresh that drops runs clamps (`shownCount`), and `firstRevealed` is recomputed from the new groups · State: the row words the remainder |
| Keyboard focus on a run's citation link by position | `PVProvenanceRecordRow` citation link | Resets: the focus value names a position that exists in the folded groups the press revealed · Missing: a position past the end is never produced (`firstRevealed` is nil when nothing is hidden) · State: the link's existing focus ring |

### Scale

At the map's Scale (a value of up to 1,200 records; the Check measures 300 and 1,200): `PVProvenanceSheetContent.folded` walks every run once per table body, O(runs), no allocation beyond the kept prefix; `grouped(by:)` stays cached per revision by `conclusionContent` in `ProvenanceSheetHost`. The draw is bounded at 50 runs per page revealed. T-7 measures first layout at both counts, before (STEP-1) and after (STEP-5). No write, key or cache changes.

### Edges

- **Assumptions.** `followsLine` and `drawsRule` read indices within a group and value run; a kept prefix keeps them (T-5). `ForEach(groups)` is keyed by `Group.id` (`owner?.id ?? ""`), so the table enumerates groups by offset to build positions, as it already does for values.
- **Neighbors.** 50 runs: no row (T-4). 51 runs: "Show 1 more" (T-1). A 50th run of 6 records: all 6 show (T-2). The cut on a value boundary: the next value's heading waits for the press (T-3).
- **Removed inputs.** A refresh while the sheet is open that removes runs: the shown count clamps and `hidden` shrinks; a refresh that changes the Citation ids is a new key, and the table starts over (D-4). Focus on a run that the refresh removed falls to the system, as it does today. A revealed run that opens a new value or owner scrolls into view with no anchor, so its heading can sit just above the visible area; accepted, as the Person page sections scroll the same way.
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
| Record table | Recipe, Extend | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceRecordTable.swift` | Draws `PVProvenanceSheetContent.folded(groups, by: Self.fold, pages: folds.pages(.runs)).groups`; each run's rows in a `VStack` with `.id(position)`; the first record's `citationFocus`; ends with the rule and the Show more row when `hidden > 0` |
| Provenance sheet | Recipe, Ship | `…/ProvenanceSheet/PVProvenanceSheet.swift` | `.pvScrollsShowMoreReveals()` on the table in its `ScrollView` (D-6) |
| Record row | Recipe, Extend | `…/ProvenanceSheet/PVProvenanceRecordRow.swift` | Gains an optional focus handle on its citation link (D-7); no visible change |
| Show more row | Component, Ship | `macos/App/DesignSystem/Components/ShowMoreRow/PVShowMoreRow.swift` | As the Person page sections use it; unchanged |
| Rule before the row | Component, Ship | `PVDivider` | A normal row rule |

**The board (turn 21).** 21a/21b: 1,200 records in 430 runs, scrolled to the foot: runs 48 – 50 (the 50th a household of three, no rules inside), a normal row rule, then "Show 50 more" at the table's leading edge under Read as; the summary counts every record; Wide the same at 1280pt. 21c: after Return, runs 51 onward below run 50, focus ring on run 51's citation link, the row after run 100. 21d/21e: 120 runs, after one press "Show 20 more", after the next no row. 21f/21g: the fold inside the first of two values, the second value's heading drawn only after the press, no repeated heading. 21i: 12 runs, no row. 21j: the spoken label and Tab order (last row's controls → Show more → Done).

**Board notes the app does not copy.** *Kit:* the web kit has no `PVShowMoreRow`, so the board draws a ghost small Button with a chevron; the app uses `PVShowMoreRow` as it is. *RF-4:* the board pads the row 8pt "as a record row"; the app uses the record row's own padding, `PVSpacing.space3` (D-5). *RF-6:* the board scrolls the revealed row to the top of the scroll area; the app uses the kit's default reveal, which scrolls it into view, as Family and Sources do (D-6). *Scroll area:* the board's 498pt is its pane less chrome; the app keeps `recordsMaxHeight` (560).

States: a table of 50 runs or fewer, no row; loading and failed as S15-21 (the table is not drawn). Accessibility: the row is the button "Show 50 more"; Tab order is the shown rows' controls, the row, then Done; a keyboard press claims `.citation(firstRevealed)`.

### Strings

None — no new or changed copy (D-8).

## 7. Steps

**STEP-1 — Measure today's first layout**
Files: `macos/ProvenenciaTests/Timing.swift` *(new)*, `macos/ProvenenciaTests/CatalogListMergeTests.swift`, `macos/ProvenenciaTests/PVProvenanceSheetLayoutTests.swift` *(new)*, `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceRecordTable.swift` (`PVProvenancePreviewData.content`). Skill: `add-swift-test`.
Do: move `milliseconds(_:)` into `Timing.swift` beside a generic `bestOfMilliseconds(runs:_:)` (Codebase fit), and point `CatalogListMergeTests` at it. Add `@Suite(.serialized, .hostedWindows) @MainActor struct PVProvenanceSheetLayoutTests` with `firstLayoutAt300And1200Records` per D-9 (records built with `PVProvenancePreviewData.record`). It prints `provenance sheet first layout at <n> records: <ms> ms` for each count. Change `PVProvenancePreviewData.content(groups:summary:)` in `PVProvenanceRecordTable.swift` from `summary: String` to `summary: String?`, so D-9's `summary: nil` compiles; the sheet's previews still pass strings. In `CatalogListMergeTests`, `Self.milliseconds(…)` becomes `milliseconds(…)`. Keep the last timed run's host in a `var` outside the timed closure and read the document height from it. Print `provenance sheet document height at <n> records: <pt> pt` beside each time; before the fold the two heights differ, which shows the read sees the rows. Run it in Debug.
Check: `-only-testing:ProvenenciaTests/PVProvenanceSheetLayoutTests` and `-only-testing:ProvenenciaTests/CatalogListMergeTests` pass in Debug; the two "before" figures are noted for the PR description.

**STEP-2 — The fold rule**
Files: `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheetContent.swift`, `macos/ProvenenciaTests/ProvenanceSheetTests.swift`. Skill: `add-swift-test`.
Do: add `RunPosition`, `Folded` and `folded(_:by:pages:)` on `PVProvenanceSheetContent` per D-2 and Codebase fit; add T-1 – T-6.
Check: `-only-testing:ProvenenciaTests/ProvenanceSheetTests` passes.

**STEP-3 — The table folds**
Files: `…/ProvenanceSheet/PVProvenanceRecordTable.swift`, `…/ProvenanceSheet/PVProvenanceRecordRow.swift`. Skill: `add-ui-component`.
Do: add `PVProvenanceFocus`, `PVProvenanceRecordTable.fold` and `Fold`, the table's `folds` and `focus` (D-4); draw the folded groups with D-3's loops; give the first record of each run its `citationFocus` (D-3, D-7); end with the rule and `PVShowMoreRow` (D-5).
Check: the app builds with no Swift warning; the `#Preview("Formatted, fallback and a same-citation run")` draws as before; `ProvenanceSheetTests` passes. The press, focus and Tab ACs (AC-1.4's presses, AC-3.1 – AC-3.4) are checked by hand in §10: the kit's press rule is covered by `PVShowMoreRowTests`, and tests do not synthesize key events (`add-swift-test`).

**STEP-4 — The sheet scrolls a keyboard reveal**
Files: `…/ProvenanceSheet/PVProvenanceSheet.swift`.
Do: apply `.pvScrollsShowMoreReveals()` (D-6); add `#Preview("Folded, 120 runs")` with 120 records in 120 runs.
Check: the preview shows 50 runs and "Show 50 more"; pressing it in the preview's live mode shows 100 runs and "Show 20 more".

**STEP-5 — Measure after the fold**
Files: `macos/ProvenenciaTests/PVProvenanceSheetLayoutTests.swift` *(new)* (written in STEP-1).
Do: add the `#expect`s of D-9 (height greater than 0, equal at both counts); rerun in Debug.
Check: the test passes in Debug; the two "after" figures are noted.

**STEP-6 — Version**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj` (`MARKETING_VERSION`).
Do: bump per the header.
Check: the three agree.

**STEP-7 — Docs**
Files: `docs/deployment-plan/spike-15/completed.md`, `docs/deployment-plan/spike-15/deployment-plan.md` (map row), this plan (status), `docs/deployment-plan/spike-15/design/S15-D17-provenance-table-fold.md` → `design/archive/`, `docs/deployment-plan/spike-15/design/README.md`, `macos/App/DesignSystem/README.md` (the ProvenanceSheet row: the table folds 50 citation runs at a time with `PagedFold` and `PVShowMoreRow`), `docs/macos-client-patterns.md` ("Detail pages share their rows": the sheet's table folds), `docs/deployment-plan/spike-15/provenance-loading.md`.
Do: per the Definition of done. The archive move rewrites the brief's links: this plan's **Brief** line, the map's S15-27 row and design-track row, and the brief's own relative links (one level deeper). In `provenance-loading.md`, replace the body of "Cap the records a provenance table draws" with three lines: shipped in S15-27 as a fold of 50 citation groups with the kit's Show more row, the Debug before and after figures, and the accepted single-group case; drop its "Show all", `LazyVStack` and "the Why needs the same cap" text, and in the status line name S15-D17 for the cap. The working rule's wording ("citation groups") stays.
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
| T-7 | Swift (hosted) | `PVProvenanceSheetLayoutTests.swift` `firstLayoutAt300And1200Records` *(new)* | 300 and 1,200 one-record runs at `.ready`: prints first-layout ms (best of 3); the scroll view's document height is greater than 0 and equal at both | AC-1.5, D-9 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `ProvenanceSheetTests` (the table's rule tests), `PVShowMoreRowTests`, `CatalogListMergeTests` (the moved helper), `ConclusionPictureViewer` previews (the row's new parameter).

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
- [ ] PR description: what shipped, AC evidence, the before and after first-layout figures (Debug, 300 and 1,200), deviations, manual check
```

## 10. Manual check

No fixture holds a value of more than 50 records, so the press, focus and Tab checks run in the `#Preview("Folded, 120 runs")` canvas in live mode, and in the app when the reviewer's project has such a value. AC-2.1 – AC-2.3 rest on T-3 and T-4.

1. Open `#Preview("Folded, 120 runs")` live. See 50 runs and "Show 50 more" at the table's foot (AC-1.1).
2. Tab through the last rows: focus reaches "Show 50 more", then Done (AC-3.1). Press Return: the next page draws, focus is on the first revealed citation link and it is in view (AC-3.2).
3. Click Show more with the pointer: the page draws, focus and scroll stay (AC-3.3). Press until the row goes: "Show 20 more", then none (AC-1.4).
4. In the app (Run, Debug), open any value's provenance sheet: a value of 50 records or fewer draws as before (AC-1.2). If the project has a value of more than 50 records, open it: 50 runs, the row, the summary counting every record (AC-1.6); close and open it again: 50 runs (AC-3.4).
5. Repeat step 4 at Wide (window over 1600pt): the same, at 1280pt (RF-W1).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| One citation run holds most of the records (crafted catalog, or many Citations rendering one full citation), so the first page still draws them all | Accepted (user, 2026-11-26): a run is never split. The sheet opens on a click, never on page load |
| A table that loads again (Read again, a key change) forgets the pages revealed | Accepted by D-4: a reload is a new read |

**Stop and report if:**

- `PVProvenanceRecordTable` no longer draws `Group.ValueGroup.citations` runs, or `followsLine` / `drawsRule` changed shape.
- A row inside a run needs focus or scroll by record (a test or the board asks to land on a record other than the run's first).
- The board places the Show more row anywhere but the table's foot, or asks for a new string or a fold inside a run.
- T-7's document heights differ after the fold.

## 12. Open questions

None.

## 13. PR

**Title:** S15-27 — The provenance table folds a page at a time
**Body:** objective in one sentence; what shipped against each US; AC evidence; the before and after first-layout figures; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-27-provenance-table-fold.md`.

## Landed

- The manual check (section 10) was not run by the implementer: the press, focus and Tab ACs (AC-1.4's presses, AC-3.1 – AC-3.4) and AC-1.6 are unchecked by hand.
- First layout, Debug, best of 3: 300 records 1558 ms and a 24,900 pt document before, 271 ms and 4,185 pt after; 1,200 records 6691 ms and 99,600 pt before, 268 ms and 4,185 pt after.
