# S15-05 — The Person page's Sources section shows each Source's date

**Status:** Blocked — on board S15-D3
**Spike / slice:** Spike 15 · Slice 5 — Rendering
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D3](../design/S15-D3-person-sources-date.md), board not yet agreed
**Board:** not yet drawn; to be a new turn "S15-D3 · Published date" on the Person page board ([S16-D2 · Folds](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ)). The implementer reads it with the Artifact tool's `read` on that link. Until the board is agreed, §6 macOS describes each frame in words from the brief
**Depends on:** S15-02 (landed [#762](https://github.com/Jake-Robins-Studios/provenencia/pull/762)), S15-04 (landed [#774](https://github.com/Jake-Robins-Studios/provenencia/pull/774)), S15-43 (landed [#900](https://github.com/Jake-Robins-Studios/provenencia/pull/900)), S16-03 (landed [#769](https://github.com/Jake-Robins-Studios/provenencia/pull/769)), S16-06 (landed [#785](https://github.com/Jake-Robins-Studios/provenencia/pull/785)), S16-07 (landed [#761](https://github.com/Jake-Robins-Studios/provenencia/pull/761)), S16-12 (landed [#800](https://github.com/Jake-Robins-Studios/provenencia/pull/800)), S16-13 (landed [#809](https://github.com/Jake-Robins-Studios/provenencia/pull/809)), S15-D3
**Blocks:** S15-22
**Branch:** `s15-05-person-sources-date`
**Version bump:** minor, the next minor at merge (0.28.0 → 0.29.0 at the planning base) — a date on an existing screen and a new field on an FFI response ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-date-value`](../../../../.agents/skills/add-date-value/SKILL.md), [`add-audit-scope`](../../../../.agents/skills/add-audit-scope/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`, `.cursor/rules/macos-client.mdc`, `.cursor/rules/versioning.mdc`
**Context:** working rules "The Source date is one optional DateValue on `sources`", "Build on Spike 16's caches" ([`../deployment-plan.md`](../deployment-plan.md#working-rules)); [`../source-provenance-date.md`](../source-provenance-date.md); S15-04's [plan](S15-04-sources-list-date.md) D-5, D-6, D-14 and **Next adds**; S15-43's [plan](S15-43-source-date-marks.md) D-3 and **Next adds**; S16-12's [plan](../../spike-16/prs/S16-12-source-records.md) (the Source record, its budget); [`../../../catalog-caches.md`](../../../catalog-caches.md) (`sources.records`)
**Planned:** 2026-11-20 against `main` @ `aa21f6d`
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

The Person page's Sources section has had a Date column since S13-16, and every row shows a dash in it. Sources have carried a date since S15-02, and the Sources list shows it as the **published** date since S15-04. This PR puts the date on the Source record (the cached words of a Source that every Source-naming answer composes from, S16-12), sends it with each Source group of the Person claims read, and draws it in the section's column as the Sources list draws its Published column. It is the Person page half of the dogfood bar's item 1.

**Why now.** The Source date's last reader before rendering. S15-22 regroups the same section by citation and builds on the rows this PR finishes.

**What stays.** The section's row order (by title), its other columns and widths, the record lines, the folds, the record links diagram, and the Sources list's look (its published date is moved into a recipe, not redrawn). A date's unknown or supplied mark is not drawn (user, 2026-11-20).

## 2. User stories

**US-1.** As a researcher, when I open a Person's Sources section, I see when each Source was published, so that I can weigh a record by its date without opening the Source.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A Person cites "Hamburg census 1867" dated `1867` (point, year only) | The row's Published cell reads "1867" in secondary ink; hover reads "Published 1867" |
| AC-1.2 | A Person cites "Letter", undated | The cell reads "Undated" in faint ink, with no hover text |
| AC-1.3 | The Source's date is marked unknown (no date row) | The cell reads "Undated" |
| AC-1.4 | The Source's date is `1 Jun 1880`, marked supplied | The cell reads "1 Jun 1880", with no bracket or mark |
| AC-1.5 | The caption line | Reads SOURCE · TYPE · PUBLISHED · REF |
| AC-1.6 | A phrase date "in the reign of Wilhelm I" in the 120pt column | One line, truncated with an ellipsis; hover reads "Published in the reign of Wilhelm I" |

**US-2.** As a VoiceOver user, a row speaks its date in the same words as the Sources list.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | The row "Hamburg census 1867", type Census, dated `1867`, ref `SRC-9TQ2M` | Its spoken label is "Hamburg census 1867, Census, published 1867, SRC-9TQ2M" |
| AC-2.2 | The row "Letter", untyped, undated, ref `SRC-4KQ7M` | "Letter, no published date, SRC-4KQ7M" |

**US-3.** As a researcher, when I change a Source's date on the Source page and come back to the Person page, the row shows the new date.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | The Source's date `1867` is edited to `1868` (the same date row, rewritten in place) | The Source record reads `1868` after the commit; the Person claims read returns `1868` |
| AC-3.2 | The date is set where there was none, or cleared | The record and the claims read follow: dated, then nil |
| AC-3.3 | An Observation's date is edited (a date row no Source holds) | The Source records are not reloaded (the derived entry is kept) |
| AC-3.4 | The edit is made, the Person page is shown again | The row reads the new date; the section's folds and the diagram are as they were (the key reloads, the page does not) |

## 3. Scope

| In | Covered by |
| --- | --- |
| `sources.Record` carries the Source's date, through `settleDate` | STEP-1, AC-1.1, AC-1.3, AC-1.4 |
| An in-place date edit reloads the Source's record (`date_values` moves `source_records`) | STEP-2, AC-3.1, AC-3.3 |
| `PersonClaimGroup.source_date` on the wire; `CatalogPersonClaimGroup.date` in Swift | STEP-3, AC-3.1 |
| The Sources list's published date becomes the recipe `PVPublishedDate` (view and text), replacing `SourcesRowDate` and the private `SourcesPublishedDate` | STEP-4, D-5 |
| The section's Published cell, caption and spoken label (PS-1 – PS-5, PS-W1) | STEP-5, AC-1.1 – AC-1.6, AC-2.1, AC-2.2 |
| A date set elsewhere shows when the page is shown again (PS-6) | STEP-2, STEP-3, AC-3.4 |
| Build cost of the records at 3,000 dated Sources | STEP-1, T-5 |
| Docs: `catalog-caches.md`, the registry comment, completed, map | STEP-6 |

| Out | Home |
| --- | --- |
| Grouping a Source's Citations under one citation | S15-22 |
| Drawing the unknown or supplied mark on a row (here or on the Sources list) | not planned (user, 2026-11-20) |
| Sorting the section by date | not planned |
| The date on the record links diagram or the provenance sheet | not planned |
| Renaming the date form's strings to `L10n.Dates` | S15-42 |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Source record | `core/database/sources/records.go` `Record`, `sqlRecordSources`, `loadRecords`, `Records` (`Build`, `Apply`, `Check`) | Words, type, credibility and Artifact labels; no date. `sqlRecordSources` selects `s.id, s.ref, s.title, s.source_type_id`, the grade key and its relative order. Build is two queries (Sources, Artifacts); `Apply` reloads the Sources named by `effects.ReadSourceRecords`; `Check` compares `bySource` with `reflect.DeepEqual` |
| Date rule | `core/database/sources/sources.go` `settleDate`, `fillDates`, `scanSource` | `settleDate(dates, id, stored)` is the one place a read decides a Source's date (nil when `id` is not 16 bytes or its row is gone) and mark. S15-43's plan names `loadRecords` as its next caller |
| Date write | `core/database/sources/sources.go` `SetDate`; `core/database/datevalues/datevalues.go` `PutTx` | A changed date on a dated Source rewrites the same `date_values` row in place (`PutTx` with `prevID`): the only change is a `date_value` update; the `sources` row is untouched |
| Effects | `core/database/effects/registry.go` `registry["date_values"]` (`ownedValue("date_value", "value_date_id", inbound("sources", "date_value_id"))`), `ReadSourceRecords` | A `date_values` change scopes its Source but moves only `ReadCitations`: an in-place date edit does not reload the Source record. The `ReadSourceRecords` comment says "A table the record gains adds its path here" |
| Effects test | `core/database/effects/reads_test.go` `TestReadsDeclare` | Pins `ReadSourceRecords` to `artifacts`, `source_credibility_assessments`, `sources` ("The tables sources.loadRecords reads") |
| Claims read | `core/database/persondetail/claims.go` `ClaimGroup`, `claims` | `ClaimGroup.Source` is a `sources.Record` from `sources.RecordsOf` |
| Handler | `api/ffi/handlers/person_detail.go` `ListPersonClaims` | Builds `engine.PersonClaimGroup` from `g.Source` (id, ref, title, type id) |
| Proto | `api/proto/engine.proto` `PersonClaimGroup` (fields 1 – 5) | No date |
| Date to proto | `core/valuecodec/valuecodec.go` `DateToProto`; `api/ffi/handlers/sources.go` `sourceProto` | `sourceProto` sets `out.Date = valuecodec.DateToProto(*s.Date)` when dated |
| Swift model | `macos/App/Platform/GenealogyStore.swift` `CatalogPersonClaimGroup`; `macos/App/Platform/GoStore.swift` `listPersonClaims` mapping, `mapDateValue` | No date; `mapDateValue` maps `DateValueInput` (as for `s.hasDate ? mapDateValue(s.date) : nil`) |
| Section content | `macos/App/Features/Conclusions/PersonSourcesContent.swift` `PersonSourcesContent.Row`, `init(groups:sourceTypes:orders:folds:)` | `Row` has no date; the spoken label joins title, type, `L10n.Conclusions.sourcesDateNotRecorded` ("date not recorded") and ref |
| Section view | `macos/App/Features/Conclusions/PersonSourcesSection.swift` `PersonSourcesList.header`, `PersonSourcesRowView.columns`, `PersonSourcesColumns` | The Date cell draws `L10n.Conclusions.sourcesDateNone` ("—") in `textMuted`; the caption is `L10n.Conclusions.sourcesColumnDate` ("Date"); `dateWidth` 120 |
| Published date view | `macos/App/Features/Sources/SourcesListRow.swift` `private struct SourcesPublishedDate` (`.labeled`, `.bare`) | The Sources list's published date: three call sites in that file. S15-04 D-6 and **Next adds**: promoted when a second caller comes (this PR) |
| Published date text | `macos/App/Features/Sources/SourcesRowDate.swift` `enum SourcesRowDate` (`line`, `help`, `spoken`) | Called by `SourcesListRow.spokenLabel` and `SourcesPublishedDate`, `SourcePageIdentityHeader.sourceDate`, `SourceCopyModel.dateLine` |
| Copy | `macos/App/Platform/L10n.swift` `L10n.Conclusions.sourcesColumnDate`, `sourcesDateNone`, `sourcesDateNotRecorded`; `L10n.Sources.publishedHelp(date:)`, `publishedSpoken(date:)`, `noPublishedDateSpoken`; `L10n.Dates.rowUndated`; `macos/App/Resources/Localizable.xcstrings` | Comments of the `sources.list.*` keys name only the Sources list |
| Preview data | `macos/App/Features/Conclusions/PersonSourcesPreviewData.swift` | Groups with no date |
| Kit | `macos/App/DesignSystem/Recipes/LastUpdated/PVLastUpdated.swift`; `macos/App/DesignSystem/README.md` built table | The recipe precedent: a list cell's domain text and spoken suffix |
| Tests | `core/database/sources/records_test.go` `TestRecordsBuild`, `TestRecordsApply`; `core/database/sources/records_bench_test.go` `BenchmarkSourceRecords`; `core/database/persondetail/claims_test.go` `TestClaimsAfterSourceEdit`, `TestClaimsWarmReadIssuesNoQuery`; `api/ffi/handlers/person_detail_test.go` `TestListPersonClaims`; `macos/ProvenenciaTests/PersonSourcesContentTests.swift` `cellsAndFallbacks`; `macos/ProvenenciaTests/SourcesModelTests.swift` `publishedDateTextAndSpokenBase`; `macos/ProvenenciaTests/SourceCopyModelTests.swift` | `cellsAndFallbacks` expects "date not recorded" |
| Docs | `docs/catalog-caches.md` row `sources.records` | "Build: two queries (every Source with its grade, every Artifact)"; 5.7 MB at 3,000 Sources of 10 Artifacts |

**Precedent.** S16-12 ([#800](https://github.com/Jake-Robins-Studios/provenencia/pull/800)) built the Source record and its `BenchmarkSourceRecords` budget; copy its Apply table shape in `TestRecordsApply` (`check(t, moves, write)`). S15-43 ([#900](https://github.com/Jake-Robins-Studios/provenencia/pull/900)) made `settleDate` the one date rule and `fillDates` its batched use; copy `fillDates`' one `datevalues.LookupManyTx` per read. S15-04 ([#774](https://github.com/Jake-Robins-Studios/provenencia/pull/774)) drew the published date; move its view and text unchanged.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `sources.Record` gains `Date *datevalue.Value` *(new field)*: nil when undated, when the stored id has no row, or when the date is marked unknown. No mark field | The Person page reads the date from the Source record (rule "Build on Spike 16's caches"); the mark is not drawn (user, 2026-11-20), so a mark field would have no reader | A `DateMark` field — dead until a reader exists; a separate per-call date lookup in `persondetail` — a second read of a Source's words beside its record |
| D-2 | `sqlRecordSources` selects `s.date_value_id` after `s.source_type_id`. `loadRecords` scans it into a local `dateIDs map[string][]byte` keyed by Source id, then (when any is 16 bytes) calls `datevalues.LookupManyTx(q, ids)` once and sets each `Record.Date` from `settleDate(dates, dateIDs[id], valuemark.Mark{})`, discarding the mark. Same for the full Build and the by-ids Apply reload | One date rule (S15-43 D-3 names `loadRecords` as its caller); one batched query, as `fillDates` | A `LEFT JOIN date_values` in `sqlRecordSources` — a second scanner of a date row beside `datevalues`; calling `fillDates` — it takes `[]Source`, not records |
| D-3 | `ownedValue(entity, col, owners...)` gives each owner path a second job: besides joining the entry's `SourceScope` (today), each owner adds `ReadPath{ReadSourceRecords, owner}` to the entry's `Reads`. The one caller with an owner, `registry["date_values"]`, is unchanged at its call (`ownedValue("date_value", "value_date_id", inbound("sources", "date_value_id"))`) and now moves `source_records` for the Source that holds the date row. `name_values` and `depiction_values` pass no owner and do not change | An in-place date edit writes only `date_values` (§4 Date write); without this the record keeps the old date until the catalog reopens. The read's own comment asks for it ("A table the record gains adds its path here"); an owner path is exactly "the Source whose row holds this value" | Making `SetDate` also emit a `sources` change on an in-place edit — a fake audit row; a hand-written `Reads` list on the `date_values` entry beside `ownedValue` — two places name the same owner |
| D-4 | `PersonClaimGroup` gains `DateValueInput source_date = 6;` (absent when undated). `ListPersonClaims` sets it with `valuecodec.DateToProto(*g.Source.Date)` when non-nil. Swift `CatalogPersonClaimGroup` gains `var date: CatalogDateValueInput?` after `sourceTypeID`; `GoStore` maps `group.hasSourceDate ? Self.mapDateValue(group.sourceDate) : nil` | The section already reads the group; the field mirrors `Source.date` (14) | A whole `Source` message on the group — carries columns the section never shows |
| D-5 | The published date becomes one recipe, `macos/App/DesignSystem/Recipes/PublishedDate/PVPublishedDate.swift` *(new)*: `struct PVPublishedDate: View` with `enum Style { case labeled, bare }`, `init(date: CatalogDateValueInput?, style: Style)`, a `body` identical to today's `SourcesPublishedDate`, and the three text functions moved from `SourcesRowDate` as `static func line(_:locale:) -> String?`, `help(_:locale:) -> String?`, `spoken(_:locale:) -> String`, unchanged. `SourcesRowDate.swift` and the private `SourcesPublishedDate` are deleted; every caller (§4) calls `PVPublishedDate` | A second caller in another feature (S15-04 D-6, **Next adds**: "promoted at S15-05"); a recipe may read `Catalog*` types and `Platform/` formatters but no `Features/` type (`add-ui-component`), so the text moves with the view | Leaving the view in `Features/Sources` and making it internal — a Conclusions view reaching into the Sources feature; a copy in the Person section — a near-copy |
| D-6 | `PersonSourcesContent.Row` gains `var date: CatalogDateValueInput?` *(new field)* from `group.date`; its `accessibilityLabel` joins `[title, typeLabel ?? "", PVPublishedDate.spoken(group.date), ref]`. `PersonSourcesRowView.columns` draws `PVPublishedDate(date: row.date, style: .bare).personSourcesDateCell().accessibilityHidden(true)` in place of the dash. `PersonSourcesColumns.dateWidth` stays 120 | Board PS-2 – PS-5: the list's `.bare` Published column look; the row is one spoken element, as today | A formatted `String` on `Row` — the recipe takes the date and decides dated vs undated in one place (S15-04 D-5) |
| D-7 | Copy. `conclusions.sources.columnDate`: value "Date" → "Published", comment "Column heading over the published date of each Source on a Person's Sources section". Removed keys: `conclusions.sources.dateNone`, `conclusions.sources.dateNotRecorded`. The comments of `sources.list.publishedHelp`, `sources.list.publishedSpoken`, `sources.list.noPublishedDateSpoken` widen to "a Source's published date on a row (the Sources list, the Person page's Sources section)"; keys and values unchanged | "Published" is the date's one name (S15-04 D-14, user 2026-11-10); the same spoken words as the list (PS-5) | Reusing `sources.list.columnPublished` for the caption — the section's other captions are `conclusions.sources.*`; moving the `sources.list.*` keys — S15-42 moves date strings and S16-25 converts keys, not this PR |
| D-8 | `BenchmarkSourceRecords` seeds a date on every Source (worst case: 3,000 `date_values` rows, a year-only point date) and its budget stays S16-12's: Build at most 50 ms and 8 MB at 3,000 Sources × 10 Artifacts | Rule "measure at Scale"; every Source dated is the most this read can cost | Seeding a fraction dated — understates the worst case |
| D-9 | `S15-42`'s scope line in the map drops its sentence that renames `SourcesRowDate`: D-5 does it (`PVPublishedDate`). Changed in the map in this plan's commit | The rename is forced here by layering; the map must not ask for it twice | Leaving the line — S15-42's planner would look for a type that is gone |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

Searched: `SourcesPublishedDate`, `SourcesRowDate`, `PVLastUpdated`, `PVListDetailCell`, `PVDatePlaceLine`, `DateRowDisplay`, `settleDate`, `fillDates`, `LookupManyTx`, `ownedValue`, `ReadSourceRecords`, `source_date`, `rowUndated`.

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `Record.Date` *(new)* | field | `Source.Date` (`core/database/sources/sources.go`) | Reuses its rule (`settleDate`) and type; the record is the cached read the Person page uses (D-1) |
| `ReadSourceRecords` path on `date_values` *(new)* | registry entry | the `artifacts` and `source_credibility_assessments` `ReadSourceRecords` paths | Extends the same read with the table the record gains (D-3) |
| `PersonClaimGroup.source_date` *(new)* | proto field | `Source.date` (field 14) | Same message type; the group carries only what the section draws (D-4) |
| `CatalogPersonClaimGroup.date`, `PersonSourcesContent.Row.date` *(new)* | Swift fields | `CatalogSource.date` | Same type, `CatalogDateValueInput?` |
| `macos/App/DesignSystem/Recipes/PublishedDate/PVPublishedDate.swift` *(new)* | recipe | `SourcesPublishedDate` (private), `SourcesRowDate`, `PVLastUpdated` | It is those two moved, unchanged, with a second caller (D-5); `PVLastUpdated` is the shape of a list-cell recipe |
| `TestRecordsDate` *(new)* | Go test | `TestRecordsBuild` | A table of date cases; `TestRecordsBuild` stays about words |
| `TestClaimsSourceDate` *(new)* | Go test | `TestClaimsAfterSourceEdit` | Same shape, for the date |
| `publishedDateCell` *(new)* | Swift test | `cellsAndFallbacks` | Dated and undated rows; `cellsAndFallbacks` keeps its type and title cases with the new spoken words |

**Builds on.** S16-12's Source record and Apply-by-read; S15-43's `settleDate`; the effects registry's keyed reads (`add-audit-scope`); S15-04's published date and copy; `add-ui-component`'s promotion rule (snowflake → recipe at the second call site).
**Deletes.** `macos/App/Features/Sources/SourcesRowDate.swift` (`SourcesRowDate`); `SourcesPublishedDate` in `SourcesListRow.swift`; `L10n.Conclusions.sourcesDateNone`, `L10n.Conclusions.sourcesDateNotRecorded` and their `Localizable.xcstrings` entries. The dash placeholder in `PersonSourcesRowView.columns`.
**Next adds.** S15-22 regroups the section's rows and keeps the Published cell; S15-42 shows the mark in the Source page header and no longer renames `SourcesRowDate` (D-9); a later row that shows a Source's date (the Promote list, a picker) calls `PVPublishedDate`.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A `date_values` change now names Sources in `source_records` | `sources.Records` `Apply`; Swift keys that follow `.reads(.sourceRecords)` (`CatalogLastUpdated.swift` `applyHiddenPolicy`) | `Apply` reloads the named Sources and patches (no new code); a date row released with the Source's id cleared names no Source (the `inbound` query finds none) and the `sources` row change names it instead; a `date_values` row of an Observation finds no Source and moves nothing (AC-3.3) |
| A dated Source on the Person page | `PersonSourcesRowView` | Dated, undated, unknown and phrase states (AC-1.1 – AC-1.6) |
| A `date_value_id` with no row (crafted) | `loadRecords` → `settleDate` | Reads as undated (S15-02's rule); `Check` agrees, since both sides call `loadRecords` |

### Scale

At the map's Scale: **3,000 Sources** in a project (the records' Build), **30 Sources** on a Person page.

- **Build** (first read, or after `Drop`): one more batched query (`datevalues.LookupManyTx`, only the dated ids) over up to 3,000 date rows; one `datevalue.Value` per dated Source on the heap. Budget: S16-12's, at most 50 ms and 8 MB at 3,000 Sources × 10 Artifacts, every Source dated (D-8, T-5).
- **Apply**: one more batched lookup for the named Sources' dates; ordinary commits name one Source.
- **A date write**: an in-place edit now reloads one Source record (two small queries plus one date lookup) and refreshes the Swift keys whose inputs name that Source: the Person claims and record links keys of the pages that cite it, each re-read when shown (S16-25's follow). An Observation's date write runs the same `inbound` query it already runs for `SourceScope` and names no Source.
- **The Person claims read**: no new query (the date is in the warm record; `TestClaimsWarmReadIssuesNoQuery` stays at 0). The wire grows by one small message per Source group (30 at Scale).

### Edges

- **Assumptions.** `Check` compares `bySource` with `reflect.DeepEqual`: a `*datevalue.Value` compares by value, so two loads of the same row agree (T-1 runs `g.Verify()` after each write). `newRecordIndex` and `Apply` copy `Record` by value; `Date` is a pointer to a value owned by that load, read-only like `ArtifactLabels`.
- **Neighbors.** A `date_values` change of an Observation's date: no Source reload (AC-3.3, T-1 "observation date edit", moves false). A `sources` row change of the date id or mark: reloads, as before (T-1). A credibility change: unchanged (existing T-1 row).
- **Removed inputs.** A cleared date: `SetDate` releases the row and writes `date_value_id` NULL; the record's `Date` becomes nil (T-1 "date clear"). A date marked unknown: no row, nil (T-1). A Source deleted: its record goes, as before.
- **Real data.** None — no table- or seed-driven rule.
- **Untrusted size.** A date row is one row per Source (unique index `sources_date_value_id_uidx`); the lookup is batched by `LookupManyTx`; no dimension multiplies.

### Schema

None — no catalog change; `sources.date_value_id` exists (migration `000063`).

### Go core

| Package | Change |
| --- | --- |
| `core/database/sources` | `records.go`: `Record.Date *datevalue.Value` *(new)*; `sqlRecordSources` selects `s.date_value_id`; `loadRecords` fills `Date` per D-2. The `Record` doc names the date |
| `core/database/effects` | `registry.go`: `ownedValue` adds `ReadPath{ReadSourceRecords, owner}` to `Reads` for each owner path (D-3); its doc comment says so; the `ReadSourceRecords` comment adds "its date" |

```go
// Record is a Source's words, held once ...
type Record struct {
	// ... unchanged ...
	// Date is the Source's own date, nil when undated, when its row is gone or
	// when it is marked unknown (settleDate). Read-only, like ArtifactLabels.
	Date *datevalue.Value
}
```

Errors: none new.

### FFI

`api/proto/engine.proto` `PersonClaimGroup`:

```proto
message PersonClaimGroup {
  // ... fields 1 – 5 unchanged ...
  // The Source's own date (original publication, or when the record was
  // made); absent when undated or marked unknown.
  DateValueInput source_date = 6;
}
```

Handler `api/ffi/handlers/person_detail.go` `ListPersonClaims` sets it (D-4). Regenerate with `./scripts/generate-proto.sh`.

### macOS

From the brief's inventory (S15-D3 § 6):

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Sources section rows | snowflake | `macos/App/Features/Conclusions/PersonSourcesSection.swift` `PersonSourcesRowView` | The Date cell draws `PVPublishedDate(date: row.date, style: .bare)` (D-6) |
| Published date | recipe *(promoted)* | `macos/App/DesignSystem/Recipes/PublishedDate/PVPublishedDate.swift` *(new)* | D-5; README built-table row |
| Caption line | snowflake | `PersonSourcesList.header` | `L10n.Conclusions.sourcesColumnDate` now reads "Published" (D-7) |
| Columns | snowflake | `PersonSourcesColumns` | Unchanged (120pt) |
| Type pill | recipe | `CatalogSourceTypePill` | Unchanged |
| Sources list | snowflake | `macos/App/Features/Sources/SourcesListRow.swift` | Calls `PVPublishedDate` in its three places; looks the same |

Frames in words (until the board is agreed): **1a/1b** Johann Weber's Sources section at Regular (1102) and Wide (2296), the diagram beside the rows; caption SOURCE · TYPE · PUBLISHED · REF; "Hamburg census 1867" reads "1867", "St Brigid parish baptisms" "bet 1834 and 1840", "Altona Nachrichten, 3 May issue" "3 May 1871", "Letter from Anna to Johann" and "Weber family portrait" a faint "Undated"; the columns as today at both widths. **2** the phrase "in the reign of Wilhelm I" truncated in 120pt with its hover. **3** the spoken label of a dated and an undated row (AC-2.1, AC-2.2).

States: undated and unknown read "Undated" (faint); loading, empty and error are the section's, unchanged. Accessibility: the cell stays hidden; the row's one spoken element carries the date (D-6). Wide: unchanged arrangement (PS-W1).

### Strings

`conclusions.sources.columnDate` "Date" → "Published" (comment D-7). Removed: `conclusions.sources.dateNone` ("—"), `conclusions.sources.dateNotRecorded` ("date not recorded"). Comments widened: `sources.list.publishedHelp`, `sources.list.publishedSpoken`, `sources.list.noPublishedDateSpoken`. No new key.

## 7. Steps

**STEP-1 — The Source record carries the date**
Files: `core/database/sources/records.go`, `core/database/sources/records_test.go`, `core/database/sources/records_bench_test.go`. Skill: `add-date-value`.
Do: D-1, D-2. Add `TestRecordsDate` (T-1's Build cases). In `BenchmarkSourceRecords`'s `seed`, insert one `date_values` row per Source and set its `date_value_id` (D-8; insert through raw SQL as the benchmark seeds, with the columns `datevalues.insert` writes for a year-only point date).
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sources/` passes; `CGO_ENABLED=1 go test -tags fts5 -run '^$' -bench BenchmarkSourceRecords -benchtime 1x ./core/database/sources/` reports `build-ms` ≤ 50 and `heap-MB` ≤ 8.

**STEP-2 — An in-place date edit reloads the record**
Files: `core/database/effects/registry.go`, `core/database/effects/reads_test.go`, `core/database/sources/records_test.go`, `core/database/persondetail/claims_test.go`. Skill: `add-audit-scope`.
Do: D-3. `TestReadsDeclare` adds `date_values` to `ReadSourceRecords`. `TestRecordsApply` gains the date rows of T-1; add `TestClaimsSourceDate` (T-3).
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/effects/ ./core/database/sources/ ./core/database/persondetail/` passes.

**STEP-3 — The date reaches Swift**
Files: `api/proto/engine.proto`, generated `api/proto/engine/engine.pb.go` and the Swift generated file, `api/ffi/handlers/person_detail.go`, `api/ffi/handlers/person_detail_test.go`, `macos/App/Platform/GenealogyStore.swift`, `macos/App/Platform/GoStore.swift`. Skill: `add-ffi-handler`.
Do: D-4. Run `./scripts/generate-proto.sh`. Extend `TestListPersonClaims` (T-4).
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/ffi/handlers/ -run TestListPersonClaims` passes; the Xcode build succeeds.

**STEP-4 — The published date becomes a recipe**
Files: `macos/App/DesignSystem/Recipes/PublishedDate/PVPublishedDate.swift` *(new)*, `macos/App/Features/Sources/SourcesRowDate.swift` (deleted), `macos/App/Features/Sources/SourcesListRow.swift`, `macos/App/Features/Sources/SourcePageIdentityHeader.swift`, `macos/App/Features/Sources/SourceCopyModel.swift`, `macos/App/DesignSystem/README.md`, `macos/ProvenenciaTests/SourcesModelTests.swift`, `macos/ProvenenciaTests/SourceCopyModelTests.swift`. Skill: `add-ui-component`.
Do: D-5. Move, do not change: the view's body and the three functions keep their code. Add a `#Preview` with a dated, a phrase and an undated value in both styles. Add the README built-table row `PublishedDate`. Rename the callers and the tests' calls.
Check: `rg -n 'SourcesRowDate|SourcesPublishedDate' macos/` has no hit; Xcode tests pass; the Sources list looks the same at Regular, Wide and 860pt.

**STEP-5 — The section draws the date**
Files: `macos/App/Features/Conclusions/PersonSourcesContent.swift`, `macos/App/Features/Conclusions/PersonSourcesSection.swift`, `macos/App/Features/Conclusions/PersonSourcesPreviewData.swift`, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `macos/ProvenenciaTests/PersonSourcesContentTests.swift`. Skills: `add-localized-string`, `add-swift-test`.
Do: D-6, D-7. In `PersonSourcesPreviewData`, give the regular and Johann groups the brief's dates (one phrase, two undated). Add `publishedDateCell` (T-6) and update `cellsAndFallbacks` (T-7).
Check: Xcode tests pass with no Swift warning; `python3 scripts/check-localizable-xcstrings.py` passes; the "Johann" and "Johann, Wide" previews match frames 1a/1b.

**STEP-6 — Docs and version**
Files: `docs/catalog-caches.md` (row `sources.records`: "Build: three queries (every Source with its grade and date id, the dated Sources' date rows, every Artifact)", and the measured size at 3,000 dated Sources), `core/database/effects/registry.go` comment (STEP-2), `VERSION`, `core/version.go`, every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`, `completed.md`, `deployment-plan.md` (map row), this plan (status), `design/S15-D3-person-sources-date.md` → `design/archive/`, `design/README.md`.
Do: per the Definition of done. Version: the minor above `VERSION` on `main` when you branch.
Check: `VERSION`, `core.Version` and every `MARKETING_VERSION` line agree; `python3 scripts/check-plan-docs.py --links docs/catalog-caches.md` passes.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/sources/records_test.go` `TestRecordsDate` *(new)*, table-driven; and `TestRecordsApply` rows "date set", "date edit", "date clear", "date unknown", "observation date edit" | Build: an undated Source → `Date` nil; `1867` (point, year) → year 1867; `1 Jun 1880` marked supplied → the date; marked unknown → nil; a `date_value_id` whose row was deleted by raw SQL with foreign keys off → nil. Apply (each through `check(t, moves, write)` and `g.Verify()`): `SetDate` 1867 on an undated Source → moves, `Date` 1867; `SetDate` 1868 on it (in place) → moves, 1868; `SetDate(nil, Unknown)` → moves, nil; `SetDate(nil, {})` after a date → moves, nil; `r.DatedBirth(src, r.Artifact, 1880)` → moves false | AC-1.1, AC-1.3, AC-1.4, AC-3.1, AC-3.2, AC-3.3, D-1, D-2, D-3 |
| T-2 | Go | `core/database/effects/reads_test.go` `TestReadsDeclare` | `ReadSourceRecords` tables = `artifacts`, `date_values`, `source_credibility_assessments`, `sources` | D-3 |
| T-3 | Go | `core/database/persondetail/claims_test.go` `TestClaimsSourceDate` *(new)* | `burialsAndBaptisms`: the group's `Source.Date` nil; after `SetDate` 1867 → 1867; after `SetDate` 1868 → 1868, and `graphfill.Graphs.Peek` still holds the loaded graph; after a clear → nil | AC-3.1, AC-3.2 |
| T-4 | Go | `api/ffi/handlers/person_detail_test.go` `TestListPersonClaims` | Before: `g.GetSourceDate()` nil; after `SetSourceDate` 1880 (point, year) → `GetSourceDate().GetStartYear() == 1880` | AC-3.1, D-4 |
| T-5 | Go | `core/database/sources/records_bench_test.go` `BenchmarkSourceRecords` | 3,000 Sources × 10 Artifacts, every Source dated → `build-ms` ≤ 50, `heap-MB` ≤ 8 | D-8 |
| T-6 | Swift | `macos/ProvenenciaTests/PersonSourcesContentTests.swift` `publishedDateCell` *(new)* | A group dated `1867` → `row.date` is it, `accessibilityLabel` "Hamburg census 1867, Census, published 1867, SRC-9TQ2M"; `PVPublishedDate.line` of a phrase → the phrase; `PVPublishedDate.help` of `1867` → "Published 1867"; nil → `line` nil, `help` nil | AC-1.1, AC-1.2, AC-1.6, AC-2.1, D-6 |
| T-7 | Swift | `macos/ProvenenciaTests/PersonSourcesContentTests.swift` `cellsAndFallbacks` | The two spoken labels read "…, no published date, …": "Hamburg census 1867, Census, no published date, SRC-9TQ2M", "Letter, no published date, SRC-4KQ7M" | AC-2.2 |
| T-8 | Swift | `macos/ProvenenciaTests/SourcesModelTests.swift` `publishedDateTextAndSpokenBase`; `macos/ProvenenciaTests/SourceCopyModelTests.swift` | Unchanged expectations, calling `PVPublishedDate` | D-5 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `TestPragmaHonesty`-adjacent registry tests in `core/database/effects` (`registry_completeness_test.go`), `TestClaimsWarmReadIssuesNoQuery`, `TestRecordsOf`, `CatalogQueryRegistryTests` and `WorkspaceSessionTests` (they build `CatalogPersonClaimGroup`).

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
- [ ] Domain doc updated if a rule in docs/*.md changed: docs/catalog-caches.md `sources.records` row (three queries, measured size)
- [ ] BenchmarkSourceRecords figures (build-ms, heap-MB, apply-ms) in the PR description
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. (AC-1.1, AC-1.2, AC-1.5, AC-1.6) Open a project with a Person who cites at least three Sources. On the Source page, give one Source the date `1867`, another the phrase "in the reign of Wilhelm I", and leave a third undated. Open the Person page, Sources section. See the caption PUBLISHED, "1867", the phrase truncated with its hover "Published in the reign of …", and a faint "Undated".
2. (AC-3.4) Open the first Source, change its date to `1868`, go Back. The row reads "1868"; the section's unfolded pages and the diagram are as they were.
3. (AC-1.3) On that Source, choose No date… (marked unknown) if S15-42 has landed, otherwise clear the date. The row reads "Undated".
4. Stretch the window past 1600pt of pane: the columns keep their widths; the title and the diagram take the room.
5. (AC-2.1) With VoiceOver, move to a dated row: it reads "…, Census, published 1868, SRC-…".
6. Open the Sources list at Regular, Wide and 860pt: the published date looks as before.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| The new `ReadSourceRecords` path on `date_values` makes every Observation date write reload a Source record | `inbound("sources", "date_value_id")` finds only a Source's own date row; T-1's "observation date edit" row pins moves false |
| The recipe move changes the Sources list's look | STEP-4 moves code unchanged; the list's existing tests and the manual check 6 |
| `ownedValue`'s new owner read reaches an entry that should not move the records | Only `date_values` passes an owner path today; `TestReadsDeclare` pins the tables |

**Stop and report if:**

- `datevalues.PutTx` no longer rewrites a held row in place, or `SetDate` starts writing a `sources` change on an in-place edit (D-3's premise).
- `BenchmarkSourceRecords` reports Build over 50 ms or heap over 8 MB at 3,000 dated Sources.
- `TestClaimsWarmReadIssuesNoQuery` counts a query after STEP-1.
- `settleDate`'s signature differs from §4 (S15-43 D-3).
- The agreed board draws the date with a label, an icon, a mark or another width, or changes another column: the plan follows the board after the user confirms; report before coding.
- A Swift key that reads the Person claims does not reload after an in-place date edit in the app (manual check 2) though T-1 and T-3 pass.

## 12. Open questions

None.

## 13. PR

**Title:** S15-05 — The Person page's Sources section shows each Source's date
**Body:** objective in one sentence; what shipped against US-1 – US-3; AC evidence; `BenchmarkSourceRecords` figures; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-05-person-sources-date.md`.
