# Person page performance

**Status:** idea only — not roadmapped. Speed work on Spike 13's Person page found by the [2026-11-08 audit](../deployment-plan/spike-16/person-page-audit.md) and descoped by the user the same day: real data has not shown the cost yet. Spike 16 caps the crafted cases instead (working rule "Crafted fan-out is capped, not engineered") and gives the Timeline a render cap (S16-02). Every figure below is an estimate from reading the code; **measure before pulling any of these in.**

Related: [`spike-15/provenance-loading.md`](../deployment-plan/spike-15/provenance-loading.md) (now Spike 15, S15-27 – S15-29) (records drawn in a provenance table).

## The record links read recomputes every pair (P-9)

`persondetail.RecordLinks` (`core/database/persondetail/recordlinks.go`) runs `recordlinks.Pairs` over every graph on every load, with no memo, while holding the catalog session. At 50 graphs that is 1,225 pairs. Any write naming the person or one of their graphs evicts the key, so the next Sources visit recomputes all of it, although one changed graph can move only its 49 pairs.

The budget was met on the lightest per-pair fixture: `recordlinks_perf_test.go`'s households have four people with a name and parent links, 44 work units a pair (27.9 ms warm, 37.9 ms cold, S13-27 ship log). Estimated by `pairWork`'s rule:

| Household (5 properties a person) | Work a pair | Work a read | Share of `MaxReadWork` |
| --- | --- | --- | --- |
| The fixture: 4 people, names only | 44 | 53,900 | 5% |
| 8 people, 7 shared, parent links | about 290 | about 355,000 | 32% |
| 12 people, implied sibling links | 466–698 | 570,000–855,000 | 52–78% |

If time follows work, the richer shapes take about 185–440 ms a read, with every other pane waiting.

**Shape.** First, add a census-sized case to `TestRecordLinksBudgets` (`censusHouseholds(f, 50, size: 8 | 12)`, birth events so parent and sibling links are implied) and log `ReadWork` and the times. If it is slow, keep each pair's lines in a keyed registry entry with `DropNamedGraphs` (as `evidencelayer.Layers`), stored under both graphs and keyed by the other graph and the page entity, so a commit to one graph drops only its pairs and `MaxReadWork` charges only what is recomputed. A write that names no graph (a portrait choice) need not refresh the key at all.

## Timeline participants are sent once per event (P-8)

`api/ffi/handlers/person_detail.go` (281–287) copies a participant's whole `PersonSummary` into every `EventParticipant`, although Go composes each one once (`timeline.go`). A household that repeats across 200 census events is about 50 people sent 2,000 times, then formatted again per copy on the main thread. A crafted name of 256 KB on 2,000 events is 512 MB on the wire.

**Shape.** Send each distinct person once on `ListPersonEventsResponse` and give `EventParticipant` a person id and roles; Swift builds one card content per person. Pull it in with the next Timeline wire change.

## An unfolded Timeline lays out every card at once (P-7)

After an unfold, every shown row and its cards are laid out in one non-lazy pass (`PersonTimelineStack`), each card's `CachedThumbnail` starting its `.task` together. Card rows are a fixed height (`PVTileCardSize.compact.height`), so a row's card block could be sized without laying it out and its cards mounted only near the viewport.

The dated rows after the death marker never fold: every dated row after the person's first own burial or funeral (a later census, a probate, a memorial) is built unfolded, so a crafted person with thousands of such rows builds every one. **Shape:** fold them as the rows before the marker fold, with their own page count (user, 2026-11-09).

## The family response sends each sibling two or three times (P-23)

Siblings ship as the sibling groups' children (S16-82; S16-81 dropped the older sibling list and the parents and siblings units), and a parent in several groups ships once for each, each with a full `PersonSummary` (`api/proto/engine.proto` `SiblingGroup`; `core/database/persondetail/family.go`). The app reads the groups (`PersonFamilyContent.swift`). **Shape:** send the groups' relatives as indexes into one relatives table.

## The Persons list reads a shared life event's places once per person (S16-19 PRF-1)

`composePersons` and `lifeFacts` (`core/database/conclusionsummaries/compose.go`) call `eventLocations` for each person's birth and death events, so P persons who share one event with K location links materialize P × K links on every list fill. S16-19's review measured about 160 ms at 400 persons × 400 links, the same before and after that PR, and about four times as long for each doubling of both. `maxLifeOwners` (64) bounds what a person row keeps, not this time. **Shape:** follow each distinct life event's locations once per call and share the result across the persons that cite it.

## The large fixture cannot show participation inputs (S16-19 CON-5)

`bulkCanon` (`core/database/promotealign/bench_test.go`) files only `subject` roles, so `catalog_search_inputs` and the event key count cannot show what S16-19 D-7 adds: one recorded input per non-subject participation (a witness, an informant). The growth is linear in participation rows. **Shape:** file a share of non-subject roles in `bulkCanon`, and take new benchmark baselines in the same PR, since every figure moves.

## Prefetch a person's other sections and a hovered person (S16-29)

Spike 16 scoped a prefetch and then descoped it (user, 2026-11-16: optimizing before real data shows the cost). Switching to Family or Timeline shows the section's spinner on first open; stale-while-refreshing (S16-09) already makes a return visit instant. **Shape:** a `prefetch` role in `ConclusionPageSection.reads` for Family and Timeline, which the place warms one key at a time after the open section's keys load, and a 250 ms hover on a person tile or card that warms what its click would load. Every engine call waits in `catalogsession`'s one queue, so a prefetch in flight delays the next click by its own read: measure the warm Family and Timeline reads at the spike's real-data Scale before pulling this in. A new role must decide each `Role` policy and stay out of the section host's derived inputs (S16-03 review M-2).

## A person past 64 graphs cycles the graph cache

A person past 64 graphs cycles the `graphfill` loaded-graph and `evidencelayer.Layers` entries, so every record-links read reloads all of their graphs and rebuilds their layers; the claims read no longer loads graphs (S16-13). A batch read of the loaded graphs would mark its graphs as used first, then load the missing ones and keep them while there is room, never evicting a graph of the same batch (graphs past the cap go to the caller uncached); `GetPersonRecordLinks` would move onto it, loading layers as well. Check: with a cap of N and N + 1 graphs in a batch, a repeat read loads one graph; time cold and repeat reads at 50 and 65 graphs. Spike 13's budget is 50 graphs, under the cap. (S13-16 PRF-2 (moved out of S13-27, 2026-11-07))
