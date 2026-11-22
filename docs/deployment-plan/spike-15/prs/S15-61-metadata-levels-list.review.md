# Review — S15-61 Metadata levels are one declared list

**Verdict:** Fits with changes — Ready with changes. After round 2 every finding is Fixed or Declined, and nothing is open.
**Rounds:** 2. **Reviewers:** maintainability (Opus) and executability (Sonnet), each in fresh context.

## To user

- **M-1:** should the effects registry's six metadata entries be built from the list in this PR? The map had deferred it as "a later cleanup". **Answered (user, 2026-11-22): fold it into S15-61.** The map scope entry is updated.

## Writer's own calls

These are calls the writer made that no source dictated; the user can veto any of them.

- **D-1:** `catalogmodel` imports `core/vocabkey`, a pure leaf, for the `Level` type.
- **D-3:** declined M-5. `OwnerTable` stays a field beside `Kind`.
- **D-8:** the generated metadata facets are spliced once, after the Source section. A Source's value facet then runs after its credibility facet: the same rows, in a different order within the revision.
- **D-9:** the Source level keeps `field("source_id")` rather than `up("source_id")`, so its effects entries stay exactly as they are today.

## Round 1 — executability

- **X-1 · major · The DoD sweep matches code the plan keeps.** **Answer:** Fixed. The sweep now matches `typeIn: +"SELECT` and says that the `typeIn: typeIn,` assignment stays.
- **X-2 · major · AC-2.3 reads as an order the PR changes.** **Answer:** Fixed. AC-2.3 now says "in any order, then `source` last".
- **X-3 · minor · `sourcePathIn`'s panics are underspecified.** **Answer:** Fixed, and moved with M-2. `catalogmodel.SourcePath` has four errors, each with its own message (§ 6), and T-1 matches each one.
- **X-4 · minor · The generated facets' column lists, comments and `ViaCitationFormats` are unnamed.** **Answer:** Fixed in D-8 and T-3.
- **X-5 · minor · Linux check-pr, the `completed.md` path and the status.** **Answer:** Fixed. The DoD notes that xcodebuild is skipped off macOS. STEP-6 and the DoD give `docs/deployment-plan/spike-15/completed.md` in full. Status stays Draft until review passes.

## Round 1 — maintainability

- **M-1 · blocker · The effects registry stays a fourth hand copy of each level.** **Answer:** To user, and the user answered "fold in" (2026-11-22). Fixed: D-9, STEP-5, T-6, AC-1.9 and AC-2.6, plus the map scope entry.
- **M-2 · major · A single `Parent` with no shared walker.** **Answer:** Fixed. `catalogmodel.SourcePath` (D-5) is now the one walk, and `sourcemetadata`, `effects` and T-1 call it. `Parent` is renamed `Up` (`MetadataUp`), so S15-55's graph link reads as a different relation. Next adds names `catalogmodel.Ancestors` for S15-55.
- **M-3 · major · Skills still teach hand-adding a metadata level's facet.** **Answer:** Fixed. STEP-6 updates `add-catalog-model`, `add-catalog-delete` and `add-catalog-migration`.
- **M-4 · minor · `catalogmodel.MetadataLevels` would collide with `vocabkey.MetadataLevels()`.** **Answer:** Fixed. The var is renamed `MetadataTables` and the type `MetadataLevelTables`.
- **M-5 · minor · The entry states the owner table twice.** **Answer:** Declined (D-3). `catalogmodel` has no exported Kind → table lookup; `deleteimpact.tableByKind` is private and filtered to deletable kinds. Adding one would save one string per entry, and T-1 ties the two fields together.
- **M-6 · minor · `ListDraftWorkspace` keeps a hand level check.** **Answer:** Fixed. It is in **Out** and **Next adds**, under S15-55.
- **M-7 · nit · Where `TestMetadataFacetOrder` lives.** **Answer:** Fixed. It moves to `facets_test.go`.

## Round 2 — executability

- **X-6 · major · The DoD sweep cannot reach zero hits.** **Answer:** Fixed. The effects sweep matches only the Artifact and graph metadata literals. "At the three levels" in `docs/source-layer-data-model.md` and `docs/citation-formats.md` stays, because it is true until S15-54.
- **X-7 · major · The splices are not valid Go inside a composite literal.** **Answer:** Fixed. D-7 and D-8 give the split-and-append shape and say where each list splits.
- **X-8 · major · D-9's scope formula is wrong as written.** **Answer:** Fixed. The columns are the owner column, then `path[i].Up.Column` for every entry but the last, passed as `up(cols...)`.
- **X-9 · major · T-3 cannot compile in `facets_test.go`.** **Answer:** Fixed. T-3 goes in a new internal-package file, `core/database/deleteimpact/facet_order_test.go`.
- **X-10 · minor · Test fixtures are left to the implementer.** **Answer:** Fixed. § 6 names the Citation fixture and the four bad lists, and says the error checks run in table order.
- **X-11 · minor · D-6's join rule is implied, not stated.** **Answer:** Fixed. D-6 now states the rule for any depth.
- **X-12 · minor · STEP-6 anchors.** **Answer:** Fixed. Each skill edit names the sentence or step it follows.

## Round 2 — maintainability

All round-1 answers were checked against the code and hold.

- **M-8 · blocker · The effects overlay only has room for `Search`, not for S15-54's values-only `EvidenceGraph`.** **Answer:** Fixed, in the reviewer's simpler shape. Extras stay partial literals in `registry`, and `metadataEffects` fills only the fields it owns, panicking if a literal sets one of them. S15-54 adds `"citation_metadata": {EvidenceGraph: …}` with no builder change. T-6 tests both the keep case and the panic case (D-9).
- **Below the bar (major):** `add-audit-scope` and `.cursor/rules/catalog-deletes.mdc` still teach the hand-wiring. **Answer:** Fixed. STEP-6 adds a one-clause exception to each.
