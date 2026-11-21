# Ship log — S16-52 The omnibar's results use the kit popup list

**Plan:** [`S16-52-omnibar-popup-list.md`](S16-52-omnibar-popup-list.md) · **Branch:** `s16-52-omnibar-popup-list` · **PR:** #932
**State:** ready

## Round 0 — implement
Head `29c208673`. Gate PASS (orchestrator run). PR #932 (draft).
Report deviations: `PromoteModelTests` reads `search.line` (STEP-4 did not name it); `WorkspaceContent` lost its unused `WorkspaceNavigation` environment and `coordinateSpace` is `nonisolated`; one extra test (`aFailedSearchIsTheMappedMessageNotNoMatches`); STEP-2 and STEP-3 in one commit; first six commits lack the Co-Authored-By trailer; plan Status written `Landed in [#932](…)` for check-plan-docs. In-app check of STEP-5 and §10 not run (owed before merge, plan §11 first stop condition; stated in the PR body).

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. Skipped: none. SEC+PRF routed for performance (`macos/App/Features/**` models, list code that measures rows); no security path touched.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| UX-1 | UX | major | After Tab leaves the omnibar, Escape no longer closes the results | To user | verified: base `OmnibarResultsHost.swift:54-59` installed an app-wide local monitor that took key code 53 whatever had focus; head's only Escape path is `.onKeyPress` on the field, and `.pvPopupList` passes `keysStayInField` (`PVPopup.swift:244`). Contradicts the plan's Out line "Tab away leaves them open, as today": the premise "as today" is false |
| CON-1, UX-2 | CON, UX | major | `onKeyPress` on the omnibar's `PVInput` reaching ↑/↓/Home/End/Page/keypad Enter is unverified (§11 stop condition); AC-1.x, AC-3.x and §10 not run | To user | Landed note says STEP-5's key check and §10 were not run. UX-2 also refutes §11's premise: `PVComboBox` attaches `onKeyPress` on its bare `TextField` (`PVComboBox.swift:352`), the omnibar on the whole `PVInput` |
| MNT-1 | MNT | major | Every popup list caller adds the card's padding to its height by hand; the omnibar spells `PVSpacing.space2` twice and copies the combo box's measured state | Fix now → F-1 | verified: `OmnibarResultsHost.swift:55,78`, `PVComboBox.swift:254-256,323-328`, `PVTextArea.swift:714`. Same-pass cleanup: this PR adds the third copy. A height helper and a measurement value keep D-11's "the caller keeps the height" |
| MNT-2 | MNT | minor | The omnibar decides alone which keys count as Return | Fix now → F-2 (combo box adoption To user) | verified: `rg 'u\{3\}' macos/App` hits only `OmnibarResultsModel.swift:73`; `PVComboBox.swift:564` matches `.return` only. Moving the combo box onto it makes keypad Enter commit a row, which a researcher can see |
| MNT-3 | MNT | minor | A third private builder for test search hits | Fix now → F-3 | same-pass cleanup: `SearchCatalogStoreTests.swift:9`, `CatalogSearchTests.swift:329`, `OmnibarResultsModelTests.swift:207` |
| MNT-4 | MNT | minor | The failed-search case is tested twice | Fix now → F-4 | both tests set `catalog.closed` and assert the same `line` |
| CON-2 | CON | minor | README ComboBox row credits `PVTextArea` with `PVPopupListMeasure`/`PVPopupListSearchingLine` and leaves out the omnibar | Fix now → F-5 | verified by `rg` in the finding |
| UX-3 | UX | minor | Hit rows lost their button trait for VoiceOver | Fix now → F-6 (omnibar call site) | base wrapped each hit in a `Button`; `PVPopupListRow` adds no `.isButton`. Kit-wide trait would change combo box options (list options, not buttons), so the call site only |
| SEC/PRF | SEC+PRF | — | No findings | — | hit list capped at 50 in Go (`search_catalog.go:23`) |

Nits (logged): `MNT-5 · PVPopupList.swift:222-226 · card doc names only PVComboBox` (rides on F-5) · `MNT-6 · PVPopupList.swift:146-147 · rewrap widened(to:) doc` (rides on F-5) · `MNT-7 · OmnibarResultsModel.swift:56,69,99 · isDisabled default` · `MNT-8 · WorkspaceToolbar.swift:28 · inline fittedPanelWidth at S16-53` · `CON-3 · first six commits lack Co-Authored-By` · `UX-4 · L10n.swift:1299 · comment still says "omnibar results panel"` (rides on F-5)

**User answers (2026-11-21):**
- UX-1: "Yes, close on blur" → Fix now, F-7. Supersedes the plan's Out line "Closing the results when the field loses focus by Tab".
- CON-1 / UX-2: "I tested it, and it works." → Resolved by the user's in-app check of STEP-5's keys (↑/↓, Home/End, Page, ⌘↑, keypad Enter; caret stays). The rest of §10 stays the user's manual check.
- MNT-2: combo box adoption accepted → F-2 covers `PVComboBox` too.

### Fix plan 1

**F-7 — Close the omnibar results when the field loses focus** (from UX-1)
Files: `macos/App/Features/Workspace/WorkspaceToolbar.swift` (or `OmnibarResultsHost.swift` if the focus is passed in), `macos/ProvenenciaTests/OmnibarResultsModelTests.swift` if a model method is added, the plan.
Failing test first: if the close goes through a new model entry point (e.g. `OmnibarResultsModel.fieldFocusChanged(_:)`), `OmnibarResultsModelTests.losingFocusClosesAndKeepsTheQuery` — open the list, lose focus, assert `!isPresented` and the query unchanged. If it is a one-line `.onChange` calling the existing `closePanel()`, no new test; say so in the report.
Do: `.onChange(of: omnibarFocused) { _, focused in if !focused { omnibarResults.closePanel() } }`, as `PVComboBox` does (`if !focused { closeAndRestore() }`). `closePanel()` keeps the query. Make sure a click on a hit row still opens the hit (the popup is its own window; if focus leaves the field before the row's tap lands, the close must not swallow the click — check `PVComboBox`'s order and match it). Plan: replace the Out line "Closing the results when the field loses focus by Tab — not planned: Tab away leaves them open, as today" with a line in Scope/Landed note saying the results close when the field loses focus (user, 2026-11-21, S16-52 review UX-1: the old app-wide Escape monitor is gone). Add a §10 manual line: Tab out of the omnibar with the list open → it closes, query stays.
Check: scripts/check-pr.sh PASS.

**F-1 — One kit height for a popup list, one measured-height value** (from MNT-1)
Files: `macos/App/DesignSystem/Components/PopupList/PVPopupList.swift`, `macos/App/DesignSystem/Components/ComboBox/PVComboBox.swift`, `macos/App/DesignSystem/Components/TextArea/PVTextArea.swift`, `macos/App/Features/Workspace/OmnibarResultsHost.swift`, `macos/App/DesignSystem/README.md` ("Sizing is the caller's job"), `macos/ProvenenciaTests/PVPopupListTests.swift`. Skill: `add-ui-component`.
Failing test first: `PVPopupListTests` `cardHeightAddsThePaddingTwice` — `PVPopupListCard.height(rows: 100, verticalPadding: 8) == 116`, and the default padding uses `PVPopupListCard.defaultVerticalPadding`.
Do: add `static let defaultVerticalPadding = PVSpacing.space2` and `static func height(rows: CGFloat, verticalPadding: CGFloat = defaultVerticalPadding) -> CGFloat` on `PVPopupListCard`; the card's `verticalPadding` default reads the constant. Add `struct PVPopupListMeasurement: Equatable { var height: CGFloat = 0; var isMeasured = false; mutating func record(_ h: CGFloat); mutating func reset() }`. `PVComboBox` (`measuredRowsHeight`/`rowsMeasured`, `listVerticalPadding`) and the omnibar (`measuredHeight`/`rowsMeasured`, both `PVSpacing.space2` spellings) hold one `@State var measurement: PVPopupListMeasurement`, pass `onHeight: { measurement.record($0) }`, reset with `measurement.reset()`, and compute `contentHeight` with `PVPopupListCard.height(rows:verticalPadding:)`. `PVTextAreaCompletionList.height` uses the same helper. The omnibar names no padding (uses the default) or one named constant used in both places.
Check: `rg -n "\* 2" macos/App/DesignSystem/Components/ComboBox macos/App/DesignSystem/Components/TextArea macos/App/Features/Workspace/OmnibarResultsHost.swift` prints no popup-height line; `rg -n "rowsMeasured|measuredRowsHeight|measuredHeight" macos/App` prints only `PVPopupListMeasurement`'s own lines; `PVComboBoxTests`, `PVTextAreaCompletionTests`, `PVPopupListTests` pass; scripts/check-pr.sh PASS.

**F-2 — One kit check for the commit key** (from MNT-2)
Files: `PVPopupList.swift`, `OmnibarResultsModel.swift`, `PVComboBox.swift`, `PVPopupListTests.swift`.
Failing test first: `PVPopupListTests` `returnAndKeypadEnterCommit` — `PVPopupListHighlight.isCommitKey(.return)` and `isCommitKey(KeyEquivalent("\u{3}"))` true; `.escape`, `.downArrow` false.
Do: add `static func isCommitKey(_ key: KeyEquivalent) -> Bool` beside `isMovementKey`. `OmnibarResultsModel.handleKey` and `PVComboBox.handleKey` use it in place of `case .return` / `case .return, KeyEquivalent("\u{3}")` (an `if isCommitKey` before the switch, or a `where` clause). User accepted keypad Enter committing a combo box row (2026-11-21). Add a `PVComboBoxTests` case if `handleKey` is reachable from tests; otherwise the kit test covers it.
Check: `rg 'u\{3\}' macos/App` prints only `PVPopupList.swift`; scripts/check-pr.sh PASS.

**F-3 — One shared test builder for search hits** (from MNT-3)
Files: new `macos/ProvenenciaTests/CatalogSearchHitFixture.swift` (add to the test target in `project.pbxproj`), `SearchCatalogStoreTests.swift`, `CatalogSearchTests.swift`, `OmnibarResultsModelTests.swift`, `PromoteModelTests.swift`. Skill: `add-swift-test`.
Do: `extension CatalogSearchHit { static func fixture(id:kind:…) -> CatalogSearchHit }` with defaults covering the three builders' parameters (`kind`, `id`, `iconKey`/lead, `location`). Delete `SearchCatalogStoreTests.hit(kind:id:)`, `CatalogSearchTests.leadHit(kind:iconKey:)`, `OmnibarResultsModelTests.hit(_:)`; move their callers and the inline `CatalogSearchHit(` literals in these four files onto it where a literal only sets fields the fixture takes.
Check: `rg -n "func .*-> CatalogSearchHit" macos/ProvenenciaTests` prints only the fixture; scripts/check-pr.sh PASS.

**F-4 — Test the failed search once** (from MNT-4)
Files: `OmnibarResultsModelTests.swift`.
Do: keep `CatalogSearchTests.aFailedSearchIsTheMappedMessageNotNoMatches`. Reduce `OmnibarResultsModelTests.searchFailureSurfacesMappedErrorNotEmpty` to what the omnibar owns (`isPresented` stays true on a failure); drop its `line` assertion and rename it (e.g. `aFailedSearchKeepsTheListOpen`).
Check: scripts/check-pr.sh PASS.

**F-5 — README and stale comments** (from CON-2, MNT-5, MNT-6, UX-4)
Files: `macos/App/DesignSystem/README.md:188`, `PVPopupList.swift:146-147, 222-226`, `macos/App/Platform/L10n.swift:1299`.
Do: README ComboBox row: the card, row and line are drawn by all three callers; `PVPopupListSearchingLine` and `PVPopupListMeasure` are `PVComboBox`'s and the omnibar's (as "Sizing is the caller's job" says). `PVPopupListCard` doc names the omnibar's results beside `PVComboBox`. Rewrap the `widened(to:)` doc line. `omnibarResultsAccessibilityLabel` comment: "the omnibar's results list" (comment only, not the string's English; if the xcstrings comment carries the same text, update it there too).
Check: scripts/check-pr.sh PASS (localizable, guidance-names).

**F-6 — Hit rows read as buttons to VoiceOver** (from UX-3)
Files: `OmnibarResultsHost.swift`.
Do: add `.accessibilityAddTraits(.isButton)` on the omnibar's `PVPopupListRow` (call site only; not in the kit).
Check: scripts/check-pr.sh PASS.

## Round 1 — fix
Head `503b37f97`. Gate PASS (orchestrator run). F-1 – F-7 done. F-1 and F-2 in one commit; F-4 rides in F-3's commit; F-7 added no test (one-line `.onChange` on the existing `closePanel()`, as the fix plan allowed). The implementer pushed from a detached HEAD (fast-forward); the orchestrator re-pointed the local branch at origin.
CON-2 (minor): read by the orchestrator in `README.md` — Resolved.

## Round 2 — review
Reviewers: MNT (MNT-1 major), UX (UX-1 major). Not sent back: CON (CON-1 resolved by the user's in-app check, CON-2 minor resolved above), SEC+PRF (no findings).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | major | (round 1) | Resolved | `PVPopupListCard.height(rows:)` and `defaultVerticalPadding` used by all three callers; `PVPopupListMeasurement` held by `PVComboBox` and the omnibar |
| UX-1 | UX | major | (round 1) | Resolved | `WorkspaceToolbar.swift:88-90` closes on blur; the popup panel cannot become key, so a hit click keeps the field's focus |

No new findings in round 2 (MNT, UX both Clean). Minors read by the orchestrator: MNT-2 (F-2) Resolved — `isCommitKey` is the only keypad literal; MNT-3 (F-3) Resolved — one fixture; MNT-4 (F-4) Resolved — `aFailedSearchKeepsTheListOpen` asserts only `isPresented`; UX-3 (F-6) Resolved — `.isButton` at the omnibar's row.

## Finish
`origin/main` moved (0774f6e8c: S15-22 docs only); merged at `edc6d835d`. Gate PASS against 0774f6e8c.

## Result
Gate PASS · CI green · open: none · follow-ups: none · to user: answered (UX-1 close on blur; CON-1/UX-2 keys verified in app by the user; MNT-2 keypad Enter in the combo box accepted). Owed before merge: the rest of plan §10 (the user's manual check), including Tab out of the omnibar.
