# S15-27 — The provenance table folds a page at a time

**Status:** Landed in [#1006](https://github.com/Jake-Robins-Studios/provenencia/pull/1006) (2026-11-27)
**Spike / slice:** Spike 15 · Slice 8 — Provenance loading
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D17](../design/archive/S15-D17-provenance-table-fold.md), board agreed 2026-11-26. No new brief: the only visual change past the agreed board is a rule between two records that repeat a citation, which only the data-entry case shows (user, 2026-11-27)
**Board:** agreed 2026-11-26 (user) — the [Person page board](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ), page *Vitals*, turn 21 "S15-D17 · Provenance sheet — the record table's fold": frames 21a – 21g, 21i, 21j and the decision notes Kit, RF-4, RF-3, RF-6, Scroll area. The board still governs the fold, with one change (user, 2026-11-27): the fold counts records, not citation runs, so RF-1, RF-3 and RF-5 read "record" for "run" and RF-2 (never split a run) no longer applies. **§ 6 macOS** says where the app departs from a board note
**Depends on:** S15-30 (landed [#996](https://github.com/Jake-Robins-Studios/provenencia/pull/996)), S15-21 (landed [#930](https://github.com/Jake-Robins-Studios/provenencia/pull/930)), S15-D17
**Blocks:** —
**Branch:** `s15-27-provenance-table-fold` (PR [#1006](https://github.com/Jake-Robins-Studios/provenencia/pull/1006), open). Work on top of its head; do not branch again
**Version bump:** patch, already made on the branch: 0.48.1 → 0.48.2 (`VERSION`, `core/version.go`, `MARKETING_VERSION`). The PR keeps that one patch bump and adds none: a long provenance table no longer freezes the sheet, a fix to an existing view; the removed proto field is read only by this app's own store ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md)
**Rules that bind:** `.cursor/rules/design-system-layers.mdc` (a recipe names no `Features/` type), `.cursor/rules/ffi-handlers.mdc`, `.cursor/rules/go-tests.mdc`, `.cursor/rules/swift-tests.mdc`
**Context:** map scope entry S15-27 ([`../deployment-plan.md`](../deployment-plan.md)); working rules "The provenance table folds a page at a time" and "Grouping is by the rendered full citation, computed when read" (withdrawn 2026-11-27); [`../provenance-loading.md`](../provenance-loading.md) "Cap the records a provenance table draws"; [`docs/citation-formats.md`](../../../citation-formats.md) "The batch"; [`docs/macos-client-patterns.md`](../../../macos-client-patterns.md) "Detail pages share their rows"; the ship log [`S15-27-provenance-table-fold.ship.md`](S15-27-provenance-table-fold.ship.md)
**Host:** macOS with Xcode. Tests: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS'`, narrowed with `-only-testing:ProvenenciaTests/<Suite>` where a Step says so; Go: `CGO_ENABLED=1 go test -tags fts5 ./…`. The implementer runs the manual check in §10.
**Planned:** 2026-11-27 against branch `s15-27-provenance-table-fold` @ `8d3290ee4` (which sits on `main` @ `c1035450b`). Read "Check the base" below as this branch head, not `main`
**Review:** [`S15-27-provenance-table-fold.review.md`](S15-27-provenance-table-fold.review.md#reshape-2026-11-27) — reshape: Fits with changes (maintainability) · Ready with changes (executability), one round; every finding Fixed

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

## Landed

- F-1 (review round 1): Return is one sheet-level claim. `pvSheetTakesReturn(_:)` (`PVSheet.swift`) raises a `||`-reduced preference that the sheet chrome puts on `\.pvSheetReturnTaken`; `PVSheetDefaultAction.shortcut(returnTaken:)` is read by `PVFormDialog`'s Confirm and `PVProvenanceSheet`'s Done, and `pvSheetInnerEdit(_:)` raises it too. The table claims Return while any of its stops has focus, so Return goes to Show more or to the focused citation link, not Done. This supersedes D-7 (`doneShortcut(showMoreFocused:)`, `PVProvenanceShowMoreFocusKey`, T-10 `doneGivesUpReturnToShowMore`) and the Out line on Return on a focused citation link firing Done; `PVFormDialogControls.confirmShortcut(innerEditOpen:)` and `\.pvSheetInnerEditOpen` are gone.
- T-7 measured 266 ms at 300 records and 266 ms at 1,200 records in Debug.
- STEP-1 carried a temporary `groupKey` in the preview data; STEP-2 removed it.

## 1. Objective

A value with hundreds or thousands of records opens its provenance sheet quickly. The record table draws its first 50 records and ends with the kit's "Show 50 more" row; each press reveals the next 50 records. Every record is its own row: records that cite the same thing are no longer gathered into citation runs, so the engine's citation group key goes too. Before the fold, 1,200 records took 6691 ms to lay out in a Debug build; the branch's fold brought it to 268 ms ([`provenance-loading.md`](../provenance-loading.md) "Cap").

**Why now.** S15-30 moved the paged fold and `PVShowMoreRow` into the kit; this is the slice's next PR, and S15-31 then opens this sheet from Event and Place rows, where a Place's name row grows with the catalog.

**What stays.** Owner lines and value headings ("1817 · 2 Sources"). A table of 50 records or fewer draws as today, except that two records repeating one citation now have a rule between them. The header's summary counts every record. The Show more row, its Return handling, the scroll after a keyboard press, `Timing.swift` and the layout test already on the branch. Records still arrive with the page (S15-29 moves them).

## 2. User stories

**US-1.** As a researcher, when I open the provenance sheet of a value with 1,200 records, it draws its first 50 records at once, so that I can read them without waiting seconds.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | 120 records under one value, sheet opens | 50 records draw, then "Show 50 more" |
| AC-1.2 | 50 records; or 0 records | Every record draws, no Show more row |
| AC-1.3 | 60 records; records 48 – 53 (1-based) render one full citation | Records 48 – 50 draw, 51 – 53 do not: the cut falls between records that repeat a citation, as between any records (the fold reads no render); "Show 10 more" |
| AC-1.4 | 120 records, Show more pressed twice | 100 records after one press ("Show 20 more"), all 120 and no row after the second |
| AC-1.5 | 1,200 records, first layout timed (T-7) | The scroll area's document height equals the height at 300 records: the fold bounds what draws |
| AC-1.6 | Summary of a value with 1,200 records | "… 1,200 records", unchanged by the fold |

**US-2.** As a researcher reading a sheet with owner lines and value headings, the fold keeps each record under its own line, so that I still see which owner and value a record counted for.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Owner A with 50 records, owner B with 3 | Only A's line and records draw, then the row; after a press, B's line and its 3 records |
| AC-2.2 | One owner, value 1 with 60 records, value 2 with 5 | Value 1's heading and 50 records, then the row; after a press, value 1's other 10 records with no second heading, then value 2's heading and its 5 records |
| AC-2.3 | An owner group with no records, before the cut | Its owner line draws, as today |

**US-3.** As a keyboard user, Show more moves me to what it revealed, so that I keep my place.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Tab past the last shown row's links | Focus reaches "Show 50 more", then Done |
| AC-3.2 | Return on Show more | The page reveals; the sheet stays open; focus is on record 51's citation link, scrolled into view |
| AC-3.3 | A pointer click on Show more | The page reveals; focus and scroll stay where they were |
| AC-3.4 | Close the sheet after two presses, open it again | 50 records and "Show 50 more" |
| AC-3.5 | Show more has focus | Done gives up Return (`doneShortcut(showMoreFocused: true)` is nil); Escape still closes the sheet |

**US-4.** As a researcher, each record is its own row in the order the value lists it, so that two records that cite the same thing (a data-entry case) read as two records.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | Records a, b, c under one value heading; a and c render the same full citation | Rows a, b, c in that order; no rule between the heading and a, a rule before b and before c |
| AC-4.2 | Renders arrive for a's and c's Citations, none for b's | a and c show their formatted citations, b today's line; the order is unchanged |

## 3. Scope

| In | Covered by |
| --- | --- |
| Every record its own row in content order, a rule before each but the first under a line (D-1) | STEP-1, AC-4.1, AC-4.2 |
| The fold rule over the table's records (RF-1, RF-3, RF-8 read for records; D-4) | STEP-1, AC-1.1 – AC-1.4, AC-1.6, AC-2.1 – AC-2.3 |
| The Show more row ending the table, its press and reset; Return on it (RF-4, RF-5, RF-W1) | STEP-1, AC-1.4, AC-3.4, AC-3.5 |
| Keyboard focus and scroll after a press, by record (RF-6, RF-7) | STEP-1, AC-3.1 – AC-3.3 |
| First layout measured at 300 and 1,200 records | STEP-2, AC-1.5 |
| Citation runs and the engine's group key removed: Swift content, store, engine, proto, FFI (D-2) | STEP-1, STEP-2 |
| The working rules, dogfood bar 7, domain docs and kit README say records, not citation runs (D-12) | STEP-3 (map edited at planning) |

| Out | Home |
| --- | --- |
| Records loading when the sheet opens | S15-29 |
| A linear assembly (the denial facts from the engine) | S15-28, S15-29 |
| The Why accordion's own table (`ReconciliationRecordRows`) on Event and Place pages | S15-31 (removed; those rows then open this sheet and get the fold) |
| Return on a focused citation link firing Done (predates this PR) | not planned here; raised to the user from the ship log's follow-up |
| A warning or merge for records that repeat a citation | not planned (user, 2026-11-27: a data-entry case; the app only must not crash) |
| A sheet-specific Show more wording | not planned (user, 2026-11-26: the kit's "Show N more") |
| Lazy rows (`LazyVStack`) in the table | not planned (the working rule chose the fold) |
| The likeness viewer's single record row (`ConclusionPictureViewer`) | not planned (one row, nothing to fold) |
| A new design brief | not planned (user, 2026-11-27; D-13) |

## 4. Current state

Verified at `8d3290ee4`.

| Area | Where | Today |
| --- | --- | --- |
| Content | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheetContent.swift` `Group.ValueGroup.CitationRun`, `ValueGroup.citations`, `ValueGroup.init(heading:citations:)`, the computed `ValueGroup.records` | A value run holds citation runs; `records` is derived from them. Wrong: no runs, the value run holds `records` again |
| Gathering | same file `grouped(by:)` | Sets each record's `rendered` and gathers records by `rendered?.groupKey` into runs. Wrong: the render stays, the gathering goes |
| Fold | same file `RunPosition`, `Folded`, `folded(_:by:pages:)` | Counts citation runs. Wrong: counts records |
| Table | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceRecordTable.swift` `PVProvenanceRecordTable.body`, `drawsRule(runIndex:followsLine:)`, `fold`, `Fold.runs`, `PVProvenanceFocus.citation(RunPosition)` | Loops runs (`id: \.element.key`), a rule before each run, the run's rows in a `VStack` with `.id(position)`, a focus handle on each run's first record. Wrong: per record |
| Kept on the table | same file `followsLine(hasHeading:valueIndex:hasOwner:)`, `PVProvenanceShowMoreFocusKey`, the `PVShowMoreRow` block, `folds`, `focus` | Correct; unchanged apart from D-5's names |
| Preview data | same file `PVProvenancePreviewData.rendered(_:key:)` (private), `formattedGroups` (built from `citations:`), `#Preview("Formatted, fallback and a same-citation run")`; `PVProvenanceSheet.swift` `#Preview("Thirty records")` and `#Preview("Folded, 120 runs")` each build numbered records inline; `macos/ProvenenciaTests/PVProvenanceSheetLayoutTests.swift` `records(_:)` builds the same records with its own copy of the census runs | Passes `groupKey:`, builds a run of two records; three copies of one numbered-record fixture |
| Row | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceRecordRow.swift` `citationFocus` | Correct; unchanged |
| Sheet | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheet.swift` `doneShortcut(showMoreFocused:)`, `.pvScrollsShowMoreReveals()`, `#Preview("Folded, 120 runs")` | Correct but for the preview's name |
| Host | `macos/App/Features/Conclusions/ProvenanceSheetHost.swift` private `grouped(_:handle:)` and the type's doc comment | Calls `content.grouped(by: value.citations)`; the doc says it groups by the engine's key |
| Store type | `macos/App/Platform/GenealogyStore.swift` `CatalogRenderedCitation.groupKey` and its doc comment | The engine's key, read only by `grouped(by:)`; the doc names "the engine's key for grouping" |
| Store map | `macos/App/Platform/GoStore.swift` `renderCitations` | Maps `$0.groupKey` |
| Engine | `core/database/citationrender/render.go` `RenderedCitation.GroupKey`, `groupKey`, the `crypto/sha256`, `encoding/binary`, `encoding/hex` imports, the package doc ("group key") | Computes the key per Citation |
| Proto | `api/proto/engine.proto` `RenderedCitation` `string group_key = 4;` | Carries the key; generated into `api/proto/engine/engine.pb.go` and `macos/App/Platform/Generated/engine.pb.swift` |
| FFI | `api/ffi/handlers/citation_render.go` `RenderCitations` (sets `GroupKey`; doc "with a group key each") | Sends the key |
| Go tests | `core/database/citationrender/render_test.go` `TestGroupKey`, `TestRender` (its `dropsGroup` case and "a stored full text that does not parse" subtest assert `GroupKey`; the `dropsGroup` field comment names the key); `api/ffi/handlers/citation_render_test.go` `TestRenderCitations` (subtest "AC-1.2 equal renders group"; "AC-1.3 …" compares keys) | Assert the key |
| Swift tests | `macos/ProvenenciaTests/CatalogFixtures.swift` `renderedCitation(_:key:full:short:)`; `macos/ProvenenciaTests/ProvenanceSheetTests.swift` (`citationTextFallsBack`, `groupedGathersByEngineKeyWithinARun`, `copyButtonsFollowTheRender`, `ruleFallsBeforeEachRunButTheFirstAfterALine`, the fold tests `foldShowsFiftyRunsThenAPageAtATime` – `foldClampsPastTheEnd`, `doneGivesUpReturnToShowMore`, the private `run`, `runs`, `single`, `runCount`, `runKeys` helpers); `macos/ProvenenciaTests/CatalogSessionStoreTests.swift` `renderCitationsAnswersTheAskedIds`; `macos/ProvenenciaTests/CatalogQueryRegistryTests.swift` `ProvenanceSheetKeyTests.provenanceSheetKeySortsAndFollowsInputs`; `macos/ProvenenciaTests/WorkspaceSessionTests.swift` `ProvenanceSheetSessionTests.releaseDuringALoadNeverLandsOnTheNewHandle`; `macos/ProvenenciaTests/PVProvenanceSheetLayoutTests.swift` `records(_:)` | Pass or assert `key` / `groupKey`; the fold tests build `CitationRun`s |
| Kept test helpers | `macos/ProvenenciaTests/Timing.swift` `bestOfMilliseconds` | Correct; unchanged |
| Version | `VERSION` 0.48.2, `core/version.go`, `MARKETING_VERSION` | Already bumped on the branch |
| Landing docs | `docs/deployment-plan/spike-15/completed.md` (S15-27 paragraph), `docs/deployment-plan/spike-15/design/README.md` (S15-D17 row), the brief in `design/archive/` | Written for the run fold; the brief stays archived |

**Precedent.** The table before S15-21 (`b58e8fbac^`, `PVProvenanceRecordTable.body`) drew one row per record with `index > 0 || !followsLine` deciding the rule: copy that shape, with offset ids (D-5). `b89b67e98` removed a proto field with `reserved 11; reserved "citation_sources";` and regenerated: copy that for `group_key`. The branch's own fold (`folded(_:by:pages:)`, T-1 – T-6) is the shape to keep, walking records instead of runs.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | No citation runs. Every record is its own row, in the content's order within its value run, with a rule before it as before any other row: `drawsRule(recordIndex:followsLine:)` is `recordIndex > 0 \|\| !followsLine`, and `followsLine` is unchanged (no rule directly under an owner line or value heading) (user, 2026-11-27) | Several records under one value from the same property and Source are a data-entry case; the app only must not crash on them (user, 2026-11-27) | Keeping runs for display only — the user withdrew the grouping |
| D-2 | The grouping is removed end to end in this PR: Swift content and table, the store type and map, the engine's key, the proto field, the FFI handler, their tests and fixtures (Deletes) (user, 2026-11-27) | Nothing reads the key once the table stops gathering; a dead wire field is the old mechanism left behind | Leaving the engine's key for a later PR — the user asked for one PR |
| D-3 | Owner lines and value headings stay as today (user, 2026-11-27) | They say which owner and value a record counted for | — |
| D-4 | The fold counts records across the whole sheet in reading order (owner groups → value runs → records): `PVProvenanceRecordTable.fold` stays `PagedFold(limit: 50, minimumHidden: 1)`, pages of `PagedFold.pageSize` (50), and "Show N more" counts records. `folded(_:by:pages:)` stays a pure `nonisolated static` function on `PVProvenanceSheetContent` that calls `fold.shownCount(count:pages:)` once and keeps every record whose sheet index is below it; a value run or owner group is kept when it holds a kept record, or holds no records and no record before it is hidden; a kept value run keeps its heading and a kept group its owner line. It returns the kept groups, the hidden record count and the first hidden record's position (user, 2026-11-27) | The branch's rule with the record as the unit; a shown prefix keeps every index, so `followsLine` and `drawsRule` read the same indices | `PagedFold.shown(_:pages:)` over a flattened list rebuilt into groups — two passes for the same result |
| D-5 | A record is addressed by its place in the whole sheet, `RecordPosition(group:value:record:)`. The table's focus enum is `PVProvenanceFocus` (`.citation(RecordPosition)`, `.showMore`). Loops: groups and value runs by offset as today, records `ForEach(Array(run.records.enumerated()), id: \.offset)`. Each drawn record: the rule when `drawsRule`, then its `PVProvenanceRecordRow` with `citationFocus: PVFieldFocus($focus, equals: .citation(position))` and `.id(position)` on the row. A keyboard press claims `.citation(firstRevealed)` and scrolls `firstRevealed` into view (user, 2026-11-27) | Record ids are not unique in a value run (a spanning row can hold one Observation twice; the data-entry case); positions are, and match between the folded and the whole sheet | `id: \.element.id` — repeats; a handle only on the first revealed record — the revealed set changes with every press |
| D-6 | The fold state is the branch's `@State private var folds = PagedFoldState<Fold>()` with the key renamed to `enum Fold: Hashable { case records }`. It lives as long as the table: closing the sheet, a key change or Read again starts at 0 pages; a refresh that keeps the table keeps its pages, and `shownCount` clamps past the end | `macos-client-patterns.md` "One sectioned detail page": every fold holds a `PagedFoldState` | — |
| D-7 | What §4 marks correct stays unchanged: the Show more row block, the scroll provider, Done giving up Return, the row's `citationFocus` and `Timing.swift` (user, 2026-11-27). The Show more row's `revealed` and `revealedRow` take the record position | Each still applies to a record fold | — |
| D-8 | No new string: the row reads `L10n.DesignSystem.showMoreRowLabel`, its N counting records (user, 2026-11-26) | RF-4, RF-7 | "Show N more records" — a kit parameter for one caller |
| D-9 | `grouped(by:)` becomes `withRenders(_ renders: [String: CatalogRenderedCitation]) -> PVProvenanceSheetContent`: it sets each record's `rendered` to `renders[record.outcome.citationID]` and changes nothing else. `ProvenanceSheetHost`'s private `grouped(_:handle:)` becomes `withRenders(_:handle:)` and calls it; its doc comments say it sets the renders | The name says what it does now, after `WorkspaceLocation.withListSelection(_:)` | Keeping `grouped` — it no longer groups |
| D-10 | The engine drops `RenderedCitation.GroupKey`, `groupKey` and the three imports only it uses; `Render` is otherwise unchanged. The proto drops `group_key` with `reserved 4;` and `reserved "group_key";` on two lines in `RenderedCitation`, as `MetadataWorkspaceEntry` reserves its fields; regenerate with `./scripts/generate-proto.sh` and commit both generated files. `CatalogRenderedCitation` drops `groupKey`, and `GoStore.renderCitations` its mapping | The repo's proto convention keeps the number and the name from reuse | Deleting the line without reserving — a later field could reuse 4 |
| D-11 | `renderedCitation(_:full:short:)` drops its `key` parameter. A test that told two replies apart by key tells them apart by `full`: `ProvenanceSheetKeyTests` passes `full: "other"` to the second reply and expects `citations["a"]?.full.plain == "a"`; `releaseDuringALoadNeverLandsOnTheNewHandle` passes `full: "released"` and `full: "current"` and expects `.full.plain == "current"`. Calls that only passed a key drop it | The render text is the reply's other distinct field | A test-only key — a field the app does not have |
| D-12 | The working rules and dogfood bar 7 were edited at planning (Rules this plan bends); every other doc that names citation runs or the group key is reworded for records in STEP-3, which holds the list. Skills and `.cursor/rules` name none of the removed terms (checked with `rg -i "citation run\|citation group\|groupKey\|group_key" .agents .cursor`) | A rule that re-keys a concept covers its docs (`plan-spike` § 3) | Rewording S15-16's and S15-21's `completed.md` paragraphs and map scope entries — they record what shipped then |
| D-13 | No new brief; the agreed S15-D17 board governs the fold, read for records (user, 2026-11-27) | The only visual change is the rule between two records that repeat a citation | — |
| D-14 | The layout timing stays the branch's T-7: Debug only, prints, and asserts the document height is greater than 0 and equal at 300 and 1,200 records; its fixture drops `groupKey:` | Every record is one row, so equal heights still prove the fold bounds the drawing | — |
| D-15 | One PR, though it spans the engine, proto, FFI and the sheet (user, 2026-11-27: one go) | The key has no reader once the table stops gathering, so it goes in the same change | A Swift PR and an engine PR — the user asked for one |
| D-16 | One numbered-record fixture: `PVProvenancePreviewData.records(_ count: Int, prefix: String = "r", formatted: Bool = false) -> [PVProvenanceSheetContent.Record]` builds record i for i from 1 to count as `record("<prefix>i", readAs: "14 May 1817", title: "Parish register i", detail: "p. i", counted: i % 5 != 0)`, the shape the previews use today, and when `formatted` sets `rendered = rendered(id)`; `rendered(_:)` loses `private`. The two sheet previews, `PVProvenanceSheetLayoutTests.records(_:)` and the fold tests call it | Three copies of one fixture become one, in the preview data the tests already use | A test-only helper — a fourth copy |

**Rules this plan bends.**

| Rule | Bent by | User's answer | Updated |
| --- | --- | --- | --- |
| Working rule "Grouping is by the rendered full citation, computed when read." | D-1, D-2 | Withdrawn (user, 2026-11-27) | At planning: marked **Withdrawn (user, 2026-11-27)** with the reason, after the precedent of "Every placeholder names its level" (**Superseded**) |
| Working rule "The provenance table folds a page at a time." ("counts citation groups, never splitting a group") | D-4 | The fold counts records (user, 2026-11-27) | At planning: "The fold counts records, 50 at a time; owner lines and value headings draw only above shown records" |
| Working rule "Citations render on demand, from SQL." ("the missing fields and a group key") | D-10 | Grouping removed end to end (user, 2026-11-27) | At planning: the group key is named as gone with S15-27 |
| Dogfood bar 7 "One household, one citation." (its first sentence) | D-1 | Withdrawn with the rule (user, 2026-11-27) | At planning: marked withdrawn; its second sentence (the Sources section shows no citations) stays |

## 6. Design

### Codebase fit

Searched: `RunPosition`, `CitationRun`, `grouped(by`, `groupKey`, `GroupKey`, `group_key`, `func with` (Swift naming), `reserved` (engine.proto), `Parish register` (record fixtures).

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `PVProvenanceSheetContent.RecordPosition` *(new)*: `struct RecordPosition: Hashable { var group: Int; var value: Int; var record: Int }` | type | `RunPosition` | The same type for the new unit |
| `PVProvenanceSheetContent.withRenders(_:)` *(new)* | func | `grouped(by:)` | Keeps its render half (D-9) |
| `PVProvenanceRecordTable.drawsRule(recordIndex:followsLine:)` *(new)* | func | `drawsRule(runIndex:followsLine:)` | Same rule, per record (D-1) |
| `PVProvenanceRecordTable.Fold.records` *(new)* | key | `Fold.runs` | Names the unit (D-6) |
| `PVProvenancePreviewData.records(_:prefix:formatted:)` *(new)* | helper | The inline builders in `#Preview("Thirty records")`, `#Preview("Folded, 120 runs")` and `PVProvenanceSheetLayoutTests.records(_:)` | Replaces all three (D-16) |

`Folded` keeps its shape with `firstRevealed: RecordPosition?`; `folded(_:by:pages:)` keeps its signature.

**Builds on.** `PagedFold`, `PagedFoldState` and `PVShowMoreRow` (S15-30); `FocusClaim` through the row; `pvScrollsShowMoreReveals`; the branch's fold, focus, Return handling and timing.
**Deletes.**
- Swift: `PVProvenanceSheetContent.Group.ValueGroup.CitationRun`, `ValueGroup.citations`, both explicit `ValueGroup` initializers and their comments (the value run stores `var records: [Record]`; the memberwise `init(heading:records:)` serves every caller), the gathering in `grouped(by:)`, `CatalogRenderedCitation.groupKey` (its doc comment becomes "One Citation rendered by `renderCitations`: its full and short forms."), `GoStore.renderCitations`'s `groupKey:` argument, `PVProvenancePreviewData.rendered(_:key:)`'s `key` parameter and `private`, the inline record builders of `#Preview("Thirty records")` and the folded preview, and `PVProvenanceSheetLayoutTests.records(_:)`'s copy of the census runs (D-16).
- Engine and wire: `citationrender.RenderedCitation.GroupKey`, `citationrender.groupKey`, `RenderedCitation.group_key` (reserved), the `GroupKey:` field in `handlers.RenderCitations`.
- Tests: `TestGroupKey`; the `GroupKey` assertions in `TestRender` (the `dropsGroup` case keeps its `len(r.Full.Runs) != 0` check; the field's comment becomes "no runs"); the subtest "AC-1.2 equal renders group" of `TestRenderCitations`, and the key comparisons in its "AC-1.3" subtest (the plain-text checks stay); `renderedCitation`'s `key` parameter; `groupedGathersByEngineKeyWithinARun`, `foldNeverSplitsARun` and the private `run`, `runs`, `runKeys` helpers of `ProvenanceSheetTests` (replaced by T-1 – T-9).
- Docs: per STEP-3.
**Next adds.** S15-29 fills the same groups from the on-open read; the fold applies unchanged. S15-31 opens this sheet from Event and Place rows; those tables fold with no further change.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| Two records under one value that render one full citation, now two rows | `PVProvenanceRecordTable`, `PVProvenanceRecordRow` | Resets: none held · Missing: a record with no render shows today's line (`Record.citationText`) · State: two ordinary rows with a rule between (AC-4.1) |
| A table drawn past its first 50 records (pages > 0) | `PVProvenanceRecordTable` | Resets: a new table starts at 0 (D-6) · Missing: a refresh that drops records clamps (`shownCount`), `firstRevealed` is recomputed · State: the row words the remainder |
| Keyboard focus on any record's citation link by position | `PVProvenanceRecordRow` citation link | Resets: the focus value names a position in the folded groups the press revealed · Missing: `firstRevealed` is nil when nothing is hidden · State: the link's focus ring |

### Scale

At the map's Scale (up to 1,200 records on one value; the Check measures 300 and 1,200): `folded` walks every record once per table body, O(records); `withRenders` is O(records), cached per key revision by `conclusionContent` in `ProvenanceSheetHost` as `grouped` was. The draw is bounded at 50 records per page revealed, each one row. The engine does less per Citation (no SHA-256). T-7 measures first layout at both counts; no write, key or cache changes.

### Edges

- **Assumptions.** `followsLine` and `drawsRule` read indices within a group and a value run; a kept prefix keeps them (T-5). Record ids repeat inside a value run, so the record loop keys by offset (D-5). `Group.id` repeats too, so groups stay enumerated by offset.
- **Neighbors.** 50 records: no row (T-4). 51: "Show 1 more" (T-1). Records repeating a citation across the cut: split like any others, since the fold never reads renders (T-1). The cut on a value boundary: the next heading waits for the press (T-3). Two records repeating a citation inside the shown page: two rows with a rule between (T-9).
- **Removed inputs.** A refresh while the sheet is open that removes records: the shown count clamps and `hidden` shrinks; a refresh that changes the Citation ids is a new key and the table starts over (D-6). A record whose Citation is missing from the renders keeps `rendered == nil` and shows today's line (T-8). Focus on a record that a refresh removed falls to the system, as today. A revealed record that opens a new value or owner scrolls into view with no anchor, so its heading can sit just above the visible area; accepted, as the Person page sections scroll.
- **Real data.** None — no table, seed or configuration drives the fold.
- **Untrusted size.** Every page draws at most 50 records, one row each; no unit is larger than a record, so a catalog of many records repeating one citation draws in pages like any other.

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/citationrender` | `RenderedCitation` loses `GroupKey`; `groupKey` and its imports go; the package doc drops "group key" (D-10) |

Errors: none change.

### FFI

`api/proto/engine.proto`: `RenderedCitation` drops `string group_key = 4;` for `reserved 4;` and `reserved "group_key";` (D-10). Handler `api/ffi/handlers/citation_render.go` `RenderCitations` stops setting it; its doc says "the full and short citation of each Citation named, and the Evidence graphs and Sources the read used". Regenerate with `./scripts/generate-proto.sh`.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Record table | Recipe, Extend | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceRecordTable.swift` | Draws `folded(groups, by: Self.fold, pages: folds.pages(.records)).groups` one row per record (D-1, D-5); ends with the rule and the Show more row when `hidden > 0`. The type's doc comment says "a rule between records" |
| Provenance sheet | Recipe, Ship | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheet.swift` | Unchanged but for the preview's name |
| Record row | Recipe, Ship | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceRecordRow.swift` | Unchanged |
| Show more row | Component, Ship | `macos/App/DesignSystem/Components/ShowMoreRow/PVShowMoreRow.swift` | Unchanged |
| Rule before each record and before the row | Component, Ship | `PVDivider` | A normal row rule |

**The board (turn 21), read for records.** 21a/21b: the table scrolled to its foot, a normal row rule, then "Show 50 more" at the table's leading edge under Read as; the summary counts every record; Wide the same at 1280pt. The 50th entry there is a household of three with no rules inside; in the app each of those records is its own row with a rule before it, and the three count as three. 21c: after Return, the next records below, focus ring on the first revealed record's citation link. 21d/21e: 120 records, after one press "Show 20 more", after the next no row. 21f/21g: the fold inside the first of two values, the second value's heading drawn only after the press, no repeated heading. 21i: 12 records, no row. 21j: the spoken label and Tab order (last row's controls → Show more → Done).

**Board notes the app does not copy.** *Kit:* the board draws a ghost small Button; the app uses `PVShowMoreRow`. *RF-4:* the board pads the row 8pt; the app uses `PVSpacing.space3`, the record row's padding. *RF-6:* the board scrolls the revealed row to the top; the app scrolls it into view, as Family and Sources do. *Scroll area:* the board's 498pt is its pane less chrome; the app keeps `recordsMaxHeight` (560).

Previews: `#Preview("Formatted, fallback and a same-citation run")` becomes `#Preview("Formatted, fallback and a repeated citation")`, drawing `formattedGroups` = one group with no owner, `records: [first, second, fallback]` (first and second carry the same render), so the canvas shows the rule between two records that repeat a citation. `#Preview("Folded, 120 runs")` becomes `#Preview("Folded, 120 records")`, same body.

States: a table of 50 records or fewer, no row; loading and failed as S15-21 (the table is not drawn). Accessibility: the row is the button "Show 50 more"; Tab order is the shown rows' controls, the row, then Done; a keyboard press claims `.citation(firstRevealed)`.

### Strings

None — no new or changed copy (D-8). The kit row's N counts records; "Show N more" names no unit.

## 7. Steps

**STEP-1 — Every record is its own row, and the fold counts records**
Files: `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheetContent.swift`, `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceRecordTable.swift`, `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheet.swift` (preview name), `macos/App/Features/Conclusions/ProvenanceSheetHost.swift`, `macos/ProvenenciaTests/ProvenanceSheetTests.swift`. Skills: `add-ui-component`, `add-swift-test`.
Do: in the content, delete `CitationRun`, `citations` and both explicit `ValueGroup` initializers; store `var records: [Record]` on `ValueGroup`. Rename `RunPosition` to `RecordPosition` and make `folded(_:by:pages:)` walk records (D-4); rename `grouped(by:)` to `withRenders(_:)` (D-9). In the table, rename `drawsRule` and `Fold.runs` (Codebase fit), loop records per D-5, update the doc comments on the type, `followsLine`, `drawsRule` and `fold` to say records; rebuild `formattedGroups` and rename the preview (§ 6 macOS); add `PVProvenancePreviewData.records(_:prefix:formatted:)` and drop `private` from `rendered` (D-16). In the sheet, rename the folded preview and make it and `#Preview("Thirty records")` call `records(_:)`. In the host, rename to `withRenders(_:handle:)` and fix its doc comments. Rewrite the tests T-1, T-3 – T-6, T-8, T-9 on `PVProvenancePreviewData.records(_:prefix:)` with two private helpers, `single(_ records:)` and `recordCount(_ groups:)`; delete `foldNeverSplitsARun`; `citationTextFallsBack` and `copyButtonsFollowTheRender` keep passing `key:` until STEP-2.
Check: `-only-testing:ProvenenciaTests/ProvenanceSheetTests` passes; the app builds with no Swift warning; `rg -n "\bCitationRun\b|RunPosition|grouped\(by|citations:\s*\[|\.citations\.(count|isEmpty|prefix|enumerated)" macos/App/DesignSystem macos/App/Features/Conclusions macos/ProvenenciaTests/ProvenanceSheetTests.swift` prints nothing. The press, focus and Tab ACs are checked by hand in §10: tests do not synthesize key events (`add-swift-test`).

**STEP-2 — The engine's group key goes**
Files: `core/database/citationrender/render.go`, `core/database/citationrender/render_test.go`, `api/proto/engine.proto`, `api/proto/engine/engine.pb.go`, `macos/App/Platform/Generated/engine.pb.swift`, `api/ffi/handlers/citation_render.go`, `api/ffi/handlers/citation_render_test.go`, `macos/App/Platform/GenealogyStore.swift`, `macos/App/Platform/GoStore.swift`, `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceRecordTable.swift` (`PVProvenancePreviewData.rendered`), `macos/ProvenenciaTests/CatalogFixtures.swift`, `macos/ProvenenciaTests/ProvenanceSheetTests.swift`, `macos/ProvenenciaTests/CatalogSessionStoreTests.swift`, `macos/ProvenenciaTests/CatalogQueryRegistryTests.swift`, `macos/ProvenenciaTests/WorkspaceSessionTests.swift`, `macos/ProvenenciaTests/PVProvenanceSheetLayoutTests.swift`. Skill: `add-ffi-handler`.
Do: D-10 in Go and the proto, then `./scripts/generate-proto.sh`; delete the Go test code in Deletes; D-10 in the store type and map; D-11 in the fixture and its callers; drop `groupKey:` from `PVProvenancePreviewData.rendered` (now `rendered(_ id: String)`); `PVProvenanceSheetLayoutTests.records(_:)` becomes a call to `PVProvenancePreviewData.records(count, formatted: true)`, and its copy of the census runs goes (D-16).
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/citationrender/... ./api/ffi/...` passes; `CGO_ENABLED=1 go vet -tags fts5 ./api/... ./core/...` clean; `rg -n "GroupKey|groupKey|group_key" core api macos --glob '!*.pb.go' --glob '!*.pb.swift'` prints only the `reserved "group_key";` line in `engine.proto`; `-only-testing:ProvenenciaTests/ProvenanceSheetTests -only-testing:ProvenenciaTests/CatalogSessionStoreTests -only-testing:ProvenenciaTests/ProvenanceSheetKeyTests -only-testing:ProvenenciaTests/ProvenanceSheetSessionTests -only-testing:ProvenenciaTests/PVProvenanceSheetLayoutTests` pass in Debug; T-7's two figures, measured on this record fold, are noted for STEP-3 and the PR description.

**STEP-3 — Docs**
Files: `docs/citation-formats.md`, `docs/deployment-plan/spike-15/provenance-loading.md`, `docs/deployment-plan/spike-15/deployment-plan.md` (the S15-D17 design-track row), `docs/macos-client-patterns.md`, `macos/App/DesignSystem/README.md`, `docs/deployment-plan/spike-15/evidence-explained-citation-map.md`, `docs/deployment-plan/spike-15/completed.md`, `docs/deployment-plan/spike-15/deployment-plan.md` (map row), this plan (status), `docs/deployment-plan/spike-15/design/README.md` (S15-D17 row).
Do: `docs/citation-formats.md` loses "and a group key" in "The batch" and the whole "The group key." paragraph; `docs/macos-client-patterns.md` "Detail pages share their rows" and `macos/App/DesignSystem/README.md` (ProvenanceSheet row) say "folds 50 records at a time"; `evidence-explained-citation-map.md` "What follows" item 2 gains "Withdrawn (user, 2026-11-27): the provenance sheet lists each record on its own row."; the map's S15-D17 design-track row says "50 records". In `provenance-loading.md` "Cap", the shipped line says "a fold of 50 records with the kit's Show more row" with the Debug figures (before 1,558 ms at 300 and 6,691 ms at 1,200; after, STEP-2's T-7 figures), and the "Accepted: a single citation group is never split" line goes; its "**Spike 15** (S15-21)" paragraph becomes "**Spike 15** (S15-21) shows each record's formatted citation, so the rows it draws are longer. Measure the cap with formatted rows." `completed.md`: rewrite the S15-27 paragraph for what ships (records fold 50 at a time; every record its own row, citation runs and the engine's group key gone; Return on Show more; STEP-2's T-7 figures against 6,691 ms before; version 0.48.2). `design/README.md` S15-D17 row: "(50 records, the kit's Show more row)". Then the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-27-provenance-table-fold.md` reports no errors; `python3 scripts/check-plan-docs.py --links docs/citation-formats.md docs/deployment-plan/spike-15/provenance-loading.md docs/deployment-plan/spike-15/completed.md` resolves; `rg -n -i "citation run|citation group|group key" docs/*.md macos/App/DesignSystem/README.md docs/deployment-plan/spike-15/provenance-loading.md docs/deployment-plan/spike-15/design/README.md` prints nothing, and in `docs/deployment-plan/spike-15/deployment-plan.md` hits only the withdrawn rule, the landed S15-16 and S15-21 entries and the map's dated notes.

In the files each step touches, every doc comment that names citation runs, the group key or an old D-ID is reworded for records: among them the content type's doc, `Folded` and `folded`, `PVProvenanceFocus`, `fold`'s "(S15-27 D-1)", the layout suite's "(S15-27 D-9)", `renderedCitation`'s doc in `CatalogFixtures.swift`, and the `engine.proto` comment on `RenderedCitation`.

Steps are three because the reshape is mostly deletion; the size limit is not reached, and the PR stays one PR either way (D-15).

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Fold the provenance table by record, one row per record."; "Drop the engine's citation group key."). No WIP commits.

## 8. Tests

Records in T-1 and T-3 – T-6 are built with `PVProvenancePreviewData.records(_:prefix:)` (D-16); a value run of n records is `.init(heading:records:)`.

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `ProvenanceSheetTests.swift` `foldShowsFiftyRecordsThenAPageAtATime` *(new; replaces `foldShowsFiftyRunsThenAPageAtATime`)* | One group, one value, 120 records: pages 0 → 50 records, hidden 70, `firstRevealed` (0, 0, 50); pages 1 → 100, hidden 20, (0, 0, 100); pages 2 → 120, hidden 0, nil. 51 records, pages 0 → 50, hidden 1 | AC-1.1, AC-1.3, AC-1.4, D-4 |
| T-3 | Swift | `foldKeepsLinesOverShownRecordsOnly` *(new; replaces `foldKeepsLinesOverShownRunsOnly`)* | Owner A 50 records, owner B 3: pages 0 → one group (A), hidden 3, `firstRevealed` (1, 0, 0); pages 1 → both. One owner, value 1 with 60 records and value 2 with 5, both with headings: pages 0 → one value run (heading 1, 50 records); pages 1 → equals the input | AC-2.1, AC-2.2 |
| T-4 | Swift | `foldLeavesASmallTableWhole` (rewritten for records) | 50 records → `groups` equals the input, hidden 0, nil; no groups → empty, hidden 0; an owner group with no values before a group of 60 records → kept at pages 0; one after the cut → dropped until pages 1 | AC-1.2, AC-2.3 |
| T-5 | Swift | `foldKeepsEveryShownPosition` (rewritten for records) | Three owners with mixed value runs, 130 records: for pages 0 – 3, every kept record has the same (group, value, record) and value as in the input, headings match, the kept count is `shownCount`, and `firstRevealed` names the first input record not shown | D-4, D-5 |
| T-6 | Swift | `foldClampsPastTheEnd` (rewritten for records) | 60 records, pages 9 → 60 records, hidden 0, nil | D-6 |
| T-7 | Swift (hosted) | `PVProvenanceSheetLayoutTests.swift` `firstLayoutAt300And1200Records` (kept; fixture per STEP-2) | 300 and 1,200 records at `.ready`: prints first-layout ms (best of 3); the document height is greater than 0 and equal at both | AC-1.5, D-14 |
| T-8 | Swift | `withRendersSetsEachRecordsRender` *(new; replaces `groupedGathersByEngineKeyWithinARun`)* | Records a, b, c (Citations ca, cb, cc) in one value; renders for ca and cc with the same `full` text → `records.map(\.id) == ["a", "b", "c"]`, a's and c's `rendered` set; renders for ca only → b and c have `rendered == nil`, order unchanged | AC-4.2, D-9 |
| T-9 | Swift | `ruleFallsBeforeEachRecordButTheFirstAfterALine` *(new; replaces `ruleFallsBeforeEachRunButTheFirstAfterALine`)* | `drawsRule` and `followsLine` only: under a heading, no rule before record 0, a rule before records 1 and 2; the owner line leads only the group's first value; no heading and no owner, a rule before record 0 | AC-4.1, D-1 |
| T-10 | Swift | `doneGivesUpReturnToShowMore` (kept) | `true` → nil; `false` → `.defaultAction` | AC-3.5, D-7 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `ProvenanceSheetTests`, `TestRender` and `TestRenderCitations` (the removed assertions), `ProvenanceSheetKeyTests` and `ProvenanceSheetSessionTests` (D-11), `CatalogListMergeTests` (`Timing.swift`), `PVShowMoreRowTests`, `ConclusionPictureViewer` previews.

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
- [ ] Domain doc updated if a rule in docs/*.md changed: STEP-3's docs
- [ ] PR description: what shipped, AC evidence, the before (1,558 / 6,691 ms) and after (STEP-2's T-7) first-layout figures, Debug, 300 and 1,200 records, deviations, manual check
```

The version is already 0.48.2 on the branch; the brief is already in `design/archive/`; the map row goes from `Planned` to `Landed #1006` on merge.

## 10. Manual check

No fixture holds a value of more than 50 records, so the press, focus and Tab checks run in the `#Preview("Folded, 120 records")` canvas in live mode, and in the app when the reviewer's project has such a value. AC-2.1 – AC-2.3 rest on T-3 and T-4; AC-4.x on T-8 and T-9 and step 6.

1. Open `#Preview("Folded, 120 records")` live. See 50 records and "Show 50 more" at the table's foot (AC-1.1).
2. Tab through the last rows: focus reaches "Show 50 more", then Done (AC-3.1). Press Return: the next page draws, the sheet stays open, focus is on record 51's citation link and it is in view (AC-3.2, AC-3.5).
3. Click Show more with the pointer: the page draws, focus and scroll stay (AC-3.3). Press until the row goes: "Show 20 more", then none (AC-1.4).
4. In the app (Run, Debug), open any value's provenance sheet: a value of 50 records or fewer draws as before (AC-1.2). If the project has a value of more than 50 records, open it: 50 records, the row, the summary counting every record (AC-1.6); close and open it again: 50 records (AC-3.4).
5. Repeat step 4 at Wide (window over 1600pt): the same, at 1280pt (RF-W1).
6. Open `#Preview("Formatted, fallback and a repeated citation")`: three rows, a rule between the two that repeat a citation, the fallback row with today's line (AC-4.1, AC-4.2).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A table that loads again (Read again, a key change) forgets the pages revealed | Accepted by D-6: a reload is a new read |
| `generate-proto.sh` needs `protoc`, `protoc-gen-go` and `protoc-gen-swift` | The script names each missing tool; install it as the script says |

**Stop and report if:**

- `PVProvenanceRecordTable`, `folded(_:by:pages:)` or `grouped(by:)` no longer match §4 at the branch head (someone moved the branch).
- Anything outside the files in §4 reads `CatalogRenderedCitation.groupKey`, `ValueGroup.citations` or `CitationRun` (`rg` before STEP-1).
- `./scripts/generate-proto.sh` changes generated code beyond `RenderedCitation` (a toolchain version drift): report the diff stat.
- T-7's document heights differ at 300 and 1,200 records, or are 0.
- The board or a test asks to draw two records that repeat a citation without a rule between them.

## 12. Open questions

None.

## 13. PR

**Title:** S15-27 — The provenance table folds a page at a time
**Body:** objective in one sentence; what shipped against each US; that citation runs and the engine's group key are gone (user, 2026-11-27); AC evidence; the before and after first-layout figures; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-27-provenance-table-fold.md`.
