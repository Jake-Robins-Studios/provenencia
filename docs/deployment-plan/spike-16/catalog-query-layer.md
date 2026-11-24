# Catalog query layer

Design for Batch 6's slice 6g (S16-68, S16-69, S16-70). Moved from `docs/ideas/catalog-query-layer.md` on 2026-11-24 and checked against the code that day. Nothing a researcher sees changes: two PRs make the code easier to change and one makes a large write cheaper. PR order and status are in the [map](deployment-plan.md#slice-6g--catalog-query-layer).

## A Source delete is learned two ways (S16-70)

*(Source type deletes join it: user, 2026-11-24.)*

**Problem.** A Source delete reaches the Swift query cache twice. `SourcePageModel.confirmResourceDelete` sends the client's own `.deletedSource(id:)` mutation (`CatalogMutation.swift`), and the engine also reports the write's `WriteEffects`. Three keys reload on the mutation (`CatalogQueryRegistry.swift`): `.sourcesList` (the whole list, or stale while hidden), `.sourceTypesList` (its `usedBy` counts) and `.sourceWorkspace` (the deleted Source's page). Handle deletes already follow the engine: the `canonical_entities` registry entry declares `Deleted: onDelete(self())`, the engine reports `WriteEffects.deleted`, and `WorkspaceSession` evicts every hidden key whose descriptor says `deletedWith: .handle`.

**Shape.** The `sources` entry in `core/database/effects/registry.go` gains `Deleted: onDelete(self())`, so a Source delete reports its id under `deleted.source` (the wire keys come from `DeletedEntities()`, so the proto does not change). Swift adds `CatalogDeletedEntity.source`. Each of the three keys takes its signal from the engine's report:

- `.sourceWorkspace` declares `deletedWith: .source`, so a hidden page for the deleted Source is evicted as a handle's page is. The Source page on screen still leaves through `leavingPage:`, as today.
- `CatalogQueryFollows` gains one slot, `.deleted(CatalogDeletedEntity)`, and `CatalogQueryPatch` one generic row-removal patch on it. `.sourcesList` declares that patch, so the deleted row drops from the engine's report instead of reloading the whole list. (The `source_holdings` re-read is not an option: a Source with no Artifacts or graphs reports none, and a delete of a Source holding either is refused.)
- `.sourceTypesList` restates `usedBy` on any `.deleted(.source)` id, by the hidden policy it already applies for `source_vocabulary`. (`.list(.counts)` was the other signal: it would also retire `.createdSource` here, but fires on every handle create, delete and merge.)

Then `.deletedSource` and its `CatalogMutationKind` go. `FakeStore.deleteSource` stays scripted (`nextWriteEffects`): what a delete reports is the Go effects test's claim, not FakeStore's.

A Source type delete goes the same way: `source_types` declares `Deleted: onDelete(self())`, Swift adds `CatalogDeletedEntity.sourceType`, and `.sourceTypesList` drops the type through the same removal patch. `.deletedSourceType` and `CatalogQueryPatch.row`'s `removes:` closure (its one user) go, and the type page applies `apply(effects, leavingPage:)`.

This is one row-removal mechanism for every delete from its own page. The next one, Spike 15's S15-70 (a Citation format delete), is one registry line and one descriptor entry.

**Stays later.** The other Swift mutations that sit beside a write's effects: `.createdSource`, `.changedSourceType`, `.createdSourceType`, `.updatedSourceType`, and the field relabel and delete mutations (`.updatedMetadataField`, `.deletedMetadataField`, S14-17) that reach Source pages. They are parked in [`ideas/catalog-query-layer.md`](../../ideas/catalog-query-layer.md).

## CatalogLastUpdated.swift holds four other types (S16-68)

**Problem.** `macos/App/Features/Workspace/Session/CatalogLastUpdated.swift` (398 lines) holds the last-updated rows (`CatalogActivity`, `CatalogLastUpdatedRow`, `CatalogLastUpdatedRows`) and four types that are not last-updated rows: `CatalogPageValue`, `CatalogQueryFollows`, `CatalogQueryPatch` and `CatalogQueryRefresh`. S16-37 already moved the list merge out (#858). (P-29, S16-26 ship log MNT-5 (rest), S16-37 review M-2.)

**Shape.** Each of the four moves, verbatim, to a file named for it in the same folder. The last-updated rows stay in `CatalogLastUpdated.swift`. No code changes, so S16-70's edits to the follows and patches read as edits, not moves.

## A commit runs the same effects lookup more than once (S16-69)

**Problem.** `effects.Resolve` (`core/database/effects/resolve.go`) walks each changed row's registry paths one by one. A path step that queries (`inbound`, `up` and the other `QueryIDs` / `QueryRow` sites in `path.go`) keeps no result, so two paths that share a step run its SQL twice. A value row (`ownedValue` in `registry.go`) runs `valueGraph(col)` for both `EvidenceGraph` and the `ReadCitations` read, and `valueMembers(col)` for both `Handles` and `HandleScope`. Since S15-05, a `date_values` change also runs `inbound("sources", "date_value_id")` for both `SourceScope` and the `ReadSourceRecords` read, Observation dates included. Each run is an indexed lookup, so the cost grows with the rows a commit writes, not with the catalog: one edit pays a few extra lookups, but an import of 10,000 dates pays 10,000 more for the Source step alone. (S15-05 PRF-1.)

**Shape.** A memo on the per-change `walk` (`path.go`), keyed by the query text and the input id, owned by one lookup method that replaces the loop `inbound`, `across` and `sqlPath` each copy; `readRowsColumn` memoises its scan before its ghost fallback. `Resolve` takes a `dbsql.Querier`, so a test counts its queries. A `walk` lives for one change in one `Resolve`, and the catalog does not change during it, so nothing goes stale. It removes every repeat, not only the Source one, and it is not a stored answer: nothing outlives the change.
