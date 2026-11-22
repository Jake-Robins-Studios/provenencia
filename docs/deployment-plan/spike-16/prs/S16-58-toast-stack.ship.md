# Ship log — S16-58 Toasts stack in one list per window

**Plan:** [`S16-58-toast-stack.md`](S16-58-toast-stack.md) · **Branch:** `s16-58-toast-stack` · **PR:** #941
**State:** fixing 3 — user dogfood

## Round 0 — implement
Head `d998b278f`. Gate PASS (orchestrator run against `cff856a14`). Report deviations: base moved to `cff856a14` (no Current state row changed); version bump 0.33.0 → 0.33.1 (VERSION was already 0.33.0); `.agents/skills/review-pr/lenses/ux.md:88` reworded (named `lastRefreshError`, failed guidance-names); README Toast row also names the stack, list and one-caller rule. Manual check §10 not run.

## Round 1 — review
Reviewers: CON, MNT, UX (`macos/App/**`), SEC+PRF (performance: `macos/App/Features/**` models — `CatalogCounts`, `WorkspaceSession`, `CitationComposerModel`; an uncapped list). Base `cff856a14`, head `d998b278f`.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | major | AC-3.1 has no test though the composer suite already saves a bridge | Fix now → F-2 | verified: `CitationComposerModelTests.pendingConnectionOnNewAndExisting` calls `saveAuthoring()` on a `.connect` model; nothing reads `session.toasts` |
| MNT-1 | MNT | major | The empty-body-to-nil rule lives in two places | Fix now → F-1 (the card path goes) | verified: `PVToastList.swift` `add` and `VocabularyChrome.swift` card path (`toast.body.isEmpty ? nil : toast.body`); D-4 says "the one place this rule lives" |
| MNT-2 | MNT | major | Two toast expiry mechanisms (list timers and `PVToast.autoDismissAfter`) | To user → Fix now → F-1 | user (2026-11-22): "One mechanism now"; supersedes the plan's Out line "One expiry mechanism for the single cards left … not planned" |
| UX-1 | UX | minor | "Bridge saved" goes to the window's stack under the still-open chained bridge dialog | To user → Rejected (keep D-11) | user (2026-11-22): "Keep window stack"; Landed note records it; manual check 4 confirms the card can be read at Regular width |
| CON-2 (+ SEC/PRF note) | CON | minor | `PVToastStack` always draws its column; D-7 says no entries draws no container | Fix now → F-4 | verified `PVToastStack.swift` body; keep code (the last card's leave animation needs the mounted column), fix doc comment and Landed note |
| CON-3 | CON | minor | Five ACs rest on the unrun manual check §10 | To user (finish) | manual check is the user's, in the report |
| CON-4 | CON | minor | T-8 still passes if `dismiss` does nothing | Fix now → F-3 | verified by trace: a refresh keeps count 1 |
| MNT-3 (+ UX-2) | MNT | minor | Kit stack hard-codes `workspace.toasts`; the id lands on every card | Fix now → F-5 | verified `PVToastStack.swift:31`; the column is not an accessibility element |

Nits (logged): `MNT-4 · CatalogCountsTests.swift:62,69,88,113 · repeated PVToastList(sleep: ManualSleep().sleep)` · `MNT-5 · VocabularyToastTests.swift:6 · use ManualSleep` · `MNT-6 · VocabularyChrome.swift:50-54 · doc comment leads with the card path` · `MNT-7 · WorkspaceSession.swift:61-62 · "outside a sheet"` · `CON-5 · CatalogCountsTests.swift:600 · refreshAllSuccessAddsNoToast starts from a failure toast`

User answers (2026-11-22): MNT-2 "One mechanism now"; UX-1 "Keep window stack".

### Fix plan 1

**F-1 — One toast expiry mechanism: every toast host owns a `PVToastList` and draws a `PVToastStack`** (from MNT-2, MNT-1; supersedes the plan's Out line "One expiry mechanism for the single cards left … not planned" and the README sentence on the split)
Files: `macos/App/DesignSystem/Components/Panel/PVSheet.swift`, `macos/App/DesignSystem/Components/Toast/PVToast.swift`, `PVToastList.swift`, `PVToastStack.swift`, `macos/App/Features/CatalogVocabulary/VocabularyChrome.swift`, `macos/App/Features/Onboarding/OnboardingView.swift`, `macos/App/DesignSystem/README.md`, `macos/ProvenenciaTests/PVToastTests.swift`. Skill: `add-ui-component`.
Failing test first: none new for the view wiring (no test can host a sheet); T-1..T-7 must stay green.
Do:
- `PVSheetChrome` owns `@State private var toasts = PVToastList()`, sets `.environment(\.pvToastList, toasts)` (replacing `nil`) and overlays `PVToastStack(list: toasts)` on its content, so a toast raised inside a sheet joins the sheet's own stack, top-trailing in the sheet.
- `VocabularyToastOverlay` keeps only the forwarding branch; the `card(_:)` path and its `toast.body.isEmpty ? nil : toast.body` go, so the empty-to-nil rule lives only in `PVToastList.add` (D-4). If no list is in the environment the binding is left as is (`assertionFailure` in debug). Prove with `rg -n "vocabularyToastOverlay" macos/App` that each of the callers sits under `WorkspaceView`'s `.environment(\.pvToastList, …)` or inside a `.pvSheet`.
- `OnboardingView` owns `@State private var toasts = PVToastList()`. On `.onChange(of: model.error?.localizedDescription, initial: true)` with a non-nil error it adds `tone: toastTone(for:)`, `message: error.localizedDescription`, then sets `model.error = nil`; it overlays `PVToastStack(list: toasts)` with the identifier `onboarding.toasts` (see F-5) in place of the `PVToast` card. Its `.animation(… value: model.error…)` goes. Before changing, `rg -n "\.error\b" macos/App/Features/Onboarding macos/ProvenenciaTests macos/ProvenenciaUITests` — if anything other than this toast reads `model.error` (a disabled button, a test, a UI test on `onboarding.error`), **stop and report**; do not rework those readers.
- `PVToast` loses `autoDismissAfter`, `defaultAutoDismissDelay`, `autoDismiss(after:onDismiss:)` and its `.task` timer; it only draws, announces and calls `onDismiss`. `PVToastList.lifetime` becomes `.seconds(5)` with the comment it had. `PVToastStack` drops `autoDismissAfter: nil`. `PVToastTests`' two `autoDismiss` tests go (T-1..T-6 cover expiry). The `#Preview` loses `autoDismissAfter:`.
- README Toast row: every toast host (the workspace window, each sheet, Onboarding) owns one `PVToastList` and draws one `PVToastStack`; `PVToast` has no timer. Drop "one-caller kit piece".
- Plan Landed note: the Out line was superseded by the user's call on MNT-2 (2026-11-22); a sheet's toast now stacks in the sheet; Onboarding's error toast moves to a list.
Check: `rg -n "autoDismiss|defaultAutoDismissDelay|isEmpty \? nil" macos` prints only `PVToastList.swift`'s normalization lines; scripts/check-pr.sh PASS.

**F-2 — A test that a saved bridge reaches the window's list** (from CON-1)
Files: `macos/ProvenenciaTests/CitationComposerModelTests.swift`, plan Landed note.
Failing test first: `CitationComposerModelTests/savingABridgeAddsItsToastToTheWindowList` — the test in CON-1 (connect model, `term-witness`, `saveAuthoring()`, then one `.success` entry titled `L10n.string(L10n.CitationComposer.bridgeSavedTitle)` in `fresh.session.toasts.entries`). Run it red by commenting out the `session.toasts.add` call, then restore.
Do: add the test beside `pendingConnectionOnNewAndExisting`, reusing `makeModel`/`seedArtifact`. Landed note: §8's "no test saves a bridge" was wrong; AC-3.1's list half is now tested. Also record UX-1: the user kept the bridge toast in the window's stack while the chained dialog is open (2026-11-22).
Check: the test passes; scripts/check-pr.sh PASS.

**F-3 — T-8 proves the dismiss** (from CON-4)
Files: `macos/ProvenenciaTests/CatalogCountsTests.swift`.
Failing test first: n/a (strengthens T-8).
Do: in `writeRecountFailureAddsToastEachTime`, save `let first = toasts.entries[0].id` before the dismiss; after the dismiss `#expect(toasts.entries.isEmpty)`; after the next failure `#expect(toasts.entries[0].id != first)`.
Check: test passes; scripts/check-pr.sh PASS.

**F-4 — `PVToastStack`'s doc comment and Landed note match the mounted column** (from CON-2, SEC/PRF note)
Files: `PVToastStack.swift`, plan Landed note.
Do: no code change. Doc comment: "With no entries it shows nothing; the column stays mounted so the last card's leave animation runs, and with no background or content shape it catches no click." Landed note line recording the D-7 difference and why.
Check: scripts/check-pr.sh PASS.

**F-5 — The stack takes its accessibility identifier, on the column** (from MNT-3, UX-2)
Files: `PVToastStack.swift`, `macos/App/Features/Workspace/WorkspaceContent.swift`, `PVSheet.swift`, `OnboardingView.swift`.
Do: `PVToastStack(list:identifier:)`; the column gets `.accessibilityElement(children: .contain)` then `.accessibilityIdentifier(identifier)`. `WorkspaceContent` passes `"workspace.toasts"` (D-7's id stays); `PVSheetChrome` passes `"sheet.toasts"`; `OnboardingView` passes `"onboarding.toasts"`.
Check: `rg -n 'accessibilityIdentifier\("workspace' macos/App/DesignSystem` empty; scripts/check-pr.sh PASS.

Ride-along nits in files F-1..F-5 touch (cheap; do them): MNT-4 (the four tests use `makeCounts`' default list or one shared helper), MNT-5 (`VocabularyToastTests` uses `ManualSleep`), MNT-6 (`vocabularyToastOverlay`'s doc comment now describes forwarding only), MNT-7 (`WorkspaceSession` comment: "outside a sheet"), CON-5 (`refreshAllSuccessAddsNoToast` starts from an empty list).


## Round 1 — fix
Head `032ae951a`. Gate PASS (orchestrator run). F-1 done (`PVToastTests.swift` deleted, both tests were `autoDismiss`); F-2 done (red with the add disabled, then green); F-3, F-4, F-5 done; nits MNT-4, MNT-5, MNT-6, CON-5 done. MNT-7 not applied: implementer looked at lines 61-62; the text is at `WorkspaceSession.swift:12` ("Every toast the workspace raises joins this one list") and is now less true, since sheets own lists — logged.
Minors read by the orchestrator: CON-2 **Resolved** (doc comment, Landed note); CON-4 **Resolved** (`first` id, empty after dismiss, new id after); MNT-3 + UX-2 **Resolved** (`identifier:` parameter, `.accessibilityElement(children: .contain)` on the column).
New nit (logged): `PVToastStack.swift` `onDismiss: { list.dismiss(entry.id) }                )` — stray spacing before `)`.

## Round 2 — review
Reviewers: CON (CON-1 major), MNT (MNT-1, MNT-2 major), UX (no round-1 major, but F-1 adds new visible behavior — a sheet's and Onboarding's toasts now stack — that UX has not seen). Skipped: SEC+PRF (no round-1 finding; F-1 adds no input, count or catalog path). Scope `d998b278f...032ae951a`.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | major | (round 1) AC-3.1 test | **Resolved** | `CitationComposerModelTests.savingABridgeAddsItsToastToTheWindowList`; fails without `session.toasts.add` |
| MNT-1 | MNT | major | (round 1) one empty-to-nil rule | **Resolved** | rule only at `PVToastList.swift:36-37`; card path gone |
| MNT-2 | MNT | major | (round 1) one expiry mechanism | **Resolved** | `PVToast` has no timer; only `PVToastStack` draws `PVToast`; three hosts own lists |
| CON-6 / MNT r2 note / UX-3 | CON, MNT, UX | minor | `vocabularyToastOverlay`'s `identifier` is no longer read; ten callers pass dead ids | Later PR → S16-59 | round 2 adds blockers only; S16-59 removes the overlay. Written into the S16-59 map scope entry ("goes with its unused `identifier` parameter") |
| MNT-7 | MNT | nit | `WorkspaceSession.swift:12` "Every toast … joins this one list" | Later PR → S16-59 | same map scope entry |

Nits (logged): `UX-4 · OnboardingView.swift:45 · Onboarding's card now sits at space8, not space6 — check in manual §10` · `PVToastStack.swift:26 · stray spacing before )` (round-1 fix note).

No blocker. No Fix plan 2.
S16-59's map scope entry also updated for the MNT-2 decision: a sheet owns its list, so the overlay goes everywhere and Onboarding's toast is no longer "Not this PR".

## Result
Merged `origin/main` (`1e3faa67d`); gate PASS. CI pending at ready · open: none · follow-ups: none (round-2 leftovers went to S16-59) · to user: MNT-2 (answered: one mechanism now), UX-1 (answered: keep window stack); manual check §10 owed.

## Round 3 — user dogfood (2026-11-22)
Manual check 1 with likenesses from two Sources: never more than two cards. Cause: D-4 merged any equal toast, and the portrait toast's body is the Source title, so choices from one Source were one card. User's call: merging is opt-in; every add makes a card; only the failed recount merges. Working rule, `stacked-toasts.md`, the plan's Objective, US-2 and D-4 amended (commit "Make merging a repeat toast opt-in").

User, follow-up (2026-11-22): comparing toasts by text is the wrong way to find a repeat. A toast has an id; `add` returns it, and a caller manages its ids as it needs. F-6 (opt-in `mergesRepeat`) was stopped before any commit; the working rule, `stacked-toasts.md`, the plan's US-2, AC-2.2, D-4 and D-10 amended again (commit "Toasts carry ids that callers hold"). AC-2.2 now reads: a failure with a different message keeps the recount's one card, with the new message (orchestrator's call under the user's "callers decide").

### Fix plan 3
**F-6 — `add` returns the card's id; a caller refreshes its own card by id; no text comparison** (from user dogfood)
Files: `macos/App/DesignSystem/Components/Toast/PVToastList.swift`, `macos/App/Features/Catalog/CatalogCounts.swift`, `macos/App/Features/CatalogVocabulary/VocabularyPane.swift` (the `add(_ toast:)` forward), `macos/ProvenenciaTests/PVToastListTests.swift`, `macos/ProvenenciaTests/CatalogCountsTests.swift`, `macos/App/DesignSystem/README.md`, `docs/deployment-plan/spike-16/completed.md`, the plan's §8 rows T-3, T-5, T-6, T-8 and its Landed note.
Failing test first: `PVToastListTests/equalAddsMakeTwoCards` *(new)* — add (success, "Portrait updated", "Register") twice → 2 entries, different ids, two sleeps started. Red today.
Do:
- `@discardableResult func add(tone:title:message:replacing: PVToastEntry.ID? = nil) -> PVToastEntry.ID` as D-4 says. Normalize empty to nil; if `replacing` is listed, replace that entry in place with a new `PVToastEntry(id: same, …new text)`, move it to index 0, restart its timer; else insert a new entry. Return the id. Delete the equal-entry search. Update the type's doc comment.
- `add(_ toast: VocabularyToast)` returns the id too (`@discardableResult`), no `replacing`.
- `CatalogCounts`: `private var failureToastID: PVToastEntry.ID?`; on failure `failureToastID = toasts.add(tone: .danger, title: …, message: …, replacing: failureToastID)`. Update `refreshAll`'s doc comment ("the same failure again refreshes the recount's own card").
- Tests: T-3 becomes `replacingMovesToTopKeepsIdAndRestartsTimer` (add A, add B, add C replacing A's id → `[A', B]` with A's id and C's text, three sleeps; A's first sleep fires → still there; its third fires → gone). T-5 becomes `replacingAGoneIdAddsANewCard` (add A, dismiss A, add replacing A's id → one entry, new id). T-6 becomes `emptyTitleOrMessageIsNone` ((info, "Filed", "") → `message == nil`). Add `equalAddsMakeTwoCards`. T-8: keep the same-failure refresh and dismiss checks; add a failure with a different message (a second error type) → still one entry, its message the new one, same id (AC-2.2).
- README Toast row: "`add` returns the card's id; a caller that passes it back as `replacing` refreshes that card; the list never compares text". `completed.md` S16-58 paragraph and the Landed note: the dogfood finding and the id design. §8 rows to match.
Check: `rg -n "replacing:" macos/App` prints only `PVToastList.swift` and `CatalogCounts.swift`; `rg -n "\.tone == tone|\.message == message" macos/App/DesignSystem` prints nothing; the new test red before, green after; scripts/check-pr.sh PASS.
