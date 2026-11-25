# Ship log — S16-68 The query-cache types have files of their own

**Plan:** [`S16-68-query-cache-type-files.md`](S16-68-query-cache-type-files.md) · **Branch:** `s16-68-query-cache-type-files` · **PR:** #976
**State:** ready

## Round 0 — implement
Head `1fd6f0f09`. Implementer's gate PASS (twice). Report: no deviations; `main` moved `6e18533` → `620ddaa52`, `CatalogLastUpdated.swift` unchanged.
Orchestrator gate **FAIL** on `xcode-test`: `PVScrollMemoryHostedTests.selectingARowThatIsAPlaceKeepsTheTablesY()` (lines 375, 380, `y(table) == 1000` after two Backs). File not in the diff; the move changes no compiled behaviour (AC-1.3 verified by the orchestrator: only imports and D-2 lines). Same suite had a flaky hosted test removed in `444c2a62f` on `main`. Taken to the user; not sent to the implementer (outside the plan's scope). User (2026-11-25): remove the test, it is flaky and will change anyway. Orchestrator removed it and its `PlaceTableFixture` in `f9479944e`; gate PASS.

## Round 1 — review
Reviewers: CON, MNT, UX. Skipped: SEC+PRF (no security or performance path, no added SQL or URL code).

No findings from any lens (CON, MNT, UX all Clean). No fix round; no round 2.

Nits (logged): `MNT-1 · docs/deployment-plan/spike-16/deployment-plan.md:283 · the rule's "except that …" clause splits "with no edit to their code" from "and land before …"; give the exception its own sentence` · `CON-1 · same line · same point (dup of MNT-1)`

## Result
Gate PASS · CI pending · open: none · follow-ups: none · to user: the gate failure, answered (test removed)

## Cost
Plan: 2,984 words (check-plan-docs info line).

| Round | Agent | Model | Tokens |
| --- | --- | --- | --- |
| 0 | implementer | sonnet | 91k |
| 1 | CON | opus | 42k |
| 1 | MNT | opus | 44k |
| 1 | UX | opus | 25k |
| | **Total** | | **202k** |
