# Review — S16-42 Every event date line reads the engine's dating

**Verdict:** Fits with changes — Ready with changes; both rounds' findings Fixed; no open blocker.
**Rounds:** 2 (round 2 after the S16-D4 and S16-D7 boards were agreed, 2026-11-17). **Reviewers:** maintainability (opus), executability (sonnet). Both read the plan and the brief S16-D4.

## To user

- M-9 (answered 2026-11-17: yes): S16-44's map scope now retires `EventSummary.Date` / `StartDate` / `EndDate` on every layer, `oneEvent`'s clear-start-and-end rule and `DateRowDisplay.span`'s last event caller.
- Before planning (answered 2026-11-17): one dating for every event on the Timeline and in order (now a Batch 5 working rule); PRF-1 stays in S16-42; the board draws the one-day mark.

- Brief split (2026-11-17, user: "we need two briefs"): S16-D4 keeps the Events list date line (ED-1 – ED-7, ED-W1; old ED-9 is now ED-7); the lifeline moved to S16-D7 (TL-1 – TL-3, TL-W1; old ED-7 and ED-8). Findings below cite the old IDs.

## Writer's own calls

- D-2: a recorded `date` always wins, placed or not; an unplaced one leaves the event undated in order (the summary already does this, since `oneEvent` clears start and end).
- D-3: the as-of dating runs from the sample whose earliest closed side ends first to the one whose latest closed side starts last; a range beside a point inside it dates as the range.
- D-4: an as-of earlier than the start, or later than the end, wins that side and draws it open; the contradiction notice stays in the idea file.
- D-5: the age reads the known dates; the dating's open sides do not open it.
- D-10: search indexes the line's two dates, not every as-of year.
- D-12: only the as-of-only probe's lookup narrows; its index keys stay one open reach.
- D-16: a day-precision `bef` / `aft` occurrence also draws the short faded bar instead of a dot.

## Round 1

### Maintainability

| ID | Severity | Finding | Answer |
| --- | --- | --- | --- |
| M-1 | blocker | Place folding re-derives the dating from the node, reading as-ofs twice and folding a birth with an as-of at it | **Fixed.** D-7: `eventPlaces` takes the fold date from its caller (`oneEvent`: Low else High; `lifeFacts`: the pick's own date); `eventWhen` deleted; AC-2.7, T-5; STEP-4 |
| M-2 | blocker | D-14 kept Swift's date-wins chooser that rule K-3 retires | **Fixed.** D-14: `DateRowDisplay` splits into `line(date:)` and `span(start:end:)`; `line(date:start:end:)` deleted; `dateRow` calls `span` until S16-44; T-13 compares literal strings |
| M-3 | major | A third and fourth inline copy of the event-period lookup | **Fixed.** D-7: `subjectcompare.Rules.EventPeriod`; `evidencelayer.go:186` and `profiles.go:184` move onto it; STEP-2; DoD sweep |
| M-4 | major | D-3's index tie rule contradicts T-1's reversed-order row | **Fixed.** D-3 breaks ties by value (lowest `E.Lo`, highest `L.Hi`), index only for samples equal in both ends; T-1 reversed and tied rows |
| M-5 | major | ED-8 should be a `.bar`, not a new `Shape` case | **Fixed.** D-16, brief ED-8 and inventory: `.bar` at `openDayLength` (≥ two fades); stop condition if the board needs another shape |
| M-6 | major | The one-day rule also catches day-precision `bef` / `aft` occurrences | **Fixed.** D-16 and brief ED-8, frame 4 say so: they draw the short faded bar, as a year-precision `bef` already draws a faded bar; a closed day stays a dot; AC-2.6, T-16 (writer's call above) |
| M-7 | major | `loadHandleValues` keeps dead keys and branches | **Fixed.** D-10: `IN ('name', 'toponym')`, `value_date`, the term join and two branches go |
| M-8 | major | Skill and docs the PR makes false | **Fixed.** STEP-13 and DoD: `add-date-value`, `matching-model.md` `MaxSamples` row, `grapheventtitles` package doc, `CatalogEventSummary` doc |
| M-9 | major | Retiring the old date fields had no slot | **To user → yes.** Map S16-44 scope entry; plan Out row |
| M-10 | minor | `EventDating` named for events, though a Place caller is named | **Fixed.** `valuecompare.DatingOf` |
| M-11 | minor | `Dating` carried order internals | **Fixed.** D-1: `Dating` holds kind, two dates, two flags; D-5 `placeDating` in `conclusionsummaries` places it |
| M-12 | minor | Brief inventory missed the graph line and mislabeled `DateRowDisplay` | **Fixed.** Brief §6 rows |
| M-13 | nit | Names hold more than titles | Logged. `CatalogSourceEventTitle` mirrors the wire message `SourceEventTitle`; doc comments updated (M-8) |

### Executability

| ID | Severity | Finding | Answer |
| --- | --- | --- | --- |
| X-1 | blocker | `abt 1990` + `bef 2015` dated 1990 alone under D-3 | **Fixed.** D-3 reads each sample's earliest and latest closed ends for `SampleExtremes`; T-1 row; AC-1.5 holds |
| X-2 | blocker | The benchmark's probes are all dated, so D-12 cannot show | **Fixed.** D-13: Source A's deaths also become as-of at the share; AC-4.3 compares the overhead base vs branch; the +3.5 ms through `-cpuprofile` |
| X-3 | blocker | How place folding gets the dating was undecided | **Fixed.** As M-1 |
| X-4 | major | Shortlist edges: open samples, tolerance, over the cap | **Fixed.** D-12: open samples ignored, tolerance as `YearReach` returns, none closed → `any`; D-11 `CountSamples` keeps an over-cap event as one open reach; T-12 rows |
| X-5 | major | Equal start and end; mixed placed and unplaced; out-of-window samples | **Fixed.** D-4: with no sample, start and end as recorded (`1985–1985` kept); with samples, unplaced start or end not read; D-3 skips a sample `DateKeyOf` rejects; T-1 rows |
| X-6 | major | Fixture random stream, property id and columns | **Fixed.** D-13: a second PCG stream, `idOf(… "as_of")`, the `date` row's columns; `newLargeFixtureAsOf` in `perf_test.go`; `TestLargeSourceBudgets` unchanged |
| X-7 | major | Swift sites that set dates go silently empty | **Fixed.** §4 row and STEP-11 name `EventDetailTests` `dated`, `PersonsListTests` `eventsRowSecondLine`, `PersonTimelinePreviewData.apply(to:)`; D-15 maps each preview case |
| X-8 | major | `protoc`, `xcodebuild` absent here; golden command unnamed | **Fixed** (the command): STEP-2, STEP-8 name `./core/graphalign/` and `TestGracieObituaryGolden`. The tools are an environment fact: §6 FFI and the risk table say the PR reports which checks ran where and CI runs `xcode-test` |
| X-9 | major | Wrong file for `eventDating` and loose names and lines | **Fixed.** §4 rows: `compose.go` lines 1136–1187, the nested `point`, stub lines 617–620, drawing 529–550, `TestListEventSummaries` |
| X-10 | minor | Sweep wording catches `L10n.Conclusions.eventDate` | **Fixed.** DoD sweep is three exact `rg` patterns |
| X-11 | minor | STEP-2 and STEP-8 too big | **Fixed.** Split into STEP-3/STEP-4 and STEP-10/STEP-11 (13 steps; the user kept S16-42 whole, map review K3-3) |
| X-12 | minor | Go and Swift Observation order may differ | **Declined.** Both read `ORDER BY o.ref COLLATE NOCASE` (`core/database/graphfill/load.go:179`, `core/database/observations/observations.go:102`); D-9 says so |
| X-13 | nit | Backticked idea path warnings | Logged; the links resolve |

## Round 2

Both reviewers confirmed every round-1 answer against the plan and the code at `2dd631e`, except X-7 (half reflected, M2-3).

| ID | Severity | Finding | Answer |
| --- | --- | --- | --- |
| M2-1 / X2-1 | blocker | A lone range as-of: D-4 gave High nil, T-1 and Edges gave High = Low; the Swift line differs | **Fixed.** D-3, D-4, Edges and T-1: High nil exactly when both sides are one sample; T-13 row `as of bet 1985 and 1995` |
| M2-2 | blocker | `oneEvent` and `lifeDate` kept hand-written date keys, against "One dating" | **Fixed.** D-7: every key read through `eventLead` / `eventPeriod`; DoD sweep for `vocabkey.Property(StartDate|EndDate|AsOf)` in both packages |
| M2-3 | major | Two Swift tests build `dateLine` from Observations | **Fixed.** §4, STEP-11, Deletes, D-15: one test deleted (T-15 replaces it), the Promote test seeds `eventTitlesByGraph`; `swift-tests.mdc` in Rules that bind |
| M2-4 / X2-2 | major | `Keys` had no stated way to get the period, and the `MaxBuckets` flip was not split | **Fixed.** D-7 `Rules.Period` is the one lookup (six readers move); D-12 names the `Keys` line and the `indexOpen` / `lookupOpen` rule |
| X2-3 | minor | The `rg` sweep missed multi-line callers | **Fixed.** The build is the check (the chooser is deleted) |
| X2-4 | minor | Where `eventDating` comes from; AC-4.3 noise | **Fixed.** D-9 names the `CatalogSourceEventTitle` entry; AC-4.3 and its stop condition use the median of 3 runs and their spread |

## Amended during ship (2026-11-17)

The S16-42 implementer stopped at STEP-9 on AC-4.3 ([ship log](S16-42-event-dating-line.ship.md)). The user relaxed AC-4.3: the branch's `asof=0.3` overhead must not exceed the base's by more than the runs' spread, because D-12 narrows only as-of-only probes' lookup and the catalog's as-of events keep an open index reach on purpose (D-9). Same pass: T-1 and §6 Edges "as-of 2020 + end 2015" now read as D-4 gives it (High nil, `as of 2020`). No Decision changed.
