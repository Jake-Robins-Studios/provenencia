# Ship log — S15-28 A value's records load on their own

**Plan:** [`S15-28-records-load-on-their-own.md`](S15-28-records-load-on-their-own.md) · **Branch:** `s15-28-records-load-on-their-own` · **PR:** #1016
**State:** fixing 1

## Round 0 — implement
Head `0cc025b12`. Report: version bump 0.51.0 (main was 0.50.1, plan's next-minor rule); T-3 malformed-id case via `RenderAll`; T-10 compares SELECT counts via `databasetest.CountSelects`. All in the plan's Landed note. Orchestrator gate on `0cc025b12`: PASS (all ten checks).

## Round 1 — review
Base `9550775e3`, head `0cc025b12`. Reviewers: CON, MNT, UX, SEC+PRF. (UX routed only by `macos/App/Platform/Generated/engine.pb.swift`.)

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| SEC-1 | SEC | minor | A malformed Citation id in a crafted catalog fails that sheet's read | Rejected | Only a catalog written outside the app reaches it (`observations.citation_id` is written as 16 bytes by the app); outcome is a `citations.invalid` user error, no crash or harm — working rule "crafted values: wrong text OK" (S15-05 SEC-1) |
| UX-note | UX | — | S15-29's sheet opened after its owner merged gets an empty answer (D-8); its empty state must say why | Later PR → S15-29 | written into S15-29's map scope entry |
| MNT-1 | MNT | major | `renderAll` skips any `citations.ErrInvalid` as "over budget" | Fix now → F-1 | verified: `render.go` `renderAll` branches only on `errors.Is(err, citations.ErrInvalid)`; the sentinel is also the package's general refusal (`Render`, `RenderAll`, `preview.go`); code this PR adds |
| MNT-2 | MNT | major | The four life row kinds hand-listed in `PersonDerivedRows`, `ProvenanceSheet`, `personDerivedRows`' `all` and the handler's `derivedRowKinds`; the unknown-kind rule lives in the caller | Fix now → F-2 | verified: `conclusiondetails.go` `personDerivedRows` calls `in.AddHandles(personID)` before filtering by kind; same-pass cleanup |
| MNT-3 | MNT | minor | Pair key and 16-byte skip written out in `fieldsByPair`, `FieldRecords`, `personDerivedRows` | Fix now → F-3 | verified: identical `len(...) != 16` checks; minor in a file this PR adds to |
| CON-1 | CON | minor | AC-3.6 not asserted for a life row's Evidence graphs and Sources | Fix now → F-4 | verified: the derived case in `provenance_records_test.go` passes `nil, nil` to `wantInputs` |
| CON-3 | CON | nit | `ProvenanceSheet` lists the four kinds inline | Fix now → F-2 | dup of MNT-2 |

Nits (logged): `MNT-4 · api/ffi/handlers/provenance_records_test.go:42 · researchedPerson looks up the name Property two ways` · `MNT-5 / CON-2 · core/database/citationrender/render.go:67-75,122 · RenderAll's and render's docs don't say a refused batch's inputs are still recorded` (riding with F-1, which rewrites those docs)

### Fix plan 1

**F-1 — The byte budget gets its own signal** (from MNT-1, MNT-5, CON-2)
Files: `core/database/citationrender/render.go`, `render_test.go`.
Failing test first: a `renderAll` case where `render` would refuse for a reason other than the budget must surface the error, not drop the batch. If no non-budget `ErrInvalid` path exists to drive, write the test against `render` directly: `render` over budget returns `errOverBudget` (unexported), and `Render` over budget still returns `citations.ErrInvalid` (`TestRenderLimits` stays green).
Do: add `var errOverBudget = errors.New(...)`; `render` returns it when `total > limit`; `renderAll` skips only `errors.Is(err, errOverBudget)`; `Render` maps `errOverBudget` to `citations.ErrInvalid`. Have `render` return the bytes it spent so `renderAll` does not re-add `size(r.Full)+size(r.Short)`. Reword the `RenderAll` and `render` docs: a refused batch's Evidence graphs and Sources are still recorded on `in`.
Check: `rg -n "ErrInvalid" core/database/citationrender/render.go` shows only the id/count refusals and `Render`'s mapping; scripts/check-pr.sh PASS.

**F-2 — The four life row kinds are declared once; an unknown kind reads nothing in `personDerivedRows`** (from MNT-2, CON-3)
Files: `core/database/conclusiondetails/conclusiondetails.go`, its tests; `api/ffi/handlers/conclusion_detail.go`, a handler test.
Failing test first: `personDerivedRows`/`PersonDerivedRow` with `Kind: "nonsense"` and a real Person records nothing on `in` (today it records the Person).
Do: in `personDerivedRows`, return before `in.AddHandles`/`PersonsByIDs` when no kind in `kinds` is a known kind. Declare an exported `DerivedRowKinds` slice (birth date, birth place, death date, death place) and use it in `PersonDerivedRows` and as the order for `all`. Drop the `slices.Contains` kind check in `ProvenanceSheet`, keeping `len(req.PersonID) > 0`. Add a handler test that `derivedRowKinds` has an entry for every `conclusiondetails.DerivedRowKinds` element.
Check: `rg -n "DerivedRowBirthDate" --type go core api` prints only the const declaration, `DerivedRowKinds`, the `all` table, the handler map and tests; `TestProvenanceSheet` "neither" case green; scripts/check-pr.sh PASS.

**F-3 — One pair key** (from MNT-3)
Files: `core/database/conclusiondetails/conclusiondetails.go`.
Failing test first: none needed (pure refactor; existing `TestFieldRecords`, `TestPersonDerivedRow`, `TestProvenanceSheet` cover it).
Do: add `func (p Pair) key() (string, bool)` returning false when either id is not 16 bytes; use it in `fieldsByPair`, `FieldRecords` and `personDerivedRows`' lookup.
Check: `rg -n 'string\(\w+\.(OwnerID|ID)\)\s*\+\s*string\(\w+\.PropertyID\)' core/database/conclusiondetails` prints only `key()`'s body; `rg -n "!= 16 \|\| len" core/database/conclusiondetails/conclusiondetails.go` prints only `key()`; scripts/check-pr.sh PASS.

**F-4 — A life row's sheet asserts its graphs and Sources** (from CON-1)
Files: `api/ffi/handlers/provenance_records_test.go`; `core/database/conclusiondetails/placerecords_test.go`.
Failing test first: n/a (test-only; the assertion must pass against current code — if it fails, report it as a defect).
Do: in the "a Person's birth date row" case, collect each owner's outcomes' `GraphId` and `SourceId` as the pairs case does and pass them to `wantInputs`. Assert inputs in `TestProvenanceSheet`'s life-row subtest likewise. Ride-along nit MNT-4: `researchedPerson` uses one lookup of the name Property.
Check: tests pass; scripts/check-pr.sh PASS.

## Cost
Plan: 5,702 words (check-plan-docs info line).

| Round | Agent | Model | Tokens |
| --- | --- | --- | --- |
| 0 | implementer | sonnet | 254k |
| 1 | UX | opus | 60k |
| 1 | SEC+PRF | opus | 66k |
| 1 | MNT | opus | 91k |
| 1 | CON | opus | 97k |
