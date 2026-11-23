# Ship log — S16-67 The Persons, Events and Places lists are native lists

**Plan:** [`S16-67-native-conclusion-lists.md`](S16-67-native-conclusion-lists.md) · **Branch:** `s16-67-native-conclusion-lists` · **PR:** [#958](https://github.com/Jake-Robins-Studios/provenencia/pull/958)
**State:** stopped — PRF-1 is only partly resolved after round 2; the user decides on Fix plan 2

## Round 0 — implement
Base `3d8863a57`. Head `3c3db8c2c`. Gate PASS (orchestrator run; xcode-test 63s). Report deviations: version 0.35.0 → 0.36.0 (main moved); row content framed to 44 pt; row insets less the platform's 8 pt cell inset; T-1 compares drawn colors; live-app checks left to the manual check. STEP-2 was reported without its `PVDatePlaceLine.swift` change and without listing it (CON-1).

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. Skipped: none (diff touches `macos/App/**` and Features models).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1, MNT-1, UX-1 | CON, MNT, UX | blocker | A selected Events row keeps its muted date and place ink | Fix now → F-1 | verified: `PVDatePlaceLine.swift:72–98` has seven plain inks, not in the diff (D-4, STEP-2) |
| PRF-2 | PRF (outside-lens note, routed) | major | The loading skeleton takes 1,980 pt: the area's frame has no minimum, so nothing clips | Fix now → F-2 | verified: a flexible frame with no `minHeight` takes its child's height; the reviewer measured 2,060 pt against a 700 pt proposal |
| PRF-1 | PRF | major | A selection move builds thousands of rows at 16,000 | Fix now → F-3 (row as a view). Its scroll-only-on-appear part Rejected | measured 76 → 32 ms, 8,925 → 13 builds. The probe shows no gain from the scroll part, and D-7 prescribes the modifier with no token; the change scroll is also what shows the row on a jump between two entries of one list. Live held-↓ at 16,000 is added to the manual check |
| CON-2 | CON | minor | A jump between two entries of the same list never checks the new anchor | Fix now → F-4 (the clear). Scrolling to the top on such a jump: Follow-up | code trace holds; the clear keeps D-7's one job |
| CON-3 | CON | minor | `<root>.list` sits on a plain `VStack` | Fix now → F-5 | pattern at `OnboardingChooseFileView.swift:34` |
| ORC-1 | CON | minor | Separators start at the title, where the board insets them to the gutter on both sides | Fix now → F-6 | Landed note; brief Board line; macOS 13+ offers both separator alignment guides |
| MNT-4 | MNT | minor | `listAnchor` doc "Only the Conclusion list body reads it" is untrue | Fix now → F-4 | `ListSelectionAnchorModifier` reads it |
| CON-4, CON-5 | CON | minor | Docs placed elsewhere than STEP-9 says | Fix now → F-7 | `completed.md` order, § 9 sentence after rule 3 |
| UX-2 | UX | minor | Late rows take the caret out of the omnibar | To user | contradicts D-6's unconditional claim |
| MNT-2 | MNT | minor | D-5's Home/End handler may duplicate the platform's | To user | contradicts D-5 and the working rule; unproven in the app and on macOS 14 |
| MNT-3 | MNT | minor | `density` / `.compact` have no app caller | Rejected | D-1 names `density` and the `horizontalInset` default among what is kept |

Nits (logged): `MNT-5, CON-6 · PVColor.swift:280, SourcesListRow.swift:291 · doubled blank line`

Security: clean.

### Fix plan 1
**F-1 — A selected Events row's date and place take the on-selection ink** (from CON-1, MNT-1, UX-1)
Files: `macos/App/DesignSystem/Components/DatePlaceLine/PVDatePlaceLine.swift`, `macos/ProvenenciaTests/PVListTests.swift`.
Failing test first: `PVListTests/datePlaceLineTakesTheOnSelectionInk`, `@MainActor`:
```swift
func png(_ prominence: BackgroundProminence) throws -> Data {
    let view = PVDatePlaceLine(date: "1851", place: "Lyon, France", accessibilityLabel: "",
                               missing: .omitted, dateTone: PVColor.textMuted)
        .padding(4).background(Color.blue)
        .environment(\.backgroundProminence, prominence)
    let image = try #require(ImageRenderer(content: view).nsImage)
    return try #require(image.tiffRepresentation)
}
#expect(try png(.increased) != png(.standard))
```
If `ImageRenderer` ignores the injected prominence or hangs the run, use a hosted `NSHostingView` bitmap; keep a test that fails without the change.
Do: wrap every `foregroundStyle` in `PVDatePlaceLine.body`, `dateTone` included, in `PVColor.onSelection`. `PVBadge` keeps its own.
Check: test red then green; `rg -n "foregroundStyle\(" macos/App/DesignSystem/Components/DatePlaceLine/PVDatePlaceLine.swift` prints only `onSelection` lines.

**F-2 — The loading rows clip to the list area** (from PRF-2)
Files: `macos/App/Features/Conclusions/ConclusionListPage.swift`, `macos/ProvenenciaTests/PersonsListTests.swift`.
Failing test first: `PersonsListTests/loadingAreaFitsTheListArea`, `@MainActor`: `NSHostingController(rootView: ConclusionListPage<PersonsList>.loadingArea(gutter: 32)).sizeThatFits(in: CGSize(width: 1000, height: 700)).height` is 700 (1,980 today).
Do: `minHeight: 0` on the `loadingArea` frame.
Check: test red then green.

**F-3 — A selection move does not rebuild the rows** (from PRF-1)
Files: `macos/App/DesignSystem/Components/List/PVList.swift`.
Do: move `row(_:)` into a private `PVListRow` view struct holding the item and the slots, so the `ForEach` closure builds only a value and SwiftUI builds a row's content only for rows on screen. Keep the row modifiers (insets, separators) and accessibility on it as today; nothing a researcher sees changes. Leave both `pvScrollsRowIntoView` calls.
Check: no `row(` function left; tests pass. Add to §10 step 3: "Hold ↓ from row ~8,000: the selection keeps up. Double-click row ~8,000, then Back: the row shows without a visible stall."

**F-4 — A history jump within one list clears a vanished row** (from CON-2, MNT-4)
Files: `macos/App/Features/Workspace/WorkspaceNavigation.swift`.
Do: `ListSelectionAnchorModifier` also calls `clearIfGone()` in `.onChange(of: navigation.listAnchor)`; it still writes only when the resolved anchor differs. Correct `listAnchor`'s doc: its view readers are the Conclusion list and its modifier.
Check: builds; `WorkspaceNavigationTests` pass.

**F-5 — The list page is an accessibility container** (from CON-3)
Files: `macos/App/Features/Conclusions/ConclusionListPage.swift`.
Do: `.accessibilityElement(children: .contain)` before `ConclusionListFrame`'s identifier.
Check: builds.

**F-6 — Row separators run gutter to gutter** (from ORC-1)
Files: `macos/App/DesignSystem/Components/List/PVList.swift`, the plan's Landed note.
Do: on the row content, `.alignmentGuide(.listRowSeparatorLeading) { _ in 0 }` and `.alignmentGuide(.listRowSeparatorTrailing) { $0.width }`, so the hairline starts at the thumbnail's leading edge and ends at the ref's trailing edge. Prove with a throwaway hosted bitmap; if the trailing guide has no effect keep the leading one only (the plan's Out line). Update the D-12 line in the Landed note and PR body.
Check: hairline x-range reported.

**F-7 — Docs where STEP-9 puts them** (from CON-4, CON-5)
Files: `docs/deployment-plan/spike-16/completed.md` (if its intro says newest first, move the entry accordingly), `docs/macos-client-patterns.md` (the sentence after rule 3), plan Landed note (STEP-2's `PVDatePlaceLine` and these fixes), PR body.
Check: `python3 scripts/check-plan-docs.py`; scripts/check-pr.sh PASS.

## Round 1 — fix
Head `d2120d0fa`. Gate PASS (orchestrator run; xcode-test 49s). F-1 to F-7 done (F-1, F-2 tests red first; F-2 and F-5 share commit `eb17f6b2a`). F-3's check did not rerun the timing probe.
Minors read by the orchestrator: CON-2, CON-3, MNT-4 Resolved in the diff; ORC-1 Resolved (reported hairline x 16–582 of 600 pt, not re-run here); CON-4, CON-5 Resolved (read by the CON reviewer).

## Round 2 — review
Reviewers: CON, MNT, UX, SEC+PRF. Scope `3c3db8c2c...d2120d0fa`. No new blockers.
- CON-1 / MNT-1 / UX-1: Resolved. PRF-2: Resolved.
- PRF-1 (major): **partly resolved → To user.** The three row modifiers still sit in the `ForEach` closure, so it runs for 8,919 rows per selection move. Probe (a model of `PVList`, not the app), median per mid-list move at 16,000: 169 ms before F-3, 102 ms now, 63 ms with the modifiers on the `ForEach`, 65 ms with none. Dropping the selection scroll: 102 → 80 ms; this replaces the round-1 evidence that rejected that part, so that question is reopened too (D-7). First jump to row 8,000: about 0.8 s.
- Not a round-2 blocker, so no Fix plan 2 runs without the user.

### Fix plan 2 (proposed, needs the user)
**F-8 — A selection move runs no row modifiers for rows off screen** (from PRF-1)
Files: `macos/App/DesignSystem/Components/List/PVList.swift`.
Do: move `.listRowInsets`, `.listRowSeparator`, `.listRowSeparatorTint` onto the `ForEach`, before `.transaction`; if 66 pt rows, the gutters or the separators change in the hosted bitmap, put them at the end of `PVListRow.body` instead. Correct the `PVListRow` doc.
Check: hosted bitmap as F-6 (66 pt rows, hairline gutter to gutter); the probe's closure count; scripts/check-pr.sh PASS.

## Result
Gate PASS · CI not run (draft) · open: PRF-1 (major) · to user: PRF-1, UX-2, MNT-2 · follow-up: CON-2's scroll to the top on a jump between two entries of one list
