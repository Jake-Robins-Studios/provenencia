# Ship log — S16-50 One kit popup presenter, and the kit menus use it

**Plan:** [`S16-50-popup-presenter.md`](S16-50-popup-presenter.md) · **Branch:** `s16-50-popup-presenter` · **PR:** #923
**State:** ready

## Round 0 — implement
Head `239caa600`. Gate PASS (orchestrator run). Report: STEP-3 and STEP-4 in one commit (removing `keyboardTitles` broke callers until STEP-4); `moveIndex` gives `edge` a default of nil for D-17's call. Owed: §10 manual check (live watcher, opening press, Clear arm timing, app-switch close) — not unit-testable per D-21.

## Round 1 — review
Base `7b0bcd2a6`, head `239caa600`.
Reviewers: CON, MNT, UX (`macos/App/**`), SEC+PRF (list code in `PVList`/`PVSelectSession`, a global event monitor in `PVPopup`). Skipped: none.

Dispatch notes: CON reviewer #1 was refused its first (chained) command and returned no review; re-dispatched fresh. UX reviewer #1's report cites files that do not exist (`macos/App/DesignKit/Sources/PVPopupPresenter.swift`, `PVMenuButton.swift`, `PVSplitButton.swift`, `PVColorPicker.swift`, `PVPopupPresenterTests`) after two tool calls; discarded as unfounded and re-dispatched fresh. Its UX-1 (trigger click reopens the menu) checked against the head anyway: Refuted — `PVPopupDecision.decide` passes a left mouse-down, and a left mouse-up close runs on `DispatchQueue.main.async` after the trigger's toggle (`PVPopup.swift:106-108`, `:225-228`).

SEC+PRF: no findings (verdict Clean). Spot-checked: `isArming` guard, `disarm()`/`deinit` in `PVPopup.swift`; per-row watcher on `SourcesListView.swift:296-300` is an idle NSView until its menu opens.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| UX-1 | UX | blocker | A tap or fast click on a `PVSelect` can close the list on its own opening release | **To user** | Verifier: Confirmed. `PVSelectClickCatcherView.mouseDown` opens on the press with no tracking loop (`PVSelect.swift:547-550`); `arm()` samples live `NSEvent.pressedMouseButtons` one main-queue turn later (`PVPopup.swift` ~181); a queued `leftMouseUp` then hits `decide` with the flag false and `inside == false` → `.close`. D-8 removed `PVSelect`'s mouse-up opt-out and rests on D-5 alone. The fix (tie the opening press to the opening event's `eventNumber`) changes D-5's mechanism, so it is the user's call |
| CON-1, UX-2 | CON, UX | major | §10 manual check not run; AC-2.2–AC-2.8 and two Stop conditions rest on it | **To user** | The live watcher is not unit-testable (D-21); the user runs §10 at hand-off. Add tap-to-click and fast-click variants to steps 2 and 5 (from UX-1) |
| CON-2, MNT-1 | CON, MNT | minor | `add-ui-component` says "new in this PR" | Fix now → F-2 | `.agents/skills/add-ui-component/SKILL.md:94`, read |
| MNT-2 | MNT | minor | `keysStayInField` checked again in `PVContextMenuPresenter.handleKey` | Fix now → F-3 | `PVContextMenu.swift:465`; `decide` already returns `.pass` and `arm()` leaves `.keyDown` out of the mask |
| MNT-3 | MNT | minor | The type-select keystroke guard is written out in `PVPopup`, `PVTable`, `PVSelect` | Fix now → F-4 (same-pass cleanup) | Read all three at head; `PVSelect.swift:321-323` lacks the ⌘/⌃ check. This PR changes all three files |
| UX-1 (reviewer #1) | UX | major | Trigger click reopens the menu | Rejected | Fabricated paths; refuted at `PVPopup.swift:106-108`, `:225-228` (above) |

Nits (logged): `MNT-4 · PVActionMenu.swift PVActionMenuModifier.body · seed builds L10n titles only to test nil; use items.contains(where: \.isEnabled)` · `MNT-5 · PVContextMenu.swift:43 · applyTypeSelect's Bool unused; @discardableResult or fold` · `MNT-6/CON-3 · PVContextMenuTests.swift:180 · extra blank line` · `CON-4 · PVFloatingMenuSelectionTests.swift:104 · T-4 split into typeSelectCharacters; note in Landed deviations`

**State: paused — UX-1 To user.**

**User, 2026-11-20, on UX-1:** "Amend D-5, fix now". D-5 amended in the plan (row text marked *Amended 2026-11-20*). UX-1 → Fix now → F-1.

### Fix plan 1

**F-1 — The release of the press that opened a popup never closes it, even when the button is already up at arm time** (from UX-1; D-5 as amended)
Files: `macos/App/DesignSystem/Components/Popup/PVPopup.swift`, `macos/ProvenenciaTests/PVPopupTests.swift`.
Failing test first: `PVPopupOpeningPressTests` (new suite in `PVPopupTests.swift`), built like the existing `PVPopupInput` tests with `NSEvent.mouseEvent(…, eventNumber:, …)`:
- `queuedReleaseOfTheOpeningPressEndsIt` — opening event = left mouse-down #7, pressed buttons 0 at arm; a left mouse-up #7 is the opening release (today: not pending → `.close`).
- `anotherReleaseIsNotTheOpeningRelease` — same opening #7; a left mouse-up #8 is not the opening release, and #7 after it no longer matters once ended.
- `noRecordedPressFallsBackToHeldButtons` — no opening event, pressed buttons ≠ 0: the next mouse-up of any button is the opening release, once; pressed buttons 0: none is.
- `aMouseUpOpeningIsNotRecorded` — opening event = left mouse-up (the Clear button opens on release): nothing recorded; falls back as above.
Do: add one small pure value type in `PVPopup.swift` (for example `struct PVPopupOpeningPress { init(openingEvent: NSEvent?, pressedMouseButtons: Int); mutating func endsOpeningPress(_ event: NSEvent) -> Bool }`) that holds the recorded mouse-down `eventNumber` or the fallback flag. In `PVPopupWatcherView.sync()`, when it starts arming (presented, `monitor == nil`, not arming), capture `NSApp.currentEvent`; in `arm()`, build the opening press from it and `NSEvent.pressedMouseButtons` instead of setting `openingPressPending` directly. In `handle(_:)`, for a mouse-up, ask the opening press whether this event ends it and pass that as `decide`'s `openingPressPending` argument; `decide` and its T-1 table stay unchanged (pure). `disarm()` clears it. Update the D-5 comments in the file to the amended rule. Do not touch `WorkspaceToolbar` / `OmnibarResultsHost` `armDismissMonitor` (S16-52, S16-53).
Check: the four tests pass, `PVPopupDecisionTests.decidesEveryRow` unchanged and green; scripts/check-pr.sh PASS.

**F-2 — The skill text does not say "new in this PR"** (from CON-2, MNT-1)
Files: `.agents/skills/add-ui-component/SKILL.md:94`.
Do: drop ", new in this PR" so it reads "(`Components/Popup/PVPopup.swift`)". Same wording fix wherever STEP-5 copied it (`rg -n "new in this PR" .agents .cursor macos/App/DesignSystem/README.md` prints nothing after).
Check: that `rg` prints nothing; check-pr PASS.

**F-3 — "Keys stay in the field" is decided once** (from MNT-2)
Files: `macos/App/DesignSystem/Components/ContextMenu/PVContextMenu.swift:465`.
Do: `guard let keyboard else { return .ignored }`; `PVPopupDecision.decide` and `arm()`'s mask own the rule.
Check: `rg -n "keysStayInField" macos/App/DesignSystem/Components/ContextMenu/PVContextMenu.swift` shows only the parameter, stored property and the `PVPopupOptions(keysStayInField:)` hand-off; existing tests green.

**F-4 — One type-select keystroke test** (from MNT-3; same-pass cleanup)
Files: `macos/App/DesignSystem/Components/FloatingMenuSelection/PVFloatingMenuSelection.swift` (`PVTypeSelectMatcher`), `Popup/PVPopup.swift` (`PVPopupInput.keyEquivalent`), `Table/PVTable.swift:429-433`, `Select/PVSelect.swift:321-323`, `macos/ProvenenciaTests/PVFloatingMenuSelectionTests.swift`.
Failing test first: `PVFloatingMenuSelectionTests.typeSelectCharacterFromAKeyPress` — `"a"` no modifiers → `a`; `"a"` with command → nil; with control → nil; `"ab"` → nil; `""`/nil → nil; `" "` → nil.
Do: add `static func typeSelectCharacter(_ characters: String?, command: Bool, control: Bool) -> Character?` beside `isTypeSelectCharacter` (one char, `isTypeSelectCharacter`, neither modifier). Call it in one line from all three sites. `PVSelect.handleTriggerKey` thereby gains the ⌘/⌃ exclusion the others have (a ⌘-letter on a focused select no longer type-selects; note in the plan's Landed deviations). Keep `isTypeSelectCharacter` if `PVContextMenu.swift:75` still needs it.
Check: `rg -n "isTypeSelectCharacter\(" macos/App` prints only the definition, the new helper's body, and `PVContextMenu.swift` (~75); `rg -n "characters.count == 1" macos/App/DesignSystem` prints nothing; tests green; check-pr PASS.

Riding along (nits, optional in this round): MNT-4 (`items.contains(where: \.isEnabled)`), MNT-6/CON-3 (blank line), CON-4 (Landed note line). Add F-1's D-5 amendment and F-4's ⌘/⌃ change to the plan's Landed note.

**§10 additions for the user (CON-1, UX-2):** steps 2 and 5 also with trackpad tap-to-click and a fast click.

## Round 1 — fix
Head `812b27584`. Gate PASS (orchestrator run). F-1 to F-4 done; nits MNT-4, MNT-5, MNT-6/CON-3, CON-4 done. Failing tests failed first as compile errors (new types). F-4's `characters.count == 1` grep prints one line, inside the new helper — expected.
Orchestrator read of the minor fixes (`a467adee6..812b27584`): CON-2/MNT-1 **Resolved** (`SKILL.md:94`); MNT-2 **Resolved** (`PVContextMenu.swift:466`); MNT-3 **Resolved** (`PVTable`, `PVSelect`, `PVPopupInput` each call `PVTypeSelectMatcher.typeSelectCharacter`).

## Round 2 — review
Scope `239caa600...812b27584`. Reviewers: UX (had the blocker UX-1). Not sent: CON (its major CON-1 is To user, no fix), MNT (minors only, resolved above), SEC+PRF (no findings).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| UX-1 | UX | blocker | (round 1) opening release closes a `PVSelect` | Resolved | `PVPopup.swift:122-138`, `:204`, `:217-219`, `:248-255`; matching by `eventNumber` per `CGEventTypes.h` `kCGMouseEventNumber`. Open assumption (`NSApp.currentEvent` is still the mouse-down when `isPresented` arrives) goes to §10 steps 2 and 5 |
| UX-r2-1 | UX (outside lens → CON) | minor | Landed note claims F-4 changed `PVSelect`'s ⌘/⌃ behavior | Fix now (orchestrator, docs) | `PVSelect.swift:302-304` already returned `.ignored` for ⌘/⌃; Landed note corrected |

No new blockers. Verdict: Clean.

## Result
Gate PASS · CI pending · open: none in code · to user: CON-1/UX-2 §10 manual check (with tap-to-click and fast-click on steps 2 and 5) · follow-ups: none
