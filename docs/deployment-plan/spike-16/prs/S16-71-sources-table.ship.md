# Ship log — S16-71 The Sources list is a native table

**Plan:** [`S16-71-sources-table.md`](S16-71-sources-table.md) · **Branch:** `s16-71-sources-table` · **PR:** [#969](https://github.com/Jake-Robins-Studios/provenencia/pull/969)
**State:** ready

## Round 0 — implement
Head `4fea1cfc3`. Gate PASS (orchestrator). Deviations: version 0.40.0; Not started is 128 pt wide against the 126 pt minimum; relative dates use `TimestampFormat`'s words; graph wheel step 26; `settleDelay` a computed static; `SourcesOutline.items`; hosted suites `.serialized`; `PVPublishedDate` "Undated" faint on the Person page too; the rules test's place; AC-1.9 manual only. `BenchmarkList` 4.5 → 17.5 ms.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | blocker | A double-click whose second press lands on no row opens nothing | Fix now → F-1 | verified: `primaryAction` needs an id and `select(nil)` returns; needs a real mouse to confirm |
| CON-3 | CON | major | A held second press opens the wrong row | Fix now → F-1 | verified in `secondPressRow`; the D-15 time limit goes, **user, 2026-11-24** |
| UX-4 | UX | minor | The double-click guard accepts a stale event | Fix now → F-1 | verified: no age check |
| UX-1 | UX | major | Opening a Source below the open one can push it out of view | Fix now → F-2 | verified: nothing scrolls on an open; the reviewer's probe measured the shift |
| PRF-1 | PRF | major | The create read walks each Source's whole audit history | Fix now → F-3 | measured; the plan's "Schema: None" is superseded, **user, 2026-11-24** |
| CON-2 | CON, UX, MNT | major | Badges are two widths | Fix now → F-4 | 128, **user, 2026-11-24** |
| MNT-1 | MNT | major | Nine micro-caps copies stay | Fix now → F-5 | same-pass cleanup; supersedes STEP-10's `kit-layering.md` entry |
| CON-4 | CON | major | Counts loading and the artifact-less boundary have no test | Fix now → F-6 | verified by the reviewer against the test bodies |
| UX-3 | UX | minor | `Today, 10:15 AM` overflows 92 pt | Fix now → F-7 | 98 and truncate, Title 352 at 1102, **user, 2026-11-24** |
| UX-2 | UX, MNT | minor | VoiceOver reads a bare dash | Fix now → F-7 | supersedes D-18's "other cells", **user, 2026-11-24** |
| CON-5 | CON | minor | Clicking the open Source with no triangle closes it | Fix now → F-8 | verified: `clickAction` tests the disclosure |
| CON-6 | CON | minor | T-11 does not prove AC-1.8 and the 800 pt widths | Fix now → F-8 | |
| MNT-2, MNT-3, CON-8, CON-9, CON-10, CON-11, UX-6 | MNT, CON, UX | minor | Stale or misplaced comments and a test name | Fix now → F-9 | files this PR changes |
| MNT-4 | MNT | minor | Positional widths and a repeated `"type"` | Fix now → F-9 | verified |
| CON-7 | CON | nit | The second scroll omits D-10's "in `ids`" | Fix now → F-9 | D-10 states it |
| PRF-2 | PRF | minor | Table cost at 3,000 rows unmeasured | Fix now → F-10 | a measurement, not code |
| UX-5 | UX | minor | Sorting from the keyboard is unchecked | Fix now → F-10 | a manual check line; if it fails, To user |

Nits (logged): `MNT-5 · SourcesTable.swift graphTitle · inline let hint = reason ?? ""`
Outside-lens note (Status Landed with items not checked): no finding, the manual check is the user's before merge.

### Fix plan 1
The user approved (2026-11-24) the changes marked **user** above. Write each into the plan's Landed note as a difference; do not edit the plan's Decisions, Scope or ACs.

**F-1 — A double-click opens the first-pressed row however the second press lands** (CON-1, CON-3, UX-4)
Files: `SourcesListView.swift`, `SourcesPointerTests.swift`, `SourcesOutlineHostedTests.swift`.
Failing tests first: (a) `SourcesPointerTests`: a second press 10 s after the first still answers the first row while it is the selection; nil when the selection is another row, `clickCount` is 1, or the event is a second old or more. (b) hosted: first press on the last Source, then a `clickCount` 2 event with a nil selection write → navigation is at that Source's page, once; the double action arriving as well does not add a second history entry. (c) hosted: `activate` through the table with a `clickCount` 2 event for another row → the first row's page.
Do: `rowForSecondPress(clickCount:selected:age:)` replaces the interval with "the pressed id is still `navigation.listAnchor`" and rejects `age >= 1` (the constant `isPlainLeftClick` uses, shared). In `select`, a second press with a nil write opens the first row a turn later and consumes the press. The press is consumed whenever it opens, so it opens once. A `clickCount` 1 press that records nothing clears it. If a test seam is needed to reach `activate`, use the one the other hosted tests use; do not walk the accessibility tree.
Check: tests pass; §10 step 5 stays a real-mouse check.

**F-2 — A Source that opens stays in view** (UX-1)
Files: `SourcesListView.swift`, `SourcesOutlineHostedTests.swift`.
Failing test first: hosted, many Sources, A open with its 12 graphs partly above the viewport, B below selected and visible, press → → B's row lies inside `documentVisibleRect` once settled. A second case for the triangle path (the page's `apply(.expand(b))` while another row is selected; if a hosted test cannot reach it, test the shared function).
Do: when `apply` runs `.expand(id)`, request a scroll of that Source's row a turn later with the kit's existing `pvScrollsRowIntoView(_:animated:whenRequested:)` on the table. A row already in view does not move. Back, the reveal and the menu keep their own scroll. No change to `pvNativeListBehavior`'s API.
Check: the tests and T-10's Back test pass.

**F-3 — The create read does not grow with history** (PRF-1)
Files: the next migration (`core/database/migrations/`), what `add-catalog-migration` lists (schema hash, format), `created_test.go`, `sources.go`'s `sqlListHead` comment. Skill: `add-catalog-migration`.
Do: `CREATE INDEX audit_changes_created_idx ON audit_changes(entity_id) WHERE action = 'create'`. No migration upgrade test. Failing first: `TestCreatedQueryPlan` requires that index.
Check: `BenchmarkList` at 20 and 80 changes, before and after, in the report.

**F-4 — One badge width** (CON-2)
Files: `SourcesEvidenceStatus+Badge.swift`, `PVBadgeTests.swift`.
Failing test first: `everyStatusBadgeIsOneWidth`, from the finding: register fonts, the fitting widths of every `EvidenceStatus.badge` are one value, 128. It replaces the weakened assertion (the general `minWidth` test may stay).
Do: `badgeWidth` 128; comments true.

**F-5 — One micro-caps definition** (MNT-1)
Files: `PVContextMenu.swift`, `DateValueEditorForm.swift`, `NameValueEditorForm.swift` (3), `PropertiesView.swift` (2), `MetadataBoardView.swift`, `EvidenceCardView.swift`, `docs/ideas/kit-layering.md`.
Do: each reads `PVMicroCaps.font` / `.tracking`, or `.pvMicroCaps()` where that is exactly what it draws. No visible change. Remove STEP-10's "nine sites" entry; say in the Landed note it is superseded.
Check: `grep -rnE "PVTypeScale\.micro \* PVTracking\.caps" macos/App` prints only `PVTypography.swift`.

**F-6 — The badge's boundaries are tested** (CON-4)
Files: `SourcesModelTests.swift`.
Do: after `warmLists` and before `warmProgress`, nil for a Source with a linked graph and `.empty` for one whose only graph has no Artifact; the second again with the progress read failed. Show each fails when its rule is broken.

**F-7 — Date cells fit and speak** (UX-2, UX-3)
Files: `SourcesTable.swift`, `SourcesTableTests.swift`, `SourcesTableHostedTests.swift`, `L10n.swift`, `Localizable.xcstrings` if a string is needed. Skill: `add-localized-string`.
Do: Added and Updated 98 at Regular (Title 352 at 1102, the tests follow; Wide unchanged). The cells pass their column width so text truncates with a tail. Updated is labelled with `L10n.LastUpdated.a11yUpdated` / `a11yUnknown` as the base row did; Evidence's failed dash is labelled (reuse existing copy for an unread graph list if there is any, else one new string "graphs unavailable").

**F-8 — The open Source and the resize** (CON-5, CON-6)
Files: `SourcesOutline.swift`, `SourcesOutlineTests.swift`, `SourcesTableHostedTests.swift`, `SourcesOutlineHostedTests.swift`.
Failing test first: `clickingTheOpenSourceWithNoTriangleLeavesItOpen`, from the finding. Do: guard on `source.id != open`.
Then: assert every width at 800; resize across 1600 and back in the page harness with a Source open and a mid-list selection → scroll position (±1 row), first responder, selection and `openSourceID` kept. If the platform moves the scroll, report it, do not loosen silently.

**F-9 — Small fixes** (MNT-2, MNT-3, MNT-4, CON-7 – CON-11, UX-6)
`createdAtStamp` above the doc comment it split in `FakeStore.swift`; the comments in `PVLastUpdated.swift:20`, `SourcesGraphCounts.swift:43`, `SourcesEvidenceStatus+Badge.swift`, `PVPublishedDate.swift:6`, `SourcesListView.swift` `.onChange(of: model.settings)`; the wheel test's name; `SourcesTableWidths.init` by named properties, one constant for the Type column's id; the second scroll also needs the id in `ids`.

**F-10 — Measurements and the check list** (PRF-2, UX-5)
Throwaway hosted timing at 3,000 Sources: opening one Source and moving the selection; numbers in the Landed note, nothing committed. PR body manual check gains: sort from the keyboard (Full Keyboard Access) and with VoiceOver on a header; a double-click on the last Source of a short list with the one above open; open a Source whose open neighbour is scrolled above.

## Round 1 — fix
Head `ee85df346`. Gate PASS (orchestrator). F-1 to F-10 done. Six extra runs of the hosted suites: `SourcesOutlineHostedTests` and `SourcesTableHostedTests` passed every time; `PVBadgeTests.anOutlinedBadge…` failed twice, at the filled badge's comparison → G-1.

## Round 2 — review
Reviewers: CON, MNT, UX, SEC+PRF (fix commits only). All four: **Clean**; every round-1 blocker and major **Resolved**. PRF-1 measured to 320 changes a Source: 20.4 ms. Minors read by the orchestrator in the fix diff: **Resolved** (UX-2, UX-3, UX-4, CON-5, CON-6, MNT-2 – MNT-4, the comments, PRF-2's numbers). Residual note from UX: the new scroll is one, not two; a Source far down a long list goes on the manual check.

**G-1 — The badge ink test is steady** (gate retry)
Files: `PVBadgeTests.swift`.
Likely cause: the test does not register the bundled fonts, and another test registers them between its two renders. Reproduce first, name the cause, then fix the test (do not weaken what it proves or mark it flaky). Also run `anAnchorSetBeforeThePageIsHosted…` 20 times; if it fails once, report the output and the cause, change nothing.
Check: `PVBadgeTests` passes 20 runs in a row, with the other hosted suites running; `scripts/check-pr.sh` PASS.

G-1 returned with no change (head still `ee85df346`). Orchestrator's measurements: `anAnchorSetBeforeThePageIsHosted…` failed 5 of 45 repeats (AC-4.8; the viewport stops about a row short of the selected graph, and nothing scrolls later); `anOutlinedBadge…` failed 4 of 14 runs in a fresh process and 0 of 20 repeats in one process, so G-1 is to be reproduced in fresh processes. The plan's stop condition is met; D-10's change is **To user**.

## User test (2026-11-24)
The user built `ee85df346`: it works, with one bug, below. Decided by the user: history records a plain scroll offset for any scroll view, plus the list's own open state, in a **new Spike 16 PR**; with no usable offset the page opens at the top. AC-4.7's and AC-4.8's "in view" moves to that PR, so the anchor test's failure is a To user item answered; D-10 does not change here.

| ID | From | Severity | Title | Decision |
| --- | --- | --- | --- | --- |
| USR-1 | user | blocker | Graph rows draw at two heights: opening a Source draws some at about 34 pt and others at about 66, varying line to line; after Back all are 34 | Fix now → U-1 |

**U-1 — Every graph row is 34 pt, always** (USR-1, AC-1.6)
Files: `SourcesTable.swift`, `SourcesOutlineHostedTests.swift` or `SourcesTableHostedTests.swift`.
Seen: a graph row beside single-height ones at double height (the same as a Source row's 66), in an opened Source; Back redraws them right. Likely: the table keeps the height it had for that index, or the row view it reuses, from a Source row when rows are inserted above; or the cells of the other columns give a taller first measure. Diagnose before fixing, and say the cause.
Failing test first: hosted, with many Sources of mixed graph counts (one with 8, one with no Artifact), open one, then another above it, below it, change the sort, filter and clear it, load late graphs, let the counts arrive late → after each, every Source row is 66 ±0.5 and every graph or pending row is 34 ±0.5, by `table.rect(ofRow:)` for every row, and every visible cell's drawn frame matches. If the platform only misbehaves in a window that is really shown, use a borderless one; if it cannot be reproduced in a test at all, say so with what was tried.
Do: fix the cause with SwiftUI means (for example a fixed height on every column's cell, a stable row kind per id, a separate row identity). If the only fix that works is AppKit, stop and report it.
Check: the test fails before and passes 20 runs after.
Then: run the anchor test (`anAnchorSetBeforeThePageIsHosted…`) 60 times, since wrong heights may be why the scroll stopped short. If it now always passes, keep it as it is. If it still fails, keep its open-and-selected assertions, remove only its "in view" and scroll-offset assertions, and name the new PR in a comment and in the Landed note (AC-4.7, AC-4.8 "in view": moved, user, 2026-11-24).

**U-2 — The badge ink test is steady** (G-1 again)
It fails 4 of 14 in **fresh processes** (`-only-testing:ProvenenciaTests/PVBadgeTests`, one `xcodebuild test` each), never in repeats within one process: so the first renders in a process differ. Name the cause (the font registration is the first suspect; a first render before a font or symbol loads is another), fix the test without weakening it.
Check: 20 fresh processes pass.

### User round — fix
Head `4d5242165`. Gate PASS (orchestrator). U-1, U-2 done (gate retry G-1 closed by U-2). Anchor test after U-1: 1 of 120, so its "in view" moved to S16-72. Quick-lens review of `ee85df346...4d5242165`: USR-1 and U-2 **Resolved**.

| ID | Severity | Title | Decision |
| --- | --- | --- | --- |
| QCK-1 | major | One End stops about 11 rows short at 100 Sources or more | Fix now → U-3 (AC-5.2; the reviewer measured it at three sizes) |
| QCK-2 | minor | Opening a Source in an undrawn part of 3,000 moves it twice | Logged: the second move corrects the first; manual check line |
| QCK-3 | minor | Scrolling up through undrawn rows jumps; the document height reads short | Later PR → S16-72's map scope, which needs stable offsets |
| QCK-4 | minor | "Before it is drawn" is observed, not tested | Fix now → U-3 |

Nits (logged): `QCK-5 · SourcesTable.swift:21 · heights stated twice`

**U-3 — End reaches the end**
Files: `PVNativeListBehavior.swift`, `SourcesOutlineHostedTests.swift`, `SourcesTable.swift` (comment), the plan's Landed note (21).
Failing test first: hosted, 100 closed Sources, End once → the last row lies inside the visible rect once settled; Home → the first row.
Do: the Home/End request repeats once after `settleDelay` when `edgeRow` is still the one requested and is in `ids`; use one helper with `requestSelectionScroll` and the opened Source's repeat in `SourcesListView.apply` if their shape is the same, without a new public parameter. A second Home/End press or a selection move in between wins. Reword the `SourcesRowHeight` comment, the `settle` comment and Landed (21): no short frame was observed, the test proves the settled heights. PR body manual check gains: End then open a Source at the largest catalog; trackpad scroll up after End.
Check: the test 20 times; `scripts/check-pr.sh` PASS.

Head `1ee76d5f9`: U-3 done except its last clause (a selection move in between wins); `main` merged.

**U-4 — A selection move cancels End's repeat**
Files: `PVNativeListBehavior.swift` (`requestEdgeScroll`). Do: the repeat also needs the selection to be the one at the request, as `requestSelectionScroll` reads it. Hosted test: End, then the selection moves to a row elsewhere before `settleDelay` → after it, that row is in view (fails first). Check: 20 runs; `scripts/check-pr.sh` PASS.

Head `0c86d981e`: U-4 done (correction: the orchestrator read the diff only after the CI failures, not at the gate; U-3, U-4 and C-1 had no reviewer). Gate PASS; the hosted and badge suites passed 3 further fresh processes.

### CI on `e487a119c`
Go green; **macOS red** (run 45504654286): the whole run aborts with "Received unexpected event testCaseDidStart for `SourcesOutlineTests/openingMovesASelectionOffTheClosedGroup(_:)` (iteration 1). Test already started." No assertion failed. Passes locally.

**C-1 — The parameterized selection test has distinct cases**
Files: `SourcesOutlineTests.swift` (and any other parameterized test this PR adds with the same trait).
Likely: two of its arguments share one case identity (equal values, or a type whose encoding is the same), so Xcode starts one case twice. Remove the duplicate, or give each case a distinct `Codable` / `CustomTestArgumentEncodable` identity, keeping every input → expected pair. Check every parameterized test in the diff (`git diff origin/main -- macos/ProvenenciaTests | grep "arguments:"`) for equal cases.
Check: a script or test shows no equal arguments; `scripts/check-pr.sh` PASS.

Head `76325e31b`: C-1 done (two pairs of cases had one description). Gate PASS (orchestrator).

### CI on `76325e31b` and `7a5def392`
C-1 works: the run completes. macOS red twice (runs 45505668518, 45505904968; macOS 15 runner, Xcode 16.4), one test: `everyRowIsItsOwnHeightHoweverTheRowsMove`, some Source rows read 34, want 66, 200 ms after a change. It passes on macOS 27.2. Not known: late on the runner, or stuck on macOS 15 (U-1's `SourcesRowHeight` was checked on 27.2 only). To user.

### CI round 2 (user, 2026-11-24)
The user saw correct heights on every Source and graph row on macOS 27.2.

**C-2 — The height test says whether a row is late or stuck**
Files: `SourcesOutlineHostedTests.swift` only.
Do: `expectRowHeights` polls (each turn lays out, then reads `wrongRows`) until no row is wrong, at most 5 s, in place of the fixed 200 ms; keep a check that the result still holds one turn later. On failure, or when settling took over 200 ms, the message carries the step name, the wrong rows with `rect(ofRow:)`, row view and every cell height, and how long it took. Print the slowest settle (one line) so a passing CI log shows it. Where a row is still wrong after 5 s, also report whether one more scroll away and back, and one `noteHeightOfRows`, corrects it (diagnosis only, after the failure is recorded). Do not weaken any height, change product code, or add a retry trait.
Check: passes 20 times locally; `scripts/check-pr.sh` PASS; push.

Head `9d417c698`: C-2 done; macOS CI green (run 45517495666, slowest settle 0.157 s, "sorted"). Not proof: both old failures were at "sorted", and the poll's layouts may correct the row. Quick-lens review of U-3, U-4, C-1, C-2:

| ID | Severity | Title | Decision |
| --- | --- | --- | --- |
| QCK-6 (its QCK-1) | major | The poll cannot tell a self-correcting row from one its layouts correct | Fix now → C-3 |
| QCK-7 (its QCK-2) | minor | A step confirms after 50 ms; "late counts" can pass before the counts arrive | Fix now → C-3 |
| QCK-8 (its QCK-3) | minor | The edge repeat's "still there" check reads the ids of the press | Fix now → C-3 |

**C-3 — The sort is checked with no forced layout, in a shown window**
Files: `SourcesOutlineHostedTests.swift`, `PVNativeListBehavior.swift` (QCK-8 only).
Do: (1) a test that hosts the page in a borderless window ordered in (opaque, on screen), opens a Source, lets it settle, sorts by Title as "sorted" does, then awaits with **no** `layoutSubtreeIfNeeded`, `displayIfNeeded` or scroll by the test, reading `wrongRows` every 20 ms for up to 5 s without laying out; it must become and stay right. Print when, and the `NSWindow` visibility and screen count, so the log shows whether the runner really showed it. Close the window after. (2) the same in the never-shown window, printed only, not asserted. (3) `expectRowHeights` confirms after 250 ms instead of 50 ms, and the "late counts" step waits for the counts to have arrived first; prints only a late or failed step. (4) QCK-8: drop the vacuous `rows.contains` checks and the comment's clause (both functions), or read live ids.
If (1) fails on CI, that is a product finding: report it, change nothing else.
Check: 20 runs locally; `scripts/check-pr.sh` PASS; push.

Head `9af301a09`: C-3 done; CI green (45523692600). C-2's reruns: 4 of 4 green, "sorted" settling in 0.16, 0.17, 0.23 and 0.35 s. The shown-window test is not yet proof: it reads "right" 0.2 ms after the click, before the sort is known to have applied, and its `wrongAgainAt` assertion failed once locally on a transient.

**C-4 — The shown-window test proves the sort**
Files: `SourcesOutlineHostedTests.swift` only.
Do: before the sort, scroll to y 500 as the failing step had (its `scrolled` steps ran first), and confirm it; after the sort, start watching only once the list is back at its top (`contentView.bounds.minY` at its top, the sort's own effect) and the first drawn row is another Source than before (read what a cell shows, without the accessibility tree, or `harness` state if it exposes the outline order; say which). Then, with no layout by the test: the rows become right within 5 s and the last second of reads are all right. A transient before that is allowed; print how long rows read wrong and the first and last times. Same for the never-shown window, printed only. No fixed sleep stands in for the sort applying.
Check: the assertion fails if the sort line is removed (say so); whole `SourcesOutlineHostedTests` 20 times; `scripts/check-pr.sh` PASS; push.

### User round 2 (2026-11-24)
The user: no repeat runs as proof; a flaky test is fixed at its cause; AppKit is allowed for exact row heights (supersedes the rule "no AppKit reach-in" for this). C-4 is dropped, uncommitted.

**U-5 — The Sources table knows every row's height before it draws it**
Files: `SourcesTable.swift`, `SourcesListView.swift`, `PVNativeListBehavior.swift`, the hosted and table tests, a new file for the AppKit piece, kit README, the plan's Landed note, `completed.md`.
Step 1, throwaway, commit nothing: show that the `NSTableView` under SwiftUI's `Table` can be given exact heights (a delegate that forwards everything else to SwiftUI's own and answers `tableView(_:heightOfRow:)`, or another way you find sounder; `usesAutomaticRowHeights` off), without private API or method swizzling, with selection, header sorting, the context menu, double-click, keys and row insertion and removal still SwiftUI's. Consider what happens when SwiftUI replaces the delegate or the table. **Stop and report** if it needs private API or swizzling, breaks one of those, or would not work on macOS 14 and 15 as well as 27; say what else could. CI is the only macOS 15: if step 1 works here, step 2's CI run is its proof.
Step 2, only if step 1 holds: height is a pure function of the row (`SourcesTableItem`: 66 Source and skeleton, 34 graph and pending), and the piece reads it; heights change in the same update as the rows. `SourcesRowHeight` goes. Every delayed second scroll that existed for estimated heights goes (`repeatOnce`, `settleDelay`, their callers), for `PVList` too only if its rows are one height and it never needed it; if some scroll still needs one, stop and say which and why.
Tests: the height function as a table; one hosted test that `rect(ofRow:)` of **every** row, drawn or not, and the document height are exact at once after open, close, sort and filter; End, Home, opening a Source with an open neighbour above, and Back's deep graph land in one scroll (put back the anchor test's "in view" assertions). Delete the diagnostics (C-2 to C-4: `SortWatch`, the never-shown test, the printing, the poll) and the U-1 multi-step test they served. Go through every wait in `SourcesOutlineHostedTests` and `SourcesTableHostedTests`: a fixed sleep goes; a wait is on the event or state itself, with a timeout only as the failure limit. Close each harness's window at the test's end, so a long run does not slow down.
Prove once, not by repeats: each test fails when its behavior is broken, and one `scripts/check-pr.sh` PASS. Do not use `-test-iterations`.

U-5 stopped at step 1, nothing changed. A forwarding delegate gives exact heights at once (3,008 rows, one scroll lands; macOS 27.2, standalone probe), but Return no longer opens the selected row. Options to user: (A) the proxy with Return taken back, other overrides untested; (B) `class_addMethod` on SwiftUI's private coordinator (works, read as inside the swizzling ban); (C) the page's own `NSTableView`, public API only, a PR of its own size, not tried; (D) one row height.

The user (2026-11-25): no AppKit table here; remove the diagnostics and fixed sleeps, and review the whole change adversarially for cruft, simplicity, idiom and separation of concerns.

### Adversarial review of `9af301a09` (whole change; two reviewers)
No blocker. Findings: APP-MNT-1 – 13 (production), TST-MNT-1 – 16 (tests, docs). Decisions:

| ID | Severity | Title | Decision |
| --- | --- | --- | --- |
| TST-1, 3, 4, 5, 6 | major | Hosted-test diagnostics, sleeps, races, duplicates, harness | Fix now → K-1 |
| APP-1, APP-8 | major, minor | One scroll request in one place; whether Home/End is the platform's | Fix now → K-2 |
| APP-2, TST-2 | major | One click value, one pure press decision; the event seam goes | Fix now → K-3 |
| APP-3 | major | Column visibility is derived | Fix now → K-4 |
| APP-4 (switches, time cell), 5, 6, 7, 9 | minor | Cells, widths, outline maps, dead code, Go attach | Fix now → K-5 |
| APP-10, 12, 13; TST-8 – 14 | major to nit | False or narrating text; small test suites | Fix now → K-6 |
| TST-7 | major | Badge tests are pure | Fix now → K-6 |
| APP-4 (inner height frames), APP-11 | minor, nit | Frames may change VoiceOver's frame; one disabled-customization Group | Logged: no gain worth the risk |
| TST-15, 16, TST-8's ship-log line | nit | Goes with K-1; map and ship log | Orchestrator |

**Cleanup plan.** No behavior a researcher can see changes. The plan's Decisions this supersedes (D-7's state, D-10's request functions, D-14 and D-15's shape) go in the Landed note. One commit per item, each leaving the tests green; prove with one run, never repeats.
- **K-1 Tests first.** TST-1, 3, 4, 5, 6 as written: the hosted suites keep only what a pure test cannot show; no `Task.sleep`; every wait is on state with a 10 s failure limit; each kept test is shown to fail when its behavior is broken.
- **K-2 Scrolling.** First one check: remove the Home/End handler and run the End/Home test; if it passes, the handler and its state go. Then APP-1's single request and one cancellable repeat; the page passes its reveal in. `PVList` keeps it only through the shared modifier.
- **K-3 Clicks.** `SourcesPointer.swift` holds the pointer, `SourcesClick` (the one parse of the event) and one pure decision (second press and what it opens, or select and which outline action), tested as a table; `select` and `activate` read, decide, perform. `sourcesCurrentEvent`, `SourcesEventSource` and the event-driven hosted click tests go.
- **K-4 Columns.** APP-3; if a constant customization is not honored on resize by `columnsFitTheirWidths`, keep the state and take the rest, and say so.
- **K-5 Rows and Go.** APP-4's switches and `timeCell`, 5, 6, 7, 9.
- **K-6 Text and small suites.** APP-10, 12, 13; TST-7 – 14.

Head `797b0d938`: K-1 to K-6 done (APP-12 not: it trips `patterns`; Home/End's handler stays: the test fails without it). Net since `9af301a09`: +709 −1535; `SourcesOutlineHostedTests` 854 → 257 lines, no sleep. Gate PASS (orchestrator), CI green (45629749578, macOS 15). Conformance review of the cleanup: no visible regression.

| ID | Severity | Title | Decision |
| --- | --- | --- | --- |
| CON-20 (its 1) | major | The selection write and the press note/consume are untested | Fix now → L-1 |
| CON-21 (its 2) | major | A header click writing the sort is untested | Fix now → L-1 |
| CON-22, 23, 24 (its 3, 5, 6) | minor, nit | Height test's equal neighbours; dead `s.Updated`; a drawn row | Fix now → L-1 |
| CON-25 (its 4) | minor | Resize keeps scroll and focus; a selection move cancels End's repeat: no test | Manual check (AC-1.8) and the Landed note; a timer race has no deterministic hosted test |

**L-1 — The wiring has tests again**
(1) `theTablesOwnSelectionBecomesTheAnchor` in `SourcesOutlineHostedTests` as the finding writes it, without its last line. (2) `SourcesPointer` owns `pressed` (`private(set)`): `press` notes, clears and consumes; `secondPress` for the double action consumes when it opens; tested as a sequence (note; a second press on no row opens once; again opens nothing; a modified first press clears; the double action after it opens the row under it). (3) `aHeaderClickSortsAndEvidenceStatusAndTypeDoNot` in `SourcesTableHostedTests` as written, Type too where it is shown. (4) The height test's steps reordered so no two neighbours have one row count; row 0 must be drawn. (5) Drop the dead `s.Updated = res.Activity` lines in `api/ffi/handlers/sources.go` (check both are overwritten on every path). (6) Landed note: CON-25's two lines. Each new test is shown to fail once with its behavior broken; no sleep, no repeats; one `scripts/check-pr.sh`.

Head `49631edee`: L-1 done (orchestrator read the diff).

## Result
Gate PASS · CI: green on `797b0d938`; the final head's run is on the PR · open: none · later PR: S16-72 · follow-ups: none · to user: the manual check

## Cost
Plan: 7,670 words (check-plan-docs info line).

| Round | Agent | Model | Tokens |
| --- | --- | --- | --- |
| 0 | implementer | sonnet | 504k |
| 1 | CON | opus | 150k |
| 1 | MNT | opus | 127k |
| 1 | UX | opus | 138k |
| 1 | SEC+PRF | opus | 143k |
| 1 | implementer (fix) | sonnet | 248k |
| 2 | CON | opus | 76k |
| 2 | MNT | opus | 70k |
| 2 | UX | opus | 61k |
| 2 | SEC+PRF | opus | 57k |
| 2 | implementer (G-1) | sonnet | 89k |
| user | implementer (U-1, U-2) | opus | 270k |
| user | QCK review | opus | 66k |
| user | implementer (U-3) | sonnet | 104k |
| user | implementer (U-4) | sonnet | 106k |
| CI | implementer (C-1) | sonnet | 85k |
| CI | implementer (C-2) | sonnet | 82k |
| CI | QCK review 2 | opus | 85k |
| CI | implementer (C-3) | sonnet | 117k |
| CI | implementer (C-4, stopped) | sonnet | — |
| user 2 | implementer (U-5) | opus | 155k |
| cleanup | adversarial review, app | opus | 237k |
| cleanup | adversarial review, tests | opus | 212k |
| cleanup | implementer (K-1 – K-6) | opus | 344k |
| cleanup | CON review | opus | 158k |
| cleanup | implementer (L-1) | sonnet | 104k |
| | **Total** (rows with a count) | | **3,788k** |
