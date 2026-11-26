# Review — S16-73 A seeded Voters list type cites a voter list down to the entry

**Verdict:** Fits with changes · Ready with changes, two rounds; no blocker open; To user answered (2026-11-26).
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet) ([`review-plan`](../../../../.agents/skills/review-plan/SKILL.md)).

## To user

- **M-2: share the copy layer?** Answered (user, 2026-11-26): "Share it, title everywhere". One `copyLayer` const replaces the ten hand copies, and every record type prints the database title when it is set. The plan gains US-4, D-7's new text and STEP-2.
- **M-5: derive suggestions in Install?** Answered (user, 2026-11-26): "Yes, plan it first". This became the preparatory PR S16-74 ([plan](S16-74-derive-seed-suggestions.md)). S16-73 depends on it and is `Blocked — on S16-74`, and it adds no hand suggestion list.

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
**Answer:** To user, answered "plan it first". This is S16-74.

### M-6 · minor · `fixture` gains a fourth mode
**Answer:** Declined. Making `values` the fixture's one input rewrites how the golden builds its full, bare and no-page fixtures for every type. That is a refactor this PR does not need. `values` is one documented switch beside them.

### M-7 · nit · D-11 restates Codebase fit
**Answer:** Fixed. D-11 points at Codebase fit.

## Round 2

Fresh reviewers had the plan and this log: maintainability (opus) gave Fits with changes, and executability (sonnet) gave Ready with changes. Both confirmed that every round-1 answer holds.

### M-8 / X-1 (round 2) · blocker · STEP-2 breaks S16-74's census count of 18
**Answer:** Fixed in S16-74. Its `TestSuggestedKeys` now pins `creator` first, `citing` last and no count, and § 2.3 drops "18" (S16-74 M-4, option A). S16-73's STEP-2 says the test stays green, and a stop condition catches a census list without `database_title` before `format`.

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
