# S15-64 — Boards show inherited values

**Status:** Blocked — on board S15-D33
**Spike / slice:** Spike 15 · Slice 11 — Metadata at any level
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D33](../design/S15-D33-inherited-values.md), board not drawn yet
**Board:** — (filled when the board is agreed; the plan's § 6 macOS and Strings follow it)
**Depends on:** S15-63 (landed [#955](https://github.com/Jake-Robins-Studios/provenencia/pull/955)), S15-D33
**Blocks:** S15-56, S15-66
**Branch:** `s15-64-inherited-values`
**Version bump:** minor, 0.35.0 (today's `VERSION`) → **0.36.0** (or the next minor after `main`'s `VERSION` when you rebase): every Artifact and graph board shows what it inherits, a new wire field ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md), [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md) (the Source workspace cache key)
**Rules that bind:** `.cursor/rules/go-tests.mdc`
**Context:** working rules "A board shows what its owner inherits", "A format reads a field from the nearest level that holds it", "One metadata board", "Metadata saves with its owner's write", "A value can be marked unknown or supplied", "Boards flag needed fields; the engine decides the rows"; [`source-layer-data-model.md` § 5.2](../../../source-layer-data-model.md); [`catalog-caches.md`](../../../catalog-caches.md)
**Planned:** 2026-11-23 against `main` @ `3d8863a`
**Review:** [`S15-64-inherited-values.review.md`](S15-64-inherited-values.review.md)

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

A citation reads each field from the nearest level that holds a value (S15-62), so Provider "Ancestry" typed once on a Source serves every Artifact and Evidence graph of it. Today the Artifact sheet and the graph form show that row empty. After this PR each board entry carries the value its owner inherits, with the level and the mark it comes from; the board row shows it read only ("From Source"), typing a value saves this owner's own and overrides it, and clearing that value falls back. It shows on the Artifact sheet (edit and add) and the graph form (edit and add); the Source's own board has nothing above it.

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
| AC-1.5 | Source's Publisher marked unknown (unknown text "n.p."); Place of publication "Calder County" marked supplied | The Artifact sheet's Publisher reads "n.p." in italics and Place of publication "[Calder County]" (IH-5) |
| AC-1.6 | Source's URL "https://example.org/calder/1880" | The Artifact's URL row opens it from the inherited value (IH-6) |
| AC-1.7 | Census Source with a Source-only extra field Column (not suggested, not read by a format) valued "4" | The Artifact board has no Column row (D-3) |

**US-2.** As a researcher, I override an inherited value for one Artifact or graph and can go back to the Source's.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | AC-1.1's sheet; type "FamilySearch" in Provider, Save the row, Save the sheet | The Artifact stores Provider "FamilySearch"; its row is a saved row with "Overrides Source: Ancestry" (IH-2, IH-3); the Source keeps "Ancestry" |
| AC-2.2 | After AC-2.1, the Artifact's citation | Reads "FamilySearch" (the S15-62 resolver; no change here) |
| AC-2.3 | Reopen the sheet; trash Provider | The row shows "Ancestry", "From Source" again, the sheet is dirty; Save clears the Artifact's value; reopening shows the inherited row (IH-4) |
| AC-2.4 | On the Source page, change the Source's Provider to "Calder Archives", then open the Artifact sheet of an Artifact with no Provider | The row shows "Calder Archives" (D-8) |

## 3. Scope

| In | Covered by |
| --- | --- |
| Each board entry carries the nearest ancestor's row (value, mark, level) from the board's own read; no extra read (D-1, D-2) | STEP-1, STEP-2, AC-1.1 – AC-1.4 |
| The wire entry carries it, with its link (D-4, D-5) | STEP-3, AC-1.6 |
| Swift decodes it; the draft host keeps it across set and clear (D-6, D-7) | STEP-4, STEP-5, AC-2.3 |
| A Source-owner board write reloads the Source workspace so cached Artifact and graph boards inherit the new value (D-8) | STEP-6, AC-2.4 |
| The board row draws IH-1 – IH-8, IH-W1 on the Artifact sheet and the graph form (D-10) | STEP-7, AC-1.1 – AC-2.3 |
| Copy (§ 6 Strings) | STEP-7 |
| Docs: `source-layer-data-model.md` § 5.2, `catalog-caches.md`, map, completed, brief archive | STEP-9 |

| Out | Home |
| --- | --- |
| The composer's Citation board and a Citation's ancestors (graph, Artifact, Source) | S15-55 (the read), S15-56 (the board) |
| Hiding inherited rows behind a control | Not planned (rule "A board shows what its owner inherits": a later choice once the boards are in use) |
| Values below an owner (a Source's Artifacts' values on the Source's section) | Not planned (same rule) |
| Inherited values in the Artifacts list's read-only copy details or on graph cards | Not planned (the brief's § 2.2: those show own values only) |
| A row for a field only an ancestor holds (not suggested, not read, no own value) | Not planned (D-3) |
| Drawing an own value's mark; the Unknown and Supplied control | S15-41 |
| Needed and used flags on the rows | S15-39 |
| The list-below hint and Move to Source | S15-66 |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Resolver | `core/database/sourcemetadata/annotation.go` `CitationValues.Resolve` | Walks `vocabkey.NearestFirst()` over `Rows` for a field target with no level and returns a `citationformat.Value` (text, mark, unknown text). The level that answered is lost |
| Without | `annotation.go` `CitationValues.Without` | Copy with one level's rows and built-ins removed; boards use it as `above` |
| Board entry | `core/database/sourcemetadata/sourcemetadata.go` `WorkspaceEntry` | `Field`, `Value *Row`, `Suggested`, `Annotation`, `SortOrder`; `OpenHref()` reads `Value` only |
| Board build | `sourcemetadata.go` `listWorkspaces` | Reads the owners' and their Sources' values in one `readByOwners`; per owner builds `r` (own level + Source) and `above := r.Without(o.Level)`; passes both to `buildEntries` |
| Draft board | `sourcemetadata.go` `ListDraftWorkspace` | `r` holds the Source's rows only; passes `above: r` |
| Entries | `sourcemetadata.go` `buildEntries`, `boardInput` | Three loops: suggestions, unsuggested heads with no own value, own-valued extras; `boardInput.above` is a `citationformat.Resolver` used only by `annotate` |
| Wire | `api/proto/engine.proto` `MetadataWorkspaceEntry` (fields 1 – 11; 3, 7, 8 reserved) | No inherited value |
| Handler | `api/ffi/handlers/metadata.go` `metadataEntryProto` | The one mapper every board reply uses (`ListWorkspaces` boards at line 68, the draft board, `ownerBoardProto`) |
| Mark on the wire | `api/ffi/handlers/value_mark.go` `valueMarkProto` | Nil for the zero mark |
| Swift entry | `macos/App/Platform/GenealogyStore.swift` `CatalogMetadataEntry`, `CatalogMetadataField` | No mark, no inherited value; `CatalogMetadataField` has no `unknownText` |
| Swift mapping | `macos/App/Platform/GoStore.swift` `mapMetadataEntry`, `mapMetadataField` | Field by field; the only mapper |
| Draft host | `macos/App/Features/Sources/MetadataDraftHost.swift` `MetadataDraftHost` | `set` and `clear` change `valueText`, `hasValue`, `openHref` in place; `clear` removes a row that is not an empty row (`isEmptyRow`: suggested, or opened empty) |
| Board model | `macos/App/Features/Sources/MetadataBoardModel.swift` `saved`, `suggested` | Split by `hasValue` |
| Board view | `macos/App/Features/Sources/MetadataBoardView.swift` `MetadataBoardSuggestionRow`, `savedRow`, `MetadataBoardTextEditor`, `MetadataValueText` | Empty row: dashed card, label, `PVInput` with prompt "Add a value…", Save, dismiss. Saved row: handle, label, `PVInlineEdit` over `MetadataValueText` with trash |
| Source board writes | `macos/App/Features/Sources/SourcePageContext.swift` `applySavedMetadata` | Every owner's write applies `.wroteMetadataBoard`, a patch of that owner's rows only (`CatalogQueryPatch.metadataBoard()` in `CatalogLastUpdated.swift`). A Source write leaves the cached Artifact and graph boards as they were |
| Sheet open | `macos/App/Features/Sources/ArtifactSheetModel.swift` (line 92), `SourceGraphFormModel.swift` (line 82) | Edit mode builds `MetadataDraftHost` from the cached rows (`context.metadataRows(for:)`); add mode from `readDraftBoardForAdd` |
| Level names | `macos/App/Platform/L10n.swift` `L10n.CitationFormats.levelName(_:)` | "Source", "Artifact", "Evidence graph", "Citation" |
| Tests | `core/database/sourcemetadata/annotation_test.go` `TestCitationValuesResolve`; `sourcemetadata_test.go` `TestListWorkspacesAnnotations`, `TestDraftBoardScenarios`, `TestListWorkspacesAnnotationsScale`; `api/ffi/handlers/metadata_test.go` `TestMetadataBoardRequirements`, `TestGetDraftMetadataBoard`; `macos/ProvenenciaTests/MetadataDraftHostTests.swift`, `SourcePageModelTests.swift` (`saveMetadataValueFillsSuggestion`), `CatalogQueryRegistryTests.swift` | Cover the requirement on the wire, the draft host's set and clear, and the patch |

**Precedent.** S15-38 ([#910](https://github.com/Jake-Robins-Studios/provenencia/pull/910)) added `requirement` to every board entry the same way: computed in `buildEntries` from the board's one read, carried by `metadataEntryProto`, a new optional proto field. Copy its shape: one Go field, one proto field, one mapper line, table tests in `sourcemetadata_test.go` and `metadata_test.go`. `openHref` (field 9) is the precedent for a derived link the client opens.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `func (v CitationValues) Nearest(fieldID []byte) (Row, bool)` *(new)* in `annotation.go`: the row of the nearest level in `vocabkey.NearestFirst()` that holds `fieldID`. `Resolve`'s no-level branch becomes `if row, ok := v.Nearest(id); ok { return CitationValue(row, v.Fields[id]) }`. The doc comment on `CitationValues` says "Nearest is the one place the levels are walked" | The rule: the inherited value is the resolver without the owner's level, "no second walk". `Resolve` returns a `citationformat.Value`, which has no level; `Row.Owner.Level` carries it | A second loop over `NearestFirst()` in `buildEntries` — two walkers; returning the level from `Resolve` — changes `citationformat.Resolver`, which the renderer and the format package share |
| D-2 | `WorkspaceEntry.Inherited *Row` *(new)*: `above.Nearest(field id)` for every entry `buildEntries` emits (the three loops), whether or not the entry has its own value; nil when nothing above holds the field. Its level is `Inherited.Owner.Level`. `boardInput.above` becomes `CitationValues` (from `citationformat.Resolver`); `annotate` still takes it as a `Resolver` | The rule: "each board entry carries, besides its own value, the value it inherits". Carried with an own value so a draft can fall back on clear without a read (D-7), and so IH-3 can say what an override hides. `listWorkspaces` and `ListDraftWorkspace` already build `above` as a `CitationValues` | An `Inherited` only on entries with no own value — the draft host could not fall back until Save; a level field beside it — `Row.Owner` already holds it |
| D-3 | Inherited values attach to the entries the board already emits. A field only an ancestor holds (not suggested, not a head, no own value) adds no entry; a dismissed suggestion stays hidden | Rule "Boards flag needed fields; the engine decides the rows": which fields a board lists is unchanged; the rule says each *entry* carries what it inherits | Emitting an entry per ancestor value — every Source extra would appear on every Artifact and graph board, a change to which rows a board lists that no rule asks for |
| D-4 | Proto: `MetadataWorkspaceEntry.inherited = 12` of `InheritedMetadataValue` *(new)* `{ string value_text = 1; ValueMark mark = 2; string level = 3; string open_href = 4; }`; absent when nil. `level` is the `vocabkey.Level` string ("source"), as `MetadataOwner.level` | One message the Citation board (S15-56) reuses with "graph" and "artifact" | Reusing `MetadataValue` — it has `field_id` and no level or link |
| D-5 | The link: `func openHref(f metadatafields.Field, r *Row) string` *(new, unexported)* holds today's `WorkspaceEntry.OpenHref` body; `OpenHref()` calls it with `e.Value`, and `InheritedOpenHref()` *(new)* with `e.Inherited` | One rule for which values are links (`urlshape.OpenHref`) | Swift building the link — rule "No client-side copy of an engine rule"; a second copy of the body |
| D-6 | Swift: `CatalogValueMark` *(new)* `{ var unknown: Bool; var supplied: Bool }` (Sendable, Equatable), `CatalogInheritedMetadataValue` *(new)* `{ var valueText: String; var mark: CatalogValueMark; var level: Level; var openHref: String; var openURL: URL? }`, `CatalogMetadataEntry.inherited: CatalogInheritedMetadataValue? = nil` *(new)*, `CatalogMetadataField.unknownText: String = ""` *(new)*. `GoStore.mapMetadataEntry` maps `hasInherited`; a `level` string `Level(rawValue:)` does not know maps to nil | The row draws the level name, the mark and the unknown text (IH-5); S15-41 reuses `CatalogValueMark` for own values | A display string from Go — the mark's look is the board's (brief IH-5), and the level name is localized in Swift (`L10n.CitationFormats.levelName`) |
| D-7 | `MetadataDraftHost.set` and `clear` leave `inherited` as it is. `clear` of a row with an inherited value follows today's rule: an empty row (suggested, or opened empty) keeps its place with no value and shows the inherited value; an extra is removed, as the engine drops it after Save (D-3). `isChanged` and `draft` are unchanged | Fall back (IH-4) is the entry with no own value; nothing to compute | Keeping an extra row because it inherits — the board would show a row the next read drops |
| D-8 | A write to the Source's own board reloads the Source workspace: in `SourcePageContext.applySavedMetadata`, when `owner.level == .source`, apply `.mutatedSourceWorkspace(sourceId: sourceID)` in place of `.wroteMetadataBoard`. Every other owner keeps `.wroteMetadataBoard`. The local `workspace?.setMetadataRows` before it stays, so the row shows at once | A Source value is what every Artifact and graph board inherits (and their `met_elsewhere`, since S15-62); a patch of the Source's rows leaves those cached boards stale, and the sheets open from the cache (AC-2.4). `applyWrite` is the precedent for a page write that reloads | Swift recomputing the boards' inherited values — a client copy of the engine's walk; re-reading the board each time a sheet opens — a read and a loading state per open; carrying every child board on the Source write's reply — a wider reply for every field save |
| D-9 | Who reads `inherited`: `MetadataBoardView` only. `MetadataBoardModel.saved` and `suggested` stay split by `hasValue`, so an inherited row is in `suggested` | The row's look is a view concern; the model's groups already match IH-1's placement | A third group in the model — IH-1 places inherited rows with the suggestions |
| D-10 | The row's composition, copy and VoiceOver: what the agreed S15-D33 board draws for IH-1 – IH-8. **Filled when the board is agreed** | The brief is the gate | — |

**Rules this plan bends.** None. D-1 moves the level walk from `Resolve` into `Nearest`, which `Resolve` calls; the rule "nothing else walks the levels" holds, and STEP-1 updates the comment.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `CitationValues.Nearest` *(new)* | func | `CitationValues.Resolve` | Extends it: `Resolve` calls it; searched `NearestFirst()` callers (`rg -n "NearestFirst\(\)" core`): `Resolve` is the only walker |
| `WorkspaceEntry.Inherited` *(new)* | field | `WorkspaceEntry.Value` | Same type, one field beside it |
| `openHref`, `WorkspaceEntry.InheritedOpenHref` *(new)* | func | `WorkspaceEntry.OpenHref` | Its body moves into `openHref`; both call it |
| `InheritedMetadataValue` *(new)* | proto message | `MetadataValue`, `ValueMark` | `MetadataValue` is a draft's input (field id, no level); it reuses `ValueMark` |
| `inheritedProto` *(new)* | func | `metadataEntryProto` | A helper beside it, as `requirementProto` |
| `CatalogValueMark`, `CatalogInheritedMetadataValue` *(new)* | Swift type | `CatalogMetadataEntry` | Searched `rg -n "Mark" macos/App/Platform/GenealogyStore.swift`: no Swift mark type yet |
| `CatalogMetadataField.unknownText` *(new)* | Swift field | `mapMetadataField` | The wire field exists (`MetadataField.unknown_text`), unmapped |
| L10n keys in § 6 Strings *(new)* | key | `L10n.Sources.metadataAddRowFieldTaken` | Same namespace |

**Builds on.** S15-62's `CitationValues` and `Without` (the "above" slot its D-9 left for this PR); S15-38's annotation path through `buildEntries` and `metadataEntryProto`; `applyWrite`'s reload; `L10n.CitationFormats.levelName`.
**Deletes.** None — nothing becomes dead. `Resolve`'s inline loop moves into `Nearest`.
**Next adds.** S15-55 adds the Citation's ancestors to `r`; `Nearest` then answers a Citation's graph, Artifact or Source with no change here. S15-56 draws the composer's board through the same row. S15-41 reuses `CatalogValueMark` for own values. S15-66 adds `list_below` beside `inherited` on the entry.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| An entry with an inherited value and no own value | `MetadataBoardSuggestionRow` | New state; drawn per D-10. An entry whose field is gone does not reach here (`buildEntries` drops a head with no field row) |
| An entry with both | `savedRow` | New state; IH-3 |
| A Source-board write now reloads the workspace (D-8) | `SourcePageModel`'s workspace observer (`resetIfChanged`, `SourcePageModel.swift` line 162) | A reload that returns the same Source rows does not reset an open edit (`resetIfChanged` compares rows); T-9 holds it |

### Scale

At the map's Scale ("a board showing up to 30 suggested fields, each with the value it inherits, read with its owner's ancestors in one batched read"; a Source with 60 Artifacts and 60 graphs): `Nearest` is a map lookup per level (two levels until S15-55), per entry; no read is added. `TestListWorkspacesAnnotationsScale` (121 boards) asserts the inherited value on every board (T-5). D-8 adds one `GetSourceWorkspace` per Source-board field write; it is the same read the page opens with, already 121 boards in one `listWorkspaces`.

### Edges

- **Assumptions.** `Resolve`'s walk stops at the first level holding a row, whatever its text: an unknown value with empty text answers (T-1). `Without(owner level)` holds only ancestors, so `Inherited` is never the owner's own row (T-2). `rowsByField` keys one row per field per level (the value tables' unique key).
- **Neighbors.** A field valued on the owner and the Source → both, own wins in a render (T-2). Valued on the owner only → `Inherited` nil. A dismissed suggestion valued on the Source → hidden (T-2). A needed head with no own value and a Source value → inherited set, `MetElsewhere` true as today (T-2). The Source's own board → every `Inherited` nil (T-2).
- **Removed inputs.** The Source's value cleared → the next read has no inherited value; on the Source page D-8's reload carries it to the cached boards (T-9). A Source deleted → its boards go with it. An Artifact moved to another Source (S15-24) → the move applies its effects and lands on the target page (`SourceMoveModel`), whose workspace read builds the board against the target Source.
- **Real data.** None — no table- or seed-driven rule changes.
- **Untrusted size.** None — the inherited value is one row per entry already read.

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/sourcemetadata` (`annotation.go`) | `func (v CitationValues) Nearest(fieldID []byte) (Row, bool)` *(new)* (D-1); `Resolve` calls it |
| `core/database/sourcemetadata` (`sourcemetadata.go`) | `WorkspaceEntry.Inherited *Row` *(new)*; `boardInput.above CitationValues`; `buildEntries` sets `Inherited` on every emitted entry (D-2); `openHref(f, r)` *(new)*, `InheritedOpenHref()` *(new)* (D-5) |

Errors: none new.

### FFI

`api/proto/engine.proto`:

```proto
// InheritedMetadataValue is the value a board entry's owner inherits: the
// nearest level above the owner that holds the field (sourcemetadata
// CitationValues.Nearest).
message InheritedMetadataValue {
  string value_text = 1;
  ValueMark mark = 2;   // absent means no mark
  string level = 3;     // vocabkey.Level: "source", "artifact" or "graph"
  string open_href = 4; // web link to open; empty when the value is not one
}
// in MetadataWorkspaceEntry:
  InheritedMetadataValue inherited = 12; // absent when nothing above holds the field
```

Handler: `api/ffi/handlers/metadata.go` `inheritedProto(e sourcemetadata.WorkspaceEntry) *engine.InheritedMetadataValue` *(new)*, set in `metadataEntryProto`. Regenerate with `./scripts/generate-proto.sh`. No new method.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Entry types | — | `macos/App/Platform/GenealogyStore.swift` | D-6 |
| Mapping | — | `macos/App/Platform/GoStore.swift` `mapMetadataEntry`, `mapMetadataField` | D-6 |
| Draft host | — | `MetadataDraftHost.swift` | D-7: no change to `set` and `clear` beyond keeping `inherited` (they already keep it); T-7 pins it |
| Source-board write | — | `SourcePageContext.swift` `applySavedMetadata` | D-8 |
| Inherited row | `MetadataBoardSuggestionRow`, `PVInput`, caption text | `MetadataBoardView.swift` | IH-1, IH-2, IH-5, IH-6, IH-8 — per D-10 |
| Override caption | caption text under `MetadataBoardTextEditor` | `MetadataBoardView.swift` `savedRow` | IH-3 |
| Value text | `MetadataValueText` | `MetadataBoardView.swift` | Inherited value and link drawn through it (inventory) |

States: no inherited value → today's rows; inherited unknown → unknown text or "Unknown", italic (IH-5); supplied → square brackets; long → one line, truncated, whole on hover (IH-6). Accessibility: IH-8. Width: the 880pt sheets at Regular and Wide; the one-column form (IH-W1).

### Strings

L10n keys *(new)*, final wording from the board (D-10):

- `L10n.Sources.metadataInheritedFrom(level:)` = "From %@"
- `L10n.Sources.metadataInheritedAccessibility(level:value:)` = "Inherited from %@: %@"
- `L10n.Sources.metadataOverrides(level:value:)` = "Overrides %@: %@"
- `L10n.Sources.metadataInheritedUnknown` = "Unknown"

`%@` level is `L10n.CitationFormats.levelName(_:)`. Removed: none.

## 7. Steps

**STEP-1 — The resolver names the level**
Files: `core/database/sourcemetadata/annotation.go`, `annotation_test.go`.
Do: D-1. Update `CitationValues`'s doc comment ("Nearest is the one place the levels are walked").
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcemetadata/ -run 'TestCitationValues'` passes, T-1 included.

**STEP-2 — Board entries carry what they inherit**
Files: `core/database/sourcemetadata/sourcemetadata.go`, `sourcemetadata_test.go`.
Do: D-2, D-3, D-5.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcemetadata/` passes, T-2 – T-5 included.

**STEP-3 — The wire carries it**
Files: `api/proto/engine.proto`, generated code, `api/ffi/handlers/metadata.go`, `metadata_test.go`. Skill: `add-ffi-handler`.
Do: D-4; `./scripts/generate-proto.sh`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/ffi/...` passes, T-6 included; `git status` shows the regenerated Go and Swift files.

**STEP-4 — Swift decodes it**
Files: `macos/App/Platform/GenealogyStore.swift`, `GoStore.swift`.
Do: D-6.
Check: the app builds (`xcodebuild build` as `scripts/check-pr.sh` runs it).

**STEP-5 — The draft host keeps it**
Files: `macos/ProvenenciaTests/MetadataDraftHostTests.swift`. Skill: `add-swift-test`.
Do: D-7 (T-7, T-8). If a test fails because `set` or `clear` drops `inherited`, fix that line in `MetadataDraftHost.swift`.
Check: T-7 and T-8 pass.

**STEP-6 — A Source write refreshes the children's boards**
Files: `macos/App/Features/Sources/SourcePageContext.swift`, `macos/ProvenenciaTests/SourcePageModelTests.swift`. Skill: `add-workspace-place`.
Do: D-8.
Check: T-9 passes; `CatalogQueryRegistryTests` stays green.

**STEP-7 — The row shows it**
Files: `macos/App/Features/Sources/MetadataBoardView.swift`, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`. Skills: `add-ui-component`, `add-localized-string`.
Do: D-9, D-10; IH-1 – IH-8 from the board; § 6 Strings.
Check: the manual check (§ 10) steps 1 – 6.

**STEP-8 — Full check**
Do: `scripts/check-pr.sh`.
Check: prints `check-pr: PASS`.

**STEP-9 — Docs**
Files: `docs/source-layer-data-model.md` § 5.2 (a board entry carries the value it inherits, from `CitationValues.Nearest`), `docs/catalog-caches.md` (a Source-board write reloads `.sourceWorkspace`, D-8), `completed.md`, `deployment-plan.md` (map row), this plan (status, Landed note), `design/S15-D33-inherited-values.md` → `design/archive/`, `design/README.md`.
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-64-inherited-values.md` reports no errors.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period ("Show each Artifact and graph board row the value it inherits from its Source."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/sourcemetadata/annotation_test.go` `TestCitationValuesNearest` *(new)* | Rows at graph and Source for field f → the graph's row, level graph; Source only → Source's; none → false; graph row marked unknown with "" → that row; `Without(graph)` → the Source's | D-1 |
| T-2 | Go | `sourcemetadata_test.go` `TestListWorkspacesInherited` *(new)*, table | Census Source with Provider "Ancestry": Artifact with no Provider → `Inherited` text "Ancestry", level source; Artifact with Provider "FamilySearch" → `Value` "FamilySearch", `Inherited` "Ancestry"; graph → same as the Artifact; Source's own board → every `Inherited` nil; Source Publisher marked unknown → `Inherited.Mark.Unknown`; Provider dismissed on the Artifact → no entry; Source-only extra Column → no Column entry on the Artifact; a needed head with a Source value → `Inherited` set and `MetElsewhere` true | AC-1.1, AC-1.3 – AC-1.5, AC-1.7, D-2, D-3 |
| T-3 | Go | `sourcemetadata_test.go` `TestDraftBoardScenarios` (new row) | Draft Artifact board on that Source → Provider `Inherited` "Ancestry" | AC-1.2 |
| T-4 | Go | `sourcemetadata_test.go` `TestWorkspaceEntryOpenHref` (new rows) | Entry with no value and an inherited URL → `OpenHref()` "", `InheritedOpenHref()` the link; inherited text that is not a URL → "" | D-5, AC-1.6 |
| T-5 | Go | `sourcemetadata_test.go` `TestListWorkspacesAnnotationsScale` (extend) | Source holds `url`; each of the 120 Artifact and graph boards → its `url` entry's `Inherited` is the Source's | D-2 (at Scale) |
| T-6 | Go | `api/ffi/handlers/metadata_test.go` `TestMetadataBoardInherited` *(new)* | `GetSourceWorkspace` and `GetDraftMetadataBoard` on the T-2 world → Artifact entry Provider `inherited` {value_text "Ancestry", level "source"}; URL entry `open_href` set; unknown Publisher `mark.unknown`; Source board entries have no `inherited` | D-4, AC-1.1, AC-1.2, AC-1.4 |
| T-7 | Swift | `macos/ProvenenciaTests/MetadataDraftHostTests.swift` `setAndClearKeepTheInheritedValue` *(new)* | Suggested entry with inherited "Ancestry": set "FamilySearch" → `hasValue`, `inherited` "Ancestry"; clear → `hasValue` false, `inherited` "Ancestry", row kept, `isChanged` false | D-7, AC-2.3 |
| T-8 | Swift | `MetadataDraftHostTests.swift` `clearingAnInheritingExtraDropsIt` *(new)* | Extra entry (not suggested, opened with a value) with an inherited value: clear → row removed | D-7 |
| T-9 | Swift | `macos/ProvenenciaTests/SourcePageModelTests.swift` `sourceMetadataSaveReloadsTheWorkspace` *(new)* | Save a Source value → `store.getSourceWorkspaceCalls` up by one and the Source board's open edit of another row kept; an Artifact sheet Save → no reload | D-8, AC-2.4 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `TestListWorkspacesAnnotations`, `TestDraftBoardScenarios` (entry struct equality), `MetadataDraftHostTests`, `CatalogQueryRegistryTests`.

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
- [ ] Domain docs updated: source-layer-data-model.md § 5.2 (inherited value), catalog-caches.md (D-8)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

Use a project with a **Census** Source "1880 census, Calder County" holding Provider "Ancestry" and a URL, with at least one Artifact and one Evidence graph that hold no Provider. The app cannot mark a value unknown or supplied until S15-41, so AC-1.5 is covered by T-2 and T-6, not here.

1. Open the Source; open an Artifact's sheet. Provider reads "Ancestry", "From Source"; the Source's URL opens from the URL row (AC-1.1, AC-1.6).
2. Type "FamilySearch" in Provider, Return, Save. Reopen: Provider is "FamilySearch" with "Overrides Source: Ancestry". Open the provenance sheet of a Citation on that Artifact: the citation reads FamilySearch (AC-2.1, AC-2.2).
3. Trash Provider: the row shows "Ancestry", "From Source" again; Save; reopen: still inherited (AC-2.3).
4. Add an Artifact: Provider reads "Ancestry", "From Source" before anything is typed; Cancel (AC-1.2).
5. Open a graph's form, then Add graph: Provider inherited in both (AC-1.3).
6. On the Source's Metadata section change Provider to "Calder Archives"; open the Artifact sheet: "Calder Archives". The Source's section shows no "From" line anywhere (AC-2.4, AC-1.4).
7. Repeat step 1 with the window at 2560pt: the sheet is the same, centred (IH-W1).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| D-8's reload resets an edit on the Source's board | `resetIfChanged` compares rows; T-9 |
| An inherited value on an extra disappears on clear | D-7, as the engine reads it after Save; T-8 |
| Entry equality in Go tests changes with the new field | Extend the expected entries; do not drop the field from comparisons |

**Stop and report if:**

- `CitationValues.Resolve` no longer walks `vocabkey.NearestFirst()` itself, or a second walker over `NearestFirst()` exists at the base.
- `boardInput.above` cannot become `CitationValues` because a caller passes another `Resolver`.
- A board reply path builds `MetadataWorkspaceEntry` without `metadataEntryProto`.
- `SourcePageContext.applySavedMetadata` is not the one apply for Source-board writes, or T-9 shows `resetIfChanged` resetting an open edit after the reload.
- The board draws the inherited value in a way IH-1 – IH-8 does not describe (for example a row that cannot be typed into), or a frame needs a new kit primitive.

## 12. Open questions

- The board's composition of IH-1 – IH-8 (D-10): blocked on the S15-D33 board.

## 13. PR

**Title:** S15-64 — Boards show inherited values
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-64-inherited-values.md`.
