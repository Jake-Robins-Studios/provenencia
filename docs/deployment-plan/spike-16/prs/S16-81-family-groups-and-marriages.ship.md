# Ship log — S16-81 Family groups siblings by their parents and shows each couple's marriage

**Plan:** [`S16-81-family-groups-and-marriages.md`](S16-81-family-groups-and-marriages.md) · **Branch:** `s16-81-family-groups-and-marriages` · **PR:** #1013
**State:** ready

## Round 0 — implement
Head `9aceaa371`. Gate FAIL: `patterns`. `swift-debug-only-in-release` fired on the new file `macos/App/Platform/EventSecondaryDisplay.swift` (D-16) with no line. Verified: `scripts/check-patterns.py` line 261's new-file loop runs every rule whose `pattern` is still `None`, and the `outside_debug` rule's pattern is filled in only after that loop (line 267), so any new non-test Swift file under `macos/App` fails. Checker bug, not the file. Sent back as gate fix 1: skip `outside_debug` rules in the new-file loop.

Report deviations: version bumped to 0.50.0, not 0.49.0, because `main` already holds 0.49.0 (S15-31). STEP-4/5 and STEP-7/8 each landed as one commit (shared files). P-8 sentence reworded so STEP-10's `rg` finds no `origin_siblings`. Small additions: `marriageLineInset`, `MarriageLine.spokenLine`, `PersonFamilyLayout.frame(ofLine:)`. `eventSummary` split moved from STEP-4 to STEP-3 (T-3 needs it). Not verified by the implementer: manual check 1–5, previews rendering, VoiceOver order of marriage lines (D-11).

### Gate fix 1
Head `04b7e5c30`. Commit "Stop the patterns check flagging every new Swift file in the app." (red first: 1 finding → 0). Implementer also pushed, opened draft #1013, and did the step-8 docs lines. Orchestrator gate on `04b7e5c30`: PASS (all ten checks).

## Round 1 — review
Ship log: Reviewers: CON, MNT, UX, SEC+PRF. Skipped: none.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1, SEC-1, UX outside-lens | CON/SEC | minor | Marriage line ids leave out the couple; one event shared by three parents gives duplicate ids and the wrong partner name | To user → Fix now → F-1 | verified: `marriageID(column:group:eventID:)` (PersonFamilyContent.swift:114), one `MarriageLine` per couple; changes D-6's id shape. User 2026-11-27: put the couple index in the id |
| MNT-1 | MNT | major | `L10n.list` is the one join, but no skill or check says so; two tests still build their expected text with `ListFormatter` | Fix now → F-2 | verified: `add-localized-string` has no mention; `ListFormatter` at ReconciledValueDisplayTests.swift:254,260, CatalogSearchTests.swift:298. Same-pass: this PR moved those callers onto `L10n.list` |
| MNT-2 | MNT | minor | `MarriageLine` stores two spoken labels | Fix now → F-3 | file added by this PR |
| MNT-3 | MNT | minor | Layout's private `Item` mirrors `Placed`; `frame(ofTile:)` / `frame(ofLine:)` are copies | Fix now → F-4 | `Item` and `frame(ofLine:)` new in this PR |
| MNT-4 | MNT | minor | `PersonLifeDisplayTests` copies the marriage fixture | Fix now → F-5 | same-pass cleanup; test file added by this PR |
| UX-1 | UX | minor | Cut-off marriage line has no way to read the whole value | Fix now → F-6 | verified: `.line` case has no `.help`; tiles have it via `PVPersonCard` |
| UX-2 | UX | minor | One parent: caption PARENT but VoiceOver says "parents" | To user → Fix now → F-7 | contradicts D-8's label list. User 2026-11-27: add singular labels |
| UX-3 | UX | minor | VoiceOver order of marriage lines (D-11) unverified | To user (manual check 3 and 5) | can't be run here; the user's manual check before merge; §11 stop condition 2 if wrong |

Nits (logged): `MNT-5 · PersonFamilyContent.swift caption switch · duplicate label branches` · `MNT-6 · PersonFamilyContent.swift init · ~230 lines; extract siblingGroups builder` · `MNT-7 · PersonLifeDisplay.swift:193 · SwiftUI import in a Platform formatter` · `UX-4 / CON-2 · PersonFamilySection.swift:157 · two blank lines before #if DEBUG` · `CON-3 · PersonFamilyLayout.swift · an empty sibling group still advances y (fakes only)`

### Fix plan 1
Supersedes D-6's marriage-line id shape (F-1) and adds two labels to D-8 (F-7), both on the user's answer of 2026-11-27. Note both in the plan's Landed note.

**F-1 — Marriage line ids include the couple** (from CON-1, SEC-1)
Files: `macos/App/Features/Conclusions/PersonFamilyContent.swift`, `macos/ProvenenciaTests/PersonFamilyContentTests.swift`.
Failing test first: `PersonFamilyContentTests/aMarriageOfThreeParentsHasOneIDPerLine`: one marriage event, couples (heinrich,anna), (heinrich,katharina), (anna,katharina) all on it, group 0 `coupleIndexes = [0,1,2]`; expect the three line ids distinct and each line's text naming its own partner.
Do: `marriageID(column:group:couple:eventID:)` → `"\(column)-\(group)-m\(coupleIndex)-\(eventID)"`, coupleIndex the index into `family.couples`; same for the right column. Update the tests that spell ids.
Check: the test passes; scripts/check-pr.sh PASS.

**F-2 — One list join, said and checked** (from MNT-1)
Files: `.agents/skills/add-localized-string/SKILL.md`, `scripts/check-patterns.py`, `macos/ProvenenciaTests/ReconciledValueDisplayTests.swift`, `macos/ProvenenciaTests/CatalogSearchTests.swift`.
Do: one line in add-localized-string: join names a sentence lists with `L10n.list(_:locale:)`, never a `ListFormatter` or `.formatted(.list(…))` of your own. Add a `check-patterns.py` rule (with its source) for `ListFormatter` / `.formatted(.list` in `macos/App/**` and `macos/ProvenenciaTests/**` outside `macos/App/Platform/L10n.swift`. The two tests build their expected text with `L10n.list`.
Check: `rg -n "ListFormatter|formatted\(\.list" macos` prints only `macos/App/Platform/L10n.swift`; the rule fires on a scratch line and is reverted; scripts/check-pr.sh PASS.

**F-3 — `MarriageLine` holds one label** (from MNT-2)
Files: `PersonFamilyContent.swift`, `PersonFamilySection.swift`, tests.
Do: set `line.accessibilityLabel` to the spoken label when building; drop `MarriageLine.accessibilityLabel` and `spokenLine`; the diagram draws `PVDatePlaceLine(marriage.line)`.
Check: tests read `marriage.line.accessibilityLabel`; scripts/check-pr.sh PASS.

**F-4 — One placed-item enum, one frame lookup** (from MNT-3)
Files: `macos/App/Features/Conclusions/PersonFamilyLayout.swift`, `PersonFamilyLayoutTests.swift`.
Do: build `Placed` with absolute frames, add `offsetBy(dx:dy:)`, drop the private `Item`; replace `frame(ofTile:)` / `frame(ofLine:)` with one `frame(of id: String)`. No geometry change.
Check: `PersonFamilyLayoutTests` pass unchanged in values; `rg -n "enum Item|frame\(ofLine|frame\(ofTile" macos` prints nothing; scripts/check-pr.sh PASS.

**F-5 — One marriage fixture** (from MNT-4)
Files: `PersonFamilyPreviewData.swift`, `PersonLifeDisplayTests.swift`.
Do: `PersonFamilyPreviewData.marriage` gains `type: String = SeededEventTypeTerm.marriage`; the test calls it with `day(…)` and its private helper goes.
Check: scripts/check-pr.sh PASS.

**F-6 — Marriage line shows its whole value on hover** (from UX-1)
Files: `PersonFamilySection.swift`.
Do: `.help(marriage.line.text)` on the `.line` item, as the tiles do.
Check: scripts/check-pr.sh PASS.

**F-7 — Singular labels for one parent** (from UX-2)
Files: `macos/App/Platform/L10n.swift`, `Localizable.xcstrings`, `PersonFamilyContent.swift`, `PersonFamilyContentTests.swift`. Skill: `add-localized-string`.
Failing test first: `captionsAndGroupLabels` gains: one parent in group 0 with a sibling → "This person, siblings and parent"; one parent, no sibling → "This person and parent".
Do: two keys, whole phrases; the `case (1, _)` branch uses them. Folding MNT-5's duplicate branches is allowed while here.
Check: the test passes; scripts/check-pr.sh PASS.

## Round 1 — fix
Head `eabcbc5b3` (commits `e2aac4dc6`, `f1d784ad3`, `eabcbc5b3`). Orchestrator gate PASS. F-1–F-7 done; F-1 and F-7 red first. MNT-5 fold not taken (optional). Landed note records the D-6 id shape, D-8's two labels and the `swift-list-formatter` rule.

Minors read by the orchestrator (no round-2 reviewer):
- CON-1 / SEC-1: **Resolved.** `marriageID(column:group:couple:eventID:)` → `l-g0-m{couple}-{event}`; `aMarriageOfThreeParentsHasOneIDPerLine` checks three distinct ids and partners Heinrich, Heinrich, Anna (parent i, per D-9).
- UX-1: **Resolved.** `.help(marriage.line.text)` on the `.line` item.
- UX-2: **Resolved.** `familyGroupThisPersonSiblingsAndParent` / `ThisPersonAndParent` in the `case (1, _)` branch.

## Round 2 — review
Reviewers: MNT (MNT-1 was a Fix-now major). CON, UX, SEC+PRF not sent: minors only, read above.

MNT-1 **Resolved** (skill line at `add-localized-string/SKILL.md:31`, rule `swift-list-formatter`, the only `ListFormatter` left is in `L10n.swift`). No new blockers. Verdict Clean.

## Finish
Merged `origin/main` `c7f4ba907` (S15-28 plan docs only). Gate PASS against `c7f4ba907`.

## Result
Gate PASS · CI pending · open: none · follow-ups: none · to user: UX-3 (VoiceOver order, manual check 3 and 5); CON-1 and UX-2 answered 2026-11-27

## Cost
Plan: 9,085 words (check-plan-docs info line).

| Round | Agent | Model | Tokens |
| --- | --- | --- | --- |
| 0 | implementer (incl. gate fix 1) | default | 417k |
| 1 | CON | opus | 147k |
| 1 | MNT | opus | 134k |
| 1 | UX | opus | 102k |
| 1 | SEC+PRF | opus | 90k |
| 1 | implementer (fix 1) | default | 146k |
| 2 | MNT | opus | 53k |
| | **Total** | | **1,089k** |
