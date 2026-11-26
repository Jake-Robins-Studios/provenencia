# Ship log — S15-59 The locator only finds things in its Artifact

**Plan:** [`S15-59-locator-file-page-only.md`](S15-59-locator-file-page-only.md) · **Branch:** `s15-59-locator-file-page-only` · **PR:** #991
**State:** ready

## Round 0 — implement
Base `main` @ `5b2606d`. Head `d84fc943c`. Gate PASS (orchestrator run). Report deviations: plan Status line written `Landed in [#991](…) (2026-11-26)` because check-plan-docs rejects `Landed #991` in the header; STEP-5 also replaced deleted package-level locator constants in sibling test files the compiler required; `validLocator`/`validLocatorJSON` kept as aliases of `depictionvaluetest.Locator`; §10 manual check not run (needs the app).

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF (route-reviewers.py; UX on `CitationLocatorDraft.swift`, SEC+PRF on `core/locator` and `core/database/**`).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | major | Plan has no Landed note though round 0 deviated | Fix now → F-2 | verified: plan diff is the Status hunk only; §9 DoD asks for a Landed note; S15-58 precedent at `S15-58-page-builtin-goes.md:293` |
| MNT-1 | MNT | minor | Five aliases still name the shared page-1 locator in Go tests | Fix now → F-1 | verified: `git grep -nE '(:=\|=) *depictionvaluetest\.Locator$'` lists `handlers/citations_test.go:35`, `citations_test.go:40,906,1008`, `evidencegraphs/progress_test.go:36`; STEP-5/D-8 say delete such names. Same-pass cleanup; also shrinks CON-1's deviation list |
| — | SEC+PRF | — | No findings | — | — |
| — | UX | — | No findings | — | — |

Nits (logged): `MNT-2 · core/locator/validate_test.go:79,83 · two rows named "page only"` · `CON-2 · same as MNT-2 (deduped)` · `MNT-3 · core/valuemark/valuemark.go:5-6 · re-wrap package comment`. Both ride along in F-3 since the files are already in the PR.

### Fix plan 1
**F-1 — Delete the page-1 locator aliases** (from MNT-1)
Files: `api/ffi/handlers/*_test.go` (14 files use `validLocatorJSON`), `core/database/citations/citations_test.go`, `core/database/evidencegraphs/progress_test.go`.
Failing test first: none (test-only rename).
Do: replace every use of `validLocatorJSON` (handlers), `validLocator` (citations_test.go local and progress_test.go const) and the two local `locatorJSON := depictionvaluetest.Locator` in `citations_test.go` with `depictionvaluetest.Locator`; delete the declarations. Keep `citationstest.PageLocator`, `evidencelayertest.Locator`, `observationstest.LikenessLocator` and `depictionvalues_test.go:72` (kept by the plan or predate this PR).
Check: `git grep -nE '(:=|=) *depictionvaluetest\.Locator$' -- '*.go'` prints only `citationstest.go:15`, `depictionvalues_test.go:72`, `evidencelayertest.go:43`, `observationstest.go:29`; `git grep -nw -e validLocatorJSON -e validLocator` prints nothing; scripts/check-pr.sh PASS.

**F-2 — Add the plan's Landed note** (from CON-1)
Files: `docs/deployment-plan/spike-15/prs/S15-59-locator-file-page-only.md`.
Do: add `## Landed` after §13 (shape of `S15-58-page-builtin-goes.md` § Landed) listing: the Status line form `Landed in [#991](…)` because check-plan-docs rejects `Landed #991`; STEP-5 also rewrote deleted package-level constants at their uses in sibling test files no Step names (list them); STEP-3/4's aliases were deleted per STEP-5 in the fix round (F-1); the §10 manual check was not run by the implementer.
Check: `python3 scripts/check-plan-docs.py <plan>` 0 errors; scripts/check-pr.sh PASS.

**F-3 — Nits** (MNT-2/CON-2, MNT-3)
Files: `core/locator/validate_test.go`, `core/valuemark/valuemark.go`.
Do: rename the refused row at line 83 to "file page with a printed page"; re-wrap the `valuemark` package comment lines 5–6.
Check: scripts/check-pr.sh PASS.

## Round 1 — fix
Head `c3b5d589f`. Gate PASS (orchestrator run). F-1, F-2, F-3 done. Implementer note: `observations_test.go` keeps a local `validLocator` holding a page-3 literal (not an alias of the shared locator; out of F-1).
MNT-1: **Resolved** (orchestrator read `e6b65353f`; the grep prints only the kept shared constants plus one assignment use at `citations_test.go:607`). Nits: done in `c3b5d589f`.

## Round 2 — review
Reviewers: CON (had the round-1 major). Scope `d84fc943c...c3b5d589f`.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | major | (round 1) Plan has no Landed note | Resolved | `36d74a369` adds `## Landed` with all four items; check-plan-docs 0 errors |

Nits (logged): `CON-3 · S15-59 plan:299 · Landed bullet says "no Step names" but four of the listed files are named in the Steps; reword to "beyond the Step's list"`.

## Finish
Merged `origin/main` @ `7a44c0f66` (#990, S16-78 plan docs only). Gate PASS after merge.

## Result
Gate PASS · CI green · open: none · follow-ups: none · to user: —

## Cost
Plan: 5,100 words (check-plan-docs info line).

| Round | Agent | Model | Tokens |
| --- | --- | --- | --- |
| 0 | implementer | sonnet | 167k |
| 1 | CON | opus | 93k |
| 1 | MNT | opus | 82k |
| 1 | UX | opus | 60k |
| 1 | SEC+PRF | opus | 59k |
| 1 | implementer (fix) | sonnet | 86k |
| 2 | CON | opus | 27k |
| | **Total** | | **~574k** |
