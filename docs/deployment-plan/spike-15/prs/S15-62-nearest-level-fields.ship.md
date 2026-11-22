# Ship log — S15-62 A format reads a field from the nearest level

**Plan:** [`S15-62-nearest-level-fields.md`](S15-62-nearest-level-fields.md) · **Branch:** `s15-62-nearest-level-fields` · **PR:** #950
**State:** ready

## Round 0 — implement
Head `6c4eb5368`. Gate PASS (orchestrator run, against `8fcb625e5`). Report: no stop. Deviations: `itemFields` deleted with `usualLevel`; `TestSeedAnnotations` rebuilt for D-10 (`unsug` lists every unsuggested head, `omitted` gone, new `listOnly`); `TestGetDraftMetadataBoard` census artifact expects suggestions then unsuggested heads; chain-by-level render cases replaced by field-and-built-in chains, `census_item_on_source` removed (covered by T-6 and `TestRenderNearestLevel`); manual check (§ 10) not run in the app.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. Skipped: none (UX: `macos/App/**`, `Localizable.xcstrings`; SEC+PRF: migration `000069.sql`, `api/ffi/handlers`, `core/database/**`, parses stored formats).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| UX-1 | UX | blocker | Unsuggested empty heads draw nowhere and leave the add-field picker | Fix now → F-1 | verified: `MetadataBoardModel.saved` keeps `hasValue`, `suggested` keeps `!hasValue && suggested`, `fieldComboOptions` drops every entry; D-10 now emits such heads on every board (census Source loses Provider from the picker, US-1's own scenario). The plan's Brief line ("Boards gain rows drawn by the existing board row, per D-10") and AC-4.3 expect them drawn |
| CON-1 | CON | major | Chain dedupe by `Target` drops a built-in option (`{source.date:year\|source.date}`) | Fix now → F-2 | verified: `parse.go:358` compares `c.Target == ref.Target`; `Ref.Option` is outside `Target`. Reviewer's probe: base renders "5 March", head renders nothing |
| UX-2 | UX | minor | `unknown_level` copy steers a bare `{provider}` toward a level | Fix now → F-3 | minor in a string file this PR changes; `option()` returns `CodeUnknownLevel` for any first part that is not `meta` or a level |

Nits (logged): `MNT-1 / CON-2 · core/vocabkey/vocabkey.go:24 · rewrap the Level doc comment` · `MNT-2 · core/database/sourcevocab/registry_test.go:48 · derivedSuggestions says "in order" but the test compares sets` · `MNT-3 · macos/App/Platform/GoStore.swift:850 · optional raw-value parse appears twice; helper on a third` · `UX-3 · Localizable.xcstrings sourceTypes.formats.sectionHint · lists the farthest level first` · `UX-4 · L10n.swift:13055 · "Missing: Title on the Source, or Title" reads twice`

### Fix plan 1

**F-1 — An empty field head draws as a row and stays out of the picker only while drawn** (from UX-1)
Files: `macos/App/Features/Sources/MetadataBoardModel.swift`, `MetadataBoardView.swift` (only if needed), `MetadataDraftHost.swift`, tests under `macos/ProvenenciaTests`. Skill: `add-swift-test`.
Failing test first: a `MetadataBoardModel` test whose host returns an entry with `hasValue: false, suggested: false` (a head D-10 emits): it must appear in the empty-row group the board draws, and it must not be lost from both the drawn rows and `fieldComboOptions`. A second test: after `moveSaved`, that entry is still present (today `moveSaved` rebuilds `savedRows + suggested` and drops it).
Do: the empty group (`suggested`) holds every entry with `!hasValue`, suggested or not, drawn by the existing `MetadataBoardSuggestionRow`; update its doc comment. `fieldComboOptions`' `used` set then equals the drawn rows. `MetadataDraftHost`: `shown`, `clear` and `dismissSuggestion` treat an empty head the read returned like an empty suggestion (clear empties it rather than removing it; dismiss removes it and records it). Check on the Go side that `DismissSuggestion` of an unsuggested, not-needed head hides it on the next read (`TestDismissNeeded` or a new subtest in `sourcemetadata_test.go`); if it does not, stop and report. No new component, no new copy, no change to the group's heading (S15-63 makes every head a suggestion).
Check: the new tests pass; scripts/check-pr.sh PASS.

**F-2 — A chain keeps an option that differs only in its option** (from CON-1)
Files: `core/citationformat/parse.go`, `core/citationformat/render_test.go`, `core/citationformat/requirements_test.go`.
Failing test first: `TestRender` (or a new `TestRenderChainKeepsAnOptionThatDiffers`) — `{source.date:year|source.date}` with a point date of 5 March and no year renders "5 March". Run it red first.
Do: in `(*parser).placeholder`, dedupe on `c.Target == ref.Target && c.Option == ref.Option`. Update D-4's comment at that line to say so. Add a `TestRequirements` case: `{meta.#X|meta.#X}` is still one requirement with one target.
Check: both tests pass; AC-3.1 tests still pass; scripts/check-pr.sh PASS.

**F-3 — `unknown_level` names the field form too** (from UX-2)
Files: `macos/App/Resources/Localizable.xcstrings`, `macos/App/Platform/L10n.swift` (comment only if it quotes the text). Skill: `add-localized-string`.
Do: change the English value of `citationFormats.diagnostic.unknown_level` to "Not a field or a level: write meta. and the field, or source, artifact, graph or citation before a built-in". If `docs/citation-formats.md` quotes this text, update it there too. No code change.
Check: scripts/check-pr.sh PASS (localizable).

## Round 1 — fix
Head `45dd28ffb`. Gate PASS (orchestrator run). F-1 done (`MetadataBoardModel.suggested` holds every empty row; `MetadataDraftHost` treats an empty row it opened like a suggestion; Go `TestDismissNeeded` "a used unsuggested field hides when dismissed" already covers the dismiss). F-2 done (red first: `TestRender/chain_keeps_an_option_that_differs`). F-3 done; the implementer also updated `L10n.swift`'s `defaultValue` to match the catalog (the fix plan allowed only a comment; a stale default would be wrong, accepted). UX-2: **Resolved** (orchestrator read `050c79364`, `45dd28ffb`).

## Round 2 — review
Reviewers: UX (UX-1 blocker), CON (CON-1 major). Scope `6c4eb5368...45dd28ffb`.
UX-1: **Resolved** (UX round 2: drawn, out of the picker only while drawn, kept through reorder, clear and dismiss; tests named in its report). CON-1: **Resolved** (`parse.go:358-362` keys on Target and Option; `TestRender/chain keeps an option that differs`, `TestRequirements` `{meta.x|meta.x}`). No new blocker.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| UX-5 | UX | minor | "Suggested by this type" heading and "Dismiss the suggestion for %@" now sit over unsuggested heads (reviewer context note) | Later PR → S15-63 | written into S15-63's map scope entry (Check line); S15-63 makes every head a suggestion |

Nits (logged): `CON-3 · docs/citation-formats.md:23 · "A target repeated in a chain counts once" should say "with the same option" after F-2; plan D-4 cell likewise`

## Result
Merged `origin/main` @ `00679ff1c`; gate PASS. CI <pending> · open: none · follow-ups: none · later PR: UX-5 → S15-63 · to user: —
