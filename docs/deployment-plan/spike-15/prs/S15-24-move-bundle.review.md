# Review — S15-24 Move a bundle to another Source in the engine

**Verdict:** round 1: Fits with changes — Ready with changes
**Rounds:** 1 (round 2 pending). **Reviewers:** maintainability (opus), executability (sonnet)

## To user

- Planning question, answered before review: a `source` (reification) Subject in a moved graph moves with it and reifies the target from then on, with no warning (user, 2026-11-21; D-9).

## Writer's own calls

- The move lives in a new package `core/database/sourcemove` (D-4), with the closure in `evidencegraphs.BundleOf` (D-2) and each table's update in its own package (D-3).
- Deferred foreign keys, no migration (D-5).
- Two RPCs, `GetSourceMoveImpact` (127, target optional) and `MoveToSource` (128); audit action `move_to_source` (D-12, D-14).
- "Credibility differs" compares the reconciler's relative order, so no assessment and `standard` do not differ (D-11).
- The old Source's cover is reset to the type icon when its cover Artifact moves (D-7).
- An Artifact that changes Source names its Citations' handles in the effects registry (D-10).
- Two error codes, `sourcemove.invalid` and `sourcemove.not_found`, with their Swift copy in this PR (D-13, D-15).
- Minor bump 0.31.0 → 0.32.0.

## Round 1

### M-1 · blocker · The preflight and the write each derive the bundle's refusals and side effects
**Answer:** Fixed — D-6: one private `sourcemove.resolve(q, seed, targetID)` holds the seed rule, the bundle, the target check and the same-Source refusal; `Impact` and `Move` both call it. D-2: `Bundle.TakesEveryGraph` comes from `BundleOf`'s own `list` rows; `Impact.LeavesNoGraph` and D-8's `CreateDefault` both read it; no count after the update. D-17 `sources.Lookup` lets `resolve` run on a `*sql.DB` and a `*sql.Tx`.

### M-2 · major · `ReportGraph` / `SourceMoveGraph` re-solve a graph's Subject count
**Answer:** Fixed — `Report.Progress []evidencegraphs.Progress`; the wire carries `repeated EvidenceGraphProgress progress` mapped with `protoProgress`; `SourceMoveGraph` dropped (D-11, § 6 FFI).

### M-3 · major · Three hand-written batched UPDATE copies
**Answer:** Fixed in part — `sqlbatch.Exec` (D-16) is the write twin of `sqlbatch.Query`, used by all three `SetSourceTx`. Declined: a shared change-building helper; each change is one `rowchange.Updated` call with a one-key map, and D-3 states the one encoding and skip rule all three follow.

### M-4 · major · `BundleOf`'s graph Source lookup copies `SourceOf`
**Answer:** Fixed — D-2: private `sourceOf` split out of `SourceOf`; the Artifact's Source is `sqlArtifactSource` beside `sqlLinkSources` (`artifacts` imports `evidencegraphs`, so it cannot be called).

### M-5 · minor · `Impact` re-implements the Artifact list order
**Answer:** Fixed — D-11 reads `artifacts.ListBySource` and keeps the bundle's rows; `LeavesSourceEmpty` comes from the same read.

### M-6 · minor · The tables a move rewrites are kept by hand
**Answer:** Fixed — D-18, T-10: a test classifies every `catalogmodel.FKs` entry to `sources` as moves or stays.

### M-7 · minor · Raw PRAGMA in a domain package
**Answer:** Fixed — D-5: `database.Tx.DeferForeignKeys`.

### M-8 · minor · Comments made false
**Answer:** Fixed — D-8 rewrites `CreateDefault`'s "only caller" comment; D-10 builds both handle queries on one head and corrects the "mirror autoreconciler" comment; listed under Deletes.

### M-9 · nit · `Seed` and its rule live apart
**Answer:** Fixed — D-1: `Seed.Valid()` beside the type; `BundleOf` and `resolve` both call it.

### X-1 · blocker · No function counts the old Source's graphs
**Answer:** Fixed — with M-1: `Bundle.TakesEveryGraph` (D-2, D-8).

### X-2 · blocker · Seed validation and malformed-id codes split across layers
**Answer:** Fixed — D-1 and D-13: `Seed.Valid` is the one rule; `resolve` returns `sourcemove.invalid`; a malformed id on the wire is `request.invalid_id` from `optionalID`. AC-1.8, T-1, T-8 updated.

### X-3 · blocker · Missing-user code contradicts AC-2.11
**Answer:** Fixed — AC-2.11 and D-13: `Move` with a nil user is `sourcemove.invalid` (T-5); an empty `user_id` over the wire is `users.invalid` from `parseUserID` (T-9).

### X-4 · major · AC fixtures cannot be built from the fixture line
**Answer:** Fixed — § 7 **Fixtures** table: the writes for each shape.

### X-5 · major · `SetSourceTx` behaviors left open
**Answer:** Fixed — D-3: target not checked (caller did; FK at commit), dedup, no ids → no query, missing row and already-there skipped, no `fixed` fields; T-2 rows for each.

### X-6 · major · `Move` and `Impact` behavior unspecified
**Answer:** Fixed — D-6 loads the old Source with `sources.GetTx` before the updates; D-11 uses `ListBySource`'s order (no Go sort), says `Impact` runs under the catalog session, and makes a bundle graph missing from the index or a Source missing from the records an internal error.

### X-7 · major · AC-2.8 has no recipe and `Verify` alone can pass
**Answer:** Fixed — AC-2.8 now builds H with two members on `low_trust` and `standard` Sources and asserts the 1840 row's `reason` goes from 'weak' to 'kept' (`core/autoreconcile/pipeline.go` step 5), with H's node loaded before the move; fixture row added.

### X-8 · minor · Scale shape
**Answer:** Fixed — AC-2.3: 20 Subjects per graph through `subjectstest.On`.

### X-9 · minor · Checks needing a caveat
**Answer:** Fixed — STEP-6 names the protoc tools and stops when one is missing; STEP-7 says `xcodebuild` runs only on macOS; STEP-8 says all four `MARKETING_VERSION` lines.

### X-10 · minor · Doc step wording
**Answer:** Fixed — STEP-9 gives the `completed.md` shape, the map status and the `## Landed` template (S16-15).

### X-11 · nit · Temptations
**Answer:** Fixed — AC-2.10 names `sources.Delete(tx, userID, S1)` under `r.Run`; the rest were already Out.

## Round 2

Maintainability: every round-1 answer checked against the code and holds; one new blocker.

### M-10 · blocker · `sqlbatch.Exec` added beside the batched IN writes it cites, which stay hand-rolled
**Answer:** Fixed — D-16's evidence corrected (`searchindex/handles.go` only reads); `searchindex.writeInputs` and `autoreconciler.recomputeBatch`'s two deletes move onto `sqlbatch.Exec` in STEP-2 (§ 6 Go core, Codebase fit, STEP-2 files and check).

Non-blocking notes, also Fixed: D-17 `sources.Get` calls `Lookup` too; D-6 names where `Move` refuses an empty target; D-10's prose says each query adds its own `WHERE`; T-3 gains Artifact create and delete rows (the new `Handles` path returns nothing for them).
