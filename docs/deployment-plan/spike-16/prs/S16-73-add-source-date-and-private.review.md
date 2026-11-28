# Review — S16-73 Add Source takes the Published date and Private

**Verdict:** Fits with changes — Ready with changes, every blocker Fixed or To user. Status stays Blocked on board S16-D15, with four To user items
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet)

## To user
- **M-4.** The `PVSwitch` doc says a choice in a form saved later is a `PVCheckbox`. The working rule asks for the header's Private switch on Add and Copy. Recommendation: accept the exception and add it to the `PVSwitch` doc in this PR (plan §5 Rules this plan bends, Open question 3).
- **M-6.** Seven form dialogs disable their own fields while saving; `PVFormDialog` could do it once from `isRunning`, which also changes three dialogs that do not today. Recommendation: a separate quick PR after S16-73; this plan keeps its one `.disabled(model.isSaving)` line (Open question 4).
- **M2-3.** S15-42 (Spike 15) puts the Unknown and Supplied control on the Add sheet's date, but no PR adds a mark to `CreateSourceRequest`, and S15-42's Context line says S16-76 does (it does not). Recommendation: S15-42 owns `ValueMark date_mark = 8` on the create request, the mark in `SourcesModel.Draft` and in `createSource`; fix S15-42's Context line in Spike 15's map. Not added here: the working rule says Add Source sends no mark.
- **AS-4 and the board.** The plan is Blocked until S16-D15's board is agreed; AS-4 (Reads as on Add Source) is recommended A.

## Writer's own calls
- The shared view is `SourceFields`, a sibling that composes `SourceTitleTypeFields`, so the Copy sheet is unchanged until S16-74 (D-11).
- The new proto field is `is_private` (zero value public), not `is_public` (D-1).
- The dialog is 560 pt, the Source date dialog's width, through one constant (D-15).
- The date's "isn't complete" copy is a date-form string, `L10n.Sources.dateIncompleteError` beside `dateRangeOrderError` (D-7).
- The brief is drawn on the Source Detail board beside the Copy Source row (brief header).
- `PVSwitch` dims under `.disabled(_:)` (D-12): a visible change to every `PVSwitch` disabled through the environment.

## Round 1

### X-1 · blocker · Status is Blocked and D-13 rests on a board choice that is not made
**Answer:** To user — the plan stays `Blocked — on board S16-D15`; it is refreshed when the board is agreed (Open questions 1 and 2).

### X-2 · major · STEP-2's check cannot run on "the Go steps run anywhere"
**Answer:** Fixed — header **Runs on** names `protoc`, `protoc-gen-go`, `protoc-gen-swift`, and says to stop at STEP-2 without them; generated files are never hand-written.

### X-3 · major · The `xcodebuild test` command is never given
**Answer:** Fixed — STEP-3 gives the `-only-testing` command; STEP-6 names `scripts/check-pr.sh` stage `xcode-test`.

### X-4 · major · A range with only an end, or only a phrase, is "valid" in Swift
**Answer:** Declined in round 1 on false evidence; corrected in round 2 (M2-1): both `DateValueDraft.isValid` and `datevalue.Validate` refuse a one-sided range (`validateComponentRanges` needs a civil part). The neighbor, T-4 and T-6 now say it shows the AS-5 line.

### X-5 · major · Placement of the Reads as strip relative to the date `PVField`
**Answer:** Fixed — §6 macOS: inside the `PVField` content, above its error; they never show together.

### X-6 · major · T-1 names checks the harness does not offer
**Answer:** Fixed — T-1 adds `latestAuditChanges(t, dir)` *(new)* in `harness_test.go` and states the expected (entity_type, action) sets; AC-4.2 reworded (the date change is a `source` update).

### X-7 · minor · The invalid-date case must be seen to roll back
**Answer:** Fixed — §6 Go core: nothing to map; T-1 checks `latestRevision` unchanged.

### X-8 · minor · The header's disabled state is not stated for the extracted switch
**Answer:** Fixed — D-12: the header applies `.disabled(model.identity.pendingPrivate != nil)` (with M-5).

### X-9 · minor · Docs paths and the pbxproj step
**Answer:** Fixed — STEP-7 full paths; STEP-4 and STEP-5 say synchronized folders need no `project.pbxproj` edit; the version files are named.

### X-10 · minor · The precedent file's path is incomplete
**Answer:** Fixed — §4 Precedent: full path, "without its `yearFocus`".

### X-11 · minor · Brief and plan disagree on what the new page's header shows
**Answer:** Fixed — brief frame 6 draws the calendar icon and the bare date, as `SourceDateText.line` and the header do.

### X-12 · nit · The caller counts differ
**Answer:** Fixed in the plan (111 literals in 44 files). The map's "150-odd" is left as written.

### X-13 · nit · Cross-references the implementer must resolve
Logged.

### M-1 · blocker · The date form's rules get restated in Source code instead of living on `DateValueDraft`
**Answer:** Fixed — D-7: `DateValueDraft.shownError(start:)` (the form reads it), `incompleteError`, `value`; D-6 reads `incompleteError`; D-10 sends `value`; the string moves beside `dateRangeOrderError`. The date dialog's silent disabled Save adopting the line is logged as a Next add.

### M-2 · blocker · S15-42's control would need two hosts; extract the date block, not just the strip
**Answer:** Fixed — D-13: `SourceDateEditor` *(new)* (form + Reads as), drawn by the date dialog and `SourceFields`; the dead `!model.clears` term goes (Deletes). Brief inventory row "Date block".

### M-3 · major · Reads as formats outside `SourceDateText`
**Answer:** Fixed — D-13 uses `SourceDateText.line(draft.value)`.

### M-4 · major · The Private switch on a form contradicts `PVSwitch`'s doc
**Answer:** To user — listed under Rules this plan bends; STEP-4 updates the doc once answered.

### M-5 · major · Two ways to disable the switch
**Answer:** Fixed — D-12: `PVSwitch` reads `isEnabled`; `SourcePrivateSwitch` has no `isDisabled`.

### M-6 · major · Fields disabled while saving is copied in each host
**Answer:** To user — a kit change that alters three other dialogs; recommended as a separate quick PR. D-15 keeps the line; the brief's inventory row no longer claims the kit does it.

### M-7 · major · The date-edit rule sits in Add's dirty check
**Answer:** Fixed — D-9: a date edit is a change of `DateValueDraft.value`; S16-74's Copy dirty compares the same (named in D-9 for S16-74's plan).

### M-8 · minor · `FakeStore.createSource` ignores `nextSourceDateSortKey`
**Answer:** Fixed — D-16.

### M-9 · minor · The 560 pt width is a repeated literal
**Answer:** Fixed — D-15 `SourceFields.dialogWidth`.

### M-10 · minor · Two docs the change makes false
**Answer:** Fixed — STEP-2 (the `Draft` doc), STEP-7 and the DoD (§ 4.2's composer line).

## Round 2

### X2-1 · major · T-1 invents a helper that already exists
**Answer:** Fixed — T-1 uses `latestRevisionTypes` (`api/ffi/handlers/metadata_test.go`) and `dbtest.LatestRevision`; no new helper.

### X2-2 · major · The invalid-date row is not buildable in `runRPC`
**Answer:** Fixed — a `t.Run` subtest outside the table, as `TestSetSourceDate` writes its own.

### X2-3 · major · The date-error identifier cannot be attached; `shownDateError` undefined
**Answer:** Fixed — D-14 drops the line's identifier; §6 names `draft.validation.dateError`.

### X2-4 · major · `DateValueEditorForm.swift` not in a Files list
**Answer:** Fixed — STEP-4 Files.

### X2-5 · minor · STEP-3 too big
**Answer:** Fixed — split into STEP-3 (stores) and STEP-4 (draft and date rules), each with its own check.

### X2-6 · minor · Where the dirty terms go
**Answer:** Fixed — D-9: before the sole-type early return.

### X2-7 · minor · The accessibility sentence cannot be built
**Answer:** Fixed — §6 says the label is read as text and the form's controls keep their own labels.

### X2-8 · minor · The `PVSwitch` change has no check
**Answer:** Fixed — §10 step 6.

### X2-9 · nit · Three `MARKETING_VERSION` lines
**Answer:** Fixed — STEP-8.

### M2-1 · blocker · A range with one side only is invalid, not valid
**Answer:** Fixed — §6 Edges, T-4, T-6 (see X-4).

### M2-2 · blocker · `PVSwitch` keeps two disable channels
**Answer:** Fixed — D-12: `isDisabled:` removed from `PVSwitch`'s inits (Deletes); the other toggles' dimming and the 0.5 / 0.45 drift go to `docs/ideas/kit-layering.md` (§3 Out, STEP-8). Also: the §6 macOS row now uses `SourceFields.dialogWidth` (M-9 follow-up); D-6 names `dateParses` so `isValid` is buildable.

### M2-3 · blocker · S15-42's mark reaches Add Source with no PR carrying it
**Answer:** To user — a cross-spike map change; the plan's Next adds names the recommended owner.

## Cost
Plan: 4,978 words at round 1, 5,727 after round 1's fixes, 6,022 at the verdict (check-plan-docs info line).

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| 1 | maintainability | opus | 193k |
| 1 | executability | sonnet | 167k |
| 2 | maintainability | opus | 195k |
| 2 | executability | sonnet | 135k |
