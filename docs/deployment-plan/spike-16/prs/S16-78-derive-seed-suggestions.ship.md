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

## Result
Gate PASS · CI pending · open: none · follow-ups: none · to user: —

## Cost
Plan: 2,488 words (check-plan-docs info line).

| Round | Agent | Model | Tokens |
| --- | --- | --- | --- |
| 0 | implementer | sonnet | 114k |
| 1 | CON | opus | 60k |
| 1 | MNT | opus | 59k |
| 1 | SEC+PRF | opus | 46k |
| | **Total** | | **279k** |
