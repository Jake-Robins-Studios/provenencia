# S16-44 — The Event page's Date row shows as-ofs

**Status:** Landed in [#881](https://github.com/mendahu/provenencia/pull/881) (2026-11-17)
**Spike / slice:** Spike 16 · Batch 5 · Slice 5a — An attestation is a sample
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S16-D6](../design/archive/S16-D6-event-date-row.md) (Event page: the Date row for an event dated by as-ofs, DR-1 – DR-8, DR-W1), board agreed 2026-11-17
**Board:** agreed 2026-11-17. [Claude Design — Event Detail](https://claude.ai/artifact/5ciAxv86fYtrUvuCHPuuJ5), page `project/Event Detail.dc.html`, turn "S16-D6 · As-of dates": frames 8a (Regular), 8b (Wide), 9 (the Why open) and 10 (the strip of every case, with Residence of Z's 10,000 as-ofs folded). The implementer reads it with the Artifact tool's `read` on that link and that `path`, as S16-42 read its boards. Wording: `from`, `as of`, `until` before each date, the role word in secondary ink (D-3); `Show 50 more` (D-5). Two things the board draws are not built here: the Why's own `Show 50 more` (S15-27), and `; 9,980 more` at the end of the spoken label (the label speaks the 20 lines it shows; the Show more button speaks the rest)
**Depends on:** S16-42 (landed [#876](https://github.com/mendahu/provenencia/pull/876)), S16-D6 (agreed 2026-11-17)
**Blocks:** —
**Branch:** `s16-44-event-date-row`
**Version bump:** minor — the next minor after `VERSION` on `main` when the branch is cut (0.21.0 → 0.22.0 at the planning base): a change a researcher sees on every as-of event's page, and wire fields removed from `EventSummary` that client and core drop together ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-date-value`](../../../../.agents/skills/add-date-value/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`, `.cursor/rules/swift-tests.mdc`
**Context:** [`event-as-of.md` § The dating envelope](../event-as-of.md#the-dating-envelope), [`structured-date-model.md` § 3.4](../../../structured-date-model.md#34-the-display-date-of-an-event), working rules (Batch 5): "The engine sends the dating, not the as-ofs", "As-ofs alone make a span open on both sides", "One dating, in Go, derived on read"; [S16-42 plan](S16-42-event-dating-line.md) D-14 and its Landed note; [S16-42 review](S16-42-event-dating-line.review.md) M-9; [S16-42 ship log](S16-42-event-dating-line.ship.md) UX-1
**Planned:** 2026-11-17 against `main` @ `2bcfd1f`
**Review:** [`S16-44-event-date-row.review.md`](S16-44-event-date-row.review.md) — Fits with changes / Ready with changes, 2 rounds, no open blocker

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

Since S16-42, an event dated only by its **As of** dates reads `as of 10 Jan 1990–10 Feb 2015` in its Event page header, while its Date row still says **No date recorded** (S16-42 ship log UX-1). After this PR the engine also says which Properties stand behind the dating, each with its role, and the Date row shows those. An as-of event's row lists each kept as-of, earliest first, with its Source count, plus the start or end that closes a side; its Why lists every record behind those lines (dogfood bar 18's Event page clause). Then the old date fields that only this row still read leave every layer: `EventSummary.Date`, `StartDate`, `EndDate` and their counts (Go, proto, `GoStore`, `CatalogEventSummary`), with `oneEvent`'s rule that clears the start and end when a `date` is kept (user, 2026-11-17; S16-42 review M-9).

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
| AC-2.1 | Start 1985; as-ofs 10 Jan 1990 and 10 Feb 2015 | Lines `from 1985`, `as of 10 Jan 1990`, `as of 10 Feb 2015` (wording per the board, D-3); the Why holds the start's record first |
| AC-2.2 | As-of 1990; end 2015 | Lines `as of 1990`, `until 2015` |
| AC-2.3 | Start 1985; as-of 1980 (before the start; the dating opens its low side) | Lines `from 1985`, `as of 1980`: in the order Go sends the properties (start, as-ofs, end), whatever the dates say (Edges) |

**US-3.** As a researcher, events dated as before keep their Date row.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `date` 14 May 1817, plus a start 1849 and an as-of 1820; dating `.occurrence` | The `date` field's row: `14 May 1817`, its records only |
| AC-3.2 | Start 1849, end 1851; dating `.span` | One row, lead `1849–1851`, Why holds both records, no badge |
| AC-3.3 | Start 1849 only; dating `.span` | The `start_date` field's row, relabeled `Date`, lead `1849` |
| AC-3.4 | No date recorded on any of the four keys; dating `.none` | `No date recorded`, no Why |
| AC-3.5 | A `date` record whose value was not kept, and nothing else; dating `.none` | The `date` field's row, relabeled `Date`, with that field's own empty text (`Nothing recorded`, `L10n.Conclusions.stateEmpty`, as today); its Why holds the record |

**US-4.** As the engine, a crafted event with 10,000 as-ofs stays bounded on its page.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | 900 kept as-ofs (10,000 records over 900 years) | The row shows 20 lines and `Show 50 more` (the paged fold, user 2026-11-17); each press adds 50; the spoken label reads the first 20 lines |
| AC-4.2 | The same event's `conclusiondetails.ForEntity` | Its `as_of` field's values arrive in date order, and the read's median time is at most twice the planning base's (T-2) |

**US-5.** As a contributor, an event summary carries one date reading: the dating, and the Properties behind it.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-5.1 | `rg` for the retired names | `EventSummary` (Go, proto, Swift) has no `Date`, `DateCount`, `StartDate`, `StartDateCount`, `EndDate`, `EndDateCount` field; proto fields 6 – 11 are `reserved` with their names |
| AC-5.2 | The Events list, the Timeline, search, Promote | Read as before (they read `dating` since S16-42); their tests pass unchanged |
| AC-5.3 | `ListEventSummaries` for an occurrence, a span, an as-of event and an undated one | `dating_properties` = `[date/OCCURRENCE]`; `[start_date/START, end_date/END]`; `[start_date/START, as_of/AS_OF, end_date/END]`; `[date/OCCURRENCE, start_date/START, end_date/END, as_of/AS_OF]` |

## 3. Scope

| In | Covered by |
| --- | --- |
| DR-1: an occurrence and a span keep today's row | STEP-3, AC-3.1, AC-3.2, AC-3.3, AC-3.4, AC-3.5 |
| DR-2, DR-5: an as-of event's row lists each kept as-of, earliest first, with its Source count | STEP-1, STEP-3, AC-1.1, AC-1.3 |
| DR-3: the start's line first, the end's last | STEP-2, STEP-3, AC-2.1, AC-2.2, AC-2.3 |
| DR-4: each line keeps its qualifier and phrase | STEP-3, AC-1.4 |
| DR-6: the Why lists every record behind the lines; no badge | STEP-3, AC-1.2 |
| DR-7: no new layout, chip, badge or icon | STEP-3, §6 macOS |
| DR-8: a long list folds through the paged fold (user, 2026-11-17) | STEP-3, AC-4.1 |
| DR-W1: the same at Regular and Wide | §10 manual check |
| Go sends the Properties behind each event's dating, with their roles (review M-1, rule K-3) | STEP-2, AC-5.3 |
| A multi-valued date field's values arrive in date order (user, 2026-11-17) | STEP-1, AC-4.2 |
| Retire `EventSummary.Date` / `StartDate` / `EndDate` and their counts on every layer; `oneEvent`'s clear rule (map scope entry, S16-42 review M-9) | STEP-4, AC-5.1, AC-5.2 |
| `structured-date-model.md` § 3.4 names the Date row and the value order | STEP-5 |

| Out | Home |
| --- | --- |
| The header's date line | S16-42 (landed) |
| A notice for an as-of outside the start or end | descoped (user, 2026-11-17); [idea](../../../ideas/event-as-of-followups.md) |
| The as-ofs of an event that also has a `date` on its Date row | not planned (the occurrence wins, as an occurrence's start and end are not shown today; brief § 2.1) |
| The Why's record table drawing 10,000 records a page at a time | S15-27 (the provenance table folds a page at a time) |
| Moving the fold to the kit | S15-30 |
| Deleting `DateRowDisplay.span(start:end:)` | not planned: `line(dating:)` still calls it (D-7) |
| `PlaceSummary.StartDate` / `EndDate` and `placeShell`, `assocDatesOf` | not planned: a Place's and an association's own period, not an event's dating |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Date row | `macos/App/Features/Conclusions/EventDetailContent.swift` `EventDetailContent.dateRow(_:summary:locale:)`, `labeled(_:_:field:)` | Branches on `summary?.date`, `summary?.startDate`, `summary?.endDate` and on `SeededPropertyKey.date`, `.startDate`, `.endDate` fields: Swift decides which keys date an event, which working rule K-3 retires. Never reads `summary.dating` or the `as_of` field, so an as-of event's row is `.empty` ("No date recorded"). The two-field span lead is `DateRowDisplay.span(start:end:)`, its last event caller. `labeled` respeaks only `shown.lead` |
| Header date | `EventDetailContent.init` → `EventSecondaryDisplay.content` | Reads `summary.dating` (S16-42). Stays |
| The event's keys in Go | `core/subjectcompare/subjectcompare.go` `Rules.EventPeriod()`; `core/database/conclusionsummaries/compose.go` `eventLead, eventPeriod` | The one home of the four keys (`date`; `Period.Start`, `End`, `Samples`) every dating reader takes |
| Row model | `macos/App/Features/Conclusions/ReconciledValueRowModel.swift` `ReconciledValueRowModel.spanning(id:label:lead:emptyText:fields:locale:)` | One row whose lead spans several fields; Why = `PVProvenanceSheetContent.spanning` (every record of the fields, in field order, one group); no badge, no count; `shown.listedValues` always `[]`. Callers: `EventDetailContent.dateRow`, `PlaceDetailContent.periodRow` |
| Row model, one field | `ReconciledValueRowModel.init(field:locale:orders:)` line 53; `PlaceDetailContent.namesRow` line 69 | Each joins `shown.listedValues` with `"; "` for the spoken label: two copies of one rule. `namesRow` relabels inline, as `EventDetailContent.labeled` does |
| Row view | `macos/App/Features/Conclusions/ReconciledValueRow.swift` `ReconciledValueRow` | Draws `PVProvenanceValueList(model.shown)` inside `summary` (one VoiceOver element); `@State` for its disclosures; no fold |
| Value lines | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceParts.swift` `PVProvenanceValueList`, `PVProvenanceValueLine` | Shows `listedValues` when not empty, else the lead, else the empty text. `ForEach(shown.listedValues)` keys on `Value.id`, which is `rank` |
| Listed value | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheetContent.swift` `PVProvenanceSheetContent.Value` (`rank`, `text`, `support`) | `support` from `ReconciledValueDisplay.sourceCountLine` ("1 Source") |
| The fold | `macos/App/Features/Conclusions/ConclusionShowMoreRow.swift` `ConclusionFold`, `ConclusionShowMoreRow`; `PersonSourcesContent.lineFold` | The one fold of a Conclusion page's lists (`docs/macos-client-patterns.md`), already used for lines inside a row; `L10n.Conclusions.showMore` "Show %lld more" |
| Date formatter | `macos/App/Platform/DateRowDisplay.swift` `DateRowDisplay.line(date:)`, `span(start:end:)`, `line(dating:)` | The only composer of `L10n.Dates.row*` (one feature use: `rowUndated`). `line(dating:)` words "as of" through `rowAsOf`, `rowAsOfRange`, `rowFromAsOf`, `rowAsOfUntil` |
| Detail values | `core/database/conclusiondetails/conclusiondetails.go` `Field.Values` (`// rank order`), `attachValues`, `finish` | `attachValues` appends `n.Values[prop]` in rank order (support, then provenance, then Observation id: `core/autoreconcile/pipeline.go` `reconcile`). `finish` orders `Outcomes` by `GroupRank`, then `ValueRank` (none last), then Observation id. So two as-ofs arrive in an order unrelated to their dates |
| Sort key | `core/autoreconcile/autoreconcile.go` `SortKey(valueType, v)` | The text a value sorts by within its Property (a date: `valuecompare.DateKeyOf`); the cache's stored `sort_key` |
| Summary fields | `core/database/conclusionsummaries/events.go` `EventSummary` | `Date`, `DateCount`, `StartDate`, `StartDateCount`, `EndDate`, `EndDateCount` beside `Dating`. Its doc comment still says "A rank-1 date wins over a start/end span; the span's counts are still reported" |
| Summary compose | `core/database/conclusionsummaries/compose.go` `oneEvent` | Reads the three into `h.Date`, `h.StartDate`, `h.EndDate` (with counts), passes them to `valuecompare.DatingOf`, and at the end clears `h.StartDate` and `h.EndDate` when `h.Date != nil` |
| Go readers | `api/ffi/handlers/conclusion_summaries.go` `eventSummaryProto` | The only non-test reader outside `oneEvent` (checked: removing the six fields leaves compile errors only there and in tests) |
| Proto | `api/proto/engine.proto` `message EventSummary`, `message EventDating` | Fields 6 `date`, 7 `date_count`, 8 `start_date`, 9 `start_date_count`, 10 `end_date`, 11 `end_date_count`; 19 `dating`. `EventDating` is shared with `SourceEventTitle` (`api/ffi/handlers/event_titles.go`) |
| Swift summary | `macos/App/Platform/GenealogyStore.swift` `CatalogEventSummary`, `CatalogEventDating`; `macos/App/Platform/GoStore.swift` `mapEventSummary`, `mapEventDating` | The six fields mapped from the proto. Swift readers: only `EventDetailContent.dateRow` |
| Preview data | `macos/App/Features/Conclusions/PersonTimelinePreviewData.swift` `When.apply(to:)` | Sets `date` / `dateCount` / `startDate` / `endDate` / counts beside `dating`; the `.years` case reads `summary.startDate` into `dating.low` |
| Go tests | `core/database/conclusionsummaries/conclusionsummaries_test.go` `TestListEvents` (lines 573 – 587), `TestSummariesShowKeptValuesOnly` (line 255), `TestListKeysFollowListOrder` (line 1672), helper `summary(date, start, end, samples...)` (line 1314); `api/ffi/handlers/conclusion_summaries_test.go` `TestListEventSummaries` (line 253) | Assert on the six fields |
| Go detail tests | `core/database/conclusiondetails/conclusiondetails_test.go` `TestForEntityGroupsOutcomesByShownValue`; fixture `newFixture` (`person`, `name`, `sex`, `date`; no `as_of`), `source`, `subjectOn`, `cite`, `promote`, `detail`, `field`, `outcomeOf`, `dateIn` | The outcome order of a single-valued name field. Stays green |
| Swift tests | `macos/ProvenenciaTests/EventDetailTests.swift` helper `dated(date:start:end:dating:)` and the Date row tests; `macos/ProvenenciaTests/PersonsListTests.swift` `eventsRowSecondLine` (line 156, `date:` argument); `macos/ProvenenciaTests/DateRowDisplayTests.swift` | Set the six fields |

**Precedent.** The retirement copies `f0245d7` (*Order every Conclusion list by one key Go computes*), which removed `MetadataWorkspaceEntry.date_summary` and reserved its number and name in `engine.proto`. The fold copies `PersonSourcesContent.lineFold` (lines inside a row behind `ConclusionShowMoreRow`). The lines copy `PlaceDetailContent.namesRow` (a multi-valued field's values as stacked lines). S16-42's STEP-11 is the last change to `dateRow`; do not copy its `span(start:end:)` call.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | **Go sends the Properties behind the dating** (rule K-3, review M-1). `conclusionsummaries` adds `type DatingRole int` *(new)* (`DatingRoleOccurrence`, `DatingRoleStart`, `DatingRoleEnd`, `DatingRoleAsOf`) and `type DatingProperty struct { Key vocabkey.PropertyKey; Role DatingRole }` *(new)*, and `EventSummary.DatingProperties []DatingProperty` *(new)*. `oneEvent` sets it from `datingProperties(kind)` *(new)*, which reads `eventLead, eventPeriod` and returns, per kind: occurrence → `[lead/Occurrence]`; span → `[Start/Start, End/End]`; as-of → `[Start/Start, Samples/AsOf, End/End]`; none → `[lead/Occurrence, Start/Start, End/End, Samples/AsOf]`. The four slices are built once at package init and shared read-only. Proto: `enum EventDatingRole` *(new)* (`EVENT_DATING_ROLE_UNSPECIFIED`, `_OCCURRENCE`, `_START`, `_END`, `_AS_OF`), `message EventDatingProperty { string property_key = 1; EventDatingRole role = 2; }` *(new)*, `repeated EventDatingProperty dating_properties = 20;` on `EventSummary` (not on `EventDating`, which `SourceEventTitle` shares). Go's `DatingRole` starts at 1 (`DatingRoleOccurrence DatingRole = iota + 1`) so its values equal the proto enum's. Swift: `CatalogEventDatingProperty { key: String; role: Role }` *(new)* with `enum Role { case occurrence, start, end, asOf }`, `CatalogEventSummary.datingProperties`; `GoStore.mapEventSummary` drops an entry whose role is `UNSPECIFIED` or `UNRECOGNIZED` | The four keys live once, in the registry; Swift stops choosing keys; a Place period would be another entry, not a Swift switch | A Swift switch on `dating.kind` naming keys (D-1 of the first draft) — bends K-3; putting the list on `EventDating` — `SourceEventTitle` has no fields to show |
| D-2 | **Go orders a multi-valued date field's values by date.** In `conclusiondetails.finish`, a field with `cardinality == propertymeta.CardinalityMultiple` and `ValueType == propertymeta.ValueTypeDate` sorts `Values` by `autoreconcile.SortKey(f.ValueType, autoreconcile.Value{Date: v.Value.Date})` (key computed once per value), stable; a value with no key (`ok` false) goes last; ties keep rank order. `Rank` is unchanged on each value. `finish` then sorts every field's `Outcomes` through a `map[rank]position` built from the ordered `Values`: the first key is `GroupRank`'s position, the second `ValueRank`'s, each with 0 (none) last, then Observation id, as today. `Outcome.GroupRank` and `ValueRank` keep the value's `Rank`, which the wire carries and Swift matches records to values by (`PVProvenanceSheetContent.valueGroups`, `ReconciledValueDisplay`). `Field.Values`' comment says so | The user chose date order (2026-11-17); `SortKey` is already the per-type sort key, so widening the gate later needs no new comparator; only `as_of` is such a seeded field | A Swift sort — a second date order in Swift; calling `DateKeyOf` by hand — `SortKey` wraps it (review M-7) |
| D-3 | **One translatable sentence per role, styled through `StyledFormat`** (review M-3, M-10, M-11; board S16-D6, user 2026-11-17: the role word in secondary ink). `DateRowDisplay.Role` *(new)*: `.plain`, `.from`, `.asOf`, `.until`. `DateRowDisplay.line(date:role:includesPhrase:locale:) -> DateRowDisplay.RoleLine` *(new)*, `struct RoleLine: Equatable { var text: String; var styled: AttributedString? }` *(new)*, as `NameDisplay { text, styled }`: `.plain` → `line(date:)`, `styled` nil; `.from` → `L10n.Dates.rowFrom` "from %@" *(new)*, `.asOf` → `L10n.Dates.rowAsOf` (the header's key, reused), `.until` → `L10n.Dates.rowUntil` "until %@" *(new)*. `text` is the format filled in; `styled` is `StyledFormat.attributed(resource, [.init(text: date, attributes: marked)])` where `marked` sets `DateRowDisplay.DateRun` *(new `AttributedStringKey`, value `Bool`)* on the date argument; an empty date gives `""` and nil. `PVProvenanceSheetContent.Value` gains `styled: AttributedString? = nil` and `propertyKey: String = ""` *(new)*; `id` becomes `"\(propertyKey)#\(rank)"` (a `String`), so lines from three fields have distinct ids while `rank` keeps the wire rank. `PVProvenanceSheetContent.value(_:propertyKey:role:locale:orders:)` *(gains `role: DateRowDisplay.Role = .plain`)*, the one builder of a `Value`, sets `text` and `styled` from `line(date:role:)` for a date value and `propertyKey`. `PVProvenanceValueLine` draws `styled` when set: a copy with `PVColor.textSecondary` on every run, then `PVColor.textPrimary` on runs carrying `DateRun` (typed `AttributeContainer` subscripts, as `PVComboBox` marks its matches); else `text` as today. `EventDetailContent` only picks the fields and maps: for each `datingProperties` entry in order whose field has records, every displayed value of a `multiple` field, or the first displayed value of a single-valued field (a start or end, even when mixed), through `value(_:propertyKey:role:)` with role Start → `.from`, AsOf → `.asOf`, End → `.until`, Occurrence → `.plain`; a value whose `text` is empty is skipped. Spoken text is `text` | One sentence per role keeps word order translatable (`add-localized-string` § Styled arguments) and shares `dates.row.asOf` with the header; one `Value` builder; `rank` keeps one meaning | Bare role words joined in Swift (`roleWord`, `Value.prefix`) — splits a sentence (review M-10); a feature-built `Value` with positional ranks (review M-11) |
| D-4 | **The row's shape.** Fields: each `datingProperties` entry's field in `detail.fields` with records (`!outcomes.isEmpty`), in that order. `dating.kind == .asOf` → `.spanning` over those fields with lead `DateRowDisplay.line(dating:)` and `listed` = D-3's lines. Any other kind: one field → that field's row via `relabeled` (D-6), keeping its own empty text ("Nothing recorded", as today); several → `.spanning`, lead `line(dating:)` (nil when empty; then the row shows `No date recorded` and its Why title is `Why “Date”`, D-6); none → `.spanning` with that lead and no fields when the lead is not empty, else `.empty` ("No date recorded"). A nil summary has no properties: `.empty` | Swift reads the kind only to choose the shape (lines vs one value), never a key | — |
| D-5 | **The lines fold** (user, 2026-11-17: the paged fold). `ReconciledValueRowModel.listFold = ConclusionFold(limit: 20, minimumHidden: 2)` *(new)*. `ReconciledValueRow` keeps `@State private var folds = ConclusionFoldState<String>()` (fold key `model.id`), as `docs/macos-client-patterns.md` keeps a list's pages, reset to a new state in `.onChange(of: model.shown.listedValues)`; it passes `PVProvenanceValueList` a copy of `model.shown` whose `listedValues` are `listFold.shown(…, pages: folds.pages(model.id)).shown`, and when `hidden > 0` draws `ConclusionShowMoreRow(hidden:fold:focus:revealed: nil, expand: { folds.revealPage(model.id) })` in `body` directly after the HStack that holds `summary` and before the other-values card, outside the summary's VoiceOver element, padded by `disclosureInset` so it sits in the value column. It folds in both `.why` and `.sheet` modes (the Person page's Vitals rows too). Its focus binding is a new `@FocusState private var focusedLine: Int?` (no line takes focus, so `revealed` is nil). Every multi-valued row gets the fold (a Place with more than 21 names too) | The documented fold for every long list on a Conclusion page; the row view lives beside the fold in `Features/Conclusions`, so S15-30 is not needed; the recipe stays unchanged | A muted "N more" text — bends the fold rule (user chose the fold); waiting for S15-30 — not started |
| D-6 | **One spoken value and one relabel** (review M-4). `ReconciledValueRowModel.spokenValue(_ shown:) -> String?` *(new, static)*: when more than one value is listed, the first `listFold.limit` listed values' `text` joined with `"; "`; else the lead (today's `> 1` gate), except that a single listed value with a `styled` copy speaks its `text` (`as of 10 Jan 1990`, not the dating line). `ReconciledValueRowModel.relabeled(_ label: String, field: CatalogConclusionField?) -> Self` *(new)*: sets `label` and `accessibilityLabel` from `spokenValue`. `init(field:)`, `spanning`, `EventDetailContent.labeled` (deleted, callers use `relabeled`) and `PlaceDetailContent.namesRow` use them. `spanning` gains `listed: [PVProvenanceSheetContent.Value] = []`, carried as `shown.listedValues` (the `Shown` memberwise init); `whyTitle` is `L10n.Conclusions.whyTitle(lead ?? label)` when the row has records (today it is `""` with a nil lead, which left an untitled Why), as `.derived` already does; no badge, no count line | The third copy of the join is extracted (rubric Q5); a relabelled row speaks what it shows | A third inline join in `spanning` |
| D-7 | **Retire the six summary fields on every layer** (map scope entry). Go: drop them from `EventSummary`; `oneEvent` reads the three dates into locals for `DatingOf` and drops the counts; the clear rule is deleted; the doc comment says the dating and its properties are the summary's date. Proto: delete fields 6 – 11, add `reserved 6, 7, 8, 9, 10, 11;` and `reserved "date", "date_count", "start_date", "start_date_count", "end_date", "end_date_count";`, regenerate. Swift: drop them from `CatalogEventSummary` and `mapEventSummary`. `DateRowDisplay.span(start:end:)` stays: `line(dating:)` calls it | Nothing reads them once the row reads `datingProperties` (§ 4 Go readers); the row's counts come from `detail.fields` | Keeping the counts — no reader |
| D-8 | **Tests.** Go: the date order in `conclusiondetails_test.go` (table-driven over field kinds); `datingProperties` in `conclusionsummaries_test.go`; the proto mapping in `conclusion_summaries_test.go`; the retired fields' assertions rewritten onto `Dating`. Swift: `DateRowDisplayTests` for `line(date:role:)`; `EventDetailTests` for every row case, fields built with `D.field` / `D.value` / `D.outcome` and properties stated by the test; `ReconciledValueRowModel` spoken value in `EventDetailTests` and the existing Place names tests | Each layer tests what it owns | — |

**Rules this plan bends.** None. (The first draft's Swift key switch bent K-3; D-1 replaces it.)

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `DatingRole`, `DatingProperty`, `EventSummary.DatingProperties`, `datingProperties` | Go types, field, func | `subjectcompare.Rules.EventPeriod()` (the keys), `valuecompare.Dating` (the kind) | Reads the registry's keys; `valuecompare.Dating` is typed on dates, not keys, and is shared with event titles |
| `EventDatingRole`, `EventDatingProperty`, `EventSummary.dating_properties` | proto | `EventDating` | Shared with `SourceEventTitle`, which has no fields to show |
| `CatalogEventDatingProperty`, `CatalogEventSummary.datingProperties` | Swift type, field | `CatalogEventDating` | Mirrors the proto |
| `DateRowDisplay.Role`, `RoleLine`, `DateRun`, `line(date:role:)` | formatter | `NameValueDisplay` `NameDisplay { text, styled }`, `NameDisplayRun.styledText`; `StyledFormat.attributed` | Same shape for dates: plain text plus a styled copy from one format |
| `L10n.Dates.rowFrom`, `rowUntil` | L10n keys | `rowAsOf` (reused), `rowFromAsOf`, `rowAsOfUntil` | Those join two dates; these word one side |
| `PVProvenanceSheetContent.Value.styled`, `propertyKey`; `value(…role:)` | recipe | `PVProvenanceSheetContent.value(_:propertyKey:)`, the one builder of a `Value` | Extended in place |
| `ReconciledValueRowModel.listFold`, `spokenValue`, `relabeled`; `spanning(listed:)` | model | `PersonSourcesContent.lineFold`; the joins in `init(field:)` and `namesRow`; `EventDetailContent.labeled` | Extracts two copies, extends one row kind |
| `ReconciledValueRow` fold state | view | `ConclusionShowMoreRow`, `ConclusionFoldState` | Reused; one fold per row needs one `Int`, not a keyed state |
| Date order of a multiple date field's values | Go rule in `finish` | `autoreconcile.SortKey` | Reused as is |

**Builds on.** The event period registry; `autoreconcile.SortKey`; `ConclusionFold`; `ReconciledValueRowModel.spanning` and `PVProvenanceSheetContent.spanning`; `DateRowDisplay` and S16-D4's copy.
**Deletes.** `EventSummary.Date`, `DateCount`, `StartDate`, `StartDateCount`, `EndDate`, `EndDateCount` (Go), proto fields 6 – 11, `CatalogEventSummary.date`, `dateCount`, `startDate`, `startDateCount`, `endDate`, `endDateCount` and their `mapEventSummary` lines; `oneEvent`'s clear rule; `EventDetailContent.dateRow`'s key branches, its `SeededPropertyKey` lookups and its `DateRowDisplay.span` call; `EventDetailContent.labeled`; the inline `"; "` joins in `init(field:)` and `namesRow`; `PersonTimelinePreviewData.When.apply(to:)`'s writes of the six fields; the tests' assertions on them. Nothing else becomes dead: `DateRowDisplay.span` keeps a caller.
**Next adds.** A Place's as-of period ([idea](../../../ideas/event-as-of-followups.md)) adds its own properties list and reuses `line(date:role:)` and `value(…role:)`. S15-30 moves `ConclusionFold` to the kit; `ReconciledValueRow` then reads it from there. S15-27 folds the Why's record table.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| An as-of event's Date row with lines (reachable since S16-40; empty until now) | `ReconciledValueRow`, `PVProvenanceValueList` | the fold state resets when the listed values change · no referent: the lines are values · `listedValues` is a state the row already draws |
| A fold inside any multi-valued row | `ReconciledValueRow` | A Place with more than 21 names now folds (neighbor; T-10) |
| A Why over the `as_of` field's records | `PVProvenanceSheetContent.spanning`, `ReconciliationReasoningView` | Built on open from the row's fields · records of several fields in one group, as the span row today |
| `dating.kind == .asOf` with no `as_of` field in `detail.fields` | `dateRow` | D-4: the fields with records only; with none, the lead alone shows |

### Scale

At the map's Scale (Batch 5): real data, an event with up to 20 as-ofs: 20 lines, no fold, a 20-value sort in `finish`. Crafted: 10,000 as-ofs on one event (900 kept values in `TestEventDatingManyAsOfs`'s shape). Go: the detail already sends every value and outcome of a multi-valued field; this PR adds one `SortKey` per value and an O(n log n) sort; T-2 measures `ForEntity` before and after (STEP-1). `datingProperties` returns a shared slice: no allocation per event. Swift: the row draws 20 lines, then 50 per press; building the model walks the values once. The Why still builds and draws every record on open (`PVProvenanceRecordTable`, non-lazy): true today for any field with many records; S15-27 bounds it, and the map names that dependency. No write, key or cache changes.

### Edges

- **Assumptions.** `PVProvenanceValueList`'s `ForEach` needs unique `Value.id` (`rank`): D-3 numbers lines by position (T-6). `finish`'s outcome sort assumed rank order equals value order; D-2 compares positions, equal to rank order for every field it does not reorder (T-1). `Shown.lead` of the `as_of` field becomes its earliest value; only `init(field:)` reads it.
- **Neighbors.** A single-valued `date` field: not reordered (T-1). A multi-valued text field (`toponym`): not reordered (T-1) but now folds past 21 names (T-10). A user's multi-valued date Property: date order (T-1). **Row order vs header:** `SortKey` orders a date by its first day, while `DatingOf` picks its extremes by closed ends (`pickSamples`). As-ofs `bet 1980 and 2000` and `1990`: the row lists the range first; the header reads `as of 1990` (T-1 row, review M-5). As-ofs `bef 1990` and `1985`: `bef 1990` sorts at 1990 (`Side` -1), after 1985. The row is in date order; the header is the dating; neither is changed to match the other. An `.asOf` dating closed on both sides: header reads as a span, row lists start, as-ofs, end (T-5). An event with a `date` and as-ofs: occurrence row only (T-8).
- **Removed inputs.** An as-of whose value was not kept: not a line; its record still in the Why (T-4). All as-ofs not kept and nothing else: dating `.none`, the `as_of` field alone → its row with `Nothing recorded` and its Why (T-9). An as-of before the start (dating opens its low side): the start's line still shows first (T-5).
- **Real data.** No table or seed drives the rule; `datingProperties` reads the registry's four keys (T-3).
- **Untrusted size.** Values per field come from Observations the app did not write. Swift: 20 lines drawn, 50 per press; the spoken label joins 20. Go: `SortKey` is constant work per value (T-2).

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/conclusiondetails` | `finish(f *Field)`: D-2. `Field.Values` comment: `// rank order; a multiple date field's in date order (autoreconcile.SortKey), ties by rank` |
| `core/database/conclusionsummaries` | `events.go`: `DatingRole`, `DatingProperty`, `EventSummary.DatingProperties`; the six fields removed; comment rewritten. `compose.go`: `datingProperties(kind valuecompare.DatingKind) []DatingProperty` beside `eventLead, eventPeriod`; `oneEvent` reads the three dates into locals, sets `h.Dating` and `h.DatingProperties`; the clear rule deleted |

No new errors.

### FFI

`api/proto/engine.proto`: `enum EventDatingRole`, `message EventDatingProperty` *(new)*; `EventSummary.dating_properties = 20` *(new)*; fields 6 – 11 deleted and reserved (D-7). `api/ffi/handlers/conclusion_summaries.go` `eventSummaryProto`: the six assignments deleted; `DatingProperties` mapped by a new `eventDatingPropertiesProto` beside `eventDatingProto`. Regenerate with `./scripts/generate-proto.sh`.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Date row | `ReconciledValueRow` (snowflake, Extend) | `macos/App/Features/Conclusions/ReconciledValueRow.swift` | Folds its listed lines (D-5) |
| Show more | `ConclusionShowMoreRow`, `ConclusionFold` (Ship) | `ConclusionShowMoreRow.swift` | Reused |
| Value lines | `PVProvenanceValueList` (recipe, Ship), `PVProvenanceValueLine` (recipe, Extend), `PVProvenanceSheetContent.Value` (Extend) | `PVProvenanceParts.swift`, `PVProvenanceSheetContent.swift` | The list gets the folded lines; a line draws its `styled` copy: the role word in secondary ink, the date in primary (D-3) |
| Why | `PVProvenanceSheetContent.spanning`, `ReconciliationReasoningView` (Ship) | `PVProvenanceSheetContent.swift`, `ReconciliationReasoningView.swift` | Records of every field behind the lines |
| Row model | `ReconciledValueRowModel` (Extend, D-5, D-6) | `ReconciledValueRowModel.swift` | `listFold`, `spokenValue`, `relabeled`, `spanning(listed:)` |
| Row choice | `EventDetailContent.dateRow` | `EventDetailContent.swift` | D-4 |
| Role wording | `DateRowDisplay` (Extend, D-3) | `macos/App/Platform/DateRowDisplay.swift` | `Role`, `RoleLine`, `DateRun`, `line(date:role:)` |
| Summary | `CatalogEventSummary`, `CatalogEventDatingProperty`, `GoStore.mapEventSummary` | `GenealogyStore.swift`, `GoStore.swift` | D-1, D-7 |

States: an empty row as today; 20 lines, then `Show 50 more`. Accessibility: the summary stays one element speaking the first 20 lines; the Show more button is its own control, Return and Space activate it. Wide: nothing moves (DR-W1). The board's frames 8a, 8b, 9, 10 are the visual check.

### Strings

L10n keys *(new)*, as the agreed board words them:
- `L10n.Dates.rowFrom(_:locale:)` → `dates.row.from` = "from %@" (comment: "An event's recorded start on its Date row, beside its As of dates; argument is the date. The words around the date are drawn muted").
- `L10n.Dates.rowUntil(_:locale:)` → `dates.row.until` = "until %@" (comment: "An event's recorded end on its Date row, beside its As of dates; argument is the date. The words around the date are drawn muted").

`dates.row.asOf` is reused: its comment gains "Also each As of line on an event's Date row, where the words around the date are drawn muted".

Reused: `L10n.Dates.rowAsOf`, `L10n.Conclusions.showMore`, `whyTitle`, `sourceCount`, `emptyEventDate`, `stateEmpty`. Removed: none. No copy names an old scope.

## 7. Steps

**STEP-1 — A multi-valued date field's values arrive in date order**
Files: `core/database/conclusiondetails/conclusiondetails.go` (`finish`, `Field` comment), `core/database/conclusiondetails/conclusiondetails_test.go`. Skill: `add-date-value`.
Do: D-2. Fixture: `newFixture` also looks up `f.asOf` (`properties.Lookup(c, "as_of", vocabkey.OriginProvenencia)`), beside `f.date`; add `(f *fixture) asOfIn(s subjects.Subject, d *datevalue.Value) observations.Input` *(new)* beside `dateIn`. Events come from `f.subjectOn(src, "event")`; T-2 files its 10,000 inputs in one `observationstest.Cite` call (it is variadic). The phrase-only date of T-1 is `&datevalue.Value{Kind: datevalue.KindPoint, Calendar: "gregorian", Phrase: "in the spring"}`. Before changing `finish`, add T-2 and run it 5 times on the planning base (`go test -tags fts5 -run TestForEntityManyAsOfs -count 5 -v ./core/database/conclusiondetails/`); after the change, 5 times again. Both medians go in the PR description.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/conclusiondetails/...` passes, `TestForEntityGroupsOutcomesByShownValue` unchanged; the after median is at most twice the before median.

**STEP-2 — Go sends the Properties behind each event's dating**
Files: `core/database/conclusionsummaries/events.go`, `compose.go`, `conclusionsummaries_test.go`; `api/proto/engine.proto`, generated `api/proto/engine/engine.pb.go` and `macos/App/Platform/Generated/engine.pb.swift`; `api/ffi/handlers/conclusion_summaries.go`, `conclusion_summaries_test.go`; `macos/App/Platform/GenealogyStore.swift`, `GoStore.swift`. Skill: `add-ffi-handler`.
Do: D-1 (additive: the six old fields stay until STEP-4). Add T-3 and T-11.
Check: `./scripts/generate-proto.sh` leaves the tree clean on a second run; `CGO_ENABLED=1 go test -tags fts5 ./api/... ./core/...` passes; `xcodebuild test` builds.

**STEP-3 — The Date row reads the dating's Properties and lists the as-ofs**
Files: `macos/App/Platform/DateRowDisplay.swift`, `L10n.swift`, `macos/App/Resources/Localizable.xcstrings`; `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheetContent.swift` (`Value.styled`, `propertyKey`, `id`, `value(…role:)`), `PVProvenanceParts.swift` (`PVProvenanceValueLine`); `macos/App/Features/Conclusions/ReconciledValueRowModel.swift`, `ReconciledValueRow.swift`, `EventDetailContent.swift`, `PlaceDetailContent.swift` (`namesRow` uses `relabeled`); `macos/ProvenenciaTests/DateRowDisplayTests.swift`, `EventDetailTests.swift`. Skills: `add-ui-component`, `add-localized-string`, `add-swift-test`.
Do: D-3, D-4, D-5, D-6; Strings. Load `add-ui-component` before extending the recipe. `dateRow` reads `summary?.dating`, `summary?.datingProperties` and `fields` only. The `dated` helper gains a `properties: [CatalogEventDatingProperty] = []` parameter (its `date:`/`start:`/`end:` parameters stay until STEP-4). Rewrite the existing Date row tests so each states its dating, properties and fields; add T-4 – T-10, T-12. T-2's time is `time.Since` around `f.detail(h)`.
Check: `xcodebuild test` (the command `scripts/check-pr.sh` runs as `xcode-test`) passes with no Swift warning; `rg "SeededPropertyKey|summary\?\.(date|startDate|endDate)" macos/App/Features/Conclusions/EventDetailContent.swift` finds nothing.

**STEP-4 — Retire the summary's old date fields**
Files: `core/database/conclusionsummaries/events.go`, `compose.go` (`oneEvent`), `conclusionsummaries_test.go`; `api/proto/engine.proto` and the generated files; `api/ffi/handlers/conclusion_summaries.go`, `conclusion_summaries_test.go`; `macos/App/Platform/GenealogyStore.swift`, `GoStore.swift`; `macos/App/Features/Conclusions/PersonTimelinePreviewData.swift`; `macos/ProvenenciaTests/EventDetailTests.swift` (`dated` helper: only `dating` and `datingProperties`), `PersonsListTests.swift` (`eventsRowSecondLine`: drop `date:`). Skill: `add-ffi-handler`.
Do: D-7. Go tests: `TestListEvents` asserts `Dating` (fire `valuecompare.DatingOccurrence` 1849; the birth `DatingOccurrence` 1985, the date winning over its start; the span `DatingSpan` 1900–1910, neither side open; undated `DatingNone`); `TestSummariesShowKeptValuesOnly` checks `h.Dating.Kind == valuecompare.DatingNone`; `TestListKeysFollowListOrder` checks `key.Last` against `e.Dating.Low == nil && e.Dating.High == nil`; helper `summary(date, start, end, samples...)` keeps its signature and sets only `Dating` (from `DatingOf` of its arguments); `TestListEventSummaries` drops its `GetDate()` check. `PersonTimelinePreviewData.When.apply(to:)` sets only `dating`; the `.years` case builds its start and end `CatalogDateValueInput` as locals for `dating.low` and `dating.high`.
Check: `./scripts/generate-proto.sh` leaves the tree clean on a second run; `CGO_ENABLED=1 go test -tags fts5 ./api/... ./core/...` passes; `xcodebuild test` passes; AC-5.1's `rg` (DoD) finds only the `reserved` line of `engine.proto`.

**STEP-5 — Docs**
Files: `docs/structured-date-model.md` § 3.4; `docs/deployment-plan/spike-16/completed.md`; `docs/deployment-plan/spike-16/deployment-plan.md` (map row); this plan (status, Landed note); `docs/deployment-plan/spike-16/design/S16-D6-event-date-row.md` → `design/archive/`, `design/README.md`; `VERSION`, `core/version.go`, `MARKETING_VERSION`.
Do: § 3.4 gains: "An event summary also names the Properties behind its dating, each with its role (occurrence, start, end, as of), from the event period registry. The Event page's Date row shows those fields: one field's own row, a start–end span, or for an as-of dating the start, each kept as-of and the end as lines, folded past 20. A Conclusion detail sends a multi-valued date field's values in date order (`autoreconcile.SortKey`); that order reads a date by its first day, so a range as-of can list before the as-of the dating starts from." Then the DoD's docs lines and the version bump.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-44-event-date-row.md` reports no errors; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/conclusiondetails/conclusiondetails_test.go` `TestForEntityMultipleDatesInDateOrder` *(new, table-driven)* | An event cited by three Sources: as-of 2015 on two, as-of 1990 on one → `as_of` `Values` 1990, 2015 with ranks 2, 1 kept; `Outcomes` the 1990 record first, then the two 2015 records, `GroupRank` 2 and 1 unchanged. Rows: as-ofs `bet 1980 and 2000` and `1990` → range first; `bef 1990` and `1985` → 1985 first; a `date` field with a kept 1849 and an outvoted 1817 → rank order unchanged; a person's `name` → as `TestForEntityGroupsOutcomesByShownValue`; a phrase-only as-of → last | AC-4.2, D-2 |
| T-2 | Go | same `TestForEntityManyAsOfs` *(new)* | 10,000 as-ofs over 900 years → the 900 kept `Values` in date order; logs `ForEntity`'s time (STEP-1's medians) | AC-4.2, Scale |
| T-3 | Go | `core/database/conclusionsummaries/conclusionsummaries_test.go` `TestEventDatingProperties` *(new)* | An occurrence (with a start and an as-of too), a span, an as-of event with a start, an undated event → AC-5.3's lists, keys from `matchregistry.Default().Subject.EventPeriod()` | AC-5.3, D-1 |
| T-4 | Swift | `macos/ProvenenciaTests/EventDetailTests.swift` `asOfRowListsEachAsOfEarliestFirst` *(new)* | `as_of` field (multiple, displayed 10 Jan 1990 support 1, 10 Feb 2015 support 2, one denied 1970 record), properties `[as_of/asOf]`, dating `.asOf` both open → `listedValues.map(\.text)` `["as of 10 Jan 1990", "as of 10 Feb 2015"]`, each `styled` marking only the date as `DateRun`, `rank` the wire rank, supports `["1 Source", "2 Sources"]`; `shown.lead` `"as of 10 Jan 1990–10 Feb 2015"`; badge nil; records include the denied one; `whyTitle` `Why “as of 10 Jan 1990–10 Feb 2015”`; `accessibilityLabel` per AC-1.5 | AC-1.1, AC-1.2, AC-1.5 |
| T-5 | Swift | same `asOfRowListsTheStartAndEndBesideItsAsOfs` *(new)* | start 1985 + as-ofs 1990, 2015 → `["from 1985", "as of 1990", "as of 2015"]`; as-of 1990 + end 2015 → `["as of 1990", "until 2015"]`; start 1985 + as-of 1980 → `["from 1985", "as of 1980"]`; start 1985, as-of 1990, end 2015 (`.asOf` both closed) → three lines, lead `1985–2015`. Each case: `provenanceContent().records.map(\.id)` lists the start's records, then the as-ofs', then the end's, and `shown.lead == DateRowDisplay.line(dating:)` of the stated dating | AC-2.1, AC-2.2, AC-2.3 |
| T-6 | Swift | same `asOfRowLinesHaveDistinctIDs` *(new)* | T-5's three-line row → `listedValues.map(\.id)` has three distinct values, and each line's `rank` is its field's wire rank | D-3 |
| T-7 | Swift | same `asOfLinesKeepTheirQualifiers` *(new)* | as-ofs `abt 1990`, `bef 2015` → `["as of abt 1990", "as of bef 2015"]`; one as-of 10 Jan 1990 → `["as of 10 Jan 1990"]` | AC-1.3, AC-1.4 |
| T-8 | Swift | same `anOccurrenceKeepsTheDateRowWhateverElseIsRecorded` *(new; replaces `dateFieldWinsOverASpan`)* | `date` 14 May 1817 + start 1849 + as-of 1820 fields, properties `[date/occurrence]`, dating `.occurrence` → lead `14 May 1817`, records only the `date` record | AC-3.1 |
| T-9 | Swift | same `undatedRowShowsTheFieldWithRecords` *(new)* | dating `.none`, all four properties; only a `date` field with an undisplayed record → the `date` row, label `Date`, empty text `Nothing recorded`, its record in the Why; only an `as_of` field with a denied record → that row, the same; a `date` and a `start_date` field each with an undisplayed record → one `.spanning` row, `No date recorded`, `whyTitle` `Why “Date”`, both records; no fields → `No date recorded`, no records | AC-3.4, AC-3.5 |
| T-10 | Swift | same `aLongListFoldsTwentyThenFifty` *(new)* | `ReconciledValueRowModel.listFold.shown` over 900 lines at 0 pages → 20 shown, 880 hidden, `nextPageCount` 50; at 1 page → 70; 21 lines → all 21 (minimumHidden 2); `spokenValue` of a 900-line row joins 20 | AC-4.1, D-5, D-6 |
| T-11 | Go | `api/ffi/handlers/conclusion_summaries_test.go` `TestEventDatingPropertiesProto` *(new, table-driven)* | `eventSummaryProto(conclusionsummaries.EventSummary{DatingProperties: …})`, as the existing `eventDatingProto` tests call the mapper directly, for each of AC-5.3's four lists → `GetDatingProperties()` equal key by key and role by role (e.g. `[start_date/START, as_of/AS_OF, end_date/END]`) | AC-5.3 |
| T-12 | Swift | `macos/ProvenenciaTests/DateRowDisplayTests.swift` `lineWordsADatesRole` *(new)* | 1985 `.from` → text `from 1985`, `styled`'s `DateRun` runs read `1985` only; `abt 1990` `.asOf` → `as of abt 1990`; 2015 `.until` → `until 2015`; `.plain` → `1985`, styled nil; empty date → `""`, nil | D-3 |
| T-13 | Swift | `EventDetailTests` `spanLeadWhenThereIsNoDate`, `dateRowFallsToTheSpanWhenTheDateShowsNothing`, `dateRowFollowsTheSummaryWhenFieldsDisagree`, `missingDateIsAnEmptyDateRow` (kept, rewritten to state dating and properties); `aSpanWithOneSideIsThatFieldsRow` *(new)*: start 1849 only → the `start_date` row, label `Date`, lead `1849` | AC-3.2, AC-3.3, AC-3.4 |
| T-14 | Go | `conclusionsummaries_test.go` `TestListEvents` (rewritten) | per STEP-4 | AC-5.2, D-7 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: the Place page names tests (`relabeled`, the fold), `PersonDetailTests`, `PersonTimelineContentTests`, `CatalogSearchTests`, `TestEventDatingManyAsOfs`, `TestListEventSummaries`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] AC-5.1: `rg -n -g '!*.pb.go' "StartDateCount|EndDateCount|start_date_count|end_date_count" api core macos/App macos/ProvenenciaTests` (the generated Go descriptor keeps reserved names) finds only the `reserved` line of `engine.proto`; `go build ./...` and the Xcode build pass with the fields gone (the compiler is the sweep for `Date`, `StartDate`, `EndDate`, which `PlaceSummary` and `LifeFacts` keep)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — or none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated)
- [ ] Domain doc updated if a rule in docs/*.md changed: structured-date-model.md § 3.4 (STEP-5)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

On a new project (As of is seeded at create time only):

1. Record a residence for person X from an obituary (As of 10 Jan 1990) and from a city directory (As of 10 Feb 2015); promote both onto one Event. Open the Event page: the header reads `as of 10 Jan 1990–10 Feb 2015`; the Date row lists `as of 10 Jan 1990` · `1 Source` above `as of 10 Feb 2015` · `1 Source`. Open Why: both records, each read as its date (bar 18's Event page clause).
2. Add a Start date 1985 from a third record: the row gains `from 1985` above the as-ofs; the header reads `from 1985, as of 10 Feb 2015`.
3. Open a Place with more than 21 names, if one exists in the test project: its Names row shows 20 and `Show N more`.
4. With VoiceOver, focus the Date row: it speaks the label and each line.
5. Widen the window past a 1600 pt pane: the row reads the same (DR-W1).
6. Open an event dated by a `date` and one dated by a start and an end: their Date rows read as before this PR.
7. AC-5.1: run the DoD's `rg`; it finds only the `reserved` line of `engine.proto`.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| Reordering values changes another page's Why order | D-2 touches only multi-valued date fields; T-1 pins the single-valued and text neighbors |
| The role word's ink drifts from the board | D-3 names the ink and gap; frame 10 is the manual check |
| A test fixture builds `CatalogEventSummary` with the retired fields in a file § 4 does not list | The Xcode build fails in STEP-4; fix each by setting `dating` only |
| The fold changes a Place page whose names list is long | Intended (D-5); T-10 and the Place names tests pin it |

**Stop and report if:**

- A frame of the agreed board needs something §6 macOS does not list (a lead above the lines, a second row, a chip).
- `TestForEntityGroupsOutcomesByShownValue` or any existing Why-order test fails after STEP-1 (D-2 reached a field it should not).
- The after median of T-2's `ForEntity` time is over twice the before median (STEP-1's procedure).
- Removing a field in STEP-4 leaves a compile error outside the files STEP-4 lists (a reader § 4 missed).
- `EventSecondaryDisplay.content` or any other header or list line changes output in any existing test.

## 12. Open questions

None.

## 13. PR

**Title:** S16-44 — The Event page's Date row shows as-ofs
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-44-event-date-row.md`.

## Landed

Differences from the plan: the version went 0.22.0 to 0.23.0, not 0.21.0 to 0.22.0 (`main` was at 0.22.0 when the branch was cut). T-1's rows use dates the reconciler keeps apart: a range of 1950 - 1955 with 1990, and `aft 1960` with 1950, because `bet 1980 and 2000` and `1990`, or `bef 1990` and `1985`, fold into one value, and a phrase-only as-of is not kept as a value, so it has no row; and the single-valued `date` row asserts rank order with both values kept (1849, 1817 as rank 2), as the reconciler keeps the second as a mixed value. `PVProvenanceSheetContent.Value.styled` and `propertyKey` default to nil and "" and `PersonDetailTests.aMixedRowDisclosesItsOtherValues` names its `propertyKey`. `L10n.Dates.rowAsOfFormat`, `rowFromFormat` and `rowUntilFormat` are the resources that `DateRowDisplay.line(date:role:)` styles, and its plain text is the styled copy's characters; `rowAsOf` now formats `rowAsOfFormat`. T-2 logs `ForEntity`'s time: median 118.8 ms before and 128.2 ms after over 5 runs. Review round 1 made four more changes: D-1's numeric cast of `DatingRole` to the wire's enum is a map (`eventDatingRoles`, beside `eventDatingKinds`); D-5's `revealed: nil` became the row's first disclosure stop (the Why, the provenance control, else the other values), claimed by the press that reveals the last page; D-5's reset on `listedValues` is a reset on their ids, so a Source count changing keeps an opened list open; and D-6's spoken label grows with the pages revealed (`accessibilityLabel(pages:)`), the first label still 20 lines (AC-4.1), so a Place's Names past 20 are heard. The Date row's lines share one listing rule with a field's listed values (`PVProvenanceSheetContent.listed`), gated on the field's `multiple` state, not on the role. The manual check (section 10) was not run.
