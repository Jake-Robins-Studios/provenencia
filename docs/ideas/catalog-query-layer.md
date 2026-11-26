# Catalog query layer

**Status:** idea only — not roadmapped. What is left after Spike 16's slice 6g ([design](../deployment-plan/spike-16/catalog-query-layer.md)) took the Source delete, the `CatalogLastUpdated.swift` split and the effects memo (2026-11-24). No user-visible change; pull it in when a feature next changes that code.

## Swift mutations beside a write's effects

After S16-70 a Source or Source type delete reaches the Swift query cache only through the engine's `WriteEffects.deleted`. Other writes still send a client mutation beside their effects: `.createdSource` and `.changedSourceType` (the Sources list's new row and page shell, a Source page's suggested rows), and a field relabel or delete (`.updatedMetadataField`, `.deletedMetadataField`, S14-17), which marks every visited Source page stale. Each could become a registry line, as the delete did, once the engine reports what the mutation names. (S13-37 plan.)

A Source create reaches the Sources list twice: through `sourceRow()` and through the `source_holdings` re-read.

The Persons, Events and Places lists could drop a deleted handle's row through `deletedRows(_:of: .handle)` instead of an empty re-read.
