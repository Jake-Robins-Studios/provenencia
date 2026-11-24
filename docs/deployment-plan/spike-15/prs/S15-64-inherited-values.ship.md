# Ship log — S15-64 Boards show inherited values

**Plan:** [`S15-64-inherited-values.md`](S15-64-inherited-values.md) · **Branch:** `s15-64-inherited-values` · **PR:** #959
**State:** ready

## Round 0 — implement
Head `a623fb01e`. Gate PASS. Deviations, accepted: `Nearest` takes a `uuid.UUID` (D-1 over the § 6 table); two strings use numbered placeholders; T-2 dismisses `schedule`, since Provider is needed under its formats and cannot be dismissed. Board link not opened; § 10 not run (the user's).

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. Skipped: none.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1, UX-1 | CON, UX | blocker | The suggestion row's `pvSheetInnerEdit(false)` masks the override editor's | Fix now → F-1 | verified: an outer `.preference` replaces its subtree's (two probes); `PVSheet.swift:205` is a plain `.preference` |
| MNT-1 | MNT | major | The override editor is a second copy of `MetadataBoardTextEditor` | Fix now → F-1 | same-pass cleanup; read both |
| CON-2, UX-2 | CON, UX | major | VoiceOver text, link and hint do not match IH-8 | Fix now → F-2 | plain in `inheritedText`; an optional `editHint` on `PVInlineEdit` is a parameter, not a new primitive |
| UX-3 | UX | major | Return does not save an override | To user → F-1 | user (2026-11-23): Return stays a newline, as saved rows; drop the dead `onSubmit`; correct IH-2 and § 10 |
| SEC-1 | SEC | major | A Source value is copied into every board with no total bound | Fix now → F-3 | verified in `inheritedProto`, `Display`; measured 120 – 524 MB replies |
| MNT-2 | MNT | major | `Display` and `printed` are two ladders | Fix now → F-3 | both are this PR's; § 6 Codebase fit says one calls the other |
| CON-3, UX-4 | CON, UX | minor | Every suggestion row became top-aligned | Fix now → F-1 | contradicts D-11 "is today's" |
| CON-4 | CON | minor | No test of open, save, cancel of an override | Fix now → F-4 | T-8 goes through `board.add` |
| MNT-3 | MNT | minor | `isURL` repeats what `openURL` says | To user → F-1 | user (2026-11-23): drop it, departing from D-8's signature |
| PRF-2, UX-6 | PRF, UX | minor | The Overrides caption wraps without limit | Fix now → F-1 | no `lineLimit` |
| PRF-1 | PRF | minor | Page reload per Source value save; `applySavedMetadata` comment false | Comment: fix now → F-4. Narrower read: Dropped (user, 2026-11-23) | 3.2 ms at Scale, budget 100 ms; Artifacts with files not measured |
| MNT-4, CON-5 | MNT, CON | minor | Reads test comment says only one read reloads | Fix now → F-4 | plain |

Nits (logged): `MNT-5 · sourcemetadata.go:1116 · place and annotation both parse the field id` · `UX-5 · override editor caption has no identifier` (goes with F-1)

### Fix plan 1
**F-1 — One inline editor for saved and inherited rows** (CON-1, UX-1, MNT-1, MNT-3, UX-3, CON-3, UX-4, PRF-2, UX-6, UX-5)
Files: `macos/App/Features/Sources/MetadataBoardView.swift`, plan and brief text. Skill: `add-ui-component`.
Do: make `MetadataBoardTextEditor` the only `PVInlineEdit` + `PVTextArea` editor in the file. The caller supplies the edit label, the resting display and the resting trailing control (trash or dismiss). It keeps its buffer, typed report and `overridesCaption` (identifier `.overrides`), and sets the field label as the text area's accessibility label on both. Split the suggestion row: only the branch with no `inherited` owns the quick-add `PVInput`, its focus, local draft, `.pvSheetInnerEdit` and `.onExitCommand`; nothing around the inherited row's editor sets `pvSheetInnerEdit` or handles Escape. The card chrome stays shared. The plain row's `HStack` is centred as on the base; the inherited row is `.top` with the label's `topPadding: 6`, as `savedRow`. Do not draw the row's error twice. Remove the dead `.onSubmit { onSave(draft) }` from the text area (Return is a newline). Drop `isURL` from `MetadataValueText`; a non-nil `openURL` is the one link test. The Overrides caption is limited to two lines with tail truncation and the whole text on hover; the caption's doc comment matches. IH-2 in `design/archive/S15-D33-inherited-values.md` ("Save (or Return)", and its line 87) and the plan's § 10 step 2 say Save only, as the user decided; note it and the `isURL` departure in the plan's Landed note.
Check: `rg -n "PVInlineEdit\(|PVTextArea\(" macos/App/Features/Sources/MetadataBoardView.swift` prints one of each (plus any already there for the add row); `rg -n "isURL" macos/App` has no `MetadataValueText` hit; check-pr PASS.

**F-2 — VoiceOver says what IH-8 says** (CON-2, UX-2)
Files: `MetadataBoardView.swift`, `PVInlineEdit.swift`, `L10n.swift`, `Localizable.xcstrings`. Skills: `add-ui-component`, `add-localized-string`.
Do: the inherited value's label is "Provider, Inherited from Source: Ancestry" (field label included; hide the row's visible label from VoiceOver on an inherited row). A link row stays a button and speaks the same label. The "From Source" caption stays hidden, since both branches now say it. Move `metadataInheritedHint` to the pencil through an optional edit hint on `PVInlineEdit` (default none, every other caller unchanged). Fix the doc comment.
Check: check-pr PASS; § 10 step 7 reads true against the code.

**F-3 — One value-printing step, bounded for boards** (SEC-1, MNT-2)
Files: `core/citationformat/render.go`, `render_test.go`, `api/ffi/handlers/metadata.go`, `metadata_test.go`.
Failing test first: `TestDisplay` rows: text, unknown text and a supplied text over the board limit → cut to the limit (a supplied value keeps its closing bracket, no rune split); `TestMetadataBoardInherited` (or a new test beside it): a Source `url` longer than the limit → `open_href` "" while `display_text` is cut; a url within it → unchanged.
Do: one unexported step holds the unknown text, date or truncated text, and `marked`; `printed` and `Display` both call it and `printed`'s results do not change. `Display` is bounded by a new documented constant in `citationformat` (4096 bytes), unknown text included. `inheritedProto` sends no `open_href` longer than the same constant; never cut a link. Correct the plan's § 6 "Untrusted size" line in the Landed note. T-3's `MaxRenderedBytes` row moves to the new limit.
Check: the tests pass; `rg -n "CitationDisplay\(" core/citationformat/render.go` prints one line; the existing render tests are untouched and green.

**F-4 — Tests and comments** (CON-4, PRF-1, MNT-4, CON-5)
Files: `macos/ProvenenciaTests/MetadataDraftHostTests.swift`, `SourcePageModelTests.swift`, `macos/App/Features/Sources/SourcePageContext.swift`.
Do: a test of the inherited entry through the board: `beginEdit` → `editingFieldID` set, draft empty; `cancelEdit` → nil, host unchanged; `beginEdit`, draft "FamilySearch", `save` → own value, `editingFieldID` nil, `inherited` kept; `beginEdit` on a suggestion with nothing inherited → nil. `applySavedMetadata`'s comment says a Source write also reloads the page through `inherited_values`. The reads test's comment says either read reloads the page, with no D-16.
Check: the test fails with `beginEdit` put back to `savedEntry`, passes now; check-pr PASS.

## Round 1 — fix
Head `0e298a4a3`. Gate PASS. F-1 to F-4 done. Accepted: F-1 and F-2 in one commit; `printed` cuts unknown text at `MaxRenderedBytes`, as the writer already did.

## Round 2 — review
CON, MNT, UX and SEC+PRF, fix commits only. CON-1, CON-2, MNT-1, MNT-2, UX-1, UX-2, UX-3 and SEC-1 Resolved; no new blocker. Minors read by the orchestrator: CON-3, UX-4, UX-5, UX-6, PRF-2, MNT-3, MNT-4, CON-4, CON-5 and PRF-1's comment Resolved.

## After ready — user change
Metadata board swapped to the right column on both sheets, per the redrawn board. Written by the orchestrator on the user's request; no review round, the user reviews it.

## Result
Gate PASS · CI green (on the commit before this line) · open: none · follow-ups: none (PRF-1's narrower read dropped by the user, 2026-11-23) · to user: UX-3 and MNT-3, answered 2026-11-23; § 10 manual check
