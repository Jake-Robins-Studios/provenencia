# S15-17 — The format editor

**Status:** Blocked — on board S15-D16
**Spike / slice:** Spike 15 · Slice 5 — Person page date and the format editor
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D16](../design/S15-D16-source-type-citation-formats.md), board not yet agreed
**Board:** — (filled in when the board is agreed: the artboard, its frames and how the implementer sees them)
**Depends on:** S15-12 (landed [#856](https://github.com/Jake-Robins-Studios/provenencia/pull/856)), S15-15 (landed [#871](https://github.com/Jake-Robins-Studios/provenencia/pull/871)), S15-16 (landed [#914](https://github.com/Jake-Robins-Studios/provenencia/pull/914)), S15-18 (landed [#877](https://github.com/Jake-Robins-Studios/provenencia/pull/877)), S15-48 (landed [#848](https://github.com/Jake-Robins-Studios/provenencia/pull/848)), S15-D16
**Blocks:** —
**Branch:** `s15-17-format-editor`
**Version bump:** minor, 0.29.0 → **0.30.0** (if `main`'s `VERSION` is no longer 0.29.0 when you rebase, the next minor after it): a new editor on the type page, and the preview RPC takes two inputs it refused before ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-catalog-query`](../../../../.agents/skills/add-catalog-query/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`use-catalog-session`](../../../../.agents/skills/use-catalog-session/SKILL.md), [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md) (the registry's `invalidateOn`), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests), `.cursor/rules/ffi-handlers.mdc`, `.cursor/rules/catalog-queries.mdc`, `.cursor/rules/macos-client.mdc`, `.cursor/rules/swift-tests.mdc`, `.cursor/rules/versioning.mdc`
**Context:** working rules "Citation formats are data on the Source type", "Every placeholder names its level; fallback is written", "Built-in placeholders are one table", "One render request for previews and the list entry", "Requirements need a refresh signal; renders do not", "Formats name fields by id", "A Source type has its own page", "One window; nothing is built for a second" ([`../deployment-plan.md`](../deployment-plan.md#working-rules)); [`../evidence-explained-citation-map.md`](../evidence-explained-citation-map.md) § 6.3 "The editor"; [`docs/citation-formats.md`](../../../citation-formats.md) (syntax, Storage, Rendering, Diagnostics); landed plans [`S15-15-type-stores-citation-formats.md`](S15-15-type-stores-citation-formats.md) (D-3, D-11, **Next adds**), [`S15-16-citations-render.md`](S15-16-citations-render.md) (D-9, D-10, D-14 and its Landed note), [`S15-12-type-suggestions-at-each-level.md`](S15-12-type-suggestions-at-each-level.md) (D-6: the list header), [`S15-18-copy-source-type.md`](S15-18-copy-source-type.md) (the formats read)
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

A researcher edits a Source type's three citation formats (full note, short note, source list) on the type's page. Each format has an **Insert field** picker that puts the prefixed placeholder at the cursor, a character count against the 4,000 limit, and the engine's warnings listed under it, each selecting the text it is about. A preview under the formats fills each form in for a Source of the type as the researcher types. One Save writes the Details and the formats; leaving with unsaved formats asks. This is bar 5's first half ("Editing the census full format on its Source type page updates a live preview against a real Source").

**Why now.** The engine (S15-14), storage (S15-15), the preview call (S15-16), the type page with its suggestion lists (S15-48, S15-12) and Copy (S15-18) have landed. Until now no screen shows a format: the seed (S15-19) writes them and nobody can change them.

**What stays.** Details' fields, the side column's suggestion lists, the header with Copy and Delete, the types list and both dialogs. `RenderCitations`, `GetCitationFormats` and `UpdateCitationFormats` keep their wire. Swift never parses a format (rule "One engine, in Go"); every warning, render and missing field comes from Go.

## 2. User stories

**US-1.** As a researcher, on an editable type's page, I edit its three formats and save them with Details' Save, so its citations change.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Census's page opens | The Citation formats section shows Full note, Short note and Source list with the stored text by key (`{source.meta.jurisdiction}`, never `#<id>`), each with "used / 4,000" |
| AC-1.2 | Append ` Test.` to the full note | Save changes and Revert enable; Revert puts the stored text back and disables them |
| AC-1.3 | Append ` Test.` to the full note, Save | One `UpdateCitationFormats` with all three forms; no `UpdateSourceType`; toast "Citation formats saved"; reopening the page shows the new text |
| AC-1.4 | Change Label to "Census (US)" and the short note, Save | `UpdateCitationFormats` then `UpdateSourceType`; toast "Source type updated" / "Census (US) and its citation formats are saved." |
| AC-1.5 | Delete the `]` of `[, p. {citation.page}]` in the short note, Save | Nothing saves (no `UpdateSourceType` either); the short note shows "Unclosed group at “[, p. {citation.page}”"; the Callout "Fix the marked formats, then save." shows beside Save; every edit stays |
| AC-1.6 | The full note saves, then `UpdateSourceType` fails with `sourcetypes.duplicate_key` | The full note's saved text is the new one (Revert no longer brings back the old); the save error shows beside Save; Label keeps its edit |
| AC-1.7 | Unsaved full note, then Back | Today's discard confirm; Discard leaves and drops it; Keep editing stays |
| AC-1.8 | A full note of 4,001 characters (`unicodeScalars.count`) | Its count reads "4,001 / 4,000" in the danger tone; the engine's `too_long` warning shows |

**US-2.** As a researcher, I insert a field without remembering the syntax.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | The full note's Insert field, type "line" | Rows for Line at Source, Artifact and Evidence graph, each with its level Chip and its text (`{graph.meta.line_number}`), in level order |
| AC-2.2 | Cursor after "census," in the full note; choose Line at Evidence graph | `{graph.meta.line_number}` is inserted at the cursor; the picker clears; the cursor sits after the insert in the text area |
| AC-2.3 | The source list's Insert field | Only Source-level rows: Title, Type, Date, Date (year only), then the fields; no Artifact, Evidence graph or Citation row |
| AC-2.4 | Two fields hold the key `page` (Provenencia's and the researcher's); choose the researcher's Page at Source | `{source.meta.page}` is inserted and no `ambiguous_field` warning follows: the pick set the key's choice |

**US-3.** As a researcher, I see what is wrong with a format where it is wrong.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Type `{source.meta.jurisdicton}` in the short note and stop typing | Within a moment: "No field has the key jurisdicton at “jurisdicton”"; the area's border is danger |
| AC-3.2 | Click that warning | The text area takes focus with `jurisdicton` selected |
| AC-3.3 | Type `{citation.page}` in the source list | "The source list reads the Source only at “{citation.page}”" (`not_in_list_form`, spanning the option `citation.page`) |
| AC-3.4 | Write `{source.meta.page}` while two fields hold `page` | The `ambiguous_field` warning carries a Select of the two Page fields; choosing one clears the warning, and Save stores that field |
| AC-3.5 | Fix the text so it parses | The warning lines go and the border returns to normal |
| AC-3.6 | Type with no Sources of the type (Letter) | Warnings still show (the preview call with no target) |

**US-4.** As a researcher, I see each form filled in for a real Source of the type as I type.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | Census's page opens, Sources "1880 census, Calder County" (latest revision) and "1870 census, Calder County" | The preview picks the 1880 Source and shows three rows rendered with italics |
| AC-4.2 | Edit the full note | A moment after typing stops, the Full note row shows the render of the unsaved text; the other rows do not re-render |
| AC-4.3 | Pick the 1870 Source | All three rows re-render for it |
| AC-4.4 | The picked Source has no `jurisdiction` | Under the full note: "Missing on this Source: Jurisdiction" |
| AC-4.5 | A Source with no Citations | Full and short render from the Source alone: Artifact, Evidence graph and Citation placeholders are empty and their groups drop (D-2) |
| AC-4.6 | The short note has a warning | Its row shows no render; the full and list rows still do |
| AC-4.7 | The preview call fails | A retry Callout in place of the rows; Try again renders again |

**US-5.** As a researcher on a plugin's type, I read its formats and preview them, and cannot edit them.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-5.1 | Grave memorial (plugin, locked) with a full note only | Full note read only in a sunken Card; the other two read "No format"; no Insert field, no count, no Save or Revert; the preview renders the stored full note |

**US-6.** As the boards, after a format save, every cached Source page re-reads its requirements.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-6.1 | Two Source pages cached, then a format Save | Both `sourceWorkspace` keys are invalidated by `.changedCitationFormats(typeId:)` |

**US-7.** As the preview call, I take a Source target for every form and a format with no target.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-7.1 | `RenderCitationPreview` form `full`, Source target whose graphs hold two Citations | Renders against the Citation with the smaller id (the older UUIDv7) |
| AC-7.2 | Form `short`, Source target with no Citation | Renders from the Source alone: Source values answer; `{citation.page}` is empty |
| AC-7.3 | Form `full`, no target, format `[, p.` | Diagnostics only (`unclosed_group`); empty render, no missing |
| AC-7.4 | Form `full`, no target, format `{source.title}.` | Empty render, no missing, no diagnostics, no error |
| AC-7.5 | No target, no format | `citations.invalid` |

## 3. Scope

| In | Covered by |
| --- | --- |
| Go: a Source target takes every form, through the Source's first Citation (D-2) | STEP-1, AC-7.1, AC-7.2 |
| Go: a format with no target returns its diagnostics only (D-3) | STEP-1, AC-7.3 – AC-7.5 |
| Swift store: formats read with choices and diagnostics, `updateCitationFormats`, `renderCitationPreview`, `listCitationBuiltins` (D-4) | STEP-2 |
| Cache signal `.changedCitationFormats(typeId:)` and its `docs/catalog-caches.md` row (rule "Requirements need a refresh signal") | STEP-3, AC-6.1 |
| `PVTextArea` cursor handle (S15-D16 inventory: Extend) | STEP-4, AC-2.2, AC-3.2 |
| The formats model: draft, choices, warnings, count, Insert field options, preview (CF-2 – CF-8) | STEP-5, US-2 – US-4 |
| One Save and Revert for Details and formats; the leave guard (CF-9, CF-10) | STEP-6, AC-1.2 – AC-1.7 |
| The section view, the preview, the locked type, VoiceOver (CF-1, CF-7, CF-11, CF-12, CF-W1) | STEP-7, AC-1.1, AC-5.1 |
| Copy, including one message per diagnostic code and the built-in names (§ 2.1 of the brief) | STEP-8 |

| Out | Home |
| --- | --- |
| Citations on the provenance sheet, the Person page and the Source page | S15-21, S15-22, S15-23 |
| Needed and used marks on boards | S15-39 |
| Choosing which Citation of the Source the preview uses | not planned (user, 2026-11-20: Source only) |
| Syntax colouring or inline underline in the text area | not planned (brief non-goal; user, 2026-11-20: warnings listed under the field) |
| Caching the formats read in the session | not planned (D-7) |
| One atomic write for Details and formats | not planned (D-6: two writes behind one Save; user, 2026-11-20) |
| Moving the rendered-runs view to the kit | S15-21, when it is the second caller |

## 4. Current state

Verified at `34c2b61`.

| Area | Where | Today |
| --- | --- | --- |
| Preview | `core/database/citationrender/preview.go` `RenderPreview` | Refuses neither-or-both targets and a Source target with a form other than `list` (`citations.ErrInvalid`); loads the target before checking the format; a Source target loads through `loadSource` (`load.go`), `cited` nil |
| Preview load | `core/database/citationrender/load.go` `loadCitations`, `loadSource`, `fillValues` | `fillValues` reads Artifact and graph values only for a subject with `cited`; a Source subject answers Source values and built-ins |
| Citations | `core/database/citations/citations.go` `ListCitedTx`, `columns` | No read from a Source to its Citations. Citation ids are UUIDv7 (`uuid.NewV7`, line 231). Indexes: `evidence_graphs_source_id_idx`, `citations_graph_artifact_idx` (migrations 000055, 000059) |
| Preview handler | `api/ffi/handlers/citation_render.go` `RenderCitationPreview` | An unset oneof leaves `Target` empty → `citations.invalid` |
| Formats handlers | `api/ffi/handlers/source_defs.go` `GetCitationFormats`, `UpdateCitationFormats`, `fieldChoicesFromProto`, `citationFormatsProto` | Read and write by key with `field_choices` and diagnostics; a plugin type's write is `sourcetypes.origin_locked` (`editableTx`) |
| Choices | `core/database/sourcetypes/formats.go` `checkChoices` | A choice for a key the text does not use is accepted; a choice naming a missing field, or a field of another key, or a key twice is `ErrInvalid` |
| Proto | `api/proto/engine.proto` `RenderCitationPreviewRequest`, `CitationFormats`, `CitationFormatDiagnostic`, `CitationBuiltin`, `CitationMissing`, `CitationRequirementOption`, `CitationRender` | As S15-15 and S15-16 left them. The preview request's comment says a Source target takes the list form only |
| Swift formats type | `macos/App/Platform/GenealogyStore.swift` `CatalogCitationFormats` (`typeID`, `full`, `short`, `list`, `text(_:)`) | No choices, no diagnostics |
| Swift read | `macos/App/Platform/GoStore.swift` `citationFormats(projectDir:typeID:)`; `FakeStore.citationFormats`, `citationFormatsByType`, `citationFormatsError` | Drops `field_choices` and `diagnostics`. Only caller: `SourceTypeCopyModel.loadFormats()` |
| Swift parity enums | `macos/App/Platform/CitationFormatVocabulary.swift` `CitationForm`, `CitationOption`, `CitationDiagnosticCode`, `CitationBuiltin`, `CitationFormatLimit.maxCharacters` | Held to Go by `api/ffi/swift_vocabulary_test.go`; no view uses them |
| Swift store | `GenealogyStore` | No `updateCitationFormats`, `renderCitationPreview` or `listCitationBuiltins`; `CoreInvoke.swift` has `getCitationFormats` only of the five citation methods |
| Page model | `macos/App/Features/SourceTypes/SourceTypePageModel.swift` `SourceTypePageModel` (420 lines) | Details draft, `isDirty`, `canSubmit`, `submit()`, `revertEdit()`, the suggestion writes, Copy, Delete, `shouldHoldNavigation` (holds when `isDirty`) |
| Page view | `macos/App/Features/SourceTypes/SourceTypePageView.swift` `SourceTypePageContent` | `primary` = `details`: `PVSectionHeader` "Details", the form, then `VocabularyFormActions` at the form's foot |
| Suggestion header | `macos/App/Features/SourceTypes/SourceTypeSuggestionList.swift` `header` | `PVSubsectionHeader(title:meta:)` with the meaning in micro italic muted: the shape the brief's form header takes |
| Text area | `macos/App/DesignSystem/Components/TextArea/PVTextArea.swift` `PVTextArea`, `PVTextEditorInsetClearer`, `PVTextEditorInsetView.clearInsets()` / `nearestTextView()` | SwiftUI `TextEditor` (macOS 14 target: no selection binding); the inset view already finds the area's `NSTextView` |
| ComboBox | `macos/App/DesignSystem/Components/ComboBox/PVComboBox.swift` `PVComboBox`, `PVComboBoxOption(value:label:subtext:)` | Filters on label and subtext; caller rows; `onCommit` |
| Mutations | `macos/App/Features/Workspace/Session/CatalogMutation.swift` `CatalogMutation`, `CatalogMutationKind`, `invalidationKind` | No formats case |
| Registry | `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift` `.sourceWorkspace` descriptor | `invalidateOn` lists six kinds; `default` → `.allCached(.sourceWorkspace)` |
| Sources | `macos/App/Features/Workspace/Session/WorkspaceSession+Sources.swift`; `CatalogSource.sourceTypeID`, `updated.revision` | The cached Sources list carries each Source's type and last revision |
| Debounce precedent | `macos/App/Features/Catalog/Search/CatalogSearchModel.swift` `debounceTask`, `searchGeneration` | Cancel the pending task, sleep, check the generation before applying |
| Copy | `macos/App/Platform/L10n.swift` `L10n.SourceTypes` (line 8020), `L10n.Errors` | No formats copy |
| Tests | `macos/ProvenenciaTests/SourceTypePageModelTests.swift`, `SourceTypeCopyModelTests.swift`, `CatalogQueryRegistryTests.swift` `wroteTypeSuggestionsInvalidatesOnlySourcePages`; `core/database/citationrender/preview_test.go` `TestRenderPreview`; `api/ffi/handlers/citation_render_test.go` `TestRenderCitationPreview` | As above |

**Precedent.** S15-12 ([#856](https://github.com/Jake-Robins-Studios/provenencia/pull/856)) extended this page with one view drawn per level and the `PVSubsectionHeader` header: copy that shape for one form view drawn per `CitationForm`. S15-18 ([#877](https://github.com/Jake-Robins-Studios/provenencia/pull/877)) added a store method beside `citationFormats` and a model with a `PVFormLoadState`: copy its GoStore and FakeStore shape. `CatalogSearchModel` is the debounce. `.wroteTypeSuggestions` and its registry test are the mutation precedent.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | **One PR** for the editor and the preview | User, 2026-11-20 (asked against the size rule: about 10 steps; this plan has 10) | S15-17 editor + a preview PR — the user kept one |
| D-2 | **A Source target takes every form.** For `full` and `short`, `RenderPreview` renders against the Source's first Citation: `citations.FirstOfSourceTx(tx *sql.Tx, sourceID []byte) ([]byte, error)` *(new)*: `SELECT c.id FROM citations c JOIN evidence_graphs g ON g.id = c.graph_id WHERE g.source_id = ? ORDER BY c.id LIMIT 1`; nil and no error when none. With a Citation, the preview loads it through `loadCitations` (as a Citation target); without one, through `loadSource` (Source values only). `list` keeps `loadSource`. A Source not in the catalog is `sources.ErrNotFound` before the Citation lookup | User, 2026-11-20: the preview picks a Source only. Ids are UUIDv7, so the smallest is the oldest Citation, stable as Citations are added; both joins are indexed | A Citation picker under the Source — user chose Source only; rendering full and short from the Source alone always — every Artifact and graph field reads empty though Citations exist |
| D-3 | **A format with no target returns its diagnostics only.** `RenderPreview` accepts an empty `Target` when `Format != nil`: it runs `ToStored` and returns `Preview{Diagnostics: diags}` (empty render, no missing, no error) without loading a target. No target and no format → `citations.ErrInvalid`. The format is checked before the target is loaded on every call | Warnings while typing on a type with no Sources (AC-3.6) through the one preview request (rule "One render request for previews") | A Swift parser — rule "One engine, in Go"; warnings only on Save — CF-4 asks for them while typing; a new check RPC — the preview already checks |
| D-4 | **Swift store.** `CatalogCitationFormats` gains `fieldChoices: [String: String] = [:]` (key → field id). New `struct CatalogCitationDiagnostic: Sendable, Equatable { form: CitationForm; code: String; utf8Start: Int; utf8End: Int }`, `struct CatalogCitationFormatsReply: Sendable, Equatable { formats: CatalogCitationFormats; diagnostics: [CatalogCitationDiagnostic] }`, `struct CatalogCitationRun { text: String; italic: Bool }`, `struct CatalogCitationOption { level: Level; field: CatalogMetadataField?; builtin: CitationBuiltin? }`, `struct CatalogCitationPreview { runs: [CatalogCitationRun]; plain: String; missing: [[CatalogCitationOption]]; diagnostics: [CatalogCitationDiagnostic] }`, `struct CatalogCitationBuiltinInfo { builtin: CitationBuiltin; options: [CitationOption]; inListForm: Bool }` *(all new, `GenealogyStore.swift` beside `CatalogCitationFormats`)*. `GenealogyStore`: `citationFormats(projectDir:typeID:) -> CatalogCitationFormatsReply` (changed return; `SourceTypeCopyModel.loadFormats()` takes `.formats`); `updateCitationFormats(projectDir:userID:formats:) -> (CatalogCitationFormatsReply, CatalogWriteEffects)` *(new; `formats.typeID` names the type, `fieldChoices` go out as `field_choices`)*; `renderCitationPreview(projectDir:form:format:fieldChoices:sourceID:) -> CatalogCitationPreview` *(new; `format: String?`, `sourceID: String?`)*; `listCitationBuiltins() -> [CatalogCitationBuiltinInfo]` *(new)*. A diagnostic form, an option level or a built-in name Swift does not know is dropped while decoding (`Level(rawValue:)`, `CitationBuiltin(rawValue:)`); an unknown diagnostic code is kept and shown with the generic message (D-15) | One reply type for read and write, as the wire has; the option type is S15-39's next caller | Separate read methods for Copy and the editor — two decoders of one message |
| D-5 | **One formats model.** `SourceTypeFormatsModel` in `macos/App/Features/SourceTypes/SourceTypeFormatsModel.swift` *(new)*, `@MainActor @Observable`, owned by `SourceTypePageModel` as `let formats: SourceTypeFormatsModel`, made in its `init`. It holds the saved and draft formats, the choices, the warnings per form, the Insert options, the preview pick and renders. The page model keeps Save, Revert and the leave guard and asks it `isDirty`, `save(...)` and `revert()` | The page model is 420 lines and owns Details, suggestions, Copy and Delete; the formats are a second draft with their own reads | Growing `SourceTypePageModel` — about 300 more lines in one type |
| D-6 | **One Save, two writes, formats first** (user, 2026-11-20: Details' Save). `canSubmit` = not saving, Label valid, and Details or formats dirty. `submit()`: (1) formats dirty → `updateCitationFormats`; a reply with diagnostics stops here: nothing else is written, the warnings show (D-9), `saveError` = "Fix the marked formats, then save."; success → `session.apply(effects, .changedCitationFormats(typeId:))`, saved formats = the reply's. (2) Details dirty → today's `updateSourceType`; a failure sets `saveError` as today, the formats stay saved. (3) Toast per what saved: Details only → today's; formats only → "Citation formats saved" / "<label>'s citations now use these formats."; both → "Source type updated" / "<label> and its citation formats are saved." `revertEdit()` also calls `formats.revert()`. A thrown formats write (not diagnostics) sets `saveError` and writes nothing else | Formats are the likelier refusal and change no label the Details write reads | One atomic RPC — not planned (Out); Details first — a refused format after a saved label leaves a half save the researcher did not expect |
| D-7 | **Reads.** The formats model reads `citationFormats` once in `load()`, from the page's `.task` (`PVFormLoadState`, as `SourceTypeCopyModel`); not a `CatalogQueryKey`. Built-ins: `listCitationBuiltins()` once in `load()`. Fields: the page's `metadataFieldsList` handle. Sources: `session.query(.sourcesList(project:))` warmed in `load()` | One reader holding a draft; Back to the page reads again; the Copy sheet reads once on its own (S15-18) | A query key — needs invalidation for one reader with a draft |
| D-8 | **Preview scheduling.** Per form, a `Task` that sleeps 300 ms then calls `renderCitationPreview` with `format` = the draft text (editable type) or nil (locked), the draft's choices, and `sourceID` = the pick (nil when the type has no Sources). An edit to one form cancels and restarts that form's task only. A pick change, a load and a Save re-render all three at once (no sleep). Each form has a generation counter; a reply whose generation is old is dropped (`CatalogSearchModel` shape). While a form's call runs, its last render stays and `isRendering` is true. A thrown error sets `previewError` (one for the subsection) and clears on the next success | The engine is the only renderer; 300 ms keeps typing from flooding calls (one call per form per pause) | Rendering all three on each keystroke — 3× the calls for one changed form |
| D-9 | **Warnings belong to text.** Each form keeps `diagnosed: (text: String, diagnostics: [CatalogCitationDiagnostic])`, set from the load read, a preview reply and a refused save, for the text that was sent. The view shows a form's warnings only while its draft text equals `diagnosed.text`, so a warning never points into text that has changed; it reappears once the next reply lands | Spans are byte offsets into the sent text; after an edit they point at the wrong place | Shifting spans by the edit — reimplementing positions in Swift |
| D-10 | **Spans in Swift.** `CatalogCitationDiagnostic.range(in text: String) -> Range<String.Index>?` *(new)*: `utf8Start`/`utf8End` through `text.utf8.index(_:offsetBy:limitedBy:)`, nil when out of range or not on a character boundary (`samePosition(in: text)`). The quoted text is `text[range]`, cut to 40 characters with an ellipsis; a zero-width span quotes nothing and reads the message alone. Selecting uses `NSRange(range, in: text)` | Go spans are UTF-8 bytes (proto comment) | Treating offsets as `Character` counts — wrong for any non-ASCII text |
| D-11 | **Cursor handle.** `PVTextAreaCursor` *(new, `@MainActor final class`, in `PVTextArea.swift`)* with `weak var textView: NSTextView?`, `func insert(_ text: String)` (`textView.insertText(text, replacementRange: textView.selectedRange())`, then `window?.makeFirstResponder(textView)`) and `func select(_ range: NSRange)` (`makeFirstResponder`, `setSelectedRange`, `scrollRangeToVisible`). `PVTextArea` gains `cursor: PVTextAreaCursor? = nil`; `PVTextEditorInsetClearer` passes it to `PVTextEditorInsetView`, whose `clearInsets()` sets `cursor.textView = textView`. Every other caller is unchanged | The text view keeps its selection while focus is in the picker, so the insert lands at the last cursor; `insertText` goes through the text view's delegate, so the SwiftUI binding and undo follow | `TextEditor(selection:)` — macOS 15 only (target 14.0); appending to the end — CF-3 asks for the cursor |
| D-12 | **Insert options.** `SourceTypeFormatsModel.insertOptions(for form: CitationForm) -> [InsertOption]` *(new; `InsertOption { value: String; label: String; level: Level; fieldID: String? }`)*. Levels in `Level.allCases` order; `list` keeps `.source` only. Per level: the built-ins at that level from `listCitationBuiltins()` (only `inListForm` ones in `list`), in table order, `{level.name}`, plus one `{level.name:year}` row for each built-in whose options hold `year` (`full` is the bare form and gets no row); then for a metadata level every field of the vocabulary by label, `{level.meta.key}`, `fieldID` set. `PVComboBoxOption(value: "<level>|<value>|<fieldID>", label:, subtext: "<level name> <value>")` so search matches label, key and level. Committing inserts `value` through the form's cursor, sets `fieldChoices[key] = fieldID` when more than one vocabulary field holds that key, and clears the picker | One table for built-ins (rule "Built-in placeholders are one table"); a pick of a shared key needs no second question (AC-2.4) | Built-ins from the Swift parity enum alone — the rule says over FFI; a level menu then a field menu — two picks |
| D-13 | **Shared key choice.** For a diagnostic `ambiguous_field`, the key is the span's text; the candidates are the vocabulary fields with that key (`fields.filter { $0.key == key }`). A `PVSelect` on the warning line sets `fieldChoices[key]` and re-renders that form at once. Choices sent with a preview or a save are those whose key still holds more than one field and whose field is still in the vocabulary | `checkChoices` refuses a choice for a deleted field (`ErrInvalid`); a choice for a key no longer in the text is harmless | Sending every choice ever made |
| D-14 | **Preview pick.** The candidates are the cached Sources list's rows with `sourceTypeID == typeID`, by title. The default (on load, and when the picked Source leaves the list) is the highest `updated.revision`, ties by title. The pick lives in the model only. A `sources.not_found` reply clears the pick and re-defaults | Bar 5 "against a real Source" with no extra click; the list is already cached (D-7) | Persisting the pick — one more stored preference for a page-local choice |
| D-15 | **Copy.** New namespace `L10n.CitationFormats` *(new)*: `builtinName(_ builtin: CitationBuiltin)`, `levelName(_ level: Level)`, `diagnostic(_ code: CitationDiagnosticCode?, key: String)` (nil → "This part of the format cannot be read"), `formTitle(_:)`, `formMeaning(_:)`, the missing line. The editor's chrome under `L10n.SourceTypes.Formats` *(new)*. The text of each message is the board's; § 6 Strings lists the brief's wording | Built-in, level and diagnostic copy is domain copy S15-39 and S15-21 reuse; page chrome stays with the page | All under `SourceTypes` — the boards would import the type page's namespace |
| D-16 | **Count.** `draft.unicodeScalars.count` against `CitationFormatLimit.maxCharacters`, formatted with the locale's grouping ("4,001 / 4,000"); over the limit the meta text is danger | S15-16 Landed note: Go counts code points | `String.count` (grapheme clusters) — disagrees with Go on combining marks |
| D-17 | **Locked type.** No draft: the forms read only (D-5 `isEditable` false), previews send `format: nil`, no Insert field, no count, no warnings, no Save or Revert (`VocabularyFormActions` hidden when `isLocked`, as the Details form is today) | CF-11; the write would be `sourcetypes.origin_locked` | Editable text that cannot save |
| D-18 | **Cache signal.** `CatalogMutation.changedCitationFormats(typeId: String)` *(new, bust-only)*, `CatalogMutationKind.changedCitationFormats` *(new)*; the `.sourceWorkspace` descriptor adds it to `invalidateOn` (its `default` branch: `.allCached(.sourceWorkspace)`). `docs/catalog-caches.md` gets no new row (the Swift query-results row names the descriptor as the source of truth); its sentence on `sourceWorkspace` in `CatalogQueryRegistry.swift` gains the formats | Working rule "Requirements need a refresh signal" (S15-17); graph boards ride `.sourceWorkspace` since S15-11 | Invalidating only the type's Sources — the cached page does not say its type without a read |

**Rules this plan bends.** The working rule "One render request for previews and the list entry" reads "a target (one Citation, or a Source for the list form)"; D-2 lets a Source target take every form and D-3 lets a format go with no target → user, 2026-11-20: "Source only" for the preview, and warnings while typing (brief CF-4) → the rule was updated in the map at planning (2026-11-20) to "a target (one Citation, or a Source, whose first Citation answers the full and short forms) or, for a format's warnings alone, none". The implementer edits neither.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `citations.FirstOfSourceTx` *(new)* | func | `citations.ListCitedTx` | That reads Citations by id; this finds one id by Source. Sits in `citations` (table reads stay in their package) |
| `CatalogCitationDiagnostic`, `CatalogCitationFormatsReply`, `CatalogCitationRun`, `CatalogCitationOption`, `CatalogCitationPreview`, `CatalogCitationBuiltinInfo` *(new)* | types | `CatalogCitationFormats` | Extended where it fits (`fieldChoices`); the rest are wire shapes no Swift type holds yet |
| `updateCitationFormats`, `renderCitationPreview`, `listCitationBuiltins` *(new)* | store methods | `citationFormats`, `copySourceType` | One per RPC, as every store method |
| `SourceTypeFormatsModel` *(new)* | model | `SourceTypePageModel`, `SourceTypeCopyModel` | D-5 |
| `SourceTypeFormatsSection.swift` *(new)*: `SourceTypeFormatsSection`, `SourceTypeFormatEditor` (one form), `SourceTypeFormatWarnings`, `SourceTypeFormatPreview`, `CitationRunsText` | views | `SourceTypeSuggestedFields` / `SourceTypeSuggestionList` | One view per form drawn three times (S15-12's shape); `CitationRunsText` is S15-21's to move to `Platform/` when it is the second caller |
| `PVTextAreaCursor` *(new)* | kit handle | `PVFieldFocus` | Focus moves between fields; this reaches into one area's text view |
| `CatalogMutation.changedCitationFormats`, `CatalogMutationKind.changedCitationFormats` *(new)* | mutation | `.wroteTypeSuggestions` | A different write; bust-only |
| `L10n.CitationFormats`, `L10n.SourceTypes.Formats` *(new)* | L10n | `L10n.SourceTypes.level(_:)` | D-15 |

**Builds on.** S15-16's preview call (`RenderPreview`, `loadCitations`, `loadSource`); S15-15's formats RPCs; S15-12's per-level view and `PVSubsectionHeader`; `PVComboBox`; `PVSelect`; `VocabularyFormActions`; `WorkspaceLeaveGuard`; the registry's `invalidateOn`; `CatalogSearchModel`'s debounce.
**Deletes.** The preview's "a Source target takes the list form only" refusal and its doc sentence; the proto comment on `RenderCitationPreviewRequest`; the `TestRenderPreview` and `TestRenderCitationPreview` cases that expect `citations.invalid` for a Source target with `full` or `short`, or for no target (rewritten to the new results). Nothing else becomes dead.
**Next adds.** S15-23 calls `renderCitationPreview(form: .list, format: nil, sourceID:)`. S15-21 and S15-22 reuse `CatalogCitationRun` and move `CitationRunsText` to `Platform/`. S15-39 maps `CatalogCitationOption` and `L10n.CitationFormats.builtinName` / `levelName` for its hint.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A Source target with `full` / `short` | `citationrender.RenderPreview` → `loadCitations` | The Citation was just read in the same transaction, so it exists; a Source with none goes through `loadSource` (AC-7.2) |
| No target with a format | `RenderPreview` | Returns before any load (AC-7.3, AC-7.4) |
| The page mounts per type (`viewIdentity`) | `SourceTypeFormatsModel` | One model per type; a new type is a new page |
| The picked Source deleted elsewhere | `renderCitationPreview` → `sources.not_found` | D-14 re-defaults |
| A field named in a draft deleted on the Metadata page | Preview / save | Go returns `unknown_field`; a choice for it is not sent (D-13) |
| A type deleted while its page is open | `isGone` leaves the page (today) | The formats model is dropped with the page |

### Scale

At the map's Scale (a type used by 500 Sources; 3,000 Sources in the project; 63 fields): a preview call reads one Source, one Citation id (one indexed query), and the values one template names (S15-16 D-4: a fixed number of reads); at most one call per form per 300 ms pause. Insert options: 63 fields × 3 levels + 9 built-ins ≈ 200 ComboBox rows, filtered locally. The Source picker filters the cached list (3,000 rows) by type once per list change, in the model. A format save invalidates every cached `sourceWorkspace` key (at most the 50 hidden entities plus the shown ones); hidden ones are marked stale, not reloaded. `UpdateCitationFormats`' own cost is S15-15's.

### Edges

- **Assumptions.** `fillValues` handles a subject with or without `cited` (S15-16 D-4); D-2 only chooses which. `insertText(_:replacementRange:)` reaches the SwiftUI binding through the delegate chain that `PVTextAreaTabRouter` forwards (Stop condition if not).
- **Neighbors.** A Source target with `list` is unchanged (still `loadSource`, T-1). A Citation target is unchanged. A format with a target behaves as today. A preview with no format and no target is still refused (AC-7.5).
- **Removed inputs.** A Citation deleted between the lookup and the load cannot happen (one transaction). A deleted Source: `sources.not_found` (D-14). A deleted field: `unknown_field`; its choice is dropped (D-13).
- **Real data.** Every seeded type's three formats (S15-19) load with no diagnostics and render in the preview; the census full note is about 560 characters (T-7 uses it).
- **Untrusted size.** A crafted stored format over the limit loads as stored (S15-15: the read returns it with diagnostics); the text area scrolls past 10 lines; previews refuse it with `too_long`. The ComboBox list is bounded by the vocabulary.

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/citations` | `FirstOfSourceTx(tx *sql.Tx, sourceID []byte) ([]byte, error)` *(new)* (D-2); `ErrInvalid` for an id that is not 16 bytes |
| `core/database/citationrender` | `RenderPreview`: the target check becomes "both set, or a bad id length → `ErrInvalid`; none set and `Format == nil` → `ErrInvalid`"; the `Format` branch's `ToStored` runs first; none set → return its diagnostics (or an empty `Preview`); a Source target with `full` or `short` → `FirstOfSourceTx`, then `loadCitations` with that id or `loadSource`. Doc comment rewritten |

Errors: unchanged codes.

### FFI

`api/proto/engine.proto`: comments only. `RenderCitationPreviewRequest`: "Renders one form against one target, or checks an unsaved format with none. A Source target takes every form: the full and short read its first Citation, or the Source alone when it has none. With no target, format is required and only its diagnostics come back." Regenerate with `./scripts/generate-proto.sh` (comments reach the generated files). Handlers unchanged: an unset oneof already leaves `Target` empty. `macos/App/Platform/CoreInvoke.swift`: `updateCitationFormats`, `renderCitationPreview`, `listCitationBuiltins` *(new constants)*.

### macOS

From the brief's inventory (the board may refine look and placement; the plan's view Decision is filled from it when agreed):

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Section | `PVSectionHeader` "Citation formats" + hint | `SourceTypeFormatsSection.swift` *(new)* | Under Details in `SourceTypePageContent.primary`'s `details` |
| One form | `PVSubsectionHeader(title:meta:)` (meta = count) + meaning + `PVTextArea(typography: .mono, lineLimit: 3...10, cursor:)` | `SourceTypeFormatEditor` *(new)* | Drawn per `CitationForm.allCases`; `isInvalid` when its shown warnings are not empty |
| Insert field | `PVComboBox` with a caller row (label, `PVChip` level, mono text) | in `SourceTypeFormatEditor` | `onCommit` → model insert (D-12) |
| Warning line | `Button` (plain) with `PVIcon` warning, message, quoted text | `SourceTypeFormatWarnings` *(new)* | Click → `cursor.select`; `ambiguous_field` adds `PVSelect` (D-13) |
| Read-only form | `PVCard` sunken, mono `Text` | in `SourceTypeFormatEditor` | Locked type |
| Preview | `PVSubsectionHeader` "Preview" (+ `ProgressView` small while any form renders), `PVComboBox` Source picker, three rows of `CitationRunsText`, missing `PVCallout` neutral compact, `PVRetryCallout`-shaped failure (`PVCallout` danger with Try again calling `model.rerenderAll()`), no-Sources `PVCallout` neutral | `SourceTypeFormatPreview` *(new)* | |
| Save / Revert | `VocabularyFormActions` | moved from `form` to the foot of `primary`, after the section | `saveError` Callout above it, as today |
| Leave confirm | unchanged | `SourceTypePageView` | `isDirty` now includes formats |

States: loading (spinner in the section until the read is ready), read failed (`PVCallout` danger with Try again → `formats.load()`), editable, locked, no Sources, preview rendering, preview failed. Accessibility (CF-12): each area `accessibilityLabel` = form title; count spoken "560 of 4,000 characters"; warning button label "<message> at “<quote>”", hint "Selects it in the format"; picker label names its form; each preview row is one element "<form title>: <plain text>". Identifiers: `sourceTypes.formats.<form>.text`, `.insert`, `.count`, `.warning.<index>`, `sourceTypes.formats.preview.source`, `sourceTypes.formats.preview.<form>`.

### Strings

From the brief § 2.1 (the board may change wording; the agreed board's text wins). Keys *(new)* under `sourceTypes.formats.*` (section title, hint, form titles and meanings via `L10n.CitationFormats.formTitle/formMeaning`, empty placeholders, Insert placeholder, spoken label, no-match, count format and its spoken form, warning "at" format, shared-key label, preview title, picker label, placeholder and hint, "No format", missing line formats, no-Sources note, preview failed title, Save refused callout, the two new toasts) and `citationFormats.*` (eight built-in names plus "Date, year only", four level names, one message per `CitationDiagnosticCode` case and the generic one). Diagnostic messages, from the brief and `docs/citation-formats.md`: `too_long` "Too long", `too_deep` "Too many groups and italics inside each other", `unclosed_placeholder` "This brace is never closed", `stray_close_brace` "This brace closes nothing", `unclosed_group` "Unclosed group", `stray_close_bracket` "This bracket closes no group", `unclosed_italic` "Italic is never closed", `bad_escape` "A backslash can only come before { } [ ] * or \\", `group_without_placeholder` "A group needs a field in it", `empty_option` "Empty field", `bad_character` "A field name cannot hold this character", `unprefixed_meta` "Name a level before meta: source, artifact or graph", `unknown_level` "Not a level: use source, artifact, graph or citation", `meta_not_at_level` "A citation has no metadata fields", `bad_field` "Not a field key", `unknown_builtin` "Not a built-in field at this level", `unknown_option` "This option does not apply here", `not_in_list_form` "The source list reads the Source only", `unknown_field` "No field has the key %@", `ambiguous_field` "Two fields have the key %@: choose one", `unknown_form` (never sent by the editor) generic. Removed: none. Existing copy that names the old scope: `L10n.SourceTypes.saveChanges` and `revert` keep their text and now cover the formats.

## 7. Steps

**STEP-1 — The preview takes a Source for every form and a format alone**
Files: `core/database/citations/citations.go`, `core/database/citations/citations_test.go`, `core/database/citationrender/preview.go`, `core/database/citationrender/preview_test.go`, `api/proto/engine.proto` (comment), generated files, `api/ffi/handlers/citation_render_test.go`, `docs/citation-formats.md` § Rendering "The preview". Skills: `add-catalog-query`, `add-ffi-handler`.
Do: D-2, D-3; regenerate with `./scripts/generate-proto.sh`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/citations/ ./core/database/citationrender/ ./api/ffi/handlers/ -run 'TestFirstOfSource|TestRenderPreview|TestRenderCitationPreview'` passes (T-1 – T-3).

**STEP-2 — The Swift store carries formats, choices, diagnostics, previews and built-ins**
Files: `macos/App/Platform/GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift`, `CoreInvoke.swift`, `macos/App/Features/SourceTypes/SourceTypeCopyModel.swift`. Skill: `add-swift-test`.
Do: D-4. FakeStore: `citationFormatsByType` holds `CatalogCitationFormatsReply`; `citationFormatsUpdates: [CatalogCitationFormats]` records writes; `citationFormatsUpdateReply` / `citationFormatsUpdateError`; `previewReplies: [CitationForm: CatalogCitationPreview]`, `previewCalls` (form, format, choices, sourceID), `previewError`; `citationBuiltins` defaulting to the eight built-ins with `source.date` taking `[.year, .full]` and `inListForm` true for the Source ones.
Check: `SourceTypeCopyModelTests` pass.

**STEP-3 — A format save marks Source pages stale**
Files: `CatalogMutation.swift`, `CatalogQueryRegistry.swift`, `macos/ProvenenciaTests/CatalogQueryRegistryTests.swift`. Skill: `add-workspace-place`.
Do: D-18.
Check: T-4 passes.

**STEP-4 — The text area inserts and selects at its cursor**
Files: `macos/App/DesignSystem/Components/TextArea/PVTextArea.swift`, `macos/App/DesignSystem/README.md` (one line under TextArea). Skill: `add-ui-component`.
Do: D-11.
Check: T-5 passes; every existing `PVTextArea` caller compiles unchanged.

**STEP-5 — The formats model**
Files: `macos/App/Features/SourceTypes/SourceTypeFormatsModel.swift` *(new)*, `macos/ProvenenciaTests/SourceTypeFormatsModelTests.swift` *(new)*. Skill: `add-swift-test`.
Do: D-5, D-7 – D-10, D-12 – D-14, D-16, D-17. API: `init(typeID:session:store:)`, `load()`, `isEditable` (set by the page from `!isLocked`), `draft(_ form) -> String`, `edit(_ form, text:)`, `isDirty`, `fieldChoices`, `shownDiagnostics(_ form)`, `count(_ form)`, `insertOptions(for:)`, `insert(_ option, into form)` (calls the form's `PVTextAreaCursor`; `cursors: [CitationForm: PVTextAreaCursor]` made in `init`), `choose(fieldID:forKey:)`, `previewSources`, `previewSourceID`, `pick(sourceID:)`, `renders[form]`, `missing[form]`, `isRendering`, `previewError`, `rerenderAll()`, `revert()`, `save(userID:) async -> SaveOutcome` (`.unchanged`, `.saved(effects)`, `.refused`, `.failed(message)`). The 300 ms sleep is `static var debounce: Duration` so tests set zero.
Check: T-6 – T-8 pass.

**STEP-6 — One Save and Revert for Details and formats**
Files: `SourceTypePageModel.swift`, `macos/ProvenenciaTests/SourceTypePageModelTests.swift`.
Do: D-6; `isDirty` includes `formats.isDirty` (leave guard); `canSubmit` per D-6; `revertEdit()` calls `formats.revert()`.
Check: T-9 passes and the existing page model tests pass.

**STEP-7 — The section and its preview on the page**
Files: `SourceTypeFormatsSection.swift` *(new)*, `SourceTypePageView.swift` (the section under Details; `VocabularyFormActions` and the save error moved to the foot of `primary`; `.task` also runs `model.formats.load()`; the `#Preview` sets Census formats in `FakeStore`). Skills: `add-ui-component`.
Do: § 6 macOS and the agreed board.
Check: `xcodebuild test` builds; the `#Preview` shows the section; the manual check's steps 1 – 3 in the app.

**STEP-8 — Copy**
Files: `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`. Skill: `add-localized-string`.
Do: D-15 and § 6 Strings; no hard-coded English in the new views.
Check: T-10 passes; `rg -n 'Text\("' macos/App/Features/SourceTypes/SourceTypeFormatsSection.swift` finds nothing.

**STEP-9 — Gate**
Do: `scripts/check-pr.sh`.
Check: `check-pr: PASS`.

**STEP-10 — Docs**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj` (`MARKETING_VERSION`); `docs/citation-formats.md` (done in STEP-1; plus § Storage gains "The type page edits them; see the editor" one sentence); `../deployment-plan.md` (map row status; the rule and scope entry were updated at planning); `../completed.md`; `../design/S15-D16-source-type-citation-formats.md` → `../design/archive/`, `../design/README.md`; this plan.
Do: per the Definition of done.
Check: links resolve; `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-17-format-editor.md` passes.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/citationrender/preview_test.go` `TestRenderPreview` (extended) | Source target + `full` on a Source with two Citations → the render of the older one (its page in the text); + `short` on a Source with none → Source values, `{citation.page}` group dropped; + `list` unchanged; no target + `[, p.` → one `unclosed_group`; no target + `{source.title}.` → empty, no error; no target, no format → `citations.ErrInvalid`; both targets → `ErrInvalid` | AC-7.1, AC-7.2, AC-7.3, AC-7.4, AC-7.5, D-2, D-3 |
| T-2 | Go | `core/database/citations/citations_test.go` `TestFirstOfSource` *(new)* | Source with Citations in two graphs → the smallest id; Source with graphs and no Citations → nil; unknown Source → nil; 15-byte id → `ErrInvalid` | D-2 |
| T-3 | Go | `api/ffi/handlers/citation_render_test.go` `TestRenderCitationPreview` (extended) | Source target with form `full` → render (not `citations.invalid`); no target with `format` `[` → one diagnostic `{form "full", code "unclosed_group", start 0, end 1}` | AC-7.1, AC-7.3 |
| T-4 | Swift | `CatalogQueryRegistryTests.swift` `changedCitationFormatsInvalidatesSourcePages` *(new)* | Two cached `sourceWorkspace` keys and a `sourceTypesList` → apply `.changedCitationFormats(typeId: "t1")` → both Source keys invalidated, the types list not | AC-6.1, D-18 |
| T-5 | Swift | `macos/ProvenenciaTests/PVTextAreaCursorTests.swift` *(new)* | An `NSTextView` holding `abc` with selection at 1 → `insert("X")` → `aXbc`, selection at 2; `select(NSRange(1..<3))` → selected range 1..<3; nil text view → no crash, nothing happens | D-11, AC-2.2, AC-3.2 |
| T-6 | Swift | `SourceTypeFormatsModelTests.swift` `insertOptions` *(new)* | Fields Line (`line_number`), two Page fields; `.full` → Source built-ins first (Title, Type, Date, Date year only), then fields, then Artifact, graph, Citation; `.list` → Source only; inserting the second Page sets `fieldChoices["page"]`; inserting Line sets none | AC-2.1, AC-2.3, AC-2.4, D-12 |
| T-7 | Swift | `SourceTypeFormatsModelTests.swift` `diagnosticsAndCount` *(new)* | A reply with `unclosed_group` at 0..<1 for `[x` → shown while the draft is `[x`, hidden after `edit` to `[xy`; `range(in:)` on `é{` with a span 2..<3 → the `{`; a span inside `é` (1..<2) → nil; the census full note's count = its `unicodeScalars.count`; 4,001 scalars → over | AC-1.8, AC-3.1, AC-3.5, D-9, D-10, D-16 |
| T-8 | Swift | `SourceTypeFormatsModelTests.swift` `preview` *(new)* (debounce zero) | Load picks the Source with the highest revision of this type; an edit to `.full` sends one call for `.full` with the draft text and the pick, none for the others; `pick(sourceID:)` sends three; a stale generation's reply is dropped; no Sources → calls with `sourceID` nil; `sources.not_found` → re-default; locked → `format` nil; an error → `previewError`, cleared on success | AC-4.1, AC-4.2, AC-4.3, AC-4.5, AC-4.7, AC-3.6, AC-5.1, D-8, D-14, D-17 |
| T-9 | Swift | `SourceTypePageModelTests.swift` `saveWritesFormatsThenDetails` *(new)* | Formats dirty only → one formats write, no `updateSourceType`, toast "Citation formats saved", `.changedCitationFormats` applied; both dirty → formats then details, the "both" toast; a formats reply with diagnostics → no details write, `saveError` set, edits kept; formats saved then details throw → formats saved (Revert keeps them), `saveError` from details; `isDirty` true with only a format edit (leave guard holds); `revertEdit()` restores formats | AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, AC-1.7, D-6 |
| T-10 | Swift | `macos/ProvenenciaTests/CitationFormatsCopyTests.swift` *(new)* | Every `CitationDiagnosticCode` case and nil → a non-empty message; every `CitationBuiltin` and `Level` → a non-empty name; `unknown_field` with key `nope` → contains "nope" | D-15 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `TestRenderPreview`, `TestRenderCitationPreview` (cases rewritten here), `SourceTypePageModelTests` (Save moved), `SourceTypeCopyModelTests` (read's return type), `TestSwiftVocabularyMatchesGo`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left ("takes the list form only"); `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (done at planning)
- [ ] UI matches the brief inventory and the agreed board; no new kit primitive (`PVTextArea` gains a handle)
- [ ] Version bump 0.29.0 → 0.30.0 (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated
- [ ] Domain doc updated: docs/citation-formats.md § Rendering "The preview" (D-2, D-3) and § Storage's one sentence
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

On a new project (the seed's 26 types), with two census Sources ("1880 census, Calder County" with jurisdiction, a household graph and one Citation on p. 14; "1870 census, Calder County" with no jurisdiction and no Citation):

1. Source types → Census. The three formats show by key with counts; the preview picks the 1880 Source and shows the full note with *the provider in italics* and "p. 14" (AC-1.1, AC-4.1).
2. In the full note, put the cursor before the final period; Insert field → type "line" → Line (Evidence graph). `{graph.meta.line_number}` appears at the cursor; a moment later the preview's full note changes (the group drops when the graph has no line). Save changes: toast "Citation formats saved"; reopen: the text stays (AC-2.2, AC-4.2, AC-1.3).
3. Delete a `]` in the short note: the warning shows with the quoted text; click it: the text is selected. Save: refused with the Callout; restore the `]` (AC-3.2, AC-1.5).
4. Pick the 1870 Source: "Missing on this Source: Jurisdiction" under the full note; full and short render from the Source alone (AC-4.3, AC-4.4, AC-4.5).
5. Type `{citation.page}` into the source list: its warning, and the source list row shows no render while the full row still does; the Insert field there offers Source rows only. Revert (AC-3.3, AC-4.6, AC-2.3).
6. Edit the short note, press Back: the discard confirm. Keep editing; Revert (AC-1.7).
7. Open a Source page of the type, go back and save a format change, return to the Source page: it reloads (requirements re-read) (AC-6.1).
8. Change Label and the short note together, Save: the "both" toast (AC-1.4).
9. In Metadata, add a field with the key `page`; in the full note write `{source.meta.page}`: the shared-key warning with its Select; choose one and save (AC-3.4).
10. At a 2,560pt window: the same centred pair; the cursor and pick survive the resize.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| `insertText` does not reach the SwiftUI binding | T-5 checks the text view; the manual check step 2 checks the binding; Stop condition |
| Preview calls pile up while typing | D-8: one task per form, cancelled on each edit; generation drops stale replies |
| A half save (formats saved, Details refused) surprises the researcher | D-6 orders the likelier refusal first and says what saved; the user chose one Save (2026-11-20) |
| The board moves Insert field or the warning look | The plan's view rows follow the board; Decisions D-11 – D-13 are about behavior, not placement |

**Stop and report if:**

- `RenderPreview` or `loadSource` no longer does what § 4 says.
- After `PVTextAreaCursor.insert`, the `PVTextArea` binding does not hold the inserted text (the SwiftUI delegate does not hear `insertText`).
- The agreed board draws a behavior a Decision rules out (an inline underline, a Citation picker, separate Saves, the formats outside the main column).
- `checkChoices` refuses a choice D-13 sends (an `ErrInvalid` from a preview with a choice whose field exists and whose key matches).
- The census full note does not load without diagnostics.

## 12. Open questions

None for the code. The plan stays `Blocked — on board S15-D16` until the board is agreed and the view rows and Strings take its decisions.

## 13. PR

**Title:** S15-17 — The format editor
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-17-format-editor.md`.
