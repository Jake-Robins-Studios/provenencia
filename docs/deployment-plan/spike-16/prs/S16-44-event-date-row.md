# S16-44 — The Event page's Date row shows as-ofs

**Status:** Blocked — on board S16-D6
**Spike / slice:** Spike 16 · Batch 5 · Slice 5a — An attestation is a sample
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S16-D6](../design/S16-D6-event-date-row.md) (Event page: the Date row for an event dated by as-ofs, DR-1 – DR-8, DR-W1); board not agreed yet
**Board:** — (not drawn yet). It will be a new turn "S16-D6 · As-of dates" (frames 8a, 8b, 9, 10) on [Claude Design — Event Detail](https://claude.ai/artifact/5ciAxv86fYtrUvuCHPuuJ5), page `project/Event Detail.dc.html`. The implementer reads it with the Artifact tool's `read` on that link and that `path`, as S16-42 read its boards
**Depends on:** S16-42 (landed [#876](https://github.com/mendahu/provenencia/pull/876)), S16-D6
**Blocks:** —
**Branch:** `s16-44-event-date-row`
**Version bump:** minor — the next minor after `VERSION` on `main` when the branch is cut (0.21.0 → 0.22.0 at the planning base): a change a researcher sees on every as-of event's page, and wire fields removed from `EventSummary` that client and core drop together ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-date-value`](../../../../.agents/skills/add-date-value/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`, `.cursor/rules/swift-tests.mdc`
**Context:** [`event-as-of.md` § The dating envelope](../event-as-of.md#the-dating-envelope), [`structured-date-model.md` § 3.4](../../../structured-date-model.md#34-the-display-date-of-an-event), working rules (Batch 5): "The engine sends the dating, not the as-ofs", "As-ofs alone make a span open on both sides", "One dating, in Go, derived on read"; [S16-42 plan](S16-42-event-dating-line.md) D-14 and its Landed note; [S16-42 review](S16-42-event-dating-line.review.md) M-9; [S16-42 ship log](S16-42-event-dating-line.ship.md) UX-1
**Planned:** 2026-11-17 against `main` @ `2bcfd1f`
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

Since S16-42, an event dated only by its **As of** dates reads `as of 10 Jan 1990–10 Feb 2015` in its Event page header, while its Date row still says **No date recorded** (S16-42 ship log UX-1). After this PR the Date row chooses what it shows by the dating the engine sends, and an as-of event's row lists each kept as-of, earliest first, with its Source count, plus the start or end that closes a side; its Why lists every record behind those lines (dogfood bar 18's Event page clause). Then the old date fields that only this row still read leave every layer: `EventSummary.Date`, `StartDate`, `EndDate` and their counts (Go, proto, `GoStore`, `CatalogEventSummary`), with `oneEvent`'s rule that clears the start and end when a `date` is kept (user, 2026-11-17; S16-42 review M-9).

**Why now.** S16-42 left the header and the Date row contradicting each other on every as-of event, and kept the three summary fields alive only for this row.

**What stays.** An event with a `date` shows the `date` field's row, with its badge, Source count and other values, as today, even when it also has as-ofs. An event with a start and an end and no as-of shows the start–end span with one Why for both, or the one side recorded, as today. The header, the Place row, the gallery and every other date line read as today. Nothing writes `start_date` or `end_date`.

## 2. User stories

**US-1.** As a researcher, when I open an event I know only from an obituary of 10 Jan 1990 and a directory of 10 Feb 2015, its Date row lists both as-ofs with their Sources, so that I see what the header's `as of 10 Jan 1990–10 Feb 2015` stands on.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | As-ofs 10 Feb 2015 (2 Sources) and 10 Jan 1990 (1 Source), no `date`, start or end; dating `.asOf` 10 Jan 1990–10 Feb 2015, both open | The row lists `as of 10 Jan 1990` · `1 Source`, then `as of 10 Feb 2015` · `2 Sources` (date order, D-2); no badge; never `No date recorded` |
| AC-1.2 | The same event, Why opened | The Why lists the obituary's record and both directory records, each read as its date; title `Why “as of 10 Jan 1990–10 Feb 2015”` |
| AC-1.3 | One as-of, 10 Jan 1990 | One line, `as of 10 Jan 1990` · `1 Source` |
| AC-1.4 | As-ofs `abt 1990` and `bef 2015` | `as of abt 1990`, `as of bef 2015` |
| AC-1.5 | VoiceOver on the AC-1.1 row | It speaks `Date, as of 10 Jan 1990; as of 10 Feb 2015` (the label, then each line, joined as a multi-valued row joins them) |

**US-2.** As a researcher, when an as-of event also records a start or an end, the row shows it beside the as-ofs, so that I see which side the researcher closed.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Start 1985; as-ofs 10 Jan 1990 and 10 Feb 2015 | Lines `from 1985`, `as of 10 Jan 1990`, `as of 10 Feb 2015` (wording per the board, D-3); the Why holds the start's record too |
| AC-2.2 | As-of 1990; end 2015 | Lines `as of 1990`, `until 2015` |
| AC-2.3 | Start 1985; as-of 1980 (before the start; the dating opens its low side) | Lines `from 1985`, `as of 1980`: start, as-ofs, end, in that order, whatever the dates say (Edges) |

**US-3.** As a researcher, events dated as before keep their Date row.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `date` 14 May 1817, plus a start 1849 and an as-of 1820; dating `.occurrence` | The `date` field's row: `14 May 1817`, its records only |
| AC-3.2 | Start 1849, end 1851; dating `.span` | One row, lead `1849–1851`, Why holds both records, no badge |
| AC-3.3 | Start 1849 only; dating `.span` | The `start_date` field's row, relabeled `Date`, lead `1849` |
| AC-3.4 | No date recorded on any of the four keys; dating `.none` | `No date recorded`, no Why |
| AC-3.5 | A `date` record whose value was not kept, and nothing else; dating `.none` | The `date` field's row: `No date recorded`, its Why holds the record (as today) |

**US-4.** As the engine, a crafted event with 10,000 as-ofs stays bounded on its page.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | 10,000 kept as-ofs | The row lists 20 lines, then one line `9,980 more` (wording per the board, D-4); the Why still lists every record |
| AC-4.2 | The same event's `conclusiondetails.ForEntity` | Its `as_of` field's values arrive in date order, and the read takes no more than twice its time at the planning base (T-2) |

**US-5.** As a contributor, an event summary carries one date reading: the dating.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-5.1 | `rg` for the retired names | `EventSummary` (Go, proto, Swift) has no `Date`, `DateCount`, `StartDate`, `StartDateCount`, `EndDate`, `EndDateCount` field; proto fields 6 – 11 are `reserved` with their names |
| AC-5.2 | The Events list, the Timeline, search, Promote | Read as before (they read `dating` since S16-42); their tests pass unchanged |

## 3. Scope

| In | Covered by |
| --- | --- |
| DR-1: an occurrence and a span keep today's row | STEP-2, AC-3.1 – AC-3.5 |
| DR-2, DR-5: an as-of event's row lists each kept as-of, earliest first, with its Source count | STEP-1, STEP-2, AC-1.1, AC-1.3 |
| DR-3: the start's line first, the end's last | STEP-2, AC-2.1 – AC-2.3 |
| DR-4: each line keeps its qualifier and phrase | STEP-2, AC-1.4 |
| DR-6: the Why lists every record behind the lines; no badge | STEP-2, AC-1.2 |
| DR-7: no new layout, chip, badge or icon | STEP-2, §6 macOS |
| DR-8: at most 20 lines, then a remainder line | STEP-2, AC-4.1 |
| DR-W1: the same at Regular and Wide | §10 manual check |
| A multi-valued date field's values arrive in date order (user, 2026-11-17) | STEP-1, AC-4.2 |
| Retire `EventSummary.Date` / `StartDate` / `EndDate` and their counts on every layer; `oneEvent`'s clear rule (map scope entry, S16-42 review M-9) | STEP-3, AC-5.1, AC-5.2 |
| `structured-date-model.md` § 3.4 names the Date row and the value order | STEP-4 |

| Out | Home |
| --- | --- |
| The header's date line | S16-42 (landed) |
| A notice for an as-of outside the start or end | descoped (user, 2026-11-17); [idea](../../../ideas/event-as-of-followups.md) |
| The as-ofs of an event that also has a `date` on its Date row | not planned (the occurrence wins, as an occurrence's start and end are not shown today; brief § 2.1) |
| A cap on the values of other multi-valued rows (a Place's names) | not planned (no crafted-data bar names it) |
| Deleting `DateRowDisplay.span(start:end:)` | not planned: `line(dating:)` still calls it (D-7) |
| `PlaceSummary.StartDate` / `EndDate` and `placeShell`, `assocDatesOf` | not planned: a Place's and an association's own period, not an event's dating |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Date row | `macos/App/Features/Conclusions/EventDetailContent.swift` `EventDetailContent.dateRow(_:summary:locale:)` | Branches on `summary?.date`, `summary?.startDate`, `summary?.endDate` and on `SeededPropertyKey.date`, `.startDate`, `.endDate` fields. Never reads `summary.dating` or the `as_of` field, so an as-of event's row is `.empty` ("No date recorded"). The two-field span lead is `DateRowDisplay.span(start:end:)`, its last event caller |
| Header date | `EventDetailContent.init` → `EventSecondaryDisplay.content` | Reads `summary.dating` (S16-42). Stays |
| Row model | `macos/App/Features/Conclusions/ReconciledValueRowModel.swift` `ReconciledValueRowModel.spanning(id:label:lead:emptyText:fields:locale:)` | One row whose lead spans several fields; Why = `PVProvenanceSheetContent.spanning` (every record of the fields, one group); no badge, no count; `shown.listedValues` always `[]`. Callers: `EventDetailContent.dateRow`, `PlaceDetailContent.periodRow` |
| Row model, one field | `ReconciledValueRowModel.init(field:locale:orders:)` | A `multiple` field lists every displayed value in `shown.listedValues` (`PVProvenanceSheetContent.Shown.init(field:)`); the spoken lead joins them with `"; "` |
| Value lines | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceParts.swift` `PVProvenanceValueList`, `PVProvenanceValueLine` | Shows `listedValues` when not empty, else the lead, else the empty text. `ForEach(shown.listedValues)` keys on `Value.id`, which is `rank` |
| Listed value | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheetContent.swift` `PVProvenanceSheetContent.Value` (`rank`, `text`, `support`), `PVProvenanceSheetContent.value(_:propertyKey:locale:orders:)` | `text` from `ReconciledValueDisplay.string` (a date → `DateRowDisplay.line(date:)`), `support` from `ReconciledValueDisplay.sourceCountLine` ("1 Source") |
| Date formatter | `macos/App/Platform/DateRowDisplay.swift` `DateRowDisplay.line(date:)`, `span(start:end:)`, `line(dating:)` | `line(dating:)` formats the header line and calls `span(start:end:)` for `.span` and for a closed-both-sides `.asOf` |
| Copy | `macos/App/Platform/L10n.swift` `L10n.Dates.rowAsOf`, `rowFromAsOf`, `rowAsOfUntil`; `L10n.Conclusions.whyTitle`, `sourceCount`, `placeContainsMore` | "as of %@", "from %1$@, as of %2$@", "as of %1$@, until %2$@"; `Why “%@”`; "%lld Source(s)"; "%lld more" (the Place page's Contains remainder) |
| Seeded keys | `macos/App/Platform/ConclusionVocabulary.swift` `SeededPropertyKey` | Has `date`, `startDate`, `endDate`; no `asOf` |
| Truncation precedent | `macos/App/Features/Conclusions/PlaceDetailContent.swift` `PlaceDetailContent.containsVisibleLimit` (12), `relationshipSections`; `PlaceRelationshipRow.swift` line 135 | Shows the first 12 Contains, then `L10n.Conclusions.placeContainsMore(omitted)` |
| Detail values | `core/database/conclusiondetails/conclusiondetails.go` `Field.Values` (`// rank order`), `attachValues`, `finish` | `attachValues` appends `n.Values[prop]` in rank order (support, then provenance, then Observation id: `core/autoreconcile/pipeline.go` `reconcile`). `finish` orders `Outcomes` by `GroupRank`, then `ValueRank` (none last), then Observation id. So two as-ofs arrive in an order unrelated to their dates |
| Date order | `core/valuecompare/dateorder.go` `DateKeyOf`, `DateKey.Compare` | The one date order; `ok` false for a date with no place |
| Summary fields | `core/database/conclusionsummaries/events.go` `EventSummary` | `Date`, `DateCount`, `StartDate`, `StartDateCount`, `EndDate`, `EndDateCount` beside `Dating`. Its doc comment still says "A rank-1 date wins over a start/end span; the span's counts are still reported" |
| Summary compose | `core/database/conclusionsummaries/compose.go` `oneEvent` | Reads the three into `h.Date`, `h.StartDate`, `h.EndDate` (with counts), passes them to `valuecompare.DatingOf`, and at the end clears `h.StartDate` and `h.EndDate` when `h.Date != nil` |
| Go readers | `api/ffi/handlers/conclusion_summaries.go` `eventSummaryProto` | The only non-test reader outside `oneEvent` (checked: removing the six fields leaves compile errors only there and in tests) |
| Proto | `api/proto/engine.proto` `message EventSummary` | Fields 6 `date`, 7 `date_count`, 8 `start_date`, 9 `start_date_count`, 10 `end_date`, 11 `end_date_count`; 19 `dating` |
| Swift summary | `macos/App/Platform/GenealogyStore.swift` `CatalogEventSummary`; `macos/App/Platform/GoStore.swift` `mapEventSummary` | The six fields mapped from the proto. Swift readers: only `EventDetailContent.dateRow` |
| Preview data | `macos/App/Features/Conclusions/PersonTimelinePreviewData.swift` `When.apply(to:)` | Sets `date` / `dateCount` / `startDate` / `endDate` / counts beside `dating` |
| Go tests | `core/database/conclusionsummaries/conclusionsummaries_test.go` `TestListEvents` (lines 573 – 587), `TestSummariesShowKeptValuesOnly` (line 255), `TestListKeysFollowListOrder` (line 1672), helper `summary(date, start, end, samples...)` (line 1313); `api/ffi/handlers/conclusion_summaries_test.go` `TestListEventSummaries` (line 253) | Assert on the six fields |
| Go detail tests | `core/database/conclusiondetails/conclusiondetails_test.go` `TestForEntityGroupsOutcomesByShownValue`, fixture `newFixture`, `source`, `subjectOn`, `cite`, `promote`, `detail`, `field`, `outcomeOf` | The outcome order of a single-valued name field. Stays green |
| Swift tests | `macos/ProvenenciaTests/EventDetailTests.swift` helper `dated(date:start:end:dating:)` and the Date row tests; `macos/ProvenenciaTests/PersonsListTests.swift` `eventsRowSecondLine` (line 156, `date:` argument) | Set the six fields |

**Precedent.** The retirement copies `f0245d7` (*Order every Conclusion list by one key Go computes*), which removed `MetadataWorkspaceEntry.date_summary` and reserved its number and name in `engine.proto`. The row copies the Place page's `PlaceDetailContent.namesRow` (a multi-valued field's values as stacked lines, the spoken label joined with `"; "`) and its Contains truncation (`containsVisibleLimit`, `placeContainsMore`). S16-42's STEP-11 is the last change to `dateRow`; do not copy its `span(start:end:)` call.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | **The row chooses by `summary.dating.kind`** (working rule K-3). Fields are looked up in `detail.fields` by key; a field "with records" has `!outcomes.isEmpty`. `.occurrence` → the `date` field's row, relabeled `Date` (today's `labeled`); if no `date` field has records, `.spanning` with the dating line as lead and no fields. `.span` → the `start_date` and `end_date` fields with records: one → that field's row, relabeled; two → `.spanning` with lead `DateRowDisplay.line(dating:)`; none → `.spanning` with that lead and no fields. `.asOf` → `.spanning` over the `start_date`, `as_of`, `end_date` fields with records (that order), lead `DateRowDisplay.line(dating:)`, listed lines per D-3 and D-4. `.none` → the `date`, `start_date`, `end_date`, `as_of` fields with records: none → `.empty`; one → that field's row, relabeled (it shows its empty text and its Why); several → `.spanning` with no lead. A nil summary reads as `.none` | Swift formats the dating and never picks a key (K-3); each kind names its fields, so no branch reads the old summary fields | Keeping the `summary.date` / `startDate` checks — the fields retire in this PR (STEP-3) |
| D-2 | **Go orders a multi-valued date field's values by date.** In `conclusiondetails.finish`, a field with `cardinality == propertymeta.CardinalityMultiple` and `ValueType == propertymeta.ValueTypeDate` sorts `Values` by `valuecompare.DateKeyOf` of `Value.Date` (key computed once per value), stable; a value with no key (`ok` false or nil date) goes last; ties keep rank order. `Rank` is unchanged on each value. Every field's `Outcomes` then order their groups by their value's position in `Values` instead of by the rank number (none last, then Observation id, as today), so the Why's runs follow the lines. `Field.Values`' comment says so | The user chose date order (2026-11-17); Go owns the one date order (`DateKeyOf`), so Swift compares no dates; only `as_of` is such a field in the seed, and a user's own multi-valued date Property gets the same reading | A Swift sort — a second date order in Swift; sorting in `attachValues` before outcomes exist — `finish` is where the field's orders are set |
| D-3 | **The lines of an as-of row** (DR-2 – DR-5), built in `EventDetailContent` *(new private static `asOfLines(start:asOf:end:locale:)`)*: the `start_date` field's first displayed value → `L10n.Dates.rowFrom(date)` *(new)*; each displayed `as_of` value in the field's order → `L10n.Dates.rowAsOf(date)`; the `end_date` field's first displayed value → `L10n.Dates.rowUntil(date)` *(new)*. `date` is `DateRowDisplay.line(date:locale:)` of the value (qualifier and phrase kept). `support` is `ReconciledValueDisplay.sourceCountLine(value.support)`. A value whose date text is empty is skipped. Each line's `rank` is its 1-based position, so `ForEach` ids are unique across the three fields. The board's wording for DR-2 / DR-3 replaces the recommended copy, not this structure | Lines reuse the recipe's `Value` and the S16-D4 "as of" copy; position ranks avoid a start's rank 1 colliding with an as-of's rank 1 | Reusing `PVProvenanceSheetContent.value(_:)` — it yields the bare date, which reads as an occurrence (DR-5) |
| D-4 | **At most 20 lines** (DR-8): `EventDetailContent.dateLineLimit` *(new)* `= 20`. Past it, the first 20 lines, then one line `L10n.Conclusions.eventDateMore(omitted)` *(new)* with `support` `""`. The spoken label reads the shown lines and the remainder line | The Batch 5 Scale: real data has up to 20 as-ofs, crafted data 10,000, which only has to stay bounded; the Place page's Contains is the precedent | No cap — 10,000 `Text` lines in a non-lazy stack; reusing `placeContainsMore` — its comment and translations are about Contains |
| D-5 | **Extend `ReconciledValueRowModel.spanning`** with `listed: [PVProvenanceSheetContent.Value] = []`. `shown` carries them as `listedValues` (the `Shown` memberwise init). When `listed` is not empty, `accessibilityLabel` is `L10n.DesignSystem.spokenJoin(label, listed.map(\.text).joined(separator: "; "))`; `whyTitle` stays `L10n.Conclusions.whyTitle(lead)`. No badge, no count line | One row kind for "a value that spans fields"; `PlaceDetailContent.periodRow` keeps the default | A new row kind `asOf` — a near-copy of `spanning` |
| D-6 | **Retire the six summary fields on every layer** (map scope entry). Go: drop them from `EventSummary`; `oneEvent` reads the three dates into locals for `DatingOf` and drops the counts; the clear rule (`if h.Date != nil { h.StartDate = nil; h.EndDate = nil }`) is deleted; the doc comment says the dating is the summary's one date. Proto: delete fields 6 – 11, add `reserved 6, 7, 8, 9, 10, 11;` and `reserved "date", "date_count", "start_date", "start_date_count", "end_date", "end_date_count";`, regenerate. Swift: drop them from `CatalogEventSummary` and `mapEventSummary` | Nothing reads them once the row reads the dating (§ 4 Go readers); the row's counts come from `detail.fields` | Keeping the counts — no reader (the map: "their counts stay if the row needs them"; it does not) |
| D-7 | **`DateRowDisplay.span(start:end:)` stays.** It loses its event caller in `dateRow`; `line(dating:)` still calls it. `DateRowDisplayTests` keep testing it | It is the span formatter `line(dating:)` composes | Inlining it into `line(dating:)` — a refactor this PR does not need |
| D-8 | **`SeededPropertyKey.asOf = "as_of"`** *(new)*, beside `endDate` | The row looks the field up by key, as it does the other three | A string literal in `EventDetailContent` |
| D-9 | **Tests.** Go: the date order in `conclusiondetails_test.go` (table-driven over field kinds); the retired fields' assertions rewritten onto `Dating`. Swift: `EventDetailTests` for every row case, with fields built by the existing `D.field` / `D.value` / `D.outcome` helpers; the `dated` helper keeps only `dating` | Each layer tests what it owns; Swift gets fields as Go sends them (date order is given by the test, not computed) | A handler test for the order — `conclusiondetails` owns it |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `listed:` parameter on `ReconciledValueRowModel.spanning` | func param | `ReconciledValueRowModel.init(field:)` (lists a multiple field's values) | That init reads one field; this row spans up to three. Extending `spanning` keeps one kind |
| `EventDetailContent.asOfLines` *(new, private static)* | func | `PVProvenanceSheetContent.value(_:propertyKey:)` | Gives the bare date (D-3); the lines need a role word and positional ranks |
| `EventDetailContent.dateLineLimit` *(new)* | constant | `PlaceDetailContent.containsVisibleLimit` | A different list with its own Scale; a shared constant would tie two unrelated limits |
| `L10n.Dates.rowFrom`, `rowUntil` *(new)* | L10n keys | `L10n.Dates.rowFromAsOf`, `rowAsOfUntil` | Those join two dates; these word one side. Board may change the wording (DR-3) |
| `L10n.Conclusions.eventDateMore` *(new)* | L10n key | `L10n.Conclusions.placeContainsMore` | Same English, different context; separate translations |
| `SeededPropertyKey.asOf` *(new)* | constant | `SeededPropertyKey.endDate` | Same registry, new entry |
| Date order of a multiple date field's values | Go rule in `finish` | `valuecompare.DateKeyOf` (used by `sources.go`, `conclusionsummaries` `datePlace`) | Reused as is |

**Builds on.** `valuecompare.DateKeyOf` (the one date order); `ReconciledValueRowModel.spanning` and `PVProvenanceSheetContent.spanning`; `PVProvenanceValueList`; `DateRowDisplay.line(dating:)` and S16-D4's copy; the Place page's names row and Contains truncation.
**Deletes.** `EventSummary.Date`, `DateCount`, `StartDate`, `StartDateCount`, `EndDate`, `EndDateCount` (Go), proto fields 6 – 11, `CatalogEventSummary.date`, `dateCount`, `startDate`, `startDateCount`, `endDate`, `endDateCount` and their `mapEventSummary` lines; `oneEvent`'s clear rule; `EventDetailContent.dateRow`'s branches on the summary fields and its `DateRowDisplay.span` call; `PersonTimelinePreviewData.When.apply(to:)`'s writes of the six fields; the tests' assertions on them. Nothing else becomes dead: `DateRowDisplay.span` keeps a caller (D-7).
**Next adds.** A notice for an as-of outside the start or end ([idea](../../../ideas/event-as-of-followups.md)) reads the same listed lines. A Place's as-of period (same idea file) reuses `asOfLines` if a Place gains `as_of`.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| An as-of event's Date row with lines (reachable since S16-40; empty until now) | `ReconciledValueRow`, `PVProvenanceValueList` | Rows rebuild from each detail (`EventDetailContent.init`), so a new id has new lines · no referent: the lines are values · `listedValues` is a state the row already draws for a multi-valued field |
| A Why over the `as_of` field's records | `PVProvenanceSheetContent.spanning`, `ReconciliationReasoningView` | Built on open from the row's fields · a record's citation is read as for any field · records of several fields in one group, as the span row today |
| `dating.kind == .asOf` with no `as_of` field in `detail.fields` | `dateRow` | D-1: the fields with records only; with none, the lead alone shows |

### Scale

At the map's Scale (Batch 5): real data, an event with up to 20 as-ofs: 20 lines, a 20-value sort in `finish`. Crafted: 10,000 as-ofs on one event. Go: the detail already sends every value and outcome of a multi-valued field; this PR adds one `DateKeyOf` per value and an O(n log n) sort over the kept values (900 distinct in `TestEventDatingManyAsOfs`'s shape: 10,000 as-ofs over 900 years). T-2 measures `ForEntity` on that shape at the planning base and after; the PR description reports both. Swift: at most 21 lines (D-4); building them walks the as-of values once (`prefix` after the line text is built only for the first 20 plus the count). No write, key or cache changes: the row is composed from the detail the page already reads.

### Edges

- **Assumptions.** `PVProvenanceValueList`'s `ForEach` needs unique `Value.id` (`rank`): D-3 numbers lines by position (T-5 checks the ids). `finish`'s outcome sort assumed rank order equals value order; D-2 makes it compare positions, which equals rank order for every field D-2 does not reorder (T-1's single-valued and text rows). `Shown.lead` (`displayedValues.first`) of the `as_of` field becomes its earliest value; only `ReconciledValueRowModel.init(field:)` reads it, and the Event page's as-of row is built by `spanning`, not that init.
- **Neighbors.** A single-valued `date` field: not reordered (its other values keep rank order; T-1). A multi-valued text field (a Place's `toponym`): not reordered (T-1). A user's multi-valued date Property on any handle: date order (T-1 row; the intended reading). An `.asOf` dating closed on both sides (start and end with as-ofs between): the header reads as a span (`line(dating:)`), the row lists start, as-ofs, end (T-4). An event with a `date` and as-ofs: the occurrence row, as-of records not in its Why (AC-3.1, T-7).
- **Removed inputs.** An as-of whose value was not kept (outvoted, weak): not a line; its record still in the Why, under the row's one group (T-3 holds a denied record). All as-ofs not kept and nothing else: dating `.none`, the `as_of` field alone → its row with `No date recorded`-style empty text and its Why (AC-3.5's neighbor, T-8). An as-of before the start (dating opens its low side): the start's line still shows first (AC-2.3, T-4); the header carries the opened side.
- **Real data.** No table or seed drives the rule.
- **Untrusted size.** Values per field come from Observations the app did not write (an import). Bound: D-4's 20 lines in Swift, checked before lines are built past the limit; Go sorts what the detail already carries (T-2). Per value, `DateKeyOf` is constant work.

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/conclusiondetails` | `finish(f *Field)`: D-2. `Field.Values` comment: `// rank order; a multiple date field's in date order (valuecompare.DateKeyOf), ties by rank` |
| `core/database/conclusionsummaries` | `events.go` `EventSummary`: the six fields removed; comment rewritten. `compose.go` `oneEvent`: `date, _, err := keptDateAt(...)` for the three, `h.Dating = valuecompare.DatingOf(date, start, end, keptDates(...))`; the clear rule deleted |

No new errors.

### FFI

`api/proto/engine.proto` `message EventSummary`: fields 6 – 11 deleted and reserved (D-6). `api/ffi/handlers/conclusion_summaries.go` `eventSummaryProto`: the six assignments deleted. Regenerate with `./scripts/generate-proto.sh`.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Date row | `ReconciledValueRow` (snowflake, Ship) | `macos/App/Features/Conclusions/ReconciledValueRow.swift` | Unchanged |
| Value lines | `PVProvenanceValueList`, `PVProvenanceValueLine` (recipe, Ship) | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceParts.swift` | Lines with their Source count; the remainder line has empty `support` |
| Why | `PVProvenanceSheetContent.spanning`, `ReconciliationReasoningView` (recipe, Ship) | `PVProvenanceSheetContent.swift`, `ReconciliationReasoningView.swift` | The records of every field behind the lines |
| Row model | `ReconciledValueRowModel.spanning` (Extend, D-5) | `ReconciledValueRowModel.swift` | `listed:` |
| Row choice | `EventDetailContent.dateRow` | `EventDetailContent.swift` | D-1, D-3, D-4 |
| Seeded key | `SeededPropertyKey.asOf` | `ConclusionVocabulary.swift` | D-8 |

States: an empty row as today (`No date recorded`); 21 lines at most. Accessibility: the row stays one element; the label speaks the lines (AC-1.5). Wide: nothing moves (DR-W1). The board's frames 8a, 8b, 9, 10 are the visual check; their DR-2 / DR-3 / DR-8 wording goes into Strings when the board is agreed.

### Strings

L10n keys *(new)*, recommended wording until the board is agreed (§ 12):
- `L10n.Dates.rowFrom(_:locale:)` → `dates.row.from` = "from %@" (comment: "An event's recorded start on its Date row, beside its As of dates; argument is the date").
- `L10n.Dates.rowUntil(_:locale:)` → `dates.row.until` = "until %@" (comment: "An event's recorded end on its Date row, beside its As of dates; argument is the date").
- `L10n.Conclusions.eventDateMore(_:)` → `conclusions.event.dateMore` = "%lld more" (comment: "Remainder when an event's Date row truncates a long list of As of dates; argument is how many are not shown").

Reused: `L10n.Dates.rowAsOf`, `L10n.Conclusions.whyTitle`, `L10n.Conclusions.sourceCount`, `L10n.Conclusions.emptyEventDate`. Removed: none. No copy names an old scope.

## 7. Steps

**STEP-1 — A multi-valued date field's values arrive in date order**
Files: `core/database/conclusiondetails/conclusiondetails.go` (`finish`, `Field` comment), `core/database/conclusiondetails/conclusiondetails_test.go`. Skill: `add-date-value`.
Do: D-2. Add T-1 and T-2.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/conclusiondetails/...` passes, `TestForEntityGroupsOutcomesByShownValue` unchanged.

**STEP-2 — The Date row reads the dating and lists the as-ofs**
Files: `macos/App/Platform/ConclusionVocabulary.swift`, `macos/App/Features/Conclusions/ReconciledValueRowModel.swift`, `macos/App/Features/Conclusions/EventDetailContent.swift`, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `macos/ProvenenciaTests/EventDetailTests.swift`. Skills: `add-ui-component`, `add-localized-string`, `add-swift-test`.
Do: D-1, D-3, D-4, D-5, D-8; Strings (board wording). `dateRow` reads `summary?.dating` and `fields` only; it no longer reads `summary?.date`, `startDate` or `endDate`. Rewrite the existing Date row tests so each states its dating and fields (`dated` helper keeps the old parameters until STEP-3); add T-3 – T-9.
Check: `xcodebuild test` (the command `scripts/check-pr.sh` runs as `xcode-test`) passes with no Swift warning; `rg "summary\?\.(date|startDate|endDate)" macos/App/Features/Conclusions/EventDetailContent.swift` finds nothing.

**STEP-3 — Retire the summary's old date fields**
Files: `core/database/conclusionsummaries/events.go`, `compose.go` (`oneEvent`), `conclusionsummaries_test.go`; `api/proto/engine.proto`, generated `api/proto/engine/engine.pb.go` and `macos/App/Platform/Generated/engine.pb.swift`; `api/ffi/handlers/conclusion_summaries.go`, `conclusion_summaries_test.go`; `macos/App/Platform/GenealogyStore.swift`, `GoStore.swift`; `macos/App/Features/Conclusions/PersonTimelinePreviewData.swift`; `macos/ProvenenciaTests/EventDetailTests.swift` (`dated` helper: only `dating`), `PersonsListTests.swift` (`eventsRowSecondLine`: drop `date:`). Skill: `add-ffi-handler`.
Do: D-6. Go tests: `TestListEvents` asserts `Dating` (fire `valuecompare.DatingOccurrence` 1849; the birth `DatingOccurrence` 1985, the date winning over its start; the span `DatingSpan` 1900–1910, neither side open; undated `DatingNone`); `TestSummariesShowKeptValuesOnly` checks `h.Dating.Kind == valuecompare.DatingNone`; `TestListKeysFollowListOrder` checks `key.Last` against `e.Dating.Low == nil && e.Dating.High == nil`; helper `summary` sets only `Dating`; `TestListEventSummaries` drops its `GetDate()` check (the dating check beside it stays). `PersonTimelinePreviewData.When.apply(to:)` sets only `dating`.
Check: `./scripts/generate-proto.sh` leaves the tree clean on a second run; `CGO_ENABLED=1 go test -tags fts5 ./api/... ./core/...` passes; `xcodebuild test` passes; AC-5.1's `rg` (DoD) finds only the `reserved` line.

**STEP-4 — Docs**
Files: `docs/structured-date-model.md` § 3.4; `docs/deployment-plan/spike-16/completed.md`; `docs/deployment-plan/spike-16/deployment-plan.md` (map row); this plan (status, Landed note); `docs/deployment-plan/spike-16/design/S16-D6-event-date-row.md` → `design/archive/`, `design/README.md`; `VERSION`, `core/version.go`, `MARKETING_VERSION`.
Do: § 3.4 gains: "The Event page's Date row reads the dating's kind: an occurrence shows the `date` field, a span its start and end, an as-of dating lists the start, each kept as-of earliest first and the end, each with its Sources (at most 20 lines). A Conclusion detail sends a multi-valued date field's values in date order." Then the DoD's docs lines and the version bump.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-44-event-date-row.md` reports no errors; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/conclusiondetails/conclusiondetails_test.go` `TestForEntityMultipleDatesInDateOrder` *(new, table-driven)* | An event cited by three Sources: as-of 2015 on two, as-of 1990 on one, promoted onto one handle → `as_of` `Values` dates 1990, 2015 with ranks 2, 1 kept; its `Outcomes` the 1990 record first, then the two 2015 records. Rows: a `date` field with a kept 1849 and an outvoted 1817 → rank order unchanged; a person's `name` (single) → as `TestForEntityGroupsOutcomesByShownValue`; an as-of with no year (phrase only) → last | AC-4.2, D-2 |
| T-2 | Go | same file `TestForEntityManyAsOfs` *(new)* | 10,000 as-ofs on one event over 900 years (`TestEventDatingManyAsOfs`'s shape) → the 900 kept `Values` in date order; the test logs `ForEntity`'s time, which the implementer also measures with the sort removed (the planning base) | AC-4.2, D-2, Scale |
| T-3 | Swift | `macos/ProvenenciaTests/EventDetailTests.swift` `asOfRowListsEachAsOfEarliestFirst` *(new)* | `as_of` field (multiple, displayed 10 Jan 1990 support 1, 10 Feb 2015 support 2, one denied 1970 record), dating `.asOf` both open → `listedValues.map(\.text)` `["as of 10 Jan 1990", "as of 10 Feb 2015"]`, supports `["1 Source", "2 Sources"]`; `shown.lead` `"as of 10 Jan 1990–10 Feb 2015"`; badge nil; records include the denied one; `whyTitle` `Why “as of 10 Jan 1990–10 Feb 2015”`; `accessibilityLabel` per AC-1.5 | AC-1.1, AC-1.2, AC-1.5 |
| T-4 | Swift | same `asOfRowListsTheStartAndEndBesideItsAsOfs` *(new)* | start 1985 + as-ofs 1990, 2015 → `["from 1985", "as of 1990", "as of 2015"]`; as-of 1990 + end 2015 → `["as of 1990", "until 2015"]`; start 1985 + as-of 1980 → `["from 1985", "as of 1980"]`; start 1985, as-of 1990, end 2015 (dating `.asOf` both closed) → three lines, lead `1985–2015` | AC-2.1, AC-2.2, AC-2.3 |
| T-5 | Swift | same `asOfRowLinesHaveDistinctIDs` *(new)* | the T-4 three-line row → `listedValues.map(\.id)` `[1, 2, 3]` | D-3 |
| T-6 | Swift | same `asOfLinesKeepTheirQualifiers` *(new)* | as-ofs `abt 1990`, `bef 2015` → `["as of abt 1990", "as of bef 2015"]`; one as-of 10 Jan 1990 → `["as of 10 Jan 1990"]` | AC-1.3, AC-1.4 |
| T-7 | Swift | same `anOccurrenceKeepsTheDateRowWhateverElseIsRecorded` *(new; replaces `dateFieldWinsOverASpan`)* | `date` 14 May 1817 + start 1849 + as-of 1820, dating `.occurrence` → lead `14 May 1817`, records only the `date` record | AC-3.1 |
| T-8 | Swift | same `undatedRowShowsTheFieldWithRecords` *(new)* | dating `.none`; only a `date` field with an undisplayed record → the `date` row with its record in the Why; only an `as_of` field with a denied record → that row; no fields → `No date recorded`, no records | AC-3.4, AC-3.5 |
| T-9 | Swift | same `aCraftedEventListsTwentyAsOfsAndTheRest` *(new)* | 10,000 displayed as-of values, dating `.asOf` → 21 lines, the last `"9,980 more"` with empty support; `recordCount` 10,000 | AC-4.1, D-4 |
| T-10 | Swift | same `spanLeadWhenThereIsNoDate`, `dateRowFallsToTheSpanWhenTheDateShowsNothing`, `dateRowFollowsTheSummaryWhenFieldsDisagree`, `missingDateIsAnEmptyDateRow` (kept, rewritten to state only `dating`) | as today | AC-3.2, AC-3.4 |
| T-11 | Swift | same `aSpanWithOneSideIsThatFieldsRow` *(new)* | start 1849 only, dating `.span` → the `start_date` row, label `Date`, lead `1849` | AC-3.3 |
| T-12 | Go | `core/database/conclusionsummaries/conclusionsummaries_test.go` `TestListEvents` (rewritten) | per STEP-3 | AC-5.2, D-6 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `PersonDetailTests`, `PersonTimelineContentTests` and `CatalogSearchTests` (they build `CatalogEventSummary` through `PersonTimelinePreviewData` or with `dating`), `TestEventDatingManyAsOfs`, `TestListEventSummaries`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] AC-5.1: `rg -n "StartDateCount|EndDateCount|start_date_count|end_date_count" api core macos/App macos/ProvenenciaTests` finds only the `reserved` line of `engine.proto`; `go build ./...` and the Xcode build pass with the fields gone (the compiler is the sweep for `Date`, `StartDate`, `EndDate`, which `PlaceSummary` and `LifeFacts` keep)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — or none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated)
- [ ] Domain doc updated if a rule in docs/*.md changed: structured-date-model.md § 3.4 (STEP-4)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

On a new project (As of is seeded at create time only):

1. Record a residence for person X from an obituary (As of 10 Jan 1990) and from a city directory (As of 10 Feb 2015); promote both onto one Event. Open the Event page: the header reads `as of 10 Jan 1990–10 Feb 2015`; the Date row lists `as of 10 Jan 1990` · `1 Source` above `as of 10 Feb 2015` · `1 Source`. Open Why: both records, each read as its date (bar 18's Event page clause).
2. Add a Start date 1985 from a third record: the row gains `from 1985` above the as-ofs; the header reads `from 1985, as of 10 Feb 2015`.
3. With VoiceOver, focus the Date row: it speaks the label and each line.
4. Widen the window past a 1600 pt pane: the row reads the same (DR-W1).
5. Open an event dated by a `date` and one dated by a start and an end: their Date rows read as before this PR.
6. AC-5.1: run the DoD's `rg`; it finds only the `reserved` line of `engine.proto`.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| Reordering values changes another page's Why order | D-2 touches only multi-valued date fields; T-1 pins the single-valued and text neighbors |
| The board draws a lead line above the listed lines | The brief's inventory forbids it (`PVProvenanceValueList` shows one or the other); a frame that needs it is a stop |
| A test fixture builds `CatalogEventSummary` with the retired fields in a file § 4 does not list | The Xcode build fails in STEP-3; fix each by setting `dating` only |

**Stop and report if:**

- The agreed board draws something `PVProvenanceValueList` cannot show (a lead above the lines, a second row, a chip), or wording that is not one string per line.
- `TestForEntityGroupsOutcomesByShownValue` or any existing Why-order test fails after STEP-1 (D-2 reached a field it should not).
- `ForEntity` on T-2's event takes over twice its time at the planning base (measure both).
- Removing a field in STEP-3 leaves a compile error outside the files STEP-3 lists (a reader § 4 missed).
- `EventSecondaryDisplay.content` or any other header or list line changes output in any existing test.

## 12. Open questions

- **Board S16-D6** (blocks Planned): the agreed wording of DR-2 (each as-of line), DR-3 (the start and end lines) and DR-8 (the remainder line). Recommendation: `as of %@`, `from %@`, `until %@`, `%lld more`, as in § Strings.

## 13. PR

**Title:** S16-44 — The Event page's Date row shows as-ofs
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-44-event-date-row.md`.
