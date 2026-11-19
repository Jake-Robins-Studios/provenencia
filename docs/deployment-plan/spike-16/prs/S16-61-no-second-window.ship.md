# Ship log — S16-61 Nothing in the app waits on a second window

**Plan:** [`S16-61-no-second-window.md`](S16-61-no-second-window.md) · **Branch:** `s16-61-no-second-window` · **PR:** [#886](https://github.com/Jake-Robins-Studios/provenencia/pull/886)
**State:** ready

## Round 0 — implement
Base `de9921e0b`. Head `3cdb843bf`. Gate PASS (orchestrator run; xcode-test 59s). Report: deviations none.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. Skipped: none (diff touches `macos/App/**`, `Localizable.xcstrings`, and Features models).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| UX-1 | UX | major | The reworded notice says "board", a word no other on-screen string uses | To user → answered, Fix now → F-2 (user, 2026-11-18: "Film number is now suggested by this type."; no second sentence, the cleared picker already asks for a pick) | verified: `rg 'defaultValue: "…board…"' L10n.swift` hits only 6750; the area is headed "Metadata" (6698) and the field lands under "Suggested by this type" (6781). Contradicts D-5's copy |
| CON-1, MNT-1, UX-2 | CON, MNT, UX | minor | `L10n.swift:9892` doc comment still says "deleted or merged elsewhere" | Fix now → F-1 | verified: `rg elsewhere L10n.swift`; STEP-5's pattern missed "merged elsewhere" |

Nits (logged): `CON-2 · Localizable.xcstrings:21010–21160 · substitutions re-indented by re-serialization` · `CON-3 · SourcePageModelTests.swift:179–182 · T-1 compares English copy (plan asked for it)` · `MNT-2 · ArtifactSheetModel.swift:173–175 · guard let graphIDs instead of the double nil check` · `MNT-3 · SourcePageModelTests.swift:128,148 · Census type literal twice; censusType() fixture` · `UX-3 · MetadataBoardModel.swift:11 · reflow the takenFieldLabel doc comment`

SEC+PRF: clean, no findings (the engine refuses unknown or other-Source graph ids, `artifacts_test.go:154–187`).

### Fix plan 1
**F-1 — The record-page gone line's doc comment names no other place** (from CON-1, MNT-1, UX-2)
Files: `macos/App/Platform/L10n.swift`.
Do: line 9892 reads "/// The line a record page leaves with when its record was deleted or merged." (drop "elsewhere").
Check: `rg -n "merged elsewhere|deleted elsewhere" macos core` finds nothing; scripts/check-pr.sh PASS.

**F-2 — The taken notice says the field is now suggested by the type** (from UX-1, user answer)
Files: `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `macos/ProvenenciaTests/SourcePageModelTests.swift`, `docs/deployment-plan/spike-16/prs/S16-61-no-second-window.md`. Skill: `add-localized-string`.
Failing test first: `typeChangeClearsTheAddRowsTakenField` — change its copy assertion to `"Film number is now suggested by this type."`; it fails.
Do: `sources.page.metadataAddRowFieldTaken` (same key) English becomes "%@ is now suggested by this type." in the `L10n` `defaultValue` and the catalog value; its comment is unchanged. In the plan, add to the Landed note: "D-5 copy changed in review (UX-1, user 2026-11-18): \"%@ is now suggested by this type.\"" and update §10 Manual check step 2's quoted text to "‹Field› is now suggested by this type.". Do not edit D-5 itself.
Check: the test passes; `rg -n "on the board" macos` finds nothing; scripts/check-pr.sh PASS.

## Round 1 — fix
Head `0761030aa`. Gate PASS (orchestrator run; xcode-test 56s). F-1 done (`81eca7ba5`); F-2 done (`0761030aa`, test red first). F-2's check `rg "on the board" macos` was too broad: the four remaining hits are code, test and translator comments naming the metadata board, not on-screen copy.

## Round 2 — review
Reviewers: UX (the only lens with a Fix-now major). Scope `3cdb843bf...0761030aa`.
- UX-1: Resolved — `L10n.swift:6750` and the catalog read "%@ is now suggested by this type."; T-1 pins it.
- CON-1 / MNT-1 / UX-2 (minor, read by the orchestrator): Resolved — `L10n.swift:9892` reads "…deleted or merged."
No new blockers.

Nits (logged): `UX-4 · L10n.swift:6751 · translator comment still says "on the board"`

## Result
Gate PASS · CI green (Go tests rerun once: `TestLargeSourceBudgets/warm_at_open` 2.519s over its 2.5s budget, a timing flake; this PR changes one Go comment) · open: none · follow-ups: none · to user: UX-1 (answered)
