# Review — S15-54 Citations hold metadata

**Document:** [`S15-54-citations-hold-metadata.md`](S15-54-citations-hold-metadata.md)
**Planned against:** `main` @ `11c91bb`
**Verdict:** Fits with changes — Ready with changes
**Rounds:** 2. **Reviewers:** maintainability (fresh context), executability (fresh context, the implementing model's tier)

## To user

None.

## Writer's own calls

- D-1, D-2: the level list's parents are `Ups []MetadataUp`, nearest first, with one `ToSource` mark (the Artifact for the Citation). The map named ordered `Ups` and the mark; the field names are the writer's.
- D-10: a Citation's board treats the Source as its only ancestor until S15-55.
- D-12: Swift's store gains no Citation draft argument until S15-56, its first caller.
- D-13: the map's delete fan-out was wrong (an Artifact or Source holding Citations cannot be deleted); the rule's parenthetical, the scope entry's fan-out and its Check were corrected with the plan.
- `CreateCitedBridge` takes no draft (Out, not planned).

## Round 1 (2026-11-24)

**Maintainability:** Fits with changes. **Executability:** Ready with changes.

### M-1 · major · Codebase fit missed a reader of `Up`; the Stop condition fires at base
`core/database/effects/registry_completeness_test.go` `TestMetadataEffects` reads `e.Up == nil`.
**Answer:** Fixed. STEP-1 Files names it (`len(e.Ups) == 0`); the Searched line lists the three test readers; the Stop condition says "production reader".

### M-2 · major · D-7 adds a second Citation-to-graph path beside `citationObservationGraphs`
**Answer:** Fixed. D-7 is now `from("citation_id", citationObservationGraphs)`, the registry's one path from a Citation to the graphs that show it. It still declares `citation_metadata`'s path to its graph, as the rule "The printed page is a metadata field" asks. T-6 checks a Citation with and without an Observation.

### M-3 · minor · The `Ups` / `ToSource` rule is taught nowhere but the code
**Answer:** Fixed. STEP-1 adds one sentence to `core/database/catalogmodel/README.md` and to `add-catalog-model` step 7.

### M-4 · minor · The sweep misses stale three-level wording
**Answer:** Fixed. The DoD sweep matches `three levels` and `the Evidence graph, then the Artifact`, and covers the citation map; STEP-6 rewrites `TestImpactMetadataFieldHolders`' comment.

### M-5 · minor · `fillValues` hand-lists owners beside the new `Ups`
**Answer:** Fixed (logged for S15-55). Next adds says S15-55 decides whether `fillValues` takes its ancestor derivation.

### M-6 · nit · The draft precedent omits the Artifact handlers
**Answer:** Fixed. Current state names `CreateArtifact`, `UpdateArtifact`.

### X-1 · blocker · STEP-1's grep cannot pass; the DoD sweep contradicts D-2
**Answer:** Fixed. STEP-1 Files and Do name `TestMetadataEffects`; the STEP-1 grep and the DoD sweep match `\.Up\.Column|e\.Up\b|\bUp:\s*&`, not `MetadataUp\{`.

### X-2 · blocker · The T-13 and T-14 fixtures cannot reach the delete paths
`newGraphFixture`'s Citation has an Observation and its graph a Subject.
**Answer:** Fixed. T-13 makes a second Citation on `page2` with no Observations; T-14 makes a new graph "Empty" linking `page2` (no Subjects) and a Citation in it.

### X-3 · major · `newLevelOwner`'s Citation case leaves the link and locator open
**Answer:** Fixed. STEP-2 names `artifactstest.Create` (a new Artifact links to every graph, `evidencegraphs.LinkArtifact`), `evidencegraphstest.SoleGraph`, the locator literal, and `TestOwnerTables`' `tables` row and loop.

### X-4 · major · T-2's failing fixture has no function to call
**Answer:** Fixed. T-2 names a test helper `upsOrderErr(list) error`.

### X-5 · major · The scope of `SourcePath`'s mark check is open
**Answer:** Fixed. D-1: checked at each entry the walk visits, naming that entry; the `cycle` and `missingUp` fixtures mark `ToSource: true`; T-3 names the two new fixtures.

### X-6 · major · `TestMetadataOwners`' "citation level" case becomes stale
**Answer:** Fixed. STEP-4 renames it "citation id that names no Citation" and rewords its comment; the draft read's case stays (S15-55).

### X-7 · major · T-15 and T-17 need a Citation fixture
**Answer:** Fixed. T-15 adds the helper `citationOwner` in `facets_test.go`; T-17 uses it.

### X-8 · minor · Staged-depiction rollback is unproven
**Answer:** Declined. A draft error is a failed `writes.Run`, the same failure path an Observation error takes today, which `withStagedDepictions` already cleans up (`api/ffi/handlers/citations.go`). The Risk row says so; no new test.

### X-9 · minor · A citation-map line is not covered
**Answer:** Fixed. The DoD rewrites "The Citation level has only built-ins: Citations carry no metadata (§ 6.9)" in `evidence-explained-citation-map.md`, and the sweep covers that file.

### X-10 · minor · Smaller choices
**Answer:** Fixed. STEP-3 names `set`'s fifth parameter; T-12 lists its two rows; T-6 covers the graph path (M-2).

**Checks the reviewer could not run here:** `generate-proto.sh` (no `protoc`) and `xcodebuild`. They run on the implementer's Mac through `scripts/check-pr.sh`.

## Round 2 (2026-11-24)

**Maintainability:** Fits. Every round-1 answer checked against the code; `from("citation_id", citationObservationGraphs)` composes (`core/database/effects/path.go` `from`, `inbound`). No new blocker.

- **M2-1 · minor · T-6's `TestEvidenceGraphsResolve` file is not in STEP-2's Files.** **Answer:** Fixed. STEP-2 names `core/database/effects/evidence_graphs_test.go`.
- **M2-2 · minor · Two `effects/README.md` sentences go stale after D-7** (a metadata write drops no cached graph; `metadata_field_usage` names three levels). **Answer:** Fixed. The DoD's README line names both.

**Executability:** Ready with changes. Round-1 answers hold; no new blocker.

- **X-11 · major · T-16 cannot be written from its row.** `citedBundle` has no Citation id; `w.metadata` and `TestMove`'s count name two owners; `w.Run` returns no effects. **Answer:** Fixed. T-16 names `citedBundle.cit`, how `cited()` fills it and sets its value, the count of 3, and `writes.RunChanges` for the scope check.
- **X-12 · minor · T-6's file and field.** **Answer:** Fixed (with M2-1); the field comes from `setProviderValue`'s `metadatafields.Create`, as in `released_metadata_scope_test.go`.
