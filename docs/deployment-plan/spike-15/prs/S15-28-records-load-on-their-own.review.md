# Review — S15-28 A value's records load on their own

**Verdict:** round 1: Fits with changes — Not ready; every finding Fixed. Round 2: see below.
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet)

## To user
- The detail read was mapped to drop each value's records here, but `scripts/check-pr.sh` builds the app, which reads them. Answered (user, 2026-11-27): the drop moves to S15-29; the map's rows, scope entries and rule say so.
- One sheet read (records and their rendered citations) or two RPCs joined in Swift. Answered (user, 2026-11-27): one read, `GetProvenanceRecords`; `RenderCitations` goes in S15-29.

## Writer's own calls
- D-5: `Sources` reproduces Swift's `sourceCount` for every state, its summed-Support fallback included.
- D-8: a gone owner, a pair with no field, an unspecified kind or an empty request answers no owners, not an error.
- D-9: a render batch refused for size is left out, so those records show today's line instead of failing the sheet.
- D-10: the life row read records the Person's handle.
- T-8's 600 ms warm budget at 1,200 records.
- Version: minor (a new RPC).

## Round 1

### M-1 · blocker · The sheet read's groups drop the owner's Place and Event, which S15-29's derived sheet needs
**Answer:** Fixed. D-3 and FFI: the response answers `repeated ConclusionOwnerField owners`, built by `ownerFieldProto` (pulled out of `derivedRowsProto`); Go returns `[]OwnerField` for both cases. `ProvenanceRecordGroup` and `OwnerRecords` are gone. AC-3.3 and T-9 assert `event` and `place`.

### M-2 · blocker · Sheet-read policy sits in the handler: chunking, the oversize fallback, citation-id selection and the Person input
**Answer:** Fixed. `citationrender.RenderAll` batches in one transaction and leaves out a batch refused for size (D-9). `conclusiondetails.ProvenanceSheet` picks the case and the Citation ids. `personDerivedRows` records the Person (D-10). The handler only parses and maps. T-3 and T-13 are core tests.

### M-3 · blocker · `FieldRecords` would be a second "(owner, Property) pairs → fields" mechanism beside `PersonDerivedRows`
**Answer:** Fixed. D-7 and Go core: `fieldsByPair` is the one step (batched `g.Nodes`, `in.Node`, `only`, `fieldsOf`), keyed by pair; `FieldRecords` collapses repeats, and `personDerivedRows` maps each owner by its pair. A Stop condition covers two life-row owners sharing a pair.

### M-4 · minor · One concept, two names
**Answer:** Fixed. Go `FieldRecordCounts`, `Field.RecordCounts`, `Outcome.DeniedBySourceTitle`.

### M-5 · minor · D-11 is stated three times
**Answer:** Fixed. D-11 is gone; Codebase fit and Deletes keep it.

### X-1 · blocker · AC-3.8 / T-11 cannot pass: the sheet read always reads record tables
**Answer:** Fixed. AC-3.8 and T-11: the same bytes, no graph query, and the warm read prepares the SELECTs a warm `citationrender.Render` of the same Citations prepares.

### X-2 · blocker · The `namedPerson` fixture gives 1 Citation, not 2
**Answer:** Fixed. AC-3.1 and T-9 use `namedPersonID` and expect one Citation.

### X-3 · blocker · `researchedPerson` leaves the seeding shape undecided
**Answer:** Fixed. STEP-6 gives the helper's signature and every call: `subjectFixture`, `namedPersonOnNewSource`, one Artifact per Subject, `perSource - 1` one-name `observationstest.Cite` calls (each its own Citation), the same name value, `promoteInDir`, `propertyIDByKey`. The 2,001-Citation case moved to T-3, a core test through `renderAll` with a small batch.

### X-4 · major · The `rg "as the Why shows it"` sweep can never pass, and the STEP-6 check is vacuous
**Answer:** Fixed. STEP-4 owns the `PictureDetail` comment and checks `rg -n -U "Why\n// shows"` over `api` and the generated Swift; STEP-7 checks the package comment. The DoD sweep has no `docs/` search.

### X-5 · major · `PersonDerivedRow` / `personDerivedRows` leaves the "only the named kinds" split unspecified
**Answer:** Fixed. Go core: `lists` is filtered to `kinds` before anything is read or recorded; `PersonDerivedRows` passes the four; an unspecified kind answers no owners (D-8). Citations are distinct, in owner then outcome order (`ProvenanceSheet`).

### X-6 · major · `FieldRecords` edge behaviours left to the implementer
**Answer:** Fixed. Go core: the batched prefetch, `fieldsOf`'s arguments, "no composed field" as the left-out test, two pairs on one owner as two owners. AC-3.2 and T-4 use `fixture.asOfIn` and the `date` Property, which the fixture already has.

### X-7 · major · D-9's chunk-refused fallback has no test and no matching rule
**Answer:** Fixed. `render` takes its byte cap as a parameter, and T-3 drives `renderAll` with a small batch and a small cap: the refused batch is left out, the rest rendered; a bad id is still `citations.ErrInvalid`. A refused batch is dropped whole, not split again.

### X-8 · minor · Smaller choices
**Answer:** Fixed. D-5 defines `Records`. Edges states that `ownerVerdict` rewrites only `kept` and `folded`, with a Stop condition. T-6 asserts the counts' values. §8 names `exact: true` cases. Pictures' zero denial facts are in Edges. `derivedRowKinds` is one map with a loop for the reverse. STEP-4 says where the generator runs.

## Cost
Plan: 4,879 words at round 1, 5,509 after the fixes (check-plan-docs info line).

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| 1 | maintainability | opus | 171k |
| 1 | executability | sonnet | 154k |
