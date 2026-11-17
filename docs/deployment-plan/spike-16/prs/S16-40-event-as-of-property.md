# S16-40 — An event records As of dates, and matching reads them as bounds

**Status:** Landed in [#869](https://github.com/mendahu/provenencia/pull/869) (2026-11-16)
**Spike / slice:** Spike 16 · Batch 5 · Slice 5a — An attestation is a sample
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: the composer lists the new seeded Property and dates it with today's editor, like any other date Property)
**Board:** —
**Depends on:** —
**Blocks:** S16-42
**Branch:** `s16-40-event-as-of-property`
**Version bump:** minor: the next minor after `VERSION` on `main` when the branch is cut (0.17.0 → 0.18.0 at the planning base `14fbfca`) — a new seeded Property in new catalogs and a matching rule a researcher sees in Promote ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-seeded-vocabulary`](../../../../.agents/skills/add-seeded-vocabulary/SKILL.md), [`add-date-value`](../../../../.agents/skills/add-date-value/SKILL.md), [`add-match-rule`](../../../../.agents/skills/add-match-rule/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`
**Context:** [`../event-as-of.md`](../event-as-of.md); working rules [Batch 5](../deployment-plan.md#batch-5--event-as-of-dates): "As of is a fourth event date Property", "New catalogs only", "On every event", "Every qualifier, no exception", "An as-of x reads as started by x, still under way at x", "A closed as-of counts toward the person's lifespan"; [`seeded-vocabulary.md` §3.2–3.3](../../../seeded-vocabulary.md#32-properties); [`conclusion-reconciliation.md` §8](../../../conclusion-reconciliation.md#8-cardinality); [`matching-model.md`](../../../matching-model.md)
**Planned:** 2026-11-16 against `main` @ `14fbfca`
**Review:** [`S16-40-event-as-of-property.review.md`](S16-40-event-as-of-property.review.md) — two rounds on this plan (3 and 4), Ready; no open blocker

**Landed.** Differences from the plan: the as-of pick (D-6) reads the samples in one linear pass through `valuecompare.SampleExtremes` and breaks a tie on the extreme end by the lowest Same key (`propertycompare.KeyCompare`), rather than sorting them first, with the same picks whatever the input order, and a side with more than `Period.MaxSamples` (1000, a registry knob) positive samples skips the sample check so the base comparison stands; `subjectcompare.PeriodSamples` is the one reading of a period's samples, which `LifeEventOf` calls (D-10's signature is kept); T-4's every-order rows run in `TestCompareSamples` through `permutationsOf`; `subjectprofile`'s tests add a `sampled` helper; T-7 has a "none closed" case; `FuzzCompareProperty` guards the comparer against any dates (seeded, runs as a unit test), and the invariants' `as_of` pool reaches the conflict branch. The §10 manual check was not run, so AC-1.2, AC-1.3, AC-1.4 and AC-2.3 are unverified until the user runs it.

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

A researcher can record that a lasting event was under way on a day without claiming when it began, ended or happened: an obituary's "survived by X of Town Y" of 10 Jan 1990 becomes **As of 10 Jan 1990** on X's residence. A second record's As of 10 Feb 2015 sits beside it, and nothing reads the two as competing answers: the auto-reconciler keeps both, and Promote meets the two records of one residence with no date conflict. An as-of still conflicts where it should: with a residence that ended in 1985 or began in 1995.

**Why now.** Dogfood, 2026-11-16: attestations put on `date` make one residence read `mixed` and make Promote score a date conflict between two records of it ([`../event-as-of.md`](../event-as-of.md#problem-dogfood-2026-11-16)).

**What stays.** `date`, `start_date` and `end_date` and every reader of them; every match between events with no as-of (the goldens). No list, page or Timeline dates an event by its as-ofs until S16-42. Existing catalogs do not gain `as_of` (working rule "New catalogs only"). The composer and its date editor are unchanged.

## 2. User stories

**US-1.** As a researcher on a new project, I can record an event's As of date with any qualifier, so that an attestation is not recorded as when the event happened.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A catalog created by `onboarding.createCatalog` | `properties` has `as_of` (origin `provenencia`, label "As of", value type `date`, cardinality `multiple`), bound to `event` at sort order 5, locked; `event_picture` is at 6 |
| AC-1.2 | The composer's Property menu on an Event Subject | Lists As of (the menu sorts by label); its date editor offers As stated, About, Before, After and Range, as for every date |
| AC-1.3 | A catalog created before this PR, opened after it | Has no `as_of`; opening adds none |
| AC-1.4 | The new catalog's `date` and `end_date` descriptions | Name As of for a day a record shows the event under way (D-2) |

**US-2.** As a researcher, when two Sources each attest one residence on a different day, the event keeps both.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Two as-of candidates from two Sources: 10 JAN 1990 and 10 FEB 2015 | Both kept, state `multiple` |
| AC-2.2 | Two as-of candidates: 1990 and 10 JAN 1990 | One value, 10 JAN 1990; the 1990 candidate folded |
| AC-2.3 | Two As of observations on one Event in an Evidence graph | No conflict mark on the card (the graph skips `multiple` keys) |

**US-3.** As a researcher running Promote, two records of one residence attested on different days meet without a date conflict, and a record that contradicts an attestation conflicts.

| AC | Given / when (side A · side B, events) | Then (the `date` lead's result) |
| --- | --- | --- |
| AC-3.1 | as_of 1990 · as_of 2015 | unknown, no values; 0 points |
| AC-3.2 | as_of 1990 · end_date 1985 | conflict; speaking pair A 1990, B "Before 1985" |
| AC-3.3 | as_of 1990 · start_date 1995 | conflict |
| AC-3.4 | as_of 1817 · start_date 1815, end_date 1820 | partial, relation `contains`, similarity 0.55, 1.1 points (AC-2.5's numbers: the same comparer call); speaking A 1817 |
| AC-3.5 | as_of 1990 · start_date 1985 | unknown (a half-open period does not agree) |
| AC-3.6 | as_of 1990 · date 1881 | unknown, no values (today's reading: no period) |
| AC-3.7 | as_of 1990, start_date 1985 · date 1881 | conflict, as today's "After 1985" against 1881 |
| AC-3.8 | as_of BEF 1990 · start_date 1995, end_date 2000 | conflict (started by 1990) |
| AC-3.9 | as_of AFT 1990 · start_date 1970, end_date 1985 | conflict (still under way after 1990) |
| AC-3.10 | as_of 1991 · end_date 1990 | unknown, no values, 0 points: `near` against the half-open "Before 1990", which does not agree (D-7), and not a conflict |
| AC-3.11 | No as-of on either side (every row of `TestCompare` today) | Unchanged |
| AC-3.12 | An event with only as-ofs | Reaches Promote's shortlist (filed as an open reach) |

**US-4.** As the engine, a closed as-of on an event a person takes part in counts toward that person's lifespan.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | `LifeEventOf` on an event with `as_of` 1990 | `Samples` holds 1990; the lifespan's span counts it; a birth with only an as-of does not fix the window's start |

## 3. Scope

| In | Covered by |
| --- | --- |
| `vocabkey.PropertyAsOf`; `as_of` seed row and event binding; `event_picture` → 6; `date` and `end_date` descriptions | STEP-1, AC-1.1 – AC-1.4 |
| Reconciler tests for a `multiple` date | STEP-2, AC-2.1, AC-2.2 |
| `subjectcompare.Period.Samples`; `Rules.Role` reads it; registry `Periods[event][date].Samples = as_of`; knob inventory row; test metas | STEP-3 |
| `CompareProperty` reads as-ofs against the other side's period | STEP-4, AC-3.1 – AC-3.11 |
| The shortlist files an as-of-only event as an open reach | STEP-5, AC-3.12 |
| `LifeEventOf` reads `as_of` | STEP-6, AC-4.1 |
| `seeded-vocabulary.md`, `matching-model.md`, `add-match-rule` | STEP-7 |

| Out | Home |
| --- | --- |
| Any reader that dates, sorts, searches or draws an event by its as-ofs; the dating helper's display fields | S16-42 |
| `EvidenceGraphSnapshot.dateLine` reading as-ofs | S16-42 |
| The Event page's Date row showing as-ofs | S16-44 |
| `as_of` in an existing catalog | [event as-of follow-ups](../../../ideas/event-as-of-followups.md) (the user's later one-off command) |
| A composer rule for as-of qualifiers | not planned (working rule "Every qualifier, no exception") |
| A weight of its own for as-ofs | not planned (working rule: counts under `date`) |
| Hiding As of on an event type | [properties and terms: lock event properties to event types](../../../ideas/properties-and-terms.md#lock-event-properties-to-specific-event-types) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Property keys | `core/vocabkey/vocabkey.go` lines 89–92 | `PropertyDate`, `PropertyStartDate`, `PropertyEndDate`; no `as_of` |
| Seed Properties | `core/database/subjectvocab/registry.go` `seedProperties` (from line 155) | `date` (line 161) "…or the best single date when a span is unknown…"; `end_date` (line 163) "When a spanned event ended or was last known…"; `toponym`, `religion` show the `Cardinality: propertymeta.CardinalityMultiple` shape |
| Seed bindings | same file, `seedBindings` (from line 188), event block lines 197–202 | `event_type` 0 … `end_date` 4, `event_picture` 5; dates locked |
| Install | `core/database/subjectvocab/subjectvocab.go` `Install`, `BindingsForType` (line 430); called only from `core/onboarding/ready.go` `createCatalog` | Create time only; open never heals |
| Seed tests | `core/database/subjectvocab/subjectvocab_test.go` `TestSeedProductValues` (line 467; `event_picture` order 5 at line 483), `TestInstallMatchesRegistry`, the install test at line 74 (`len(eb) != 6`); `vocabkey_test.go` `TestVocabKeysMatchSeed` (list near line 54); `subject_section_test.go` line 101 pins `subjectcomparetest.Metas()` to the seed | Six event bindings; the key and meta lists are hand-kept |
| Reconcile | `core/autoreconcile/pipeline.go` (`CardinalityMultiple` skips `elect`), `dates.go` `dateModule` | A `multiple` date keeps each distinct value; nested dates fold |
| Reconcile tests | `core/autoreconcile/dates_test.go` `TestDateReconcile` (fields `want`, `state`, `shown`, `folded`; calls `Reconcile` with `CardinalitySingle`); helpers `date`, `ip` in `autoreconcile_test.go`, `ymd`, `datePtr`, `reasonOf` in `dates_test.go` | No `multiple` date case |
| Period rule | `core/subjectcompare/subjectcompare.go` `Period` (line 33: `struct{ Start, End vocabkey.PropertyKey }`), `Rules.Role` (line 198: a period's Start or End is `RolePeriodEnd` under its lead), `CountsUnder` (line 240: a period end counts under none of its own) | No samples |
| Side and period | `core/subjectcompare/pairs.go` `Side` (line 15), `period` (line 43) | A side with no positive `date` gets one stand-in from its earliest start to its latest end; a missing side is open ("After 1815", "Before 1820"); none when both are missing |
| Compare entry | `subjectcompare.go` `CompareProperty` (line 149), called by `Compare` (line 125) and `core/recordlinks/recordlinks.go` line 373 (Person only) | "The one place Side meets property compare" |
| Compare tests | `core/subjectcompare/subjectcompare_test.go` `TestCompare` (line 88; event rows AC-2.5 – AC-2.13 at lines 188–257; helpers `year`, `is`, `prop`, `near`, constants `date`, `start`, `end`); `invariants_test.go` `TestInvariants` | Period rows; the invariants hold over every row |
| Test metas | `core/subjectcompare/subjectcomparetest/subjectcomparetest.go` `Metas` | The three dates, single |
| Registry | `core/matchregistry/subject.go` line 37 `Periods[Event][PropertyDate] = {Start, End}`; `inventory_test.go` `TestKnobInventoryMatchesRegistry` (every registry field has a row in `docs/matching-model.md`); `registry_test.go` line 24 | — |
| Shortlist | `core/shortlist/shortlist.go` `Keys` (line 67), `positive` (line 48); date keys from `valuecompare.YearReach` | An event with no positive `date` and no period stand-in gets no date keys, so Promote never shortlists it |
| Shortlist tests | `core/shortlist/shortlist_test.go` `TestKeys` (line 324), helper `event(…)` | — |
| Lifespan input | `core/subjectprofile/subjectprofile.go` `LifeEventOf` (line 38; key list line 46), `lifespan` (line 180: every date to `firsts`/`lasts`, a Starts event's to `startFirsts`, an Ends event's to `endLasts`); callers `core/database/evidencelayer/evidencelayer.go` line 186, `core/database/promotealign/profiles.go` line 184 | Reads `date`, `start_date`, `end_date` from a hand list; the lifespan skips open dates |
| Lifespan tests | `core/subjectprofile/lifeevent_test.go` `TestLifeEventOf` ("every date, in key order") | — |
| Docs | `docs/seeded-vocabulary.md` §3.2 (line 315; `date` "point-in-time (or best single date)"), coexistence paragraph (line 355, "Event date Properties (`date`, `start_date`, `end_date`)"), §3.3 event block (line 371); `docs/matching-model.md` pair row (line 76), `subject.Periods` rows (lines 183–184); `.agents/skills/add-match-rule/SKILL.md` | Three event date Properties |

**Precedent.** S11-48 seeded `religion` and `languages_spoken` as `multiple` Properties (a `seedProperties` row, a `seedBindings` row, a `TestSeedProductValues` case, the §3.2 / §3.3 rows). The period rule itself (`subject.Periods`, `period`, rows AC-2.5 – AC-2.13 of `TestCompare`) is the precedent for the matching change: copy its row style.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `as_of` is bound to `event` at sort order 5, locked; `event_picture` moves to 6 | The dates sit together on the Properties page; locked like the other event dates (§3.2) | Appending at 6 — splits the dates |
| D-2 | Descriptions. `as_of`: "A day the event was known to be under way, from a record made then (an obituary's \"of Town Y\", a directory's year). Not when it began, ended or happened. More than one is allowed." `date`: "Point-in-time when the event occurred. Prefer this for births, deaths, and other one-day facts. Use Start date and End date when the event lasts across a range, and As of for a day a record shows it under way." `end_date`: "When a spanned event ended. Pair with Start date; leave empty for instantaneous events that only need Date. A day the event was last seen under way is As of." | One concept, one Property; today's "best single date" and "last known" send an attestation elsewhere | Leaving the neighbours — the Properties page points two ways |
| D-3 | No qualifier rule anywhere: Go accepts any DateValue on `as_of`, the composer is unchanged | Working rule "Every qualifier, no exception" (user, 2026-11-16) | A composer chip rule — dropped by the user |
| D-4 | `subjectcompare.Period` becomes `struct{ Start, End, Samples vocabkey.PropertyKey }`; registry `Periods[Event][PropertyDate] = {Start: PropertyStartDate, End: PropertyEndDate, Samples: PropertyAsOf}`. `RolePeriodEnd` is renamed `RolePeriodMember` (its readers: `Rules.Role`, `Meta`, `CountsUnder` and their tests) and `Rules.Role` returns it for `p.Samples == key` too. The docs of `Period` ("reads two date properties as one range"), `Rules.Periods`, `Meta` and `CountsUnder` say "start, end or samples"; `Meta`'s doc adds that a period member is compared inside `CompareProperty` under the lead's meta | An as-of counts under `date` (no weight of its own) and never on its own key (`CountsUnder` false), as start and end do; the old name would mislabel a sample | A `RolePeriodSample` — a new role every reader would have to learn for the same treatment; keeping `RolePeriodEnd` — names a sample an end |
| D-5 | `CompareProperty` keeps today's result as `base` (`propertycompare.Compare` of the two `Side`s), and when `rules.Periods[kind][key]` names `Samples` adds the sample checks of D-6; with no positive sample on either side it returns `base` unchanged | Every caller (Compare, Promote, record links) gets the rule in one place; events with no as-of keep their result bit for bit (AC-3.11) | A separate check in `Compare` beside `lifespan` — record links and any later caller of `CompareProperty` would miss it |
| D-6 | Three pieces. (a) `subjectcompare.Samples(kind vocabkey.SubjectType, key vocabkey.PropertyKey, v Values, rules Rules) []propertycompare.Value` *(new, `pairs.go`, beside `Side`)*: the positive values of `v[rules.Periods[kind][key].Samples]`, nil when the period names no samples; the only place D-8 lives. (b) `valuecompare.SampleExtremes(firsts, lasts []DateEnd) (endsFirst, startsLast int)` *(new, `datewindow.go`, beside `Earliest` and `Latest`)*: the index of the lowest `Hi` among closed `lasts` and of the highest `Lo` among closed `firsts`, the lower index on a tie, -1 when none is closed; the caller supplies the reading. (c) `samplesAgainst(kind, key, mine, other Values, rules Rules, swapped bool, meta propertymeta.Meta, value valuecompare.Rules) []propertycompare.Result` *(new, unexported, `pairs.go`)*: nil unless `other[key]` (the map, not `Side`) has no positive value and `period(other[p.Start], other[p.End])` builds a stand-in **closed on at least one side** (always true for a built period); mine's own `date` does not stop it. It takes `Samples(kind, key, mine, rules)`, sorts them by `valuecompare.Key(propertycompare.Typed(v, meta).Value, valuecompare.Same, value)` (profile values carry no type until `Typed` sets it from the meta, so an untyped key would be empty; typed, ties never depend on input order), reads each one's ends with `valuecompare.AboutEnds(*v.Date, value.Dates.AboutUnits)` (the comparer's own reading; a value whose ends are not ok is dropped), picks with `SampleExtremes` (an index picked twice is compared once), and compares each pick with the stand-in through `propertycompare.Compare([]Value{sample}, []Value{standIn}, meta, value)`, the slices swapped when `swapped` (B's samples, so A's value stays on the A side). `meta` is `metas[key]`, the lead's. A result against a stand-in with an open end has its `agree` or `partial` outcome replaced by `OutcomeUnknown` (cause unchanged) before it is returned. Match strength therefore reads from the two extreme samples only: samples 1983, 1990 and 2002 against 1985 – 2000 score as 1983 and 2002 (`near`), never as 1990 (`contains`); an attestation inside the period does not raise it. `CompareProperty` calls it as `(…, a, b, …, false, …)` then `(…, b, a, …, true, …)` | The window rule (started by the window's last day, under way on its first) is exactly "the sample's window does not overlap the other side's period", which the comparer reports as `different` with its tolerance and ABT widening (probe at `14fbfca`, review log); read the comparer's way, the latest-starting and earliest-ending samples are the only ones that can be `different` from one period, so cost is two compares per side however many as-ofs; `SampleExtremes` is the selection S16-42's display helper reuses with `DateEnds` | A new bounds type — re-implements the comparer; comparing every sample — 10,000 compares per pair on crafted data; picking by raw `DateEnds` — a second reading of one date (review M3-1) |
| D-7 | Combining in `CompareProperty`: the results are `base` and every result of D-6 in both directions. When any is `conflict`, the result is the best conflict; else when any matches (`agree` or `partial`), the best match; else `base`. "Best" is `propertycompare.Better(x, y Result, value valuecompare.Rules) bool` *(new, exported)*: the existing `better` ordering applied to two Results' speaking pairs, each side keyed as `Compare` keys it (`keyed` from the pair's values under `value`); a Result with no speaking pair is never better, so the choice never depends on which side is A When `Better` is false both ways, the first in the order `base`, A's results, B's results is kept | One ranking of "which pair speaks", order-free, shared with `propertycompare`; the open-end downgrade in D-6 keeps a half-open period from agreeing (working rule); a better `base` keeps winning | A hand-written ranking with an A-before-B tie — a second ordering beside `better` that flips Promote's explanation with side order (review M3-3) |
| D-8 | Negative as-ofs are ignored by the sample check (positive values only) | A denied attestation says nothing about bounds | Reading a negative as a conflict — no rule asks for it |
| D-9 | Shortlist: in `Keys`, for a Dated kind whose `positive(kind, d.Date, …)` list is empty, when `subjectcompare.Samples(kind, d.Date, v, subject)` is not empty, the event is keyed as one open reach: the date loop first collects a list of reaches `(lo, hi int, open bool)` from `YearReach` per date, the as-of case appends one `(0, 0, true)`, and the existing per-type emission runs over that list (no second branch). An event with an as-of and a period stand-in is keyed by the stand-in only | An as-of-only event's span is unknown both ways; an open reach meets every closed one, as a `BEF` date does today | Keying the samples' years — an event that began years before its first attestation would never be shortlisted |
| D-10 | `LifeEventOf(event Values, role vocabkey.Role, lead vocabkey.PropertyKey, p subjectcompare.Period) LifeEvent` reads `lead`, `p.Start` and `p.End` into `Dates` and `p.Samples` into a new `LifeEvent.Samples`; its hand-kept key list goes. Both callers pass `vocabkey.PropertyDate` and their registry's `Subject.Periods[vocabkey.Event][vocabkey.PropertyDate]` (`core/database/evidencelayer/evidencelayer.go` line 186, `rules.Subject`; `core/database/promotealign/profiles.go` line 184, `p.cfg.Subject`). `lifespan` adds a sample's closed ends to the span (`firsts`, `lasts`) but never to `startFirsts` or `endLasts` | Working rule: a closed as-of counts toward the lifespan but never dates a birth or a death; an as-of on a birth event (allowed: "On every event") must not fix the window; the registry is the one list of an event's date keys | Adding `PropertyAsOf` to the key list — an as-of on a birth would fix the lifespan's start (review M3-5) |
| D-11 | Reconcile is proven by tests only: `TestDateReconcile`'s cases gain a `cardinality string` field (empty reads as `propertymeta.CardinalitySingle`) | `multiple` already keeps distinct dates and folds a wider date into a narrower one it contains; a narrower as-of implies the wider one's bounds, so the fold loses nothing | An end-to-end autoreconciler test — cardinality reaches `Reconcile` through the generic loader |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `vocabkey.PropertyAsOf` *(new)* | const | `vocabkey.PropertyEndDate` | Extends the block |
| `as_of` seed row and binding *(new)* | registry row | `religion` row | Extends `seedProperties` / `seedBindings` |
| `Period.Samples` *(new)* | field | `Period.Start`, `Period.End` | Extends the period rule the as-of belongs to |
| `subjectcompare.Samples` *(new)* | func | `subjectcompare.Side` | Same file and shape; the one reading of a side's samples, for compare and the shortlist |
| `samplesAgainst` *(new, unexported, `pairs.go`)* | func | `period` (same file) | Reuses `period`, `AboutEnds` and `propertycompare.Compare`; no new comparison |
| `valuecompare.SampleExtremes` *(new)* | func | `valuecompare.Earliest`, `Latest` | They return a `DateEnd`, not which value it came from; S16-42 reuses this |
| `propertycompare.Better` *(new)* | func | `propertycompare.better` | Exports the existing ordering over two Results instead of a second one; `better` stays the one ordering |

**Builds on.** `add-seeded-vocabulary`; `add-match-rule` (registry knob, inventory row); the period rule (`subject.Periods`, `period`); the date comparer.
**Deletes.** None — nothing becomes dead.
**Next adds.** S16-42 reads `vocabkey.PropertyAsOf` in `conclusionsummaries` and adds the dating helper's display fields; S16-42's helper reuses `valuecompare.SampleExtremes` with `DateEnds` and reads the samples key from `subject.Periods`.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| An event with several values on one date Property | Evidence graph marks (`EvidenceCitedPropertyMarks.conflictCounts`), conclusion detail `state` | `multiple` keys are skipped / read `multiple` today (toponym, religion); AC-2.3 |
| An event with only as-ofs | Promote's shortlist and scoring | Filed as an open reach (D-9); scored by D-5 – D-7 |
| An event with only as-ofs | Event page Date row, Events list, Timeline | Undated, as an event with no date today, until S16-42 (manual check 5) |
| `as_of` in a project's profile | `subjectcompare.Rules.CountsUnder`, `graphalign` `subjectHasValues` | Counts under `date` (D-4) |
| An as-of on a birth or death event | `subjectprofile.lifespan` | Counts in the span, never fixes the window (D-10, T-6) |

### Scale

At the map's Scale (Batch 5: up to 20 as-ofs on an event; 10,000 crafted): the sample check is at most two date compares per side per compared pair (D-6), plus one pass over the samples to pick them. The shortlist adds no keys beyond today's open reach. The seed is one row at create time.

### Edges

- **Assumptions.** `TestInvariants` (`core/subjectcompare/invariants_test.go`) draws random values per property from `propertyPools` for each lead's group (`groups()`: lead, pool, period start and end); STEP-4 adds `p.Samples` to `groups()` and a pool for `as_of`, so the invariants run over as-ofs. D-6 runs both directions, sorts samples by their typed Same key, and D-7 ranks with `propertycompare.Better`, so a swapped or shuffled pair gives the same outcome; T-4 has a swapped row. `Rules.Role` assumes a key belongs to at most one lead: `as_of` only to `date`.
- **Neighbors.** Today's period rows AC-2.5 – AC-2.13 are unchanged (AC-3.11). A date within tolerance of a bound is not a conflict (AC-3.10). A half-open period bounds but does not agree (AC-3.5). An occurrence `date` keeps the as-of side to today's reading (AC-3.6, AC-3.7). `BEF` / `AFT` as-ofs bound on their closed side only (AC-3.8, AC-3.9).
- **Removed inputs.** A negative as-of contributes nothing (D-8). A folded as-of (1990 into 10 JAN 1990) keeps its record on the kept value (T-2).
- **Real data.** The registry is the only table: `Periods` has one entry; `TestKnobInventoryMatchesRegistry` runs over all of it.
- **Untrusted size.** A side's as-ofs: bounded to two compares per side (D-6), one sort and one pass to choose them. The reconciler is not bounded: `autoreconcile` folds every pair of a Property's distinct values (`foldValues`), measured 2026-11-16 at 0.6 s for 1,000 distinct dates and 61 s for 10,000 on a `multiple` date. That cost is every `multiple` Property's today (toponym, religion); this PR adds none, and it is parked in [share packages](../../../ideas/share-packages.md) (user, 2026-11-16).

### Schema

None — seeded rows only, at create time.

### Go core

| Package | Change |
| --- | --- |
| `core/vocabkey` | `PropertyAsOf = "as_of"` *(new)* after `PropertyEndDate` |
| `core/database/subjectvocab` | `as_of` row (D-2), binding (D-1), `date` and `end_date` descriptions (D-2) |
| `core/subjectcompare` | `Period.Samples` *(new)*; `RolePeriodMember` (D-4); `Samples` *(new)*; `CompareProperty` (D-5) calls `samplesAgainst` per direction (D-6) and combines with `propertycompare.Better` (D-7) |
| `core/valuecompare` | `SampleExtremes` *(new)* (D-6) |
| `core/propertycompare` | `Better` *(new)* (D-7) |
| `core/subjectcompare/subjectcomparetest` | `Metas`: `vocabkey.PropertyAsOf: {ValueType: date, Cardinality: multiple}` |
| `core/matchregistry` | `subject.go` `Periods` entry gains `Samples: vocabkey.PropertyAsOf` with a `// decided (user, 2026-11-16)` comment |
| `core/shortlist` | `Keys` (D-9) |
| `core/subjectprofile` | `LifeEventOf` key list (D-10) |

Errors: none new.

### FFI

None — no wire change.

### macOS

None — no Swift change: the composer lists the Property from the catalog and dates it with `DateValueEditorForm` as it is.

### Strings

None — the label and descriptions are seed data.

## 7. Steps

**STEP-1 — Seed `as_of`**
Files: `core/vocabkey/vocabkey.go`, `core/database/subjectvocab/registry.go`, `subjectvocab_test.go`, `vocabkey_test.go`. Skill: `add-seeded-vocabulary`.
Do: the key; the `as_of` row and binding (D-1, D-2); the `date` and `end_date` descriptions (D-2); `event_picture` → 6. T-1: the `TestSeedProductValues` case, `event_picture`'s expected order 6, `vocabkey.PropertyAsOf` in `TestVocabKeysMatchSeed`'s list, and the count at `subjectvocab_test.go` line 74 replaced by `len(BindingsForType("event"))` (its message too: "want %d").
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/vocabkey/... ./core/database/subjectvocab/... ./core/onboarding/...` passes.

**STEP-2 — Prove the reconciler keeps as-ofs**
Files: `core/autoreconcile/dates_test.go`. Skill: `add-date-value`.
Do: D-11; T-2.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/autoreconcile/...` passes.

**STEP-3 — The period names its samples**
Files: `core/subjectcompare/subjectcompare.go`, `core/subjectcompare/subjectcomparetest/subjectcomparetest.go`, `core/matchregistry/subject.go`, `core/matchregistry/subject_test.go` (the pair-claim loop claims `p.Samples` as `"period"`), `core/database/subjectvocab/subject_section_test.go` (line 80's period-member list adds `p.Samples` when set), `docs/matching-model.md`, `core/subjectcompare/subjectcompare_test.go` (`TestRulesRole`, `TestCountsUnder`, `TestLead`, `TestMeta`). Skill: `add-match-rule`.
Do: D-4; the test metas; the registry entry; a `matching-model.md` row `subject.Periods.event.date.Samples` | `as_of` | decided (user, 2026-11-16) | "As-ofs read against the other side's period"; T-3.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/subjectcompare/... ./core/matchregistry/... ./core/database/subjectvocab/...` passes (the inventory and the metas pin).

**STEP-4 — Compare reads as-ofs against the other side's period**
Files: `core/valuecompare/datewindow.go`, `core/valuecompare/datewindow_test.go`, `core/propertycompare/propertycompare.go`, `core/propertycompare/propertycompare_test.go`, `core/subjectcompare/pairs.go`, `core/subjectcompare/subjectcompare.go`, `core/subjectcompare/subjectcompare_test.go`, `core/subjectcompare/invariants_test.go`. Skill: `add-match-rule`.
Do: D-5 – D-8; T-7 then T-4; in `invariants_test.go`, `groups()` appends `p.Samples` when set and `propertyPools` gains `asOf: {year(1817), pt.Date(datevaluetest.About(1817, 0, 0)), pt.Date(datevaluetest.Before(1818, 0, 0)), pt.Date(datevaluetest.After(1816, 0, 0))}`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/valuecompare/... ./core/propertycompare/... ./core/subjectcompare/... ./core/recordlinks/... ./core/graphalign/... ./core/database/promotealign/...` passes with no golden change.

**STEP-5 — The shortlist reaches an as-of event**
Files: `core/shortlist/shortlist.go`, `shortlist_test.go`.
Do: D-9; T-5.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/shortlist/... ./core/graphalign/... ./core/database/promotealign/...` passes.

**STEP-6 — The lifespan reads as-ofs**
Files: `core/subjectprofile/subjectprofile.go`, `core/subjectprofile/lifeevent_test.go`, `core/subjectprofile/lifespan_test.go`, `core/database/evidencelayer/evidencelayer.go`, `core/database/promotealign/profiles.go`.
Do: D-10; T-6.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/subjectprofile/... ./core/database/evidencelayer/... ./core/database/promotealign/...` passes.

**STEP-7 — Docs and version**
Files: `docs/seeded-vocabulary.md`, `docs/matching-model.md`, `.agents/skills/add-match-rule/SKILL.md`, `docs/deployment-plan/spike-16/completed.md`, `docs/deployment-plan/spike-16/deployment-plan.md` (S16-40 row), this plan (status), `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj`.
Do: §3.2 adds `as_of  date  a day the event was known to be under way; cardinality multiple; locked on event; new catalogs only (S16-40)` and drops "(or best single date)" from `date`; §3.3 adds `event  as_of  # date; multiple; locked (S16-40)` and moves `event_picture` to 6; the coexistence paragraph lists `as_of` among the event date Properties and adds "use `as_of` for a day a record shows the event under way, without saying when it began or ended (an obituary's 'of Town Y'); several may sit on one event". `matching-model.md`: the pair row (line 76) adds "and reads `as_of` against the other side's period: a sample whose window misses it conflicts, one inside a period closed on both ends agrees". `matching-model.md` line 212 (`alignment.Shortlist.Dated.event.Date`) adds "an event with only as-ofs is filed as an open reach". `add-match-rule`: line 54's recipe lists `subject.Periods.<kind>.<lead>.Start`, `.End` and `.Samples`; line 36 says "a derived key or a period member (start, end or samples)"; line 30's "period property" stays true. Then `rg -n 'Start\` and \`.End' .agents docs` finds no recipe that omits `.Samples`. Bump the version to the next minor after `VERSION` on the branch's base (0.17.0 → 0.18.0 at `14fbfca`): `VERSION`, `core/version.go` `Version`, every `MARKETING_VERSION` line. Then the Definition of done.
Check: links resolve; `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-40-event-as-of-property.md` passes; `scripts/check-pr.sh` prints `check-pr: PASS`.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/subjectvocab/subjectvocab_test.go` `TestSeedProductValues`; `vocabkey_test.go` `TestVocabKeysMatchSeed` | `{"as_of", "As of", propertymeta.ValueTypeDate, propertymeta.CardinalityMultiple, "event", 5, true, nil, false}`; `event_picture` → 6; `PropertyAsOf` seeded | AC-1.1, D-1 |
| T-2 | Go | `core/autoreconcile/dates_test.go` `TestDateReconcile` | cardinality `multiple`: "two as-ofs both kept": `date(1, 1990, ip(1), ip(10))`, `date(2, 2015, ip(2), ip(10))` → `want: {{1}, {2}}`, `StateMultiple`; "an as-of year folds into a day": `date(1, 1990, nil, nil)`, `date(2, 1990, ip(1), ip(10))` → `want: {{1, 2}}`, `StateMerged`, `shown` 10 JAN 1990, `folded: {1}` | AC-2.1, AC-2.2, D-11 |
| T-3 | Go | `core/subjectcompare/subjectcompare_test.go` `TestRulesRole`, `TestCountsUnder`, `TestLead`, `TestMeta`; `core/matchregistry/subject_test.go` | event `as_of` → lead `date`, `RolePeriodMember`; `CountsUnder(event, as_of)` → false; `Lead` → `date`; `Meta` → `as_of`; the registry claims `as_of` once, as a period key; `TestSubjectSectionMatchesSeed` checks `as_of` is bound to event and is a date | D-4 |
| T-4 | Go | `core/subjectcompare/subjectcompare_test.go` `TestCompare` (event rows; constant `asOf = vocabkey.PropertyAsOf`; `year(…)`, `pt.Date(datevaluetest.Before(y, 0, 0))`, `pt.Date(datevaluetest.After(y, 0, 0))`) | Rows (`sim`, `ev`, check): AC-3.1 `0, 0, is(date, unknown, noVals, 0)`; AC-3.2 `0, -3, is(date, conflict, rel, -3)` plus a check that the speaking A is 1990 and B reads "Before 1985" (`datevalue.CompactDisplay`); AC-3.3, AC-3.7, AC-3.8, AC-3.9 `0, -3, is(date, conflict, rel, -3)`; AC-3.4 `0.55, 1.1, is(date, partial, rel, 1.1)` plus speaking relation `valuecompare.Contains` and speaking A 1817 (as AC-2.5); AC-3.5, AC-3.6, AC-3.10 `0, 0, is(date, unknown, noVals, 0)`; "swapped": AC-3.2 with A and B exchanged → `0, -3`, conflict; "extremes decide": A as-ofs `year(1986 + i%14)` for i in 0…998 and `year(1970)` · B 1985 – 2000 → `0, -3`, conflict; "a negative as-of is ignored": A `pt.Neg(year(1970))` · B 1985 – 2000 → `0, 0`, unknown; "ABT widens the pick": A `pt.Date(datevaluetest.About(1990, 0, 0))` and `year(1990)` · B start 1993 → `0, -3`, conflict, speaking A 1990, in both value orders; "extremes set the strength": A 1983, 1990, 2002 · B 1985 – 2000 → partial from `near` (not 1990's `contains`), the same in every value order; "a tie decided by the sort": A 1989, 1990, `datevaluetest.Between(1990, 0, 0, 2000, 0, 0)` · B 1990 – 1991 → the same `sim` and `ev` in every value order | AC-3.1, AC-3.2, AC-3.3, AC-3.4, AC-3.5, AC-3.6, AC-3.7, AC-3.8, AC-3.9, AC-3.10, AC-3.11, D-5, D-6, D-7, D-8 |
| T-5 | Go | `core/shortlist/shortlist_test.go` `TestKeys` | a hand-built `subjectcompare.Values{PropertyEventType: {pt.Term("residence")}, PropertyAsOf: {pt.Date(datevaluetest.YMD(1990, 0, 0))}}` → the same index and lookup keys as `event(1, "residence", datevaluetest.After(1990, 0, 0)).v`; with no as-of and no date → no date keys (today) | AC-3.12, D-9 |
| T-7 | Go | `core/valuecompare/datewindow_test.go` `TestSampleExtremes` *(new)*; `core/propertycompare/propertycompare_test.go` `TestBetter` *(new)* | ends (1990, 1990), (1985, 1985), BEF 1995 (open first), AFT 1980 (open last) → `endsFirst` 1 (1985), `startsLast` 0 (1990; BEF's open first skipped); none closed → -1, -1; equal ends → the lower index. `Better`: an agree beats a partial; equal outcomes → higher similarity; swapping arguments never makes both true | D-6, D-7 |
| T-6 | Go | `core/subjectprofile/lifeevent_test.go` `TestLifeEventOf`; `lifespan_test.go` `TestLifespanFromEvents` | `LifeEventOf(…, vocabkey.PropertyDate, matchregistry.Default().Subject.Periods[vocabkey.Event][vocabkey.PropertyDate])`: "every date, in key order" keeps `Dates {d1, d2, d3}` and gains `PropertyAsOf: in(autoreconcile.Value{Date: d4}, false)` → `Samples {d4}`; lifespan: a death 1900 and a residence as-of 1880 → the span runs 1880 – 1900; a birth event carrying only an as-of 1850 and a death 1900 → the window's start is not fixed by 1850 (it is the span's first day less `MaxYears`, as with no birth) | AC-4.1, D-10 |

AC-1.2, AC-1.3, AC-1.4 and AC-2.3 are covered by the manual check: they are generic paths (the composer menu and editor, create-only Install, the seed text, `multiple` marks) tested today for other Properties.

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `TestInvariants` (subjectcompare), `TestKnobInventoryMatchesRegistry`, the `graphalign` goldens, `subject_section_test.go`'s metas pin, the `RolePeriodEnd` rename's readers.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none expected)
- [ ] Sweep (`RolePeriodEnd` → `RolePeriodMember`): each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none)
- [ ] No goldens changed
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Domain docs updated: docs/seeded-vocabulary.md (§3.2, §3.3, coexistence), docs/matching-model.md (pair row, Samples row); add-match-rule skill
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Create a new project. Open Properties: As of is listed (date, Multiple, locked, bound to Event, after End date). Date's and End date's descriptions name As of.
2. Open an image Citation in the composer, choose an Event Subject. The Property menu lists As of; its editor offers As stated, About, Before, After and Range.
3. Make two Sources: an obituary Citation saying As of 10 Jan 1990 on a residence of X, and a directory Citation saying As of 10 Feb 2015 on a residence of X. The Evidence graph cards show the values with no conflict mark.
4. Promote the second Source's records against the first's: the residences are proposed together, and the date line in the proposal's explanation is not a conflict. Add a third Source whose residence of X has End date 1985: Promote shows a date conflict with the 1990 record.
5. Open the Event page: the Date row reads as an undated event does today (S16-44 shows the as-ofs).
6. Open a project created before this build: Properties has no As of.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A test elsewhere restates the event bindings or the date metas | STEP-1 and STEP-3 run those packages; restating tests read the registry (`BindingsForType`) or `subjectcomparetest.Metas` |
| An as-of-only event, filed open, widens Promote's candidate lists | Same reach as a `BEF` / `AFT` date today; the TieCap and TopK bounds hold |

**Stop and report if:**

- T-2's "two as-ofs both kept" or "an as-of year folds into a day" fails in STEP-2 (the reconciler needs a code change, which is Out).
- Any `graphalign` or `promotealign` golden changes in STEP-4 or STEP-5.
- `TestInvariants` fails once `as_of` is in its groups (D-7's combining breaks an invariant the period rule keeps).
- `propertycompare.Compare` of a sample against a stand-in does not report `different` for AC-3.2, AC-3.3, AC-3.8 or AC-3.9 (the window rule is not the comparer's relation).

## 12. Open questions

None.

## 13. PR

**Title:** S16-40 — An event records As of dates, and matching reads them as bounds
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-40-event-as-of-property.md`.
