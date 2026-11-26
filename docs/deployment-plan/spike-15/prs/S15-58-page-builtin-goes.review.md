# Review — S15-58 The page built-in goes

**Verdict:** Fits with changes — Ready with changes
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet)

## To user
- None.

## Writer's own calls
- D-5: no migration and no install-on-open rewrite of stored formats; a stored `{citation.page}` stops parsing until fixed, and the PR description carries two `replace` statements for the dogfood project (precedent S15-62, user 2026-11-22).
- AC-1.2: a Citation whose page is only a locator `page_label` prints no page (follows the user's 2026-11-25 call not to move labels into `page` values).
- D-3: test fixtures keep their locator labels and gain a `page` value with the same text, so expectations do not change.
- D-4: `builtinHeads` stays a map with one key (`SourceDate`).
- D-8: S16-79's planned formats edited to `{meta.page}` during planning, with a note in both maps.
- Version: minor, 0.45.0.

## Round 1

### X-1 · blocker · STEP-5 check contradicts D-6
The `rg` excludes `*.pb.*` but not `engine.proto`, whose `reserved "page_requirement"` line would hit.
**Answer:** Fixed — STEP-5 Check excludes `engine.proto` and expects exactly the `reserved` line there.

### X-2 · blocker · STEP-3 check does not run the tests the step edits
`-run 'Render|Placeholder'` skips `TestGroupKey`.
**Answer:** Fixed — the `citationrender` package runs with no `-run`; the handlers keep `-run 'Render|Placeholder'`, which matches every handler test STEP-3 edits.

### X-3 · blocker · Current state misses compile breaks and failing tests
`TestListWorkspacesAnnotations` (3144) and `TestSeedAnnotations` (3427) read `Board.Page`; `newRenderWorld`'s `w.citation`, "AC-1.2 equal pages group" and "AC-1.3 a Citation's page beats the locator's" in `citation_render_test.go` print pages from labels; `censusValues`' `cit` goes unused.
**Answer:** Fixed — §4 rows name each; STEP-1 drops both `cit`s; STEP-3 gives `newRenderWorld`, "AC-1.2" (14/14/15) and "AC-1.6" their `page` values and renames "AC-1.3"; STEP-4 drops the two `Page` conditions; Stop condition allows deleting a `Board.Page` assertion.

### X-4 · blocker · STEP-7's docs check cannot pass as written
Also hits `completed.md`, rule "The printed page is a metadata field", the S15-60 row and scope entries, and S16-79.
**Answer:** Fixed — the expected hit list names each history line that stays; S16-79 is edited in planning (D-8).

### X-5 · major · No step carries the version bump and status
**Answer:** Fixed — STEP-8 *(new)*.

### X-6 · major · Checks need tools absent on Linux
**Answer:** Fixed — STEP-5 and STEP-6 say they run on the Mac; without `protoc` the implementer stops rather than hand-editing generated files.

### X-7 · minor · Commits are not mapped to steps
**Answer:** Fixed — STEP-1 – STEP-5 are one commit (the tree does not build between them); STEP-6, -7, -8 one each.

### X-8 · minor · Test rows are vague
**Answer:** Fixed — T-4 names `TestRenderCensus` and `TestRenderCitations`; STEP-3 says which Citation gets which mark in `TestRenderUnknownAndSupplied`.

### X-9 · minor · The hand-run `replace` does not cover a head or bare `{citation.page}`
**Answer:** Fixed — D-5 says the statements cover the seeded forms, where `citation.page` is never a head, and a researcher-written one is fixed in the editor.

### M-1 · blocker · An open Spike 16 plan writes the placeholder this PR retires
`S16-79-voters-list-type.md` lines 181–182 seed `{meta.page|citation.page}`.
**Answer:** Fixed — edited to `{meta.page}` in this planning PR (valid before and after S15-58); D-8; **Blocks** and **Next adds** name S16-79; notes in the Spike 15 dependency list and the Spike 16 S16-79 row; Stop condition counts on `main` at rebase.

### M-2 · major · `interpretation-layer-data-model.md` § 3.2 goes false
"A citation prints an unknown page as "unpaginated" and a supplied one in square brackets."
**Answer:** Fixed — STEP-7 rewrites the sentence; DoD names the doc.

### M-3 · minor · D-4 keeps a one-key map
**Answer:** Declined, with the comment — D-4 now has the `levelNeeds` comment name its one key; collapsing it rewrites `annotate`'s generic branch and `fieldIDs` for no reader's gain.

### M-4 · minor · Deletes misses `censusValues`' `cit`
**Answer:** Fixed — Deletes names both.

### M-5 · minor · Test locators keep a label that no longer prints
**Answer:** Fixed — D-3: `pageLocator` and `pageLocatorJSON` each get a comment saying so, and Next adds points S15-59 at them.

### M-6 · nit · §1 What stays restates §3
**Answer:** Fixed — trimmed to one sentence.

## Round 2

### X-10 · blocker · STEP-3's check cannot pass before the board and wire edits
`citationrender` imports `sourcemetadata`, which still named `CitationPage`; the handlers need `sources.go` fixed.
**Answer:** Fixed — the board step is now STEP-3 and the renderer STEP-4; the handler render tests run in STEP-5's check.

### X-11 · major · STEP-7's docs check misses two history lines; § 1 edit ambiguous
**Answer:** Fixed — the expected hits name the "S15-58 — S16-79" dependency line and Spike 16's S16-79 row; § 1 drops one named clause.

### X-12 · minor · FuzzAnnotate seed edits
**Answer:** Fixed — STEP-3 gives both seeds' exact text.

### X-13 · minor · TestSourceBoardBuiltins court-report indexes
**Answer:** Fixed — STEP-3 gives the length, index and message.

### M-7 · blocker · STEP-7's check and Files
**Answer:** Fixed — the hit list was corrected with X-11; STEP-7 Files adds `docs/interpretation-layer-data-model.md`. The `Annotation` comment and `TestSourceBoardBuiltins`' case comment are added to STEP-3; the proto comment is D-6's.

## Cost
Plan: 4,065 words at round 1, about 4,560 at the verdict.

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| 1 | maintainability | opus | 140k |
| 1 | executability | sonnet | 135k |
| 2 | maintainability | opus | 143k |
| 2 | executability | sonnet | 129k |
