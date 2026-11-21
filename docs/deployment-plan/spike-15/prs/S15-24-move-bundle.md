# S15-24 — Move a bundle to another Source in the engine

**Status:** Landed in [#935](https://github.com/Jake-Robins-Studios/provenencia/pull/935) (2026-11-21)
**Spike / slice:** Spike 15 · Slice 7 — Move
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: Go, the wire, and two error strings; no view offers the move until S15-25)
**Board:** —
**Depends on:** S16-12 (landed [#800](https://github.com/Jake-Robins-Studios/provenencia/pull/800)), S16-13 (landed [#809](https://github.com/Jake-Robins-Studios/provenencia/pull/809)), S16-15 (landed [#805](https://github.com/Jake-Robins-Studios/provenencia/pull/805))
**Blocks:** S15-25
**Branch:** `s15-24-move-bundle`
**Version bump:** minor, 0.31.0 → **0.32.0** (if `main`'s `VERSION` is no longer 0.31.0 when you rebase, the next minor after it): two new RPCs old clients ignore ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-catalog-query`](../../../../.agents/skills/add-catalog-query/SKILL.md), [`add-audit-scope`](../../../../.agents/skills/add-audit-scope/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`use-catalog-session`](../../../../.agents/skills/use-catalog-session/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md)
**Rules that bind:** `.cursor/rules/catalog-queries.mdc` (each table's SQL stays in its package), `.cursor/rules/catalog-audit.mdc`, `.cursor/rules/catalog-session.mdc`, `.cursor/rules/ffi-handlers.mdc`, `.cursor/rules/go-tests.mdc` (table tests), `.cursor/rules/macos-l10n.mdc`, `.cursor/rules/versioning.mdc`
**Context:** working rules "A move is the whole bundle", "Build on Spike 16's caches", "Refused in this spike" ([`../deployment-plan.md`](../deployment-plan.md#working-rules)); [`../move-artifact-between-sources.md`](../move-artifact-between-sources.md) (the feature, "Which graphs move", "Engine notes"); [`docs/source-layer-data-model.md`](../../../source-layer-data-model.md) § 7, § 7.1; [`docs/interpretation-layer-data-model.md`](../../../interpretation-layer-data-model.md) § 4.2; [`core/database/effects/README.md`](../../../../core/database/effects/README.md); the landed plans [`S16-12-source-records.md`](../../spike-16/prs/S16-12-source-records.md) (Apply keeps an Artifact moved between two named Sources), [`S16-15-graph-catalog.md`](../../spike-16/prs/S16-15-graph-catalog.md) (D-5, D-7, AC-2.2: a graph that changes Source)
**Planned:** 2026-11-21 against `main` @ `496ffa9` (compare with `origin/main` after `git fetch origin main`; a local `main` may be stale)
**Review:** [`S15-24-move-bundle.review.md`](S15-24-move-bundle.review.md) — Fits with changes / Ready with changes, 2 rounds; every finding Fixed or Declined; nothing open

## Landed

- `VERSION` was 0.31.1 on `main`, so the bump is 0.31.1 → 0.32.0 (the header's "next minor after it").
- The `SetSourceTx` tests (T-2) are in new files `core/database/{evidencegraphs,artifacts,subjects}/setsource_test.go`, and `TestLookup` is in `core/database/sources/lookup_test.go`, not in the existing test files: `subjects_test.go` and `sources_test.go` are internal test packages and cannot import `evidencelayertest` (an import cycle). `TestExec` is in `sqlbatch_test.go` as planned.
- The three `SetSourceTx` bodies are one `database.SetSource(tx, entity, selectHead, updateHead, keys, sourceID)` in `core/database/setsource.go` (review MNT-1); each package's `SetSourceTx` is a thin wrapper that keeps its `ErrInvalid` check and its own SQL. It lives in `core/database`, not `sqlbatch`, which cannot import `database` (`UUIDJSON`, `UniqueBlobIDs`). This supersedes D-3's declined shared change-building helper; its premise was one map literal, and the copy is the whole body.
- D-10's `artifacts` entry (`Handles: onField("source_id", sqlPath(sqlHandlesForArtifact))`), `sqlHandlesForArtifact`, `sqlHandlesCitingHead` and the T-3 Artifact rows were dropped on review (CON-1, user 2026-11-21): `observations.requireSameGraph` keeps every Subject citing a bundled Artifact in the bundle, so the `subjects` entry's `Handles` already names every handle whose score moves. `sqlHandlesForSource` is unchanged.
- Not run: the manual check's step 2 (a scratch test against a dogfood copy); step 1 (`TestMove/scale`) passes.

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

The engine can move an Artifact or an Evidence graph to another Source, with everything that must travel with it: the bundle, the closure of the picked Artifact or graph over `evidence_graph_artifacts`. A read (the preflight) names the bundle, each graph's Subject count, whether the two Sources' credibility differs, and whether the old Source is left with no Artifacts or no graph; a write moves the bundle in one audited transaction that changes only `source_id` on `artifacts`, `evidence_graphs` and `subjects`. Every row keeps its id and ref, so Citations, Observations, identity claims, regions and metadata stay attached. This is the engine half of the slice-7 bar ("Bar 8"); S15-25 adds the menu items and the confirm.

**Why now.** Spike 16's Source records (S16-12), records tier (S16-13) and graph catalog (S16-15) have landed, and each Apply already handles a row that changes Source (S16-12's interleaved delete-then-insert fix, S16-15's `TestGraphIndexApplyMove`). The move is the first write that does it.

**What stays.** No view changes. Source-level values (metadata, title, date, credibility) are not read, copied or compared, except the two credibility grades the preflight reports. No migration: the composite key `(graph_id, source_id) → evidence_graphs(id, source_id)` is satisfied at commit through `PRAGMA defer_foreign_keys`. No undo, no Merge Sources, no move to a new Source (rule "Refused in this spike").

## 2. User stories

**US-1.** As S15-25's confirm, I send the picked Artifact or graph and, once the researcher picks one, the target Source, and get back everything that would move with it and the side effects to name, so the researcher sees the whole bundle before saying yes.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Source S1 holds Artifacts A1 (linked only to graph G1) and A2 (linked only to graph G2); G1 holds 3 person Subjects. `GetSourceMoveImpact` with `artifact_id` A1, no target | `source_id` S1; `artifacts` [A1]; `graphs` [G1] and `progress` [G1's row with `subject_count` 3]; `leaves_source_empty` false; `leaves_no_graph` false; both credibility keys empty, `credibility_differs` false |
| AC-1.2 | S1: G1 links A1 and A2; G2 links A2 and A3; G3 links A4. Seed A1 | `artifacts` A1, A2, A3 (by ref); `graphs` G1, G2 (list order); A4 and G3 are not in it. Seed G2 gives the same bundle |
| AC-1.3 | An Artifact A5 in no graph. Seed A5 | `artifacts` [A5]; `graphs` empty |
| AC-1.4 | A graph G4 with no Artifacts (a Source's Default graph before any Artifact) and 1 Subject. Seed G4 | `artifacts` empty; `graphs` [G4]; its `progress` row has `subject_count` 1 |
| AC-1.5 | AC-1.1's seed with target S2. S1 assessed `low_trust`, S2 not assessed | `source_credibility_key` "low_trust"; `target_credibility_key` ""; `credibility_differs` true |
| AC-1.6 | S1 not assessed, S2 assessed `standard` | Both keys as stored ("" and "standard"); `credibility_differs` false (both read as the default grade, as the reconciler scores them) |
| AC-1.7 | S1 holds only A1 and G1. Seed A1 | `leaves_source_empty` true; `leaves_no_graph` true |
| AC-1.8 | Neither `artifact_id` nor `graph_id`; both set; target equal to the bundle's Source | `sourcemove.invalid` each. A malformed id on the wire is `request.invalid_id` (the handler's `optionalID`), before the engine |
| AC-1.9 | A well-formed `artifact_id` with no row; a well-formed `target_source_id` with no row | `sourcemove.not_found`; `sources.not_found` |

**US-2.** As S15-25, I send the same seed and a target and the bundle moves in one write; the reply names what moved and the write's effects, so the app refreshes both Sources and lands on the moved Artifact under its new Source.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | AC-1.1's catalog; A1 has a Citation C1 in G1 with one Observation on Subject P1; A1 holds `artifact_metadata` "citing" = "film 7"; G1 holds `evidence_graph_metadata` "item" = "Ada Robins". `MoveToSource` seed A1, target S2 | `artifacts.source_id` of A1, `evidence_graphs.source_id` of G1 and `subjects.source_id` of G1's 3 Subjects are S2; every id and ref is unchanged; C1's `artifact_id` and `graph_id`, the Observation, the link (G1, A1) and both metadata rows are unchanged, and the metadata boards of A1 and G1 read the same values. Reply: `artifact_ids` [A1], `graph_ids` [G1], `default_graph_id` empty |
| AC-2.2 | AC-1.2's catalog. Seed G2, target S2 | A1, A2, A3, G1, G2 and their Subjects are on S2; A4 and G3 stay on S1 |
| AC-2.3 | Scale: a bundle of 5 Artifacts and 5 graphs (G1 links A1–A5; G2–G5 each link one of A2–A5) holding 100 Subjects, 20 per graph, made with `subjectstest.On` | One write, one audit revision; every row is on S2; `c.Graph().Verify()` returns nil after the write |
| AC-2.4 | AC-1.7's catalog (the bundle holds every graph of S1). Seed A1, target S2 | S1 gains one new graph named "Default" with no Artifacts and a fresh `GPH-` ref; its id is `default_graph_id`; S1 stays, with no Artifacts |
| AC-2.5 | S1's cover is `artifact` with `primary_artifact_id` A1. Seed A1, target S2 | S1's `cover_mode` is `type_icon` and `primary_artifact_id` NULL; S2's cover is unchanged. When the cover is A2 (not moved), it stays |
| AC-2.6 | AC-2.1's move | One `audit_transactions` row; `audit_transaction_scopes` has `source` rows for S1 and S2; `WriteEffects.source_scopes` holds S1 and S2; `reads` holds `evidence_graphs` [S1, S2 in either order] and `source_records` [S1, S2] |
| AC-2.7 | AC-2.1's move, with the graph index, the Source records and G1's search document built before it | `evidencegraphs.IndexOf(g).Graph(G1).SourceID` = S2 and `OfSource(S1)` lacks G1; `sources.RecordsOf(g).Artifact(A1)` returns S2's record; G1's `catalog_search_docs` row has `display_subtitle` = S2's title and `display_parent_id` = S2 |
| AC-2.8 | Handle H (made by `promotetest.Save` on P1, then an accepted claim of P2 to H) has two members: P1 in G1 on S1 with birth year 1840, and P2 on Source S3 with 1841; S1 is `low_trust`, S3 and S2 `standard`. H's node is loaded (`c.Graph()` read of H) before the move. AC-2.1's move | Before: 1840's `auto_reconciler_values` row has `reason` 'weak' (a low-trust value drops one to one, `core/autoreconcile/pipeline.go` step 5). After: `writes.Result.Effects.Handles` holds H; 1840's row has `reason` 'kept'; `c.Graph().Verify()` returns nil |
| AC-2.9 | G1 also holds a Subject R of type `source` (a reification of S1). AC-2.1's move | R's `source_id` is S2, as every Subject of G1 (user, 2026-11-21: it moves and reifies the target from then on; no warning) |
| AC-2.10 | S1 holds A1 (in G1) and A2 (in G2). Merge by moving: seed each Artifact of S1 in turn (A1, then A2), target S2; the fresh empty Default graph the last move leaves is not moved. Then `sources.Delete(tx, userID, S1)` under `r.Run` | Each move succeeds; the last leaves S1 a fresh Default graph; the delete succeeds |
| AC-2.12 | G1 also holds a Subject Q promoted to handle K (`promotetest.Save`) with no Observation; K's node is loaded before the move. AC-2.1's move | `Effects.Handles` holds K; K's member reads Source S2; `c.Graph().Verify()` returns nil |
| AC-2.11 | Any refusal of AC-1.8 or AC-1.9; a nil user | The same code as the preflight for AC-1.8 and AC-1.9 (both call `resolve`, D-6); a nil user given to `sourcemove.Move` is `sourcemove.invalid`, and over the wire an empty `user_id` is `users.invalid` (the handler's `parseUserID`); no audit revision is written; nothing moved |

## 3. Scope

| In | Covered by |
| --- | --- |
| The bundle closure, one function for the preflight and the write (`evidencegraphs.BundleOf`) | STEP-1, AC-1.1 – AC-1.4 |
| Per-table `source_id` updates that return one change per row (`artifacts.SetSourceTx`, `evidencegraphs.SetSourceTx`, `subjects.SetSourceTx`), over `sqlbatch.Exec`; `database.Tx.DeferForeignKeys`; `sources.Lookup` | STEP-2, AC-2.1 |
| An Artifact that changes Source names its Citations' handles, and a Subject that changes Source names its own handles, for recompute (effects registry) | STEP-3, AC-2.8, AC-2.12 |
| `core/database/sourcemove`: `Impact` (preflight) and `Move` (write) with deferred foreign keys, the old Source's cover cleared, `CreateDefault` on the last graph | STEP-4, AC-1.5 – AC-1.9, AC-2.1 – AC-2.5, AC-2.9 – AC-2.11 |
| Audit: both Sources scoped (from the registry, no hand-written scope) | STEP-5, AC-2.6 |
| FFI: `GetSourceMoveImpact`, `MoveToSource` | STEP-6, AC-1.*, AC-2.* |
| Two error codes and their Swift copy | STEP-7, AC-1.8, AC-1.9 |
| Version, domain docs, the feature doc's engine notes | STEP-8, STEP-9 |

| Out | Home |
| --- | --- |
| Menu items, the confirm, landing on the moved Artifact, the GoStore methods | S15-25 |
| Mapping `sourcemove.*` into `EngineErrorCode` and its parity row in `api/ffi/swift_vocabulary_test.go` | S15-25 (its first Swift caller) |
| Undo of a move; Merge Sources; moving to a new Source | not planned (rule "Refused in this spike") |
| Splitting a shared graph or refusing a bundle | not planned (`move-artifact-between-sources.md`: the whole bundle is the only option) |
| Warning about a `source` (reification) Subject in the bundle | not planned (user, 2026-11-21) |
| Comparing or warning about the two Sources' metadata | not planned (`move-artifact-between-sources.md` "Source-level values are not looked at") |
| Deleting the emptied old Source | not planned (the researcher deletes it with the existing Source delete) |
| `ON UPDATE CASCADE` on the subjects composite key | not planned (D-5) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Graph–Artifact links | `core/database/evidencegraphs/evidencegraphs.go` `list(q database.Querier, sourceID []byte)`, `sqlListBySource`, `sqlListLinksBySource` | Loads one Source's graphs in list order (name NOCASE, ref, id) with each graph's linked Artifact ids by Artifact ref, in two queries. The only per-Source graph loader (S16-15 D-5) |
| Link invariant | `evidencegraphs.go` `checkLink`, `sqlLinkSources` | A link is refused unless the graph and the Artifact are on the same Source, so a bundle never spans two Sources |
| Citation needs a link | `core/database/citations/citations.go:227` (`evidencegraphs.IsLinkedTx`); `evidencegraphs.go` `checkUnlink` | A Citation is made only on a linked (graph, Artifact); a link with Citations cannot be removed. So every graph holding a Citation on a moved Artifact is in its bundle |
| Default graph | `evidencegraphs.go` `CreateDefault(tx, sourceID)`, `DefaultName = "Default"`, `ErrLastGraph` | Inserts a Source's Default graph; only caller `sources.Create`. A Source keeps at least one graph |
| Graph row writes | `evidencegraphs.go` `Update`, `graphFields` | Updates name and description with a `rowchange.Updated("evidence_graph", …)` change. Nothing writes `source_id` |
| Artifact row writes | `core/database/artifacts/artifacts.go` `Update`, `getTx`, `GetMany(c, ids)` | Nothing writes `source_id`. `GetMany` returns Artifacts keyed by id string, missing ids omitted |
| Subject row writes | `core/database/subjects/subjects.go` `Update`, `Subject.SourceID`, `GraphID` | Nothing writes `source_id` |
| Composite key | `core/database/migrations/000055.sql` `subjects.FOREIGN KEY (graph_id, source_id) REFERENCES evidence_graphs(id, source_id)`; `evidence_graphs UNIQUE (id, source_id)`; `catalogmodel/model.go:187` | No `ON UPDATE` action, not deferrable: updating either side alone fails the immediate check. No trigger is on `artifacts`, `subjects` or `evidence_graphs` |
| Source cover | `core/database/sources/sources.go` `SetCover(tx, userID, sourceID, mode, primaryArtifactID)`, `CoverModeTypeIcon`, `Source.PrimaryArtifactID`; trigger `sources_clear_cover_on_primary_null` (`000015.sql`) | `SetCover` does not check that the Artifact is on the Source. Deleting the cover Artifact nulls the pin and the trigger resets the mode; nothing handles a cover Artifact that leaves |
| Source records | `core/database/sources/records.go` `Records`, `RecordsOf(g)`, `Record.CredibilityKey`, `Record.Credibility`, `Record.ArtifactLabels`, `RecordIndex.Source`, `RecordIndex.Artifact` | One record per Source with its grade key, its grade order relative to `standard` (0 with no assessment), and its Artifacts. Apply on `source_records` lets every named Source leave before any returns, so a moved Artifact keeps its new Source |
| Graph index | `core/database/evidencegraphs/index.go` `Index`, `IndexOf(g)`, `GraphIndex.Graph`, `OfSource`, `Progress(id).SubjectCount`; `index_test.go` `TestGraphIndexApplyMove` | Every graph with links and counts; `SubjectCount` leaves out `source` Subjects (`progress.go` `Progress.add`). Apply re-lists the Sources named under `evidence_graphs`, either order |
| Effects registry | `core/database/effects/registry.go` entries `artifacts`, `evidence_graphs`, `subjects`, `sources`, `source_credibility_assessments`; `core/database/effects/path.go` `field`, `readChangeColumn`, `uuidPair` | `field("source_id")` on a change that carries `source_id` yields the new and the old id, so `SourceScope`, `Reads` (`source_records`, `evidence_graphs`) and `Search` already name both Sources. `artifacts` has no `Handles`: only a credibility change (`source_credibility_assessments` `Handles: onField("credibility_grade_id", from("source_id", sqlPath(sqlHandlesForSource)))`) recomputes handles |
| Reconciler | `core/database/autoreconciler/autoreconciler.go` `sqlLoadCandidates` | Scores each Observation with the grade of `artifacts.source_id` of its Citation's Artifact (`RelativeOrderJoins("a.source_id")`). A move that changes an Artifact's Source changes those scores |
| Search | `core/database/searchindex/searchindex.go` `Reproject`, `ReprojectEvidenceGraph`, `ReprojectSource` | A graph document carries its Source's title and id in its display columns; a Source document rolls up its Artifacts. Both reproject from `Effect.Search` |
| Writes | `core/writes/run.go` `RunChanges`, `Run` | One transaction: changes → `effects.Resolve` → `audit.Record` → handles recompute → search reproject → commit → listeners |
| FFI precedent | `api/ffi/handlers/evidence_graphs.go` `GetEvidenceGraphUnlinkImpact`, `DeleteEvidenceGraph`; `api/ffi/handlers/artifacts.go` `artifactProto`, `thumbnailPass`; `evidenceGraphProto`; `catalog.go` `parseUserID`, `parseID`, `optionalID` | A read named `Get…Impact` and a write that returns `WriteEffects` |
| Helpers this plan extends | `evidencegraphs.SourceOf(q, graphID)` (`sqlGraphSource`; missing → `ErrInvalid`); `core/database/sqlbatch/sqlbatch.go` `Query`, `Each`, `Size = 500` (no write twin); `core/database/tx.go` `Tx` (no pragma method; no domain package issues a PRAGMA); `sources.GetTx(tx, id)` → private `getOne(q database.Querier, …)`; `catalogmodel.FKs` (seven FKs to `sources`); `api/ffi/handlers/evidence_graph_progress.go` `protoProgress`, proto `EvidenceGraphProgress` | What D-1, D-2, D-5, D-11, D-16 – D-18 build on |
| Method numbers | `api/proto/engine.proto` `Method` | Last is `METHOD_LIST_CITATION_PLACEHOLDERS = 126` |
| Error copy | `core/apperr/apperr.go` codes; `macos/App/Platform/L10n.swift` `L10n.Errors`, `message(code:params:)` | No `sourcemove.*` code |
| Tests | `core/database/effects/handle_paths_test.go` `TestHandlePaths`; `core/database/audit/scopes_test.go` `TestSourceScopes`, `scopeSeed.sourceRevisions`; `api/ffi/handlers/evidence_graphs_test.go` `newGraphFixture`, `graphFixture.createArtifact`, `createGraph`, `otherSource`; `api/ffi/handlers/write_effects_test.go` `TestEveryAuditedWriteReturnsEffects`; `core/database/evidencelayer/evidencelayertest` `New`, `NewSource`, `Person`, `Cite`, `Graph`, `Run` | Fixtures to reuse |

**Precedent.** Copy Source (`core/database/sourcecopy/sourcecopy.go` `Copy`, handler `api/ffi/handlers/sources.go` `CopySource`) is a cross-table write composed of owner-package calls inside the caller's `writes.Run`, in its own package that never calls `writes.Run`. Copy that shape for `sourcemove`. Copy `GetEvidenceGraphUnlinkImpact` / `evidencegraphs.UnlinkImpact` for the preflight's naming and handler. Do not copy `sourcecopy`'s reads of Source-level values: the move reads none.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | A seed is exactly one of an Artifact id or a graph id: `evidencegraphs.Seed{ArtifactID, GraphID []byte}` *(new)* with `func (s Seed) Valid() bool` *(new)*: true when exactly one is set and it is 16 bytes. The type and its rule live together; `BundleOf` returns `evidencegraphs.ErrInvalid` for an invalid seed, and `sourcemove`'s `resolve` (D-6) checks `Valid()` first and returns `sourcemove.ErrInvalid`, so a caller of `sourcemove` never sees `evidencegraphs.invalid`. A malformed id over the wire never reaches either: the handler's `optionalID` returns `request.invalid_id` | The feature has two entry points and one flow; a list of seeds has no caller | Repeated seeds — no caller; `oneof` in proto — the repo's requests use plain optional ids (`GetSourceWorkspace`, `ListEvidenceGraphs`) |
| D-2 | The closure lives in `evidencegraphs` as `BundleOf(q database.Querier, seed Seed) (Bundle, error)` *(new)*. It reads the seed's Source through a private `sourceOf(q, graphID)` split out of `SourceOf` (which keeps its `ErrInvalid` mapping; `sourceOf` returns `sql.ErrNoRows`) or, for an Artifact seed, `sqlArtifactSource` *(new)* = `SELECT source_id FROM artifacts WHERE id = ?` beside `sqlLinkSources`; then loads that Source with the existing `list(q, sourceID)` and walks links in memory, marking visited ids, until nothing joins. `Bundle{SourceID []byte; ArtifactIDs, GraphIDs [][]byte; TakesEveryGraph bool}`: id lists in ascending id bytes; `TakesEveryGraph` is true when every graph `list` returned is in the bundle. A seed with no row returns `sql.ErrNoRows` | `evidencegraphs` owns the links; `checkLink` keeps a bundle inside one Source, so one Source's links are the whole input; `list` is the one graph loader (S16-15 D-5). Three queries whatever the bundle. `TakesEveryGraph` comes from the same rows, so the preflight's "leaves no graph" and the write's `CreateDefault` cannot disagree (review M-1) | A recursive CTE — a second reading of the link table; the graph index — the write runs in a transaction and must read the same rows as the preflight; counting graphs after the update — a second derivation of the rule (M-1) |
| D-3 | Each table's `source_id` update lives in its package: `artifacts.SetSourceTx(tx *sql.Tx, ids [][]byte, sourceID []byte)`, `evidencegraphs.SetSourceTx(tx *sql.Tx, ids [][]byte, sourceID []byte)`, `subjects.SetSourceTx(tx *sql.Tx, graphIDs [][]byte, sourceID []byte)` (every Subject of those graphs) *(new)*, each returning `([]rowchange.Change, error)`. Each: refuses a nil tx or a `sourceID` not 16 bytes with its package's `ErrInvalid`; does not check the target exists (the caller did, D-6; the foreign key is the backstop at commit); dedupes ids with `database.UniqueBlobIDs`; returns nil and runs no query for no ids; reads `id, source_id` of its rows with `sqlbatch.Query`; skips an id with no row and a row already on `sourceID`; updates the rest with `sqlbatch.Exec` (D-16), one statement per 500-id batch; returns one `*rowchange.Updated(entity, id, {"source_id": UUIDJSON(old)}, {"source_id": UUIDJSON(new)})` per updated row (no `fixed` fields), in ascending id order. Entities: `"artifact"`, `"evidence_graph"`, `"subject"` | `.cursor/rules/catalog-queries.mdc`: a table's SQL stays in its package. Per-row changes are what the effects registry resolves (rule "A move is the whole bundle") | One UPDATE per row — up to 110 statements; SQL for all three tables in `sourcemove` — breaks the query rule; a shared change-building helper — one map literal each (review M-3, declined in part) |
| D-4 | `core/database/sourcemove` *(new)* composes the move inside the caller's `writes.Run`, like `sourcecopy`; it never calls `writes.Run`. `Move(tx *database.Tx, userID []byte, seed evidencegraphs.Seed, targetID []byte) (Result, []rowchange.Change, error)` and `Impact(c *database.Catalog, seed evidencegraphs.Seed, targetID []byte) (Report, error)` | One owner for the flow; `evidencegraphs`, `artifacts`, `subjects` and `sources` stay unaware of each other's moves | Putting it in `evidencegraphs` — `sources` imports `evidencegraphs` (`CreateDefault`), so `evidencegraphs` cannot call `sources.SetCover` |
| D-5 | `database.Tx` gains `func (t *Tx) DeferForeignKeys() error` *(new)* in `core/database/tx.go`: it runs `PRAGMA defer_foreign_keys = ON`; its comment says the check then runs at commit and SQLite clears the setting at commit or rollback. `Move` calls it before its first update | The user preferred deferred keys unless planning found a reason not to (`move-artifact-between-sources.md`); none found: no trigger on the three tables, and the check still runs at commit. Connection pragmas live in `core/database` (`catalog.go`, `migrate.go`), not in a domain package (review M-7) | A migration adding `ON UPDATE CASCADE` — a table rebuild of `subjects` for one write path; a raw PRAGMA in `sourcemove` |
| D-6 | One private `resolve(q database.Querier, seed evidencegraphs.Seed, targetID []byte) (evidencegraphs.Bundle, error)` in `sourcemove` holds every refusal: `seed.Valid()` else `ErrInvalid`; `BundleOf` (`sql.ErrNoRows` → `ErrNotFound`); when `targetID` is given: 16 bytes else `ErrInvalid`, `sources.Lookup(q, targetID)` *(new, D-17)* whose `sources.ErrNotFound` passes through, and the target differs from `Bundle.SourceID` else `ErrInvalid`. `Impact` calls it on the catalog's `*sql.DB` (`db, err := c.DB()`); `Move` calls it on `tx.Tx` with a required target (an empty target is `ErrInvalid` in `Move`). `Move`'s order: `database.RequireUserID(userID, ErrInvalid)`; an empty `targetID` → `ErrInvalid`; `resolve`; `sources.GetTx(tx.Tx, bundle.SourceID)` for the old Source's cover; `tx.DeferForeignKeys()`; `evidencegraphs.SetSourceTx`; `subjects.SetSourceTx`; `artifacts.SetSourceTx`; then D-7 and D-8. Changes are returned in that order | One derivation of each refusal for the preflight and the write (review M-1; rule "one function computes the bundle"); refusals before any write | Repeating the checks in `Impact` and `Move` |
| D-7 | When the old Source's `PrimaryArtifactID` is in `Bundle.ArtifactIDs`, `Move` calls `sources.SetCover(tx, userID, oldSourceID, sources.CoverModeTypeIcon, nil)` and appends its change | A cover must be one of the Source's own Artifacts; this is what deleting the cover Artifact already does (`ON DELETE SET NULL` and the trigger) | Leaving the pin — the old Source would show another Source's scan; moving the cover setting to the target — the target has its own cover |
| D-8 | When `Bundle.TakesEveryGraph`, `Move` calls `evidencegraphs.CreateDefault(tx, oldSourceID)` after the updates and returns the new graph's id in `Result.DefaultGraphID`. The emptied Source is never deleted. `CreateDefault`'s comment names both callers: `sources.Create` and `sourcemove.Move`, each of which has checked the user and the Source (review M-8) | Rule "A move is the whole bundle"; `ErrLastGraph` invariant; the flag comes from `BundleOf`'s own rows (D-2) | Refusing the move — the user ruled the whole bundle always moves; counting graphs after the update (review X-1, M-1) |
| D-9 | A Subject of type `source` (a reification) moves with its graph like every Subject; nothing warns (user, 2026-11-21) | Matches "Source-level values are not looked at" and keeps a merge by moving finishable | Refusing such a bundle; reporting it in the preflight |
| D-10 | The effects registry's `artifacts` entry gains `Handles: onField("source_id", sqlPath(sqlHandlesForArtifact))`, and its `subjects` entry gains `Handles: onField("source_id", membersOf)`: a loaded handle node caches each member's `source_id` (`core/database/graphcache/load.go` `loadMembers`, compared by `verify.go` `sameMembers`), so a Subject that changes Source reloads its handles even when no Observation cites a moved Artifact (review X-12). `sqlHandlesForSource` and `sqlHandlesForArtifact` *(new)* are built from one shared head `sqlHandlesCitingHead` *(new)* (the `identity_claims` → `observations` → `citations` join; each query adds its own `WHERE` with the status filter, as the code block shows), so the join exists once: `sqlHandlesForArtifact = sqlHandlesCitingHead + " AND c.artifact_id = ?"`, `sqlHandlesForSource` = the head joined to `artifacts a` + `" AND a.source_id = ?"`. The comment "Handle queries mirror autoreconciler" says that `sqlHandlesForArtifact` has no autoreconciler twin (review M-8). No `HandleScope` | The reconciler scores an Observation with `artifacts.source_id`'s grade, so the Artifact row's change is the one that moves scores; the same shape as `source_credibility_assessments`, which also sets no `HandleScope` | `Handles` on `subjects` only — the reconciler scores with the Artifact's Source, which a Subject's change does not name; a hand-written recompute in `sourcemove` — the rule forbids hand-written cache updates |
| D-11 | `Impact`: after `resolve`, Artifacts from `artifacts.ListBySource(c, bundle.SourceID)` kept when in the bundle (the list's own order, `ref COLLATE NOCASE`; review M-5), and `LeavesSourceEmpty` = that list's length equals the bundle's; `LeavesNoGraph` = `bundle.TakesEveryGraph`; graphs and counts from `evidencegraphs.IndexOf(c.Graph())`: `OfSource(bundle.SourceID)` kept when in the bundle (list order), and `Progress(id)` per kept graph (review M-2); when a target is given, from `sources.RecordsOf(c.Graph())`: both `CredibilityKey`s and `CredibilityDiffers` = the two `Credibility` values differ. A bundle graph missing from the index, or a Source missing from the records, is an internal error (`fmt.Errorf`): the index and records are kept current under the catalog session `Impact` runs in (`withProjectCatalog`) | No new SQL for what the caches hold; `Credibility` is the order the reconciler scores with, so "differs" means "Conclusions can re-rank"; `Progress.SubjectCount` is the count the Source page shows | Comparing grade keys — "" and "standard" score alike; a new `SubjectCount` field beside `Progress` (M-2); sorting `GetMany`'s map in Go (M-5) |
| D-12 | `Impact`'s target is optional. Empty: no credibility fields and no same-Source check | The confirm can show the bundle before a target is picked, then ask again with it, through one RPC | A second RPC for the credibility note |
| D-13 | Errors in `sourcemove`: `ErrInvalid = apperr.New(apperr.CodeSourceMoveInvalid, apperr.KindUser)` with `CodeSourceMoveInvalid = "sourcemove.invalid"` (invalid seed, empty target in `Move`, same Source, nil user); `ErrNotFound = apperr.New(apperr.CodeSourceMoveNotFound, apperr.KindNotFound)` with `CodeSourceMoveNotFound = "sourcemove.not_found"` (the seed is gone) *(new)*. A missing target is the existing `sources.not_found`. Over the wire, an empty or malformed `user_id` is `users.invalid` and a malformed id `request.invalid_id`, both from the handler's parsers before the engine | Package-prefixed codes, as every package; the same-Source case is a client bug (S15-25's picker leaves out the current Source), so it needs no code of its own | `sourcemove.same_source` — no screen would show it |
| D-14 | Wire: `METHOD_GET_SOURCE_MOVE_IMPACT = 127`, `METHOD_MOVE_TO_SOURCE = 128` (§ 6 FFI). The handlers live in `api/ffi/handlers/source_move.go` *(new)*. The audit action is `move_to_source` | `Get…Impact` is the repo's preflight name (`GetDeleteImpact`, `GetEvidenceGraphUnlinkImpact`, `GetUnpromoteImpact`) | `MoveArtifactsToSource` (the feature doc's working name) — a graph is a seed too |
| D-15 | Copy for the two codes rides in this PR: `L10n.Errors.sourceMoveInvalid`, `L10n.Errors.sourceMoveNotFound` and their `message(code:params:)` cases | `add-ffi-handler`: "Add a matching `L10n.Errors` / String Catalog entry for any new code" | Leaving them to S15-25 — the skill puts them with the code |
| D-16 | `sqlbatch.Exec[T any](q dbsql.Execer, head, tail string, args []any, ids []T) error` *(new)*, the write twin of `sqlbatch.Query`: head + placeholders + tail once per batch of ids, args bound first | Today's batched IN writes are hand-rolled inside a `sqlbatch.Each` chunk: `searchindex/inputs.go` `writeInputs` (one `DELETE … IN`) and `autoreconciler/autoreconciler.go` `recomputeBatch` (two). This PR moves those three onto `sqlbatch.Exec` too (each is one chunk, so `Exec` runs once with the same SQL and binds), so batched IN writes have one mechanism (review M-3, M-10) | A loop per package; `sqlbatch.Exec` beside the old hand-rolled writes (M-10) |
| D-17 | `sources.Lookup(q database.Querier, id []byte) (Source, error)` *(new)*: `ErrInvalid` for a malformed id, else `getOne(q, sqlGet, id)` (`ErrNotFound` when missing). `GetTx` and `Get` call it, so the id check exists once | `resolve` runs on a `*sql.DB` for the preflight and a `*sql.Tx` for the write; `getOne` already takes a `Querier` | Two target checks, one per caller (M-1) |
| D-18 | A test in `sourcemove` walks `catalogmodel.FKs` whose `To` is `"sources"` and requires each `(From, Column)` to be in one of two lists: moves with the bundle (`artifacts.source_id`, `evidence_graphs.source_id`, `subjects.source_id`) or stays with the Source (`source_notes`, `source_metadata`, `source_credibility_assessments`, `source_metadata_layout`). Today there are exactly these seven. An FK in neither list fails | A table added later with a Source key (`source-structure-later.md` names `parent_source_id`, `source_derivations`) must decide whether it moves (review M-6) | A Stop condition only, which binds this PR's implementer alone |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `evidencegraphs.Seed`, `Seed.Valid`, `evidencegraphs.Bundle`, `evidencegraphs.BundleOf`, private `sourceOf`, `sqlArtifactSource` *(new)* | type / func | `evidencegraphs.list`, `SourceOf`, `sqlLinkSources`, `Pair` + `requireDistinctPairs` | Extends `list` and splits `SourceOf`; no existing walk over links (searched `rg "closure\|evidence_graph_artifacts" core/database`). `artifacts` cannot be imported (it imports `evidencegraphs`), so the Artifact's Source is read beside `sqlLinkSources` |
| `evidencegraphs.SetSourceTx` *(new)* | func | `evidencegraphs.Update` (`sqlUpdate`) | `Update` writes name and description of one graph and refuses an empty name; a Source change is a different column over a set |
| `artifacts.SetSourceTx` *(new)* | func | `artifacts.Update` | `Update` writes label, description and links of one Artifact; `source_id` is fixed there |
| `subjects.SetSourceTx` *(new)* | func | `subjects.Update` | `Update` writes label and description of one Subject |
| `sqlbatch.Exec` *(new)* | func | `sqlbatch.Query`; hand-rolled `searchindex.writeInputs`, `autoreconciler.recomputeBatch` | Its write twin; the three `SetSourceTx` and the three existing batched deletes use it |
| `database.Tx.DeferForeignKeys` *(new)* | func | `catalog.go` `locking_mode`, `migrate.go` `foreign_keys` | Pragmas stay in `core/database` |
| `sources.Lookup` *(new)* | func | `sources.GetTx`, private `getOne` | Exposes `getOne` over a `Querier`; `GetTx` becomes its caller |
| `core/database/sourcemove` *(new)*: `Report`, `Impact`, `Result`, `Move`, private `resolve`, `ErrInvalid`, `ErrNotFound` | package | `core/database/sourcecopy` | Same shape (a composer inside `writes.Run`); a different operation |
| `effects` `sqlHandlesCitingHead`, `sqlHandlesForArtifact` *(new)* | const | `effects` `sqlHandlesForSource`, `sqlHandlesForCitation` | `sqlHandlesForSource` is rebuilt on the shared head; the registry has no Artifact-keyed handle path |
| `apperr.CodeSourceMoveInvalid`, `CodeSourceMoveNotFound` *(new)* | const | `CodeSourcesNotFound` | A new package's codes |
| `GetSourceMoveImpact`, `MoveToSource` RPCs and their four messages *(new)* | FFI | `GetEvidenceGraphUnlinkImpact`, `CopySource` | New operation. Reuses `Artifact`, `EvidenceGraph`, `EvidenceGraphProgress`, `WriteEffects` and `artifactProto`, `evidenceGraphProto`, `protoProgress`, `writeEffectsProto` |
| `L10n.Errors.sourceMoveInvalid`, `sourceMoveNotFound` *(new)* | key | `L10n.Errors.sourcesNotFound` | New codes |

**Builds on.** The effects registry (both Sources follow from `field("source_id")`; one new `Handles` path), `writes.Run`, Spike 16's Applys (`sources.Records`, `evidencegraphs.Index`, `graphfill` entries dropped by `EvidenceGraph` paths), `evidencegraphs.list`, `evidencegraphs.CreateDefault`, `sources.SetCover`, `artifacts.GetMany`, the `sourcecopy` composer shape, the `Get…Impact` preflight shape.
**Deletes.** None — nothing becomes dead: no existing path moved rows between Sources. Comments this PR makes false are rewritten: `CreateDefault`'s "Its only caller is sources.Create" (D-8) and the registry's "Handle queries mirror autoreconciler" (D-10).
**Next adds.** S15-25 calls `GetSourceMoveImpact` when the confirm opens and again when a target is picked, then `MoveToSource`, and maps `sourcemove.*` into `EngineErrorCode`. Undo (refused this spike) would be `MoveToSource` back.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| An Artifact, graph or Subject whose `source_id` changes after creation | `sources.Records` Apply, `evidencegraphs.Index` Apply, `graphfill.Graphs` / `graphfill.Records` (dropped through `EvidenceGraph`), `autoreconciler` (D-10), `searchindex` | Both Applys handle a two-Source commit (S16-12 CON-4 fix, `TestGraphIndexApplyMove`); `Verify()` in T-5 checks every loaded entry against SQL after a move |
| A Source with Artifacts and no graph during the transaction | `ErrLastGraph` invariant | D-8 restores it before commit; T-5 last-graph row |
| A Source left with no Artifacts | Sources list, Source page | Already reachable by deleting every Artifact; nothing changes |
| A Source whose cover pin left with its Artifact | `sources.Source.PrimaryArtifactID` readers | D-7 clears it in the same write |
| A target Source holding two `source` Subjects | `observations.requireSameGraph`, the Source page | The schema allows it today ("should maintain at most one" is advice); D-9 |

### Scale

At the map's Scale (a move writes 5 Artifacts, 5 graphs and up to 100 Subjects): 110 row changes in one transaction, plus at most one `sources` change (D-7) and one graph create (D-8). `BundleOf` is three queries whatever the bundle (D-2). Each `SetSourceTx` reads its rows and updates them in one statement per 500-id batch. `effects.Resolve` walks each change's paths: per Subject, `subjectGraph` and the progress read each read the live `graph_id` (two point reads), so about 200 point reads for 100 Subjects; per Artifact, the new `sqlHandlesForArtifact` (one indexed join). `searchindex.Reproject` rebuilds two Source documents and 5 graph documents. The handles recompute runs once over the union of handles. Caches: `sources.Records` reloads 2 Sources, `evidencegraphs.Index` re-lists 2 Sources and recounts the 5 graphs, and the 5 graphs' keyed entries are dropped. T-5's Scale row runs this exact bundle and asserts one revision and `Verify() == nil`; no budget is set, so no timing is asserted.

### Edges

- **Assumptions.** (1) A bundle is on one Source: `checkLink` refuses a cross-Source link; `BundleOf` loads only the seed's Source, and T-1 covers a second Source with links of its own that must not join. (2) Every Citation on a moved Artifact is in a moved graph: a Citation needs its link (`citations.go:227`) and `checkUnlink` keeps it; T-5 AC-2.1 checks C1. (3) The closure terminates: the walk marks visited ids; a cycle (G1–A1–G2–A2–G1) is T-1's row. (4) `field("source_id")` yields both Sources because the change carries the diff (`readChangeColumn` → `uuidPair`); T-6 asserts both scopes. (5) Deferred keys hold at commit only if every Subject of every moved graph moved: `subjects.SetSourceTx` updates by `graph_id`, not by a list read earlier; T-5's Scale row.
- **Neighbors.** A bundle of one Artifact in no graph (AC-1.3) and a graph with no Artifacts (AC-1.4) sit either side of the common pair; both move. A bundle holding every Artifact but not every graph leaves the Source empty with a graph (AC-1.7 splits the two flags). A cover on a non-moved Artifact stays (AC-2.5). Credibility "" vs "standard" does not differ; "low_trust" vs "" does (AC-1.5, AC-1.6).
- **Removed inputs.** The old Source loses the moved Artifacts' contribution to its record (labels), its graph list and its search document's rolled children; each is rebuilt from SQL by its Apply or reprojection, checked by T-5 and T-7. A handle loses the old grade on the moved Observations and gains the new one (AC-2.8). Nothing the move leaves behind holds a moved row's old Source: the reconciler's outcomes are recomputed, and Citations hold no Source.
- **Real data.** None — no table, seed or configuration drives the rule.
- **Untrusted size.** None — every input is the app's own catalog rows; the walk is bounded by one Source's links, loaded once.

### Schema

None — no catalog change. The move relies on the existing composite key, checked at commit (D-5).

### Go core

| Package | Change |
| --- | --- |
| `core/database` | `tx.go`: `func (t *Tx) DeferForeignKeys() error` *(new)* (D-5) |
| `core/database/sqlbatch` | `func Exec[T any](q dbsql.Execer, head, tail string, args []any, ids []T) error` *(new)* (D-16) |
| `core/database/searchindex`, `core/database/autoreconciler` | `writeInputs`'s `DELETE` and `recomputeBatch`'s two `DELETE`s call `sqlbatch.Exec` (D-16); behavior unchanged |
| `core/database/evidencegraphs` | New file `bundle.go`: `Seed`, `Seed.Valid`, `Bundle`, `BundleOf`, `sqlArtifactSource` (D-1, D-2). `evidencegraphs.go`: private `sourceOf` split out of `SourceOf`; `SetSourceTx` *(new)* (D-3); `CreateDefault` comment (D-8) |
| `core/database/artifacts` | `SetSourceTx` *(new)*; entity `"artifact"` (D-3) |
| `core/database/subjects` | `SetSourceTx` *(new)*; entity `"subject"` (D-3) |
| `core/database/sources` | `Lookup` *(new)*; `GetTx` calls it (D-17) |
| `core/database/effects` | `registry.go`: `sqlHandlesCitingHead`, `sqlHandlesForArtifact` *(new)*, `sqlHandlesForSource` rebuilt on the head; `artifacts` and `subjects` entries gain `Handles` (D-10) |
| `core/apperr` | `CodeSourceMoveInvalid`, `CodeSourceMoveNotFound` *(new)* (D-13) |
| `core/database/sourcemove` *(new)* | `sourcemove.go`: package comment (what moves, what does not, D-5, D-9); `ErrInvalid`, `ErrNotFound`; `resolve`; `Report`, `Impact`; `Result`, `Move` |

```go
// effects/registry.go
sqlHandlesCitingHead = `SELECT DISTINCT ic.entity_id FROM identity_claims ic
	JOIN observations o ON o.subject_id = ic.subject_id
	JOIN citations c ON c.id = o.citation_id`
sqlHandlesForArtifact = sqlHandlesCitingHead + `
	WHERE ic.status IN ('accepted', 'provisional') AND c.artifact_id = ?`
sqlHandlesForSource = sqlHandlesCitingHead + `
	JOIN artifacts a ON a.id = c.artifact_id
	WHERE ic.status IN ('accepted', 'provisional') AND a.source_id = ?`

// evidencegraphs/bundle.go
type Seed struct{ ArtifactID, GraphID []byte }
func (s Seed) Valid() bool
type Bundle struct {
	SourceID                []byte
	ArtifactIDs, GraphIDs   [][]byte // ascending id bytes
	TakesEveryGraph         bool     // every graph of SourceID is in GraphIDs
}
func BundleOf(q database.Querier, seed Seed) (Bundle, error)

// sourcemove
type Report struct {
	Bundle               evidencegraphs.Bundle
	Artifacts            []artifacts.Artifact      // ListBySource order
	Graphs               []evidencegraphs.Graph    // the index's list order; ArtifactIDs read-only
	Progress             []evidencegraphs.Progress // one per graph, same order
	SourceCredibilityKey string                    // "" when not assessed
	TargetCredibilityKey string                    // "" when not assessed or no target
	CredibilityDiffers   bool
	LeavesSourceEmpty    bool
	LeavesNoGraph        bool
}
func Impact(c *database.Catalog, seed evidencegraphs.Seed, targetID []byte) (Report, error)

type Result struct {
	Bundle         evidencegraphs.Bundle
	DefaultGraphID []byte // nil unless D-8 created one
}
func Move(tx *database.Tx, userID []byte, seed evidencegraphs.Seed, targetID []byte) (Result, []rowchange.Change, error)
func resolve(q database.Querier, seed evidencegraphs.Seed, targetID []byte) (evidencegraphs.Bundle, error)
```

Errors: `sourcemove.invalid` → an invalid seed, an empty target in `Move`, the target is the bundle's Source, a nil user; `sourcemove.not_found` → the seed's row is gone; `sources.not_found` → the target is gone.

### FFI

`api/proto/engine.proto`:

```proto
  METHOD_GET_SOURCE_MOVE_IMPACT = 127;
  METHOD_MOVE_TO_SOURCE = 128;

// What moving an Artifact or an Evidence graph to another Source moves with it.
message GetSourceMoveImpactRequest {
  string project_dir = 1;
  string artifact_id = 2;      // exactly one of artifact_id and graph_id
  string graph_id = 3;
  string target_source_id = 4; // optional; empty leaves the credibility fields empty
}

message GetSourceMoveImpactResponse {
  string source_id = 1;                 // the bundle's Source today
  repeated Artifact artifacts = 2;      // by ref
  repeated EvidenceGraph graphs = 3;    // the Source's graph order
  repeated EvidenceGraphProgress progress = 9; // one per graph, same order
  string source_credibility_key = 4;    // "" when not assessed
  string target_credibility_key = 5;
  bool credibility_differs = 6;         // the two grades score differently
  bool leaves_source_empty = 7;         // every Artifact of the Source moves
  bool leaves_no_graph = 8;             // every graph moves; the Source gets a new Default graph
}

message MoveToSourceRequest {
  string project_dir = 1;
  string user_id = 2;
  string artifact_id = 3;
  string graph_id = 4;
  string target_source_id = 5;
}

message MoveToSourceResponse {
  repeated string artifact_ids = 1;
  repeated string graph_ids = 2;
  string default_graph_id = 3; // the old Source's new Default graph, when every graph moved
  WriteEffects effects = 4;
}
```

Handlers in `api/ffi/handlers/source_move.go` *(new)*: `GetSourceMoveImpact` parses ids with `optionalID`, builds the seed, runs `sourcemove.Impact` in `withProjectCatalog`, and maps Artifacts with `artifactProto(c, a, pass)` (one `thumbnailPass{}` per call) graphs with `evidenceGraphProto`, and counts with `protoProgress`; after the session it calls `pass.run(req.GetProjectDir(), nil)` as `CreateArtifact` does, so a missing thumbnail is filled. `MoveToSource` parses `user_id` with `parseUserID`, runs `writes.Run(c, writes.Op{Action: "move_to_source", UserID: userID}, …sourcemove.Move…)` and returns `Effects: writeEffectsProto(wrote)`. `dispatch.go`: `MethodGetSourceMoveImpact`, `MethodMoveToSource` and two `route` cases. Regenerate with `./scripts/generate-proto.sh` (commits Go and Swift generated files).

### macOS

None — no view, store method or model changes. The generated `macos/App/Platform/Generated/engine.pb.swift` is regenerated; only `L10n.swift` and `Localizable.xcstrings` change by hand (§ Strings).

### Strings

L10n keys *(new)*, under `L10n.Errors`:

- `sourceMoveInvalid`: key `error.sourcemove.invalid` = "This move could not be made." (comment "FFI error sourcemove.invalid: no seed, two seeds, or the target is the same Source")
- `sourceMoveNotFound`: key `error.sourcemove.not_found` = "The Artifact or Evidence graph to move no longer exists." (comment "FFI error sourcemove.not_found: the picked Artifact or graph was deleted")

`message(code:params:)` gains `case "sourcemove.invalid"` and `case "sourcemove.not_found"`. Removed: none.

## 7. Steps

**Fixtures.** Every Go test in `core/database` starts from `r := evidencelayertest.New(t)`; `r.NewSource(title)` returns a Source with its Default graph and one Artifact "Scan" linked to it (the create default links every graph). Build each AC's shape with these writes, all under `r.Run` or `writes.Call` with `evidencelayertest.UserID`:

| Shape | Writes |
| --- | --- |
| An Artifact linked only to a named graph | `artifactstest.Create` with `Graphs: evidencegraphs.GraphLinks{Given: true}` (none), then `evidencegraphs.Create` with `ArtifactIDs: [it]` |
| An Artifact in no graph (AC-1.3) | `artifactstest.Create` with `Graphs: evidencegraphs.GraphLinks{Given: true}` |
| A graph with no Artifacts (AC-1.4) | The Default graph of `r.NewSource` after `evidencegraphs.SetArtifactGraphs(tx, uid, scan.ID, [][]byte{otherGraph})` moves "Scan" to a second graph |
| A Source holding only A1 and G1 (AC-1.7) | `r.NewSource`: "Scan" is A1, Default is G1 |
| Subjects in a graph | `subjectstest.On(t, r.C, uid, graphID, kind, label)` (`r.Bare` and `r.Labelled` call it on a Source's sole graph through `r.Graph`) |
| Credibility | `sourcecredibilitygradestest.Install(r.C)`; `sourcecredibilitygrades.Lookup(r.C, key, vocabkey.OriginProvenencia)`; `sourcecredibility.Upsert(tx, uid, sourcecredibility.UpsertInput{SourceID, CredibilityGradeID})` |
| A handle with two members (AC-2.8) | `promotetest.Save(t, r.C, uid, promote.Input{SubjectID: P1})`, then `identityclaims.Create` with `Status: identityclaims.StatusAccepted` for P2 (as `core/database/effects/handle_paths_test.go` does) |
| Cover (AC-2.5) | `sources.SetCover(tx, uid, S1, sources.CoverModeArtifact, A1)` |

**STEP-1 — The bundle closure**
Files: `core/database/evidencegraphs/bundle.go` *(new)*, `core/database/evidencegraphs/bundle_test.go` *(new)*, `core/database/evidencegraphs/evidencegraphs.go` (`sourceOf` split from `SourceOf`). Skill: `add-catalog-query`.
Do: D-1, D-2.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/evidencegraphs/ -run 'TestBundleOf|TestSourceOf'` passes (T-1).

**STEP-2 — The write helpers and per-table `source_id` updates**
Files: `core/database/sqlbatch/sqlbatch.go` and its test, `core/database/searchindex/inputs.go`, `core/database/autoreconciler/autoreconciler.go`, `core/database/tx.go`, `core/database/sources/sources.go`, `core/database/evidencegraphs/evidencegraphs.go`, `core/database/artifacts/artifacts.go`, `core/database/subjects/subjects.go`, and a table test in each package's existing `_test.go`. Skill: `add-catalog-query`, `add-audit-scope`.
Do: D-3, D-5, D-8's comment, D-16, D-17. The three `SetSourceTx` tests run inside one write that calls `tx.DeferForeignKeys()` first, then graphs, Subjects, Artifacts, and assert rows and changes.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/ ./core/database/sqlbatch/ ./core/database/searchindex/ ./core/database/autoreconciler/ ./core/database/sources/ ./core/database/evidencegraphs/ ./core/database/artifacts/ ./core/database/subjects/` passes (T-2).

**STEP-3 — An Artifact's Source change recomputes its handles**
Files: `core/database/effects/registry.go`, `core/database/effects/handle_paths_test.go`, `core/database/effects/README.md`. Skill: `add-audit-scope`.
Do: D-10. Add one sentence to the README after the `Set.Handles` paragraph: an Artifact that changes Source names the handles whose Observations cite it, since the reconciler scores with the Artifact's Source, and a Subject that changes Source names its own handles, whose loaded members carry it.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/effects/` passes (T-3), including `registry_completeness_test.go`.

**STEP-4 — `sourcemove`: preflight and move**
Files: `core/apperr/apperr.go`, `core/database/sourcemove/sourcemove.go` *(new)*, `core/database/sourcemove/sourcemove_test.go` *(new)*. Skill: `use-catalog-session`, `add-audit-scope`.
Do: D-4, D-6 – D-9, D-11 – D-13, D-18. Fixtures as above.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcemove/` passes (T-4, T-5, T-7, T-10).

**STEP-5 — Both Sources' histories**
Files: `core/database/audit/scopes_test.go`. Skill: `add-audit-scope`.
Do: add a `TestSourceScopes` row "move a bundle to the other Source": `writes.Run` of `sourcemove.Move` with seed `s.artifact`, target `s.b`; `sourceRevisions` after shows both `a` and `b` equal to the move's revision.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/audit/ -run TestSourceScopes` passes (T-6).

**STEP-6 — FFI**
Files: `api/proto/engine.proto`, generated `api/proto/engine/engine.pb.go` and `macos/App/Platform/Generated/engine.pb.swift`, `api/ffi/dispatch.go`, `api/ffi/handlers/source_move.go` *(new)*, `api/ffi/handlers/source_move_test.go` *(new)*. Skill: `add-ffi-handler`, `use-catalog-session`.
Do: D-14 and § 6 FFI. Tests use `runRPC` rows and `newGraphFixture` / `otherSource`. `./scripts/generate-proto.sh` needs `protoc`, `protoc-gen-go` and `protoc-gen-swift` on `PATH`; where one is missing, stop and report it (the generated files must come from the script).
Check: `./scripts/generate-proto.sh` succeeds; `CGO_ENABLED=1 go test -tags fts5 ./api/ffi/...` passes (T-8, T-9, and `TestEveryAuditedWriteReturnsEffects`).

**STEP-7 — Error copy**
Files: `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`. Skill: `add-localized-string`.
Do: D-15 and § 6 Strings.
Check: `python3 scripts/check-localizable-xcstrings.py` passes. `xcodebuild test` runs only on macOS: on a Linux host, report it as not run and let `scripts/check-pr.sh`'s result on macOS (CI or the reviewer) be the evidence.

**STEP-8 — Version**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj`.
Do: 0.31.0 → 0.32.0 in `VERSION`, `core/version.go` and all four `MARKETING_VERSION` lines.
Check: `CGO_ENABLED=1 go test ./core/ -run TestVersion` passes.

**STEP-9 — Docs**
Files: `docs/interpretation-layer-data-model.md` § 4.2, `docs/source-layer-data-model.md` § 7 and § 7.1, `docs/deployment-plan/spike-15/move-artifact-between-sources.md` ("Engine notes"), `docs/deployment-plan/spike-15/completed.md`, `docs/deployment-plan/spike-15/deployment-plan.md` (map row), this plan (status, Landed note).
Do: § 4.2: replace "A Subject belongs to one graph and never moves." with "A Subject belongs to one graph and never changes graph; moving its graph to another Source (`sourcemove.Move`, S15-24) changes its `source_id` with the graph's." § 7: add a last paragraph before § 7.1: an Artifact's `source_id` changes only through a move, which carries its bundle. § 7.1: add a last paragraph: a graph's `source_id` changes only through a move; a Source left with no graph gets a new Default graph. Feature doc "Engine notes": name `GetSourceMoveImpact`, `MoveToSource`, `evidencegraphs.BundleOf`, the deferred keys, the cleared cover, and the reification decision (D-9). `completed.md`: a paragraph at the top in the shape of the others: its bold title "S15-24 — Move a bundle to another Source in the engine" and the PR link, then sentences naming the two RPCs, what moves, what stays, the cover and Default-graph cases, the handle recompute, and "Product 0.32.0." Map row status: `Landed #N`. This plan: Status `Landed in [#N](…) (date)` and a `## Landed` section after the header, as in [`S16-15-graph-catalog.md`](../../spike-16/prs/S16-15-graph-catalog.md), listing only where the code differs from the plan.
Check: links resolve; `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-24-move-bundle.md` reports no errors.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/evidencegraphs/bundle_test.go` `TestBundleOf` *(new)*; `TestSourceOf` (existing, unchanged result) | Rows: AC-1.1 seed A1 → {A1},{G1}, `TakesEveryGraph` false; AC-1.2 seed A1 and seed G2 → {A1,A2,A3},{G1,G2}; a cycle G1–A1–G2–A2–G1 → both graphs and Artifacts once; AC-1.3; AC-1.4; AC-1.7 → `TakesEveryGraph` true; a second Source with its own linked pair is never in the result; missing well-formed seed → `sql.ErrNoRows`; neither, both, or a short id → `ErrInvalid`. Lists sorted ascending | AC-1.1 – AC-1.4, AC-1.7, D-1, D-2 |
| T-2 | Go | `sqlbatch_test.go` `TestExec`; `evidencegraphs_test.go`, `artifacts_test.go`, `subjects_test.go` `TestSetSourceTx`; `sources_test.go` `TestLookup` *(new)* | `Exec` over 1,001 ids runs three statements (counted by a `countingExecer` *(new, test-only)* in `sqlbatch_test.go` that wraps the `*sql.DB` and counts `Exec` calls) and touches every row. `SetSourceTx`: two rows moved → two `Updated` changes with `source_id` old → new, rows read back on the new Source; a row already there and an id with no row → no change; a repeated id → one change; no ids → nil, no query; malformed `sourceID` → package `ErrInvalid`. `Lookup`: a Source → it; missing → `ErrNotFound`; short id → `ErrInvalid` | D-3, D-16, D-17 |
| T-3 | Go | `core/database/effects/handle_paths_test.go` `TestHandlePaths` (new rows) | An `artifact` update change carrying `source_id` → the handles of Subjects with Observations on the Artifact's Citations (accepted and provisional; not rejected); the same change carrying only `label` → none; an Artifact create and an Artifact delete (their changes carry `source_id`) → none, since a new Artifact has no Citations and a deleted one released them; a `source_credibility_assessment` grade change still names the same handles as before (the rebuilt `sqlHandlesForSource`); a `subject` update carrying `source_id` → its accepted and provisional handles; a `subject` update carrying only `label` → none | D-10, AC-2.8, AC-2.12 |
| T-4 | Go | `core/database/sourcemove/sourcemove_test.go` `TestImpact` *(new)* | AC-1.1, AC-1.2 (Artifacts in `ListBySource` order, graphs in list order, one `Progress` per graph), AC-1.4, AC-1.5, AC-1.6, AC-1.7, AC-1.8, AC-1.9 | AC-1.*, D-6, D-11 – D-13 |
| T-5 | Go | `sourcemove_test.go` `TestMove` *(new)* | Rows: AC-2.1 (ids, refs, Citation, Observation, link and both metadata rows unchanged; `sourcemetadata.ListByOwnersTx` for A1 and G1 returns the same values); AC-2.2; `scale` AC-2.3 (5 + 5 + 100; one revision); AC-2.4; AC-2.5 both cases; AC-2.9; AC-2.12; AC-2.11 (each refusal and a nil user: the code, and the `audit_transactions` count unchanged). Every row ends with `r.C.Graph().Verify()` nil | AC-2.1 – AC-2.5, AC-2.9, AC-2.11, AC-2.12, D-5 – D-10 |
| T-6 | Go | `core/database/audit/scopes_test.go` `TestSourceScopes` (new row) | A move from `s.a` to `s.b` → both Sources' revisions equal the move's revision | AC-2.6 |
| T-7 | Go | `sourcemove_test.go` `TestMoveCachesAndSearch`, `TestMoveRecomputesHandles`, `TestMergeByMoving` *(new)* | AC-2.7 (index, records and G1's `catalog_search_docs` row, each built before the move); AC-2.8 (the 1840 row's `reason` 'weak' before, 'kept' after; `Effects.Handles` holds H; `Verify` nil); AC-2.10 | AC-2.7, AC-2.8, AC-2.10 |
| T-8 | Go | `api/ffi/handlers/source_move_test.go` `TestGetSourceMoveImpact` *(new)* | `runRPC` rows: AC-1.1's shape on the wire (Artifacts, graphs and `progress` mapped); a target with a different grade; bad proto → error; a malformed id → `request.invalid_id`; no seed and two seeds → `sourcemove.invalid`; a missing seed → `sourcemove.not_found`; a missing target → `sources.not_found` | AC-1.*, D-13, D-14 |
| T-9 | Go | `source_move_test.go` `TestMoveToSource` *(new)* | A pair moved: reply ids, `effects.source_scopes` holds both Sources, `ListEvidenceGraphs` for each Source shows the graph under the target; the last-graph case returns `default_graph_id`; empty `user_id` → `users.invalid`; same Source → `sourcemove.invalid` | AC-2.1, AC-2.4, AC-2.6, AC-2.11 |
| T-10 | Go | `sourcemove_test.go` `TestSourceKeysAreClassified` *(new)* | Every `catalogmodel.FKs` entry with `To == "sources"` is in the moves list or the stays list; today seven entries, none unclassified | D-18 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `core/database/effects` (`registry_completeness_test.go`, `TestHandlePaths`), `core/database/audit` (`TestSourceScopes`), `api/ffi/handlers` (`TestEveryAuditedWriteReturnsEffects`), `core/database/evidencegraphs` (`TestGraphIndexApplyMove`, `TestSourceOf`).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none)
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New (no UI)
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (no brief: not gated)
- [ ] Domain docs updated: interpretation-layer-data-model.md § 4.2, source-layer-data-model.md § 7 and § 7.1, effects/README.md, move-artifact-between-sources.md "Engine notes"
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

No view offers the move yet (S15-25). The check is the engine on a real project:

1. Build and run the tests in STEP-4 and STEP-6 with `-v` and read the Scale row of `TestMove` (`-run 'TestMove/scale'`): one revision, `Verify` nil.
2. On a copy of a dogfood project, run `TestMoveToSource`'s shape by hand through a scratch Go test pointed at the copy (not committed): move one Artifact with a graph that holds Citations to another Source, then open the copy in the app: the Artifact and its graph show under the target Source with their Citations, the old Source's page lists them no more, and both Sources' "Updated" move to the same time.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A deferred foreign-key failure at commit hides which row failed | T-5's Scale row and T-2 move every Subject by `graph_id`, the only way the key can break |
| A loaded cache keeps an old Source for a moved row | `Verify()` after every T-5 row; AC-2.7 builds each entry before the move |
| Handles score with the old grade | D-10 and T-3; `Verify()` compares stored values with the truth recompute |
| 110 changes make `effects.Resolve` slow | Point reads only; T-5's Scale row runs it; no budget is set |

**Stop and report if:**

- `PRAGMA defer_foreign_keys = ON` inside `writes.RunChanges`'s transaction does not defer the composite key check (T-5 fails with a foreign-key error at an UPDATE, not at commit).
- `evidencegraphs.list` no longer takes a `database.Querier`, or `checkLink` no longer refuses a cross-Source link.
- `sources.Records` or `evidencegraphs.Index` fails `Verify()` after a move although the commit named both Sources (an Apply bug in Spike 16 code: Out of this PR).
- `TestEveryAuditedWriteReturnsEffects` needs a change to its own table to pass.
- Any table other than `artifacts`, `evidence_graphs`, `subjects` and `sources` (cover) would need a write for AC-2.1 to hold.

## 12. Open questions

None.

## 13. PR

**Title:** S15-24 — Move a bundle to another Source in the engine
**Body:** objective in one sentence; what shipped against US-1 and US-2; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-24-move-bundle.md`.
