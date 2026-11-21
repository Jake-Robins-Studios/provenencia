# Ship log — S16-51 The combo box's list becomes a kit popup list

**Plan:** [`S16-51-popup-list.md`](S16-51-popup-list.md) · **Branch:** `s16-51-popup-list` · **PR:** #928
**State:** ready

## Round 0 — implement
Head `26536852b`. Gate PASS (orchestrator run against `7898cee50`). PR #928 (draft).
Report deviations: `PVPopupListWindow.Coordinator` keeps `shownWidth` (D-15's host has no frame accessor, so §6's read of the panel's frame width became a stored width); plan Status reworded to the form `check-plan-docs.py` accepts; one push went out before the gate passed (final head passes); §10 manual check not run.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. UX: `macos/App/**`. SEC+PRF: no security path matches; dispatched for the performance lens's list code (`PVList`, `PVPopupList`, the window host).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | major | A click away on AppKit controls that track the mouse (scroller drag, title-bar drag, native control tracking) no longer closes the combo list or the completion | Fix now → F-1 | verified: `addLocalMonitorForEvents` docs say the handler is not called for events a nested tracking loop consumes; `decide` passes every left press and closes only on a left release outside (`PVPopup.swift`), so a press that starts a tracking loop never closes. Base closed on the press. Fix in the presenter, so S16-50's menus gain it too |
| CON-2 | CON | major | §10 manual check not run | Rejected | ship-pr step 8: the user runs the manual check before merge; it is in the PR body and the report. No in-app pass is possible from the agents |
| PRF-1 | PRF | major | `PVPopupWindowHost.init` builds its `NSHostingView` up front, so every right-click-menu row, `PVSelect` and combo box holds one that is rarely shown (base built it on first `show()`) | To user → Fix now → F-4 (user, 2026-11-21: lazy) | verified: base `PVContextMenu.swift:553`, `PVPopupList.swift:128` lazy in `show()`, released in `tearDown()`; head `PVPopupWindowHost.swift:28` in `init`. Contradicts D-14 ("made in `init`") |
| MNT-1 | MNT | major | The completion session checks its highlight's bounds by hand in four places beside `PVPopupListHighlight.current(count:)` | Fix now → F-2 | verified: `PVTextArea.swift:621, 647, 670, 727`; D-5 "instead of a third … bounds check" |
| MNT-2 | MNT | minor | `shownWidth` copies the panel's frame width the host already owns | To user → Fix now → F-5 (user, 2026-11-21: add the accessor) | adding `frame` to the host's surface changes D-15 |
| MNT-3 | MNT | minor | "Highlight" names both the match mark and the active row | Rejected | D-5 fixed the type name and D-9 the session's `highlight` property |
| MNT-4 | MNT | minor | `add-ui-component` does not say a floating popup's window is a `PVPopupWindowHost` | Fix now → F-3 | the skill line this PR edits; `rg "NSPanel\|WindowHost" .agents/skills .cursor/rules` empty |

Nits (logged): `MNT-5 · PVPopup.swift:572 · onField vs onAnchor, one word` · `MNT-6 / CON-3 · PVPopup.swift pvPopup doc comment line overlong, rewrap` · `MNT-7 · PVContextMenu.swift:61 · key list repeats moveIndex's` · `MNT-8 · README.md:165-166 · move the popup list clause into the PopupList row` · `MNT-9 · PVPopupList.swift pvPopupList doc · "it" → "the field"` · `MNT-10 · PVPopupListTests.swift:8 · option/pool helpers copied (D-10)` · `CON-4 · README FloatingMenuSelection row wording`
Outside-lens notes: MNT on completion hover skipping disabled rows (UX: `PVPopupListRow.onHover` already skips them; no visible change) and the dropped `index != activeIndex` write guard (PRF: one Observation write per row entered on a short list); logged, no finding.
UX: no findings.

### Fix plan 1
The user answered PRF-1 and MNT-2 on 2026-11-21: F-4 and F-5 amend D-14 and D-15; record both in the plan's Landed note.

**F-1 — A press outside that a tracking loop swallows still closes the popup** (from CON-1)
Files: `macos/App/DesignSystem/Components/Popup/PVPopup.swift`, `macos/ProvenenciaTests/PVPopupTests.swift`. Skill: `add-swift-test`, `add-ui-component`.
Failing test first: `PVPopupDecisionTests.aPressWithNoReleaseClosesLikeARelease` — a new `PVPopupDecision` input for "a left press outside ended with no release seen" (for example an event case `.pressEndedUnseen` or an input flag; pick the smallest shape beside `aClickIsWhereItsPressBegan`) decides `.close` when the press began outside and not on the field, and `.pass` when the press began inside or on the field.
Do: in `PVPopupWatcherView`, when a left mouse-down outside passes (not on the field, not in the popup), record a pending outside press and queue `RunLoop.main.perform(inModes: [.default]) { … }`; that block runs only after any nested event-tracking loop (scroller drag, title-bar drag, control tracking) returns. In it, if the press is still pending and `NSEvent.pressedMouseButtons & 1 == 0`, ask `decide` with the new input and close as the release would. A left mouse-up clears the pending press; `disarm` resets it. The rule stays in `decide`. Applies to every `.pvPopup` caller (the combo box, the completion, S16-50's menus).
Check: the test passes; `PVPopupDecisionTests.decidesEveryRow` and `aClickIsWhereItsPressBegan` unchanged and pass; scripts/check-pr.sh PASS. Add a §10 manual line to the PR body: drag the page's scroller or the window's title bar with a combo box list open → the list closes on the release and the field shows its pick.

**F-2 — The completion session reads its highlight through `current(count:)`** (from MNT-1)
Files: `macos/App/DesignSystem/Components/TextArea/PVTextArea.swift`.
Do: replace the four hand checks (`rows.indices.contains(activeIndex)` in `evaluate`, `options.indices.contains(activeIndex)` in the `insertNewline:`/`insertTab:` branch, `options.indices.contains(highlight.index)` in `move`, and the `activeID:` expression in `PVTextAreaCompletionRows`) with `highlight.current(count:)`. Add `var currentIndex: Int? { highlight.current(count: options.count) }` to the session for the rows view. Keep `activeIndex` (D-9).
Check: `rg -n "indices.contains\((session\.)?activeIndex|indices.contains\(highlight.index" macos/App` prints nothing; `PVTextAreaCompletionTests` pass; scripts/check-pr.sh PASS.

**F-3 — `add-ui-component` names the window host** (from MNT-4)
Files: `.agents/skills/add-ui-component/SKILL.md`.
Do: add to the sentence this PR edited: every floating popup window is a `PVPopupWindowHost` (`Components/Popup/PVPopupWindowHost.swift`); do not subclass `NSPanel`.
Check: `scripts/check-guidance-names.py` passes.

**F-4 — The window host builds its hosting view on first use and releases it on tear-down** (from PRF-1; amends D-14)
Files: `macos/App/DesignSystem/Components/Popup/PVPopupWindowHost.swift`.
Do: make the hosting view optional, created on first access through a private accessor used by `rootView`, `fittingSize` and `show(at:)`/`makePanel`, and set to nil in `tearDown()` (as base did). `setContent` already returns early while not shown, so a closed popup never makes one. `init` builds nothing.
Check: `rg -n "PVPopupWindowHostingView\(" macos/App` shows the one creation site inside the accessor, not `init`; full tests pass; scripts/check-pr.sh PASS.

**F-5 — The host exposes its frame; `shownWidth` goes** (from MNT-2; amends D-15)
Files: `PVPopupWindowHost.swift`, `macos/App/DesignSystem/Components/PopupList/PVPopupList.swift`.
Do: add `var frame: CGRect? { get }` to `PVPopupWindowHost` (the panel's frame while shown, nil otherwise). `PVPopupListWindow.Coordinator.setContent` widens to `host.frame?.width`; remove `shownWidth` and its write in `frame()`. Update the plan's Landed note (the `shownWidth` deviation line becomes the D-15 amendment).
Check: `rg -n shownWidth macos` prints nothing; scripts/check-pr.sh PASS.

Riding nits (do them, they are in lines F-1 touches): rewrap the `pvPopup` doc comment line (MNT-6/CON-3); name `onField` and `onAnchor` with one word (MNT-5).

## Round 1 — fix
Head `2d28bb7e1`. Gate PASS (orchestrator run). F-1 to F-5 and the riding nits done. F-1's failing test was red by compile failure (`.pressEndedUnseen` did not exist). MNT-5 read as renaming the local `onField` to `anchorKeepsOpen`. Plan Landed note records the D-14 and D-15 amendments.
F-3 (MNT-4, minor): read by the orchestrator — **Resolved** (the skill line names `PVPopupWindowHost` and forbids subclassing `NSPanel`).

## Round 2 — review
Reviewers: CON (CON-1), MNT (MNT-1), SEC+PRF (PRF-1). Skipped: UX (no round-1 findings). Scope `26536852b...2d28bb7e1`.
CON-1: **Resolved** (`.pressEndedUnseen` in `decide`, `watchPress()` on `RunLoop.main.perform(inModes: [.default])`; `aPressWithNoReleaseClosesLikeARelease`). MNT-1: **Resolved** (`currentIndex`; the four hand checks gone). PRF-1: **Resolved** (hosting view lazy, released in `tearDown()`). MNT-2 (minor, F-5): **Resolved** (read by the orchestrator through the MNT and CON round-2 reports and `rg shownWidth`).
No new blockers. CON noted one manual risk, not a finding: a fast trackpad tap on a trigger that toggles its popup on release (the Citation Composer's Clear menu) might close then reopen it; added to the PR's manual check, with the reviewer's cheap guard (skip the queued close when a left mouse-up is already queued) if it reproduces.

Nits (logged): `CON-5 / MNT · PVPopup.swift:121 · .pressEndedUnseen's pressBeganInside branch is unreachable from the watcher (watchPress runs only for a press outside); the test's second assertion covers a case the app never sends`

## Finish
Merged `origin/main` @ `c0f5d7ba5` (docs only: S15-21 plan and S15-D9 brief). Gate PASS against `c0f5d7ba5`.

## Result
Gate PASS · CI pending · open: none · follow-ups: none · to user: PRF-1 and MNT-2, answered 2026-11-21 (lazy hosting view; host exposes `frame`) · manual check: the user's, before merge
