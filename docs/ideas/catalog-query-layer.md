# Catalog query layer

**Status:** idea only — not roadmapped. Split out of the retired `structural-debt.md` on 2026-11-17 (checked against the code that day). No user-visible change unless a section says so; pull one in when a feature next changes that code. The Swift query cache: how it learns about writes, and how its files are laid out.

## Two ways to learn a Source was deleted

The client-asserted `.deletedSource(id:)` mutation and the engine-reported `WriteEffects.deleted` are two ways to learn a delete; the Event and Place "entity was deleted" rule picks the engine's, and a later deleted-Sources set is one more registry line (`Deleted: onDelete(self())` on `sources`) that replaces the mutation. A field relabel or delete also reaches Source pages through a Swift mutation beside its effects (S14-17). (S13-37 plan)

## CatalogLastUpdated.swift holds four other types

`CatalogLastUpdated.swift` holds the query follows, patches and refreshes: after S16-37 moves the list merge out, most of the file is `CatalogQueryFollows`, `CatalogQueryPatch`, `CatalogQueryRefresh` and `CatalogPageValue`, not last-updated rows. Split it by type into files named for them, verbatim, when one of them next changes. (P-29, S16-26 ship log MNT-5 (rest), S16-37 review M-2)

## A commit runs the same effects lookup more than once (S15-05 PRF-1)

`effects.Resolve` (`core/database/effects/resolve.go`) walks each changed row's registry paths one by one, and a path step that queries (`inbound`, `up` and the other `QueryIDs` / `QueryRow` sites in `path.go`) keeps no result, so two paths that share a step run its SQL twice. A value row (`ownedValue` in `registry.go`) runs `valueGraph(col)` for both `EvidenceGraph` and the `ReadCitations` read, and `valueMembers(col)` for both `Handles` and `HandleScope`. Since S15-05, a `date_values` change also runs `inbound("sources", "date_value_id")` for both `SourceScope` and the `ReadSourceRecords` read, Observation dates included. Each run is an indexed lookup, so the cost grows with the rows a commit writes, not the catalog: one edit pays a few extra lookups, an import of 10,000 dates pays 10,000 more for the Source step alone.

**Shape.** A memo on the per-change `walk` (`path.go`), keyed by the query text and the id, checked before each query. A `walk` lives for one change in one `Resolve`, and the catalog does not change during it, so nothing goes stale. It removes every repeat, not only the Source one. Check: a query-counting `Querier` in a test shows a Source date change issues the `sources.date_value_id` lookup once. Pull it in when the effects package is next changed, or when an import shows `Resolve` in a profile.
