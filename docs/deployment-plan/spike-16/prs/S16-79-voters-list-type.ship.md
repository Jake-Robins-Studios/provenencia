# Ship log — S16-79 A seeded Voters list type cites a voter list down to the entry

**Plan:** [`S16-79-voters-list-type.md`](S16-79-voters-list-type.md) · **Branch:** `s16-79-voters-list-type` · **PR:** —
**State:** implementing

## Round 0 — implement
Head `d96d26ccb` (branch cut, nothing committed). Gate not run. **Stopped on** §4 row "Copy layer" and the §11 stop "STEP-2's `rg` prints a hand copy … other than `copyLayer`".

Verified by the orchestrator: `core/database/sourcevocab/registry.go:238` (type `map`) holds `[; {meta.format}, *{meta.provider}*][ ({meta.url}…)]`. The `map` type landed in `92d4249d8` and `a5da6fff7`, after the plan's refresh base `4f0806f`. The plan counts ten hand copies and twelve copy-printing types (AC-4.3, STEP-2/3 checks, Design "Deletes"); the base has eleven and thirteen. Back to `plan-pr` for a refresh: either `map` joins `copyLayer` (D-7 as written; `map` gains `database_title` in its suggestions; counts 11/12 and AC-4.3 thirteen types) or a Decision carves it out.

Resolved: user, 2026-11-26, "Map joins" `copyLayer`. Plan refreshed against `d96d26ccb` with `plan-pr` in commit `05cc63963` on the branch (also dropped the seed-entry subtest step #999 had already deleted; 28 types; version 0.48.0); review-plan one round, Fits · Ready with changes, no blocker.

## Round 0b — implement (after refresh)

## Cost
Plan: 5,340 words (check-plan-docs info line).

| Round | Agent | Model | Tokens |
| --- | --- | --- | --- |
| 0 | implementer | sonnet | 93k |
| refresh | plan maintainability | opus | 92k |
| refresh | plan executability | sonnet | 120k |
