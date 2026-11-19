# Review — S15-44 The printed page can be marked unknown or supplied

**Verdict:** Fits with changes — Ready with changes
**Rounds:** 2. **Reviewers:** maintainability (Opus), executability (Sonnet)

## To user

None.

## Writer's own calls

- D-1: the mark is about the printed page only; `artifact_page` never counts as a value, and a blank label counts as none.
- D-3: a refused pair returns `valuemark.invalid`, not `locator.invalid`, as the Source date and metadata values do.
- D-3 / D-6 (changed in round 1): writes refuse a bad pair (`Validate`), and reads settle it (`Page` through `valuemark.Settle`). `parse` checks only that the selector holds something. A selector holding `page_unknown` alone is valid: an image whose original prints no number.
- D-3 (round 2): one `pageSelector` finder serves the write check and the read settle.
- D-5: a mark on a depiction's region document is ignored, not checked.
- D-7: `graphfill` and the wire stay unchanged. The resolver (S15-16) reads `locator.Page` itself.
- The version bump is minor (0.26.0), as S15-13 did for the label-only selector.
- This is not a quick PR: it is a feature, not a fix with a reproducible wrong result (quick-pr fit line 1), and two map PRs build on it.

## Round 1

### M-1 · major · The plan cites go-tests.mdc for table tests only; its fuzz rule is skipped
`.cursor/rules/go-tests.mdc` § "Fuzz targets" applies to `core/locator`. That package parses `locator_json` and has no fuzz target. Precedent: `core/citationformat/fuzz_test.go` `FuzzParse`.
**Answer:** Fixed. T-5 `FuzzValidate` *(new)* checks two properties. `Page`'s mark always passes `valuemark.Validate` against its label, and a valid document reads its raw pair. STEP-2 runs it for 5 minutes, and the DoD has a fuzz line. The header names the rule.

### M-2 · major · D-6 and D-7 contradict the map's own lines and leave them false
The map's S15-53 entry names "S15-44's page read" as `valuemark.Settle`'s next caller. The S15-44 entry says `graphfill` reads the mark. Outside the reviewer's lens: with the pair check in `parse`, a stored locator that reads today, with a stray `page_unknown` beside a label, would lose its page in `graphfill` and its depictions in `depictionvalue.Readable`.
**Answer:** Fixed, with a reshape. Checking this showed the S15-53 split fits better than defending D-6.
- D-3 now splits the work. `validatePage` (in `parse`) does the structural checks. `Validate` (write only) runs the pair check (round 2 M-7 replaced the planned `validateMarks` with one `pageSelector` finder).
- D-6 settles the mark in `citationPage`. One `selectorRaw.pageMark` computes "has a label" for both paths.
- AC-2.4 and AC-3.4 pin the crafted-data reads.
- STEP-4 rewrites the map's S15-44 entry for D-7. The S15-53 entry is now true as written.

### M-3 · minor · Doc comments and domain-doc lines this PR makes false are not in STEP-4
**Answer:** Fixed. §6 Go core now edits the `PageRef`, `ArtifactPage` and `ValidateDepictionRegion` docs. STEP-4 edits § 3.2 line 209, and the DoD sweep `rg`s the old phrases.

### M-4 · minor · D-5 says a region document's mark is "accepted and ignored", but it is validated
**Answer:** Fixed by the D-3 reshape. Region documents go through `parse` only, so their mark is truly ignored. AC-3.4 pins this.

### M-5 · nit · `PageRef` zero value vs an unknown-only selector
**Answer:** Fixed. The `PageRef` doc now says how to test for no page, and Edges notes it.

### M-6 · nit · Bare error vs `WithParams`
**Answer:** Fixed. §4 Precedent says why the bare error is enough.

### X-1 · minor · The tail of the § 3.2 sentence
**Answer:** Fixed. STEP-4 says ", as is `artifact_page` below 1." stays.

### X-2 · minor · § 3.2 line 209 and the composer sentence
**Answer:** Fixed. STEP-4 adds a sentence after line 209 and keeps the composer sentence.

### X-3 · minor · Where the new example goes
**Answer:** Fixed. It goes after the first JSON block of § 3.2, with its lead-in text given.

### X-4 · minor · `go vet ./...` differs from the gate
**Answer:** Fixed. The check now uses `go vet -tags fts5 ./api/... ./core/...`.

### X-5 · minor · Checks that cannot run on Linux; the map row contents
**Answer:** Fixed. STEP-4 names the Go part of check-pr to run on Linux and leaves the Xcode part to the Mac or CI. The map row's Plan and Status values are spelled out. The lint warning about the map link goes away when the row is wired.

### X-6 · nit · The `unknown` helper in `TestValidateDepictionRegion`
**Answer:** Fixed. STEP-2 names a local `unknown` variable beside `label`.

## Round 2

The round-1 answers were checked. M-1 through M-6 hold. M-3's sweep and T-5 needed more work, recorded below.

### M-7 · blocker · `validateMarks` is a second scan for the page selector beside `citationPage`
**Answer:** Fixed. `pageSelector(doc) (selectorRaw, bool)` *(new)* is the one finder. `Validate` and `citationPage` both use it, and `validateMarks` is gone from D-3, Codebase fit, Go core and the sketch. The stale text is now covered:
- `ValidateDepictionRegion`'s "Both documents must pass Validate" is reworded (§6 Go core).
- `Validate`'s doc comment is reworded (§6 Go core).
- The map's S15-44 entry and row were reworded at planning and no longer say `validatePage` checks the pair.
- The DoD sweep is now `rg -U` over the wrapped comment text. At planning it hits exactly the lines this PR edits.

### M-8 · blocker · T-5's raw-pair property fails above `math.MaxInt32`; how the test reads the raw pair
**Answer:** Fixed. T-5 now applies the property only when `Page(doc) != PageRef{}`. It reads the raw pair in package `locator` through `decode`, `pageSelector` and `pageMark`, with no second decoder. The MaxInt32 document is a seed, and it is a T-2 row expecting `PageRef{}`.

### X-1 · blocker · T-5's second property fails above int32
**Answer:** Fixed with M-8.

### X-2 · blocker · The DoD sweep hits the plan and the map's Context
**Answer:** Fixed. The sweep excludes `S15-44-*`. The map's Context line was reworded at planning and no longer says "simply omits".

### X-3 · minor · The map's Ships sentence keeps "checked in `validatePage`"
**Answer:** Fixed. The whole Ships sentence and the map row were rewritten at planning, and STEP-4 no longer touches the map entry.

### X-4 · nit · `TestPage` rows as `PageRef` literals
Logged. STEP-2 says to move to a `want PageRef` column that keeps every row's values.
