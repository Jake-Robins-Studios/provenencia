# S15-27 — review log

Plan: [`S15-27-provenance-table-fold.md`](S15-27-provenance-table-fold.md). Brief: [S15-D17](../design/archive/S15-D17-provenance-table-fold.md), reviewed with the plan.

**Verdict:** Fits with changes (maintainability) · Ready with changes (executability). One round: the one blocker (M-1) was Fixed with no change to the plan's shape, so no second round ran. Nothing is open. Board S15-D17 agreed 2026-11-26 (user, turn 21); the plan is `Planned`.

## Before review (user, 2026-11-26)

- The Show more row keeps the kit's "Show N more"; N counts citation groups → D-8.
- A single huge citation group is not split; accepted and recorded → Edges "Untrusted size", §11.
- The board reaches the implementer as the Person page board link → **Board** line.

## Round 1

Fresh maintainability and executability reviewers each read the plan and the brief.

### M-1 · blocker · `CitationFocus` is a second focus handle beside `PVFieldFocus`
**Answer:** Fixed. D-7 uses `var citationFocus: PVFieldFocus? = nil`, applied as `CircularLinkDiagram` applies its handles; the `CitationFocus` type is gone from Codebase fit and STEP-3.

### M-2 · major · A bare `Int` beside `PagedFoldState`
**Answer:** Fixed. D-4 holds `PagedFoldState<PVProvenanceRecordTable.Fold>` with a one-case key, as `ReconciledValueRow` holds its one fold; D-5's `expand` and the macOS table read it.

### M-3 · minor · `Folded` and `folded` hang off `Group`
**Answer:** Fixed. Both sit on `PVProvenanceSheetContent`, beside `grouped(by:)` (D-2, Codebase fit, STEP-2, Scale).

### M-4 · minor · The timing helper would be copied
**Answer:** Fixed. `macos/ProvenenciaTests/Timing.swift` takes `milliseconds(_:)` from `CatalogListMergeTests` and adds `bestOfMilliseconds(runs:_:)`; STEP-1 moves it; Deletes names the removed private copy.

### M-5 · minor · The row is Ship in both inventories but gains a parameter
**Answer:** Fixed. Extend in the plan's macOS table and the brief's inventory.

### M-6 · minor · §4 Precedent repeats the Decisions
**Answer:** Fixed. The paragraph keeps the two PR links, what not to copy, and the `CircularLinkDiagram` pointer.

### M-7 · nit · "Runs have no unique id"
**Answer:** Fixed. The `RunPosition` row says a run's `key` is unique only within its value run.

### X-1 · major · The hosting and timing method is open
**Answer:** Fixed. D-9 names the window size, the content, the `idPrefix` and `open`, a fresh host per run, what is timed (host creation plus one layout), and one layout before reading the height, per `add-swift-test`.

### X-2 · major · STEP-3's check cannot see the table's behavior
**Answer:** Fixed. STEP-3 says the press, focus and Tab ACs are manual (§10): the kit's press rule is covered by `PVShowMoreRowTests`, and `add-swift-test` forbids synthesized key events. The fold's content is covered by T-1 – T-6, and the drawn bound by T-7.

### X-3 · major · The run's `VStack`, the rule and the loop keys are open
**Answer:** Fixed. D-3 gives the three `ForEach` ids (groups by offset, because group ids can repeat) and keeps the rule before the run, outside its `VStack`.

### X-4 · major · The manual check needs a project the plan does not provide
**Answer:** Fixed. §10 runs the press, focus and Tab checks in `#Preview("Folded, 120 runs")` live, and in the app only where the project has such a value; AC-2.x rest on T-3 and T-4.

### X-5 · minor · The Release command is incomplete
**Answer:** Fixed. D-9 writes the full command; STEP-1 and STEP-5 point at it.

### X-6 · minor · The archive move's links
**Answer:** Fixed. STEP-7 names the links to rewrite.

### X-7 · minor · The "Cap" edit, and "groups" against "runs"
**Answer:** Fixed. STEP-7 says what the "Cap" section becomes; §1 says a run is the working rule's citation group, and the rule's wording stays.

### X-8 · minor · Small unstated choices
**Answer:** Fixed. D-5: no horizontal padding. D-6: the modifier goes after the trailing padding. Codebase fit: `fold` and `folded` are `nonisolated static`, as `followsLine` is. Edges: a revealed run's heading may sit just above the visible area, accepted as the Person page sections behave.

## Refresh (2026-11-26)

Round 0 of ship-pr stopped on §11 "The Release test build fails": the test target cannot compile in Release, because `FakeStore` is `#if DEBUG` by design. The user chose to make the figures Debug-only. Meanwhile #1003 fixed the Release app build, and #1005 deleted `PVShowMoreRowHostedTests` and `pvScrollsShowMoreReveals(animated:)`. Refreshed against `main` @ `c1035450b`: D-9, STEP-1, STEP-5, T-7, the DoD figures line and §11 are now Debug-only; the Kit fold and Tests rows and the layout test's model row are retargeted; the version goes to 0.48.2; the round-0 deviations are settled (`summary: String?`, `CatalogListMergeTests` keeps its own best-of loop). One executability dry run of the refreshed parts (opus): **Ready with changes**, no blocker.

| ID | Severity | Finding | Answer |
| --- | --- | --- | --- |
| X-1 | major | STEP-1 stated `content(groups:summary:)` already took `String?` | Fixed. STEP-1 says to change it; the Previews row records the non-optional parameter |
| X-2 | minor | Equal heights could pass at 0; which host is read was unstated | Fixed. D-9, STEP-5 and T-7 add height > 0; STEP-1 reads the last run's host and prints the heights |
| X-3 | minor | D-9 called the preview fixtures `#if DEBUG` | Fixed. D-9 names `FakeStore` only |
| X-4 | minor | §10 step 4 named a "Release scheme" that does not exist | Fixed. Run, Debug |
| X-5 | nit | `Self.milliseconds` call site | Fixed. Named in STEP-1 |
| X-6 | nit | The Cap rewrite should name the build | Fixed. "the Debug before and after figures" |
| X-7 | nit | Draft history on the Planned line | Fixed. Removed |

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| Refresh | executability | opus | 121k |

## Reshape (2026-11-27)

The user reshaped the PR on 2026-11-27: no citation runs (every record is its own row), the fold counts records, and the grouping goes end to end, engine group key and proto field included; owner lines and value headings stay; no new brief. The plan was rewritten on the branch head `8d3290ee4`. Fresh maintainability and executability reviewers read it: **Fits with changes** · **Ready with changes**, one round, no blocker.

| ID | Severity | Finding | Answer |
| --- | --- | --- | --- |
| M-1 | major | Three copies of the numbered-record fixture | Fixed. D-16: `PVProvenancePreviewData.records(_:prefix:formatted:)`, `rendered(_:)` made non-private; previews, layout test and fold tests call it; Codebase fit, Deletes, STEP-1, STEP-2 |
| M-2 | minor | `CatalogRenderedCitation`'s doc and the map's S15-D17 row unnamed | Fixed. Deletes and STEP-3 name them; STEP-3's rg covers `design/README.md` and `deployment-plan.md` |
| M-3 | minor | T-2 and T-8's two-values case add no coverage | Fixed. T-2 dropped, AC-1.3 points at T-1; T-8 keeps order and nil-render cases |
| M-4 | minor | Doc list in three places; D-7 repeats §4; history in §1 and Codebase fit | Fixed. The list lives in STEP-3; D-12 and the DoD point there; D-7 trimmed; "Why now" and the *(new)* marks cleaned |
| M-5 | minor | `ValueGroup`'s explicit initializer survives | Fixed. Both explicit initializers go; the memberwise init serves |
| X-1 | minor | STEP-2's vet command | Fixed. `CGO_ENABLED=1 go vet -tags fts5 ./api/... ./core/...` |
| X-2 | minor | STEP-1's rg check matched too much | Fixed. Narrowed pattern; stale exclusion sentence dropped |
| X-3 | minor | §11 stop condition 2 too narrow | Fixed. "Anything outside the files in §4 reads …" |
| X-4 | minor | Missed doc rows | Fixed with M-2 |
| X-5 | minor | Which figures the docs use | Fixed. Before 1,558 / 6,691 ms; after, STEP-2's T-7 on the record fold; STEP-3, DoD |
| X-6 | minor | Doc comments naming runs, the key or old D-IDs | Fixed. One line before the Steps' count lists them |
| X-7 | nit | T-9 and T-8 overlap | Fixed. T-9 asserts `drawsRule` and `followsLine` only; order is T-8's |

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| Reshape | maintainability | opus | 174k |
| Reshape | executability | opus | — |
