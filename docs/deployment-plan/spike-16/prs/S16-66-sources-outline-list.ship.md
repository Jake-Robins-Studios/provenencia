# Ship log — S16-66 The Sources list is a native outline list

**Plan:** [`S16-66-sources-outline-list.md`](S16-66-sources-outline-list.md) · **Branch:** `s16-66-sources-outline-list` · **PR:** #962
**State:** fixing — user change U-1

## Round 0 — implement
Base `main` @ `11c91bba3`. Dispatched pr-implementer. `VERSION` is 0.37.0 at the base (S15-64), so STEP-8 gives 0.38.0.
Head `a09c2ac33`, PR #962 (draft). Report deviations: `SourcesListSettings` is `Hashable`; `SourcesModel.graphListError` new; `@MainActor` on `PVListPageArea` and `SourcesRowColumns`; the pre-handles fallback is the skeleton; `ZStack` count and status slots (not re-rendered); the STEP-4 `#Preview`s were not written; two catalog comments still say "button"; `%lld in progress` / `%lld promoted` given identical plural forms; STEPs 3–6 in one commit. Not checked by the implementer: triangle click, double-click, ink, menus as drawn, VoiceOver, skeleton and failure frames, Back edges, Scale stalls, resize.
Gate (orchestrator) PASS on `a09c2ac33`: all nine checks.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF (PRF for list code and `Features/Sources` models; SEC rides along). Skipped: none.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1, UX-1 | CON, UX | blocker | The list takes focus from the search field when rows come back | Fix now → F-1 | verified: `PVListBody` claims on every `onAppear`; `content` unmounts it on no match and while waiting |
| CON-2, UX-2 | CON, UX | blocker | Back loses the selected row while a status filter's counts load | To user → Fix now → F-2 | contradicts D-8's spelled `isSettled`; verified: `isAwaitingFilterData` not consulted. User, 2026-11-24: amend D-8 |
| MNT-1 | MNT | blocker | The page's state is derived twice and the copies disagree | Fix now → F-3 | verified: `statusCountsError` wins before `isAwaitingGraphList` in `content`; `showsToolbar` is false then (AC-6.7). Also `content` gates failure on `sources.isEmpty`, `showsToolbar` on `loadError` |
| CON-3 | CON | major | Back to a graph row has no end-to-end proof; a test is misnamed | Fix now → F-4 | verified: hosted tests set no anchor in a closed Source |
| CON-4 | CON | major | STEP-4's `#Preview`s missing; page states untested | Fix now → F-5 | verified: no `#Preview` in either file |
| PRF-1 | PRF | major | Each keystroke in Add Source re-runs the row builder for every row | Fix now → F-6 | verified: `SourcesListContent.body` reads `addSheetIsDirty`, `canSubmitAdd`; reviewer's probe about 26 ms at 3,000 rows, 61 ms at 12,000 |
| MNT-2 | MNT | major | `graphRowLabel` repeats `spokenJoin` | Fix now → F-7 | same-pass cleanup, output identical; supersedes D-25's named function |
| MNT-3 | MNT | major | A graph's counts are assembled in three places | Fix now → F-7 | same-pass cleanup; two of the copies are this PR's |
| MNT-4 | MNT | major | Rows re-test `hasArtifact` beside `graphBlockedReason` | Fix now → F-7 | D-10 names the helper the one place the gate is read |
| MNT-5 | MNT | major | `PVListRow` accessibility opt-out for one caller that re-applies the same | Fix now → F-8 | verified |
| MNT-6 | MNT | major | Every row repeats the separator guides | Fix now → F-8 | same-pass cleanup; supersedes the place D-2 and D-12 put them, if the wrapper's guide draws |
| CON-5, MNT-7 | CON, MNT | major | `add-ui-component` still states the bent menu rule | Fix now → F-9 | verified |
| SEC-1, MNT-10 | SEC, MNT | minor | A graph's name is parsed as Markdown in the menu | Fix now → F-10 | verified by the reviewer's `_resolveText`. MNT-10's `verbatimTitle:` initializer Rejected: D-16 chose the resource; F-10 draws it verbatim for every menu |
| PRF-2 | PRF | minor | ⌥-click close-all cost at Scale | Fix now (record) → F-9 | probe 324 / 250 ms at the map's 3,000 Sources: no visible stall at Scale; the numbers go in the Landed note, the user's §10 check stands |
| UX-3 | UX | minor | Truncated titles and graph names cannot be read | Fix now → F-7 | verified; a tooltip is not a hover look (AC-1.7) |
| CON-6, UX-4 | CON, UX | minor | Docs and comments describe the old list | Fix now → F-9 | verified by `rg` |
| CON-7, UX-5 | CON, UX | minor | The pre-handles frame drops Add source | Fix now → F-3 | verified |
| MNT-8, CON-8 | MNT, CON | minor | Placeholder id format written twice and parsed back | Fix now → F-7 | verified |
| MNT-9 | MNT | minor | First-load page and column widths repeated | Fix now → F-3 | verified |
| MNT-11 | MNT | minor | `SourcesOutline.swift` holds five jobs | Rejected | D-11 and D-16 place `SourcesRowColumns`, `secondaryParts` and `SourcesRowMenu` in that file |

Nits (logged): `MNT-12 · WorkspaceNavigation.swift ListAnchor.settle · build on resolved(_:in:)` · `MNT-13 · SourcesListView.swift toggle · id never read` · `MNT-14 · SourcesOutlineRows.swift · icon slot and spacing literals repeat` · `MNT-15 · SourcesModel.swift:192 · isLoading unread by views` · `CON-9 · STEP-7 lines 3, 7, 8 say "not checked"`

### Fix plan 1

**F-1 — The list claims focus once per arrival, never from the search field** (CON-1, UX-1)
Files: `PVListBody.swift`, `SourcesListView.swift`, `SourcesOutlineHostedTests.swift`. Skill: `add-ui-component`.
Failing test first: `aReturningListLeavesTheSearchFieldFocused` (query to no match, then back to a match: the first responder is still the field's editor); and a second, `theListTakesFocusOnArrival` (AC-4.1, must pass before and after).
Do: `PVListBody` gains `claimsFocus: Bool = true`, read in its `onAppear`; Conclusion lists unchanged. The Sources page passes false once its list has appeared, once the search field has been focused or once the settings changed (`PVInput` takes a `focused:` binding). Keep that state page-local, not on the kit's `FocusClaim`.
Check: both pass; `PVListTests`, `PersonsListTests` pass.

**F-2 — A selection waits for the filter's data** (CON-2, UX-2; amends D-8, user 2026-11-24)
Files: `SourcesModel.swift`, `SourcesModelTests.swift`.
Failing test first: `outlineWaitsForTheCountsAStatusFilterNeeds` — status filter set, Sources and graphs read, progress held: `isAwaitingFilterData` and `!outlineIsSettled` (hold the progress read through `FakeStore` so it cannot arrive).
Do: `outlineIsSettled` also requires `!isAwaitingFilterData && statusCountsError == nil`. Record the amendment in the Landed note; do not edit D-8.
Check: passes; Back to a row a filter hides still clears (AC-7.6).

**F-3 — One state for the list area** (MNT-1, CON-7, UX-5, MNT-9)
Files: `SourcesModel.swift`, `SourcesListView.swift`, `SourcesOutline.swift`, `SourcesModelTests.swift`.
Failing test first: `statusFailureKeepsTheToolbar` — status filter set, graph list loading, progress failed: the state and its toolbar agree (the status failure shows with the toolbar, AC-6.7).
Do: an enum `SourcesListState` (precedent `ConclusionListPresentation`) with the cases `failed`, `firstLoad`, `empty`, `statusFailed`, `waitingForFilter`, `noMatch`, `rows(graphsError:)` and `showsToolbar` on it. Built by one pure function; the model exposes it; `content` switches on it and the page reads `showsToolbar` from it. Order: whole-list failure with nothing to show; Sources list not read; empty catalog; status failure; graph list not read (no toolbar); filter data not in; no match; rows. Delete the model booleans nothing else reads. The pre-handles frame is the same page code (same `add:`, title, description, root) in `firstLoad`; `SourcesRowColumns.widths(isWide:)` replaces both dummy-closure `details(...)` calls and `details` uses the same constants.
Check: a test table over AC-6.1, 6.2, 6.6 – 6.10 plus the case above; `rg -n 'typeLabel: \{ _ in "" \}' macos` prints nothing.

**F-4 — Prove Back to a graph row** (CON-3)
Files: `SourcesOutlineHostedTests.swift`.
Tests: an anchor in a closed Source opens it and selects the graph; the same with the anchor set before the page is hosted (also that the row lies in the table's visible rect, with enough rows that it starts off screen); a graph selected then its Source closed through the page's path selects the Source (AC-2.5: ← twice does select-then-collapse, so drive the toggle; if the hosted harness cannot reach the triangle, expose the close through the row's accessibility action or ⌥-free `toggle` path and say which). Complete or rename `aSelectedGraphRowStaysSelectedAndClosingItsSourceSelectsTheSource`. If a Back test fails: fix within D-9, two tries, then stop (§11).
Check: all pass.

**F-5 — STEP-4's previews** (CON-4)
Files: `SourcesOutlineRows.swift`, `SourcesListView.swift` (or beside them).
Do: the `#Preview`s STEP-4 lists: rows (collapsed, expanded with 8 graphs, no Artifact, three count states, pending, one selected on accent with `\.backgroundProminence` `.increased`) at 1102 pt, and the page's states (counts failed; graph list failed with and without a status filter; whole-list failure). Render them to images through a hosted view once (not committed) and report what each looks like, especially the graph row's counts and status slots and "Needs an artifact to open". Fix the Landed note's line 6.
Check: they compile with no warning; report the renders.

**F-6 — Typing in Add Source leaves the list alone** (PRF-1)
Files: `SourcesListView.swift`.
Failing test first: none (a render count); say how it was checked.
Do: move the Add Source `pvFormDialog` with `addForm`, its `task`, its `onChange(of: typesHandle.status)` and `addPresented` into a private `ViewModifier` taking `model` and `typesHandle`, so the body that builds the list reads no `model.draft`.
Check: no read of `addSheetIsDirty`, `canSubmitAdd`, `draft` or `isSaving` in `SourcesListContent.body`.

**F-7 — One copy of each row mechanism** (MNT-2, MNT-3, MNT-4, MNT-8, UX-3)
Files: `SourcesOutlineRows.swift`, `SourcesOutline.swift`, `SourcePageGraphsView.swift`, `SourceGraphsSection.swift`, `WorkspaceSession+EvidenceGraphs.swift` (counts as an extension; keep layer order: if `SourcesGraphCounts` is a Feature type the extension lives beside it in `Features/Sources`), `L10n.swift`, `Localizable.xcstrings`, tests. Skill: `add-localized-string`.
Do: `spokenJoin([name, counts, status ?? ""])` replaces `graphRowLabel` (delete it and both catalog keys); `graphCounts(graphID:) -> SourcesGraphCounts` on the session serves the summary, the graph row and `SourcePageGraphsView`, and `SourceGraphsSection`'s forwarders go if unread; `SourcesGraphRow` and `SourcesRowMenu` read `SourcesListNavigation.graphBlockedReason(for:)` once each for opens, help, hint and `isEnabled`; `selectionAfterCollapsing` finds the row with `row(id:)` and its `source`, no id parsing (tests use drawn ids); `.help(title)` on the Source title, `.help(name)` on the graph name, the counts slot keeps the reason's help.
Check: `rg -n "graphRowLabel" macos` nothing; `rg -n '"#graphs"|#graphs' macos/App --glob '*.swift'` one code line (doc comments aside); `rg -n "graphNeedsArtifactTooltip" macos/App/Features` only the helper; `rg -n "SourcesGraphCounts\(progress" macos/App` only the extension, `SourceMoveDialog` and `SourcesModel` (or fewer).

**F-8 — The kit row and body own accessibility and separators once** (MNT-5, MNT-6)
Files: `PVList.swift`, `PVListBody.swift`, `SourcesOutlineRows.swift`, `macos/App/DesignSystem/README.md`. Skill: `add-ui-component`.
Do: `PVListRow`'s label is non-optional, `PVListRowAccessibility` goes, the Source row passes its label and identifier and appends `SourcesExpandedState`. `PVListBodyRow` sets both separator guides from `leadingHang`; rows drop theirs. Check in a hosted render that the rules still run gutter to gutter on Persons and Sources; if the wrapper's guide does not draw, restore the rows' guides and report MNT-6 as not possible with the render.
Check: `rg -n "listRowSeparatorLeading" macos/App` only `PVListBody.swift`; `PVListTests` pass.

**F-9 — Docs and comments** (CON-5, MNT-7, CON-6, UX-4, PRF-2)
Files: `.agents/skills/add-ui-component/SKILL.md:95`, `PVActionMenu.swift` header, `docs/macos-client-patterns.md` (List → detail row: drop the Sources list's columns from the centred clause, they are at `fullPane` now), `WorkspaceNavigation.swift` (`listAnchor`, `noteListAnchor` comments), `L10n.swift` 5344, 5501, 6453, 11251 and their catalog comments ("graph button" → "graph row"; not 6655), the plan's Landed note (PRF-2's numbers, F-2's amendment, MNT-2 and MNT-6 superseding D-25 / D-2 / D-12, the previews).
Check: `rg -n "Sources list graph button" macos` prints nothing.

**F-10 — A menu title is drawn verbatim** (SEC-1)
Files: `PVListBody.swift`, a test in `PVListTests.swift` if reachable.
Do: in `menuContent`, `Button { entry.action() } label: { Text(verbatim: L10n.string(entry.title)) }`.
Check: a graph named `**a**` keeps its asterisks (test the string path if the menu cannot be hosted).

## Round 1 — fix
Head `8cd9922d6`. Gate (orchestrator) PASS on `8cd9922d6`: all nine checks. F-1 – F-10 done. MNT-6's wrapper guides draw (hosted renders, Persons and Sources). Deviations: F-1, F-2, F-3, F-6 and F-10 share one commit; F-7 and F-8 share one; `FakeStore.listEvidenceGraphProgressHold` is new; `statusFailureKeepsTheToolbar` had no red run (the state type did not exist). F-5's renders show a selected row's Not started badge faint on the accent bar (AC-3.1 keeps the badge's colors): for the user's manual check.

## Round 2 — review
Reviewers: CON, MNT, UX, SEC+PRF, on `a09c2ac33...8cd9922d6`.

All four **Clean**, no new blocker. CON-1 – CON-5, MNT-1 – MNT-7, UX-1, UX-2, PRF-1 **Resolved**. Minors, read by the orchestrator: UX-3, CON-6, UX-4, CON-7, UX-5, MNT-8, MNT-9, SEC-1, PRF-2 **Resolved**.
Nits (logged): `MNT-16 · SourcesListView.swift:90 · sourcesHandle no longer read` · `CON-10 · PVListTests.swift:179 · aMenuTitleKeepsItsAsterisks tests L10n.string, not the menu` · `CON-11 · SourcesListPreviews.swift:64 · comment says Wide; 1102 pt is Regular`

## Result
Merged `origin/main` @ `6e18533b6` (docs only, S15-54's plan). Gate PASS on the merge · CI: red on the first ready head, see the CI fix round · open: none · follow-ups: none · to user: CON-2 answered (D-8 amended, 2026-11-24). Left to the user's manual check: STEP-7 lines 3, 7, 8, the Scale part of 6, and a selected row's faint Not started badge.

## CI fix round
CI macOS `test` FAIL on the ready head (run 45411247665). `closingTheSourceOfASelectedGraphSelectsTheSource`: the accessibility action is nil on the runner. Three others timed out in `waitUntil`, all ending at about 7.7 s together: `createSavesOneGraphAndToasts`, `confirmDeleteSourceRecountsThroughSession`, `copyRecountsThroughSession` (untouched code; the suspected cause is main-thread work in the new hosted tests).

**G-1 — The close test does not depend on the accessibility tree**
Files: `SourcesListView.swift`, `SourcesListNavigation.swift` (or beside `SourcesOutline`), `SourcesOutlineHostedTests.swift`.
Do: move the body of the page's `toggle` (D-15's order: select, then collapse) into one `@MainActor` function taking the outline, the session and the navigation, which the triangle, the keys and the row's action all call through the page; drop the unread `id` parameter (MNT-13). The hosted test calls that function and asserts the expanded set, `listAnchor` and the table's selected row. Delete the accessibility tree search.
Check: the test passes; `rg -n "accessibilityCustomActions" macos/ProvenenciaTests/SourcesOutlineHostedTests.swift` prints nothing.

**G-2 — The hosted tests keep the main thread free**
Files: `SourcesOutlineHostedTests.swift`.
Do: measure each test's synchronous main-thread time before and after (print once, do not commit). Expected cost: `ruleExtent` renders the whole table bitmap and calls `colorAt` per pixel; render only the row's rect and read bytes. Cut any other long synchronous block. Do not raise another suite's timeout, mark a test flaky, or change the three timed-out tests.
Check: report each test's time before and after; `scripts/check-pr.sh` PASS three times in a row.

Head `fa55de54b`. Gate PASS. G-1 done. G-2 done: `ruleExtent` 12–19 ms → 3–5 ms a call; no other long synchronous block found, so it does not by itself explain the runner's stall. The second run on the old test head (45412220503) failed the same test and the same kind of waits (`confirmDeleteSourceRecountsThroughSession`, `copyRecountsThroughSession`, `editSavesNameAndFullLinkSet`). `main` took bars 38 – 40 (slice 6g), so this PR's bar is 41; merged.

Gate PASS and CI green on the merge (run 45414806140): all 2,340-odd tests, `localizable`, Go. The three timed-out waits did not recur. They use `waitUntil`'s fixed two seconds in untouched suites, The longest gap in test output in both red runs (2.75 s, 2.32 s) ends at the failure of the accessibility-tree test G-1 removed, so that walk is the likely stall (not reproduced). `waitUntil`'s fixed two seconds fails on any stall that long: follow-up **dropped** by the user (2026-11-24).

## User change (2026-11-24)
The user keeps the Wide columns for now (a table is spiked after the merge) and adds one change before merging.

**U-1 — A click that selects a closed Source opens its graphs**
Files: `SourcesListView.swift`, `SourcesOutline.swift` (the pure rule), `SourcesOutlineRows.swift` (the triangle), `SourcesOutlineTests.swift`, `SourcesOutlineHostedTests.swift`, the plan's Landed note, `completed.md`, map bar 41.
Rule: a left click that moves the selection to a closed Source with a triangle opens it. Not: a selection moved by the keyboard, Back, a reveal, a right-click or a menu; a ⌘- or ⇧-click; a click on an already selected row; an open Source (a click never closes one); a Source with no triangle; a graph row. Other Sources keep their state. A double-click still opens the page, its first click having opened the Source.
The triangle: one click on it toggles exactly once, whether or not the platform selects its row first (STEP-7 line 3 is unproven). A selection made by a press on the triangle must not open the Source, or the button's action would close it again.
Do: in the page's selection binding `set` (the one place the list writes the selection), ask a pure function (new id, old id, whether it was a plain left click, whether the press was on a triangle, the outline) which Source to open, then `outline.setExpanded`. Read the click from `NSApp.currentEvent` (left mouse down or up, no modifiers), as the triangle reads `NSEvent.modifierFlags`. Know the press was on a triangle without a gesture on the row, which would compete with the list's selection and double-click: for example the triangle's `onHover` noting its Source in a non-observed page-local holder, cleared when it leaves or disappears. If that is unreliable, say what you used instead. Do not write SwiftUI state during a view update; a turn later is fine, but the rows must not animate.
Failing test first: the pure rule as a table over every line of the Rule. Hosted: a synthesized click on a closed Source's row (its title area) selects and opens it; a key move onto a closed Source leaves it closed; a click on the triangle of an unselected closed Source leaves it open, if a synthesized click reaches the button (round 0 reported it does not; try a key window, else say not checked).
Docs: the Landed note says AC-2.1 – AC-2.4 gain this, by the user, 2026-11-24; `completed.md` and bar 41 say a click selects a Source and opens its graphs. Do not edit the plan's ACs or Decisions.
Check: the tests pass; `scripts/check-pr.sh` PASS.

Head `119468aaa`. Gate (orchestrator) PASS. U-1 done: the pure rule is table-tested, the hosted tests stand in for the click (`selectRowIndexes` and a substituted current event); a real click on a row and a real press on the triangle are for the user's manual check. Quick-lens review of `4bcce2728...119468aaa`: **Clean**, no blocker or major.

| ID | Severity | Title | Decision |
| --- | --- | --- | --- |
| QCK-1 | minor | The one-second stale-event guard has no test | Fix now → U-2 |
| QCK-2, QCK-3 | nit | Misplaced and untrue comments in `SourcesListView.swift` | Fix now → U-2 (riding along) |

**U-2 — The stale-event guard is tested; two comments**
Files: `SourcesListView.swift`, `SourcesOutline.swift`, `SourcesOutlineTests.swift`.
Do: `isPlainLeftClick` takes the event's age (`systemUptime - timestamp`) and rejects one of a second or more; its table gains a stale press. Put the "leaves focus where it is" comment back above `listLeavesFocusAlone`; `select`'s comment says the write the platform list makes.
Check: the table fails when the age check is removed; `scripts/check-pr.sh` PASS.
