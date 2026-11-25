# Ship log — S16-72 Back returns to the scroll position

**Plan:** [`S16-72-scroll-offset-history.md`](S16-72-scroll-offset-history.md) · **Branch:** `s16-72-scroll-offset-history` · **PR:** [#973](https://github.com/Jake-Robins-Studios/provenencia/pull/973)
**State:** ready

## Round 0 — implement
Head `f4fe67b4c`. Gate PASS (orchestrator). Deviations: `connect(to:)` and `applyHistoryState(_:kind:)`; the y reads the clip view's inset; `SourcesTable.insetsItself`; two scroll-id helpers removed; `movedTo` in `PVNativeListBehavior`; T-6 uses a near graph (a far selected row draws selected only once drawn); a far Sources y can exceed the table's estimate and open at the top. Not checked by hand: the Timeline hand-off, Promote.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1, UX-1 | CON, UX | blocker | Selecting a row in Metadata or Properties throws the table to its top | Fix now → F-1 | two lenses; a selection there is a push on a mounted table |
| CON-2, UX-3, SEC+PRF notes | CON, UX | blocker | A reused scroll view is not put at the top, and a clamp cancels the restore | Fix now → F-2 | verified in `arm` and `bounds`; D-6's own sentence says the top |
| UX-2 | UX | blocker | A far y on a list whose document is still growing opens at the top | Fix now → F-2 | **user, 2026-11-25:** "no concept or opinion about the content … It's a scroll position": no height in the rule |
| CON-3 | CON | major | A y that did not fit stays armed and jumps later | Fix now → F-2 | user: no preference; orchestrator's choice, amends D-6 |
| UX-4 | UX | major | A remount mid-visit restores again | Fix now → F-2 | same; amends Edges "A remount mid-visit" |
| MNT-1 | MNT | major | `navigation-history.md` describes the deleted row anchors | Fix now → F-4 | the skill calls it authoritative |
| MNT-2 | MNT | major | The hand-kept encoder has no guard | Fix now → F-3 | verified: base had no `encode` |
| MNT-3 | MNT | major | `insetsItself` is a Bool for one caller | Fix now → F-3 | |
| MNT-4 (CON-6), 5, 6; CON-4 | MNT, CON | minor | Stale doc, the open Source beside the revisit, dead parameter and coding, a test that proves nothing | Fix now → F-3, F-4 | files this PR changes |
| MNT (outside lens) | CON | minor | A corrected Promote location loses its y | Rejected | D-7 says `replaceCurrent` is a push; it opens at the top, the user's fallback |

Nits: `MNT-7 – MNT-11`, `CON-5`, `CON-7` ride along in F-4.

### Fix plan 1
Binding (user, 2026-11-25): nothing in the scroll memory, its tests' rules or its docs knows rows, kinds or heights, and no height is tuned for it. Differences from the plan's Decisions go in the Landed note; do not edit the Decisions. One run per proof; no sleeps.

**F-1 — Selecting inside a page keeps its scroll** (CON-1, UX-1)
Files: `WorkspaceNavigation.swift`, `NavigationHistoryStore.swift`, `PlaceRegistry.swift` or `WorkspaceLocation.swift` (one rule), `PVTable.swift`, tests.
Failing tests first: `selectingARowThatIsAPlaceKeepsTheTablesY` (the finding, through the real navigation rule rather than by setting `arrival` by hand); navigation: Metadata field → field and Properties property → property of one category carry the live offsets into the new entry and start no new scroll visit; a category press and a Person section switch start clean; Back from field B to field A shows A's y.
Do: navigation decides, by one named rule on two locations ("the same page, another selection"), that a push carries the live offsets and keeps the arrival for the scroll. The kit learns nothing. The selection-with-arrival rule of `PVNativeListBehavior.movedTo` moves to one shared place that `PVTable` uses too.

**F-2 — One scroll rule: ask for the y until it lands, never after the researcher acts** (CON-2, CON-3, UX-2, UX-3, UX-4)
Files: `PVScrollMemory.swift`, `PVScrollMemoryTests.swift`, `PVScrollMemoryHostedTests.swift`, `SourcesOutlineHostedTests.swift`, `docs/ideas/source-page-followups.md`.
Do: on a new arrival the view goes to its top. With a y, it asks for y; the platform clamps; when the document grows, it asks again; done when it is at y. If a turn passes with no growth short of y, it is back at the top and waits, still armed, for the next growth (late rows). While armed nothing is noted and a clamp means nothing. The researcher's first scroll wheel, key or mouse press in the window ends it (a local `NSEvent` monitor held only while armed; tests call the coordinator's `input()`); from then on every bounds change is noted. Once per arrival and slot: a remount in the same arrival starts at the top and notes 0 (the memory records a slot as done). `layout` loses `currentY`.
Failing tests first: the two CON-2 tests; a document that grows only as it is scrolled (a lazy stack or table whose height is an estimate) with a y past its first height lands at y; growth after `input()` leaves y alone; a remount in the same arrival is at the top and the note is 0; T-6 takes back a deep case. A document that never grows enough ends at the top. Rewrite the T-1 table to this rule.
If a growing platform list cannot be brought to y without a visible jump to an intermediate position, say what is seen; if it never converges, stop and report. Correct the idea file: it must not say opening at the top was the user's answer for far Sources positions.

**F-3 — Simpler shapes** (MNT-2, 3, 5, 6)
`WorkspaceRevisit` codes itself flat (its own keys, lenient decode, encode) and `WorkspaceLocation` calls it; a test builds a location with every field set and asserts the encoded keys equal all `CodingKeys` of both. `insetsItself` goes: each caller pads, and `PVNativeListBehavior`'s doc says nothing may pad between it and the list. The held revisit carries `openSourceId`; `flush` calls the one private stamp; `handledArrival` goes. One finite-and-non-negative check; `PVScrollSlot` loses its unused `Codable`.

**F-4 — Docs, tests, nits** (MNT-1, 4, 7 – 11; CON-4, 5, 7)
Rewrite `navigation-history.md`'s three lines; `restartKey`'s doc; the nits as written. CON-4: host a section with a `sectionAnchor` and a remembered y, assert the y and the focused stop, the Timeline included (the plan's stop condition): if the Timeline card does not take the keyboard, stop and report.
Check: `scripts/check-pr.sh` PASS once.

## Round 1 — fix
Head `2a73612fe`. Gate PASS (orchestrator). F-1 to F-4 done; the Timeline row takes the keyboard (asserted only where full keyboard access is on). Asking for y alone did not converge on the platform table, so the probe steps a screen at a time in one turn; not timed by the implementer → PRF round 2 measures it. `onLocationCommit` passes the kind. Minors read in the diff by the orchestrator: pending round 2.

## Round 2 — review
Reviewers: CON, MNT, UX, SEC+PRF (new cost in F-2).

MNT, UX: **Clean**. Every round-1 blocker and major **Resolved** (CON-3 as the fix plan decided).

| ID | Severity | Title | Decision |
| --- | --- | --- | --- |
| CON-8 | blocker | Leaving a page while its restore is armed overwrites its y with 0 | Fix now → S-1 |
| PRF-1 | blocker | The drawing pass freezes the app: 12.6 s near the end of 3,000 rows, 44–47 s for an unreachable y | Fix now → S-1: the pass goes |

Nits: MNT-12, MNT-13 ride along. Logged: an AXPress does not count as input (UX).

**User (2026-11-25):** "implement the simplest version you can, and we will accept that the sources page may be a little buggy, and then we'll review it in practice … minimize the impact of this." Not planned now: keep-alive pages, a Sources table that reports its height.

### Fix plan 2
**S-1 — One y, set on arrival, top when it cannot**
Files: `PVScrollMemory.swift`, `WorkspaceRevisit.swift`, `WorkspaceNavigation.swift`, `WorkspaceLocation.swift`, their tests, the docs that name slots.
Do, deleting more than adding:
- The drawing pass, `show`, `reach` history and `landed` go. On arrival: to the top; when the remembered y fits what the view can show now, set it and be done; else stay at the top and check again only when the document or view changes size. The researcher's first wheel, key or press ends it.
- Ending it notes nothing (CON-8): only a bounds change while done notes. `leavingWhileTheRowsLoadKeepsTheEntrysY`, the finding's test, first.
- One scroll view per page: `PVScrollSlot`, `scrollOffsets`, `claimed` and `notedSlots` become one `scrollOffset: Double?` on the revisit (a plain optional number in the file, validated once), one "noted in this visit" flag, and a container that claims the memory hands its content nil. No second slot is kept for later.
- `PVScrollRestore` stays a value only if it is still the shortest way to test the rule; otherwise fold it in.
- Look through the whole diff against `d0d0049f1` for anything else that exists only for the removed parts or for a later use, and delete it. Report anything bigger you would cut that changes behavior; do not cut it.
- Tests: the deep T-6 becomes one near case, and one that a y past what the Sources table reports opens at the top; the estimated-document tests go. Keep each AC's test.
- `docs/ideas/source-page-followups.md`: a far Sources position opens at the top, accepted by the user to try in practice (2026-11-25), and the two ways out (keep the page alive; the table reports its height), no more. Landed note: what differs from D-4, D-6, D-8, D-9, in final-state words; not a history.
Check: every test one run; `scripts/check-pr.sh` PASS once. Report the diff size before and after against `d0d0049f1`.

## Round 2 — fix
Head `7df960a85`. Gate PASS (orchestrator). S-1 done: one `pending` y is the rule; `PVScrollMemory.swift` 377 → 257 lines; app +788 → +646; whole diff +1827 −552 → +1620 −552. Cases left out for less code: a remount notes nothing until it scrolls, and restores again if the researcher acted without scrolling; a y that does not fit can land later if the page grows before any input; an AXPress is not input.

Quick-lens review of `2a73612fe...7df960a85` (scope limited by the user's bar): **Clean**; CON-8 and PRF-1 **Resolved**; a page left at its exact bottom restores in every probed case. Nit logged: `QCK-1 · PVScrollMemory.swift · two lines restate AppKit's default`. MNT-12's line added by the orchestrator (skill doc); MNT-13's comment is gone.

## Result
Gate PASS · CI: on the PR · open: none · follow-ups: none (the far Sources note is in `docs/ideas/source-page-followups.md`, named by the plan) · to user: the manual check; a far Sources position opens at the top, to be judged in practice

## Cost
Plan: 6,114 words (check-plan-docs info line).

| Round | Agent | Model | Tokens |
| --- | --- | --- | --- |
| 0 | implementer | sonnet | 342k |
| 1 | SEC+PRF | opus | 93k |
| 1 | MNT | opus | 127k |
| 1 | UX | opus | 132k |
| 1 | CON | opus | 138k |
| 1 | implementer (fix) | opus | 356k |
| 2 | CON | opus | 123k |
| 2 | MNT | opus | 79k |
| 2 | UX | opus | 100k |
| 2 | SEC+PRF | opus | 87k |
| 2 | implementer (S-1) | opus | 200k |
| 2 | QCK review | opus | 69k |
| | **Total** | | **1,846k** |
