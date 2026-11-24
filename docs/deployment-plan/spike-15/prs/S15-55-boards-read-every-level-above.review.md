# Review — S15-55 Boards read every level above

**Verdict:** Fits with changes — Ready with changes (all fixed)
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet)

## To user
- None.

## Writer's own calls
- D-6: a draft's parents may come in any order; they must share one Source; the read does not check the graph–Artifact link (D-7), which the Citation create already refuses.
- D-9: Swift's `getDraftMetadataBoard` takes `parents` in this PR (M-4), so the map row and scope entry now read "Go, and Swift's draft-board store call". No view changes. `FakeStore` keys drafts by sorted parent ids.
- The map's scope entry Check names `{meta.line_number}` instead of `{meta.page}`: `page` is not seeded until S15-60.
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

## Round 2

Both reviewers found every round-1 answer sound (M-6's decline included).

### M-7 · blocker · The draft board works out its ancestors a second way, and `boardSpec` repeats `ownerAbove`
**Answer:** Fixed — D-3, D-6, Codebase fit: `boardSpec` is gone; `buildBoards` takes `[]ownerAbove`, and a draft is an `ownerAbove` with a nil owner ID and the parents as its up ids, so its ancestors come from `OwnersAbove`. The below-bar note on `FakeStore`'s key is taken too (D-9: sorted parent ids).

### X-8 · blocker · STEP-5 cannot run without the proto toolchain
**Answer:** Fixed — STEP-5 says to stop after STEP-4 when `generate-proto.sh` exits for a missing tool or off macOS, and what to hand over.

### X-9 · major · The "before" benchmark is never taken
**Answer:** Fixed — STEP-2's check runs it with `CGO_ENABLED=1 -count 5`; STEP-3 compares medians; the stop condition says medians.

### X-10 · major · The sweep cannot come out clean
**Answer:** Fixed — the DoD lists the hits to change and the hits that stay.

### X-11 · major · No step updates the map's scope entry
**Answer:** Fixed — the scope entry's Ships, Check and Context lines were rewritten with this plan; STEP-7 says only the row status changes.

### X-12 · minor · Choices left to the implementer
**Answer:** Fixed — D-2: `readAbove` is `ErrInvalid` on a missing row for every caller; D-3: `buildBoards` returns boards in input order and `listWorkspaces` keys them back; T-6 names the compared fields; T-1 names both levels in the error; T-8 reads the type id and uses a fresh fixture; T-7 gives the table's row type; D-9 spells out the stub.

### X-13 · minor · The risk guard did not guard the draft read
**Answer:** Fixed — §11 names `TestListDraftWorkspaceInherited`, `TestGetDraftMetadataBoard` and T-6.

## Cost
Plan: 5,345 words at round 1, 6,135 at the verdict (check-plan-docs info line).

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| 1 | maintainability | opus | 157k |
| 1 | executability | sonnet | — |
| 2 | maintainability | opus | — |
| 2 | executability | sonnet | — |
