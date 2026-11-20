# S15-16 — Citations render through their type's formats

**Status:** Draft
**Spike / slice:** Spike 15 · Slice 4 — Formats as data
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: Go, the wire and three Swift parity enums; no view draws a rendered citation until S15-17, S15-21, S15-22 and S15-23)
**Board:** —
**Depends on:** S15-02 (landed #762), S15-08 (landed [#791](https://github.com/Jake-Robins-Studios/provenencia/pull/791)), S15-15 (landed [#871](https://github.com/Jake-Robins-Studios/provenencia/pull/871)), S15-37 (landed #879), S15-43 (landed #900), S15-44 (landed #905), S15-53 (landed #902); builds on S15-38 (landed [#910](https://github.com/Jake-Robins-Studios/provenencia/pull/910)) and reads the seed of S15-19 (landed #897)
**Blocks:** S15-17, S15-21, S15-22, S15-23
**Branch:** `s15-16-citations-render`
**Version bump:** minor, 0.27.0 → **0.28.0** (if `main`'s `VERSION` is no longer 0.27.0 when you rebase, the next minor after it): three new RPCs old clients ignore ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-catalog-query`](../../../../.agents/skills/add-catalog-query/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`use-catalog-session`](../../../../.agents/skills/use-catalog-session/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests), `.cursor/rules/catalog-queries.mdc` (table reads stay in their domain package), `.cursor/rules/ffi-handlers.mdc`, `.cursor/rules/versioning.mdc`
**Context:** working rules "One engine, in Go", "Citations render on demand, from SQL", "One render request for previews and the list entry", "Built-in placeholders are one table", "Today's line stays the fallback, in Swift", "A value can be marked unknown or supplied", "A format's fields are needed or used", "Grouping is by the rendered full citation, computed when read", "The item is a graph field" ([`../deployment-plan.md`](../deployment-plan.md#working-rules)); [`../evidence-explained-citation-map.md`](../evidence-explained-citation-map.md) §§ 6.3, 6.5, 6.6, 6.9; [`docs/citation-formats.md`](../../../citation-formats.md); the landed plans [`S15-14-citation-format-engine.md`](S15-14-citation-format-engine.md) (D-11: `Resolver`, `Value`), [`S15-15-type-stores-citation-formats.md`](S15-15-type-stores-citation-formats.md) (D-9: `StoredFormatsTx`, `ToStored`), [`S15-38-board-requirements.md`](S15-38-board-requirements.md) (D-4: `CitationValue`, `CitationDate`; D-13: `Formats.Parse`), [`S15-43-source-date-marks.md`](S15-43-source-date-marks.md) (D-3: `fillDates`), [`S15-44-page-marks.md`](S15-44-page-marks.md) (D-6: `locator.Page` settles the mark)
**Planned:** 2026-11-20 against `main` @ `ef66e21` (compare with `origin/main` after `git fetch origin main`; a local `main` may be stale)
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

The engine turns a Citation into its full and short citation from data entered once on the Source, its Artifact and its Evidence graph, and turns a Source into its source-list entry. One batch call renders the Citations a screen shows (runs, plain text and a group key each), one preview call renders one form against one target with an unsaved format and reports what is missing and what is wrong with the text, and one call lists the built-in placeholders. This is the Go half of bar 4 ("Citations read like citations") and bar 11 ("n.p.", "[12 March 1880]", "ca. 1880"); the screens that call it are S15-17, S15-21, S15-22 and S15-23.

**Why now.** Every piece it reads has landed: the engine (S15-14), stored formats (S15-15), values at three levels (S15-08), their marks (S15-37, S15-43, S15-44, S15-53), and S15-38's `CitationValue`, `CitationDate` and `Formats.Parse`, which this PR builds on so a board and a rendered citation agree on what answers. S15-38's review left the shared query counter to this PR (review M-9, X-2).

**What stays.** No view changes. `CitationLineDisplay` stays as the fallback and for its other callers (rule "Today's line stays the fallback, in Swift"). `sourcemetadata.listWorkspaces` and its `ownerValues` resolver are unchanged. Nothing is cached. No migration.

## 2. User stories

**US-1.** As the provenance sheet and the Sources section (S15-21, S15-22), I send the Citation ids I show and get back each one's full and short citation, as styled runs and plain text, and a group key, so I draw formatted citations and group a household's Citations without parsing a format.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | The seeded census type; a Source dated 1880 holding creator "Westmark", jurisdiction "Calder County, Westmark", schedule "population schedule", enumeration_district "236", piece "1047", folio "22"; its graph holding schedule_number "9", dwelling_number "112", family_number "118", line_number "14", item "Ada Robins"; its Artifact holding format "digital image", provider "Westmark Heritage", url "https://example.org/calder/1880", accessed_date "12 March 2025", citing "county film 7, item 3"; a Citation on that graph and Artifact with page label "14". `RenderCitations` for it | `full.plain` = "1880 Westmark census, Calder County, Westmark, population schedule, ED 236, piece 1047, fol. 22, p. 14, schedule 9, dwelling 112, family 118, line 14, Ada Robins; digital image, *Westmark Heritage* (https://example.org/calder/1880 : accessed 12 March 2025); citing county film 7, item 3." without the asterisks, in three runs: plain up to "digital image, ", italic "Westmark Heritage", plain from " (https…" to the end. `short.plain` = "1880 Westmark census, Calder County, Westmark, ED 236, fol. 22, p. 14, dwell. 112, fam. 118, Ada Robins." |
| AC-1.2 | AC-1.1's catalog plus a second Citation on the same graph and Artifact with page label "14", and a third with page label "15" | The first two have equal `group_key`; the third's differs |
| AC-1.3 | A Citation whose Source type has no full format (a new researcher type) | `full` has no runs and an empty `plain`; `group_key` is `citation:` and the Citation's id; the app shows today's line |
| AC-1.4 | Ids [C3, C1, C3, unknown-id] where C1 and C3 exist | Two entries, C3 then C1; the unknown id is left out without an error |
| AC-1.5 | 2,001 ids | `citations.invalid`, before any query |
| AC-1.6 | A type with full format `{source.meta.publisher}; {source.date}; p. {citation.page}.`: Source A's publisher marked unknown, date marked unknown, Citation page marked unknown; Source B's publisher "Ashby Press" supplied, date ABT 1880 supplied, Citation page label "23" supplied | A renders "n.p.; n.d.; p. unpaginated."; B renders "[Ashby Press]; [ca. 1880]; p. [23]." |

**US-2.** As the format editor and the Source page (S15-17, S15-23), I render one form against one Citation, or the list form against one Source, optionally with an unsaved format written with keys, and get back the render, what it is missing and what is wrong with the text.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | AC-1.1's Source, form `list`, no unsaved format, target the Source | `render.plain` = "Calder County, Westmark. 1880 Westmark census, population schedule."; no missing; no diagnostics |
| AC-2.2 | AC-1.1's Citation, form `full`, unsaved format `{source.meta.jurisdiction}, line {graph.meta.line_number}.` | `render.plain` = "Calder County, Westmark, line 14." |
| AC-2.3 | The same, unsaved format `{source.meta.nope}.` | `render` empty; `missing` empty; one diagnostic `full` · `unknown_field` over `nope` |
| AC-2.4 | A census Source with no jurisdiction and no Citations, form `list`, no unsaved format, target the Source | `missing` has one entry with one option: level `source`, field `jurisdiction` (with its label) |
| AC-2.5 | A Source target with form `full`; both targets set; neither set; form `fourth` | `citations.invalid` each |
| AC-2.6 | A Source id that is not in the catalog; a Citation id that is not | `sources.not_found`; `citations.invalid` |
| AC-2.7 | Unsaved format `   ` (blank) | Empty render, no missing, no diagnostics |

**US-3.** As the format editor (S15-17), I read the built-in placeholders from the engine's one table.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `ListCitationBuiltins` | Eight entries in `citationformat.Builtins()` order; `source.date` has options `year`, `full`, `date` true and unknown text "n.d."; `citation.page` has unknown text "unpaginated"; only the three `source` built-ins have `in_list_form` true |

**US-4.** As a contributor, a renamed form option, diagnostic code or built-in fails a Go test, not a Swift screen.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | `TestSwiftVocabularyMatchesGo` | Rows for `CitationOption`, `CitationDiagnosticCode` and `CitationBuiltin` pass; renaming any Go value fails its row |

## 3. Scope

| In | Covered by |
| --- | --- |
| A shared test query counter, `dbsqltest.CountingQuerier`; the effects test's private counter replaced by it | STEP-1, D-12, T-1 |
| `StoredFormatsTx`, `ListByOwnersTx`, `metadatafields.ListByIDsTx` take a `database.Querier` | STEP-1, D-11 |
| By-id reads: `citations.ListCitedTx`, `sources.GetManyTx`, `sourcetypes.GetManyTx` | STEP-2, D-3, T-2, T-3, T-4 |
| `core/database/citationrender`: the resolver over the catalog (built-ins, metadata at each level, the Source date, the page, each with its mark) | STEP-3, D-1, D-2, D-4, D-5, AC-1.1, AC-1.6 |
| The batch render: full and short per Citation, group key, order, limits | STEP-3, D-6, D-7, D-8, AC-1.2 – AC-1.5 |
| The preview render: one form, one target, an optional unsaved format, missing requirements, diagnostics | STEP-4, D-9, D-10, US-2 |
| Query count and time at 300 and 1,200 Citations | STEP-5, D-13, T-8 |
| RPCs `RenderCitations`, `RenderCitationPreview`, `ListCitationBuiltins` | STEP-6, D-14, US-1 – US-3 |
| Swift parity enums and rows for options, diagnostic codes and built-ins | STEP-7, D-15, US-4 |
| Docs: `docs/citation-formats.md` § Rendering; map row, S15-16 Check and the preview rule's target wording | STEP-8 |

| Out | Home |
| --- | --- |
| Any screen, Swift store method or `CatalogQueryKey` that calls these RPCs | S15-17 (preview, built-ins), S15-21 (batch, sheet key), S15-22 (batch), S15-23 (preview, list form) |
| Swift copy for a built-in's name (the hint "or the Source date", Insert field) | S15-39 (the board hint), S15-17 (Insert field). Moved from S15-38's Out, which named S15-16: this PR adds the parity enum the copy keys on, and no view draws one |
| Swift copy per diagnostic code | S15-17 |
| Rich-text (RTF) output and the clipboard write | S15-21 (`PVClipboardCopyState` rich payload) |
| Caching a render | not planned (rule "Citations render on demand, from SQL"; caching is a later decision if S15-21 measures it slow) |
| Rendering the list form for Citations in the batch | not planned (the list form is the Source's; S15-23 renders it through the preview call) |
| The sourcevocab golden (`core/database/sourcevocab/render_test.go`) rendering through the catalog resolver | not planned (it tests the seed's formats against a fixture resolver on purpose) |
| The page's mark in `Observation` or other citation messages | not planned (S15-44 D-7; the render reply carries the printed text) |
| Replacing `graphcache.Graph.SetQueryCounterForTest` with the shared counter | not planned (it counts the cache's own loads, not a `Querier`) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Engine | `core/citationformat/render.go` `Resolver`, `Value`, `Render`, `Rendered.Plain`, `MaxRenderedBytes` | Renders one template through a `Resolver` into merged runs, at most 64 KiB. Pure; nothing calls it over the catalog |
| Engine | `core/citationformat/requirements.go` `Requirements`, `Missing` | Derives a template's chains and the needed ones no target answers |
| Engine | `core/citationformat/builtins.go` `Builtin`, `Builtins`, `LookupBuiltin`, `ListFormAllows` | The one table of 8 built-ins with level, `Date`, `Options`, `AlwaysSet`, `UnknownText` |
| Engine | `core/citationformat/parse.go` `Target`, `FieldRef`, `DiagnosticCodes`; `form.go` `Form`, `Forms`, `Form.Valid`, `FormDiagnostic`, `OptionYear`, `OptionFull` | The vocabulary Swift mirrors; only `Form` has a parity row today |
| Stored formats | `core/database/sourcetypes/formats.go` `StoredFormatsTx(tx *sql.Tx, …)`, `Formats.Parse`, `Formats.Text`, `ToStored`, `ErrInvalid` | Batched read of the three columns keyed by `string(id)`; one parse per type; key→id storage step returning diagnostics. `StoredFormatsTx` takes `*sql.Tx` but only calls `sqlbatch.Query`, which takes a `Querier` |
| Type read | `core/database/sourcetypes/sourcetypes.go` `sqlGetByID`, `GetByIDTx`, `Type` | One type by id; no batch read |
| Values | `core/database/sourcemetadata/sourcemetadata.go` `ListByOwnersTx(tx *sql.Tx, owners)`, `Row`, `Owner`, `readByOwners(q database.Querier, …)` | One query per level, marks settled. Its body already runs on a `Querier` |
| Values | `core/database/sourcemetadata/annotation.go` `CitationValue`, `ownerValues` | `CitationValue(row, field)` is the one value a stored metadata value gives a citation; `ownerValues` is the board's resolver (one owner) |
| Fields | `core/database/metadatafields/metadatafields.go` `ListByIDsTx(tx *sql.Tx, ids)`, `Field.UnknownText` | Batched read by id; body runs `sqlbatch.Query` on the tx |
| Sources | `core/database/sources/sources.go` `sqlColumns`, `scanSource`, `fillDates(q database.Querier, …)`, `settleDate`, `CitationDate`, `GetTx`, `ErrNotFound`, `ErrInvalid` | One Source by id with its settled date; `List` reads all. No batch read by id (S15-43's plan names this PR's) |
| Citations | `core/database/citations/citations.go` `Citation`, `sqlGet`, `scanRow`, `ErrInvalid` | One Citation by id; no batch read; `graph_id` and `artifact_id` are `NOT NULL` (`core/database/migrations/000059.sql`) |
| Locator | `core/locator/depiction.go` `Page(locatorJSON) PageRef` (`ArtifactPage`, `Label`, `Mark`) | Reads the page selector with its settled mark; zero `PageRef` for a bad or pageless document |
| Batching | `core/database/sqlbatch` `Query`, `Size` (500) | Every by-id read issues one query per 500 ids |
| Query counter | `core/database/effects/path_test.go` `countingQuerier` (QueryRow only, private); `graphcache.Graph.SetQueryCounterForTest` | No shared counter for a `Querier` (S15-38 review M-9) |
| Test packages | `core/database/databasetest/budget.go` `Warm`, `WithinBudget`; `core/database/dbsql/dbsql.go` `Querier` | `databasetest` imports `effects` (via `graphcache` and `database`), so `effects`' own tests cannot import it; `dbsql` imports nothing from the catalog |
| FFI | `api/ffi/handlers/source_defs.go` `GetCitationFormats`, `citationFormatDiagnosticsProto`, `metadataFieldProto`; `api/ffi/handlers/metadata.go` `requirementProto`; `api/ffi/handlers/catalog.go` `withProjectCatalog`, `parseID`, `parseIDs`, `errInvalidID`; `api/ffi/handlers/version.go` `GetVersion` | The format read and write; the requirement option converter is inline in `requirementProto`; `GetVersion` opens no catalog |
| Wire | `api/proto/engine.proto` `METHOD_GET_DRAFT_METADATA_BOARD = 123`, `CitationFieldChoice`, `CitationFormatDiagnostic`, `CitationRequirementOption`, `MetadataField` | No render message or method |
| Dispatch | `api/ffi/dispatch.go` `MethodGetDraftMetadataBoard`, `Call` switch | One constant and one case per method |
| Parity | `api/ffi/swift_vocabulary_test.go` `TestSwiftVocabularyMatchesGo` rows "citation forms" (`swiftCitationForm`), `rawCase`, `listCase` | `listCase` matches `[a-z_]+` only, no dots |
| Swift | `macos/App/Platform/CitationForm.swift` `CitationForm` | The one citation vocabulary enum in Swift |
| Fixtures | `api/ffi/handlers/harness_test.go` `sourceFixture`, `seededSourceOfType`; `api/ffi/handlers/citations_test.go` `citationFixture`; `api/ffi/handlers/metadata_test.go` `lineLedgerSource`; `core/database/sourcemetadata/sourcemetadata_test.go` `seededWorld`; `core/database/sourcevocab/sourcevocabtest` `Install` | Seeded catalogs and Sources by RPC and in package tests |
| Seed | `core/database/sourcevocab/registry.go` census `Full`, `Short`, `List`; `core/database/sourcevocab/testdata/seed-citations.txt` | The census lines AC-1.1 and AC-2.1 expect, rendered there against a fixture resolver |

**Precedent.** S15-38 ([#910](https://github.com/Jake-Robins-Studios/provenencia/pull/910)) built the board's resolver `ownerValues` on `CitationValue`, `CitationDate` and `RequirementsTx`: copy how it keys rows by field id (`rowsByField`) and answers a key-named field with the zero `Value`; do not copy its one-owner shape (this resolver answers per Citation over three owners). `artifacts.GetMany` (`core/database/artifacts/artifacts.go`) is the by-id batch read to copy for each new `GetManyTx` (`database.UniqueBlobIDs`, `sqlbatch.Query`, map keyed by `string(id)`, missing ids absent). `sourcetypes.GetFormats` is the read-transaction shape (`c.DB()`, `db.Begin()`, deferred rollback). `autoreconciler`'s `export_test.go` `LoadQueryCount` is the shape for exposing a counted read to a test.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | **One package.** `core/database/citationrender` *(new)* owns the catalog resolver, the batch render and the preview. It reads through the owning packages' exported reads (D-3, D-11) and runs no SQL of its own | `.cursor/rules/catalog-queries.mdc`: table reads stay in their package; the render is a composition over five of them, like `sourcemetadata.listWorkspaces` over types, values and formats | The render in `citations` — it would import `sourcemetadata`, `sourcetypes` and `sources`, and `citations` is imported by more of the catalog; a resolver in `citationformat` — it is pure (S15-14) |
| D-2 | **What each built-in answers** (resolver `values.Resolve`, unexported): `source.title` → `Text` = Source title; `source.type` → `Text` = the type's `Label`; `source.date` → `sources.CitationDate(source)`; `artifact.label` → `Text` = `Cited.ArtifactLabel`; `graph.name` → `Text` = `Cited.GraphName`; `citation.page` → `Text` = `PageRef.Label`, `Mark` = `PageRef.Mark`; `citation.image` → `Text` = `strconv.Itoa(PageRef.ArtifactPage)` when it is above 0, else zero; `citation.label` → `Text` = the Citation label. A field target named by id at level `source`, `artifact` or `graph` answers `sourcemetadata.CitationValue(row, field)` from that owner's row (the Citation's Source, Artifact or graph); no row → zero; a field whose row did not load still answers with no unknown text (as `ownerValues`). A key-named field target → zero (stored formats name fields by id). For a Source target (D-9) every `artifact`, `graph` and `citation` target answers zero | One function per value source, so a board and a render agree (map scope "built on S15-38's `CitationValue`, `CitationDate`"); the page's mark comes from `locator.Page`, settled (S15-44 D-6) | Reading the page label from the locator JSON here — a second decoder beside `locator.Page` (known trap S10-32) |
| D-3 | **By-id reads, one per table owner.** `citations.ListCitedTx(q database.Querier, ids [][]byte) (map[string]Cited, error)` *(new)*: `type Cited struct { Citation; ArtifactLabel, GraphName string; SourceID []byte }` *(new)*; one query per 500 ids, `citations` `LEFT JOIN artifacts` on `artifact_id` and `LEFT JOIN evidence_graphs` on `graph_id`, columns `sqlGet`'s plus `COALESCE(a.label, '')`, `COALESCE(g.name, '')`, `g.source_id`; scanned through `scanRow` plus the three. `sources.GetManyTx(q database.Querier, ids [][]byte) (map[string]Source, error)` *(new)*: `SELECT sqlColumns FROM sources WHERE id IN (` through `sqlbatch.Query` and `scanSource`, then `fillDates` on the found Sources. `sourcetypes.GetManyTx(q database.Querier, ids [][]byte) (map[string]Type, error)` *(new)*: `sqlGetByID`'s columns with `IN (`. Each: `database.UniqueBlobIDs`, no ids → empty map and no query, missing ids absent, keyed by `string(id)` | The Citation's Source is its graph's (`g.source_id`): a Citation never leaves its graph, and a move updates graph and Artifact together (rule "A move is the whole bundle"). The join lives in `citations`, which already joins `artifacts` and `subjects` (`sqlListByArtifact`, `sqlPersonNamesByArtifact`). `GetManyTx` follows `artifacts.GetMany`'s name and shape. S15-43's plan names `sources`' by-id read as this PR's | `artifacts.GetMany` plus a new `evidencegraphs` batch read — two more queries and two more functions for two strings; the Source's title and type label joined into the Citation query — the Source-target preview needs the Source read anyway, and `fillDates` must stay in `sources` (S15-43 D-3) |
| D-4 | **The batch read plan** (`load`, unexported), per call: `ListCitedTx` (the ids) → `sources.GetManyTx` (the `SourceID`s; it runs `fillDates`) → `sourcetypes.GetManyTx` (the Sources' type ids) → `sourcetypes.StoredFormatsTx` (the same type ids) → `Formats.Parse` once per type, keeping only `FormFull` and `FormShort` templates → `metadatafields.ListByIDsTx` (every by-id field the kept templates name, `Template.Fields`) → `sourcemetadata.ListByOwnersTx` (the Sources at `source`, the `Cited.ArtifactID`s at `artifact`, the `Cited.GraphID`s at `graph`). Each list of ids is the distinct non-nil ids from the previous step. Parse diagnostics are dropped: a form that does not parse has no template | A fixed number of reads per 500 ids at each step (D-13): 9 queries when every list is under 500 and some Source is dated. The field read takes only fields a template names: no other field's unknown text can print | Reading every field (`metadatafields.List`) — grows with the vocabulary, not the formats; parsing per Citation — 600 parses where 1 per type suffices |
| D-5 | **The page, once per Citation.** `locator.Page(cited.LocatorJSON)` is called once per Citation in `load`, and the `PageRef` kept beside the `Cited` | `Page` parses JSON; the resolver asks `citation.page` and `citation.image` per form | Calling `Page` inside `Resolve` — a parse per placeholder |
| D-6 | **Batch render API.** `type Rendered struct { CitationID []byte; Full, Short citationformat.Rendered; GroupKey string }` *(new)*. `func Render(c *database.Catalog, citationIDs [][]byte) ([]Rendered, error)` *(new)* opens a read transaction (as `sourcetypes.GetFormats`) and calls `render(q database.Querier, citationIDs)` *(new, unexported)*. Order: the input order, a repeated id once (first place), an id with no Citation row left out. A Citation whose graph, Source or type row is missing, or whose type has no parsing full (short) format, gets an empty `Full` (`Short`). Every id must be 16 bytes, else `citations.ErrInvalid`. No ids → nil, no query | Rule "Citations render on demand, from SQL"; a deleted Citation between a screen's read and its render is not an error (the screen drops it) | Failing on a missing id — the sheet would fail for a Citation deleted while it opened |
| D-7 | **Group key** (`groupKey`, unexported): a Citation with a non-empty `Full` gets `"full:"` + lowercase hex SHA-256 over each run of `Full` in order, written as one byte (1 italic, 0 plain), the text's length as `binary.AppendUvarint`, then the text. A Citation with an empty `Full` gets `"citation:"` + `database.UUIDString(id)`. Citations of different Sources whose full citations render the same share a key | Rule "Grouping is by the rendered full citation": Go decides grouping and Swift only compares keys, with no special case for the fallback (each fallback Citation stands alone, as today). Hashing keeps the key at 69 bytes whatever the text; runs, not plain text, so the same words in different italics do not group | The plain text as the key — up to 64 KiB repeated on the wire and italics ignored; an empty key for the fallback — Swift would branch on it |
| D-8 | **Limits** (exported constants in `citationrender`): `MaxCitations = 2_000` ids per batch call, checked before any query; `MaxRenderedBytes = 8 << 20`, the sum of `len(Full.Plain()) + len(Short.Plain())` over the call, checked after each Citation; over either → `citations.ErrInvalid`, and rendering stops there | The map's Scale is 1,200 Citations per call; a census full note is about 350 bytes, so 1,200 Citations make about 1 MiB of text. A crafted format (repeating `{source.title}` up to 4,096 bytes) renders 64 KiB per form; without a call cap 2,000 Citations would hold 256 MiB | No cap — a crafted catalog makes one sheet open allocate 256 MiB; a new error code — `EngineErrorCode` and `L10n.Errors` copy for a case only a crafted catalog reaches; the screens show the generic failure with Try again (S16-04) |
| D-9 | **Preview API.** `type Target struct { CitationID, SourceID []byte }` *(new)*, exactly one set, 16 bytes. `type PreviewInput struct { Form citationformat.Form; Format *string; Choices []sourcetypes.FieldChoice; Target Target }` *(new)*. `type Preview struct { Rendered citationformat.Rendered; Missing []citationformat.Requirement; Fields map[string]metadatafields.Field; Diagnostics []citationformat.FormDiagnostic }` *(new)*. `func RenderPreview(c *database.Catalog, in PreviewInput) (Preview, error)` *(new)* opens one read transaction. Refusals, all `citations.ErrInvalid`: `!in.Form.Valid()`; neither or both targets; a target id not 16 bytes; a Source target with a form other than `list`. A Source target that is not in the catalog → `sources.ErrNotFound`; a Citation target that is not → `citations.ErrInvalid`. A Citation target loads through D-4 with one id; a Source target runs D-4's steps from `sources.GetManyTx` with only the Source as an owner. `Fields` holds every field the template names that loaded, keyed by `string(id)`, so the handler can describe a missing option | Rule "One render request for previews and the list entry": a form, an optional unsaved format, a target. The list form is the Source's (map § 6.10), and a Source has no Artifact, graph or page to answer a note's other levels | Several Citation ids per preview — S15-17 and S15-23 each preview one target; a full or short preview against a Source — every Artifact, graph and Citation placeholder would read as missing. The map rule's "Citation ids" became "one Citation" at planning |
| D-10 | **Which format a preview renders.** `Format == nil`: the target's type's stored text for `Form`, parsed with `citationformat.Parse`; a stored text that does not parse renders empty with no diagnostics and no missing (its diagnostics are for the type page's read, `GetCitationFormats`). `Format != nil`: `sourcetypes.ToStored(tx, Formats{<Form>: *Format}, in.Choices, "")` (other forms blank); its error (a bad choice → `sourcetypes.ErrInvalid`) is returned; with diagnostics the preview returns them only (empty render, no missing); else the stored text it returns is parsed. A blank text (`strings.TrimSpace` empty) is no template. With a template: `Rendered = citationformat.Render(tpl, values)`, `Missing = citationformat.Missing(citationformat.Requirements(tpl), values)` | `ToStored` is the one key→id step (S15-15 D-9), so a key the save would refuse is refused here with the same diagnostic; the unsaved text is checked against this form only. The missing list is the format editor's (rule "A format's fields are needed or used") | Parsing the key-named text and resolving keys here — a second copy of `ToStored`'s resolution |
| D-11 | `sourcetypes.StoredFormatsTx`, `sourcemetadata.ListByOwnersTx` and `metadatafields.ListByIDsTx` take `q database.Querier` in place of `tx *sql.Tx`, names and behavior unchanged; `ListByOwnersTx`'s `tx == nil` check becomes `q == nil` (an untyped `nil` argument still returns `ErrInvalid`) | Their bodies already run only `Query` through `sqlbatch`; a `Querier` lets the render take one and lets T-8 count it. Every caller passes a `*sql.Tx` and compiles unchanged. `datevalues.LookupManyTx` already has this shape | Copies of the three reads taking a `Querier` — near-copies; a counting SQL driver — `core/database/driver.go` registers one fixed driver, and mattn's trace needs a build tag |
| D-12 | **The shared counter.** `core/database/dbsql/dbsqltest` *(new)*: `type CountingQuerier struct { dbsql.Querier; Queries, RowQueries int }` with `Query` incrementing `Queries` and `QueryRow` incrementing `RowQueries`, and `func (c *CountingQuerier) Total() int`. `core/database/effects/path_test.go` drops `countingQuerier` and uses it, asserting `RowQueries` where it asserted `rows` | The S15-38 review left the mechanism to this PR. A package beside `dbsql` imports nothing from the catalog, so `effects`' own tests can use it (`databasetest` imports `effects`) | A counter in `databasetest` — `effects` could not use it; a counter private to `citationrender` — the third private copy |
| D-13 | **Scale check.** T-8 builds 30 census Sources, each dated, each with 2 Artifacts and 5 graphs (all linked to both Artifacts), values at all three levels, and Citations spread evenly over the graphs and Artifacts: 300 (10 per Source) and 1,200 (40 per Source). It counts `render` on a `dbsqltest.CountingQuerier` over a read transaction: **9** queries at 300 and **11** at 1,200 (only `ListCitedTx` takes 3 batches), `RowQueries` 0. Times with `databasetest.Warm` and `databasetest.WithinBudget`: **100 ms** at 300, **400 ms** at 1,200 | The map's Scale: a Person page citing 30 Sources renders up to 300 citations; a value with 1,200 records. Exact counts hold "a fixed number of queries"; the 1,200 case shows the count grows only by batches of 500, never per Citation. The budgets leave a sheet open well under half a second | Counting through the handler — the handler owns the transaction; one budget — the 1,200 case is the slow one |
| D-14 | **Wire and handlers.** Messages and methods in § FFI; handlers in `api/ffi/handlers/citation_render.go` *(new)*; `RenderCitations` and `RenderCitationPreview` run under `withProjectCatalog`; `ListCitationBuiltins` opens no catalog (as `GetVersion`) and converts `citationformat.Builtins()`. A missing option's proto is built by `citationOptionProto(level vocabkey.Level, f *metadatafields.Field, builtin string) *engine.CitationRequirementOption` *(new)*, extracted from `requirementProto`'s loop, which then calls it. A missing requirement's field option whose field is not in `Preview.Fields` is skipped; a requirement left with no option is skipped | One converter for "an option of a chain" on both board and preview replies; no domain logic in handlers (known trap Q3) | A new option message — `CitationRequirementOption` is already "one option of a chain, a field or a built-in, at a level" |
| D-15 | **Swift parity.** `macos/App/Platform/CitationFormatVocabulary.swift` *(new)* holds `enum CitationOption: String, CaseIterable, Sendable` (`case year`, `case full`, one per line), `enum CitationDiagnosticCode: String, CaseIterable, Sendable` (one `case camelName = "snake_code"` per `citationformat.DiagnosticCodes()` entry), `enum CitationBuiltin: String, CaseIterable, Sendable` (one `case sourceTitle = "source.title"` per built-in, `level.name`). `TestSwiftVocabularyMatchesGo` gains three rows; built-ins read with a new regexp `dottedListCase` = ``case \w+ = "([a-z_]+\.[a-z_]+)"`` | The map's S15-16 **Parity** line: the first PR that sends these over FFI. Each enum is the type S15-17 and S15-39 decode with; known trap "a string vocabulary that crosses the client boundary … with no parity test" | Widening `listCase` to dots — it would read more from files other rows check; the rows in S15-17 — the map puts them here |

**Rules this plan bends.** None. The map was edited at planning (2026-11-20): the S15-16 **Check** names a package test for the scale counts (the counter needs the transaction, D-13), and rule "One render request for previews and the list entry" reads "a target (one Citation, or a Source for the list form)" (D-9). The implementer edits neither.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `core/database/citationrender` *(new)* | package | `core/database/sourcemetadata` `listWorkspaces` + `ownerValues` | That is the board's read for owners; this is a per-Citation read over three owners and four other tables. It reuses `CitationValue`, `CitationDate`, `Formats.Parse` (D-1, D-2) |
| `values` *(new)* | type (resolver) | `sourcemetadata.ownerValues` | Answers one owner's level and the Source; a Citation needs its Artifact, graph, Source, built-ins and page (D-2). Both build values through `CitationValue` / `CitationDate` |
| `Render`, `render`, `Rendered`, `groupKey`, `MaxCitations`, `MaxRenderedBytes` *(new)* | func / type / const | `citationformat.Render`, `citationformat.MaxRenderedBytes` | The engine renders one template; this loads and renders a batch and caps the call (D-6 – D-8) |
| `RenderPreview`, `PreviewInput`, `Preview`, `Target` *(new)* | func / type | `sourcetypes.UpdateFormats` (`ToStored` then parse) | Reuses `ToStored` for the key→id step (D-10); renders instead of storing |
| `citations.ListCitedTx`, `citations.Cited` *(new)* | func / type | `citations.GetTx`, `sqlListByArtifact` | One by id, or by Artifact and graph; no batch by id. Reuses `sqlGet`'s columns and `scanRow` (D-3) |
| `sources.GetManyTx` *(new)* | func | `sources.getOne`, `sources.List` | One, or all; reuses `sqlColumns`, `scanSource`, `fillDates` (D-3) |
| `sourcetypes.GetManyTx` *(new)* | func | `sourcetypes.GetByIDTx` | One by id; reuses `sqlGetByID`'s columns (D-3) |
| `core/database/dbsql/dbsqltest` `CountingQuerier` *(new)* | test helper | `effects/path_test.go` `countingQuerier` | Private and QueryRow-only; replaced (D-12) |
| `citationOptionProto` *(new)* | func | the loop in `requirementProto` | Extracted, not copied (D-14) |
| `api/ffi/handlers/citation_render.go` *(new)* with `RenderCitations`, `RenderCitationPreview`, `ListCitationBuiltins`, `citationRenderProto` | FFI | `source_defs.go` `GetCitationFormats` | Format storage handlers live there; rendering is its own surface (§ FFI) |
| Proto messages and three methods *(new)* | FFI | `CitationFormatDiagnostic`, `CitationFieldChoice`, `CitationRequirementOption` | Reused in the new messages; nothing on the wire carries runs or a render |
| `macos/App/Platform/CitationFormatVocabulary.swift` *(new)* | Swift enums | `macos/App/Platform/CitationForm.swift` | One enum per Go vocabulary, as `CitationForm` (D-15) |
| `dottedListCase` *(new)* | test regexp | `listCase` | `listCase` matches no dot (D-15) |

**Builds on.** `citationformat` (`Render`, `Requirements`, `Missing`, `Builtins`), S15-38's `CitationValue`, `CitationDate` and `Formats.Parse`, S15-15's `StoredFormatsTx`, `ToStored` and `citationFormatDiagnosticsProto`, S15-07's `ListByOwnersTx`, S15-43's `fillDates`, S15-44's `locator.Page`, `sqlbatch`, `databasetest.Warm` / `WithinBudget`.
**Deletes.** `countingQuerier` in `core/database/effects/path_test.go` (D-12); the option-building loop body in `requirementProto` (replaced by `citationOptionProto`, D-14).
**Next adds.** S15-21 and S15-22 call `RenderCitations` from a store method and group by `group_key`; S15-17 calls `RenderCitationPreview` with `format` and `ListCitationBuiltins`, and maps copy per `CitationDiagnosticCode`; S15-23 calls `RenderCitationPreview` with a Source target and `list`; S15-39 keys built-in copy on `CitationBuiltin`. A ninth built-in is one row in `citationformat.builtins`, one case in D-2's `Resolve`, and one Swift case its parity row demands. Another test that counts a `Querier`'s queries uses `dbsqltest.CountingQuerier`.

### Reach

None — no new path into existing code, no new state reachable: the three RPCs are new and no view calls them; the widened signatures (D-11) keep every caller's behavior.

### Scale

At the map's Scale (a provenance sheet or Sources section of 300 Citations over 30 Sources; a value with 1,200 records): per call, D-4's reads are 9 queries while every list of ids is under 500 (1,200 Citations: 11, the Citation read in 3 batches), one `Formats.Parse` per distinct type (the seed has 26 types; a sheet usually 1 to 5), one `locator.Page` per Citation, and two `Render` calls per Citation: the census full format has 18 placeholders and 24 options, so 1,200 Citations make about 58,000 `Resolve` calls, each a map lookup. No write changes; nothing is invalidated or cached. T-8 measures D-13's budgets at 300 and 1,200 on its fixture.

### Edges

- **Assumptions.** `citationformat.Render` assumes a resolver answers every target without error; D-4 loads everything first, so `Resolve` is a lookup and a missing row answers zero. `ListByOwnersTx` assumes owners at metadata levels only; `load` passes only `source`, `artifact` and `graph` owners. `Formats.Parse` assumes stored text; a crafted stored text that does not parse leaves no template and an empty render (T-5). A Citation's Source is its graph's (D-3): T-5 crafts an Artifact of Source B under a graph of Source A and expects Source A's title, with the Artifact's own values still read.
- **Neighbors.** Two Citations that differ only in a field the format does not read share a group key; one that differs in `citation.page` does not (AC-1.2); one that differs only in `citation.label` shares it unless the format reads `{citation.label}` (T-6). A value marked unknown on a field with no unknown text answers with "" (its group drops, the chain stops): T-5. A blank value with a stored supplied mark reads unmarked (`readByOwners` settles it) and prints nothing: T-5.
- **Removed inputs.** A Citation deleted before the call is left out (AC-1.4). A Source whose date row is gone renders undated (`settleDate`); a deleted field cannot be named by a format (S15-15's delete impact); a field row missing in a crafted catalog leaves its value answering with no unknown text (D-2). A type with its full format cleared renders empty and falls back (AC-1.3).
- **Real data.** The seed's 26 types render through a fixture resolver in `core/database/sourcevocab/render_test.go`; AC-1.1 and AC-2.1 render the census through the catalog and expect the same lines as `seed-citations.txt`'s `census full` rows, so the two resolvers agree on the seed's census.
- **Untrusted size.** Ids per call: at most `MaxCitations` (2,000), checked before any query. Per Citation: two renders of at most 64 KiB each (engine). Per call: rendered text at most `MaxRenderedBytes` (8 MiB), checked after each Citation (D-8); the reply carries runs and plain text, so at most twice that on the wire. Formats: at most 4,096 bytes and one parse per type. Locator: `locator.Page` reads at most `MaxDocumentBytes`. Distinct types, fields and owners are each bounded by the Citations in the call.

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/dbsql/dbsqltest` *(new)* | `CountingQuerier` (D-12) |
| `core/database/sourcetypes` | `StoredFormatsTx(q database.Querier, typeIDs [][]byte)` (D-11); `GetManyTx(q database.Querier, ids [][]byte) (map[string]Type, error)` *(new)* (D-3) |
| `core/database/sourcemetadata` | `ListByOwnersTx(q database.Querier, owners []Owner)` (D-11) |
| `core/database/metadatafields` | `ListByIDsTx(q database.Querier, ids [][]byte)` (D-11) |
| `core/database/citations` | `Cited` *(new)*, `ListCitedTx` *(new)*, `sqlListCitedIn` *(new)* (D-3) |
| `core/database/sources` | `GetManyTx` *(new)*, `sqlGetManyIn` *(new)* (D-3) |
| `core/database/citationrender` *(new)* | `render.go`: `Rendered`, `Render`, `render`, `groupKey`, `MaxCitations`, `MaxRenderedBytes` (D-6 – D-8); `load.go`: `batch` (the loaded rows), `load`, `values` and `Resolve` (D-2, D-4, D-5); `preview.go`: `Target`, `PreviewInput`, `Preview`, `RenderPreview` (D-9, D-10); `export_test.go`: `var RenderQ = render` (D-13) |

Errors: `citations.invalid` → a bad id length, more than 2,000 ids, more than 8 MiB rendered, a bad form or target (D-8, D-9); `sources.not_found` → a preview Source that is not there; `sourcetypes.invalid` → a bad field choice (D-10).

### FFI

`api/proto/engine.proto`, regenerate with `./scripts/generate-proto.sh`:

```proto
// Method enum, after METHOD_GET_DRAFT_METADATA_BOARD = 123:
METHOD_RENDER_CITATIONS = 124;
METHOD_RENDER_CITATION_PREVIEW = 125;
METHOD_LIST_CITATION_BUILTINS = 126;

// One stretch of a rendered citation in one style.
message CitationRun {
  string text = 1;
  bool italic = 2;
}

// A format filled in: its runs (adjacent runs differ in style, none empty) and
// their text. Empty when there is no format.
message CitationRender {
  repeated CitationRun runs = 1;
  string plain = 2;
}

// Renders each Citation's full and short note. Ids not in the catalog are left
// out; a repeated id comes back once, in first place. At most 2,000 ids.
message RenderCitationsRequest {
  string project_dir = 1;
  repeated string citation_ids = 2;
}

message RenderedCitation {
  string citation_id = 1;
  CitationRender full = 2;  // empty: the type has no full format; show today's line
  CitationRender short = 3;
  // Equal keys are one citation: same rendered full note. Opaque.
  string group_key = 4;
}

message RenderCitationsResponse {
  repeated RenderedCitation citations = 1;
}

// Renders one form against one target. A Source target takes the list form
// only. format, when present, is unsaved text with fields by key.
message RenderCitationPreviewRequest {
  string project_dir = 1;
  string form = 2; // "full", "short" or "list"
  optional string format = 3;
  repeated CitationFieldChoice field_choices = 4;
  oneof target {
    string citation_id = 5;
    string source_id = 6;
  }
}

// A needed chain no option answers: its options in chain order.
message CitationMissing {
  repeated CitationRequirementOption options = 1;
}

message RenderCitationPreviewResponse {
  CitationRender render = 1;
  repeated CitationMissing missing = 2;
  // Only for an unsaved format; with any, render and missing are empty.
  repeated CitationFormatDiagnostic diagnostics = 3;
}

message ListCitationBuiltinsRequest {}

// One built-in placeholder, from citationformat's table.
message CitationBuiltin {
  string level = 1;
  string name = 2;               // bare: "date"
  bool date = 3;                 // a DateValue, written in citation terms
  repeated string options = 4;   // "year", "full"
  bool always_set = 5;
  bool in_list_form = 6;
  string unknown_text = 7;       // what it prints when marked unknown; "" for none
}

message ListCitationBuiltinsResponse {
  repeated CitationBuiltin builtins = 1;
}
```

`api/ffi/dispatch.go`: `MethodRenderCitations`, `MethodRenderCitationPreview`, `MethodListCitationBuiltins` *(new)* and their `Call` cases. Handlers in `api/ffi/handlers/citation_render.go` *(new)*: `RenderCitations` (`parseIDs` the ids, then `citationrender.Render`; each result through `citationRenderProto(citationformat.Rendered) *engine.CitationRender` *(new)*, which sets `plain` from `Rendered.Plain()`); `RenderCitationPreview` (`parseID` the set target; `format` → `PreviewInput.Format` only when the field is present; choices as `UpdateCitationFormats` parses them; reply diagnostics through `citationFormatDiagnosticsProto`, missing through `citationOptionProto`, D-14); `ListCitationBuiltins` (no catalog). `citationOptionProto` *(new)* in `api/ffi/handlers/metadata.go`, called by `requirementProto`.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Option parity | `CitationOption` *(new)* | `macos/App/Platform/CitationFormatVocabulary.swift` *(new)* | D-15; no view uses it yet |
| Diagnostic code parity | `CitationDiagnosticCode` *(new)* | same | D-15 |
| Built-in parity | `CitationBuiltin` *(new)* | same | D-15 |

States: none — no view. `macos/App/Platform/Generated/engine.pb.swift` is regenerated. The file sits in the app target's synchronized folder group (`PBXFileSystemSynchronizedRootGroup`), so the project file needs no entry.

### Strings

None — no user-facing copy. The render's words ("n.d.", "unpaginated", "ca.") are citation text from the engine, not localized ([`docs/citation-formats.md`](../../../citation-formats.md) § Dates).

## 7. Steps

**STEP-1 — Shared counter and `Querier` reads**
Files: `core/database/dbsql/dbsqltest/dbsqltest.go` *(new)*, `core/database/dbsql/dbsqltest/dbsqltest_test.go` *(new)*, `core/database/effects/path_test.go`, `core/database/sourcetypes/formats.go`, `core/database/sourcemetadata/sourcemetadata.go`, `core/database/metadatafields/metadatafields.go`. Skill: `add-catalog-query`.
Do: D-12; D-11 (signatures and doc comments only).
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/dbsql/... ./core/database/effects/ ./core/database/sourcetypes/ ./core/database/sourcemetadata/ ./core/database/metadatafields/` passes, T-1; `go vet ./...` passes.

**STEP-2 — By-id reads**
Files: `core/database/citations/citations.go`, `core/database/citations/citations_test.go`, `core/database/sources/sources.go`, `core/database/sources/sources_test.go`, `core/database/sourcetypes/sourcetypes.go`, `core/database/sourcetypes/sourcetypes_test.go`. Skill: `add-catalog-query`.
Do: D-3.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/citations/ ./core/database/sources/ ./core/database/sourcetypes/` passes, T-2, T-3, T-4.

**STEP-3 — The resolver and the batch render**
Files: `core/database/citationrender/render.go` *(new)*, `core/database/citationrender/load.go` *(new)*, `core/database/citationrender/export_test.go` *(new)*, `core/database/citationrender/render_test.go` *(new)*.
Do: D-1, D-2, D-4 – D-8. Test worlds: `database.Create`, `sourcevocabtest.Install`, a user as `sourcemetadata_test.go` `emptyWorld` makes one, and the catalog's own writes (`sources.Create`, `sources.SetDate`, `sourcemetadata.Set`, `artifactstest.Create`, `evidencegraphstest.Create`, `sourcetypes.UpdateFormats`); Citations as direct `INSERT`s, as `evidencegraphstest.ScaleSeed.Graph` writes them; direct `INSERT`s or `UPDATE`s on one transaction where a case crafts a row the writes refuse.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/citationrender/` passes, T-5, T-6, T-7.

**STEP-4 — The preview**
Files: `core/database/citationrender/preview.go` *(new)*, `core/database/citationrender/preview_test.go` *(new)*.
Do: D-9, D-10.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/citationrender/` passes, T-9.

**STEP-5 — Scale**
Files: `core/database/citationrender/scale_test.go` *(new)*.
Do: D-13. The fixture writes structure and values with direct `INSERT`s on one transaction, as `evidencegraphstest.ScaleSeed` does, and dates the 30 Sources through `sources.SetDate`.
Check: `CGO_ENABLED=1 go test -tags fts5 -run TestRenderScale -v ./core/database/citationrender/` passes and logs both times under budget, T-8.

**STEP-6 — RPCs**
Files: `api/proto/engine.proto`, generated Go and Swift (`./scripts/generate-proto.sh`), `api/ffi/dispatch.go`, `api/ffi/handlers/citation_render.go` *(new)*, `api/ffi/handlers/citation_render_test.go` *(new)*, `api/ffi/handlers/metadata.go`. Skills: `add-ffi-handler`, `use-catalog-session`.
Do: D-14, § FFI.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/...` passes, T-10, T-11, T-12. (`./scripts/generate-proto.sh` needs `protoc`, `protoc-gen-go` and `protoc-gen-swift` on PATH; run it on a Mac if this machine lacks them.)

**STEP-7 — Swift parity**
Files: `macos/App/Platform/CitationFormatVocabulary.swift` *(new)*, `api/ffi/swift_vocabulary_test.go`.
Do: D-15: the three enums; the `swiftCitationVocabulary` path constant *(new)*, `dottedListCase`, and the three rows.
Check: `CGO_ENABLED=1 go test -tags fts5 -run TestSwiftVocabularyMatchesGo ./api/ffi/` passes, T-13; `xcodebuild test` (via `scripts/check-pr.sh`, on macOS) passes with no Swift warning.

**STEP-8 — Version and docs**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj` (`MARKETING_VERSION`); `docs/citation-formats.md` (new § Rendering after § Storage: what each built-in reads (D-2), the Citation's Source is its graph's, the batch and its order and limits (D-6, D-8), the group key (D-7), the preview's target and format rules (D-9, D-10), nothing cached); `../deployment-plan.md` (map row status; the S15-16 Check and the preview rule were edited at planning); `../completed.md`; this plan.
Do: per the Definition of done.
Check: `scripts/check-pr.sh` prints `check-pr: PASS`; `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-16-citations-render.md` reports no errors.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Render a Citation's full and short citation from its type's formats."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/dbsql/dbsqltest/dbsqltest_test.go` `TestCountingQuerier` *(new)*; `core/database/effects/path_test.go` `TestReadRowsColumnLooksUpEachIDOnce` | In-memory SQLite: two `Query`, one `QueryRow` → `Queries` 2, `RowQueries` 1, `Total` 3. The effects test passes on `RowQueries` | D-12 |
| T-2 | Go | `core/database/citations/citations_test.go` `TestListCitedTx` *(new)* | Table: two Citations on one graph and Artifact → each with the Artifact label, graph name, graph's Source id; ids [a, a, missing] → one entry; nil ids → empty map, zero queries (counted); a Citation whose Artifact row is gone (FKs off, crafted) → `ArtifactLabel` "" | D-3 |
| T-3 | Go | `core/database/sources/sources_test.go` `TestGetManyTx` *(new)* | Dated Source (1880, supplied) and undated Source → both with `Date` and `DateMark` as `GetTx` returns them; missing id absent; repeated id once; nil → empty, zero queries | D-3 |
| T-4 | Go | `core/database/sourcetypes/sourcetypes_test.go` `TestGetManyTx` *(new)* | Two types → labels as `GetByIDTx`; missing absent; nil → empty, zero queries | D-3 |
| T-5 | Go | `core/database/citationrender/render_test.go` `TestRender` *(new)* | Table, one type per case with a one-line full format: `{source.title}/{source.type}/{artifact.label}/{graph.name}/{citation.label}` → the five values joined by "/"; `image {citation.image}` with `artifact_page` 37 → "image 37", with label only → "" (the placeholder prints nothing); a field marked unknown with no unknown text inside `[x {source.meta.k}]` → "" ; a blank value with a stored supplied mark (crafted) → ""; a stored full text that does not parse (crafted `UPDATE source_types`) → empty `Full`, `citation:` key; a key-named field in a stored format (crafted) → answers nothing; no short format → empty `Short`, `Full` set; an Artifact of Source B under a graph of Source A (crafted) → Source A's title and the Artifact's own `{artifact.meta.k}`; AC-1.4's order and omission; no ids → nil with zero queries; an id of 15 bytes → `citations.ErrInvalid` | D-2, D-4, D-6, AC-1.3, AC-1.4 |
| T-6 | Go | `core/database/citationrender/render_test.go` `TestGroupKey` *(new)* | Two Citations on one graph, Artifact and page label → equal keys starting `full:`; page "14" vs "15" → differ; labels "a" vs "b", format without `{citation.label}` → equal; with it → differ; two types whose full formats render the same words, one italic (`*{source.title}*` vs `{source.title}`) → differ; no full format → `citation:<uuid>` each, distinct | D-7, AC-1.2 |
| T-7 | Go | `core/database/citationrender/render_test.go` `TestRenderLimits` *(new)* | 2,001 ids → `citations.ErrInvalid` with `Total()` 0; a crafted full format of `{source.title}` repeated to 4,000 bytes and a 255-byte title, on 70 Citations → `citations.ErrInvalid` (70 × 2 × 64 KiB passes 8 MiB); the same on 60 Citations → renders | D-8, AC-1.5 |
| T-8 | Go | `core/database/citationrender/scale_test.go` `TestRenderScale` *(new)* | D-13's fixture: 300 → 300 results, `Queries` 9, `RowQueries` 0, warm time ≤ 100 ms; 1,200 → 1,200 results, `Queries` 11, warm ≤ 400 ms; every `Full.Plain()` non-empty and ends in "." | D-4, D-13 |
| T-9 | Go | `core/database/citationrender/preview_test.go` `TestRenderPreview` *(new)* | Table over AC-2.1 – AC-2.7: each input → render, missing (as `[]Target` chains), diagnostics or error as the AC; plus a chain `{graph.meta.item\|source.meta.item}` empty on both, Citation target, unsaved `{graph.meta.item\|source.meta.item}.` → one missing requirement with both targets; a field choice naming a field of another key → `sourcetypes.ErrInvalid`; `Fields` holds `jurisdiction` in AC-2.4 | D-9, D-10, AC-2.1, AC-2.2, AC-2.3, AC-2.4, AC-2.5, AC-2.6, AC-2.7 |
| T-10 | Go | `api/ffi/handlers/citation_render_test.go` `TestRenderCitations` *(new)* | AC-1.1's catalog built by RPC (`seededSourceOfType` census, `SetSourceDate` year 1880, `SetMetadata` at `source`, `graph`, `artifact`, `CreateArtifact`, `CreateCitationWithObservations` with locator `{"version":1,"selectors":[{"type":"page","page_label":"14"}]}`) → AC-1.1's runs and short text; AC-1.2's keys; AC-1.6's two Sources (a type made by `CreateSourceType` and `UpdateCitationFormats`; marks through `SetMetadata.mark`, `SetSourceDate.mark`, locator `page_unknown` / `page_supplied`); `citation_ids` ["nope"] → `errInvalidID` | AC-1.1, AC-1.2, AC-1.6 |
| T-11 | Go | `api/ffi/handlers/citation_render_test.go` `TestRenderCitationPreview` *(new)* | AC-2.1 on the T-10 Source; AC-2.3's diagnostic as `{form "full", code "unknown_field", start, end}` over `nope`; AC-2.4's missing as one `CitationMissing` with one option, level `source`, `field.key` `jurisdiction`; `format` absent vs present and blank (AC-2.7) differ: absent renders the stored list form | AC-2.1, AC-2.3, AC-2.4, AC-2.7, D-14 |
| T-12 | Go | `api/ffi/handlers/citation_render_test.go` `TestListCitationBuiltins` *(new)* | Reply equals `citationformat.Builtins()` field by field, in order (AC-3.1's values); `TestMetadataBoardRequirements` (existing, `api/ffi/handlers/metadata_test.go`) still passes after the extraction | AC-3.1, D-14 |
| T-13 | Go | `api/ffi/swift_vocabulary_test.go` `TestSwiftVocabularyMatchesGo` | Rows "citation options" (`CitationOption`, `rawCase`, want `OptionYear`, `OptionFull`), "citation diagnostic codes" (`CitationDiagnosticCode`, `listCase`, want `DiagnosticCodes()`), "citation built-ins" (`CitationBuiltin`, `dottedListCase`, want `level.name` of each `Builtins()` row), each sorted | AC-4.1, D-15 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `./core/database/sourcemetadata/` (D-11's nil check), `./api/ffi/handlers/` `TestMetadataBoardRequirements` and the board tests (D-14's extraction), `./core/database/sourcevocab/` (it calls `StoredFormatsTx`).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none: § Strings)
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left (`countingQuerier`); `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none)
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New (no UI)
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together): 0.28.0
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated): not gated
- [ ] Domain doc updated if a rule in docs/*.md changed: docs/citation-formats.md § Rendering
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

None in the app — no view calls the new RPCs; bar 4's sheet is S15-21's. The reviewer checks from the command line:

1. `CGO_ENABLED=1 go test -tags fts5 -run 'TestRenderCitations|TestRenderCitationPreview|TestListCitationBuiltins' -v ./api/ffi/handlers/` passes; the log shows AC-1.1's census line.
2. `CGO_ENABLED=1 go test -tags fts5 -run TestRenderScale -v ./core/database/citationrender/` logs the 300 and 1,200 times and their budgets.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A crafted catalog makes one call allocate hundreds of MiB | D-8's caps, T-7 |
| The board and the render disagree on what answers | Both build values through `CitationValue` and `CitationDate` (D-2); T-10 renders the seed census lines the board fixture uses |
| A per-Citation query sneaks into `load` | T-8's exact counts |
| The extracted `citationOptionProto` changes a board reply | `TestMetadataBoardRequirements` and the board handler tests stay green (T-12) |

**Stop and report if:**

- `sourcemetadata.ListByOwnersTx`, `sourcetypes.StoredFormatsTx` or `metadatafields.ListByIDsTx` calls anything on its transaction besides `Query` / `QueryRow`, so D-11's `Querier` cannot hold.
- A `citations` row's Artifact belongs to a different Source than its graph in a catalog the app wrote (not crafted): D-3's "the graph's Source" is then a choice the map must make.
- `CreateCitationWithObservations` refuses the locator `{"version":1,"selectors":[{"type":"page","page_label":"14"}]}` on an Artifact with no file, so T-10 cannot build AC-1.1 by RPC.
- T-8's counts differ from 9 and 11 with D-4's reads in place (another read issues a query D-4 does not list).
- T-8's warm 300 time is over 100 ms or its 1,200 time over 400 ms on the implementer's machine: report the numbers; do not raise the budget.
- AC-1.1 renders a line other than `seed-citations.txt`'s `census full full` row with the same values: the catalog resolver and the seed's fixture resolver disagree.

## 12. Open questions

None.

## 13. PR

**Title:** S15-16 — Citations render through their type's formats
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-16-citations-render.md`.
