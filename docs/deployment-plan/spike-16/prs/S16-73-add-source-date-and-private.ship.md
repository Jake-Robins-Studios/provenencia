# Ship log — S16-73 Add Source takes the Published date and Private

**Plan:** [`S16-73-add-source-date-and-private.md`](S16-73-add-source-date-and-private.md) · **Branch:** `s16-73-add-source-date-and-private` · **PR:** #1019
**State:** ready

## Round 0 — implement
Head `938c622a0`. Gate PASS (orchestrator re-run against `9d0a20145`). Report deviations: version bump is 0.52.0 (main was already 0.51.1), four `MARKETING_VERSION` lines; T-2 is a `TestSourcePublic` subtest; plan STEP-8 brief path moved to `design/archive/`; `DateValueEditorForm` routes the end side through `shownError` too (end-side range message gets `end.fieldError` identifier); STEP-5 `rg` also lists `PromoteView` (a page, left alone). Not verified: previews not rendered, §10 manual check, proto idempotence not byte-compared.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. Skipped: none.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1, UX-1 | CON, UX | major | Add Source dialog body does not scroll; frame 8 / §11 Risks row 1 unmet | Fix now → F-1 | verified: `SourcesListView.swift` `pvFormDialog` call passes no `scrollsBody`; default `false` (`PVFormDialog.swift:113`); the four other tall dialogs pass `true` |
| MNT-1 | MNT | major | `PVFormColumns` still disables its left column; `isSaving` param dead; doc now false | Fix now → F-2 | verified: `PVFormColumns.swift:3-5,15,45`; all three callers sit in `pvFormDialog(isRunning: model?.isSaving)`. Same-pass cleanup of D-15's host lines |
| MNT-2 | MNT | major | Dead `isDisabled: model.isSaving` on `PVCopyPartTick` in two touched files; no skill records the kit rule | Fix now → F-3 | verified: eight `PVCopyPartTick` calls, every one passes `model.isSaving`; tick forwards to `PVCheckbox`, which dims on `!isEnabled` (D-12). `PVArtifactChecklist`/`PVRadio` keep theirs (dim on param only). Same-pass cleanup |
| CON-2, UX-3 | CON, UX | minor | Kit-wide disable drops focus on a failed save; Add Source create error not announced | Fix now (announce + Landed note line) → F-1; focus restore → Follow-up | the announce is one argument in a file this PR changes; restoring focus in the kit is a design of its own, low confidence it occurs |
| MNT-3 | MNT | minor | Add Source's create path lives in package `sourcecopy` | Rejected | working rule "(Batch 8) A new Source and its parts are one write through one composer" names `sourcecopy.CreateFromDraft` and says it stays where it is, with its doc rewritten to cover Add and Copy (done) |
| UX-2 | UX | minor | Incomplete-date line can point at a hidden time block | Follow-up | the hiding is the existing `DateValueEditorForm` time toggle, which this PR does not change; ask the user for a home |

Nits (logged): `MNT-4 · SourceFields.swift:3 · doc says shared by Copy, which is S16-74` · `MNT-5 · SourceFields.swift:9 · dialogWidth doc vs SourceDateDialog` · `MNT-6 · SourceDateFormModel.swift:62 · could read storedDraft.value` · `CON-3 · source-layer-data-model.md:193 · "the copy is the composer"` · `CON-4 · plan header still says 0.51.0` · `UX-4 · SourceFields.swift:26-34 · incomplete-date line not announced` · `UX-5 · DateValueDraft incompleteError eager on a half-typed range`. MNT-4, MNT-5, CON-3 and CON-4 are stale comments in files this PR changes, so they ride along as F-4.

### Fix plan 1

**F-1 — Add Source scrolls its body and announces its create error** (from CON-1, UX-1, CON-2, UX-3)
Files: `macos/App/Features/Sources/SourcesListView.swift`; the plan's Landed note.
Failing test first: none (view wiring; no unit test reaches `pvFormDialog`'s body choice).
Do: pass `scrollsBody: true` in `SourcesAddDialog`'s `pvFormDialog` call, as `SourceMoveDialog` and `ArtifactSheet` do. If the create-error Callout can sit above the scrolled viewport, bring it back into view on a failed create with the same `scrollTarget`/`scrollRequest` + `.id(...)` pattern `ArtifactSheet` uses; otherwise skip that part and say so. Give the create-error `PVCallout` `announces: true`, as `SourceDateForm`'s save error does. Add one line to the plan's Landed note: D-15 disables every `pvFormDialog` body while it runs, so a failed save no longer keeps first responder in the field that was focused (as the Copy sheets already behaved).
Check: `rg -n "scrollsBody: true" macos/App/Features/Sources/SourcesListView.swift` prints one line; scripts/check-pr.sh PASS.

**F-2 — `PVFormColumns` stops disabling its own column** (from MNT-1)
Files: `macos/App/DesignSystem/Components/FormDialog/PVFormColumns.swift`, `macos/App/Features/SourceTypes/SourceTypeAddDialog.swift`, `macos/App/Features/Sources/SourceGraphFormDialog.swift`, `macos/App/Features/Sources/ArtifactSheet.swift`.
Failing test first: none (deletion).
Do: delete `isSaving` from `PVFormColumns`, its `.disabled(isSaving)`, the argument at the three call sites and in its two previews. Rewrite the doc comment: the form dialog disables the whole body while it runs, so the columns disable nothing themselves.
Check: `rg -n "isSaving" macos/App/DesignSystem/Components/FormDialog/PVFormColumns.swift` prints nothing; `rg -n "PVFormColumns\(" -A6 macos/App | rg isSaving` prints nothing; check-pr PASS.

**F-3 — `PVCopyPartTick` drops its saving flag; the skill records the kit rule** (from MNT-2)
Files: `macos/App/DesignSystem/Components/*/PVCopyPartTick.swift`, `macos/App/Features/Sources/SourceCopyDialog.swift`, `macos/App/Features/SourceTypes/SourceTypeCopyDialog.swift`, `.agents/skills/add-ui-component/SKILL.md`.
Failing test first: none (deletion).
Do: every `PVCopyPartTick` caller passes `model.isSaving` inside a `pvFormDialog`, so delete the `isDisabled` property from `PVCopyPartTick` and pass `isDisabled: !isAvailable` to `PVCheckbox`; remove the argument from the eight call sites (and any preview). Leave `PVArtifactChecklist`'s and `PVRadio`'s `isDisabled: model.isSaving` callers alone. Add one line beside the `isRunning` note in `add-ui-component` (~line 100): `PVFormDialog` disables its form body while `isRunning`; kit controls that read `isEnabled` (`PVCheckbox`, `PVSwitch`) need no `.disabled(model.isSaving)` or `isDisabled: model.isSaving` from the host; `PVRadio` and `PVArtifactChecklist` still dim only on their own parameter, so their hosts keep passing it.
Check: `rg -n "PVCopyPartTick\(" -A6 macos/App | rg "isSaving"` prints nothing; `rg -n "isDisabled: model.isSaving" macos/App/Features/Sources/SourceCopyDialog.swift macos/App/Features/SourceTypes/SourceTypeCopyDialog.swift` prints only the `PVArtifactChecklist` line in `SourceCopyDialog.swift`; check-pr PASS.

**F-4 — Stale doc lines** (from MNT-4, MNT-5, CON-3, CON-4)
Files: `macos/App/Features/Sources/SourceFields.swift`, `docs/source-layer-data-model.md`, the plan header.
Do: `SourceFields` doc says it is Add Source's, and Copy takes it in S16-74. `dialogWidth`'s doc says it is the width of the Add Source sheet and the Source date dialog. In `source-layer-data-model.md:193` make `core/database/sourcecopy` the subject of "the composer under the Add and Copy forms". Plan header's Version bump line reads 0.51.1 → 0.52.0.
Check: check-plan-docs PASS; check-pr PASS.

## Round 1 — fix
Head `5cc2e34f5`. Gate PASS (orchestrator re-run). F-1 to F-4 done. F-1 also did the scroll-back to the create error (`SourcesModel.createErrorScrollRequest`), since the Callout sits above a scrolled viewport. Not verified in the app: scroll-to-error and the announcement.

## Round 2 — review
Reviewers: CON, MNT, UX (each had a Fix-now major). Scope: `938c622a0...5cc2e34f5`.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1, UX-1 | CON, UX | major | Add Source body scrolls | Resolved | `SourcesListView.swift` passes `scrollsBody: true` + scroll target/request, `ArtifactSheet` pattern |
| CON-2, UX-3 | CON, UX | minor | Create error announced; Landed note line | Resolved | `announces: true` at `SourcesListView.swift:418`; Landed note line present |
| MNT-1 | MNT | major | `PVFormColumns` own disable | Resolved | no `isSaving` left in `FormDialog/` |
| MNT-2 | MNT | major | Kit rule recorded in the skill | Not resolved → F-5 | verified: the code half is done, but the skill line (`add-ui-component/SKILL.md:100`) lists `PVSwitch` as reading `isEnabled`; `PVSwitch.swift:59-60` dims only on its own `isDisabled`. `kit-layering.md:35` still lists `PVCopyPartTick` as dimming only on its own parameter. The wrong text came from Fix plan 1's F-3 wording (orchestrator's error) |
| F-4 doc lines | MNT, CON | minor | Stale doc lines | Resolved (orchestrator read) | `SourceFields.swift:3,8`, `source-layer-data-model.md:193`, plan header |

Nits (logged): `CON-5 · PVFormColumns.swift:68 · trailing comma in the first preview's argument list` (rides along in F-5).

### Fix plan 2
**F-5 — The skill and idea lines say which kit controls read `isEnabled`** (from MNT-2, CON-5)
Files: `.agents/skills/add-ui-component/SKILL.md`, `docs/ideas/kit-layering.md`, `macos/App/DesignSystem/Components/FormDialog/PVFormColumns.swift`.
Failing test first: none (docs).
Do: in `add-ui-component/SKILL.md:100`, the `isEnabled` list is "`PVCheckbox` (and `PVCopyPartTick`, which wraps it)"; move `PVSwitch` into the clause with `PVRadio` and `PVArtifactChecklist`, whose hosts keep passing their saving flag. In `kit-layering.md:35`, drop `PVCopyPartTick` from the "still dim only on their own parameter" list and add `PVArtifactChecklist` to it if it is not there (it dims only on its parameter). Drop the trailing comma before `)` in `PVFormColumns.swift`'s first preview.
Check: `rg -n "PVSwitch" .agents/skills/add-ui-component/SKILL.md` shows it only beside `PVRadio`; `rg -n "PVCopyPartTick" docs/ideas/kit-layering.md` prints nothing on line 35; scripts/check-pr.sh PASS.

## Round 2 — fix
Head `2f617839e`. Gate PASS (orchestrator re-run). F-5 done; orchestrator read the two lines: the skill's `isEnabled` list is `PVCheckbox` and `PVCopyPartTick`, with `PVSwitch` beside `PVRadio` and `PVArtifactChecklist`; `kit-layering.md:35` lists `PVSwitch`, `PVRadio`, `PVArtifactChecklist`. MNT-2 **Resolved**. `origin/main` has not moved since `9d0a20145`.

## Round 3 — user-directed copy fix
After the report the user asked what "This date isn't complete" means, since a partial publication date (a year, a month and year) is valid, and said: "Yeah, let's make sure our error messages are accurate and helpful to the user." The line fires for drafts that cannot be saved, not for partial dates, so "complete" is wrong. This round is the user's call, outside the two-round cap; UX-2 (Follow-up) and UX-5 (nit) come into it because the user asked for accurate, helpful messages.

Reachable cases where `DateValueDraft.isValid` is false and no field shows an error (read from `DateValueDraft.swift` and `DateValueEditorForm.swift`):
- Between two bounds with no earliest bound, no latest bound, or neither (phrase only on a range).
- Single date with a phrase and a time zone but no date or time (the time zone sits in the time block).
- A time block hidden by Hide time still holds its values (UX-2); a loaded date with a time zone but no hour opens with its time block hidden (`showStartTime: input.startHour != nil`).
- Not reachable from the form (qualifier on a range, end values on a single date, millisecond alone): a fallback line.

### Fix plan 3

**F-6 — Say why a date can't be saved** (from the user, UX-5)
Files: `macos/App/Platform/DateValueDraft.swift`, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `macos/App/Features/Sources/SourcesModel.swift`, `macos/ProvenenciaTests/DateValueDraftTests.swift`, `macos/ProvenenciaTests/SourcesModelTests.swift`. Skill: `add-localized-string`.
Failing test first: `DateValueDraftTests.unsavableErrors` — one `#expect` per case below, on the message.
Do: rename `incompleteError` to `unsavableError` (doc: the line for a draft that is typed into but cannot be saved, when no field shows an error). Same guard (not blank, not valid, no shown error). Return the first case that applies:
1. Range, start side and end side both without a date or time: "Between two bounds needs an earliest and a latest bound. Add both, or choose Single date."
2. Range, start side without a date or time: "Add the earliest bound, or choose Single date."
3. Range, end side without a date or time: "Add the latest bound, or choose Single date."
4. Single date, no date or time, a time zone set: "A time zone needs a date or a time. Add one, or clear the time zone."
5. Otherwise: "This date can't be saved as typed. Check its fields, or clear them."
"Without a date or time" is the existing `Side.hasCivil` false. Delete `L10n.Sources.dateIncompleteError` and its catalog entry; add one `L10n.Sources` key per message with a comment saying when it shows. Update `SourcesModel`'s caller and the two existing tests that name the old key.
Check: the test passes; `rg -n "incompleteError|dateIncompleteError" macos` prints nothing.

**F-7 — No hidden time values** (from UX-2)
Files: `macos/App/Platform/DateValueDraft.swift`, `macos/App/Features/Dates/DateValueEditorForm.swift`, `macos/ProvenenciaTests/DateValueDraftTests.swift`.
Failing test first: `DateValueDraftTests.hidingTimeClearsIt` — set start hour, minute and time zone with `showStartTime` true, call the new `hideTime(start: true)`: the four time fields and the zone are nil/empty and `showStartTime` is false; the end side likewise. Plus `DateValueDraftTests.loadShowsTimeWithZoneOnly` — a draft built from an input with a start time zone and no hour has `showStartTime` true.
Do: add `mutating func hideTime(start:)` beside `setKind`, which already clears the end side when switching to Single date: it clears that side's hour, minute, second, millisecond and time zone and sets its show flag false. The form's time toggle calls it when hiding (showing stays `toggle()` plus focus). In the init from input, a side's show flag is true when any of its hour, minute, second, millisecond or time zone is set.
Check: both tests pass; scripts/check-pr.sh PASS.

### Round 3 — fix and review
Head `365f4a28a`. Gate PASS (orchestrator re-run). F-6, F-7 done. Reviewer: UX (fresh), scope `a299eafb3...365f4a28a`.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| UX-1 (r3) | UX | major | "Hide time" now deletes the time but still says it hides | Fix now → F-8 | verified: `hideTime(start:)` clears the fields; `dateHideTime` label and comment unchanged; the Source date dialog and observation dates edit saved times |
| UX-2 (r3) | UX | major | "Add the earliest bound, or choose Single date" erases the only bound typed | Fix now → F-8 | verified: `setKind("point")` clears every `end*` field, so following the advice leaves a blank draft and Create enabled |
| UX-3 (r3) | UX | minor | A Single date with only a millisecond gets the catch-all line | Fix now → F-8 | traced: `hasCivil` leaves out the millisecond; the Millisecond field is in the time block, now never hidden with a value |

Nits (logged): `UX-4 (r3) · SourcesModel.swift:58 · doc still says "incomplete date"` (rides along in F-8).

**F-8 — The date messages and Hide time say what happens** (from UX-1, UX-2, UX-3, UX-4 of round 3)
Files: `macos/App/Platform/DateValueDraft.swift`, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `macos/App/Features/Sources/SourcesModel.swift`, `macos/ProvenenciaTests/DateValueDraftTests.swift`. Skill: `add-localized-string`.
Failing test first: extend `DateValueDraftTests.unsavableErrors` with the millisecond-only, millisecond-and-zone and zone-only cases; add `DateValueDraftTests.latestOnlyMessageKeepsTheBound` — a range with only `endYear` set shows `dateUnsavableRangeStart`, and its text does not contain "Single date".
Do:
- `dateHideTime`: value "Remove time", comment "Link that clears the optional time fields on one side". Update its catalog entry.
- `dateUnsavableRangeStart`: "Add the earliest bound." (choosing Single date clears the latest bound, the only one typed). `dateUnsavableRangeEnd` and `dateUnsavableRangeBoth` keep their text.
- Single date with no date or time, in place of the zone case: zone and millisecond both set → new key `dateUnsavableZoneAndMillisecond` "A time zone and a millisecond need a date or a time. Add one, or clear them."; zone only → `dateUnsavableZone` as now; millisecond only → new key `dateUnsavableMillisecond` "A millisecond needs a date or a time. Add one, or clear the millisecond."
- `SourcesModel.swift:58` doc: "for a date that can't be saved".
Check: tests pass; `rg -n '"Hide time"' macos/App` prints nothing; scripts/check-pr.sh PASS.

Head `24fee849c`. Gate PASS (orchestrator re-run). F-8 done; orchestrator read `unsavableError` and the seven strings: each case and its text match F-8. UX-1, UX-2, UX-3 (round 3) **Resolved**.

## Round 4 — user-directed board update
The user, 2026-11-28: "I want to just give you one more design update for this add source form. I got them to tighten up some of the fields just to make it take up less space." Board: Source Detail, `project/Source.dc.html`, the `S16-D15` block (markup at the `S16-D15 · the shared Source fields` comment, values in `addVals`, `privHelp`). "Go ahead and implement that on this PR."

What the board now draws, against the shipped `SourceFields`:
- **Type and Private share a row.** Type takes the rest of the width; Private sits at its right, top-aligned with the Type input (the board pads it 31 px, the height of the field label), at its natural width.
- **Private's help sits behind an info icon** beside the checkbox, as the Source page's Metadata help does (`SourcePageMetadataView.swift:13-19`): hover or focus shows "Private Sources will be kept out of sharing. Nothing else changes yet." The checkbox has no description line. The board's spoken label is "About Private." followed by the help.
- **Order: Title, Type | Private, Description, Published date.** Description moves above the date block; the date block is last.
- Unchanged: Title, Description's single-line input and hint, the Published date field and its hint, the date form itself, Reads as, the 560 pt width, the scrolling body.

This supersedes the order in the plan's AC-1.1 and the Batch 8 working rule ("Title, Type, Published date, Description and Private"); the user's board is the later call. Note it in the plan's Landed note.

### Fix plan 4

**F-9 — Add Source takes the board's tighter layout** (from the user)
Files: `macos/App/Features/Sources/SourceFields.swift`, `macos/App/Features/Sources/SourceTitleTypeFields.swift`, a new kit file `macos/App/DesignSystem/Components/HelpIcon/PVHelpIcon.swift`, `macos/App/Features/Sources/SourcePageMetadataView.swift`, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, the plan (§10 step 1 and Landed note), `docs/deployment-plan/spike-16/completed.md` if its paragraph names the order. Skills: `add-ui-component`, `add-localized-string`.
Failing test first: none (layout; no unit test reaches it). Keep the existing previews and update them.
Do:
1. `PVHelpIcon` (recipe layer, read `add-ui-component`): an icon (`PVIcon`, size 15, `PVColor.textMuted`) with `.help(text)`, one accessibility element with a label and a hint, and an accessibility identifier. Inits take `icon: PVIcon.Name` (or the kit's icon type), `label:` and `help:` as `LocalizedStringResource`. Move `SourcePageMetadataView`'s help icon onto it with no visible or spoken change (`.circleHelp`, `metadataHelpLabel`, `metadataIntro`, `sources.page.metadataHelp`). Find other copies by body: `rg -n "\.help\(" -B3 macos/App | rg "PVIcon\("` — move any icon-plus-`.help` copy onto it, or name why not in the report.
2. `SourceTitleTypeFields` gains an optional trailing view on the Type row (`@ViewBuilder typeTrailing`, defaulting to `EmptyView` through a constrained init so `SourceCopyDialog` compiles unchanged). When present, Type and the trailing view sit in an `HStack(alignment: .top, spacing: PVSpacing.space7)`; Type fills the width (`.frame(maxWidth: .infinity)`), the trailing view keeps its natural width.
3. `SourceFields` passes as the trailing view: the Private `PVCheckbox(L10n.Sources.privateSwitch, isChecked:)` with no description, then `PVHelpIcon(icon: .info, label: L10n.Sources.privateHelpLabel, help: L10n.Sources.privateSwitchHelp)` with identifier `<prefix>.privateHelp`, in an `HStack(spacing: PVSpacing.space3)`, padded on top so the checkbox centres on the Type input (match the field label's height from `PVField`; do not hard-code 31). New key `L10n.Sources.privateHelpLabel` "About Private". The checkbox keeps `<prefix>.private`.
4. `SourceFields` order: `SourceTitleTypeFields` (with the trailing view), Description, Published date. Update the type's doc comment and the previews' names.
5. Plan §10 step 1 reads the new order and the Type | Private row; the Landed note says the board update (2026-11-28) moved Private beside Type with its help behind an info icon and put Description above the date.
Check: `rg -n "PVIcon\(\.circleHelp" macos/App/Features` prints nothing; `rg -n "PVHelpIcon\(" macos/App` lists the Metadata header and `SourceFields`; scripts/check-pr.sh PASS.

### Round 4 — fix and review
Head `e192e235a`. Gate PASS (orchestrator re-run). F-9 done. Deviations: `PVField(labelHidden:)` added to align Private (no label height exposed); icon type is `PVSymbol`; README Components row added for `PVHelpIcon` (guidance-names). Reviewers (fresh): UX, MNT; scope `032fe6c80...e192e235a`.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 (r4), UX outside-lens | MNT, UX | major | `PVField(labelHidden:)` is a one-caller Bool with a fake "Type" label; control height set by hand | Fix now → F-10 | verified: `SourceFields` wraps the checkbox in `PVField(label: formType, labelHidden: true)` and `.frame(height: PVControlSize.md.height)`; the kit already aligns neighbours with a custom `VerticalAlignment` (`PVProvenanceRecordRow.swift:174-180`) |
| UX-1 (r4), MNT-3 (r4) | UX, MNT | minor | `PVHelpIcon` doc says focus shows the help; the icon can't take focus, so keyboard users lose Private's help | Fix now (doc) → F-10; keyboard-reachable help → To user | verified: no `.focusable` in `PVHelpIcon.swift`. The board promises "hover or focus"; making the help reachable by keyboard needs a kit design (focusable icon with a popover), so it goes to the user with a recommendation |
| MNT-2 (r4) | MNT | minor | Generic Type-row slot is dead once S16-74 moves Copy onto `SourceFields` | Later PR → written into S16-74's map scope entry (Ships) | done by the orchestrator in `deployment-plan.md` |

Nits (logged): `UX-2 (r4) · plan overview and AC-1.1 still list the old order` (rides along in F-10) · `MNT-4 (r4) · PVHelpIcon could take any PVCopy` · `MNT-5 (r4) · PVHelpIcon preview uses L10n.Sources` (rides along) · `MNT-6 (r4) · "neighbour" vs "beside"` (goes with MNT-1).

### Fix plan 5

**F-10 — Private lines up through an alignment guide; the help icon's doc says hover** (from MNT-1, UX-1, MNT-3, UX-2, MNT-5 of round 4)
Files: `macos/App/DesignSystem/Components/Field/PVField.swift`, `macos/App/DesignSystem/Components/HelpIcon/PVHelpIcon.swift`, `macos/App/DesignSystem/README.md`, `macos/App/Features/Sources/SourceTitleTypeFields.swift`, `macos/App/Features/Sources/SourceFields.swift`, the plan (overview line, AC-1.1, Landed note).
Failing test first: none (layout).
Do:
1. In `PVField.swift` declare a kit `VerticalAlignment.pvFieldControl` (pattern: `citationFirstLineCenter` in `PVProvenanceRecordRow.swift:174-180`, but internal to the kit, not private) whose value is the centre of the field's control; `PVField` sets it on its content with `.alignmentGuide(.pvFieldControl) { $0[VerticalAlignment.center] }`. Doc: lines up a control placed beside a field with that field's control.
2. Remove `labelHidden` from `PVField` (parameter, stored property, body branch) and its clause in the README Field row; describe the guide there instead.
3. `SourceTitleTypeFields`: the Type row is `HStack(alignment: .pvFieldControl, spacing: PVSpacing.space7)`.
4. `SourceFields`: drop the wrapping `PVField` and the `.frame(height:)`; the Private `HStack` sets `.alignmentGuide(.pvFieldControl) { $0[VerticalAlignment.center] }`.
5. `PVHelpIcon` doc and README row: "hover shows `help` as a tooltip; VoiceOver reads it as the hint. It cannot take keyboard focus, so do not put an instruction a researcher needs only here." Its preview uses string literals (`LocalizedStringResource` from a literal), not `L10n.Sources`.
6. Plan: overview line and AC-1.1 name the new order (Title, Type with Private beside it, Description, Published date; Private's help behind an info icon). Landed note: the alignment guide replaces any label padding.
Check: `rg -n "labelHidden" macos` prints nothing; `rg -n "pvFieldControl" macos/App` lists `PVField.swift`, `SourceTitleTypeFields.swift`, `SourceFields.swift`; `rg -n "L10n\\." macos/App/DesignSystem/Components/HelpIcon` prints nothing; scripts/check-pr.sh PASS.

Head `9b98c4abd`. Gate PASS (orchestrator re-run). F-10 done; orchestrator read the `PVField` guide and `SourceFields` diff: `labelHidden` and the fixed height are gone, the Private row sets the guide. The Check's `rg L10n.` over `HelpIcon` still lists `PVHelpIcon.body`'s `L10n.string` resolver calls, which are the kit's resolver, not feature copy; accepted. MNT-1, UX-1, MNT-3 (round 4) **Resolved**.

## Round 6 — user-directed: the help icon takes focus
The user, 2026-11-28, on round 4's To user item: "Make the icon focusable and the space command, and let's do it all in this PR." The board's promise ("hover or focus shows it", `privHelp`'s `tabIndex: 0`) is kept by the kit, for both callers (Add Source's Private, the Source page's Metadata heading).

### Fix plan 6

**F-11 — `PVHelpIcon` is a Tab stop; Space opens its help** (from the user; round 4 UX-1, MNT-3)
Files: `macos/App/DesignSystem/Components/HelpIcon/PVHelpIcon.swift`, `macos/App/DesignSystem/README.md` (HelpIcon row), tests under `macos/ProvenenciaTests` if the open/close rule is a value type. Skills: `add-ui-component`, `add-swift-test`.
Failing test first: if the open/close rule lands as a small value type (for example `PVHelpIconState` with `toggle()`, `close()`), `PVHelpIconTests` covers Space toggling and Escape closing; otherwise none, and say so.
Do:
1. The icon joins the key loop as `PVSegmentedControl`'s focus target does: `.focusable()`, a `@FocusState`, and the kit focus ring (`pvFocusRing(isFocused, cornerRadius: PVRadius.full)` or the ring `PVFocusRingButtonStyle` draws), always applied, opacity only (README "Interaction state").
2. Space (`.onKeyPress(.space)`) and a click toggle a small help card anchored below the icon: the `help` text in `PVFont.body(size: PVTypeScale.bodySmall)`, `PVColor.textSecondary`, max width 260 pt (the board's tooltip width), on the kit's popup surface. Present it the way the kit already presents an anchored popup (`PVContextMenu`'s child-panel presenter, closed through `.pvPopup`), so Escape, a click outside and the window losing key close it. Read `PVPopup.swift` and `PVContextMenu.swift` first; reuse a presenter, do not copy one. If no kit presenter can show a non-menu card without a copy, stop and report which one is closest and what it lacks.
3. Escape closes the card first. Inside a sheet (Add Source) Escape must close only the card, not the sheet: raise `.pvSheetInnerEdit(isOpen)` while it is open if the popup does not already keep Escape from the sheet (README § sheets). Tab away closes it.
4. Hover still shows `.help(help)` as today. VoiceOver: keep the label and hint, add `.accessibilityAddTraits(.isButton)` and an `.accessibilityAction` that toggles the card, and `pvExpandedState(isOpen)` as `PVSelect` does.
5. Doc and README row: "Tab reaches it; Space or a click opens its help in a small card, Escape or a click outside closes it; hover shows the same text as a tooltip; VoiceOver reads it as the hint." Remove the "cannot take keyboard focus" sentence.
6. The Source page's Metadata heading gets the same behaviour through the shared control; no change at its call site.
Check: `rg -n "cannot take keyboard focus" macos` prints nothing; `rg -n "\\.popover\\(" macos/App` prints nothing; scripts/check-pr.sh PASS. The plan's §10 step 1 adds: Tab to the info icon by Private, press Space, read the help, press Escape: the card closes and the sheet stays open.

### Round 6 — fix and review
Head `e30ab2e0e`. Gate PASS (orchestrator re-run). F-11 done through `pvContextMenu` + `PVContextMenuPanel(width: 260)`, no new presenter; `.pvSheetInnerEdit` raised unconditionally; no unit test (reuses `PVContextMenuState`). Reviewer (fresh): UX, scope `9b98c4abd...e30ab2e0e`. Traced and holding: Tab reaches the icon, Space and one click toggle, Escape closes only the card (the watcher consumes it), a click outside and Tab away close it, VoiceOver traits and action.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| UX-1 (r6) | UX | minor | Return does nothing while the card is open; the inner-edit signal isn't needed for Escape | Fix now → F-12 | traced: `pvSheetInnerEdit` raises `pvSheetTakesReturn`, Create loses its shortcut, the keyboard-less presenter ignores Return; the watcher already consumes Escape |
| UX-2 (r6) | UX | minor | Focus ring drawn inside the 15 pt glyph; system focus effect not off | Fix now → F-12 | `PVIcon` frames at size × size and `strokeBorder` insets; kit `.focusable()` views with their own ring add `.focusEffectDisabled()` |
| UX-3 (r6) | UX | minor | In Add Source the 260 pt card hangs right from an icon at the sheet's right edge | Fix now (call-site edge) → F-12; screen clamp in `PVContextMenuPlacement.panelFrame` → Follow-up | `present(at: x: 0)`; icon is the Type row's last item |

Nits (logged): `UX-4 (r6) · tooltip shows over the open card` (rides along in F-12) · `UX-5 (r6) · .focusable() takes focus on click; .activate would act more like a button` (kept: the user asked for a Tab stop, and `.activate` leaves the key loop without Full Keyboard Access).

### Fix plan 7

**F-12 — The help card leaves Return alone, rings the glyph, and opens inward** (from UX-1, UX-2, UX-3, UX-4 of round 6)
Files: `macos/App/DesignSystem/Components/HelpIcon/PVHelpIcon.swift`, `macos/App/Features/Sources/SourceFields.swift`, `macos/App/DesignSystem/README.md` (HelpIcon row), the plan §10 step 1.
Failing test first: none (view wiring).
Do:
1. Remove `.pvSheetInnerEdit(card.isPresented)`; the popup watcher already keeps Escape from the sheet.
2. Pad the icon by `PVSpacing.space1` (or the nearest token that gives about 3 pt) before `.contentShape(Circle())` and `.pvFocusRing`, so the ring circles the glyph; add `.focusEffectDisabled()` after `.focusable()`. Keep the visual size at 15 pt and adjust the card's y offset for the padding.
3. `PVHelpIcon` gains `cardEdge: HorizontalEdge = .leading`. `.trailing` places the card's trailing edge at the icon's trailing edge (`x: iconFrame - cardWidth`). `SourceFields` passes `.trailing`; the Metadata heading keeps the default.
4. Drop `.help(help)` while `card.isPresented` is true.
5. README row names `cardEdge`. Plan §10 step 1 adds: with the card open, press Return: the Source is created.
Check: `rg -n "pvSheetInnerEdit" macos/App/DesignSystem/Components/HelpIcon` prints nothing; scripts/check-pr.sh PASS.

Head `3c632e297`. Gate PASS (orchestrator re-run). F-12 done; orchestrator read the `PVHelpIcon` diff: no inner-edit signal, 4 pt ring padding (`space2`, the nearest token) with `.focusEffectDisabled()`, `cardEdge` with `.trailing` from `SourceFields`, tooltip empty while the card is open. The padding also widens the Metadata heading's icon by 8 pt. UX-1 to UX-4 (round 6) **Resolved**; not seen in the app.

## Result
Gate PASS · CI green at `a299eafb3`, re-run on push · open: none · follow-ups: CON-2/UX-3 (round 1) focus restore and UX-3 (round 6) popup screen clamp dropped by the user (2026-11-28); UX-2 (round 1) and UX-5 to `docs/ideas/date-value-form.md` · UX-2 (round 1) fixed in round 3 · to user: —

## Cost
Plan: 6,277 words (check-plan-docs info line).

| Round | Agent | Model | Tokens |
| --- | --- | --- | --- |
| 0 | implementer | sonnet | 207k |
| 1 | CON | opus | 101k |
| 1 | MNT | opus | 70k |
| 1 | UX | opus | 91k |
| 1 | SEC+PRF | opus | 65k |
| 1 | implementer fix | sonnet | 90k |
| 2 | CON | opus | 40k |
| 2 | MNT | opus | 47k |
| 2 | UX | opus | 34k |
| 2 | implementer fix | sonnet | 72k |
| 3 | implementer fix | sonnet | 87k |
| 3 | UX | opus | 62k |
| 3 | implementer fix | sonnet | 77k |
| 4 | implementer fix | sonnet | 95k |
| 4 | UX | opus | 49k |
| 4 | MNT | opus | 67k |
| 5 | implementer fix | sonnet | 82k |
| 6 | implementer fix | sonnet | 99k |
| 6 | UX | opus | 86k |
| 7 | implementer fix | sonnet | 72k |
| | **Total** | | **1,593k** |
