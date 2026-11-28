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
Gate PASS · CI green on `415051462` and, after the user round, on `84355b64c` · open: none · follow-ups: none · to user: UX-3 (VoiceOver order, manual check 3 and 5); CON-1 and UX-2 answered 2026-11-27

## User round — dogfood visual changes (2026-11-27)
The user asked for two layout changes after seeing the PR in the dogfood project. There is no design brief, and these changes supersede D-10's x for marriage lines and the partner-group placement in D-9 and D-10.

### Fix plan U
**U-1 — Marriage lines start where a tile's text starts**
Files: `macos/App/DesignSystem/Components/TileCard/PVTileCard.swift`, `macos/App/Features/Conclusions/PersonFamilyLayout.swift`, `macos/ProvenenciaTests/PersonFamilyLayoutTests.swift`.
Failing test first: `PersonFamilyLayoutTests/marriageLinesSitBetweenTheCouple`. A left-column line's frame x is the parent tile's x + `PVTileCardSize.regular.textLeading` (20 + 90 = 110), and its width is the tile's width less that.
Do: add `nonisolated var textLeading: CGFloat { padding.leading + thumbnail + contentSpacing }` to `PVTileCardSize`, a measure taken from the kit rather than a literal. Left-column line rects use `x: m + textLeading` and `width: tp - textLeading`. Line y values are unchanged.
Check: the test passes.

**U-2 — A partner's marriages sit below the partner, indented the same**
Files: `PersonFamilyLayout.swift`, `PersonFamilyContent.swift` (doc comment), `PersonFamilyLayoutTests.swift`.
Failing test first: `marriageLinesSitBetweenTheCouple` (right column).
- With one line: the partner tile is at y 26, and the line is at `x: c2 + textLeading`, `y: partner.maxY + marriageLineInset`.
- With two lines: they stack 21 pt apart.
- The first child starts at `partner.maxY + tileGap + n × marriageLineHeight`, the same rule as a parent's gap on the left.
- A partner group with lines and no children ends at or below its last line's maxY.
Do: in the right-column loop, place the partner first, then its lines, using the left column's gap rule. Drop `partnerMarriageGap`. Items go in the order partner, then lines, so VoiceOver reads the partner and then the marriage, as the left column reads a line after its parent. Fix the comments at Layout line 244 and Content line 77. The partner's horizontal join to the bus stays at the partner's centre. The child rail at `c2 - 12` passes left of the lines.
Check: the test passes, and the item order check `["r-0-maria", "r-0-m…"]` holds.

**U-3 — Previews and docs**
Do: the plan's Landed note records U-1 and U-2 as user changes of 2026-11-27, superseding D-10's line x and the partner-group placement. No new strings.
Check: scripts/check-pr.sh PASS.

### User round — implement
Head `c60542a65` (`a6abbf0fb`, `c60542a65`). Orchestrator gate PASS. Lines at x 110 (left) and x 643 (right), width 395; the partner's first line is at y 124.

### User round — review (quick lens, one reviewer)
| ID | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- |
| QCK-1 | major | The "lines and no children" assertion runs on a group that has children and reads the union frame, so it cannot fail | Fix now → U-4 | verified: `twoMarriages` gives Maria three children; `container` frames are the union of items |
| QCK-2 | nit | Right column bottom as a special case | Fix now → U-4 (one rule with the left column) | Layout:205 is the left column's rule |
| QCK-3 | nit | `PVTileCardSize` doc omits `textLeading` | Fix now → U-5 | file changed here |
| QCK-4 | nit | Codebase-fit row still names `partnerMarriageGap` | Logged | the Landed note supersedes it; plan tables are not edited |

**U-4 — One bottom rule, tested** (from QCK-1, QCK-2)
Failing test first: a fixture where Maria has a marriage and no children, followed by another partner group. Assert the next right group's `frame.minY` equals the last line's `maxY + partnerGroupGap`. When it is the last right group, assert `height >= ` the line's maxY. In `married`, assert Karl's minY is 151. To show the test is red, drop the `max` line on a scratch run, then restore it.
Do: set the right column's `bottom` from the items' max frame maxY, as the left column does at Layout:205, and drop the no-children special case.
**U-5** — add `textLeading` to the measures in `PVTileCard.swift`'s type doc.
Check: scripts/check-pr.sh PASS.

### User round — fix
Head `e3429ebc8`. Orchestrator gate PASS. U-4 done: red first (dropping `max` failed at the Sophie-minY expectation), then one rule, `bottom = items.map { $0.frame.maxY }.max()`. U-5 done. QCK-1 **Resolved** (read by the orchestrator: the childless-Maria case and Karl at 151 are now asserted).

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
| U | implementer (U-1–U-3) | default | 93k |
| U | quick reviewer | opus | 45k |
| U | implementer (U-4, U-5) | default | 88k |
| | **Total** | | **1,315k** |

## User round 2 — partner marriage spacing (2026-11-28)
The user, from dogfooding: in the right column a partner's marriage line sits 6 pt below the partner and 6 pt above the first child, so it reads as belonging to the child. They asked for more space so it clearly belongs to the partner alone.

**U-6 — Space after a partner's marriages**
Files: `macos/App/Features/Conclusions/PersonFamilyLayout.swift`, `macos/ProvenenciaTests/PersonFamilyLayoutTests.swift`.
Failing test first: `marriageLinesSitBetweenTheCouple`. In `married`, Karl's minY is the line's maxY + 18, which is 26 + 92 + 6 + 21 + 18 = 163. With `twoMarriages`, the first child is 18 below the second line. A partner with no marriage keeps its children `tileGap` (12) below the partner, unchanged. The line stays 6 pt below the partner.
Do: add `static let partnerMarriageChildGap: CGFloat = 18`, documented as the space between a partner's last marriage line and their first child, three times `marriageLineInset` so the line reads as the partner's. In the right-column loop, when the group has marriages, the children start at the last line's maxY + that gap. Otherwise keep `top += Self.tileGap`. The left column is unchanged.
Check: the test passes; scripts/check-pr.sh PASS. The Landed note records U-6 as a user change of 2026-11-28.

### User round 2 — fix
Head `5ee368caf`. Red first (Karl 151 vs 163). `partnerMarriageChildGap` = 18; the left column is unchanged. Orchestrator gate PASS; diff read: a partner with lines and no children still ends at its last line (one bottom rule). CI green on `5ee368caf`. Implementer 84k.
