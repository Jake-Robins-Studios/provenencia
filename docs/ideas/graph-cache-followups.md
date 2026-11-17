# Graph cache follow-ups

**Status:** idea only — not roadmapped. Split out of the retired `structural-debt.md` on 2026-11-17 (checked against the code that day). No user-visible change unless a section says so; pull one in when a feature next changes that code. The engine's caches and the readers built on them ([`catalog-caches.md`](../catalog-caches.md)).

## The kinship pivots walk cached neighbours

`canonlinks.kinship` walks its pivots' cached neighbours through `deps` (`core/database/canonlinks/reader.go`), which misses a removed link whose ends are not loaded. Declaring the pivots' `FollowKeys` as the entry's `Inputs` (`graphcache.FollowKeys`, `cache.go` `Inputs`) would follow them instead. (S16-18 plan)

## Value columns repeated across readers

S14-36 shared the text, integer and boolean columns (`propertymeta.Scalar`, `scalarcols`) and the Observation row (`observationrow`). The term, entity, date, name and image columns are still repeated across `graphcache` `Value` / `TruthRow` / `EvidenceObservation`, `evidencelayer.Decode` and `conclusiondetails.Value`; a new type of those threads each by hand. (S14-36 ship log)

## Two readers pick a Place's first toponym

Two readers pick a Place's first toponym from cached Observations: the detail read through `observations.FirstTextOf` with the provenencia `toponym` Property id, and `grapheventtitles.FromStored` by Property key across origins with its own `TextRecord` loop. Folding `FromStored` onto `FirstTextOf` needs one choice of toponym Property for both (a plugin-origin `toponym` would stop titling Source event cards). (P-28, S16-30 review M-9)

## A part_of connect reads every filed link

A `part_of` connect reads every filed link of the term (`filedLinks`): 2.97 ms at 1,200 links. Walking up from the new link's `to` end would follow only the reachable chain. (S14-33 ship log)

## A two-term bridge may miss a loaded filed-link set

A two-term bridge filed mid-Done can be missing from an already-loaded filed-link set for its other term (not reproduced). (S14-22 ship log)
