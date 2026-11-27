# S15-31 — Event and Place rows open the provenance sheet

**Status:** Blocked — on boards S15-D11 and S15-D12
**Spike / slice:** Spike 15 · Slice 8 — Provenance loading
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D11](../design/S15-D11-event-page-provenance-sheet.md) (Event page) and [S15-D12](../design/S15-D12-place-page-provenance-sheet.md) (Place page), boards not agreed yet
**Board:** — (not drawn yet). Event: the [Event Detail board](https://claude.ai/artifact/5ciAxv86fYtrUvuCHPuuJ5), page *Event Detail*, a new turn after "S16-D6 · As-of dates". Place: the [Places Detail board](https://claude.ai/artifact/WTfDyrGRH2PEtXyhY2KJtt), page *Place Detail*. Until a board is agreed, **§ 6 macOS** describes each frame in words
**Depends on:** S15-27 (landed [#1006](https://github.com/Jake-Robins-Studios/provenencia/pull/1006)), S15-D11, S15-D12
**Blocks:** S15-29
**Branch:** `s15-31-event-and-place-provenance-sheet`
**Version bump:** minor, the next minor after `main`'s `VERSION` (0.48.2 → 0.49.0 at the planning base): Event and Place rows gain the provenance sheet with its citations and copy buttons, a feature on two screens ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go` and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md) (removed strings), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/design-system-layers.mdc` (a recipe names no `Features/` type), `.cursor/rules/macos-l10n.mdc`, `.cursor/rules/swift-tests.mdc`
**Context:** map scope entry S15-31 ([`../deployment-plan.md`](../deployment-plan.md)); working rules "The Why accordion goes" and "The provenance table folds a page at a time"; [`docs/macos-client-patterns.md`](../../../macos-client-patterns.md) "Detail pages share their rows"; [`../provenance-loading.md`](../provenance-loading.md)
**Host:** macOS with Xcode. Tests: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS'`, narrowed with `-only-testing:ProvenenciaTests/<Suite>` where a Step says so. The implementer runs the manual check in §10.
**Planned:** 2026-11-27 against `main` @ `9d83091`
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
| AC-1.4 | An Event with nothing recorded on its dating | "No date recorded", empty slot |
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
| AC-4.1 | `rg -n "ReconciliationReasoningView\|ReconciliationRecordRows\|PVProvenanceReservedCell\|actionWidth\|whyTitle\|whyButton\|whySource\|whyThese\|whyRecords\|showsWhy\|Provenance\.why\|conclusions\.why" macos .agents .cursor docs/*.md` | No hit |

## 3. Scope

| In | Covered by |
| --- | --- |
| Every Details row ends with the provenance slot on Person, Event and Place (EP-1, EP-2, PP-1, PP-2) | STEP-1, AC-1.1, AC-1.3, AC-1.4, AC-2.1, AC-2.3 |
| The Why button, card and table go (EP-3, PP-3) | STEP-1, STEP-2, AC-4.1 |
| The sheet opens over Event and Place pages with the row's records, folded (EP-4, EP-5, PP-4, PP-5) | STEP-1, AC-1.2, AC-1.5, AC-2.2, AC-2.4 |
| Leaving the sheet and Back (EP-6, PP-6) | STEP-1 (presenter unchanged), AC-3.3 |
| Keyboard and VoiceOver (EP-7, PP-7) | STEP-1, AC-3.1, AC-3.2 |
| Wide: the pages centered as today, the sheet 1280pt (EP-W1, PP-W1) | STEP-1 (no layout change), §10 |
| `whyTitle` leaves the row model | STEP-2 |
| The reserved column leaves the recipe | STEP-3 |
| The Why strings leave L10n and the String Catalog | STEP-4 |
| Doc comments, `docs/macos-client-patterns.md` and `docs/conclusion-reconciliation.md` that name the Why | STEP-5, STEP-7 |

| Out | Home |
| --- | --- |
| Records loading when the sheet opens; the row counts from `FieldRecordCounts` | S15-29 |
| The `conclusiondetails` package comment ("the Why a detail page shows") and `api/proto/engine.proto`'s `PictureDetail` comment ("as the Why shows it"), and `api/ffi/handlers/conclusion_detail_test.go`'s comment | S15-28, which rewrites that package comment and regenerates the proto |
| A control on the Place relationship rows or on the Event's Place row | not planned (their records live on the Place the row opens; the briefs' non-goals) |
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
| String comments | `L10n.swift` `readAsNone`, `readAsNot(_:)` and their xcstrings entries `conclusions.readAs.none`, `conclusions.readAs.not` | Comments say "Why table, Read as column"; the sheet's Read as column uses them (`ReconciledValueDisplay.swift`) |
| Doc comments | `EventDetailContent.swift` (type comment, `dateRow`, `placeRow`), `PlaceDetailView.swift` (type comment), `ReconciledValueRow.swift` (type comment), `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheetContent.swift` `PVProvenanceFace`, `macos/App/Platform/DerivedPlace.swift` `shown`, `macos/App/Platform/ReconciledValueDisplay.swift` `outcomeMark` | Name the Why |
| Tests | `macos/ProvenenciaTests/EventDetailTests.swift` (lines asserting `whyTitle`), `PlaceDetailTests.swift` `keptNamesAreAllListedAndAWeakSpellingStaysInTheWhy`, `PersonDetailTests.swift` `aMergedNameRowCarriesItsStateAndWhy` and the derived-row test asserting `whyTitle`, `PVProvenanceColumnsTests.swift` (`actionWidth == 88`), `ProvenanceSheetTests.swift` `theSheetFollowsItsRowAcrossARefresh` | `whyTitle` and `actionWidth` assertions break when those go |
| Docs | `docs/macos-client-patterns.md` "Detail pages share their rows (S9-16)"; `docs/conclusion-reconciliation.md` (the two-birth-Events paragraph) | Describe the Why and the `.sheet` mode |

**Precedent.** S13-11 put the Person page's Vitals on `.sheet` mode: the 28pt `provenanceSlot`, one `.pvSheet(item:)` presenter per section holding `ProvenanceSheetItem`, and `ProvenanceSheetHost`. This PR makes that the only mode; copy nothing new, delete the other branch.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `ReconciledValueRow.Provenance` goes. Every row draws `provenanceSlot`; `ConclusionDetailRowsSection` loses its `provenance` parameter; `PersonDetailSections` stops passing it | One owner of the row's ending, so every page gains the sheet with no mode (feedback: rules over branches) | Passing `.sheet` from `ConclusionDetailDefaultPageSections` — leaves an enum with one live case |
| D-2 | `whyTitle` goes from `ReconciledValueRowModel` (stored property, every assignment, the private `init`'s parameter), with `namesRow`'s override. The sheet's title stays the row's label, as on the Person page | Its only reader is the Why card | Moving the "Why “1851”" wording into the sheet title — a sheet change no board draws |
| D-3 | `PVProvenanceReservedCell` and `PVProvenanceColumns.actionWidth` go | Their last caller is `ReconciliationRecordRows` (S15-21 D-14) | — |
| D-4 | The six `L10n.Conclusions.why*` members and their six String Catalog entries go. `readAsNone` and `readAsNot` keep their keys; their comments read "Provenance table, Read as column: the record states nothing for this field" and "Provenance table, Read as column: a negative record saying the value is not this; argument is the value" in both `L10n.swift` and the xcstrings `comment` | Nothing reads the six; the two remaining comments name a table that is gone | Keeping unused keys for translators — the catalog would flag them stale |
| D-5 | `firstStop` returns `.provenance` when the row has records, else `.others` when it has other values, else nil; `Stop` loses `.why` | The Show more `revealed` stop already follows `firstStop` | — |
| D-6 | Accessibility identifiers: `conclusion.detail.row.<id>.provenance` on every page; `conclusion.detail.row.<id>.why` and `conclusion.detail.why.<record>.source` go | No UI test target reads them; one name per control | — |
| D-7 | Tests stay at the model layer: each removed `whyTitle` assertion becomes an assertion on `provenanceContent().title`, and a new `ProvenanceSheetTests` case checks which Event and Place rows a `ProvenanceSheetItem` resolves (§ 8). The visual and keyboard ACs are the manual check | The repo does not test view trees; `ProvenanceSheetItem.row(in:)` is the rule that decides whether a sheet can open | A hosting-view test for the control's presence — no precedent in `ProvenenciaTests` |
| D-8 | The two test functions named for the Why are renamed: `aMergedNameRowCarriesItsStateAndWhy` → `aMergedNameRowCarriesItsStateAndProvenance`, `keptNamesAreAllListedAndAWeakSpellingStaysInTheWhy` → `keptNamesAreAllListedAndAWeakSpellingStaysInTheSheet` (and its doc comment) | The sweep in the DoD finds no name of a removed control | — |
| D-9 | One PR for both pages | Both pages draw through `ConclusionDetailDefaultPageSections`, so D-1 changes them together; splitting would ship one page with the Why still on the other | Two PRs — the map row is one PR, and the shared fill cannot change for one page |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `ProvenanceSheetTests.eventAndPlaceRowsOpenTheSheetWhenTheyHaveRecords` *(new)* | test | `ProvenanceSheetTests.theSheetFollowsItsRowAcrossARefresh` | A new case beside it in the same suite, built with `EventDetailContent` and `PlaceDetailContent` |

Searched: `ProvenanceSheetItem`, `provenanceSlot`, `Provenance\.`, `ReconciliationRecordRows`, `PVProvenanceReservedCell`, `whyTitle` across `macos/`. The PR adds no type, view, key or helper.

**Builds on.** S13-11's `.sheet` mode (`provenanceSlot`, `ProvenanceSheetItem`, `ProvenanceSheetHost`, `.pvSheet(item:)`), S15-27's fold in `PVProvenanceRecordTable`, `ReconciledValueRowModel.provenanceContent()`.
**Deletes.** `ReconciledValueRow.Provenance`, `ReconciledValueRow.provenance`, `showsWhy`, `Stop.why`, the `.why` branches in `body` and `disclosures`; `ConclusionDetailRowsSection.provenance`; `ReconciliationReasoningView.swift` and `ReconciliationRecordRows.swift` (whole files; the project uses synchronized folders, so `project.pbxproj` lists neither); `ReconciledValueRowModel.whyTitle` and its parameter; `PVProvenanceReservedCell`; `PVProvenanceColumns.actionWidth`; the six strings in Strings; the `whyTitle` and `actionWidth` test assertions.
**Next adds.** S15-29 changes one presentation: every row's sheet takes its records from the on-open read; nothing on the page still reads `provenanceContent()` outside the sheet.

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

None — Swift only.

### FFI

None —

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Details row ending | `PVIconButton(.info, size: .sm)` in the 28pt slot | `ReconciledValueRow.provenanceSlot` | Unchanged code, now on every page (EP-1, PP-1) |
| Empty slot | `Color.clear` 28 × 28, accessibility hidden | same | EP-2, PP-2 |
| Sheet | `PVProvenanceSheet` via `ProvenanceSheetHost` | `ConclusionDetailRowsSection` | Unchanged; `PVProvenanceColumns(widthClass:)` gives 880 / 1280pt |
| Why disclosure, card, table, reserved column | — | removed | EP-3, PP-3 |

**Frames in words** (until the boards are agreed). Event page, Regular (1102pt pane): header; "Details"; Date row: label column 132pt, the as-of lines with their Source counts, then the ⓘ at the row's right end; Place row: the place name, its open arrow, then an empty 28pt slot so the arrow sits where Date's controls end. Wide: the same column centered at the Regular measure. Place page: the same for Names (the kept names, ⓘ) and Period (the span, ⓘ, or "No period recorded" with an empty slot); the relationship sections below unchanged. The sheet over either page is the Person page's sheet. If an agreed board places anything differently, stop (§ 11).

States: a row with no records shows its empty text and an empty slot; a refresh that removes a row's records closes its open sheet. Accessibility: the control's label and tooltip are `L10n.Conclusions.provenanceOpen(label)`; Tab order follows the row's `HStack` (other values, open arrow, provenance), then the list's Show more below.

### Strings

L10n keys *(new)*: none. Removed: `conclusions.why.source`, `conclusions.why.button`, `conclusions.why.title`, `conclusions.why.title.name`, `conclusions.why.these`, `conclusions.why.records` (members `whySource`, `whyButton`, `whyTitle(_:)`, `whyTitleName(_:)`, `whyThese(_:label:)`, `whyRecords(_:)`). Comment only: `conclusions.readAs.none`, `conclusions.readAs.not` (D-4).

## 7. Steps

**STEP-1 — One row ending on every page**
Files: `macos/App/Features/Conclusions/ReconciledValueRow.swift`, `PersonDetailView.swift`. Skill: `add-ui-component`.
Do: D-1, D-5, D-6. Remove the enum, the property, `showsWhy`, `Stop.why`, the `.why` branches; draw `provenanceSlot` unconditionally in the row's `HStack`; drop `ConclusionDetailRowsSection.provenance` and the `provenance:` argument at both call sites (`ReconciledValueRow(model:provenance:…)` in the section, `PersonDetailSections`). Rewrite the row's and the enum-free type's doc comments to name the provenance control and sheet. `ReconciliationReasoningView` is still compiled but unreferenced after this step.
Check: the app builds (`xcodebuild build -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS'`); `rg -n "provenance: \.sheet|Provenance\.why|showsWhy" macos/App` finds nothing.

**STEP-2 — The Why card, table and title go**
Files: `ReconciliationReasoningView.swift`, `ReconciliationRecordRows.swift` (delete), `ReconciledValueRowModel.swift`, `PlaceDetailContent.swift`, `macos/ProvenenciaTests/EventDetailTests.swift`, `PlaceDetailTests.swift`, `PersonDetailTests.swift`. Skill: `add-swift-test`.
Do: delete both files; D-2 in the model and `namesRow`; reword the model's doc comments that say "Why" to "sheet". In the tests, replace each `whyTitle` assertion as § 8 T-1 – T-3 say, and rename per D-8.
Check: `xcodebuild test … -only-testing:ProvenenciaTests/EventDetailTests -only-testing:ProvenenciaTests/PlaceDetailTests -only-testing:ProvenenciaTests/PersonDetailTests` passes.

**STEP-3 — The reserved column goes**
Files: `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceParts.swift`, `PVProvenanceColumns.swift`, `macos/ProvenenciaTests/PVProvenanceColumnsTests.swift`.
Do: D-3; drop `actionWidth` from the columns test's expectation (T-5).
Check: `-only-testing:ProvenenciaTests/PVProvenanceColumnsTests` passes; `rg -n "PVProvenanceReservedCell|actionWidth" macos` finds nothing.

**STEP-4 — The Why strings go**
Files: `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`. Skill: `add-localized-string`.
Do: D-4.
Check: the app builds with no Swift warning; `rg -n "conclusions\.why|whyButton|whySource|whyTitle|whyThese|whyRecords" macos` finds nothing; `python3 -c "import json;json.load(open('macos/App/Resources/Localizable.xcstrings'))"` succeeds.

**STEP-5 — Doc comments that name the Why**
Files: `EventDetailContent.swift`, `PlaceDetailView.swift`, `PVProvenanceSheetContent.swift` (`PVProvenanceFace`), `macos/App/Platform/DerivedPlace.swift`, `macos/App/Platform/ReconciledValueDisplay.swift`.
Do: reword each comment listed in § 4 "Doc comments" to the provenance sheet (for example `EventDetailContent.placeRow`: "No provenance control: its records stay on the Place, which the row opens"). Comments only.
Check: `rg -n "\bWhy\b|the Why" macos/App/Features/Conclusions macos/App/DesignSystem/Recipes/ProvenanceSheet macos/App/Platform/DerivedPlace.swift macos/App/Platform/ReconciledValueDisplay.swift` returns only sentences where "why" is an ordinary word, not the control.

**STEP-6 — The sheet test for Event and Place rows**
Files: `macos/ProvenenciaTests/ProvenanceSheetTests.swift`. Skill: `add-swift-test`.
Do: add T-4.
Check: `-only-testing:ProvenenciaTests/ProvenanceSheetTests` passes.

**STEP-7 — Docs, version and the PR's records**
Files: `docs/macos-client-patterns.md` ("Detail pages share their rows"), `docs/conclusion-reconciliation.md` (the two-birth-Events paragraph), `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj` (`MARKETING_VERSION`), `../completed.md`, `../deployment-plan.md` (map row), this plan (status, Landed note), `../design/` (both briefs → `design/archive/`, `design/README.md`).
Do: in `macos-client-patterns.md`, the row bullet reads: every Details row (Person, Event, Place) ends with the provenance `PVIconButton` and `ConclusionDetailRowsSection` presents one `PVProvenanceSheet` for all rows; remove the Why's names and the "`.sheet` mode" wording and the sentence about `ReconciliationRecordRows`. In `conclusion-reconciliation.md`, "A derived value's Why lists" becomes "A derived value's provenance sheet lists". Version per the header. Then the DoD's docs lines.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-31-event-and-place-provenance-sheet.md` reports no errors; `scripts/check-pr.sh` prints `check-pr: PASS`.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Open the provenance sheet from Event and Place rows."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `EventDetailTests.swift`, the as-of Date row test and the dating-fields test (the ones asserting `whyTitle`) | `row.whyTitle == "Why “as of …”"` → `row.provenanceContent().title == "Date"`; `both.whyTitle == "Why “Date”"` → `both.provenanceContent().title == "Date"`; `none.whyTitle == ""` dropped (the records-empty half stays) | AC-1.2, AC-1.4, D-2 |
| T-2 | Swift | `PlaceDetailTests.swift` `keptNamesAreAllListedAndAWeakSpellingStaysInTheSheet` (renamed) | `names.whyTitle == "Why these 2 names"` → `names.provenanceContent().title == "Names"`; the `letter` record assertion stays | AC-2.2, D-2, D-8 |
| T-3 | Swift | `PersonDetailTests.swift` `aMergedNameRowCarriesItsStateAndProvenance` (renamed) and the derived birth-date test | each `whyTitle` assertion → `provenanceContent().title` equals the row's label ("Name" row: its `label`; `birth`, `empty`: "Birth date"); `page.rows[3].whyTitle == ""` dropped (its records-empty half stays) | D-2, D-8 |
| T-4 | Swift | `ProvenanceSheetTests.swift` `eventAndPlaceRowsOpenTheSheetWhenTheyHaveRecords` *(new)* | `EventDetailContent` with an as-of dating (3 records): `ProvenanceSheetItem(id: "date").row(in:)` is the Date row with `recordCount == 3`; `ProvenanceSheetItem(id: "place").row(in:)` is nil. `PlaceDetailContent` with York's toponyms: `"names"` resolves with the weak record among its records; a Place with no start or end: `"period"` is nil | AC-1.2, AC-1.3, AC-2.2, AC-2.3 |
| T-5 | Swift | `PVProvenanceColumnsTests.swift` (the test at line 10) | `recordWidth == 72` alone; `actionWidth` gone | D-3 |

Build T-4's fixtures with the helpers the Event and Place suites already use (`ReconciledValueDisplayTests` `D.field`, `D.outcome`; `EventDetailTests`' dating fixture; `PlaceDetailTests`' `content(detail(...))`); if those are `private` to their suites, copy the smallest fixture into T-4 rather than widening their access.

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `ConclusionAnchorRestoreTests` (constructs `ConclusionDetailRowsSection(rows:refreshing:)`; it compiles unchanged once the parameter goes because it never passed it), `ProvenanceSheetTests`, `WorkspaceSessionTests` (`ProvenanceSheetHost`).

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

## 10. Manual check

Use a project with an Event dated by as-ofs from several Sources, a Place cited under two kept names and a weak spelling, and a Place with no period.

1. Open the Event. Details: the Date row ends with ⓘ; no "Why" anywhere; the Place row shows its open arrow and an empty slot, aligned with Date. Hover ⓘ: "Provenance of Date". (AC-1.1, AC-1.3)
2. Click ⓘ. The sheet: title "Date", the as-of lines, the summary, the records; Done closes it. (AC-1.2)
3. Tab to ⓘ, press Space: the sheet opens. Click a record's Citation: the composer opens; Back returns to the Event page. (AC-3.1, AC-3.2, AC-3.3; with VoiceOver on, the control reads "Provenance of Date")
4. Open the Place. Names ends with ⓘ; the sheet's title is "Names" and lists the weak spelling's record. Open the Place with no period: "No period recorded", empty slot. (AC-2.1 – AC-2.4)
5. On a Place or Event with more than 50 records on one row, the sheet opens on 50 and "Show 50 more". (AC-1.5)
6. Widen the window past 1600pt pane width on both pages: the pages stay centered, the sheet is 1280pt. (EP-W1, PP-W1)
7. Open a Person page: Vitals look and behave as before.
8. Run AC-4.1's `rg` from the repo root: no hit. (AC-4.1)

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A test or preview elsewhere passes `provenance:` | STEP-1's build fails at once; remove the argument (it can only have been `.sheet` or `.why`) |
| A board moves the control or adds chrome | Stop (below) |

**Stop and report if:**

- An agreed board (S15-D11 or S15-D12) draws the control anywhere but the row's end, draws one on the Event's Place row or a relationship row, or changes the sheet.
- `ConclusionDetailDefaultPageSections` is no longer how Event and Place fill their page, or a third page uses `ConclusionDetailRowsSection` with `.why`.
- A sheet opened from an Event or Place row lists different records than `provenanceContent()` returns for that row.
- `rg` finds a reader of a removed name outside the files in § 4.

## 12. Open questions

None.

## 13. PR

**Title:** S15-31 — Event and Place rows open the provenance sheet
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-31-event-and-place-provenance-sheet.md`.
