# Review — S16-78 Install derives each seeded type's suggested fields from its formats

**Verdict:** Fits · Ready with changes, two rounds; no blocker open.
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet) ([`review-plan`](../../../../.agents/skills/review-plan/SKILL.md)).

## To user

None. The PR itself is the user's answer to S16-79's review finding M-5 (2026-11-26).

## Writer's own calls

- Version bump: none, since a new project's rows are unchanged.
- `registry_suggestions.go` keeps its name and holds the rule.

## Round 1

### M-1 · blocker · `suggestedKeys` parsed each form a second way
**Answer:** Fixed. D-1 builds on `Formats.Parse` and has no error return; D-2 has no branch of its own.

### M-2 / X-2 · major / blocker · `seedSuggestionKeys` keeps the deleted name, and AC-1.2's `rg` hits it
**Answer:** Fixed. It is renamed `suggestedKeysOf` (D-6). AC-1.2 and STEP-2's check use the same pattern.

### M-3 · major · `docs/seeded-vocabulary.md` line 83 stays false
**Answer:** Fixed. STEP-3 rewrites its clause, and § 4's Docs row names it.

### M-4 · major · The census count of 18 is S16-79's first edit
**Answer:** Fixed with option A. `TestSuggestedKeys` pins `creator` first and `citing` last with no count, and § 2.3 drops "18".

### M-5 · minor · "Names only seeded fields" repeats `TestSeedFieldsAreRead`
**Answer:** Fixed. That assertion is dropped from T-3.

### M-6 · nit · D-4 and D-5 restate the tests
**Answer:** Fixed for D-4. D-5 keeps the test type's literal, because the implementer needs it and § 8 points at it.

### M-7 · nit · D-2's guard
**Answer:** Fixed, together with M-1.

### X-1 · blocker · STEP-1's check fails once `Install` stops reading `seedSuggestions`
**Answer:** Fixed. D-5's replacement case moves into STEP-1.

### X-3 · major · What `derivedSuggestions` and the helpers do with the error
**Answer:** Fixed. There is no error any more (M-1).

### X-4 · major · D-5's test type and where its error arises
**Answer:** Fixed. D-5 gives the whole type literal and says that `ToStored` refuses it.

### X-5 · minor · The § 4 Docs row
**Answer:** Fixed. It now names line 83 and § 2.3.

### X-6 · minor · Smaller gaps
**Answer:** Fixed. The unused `maps` import is dropped, `mustParseForm` stays, `TestInstall` loops once over `seedTypes`, and the not-empty check stays.

## Round 2

One fresh reviewer (opus) worked both lenses with the plan and this log and found no new blockers. Every round-1 answer holds, except where two edits had not reached every section.

### X-7 · major · STEP-1 could not compile: the `maps` import was dropped only in STEP-2
**Answer:** Fixed. STEP-1 drops it and names `registry_suggestions.go`'s new imports.

### X-8 · major · § 6 Go core still gave `suggestedKeys` an error return
**Answer:** Fixed. The row points at D-1, which holds the one signature.

### X-9 · nit · "Three uses" of the helper
**Answer:** Fixed. It has one definition and two call sites.

**Final verdict:** Fits · Ready with changes, two rounds; no blocker open; To user: none.
