# S15-31 — Event and Place rows open the provenance sheet

**Status:** Planned
**Spike / slice:** Spike 15 · Slice 8 — Provenance loading
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D11](../design/S15-D11-event-page-provenance-sheet.md) (Event page) and [S15-D12](../design/S15-D12-place-page-provenance-sheet.md) (Place page), boards agreed 2026-11-27
**Board:** Event: agreed 2026-11-27 (user) — [Event Detail board](https://claude.ai/artifact/5ciAxv86fYtrUvuCHPuuJ5), page *Event Detail*, turn "S15-D11 · Value rows open the provenance sheet": frames 1a, 1b, 2, 3a, 3b, 4a, 4b, 5, 6 and the notes EP-1, EP-2, EP-4. Place: agreed 2026-11-27 (user) — [Places Detail board](https://claude.ai/artifact/WTfDyrGRH2PEtXyhY2KJtt), page *Place Detail*, turn "S15-D12 · Place page — value rows open the provenance sheet": frames 1a, 1b, 2a, 2b, 3a, 3b, 3c, 4, 5 and the notes PP-1, PP-3, PP-4. The implementer cannot open the boards: **§ 6 macOS** describes each frame in words and lists where the app departs from a board note
**Depends on:** S15-27 (landed [#1006](https://github.com/Jake-Robins-Studios/provenencia/pull/1006)), S15-D11, S15-D12
**Blocks:** S15-29
**Branch:** `s15-31-event-and-place-provenance-sheet`
**Version bump:** minor, the next minor after `main`'s `VERSION` (0.48.2 → 0.49.0 at the planning base): Event and Place rows gain the provenance sheet with its citations and copy buttons, a feature on two screens ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go` and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md) (removed strings), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/design-system-layers.mdc` (a recipe names no `Features/` type), `.cursor/rules/macos-l10n.mdc`, `.cursor/rules/swift-tests.mdc`
**Context:** map scope entry S15-31 ([`../deployment-plan.md`](../deployment-plan.md)); working rules "The Why accordion goes" and "The provenance table folds a page at a time"; [`docs/macos-client-patterns.md`](../../../macos-client-patterns.md) "Detail pages share their rows"; [`../provenance-loading.md`](../provenance-loading.md)
**Host:** macOS with Xcode. Tests: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS'`, narrowed with `-only-testing:ProvenenciaTests/<Suite>` where a Step says so. The implementer runs the manual check in §10.
**Planned:** 2026-11-27 against `main` @ `9d83091`
**Review:** [`S15-31-event-and-place-provenance-sheet.review.md`](S15-31-event-and-place-provenance-sheet.review.md) — Fits with changes · Ready with changes, two rounds, every finding answered

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

On the Event and Place pages, each Details row with records ends with the provenance control the Person page's Vitals rows already have, and pressing it opens the provenance sheet for that row: formatted citations, copy buttons and the 50-record fold. The Why accordion (its button, its inline card and its table) is deleted, with the row mode that chose between the two. A Place's name row, which grows with the catalog, then draws 50 records instead of every record inline.

**Why now.** Working rule "The Why accordion goes" (user, 2026-11-09): the Why is deleted before records leave the page read (S15-28, S15-29), so S15-29 changes one presentation, not two.

**What stays.** Every row's label, value, badge, counts, other-values disclosure, list fold and open arrow; the Place relationship sections; the sheet, its content and its presenter; the records each row lists (`provenanceContent()` is unchanged); the Person page, which looks and behaves as today.

## 2. User stories

**US-1.** As a researcher on an Event page, when I press a row's provenance control, I see that value's records in the provenance sheet, so that I read and copy their citations as on the Person page.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | An Event dated by two as-ofs (3 records on `as_of`), Details | The Date row ends with the ⓘ control "Provenance of Date"; there is no "Why" button |
| AC-1.2 | Press the Date row's control | The sheet opens, title "Date", value header with the two as-of lines, summary "3 records", 3 records in the table |
| AC-1.3 | The same Event's Place row | Empty 28pt slot, no control; the open arrow stays and opens the Place |
| AC-1.4 | An Event with no records on any dating property | "No date recorded", empty slot. A Date row that reads "No date recorded" but holds records (every record denied or unshown) ends with the control (D-10) |
| AC-1.5 | A Date row with 1,200 records | The sheet opens on 50 records and "Show 50 more" |

**US-2.** As a researcher on a Place page, when I press the Names or Period row's control, I see its records in the provenance sheet.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | York: kept names Toronto (3 Sources), Tkaronto (1), a weak "Torento" record | The Names row ends with "Provenance of Names"; no "Why" button |
| AC-2.2 | Press it | The sheet's title is "Names"; its records include the weak "Torento" record |
| AC-2.3 | A Place with no start or end date | Period reads "No period recorded" with an empty slot |
| AC-2.4 | Period "1793–1834" from a start and an end record | "Provenance of Period" opens the sheet with both records |

**US-3.** As a researcher using the keyboard or VoiceOver, I reach and open the control as on the Person page.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Tab through an Event or Place row | Other values (when shown), the open arrow (when shown), then the provenance control; the empty slot is skipped |
| AC-3.2 | Return or Space on the control | The sheet opens; VoiceOver reads the control as "Provenance of Date" |
| AC-3.3 | A record's Citation link in the sheet, then Back | The sheet closes, the composer opens; Back returns to the Event or Place page |

**US-4.** As a contributor, the Why is gone from the code, so the rows have one provenance path.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | The sweep command in §9, run from the repo root | No hit |

## 3. Scope

| In | Covered by |
| --- | --- |
| Every Details row ends with the provenance slot on Person, Event and Place (EP-1, EP-2, EP-2a, PP-1, PP-2) | STEP-1, AC-1.1, AC-1.3, AC-1.4, AC-2.1, AC-2.3 |
| The Why button, card and table go (EP-3, PP-3) | STEP-1, STEP-2, AC-4.1 |
| The sheet opens over Event and Place pages with the row's records, folded (EP-4, EP-5, PP-4, PP-5) | STEP-1, AC-1.2, AC-1.5, AC-2.2, AC-2.4 |
| Leaving the sheet and Back (EP-6, PP-6) | STEP-1 (presenter unchanged), AC-3.3 |
| Keyboard and VoiceOver (EP-7, PP-7) | STEP-1, AC-3.1, AC-3.2 |
| Wide: the pages centered as today, the sheet 1280pt (EP-W1, PP-W1) | STEP-1 (no layout change), §10 |
| `whyTitle` leaves the row model | STEP-2 |
| The reserved column leaves the recipe | STEP-3 |
| The Why strings leave L10n and the String Catalog | STEP-4 |
| Doc comments (Swift, L10n, the `conclusiondetails` Go package), `docs/macos-client-patterns.md` and `docs/conclusion-reconciliation.md` that name the Why | STEP-4, STEP-5, STEP-6 |

| Out | Home |
| --- | --- |
| Records loading when the sheet opens; the row counts from `FieldRecordCounts` | S15-29 |
| `api/proto/engine.proto`'s `PictureDetail` comment ("as the Why shows it") | S15-28, which edits and regenerates the proto; STEP-6 names it in S15-28's scope entry |
| A control on the Place relationship rows or on the Event's Place row | not planned (their records live on the Place the row opens; the briefs' non-goals) |
| A Merged Badge and Source count on span rows (Place Period, Event start–end), and the 28pt end cell on relationship rows, as the Places Detail board draws them | not planned (user, 2026-11-27) |
| Focus returning to the control after Done | not planned here: it behaves as on the Person page (user, 2026-11-27) |
| The `"Why"` sample label in `PVDisclosureButton`'s `#Preview` | not planned (a preview word, not a reference to the removed control) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Row mode | `macos/App/Features/Conclusions/ReconciledValueRow.swift` `ReconciledValueRow.Provenance` (`.why`, `.sheet`), `provenance` (default `.why`), `showsWhy`, `Stop.why`, `firstStop`, `disclosures`, `provenanceSlot` | Two modes; `.why` draws `PVDisclosureButton(L10n.Conclusions.whyButton)` and `ReconciliationReasoningView` under the row; `.sheet` draws `provenanceSlot`. The mode the PR keeps is `.sheet` |
| Section | same file, `ConclusionDetailRowsSection.provenance` (default `.why`), `provenanceItem`, `.pvSheet(item:)` with `ProvenanceSheetHost` | Presents the sheet for any row; only the Person page passes `.sheet` |
| Person page | `macos/App/Features/Conclusions/PersonDetailView.swift` `PersonDetailSections` | Passes `provenance: .sheet` |
| Event and Place pages | `macos/App/Features/Conclusions/ConclusionDetailPage.swift` `ConclusionDetailDefaultPageSections` | `ConclusionDetailRowsSection(rows:refreshing:title:)` with the default `.why`; Event (`EventDetailView.swift`) and Place (`PlaceDetailView.swift`) use this default fill |
| Why card | `macos/App/Features/Conclusions/ReconciliationReasoningView.swift` `ReconciliationReasoningView` | Draws `model.whyTitle` and `ReconciliationRecordRows`; its only caller is the row's `.why` branch |
| Why table | `macos/App/Features/Conclusions/ReconciliationRecordRows.swift` `ReconciliationRecordRows` | Four-column grid with `L10n.Conclusions.whySource` and `PVProvenanceReservedCell`; its only caller is the Why card |
| Row model | `macos/App/Features/Conclusions/ReconciledValueRowModel.swift` `whyTitle` (set in `init(field:)`, `spanning`, `derived`, `empty`, the private `init`); doc comments on `RecordsSource`, `provenanceContent()`, `spanning`, `derived` name the Why | Read only by `ReconciliationReasoningView` and tests |
| Place names | `macos/App/Features/Conclusions/PlaceDetailContent.swift` `namesRow` | Overrides `whyTitle` with `L10n.Conclusions.whyThese` |
| Reserved column | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceParts.swift` `PVProvenanceReservedCell`; `PVProvenanceColumns.swift` `actionWidth` | Drawn only by `ReconciliationRecordRows` (S15-21 D-14 kept them for the Why) |
| Strings | `macos/App/Platform/L10n.swift` `L10n.Conclusions.whySource`, `whyButton`, `whyTitle(_:)`, `whyTitleName(_:)`, `whyThese(_:label:)`, `whyRecords(_:)`; `macos/App/Resources/Localizable.xcstrings` keys `conclusions.why.source`, `conclusions.why.button`, `conclusions.why.title`, `conclusions.why.title.name`, `conclusions.why.these`, `conclusions.why.records` | Read only by the Why code above |
| String comments | `L10n.swift` `readAsNone`, `readAsNot(_:)` and their xcstrings entries `conclusions.readAs.none`, `conclusions.readAs.not`; the doc comments on `enum ProvenanceSheet` ("the Why's table") and `enum Conclusions` ("the Why table") | Name the Why table; the sheet's Read as column uses the two keys (`ReconciledValueDisplay.swift`) |
| Go comments | `core/database/conclusiondetails/conclusiondetails.go` package comment (`the "Why" a detail page shows`, `the Why's reconciler half`); `api/ffi/handlers/conclusion_detail_test.go` comment above the warm-open test ("composes the Why") | Name the Why |
| Doc comments | `EventDetailContent.swift` (type comment, `dateRow`, `placeRow`), `PlaceDetailView.swift` (type comment), `ReconciledValueRow.swift` (type comment, `firstStop`, `openProvenance`), `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheetContent.swift` `PVProvenanceFace`, `macos/App/Platform/DerivedPlace.swift` `shown`, `macos/App/Platform/ReconciledValueDisplay.swift` `outcomeMark` | Name the Why |
| Tests | `EventDetailTests.swift` lines 268 (the as-of row test) and 382, 386 (`undatedRowShowsTheFieldWithRecords`); `PlaceDetailTests.swift` `keptNamesAreAllListedAndAWeakSpellingStaysInTheWhy` (line 69); `PersonDetailTests.swift` `aMergedNameRowCarriesItsStateAndWhy` (lines 414, 422) and `lifeRowsCarryTheirOwnersRecords` (lines 688, 690, 698); `PVProvenanceColumnsTests.swift` line 10 (`actionWidth == 88`) | Assert `whyTitle` and `actionWidth`. The rules this PR relies on are already tested: `ProvenanceSheetTests.theSheetFollowsItsRowAcrossARefresh` (`ProvenanceSheetItem.row(in:)`), `ProvenanceSheetTests.aRowBuildsItsContentOnCall` (sheet title is the row label), `EventDetailTests.swift:267` (as-of Date row has 3 records), `:499`, `:511` (Event Place row has none), `PlaceDetailTests.swift:71–73` (Names holds the weak record). `PlaceDetailTests.periodAndRelationshipsAreStatedEmpty` checks the empty Period's text, not its record count |
| Docs | `docs/macos-client-patterns.md` "Detail pages share their rows (S9-16)"; `docs/conclusion-reconciliation.md` line 175 ("the *Why* view") and the two-birth-Events paragraph ("A derived value's Why lists") | Describe the Why and the `.sheet` mode |

**Precedent.** S13-11 put the Person page's Vitals on `.sheet` mode: the 28pt `provenanceSlot`, one `.pvSheet(item:)` presenter per section holding `ProvenanceSheetItem`, and `ProvenanceSheetHost`. This PR makes that the only mode; copy nothing new, delete the other branch.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `ReconciledValueRow.Provenance` goes with the mode's branches (Deletes). Every row draws `provenanceSlot`; `ConclusionDetailRowsSection` and `PersonDetailSections` stop passing a mode. `openProvenance` becomes `let openProvenance: () -> Void`, no default | One owner of the row's ending, so every page gains the sheet with no mode (feedback: rules over branches); with no default, a row host cannot draw a dead control | Passing `.sheet` from `ConclusionDetailDefaultPageSections` — leaves an enum with one live case |
| D-2 | `whyTitle` goes from the row model, with `namesRow`'s override. The sheet's title stays the row's label, as on the Person page | Its only reader is the Why card | Moving the "Why “1851”" wording into the sheet title — a sheet change no board draws |
| D-3 | The reserved column goes (Deletes) | Its last caller is `ReconciliationRecordRows` (S15-21 D-14) | — |
| D-4 | The six Why strings go (Strings). `readAsNone` and `readAsNot` keep their keys; their comments read "Provenance table, Read as column: the record states nothing for this field" and "Provenance table, Read as column: a negative record saying the value is not this; argument is the value" in `L10n.swift` and the xcstrings `comment`. `enum ProvenanceSheet`'s doc comment ends "read by the sheet and its record rows"; `enum Conclusions`'s reads "field states, auto-reconciler outcomes and the Person page" | Nothing reads the six; the remaining comments name a table that is gone | Keeping unused keys for translators — the catalog would flag them stale |
| D-5 | `ReconciledValueRowModel.hasRecords` *(new)*, `recordCount > 0`, is the one test of "this row offers the sheet": `provenanceSlot`, `firstStop` and `ProvenanceSheetItem.row(in:)` read it. `firstStop` returns `.provenance` when `hasRecords`, else `.others` when the row has other values, else nil; `Stop` loses `.why` | One place changes when S15-29 moves the counts to `FieldRecordCounts` | Three spellings of `recordCount` against 0 |
| D-6 | Accessibility identifiers: `conclusion.detail.row.<id>.provenance` on every page; `conclusion.detail.row.<id>.why` and `conclusion.detail.why.<record>.source` go | No UI test target reads them; one name per control | — |
| D-7 | No new test. Each `whyTitle` assertion in §4 Tests is deleted, keeping the records half of its line; the title rule stays `aRowBuildsItsContentOnCall`'s. One expectation is added for the empty Period (T-1). The visual and keyboard ACs are the manual check | The rules the rows rely on are already tested (§4 Tests); a new case would copy private Event and Place fixtures | A `ProvenanceSheetTests` case over `EventDetailContent` and `PlaceDetailContent` — a second copy of fixtures S15-29 must keep in step; a hosting-view test — no precedent in `ProvenenciaTests` |
| D-8 | The two test functions named for the Why are renamed: `aMergedNameRowCarriesItsStateAndWhy` → `aMergedNameRowCarriesItsStateAndProvenance`, `keptNamesAreAllListedAndAWeakSpellingStaysInTheWhy` → `keptNamesAreAllListedAndAWeakSpellingStaysInTheSheet` (its doc comment: "A weak spelling stays in the sheet's records and is not a displayed name") | The sweep finds no name of a removed control | — |
| D-9 | One PR for both pages | Both pages draw through `ConclusionDetailDefaultPageSections`, so D-1 changes them together | Two PRs — the shared fill cannot change for one page |
| D-10 | The control shows whenever the row has records, whatever its value line says: a Date or Birth date that reads "No date recorded" because every record was denied still opens the sheet (`EventDetailTests.undatedRowShowsTheFieldWithRecords`, `PersonDetailTests.lifeRowsCarryTheirOwnersRecords`) | The sheet is where the researcher sees why nothing shows | Hiding it on an empty value — the denied records would have no view |
| D-11 | The control centers vertically on the row, as `ReconciledValueRow.body`'s `HStack(alignment: .center)` does today; a row of 20 as-of lines or names has it at the middle of the lines | The code needs no change; the briefs (EP-1, PP-1) ask the board to draw it so | Moving it to the first line — a layout change in the shared row, for the Person page too |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `ReconciledValueRowModel.hasRecords` *(new)* | property | `ReconciledValueRowModel.recordCount` | It reads `recordCount`; it names the one rule three call sites spell today (D-5) |

Searched: `ProvenanceSheetItem`, `provenanceSlot`, `recordCount > 0`, `recordCount == 0`, `Provenance\.`, `ReconciliationRecordRows`, `PVProvenanceReservedCell`, `whyTitle` across `macos/`. The PR adds no type, view, key or test helper.

**Builds on.** S13-11's `.sheet` mode (`provenanceSlot`, `ProvenanceSheetItem`, `ProvenanceSheetHost`, `.pvSheet(item:)`), S15-27's fold in `PVProvenanceRecordTable`, `ReconciledValueRowModel.provenanceContent()`.
**Deletes.** `ReconciledValueRow.Provenance`, `ReconciledValueRow.provenance`, `showsWhy`, `Stop.why`, the `.why` branches in `body` and `disclosures`; `ConclusionDetailRowsSection.provenance`; `ReconciliationReasoningView.swift` and `ReconciliationRecordRows.swift` (whole files; the project uses synchronized folders, so `project.pbxproj` lists neither); `ReconciledValueRowModel.whyTitle` and its parameter; `PVProvenanceReservedCell`; `PVProvenanceColumns.actionWidth`; the six strings in Strings; the `whyTitle` and `actionWidth` test assertions; `openProvenance`'s `{}` default.
**Next adds.** S15-29 changes one presentation: every row's sheet takes its records from the on-open read, and `hasRecords` reads `FieldRecordCounts` in one place; nothing on the page still reads `provenanceContent()` outside the sheet.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| An Event or Place row opens the sheet | `ConclusionDetailRowsSection` `.pvSheet(item:)` → `ProvenanceSheetHost` | `ProvenanceSheetItem` holds the row id; `.onChange(of: rows)` closes the sheet when the row leaves or loses its records (`row(in:)` requires `recordCount > 0`). Row ids on one page are unique: Event `date`, `place`; Place `names`, `period` |
| A `.spanning` row in the sheet (Event as-of or span Date; Place Period) | `PVProvenanceSheetContent.spanning` | Already built by the Why from the same `provenanceContent()`; summary "N records", no badge (`theSummarySaysOnlyWhatTheRowKnows`) |
| Event Place row (`.derived` with no owners) | `provenanceSlot` | `recordCount == 0` → empty slot, accessibility hidden |
| A sheet link from an Event or Place page | `WorkspaceLocation.provenance(_:_:)` via `navigation.go`, sheet closed first | As on the Person page; Back returns to the page through its history entry |

### Scale

At the map's Scale (up to 1,200 records on one value; a Place's name row): the sheet draws 50 records (S15-27, timed there at 300 and 1,200) and its on-open render read takes the records' Citation ids (S15-16, timed at 1,200). The page itself draws less than today: no inline table. No write, cache key or loop changes.

### Edges

None — no rule, comparison or algorithm changes. The records each row lists come from `provenanceContent()`, unchanged; only where they are drawn changes.

### Schema

None — no catalog change.

### Go core

Comments only (STEP-5): the `conclusiondetails` package comment and one test comment. No code.

### FFI

None —

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Details row ending | `PVIconButton(.info, size: .sm)` in the 28pt slot | `ReconciledValueRow.provenanceSlot` | Unchanged code, now on every page (EP-1, PP-1) |
| Empty slot | `Color.clear` 28 × 28, accessibility hidden | same | EP-2, PP-2 |
| Sheet | `PVProvenanceSheet` via `ProvenanceSheetHost` | `ConclusionDetailRowsSection` | Unchanged; `PVProvenanceColumns(widthClass:)` gives 880 / 1280pt |
| Why disclosure, card, table, reserved column | — | removed | EP-3, PP-3 |

**Frames in words** (as the boards draw them). Event page, Regular (1102pt pane): header; "Details"; Date row: label column 132pt, the as-of lines with their Source counts, then the ⓘ at the row's right end; Place row: the place name, its open arrow, then an empty 28pt slot so the arrow sits where Date's controls end. Wide: the same column centered at the Regular measure. Place page: the same for Names (the kept names, ⓘ) and Period (the span, ⓘ, or "No period recorded" with an empty slot); the relationship sections below unchanged. The sheet over either page is the Person page's sheet. The sheet sits over the page with no scrim, as on the Person page (board notes EP-4, PP-4). On a tall row the label and the lines keep their top alignment and only the slot centers (EP-1; the row's `summary` keeps its `.firstTextBaseline` alignment and the outer `HStack` centers the slot, as today).

**Where the app departs from the boards** (user, 2026-11-27):

| Board | Draws | The app | Why |
| --- | --- | --- | --- |
| Places Detail, frames 1a, 3c | The Period row with a Merged Badge and "2 Sources"; its sheet summary "merged from 2 Sources · 2 records" | Unchanged: a span row has no badge and no count, and its sheet summary reads "2 records" (`ReconciledValueRowModel.spanning`, `PVProvenanceSheetContent.spanning`) | This PR only replaces the Why with the sheet; a badge for span rows is not planned |
| Places Detail, note PP-3 | An empty 28pt cell at the end of each relationship row | Unchanged: `PlaceRelationshipRow` ends with its chevron | The relationship rows stay as they are |
| Both boards, notes EP-4, PP-4 | Done returns focus to the row's control | Whatever the Person page does today; §10 step 3 notes where focus lands | A focus fix belongs to all three pages and is not this PR |

States: a row with no records shows its empty text and an empty slot; a row whose value is empty but which holds records shows the control (D-10); the control centers on a tall row (D-11); a refresh that removes a row's records closes its open sheet. Accessibility: the control's label and tooltip are `L10n.Conclusions.provenanceOpen(label)`; Tab order follows the row's `HStack` (other values, open arrow, provenance), then the list's Show more below.

### Strings

L10n keys *(new)*: none. Removed: `conclusions.why.source`, `conclusions.why.button`, `conclusions.why.title`, `conclusions.why.title.name`, `conclusions.why.these`, `conclusions.why.records` (members `whySource`, `whyButton`, `whyTitle(_:)`, `whyTitleName(_:)`, `whyThese(_:label:)`, `whyRecords(_:)`). Comment only: `conclusions.readAs.none`, `conclusions.readAs.not` (D-4).

## 7. Steps

**STEP-1 — One row ending on every page**
Files: `macos/App/Features/Conclusions/ReconciledValueRow.swift`, `ReconciledValueRowModel.swift`, `ProvenanceSheetItem.swift`, `PersonDetailView.swift`. Skill: `add-ui-component`.
Do: D-1, D-5, D-6. Remove the enum, the property, `showsWhy`, `Stop.why`, the `.why` branches; draw `provenanceSlot` unconditionally in the row's `HStack`; drop `ConclusionDetailRowsSection.provenance` and the `provenance:` argument at both call sites (`ReconciledValueRow(model:provenance:…)` in the section, `PersonDetailSections`). Add `hasRecords` to `ReconciledValueRowModel.swift` and read it in `provenanceSlot`, `firstStop` and `ProvenanceSheetItem.row(in:)` (`ProvenanceSheetItem.swift`). Doc comments: the type's last clause reads "· disclosures for a mixed field's other values · the provenance control"; `firstStop`: "The row's first disclosure stop: the provenance control when the row has records, else the other values. Nil when the row has neither."; `openProvenance`: "Opens the provenance sheet on this row." `ReconciliationReasoningView` is still compiled but unreferenced after this step.
Check: the app builds (`xcodebuild build -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS'`); `rg -n "provenance: \.sheet|Provenance\.why|enum Provenance|case why" macos/App/Features/Conclusions` finds nothing. (`showsWhy` is not checked by name: `SourceMoveModel.showsWhy` is unrelated and stays.)

**STEP-2 — The Why card, table and title go**
Files: `ReconciliationReasoningView.swift`, `ReconciliationRecordRows.swift` (delete), `ReconciledValueRowModel.swift`, `PlaceDetailContent.swift`, `macos/ProvenenciaTests/EventDetailTests.swift`, `PlaceDetailTests.swift`, `PersonDetailTests.swift`. Skill: `add-swift-test`.
Do: delete both files; D-2 in the model and `namesRow` (the model's comments are STEP-5's). In the tests, delete each `whyTitle` assertion in §4 Tests, keeping the other conditions on its line: `EventDetailTests.swift:386` keeps `none.shown.emptyText == "No date recorded" && none.provenanceContent().records.isEmpty`; `PersonDetailTests.swift:688` keeps `birth.shown.lead != nil`; `:690` keeps `page.rows[3].provenanceContent().records.isEmpty`; lines 268, 382, 414, 422, 698 and `PlaceDetailTests.swift:69` assert only `whyTitle` and are deleted whole; add T-1; rename per D-8.
Check: `xcodebuild test … -only-testing:ProvenenciaTests/EventDetailTests -only-testing:ProvenenciaTests/PlaceDetailTests -only-testing:ProvenenciaTests/PersonDetailTests` passes.

**STEP-3 — The reserved column goes**
Files: `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceParts.swift`, `PVProvenanceColumns.swift`, `macos/ProvenenciaTests/PVProvenanceColumnsTests.swift`.
Do: D-3; the columns test's line 10 becomes `#expect(PVProvenanceColumns.recordWidth == 72)` (T-2).
Check: `-only-testing:ProvenenciaTests/PVProvenanceColumnsTests` passes; `rg -n "PVProvenanceReservedCell|actionWidth" macos` finds nothing.

**STEP-4 — The Why strings go**
Files: `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`. Skill: `add-localized-string`.
Do: D-4.
Check: the app builds with no Swift warning; `rg -n "conclusions\.why|whyButton|whySource|whyTitle|whyThese|whyRecords|Why table|Why's table" macos` finds nothing; `python3 -c "import json;json.load(open('macos/App/Resources/Localizable.xcstrings'))"` succeeds.

**STEP-5 — Comments that name the Why**
Files: as in the table. Comments only; no code changes, and `gofmt` leaves the Go files as they are otherwise.
Do: each comment reads as the table says (the line numbers are the planning base's).

| File · line | Becomes |
| --- | --- |
| `EventDetailContent.swift:5` | "kept date or span (the band) and the places. The date's records open in the provenance sheet from this page's date row." |
| `EventDetailContent.swift:46`, `:48` | "its provenance sheet holds every record behind them"; "whose provenance sheet holds their records" |
| `EventDetailContent.swift:100` | "No provenance control: its records stay on the Place, which the row opens." |
| `PlaceDetailView.swift:4` | "`ConclusionDetailPage`: names, period, parent chain, and" |
| `ReconciledValueRowModel.swift:13–14` | "What the row's records are built from, not the records: the sheet builds them when it opens (`provenanceContent()`)." |
| `ReconciledValueRowModel.swift:120` | "The sheet content of the row, built from its records now." |
| `ReconciledValueRowModel.swift:138`, `:168` | "Its sheet lists every record on those"; "Its sheet lists the owning handles' fields" |
| `PVProvenanceSheetContent.swift:4–5` (`PVProvenanceFace`) | "places in italic. One type for the Details rows and the provenance sheet (S13-36 D-6)." |
| `DerivedPlace.swift:8` | "the open arrow and the sheet's ink all read this one Place." |
| `ReconciledValueDisplay.swift:202` | "so the provenance table reads without" |
| `conclusiondetails.go:5` | "considered, joined to the record's Source: the records a detail page's provenance sheet shows." |
| `conclusiondetails.go:7` | "and the sheet's reconciler half" |
| `conclusion_detail_test.go:316` | "A warm open composes the records and the gallery from the canonical node" |

Check: `rg -nw "Why" macos/App/Features/Conclusions macos/App/DesignSystem/Recipes/ProvenanceSheet macos/App/Platform/DerivedPlace.swift macos/App/Platform/ReconciledValueDisplay.swift core/database/conclusiondetails/conclusiondetails.go api/ffi/handlers/conclusion_detail_test.go` prints exactly two lines, both ordinary words: `PersonRecordLinksContent.swift:10` ("Why the drawing is not the whole read") and `ReconciledValueDisplay.swift:217` ("Why a record's evidence is weak"). Any other line is a comment this step missed.

**STEP-6 — Docs, version and the PR's records**
Files: `docs/macos-client-patterns.md` ("Detail pages share their rows"), `docs/conclusion-reconciliation.md` (line 175 and the two-birth-Events paragraph), `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj` (`MARKETING_VERSION`), `../completed.md`, `../deployment-plan.md` (map row), this plan (status, Landed note), `../design/` (both briefs → `design/archive/`, `design/README.md`).
Do: in `macos-client-patterns.md`, the row bullet reads: every Details row (Person, Event, Place) ends with the provenance `PVIconButton` and `ConclusionDetailRowsSection` presents one `PVProvenanceSheet` for all rows; remove the Why's names and the "`.sheet` mode" wording and the sentence about `ReconciliationRecordRows`. In `conclusion-reconciliation.md`, "the *Why* view do that work" becomes "the provenance sheet do that work" and "A derived value's Why lists" becomes "A derived value's provenance sheet lists". In `../deployment-plan.md`, S15-28's scope entry **Context** names the `PictureDetail` comment in `api/proto/engine.proto` ("as the Why shows it") among what it updates, and its quoted phrase "The Why stays a SQL read" is dropped from that Context (no comment in the code holds it; STEP-5 rewords the package comment). Version per the header. Then the DoD's docs lines, copying the S15-27 precedent: its `completed.md` paragraph, its map-row status "Landed #1006", and S15-D17's `design/README.md` Archived row (brief link, view and date, board link and agreed frames, "S15-31 (#N)").
Check: `rg -n "\bWhy\b" docs/*.md` shows no line about the removed control; `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-31-event-and-place-provenance-sheet.md` reports no errors; `scripts/check-pr.sh` prints `check-pr: PASS`.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Open the provenance sheet from Event and Place rows."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `PlaceDetailTests.swift` `periodAndRelationshipsAreStatedEmpty` (one added expectation) | York with no start or end → `page.rows[1].recordCount == 0` | AC-2.3 |
| T-2 | Swift | `PVProvenanceColumnsTests.swift` (the test at line 10) | `recordWidth == 72` alone; `actionWidth` gone | D-3 |

Every other AC rests on a test that exists today (§4 Tests): AC-1.2 on `EventDetailTests.swift:267` and `ProvenanceSheetTests.aRowBuildsItsContentOnCall`; AC-1.3 on `EventDetailTests.swift:499`, `:511`; AC-1.4 on `undatedRowShowsTheFieldWithRecords`; AC-2.2 on `PlaceDetailTests.swift:71–73`; the sheet opening for a row with records on `theSheetFollowsItsRowAcrossARefresh`.

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `ConclusionAnchorRestoreTests` (constructs `ConclusionDetailRowsSection(rows:refreshing:)`; it never passed the mode, so it compiles unchanged), `ProvenanceSheetTests` (`ProvenanceSheetItem` now reads `hasRecords`), `WorkspaceSessionTests` (`ProvenanceSheetHost`).

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
- [ ] Domain doc updated if a rule in docs/*.md changed: docs/macos-client-patterns.md "Detail pages share their rows"; docs/conclusion-reconciliation.md (derived value's provenance sheet)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

Both briefs, S15-D11 and S15-D12, move to `design/archive/`.

The sweep command (AC-4.1), from the repo root, prints nothing:

```bash
rg -n 'ReconciliationReasoningView|ReconciliationRecordRows|PVProvenanceReservedCell|actionWidth|whyTitle|whyButton|whySource|whyThese|whyRecords|showsWhy|Provenance\.why|conclusions\.why' macos .agents .cursor docs/*.md
```

## 10. Manual check

Use a project with an Event dated by as-ofs from several Sources, a Place cited under two kept names and a weak spelling, and a Place with no period.

1. Open the Event. Details: the Date row ends with ⓘ; no "Why" anywhere; the Place row shows its open arrow and an empty slot, aligned with Date. Hover ⓘ: "Provenance of Date". (AC-1.1, AC-1.3)
2. Click ⓘ. The sheet: title "Date", the as-of lines, the summary, the records; Done closes it. (AC-1.2)
3. Tab to ⓘ, press Space: the sheet opens; press Done and note where focus lands, then compare with the Person page (a difference is a finding). Click a record's Citation: the composer opens; Back returns to the Event page. (AC-3.1, AC-3.2, AC-3.3; with VoiceOver on, the control reads "Provenance of Date")
4. Open the Place. Names ends with ⓘ; the sheet's title is "Names" and lists the weak spelling's record. Open the Place with no period: "No period recorded", empty slot. (AC-2.1 – AC-2.4)
5. On a Place or Event with more than 50 records on one row, the sheet opens on 50 and "Show 50 more". (AC-1.5)
6. Widen the window past 1600pt pane width on both pages: the pages stay centered, the sheet is 1280pt. (EP-W1, PP-W1)
7. Open a Person page: Vitals look and behave as before.
8. Run §9's sweep command: no output. (AC-4.1)

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A test or preview elsewhere passes `provenance:` | STEP-1's build fails at once; remove the argument (it can only have been `.sheet` or `.why`) |
| A future row host forgets `openProvenance` | D-1 removes the default, so it does not compile |

**Stop and report if:**

- The row's `summary` loses its top alignment when the slot is drawn on every row (a tall row's lines no longer start at the top).
- `ConclusionDetailDefaultPageSections` is no longer how Event and Place fill their page, or a third page uses `ConclusionDetailRowsSection` with `.why`.
- A sheet opened from an Event or Place row lists different records than `provenanceContent()` returns for that row.
- The sweep in §9 finds a reader of a removed name outside the files in § 4.

## 12. Open questions

None.

## 13. PR

**Title:** S15-31 — Event and Place rows open the provenance sheet
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-31-event-and-place-provenance-sheet.md`.
