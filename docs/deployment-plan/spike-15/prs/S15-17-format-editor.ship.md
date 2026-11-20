# Ship log — S15-17 The format editor

**Plan:** [`S15-17-format-editor.md`](S15-17-format-editor.md) · **Branch:** `s15-17-format-editor` · **PR:** #924
**State:** ready

## Round 0 — implement
Head `7efe84770`. Gate PASS (orchestrator run, against `24bd80e70`). Report deviations: the Claude Design board could not be opened (copy from brief § 2.1 and the plan's Strings; layout from the plan's macOS table); the completion popup, warning-click selection, page layout and manual check § 10 were never run by hand; `PVPopupList` moved out of `PVComboBox` with `width` and `anchorRect`; completion row level is a `PVBadge` (`PVChip` is a toggle); a warning's quote is not mono; extra helpers `SourceTypeFormatsModel.isRendering(_:)`, `placeholder(_:id:)`, `FakeStore.resetPreviewCalls()`, extra copy keys (loading, load error, preview no-match, locked hint, origin words, `readerLabel`), `L10n.CitationFormats.diagnostic(_:key:characters:)`; `sourcetypes.Update` checks the type before the label (D-4).

## Round 1 — review
Reviewers: CON, MNT, UX (`macos/App/**`, `Localizable.xcstrings`), SEC+PRF (`api/ffi/**`, `core/database/**`, `macos/App/Features/**` models; a 4,000-character user format parsed per keystroke). Skipped: none.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1, UX-4 | CON, UX | blocker | A failed preview leaves the three previews showing; another form's success clears the error | Fix now → F-1 | verified: `previewError` read only at `SourceTypeFormatsSection.swift:106`; `applyPreview` `.success` sets `previewError = nil` for any form (`SourceTypeFormatsModel.swift:348`) |
| MNT-1 | MNT | blocker | The completion list re-draws the combo box's list beside `PVPopupList` | Fix now → F-2; S16-51 map row and scope entry updated on this branch (Later PR) | verified: D-12 "`PVComboBoxPopupWindow` and its rows move to `PVPopupList.swift`", rejects "a second popup list design"; only the window moved |
| CON-2, MNT-3 | CON, MNT | major | Completion's accept rule sits in a view closure, untested, with magic brace constants | Fix now → F-3 | verified: D-21 and T-6b; no test reaches `accept` |
| CON-3 | CON | major | § 10 manual check not run; the binding Stop condition has no evidence | Fix now → F-4 (binding test); § 10 and board check go to the user at finish | the plan's Risk row and Stop condition name the binding; a hosted-binding test closes the Stop condition, the hand steps remain the user's |
| UX-1 | UX | major | Completion list outlives Shift-Tab / Tab with no rows | Fix now → F-5 | verified: `handle` has no `insertBacktab:`; router's focus branch never closes |
| UX-2 | UX | major | Return on a focused warning does nothing | Fix now → F-6 | `pvActivatesOnReturn` exists and is not used |
| UX-3 | UX | major | VoiceOver reads only "Full note, read only" on a locked type | Fix now → F-6 | explicit label replaces the combined text; no value |
| MNT-2, UX-8 | MNT, UX | major | A fourth origin → words mapping with new strings | Fix now → F-7 (same-pass cleanup) | `OriginMarkers.swift:10-31`, `L10n.Origin` |
| MNT-4 | MNT | major | `PVSubsectionHeader` accessory slot has no caller | To user → **drop it** (user, 2026-11-20) → F-8; supersedes that part of D-20 | `rg 'accessory:' macos/App` matches only the component |
| MNT-5 | MNT | major | `LatestCall` has no guide line; `ArtifactViewerModel` still hand-rolls a generation counter | Fix now → F-9 (same-pass cleanup) | `ArtifactViewerModel.swift:122,160` |
| UX-6 | UX | minor | Warnings flicker on every keystroke | To user → **keep the last warnings, dimmed and inert, until the form's next reply** (user, 2026-11-20) → F-10; amends D-11 | `shownDiagnostics` returns `[]` once the draft moves |
| CON-4 | CON | minor | AC-1.5 / AC-1.8 warning text vs engine spans | too_long: Fix now → F-11 (AC-1.8 has no quote). unclosed_group: To user → **correct AC-1.5's example to quote "["** (user, 2026-11-20) → F-11 | `parse.go:340` span is the `[`; `formats.go:390` spans the whole text |
| CON-5, UX-9 | CON, UX | minor | Edits typed while a Save is in flight are overwritten | Fix now → F-12 | `adopt` sets drafts unconditionally |
| CON-6 | CON | minor | too_long from the stored-byte limit reads "0 over" | Fix now → F-11 | `L10n.swift` clamps `over` to 0 |
| CON-7 | CON | minor | Weak checks in T-10, T-11 | Fix now → F-13 | test bodies |
| CON (outside lens) → UX-14 | UX | minor | `sources.not_found` on the first Source clears the pick with no re-render and no message | Fix now → F-14 | verified: `applyPreview:355-357` returns after `pickedSourceID = nil`; `effectivePickID` is unchanged when the pick was the first Source |
| UX-5 | UX | minor | Preview element doesn't name its form; `previewSpoken` unused | Fix now → F-6 | `grep previewSpoken` finds only its definition |
| UX-7 | UX | minor | "No Census Source yet" while the Sources list loads | Fix now → F-14 | `previewSources` defaults `[]` |
| UX-10 | UX | minor | Count spoken as "560 / 4,000"; area value override | Fix now → F-6 | header meta has no label or `.count` id |
| UX-11 | UX | minor | No announcement when the open list empties | Fix now → F-5 | `evaluate` has no empty branch |
| PRF-1 | PRF | minor | Page open sends up to three rounds of previews | Fix now → F-14 | `schedule` runs before `load()` finishes |
| PRF-2 | PRF | minor | Completion list builds every row; per-row linear lookup | Fix now → F-2 (lazy list) and F-14 (dictionary) | non-lazy `VStack`; `placeholder(_:id:)` is `first { }` |
| MNT-6 | MNT | minor | "Save formats with the type's details" written four times in Go tests | Fix now → F-15 (same-pass cleanup) | diff hunks |
| MNT-7 | MNT | minor | Field row `Ref` sliced from text though `metaRef` exists | Fix now → F-15 | `placeholders.go:43-45` |
| MNT-8 | MNT | minor | `Update` and `UpdateWithFormats` repeat the same tail | Fix now → F-15 | `sourcetypes.go:333-357`, `formats.go` |
| MNT-9 | MNT | minor | Plugin check derived twice | To user → **keep D-7** (user, 2026-11-20) → Rejected | each default fits its own use |

Nits (logged): `MNT-10 · L10n.swift:12745 · formTitle repeats formTitleResource's switch` · `MNT-11 · PVTextArea.swift · two blank lines in PVTextEditorInsetClearer` · `MNT-12 · PVTextArea.swift:560 · completion session keeps its own PVTextAreaCursor` · `MNT-13 · GoStore.swift citationPlaceholders · builtin id rebuilt by hand; use p.ref` · `CON-8 · SourceTypePageModel.submit · detailsChanged compares untrimmed label` · `UX-12 · SourceTypeFormatsSection.swift:402 · empty PREVIEW block with no runs` · `UX-13 · SourceTypeFormatsSection.swift:203,405 · locked empty form reads "No format" twice`

### Fix plan 1

Order: blockers, majors, then minors. Each F is its own commit. Plan changes the user approved (MNT-4, UX-6, CON-4) go into the plan's Landed note, and AC-1.5's example text is corrected in § 2.

**F-1 — A failed preview hides the previews; each form keeps its own failure** (from CON-1, UX-4)
Files: `macos/App/Features/SourceTypes/SourceTypeFormatsModel.swift`, `SourceTypeFormatsSection.swift`, `macos/ProvenenciaTests/SourceTypeFormatsModelTests.swift`.
Failing test first: `SourceTypeFormatsModelTests` — full fails, then short succeeds → `previewError` still set (today nil); while any form has failed, the section draws no `SourceTypeFormatPreview` (model exposes `isPreviewFailed`).
Do: `previewErrors: [CitationForm: String]`; `previewError` (the callout's text) is the first in form order; a form's success clears only its own entry; a retry (`rerenderAll`) keeps them until each reply lands. `SourceTypeFormatEditor` skips `SourceTypeFormatPreview` while `previewError != nil` (AC-4.7: the three previews hidden). Update `aFailedPreviewIsKeptUntilTheNextSuccess`.
Check: the tests pass; scripts/check-pr.sh PASS.

**F-2 — One popup list view for the combo box and the completion** (from MNT-1, PRF-2)
Files: `macos/App/DesignSystem/Components/ComboBox/PVPopupList.swift`, `PVComboBox.swift`, `macos/App/DesignSystem/Components/TextArea/PVTextArea.swift`, `macos/App/DesignSystem/README.md`, tests.
Do: as D-12 says, the combo box's list content moves to `PVPopupList.swift` as one kit view both callers draw: the card (fill, stroke, radius), the scroller with `pvScrollsRowIntoView`, the row shell (highlight fill, `.onHover` sets the highlight, tap commits, `.accessibilityAction(.default)`), the empty / loading line, and the caller-built rows. Use a `LazyVStack` (the fixed row height sizes the window). `PVComboBox` draws it with no behaviour change (its tests pass unchanged); `PVTextAreaCompletionList` goes and the completion draws the same view. `PVTextAreaCompletionSession.move` uses `PVComboBoxMatch.move` / `firstEnabledIndex` instead of its own arithmetic. Do not touch `PVPopupList`'s click watcher (S16-51 moves both callers onto `.pvPopup`; its map row now names the completion). README ComboBox/TextArea rows say the list view is shared.
Check: `grep -n "surfaceCard\|surfaceSelected\|pvScrollsRowIntoView" macos/App/DesignSystem/Components/TextArea/PVTextArea.swift` prints nothing; `PVComboBoxTests` and `PVTextAreaCompletionTests` pass; scripts/check-pr.sh PASS.

**F-3 — Completion accept is a tested function beside the scan** (from CON-2, MNT-3)
Files: `SourceTypeFormatsModel.swift`, `SourceTypeFormatsSection.swift`, `SourceTypeFormatsModelTests.swift`.
Failing test first: `SourceTypeFormatsModelTests.acceptAddsAClosingBraceOnlyWhenNoneOrPipeFollows` (T-6b): on `{li` caret 3 → `graph.meta.line_number}`, caret after `}`; on `{li}` → no second `}`; on `{graph.meta.line_number|so` → `…|source.meta.line_number}`.
Do: `CitationCompletionContext.accept(ref:in:context:) -> (text: String, caretAfter: Int)` using the type's own `closeBrace` / `pipe` constants; the view's closure calls it, replaces the text, then calls `formats.didComplete` (after the replace, so the render sees the new draft).
Check: the test passes; scripts/check-pr.sh PASS.

**F-4 — The text area's binding follows a cursor replace** (from CON-3)
Files: `macos/ProvenenciaTests/PVTextAreaCompletionTests.swift`.
Failing test first (or green if it already holds; then it is the evidence): host `PVTextArea(text: binding, cursor: cursor)` in an `NSHostingView` in a window, `cursor.replace(range, with:caretAfter:)`, assert the `Binding`'s value equals the new text.
Do: if it fails, that is the plan's Stop condition: stop and report. Do not work around it.
Check: the test passes; scripts/check-pr.sh PASS.

**F-5 — The completion list closes whenever focus leaves; an emptied list is announced** (from UX-1, UX-11)
Files: `PVTextArea.swift`, `PVTextAreaCompletionTests.swift`.
Failing test first: `PVTextAreaCompletionTests` — open, then `insertBacktab:` → session closed; open, `insertTab:` with no rows → session closed; open with rows, narrow to none → `.openedEmpty` (or the empty label) announced.
Do: the router's focus-moving branch calls `completionSession?.close()` before moving focus; forward `textDidEndEditing(_:)` to the session's `close()`; in `evaluate`, an open list that goes to zero rows announces the empty line once.
Check: the tests pass; scripts/check-pr.sh PASS.

**F-6 — Keyboard and VoiceOver on the warnings, the locked card, the preview and the count** (from UX-2, UX-3, UX-5, UX-10)
Files: `SourceTypeFormatsSection.swift`, `PVSubsectionHeader.swift` (meta label only, if needed).
Do: the warning button adds `.pvActivatesOnReturn` with the same action; the locked card keeps `readerLabel` and adds `.accessibilityValue(text.isEmpty ? <no format> : text)`; each preview render row is one element labelled `L10n.SourceTypes.Formats.previewSpoken(form:text:)`; the header meta count gets the spoken count as its label and the identifier `sourceTypes.formats.<form>.count`; the area's `.accessibilityValue(countSpoken)` becomes `.accessibilityHint`.
Check: `grep -rn previewSpoken macos/App` shows a caller; scripts/check-pr.sh PASS.

**F-7 — One origin → words helper** (from MNT-2, UX-8; same-pass cleanup)
Files: `macos/App/Features/Catalog/OriginMarkers.swift`, `L10n.swift`, `Localizable.xcstrings`, `SourceTypeFormatsSection.swift`, and every other origin → copy switch the grep finds.
Do: one `L10n.Origin` function from an origin (and plugin label) to the words `OriginPill` shows; `OriginBadge` / `OriginPill` and the shared-key Select call it, so the Select reads the same words as the completion row's pill. Drop `sourceTypes.formats.origin.*`. Move any other copy the grep finds onto it, unless it is a deliberately short form (`Properties` `originUserShort`): leave that and say why in the commit.
Check: `rg -n "case CatalogOrigin\.(provenencia|user)|CatalogOrigin\.isPlugin" macos/App --type swift` prints only the helper and non-copy uses (gating, sorting); `rg "sourceTypes.formats.origin" macos` prints nothing; scripts/check-pr.sh PASS.

**F-8 — Drop the unused header accessory slot** (from MNT-4; user, 2026-11-20, supersedes that part of D-20)
Files: `PVSubsectionHeader.swift`, `macos/App/DesignSystem/README.md`.
Do: keep `metaTone`; remove the `Accessory` generic, its init, the `where Accessory == EmptyView` extension, its preview and the README words. Note it in the plan's Landed note.
Check: `rg -n "accessory" macos/App/DesignSystem/Components/SubsectionHeader` prints nothing; scripts/check-pr.sh PASS.

**F-9 — `LatestCall` is the one latest-wins mechanism** (from MNT-5; same-pass cleanup)
Files: `docs/macos-client-patterns.md`, `macos/App/Features/ArtifactViewer/ArtifactViewerModel.swift`, its tests.
Do: one line in the patterns doc: a call whose newer run supersedes an older one (search, counts, previews, loads) holds a `LatestCall`; no generation counters. Move `ArtifactViewerModel.load` onto `LatestCall` (`unload()` → `cancel()`); its tests pass unchanged.
Check: `rg -n "eneration \+= 1" macos/App` prints only `OmnibarFocusCoordinator` (a focus request, not a call); scripts/check-pr.sh PASS.

**F-10 — The last warnings stay, dimmed, until the next reply** (from UX-6; user, 2026-11-20, amends D-11)
Files: `SourceTypeFormatsModel.swift`, `SourceTypeFormatsSection.swift`, `SourceTypeFormatsModelTests.swift`.
Failing test first: warnings shown for a draft; `edit` → `shownDiagnostics` still returns them, marked stale (`areDiagnosticsStale(form)` true); the reply for the new draft replaces them.
Do: while the draft differs from `diagnosed.text`, the section still draws the last warnings and the danger border, dimmed (`PVOpacity` or the kit's disabled tone), with the buttons disabled (a stale span is never selected, D-11's reason). Record the amendment in the Landed note.
Check: the test passes; scripts/check-pr.sh PASS.

**F-11 — Warning text matches the ACs** (from CON-4, CON-6; user, 2026-11-20 on AC-1.5)
Files: `SourceTypeFormatsSection.swift`, `L10n.swift`, `Localizable.xcstrings`, the plan § 2 AC-1.5.
Failing test first: `SourceTypeFormatsModelTests` (or an `L10n.CitationFormats` test) — `too_long` with 4,012 characters reads "Too long: 4,012 characters, 12 over" with no quote; `too_long` at ≤ 4,000 characters (stored-byte limit) reads a second message (e.g. "Too many fields for one format").
Do: no quote for `too_long`; add the second message key. Correct AC-1.5's example in the plan to `Unclosed group at “[”`.
Check: the tests pass; scripts/check-pr.sh PASS.

**F-12 — Edits typed during a Save survive its reply** (from CON-5, UX-9)
Files: `SourceTypeFormatsModel.swift`, `SourceTypeFormatsModelTests.swift`.
Failing test first: `anEditDuringASaveSurvivesItsReply` as CON-5 wrote it.
Do: `saved` replaces a draft only when it still equals what `draftForSave()` sent for that form; the saved text still becomes the baseline.
Check: the test passes; scripts/check-pr.sh PASS.

**F-13 — Stronger T-10 and T-11** (from CON-7)
Files: `SourceTypePageModelTests.swift`, `api/ffi/handlers/source_defs_test.go`.
Do: the refused-Save test holds a cached `sourceWorkspace` handle and expects it not stale; the handler's errors table gains a plugin type sent with `Formats` → `sourcetypes.origin_locked`.
Check: tests pass; scripts/check-pr.sh PASS.

**F-14 — Preview scheduling and Source list edges** (from PRF-1, PRF-2, UX-7, UX-14)
Files: `SourceTypeFormatsModel.swift`, `SourceTypeFormatsSection.swift`, `SourceTypeFormatsModelTests.swift`, `macos/App/Platform/FakeStore.swift` if needed.
Failing tests first: page open sends exactly 3 preview calls (`FakeStore` count); with the Sources handle not yet loaded, the "no Source yet" callout is not shown (`showsNoSourceCallout` false); `sources.not_found` on the effective first Source with no explicit pick shows the error instead of a stale preview.
Do: `schedule` does nothing until `loadState == .ready` (load's own `rerenderAll` covers the first render); `previewSources` tells "not loaded" from "empty", and the callout waits for a value; on `sources.not_found`, clear the pick and re-render only if `effectivePickID` changes, otherwise set that form's error; keep a `[String: CatalogCitationPlaceholder]` per form built in `load()` so `placeholder(_:id:)` is a lookup.
Check: tests pass; scripts/check-pr.sh PASS.

**F-15 — Go same-pass cleanups** (from MNT-6, MNT-7, MNT-8)
Files: `core/database/sourcetypes/sourcetypestest/sourcetypestest.go`, `core/database/effects/source_type_search_test.go`, `core/database/sourcetypes/formats_test.go`, `core/database/sourcetypes/sourcetypes.go`, `formats.go`, `core/citationformat/placeholder.go`, `core/database/citationrender/placeholders.go`.
Do: `sourcetypestest.SetFormatsTx(tx, typeID, in, choices…)` used by `SetFormats` and the effects test; `formats_test.go` keeps one local helper used at both sites. `citationformat` exports one constructor for a field placeholder row (`Level`, `Text`, `Ref` built from `metaRef` once), and `citationrender.Placeholders` uses it. One unexported `updateTx(tx, id, label, description, iconKey, stored *Formats)` that `Update` and `UpdateWithFormats` both call.
Check: `rg -n "UpdateWithFormats\(tx, .*t\.Label" core` prints only the helpers; `rg -n 'text\[1:len\(text\)-1\]' core/database/citationrender` prints nothing; go tests pass; scripts/check-pr.sh PASS.

## Round 1 — fix
Head `01829cd31`. Gate PASS (orchestrator run). F-1 – F-13, F-15 done; F-14 done for PRF-1, PRF-2, UX-7; UX-14 **not reproduced** (`aMissingFirstSourceShowsTheErrorInsteadOfAStalePreview` green before any change: the other two forms' `sources.not_found` reach `previewErrors`, and F-1 hides the previews) → UX-14 Rejected. F-4's hosted-binding test was green first run: the plan's binding Stop condition does not fire.
Deviations accepted: F-13 asserts `sourcetypes.ErrLocked` (code `source_types.invalid`), which `editableTx` returned before this PR ("as today", plan § 6); the plan's word `origin_locked` named Delete's error. F-3 adds `PVTextAreaCompletion.didAccept`, run after the replace. F-2: `PVPopupListCard` takes the caller's stack (the combo box measures unequal rows); completion rows gain hover highlight. F-6 adds `PVSubsectionHeader` `metaLabel` / `metaIdentifier`. F-7: `OriginBadge` keeps its short badge words; the Properties inspector's plugin row now reads the plugin words. F-10: only the warning rows dim; the border keeps its danger tone. F-15: `updateTx` takes the read `existing` row.
PRF-1, PRF-2 (minor, no round 2 for SEC+PRF): read in `d8cd8e5a5` and `2729f59f4` — `schedule` waits for `.ready` with `openingThePageSendsExactlyOneRoundOfPreviews`; completion uses `LazyVStack`; `placeholder(_:id:)` is a dictionary lookup → **Resolved**.

## Round 2 — review
Reviewers: CON, MNT, UX (each had a Fix-now blocker or major). Not sent: SEC+PRF (minors only, resolved above). Scope `7efe84770...01829cd31`.

| ID | Lens | Round-1 finding | Result |
| --- | --- | --- | --- |
| CON-1, UX-4 | CON, UX | blocker · failed preview | Resolved (both reviewers) |
| MNT-1 | MNT | blocker · second popup list | Resolved |
| CON-2, MNT-3 | CON, MNT | major · accept untested | Resolved |
| CON-3 | CON | major · binding / § 10 | Resolved for code (`aHostedAreasBindingFollowsACursorReplace`); § 10 and the board check are the user's |
| UX-1, UX-2, UX-3 | UX | major · keyboard and VoiceOver | Resolved |
| MNT-2, UX-8 | MNT, UX | major · origin words | Resolved |
| MNT-4, MNT-5 | MNT | major · header slot, `LatestCall` | Resolved |

No new findings above nit. Minors fixed in round 1 (CON-4 – CON-7, UX-5 – UX-7, UX-9 – UX-11, MNT-6 – MNT-8, PRF-1, PRF-2): read in the fix commits and in the round-2 sweeps (F-10, F-12, F-11, F-13 called out by CON and UX) → Resolved.

Nits (logged): `UX-15 · PVSubsectionHeader.swift:50 · empty accessibilityIdentifier set on callers that pass none` · `UX-16 · L10n.swift:5121 · origin.badge.user comment still says "Origin badge"` · `MNT-16 · SourceTypeFormatsSection.swift:311 · third literal 0.42 disabled opacity; no kit token` · `MNT-17 · PVTextArea.swift PVTextAreaCompletionRows · same check passed to isActive and isSelected`

## Result
Gate PASS (`5f07ba66c`, `origin/main` unchanged at `24bd80e70`) · CI green · open: none · follow-ups: none · to user: MNT-4 (dropped slot), MNT-9 (kept D-7), UX-6 (dimmed warnings), CON-4 (AC-1.5 text) — all answered 2026-11-20 · manual check § 10 and board comparison: the user's

## User addition — seed (2026-11-20)
The user asked, after the report, for the seed fix on this PR: the three certificate types' source-list format needs `{source.meta.jurisdiction}` (outside any group, `certificateFormats` in `core/database/sourcevocab/registry.go:41`), but their Source suggestions (`registry_suggestions.go:13,16,19`) do not list `jurisdiction`, so the type page never offers it and a Source without it renders `. Birth certificates.`. Gap from S15-19, on `main`. The user updates their dogfood project by hand (no migration).

**F-16 — Every field a seeded format needs is suggested at its level**
Files: `core/database/sourcevocab/registry_suggestions.go`, `core/database/sourcevocab/registry_test.go`. Skill: `add-seeded-vocabulary`.
Failing test first: `TestSeededFormatsNeedOnlySuggestedFields` (table over every seeded type) — parse the type's three formats, take `citationformat.Requirements` (needed only, not used), and for each needed meta-field requirement expect at least one of its options (`level`, `key`) to be in that type's suggestions at that level. Fails today on `birth_certificate`, `marriage_certificate`, `death_certificate` (Source · `jurisdiction`).
Do: add `"jurisdiction"` to the three certificate types' `LevelSource` suggestions (after `creator`, as `church_register` orders it). If the test finds other seeded types with the same gap, add the field the format reads to that type's suggestions at that level, the same way, and list each in the report. Built-ins (`source.title`, `source.date`, `citation.page`, …) are not suggestions; skip them. Do not change any format text. Update any golden or test that counts suggestions.
Check: the test passes; `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcevocab/...` passes; scripts/check-pr.sh PASS. Add a line to the plan's Landed note ("user addition: the certificate types suggest Jurisdiction").

**F-16 stopped, then amended (user, 2026-11-20).** The implementer pushed `da54e7c63` (certificates suggest `jurisdiction`; `TestSeededFormatsNeedOnlySuggestedFields`; `TestSeedSuggestionsFollowFormats` given an exemption, `otherFormFields`), then stopped: that contradicts S15-19 D-4 and map § 6.8 "Suggestions" (suggestions are derived from the full format only). Head `da54e7c63` fails go-test (`TestUpdateSourceType`, `TestListWorkspacesAnnotations`, `TestSeedAnnotations`); the count updates are in `stash@{0}`. Asked the user: **widen the rule** (user, 2026-11-20). Amended F-16:
- The § 6.8 rule becomes: each type suggests every metadata field its full format uses (as before, same levels, order and two exceptions), **then** every field its list or short format needs outside any group that the full format does not use, at the field's usual level, in the order the list format, then the short format, first needs it. Fields that only optional groups of the short or list format read (`short_title`, `author_sort`, `coverage`) stay unsuggested.
- `TestSeedSuggestionsFollowFormats` derives the widened lists and checks exact equality (no exemption helper); `TestSeededFormatsNeedOnlySuggestedFields` may stay as the readable guard or fold into it, the implementer's call.
- The certificates' Source suggestions are therefore `creator`, `document_number`, `volume`, `repository`, `jurisdiction` (appended, not after `creator`). Any other type the derivation changes (expected: none; S15-19 flagged `statute`'s list format too) is listed in the report.
- Docs: map § 6.8 "Suggestions" states the widened rule with "(user, 2026-11-20, S15-17)"; `docs/seeded-vocabulary.md` § 2.3 says the same in place of the "wherever the type lists it" wording; the S15-17 Landed note names the amendment of S15-19 D-4.
- Apply `stash@{0}` (count updates) and adjust any order the append changes.

## User addition — fix
Head `de6f42186`. Gate PASS (orchestrator run). F-16 done: `derivedSuggestions` derives the widened rule and `TestSeedSuggestionsFollowFormats` checks exact equality (exemption removed); `TestSeededFormatsNeedOnlySuggestedFields` kept as a guard. Only `birth_certificate`, `marriage_certificate` and `death_certificate` changed (Source · `jurisdiction`, appended); `statute` unchanged (a chain whose option the full format uses adds nothing). Counts: handler 4 → 5, unsuggested heads 32 → 29. Map § 6.8, `docs/seeded-vocabulary.md` § 2.3 and the Landed note record the amendment of S15-19 D-4. Read by the orchestrator (seed data and its test); no review round, by the two-round cap and the size of the change.

## User addition 2 — certificate notes (2026-11-20)
The user asked for Jurisdiction ahead of Creator in the certificates' full and short notes, for all three certificate types (one shared `certificateFormats`), as a **needed** field (as the list format already reads it).

**F-17 — The certificate notes lead with Jurisdiction**
Files: `core/database/sourcevocab/registry.go` (`certificateFormats`), `core/database/sourcevocab/registry_suggestions.go`, `core/database/sourcevocab/testdata/seed-citations.txt`, any test that counts or orders certificate suggestions or unsuggested heads, map § 6.8 "Formats" (certificate rows), the S15-17 Landed note.
Do: Full becomes `{source.meta.jurisdiction}, [{source.meta.creator}, ]` + word + (the rest unchanged); Short becomes `{source.meta.jurisdiction}, [{source.meta.creator}, ]` + word + (the rest unchanged); List unchanged. Re-derive the three certificates' Source suggestions by the rule (`TestSeedSuggestionsFollowFormats`): `jurisdiction` now leads (`jurisdiction`, `creator`, `document_number`, `volume`, `repository`). Regenerate the render goldens by the repo's own update path (no hand edits), and check the full-data rows read "Calder County, Westmark, Calder County Clerk, birth certificate no. …" and the bare rows now miss Jurisdiction in all three forms.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcevocab/... ./core/database/sourcemetadata/... ./api/ffi/handlers/...` passes; scripts/check-pr.sh PASS.

## User addition 2 — fix
Head `5f07ba66c`. Gate PASS (orchestrator run). F-17 done: certificate Full and Short lead with `{source.meta.jurisdiction}, `; Source suggestions re-derived to `jurisdiction, creator, document_number, volume, repository`; goldens regenerated with `-update` (full row: "Calder County, Westmark, Calder County Clerk, birth certificate no. 1880-0412 …"; bare rows start ", birth certificate", as the list's bare ". Birth certificates." does, since Jurisdiction is needed). One fixture changed beyond the file list: `metadataSuggestionFixture` (`api/ffi/handlers/sources_test.go`) dismissed the first suggestion, now the needed `jurisdiction`, which cannot be dismissed; it now picks `creator`. Map § 6.8 and `docs/seeded-vocabulary.md` § 2.3 note no seeded type needs the appended case today. Read by the orchestrator; no review round.

## CI — Go red (2026-11-20)
`TestLargeSourceBudgets/after_a_handle_commit` (`core/database/promotealign`, untouched by this PR) failed on CI twice on this branch (`da54e7c63`: 48.5 ms vs 46.2 ms; `391461938`: 35.4 ms vs 33.5 ms): the ratio check "after a commit within 1.5 × a warm proposal", over 3 samples. Measured at the map's fixture locally, 3 runs each: base `24bd80e70` 16.9 – 17.2 ms against budgets 25.5 – 26.1 ms; head 17.0 – 18.0 ms against 25.5 – 27.5 ms. No regression; runner noise on a ratio budget, pre-existing. The user raised the ratio to 1.75 × for the Blacksmith CI runners (2026-11-20): `perf_test.go` both ratio checks and Spike 16 bar 10 / S16-32 Check. Also removed `core/database/sourcevocab/registry_suggestions.go-E`, a BSD `sed -i -E` backup committed by mistake in `da54e7c63`.
