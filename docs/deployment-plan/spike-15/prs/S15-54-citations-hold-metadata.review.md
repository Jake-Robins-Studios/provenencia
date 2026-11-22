# Review — S15-54 Citations hold metadata

**Verdict:** Fits with changes — Ready with changes (round 2). No blocker open; the S15-D30 board agreed 2026-11-22; the plan is Planned.
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet)

## To user
- **Answered 2026-11-22.** The board is agreed. M-3: the Evidence graph copy reworded as drawn. Not taken from the board: suggested-first ranking in completion and multi-word narrowing (D-15).
- **M-3 (copy, through the board).** The Evidence graph list's meaning and empty copy say "one item … an entry" and "its line", which the rule "Page-relative fields are read from the Citation first" now gives to the Citation. The brief rewords them ("Your grouping of evidence: a household, a family"). Recommendation: keep the rewording; the board settles the words.
- **The board.** S15-D30 is written, not drawn. The plan stays Blocked until the board is agreed and its link is on the plan's **Board** line.

## Writer's own calls
- D-4: delete the `meta_not_at_level` diagnostic and every level check that can no longer fail (Swift `holdsMetadata`, the FakeStore guards, the `Placeholders` branch); keep Go `HoldsMetadata` on the wire guards.
- D-9: `CreateCitedBridge` takes no draft (the composer creates its Citation first).
- D-10: the Swift store gets its `metadata` parameter in S15-56, with its first caller.
- D-5 (user, 2026-11-22, M-7): no graph-cache path for `citation_metadata` in this PR; S15-56 adds it with its reader. Map rule and both scope entries reworded.
- D-11: corrected the map scope entry's Scale: a Source or Artifact delete never reaches a Citation; a graph delete releases at most about 80 value rows.
- The brief draws the Metadata page's delete-notice line instead of a second brief for one line.
- The Citation list's copy ("On each Citation", "The spot you cite: a page, a line, an entry") is proposed; the board may change it.
- Version minor, 0.34.0.

## Round 1

### M-1 · major · D-4 keeps checks that can no longer fail, while deleting their twin in the parser
Swift `holdsMetadata` (closed enum, every case in `metadataLevels`), the three `FakeStore` guards, and `citationrender.Placeholders`' branch can never fire; keep only the wire guards in `sourcevocab`.
**Answer:** Fixed — D-4 now states the test (a check stays only where its input can hold a non-metadata level) and deletes the four checks and Swift `holdsMetadata`; **Deletes**, STEP-2, STEP-7 and the DoD sweep (`holdsMetadata`) follow.

### M-2 · minor · The DoD's stale-wording search hits files no Step lists
`CatalogMutation.swift:37`, `SourceTypePageModel.swift:5`, `GenealogyStore.swift:1307`.
**Answer:** Fixed — § 4 row "Swift level checks and comments", § 6 Strings "Comments", STEP-7 Files.

### M-3 · minor · Existing Evidence graph copy reuses "entry" and "line", now the Citation's words
**Answer:** Fixed in the brief and § 6 Strings (the graph's meaning and empty copy reworded); To user through the board.

### M-4 · minor · Each further level adds owner lines in two places in `fillValues`
**Answer:** Fixed — D-6 builds a subject's owners once in `ownersOf` (Codebase fit row); **Next adds** says S15-55 moves `ownersOf` and the effects literal's graph path onto the declared ancestor chain.

### M-5 · minor · The draft-on-owner-write steps become a fifth and sixth copy
**Answer:** Declined — `applyDraft` already holds the rule (`api/ffi/handlers/metadata.go` `applyDraft`); what repeats at each call site is one `append` around a differently typed `writes.Run` result (`artifacts.Artifact`, `evidencegraphs.Graph`, `citations.CreateResult`, `citations.Citation`), so a helper would save one line per site. D-8's Rejected column records it.

### X-1 · blocker · Existing tests that expect the Citation level to be refused are not in any Step
Seven assertions in `sourcevocab_test.go`, `copy_test.go`, `sourcemetadata_test.go`, `source_defs_test.go`, and the local Citation entries in `TestSourcePath` / `TestSourcePathIn`.
**Answer:** Fixed — § 4 row "Tests that expect the Citation refused"; new T-16 gives each its new expectation; STEP-1 and STEP-6 list the files.

### X-2 · major · User-facing copy and comments that become false are not in Strings or the sweep
**Answer:** Fixed — `error.metadatafields.in_use` reworded in § 6 Strings; every comment named with its new text (§ 6 Strings "Comments"); `docs/source-layer-data-model.md` line 204 in STEP-9; the sweep widened to "holds no metadata" and "Source, Artifact or Evidence graph"; the xcstrings comment named.

### X-3 · major · The plural string variants are not given
**Answer:** Fixed — § 6 Strings gives `one` and `other` for `deleteImpact.via.citationMetadataFieldId`. The removed-body toast keeps its existing plural handling; only its text changes.

### X-4 · major · Test fixtures are left to me
**Answer:** Fixed — T-1 (`artifactstest.Create`, `evidencegraphstest.SoleGraph`, `citations.CreateWithObservations` with an artifact locator; both loops run four levels), T-6 (`scaleValues[3]` with `entry_number`, seeded after each Citation insert), T-10 (`citation` owner via `CreateCitationWithObservations`; the assign loop takes `"citation"`), T-11 (Citation owners on `ownerFixture`; release by `citations.Delete`; new `TestGraphDeleteReleasesCitationValues` with `evidencegraphstest.Create`).

### X-5 · minor · Docs wording is left to the implementer
**Answer:** Fixed — STEP-9 gives every sentence, and adds `docs/catalog-deletes.md` lines 50 and 56.

### X-6 · minor · Check commands that tell me little
**Answer:** Fixed — STEP-1's check names `TestMetadataTables` and no longer names `TestMetadataEffects`; STEP-5's check looks for the generated fields; STEP-7 and STEP-8 run Swift through `scripts/check-pr.sh` on a Mac and say to report them as not run elsewhere. The SELECT counts stay with their Stop condition.

### X-7 · minor · Small gaps
**Answer:** Fixed — D-8 gives both closures' shapes. The rest needs no change.

## Round 2

Executability (sonnet): round-1 answers X-1 – X-5 and X-7 accepted; X-6 partly (see X-8). Verdict Ready with changes.

### X-8 · blocker · STEP-5 and STEP-6 checks run `./api/...`, which fails until STEP-7 and STEP-8
`api/ffi/swift_vocabulary_test.go` `TestSwiftVocabularyMatchesGo` reads the Swift mirrors, which move only in STEP-7 and STEP-8.
**Answer:** Fixed — STEP-1, STEP-5 and STEP-6 run their Go checks with `-skip TestSwiftVocabularyMatchesGo`; STEP-7 runs its `metadata_levels` case; STEP-8 runs every case.

### X-9 · major · `TestSourcePath` "missing level" case breaks and the plan does not replace it
**Answer:** Fixed — T-16 names `"nowhere-level"` for the "missing level" and `missingUp` cases, with each case's expected error.

Maintainability (opus): M-1, M-2, M-3, M-5 accepted; M-4 not accepted (the **Next adds** sentence was missing). Verdict Fits with changes.

### M-4 (round 2) · The Next adds sentence was missing
**Answer:** Fixed — § 6 **Next adds** now says S15-55 derives `ownersOf`'s chain from the declared graph link and deletes the hand-written copy. The round-1 **Deletes** edit had not landed either; it is in now.

### M-7 · blocker · D-5 adds a graph-cache path for a table no cache loads yet, against `add-audit-scope`
**Answer:** To user → answered (2026-11-22): move the path to S15-56. D-5 now declares no `citation_metadata` literal; AC-4.1, T-5, T-10, Scale, Edges and the stop conditions follow; the map's rule "The printed page is a metadata field" and the S15-54 and S15-56 scope entries say S15-56 adds it. No rule is bent.

### Notes (below the blocker cap)
- X-4: T-1 and T-11 now use `observationstest.Cite`. **Answer:** Fixed.
- `api/ffi/handlers/source_defs_test.go` line 581 ("three levels' lists"). **Answer:** Fixed — § 6 Strings "Comments".
- `TestEvidenceGraphPathsEndAtGraphs` would have broken under D-5's literal. **Answer:** moot after M-7; T-5 says it stays as it is.
