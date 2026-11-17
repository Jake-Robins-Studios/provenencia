# S16-42 — Every event date line reads the engine's dating

**Status:** Blocked — on board S16-D4
**Spike / slice:** Spike 16 · Batch 5 · Slice 5a — An attestation is a sample
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S16-D4](../design/S16-D4-event-date-line.md), board not agreed yet (the shared event date line on an Events list row, and the Timeline lifeline: ED-1 – ED-9, ED-W1)
**Board:** not drawn yet. When agreed: the Claude Design artifact link, the turn "S16-D4 · Event dates", its frames, the ED-2 – ED-5 wording and the ED-8 mark go here; the implementer reads it with the Artifact tool's `read` on that link
**Depends on:** S16-40 (landed [#869](https://github.com/mendahu/provenencia/pull/869)), S16-D4
**Blocks:** S16-44
**Branch:** `s16-42-event-dating-line`
**Version bump:** minor — the next minor after `VERSION` on `main` when the branch is cut (0.18.0 → 0.19.0 at the planning base): additive wire fields (`EventSummary.dating`, `SourceEventTitle.dating`) and a change a researcher sees on every event date line ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-date-value`](../../../../.agents/skills/add-date-value/SKILL.md), [`add-match-rule`](../../../../.agents/skills/add-match-rule/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-searchable-kind`](../../../../.agents/skills/add-searchable-kind/SKILL.md), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`
**Context:** [`event-as-of.md` § The dating envelope](../event-as-of.md#the-dating-envelope), [`structured-date-model.md` § 3.4](../../../structured-date-model.md#34-the-display-date-of-an-event), working rules (Batch 5): "One dating, in Go, derived on read", "The engine sends the dating, not the as-ofs", "As-ofs alone make a span open on both sides", "A closed as-of counts toward the person's lifespan; it never dates a birth or a death"; S16-40 plan D-6 and D-9, [S16-40 ship log](S16-40-event-as-of-property.ship.md) SEC-3 and PRF-1
**Planned:** 2026-11-17 against `main` @ `dbc946c`
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

An event dated only by its **As of** dates (S16-40) shows no date anywhere today and sorts last. After this PR the engine gives every event one dating — an occurrence, a span, or an as-of span with its open sides — and every event date line, the Events list order, the Timeline's lifeline, place folding and search read it. A residence known from an obituary of 10 Jan 1990 and a directory of 10 Feb 2015 reads from 10 Jan 1990 to 10 Feb 2015, open on both sides, sorts at 10 Jan 1990, and spans 1990 to 2015 on the lifeline (dogfood bar 18 except the Event page Date row, and bar 19).

**Why now.** S16-40 records as-ofs and matches them; until this PR a researcher who records one sees the event undated. The map review moved every `eventDating` reader here (K-2) and made the engine send the dating (K-3).

**What stays.** Every line for an event with a `date`, a start and an end, a start alone or an end alone reads as today (ED-1). A birth or a death is never dated by an as-of (`lifeFrom`). The Event page's Date row is S16-44's. Nothing writes `start_date` or `end_date`. The Timeline now also draws a start-and-end event across its whole span and a start-only or end-only event open on its missing side, and an end-only event sorts at its end (user, 2026-11-17: one rule for all).

## 2. User stories

**US-1.** As a researcher, when an event is dated only by as-ofs, I see its dating on every date line so that I know when it was under way.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A residence with as-ofs 10 Jan 1990 and 10 Feb 2015 | Events list row, Event page header line, Timeline row, search hit and Promote's candidate menu show the ED-2 line (board wording) for 10 Jan 1990 – 10 Feb 2015, open both sides |
| AC-1.2 | A residence with one as-of 10 Jan 1990 | The ED-3 line; never the bare `10 Jan 1990` an occurrence shows |
| AC-1.3 | `start_date` 1985, as-ofs 10 Jan 1990 and 10 Feb 2015 | The ED-4 line: closed at 1985, open after 10 Feb 2015 |
| AC-1.4 | As-of 1990, `end_date` 2015 | The ED-5 line: open before 1990, closed at 2015 |
| AC-1.5 | As-ofs `abt 1990`, `bef 2015` | Each keeps its qualifier inside the ED-2 line (ED-6) |
| AC-1.6 | An event with `date` 14 May 1817; one with start 1985 and end 2015; one with start 1985 only; one with end 2015 only | `14 May 1817`; `1985–2015`; `1985`; `2015`: the same strings as at the planning base |
| AC-1.7 | A promoted residence whose Source graph has the two as-of Observations | Promote's record row for that Subject shows the AC-1.1 line (from the engine, not from Swift reading Observations) |

**US-2.** As a researcher, I see an as-of event in date order and on my person's lifeline.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Events list with events dated 1989, as-of-only 10 Jan 1990 – 10 Feb 2015, and 1991 | Order: 1989, the residence, 1991 |
| AC-2.2 | Person born 1955, residence with as-ofs 1990 and 2015 | Timeline span From 1990 To 2016, OpenStart and OpenEnd true; age 34–60 |
| AC-2.3 | The same residence with `start_date` 1985 | Span From 1985 To 2016, OpenStart false, OpenEnd true |
| AC-2.4 | A residence with start 1960 and end 1970 | Span From 1960 To 1971, both closed (today: 1960 to 1961) |
| AC-2.5 | An occupation with start 1975 only; one with end 1980 only | Span 1975–1976 OpenEnd true; span 1980–1981 OpenStart true, and the end-only event sorts at 1980 (today: undated, last) |
| AC-2.6 | One as-of 10 Jan 1990 | A one-day span with both sides open; the lifeline draws the ED-8 mark, not a dot |
| AC-2.7 | A person whose birth event has only an as-of 1950 and a start 1948 | The person's birth reads 1948 (start), never the as-of; a birth event with only an as-of reads no birth date |
| AC-2.8 | An event with 10,000 as-ofs | The summary carries two dates; the Events list row builds from them; the compose reads each as-of once (bounded, T-6) |

**US-3.** As a researcher, I find an as-of event by its years in search.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Search "1990" with the AC-1.1 residence in the catalog | The residence is a hit; its second line is the AC-1.1 line |
| AC-3.2 | Search "2003" for a residence with as-ofs 1990, 2003 and 2015 | No hit from the as-of 2003: only the dating's two dates are indexed |

**US-4.** As the engine, Promote's shortlist stays bounded and narrower for as-of-only events (S16-40 PRF-1), and no read copies 10,000 crafted as-ofs (S16-40 SEC-3).

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | An as-of-only residence (as-ofs 1990, 2015) probes the shortlist | Its lookup keys are the closed reach of its samples' years plus `wide`; it meets a residence dated 2000, an open (AFT 1970) one, and not one dated 1881 |
| AC-4.2 | A residence dated 1881 probes | It still meets the as-of-only residence (its index keys stay one open reach) |
| AC-4.3 | `BenchmarkLargeSourcePropose` at 4,000 and 16,000 persons, `asof=0.3` | Warm proposal within 3% of `asof=0` on the same machine (S16-40 measured +7%); numbers and the `warm-ms` +3.5 ms cause in the PR body |
| AC-4.4 | A Subject with 1,001 positive as-ofs (above `MaxSamples` 1,000) | `subjectcompare.PeriodSamples` returns nil without copying; compare, the shortlist and the lifespan read none of them |

## 3. Scope

| In | Covered by |
| --- | --- |
| `valuecompare.EventDating` *(new)* (the one dating, D-1 – D-6) | STEP-1, AC-1.*, AC-2.* |
| `conclusionsummaries`: `EventSummary.Dating`; `eventKeyOf`, `EventSpanAndAge`, `eventWhen` read it; `lifeFrom` keeps `date` or start (D-7) | STEP-2, AC-2.1 – AC-2.7 |
| Wire: `EventDating` on `EventSummary` and `SourceEventTitle`; `CatalogEventDating` in Swift (D-8) | STEP-3, STEP-4 |
| `grapheventtitles` dates each graph Event Subject (D-9) | STEP-4, AC-1.7 |
| `searchindex` indexes the dating; `ProjectionVersion` 12; dead date keys leave `sqlHandleValues` (D-10) | STEP-5, AC-3.* |
| SEC-3: `PeriodSamples` counts before it copies (D-11) | STEP-6, AC-4.4 |
| PRF-1: narrower shortlist lookup for as-of-only events, with the benchmark (D-12, D-13) | STEP-7, AC-4.1 – AC-4.3 |
| `DateRowDisplay.line(dating:)` formats the dating on every `EventSecondaryDisplay` surface and on `EvidenceGraphSnapshot.dateLine` (ED-1 – ED-6, ED-9, ED-W1) | STEP-8, AC-1.* |
| The lifeline's one-day open mark and a both-open bar's tether (ED-7, ED-8) | STEP-9, AC-2.6 |
| `structured-date-model.md` § 3.4 rewritten; its drift note closed; `event-as-of.md` table row | STEP-10 |

| Out | Home |
| --- | --- |
| The Event page Date row (`EventDetailContent.dateRow`) | S16-44 |
| A notice for an as-of outside the start or end | [`ideas/event-as-of-followups.md`](../../../ideas/event-as-of-followups.md) |
| Removing `EventSummary.Date`, `StartDate`, `EndDate` from the wire | S16-44 decides once the Date row reads the dating (it reads them today) |
| Indexing every as-of year in search | not planned (AC-3.2: the line's two dates are what the row shows) |
| Narrowing the as-of-only event's **index** keys | not planned (D-12: it would drop pairs probed from the dated side) |
| A Place's as-of | [`ideas/event-as-of-followups.md`](../../../ideas/event-as-of-followups.md) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Event dating chooser | `core/database/conclusionsummaries/order.go` `eventDated`, `eventDating`, `datePlace` | Placed `date`, else placed start, else unplaced date, else start; ignores `end_date` and as-ofs; `eventDated` carries key, span, ends |
| Its readers | `compose.go` `eventDate`, `lifeFrom`, `eventWhen`, `eventKeyOf`; `order.go` `EventSpanAndAge` | Sort, Timeline span and age, place folding, birth and death all read `eventDating` |
| Summary compose | `compose.go` `oneEvent`, `keptDateAt` | Reads rank-1 `date`, `start_date`, `end_date`; clears start and end when `date` is set. Never reads `as_of` |
| Summary type | `core/database/conclusionsummaries/events.go` `EventSummary` | `Date`, `StartDate`, `EndDate` and counts; no dating |
| Timeline | `core/database/persondetail/timeline.go` (`EventSpanAndAge` at line 148); `api/ffi/handlers/person_detail.go` line 297 | Span and age from `EventSpanAndAge`; open flags reach Swift `CatalogTimelineSpan` |
| Display helpers | `core/valuecompare/datewindow.go` `DateEnds`, `SampleExtremes`, `EndsWindow`; `dateorder.go` `DateKeyOf`, `DateKey.Compare` | S16-40 added `SampleExtremes`, documented as the selection this PR reuses |
| Samples key | `core/matchregistry/subject.go` `Periods[Event][date]` (`Start`, `End`, `Samples: as_of`, `MaxSamples: 1000`) | The one place the four date keys are named |
| SEC-3 | `core/subjectcompare/pairs.go` `PeriodSamples`, `samplesAgainst` | Copies every positive sample, then `samplesAgainst` checks `len > MaxSamples` |
| PRF-1 | `core/shortlist/shortlist.go` `Keys` lines 96–135 | An as-of-only event is one open reach: index `wide`+`any`, lookup `any` (meets every event of its type) |
| Wire | `api/proto/engine.proto` `EventSummary` (fields 1–18), `SourceEventTitle` (1–2), `TimelineSpan`; `api/ffi/handlers/conclusion_summaries.go` `eventSummaryProto`; `api/ffi/handlers/event_titles.go` `ListEvidenceGraphEventTitles` | No dating |
| Graph titles | `core/database/grapheventtitles/grapheventtitles.go` `FromStored`, `Title` | Titles each Event Subject from its graph's Observations; no dates |
| Search | `core/database/searchindex/handles.go` `sqlHandleValues`, `loadHandleValues`, `eventMatchSecondary`; `searchindex.go` `ProjectionVersion = 11` | `eventMatchSecondary` indexes `CompactDisplay` of `Date`, `StartDate`, `EndDate`; `sqlHandleValues` loads `date`, `start_date`, `end_date` that `matchText` never reads (only `name`, `toponym`) |
| Swift line | `macos/App/Platform/DateRowDisplay.swift` `line(date:start:end:)`; `macos/App/Features/Conclusions/EventsListView.swift` `EventSecondaryDisplay.content` | Swift chooses date over start–end. `content` serves the Events list, `EventDetailContent` header (line 31), `PersonTimelineContent` (line 368), `ConclusionSummaryDisplay.secondary` (search hits, `PromoteFlow` line 555) |
| Swift graph line | `macos/App/Features/Workspace/Session/EvidenceGraphSnapshot.swift` `EvidenceGraphPlacedSubject.dateLine` | Reads the first asserted `date`, `start_date`, `end_date` Observations itself; read by `PromoteModel.subjectFacts` |
| Swift graph titles | `GoStore.listEvidenceGraphEventTitles`, `GenealogyStore`, `FakeStore` (`eventTitlesByGraph`), `CatalogQueryRegistry` line 252, `EvidenceGraphSnapshot.eventTitles`; `OnboardingModelTests.swift` line 620 stub | `[String: CatalogEventTitle]` |
| Lifeline | `macos/App/Features/Conclusions/PersonTimelineLifeline.swift` `point(_:_:stubsBefore:)`, `Mark.pointY`; drawing `PersonTimelineSection.swift` line 538 | A span of a day or less is a `.dot` (open flags dropped); a bar open at both ends tethers 8 pt in from `to` |
| Tests | `conclusionsummaries_test.go` `TestEventSpan`, `TestEventSpanDays`, `TestEventOrderAtKnownEnd`, `TestEventAge`, `TestListEvents`; `core/database/persondetail/timeline_test.go` `TestPersonEventsLifeline`; `searchindex_test.go`; `grapheventtitles_test.go` `TestForEvidenceGraph`; `shortlist_test.go` `TestKeys`; `subjectcompare` pairs tests; `core/valuecompare/datewindow_test.go` `TestSampleExtremes`; Swift `DateRowDisplayTests`, `EventDetailTests`, `EvidenceGraphSnapshotTests`, `PersonTimelineLifelineTests`, `CatalogSearchTests` | `TestEventSpan` pins "start date only" (closed), "end date only" (undated) and "date with no year, dated start" (1860), which D-4 and D-5 change |

**Precedent.** S16-40 ([#869](https://github.com/mendahu/provenencia/pull/869)) added `SampleExtremes` beside `Earliest`/`Latest` and read the samples key from `subject.Periods`: copy that placement and that registry read. For wire on a graph Subject, copy how `ListEvidenceGraphEventTitles` sends Go's title per Event Subject (S9 R4): one field more on `SourceEventTitle`, not a new RPC. For a `ProjectionVersion` bump with its comment line, copy S14-40's 11.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `valuecompare.EventDating(date, start, end *datevalue.Value, samples []datevalue.Value) Dating` in `core/valuecompare/dating.go` *(new)*. `Dating{Kind DatingKind; Low, High *datevalue.Value; OpenLow, OpenHigh bool; Key DateKey; Placed bool; First, Last DateEnd}`; `DatingKind` is `DatingNone`, `DatingOccurrence`, `DatingSpan`, `DatingAsOf`. Pure; no Property keys | Working rule "One dating": one pure helper in `valuecompare`, typed on date slices | A method on `EventSummary` — `grapheventtitles` needs it without a summary; a Swift copy — rule K-3 |
| D-2 | **Occurrence.** A non-nil `date` gives `DatingOccurrence`, `Low = date`, `High = nil`, open flags false; `Placed`, `Key`, `First`, `Last` from `DateKeyOf(*date)` (unplaced → `Placed` false). Start, end and samples are not read | The line already shows a recorded `date` whenever one is set, and `oneEvent` already clears start and end then, so list order and the Timeline already treat an unplaced `date` as undated: this closes `structured-date-model.md` § 3.4's drift note without changing a list | Placed date else placed start (today's `eventDating`) — the line and the order would keep disagreeing |
| D-3 | **Samples.** Each sample is read once with `DateEnds` (the as-written reading; About not widened); one whose read is not ok or has both ends open is skipped. `SampleExtremes(firsts, lasts)` gives `endsFirst` (low pick) and `startsLast` (high pick); when one is -1 it takes the other. Ties: the lower index (kept rank order) | The map names `SampleExtremes` with `DateEnds`; the sample that ends first is the tightest "started by", the one that starts last the tightest "still under way" (the window rule) | `Earliest`/`Latest` over all ends — a 1985–1995 range beside 1990 would date 1985–1995 though the event is only known under way in 1990 |
| D-4 | **Span and as-of.** Low = the earlier, by `DateKey.Compare`, of a placed start and the low pick; a tie goes to the start. High = the later of a placed end and the high pick; a tie goes to the end. `OpenLow` is true unless Low is the start; `OpenHigh` unless High is the end. `Kind` is `DatingAsOf` when either side came from a sample, else `DatingSpan`. `High` is nil when it is the same value as Low (one sample, or a start alone). With no placed start, end or sample: an unplaced start or end gives `DatingSpan` with them as Low and High, unplaced; nothing gives `DatingNone`. `Key` is Low's `DateKeyOf`, else High's; `First` is Low's first end (else High's), `Last` is High's last end (else Low's) | Design table in `event-as-of.md`; rule "a start or an end closes that side"; user 2026-11-17: one rule for all (an end-only event sorts at its end) | Start wins over an earlier as-of — would hide the as-of the researcher recorded; the contradiction notice is the idea file's |
| D-5 | **Timeline span** *(`order.go` `datingSpan(d valuecompare.Dating) (TimelineSpan, bool)`, new, replacing `eventDated`'s span)*: From is Low's `datePlace` span From (High's when Low is nil or unplaced); To is High's span To (Low's when High is nil); `OpenStart = OpenLow || that span's OpenStart`, `OpenEnd = OpenHigh || that span's OpenEnd`. An occurrence keeps `datePlace(date).span` exactly. `Days = EndsWindow(First, Last)`. **Age** reads `First` and `Last` as `EventSpanAndAge` reads `ev.first` / `ev.last` today: the dating's open sides do not open the age, only a date's own open end does | User 2026-11-17 (whole span, open on a missing side). The person was alive on each known day, so the age over the known span is true | Opening the age on an open side — an as-of residence would never show an age |
| D-6 | No sample cap in `EventDating`: every kept as-of is read once. The summary is composed once per change of the node and cached (`SetDisplay`) | Map Scale (Batch 5): "the dating read two extremes after one pass"; a cap would date a crafted event differently from a real one | `MaxSamples` here — a crafted event would read undated while matching says it is not read; two rules |
| D-7 | `conclusionsummaries`: `EventSummary.Dating valuecompare.Dating` *(new field)* set in `oneEvent` before start and end are cleared, from rank-1 `date`, `start_date`, `end_date` (`keptDateAt`) and every kept `as_of` (`keptDates`, new). The four keys come from `eventPeriod` *(new package var)* `= matchregistry.Default().Subject.Periods[vocabkey.Event][vocabkey.PropertyDate]` (lead `vocabkey.PropertyDate`). `eventKeyOf` reads `h.Dating.Key`/`Placed`; `EventSpanAndAge` reads `h.Dating` through D-5; `eventWhen` folds at `Low`, else `High`, from `EventDating` on the node. `lifeFrom` keeps its chooser: `eventDating` and `eventDate` become `lifeDating` / `lifeDate` (date when placed, else start when placed, else date, else start; no span or ends); `eventDated` loses `span`, `first`, `last` | Working rules: four keys from `subject.Periods`; a birth or death never dated by an as-of | A hand list of keys — rule; deleting `lifeFrom`'s chooser for `EventDating` — a birth with an as-of would be dated by it |
| D-8 | Wire: `message EventDating { EventDatingKind kind = 1; DateValueInput low = 2; DateValueInput high = 3; bool open_low = 4; bool open_high = 5; }`; `enum EventDatingKind { EVENT_DATING_KIND_UNSPECIFIED = 0; EVENT_DATING_KIND_OCCURRENCE = 1; EVENT_DATING_KIND_SPAN = 2; EVENT_DATING_KIND_AS_OF = 3; }` (UNSPECIFIED is none); `EventSummary.dating = 19`; `SourceEventTitle.dating = 3`. Go `eventDatingProto(d valuecompare.Dating) *engine.EventDating` *(new, `conclusion_summaries.go`)*. Swift `struct CatalogEventDating: Sendable, Equatable { enum Kind { case none, occurrence, span, asOf }; var kind; var low, high: CatalogDateValueInput?; var openLow, openHigh: Bool }` *(new, `GenealogyStore.swift`)*, `CatalogEventSummary.dating` defaults to `.none`-kind; `GoStore.mapEventDating` *(new)*. `Key`, `Placed`, `First`, `Last` stay in Go | Rule K-3: kind, two dates, open sides | Sending as-ofs — rule; sending the order key — the list already gets `ListKey` |
| D-9 | `grapheventtitles.Title` gains `Dating valuecompare.Dating`. `FromStored` collects, per Event Subject, the first positive `date`, `start_date` and `end_date` Observation in `eg.Observations` order and every positive `as_of` (`valuecodec.UnmarshalDate` of `o.Date`; one that fails is skipped), the four keys from `matchregistry`'s period as in D-7, and calls `EventDating`. Swift: the store method keeps its name and returns `[String: CatalogSourceEventTitle]` *(new: `title`, `dating`)*; `EvidenceGraphRows` / `EvidenceGraphSnapshot.eventTitles` carry it; `EvidenceGraphPlacedSubject` gains `eventDating: CatalogEventDating?`; `dateLine` is `DateRowDisplay.line(dating:includesPhrase: false)` over it | Rule K-3 names `EvidenceGraphSnapshot.dateLine`; the titles read already carries per-Subject engine facts | A new RPC — one more round trip per graph; Swift reading as-of Observations — rule |
| D-10 | Search: `eventMatchSecondary` indexes `CompactDisplay` of `h.Dating.Low` and `h.Dating.High` (not `Date`, `StartDate`, `EndDate`). `sqlHandleValues` drops `'date', 'start_date', 'end_date'` from its `IN` list (no document reads them). `ProjectionVersion = 12` with the comment line "12: an Event's dating, as-ofs included (S16-42)" | An Event's search text follows its line; a bump heals catalogs created since S16-40 | Adding `as_of` to `sqlHandleValues` — those values are never read |
| D-11 | SEC-3: `PeriodSamples` counts `v[p.Samples]`'s positive values first and returns nil when there are none or more than `p.MaxSamples`; only then it copies. `samplesAgainst`'s own `len(samples) > p.MaxSamples` check goes. Over the cap a side's as-ofs are read by nothing in matching (compare, shortlist, lifespan), as the knob's comment already says | Count before copy, the follow-up's fix; one place holds the cap | A second counting helper — two readings of one cap |
| D-12 | PRF-1: in `shortlist.Keys`, an as-of-only event (no positive date or stand-in, samples present) keeps today's **index** keys (one open reach: `wide`, `any`), and its **lookup** keys become a closed reach: lo the lowest and hi the highest closed `YearReach` bound over its samples (one pass), emitted as a closed probe's lookup (`wide` plus the buckets). When no sample has a closed reach or the reach exceeds `MaxBuckets`, the lookup stays `any` (today). Implemented by giving the existing `reach` struct separate index and lookup openness, no second branch | An as-of-only probe stops meeting every event of its type; a dated probe still meets it through `wide` (AC-4.2), so the pairs S16-40 D-9 protected are kept from that side. The pairs lost: an as-of-only Source event probing a catalog event whose own date reach lies wholly outside its samples' years; a closed period there conflicts anyway; an occurrence there compares unknown on date | Narrowing the index too — drops D-9's pairs from both sides; samples' years ±`MaxYears` — exceeds `MaxBuckets` and gives the same keys (S16-40 verifier) |
| D-13 | Benchmark: `catalogShape` gains `AsOfShare float64` *(new)*: each town death `j` with `Rand.Float64() < AsOfShare` writes its date on `as_of` instead of `date`. `newLargeFixture(t, persons)` stays and calls `newLargeFixtureAsOf(t, persons, 0)` *(new)*; `BenchmarkLargeSourcePropose` runs `persons=4000,16000` × `asof=0,0.3`. The PR body records both rows before (at the planning base, with the share patched in) and after, and the cause of S16-40's flat +3.5 ms `warm-ms` | Map scope: measured at 4,000 and 16,000 with 30% as-of deaths | A one-off scratch patch — not repeatable |
| D-14 | Swift: `DateRowDisplay.line(dating: CatalogEventDating, includesPhrase: Bool = true, locale:)` *(new)*. `.occurrence` → today's `rowDate(low)`; `.span` → today's `line(date: nil, start: low, end: high)`; `.asOf` → the board's ED-2 – ED-5 wording over `rowDate(low)` and `rowDate(high)` with `openLow` / `openHigh`; `.none` → "". `EventSecondaryDisplay.content` and `dateLine` call it. `line(date:start:end:)` stays for its other callers (`EventDetailContent.dateRow` until S16-44, `PersonLifeDisplay`, `SourcesRowDate`, `SourceDateDialog`, `ReconciledValueDisplay`) | One formatter; the occurrence and span text cannot drift from today because they call today's code | A second formatter type — the brief's inventory extends `DateRowDisplay` |
| D-15 | Tests, previews and `FakeStore` that build a `CatalogEventSummary` with dates set its `dating` explicitly with the memberwise initializer; no Swift helper derives a dating from date fields | Rule K-3: Swift never decides which key dates an event | A `CatalogEventDating(date:start:end:)` convenience — a Swift copy of D-2/D-4 |
| D-16 | Lifeline: a span whose `to - from` is a day or less and which has an open side is drawn as the board's ED-8 mark (not `.dot`); a `.bar` open at both ends tethers at its middle (`Mark.pointY`). Everything else draws as today | Brief ED-7, ED-8; user 2026-11-17 (the board decides the one-day mark) | Keeping the dot — the open sides would not show |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `valuecompare.EventDating`, `Dating`, `DatingKind` *(new, `dating.go`)* | func, types | `conclusionsummaries.eventDating` / `eventDated` | Lives in a database package and knows no end or sample; the rule wants it pure in `valuecompare`; `eventDating` shrinks to `lifeDating` |
| `conclusionsummaries.datingSpan` *(new)* | func | `datePlace` | Builds on `datePlace` for each side; `datePlace` stays for births |
| `conclusionsummaries.keptDates` *(new)* | func | `keptDateAt` | `keptDateAt` reads rank 1 only |
| `conclusionsummaries.eventPeriod` *(new var)* | var | `searchindex.productRules` (package var from a registry) | Same pattern |
| `EventDating`, `EventDatingKind` *(new proto)*; `eventDatingProto` *(new)* | message, func | `TimelineSpan`, `eventTitleProto` | A different fact |
| `CatalogEventDating`, `CatalogSourceEventTitle` *(new Swift)*; `GoStore.mapEventDating` *(new)* | struct, func | `CatalogTimelineSpan`, `CatalogEventTitle` | Mirror the wire |
| `DateRowDisplay.line(dating:)` *(new overload)* | func | `DateRowDisplay.line(date:start:end:)` | Extends the same type; calls its private `rowDate` |
| `catalogShape.AsOfShare`, `newLargeFixtureAsOf` *(new, tests)* | test helper | `newLargeFixture` | Adds one knob to the existing fixture |
| L10n `Dates` as-of keys *(new)* | key | `L10n.Dates.rowSpan` | Wording set by the board (§ Strings) |

**Builds on.** `valuecompare.SampleExtremes` and `DateEnds` (S16-40); `matchregistry` `Periods` (rule); `ListEvidenceGraphEventTitles` (wire per graph Subject); `PVDatePlaceLine` and `EventSecondaryLine` unchanged; the lifeline's open-side fade.
**Deletes.** `eventDated`'s `span`, `first`, `last` fields and `eventDating`'s Timeline use (renamed `lifeDating`, D-7); `EvidenceGraphPlacedSubject.dateLine`'s Observation reading; `sqlHandleValues`' three date keys; `samplesAgainst`'s `MaxSamples` check (D-11); `TestEventSpan`'s cases that pinned the old start-only / end-only / unplaced-date rule are rewritten, not kept.
**Next adds.** S16-44's Date row branches on `summary.dating.kind` instead of `SeededPropertyKey.date` / `.startDate` / `.endDate`; once it lands, `EventSummary.StartDate`, `EndDate` on the wire may have no reader (S16-44 decides). A Place's as-of ([idea](../../../ideas/event-as-of-followups.md)) calls `EventDating` with its period.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| An event dated only by as-ofs | Events list, Timeline, search, Promote menus and rows | Dated and sorted from its dating (D-4); line per board |
| An end-only event now dated | Events list order, Timeline | Sorts at its end; drawn open before (D-4, D-5) |
| A one-day span with open sides | `PersonTimelineLifeline.point` | ED-8 mark (D-16); click target as a dot's |
| A catalog with no `as_of` Property (created before S16-40) | `oneEvent`, `FromStored` | `v.prop` returns nil, `Node.Kept(nil)` returns none: no samples, today's dating |
| A graph Subject with no date Observations | `dateLine` | `.none` → "" as today |

### Scale

At the map's Scale (Batch 5): an event with up to 20 as-ofs on a person with 200 events: `oneEvent` unmarshals 20 extra dates once per change of the node (cached display), `SampleExtremes` one pass; the Timeline reads `h.Dating`, no extra work per row. Crafted: 10,000 as-ofs on one event → 10,000 unmarshals and two `DateEnd` slices of 10,000 in one compose (T-6 measures it under 50 ms and asserts the summary holds two dates); the wire carries two dates. Graph titles: per graph Subject, its own Observations (one pass over `eg.Observations`, as today). Search: two `CompactDisplay` per event. Shortlist (Batch 2 Scale, D-13): the lookup of an as-of-only probe goes from every event of its type to its sample years' buckets plus `wide`. `PeriodSamples` over the cap counts without copying (AC-4.4).

### Edges

- **Assumptions.** `ListKey` sorting assumes one key per row: `Dating.Key` is computed once in compose (T-2). `SampleExtremes` breaks ties by index: kept rows come in rank order, so the dating is stable across reads (T-1 "order" rows). `datePlace` assumes a placeable date: `datingSpan` only places `Placed` sides.
- **Neighbors.** `date` with no year beside a placed start: undated in order and on the Timeline (D-2; the summary already behaves so); `TestEventSpan`'s "date with no year, dated start" changes to undated. Start only → open end; end only → dated at its end, open start (user 2026-11-17). An as-of equal to the start → the start (closed). An as-of after the end → High is the as-of, open (contradiction, Out notice). A range as-of `bet 1985 and 1995` alone → Low = High = that range, open both sides; beside 1990 → 1990 only (D-3).
- **Removed inputs.** A deleted as-of Observation re-keeps the node's values; the next compose redates (the cached display is per node, dropped on its change as today; T-2 "edit" row). An as-of excluded by the reconciler is not kept and not read.
- **Real data.** The dogfood project has no `as_of` (new catalogs only); its event lines must be byte-identical before and after for every event with a date, start or end (T-8 runs the Swift formatter over each AC-1.6 shape; the manual check compares the Events list of the dogfood project before and after).
- **Untrusted size.** As-ofs per event: unbounded on read, one linear pass (D-6), two dates sent. Per graph Subject as-of Observations: one pass. `PeriodSamples`: counted before copy, cap 1,000 (D-11).

### Schema

None — no catalog change. `as_of` is seeded by S16-40.

### Go core

| Package | Change |
| --- | --- |
| `core/valuecompare` | `core/valuecompare/dating.go` *(new)*: D-1 – D-4 |
| `core/database/conclusionsummaries` | `events.go` `EventSummary.Dating`; `compose.go` `oneEvent`, `keptDates`, `eventWhen`, `lifeFrom` / `lifeDate`; `order.go` `eventKeyOf`, `EventSpanAndAge`, `datingSpan`, `lifeDating`; `eventPeriod` (D-5, D-7) |
| `core/database/grapheventtitles` | `Title.Dating`; `FromStored` (D-9) |
| `core/database/searchindex` | `handles.go` `sqlHandleValues`, `eventMatchSecondary`; `searchindex.go` `ProjectionVersion` (D-10) |
| `core/subjectcompare` | `pairs.go` `PeriodSamples`, `samplesAgainst` (D-11) |
| `core/shortlist` | `shortlist.go` `Keys` (D-12) |
| `core/database/promotealign` | `bench_test.go` `catalogShape.AsOfShare`, `BenchmarkLargeSourcePropose`; `perf_test.go` `newLargeFixtureAsOf` (D-13) |

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
	Key               DateKey
	Placed            bool
	First, Last       DateEnd
}

func EventDating(date, start, end *datevalue.Value, samples []datevalue.Value) Dating
```

Errors: none new.

### FFI

`api/proto/engine.proto`: `EventDating`, `EventDatingKind` *(new)*; `EventSummary.dating = 19`; `SourceEventTitle.dating = 3` (D-8). Handlers: `api/ffi/handlers/conclusion_summaries.go` `eventSummaryProto` sets `Dating` through `eventDatingProto`; `api/ffi/handlers/event_titles.go` sets it on each `SourceEventTitle`. Regenerate with `./scripts/generate-proto.sh`. No new Method.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Date and place line | `PVDatePlaceLine` | `macos/App/DesignSystem/Components/DatePlaceLine/PVDatePlaceLine.swift` | Ship, unchanged |
| Event secondary line | `EventSecondaryDisplay`, `EventSecondaryLine` | `macos/App/Features/Conclusions/EventsListView.swift` | `content` reads `summary.dating` (D-14) |
| Row date text | `DateRowDisplay` | `macos/App/Platform/DateRowDisplay.swift` | Extend: `line(dating:)` |
| Graph card line | `EvidenceGraphPlacedSubject.dateLine` | `macos/App/Features/Workspace/Session/EvidenceGraphSnapshot.swift` | Reads `eventDating` (D-9) |
| Lifeline mark | `PersonTimelineLifeline.Shape`, `point`, `Mark.pointY`; drawing | `PersonTimelineLifeline.swift`, `PersonTimelineSection.swift` | Extend per ED-8 (D-16) |
| Wire types | `CatalogEventDating`, `CatalogSourceEventTitle` | `macos/App/Platform/GenealogyStore.swift`; mapping `GoStore.swift` | New |

States: an event with no dating → empty date, place only (today). Large: two dates whatever the as-of count. Accessibility: the row label speaks the same words (`EventsListView` `line(content)`), so the open-side wording is in words (ED-8 in the brief). Regular and Wide: identical (ED-W1).

### Strings

Set from the agreed board (Open question O-1): the `L10n.Dates` keys for ED-2 – ED-5 (as-of span, one as-of, as-of with a start, as-of with an end), each with a translator comment naming its arguments, in `Localizable.xcstrings`. No existing key changes; `dates.row.span` stays for spans. No copy names an old scope.

## 7. Steps

**STEP-1 — The one dating in `valuecompare`**
Files: `core/valuecompare/dating.go` *(new)*, `core/valuecompare/dating_test.go` *(new)*. Skill: `add-date-value`.
Do: D-1 – D-4.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/valuecompare/` passes with T-1.

**STEP-2 — Summaries date events through it**
Files: `core/database/conclusionsummaries/events.go`, `compose.go`, `order.go`, `conclusionsummaries_test.go`. Skill: `add-date-value`.
Do: D-5, D-6, D-7. Rewrite `TestEventSpan` / `TestEventSpanDays` cases for D-2, D-4, D-5; add T-2 – T-6.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/conclusionsummaries/ ./core/database/persondetail/` passes.

**STEP-3 — The wire carries the dating**
Files: `api/proto/engine.proto`, generated `api/proto/engine/engine.pb.go` and `macos/App/Platform/Generated/engine.pb.swift`, `api/ffi/handlers/conclusion_summaries.go`, its handler test. Skill: `add-ffi-handler`.
Do: D-8 (Go side); `./scripts/generate-proto.sh`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/...` passes with T-7.

**STEP-4 — Graph Subjects are dated by the engine**
Files: `core/database/grapheventtitles/grapheventtitles.go`, `grapheventtitles_test.go`, `api/ffi/handlers/event_titles.go`. Skill: `add-ffi-handler`.
Do: D-9 (Go side).
Check: `go test -tags fts5 ./core/database/grapheventtitles/ ./api/...` passes with T-9.

**STEP-5 — Search indexes the dating**
Files: `core/database/searchindex/handles.go`, `searchindex.go`, `searchindex_test.go`. Skill: `add-searchable-kind`.
Do: D-10.
Check: `go test -tags fts5 ./core/database/searchindex/ ./core/search/` passes with T-10.

**STEP-6 — `PeriodSamples` counts before it copies**
Files: `core/subjectcompare/pairs.go`, its tests. Skill: `add-match-rule`.
Do: D-11.
Check: `go test -tags fts5 ./core/subjectcompare/ ./core/shortlist/ ./core/subjectprofile/ ./core/database/promotealign/` passes with T-11; matching goldens unchanged.

**STEP-7 — The shortlist looks up an as-of-only event by its years**
Files: `core/shortlist/shortlist.go`, `shortlist_test.go`, `core/database/promotealign/bench_test.go`, `perf_test.go`. Skill: `add-match-rule`.
Do: D-12, D-13. Run the benchmark at the planning base (with D-13's shape patched in) and on the branch.
Check: `go test -tags fts5 ./core/shortlist/ ./core/database/promotealign/` passes with T-12; `go test -tags fts5 -run '^$' -bench BenchmarkLargeSourcePropose ./core/database/promotealign/` meets AC-4.3.

**STEP-8 — Swift formats the dating on every line**
Files: `macos/App/Platform/GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift`, `DateRowDisplay.swift`, `L10n.swift`, `Localizable.xcstrings`; `macos/App/Features/Conclusions/EventsListView.swift`, `PersonTimelinePreviewData.swift`; `macos/App/Features/Workspace/Session/EvidenceGraphSnapshot.swift`, `CatalogQueryRegistry.swift`; tests named in §8 and the stubs in `OnboardingModelTests.swift`. Skills: `add-localized-string`, `add-ui-component`, `add-swift-test`.
Do: D-8, D-9 (Swift side), D-14, D-15; Strings from the board.
Check: `xcodebuild test` (the scheme `scripts/check-pr.sh` runs) passes with T-13 – T-15, no Swift warning.

**STEP-9 — The lifeline marks open sides of a one-day as-of**
Files: `macos/App/Features/Conclusions/PersonTimelineLifeline.swift`, `PersonTimelineSection.swift`, `macos/ProvenenciaTests/PersonTimelineLifelineTests.swift`. Skill: `add-ui-component`.
Do: D-16 per the board's ED-8 frame.
Check: `xcodebuild test` passes with T-16.

**STEP-10 — Docs**
Files: `docs/structured-date-model.md` § 3.4, `docs/deployment-plan/spike-16/event-as-of.md` (the "Drawn as" column of the start-and-end row stays "closed span"; it is now true on the lifeline), `completed.md`, `deployment-plan.md` (map row), this plan (status), `design/S16-D4-event-date-line.md` → `design/archive/`, `design/README.md`.
Do: § 3.4 says an event's dating comes from `valuecompare.EventDating` (D-2 – D-5), sorts at its Low, spans Low to High with open sides on the Timeline, and closes the drift note; per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-42-event-dating-line.md` and links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/valuecompare/dating_test.go` `TestEventDating` *(new)* | Table: `date` 14 May 1817 → Occurrence, Low date, not open; unplaced date + start 1860 → Occurrence, `Placed` false; start 1985 + end 2015 → Span, closed both, High end; start only → Span, High nil, OpenHigh; end only → Span, Low nil, OpenLow, Key at 2015; as-ofs 1990, 2015 → AsOf, Low 1990, High 2015, open both; one as-of → AsOf, High nil, open both; start 1985 + as-ofs → Low start closed, High 2015 open; as-of 1990 + end 2015 → Low open, High end closed; start 1995 + as-of 1990 → Low as-of, OpenLow; `bet 1985 and 1995` + 1990 → Low = High = 1990; `bef 1990` alone → Low = High = it; samples in reversed order → same dating; nothing → None | D-1 – D-4, AC-1.2, AC-1.3, AC-1.4, AC-2.1, AC-2.5 |
| T-2 | Go | `conclusionsummaries_test.go` `TestEventDatingInSummaries` *(new)* | A catalog fixture with the AC-1.1 residence, a 1989 and a 1991 event → `ListEvents` order 1989, residence, 1991; `h.Dating` Low/High; deleting the 2015 as-of Observation → High nil on the next read | AC-2.1, D-7 |
| T-3 | Go | `conclusionsummaries_test.go` `TestEventSpan`, `TestEventSpanDays` (rewritten rows) | AC-2.2 – AC-2.6 spans and days; occurrence rows unchanged | AC-2.2, AC-2.3, AC-2.4, AC-2.5, AC-2.6, D-5 |
| T-4 | Go | `conclusionsummaries_test.go` `TestEventAge` (new rows) | Born 1955, as-ofs 1990, 2015 → Age 34–60, Aged | AC-2.2, D-5 |
| T-5 | Go | `conclusionsummaries_test.go` `TestLifeIgnoresAsOf` *(new)* | Birth with start 1948 and as-of 1950 → birth 1948; birth with only as-of → no birth date | AC-2.7, D-7 |
| T-6 | Go | `conclusionsummaries_test.go` `TestEventDatingManyAsOfs` *(new)* | One event with 10,000 as-ofs → summary Dating Low/High set, composed in under 50 ms on the test machine | AC-2.8, D-6 |
| T-7 | Go | `api/ffi/handlers` summary handler test (the file `add-ffi-handler` names for `eventSummaryProto`) | An as-of event → `dating` kind AS_OF, low, high, open_low, open_high | D-8 |
| T-8 | Go | `core/database/persondetail/timeline_test.go` `TestPersonEventsLifeline` (new rows) | AC-2.2, AC-2.3 spans on a person's Timeline | AC-2.2, AC-2.3 |
| T-9 | Go | `grapheventtitles_test.go` `TestForEvidenceGraph` (new rows) | A graph Event Subject with two as-of Observations → `Title.Dating` AsOf 1990 – 2015; one with `date` → Occurrence | AC-1.7, D-9 |
| T-10 | Go | `searchindex_test.go` `TestEventSecondaryIndexesDating` *(new)* | AC-1.1 residence → Secondary holds `10 Jan 1990` and `10 Feb 2015`; three as-ofs → middle year absent; `ProjectionVersion` is 12 | AC-3.1, AC-3.2, D-10 |
| T-11 | Go | `core/subjectcompare` pairs test `TestPeriodSamplesCap` *(new)* | 1,001 positive as-ofs → nil; 1,000 → 1,000; negative values not counted | AC-4.4, D-11 |
| T-12 | Go | `shortlist_test.go` `TestKeys` (new rows), `TestFind` (new rows) | As-of-only 1990/2015 lookup → closed reach keys + `wide`, no `any`; index unchanged (`wide`, `any`); meets 2000 and AFT 1970, not 1881; a probe dated 1881 meets it | AC-4.1, AC-4.2, D-12 |
| T-13 | Swift | `macos/ProvenenciaTests/DateRowDisplayTests.swift` (new tests) | Each AC-1.6 shape through `line(dating:)` equals today's `line(date:start:end:)` string; ED-2 – ED-6 board strings for AC-1.1 – AC-1.5 | AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, D-14 |
| T-14 | Swift | `EventDetailTests.swift`, `CatalogSearchTests.swift` (new tests) | The header line and a search hit's second line for an as-of summary show the T-13 string | AC-1.1, AC-3.1 |
| T-15 | Swift | `EvidenceGraphSnapshotTests.swift` (new test) | A placed Event Subject with `eventDating` AsOf → `dateLine` the T-13 string, with no date Observations on it | AC-1.7, D-9 |
| T-17 | Go | `core/database/promotealign/bench_test.go` `BenchmarkLargeSourcePropose` (`asof=0`, `asof=0.3` rows) | 4,000 and 16,000 persons → warm proposal at `asof=0.3` within 3% of `asof=0`; reported, not gated | AC-4.3, D-13 |
| T-16 | Swift | `PersonTimelineLifelineTests.swift` (new tests) | A one-day span open both sides → the ED-8 shape, not `.dot`; a both-open bar → `pointY` at its middle; a closed one-day span → `.dot` | AC-2.6, D-16 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `conclusionsummaries` order and span tests, `persondetail` Timeline tests, matching goldens (`subjectcompare`, `promotealign`), `EvidenceGraphSnapshotTests`, `PromoteFlowTests`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left (`eventDating`, `eventDate`); `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches the brief inventory; no new kit primitive
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] AC-4.3 benchmark rows (before and after, both shares, both sizes) and the warm-ms cause in the PR body
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated
- [ ] Domain doc updated: docs/structured-date-model.md § 3.4 (dating, order, Timeline; drift note closed)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Create a new project. Add a Source "Obituary of A. Smith 1990" with a residence Event for X in Town Y, **As of** 10 Jan 1990; a Source "City directory 2015" with X's residence in Town Y, **As of** 10 Feb 2015; promote both to one Event.
2. Events list: the residence shows the ED-2 line and sits between events dated 1989 and 1991. Open it: the header line is the same (the Date row is S16-44's).
3. Open X's Person page, Timeline: the residence row shows the line; the lifeline bar spans 1990–2015 faded at both ends. Add `start_date` 1985 on another Source and promote: the left end closes.
4. Add a residence with only As of 10 Jan 1990: the ED-8 mark, the ED-3 line.
5. Search "1990": the residence is a hit with the ED-2 line. Promote a third Source's residence: the candidate menu and the record row show the line.
6. On the dogfood project (no `as_of`), compare the Events list's date column before and after: identical; a start-and-end residence now spans its years on the lifeline.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| An occurrence or span line changes by a character | T-13 compares `line(dating:)` with today's `line(date:start:end:)` on every AC-1.6 shape |
| Matching goldens move through D-11 | No golden has more than 1,000 samples; STEP-6 runs them |
| D-12 loses Promote pairs a researcher expects | AC-4.2 keeps the dated side's recall; the lost pairs are named in D-12 |
| The board picks a one-day mark the `Shape` enum cannot draw with the fade | D-16 adds what the frame needs inside `PersonTimelineLifeline`; no kit change |

**Stop and report if:**

- `eventDating`, `oneEvent`, `EventSpanAndAge`, `eventMatchSecondary` or `PersonTimelineLifeline.point` no longer do what §4 says.
- Any AC-1.6 line differs from the planning base string.
- A matching golden changes in STEP-6 or STEP-7.
- AC-4.3 is not met (warm proposal at `asof=0.3` more than 3% above `asof=0`): report both rows; do not tune other knobs.
- T-6 exceeds 50 ms, or the compose reads the as-ofs more than once.
- The board's ED-2 – ED-5 wording cannot be built from two formatted dates and the two open flags (it needs a third date or the as-of count).
- `matchregistry` cannot be imported from `conclusionsummaries` or `grapheventtitles` without a cycle.

## 12. Open questions

- **O-1** (blocks Planned): the S16-D4 board's ED-2 – ED-5 wording and ED-8 mark. Recommendation in the brief: "as of" before the date or span; a short bar faded at both ends. When agreed, fill **Board**, **Strings**, T-13 strings and STEP-9, then run the self-review gate and `review-plan`.

## 13. PR

**Title:** S16-42 — Every event date line reads the engine's dating
**Body:** objective in one sentence; what shipped against US-1 – US-4; AC evidence (test names, the AC-4.3 benchmark table, the warm-ms cause); deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-42-event-dating-line.md`.
