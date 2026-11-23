# S15-64 — Boards show inherited values

**Status:** Planned
**Spike / slice:** Spike 15 · Slice 11 — Metadata at any level
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D33](../design/S15-D33-inherited-values.md), board drawn 2026-11-23
**Board:** [Claude Design — Source Detail](https://claude.ai/artifact/443NPNYmGErAmxgV1fBsFK), page *Artifacts* frames `d33-sheet`, `d33-override`, `d33-overridden`, `d33-marks`, `sheet-add`; page *Evidence graphs* frame `d33-gf`; the S15-D33 spec note (the brief's **Board** line lists the rest). The implementer can open the link; D-11 and D-12 describe what it draws
**Depends on:** S15-63 (landed [#955](https://github.com/Jake-Robins-Studios/provenencia/pull/955)), S15-D33
**Blocks:** S15-56, S15-66
**Branch:** `s15-64-inherited-values`
**Version bump:** minor, 0.35.0 (today's `VERSION`) → **0.36.0** (or the next minor after `main`'s `VERSION` when you rebase): every Artifact and graph board shows what it inherits, with new wire fields ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md), [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md) (the Source workspace's refreshes)
**Rules that bind:** `.cursor/rules/go-tests.mdc`
**Context:** working rules "A board shows what its owner inherits", "A format reads a field from the nearest level that holds it", "One metadata board", "Metadata saves with its owner's write", "A value can be marked unknown or supplied", "Boards flag needed fields; the engine decides the rows"; [`source-layer-data-model.md` § 5.2](../../../source-layer-data-model.md); [`catalog-caches.md` § Swift caches](../../../catalog-caches.md#swift-caches)
**Planned:** 2026-11-23 against `main` @ `3d8863a`
**Review:** [`S15-64-inherited-values.review.md`](S15-64-inherited-values.review.md) — two rounds; no blocker open; R-1 answered by the user (2026-11-23)

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

A citation reads each field from the nearest level that holds a value (S15-62), so Provider "Ancestry" typed once on a Source serves every Artifact and Evidence graph of it. Today the Artifact sheet and the graph form show that row empty. After this PR each board entry carries the value its owner inherits, with the level it comes from, printed as a citation prints it; the board row shows it read only ("From Source"), opening it and saving a value overrides it for this owner, and clearing that value falls back. It shows on the Artifact sheet (edit and add) and the graph form (edit and add); the Source's own board has nothing above it.

**Why now.** S15-62 made formats read the nearest level and S15-63 put every suggested field on every board, so an Artifact board now lists Provider while its citation already reads the Source's. The rule "A board shows what its owner inherits" (user, 2026-11-22) closes that gap before the composer's Citation board (S15-56) reuses the same row.

**What stays.** Which entries a board holds (suggestions, the formats' heads, own values), their order, dismissals, the requirement annotation, every write RPC and the drafts the sheet and form send. The Source's own Metadata section and the Artifacts list's read-only copy details.

## 2. User stories

**US-1.** As a researcher editing an Artifact, I see the value it inherits from its Source on each row with no value of its own, so I do not type it again.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Census Source with Provider "Ancestry"; its Artifact has no Provider; open the Artifact sheet | The Provider row shows "Ancestry" read only with "From Source" (IH-1) |
| AC-1.2 | The same, Add an Artifact on that Source | The draft board's Provider row shows "Ancestry", "From Source" (IH-7) |
| AC-1.3 | Graph of that Source with no Provider; open the graph form (edit or add) | Provider shows "Ancestry", "From Source" (IH-7) |
| AC-1.4 | The Source's own Metadata section | No row shows an inherited value (IH-7) |
| AC-1.5 | Book Source with Publisher marked unknown (unknown text "n.p.") and Place of publication "Calder County" marked supplied | Its Artifact's board reads Publisher "n.p." (italic) and Place of publication "[Calder County]" (IH-5) |
| AC-1.6 | Census Source's URL "https://example.org/calder/1880" | The Artifact's URL row shows it as a link that opens it (IH-6) |
| AC-1.7 | Census Source with an extra field Column (not suggested, not read by a format) valued "4" | The Artifact board has no Column row (D-3) |

**US-2.** As a researcher, I override an inherited value for one Artifact or graph and can go back to the Source's.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | AC-1.1's sheet; Provider's pencil, type "FamilySearch", Save the row, Save the sheet | The Artifact stores Provider "FamilySearch"; its row is a saved row with "Overrides Source: Ancestry" (IH-2, IH-3); the Source keeps "Ancestry" |
| AC-2.2 | After AC-2.1, the Artifact's citation | Reads "FamilySearch" (the S15-62 resolver; no change here) |
| AC-2.3 | Reopen the sheet; trash Provider | The row shows "Ancestry", "From Source" again, the sheet is dirty; Save clears the Artifact's value; reopening shows the inherited row (IH-4) |
| AC-2.4 | A head the formats read but the type does not suggest, valued on the Artifact and on the Source; trash it in the sheet | The row stays and shows the Source's value (D-7) |
| AC-2.5 | On the Source page, change the Source's Provider to "Calder Archives", then open the Artifact sheet of an Artifact with no Provider | The row shows "Calder Archives" (D-9) |

## 3. Scope

| In | Covered by |
| --- | --- |
| Each board entry carries the nearest ancestor's row from the board's own read; no extra read (D-1, D-2, D-3) | STEP-1, STEP-2, AC-1.1 – AC-1.4, AC-1.7 |
| The engine prints the inherited value as a citation prints it (D-4) | STEP-1, AC-1.5 |
| Each entry says whether the board keeps it with no value (D-5) | STEP-2, AC-2.4 |
| The wire carries both (D-6) | STEP-3, AC-1.6 |
| A Source's metadata value write reports a keyed read the Source page follows (D-9) | STEP-4, STEP-6, AC-2.5 |
| Swift decodes the entry (D-7, D-8) and the draft host keeps a row the engine keeps (D-7) | STEP-5, AC-2.3, AC-2.4 |
| The board row draws IH-1 – IH-8, IH-W1 on the Artifact sheet and the graph form (D-10, D-11, D-12) | STEP-7, AC-1.1 – AC-2.3 |
| Copy (§ 6 Strings) | STEP-7 |
| Docs: the rule's walker name, `source-layer-data-model.md` § 5.2, `catalog-caches.md`, map, completed, brief archive | STEP-9 |

| Out | Home |
| --- | --- |
| The composer's Citation board and a Citation's ancestors (graph, Artifact, Source); an Artifact- or graph-level value reporting `inherited_values` | S15-55 (the read), S15-56 (the board and the read's Artifact and graph paths) |
| Hiding inherited rows behind a control | Not planned (rule "A board shows what its owner inherits": a later choice once the boards are in use) |
| Values below an owner (a Source's Artifacts' values on the Source's section) | Not planned (same rule) |
| Inherited values in the Artifacts list's read-only copy details or on graph cards | Not planned (the brief's § 2.2: those show own values only) |
| A row for a field only an ancestor holds (not suggested, not read, no own value) | Not planned (D-3) |
| Mapping an own value's `mark` in Swift; drawing it; the Unknown and Supplied control | S15-41 |
| Needed and used flags on the rows (Swift reading `requirement`) | S15-39 |
| The list-below hint and Move to Source | S15-66 |
| `FakeStore` computing inherited values or `inherited_values` reads by itself | Not planned (tests set them, as they set `nextWriteEffects`) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Resolver | `core/database/sourcemetadata/annotation.go` `CitationValues.Resolve` | Walks `vocabkey.NearestFirst()` over `Rows` for a field target with no level and returns `CitationValue(row, field)`. The level that answered is lost. Its doc comment: "Resolve is the one place the levels are walked" |
| Without | `annotation.go` `CitationValues.Without` | Copy with one level's rows and built-ins removed; boards use it as `above` |
| Value of a row | `annotation.go` `CitationValue(r Row, f metadatafields.Field) citationformat.Value` | Text, mark, the field's unknown text |
| Printing a value | `core/citationformat/render.go` `printed` | Unknown → unknown text (empty possible); text only space → not answered; supplied → `[text]`; a built-in date through `datevalue.CitationDisplay` |
| Board entry | `core/database/sourcemetadata/sourcemetadata.go` `WorkspaceEntry` | `Field`, `Value *Row`, `Suggested`, `Annotation`, `SortOrder`; `OpenHref()` reads `Value` only; its comment says it is "the only link the app opens from metadata" |
| Board build | `sourcemetadata.go` `listWorkspaces` | Reads the owners' and their Sources' values in one `readByOwners`; per owner builds `r` (own level + Source) and `above := r.Without(o.Level)`; passes both to `buildEntries` |
| Draft board | `sourcemetadata.go` `ListDraftWorkspace` | `r` holds the Source's rows only; passes `above: r` |
| Entries | `sourcemetadata.go` `buildEntries`, `boardInput` | Loop 1: suggestions (valued or not). Loop 2: heads in `in.needs.order` that are neither suggested nor valued. Loop 3: valued fields not yet seen (a valued unsuggested head lands here). `boardInput.above` is a `citationformat.Resolver` used only by `annotate` |
| Effects | `core/database/effects/registry.go` `Read`, `Reads`, `KeyTable`, `registry["source_metadata"]` | Keyed reads `citations` … `source_records`; `source_metadata` carries only `Search`. `metadataEffects` owns Entity, SourceScope and Lists of the metadata tables and leaves `Reads` to the entry |
| Effects tests | `core/database/effects/reads_test.go` `TestReadsDeclare`; `api/ffi/swift_vocabulary_test.go` (Swift `CatalogRead` parity) | The read → tables map; the Swift enum matches `Reads` |
| Wire | `api/proto/engine.proto` `MetadataWorkspaceEntry` (fields 1 – 11; 3, 7, 8 reserved); `MetadataOwner` (`level`, `id`) | No inherited value |
| Handler | `api/ffi/handlers/metadata.go` `metadataEntryProto` | The one mapper every board reply uses (`ListWorkspaces` boards at line 68, the draft board, `ownerBoardProto`) |
| Swift entry | `macos/App/Platform/GenealogyStore.swift` `CatalogMetadataEntry` | `field`, `valueText`, `hasValue`, `suggested`, `sortOrder`, `openHref`, `openURL`; its `openHref` comment says "The only link the app opens from metadata" |
| Swift reads | `macos/App/Features/Workspace/Session/CatalogMutation.swift` `CatalogRead` | Mirrors Go's `Read` |
| Source workspace key | `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift` `.sourceWorkspace` | `refreshes: [.applyHiddenPolicy(followsOwnId: .reads(.sourceHoldings))]`, `patches: [.updatedSourceShell(), .metadataBoard()]` |
| Swift mapping | `macos/App/Platform/GoStore.swift` `mapMetadataEntry` | Field by field; the only mapper |
| Draft host | `macos/App/Features/Sources/MetadataDraftHost.swift` `MetadataDraftHost`, `isEmptyRow` | `set` and `clear` change `valueText`, `hasValue`, `openHref` in place; `clear` keeps a row only when `isEmptyRow` (`row.suggested`, or `opened` held it with no value), else removes it |
| Board model | `macos/App/Features/Sources/MetadataBoardModel.swift` `saved`, `suggested` | Split by `hasValue` |
| Board view | `macos/App/Features/Sources/MetadataBoardView.swift` `MetadataBoardSuggestionRow`, `savedRow`, `MetadataBoardTextEditor`, `MetadataValueText`, `MetadataBoardAddRowView` | Empty row: dashed card, label, always-open `PVInput` ("Add a value…"), Save, dismiss. Saved row: handle, label, `PVInlineEdit` over `MetadataValueText` (takes a `CatalogMetadataEntry`) with trash. The add row's "taken" notice draws the caption tokens inline |
| Source board writes | `macos/App/Features/Sources/SourcePageContext.swift` `applySavedMetadata` | Every owner's write applies `.wroteMetadataBoard`, a patch of that owner's rows only. A Source write leaves the cached Artifact and graph boards (their `met_elsewhere` since S15-62) as they were |
| Sheet open | `macos/App/Features/Sources/ArtifactSheetModel.swift` (line 92), `SourceGraphFormModel.swift` (line 82) | Edit mode builds `MetadataDraftHost` from the cached rows; add mode from `readDraftBoardForAdd` |
| Level names | `macos/App/Platform/L10n.swift` `L10n.CitationFormats.levelName(_:)` | "Source", "Artifact", "Evidence graph", "Citation" |
| Tests | `annotation_test.go` `TestCitationValuesResolve`; `sourcemetadata_test.go` `TestWorkspaceEntryOpenHref`, `TestListWorkspacesAnnotations`, `TestDraftBoardScenarios`, `TestListWorkspacesAnnotationsScale` (121 boards on a `census` Source; helpers `seededWorld`, `newSource`, `seededType`, `newLevelOwner`); `api/ffi/handlers/metadata_test.go` `TestMetadataBoardRequirements`, `TestGetDraftMetadataBoard` (helpers `newMetadataOwners`, `boardEntries`); `core/citationformat/render_test.go`; `macos/ProvenenciaTests/MetadataDraftHostTests.swift` (`anEmptyHeadTheReadReturnedClearsToEmptyAndDismisses`), `SourcePageModelTests.swift` (the reads test at line 445), `CatalogQueryRegistryTests.swift` | Cover the requirement on the wire, the draft host's set and clear, the page following `source_holdings` |

**Precedent.** S15-38 ([#910](https://github.com/Jake-Robins-Studios/provenencia/pull/910)) added `requirement` to every board entry the same way: computed in `buildEntries` from the board's one read, carried by `metadataEntryProto`, a new optional proto field. Copy its shape. For D-9, `ReadSourceHoldings` is the precedent: declared on `effects.Read`, put on its tables' entries in `registry`, mirrored in `CatalogRead`, followed by `.sourceWorkspace` with `.applyHiddenPolicy(followsOwnId:)`, tested in `TestReadsDeclare` and in `SourcePageModelTests` at line 445.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `func (v CitationValues) Nearest(id uuid.UUID) (Row, bool)` *(new)* in `annotation.go`: the row of the nearest level in `vocabkey.NearestFirst()` that holds field `id` (looked up as `Rows[level][string(id[:])]`, as `Resolve` does today). `Resolve`'s no-level branch becomes `if row, ok := v.Nearest(t.Field.ID); ok { return CitationValue(row, v.Fields[string(t.Field.ID[:])]) }`. The doc comment says "Nearest is the one place the levels are walked; Resolve and the boards' inherited values read it" | The inherited value needs the level, which `Resolve`'s `citationformat.Value` does not carry; `Row.Owner.Level` does. One walker stays one walker | A second loop over `NearestFirst()` in `buildEntries` — two walkers; a level on `citationformat.Value` or `Resolver` — the format package and the renderer share them |
| D-2 | `WorkspaceEntry.Inherited *Row` *(new)*: `above.Nearest(field id)` for every entry `buildEntries` emits (all three loops; the id from `uuid.FromBytes`, a bad id leaves it nil), whether or not the entry has its own value; nil when nothing above holds the field. `boardInput.above` becomes `CitationValues` (from `citationformat.Resolver`); `annotate` still takes it as a `Resolver` | The rule: "each board entry carries, besides its own value, the value it inherits". Carried with an own value so a draft falls back on clear with no read, and IH-3 can say what an override hides. Both callers already build `above` as `CitationValues` | `Inherited` only on entries with no own value — no fall back until Save; a level field beside it — `Row.Owner` holds it |
| D-3 | Inherited values attach to the entries the board already emits. A field only an ancestor holds adds no entry; a dismissed suggestion stays hidden | Rule "Boards flag needed fields; the engine decides the rows": which fields a board lists does not change; the rule gives each *entry* its inherited value | An entry per ancestor value — every Source extra on every Artifact and graph board, a change no rule asks for |
| D-4 | One marking step in `core/citationformat/render.go`. `func marked(text string, m valuemark.Mark) string` *(new, unexported)*: "" when `text` is only space, else `text` in square brackets when `m.Supplied`, else `text`. `printed` keeps its unknown branch as it is, computes `text` as today (date or truncated text), then returns `marked(text, v.Mark), marked(...) != ""`, so its results do not change. `func Display(v Value) string` *(new)*: unknown → `v.UnknownText`; else `marked(text, v.Mark)` where `text` is `datevalue.CitationDisplay(*v.Date, datevalue.CitationLong)` when `v.Date != nil`, else `truncate(v.Text, MaxRenderedBytes)`. The handler sends `Display(sourcemetadata.CitationValue(*e.Inherited, e.Field))` as the inherited value's text | Working rules "A value can be marked unknown or supplied" (supplied prints in brackets, unknown its unknown text) and "No client-side copy of an engine rule": the bracket lives once, for text and dates, so S15-41, S15-42 (the date) and S15-56 call `Display` (review M-10) | Swift composing brackets and unknown text — a client copy; `Display` for text only — the date path would keep its own bracket |
| D-5 | `WorkspaceEntry.StaysWithoutValue bool` *(new)*: true when `buildEntries` would emit the entry with no own value: suggested, or its id (`uuid.FromBytes`; a bad id is false) is a key of `in.needs.heads`. Set in all three loops. A suggestion dismissed while valued is still true; the next read drops it once its value is cleared and saved (`hidden`), the same as today | The draft host must know whether clearing keeps the row (IH-4). Today it guesses from `suggested` or "opened empty", which drops a valued unsuggested head (AC-2.4). The engine decides the rows | Swift mapping `requirement` and re-deriving the rule — a used later option has a requirement and is not kept; a client copy of loop 2 |
| D-6 | Proto. `message InheritedMetadataValue { string display_text = 1; ValueMark mark = 2; MetadataOwner owner = 3; string open_href = 4; }` *(new)*; `MetadataWorkspaceEntry.inherited = 12` (absent when nil) and `bool stays_without_value = 13`. `display_text` is D-4; `mark` styles it (italic when unknown); `owner` is the ancestor that answered (`level`, `id`) | One message the Citation board (S15-56) reuses, where the ancestor can be a graph or an Artifact | Reusing `MetadataValue` — a draft input with a `field_id`; a bare `level` string — `MetadataOwner` exists |
| D-7 | Swift. `CatalogMetadataEntry.staysWithoutValue: Bool = false` *(new)*. `MetadataDraftHost.isEmptyRow(row)` becomes `row.suggested \|\| row.staysWithoutValue`; the "opened with no value" clause goes (the engine says it). `set` and `clear` leave `inherited` as it is. A row added through Add field is appended by `set` with `inherited` nil and `staysWithoutValue` false: it shows no "Overrides" caption and clears away until the owner's Save returns the engine's rows | The engine decides which rows stay (D-5); fall back is the kept row with no own value | Computing `inherited` for an added row in Swift — a copy of the walk |
| D-8 | Swift. `CatalogInheritedMetadataValue` *(new)* `{ var displayText: String; var isUnknown: Bool; var level: Level; var openHref: String; var openURL: URL? }` and `CatalogMetadataEntry.inherited: CatalogInheritedMetadataValue? = nil` *(new)*, mapped in `GoStore.mapMetadataEntry` when `hasInherited`. A level `Level(rawValue:)` does not know maps `inherited` to nil: `Level` mirrors `vocabkey.MetadataLevels` under `api/ffi/swift_vocabulary_test.go`, so that is a version skew, not data. `MetadataValueText` gains `init(text: String, openURL: URL?, isURL: Bool, accessibilityIdentifier: String, lineLimit: Int?, chrome: Bool, secondary: Bool = false, italic: Bool = false)` *(new)*; its entry init forwards to it; its hover help shows `text` (the printed, bracketed text for an inherited value). `catalogMetadataEntry` in `macos/ProvenenciaTests/CatalogFixtures.swift` gains `inherited:` and `staysWithoutValue:` parameters with defaults | `MetadataValueText` is the one value view (inventory); the inherited value draws through it (IH-1, IH-6) | A shared value struct for own and inherited values — an own value's mark lands in S15-41, which reshapes the entry then; a forked value view |
| D-9 | A Source's metadata value write reports a keyed read. `effects.ReadInheritedValues Read = "inherited_values"` *(new)*: "what the boards below a Source inherit: moved when the Source's metadata values change", key table `sources`, added to `Reads`; `registry["source_metadata"]` gains `Reads: []ReadPath{{ReadInheritedValues, field("source_id")}}`. Swift: `CatalogRead.inheritedValues = "inherited_values"` *(new)*; `.sourceWorkspace` adds `.applyHiddenPolicy(followsOwnId: .reads(.inheritedValues))` to its `refreshes`. `applySavedMetadata` is unchanged | The engine says what a write moves (catalog-caches: "every cache names the signal that updates it"); the shown page reloads, so the cached Artifact and graph boards inherit the new value and their `met_elsewhere` follows. S15-56 adds the Artifact and graph values tables' paths, with no Swift branch | A `level == .source` branch in `applySavedMetadata` applying `.mutatedSourceWorkspace` — a second mechanism beside the effects (review M-1); Swift recomputing inherited values; re-reading a board each time a sheet opens |
| D-10 | Who reads `inherited`: `MetadataBoardView` only. `MetadataBoardModel.saved` and `suggested` stay split by `hasValue`, so an inherited row is in `suggested`. Opening an inherited row goes through the board's one inline edit: `MetadataBoardModel.editingFieldID` and `beginEdit` / `cancelEdit`, as a saved row (`beginEdit` accepts an entry with `inherited` and no value; `savedEntry` is not widened) | The model's groups already match IH-1's placement; one edit at a time, one open path (review M-11) | A row-local open `@State` — a second open/close mechanism beside `PVInlineEdit` |
| D-11 | Composition, pinned by the brief (IH-1, IH-2): an inherited row (no own value, `inherited` set) is `MetadataBoardSuggestionRow` whose value column is `PVInlineEdit` (the saved row's control, `axis: .horizontal`, `actionsStyle: .iconStack`). Its display is `MetadataValueText(text: displayText, …, lineLimit: 1, secondary: true, italic: isUnknown)` ("Unknown" when `displayText` is empty) with the caption "From {level}" on a second line under it; its pencil (`editLabel` "Override {field}") opens the editor; `restingTrailing` is the dismiss `PVIconButton`; the editor is `PVTextArea` as `MetadataBoardTextEditor`'s, empty, with the caption "Overrides {level}: {value}" under it; Save with text saves through `board.save` as a suggestion's save does; Save is disabled with no text; Escape and Cancel close it and drop the text, and the sheet's own Escape stands down while it is open (`PVInlineEdit`'s inner edit, as a saved row's). The row has no Save button or open `PVInput` at rest. A row without `inherited` is today's. A saved row with `inherited` shows the "Overrides" caption under `MetadataBoardTextEditor`, at rest and in edit. The three captions (the two new and the add row's taken notice) draw through one file-private `MetadataBoardCaption` *(new)* | The brief's IH-1 – IH-4 and inventory; one inline-edit control on the board (review M-11) | A prompt holding the inherited value — `PVInput.prompt` cannot hold a link, italics or hover help (review M-5); a click-to-open row — a second open mechanism; click-to-open on `PVInlineEdit` is a kit change for the board to propose (D-12) |
| D-12 | The board (2026-11-23) as D-11, with: the label column muted on an inherited row as on an empty suggestion; "From Source" muted under the value, hidden from VoiceOver because the value's label already says "Inherited from Source: Ancestry"; the whole value on hover through `MetadataValueText`'s `.help` (the board's kit tooltip past 36 characters); the editor is the app's `PVInlineEdit` with `PVTextArea`, as saved rows are (the board draws an input with ✓ and ✕ for its own saved rows too, and its note records that); copy as § 6 Strings, unchanged. A later wish to open the row on a click rather than the pencil goes to the user as a `PVInlineEdit` option for every row | The agreed frames and the board's spec note | — |

**Rules this plan bends.** One, accepted by the user (2026-11-23, review R-1): the rule "A format reads a field from the nearest level that holds it" and the map's S15-64 row name `CitationValues.Resolve` as the one walker and the inherited value as "`Resolve` with the owner's own level left out". D-1 moves the walk into `Nearest`, which `Resolve` calls; the inherited value is `Nearest` on `Without(owner level)`. Answer: accepted; STEP-9 rewrites the rule's sentences and the map row to name `Nearest`.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `CitationValues.Nearest` *(new)* | func | `CitationValues.Resolve` | Extends it: `Resolve` calls it; `rg -n "NearestFirst\(\)" core` finds `Resolve` the only walker |
| `citationformat.Display` *(new)* | func | `citationformat.printed` | The field branch moves into it; `printed` calls it |
| `WorkspaceEntry.Inherited`, `StaysWithoutValue` *(new)* | field | `WorkspaceEntry.Value`, `Suggested` | Fields beside them |
| `openHref(f, r)`, `WorkspaceEntry.InheritedOpenHref` *(new)* | func | `WorkspaceEntry.OpenHref` | Its body moves into `openHref`; both call it |
| `effects.ReadInheritedValues`, `CatalogRead.inheritedValues` *(new)* | keyed read | `ReadSourceHoldings` | A different set of tables moves it; the keyed-read registry is the slot |
| `InheritedMetadataValue` *(new)* | proto message | `MetadataValue`, `ValueMark`, `MetadataOwner` | Reuses `ValueMark` and `MetadataOwner` |
| `inheritedProto` *(new)* | func | `metadataEntryProto` | A helper beside it, as `requirementProto` |
| `CatalogInheritedMetadataValue` *(new)* | Swift type | `CatalogMetadataEntry` | Holds a level and printed text an entry does not |
| `MetadataValueText.init(text:…)` *(new)* | init | `MetadataValueText` | Extends the one value view |
| `marked` *(new, unexported)* | func | the bracket in `printed` | The bracket moves into it; `printed` and `Display` call it |
| `MetadataBoardCaption` *(new, file-private)* | view | the taken notice in `MetadataBoardAddRowView` | Extracted from it; three call sites in the file |
| L10n keys in § 6 Strings *(new)* | key | `L10n.Sources.metadataAddRowFieldTaken` | Same namespace |

**Builds on.** S15-62's `CitationValues` and `Without` (the `above` slot its D-9 left for this PR); S15-38's annotation path through `buildEntries` and `metadataEntryProto`; the effects registry's keyed reads; `MetadataValueText`; `L10n.CitationFormats.levelName`.
**Deletes.** `MetadataDraftHost.isEmptyRow`'s "opened with no value" clause (D-7). The add row's inline caption styling (moves into `MetadataBoardCaption`). `Resolve`'s inline loop (moves into `Nearest`).
**Next adds.** S15-55 adds the Citation's ancestors to `r`; `Nearest` then answers a Citation's graph, Artifact or Source unchanged. S15-56 draws the composer's board through the same row and adds `inherited_values` paths for the Artifact and graph values tables. S15-41 maps an own value's mark and reuses `Display` for it. S15-66 adds `list_below` beside `inherited` on the entry.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| An entry with an inherited value and no own value | `MetadataBoardSuggestionRow` | New state (D-11). An entry whose field is gone does not reach here (`buildEntries` drops a head with no field row) |
| An entry with both | `savedRow` | New state; IH-3 |
| A Source value write now refreshes the shown Source page (D-9) | `SourcePageModel`'s workspace observer (`metadata.resetIfChanged`, `SourcePageModel.swift` line 162) | The reload returns the Source rows the patch already set, so `resetIfChanged` keeps an open edit; T-11 holds it. A hidden page goes stale and reloads when shown (`whenHidden: .markStale`) |

### Scale

At the map's Scale ("a board showing up to 30 suggested fields, each with the value it inherits, read with its owner's ancestors in one batched read"; a Source with 60 Artifacts and 60 graphs): `Nearest` is a map lookup per level (two levels until S15-55) per entry; no read is added to a board. D-9 adds one `GetSourceWorkspace` per Source value save while the page is shown; `BenchmarkListWorkspacesScale` *(new, T-12)* measures `ListWorkspaces` over 121 owners on a census Source with all 16 suggested fields valued on the Source, and the PR reports its ns/op. Budget: 100 ms per read on the implementer's machine; over it is a Stop condition.

### Edges

- **Assumptions.** `Nearest` stops at the first level holding a row, whatever its text: an unknown value with empty text answers (T-1). `Without(owner level)` holds only ancestors, so `Inherited` is never the owner's own row (T-2). One row per field per level (the values tables' unique key). `Display` keeps `printed`'s results for every option (T-3, and the existing render tests stay green).
- **Neighbors.** Valued on the owner and the Source → both, own wins in a render (T-2). Owner only → `Inherited` nil. A dismissed suggestion valued on the Source → hidden (T-2). A needed head with no own value and a Source value → inherited set, `MetElsewhere` true as today (T-2). An unsuggested head valued on the owner → `StaysWithoutValue` true; an unsuggested non-head extra → false (T-2). The Source's own board → every `Inherited` nil (T-2).
- **Removed inputs.** The Source's value cleared → the write reports `inherited_values`, the page reloads, the boards lose the inherited value (T-10, T-11). An Artifact moved to another Source (S15-24) → the move lands on the target page, whose workspace read builds the boards against the target Source.
- **Real data.** `TestEveryBoardOffersTheTypeList` and T-12 run on the seeded census type; no seed changes.
- **Untrusted size.** None — the inherited value is one row per entry already read; `Display` truncates to `MaxRenderedBytes` as the render does.

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/citationformat` (`render.go`) | `func Display(v Value) string` *(new)* (D-4); `printed` calls it |
| `core/database/sourcemetadata` (`annotation.go`) | `func (v CitationValues) Nearest(fieldID []byte) (Row, bool)` *(new)* (D-1); `Resolve` calls it; doc comment |
| `core/database/sourcemetadata` (`sourcemetadata.go`) | `WorkspaceEntry.Inherited *Row`, `StaysWithoutValue bool` *(new)*; `boardInput.above CitationValues`; `buildEntries` sets both on every emitted entry (D-2, D-5); `openHref(f, r)`, `InheritedOpenHref()` *(new)*; `OpenHref`'s comment drops "the only link" |
| `core/database/effects` (`registry.go`) | `ReadInheritedValues` *(new)*, in `Reads` and `KeyTable` (`sources`); `registry["source_metadata"].Reads` (D-9) |

Errors: none new.

### FFI

`api/proto/engine.proto`:

```proto
// InheritedMetadataValue is the value a board entry's owner inherits: the
// nearest level above the owner that holds the field (sourcemetadata
// CitationValues.Nearest), printed as a citation prints it.
message InheritedMetadataValue {
  string display_text = 1; // citationformat.Display; empty for an unknown value whose field has no unknown text
  ValueMark mark = 2;      // absent means no mark
  MetadataOwner owner = 3; // the ancestor that holds it
  string open_href = 4;    // web link to open; empty when the value is not one
}
// in MetadataWorkspaceEntry:
  InheritedMetadataValue inherited = 12; // absent when nothing above holds the field
  bool stays_without_value = 13;         // the board keeps this entry with no own value (suggested, or a head its formats read)
```

Handler: `api/ffi/handlers/metadata.go` `inheritedProto(e sourcemetadata.WorkspaceEntry) *engine.InheritedMetadataValue` *(new)*, set in `metadataEntryProto` with `StaysWithoutValue`. The `inherited_values` read rides `WriteEffects.reads` with no handler change. Regenerate with `./scripts/generate-proto.sh`. No new method.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Entry types | — | `macos/App/Platform/GenealogyStore.swift` | D-7, D-8; `openHref`'s comment drops "The only link" |
| Mapping | — | `macos/App/Platform/GoStore.swift` `mapMetadataEntry` | D-7, D-8 |
| Keyed read | — | `CatalogMutation.swift` `CatalogRead`, `CatalogQueryRegistry.swift` `.sourceWorkspace` | D-9 |
| Draft host | — | `MetadataDraftHost.swift` `isEmptyRow` | D-7 |
| Inherited row | `MetadataBoardSuggestionRow`, `PVInlineEdit`, `MetadataValueText`, `PVTextArea`, `MetadataBoardCaption` | `MetadataBoardView.swift` | D-10, D-11; IH-1, IH-2, IH-5, IH-6, IH-8 |
| Override caption | `MetadataBoardCaption` under `MetadataBoardTextEditor` | `MetadataBoardView.swift` `savedRow` | IH-3 |
| Caption | `MetadataBoardCaption` *(new, file-private)* | `MetadataBoardView.swift` | The taken notice moves to it |

States: no inherited value → today's rows; unknown → `displayText` italic, or "Unknown" when empty (IH-5); supplied → the engine's brackets; long → one line, truncated, whole on hover (IH-6). Accessibility: IH-8; identifiers `<prefix>.<fieldID>.inherited` *(new)* for the closed value and `<prefix>.<fieldID>.inheritedFrom` *(new)* for its caption. Width: the 880pt sheets at Regular and Wide (IH-W1); there is no one-column form.

### Strings

L10n keys *(new)*, final wording from the board (D-12):

- `L10n.Sources.metadataInheritedFrom(level:)` = "From %@"
- `L10n.Sources.metadataInheritedAccessibility(level:value:)` = "Inherited from %@: %@"
- `L10n.Sources.metadataInheritedHint` = "Opens a field to type a value that overrides it"
- `L10n.Sources.overrideMetadataValueLabel(field:)` = "Override %@"
- `L10n.Sources.metadataOverrides(level:value:)` = "Overrides %@: %@"
- `L10n.Sources.metadataInheritedUnknown` = "Unknown"

`%@` level is `L10n.CitationFormats.levelName(_:)`. Removed: none.

## 7. Steps

**STEP-1 — One walker names the level; one rule prints a value**
Files: `core/database/sourcemetadata/annotation.go`, `annotation_test.go`, `core/citationformat/render.go`, `render_test.go`.
Do: D-1, D-4.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/citationformat/ ./core/database/sourcemetadata/` passes, T-1 and T-3 included.

**STEP-2 — Board entries carry what they inherit and whether they stay**
Files: `core/database/sourcemetadata/sourcemetadata.go`, `sourcemetadata_test.go`.
Do: D-2, D-3, D-5; `openHref`, `InheritedOpenHref`; the `OpenHref` comment.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcemetadata/` passes, T-2, T-4, T-5, T-6 included.

**STEP-3 — The wire carries them**
Files: `api/proto/engine.proto`, generated code, `api/ffi/handlers/metadata.go`, `metadata_test.go`. Skill: `add-ffi-handler`.
Do: D-6; `./scripts/generate-proto.sh`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/ffi/...` passes, T-7 included; `git status` shows the regenerated Go and Swift files.

**STEP-4 — A Source value write reports `inherited_values`**
Files: `core/database/effects/registry.go`, `reads_test.go`, `api/ffi/handlers/metadata_test.go`, `macos/App/Features/Workspace/Session/CatalogMutation.swift`.
Do: D-9's Go part and the `CatalogRead` case.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/effects/ ./api/ffi/...` passes, T-10 and the Swift vocabulary parity test included.

**STEP-5 — Swift decodes the entry; the draft host keeps what the engine keeps**
Files: `macos/App/Platform/GenealogyStore.swift`, `GoStore.swift`, `macos/App/Features/Sources/MetadataDraftHost.swift`, `macos/ProvenenciaTests/CatalogFixtures.swift`, `MetadataDraftHostTests.swift`. Skill: `add-swift-test`.
Do: D-7, D-8 (types and mapping). Update `anEmptyHeadTheReadReturnedClearsToEmptyAndDismisses` to build its head with `staysWithoutValue: true`.
Check: T-8 and T-9 pass; `MetadataDraftHostTests` green.

**STEP-6 — The Source page follows `inherited_values`**
Files: `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift`, `macos/ProvenenciaTests/SourcePageModelTests.swift`. Skill: `add-workspace-place`.
Do: D-9's `refreshes` line.
Check: T-11 passes; `CatalogQueryRegistryTests` green.

**STEP-7 — The row shows it**
Files: `macos/App/Features/Sources/MetadataBoardView.swift`, `MetadataBoardModel.swift` (`beginEdit` for an inherited entry), `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`. Skills: `add-ui-component`, `add-localized-string`.
Do: D-8's `MetadataValueText` init, D-10, D-11, D-12; § 6 Strings.
Check: the manual check (§ 10) steps 1 – 7.

**STEP-8 — Measure and run the full check**
Files: `core/database/sourcemetadata/sourcemetadata_test.go` (T-12, and `seededWorld`, `emptyWorld`, `newSource`, `newLevelOwner` widened to `testing.TB`).
Do: T-12; `CGO_ENABLED=1 go test -tags fts5 -run '^$' -bench BenchmarkListWorkspacesScale ./core/database/sourcemetadata/`; then `scripts/check-pr.sh`.
Check: ns/op under the § 6 Scale budget and recorded in the PR body; `check-pr: PASS`.

**STEP-9 — Docs**
Files: `docs/deployment-plan/spike-15/deployment-plan.md` (the rule "A format reads a field from the nearest level that holds it": its sentences from "One resolver walks them" to "nothing else walks the levels" name `CitationValues.Nearest`, which `Resolve` and the inherited value read; the S15-64 row and scope entry name `Nearest` on `Without(owner level)`; map row status), `docs/source-layer-data-model.md` § 5.2 (beside the paragraph on every board offering the type's list: each board entry carries the value it inherits, from `CitationValues.Nearest`, printed by `citationformat.Display`), `docs/catalog-caches.md` § Swift caches (the "Per-view query results" row's sentence on the Source page's workspace and the `source_holdings` read gains `inherited_values`), `core/database/effects/README.md` (its list of keyed reads), the `KeyTable` doc comment in `registry.go`, `docs/macos-client-patterns.md` (the metadata values bullet: a Source value write also reports `inherited_values`, which reloads the shown Source page), `.agents/skills/add-workspace-place/SKILL.md` (what `sourceWorkspace` follows), `.agents/skills/add-audit-scope/SKILL.md` (the keyed reads it lists), `completed.md`, this plan (status, Landed note), `design/S15-D33-inherited-values.md` → `design/archive/`, `design/README.md`.
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-64-inherited-values.md` reports no errors.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period ("Show each Artifact and graph board row the value it inherits from its Source."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/sourcemetadata/annotation_test.go` `TestCitationValuesNearest` *(new)* | Rows at graph and Source for field f → the graph's row, `Owner.Level` graph; Source only → Source's; none → false; graph row marked unknown with "" → that row; `Without(graph)` → the Source's | D-1 |
| T-2 | Go | `sourcemetadata_test.go` `TestListWorkspacesInherited` *(new)*, table on `seededWorld` | World: a census Source (`seededType(t, c, "census")`) with Provider "Ancestry" and Publisher "Ashby Press" set by `runSet`, its census formats replaced through `sourcetypestest.SetFormats` with `Full: "{meta.provider}, {meta.publisher}"` so `publisher` is a needed unsuggested head; Column (`column`) set on the Source as an extra; one Artifact and one graph (`newLevelOwner`). Rows: Artifact with no Provider → `Inherited` "Ancestry", level source, `StaysWithoutValue` true; Artifact with Provider "FamilySearch" (`runSetOwner`) → `Value` "FamilySearch", `Inherited` "Ancestry"; graph → as the Artifact; Source's board → every `Inherited` nil; Publisher with no Artifact value → `Inherited` "Ashby Press", `MetElsewhere` true; Publisher valued on the Artifact → `StaysWithoutValue` true; Column → no entry on the Artifact; Line (`line_number`) set on the Artifact only and not read → `StaysWithoutValue` true (suggested); a field neither suggested nor read (`column`) set on the Artifact → `StaysWithoutValue` false; Provider dismissed on the Artifact (`runDismissOwner`) → no entry; a Book Source (`seededType(t, c, "book")`) with Publisher set unknown → its Artifact's `Inherited.Mark.Unknown` | AC-1.1, AC-1.3 – AC-1.5, AC-1.7, AC-2.4, D-2, D-3, D-5 |
| T-3 | Go | `core/citationformat/render_test.go` `TestDisplay` *(new)* | {"Ancestry"} → "Ancestry"; supplied "Calder County" → "[Calder County]"; unknown with unknown text "n.p." → "n.p."; unknown, none → ""; "  " → ""; text over `MaxRenderedBytes` → truncated; a supplied date → its long display in brackets | D-4, AC-1.5 |
| T-4 | Go | `sourcemetadata_test.go` `TestListDraftWorkspaceInherited` *(new)*, on `seededWorld` | A census Source with Provider "Ancestry" (`runSet`); `ListDraftWorkspace(c, src.ID, LevelArtifact)` and `LevelGraph` → Provider `Inherited` "Ancestry", `StaysWithoutValue` true | AC-1.2 |
| T-5 | Go | `sourcemetadata_test.go` `TestWorkspaceEntryOpenHref` (new rows) | No value, inherited URL → `OpenHref()` "", `InheritedOpenHref()` the link; inherited text not a URL → "" | AC-1.6 |
| T-6 | Go | `sourcemetadata_test.go` `TestListWorkspacesAnnotationsScale` (extend) | Before the read, `runSet` puts `url` (census suggests it) on the Source; each of the 120 Artifact and graph boards → its `url` entry's `Inherited` is the Source's | D-2 (at Scale) |
| T-7 | Go | `api/ffi/handlers/metadata_test.go` `TestMetadataBoardInherited` *(new)* (helpers `newMetadataOwners`, `boardEntries`) | The Source page's boards (`GetSourceWorkspace`, `api/ffi/handlers/sources.go`, through `boardsProto`) and `GetDraftMetadataBoard` → Artifact Provider `inherited` {display_text "Ancestry", owner {level "source", id the Source}}; URL `open_href` set; a supplied value's `display_text` "[Calder County]"; `stays_without_value` true on suggestions; Source board entries have no `inherited` | D-6, AC-1.1, AC-1.2, AC-1.4, AC-1.6 |
| T-8 | Swift | `macos/ProvenenciaTests/MetadataDraftHostTests.swift` `setAndClearKeepTheInheritedValue` *(new)* | Suggested entry with inherited "Ancestry": set "FamilySearch" → `hasValue`, `inherited` "Ancestry"; clear → `hasValue` false, `inherited` kept, row kept, `isChanged` false | D-7, AC-2.3 |
| T-9 | Swift | `MetadataDraftHostTests.swift` `clearKeepsOnlyRowsTheEngineKeeps` *(new)* | Unsuggested entry opened with a value and `staysWithoutValue` true, with inherited → clear keeps it, inherited shown; `staysWithoutValue` false → removed; a row added through `set` for a new field → `inherited` nil, removed on clear | D-7, AC-2.4 |
| T-10 | Go | `core/database/effects/reads_test.go` `TestReadsDeclare` (new key) and `api/ffi/handlers/metadata_test.go` `TestSetMetadataReportsInheritedValues` *(new)* | `ReadInheritedValues: {"source_metadata"}`; `SetMetadata` on a Source owner → the reply's `effects.reads` hold `inherited_values` with the Source's id; on an Artifact owner → no `inherited_values` | D-9 |
| T-11 | Swift | `macos/ProvenenciaTests/SourcePageModelTests.swift` `sourcePageFollowsInheritedValues` *(new)*, beside the reads test at line 445 | `session.apply(reads(.inheritedValues))` → `getSourceWorkspaceCalls` + 1; a Source board save whose `nextWriteEffects` report it → one reload, and an open edit on another Source row kept | D-9, AC-2.5 |
| T-12 | Go | `sourcemetadata_test.go` `BenchmarkListWorkspacesScale` *(new)* | 121 owners on a census Source with its 16 suggested fields valued on the Source (`runSet` each) → ns/op reported. `seededWorld`, `emptyWorld`, `newSource` and `newLevelOwner` take `testing.TB` (from `*testing.T`) so the benchmark shares them | D-9 (Scale) |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `TestListWorkspacesAnnotations` (entry struct equality), `core/citationformat` render tests, `MetadataDraftHostParityTests` (the shared `core/database/sourcemetadata/testdata/draft_board_scenarios.json`, untouched), `MetadataDraftHostTests`, `CatalogQueryRegistryTests`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it); "the only link the app opens from metadata" gone from both comments
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] T-12's ns/op is in the PR body
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status, the rule and row naming Nearest; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated
- [ ] Domain docs updated: source-layer-data-model.md § 5.2, catalog-caches.md § Swift caches, effects/README.md, macos-client-patterns.md, the add-workspace-place and add-audit-scope skills
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

Use a project with a **Census** Source "1880 census, Calder County" holding Provider "Ancestry" and a URL, with at least one Artifact and one Evidence graph that hold no Provider. The app cannot mark a value unknown or supplied until S15-41, so AC-1.5 is covered by T-2, T-3 and T-7, not here.

1. Open the Source; open an Artifact's sheet. Provider reads "Ancestry", "From Source"; the URL row's link opens the Source's URL (AC-1.1, AC-1.6).
2. Click Provider's pencil ("Override Provider"): an empty editor with "Overrides Source: Ancestry" under it; Escape closes it and the sheet stays. Type "FamilySearch", Return, Save. Reopen: Provider is "FamilySearch" with "Overrides Source: Ancestry". Open the provenance sheet of a Citation on that Artifact: the citation reads FamilySearch (AC-2.1, AC-2.2).
3. Trash Provider: the row shows "Ancestry", "From Source" again; Save; reopen: still inherited (AC-2.3).
4. Add an Artifact: Provider reads "Ancestry", "From Source" before anything is typed; Cancel (AC-1.2).
5. Open a graph's form, then Add graph: Provider inherited in both (AC-1.3).
6. On the Source's Metadata section change Provider to "Calder Archives"; open the Artifact sheet: "Calder Archives". The Source's section shows no "From" line anywhere (AC-2.5, AC-1.4).
7. With VoiceOver, focus the inherited Provider value: it reads "Provider, Inherited from Source: Ancestry"; its pencil reads "Override Provider" and the hint. Repeat step 1 with the window at 2560pt: the sheet is the same, centred (IH-8, IH-W1).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| D-9's reload resets an edit on the Source's board | `resetIfChanged` compares rows; T-11 |
| `Display` changes a rendered citation | `printed` calls it with today's logic; the render tests stay green |
| Entry equality in Go tests changes with the new fields | Extend the expected entries; do not drop the fields from comparisons |

**Stop and report if:**

- `CitationValues.Resolve` no longer walks `vocabkey.NearestFirst()` itself, or a second walker over `NearestFirst()` exists at the base.
- `boardInput.above` cannot become `CitationValues` because a caller passes another `Resolver`.
- A board reply path builds `MetadataWorkspaceEntry` without `metadataEntryProto`.
- `printed` cannot call `Display` without changing a render test's expected text.
- `registry["source_metadata"]` cannot take `Reads` because `metadataEffects` panics on it.
- T-11 shows a reload resetting an open edit, or T-12 is over 100 ms.
- The agreed board draws the inherited row differently from D-11 in kind (an input holding the value, a new row type), or needs a new kit primitive.

## 12. Open questions

None.

## 13. PR

**Title:** S15-64 — Boards show inherited values
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; T-12's ns/op; `Plan: docs/deployment-plan/spike-15/prs/S15-64-inherited-values.md`.
