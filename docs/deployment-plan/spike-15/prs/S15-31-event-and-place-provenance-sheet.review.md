# Review — S15-31 Event and Place rows open the provenance sheet

**Verdict:** Fits with changes — Ready with changes (round 1). Round 2: see below.
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet). Both read the plan and the briefs S15-D11 and S15-D12.

## To user
- How do the agreed boards reach the implementer? Recommendation: the Board line of each brief and of the plan names the turn and frames on the Event Detail and Places Detail boards. The implementer cannot open them, so the plan keeps § 6 "Frames in words" and the Stop condition.

## Writer's own calls
- D-1: one row mode. `ReconciledValueRow.Provenance` goes, and `openProvenance` loses its no-op default.
- D-5: `ReconciledValueRowModel.hasRecords` is the one test of "this row offers the sheet".
- D-7: no new test. The Why-title assertions are deleted and the existing tests carry the ACs, plus one expectation for the empty Period.
- D-10: the control shows on a row whose value is empty but which holds records.
- D-11: the control stays vertically centered on a tall row, as the code does today. The briefs ask the boards to draw it there.
- Version: minor.
- The Go comments that name the Why are reworded here. The proto comment goes to S15-28, and STEP-6 records that in S15-28's scope entry.

## Round 1

### M-1 · major · T-4 copies private fixtures to re-test what existing tests already cover
**Answer:** Fixed. T-4 and its step are gone. § 8 T-1 adds the empty Period's `recordCount == 0`, and § 8 maps each AC to the existing test. D-7 is rewritten.

### M-2 · major · `openProvenance` keeps a no-op default once the control is always drawn
**Answer:** Fixed. D-1 makes it `let openProvenance: () -> Void`. It is listed in Deletes and in a Risk row.

### M-3 · major · Out line sends the Go and proto comments to S15-28, whose scope does not include them
**Answer:** Fixed. STEP-5 rewords the two Go comments (comments only). Only the `engine.proto` comment stays Out, and STEP-6 adds it to S15-28's scope entry, replacing its misquoted phrase.

### M-4 · major · The sweep misses `docs/conclusion-reconciliation.md:175`
**Answer:** Fixed. § 4 Docs and STEP-6 reword it, and STEP-6's check runs `rg -n "\bWhy\b" docs/*.md`.

### M-5 · minor · T-1 – T-3 copy the title-equals-label test
**Answer:** Fixed. The `whyTitle` assertions are deleted and the records halves kept. The rule stays with `aRowBuildsItsContentOnCall` (D-7).

### M-6 · minor · Three spellings of "this row offers provenance"
**Answer:** Fixed. D-5 adds `hasRecords`, read by `provenanceSlot`, `firstStop` and `ProvenanceSheetItem.row(in:)` (Codebase fit).

### M-7 · minor · Facts written several times
**Answer:** Fixed in part. D-1 – D-4 now point at Deletes and Strings. § 4 keeps its rows, because it is the implementer's map of the current code.

### M-8 · nit · Brief inventory wording
**Answer:** Fixed. In both briefs the Details row is Ship, and the presenter is `ConclusionDetailRowsSection`, with `ProvenanceSheetHost` as its content.

### X-1 · blocker · Boards not drawn; plan not Planned
**Answer:** Declined as a plan defect. The status is already `Blocked — on boards S15-D11 and S15-D12`, by design (plan-pr step 3). The plan moves to Planned when both boards are agreed. The board hand-off is To user.

### X-2 · blocker · AC-4.1's `rg` uses `\|`, so it can never fail
**Answer:** Fixed. The sweep is a fenced `bash` block in § 9 with plain `|`, and AC-4.1 and § 10 step 8 point at it. It covers `.xcstrings` (no glob excludes it).

### X-3 · major · Empty value with records vs AC-1.4 and EP-2
**Answer:** Fixed. D-10 is new. AC-1.4 is reworded. S15-D11 adds EP-2a and frame 3b, and S15-D12's PP-2 covers the case.

### X-4 · major · Where the control sits on a tall row
**Answer:** Fixed. D-11 keeps it centered, as the code does. EP-1 and PP-1 say so. The Stop condition now reads "the row's end centered on the row".

### X-5 · minor · `conclusion-reconciliation.md:175`
**Answer:** Fixed with M-4.

### X-6 · minor · L10n type comments name the Why table
**Answer:** Fixed. D-4 gives both new comment texts, § 4 lists them, and STEP-4's check greps "Why table" and "Why's table".

### X-7 · major · T-4 fixtures undecided
**Answer:** Fixed by M-1: there is no T-4.

### X-8 · minor · T-1 and T-3 name no test functions
**Answer:** Fixed. § 4 Tests names each function and line.

### X-9 · minor · STEP-1 and STEP-5 wording left open
**Answer:** Fixed. STEP-1 gives the three comment texts. STEP-5 gives the replacements and an exact check, and names `PersonRecordLinksContent.swift:10` as an expected ordinary-word hit.

### X-10 · minor · Brief inventory names the wrong presenter
**Answer:** Fixed with M-8.

### X-11 · minor · design/README and map edits unspecified
**Answer:** Fixed. STEP-6 points at the S15-27 and S15-D17 precedent rows.

### X-12 · nit · PP-3 omits other values
**Answer:** Fixed. PP-3 now names a field's other values.

## Cost
Plan: 4,326 words at round 1, about 4,780 after the fixes (check-plan-docs info line).

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| 1 | maintainability | opus | 169k |
| 1 | executability | sonnet | 158k |

## Round 2

Executability (sonnet) checked every round-1 answer against the code at `main` @ `c321075`. Every Fixed answer held except the two checks below. Verdict: Ready with changes. Maintainability was not re-run: round 1 raised no maintainability blocker.

### X2-1 · blocker · The sweep and STEP-1's check hit `SourceMoveModel.showsWhy`
**Answer:** Fixed. `showsWhy` is out of the sweep. STEP-1 checks `provenance: \.sheet|Provenance\.why|enum Provenance|case why` in `Features/Conclusions` and notes that `SourceMoveModel.showsWhy` stays. The Stop condition now points at § 9's sweep.

### X2-2 · major · STEP-5's check cannot fail, and two replacements were undecided
**Answer:** Fixed. STEP-5 is now a table with each comment and its new text: `PVProvenanceFace`, `conclusiondetails.go:5` and the model's comments are in it. The check is `rg -nw "Why"` over the listed files, and the two ordinary-word lines are named.

### X2-3 · minor · STEP-2 "keeping the rest of its line"
**Answer:** Fixed. STEP-2 names each line: what 386, 688 and 690 keep, and which lines are deleted whole.

### X2-4 · minor · STEP-6 drops a phrase not in the code
**Answer:** Fixed. STEP-6 drops the phrase from S15-28's Context only and says no comment holds it.

**Final verdict:** Fits with changes — Ready with changes, every finding Fixed or answered. The plan stays `Blocked — on boards S15-D11 and S15-D12` until both boards are agreed, then moves to Planned.

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| 2 | executability | sonnet | — |
