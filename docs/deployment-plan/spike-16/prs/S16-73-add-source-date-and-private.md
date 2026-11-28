# S16-73 — Add Source takes the Published date and Private

**Status:** Landed in [#1019](https://github.com/Jake-Robins-Studios/provenencia/pull/1019) (2026-11-28)
**Landed:** As planned, except: D-15 disables every `pvFormDialog` body while it runs, so a failed save no longer keeps first responder in the field that was focused (as the Copy sheets already behaved); the version bump is to 0.52.0 (main was already 0.51.1) and all four `MARKETING_VERSION` lines moved; T-2 is a subtest of `TestSourcePublic`; STEP-8 names the brief at `design/archive/`; the date form's range-order message now carries the `end.fieldError` identifier too; `rg "\.disabled\(model\.isSaving\)"` also lists `PromoteView` (a page, not a dialog). The date line names what keeps a date from saving, and Hide time clears that side's time.
**Spike / slice:** Spike 16 · Slice 8a — The Add and Copy Source sheets
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S16-D15](../design/archive/S16-D15-add-source-fields.md), board agreed 2026-11-28
**Board:** [Claude Design — Source Detail](https://claude.ai/artifact/443NPNYmGErAmxgV1fBsFK), page *Dialogs*, section "Add Source" (frames `add-today` 0, `add-open` 1a, `add-open-wide` 1b, `add-filled` 2, `add-range` 3, `add-field-error` 4, `add-incomplete` 5, `add-created` 6, `add-discard` 7, `add-more` 8); read it with the Artifact tool's `read`, `path` "project/Source.dc.html", near `S16-D15`. §6 macOS describes each frame in words, so the implementer does not need to open it. Where the plan and the board differ, the plan wins (user, 2026-11-28): Private is a checkbox, not the board's switch (D-12); frame 5's phrase-only date is valid in the app (the board's stand-in check is simpler than `DateValueDraft.isValid`), so the AS-5 example is a phrase with a time zone
**Depends on:** S16-D15 (agreed 2026-11-28)
**Blocks:** S16-74
**Branch:** `s16-73-add-source-date-and-private`
**Version bump:** minor, 0.51.1 → 0.52.0 — Add Source gains two fields, and `CreateSourceRequest` gains two fields that old clients can leave out ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-date-value`](../../../../.agents/skills/add-date-value/SKILL.md), [`add-audit-scope`](../../../../.agents/skills/add-audit-scope/SKILL.md), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`, `.cursor/rules/swift-tests.mdc`
**Context:** map scope entry [S16-73](../deployment-plan.md#s16-73--add-source-takes-the-published-date-and-private); working rules "(Batch 8) The Add and Copy sheets share one set of Source fields" and "(Batch 8) A new Source and its parts are one write through one composer"; bar 44; [`docs/source-layer-data-model.md`](../../../source-layer-data-model.md) (the `sources` table, § 4.2 Copy Source)
**Runs on:** macOS with Xcode, `protoc`, `protoc-gen-go` and `protoc-gen-swift` (STEP-2's generation, the Swift steps and §10). STEP-1 and STEP-2's Go tests run anywhere with Go; without the proto tools, stop at STEP-2 and report: generated files are never written by hand
**Planned:** 2026-11-28 against `main` @ `9550775`
**Review:** [`S16-73-add-source-date-and-private.review.md`](S16-73-add-source-date-and-private.review.md) — Fits with changes / Ready with changes, 2 rounds; every blocker Fixed, every To user item answered (2026-11-28)

### Implementer — read this first

1. **This file is the whole task.** Read it top to bottom before you change code. Then read every file under **Current state** and load every skill under **Skills to load**.
2. **Check the base.** Compare `main` with the **Planned** commit. If a file under **Current state** has changed so a row is no longer true, stop and report which rows.
3. **Decisions are made.** Do not reopen a **Decision** or a **Scope** line, and do not swap in a design you like better. If one cannot work, stop: say which ID it is, what you found (path, line, output), and what you would need. Do not improvise around it.
4. **Do only In.** Out stays out, even when it is one line away. Do not refactor, rename, or tidy code the plan does not name.
5. **Work the Steps in order.** Run each step's check before you start the next. A failing check is fixed in that step.
6. **Hit a Stop condition → stop.** Report it. Do not work around it.
7. **Done is the Definition of done.** Report each box with its evidence: the command and its result, the test name, or the manual check you ran.
8. **Docs-only lines in the DoD are part of the PR.** Do not skip them.

---

## 1. Objective

A researcher adding a Source often knows when the record was published and whether it is private. Today Add Source takes only Title, Type and Description, so both need a second visit to the Source page. After this PR the Add Source dialog shows the shared Source fields, Title, Type, Published date, Description and Private, and Create writes the Source with its date and Private in its one write.

**Why now.** It is a user request (2026-11-26), Batch 8 of Spike 16. S16-74 puts the same fields on the Copy sheet and needs the shared view and the one composer this PR makes.

**What stays.** Title and Type and their error rule; what happens after Create (the page opens, the toast); a blank date and Private off create the Source exactly as today; the Copy sheet; the Source page; the date form.

## 2. User stories

**US-1.** As a researcher, when I add a Source, I enter its published date and tick Private in the same dialog, so the new Source starts complete.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Add Source opens | Title (focused), Type, Published date (the date form, blank), Description, Private (a checkbox, unticked, its help under it), in that order; the dialog is 560 pt wide |
| AC-1.2 | Title "1880 census, Ward 4", Type Census, date Point 1 Jun 1880, Private ticked → Create | The new Source's page header shows "1 Jun 1880" and its Private switch on; the Sources table's Published column shows the date; one `create_source` audit row |
| AC-1.3 | Same, date left blank, Private unticked | The Source is undated and public, exactly as a create today |
| AC-1.4 | Date Range 1879 to 1880 → Create | The Source's date is that range |
| AC-1.5 | A date that parses | The "Reads as" strip under the form shows it as the header will ("1 Jun 1880"); a blank or broken date shows no strip |

**US-2.** As a researcher, when the date I typed is not a date, I see why Create is disabled.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Month 13 typed | The form's own "month" error shows; no second line; Create disabled |
| AC-2.2 | Phrase "Spring 1880" and a time zone, no year | Under the form: "This date isn't complete. Finish it or clear its fields."; Create disabled |
| AC-2.3 | The fields of AC-2.2 cleared | The line goes; Create follows Title and Type again |
| AC-2.4 | Kind switched to Range alone, nothing typed | Blank: no line, Create follows Title and Type, the dialog is not dirty |

**US-3.** As a researcher, the dialog asks before discarding what I entered.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Only Private ticked → Cancel | The discard confirm shows |
| AC-3.2 | Only a year typed → Cancel | The discard confirm shows |

**US-5.** As a researcher, while a dialog saves, I cannot change what it is saving.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-5.1 | Add Source, Create pressed, the write still running | Every field, the Private checkbox and the date form are disabled and dimmed |
| AC-5.2 | Move to another Source, Move pressed, still running | Its fields are disabled, as the Copy sheet's are today |

**US-4.** As the engine, a create carries the date and the switch, and an old request means what it meant.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | `CreateSourceRequest` with no `date`, `is_private` unset | A public, undated Source, the same changes as today plus none |
| AC-4.2 | `date` Point 1880, `is_private` true | One write: the Source created with `is_public` 0 and its date row; one audit transaction `create_source` whose changes are source create (with `is_public` 0), evidence_graph create, date_value create, source update (`date_value_id`) |
| AC-4.3 | `date` with month 13 | `datevalue.ErrInvalid`; no Source is created and no audit transaction is added |
| AC-4.4 | `date` with a blank kind | Undated, as `SetSourceDate` reads it |

## 3. Scope

| In | Covered by |
| --- | --- |
| `CreateSourceRequest.date`, `is_private`; `sources.CreateInput.Private`; `CreateSource` through `sourcecopy.CreateFromDraft` | STEP-1, STEP-2, AC-4.1 – AC-4.4 |
| The shared Source fields view (AS-1) | STEP-6, AC-1.1 |
| Published date inline (AS-3), Reads as (AS-4) | STEP-5, STEP-6, AC-1.1, AC-1.4, AC-1.5 |
| The date-error line (AS-5) and the draft's date validation | STEP-4, STEP-6, AC-2.1 – AC-2.4 |
| Description moved into the shared view (AS-6) | STEP-6, AC-1.1 |
| Private as a kit checkbox (AS-7); `PVCheckbox` dims when disabled | STEP-5, STEP-6, AC-1.2 |
| Create sends both (AS-8); `PVFormDialog` disables its form while it runs, for every host | STEP-3, STEP-4, STEP-5, STEP-7, AC-1.2, AC-1.3, AC-5.1, AC-5.2 |
| Dirty (AS-9) | STEP-4, AC-3.1, AC-3.2, AC-2.4 |
| 560 pt, same at Wide (AS-2, AS-W1) | STEP-7, §10 |
| `sourcecopy` package doc, `source-layer-data-model.md` | STEP-8 |

| Out | Home |
| --- | --- |
| The Copy sheet's date, description and Private | S16-74 |
| Copy Source's call site moving from `SourceTitleTypeFields` to the shared view | S16-74 |
| An Unknown or Supplied control for the date; the empty-date flag | S15-42 (Spike 15) |
| Metadata, credibility or Artifacts on Add Source | not planned |
| A Clear date button on Add Source (the form is blank on open) | S16-74 (the Copy sheet starts filled), if its board draws one |
| Changing the date form or the Source date dialog's look | not planned |
| `PVSwitch`, `PVRadio`, `PVCopyPartTick` dimming under `.disabled(_:)`; the 0.5 vs `PVHoverEffect`'s 0.45 disabled opacity | [`docs/ideas/kit-layering.md`](../../../ideas/kit-layering.md) (a line added in STEP-8) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Proto | `api/proto/engine.proto` `CreateSourceRequest` (fields 1–5) | No date, no privacy |
| Handler | `api/ffi/handlers/sources.go` `CreateSource` | Calls `sources.Create` directly in its `writes.Run`; the second Source writer beside `sourcecopy.CreateFromDraft` |
| Create | `core/database/sources/sources.go` `CreateInput`, `Create`, `sqlInsert` | `INSERT` names five columns; `is_public` takes the column default 1; the returned `Source.IsPublic` is the literal `true` |
| Composer | `core/database/sourcecopy/sourcecopy.go` `Draft`, `CreateFromDraft`, package doc | Writes a Source with its date, metadata, credibility and Artifacts; the doc says it copies a Source, and nothing but `Copy` calls it |
| Date read | `core/valuecodec/valuecodec.go` `OptionalDateFromProto` | nil for an absent date or a blank kind; `SetSourceDate` uses it |
| Store | `macos/App/Platform/GenealogyStore.swift` `createSource(projectDir:userID:sourceTypeID:title:description:)`; `GoStore.swift` `createSource`; `FakeStore.swift` `createSource` | No date, no privacy |
| Test store | `macos/ProvenenciaTests/OnboardingModelTests.swift` `ThrowingStore.createSource` | Conforms to the protocol; changes with it |
| Draft | `macos/App/Features/Sources/SourcesModel.swift` `Draft`, `SourceDraftValidation`, `addSheetIsDirty`, `canSubmitAdd`, `openAdd`, `create()` | Title, type and description only |
| Add dialog | `macos/App/Features/Sources/SourcesListView.swift` `SourcesAddDialog.form` | Callouts, `SourceTitleTypeFields`, its own Description `PVField`; FormDialog width default 480; fields stay enabled while Create runs |
| Title and Type | `macos/App/Features/Sources/SourceTitleTypeFields.swift` `SourceTitleTypeFields` | Shared by Add and Copy; stays as it is |
| Date form | `macos/App/Features/Dates/DateValueEditorForm.swift` `DateValueEditorForm` | Shows its own field errors (`cascadeFieldError(start:)`, `endError`); takes no focus unless given `yearFocus` |
| Date draft | `macos/App/Platform/DateValueDraft.swift` `DateValueDraft` `isBlank`, `isValid`, `toInput()` | `isBlank` ignores kind, qualifier and time zones; nothing says whether the form is showing an error |
| Reads as | `macos/App/Features/Sources/SourceDateDialog.swift` `SourceDateForm.readsAs`, `showsReadsAs` | Private to the date dialog |
| Private switch | `macos/App/Features/Sources/SourcePageIdentityHeader.swift` `privateSwitch` | The header's immediate switch; stays as it is. Its strings `L10n.Sources.privateSwitch` and `privateSwitchHelp` are reused by the sheet's checkbox |
| Form dialog | `macos/App/DesignSystem/Components/FormDialog/PVFormDialog.swift` `PVFormDialogContent.formBody`, `PVFormDialogControls` | `isRunning` disables only Cancel and Confirm; hosts disable their own fields: `SourceCopyDialog.swift:63`, `ArtifactSheet.swift:90`, `SourceDateDialog.swift:52` and `:86`, `SourceGraphFormDialog.swift:83`, `SourceTypeAddDialog.swift:84`, `SourceTypeCopyDialog.swift:62`, `CitationMetadataSheet.swift:58` (all `.disabled(model.isSaving)`, the same flag they pass as `isRunning`). Hosts that pass `isRunning` and disable nothing: `PropertiesView` (`:736`), `SourceMoveDialog`, `SourcePageView` (three dialogs), `EvidenceGraphView`, `CitationComposerView` (five dialogs). `SourceTypePageView.swift:211` and `:237` disable a page form, not a dialog |
| Checkbox | `macos/App/DesignSystem/Components/Checkbox/PVCheckbox.swift` `PVCheckbox` | `.opacity(isDisabled ? 0.5 : 1)` only: inside a `.disabled` container it refuses clicks but does not dim |
| Tests | `api/ffi/handlers/sources_test.go` `TestCreateSourceAndWorkspace`; `core/database/sources/sources_test.go` `TestSources`, `TestSourcePublic`; `core/database/sourcecopy/sourcecopy_test.go` `TestCopy`; `macos/ProvenenciaTests/SourcesModelTests.swift` `draftValidation`, `canSubmitAddFollowsValidation`, `createReturnsSourceAndRefreshesList`, `cancelAddDoesNotCreate`; `EvidenceGraphStoreTests.swift` `createSourceMakesADefaultGraph`, `CatalogCountsTests.swift` (FakeStore `createSource` callers) | Cover today's three fields; no Swift test runs `GoStore` against the engine, so `GoStore`'s mapping is checked by §10 |

**Precedent.** `SetSourceDate` in `api/ffi/handlers/sources.go` reads the optional date with `valuecodec.OptionalDateFromProto` and maps it in `GoStore.setSourceDate` with `Self.mapDateValueToProto`: copy both. `sources.Create`'s `description` field in the created change (set only when non-empty) is the shape for `is_public` (set only when private). The citation composer puts `DateValueEditorForm` inline (`macos/App/Features/CitationComposer/CitationComposerAuthoringBox.swift`, `case .date`): copy how it passes the draft binding and an identifier prefix, without its `yearFocus` and without its sunken box.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | Proto: `CreateSourceRequest` gains `DateValueInput date = 6` (absent or blank kind is undated) and `bool is_private = 7`. No mark field | Working rule "one write through one composer"; Add Source sends no mark (rule "Swift carries the marks it reads") | `bool is_public` — its zero value would make every old request private |
| D-2 | `sources.CreateInput` gains `Private bool`. `Create` writes `is_public = !Private` in its `INSERT`, returns `IsPublic: !in.Private`, and adds `"is_public": 0` to the created change's fields only when private | The zero value stays public for the 111 `sources.CreateInput{` literals in 44 files (rule, map review K8-2); the audit records a non-default as `description` is recorded | A second write through `SetPublic` — two changes for one fact, and a public row that exists for an instant |
| D-3 | `CreateSource` builds a `sourcecopy.Draft{Source: CreateInput{…, Private}, Date: OptionalDateFromProto(req.GetDate())}` and calls `sourcecopy.CreateFromDraft` in its one `writes.Run`, action `create_source` | There is no second Source-and-date writer (rule) | Calling `sources.SetDate` in the handler — the second writer the rule forbids |
| D-4 | `sourcecopy.Copy` and `ReadDraft` are unchanged: a copy stays public until S16-74 | S16-74 owns the copy's Private | Reading `IsPublic` into the draft now — changes Copy behavior without its board |
| D-5 | `GenealogyStore.createSource` gains `date: CatalogDateValueInput?` and `isPrivate: Bool`, after `description`, with no default (a protocol requirement cannot have one). Every conformer and caller passes them | One signature, as `setSourceDate` takes an optional date | A second `createSource` overload — two ways to create |
| D-6 | `SourcesModel.Draft` gains `date: DateValueDraft = .empty()` and `isPrivate = false`. `SourceDraftValidation` gains `dateError: String?` = `draft.date.incompleteError` and `dateParses: Bool` = `draft.date.isBlank \|\| draft.date.isValid`; `isValid` also needs `dateParses` (month 13 has no `dateError`, since the form shows its own, yet is not valid) | The rule puts "whether a date parses" in `Draft.validation`; the date's own rules stay on `DateValueDraft` (D-7) | Checking the date in the view or the dialog — two rules |
| D-7 | `DateValueDraft` owns the date's display rules, three members *(new)*: `shownError(start:) -> String?` (`cascadeFieldError(start:)`, else on the end side `endError`), which `DateValueEditorForm.cascadeSection(start:)` reads in place of its inline `if` chain, same look; `incompleteError: String?` (not blank, not `isValid`, and `shownError` nil on both sides → `L10n.Sources.dateIncompleteError`); `value: CatalogDateValueInput?` (nil when blank, else `toInput()`). `SourceFields` passes `validation.dateError` to the Published date `PVField`'s `error:` | AS-5: one message, never two for one fault, and one place that says when the form shows an error | A `showsOwnError` that re-states the form's condition — two copies of one rule |
| D-8 | The date line needs no stored error and no "after first edit" flag: the date is blank on open, so it cannot be incomplete before the researcher types | AS-5's "not on open" holds by construction | A `dateError` stored on the model beside `titleError` — state that never differs from the derived value |
| D-9 | `addSheetIsDirty` is also true when `draft.date.value != nil` or `draft.isPrivate`, checked beside the title and description, before the sole-type early return. A date's edit is a change of `value`, never of the whole `DateValueDraft` (which also holds `showAdvanced`, `showStartTime`, `showEndTime`); S16-74's Copy dirty compares `value` the same way | AS-9; kind or qualifier alone, or opening More options, is not an edit | Comparing whole `DateValueDraft`s — opening More options would ask to discard |
| D-10 | `create()` sends `date: draft.date.value` and `isPrivate: draft.isPrivate`; validation has already refused an incomplete date | A blank form is undated (rule) | Sending a blank input with a kind — the engine would store an empty date |
| D-11 | The shared view is `SourceFields` *(new)*, `macos/App/Features/Sources/SourceFields.swift`. It composes `SourceTitleTypeFields`, the date `PVField`, the Description `PVField`, and the Private checkbox (D-12). `SourceTitleTypeFields` stays a separate view because the Copy sheet uses it until S16-74 | The rule lets the plan name it; a sibling keeps Copy unchanged in this PR | Growing `SourceTitleTypeFields` — the Copy sheet would show three new fields that write nothing |
| D-12 | Private on the sheet is a kit checkbox: `PVCheckbox(L10n.Sources.privateSwitch, description: L10n.Sources.privateSwitchHelp, isChecked: $draft.isPrivate)` with identifier `<prefix>.private`. The Source page header keeps its `PVSwitch` unchanged. `PVCheckbox` dims at `isDisabled \|\| !isEnabled` (it reads `@Environment(\.isEnabled)`; today it dims only on its parameter), so it dims inside the running form (D-15) | `PVSwitch`'s doc: a choice in a form that is saved later is a `PVCheckbox` (user, 2026-11-28, over the board's switch); the help is the checkbox's visible description, since a form shows its hints | The header's switch on the sheet — a control that reads as saved at once; the help as a tooltip — hidden in a form |
| D-13 | `SourceDateEditor` *(new)*, `macos/App/Features/Sources/SourceDateEditor.swift`: `DateValueEditorForm` then the Reads as card (today's `SourceDateForm.readsAs` look), the card shown when `draft.isValid` and `SourceDateText.line(draft.value)` is non-nil, with that line as its text. Inputs: `draft: Binding<DateValueDraft>`, `accessibilityIdentifierPrefix`, `yearFocus: PVFieldFocus? = nil`. `SourceDateForm` (the dialog) and `SourceFields` both draw it; the dialog's `showsReadsAs` and its `!model.clears` term go (`clear()` empties the draft, so `clears` implies blank). Identifier of the card: `<prefix>.readsAs` (the dialog keeps `sources.page.sourceDate.readsAs`) | AS-4 option A (board, 2026-11-28); one date block, so S15-42's control and empty-date flag land in one view for the dialog and both sheets; the Source date's wording has one helper (`SourceDateText`) | Extracting only the strip — S15-42 would change two hosts; `DateRowDisplay.line` directly — a second path beside `SourceDateText` |
| D-14 | Identifiers: `sources.add.date` (the form's prefix), `sources.add.date.readsAs`, `sources.add.private`. The error line gets none: `PVField` draws it through `PVErrorText` with no identifier, and the tests read `validation.dateError`. `SourceFields` takes the `accessibilityIdentifierPrefix` that `SourceTitleTypeFields` takes and builds these from it; the description keeps `sources.add.description` | S16-74 passes `sources.copy` | Fixed `sources.add.*` strings in `SourceFields` |
| D-15 | `PVFormDialog` disables its form body while it runs: `formBody` (both its scrolling and plain branches) wears `.disabled(isRunning)`. The host copies of that line go (Deletes); every other `pvFormDialog` host that passes `isRunning` now has its fields disabled while it runs, as the sheets that did it by hand do. `SourceFields.dialogWidth = 560` *(new)*; `SourcesAddDialog` and `SourceDateDialogModifier` pass it as `width:` | AS-2, AS-8; the running state is the kit's, one line for every host (user, 2026-11-28) | `.disabled(model.isSaving)` on `SourceFields` — the eighth copy; two `560` literals |
| D-16 | `FakeStore.createSource` sets `source.date = date`, `source.dateSortKey = date == nil ? nil : nextSourceDateSortKey`, `source.isPublic = !isPrivate` | The fake's two date writers agree (`setSourceDate` uses `nextSourceDateSortKey`) | Leaving the sort key nil |

**Rules this plan bends.** None. The working rule "(Batch 8) The Add and Copy sheets share one set of Source fields" said the sheets draw the header's switch; the user changed it to a checkbox (2026-11-28), and the map's rule is amended in this PR's planning commit.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `CreateSourceRequest.date`, `.is_private` *(new)* | proto fields | `SetSourceDateRequest.date`, `SetSourcePublicRequest.is_public` | Extends the existing request; same message types |
| `sources.CreateInput.Private` *(new)* | field | `sources.SetPublic` | `SetPublic` is an update of an existing row (D-2) |
| `SourceFields` *(new)*, `SourceFields.dialogWidth` *(new)* | view, constant | `SourceTitleTypeFields` | Kept for Copy until S16-74 (D-11); composed, not copied |
| `SourceDateEditor` *(new)* | view | `SourceDateForm` (form + `readsAs`) | Extracted from it, so the dialog and both sheets draw one date block (D-13) |
| `DateValueDraft.shownError(start:)`, `.incompleteError`, `.value` *(new)* | properties | `cascadeFieldError(start:)`, `endError`, `isBlank`, `toInput()`; `CitationObservationValue.invalidDate` | The form's display rule and the blank/valid/value split in one place (D-7); the composer's message is about several Observations, not one date |
| `SourceDraftValidation.dateError` *(new)* | field | `titleError`, `typeError` | Extends the one validation (D-6) |
| `L10n.Sources.formPublishedDate`, `formPublishedDateHint`, `dateIncompleteError` *(new)* | keys | `formTitle`, `formDescription`, `dateRangeOrderError` | Same namespace; the date message sits with the date form's messages |

**Builds on.** `sourcecopy.CreateFromDraft` (the one composer), `valuecodec.OptionalDateFromProto`, `GoStore.mapDateValueToProto`, `DateValueEditorForm`, `PVField`, `PVCheckbox`, `PVFormDialog`.
**Deletes.** `SourcesAddDialog`'s own Description `PVField` (moves into `SourceFields`); the eight host `.disabled(model.isSaving)` lines named in §4 Form dialog (the kit does it); `SourceDateForm.readsAs`, `showsReadsAs` and its `!model.clears` term; the inline error `if` chain in `DateValueEditorForm.cascadeSection(start:)` (it reads `shownError`); the literal `width: 560` in `SourceDateDialog.swift`. `CreateSource`'s direct `sources.Create` call.
**Next adds.** S16-74 calls `SourceFields` from `SourceCopyDialog` with the original's draft and `sources.copy`, and sends the date and Private through the same composer; `SourceTitleTypeFields` may then fold into `SourceFields`. S15-42's marks control and empty-date flag go into `SourceDateEditor`, so the date dialog and both sheets gain them from one view. Add Source sends no mark here (working rule); the create request's `date_mark` (into `sourcecopy.Draft.DateMark`), `SourcesModel.Draft`'s mark and `createSource`'s parameter belong to S15-42 (user, 2026-11-28; Spike 15's map says so). The date dialog can adopt `incompleteError` for its silent disabled Save (logged in the review).

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A Source created private, or dated, before its page first opens | Source page header (`SourcePageIdentityHeader`), Sources table Published column | The page reads the created `CatalogSource` that `session.apply(effects, .createdSource(created))` inserts; `mapSource` already carries `date`, `dateSortKey` and `isPublic`. T-1 reads them back through the workspace; §10 step 2 through the app |
| `SourcesModel.Draft` with a date on the Copy sheet | `SourceCopyModel` builds `SourcesModel.Draft(sourceTypeID:title:)` | Defaults keep its date blank, so its validation and Copy are unchanged (T-3, T-4) |

### Scale

None — one create writes one Source and at most one date row, as `SetSourceDate` already does; the dialog draws one form. The batch's Scale line (60 values, 200 Artifacts) is the Copy sheet's.

### Edges

- **Assumptions.** `CreateFromDraft` calls `sources.SetDate` with a nil date and an empty mark on a new Source: it reads the row and writes nothing, so an undated create's changes are today's plus none (T-1 "undated" compares the change list). `sourcemetadata.CreateAll` with an empty draft returns no changes before it reads.
- **Neighbors.** A date with only a kind or qualifier set is blank: undated, not dirty (AC-2.4, T-7). A phrase alone is a valid date (T-4). A time zone with no year and no phrase is blank and is dropped (T-4). A range with one side only (an end year 1880, no start) is invalid in `DateValueDraft.isValid` and in `datevalue.Validate` alike (`validateComponentRanges` needs a civil part on each side); it has no field error, so the AS-5 line shows and Create is disabled (T-4, T-6).
- **Removed inputs.** None — nothing is decided, excluded or deleted.
- **Real data.** None — no table-driven rule.
- **Untrusted size.** None — one date per request, validated by `datevalues.PutTx`.

### Schema

None — `sources.is_public` and `sources.date_value_id` exist (migration 63).

### Go core

| Package | Change |
| --- | --- |
| `core/database/sources` | `CreateInput.Private bool` *(new)*; `sqlInsert` names `is_public`; `Create` passes `boolInt(!in.Private)`, returns `IsPublic: !in.Private`, adds `fields["is_public"] = 0` when private (D-2) |
| `core/database/sourcecopy` | Package doc rewritten: it creates a Source with its parts, for Add Source (`CreateFromDraft` from a request) and Copy Source (`Copy`, from the original). No code change |

Errors: an invalid date is `datevalue.ErrInvalid` from `datevalues.PutTx`; the handler returns it as `SetSourceDate` does (nothing to add), and `writes.Run` rolls back the Source created before it.

### FFI

`api/proto/engine.proto` `CreateSourceRequest`:

```proto
message CreateSourceRequest {
  string project_dir = 1;
  string user_id = 2;
  string source_type_id = 3;
  string title = 4; // required (non-empty after trim)
  string description = 5;
  DateValueInput date = 6; // absent or blank kind: undated
  bool is_private = 7; // unset: public
}
```

Handler `api/ffi/handlers/sources.go` `CreateSource` per D-3. Regenerate with `./scripts/generate-proto.sh`.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Add Source dialog | `PVFormDialog` | `SourcesListView.swift` `SourcesAddDialog` | `width: SourceFields.dialogWidth`; form = the Callouts, then `SourceFields(…)`; the kit disables it while Create runs (D-15) |
| Source fields | snowflake | `SourceFields.swift` *(new)* | `VStack(spacing: PVSpacing.space6)`: `SourceTitleTypeFields`; `PVField(label: formPublishedDate, hint: formPublishedDateHint, error: draft.validation.dateError)` holding `SourceDateEditor(draft: $draft.date, accessibilityIdentifierPrefix: "\(prefix).date")` with no `yearFocus`; `error:` is `draft.validation.dateError` (its Reads as card sits inside the `PVField` content, above the field's error; the card shows only for a valid date and the error only for an incomplete one, so they never show together); `PVField(label: formDescription, hint: formDescriptionHint)` + `PVInput(text: $draft.description)`; the Private `PVCheckbox` (D-12). Inputs: `@Binding draft`, `@Binding titleError`, `@Binding typeError`, `types`, `accessibilityIdentifierPrefix` |
| Date form | `DateValueEditorForm` | `macos/App/Features/Dates/` | Unchanged |
| Date block | `DateValueEditorForm` + `PVCard(tone: .sunken)` | `SourceDateEditor.swift` *(new)* | D-13 |
| Private | `PVCheckbox` | `SourceFields.swift` | D-12; the label "Private", the help as its description |
| Running form | `PVFormDialog` | `PVFormDialog.swift` | D-15 |
| Previews | `#Preview` | `SourceFields.swift` | Frames 1 (blank), 2 (filled, Private ticked, Reads as), 4 (month 13), 5 (the AS-5 line), each over a `FakeStore` type list at 560 pt |

**Frames in words** (brief § 5). 1: on open, Title focused and empty, Type empty, the date form blank (Point, no qualifier, More options closed), Description empty, the Private checkbox off with its help line under it. 2: Title "1880 census, Ward 4, Altona", Type Census, the date 1 Jun 1880, the Reads as strip "1 Jun 1880", Description "Enumeration district 12", Private checked. 3: a range 1879 to 1880 with the Latest row. 4: month 13, the form's month error, Create disabled. 5: phrase "Spring 1880" with a time zone, the AS-5 line in danger ink under the form, Create disabled. 6: the new Source's header with the date and its Private switch on, and the created toast. 7: Cancel with only Private checked asks to discard. 8: More options on a range, the body scrolling.

States: loading types and a failed create keep today's Callouts; saving disables every field. Accessibility: the "Published date" label is read as text before the form, and the form's controls keep their own labels, as in the date dialog (the form resets `pvFieldLabel`); the AS-5 line is the field's error, read as `PVField` reads errors; the switch is spoken "Private" with its help.

### Strings

L10n keys *(new)*, in `L10n.Sources` beside `formDescription`:
- `formPublishedDate` · `sources.add.formPublishedDate` = "Published date"
- `formPublishedDateHint` · `sources.add.formPublishedDateHint` = "Optional — leave blank for an undated Source"
- `dateIncompleteError` · `sources.page.dateIncompleteError` = "This date isn't complete. Finish it or clear its fields." (beside `dateRangeOrderError`)

Removed: none. Old-scope copy: the subtitle `addDialogSubtitle` ("A thin record now — artifacts, notes and metadata live on the Source page.") stays true and is kept.

## 7. Steps

**STEP-1 — The engine creates a Source private.**
Files: `core/database/sources/sources.go`, `sources_test.go`. Skill: `add-audit-scope`.
Do: D-2.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sources/` passes with T-2.

**STEP-2 — Create Source takes the date and Private through the composer.**
Files: `api/proto/engine.proto`, generated `api/proto/engine/engine.pb.go` and `macos/App/Platform/Generated/engine.pb.swift`, `api/ffi/handlers/sources.go`, `sources_test.go`, `core/database/sourcecopy/sourcecopy.go` (the package doc and the `Draft` doc, "everything a copy can carry", only). Skills: `add-ffi-handler`, `add-date-value`.
Do: D-1, D-3; rewrite the package doc and the `Draft` doc to say a draft is a new Source with its parts, read from an original or built from a create request.
Check: `./scripts/generate-proto.sh` leaves no diff on a second run; `CGO_ENABLED=1 go test -tags fts5 ./api/ffi/handlers/ ./core/database/sourcecopy/` passes with T-1, T-3.

**STEP-3 — The store sends the date and Private.**
Files: `macos/App/Platform/GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift`, `macos/ProvenenciaTests/OnboardingModelTests.swift`, `EvidenceGraphStoreTests.swift`, `CatalogCountsTests.swift`, `macos/App/Features/Sources/SourcesModel.swift` (`create()` only, passing `date: nil, isPrivate: false` until STEP-4). Skill: `add-swift-test`.
Do: D-5, D-16.
Check: `NSUnbufferedIO=YES xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/EvidenceGraphStoreTests -only-testing:ProvenenciaTests/CatalogCountsTests CODE_SIGNING_ALLOWED=NO` passes; the app builds (`GoStore` maps both fields, read in review: `req.date` only when non-nil, as `setSourceDate`).

**STEP-4 — The draft holds the date and Private, and knows when the date is incomplete.**
Files: `macos/App/Platform/DateValueDraft.swift`, `macos/App/Features/Dates/DateValueEditorForm.swift` (`cascadeSection(start:)` reads `shownError`), `SourcesModel.swift`, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `macos/ProvenenciaTests/SourcesModelTests.swift`, `DateValueDraftTests.swift`. Skills: `add-localized-string`, `add-swift-test`.
Do: D-6, D-7, D-9, D-10; the three keys.
Check: `NSUnbufferedIO=YES xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/SourcesModelTests -only-testing:ProvenenciaTests/DateValueDraftTests CODE_SIGNING_ALLOWED=NO` passes T-4 – T-7; the date dialog shows its field errors as before.

**STEP-5 — Extract the date block; the kit disables a running form and dims a disabled checkbox.**
Files: `macos/App/Features/Sources/SourceDateEditor.swift` *(new)*, `SourceDateDialog.swift`, `macos/App/DesignSystem/Components/FormDialog/PVFormDialog.swift`, `macos/App/DesignSystem/Components/Checkbox/PVCheckbox.swift`, `macos/ProvenenciaTests/PVPanelFormDialogTests.swift`, and the seven host files of §4 Form dialog (the project uses synchronized folders: a new file needs no `project.pbxproj` edit). Skill: `add-ui-component`.
Do: D-13; D-15's kit line through `PVFormDialogControls.isFormDisabled(isRunning:)` *(new)*, beside `isCancelDisabled`, and the eight host lines removed; D-12's `PVCheckbox` dimming. The date dialog looks and behaves as before.
Check: `NSUnbufferedIO=YES xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/PVFormDialogControlsTests -only-testing:ProvenenciaTests/SourcePageModelTests CODE_SIGNING_ALLOWED=NO` passes T-8; `rg -n "\.disabled\(model\.isSaving\)" macos/App/Features` lists only `SourceTypePageView.swift`; the `PVCheckbox` preview's "Disabled" row and a row under `.disabled(true)` look the same.

**STEP-6 — The shared Source fields.**
Files: `macos/App/Features/Sources/SourceFields.swift` *(new)*, `SourceDateDialog.swift` (its width). Skill: `add-ui-component`.
Do: D-11, D-14, D-15's `dialogWidth` (the date dialog passes it), the macOS table; the previews.
Check: build; the four previews render the frames in words.

**STEP-7 — Add Source shows the shared fields.**
Files: `SourcesListView.swift`.
Do: D-15's width; the form calls `SourceFields`; its own Description field goes.
Check: `scripts/check-pr.sh` stage `xcode-test` passes (the whole `ProvenenciaTests` target); §10 steps 1–4.

**STEP-8 — Docs.**
Files: `docs/source-layer-data-model.md` (after the `is_public` paragraph: Add Source sets the date and the switch in its one `create_source` write, through `sourcecopy.CreateFromDraft`; a request with neither creates a public, undated Source. In § 4.2, "the engine under the Copy form" becomes "the composer under the Add and Copy forms"); `docs/deployment-plan/spike-16/completed.md`; `docs/deployment-plan/spike-16/deployment-plan.md` (map row); this plan (status, Landed note); `docs/deployment-plan/spike-16/design/archive/S16-D15-add-source-fields.md` (moved from `design/`; its relative links fixed); `docs/deployment-plan/spike-16/design/README.md`; `docs/ideas/kit-layering.md` (the Out line on the other toggles' disabled dimming); `VERSION`, `core/version.go`, all three `MARKETING_VERSION` lines in `macos/Provenencia.xcodeproj/project.pbxproj`.
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-73-add-source-date-and-private.md` reports no errors.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `api/ffi/handlers/sources_test.go` `TestCreateSourceAndWorkspace` (new rows) | "undated, public": no date, no flag → workspace `IsPublic` true, no date, the latest transaction's changes are {(source, create), (evidence_graph, create)}; "dated and private": Point 1880, `is_private` → response and workspace carry the date and `IsPublic` false, `DateSortKey` set, the latest transaction is `create_source` with changes {(source, create), (evidence_graph, create), (date_value, create), (source, update)} and the source create's `changes_json` holds `is_public` 0. Compare as sets, through the existing `latestRevisionTypes(t, dir)` (`api/ffi/handlers/metadata_test.go`, "entity action" strings); read the source create's `Fields` through `dbtest.LatestRevision` inside `catalogsession.Do`, as `latestRevisionTypes` does; "range": 1879 to 1880 → the workspace date is that range; "blank kind": `DateValueInput{}` → undated; and a subtest `t.Run("invalid date creates nothing", …)` *(new)* outside the `runRPC` table, as `TestSetSourceDate` writes its subtests: take `latestRevision(t, dir)` and the `ListSources` count, call `CreateSource` with month 13, require `errors.Is(err, datevalue.ErrInvalid)`, then both unchanged | AC-4.1, AC-4.2, AC-4.3, AC-4.4, AC-1.2, AC-1.4 |
| T-2 | Go | `core/database/sources/sources_test.go` `TestSources` (new row) | `CreateInput{…, Private: true}` → `Lookup` `IsPublic` false; the created change's fields hold `is_public` 0; without `Private` the fields hold no `is_public` | D-2 |
| T-3 | Go | `core/database/sourcecopy/sourcecopy_test.go` `TestCopy` (existing) | Unchanged and green: a copy of a private original is public | D-4 |
| T-4 | Swift | `SourcesModelTests.swift` `draftValidation` (extended) | blank date → `dateError` nil, valid; month 13 → `dateError` nil (the form shows its own) and invalid; phrase + time zone, no year → `dateError` set; phrase alone → nil; a time zone alone → blank, nil; a range with only an end year 1880 → `dateError` set, invalid; `Draft(sourceTypeID:title:)` with no date → nil | D-6, AC-2.1 – AC-2.3 |
| T-5 | Swift | `SourcesModelTests.swift` `createSendsDateAndPrivate` *(new)* | FakeStore; draft with date Point 1 Jun 1880 and `isPrivate` → created `CatalogSource` has that date and `isPublic` false; a blank draft → `date` nil, `isPublic` true | D-10, D-16, AC-1.2, AC-1.3 |
| T-6 | Swift | `macos/ProvenenciaTests/DateValueDraftTests.swift` `shownAndIncompleteErrors` *(new test)* | month 13 → `shownError(start: true)` set, `incompleteError` nil; range 1880 to 1879 → `shownError(start: false)` set; phrase + time zone → both shown nil, `incompleteError` set; a range with only an end year → both shown nil, `incompleteError` set; blank → all nil, `value` nil; only `showAdvanced` toggled on a blank draft → `value` nil | D-7, AC-2.1, AC-2.2 |
| T-7 | Swift | `SourcesModelTests.swift` `addSheetDirtyCountsDateAndPrivate` *(new)* | Only `isPrivate` → dirty; only a year → dirty; only `setKind("range")` or `showAdvanced` → not dirty, `canSubmitAdd` follows title and type | D-9, AC-3.1, AC-3.2, AC-2.4 |
| T-8 | Swift | `macos/ProvenenciaTests/PVPanelFormDialogTests.swift` `PVFormDialogControlsTests.formIsDisabledWhileRunning` *(new)* | `isFormDisabled(isRunning: true)` → true; `false` → false | D-15, AC-5.1, AC-5.2 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `SourcesModelTests`, `SourcePageModelTests`, `EvidenceGraphStoreTests`, `CatalogCountsTests`, `TestCopy`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — or none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated)
- [ ] Domain doc updated if a rule in docs/*.md changed: source-layer-data-model.md (creating a Source; § 4.2's composer line); the sourcecopy package and Draft docs
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

Bar 44. In a project with the seeded Source types:

1. Sources → Add Source. See Title (focused), Type, Published date, Description, the Private checkbox unticked with its help, in that order, at 560 pt. Stretch the window past 1600 pt of pane: the dialog stays 560 pt and centered (AC-1.1).
2. Title "1880 census, Ward 4", Type Census, Year 1880, Month June, Day 1; see "Reads as 1 Jun 1880". Tick Private. Create. The page header shows "1 Jun 1880" and its Private switch on; back on Sources the Published column shows the date (AC-1.2, AC-1.5).
3. Add Source, Title "Undated", a type, nothing else. Create: the Source is undated and its Private switch is off (AC-1.3).
4. Add Source: type 13 in Month: the form's month error shows, Create is disabled. Clear it; open More options, type the phrase "Spring 1880" and a time zone: the line "This date isn't complete. Finish it or clear its fields." shows. Clear the time zone: the line goes and Reads as shows the phrase (AC-2.1, AC-2.2, AC-2.3).
5. Add Source, tick only Private, press Cancel: the discard confirm shows (AC-3.1).
6. In Add Source, press Create: every field, the checkbox included, dims while it runs (AC-5.1). Move an Artifact to another Source: the dialog's fields are disabled while it moves (AC-5.2). Copy Source and the Source date dialog still disable their fields while saving (D-15).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| The date form inside a 560 pt dialog grows past the window with More options open on a range | `PVFormDialog` scrolls its body (`PVFittedScrollView`); §10 step 4 and frame 8 check it |
| A `CreateInput` literal elsewhere relies on `is_public` defaulting through the column | The zero value of `Private` writes 1, as the column default does; `go test ./...` covers the 111 literals |

**Stop and report if:**

- A `pvFormDialog` host's form holds a control that must stay live while the dialog runs (a stop or cancel inside the form, a field the run reads): D-15 would disable it.
- `sourcecopy.CreateFromDraft` writes any change for an undated, metadata-free draft beyond `sources.Create`'s (T-1 "undated" fails).
- `DateValueEditorForm` draws a date error that does not come from `shownError(start:)` (another `PVErrorText` site in the form).
- Putting `PVField` around `DateValueEditorForm` hides or doubles its section labels (its `.environment(\.pvFieldLabel, nil)`) in a way the previews show.
- S16-74 or S16-76 has landed and changed `CreateSourceRequest`, `sourcecopy.Draft` or `SourcesModel.Draft`.

## 12. Open questions

None.

## 13. PR

**Title:** S16-73 — Add Source takes the Published date and Private
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-73-add-source-date-and-private.md`.
