# Ship log — S15-49 The Source types list is redesigned

**Plan:** [`S15-49-source-types-list.md`](S15-49-source-types-list.md) · **Branch:** `s15-49-source-types-list` · **PR:** #852
**State:** ready

## Round 0 — implement
Base `main` @ `1f52b6080`. Note to the implementer: T-1's `sortColumn == .usage` is a typo for `.usedBy` (D-6, review M-2).
Head `f8f8349a7`, PR #852 (draft). Report: version 0.15.5 (main was already 0.15.4); brief links repointed into `design/archive/` incl. the review log; manual check not run.

### Gate
Implementer's gate PASS. Orchestrator's gate hung twice in `xcode-test` (not a failure of this PR's code):
`SourceTypePageModelTests.aSaveInFlightIsNotHeld` (landed in S15-48) — `waitUntil` (2 s default) times out before
`submit()` reaches `updateSourceTypeHold.wait()` under full-suite load (passing runs took 14–16 s); `release()` then finds
no waiter, the late `wait()` suspends forever, and `await save.value` never returns. Same issue at line 560 in both hung
logs (`check-pr.3tDmc4`, `check-pr.ufSbDB`). 27 `Hold.count` waits across 8 test files share the pattern.
User (2026-11-15): fix it on this PR.

### Fix plan 0 (gate)
**F-0 — A test waits for a held store call with no deadline** (gate hang; not a review finding)
Files: `macos/App/Platform/FakeStore.swift` (`FakeHold`), `macos/ProvenenciaTests/QueryHandleWaiting.swift` (only if a shared doc line belongs there), and the 8 test files below. Skill: `add-swift-test`.
Failing test first: none practical (the failure is a timing race under full-suite load); evidence is the two hung gate logs.
Do: give `FakeHold` an `async` method that suspends until exactly `n` calls are suspended in `wait()` — no deadline, signalled from `append`/`takeOldest` under the existing lock (continuations, not polling), with a doc comment saying why it has no deadline (a full-suite run starves the main actor past any fixed timeout; see `QueryHandleWaiting.swift`'s no-deadline helper). Move every positive wait on a hold's count onto it: each `#expect(await waitUntil { x.count == n })`, `try #require(await waitUntil(timeout:) { x.count == n })` and the `while x.count == 0 { await Task.yield() }` loop in `PersonDetailTests.swift:348`. Keep the two negative checks (`!(await waitUntil(timeout: .milliseconds(300)) { … count == 2 })` in `SourceGraphFormModelTests.swift:396`, `SourcePageModelTests.swift:2344`) as they are: they assert something does *not* happen.
Sites: `SourceGraphFormModelTests` 394, 408 · `SourceTypePageModelTests` 560 · `SourcePageModelTests` 2340, 2362, 2380 · `EvidenceGraphModelTests` 826, 834, 883, 891 · `PersonDetailTests` 348 · `CatalogCountsTests` 103 · `UnpromoteFlowTests` 184, 188, 190, 243, 261, 353 · `WorkspaceSessionTests` 2125, 2134, 2358, 2406, 2409, 2424, 2457.
Check: `grep -rnE 'waitUntil.*Hold\.count|Hold\.count == 0' macos/ProvenenciaTests` prints only the two negative lines (`SourceGraphFormModelTests.swift:396`, `SourcePageModelTests.swift:2344`); `scripts/check-pr.sh` PASS, run twice. Commit subject is a full sentence, e.g. "Wait for a held store call without a deadline so slow full-suite runs cannot hang the tests."

## Round 0 — gate fix
Head `38635f753`. F-0 done: `FakeHold.untilSuspended(_:)` (continuations, no deadline); 27 positive waits moved; grep prints only the two negative 300 ms lines. Implementer gate PASS ×2; orchestrator gate PASS (xcode-test 77 s).

## Round 1 — review
Base `1f52b6080`, head `38635f753`. Reviewers: CON, MNT, UX (`macos/App/**`, `Localizable.xcstrings`), SEC+PRF (performance: `macos/App/Features/**` models; no security path touched, run together per the rule).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | blocker | Six positive hold waits (local `hold`) still poll `count` with a deadline | Fix now → F-1 | verified: `rg 'waitUntil.*\w+\.count =='` prints `WorkspaceSessionTests.swift:184`, `PromoteModelTests.swift:343/348/371/377/420`; F-0's grep was by name, not body. Same-pass cleanup |
| MNT-2, CON-2 | MNT, CON | major | `add-swift-test` still teaches `count` polling for a `FakeHold` | Fix now → F-2 | verified: `.agents/skills/add-swift-test/SKILL.md:21` names `count`, no `untilSuspended` |
| UX-1 | UX | major | VoiceOver reads the two count cells as bare numbers / two dashes | Fix now → F-3 | verified: `PVTable.swift:345` `.accessibilityElement(children: .combine)`; `countCell` has no label. Spoken-only label keeps D-2's on-screen look |
| CON-1 | CON | major | Archived S15-D28 brief and the review log have broken relative links | Fix now → F-4 | verified: 9 broken targets from `design/archive/`; review log href still `../design/S15-D28-…` |
| UX-2, CON-3b, SEC outside-lens | UX, CON | minor | `.help` on every description cell, D-3 says non-empty only | Fix now → F-5 | verified: `SourceTypesListPane.swift:84` unconditional |
| CON-3a | CON | major | Landed note omits the `FakeHold` change | Fix now → F-6 | verified: plan § Landed has 3 bullets, none on test infra |

Nits (logged): `UX-3 · SourceTypesListPane.swift · cut label at Wide has no tooltip` · `MNT-3 · SourceTypesModelTests.swift:918 · width constant re-checked` · `MNT-4 · FakeStore.swift:94-97 · filter then removeAll, one partition pass` · `CON-4 · FakeStore.swift:36 · say an overshoot past n waits forever` · `CON-5 · 38635f753 subject overstates` (SEC+PRF outside-lens note on overshoot hang folded into CON-4)

### Fix plan 1
**F-1 — Every positive hold wait uses `untilSuspended`** (from MNT-1)
Files: `macos/ProvenenciaTests/WorkspaceSessionTests.swift`, `PromoteModelTests.swift`, `CitationAutoTranscribeTests.swift`.
Do: `WorkspaceSessionTests.swift:184` `_ = await waitUntil { hold.count == 1 }` → `await hold.untilSuspended(1)`; `PromoteModelTests.swift:343, 348, 371, 377, 420` `#expect(await waitUntil { hold.count == 1 })` → `await hold.untilSuspended(1)`; `CitationAutoTranscribeTests.swift` before `engine.hold.release()` (~line 360) add `await engine.hold.untilSuspended(1)` so the release cannot run before `recognizeText` reaches the hold (keep the `isTranscribing` expectations).
Check (by body, not name): `rg -n 'waitUntil[^{]*\{ *[\w.]+\.count ==|\.count == 0 \{ await Task.yield' macos/ProvenenciaTests` prints only `SourceGraphFormModelTests.swift:396` and `SourcePageModelTests.swift:2344` (the negative 300 ms checks).

**F-2 — The test skill and `waitUntil` doc name `untilSuspended`** (from MNT-2, CON-2)
Files: `.agents/skills/add-swift-test/SKILL.md:21`, `macos/ProvenenciaTests/QueryHandleWaiting.swift` (`waitUntil` doc), `macos/App/Platform/FakeStore.swift` (`untilSuspended` doc, CON-4).
Do: skill line → "`FakeHold` (`isOn`, `release()`; wait for a held call with `await hold.untilSuspended(n)`, never `waitUntil` on `count`; `count` is for negative checks only, such as no second call within 300 ms)". One sentence on `waitUntil`: for a `FakeHold`, use `untilSuspended`. On `untilSuspended`: it waits for exactly `n`, so pick `n` from calls the test controls; a count that passes `n` and never comes back waits forever.
Check: `rg -n untilSuspended .agents` finds the skill line; `scripts/check-guidance-names.py` passes.

**F-3 — Each count cell has a spoken label** (from UX-1)
Files: `macos/App/Features/SourceTypes/SourceTypesListPane.swift`, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`. Skill: `add-localized-string`.
Do: `countCell(_ count: Int, spoken: String)`; the cell adds `.accessibilityLabel(Text(verbatim: spoken))`; on-screen text unchanged (D-2). `usedBy` passes `L10n.SourceTypes.usage(count: type.usedBy)` (reused: "in use on %lld sources" / its zero case). `fields` passes a new `L10n.SourceTypes.suggestedFieldsSpoken(count:)` shaped like `usage(count:)`: 0 → key `sourceTypes.list.suggestedFieldsNone` "no suggested fields"; else `sourceTypes.list.suggestedFields` "%lld suggested fields", comment "VoiceOver label for the Associated fields count in the Source types list; argument is the count" (plural variations as `sourceTypes.detail.usage` has them, if it has them).
Check: build; `check-localizable-xcstrings.py` OK.

**F-4 — The archived brief's links resolve** (from CON-1)
Files: `docs/deployment-plan/spike-15/design/archive/S15-D28-source-types-list.md`, `docs/deployment-plan/spike-15/prs/S15-49-source-types-list.review.md`.
Do: as df13d1b11 did for S15-D27: one more `../` on each relative link; `archive/S15-D2-…` and `archive/S15-D27-…` drop `archive/`; `README.md` → `../README.md`. Review log href → `../design/archive/S15-D28-source-types-list.md`.
Check: from `design/archive/`, every non-http link target in the brief exists (`[ -e ]` loop); same for the review log from `prs/`.

**F-5 — Only a non-empty description carries a tooltip** (from UX-2, CON-3b)
Files: `SourceTypesListPane.swift`. Do: `.help` only when `!type.description.isEmpty` (D-3). Check: build.

**F-6 — The Landed note lists the test-infra change** (from CON-3a)
Files: `docs/deployment-plan/spike-15/prs/S15-49-source-types-list.md` § Landed. Do: one bullet: on the user's request (2026-11-15) this PR adds `FakeHold.untilSuspended(_:)` and moves every positive hold wait onto it, fixing a full-suite hang in `SourceTypePageModelTests.aSaveInFlightIsNotHeld` (landed in S15-48); and the spoken labels on the count cells (F-3). Check: `python3 scripts/check-plan-docs.py` on the plan, 0 errors.

Whole round Check: `scripts/check-pr.sh` PASS.

## Round 1 — fix
Head `f4e17f9b4`. Orchestrator gate PASS (xcode-test 79 s); body-level sweep prints only the two negative lines. F-1 – F-4, F-6 done.
F-5: **Resolved in effect, code redundant** — the cell is `.help(type.description.isEmpty ? "" : type.description)`, which equals `.help(type.description)`; an empty `.help("")` shows no tooltip (precedent `SourcesListRow.swift:300` `.help(… ?? "")`). Logged as nit `ORC-1 · SourceTypesListPane.swift:84 · ternary is a no-op; write .help(type.description)`; rides on a Fix plan 2 if round 2 needs one.

## Round 2 — review
Scope `38635f753...f4e17f9b4`. Reviewers: MNT (MNT-1 blocker), CON (CON-1, CON-3 majors), UX (UX-1 major). Not sent: SEC+PRF (no findings).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | blocker | (round 1) | Resolved | body-level sweep prints only the two negative lines; all 12 `FakeHold`s checked |
| MNT-2, CON-2 | MNT, CON | major | (round 1) | Resolved | skill line 21 and both doc comments name `untilSuspended` |
| CON-1 | CON | major | (round 1) | Resolved | all 9 brief links and the review-log link resolve |
| CON-3a | CON | major | (round 1) | Resolved | Landed bullet at plan line 280 |
| UX-1 | UX | major | (round 1) | Resolved | `countCell(_:spoken:)` labels; plural keys |
| UX-2, CON-3b | UX, CON | minor | (round 1) | Resolved in effect | read by orchestrator: empty `.help("")` shows nothing; code redundant (ORC-1) |

No new findings in round 2 (CON, MNT, UX all Clean). No Fix plan 2.

## Finish
Merged `origin/main` @ `ce1dbf761` (S16-27 plan docs only) → `8c21d62cc`. Orchestrator gate PASS (xcode-test 68 s).

## Result
Gate PASS · CI pending · open: none · follow-ups: none · nits open: ORC-1 (`.help` ternary is a no-op) · to user: —
