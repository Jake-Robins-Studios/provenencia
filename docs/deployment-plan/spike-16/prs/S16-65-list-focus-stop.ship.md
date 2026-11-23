# Ship log — S16-65 One kit focus stop for a list of rows

**Plan:** [`S16-65-list-focus-stop.md`](S16-65-list-focus-stop.md) · **Branch:** `s16-65-list-focus-stop` · **PR:** #951
**State:** fixing 1

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
