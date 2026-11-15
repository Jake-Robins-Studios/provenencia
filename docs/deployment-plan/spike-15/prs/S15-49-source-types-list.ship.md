# Ship log — S15-49 The Source types list is redesigned

**Plan:** [`S15-49-source-types-list.md`](S15-49-source-types-list.md) · **Branch:** `s15-49-source-types-list` · **PR:** #852
**State:** fixing 6 (user request after ready)

## Round 0 — implement
Base `main` @ `1f52b6080`. Note to the implementer: T-1's `sortColumn == .usage` is a typo for `.usedBy` (D-6, review M-2).
Head `f8f8349a7`, PR #852 (draft). Report: version 0.15.5 (main was already 0.15.4); brief links repointed into `design/archive/` incl. the review log; manual check not run.

### Gate
Implementer's gate PASS. Orchestrator's gate hung twice in `xcode-test` (not a failure of this PR's code):
`SourceTypePageModelTests.aSaveInFlightIsNotHeld` (landed in S15-48) — `waitUntil` (2 s default) times out before
`submit()` reaches `updateSourceTypeHold.wait()` under full-suite load (passing runs took 14–16 s); `release()` then finds
no waiter, the late `wait()` suspends forever, and `await save.value` never returns. Same issue at line 560 in both hung
logs (`check-pr.3tDmc4`, `check-pr.ufSbDB`). 27 `Hold.count` waits across 8 test files share the pattern.
User (2026-11-15): fix it on this PR.

### Fix plan 0 (gate)
**F-0 — A test waits for a held store call with no deadline** (gate hang; not a review finding)
Files: `macos/App/Platform/FakeStore.swift` (`FakeHold`), `macos/ProvenenciaTests/QueryHandleWaiting.swift` (only if a shared doc line belongs there), and the 8 test files below. Skill: `add-swift-test`.
Failing test first: none practical (the failure is a timing race under full-suite load); evidence is the two hung gate logs.
Do: give `FakeHold` an `async` method that suspends until exactly `n` calls are suspended in `wait()` — no deadline, signalled from `append`/`takeOldest` under the existing lock (continuations, not polling), with a doc comment saying why it has no deadline (a full-suite run starves the main actor past any fixed timeout; see `QueryHandleWaiting.swift`'s no-deadline helper). Move every positive wait on a hold's count onto it: each `#expect(await waitUntil { x.count == n })`, `try #require(await waitUntil(timeout:) { x.count == n })` and the `while x.count == 0 { await Task.yield() }` loop in `PersonDetailTests.swift:348`. Keep the two negative checks (`!(await waitUntil(timeout: .milliseconds(300)) { … count == 2 })` in `SourceGraphFormModelTests.swift:396`, `SourcePageModelTests.swift:2344`) as they are: they assert something does *not* happen.
Sites: `SourceGraphFormModelTests` 394, 408 · `SourceTypePageModelTests` 560 · `SourcePageModelTests` 2340, 2362, 2380 · `EvidenceGraphModelTests` 826, 834, 883, 891 · `PersonDetailTests` 348 · `CatalogCountsTests` 103 · `UnpromoteFlowTests` 184, 188, 190, 243, 261, 353 · `WorkspaceSessionTests` 2125, 2134, 2358, 2406, 2409, 2424, 2457.
Check: `grep -rnE 'waitUntil.*Hold\.count|Hold\.count == 0' macos/ProvenenciaTests` prints only the two negative lines (`SourceGraphFormModelTests.swift:396`, `SourcePageModelTests.swift:2344`); `scripts/check-pr.sh` PASS, run twice. Commit subject is a full sentence, e.g. "Wait for a held store call without a deadline so slow full-suite runs cannot hang the tests."

## Round 0 — gate fix
Head `38635f753`. F-0 done: `FakeHold.untilSuspended(_:)` (continuations, no deadline); 27 positive waits moved; grep prints only the two negative 300 ms lines. Implementer gate PASS ×2; orchestrator gate PASS (xcode-test 77 s).

## Round 1 — review
Base `1f52b6080`, head `38635f753`. Reviewers: CON, MNT, UX (`macos/App/**`, `Localizable.xcstrings`), SEC+PRF (performance: `macos/App/Features/**` models; no security path touched, run together per the rule).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | blocker | Six positive hold waits (local `hold`) still poll `count` with a deadline | Fix now → F-1 | verified: `rg 'waitUntil.*\w+\.count =='` prints `WorkspaceSessionTests.swift:184`, `PromoteModelTests.swift:343/348/371/377/420`; F-0's grep was by name, not body. Same-pass cleanup |
| MNT-2, CON-2 | MNT, CON | major | `add-swift-test` still teaches `count` polling for a `FakeHold` | Fix now → F-2 | verified: `.agents/skills/add-swift-test/SKILL.md:21` names `count`, no `untilSuspended` |
| UX-1 | UX | major | VoiceOver reads the two count cells as bare numbers / two dashes | Fix now → F-3 | verified: `PVTable.swift:345` `.accessibilityElement(children: .combine)`; `countCell` has no label. Spoken-only label keeps D-2's on-screen look |
| CON-1 | CON | major | Archived S15-D28 brief and the review log have broken relative links | Fix now → F-4 | verified: 9 broken targets from `design/archive/`; review log href still `../design/S15-D28-…` |
| UX-2, CON-3b, SEC outside-lens | UX, CON | minor | `.help` on every description cell, D-3 says non-empty only | Fix now → F-5 | verified: `SourceTypesListPane.swift:84` unconditional |
| CON-3a | CON | major | Landed note omits the `FakeHold` change | Fix now → F-6 | verified: plan § Landed has 3 bullets, none on test infra |

Nits (logged): `UX-3 · SourceTypesListPane.swift · cut label at Wide has no tooltip` · `MNT-3 · SourceTypesModelTests.swift:918 · width constant re-checked` · `MNT-4 · FakeStore.swift:94-97 · filter then removeAll, one partition pass` · `CON-4 · FakeStore.swift:36 · say an overshoot past n waits forever` · `CON-5 · 38635f753 subject overstates` (SEC+PRF outside-lens note on overshoot hang folded into CON-4)

### Fix plan 1
**F-1 — Every positive hold wait uses `untilSuspended`** (from MNT-1)
Files: `macos/ProvenenciaTests/WorkspaceSessionTests.swift`, `PromoteModelTests.swift`, `CitationAutoTranscribeTests.swift`.
Do: `WorkspaceSessionTests.swift:184` `_ = await waitUntil { hold.count == 1 }` → `await hold.untilSuspended(1)`; `PromoteModelTests.swift:343, 348, 371, 377, 420` `#expect(await waitUntil { hold.count == 1 })` → `await hold.untilSuspended(1)`; `CitationAutoTranscribeTests.swift` before `engine.hold.release()` (~line 360) add `await engine.hold.untilSuspended(1)` so the release cannot run before `recognizeText` reaches the hold (keep the `isTranscribing` expectations).
Check (by body, not name): `rg -n 'waitUntil[^{]*\{ *[\w.]+\.count ==|\.count == 0 \{ await Task.yield' macos/ProvenenciaTests` prints only `SourceGraphFormModelTests.swift:396` and `SourcePageModelTests.swift:2344` (the negative 300 ms checks).

**F-2 — The test skill and `waitUntil` doc name `untilSuspended`** (from MNT-2, CON-2)
Files: `.agents/skills/add-swift-test/SKILL.md:21`, `macos/ProvenenciaTests/QueryHandleWaiting.swift` (`waitUntil` doc), `macos/App/Platform/FakeStore.swift` (`untilSuspended` doc, CON-4).
Do: skill line → "`FakeHold` (`isOn`, `release()`; wait for a held call with `await hold.untilSuspended(n)`, never `waitUntil` on `count`; `count` is for negative checks only, such as no second call within 300 ms)". One sentence on `waitUntil`: for a `FakeHold`, use `untilSuspended`. On `untilSuspended`: it waits for exactly `n`, so pick `n` from calls the test controls; a count that passes `n` and never comes back waits forever.
Check: `rg -n untilSuspended .agents` finds the skill line; `scripts/check-guidance-names.py` passes.

**F-3 — Each count cell has a spoken label** (from UX-1)
Files: `macos/App/Features/SourceTypes/SourceTypesListPane.swift`, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`. Skill: `add-localized-string`.
Do: `countCell(_ count: Int, spoken: String)`; the cell adds `.accessibilityLabel(Text(verbatim: spoken))`; on-screen text unchanged (D-2). `usedBy` passes `L10n.SourceTypes.usage(count: type.usedBy)` (reused: "in use on %lld sources" / its zero case). `fields` passes a new `L10n.SourceTypes.suggestedFieldsSpoken(count:)` shaped like `usage(count:)`: 0 → key `sourceTypes.list.suggestedFieldsNone` "no suggested fields"; else `sourceTypes.list.suggestedFields` "%lld suggested fields", comment "VoiceOver label for the Associated fields count in the Source types list; argument is the count" (plural variations as `sourceTypes.detail.usage` has them, if it has them).
Check: build; `check-localizable-xcstrings.py` OK.

**F-4 — The archived brief's links resolve** (from CON-1)
Files: `docs/deployment-plan/spike-15/design/archive/S15-D28-source-types-list.md`, `docs/deployment-plan/spike-15/prs/S15-49-source-types-list.review.md`.
Do: as df13d1b11 did for S15-D27: one more `../` on each relative link; `archive/S15-D2-…` and `archive/S15-D27-…` drop `archive/`; `README.md` → `../README.md`. Review log href → `../design/archive/S15-D28-source-types-list.md`.
Check: from `design/archive/`, every non-http link target in the brief exists (`[ -e ]` loop); same for the review log from `prs/`.

**F-5 — Only a non-empty description carries a tooltip** (from UX-2, CON-3b)
Files: `SourceTypesListPane.swift`. Do: `.help` only when `!type.description.isEmpty` (D-3). Check: build.

**F-6 — The Landed note lists the test-infra change** (from CON-3a)
Files: `docs/deployment-plan/spike-15/prs/S15-49-source-types-list.md` § Landed. Do: one bullet: on the user's request (2026-11-15) this PR adds `FakeHold.untilSuspended(_:)` and moves every positive hold wait onto it, fixing a full-suite hang in `SourceTypePageModelTests.aSaveInFlightIsNotHeld` (landed in S15-48); and the spoken labels on the count cells (F-3). Check: `python3 scripts/check-plan-docs.py` on the plan, 0 errors.

Whole round Check: `scripts/check-pr.sh` PASS.

## Round 1 — fix
Head `f4e17f9b4`. Orchestrator gate PASS (xcode-test 79 s); body-level sweep prints only the two negative lines. F-1 – F-4, F-6 done.
F-5: **Resolved in effect, code redundant** — the cell is `.help(type.description.isEmpty ? "" : type.description)`, which equals `.help(type.description)`; an empty `.help("")` shows no tooltip (precedent `SourcesListRow.swift:300` `.help(… ?? "")`). Logged as nit `ORC-1 · SourceTypesListPane.swift:84 · ternary is a no-op; write .help(type.description)`; rides on a Fix plan 2 if round 2 needs one.

## Round 2 — review
Scope `38635f753...f4e17f9b4`. Reviewers: MNT (MNT-1 blocker), CON (CON-1, CON-3 majors), UX (UX-1 major). Not sent: SEC+PRF (no findings).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | blocker | (round 1) | Resolved | body-level sweep prints only the two negative lines; all 12 `FakeHold`s checked |
| MNT-2, CON-2 | MNT, CON | major | (round 1) | Resolved | skill line 21 and both doc comments name `untilSuspended` |
| CON-1 | CON | major | (round 1) | Resolved | all 9 brief links and the review-log link resolve |
| CON-3a | CON | major | (round 1) | Resolved | Landed bullet at plan line 280 |
| UX-1 | UX | major | (round 1) | Resolved | `countCell(_:spoken:)` labels; plural keys |
| UX-2, CON-3b | UX, CON | minor | (round 1) | Resolved in effect | read by orchestrator: empty `.help("")` shows nothing; code redundant (ORC-1) |

No new findings in round 2 (CON, MNT, UX all Clean). No Fix plan 2.

## Finish
Merged `origin/main` @ `ce1dbf761` (S16-27 plan docs only) → `8c21d62cc`. Orchestrator gate PASS (xcode-test 68 s).

## Result
Gate PASS · CI pending · open: none · follow-ups: none · nits open: ORC-1 (`.help` ternary is a no-op) · to user: —

## After ready — user request (2026-11-15)
User, from the running app at a ~1540pt pane: Description should come in earlier; there is plenty of room below Wide. Asked and answered:
- **Approach:** the table's own breakpoint (not always-on: at the 700pt window floor Label and Description would share ~150pt each; not a lower global `widthWideBreakpoint`: every page's Wide layout would move). Amends D-1, D-3's "at Wide", AC-2.2 / AC-2.4 and TL-W2 by the user's decision; the band (D-4, AC-2.1) stays at Wide.
- **Threshold:** Description shows when the table is at least **1200pt** wide.

### Fix plan 3
**F-7 — A table column can show only from a table width** (user request)
Files: `macos/App/DesignSystem/Components/Table/PVTable.swift`, `macos/ProvenenciaTests/PVTableTests.swift`. Skill: `add-ui-component`, `add-swift-test`.
Failing test first: `PVTableTests.optionalColumnShowsFromItsMinimumTableWidth` — three columns, the middle with `minTableWidth: 1200`; `PVTable.shownColumns(columns, tableWidth: 1199).map(\.id) == ["a","c"]`, at `1200` → `["a","b","c"]`, at `0` → `["a","c"]`.
Do: `PVTableColumn` gains `let minTableWidth: CGFloat?` (init parameter `minTableWidth: CGFloat? = nil`, after `width`), doc: "The column shows only while the table is at least this wide; nil always shows. For a column that only adds context (a description), never one that sorts by default or holds the row's name." `PVTable` measures its own width once with `onGeometryChange` (into `@State private var tableWidth: CGFloat = 0`) on the outer container, and a `static func shownColumns(_ columns: [PVTableColumn<Row>], tableWidth: CGFloat) -> [PVTableColumn<Row>]` filters; the header's and `rowView`'s `ForEach(columns)` use the shown list. Nothing else in `PVTable` changes. Existing callers pass nothing (default nil).
Check: the test passes; `PVTableTests` and `MetadataModelTests` stay green.

**F-8 — Description shows from a 1200pt table, at any width class** (user request)
Files: `macos/App/Features/SourceTypes/SourceTypesListPane.swift`, `macos/ProvenenciaTests/SourceTypesModelTests.swift`.
Do: `columns(_ widthClass:)` → `static func columns() -> [PVTableColumn<CatalogSourceType>]`, always `label, description, key, fields, usedBy`; Description gets `minTableWidth: descriptionMinTableWidth` with `static let descriptionMinTableWidth: CGFloat = 1200` beside the other width constants (doc: user, 2026-11-15: the Label and Description share ~360pt each at that width). The pane drops `@Environment(\.pvWidthClass)` (the band in `SourceTypesContent` keeps its own read). Update the struct and `columns()` doc comments ("Description once the table is 1200pt wide"). T-2 `listColumnsFollowTheWidthClass` → rename `listColumnsShowDescriptionFromATableWidth`: ids `["label","description","key","fields","usedBy"]`; only `description` has a `minTableWidth`, equal to 1200; only `description` is not sortable; widths as before.
Check: tests pass; `rg -n 'columns\(\.(regular|wide)\)|pvWidthClass' macos/App/Features/SourceTypes/SourceTypesListPane.swift` prints nothing.

**F-9 — Docs and the plan record the amendment**
Files: `docs/macos-client-patterns.md` § 9, `docs/ideas/wide-layout.md`, the plan (D-1 row and § Landed), `docs/deployment-plan/spike-15/completed.md` (S15-49 paragraph).
Do: § 9: one sentence under rule 3 — a table may show an optional column only from its own width (`PVTableColumn.minTableWidth`), as the Source types list's Description does from 1200pt; the width class still decides bands and page layout. The "List → detail page" row's "the Source types list's Description column" and the rule-3 / wide-layout wording that says Description is "at Wide" → "from a 1200pt table". Plan: add "*(amended by the user 2026-11-15 after review: Description shows from a 1200pt table at any width class, `PVTableColumn.minTableWidth`; see Landed)*" at the end of D-1's Decision cell, and a Landed bullet saying the same with AC-2.2 / AC-2.4 now read against the table width. completed.md: the same change in its paragraph.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-49-source-types-list.md` 0 errors; `rg -n 'Description (column )?at Wide' docs/macos-client-patterns.md docs/ideas/wide-layout.md docs/deployment-plan/spike-15/completed.md` prints nothing.

**ORC-1 rides along:** `SourceTypesListPane.swift` description cell: `.help(type.description.isEmpty ? "" : type.description)` → `.help(type.description)` (empty help shows nothing; precedent `SourcesListRow.swift:300`).

Whole round Check: `scripts/check-pr.sh` PASS.

## Round 3 — fix (user request)
Head `04a804a03`. Orchestrator gate PASS (xcode-test 69 s). F-7, F-8, F-9, ORC-1 done. Deviations: F-7 test written with the code in one pass (it could not compile first); `PVTableShownColumnsTests` is `@MainActor` (swift-warnings).

## Round 3 — review (user-requested change; outside the two-round cap by the user's request)
Scope `ec971b2cd...04a804a03`. Reviewers: CON, MNT, UX (kit change to `PVTable`, `macos/App/**`). Not sent: SEC+PRF — one `onGeometryChange` per table and a filter over ≤ 5 columns; no catalog input.

Round 3 review: CON, MNT, UX all **Clean**; no blocker or major.
Nits (logged): `UX-4 · PVTable.swift:101-103 · minTableWidth doc should rule out any sortable or filterable column` · `UX-5 · PVTable.swift:176 · tableWidth starts at 0; Description may pop in a pass late (manual check)` · `MNT-R3-1 · PVTable.swift:176,226 · measure the shown ids, not the raw width, so a resize redraws only at the threshold` · `MNT-R3-2 · PVTable.swift:13-21 · Contract list should say columns decide whether they show` · `CON-1 · SourceTypesListPane.swift:20 · "~360pt each" is ~330pt` · `CON-2 · plan line 133 · Next adds still names columns(.wide)`
Follow-up candidate (ask user): MNT outside-diff note — `SourcesListColumns.compactBelow` is a second list-width breakpoint in the hand-built Sources list; `PVTableColumn.minTableWidth` is now the kit's.

### Fix plan 4 (comments and code this PR adds; stale-comment rule)
**F-10 — Nits in code this PR added** (UX-4, MNT-R3-1, MNT-R3-2, CON-1, CON-2)
Files: `macos/App/DesignSystem/Components/Table/PVTable.swift`, `macos/App/Features/SourceTypes/SourceTypesListPane.swift`, the plan.
Do: `minTableWidth` doc → "…never a column that sorts or filters, or holds the row's name." `PVTable` measures `[String]` shown ids (Equatable) with `onGeometryChange(for: [String].self) { Self.shownColumns(columns, tableWidth: $0.size.width).map(\.id) }` into `@State private var shownIDs: [String]?`; `shownColumns` filters `columns` by those ids, and until the first measure (`nil`) shows the columns with no `minTableWidth` (keep the static `shownColumns(_:tableWidth:)` and its test). Add one Contract bullet at the top of `PVTable.swift`: columns also decide whether they show (`minTableWidth`), so header and rows always agree. `SourceTypesListPane` comment "~360pt" → "~330pt". Plan line 133: "a later optional column is one more entry with a `minTableWidth`".
Check: `scripts/check-pr.sh` PASS.

## Round 4 — fix
Head `23d546417`. Orchestrator gate PASS (xcode-test 72 s). F-10 done; deviation: `PVTableColumnGate.shownIDs(gates:tableWidth:)` holds the rule as plain values so the Sendable geometry closure captures no generic `columns` (swift-warnings); `shownColumns` delegates to it. Read by orchestrator: UX-4, MNT-R3-1, MNT-R3-2, CON-1, CON-2 **Resolved**.
Orchestrator finding on the read — **ORC-2 · minor · Fix now:** `shownColumns` filters *every* column by the measured `shownIDs`, which only update on a geometry change. A caller whose column set changes while the width holds (a new always-on column) would hide that column until the next resize. No caller does this today (Properties, Metadata, Source types build fixed column lists), but it is a kit contract this PR adds. Also a stray double blank line after `shownColumns(_:tableWidth:)`.

### Fix plan 5
**F-11 — Only gated columns read the measure** (ORC-2)
Files: `macos/App/DesignSystem/Components/Table/PVTable.swift`.
Do: the private `shownColumns` → `columns.filter { $0.minTableWidth == nil || shownIDs?.contains($0.id) == true }` (one expression; drop the `guard`). Remove the extra blank line. Doc on `shownIDs`: "Gated columns only consult it; a column with no `minTableWidth` always shows."
Check: `scripts/check-pr.sh` PASS.

## Round 5 — fix
Head `5135fb8ac`. Orchestrator gate PASS. F-11 read by orchestrator: **Resolved** (ORC-2). `main` unchanged since `ce1dbf761`.

## Result (final)
Gate PASS · CI pending on `5135fb8ac`+ · open: none · follow-ups: one candidate for the user (`SourcesListColumns.compactBelow` vs `PVTableColumn.minTableWidth`) · to user: — (D-1 amended by the user 2026-11-15)

## After ready — user request 2 (2026-11-15)
User, from the running app at ~1440pt: Label takes half the free width but holds short text, so Description truncates too soon; give Description more room. Amends D-3's "sharing the free width equally with Label" (and the board's 562pt each) by the user's decision. Ratio chosen by the orchestrator: **Label 1 : Description 2** (at a 1200pt table about 220 / 440pt; at ~1540pt about 333 / 667pt).
User also asked for a Spike 16 PR to unify own-width breakpoints into one tool: **S16-39** added to the Spike 16 map (row, slice 4a, scope entry) on this branch.

### Fix plan 6
**F-12 — Flexible table columns share the free width by weight** (user request)
Files: `macos/App/DesignSystem/Components/Table/PVTable.swift`, `macos/ProvenenciaTests/PVTableTests.swift` (or the `PVTableShownColumnsTests` file). Skills: `add-ui-component`, `add-swift-test`.
Failing test first: `PVTableColumnsLayoutTests.flexibleColumnsShareTheFreeWidthByWeight` — `PVTableColumnsLayout.widths(fixed: [nil, nil, 100], flex: [1, 2, 1], total: 1000, spacing: 0) == [300, 600, 100]`; with `spacing: 10` and three columns the free width is `1000 − 100 − 20`; all-fixed columns keep their widths; a flex of 0 is treated as 1.
Do: `PVTableColumn` gains `flex: CGFloat = 1` (after `minTableWidth`; doc: "A flexible column's share of the width the fixed columns leave; ignored when `width` is set"). Add `struct PVTableColumnsLayout: Layout` (spacing, per-subview fixed width and flex) with a `static func widths(fixed:flex:total:spacing:) -> [CGFloat]` that the layout calls (S16-35's pattern: placement through a static function tests drive with made-up sizes). The header's and `rowView`'s `HStack(spacing: PVSpacing.space6) { ForEach(shownColumns) … }` become `PVTableColumnsLayout(…) { ForEach(shownColumns) … }` built from `shownColumns`; each cell keeps its `.frame(maxWidth:…, alignment: .leading)` so its content stays leading in the slot it is given; heights as today (the row's tallest cell). Existing callers pass no `flex`, so equal shares as before. Update the Contract bullet on widths.
Check: the new test passes; `PVTableTests`, `MetadataModelTests`, `SourceTypesModelTests` green.

**F-13 — Description takes twice Label's share**
Files: `macos/App/Features/SourceTypes/SourceTypesListPane.swift`, `SourceTypesModelTests.swift`, the plan (D-3 cell and Landed), `docs/deployment-plan/spike-15/completed.md` if it states the split.
Do: the Description column passes `flex: 2` from `static let descriptionFlex: CGFloat = 2` beside the width constants (doc: user, 2026-11-15: labels are short, so Description takes twice Label's share). Fix the "~330pt each" comment to the new split (about 220 / 440pt at a 1200pt table). T-2 also asserts `description` has flex 2 and every other flexible column flex 1. Plan: append to D-3's Decision cell "*(amended by the user 2026-11-15 after review: Description takes twice Label's share, `PVTableColumn.flex`; see Landed)*" and a Landed bullet.
Check: tests pass; `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-49-source-types-list.md` 0 errors.

Whole round Check: `scripts/check-pr.sh` PASS.
