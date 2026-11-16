# Review — S16-37 The list merge has a file of its own and no test-only parameters

**Verdict:** Fits with changes — Ready with changes
**Rounds:** 1 (no blocker, no reshape, so no round 2). **Reviewers:** maintainability (Opus), executability (Sonnet)

## To user
None.

## Writer's own calls
- The new file's name, `CatalogListMerge.swift`, matches the test file (D-1).
- The `CatalogLastUpdatedRows` conformance of `CatalogListRows` moves with the struct, because it reads the struct's private index (D-3).
- The tests force a path through the touched-id count, the app's own rule: at most 16 ids for the indexed path, and 17 of the list's own ids for the one pass (D-5, from review M-3).
- The random equivalence test draws at most 8 dropped ids and 8 fresh rows, so its indexed assertion runs the indexed path (D-6).
- The map's S16-37 row was first written as `quick-pr`. It fails the quick fit list, because it is not one behavior and moves about 165 lines, so it gets a full plan.

## Round 1

### M-1 · major · S16-38's map row now points to this plan and reads Draft
**Answer:** Fixed. The S16-38 row is back to `quick-pr | Scoped`. STEP-4's check now says the map diff changes only the S16-37 row and its scope entry.

### M-2 · minor · MNT-5 is only half closed and the rest has no home
**Answer:** Fixed. §1 says this PR closes the list-merge half. The Out row's home is now `docs/ideas/structural-debt.md` row P-29, added with this plan, and the map scope entry's Context points to it.

### M-3 · minor · Pad ids choose the path through an accident of the touched count
**Answer:** Fixed. D-5, D-6, D-7, AC-2.3, AC-2.5, T-1 and T-3 now force the one pass with 17 of the list's own ids, and there is no pad helper. Unknown ids stay covered by `pickID`'s `"u…"` ids.

### M-4 · minor · A new Go-ordered list now edits two conformance lists, and the skill names only one
**Answer:** Fixed. D-9 is new. STEP-4 adds a clause to `add-workspace-place` line 178, and Next adds names both files.

### M-5 · nit · Test helpers are generic over a type they ignore
**Answer:** Fixed. `merged` works on the test's private `Row` only (D-7), and the pad helper is gone (M-3).

### M-6 · nit · AC-1.2 names the wrong remaining hit, and a Planned S15 PR cites line numbers in this file
**Answer:** Fixed. AC-1.2 now names the doc comment on `CatalogLastUpdatedRows` and `mergedRows`. §4 has a row for S15-12's line references, and the map's "Shared with Spike 15" table has a row for S16-37 → S15-12.

### X-1 · major · The AC `rg` lines are written with `\|` and would match nothing
**Answer:** Fixed. The three commands sit in a `bash` block under §2 with plain `|`, and the AC rows, STEP-1, STEP-2 and §10 refer to that block.

### X-2 · major · `pads<R>(_: R.Type)` will not compile as written
**Answer:** Fixed, by removing the helper (M-3).

### X-3 · minor · D-6's follow-up merge leaves small choices to the implementer
**Answer:** Fixed. In D-6, `fresh2` rows take `note: "fresh2"` and are drawn after `fresh`. `merged` is an instance method (D-7).

### X-4 · minor · T-2's timing placement is unspecified
**Answer:** Fixed. D-7: the copy is made outside `measure` and the mutation runs inside it, as `best` does today.

### X-5 · minor · Runs-on-macOS note and STEP-1's check disagree
**Answer:** Fixed. The note now says which of STEP-1's checks need `xcodebuild` and which run anywhere.

### X-6 · minor · STEP-4 leaves the status and PR-number wording open
**Answer:** Fixed.
- STEP-4 now gives the status texts, says they are written after the PR is open, and puts the `completed.md` paragraph at the top of the file.
- D-8 rewords the map's Check line to the claims the tests keep.
- The map row already linked the plan, so STEP-4 no longer sets it.

### X-7 · nit · STEP-1's blank-line instruction is unnecessary
Logged.

Temptations the executability reviewer listed: the moved doc comments and the test file's header are now an Out line ("not planned").
