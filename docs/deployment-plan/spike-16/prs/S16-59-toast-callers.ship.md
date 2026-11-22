# Ship log — S16-59 Workspace callers add to the toast stack

**Plan:** [`S16-59-toast-callers.md`](S16-59-toast-callers.md) · **Branch:** `s16-59-toast-callers` · **PR:** #945
**State:** ready

## Round 0 — implement
Head `797eed0dc`. Gate PASS (orchestrator run). Report deviations: `\.pvSheetToasts` rename landed in the STEP-6 commit, not STEP-7; STEP-3 also converted `SourceTypePageModel.keepEditing`; some assertions read `cards.first?.title`/`.message` instead of whole cards; 5 residual DoD-sweep hits in `deployment-plan.md` scope entries left as history; `PromoteModel` body ternary ends in `nil`. Manual checks not run (need the app).

## Round 1 — review
Base `843619048` · Head `797eed0dc`.
Reviewers: CON, MNT, UX (`macos/App/**`), SEC+PRF (`macos/App/Features/**` models — performance path; the toast list is uncapped by Decision). Skipped: none.

UX reviewer (first dispatch) returned without reading the diff (2 tool calls; its report says "Not checked"). Its UX-1 named `macos/App/Features/Sources/WindowToastList.swift`, which does not exist. Re-dispatched a fresh UX reviewer; its findings replace this one's.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| UX-1 (void dispatch) | UX | major | Notices not announced after move to the window list | Rejected | Each card in a `PVToastStack` is a `PVToast`, which announces itself through `.pvAnnounce` (`PVToast.swift:96`); the named file does not exist; reviewer read no code |

SEC+PRF: no findings, no nits. Clean (one `PVToastList.add` per action; nine `onChange` forwards removed; attached filename still drawn through `Text(String)`).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | major | `stacked-toasts.md:18` still says `WorkspaceView` puts the window's list in the environment | Fix now → F-1 | verified: line 18 at head; the `WorkspaceView` diff deletes `.environment(\.pvToastList, session.toasts)` |
| MNT-4 | MNT | nit→minor | `PVToastList.swift:13` comment "The toasts of one window" while sheets and Onboarding own lists too | Fix now → F-2 | stale comment in a file this PR changes |

Nits (logged): `MNT-2 · ConclusionLeadModel.swift:70,74 · private computed toasts for (viewerToasts ?? session.toasts)` · `MNT-3 · CitationComposerModelTests.swift:917-919 · one cards == [ToastCard(...)] comparison`

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | major | Same as MNT-1 (also: a sheet surface does not add to the window's list) | Fix now → F-1 (dup of MNT-1) | verified with MNT-1 |
| CON-2 | CON | minor | `SourceTypePageModelTests` :374, :429 add twice but read `cards.first` (D-9) | Fix now → F-3 | verified: lines 374, 429 at head; D-9 "A test that adds twice compares the whole list" |
| CON-3 | CON | minor | No test for AC-2.4 with the viewer open | Fix now → F-4 | verified: `setPreferredLikenessError` set once (:389), no `viewerOpened` in that test |
| CON-4 + MNT-3 | CON, MNT | nit→minor | `CitationComposerModelTests.swift:916-919` field-by-field, against D-9 | Fix now → F-3 | two lenses; D-9 names this suite; file changed by this PR |

UX (re-dispatch):

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| UX-1 | UX | minor | "Connect is unavailable" can show on a page the researcher already left | Fix now → F-5 | verified: `EvidenceGraphModel.prepare()` adds after seven `readyValue` waits (`:254-267`); `readyValue` (`WorkspaceSession.swift:108-122`) never checks cancellation; the card names no graph, so §11 Risk row 1's premise ("nothing reads wrong out of its page") does not hold for it. A load-time error, not a researcher action, so the Reach row's intended timing change is for saves |
| UX-2 | UX | nit→minor | `ConclusionDetailPage.swift:191-192` comment broken after "so the" | Fix now → F-2 | stale comment in a file this PR changes |

### Fix plan 1

**F-1 — `stacked-toasts.md` says where the window's list lives** (from MNT-1, CON-1)
Files: `docs/deployment-plan/spike-16/stacked-toasts.md`.
Do: on line 18, replace "(an `@Observable` model, named in S16-58's plan, put in the environment by `WorkspaceView`)" with "(`WorkspaceSession.toasts`, drawn by `WorkspaceContent`)", and "Every workspace surface adds to it" with "Every workspace surface outside a sheet adds to it".
Check: `rg -n "environment by|put in the environment" docs/deployment-plan/spike-16/stacked-toasts.md` prints nothing; scripts/check-pr.sh PASS.

**F-2 — Two stale comments** (from MNT-4, UX-2)
Files: `macos/App/DesignSystem/Components/Toast/PVToastList.swift`, `macos/App/Features/Conclusions/ConclusionDetailPage.swift`.
Do: `PVToastList.swift:13`: "The toasts of one window" → "The toasts of one host (the workspace window, a sheet, or Onboarding)". `ConclusionDetailPage.swift:191-192`: rewrap the `lead` comment so the first line is not cut after "so the" ("The page owns it, so the model resets with the page …").
Check: scripts/check-pr.sh PASS.

**F-3 — Tests that add twice compare the whole list (D-9)** (from CON-2, CON-4, MNT-3)
Files: `macos/ProvenenciaTests/SourceTypePageModelTests.swift`, `macos/ProvenenciaTests/CitationComposerModelTests.swift`. Skill: `add-swift-test`.
Do: `assigningAppendsTheFieldAndUpdatesTheListCount` (:374): compare `session.toasts.cards` to the full list of two `ToastCard`s (newest first) with the titles and bodies each assign produces. `aFieldCanSitInTwoLists` (:429): `#expect(session.toasts.cards == [ToastCard(.info, removedTitle, removedBody), ToastCard(.success, assignedTitle, assignedBody)])` with the real L10n values. `CitationComposerModelTests.swift:916-919`: replace the count/tone/title checks with one `cards == [ToastCard(.success, title, message)]`, the message from `CitationComposerModel+Authoring.swift:675`. Also sweep the other `cards.first` reads in `SourceTypePageModelTests` (:404, :547-549, :563, :751): any test that adds more than once compares the whole list; a single-add test may keep its read.
Check: the tests pass; scripts/check-pr.sh PASS.

**F-4 — AC-2.4 with the viewer open** (from CON-3)
Files: `macos/ProvenenciaTests/PersonDetailTests.swift`. Skill: `add-swift-test`.
Failing test first: none (coverage for existing behavior); add `portraitFailureWithTheViewerOpenToastsInTheViewer`.
Do: as `portraitFailureToastsTheError` (:389), but call `model.viewerOpened(toasts: sheet)` (shape as :305) before the write; expect `sheet.cards == [ToastCard(.danger, …)]` with the same values the existing test expects, and `session.toasts.cards.isEmpty`.
Check: the test passes; scripts/check-pr.sh PASS.

**F-5 — A graph left while loading adds no load error** (from UX-1)
Files: `macos/App/Features/EvidenceGraph/EvidenceGraphModel.swift`, `macos/ProvenenciaTests/EvidenceGraphModelTests.swift`. Skill: `add-swift-test`.
Failing test first: `EvidenceGraphModelTests.aGraphLeftWhileLoadingAddsNoConnectRulesToast` — with the connect-rules read failing, run `prepare()` in a `Task`, cancel it before the reads finish, await it, and expect `session.toasts.cards.isEmpty`. If the fake store cannot hold a read open long enough to cancel before it finishes, cancel the task before it starts (a cancelled task's `prepare()` still runs to the add today), and say so in the report.
Do: in `prepare()`, add `guard !Task.isCancelled else { return }` after the last `readyValue` wait and before the connect-rules add. Leave `toggleConnect`'s add alone (a researcher action on the page).
Check: the test fails before the guard and passes after; scripts/check-pr.sh PASS.

## Round 1 — fix
Head `7feb71d33`. Gate PASS (orchestrator run). F-1 to F-5 done. Deviations: the composer test pins list size, tone and title but takes the message from the card (the fake store gives no cheap way to derive the bridge reading and ref); the other `cards.first` reads in `SourceTypePageModelTests` are single-add tests and stay; F-5's test cancels before `prepare()` starts (failed red first, then green).
Minors read by the orchestrator: F-2 (MNT-4, UX-2) **Resolved**. F-5 (UX-1) **Resolved**: the guard also skips `disarmCiteTools()` and `takeOpeningSubject()` on a cancelled run; `.task` with no id is cancelled only when the view goes, and a re-run `prepare()` on return still takes the opening Subject (`openingSubjectID` is kept), so nothing is lost. F-4 (CON-3) and F-3 (CON-2, CON-4/MNT-3) go to the CON round-2 reviewer with its scope.

## Round 2 — review
Scope `797eed0dc...7feb71d33`. Reviewers: CON (CON-1 major), MNT (MNT-1 major). Not sent: UX, SEC+PRF (no Fix-now blocker or major).

MNT round 2: MNT-1 **Resolved** (`stacked-toasts.md:18` now names `WorkspaceSession.toasts`, drawn by `WorkspaceContent`, matching `WorkspaceContent.swift:34`). No new blockers. MNT-3 (via F-3) **Resolved in part**: the composer test pins count, tone and title; its message slot is taken from the card, so it checks nothing (recorded deviation).

CON round 2: CON-1 **Resolved**. F-4 (CON-3) **Resolved** (`PersonDetailTests.swift:396-407`). F-3 (CON-2) **Resolved** in `SourceTypePageModelTests` (:374-379, :434-443, whole two-card lists, newest first); CON-4 **Resolved in part** (same composer-test gap MNT noted). F-5 checked for regressions: none. No new blockers.

## Result
Gate PASS (`7feb71d33`; `origin/main` unchanged since the branch was cut) · CI pending · open: none · follow-ups: none · to user: — · logged nits: MNT-2. Known gap (minor, recorded): `CitationComposerModelTests.swift:917-919` does not check the bridge toast's message.
