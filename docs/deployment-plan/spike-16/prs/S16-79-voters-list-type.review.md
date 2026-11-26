# Review — S16-79 A seeded Voters list type cites a voter list down to the entry

**Verdict:** Fits with changes · Ready with changes, two rounds; no blocker open; To user answered (2026-11-26).
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet) ([`review-plan`](../../../../.agents/skills/review-plan/SKILL.md)).

## To user

- **M-2: share the copy layer?** Answered (user, 2026-11-26): "Share it, title everywhere". One `copyLayer` const replaces the ten hand copies, and every record type prints the database title when it is set. The plan gains US-4, D-7's new text and STEP-2.
- **M-5: derive suggestions in Install?** Answered (user, 2026-11-26): "Yes, plan it first". This became the preparatory PR S16-78 ([plan](S16-78-derive-seed-suggestions.md)). S16-79 depends on it and is `Blocked — on S16-78`, and it adds no hand suggestion list.

## Writer's own calls

- **D-6.** No `source.date` in the voters list formats; the election value carries the year.
- **D-8.** No `creator`, no `citing` and no `film_publication` in the formats.
- **Icon.** `type_document`, so no asset and no brief.
- **Version.** Minor, because a new seeded type is a feature.
- **URL group placement.** The shared copy layer keeps the URL group beside the copy group, as the ten types have it today, not nested as the first draft had it for the voters list. The voters list renders are the same in every case the ACs pin.

## Round 1

### X-1 · blocker · `TestSeedAnnotations`' closing totals fail at STEP-2
**Answer:** Fixed. STEP-3, then STEP-2, now names the new totals: 34, `2*(34-4)`, 30, 5, with their message. § 4's Board needs row quotes today's line. Checked at `sourcemetadata_test.go:3437`.

### X-2 · major · Count messages not named
**Answer:** Fixed. STEP-1 and STEP-3 give the condition and message of `TestInstall`. `placeholders_test.go` stops counting (M-4).

### X-3 · major · STEP-5 doc edits left to judgment
**Answer:** Fixed. The docs step, now STEP-6, lists each line to change and the Spike 15 lines to leave as #967 left them.

### X-4 · major · completed.md and map row text
**Answer:** Fixed. They are written after the PR opens, and the plan gives the wording.

### X-5 · minor · Stale local `main`
**Answer:** Fixed. The **Planned** line says `origin/main` @ `0886b43` and to fetch it. The golden has 157 lines because of court report's no-page line, and § 4 says so.

### X-6 · minor · `fixture.values` details
**Answer:** Fixed. STEP-5 says what a missing key answers, that `bare`, `noPage` and the creator are ignored, and that the setup goes through `seedRenderer` (M-1).

### X-7 · minor · Stale `unreadFields` comment in STEP-1
**Answer:** Declined. It is temporary, and STEP-3 rewrites it.

### X-8 · minor · STEP-3 stop condition
**Answer:** Fixed by STEP-2 and STEP-4 each naming the exact `git diff` they expect.

### M-1 · major · The literal-render test copies `TestSeedCitations`' setup
**Answer:** Fixed. `seedRenderer` is moved, not copied (STEP-5, Codebase fit). The skill bullet points at it.

### M-2 · major · Eleventh hand-typed copy layer
**Answer:** To user, answered "Share it, title everywhere" (see To user). D-7 and STEP-2 follow.

### M-3 · major · The format rule is in no skill
**Answer:** Fixed. STEP-6 adds the bullet to `add-seeded-vocabulary` § Source vocabulary step 1.

### M-4 · major · A seed count restated outside `TestInstall`
**Answer:** Fixed. `placeholders_test.go` asserts non-empty, and the `seedFields` comment drops its count (STEP-1, STEP-3, T-9).

### M-5 · major · Hand entry in `seedSuggestions`
**Answer:** To user, answered "plan it first". This is S16-78.

### M-6 · minor · `fixture` gains a fourth mode
**Answer:** Declined. Making `values` the fixture's one input rewrites how the golden builds its full, bare and no-page fixtures for every type. That is a refactor this PR does not need. `values` is one documented switch beside them.

### M-7 · nit · D-11 restates Codebase fit
**Answer:** Fixed. D-11 points at Codebase fit.

## Round 2

Fresh reviewers had the plan and this log: maintainability (opus) gave Fits with changes, and executability (sonnet) gave Ready with changes. Both confirmed that every round-1 answer holds.

### M-8 / X-1 (round 2) · blocker · STEP-2 breaks S16-78's census count of 18
**Answer:** Fixed in S16-78. Its `TestSuggestedKeys` now pins `creator` first, `citing` last and no count, and § 2.3 drops "18" (S16-78 M-4, option A). S16-79's STEP-2 says the test stays green, and a stop condition catches a census list without `database_title` before `format`.

### X-2 (round 2) · major · The version bump has no step
**Answer:** Fixed. STEP-5 moves `VERSION`, `core/version.go` and every `MARKETING_VERSION` to the next minor.

### X-3 (round 2) · minor · Stale step references after the renumbering
**Answer:** Fixed. The golden folds into STEP-3, so the steps are 1 to 5. Scope, T-8, T-10 and the stop conditions use the new numbers.

### X-4 (round 2) · minor · STEP-3 ended red
**Answer:** Fixed. STEP-3 runs `-update` itself and ends green.

### X-5 (round 2) · minor · `seedRenderer` choices
**Answer:** Fixed. One catalog closed by `t.Cleanup`, the key map built once, and the type and formats looked up per call.

### Below the bar · `docs/seeded-vocabulary.md:91` points at the Spike 15 map's formats
**Answer:** Logged, not fixed here. That map's formats have drifted from `registry.go` since #967. Repointing the line is a docs fix for a later pass and does not bear on this PR.

**Final verdict:** Fits with changes · Ready with changes, two rounds; no blocker open; To user answered (M-2, M-5).

## Refresh (2026-11-26, after S16-78 landed in #993)

S16-78 landed with a user change: the seed is data, and no test validates registry entries ("all seed-data tests"). The refresh drops every planned seed test (golden, literal renders, board table, counts, `seedRenderer`, `fixture.values`) and checks the ACs with uncommitted renders (D-11) and the app check. At `4f0806f` the writer rendered AC-1.1 – AC-2.3 and AC-4.1 – AC-4.2 through `citationformat.Render` and ran `suggestedKeys` on the formats (AC-3.1): all match.

**Writer's own calls (refresh).** D-11 (uncommitted overlay renders as AC evidence); deleting `TestPlaceholders`' seed subtest (M-1, read as inside the user's "all seed-data tests"); leaving the Spike 15 citation map untouched and pointing `seeded-vocabulary.md` at `registry.go` (M-3); `polling_division` on the `graph` line of § 2.2 (X-1); version 0.47.0.

### Refresh round 1

**Reviewers:** maintainability (opus), executability (sonnet). Verdicts: Fits with changes · Ready with changes.

- **M-1 · blocker · `TestPlaceholders` keeps a seed-entry check.** Fixed — STEP-3 deletes the subtest; `Install` already refuses a seed format with a diagnostic (`sourcevocab.go` `Install`), so `TestInstall` covers loading. T-1 is now `TestInstall`.
- **M-2 · major · Skill bullet's order contradicts ten older formats.** Fixed — the bullet names new or rewritten formats and says which older ones print the copy before the archive; Out line for reordering them.
- **M-3 · major · Spike 15 map half-updated; still the formats' named home.** Fixed — no edit to the map (Out line); `seeded-vocabulary.md` line 91 points at `registry.go`.
- **M-4 · minor · "record type" names two sets.** Fixed — "types that print a copy" throughout.
- **M-5 · minor · Hand-typed film clause beside `copyLayer`.** Fixed — Out line with the reason (two exact copies; church register's differs).
- **M-6 · minor · D-11 harness rebuilt from history.** Declined — no other seed-format PR is in the map; D-11 now carries the full recipe (X-2).
- **X-1 · major · `polling_division` level.** Fixed — STEP-4 puts it on the `graph` line, matching § 10.
- **X-2 · minor · No runnable D-11 recipe.** Fixed — D-11 gives the overlay JSON, command, Parse call and title match.
- **X-3 · minor · Title with no format or provider drops.** Fixed — an Edges line accepts it, as today.
- **X-4 · nit · Map line 870 still says 26.** Logged; the map is left whole as Spike 15's record (M-3).
- **X-5 · nit · Doc comments.** Logged.


### Refresh round 2

**Reviewers:** maintainability (opus), executability (sonnet). Verdicts: Fits with changes · Ready with changes. Every round-1 answer holds; no new blocker.

- **Maintainability, below the bar · § 6.8 still named as the seed in two lines.** Fixed — STEP-4 rewords `seeded-vocabulary.md` line 83 and the skill's step 2: the seed began as § 6.8 and `registry.go` is now its record.
- **X-6 · minor · AC-4.3 unchecked for eleven types.** Fixed — STEP-2's check adds `git diff -U0` on `registry.go`: each changed line differs only by the clause. Their suggestions follow from `suggestedKeys`, which `TestSuggestedKeys` covers.
- **X-7 · minor · Xcode and app boxes off macOS.** Declined — `implement-pr` and `ship-pr` say how a box that cannot run is reported; D-11 gives the evidence that runs anywhere.
- **X-8 · minor · Commit boundaries.** Fixed — STEP-4's Commits line maps steps to commits and puts the Landed edits last.
- **X-9 · nit · `copyLayer` comment.** Fixed — STEP-2 gives it.

**Verdict (refresh):** Fits with changes · Ready with changes, two rounds; no blocker open; To user: none.

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| R1 | maintainability | opus | 131k |
| R1 | executability | sonnet | 105k |
| R2 | maintainability | opus | 133k |
| R2 | executability | sonnet | 115k |

### Second refresh (against `d96d26ccb`)

The implementer stopped at round 0: the Map type (#997) holds an eleventh hand copy of the copy clause. User, 2026-11-26: Map joins `copyLayer` (D-7 as written). The refresh also drops the seed-entry subtest step (#999 deleted it), moves the type count to 27 → 28 and the version to 0.48.0.

**Reviewers:** maintainability (opus), executability (sonnet), one round. Verdicts: Fits · Ready with changes. No blocker or major.

- **M-1 · minor · `registry.go` header still calls the seed § 6.8.** Fixed — STEP-2 rewords it to "began as".
- **M-2 · minor · Skill bullet's hand list of older formats.** Fixed — STEP-4's bullet says formats written before the rule may print the copy first, `registry.go` being their record; no list.
- **M-3 · minor · Copy-type counts restated in prose.** Declined — each count names a different set (hand copies, types, `rg` hits) the implementer checks against; the stop condition caught the drift this time, which is its job.
- **X-1 · minor · D-5 says `election` is needed in the list form.** Fixed — D-5: full and short.
- **X-2 · minor · Commit order.** Fixed — STEP-1 stays uncommitted through STEP-2.
- **X-3 · minor · Skill step 2 replacement leaves a dangling clause.** Fixed — STEP-4 quotes and replaces the whole sentence.
- **X-4 · minor · STEP-4 check misses "The 69 are".** Fixed — added, plus an `rg` for "is the citation vocabulary of".
- **X-5 · nit · Bullet vs sentence.** Fixed — appended to the `seedTypes` bullet.
- **X-6 · nit · Stale ship log.** Logged; the orchestrator updates it.

**Verdict (second refresh):** Fits · Ready with changes, one round; no blocker open; To user: answered (Map joins).

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| R1 | maintainability | opus | 92k |
| R1 | executability | sonnet | 120k |
