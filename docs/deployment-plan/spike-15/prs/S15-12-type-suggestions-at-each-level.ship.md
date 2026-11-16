# Ship log — S15-12 Source types suggest fields at each level

**Plan:** [`S15-12-type-suggestions-at-each-level.md`](S15-12-type-suggestions-at-each-level.md) · **Branch:** `s15-12-type-suggestions-at-each-level` · **PR:** #856
**State:** ready

Base `04e76c424` (main). Review log's one To user item (M-2 option a, a kit sub-level header) stays as recommended: not now; the plan takes option b and S15-17 asks the kit question.

## Round 0 — implement
Head `c2de4d768`. Gate PASS (orchestrator run). Report deviations: VERSION was 0.15.6, bumped to 0.16.0; STEP-4 copy ran before STEP-3 model (one commit for copy, model, view, tests); `listLabel` is a plural substitution; two `PVComboBox` previews moved to `level(.source).pickerLabel`; two extra accessibility ids (`…poolEmpty`, `…hint`); extra test `aFailedListOffersNoAdd`; the handler test assigns its graph field in the request builder. Not run in the app: AC-1.2, AC-1.4, AC-2.5, AC-2.6 focus return (D-10 stop condition), AC-3.1 column, board comparison.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. Skipped: none (diff touches `macos/App/**`, `Localizable.xcstrings`, `core/database/**`, `macos/App/Features/**` models).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1, UX-2 | CON, UX | major | Return in a cleared or retyped picker adds the earlier, hidden pick | Follow-up (user, 2026-11-15) | Verified: `PVComboBox` sets `selection` only in `commit` (`PVComboBox.swift:631`); Return with no active row returns `.ignored` (`:683`), so the list's `.onSubmit` → `submitPick` → `canAssign` sees the old pick. Each fix goes past the plan (§11 stop on a kit change, or AC-2.6 becomes one Return). User chose to defer |
| MNT-1 | MNT | major | List header copies the composer's `stepper` header | Fix now → F-1 | Same-pass cleanup: verified the two blocks match (`rg 'frame\(height: 20\)' macos/App` = these two). Supersedes D-6's deferral and review-log M-2 (b); no researcher-visible change |
| UX-1 | UX | major | Focus return after Return-add rests on one `Task.yield` | Fix now → F-2 | Verified `submitPick` (`SourceTypeSuggestionList.swift:246-252`); picker is disabled while `suggestionWrite != nil`; precedent defers (`MetadataBoardView.swift:158`) |
| CON-2 | CON | major | Manual check §10 not run (AC-2.6 focus, AC-1.4, AC-2.5, board) | To user | Manual check is the user's at finish (ship-pr step 8); listed in the report with the D-10 stop condition |
| UX-3 (+ CON outside-lens) | UX | minor | Group's spoken label says "0 fields" while loading or failed | Fix now → F-3 | Verified: label passes `suggestions.count` with no `isLoaded(at:)` gate |
| MNT-2 | MNT | minor | `suggestedFieldCountOverride` is no longer an override | Fix now → F-4 | Verified `FakeStore.swift:1177` reads only the dictionary |
| CON-3 | CON | minor | Three page-model count assertions no longer prove the patch | Fix now → F-5 | Verified: same scripted value fills the row and the reply |
| CON outside-lens (intro copy) | UX | — | List intro says "a source of this type", hint now "a record" | Rejected | Hint copy is the board's (§ 2.1); the list intro is S15-48's and names the type's Sources, which is right on that page |

Nits (logged): `MNT-3 · SourceTypeSuggestionList.swift:223 · model predicate for write in flight` · `MNT-4 · SourceTypePageModel.swift:20-24 · drop unused fieldID` · `MNT-5 · SourceTypeSuggestionList.swift · private modifier for micro italic muted` · `MNT-6/CON-4 · engine.proto:341-342 · rewrap comment` · `MNT-7 · source_defs_test.go:542 · len(listSuggestions)` · `UX-4 · SourceTypeSuggestionList.swift:251 · focus lost when the last pool field is added` · `UX-5 · L10n.swift suggestedHint · "record" overlaps the Source list's meaning (board copy)`

### Fix plan 1

**F-1 — Promote the micro-caps header row to the kit** (from MNT-1)
Files: new `macos/App/DesignSystem/Components/SubsectionHeader/PVSubsectionHeader.swift` (+ `project.pbxproj`), `macos/App/Features/SourceTypes/SourceTypeSuggestionList.swift` (`header`), `macos/App/Features/CitationComposer/CitationComposerEvidenceColumn.swift` (`stepper(eyebrow:position:control:)`). Skill: `add-ui-component`.
Do: one agnostic view taking a title, an optional trailing mono meta string, and a content slot below: `VStack(spacing: PVSpacing.space2)` holding `HStack(spacing: PVSpacing.space4)` of `.pvMicroCaps()` `textSecondary` title, `Spacer(minLength: 0)`, `PVFont.mono(size: 11)` `textMuted` meta, `.frame(height: 20)`, then the content. Move both callers onto it with no visual change (keep each caller's accessibility ids and labels); delete both private copies. Add a preview. Supersedes plan D-6's "snowflake" and the review log's M-2 (b); write that in the plan's Landed note.
Check: `rg -n 'frame\(height: 20\)' macos/App` prints only the new component's line; `rg -n 'func stepper' macos/App` prints nothing; scripts/check-pr.sh PASS.

**F-2 — Return focus to the picker when it is enabled again** (from UX-1)
Files: `SourceTypeSuggestionList.swift`.
Do: `submitPick` sets a private `@State` flag (refocus pending) instead of `Task.yield()` + `focus = .picker`. An `.onChange(of: model.suggestionWrite)` that sees it go to `nil` with the flag set clears the flag and sets `focus = .picker` (only when the level's pool is not empty, so focus never lands on a disabled picker).
Check: no `Task.yield` left in the file; scripts/check-pr.sh PASS.

**F-3 — Spoken list label without a count until loaded** (from UX-3)
Files: `SourceTypeSuggestionList.swift`.
Do: when `!model.isLoaded(at: level)`, the group's `accessibilityLabel` is `L10n.string(copy.title)` alone, matching the visible header; otherwise unchanged.
Check: scripts/check-pr.sh PASS.

**F-4 — Rename the fake's scripted count** (from MNT-2)
Files: `macos/App/Platform/FakeStore.swift` and every seeding site (tests, `SourceTypePageView.swift` and `SourceTypesView.swift` previews).
Do: `suggestedFieldCountOverride` → `suggestedFieldCounts`; doc comment says it is the scripted engine count (D-7).
Check: `rg -n suggestedFieldCountOverride macos` prints nothing; scripts/check-pr.sh PASS.

**F-5 — Make the count assertions prove the reply patch** (from CON-3)
Files: `macos/ProvenenciaTests/SourceTypePageModelTests.swift` (`assigningAppendsTheFieldAndUpdatesTheListCount`, `fieldsColumnShowsTheEnginesCountNotTheReplyLength`, `removingASuggestionKeepsTheFieldInThePool`).
Failing test first: none (test-only change); confirm each assertion fails with the count patch in `typeSuggestionCount()` commented out, then restore it.
Do: seed one count, warm, change `store.suggestedFieldCounts["t1"]` to the post-write value, write, assert the row shows the new value.
Check: scripts/check-pr.sh PASS.

## Round 1 — fix
Head `dd3df7842`. Gate PASS (orchestrator run). F-1 – F-5 done. Deviations: no `project.pbxproj` edit (synchronized group); `macos/App/DesignSystem/README.md` gains a `SubsectionHeader` row (guidance-names); `PVSubsectionHeader` marks its title `.isHeader`, which the composer's eyebrow lacked before.
Minors read by the orchestrator: F-3 **Resolved** (label is the title alone until `isLoaded(at:)`); F-4 **Resolved** (`suggestedFieldCounts`, no old name left); F-5 **Resolved** (each test asserts the seeded count, then scripts the post-write count before the write).

## Round 2 — review
Reviewers: MNT (MNT-1), UX (UX-1). Scope `c2de4d768...dd3df7842`. Not sent: CON (no Fix-now blocker or major), SEC+PRF (clean).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | major | (round 1) header copy | Resolved | `PVSubsectionHeader` in the kit; `rg 'frame\(height: 20\)' macos/App` prints only it; `func stepper` gone |
| UX-1 | UX | major | (round 1) focus after Return-add | Resolved | `refocusPending` + `.onChange(of: model.suggestionWrite)`; no `Task.yield` left |

No new findings. Both reviewers noted, outside the lenses, that the composer's Artifact and Citation eyebrows now carry `.isHeader` (VoiceOver announces them as headings; nothing visible changes). Kept: an improvement, recorded in the PR body.

## Finish
Merged `origin/main` (`bca068ca3`, S16 docs only). Gate PASS against `bca068ca3`.

## Result
Gate PASS · CI pending · open: none · follow-ups: CON-1/UX-2 (stale pick on Return) · to user: CON-2 (plan § 10 manual check, incl. the D-10 focus stop condition)
