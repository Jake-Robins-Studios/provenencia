# Review — S15-43 The Source date can be marked unknown or supplied

**Verdict:** Fits with changes — Ready with changes
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet)

## To user

- None.

## Writer's own calls

- D-6: no mark on the wire means no mark (a date write without a mark clears it), as S15-37 D-7 did for metadata values.
- D-5 / D-7: the mark's audit keys are Go `bool` (S15-37's shape for the pair), not `boolInt` like `is_public` on the same entity.
- D-3: a supplied Source whose date row is gone reads undated with no mark; the audit still diffs the stored column (D-5).
- D-9: the phrase cap is 4096 bytes, in `datevalue.Validate`, so it also bounds Observation dates.
- An unknown Source sorts with the undated Sources (last); no separate place in the Sources list sort.

## Round 1

### M-1 · major · This PR adds two columns to five hand-kept copies of the `sources` column list
**Plan:** D-2 adds the columns to `sqlGet`, `sqlGetByRef`, `sqlList`, `scanSource`, `scanSourceList`.
**Codebase:** `core/database/sources/sources.go`; precedents `observationrow.Columns`/`Scan`, `identityclaims.sqlColumns`.
**Better shape:** one `sqlColumns`, one `scanSource(row, extra ...any)`; delete `scanSourceList`.
**Answer:** Fixed — D-2, Codebase fit, Deletes.

### M-2 · major · The date fill and its settle rule are two copies, and S15-16 will need a third
**Plan:** D-3's `settleDateMark` called from `getOne` and `List`, each with its own date fill.
**Better shape:** one `fillDates(q, out []Source)` over `datevalues.LookupManyTx` that sets `Date` and the settled mark.
**Answer:** Fixed — D-3, Codebase fit, Deletes, Next adds.

### M-3 · minor · D-3's settled read becomes `SetDate`'s diff base, so the table and the audit can disagree
**Answer:** Fixed — D-2 adds the unexported `storedDateMark`; D-4 step 4 and D-5 diff against it; T-8 asserts the `date_supplied` {true → false} change; Edges "Removed inputs".

### M-4 · minor · The audit diff for a mark is spelled out a third time
**Better shape:** a `rowchange` helper shared with `sourcemetadata.updateValueTx`, or say why two copies.
**Answer:** Declined — two holders with different column names; S15-44 keeps its pair in locator JSON, so no third column copy is named in the map, and the helper would reach into `sourcemetadata`, outside this PR. D-5's Rejected column says so.

### M-5 · minor · `CreateFromDraft`'s guard repeats `SetDate`'s no-change rule
**Answer:** Fixed — D-8 calls `SetDate` with no guard; Deletes names the guard.

### M-6 · nit · The Codebase fit row cites the wrong precedent for the phrase cap
**Answer:** Fixed — Codebase fit and D-9 cite `locator.MaxDocumentBytes`.

### X-1 · blocker · STEP-5, the Xcode check and check-pr cannot run in this environment
**Answer:** Fixed — the stop condition now says: stop after STEP-4, push the branch, report; no PR, no STEP-6, nothing Landed; STEP-5 and STEP-6 run on a Mac.

### X-2 · major · T-8 fixture: how to make the supplied-but-dangling row is not stated
**Answer:** Fixed — T-8 names the fixture (`runSetDate` with `Mark{Supplied}`, then `DELETE FROM date_values` with foreign keys off) and `YMD(1900, 0, 0)`.

### X-3 · major · Audit shape when the stored mark was settled away (D-3 with D-5)
**Answer:** Fixed — same fix as M-3.

### X-4 · minor · STEP-2 does not name every `SetDate` call site that needs the new argument
**Answer:** Fixed — STEP-2 names the `set` closure in `TestSourceDate` and `audit/scopes_test.go`.

### X-5 · minor · Rewrite of `SetDate`'s control flow is under-specified
**Answer:** Fixed — D-4 gives the six-step flow, including the mark-only cases.

### X-6 · minor · The `datevalue.Validate` cap changes Observation dates too
**Answer:** Fixed — §8 "Most likely to break" names the `datevalue`, `datevalues` and Observation date tests.

Other: the `add-date-value` line STEP-6 edits is named by its opening words.

## Round 2

Maintainability: round-1 answers hold (M-4's decline checked). Executability: Current state still true at `d3abece`; every transition of D-4 walked.

### M-7 · blocker · D-7 audits a Source delete from the settled mark, against the rule D-5 now sets
**Answer:** Fixed — D-7 reads `storedDateMark`; D-2 adds the `Source` doc comment line (readers `DateMark`, writes and audits `storedDateMark`); T-3 gains the dangling supplied delete case.

### M-8 · blocker · `fillDates` is typed to `[]Source`, so the named S15-05 add on the Source record must copy the date rules
**Answer:** Fixed — D-3 puts both rules in `settleDate(dates, id, stored)`; `fillDates` loops over it; Codebase fit and Next adds name S15-05's `loadRecords`.

### M-1 note · `sqlGet` and friends can stay `const`
**Answer:** Fixed — D-2 says they stay `const`s built by concatenation, as `identityclaims.sqlGet`.

### X-7 · major · STEP-3 and T-4 give no way to set an unknown or supplied original
**Answer:** Fixed — STEP-2 gives `sourcecopy_test.go`'s `setDate` a `mark` parameter.

### X-8 · minor · `getOne`'s query parameter must be widened
**Answer:** Fixed — D-3 says `getOne`'s `q` gains `Query`.

### X-9 · minor · D-4 steps 5 and 6 lean on unstated definitions
**Answer:** Fixed — step 3 defines `held`; step 6 counts the `PutTx` change.

### X-10 · minor · T-5 and T-8 do not name their source fixture or DB handle
**Answer:** Fixed — T-5 names `dbtest.MustDB(t, c)`; T-8 makes its own Source with `runCreate`.

The loop stops here (two rounds). The round-2 fixes are small and local; no blocker is open.
