# S15-37 — Metadata values can be marked unknown or supplied

**Status:** Planned
**Spike / slice:** Spike 15 · Slice 4 — Formats as data
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: Go, one migration, the wire and one error message. No view can set or show a mark yet; S15-41 adds the control and S15-46 the unknown text editor)
**Board:** —
**Depends on:** S15-08 (landed [#791](https://github.com/mendahu/provenencia/pull/791)), S15-14 (landed [#868](https://github.com/mendahu/provenencia/pull/868))
**Blocks:** S15-16, S15-19, S15-38, S15-41, S15-46
**Branch:** `s15-37-metadata-value-marks`
**Version bump:** minor, 0.20.0 → **0.21.0** (if `main`'s `VERSION` is no longer 0.20.0 when you rebase, the next minor after it): a format step that old apps refuse by `user_version`, and new wire fields ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-catalog-migration`](../../../../.agents/skills/add-catalog-migration/SKILL.md), [`add-catalog-model`](../../../../.agents/skills/add-catalog-model/SKILL.md), [`add-catalog-query`](../../../../.agents/skills/add-catalog-query/SKILL.md), [`add-catalog-delete`](../../../../.agents/skills/add-catalog-delete/SKILL.md), [`add-audit-scope`](../../../../.agents/skills/add-audit-scope/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`use-catalog-session`](../../../../.agents/skills/use-catalog-session/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests), `.cursor/rules/catalog-deletes.mdc`
**Context:** working rules "A value can be marked unknown or supplied", "Metadata lives at three levels with one vocabulary", "Metadata saves with its owner's write" ([`../deployment-plan.md`](../deployment-plan.md#working-rules)); [`../evidence-explained-citation-map.md`](../evidence-explained-citation-map.md) § 6.10 "Unknown and supplied"; [`docs/citation-formats.md`](../../../citation-formats.md) (the mark's meaning in a render); [`docs/source-layer-data-model.md`](../../../source-layer-data-model.md) §§ 5.1, 5.3; S15-14's `core/valuemark` ([`S15-14-citation-format-engine.md`](S15-14-citation-format-engine.md))
**Planned:** 2026-11-17 against `main` @ `b4c77df` (compare with `origin/main` after `git fetch origin main`; a local `main` may be stale)
**Review:** [`S15-37-metadata-value-marks.review.md`](S15-37-metadata-value-marks.review.md) — Fits / Ready with changes, 2 rounds; every finding Fixed; nothing open

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

A metadata value on a Source, an Artifact or an Evidence graph can carry the two facts of [`core/valuemark`](../../../../core/valuemark/valuemark.go): **unknown** (the record does not give it; the value has no text) and **supplied** (the text is not on the record; the researcher took it from elsewhere). A metadata field gains its **unknown text**, what a marked-unknown value prints ("n.p."). The engine stores, validates, reads, copies and audits both; the wire carries them. This is the storage half of bar 11 ("a book Source with no place of publication marked unknown cites 'n.p.'").

**Why now.** S15-14 landed the pure `valuemark` type. The seed (S15-19) writes `unknown_text`, the renderer (S15-16) reads the mark, the boards' requirements (S15-38) count an unknown value as an answer, and the control (S15-41) and unknown-text editor (S15-46) write them. All of them need these columns and this wire first.

**What stays.** No view draws a mark or the unknown text. Swift sends no mark and no unknown text yet, so every save the app makes today writes a value with no mark and leaves a field's unknown text as it is (D-7, D-9). `metadatafields.Create` and `metadatafields.Upsert` do not take unknown text (S15-19 seeds it). The Source date (S15-43) and the printed page (S15-44) are not marked here. Search indexes a supplied value's text as today; an unknown value has no text to index.

## 2. User stories

**US-1.** As the engine, when a metadata value is saved with a mark, I store the mark with the value and refuse a mark `valuemark.Validate` refuses, so that every later reader (render, requirements, boards) can trust the stored pair.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | `SetMetadata` on a Source's text field `publication_place` with `value_text` "" and `mark {unknown: true}` | The reply's entry has `has_value` true, `value_text` "", `mark.unknown` true; the row's `value_text` is NULL and `is_unknown` is 1 |
| AC-1.2 | `SetMetadata` with `value_text` "Topeka" and `mark {supplied: true}` | The entry reads "Topeka" with `mark.supplied` true |
| AC-1.3 | `SetMetadata` with `value_text` "Topeka" and `mark {unknown: true}`; or `mark {unknown: true, supplied: true}`; or `value_text` "  " and `mark {supplied: true}` | Each is refused `valuemark.invalid` with params `[<field wire id>]`; nothing is written and the board is unchanged |
| AC-1.4 | An Artifact's url field `url` set with `mark {unknown: true}` and no text; then set "ancestry.com/x" with `mark {supplied: true}` | The first stores no text; the second stores the canonical URL "https://ancestry.com/x" with `is_supplied` 1, and `open_href` is that URL. An unknown url entry's `open_href` is "" |
| AC-1.5 | A value is unknown; `SetMetadata` with `value_text` "Lawrence" and no mark | The row becomes text "Lawrence" with no mark: a write without a mark is a value with no mark (D-7) |
| AC-1.6 | `SetMetadata` repeats the stored text and mark | No change is recorded (`effects` empty, no audit revision) |
| AC-1.7 | An unknown value, `ClearMetadata` on its field | The row is deleted, as for a value with text |

**US-2.** As the engine, when an owner's draft is saved or a Source is copied, the marks travel with the values.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | `UpdateArtifact` with a `MetadataDraft` holding `{field: provider, value_text: "", mark: {unknown: true}}` and `{field: url, value_text: "https://x.org/1", mark: {supplied: true}}` | The Artifact's board reads both with their marks |
| AC-2.2 | A draft that repeats a stored value with only its mark changed | One update change for that value, carrying only the mark columns that differ |
| AC-2.3 | A draft value whose mark `valuemark.Validate` refuses | The write is refused `valuemark.invalid` naming that field, before anything is written |
| AC-2.4 | Copy Source (Metadata ticked, one Artifact ticked) of a Source whose `publisher` is unknown and whose Artifact's `provider` is supplied "Ancestry" | The copy's `publisher` is unknown with no text; its Artifact's `provider` is supplied "Ancestry" |

**US-3.** As the engine, a metadata field holds its unknown text, editable through the existing field update.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `UpdateMetadataField` on a user field with `unknown_text` "  not stated " | The field reads `unknown_text` "not stated" in the reply, in `ListMetadataFields`-style reads and on every board entry's `field` |
| AC-3.2 | `UpdateMetadataField` with the `unknown_text` field absent (as today's app sends) | The stored unknown text is unchanged |
| AC-3.3 | `UpdateMetadataField` with `unknown_text` "" | The unknown text is cleared (NULL) |
| AC-3.4 | `UpdateMetadataField` with label, description and unknown text all unchanged | No change is recorded |

**US-4.** As the researcher reading the history, every change to a mark or an unknown text is in the audit, as part of the value.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | AC-1.1's set | The create change's fields hold `id`, `source_id`, `field_id`, `value_text` {nil → nil}, `is_unknown` {nil → true} and `is_supplied` {nil → false} |
| AC-4.2 | AC-1.5's set over the unknown value | The update change holds `value_text` {nil → "Lawrence"} and `is_unknown` {true → false}, and no `is_supplied` |
| AC-4.3 | Deleting the Source (or the Artifact, or the graph) that holds an unknown value | The value's delete change in the release holds `is_unknown` true and `is_supplied` false |
| AC-4.4 | AC-3.1's update | The `metadata_field` update change holds `unknown_text` {nil → "not stated"} |

## 3. Scope

| In | Covered by |
| --- | --- |
| Migration `000067.sql`: `is_unknown`, `is_supplied` with their checks on the three value tables; `unknown_text` on `source_metadata_fields` | STEP-1, AC-1.1 |
| `sourcemetadata.Row` and `Input` carry `Mark`; `Set`, `Apply`, `CreateAll`, `Clear`, reads and `ReadDraftsTx` store and return it | STEP-2, AC-1.1 – AC-1.7, AC-2.1 – AC-2.3 |
| Audit: value changes carry the mark columns; facet releases of the three value tables carry them | STEP-2, STEP-3, AC-4.1 – AC-4.3 |
| `metadatafields.Field.UnknownText`; every field read returns it; `Update` takes it, absent keeps it | STEP-4, AC-3.1 – AC-3.4, AC-4.4 |
| Copy Source carries marks (through `ReadDraftsTx` and `CreateAll`) | STEP-2 (code), STEP-5 (test), AC-2.4 |
| Proto: `ValueMark` *(new)*; `mark` on `SetMetadataRequest`, `MetadataValue`, `MetadataWorkspaceEntry`; `unknown_text` on `MetadataField`; optional `unknown_text` on `UpdateMetadataFieldRequest`; handlers | STEP-6, AC-1.1 – AC-1.4, AC-2.1, AC-3.1 – AC-3.3 |
| Swift: regenerated proto; `valuemark.invalid` in `L10n.Errors` | STEP-7 |
| Docs: `source-layer-data-model.md`, map row, `completed.md`, version | STEP-8 |

| Out | Home |
| --- | --- |
| The Unknown and Supplied control on board rows; Swift carrying a row's mark through its board model, drafts and `SetMetadata` | S15-41 |
| Editing a field's unknown text on the Metadata page | S15-46 |
| Seeding "n.p." on `publication_place` and `publisher`; `Upsert` taking unknown text | S15-19 |
| Rendering a mark ("n.p.", "[Topeka]") | S15-16 |
| An unknown value answering a needed field on the boards | S15-38, S15-39 |
| The Source date's marks | S15-43 |
| The printed page's marks | S15-44 |
| A move carrying marks | S15-24 (the move updates `source_id`; values move untouched) |
| `Create` taking unknown text (a new field gets it by an update) | not planned |
| Indexing a field's unknown text for search | not planned |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Mark type | `core/valuemark/valuemark.go` `Mark`, `Validate(m Mark, hasValue bool) error`, `ErrInvalid` (code `valuemark.invalid`, `apperr.CodeValueMarkInvalid`) | Pure; nothing in the catalog uses it yet |
| Value tables | `core/database/migrations/000009.sql` (`source_metadata`, later rebuilt by `000028.sql`), `000065.sql` (`artifact_metadata`, `evidence_graph_metadata`) | `id`, owner column, `field_id`, `value_text TEXT` (nullable). No mark columns. Latest step is `000066.sql` |
| Field table | `000028.sql` `source_metadata_fields` | `id, key, origin, label, data_type, description`. No `unknown_text` |
| Value store SQL | `core/database/sourcemetadata/owner.go` `newStore` | `insert`, `update`, `getPair`, `listIn` name `value_text` only; `stores` builds one per level |
| Value types | `core/database/sourcemetadata/sourcemetadata.go` `Row`, `Input` | `Row{ID, Owner, FieldID, ValueText}`, `Input{FieldID, ValueText}` |
| Set | same file, `Set` | `normalizeFor` → no-op when `prev.ValueText == normalized` → `insertValueTx` + `layoutAppend`, or `updateValueTx` |
| Value changes | same file, `insertValueTx`, `updateValueTx`, `deleteValueTx` | Create and delete carry `id`, owner column, `field_id`, and `value_text` when not empty; update always carries `value_text` and runs only when the text differs |
| Drafts | same file, `apply`, `CreateAll`, `Apply`, `ReadDraftsTx` | `apply` normalizes each draft value, then deletes, inserts, updates where `prev.ValueText != normalized[i]`. `ReadDraftsTx` builds `Input{FieldID, ValueText}` |
| Normalize | same file, `normalizeFor`, `normalizeValue` | Trims, refuses "" (`sourcemetadata.invalid` with the field's wire id), canonicalizes a url field through `urlshape.Canonical` |
| Scan | same file, `scanRow`, `getPairTx` | Scans `id, owner, field_id, COALESCE(value_text, '')` |
| Board | same file, `WorkspaceEntry.OpenHref`, `listWorkspaces` | Entry `Value *Row`; `OpenHref` returns "" when `urlshape.OpenHref` refuses (an empty text included) |
| Facet release | `core/database/deleteimpact/facets.go` `rowFacet(…"source_metadata"…)`, `"artifact_metadata"`, `"evidence_graph_metadata"` | Columns `id, <owner>, field_id, value_text`; `colBool` exists (`dismissed`) and records false as well as true |
| Fields | `core/database/metadatafields/metadatafields.go` `Field`, `ScanField`, `sqlLookup`, `sqlGetByID`, `sqlGetByIDsIn`, `sqlList`, `Update(tx, id, label, dataType, description string)` | Six scanned columns; `Update` diffs label and description only |
| Suggestions read | `core/database/sourcevocab/sourcevocab.go` `sqlListSuggestions`, `ListSuggestionsTx` | Selects the six field columns plus `j.sort_order` into `metadatafields.ScanField(rows, &sort)` |
| Copy Source | `core/database/sourcecopy/sourcecopy.go` `ReadDraft`, `CreateFromDraft` | Reads values through `sourcemetadata.ReadDraftTx` / `ReadDraftsTx`, writes through `sourcemetadata.CreateAll`: carries whatever `Input` holds |
| Wire | `api/proto/engine.proto` `SetMetadataRequest` (next free tag 8), `MetadataValue` (3), `MetadataWorkspaceEntry` (10), `MetadataField` (8), `UpdateMetadataFieldRequest` (7) | No mark, no unknown text |
| Handlers | `api/ffi/handlers/metadata.go` `SetMetadata`, `parseDraft`, `metadataEntryProto` | `metadataEntryProto` builds `engine.MetadataField` inline, a copy of `metadataFieldProto` without `UsedBy` |
| Field handlers | `api/ffi/handlers/source_defs.go` `UpdateMetadataField`, `metadataFieldProto` | Passes label, data type, description to `metadatafields.Update` |
| Swift errors | `macos/App/Platform/L10n.swift` `L10n.Errors` (`sourceMetadataInvalid` resource and `case "sourcemetadata.invalid"` in `message(code:params:)`); `macos/App/Resources/Localizable.xcstrings` | No entry for `valuemark.invalid`: it would read as the unknown-error message |
| Swift test | `macos/ProvenenciaTests/L10nResolutionTests.swift` `errorCodesHaveCopy` | A table of code → sentence |
| Tests | `core/database/sourcemetadata/sourcemetadata_test.go` `TestSourceMetadata`, `TestApply`, `TestCreateAll`, `TestReadDraftsTx`, `TestListWorkspaces`; `core/database/metadatafields/metadatafields_test.go` `TestCreateUpdateGetByID`, `TestUpsertLookupList`, `TestListByIDsTx`; `core/database/sourcecopy/sourcecopy_test.go` `TestCopy`; `core/database/deleteimpact/facets_test.go` `TestFacetReleaseAuditsSourceSide`; `api/ffi/handlers/metadata_test.go` `TestMetadataOwners`; `api/ffi/handlers/artifacts_test.go` (drafts on `UpdateArtifact`) | Assert value changes and boards without marks; some compare a create change's `Fields` map exactly and will gain the two mark keys |

**Precedent.** S15-08 ([#791](https://github.com/mendahu/provenencia/pull/791)) added the Artifact and graph value tables behind the same `store` and facet releases: copy its shape (one SQL string per level in `newStore`, one facet per table). `000066.sql` (S15-15) is the `ALTER TABLE … ADD COLUMN` step to copy. S15-33 ([#806](https://github.com/mendahu/provenencia/pull/806)) added `MetadataDraft` to the wire: `parseDraft` is where the mark is read. `updateLayoutTx` is the "carry only the columns that differ" update change to copy for values.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | One migration `core/database/migrations/000067.sql` *(new)*, `ALTER TABLE … ADD COLUMN` only, foreign keys on. On each of `source_metadata`, `artifact_metadata`, `evidence_graph_metadata`: `is_unknown INTEGER NOT NULL DEFAULT 0 CHECK (is_unknown IN (0, 1) AND (is_unknown = 0 OR value_text IS NULL))`, then `is_supplied INTEGER NOT NULL DEFAULT 0 CHECK (is_supplied IN (0, 1) AND NOT (is_unknown = 1 AND is_supplied = 1) AND (is_supplied = 0 OR value_text IS NOT NULL))`. On `source_metadata_fields`: `unknown_text TEXT` | Map § 6.10's DDL plus the two text rules of `valuemark.Validate`, so the table refuses what Go refuses (checked on SQLite 3.53: a column CHECK may name another column, and `ADD COLUMN` checks existing rows, which pass with the defaults). No rebuild: every existing value row has `is_unknown = 0` | A table rebuild — not needed for added columns; only the both-flags check (map) — leaves a supplied row with no text or an unknown row with text storable by a crafted write |
| D-2 | `sourcemetadata.Row` and `Input` gain `Mark valuemark.Mark`. An unknown row's `ValueText` is "" and its column NULL | Map row: "`Input` and `Row` carry a `valuemark.Mark`"; one type for every holder (rule "A value can be marked unknown or supplied") | Two bools on each struct — the rule names one type |
| D-3 | `normalizeFor(field, text string, mark valuemark.Mark) (string, error)`: trim; then `valuemark.Validate(mark, trimmed != "")`, refused as `valuemark.ErrInvalid.WithParams(<field wire id>)`; then, when `mark.Unknown`, return ""; else `normalizeValue` as today (an empty, unmarked value stays `sourcemetadata.invalid` with the field id). `Set` and `apply` call it; nothing else validates the mark | Map row: "`normalizeValue` takes the mark". The mark's rule has one owner (`valuemark`); the field id param lets S15-41 place the message on its row, as `sourcemetadata.invalid` does (`MetadataBoardModel.isRowRefusal`) | Returning `sourcemetadata.invalid` for a bad mark — the map says S15-37 sends `valuemark.invalid` over FFI; a bare `valuemark.ErrInvalid` — the row could not be found |
| D-4 | One helper decides insert, update or nothing for a value: `putValueTx(tx *sql.Tx, st *store, owner Owner, prev *Row, fieldID []byte, normalized string, mark valuemark.Mark) (Row, *rowchange.Change, error)` *(new)*. `prev == nil` inserts; equal text and mark returns `*prev` and a nil change; otherwise it updates. `Set` calls it (and runs `layoutAppend` only when it inserted); `apply`'s insert-and-update loop calls it and appends each non-nil change | A mark-only edit is an edit (AC-1.5, AC-2.2), and what counts as "unchanged" lives in one place instead of the two switches in `Set` and `apply` (review M-4) | Editing both switches — the next value rule would reach one path; comparing text only — a mark change would be dropped |
| D-5 | Value change rows come from one column map: `auditFields(st *store, r Row) map[string]any` *(new)* = `id` (`database.UUIDString`), the owner column (`UUIDString`), `field_id` (`UUIDString`), `value_text` (`database.NullString`, so nil for an unknown row), `is_unknown` and `is_supplied` (Go `bool`). Create is `rowchange.FullRow(auditFields(…))`; delete is `rowchange.DeletedRow(auditFields(prev))`; both always hold all six keys. Update holds only the columns that differ among `value_text` (`NullString` on both sides), `is_unknown`, `is_supplied`, as `updateLayoutTx` does | "The audit records them as part of the value" (map § 6.10). Every key always present matches the facet release (`rowFacet` writes every listed column, NULL as nil, `colBool` as Go `bool`), so a value deleted by `Clear` or dropped by a draft reads exactly as one deleted with its owner; T-12 pins that equality for an unknown and a supplied row (review M-1, option B). Today `value_text` is left out when empty; an unknown row is the first stored row with no text, so this is where the two shapes would first differ | One exported release in `deleteimpact` that `deleteValueTx` calls (review M-1, option A) — `Clear` deletes by owner and field and the create change needs the same map, so the map is the shared part; recording a bool only when true — differs from the facet release |
| D-6 | `core/database/deleteimpact/facets.go`: `metadataValueFacet(parent catalogmodel.Kind, table, ownerCol string) facetRelease` *(new)* returns `rowFacet(parent, table, ownerCol, table, "id", col{"id", colUUID}, col{ownerCol, colUUID}, col{"field_id", colUUID}, col{"value_text", colText}, col{"is_unknown", colBool}, col{"is_supplied", colBool})`; the three value-table entries call it. The layout facets are not touched | The release audits the row whole; a released mark would otherwise vanish (AC-4.3). The three value entries repeat one list that differs only in the owner column; one helper makes this PR's edit one edit (review M-2) | Adding two cols to each of three copies; folding the layout facets too — this PR does not change them |
| D-7 | No mark on the wire means no mark: `SetMetadataRequest.mark` absent, and a `MetadataValue` with no `mark`, are `valuemark.Mark{}`. A set or draft without a mark over a marked row clears the mark | One meaning for every write; proto3 messages default to absent. Today's app sends no mark and cannot create one, so nothing it saves today loses a mark; S15-41 sends the row's mark with every write from then on (Next adds) | "Absent keeps the stored mark" — a draft (`Apply`) makes stored values equal the draft, and a keep rule there would be a second meaning for one field |
| D-8 | Proto: `message ValueMark { bool unknown = 1; bool supplied = 2; }` *(new)*, placed after `MetadataOwner`. `SetMetadataRequest.mark = 8`, `MetadataValue.mark = 3`, `MetadataWorkspaceEntry.mark = 10` (set only when `has_value`), `MetadataField.unknown_text = 8`, `UpdateMetadataFieldRequest`: `optional string unknown_text = 7` | The rule's "the proto has one `ValueMark` message", which S15-43 and S15-44 reuse | Two bools per message — a second shape of the pair on the wire |
| D-9 | `metadatafields.Field` gains `UnknownText string`. `metadatafields.Update(tx, id, label, dataType, description string, unknownText *string)`: nil keeps the stored text; otherwise trimmed, "" stores NULL. The diff gains `unknown_text` {old → new} with `database.NullString` on both sides when it differs; an all-equal update returns no changes. `sqlUpdate` becomes one statement, `UPDATE source_metadata_fields SET label = ?, description = ?, unknown_text = ? WHERE id = ?`, binding `database.NullString(existing.UnknownText)` when the argument is nil. The handler passes `req.UnknownText` (nil when the optional field is absent). `Delete`'s change gains `unknown_text` {old → nil} when the stored text is not empty, as `description` does. The keep-on-absent rule lasts until S15-46, which sends the field on every update and turns it into a plain `string` (map scope entry S15-46) | Map row: "`metadatafields`' update write takes `unknown_text`". Absent keeps, because today's Metadata page sends `UpdateMetadataFieldRequest` without it and would otherwise erase S15-19's seeded "n.p." on every label edit (AC-3.2). Trim matches `description` | A plain string — today's app would clear it; a new RPC — the field's one update write already exists |
| D-10 | `metadatafields.ScanField` scans seven columns, then `extra`. Its SELECT list is written once: `func Columns(alias string) string` *(new)* in `metadatafields.go` returns `id, key, origin, label, data_type, COALESCE(description, ''), COALESCE(unknown_text, '')`, each column prefixed `alias.` when `alias` is not empty. `sqlLookup`, `sqlGetByID`, `sqlGetByIDsIn`, `sqlList` become package `var`s built from `Columns("")`; `sourcevocab.sqlListSuggestions` becomes a `var` built from `metadatafields.Columns("f")` plus `, j.sort_order`. In each file the `const (…)` block is split: the other constants stay `const`, the rebuilt queries move to one `var (…)` block, each with its `FROM`, `WHERE` and `ORDER BY` unchanged | One scan and one column list for every field read, so the boards, the suggestions and the Metadata list all carry it (AC-3.1), and the next field column is one edit (review M-3; precedent `observationrow.Columns` beside `observationrow.Scan`). `rg -n "ScanField\(" core api` lists only these callers at the planning base | Adding `COALESCE(unknown_text, '')` to five hand-written lists; a second scan function |
| D-11 | Handlers: a new file `api/ffi/handlers/value_mark.go` *(new)* holds `valueMarkProto(m valuemark.Mark) *engine.ValueMark` (nil for the zero mark) and `parseValueMark(m *engine.ValueMark) valuemark.Mark` (nil → zero). `SetMetadata` and `parseDraft` call `parseValueMark`; `metadataEntryProto` sets `Mark: valueMarkProto(e.Value.Mark)` when the entry has a value, and builds its `Field` with `metadataFieldProto(e.Field)` instead of its inline copy; `metadataFieldProto` sets `UnknownText` | One converter pair beside `write_effects.go`-style shared helpers: S15-43's Source date read and write call it from `sources.go`, and so will whichever PR puts the printed page's mark on the wire (S15-44 itself is Go-only). `metadataFieldProto` already exists; `e.Field.UsedBy` is 0 on board reads, so the entry's field is unchanged apart from the new `unknown_text` | Converters in `metadata.go` — S15-43 and S15-44 are in other handler files; keeping the inline `MetadataField` — a second place to add `unknown_text` |
| D-12 | Swift: `L10n.Errors.valueMarkInvalid` *(new)*, key `error.valuemark.invalid`, "A value can’t be both unknown and supplied; an unknown value has no text, and a supplied one needs text.", comment "FFI error valuemark.invalid", and `case "valuemark.invalid"` in `message(code:params:)`. No `EngineErrorCode` case | Map: "Maps S15-14's `valuemark.invalid` in `L10n.Errors`, the first PR that sends it over FFI". Nothing in the app branches on it yet; S15-41 adds the case when its row places the message | An `EngineErrorCode` case now — no caller, and `TestSwiftVocabularyMatchesGo` would need a want list change with no reader |
| D-13 | No Swift model, view or store change beyond the regenerated `engine.pb.swift` and D-12 | No view sets or shows a mark in this PR (Out → S15-41, S15-46) | Carrying the mark through `MetadataBoardModel` now — that is S15-41's control and gated by S15-D22 |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `000067.sql` *(new)* | migration | `000066.sql` | Extends the same pattern (additive `ALTER TABLE`) |
| `Row.Mark`, `Input.Mark` *(new fields)* | field | `valuemark.Mark` | Reuses the type; no new type |
| `normalizeFor`'s `mark` parameter | param | `normalizeFor` | Extends the one normalize step both writes call |
| `Field.UnknownText` *(new field)*, `Update`'s `unknownText *string` | field, param | `Field.Description`, `Update` | Extends the one field row and its one update write |
| `metadatafields.Columns(alias)` *(new)* | func | `observationrow.Columns` | Same pattern; replaces five hand-written copies |
| `putValueTx` *(new)* | func | the insert/update switches in `Set` and `apply` | Replaces both (D-4) |
| `auditFields` *(new)* | func | the hand-built maps in `insertValueTx`, `deleteValueTx` | Replaces both (D-5) |
| `metadataValueFacet` *(new)* | func | three `rowFacet(… value table …)` calls | Replaces three copies of one column list (D-6) |
| `message ValueMark` *(new)* and four wire fields | proto | `MetadataOwner` (shared sub-message) | None exists; the rule names one message |
| `api/ffi/handlers/value_mark.go` *(new)* `valueMarkProto`, `parseValueMark` | file, func | `parseOwner` in `metadata.go`; `write_effects.go` | Searched `rg -n "func .*Mark" api/ffi`: none. A shared file because S15-43's `sources.go` handlers call it too |
| `L10n.Errors.valueMarkInvalid` *(new)* | L10n key | `L10n.Errors.sourceMetadataInvalid` | Same namespace and pattern |
| Test tables T-1 – T-8 | test | the named existing tests | New cases go in the existing test functions that cover the same write; two new functions (`TestValueMarks`, `TestValueMarkChanges`) hold the mark table, `TestMetadataValueMarks` the wire |

**Builds on.** `core/valuemark` (S15-14); `sourcemetadata`'s per-level `store` (S15-08); `deleteimpact`'s `rowFacet` and `colBool`; `metadatafields.ScanField`; `writes.Run` recording returned changes (no new effect: the entity types are unchanged); `add-ffi-handler`'s handler shape.
**Deletes.** `metadataEntryProto`'s inline `engine.MetadataField{…}` literal, replaced by `metadataFieldProto(e.Field)` (D-11); the insert-or-update switches in `Set` and `apply` (D-4); the hand-built change maps in `insertValueTx` and `deleteValueTx` (D-5); the three value-table column lists in `facets.go` (D-6); the five hand-written field SELECT lists (D-10).
**Next adds.** S15-16's resolver reads `Row.Mark` from `ListByOwnersTx` and `Field.UnknownText` from `ListByIDsTx`. S15-19's `seedField` gains `UnknownText` and `Upsert` writes the column. S15-38 counts an unknown row as an answer. S15-41 reads `MetadataWorkspaceEntry.mark`, sends `SetMetadataRequest.mark` and each `MetadataValue.mark` from the row (so D-7 never clears a mark the researcher set), and adds `EngineErrorCode` `valuemark.invalid`. S15-43 calls `valueMarkProto` / `parseValueMark` from `sources.go`, as will the PR that sends the page's mark. S15-46 sends `UpdateMetadataFieldRequest.unknown_text`.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A value row with text "" and `is_unknown` 1 | Every reader of `Row.ValueText`: `WorkspaceEntry.OpenHref` (returns "" for an empty text, AC-1.4); `searchindex.go` Source projection (`COALESCE(m.value_text, '')`, indexes nothing); `deleteimpact.FillUsedBy` (counts rows, so an unknown value holds its field in use, as intended) | Swift is not reached: no app write creates one (D-7, D-13) |
| A value row with `is_supplied` 1 | Same readers; text unchanged | Indexed and shown as its text, as today |
| A field with `unknown_text` set | `metadataFieldProto`, board entries | Read only; no view shows it (S15-46) |

### Scale

At the map's Scale (a census Source with 60 graphs and 60 Artifacts; 26 types, 63 fields): no write or read adds a query. Each value read selects two more integer columns; each field read one more text column. `Set` and `apply` do the same number of statements as today. No cache key, signal or invalidation changes: the writes keep their entity types and owners, so `writes.Run`'s effects are unchanged.

### Edges

- **Assumptions.** `apply` assumes a value is "unchanged" when its text is equal (D-4 extends it to the mark). `normalizeValue` assumes a value has text (an unknown value never reaches it, D-3). `deleteValueTx` and the facet release assume they audit the whole row (D-5, D-6). Tests T-1, T-3, T-6.
- **Neighbors.** An unmarked empty value stays `sourcemetadata.invalid` (T-1 "empty, no mark"); a supplied empty value is `valuemark.invalid` (T-1). A url field: unknown skips canonicalizing; supplied canonicalizes (T-1). A suggested field whose value is unknown is a value, so `DismissSuggestion` is a no-op on it, as for text (T-1 "dismiss an unknown value").
- **Removed inputs.** Clearing an unknown value deletes its row and its mark (AC-1.7). Deleting the owner releases the row with its mark in the audit (AC-4.3). Deleting a field with an unknown value is refused in use, as for text (T-1 "field in use").
- **Real data.** None — no table, seed or configuration drives a rule here; the seed's unknown text is S15-19's.
- **Untrusted size.** None — no list, map or graph is read from data the app did not write. The schema hash refuses a catalog whose tables differ, so stored rows satisfy D-1's checks.

### Schema

Migration `core/database/migrations/000067.sql` *(new)*:

```sql
-- S15-37: a metadata value can be marked unknown or supplied
-- (core/valuemark), and a field holds what an unknown value prints (map § 6.10).
ALTER TABLE source_metadata ADD COLUMN is_unknown INTEGER NOT NULL DEFAULT 0
	CHECK (is_unknown IN (0, 1) AND (is_unknown = 0 OR value_text IS NULL));
ALTER TABLE source_metadata ADD COLUMN is_supplied INTEGER NOT NULL DEFAULT 0
	CHECK (is_supplied IN (0, 1) AND NOT (is_unknown = 1 AND is_supplied = 1)
		AND (is_supplied = 0 OR value_text IS NOT NULL));
-- the same two statements for artifact_metadata and evidence_graph_metadata
ALTER TABLE source_metadata_fields ADD COLUMN unknown_text TEXT;
```

`catalogmodel`: no change (no new table or foreign key; `TestPragmaHonesty` stays green). Delete class: unchanged (value tables are facets, D-6 adds columns to their releases). Audit: unchanged entity types; changes carry the new columns (D-5, D-9).

### Go core

| Package | Change |
| --- | --- |
| `core/database/sourcemetadata` | `Row.Mark`, `Input.Mark` *(new fields)*; `newStore`: `insert` → `(id, <owner>, field_id, value_text, is_unknown, is_supplied)`; `update` → `SET value_text = ?, is_unknown = ?, is_supplied = ? WHERE id = ?`; `getPair` and `listIn` select `is_unknown, is_supplied` after `COALESCE(value_text, '')`; `scanRow` reads them into `Mark`. `normalizeFor(field, text, mark)` (D-3). `Set`, `apply`: D-3, D-4. `putValueTx` (D-4) over `insertValueTx(tx, st, owner, fieldID, normalized string, mark valuemark.Mark)` and `updateValueTx(tx, st, prev Row, normalized string, mark valuemark.Mark)`; `auditFields` and `deleteValueTx`: D-5. `scanRow` stays the only scan that builds a `Row` (checked: `rg -n "Scan\(" core/database/sourcemetadata/sourcemetadata.go`). `ReadDraftsTx` copies `Mark` into `Input` |
| `core/database/deleteimpact` | `core/database/deleteimpact/facets.go`: D-6 |
| `core/database/metadatafields` | `Field.UnknownText`, `Columns` *(new)*, `ScanField`, the four queries, `sqlUpdate`, `Update` (D-9, D-10) |
| `core/database/sourcevocab` | `sqlListSuggestions` built from `metadatafields.Columns("f")` (D-10) |
| `core/database/sourcecopy` | No code change: marks travel through `ReadDraftTx`/`ReadDraftsTx` and `CreateAll` |

Errors: `valuemark.invalid` (params `[<field wire id>]`) → a mark `Validate` refuses, from `Set`, `Apply`, `CreateAll`. `sourcemetadata.invalid` → as today.

### FFI

`api/proto/engine.proto`: `ValueMark` *(new)* and the fields of D-8. Handlers: `api/ffi/handlers/value_mark.go` *(new)*; `metadata.go` `SetMetadata` (`Input.Mark: parseValueMark(req.GetMark())`), `parseDraft` (`Mark: parseValueMark(v.GetMark())`), `metadataEntryProto` (D-11); `source_defs.go` `UpdateMetadataField` passes `req.UnknownText` (the generated `*string` for a proto3 `optional`), `metadataFieldProto` sets `UnknownText`. No new RPC, no `ffi.Call` case. Regenerate with `./scripts/generate-proto.sh`.

### macOS

None — no view changes (D-13). `macos/App/Platform/Generated/engine.pb.swift` is regenerated; `L10n.Errors` gains one message (D-12).

### Strings

L10n keys *(new)*: `L10n.Errors.valueMarkInvalid` = "A value can’t be both unknown and supplied; an unknown value has no text, and a supplied one needs text." (`error.valuemark.invalid` in `Localizable.xcstrings`, `extractionState` `manual`, as `error.sourcemetadata.invalid`). Removed: none.

## 7. Steps

**STEP-1 — The migration**
Files: `core/database/migrations/000067.sql` *(new)*. Skills: `add-catalog-migration`, `add-catalog-model`.
Do: write D-1's DDL for the three value tables and the field table. No `-- migrate:` line.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/...` passes (schema hash, `TestPragmaHonesty`, every existing store test).

**STEP-2 — Values carry their mark**
Files: `core/database/sourcemetadata/owner.go`, `sourcemetadata.go`, `sourcemetadata_test.go`. Skills: `add-catalog-query`, `add-audit-scope`.
Do: D-2 – D-5 and `ReadDraftsTx`. Update existing tests that compare a create or delete change's `Fields` exactly to D-5's six keys; change nothing else in them. Add T-1 – T-4.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/... ./api/...` passes (other packages' tests that compare a value change's `Fields` are updated here, for the two mark keys and the always-present `value_text` only).

**STEP-3 — Released values keep their mark in the audit**
Files: `core/database/deleteimpact/facets.go`, `facets_test.go`. Skill: `add-catalog-delete`.
Do: D-6. Add T-5 and T-12.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/... ./api/...` passes.

**STEP-4 — A field holds its unknown text**
Files: `core/database/metadatafields/metadatafields.go`, `metadatafields_test.go`, `core/database/sourcevocab/sourcevocab.go`, `core/database/sourcevocab/sourcevocab_test.go`, `core/database/sourcetypes/formats_test.go` (calls `metadatafields.Update`), `api/ffi/handlers/source_defs.go` (the `metadatafields.Update` call passes `nil` in this step). Skill: `add-catalog-query`.
Do: D-9, D-10. Update every test caller of `metadatafields.Update` to pass `nil`. Add T-6.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/... ./api/...` passes.

**STEP-5 — Copy Source keeps marks**
Files: `core/database/sourcecopy/sourcecopy_test.go`.
Do: add T-7. No code change; if T-7 fails, stop (Stop conditions).
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcecopy/...` passes.

**STEP-6 — The wire**
Files: `api/proto/engine.proto`, regenerated `api/proto/engine/engine.pb.go` and `macos/App/Platform/Generated/engine.pb.swift`, `api/ffi/handlers/value_mark.go` *(new)*, `metadata.go`, `source_defs.go`, `metadata_test.go`, `artifacts_test.go`, `source_defs_test.go` (`TestUpdateMetadataField`). Skills: `add-ffi-handler`, `use-catalog-session`.
Do: D-8, D-11; `UpdateMetadataField` passes `req.UnknownText`. Run `./scripts/generate-proto.sh` (needs `protoc`, `protoc-gen-go` and `protoc-gen-swift`). Never hand-edit `engine.pb.go` or `engine.pb.swift`. Add T-8 – T-10.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/...` passes; `git diff --stat` shows both generated files changed.

**STEP-7 — The error reads in the app**
Files: `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `macos/ProvenenciaTests/L10nResolutionTests.swift`. Skills: `add-localized-string`, `add-swift-test`.
Do: D-12. Add T-11.
Check: `python3 scripts/check-localizable-xcstrings.py` passes; the Xcode test run in `scripts/check-pr.sh` passes with no Swift warning.

**STEP-8 — Docs and version**
Files: `docs/source-layer-data-model.md` (§ 5.1 `unknown_text`; § 5.3 the two columns, their checks and their meaning; § 5.5's `artifact_metadata` DDL gains the two columns, and its text says graph values have them too; § 11 rule 4 says an unknown value has no text), `docs/deployment-plan/spike-15/deployment-plan.md` (map row status), `docs/deployment-plan/spike-15/completed.md`, this plan (status, Landed note), `VERSION`, `core/version.go`, `MARKETING_VERSION` lines in `macos/Provenencia.xcodeproj/project.pbxproj`.
Do: per the Definition of done.
Check: links resolve; `scripts/check-pr.sh` prints `check-pr: PASS`.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Store whether a metadata value is unknown or supplied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/sourcemetadata/sourcemetadata_test.go` `TestValueMarks` *(new)*, table over the three levels | unknown, no text → Row `Mark{Unknown}`, `ValueText` "", column NULL, `is_unknown` 1; supplied "Topeka" → `Mark{Supplied}`; unknown "Topeka", both, supplied "  " → `errors.Is(err, valuemark.ErrInvalid)`, params `[field id]`, no row; empty, no mark → `sourcemetadata.ErrInvalid`; url unknown → no text; url supplied "ancestry.com/x" → "https://ancestry.com/x"; same text and mark again → no changes; text "Lawrence", no mark, over unknown → update; clear an unknown value → row gone; dismiss an unknown suggested value → no changes; delete the field while an unknown value holds it → `metadatafields.ErrInUse`; unknown with "   " → stored unknown, no text; supplied url "not a link" → `sourcemetadata.ErrInvalid` (today's path); a crafted `INSERT` of an unknown row with text, and of a supplied row with no text, straight through `tx.Exec` → a constraint error (D-1) | AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, AC-1.7, D-3, D-4 |
| T-2 | Go | same file, `TestValueMarkChanges` *(new)* | create unknown → six keys, `value_text` {nil → nil}, `is_unknown` {nil → true}, `is_supplied` {nil → false}; update unknown → "Lawrence" → `value_text` {nil → "Lawrence"}, `is_unknown` {true → false}, no `is_supplied`; update supplied "A" → supplied "B" → only `value_text`; update text "A" (no mark) → unknown → `value_text` {"A" → nil}, `is_unknown` {false → true}, no `is_supplied`; delete supplied "A" → `is_unknown` {false → nil}, `is_supplied` {true → nil}, `value_text` {"A" → nil} | AC-4.1, AC-4.2, D-5 |
| T-3 | Go | same file, `TestApply` (new cases) and `TestCreateAll` (new case) | draft unknown + supplied on an empty Artifact → both stored with marks; draft repeating a value with only its mark changed → one update change with only the mark columns that differ; draft with a refused mark → `valuemark.ErrInvalid` naming that field, nothing written; `CreateAll` with a supplied value → stored supplied | AC-2.1, AC-2.2, AC-2.3, D-4 |
| T-4 | Go | same file, `TestReadDraftsTx` and `TestListWorkspaces` (new cases) | an owner with an unknown and a supplied value → the draft's `Input.Mark` and the entry's `Value.Mark` match | US-2, D-2 |
| T-5 | Go | `core/database/deleteimpact/facets_test.go` `TestFacetReleaseAuditsSourceSide` (new case) | a Source with an unknown value, deleted → the `source_metadata` delete change holds `is_unknown` true, `is_supplied` false | AC-4.3, D-6 |
| T-6 | Go | `core/database/metadatafields/metadatafields_test.go` `TestCreateUpdateGetByID` (new cases) and `TestListByIDsTx` (new case) | `Update(…, ptr("  not stated "))` → `UnknownText` "not stated", change `unknown_text` {nil → "not stated"}; `Update(…, nil)` → kept; `Update(…, ptr(""))` → cleared, change {"not stated" → nil}; all equal → no changes; `Delete` of a user field with unknown text "not stated" → its change holds `unknown_text` {"not stated" → nil}; `GetByID`, `List`, `ListByIDsTx` each return `UnknownText`; and in `core/database/sourcevocab/sourcevocab_test.go` `TestAppendSuggestion`, the case "ListSuggestionsTx reads what ListSuggestions reads" sets an unknown text on the suggested field first and expects it on the suggestion | AC-3.1, AC-3.2, AC-3.3, AC-3.4, AC-4.4, D-9, D-10 |
| T-7 | Go | `core/database/sourcecopy/sourcecopy_test.go` `TestCopy` (new case) | original `publisher` unknown, Artifact `provider` supplied "Ancestry", copy with Metadata and the Artifact ticked → the copy's rows carry the same marks | AC-2.4 |
| T-8 | Go | `api/ffi/handlers/metadata_test.go` `TestMetadataValueMarks` *(new)* | `SetMetadata` unknown on a Source → entry `has_value`, `value_text` "", `mark.unknown`; supplied → `mark.supplied`; unknown with text → error code `valuemark.invalid`, params `[field id]` (`errParams`); no mark over unknown → entry `mark` nil | AC-1.1, AC-1.2, AC-1.3, AC-1.5, D-7, D-8 |
| T-9 | Go | `api/ffi/handlers/artifacts_test.go` (new case beside the existing draft cases) | `UpdateArtifact` with AC-2.1's draft → the reply's board entries carry both marks | AC-2.1, D-11 |
| T-10 | Go | `api/ffi/handlers/source_defs_test.go` `TestUpdateMetadataField` (new cases) | request with `UnknownText: proto.String("n.p.")` → reply `field.unknown_text` "n.p."; next request without it → still "n.p."; with `proto.String("")` → "" | AC-3.1, AC-3.2, AC-3.3, D-9 |
| T-12 | Go | `core/database/deleteimpact/facets_test.go` `TestMetadataValueAuditParity` *(new)*, over the three levels | per level, two owners of the same type each hold the same field with the same value (one pair unknown, one pair supplied "Topeka"); `sourcemetadata.Clear` on the first owner's value, then the second owner's delete release → the two delete changes have the same key set, and equal `value_text`, `is_unknown` and `is_supplied` diffs and equal `field_id`; `id` and the owner column hold different ids and are not compared. Artifact and graph owners come from `ownerFixture`; the Source level builds two Sources with `sources.Create` as `TestFacetReleaseAuditsSourceSide` does | D-5, D-6 |
| T-11 | Swift | `macos/ProvenenciaTests/L10nResolutionTests.swift` `errorCodesHaveCopy` (new row) | `"valuemark.invalid"` → D-12's sentence, not the unknown message | D-12 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `sourcemetadata` tests that compare change `Fields` maps exactly; `deleteimpact` release tests that compare a value table's released fields; `metadatafields` tests that call `Update`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New — n/a, no chrome
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated) — n/a, not gated
- [ ] Domain doc updated: docs/source-layer-data-model.md §§ 5.1, 5.3, 5.5, 11 (STEP-8)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

No view shows a mark, so the reviewer checks that nothing the app does today changed:

1. Open a project made before this build. It opens (the format step runs) and the Source page's Metadata section, an Artifact's sheet and a graph's form show their values as before.
2. Edit a value on the Source page, save an Artifact sheet with a changed provider, and rename a field on the Metadata page. Each saves as before.
3. Copy a Source with Metadata ticked. The copy's values read as the original's.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A Metadata page label edit erases a field's unknown text | D-9's optional field; T-10 |
| An app save clears a mark | No app write can create a mark before S15-41, which sends it (D-7, Next adds) |
| Exact `Fields` comparisons in other packages' tests break on the two new keys | STEP-2 and STEP-3 update them; only the new keys change |

**Stop and report if:**

- `protoc`, `protoc-gen-go` or `protoc-gen-swift` is missing, or `xcodebuild` cannot run (not on macOS): stop after STEP-5 and report; STEP-6 and STEP-7 run on a Mac. Never hand-write generated code.
- T-12 fails because a key's value differs in type between the two paths (check `colJSON` against `auditFields`): report the key.

- `000067.sql` is taken on `main` (another PR added a step): use the next number only if nothing else in that step touches these tables; otherwise report.
- `ADD COLUMN` with D-1's checks fails on the repo's SQLite build (`go test` shows a migrate error naming the CHECK).
- `rg -n "ScanField\(" core api` lists a caller other than `metadatafields.go` and `sourcevocab.go` (it must then be built from `Columns`).
- T-7 fails without a `sourcecopy` code change (Copy Source does not read or write through `ReadDraftsTx`/`CreateAll` as §4 says).
- A `writes.Run` effect or audit scope test fails because a value change now carries a column it does not expect (`core/database/effects`, `core/database/audit`): report the test; do not add an effect entry.
- Swift code other than `L10n.swift` fails to build against the regenerated `engine.pb.swift`.

## 12. Open questions

None.

## 13. PR

**Title:** S15-37 — Metadata values can be marked unknown or supplied
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-37-metadata-value-marks.md`.
