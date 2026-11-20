# Review — S15-16 Citations render through their type's formats

**Verdict:** Fits with changes — Ready with changes (both rounds); every finding Fixed or Logged, nothing open
**Rounds:** 2. **Reviewers:** maintainability (Opus), executability (Sonnet)

## To user
- None.

## Writer's own calls
- The preview takes one target (one Citation, or a Source for the list form only); the map rule's "Citation ids" was edited to "one Citation" (D-9).
- A Citation's Source is its graph's Source (D-3).
- The group key is a SHA-256 of the full note's runs; a Citation with no full text gets its own `citation:<id>` key; equal text across Sources groups (D-7).
- Per-call caps of 2,000 Citations and 8 MiB rendered text, both `citations.invalid` (D-8).
- Budgets 100 ms at 300 Citations and 400 ms at 1,200; exact SELECT counts 9 and 11 (D-13). Not measured: no code yet.
- Swift copy for built-in names moves to S15-39 and S15-17 from S15-38's Out line, which named S15-16.
- The preview reply carries no inputs: no caller holds a key for it.

## Round 1

### M-1 · blocker · A second catalog resolver beside `ownerValues`
**Answer:** Fixed — D-11: `sourcemetadata.CitationValues` (rows by level, fields, built-ins) replaces `ownerValues`; `listWorkspaces` and `citationrender` both build it. Deletes, Codebase fit, Reach and T-1 updated.

### M-2 · blocker · The render reply reports no inputs
**Answer:** Fixed — D-6: `Render` takes `*graphcache.PageInputs` and records each found Citation's graph and Source; `RenderCitationsResponse.inputs` (§ FFI) through `pageInputsProto` (D-14); AC-1.1 and T-5 assert them. The preview reply gets none (Out: no caller holds a key).

### M-3 · blocker · The preview handler decides which missing options survive
**Answer:** Fixed — D-16: `sourcemetadata.AppendOptions` extracted from `annotate`; `Preview.Missing` is `[][]sourcemetadata.Alternative` (D-9), `Preview.Fields` dropped; `citationOptionProto(Alternative)` (D-14).

### M-4 · blocker · The preview has its own blank-and-parse rule beside `Formats.Parse`
**Answer:** Fixed — D-10 parses both branches through `Formats{}.With(form, text).Parse()`; `Formats.with` is exported as `With` (also answers X-3).

### M-5 · major · New by-id reads add more column lists and scans
**Answer:** Fixed — D-3: `citations.sqlColumns` and `scanRow(row, extra...)` absorbing `scanListedRow`; `sourcetypes.sqlColumns` and `scanType(row, extra...)` absorbing the five inline scans (also answers X-2).

### M-6 · minor · Same names, different concepts
**Answer:** Fixed — `RenderedCitation`, `MaxBatchBytes`.

### M-7 · minor · `listWorkspaces` reads Sources one at a time
**Answer:** Fixed — D-17, STEP-2.

### M-8 · minor · Two Swift files for one vocabulary family
**Answer:** Fixed — D-15 renames `CitationForm.swift` to `CitationFormatVocabulary.swift` and `swiftCitationForm` to `swiftCitationVocabulary`.

### M-9 · nit · `dottedListCase` rejected for the wrong reason
**Answer:** Fixed — `listCase` widens to `[a-z_.]+` (D-15), verified each row reads only `swiftEnumBody`.

### X-1 · major · A catalog-level query counter already exists
**Answer:** Fixed — D-12 uses `databasetest.CountSelects`; the new `dbsqltest` counter and the three signature widenings (old D-11) are dropped; `effects`' counter stays (Out).

### X-2 · blocker · `Cited` cannot be scanned by `scanRow` plus three
**Answer:** Fixed — D-3 gives `scanRow` extra destinations (M-5).

### X-3 · major · `Formats{<Form>: *Format}` is not Go
**Answer:** Fixed — D-10 uses `Formats{}.With(form, text)`.

### X-4 · major · T-7's over-limit case does not exceed the limit
**Answer:** Fixed — T-7 crafts both full and short formats; 60 Citations ≈ 7.5 MiB renders.

### X-5 · minor · AC-1.4's "unknown-id" contradicts the id rules
**Answer:** Fixed — AC-1.4 and AC-2.6 say a well-formed id with no row.

### X-6 · minor · Handler edges left open
**Answer:** Fixed — D-14: an unset oneof leaves `Target` empty (→ `citations.invalid`, T-11); `fieldChoicesFromProto` extracted from `UpdateCitationFormats`; missing conversion through `citationOptionProto(Alternative)`.

### X-7 · minor · Fixture details left open
**Answer:** Fixed — STEP-3 names the helpers' packages; D-13 and STEP-5 name the seeded census type and AC-1.1's values at every level; T-8 expects AC-1.1's full line for every Citation.

## Round 2

All round-1 answers were verified against the code by both reviewers, except M-1 (incomplete, M-11) and M-5 (half fixed, M-10).

### M-10 · blocker · Three citation column lists and two type lists remain, though `metadatafields.Columns(alias)` exists
**Answer:** Fixed — D-3: `citations.columns(alias)` used by `sqlGet`, `sqlListByArtifact` and `ListCitedTx`; `sourcetypes.columns(alias)` used by `sqlLookup`, `sqlGetByID`, `sqlList` and `GetManyTx`, shaped like `metadatafields.Columns`. Precedent, Codebase fit and Deletes updated. No subquery added, so D-13's counts hold.

### M-11 · blocker · `ListDraftWorkspace` and `TestAnnotate` still use `ownerValues`
**Answer:** Fixed — D-11 names `ListDraftWorkspace` (`Rows: {source: rows}`, no own entry) and the `TestAnnotate` conversion mapping; Reach gains the draft-board row; T-12 names `TestGetDraftMetadataBoard` and `TestDraftBoardScenarios`; the stop condition reads "a converted case needs a different expected output".

### Round 2 · major · `FieldsByIDTx` exported from the wrong package
**Answer:** Fixed — D-11: `metadatafields.MapByIDsTx` beside `ListByIDsTx`; `sourcemetadata.fieldsByID` deleted. The three maps in `sourcetypes/formats.go` key by `uuid.UUID` or another value, so they stay (Out, logged).

### Round 2 · minor · D-4 reads `source_types` twice
**Answer:** Logged — one extra SELECT per call; Out row.

### E-1 · blocker · `TestAnnotate` cannot pass unchanged
**Answer:** Fixed — same as M-11.

### E-2 · major · The preview cannot use D-4 as written
**Answer:** Fixed — D-4 splits into `loadCitations`, `loadSource` and `fillValues(tx, subjects, templates)`; the batch and the preview each name their sequence; the field read takes the given templates' fields.

### E-3 · major · AC-2.4 leaves a second missing entry (the undated Source's date)
**Answer:** Fixed — AC-2.4 and T-9: the Source is dated 1880.

### E-4 · minor · nil `*PageInputs`
**Answer:** Fixed — D-6: `in` must not be nil; `NoPageInputs()` for callers that record nothing; STEP-3 tests use `c.Graph().PageInputs()`.

### E-5 · minor · `scanListedRow` into `scanRow`
**Answer:** Fixed — D-3 names the local `n int32` and the `ListedCitation` build.

### E-6 · minor · How to turn foreign keys off
**Answer:** Fixed — STEP-3: `PRAGMA foreign_keys=OFF` on the catalog's `*sql.DB` outside a transaction, then back on.

### E-7 · minor · Scale fixture choices
**Answer:** Fixed — STEP-5 names the `BenchID` kinds, ref patterns, the type and field lookups, the links and the Citation spread.

### E-8 · nit · A Citation target with form `list`
**Answer:** Fixed — D-9: allowed; renders its Source's list entry; T-9 row.
