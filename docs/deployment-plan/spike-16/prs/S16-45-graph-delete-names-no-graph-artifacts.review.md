# Review — S16-45 A graph delete names the Artifacts it leaves in no graph

**Verdict:** Fits with changes — Ready with changes
**Rounds:** 1 (no blocker, no reshape, so no round 2). **Reviewers:** maintainability (default model), executability (sonnet)

## To user
None.

## Writer's own calls
- The via name `evidence_graph_artifacts.last_graph` (D-2), shaped like `canonical_entities.last_member`.
- Refs, not labels, in the sentence (D-7), as every cascade line does today.
- The count is not printed in the sentence (D-6), as in `deletesHandles`.
- The cascade registry moves out of `handle_gone.go` into `cascades.go` in this PR (D-1, from M-2).
- The bump is a patch (header): a new sentence a researcher sees, no wire or catalog change.

## Round 1

### M-1 · major · The "cascade vias" parity row is a hand-kept list beside the registry
`api/ffi/swift_vocabulary_test.go` row "cascade vias" lists the vias by hand; a new cascade with a forgotten line passes and Swift falls to `alsoAffects`.
**Answer:** Fixed — D-9: `deleteimpact.CascadeVias()` *(new)* reads the Named facets and `cascadeEdgeList`; the row reads it (STEP-3, T-3).

### M-2 · major · `handle_gone.go` stays the home of the cascade registry
The const block, `cascadeEdgeList` and `buildCascadeEdges` live beside handle helpers; the plan added a third file `no_graph.go`.
**Answer:** Fixed — option (a): D-1 moves them unchanged to `cascades.go` *(new)*; the edge is a literal in `buildCascadeEdges`; `no_graph.go` dropped; the count and list share `soleLinkFrom` (D-3). STEP-1 does the pure move first; a Stop condition guards it.

### M-3 · minor · D-6 forks the Artifact sheet's sentence
**Answer:** Fixed — D-6 now uses the sheet's words ("won’t be in an evidence graph. Citations can’t use it until it is linked.") and the plural of them; AC-1.1–AC-1.3 and T-4–T-6 updated. Same as X-6.

### X-1 · major · The version bump is in no step
**Answer:** Fixed — STEP-4 bumps `VERSION`, `core/version.go` and the 4 `MARKETING_VERSION` lines in its commit.

### X-2 · major · STEP-3's check cannot run off macOS
**Answer:** Fixed — STEP-3 adds a JSON check of `Localizable.xcstrings` and says off macOS the Swift checks are reported not run; a Stop condition says the same.

### X-3 · minor · STEP-2 and STEP-3 conflict on commit and check order
**Answer:** Fixed — the `swift_vocabulary_test` edit moved into STEP-3, where its check passes.

### X-4 · minor · T-2 does not say how to build the fixture
**Answer:** Fixed — T-2 names `f.newArtifact`, `f.link` and `f.createGraph`.

### X-5 · minor · T-1 lists a neighbor with no case
**Answer:** Fixed — T-1 case "unlinked Artifact".

### X-6 · minor · The sentence is not the Artifact sheet's words
**Answer:** Fixed with M-3.

### X-7 · minor · Small gaps in the Swift tests and the docs step
**Answer:** Fixed — tests join `PVDeleteImpactTests` after `graphDeleteConfirmReadsSingularForOneCitation`; full doc paths; the `completed.md` text and map status are given; the L10n and `.xcstrings` entries go beside `deletesHandles`.

### X-8 · nit · T-6 is not a whole-string compare
**Answer:** Fixed — §11 says T-6 checks prefix, overflow and suffix, as the Citations cap test does.
