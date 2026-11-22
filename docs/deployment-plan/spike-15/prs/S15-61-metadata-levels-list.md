# S15-61 — Metadata levels are one declared list

**Status:** Draft
**Spike / slice:** Spike 15 · Slice 11 — Citation metadata
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: a Go refactor of how the metadata stores and delete rows are built; no view draws anything different)
**Board:** —
**Depends on:** —
**Blocks:** S15-54
**Branch:** `s15-61-metadata-levels-list`
**Version bump:** none — a preparatory refactor with no change a researcher can see, no wire and no catalog change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-catalog-model`](../../../../.agents/skills/add-catalog-model/SKILL.md), [`add-catalog-delete`](../../../../.agents/skills/add-catalog-delete/SKILL.md), [`add-audit-scope`](../../../../.agents/skills/add-audit-scope/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests)
**Context:** map scope entry S15-61 ([`../deployment-plan.md`](../deployment-plan.md)); working rules "Metadata lives at four levels with one vocabulary", "One level type", "A Citation holds metadata"; map review K-5, K11-11 ([`../deployment-plan.review.md`](../deployment-plan.review.md)); [`docs/catalog-deletes.md`](../../../catalog-deletes.md); [`core/database/catalogmodel/README.md`](../../../../core/database/catalogmodel/README.md); [`docs/source-layer-data-model.md`](../../../source-layer-data-model.md) § 5.5
**Planned:** 2026-11-22 against `main` @ `cff856a` (compare with `origin/main` after `git fetch origin main`)
**Review:** — (not reviewed yet)

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

The three metadata levels (Source, Artifact, Evidence graph) are declared once, in `catalogmodel`, and both `sourcemetadata`'s stores and `deleteimpact`'s metadata rows are built from that one list. Today each level is spelled out three times: one `newStore` call in `core/database/sourcemetadata/owner.go`, one field-in-use probe in `core/database/deleteimpact/register.go`, and three facet entries in `core/database/deleteimpact/facets.go`. Nothing a researcher sees changes: every delete reports and releases the same rows, and every board reads and writes the same tables.

**Why now.** S15-54 adds the Citation as the fourth level. With the list, it adds one entry and its migration; without it, it adds a store, a probe and three facets by hand, and a missed one is a delete that leaves rows behind or a field delete that is not refused (map review K-5, K11-11).

**What stays.** The tables, the SQL each store runs, the audit change rows and their entity types, the delete notice's groups and their order, the via strings the Swift headings read, and the effects registry's metadata entries.

## 2. User stories

**US-1.** As a contributor adding a metadata level, I add one entry to `catalogmodel.MetadataLevels` and the level's tables, and `sourcemetadata` reads and writes it and every delete releases and probes it, so no level is half-wired.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | `catalogmodel.MetadataLevels` as shipped | Its levels, in order, equal `vocabkey.MetadataLevels()`: `source`, `artifact`, `graph` |
| AC-1.2 | Each entry | Its owner table is in `catalogmodel.Tables` with the entry's `Kind`; its values and layout tables are in `Tables`; `catalogmodel.FKs` holds `<values>.<owner column>` and `<layout>.<owner column>` to the owner table, and `<values>.field_id` and `<layout>.field_id` to `source_metadata_fields` |
| AC-1.3 | Each entry's parent chain | The Source entry has no parent; every other entry's parent names a level in the list and a column with an FK from the owner table to that level's owner table; following parents from any entry reaches `source` with no level repeated |
| AC-1.4 | `sourcemetadata.stores` | One store per list entry, keyed by its level, with that entry's owner column, values table and layout table |
| AC-1.5 | The store's type read for each level | Source: `SELECT t0.id, t0.source_type_id, t0.id FROM sources t0 WHERE t0.id IN (`; Artifact: `SELECT t0.id, t1.source_type_id, t1.id FROM artifacts t0 JOIN sources t1 ON t1.id = t0.source_id WHERE t0.id IN (`; graph: the same with `evidence_graphs t0` |
| AC-1.6 | A test list with a two-hop entry (`citations` → `artifacts` via `artifact_id` → `sources` via `source_id`) | The type read is `SELECT t0.id, t2.source_type_id, t2.id FROM citations t0 JOIN artifacts t1 ON t1.id = t0.artifact_id JOIN sources t2 ON t2.id = t1.source_id WHERE t0.id IN (` |

**US-2.** As a researcher, deleting a metadata field, an Artifact, an Evidence graph or a Source behaves exactly as before.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | `Impact` on a field held by two Sources, an Artifact and a graph | Groups `source_metadata.field_id` (2), `artifact_metadata.field_id` (1), `evidence_graph_metadata.field_id` (1), in that order (today's `TestImpactMetadataFieldHolders`) |
| AC-2.2 | The facet releases registered for each parent kind | Exactly the lists in D-6, in that order |
| AC-2.3 | A Source delete with a note, a value, a dismissed suggestion and a credibility assessment | The revision holds `source_note`, `source_metadata`, `source_credibility_assessment`, `source_metadata_layout`, then `source` last (today's `TestFacetReleaseAuditsSourceSide`) |
| AC-2.4 | A value cleared and a value released with its owner, at each level, marks included | They read alike in the audit (today's `TestMetadataValueAuditParity`) |
| AC-2.5 | A field delete with one dismissed layout row | The revision is `source_metadata_layout,metadata_field` (today's `TestFacetReleaseAuditsSourceSide` "metadata field delete audits per-source layout rows") |

## 3. Scope

| In | Covered by |
| --- | --- |
| `catalogmodel.MetadataLevel`, `MetadataParent` and `MetadataLevels` *(new)*, the three shipped levels | STEP-1, AC-1.1 – AC-1.3 |
| `sourcemetadata.stores` built from the list; the type read derived from the parent chain | STEP-2, AC-1.4 – AC-1.6 |
| `deleteimpact`'s three field-in-use probes built from the list | STEP-3, AC-2.1 |
| `deleteimpact`'s nine metadata facet releases built from the list | STEP-4, AC-2.2 – AC-2.5 |
| A test pinning each parent kind's facet list | STEP-4, AC-2.2 |
| `docs/catalog-deletes.md`, `core/database/catalogmodel/README.md`, `docs/source-layer-data-model.md` § 5.5 name the list | STEP-5 |

| Out | Home |
| --- | --- |
| The Citation level: its entry, migration, store, delete rows | S15-54 |
| A Citation's second parent (its graph) for the ancestor read | S15-55 (see **Next adds**) |
| Deriving the effects registry's metadata entries (`SourceScope: up(…)`) from the list | [`docs/ideas/catalog-query-layer.md`](../../../ideas/catalog-query-layer.md), a new section STEP-5 adds |
| Rewording `metadatafields.ErrInUse`'s and `metadatafields.Delete`'s doc comments, which name the three value tables | S15-54 (they become wrong when the fourth level lands, not before) |
| Swift `Level.metadataLevels`, `api/ffi/swift_vocabulary_test.go` | not planned (unchanged; the Swift mirror reads `vocabkey`, not this list) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Catalog model | `core/database/catalogmodel/model.go` `Tables`, `FKs`, `Kind` constants | Declares the six metadata tables and their FKs. Imports nothing. No notion of a metadata level |
| Catalog model doc | `core/database/catalogmodel/README.md` | Says the package "imports nothing else in `core/database`"; table row "Imports: nothing in `core/database`" |
| Level keys | `core/vocabkey/vocabkey.go` `Level`, `MetadataLevels()`, `HoldsMetadata` | Pure. `MetadataLevels()` returns `source`, `artifact`, `graph`. Imports only `slices`, `strings` |
| Stores | `core/database/sourcemetadata/owner.go` `newStore(level, ownerTable, ownerColumn, values, layout, typeIn string)`, `stores` | Three hand calls; `typeIn` passed whole per level (Source: `SELECT id, source_type_id, id FROM sources WHERE id IN (`; Artifact and graph: a one-join `a`/`s` or `g`/`s` alias form) |
| Type read user | `core/database/sourcemetadata/annotation.go` `typesIn` | Runs `st.typeIn` … `st.typeSuffix` through `sqlbatch.Query`, scans `(id, typeID, sourceID)` |
| Field-in-use probes | `core/database/deleteimpact/register.go` `inboundEdgeList` | Three hand `withTotals(joinEdge(catalogmodel.KindMetadataField, "<values>.field_id", <owner kind>, count, list), "<values>", "field_id")`, between the `sources.source_type_id` edge and `citationFormatEdge()`. The graph's list reads `COALESCE(g.ref, '')`; the others `s.ref`, `a.ref` |
| Facet releases | `core/database/deleteimpact/facets.go` `buildFacetReleases` | Hand entries: `metadataValueFacet` + owner-layout `rowFacet` for Artifact (lines 177–179) and graph (193–195); Source value (207) and layout (211–212) split by the credibility facet; three field-layout `rowFacet`s on `KindMetadataField` (213–218) |
| Value facet helper | `core/database/deleteimpact/facets.go` `metadataValueFacet(parent, table, ownerCol)` | Builds the value table's `rowFacet` with the mark columns |
| Swift via headings | `macos/App/Platform/L10n.swift` (`"artifact_metadata.field_id"` …), `api/ffi/swift_vocabulary_test.go` (reads `deleteimpact.ResourceInboundVias()`) | Keyed by the via strings; must not change |
| Tests | `core/database/sourcemetadata/sourcemetadata_test.go` `TestStoresAreRegistered` | Stores' levels equal `vocabkey.MetadataLevels()`; each store's values and layout are in `catalogmodel.Tables` with an FK on the owner column |
| Tests | `core/database/deleteimpact/pragma_test.go` `TestFacetReleaseHonesty` | Every audited CASCADE FK has exactly one release, no duplicate via |
| Tests | `core/database/deleteimpact/facets_test.go` `TestFacetReleaseAuditsSourceSide`, `TestImpactMetadataFieldHolders`, `TestMetadataValueAuditParity` | Pin the audit entity types and the field-in-use groups' order |
| Tests | `core/database/catalogmodel/pragma_test.go` `TestPragmaHonesty` | Ties `Tables` and `FKs` to SQLite |

**Precedent.** `deleteimpact`'s `originRules` → `extraGateList` (`register.go`) and `productionPlan` (`ownedPlanFrom(catalogmodel.FKs, catalogmodel.Tables)`) build `deleteimpact` rows from a declared list; copy that shape (a loop over a declared slice inside the existing builder). `TestStoresAreRegistered` is the parity test's shape; its table and FK half moves to `catalogmodel`.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | The list lives in `catalogmodel` as `var MetadataLevels []MetadataLevel` *(new)*, beside `Tables` and `FKs`, in a new file `core/database/catalogmodel/metadata.go`. `catalogmodel` imports `core/vocabkey` for the `Level` type | Both `sourcemetadata` and `deleteimpact` import `catalogmodel`; `vocabkey` is a pure leaf (stdlib only), outside `core/database`, so the README rule "imports nothing else in `core/database`" holds and no cycle is possible | The list in `sourcemetadata` — `deleteimpact` cannot import it (`sourcemetadata` → `metadatafields` → `deleteimpact`). In `vocabkey` — it holds product keys, not table names. A plain `string` level — every reader converts, and the parity test loses the type |
| D-2 | `MetadataLevel` fields: `Level vocabkey.Level`, `Kind Kind` (the owner table's kind), `OwnerTable`, `OwnerColumn` (the column in the values and layout tables), `Values`, `Layout string`, `Parent *MetadataParent`. `MetadataParent` *(new)* is `{Level vocabkey.Level; Column string}`: the owner table's column that points at the parent level's owner table. The Source has `Parent: nil`; Artifact and graph have `{LevelSource, "source_id"}` | The parent is named by level, not table, so a chain (S15-54's Citation → Artifact → Source) is walked through the list instead of repeated | A parent table name — repeats the parent's own entry. A `Parents []MetadataParent` — no shipped level has two; S15-55 decides the Citation's graph side (Next adds) |
| D-3 | The field column is always `field_id` and the ref column always `ref`; they are not fields of the entry | True of every metadata table and owner table today and of S15-54's | Fields for them — configuration no level varies |
| D-4 | `sourcemetadata` builds `stores` with `buildStores(catalogmodel.MetadataLevels)` *(new)*. `newStore` takes `(levels []catalogmodel.MetadataLevel, l catalogmodel.MetadataLevel)` and derives `typeIn` with `sourcePathIn(levels, l)` *(new)*: aliases `t0` for the owner and `t1`, `t2` and on for each parent in turn; the last alias is `sources`; text exactly as AC-1.5 and AC-1.6. A parent level missing from the list panics at init | One derivation for every depth, so S15-54's two-hop path needs no special case; a bad list fails at start, never at a query | A per-level `TypeIn` string on the entry — SQL in `catalogmodel`, and the path stated twice |
| D-5 | `deleteimpact` builds the field-in-use probes with `metadataFieldEdges()` *(new)*, which returns one `withTotals(joinEdge(…))` per list entry, in list order, spliced at the same spot in `inboundEdgeList` (`metadataFieldEdges()...`). Via `<values>.field_id`; count `SELECT COUNT(*) FROM <values> WHERE field_id = ?`; list `SELECT o.id, COALESCE(o.ref, '') FROM <values> m JOIN <owner> o ON o.id = m.<owner column> WHERE m.field_id = ? ORDER BY COALESCE(o.ref, '') COLLATE NOCASE LIMIT ?` | Same via strings, same group order, same rows. `COALESCE` for every level because the graph's `ref` is nullable; for a NOT NULL ref it is the same value and order | A per-level ref expression — configuration for one nullable column |
| D-6 | `deleteimpact` builds the metadata facets with `metadataLevelFacets()` *(new)*: per list entry, in list order, the value facet (parent `Kind`), the owner-layout `rowFacet` (parent `Kind`, via `<layout>.<owner column>`), and the field-layout `rowFacet` (parent `KindMetadataField`, via `<layout>.field_id`). It is spliced once in `buildFacetReleases`, after the Source section and before the Property bindings, replacing the nine hand entries. `metadataValueFacet` takes a `catalogmodel.MetadataLevel`. Resulting order per parent: **Artifact** `evidence_graph_artifacts.artifact_id`, `sources.primary_artifact_id`, `artifact_metadata.artifact_id`, `artifact_metadata_layout.artifact_id`; **graph** `citations.graph_id`, `evidence_graph_artifacts.graph_id`, `evidence_graph_metadata.graph_id`, `evidence_graph_metadata_layout.graph_id`; **Source** `source_notes.source_id`, `evidence_graphs.source_id`, `source_credibility_assessments.source_id`, `source_metadata.source_id`, `source_metadata_layout.source_id`; **field** `source_metadata_layout.field_id`, `artifact_metadata_layout.field_id`, `evidence_graph_metadata_layout.field_id` | One splice point, so S15-54 adds no facet line. The only order change is a Source's value facet moving after the credibility facet: the two touch different tables, and audit readers group a revision's changes by entity, not by position | Splicing per kind at today's three spots — S15-54 would splice a fourth by hand, the hand-wiring this PR removes |
| D-7 | Parity and honesty of the list are tested in `catalogmodel` (`TestMetadataLevels` *(new)*, pure, no catalog). `TestStoresAreRegistered` keeps only "one store per list entry with that entry's names"; its table and FK checks move to `TestMetadataLevels` | The list is checked where it is declared; `TestPragmaHonesty` already ties `Tables` and `FKs` to SQLite | Checking the list against SQLite again — duplicates `TestPragmaHonesty` |
| D-8 | `deleteimpact` gains `TestMetadataFacetOrder` *(new)* pinning `facetReleasesFor(kind)` vias for the four kinds in D-6 and the `KindMetadataField` inbound vias | The refactor's promise is "same rows"; the existing tests check sets, not the registry | Relying on the existing set-based tests alone |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `core/database/catalogmodel/metadata.go` *(new)* `MetadataLevel`, `MetadataParent`, `MetadataLevels` | file / type / var | `catalogmodel.Tables`, `FKs` (`model.go`) | Extends that package with its third declared list; a separate file keeps `model.go` the table and FK mirror of SQLite |
| `sourcemetadata.buildStores`, `sourcePathIn` *(new)* | func | `sourcemetadata.newStore` | `newStore` stays and takes the entry; `sourcePathIn` replaces the three hand `typeIn` strings |
| `deleteimpact.metadataFieldEdges`, `metadataLevelFacets` *(new)* | func | `extraGateList`'s loop over `originRules` | Same shape: a loop over a declared slice in the existing builder |
| `catalogmodel` `TestMetadataLevels` *(new)* in `core/database/catalogmodel/metadata_test.go` *(new)* | test | `sourcemetadata` `TestStoresAreRegistered` | Its table/FK half moves here (D-7) |
| `sourcemetadata` `TestSourcePathIn` *(new)* | test | — (no test pins `typeIn` today) | — |
| `deleteimpact` `TestMetadataFacetOrder` *(new)* in `pragma_test.go` | test | `TestFacetReleaseHonesty` | That test checks coverage, not order |

**Builds on.** `catalogmodel` as the declared model both policy packages read ([`add-catalog-model`](../../../../.agents/skills/add-catalog-model/SKILL.md)); `deleteimpact`'s `rowFacet`, `joinEdge`, `withTotals` ([`add-catalog-delete`](../../../../.agents/skills/add-catalog-delete/SKILL.md)); the `originRules` loop.
**Deletes.** The three hand `newStore` calls and their `typeIn` strings in `owner.go`; the three hand metadata `joinEdge`s in `register.go`; the nine hand metadata facet entries in `facets.go`; the table and FK loop of `TestStoresAreRegistered`; "three inbound probes" in `docs/catalog-deletes.md`.
**Next adds.** S15-54 adds `{LevelCitation, KindCitation, "citations", "citation_id", "citation_metadata", "citation_metadata_layout", &MetadataParent{LevelArtifact, "artifact_id"}}` and gets its store, type read (AC-1.6), field-in-use probe and three facets. S15-55 reads a level's ancestors by walking `Parent`; the Citation's graph is a second parent, which S15-55 adds as a field of `MetadataLevel` when it plans its read. The effects cleanup in **Out** derives `SourceScope` from the same chain.

### Reach

None — no new path into existing code, no new state reachable; the same three levels reach the same code.

### Scale

None — no write, list or loop changes at run time. The list is read once at package init (`stores`, `init`'s `buildFacetReleases`) or once per process (`inboundEdgeList`'s `sync.OnceValue`); each statement it builds is the one built today.

### Edges

- **Assumptions.** `releaseFacets` runs a kind's facets in registry order, and none of a metadata level's facets depends on another facet of its kind having run first (they touch different tables; the owner row is deleted after all of them). `TestFacetReleaseHonesty` requires each via to appear once; D-6's vias are today's. Swift's headings and `ResourceInboundVias` key on `<values>.field_id`, unchanged (`swift_vocabulary_test.go`). `typesIn` scans three columns in the order `(owner id, source type id, source id)`; `sourcePathIn` keeps it. Package init order: `catalogmodel` initializes before `sourcemetadata` and `deleteimpact`, so `MetadataLevels` is set when `stores` and `facetReleaseList` are built.
- **Neighbors.** A Source delete: the same five facets run, the value facet now after credibility (D-6); `TestFacetReleaseAuditsSourceSide` checks the set and that `source` is last, both unchanged. An Artifact, graph and field delete: same order (T-3).
- **Removed inputs.** None — no input is removed; a level missing from the list is a test failure (T-1), not a silent gap.
- **Real data.** None — no table, seed or configuration drives a rule here.
- **Untrusted size.** None — the list is code.

### Schema

None — no catalog change. `TestPragmaHonesty` stays as is.

### Go core

| Package | Change |
| --- | --- |
| `core/database/catalogmodel` | `metadata.go` *(new)*, sketch below. `MetadataLevels` holds Source, Artifact, graph in that order |
| `core/database/sourcemetadata` | `owner.go`: `var stores = buildStores(catalogmodel.MetadataLevels)`; `newStore(levels, l)`; `sourcePathIn(levels, l) string`. `store`'s fields and every other SQL string are unchanged |
| `core/database/deleteimpact` | `register.go`: `metadataFieldEdges()` replaces the three hand edges in place. `facets.go`: `metadataLevelFacets()` replaces the nine hand entries (D-6); `metadataValueFacet(l catalogmodel.MetadataLevel)` |

```go
// metadata.go (new)
type MetadataParent struct {
	Level  vocabkey.Level
	Column string // owner table column pointing at the parent level's owner table
}

type MetadataLevel struct {
	Level       vocabkey.Level
	Kind        Kind
	OwnerTable  string
	OwnerColumn string // in Values and Layout
	Values      string
	Layout      string
	Parent      *MetadataParent // nil for the Source
}

var MetadataLevels = []MetadataLevel{
	{Level: vocabkey.LevelSource, Kind: KindSource, OwnerTable: "sources", OwnerColumn: "source_id",
		Values: "source_metadata", Layout: "source_metadata_layout"},
	{Level: vocabkey.LevelArtifact, Kind: KindArtifact, OwnerTable: "artifacts", OwnerColumn: "artifact_id",
		Values: "artifact_metadata", Layout: "artifact_metadata_layout",
		Parent: &MetadataParent{Level: vocabkey.LevelSource, Column: "source_id"}},
	{Level: vocabkey.LevelGraph, Kind: KindEvidenceGraph, OwnerTable: "evidence_graphs", OwnerColumn: "graph_id",
		Values: "evidence_graph_metadata", Layout: "evidence_graph_metadata_layout",
		Parent: &MetadataParent{Level: vocabkey.LevelSource, Column: "source_id"}},
}
```

Errors: none new. `sourcePathIn` panics with `"sourcemetadata: level <l> has parent <p> not in the list"` when a parent level has no entry, or when the chain does not end at `sources` within `len(levels)` hops.

### FFI

None — no RPC or message changes.

### macOS

None — no Swift change.

### Strings

None — no copy changes; the via-keyed headings keep their keys.

## 7. Steps

**STEP-1 — Declare the list**
Files: `core/database/catalogmodel/metadata.go` *(new)*, `core/database/catalogmodel/metadata_test.go` *(new)*. Skill: `add-catalog-model`.
Do: add the types and `MetadataLevels` as in § 6. Add `TestMetadataLevels` (T-1).
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/catalogmodel/` passes.

**STEP-2 — Build the stores from the list**
Files: `core/database/sourcemetadata/owner.go`, `core/database/sourcemetadata/sourcemetadata_test.go`.
Do: D-4. Trim `TestStoresAreRegistered` (T-2); add `TestSourcePathIn` (T-4).
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcemetadata/` passes with no other test edited.

**STEP-3 — Build the field-in-use probes from the list**
Files: `core/database/deleteimpact/register.go`. Skill: `add-catalog-delete`.
Do: D-5.
Check: `TestImpactMetadataFieldHolders`, `TestInboundTotal`, `TestInboundTotals` pass unedited; `CGO_ENABLED=1 go test -tags fts5 ./api/ffi/ -run Swift` passes (via headings).

**STEP-4 — Build the metadata facets from the list**
Files: `core/database/deleteimpact/facets.go`, `core/database/deleteimpact/pragma_test.go`. Skills: `add-catalog-delete`, `add-audit-scope`.
Do: D-6. Add `TestMetadataFacetOrder` (T-3).
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/deleteimpact/` passes with no existing test edited.

**STEP-5 — Docs**
Files: `docs/catalog-deletes.md` (line 56: "three inbound probes" → "one inbound probe per entry of `catalogmodel.MetadataLevels`"; "at the three levels" → "at every level"), `core/database/catalogmodel/README.md` (the imports line and the table row become "nothing else in `core/database`; `core/vocabkey` for the metadata level type"; add one sentence naming `MetadataLevels` and that a new level is one entry), `docs/source-layer-data-model.md` § 5.5 line 332 (the sentence "Its one store table names the level's tables and owner column, so a level adds an entry and no code." → "Its stores are built from `catalogmodel.MetadataLevels`, which `deleteimpact` reads too, so a level adds an entry and no code"), `docs/ideas/catalog-query-layer.md` (new section "The effects registry's metadata entries from the level list": the six metadata entries in `core/database/effects/registry.go` repeat each level's `up(<owner column>, "source_id")`; derive them from `catalogmodel.MetadataLevels`' parent chain when the effects registry next changes; source S15-61), `completed.md`, `deployment-plan.md` (map row), this plan (status).
Do: per the Definition of done.
Check: links resolve; `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-61-metadata-levels-list.md` passes.

Commits: one per behavior. The subject is one full imperative sentence that says what changed, ending in a period ("Declare the metadata levels once and build their stores and delete rows from the list.").

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/catalogmodel/metadata_test.go` `TestMetadataLevels` *(new)* | Table test over `MetadataLevels`: levels in order equal `vocabkey.MetadataLevels()`; per entry, owner table in `Tables` with `Kind`; values and layout in `Tables`; the four FKs of AC-1.2 in `FKs`; parent level in the list with an FK `OwnerTable.Parent.Column` → parent's `OwnerTable`; chain ends at `source` within `len(MetadataLevels)` hops | AC-1.1, AC-1.2, AC-1.3, D-7 |
| T-2 | Go | `core/database/sourcemetadata/sourcemetadata_test.go` `TestStoresAreRegistered` (trimmed) | `stores` has exactly the list's levels; each store's `level`, `ownerColumn`, `values`, `layout` equal the entry's | AC-1.4 |
| T-3 | Go | `core/database/deleteimpact/pragma_test.go` `TestMetadataFacetOrder` *(new)* | `facetReleasesFor` vias for `KindArtifact`, `KindEvidenceGraph`, `KindSource`, `KindMetadataField` equal D-6's lists; `inboundFor(KindMetadataField)` vias begin `source_metadata.field_id`, `artifact_metadata.field_id`, `evidence_graph_metadata.field_id`, then `citationFormatEdge`'s | AC-2.2, D-5, D-6 |
| T-4 | Go | `core/database/sourcemetadata/sourcemetadata_test.go` `TestSourcePathIn` *(new)* | Table: Source, Artifact, graph from `MetadataLevels` → AC-1.5 strings; a test list adding `{LevelCitation, KindCitation, "citations", "citation_id", …, &MetadataParent{LevelArtifact, "artifact_id"}}` → AC-1.6 string; a test list whose parent level is missing → panics | AC-1.5, AC-1.6, D-4 |
| T-5 | Go | existing `TestImpactMetadataFieldHolders`, `TestFacetReleaseAuditsSourceSide`, `TestMetadataValueAuditParity`, `TestFacetReleaseHonesty`, `TestOwnerTables`, `TestListWorkspaces` | Unedited, pass | AC-2.1, AC-2.3, AC-2.4, AC-2.5 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `core/database/deleteimpact` (order, honesty), `api/ffi` `swift_vocabulary_test.go` (vias), `core/database/sourcemetadata` (type read).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] No existing test other than TestStoresAreRegistered was edited
- [ ] Sweep: `rg 'three inbound probes|typeIn:|newStore\(vocabkey'` across `core/`, `.agents/`, `.cursor/rules/`, `docs/*.md` finds no stale hit; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Version bump: none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Domain docs updated: docs/catalog-deletes.md, docs/source-layer-data-model.md § 5.5, core/database/catalogmodel/README.md, docs/ideas/catalog-query-layer.md (STEP-5)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

None in the app — nothing draws differently and no behavior changes. The reviewer checks the slice Check ("the metadata, delete-impact and catalog-model tests pass unchanged; deleting a field, an Artifact, a graph and a Source reports and releases the same rows as before") through T-3 and T-5 and the diff of `facets.go` and `register.go`: every removed hand entry has its generated counterpart in D-5 or D-6.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A generated SQL string differs from today's in a way that changes rows | T-4 pins the type reads; T-5 runs today's delete and impact tests unedited |
| Package init order leaves `MetadataLevels` empty when `stores` or `facetReleaseList` is built | Go initializes an imported package first; T-2 and T-3 fail on an empty build |
| An import cycle through `catalogmodel` → `vocabkey` | `vocabkey` imports only the standard library (`core/vocabkey/vocabkey.go`) |

**Stop and report if:**

- `core/vocabkey` imports anything in the repo at your base (the cycle argument of D-1 no longer holds).
- Any existing test other than `TestStoresAreRegistered` fails and passing it needs an edit to the test.
- `buildFacetReleases` has a facet for `KindSource`, `KindArtifact` or `KindEvidenceGraph` after the Source section (D-6's splice point would then reorder it relative to the metadata facets).
- `sourcemetadata` uses `typeIn` with a column order other than `(owner id, source type id, source id)` anywhere besides `typesIn`.
- A level's owner table has no `ref` column (D-3).

## 12. Open questions

None.

## 13. PR

**Title:** S15-61 — Metadata levels are one declared list
**Body:** objective in one sentence; what shipped against US-1 and US-2; AC evidence; deviations from the plan; manual check (none in the app, and why); `Plan: docs/deployment-plan/spike-15/prs/S15-61-metadata-levels-list.md`.
