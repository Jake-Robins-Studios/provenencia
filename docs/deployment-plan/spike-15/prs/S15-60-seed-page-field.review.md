# Review — S15-60 The seed has a page field

**Verdict:** Fits with changes — Ready with changes (all fixed)
**Rounds:** 1 (no blocker, so no round 2). **Reviewers:** maintainability (opus), executability (sonnet)

## To user
- M-1, the page order until S15-58. Answered (user, 2026-11-25): keep `{meta.page|citation.page}` as the map says; one dogfood project, and no Page is typed on a board until S15-58 lands, so take the simplest order and do not test the case. Recorded in §6 Edges "Neighbors".

## Writer's own calls
- D-2: the field before the built-in, as the map's scope entry says (confirmed by the user under M-1).
- D-4: no `vocabkey` key for `page` until S15-56's first reader.
- D-5: `Board.Page` and `page_requirement` stay for S15-58; seeded types now report them as none (no Swift reader); a `newLedger` test type keeps the built-in-head path tested.
- D-6: the render golden stays byte for byte; the fixture answers the `page` field "14".
- D-8: the docs this PR makes false (map §§ 6.8, 6.10 and `seeded-vocabulary.md` § 1) are rewritten here, beyond the scope entry's § 6.9 and `seeded-vocabulary.md`.
- Version 0.42.0 (minor: a new seeded field that citations read).

## Round 1

### M-1 · major · A farther-level `page` beats the Citation's locator page until S15-58
The chain lets a graph, Artifact or Source Page win over the composer's Printed page on the Citation.
**Answer:** To user → answered: keep the order; Edges "Neighbors" names the case with the user's answer; no AC.

### M-2 · major · Docs the seed change makes false are missing
`seeded-vocabulary.md` § 1's "68 fields … the map's 63", map § 6.10's unknown-text sentence, and § 6.8's "Usual level" column.
**Answer:** Fixed — D-8 now points at STEP-5, which edits all three; the DoD `rg`s the old counts.

### M-3 · major · The render fixture's built-in page case becomes unreachable
**Answer:** Fixed — D-6 and T-3: the built-in `page` case of `fixture.Resolve` is deleted; `noPage` blanks the field.

### M-4 · minor · D-1 leaves the rest of the `seedFields` head comment false
**Answer:** Fixed — D-1 gives the whole comment.

### M-5 · minor · T-6's locator literal repeats `likenessLocatorJSON`
**Answer:** Fixed — D-7 uses `likenessLocatorJSON`; the existing inline copies are left (not this PR's files).

### M-6 · minor · Facts stated twice
**Answer:** Fixed — §1 "What stays" points at Out and D-5; D-8 points at STEP-5; the Codebase fit row points at D-7.

### M-7 · nit · `TestSeedFieldsAreRead` gets a third hard-coded key
**Answer:** Fixed — T-1: a `map[string]string` of expected unknown texts.

### X-1 · blocker · STEP-5's `rg` check fails on § 6.10's "Built-ins" line
**Answer:** Fixed — the check allows § 6.3's table and § 6.10's "Built-ins" sentence, both S15-58's.

### X-2 · major · D-1's head comment half specified
**Answer:** Fixed — same edit as M-4.

### X-3 · major · `TestRenderSeededPage`'s shape left open
**Answer:** Fixed — T-6 names the project, the `newspaper` helper, one `t.Run` per AC, each making its own Source, and the AC-1.3 assertion through `strings.NewReplacer` on `renderCensusFull`.

### X-4 · major · T-5's ledger case ambiguous
**Answer:** Fixed — T-5 gives the calls (`newLedger`, `l.setFormats`, `boardOf(...).Page`, `runSet`) and keeps the `plain` assertions.

### X-5 · minor · `completed.md` and `deployment-plan.md` paths
**Answer:** Fixed — full paths in STEP-5.

### X-6 · minor · Doc edits not word for word
**Answer:** Fixed — STEP-5 gives the § 2.2 sentence, the row, and the § 6.8 row and header.

### X-7 · minor · Some checks cannot run on Linux
**Answer:** Declined — `scripts/check-pr.sh` and the manual check run on the implementer's Mac, as for every plan.

## Cost
Plan: 3,995 words at round 1, about 4,400 at the verdict (check-plan-docs info line).

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| 1 | maintainability | opus | — |
| 1 | executability | sonnet | 146k |
