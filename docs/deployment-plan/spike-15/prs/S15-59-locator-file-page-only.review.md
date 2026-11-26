# Review — S15-59 The locator only finds things in its Artifact

**Verdict:** Fits — Ready with changes (round 2; every finding answered)
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet)

## To user
- Answered (2026-11-26): a metadata-only save keeps the stored retired keys; the composer's next save of the locator writes them out (D-4). The map rule was updated to say so.
- Answered (2026-11-26): every Go test copy of the page-1 locator literal moves to `depictionvaluetest.Locator` (D-8), not only the copies this PR must edit.

## Writer's own calls
- D-2: refuse the retired keys on write (presence, any value) rather than strip them.
- D-3: `PageRef` and `Page` go for `ArtifactPage(locatorJSON) int`.
- D-4: `citations.Update` checks the locator only when it changes (found in planning: `CitationMetadataSheetModel.save` sends the stored text back).
- D-5: depiction region documents are not checked for the retired keys.
- Version: minor, 0.46.0.

## Round 1

### X-1 · blocker · STEP-3 points two tests at a variable they cannot see
`validLocator` is local to `TestCitations`; lines 874 and 976 are in `TestListCitedTx` and `TestFirstOfSource`.
**Answer:** Fixed — STEP-3: both use `depictionvaluetest.Locator` (D-8).

### X-2 · major · `citationPage`'s bool is undefined
**Answer:** Fixed — D-3: `citationPage` returns `int`, 0 for none; `selectorRaw.filePage()` holds the rule.

### X-3 · major · `TestRenderScale` and `seed-citations.txt` do not exist
**Answer:** Declined — `core/database/citationrender/scale_test.go` `TestRenderScale` (line 139) and `core/database/sourcevocab/testdata/seed-citations.txt` exist at the planning base.

### X-4 · major · D-7 and STEP-6 repeat map edits already made; the scope entry's Ships line still contradicts D-4
**Answer:** Fixed — the Ships line was edited in planning; STEP-7 (docs) no longer touches the map; D-7 says the map is already edited.

### X-5 · major · `holdsRetiredPageKey` leaves choices open
**Answer:** Fixed by M-2 — the helper is gone; the retired fields fill in the one `decode`, and T-1 has the padded-type, null and other-case rows.

### X-6 · major · T-5 cannot be written from its row alone
**Answer:** Fixed — T-5 names the seed, `obs`, the `writes.Call` shape, `dbtest.MustDB`, the update's starting locator and the empty-changes assertion.

### X-7 · minor · `Update`'s error order changes
**Answer:** Fixed — D-4 states the order and the new error for an unknown id with a bad locator.

### X-8 · minor · Smaller gaps
**Answer:** Fixed — STEP-2's comments are given verbatim. STEP-1's check says which packages stay red until STEP-3 and STEP-4.

### M-1 · blocker · D-4/D-7 narrow a user rule without the user
**Answer:** To user → answered (2026-11-26): keep the keys on a metadata-only save. §5 **Rules this plan bends** records it; the map rule stands as edited.

### M-2 · blocker · `holdsRetiredPageKey` is a second decoder beside `decode`
**Answer:** Fixed — D-2: `PageLabel`, `PageUnknown`, `PageSupplied` stay on `selectorRaw` as presence-only `json.RawMessage` (checked: a `null` value and `"Page_Label"` both fill the field). Codebase fit, Edges and T-1 follow.

### M-3 · major · `core/valuemark`'s package comment becomes false
**Answer:** Fixed — §6 Go core `core/valuemark` row, STEP-1 Files, Deletes, and the DoD sweep.

### M-4 · major · Four copies of the page locator fixture when a shared one exists
**Answer:** To user → answered: all copies (D-8, STEP-5).

### M-5 · minor · The file-page rule read by hand in three places
**Answer:** Fixed — `selectorRaw.filePage()` (D-3, Codebase fit).

### M-6 · minor · Written once
**Answer:** Fixed — STEP-7 drops the map edits; D-6 keeps the rule and leaves the sites to §4 and STEP-4.

## Round 2

### X-9 · blocker · D-3 and T-3 disagree on whether `Validate` accepts a file page above `math.MaxInt32`
**Answer:** Fixed — D-3: `filePage` returns the raw page; `Validate` and `regionDocPages` accept a page above `MaxInt32` as today, and `citationPage` keeps the cap. T-3 stands.

### X-10 · nit · STEP-5's list misses `graphcachetest.go`'s SQL-string copy
**Answer:** Fixed — STEP-5 excludes it by name; its copy sits inside a SQL literal. The round-2 maintainability reviewer raised the same note and no blocker (verdict Fits).

## Cost
Plan: 4,680 words at round 1, about 5,100 after the answers (check-plan-docs info line).

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| 1 | maintainability | opus | — |
| 1 | executability | sonnet | 131k |
| 2 | maintainability | opus | — |
| 2 | executability | sonnet | 97k |
