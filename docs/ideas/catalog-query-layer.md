# Catalog query layer

**Status:** idea only — not roadmapped. Split out of the retired `structural-debt.md` on 2026-11-17 (checked against the code that day). No user-visible change unless a section says so; pull one in when a feature next changes that code. The Swift query cache: how it learns about writes, and how its files are laid out.

## Two ways to learn a Source was deleted

The client-asserted `.deletedSource(id:)` mutation and the engine-reported `WriteEffects.deleted` are two ways to learn a delete; the Event and Place "entity was deleted" rule picks the engine's, and a later deleted-Sources set is one more registry line (`Deleted: onDelete(self())` on `sources`) that replaces the mutation. A field relabel or delete also reaches Source pages through a Swift mutation beside its effects (S14-17). (S13-37 plan)

## CatalogLastUpdated.swift holds four other types

`CatalogLastUpdated.swift` holds the query follows, patches and refreshes: after S16-37 moves the list merge out, most of the file is `CatalogQueryFollows`, `CatalogQueryPatch`, `CatalogQueryRefresh` and `CatalogPageValue`, not last-updated rows. Split it by type into files named for them, verbatim, when one of them next changes. (P-29, S16-26 ship log MNT-5 (rest), S16-37 review M-2)
