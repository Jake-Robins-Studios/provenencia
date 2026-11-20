# S15-17 — The format editor

**Status:** Landed in [#924](https://github.com/Jake-Robins-Studios/provenencia/pull/924) (2026-11-20)
**Spike / slice:** Spike 15 · Slice 5 — Person page date and the format editor
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D16](../design/archive/S15-D16-source-type-citation-formats.md), board agreed 2026-11-20
**Board:** [Claude Design — Source Type Page](https://claude.ai/artifact/42ZuWus4ynyz7xUDwcF6zG), artboard *S15-D27 · S15-D6 · S15-D7 · S15-D16 · Source type page board*, the frames named "S15-D16" in its menu (D16-1a, D16-1b, D16-2, D16-2b, D16-2c, D16-3 – D16-7, D16-7b, D16-8, D16-9, D16-10, D16-10b, D16-11 – D16-13, D16-14a, D16-14b, D16-15) and its decision notes (CF-3, CF-4, CF-7 · CF-9, Copy added, CF-11, Handoff), drawn by *Source type page · component* (`Source-Type-Page.dc.html`); the implementer opens the link. The board's "small stand-in for the engine" is drawing only: the PR uses Go's parser, messages and render. **Not binding from the board:** its CF-3 note's ranking ("the type's own suggested fields rank first"; after `|`, "the same field at the other levels first") and the row order frames D16-2 and D16-2b show; rows follow D-21 (the typed query only; user, 2026-11-20)
**Depends on:** S15-12 (landed [#856](https://github.com/Jake-Robins-Studios/provenencia/pull/856)), S15-15 (landed [#871](https://github.com/Jake-Robins-Studios/provenencia/pull/871)), S15-16 (landed [#914](https://github.com/Jake-Robins-Studios/provenencia/pull/914)), S15-18 (landed [#877](https://github.com/Jake-Robins-Studios/provenencia/pull/877)), S15-48 (landed [#848](https://github.com/Jake-Robins-Studios/provenencia/pull/848)), S15-D16
**Blocks:** —
**Branch:** `s15-17-format-editor`
**Version bump:** minor, 0.29.0 → **0.30.0** (if `main`'s `VERSION` is no longer 0.29.0 when you rebase, the next minor after it): a new editor on the type page; `UpdateSourceType` carries formats, `UpdateCitationFormats` goes, and method 126 becomes `ListCitationPlaceholders` ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-catalog-query`](../../../../.agents/skills/add-catalog-query/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`use-catalog-session`](../../../../.agents/skills/use-catalog-session/SKILL.md), [`add-audit-scope`](../../../../.agents/skills/add-audit-scope/SKILL.md) (one change per row), [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md) (the registry's `invalidateOn`, `session.derived`), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests), `.cursor/rules/ffi-handlers.mdc`, `.cursor/rules/catalog-queries.mdc`, `.cursor/rules/macos-client.mdc`, `.cursor/rules/swift-tests.mdc`, `.cursor/rules/versioning.mdc`; `docs/macos-client-patterns.md` §2.5 (models keep form state; views derive with `session.derived`) and §4 (AppKit in a small wrapper)
**Context:** working rules "Citation formats are data on the Source type", "Every placeholder names its level; fallback is written", "Built-in placeholders are one table", "One engine, in Go", "One render request for previews and the list entry", "Requirements need a refresh signal; renders do not", "Formats name fields by id", "A Source type has its own page", "One window; nothing is built for a second" ([`../deployment-plan.md`](../deployment-plan.md#working-rules)); [`../evidence-explained-citation-map.md`](../evidence-explained-citation-map.md) § 6.3 "The editor"; [`docs/citation-formats.md`](../../../citation-formats.md) (syntax, Storage, Rendering, Diagnostics); landed plans [`S15-15-type-stores-citation-formats.md`](S15-15-type-stores-citation-formats.md) (D-3, D-11, **Next adds**), [`S15-16-citations-render.md`](S15-16-citations-render.md) (D-9, D-10, D-14 and its Landed note), [`S15-12-type-suggestions-at-each-level.md`](S15-12-type-suggestions-at-each-level.md) (D-6: the list header), [`S15-18-copy-source-type.md`](S15-18-copy-source-type.md) (the formats read), [`S15-33-artifact-update-saves-metadata.md`](S15-33-artifact-update-saves-metadata.md) (one Save is one write: an update request carries an optional draft)
**Planned:** 2026-11-20 against `main` @ `34c2b61` (compare with `origin/main` after `git fetch origin main`)
**Review:** [`S15-17-format-editor.review.md`](S15-17-format-editor.review.md) — Fits with changes / Ready with changes, 2 rounds (2026-11-20); no blocker open, nothing to user

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

A researcher edits a Source type's three citation formats (full note, short note, source list) on the type's page. Typing `{` in a format opens a list of the fields and built-ins at the cursor that narrows as the researcher types and puts the whole placeholder in on Return (user, 2026-11-20); a character count against the 4,000 limit, and the engine's warnings listed under it; clicking a warning selects the text it is about. A preview under the formats fills each form in for a Source of the type as the researcher types. One Save writes the Details and the formats in one engine write, and leaving with unsaved formats asks. This is bar 5's first half ("Editing the census full format on its Source type page updates a live preview against a real Source").

**Why now.** The engine (S15-14), storage (S15-15), the preview call (S15-16), the type page with its suggestion lists (S15-48, S15-12) and Copy (S15-18) have landed. No screen shows a format yet: the seed (S15-19) writes them and nobody can change them.

**What stays.** Details' fields, the side column's suggestion lists, the header with Copy and Delete, the types list and both dialogs. `GetCitationFormats` and `RenderCitations` keep their wire. Swift never validates or renders a format or decides which level a form allows (rule "One engine, in Go"): warnings, renders, missing fields and the completion rows come from Go; Swift only finds where the placeholder being typed starts (D-21).

## 2. User stories

**US-1.** As a researcher, on an editable type's page, I edit its three formats and save them with Details' Save, so its citations change.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Census's page opens | Under the section title and hint, the syntax strip: `{ }` a field · `|` or, if empty, the next · `[ ]` drops out when empty · `* *` italic · `\` a literal { [ * or \; then the section shows Full note, Short note and Source list with the stored text by key (`{source.meta.jurisdiction}`, never `#<id>`), each with "used / 4,000" |
| AC-1.2 | Append ` Test.` to the full note | Save changes and Revert enable; Revert puts the stored text back and disables them |
| AC-1.3 | Append ` Test.` to the full note, Save | One `UpdateSourceType` carrying the three forms; toast "Citation formats saved"; reopening the page shows the new text |
| AC-1.4 | Change Label to "Census (US)" and the short note, Save | One `UpdateSourceType` carrying both; one revision; toast "Source type updated" / "Census (US) and its citation formats are saved." |
| AC-1.5 | Delete the `]` of `[, p. {citation.page}]` in the short note and change Label, Save | Nothing saves (no revision; Label is not saved either); the short note shows "Unclosed group at “[”"; the Callout "Fix the marked formats, then save." shows beside Save; every edit stays |
| AC-1.6 | Change only Label, Save | `UpdateSourceType` without formats; today's toast; the formats are untouched |
| AC-1.7 | Unsaved full note, then Back | Today's discard confirm; Discard leaves and drops it; Keep editing stays |
| AC-1.8 | A full note of 4,012 characters (`unicodeScalars.count`) | Its count reads "4,012 / 4,000" in the danger tone; the warning reads "Too long: 4,012 characters, 12 over" |

**US-2.** As a researcher, I insert a field without remembering the syntax.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | In the full note, type `{line` | A list opens under the cursor: Line at Evidence graph, Source and Artifact, each with its level Chip and placeholder (`graph.meta.line_number`), first row highlighted; the list narrows with each character |
| AC-2.2 | Then Return (or Tab, or a click on the row) | `{line` becomes `{graph.meta.line_number}`; the cursor sits after the `}`; the list closes |
| AC-2.3 | Type `{` in the source list | Only Source-level rows: Title, Type, Date, "Date, year only", then the fields; no Artifact, Evidence graph or Citation row |
| AC-2.4 | Two fields hold the key `page`; type `{page`, choose the researcher's Page at Source | The two rows read the same label with different origin pills; `{source.meta.page}` goes in; no `ambiguous_field` warning follows, because the pick recorded its field |
| AC-2.5 | Type `{graph.meta.line_number|so` then Return on Line at Source; type `\{` ; type `{li` then Escape; type `{li` then a space; type `{li` before an existing `}` and Return | The chain becomes `{graph.meta.line_number|source.meta.line_number}`; `\{` opens no list; Escape closes it and `{li` stays; the space closes it; with a `}` already following, no second `}` is added |

**US-3.** As a researcher, I see what is wrong with a format where it is wrong.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Type `{source.meta.jurisdicton}` in the short note and stop typing | Within a moment: "No field has the key jurisdicton at “jurisdicton”"; the area's border is danger |
| AC-3.2 | Click that warning (or Tab to it and press Return) | The text area takes focus with `jurisdicton` selected |
| AC-3.3 | Type `{citation.page}` in the source list | "The source list reads the Source only at “citation.page”" (`not_in_list_form`, spanning the option) |
| AC-3.4 | Write `{source.meta.page}` while two fields hold `page` | The `ambiguous_field` warning carries a Select of the two Page fields; choosing one clears the warning, and Save stores that field |
| AC-3.5 | Fix the text so it parses | The warning lines go and the border returns to normal |
| AC-3.6 | Type with no Sources of the type (Letter) | Warnings still show (the preview call with no target) |

**US-4.** As a researcher, I see each form filled in for a real Source of the type as I type.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | Census's page opens; Sources "1880 census, Calder County" (latest revision) and "1870 census, Calder County" | "Preview with" picks the 1880 Source; each format's preview, above its text area, shows its render with italics |
| AC-4.2 | Edit the full note | A moment after typing stops, the full note's preview shows the render of the unsaved text; the other two do not re-render |
| AC-4.3 | Pick the 1870 Source | All three previews re-render for it |
| AC-4.4 | The picked Source has no `jurisdiction` | Under the full note's preview: "Missing: Jurisdiction on the Source" |
| AC-4.5 | A Source with no Citations | Full and short render from the Source alone: Artifact, Evidence graph and Citation placeholders are empty and their groups drop (D-2) |
| AC-4.6 | The short note has a warning | Its preview reads "Not shown while the format has a warning"; the full and list previews still render |
| AC-4.7 | The preview call fails | `PVRetryCallout` under "Preview with", the three previews hidden; Try again renders again |
| AC-4.8 | The Sources list loads after the page | The preview renders with no target (warnings only) until the list lands, then picks the latest Source and renders all three |

**US-5.** As a researcher on a plugin's type, I read its formats and preview them, and cannot edit them.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-5.1 | Grave memorial (plugin, locked) with a full note only | Full note read only in a sunken Card; the other two read "No format"; no completion, no count, no Save or Revert; the preview renders the stored full note |

**US-6.** As the boards, after a format save, every cached Source page re-reads its requirements.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-6.1 | Two Source pages cached, then a Save carrying formats | Both `sourceWorkspace` keys are invalidated by `.changedCitationFormats(typeId:)`; a Details-only Save does not apply it |

**US-7.** As the engine, I take a Source target for every form, a format with no target, one write for a type's details and formats, and the completion rows for a form.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-7.1 | `RenderCitationPreview` form `full`, Source target whose graphs hold two Citations | Renders against the Citation with the smaller id (the older UUIDv7) |
| AC-7.2 | Form `short`, Source target with no Citation | Renders from the Source alone: Source values answer; `{citation.page}` is empty |
| AC-7.3 | Form `full`, no target, format `[, p.` | Diagnostics only (`unclosed_group`); empty render, no missing |
| AC-7.4 | Form `full`, no target, format `{source.title}.` | Empty render, no missing, no diagnostics, no error |
| AC-7.5 | No target, no format | `citations.invalid` |
| AC-7.6 | A Citation target that is not in the catalog with format `[` | The diagnostics come back (the format is checked first); with format `{source.title}` → `citations.not_found` |
| AC-7.7 | `UpdateSourceType` with a new label and formats | One revision; one `source_types` change holding the label and the format columns; the reply carries the type and the formats by key |
| AC-7.8 | `UpdateSourceType` with formats holding a diagnostic | Nothing written, no revision, empty effects; the reply carries the diagnostics and the stored formats; the type unchanged |
| AC-7.9 | `ListCitationPlaceholders` form `list` on a project with 3 fields | 4 Source built-in rows (`{source.title}`, `{source.type}`, `{source.date}`, `{source.date:year}`) then 3 `{source.meta.key}` rows; no other level |
| AC-7.10 | Form `full` | Source, Artifact, Evidence graph, Citation in that order; each level's built-ins, then (metadata levels) the fields in `metadatafields.List` order |

## 3. Scope

| In | Covered by |
| --- | --- |
| Go: a Source target takes every form, through the Source's first Citation (D-2) | STEP-1, AC-7.1, AC-7.2 |
| Go: a format with no target returns its diagnostics only; the format is checked first (D-3) | STEP-1, AC-7.3 – AC-7.6 |
| Go: `UpdateSourceType` carries an optional formats draft in one write; `UpdateCitationFormats` goes (D-4) | STEP-2, AC-7.7, AC-7.8 |
| Go: `ListCitationPlaceholders` replaces `ListCitationBuiltins` (D-5) | STEP-3, AC-7.9, AC-7.10 |
| Swift store for these (D-6) | STEP-4 |
| Cache signal `.changedCitationFormats(typeId:)` (rule "Requirements need a refresh signal") | STEP-5, AC-6.1 |
| One latest-call helper; `CatalogSearchModel` and `CatalogCounts` move onto it (D-10) | STEP-5 |
| Kit: `PVTextArea` cursor handle and completion at the cursor over the ComboBox's popup list; `PVSubsectionHeader` meta tone and trailing accessory (brief inventory: Extend) | STEP-6, AC-2.1, AC-2.2, AC-2.5, AC-3.2, AC-1.8 |
| The formats model and the page's one Save (CF-2 – CF-10) | STEP-7, US-1 – US-4 |
| The section view, the preview, the locked type, VoiceOver (CF-1, CF-7, CF-11, CF-12, CF-W1) | STEP-8, AC-1.1, AC-5.1 |
| Copy (§ 2.1 of the brief), one message per diagnostic code, built-in names | STEP-9 |

| Out | Home |
| --- | --- |
| Citations on the provenance sheet, the Person page and the Source page | S15-21, S15-22, S15-23 |
| Needed and used marks on boards | S15-39 |
| Choosing which Citation of the Source the preview uses | not planned (user, 2026-11-20: Source only) |
| Syntax colouring or inline underline in the text area | not planned (user, 2026-11-20: warnings listed under the field) |
| A fuller syntax guide (detachable popover, docked panel or window) | not planned (user, 2026-11-20: the syntax strip only, for now) |
| Caching the formats read in the session | not planned (D-9) |
| Moving `CitationRunsText` to `Platform/` | S15-21, its second caller |

## 4. Current state

Verified at `34c2b61`.

| Area | Where | Today |
| --- | --- | --- |
| Preview | `core/database/citationrender/preview.go` `RenderPreview` | Refuses neither-or-both targets and a Source target with a form other than `list` (`citations.ErrInvalid`); loads the target, then checks the format; a Source target loads through `loadSource` (`load.go`), `cited` nil |
| Preview load | `core/database/citationrender/load.go` `loadCitations`, `loadSource`, `fillValues` | `fillValues` reads Artifact and graph values only for a subject with `cited`; a Source subject answers Source values and built-ins |
| Citations | `core/database/citations/citations.go` `ListCitedTx` | No read from a Source to its Citations. Citation ids are UUIDv7 (`uuid.NewV7`, line 231). Indexes: `evidence_graphs_source_id_idx` (migration 000055), `citations_graph_artifact_idx` (000059) |
| Type update | `core/database/sourcetypes/sourcetypes.go` `Update(tx, id, label, description, iconKey)`; `UpsertTx(tx, t, formats *Formats)` | `Update`: `editableTx`, normalises, `updateChange(existing, next, nil)`, `sqlUpdate`; one change or none. `UpsertTx`'s update branch already writes columns and formats as one change (`writeStoredTx`, `rowDiff`, `updateChange(existing, next, diffs)`, `sqlUpdate` when `rowDiff != nil`) |
| Formats write | `core/database/sourcetypes/formats.go` `UpdateFormats`, `ToStored`, `writeStoredTx`, `viewTx`, `checkChoices`, `updateChange(prev, next, formats)` | `UpdateFormats` builds its own change `updateChange(existing, existing, fields)`; `checkChoices` accepts a choice for a key the text does not use and refuses one for a missing field or another key |
| Handlers | `api/ffi/handlers/source_defs.go` `UpdateSourceType` (one `writes.Run`, action `update_source_type`), `GetCitationFormats`, `UpdateCitationFormats` (own `writes.Run`), `fieldChoicesFromProto`, `citationFormatsProto` | Two RPCs for one page |
| Built-ins RPC | `api/ffi/handlers/citation_render.go` `ListCitationBuiltins`; `core/citationformat/builtins.go` `Builtins()`, `ListFormAllows`, `Builtin.InListForm()`; `FieldRef.Token()` | Lists the table; no Go code writes a whole placeholder's text; no Swift caller |
| Proto | `api/proto/engine.proto` `UpdateSourceTypeRequest` (fields 1–6), `UpdateSourceTypeResponse`, `UpdateCitationFormatsRequest/Response`, `METHOD_UPDATE_CITATION_FORMATS = 121`, `METHOD_LIST_CITATION_BUILTINS = 126`, `ListCitationBuiltinsRequest/Response`, `CitationBuiltin`, `CitationFormats`, `CitationRender`, `CitationMissing`, `CitationRequirementOption` | As S15-15 and S15-16 left them |
| Tests using the formats write | `api/ffi/handlers/source_defs_test.go`, `metadata_test.go` (line 458), `vocabulary_write_effects_test.go` (line 33), `citation_render_test.go` (20 references to `UpdateCitationFormats` in all); `UpdateFormats` in `core/database/sourcetypes/formats_test.go` (lines 82, 187; `TestUpdateFormats`), `core/database/sourcetypes/sourcetypestest/sourcetypestest.go` `SetFormats` (line 24; used by `sourcemetadata_test.go`, `core/database/sourcevocab/copy_test.go`, `metadatafields_test.go`), `core/database/citationrender/render_test.go` (101), `core/database/effects/source_type_search_test.go` (75) | Seed formats through the RPC or function this PR retires |
| Swift formats type | `macos/App/Platform/GenealogyStore.swift` `CatalogCitationFormats` (`typeID`, `full`, `short`, `list`, `text(_:)`) | No choices, no diagnostics |
| Swift read | `macos/App/Platform/GoStore.swift` `citationFormats(projectDir:typeID:)`; `FakeStore.citationFormats`, `citationFormatsByType`, `citationFormatsError` | Drops `field_choices` and `diagnostics`. Only caller: `SourceTypeCopyModel.loadFormats()` |
| Swift update | `GenealogyStore.updateSourceType(projectDir:userID:typeID:label:description:iconKey:)`; one caller `SourceTypePageModel.submit()` | No formats |
| Swift parity enums | `macos/App/Platform/CitationFormatVocabulary.swift` `CitationForm`, `CitationOption`, `CitationDiagnosticCode`, `CitationBuiltin`, `CitationFormatLimit.maxCharacters` | Held to Go by `api/ffi/swift_vocabulary_test.go` |
| Page model | `macos/App/Features/SourceTypes/SourceTypePageModel.swift` `SourceTypePageModel` (420 lines) | `isDirty` (`guard !isLocked, let type, let draft`), `canSubmit`, `submit()`, `revertEdit()`, the suggestion writes, Copy, Delete, `shouldHoldNavigation` |
| Page view | `macos/App/Features/SourceTypes/SourceTypePageView.swift` `SourceTypePageContent` | `primary` = `details`: `PVSectionHeader` "Details", the form, then `VocabularyFormActions` at the form's foot |
| Kit | `PVTextArea.swift` (`PVTextArea`, `PVTextEditorInsetClearer`, `PVTextEditorInsetView.clearInsets()`, `PVTextAreaTabRouter`); `PVSubsectionHeader.swift` (`meta: String?`, always `textMuted`, no accessory); `PVComboBox`, `PVComboBoxOption(value:label:subtext:)`; `PVRetryCallout`; `PVFormLoadArea` with `PVFormLoadState`; `PVFocusRingButtonStyle`; `PVErrorText`; `PVSelect`; `PVChip`; `PVIcon.warning` | As named |
| Origin mark | `macos/App/Features/Catalog/OriginMarkers.swift` `OriginPill` | The vocabulary's origin pill |
| Level copy | `macos/App/Platform/L10n.swift` `L10n.SourceTypes.LevelCopy`, `level(_:)` ("One switch over `Level`") | Title, meaning, empty body, picker label, phrase, copy tick; no plain name |
| Derived values | `macos/App/Features/Workspace/Session/WorkspaceSession+Derived.swift` `DerivedValueID`, `session.derived(_:inputs:extra:build:)`; `macos/App/Features/Sources/SourcesModel.swift` `buildVisibleSources()` (the `.updated` sort: revision, then id, inline) | |
| Latest call | `macos/App/Features/Catalog/Search/CatalogSearchModel.swift` (`debounceTask`, `searchGeneration`, `settle()`; tests reach it through `macos/ProvenenciaTests/QueryHandleWaiting.swift` `waitForSearch`), `macos/App/Features/Catalog/CatalogCounts.swift` (`refreshAll() async`, `refreshGeneration`; `CatalogCountsTests` await it), `macos/App/Features/Catalog/Unpromote/UnpromoteFlow.swift` (`generation`, `mine`), `macos/App/Features/CitationComposer/CitationComposerModel.swift` (`startIdentitySwitch`, `switchGeneration`, `identityTask`, `awaitIdentitySwitch()`) | Four hand-written latest-wins copies |
| Mutations | `macos/App/Features/Workspace/Session/CatalogMutation.swift`; `CatalogQueryRegistry.swift` `.sourceWorkspace` descriptor (`invalidateOn` six kinds; `default` → `.allCached(.sourceWorkspace)`) | No formats case |
| Tests | `macos/ProvenenciaTests/SourceTypePageModelTests.swift`, `SourceTypeCopyModelTests.swift`, `CatalogQueryRegistryTests.swift` `wroteTypeSuggestionsInvalidatesOnlySourcePages`; `core/database/citationrender/preview_test.go` `TestRenderPreview`; `api/ffi/handlers/citation_render_test.go` `TestRenderCitationPreview`, `TestListCitationBuiltins` | As above |

**Precedent.** S15-33 ([`S15-33-artifact-update-saves-metadata.md`](S15-33-artifact-update-saves-metadata.md)): an update request gains an optional draft and saves it in the same write. S15-12 ([#856](https://github.com/Jake-Robins-Studios/provenencia/pull/856)): one view drawn per level with `PVSubsectionHeader`; copy that shape per `CitationForm`. S15-18 ([#877](https://github.com/Jake-Robins-Studios/provenencia/pull/877)): a model with `PVFormLoadState` over a store read. `.wroteTypeSuggestions` and its registry test: the mutation.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | **One PR** for the editor and the preview | User, 2026-11-20 (asked against the size rule) | An editor PR and a preview PR — the user kept one |
| D-2 | **A Source target takes every form.** For `full` and `short`, `RenderPreview` renders against the Source's first Citation: `citations.FirstOfSourceTx(tx *sql.Tx, sourceID []byte) ([]byte, error)` *(new)*: `SELECT c.id FROM citations c JOIN evidence_graphs g ON g.id = c.graph_id WHERE g.source_id = ? ORDER BY c.id LIMIT 1`; nil and no error when none; `ErrInvalid` for an id not 16 bytes. With a Citation, the preview loads it through `loadCitations`; without one, through `loadSource`. `list` keeps `loadSource`. A Source not in the catalog is `sources.ErrNotFound`, checked by `loadSource` before the Citation lookup | User, 2026-11-20: the preview picks a Source only. Ids are UUIDv7, so the smallest is the oldest Citation, stable as Citations are added; both joins are indexed | A Citation picker — the user chose Source only; full and short from the Source alone always — every Artifact and graph field would read empty though Citations exist |
| D-3 | **The format is checked first; with no target it is all there is.** `RenderPreview`: an unknown form, both targets, or an id not 16 bytes → `ErrInvalid`; no target and `Format == nil` → `ErrInvalid`. Then, when `Format != nil`, `ToStored` runs first; diagnostics return alone (AC-7.6: even for a Citation not in the catalog). No target → an empty `Preview` after that. Then the target loads | Warnings while typing on a type with no Sources (AC-3.6) through the one preview request (rule "One render request for previews") | A Swift parser — rule "One engine, in Go"; warnings only on Save — CF-4 asks for them while typing; a check RPC — the preview already checks |
| D-4 | **One Save is one write.** `UpdateSourceTypeRequest` gains `optional CitationFormats formats = 7;` (`type_id` inside is ignored; `full`, `short`, `list`, `field_choices` used). `UpdateSourceTypeResponse` gains `CitationFormats formats = 3; repeated CitationFormatDiagnostic diagnostics = 4;` (set only when the request carried formats). One write step for a type's row, lifted from `UpsertTx`'s update branch: `applyTx(tx *database.Tx, existing, next Type, stored *Formats) (*rowchange.Change, error)` *(new, unexported)*: `stored != nil` → `writeStoredTx` (its diffs); `rowDiff := updateChange(existing, next, nil)`; `change := updateChange(existing, next, diffs)`; `sqlUpdate` only when `rowDiff != nil`; returns `change` (nil when nothing differs). `UpsertTx`'s update branch calls it with its own `formats` (behaviour unchanged). `nextOf(existing Type, label, description, iconKey string) (Type, error)` *(new, unexported)*: `Update`'s trim, empty-label refusal (`ErrInvalid`) and icon normalisation, returning `next`. `Update` (signature unchanged) = `editableTx` → `nextOf` → `applyTx(…, nil)` → nil → `existing`, no change; else re-read (`getByIDTx`) and the change. `sourcetypes.UpdateWithFormats(tx *database.Tx, id []byte, label, description, iconKey string, formats Formats, choices []FieldChoice) (Type, FormatsView, []rowchange.Change, error)` *(new)*: `editableTx` (a missing type stays `sql.ErrNoRows`, as `Update`); `ToStored`; diagnostics → (`existing`, `viewTx` with `Diagnostics`, no change), nothing written; `nextOf`; `applyTx(…, &stored)`; nil → (`existing`, `viewTx`, no change); else re-read the type and `viewTx`, and that one change. So one write path holds every `source_types` row update (Upsert, Update, UpdateWithFormats). `UpdateFormats` is deleted. Its callers move: `core/database/sourcetypes/sourcetypestest/sourcetypestest.go` `SetFormats` keeps its signature and wraps `UpdateWithFormats` with the type's own label, description and icon (read by `GetByIDTx`), action `update_source_type`, so `sourcemetadata_test.go`, `sourcevocab/copy_test.go` and `metadatafields_test.go` need no edit; `core/database/citationrender/render_test.go` (line 101) calls `sourcetypestest.SetFormats`; `core/database/effects/source_type_search_test.go` (line 75) calls `UpdateWithFormats` with the type's label, description and icon, and its assertions stand (one `source_types` update change); `formats_test.go`'s helper (line 82) calls `UpdateWithFormats` the same way, and `TestUpdateFormats` is renamed `TestUpdateWithFormats` with its cases kept plus T-11's Go cases. The handler calls `UpdateWithFormats` when `formats` is present, else `Update`, in today's one `writes.Run`; a reply with diagnostics records nothing (the op returns no change). `UpdateCitationFormats` goes: handler, `MethodUpdateCitationFormats`, its `Call` case, its messages; `METHOD_UPDATE_CITATION_FORMATS = 121` becomes `reserved 121; reserved "METHOD_UPDATE_CITATION_FORMATS";`. The 20 test references seed formats through `UpdateSourceType` with formats, through one helper `setFormats(t, world, typeID, Formats)` *(new, `harness_test.go`)* | Plan review M-1, M-17: a user action needing two writes carries the owning layer's change, one transaction and one history entry (`plan-spike` "No client-side copy of an engine rule", S15-33's precedent). The user's "Share Details' Save" (2026-11-20) asked for one Save; this makes it one write | Two RPCs ordered in Swift — a client copy of atomicity, two revisions per Save; keeping `UpdateCitationFormats` beside — a second write path with no caller; an `updateColumnsTx` beside `UpsertTx`'s branch — a second columns-plus-formats write (M-17) |
| D-5 | **Completion rows come from Go.** Method 126 becomes `METHOD_LIST_CITATION_PLACEHOLDERS` (the number kept; no client calls 126 yet). `ListCitationPlaceholdersRequest { project_dir = 1; form = 2; }`, `CitationPlaceholder { level = 1; builtin = 2; option = 3; MetadataField field = 4; text = 5; ref = 6; }` (`text` the whole placeholder, `{graph.meta.line_number}`; `ref` the option inside the braces, `graph.meta.line_number`, what completion puts in), `ListCitationPlaceholdersResponse { repeated CitationPlaceholder placeholders = 1; }` *(new)*; `ListCitationBuiltins*` and `CitationBuiltin` messages, the handler and `TestListCitationBuiltins` go. Go: `citationformat.BuiltinPlaceholders(f Form) []Placeholder` and `citationformat.MetaPlaceholder(l vocabkey.Level, key string) string` *(new, pure)*: `Placeholder{Level, Builtin, Option, Text, Ref}`; per level in `vocabkey` order, kept by `ListFormAllows` for `list`; each built-in `{level.name}` and, for each option other than `full`, `{level.name:option}`. `citationrender.Placeholders(c *database.Catalog, f citationformat.Form) ([]Placeholder, error)` *(new; `Placeholder` with a `Field *metadatafields.Field`)*: per allowed level, the built-ins, then (metadata levels) every field of `metadatafields.List(c)` in its order (`label COLLATE NOCASE, origin, key`), unfiltered and not re-sorted, text `MetaPlaceholder`; `Field` is `metadatafields.Field`. Handler `ListCitationPlaceholders` in `citation_render.go`; a bad form → `citations.invalid` | Map review (M-2): the placeholder syntax and the list-form rule live once, in Go (rules "Built-in placeholders are one table", "One engine, in Go") | Swift composing `{level.meta.key}` and filtering levels — a client copy of the syntax and of `ListFormAllows` |
| D-6 | **Swift store.** `CatalogCitationFormats` gains `fieldChoices: [String: String] = [:]` (key → field id). New *(in `GenealogyStore.swift` beside it)*: `CatalogCitationDiagnostic { form: CitationForm; code: String; utf8Start: Int; utf8End: Int }`, `CatalogCitationFormatsReply { formats: CatalogCitationFormats; diagnostics: [CatalogCitationDiagnostic] }`, `CatalogCitationRender { runs: [CatalogCitationRun]; plain: String }` with `CatalogCitationRun { text: String; italic: Bool }` (one decoder of the wire's `CitationRender`, for S15-21 and S15-22 too), `CatalogCitationOption { level: Level; field: CatalogMetadataField?; builtin: CitationBuiltin? }`, `CatalogCitationPreview { render: CatalogCitationRender; missing: [[CatalogCitationOption]]; diagnostics: [CatalogCitationDiagnostic] }`, `CatalogCitationPlaceholder: Identifiable { id: String ("<level>.<builtin>[:<option>]" for a built-in, "<level>#<field id>" for a field: what the row is, never its text, so two fields with one key are two rows); level: Level; builtin: CitationBuiltin?; option: CitationOption?; field: CatalogMetadataField?; text: String; ref: String }`. `GenealogyStore`: `citationFormats(projectDir:typeID:) -> CatalogCitationFormatsReply` (changed; `SourceTypeCopyModel.loadFormats()` takes `.formats`); `updateSourceType(projectDir:userID:typeID:label:description:iconKey:formats: CatalogCitationFormats?) -> (CatalogSourceType, CatalogCitationFormatsReply?, CatalogWriteEffects)` (changed: `formats` nil sends none; the reply is nil when none was sent); `renderCitationPreview(projectDir:form:format:fieldChoices:sourceID:) -> CatalogCitationPreview` *(new; `format: String?`, `sourceID: String?`)*; `citationPlaceholders(projectDir:form:) -> [CatalogCitationPlaceholder]` *(new)*. A form, level, option or built-in Swift does not know is dropped while decoding; an unknown diagnostic code is kept (generic message, D-16) | One reply type for read and write; one render type for preview and batch (M-4) | A separate formats update method — D-4 |
| D-7 | **One formats model, no AppKit.** `SourceTypeFormatsModel` in `macos/App/Features/SourceTypes/SourceTypeFormatsModel.swift` *(new)*, `@MainActor @Observable`, made by `SourceTypePageModel.init` as `let formats`, given `typeID`, `session`, `store` and `debounce: Duration = .milliseconds(250)`. It reads whether the type is locked from `session.sourceType(id:)` itself (`isEditable`, computed; false until the type loads). It holds saved and draft texts, `fieldChoices`, warnings per form, placeholders per form, the explicit preview pick, renders and missing per form, `isRendering`, `previewError`, `loadState: PVFormLoadState`. It never touches a text view: the view owns the `PVTextAreaCursor`s (D-12) | The page model is 420 lines; §2.5 keeps AppKit out of models | Growing `SourceTypePageModel`; cursors in the model (M-11) |
| D-8 | **The Save.** `SourceTypePageModel.isDirty` = not locked and (Details differ, or `formats.isDirty`), the formats test placed before the Details guard. `canSubmit` = not saving, Label valid, `isDirty`. `submit()` calls `updateSourceType` with the Details draft (or the saved values when only formats changed) and `formats.isDirty ? formats.draftForSave() : nil`. A reply with diagnostics: `formats.refused(reply)` (warnings show, D-11), `saveError` = "Fix the marked formats, then save.", nothing applied. Success: `session.apply(effects, .updatedSourceType(type))`, and, when formats were sent, `session.apply(.changedCitationFormats(typeId:))` and `formats.saved(reply)`; the toast per what was sent (Details only → today's; formats only → "Citation formats saved" / "<label>'s citations now use these formats."; both → "Source type updated" / "<label> and its citation formats are saved."). A thrown error sets `saveError` as today. `revertEdit()` also calls `formats.revert()`. `draftForSave()` carries every recorded choice (D-14) | User, 2026-11-20 (one Save); D-4 makes it one write | Two writes — M-1 |
| D-9 | **Reads.** `formats.load()` from the page's `.task`: `citationFormats` and the three `citationPlaceholders` calls (one per form), together, into `loadState` (`PVFormLoadState.combining`); not a `CatalogQueryKey`. Placeholder rows hold a field's label at read; a Metadata edit is seen next time the page mounts | One reader holding a draft; Back to the page reads again; the Copy sheet reads on its own (S15-18) | A query key — invalidation for one reader with a draft |
| D-10 | **Latest call.** `LatestCall` in `macos/App/Platform/LatestCall.swift` *(new)*, a `@MainActor final class`: `func run<T: Sendable>(after delay: Duration = .zero, _ work: @escaping @MainActor () async throws -> T, apply: @escaping @MainActor (Result<T, Error>) -> Void) async` cancels the pending call, starts this one as the held task, and returns once its `apply` ran or a newer call superseded it (a cancelled sleep or a cancelled `work` ends the call without `apply`); `func start(…)` the same, not awaited (returns at once); `func settle() async` awaits the held task (lifted from `CatalogSearchModel.settle()`); `cancel()`. Four hand-written latest-wins copies move onto it, their tests unchanged: `CatalogSearchModel` (`debounceTask`, `searchGeneration`, `settle()` → `LatestCall.settle()`), `CatalogCounts.refreshAll()` (`refreshGeneration`; awaits `run`), `UnpromoteFlow.open(...)` (`generation` / `mine`), `CitationComposerModel.startIdentitySwitch` (`switchGeneration`, `identityTask`; `awaitIdentitySwitch()` → `settle()`; `apply` clears `isSwitchingCitation`). The formats model holds one per form | Plan review M-6, M-14: one latest-wins mechanism, extracted in the PR that adds another copy; `run` is awaitable because `refreshAll()` and the tests' `waitForSearch` await | A helper the awaited callers cannot use; moving only two of four |
| D-11 | **Preview and warnings.** Each form's preview runs through its `LatestCall` with `format` = the draft (editable) or nil (locked), the draft's choices, and `sourceID` = the effective pick (nil when none). An edit to one form runs that form after `debounce`; `rerenderAll()` runs all three with no delay. The view calls `rerenderAll()` on `.onChange(of: effectivePickID, initial: true)` (the pick, the Sources list landing, a Source leaving) and after a Save. While a call runs its last render stays and `isRendering` is true; an error sets `previewError`, cleared on the next success; `sources.not_found` clears the explicit pick. **Warnings belong to text:** each form keeps `diagnosed: (text, diagnostics)` from the read, a preview reply or a refused Save, for the text that was sent; the view shows them only while the draft equals `diagnosed.text` | The engine is the only renderer; spans are offsets into the sent text | Rendering all three per keystroke; shifting spans in Swift |
| D-12 | **Cursor handle and completion (kit).** `PVTextAreaCursor` *(new, `@MainActor final class`, in `PVTextArea.swift`)*: `weak var textView: NSTextView?`, `func select(_ range: NSRange)` (`makeFirstResponder`, `setSelectedRange`, `scrollRangeToVisible`), `func replace(_ range: NSRange, with text: String, caretAfter: Int)` (`insertText(text, replacementRange: range)` so the SwiftUI binding and undo follow, then the caret). `PVTextAreaCompletion` *(new, `@MainActor final class`, in `PVTextArea.swift`)*, given by the caller: `context: (String, Int) -> PVTextAreaCompletion.Context?` (text and caret, UTF-16 → the range being typed and its query, or nil), `options: (String) -> [PVComboBoxOption]` (query → rows, in order), `row: (PVComboBoxOption, String) -> AnyView`, `accept: (PVComboBoxOption, Context) -> (text: String, caretAfter: Int)?`, `emptyLabel`, `announce`. `PVTextArea` gains `cursor:` and `completion:` (both default nil; every caller unchanged). The area opens the list when an edit leaves a non-nil context (a typed character, not a caret move), keeps it in step with each edit, and closes it when the context goes nil, on Escape (until the next typed character), or on focus loss. While open, `PVTextAreaTabRouter.textView(_:doCommandBy:)` takes `moveUp:`, `moveDown:`, `insertNewline:`, `insertTab:` and `cancelOperation:`; other keys type as usual. The list is the popup `PVComboBox` already draws: `PVComboBoxPopupWindow` and its rows move to `macos/App/DesignSystem/Components/ComboBox/PVPopupList.swift` *(new)*, taking an anchor rect (the ComboBox passes its field's frame; the area passes `textView.firstRect(forCharacterRange:actualRange:)` of the caret, flipped above the line when the screen has no room below), max 8 rows; `PVComboBox` keeps its behaviour and tests. VoiceOver: `NSAccessibility.post` announces the open (count and keys), each highlight and the insert | User, 2026-11-20: complete as you type, no second input. `TextEditor(selection:)` is macOS 15 (target 14.0), so the area reaches its `NSTextView` as it already does for Tab | An Insert field ComboBox (replaced by the user); `NSTextView`'s native completion (`complete:`) — plain strings, prefix only, no level or origin; a second popup list design |
| D-13 | **Spans in Swift.** `CatalogCitationDiagnostic.range(in text: String) -> Range<String.Index>?` *(new)*: offsets through `text.utf8.index(_:offsetBy:limitedBy:)`, nil when out of range or not on a character boundary. The quote is `text[range]`, cut to 40 characters with an ellipsis; a zero-width span quotes nothing. Selecting uses `NSRange(range, in: text)` | Go spans are UTF-8 bytes | Character counts — wrong for non-ASCII text |
| D-14 | **Choices.** `didComplete(row, into:)` records `fieldChoices[field.key] = field.id` for every field row put in by completion. The Select on an `ambiguous_field` line (key = the span's text) lists the vocabulary fields with that key (label · origin pill copy) and sets the choice. Swift sends every recorded choice. Go: `sourcetypes.checkChoices` treats a well-formed choice whose field no longer exists as absent (the key then resolves as with no choice: the one field, `unknown_field` or `ambiguous_field`); a choice with an empty key, a bad id length, a key twice, or a field of another key stays `ErrInvalid`. The proto comment on `CitationFormats.field_choices` becomes "The field each shown key means, for keys more than one field holds; a write may send more, and a choice whose field is gone is ignored." | `checkChoices` is the one acceptance rule (M-3, M-18); a field deleted after Swift's list was read no longer fails the Save | A Swift filter against the cached field list — a client copy of the engine's refusal |
| D-15 | **Preview Sources.** `DerivedValueID.sourcesOfType(typeID: String)` *(new)*, built from `.sourcesList`: the type's Sources by `SourcesModel.updatedOrder(_:_:)` *(new static beside `titleOrder` and `dateOrder`: revision then id, both descending)*, which `buildVisibleSources()`'s `.updated` case also calls. The model keeps only `pickedSourceID: String?`; `effectivePickID` = the pick when it is in the list, else the list's first | §2.5 and M-5: one derivation, one "most recently changed" order | A filtered copy in the model |
| D-16 | **Copy.** `L10n.CitationFormats` *(new)*: `builtinName(_:option:)` (eight names, "Date, year only" for `.sourceDate` with `.year`), `formTitle(_:)`, `formMeaning(_:)`, `diagnostic(_ code: CitationDiagnosticCode?, key: String)` (nil → "This part of the format cannot be read"), `missing(_ chain: [CatalogCitationOption])`. `L10n.CitationFormats.levelName(_ level: Level)` over all four levels ("Source", "Artifact", "Evidence graph", "Citation"), keyed `citationFormats.level.<level>`; `L10n.SourceTypes.LevelCopy` stays the suggestion lists' copy for the three metadata levels (its `.citation` case traps); the missing line and the completion row chip use `levelName`. The editor's chrome under `L10n.SourceTypes.Formats` *(new)*. **Missing line:** one line per chain, "Missing: " then the options joined by ", or ", each "<name> on the <level name>"; a later option with the first's name reads "on the <level name>" alone ("Missing: Line on the Evidence graph, or on the Source"); a built-in's name is `builtinName` | Domain copy S15-39 and S15-21 reuse; a level's name is not suggestion-list copy (M-16) | `LevelCopy.name` — its `.citation` case is `preconditionFailure` |
| D-17 | **Count.** `draft.unicodeScalars.count` against `CitationFormatLimit.maxCharacters`, grouped by the locale ("4,001 / 4,000"); over → `PVSubsectionHeader`'s meta in the danger tone | Go counts code points (S15-16 Landed) | `String.count` |
| D-18 | **Locked type.** `isEditable` false: read-only forms, previews send `format: nil`, no completion, no count, no warnings, no Save or Revert (`VocabularyFormActions` hidden when locked); with no Sources, the same no-Sources note | CF-11; the write is `sourcetypes.origin_locked` | Editable text that cannot save |
| D-19 | **Cache signal.** `CatalogMutation.changedCitationFormats(typeId: String)` *(new, bust-only)*, `CatalogMutationKind.changedCitationFormats` *(new)*; the `.sourceWorkspace` descriptor adds it to `invalidateOn` (its `default`: `.allCached(.sourceWorkspace)`) and its comment names it. `docs/catalog-caches.md` records it: the Swift "Per-view query results" row's **Updated by** cell gains "a Save carrying citation formats (`.changedCitationFormats`) marks every cached Source page stale" | Working rule "Requirements need a refresh signal" ("records it in `docs/catalog-caches.md`") | Invalidating only the type's Sources — a cached page does not carry its type id without a read |
| D-20 | **Kit extensions.** `PVSubsectionHeader` gains `metaTone: PVSubsectionHeader.MetaTone = .muted` (`.muted`, `.danger`) and an optional trailing accessory (`init(title:meta:metaTone:accessory:content:)`, `accessory` defaulting to `EmptyView`); today's callers are unchanged. `macos/App/DesignSystem/README.md` gets one line each for the cursor handle and the header's tone and accessory | Brief inventory: Extend (M-9); one change in the kit | A local header |
| D-21 | **Where the caret's placeholder starts** (feature side of D-12). `CitationCompletionContext.at(_ text: String, caret: Int) -> PVTextAreaCompletion.Context?` *(new, in `SourceTypeFormatsModel.swift`)*: from the caret, step back over option characters (letters, digits, `_` `-` `.` `:` `#`) to the opener; the opener is `{` with an even number of `\` before it, or `|` inside such a `{` (stepping back over earlier options and `|` to it, with no `}` between); anything else (a space, `}`, `[`, start of text) → nil. The query is the characters from the opener to the caret; the range runs from after the opener to the end of the option characters after the caret. `accept` puts `row.ref` in that range and adds `}` unless the next character is `}` or `|`; the caret goes after the `}` (or after `ref` before a `|`). `completionOptions(form, query:)` filters the form's Go rows (`placeholders(form)`) with `PVComboBoxMatch` over label, key, level name and `ref`, keeping the engine's order inside each band; the typed query is the only ranking input (no suggested-fields-first; user, 2026-11-20). The scan decides only where a placeholder being typed starts; it does not judge whether a format is valid (Go's warnings do) | The completion must answer per keystroke, with no FFI round trip | A Go call per keystroke — async under typing; Swift validating options — Go's diagnostics own that |

**Rules this plan bends.** The working rule "One render request for previews and the list entry" read "a target (one Citation, or a Source for the list form)"; D-2 and D-3 widen it. Asked: user, 2026-11-20, "Source only" for the preview, and warnings while typing (brief CF-4). Done: the rule was updated in the map at planning (2026-11-20). The rule "Requirements need a refresh signal" said S15-17 "applies a typed mutation after S15-15's write"; D-4 moves that write onto `UpdateSourceType`. It is the user's one Save, made one write per `plan-spike` "No client-side copy of an engine rule". The map's rule and the S15-17 scope entry were updated at planning (2026-11-20). D-21 has Swift read the format text around the caret, against "Swift never parses a format" (rules "A format's fields are needed or used", "One render request for previews"): asked, user 2026-11-20: "it's fine for Swift to read the format; I don't see another way around that"; done: both rules in the map name the exception (2026-11-20). The implementer edits none of these rules.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `citations.FirstOfSourceTx` *(new)* | func | `citations.ListCitedTx` | That reads by Citation id; this finds one id by Source |
| `sourcetypes.UpdateWithFormats`, `applyTx`, `nextOf` *(new)* | funcs | `UpsertTx`'s update branch (lifted into `applyTx`), `Update`, `UpdateFormats` (deleted) | One write step for every row update (D-4) |
| `citationformat.BuiltinPlaceholders`, `MetaPlaceholder`, `Placeholder` *(new)* | pure funcs | `Builtins()`, `FieldRef.Token()` | The table and the syntax own the text (D-5) |
| `citationrender.Placeholders` *(new)*, `ListCitationPlaceholders` *(new, method 126)* | func, FFI | `ListCitationBuiltins` (replaced) | Needs the vocabulary; replaces the built-ins RPC |
| `CatalogCitationDiagnostic`, `CatalogCitationFormatsReply`, `CatalogCitationRender`, `CatalogCitationRun`, `CatalogCitationOption`, `CatalogCitationPreview`, `CatalogCitationPlaceholder` *(new)* | types | `CatalogCitationFormats` | Extended where it fits (`fieldChoices`); the rest are wire shapes Swift lacks |
| `renderCitationPreview`, `citationPlaceholders` *(new)* | store methods | `citationFormats` | One per RPC |
| `SourceTypeFormatsModel` *(new)* | model | `SourceTypePageModel`, `SourceTypeCopyModel` | D-7 |
| `SourceTypeFormatsSection.swift` *(new)*: `SourceTypeFormatsSection`, `SourceTypeFormatEditor`, `SourceTypeFormatWarning`, `SourceTypeFormatPreview`, `CitationRunsText` | views | `SourceTypeSuggestedFields`, `SourceTypeSuggestionList` | One form view drawn three times (S15-12's shape) |
| `PVTextAreaCursor`, `PVTextAreaCompletion`, `PVPopupList` (moved out of `PVComboBox`) *(new)*; `PVSubsectionHeader` tone and accessory | kit | `PVFieldFocus`; `PVSubsectionHeader` | Extend, not a new control (D-12, D-20) |
| `LatestCall` *(new)* | Platform | the counters in `CatalogSearchModel`, `CatalogCounts`, `UnpromoteFlow`, `CitationComposerModel` | They move onto it (D-10) |
| `DerivedValueID.sourcesOfType`, `SourcesModel.updatedOrder` *(new)* | derived, func | `.visibleSources`, its inline `.updated` sort | D-15 |
| `CatalogMutation.changedCitationFormats` *(new)* | mutation | `.wroteTypeSuggestions` | Bust-only |
| `L10n.CitationFormats` (with `levelName`), `L10n.SourceTypes.Formats` *(new)* | L10n | `L10n.SourceTypes.level(_:)` | D-16 |
| `setFormats` *(new, `api/ffi/handlers/harness_test.go`)* | test helper | the 20 `UpdateCitationFormats` call sites | One seed path |

**Builds on.** S15-16's preview (`RenderPreview`, `loadCitations`, `loadSource`); S15-15's `ToStored`, `writeStoredTx`, `updateChange`; S15-33's optional-draft update; S15-12's per-level view; `PVComboBox`, `PVSelect`, `PVRetryCallout`, `PVFormLoadArea`, `PVFocusRingButtonStyle`, `PVErrorText`, `OriginPill`, `VocabularyFormActions`; `WorkspaceLeaveGuard`; the registry's `invalidateOn`; `session.derived`.
**Deletes.** `UpdateCitationFormats` (handler, dispatch constant and case, request and response messages; method 121 reserved), `sourcetypes.UpdateFormats`, `ListCitationBuiltins` (handler, its messages, `CitationBuiltin` message, `TestListCitationBuiltins`; method 126 renamed), the preview's "a Source target takes the list form only" refusal and its doc sentence and proto comment, the `TestRenderPreview` / `TestRenderCitationPreview` cases that expect `citations.invalid` for a Source target with `full` or `short` or for no target with a format (rewritten), `CatalogSearchModel.searchGeneration` / `debounceTask`, `CatalogCounts.refreshGeneration`, `UnpromoteFlow`'s `generation`, `CitationComposerModel.switchGeneration` / `identityTask` (moved onto `LatestCall`), the inline `.updated` comparator in `SourcesModel` (moved to `SourcesModel.updatedOrder`). The `docs/citation-formats.md` sentences naming `UpdateCitationFormats` and `ListCitationBuiltins`.
**Next adds.** S15-23 calls `renderCitationPreview(form: .list, format: nil, sourceID:)`. S15-21 and S15-22 decode `CatalogCitationRender` and move `CitationRunsText` to `Platform/`. S15-39 maps `CatalogCitationOption` with `L10n.CitationFormats.missing` and `builtinName`. A new built-in or option is one row in `citationformat.builtins`, and the completion list shows it with no Swift change beyond its parity case and name.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A Source target with `full` / `short` | `RenderPreview` → `loadCitations` | The id was read in the same transaction; a Source with none goes through `loadSource` (AC-7.2) |
| No target with a format | `RenderPreview` | Returns after `ToStored`, before any load (AC-7.3, AC-7.4) |
| `UpdateSourceType` with formats | `writes.Run` `update_source_type` | Diagnostics return no change, so no revision (AC-7.8); a locked type is `origin_locked` from `editableTx` as today |
| The page mounts per type (`viewIdentity`) | `SourceTypeFormatsModel` | One model per type |
| The picked Source deleted elsewhere | `effectivePickID` (D-15) and `sources.not_found` (D-11) | Falls back to the list's first |
| A field in a draft deleted on the Metadata page | Preview / save | Go ignores its choice and returns `unknown_field` or resolves the key (D-14) |
| A type deleted while its page is open | `isGone` leaves the page (today) | The model goes with the page |

### Scale

At the map's Scale (a type used by 500 Sources; 3,000 Sources; 63 fields): a preview call reads one Source, one Citation id (one indexed query) and the values one template names (S15-16 D-4); at most one call per form per 250 ms pause. `ListCitationPlaceholders` reads the fields once per form at page load: at most 63 × 3 + 9 rows. `sourcesOfType` filters the cached 3,000 rows once per list revision (`session.derived`). A Save with formats invalidates every cached `sourceWorkspace` key (at most 50 hidden plus the shown); hidden ones are marked stale, not reloaded. The write's cost is S15-15's `UpdateFormats` plus today's `Update`, in one transaction.

### Edges

- **Assumptions.** `fillValues` handles a subject with or without `cited` (S15-16 D-4); D-2 only chooses which. One `source_types` change per write: `updateChange(existing, next, fields)` already takes the format diffs (S15-15). `insertText(_:replacementRange:)` reaches the SwiftUI binding through the delegate chain the tab router forwards (Stop condition if not).
- **Neighbors.** A Source target with `list`, a Citation target with no format, and `UpdateSourceType` without formats are unchanged (T-1, T-3, T-11). No target and no format is still refused (AC-7.5).
- **Removed inputs.** A deleted Source: `sources.not_found` (D-11, D-15). A deleted field: its choice is ignored by `checkChoices` and the key resolves without it (D-14, T-11). A deleted Citation between lookup and load cannot happen (one transaction).
- **Real data.** Every seeded type's three formats (S15-19) load with no diagnostics and preview (T-12 runs the 26 seeded types through `GetCitationFormats` and a no-target preview of each form: zero diagnostics). The census full note is about 560 characters.
- **Untrusted size.** A crafted stored format over the limit loads as stored with diagnostics (S15-15); the area scrolls past 10 lines; previews refuse it with `too_long`. The placeholder list is bounded by the vocabulary.

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/citations` | `FirstOfSourceTx` *(new)* (D-2) |
| `core/database/citationrender` | `RenderPreview` per D-2, D-3 (doc comment rewritten); `placeholders.go` *(new)*: `Placeholder`, `Placeholders` (D-5) |
| `core/citationformat` | `placeholder.go` *(new)*: `Placeholder`, `BuiltinPlaceholders`, `MetaPlaceholder` (D-5) |
| `core/database/sourcetypes` | `UpdateWithFormats`, `applyTx`, `nextOf` *(new)*; `Update` and `UpsertTx` call `applyTx`; `checkChoices` ignores a choice for a missing field (D-14); `UpdateFormats` deleted (D-4) |

Errors: unchanged codes.

### FFI

`api/proto/engine.proto`: D-4's fields on `UpdateSourceTypeRequest` / `Response`; `UpdateCitationFormats*` removed, 121 reserved; method 126 renamed `METHOD_LIST_CITATION_PLACEHOLDERS` with D-5's messages; `ListCitationBuiltins*` and `CitationBuiltin` removed; `RenderCitationPreviewRequest`'s comment: "Renders one form against one target, or checks an unsaved format with none. A Source target takes every form: the full and short read its first Citation, or the Source alone when it has none. With no target, format is required and only its diagnostics come back." Regenerate with `./scripts/generate-proto.sh` (needs `protoc`, `protoc-gen-go` and `protoc-gen-swift` on the machine; the generated `api/proto/engine/engine.pb.go` and `macos/App/Platform/Generated/engine.pb.swift` are committed). `api/ffi/dispatch.go`: `MethodUpdateCitationFormats` and its case removed; `MethodListCitationBuiltins` → `MethodListCitationPlaceholders`. `macos/App/Platform/CoreInvoke.swift`: `renderCitationPreview`, `listCitationPlaceholders` *(new)*.

### macOS

From the brief's inventory (the board may refine look and placement):

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Section | `PVSectionHeader` "Citation formats" + hint + the syntax strip (`PVFlowLayout` of mono tokens and micro text, editable type only), the forms inside `PVFormLoadArea(state: formats.loadState …)` | `SourceTypeFormatsSection.swift` *(new)* | Under Details in `SourceTypePageContent.primary`; the read's failure is `PVFormLoadArea`'s retry |
| One form | `PVSubsectionHeader(title:meta:metaTone:)` (meta = count) + meaning; then its preview (`SourceTypeFormatPreview`); then `PVTextArea(typography: .mono, lineLimit: 3...10, cursor:, completion:)`; then its warnings | `SourceTypeFormatEditor` *(new)* | Drawn per `CitationForm.allCases`; `isInvalid` when its shown warnings are not empty (board D16-1a: preview above the text, user 2026-11-20) |
| Completion | `PVTextArea(completion:)` (D-12) with `CitationCompletionContext` (D-21); rows from `placeholders(form)`: label (built-in name or field label), `OriginPill` for a field, `PVChip` level name, mono `ref` | in `SourceTypeFormatEditor` | Editable type only; `accept` → `cursor`, then `model.didComplete(row, into:)` |
| Warning line | `Button` with `PVFocusRingButtonStyle`: `PVIcon(.warning)`, then `PVErrorText`-styled message, "at" and the quote in mono, underlined on hover | `SourceTypeFormatWarning` *(new)* | Click or Return → `cursor.select`; `ambiguous_field` adds `PVSelect` (D-14) |
| Read-only form | `PVCard` sunken, mono `Text` | in `SourceTypeFormatEditor` | Locked type |
| "Preview with" | `PVComboBox` Source picker (label title, subtext ref, value id; placeholder "Choose a <type> Source") and its hint, once, above the three forms; failure `PVRetryCallout(message:retry:isRetrying:compact:retryIdentifier:onRetry:)` under it → `rerenderAll()`, the three previews hidden; no Sources `PVCallout` neutral compact in its place | in `SourceTypeFormatsSection` | Board D16-1a, D16-10, D16-10b |
| A form's preview | A sunken block with an accent rule at its left edge (the board's): a micro-caps "Preview" tag with a small `ProgressView` while that form renders, `CitationRunsText(render:)` in body type, then its missing lines as `PVCallout` neutral compact; with warnings, "Not shown while the format has a warning" muted; no format, "No format" | `SourceTypeFormatPreview` *(new)* | Board CF-7 · CF-9 note |
| Completion list | `PVPopupList` 360pt wide, max 8 rows | via `PVTextArea(completion:)` | Board CF-3 note (its ranking excepted) |
| Save / Revert | `PVDivider()` above, then `VocabularyFormActions`, the `saveError` Callout beside it | moved from `form` to the foot of `primary`, after the section | Hidden on a locked type |
| Leave confirm | unchanged | `SourceTypePageView` | `isDirty` includes formats |

Accessibility (CF-12): each area labelled by its form title; the count spoken "560 of 4,000 characters"; a warning is a button "<message> at “<quote>”" with hint "Selects it in the format"; the completion list announces its count and keys on open, and each highlighted row; each preview row is one element "<form title>: <plain>". Identifiers: `sourceTypes.formats.<form>.text`, `.insert`, `.count`, `.warning.<index>`, `sourceTypes.formats.preview.source`, `sourceTypes.formats.preview.<form>`.

### Strings

From the brief § 2.1 and the board's "Copy added" note (the board's text wins). Keys *(new)*: `sourceTypes.formats.*` (section title, hint, the five syntax-strip meanings in the board's order (`{ }` "a field", `|` "or, if empty, the next", `[ ]` "drops out when empty", `* *` "italic", `\` "a literal { [ * or \\"; the tokens are `Text(verbatim:)`), "Not shown while the format has a warning", empty placeholders, the completion's no-match line and its spoken open and highlight, count format and its spoken form, warning "at" format and hint, shared-key label, preview title, picker label, placeholder with the type label, hint, "No format", no-Sources note, preview failed title, Save refused Callout, the two new toasts); `citationFormats.*` (eight built-in names, "Date, year only", form titles and meanings, the missing line's "Missing: %@", "%1$@ on the %2$@", "on the %@", ", or ", one message per `CitationDiagnosticCode` and the generic one); `citationFormats.level.<level>` (four). Diagnostic messages: `too_long` "Too long: %1$@ characters, %2$@ over" (the count and the excess, from D-17's count), `too_deep` "Too many groups and italics inside each other", `unclosed_placeholder` "Unclosed field", `stray_close_brace` "This brace closes nothing", `unclosed_group` "Unclosed group", `stray_close_bracket` "This bracket closes no group", `unclosed_italic` "Unclosed italic", `bad_escape` "A backslash can only come before { } [ ] * or \\", `group_without_placeholder` "A group needs a field in it", `empty_option` "Empty field", `bad_character` "A field name cannot hold this character", `unprefixed_meta` "Name a level before meta: source, artifact or graph", `unknown_level` "Not a level: use source, artifact, graph or citation", `meta_not_at_level` "A citation has no metadata fields", `bad_field` "Not a field key", `unknown_builtin` "Not a built-in field at this level", `unknown_option` "This option does not apply here", `not_in_list_form` "The source list reads the Source only", `unknown_field` "No field has the key %@", `ambiguous_field` "Two fields have the key %@: choose one", `unknown_form` generic. Existing copy that names the old scope: `L10n.SourceTypes.saveChanges` and `revert` keep their text and now cover the formats.

## 7. Steps

**STEP-1 — The preview takes a Source for every form and a format alone**
Files: `core/database/citations/citations.go`, `citations_test.go`, `core/database/citationrender/preview.go`, `preview_test.go`, `api/ffi/handlers/citation_render_test.go`. Skills: `add-catalog-query`.
Do: D-2, D-3.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/citations/ ./core/database/citationrender/ ./api/ffi/handlers/ -run 'TestFirstOfSource|TestRenderPreview|TestRenderCitationPreview'` passes (T-1 – T-3).

**STEP-2 — One write saves a type's details and formats**
Files: `core/database/sourcetypes/sourcetypes.go` (`applyTx`, `nextOf`, `UpsertTx`, `Update`), `formats.go` (`UpdateWithFormats`, `checkChoices`), `formats_test.go`, `sourcetypes_test.go`, `core/database/sourcetypes/sourcetypestest/sourcetypestest.go`; `core/database/citationrender/render_test.go`; `core/database/effects/source_type_search_test.go`; `api/proto/engine.proto`, generated files; `api/ffi/dispatch.go`; `api/ffi/handlers/source_defs.go`, `source_defs_test.go`, `harness_test.go`, `metadata_test.go`, `vocabulary_write_effects_test.go`, `citation_render_test.go`. Skills: `add-ffi-handler`, `add-audit-scope`.
Do: D-4, D-14's Go half; regenerate with `./scripts/generate-proto.sh`.
Check: `rg -n 'UpdateCitationFormats|UpdateFormats\(' core api --glob '!*.pb.go'` finds nothing; `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcetypes/ ./api/ffi/...` passes (T-11).

**STEP-3 — Go lists the completion rows**
Files: `core/citationformat/placeholder.go` *(new)*, `placeholder_test.go` *(new)*, `core/database/citationrender/placeholders.go` *(new)*, `placeholders_test.go` *(new)*, `api/proto/engine.proto`, generated files, `api/ffi/dispatch.go`, `api/ffi/handlers/citation_render.go`, `citation_render_test.go`. Skill: `add-ffi-handler`.
Do: D-5.
Check: `rg -n 'ListCitationBuiltins' core api --glob '!*.pb.go'` finds nothing; `CGO_ENABLED=1 go test -tags fts5 ./core/citationformat/ ./core/database/citationrender/ ./api/ffi/...` passes (T-12, T-13).

**STEP-4 — The Swift store**
Files: `macos/App/Platform/GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift`, `CoreInvoke.swift`, `macos/App/Features/SourceTypes/SourceTypeCopyModel.swift`, `SourceTypePageModel.swift` (the call's new argument, `formats: nil`). Skill: `add-swift-test`.
Do: D-6. FakeStore: `citationFormatsByType` holds `CatalogCitationFormatsReply`; `updateSourceTypeCalls` record `formats`; `updateSourceTypeFormatsReply` for a refused reply; `previewReplies: [CitationForm: CatalogCitationPreview]`, `previewCalls` (form, format, choices, sourceID), `previewError`; `placeholdersByForm`.
Check: `SourceTypeCopyModelTests` and `SourceTypePageModelTests` pass.

**STEP-5 — Shared Swift plumbing: latest call, the Sources of a type, the cache signal**
Files: `macos/App/Platform/LatestCall.swift` *(new)*, `macos/App/Features/Catalog/Search/CatalogSearchModel.swift`, `macos/App/Features/Catalog/CatalogCounts.swift`, `macos/App/Features/Catalog/Unpromote/UnpromoteFlow.swift`, `macos/App/Features/CitationComposer/CitationComposerModel.swift`, `WorkspaceSession+Derived.swift`, `SourcesModel.swift` (`updatedOrder`), `CatalogMutation.swift`, `CatalogQueryRegistry.swift`, `docs/catalog-caches.md`, tests `macos/ProvenenciaTests/LatestCallTests.swift` *(new)*, `CatalogQueryRegistryTests.swift`. Skill: `add-workspace-place`.
Do: D-10, D-15, D-19.
Check: T-4, T-5 pass; the existing search, counts, Unpromote, citation composer and Sources list tests pass unchanged.

**STEP-6 — Kit: cursor handle, completion at the cursor, header tone**
Files: `macos/App/DesignSystem/Components/TextArea/PVTextArea.swift`, `macos/App/DesignSystem/Components/ComboBox/PVComboBox.swift`, `macos/App/DesignSystem/Components/ComboBox/PVPopupList.swift` *(new)*, `macos/App/DesignSystem/Components/SubsectionHeader/PVSubsectionHeader.swift`, `macos/App/DesignSystem/README.md`, `macos/ProvenenciaTests/PVTextAreaCompletionTests.swift` *(new)*. Skill: `add-ui-component`.
Do: D-12, D-20.
Check: T-6 passes; the `PVComboBox` tests pass unchanged; every existing `PVTextArea` and `PVSubsectionHeader` caller compiles unchanged.

**STEP-7 — The formats model and the one Save**
Files: `macos/App/Features/SourceTypes/SourceTypeFormatsModel.swift` *(new)*, `SourceTypePageModel.swift`, `macos/ProvenenciaTests/SourceTypeFormatsModelTests.swift` *(new)*, `SourceTypePageModelTests.swift`. Skill: `add-swift-test`.
Do: D-7 – D-9, D-11, D-13 – D-15, D-17, D-18, D-21. Model API: `init(typeID:session:store:debounce:)`, `load()`, `loadState`, `isEditable`, `draft(_:)`, `edit(_:text:)`, `isDirty`, `fieldChoices`, `shownDiagnostics(_:)`, `count(_:)`, `isOverLimit(_:)`, `placeholders(_:)`, `completionOptions(_:query:)`, `didComplete(_:into:)`, `choose(fieldID:forKey:)`, `pickedSourceID`, `previewSources` (reads D-15), `effectivePickID`, `pick(sourceID:)`, `render(_:)`, `missing(_:)`, `isRendering`, `previewError`, `rerenderAll()`, `revert()`, `draftForSave()`, `refused(_:)`, `saved(_:)`.
Check: T-6b, T-7 – T-10 pass and the existing page model tests pass.

**STEP-8 — The section and its preview on the page**
Files: `macos/App/Features/SourceTypes/SourceTypeFormatsSection.swift` *(new)*, `SourceTypePageView.swift` (the section under Details; `VocabularyFormActions` and the save error moved to the foot of `primary`; `.task` also runs `model.formats.load()`; `.onChange(of: model.formats.effectivePickID, initial: true)`; the `#Preview` sets Census formats, placeholders and two Sources in `FakeStore`). Skill: `add-ui-component`.
Do: § 6 macOS and the agreed board.
Check: `xcodebuild test` builds; the `#Preview` shows the section; manual check steps 1 – 3.

**STEP-9 — Copy**
Files: `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `macos/ProvenenciaTests/CitationFormatsCopyTests.swift` *(new)*. Skill: `add-localized-string`.
Do: D-16 and § 6 Strings.
Check: T-14 passes; `rg -n 'Text\("' macos/App/Features/SourceTypes/SourceTypeFormatsSection.swift` finds nothing.

**STEP-10 — Gate and docs**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj` (`MARKETING_VERSION`); `docs/citation-formats.md` (§ Storage: formats save with `UpdateSourceType`, one write with the details; § Rendering "The preview": D-2, D-3; `ListCitationPlaceholders` in place of `ListCitationBuiltins`); `../deployment-plan.md` (map row status); `../completed.md`; `../design/archive/S15-D16-source-type-citation-formats.md` → `../design/archive/`, `../design/README.md`; this plan.
Do: `scripts/check-pr.sh`; then the Definition of done.
Check: `check-pr: PASS`; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/citationrender/preview_test.go` `TestRenderPreview` (extended) | Source target + `full`, two Citations → the older one's render (its page in the text); + `short`, no Citation → Source values, the `{citation.page}` group dropped; + `list` unchanged; no target + `[, p.` → one `unclosed_group`; no target + `{source.title}.` → empty, no error; no target, no format → `citations.ErrInvalid`; both → `ErrInvalid`; a missing Citation with `[` → diagnostics; with `{source.title}` → `citations.ErrNotFound` | AC-7.1, AC-7.2, AC-7.3, AC-7.4, AC-7.5, AC-7.6, D-2, D-3 |
| T-2 | Go | `core/database/citations/citations_test.go` `TestFirstOfSource` *(new)* | Citations in two graphs → the smallest id; graphs with no Citation → nil; unknown Source → nil; 15-byte id → `ErrInvalid` | D-2 |
| T-3 | Go | `api/ffi/handlers/citation_render_test.go` `TestRenderCitationPreview` (extended) | Source target, form `full` → a render; no target, `format` `[` → `{form "full", code "unclosed_group", start 0, end 1}` | AC-7.1, AC-7.3 |
| T-4 | Swift | `CatalogQueryRegistryTests.swift` `changedCitationFormatsInvalidatesSourcePages` *(new)* | Two cached `sourceWorkspace` keys and `sourceTypesList` → `.changedCitationFormats(typeId: "t1")` → both Source keys invalidated, the types list not | AC-6.1, D-19 |
| T-5 | Swift | `macos/ProvenenciaTests/LatestCallTests.swift` *(new)* | Two runs, the first slower → only the second applies; `cancel()` → nothing applies; a delay with a run inside it → one call | D-10 |
| T-6 | Swift | `macos/ProvenenciaTests/PVTextAreaCompletionTests.swift` *(new)* | On an `NSTextView`: `cursor.replace(NSRange(1..<2), with: "XY", caretAfter: 3)` on "abc" → "aXYc", caret 3; `select` → that range; a completion whose `context` is non-nil after typing `{` → open with `options("")`; `moveDown:` then `insertNewline:` → `accept` called with the second row and the text replaced; `cancelOperation:` → closed, text unchanged; a caret move with no edit does not open it; `PVPopupList` anchored to a rect near the screen's bottom → above it | D-12, AC-2.1, AC-2.2, AC-2.5, AC-3.2 |
| T-6b | Swift | `SourceTypeFormatsModelTests.swift` `completionContext` *(new)* | `{li|` caret after `li` → query "li", range 1..<3; `{graph.meta.line_number|so` → query "so", range after `|`; `\{li` (one backslash) → nil; `\\{li` (two) → "li"; `{li ` caret after the space → nil; `{a}b` caret after `b` → nil; accept Line@graph on `{li` → `{graph.meta.line_number}`, caret after `}`; on `{li}` → no second `}`; on `{graph.meta.line_number|so` → `…|source.meta.line_number}`; `completionOptions(.full, query: "graph li")` → Line@graph first; `.list` → Source rows only | D-21, AC-2.1, AC-2.3, AC-2.5 |
| T-7 | Swift | `SourceTypeFormatsModelTests.swift` `insertAndChoices` *(new)* | `didComplete` of a field row → `fieldChoices[key] = id`; of a built-in row → none; `draftForSave()` carries every recorded choice; `choose(fieldID:forKey:)` sets it and re-renders that form | AC-2.4, AC-3.4, D-14 |
| T-8 | Swift | `SourceTypeFormatsModelTests.swift` `diagnosticsAndCount` *(new)* | `unclosed_group` 0..<1 for `[x` → shown while the draft is `[x`, hidden after `edit` to `[xy`; `range(in:)` on `é{` span 2..<3 → the `{`; span 1..<2 → nil; 4,001 scalars → `isOverLimit` | AC-1.8, AC-3.1, AC-3.5, D-11, D-13, D-17 |
| T-9 | Swift | `SourceTypeFormatsModelTests.swift` `preview` *(new)* (debounce zero) | No Sources → calls with `sourceID` nil; the list lands → `effectivePickID` = highest revision, `rerenderAll` sends three; an edit to `.full` sends one call for `.full` with the draft and the pick; `pick(sourceID:)` then `rerenderAll` sends three; `sources.not_found` clears the pick; locked → `format` nil; an error → `previewError`, cleared on success | AC-3.6, AC-4.1, AC-4.2, AC-4.3, AC-4.7, AC-4.8, AC-5.1, D-11, D-15, D-18 |
| T-10 | Swift | `SourceTypePageModelTests.swift` `saveSendsDetailsAndFormatsInOneWrite` *(new)* | Formats dirty only → one `updateSourceType` with formats and the saved Details, toast "Citation formats saved", `.changedCitationFormats` applied; both → one call, the "both" toast; Details only → `formats` nil, today's toast, no `.changedCitationFormats`; a reply with diagnostics → `saveError`, nothing applied, edits kept, warnings shown; `isDirty` true with only a format edit (leave guard holds); `revertEdit()` restores formats | AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, AC-1.7, D-8 |
| T-11 | Go | `core/database/sourcetypes/formats_test.go` (helper moved to `UpdateWithFormats`) and `api/ffi/handlers/source_defs_test.go` `TestUpdateSourceTypeWithFormats` *(new)* | Label and full note together → one revision, one `source_types` change holding `label` and `citation_full`; a diagnostic → no revision, empty effects, diagnostics in the reply, label unchanged; no formats → today's reply, `formats` unset; a plugin type → `sourcetypes.origin_locked`; a choice naming a deleted field → ignored, the key resolves to the one remaining field, no `ErrInvalid` | AC-7.7, AC-7.8, D-4, D-14 |
| T-12 | Go | `core/database/citationrender/placeholders_test.go` `TestPlaceholders` *(new)* | AC-7.9 and AC-7.10 on a 3-field project; and on a new project (the seed): for each of the 26 types and each form, `GetCitationFormats` text through a no-target `RenderPreview` → zero diagnostics | AC-7.9, AC-7.10, D-5 |
| T-13 | Go | `core/citationformat/placeholder_test.go` `TestBuiltinPlaceholders` *(new)* | `list` → the four Source rows; `full` → every built-in, plus `{source.date:year}`, none for `:full`; `MetaPlaceholder(LevelGraph, "line_number")` → `{graph.meta.line_number}`, and the text parses | D-5 |
| T-14 | Swift | `CitationFormatsCopyTests.swift` *(new)* | Every `CitationDiagnosticCode` and nil → a non-empty message; every built-in and `Level` → a non-empty name; `missing([Line@graph, Line@source])` → "Missing: Line on the Evidence graph, or on the Source"; `missing([Jurisdiction@source])` → "Missing: Jurisdiction on the Source" | AC-4.4, D-16 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: the handler tests that seeded formats (D-4), `TestRenderPreview`, `TestRenderCitationPreview`, `SourceTypePageModelTests`, `SourceTypeCopyModelTests`, the search, counts, Unpromote and composer tests (D-10), `TestSwiftVocabularyMatchesGo`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: `UpdateCitationFormats`, `UpdateFormats`, `ListCitationBuiltins`, `CitationBuiltin` (the proto message) and "takes the list form only" `rg`'d across `.agents/`, `.cursor/rules/`, `docs/*.md` (not `docs/deployment-plan/**/prs/*` of landed PRs or `*.review.md`, which record history) and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (done at planning)
- [ ] UI matches the brief inventory and the agreed board; no new kit primitive (`PVTextArea` and `PVSubsectionHeader` are extended)
- [ ] Version bump 0.29.0 → 0.30.0 (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated
- [ ] Domain doc updated: docs/citation-formats.md § Storage, § Rendering "The preview", the placeholder RPC
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

On a new project (the seed's 26 types), with two census Sources ("1880 census, Calder County" with jurisdiction, a household graph and one Citation on p. 14; "1870 census, Calder County" with no jurisdiction and no Citation):

1. Source types → Census. The three formats show by key with counts; the preview picks the 1880 Source and shows the full note with the provider in italics and "p. 14" (AC-1.1, AC-4.1, AC-4.8).
2. In the full note, put the cursor before the final period; type `{line`, Return on Line (Evidence graph). `{graph.meta.line_number}` replaces `{line`; a moment later the preview's full note changes. Save changes: toast "Citation formats saved"; reopen: the text stays (AC-2.1, AC-2.2, AC-4.2, AC-1.3).
3. Delete a `]` in the short note: the warning shows with its quote; click it: the text is selected. Save: refused with the Callout; restore the `]` (AC-3.1, AC-3.2, AC-3.5, AC-1.5).
4. Pick the 1870 Source: "Missing: Jurisdiction on the Source" under the full note; full and short render from the Source alone (AC-4.3, AC-4.4, AC-4.5).
5. Type `{citation.page}` into the source list: its warning, and its preview reads "Not shown while the format has a warning" while the full note's still renders; typing `{` there offers Source rows only. Revert (AC-3.3, AC-4.6, AC-2.3).
6. Edit the short note, press Back: the discard confirm. Keep editing; Revert (AC-1.7).
7. Open a Source page of the type, go back and save a format change, return to the Source page: it reloads (AC-6.1).
8. Change Label and the short note together, Save: the "both" toast, and the type's history shows one entry (AC-1.4). Change Label alone, Save: today's toast (AC-1.6).
9. In Metadata, add a field with the key `page`; in the full note write `{source.meta.page}`: the shared-key warning with its Select; choose one and save. Then type `{page`: two rows, told apart by their origin pills (AC-3.4, AC-2.4).
10. Grave memorial (or any plugin type): read-only formats, the preview, no Save (AC-5.1).
11. At a 2,560pt window: the same centred pair; the cursor and pick survive the resize.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| `insertText` does not reach the SwiftUI binding | T-6 checks the text view; manual check step 2 checks the binding; Stop condition |
| Two changes for one row break the audit | D-4 builds one change with `updateChange(existing, next, fields)`; T-11 counts it |
| Preview calls pile up while typing | D-10, D-11: one `LatestCall` per form |
| Moving four callers onto `LatestCall` changes their timing | Their existing tests must pass unchanged |

**Stop and report if:**

- `RenderPreview`, `loadSource`, `Update` or `UpdateFormats` no longer does what § 4 says.
- `UpsertTx`'s update branch cannot move into `applyTx`, or `Update` onto `nextOf` and `applyTx`, without changing their results (their tests fail).
- After `PVTextAreaCursor.replace`, the `PVTextArea` binding does not hold the new text.
- `PVComboBoxPopupWindow` cannot move to `PVPopupList` without changing `PVComboBox`'s behaviour or tests.
- The search, counts, Unpromote or citation composer tests need changing to pass on `LatestCall`.
- The agreed board draws a behavior a Decision rules out (an inline underline, a Citation picker, separate Saves, the formats outside the main column).
- Any seeded type's format comes back with a diagnostic (T-12).

## 12. Open questions

None. (The board was agreed 2026-11-20; § 6 macOS and Strings carry its decisions.)

## 13. PR

**Title:** S15-17 — The format editor
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-17-format-editor.md`.

## Landed

Where the code differs from the plan:

- **The board was not opened.** The implementer had no access to the Claude Design artifact, so the copy is the brief's § 2.1 and this plan's Strings, and the layout follows the plan's macOS table; the board is to be checked against the built page by hand (§ 10).
- **`PVPopupList`** is the combo box's popup window moved out of `PVComboBox.swift` with two added fields: `width` (nil keeps the anchor's width) and `anchorRect` (a screen rect read each time the popup is framed; nil keeps the anchor view's frame). `PVComboBox` passes neither. The list inside the window is one kit view both callers draw (`PVPopupListCard` scroller and card, `PVPopupListRow` shell with the pointer highlight, `PVPopupListLine` empty or searching line); the combo box stacks its rows in a `VStack` (measured before it shows), the completion in a `LazyVStack` of fixed 40pt rows, 360pt wide, at most 8 rows, whose sizes are `PVTextAreaCompletionList`'s constants.
- **`PVTextAreaCompletion.emptyLabel`** is a closure over the typed query (its line names the query), `didAccept` runs after a row's text is in (the model records the field choice then), and `announce` takes a `PVTextAreaCompletion.Announcement` (opened, highlighted, inserted) and returns the text to speak. The area's open state lives in `PVTextAreaCompletionSession`, which the tab router feeds with edits, selection changes and key commands.
- **The completion row's level** is a `PVBadge`, not a `PVChip` (the kit's chip is a toggle). A warning line's message and quote are one string (`warningAt`), so the quote is not set in mono.
- **`SourceTypeFormatsModel`** also has `isRendering(_ form:)` (a spinner per form) and `placeholder(_:id:)` (the row behind a completion option); `choose(fieldID:forKey:in:)` takes the form to render. The model loads from the section's own `.task`, and the section re-renders when the type becomes known.
- **`FakeStore`** gains `resetPreviewCalls()`, so a test counts only the calls it makes.
- **Copy** beyond the plan's list: `sourceTypes.formats.loading`, `.loadErrorTitle`, `.preview.noMatch`, `.sectionHintLocked`, `.completion.openedEmpty` and `.readerLabel`; the model's `L10n.CitationFormats.diagnostic(_:key:characters:)` takes the format's length for `too_long`, and `citationFormats.diagnostic.too_long_stored` ("Too many fields for one format") reads a `too_long` within the character limit. The shared-key Select's origin words are `L10n.Origin.words(for:)`, which the origin pill and the property inspector also call.
- **`Update`** now checks the type before the label: an empty label on a plugin or missing type is `ErrLocked` or `sql.ErrNoRows` before `ErrInvalid` (D-4's order, `editableTx` then `nextOf`).
- **Tests** are named in the PR; `TestPlaceholders` checks the seeded project's own fields, not a project with exactly 3.
- **User decisions after review round 1 (2026-11-20).** `PVSubsectionHeader` has no trailing `accessory` slot (nothing used it; this supersedes that part of D-20), and gained `metaLabel` and `metaIdentifier` for how its count is spoken and found. D-11 is amended: while the draft differs from the text a form's warnings were found in, the last warnings stay on screen dimmed and inert (their spans are never selected) until the next reply replaces them (`areDiagnosticsStale`); the text area's danger border is not dimmed with them. AC-1.5's example reads `Unclosed group at “[”`, the engine's span for that code; a `too_long` warning quotes nothing. D-7 stands.
- **User addition (2026-11-20):** the certificate types suggest Jurisdiction. Their list format reads `{source.meta.jurisdiction}` outside any group, but the seed did not suggest it (a gap from S15-19). `TestSeededFormatsNeedOnlySuggestedFields` checks every seeded type; `TestSeedSuggestionsFollowFormats` now leaves a field only the short or list format needs out of its full-format order.
- **§ 10 manual check:** not run.
