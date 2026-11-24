# Catalog query layer

**Status:** idea only — not roadmapped. What is left after Spike 16's slice 6g ([design](../deployment-plan/spike-16/catalog-query-layer.md)) took the Source delete, the `CatalogLastUpdated.swift` split and the effects memo (2026-11-24). No user-visible change; pull it in when a feature next changes that code.

## Swift mutations beside a write's effects

After S16-70 a Source delete reaches the Swift query cache only through the engine's `WriteEffects.deleted`. Other writes still send a client mutation beside their effects: `.createdSource` and `.changedSourceType` (the Sources list's new row, the Source types list's `usedBy`, a Source page's suggested rows), `.deletedSourceType` (the Source types list's row removal, the last user of `CatalogQueryPatch.row`'s `removes:` closure; after S16-70 it is one `Deleted` line on `source_types` and the `.deleted(entity)` patch), and a field relabel or delete (`.updatedMetadataField`, `.deletedMetadataField`, S14-17), which marks every visited Source page stale. Each could become a registry line, as the delete did, once the engine reports what the mutation names. (S13-37 plan.)
