# S15-15 — Source types store citation formats

**Status:** Draft
**Spike / slice:** Spike 15 · Slice 4 — Formats as data
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: Go, the wire, one delete-notice heading and one toast sentence in existing copy; the delete notice draws its groups as today, and S15-17 adds the editor; precedent S15-08, user 2026-11-11)
**Board:** —
**Depends on:** S15-14 (landed [#868](https://github.com/mendahu/provenencia/pull/868))
**Blocks:** S15-16, S15-17, S15-18, S15-20, S15-38
**Branch:** `s15-15-type-stores-citation-formats`
**Version bump:** minor, 0.17.0 → **0.18.0** (if `main`'s `VERSION` is no longer 0.17.0 when you rebase, the next minor after it): a format step that old apps refuse by `user_version`, and two new RPCs ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-catalog-migration`](../../../../.agents/skills/add-catalog-migration/SKILL.md), [`add-catalog-query`](../../../../.agents/skills/add-catalog-query/SKILL.md), [`add-catalog-delete`](../../../../.agents/skills/add-catalog-delete/SKILL.md), [`add-audit-scope`](../../../../.agents/skills/add-audit-scope/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`use-catalog-session`](../../../../.agents/skills/use-catalog-session/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests), `.cursor/rules/catalog-deletes.mdc`
**Context:** working rules "Citation formats are data on the Source type", "Formats name fields by id", "Requirements need a refresh signal; renders do not" (as amended by this plan, D-11), "Built-in placeholders are one table", "One engine, in Go" ([`../deployment-plan.md`](../deployment-plan.md#working-rules)); [`../evidence-explained-citation-map.md`](../evidence-explained-citation-map.md) § 6.3 "Storage"; [`docs/citation-formats.md`](../../../citation-formats.md); [`docs/catalog-deletes.md`](../../../catalog-deletes.md); map review K-7, K-8, K-22 ([`../deployment-plan.review.md`](../deployment-plan.review.md)); S15-14's **Landed** note ([`S15-14-citation-format-engine.md`](S15-14-citation-format-engine.md#landed))
**Planned:** 2026-11-17 against `main` @ `754d8f6` (compare with `origin/main` after `git fetch origin main`; a local `main` may be stale)
**Review:** — (not reviewed yet)

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

A Source type stores its three citation formats (full note, short note, source-list entry). The researcher writes fields by key (`{graph.meta.line_number}`); the catalog stores them by field id, so a field named by a format can never be deleted out from under it, and a key that a product field and a researcher's field share is never ambiguous once saved. The engine reads and writes the formats over two new RPCs, refuses a format with every diagnostic at its byte position, and the field delete refuses a field a format names, listing the types.

**Why now.** S15-14 landed the engine (parse, rewrite between keys and ids, the list-form rule). Rendering (S15-16), the editor (S15-17), Copy from (S15-18), the seeded formats (S15-20) and the boards' requirements (S15-38) all read the stored formats.

**What stays.** No view draws a format: the editor is S15-17. `ListSourceTypes`, `UpdateSourceType` and the `SourceType` message are unchanged. `sourcevocab.Install` writes no format (S15-20). Copy Source copies nothing new: formats belong to the type. The Swift store gains no method and no mutation (D-11).

## 2. User stories

**US-1.** As the format editor (S15-17), I save a type's three formats with fields typed by key, and read them back by key, so the researcher never sees an id.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | User type T; product field `line_number` (id L). `UpdateCitationFormats(T, full: "{source.title}[, line {graph.meta.line_number}]")` | Saved. `source_types.citation_full` holds `{source.title}[, line {graph.meta.#<L>}]` (`<L>` the canonical lowercase id). The reply and `GetCitationFormats(T)` show `full` = the text as sent; `short` and `list` are empty; no diagnostic |
| AC-1.2 | AC-1.1 saved; then field L relabelled "Line no." through `UpdateMetadataField` | `GetCitationFormats(T)` still shows `{graph.meta.line_number}` (the key; keys are immutable) |
| AC-1.3 | `UpdateCitationFormats(T, full: "")` after AC-1.1 | `citation_full` is NULL; `full` reads empty |
| AC-1.4 | `UpdateCitationFormats` with the three texts T already stores (as read) | No change recorded: `effects` has revision 0 and no lists; the stored text is byte-identical |
| AC-1.5 | A saving write | `effects.lists` = `[source_vocabulary]` and a revision; the audit change is an update of `source_type` T with the changed `citation_*` columns, old and new stored text |

**US-2.** As the editor, a format the engine cannot store is refused with every mistake at its place, and nothing is saved.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | `full: "{source.title"` | Not saved. One diagnostic: form `full`, code `unclosed_placeholder`, span 0–1. `effects` empty. The reply's `formats` are what T stores (unchanged) |
| AC-2.2 | `list: "{artifact.label}"` | Diagnostic form `list`, code `not_in_list_form`, span 1–15 (S15-14's list-form rule) |
| AC-2.3 | `short: "{source.meta.no_such_key}"`, no field has key `no_such_key` | Diagnostic form `short`, code `unknown_field`, span over `no_such_key` (13–24) |
| AC-2.4 | Product field `publisher` (id P) and user field `publisher` (id U); `full: "{source.meta.publisher}"`, no choice | Diagnostic code `ambiguous_field` over `publisher`; not saved |
| AC-2.5 | AC-2.4 with `field_choices` `[{key: "publisher", field_id: U}]` | Saved with `#<U>`; reads back `{source.meta.publisher}` with `field_choices` `[{publisher, U}]` |
| AC-2.6 | Full has a parse error and short an unknown key in one call | Both forms' diagnostics come back (parse first; key resolution runs only on forms that parsed) and nothing saves |
| AC-2.7 | `field_choices` names key `publisher` with an id whose field's key is `author`, or an id with no field | `sourcetypes.invalid`; nothing saves |
| AC-2.8 | T is plugin-origin; or T does not exist | `ErrLocked` (`sourcetypes.invalid`); missing → `sourcetypes.invalid` |
| AC-2.9 | Text `{source.meta.#<id>}` where `<id>` names no field | Diagnostic `unknown_field` over `#<id>` |

**US-3.** As a researcher, I cannot delete a field a citation format names, and the notice tells me which types name it.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | User field F named in the full format of type "Census" and the short format of type "Bible": `GetDeleteImpact(metadata_field, F)` | Not allowed, gate `inbound`; one group via `source_types.citation_formats`, kind `source_type`, total 2, listing Bible then Census (label order), each locating the type's page |
| AC-3.2 | Same F, `DeleteMetadataField` | Refused `metadata_fields.in_use` |
| AC-3.3 | F named twice in one type (full and list) | That type counts once: total 1 |
| AC-3.4 | F also holds values on 2 Sources | Groups `source_metadata.field_id` (2) and `source_types.citation_formats` (2); `metadatafields.UsedBy` = 4; `metadatafields.List` row F `UsedBy` = 4 |
| AC-3.5 | The formats naming F are cleared | Delete allowed and succeeds |
| AC-3.6 | Delete notice in the app on a field a format names | Heading "2 source types name this field in their citation formats" (one: "1 source type names this field in its citation formats") |

**US-4.** As the app, when a stored format cannot be read as written (a crafted project), I still get its text and its diagnostics.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | `citation_full` set by raw SQL to `{source.title` | `GetCitationFormats` returns `full` = the stored text verbatim and diagnostic `unclosed_placeholder` for form `full` |
| AC-4.2 | Stored `{source.meta.#<X>}` where X names no field | `full` shows `{source.meta.#<X>}` (the id token, which the write accepts) and no diagnostic |
| AC-4.3 | Stored full names product `publisher` (P) and stored short names user `publisher` (U) | `full` shows `{source.meta.publisher}`, `short` shows `{source.meta.#<U>}`, `field_choices` = `[{publisher, P}]`. Sending the reply back unchanged stores byte-identical text (AC-1.4 holds) |

## 3. Scope

| In | Covered by |
| --- | --- |
| Migration: `citation_full`, `citation_short`, `citation_list` on `source_types` | STEP-2 |
| `metadatafields.ResolveKeysTx(tx, keys, preferOrigin)` | STEP-1, T-1 |
| `citationformat`: `CodeUnknownField`, `CodeAmbiguousField`, `Template.FieldSpans` | STEP-1, T-2 |
| `sourcetypes` format read and write: keys ↔ ids, diagnostics, field choices, audit | STEP-3, STEP-4, US-1, US-2, US-4 |
| The list form rejects non-Source placeholders (through `Parse`) | STEP-4, AC-2.2 |
| Delete impact: the text-reference edge over the three columns; `UsedBy` counts it | STEP-5, US-3 |
| RPCs `GetCitationFormats`, `UpdateCitationFormats`; a format write reports `source_vocabulary` | STEP-6, AC-1.5 |
| Swift: the via heading, the toast sentence, comments naming the old scope | STEP-7, AC-3.6 |
| Docs: syntax doc, data model, delete contract, `add-catalog-delete`, map rule | STEP-8 |

| Out | Home |
| --- | --- |
| Rendering a Citation through its type's formats; the resolver over the catalog | S15-16 |
| The format editor, its Swift store method, `CatalogMutation.changedCitationFormats(typeId)` and copy per diagnostic code | S15-17 (D-11) |
| Copy from: a new type copying another's formats | S15-18 |
| Seeding formats; `Install` calling `ResolveKeysTx` with `preferOrigin` `provenencia` | S15-20 |
| Board requirements and their cache invalidation | S15-38 |
| Formats on `SourceType` / `ListSourceTypes` / `UpdateSourceType` | not planned (D-3) |
| A delete-impact count that parses formats instead of matching the id token | not planned (D-7) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Type table | `core/database/migrations/` (latest `000065.sql`, S15-08); `docs/source-layer-data-model.md` § 3 | `source_types` has `id`, `key`, `origin`, `label`, `description`, `icon_key`; no format column |
| Type package | `core/database/sourcetypes/sourcetypes.go` `Type`, `Update`, `getByIDTx`, `ErrInvalid`, `ErrLocked` | Update patches label, description, icon; returns `[]rowchange.Change` of entity `source_type`, `ActionUpdate`, `database.NullString` diffs; plugin origin → `ErrLocked` |
| Field package | `core/database/metadatafields/metadatafields.go` `lookupTx`, `ListByIDsTx`, `ScanField`, `Field`, `List` (`FillUsedBy`) | Looks a field up by (key, origin) or by ids; no lookup by key across origins. `UNIQUE (key, origin)` lets a user and a product field share a key |
| Engine | `core/citationformat/parse.go` `Parse`, `FieldRef` (`Token`, `ByID`), `Ref` (unexported `fieldSpan`), `DiagnosticCode`, `DiagnosticCodes`, `Diagnostic`, `Span`, `MaxFormatBytes`; `rewrite.go` `Template.Fields`, `RewriteFields`, `ErrFieldRef`; `doc_test.go` `TestDocMatchesEngine` | Parses (list-form rule included as `not_in_list_form`), lists distinct fields, rewrites field tokens; no exported span per field; the doc test holds `docs/citation-formats.md` § Diagnostics to `DiagnosticCodes` |
| Delete impact | `core/database/deleteimpact/register.go` `inboundEdgeList`, `joinEdge`, `withTotals`; `probes.go` `countSQLFn`, `listSQLFn`, `groupedTotalsFn`; `impact.go` `Impact`, `InboundTotals`, `FillUsedBy`; `projectors.go` `projectKind` case `KindSourceType` | Field edges are the three value tables; every edge's SQL binds the parent id as a blob. `KindSourceType` already projects a listed row (label, `SourceTypes` section, `TypeID`) |
| Effects | `core/database/effects/registry.go` entity `source_type` → `ListSourceVocabulary` | Any audited `source_type` update reports `source_vocabulary` |
| Writes | `core/writes/run.go` `Run` | No changes → no revision, empty `Result` |
| FFI | `api/proto/engine.proto` (last method `METHOD_GET_METADATA_BOARD = 119`; no `map<>` field anywhere); `api/ffi/dispatch.go`; `api/ffi/handlers/source_defs.go` `UpdateSourceType`, `sourceTypeProto`, `metadataFieldProto`; `api/ffi/handlers/write_effects.go` `writeEffectsProto` | No format RPC. `MetadataField.used_by`'s comment names Sources, Artifacts and Evidence graphs |
| Swift copy | `macos/App/Platform/L10n.swift` delete-impact via headings (`"source_metadata.field_id"` …), `SourceTypes.toastRemovedBody` / `removedBodyWithValues` (called from `SourceTypePageModel.swift` with `field.usedBy`); `macos/App/Resources/Localizable.xcstrings`; `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift` `.metadataFieldsList` comment | The toast says "the %3$lld Sources, Artifacts and graphs already carrying a value keep it"; the registry comment says `usedBy` counts Sources, Artifacts and graphs |
| Tests | `core/database/metadatafields/metadatafields_test.go` `TestDelete`, `TestListByIDsTx`; `core/database/sourcetypes/sourcetypes_test.go`; `api/ffi/handlers/source_defs_test.go` `TestDeleteMetadataField`, `TestUpdateSourceType`; `api/ffi/handlers/vocabulary_write_effects_test.go` `TestVocabularyWritesReturnEffects`; `macos/ProvenenciaTests/PVDeleteImpactTests.swift` `knownViaHeadingsMatchEngineEdges` | Cover today's field delete groups, type update, effects, via headings |

**Precedent.** S15-08 ([#791](https://github.com/mendahu/provenencia/pull/791); plan [`S15-08-artifacts-and-graphs-hold-metadata.md`](S15-08-artifacts-and-graphs-hold-metadata.md) D-5, D-17): two new field-delete edges in `inboundEdgeList`, a via heading per edge in `L10n.swift` with a row in `knownViaHeadingsMatchEngineEdges`, the toast and `used_by` comment rewritten for the new scope, no brief. Copy that shape. S15-02 ([#762](https://github.com/mendahu/provenencia/pull/762)) for new RPCs shipped Go-only with the generated Swift proto as the only Swift code diff. `sourcetypes.Update` for the audited change shape.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | Migration `000066.sql` *(new; the next free number if another landed)*: `ALTER TABLE source_types ADD COLUMN citation_full TEXT;` and the same for `citation_short`, `citation_list`. No `CHECK`, no index, no backfill. NULL means no format; the write never stores an empty string | Map § 6.3 "Storage"; a bad stored text is handled on read (AC-4.1), so a `CHECK` adds nothing; no column is a FK, so `catalogmodel` is unchanged | A `citation_formats` child table — three fixed forms, rule says columns |
| D-2 | `metadatafields.ResolveKeysTx(tx *sql.Tx, keys []string, preferOrigin string) (KeyResolution, error)` *(new)* with `type KeyResolution struct { IDs map[string][]byte; Unknown, Ambiguous []string }`. One read `SELECT id, key, origin FROM source_metadata_fields WHERE key IN (…)`, batched with `sqlbatch.Each` over the distinct keys, **each bound as a Go `string`** (SQLite never matches a BLOB to TEXT). A key held by one field → `IDs`; by several → the one of `preferOrigin` when `preferOrigin != ""` and one holds it, else `Ambiguous`; by none → `Unknown`. `Unknown` and `Ambiguous` sorted; empty input → zero value, no query | Map rule and review K-22: one key-to-id function beside `lookupTx`, shared with `Install` (S15-20 passes `provenencia`); the type write passes `""` | A lookup in `sourcetypes` (K-22); per-key `lookupTx` calls — up to ~800 keys in a crafted format |
| D-3 | Two RPCs, not fields on the type: `GetCitationFormats` (method 120) and `UpdateCitationFormats` (121) *(new)*. `ListSourceTypes`, `UpdateSourceType`, `SourceType` and `sourcetypes.Type` / `List` / `GetByID` do not change | `UpdateSourceType` requires a label and is the page's name Save; a format read carries diagnostics and choices no list row should; S15-38 and S15-17 key on a separate format read | Extending `SourceType` — every list read would parse 3 formats per type and carry diagnostics |
| D-4 | The write takes all three forms in one call and replaces all three: an empty or all-whitespace text stores NULL; any other text is parsed and stored as sent (no trim) after the field rewrite. The reply carries the three forms as read after the call | One call per Save whatever the editor's layout; the read-back round trip is lossless (AC-1.4, AC-4.3) | One RPC per form — a one-Save editor would make three non-atomic writes |
| D-5 | Ambiguity is stateless on the wire: `field_choices` (repeated `CitationFieldChoice {key, field_id}`) on both read and write. The read lists, for each shown key held by more than one field, the id the stored format uses. The write resolves each key in this order: a choice for that key (its field must exist and hold that key, else `sourcetypes.invalid`, AC-2.7); else `ResolveKeysTx(…, "")`; `Unknown` → `unknown_field`, `Ambiguous` → `ambiguous_field` at every occurrence. A choice for a key no format names is ignored. A `#<id>` token typed in the text resolves to that id when a field has it, else `unknown_field` | Map § 6.3: "The editor resolves a typed key when the format is saved and asks if two fields share it"; scope Check "resolves to the one chosen". Echoing choices on read means a resave never asks again | Keep-previous-resolution inside the write — hidden state; a `prefer_origin` on the request — one answer for every key |
| D-6 | Read rewrite (ids → keys): every by-id field of the three stored formats is shown by its key, except an id with no field and an id whose key a different id in the same type's formats already took (scanned full, short, list, in `Fields()` order); both stay as their `#<id>` token. A stored text that does not `Parse` is returned verbatim with its diagnostics and contributes no field | Lossless and total: the write accepts the id token (D-5), and no stored text makes the read fail (AC-4.1 – 4.3) | Failing the read on a bad row — the type page would not open |
| D-7 | Delete impact: one edge, via `source_types.citation_formats` (`deleteimpact.ViaCitationFormats` *(new)*), parent `KindMetadataField`, child `KindSourceType`, bucket resource, built by `citationFormatEdge()` *(new)* in `probes.go`. It matches the field's stored token `citationformat.FieldRef{ID: id}.Token()` (`#` + canonical id) as a substring: Count `SELECT COUNT(*) FROM source_types WHERE instr(COALESCE(citation_full,''),?)>0 OR instr(COALESCE(citation_short,''),?)>0 OR instr(COALESCE(citation_list,''),?)>0`; List `SELECT id, key FROM source_types` with the same `WHERE`, `ORDER BY label COLLATE NOCASE, key LIMIT ?`; Totals reads `SELECT citation_full, citation_short, citation_list FROM source_types WHERE` any is non-NULL once and counts, per id, the rows whose text contains its token (`strings.Contains`). A type counts once however many times it names the field. Registered in `inboundEdgeList` after the three value edges | Map: a field named in any format is in use and its delete is refused, listing the types. A token inside a literal (crafted) over-refuses, the safe direction. `FillUsedBy` then counts types, as K-8 requires ("the number a list shows is the number that blocks its delete") | Parsing every format per probe; three edges, one per column (a type would count up to three times) |
| D-8 | `citationformat` gains `CodeUnknownField = "unknown_field"` and `CodeAmbiguousField = "ambiguous_field"`, appended to `DiagnosticCodes()`, and `func (t *Template) FieldSpans(f FieldRef) []Span` *(new)*: the `fieldSpan` of each option naming `f`, in text order; nil for a nil template or a field it does not name. `Parse` never emits the two codes; the storage write does. The doc table gets their rows | One code list for S15-17's copy; spans point at the key only, as `bad_field` does | Codes private to `sourcetypes` — a second list for the editor to map |
| D-9 | Go layout: `core/database/sourcetypes/formats.go` *(new)*: `type Formats struct{ Full, Short, List string }`; `type FieldChoice struct{ Key string; FieldID []byte }`; `type FormDiagnostic struct{ Form citationformat.Form; citationformat.Diagnostic }`; `type FormatsView struct{ Formats; Choices []FieldChoice; Diagnostics []FormDiagnostic }`; `func GetFormats(c *database.Catalog, typeID []byte) (FormatsView, error)` (read transaction, like `List`); `func UpdateFormats(tx *database.Tx, typeID []byte, in Formats, choices []FieldChoice) (FormatsView, []rowchange.Change, error)`. With any diagnostic `UpdateFormats` returns the view of what is stored, plus the diagnostics, and nil changes, so `writes.Run` records nothing | The type package owns its columns (`add-catalog-query`); nil changes is today's "no change" path in `Run` | A new `citationformats` DB package — the columns are the type's |
| D-10 | Audit: a saving write returns one `source_type` `ActionUpdate` change whose `Fields` hold only the changed columns `citation_full` / `citation_short` / `citation_list`, `Old`/`New` the stored text via `database.NullString`. Effects come from the existing `source_type` registry row (`ListSourceVocabulary`); no effects change | Map § 6.3: "Editing them is a Source type edit, audited as one today" | — |
| D-11 | Swift: only the generated proto, the via heading, the toast sentence and comments. The Swift store method and `CatalogMutation.changedCitationFormats(typeId)` move to S15-17, the first Swift caller; S15-38 still adds its invalidation. The working rule and both scope entries are updated (STEP-8) | User, 2026-11-17: a mutation nothing applies is dead until S15-17 | Adding them here with no caller |
| D-12 | Strings (no brief, as S15-08 D-17): via heading `"source_types.citation_formats"` = `deleteImpact.via.sourceTypesCitationFormats`, plural: one "%lld source type names this field in its citation formats", other "%lld source types name this field in their citation formats". `sourceTypes.toast.removedBodyWithValues` becomes "%1$@ is no longer suggested %2$@. The field stays in this project’s vocabulary, and the %3$lld Sources, Artifacts, graphs and Source types that use it keep it." (key unchanged); its comment and `removedBodyNoValues`' comment name Source types too | `usedBy` now counts types naming the field (D-7); the toast quotes that count | Keeping the old sentence — wrong once a format names the field |
| D-13 | Errors: missing type (read or write), a bad `field_choices` entry, a malformed id → `sourcetypes.ErrInvalid`; plugin type on write → `sourcetypes.ErrLocked`. A refused format is a reply with diagnostics, not an error | Diagnostics carry positions an `apperr` cannot | An `apperr` per diagnostic |

**Rules this plan bends.** The working rule "Requirements need a refresh signal; renders do not" says S15-15's format write reports `.changedCitationFormats(typeId)` → D-11 moves it to S15-17, the first Swift writer → user, 2026-11-17: "Move it to S15-17" → STEP-8 updates the rule and the S15-15 and S15-17 scope entries.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `000066.sql` | migration | `000065.sql` | New step; shipped steps are never edited |
| `metadatafields.ResolveKeysTx`, `KeyResolution` | func, type | `lookupTx` (one key, one origin), `ListByIDsTx` (by id) | Neither looks a key up across origins; this is the map's named function |
| `citationformat.CodeUnknownField`, `CodeAmbiguousField` | const | `DiagnosticCodes()` | Extends the one list |
| `citationformat.Template.FieldSpans` | method | `Ref.fieldSpan` (unexported), `Template.Fields` | Exposes the span `RewriteFields` already uses; no new scan |
| `core/database/sourcetypes/formats.go` *(new)*: `Formats`, `FieldChoice`, `FormDiagnostic`, `FormatsView`, `GetFormats`, `UpdateFormats` | file, types, funcs | `sourcetypes.Update`, `getByIDTx` | `Update`'s contract is the label Save (D-3); same package, same change shape |
| `deleteimpact.citationFormatEdge`, `ViaCitationFormats` | func, const | `joinEdge`, `withTotals`, `ViaLastMember` | `joinEdge` binds the id blob; this edge binds the text token three times |
| RPCs `GetCitationFormats`, `UpdateCitationFormats`; messages `CitationFormats`, `CitationFieldChoice`, `CitationFormatDiagnostic` | FFI | `UpdateSourceType` | D-3 |
| Handlers in `api/ffi/handlers/source_defs.go` | func | `UpdateSourceType`, `sourceTypeProto` | Same file as the type RPCs |
| `deleteImpact.via.sourceTypesCitationFormats` | L10n key | the via headings dictionary | One entry per via |

**Builds on.** `citationformat.Parse` / `Fields` / `RewriteFields` (S15-14); `sqlbatch.Each`; `writes.Run`; the `source_type` effects row; `inboundEdgeList` and `FillUsedBy`; `projectKind`'s `KindSourceType` case; the via-heading dictionary.
**Deletes.** None — nothing becomes dead. The toast sentence and three comments are rewritten, not removed.
**Next adds.** S15-16 reads the stored id-keyed text directly (no key rewrite) and parses it once per type. S15-17 calls the two RPCs, adds the store method and `.changedCitationFormats(typeId)`, maps copy per code including `unknown_field` and `ambiguous_field`, and asks with `field_choices`. S15-18 copies the three columns as stored. S15-20 calls `ResolveKeysTx(tx, keys, vocabkey.OriginProvenencia)` and `RewriteFields` from `Install`. S15-38 calls `GetFormats` (or a batched variant it adds) for requirements.

### Reach

| New path or state | Destination | Checked |
| --- | --- | --- |
| A field delete notice with a `source_type` group | `DeleteImpact` recipe; `projectKind` `KindSourceType` | Existing projector locates the type's page (`TypeID`); an unknown via still renders, and this one gets a heading (D-12) |
| `usedBy` > 0 for a field with no values | Metadata page count, type page toast (`SourceTypePageModel.swift` `toastRemovedBody`) | Count now includes types; toast copy covers them (D-12) |
| A type whose stored format no longer parses | `GetCitationFormats` | Returned verbatim with diagnostics (AC-4.1) |

### Scale

At the map's Scale (26 types, 63 fields, a format or field edit on a type used by 500 Sources):

- `UpdateCitationFormats`: one type read, three parses (≤ 4 KiB each), one batched key read (one statement up to 500 distinct keys), one `ListByIDsTx` for typed ids, one `UPDATE`, then the reply's read (one `ListByIDsTx`, one `ResolveKeysTx`). It reports `source_vocabulary`, which today's keys follow: the types list (26 rows), the fields list (63 rows) and each cached type-suggestion key; the 500 Sources are not touched. No Swift caller exists until S15-17.
- `metadatafields.List`: the new edge's Totals is one statement over the types that have a format, plus `strings.Contains` of 63 tokens over at most 78 texts.
- `GetDeleteImpact(metadata_field)`: one `instr` scan of `source_types` for Count and one for List.

### Edges

- **Assumptions.** `RewriteFields` calls `to` once per distinct `FieldRef`, so a key and a `#id` naming the same field are two refs; both resolve to the same id and store the same token (T-3 case "key and id of one field"). Field keys are immutable (`metadatafields.Update`), so the stored id always reads back as the key it was saved from.
- **Neighbors.** A key held by one user field only → resolves with no choice. A key held by a user and a plugin field → ambiguous (origin does not decide, D-5). A choice for a key not in the text → ignored. An empty `list` with a set `full` → `list` NULL.
- **Removed inputs.** A field deleted between the editor's read and its save: the save reports `unknown_field` at the key. A field that a format names cannot be deleted (D-7), so a stored id loses its field only in a crafted project (AC-4.2).
- **Real data.** No seeded format exists until S15-20; the probe is exercised against formats written in tests.
- **Untrusted size.** A stored text is bounded by `Parse` (`MaxFormatBytes`) before any rewrite; one that fails is returned as is, not scanned again. Keys per format are bounded by its bytes (≤ ~270); the key read is batched (`sqlbatch.Size`). The Totals scan reads each stored text once and runs one `strings.Contains` per (id, text). `field_choices` comes from the app's own request and is read into one map.

### Schema

Migration `core/database/migrations/000066.sql` *(new)*:

```sql
-- S15-15: a Source type's three citation formats (map § 6.3 "Storage"),
-- fields named by id (docs/citation-formats.md).
ALTER TABLE source_types ADD COLUMN citation_full TEXT;
ALTER TABLE source_types ADD COLUMN citation_short TEXT;
ALTER TABLE source_types ADD COLUMN citation_list TEXT;
```

`catalogmodel`: unchanged (no FK). Delete class: the columns are the type's own; deleting a type drops them. Audit: D-10.

### Go core

| Package | Change |
| --- | --- |
| `core/citationformat` | D-8: two codes, `FieldSpans` |
| `core/database/metadatafields` | D-2: `ResolveKeysTx`, `KeyResolution` |
| `core/database/sourcetypes` | D-9 `formats.go`; SQL `sqlFormats = SELECT citation_full, citation_short, citation_list FROM source_types WHERE id = ?` and `sqlUpdateFormats = UPDATE source_types SET citation_full = ?, citation_short = ?, citation_list = ? WHERE id = ?` |
| `core/database/deleteimpact` | D-7 edge and via constant |

```go
// sourcetypes, signatures only
type Formats struct{ Full, Short, List string }
type FieldChoice struct{ Key string; FieldID []byte }
type FormDiagnostic struct {
	Form citationformat.Form
	citationformat.Diagnostic
}
type FormatsView struct {
	Formats
	Choices     []FieldChoice    // sorted by key
	Diagnostics []FormDiagnostic // full, short, list; each form's sorted by position
}
func GetFormats(c *database.Catalog, typeID []byte) (FormatsView, error)
func UpdateFormats(tx *database.Tx, typeID []byte, in Formats, choices []FieldChoice) (FormatsView, []rowchange.Change, error)
```

`UpdateFormats` order: type exists (`ErrInvalid`) and is not plugin (`ErrLocked`); validate choices (D-5; `ErrInvalid`); parse each non-blank form; if any parse diagnostic, return the stored view plus diagnostics; resolve keys and typed ids across the parsed forms; if any `unknown_field` / `ambiguous_field`, return likewise; rewrite to ids; compare with the stored columns; nothing changed → stored view, nil changes; else `UPDATE`, the D-10 change, and the view read back in the same tx.

Errors: `sourcetypes.invalid` (D-13).

### FFI

`api/proto/engine.proto`:

```proto
METHOD_GET_CITATION_FORMATS = 120;
METHOD_UPDATE_CITATION_FORMATS = 121;

// A Source type's citation formats as the editor shows them: fields by key.
// An empty form has no format.
message CitationFormats {
  string type_id = 1;
  string full = 2;
  string short = 3;
  string list = 4;
  // For each shown key that more than one field holds, the field the stored
  // format uses. Send them back on update so the save does not ask again.
  repeated CitationFieldChoice field_choices = 5;
}
message CitationFieldChoice {
  string key = 1;
  string field_id = 2;
}
// One mistake in a form; start and end are UTF-8 byte offsets in that form's text.
message CitationFormatDiagnostic {
  string form = 1;  // "full", "short" or "list"
  string code = 2;  // citationformat.DiagnosticCodes
  int32 start = 3;
  int32 end = 4;
}
message GetCitationFormatsRequest { string project_dir = 1; string type_id = 2; }
message GetCitationFormatsResponse {
  CitationFormats formats = 1;
  repeated CitationFormatDiagnostic diagnostics = 2;
}
// Replaces all three forms. With any diagnostic nothing is saved and effects is empty.
message UpdateCitationFormatsRequest {
  string project_dir = 1;
  string user_id = 2;
  string type_id = 3;
  string full = 4;
  string short = 5;
  string list = 6;
  repeated CitationFieldChoice field_choices = 7;
}
message UpdateCitationFormatsResponse {
  CitationFormats formats = 1;
  repeated CitationFormatDiagnostic diagnostics = 2;
  WriteEffects effects = 3;
}
```

`MetadataField.used_by` comment: "How many Sources, Artifacts and Evidence graphs hold a value for this field, plus how many Source types name it in a citation format (the delete-impact total). Deleting is only allowed at 0."

Handlers `GetCitationFormats`, `UpdateCitationFormats` *(new)* in `api/ffi/handlers/source_defs.go`, through `withProjectCatalog`; the write through `writes.Run(c, writes.Op{Action: "update_citation_formats"}, …)` and `parseUserID` as `UpdateSourceType`. Dispatch constants `MethodGetCitationFormats`, `MethodUpdateCitationFormats` in `api/ffi/dispatch.go`. Regenerate with `./scripts/generate-proto.sh`.

### macOS

None — no view changes (D-11). Generated `macos/App/Platform/Generated/engine.pb.swift` only, plus Strings below and the `.metadataFieldsList` comment in `CatalogQueryRegistry.swift` ("`usedBy` counts Sources, Artifacts and Evidence graphs holding a value for the field and Source types naming it in a citation format; a format write reports `source_vocabulary`, which this key follows").

### Strings

D-12. Old-scope copy rewritten: `sourceTypes.toast.removedBodyWithValues` (text and comment), `sourceTypes.toast.removedBodyNoValues` (comment only), proto `MetadataField.used_by` comment, `CatalogQueryRegistry` comment. New: `deleteImpact.via.sourceTypesCitationFormats` with plural variations in `Localizable.xcstrings`, as `deleteImpact.via.sourcesSourceTypeId` is.

## 7. Steps

**STEP-1 — Engine codes, field spans and the key resolver**
Files: `core/citationformat/parse.go`, `core/citationformat/rewrite.go`, `docs/citation-formats.md` (§ Diagnostics rows), `core/citationformat/rewrite_test.go`, `core/database/metadatafields/metadatafields.go`, `core/database/metadatafields/metadatafields_test.go`. Skill: `add-catalog-query`.
Do: D-8 and D-2. The two doc rows say "Reported by a type's format write, not `Parse`" with span "The field".
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/citationformat/ ./core/database/metadatafields/` passes, including `TestDocMatchesEngine`, T-1, T-2.

**STEP-2 — Migration**
Files: `core/database/migrations/000066.sql` *(new)*. Skill: `add-catalog-migration`.
Do: D-1. No migration test.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/...` passes (schema hash, `TestPragmaHonesty`).

**STEP-3 — Format read**
Files: `core/database/sourcetypes/formats.go` *(new)*, `core/database/sourcetypes/formats_test.go` *(new)*. Skill: `add-catalog-query`.
Do: types of D-9, `GetFormats` and its unexported tx form used by `UpdateFormats`, D-6.
Check: T-4 passes.

**STEP-4 — Format write**
Files: `core/database/sourcetypes/formats.go` *(new)*, `core/database/sourcetypes/formats_test.go` *(new)*. Skills: `add-catalog-query`, `add-audit-scope`.
Do: `UpdateFormats` per D-4, D-5, D-9, D-10, D-13.
Check: T-3 passes.

**STEP-5 — Delete impact**
Files: `core/database/deleteimpact/probes.go`, `register.go`, `core/database/metadatafields/metadatafields_test.go` (`TestDelete` cases). Skill: `add-catalog-delete`.
Do: D-7. `Field.UsedBy`'s doc comment names Source types too.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/deleteimpact/ ./core/database/metadatafields/` passes, T-5.

**STEP-6 — RPCs**
Files: `api/proto/engine.proto`, generated Go and Swift (`./scripts/generate-proto.sh`), `api/ffi/dispatch.go`, `api/ffi/handlers/source_defs.go`, `api/ffi/handlers/source_defs_test.go`, `api/ffi/handlers/vocabulary_write_effects_test.go`. Skills: `add-ffi-handler`, `use-catalog-session`.
Do: § FFI.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/...` passes, T-6, T-7.

**STEP-7 — Swift copy**
Files: `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift` (comment), `macos/ProvenenciaTests/PVDeleteImpactTests.swift`. Skills: `add-localized-string`, `add-swift-test`.
Do: D-12; a row in `knownViaHeadingsMatchEngineEdges`.
Check: `xcodebuild test` (via `scripts/check-pr.sh`) passes with T-8 and no Swift warning.

**STEP-8 — Version and docs**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj` (`MARKETING_VERSION`); `docs/citation-formats.md` (new § Storage: three columns, ids on disk, keys on the wire, `field_choices`, D-6); `docs/source-layer-data-model.md` § 3 (the DDL, which today lacks `icon_key`, gains `icon_key TEXT NOT NULL` and the three columns; one sentence points at § Storage); `docs/catalog-deletes.md` rule 7 (append: "A registered text reference, `source_types.citation_formats`, also holds a row: `Impact` refuses though a raw `DELETE` would succeed."); `.agents/skills/add-catalog-delete/SKILL.md` (a "Text references" paragraph: an edge with no FK that matches a token in text columns, with its own Count, List and Totals, over-refusal accepted; and a checklist line); `../deployment-plan.md` (rule "Requirements need a refresh signal" names S15-17 for the mutation; S15-15 scope entry: "the format read and write RPCs (`GetCitationFormats`, `UpdateCitationFormats`)", Cache-signal line removed; S15-17 scope entry gains "the store method and `.changedCitationFormats(typeId)`"; map row status); `../completed.md`; this plan.
Do: per the Definition of done.
Check: `scripts/check-pr.sh` prints `check-pr: PASS`; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Store a Source type's citation formats with fields named by id."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/metadatafields/metadatafields_test.go` `TestResolveKeysTx` *(new)* | Table: one user key → `IDs`; product+user key with `""` → `Ambiguous`; same with `provenencia` → product id; same with `plugin:x` (neither) → `Ambiguous`; missing key → `Unknown`; a key repeated → one entry; nil keys → zero value | D-2, AC-2.3, AC-2.4 |
| T-2 | Go | `core/citationformat/rewrite_test.go` `TestFieldSpans` *(new)* | `{source.meta.a} {graph.meta.a\|source.meta.b}`: `a` → [13–14, 28–29]; `b` → one span; `c` → nil; nil template → nil. `TestDocMatchesEngine` passes with the new rows | D-8 |
| T-3 | Go | `core/database/sourcetypes/formats_test.go` `TestUpdateFormats` *(new)* | Table, each case on a fresh catalog: AC-1.1 (raw `SELECT` shows `#<id>`), AC-1.3, AC-1.4 (nil changes), AC-1.5 (change fields), AC-2.1, AC-2.2, AC-2.3, AC-2.4, AC-2.5, AC-2.6, AC-2.7, AC-2.8, AC-2.9; "key and id of one field" → one stored token | US-1, US-2, D-4, D-5, D-10, D-13 |
| T-4 | Go | `formats_test.go` `TestGetFormats` *(new)* | AC-1.2 (relabel), AC-4.1 (raw-SQL text), AC-4.2, AC-4.3 (and its resave is byte-identical), no format → three empty forms, missing type → `ErrInvalid` | US-1, US-4, D-6 |
| T-5 | Go | `core/database/metadatafields/metadatafields_test.go` `TestDelete` *(cases added)* | AC-3.1 (group, order, `Listed[i].Location.TypeID`), AC-3.2, AC-3.3, AC-3.4 (`UsedBy` and `List` equal 4: Totals and Count agree), AC-3.5 | US-3, D-7 |
| T-6 | Go | `api/ffi/handlers/source_defs_test.go` `TestCitationFormats` *(new)* | `runRPC` table: update then get round trip (AC-1.1); refused update → diagnostics with form, code, start, end and no effects (AC-2.1); bad `type_id` → `sourcetypes.invalid`; missing `user_id` → error as `UpdateSourceType`; `DeleteMetadataField` of a field a format names → `metadata_fields.in_use` | AC-1.1, AC-2.1, AC-3.2, D-13 |
| T-7 | Go | `api/ffi/handlers/vocabulary_write_effects_test.go` `TestVocabularyWritesReturnEffects` *(case added)* | `UpdateCitationFormats` saving → `[source_vocabulary]` and a revision | AC-1.5 |
| T-8 | Swift | `macos/ProvenenciaTests/PVDeleteImpactTests.swift` `knownViaHeadingsMatchEngineEdges` *(row added)* | `("source_types.citation_formats", "source_type", 2, "2 source types name this field in their citation formats")` and the count-1 form | AC-3.6, D-12 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `core/database/deleteimpact` pragma and projector tests, `TestDocMatchesEngine`, `MetadataModelTests`, `TestSourceDefs`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New — n/a, no brief
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status, the rule and S15-15 / S15-17 scope entries (STEP-8); completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated — n/a, no brief
- [ ] Domain docs updated: docs/citation-formats.md (§ Storage, codes), docs/source-layer-data-model.md § 3, docs/catalog-deletes.md rule 7, add-catalog-delete
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

No view saves a format yet, so the check is at the engine and in the delete notice.

1. Run `CGO_ENABLED=1 go test -tags fts5 -run 'TestUpdateFormats|TestGetFormats|TestCitationFormats' -v ./core/database/sourcetypes/ ./api/ffi/handlers/` and read the case names against AC-1.1 – AC-4.3.
2. In a copy of a dogfood project (quit the app first), open the copy in the app and add a user field "Line number" on the Metadata page; quit. Run:
   `sqlite3 <copy>/provenencia.sqlite "UPDATE source_types SET citation_full = (SELECT '{graph.meta.#' || lower(substr(hex(id),1,8)||'-'||substr(hex(id),9,4)||'-'||substr(hex(id),13,4)||'-'||substr(hex(id),17,4)||'-'||substr(hex(id),21)) || '}' FROM source_metadata_fields WHERE key = 'line-number' AND origin = 'user') WHERE key = 'birth_certificate'"`
   Open the copy, go to Metadata, select "Line number". Its count is 1. Press Delete: the notice reads "1 source type names this field in its citation formats" and lists Birth certificate; activating the row opens that type's page.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A key bound as `[]byte` matches nothing (BLOB ≠ TEXT) | D-2 binds strings; T-1 fails on it |
| `FillUsedBy` counts change other screens' numbers | Only fields a format names change; no format exists before S15-17 / S15-20 |
| The toast copy reads oddly for a type-only use | D-12 wording covers "use", not "value" |
| Byte spans differ from Swift's string indices | Documented on the proto message; S15-17 converts |

**Stop and report if:**

- `citationformat.RewriteFields` does not call `to` exactly once per distinct `FieldRef`, or a `#<id>` token does not parse as a field (S15-14 contract changed).
- `writes.Run` records a revision for nil changes (AC-1.4, AC-2.x would leave an empty audit row).
- `TestResourceAndOwnedHonesty` or a `catalogmodel` test refuses an inbound edge whose via is not a registered FK.
- `deleteimpact` cannot import `core/citationformat` without an import cycle (`go list -deps` shows `citationformat` importing a database package).
- A migration other than yours took `000066`, and the next number is not free on rebase.
- `projectKind`'s `KindSourceType` case no longer sets `TypeID`.

## 12. Open questions

None.

## 13. PR

**Title:** S15-15 — Source types store citation formats
**Body:** objective in one sentence; what shipped against each US; AC evidence (test names); deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-15-type-stores-citation-formats.md`.
