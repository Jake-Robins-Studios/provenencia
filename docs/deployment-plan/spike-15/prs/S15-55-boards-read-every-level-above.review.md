# Review — S15-55 Boards read every level above

**Verdict:** (pending round 2)
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet)

## To user
- None.

## Writer's own calls
- D-6: a draft's parents may come in any order; they must share one Source; the read does not check the graph–Artifact link (D-7), which the Citation create already refuses.
- D-9: Swift's `getDraftMetadataBoard` takes `parents` in this PR (M-4), so the map row's scope now reads "Go, and Swift's draft-board store call". No view changes.
- D-10: the render's owners come from `OwnersAbove`; its reads do not change.
- Version 0.40.0 (minor: a wire field changes).

## Round 1

### M-1 · blocker · `boardValues` would be a third way to build `CitationValues`
`citationrender.fillValues` already builds the same rows; one exported constructor should serve boards and renders.
**Answer:** Fixed — D-4: `ValuesOf(rows, owners, fields)` *(new)* replaces the three literals (`listWorkspaces`, `ListDraftWorkspace`, `fillValues`); `boardValues` is gone. §11's stop condition now names `ValuesOf` and `Without` as the only production literals.

### M-2 · blocker · Two mechanisms would answer "a Citation's owners at every level"
`subject.owners()` kept its hand list beside `ancestors()`, tied by a parity test.
**Answer:** Fixed — D-1, D-10: `OwnersAbove(level, upIDs, sourceID)` *(new)* is the one derivation; `ownerAbove.ancestors()` and `subject.owners()` both call it with ids they already hold. The parity test is replaced by `TestOwnersAbove` (T-9).

### M-3 · major · The draft board keeps its own copy of the board steps
**Answer:** Fixed — D-3: `boardSpec` and `buildBoards` *(new)* build saved and draft boards; `ListDraftWorkspace` is the parent checks, `readAbove` and one spec with no own owner. T-6 compares a draft with a saved empty board.

### M-4 · major · Swift keeps the `sourceID` the wire removes
**Answer:** Fixed — D-9, STEP-6, T-11: `getDraftMetadataBoard(projectDir:parents:level:)` on `GenealogyStore`, `GoStore`, `FakeStore`; the one caller passes the Source; the map row's scope says so.

### M-5 · minor · "line" already means something
**Answer:** Fixed — `ownerLine` / `readLines` renamed `ownerAbove` / `readAbove`; T-1's fixture level is `"deep"`.

### M-6 · minor · `newCitationOwners` beside `newLevelOwner`'s citation case
**Answer:** Declined — `newLevelOwner`'s citation case uses `evidencegraphstest.SoleGraph` on a one-graph Source and serves the level-loop tests (lines 1982, 2080, 2517, 2795); `newCitationOwners` exists because `newLedger`'s Source has two graphs, where `SoleGraph` fails. Routing the level-loop tests through it would add a graph to their Sources for no gain. The `needOfTx` half is Fixed (D-2: `needOfTx` calls `readAbove`).

### X-1 · major · The first stop condition is already true at the base
**Answer:** Fixed — §11 now runs `rg` on non-test files after STEP-4 and names the allowed literals.

### X-2 · major · `ancestors()` for a Source owner is undefined
**Answer:** Fixed — D-1 and `OwnersAbove`: a Source has none; `ownerAbove` holds its `owner`; up owners take their level from `store.ups` (Codebase fit).

### X-3 · major · Several checks need macOS
**Answer:** Fixed — STEP-5 names the proto toolchain and "never hand-edit the generated files"; STEP-6 says to stop after STEP-4 off macOS.

### X-4 · minor · STEP-4 leaves the build broken
**Answer:** Fixed — STEP-4 to STEP-6 are one commit.

### X-5 · minor · Sweep pattern and draft-read details
**Answer:** Fixed — the DoD sweep uses a case-insensitive pattern and lists the seven lines; D-6 names the type, date and fields sources (now through `buildBoards`).

### X-6 · minor · Fixture choices left open
**Answer:** Fixed — `newCitationOwners` row says how it builds the graph and that `l.graph` is not used, and that `citations` allows repeats; AC-1.5 names the mark input; AC-1.9 names its assertion.

### X-7 · nit · "before any query" holds for shape checks only
**Answer:** Fixed — D-6 says "Shape checks, before any query".

## Cost
Plan: 5,345 words at round 1, 5,954 after the round-1 fixes (check-plan-docs info line).

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| 1 | maintainability | opus | 157k |
| 1 | executability | sonnet | — |
