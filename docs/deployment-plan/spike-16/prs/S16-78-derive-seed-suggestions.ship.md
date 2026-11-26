# Ship log — S16-78 Install derives each seeded type's suggested fields from its formats

**Plan:** [`S16-78-derive-seed-suggestions.md`](S16-78-derive-seed-suggestions.md) · **Branch:** `s16-78-derive-seed-suggestions` · **PR:** #993
**State:** ready

## Round 0 — implement
Head `7d45674d4`. Gate PASS (orchestrator run). Report: no Landed note (code matches plan); the map's S16-78 scope entry (deployment-plan.md ~1226–1228) still names `seedSuggestions` and `TestSeedSuggestionsFollowFormats` as the old state, outside the sweep paths; manual check not run in the app (TestInstall equality covers it).

## Round 1 — review
Reviewers: CON, MNT, SEC+PRF. Skipped: UX (no `macos/App/**`, strings, or error codes).

No blocker, major or minor from any lens. CON verified AC-1.1 by running STEP-1 commit `3423828a3`'s `TestInstall` against the untouched hand lists (pass) and diffing formats unchanged to head. SEC+PRF: no untrusted input; fixed 26×3 parse at create.

Nits (logged): `CON-1 / MNT-1 · core/database/sourcevocab/registry_test.go:37 · census[0] has no length guard; an empty list panics instead of failing` · `MNT-2 · registry_test.go TestSeededFormatsNeedOnlySuggestedFields · doc comment could say it now checks a property of suggestedKeys` · `CON-2 · plan:3 · DoD asks for a Landed note` (closed by the orchestrator in the ship-log commit: "As planned") · `CON-3 · deployment-plan.md:405 · map row Landed #993 unlinked` (linked in the ship-log commit)

No fix round; no round 2 (no Fix-now blocker or major).

## User change — seed-data tests retire (user, 2026-11-26)

After round 1 the user ruled: the seed is data, just vocabulary; a unit test of `Install` is enough, and tests that validate the registry entries go. Asked which tests: **all seed-data tests**, including the golden render and the board-needs table; landing **on this PR**. This supersedes the plan's D-4 (`TestSuggestedKeys` per-type checks), T-3's per-type cases and T-4 (`TestSeedAnnotations` stays green → deleted), and S16-79's planned test additions.

### Fix plan U

**F-U1 — Delete the registry content tests**
Files: `core/database/sourcevocab/registry_test.go`.
Do: delete `TestSeedFieldsAreRead`, `unreadFields`, `TestSeedTypes`, `TestSeededFormatsNeedOnlySuggestedFields`, `TestSeedPlaceFields`, and `mustParseForm` if nothing else uses it. Keep `TestFieldKeysMatchSeed`: it guards a key code reads by name (`vocabkey.FieldPage`), a code-to-data contract, not a content check.
Check: `rg -n "TestSeedFieldsAreRead|TestSeedTypes|TestSeededFormatsNeedOnlySuggestedFields|TestSeedPlaceFields|unreadFields" core` prints nothing.

**F-U2 — `TestSuggestedKeys` tests the rule, not the seed**
Files: `registry_test.go`.
Do: rewrite `TestSuggestedKeys` as a table test over hand-written `sourcetypes.Formats` (not `seedTypes`), one case per clause of the § 2.3 rule as `suggestedKeys`' doc comment states it: full format's fields in first-read order; a list/short needed chain the full format does not meet is appended; a chain the full format already meets adds nothing; a field read twice appears once; an optional (grouped) field in list/short only adds nothing; built-ins (no field key) add nothing. Delete the census spot check and the per-seed-type loop.
Check: the test passes.

**F-U3 — `TestInstall` checks Install, not the seed's size**
Files: `core/database/sourcevocab/sourcevocab_test.go`.
Do: in "empty catalog gets the seed" delete the `len(seedTypes) != 26 || len(seedFields) != 69` pin and the "has no suggestions" fatal; keep every row-for-row comparison with `seedTypes`/`seedFields`/`suggestedKeysOf` (that is Install's contract). Leave the other cases.
Check: `TestInstall` passes.

**F-U4 — Delete the golden render**
Files: `core/database/sourcevocab/render_test.go`, `testdata/seed-citations.txt`.
Do: delete both (the file holds only `TestSeedCitations` and its fixture). `storedFormats` lives in `sourcevocab_test.go` and stays (copy_test uses it).
Check: `rg -n "seed-citations|TestSeedCitations|fieldValues|fixtureCreators|plainWithItalics" core` prints nothing.

**F-U5 — Delete the board-needs seed table**
Files: `core/database/sourcemetadata/sourcemetadata_test.go`.
Do: delete `seedExpect`, `seedExpectations` and `TestSeedAnnotations`. Keep `seededWorld` and every other test that uses it.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcemetadata/...` passes.

**F-U6 — Guidance and docs**
Files: `.agents/skills/add-seeded-vocabulary/SKILL.md` (line ~39 the `-update` golden step; step 6 Tests), `docs/seeded-vocabulary.md` (line ~91 `testdata` mention; § 2.3 sentence naming `TestSuggestedKeys`), and any hit of the deleted names under `.agents/`, `.cursor/rules/`, `docs/*.md`.
Do: remove the golden step; step 6 says the seed is data: `TestInstall` checks Install writes the registry row for row and rolls back a bad entry, `TestSuggestedKeys` tests the rule on synthetic formats, and no test validates registry entries (user, 2026-11-26). Rewrite each doc hit to match.
Check: `scripts/check-guidance-names.py` passes; `rg -n "TestSeedCitations|TestSeedAnnotations|TestSeedFieldsAreRead|TestSeedTypes|TestSeedPlaceFields|TestSeededFormatsNeedOnlySuggestedFields|seed-citations" .agents .cursor/rules docs/*.md` prints nothing.

Commits: F-U1–F-U3 one commit ("Test Install and the suggestion rule, not the seed's entries."), F-U4 + F-U5 one ("Remove the golden render and board table that re-check seed data."), F-U6 one. Then `scripts/check-pr.sh` PASS.

Orchestrator (not the implementer): the S16-78 plan's Landed note and S16-79's plan get a note of the superseded tests.

## User change — review
Reviewer: CON (fresh), scope `7e423e960...250dc9c4b`. Gate PASS at `250dc9c4b`.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-U1 | CON | minor | `TestSuggestedKeys` has no list-before-short order case | Fix now → F-U7 | verified by the reviewer: swapping the form order via `go test -overlay` still passes |
| CON-U2 | CON | minor | No case has an unmet chain with two field options | Fix now → F-U7 | verified: appending only the first option via overlay still passes |

Nits (logged): `CON-U3 · deployment-plan.md:1219 · S16-79 Ships line still promises golden and literal renders` (orchestrator: noted the refresh on that line)

### Fix plan U2
**F-U7 — Two more rule cases** (from CON-U1, CON-U2)
Files: `core/database/sourcevocab/registry_test.go`.
Failing test first: none fails today; each case fails under its mutation (form order Full, Short, List; append only the first option of a chain).
Do: add to `TestSuggestedKeys`' table `{name: "list-needed fields come before short-needed ones", formats: sourcetypes.Formats{Full: `{meta.a}`, List: `{meta.z}`, Short: `{meta.y}`}, want: []string{"a", "z", "y"}}` and `{name: "every field option of an unmet needed chain is appended", formats: sourcetypes.Formats{Full: `{meta.a}`, List: `{meta.y|meta.z}`}, want: []string{"a", "y", "z"}}`.
Check: both pass; scripts/check-pr.sh PASS.

## User change — fix
Head `d198715a1`. Gate PASS. F-U7 done; CON-U1 and CON-U2 **Resolved** (orchestrator read the commit: both table rows as written).

## Result
Gate PASS · CI green (see PR) · open: none · follow-ups: S16-79 plan refresh (seed-data tests retired) · to user: —

## Cost
Plan: 2,488 words (check-plan-docs info line).

| Round | Agent | Model | Tokens |
| --- | --- | --- | --- |
| 0 | implementer | sonnet | 114k |
| 1 | CON | opus | 60k |
| 1 | MNT | opus | 59k |
| 1 | SEC+PRF | opus | 46k |
| U | implementer | sonnet | 88k |
| U | CON | opus | 60k |
| U2 | implementer | sonnet | 69k |
| | **Total** | | **496k** |
