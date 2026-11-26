# Review — S16-69 A commit runs each effects lookup once

**Verdict:** Maintainability: Fits with changes. Executability: Ready with changes. No blocker open.
**Rounds:** 1. **Reviewers:** maintainability (opus), executability (sonnet) ([`review-plan`](../../../../.agents/skills/review-plan/SKILL.md)).

## To user

None.

## Writer's own calls

- `Handles` and `resolve` are deleted in this PR (M-2), not re-signed. This widens the map's scope entry (which said `Resolve` and `resolve` take a `Querier`): about 14 test call sites move to `Resolve(…).Handles`, and four prose lines (`docs/catalog-deletes.md`, `add-catalog-delete`, the `deleteimpact/facets.go` comment, the effects README) stop naming `effects.Handles`. The map row and scope entry are updated to match.
- The package's one counting double becomes an exported `QueryLog` in `export_test.go` (M-1), so `TestReadRowsColumnLooksUpEachIDOnce` asserts `Total() == 2` in place of `rows == 2`: the same claim through the new double.
- `readRowsColumn` moves from `QueryRow` to `Query` (through `lookup`) so one method owns the memo, as the working rule says.
- No timing benchmark: the PR sets no time budget; its claim is a query count per change, pinned by T-1.
- Version bump none.

## Round 1

### M-1 · major · One counting double per package, not two
D-6 rejected reusing `countingQuerier` as unreachable from `effects_test`; `export_test.go` already shows internal test code to the external package.
**Answer:** Fixed — D-5 makes `QueryLog` in `export_test.go` the one double, replacing `countingQuerier`; Codebase fit, T-2 and the DoD sweep follow. D-6 is gone.

### M-2 · major · `Handles` and `resolve` are a second walk loop with no production caller
**Answer:** Fixed — D-4 deletes them; STEP-1 moves the test callers to `Resolve(…).Handles` and fixes the four prose lines; Deletes, AC-1.5, the sweep and the map entry follow. Checked: `Resolve` folds `Handles` through `appendIDs` per change, the same first-seen order `resolve` builds.

### M-3 · minor · The input-selection snippet stays copied three times
**Answer:** Fixed — `lookup` takes `fromChange` and selects the inputs (D-1).

### M-4 · minor · Make the memo key a struct
**Answer:** Fixed — `memoKey{query string; id [16]byte}` (D-3, Codebase fit).

### M-5 · minor · Facts written twice; garbled "Rules this plan bends"
**Answer:** Fixed — "Rules this plan bends" is "None."; Risks rows point at D-IDs; Edges no longer restates D-3's immutability.

### X-1 · major · T-1's fixture inputs are left to the implementer
**Answer:** Fixed — §8 names `art.SourceID`, `dateID := only(…)[0].EntityID`, the Subject's label, `properties.LookupTx` for `start_date`, and the new imports.

### X-2 · major · D-2's ghost fallback leaves two behaviours unstated
**Answer:** Fixed — D-2 keeps the fallback as written (non-16-byte `raw`, `entityOf(table) != ""`); the Current state row says NULL counts too.

### X-3 · major · `lookup` may return the memo's own slice
**Answer:** Fixed — D-1: always a new outer slice, id bytes shared; Risks row 3.

### X-4 · minor · The STEP-3 mutation check is ambiguous
**Answer:** Fixed — "make `lookup` skip its memo-hit return".

### X-5 · minor · Choices left open in `queryLog`
**Answer:** Fixed — the Codebase fit row fixes what `Query`/`QueryRow` record, `Count`, `Repeats` and `Total`.

### X-6 · nit · §5 "Rules this plan bends" is garbled
**Answer:** Fixed with M-5.

### X-7 · nit · AC-1.1 covers less than its test
**Answer:** Fixed — AC-1.1 names the `observations.value_date_id` lookup too.

## Cost

Plan: 3,545 words at round 1, 3,753 at the verdict (check-plan-docs info line).

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| 1 | maintainability | opus | — |
| 1 | executability | sonnet | 115k |
