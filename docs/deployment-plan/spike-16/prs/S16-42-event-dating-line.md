# S16-42 — Every event date line reads the engine's dating

**Status:** Planned
**Spike / slice:** Spike 16 · Batch 5 · Slice 5a — An attestation is a sample
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S16-D4](../design/S16-D4-event-date-line.md) (Events list: the shared event date line, ED-1 – ED-7, ED-W1) and [S16-D7](../design/S16-D7-timeline-lifeline-dating.md) (Person page Timeline: the lifeline, TL-1 – TL-3, TL-W1); both boards agreed 2026-11-17
**Board:** agreed 2026-11-17. [Claude Design — Events List](https://claude.ai/artifact/HP8p5mK3BFhNzFRrP5UK9w), page `project/Events List.dc.html`, section `#s16-d4` "S16-D4 · Event dates": frames 1a (Regular, with the table of every dating case, its VoiceOver words and the four new keys), 1b (Wide), 2 (every surface). [Claude Design — Person Detail](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ), page `project/Person Detail - Timeline.dc.html`, turn 18 "S16-D7 · Lifeline dating" (search `Turn 18`; drawing in `spanMark`): frames 18a (Regular), 18b (Wide), 18c (the four marks zoomed). The implementer reads each with the Artifact tool's `read` on its link and that `path`. Turn 18's row date texts are stand-ins; S16-D4's wording is the one to build (§ Strings)
**Depends on:** S16-40 (landed [#869](https://github.com/mendahu/provenencia/pull/869)), S16-D4, S16-D7
**Blocks:** S16-44
**Branch:** `s16-42-event-dating-line`
**Version bump:** minor — the next minor after `VERSION` on `main` when the branch is cut (0.18.0 → 0.19.0 at the planning base): additive wire fields (`EventSummary.dating`, `SourceEventTitle.dating`) and a change a researcher sees on every event date line ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-date-value`](../../../../.agents/skills/add-date-value/SKILL.md), [`add-match-rule`](../../../../.agents/skills/add-match-rule/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-searchable-kind`](../../../../.agents/skills/add-searchable-kind/SKILL.md), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`, `.cursor/rules/swift-tests.mdc`
**Context:** [`event-as-of.md` § The dating envelope](../event-as-of.md#the-dating-envelope), [`structured-date-model.md` § 3.4](../../../structured-date-model.md#34-the-display-date-of-an-event), working rules (Batch 5): "One dating, in Go, derived on read", "The engine sends the dating, not the as-ofs", "As-ofs alone make a span open on both sides", "One dating for every event, on the Timeline and in order too", "A closed as-of counts toward the person's lifespan; it never dates a birth or a death"; S16-40 plan D-6 and D-9, [S16-40 ship log](S16-40-event-as-of-property.ship.md) SEC-3 and PRF-1
**Planned:** 2026-11-17 against `main` @ `dbc946c`
**Review:** [`S16-42-event-dating-line.review.md`](S16-42-event-dating-line.review.md) — Fits with changes / Ready with changes, 2 rounds, no open blocker

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

An event dated only by its **As of** dates (S16-40) shows no date anywhere today and sorts last. After this PR the engine gives every event one dating — an occurrence, a span, or an as-of span with its open sides — and every event date line, the Events list order, the Timeline's lifeline, place folding and search read it. A residence known from an obituary of 10 Jan 1990 and a directory of 10 Feb 2015 reads from 10 Jan 1990 to 10 Feb 2015, open on both sides, sorts at 10 Jan 1990, and spans 1990 to 2015 on the lifeline (dogfood bar 18 except the Event page Date row, and bar 19).

**Why now.** S16-40 records as-ofs and matches them; until this PR a researcher who records one sees the event undated. The map review moved every `eventDating` reader here (K-2) and made the engine send the dating (K-3).

**What stays.** Every line for an event with a `date`, a start and an end, a start alone or an end alone reads as today (ED-1). A birth or a death is never dated by an as-of (`lifeFrom`), and its places fold at its own date as today. The Event page's Date row is S16-44's. Nothing writes `start_date` or `end_date`. The Timeline now also draws a start-and-end event across its whole span and a start-only or end-only event open on its missing side, and an end-only event sorts at its end (user, 2026-11-17: one rule for all).

## 2. User stories

**US-1.** As a researcher, when an event is dated only by as-ofs, I see its dating on every date line so that I know when it was under way.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A residence with as-ofs 10 Jan 1990 and 10 Feb 2015 | Events list row, Event page header line, Timeline row, search hit and Promote's candidate menu show `as of 10 Jan 1990–10 Feb 2015` (ED-2); VoiceOver hears "as of 10 January 1990 to 10 February 2015" in the row label |
| AC-1.2 | A residence with one as-of 10 Jan 1990 | `as of 10 Jan 1990` (ED-3); never the bare `10 Jan 1990` an occurrence shows |
| AC-1.3 | `start_date` 1985, as-ofs 10 Jan 1990 and 10 Feb 2015 | `from 1985, as of 10 Feb 2015` (ED-4) |
| AC-1.4 | As-of 1990, `end_date` 2015 | `as of 1990, until 2015` (ED-5) |
| AC-1.5 | As-ofs `abt 1990`, `bef 2015` | `as of abt 1990–bef 2015` (ED-6) |
| AC-1.6 | An event with `date` 14 May 1817; start 1985 and end 2015; start 1985 and end 1985; start 1985 only; end 2015 only | `14 May 1817`; `1985–2015`; `1985–1985`; `1985`; `2015`: the planning-base strings |
| AC-1.7 | A promoted residence whose Source graph has the two as-of Observations | Promote's record row for that Subject shows the AC-1.1 line (from the engine, not from Swift reading Observations) |

**US-2.** As a researcher, I see an as-of event in date order and on my person's lifeline.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Events list with events dated 1989, as-of-only 10 Jan 1990 – 10 Feb 2015, and 1991 | Order: 1989, the residence, 1991 |
| AC-2.2 | Person born 1955, residence with as-ofs 1990 and 2015 | Timeline span From 1990 To 2016, OpenStart and OpenEnd true; age 34–60 |
| AC-2.3 | The same residence with `start_date` 1985 | Span From 1985 To 2016, OpenStart false, OpenEnd true |
| AC-2.4 | A residence with start 1960 and end 1970 | Span From 1960 To 1971, both closed (today: 1960 to 1961) |
| AC-2.5 | An occupation with start 1975 only; one with end 1980 only | Span 1975–1976 OpenEnd true; span 1980–1981 OpenStart true, and the end-only event sorts at 1980 (today: undated, last) |
| AC-2.6 | One as-of 10 Jan 1990; a `bef 14 May 1880` occurrence | Each a one-day span with an open side; the lifeline draws the TL-2 32 pt bar for both (faded at both ends, tethered from its middle; the `bef` faded at its top only, tethered 8 pt in from its lower end), not a dot; a closed `14 May 1880` stays a dot |
| AC-2.7 | A person whose birth event has a start 1948 and an as-of 1950; another whose birth event has only an as-of | The first birth reads 1948 and its places fold at 1948; the second reads no birth date and its places fold with no date (today's fold for an undated birth) |
| AC-2.8 | An event with 10,000 as-ofs | The summary carries two dates; the Events list row builds from them; the compose reads each as-of once (T-6) |

**US-3.** As a researcher, I find an as-of event by its years in search.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Search "1990" with the AC-1.1 residence in the catalog | The residence is a hit; its second line is the AC-1.1 line |
| AC-3.2 | Search "2003" for a residence with as-ofs 1990, 2003 and 2015 | No hit from the as-of 2003: only the dating's two dates are indexed |

**US-4.** As the engine, Promote's shortlist looks up an as-of-only event by its years (S16-40 PRF-1), and no read copies more than `MaxSamples` crafted as-ofs (S16-40 SEC-3).

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | An as-of-only residence (as-ofs 1990, 2015) probes the shortlist | Its lookup keys are its closed samples' year reach plus `wide`; it meets a residence dated 2000 and an `aft 1970` one, and not one dated 1881 |
| AC-4.2 | A residence dated 1881 probes | It still meets the as-of-only residence (its index keys stay one open reach) |
| AC-4.3 | `BenchmarkLargeSourcePropose` at 4,000 and 16,000 persons, `asof=0` and `asof=0.3` (Source A's deaths and the town deaths) | The warm-proposal overhead of `asof=0.3` over `asof=0` (median of 3 runs each) on the branch is not higher than at the planning base with the same shape by more than the spread of those runs (user, 2026-11-17: D-12 narrows only as-of-only probes' lookup, so it cannot lower this overhead; T-12 shows the narrowing); the four rows of each run and the cause of S16-40's flat +3.5 ms `warm-ms` are in the PR body |
| AC-4.4 | A Subject with 1,001 positive as-ofs (above `MaxSamples` 1,000) | `subjectcompare.PeriodSamples` returns nil without copying; compare and the lifespan read none of them; the shortlist files it as one open reach both ways (today's filing) |

## 3. Scope

| In | Covered by |
| --- | --- |
| `valuecompare.DatingOf` *(new)*, the one dating (D-1 – D-4) | STEP-1, AC-1.*, AC-2.* |
| `subjectcompare.Rules.EventPeriod` *(new)*: the one reading of an event's four date keys; its two existing inline readers move onto it (D-7) | STEP-2 |
| `conclusionsummaries`: `EventSummary.Dating`; `eventKeyOf` and `EventSpanAndAge` place it (D-5); place folding takes its date from the caller and `eventWhen` goes; `lifeFrom` keeps `date` or start (D-7) | STEP-3, STEP-4, AC-2.1 – AC-2.8 |
| Wire: `EventDating` on `EventSummary` and `SourceEventTitle` (D-8) | STEP-5, STEP-6 |
| `grapheventtitles` dates each graph Event Subject (D-9) | STEP-6, AC-1.7 |
| `searchindex` indexes the dating; `ProjectionVersion` 12; `sqlHandleValues` reads only what documents use (D-10) | STEP-7, AC-3.* |
| SEC-3: count samples before copying (D-11) | STEP-8, AC-4.4 |
| PRF-1: narrower shortlist lookup for as-of-only events, with the benchmark (D-12, D-13) | STEP-9, AC-4.1 – AC-4.3 |
| Swift wire types and the formatter: `DateRowDisplay` splits into one date and one span, and `line(dating:)` formats the dating on every `EventSecondaryDisplay` surface and on `EvidenceGraphSnapshot.dateLine` (ED-1 – ED-7, ED-W1) | STEP-10, STEP-11, AC-1.* |
| The lifeline's spans, one-day open mark and a both-open bar's tether (TL-1 – TL-3, TL-W1) | STEP-12, AC-2.6 |
| Docs and guidance: `structured-date-model.md` § 3.4, `matching-model.md`'s `MaxSamples` row, `add-date-value`, the `grapheventtitles` package doc, the `CatalogEventSummary` doc | STEP-13 |

| Out | Home |
| --- | --- |
| The Event page Date row (`EventDetailContent.dateRow`) | S16-44 |
| Removing `EventSummary.Date`, `StartDate`, `EndDate` (Go, proto, Swift), `oneEvent`'s clear-start-and-end rule and `DateRowDisplay.span`'s last event caller | S16-44 (map scope entry, user 2026-11-17) |
| A notice for an as-of outside the start or end | [`ideas/event-as-of-followups.md`](../../../ideas/event-as-of-followups.md) |
| Indexing every as-of year in search | not planned (AC-3.2: the line's two dates are what the row shows) |
| Narrowing the as-of-only event's **index** keys | not planned (D-12: it would drop pairs probed from the dated side) |
| A Place's as-of | [`ideas/event-as-of-followups.md`](../../../ideas/event-as-of-followups.md) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Event dating chooser | `core/database/conclusionsummaries/compose.go` `eventDated`, `eventDating`, `datePlace`, `placedDate`, `dateKey`, `eventKeyOf` (lines 1136–1187) | Placed `date`, else placed start, else unplaced date, else start; ignores `end_date` and as-ofs; `eventDated` carries key, span, ends |
| Its readers | `compose.go` `eventDate`, `lifeFrom`, `eventWhen` (called from `eventPlaces`, which `oneEvent` and `lifeFacts` call), `eventKeyOf`; `core/database/conclusionsummaries/order.go` `EventSpanAndAge` | Sort, Timeline span and age, place folding, birth and death all read `eventDating` |
| Summary compose | `compose.go` `oneEvent`, `keptDateAt` | Reads rank-1 `date`, `start_date`, `end_date`; clears start and end when `date` is set. Never reads `as_of` |
| Summary type | `core/database/conclusionsummaries/events.go` `EventSummary` | `Date`, `StartDate`, `EndDate` and counts; no dating |
| Timeline | `core/database/persondetail/timeline.go` (`EventSpanAndAge` at line 148); `api/ffi/handlers/person_detail.go` line 297 | Span and age from `EventSpanAndAge`; open flags reach Swift `CatalogTimelineSpan` |
| Date helpers | `core/valuecompare/datewindow.go` `DateEnds`, `SampleExtremes`, `EndsWindow`; `core/valuecompare/dateorder.go` `DateKeyOf`, `DateKey.Compare` | S16-40 added `SampleExtremes`, documented as the selection this PR reuses; the caller supplies the reading |
| Event period | `core/matchregistry/subject.go` `Periods[Event][date]` (`Start`, `End`, `Samples: as_of`, `MaxSamples: 1000`); read inline at `core/database/evidencelayer/evidencelayer.go:186` and `core/database/promotealign/profiles.go:184` | Two hand-written copies of "the event's lead and its period" |
| SEC-3 | `core/subjectcompare/pairs.go` `PeriodSamples`, `samplesAgainst` | Copies every positive sample, then `samplesAgainst` checks `len > MaxSamples` |
| PRF-1 | `core/shortlist/shortlist.go` `Keys` lines 96–135 | An as-of-only event is one open reach: index `wide`+`any`, lookup `any` (meets every event of its type); `len(subjectcompare.Samples(…)) > 0` copies to test presence |
| Benchmark | `core/database/promotealign/bench_test.go` `catalogShape`, `bulkCanon` (date row written with `dateP` / `dateVal` at lines 285, 355, 432), `BenchmarkLargeSourcePropose`; `core/database/promotealign/perf_test.go` `newLargeFixture` (Source A's dated births and deaths through `filedOn`) | No as-of in either Source A or the catalog |
| Wire | `api/proto/engine.proto` `EventSummary` (fields 1–18), `SourceEventTitle` (1–2), `TimelineSpan`; `api/ffi/handlers/conclusion_summaries.go` `eventSummaryProto`; `api/ffi/handlers/event_titles.go` `ListEvidenceGraphEventTitles` | No dating |
| Graph titles | `core/database/grapheventtitles/grapheventtitles.go` `FromStored`, `Title` | Titles each Event Subject from its graph's Observations (loaded `ORDER BY o.ref COLLATE NOCASE`, `core/database/graphfill/load.go:179`, the same order Swift's Observation list has); no dates |
| Search | `core/database/searchindex/handles.go` `sqlHandleValues`, `loadHandleValues`, `matchText`, `eventMatchSecondary`; `core/database/searchindex/searchindex.go` `ProjectionVersion = 11` | `eventMatchSecondary` indexes `CompactDisplay` of `Date`, `StartDate`, `EndDate`. `sqlHandleValues` loads `event_type`, `date`, `start_date`, `end_date` that `matchText` never reads (it reads `name` and `toponym` only); `loadHandleValues` has a date branch and a term branch only those keys reach |
| Swift line | `macos/App/Platform/DateRowDisplay.swift` `line(date:start:end:)`; `macos/App/Features/Conclusions/EventsListView.swift` `EventSecondaryDisplay.content` | Swift chooses date over start–end. `content` serves the Events list, `EventDetailContent` header (line 31), `PersonTimelineContent` (line 368), `ConclusionSummaryDisplay.secondary` (search hits, `PromoteFlow` line 555). Other `line` callers pass `date:` only (`PersonLifeDisplay.swift:107`, `ReconciledValueDisplay.swift:107`, `SourcesRowDate.swift:8`, `SourceDateDialog.swift:72`) or `date: nil` with start and end (`EventDetailContent.swift:72`) |
| Swift graph line | `macos/App/Features/Workspace/Session/EvidenceGraphSnapshot.swift` `EvidenceGraphPlacedSubject.dateLine` | Reads the first asserted `date`, `start_date`, `end_date` Observations itself; read by `PromoteModel.subjectFacts` (`PromoteModel.swift:413`) |
| Swift graph titles | `GoStore.listEvidenceGraphEventTitles`, `GenealogyStore`, `FakeStore` (`eventTitlesByGraph`), `CatalogQueryRegistry.swift` line 252, `EvidenceGraphSnapshot.eventTitles`; stub at `macos/ProvenenciaTests/OnboardingModelTests.swift` lines 617–620 | `[String: CatalogEventTitle]` |
| Swift sites that set event dates | `macos/ProvenenciaTests/EventDetailTests.swift` `dated(date:start:end:)` (lines 41–51); `macos/ProvenenciaTests/PersonsListTests.swift` `eventsRowSecondLine` (lines 156–171); `macos/App/Features/Conclusions/PersonTimelinePreviewData.swift` `apply(to:)` (lines 36–55); `macos/ProvenenciaTests/PromoteModelTests.swift` `aPlacedEventsRowCarriesItsDate` (lines 832–858) and `macos/ProvenenciaTests/EvidenceGraphSnapshotTests.swift` `anEventsDateLineReadsItsDateObservations` (line 453), which build `dateLine` from date Observations | Set dates and expect a line through `content` or `dateLine` |
| Lifeline | `macos/App/Features/Conclusions/PersonTimelineLifeline.swift`: the nested `point(_:_:stubsBefore:)` in the layout builder (line 182), `Mark.pointY`; drawing in `PersonTimelineSection.swift` lines 529–550 | A span of a day or less is a `.dot` (open flags dropped); a `.bar` fades its open sides (`fade = min(16, height)`); a bar open at both ends tethers 8 pt in from `to` |
| Tests | `core/database/conclusionsummaries/conclusionsummaries_test.go` `TestEventSpan`, `TestEventSpanDays`, `TestEventOrderAtKnownEnd`, `TestEventAge`, `TestListEvents`; `core/database/persondetail/timeline_test.go` `TestPersonEventsLifeline`; `core/database/searchindex/searchindex_test.go`; `core/database/grapheventtitles/grapheventtitles_test.go` `TestForEvidenceGraph`; `core/shortlist/shortlist_test.go` `TestKeys`, `TestFind`; `core/valuecompare/datewindow_test.go` `TestSampleExtremes`; `api/ffi/handlers/conclusion_summaries_test.go` `TestListEventSummaries`; `core/graphalign/align_test.go` `TestGracieObituaryGolden`; Swift `DateRowDisplayTests`, `EventDetailTests`, `EvidenceGraphSnapshotTests`, `PersonTimelineLifelineTests`, `CatalogSearchTests`, `PersonsListTests` | `TestEventSpan` pins "start date only" (closed), "end date only" (undated) and "date with no year, dated start" (1860), which D-2, D-4 and D-5 change |

**Precedent.** S16-40 ([#869](https://github.com/mendahu/provenencia/pull/869)) added `SampleExtremes` beside `Earliest`/`Latest` with the reading supplied by the caller, and broke its ties so picks never depend on input order (`samplesAgainst`): copy both. For wire on a graph Subject, copy how `ListEvidenceGraphEventTitles` sends Go's title per Event Subject (S9 R4): one field more on `SourceEventTitle`, not a new RPC. For a `ProjectionVersion` bump with its comment line, copy S14-40's 11.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `valuecompare.DatingOf(date, start, end *datevalue.Value, samples []datevalue.Value) Dating` in `core/valuecompare/dating.go` *(new)*. `Dating{Kind DatingKind; Low, High *datevalue.Value; OpenLow, OpenHigh bool}`; `DatingKind` is `DatingNone`, `DatingOccurrence`, `DatingSpan`, `DatingAsOf`. Pure; no Property keys, no order key or ends: placing a dating is the caller's (D-5) | Working rule "One dating": one pure helper in `valuecompare`, typed on date slices. Named for what it reads, not for events, so a Place's period can call it ([idea](../../../ideas/event-as-of-followups.md)) | A method on `EventSummary` — `grapheventtitles` needs it without a summary; a Swift copy — rule K-3; key and ends on `Dating` — Conclusion order internals in a domain-neutral type (S15-02 D-4) |
| D-2 | **Occurrence.** A non-nil `date` gives `DatingOccurrence`, `Low = date`, `High = nil`, open flags false. Start, end and samples are not read | The line already shows a recorded `date` whenever one is set, and `oneEvent` already clears start and end then, so list order and the Timeline already treat an unplaced `date` as undated: this closes § 3.4's drift note without changing a list | Placed date else placed start (today's `eventDating`) — the line and the order would keep disagreeing |
| D-3 | **Samples.** A sample whose `DateKeyOf` is not ok is skipped (no year, both ends open, a year outside the window). Each other sample is read once with `DateEnds` (as written; About not widened) into its **earliest closed end** E (`first`, else `last`) and its **latest closed end** L (`last`, else `first`). `SampleExtremes(firsts: Ls, lasts: Es)` gives the low pick (`endsFirst`: lowest `E.Hi`) and the high pick (`startsLast`: highest `L.Lo`). Ties: among samples with the picked `E.Hi`, the low pick is the lowest `E.Lo`; among those with the picked `L.Lo`, the high pick is the highest `L.Hi`; samples equal in both ends go to the lower index (kept rank order, stable across reads). So `abt 1990` and `bef 2015` date 1990 – 2015; a range `bet 1985 and 1995` beside 1990 is both picks, so the dating is that one range (Low the range, High nil, D-4) | `event-as-of.md`'s known span runs from the earliest of the samples' closed sides to the latest; `SampleExtremes` with this reading is that selection, and the caller supplies the reading as S16-40 designed it. The tie rule reads values, not order, as `samplesAgainst` does (review M-4) | Each sample's own first and last ends (the matching reading) — `bef 2015` has no closed first, so it would never be the high pick and `abt 1990` + `bef 2015` would show 1990 alone (review X-1) |
| D-4 | **Span and as-of.** With no placed sample: `DatingSpan` with `Low = start`, `High = end` as recorded (placed or not, equal or not), `OpenLow = start == nil`, `OpenHigh = end == nil`; neither recorded → `DatingNone`. With a placed sample: Low = the earlier, by `DateKey.Compare`, of a placed start and the low pick; a tie goes to the start. High = the later of a placed end and the high pick; a tie goes to the end. An unplaced start or end is not read. `OpenLow` is true unless Low is the start; `OpenHigh` unless High is the end. `Kind` is `DatingAsOf` when either side is a sample, else `DatingSpan` (as-ofs inside a start and end). `High` is nil exactly when both sides are the same sample (by index); a nil `High` always means one date, on every reader | Design table in `event-as-of.md`; rule "a start or an end closes that side"; the span text stays today's for every no-as-of event (`1985–1985` included, AC-1.6); user 2026-11-17 | Start wins over an earlier as-of — would hide the as-of the researcher recorded; the contradiction notice is the idea file's |
| D-5 | **Placing.** `placeDating(d valuecompare.Dating) placedDating` *(new, `compose.go` beside `datePlace`)*: `placedDating{key dateKey; span TimelineSpan; first, last valuecompare.DateEnd}`, from `datePlace` of Low and of High. key: Low's when placed, else High's (`ok` false when neither). span: From is Low's span From (High's when Low is nil or unplaced); To is High's span To (Low's when High is nil or unplaced); `OpenStart = OpenLow || that span's OpenStart`, `OpenEnd = OpenHigh || that span's OpenEnd`. An occurrence's span is `datePlace(date).span` exactly. first: Low's first end (High's when Low is unplaced); last: High's last end (Low's when High is nil or unplaced). `eventKeyOf` and `EventSpanAndAge` call it on `h.Dating`; `Days = EndsWindow(first, last)`. **Age** reads `first` and `last` as it reads `ev.first` / `ev.last` today: the dating's open sides do not open the age, only a date's own open end does | User 2026-11-17 (whole span, open on a missing side). The person was alive on each known day, so the age over the known span is true | Opening the age on an open side — an as-of residence would never show an age; storing the placing on the summary — the Go tests build summaries by hand and the placing is cheap |
| D-6 | No sample cap in `DatingOf`: every kept as-of is read once. The summary is composed once per change of the node and cached (`SetDisplay`) | Map Scale (Batch 5): "the dating read two extremes after one pass"; a cap would date a crafted event differently from a real one | `MaxSamples` here — a crafted event would read undated in display while matching skips it; two rules |
| D-7 | **Summaries.** `subjectcompare.Rules.Period(kind vocabkey.SubjectType, key vocabkey.PropertyKey) (Period, bool)` *(new, `core/subjectcompare/subjectcompare.go`)* is the one lookup of `Periods`: `Side`, `Samples`, `samplesAgainst` (`pairs.go` lines 32, 45, 80) and the period check at `subjectcompare.go:244` call it. `Rules.EventPeriod() (lead vocabkey.PropertyKey, p Period)` *(new)* returns `vocabkey.PropertyDate` and `Period(vocabkey.Event, vocabkey.PropertyDate)`; `evidencelayer.go:186` and `profiles.go:184` move onto it. `conclusionsummaries` reads it once into a package var `eventPeriod` *(new)* from `matchregistry.Default().Subject`. `EventSummary.Dating valuecompare.Dating` *(new field)* is set in `oneEvent` before start and end are cleared, from rank-1 lead, start and end (`keptDateAt`) and every kept sample (`keptDates`, new), each Property id read as `v.prop(eventLead)`, `v.prop(eventPeriod.Start)`, `v.prop(eventPeriod.End)`, `v.prop(eventPeriod.Samples)` (package vars `eventLead`, `eventPeriod` from `EventPeriod()`); `oneEvent`'s three hand-written `vocabkey.PropertyDate` / `PropertyStartDate` / `PropertyEndDate` reads go. `eventPlaces(v vocab, pg *placeGraph, at *datevalue.Value, locations []graphcache.Link)` takes the fold date from its caller: `oneEvent` passes `Dating.Low`, else `Dating.High`; `lifeFacts` passes `pick.date` (the birth's or death's own date, as today). `eventWhen` is deleted. `eventDating` / `eventDate` become `lifeDating` / `lifeDate`, read only by `lifeFrom` (placed date, else placed start, else date, else start; `eventDated` loses `span`, `first`, `last`); `lifeDate` reads `eventLead` and `eventPeriod.Start` the same way | Working rules: four keys from `subject.Periods`; a birth or death never dated by an as-of. The as-ofs are read on one path, once per compose (review M-1, X-3) | Re-reading the node in `eventWhen` — reads the as-ofs twice and would fold a birth with only an as-of at that as-of; a fourth inline copy of the period lookup (review M-3) |
| D-8 | **Wire.** `message EventDating { EventDatingKind kind = 1; DateValueInput low = 2; DateValueInput high = 3; bool open_low = 4; bool open_high = 5; }`; `enum EventDatingKind { EVENT_DATING_KIND_UNSPECIFIED = 0; EVENT_DATING_KIND_OCCURRENCE = 1; EVENT_DATING_KIND_SPAN = 2; EVENT_DATING_KIND_AS_OF = 3; }` (UNSPECIFIED is none); `EventSummary.dating = 19`; `SourceEventTitle.dating = 3`. Go `eventDatingProto(d valuecompare.Dating) *engine.EventDating` *(new, `conclusion_summaries.go`)*. Swift `struct CatalogEventDating: Sendable, Equatable { enum Kind: Sendable, Equatable { case none, occurrence, span, asOf }; var kind: Kind = .none; var low, high: CatalogDateValueInput?; var openLow = false, openHigh = false }` *(new, `GenealogyStore.swift`)*; `CatalogEventSummary.dating = CatalogEventDating()`; `GoStore.mapEventDating` *(new)* | Rule K-3: kind, two dates, open sides | Sending as-ofs — rule; sending the order key — the list already gets `ListKey` |
| D-9 | **Graph Subjects.** `grapheventtitles.Title` gains `Dating valuecompare.Dating`. `FromStored` collects, per Event Subject, the first positive lead, start and end Observation in `eg.Observations` order (by ref, the order Swift's `dateLine` reads today) and every positive sample (`valuecodec.UnmarshalDate` of `o.Date`; one that fails is skipped), keys from `matchregistry.Default().Subject.EventPeriod()` (as package vars, as D-7), and calls `DatingOf`. The package doc says it titles and dates. Swift: the store method keeps its name and returns `[String: CatalogSourceEventTitle]` *(new: `title`, `dating`; named for the wire message `SourceEventTitle`)*; `EvidenceGraphRows` / `EvidenceGraphSnapshot.eventTitles` carry it; `EvidenceGraphPlacedSubject` gains `eventDating: CatalogEventDating?`, set beside `eventTitle` from the same `CatalogSourceEventTitle` entry (`eventTitles[subject.id]`, `EvidenceGraphSnapshot.swift` line 267); `dateLine` is `DateRowDisplay.line(dating:includesPhrase: false)` over it, `""` when nil | Rule K-3 names `EvidenceGraphSnapshot.dateLine`; the titles read already carries per-Subject engine facts | A new RPC — one more round trip per graph; Swift reading as-of Observations — rule |
| D-10 | **Search.** `eventMatchSecondary` indexes `CompactDisplay` of `h.Dating.Low` and `h.Dating.High`. `sqlHandleValues` reads only `('name', 'toponym')`: `r.value_date`, the `property_terms` join and `loadHandleValues`' date and term branches go. `ProjectionVersion = 12` with "12: an Event's dating, as-ofs included (S16-42)" | An Event's search text follows its line; a bump heals catalogs created since S16-40; the query reads only what a document uses (review M-7) | Adding `as_of` to `sqlHandleValues` — never read |
| D-11 | **SEC-3.** `subjectcompare.CountSamples(v Values, p Period) int` *(new, `pairs.go`)* counts `v[p.Samples]`'s positive values without copying. `PeriodSamples` calls it and returns nil when the count is 0 or above `p.MaxSamples`, then copies. `samplesAgainst`'s own `len(samples) > p.MaxSamples` check goes. `shortlist.Keys` tests presence with `CountSamples > 0` (no copy) | Count before copy; one place holds the cap | A second cap check per caller — two readings of one cap |
| D-12 | **PRF-1.** In `shortlist.Keys`, an event with no positive lead or stand-in and `CountSamples > 0`: its **index** keys stay one open reach (`wide`, `any`). Its **lookup** keys: when `PeriodSamples` is not nil, `lo` and `hi` are the lowest and highest bound over the samples whose `valuecompare.YearReach` is closed (tolerance included, as `YearReach` returns it; open ones are ignored), emitted as a closed probe's lookup (`wide` plus the buckets); when none is closed, the reach exceeds `MaxBuckets`, or the count is above the cap, the lookup stays `any` (today). `Keys` reads the period once as `p, _ := subject.Period(kind, d.Date)` and passes it to `CountSamples` and `PeriodSamples`. The `reach` struct's `open` becomes `indexOpen` and `lookupOpen`; a dated reach sets both from `YearReach` as today; the as-of reach sets `indexOpen` true and `lookupOpen` from its own closed bounds; the `MaxBuckets` test sets both for a dated reach and only `lookupOpen` for the as-of reach. No second branch | An as-of-only probe stops meeting every event of its type; a dated probe still meets it through `wide` (AC-4.2), so the pairs S16-40 D-9 protected are kept from that side. Lost: an as-of-only probe meeting a catalog event whose date reach is wholly outside its samples' years; a closed period there conflicts anyway; an occurrence there compares unknown on date | Narrowing the index too — drops D-9's pairs from both sides; samples' years ±`MaxYears` — exceeds `MaxBuckets` and gives the same keys (S16-40 verifier) |
| D-13 | **Benchmark.** `catalogShape.AsOfShare float64` *(new)*: in `bulkCanon`, each town death is chosen from a second stream `rand.New(rand.NewPCG(3, 4))` (the shape's `Rand` is not drawn, so `asof=0` builds the base catalog byte for byte) and, when `< AsOfShare`, its date row is written on the `as_of` property (`idOf(db, "properties", "as_of")`) with the same columns and values the `date` row gets. `newLargeFixtureAsOf(t, persons int, asOfShare float64)` *(new, `perf_test.go`)* does the same for Source A's deaths in `filedOn` (an as-of Observation instead of a date, same second stream); `newLargeFixture` calls it with 0; `TestLargeSourceBudgets` is unchanged. `BenchmarkLargeSourcePropose` runs `persons=4000,16000` × `asof=0,0.3`. Run it at the planning base with D-13 applied (STEP-9 first commits the shape; the base run checks that commit out on top of `dbc946c`) and on the branch. The +3.5 ms: compare `-cpuprofile` of `asof=0` and `asof=0.3` warm proposals and name the top differing function in the PR body | Map scope: measured at 4,000 and 16,000 with 30% as-of deaths; Source A must hold as-of-only probes for D-12 to show (review X-2) | Measuring only town deaths — every probe is dated, D-12 changes nothing |
| D-14 | **Swift formatter.** `DateRowDisplay` splits: `line(date:includesPhrase:precision:locale:)` formats one date (today's callers that pass `date:` only); `span(start:end:includesPhrase:precision:locale:)` *(new name)* formats today's start–end text (`rowSpan`, or the one side recorded); `line(dating:includesPhrase:locale:)` *(new)*: `.occurrence` → `line(date: low)`, `.span` → `span(start: low, end: high)`, `.asOf` → by the open flags, over `line(date:)` of Low and High: both open and High nil → `L10n.Dates.rowAsOf(low)`; both open → `rowAsOfRange(low, high)`; low closed (a start), high open → `rowFromAsOf(low, high)`; low open, high closed (an end) → `rowAsOfUntil(low, high)`; `.none` → "". Each date keeps its own qualifier and phrase (ED-6). The chooser `line(date:start:end:)` is deleted; `EventDetailContent.dateRow` calls `span(start:end:)` until S16-44 | Rule K-3 retires Swift's date-wins chooser (review M-2); no caller passes a date with a start or end after this PR | Keeping the chooser for its other callers — the rule names it |
| D-15 | Tests, previews and `FakeStore` that build a `CatalogEventSummary` with dates, or a `CatalogSourceEventTitle`, set its `dating` with the memberwise initializer (`FakeStore` seeds `eventTitlesByGraph`, never derives from Observations: `.cursor/rules/swift-tests.mdc`); no Swift helper derives a dating from date fields. `PersonTimelinePreviewData.apply(to:)`: `.day`, `.month`, `.year`, `.before` → `.occurrence` with `low` the date it sets; `.years` → `.span` with `low` start, `high` end | Rule K-3: Swift never decides which key dates an event | A `CatalogEventDating(date:start:end:)` convenience — a Swift copy of D-2 / D-4 |
| D-16 | **Lifeline.** In the nested `point(_:_:stubsBefore:)`, a span whose `to - from` is a day or less and which has an open side becomes `.bar` centred on the day with length `PersonTimelineLifeline.openDayLength` *(new constant, 32 pt: twice the 16 pt fade, board TL-2)*; a `.bar` open at both ends tethers at its middle (`Mark.pointY`), as a closed bar already does (board TL-3). No new `Shape` case. This also draws a day-precision `bef` / `aft` occurrence as the short faded bar instead of a dot, as a year-precision `bef` already draws a faded bar; a closed day stays a dot | Brief S16-D7 TL-1 – TL-3 (the brief draws TL-2 as the TL-1 fade at a fixed short length); the span carries no dating kind and an open day is open whatever its kind (review M-5, M-6) | A fourth `Shape` case — three switches and their tests repeat it; a dating kind on `TimelineSpan` to keep `bef` days as dots — a wire field to keep a mark that hides the open side |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `valuecompare.DatingOf`, `Dating`, `DatingKind` in `core/valuecompare/dating.go` *(new)* | func, types | `conclusionsummaries.eventDating` / `eventDated` | In a database package, no end or sample; the rule wants it pure in `valuecompare`; `eventDating` shrinks to `lifeDating` |
| `subjectcompare.Rules.Period`, `Rules.EventPeriod` *(new)* | method | inline `Periods[…][…]` in `pairs.go` (3), `subjectcompare.go:244`, `evidencelayer.go:186`, `profiles.go:184` | One lookup replaces six |
| `subjectcompare.CountSamples` *(new)* | func | `PeriodSamples` | Counting without copying; `PeriodSamples` calls it |
| `conclusionsummaries.placeDating`, `placedDating` *(new)* | func, type | `datePlace`, `placedDate`, `eventDated` | Builds on `datePlace` for each side; `eventDated`'s placing fields go |
| `conclusionsummaries.keptDates` *(new)* | func | `keptDateAt` | `keptDateAt` reads rank 1 only |
| `conclusionsummaries.eventPeriod` *(new var)* | var | `searchindex.productRules` (package var from a registry) | Same pattern |
| `EventDating`, `EventDatingKind` *(new proto)*; `eventDatingProto` *(new)* | message, func | `TimelineSpan`, `eventTitleProto` | A different fact |
| `CatalogEventDating`, `CatalogSourceEventTitle` *(new Swift)*; `GoStore.mapEventDating` *(new)* | struct, func | `CatalogTimelineSpan`, `CatalogEventTitle` | Mirror the wire |
| `DateRowDisplay.span(start:end:)`, `DateRowDisplay.line(dating:)` *(new)* | func | `DateRowDisplay.line(date:start:end:)` | Splits it; the chooser goes |
| `PersonTimelineLifeline.openDayLength` *(new constant)* | constant | `.bar`'s minimum `max(to, top + 6)` | Must hold two fades |
| `catalogShape.AsOfShare`, `newLargeFixtureAsOf` *(new, tests)* | test helper | `newLargeFixture` | One knob on the existing fixture |
| L10n `Dates` as-of keys *(new)* | key | `L10n.Dates.rowSpan` | Wording set by the board (§ Strings) |

**Builds on.** `valuecompare.SampleExtremes` and `DateEnds` (S16-40); `matchregistry` `Periods` through one accessor (rule); `ListEvidenceGraphEventTitles` (wire per graph Subject); `PVDatePlaceLine` and `EventSecondaryLine` unchanged; the lifeline's `.bar` fade.
**Deletes.** `eventWhen`; `eventDated`'s `span`, `first`, `last`; `DateRowDisplay.line(date:start:end:)`; `EvidenceGraphPlacedSubject.dateLine`'s Observation reading and its test `anEventsDateLineReadsItsDateObservations`; `sqlHandleValues`' `event_type`, `date`, `start_date`, `end_date`, `value_date` and term join with `loadHandleValues`' two dead branches; `samplesAgainst`'s `MaxSamples` check; the two inline period lookups; `TestEventSpan` rows pinning the old start-only, end-only and unplaced-date rule are rewritten.
**Next adds.** S16-44's Date row branches on `summary.dating.kind`, then deletes `EventSummary.Date` / `StartDate` / `EndDate` on every layer, `oneEvent`'s clear rule and `span(start:end:)`'s last event caller (map scope entry). A Place's as-of calls `DatingOf` with its period.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| An event dated only by as-ofs | Events list, Timeline, search, Promote menus and rows | Dated and sorted from its dating (D-4, D-5); line per board |
| An end-only event now dated | Events list order, Timeline | Sorts at its end; drawn open before (D-4, D-5) |
| A one-day span with an open side | the lifeline's `point` | Short faded bar (D-16); click target as a bar's |
| A catalog with no `as_of` Property (created before S16-40) | `oneEvent`, `FromStored` | `v.prop` returns nil, `Node.Kept(nil)` returns none: no samples, today's dating |
| A graph Subject with no date Observations | `dateLine` | `.none` → "" as today |

### Scale

At the map's Scale (Batch 5): an event with up to 20 as-ofs on a person with 200 events: `oneEvent` unmarshals 20 extra dates once per change of the node (cached display), `SampleExtremes` one pass; the Timeline places each row's two dates (two `DateKeyOf`). Crafted: 10,000 as-ofs on one event → 10,000 unmarshals and two `DateEnd` slices of 10,000 in one compose (T-6 asserts the summary holds two dates and the compose stays under 50 ms); the wire carries two dates. Graph titles: one pass over `eg.Observations`, as today. Search: two `CompactDisplay` per event. Shortlist (Batch 2 Scale, D-13): an as-of-only probe's lookup goes from every event of its type to its sample years' buckets plus `wide`. Over the cap, `CountSamples` counts without copying (AC-4.4).

### Edges

- **Assumptions.** `ListKey` sorting assumes one key per row: the key is placed from `h.Dating`, which compose sets once (T-2). Picks never depend on row order (D-3 tie rule; T-1 reversed rows). `datePlace` assumes a placeable date: `placeDating` places only sides `DateKeyOf` accepts.
- **Neighbors.** `date` with no year beside a placed start: undated in order and on the Timeline (D-2; the summary already behaves so). Start only → open end; end only → dated at its end, open start; start equal to end → `1985–1985` as today. An as-of equal to the start → the start (closed). An as-of after the end → the as-of is both picks, so the dating is that as-of alone (High nil, open both sides: `as of 2020`, D-4); an as-of before an end-only event → Low the as-of, High the end, closed after (T-1 rows). A range as-of alone, or beside a point inside it → Low the range, High nil, open both sides: `as of bet 1985 and 1995`. `bef` / `aft` day-precision occurrences now draw the short faded bar (D-16).
- **Removed inputs.** A deleted as-of Observation re-keeps the node's values; the cached display is per node and dropped on its change as today; the next compose redates (T-2 "edit" row). An as-of the reconciler does not keep is not read.
- **Real data.** The dogfood project has no `as_of` (new catalogs only); every line for an event with a date, start or end must be the planning-base string (T-13 runs each AC-1.6 shape against literal strings; manual check 6 compares the dogfood Events list before and after).
- **Untrusted size.** As-ofs per event: one linear pass on read (D-6), two dates sent. Per graph Subject as-of Observations: one pass. Matching: counted before copy, cap 1,000 (D-11).

### Schema

None — no catalog change. `as_of` is seeded by S16-40.

### Go core

| Package | Change |
| --- | --- |
| `core/valuecompare` | `core/valuecompare/dating.go` *(new)*: D-1 – D-4 |
| `core/subjectcompare` | `subjectcompare.go` `Rules.EventPeriod`; `pairs.go` `CountSamples`, `PeriodSamples`, `samplesAgainst` (D-7, D-11) |
| `core/database/evidencelayer`, `core/database/promotealign` | `evidencelayer.go:186`, `profiles.go:184` read `EventPeriod` (D-7) |
| `core/database/conclusionsummaries` | `events.go` `EventSummary.Dating`; `compose.go` `oneEvent`, `keptDates`, `eventPlaces`, `lifeFacts`, `lifeFrom` / `lifeDate`, `lifeDating`, `placeDating`, `eventKeyOf`, `eventPeriod`; `order.go` `EventSpanAndAge` (D-5, D-7) |
| `core/database/grapheventtitles` | `Title.Dating`; `FromStored`; package doc (D-9) |
| `core/database/searchindex` | `handles.go` `sqlHandleValues`, `loadHandleValues`, `eventMatchSecondary`; `searchindex.go` `ProjectionVersion` (D-10) |
| `core/shortlist` | `shortlist.go` `Keys` (D-11, D-12) |
| `core/database/promotealign` | `bench_test.go` `catalogShape.AsOfShare`, `bulkCanon`, `BenchmarkLargeSourcePropose`; `perf_test.go` `newLargeFixtureAsOf` (D-13) |

```go
// core/valuecompare/dating.go (sketch)
type DatingKind int

const (
	DatingNone DatingKind = iota
	DatingOccurrence
	DatingSpan
	DatingAsOf
)

type Dating struct {
	Kind              DatingKind
	Low, High         *datevalue.Value
	OpenLow, OpenHigh bool
}

func DatingOf(date, start, end *datevalue.Value, samples []datevalue.Value) Dating
```

Errors: none new.

### FFI

`api/proto/engine.proto`: `EventDating`, `EventDatingKind` *(new)*; `EventSummary.dating = 19`; `SourceEventTitle.dating = 3` (D-8). Handlers: `api/ffi/handlers/conclusion_summaries.go` `eventSummaryProto` sets `Dating` through `eventDatingProto`; `api/ffi/handlers/event_titles.go` sets it on each `SourceEventTitle`. Regenerate with `./scripts/generate-proto.sh` (needs `protoc` with the Go and Swift plugins; where they are missing, the PR names it and CI's generated-file check is the gate). No new Method.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Date and place line | `PVDatePlaceLine` | `macos/App/DesignSystem/Components/DatePlaceLine/PVDatePlaceLine.swift` | Ship, unchanged |
| Event secondary line | `EventSecondaryDisplay`, `EventSecondaryLine` | `macos/App/Features/Conclusions/EventsListView.swift` | `content` reads `summary.dating` (D-14) |
| Row date text | `DateRowDisplay` (shared Platform formatter) | `macos/App/Platform/DateRowDisplay.swift` | Split and extended (D-14) |
| Graph Event line | `EvidenceGraphPlacedSubject.dateLine` | `macos/App/Features/Workspace/Session/EvidenceGraphSnapshot.swift` | Reads `eventDating` (D-9) |
| Lifeline mark | `.bar` in `PersonTimelineLifeline`; drawing in `PersonTimelineSection.swift` | `macos/App/Features/Conclusions/` | One-day open bar and middle tether (D-16) |
| Wire types | `CatalogEventDating`, `CatalogSourceEventTitle` | `macos/App/Platform/GenealogyStore.swift`; mapping `GoStore.swift` | New; the `CatalogEventSummary` doc comment stops saying Swift picks a date |

States: an event with no dating → empty date, place only (today). Large: two dates whatever the as-of count. Accessibility: the row label speaks the same words (`EventSecondaryDisplay.line(content)`), so the open-side wording is in words (S16-D4 ED-7). Regular and Wide: identical (ED-W1).

### Strings

L10n keys *(new)*, in `L10n.Dates` beside `rowSpan`, each with a translator comment naming its arguments, in `Localizable.xcstrings` (board S16-D4 frame 1a):

| Function | Key | English | When |
| --- | --- | --- | --- |
| `rowAsOf(_:locale:)` | `dates.row.asOf` | `as of %@` | as-of, both sides open, one date |
| `rowAsOfRange(start:end:locale:)` | `dates.row.asOfRange` | `as of %1$@–%2$@` (en dash) | as-of, both sides open |
| `rowFromAsOf(start:asOf:locale:)` | `dates.row.fromAsOf` | `from %1$@, as of %2$@` | a start closes the earliest side, the latest open |
| `rowAsOfUntil(asOf:end:locale:)` | `dates.row.asOfUntil` | `as of %1$@, until %2$@` | the earliest open, an end closes the latest side |

The row label speaks these strings as they are; the board's VoiceOver line ("as of 10 January 1990 to 10 February 2015") is how VoiceOver reads them, not a second string. No existing key changes; `dates.row.span` stays for spans. No copy names an old scope.

## 7. Steps

**STEP-1 — The one dating in `valuecompare`**
Files: `core/valuecompare/dating.go` *(new)*, `core/valuecompare/dating_test.go` *(new)*. Skill: `add-date-value`.
Do: D-1 – D-4.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/valuecompare/` passes with T-1.

**STEP-2 — One reading of the event period**
Files: `core/subjectcompare/subjectcompare.go`, `core/database/evidencelayer/evidencelayer.go`, `core/database/promotealign/profiles.go`. Skill: `add-match-rule`.
Do: D-7's `Period` and `EventPeriod`; move the six readers onto them.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/subjectcompare/ ./core/database/evidencelayer/ ./core/database/promotealign/ ./core/graphalign/` passes, `TestGracieObituaryGolden` unchanged.

**STEP-3 — Summaries carry and place the dating**
Files: `core/database/conclusionsummaries/events.go`, `compose.go`, `order.go`, `conclusionsummaries_test.go`. Skill: `add-date-value`.
Do: D-5, D-6, D-7's `EventSummary.Dating`, `keptDates`, `eventPeriod`, `placeDating`, `eventKeyOf`, `EventSpanAndAge`. Rewrite `TestEventSpan` / `TestEventSpanDays` rows to build `EventSummary{Dating: valuecompare.DatingOf(…)}`; add T-2 – T-4, T-6.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/conclusionsummaries/ ./core/database/persondetail/` passes.

**STEP-4 — Place folding takes its date from the caller; births keep theirs**
Files: `core/database/conclusionsummaries/compose.go`, `conclusionsummaries_test.go`.
Do: D-7's `eventPlaces` signature, `eventWhen` deleted, `lifeDating` / `lifeDate`; T-5.
Check: same command as STEP-3 passes; `rg -n 'eventWhen|eventDating\(|func eventDate\(' core` finds nothing.

**STEP-5 — The wire carries the dating**
Files: `api/proto/engine.proto`, generated `api/proto/engine/engine.pb.go` and `macos/App/Platform/Generated/engine.pb.swift`, `api/ffi/handlers/conclusion_summaries.go`, `api/ffi/handlers/conclusion_summaries_test.go`. Skill: `add-ffi-handler`.
Do: D-8 (Go side); `./scripts/generate-proto.sh`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/...` passes with T-7.

**STEP-6 — Graph Subjects are dated by the engine**
Files: `core/database/grapheventtitles/grapheventtitles.go`, `grapheventtitles_test.go`, `api/ffi/handlers/event_titles.go`. Skill: `add-ffi-handler`.
Do: D-9 (Go side).
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/grapheventtitles/ ./api/...` passes with T-9.

**STEP-7 — Search indexes the dating**
Files: `core/database/searchindex/handles.go`, `searchindex.go`, `searchindex_test.go`. Skill: `add-searchable-kind`.
Do: D-10.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/searchindex/ ./core/search/` passes with T-10.

**STEP-8 — Samples are counted before they are copied**
Files: `core/subjectcompare/pairs.go`, its tests, `core/shortlist/shortlist.go`. Skill: `add-match-rule`.
Do: D-11.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/subjectcompare/ ./core/shortlist/ ./core/subjectprofile/ ./core/graphalign/ ./core/database/promotealign/` passes with T-11; `TestGracieObituaryGolden` unchanged.

**STEP-9 — The shortlist looks up an as-of-only event by its years**
Files: `core/database/promotealign/bench_test.go`, `perf_test.go` (commit the D-13 shape first), then `core/shortlist/shortlist.go`, `shortlist_test.go`. Skill: `add-match-rule`.
Do: D-13 (commit), the base run, then D-12 and the branch run.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/shortlist/ ./core/database/promotealign/` passes with T-12; `CGO_ENABLED=1 go test -tags fts5 -run '^$' -bench BenchmarkLargeSourcePropose ./core/database/promotealign/` meets AC-4.3.

**STEP-10 — Swift reads the dating from the wire**
Files: `macos/App/Platform/GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift`; `macos/App/Features/Workspace/Session/EvidenceGraphSnapshot.swift`, `CatalogQueryRegistry.swift`; `macos/ProvenenciaTests/OnboardingModelTests.swift` (stub). Skill: `add-swift-test`.
Do: D-8, D-9 (Swift side): types, mapping, the graph titles map; `dateLine` not yet changed.
Check: `xcodebuild test` (the command `scripts/check-pr.sh` runs as `xcode-test`) builds and passes, no Swift warning.

**STEP-11 — Every line formats the dating**
Files: `macos/App/Platform/DateRowDisplay.swift`, `L10n.swift`, `Localizable.xcstrings`; `macos/App/Features/Conclusions/EventsListView.swift`, `EventDetailContent.swift` (line 72 only), `PersonTimelinePreviewData.swift`; `EvidenceGraphSnapshot.swift` `dateLine`; `macos/ProvenenciaTests/DateRowDisplayTests.swift`, `EventDetailTests.swift` (`dated` helper sets `dating`), `PersonsListTests.swift` (`eventsRowSecondLine` sets `dating`), `CatalogSearchTests.swift`, `EvidenceGraphSnapshotTests.swift` (`anEventsDateLineReadsItsDateObservations` deleted, T-15 replaces it), `PromoteModelTests.swift` (`aPlacedEventsRowCarriesItsDate` seeds `store.eventTitlesByGraph[graphID]` with a `CatalogSourceEventTitle` whose `dating` is `.occurrence`). Skills: `add-localized-string`, `add-ui-component`, `add-swift-test`.
Do: D-14, D-15; Strings from the board.
Check: `xcodebuild test` passes with T-13 – T-15 (the build fails on any caller left on the deleted `line(date:start:end:)`).

**STEP-12 — The lifeline marks open sides of a one-day span**
Files: `macos/App/Features/Conclusions/PersonTimelineLifeline.swift`, `PersonTimelineSection.swift`, `macos/ProvenenciaTests/PersonTimelineLifelineTests.swift`. Skill: `add-ui-component`.
Do: D-16 per the S16-D7 board's frames 18a – 18c (TL-1 – TL-3).
Check: `xcodebuild test` passes with T-16.

**STEP-13 — Docs**
Files: `docs/structured-date-model.md` § 3.4; `docs/matching-model.md` (the `MaxSamples` row: over the cap a side's as-ofs are read by nothing in matching — compare, shortlist presence aside, lifespan); `.agents/skills/add-date-value/SKILL.md` (a line: `valuecompare.DatingOf` is the one dating of an event or period; the engine sends it and Swift formats `CatalogEventDating`, never picking a key); `docs/deployment-plan/spike-16/completed.md`, `deployment-plan.md` (map row), this plan (status), `design/S16-D4-event-date-line.md` and `design/S16-D7-timeline-lifeline-dating.md` → `design/archive/`, `design/README.md`.
Do: § 3.4 says an event's dating comes from `valuecompare.DatingOf` (D-2 – D-4), sorts at its Low (else High), spans Low to High with open sides on the Timeline, and its drift note is closed; per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-42-event-dating-line.md` and links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/valuecompare/dating_test.go` `TestDatingOf` *(new)* | Table: `date` 14 May 1817 → Occurrence; unplaced date + start 1860 → Occurrence, Low the date; start 1985 + end 2015 → Span, closed both; start = end 1985 → Span, Low and High both 1985; start only → Span, High nil, OpenHigh; end only → Span, Low nil, OpenLow; as-ofs 1990, 2015 → AsOf 1990–2015 open both; one as-of → AsOf, High nil, open both; start 1985 + as-ofs 1990, 2015 → Low start closed, High 2015 open; as-of 1990 + end 2015 → open low, closed high; start 1995 + as-of 1990 → Low the as-of, OpenLow; as-of 2020 + end 2015 → AsOf, Low the as-of, High nil, open both (D-4: both sides are the same sample); as-of 1980 + end-only 2015 → Low as-of open, High end closed; `abt 1990` + `bef 2015` → Low abt 1990, High bef 2015; `bet 1985 and 1995` + 1990 → Low the range, High nil; as-ofs inside start 1980 and end 2020 → Span; a sample with year 10000 → skipped; each sample row also run reversed → the same dating; `1990` and `bet 1985 and 1990` (tied Hi) in both orders → the same Low | D-1 – D-4, AC-1.2 – AC-1.6, AC-2.1, AC-2.5 |
| T-2 | Go | `core/database/conclusionsummaries/conclusionsummaries_test.go` `TestEventDatingInSummaries` *(new)* | A fixture with the AC-1.1 residence and events dated 1989 and 1991 → `ListEvents` order 1989, residence, 1991; `h.Dating` Low/High; deleting the 2015 as-of Observation → High nil on the next read | AC-2.1, D-7 |
| T-3 | Go | `conclusionsummaries_test.go` `TestEventSpan`, `TestEventSpanDays` (rewritten rows) | AC-2.2 – AC-2.6 spans and days; occurrence rows unchanged | AC-2.2, AC-2.3, AC-2.4, AC-2.5, AC-2.6, D-5 |
| T-4 | Go | `conclusionsummaries_test.go` `TestEventAge` (new rows) | Born 1955, as-ofs 1990, 2015 → Age 34–60, Aged | AC-2.2, D-5 |
| T-5 | Go | `conclusionsummaries_test.go` `TestLifeIgnoresAsOf` *(new)* | Birth with start 1948 and as-of 1950 → birth 1948, places folded at 1948; birth with only an as-of → no birth date, places folded with no date | AC-2.7, D-7 |
| T-6 | Go | `conclusionsummaries_test.go` `TestEventDatingManyAsOfs` *(new)* | One event with 10,000 as-ofs → summary `Dating` Low and High set; compose under 50 ms on the test machine | AC-2.8, D-6 |
| T-7 | Go | `api/ffi/handlers/conclusion_summaries_test.go` `TestListEventSummaries` (new row) | An as-of event → `dating` kind AS_OF, low, high, open_low, open_high | D-8 |
| T-8 | Go | `core/database/persondetail/timeline_test.go` `TestPersonEventsLifeline` (new rows) | AC-2.2, AC-2.3 spans on a person's Timeline | AC-2.2, AC-2.3 |
| T-9 | Go | `core/database/grapheventtitles/grapheventtitles_test.go` `TestForEvidenceGraph` (new rows) | A graph Event Subject with two as-of Observations → `Title.Dating` AsOf 1990–2015; one with `date` → Occurrence | AC-1.7, D-9 |
| T-10 | Go | `core/database/searchindex/searchindex_test.go` `TestEventSecondaryIndexesDating` *(new)* | AC-1.1 residence → Secondary holds `10 Jan 1990` and `10 Feb 2015`; three as-ofs → middle year absent; `ProjectionVersion` is 12; a Person's alternate names still indexed | AC-3.1, AC-3.2, D-10 |
| T-11 | Go | `core/subjectcompare/pairs_test.go` `TestPeriodSamplesCap` *(new)* | 1,001 positive as-ofs → `CountSamples` 1,001, `PeriodSamples` nil; 1,000 → 1,000; negative values not counted | AC-4.4, D-11 |
| T-12 | Go | `core/shortlist/shortlist_test.go` `TestKeys` (new rows), `TestFind` (new rows) | As-of-only 1990/2015 lookup → closed reach keys + `wide`, no `any`; index unchanged (`wide`, `any`); meets 2000 and `aft 1970`, not 1881; a probe dated 1881 meets it; `bef 2015` alone → lookup `any`; 1,001 as-ofs → open reach both ways | AC-4.1, AC-4.2, AC-4.4, D-12 |
| T-17 | Go | `core/database/promotealign/bench_test.go` `BenchmarkLargeSourcePropose` (`asof=0`, `asof=0.3` rows) | 4,000 and 16,000 persons → reported, not gated; AC-4.3 read from base and branch runs | AC-4.3, D-13 |
| T-13 | Swift | `macos/ProvenenciaTests/DateRowDisplayTests.swift` (new tests) | Each AC-1.6 shape through `line(dating:)` equals its literal planning-base string; `en_US`: `as of 10 Jan 1990–10 Feb 2015`, `as of 10 Jan 1990`, `from 1985, as of 10 Feb 2015`, `as of 1990, until 2015`, `as of abt 1990–bef 2015`, a lone range as-of → `as of bet 1985 and 1995`; `span(start:end:)` equals today's start–end strings | AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, D-14 |
| T-14 | Swift | `EventDetailTests.swift`, `CatalogSearchTests.swift` (new tests) | The header line and a search hit's second line for an as-of summary show the T-13 string | AC-1.1, AC-3.1 |
| T-15 | Swift | `EvidenceGraphSnapshotTests.swift` (new test) | A placed Event Subject with `eventDating` AsOf → `dateLine` the T-13 string, with no date Observations on it | AC-1.7, D-9 |
| T-16 | Swift | `PersonTimelineLifelineTests.swift` (new tests) | A one-day span open both sides → `.bar` of 32 pt (`openDayLength`) centred on the day, `pointY` at its middle; a one-day `bef` span → the same bar shape; a both-open bar → `pointY` at its middle; a closed one-day span → `.dot` | AC-2.6, D-16 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `conclusionsummaries` order and span tests, `persondetail` Timeline tests, the graphalign goldens, `EvidenceGraphSnapshotTests`, `PromoteFlowTests`, `PersonsListTests`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: `rg -n 'eventWhen|eventDating\(|func eventDate\(' core` finds nothing; `rg -n 'Periods\[' core --glob '!*_test.go'` finds only `Rules.Period`; `rg -n 'vocabkey\.Property(StartDate|EndDate|AsOf)' core/database/conclusionsummaries core/database/grapheventtitles --glob '!*_test.go'` finds nothing; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches the brief inventory; no new kit primitive; no new lifeline Shape case
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] AC-4.3 benchmark rows (base and branch, both shares, both sizes) and the warm-ms cause in the PR body
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Both briefs (S16-D4, S16-D7) moved to design/archive/ and design/README.md updated
- [ ] Domain docs and guidance updated: structured-date-model.md § 3.4, matching-model.md MaxSamples row, add-date-value skill, grapheventtitles package doc, CatalogEventSummary doc comment
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Create a new project. Add a Source "Obituary of A. Smith 1990" with a residence Event for X in Town Y, **As of** 10 Jan 1990; a Source "City directory 2015" with X's residence in Town Y, **As of** 10 Feb 2015; promote both to one Event.
2. Events list: the residence shows `as of 10 Jan 1990–10 Feb 2015` and sits between events dated 1989 and 1991. Open it: the header line is the same (the Date row is S16-44's).
3. Open X's Person page, Timeline: the residence row shows the line; the lifeline bar spans 1990–2015 faded at both ends. Add `start_date` 1985 on another Source and promote: the left end closes.
4. Add a residence with only As of 10 Jan 1990: the 32 pt bar faded at both ends, and `as of 10 Jan 1990`.
5. Search "1990": the residence is a hit with the same line. Promote a third Source's residence: the candidate menu and the record row show the line.
6. On the dogfood project (no `as_of`), compare the Events list's date column before and after: identical; a start-and-end residence now spans its years on the lifeline.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| An occurrence or span line changes by a character | T-13 compares with literal planning-base strings on every AC-1.6 shape |
| Matching goldens move through D-7 or D-11 | No golden has more than 1,000 samples; `EventPeriod` returns the same period; STEP-2 and STEP-8 run them |
| D-12 loses Promote pairs a researcher expects | AC-4.2 keeps the dated side's recall; the lost pairs are named in D-12 |
| The S16-D7 board picks a one-day mark `.bar` cannot draw | Stop condition below |
| `protoc` or `xcodebuild` is missing where the implementer runs | The PR says which checks ran where; CI runs `xcode-test` and the generated files' check |

**Stop and report if:**

- `eventDating`, `oneEvent`, `eventPlaces`, `EventSpanAndAge`, `eventMatchSecondary` or the lifeline's `point` no longer do what §4 says.
- Any AC-1.6 line differs from the planning-base string.
- A matching golden changes in STEP-2, STEP-8 or STEP-9.
- AC-4.3 is not met (the branch's median `asof=0.3` overhead is higher than the base's by more than the runs' spread): report all runs; do not tune other knobs.
- T-6 exceeds 50 ms, or the compose reads the as-ofs more than once.
- The S16-D7 board's TL-2 mark is not a `.bar` with faded sides (it would need a new `Shape` case).
- `matchregistry` cannot be imported from `conclusionsummaries` or `grapheventtitles` without a cycle.

## 12. Open questions

None.

## 13. PR

**Title:** S16-42 — Every event date line reads the engine's dating
**Body:** objective in one sentence; what shipped against US-1 – US-4; AC evidence (test names, the AC-4.3 benchmark table, the warm-ms cause); deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-42-event-dating-line.md`.
