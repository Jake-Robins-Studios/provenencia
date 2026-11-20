# S15-05 — The Person page's Sources section shows each Source's date

**Status:** Planned
**Spike / slice:** Spike 15 · Slice 5 — Rendering
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D3](../design/S15-D3-person-sources-date.md), board agreed 2026-11-20
**Board:** [Person page board](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ), page *Sources*, turn 19 "S15-D3 · Published date": frames F1a (Regular), F1b (Wide), F2 (the phrase truncated with its hover). Read it with the Artifact tool's `read` on that link, `path` "project/Person Detail - Sources.dc.html" (turn 19 and the row template's Date cell). Board decision (user, 2026-11-20), which replaces the brief's PS-3: "Undated" is italic, secondary ink, caption size (6.9:1 on the page in light, 10.8:1 in dark; faint ink is 2.6:1), and because the published date is one shared view the Sources list's undated text ("Undated", "No published date") takes the same look. The date is the body face, not mono. Frame 3 (the spoken labels) was not drawn; PS-5 stands as written
**Depends on:** S15-02 (landed [#762](https://github.com/Jake-Robins-Studios/provenencia/pull/762)), S15-04 (landed [#774](https://github.com/Jake-Robins-Studios/provenencia/pull/774)), S15-43 (landed [#900](https://github.com/Jake-Robins-Studios/provenencia/pull/900)), S16-03 (landed [#769](https://github.com/Jake-Robins-Studios/provenencia/pull/769)), S16-06 (landed [#785](https://github.com/Jake-Robins-Studios/provenencia/pull/785)), S16-07 (landed [#761](https://github.com/Jake-Robins-Studios/provenencia/pull/761)), S16-12 (landed [#800](https://github.com/Jake-Robins-Studios/provenencia/pull/800)), S16-13 (landed [#809](https://github.com/Jake-Robins-Studios/provenencia/pull/809)), S15-D3
**Blocks:** S15-22
**Branch:** `s15-05-person-sources-date`
**Version bump:** minor, the next minor at merge (0.28.0 → 0.29.0 at the planning base) — a date on an existing screen and a new field on an FFI response ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-date-value`](../../../../.agents/skills/add-date-value/SKILL.md), [`add-audit-scope`](../../../../.agents/skills/add-audit-scope/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`, `.cursor/rules/macos-client.mdc`, `.cursor/rules/design-system-layers.mdc` (value formatting in `Platform/`; a recipe composes it), `.cursor/rules/versioning.mdc`
**Context:** working rules "The Source date is one optional DateValue on `sources`", "Build on Spike 16's caches" ([`../deployment-plan.md`](../deployment-plan.md#working-rules)); [`../source-provenance-date.md`](../source-provenance-date.md); S15-04's [plan](S15-04-sources-list-date.md) D-5, D-6, D-14 and **Next adds**; S15-43's [plan](S15-43-source-date-marks.md) D-3 and **Next adds**; S16-12's [plan](../../spike-16/prs/S16-12-source-records.md) (the Source record, its budget); [`../../../catalog-caches.md`](../../../catalog-caches.md) (`sources.records`)
**Planned:** 2026-11-20 against `main` @ `aa21f6d`
**Review:** [`S15-05-person-sources-date.review.md`](S15-05-person-sources-date.review.md) — Fits with changes / Ready with changes, 2 rounds; every finding Fixed or answered; nothing To user

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

**What stays.** The section's row order (by title), its other columns and widths, the record lines, the folds, the record links diagram, and the Sources list's dates (its published date is moved into a recipe; only its undated text changes, to the board's italic secondary look, user 2026-11-20). A date's unknown or supplied mark is not drawn (user, 2026-11-20).

## 2. User stories

**US-1.** As a researcher, when I open a Person's Sources section, I see when each Source was published, so that I can weigh a record by its date without opening the Source.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A Person cites "Hamburg census 1867" dated `1867` (point, year only) | The row's Published cell reads "1867" in secondary ink; hover reads "Published 1867" |
| AC-1.2 | A Person cites "Letter", undated | The cell reads "Undated" in italic secondary ink, caption size, with no hover text |
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
| `PersonClaimGroup.source_date` on the wire; `CatalogPersonClaimGroup.sourceDate` in Swift | STEP-3, AC-3.1 |
| The date's text becomes `SourceDateText` in `Platform/` and its look the recipe `PVPublishedDate`, replacing `SourcesRowDate`, the private `SourcesPublishedDate` and `SourcesListRow.spokenBase`; their copy moves to `L10n.PublishedDate` | STEP-4, D-5, D-7 |
| The section's Published cell, caption and spoken label (PS-1 – PS-5, PS-W1) | STEP-5, AC-1.1 – AC-1.6, AC-2.1, AC-2.2 |
| A date set elsewhere shows when the page is shown again (PS-6) | STEP-2, STEP-3, AC-3.4 |
| Build cost of the records at 3,000 dated Sources | STEP-1, T-5 |
| Docs: `catalog-caches.md`, the two skills (D-3), the registry comments, completed, map | STEP-2, STEP-6 |

| Out | Home |
| --- | --- |
| Grouping a Source's Citations under one citation | S15-22 |
| Drawing the unknown or supplied mark on a row (here or on the Sources list) | not planned (user, 2026-11-20) |
| Sorting the section by date | not planned |
| The date on the record links diagram or the provenance sheet | not planned |
| Renaming the date form's strings to `L10n.Dates` | S15-42 |
| Tidying `SourcesListRow`'s other spoken-label code beyond the `spokenBase` move | not planned |
| Rewriting `SourcesRowDate` in earlier plans' prose (`prs/S15-04-…`, `prs/S15-32-…`) | not planned: landed plans record what was |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Source record | `core/database/sources/records.go` `Record`, `sqlRecordSources`, `loadRecords`, `Records` (`Build`, `Apply`, `Check`) | Words, type, credibility and Artifact labels; no date. `sqlRecordSources` selects `s.id, s.ref, s.title, s.source_type_id`, the grade key and its relative order. Build is two queries (Sources, Artifacts); `Apply` reloads the Sources named by `effects.ReadSourceRecords`; `Check` compares `bySource` with `reflect.DeepEqual` |
| Date rule | `core/database/sources/sources.go` `settleDate`, `fillDates`, `scanSource` | `settleDate(dates, id, stored)` is the one place a read decides a Source's date (nil when `id` is not 16 bytes or its row is gone) and mark. S15-43's plan names `loadRecords` as its next caller |
| Date write | `core/database/sources/sources.go` `SetDate`; `core/database/datevalues/datevalues.go` `PutTx` | A changed date on a dated Source rewrites the same `date_values` row in place (`PutTx` with `prevID`): the only change is a `date_value` update; the `sources` row is untouched |
| Effects | `core/database/effects/registry.go` `ownedValue(entity, col string, owners ...Path)`, `registry["date_values"]` (`ownedValue("date_value", "value_date_id", inbound("sources", "date_value_id"))`), `ReadSourceRecords` | A `date_values` change scopes its Source but moves only `ReadCitations`: an in-place date edit does not reload the Source record. The `ReadSourceRecords` comment says "A table the record gains adds its path here" |
| Effects test | `core/database/effects/reads_test.go` `TestReadsDeclare` | Pins `ReadSourceRecords` to `artifacts`, `source_credibility_assessments`, `sources` ("The tables sources.loadRecords reads") |
| Claims read | `core/database/persondetail/claims.go` `ClaimGroup`, `claims` | `ClaimGroup.Source` is a `sources.Record` from `sources.RecordsOf` |
| Handler | `api/ffi/handlers/person_detail.go` `ListPersonClaims` | Builds `engine.PersonClaimGroup` from `g.Source` (id, ref, title, type id) |
| Proto | `api/proto/engine.proto` `PersonClaimGroup` (fields 1 – 5) | No date |
| Date to proto | `core/valuecodec/valuecodec.go` `DateToProto`; `api/ffi/handlers/sources.go` `sourceProto` | `sourceProto` sets `out.Date = valuecodec.DateToProto(*s.Date)` when dated |
| Swift model | `macos/App/Platform/GenealogyStore.swift` `CatalogPersonClaimGroup`; `macos/App/Platform/GoStore.swift` `listPersonClaims` mapping, `mapDateValue` | No date; `mapDateValue` maps `DateValueInput` (as for `s.hasDate ? mapDateValue(s.date) : nil`) |
| Section content | `macos/App/Features/Conclusions/PersonSourcesContent.swift` `PersonSourcesContent.Row`, `init(groups:sourceTypes:orders:folds:)` | `Row` has no date; the spoken label joins title, type, `L10n.Conclusions.sourcesDateNotRecorded` ("date not recorded") and ref |
| Section view | `macos/App/Features/Conclusions/PersonSourcesSection.swift` `PersonSourcesList.header`, `PersonSourcesRowView.columns`, `PersonSourcesColumns` | The Date cell draws `L10n.Conclusions.sourcesDateNone` ("—") in `textMuted`; the caption is `L10n.Conclusions.sourcesColumnDate` ("Date"); `dateWidth` 120 |
| Published date view | `macos/App/Features/Sources/SourcesListRow.swift` `private struct SourcesPublishedDate` (`.labeled`, `.bare`) | The Sources list's published date: three call sites in that file. S15-04 D-6 and **Next adds**: promoted when a second caller comes (this PR) |
| Published date text | `macos/App/Features/Sources/SourcesRowDate.swift` `enum SourcesRowDate` (`line`, `help`, `spoken`); `macos/App/Features/Sources/SourcesListRow.swift` `SourcesListRow.spokenBase(title:type:ref:date:locale:)` | `SourcesRowDate` is called by `SourcesListRow.spokenBase` and `SourcesPublishedDate`, `SourcePageIdentityHeader.sourceDate`, `SourceCopyModel.dateLine`. `spokenBase` joins title, type, the spoken date and ref (S15-04 D-11); called by `SourcesListRow`'s `accessibilityValue` and `SourcesModelTests` |
| Copy | `macos/App/Platform/L10n.swift` `L10n.Conclusions.sourcesColumnDate`, `sourcesDateNone`, `sourcesDateNotRecorded`; `L10n.Sources.publishedLabel`, `noPublishedDate`, `publishedHelp(date:)`, `publishedSpoken(date:)`, `noPublishedDateSpoken`; `L10n.Dates.rowUndated`; `macos/App/Resources/Localizable.xcstrings` | The five `sources.list.*` published-date strings are read only by `SourcesRowDate` and `SourcesPublishedDate`. Recipes own their copy namespace (`L10n.LastUpdated`, `L10n.Unpromote`); none reads `L10n.Sources` |
| Preview data | `macos/App/Features/Conclusions/PersonSourcesPreviewData.swift` `regular`, `folded`, `manySources`, `johannClaims` | Groups with no date. `johannClaims` holds five Sources: "Hamburg census 1867", "Hamburger Adressbuch 1861", "Hamburger Nachrichten, obituary 1880", "Konfirmandenbuch St. Ansgarii 1831" and the long "Verzeichniß …" title; the brief's frames use them |
| Skills | `.agents/skills/add-audit-scope/SKILL.md` (the `ownedValue` owner paragraph and the `source_records` paragraph); `.agents/skills/add-date-value/SKILL.md` (the date row ownership paragraph) | Say an owner path reaches the owner's scope only, and that S15-05 adds the `date_values` `source_records` path |
| Bench seed | `core/database/sources/records_bench_test.go` `seed` | Raw `INSERT`s inside one transaction, ids from `databasetest.BenchID(1|2|3, n)`; reports metrics, asserts no budget |
| Kit | `macos/App/DesignSystem/Recipes/LastUpdated/PVLastUpdated.swift`; `macos/App/DesignSystem/README.md` built table | The recipe precedent: a list cell's domain text and spoken suffix |
| Tests | `core/database/sources/records_test.go` `TestRecordsBuild`, `TestRecordsApply`; `core/database/sources/records_bench_test.go` `BenchmarkSourceRecords`; `core/database/persondetail/claims_test.go` `TestClaimsAfterSourceEdit`, `TestClaimsWarmReadIssuesNoQuery`; `api/ffi/handlers/person_detail_test.go` `TestListPersonClaims`; `macos/ProvenenciaTests/PersonSourcesContentTests.swift` `cellsAndFallbacks`; `macos/ProvenenciaTests/SourcesModelTests.swift` `publishedDateTextAndSpokenBase`; `macos/ProvenenciaTests/SourceCopyModelTests.swift` | `cellsAndFallbacks` expects "date not recorded" |
| Docs | `docs/catalog-caches.md` row `sources.records` | "Build: two queries (every Source with its grade, every Artifact)"; 5.7 MB at 3,000 Sources of 10 Artifacts |

**Precedent.** S16-12 ([#800](https://github.com/Jake-Robins-Studios/provenencia/pull/800)) built the Source record and its `BenchmarkSourceRecords` budget; copy its Apply table shape in `TestRecordsApply` (`check(t, moves, write)`). S15-43 ([#900](https://github.com/Jake-Robins-Studios/provenencia/pull/900)) made `settleDate` the one date rule and `fillDates` its batched use; copy `fillDates`' one `datevalues.LookupManyTx` per read. S15-04 ([#774](https://github.com/Jake-Robins-Studios/provenencia/pull/774)) drew the published date; move its view and text unchanged.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `sources.Record` gains `Date *datevalue.Value` *(new field)*: nil when undated, when the stored id has no row, or when the date is marked unknown. No mark field | The Person page reads the date from the Source record (rule "Build on Spike 16's caches"); the mark is not drawn (user, 2026-11-20), so a mark field would have no reader | A `DateMark` field — dead until a reader exists; a separate per-call date lookup in `persondetail` — a second read of a Source's words beside its record |
| D-2 | `sqlRecordSources` selects `s.date_value_id` after `s.source_type_id`. `loadRecords` scans it into a local `dateIDs map[string][]byte` keyed by Source id. A new package function `lookupDates(q database.Querier, ids [][]byte) (map[string]datevalue.Value, error)` *(new)* keeps the 16-byte ids and calls `datevalues.LookupManyTx` once (an empty set issues no query); `fillDates` calls it instead of its own loop, and `loadRecords` calls it on a slice built by ranging over the `dateIDs` values (order does not matter; `LookupManyTx` dedupes), then sets each `Record.Date` from `settleDate(dates, dateIDs[id], valuemark.Mark{})`, discarding the mark. Same for the full Build and the by-ids Apply reload | One date rule (S15-43 D-3 names `loadRecords` as its caller); one batch rule (`lookupDates`) for both reads (review M-6) | A `LEFT JOIN date_values` in `sqlRecordSources` — a second scanner of a date row beside `datevalues`; calling `fillDates` — it takes `[]Source`, not records; a second copy of the id filter in `loadRecords` |
| D-3 | `ownedValue`'s variadic parameter is renamed `owners` → `sourceOwners` and gains a second job: besides joining the entry's `SourceScope` (today), each Source-owner path adds `ReadPath{ReadSourceRecords, path}` to the entry's `Reads`. Its doc comment says an owner path must end at `sources`. The one caller with an owner, `registry["date_values"]`, is unchanged at its call (`ownedValue("date_value", "value_date_id", inbound("sources", "date_value_id"))`) and now moves `source_records` for the Source that holds the date row. `name_values` and `depiction_values` pass no owner and do not change. The skill lines that describe the owner argument are updated in the same step (review M-4) | An in-place date edit writes only `date_values` (§4 Date write); without this the record keeps the old date until the catalog reopens. The read's own comment asks for it ("A table the record gains adds its path here"); an owner path is exactly "the Source whose row holds this value", and both jobs need it to end at `sources` (`ReadSourceRecords.KeyTable()`) | Making `SetDate` also emit a `sources` change on an in-place edit — a fake audit row; a hand-written `Reads` list on the `date_values` entry beside `ownedValue` — two places name the same owner |
| D-4 | `PersonClaimGroup` gains `DateValueInput source_date = 6;` (absent when undated). `ListPersonClaims` sets it with `valuecodec.DateToProto(*g.Source.Date)` when non-nil. Swift `CatalogPersonClaimGroup` gains `var sourceDate: CatalogDateValueInput?` after `sourceTypeID`; `GoStore` maps `group.hasSourceDate ? Self.mapDateValue(group.sourceDate) : nil` | The section already reads the group; the field mirrors `Source.date` (14); the Swift name matches its `source*` neighbours (review M-8) | A whole `Source` message on the group — carries columns the section never shows |
| D-5 | The date's text and its look split by layer. **Text:** `macos/App/Platform/SourceDateText.swift` *(new)* `enum SourceDateText` holds `line(_:locale:) -> String?`, `help(_:locale:) -> String?`, `spoken(_:locale:) -> String` moved unchanged from `SourcesRowDate`, and `spokenRow(title:type:ref:date:locale:) -> String` moved unchanged from `SourcesListRow.spokenBase` (D-6). **Look:** `macos/App/DesignSystem/Recipes/PublishedDate/PVPublishedDate.swift` *(new)* `struct PVPublishedDate: View`, `enum Style { case labeled, bare }`, `init(date: CatalogDateValueInput?, style: Style)`, a `body` identical to today's `SourcesPublishedDate`, calling `SourceDateText`. Deleted: `SourcesRowDate.swift`, the private `SourcesPublishedDate`, `SourcesListRow.spokenBase`. Callers: the Sources list row and this section draw `PVPublishedDate`; `SourceCopyModel.dateLine` and `SourcePageIdentityHeader.sourceDate` call `SourceDateText.line` | Value formatting lives in `Platform/` and a recipe composes it (`docs/design-system-layers.md`, `.cursor/rules/design-system-layers.mdc`; precedent `PVLastUpdated` over `TimestampFormat`); the Copy form's model and the page header need the text, not a list-cell view (review M-1). The view has a second caller in another feature (S15-04 D-6, **Next adds**) | Static text functions on the view — a model would import a DesignSystem view for a string; the view left in `Features/Sources` — a Conclusions view reaching into the Sources feature; a copy in the Person section — a near-copy |
| D-6 | `PersonSourcesContent.Row` gains `var date: CatalogDateValueInput?` *(new field)* from `group.sourceDate`; its `accessibilityLabel` is `SourceDateText.spokenRow(title: title.text, type: typeLabel ?? "", ref: group.sourceRef, date: group.sourceDate)`, the function the Sources list calls. `PersonSourcesRowView.columns` replaces the dash `Text` (and its `.font`/`.foregroundStyle`, which the recipe owns) with `PVPublishedDate(date: row.date, style: .bare).personSourcesDateCell().accessibilityHidden(true)`, in that order. `PersonSourcesColumns.dateWidth` stays 120 | Board PS-2 – PS-5: the list's `.bare` Published column look; "the same words the Sources list speaks" is one function, not two joins (review M-2) | A formatted `String` on `Row` — the recipe takes the date and decides dated vs undated in one place (S15-04 D-5); a hand join in the content — drifts from the list's |
| D-7 | Copy. The five published-date strings move to the recipe's own namespace `L10n.PublishedDate` *(new)*, values unchanged: `sources.list.publishedLabel` → `publishedDate.label` ("Published"), `sources.list.noPublishedDate` → `publishedDate.none` ("No published date"), `sources.list.publishedHelp` → `publishedDate.help` ("Published %@"), `sources.list.publishedSpoken` → `publishedDate.spoken` ("published %@"), `sources.list.noPublishedDateSpoken` → `publishedDate.noneSpoken` ("no published date"); each comment names "a Source's published date on a row (the Sources list, the Person page's Sources section, the Source page header, the Copy Source form)". Both `L10n.swift` and `Localizable.xcstrings` change; the old keys go. `conclusions.sources.columnDate`: value "Date" → "Published", comment "Column heading over the published date of each Source on a Person's Sources section". Removed: `conclusions.sources.dateNone`, `conclusions.sources.dateNotRecorded`. `sources.list.columnPublished` (the list's own caption) stays | Recipes own their copy (`L10n.LastUpdated`, `L10n.Unpromote`); no PR in either map moves these keys (S15-42 moves only `sources.page.date…`) (review M-3). "Published" is the date's one name (S15-04 D-14, user 2026-11-10) | Keeping the `sources.list.*` keys with widened comments — a Conclusions section and a Platform type reading a list's keys; reusing `sources.list.columnPublished` for the caption — the section's other captions are `conclusions.sources.*` |
| D-8 | `BenchmarkSourceRecords` seeds a date on every Source (worst case: 3,000 date rows). In `seed`, before the `sources` INSERT, call `datevalues.InsertTx(tx, datevalue.Value{Kind: datevalue.KindPoint, StartYear: &year})` with `year := 1800 + src%200` and add `date_value_id` to the `sources` INSERT with the returned id. The budget stays S16-12's: Build at most 50 ms and 8 MB at 3,000 Sources × 10 Artifacts. The benchmark reports and does not assert; the implementer reads the figures and stops over budget. Baseline before this PR: 25 ms and 5.7 MB (S16-12 ship log) | Rule "measure at Scale"; every Source dated is the most this read can cost; `InsertTx` keeps the seed in step with the table (review M-5) | Seeding a fraction dated — understates the worst case; raw `INSERT INTO date_values` — copies the package's columns |
| D-9 | `S15-42`'s scope line in the map no longer asks for `SourcesRowDate`'s rename: D-5 does it (`SourceDateText`, with the recipe `PVPublishedDate`). The map was changed with this plan | The rename is forced here by layering; the map must not ask for it twice | Leaving the line — S15-42's planner would look for a type that is gone |
| D-10 | The recipe's undated text ("Undated" in `.bare`, "No published date" in `.labeled`) is drawn in `PVColor.textSecondary` with `.italic()`, caption size, one line, in place of `PVColor.textFaint`. This is the only change to the moved body; the Sources list takes it too (user, 2026-11-20) | Board decision on PS-3: faint ink is 2.6:1 in light, below 4.5:1; italic sets undated apart from a date, as the Person header's "date unknown" does | Faint in the section only — two looks for one state; a muted tone — 4.4:1, still below 4.5:1 |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

Searched: `SourcesPublishedDate`, `SourcesRowDate`, `spokenBase`, `PVLastUpdated`, `TimestampFormat`, `PVListDetailCell`, `PVDatePlaceLine`, `DateRowDisplay`, `settleDate`, `fillDates`, `LookupManyTx`, `InsertTx`, `ownedValue`, `ReadSourceRecords`, `source_date`, `rowUndated`, `L10n.Unpromote`.

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `Record.Date` *(new)* | field | `Source.Date` (`core/database/sources/sources.go`) | Reuses its rule (`settleDate`) and type; the record is the cached read the Person page uses (D-1) |
| `lookupDates` *(new)* | func | the loop in `fillDates` | It is that loop, pulled out so `loadRecords` shares it (D-2) |
| `ReadSourceRecords` from `ownedValue`'s Source owners *(new)* | registry rule | the `artifacts` and `source_credibility_assessments` `ReadSourceRecords` paths | Extends the same read with the table the record gains, from the owner path the entry already names (D-3) |
| `PersonClaimGroup.source_date` *(new)* | proto field | `Source.date` (field 14) | Same message type; the group carries only what the section draws (D-4) |
| `CatalogPersonClaimGroup.sourceDate`, `PersonSourcesContent.Row.date` *(new)* | Swift fields | `CatalogSource.date` | Same type, `CatalogDateValueInput?` |
| `macos/App/Platform/SourceDateText.swift` *(new)* | Platform formatter | `SourcesRowDate`, `SourcesListRow.spokenBase`, `TimestampFormat` | It is the first two moved, unchanged, to the layer that owns value formatting (D-5) |
| `macos/App/DesignSystem/Recipes/PublishedDate/PVPublishedDate.swift` *(new)* | recipe | `SourcesPublishedDate` (private), `PVLastUpdated` | It is the first moved, unchanged, with a second caller; `PVLastUpdated` is the shape of a recipe over a Platform formatter (D-5) |
| `L10n.PublishedDate` *(new)* | L10n namespace | `L10n.LastUpdated`, `L10n.Unpromote` | The recipe's copy, moved from `L10n.Sources` (D-7) |
| `TestRecordsDate` *(new)* | Go test | `TestRecordsBuild` | A table of date cases; `TestRecordsBuild` stays about words |
| `TestClaimsSourceDate` *(new)* | Go test | `TestClaimsAfterSourceEdit` | Same shape, for the date |
| `publishedDateCell` *(new)* | Swift test | `cellsAndFallbacks` | Dated and undated rows; `cellsAndFallbacks` keeps its type and title cases with the new spoken words |

**Builds on.** S16-12's Source record and Apply-by-read; S15-43's `settleDate`; the effects registry's keyed reads (`add-audit-scope`); S15-04's published date and copy; the layering rule (formatter in `Platform/`, recipe composes it); `add-ui-component`'s promotion rule (snowflake → recipe at the second call site).
**Deletes.** `macos/App/Features/Sources/SourcesRowDate.swift` (`SourcesRowDate`); `SourcesPublishedDate` and `SourcesListRow.spokenBase` in `SourcesListRow.swift`; the keys `sources.list.publishedLabel`, `sources.list.noPublishedDate`, `sources.list.publishedHelp`, `sources.list.publishedSpoken`, `sources.list.noPublishedDateSpoken` (moved, D-7); `L10n.Conclusions.sourcesDateNone`, `L10n.Conclusions.sourcesDateNotRecorded` and their `Localizable.xcstrings` entries; the loop in `fillDates` (into `lookupDates`); the dash placeholder in `PersonSourcesRowView.columns`.
**Next adds.** S15-22 regroups the section's rows and keeps the Published cell and `SourceDateText.spokenRow` (a citation count joins it there); S15-42 shows the mark in the Source page header through `SourceDateText` and no longer renames `SourcesRowDate` (D-9); a later row that shows a Source's date (the Promote list, a picker) draws `PVPublishedDate`; a later Source-held value row passes a Source owner to `ownedValue` and gets both jobs.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A `date_values` change now names Sources in `source_records` | `sources.Records` `Apply`; Swift keys that follow `.reads(.sourceRecords)` (`CatalogLastUpdated.swift` `applyHiddenPolicy`) | `Apply` reloads the named Sources and patches (no new code). Every `entityPage` key whose inputs name the Source follows (`followsInputs`): the Person claims and record links keys, and also `.conclusionDetail` (`macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift`) of every page citing it, whose Vitals, Gallery and provenance sheet do not draw the date: accepted as the coarse read's cost, the same as a Source rename today (review M-7). A date row released with the Source's id cleared names no Source (the `inbound` query finds none) and the `sources` row change names it instead; a `date_values` row of an Observation finds no Source and moves nothing (AC-3.3) |
| A dated Source on the Person page | `PersonSourcesRowView` | Dated, undated, unknown and phrase states (AC-1.1 – AC-1.6) |
| A `date_value_id` with no row (crafted) | `loadRecords` → `settleDate` | Reads as undated (S15-02's rule); `Check` agrees, since both sides call `loadRecords` |

### Scale

At the map's Scale: **3,000 Sources** in a project (the records' Build), **30 Sources** on a Person page.

- **Build** (first read, or after `Drop`): one more batched query (`datevalues.LookupManyTx`, only the dated ids) over up to 3,000 date rows; one `datevalue.Value` per dated Source on the heap. Budget: S16-12's, at most 50 ms and 8 MB at 3,000 Sources × 10 Artifacts, every Source dated (D-8, T-5).
- **Apply**: one more batched lookup for the named Sources' dates; ordinary commits name one Source.
- **A date write**: an in-place edit now reloads one Source record (two small queries plus one date lookup) and refreshes the Swift keys whose inputs name that Source: the Person claims, record links and conclusion detail keys of the pages that cite it (30 Sources per page at Scale), each re-read when shown (S16-25's follow), as a Source rename does today. An Observation's date write runs the same `inbound` query it already runs for `SourceScope` and names no Source.
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
| `core/database/sources` | `records.go`: `Record.Date *datevalue.Value` *(new)*; `sqlRecordSources` selects `s.date_value_id`; `loadRecords` fills `Date` per D-2. The `Record` doc names the date. `sources.go`: `lookupDates` *(new)*; `fillDates` calls it |
| `core/database/effects` | `registry.go`: `ownedValue(entity, col string, sourceOwners ...Path)` adds `ReadPath{ReadSourceRecords, owner}` to `Reads` for each Source owner (D-3); its doc comment says so and that each path ends at `sources`; the `ReadSourceRecords` comment adds "its date" |

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
| Published date | recipe *(promoted)* | `macos/App/DesignSystem/Recipes/PublishedDate/PVPublishedDate.swift` *(new)* | D-5; README built-table row; composes `SourceDateText` |
| Published date text | Platform formatter | `macos/App/Platform/SourceDateText.swift` *(new)* | D-5; also read by `SourceCopyModel` and `SourcePageIdentityHeader` |
| Caption line | snowflake | `PersonSourcesList.header` | `L10n.Conclusions.sourcesColumnDate` now reads "Published" (D-7) |
| Columns | snowflake | `PersonSourcesColumns` | Unchanged (120pt) |
| Type pill | recipe | `CatalogSourceTypePill` | Unchanged |
| Sources list | snowflake | `macos/App/Features/Sources/SourcesListRow.swift` | Calls `PVPublishedDate` in its three places; dated values look the same, undated text ("Undated", "No published date") becomes italic secondary (D-10) |

Frames in words (as agreed on the board, turn 19), over `PersonSourcesPreviewData.johannClaims`: **1a/1b** Johann Weber's Sources section at Regular (1102) and Wide (2296), the diagram beside the rows; caption SOURCE · TYPE · PUBLISHED · REF; in title order "Hamburg census 1867" reads "1867", "Hamburger Adressbuch 1861" "abt 1861", "Hamburger Nachrichten, obituary 1880" an italic "Undated", "Konfirmandenbuch St. Ansgarii 1831" the phrase "in the reign of Wilhelm I" (truncated), the `src-verein` Source (the long "Verzeichniß der Mitglieder" title) an italic "Undated" (its date marked unknown); the columns as today at both widths. **2** the phrase truncated in 120pt with its hover "Published in the reign of Wilhelm I". **3** the spoken label of a dated and an undated row (AC-2.1, AC-2.2).

Preview data (STEP-5), each `sourceDate` a `CatalogDateValueInput`:

| Fixture | Source | `sourceDate` |
| --- | --- | --- |
| `johannClaims` | `src-census` "Hamburg census 1867" | `CatalogDateValueInput(kind: "point", startYear: 1867)` |
| `johannClaims` | `src-adress` "Hamburger Adressbuch 1861" | `CatalogDateValueInput(kind: "point", qualifier: "ABT", startYear: 1861)` |
| `johannClaims` | `src-news` | nil |
| `johannClaims` | `src-konf` | `CatalogDateValueInput(kind: "point", phrase: "in the reign of Wilhelm I")` |
| `johannClaims` | `src-verein` | nil |
| `regular` | `src-1` "Hamburg census 1867" | `CatalogDateValueInput(kind: "point", startYear: 1867)`; the other `regular` groups nil |
| `folded`, `manySources`, `manyClaims`, `crowdClaims` | all | nil |

No Source is added or renamed. Use the `CatalogDateValueInput` initializer labels as declared in `macos/App/Platform/GenealogyStore.swift`; the qualifier string is `datevalue.QualifierABT` ("ABT"), which `DateRowDisplay` writes as "abt".

States: undated and unknown read "Undated" (italic, secondary ink, D-10); loading, empty and error are the section's, unchanged. Accessibility: the cell stays hidden; the row's one spoken element carries the date (D-6). Wide: unchanged arrangement (PS-W1).

### Strings

Moved to `L10n.PublishedDate` *(new)* (D-7), values unchanged: `publishedDate.label`, `publishedDate.none`, `publishedDate.help`, `publishedDate.spoken`, `publishedDate.noneSpoken`. Changed: `conclusions.sources.columnDate` "Date" → "Published". Removed: `conclusions.sources.dateNone` ("—"), `conclusions.sources.dateNotRecorded` ("date not recorded"), and the five `sources.list.*` keys moved above.

## 7. Steps

**Host.** STEP-1 and STEP-2 run on any host with Go and cgo. STEP-3's proto generation and every Xcode check (STEP-3 to STEP-6, `scripts/check-pr.sh`) need the macOS host with `protoc`, `protoc-gen-go`, `protoc-gen-swift` and Xcode. On a host without them, finish STEP-2, then stop and report.

**STEP-1 — The Source record carries the date**
Files: `core/database/sources/records.go`, `core/database/sources/sources.go`, `core/database/sources/records_test.go`, `core/database/sources/records_bench_test.go`. Skill: `add-date-value`.
Do: D-1, D-2 (with `lookupDates`). Add `TestRecordsDate` (T-1, Build cases). Seed the benchmark per D-8.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sources/` passes; `CGO_ENABLED=1 go test -tags fts5 -run '^$' -bench BenchmarkSourceRecords -benchtime 1x ./core/database/sources/` reports `build-ms` ≤ 50 and `heap-MB` ≤ 8 (read the figures; the benchmark asserts nothing).

**STEP-2 — An in-place date edit reloads the record**
Files: `core/database/effects/registry.go`, `core/database/effects/reads_test.go`, `core/database/sources/records_test.go`, `core/database/persondetail/claims_test.go`, `.agents/skills/add-audit-scope/SKILL.md`, `.agents/skills/add-date-value/SKILL.md`. Skill: `add-audit-scope`.
Do: D-3. `TestReadsDeclare` adds `date_values` to `ReadSourceRecords`. `TestRecordsApply` gains the date rows of T-1; add `TestClaimsSourceDate` (T-3). In `add-audit-scope`, the owner paragraph says a Source owner path moves both the owner's scope and its `source_records`, and the `source_records` paragraph lists `date_values` among the tables that set it (through `ownedValue`), dropping its sentence that names S15-05; in `add-date-value`, the ownership paragraph says the same of `sources.date_value_id`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/effects/ ./core/database/sources/ ./core/database/persondetail/` passes; `python3 scripts/check-guidance-names.py` passes.

**STEP-3 — The date reaches Swift**
Files: `api/proto/engine.proto`, generated `api/proto/engine/engine.pb.go` and `macos/App/Platform/Generated/engine.pb.swift`, `api/ffi/handlers/person_detail.go`, `api/ffi/handlers/person_detail_test.go`, `macos/App/Platform/GenealogyStore.swift`, `macos/App/Platform/GoStore.swift`. Skill: `add-ffi-handler`.
Do: D-4. Run `./scripts/generate-proto.sh`. Extend `TestListPersonClaims` (T-4).
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/ffi/handlers/ -run TestListPersonClaims` passes; the Xcode build succeeds.

**STEP-4 — The date's text and look move to their layers**
Files: `macos/App/Platform/SourceDateText.swift` *(new)*, `macos/App/DesignSystem/Recipes/PublishedDate/PVPublishedDate.swift` *(new)*, `macos/App/Features/Sources/SourcesRowDate.swift` (deleted), `macos/App/Features/Sources/SourcesListRow.swift`, `macos/App/Features/Sources/SourcePageIdentityHeader.swift`, `macos/App/Features/Sources/SourceCopyModel.swift`, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `macos/App/DesignSystem/README.md`, `macos/ProvenenciaTests/SourcesModelTests.swift`, `macos/ProvenenciaTests/SourceCopyModelTests.swift`. Skills: `add-ui-component`, `add-localized-string`.
Do: D-5, and D-7's five moved strings. Put `enum PublishedDate` in `L10n.swift` directly before `enum LastUpdated`; its xcstrings entries take the shape of the `lastUpdated.*` entries. Move, do not change, except D-10: the view's body and the four functions keep their code, reading `L10n.PublishedDate`. `PVPublishedDate` gets a `#Preview` with `CatalogDateValueInput(kind: "point", startYear: 1880, startMonth: 6, startDay: 1)`, `CatalogDateValueInput(kind: "point", phrase: "in the reign of Victoria")` and nil, each in both styles. Add the README built-table row `PublishedDate`. Rename the callers and the tests' calls (`SourcesListRow.spokenBase(…)` → `SourceDateText.spokenRow(…)`, same labels).
Check: `rg -n 'SourcesRowDate|SourcesPublishedDate|spokenBase|sources\.list\.(publishedLabel|noPublishedDate|publishedHelp|publishedSpoken)' macos/` has no hit; `python3 scripts/check-localizable-xcstrings.py` passes; Xcode tests pass; the Sources list's dates look the same at Regular, Wide and 860pt and its undated text is italic secondary (manual: §10 step 6; no automated check covers the look).

**STEP-5 — The section draws the date**
Files: `macos/App/Features/Conclusions/PersonSourcesContent.swift`, `macos/App/Features/Conclusions/PersonSourcesSection.swift`, `macos/App/Features/Conclusions/PersonSourcesPreviewData.swift`, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `macos/ProvenenciaTests/PersonSourcesContentTests.swift`. Skills: `add-localized-string`, `add-swift-test`.
Do: D-6, and D-7's three Conclusions keys. Preview data per §6 macOS. In `PersonSourcesContentTests`, build dated groups by passing `sourceDate:` to `CatalogPersonClaimGroup(...)` directly; the `claim` and `content` helpers do not change. Add `publishedDateCell` (T-6) and update `cellsAndFallbacks` (T-7).
Check: Xcode tests pass with no Swift warning; `python3 scripts/check-localizable-xcstrings.py` passes; the "Johann" and "Johann, Wide" previews show the dates of the §6 table.

**STEP-6 — Docs and version**
Files: `docs/catalog-caches.md` (row `sources.records`: "Build: three queries (every Source with its grade and date id, the dated Sources' date rows, every Artifact)", and the measured size at 3,000 dated Sources), `VERSION`, `core/version.go`, every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`, `docs/deployment-plan/spike-15/completed.md`, `docs/deployment-plan/spike-15/deployment-plan.md` (map row), this plan (status), `docs/deployment-plan/spike-15/design/S15-D3-person-sources-date.md` → `design/archive/`, `docs/deployment-plan/spike-15/design/README.md`.
Do: per the Definition of done. Version: the minor above `VERSION` on `main` when you branch.
Check: `VERSION`, `core.Version` and every `MARKETING_VERSION` line agree; `python3 scripts/check-plan-docs.py --links docs/catalog-caches.md` passes.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/sources/records_test.go` `TestRecordsDate` *(new)*, table-driven; and `TestRecordsApply` rows "date set", "date edit", "date unknown", "date clear", "observation date edit", run in that order on `r.Source` after the existing rows and before "source delete" | **Build** (`TestRecordsDate`, each case a fresh `recordsFixture` and `sources.SetDate` through `r.Run("set_source_date", func(tx) { _, ch, err := sources.SetDate(tx, evidencelayertest.UserID, src.ID, date, mark); return ch, err })`, then `g.Drop()` and `records(t, r)`): undated → `Date` nil; `datevalue.Value{Kind: datevalue.KindPoint, StartYear: &y1867}` → year 1867; `1 Jun 1880` (`KindPoint`, StartYear 1880, StartMonth 6, StartDay 1) with `valuemark.Mark{Supplied: true}` → the date; `nil` with `valuemark.Mark{Unknown: true}` → nil. **Apply** (each through `check(t, true|false, write)`, which runs `g.Verify()`): "date set" `SetDate` 1867 on the undated Source → moves, `Date` 1867; "date edit" `SetDate` 1868 (the held row rewritten in place, the only row that proves D-3: with D-3 reverted it fails) → moves, 1868; "date unknown" `SetDate(nil, Unknown)` → moves, nil; "date clear" `SetDate` 1870 then `SetDate(nil, Mark{})` → moves, nil; "observation date edit" `r.DatedBirth(src, r.Artifact, 1880)` → moves false | AC-1.1, AC-1.3, AC-1.4, AC-3.1, AC-3.2, AC-3.3, D-1, D-2, D-3 |
| T-2 | Go | `core/database/effects/reads_test.go` `TestReadsDeclare` | `ReadSourceRecords` tables = `artifacts`, `date_values`, `source_credibility_assessments`, `sources` | D-3 |
| T-3 | Go | `core/database/persondetail/claims_test.go` `TestClaimsSourceDate` *(new)* | `burialsAndBaptisms`: the group's `Source.Date` nil; after `SetDate` 1867 → 1867; after `SetDate` 1868 → 1868, and `graphfill.Graphs.Peek` still holds the loaded graph; after `SetDate(nil, Mark{})` → nil | AC-3.1, AC-3.2 |
| T-4 | Go | `api/ffi/handlers/person_detail_test.go` `TestListPersonClaims` | Before: `g.GetSourceDate()` nil; after `SetSourceDate` 1880 (point, year, as `citation_render_test.go` sends it) → `GetSourceDate().GetStartYear() == 1880` | AC-3.1, D-4 |
| T-5 | Go | `core/database/sources/records_bench_test.go` `BenchmarkSourceRecords` | 3,000 Sources × 10 Artifacts, every Source dated → `build-ms` ≤ 50, `heap-MB` ≤ 8 (read, not asserted) | D-8 |
| T-6 | Swift | `macos/ProvenenciaTests/PersonSourcesContentTests.swift` `publishedDateCell` *(new)* | A group `sourceDate: CatalogDateValueInput(kind: "point", startYear: 1867)` → `row.date` is it, `accessibilityLabel` "Hamburg census 1867, Census, published 1867, SRC-9TQ2M"; `SourceDateText.line(CatalogDateValueInput(kind: "point", phrase: "in the reign of Wilhelm I"), locale: en_US)` → the phrase; `SourceDateText.help` of the 1867 date → "Published 1867"; nil → `line` nil, `help` nil | AC-1.1, AC-1.2, AC-1.6, AC-2.1, D-6 |
| T-7 | Swift | `macos/ProvenenciaTests/PersonSourcesContentTests.swift` `cellsAndFallbacks` | The fixture groups have no date: "Hamburg census 1867, Census, no published date, SRC-9TQ2M", "Letter, no published date, SRC-4KQ7M" | AC-2.2 |
| T-8 | Swift | `macos/ProvenenciaTests/SourcesModelTests.swift` `publishedDateTextAndSpokenBase`; `macos/ProvenenciaTests/SourceCopyModelTests.swift` | Unchanged expectations, calling `SourceDateText`; `publishedDateTextAndSpokenBase` is renamed `publishedDateTextAndSpokenRow` | D-5 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `TestPragmaHonesty`-adjacent registry tests in `core/database/effects` (`registry_completeness_test.go`), `TestClaimsWarmReadIssuesNoQuery`, `TestRecordsOf`, `CatalogQueryRegistryTests` and `WorkspaceSessionTests` (they build `CatalogPersonClaimGroup`).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left (`SourcesRowDate`, `SourcesPublishedDate`, `spokenBase`, the five `sources.list.*` keys, `sourcesDateNone`, `sourcesDateNotRecorded`; earlier plans' prose is left as written); `scripts/check-guidance-names.py` passes (check-pr runs it)
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

1. (AC-1.1, AC-1.2, AC-1.5, AC-1.6) Open a project with a Person who cites at least three Sources. On the Source page, give one Source the date `1867`, another the phrase "in the reign of Wilhelm I", and leave a third undated. Open the Person page, Sources section. See the caption PUBLISHED, "1867", the phrase truncated with its hover "Published in the reign of …", and an italic "Undated".
2. (AC-3.4) Open the first Source, change its date to `1868`, go Back. The row reads "1868"; the section's unfolded pages and the diagram are as they were.
3. (AC-1.3) On that Source, choose No date… (marked unknown) if S15-42 has landed, otherwise clear the date. The row reads "Undated".
4. Stretch the window past 1600pt of pane: the columns keep their widths; the title and the diagram take the room.
5. (AC-2.1) With VoiceOver, move to a dated row: it reads "…, Census, published 1868, SRC-…".
6. (D-10) Open the Sources list at Regular, Wide and 860pt: a dated Source's published date looks as before; an undated one reads "No published date" (Regular, narrow) or "Undated" (Wide column) in italic secondary ink.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| The new `ReadSourceRecords` path on `date_values` makes every Observation date write reload a Source record | `inbound("sources", "date_value_id")` finds only a Source's own date row; T-1's "observation date edit" row pins moves false |
| The recipe move changes more of the Sources list's look than D-10's undated text | STEP-4 moves code unchanged except D-10; the list's existing tests and the manual check 6 |
| `ownedValue`'s new owner read reaches an entry that should not move the records | Only `date_values` passes a Source owner today; the parameter is named `sourceOwners`; `TestReadsDeclare` pins the tables |

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
