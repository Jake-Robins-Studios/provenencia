# S15-16 — Citations render through their type's formats

**Status:** Planned
**Spike / slice:** Spike 15 · Slice 4 — Formats as data
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: Go, the wire and three Swift parity enums; no view draws a rendered citation until S15-17, S15-21, S15-22 and S15-23)
**Board:** —
**Depends on:** S15-02 (landed #762), S15-08 (landed [#791](https://github.com/Jake-Robins-Studios/provenencia/pull/791)), S15-15 (landed [#871](https://github.com/Jake-Robins-Studios/provenencia/pull/871)), S15-37 (landed #879), S15-43 (landed #900), S15-44 (landed #905), S15-53 (landed #902); builds on S15-38 (landed [#910](https://github.com/Jake-Robins-Studios/provenencia/pull/910)) and reads the seed of S15-19 (landed #897)
**Blocks:** S15-17, S15-21, S15-22, S15-23
**Branch:** `s15-16-citations-render`
**Version bump:** minor, 0.27.0 → **0.28.0** (if `main`'s `VERSION` is no longer 0.27.0 when you rebase, the next minor after it): three new RPCs old clients ignore ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-catalog-query`](../../../../.agents/skills/add-catalog-query/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`use-catalog-session`](../../../../.agents/skills/use-catalog-session/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests), `.cursor/rules/catalog-queries.mdc` (table reads stay in their domain package; a page read takes the caller's `*graphcache.PageInputs`), `.cursor/rules/ffi-handlers.mdc`, `.cursor/rules/macos-client.mdc` (vocabulary enums in `Platform/`), `.cursor/rules/versioning.mdc`
**Context:** working rules "One engine, in Go", "Citations render on demand, from SQL", "One render request for previews and the list entry", "Built-in placeholders are one table", "Today's line stays the fallback, in Swift", "A value can be marked unknown or supplied", "A format's fields are needed or used", "Grouping is by the rendered full citation, computed when read", "The item is a graph field" ([`../deployment-plan.md`](../deployment-plan.md#working-rules)); [`../evidence-explained-citation-map.md`](../evidence-explained-citation-map.md) §§ 6.3, 6.5, 6.6, 6.9; [`docs/citation-formats.md`](../../../citation-formats.md); the landed plans [`S15-14-citation-format-engine.md`](S15-14-citation-format-engine.md) (D-11: `Resolver`, `Value`), [`S15-15-type-stores-citation-formats.md`](S15-15-type-stores-citation-formats.md) (D-9: `StoredFormatsTx`, `ToStored`), [`S15-38-board-requirements.md`](S15-38-board-requirements.md) (D-4: `CitationValue`, `CitationDate`, `ownerValues`; D-13: `Formats.Parse`), [`S15-43-source-date-marks.md`](S15-43-source-date-marks.md) (D-3: `fillDates`), [`S15-44-page-marks.md`](S15-44-page-marks.md) (D-6: `locator.Page` settles the mark)
**Planned:** 2026-11-20 against `main` @ `ef66e21` (compare with `origin/main` after `git fetch origin main`; a local `main` may be stale)
**Review:** [`S15-16-citations-render.review.md`](S15-16-citations-render.review.md) — Fits with changes / Ready with changes, 2 rounds; every finding Fixed or Logged; nothing open

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

The engine turns a Citation into its full and short citation from data entered once on the Source, its Artifact and its Evidence graph, and turns a Source into its source-list entry. One batch call renders the Citations a screen shows (runs, plain text and a group key each, plus the inputs it read), one preview call renders one form against one target with an unsaved format and reports what is missing and what is wrong with the text, and one call lists the built-in placeholders. This is the Go half of bar 4 ("Citations read like citations") and bar 11 ("n.p.", "[12 March 1880]", "ca. 1880"); the screens that call it are S15-17, S15-21, S15-22 and S15-23.

**Why now.** Every piece it reads has landed: the engine (S15-14), stored formats (S15-15), values at three levels (S15-08), their marks (S15-37, S15-43, S15-44, S15-53), and S15-38's board resolver, which this PR makes the one resolver for boards and renders so the two agree on what answers.

**What stays.** No view changes. `CitationLineDisplay` stays as the fallback and for its other callers (rule "Today's line stays the fallback, in Swift"). Every board read and write reply is unchanged. Nothing is cached. No migration.

## 2. User stories

**US-1.** As the provenance sheet and the Sources section (S15-21, S15-22), I send the Citation ids I show and get back each one's full and short citation, as styled runs and plain text, and a group key, with the graphs and Sources the read used, so I draw formatted citations, group a household's Citations and refresh when those inputs change, without parsing a format.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | The seeded census type; a Source dated 1880 holding creator "Westmark", jurisdiction "Calder County, Westmark", schedule "population schedule", enumeration_district "236", piece "1047", folio "22"; its graph holding schedule_number "9", dwelling_number "112", family_number "118", line_number "14", item "Ada Robins"; its Artifact holding format "digital image", provider "Westmark Heritage", url "https://example.org/calder/1880", accessed_date "12 March 2025", citing "county film 7, item 3"; a Citation on that graph and Artifact with page label "14". `RenderCitations` for it | `full.plain` = "1880 Westmark census, Calder County, Westmark, population schedule, ED 236, piece 1047, fol. 22, p. 14, schedule 9, dwelling 112, family 118, line 14, Ada Robins; digital image, Westmark Heritage (https://example.org/calder/1880 : accessed 12 March 2025); citing county film 7, item 3." in three runs: plain up to and including "digital image, ", italic "Westmark Heritage", plain from " (https…" to the end. `short.plain` = "1880 Westmark census, Calder County, Westmark, ED 236, fol. 22, p. 14, dwell. 112, fam. 118, Ada Robins." `inputs.evidence_graphs` = [the graph]; `inputs.sources` = [the Source] |
| AC-1.2 | AC-1.1's catalog plus a second Citation on the same graph and Artifact with page label "14", and a third with page label "15" | The first two have equal `group_key`; the third's differs |
| AC-1.3 | A Citation whose Source type has no full format (a new researcher type) | `full` has no runs and an empty `plain`; `group_key` is `citation:` and the Citation's id; the app shows today's line |
| AC-1.4 | Ids [C3, C1, C3, X] where C1 and C3 exist and X is a well-formed UUIDv7 with no Citation row | Two entries, C3 then C1; X is left out without an error |
| AC-1.5 | 2,001 ids | `citations.invalid`, before any query |
| AC-1.6 | A type with full format `{source.meta.publisher}; {source.date}; p. {citation.page}.`: Source A's publisher marked unknown, date marked unknown, Citation page marked unknown; Source B's publisher "Ashby Press" supplied, date ABT 1880 supplied, Citation page label "23" supplied | A renders "n.p.; n.d.; p. unpaginated."; B renders "[Ashby Press]; [ca. 1880]; p. [23]." |

**US-2.** As the format editor and the Source page (S15-17, S15-23), I render one form against one Citation, or the list form against one Source, optionally with an unsaved format written with keys, and get back the render, what it is missing and what is wrong with the text.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | AC-1.1's Source, form `list`, no unsaved format, target the Source | `render.plain` = "Calder County, Westmark. 1880 Westmark census, population schedule."; no missing; no diagnostics |
| AC-2.2 | AC-1.1's Citation, form `full`, unsaved format `{source.meta.jurisdiction}, line {graph.meta.line_number}.` | `render.plain` = "Calder County, Westmark, line 14." |
| AC-2.3 | The same, unsaved format `{source.meta.nope}.` | `render` empty; `missing` empty; one diagnostic `full` · `unknown_field` over `nope` |
| AC-2.4 | A census Source dated 1880 with no jurisdiction and no Citations, form `list`, no unsaved format, target the Source | `missing` has one entry with one option: level `source`, field `jurisdiction` (with its label) |
| AC-2.5 | A Source target with form `full`; both targets set; neither set; form `fourth` | `citations.invalid` each |
| AC-2.6 | A well-formed Source id that is not in the catalog; a well-formed Citation id that is not | `sources.not_found`; `citations.invalid` |
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
| One citation resolver, `sourcemetadata.CitationValues`, for boards and renders; `ownerValues` goes; one option rule, `sourcemetadata.AppendOptions`; `metadatafields.MapByIDsTx` | STEP-1, D-2, D-11, D-16, T-1 |
| The board read loads its Sources in one batch (`sources.GetManyTx`) | STEP-2, D-17 |
| By-id reads with one alias-aware column list and one scan per table: `citations.ListCitedTx`, `sources.GetManyTx`, `sourcetypes.GetManyTx` | STEP-2, D-3, T-2, T-3, T-4 |
| `core/database/citationrender`: the batch render (full and short per Citation, group key, order, limits, inputs) | STEP-3, D-1, D-4 – D-8, AC-1.1 – AC-1.6 |
| The preview render: one form, one target, an optional unsaved format, missing options, diagnostics | STEP-4, D-9, D-10, US-2 |
| Query count and time at 300 and 1,200 Citations, through `databasetest.CountSelects` | STEP-5, D-12, D-13, T-8 |
| RPCs `RenderCitations` (with `PageInputs`), `RenderCitationPreview`, `ListCitationBuiltins` | STEP-6, D-14, US-1 – US-3 |
| Swift parity enums and rows for options, diagnostic codes and built-ins, in one vocabulary file | STEP-7, D-15, US-4 |
| Docs: `docs/citation-formats.md` § Rendering; map row | STEP-8 |

| Out | Home |
| --- | --- |
| Any screen, Swift store method or `CatalogQueryKey` that calls these RPCs | S15-17 (preview, built-ins), S15-21 (batch, sheet key), S15-22 (batch), S15-23 (preview, list form) |
| Inputs on the preview reply | not planned (S15-17 re-asks on each edit and S15-23 on each click; neither holds a key) |
| Swift copy for a built-in's name (the hint "or the Source date", Insert field) | S15-39 (the board hint), S15-17 (Insert field). Moved from S15-38's Out, which named S15-16: this PR adds the parity enum the copy keys on, and no view draws one |
| Swift copy per diagnostic code | S15-17 |
| Rich-text (RTF) output and the clipboard write | S15-21 (`PVClipboardCopyState` rich payload) |
| Caching a render | not planned (rule "Citations render on demand, from SQL"; caching is a later decision if S15-21 measures it slow) |
| Rendering the list form for Citations in the batch | not planned (the list form is the Source's; S15-23 renders it through the preview call) |
| The sourcevocab golden (`core/database/sourcevocab/render_test.go`) rendering through the catalog resolver | not planned (it tests the seed's formats against a fixture resolver on purpose) |
| The page's mark in `Observation` or other citation messages | not planned (S15-44 D-7; the render reply carries the printed text) |
| The type label and the formats read from `source_types` in two SELECTs (`sourcetypes.GetManyTx`, `StoredFormatsTx`) | not planned (one extra SELECT per call; logged in the review) |
| `core/database/sourcetypes/formats.go`'s three id maps built from `ListByIDsTx` moving to `MapByIDsTx` | not planned (they key by `uuid.UUID` or a different value; logged in the review) |
| `effects`' private `countingQuerier` | not planned (it counts a `Querier` in a package test that cannot import `databasetest`; T-8 uses `CountSelects`) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Engine | `core/citationformat/render.go` `Resolver`, `Value`, `Render`, `Rendered.Plain`, `MaxRenderedBytes` | Renders one template through a `Resolver` into merged runs, at most 64 KiB. Pure; nothing calls it over the catalog |
| Engine | `core/citationformat/requirements.go` `Requirements`, `Missing`, `Requirement.Targets` | Derives a template's chains and the needed ones no target answers |
| Engine | `core/citationformat/builtins.go` `Builtin`, `Builtins`, `ListFormAllows` | The one table of 8 built-ins with level, `Date`, `Options`, `AlwaysSet`, `UnknownText` |
| Engine | `core/citationformat/parse.go` `Target`, `FieldRef`, `DiagnosticCodes`; `form.go` `Form`, `Forms`, `Form.Valid`, `FormDiagnostic`, `OptionYear`, `OptionFull` | The vocabulary Swift mirrors; only `Form` has a parity row today |
| Stored formats | `core/database/sourcetypes/formats.go` `StoredFormatsTx`, `Formats`, `Formats.Parse`, `Formats.Text`, `Formats.with`, `ToStored`, `ErrInvalid` | Batched read of the three columns keyed by `string(id)`; `Parse` is the one parse of a type's forms (blank skipped, an unparsed form has no template); `with` (unexported) sets one form; `ToStored` is the key→id step |
| Type reads | `core/database/sourcetypes/sourcetypes.go` `sqlLookup`, `sqlGetByID`, `sqlList`, `GetByIDTx`, `getByIDTx`, `lookupTx`, `Lookup`, `List`, `GetByID`, `Type` | Three copies of the column list and five inline `Scan`s of a `Type`; no batch read by id |
| Board resolver | `core/database/sourcemetadata/annotation.go` `CitationValue`, `ownerValues`, `ownerValues.Resolve`, `dateHead`, `pageHead`, `rowsByField`, `annotate`, `Alternative` | `ownerValues` answers one owner's level, the Source level and the date; `annotate` builds `Alternative`s from a chain's tail, keeping a field only when its row loaded, deduped across chains with a `seen` set |
| Board read | `core/database/sourcemetadata/sourcemetadata.go` `newOwnerValues`, `listWorkspaces` (`dateOf`: one `sources.GetTx` per distinct Source), `ListDraftWorkspace`, `fieldsByID`, `ListByOwnersTx`, `Row`, `Owner` | `listWorkspaces` and `ListDraftWorkspace` (the draft board, `own` nil) each build an `ownerValues` through `newOwnerValues`; `fieldsByID` maps `metadatafields.ListByIDsTx` by `string(id)` |
| Board tests | `core/database/sourcemetadata/annotation_test.go` `TestAnnotate` (a `values ownerValues` field, eight `ownerValues{…}` literals, `tt.values.fields = fields`), `TestCitationValues`; `core/database/sourcemetadata/sourcemetadata_test.go` `TestDraftBoardScenarios` | Build the board resolver directly |
| Field columns | `core/database/metadatafields/metadatafields.go` `Columns(alias string)`, `ScanField(row, extra ...any)`, `ListByIDsTx` | One column list read bare (`Columns("")`) or in a join (`sourcevocab` `sqlListSuggestions`, `Columns("f")`) |
| Sources | `core/database/sources/sources.go` `sqlColumns`, `scanSource(row, extra ...any)`, `fillDates`, `settleDate`, `CitationDate`, `GetTx`, `ErrNotFound` | One Source by id with its settled date; no batch read by id (S15-43's plan names this PR's) |
| Citations | `core/database/citations/citations.go` `Citation`, `ListedCitation`, `sqlGet`, `sqlListByArtifact`, `scanRow`, `scanListedRow`, `ErrInvalid` | Two column lists (`sqlGet`, `sqlListByArtifact`'s `c.` list) and two near-copy scans of the nine columns, `scanRow` takes no extra destinations; no batch read; `graph_id` and `artifact_id` are `NOT NULL` (`core/database/migrations/000059.sql`) |
| Locator | `core/locator/depiction.go` `Page(locatorJSON) PageRef` (`ArtifactPage`, `Label`, `Mark`) | Reads the page selector with its settled mark; zero `PageRef` for a bad or pageless document |
| Batching | `core/database/sqlbatch` `Query`, `Size` (500) | Every by-id read issues one query per 500 ids |
| Query counter | `core/database/databasetest/selects.go` `CountSelects(t, c)`, `Selects.N`, `Selects.Reset` | Counts every SELECT the catalog's one connection prepares, through a SQLite authorizer; used by `conclusiondetails` and `promotealign` tests |
| Budget | `core/database/databasetest/budget.go` `Warm`, `WithinBudget` | Times a read against a budget |
| Page inputs | `core/database/graphcache/pageinputs.go` `PageInputs`, `Graph.PageInputs`, `AddEvidenceGraphs`, `AddSources`, `Lists`; `api/ffi/handlers/page_inputs.go` `pageInputsProto`; `core/database/conclusiondetails` `ForEntity(c, h, in *graphcache.PageInputs)` | A page read records the graphs and Sources it shows; the handler sends them as `engine.PageInputs`; Swift refreshes a key on them (`CatalogQueryRefresh.followsInputs`) |
| FFI | `api/ffi/handlers/source_defs.go` `UpdateCitationFormats` (inline `field_choices` parse), `citationFormatDiagnosticsProto`, `metadataFieldProto`; `api/ffi/handlers/metadata.go` `requirementProto`; `api/ffi/handlers/catalog.go` `withProjectCatalog`, `parseID`, `parseIDs`, `errInvalidID`; `api/ffi/handlers/version.go` `GetVersion` | `requirementProto` builds each `CitationRequirementOption` inline; `GetVersion` opens no catalog |
| Wire | `api/proto/engine.proto` `METHOD_GET_DRAFT_METADATA_BOARD = 123`, `CitationFieldChoice`, `CitationFormatDiagnostic`, `CitationRequirementOption`, `MetadataField`, `PageInputs` | No render message or method |
| Dispatch | `api/ffi/dispatch.go` `MethodGetDraftMetadataBoard`, `Call` switch | One constant and one case per method |
| Parity | `api/ffi/swift_vocabulary_test.go` `TestSwiftVocabularyMatchesGo`, `swiftCitationForm`, `rawCase`, `listCase` (`[a-z_]+`), `swiftEnumBody` | Each row reads only its enum's body; no `listCase` enum has a dotted value |
| Swift | `macos/App/Platform/CitationForm.swift` `CitationForm` | The one citation vocabulary enum in Swift; the app target is a synchronized folder group (`PBXFileSystemSynchronizedRootGroup`) |
| Fixtures | `api/ffi/handlers/harness_test.go` `sourceFixture`, `seededSourceOfType`; `api/ffi/handlers/metadata_test.go` `lineLedgerSource`, `TestMetadataBoardRequirements`; `core/database/sourcemetadata/sourcemetadata_test.go` `seededWorld`, `emptyWorld`; `core/database/sourcevocab/sourcevocabtest` `Install`; `core/database/artifacts/artifactstest` `Create`; `core/database/evidencegraphs/evidencegraphstest` `Create`, `ScaleSeed` | Seeded catalogs and Sources by RPC and in package tests |
| Seed | `core/database/sourcevocab/registry.go` census `Full`, `Short`, `List`; `core/database/sourcevocab/testdata/seed-citations.txt` | The census lines AC-1.1 and AC-2.1 expect, rendered there against a fixture resolver |

**Precedent.** S15-38 ([#910](https://github.com/Jake-Robins-Studios/provenencia/pull/910)) built `ownerValues` on `CitationValue` and `CitationDate`; this PR generalizes it (D-11) instead of writing a second resolver. `metadatafields.Columns(alias)` with `ScanField(row, extra ...any)` is the shape for one column list, bare or in a join, and one scan per table (D-3). `artifacts.GetMany` is the shape of a by-id batch read (`database.UniqueBlobIDs`, `sqlbatch.Query`, map keyed by `string(id)`, missing ids absent). `conclusiondetails.ForEntity(c, h, in)` with its `CountSelects` test (`conclusiondetails_test.go`) is the shape of a page read that records its inputs and is counted. `sourcetypes.GetFormats` is the read-transaction shape (`c.DB()`, `db.Begin()`, deferred rollback).

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | **One package.** `core/database/citationrender` *(new)* owns the batch render and the preview. It reads through the owning packages' exported reads (D-3) and answers through `sourcemetadata.CitationValues` (D-11); it runs no SQL of its own | `.cursor/rules/catalog-queries.mdc`: table reads stay in their package; the render is a composition over five of them | The render in `citations` — it would import `sourcemetadata`, `sourcetypes` and `sources`; a resolver in `citationformat` — it is pure (S15-14) |
| D-2 | **What each built-in answers** (filled by `citationrender` into `CitationValues.Builtins`, D-11): `source.title` → `Text` = Source title; `source.type` → `Text` = the type's `Label`; `source.date` → `sources.CitationDate(source)`; `artifact.label` → `Text` = `Cited.ArtifactLabel`; `graph.name` → `Text` = `Cited.GraphName`; `citation.page` → `Text` = `PageRef.Label`, `Mark` = `PageRef.Mark`; `citation.image` → `Text` = `strconv.Itoa(PageRef.ArtifactPage)` when it is above 0, else not set; `citation.label` → `Text` = the Citation label. A Source target (D-9) sets only the three `source` built-ins and only the `source` level's rows | One table of where each value comes from; the page's mark comes from `locator.Page`, settled (S15-44 D-6) | Reading the page label from the locator JSON here — a second decoder beside `locator.Page` (known trap S10-32) |
| D-3 | **By-id reads, one column list and one scan per table.** `citations`: `columns(alias string) string` *(new)*, the nine columns `sqlGet` reads, each prefixed with `alias.` when `alias` is not empty (shaped like `metadatafields.Columns`), used by `sqlGet` (`columns("")`), `sqlListByArtifact` (`columns("c")`) and `ListCitedTx` (`columns("c")`); `scanRow(row database.Scanner, extra ...any)` takes extra destinations, and `scanListedRow` is deleted: `ListByArtifact` scans with `scanRow(rows, &n)` into a local `n int32` and builds `ListedCitation{Citation: c, ObservationCount: n}`; `type Cited struct { Citation; ArtifactLabel, GraphName string; SourceID []byte }` *(new)*; `ListCitedTx(tx *sql.Tx, ids [][]byte) (map[string]Cited, error)` *(new)*: `SELECT ` + `columns("c")` + `, COALESCE(a.label, ''), COALESCE(g.name, ''), g.source_id FROM citations c LEFT JOIN artifacts a ON a.id = c.artifact_id LEFT JOIN evidence_graphs g ON g.id = c.graph_id WHERE c.id IN (` through `sqlbatch.Query` and `scanRow` with three extras. `sources.GetManyTx(tx *sql.Tx, ids [][]byte) (map[string]Source, error)` *(new)*: `SELECT sqlColumns FROM sources WHERE id IN (` through `scanSource`, then `fillDates` on the found Sources. `sourcetypes`: `columns(alias string) string` *(new)* (`id, key, origin, label, COALESCE(description, ''), icon_key`, alias-prefixed the same way) used by `sqlLookup` and `sqlGetByID` (`columns("")`), `sqlList` (`columns("t")`, its subselect after it) and `GetManyTx`; `scanType(row database.Scanner, extra ...any) (Type, error)` *(new)*, which every inline `Type` scan in `sourcetypes.go` calls (`Lookup`, `List` with `&t.SuggestedFields` as an extra, `GetByID`, `getByIDTx`, `lookupTx`); `GetManyTx(tx *sql.Tx, ids [][]byte) (map[string]Type, error)` *(new)* with `IN (`. Each new by-id read: `database.UniqueBlobIDs`, no ids → empty map and no query, missing ids absent, keyed by `string(id)` | The Citation's Source is its graph's (`g.source_id`): a Citation never leaves its graph, and a move updates graph and Artifact together (rule "A move is the whole bundle"). LEFT JOIN so a crafted Citation with a missing row still reads. `metadatafields.Columns(alias)` / `ScanField(row, extra...)` is the precedent, and the alias covers the join `ListCitedTx` adds; a new column is then one edit per table, not three to six (review M-5, M-10) | A third citation scan and a sixth inline type scan; the Source's title and type label joined into the Citation query — the Source-target preview needs the Source read anyway, and `fillDates` stays in `sources` (S15-43 D-3) |
| D-4 | **The read plan**, in `load.go`, on one read transaction. `type subject struct { cited *citations.Cited; source *sources.Source; typeLabel string; page locator.PageRef; values sourcemetadata.CitationValues }` *(new, unexported)*: what one Citation, or one Source alone, renders from. `loadCitations(tx *sql.Tx, ids [][]byte) ([]*subject, error)`: `ListCitedTx` (the ids) → `sources.GetManyTx` (the `SourceID`s; it runs `fillDates`) → `sourcetypes.GetManyTx` (the Sources' type ids), one `subject` per found Citation in input order. `loadSource(tx *sql.Tx, id []byte) (*subject, error)`: `sources.GetManyTx` and `sourcetypes.GetManyTx` for one Source, `cited` nil; a missing Source → `sources.ErrNotFound`. `fillValues(tx *sql.Tx, subs []*subject, templates []*citationformat.Template) error`: `metadatafields.MapByIDsTx` (every by-id field the given templates name, `Template.Fields`) → `sourcemetadata.ListByOwnersTx` (each subject's Source at `source`; for a subject with `cited`, its `ArtifactID` at `artifact` and `GraphID` at `graph`) → each subject's `values` (D-2, D-11). The batch: `loadCitations` → `sourcetypes.StoredFormatsTx` (the subjects' type ids) → `Formats.Parse` once per type, keeping `FormFull` and `FormShort` → `fillValues` with every kept template → render. The preview (D-9, D-10): `loadCitations` with one id or `loadSource`, then its one template, then `fillValues` with that template only. Each list of ids is the distinct non-nil ids from the previous step. Parse diagnostics are dropped: a form that does not parse has no template | A fixed number of reads per 500 ids at each step (D-13): 9 SELECTs when every list is under 500 and some Source is dated. The field read takes only fields a template names | Reading every field — grows with the vocabulary; parsing per Citation — 600 parses where one per type suffices |
| D-5 | **The page, once per Citation.** `locator.Page(cited.LocatorJSON)` is called once per Citation in `loadCitations` and kept on the `subject`; `fillValues` puts it into that Citation's `Builtins` | `Page` parses JSON | Calling `Page` per placeholder |
| D-6 | **Batch render API.** `type RenderedCitation struct { CitationID []byte; Full, Short citationformat.Rendered; GroupKey string }` *(new)*. `func Render(c *database.Catalog, citationIDs [][]byte, in *graphcache.PageInputs) ([]RenderedCitation, error)` *(new)* opens a read transaction (as `sourcetypes.GetFormats`) and calls `render(tx *sql.Tx, citationIDs, in)` *(new, unexported)*. `in` must not be nil (callers that record nothing pass `c.Graph().NoPageInputs()`). It records with `in.AddEvidenceGraphs` every `Cited.GraphID` and with `in.AddSources` every non-nil `Cited.SourceID` of the Citations it found. Order: the input order, a repeated id once (first place), an id with no Citation row left out. A Citation whose graph, Source or type row is missing, or whose type has no parsing full (short) format, gets an empty `Full` (`Short`). Every id must be 16 bytes, else `citations.ErrInvalid`. No ids → nil, no query, nothing recorded | Rule "Citations render on demand, from SQL": the sheet's key gets "the registry's refresh on the inputs its read reports"; `.cursor/rules/catalog-queries.mdc` has page reads take the caller's `PageInputs` (precedent `conclusiondetails.ForEntity`). A deleted Citation between a screen's read and its render is not an error (the screen drops it). `RenderedCitation` matches the proto message and does not shadow `citationformat.Rendered` (review M-6) | No inputs — S15-21 would reopen this PR's proto and read (review M-2); failing on a missing id — the sheet would fail for a Citation deleted while it opened |
| D-7 | **Group key** (`groupKey`, unexported): a Citation with a non-empty `Full` gets `"full:"` + lowercase hex SHA-256 over each run of `Full` in order, written as one byte (1 italic, 0 plain), the text's length as `binary.AppendUvarint`, then the text. A Citation with an empty `Full` gets `"citation:"` + `database.UUIDString(id)`. Citations of different Sources whose full citations render the same share a key | Rule "Grouping is by the rendered full citation": Go decides grouping and Swift only compares keys, with no special case for the fallback (each fallback Citation stands alone, as today). The length prefix means no text can fake a run boundary; the hash keeps the key at 69 bytes; runs, not plain text, so the same words in different italics do not group | The plain text as the key — up to 64 KiB repeated on the wire and italics ignored; an empty key for the fallback — Swift would branch on it |
| D-8 | **Limits** (exported constants in `citationrender`): `MaxCitations = 2_000` ids per batch call, checked before any query; `MaxBatchBytes = 8 << 20`, the sum of `len(Full.Plain()) + len(Short.Plain())` over the call, checked after each Citation; over either → `citations.ErrInvalid`, and rendering stops there | The map's Scale is 1,200 Citations per call; a census full note is about 350 bytes, so 1,200 Citations make about 1 MiB. A crafted format (repeating `{source.title}` up to 4,096 bytes) renders 64 KiB per form; without a call cap 2,000 Citations would hold 256 MiB | No cap; a new error code — `EngineErrorCode` and `L10n.Errors` copy for a case only a crafted catalog reaches; the screens show the generic failure with Try again (S16-04) |
| D-9 | **Preview API.** `type Target struct { CitationID, SourceID []byte }` *(new)*, exactly one set, 16 bytes. `type PreviewInput struct { Form citationformat.Form; Format *string; Choices []sourcetypes.FieldChoice; Target Target }` *(new)*. `type Preview struct { Rendered citationformat.Rendered; Missing [][]sourcemetadata.Alternative; Diagnostics []citationformat.FormDiagnostic }` *(new)*. `func RenderPreview(c *database.Catalog, in PreviewInput) (Preview, error)` *(new)* opens one read transaction. Refusals, all `citations.ErrInvalid`: `!in.Form.Valid()`; neither or both targets; a target id not 16 bytes; a Source target with a form other than `list`. A Source target that is not in the catalog → `sources.ErrNotFound`; a Citation target that is not → `citations.ErrInvalid`. A Citation target loads through `loadCitations` with one id and takes any form (`list` renders its Source's list entry from Source values); a Source target loads through `loadSource` (D-4). `Missing`: for each requirement `citationformat.Missing` returns, `sourcemetadata.AppendOptions(nil, map[citationformat.Target]bool{}, req.Targets, subject.values.Fields)` (D-16); a requirement whose options come back empty is left out | Rule "One render request for previews and the list entry": a form, an optional unsaved format, a target. The list form is the Source's (map § 6.10). Which options of a chain can be shown is decided in core, by the rule the boards use (review M-3) | Several Citation ids per preview — S15-17 and S15-23 each preview one target; a full or short preview against a Source — every Artifact, graph and Citation placeholder would read as missing; raw targets plus a field map for the handler to filter — domain logic in a handler (known trap Q3). The map rule's "Citation ids" became "one Citation" at planning |
| D-10 | **Which format a preview renders.** `Format == nil`: the target's type's stored text for `Form`. `Format != nil`: `sourcetypes.ToStored(tx, sourcetypes.Formats{}.With(in.Form, *in.Format), in.Choices, "")`; its error (a bad choice → `sourcetypes.ErrInvalid`) is returned; with diagnostics the preview returns them only (empty render, no missing); else the text it returns for `Form`. Either way the text is parsed through `sourcetypes.Formats{}.With(in.Form, text).Parse()` and the template is `templates[in.Form]`; no template (blank, or a stored text that does not parse) → empty render, no missing, no diagnostics. With a template: `Rendered = citationformat.Render(tpl, values)`, `Missing` from `citationformat.Missing(citationformat.Requirements(tpl), values)` (D-9). `Formats.with` is exported as `Formats.With`, its callers in `formats.go` renamed | `Formats.Parse` is "the one parse of a type's three formats" (blank and unparsed rules there, review M-4); `ToStored` is the one key→id step, so a key the save would refuse is refused here with the same diagnostic. Stored diagnostics belong to the type page's `GetCitationFormats` | A local `strings.TrimSpace` check and a direct `citationformat.Parse`; a switch building `Formats` in `preview.go` — a second form→field setter beside `with` |
| D-11 | **One citation resolver.** `sourcemetadata.CitationValues` *(new, exported, in `annotation.go`)*: `struct { Rows map[vocabkey.Level]map[string]Row; Fields map[string]metadatafields.Field; Builtins map[citationformat.Target]citationformat.Value }` with `func (v CitationValues) Resolve(t citationformat.Target) citationformat.Value`: a built-in target answers `Builtins[t]` (absent → zero); a field target not named by id answers zero; a field target named by id answers `CitationValue(row, v.Fields[id])` from `Rows[t.Level][id]` (no row → zero; a field whose row did not load still answers, with no unknown text). `ownerValues`, `ownerValues.Resolve` and `newOwnerValues` are deleted; `listWorkspaces` builds `CitationValues{Rows: {owner level: own, source: source}, Fields: fields, Builtins: {dateHead: the Source's date}}` (an owner at `source` gives one map entry), and `ListDraftWorkspace` builds `CitationValues{Rows: {source: rows}, Fields: fields, Builtins: {dateHead: sources.CitationDate(src)}}` (no own-level entry, as today's `own: nil`). `TestAnnotate`'s `values` field becomes a `CitationValues`, each literal converted case for case (`own` → `Rows[level]`, `source` → `Rows[source]`, `date` → `Builtins[dateHead]`, the `fields` assignment → `Fields`), expectations unchanged. The id-keyed field map moves to `metadatafields.MapByIDsTx(tx *sql.Tx, ids [][]byte) (map[string]Field, error)` *(new)* beside `ListByIDsTx`; `sourcemetadata.fieldsByID` is deleted and its callers and `fillValues` call `MapByIDsTx` | The field-answer rule lives once, so a board and a render cannot disagree (map scope "so the boards and the render agree", review M-1); a ninth built-in is one value set in `fillValues`, not a case in a second switch. Both board readers and the render build the one type (review M-11). The field map sits with the field table (review round 2) | A second resolver in `citationrender` beside `ownerValues`; exporting `sourcemetadata.fieldsByID` — a `metadata_fields` read in the wrong package |
| D-12 | **Counting queries.** T-8 counts with `databasetest.CountSelects(t, c)` around one `Render` call (warmed once first, then `Reset`). No new counter, and no read's signature changes | `CountSelects` counts every SELECT on the catalog's one connection, whatever issues it, and `citationrender` can import `databasetest`; it is the counter `conclusiondetails` already uses (review X-1) | A `Querier` wrapper and widening `StoredFormatsTx`, `ListByOwnersTx`, `metadatafields.ListByIDsTx` to take it — a third counting mechanism and three signature changes for a test |
| D-13 | **Scale check.** T-8 builds 30 Sources of the seeded census type, each dated 1880 and holding AC-1.1's Source values, each with 2 Artifacts holding AC-1.1's Artifact values and 5 graphs holding AC-1.1's graph values (each graph linked to both Artifacts), and Citations spread evenly over the graphs and Artifacts with page label "14": 300 (10 per Source) and 1,200 (40 per Source). One `Render` call each: **9** SELECTs at 300 and **11** at 1,200 (only `ListCitedTx` takes 3 batches). Times with `databasetest.Warm` and `databasetest.WithinBudget`: **100 ms** at 300, **400 ms** at 1,200 | The map's Scale: a Person page citing 30 Sources renders up to 300 citations; a value with 1,200 records. Exact counts hold "a fixed number of queries"; the 1,200 case shows the count grows only by batches of 500, never per Citation | Counting through the handler; one budget — the 1,200 case is the slow one |
| D-14 | **Wire and handlers.** Messages and methods in § FFI; handlers in `api/ffi/handlers/citation_render.go` *(new)*. `RenderCitations`: `parseIDs`, then `citationrender.Render(c, ids, c.Graph().PageInputs())`, reply `inputs` through `pageInputsProto`. `RenderCitationPreview`: the set oneof field through `parseID` into `Target`; an unset oneof leaves `Target` empty (→ `citations.invalid` from `RenderPreview`); `format` → `PreviewInput.Format` only when present; `field_choices` through `fieldChoicesFromProto([]*engine.CitationFieldChoice) ([]sourcetypes.FieldChoice, error)` *(new, `source_defs.go`)*, extracted from `UpdateCitationFormats`, which then calls it; missing options through `citationOptionProto(sourcemetadata.Alternative) *engine.CitationRequirementOption` *(new, `metadata.go`)*, extracted from `requirementProto`'s loop, which then calls it. `ListCitationBuiltins` opens no catalog (as `GetVersion`) | One converter per wire shape, shared by board and preview; no domain logic in handlers (known trap Q3) | A new option message — `CitationRequirementOption` already is "one option of a chain"; copying the choices loop |
| D-15 | **Swift parity in one file.** `macos/App/Platform/CitationForm.swift` is renamed (`git mv`) to `macos/App/Platform/CitationFormatVocabulary.swift` *(new)* and gains `enum CitationOption: String, CaseIterable, Sendable` (`case year`, `case full`, one per line), `enum CitationDiagnosticCode: String, CaseIterable, Sendable` (one `case camelName = "snake_code"` per `citationformat.DiagnosticCodes()` entry), `enum CitationBuiltin: String, CaseIterable, Sendable` (one `case sourceTitle = "source.title"` per built-in, `level.name`). In `api/ffi/swift_vocabulary_test.go`, `swiftCitationForm` becomes `swiftCitationVocabulary` with the new path, `listCase` widens to `[a-z_.]+`, and three rows are added | The map's S15-16 **Parity** line; one file and one path constant for the citation vocabulary (review M-8). Each row reads only its own enum body (`swiftEnumBody`), and no `listCase` enum has a dotted value, so widening reads nothing new (review M-9) | A second Swift file; a `dottedListCase` regexp |
| D-16 | **One option rule.** `sourcemetadata.AppendOptions(dst []Alternative, seen map[citationformat.Target]bool, targets []citationformat.Target, fields map[string]metadatafields.Field) []Alternative` *(new, exported, `annotation.go`)*: for each target not in `seen`, marks it seen and appends `Alternative{Level, Builtin}` for a built-in, `Alternative{Level, Field: &f}` for a by-id field whose row is in `fields`, and nothing for any other target. `annotate`'s tail loop calls it with its own `seen`. `Alternative`'s doc becomes "one option of a chain" | The board's rule for which options can be shown, used by the preview too (review M-3) | A copy of the loop in `citationrender` |
| D-17 | **The board reads its Sources in one batch.** `listWorkspaces` replaces its per-Source `sources.GetTx` loop with one `sources.GetManyTx` over the distinct Source ids; a Source id with no row returns `sources.ErrNotFound`, the error `GetTx` returns today | The board and the render read Sources the same way; the board read becomes a fixed number of queries (review M-7) | Leaving one query per Source beside a batch read this PR adds |

**Rules this plan bends.** None. The map was edited at planning (2026-11-20): the S15-16 **Check** names a package test for the scale counts (D-13), and rule "One render request for previews and the list entry" reads "a target (one Citation, or a Source for the list form)" (D-9). The implementer edits neither.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `core/database/citationrender` *(new)* | package | `sourcemetadata.listWorkspaces` | That is the board's read for owners; this is a per-Citation read over three owners and four other tables. It answers through the shared `CitationValues` (D-1, D-11) |
| `sourcemetadata.CitationValues` *(new)* | type (resolver) | `sourcemetadata.ownerValues` | Generalizes it to any set of levels and built-ins; `ownerValues` is deleted (D-11) |
| `sourcemetadata.AppendOptions` *(new)* | func | `annotate`'s tail loop | Extracted, not copied (D-16) |
| `metadatafields.MapByIDsTx` *(new)* | func | `sourcemetadata.fieldsByID` | Moved to the field package and exported (D-11) |
| `RenderedCitation`, `Render`, `render`, `subject`, `loadCitations`, `loadSource`, `fillValues`, `groupKey`, `MaxCitations`, `MaxBatchBytes` *(new)* | func / type / const | `citationformat.Render`, `citationformat.MaxRenderedBytes` | The engine renders one template; this loads and renders a batch, records inputs and caps the call (D-4 – D-8) |
| `RenderPreview`, `PreviewInput`, `Preview`, `Target` *(new)* | func / type | `sourcetypes.UpdateFormats` (`ToStored`, then `Parse`) | Reuses `ToStored` and `Formats.Parse` (D-10); renders instead of storing |
| `citations.ListCitedTx`, `citations.Cited`, `citations.columns` *(new)* | func / type | `citations.GetTx`, `sqlListByArtifact`, `scanRow`, `scanListedRow`, `metadatafields.Columns` | No batch by id; one alias-aware column list for three queries; `scanRow` gains extras and absorbs `scanListedRow` (D-3) |
| `sources.GetManyTx` *(new)* | func | `sources.getOne`, `sources.List` | One, or all; reuses `sqlColumns`, `scanSource`, `fillDates` (D-3) |
| `sourcetypes.GetManyTx`, `sourcetypes.columns`, `sourcetypes.scanType` *(new)* | func | `GetByIDTx`, five inline `Scan`s | One by id; the scans fold into `scanType` (D-3) |
| `sourcetypes.Formats.With` | method (exported) | `Formats.with` | Exported, not copied (D-10) |
| `citationOptionProto`, `fieldChoicesFromProto` *(new)* | func | `requirementProto`'s loop; `UpdateCitationFormats`'s choices loop | Extracted, not copied (D-14) |
| `api/ffi/handlers/citation_render.go` *(new)* with `RenderCitations`, `RenderCitationPreview`, `ListCitationBuiltins`, `citationRenderProto` | FFI | `source_defs.go` `GetCitationFormats` | Format storage handlers live there; rendering is its own surface |
| Proto messages and three methods *(new)* | FFI | `CitationFormatDiagnostic`, `CitationFieldChoice`, `CitationRequirementOption`, `PageInputs` | Reused inside the new messages; nothing on the wire carries runs or a render |
| `CitationOption`, `CitationDiagnosticCode`, `CitationBuiltin` *(new)* | Swift enums | `CitationForm` | Same file, renamed (D-15) |

**Builds on.** `citationformat` (`Render`, `Requirements`, `Missing`, `Builtins`), S15-38's `CitationValue`, `CitationDate`, `Formats.Parse` and `annotate`, S15-15's `StoredFormatsTx`, `ToStored` and `citationFormatDiagnosticsProto`, S15-07's `ListByOwnersTx`, S15-43's `fillDates`, S15-44's `locator.Page`, `sqlbatch`, `graphcache.PageInputs` and `pageInputsProto`, `databasetest.CountSelects`, `Warm` and `WithinBudget`.
**Deletes.** `ownerValues`, `ownerValues.Resolve`, `newOwnerValues` (D-11); `sourcemetadata.fieldsByID` (moved to `metadatafields.MapByIDsTx`, D-11); `scanListedRow` (folded into `scanRow`, D-3); the hand-written column lists in `citations.sqlGet` and `sqlListByArtifact`, and in `sourcetypes.sqlLookup`, `sqlGetByID` and `sqlList`; the five inline `Type` scans (D-3); `listWorkspaces`' per-Source `GetTx` loop (D-17); the option loop body in `requirementProto` and the choices loop in `UpdateCitationFormats` (D-14); `Formats.with` (renamed, D-10); `macos/App/Platform/CitationForm.swift` and `swiftCitationForm` (renamed, D-15).
**Next adds.** S15-21 and S15-22 call `RenderCitations` from a store method, group by `group_key` and refresh on `inputs`; S15-17 calls `RenderCitationPreview` with `format` and `ListCitationBuiltins`, and maps copy per `CitationDiagnosticCode`; S15-23 calls `RenderCitationPreview` with a Source target and `list`; S15-39 keys built-in copy on `CitationBuiltin`. A ninth built-in is one row in `citationformat.builtins`, one entry D-2 sets in `fillValues`, and one Swift case its parity row demands. A new column on `citations` or `source_types` is one `columns` edit.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| The board read answers through `CitationValues` (D-11) and reads Sources in a batch (D-17) | `sourcemetadata.listWorkspaces` | Same answers as `ownerValues` for every target (T-1 holds the old cases); a missing Source is still `sources.ErrNotFound`; `TestMetadataBoardRequirements` and the board tests stay green |
| The draft board answers through `CitationValues` (D-11) | `sourcemetadata.ListDraftWorkspace` | Same answers as its `ownerValues` with `own` nil; `TestGetDraftMetadataBoard` and `TestDraftBoardScenarios` stay green |

No other path: the three RPCs are new and no view calls them.

### Scale

At the map's Scale (a provenance sheet or Sources section of 300 Citations over 30 Sources; a value with 1,200 records): per call, D-4's reads are 9 SELECTs while every list of ids is under 500 (1,200 Citations: 11, the Citation read in 3 batches), one `Formats.Parse` per distinct type, one `locator.Page` per Citation, and two `Render` calls per Citation: the census full format has 18 placeholders and 24 options, so 1,200 Citations make about 58,000 `Resolve` calls, each a map lookup. No write changes; nothing is invalidated or cached. The board read (D-17) loses one query per distinct Source: a Source page's read has one Source, so it reads the same. T-8 measures D-13's budgets at 300 and 1,200.

### Edges

- **Assumptions.** `citationformat.Render` assumes a resolver answers every target without error; D-4 loads everything first, so `Resolve` is a lookup and a missing row answers zero. `ListByOwnersTx` assumes owners at metadata levels only; `load` passes only `source`, `artifact` and `graph` owners. `Formats.Parse` assumes stored or `ToStored` text; a crafted stored text that does not parse leaves no template and an empty render (T-5). A Citation's Source is its graph's (D-3): T-5 crafts an Artifact of Source B under a graph of Source A and expects Source A's title, with the Artifact's own values still read. `CitationValues` keys `Rows` by level: a Source-level owner's board has one map for `own` and `source`, which is what `ownerValues` answered for both cases (T-1).
- **Neighbors.** Two Citations that differ only in a field the format does not read share a group key; one that differs in `citation.page` does not (AC-1.2); one that differs only in `citation.label` shares it unless the format reads `{citation.label}` (T-6). A value marked unknown on a field with no unknown text answers with "" (its group drops, the chain stops): T-5. A blank value with a stored supplied mark reads unmarked (`readByOwners` settles it) and prints nothing: T-5.
- **Removed inputs.** A Citation deleted before the call is left out and records no input (AC-1.4). A Source whose date row is gone renders undated (`settleDate`); a field a format names cannot be deleted (S15-15); a field row missing in a crafted catalog leaves its value answering with no unknown text and drops it from a preview's missing options (D-11, D-16). A type with its full format cleared renders empty and falls back (AC-1.3).
- **Real data.** The seed's 26 types render through a fixture resolver in `core/database/sourcevocab/render_test.go`; AC-1.1 and AC-2.1 render the census through the catalog and expect the same lines as `seed-citations.txt`'s `census full` rows (asterisks dropped, the italic as a run), so the two resolvers agree on the seed's census.
- **Untrusted size.** Ids per call: at most `MaxCitations` (2,000), checked before any query. Per Citation: two renders of at most 64 KiB each (engine). Per call: rendered text at most `MaxBatchBytes` (8 MiB), checked after each Citation (D-8); the reply carries runs and plain text, so at most twice that on the wire. Formats: at most 4,096 bytes and one parse per type. Locator: `locator.Page` reads at most `MaxDocumentBytes`. Distinct types, fields and owners are each bounded by the Citations in the call. The group key length-prefixes each run, so no value can forge a boundary (D-7).

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/sourcemetadata` | `CitationValues` *(new)*, `AppendOptions` *(new)*; `ownerValues`, `newOwnerValues` and `fieldsByID` deleted; `listWorkspaces` and `ListDraftWorkspace` use `CitationValues`; `listWorkspaces` uses `sources.GetManyTx` (D-11, D-16, D-17) |
| `core/database/metadatafields` | `MapByIDsTx` *(new)* (D-11) |
| `core/database/citations` | `columns` *(new)*, `scanRow(row, extra ...any)`, `scanListedRow` deleted, `Cited` *(new)*, `ListCitedTx` *(new)* (D-3) |
| `core/database/sources` | `GetManyTx` *(new)* (D-3) |
| `core/database/sourcetypes` | `columns` *(new)*, `scanType` *(new)*, `GetManyTx` *(new)* (D-3); `Formats.With` (was `with`) (D-10) |
| `core/database/citationrender` *(new)* | `render.go`: `RenderedCitation`, `Render`, `render`, `groupKey`, `MaxCitations`, `MaxBatchBytes` (D-6 – D-8); `load.go`: `subject`, `loadCitations`, `loadSource`, `fillValues` (D-2, D-4, D-5); `preview.go`: `Target`, `PreviewInput`, `Preview`, `RenderPreview` (D-9, D-10) |

Errors: `citations.invalid` → a bad id length, more than 2,000 ids, more than 8 MiB rendered, a bad form or target, a preview Citation that is not there (D-8, D-9); `sources.not_found` → a preview Source that is not there; `sourcetypes.invalid` → a bad field choice (D-10).

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
  PageInputs inputs = 2; // the Evidence graphs and Sources the render read
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

`api/ffi/dispatch.go`: `MethodRenderCitations`, `MethodRenderCitationPreview`, `MethodListCitationBuiltins` *(new)* and their `Call` cases. Handlers per D-14; `citationRenderProto(citationformat.Rendered) *engine.CitationRender` *(new)* sets `plain` from `Rendered.Plain()`.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Form parity (existing) | `CitationForm` | `macos/App/Platform/CitationFormatVocabulary.swift` *(new)* (renamed from `CitationForm.swift`) | Unchanged enum, moved file (D-15) |
| Option parity | `CitationOption` *(new)* | same | No view uses it yet |
| Diagnostic code parity | `CitationDiagnosticCode` *(new)* | same | No view uses it yet |
| Built-in parity | `CitationBuiltin` *(new)* | same | No view uses it yet |

States: none — no view. `macos/App/Platform/Generated/engine.pb.swift` is regenerated. The app target is a synchronized folder group, so the rename needs no project-file edit.

### Strings

None — no user-facing copy. The render's words ("n.d.", "unpaginated", "ca.") are citation text from the engine, not localized ([`docs/citation-formats.md`](../../../citation-formats.md) § Dates).

## 7. Steps

**STEP-1 — One citation resolver and option rule**
Files: `core/database/sourcemetadata/annotation.go`, `core/database/sourcemetadata/sourcemetadata.go`, `core/database/sourcemetadata/annotation_test.go`, `core/database/metadatafields/metadatafields.go`, `core/database/metadatafields/metadatafields_test.go`. Skill: `add-catalog-query`.
Do: D-11, D-16 (`listWorkspaces` keeps `sources.GetTx` until STEP-2).
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcemetadata/ ./core/database/metadatafields/ ./api/ffi/handlers/` passes, T-1.

**STEP-2 — By-id reads and the board's Source batch**
Files: `core/database/citations/citations.go`, `core/database/citations/citations_test.go`, `core/database/sources/sources.go`, `core/database/sources/sources_test.go`, `core/database/sourcetypes/sourcetypes.go`, `core/database/sourcetypes/sourcetypes_test.go`, `core/database/sourcemetadata/sourcemetadata.go`. Skill: `add-catalog-query`.
Do: D-3, D-17.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/...` passes, T-2, T-3, T-4.

**STEP-3 — The batch render**
Files: `core/database/citationrender/render.go` *(new)*, `core/database/citationrender/load.go` *(new)*, `core/database/citationrender/render_test.go` *(new)*.
Do: D-1, D-2, D-4 – D-8. Test worlds: `database.Create`, `sourcevocabtest.Install` (`core/database/sourcevocab/sourcevocabtest`), a user as `sourcemetadata_test.go` `emptyWorld` makes one; Sources, dates and values through `sources.Create`, `sources.SetDate`, `sourcemetadata.Set` on a `c.BeginWrite()` transaction; Artifacts and graphs through `artifactstest.Create` and `evidencegraphstest.Create`; types through `sourcetypes.Create` and `sourcetypes.UpdateFormats`; Citations as direct `INSERT`s, as `evidencegraphstest.ScaleSeed.Graph` writes them; direct `INSERT`s or `UPDATE`s on one transaction where a case crafts a row the writes refuse; a case that needs a missing referent turns foreign keys off with `db.Exec("PRAGMA foreign_keys=OFF")` on the catalog's `*sql.DB` outside any transaction (the catalog holds one connection), writes, and turns them back on. `Render` gets `c.Graph().PageInputs()` in every test.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/citationrender/` passes, T-5, T-6, T-7.

**STEP-4 — The preview**
Files: `core/database/citationrender/preview.go` *(new)*, `core/database/citationrender/preview_test.go` *(new)*, `core/database/sourcetypes/formats.go`.
Do: D-9, D-10.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/citationrender/ ./core/database/sourcetypes/` passes, T-9.

**STEP-5 — Scale**
Files: `core/database/citationrender/scale_test.go` *(new)*.
Do: D-12, D-13. The fixture writes structure and values with direct `INSERT`s on one transaction, in the style of `evidencegraphstest.ScaleSeed` (not its methods: they write one Artifact and an empty locator): ids `databasetest.BenchID` of kind 1 (Source), 2 (Artifact), 3 (graph), 4 (Citation), 7 (metadata row); refs `SRC-B<n>`, `ART-B<n>`, `GPH-B<n>`, `CIT-B<n>`; Sources of the seeded census type (`sourcetypes.Lookup(c, "census", vocabkey.OriginProvenencia)`); field ids from `metadatafields.ResolveKeysTx(tx, keys, vocabkey.OriginProvenencia)`; metadata rows into `source_metadata`, `artifact_metadata`, `evidence_graph_metadata`; each graph linked to both its Source's Artifacts in `evidence_graph_artifacts`; Citation k of a Source on graph k mod 5 and Artifact k mod 2, locator `{"version":1,"selectors":[{"type":"page","page_label":"14"}]}`. It then dates the 30 Sources through `sources.SetDate`.
Check: `CGO_ENABLED=1 go test -tags fts5 -run TestRenderScale -v ./core/database/citationrender/` passes and logs both times under budget, T-8.

**STEP-6 — RPCs**
Files: `api/proto/engine.proto`, generated Go and Swift (`./scripts/generate-proto.sh`), `api/ffi/dispatch.go`, `api/ffi/handlers/citation_render.go` *(new)*, `api/ffi/handlers/citation_render_test.go` *(new)*, `api/ffi/handlers/metadata.go`, `api/ffi/handlers/source_defs.go`. Skills: `add-ffi-handler`, `use-catalog-session`.
Do: D-14, § FFI.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/...` passes, T-10, T-11, T-12. (`./scripts/generate-proto.sh` needs `protoc`, `protoc-gen-go` and `protoc-gen-swift` on PATH; run it on a Mac if this machine lacks them.)

**STEP-7 — Swift parity**
Files: `macos/App/Platform/CitationForm.swift` → `macos/App/Platform/CitationFormatVocabulary.swift` *(new)*, `api/ffi/swift_vocabulary_test.go`.
Do: D-15.
Check: `CGO_ENABLED=1 go test -tags fts5 -run TestSwiftVocabularyMatchesGo ./api/ffi/` passes, T-13; `xcodebuild test` (via `scripts/check-pr.sh`, on macOS) passes with no Swift warning.

**STEP-8 — Version and docs**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj` (`MARKETING_VERSION`); `docs/citation-formats.md` (new § Rendering after § Storage: what each built-in reads (D-2), the Citation's Source is its graph's, the batch's order, limits and inputs (D-6, D-8), the group key (D-7), the preview's target and format rules (D-9, D-10), nothing cached); `../deployment-plan.md` (map row status; the S15-16 Check and the preview rule were edited at planning); `../completed.md`; this plan.
Do: per the Definition of done.
Check: `scripts/check-pr.sh` prints `check-pr: PASS`; `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-16-citations-render.md` reports no errors.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Render a Citation's full and short citation from its type's formats."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/sourcemetadata/annotation_test.go` `TestCitationValuesResolve` *(new)*, `TestAppendOptions` *(new)*; `TestCitationValues`, `TestAnnotate` (existing) | Resolve table: a by-id field at a level with a row → `CitationValue`; no row → zero; a field whose row did not load → text, no unknown text; a key-named field → zero; a built-in in `Builtins` → that value; one not in it → zero; a Source-level owner (one `Rows` entry) answers source fields. `AppendOptions`: a built-in, a loaded field, a field not loaded (skipped), a key-named field (skipped), a target already in `seen` (skipped). `TestAnnotate` converted per D-11 with every expected output unchanged; `TestCitationValues` unchanged. `metadatafields_test.go` `TestMapByIDsTx` *(new)*: two ids → keyed by `string(id)`; nil → empty | D-11, D-16 |
| T-2 | Go | `core/database/citations/citations_test.go` `TestListCitedTx` *(new)* | Two Citations on one graph and Artifact → each with the Artifact label, graph name, graph's Source id; ids [a, a, missing] → one entry; nil ids → empty map; a Citation whose Artifact row is gone (FKs off, crafted) → `ArtifactLabel` ""; `ListByArtifact`'s existing tests still pass on the shared `scanRow` | D-3 |
| T-3 | Go | `core/database/sources/sources_test.go` `TestGetManyTx` *(new)* | Dated Source (1880, supplied) and undated Source → both with `Date` and `DateMark` as `GetTx` returns them; missing id absent; repeated id once; nil → empty | D-3 |
| T-4 | Go | `core/database/sourcetypes/sourcetypes_test.go` `TestGetManyTx` *(new)* | Two types → as `GetByIDTx` returns them; missing absent; nil → empty; existing `List`, `Lookup`, `GetByID` tests pass on `scanType` | D-3 |
| T-5 | Go | `core/database/citationrender/render_test.go` `TestRender` *(new)* | Table, one type per case with a one-line full format: `{source.title}/{source.type}/{artifact.label}/{graph.name}/{citation.label}` → the five values joined by "/"; `image {citation.image}` with `artifact_page` 37 → "image 37"; `[image {citation.image}]` with label only → ""; a field marked unknown with no unknown text inside `[x {source.meta.k}]` → ""; a blank value with a stored supplied mark (crafted) → ""; a stored full text that does not parse (crafted `UPDATE source_types`) → empty `Full`, `citation:` key; a key-named field in a stored format (crafted) → answers nothing; no short format → empty `Short`, `Full` set; an Artifact of Source B under a graph of Source A (crafted) → Source A's title and the Artifact's own `{artifact.meta.k}`; AC-1.4's order and omission, with inputs holding only C1's and C3's graph and Source; no ids → nil with nothing recorded; an id of 15 bytes → `citations.ErrInvalid` | D-2, D-4, D-6, AC-1.3, AC-1.4 |
| T-6 | Go | `core/database/citationrender/render_test.go` `TestGroupKey` *(new)* | Two Citations on one graph, Artifact and page label → equal keys starting `full:`; page "14" vs "15" → differ; labels "a" vs "b", format without `{citation.label}` → equal; with it → differ; two types whose full formats render the same words, one italic (`*{source.title}*` vs `{source.title}`) → differ; no full format → `citation:<uuid>` each, distinct | D-7, AC-1.2 |
| T-7 | Go | `core/database/citationrender/render_test.go` `TestRenderLimits` *(new)* | 2,001 ids → `citations.ErrInvalid` with `CountSelects` N 0; crafted full **and** short formats of `{source.title}` repeated to 4,000 bytes and a 255-byte title (each render 64 KiB), on 70 Citations → `citations.ErrInvalid` (70 × 2 × 64 KiB ≈ 8.75 MiB); the same on 60 Citations (≈ 7.5 MiB) → renders | D-8, AC-1.5 |
| T-8 | Go | `core/database/citationrender/scale_test.go` `TestRenderScale` *(new)* | D-13's fixture: 300 → 300 results, `CountSelects` N 9, warm time ≤ 100 ms; 1,200 → 1,200 results, N 11, warm ≤ 400 ms; every `Full.Plain()` equals AC-1.1's full line | D-4, D-12, D-13 |
| T-9 | Go | `core/database/citationrender/preview_test.go` `TestRenderPreview` *(new)* | Table over AC-2.1 – AC-2.7 (AC-2.4's Source dated 1880); a Citation target with form `list` → AC-2.1's line; each input → render, missing (as `Alternative` lists), diagnostics or error as the AC; plus a chain `{graph.meta.item\|source.meta.item}` empty on both, Citation target, unsaved `{graph.meta.item\|source.meta.item}.` → one missing entry with two options; a field choice naming a field of another key → `sourcetypes.ErrInvalid` | D-9, D-10, D-16, AC-2.1, AC-2.2, AC-2.3, AC-2.4, AC-2.5, AC-2.6, AC-2.7 |
| T-10 | Go | `api/ffi/handlers/citation_render_test.go` `TestRenderCitations` *(new)* | AC-1.1's catalog built by RPC (`seededSourceOfType` census, `SetSourceDate` year 1880, `SetMetadata` at `source`, `graph`, `artifact`, `CreateArtifact`, `CreateCitationWithObservations` with locator `{"version":1,"selectors":[{"type":"page","page_label":"14"}]}`) → AC-1.1's runs, short text and inputs; AC-1.2's keys; AC-1.6's two Sources (a type made by `CreateSourceType` and `UpdateCitationFormats`; marks through `SetMetadata.mark`, `SetSourceDate.mark`, locator `page_unknown` / `page_supplied`); `citation_ids` ["nope"] → `errInvalidID` | AC-1.1, AC-1.2, AC-1.6 |
| T-11 | Go | `api/ffi/handlers/citation_render_test.go` `TestRenderCitationPreview` *(new)* | AC-2.1 on the T-10 Source; AC-2.3's diagnostic as `{form "full", code "unknown_field", start, end}` over `nope`; AC-2.4's missing as one `CitationMissing` with one option, level `source`, `field.key` `jurisdiction`; no target set → `citations.invalid`; `format` absent renders the stored list form, present and blank (AC-2.7) renders nothing | AC-2.1, AC-2.3, AC-2.4, AC-2.5, AC-2.7, D-14 |
| T-12 | Go | `api/ffi/handlers/citation_render_test.go` `TestListCitationBuiltins` *(new)*; `api/ffi/handlers/metadata_test.go` `TestMetadataBoardRequirements` and `TestGetDraftMetadataBoard`, `core/database/sourcemetadata/sourcemetadata_test.go` `TestDraftBoardScenarios`, `api/ffi/handlers/source_defs_test.go` `TestCitationFormats` (existing) | Reply equals `citationformat.Builtins()` field by field, in order (AC-3.1's values); the existing tests pass after the two extractions | AC-3.1, D-14 |
| T-13 | Go | `api/ffi/swift_vocabulary_test.go` `TestSwiftVocabularyMatchesGo` | The "citation forms" row on the renamed file; rows "citation options" (`CitationOption`, `rawCase`, want `OptionYear`, `OptionFull`), "citation diagnostic codes" (`CitationDiagnosticCode`, `listCase`, want `DiagnosticCodes()`), "citation built-ins" (`CitationBuiltin`, `listCase`, want `level.name` of each `Builtins()` row), each sorted | AC-4.1, D-15 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `./core/database/sourcemetadata/` (D-11, D-17), `./api/ffi/handlers/` board and format tests (D-14's extractions), `./core/database/sourcetypes/` (D-3's `scanType`), `./core/database/citations/` (`scanRow`).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none: § Strings)
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left (`ownerValues`, `newOwnerValues`, `sourcemetadata.fieldsByID`, `scanListedRow`, `Formats.with`, `CitationForm.swift`, `swiftCitationForm`); `scripts/check-guidance-names.py` passes (check-pr runs it)
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
| The board and the render disagree on what answers | One resolver (D-11), one option rule (D-16); T-10 renders the seed census lines |
| A per-Citation query sneaks into `loadCitations` or `fillValues` | T-8's exact counts |
| The resolver or extraction changes a board reply | T-1, `TestMetadataBoardRequirements` and the board tests (T-12) |

**Stop and report if:**

- A `TestAnnotate` case converted per D-11 needs a different expected output, or a board or draft-board test fails after STEP-1: `CitationValues.Resolve` answers some target differently from `ownerValues.Resolve`.
- A `citations` row's Artifact belongs to a different Source than its graph in a catalog the app wrote (not crafted): D-3's "the graph's Source" is then a choice the map must make.
- `CreateCitationWithObservations` refuses the locator `{"version":1,"selectors":[{"type":"page","page_label":"14"}]}` on an Artifact with no file, so T-10 cannot build AC-1.1 by RPC.
- T-8's counts differ from 9 and 11 with D-4's reads in place (another read issues a SELECT D-4 does not list, or the graph cache loads during the call).
- T-8's warm 300 time is over 100 ms or its 1,200 time over 400 ms on the implementer's machine: report the numbers; do not raise the budget.
- AC-1.1 renders a line other than `seed-citations.txt`'s `census full full` row with the same values: the catalog resolver and the seed's fixture resolver disagree.

## 12. Open questions

None.

## 13. PR

**Title:** S15-16 — Citations render through their type's formats
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-16-citations-render.md`.
