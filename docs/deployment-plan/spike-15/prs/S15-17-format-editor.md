# S15-17 — The format editor

**Status:** Blocked — on board S15-D16
**Spike / slice:** Spike 15 · Slice 5 — Person page date and the format editor
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D16](../design/S15-D16-source-type-citation-formats.md), board not yet agreed
**Board:** — (filled in when the board is agreed: the artboard, its frames and how the implementer sees them)
**Depends on:** S15-12 (landed [#856](https://github.com/Jake-Robins-Studios/provenencia/pull/856)), S15-15 (landed [#871](https://github.com/Jake-Robins-Studios/provenencia/pull/871)), S15-16 (landed [#914](https://github.com/Jake-Robins-Studios/provenencia/pull/914)), S15-18 (landed [#877](https://github.com/Jake-Robins-Studios/provenencia/pull/877)), S15-48 (landed [#848](https://github.com/Jake-Robins-Studios/provenencia/pull/848)), S15-D16
**Blocks:** —
**Branch:** `s15-17-format-editor`
**Version bump:** minor, 0.29.0 → **0.30.0** (if `main`'s `VERSION` is no longer 0.29.0 when you rebase, the next minor after it): a new editor on the type page; `UpdateSourceType` carries formats, `UpdateCitationFormats` goes, and method 126 becomes `ListCitationPlaceholders` ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-catalog-query`](../../../../.agents/skills/add-catalog-query/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`use-catalog-session`](../../../../.agents/skills/use-catalog-session/SKILL.md), [`add-audit-scope`](../../../../.agents/skills/add-audit-scope/SKILL.md) (one change per row), [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md) (the registry's `invalidateOn`, `session.derived`), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests), `.cursor/rules/ffi-handlers.mdc`, `.cursor/rules/catalog-queries.mdc`, `.cursor/rules/macos-client.mdc`, `.cursor/rules/swift-tests.mdc`, `.cursor/rules/versioning.mdc`; `docs/macos-client-patterns.md` §2.5 (models keep form state; views derive with `session.derived`) and §4 (AppKit in a small wrapper)
**Context:** working rules "Citation formats are data on the Source type", "Every placeholder names its level; fallback is written", "Built-in placeholders are one table", "One engine, in Go", "One render request for previews and the list entry", "Requirements need a refresh signal; renders do not", "Formats name fields by id", "A Source type has its own page", "One window; nothing is built for a second" ([`../deployment-plan.md`](../deployment-plan.md#working-rules)); [`../evidence-explained-citation-map.md`](../evidence-explained-citation-map.md) § 6.3 "The editor"; [`docs/citation-formats.md`](../../../citation-formats.md) (syntax, Storage, Rendering, Diagnostics); landed plans [`S15-15-type-stores-citation-formats.md`](S15-15-type-stores-citation-formats.md) (D-3, D-11, **Next adds**), [`S15-16-citations-render.md`](S15-16-citations-render.md) (D-9, D-10, D-14 and its Landed note), [`S15-12-type-suggestions-at-each-level.md`](S15-12-type-suggestions-at-each-level.md) (D-6: the list header), [`S15-18-copy-source-type.md`](S15-18-copy-source-type.md) (the formats read), [`S15-33-artifact-update-saves-metadata.md`](S15-33-artifact-update-saves-metadata.md) (one Save is one write: an update request carries an optional draft)
**Planned:** 2026-11-20 against `main` @ `34c2b61` (compare with `origin/main` after `git fetch origin main`)
**Review:** [`S15-17-format-editor.review.md`](S15-17-format-editor.review.md)

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

A researcher edits a Source type's three citation formats (full note, short note, source list) on the type's page. Each format has an **Insert field** picker that puts a placeholder at the cursor, a character count against the 4,000 limit, and the engine's warnings listed under it; clicking a warning selects the text it is about. A preview under the formats fills each form in for a Source of the type as the researcher types. One Save writes the Details and the formats in one engine write, and leaving with unsaved formats asks. This is bar 5's first half ("Editing the census full format on its Source type page updates a live preview against a real Source").

**Why now.** The engine (S15-14), storage (S15-15), the preview call (S15-16), the type page with its suggestion lists (S15-48, S15-12) and Copy (S15-18) have landed. No screen shows a format yet: the seed (S15-19) writes them and nobody can change them.

**What stays.** Details' fields, the side column's suggestion lists, the header with Copy and Delete, the types list and both dialogs. `GetCitationFormats` and `RenderCitations` keep their wire. Swift never parses a format, writes placeholder syntax or decides which level a form allows (rule "One engine, in Go"): warnings, renders, missing fields and the Insert rows all come from Go.

## 2. User stories

**US-1.** As a researcher, on an editable type's page, I edit its three formats and save them with Details' Save, so its citations change.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Census's page opens | The Citation formats section shows Full note, Short note and Source list with the stored text by key (`{source.meta.jurisdiction}`, never `#<id>`), each with "used / 4,000" |
| AC-1.2 | Append ` Test.` to the full note | Save changes and Revert enable; Revert puts the stored text back and disables them |
| AC-1.3 | Append ` Test.` to the full note, Save | One `UpdateSourceType` carrying the three forms; toast "Citation formats saved"; reopening the page shows the new text |
| AC-1.4 | Change Label to "Census (US)" and the short note, Save | One `UpdateSourceType` carrying both; one revision; toast "Source type updated" / "Census (US) and its citation formats are saved." |
| AC-1.5 | Delete the `]` of `[, p. {citation.page}]` in the short note and change Label, Save | Nothing saves (no revision; Label is not saved either); the short note shows "Unclosed group at “[, p. {citation.page}”"; the Callout "Fix the marked formats, then save." shows beside Save; every edit stays |
| AC-1.6 | Change only Label, Save | `UpdateSourceType` without formats; today's toast; the formats are untouched |
| AC-1.7 | Unsaved full note, then Back | Today's discard confirm; Discard leaves and drops it; Keep editing stays |
| AC-1.8 | A full note of 4,001 characters (`unicodeScalars.count`) | Its count reads "4,001 / 4,000" in the danger tone; the engine's `too_long` warning shows |

**US-2.** As a researcher, I insert a field without remembering the syntax.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | The full note's Insert field, type "line" | Rows for Line at Source, Artifact and Evidence graph, each with its level Chip and its text (`{graph.meta.line_number}`), in level order |
| AC-2.2 | Cursor after "census," in the full note; choose Line at Evidence graph | `{graph.meta.line_number}` is inserted at the cursor; the picker clears; the cursor sits after the insert in the text area |
| AC-2.3 | The source list's Insert field | Only Source-level rows: Title, Type, Date, "Date, year only", then the fields; no Artifact, Evidence graph or Citation row |
| AC-2.4 | Two fields hold the key `page` (Provenencia's and the researcher's); choose the researcher's Page at Source | The two rows read the same label with different origin pills; `{source.meta.page}` is inserted; no `ambiguous_field` warning follows, because the pick recorded its field |
| AC-2.5 | Choose a row before the area was ever focused | The text goes at the end of the format |

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
| AC-4.1 | Census's page opens; Sources "1880 census, Calder County" (latest revision) and "1870 census, Calder County" | The preview picks the 1880 Source and shows three rows rendered with italics |
| AC-4.2 | Edit the full note | A moment after typing stops, the Full note row shows the render of the unsaved text; the other rows do not re-render |
| AC-4.3 | Pick the 1870 Source | All three rows re-render for it |
| AC-4.4 | The picked Source has no `jurisdiction` | Under the full note: "Missing: Jurisdiction on the Source" |
| AC-4.5 | A Source with no Citations | Full and short render from the Source alone: Artifact, Evidence graph and Citation placeholders are empty and their groups drop (D-2) |
| AC-4.6 | The short note has a warning | Its row shows no render; the full and list rows still do |
| AC-4.7 | The preview call fails | `PVRetryCallout` in place of the rows; Try again renders again |
| AC-4.8 | The Sources list loads after the page | The preview renders with no target (warnings only) until the list lands, then picks the latest Source and renders all three |

**US-5.** As a researcher on a plugin's type, I read its formats and preview them, and cannot edit them.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-5.1 | Grave memorial (plugin, locked) with a full note only | Full note read only in a sunken Card; the other two read "No format"; no Insert field, no count, no Save or Revert; the preview renders the stored full note |

**US-6.** As the boards, after a format save, every cached Source page re-reads its requirements.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-6.1 | Two Source pages cached, then a Save carrying formats | Both `sourceWorkspace` keys are invalidated by `.changedCitationFormats(typeId:)`; a Details-only Save does not apply it |

**US-7.** As the engine, I take a Source target for every form, a format with no target, one write for a type's details and formats, and the Insert rows for a form.

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
| AC-7.10 | Form `full` | Source, Artifact, Evidence graph, Citation in that order; each level's built-ins, then (metadata levels) the fields by label |

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
| Kit: `PVTextArea` cursor handle; `PVSubsectionHeader` meta tone and trailing accessory (brief inventory: Extend) | STEP-6, AC-2.2, AC-2.5, AC-3.2, AC-1.8 |
| The formats model and the page's one Save (CF-2 – CF-10) | STEP-7, US-1 – US-4 |
| The section view, the preview, the locked type, VoiceOver (CF-1, CF-7, CF-11, CF-12, CF-W1) | STEP-8, AC-1.1, AC-5.1 |
| Copy (§ 2.1 of the brief), one message per diagnostic code, built-in names | STEP-9 |

| Out | Home |
| --- | --- |
| Citations on the provenance sheet, the Person page and the Source page | S15-21, S15-22, S15-23 |
| Needed and used marks on boards | S15-39 |
| Choosing which Citation of the Source the preview uses | not planned (user, 2026-11-20: Source only) |
| Syntax colouring or inline underline in the text area | not planned (user, 2026-11-20: warnings listed under the field) |
| Caching the formats read in the session | not planned (D-9) |
| Moving `CitationRunsText` to `Platform/` | S15-21, its second caller |

## 4. Current state

Verified at `34c2b61`.

| Area | Where | Today |
| --- | --- | --- |
| Preview | `core/database/citationrender/preview.go` `RenderPreview` | Refuses neither-or-both targets and a Source target with a form other than `list` (`citations.ErrInvalid`); loads the target, then checks the format; a Source target loads through `loadSource` (`load.go`), `cited` nil |
| Preview load | `core/database/citationrender/load.go` `loadCitations`, `loadSource`, `fillValues` | `fillValues` reads Artifact and graph values only for a subject with `cited`; a Source subject answers Source values and built-ins |
| Citations | `core/database/citations/citations.go` `ListCitedTx` | No read from a Source to its Citations. Citation ids are UUIDv7 (`uuid.NewV7`, line 231). Indexes: `evidence_graphs_source_id_idx` (migration 000055), `citations_graph_artifact_idx` (000059) |
| Type update | `core/database/sourcetypes/sourcetypes.go` `Update(tx, id, label, description, iconKey)` | `editableTx`, normalises, `updateChange(existing, next, nil)`, `sqlUpdate`; one change or none |
| Formats write | `core/database/sourcetypes/formats.go` `UpdateFormats`, `ToStored`, `writeStoredTx`, `viewTx`, `checkChoices`, `updateChange(prev, next, formats)` | `UpdateFormats` builds its own change `updateChange(existing, existing, fields)`; `checkChoices` accepts a choice for a key the text does not use and refuses one for a missing field or another key |
| Handlers | `api/ffi/handlers/source_defs.go` `UpdateSourceType` (one `writes.Run`, action `update_source_type`), `GetCitationFormats`, `UpdateCitationFormats` (own `writes.Run`), `fieldChoicesFromProto`, `citationFormatsProto` | Two RPCs for one page |
| Built-ins RPC | `api/ffi/handlers/citation_render.go` `ListCitationBuiltins`; `core/citationformat/builtins.go` `Builtins()`, `ListFormAllows`, `Builtin.InListForm()`; `FieldRef.Token()` | Lists the table; no Go code writes a whole placeholder's text; no Swift caller |
| Proto | `api/proto/engine.proto` `UpdateSourceTypeRequest` (fields 1–6), `UpdateSourceTypeResponse`, `UpdateCitationFormatsRequest/Response`, `METHOD_UPDATE_CITATION_FORMATS = 121`, `METHOD_LIST_CITATION_BUILTINS = 126`, `ListCitationBuiltinsRequest/Response`, `CitationBuiltin`, `CitationFormats`, `CitationRender`, `CitationMissing`, `CitationRequirementOption` | As S15-15 and S15-16 left them |
| Tests using the formats write | `api/ffi/handlers/source_defs_test.go`, `metadata_test.go` (line 458), `vocabulary_write_effects_test.go` (line 33), `citation_render_test.go` (20 references to `UpdateCitationFormats` in all); `core/database/sourcetypes/formats_test.go` (line 82, `UpdateFormats`) | Seed formats through the RPC or function this PR retires |
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
| Latest call | `macos/App/Features/Catalog/Search/CatalogSearchModel.swift` (`debounceTask`, `searchGeneration`), `macos/App/Features/Catalog/CatalogCounts.swift` (`refreshGeneration`) | Two hand-written generation counters |
| Mutations | `macos/App/Features/Workspace/Session/CatalogMutation.swift`; `CatalogQueryRegistry.swift` `.sourceWorkspace` descriptor (`invalidateOn` six kinds; `default` → `.allCached(.sourceWorkspace)`) | No formats case |
| Tests | `macos/ProvenenciaTests/SourceTypePageModelTests.swift`, `SourceTypeCopyModelTests.swift`, `CatalogQueryRegistryTests.swift` `wroteTypeSuggestionsInvalidatesOnlySourcePages`; `core/database/citationrender/preview_test.go` `TestRenderPreview`; `api/ffi/handlers/citation_render_test.go` `TestRenderCitationPreview`, `TestListCitationBuiltins` | As above |

**Precedent.** S15-33 ([`S15-33-artifact-update-saves-metadata.md`](S15-33-artifact-update-saves-metadata.md)): an update request gains an optional draft and saves it in the same write. S15-12 ([#856](https://github.com/Jake-Robins-Studios/provenencia/pull/856)): one view drawn per level with `PVSubsectionHeader`; copy that shape per `CitationForm`. S15-18 ([#877](https://github.com/Jake-Robins-Studios/provenencia/pull/877)): a model with `PVFormLoadState` over a store read. `.wroteTypeSuggestions` and its registry test: the mutation.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | **One PR** for the editor and the preview | User, 2026-11-20 (asked against the size rule) | An editor PR and a preview PR — the user kept one |
| D-2 | **A Source target takes every form.** For `full` and `short`, `RenderPreview` renders against the Source's first Citation: `citations.FirstOfSourceTx(tx *sql.Tx, sourceID []byte) ([]byte, error)` *(new)*: `SELECT c.id FROM citations c JOIN evidence_graphs g ON g.id = c.graph_id WHERE g.source_id = ? ORDER BY c.id LIMIT 1`; nil and no error when none; `ErrInvalid` for an id not 16 bytes. With a Citation, the preview loads it through `loadCitations`; without one, through `loadSource`. `list` keeps `loadSource`. A Source not in the catalog is `sources.ErrNotFound`, checked by `loadSource` before the Citation lookup | User, 2026-11-20: the preview picks a Source only. Ids are UUIDv7, so the smallest is the oldest Citation, stable as Citations are added; both joins are indexed | A Citation picker — the user chose Source only; full and short from the Source alone always — every Artifact and graph field would read empty though Citations exist |
| D-3 | **The format is checked first; with no target it is all there is.** `RenderPreview`: an unknown form, both targets, or an id not 16 bytes → `ErrInvalid`; no target and `Format == nil` → `ErrInvalid`. Then, when `Format != nil`, `ToStored` runs first; diagnostics return alone (AC-7.6: even for a Citation not in the catalog). No target → an empty `Preview` after that. Then the target loads | Warnings while typing on a type with no Sources (AC-3.6) through the one preview request (rule "One render request for previews") | A Swift parser — rule "One engine, in Go"; warnings only on Save — CF-4 asks for them while typing; a check RPC — the preview already checks |
| D-4 | **One Save is one write.** `UpdateSourceTypeRequest` gains `optional CitationFormats formats = 7;` (`type_id` inside is ignored; `full`, `short`, `list`, `field_choices` used). `UpdateSourceTypeResponse` gains `CitationFormats formats = 3; repeated CitationFormatDiagnostic diagnostics = 4;` (set only when the request carried formats). `sourcetypes.UpdateWithFormats(tx *database.Tx, id []byte, label, description, iconKey string, formats Formats, choices []FieldChoice) (Type, FormatsView, []rowchange.Change, error)` *(new)*: `editableTx`; `ToStored`; diagnostics → the stored view with `Diagnostics`, no change, no write; else `writeStoredTx`, then the column write of `Update`, and **one** change `updateChange(existing, next, fields)`. `Update` and `UpdateWithFormats` share an unexported `updateColumnsTx` *(new)* holding today's `Update` body after `editableTx`. `UpdateFormats` is deleted (its only callers are the retired handler and `formats_test.go`, whose helper calls `UpdateWithFormats` with the type's own label, description and icon). The handler calls `UpdateWithFormats` when `formats` is present, else `Update`, in today's one `writes.Run`; a reply with diagnostics records nothing (the op returns no change). `UpdateCitationFormats` goes: handler, `MethodUpdateCitationFormats`, its `Call` case, its messages; `METHOD_UPDATE_CITATION_FORMATS = 121` becomes `reserved 121; reserved "METHOD_UPDATE_CITATION_FORMATS";`. The 20 test references seed formats through `UpdateSourceType` with formats, through one helper `setFormats(t, world, typeID, Formats)` *(new, `harness_test.go`)* | Map review (M-1): a user action needing two writes carries the owning layer's change, one transaction and one history entry (`plan-spike` "No client-side copy of an engine rule", S15-33's precedent). The user's "Share Details' Save" (2026-11-20) asked for one Save; this makes it one write | Two RPCs ordered in Swift — a client copy of atomicity, two revisions per Save; keeping `UpdateCitationFormats` beside — a second write path with no caller |
| D-5 | **Insert rows come from Go.** Method 126 becomes `METHOD_LIST_CITATION_PLACEHOLDERS` (the number kept; no client calls 126 yet). `ListCitationPlaceholdersRequest { project_dir = 1; form = 2; }`, `CitationPlaceholder { level = 1; builtin = 2; option = 3; MetadataField field = 4; text = 5; }`, `ListCitationPlaceholdersResponse { repeated CitationPlaceholder placeholders = 1; }` *(new)*; `ListCitationBuiltins*` and `CitationBuiltin` messages, the handler and `TestListCitationBuiltins` go. Go: `citationformat.BuiltinPlaceholders(f Form) []Placeholder` and `citationformat.MetaPlaceholder(l vocabkey.Level, key string) string` *(new, pure)*: `Placeholder{Level, Builtin, Option, Text}`; per level in `vocabkey` order, kept by `ListFormAllows` for `list`; each built-in `{level.name}` and, for each option other than `full`, `{level.name:option}`. `citationrender.Placeholders(c *database.Catalog, f citationformat.Form) ([]Placeholder, error)` *(new; `Placeholder` with a `Field *metadatafields.Field`)*: per allowed level, the built-ins, then (metadata levels) every field from `metadatafields` by lowercased label then key, text `MetaPlaceholder`. Handler `ListCitationPlaceholders` in `citation_render.go`; a bad form → `citations.invalid` | Map review (M-2): the placeholder syntax and the list-form rule live once, in Go (rules "Built-in placeholders are one table", "One engine, in Go") | Swift composing `{level.meta.key}` and filtering levels — a client copy of the syntax and of `ListFormAllows` |
| D-6 | **Swift store.** `CatalogCitationFormats` gains `fieldChoices: [String: String] = [:]` (key → field id). New *(in `GenealogyStore.swift` beside it)*: `CatalogCitationDiagnostic { form: CitationForm; code: String; utf8Start: Int; utf8End: Int }`, `CatalogCitationFormatsReply { formats: CatalogCitationFormats; diagnostics: [CatalogCitationDiagnostic] }`, `CatalogCitationRender { runs: [CatalogCitationRun]; plain: String }` with `CatalogCitationRun { text: String; italic: Bool }` (one decoder of the wire's `CitationRender`, for S15-21 and S15-22 too), `CatalogCitationOption { level: Level; field: CatalogMetadataField?; builtin: CitationBuiltin? }`, `CatalogCitationPreview { render: CatalogCitationRender; missing: [[CatalogCitationOption]]; diagnostics: [CatalogCitationDiagnostic] }`, `CatalogCitationPlaceholder: Identifiable { id: String (= text); level: Level; builtin: CitationBuiltin?; option: CitationOption?; field: CatalogMetadataField?; text: String }`. `GenealogyStore`: `citationFormats(projectDir:typeID:) -> CatalogCitationFormatsReply` (changed; `SourceTypeCopyModel.loadFormats()` takes `.formats`); `updateSourceType(projectDir:userID:typeID:label:description:iconKey:formats: CatalogCitationFormats?) -> (CatalogSourceType, CatalogCitationFormatsReply?, CatalogWriteEffects)` (changed: `formats` nil sends none; the reply is nil when none was sent); `renderCitationPreview(projectDir:form:format:fieldChoices:sourceID:) -> CatalogCitationPreview` *(new; `format: String?`, `sourceID: String?`)*; `citationPlaceholders(projectDir:form:) -> [CatalogCitationPlaceholder]` *(new)*. A form, level, option or built-in Swift does not know is dropped while decoding; an unknown diagnostic code is kept (generic message, D-16) | One reply type for read and write; one render type for preview and batch (M-4) | A separate formats update method — D-4 |
| D-7 | **One formats model, no AppKit.** `SourceTypeFormatsModel` in `macos/App/Features/SourceTypes/SourceTypeFormatsModel.swift` *(new)*, `@MainActor @Observable`, made by `SourceTypePageModel.init` as `let formats`, given `typeID`, `session`, `store` and `debounce: Duration = .milliseconds(300)`. It reads whether the type is locked from `session.sourceType(id:)` itself (`isEditable`, computed; false until the type loads). It holds saved and draft texts, `fieldChoices`, warnings per form, placeholders per form, the explicit preview pick, renders and missing per form, `isRendering`, `previewError`, `loadState: PVFormLoadState`. It never touches a text view: the view owns the `PVTextAreaCursor`s (D-12) | The page model is 420 lines; §2.5 keeps AppKit out of models | Growing `SourceTypePageModel`; cursors in the model (M-11) |
| D-8 | **The Save.** `SourceTypePageModel.isDirty` = not locked and (Details differ, or `formats.isDirty`), the formats test placed before the Details guard. `canSubmit` = not saving, Label valid, `isDirty`. `submit()` calls `updateSourceType` with the Details draft (or the saved values when only formats changed) and `formats.isDirty ? formats.draftForSave() : nil`. A reply with diagnostics: `formats.refused(reply)` (warnings show, D-11), `saveError` = "Fix the marked formats, then save.", nothing applied. Success: `session.apply(effects, .updatedSourceType(type))`, and, when formats were sent, `session.apply(.changedCitationFormats(typeId:))` and `formats.saved(reply)`; the toast per what was sent (Details only → today's; formats only → "Citation formats saved" / "<label>'s citations now use these formats."; both → "Source type updated" / "<label> and its citation formats are saved."). A thrown error sets `saveError` as today. `revertEdit()` also calls `formats.revert()`. `draftForSave()` carries each choice whose field is still in the vocabulary (D-14) | User, 2026-11-20 (one Save); D-4 makes it one write | Two writes — M-1 |
| D-9 | **Reads.** `formats.load()` from the page's `.task`: `citationFormats` and the three `citationPlaceholders` calls (one per form), together, into `loadState` (`PVFormLoadState.combining`); not a `CatalogQueryKey`. Placeholder rows hold a field's label at read; a Metadata edit is seen next time the page mounts | One reader holding a draft; Back to the page reads again; the Copy sheet reads on its own (S15-18) | A query key — invalidation for one reader with a draft |
| D-10 | **Latest call.** `LatestCall` in `macos/App/Platform/LatestCall.swift` *(new)*, a `@MainActor final class`: `func run<T: Sendable>(after delay: Duration = .zero, _ work: @escaping @Sendable () async throws -> T, apply: @escaping @MainActor (Result<T, Error>) -> Void)` cancels the pending task, sleeps `delay` (a cancelled sleep ends the call), runs `work`, and calls `apply` only while it is still the newest call; `cancel()`. `CatalogSearchModel` (its `debounceTask` / `searchGeneration`) and `CatalogCounts` (`refreshGeneration`) move onto it, their behaviour and tests unchanged. The formats model holds one per form | Map review (M-6): the third copy is extracted in the PR that adds it | A third hand-written counter |
| D-11 | **Preview and warnings.** Each form's preview runs through its `LatestCall` with `format` = the draft (editable) or nil (locked), the draft's choices, and `sourceID` = the effective pick (nil when none). An edit to one form runs that form after `debounce`; `rerenderAll()` runs all three with no delay. The view calls `rerenderAll()` on `.onChange(of: effectivePickID, initial: true)` (the pick, the Sources list landing, a Source leaving) and after a Save. While a call runs its last render stays and `isRendering` is true; an error sets `previewError`, cleared on the next success; `sources.not_found` clears the explicit pick. **Warnings belong to text:** each form keeps `diagnosed: (text, diagnostics)` from the read, a preview reply or a refused Save, for the text that was sent; the view shows them only while the draft equals `diagnosed.text` | The engine is the only renderer; spans are offsets into the sent text | Rendering all three per keystroke; shifting spans in Swift |
| D-12 | **Cursor handle.** `PVTextAreaCursor` *(new, `@MainActor final class`, in `PVTextArea.swift`)*: `weak var textView: NSTextView?`, `private(set) var hasCaret = false`, `@discardableResult func insert(_ text: String) -> Bool` (nil text view → false; else `insertText(text, replacementRange:)` at `selectedRange()` when `hasCaret`, else at the end; `makeFirstResponder`; true), `func select(_ range: NSRange)`. `PVTextArea` gains `cursor: PVTextAreaCursor? = nil`; `PVTextEditorInsetView.clearInsets()` sets `cursor.textView`; `PVTextAreaTabRouter` forwards `textViewDidChangeSelection(_:)` to the existing delegate and sets `cursor.hasCaret = true` while the text view is first responder. The view owns `@State` cursors per form; on an Insert commit it calls `cursor.insert(row.text)` and, when it returns true, `model.didInsert(row, into: form)` | `TextEditor(selection:)` is macOS 15 (target 14.0); the text view keeps its selection while focus is in the picker | Appending always — CF-3 asks for the cursor |
| D-13 | **Spans in Swift.** `CatalogCitationDiagnostic.range(in text: String) -> Range<String.Index>?` *(new)*: offsets through `text.utf8.index(_:offsetBy:limitedBy:)`, nil when out of range or not on a character boundary. The quote is `text[range]`, cut to 40 characters with an ellipsis; a zero-width span quotes nothing. Selecting uses `NSRange(range, in: text)` | Go spans are UTF-8 bytes | Character counts — wrong for non-ASCII text |
| D-14 | **Choices.** `didInsert(row, into:)` records `fieldChoices[field.key] = field.id` for every field row. The Select on an `ambiguous_field` line (key = the span's text) lists the vocabulary fields with that key (label · origin pill copy) and sets the choice. `draftForSave()` and previews send each choice whose field id is still in `session`'s metadata fields list | `checkChoices` accepts any existing field of the key and refuses only a missing one (M-3); no Swift copy of the ambiguity rule | Sending only keys Swift counts as shared |
| D-15 | **Preview Sources.** `DerivedValueID.sourcesOfType(typeID: String)` *(new)*, built from `.sourcesList`: the type's Sources by `CatalogSource.updatedOrder(_:_:)` *(new static, revision then id, both descending)*, which `SourcesModel.buildVisibleSources()`'s `.updated` case also calls. The model keeps only `pickedSourceID: String?`; `effectivePickID` = the pick when it is in the list, else the list's first | §2.5 and M-5: one derivation, one "most recently changed" order | A filtered copy in the model |
| D-16 | **Copy.** `L10n.CitationFormats` *(new)*: `builtinName(_:option:)` (eight names, "Date, year only" for `.sourceDate` with `.year`), `formTitle(_:)`, `formMeaning(_:)`, `diagnostic(_ code: CitationDiagnosticCode?, key: String)` (nil → "This part of the format cannot be read"), `missing(_ chain: [CatalogCitationOption])`. `L10n.SourceTypes.LevelCopy` gains `name` ("Source", "Artifact", "Evidence graph", "Citation"), so one switch over `Level` still holds the level copy; the missing line and the Insert row chip use `level(_:).name`. The editor's chrome under `L10n.SourceTypes.Formats` *(new)*. **Missing line:** one line per chain, "Missing: " then the options joined by ", or ", each "<name> on the <level name>"; a later option with the first's name reads "on the <level name>" alone ("Missing: Line on the Evidence graph, or on the Source"); a built-in's name is `builtinName` | Domain copy S15-39 and S15-21 reuse; one `Level` switch (M-13) | A second `Level` switch |
| D-17 | **Count.** `draft.unicodeScalars.count` against `CitationFormatLimit.maxCharacters`, grouped by the locale ("4,001 / 4,000"); over → `PVSubsectionHeader`'s meta in the danger tone | Go counts code points (S15-16 Landed) | `String.count` |
| D-18 | **Locked type.** `isEditable` false: read-only forms, previews send `format: nil`, no Insert field, no count, no warnings, no Save or Revert (`VocabularyFormActions` hidden when locked); with no Sources, the same no-Sources note | CF-11; the write is `sourcetypes.origin_locked` | Editable text that cannot save |
| D-19 | **Cache signal.** `CatalogMutation.changedCitationFormats(typeId: String)` *(new, bust-only)*, `CatalogMutationKind.changedCitationFormats` *(new)*; the `.sourceWorkspace` descriptor adds it to `invalidateOn` (its `default`: `.allCached(.sourceWorkspace)`) and its comment names it. `docs/catalog-caches.md` records it: the Swift "Per-view query results" row's **Updated by** cell gains "a Save carrying citation formats (`.changedCitationFormats`) marks every cached Source page stale" | Working rule "Requirements need a refresh signal" ("records it in `docs/catalog-caches.md`") | Invalidating only the type's Sources — a cached page does not carry its type id without a read |
| D-20 | **Kit extensions.** `PVSubsectionHeader` gains `metaTone: PVSubsectionHeader.MetaTone = .muted` (`.muted`, `.danger`) and an optional trailing accessory (`init(title:meta:metaTone:accessory:content:)`, `accessory` defaulting to `EmptyView`); today's callers are unchanged. `macos/App/DesignSystem/README.md` gets one line each for the cursor handle and the header's tone and accessory | Brief inventory: Extend (M-9); one change in the kit | A local header |

**Rules this plan bends.** The working rule "One render request for previews and the list entry" read "a target (one Citation, or a Source for the list form)"; D-2 and D-3 widen it. Asked: user, 2026-11-20, "Source only" for the preview, and warnings while typing (brief CF-4). Done: the rule was updated in the map at planning (2026-11-20). The rule "Requirements need a refresh signal" said S15-17 "applies a typed mutation after S15-15's write"; D-4 moves that write onto `UpdateSourceType`. It is the user's one Save, made one write per `plan-spike` "No client-side copy of an engine rule". The map's rule and the S15-17 scope entry were updated at planning (2026-11-20). The implementer edits neither.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `citations.FirstOfSourceTx` *(new)* | func | `citations.ListCitedTx` | That reads by Citation id; this finds one id by Source |
| `sourcetypes.UpdateWithFormats`, `updateColumnsTx` *(new)* | funcs | `sourcetypes.Update`, `UpdateFormats` (deleted) | One write and one change for both (D-4) |
| `citationformat.BuiltinPlaceholders`, `MetaPlaceholder`, `Placeholder` *(new)* | pure funcs | `Builtins()`, `FieldRef.Token()` | The table and the syntax own the text (D-5) |
| `citationrender.Placeholders` *(new)*, `ListCitationPlaceholders` *(new, method 126)* | func, FFI | `ListCitationBuiltins` (replaced) | Needs the vocabulary; replaces the built-ins RPC |
| `CatalogCitationDiagnostic`, `CatalogCitationFormatsReply`, `CatalogCitationRender`, `CatalogCitationRun`, `CatalogCitationOption`, `CatalogCitationPreview`, `CatalogCitationPlaceholder` *(new)* | types | `CatalogCitationFormats` | Extended where it fits (`fieldChoices`); the rest are wire shapes Swift lacks |
| `renderCitationPreview`, `citationPlaceholders` *(new)* | store methods | `citationFormats` | One per RPC |
| `SourceTypeFormatsModel` *(new)* | model | `SourceTypePageModel`, `SourceTypeCopyModel` | D-7 |
| `SourceTypeFormatsSection.swift` *(new)*: `SourceTypeFormatsSection`, `SourceTypeFormatEditor`, `SourceTypeFormatWarning`, `SourceTypeFormatPreview`, `CitationRunsText` | views | `SourceTypeSuggestedFields`, `SourceTypeSuggestionList` | One form view drawn three times (S15-12's shape) |
| `PVTextAreaCursor` *(new)*; `PVSubsectionHeader` tone and accessory | kit | `PVFieldFocus`; `PVSubsectionHeader` | Extend, not a new control (D-12, D-20) |
| `LatestCall` *(new)* | Platform | `CatalogSearchModel`, `CatalogCounts` counters | They move onto it (D-10) |
| `DerivedValueID.sourcesOfType`, `CatalogSource.updatedOrder` *(new)* | derived, func | `.visibleSources`, its inline `.updated` sort | D-15 |
| `CatalogMutation.changedCitationFormats` *(new)* | mutation | `.wroteTypeSuggestions` | Bust-only |
| `L10n.CitationFormats`, `L10n.SourceTypes.Formats`, `LevelCopy.name` *(new)* | L10n | `L10n.SourceTypes.level(_:)` | D-16 |
| `setFormats` *(new, `api/ffi/handlers/harness_test.go`)* | test helper | the 20 `UpdateCitationFormats` call sites | One seed path |

**Builds on.** S15-16's preview (`RenderPreview`, `loadCitations`, `loadSource`); S15-15's `ToStored`, `writeStoredTx`, `updateChange`; S15-33's optional-draft update; S15-12's per-level view; `PVComboBox`, `PVSelect`, `PVRetryCallout`, `PVFormLoadArea`, `PVFocusRingButtonStyle`, `PVErrorText`, `OriginPill`, `VocabularyFormActions`; `WorkspaceLeaveGuard`; the registry's `invalidateOn`; `session.derived`.
**Deletes.** `UpdateCitationFormats` (handler, dispatch constant and case, request and response messages; method 121 reserved), `sourcetypes.UpdateFormats`, `ListCitationBuiltins` (handler, its messages, `CitationBuiltin` message, `TestListCitationBuiltins`; method 126 renamed), the preview's "a Source target takes the list form only" refusal and its doc sentence and proto comment, the `TestRenderPreview` / `TestRenderCitationPreview` cases that expect `citations.invalid` for a Source target with `full` or `short` or for no target with a format (rewritten), `CatalogSearchModel.searchGeneration` / `debounceTask` and `CatalogCounts.refreshGeneration` (moved onto `LatestCall`), the inline `.updated` comparator in `SourcesModel` (moved to `CatalogSource.updatedOrder`). The `docs/citation-formats.md` sentences naming `UpdateCitationFormats` and `ListCitationBuiltins`.
**Next adds.** S15-23 calls `renderCitationPreview(form: .list, format: nil, sourceID:)`. S15-21 and S15-22 decode `CatalogCitationRender` and move `CitationRunsText` to `Platform/`. S15-39 maps `CatalogCitationOption` with `L10n.CitationFormats.missing` and `builtinName`. A new built-in or option is one row in `citationformat.builtins`, and Insert field shows it with no Swift change beyond its parity case and name.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A Source target with `full` / `short` | `RenderPreview` → `loadCitations` | The id was read in the same transaction; a Source with none goes through `loadSource` (AC-7.2) |
| No target with a format | `RenderPreview` | Returns after `ToStored`, before any load (AC-7.3, AC-7.4) |
| `UpdateSourceType` with formats | `writes.Run` `update_source_type` | Diagnostics return no change, so no revision (AC-7.8); a locked type is `origin_locked` from `editableTx` as today |
| The page mounts per type (`viewIdentity`) | `SourceTypeFormatsModel` | One model per type |
| The picked Source deleted elsewhere | `effectivePickID` (D-15) and `sources.not_found` (D-11) | Falls back to the list's first |
| A field in a draft deleted on the Metadata page | Preview / save | Go returns `unknown_field`; its choice is not sent (D-14) |
| A type deleted while its page is open | `isGone` leaves the page (today) | The model goes with the page |

### Scale

At the map's Scale (a type used by 500 Sources; 3,000 Sources; 63 fields): a preview call reads one Source, one Citation id (one indexed query) and the values one template names (S15-16 D-4); at most one call per form per 300 ms pause. `ListCitationPlaceholders` reads the fields once per form at page load: at most 63 × 3 + 9 rows. `sourcesOfType` filters the cached 3,000 rows once per list revision (`session.derived`). A Save with formats invalidates every cached `sourceWorkspace` key (at most 50 hidden plus the shown); hidden ones are marked stale, not reloaded. The write's cost is S15-15's `UpdateFormats` plus today's `Update`, in one transaction.

### Edges

- **Assumptions.** `fillValues` handles a subject with or without `cited` (S15-16 D-4); D-2 only chooses which. One `source_types` change per write: `updateChange(existing, next, fields)` already takes the format diffs (S15-15). `insertText(_:replacementRange:)` reaches the SwiftUI binding through the delegate chain the tab router forwards (Stop condition if not).
- **Neighbors.** A Source target with `list`, a Citation target with no format, and `UpdateSourceType` without formats are unchanged (T-1, T-3, T-11). No target and no format is still refused (AC-7.5).
- **Removed inputs.** A deleted Source: `sources.not_found` (D-11, D-15). A deleted field: `unknown_field`, its choice dropped (D-14). A deleted Citation between lookup and load cannot happen (one transaction).
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
| `core/database/sourcetypes` | `UpdateWithFormats`, `updateColumnsTx` *(new)*; `Update` calls `updateColumnsTx`; `UpdateFormats` deleted (D-4) |

Errors: unchanged codes.

### FFI

`api/proto/engine.proto`: D-4's fields on `UpdateSourceTypeRequest` / `Response`; `UpdateCitationFormats*` removed, 121 reserved; method 126 renamed `METHOD_LIST_CITATION_PLACEHOLDERS` with D-5's messages; `ListCitationBuiltins*` and `CitationBuiltin` removed; `RenderCitationPreviewRequest`'s comment: "Renders one form against one target, or checks an unsaved format with none. A Source target takes every form: the full and short read its first Citation, or the Source alone when it has none. With no target, format is required and only its diagnostics come back." Regenerate with `./scripts/generate-proto.sh` (needs `protoc`, `protoc-gen-go` and `protoc-gen-swift` on the machine; the generated `api/proto/engine/engine.pb.go` and `macos/App/Platform/Generated/engine.pb.swift` are committed). `api/ffi/dispatch.go`: `MethodUpdateCitationFormats` and its case removed; `MethodListCitationBuiltins` → `MethodListCitationPlaceholders`. `macos/App/Platform/CoreInvoke.swift`: `renderCitationPreview`, `listCitationPlaceholders` *(new)*.

### macOS

From the brief's inventory (the board may refine look and placement):

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Section | `PVSectionHeader` "Citation formats" + hint, the forms inside `PVFormLoadArea(state: formats.loadState …)` | `SourceTypeFormatsSection.swift` *(new)* | Under Details in `SourceTypePageContent.primary`; the read's failure is `PVFormLoadArea`'s retry |
| One form | `PVSubsectionHeader(title:meta:metaTone:)` (meta = count) + meaning + `PVTextArea(typography: .mono, lineLimit: 3...10, cursor:)` | `SourceTypeFormatEditor` *(new)* | Drawn per `CitationForm.allCases`; `isInvalid` when its shown warnings are not empty |
| Insert field | `PVComboBox` (`value` = the row's `id`; label = built-in name or field label; subtext = level name and text) with a caller row: label, `OriginPill` for a field, `PVChip` level name, mono text | in `SourceTypeFormatEditor` | `onCommit` looks the row up by id, then D-12 |
| Warning line | `Button` with `PVFocusRingButtonStyle`: `PVIcon(.warning)`, then `PVErrorText`-styled message and quote | `SourceTypeFormatWarning` *(new)* | Click or Return → `cursor.select`; `ambiguous_field` adds `PVSelect` (D-14) |
| Read-only form | `PVCard` sunken, mono `Text` | in `SourceTypeFormatEditor` | Locked type |
| Preview | `PVSubsectionHeader` "Preview" with a small `ProgressView` as its accessory while any form renders; `PVComboBox` Source picker (label title, subtext ref, value id; placeholder "Choose a <type> Source"); its hint; three rows of `CitationRunsText(render:)`; missing lines as `PVCallout` neutral compact; failure `PVRetryCallout(message:retry:isRetrying:compact:retryIdentifier:onRetry:)` → `rerenderAll()`; no Sources `PVCallout` neutral compact | `SourceTypeFormatPreview` *(new)* | |
| Save / Revert | `VocabularyFormActions`, the `saveError` Callout above it | moved from `form` to the foot of `primary`, after the section | Hidden on a locked type |
| Leave confirm | unchanged | `SourceTypePageView` | `isDirty` includes formats |

Accessibility (CF-12): each area labelled by its form title; the count spoken "560 of 4,000 characters"; a warning is a button "<message> at “<quote>”" with hint "Selects it in the format"; each Insert picker names its form; each preview row is one element "<form title>: <plain>". Identifiers: `sourceTypes.formats.<form>.text`, `.insert`, `.count`, `.warning.<index>`, `sourceTypes.formats.preview.source`, `sourceTypes.formats.preview.<form>`.

### Strings

From the brief § 2.1; the agreed board's text wins. Keys *(new)*: `sourceTypes.formats.*` (section title, hint, empty placeholders, Insert placeholder, spoken label, no-match, count format and its spoken form, warning "at" format and hint, shared-key label, preview title, picker label, placeholder with the type label, hint, "No format", no-Sources note, preview failed title, Save refused Callout, the two new toasts); `citationFormats.*` (eight built-in names, "Date, year only", form titles and meanings, the missing line's "Missing: %@", "%1$@ on the %2$@", "on the %@", ", or ", one message per `CitationDiagnosticCode` and the generic one); `sourceTypes.suggested.level.<level>.name` (four). Diagnostic messages: `too_long` "Too long", `too_deep` "Too many groups and italics inside each other", `unclosed_placeholder` "This brace is never closed", `stray_close_brace` "This brace closes nothing", `unclosed_group` "Unclosed group", `stray_close_bracket` "This bracket closes no group", `unclosed_italic` "Italic is never closed", `bad_escape` "A backslash can only come before { } [ ] * or \\", `group_without_placeholder` "A group needs a field in it", `empty_option` "Empty field", `bad_character` "A field name cannot hold this character", `unprefixed_meta` "Name a level before meta: source, artifact or graph", `unknown_level` "Not a level: use source, artifact, graph or citation", `meta_not_at_level` "A citation has no metadata fields", `bad_field` "Not a field key", `unknown_builtin` "Not a built-in field at this level", `unknown_option` "This option does not apply here", `not_in_list_form` "The source list reads the Source only", `unknown_field` "No field has the key %@", `ambiguous_field` "Two fields have the key %@: choose one", `unknown_form` generic. Existing copy that names the old scope: `L10n.SourceTypes.saveChanges` and `revert` keep their text and now cover the formats.

## 7. Steps

**STEP-1 — The preview takes a Source for every form and a format alone**
Files: `core/database/citations/citations.go`, `citations_test.go`, `core/database/citationrender/preview.go`, `preview_test.go`, `api/ffi/handlers/citation_render_test.go`. Skills: `add-catalog-query`.
Do: D-2, D-3.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/citations/ ./core/database/citationrender/ ./api/ffi/handlers/ -run 'TestFirstOfSource|TestRenderPreview|TestRenderCitationPreview'` passes (T-1 – T-3).

**STEP-2 — One write saves a type's details and formats**
Files: `core/database/sourcetypes/sourcetypes.go`, `formats.go`, `formats_test.go`, `sourcetypes_test.go`; `api/proto/engine.proto`, generated files; `api/ffi/dispatch.go`; `api/ffi/handlers/source_defs.go`, `source_defs_test.go`, `harness_test.go`, `metadata_test.go`, `vocabulary_write_effects_test.go`, `citation_render_test.go`. Skills: `add-ffi-handler`, `add-audit-scope`.
Do: D-4; regenerate with `./scripts/generate-proto.sh`.
Check: `rg -n 'UpdateCitationFormats|UpdateFormats\(' core api --glob '!*.pb.go'` finds nothing; `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcetypes/ ./api/ffi/...` passes (T-11).

**STEP-3 — Go lists the Insert field rows**
Files: `core/citationformat/placeholder.go` *(new)*, `placeholder_test.go` *(new)*, `core/database/citationrender/placeholders.go` *(new)*, `placeholders_test.go` *(new)*, `api/proto/engine.proto`, generated files, `api/ffi/dispatch.go`, `api/ffi/handlers/citation_render.go`, `citation_render_test.go`. Skill: `add-ffi-handler`.
Do: D-5.
Check: `rg -n 'ListCitationBuiltins' core api --glob '!*.pb.go'` finds nothing; `CGO_ENABLED=1 go test -tags fts5 ./core/citationformat/ ./core/database/citationrender/ ./api/ffi/...` passes (T-12, T-13).

**STEP-4 — The Swift store**
Files: `macos/App/Platform/GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift`, `CoreInvoke.swift`, `macos/App/Features/SourceTypes/SourceTypeCopyModel.swift`, `SourceTypePageModel.swift` (the call's new argument, `formats: nil`). Skill: `add-swift-test`.
Do: D-6. FakeStore: `citationFormatsByType` holds `CatalogCitationFormatsReply`; `updateSourceTypeCalls` record `formats`; `updateSourceTypeFormatsReply` for a refused reply; `previewReplies: [CitationForm: CatalogCitationPreview]`, `previewCalls` (form, format, choices, sourceID), `previewError`; `placeholdersByForm`.
Check: `SourceTypeCopyModelTests` and `SourceTypePageModelTests` pass.

**STEP-5 — Shared Swift plumbing: latest call, the Sources of a type, the cache signal**
Files: `macos/App/Platform/LatestCall.swift` *(new)*, `CatalogSearchModel.swift`, `CatalogCounts.swift`, `WorkspaceSession+Derived.swift`, `SourcesModel.swift`, `GenealogyStore.swift` (`CatalogSource.updatedOrder`), `CatalogMutation.swift`, `CatalogQueryRegistry.swift`, `docs/catalog-caches.md`, tests `macos/ProvenenciaTests/LatestCallTests.swift` *(new)*, `CatalogQueryRegistryTests.swift`. Skill: `add-workspace-place`.
Do: D-10, D-15, D-19.
Check: T-4, T-5 pass; the existing search, counts and Sources list tests pass.

**STEP-6 — Kit: cursor handle and header tone**
Files: `macos/App/DesignSystem/Components/TextArea/PVTextArea.swift`, `macos/App/DesignSystem/Components/SubsectionHeader/PVSubsectionHeader.swift`, `macos/App/DesignSystem/README.md`, `macos/ProvenenciaTests/PVTextAreaCursorTests.swift` *(new)*. Skill: `add-ui-component`.
Do: D-12, D-20.
Check: T-6 passes; every existing `PVTextArea` and `PVSubsectionHeader` caller compiles unchanged.

**STEP-7 — The formats model and the one Save**
Files: `macos/App/Features/SourceTypes/SourceTypeFormatsModel.swift` *(new)*, `SourceTypePageModel.swift`, `macos/ProvenenciaTests/SourceTypeFormatsModelTests.swift` *(new)*, `SourceTypePageModelTests.swift`. Skill: `add-swift-test`.
Do: D-7 – D-9, D-11, D-13 – D-15, D-17, D-18. Model API: `init(typeID:session:store:debounce:)`, `load()`, `loadState`, `isEditable`, `draft(_:)`, `edit(_:text:)`, `isDirty`, `fieldChoices`, `shownDiagnostics(_:)`, `count(_:)`, `isOverLimit(_:)`, `placeholders(_:)`, `didInsert(_:into:)`, `choose(fieldID:forKey:)`, `pickedSourceID`, `previewSources` (reads D-15), `effectivePickID`, `pick(sourceID:)`, `render(_:)`, `missing(_:)`, `isRendering`, `previewError`, `rerenderAll()`, `revert()`, `draftForSave()`, `refused(_:)`, `saved(_:)`.
Check: T-7 – T-10 pass and the existing page model tests pass.

**STEP-8 — The section and its preview on the page**
Files: `macos/App/Features/SourceTypes/SourceTypeFormatsSection.swift` *(new)*, `SourceTypePageView.swift` (the section under Details; `VocabularyFormActions` and the save error moved to the foot of `primary`; `.task` also runs `model.formats.load()`; `.onChange(of: model.formats.effectivePickID, initial: true)`; the `#Preview` sets Census formats, placeholders and two Sources in `FakeStore`). Skill: `add-ui-component`.
Do: § 6 macOS and the agreed board.
Check: `xcodebuild test` builds; the `#Preview` shows the section; manual check steps 1 – 3.

**STEP-9 — Copy**
Files: `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `macos/ProvenenciaTests/CitationFormatsCopyTests.swift` *(new)*. Skill: `add-localized-string`.
Do: D-16 and § 6 Strings.
Check: T-14 passes; `rg -n 'Text\("' macos/App/Features/SourceTypes/SourceTypeFormatsSection.swift` finds nothing.

**STEP-10 — Gate and docs**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj` (`MARKETING_VERSION`); `docs/citation-formats.md` (§ Storage: formats save with `UpdateSourceType`, one write with the details; § Rendering "The preview": D-2, D-3; `ListCitationPlaceholders` in place of `ListCitationBuiltins`); `../deployment-plan.md` (map row status); `../completed.md`; `../design/S15-D16-source-type-citation-formats.md` → `../design/archive/`, `../design/README.md`; this plan.
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
| T-6 | Swift | `PVTextAreaCursorTests.swift` *(new)* | `NSTextView` "abc", `hasCaret` true, selection 1 → `insert("X")` → "aXbc", selection 2, returns true; `hasCaret` false → "abcX"; `select(NSRange(1..<3))` → selected 1..<3; nil text view → returns false | D-12, AC-2.2, AC-2.5, AC-3.2 |
| T-7 | Swift | `SourceTypeFormatsModelTests.swift` `insertAndChoices` *(new)* | `didInsert` of a field row → `fieldChoices[key] = id`; of a built-in row → none; `draftForSave()` drops a choice whose field left the vocabulary; `choose(fieldID:forKey:)` sets it and re-renders that form | AC-2.4, AC-3.4, D-14 |
| T-8 | Swift | `SourceTypeFormatsModelTests.swift` `diagnosticsAndCount` *(new)* | `unclosed_group` 0..<1 for `[x` → shown while the draft is `[x`, hidden after `edit` to `[xy`; `range(in:)` on `é{` span 2..<3 → the `{`; span 1..<2 → nil; 4,001 scalars → `isOverLimit` | AC-1.8, AC-3.1, AC-3.5, D-11, D-13, D-17 |
| T-9 | Swift | `SourceTypeFormatsModelTests.swift` `preview` *(new)* (debounce zero) | No Sources → calls with `sourceID` nil; the list lands → `effectivePickID` = highest revision, `rerenderAll` sends three; an edit to `.full` sends one call for `.full` with the draft and the pick; `pick(sourceID:)` then `rerenderAll` sends three; `sources.not_found` clears the pick; locked → `format` nil; an error → `previewError`, cleared on success | AC-3.6, AC-4.1, AC-4.2, AC-4.3, AC-4.7, AC-4.8, AC-5.1, D-11, D-15, D-18 |
| T-10 | Swift | `SourceTypePageModelTests.swift` `saveSendsDetailsAndFormatsInOneWrite` *(new)* | Formats dirty only → one `updateSourceType` with formats and the saved Details, toast "Citation formats saved", `.changedCitationFormats` applied; both → one call, the "both" toast; Details only → `formats` nil, today's toast, no `.changedCitationFormats`; a reply with diagnostics → `saveError`, nothing applied, edits kept, warnings shown; `isDirty` true with only a format edit (leave guard holds); `revertEdit()` restores formats | AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, AC-1.7, D-8 |
| T-11 | Go | `core/database/sourcetypes/formats_test.go` (helper moved to `UpdateWithFormats`) and `api/ffi/handlers/source_defs_test.go` `TestUpdateSourceTypeWithFormats` *(new)* | Label and full note together → one revision, one `source_types` change holding `label` and `citation_full`; a diagnostic → no revision, empty effects, diagnostics in the reply, label unchanged; no formats → today's reply, `formats` unset; a plugin type → `sourcetypes.origin_locked` | AC-7.7, AC-7.8, D-4 |
| T-12 | Go | `core/database/citationrender/placeholders_test.go` `TestPlaceholders` *(new)* | AC-7.9 and AC-7.10 on a 3-field project; and on a new project (the seed): for each of the 26 types and each form, `GetCitationFormats` text through a no-target `RenderPreview` → zero diagnostics | AC-7.9, AC-7.10, D-5 |
| T-13 | Go | `core/citationformat/placeholder_test.go` `TestBuiltinPlaceholders` *(new)* | `list` → the four Source rows; `full` → every built-in, plus `{source.date:year}`, none for `:full`; `MetaPlaceholder(LevelGraph, "line_number")` → `{graph.meta.line_number}`, and the text parses | D-5 |
| T-14 | Swift | `CitationFormatsCopyTests.swift` *(new)* | Every `CitationDiagnosticCode` and nil → a non-empty message; every built-in and `Level` → a non-empty name; `missing([Line@graph, Line@source])` → "Missing: Line on the Evidence graph, or on the Source"; `missing([Jurisdiction@source])` → "Missing: Jurisdiction on the Source" | AC-4.4, D-16 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: the handler tests that seeded formats (D-4), `TestRenderPreview`, `TestRenderCitationPreview`, `SourceTypePageModelTests`, `SourceTypeCopyModelTests`, the search and counts tests (D-10), `TestSwiftVocabularyMatchesGo`.

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
2. In the full note, put the cursor before the final period; Insert field → type "line" → Line (Evidence graph). `{graph.meta.line_number}` appears at the cursor; a moment later the preview's full note changes. Save changes: toast "Citation formats saved"; reopen: the text stays (AC-2.1, AC-2.2, AC-4.2, AC-1.3).
3. Delete a `]` in the short note: the warning shows with its quote; click it: the text is selected. Save: refused with the Callout; restore the `]` (AC-3.1, AC-3.2, AC-3.5, AC-1.5).
4. Pick the 1870 Source: "Missing: Jurisdiction on the Source" under the full note; full and short render from the Source alone (AC-4.3, AC-4.4, AC-4.5).
5. Type `{citation.page}` into the source list: its warning, and its preview row is empty while the full row still renders; the Insert field there offers Source rows only. Revert (AC-3.3, AC-4.6, AC-2.3).
6. Edit the short note, press Back: the discard confirm. Keep editing; Revert (AC-1.7).
7. Open a Source page of the type, go back and save a format change, return to the Source page: it reloads (AC-6.1).
8. Change Label and the short note together, Save: the "both" toast, and the type's history shows one entry (AC-1.4). Change Label alone, Save: today's toast (AC-1.6).
9. In Metadata, add a field with the key `page`; in the full note write `{source.meta.page}`: the shared-key warning with its Select; choose one and save. Then Insert field "page": two rows, told apart by their origin pills (AC-3.4, AC-2.4).
10. Grave memorial (or any plugin type): read-only formats, the preview, no Save (AC-5.1).
11. At a 2,560pt window: the same centred pair; the cursor and pick survive the resize.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| `insertText` does not reach the SwiftUI binding | T-6 checks the text view; manual check step 2 checks the binding; Stop condition |
| Two changes for one row break the audit | D-4 builds one change with `updateChange(existing, next, fields)`; T-11 counts it |
| Preview calls pile up while typing | D-10, D-11: one `LatestCall` per form |
| Moving search and counts onto `LatestCall` changes their timing | Their existing tests must pass unchanged |

**Stop and report if:**

- `RenderPreview`, `loadSource`, `Update` or `UpdateFormats` no longer does what § 4 says.
- `Update`'s body cannot move into `updateColumnsTx` without changing `Update`'s results (its tests fail).
- After `PVTextAreaCursor.insert`, the `PVTextArea` binding does not hold the inserted text.
- `CatalogSearchModel` or `CatalogCounts` tests need changing to pass on `LatestCall`.
- The agreed board draws a behavior a Decision rules out (an inline underline, a Citation picker, separate Saves, the formats outside the main column).
- Any seeded type's format comes back with a diagnostic (T-12).

## 12. Open questions

None for the code. The plan stays `Blocked — on board S15-D16` until the board is agreed and the § 6 macOS rows and Strings take its decisions.

## 13. PR

**Title:** S15-17 — The format editor
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-17-format-editor.md`.
