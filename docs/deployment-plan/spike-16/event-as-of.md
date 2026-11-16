# Event as-of dates (Spike 16, Batch 5)

A feature doc for [Batch 5](deployment-plan.md#batch-5--event-as-of-dates). It holds the shape; the PR order is the [map](deployment-plan.md#pr-map), and the decisions binding every PR are the batch's [working rules](deployment-plan.md#batch-5--event-as-of-dates).

## Problem (dogfood, 2026-11-16)

A record often shows that a lasting fact held on one day without saying when it began or ended. An obituary of 10 Jan 1990 says the deceased was "survived by X of Town Y": X's residence in Town Y was under way on 10 Jan 1990. That is not "the residence happened on 10 Jan 1990".

Today the event has three date Properties ([`seeded-vocabulary.md` §3.2](../../seeded-vocabulary.md#32-properties)): `date` (when it happened), and `start_date` / `end_date` (when a span began and ended). None of them fits an attestation:

- On `date`, two attestations of one residence (an obituary in 1990 and a directory in 2015) are two answers to "when did this happen?". `date` is single-valued, so the event reads `mixed`, and Promote scores a date conflict between the two records ([`matching-model.md`](../../matching-model.md), `subject.Weights.event.date`).
- As `start_date = BEF 10 JAN 1990` and `end_date = AFT 10 JAN 1990`, both ends are open, so `subjectcompare` `period()` builds no stand-in date, and the event is undated on every list (`valuecompare.DateKeyOf` refuses a date with both ends open).

## Shape

**A fourth event date Property, `as_of` ("As of").** Same value type (`date`), same `DateValue`, same `observations.value_date_id`. A DateValue stays one genealogical moment ([`structured-date-model.md`](../../structured-date-model.md)): an as-of is a moment at which the event was under way. It is not a new DateValue kind.

- **Multiple.** Several as-ofs sit on one event without competing; the auto-reconciler keeps each distinct one (`autoreconcile` `StateMultiple`, [conclusion-reconciliation §8](../../conclusion-reconciliation.md#8-cardinality)). Nested ones still fold (`1990` into `10 JAN 1990`).
- **On every event.** Bound to `event` and locked, like the other three. Nothing hides it on an instantaneous type (no per-event-type binding exists).
- **Exact or About, a point or a range.** Before and After belong to a start or an end; the composer does not offer them on an as-of.

## The dating envelope

Every consumer asks one question of an event: what span and which points does it assert? One pure helper in `core/valuecompare` (beside `DateEnds`, `Earliest`, `Latest`) answers it from the kept or recorded values of the four Properties. The helper lands with its first reader (S16-41); every later reader calls it.

- **Occurrence.** A `date` wins, as today: the event happened then. The other three do not move it.
- **Bounds.** The earliest closed `start_date` is the low bound; the latest closed `end_date` is the high bound. A missing one is open.
- **Samples.** Each as-of with both ends closed is a sample: a window of days at least one of which the event was under way. An as-of with an open end (a `BEF` or `AFT` written outside the composer) is not a sample and is skipped, as the lifespan skips open dates.
- **Known span.** From the earliest of the low bound and the samples to the latest of the high bound and the samples. Without a start, the low side is open beyond the earliest sample; without an end, the high side is open beyond the latest one.

| Recorded | Known span | Drawn as |
| --- | --- | --- |
| `start_date` 1990, `end_date` 2015 | 1990 – 2015 | closed span (today) |
| `as_of` 10 Jan 1990 | 10 Jan 1990 | a point, open both sides |
| `as_of` 10 Jan 1990 and 10 Feb 2015 | 10 Jan 1990 – 10 Feb 2015 | span, open both sides |
| `start_date` 1985, `as_of` 10 Jan 1990 | 1985 – 10 Jan 1990 | span, open after |
| `as_of` 1990, `end_date` 2015 | 1990 – 2015 | span, open before |
| `date` 1990 | 1990 | the occurrence (today) |

**Matching reads samples, not occurrences** (user, 2026-11-16). Two as-ofs never conflict with each other. An as-of conflicts only with the other side's closed start after it or closed end before it, and agrees when it falls inside the other side's closed bounds. The 1990 obituary record and the 2015 directory record of one residence therefore meet in Promote with no date conflict.

**Derived, never written.** The envelope is read, not stored. Nothing writes `start_date` or `end_date` from as-ofs; the researcher's start and end stay theirs.

## What stays later

[`ideas/event-as-of-followups.md`](../../ideas/event-as-of-followups.md): as-of on a Place's period, hiding as-of on instantaneous event types, a notice when an as-of falls outside the researcher's own start or end, and the one-off backfill of `as_of` into an existing catalog.
