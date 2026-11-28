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

## Result
Gate PASS · CI see PR · open: none · follow-ups: UX-2 (incomplete-date line can point at a hidden time block), CON-2/UX-3 focus restore after a failed form-dialog save · to user: —

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
| | **Total** | | **817k** |
