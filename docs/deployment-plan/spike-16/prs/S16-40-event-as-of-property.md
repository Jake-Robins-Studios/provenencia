# S16-40 — An event records As of dates, and matching reads them as bounds

**Status:** Planned
**Spike / slice:** Spike 16 · Batch 5 · Slice 5a — An attestation is a sample
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: the composer lists the new seeded Property and dates it with today's editor, like any other date Property)
**Board:** —
**Depends on:** —
**Blocks:** S16-42
**Branch:** `s16-40-event-as-of-property`
**Version bump:** minor, the next minor at merge (0.16.1 → 0.17.0 at the planning base) — a new seeded Property in new catalogs and a matching rule a researcher sees in Promote ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-seeded-vocabulary`](../../../../.agents/skills/add-seeded-vocabulary/SKILL.md), [`add-date-value`](../../../../.agents/skills/add-date-value/SKILL.md), [`add-match-rule`](../../../../.agents/skills/add-match-rule/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`
**Context:** [`../event-as-of.md`](../event-as-of.md); working rules [Batch 5](../deployment-plan.md#batch-5--event-as-of-dates): "As of is a fourth event date Property", "New catalogs only", "On every event", "Every qualifier, no exception", "An as-of x reads as started by x, still under way at x", "A closed as-of counts toward the person's lifespan"; [`seeded-vocabulary.md` §3.2–3.3](../../../seeded-vocabulary.md#32-properties); [`conclusion-reconciliation.md` §8](../../../conclusion-reconciliation.md#8-cardinality); [`matching-model.md`](../../../matching-model.md)
**Planned:** 2026-11-16 against `main` @ `14fbfca`
**Review:** [`S16-40-event-as-of-property.review.md`](S16-40-event-as-of-property.review.md)

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
| AC-3.4 | as_of 1990 · start_date 1985, end_date 2000 | partial, relation `contains`, speaking A 1990 |
| AC-3.5 | as_of 1990 · start_date 1985 | unknown (a half-open period does not agree) |
| AC-3.6 | as_of 1990 · date 1881 | unknown, no values (today's reading: no period) |
| AC-3.7 | as_of 1990, start_date 1985 · date 1881 | conflict, as today's "After 1985" against 1881 |
| AC-3.8 | as_of BEF 1990 · start_date 1995, end_date 2000 | conflict (started by 1990) |
| AC-3.9 | as_of AFT 1990 · start_date 1970, end_date 1985 | conflict (still under way after 1990) |
| AC-3.10 | as_of 1991 · end_date 1990 | not a conflict (within the date tolerance) |
| AC-3.11 | No as-of on either side (every row of `TestCompare` today) | Unchanged |
| AC-3.12 | An event with only as-ofs | Reaches Promote's shortlist (filed as an open reach) |

**US-4.** As the engine, a closed as-of on an event a person takes part in counts toward that person's lifespan.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | `LifeEventOf` on an event with `as_of` 1990 | `Dates` includes 1990 |

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
| Lifespan input | `core/subjectprofile/subjectprofile.go` `LifeEventOf` (line 38; key list line 46) | Reads `date`, `start_date`, `end_date`; the lifespan skips open dates |
| Lifespan tests | `core/subjectprofile/lifeevent_test.go` `TestLifeEventOf` ("every date, in key order") | — |
| Docs | `docs/seeded-vocabulary.md` §3.2 (line 315; `date` "point-in-time (or best single date)"), coexistence paragraph (line 355, "Event date Properties (`date`, `start_date`, `end_date`)"), §3.3 event block (line 371); `docs/matching-model.md` pair row (line 76), `subject.Periods` rows (lines 183–184); `.agents/skills/add-match-rule/SKILL.md` | Three event date Properties |

**Precedent.** S11-48 seeded `religion` and `languages_spoken` as `multiple` Properties (a `seedProperties` row, a `seedBindings` row, a `TestSeedProductValues` case, the §3.2 / §3.3 rows). The period rule itself (`subject.Periods`, `period`, rows AC-2.5 – AC-2.13 of `TestCompare`) is the precedent for the matching change: copy its row style.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `as_of` is bound to `event` at sort order 5, locked; `event_picture` moves to 6 | The dates sit together on the Properties page; locked like the other event dates (§3.2) | Appending at 6 — splits the dates |
| D-2 | Descriptions. `as_of`: "A day the event was known to be under way, from a record made then (an obituary's \"of Town Y\", a directory's year). Not when it began, ended or happened. More than one is allowed." `date`: "Point-in-time when the event occurred. Prefer this for births, deaths, and other one-day facts. Use Start date and End date when the event lasts across a range, and As of for a day a record shows it under way." `end_date`: "When a spanned event ended. Pair with Start date; leave empty for instantaneous events that only need Date. A day the event was last seen under way is As of." | One concept, one Property; today's "best single date" and "last known" send an attestation elsewhere | Leaving the neighbours — the Properties page points two ways |
| D-3 | No qualifier rule anywhere: Go accepts any DateValue on `as_of`, the composer is unchanged | Working rule "Every qualifier, no exception" (user, 2026-11-16) | A composer chip rule — dropped by the user |
| D-4 | `subjectcompare.Period` becomes `struct{ Start, End, Samples vocabkey.PropertyKey }`; registry `Periods[Event][PropertyDate] = {Start: PropertyStartDate, End: PropertyEndDate, Samples: PropertyAsOf}`. `Rules.Role` returns `RolePeriodEnd` for `p.Samples == key` too, and `RolePeriodEnd`'s comment reads "the start, end or samples a lead reads with its period" | An as-of counts under `date` (no weight of its own) and never on its own key (`CountsUnder` false), as start and end do | A `RolePeriodSample` — a new role every `RolePeriodEnd` reader would have to learn for the same treatment |
| D-5 | `CompareProperty` keeps today's result as `base` (`propertycompare.Compare` of the two `Side`s), and when `rules.Periods[kind][key]` names `Samples` adds the sample checks of D-6; with no positive sample on either side it returns `base` unchanged | Every caller (Compare, Promote, record links) gets the rule in one place; events with no as-of keep their result bit for bit (AC-3.11) | A separate check in `Compare` beside `lifespan` — record links and any later caller of `CompareProperty` would miss it |
| D-6 | Sample check, per direction (A's samples against B, then B's against A): it runs only when the other side has no positive value for `key` (no occurrence `date`) and `period(other[p.Start], other[p.End])` builds a stand-in. Of this side's positive sample values, take at most two: the one whose last end is `valuecompare.Earliest` among the samples' closed last ends, and the one whose first end is `valuecompare.Latest` among their closed first ends (ends from `valuecompare.DateEnds`; a sample with both ends open is no sample). Each is compared with the stand-in by `propertycompare.Compare([]Value{sample}, []Value{standIn}, metas[key], value)` (sides kept: A's value on the A side) | The window rule (the event started by the window's last day and was under way on its first) is exactly "the sample's window does not overlap the other side's period", which the date comparer already reports as `different`, with its tolerance and its ABT widening (`AboutUnits`); the two extremes are the only samples that can conflict, so cost is two compares per side however many as-ofs (Scale) | A new bounds type in `valuecompare` — re-implements what the comparer does; comparing every sample — 10,000 compares per pair on crafted data |
| D-7 | Combining. First conflict wins, in order `base`, A's checks, B's checks. Else `base` when its outcome is `agree`. Else the best match among the sample checks whose stand-in is closed on both ends (`DateEnds` of the stand-in: neither end `Open`): `agree` before `partial`, then the higher similarity, A before B on a tie. Else `base` | Working rule: an as-of conflicts with a closed start after it or a closed end before it, even on a half-open period, and agrees only inside a period closed on both ends; `base` keeps today's reading of dates and periods | Letting a half-open period agree — the user ruled it out |
| D-8 | Negative as-ofs are ignored by the sample check (positive values only) | A denied attestation says nothing about bounds | Reading a negative as a conflict — no rule asks for it |
| D-9 | Shortlist: in `Keys`, for a Dated kind whose `positive(kind, d.Date, …)` list is empty, when `subject.Periods[kind][d.Date].Samples` has a positive value, the event is keyed exactly as one open reach (the `open` branch: index `…|wide` and `…|any`, lookup `…|any`, for each type key) | An as-of-only event's span is unknown both ways; an open reach meets every closed one, as a `BEF` date does today | Keying the samples' years — an event that began years before its first attestation would never be shortlisted |
| D-10 | `LifeEventOf` adds `vocabkey.PropertyAsOf` to its key list, after `PropertyEndDate` | Working rule: a closed as-of counts toward the lifespan; the lifespan already skips open dates | Reading through a helper — one key list is the existing shape |
| D-11 | Reconcile is proven by tests only: `TestDateReconcile`'s cases gain a `cardinality string` field (empty reads as `propertymeta.CardinalitySingle`) | `multiple` already keeps distinct dates and folds a wider date into a narrower one it contains; a narrower as-of implies the wider one's bounds, so the fold loses nothing | An end-to-end autoreconciler test — cardinality reaches `Reconcile` through the generic loader |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `vocabkey.PropertyAsOf` *(new)* | const | `vocabkey.PropertyEndDate` | Extends the block |
| `as_of` seed row and binding *(new)* | registry row | `religion` row | Extends `seedProperties` / `seedBindings` |
| `Period.Samples` *(new)* | field | `Period.Start`, `Period.End` | Extends the period rule the as-of belongs to |
| `samplesAgainst` *(new, unexported, `pairs.go`)* | func | `period` (same file) | Reuses `period`, `DateEnds`, `Earliest`, `Latest` and `propertycompare.Compare`; no new comparison |

**Builds on.** `add-seeded-vocabulary`; `add-match-rule` (registry knob, inventory row); the period rule (`subject.Periods`, `period`); the date comparer.
**Deletes.** None — nothing becomes dead.
**Next adds.** S16-42 reads `vocabkey.PropertyAsOf` in `conclusionsummaries` and adds the dating helper's display fields; a Place as-of ([idea](../../../ideas/event-as-of-followups.md)) is a `Periods[place][…]` entry with `Samples`.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| An event with several values on one date Property | Evidence graph marks (`EvidenceCitedPropertyMarks.conflictCounts`), conclusion detail `state` | `multiple` keys are skipped / read `multiple` today (toponym, religion); AC-2.3 |
| An event with only as-ofs | Promote's shortlist and scoring | Filed as an open reach (D-9); scored by D-5 – D-7 |
| An event with only as-ofs | Event page Date row, Events list, Timeline | Undated, as an event with no date today, until S16-42 (manual check 5) |
| `as_of` in a project's profile | `subjectcompare.Rules.CountsUnder`, `graphalign` `subjectHasValues` | Counts under `date` (D-4) |

### Scale

At the map's Scale (Batch 5: up to 20 as-ofs on an event; 10,000 crafted): the sample check is at most two date compares per side per compared pair (D-6), plus one pass over the samples to pick them. The shortlist adds no keys beyond today's open reach. The seed is one row at create time.

### Edges

- **Assumptions.** `TestInvariants` (`core/subjectcompare/invariants_test.go`) holds its invariants over the `TestCompare` rows (symmetry of outcome among them): D-6 runs both directions and D-7 is order-free up to the A-before-B tie, so a swapped pair gives the same outcome; T-4's rows run under it. `Rules.Role` assumes a key belongs to at most one lead: `as_of` only to `date`.
- **Neighbors.** Today's period rows AC-2.5 – AC-2.13 are unchanged (AC-3.11). A date within tolerance of a bound is not a conflict (AC-3.10). A half-open period bounds but does not agree (AC-3.5). An occurrence `date` keeps the as-of side to today's reading (AC-3.6, AC-3.7). `BEF` / `AFT` as-ofs bound on their closed side only (AC-3.8, AC-3.9).
- **Removed inputs.** A negative as-of contributes nothing (D-8). A folded as-of (1990 into 10 JAN 1990) keeps its record on the kept value (T-2).
- **Real data.** The registry is the only table: `Periods` has one entry; `TestKnobInventoryMatchesRegistry` runs over all of it.
- **Untrusted size.** A side's as-ofs: bounded to two compares per side (D-6), one pass to choose them; checked before any compare.

### Schema

None — seeded rows only, at create time.

### Go core

| Package | Change |
| --- | --- |
| `core/vocabkey` | `PropertyAsOf = "as_of"` *(new)* after `PropertyEndDate` |
| `core/database/subjectvocab` | `as_of` row (D-2), binding (D-1), `date` and `end_date` descriptions (D-2) |
| `core/subjectcompare` | `Period.Samples` *(new)*; `Rules.Role` (D-4); `CompareProperty` (D-5) calls `samplesAgainst(kind, key, p, a, b, metas, value) []propertycompare.Result` *(new, `pairs.go`)* per direction and combines (D-7) |
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
Do: the key; the `as_of` row and binding (D-1, D-2); the `date` and `end_date` descriptions (D-2); `event_picture` → 6. T-1: the `TestSeedProductValues` case, `event_picture`'s expected order 6, `vocabkey.PropertyAsOf` in `TestVocabKeysMatchSeed`'s list, and the count at `subjectvocab_test.go` line 74 replaced by `len(BindingsForType("event"))`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/vocabkey/... ./core/database/subjectvocab/... ./core/onboarding/...` passes.

**STEP-2 — Prove the reconciler keeps as-ofs**
Files: `core/autoreconcile/dates_test.go`. Skill: `add-date-value`.
Do: D-11; T-2.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/autoreconcile/...` passes.

**STEP-3 — The period names its samples**
Files: `core/subjectcompare/subjectcompare.go`, `core/subjectcompare/subjectcomparetest/subjectcomparetest.go`, `core/matchregistry/subject.go`, `docs/matching-model.md`, `core/subjectcompare/subjectcompare_test.go` (`TestRulesRole`, `TestCountsUnder`). Skill: `add-match-rule`.
Do: D-4; the test metas; the registry entry; a `matching-model.md` row `subject.Periods.event.date.Samples` | `as_of` | decided (user, 2026-11-16) | "As-ofs read against the other side's period"; T-3.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/subjectcompare/... ./core/matchregistry/... ./core/database/subjectvocab/...` passes (the inventory and the metas pin).

**STEP-4 — Compare reads as-ofs against the other side's period**
Files: `core/subjectcompare/pairs.go`, `core/subjectcompare/subjectcompare.go`, `subjectcompare_test.go`. Skill: `add-match-rule`.
Do: D-5 – D-8; T-4.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/subjectcompare/... ./core/recordlinks/... ./core/graphalign/... ./core/database/promotealign/...` passes with no golden change.

**STEP-5 — The shortlist reaches an as-of event**
Files: `core/shortlist/shortlist.go`, `shortlist_test.go`.
Do: D-9; T-5.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/shortlist/... ./core/graphalign/...` passes.

**STEP-6 — The lifespan reads as-ofs**
Files: `core/subjectprofile/subjectprofile.go`, `lifeevent_test.go`.
Do: D-10; T-6.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/subjectprofile/... ./core/database/evidencelayer/... ./core/database/promotealign/...` passes.

**STEP-7 — Docs and version**
Files: `docs/seeded-vocabulary.md`, `docs/matching-model.md`, `.agents/skills/add-match-rule/SKILL.md`, `completed.md`, `../deployment-plan.md` (S16-40 row), this plan (status), `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj`.
Do: §3.2 adds `as_of  date  a day the event was known to be under way; cardinality multiple; locked on event; new catalogs only (S16-40)` and drops "(or best single date)" from `date`; §3.3 adds `event  as_of  # date; multiple; locked (S16-40)` and moves `event_picture` to 6; the coexistence paragraph lists `as_of` among the event date Properties and adds "use `as_of` for a day a record shows the event under way, without saying when it began or ended (an obituary's 'of Town Y'); several may sit on one event". `matching-model.md`: the pair row (line 76) adds "and reads `as_of` against the other side's period: a sample whose window misses it conflicts, one inside a period closed on both ends agrees". `add-match-rule`: one line under the period rule that a period may name `Samples`, checked in `CompareProperty`. Bump the version (0.16.1 → 0.17.0, or the next minor after `main`'s `VERSION`): `VERSION`, `core/version.go` `Version`, every `MARKETING_VERSION` line. Then the Definition of done.
Check: links resolve; `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-40-event-as-of-property.md` passes; `scripts/check-pr.sh` prints `check-pr: PASS`.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/subjectvocab/subjectvocab_test.go` `TestSeedProductValues`; `vocabkey_test.go` `TestVocabKeysMatchSeed` | `{"as_of", "As of", date, multiple, "event", 5, true}`; `event_picture` → 6; `PropertyAsOf` seeded | AC-1.1, D-1 |
| T-2 | Go | `core/autoreconcile/dates_test.go` `TestDateReconcile` | cardinality `multiple`: "two as-ofs both kept": `date(1, 1990, ip(1), ip(10))`, `date(2, 2015, ip(2), ip(10))` → `want: {{1}, {2}}`, `StateMultiple`; "an as-of year folds into a day": `date(1, 1990, nil, nil)`, `date(2, 1990, ip(1), ip(10))` → `want: {{1, 2}}`, `StateMerged`, `shown` 10 JAN 1990, `folded: {1}` | AC-2.1, AC-2.2, D-11 |
| T-3 | Go | `core/subjectcompare/subjectcompare_test.go` `TestRulesRole`, `TestCountsUnder` | event `as_of` → lead `date`, `RolePeriodEnd`; `CountsUnder(event, as_of)` → false | D-4 |
| T-4 | Go | `core/subjectcompare/subjectcompare_test.go` `TestCompare` (new event rows, a constant `asOf = vocabkey.PropertyAsOf`; dates with `year(…)`, BEF / AFT with `pt.Date(&datevalue.Value{Kind: datevalue.KindPoint, Qualifier: …, StartYear: …})`) | AC-3.1 – AC-3.10 as rows, each with `is(date, …)`; AC-3.2, AC-3.4 with a `check` func on the speaking pair (as AC-2.5); plus "extremes decide": A 999 as-ofs 1986 – 1999 and one 1970 · B 1985 – 2000 → conflict; "a negative as-of is ignored": A `pt.Neg(year(1970))` · B 1985 – 2000 → unknown | AC-3.1, AC-3.2, AC-3.3, AC-3.4, AC-3.5, AC-3.6, AC-3.7, AC-3.8, AC-3.9, AC-3.10, AC-3.11, D-5, D-6, D-7, D-8 |
| T-5 | Go | `core/shortlist/shortlist_test.go` `TestKeys` | an event of type residence with `as_of` 1990 only → the same index and lookup keys as that event with `date` `AFT 1990`; with no as-of and no date → no date keys (today) | AC-3.12, D-9 |
| T-6 | Go | `core/subjectprofile/lifeevent_test.go` `TestLifeEventOf` | "every date, in key order" gains `PropertyAsOf: d4` → `Dates` `{d1, d2, d3, d4}` | AC-4.1, D-10 |

AC-1.2, AC-1.3, AC-1.4 and AC-2.3 are covered by the manual check: they are generic paths (the composer menu and editor, create-only Install, the seed text, `multiple` marks) tested today for other Properties.

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `TestInvariants` (subjectcompare), `TestKnobInventoryMatchesRegistry`, the `graphalign` goldens, `subject_section_test.go`'s metas pin.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none expected)
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
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
- `TestInvariants` fails on a T-4 row (D-7's combining is not order-free as claimed).
- `propertycompare.Compare` of a sample against a stand-in does not report `different` for AC-3.2, AC-3.3, AC-3.8 or AC-3.9 (the window rule is not the comparer's relation).

## 12. Open questions

None.

## 13. PR

**Title:** S16-40 — An event records As of dates, and matching reads them as bounds
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-40-event-as-of-property.md`.
