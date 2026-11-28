# Ship log — S15-29 The provenance sheet loads its records when it opens

**Plan:** [`S15-29-records-load-when-the-sheet-opens.md`](S15-29-records-load-when-the-sheet-opens.md) · **Branch:** `s15-29-records-load-when-the-sheet-opens` · **PR:** #1024
**State:** ready

## Round 0 — implement
Head `49606eb3d`. Gate PASS (orchestrator run against `07278873f`). Report deviations: version 0.53.0 (main was 0.52.1); STEP-3–6 in one commit (only build together); T-15's sheet-read case runs in `core/database/conclusiondetails` (no Place life-row handler fixture), `pooled_support` wire mapping asserted in `TestReconcilerOutcomeProtoCarriesVoteAndArtifact`; Event/Place fixtures take counts from new helper `ReconciledValueDisplayTests.counted`; `FakeStore` detail sets `recordCounts`; manual check §10 not run.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. (route-reviewers ran all four.)

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1, CON-4 | MNT, CON | minor | FakeStore's detail still sends outcomes; count rule copied in FakeStore and test `counted`; fake sheet read answers empty | Fix now → F-1 | verified: `FakeStore.swift:2323` and `ReconciledValueDisplayTests.swift:74` each hand-roll `records/sources`; same-pass cleanup (both touched here) |
| CON-1 | CON | minor | T-15's catalog case never pools two links | Fix now → F-2 | verified: `placerecords_test.go:279-281` reuse `birth` and `swift` handles, so one owner; assertion guarded by `v.Displayed()` only |
| CON-2 | CON | minor | Relabelled-sheet title check dropped | Fix now → F-3 | verified: no `Born` left in `macos/ProvenenciaTests`; doc comment on `provenanceContent(records:)` still claims it |
| MNT-2 | MNT | minor | Pooled heading's runs (Swift, by text) and its count (Go, by Place+scalar) use two pool keys | Follow-up | plan Edges "Pool keys" accepts it; no fixture reaches the split; home to user |
| UX-1 | UX | minor | §10 manual check not run | Rejected (as code finding) | no code change; the manual check is the user's step before merge (ship-pr step 8), carried in the report |
| SEC+PRF | — | — | Clean | — | — |

Nits (logged): `MNT-3 · GenealogyStore.swift CatalogProvenanceSheetRead.init · delete hand-written memberwise init` · `MNT-4 · CatalogQueryKey.swift · "fields"/"life" tags as one constant pair` · `MNT-5 · ReconciledValueDisplayTests.swift:74 · rename counted(_ field:)` (subsumed by F-1) · `UX-2 · EventDetailContent.swift:61-80 · Date sheet reloads visibly when a second dating Property gains records; not a regression` · `CON-3 · docs/macos-client-patterns.md:104 · record_counts belongs to the field, not each value`

### Fix plan 1

**F-1 — FakeStore's detail has the wire shape and one count helper** (from MNT-1, CON-4, MNT-5)
Files: `macos/App/Platform/FakeStore.swift`, `macos/ProvenenciaTests/ReconciledValueDisplayTests.swift` (and any test using its `counted(_ field:)`).
Failing test first: none required (fake-shape refactor); existing Swift suite must stay green.
Do: Add one `static` helper beside FakeStore's `nameField` that computes `CatalogFieldRecordCounts` from a field's outcomes and displayed values the way Go's `recordCounts` does (`core/database/conclusiondetails/conclusiondetails.go:345-370`: one displayed value → its Support; several → distinct Sources of outcomes with group rank above 0, else summed Support). FakeStore's `getConclusionDetail` sets `recordCounts` from it and then clears the field's `outcomes`, matching the Go detail read. FakeStore's `getProvenanceRecords` answers a `.fields` request on its name field's (owner, Property) with that field and its outcomes, instead of an empty read. Replace the test helper `counted(_ field:)` with a call to the FakeStore helper, renamed so it does not collide with `ReconciledValueDisplay.counted(_ outcome:)` (e.g. `withEngineCounts`).
Check: `grep -rn "CatalogFieldRecordCounts(records: .*outcomes.count" macos` prints only the new helper; scripts/check-pr.sh PASS.

**F-2 — T-15's catalog case pools across two links** (from CON-1)
Files: `core/database/conclusiondetails/placerecords_test.go`.
Failing test first: in the "the sheet's life row carries it, the detail read's does not" subtest, assert `len(sheet.Owners) >= 2` and count the displayed values checked (`> 0`); run it red against the current fixture.
Do: File the second (and third) Register's birth onto a separate birth Event linked to the same Place (the `swift` handle), so the sheet read has at least two owners pooling one York-like Place; expected `PooledSupport` is the distinct Source count across the links. Keep the detail-read half.
Check: the subtest passes; scripts/check-pr.sh PASS.

**F-3 — A relabelled row's sheet carries its new title** (from CON-2)
Files: `macos/ProvenenciaTests/ProvenanceSheetTests.swift`.
Failing test first: not applicable (restores a dropped assertion on behavior that exists).
Do: In `contentTakesRecordsFromTheRead`, add `var renamed = row; renamed.label = "Born"; #expect(renamed.provenanceContent(records: []).title == "Born")`.
Check: test passes; scripts/check-pr.sh PASS.

## Round 1 — fix
Head `9735e26c3`. Gate PASS. F-1 done (`FakeStore.recordCounts(of:)` is the one count rule; fake detail clears outcomes; fake sheet read answers `.fields` on the name field; test helper renamed `withEngineCounts`; deviation: `CatalogQueryRegistryTests.conclusionDetailLoadsAPersonsNameValuesAndOutcomes` now reads outcomes through `getProvenanceRecords`). F-2 done (red with 1 owner, green with 3). F-3 done.
Orchestrator read the fix commits: MNT-1/CON-4 **Resolved**, CON-1 **Resolved**, CON-2 **Resolved**. No round 2: round 1 had no blocker or major.
Merged `origin/main` @ `a39185aab` (docs only); gate PASS at `5f92f8345`.

## Result
Gate PASS · CI pending · open: none · follow-ups: MNT-2 · to user: — (manual check §10 is the user's)

## Cost
Plan: 7,640 words (check-plan-docs info line).

| Round | Agent | Model | Tokens |
| --- | --- | --- | --- |
| 0 | implementer | sonnet | 368k |
| 1 | CON | opus | 156k |
| 1 | MNT | opus | 114k |
| 1 | UX | opus | 106k |
| 1 | SEC+PRF | opus | 69k |
| 1 | implementer (fix) | sonnet | 103k |
| | **Total** | | **916k** |
