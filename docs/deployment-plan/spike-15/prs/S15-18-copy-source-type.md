# S15-18 — A Source type can be copied

**Status:** Landed in [#877](https://github.com/mendahu/provenencia/pull/877) (2026-11-17)
**Spike / slice:** Spike 15 · Slice 4 — Formats as data
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D7](../design/archive/S15-D7-copy-source-type.md), board agreed 2026-11-17
**Board:** [Claude Design — Source Type Page](https://claude.ai/artifact/42ZuWus4ynyz7xUDwcF6zG), artboard *S15-D27 · S15-D6 · S15-D7 · Source type page board*, the frames named "S15-D7" in its menu (D7-1a, D7-1b, D7-2a, D7-2b, D7-3 – D7-6, D7-7, D7-7b, D7-8 – D7-10) and its decision notes (CT-1 the button, CT-4 ticks, CT-9 leaving, CT-5, CT-3 · CT-8, CT-10, Handoff), drawn by *Source type page · component* (`Source-Type-Page.dc.html`). Board decisions: the kit's `copy` glyph (the app's `.duplicate`), shown disabled while the page loads; Escape or a click outside closes at once when nothing changed; frame 7 split into 7 (duplicate key) and 7b (save failed). The board writes its own duplicate-key sentence; the app keeps the engine's message, as Add type does (D-8)
**Depends on:** S15-06 (landed [#782](https://github.com/mendahu/provenencia/pull/782)), S15-12 (landed [#856](https://github.com/mendahu/provenencia/pull/856)), S15-15 (landed [#871](https://github.com/mendahu/provenencia/pull/871)), S15-48 (landed [#848](https://github.com/mendahu/provenencia/pull/848)), S15-D7
**Blocks:** —
**Branch:** `s15-18-copy-source-type`
**Version bump:** minor, 0.19.0 → **0.20.0** (if `main`'s `VERSION` is no longer 0.19.0 when you rebase, the next minor after it): a new RPC and a new action on the type page ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`use-catalog-session`](../../../../.agents/skills/use-catalog-session/SKILL.md), [`add-seeded-vocabulary`](../../../../.agents/skills/add-seeded-vocabulary/SKILL.md) (the suggestion join's owner), [`add-catalog-query`](../../../../.agents/skills/add-catalog-query/SKILL.md), [`add-audit-scope`](../../../../.agents/skills/add-audit-scope/SKILL.md), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`, `.cursor/rules/swift-tests.mdc`, `.cursor/rules/macos-client.mdc`, `.cursor/rules/versioning.mdc`
**Context:** [map § 6.3 "The editor"](../evidence-explained-citation-map.md), working rules: "A Source type has its own page" (Copy in the page header, user 2026-11-17), "Suggestions have a level", "Formats name fields by id", "No engineering for two windows editing the same data"; [`source-layer-data-model.md`](../../../source-layer-data-model.md) § 3 `source_types` and § 4.2 Copy Source; [`S15-15` plan](S15-15-type-stores-citation-formats.md) **Next adds** ("S15-18 copies `StoredFormatsTx` output as stored")
**Planned:** 2026-11-17 against `main` @ `09f7398`
**Review:** [`S15-18-copy-source-type.review.md`](S15-18-copy-source-type.review.md) — Fits with changes — Ready with changes, rounds 1 – 2 (2026-11-17); no open blocker, nothing to user

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

A researcher who wants a type close to one they have (a state census beside the census, a second parish register) adds a blank type today and rebuilds its suggested fields at three levels and its three citation formats by hand. After this PR, **Copy** on a Source type's page opens a Copy type sheet modelled on Copy Source: the researcher names the new type, ticks what it starts with (icon, description, citation formats, suggested fields on the Source, on each Artifact and on each Evidence graph), and **Copy type** creates it in one engine write and opens its page. The request is map § 6.3 "The editor" and dogfood bar 5; the user moved it from the Add type dialog to the page, as Copy Source sits on the Source page (2026-11-17).

**Why now.** S15-15 stores formats, S15-12 shows suggestions at three levels, S15-48 gives the type its page. Bar 5 needs Copy before slice 4 closes.

**What stays.** The Add type dialog (it gets no Copy from). Details, the suggestion lists, Delete and the locked note on the page. `CreateSourceType`'s request and reply.

## 2. User stories

**US-1.** As a researcher on a Source type's page, when I press Copy, name the new type and press Copy type, I land on the new type's page with the parts I ticked, so that I start from a type I already shaped.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Census (yours): census-sheet mark, a description, all three formats, 4 Source, 3 Artifact, 5 graph suggestions. Copy, label "State census", every tick on, Copy type | A user type `state-census` exists with the census-sheet mark, Census's description, `GetCitationFormats` texts equal to Census's, and the same suggestions in the same order at each level; its page opens; its list row reads 12 fields |
| AC-1.2 | As AC-1.1 with the Artifact tick off | No Artifact suggestions; Source and graph suggestions copied; row reads 9 fields |
| AC-1.3 | As AC-1.1 with Icon, Description and Citation formats off | Default mark, no description, `GetCitationFormats` returns three empty forms |
| AC-1.4 | Letter (Provenencia's): no description, no formats, 2 Source suggestions | Description, Citation formats, Artifact and Evidence graph ticks are unticked, disabled, hint "None on this type"; Icon and Source ticked; Copy type copies the mark and the 2 Source suggestions |
| AC-1.5 | A locked plugin type's page | Copy is enabled; the copy is origin `user` and editable |
| AC-1.6 | After the copy, remove a suggestion from the copy | The original's list is unchanged |

**US-2.** As a researcher, when the copy cannot be made, I see why and keep what I typed.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Label "Census" while a user type `census` exists | Duplicate-key message under Label, announced; sheet stays open |
| AC-2.2 | Label blank, or "..." | Copy type disabled; "A label is required…" / "That label cannot be turned into a key…" under Label after typing |
| AC-2.3 | The original was deleted in another window before Copy type | Danger Callout "The type was not copied" with "Invalid source type."; every field and tick kept |
| AC-2.4 | The formats read fails when the sheet opens | Ticks area shows the compact Callout with Read again; Copy type disabled; Read again succeeds → ticks show |
| AC-2.5 | Label typed or a tick changed, then a click outside | The kit's discard confirm asks |

**US-3.** As the engine, a copy is one audited write.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `CopySourceType` with every part | One revision, action `copy_source_type`, one `source_type` create change whose fields include `citation_full`, `citation_short`, `citation_list` for each non-empty form |
| AC-3.2 | Levels `["citation"]`, or `["graph","graph"]` | `sourcevocab.invalid`, nothing written |
| AC-3.3 | An unknown `type_id` | `sourcetypes.invalid`, nothing written |

## 3. Scope

| In | Covered by |
| --- | --- |
| `CopySourceType` RPC and `sourcevocab.CopyType` (one write, ticked parts) | STEP-1 – STEP-3, AC-1.1 – AC-1.6, US-3 |
| `sourcetypes.Create` stores stored-form formats and audits them | STEP-1, AC-3.1 |
| Swift store: `copySourceType`, `citationFormats` | STEP-4 |
| Copy in the page header on every type (CT-1) | STEP-8, AC-1.5 |
| Copy type sheet: Label, Key, ticks, read state, errors, discard (CT-2 – CT-6, CT-8 – CT-10) | STEP-7, US-2 |
| After Copy type, open the new type's page with no toast (CT-7) | STEP-7, AC-1.1 |
| Wide: the sheet and the page are the same at both widths (CT-W1) | STEP-7, manual check 5 |
| Label and Key fields and the label rule shared by Add, the page and Copy | STEP-6 |
| The read area and the part tick promoted to kit components | STEP-5 |
| `CitationForm` and the form names | STEP-4 |

| Out | Home |
| --- | --- |
| Copy from in the Add type dialog | not planned (user, 2026-11-17) |
| Editing formats on the page; caching the formats read | S15-17 |
| Copying Sources of the type or metadata values | not planned (map scope entry) |
| A choice of which suggestions within a level to copy | not planned |
| Copying several types at once | not planned |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Type create | `core/database/sourcetypes/sourcetypes.go` `Create(tx, label, description, iconKey)` | Mints the key, refuses a user duplicate (`ErrDuplicateKey` with the key), inserts with `sqlUpsert` (no citation columns), returns `getByIDTx` and one create change. No way to start with formats |
| Type read in a tx | same file, `getByIDTx` (unexported), `sqlGetByID` | Reads id, key, origin, label, description, icon. `sourcevocab` cannot call it |
| Suggested count | same file, `sqlSuggestedFields`, `SuggestedFields(c, typeID)` | Counts join rows at all levels |
| Formats | `core/database/sourcetypes/formats.go` `Formats`, `StoredFormatsTx`, `formColumns`, `Formats.text` | Batched stored read (fields by id); `Delete` records each non-empty column in its change |
| Suggestion join | `core/database/sourcevocab/sourcevocab.go` `sqlAppendSuggestion`, `ListSuggestions`, `EnsureSuggestion` | Owner of `source_type_metadata_fields`; not audited (`core/database/effects/registry.go` `"source_type_metadata_fields": {None: true}`); imports `sourcetypes` (so `sourcetypes` cannot copy suggestions) |
| Create RPC | `api/ffi/handlers/source_defs.go` `CreateSourceType`; `api/proto/engine.proto` `CreateSourceTypeRequest` | `writes.Run` with `Op{Action: "create_source_type"}` |
| Update RPC | same file `UpdateSourceType` | After `writes.Run` fills `UsedBy` and `SuggestedFields` (the precedent for the copy's reply) |
| Formats RPC | same file `GetCitationFormats`; `api/ffi/dispatch.go` `MethodGetCitationFormats` (120) | Exists in Go; Swift has no store method or `CoreMethod` constant for it |
| Method enum | `api/proto/engine.proto` `Method` | Last is `METHOD_UPDATE_CITATION_FORMATS = 121` |
| Copy Source engine | `core/database/sourcecopy/sourcecopy.go` `Copy`, `CopyInput`; `api/ffi/handlers/sources.go` `CopySource` | A composing package called inside the handler's `writes.Run`; never calls `writes.Run` |
| Swift store | `macos/App/Platform/GenealogyStore.swift` `createSourceType`, `copySource`; `GoStore.swift` `createSourceType`; `FakeStore.swift` `createSourceType`, `suggestionsByLevel`, `suggestedFieldCounts`, `createSourceTypeError`; `CoreInvoke.swift` `CoreMethod.createSourceType` | No copy or formats read |
| Copy Source UI | `macos/App/Features/Sources/SourceCopyDialog.swift` `sourceCopyDialog(_:)`, private `SourceCopyForm.partTick`; `SourceCopyModel.swift` `SourceCopyChoices`, `SourceCopyModel`; `SourcePageIdentityHeader.swift` `copySourceButton`; `SourcePageModel.swift` `copying`, `openCopy()`; `SourcePageView.swift` `.sourceCopyDialog($model.copying)` | The shape to mirror |
| Read area | `macos/App/Features/Sources/SourceFormLoadArea.swift` `SourceFormLoadArea`, `SourceFormLoadState` | Skeleton, compact danger Callout with Read again, ready |
| Add type | `macos/App/Features/SourceTypes/SourceTypeAddDialog.swift` private `SourceTypeAddForm` (Label and Key `PVField`s); `SourceTypeAddModel.swift` `editLabel`, `labelError`, `labelErrorFromWrite`, duplicate-key mapping | Label and Key drawn inline in the private form |
| Draft | `macos/App/Features/SourceTypes/SourceTypeDraft.swift` `SourceTypeDraft` (`key`, `labelError`) | One label rule |
| Type page | `SourceTypePageHeader.swift` (top row: eyebrow, trash); `SourceTypePageModel.swift` `type`, `isGone`, `suggestionsHandle(at:)`; `SourceTypePageView.swift` (leave guard, delete impact, icon sheet) | No Copy |
| Level copy | `macos/App/Platform/L10n.swift` `L10n.SourceTypes.level(_:)`; `macos/App/Platform/Level.swift` `Level.metadataLevels` | Titles "On the Source", "On each Artifact", "On each Evidence graph" |
| Mark name | `macos/App/DesignSystem/Recipes/Marks/PVMark.swift` `PVMarkKey.typePickerTitle`, `PVMarkKey(catalogKey:)` | The mark's name |
| Tests | `core/database/sourcetypes/sourcetypes_test.go` `TestCreateUpdateGetByID`; `core/database/sourcevocab/sourcevocab_test.go`; `api/ffi/handlers/source_defs_test.go` `TestCreateSourceTypeMintsKeyFromLabel`, `TestCitationFormats`; `macos/ProvenenciaTests/SourceCopyModelTests.swift`, `SourceTypePageModelTests.swift`, `SourceTypesModelTests.swift` | Cover create, formats, Copy Source, the page |

**Precedent.** Copy Source (Spike 12; S15-32 [#778](https://github.com/mendahu/provenencia/pull/778) added its date tick): copy its RPC shape (a `Copy…Request` with one bool per part), its composing core function inside the handler's `writes.Run`, its model (`choices` vs `prefill` for `isDirty`, availability per part, "None on this …"), its dialog modifier and its header button. Do not copy its workspace read (a type has no workspace) or its Artifact checklist.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | **A new RPC** `CopySourceType` (`METHOD_COPY_SOURCE_TYPE = 122`): request `project_dir`, `user_id`, `type_id` (the original), `label`, `copy_icon`, `copy_description`, `copy_formats`, `repeated string levels`; response `SourceType type`, `WriteEffects effects` | Copy Source has its own RPC beside create; a create request stays free of copy flags | Extending `CreateSourceTypeRequest` — every Add would carry six unused fields |
| D-2 | **`sourcevocab.CopyType(tx *database.Tx, in CopyTypeInput) (sourcetypes.Type, []rowchange.Change, error)`** *(new)* in `core/database/sourcevocab/copy.go` *(new)*; `CopyTypeInput{TypeID []byte; Label string; Icon, Description, Formats bool; Levels []vocabkey.Level}`. It never calls `writes.Run` | `sourcevocab` owns the suggestion join and already imports `sourcetypes`; `sourcetypes` cannot import it (cycle). Same role as `sourcecopy` | A new `sourcetypecopy` package — about 80 lines that `sourcevocab` already composes; logic in the handler — not table-testable in core |
| D-3 | **`sourcetypes.Create(tx *database.Tx, in CreateInput) (Type, []rowchange.Change, error)`** with `CreateInput{Label, Description, IconKey string; Formats Formats}` *(new)*; `Formats` is stored form (fields by id, as `StoredFormatsTx` returns). It inserts with `sqlInsert` *(new)*: `INSERT INTO source_types (id, key, origin, label, description, icon_key, citation_full, citation_short, citation_list) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`, empty text as NULL (`database.NullString`), and merges `formatFieldDiffs(Formats{}, in.Formats)` into the create change. `formatFieldDiffs(before, after Formats) map[string]rowchange.FieldDiff` *(new, unexported, `formats.go`)* returns one diff per `formColumns` column whose text differs, `database.NullString` on both sides; `Delete` calls it with `(stored, Formats{})` and `UpdateFormats` with `(before, next)`, replacing their two loops. Every caller of `Create` moves to the struct, leaving `Formats` out: `CreateSourceType` handler (`api/ffi/handlers/source_defs.go`), `core/database/sourcetypes/sourcetypes_test.go` `TestCreateUpdateGetByID`, `core/database/sourcemetadata/sourcemetadata_test.go`, `core/search/search_test.go` | One row, one change; how a format column is audited is decided once (review M-6). An input struct takes the next create-time property without a signature change (`sources.CreateInput` precedent; M-9). Copied as stored: the original's ids already name fields (a format field's delete is refused, S15-15), so no `ToStored` pass | `UpdateFormats` after `Create` — two changes for one new row and a key round trip; a fifth positional parameter three of four callers pass empty |
| D-4 | **`sourcetypes.GetByIDTx(tx *sql.Tx, id []byte) (Type, error)`** *(new, exported)*: `ErrInvalid` when `len(id) != 16`, else `getByIDTx` | `CopyType` reads the original's icon and description in the write's tx | Reading outside the tx |
| D-5 | **CopyType rules.** Every level must satisfy `HoldsMetadata()` and appear once, else `sourcevocab.ErrInvalid`, checked before any write. A missing original is `sourcetypes.ErrInvalid` (via `errors.Is(err, sql.ErrNoRows)`). Icon off → `""` (Create's default mark); Description off → `""`; Formats off → `Formats{}`; on → `StoredFormatsTx` of the original. Then `sourcetypes.Create`. Then, when `Levels` is non-empty, one `sqlCopySuggestions` *(new)*: `INSERT INTO source_type_metadata_fields (source_type_id, field_id, level, sort_order) SELECT ?, field_id, level, sort_order FROM source_type_metadata_fields WHERE source_type_id = ? AND level IN (` + `database.SQLInPlaceholders(len(levels))` + `)` (`core/database/sqlin.go`, the package's one bind-list helper), args the new id, the original id, then each level's string. No change is recorded for join rows. STEP-2 updates the `sourcevocab` package doc: it also holds the type copy, run inside the caller's `writes.Run` and never calling it | The join is not audited (`AppendSuggestion` precedent; effects registry `None`). One statement keeps order | Per-row `EnsureSuggestion` — opens the catalog's DB, not the tx; a hand-joined `?` list — a fourth copy of `SQLInPlaceholders` |
| D-6 | **Handler** `CopySourceType` in `api/ffi/handlers/source_defs.go`: `parseUserID(req.GetUserId())`, `parseID(req.GetTypeId())`, levels as `vocabkey.Level(s)`; `writes.Run(c, writes.Op{Action: "copy_source_type", UserID: userID}, …)` as `CopySource` does, so the revision carries who copied; after Run fills `got.SuggestedFields` with `sourcetypes.SuggestedFields(c, got.ID)` (as `UpdateSourceType`); `UsedBy` stays 0 | Copy Source's handler is the sibling; the reply's count keeps the list row right through `.createdSourceType` | `Op` without `UserID`, as `CreateSourceType` (an older handler) |
| D-7 | **Swift store** *(new)*: `copySourceType(projectDir:userID:typeID:label:copyIcon:copyDescription:copyFormats:levels: [Level]) async throws -> (CatalogSourceType, CatalogWriteEffects)` (GoStore sends `levels.map(\.rawValue)`) and `citationFormats(projectDir:typeID:) async throws -> CatalogCitationFormats`, with `CatalogCitationFormats` *(new)* `{ typeID, full, short, list: String; func text(_ form: CitationForm) -> String }` in `macos/App/Platform/GenealogyStore.swift` beside `CatalogSourceType`; `CitationForm` *(new)*, `macos/App/Platform/CitationForm.swift`, `enum CitationForm: String, CaseIterable` with one `case full` / `case short` / `case list` per line (the parity test's `rawCase` regex reads one case per line, as in `Level.swift`), mirroring `citationformat.Forms()`; `api/ffi/swift_vocabulary_test.go` gains `swiftCitationForm = "../../macos/App/Platform/CitationForm.swift"` and a `TestSwiftVocabularyMatchesGo` row `{name: "citation forms", path: swiftCitationForm, enum: "CitationForm", re: rawCase, want: sorted(strs(citationformat.Forms())...)}`, as the `levels` row; `CoreMethod.copySourceType`, `CoreMethod.getCitationFormats`. `FakeStore` scripts, never computes (`.cursor/rules/swift-tests.mdc`): `copySourceTypeResult: (CatalogSourceType, CatalogWriteEffects)?` (the reply), `copySourceTypeError`, `copySourceTypeCalls` (the arguments), `citationFormatsByType: [String: CatalogCitationFormats]`, `citationFormatsError` | The sheet needs to know which forms exist (CT-4); S15-17 reuses the read, the struct and `CitationForm` (map S15-17 "Cache signal"; review M-7). Which rows a copy makes is tested in Go only (review M-2) | A `has_formats` column on the list; a fake that copies `suggestionsByLevel` — a second copy of the engine's rule |
| D-8 | **`SourceTypeCopyModel`** *(new)*, `macos/App/Features/SourceTypes/SourceTypeCopyModel.swift`, `@MainActor @Observable final class`, `init(original: CatalogSourceType, session:userID:store:)`. `SourceTypeCopyChoices` *(new)* `Equatable { draft = SourceTypeDraft(label: "", description: ""); includeIcon = true; includeDescription = true; includeFormats = true; includedLevels: Set<Level> = Set(Level.metadataLevels) }`; `prefill`; `var labelCheck = SourceTypeLabelCheck()` (D-11); `copyError`, `isSaving`. Reads: three level handles from `CatalogQueryKey.typeSuggestionsKeys(project:typeId:)` for the original, each `session.query(...)` in init; the formats read as `private(set) var formatsState: PVFormLoadState = .loading` plus `formats: CatalogCitationFormats?`, set by `loadFormats() async` (the form's `.task`; success → `.ready` and the value, failure → `.failed(L10n.Errors.message(for:))`). `loadState: PVFormLoadState`: the first `.failed` in the order formats, source, artifact, graph (its message); else `.loading` while any is loading; else `.ready`. `reload()` rereads each failed level (`session.reread`) and, when the formats read failed, sets `formatsState = .loading` and starts `Task { await loadFormats() }`. Availability: icon always; description non-empty after trim; formats when any `CitationForm` has text; a level when its list is non-empty. `levelsToCopy` = ticked ∩ available, in `Level.metadataLevels` order. `canCopy` = ready ∧ !isSaving ∧ `draft.labelError == nil`. `isDirty` = `choices != prefill`; `prefill` is the initial `choices` (`let prefill: SourceTypeCopyChoices`, set in init as `SourceCopyModel` does). `loadFormats()` returns at once when `formatsState == .ready`. `copy() async -> CatalogSourceType?` follows `SourceCopyModel.copy()`: `guard !isSaving, loadState == .ready` else nil; `labelCheck.validate(draft)` or nil; `isSaving = true` with `defer`; `copyError = nil`; `projectDir` is `session.projectKey.projectDir`; sends ticked ∧ available parts; on success `session.apply(effects, .createdSourceType(created))`; on error `labelCheck.refuse(error)` or else `copyError = L10n.Errors.message(for:)` | Copy Source's model shape; one state per read (review M-8) | Reusing `SourceTypeAddModel` with a mode — two dialogs' state in one class; a `formats` and `formatsError` pair |
| D-9 | **Host.** `SourceTypePageModel` gains `var copying: SourceTypeCopyModel?`, `func openCopy()` (does nothing while `type` is nil or `isGone`; otherwise a fresh model from `type`) and `var canOpenCopy: Bool` (`type != nil && !isGone`). `SourceTypePageHeader` draws `PVIconButton(.duplicate, label: L10n.SourceTypes.copyEntry, size: .sm)` (spoken label the same as the tooltip, board CT-1) `.disabled(!model.canOpenCopy)`, id `sourceTypes.page.copy`, on every origin. In both `loaded(_:)` and `loading`, the top row stays `HStack(alignment: .top, spacing: PVSpacing.space5)` with the eyebrow first; its trailing item becomes a nested `HStack(alignment: .top, spacing: PVSpacing.space4)` holding Copy then the trash (in `loading`, Copy disabled then the trash's `PVSkeletonBar(width: 28, height: 28)`), as `SourcePageIdentityHeader` groups Copy and Delete (board: "shown disabled while the page loads"). `SourceTypePageView` adds `.sourceTypeCopyDialog($model.copying)` | Copy Source's host shape (`SourcePageModel.copying`) | A `@State` bool in the view |
| D-10 | **Dialog** `SourceTypeCopyDialog.swift` *(new)*: `View.sourceTypeCopyDialog(_:)` over `pvFormDialog(item:)`, width 520, copy from § 6 Strings, `accessibilityIdentifierPrefix: "sourceTypes.copy"`; `onConfirm` calls `copy()`, then `navigation.go(to: .sourceTypePage(typeId: created.id, title: created.label))` (the existing case S15-47 uses), no toast. The form: save-error `PVCallout` (danger, title `copyErrorTitle`), `SourceTypeLabelKeyFields`, `PVDivider`, the micro-caps heading, `PVFormLoadArea` holding six `PVCopyPartTick`s | CT-2 – CT-6, CT-8 – CT-10; Copy Source's form | Two columns with the icon grid (brief non-goal) |
| D-11 | **One label rule, one Label + Key view.** `SourceTypeLabelCheck` *(new)*, a struct in `SourceTypeDraft.swift`: `private(set) var error: String?`, `private(set) var announces = false`; `mutating func edit(_ new: String, in draft: inout SourceTypeDraft)` (no-op when unchanged; sets the label, `error = draft.labelError`, `announces = false`); `mutating func validate(_ draft: SourceTypeDraft) -> Bool` (`error = draft.labelError`, `announces = false`, returns `error == nil`); `mutating func refuse(_ error: Error) -> Bool` (on `.sourceTypeDuplicateKey`: `self.error = L10n.Errors.message(for:)`, `announces = true`, true; else false); `mutating func clear()`. `SourceTypeAddModel` and `SourceTypePageModel` replace `labelError`, `labelErrorFromWrite` and their `editLabel` bodies with it (`editLabel` stays as a one-line call; the page's guards on its optional draft); `SourceTypeAddDialog.swift` and `SourceTypePageView.swift` read `labelCheck.error` / `.announces`. `SourceTypeLabelKeyFields` *(new)*, `SourceTypeLabelKeyFields.swift`: the Label `PVField` (required, error, `announcesError`, `PVInput` with `activateOnAppear`, placeholder) and the read-only mono Key `PVField`, taking `label: Binding<String>`, `check: SourceTypeLabelCheck`, `key: String`, `placeholder: LocalizedStringResource`, `focus: PVFieldFocus?`, `accessibilityIdentifierPrefix: String` (ids `<prefix>.label`, `<prefix>.key`); `SourceTypeAddForm` uses it with today's ids (`sourceTypes.add.label`, `.key`) | The label rule exists twice today (review M-1); a third copy is pulled out by the PR that adds it | A third `editLabel` |
| D-12 | **Ticks and hints.** `PVCopyPartTick` *(new component, D-14)*. Icon hint: `PVMarkKey(catalogKey: original.iconKey).typePickerTitle`. Description: "The original's description, as written". Formats: `CitationForm.allCases.filter { !formats.text($0).isEmpty }.map { L10n.CitationForms.name($0) }` joined by `ListFormatter.localizedString(byJoining:)` ("Full note, Short note and Source-list entry"). Levels: `L10n.SourceTypes.assignedCount(count:)` (the page's list count, review M-5). Labels: "Icon", "Description", "Citation formats", and `L10n.SourceTypes.level(level).copyTick` *(new field on `LevelCopy`)* (review M-4). Absent: "None on this type" | S15-D7 § 2.1; one switch per vocabulary | New `copyLevel` and `copyFieldCount` keys |
| D-14 | **Promote before the second feature (`add-ui-component`).** Both are content-agnostic (no catalog type, no product noun), so they go to `Components/`, not `Recipes/` (`docs/design-system-layers.md` § 1). `SourceFormLoadArea` and `SourceFormLoadState` move to `macos/App/DesignSystem/Components/FormLoadArea/PVFormLoadArea.swift` *(new)* as `PVFormLoadArea` and `PVFormLoadState`, unchanged in behavior; its Read again string moves from `L10n.Sources.formReadAgain` to `L10n.DesignSystem.formReadAgain` (key `designSystem.formLoad.readAgain`); its three callers (`SourceCopyDialog.swift`, `ArtifactSheet.swift`, `SourceGraphFormDialog.swift`) and every `SourceFormLoadState` use (`SourceCopyModel`, `ArtifactSheetModel`, `SourceGraphFormModel`, `UnlinkLocks` and their tests) are renamed; each caller's strings and accessibility ids stay as they are. `SourceCopyForm.partTick`/`partBinding` become `macos/App/DesignSystem/Components/CopyPartTick/PVCopyPartTick.swift` *(new)*: `PVCopyPartTick(label: String, hint: String, absentHint: String, isChecked: Binding<Bool>, isAvailable: Bool, isDisabled: Bool)` — an unavailable part reads unticked and disabled with `absentHint`; Copy Source and Copy type both use it | `.agents/skills/add-ui-component/SKILL.md` "If a second feature needs it, promote to `Recipes/<Name>/` before copying"; S15-32 review M-1 made `partTick` so the rule lives once (review M-3) | Reaching into `Features/Sources`; a second `partTick` |
| D-13 | **Unsaved Details.** The sheet copies saved values (the original's `CatalogSourceType` and server reads), never the page's draft. After Copy type, `navigation.go(to:)` runs through the page's existing leave guard, which asks when Details are dirty | Brief § 2 "Saved values only"; no new safety rule | Copying the draft — a write of values the researcher has not saved |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `CopySourceType` RPC, `CopySourceTypeRequest`/`Response`, `METHOD_COPY_SOURCE_TYPE` *(new)* | FFI | `CreateSourceType`, `CopySource` | D-1 |
| `sourcevocab.CopyType`, `CopyTypeInput`, `sqlCopySuggestions` *(new)* | func / SQL | `sourcecopy.Copy`; `sqlAppendSuggestion` | D-2, D-5; searched `INSERT INTO source_type_metadata_fields` — only `sourcevocab` writes it |
| `sourcetypes.GetByIDTx` *(new)*, `sqlInsert` *(new)* | func / SQL | `getByIDTx`, `sqlUpsert` | D-3, D-4: `sqlUpsert` has no citation columns and an `ON CONFLICT` only `Upsert` needs |
| `copySourceType`, `citationFormats` store methods; `CatalogCitationFormats` *(new)* | Swift API | `copySource`, `createSourceType` | D-7 |
| `SourceTypeCopyModel`, `SourceTypeCopyChoices` *(new)* | type | `SourceCopyModel`, `SourceCopyChoices` | Different parts and reads; same shape |
| `SourceTypeCopyDialog.swift` *(new)* | view | `SourceCopyDialog.swift` | Same shape |
| `SourceTypeLabelKeyFields` *(new)* | view | `SourceTypeAddForm`'s two fields | Extracted from it (D-11) |
| `SourceTypeLabelCheck` *(new)* | type | `SourceTypeAddModel.editLabel`, `SourceTypePageModel.editLabel` | Replaces both (D-11) |
| `PVFormLoadArea`, `PVFormLoadState` *(moved)* | component | `Features/Sources/SourceFormLoadArea.swift` | Promoted (D-14) |
| `PVCopyPartTick` *(new)* | component | `SourceCopyForm.partTick` | Promoted (D-14) |
| `CitationForm` *(new)*, `L10n.CitationForms` *(new)* | enum / keys | `Platform/Level.swift`, `L10n.SourceTypes.LevelCopy` | Mirror of `citationformat.Forms()`; S15-17 reuses (D-7, D-12) |
| `formatFieldDiffs` *(new)*, `CreateInput` *(new)* | func / type | `Delete`'s and `UpdateFormats`'s loops; `sources.CreateInput` | D-3 |
| `L10n.SourceTypes.copy*` keys *(new)*, `LevelCopy.copyTick` *(new)* | key | `L10n.Sources.copySource*`; `LevelCopy` | Different nouns; level text stays in `LevelCopy`'s one switch |
| `SourceTypeCopyModelTests.swift` *(new)* | test | `SourceCopyModelTests.swift` | One file per model |

**Builds on.** Copy Source's RPC, model and dialog; `writes.Run` composing; `SourceFormLoadArea`; `.createdSourceType` row patch (S15-47); `pvFormDialog(item:)`; the page's leave guard (S15-48).
**Deletes.** The inline Label and Key `PVField`s in `SourceTypeAddForm`; `labelError`, `labelErrorFromWrite` and the duplicate-key branch in `SourceTypeAddModel`, `labelError` in `SourceTypePageModel` (replaced by `SourceTypeLabelCheck`); `Features/Sources/SourceFormLoadArea.swift` (moved); `SourceCopyForm.partTick`, `partBinding` (promoted); `L10n.Sources.formReadAgain` (moved); the `formColumns` loops in `Delete` and `UpdateFormats` (replaced by `formatFieldDiffs`).
**Next adds.** S15-17 reuses `citationFormats`, `CitationForm` and `L10n.CitationForms`, and extends `CatalogCitationFormats` with field choices and diagnostics. S15-20's seed needs nothing from this. A fourth part (a future type property) is one more `include…` bool, request field and tick.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| Type page → new type's page by `go(to:)` | `SourceTypePageView` (`viewIdentity: typeId`, S15-48) | A new id builds a fresh `SourceTypePageModel`; dirty Details on the original ask through `workspaceLeaveGuard` (D-13) |
| A user type born with formats and suggestions | type list row (`.createdSourceType`), the page's three lists, `GetCitationFormats` | The row patch carries the count (D-6); the lists read their own keys; formats read as stored |
| A copied original deleted before Save | `CopyType` | `sourcetypes.ErrInvalid` → `copyError` (AC-2.3) |
| Copy on a plugin type | header | Enabled; the copy is `user` origin (AC-1.5) |

### Scale

At the map's Scale (26 seeded types, 63 fields; a type suggests at most every field at each level, 189 rows): one `GetByIDTx`, one `StoredFormatsTx` (one id), one insert, one `INSERT … SELECT` of up to 189 rows, one count. The sheet reads one formats row and three suggestion lists already cached by the page. The write invalidates what `.createdSourceType` patches (the types list row); nothing reloads. No budget is set.

### Edges

- **Assumptions.** `StoredFormatsTx` text names fields by id that exist (a format field's delete is refused, S15-15); copied unchanged, the copy's formats hold the same ids, so the copied field's delete is refused while either type names it (T-1 case "copied formats block the field's delete"). The join's key is `(source_type_id, field_id, level)`; the new id is fresh, so the `INSERT … SELECT` cannot conflict.
- **Neighbors.** Label "Census" copying Provenencia's `census`: allowed (the duplicate rule checks user origin only, as Create today), a second "Census" of yours (T-1 case). Label "Census" when a user `census` exists: `ErrDuplicateKey` (AC-2.1). Copying with no ticks: a blank user type, same as Add (T-1 case).
- **Removed inputs.** An original that loses a suggestion between the sheet's read and Save: the copy follows the write's tx (the hint was stale; rule "No engineering for two windows"). A level ticked but empty on the original: Swift does not send it (D-8); the engine copies zero rows if sent (T-1 case).
- **Real data.** None — no table-driven rule.
- **Untrusted size.** `levels` from the wire: at most 3 distinct metadata levels, checked before any write (AC-3.2).

### Schema

None — no catalog change; `source_types` has the citation columns since S15-15.

### Go core

| Package | Change |
| --- | --- |
| `core/database/sourcetypes` | `Create(tx *database.Tx, in CreateInput) (Type, []rowchange.Change, error)`, `CreateInput` *(new)*, `formatFieldDiffs` *(new)* (D-3); `GetByIDTx(tx *sql.Tx, id []byte) (Type, error)` *(new)* (D-4); `sqlInsert` *(new)* |
| `core/database/sourcevocab` | `copy.go` *(new)*: `CopyTypeInput` *(new)*, `CopyType` *(new)*, `sqlCopySuggestions` *(new)* (D-2, D-5) |

```go
type CopyTypeInput struct {
	TypeID      []byte
	Label       string
	Icon        bool
	Description bool
	Formats     bool
	Levels      []vocabkey.Level
}
```

Errors: `sourcevocab.invalid` → a level outside the metadata levels or repeated; `sourcetypes.invalid` → unknown original, bad icon, unslugifiable label; `sourcetypes.duplicate_key` → as Create.

### FFI

`api/proto/engine.proto`: `METHOD_COPY_SOURCE_TYPE = 122` *(new)*; `CopySourceTypeRequest` *(new)* `{ string project_dir = 1; string user_id = 2; string type_id = 3; string label = 4; bool copy_icon = 5; bool copy_description = 6; bool copy_formats = 7; repeated string levels = 8; }`; `CopySourceTypeResponse` *(new)* `{ SourceType type = 1; WriteEffects effects = 2; }`. Handler `CopySourceType` in `api/ffi/handlers/source_defs.go` (D-6); `api/ffi/dispatch.go` `MethodCopySourceType` and its case. Regenerate with `./scripts/generate-proto.sh`.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Copy button | `PVIconButton(.duplicate, size: .sm)` | `SourceTypePageHeader.swift` | Before the trash (CT-1) |
| Copy type sheet | `pvFormDialog(item:)` | `SourceTypeCopyDialog.swift` *(new)* | 520pt (CT-2) |
| Label, Key | `SourceTypeLabelKeyFields` (`PVField` + `PVInput`) | *(new)* file | D-11 |
| Divider, heading | `PVDivider`; `Text(...).pvMicroCaps()` `PVColor.textFaint` | dialog | As Copy Source |
| Ticks | `PVCopyPartTick` (over `PVCheckbox`) | `DesignSystem/Components/CopyPartTick/` *(new)* | D-12, D-14 |
| Read area | `PVFormLoadArea` | `DesignSystem/Components/FormLoadArea/` *(new)* | CT-5, D-14 |
| Errors | `PVField` error; `PVCallout(tone: .danger, title:message:)` | dialog | CT-3, CT-8 |
| Discard confirm | `pvFormDialog`'s `isDirty` | — | CT-9 |

Frames: the board's "S15-D7" frames (the **Board** line). They draw this table and § 6 Strings exactly; the one difference, the board's duplicate-key sentence, is not built (the engine's message shows).

States: reading (skeleton, Copy type disabled), read failed (Callout, Read again), saving (all disabled, button loading), a part absent (unticked, disabled, "None on this type"). Accessibility: CT-10 — Return in Label confirms when enabled (`pvFormDialog` default), Tab runs Label then the ticks.

### Strings

L10n keys *(new)*, all in `L10n.SourceTypes`, with `Localizable.xcstrings` entries:

| Key | Text |
| --- | --- |
| `copyEntry` (`sourceTypes.copy.entry`) | "Copy…" |
| `copyDialogTitle` (`sourceTypes.copy.title`) | "Copy source type" |
| `copyDialogSubtitle(_:)` (`sourceTypes.copy.subtitle`) | "Start a new type of yours from %@. Its Sources and their values are not copied." |
| `copyLabelPlaceholder` (`sourceTypes.copy.labelPlaceholder`) | "State census" |
| `copyPartsHeading` (`sourceTypes.copy.parts`) | "Copy from the original" |
| `copyIcon`, `copyDescription`, `copyFormats` | "Icon", "Description", "Citation formats" |
| `copyDescriptionHint` | "The original's description, as written" |
| `L10n.CitationForms.name(_:)` (`citationForms.full`, `.short`, `.list`) | "Full note", "Short note", "Source-list entry" |
| `LevelCopy.copyTick` (`sourceTypes.suggested.level.source.copyTick`, `.artifact.copyTick`, `.graph.copyTick`) | "Suggested fields on the Source", "Suggested fields on each Artifact", "Suggested fields on each Evidence graph" |
| `L10n.DesignSystem.formReadAgain` (`designSystem.formLoad.readAgain`, moved from `L10n.Sources.formReadAgain`) | today's text |
| `copyPartAbsent` | "None on this type" |
| `copyLoading` | "Reading the original's formats and suggested fields" |
| `copyLoadErrorTitle` | "The original's parts could not be read." |
| `copyConfirm` | "Copy type" |
| `copyErrorTitle` | "The type was not copied" |

Reused: `L10n.SourceTypes.assignedCount(count:)`, `L10n.SourceTypes.cancel`, `formLabel`, `addKey`, `keyHintAdd`, `addKeyPlaceholder`, `errorLabelRequired`, `errorUnslugifiable`, `L10n.Errors.message(for:)`. The load error message comes from `PVFormLoadArea`'s `errorMessage` parameter (the engine message). Removed: `L10n.Sources.formReadAgain` (moved). No existing copy names the old scope.

## 7. Steps

Ten steps, at the size limit: steps 5 and 6 are the promotions and the label rule the review asked for, each a no-change refactor with its own commit.

**STEP-1 — Create takes an input and stores formats**
Files: `core/database/sourcetypes/sourcetypes.go`, `formats.go`, `sourcetypes_test.go`, `api/ffi/handlers/source_defs.go`, `core/database/sourcemetadata/sourcemetadata_test.go`, `core/search/search_test.go`. Skill: `add-catalog-query`, `add-audit-scope`.
Do: D-3, D-4. Extend `TestCreateUpdateGetByID` (T-2). Before editing, `rg -n 'sourcetypes\.Create\(|\bCreate\(tx' core api` lists exactly the four callers in D-3.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcetypes/ ./core/database/sourcemetadata/ ./core/search/ ./api/ffi/handlers/` passes (`TestDelete` and the formats tests unchanged).

**STEP-2 — CopyType**
Files: `core/database/sourcevocab/copy.go` *(new)*, `copy_test.go` *(new)*, `sourcevocab.go` (package doc). Skill: `add-seeded-vocabulary`.
Do: D-2, D-5. T-1.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcevocab/` passes.

**STEP-3 — The RPC**
Files: `api/proto/engine.proto`, generated files, `api/ffi/dispatch.go`, `api/ffi/handlers/source_defs.go`, `source_defs_test.go`. Skill: `add-ffi-handler`, `use-catalog-session`.
Do: D-1, D-6; `./scripts/generate-proto.sh`. T-3.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/...` passes.

**STEP-4 — Swift store and CitationForm**
Files: `macos/App/Platform/GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift`, `CoreInvoke.swift`, `CitationForm.swift` *(new)*, `L10n.swift`, `Localizable.xcstrings`, `api/ffi/swift_vocabulary_test.go`. Skill: `add-localized-string`.
Do: D-7; `L10n.CitationForms.name(_:)`. T-6.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/ffi/ -run TestSwiftVocabularyMatchesGo` passes; `xcodebuild build` succeeds with no new warning.

**STEP-5 — Promote the read area and the part tick to the kit**
Files: `macos/App/DesignSystem/Components/FormLoadArea/PVFormLoadArea.swift` *(new, moved)*, `macos/App/DesignSystem/Components/CopyPartTick/PVCopyPartTick.swift` *(new)*, `Features/Sources/SourceFormLoadArea.swift` (deleted), `SourceCopyDialog.swift`, `SourceCopyModel.swift`, `ArtifactSheet.swift`, `ArtifactSheetModel.swift`, `SourceGraphFormDialog.swift`, `SourceGraphFormModel.swift`, `UnlinkLocks.swift`, their tests, `L10n.swift`, `Localizable.xcstrings`. Skill: `add-ui-component`, `add-localized-string`.
Do: D-14. No visible change.
Check: `rg -n 'SourceFormLoad|formReadAgain|partTick' macos docs/*.md .agents .cursor` finds only the new names; `xcodebuild test` passes (`SourceCopyModelTests` unchanged).

**STEP-6 — One label rule, one Label + Key view**
Files: `SourceTypeDraft.swift`, `SourceTypeLabelKeyFields.swift` *(new)*, `SourceTypeAddModel.swift`, `SourceTypeAddDialog.swift`, `SourceTypePageModel.swift`, `SourceTypePageView.swift`, their tests.
Do: D-11. No visible change.
Check: `rg -n 'labelErrorFromWrite' macos` finds nothing; `rg -n '"sourceTypes\.add"' macos/App/Features/SourceTypes/SourceTypeAddDialog.swift` shows the prefix passed to `SourceTypeLabelKeyFields` (which builds `sourceTypes.add.label` and `.key`); `xcodebuild test` passes (`SourceTypesModelTests`, `SourceTypePageModelTests` unchanged in what they assert).

**STEP-7 — Model and sheet**
Files: `SourceTypeCopyModel.swift` *(new)*, `SourceTypeCopyDialog.swift` *(new)*, `L10n.swift`, `Localizable.xcstrings`, `macos/ProvenenciaTests/SourceTypeCopyModelTests.swift` *(new)*. Skill: `add-localized-string`, `add-swift-test`.
Do: D-8, D-10, D-12, Strings. T-4.
Check: `xcodebuild test` runs `SourceTypeCopyModelTests` green.

**STEP-8 — Host on the page**
Files: `SourceTypePageModel.swift`, `SourceTypePageHeader.swift`, `SourceTypePageView.swift`, `macos/ProvenenciaTests/SourceTypePageModelTests.swift`.
Do: D-9, D-13. T-5.
Check: `xcodebuild test` green; in the app, Copy shows on Census and on a plugin type, disabled while the page loads.

**STEP-9 — Version**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj`.
Do: the header's bump.
Check: `scripts/check-pr.sh` prints `check-pr: PASS` (on macOS: it runs the Xcode tests).

**STEP-10 — Docs**
Files: `docs/source-layer-data-model.md` (a new `## 4.3 Copy a Source type` after § 4.2 Copy Source: action `copy_source_type`, what each part copies, join rows unaudited), `.agents/skills/add-seeded-vocabulary/SKILL.md` (the `sourcevocab` row: it also holds the type copy), `docs/deployment-plan/spike-15/completed.md`, `docs/deployment-plan/spike-15/deployment-plan.md` (map row), this plan (status, Landed note), `docs/deployment-plan/spike-15/design/S15-D7-copy-source-type.md` → `docs/deployment-plan/spike-15/design/archive/`, `docs/deployment-plan/spike-15/design/README.md`. No change to `docs/design-system-layers.md` (it names no recipe).
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-18-copy-source-type.md` reports no errors (its one warning, the Copy button's ellipsis in § 6 Strings, is expected); links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/sourcevocab/copy_test.go` `TestCopyType` *(new)*, table | every part → icon, description, stored formats equal, rows equal with sort order at each level, one create change with three `citation_*` fields; Artifact level off → no Artifact rows; Icon/Description/Formats off → default mark, empty, no `citation_*` fields; no ticks → blank user type; plugin original → user copy; Provenencia `census` with label "Census" → succeeds; user `census` exists → `ErrDuplicateKey`; unknown original → `sourcetypes.ErrInvalid`; levels `citation` or duplicated → `sourcevocab.ErrInvalid`, no row; level with no rows → succeeds, none copied; removing the copy's row leaves the original's; copied formats → `deleteimpact.Impact(tx, catalogmodel.KindMetadataField, fieldID)` has the group `deleteimpact.ViaCitationFormats` with `Total == 2` (as `metadatafields_test.go` asserts it) | AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, AC-3.2, AC-3.3, D-3, D-5 |
| T-2 | Go | `core/database/sourcetypes/sourcetypes_test.go` `TestCreateUpdateGetByID` (extended) | `CreateInput` with stored formats → `StoredFormatsTx` returns them; change fields include the non-empty forms only, `Old` nil; `GetByIDTx` with a 15-byte id → `ErrInvalid`; `TestDelete` and `UpdateFormats` tests keep their change fields (via `formatFieldDiffs`) | D-3, D-4 |
| T-3 | Go | `api/ffi/handlers/source_defs_test.go` `TestCopySourceType` *(new)*, `runRPC` | Census-like type with formats and suggestions → reply origin `user`, `suggested_field_count` equal to the copied rows, effects with a revision; `GetCitationFormats` on the copy equals the original's texts; bad `user_id` → invalid; bad `type_id` → invalid | AC-1.1, AC-3.1 |
| T-4 | Swift | `macos/ProvenenciaTests/SourceTypeCopyModelTests.swift` *(new)* | `prefillsBlankLabelAndEveryTick`; `absentPartsReadUntickedAndAreNotSent` (Letter-like: `copySourceTypeCalls` has `copyDescription == false`, `copyFormats == false`, levels `[.source]`); `copySendsTickedPartsAndPatchesTheList` (Artifact off → levels `[.source, .graph]`; the scripted `copySourceTypeResult` row, with its `suggestedFieldCount`, is in the cached types list); `duplicateKeyShowsUnderLabel` (`labelCheck.announces`); `otherFailureKeepsChoices`; `formatsReadFailureThenReadAgain` (`citationFormatsError` set → `.failed`; cleared, `reload()` then `await loadFormats()` → `.ready`); `cannotCopyWhileReading`; `dirtyAfterLabelOrTick` | AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-2.1, AC-2.2, AC-2.3, AC-2.4, AC-2.5, D-8 |
| T-5 | Swift | `macos/ProvenenciaTests/SourceTypePageModelTests.swift` `openCopyOnLoadedTypeOnly` *(new)* | type not loaded → `canOpenCopy` false, `openCopy()` leaves `copying` nil; loaded plugin type → `copying.original.id` equals it | AC-1.5, D-9 |
| T-6 | Go | `api/ffi/swift_vocabulary_test.go` `TestSwiftVocabularyMatchesGo` (a row) | `CitationForm` cases equal `citationformat.Forms()` | D-7 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `TestCreateUpdateGetByID`, `TestDelete`, `TestCitationFormats`, `TestCreateSourceTypeMintsKeyFromLabel`, `SourceCopyModelTests`, `SourcePageModelTests` (Artifact sheet's load state), `SourceTypesModelTests`, `SourceTypePageModelTests`, `api/ffi/dispatch_test.go`.

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
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated
- [ ] Domain doc updated: docs/source-layer-data-model.md § 4.3 Copy a Source type (new)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Open a project with a user type "Census" given the census-sheet mark, a description and suggestions at all three levels. On its page press Copy: the sheet shows six ticks with the mark's name and the three counts. Until S15-17 lands no screen writes formats, so Citation formats reads "None on this type" here; copying formats is covered by T-1 and T-3, and once S15-17 has landed, give Census formats first and see "Full note, Short note and Source-list entry".
2. Type "State census", untick "Suggested fields on each Artifact", press Copy type: the State census page opens with the census-sheet mark, the description, the Source and Evidence graph lists, no Artifact list entries; the Source types list shows it with the summed count. 
3. On Census, type "Census" in the sheet: the duplicate message shows under Label.
4. Open a Provenencia type with no formats (Birth certificate): Description and Citation formats read "None on this type" when absent; Copy is enabled; on a plugin type, Copy is enabled.
5. Repeat 1 with the window at Regular and stretched to Wide: the sheet and the page look the same at both widths (CT-W1).
6. Edit Details on Census without saving, copy it: after Copy type the discard confirm asks; Keep editing stays on Census.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| Changing `Create`'s signature misses a caller | STEP-1 lists all three; `go vet ./...` catches the rest |
| The promotions touch Copy Source and the Artifact sheet | STEP-5 is its own commit with no visible change; their tests must pass unchanged |
| The board draws Icon or Description as fields | Stop condition below |

**Stop and report if:**

- `sourcetypes.Create` has a caller not listed in D-3.
- `sourcevocab` no longer imports `sourcetypes`, or `sourcetypes` imports `sourcevocab`.
- `StoredFormatsTx` no longer returns text by id, or a stored format can name a field id that does not exist.
- The agreed board puts the icon grid, a description field or format text in the sheet, adds a tick list other than § 2.1's six, puts Copy anywhere but the header's top row, or needs a kit piece the inventory does not name.
- `pvFormDialog(item:)` cannot run Return-to-confirm from Label.
- `SourceFormLoadArea`'s parameters cannot take the copy's strings without changing its other callers.

## 12. Open questions

None.

## 13. PR

**Title:** S15-18 — A Source type can be copied
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-18-copy-source-type.md`.

## Landed

- The version bump is 0.20.0 → 0.21.0: `main` was already at 0.20.0 when the PR was cut.
- `OnboardingModelTests.ThrowingStore` conforms to `GenealogyStore`, so it gained `copySourceType` and `citationFormats` stubs (its own commit).
- STEP-7 and STEP-8 landed in one commit (the sheet, its model, and Copy in the page header and host).
- The kit's `DesignSystem/README.md` gained rows for `FormLoadArea` and `CopyPartTick` (the guidance check requires one per kit folder).
- The Copy button's accessibility id is `sourceTypes.page.copy`; the sheet's tick ids are `sourceTypes.copy.icon`, `.description`, `.formats`, `.source`, `.artifact` and `.graph`.
- `SourceTypeCopyModelTests` also covers `unticksSkipTheirParts`, `aBlankOrUnslugifiableLabelCannotBeCopied` and `aFailedListReadFailsTheSheetAndReloads`; `TestCopyType` and `TestCreateUpdateGetByID` hold T-1's and T-2's cases as table rows.
- The in-app manual check (§ 10) was not run in the implementing session.
