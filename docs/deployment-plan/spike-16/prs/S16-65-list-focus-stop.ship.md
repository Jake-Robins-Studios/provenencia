# Ship log — S16-65 One kit focus stop for a list of rows

**Plan:** [`S16-65-list-focus-stop.md`](S16-65-list-focus-stop.md) · **Branch:** `s16-65-list-focus-stop` · **PR:** #951
**State:** review 1 (re-plan)

## Round 0 — implement
Head `8d444edb1`. Gate PASS (orchestrator run against `a0923028f`). Report: the README's `kit-layering.md` link is `../../../docs/ideas/kit-layering.md` (the plan's `../../../../` does not resolve from `macos/App/DesignSystem/`); STEP-1's targeted `-only-testing` run and STEP-2's build were covered by check-pr's xcode-test and swift-warnings; §10 manual check not run (needs a window).

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. UX: the diff touches `macos/App/**` (kit list keyboard and focus ring). SEC+PRF: list code on the Persons list at the 16,000-row Scale (the performance path "list code"); no security path, but the combined reviewer reads both rubrics.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | major | `clampedIndex` is a second clamp beside `action`'s `.activate` clamp, and they disagree below 0 | Fix now → F-1 | verified: `PVList.swift:296` `min(index, max(0, count - 1))` vs `:346` `min(max(index, 0), count - 1)`. Same-pass cleanup: this PR adds the first copy. D-7's formula gains a lower bound; every T-1 case and every index `PVList` can hold (≥ 0) gives the same result, so no visible change |
| MNT-2 | MNT | minor | Each caller writes the focused-row ring expression by hand; S16-66 adds a third | Fix now → F-2 | verified: `PVList.swift:158` and the `PVListFocusStop.swift` preview. Same-pass cleanup: this PR adds both copies |
| CON-1 | CON | minor | The Landed note does not say §10 was not run | Fix now → F-3 | verified: plan line 5 vs PR #951 body; S16-39's Landed note is the precedent |
| SEC/PRF | SEC+PRF | — | No findings | — | — |
| UX | UX | — | No findings | — | §10 step 2 confirms the scroll modifier's move outside `pvListChrome` |

Nits (logged): `MNT-3 · macos/App/DesignSystem/README.md:192 · List row nests parentheses three deep` · `MNT-4 / CON-3 · PVList.swift:18 · rewrapped keyboard line runs past the doc comment's width` · `MNT-5 · PVListFocusStop.swift · preview repeats 30 three times` · `CON-2 · S16-65-list-focus-stop.md:4 · stray blank line between Status and Landed`

### Fix plan 1

**F-1 — One clamp for the focused index** (from MNT-1)
Files: `macos/App/DesignSystem/Components/List/PVList.swift`, `macos/ProvenenciaTests/PVListTests.swift`. Skill: `add-swift-test`.
Failing test first: `PVListTests/clampedIndexStaysInTheList` — add `(-1, count 3) → 0`.
Do: `PVListKeyboard.clampedIndex` becomes `min(max(index, 0), max(0, count - 1))`; its doc comment adds "and a negative one at 0". `action`'s `case .return, .space:` returns `.activate(clampedIndex(index, count: count))`. Keep the existing five T-1 cases. In the plan's Landed note, record that D-7's clamp gained a lower bound and `action`'s activate clamp now calls it (ship log MNT-1).
Check: `rg -n "min\(max\(index" macos/App/DesignSystem` prints only `clampedIndex`'s line; `PVListTests` pass; scripts/check-pr.sh PASS.

**F-2 — One rule for which row draws the ring** (from MNT-2)
Files: `PVList.swift`, `macos/App/DesignSystem/Components/List/PVListFocusStop.swift`, `PVListTests.swift`.
Failing test first: `PVListTests/isFocusedRowIsTheClampedRowWhileFocused` (new) — `(2, focusIndex 2, count 3, listFocused true) → true`; `(2, focusIndex 7, count 3, true) → true`; `(1, focusIndex 7, count 3, true) → false`; `(2, focusIndex 2, count 3, false) → false`.
Do: add `static func isFocusedRow(_ index: Int, focusIndex: Int, count: Int, listFocused: Bool) -> Bool` to `PVListKeyboard` = `listFocused && index == clampedIndex(focusIndex, count: count)`, doc comment "The row that draws the focus ring: the clamped focused row while the list holds focus." `PVList`'s row and the preview's row read `PVListRowStyle(focused: PVListKeyboard.isFocusedRow(…))`. The modifier's doc comment's last sentence points to `PVListKeyboard.isFocusedRow` instead of the spelled-out expression; same for the README List row's "draws its ring at `PVListKeyboard.clampedIndex`". Record in the Landed note.
Check: `rg -n "== PVListKeyboard.clampedIndex" macos/App` prints nothing; `PVListTests` pass; scripts/check-pr.sh PASS.

**F-3 — The Landed note says §10 is owed** (from CON-1)
Files: `docs/deployment-plan/spike-16/prs/S16-65-list-focus-stop.md`.
Do: add to the Landed note, as S16-39 does: "the §10 manual check was not run by the implementer (no UI session); the user runs steps 1–5 before merge."
Check: scripts/check-pr.sh PASS (plan-docs).

## Round 1 — fix
Head `c15277256` (code), `7e86b15e2` after the orchestrator's `completed.md` wording fix (it still said the ring is drawn at `clampedIndex`). Gate PASS. F-1, F-2, F-3 done in one commit (all touch `PVList.swift` or its plan). F-1 ran red first; F-2's test did not compile before `isFocusedRow`.
- MNT-2 (minor): **Resolved** — `PVList`'s row and the preview read `PVListKeyboard.isFocusedRow`; `rg "== PVListKeyboard.clampedIndex" macos/App` prints nothing; README and modifier doc point at it.
- CON-1 (minor): **Resolved** — the Landed note says §10 was not run and the user runs steps 1–5 before merge.
- MNT-1 (major): to round 2.

## Round 2 — review
Reviewers: MNT (MNT-1 was a Fix-now major). Scope `8d444edb1...7e86b15e2`. Not sent: CON (minor only, resolved above), UX and SEC+PRF (no findings).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | major | (round 1) second clamp | **Resolved** | one `clampedIndex`, called by `action`; `rg "min\(max\(index" macos/App/DesignSystem` finds only it; `(-1, 3) → 0` tested |

No new findings; no nits.

## Result
Gate PASS (`origin/main` still `a0923028f`, no merge needed) · CI see PR #951 · open: none · follow-ups: none · to user: — · owed: §10 manual check (steps 1–5) before merge

## Manual check (user, 2026-11-22)
§10 step 2 fails: past the window's bottom edge, every other ↓ scrolls the focused row into view and the next jumps the page back to the top; Page Up/Down and End do the same. The user ran `main` (`a0923028f`): same bounce, so not caused by this PR. Suspect: `ListScrollAnchorModifier`'s `.scrollPosition(id:anchor: .top)` pin on the page's `ScrollView` against `.pvScrollsRowIntoView`'s `scrollTo` (not verified). The user questions the design: Page Up/Down and Home/End scroll a page of plain text too, so they may belong to the scroll view, and only the focus ring and ↑/↓ to the list. Loop paused for that decision.

## Re-plan (2026-11-23)
The user moved Page Up/Down and Home/End from the list to the page's scroll view (content-agnostic, with nothing focused too) and split the bounce and the scroll memory into S16-67. A throwaway spike, run by the user, showed a SwiftUI `ScrollView` handles none of the page keys and that a responder after the window receives keys nothing handled. The temporary logging build (no app code scrolled to the top; the remembered row id never changed while arrowing) is recorded in S16-67's scope entry. The plan was rewritten in place and passed review-plan in two rounds (log: `S16-65-list-focus-stop.review.md`). The first round's commits (`.pvListFocusStop`, `clampedIndex`, `isFocusedRow`) stay on the branch as the new plan's base. The loop restarts at Round 0 with the implementer.

## Re-plan round 0 — implement
Head `eeb64049c`. Gate PASS (orchestrator, against `a0923028f`). Report: two commits, not three (STEP-4's doc comments rode in the first); `PVPageKeyResponder` and `PVPageKeys.scrollToEdge` are `@MainActor` (Swift 6 warned without it); doc wording on `PVListKeyboard.action` and `isSideList` is the implementer's; §10 not run (needs a window).

## Re-plan round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. UX: `macos/App/**`, keyboard behavior on every page. SEC+PRF: a responder that sees every unhandled key event in the window and walks a probe list per key, list and table code at the 16,000-row Scale.
