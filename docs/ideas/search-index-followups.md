# Search index follow-ups

**Status:** idea only — not roadmapped. Split out of the retired `structural-debt.md` on 2026-11-17 (checked against the code that day). No user-visible change unless a section says so; pull one in when a feature next changes that code. The omnibar's search index ([`add-searchable-kind`](../../.agents/skills/add-searchable-kind/SKILL.md)).

## Search kinds should own their columns

Search kinds should own their columns and locations: `KindSpec` names each field's column and carries its location builder; `Reproject` and `RebuildAll` read a projector table; a completeness test. Touch it with the next searchable kind ([`add-searchable-kind`](../../.agents/skills/add-searchable-kind/SKILL.md)). (A-31, S12-36)

## A term rename leaves handle documents on the old label

Renaming a term leaves handle search documents on the old label: the vocabulary drop (`graphcache` `DropLabels`) is in memory only, while `searchindex/handles.go` stores term labels (`sqlHandleValues` `t.label`, the event title's type label), and the `property_terms` registry entry recomputes handles only on `neutral`. A term key could become a fourth input kind. (Spike 14 map review K-12)
