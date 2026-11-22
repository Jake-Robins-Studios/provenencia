# S15-61 — Metadata levels are one declared list

**Status:** Landed in [#943](https://github.com/Jake-Robins-Studios/provenencia/pull/943) (2026-11-22)
**Spike / slice:** Spike 15 · Slice 11 — Citation metadata
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: a Go refactor of how the metadata stores, delete rows and effects entries are built; no view draws anything different)
**Board:** —
**Depends on:** —
**Blocks:** S15-54
**Branch:** `s15-61-metadata-levels-list`
**Version bump:** none — a preparatory refactor with no change a researcher can see, no wire and no catalog change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-catalog-model`](../../../../.agents/skills/add-catalog-model/SKILL.md), [`add-catalog-delete`](../../../../.agents/skills/add-catalog-delete/SKILL.md), [`add-audit-scope`](../../../../.agents/skills/add-audit-scope/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests)
**Context:** map scope entry S15-61 ([`../deployment-plan.md`](../deployment-plan.md)); working rules "Metadata lives at four levels with one vocabulary", "One level type", "A Citation holds metadata"; map review K-5, K11-11 ([`../deployment-plan.review.md`](../deployment-plan.review.md)); [`docs/catalog-deletes.md`](../../../catalog-deletes.md); [`core/database/catalogmodel/README.md`](../../../../core/database/catalogmodel/README.md); [`docs/source-layer-data-model.md`](../../../source-layer-data-model.md) § 5.5; [`core/database/effects/README.md`](../../../../core/database/effects/README.md)
**Planned:** 2026-11-22 against `main` @ `cff856a` (compare with `origin/main` after `git fetch origin main`)
**Review:** [`S15-61-metadata-levels-list.review.md`](S15-61-metadata-levels-list.review.md) — round 2: Fits with changes / Ready with changes; every finding Fixed or Declined, M-1 answered by the user; nothing open
**Landed.** Three differences from the plan. The Status line reads "Landed in [#943](https://github.com/Jake-Robins-Studios/provenencia/pull/943)" because `check-plan-docs` rejects "Landed #943". `SourcePath`'s "goes up to" error names the entry being walked, which may differ from the level asked for (§ 6 writes `level <l>`). The `add-catalog-delete` bullet puts the metadata-level exception on the `facetRelease` instruction and adds the `metadataFieldEdges` note to the inbound-probes checklist line.

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

The three metadata levels (Source, Artifact, Evidence graph) are declared once, in `catalogmodel`. `sourcemetadata`'s stores, `deleteimpact`'s metadata rows and the effects registry's metadata entries are all built from that one list. Today each level is written out four times:

- one `newStore` call in `core/database/sourcemetadata/owner.go`;
- one field-in-use probe in `core/database/deleteimpact/register.go`;
- three facet entries in `core/database/deleteimpact/facets.go`;
- two entries, each with its Source path, in `core/database/effects/registry.go`.

Nothing a researcher sees changes. Every delete reports and releases the same rows, every board reads and writes the same tables, and every write tags the same Source scope.

**Why now.** S15-54 adds the Citation as the fourth level. With the list, it adds one entry and its migration. Without the list, it adds a store, a probe, three facets and two effects paths by hand. A missed one leaves rows behind after a delete, lets a field delete through that should be refused, or files a write under no Source (map review K-5, K11-11; user, 2026-11-22, folding the effects entries in).

**What stays.** These do not change: the tables, the SQL each store runs, the audit change rows and their entity types, the delete notice's groups and their order, the via strings the Swift headings read, and each metadata table's effects (`Entity`, `SourceScope`, `Lists`, `Search`).

## 2. User stories

**US-1.** As a contributor adding a metadata level, I add one entry to `catalogmodel.MetadataTables` plus the level's tables. `sourcemetadata` then reads and writes the level, every delete releases and probes it, and its writes scope their Source, so no level is half-wired.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | `catalogmodel.MetadataTables` as shipped | Its levels, in order, equal `vocabkey.MetadataLevels()`: `source`, `artifact`, `graph` |
| AC-1.2 | Each entry | Its owner table is in `catalogmodel.Tables` with the entry's `Kind`. Its values and layout tables are in `Tables`. `catalogmodel.FKs` holds `<values>.<owner column>` and `<layout>.<owner column>` to the owner table, and `<values>.field_id` and `<layout>.field_id` to `source_metadata_fields` |
| AC-1.3 | `catalogmodel.SourcePath(MetadataTables, l)` for each level | Source → `[source]`; Artifact → `[artifact, source]`; graph → `[graph, source]`. Each `Up.Column` has an FK from the owner table to the next entry's owner table |
| AC-1.4 | `SourcePath` on a test list with a Citation entry (`citations`, `Up{LevelArtifact, "artifact_id"}`) | `[citation, artifact, source]` |
| AC-1.5 | `SourcePath` on a test list with a missing up level, a two-entry cycle, or an entry without `Up` whose owner table is not `sources` | Errors, one per case, with the messages in § 6 |
| AC-1.6 | `sourcemetadata.stores` | One store per list entry, keyed by its level, with that entry's owner column, values table and layout table |
| AC-1.7 | The store's type read for each level | Source: `SELECT t0.id, t0.source_type_id, t0.id FROM sources t0 WHERE t0.id IN (`. Artifact: `SELECT t0.id, t1.source_type_id, t1.id FROM artifacts t0 JOIN sources t1 ON t1.id = t0.source_id WHERE t0.id IN (`. Graph: the same as Artifact with `evidence_graphs t0` |
| AC-1.8 | The type read for AC-1.4's Citation entry | `SELECT t0.id, t2.source_type_id, t2.id FROM citations t0 JOIN artifacts t1 ON t1.id = t0.artifact_id JOIN sources t2 ON t2.id = t1.source_id WHERE t0.id IN (` |
| AC-1.9 | The effects entries for each list entry's values and layout tables | `Entity` is the table name. `SourceScope` ends at `sources` (`Path.check`). Its columns are `source_id` for the Source level, `artifact_id`, `source_id` for the Artifact level, and `graph_id`, `source_id` for the graph level. The values entry has `Lists: [ListMetadataFieldUsage]` and `ListsOnCreateDelete`. Only the Source level's entries have `Search: [{DocSource, field("source_id")}]` |

**US-2.** As a researcher, deleting a metadata field, an Artifact, an Evidence graph or a Source, or editing metadata at any level, behaves exactly as before.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | `Impact` on a field held by two Sources, an Artifact and a graph | Groups `source_metadata.field_id` (2), `artifact_metadata.field_id` (1), `evidence_graph_metadata.field_id` (1), in that order (today's `TestImpactMetadataFieldHolders`) |
| AC-2.2 | The facet releases registered for each parent kind | Exactly the lists in D-6, in that order |
| AC-2.3 | A Source delete with a note, a value, a dismissed suggestion and a credibility assessment | The revision holds `source_note`, `source_metadata`, `source_credibility_assessment` and `source_metadata_layout` in any order, then `source` last (today's `TestFacetReleaseAuditsSourceSide`, which checks the set and the last entry) |
| AC-2.4 | A value cleared and a value released with its owner, at each level, marks included | They read alike in the audit (today's `TestMetadataValueAuditParity`) |
| AC-2.5 | A field delete with one dismissed layout row | The revision is `source_metadata_layout,metadata_field` (today's `TestFacetReleaseAuditsSourceSide`, subtest "metadata field delete audits per-source layout rows") |
| AC-2.6 | An Artifact's or a graph's value released with its deleted owner | The revision scopes the owner's Source (today's `TestReleasedMetadataScopesThroughDeletedOwner`) |

## 3. Scope

| In | Covered by |
| --- | --- |
| `catalogmodel.MetadataLevelTables`, `MetadataUp`, `MetadataTables` and `SourcePath` *(new)*, holding the three shipped levels | STEP-1, AC-1.1 – AC-1.5 |
| `sourcemetadata.stores` built from the list, with the type read derived through `SourcePath` | STEP-2, AC-1.6 – AC-1.8 |
| `deleteimpact`'s three field-in-use probes built from the list | STEP-3, AC-2.1 |
| `deleteimpact`'s nine metadata facet releases built from the list, and a test that pins each parent kind's facet list | STEP-4, AC-2.2 – AC-2.5 |
| The effects registry's six metadata entries built from the list | STEP-5, AC-1.9, AC-2.6 |
| Docs and skills name the list: `docs/catalog-deletes.md`, `core/database/catalogmodel/README.md`, `core/database/effects/README.md`, `docs/source-layer-data-model.md` § 5.5, the skills `add-catalog-model`, `add-catalog-delete`, `add-catalog-migration`, `add-audit-scope`, and `.cursor/rules/catalog-deletes.mdc` | STEP-6 |

| Out | Home |
| --- | --- |
| The Citation level itself: its entry, migration, store, delete rows and effects entries (the `EvidenceGraph` path K11-1 names) | S15-54 |
| A Citation's link to its graph, for the ancestor read | S15-55 (see **Next adds**) |
| `ListDraftWorkspace`'s hand check `level != LevelArtifact && level != LevelGraph` (`core/database/sourcemetadata/sourcemetadata.go`) | S15-55, which makes it take the Citation level (see **Next adds**) |
| Rewording the doc comments of `metadatafields.ErrInUse` and `metadatafields.Delete`, which name the three value tables | S15-54 (they become wrong only when the fourth level lands) |
| Swift `Level.metadataLevels` and `api/ffi/swift_vocabulary_test.go` | not planned (they stay as they are: the Swift mirror reads `vocabkey`, not this list) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Catalog model | `core/database/catalogmodel/model.go` `Tables`, `FKs`, the `Kind` constants | Declares the six metadata tables and their FKs. Imports nothing. Has no notion of a metadata level |
| Catalog model doc | `core/database/catalogmodel/README.md` | Says the package "imports nothing else in `core/database`". The table row reads "Imports: nothing in `core/database`" |
| Level keys | `core/vocabkey/vocabkey.go` `Level`, `MetadataLevels()` | Pure. `MetadataLevels()` returns `source`, `artifact`, `graph`. Imports only `slices` and `strings` |
| Stores | `core/database/sourcemetadata/owner.go` `newStore(level, ownerTable, ownerColumn, values, layout, typeIn string)`, `stores` | Three hand calls. `typeIn` is passed whole for each level. Source: `SELECT id, source_type_id, id FROM sources WHERE id IN (`. Artifact and graph: a one-join form with the aliases `a`/`s` or `g`/`s` |
| Type read user | `core/database/sourcemetadata/annotation.go` `typesIn` | The only reader of `st.typeIn`. Runs it with `st.typeSuffix` through `sqlbatch.Query` and scans `(id, typeID, sourceID)` |
| Field-in-use probes | `core/database/deleteimpact/register.go` `inboundEdgeList` | Three hand `withTotals(joinEdge(catalogmodel.KindMetadataField, "<values>.field_id", <owner kind>, count, list), "<values>", "field_id")`, between the `sources.source_type_id` edge and `citationFormatEdge()`. The graph's list reads `COALESCE(g.ref, '')`; the others read `s.ref` and `a.ref` |
| Facet releases | `core/database/deleteimpact/facets.go` `buildFacetReleases` | Hand entries: a `metadataValueFacet` and an owner-layout `rowFacet` for the Artifact (lines 175–179) and the graph (193–195). The Source's value facet (207) and layout facet (210–212) have the credibility facet between them. Three field-layout `rowFacet`s on `KindMetadataField` (213–218). No other facet of these four kinds comes after line 218 |
| Value facet helper | `core/database/deleteimpact/facets.go` `metadataValueFacet(parent, table, ownerCol)` | Builds the value table's `rowFacet` with the mark columns |
| Effects entries | `core/database/effects/registry.go` `registry`: `source_metadata`, `source_metadata_layout`, `artifact_metadata`, `artifact_metadata_layout`, `evidence_graph_metadata`, `evidence_graph_metadata_layout` (lines 358–399) | Six literals. `SourceScope`: `field("source_id")`, `up("artifact_id", "source_id")` or `up("graph_id", "source_id")`. Each values entry has `Lists: []List{ListMetadataFieldUsage}` and `ListsOnCreateDelete: true`. The two Source entries also have `Search: []SearchDoc{{Kind: DocSource, Path: field("source_id")}}` |
| Effects init | `core/database/effects/registry.go` `init` | Checks every non-skip `catalogmodel.Tables` row has a `registry` entry, validates each one, and builds `entityTable` |
| Swift via headings | `macos/App/Platform/L10n.swift` (`"artifact_metadata.field_id"` and the rest), `api/ffi/swift_vocabulary_test.go` `TestSwiftVocabularyMatchesGo` (reads `deleteimpact.ResourceInboundVias()`) | Keyed by the via strings, which must not change |
| Skills | `.agents/skills/add-catalog-model/SKILL.md` (step 5; the intro), `.agents/skills/add-catalog-delete/SKILL.md` (the "`Audited: true`" bullet), `.agents/skills/add-catalog-migration/SKILL.md` (the classify-the-FK bullet) | Teach that an audited facet is a hand `facetRelease` in `deleteimpact`. That is still true in general, but false for a metadata level once this PR lands |
| Tests | `core/database/sourcemetadata/sourcemetadata_test.go` `TestStoresAreRegistered` | The stores' levels equal `vocabkey.MetadataLevels()`. Each store's values and layout tables are in `catalogmodel.Tables` with an FK on the owner column |
| Tests | `core/database/deleteimpact/pragma_test.go` `TestFacetReleaseHonesty` | Every audited CASCADE FK has exactly one release, and no via repeats |
| Tests | `core/database/deleteimpact/facets_test.go` `TestFacetReleaseAuditsSourceSide`, `TestImpactMetadataFieldHolders`, `TestMetadataValueAuditParity` | Pin the audit entity types and the order of the field-in-use groups |
| Tests | `core/database/effects/registry_completeness_test.go` `TestEveryNonSkipTableHasAnEntry`; `core/database/effects/released_metadata_scope_test.go` `TestReleasedMetadataScopesThroughDeletedOwner` | Coverage, and a released value's Source scope |
| Tests | `core/database/catalogmodel/pragma_test.go` `TestPragmaHonesty` | Ties `Tables` and `FKs` to SQLite |

**Precedent.** These build rows from a declared list; copy their shape, a loop over a declared slice inside the existing builder:

- in `deleteimpact`, `originRules` → `extraGateList` (`core/database/deleteimpact/register.go`);
- in `deleteimpact`, `productionPlan` (`ownedPlanFrom(catalogmodel.FKs, catalogmodel.Tables)`);
- in `effects`, `init`'s loop over `catalogmodel.Tables`.

`TestStoresAreRegistered` is the shape for the parity test. Its table and FK half moves to `catalogmodel`.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | The list lives in `catalogmodel`, in a new file `core/database/catalogmodel/metadata.go`, beside `Tables` and `FKs`. The type is `MetadataLevelTables` *(new)* and the var is `MetadataTables []MetadataLevelTables` *(new)*. `catalogmodel` imports `core/vocabkey` for the `Level` type | `sourcemetadata`, `deleteimpact` and `effects` all import `catalogmodel`. `vocabkey` is a pure leaf (standard library only) outside `core/database`, so the README rule "imports nothing else in `core/database`" holds and no cycle is possible. The name says the list holds tables. `vocabkey.MetadataLevels()` stays the product key set (review M-4) | **In `sourcemetadata`:** `deleteimpact` cannot import it (`sourcemetadata` → `metadatafields` → `deleteimpact`). **In `vocabkey`:** that package holds product keys, not table names. **A plain `string` level:** every reader would convert, and the parity test would lose the type. **Naming it `MetadataLevels`:** one name for two lists |
| D-2 | `MetadataLevelTables` fields: `Level vocabkey.Level`, `Kind Kind` (the owner table's kind), `OwnerTable`, `OwnerColumn` (the column in the values and layout tables), `Values`, `Layout string`, `Up *MetadataUp`. `MetadataUp` *(new)* is `{Level vocabkey.Level; Column string}`: the owner table's column that leads toward the Source, and the level it reaches. The Source has `Up: nil`; Artifact and graph have `{LevelSource, "source_id"}` | `Up` names the one link that leads to the Source, which the type read and the audit scope follow. A Citation's graph link (S15-55) is a different relation and gets its own field, not a second "parent" (review M-2). Naming the level, not the table, lets a chain be walked through the list | **`Parents []…`:** "first is the path" would be implicit. **An up table name:** repeats the up level's own entry |
| D-3 | `OwnerTable` stays a field beside `Kind` | The SQL builders read a table name, and `catalogmodel` has no exported Kind → table lookup (`deleteimpact.tableByKind` is private and filtered by deletable kinds). T-1 ties the two fields together | Resolving the table from `Kind` (review M-5): it needs a new exported lookup to save one string per entry |
| D-4 | The field column is always `field_id`, and the ref column is always `ref`. Neither is a field of the entry | True of every metadata table and owner table today, and of S15-54's | Fields for them: configuration that no level varies |
| D-5 | `catalogmodel.SourcePath(list []MetadataLevelTables, level vocabkey.Level) ([]MetadataLevelTables, error)` *(new)* is the one walk of the chain. It returns the entries from `level` to the Source, both included, finding each up entry by a linear search for its `Level`. Its errors are in § 6. `sourcemetadata`, `effects` and T-1 call it; no package walks `Up` itself | One walk for the type read, the audit scope and the tests, and S15-55 adds its ancestor walk beside it (review M-2). It takes the list as an argument so tests can pass a two-hop list | A private walk in `sourcemetadata`: `effects` and S15-55 would need a second and a third |
| D-6 | `sourcemetadata` builds `stores` with `buildStores(catalogmodel.MetadataTables)` *(new)*. `newStore` takes `(path []catalogmodel.MetadataLevelTables)`, the `SourcePath` of its level, and derives `typeIn` with `sourcePathIn(path)` *(new)*. The aliases are `t0` for the owner and `t1`, `t2` and on for each step up; the last alias is `sources`. The rule for any depth N = `len(path)-1`: `SELECT t0.id, t<N>.source_type_id, t<N>.id FROM <path[0].OwnerTable> t0`, then for each k from 1 to N ` JOIN <path[k].OwnerTable> t<k> ON t<k>.id = t<k-1>.<path[k-1].Up.Column>`, then ` WHERE t0.id IN (`, single spaces throughout, so the text is exactly as in AC-1.7 and AC-1.8. A `SourcePath` error panics at init with that error | One derivation for every depth, so S15-54's two-hop path needs no special case. A bad list fails at start, never at a query | A `TypeIn` string on the entry: it puts SQL in `catalogmodel` and states the path twice |
| D-7 | `deleteimpact` builds the field-in-use probes with `metadataFieldEdges()` *(new)*. It returns one `withTotals(joinEdge(…))` per list entry, in list order, spliced at today's place in `inboundEdgeList`: the literal splits into `edges := []inboundEdge{…through the `sources.source_type_id` edge}`, then `edges = append(edges, metadataFieldEdges()...)`, then `edges = append(edges, citationFormatEdge(), …the rest in today's order)`, then `return edges`. Via: `<values>.field_id`. Count: `SELECT COUNT(*) FROM <values> WHERE field_id = ?`. List: `SELECT o.id, COALESCE(o.ref, '') FROM <values> m JOIN <owner> o ON o.id = m.<owner column> WHERE m.field_id = ? ORDER BY COALESCE(o.ref, '') COLLATE NOCASE LIMIT ?` | Same via strings, same group order, same rows. `COALESCE` applies to every level because the graph's `ref` is nullable. For a NOT NULL ref it gives the same value and order | A per-level ref expression: configuration for one nullable column |
| D-8 | `deleteimpact` builds the metadata facets with `metadataLevelFacets()` *(new)*. For each list entry, in list order, it builds three facets: (1) the value facet, parent `Kind`; (2) the owner-layout `rowFacet`, parent `Kind`, via `<layout>.<owner column>`; (3) the field-layout `rowFacet`, parent `KindMetadataField`, via `<layout>.field_id`. Both layout facets are `rowFacet(<parent>, <layout>, <fk column>, <layout>, "field_id", col{<owner column>, colUUID}, col{"field_id", colUUID}, col{"sort_order", colInt}, col{"dismissed", colBool})`, as today's hand entries are. `metadataValueFacet` takes a `catalogmodel.MetadataLevelTables`. The block is spliced once in `buildFacetReleases`: the literal splits into `out := []facetRelease{…through the Source section, the credibility facet included}`, then `out = append(out, metadataLevelFacets()...)`, then `out = append(out, …the Property and SubjectType bindings with their comment)`, then `return out`; the nine hand entries go. The comments above the removed entries ("layout rows are audited under field_id") move into the doc comment of `metadataLevelFacets`. The resulting order per parent is in the list after this table | One splice point, so S15-54 adds no facet line. The only order change is the Source's value facet, which moves after the credibility facet. The two touch different tables, and audit readers group a revision's changes by entity, not by position | Splicing per kind at today's three places: S15-54 would splice a fourth by hand, which is the hand-wiring this PR removes |
| D-9 | `effects` fills the six metadata entries with `metadataEffects(catalogmodel.MetadataTables, registry)` *(new)*, called first in `init`. For each list entry and each of its two tables it starts from `registry[<table>]` (the zero `Effect` when absent), panics if that entry already sets a field the builder owns (`Entity`, `SourceScope`, `Lists`, `ListsOnCreateDelete`), sets those fields, and stores the result. Owned fields: `Entity` is the table name; `SourceScope` is `field(OwnerColumn)` when `Up` is nil, and otherwise, with `path := SourcePath(list, Level)`, `cols := []string{OwnerColumn}` plus `path[i].Up.Column` for `i` from 0 to `len(path)-2` (every entry but the last, the Source), then `up(cols...)`: `up("artifact_id", "source_id")` for the Artifact, `up("citation_id", "artifact_id", "source_id")` for S15-54's Citation; the values table also gets `Lists: []List{ListMetadataFieldUsage}` and `ListsOnCreateDelete: true`. Whatever a table needs beyond these stays a partial literal in `registry`: today `"source_metadata": {Search: []SearchDoc{{Kind: DocSource, Path: field("source_id")}}}` and the same for `"source_metadata_layout"`; the four Artifact and graph literals go. The comment "A value held or released moves the field list's usedBy; an edit does not" moves to `metadataEffects` | User, 2026-11-22 (review M-1): the audit scope comes from the same chain as the type read. The extras are declared per table in the registry, where every other entry's paths live, so S15-54 adds `"citation_metadata": {EvidenceGraph: up("citation_id", "graph_id")}` and S15-56 a `Reads` the same way, with no builder change (review M-8). `init` validates the merged entries as it validates every literal | **Leaving the six literals:** the user chose to fold them in. **A per-level overlay map (`metadataSearch`):** one map per `Effect` field, applied to both tables alike; a values-only path needs builder code (M-8). **`up(OwnerColumn)` for the Source:** differs from today's `field("source_id")` only in name |
| D-10 | Parity and honesty of the list are tested in `catalogmodel`, in `TestMetadataTables` *(new)* and `TestSourcePath` *(new)*. Both are pure and need no catalog. `TestStoresAreRegistered` keeps only "one store per list entry, with that entry's names"; its table and FK checks move to `TestMetadataTables` | The list is checked where it is declared. `TestPragmaHonesty` already ties `Tables` and `FKs` to SQLite | Checking the list against SQLite again: duplicates `TestPragmaHonesty` |
| D-11 | `deleteimpact` gains `TestMetadataFacetOrder` *(new)* in a new internal-package file `core/database/deleteimpact/facet_order_test.go` (`package deleteimpact`, since `facets_test.go` is `package deleteimpact_test` and the test reads `facetReleasesFor` and `inboundFor`; review M-7, X-9). It pins the `facetReleasesFor(kind)` vias for the four kinds in D-8, and the `KindMetadataField` inbound vias | The refactor promises the same rows, and the existing tests check sets, not the registry | Relying on the set-based tests alone |

D-8's resulting order per parent:

- **Artifact:** `evidence_graph_artifacts.artifact_id`, `sources.primary_artifact_id`, `artifact_metadata.artifact_id`, `artifact_metadata_layout.artifact_id`.
- **Graph:** `citations.graph_id`, `evidence_graph_artifacts.graph_id`, `evidence_graph_metadata.graph_id`, `evidence_graph_metadata_layout.graph_id`.
- **Source:** `source_notes.source_id`, `evidence_graphs.source_id`, `source_credibility_assessments.source_id`, `source_metadata.source_id`, `source_metadata_layout.source_id`.
- **Field:** `source_metadata_layout.field_id`, `artifact_metadata_layout.field_id`, `evidence_graph_metadata_layout.field_id`.

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `core/database/catalogmodel/metadata.go` *(new)*: `MetadataLevelTables`, `MetadataUp`, `MetadataTables`, `SourcePath` | file, type, var, func | `catalogmodel.Tables` and `FKs` (`model.go`) | It extends that package with a third declared list. A separate file keeps `model.go` the mirror of SQLite's tables and FKs |
| `sourcemetadata.buildStores`, `sourcePathIn` *(new)* | func | `sourcemetadata.newStore` | `newStore` stays and takes the path. `sourcePathIn` replaces the three hand `typeIn` strings |
| `deleteimpact.metadataFieldEdges`, `metadataLevelFacets` *(new)* | func | `extraGateList`'s loop over `originRules` | Same shape: a loop over a declared slice inside the existing builder |
| `effects.metadataEffects` *(new)* | func | `effects.init`'s loop over `catalogmodel.Tables`; `ownedValue` (`registry.go`), a builder of entries | Same shape as `ownedValue`: a function that fills entries for a family of tables; the extras stay registry literals |
| `TestMetadataTables`, `TestSourcePath` *(new)* in `core/database/catalogmodel/metadata_test.go` *(new)* | test | `sourcemetadata` `TestStoresAreRegistered` | Its table and FK half moves here (D-10) |
| `sourcemetadata` `TestSourcePathIn` *(new)* | test | none (no test pins `typeIn` today) | none |
| `deleteimpact` `TestMetadataFacetOrder` *(new)* in `core/database/deleteimpact/facet_order_test.go` *(new)* | test | `TestFacetReleaseHonesty` | That test checks coverage, not order |
| `effects` `TestMetadataEffects` *(new)* in `registry_completeness_test.go` | test | `TestEveryNonSkipTableHasAnEntry` | That test checks presence, not the scope's columns or the partial literals |

**Builds on.** This PR builds on:

- `catalogmodel` as the declared model the policy packages read ([`add-catalog-model`](../../../../.agents/skills/add-catalog-model/SKILL.md));
- `deleteimpact`'s `rowFacet`, `joinEdge` and `withTotals` ([`add-catalog-delete`](../../../../.agents/skills/add-catalog-delete/SKILL.md));
- `effects`' `field`, `up` and `init` validation ([`add-audit-scope`](../../../../.agents/skills/add-audit-scope/SKILL.md));
- the `originRules` loop.

**Deletes.** The PR removes:

- the three hand `newStore` calls and their `typeIn` strings in `owner.go`;
- the three hand metadata `joinEdge`s in `register.go`;
- the nine hand metadata facet entries in `facets.go`;
- the four Artifact and graph metadata literals in `core/database/effects/registry.go`, and every field but `Search` of the two Source ones;
- the table and FK loop of `TestStoresAreRegistered`;
- "three inbound probes" in `docs/catalog-deletes.md`;
- the skills' instruction to hand-add a metadata level's facet.

**Next adds.**

- **S15-54** adds `{Level: LevelCitation, Kind: KindCitation, OwnerTable: "citations", OwnerColumn: "citation_id", Values: "citation_metadata", Layout: "citation_metadata_layout", Up: &MetadataUp{LevelArtifact, "artifact_id"}}`. That gives it a store, the type read of AC-1.8, a field-in-use probe, three facets, and effects entries scoped by `up("citation_id", "artifact_id", "source_id")`. Its values-only `EvidenceGraph` path is one partial literal, `"citation_metadata": {EvidenceGraph: up("citation_id", "graph_id")}`.
- **S15-55** adds a field to `MetadataLevelTables` for a Citation's graph link and a `catalogmodel.Ancestors` beside `SourcePath`. It also replaces `ListDraftWorkspace`'s hand level check with "the entry has `Up`".

### Reach

None: no new path into existing code and no new reachable state. The same three levels reach the same code.

### Scale

None: no write, list or loop changes at run time. The list is read once at package init (`stores`, `effects.init`, `deleteimpact`'s `init` for `buildFacetReleases`) or once per process (`inboundEdgeList`'s `sync.OnceValue`). Each statement and path it builds is the one built today.

### Edges

- **Assumptions.**
  - `releaseFacets` runs a kind's facets in registry order. No metadata facet depends on another facet of its kind running first: they touch different tables, and the owner row is deleted after all of them.
  - `TestFacetReleaseHonesty` requires each via to appear once. D-8's vias are today's.
  - Swift's headings and `ResourceInboundVias` key on `<values>.field_id`, which does not change (`TestSwiftVocabularyMatchesGo`).
  - `typesIn` scans three columns in the order `(owner id, source type id, source id)`, and `sourcePathIn` keeps that order.
  - Init order: Go initializes `catalogmodel` before `sourcemetadata`, `deleteimpact` and `effects`. Within `effects`, `init` merges `metadataEffects` before the validation loop, and no package-level var reads `registry`.
  - `up(...)` resolves a released row through its change's owner column (`TestReleasedMetadataScopesThroughDeletedOwner`). The derived paths hold the same columns.
- **Neighbors.**
  - A Source delete runs the same five facets, with the value facet now after credibility (D-8). `TestFacetReleaseAuditsSourceSide` checks the set and that `source` is last; neither changes.
  - An Artifact, graph or field delete runs its facets in the same order as today (T-3).
  - A metadata write at each level tags the same Source (T-6, AC-2.6).
- **Removed inputs.** None: no input is removed. A level missing from the list fails a test (T-1); it is not a silent gap.
- **Real data.** None: no table, seed or configuration drives a rule here.
- **Untrusted size.** None: the list is code.

### Schema

None: no catalog change. `TestPragmaHonesty` stays as it is.

### Go core

| Package | Change |
| --- | --- |
| `core/database/catalogmodel` | `metadata.go` *(new)*, sketched below. `MetadataTables` holds Source, Artifact and graph, in that order |
| `core/database/sourcemetadata` | `owner.go`: `var stores = buildStores(catalogmodel.MetadataTables)`, plus `newStore(path)` and `sourcePathIn(path) string`. `store`'s fields and every other SQL string stay as they are |
| `core/database/deleteimpact` | `register.go`: `metadataFieldEdges()` replaces the three hand edges where they stand. `facets.go`: `metadataLevelFacets()` replaces the nine hand entries (D-8), and `metadataValueFacet` takes `catalogmodel.MetadataLevelTables` |
| `core/database/effects` | `registry.go`: the four Artifact and graph metadata literals go, the two Source ones keep only `Search`, and `metadataEffects` is added and called first in `init` (D-9) |

```go
// metadata.go (new)
type MetadataUp struct {
	Level  vocabkey.Level
	Column string // owner table column pointing at Level's owner table
}

type MetadataLevelTables struct {
	Level       vocabkey.Level
	Kind        Kind
	OwnerTable  string
	OwnerColumn string // in Values and Layout
	Values      string
	Layout      string
	Up          *MetadataUp // nil for the Source
}

var MetadataTables = []MetadataLevelTables{
	{Level: vocabkey.LevelSource, Kind: KindSource, OwnerTable: "sources", OwnerColumn: "source_id",
		Values: "source_metadata", Layout: "source_metadata_layout"},
	{Level: vocabkey.LevelArtifact, Kind: KindArtifact, OwnerTable: "artifacts", OwnerColumn: "artifact_id",
		Values: "artifact_metadata", Layout: "artifact_metadata_layout",
		Up: &MetadataUp{Level: vocabkey.LevelSource, Column: "source_id"}},
	{Level: vocabkey.LevelGraph, Kind: KindEvidenceGraph, OwnerTable: "evidence_graphs", OwnerColumn: "graph_id",
		Values: "evidence_graph_metadata", Layout: "evidence_graph_metadata_layout",
		Up: &MetadataUp{Level: vocabkey.LevelSource, Column: "source_id"}},
}

func SourcePath(list []MetadataLevelTables, level vocabkey.Level) ([]MetadataLevelTables, error)
```

Test fixtures (T-1, T-4). `citationEntry` is S15-54's entry from **Next adds**, verbatim. The good list is `append(slices.Clone(MetadataTables), citationEntry)`. The bad lists, each `MetadataTables` plus one entry: missing up level → `{Level: LevelCitation, Kind: KindCitation, OwnerTable: "citations", OwnerColumn: "citation_id", Values: "x", Layout: "y", Up: &MetadataUp{"nowhere", "artifact_id"}}`; cycle → `MetadataTables[:1]` (the Source) plus two entries `{Level: "a", Up: &MetadataUp{"b", "b_id"}}` and `{Level: "b", Up: &MetadataUp{"a", "a_id"}}`, asked for `"a"`; root not `sources` → `[]MetadataLevelTables{{Level: "a", OwnerTable: "artifacts"}}`, asked for `"a"`; missing level → `MetadataTables`, asked for `LevelCitation`. The checks run in the order the table below lists them, and the first that holds is returned.

Errors: no new apperr codes. `SourcePath` returns a plain `fmt.Errorf` error in four cases:

| Case | Message |
| --- | --- |
| `level` has no entry | `catalogmodel: level <l> not in the metadata list` |
| An up level has no entry | `catalogmodel: level <l> goes up to <u>, not in the metadata list` |
| The chain runs past `len(list)` entries (a cycle) | `catalogmodel: level <l> has an up cycle` |
| The chain's entry without `Up` has an owner table other than `sources` | `catalogmodel: level <l> does not reach sources` |

`sourcemetadata` and `effects` panic at init with the returned error.

### FFI

None: no RPC or message changes.

### macOS

None: no Swift change.

### Strings

None: no copy changes. The via-keyed headings keep their keys.

## 7. Steps

**STEP-1 — Declare the list**
Files: `core/database/catalogmodel/metadata.go` *(new)*, `core/database/catalogmodel/metadata_test.go` *(new)*. Skill: `add-catalog-model`.
Do: Add the types, `MetadataTables` and `SourcePath` as sketched in § 6. Add `TestMetadataTables` and `TestSourcePath` (T-1).
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/catalogmodel/` passes.

**STEP-2 — Build the stores from the list**
Files: `core/database/sourcemetadata/owner.go`, `core/database/sourcemetadata/sourcemetadata_test.go`.
Do: Apply D-6. Trim `TestStoresAreRegistered` (T-2) and add `TestSourcePathIn` (T-4).
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcemetadata/` passes, with no other test edited.

**STEP-3 — Build the field-in-use probes from the list**
Files: `core/database/deleteimpact/register.go`. Skill: `add-catalog-delete`.
Do: Apply D-7.
Check: `TestImpactMetadataFieldHolders`, `TestInboundTotal` and `TestInboundTotals` pass unedited, and `CGO_ENABLED=1 go test -tags fts5 ./api/ffi/ -run TestSwiftVocabularyMatchesGo` passes (via headings).

**STEP-4 — Build the metadata facets from the list**
Files: `core/database/deleteimpact/facets.go`, `core/database/deleteimpact/facet_order_test.go` *(new)*. Skills: `add-catalog-delete`, `add-audit-scope`.
Do: Apply D-8. Add `TestMetadataFacetOrder` (T-3).
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/deleteimpact/` passes, with no existing test edited.

**STEP-5 — Build the effects entries from the list**
Files: `core/database/effects/registry.go`, `core/database/effects/registry_completeness_test.go`. Skill: `add-audit-scope`.
Do: Apply D-9. Add `TestMetadataEffects` (T-6).
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/effects/ ./core/database/audit/ ./core/writes/` passes, with no existing test edited.

**STEP-6 — Docs and skills**

Files and changes:

- `docs/catalog-deletes.md`, line 56: "three inbound probes" becomes "one inbound probe per entry of `catalogmodel.MetadataTables`", and "at the three levels" becomes "at every level".
- `core/database/catalogmodel/README.md`: the imports line and the table row become "nothing else in `core/database`; `core/vocabkey` for the metadata level type". Add one sentence naming `MetadataTables` and `SourcePath`, and saying that a new metadata level is one entry.
- `core/database/effects/README.md`: add one sentence saying the metadata tables' entries are built from `catalogmodel.MetadataTables` by `metadataEffects`.
- `docs/source-layer-data-model.md` § 5.5, line 332: the sentence "Its one store table names the level's tables and owner column, so a level adds an entry and no code." becomes "Its stores are built from `catalogmodel.MetadataTables`, which `deleteimpact` and `effects` read too, so a level adds an entry and no code."
- `.agents/skills/add-catalog-model/SKILL.md`: add a new step 7 after step 6 (the `effects` entry step), renumbering nothing before it: "A metadata level's values and layout tables are one `MetadataTables` entry. `sourcemetadata`, `deleteimpact` and `effects` derive the store, probe, facets and scope from it. Do not hand-add them." In the intro, after the sentence "`core/database/catalogmodel` is the hand-written list of catalog tables and foreign keys.", add "It also declares `MetadataTables`, the metadata levels' tables, and imports `core/vocabkey` for their level type."
- `.agents/skills/add-catalog-delete/SKILL.md`, the "`Audited: true`" bullet: add "except a metadata level's tables, which `metadataLevelFacets` builds from `catalogmodel.MetadataTables` (`add-catalog-model`)".
- `.agents/skills/add-catalog-migration/SKILL.md`, the classify-the-FK bullet: after the sentence that ends "or silent — see `add-catalog-delete`." (the link text in the skill), add "A metadata level's tables are one `catalogmodel.MetadataTables` entry instead (`add-catalog-model`)."
- `.agents/skills/add-audit-scope/SKILL.md`, the row-shape table's "`SourceScope: up(...)` along that chain" row: add "(a metadata level's tables: built from `catalogmodel.MetadataTables` by `effects.metadataEffects`; only extras such as `Search` or `EvidenceGraph` are a partial literal)".
- `.cursor/rules/catalog-deletes.mdc`, the "New table in the same PR" bullet: add at its end "A metadata level's tables are one `catalogmodel.MetadataTables` entry instead; `deleteimpact` builds their probes and releases."
- The completion docs: `docs/deployment-plan/spike-15/completed.md`, `deployment-plan.md` (the map row) and this plan's status.

Do: Make the changes above, per the Definition of done.
Check: links resolve, `python3 scripts/check-guidance-names.py` passes, and `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-61-metadata-levels-list.md` passes.

Commits: one per behavior. Each subject is one full imperative sentence that says what changed and ends in a period, like "Declare the metadata levels once and build their stores, delete rows and effects from the list."

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/catalogmodel/metadata_test.go` `TestMetadataTables` *(new)*, `TestSourcePath` *(new)* | `TestMetadataTables`: the levels, in order, equal `vocabkey.MetadataLevels()`; each entry meets AC-1.2; each `Up.Column` has an FK from the owner table to the up entry's owner table. `TestSourcePath` is a table test: the three shipped levels → AC-1.3; a test list with the Citation entry → AC-1.4; missing level, missing up level, cycle, root not `sources` → each § 6 message (`strings.Contains`) | AC-1.1 – AC-1.5, D-5, D-10 |
| T-2 | Go | `core/database/sourcemetadata/sourcemetadata_test.go` `TestStoresAreRegistered` (trimmed) | `stores` has exactly the list's levels. Each store's `level`, `ownerColumn`, `values` and `layout` equal the entry's | AC-1.6 |
| T-3 | Go | `core/database/deleteimpact/facet_order_test.go` *(new)* `TestMetadataFacetOrder` *(new)* | The `facetReleasesFor` vias for `KindArtifact`, `KindEvidenceGraph`, `KindSource` and `KindMetadataField` equal D-8's lists. The `inboundFor(KindMetadataField)` vias begin `source_metadata.field_id`, `artifact_metadata.field_id`, `evidence_graph_metadata.field_id`, then `ViaCitationFormats` (`core/database/deleteimpact/formatrefs.go`) | AC-2.2, D-7, D-8, D-11 |
| T-4 | Go | `core/database/sourcemetadata/sourcemetadata_test.go` `TestSourcePathIn` *(new)* | A table test: the `SourcePath` of Source, Artifact and graph from `MetadataTables` → the AC-1.7 strings, and AC-1.4's Citation path → the AC-1.8 string | AC-1.7, AC-1.8, D-6 |
| T-5 | Go | Existing tests: `TestImpactMetadataFieldHolders`, `TestFacetReleaseAuditsSourceSide`, `TestMetadataValueAuditParity`, `TestFacetReleaseHonesty`, `TestOwnerTables`, `TestListWorkspaces`, `TestEveryNonSkipTableHasAnEntry`, `TestReleasedMetadataScopesThroughDeletedOwner` | Unedited, and they pass | AC-2.1, AC-2.3, AC-2.4, AC-2.5, AC-2.6 |
| T-6 | Go | `core/database/effects/registry_completeness_test.go` `TestMetadataEffects` *(new)* | For each list entry, `registry[Values]` and `registry[Layout]` exist; `Entity` equals the table name; `SourceScope.check(<table>)` returns `"sources"`; the values entry has `Lists == [ListMetadataFieldUsage]` and `ListsOnCreateDelete`, the layout entry neither. A table test over a test registry: a partial literal setting `Search` keeps it after `metadataEffects`; one setting `SourceScope` (an owned field) panics. The Source tables' `Search` is `[{DocSource, field("source_id")}]`, the other four tables' is empty | AC-1.9, D-9 |

Must stay green: everything `scripts/check-pr.sh` runs. The suites most likely to break: `core/database/deleteimpact` (order, honesty), `api/ffi` `TestSwiftVocabularyMatchesGo` (vias), `core/database/sourcemetadata` (type read), and `core/database/effects` and `core/database/audit` (scopes).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks); off macOS it skips xcodebuild, and the PR description says so (no Swift file changes)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] No existing test other than TestStoresAreRegistered was edited
- [ ] Sweep: `rg 'three inbound probes|typeIn: +"SELECT|newStore\(vocabkey'` across `core/`, `.agents/`, `.cursor/rules/`, `docs/*.md` finds no hit (the `typeIn: typeIn,` assignment inside newStore stays and is not a hit); `rg '"(artifact|evidence_graph)_metadata(_layout)?": \{' core/database/effects/registry.go` finds no hit, and the two `source_metadata` literals hold only `Search`; `scripts/check-guidance-names.py` passes (check-pr runs it). "At the three levels" in `docs/source-layer-data-model.md` § 5.5 and `docs/citation-formats.md` stays: it is true until S15-54, which rewords it
- [ ] Version bump: none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; docs/deployment-plan/spike-15/completed.md: one short paragraph of what shipped
- [ ] Domain docs and skills updated per STEP-6
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

None in the app: nothing draws differently and no behavior changes. The reviewer checks the slice Check through T-3, T-5 and T-6, and through the diffs of `facets.go`, `register.go` and `core/database/effects/registry.go`. Every removed hand entry must have a generated counterpart in D-7, D-8 or D-9. The slice Check: the metadata, delete-impact and catalog-model tests pass unchanged, and deleting a field, an Artifact, a graph and a Source reports and releases the same rows as before.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A generated SQL string or path differs from today's in a way that changes rows or scopes | T-4 pins the type reads and T-6 the scope columns. T-5 runs today's delete, impact and scope tests unedited |
| Package init order leaves `MetadataTables` empty when `stores`, `facetReleaseList` or `registry` is built | Go initializes an imported package first. T-2, T-3 and T-6 fail on an empty build |
| An import cycle through `catalogmodel` → `vocabkey` | `vocabkey` imports only the standard library (`core/vocabkey/vocabkey.go`) |

**Stop and report if:**

- `core/vocabkey` imports anything in the repo at your base (D-1's cycle argument no longer holds).
- Any existing test other than `TestStoresAreRegistered` fails, and passing it needs an edit to the test.
- `buildFacetReleases` has a facet for `KindSource`, `KindArtifact` or `KindEvidenceGraph` after the Source section (D-8's splice point would then reorder it relative to the metadata facets).
- `sourcemetadata` uses `typeIn` anywhere besides `typesIn`, or with a column order other than `(owner id, source type id, source id)`.
- A level's owner table has no `ref` column (D-4).
- One of the six effects literals sets a field other than D-9's owned fields and `Search` (such as `Reads`, `EvidenceGraph`, `Handles` or `Deleted`); that field must then stay in the partial literal, so report which.
- A package-level var in `effects` reads `registry` before `init` runs.

## 12. Open questions

None.

## 13. PR

**Title:** S15-61 — Metadata levels are one declared list
**Body:** The objective in one sentence; what shipped against US-1 and US-2; AC evidence; deviations from the plan; the manual check (none in the app, and why); `Plan: docs/deployment-plan/spike-15/prs/S15-61-metadata-levels-list.md`.
