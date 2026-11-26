# Ship log — S16-79 A seeded Voters list type cites a voter list down to the entry

**Plan:** [`S16-79-voters-list-type.md`](S16-79-voters-list-type.md) · **Branch:** `s16-79-voters-list-type` · **PR:** #1001
**State:** ready

## Round 0 — implement
Head `d96d26ccb` (branch cut, nothing committed). Gate not run. **Stopped on** §4 row "Copy layer" and the §11 stop "STEP-2's `rg` prints a hand copy … other than `copyLayer`".

Verified by the orchestrator: `core/database/sourcevocab/registry.go:238` (type `map`) holds `[; {meta.format}, *{meta.provider}*][ ({meta.url}…)]`. The `map` type landed in `92d4249d8` and `a5da6fff7`, after the plan's refresh base `4f0806f`. The plan counts ten hand copies and twelve copy-printing types (AC-4.3, STEP-2/3 checks, Design "Deletes"); the base has eleven and thirteen. Back to `plan-pr` for a refresh: either `map` joins `copyLayer` (D-7 as written; `map` gains `database_title` in its suggestions; counts 11/12 and AC-4.3 thirteen types) or a Decision carves it out.

Resolved: user, 2026-11-26, "Map joins" `copyLayer`. Plan refreshed against `d96d26ccb` with `plan-pr` in commit `05cc63963` on the branch (also dropped the seed-entry subtest step #999 had already deleted; 28 types; version 0.48.0); review-plan one round, Fits · Ready with changes, no blocker.

## Round 0b — implement (after refresh)
Head `0f86e82ee`. Gate **FAIL xcode-test**: `PVShowMoreRowHostedTests.revealScrollsAfterTheCallerLeaves()` (`PVShowMoreRowTests.swift:71`, `visible` false after 10 s); every other check PASS. This PR changes no Swift (only `MARKETING_VERSION`); the test came with S15-30 (#996) and has had four fix commits on `main` (`d333cc4f2`, `f5a15cc5c`, `a1ed16eea`, `f30914194`). To user. Report: deviations none; the implementer committed this ship log in `a281de53d` despite being told not to (harmless; it is committed at finish anyway).

## Round 1 — review
Reviewers: CON, MNT, SEC+PRF. Skipped: UX (no `macos/App/**`, strings, or error codes).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | minor | `copyLayer` comment and `seeded-vocabulary.md` say "every format" prints the copy through it; `website` does not | Fix now → F-2 | verified: `registry.go:285` `website` Full prints `[{meta.format}, ]*{meta.site_name}*[ ({meta.url}…)]` by hand; the site is the Source, not a copy |
| CON-1, MNT-2 | CON, MNT | minor | `registry.go` header comment not re-wrapped as STEP-2 says; "registry (…): began as" has no subject | Fix now → F-1 | verified: `registry.go:9` is 89 columns; STEP-2 asks for the re-wrap |
| — | SEC+PRF | — | Clean | — | — |
| GATE | gate | blocker | Hosted Swift scroll test fails | To user | unrelated to this diff; see Round 0b |

Nits (logged): none beyond CON-1/MNT-2, raised to minor because STEP-2 asked for the re-wrap.

### Fix plan 1
**F-1 — Re-wrap the `registry.go` header comment** (from CON-1, MNT-2)
Files: `core/database/sourcevocab/registry.go`.
Failing test first: none (comment).
Do: the header reads "Declarative provenencia seed registry (create-time starter for new catalogs). It began as the citation vocabulary of the Spike 15 map, section 6.8. The types and their formats live here; the fields are in registry_fields.go, and Install derives the suggestions from the formats (registry_suggestions.go)." wrapped at the width of the comments around it (80 columns).
Check: no line of the comment passes 80 columns; `gofmt -l core` prints nothing.

**F-2 — Name `website` as the exception to the shared copy clause** (from MNT-1)
Files: `core/database/sourcevocab/registry.go`, `docs/seeded-vocabulary.md`.
Failing test first: none (comment and doc).
Do: the `copyLayer` comment's last sentence becomes "Every format that prints a copy of a record uses it; `website` cites the site itself and prints its own URL clause." The `seeded-vocabulary.md` § 2.2 sentence "Every full format that prints the online copy prints it through one shared clause, `copyLayer` in `registry.go`: …, each part when set (user, 2026-11-26)." gains, after it, "`website` cites the site itself and prints its own URL clause."
Check: `rg -n 'website. cites the site itself' core/database/sourcevocab/registry.go docs/seeded-vocabulary.md` prints two lines; `python3 scripts/check-guidance-names.py` passes.

## Round 1 — fix
Head `c74a92cc6`. F-1 done (`d896b75c8`); F-2 done (`d896b75c8` comment, `c74a92cc6` doc). Read by the orchestrator: MNT-1 **Resolved**, CON-1/MNT-2 **Resolved**. Comment and doc only since the orchestrator's gate on `0f86e82ee`; the implementer's gate on `c74a92cc6` fails only on the same hosted scroll test. No round 2: round 1 had no Fix-now blocker or major. Waiting on the user for the scroll test.

## Gate fix — hosted scroll test
User, 2026-11-26: "Fix it on #1001". Orchestrator diagnosis: in `PVShowMoreRowTests.swift` `Harness`, `Probe` is in the tree from the first update, so its `onAppear` asks for the reveal before the test's `eventually` lays the list out. `PVScrollRowIntoView`'s request path scrolls once, on the next main-actor turn (`Task { proxy.scrollTo }`); in a never-shown window that turn can come before the first `layoutSubtreeIfNeeded()` gives the document its rows, so `scrollTo` finds nothing and is never retried. The "Wait for the list to lay out" step does not guard it, since the ask already happened. The app is not affected: a Show more is pressed after its list is on screen.

### Fix plan G-1
**G-1 — Ask for the reveal only after the list is laid out** (gate)
Files: `macos/ProvenenciaTests/PVShowMoreRowTests.swift`. Skill: `add-swift-test`.
Failing test first: none new; the test is the one that fails.
Do: `Harness` takes a `@MainActor @Observable final class` trigger *(new, private to the suite)* with `var asking = false`; `Probe` is in the tree only while `trigger.asking && probing`, and still asks and leaves in one action in `onAppear`. The test hosts the harness, waits for `laidOut` as today, then sets `trigger.asking = true`, then waits for `visible` as today. No change to app code, `HostedWindow.swift` or the timeout. Keep `.pvScrollsShowMoreReveals(animated: false)` and its comment.
Check: scripts/check-pr.sh PASS, run once. No repeat runs to chase a pass.

### Gate fix — attempt 1
Nothing committed; head still `c74a92cc6`. G-1 edit in the working tree, but `Trigger` is declared `private` inside the suite and the test method cannot name it: check-pr FAIL xcode-test, build error "'Trigger' is inaccessible due to 'private' protection level". The implementer's `sed` to drop `private` did not apply (verified: line still reads `@MainActor @Observable private final class Trigger`), and its second check-pr run was denied by the auto-mode permission check. Gate failure 1 of 3. To user: the denied re-run.

### Gate fix — attempt 2
Head `79940348e` ("Ask for the Show more reveal only after the test's list is laid out."), `private` dropped from `Trigger` (user approved the run, 2026-11-26). Implementer gate PASS; orchestrator gate PASS on `79940348e` (xcode-test 41 s). `origin/main` still `d96d26ccb`: no merge needed.

## Result
Gate PASS · CI pending · open: none · follow-ups: none · to user: answered (Map joins `copyLayer`; scroll test fixed on #1001)

## Cost
Plan: 5,476 words (check-plan-docs info line).

| Round | Agent | Model | Tokens |
| --- | --- | --- | --- |
| 0 | implementer | sonnet | 93k |
| refresh | plan maintainability | opus | 92k |
| refresh | plan executability | sonnet | 120k |
| 0b | implementer | sonnet | 119k |
| 1 | CON | opus | 66k |
| 1 | MNT | opus | 51k |
| 1 | SEC+PRF | opus | 49k |
| 1 | implementer fix | sonnet | 72k |
| gate | implementer G-1 | sonnet | 70k |
| gate | implementer G-1b | sonnet | 66k |
| | **Total** | | **798k** |
