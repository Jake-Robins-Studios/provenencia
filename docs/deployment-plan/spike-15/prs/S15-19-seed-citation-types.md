# S15-19 — Seed the citation types, fields, suggestions and formats

**Status:** Landed in [#897](https://github.com/Jake-Robins-Studios/provenencia/pull/897) (2026-11-19)
**Spike / slice:** Spike 15 · Slice 4 — Formats as data
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: Go seed data only. The Source types list, the type page and the boards draw the new rows with the views they have today)
**Board:** —
**Depends on:** S15-06 (landed [#782](https://github.com/Jake-Robins-Studios/provenencia/pull/782)), S15-15 (landed [#871](https://github.com/Jake-Robins-Studios/provenencia/pull/871)), S15-37 (landed [#879](https://github.com/Jake-Robins-Studios/provenencia/pull/879)), S15-52 (landed [#891](https://github.com/Jake-Robins-Studios/provenencia/pull/891))
**Blocks:** —
**Branch:** `s15-19-seed-citation-types`
**Version bump:** minor, 0.23.4 → **0.24.0** (if `main`'s `VERSION` is no longer 0.23.4 when you rebase, the next minor after it): every new project gets 26 types, 63 fields and their formats, a backward-compatible feature ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-seeded-vocabulary`](../../../../.agents/skills/add-seeded-vocabulary/SKILL.md), [`add-catalog-query`](../../../../.agents/skills/add-catalog-query/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests)
**Context:** working rules "Follow the *Evidence Explained* style; never copy the book", "The seed is the product default", "Formats name fields by id", "Every placeholder names its level; fallback is written", "The item is a graph field", "No transforms on metadata", "A value can be marked unknown or supplied", "Suggestions have a level" ([`../deployment-plan.md`](../deployment-plan.md#working-rules)); [`../evidence-explained-citation-map.md`](../evidence-explained-citation-map.md) §§ 6.3, 6.4, 6.8; [`../README.md`](../README.md#working-rules); [`docs/seeded-vocabulary.md`](../../../seeded-vocabulary.md) §§ 1, 2; [`core/writes/README.md`](../../../../core/writes/README.md)
**Planned:** 2026-11-17 against `main` @ `6d49722`; refreshed 2026-11-19 against `main` @ `809833a` after S15-52 landed (compare with `origin/main` after `git fetch origin main`)
**Review:** [`S15-19-seed-citation-types.review.md`](S15-19-seed-citation-types.review.md) — Fits / Ready, 2 rounds and a refresh round after S15-52 landed (2026-11-19); every finding Fixed or Logged; nothing open

**Landed.** The handler tests that read the old seed needed more than D-11 named, because the birth certificate type now suggests Artifact and graph fields: `graphFixture` (`evidence_graphs_test.go`) detaches its Source type's Artifact and graph suggestions so the boards those tests read start empty, `TestUpdateSourceType` expects 4 + 10 + 2 + 1 suggested fields, and `TestSearchCatalogHandleKinds` queries "James Kenneth" because the seeded `item` field's example names "Ada Robins". `TestUpsertTx` and the effects case gained the format cases T-9 names. No other difference from the plan.

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

A new project starts with the citation vocabulary of map § 6.8: 26 Source types, each with an icon, a description and its three citation formats (full, short, list); 63 metadata fields, each with a label and a description that says to enter the value as it should appear; and each type's suggested fields at the Source, the Artifact and the Evidence graph. A census Source suggests its record fields, its Artifacts the copy fields, its graphs the item fields. The formats are stored by field id, as the format write stores them. A test renders every seeded format in all three forms against an invented Source of its type, so the whole set can be checked against the edition on hand.

**Why now.** S15-06 gave suggestions a level, S15-15 gave types their stored formats and `ToStored`, S15-37 gave fields their unknown text, and S15-52 moves the seed onto `writes.Run`. The format editor (S15-17), the renderer (S15-16) and the requirements on the boards (S15-38) all need real formats to show. S15-20 is merged in here (user, 2026-11-17).

**What stays.** Install runs at create only, from `onboarding.createCatalog`, as today: no install on open, no seed-version row, no FFI or Swift path to it. No view changes: the app does not render a format until S15-16. Existing projects keep what they have; the product owner updates the dogfood projects by hand (D-12).

## 2. User stories

**US-1.** As a researcher creating a project, I get every type, field and suggestion the citation patterns use, so I can catalog a census page, a certificate or a book without first building the vocabulary.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | `Install` on an empty catalog | `sourcetypes.List` returns 26 types, each origin `provenencia` with its registry label, description and icon; `metadatafields.List` returns 63 fields, origin `provenencia` |
| AC-1.2 | The `census` type after AC-1.1 | Source suggestions, in order: `creator`, `jurisdiction`, `schedule`, `enumeration_district`, `piece`. Artifact: `format`, `provider`, `url`, `accessed_date`, `citing`, `database_title`, `film_publication`, `roll`, `film_number`, `item_number`. Graph: `folio`, `schedule_number`, `dwelling_number`, `family_number`, `line_number`, `item`. Each list's sort orders are 0, 1, 2, … |
| AC-1.3 | The `birth_certificate` type after AC-1.1 | Source: `creator`, `document_number`, `volume`, `repository`. Artifact: `format`, `provider`, `url`, `accessed_date`, `database_title`, `citing`, `film_publication`, `roll`, `film_number`, `item_number`. Graph: `item`, `entry_number`. `record_date` and `issue_date` are not fields of a new catalog |
| AC-1.4 | `publication_place` and `publisher` after AC-1.1 | `UnknownText` "n.p."; every other seeded field's `UnknownText` is "" |
| AC-1.5 | `url` after AC-1.1 | `DataType` `url`; every other seeded field is `text` |
| AC-1.6 | A catalog made by `onboarding.Complete` | It holds the `census` type (`sourcetypes.Lookup(c, "census", provenencia)` succeeds) |

**US-2.** As the engine, each seeded type stores its three formats by field id, naming the product fields, so a researcher's field with the same key never captures a seeded format.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | `census` after AC-1.1, read with `sourcetypes.StoredFormatsTx` | Three non-empty texts; every field placeholder is a `#<uuid>` token, and each id is the `provenencia` field of the key the registry wrote |
| AC-2.2 | `sourcetypes.GetFormats(c, censusID)` | The full text equals the registry's census full format (fields by key), with no `Choices` and no `Diagnostics` |
| AC-2.3 | A user-origin field `author` exists before `Install` | `book`'s stored formats name the `provenencia` `author`'s id, never the user field's |

**US-3.** As the product owner checking the seed against the edition on hand, I read every seeded citation rendered from an invented Source of its type.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | The census full format rendered from the full fixture (D-9) | `1880 Westmark census, Calder County, Westmark, population schedule, ED 236, piece 1047, fol. 22, p. 14, schedule 9, dwelling 112, family 118, line 14, Ada Robins; digital image, *Westmark Heritage* (https://example.org/calder/1880 : accessed 12 March 2025); citing county film 7, item 3.` (asterisks mark the italic run) |
| AC-3.2 | The census short and list formats from the same fixture | Short: `1880 Westmark census, Calder County, Westmark, ED 236, fol. 22, p. 14, dwell. 112, fam. 118, Ada Robins.` List: `Calder County, Westmark. 1880 Westmark census, population schedule.` |
| AC-3.3 | Every seeded type, each form, from the full fixture and from the bare fixture (D-9) | The rendered text equals its line in `core/database/sourcevocab/testdata/seed-citations.txt` *(new)* |

**US-4.** As the engine, running `Install` again on a catalog it already wrote changes nothing, as the map's Check asks.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | `Install` twice on an empty catalog | The second run records no audit revision (`audit_transactions` count unchanged); type and field ids, labels, formats and every suggestion's sort order are unchanged |

## 3. Scope

| In | Covered by |
| --- | --- |
| `seedType` gains `Formats` (by key); `seedField` gains `UnknownText`; 26 types, 63 fields, the suggestion lists (D-1 – D-6) | STEP-2, STEP-3, STEP-4, AC-1.1 – AC-1.5 |
| `sourcetypes.UpsertTx` writes a type's stored formats; `metadatafields.UpsertTx` already writes `unknown_text` (S15-52) | STEP-1, AC-1.4, AC-2.1, AC-4.1 |
| `Install` stores each type's formats through `sourcetypes.ToStored` with `preferOrigin` `provenencia`; a format that does not store is an error (D-7) | STEP-5, AC-2.1 – AC-2.3 |
| `Install`'s suggestion write stays as S15-52 landed it (`ensureSuggestionTx`, index as order; D-10): no code change | AC-1.2, AC-1.3, AC-4.1 |
| Registry tests: the suggestions follow the full formats (D-4); every field a format reads is seeded and every seeded field is read (D-3); the render goldens (D-9) | STEP-6, STEP-7, AC-3.1 – AC-3.3 |
| Tests that read today's three-field seed move to their own fixture vocabulary (D-11) | STEP-8, AC-1.6 |
| S15-14's seed corpus and `TestSeedFormatsParse` deleted; `FuzzParse` keeps its other seeds (D-13) | STEP-7 |
| `docs/seeded-vocabulary.md` §§ 1, 2 and `add-seeded-vocabulary` describe the new seed | STEP-9 |

| Out | Home |
| --- | --- |
| Moving the Source seed onto `writes.Run` (`UpsertTx`, Install's one transaction, test helpers) | S15-52 |
| Running `Install` against an existing dogfood project, or any re-run behavior on an old catalog beyond AC-4.1 | Not planned: the product owner updates the dogfood projects by hand (user, 2026-11-17) |
| The subject vocabulary's, grades' and properties' seed Upserts reprojecting by hand | S16-62 |
| Rendering formats in the app; the batch render RPC | S15-16 |
| Requirements on the boards (needed, used) | S15-38 |
| The format editor | S15-17 |
| Removing `record_date` and `issue_date` from an existing catalog | Not planned: Install never deletes; the researcher removes them on the type page if they want |
| Suggesting fields that only the short or list format reads (`short_title`, `author_sort`, `coverage`) | Not planned: map § 6.8 "Suggestions" reads the full format only; S15-38 shows them as used on the boards |
| An install on open, a seed version, healing deleted rows | Not planned (rule "The seed is the product default") |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Registry | `core/database/sourcevocab/registry.go` `seedType`, `seedField`, `seedSuggestion`, `seedTypes`, `seedFields`, `seedSuggestions` | One type (`birth_certificate`, icon `type_certificate`), three fields (`document_number`, `record_date`, `issue_date`), one suggestion entry at `source`. `seedType` has `Key, Label, Description, IconKey`; `seedField` has `Key, Label, DataType, Description` |
| Install | `core/database/sourcevocab/sourcevocab.go` `Install`, `ActionInstall`, `ensureSuggestionTx` | `Install(tx *database.Tx) ([]rowchange.Change, error)` composes on the caller's transaction: `metadatafields.UpsertTx` per seed field (no `UnknownText` passed), `sourcetypes.UpsertTx` per seed type, then `ensureSuggestionTx` per suggested field with its index as sort order; returns the changes. `EnsureSuggestion` is gone |
| Suggestion SQL | `sourcevocab.go` `sqlEnsureSuggestion`, `listSuggestions` | Upsert of a join row's `sort_order`; the list reads `ORDER BY j.sort_order, f.label, f.key` |
| Type upsert | `core/database/sourcetypes/sourcetypes.go` `UpsertTx`, `sqlInsert`, `sqlUpdate`, `createChange`, `updateChange`, `rowFields` | `UpsertTx(tx, t Type) ([]byte, []rowchange.Change, error)`: a new row goes in through `sqlInsert` with the three `citation_*` columns NULL and the change `createChange(t, Formats{})` (which already takes formats); an existing row is diffed with `updateChange(existing, next)` over `rowFields` (no format columns) and written with `sqlUpdate`. No hand reprojection |
| Field upsert | `core/database/metadatafields/metadatafields.go` `UpsertTx`, `sqlInsert`, `sqlUpdate` | Writes every input column on insert and update, `f.UnknownText` included (trimmed, "" → NULL) |
| Format storage | `core/database/sourcetypes/formats.go` `ToStored`, `StoredFormatsTx`, `GetFormats`, `formatFieldDiffs`, `Formats` | `ToStored(tx, in, choices, preferOrigin)` parses three key-form texts and rewrites each field to `#id`; diagnostics return empty `Formats`. `formatFieldDiffs` is the one audit of the format columns |
| Key resolution | `metadatafields.ResolveKeysTx` | A key held by several origins resolves to `preferOrigin` |
| Engine | `core/citationformat` `Parse`, `Render`, `Resolver`, `Value`, `Requirements`, `Target`, `Template.Fields` | Pure; `Requirements(tpl)` returns each chain's targets in first-appearance order |
| Seed corpus | `core/citationformat/testdata/seed-formats.txt`; `parse_test.go` `seedFormats`, `TestSeedFormatsParse`; `fuzz_test.go` `FuzzParse` | 66 lines (`form<TAB>text`): map § 6.8's 22 distinct format sets, one line each, in the order census, birth certificate, church register, record book, passenger list, case file, manuscript, government file, grave marker, family Bible, photograph, private papers, DNA, GEDCOM, interview, correspondence, book, journal article, newspaper, website, statute, court report. `FuzzParse` adds them as fuzz seeds |
| Icons | `core/database/sourcetypes/icons.go` `ValidIconKeys` | Includes every icon D-2 uses |
| Create path | `core/onboarding/ready.go` `createCatalog` | Runs `sourcevocab.Install` in one `writes.Call` with `sourcevocab.ActionInstall` |
| Tests reading the seed | `core/database/sourcevocab/sourcevocab_test.go` `TestInstall` (helper `install`; eight cases, three of them counting today's 1 type and 3 fields: "empty catalog gets trimmed seed", "install twice keeps same ids" (`len(types) != 1`), "install records one revision" (one `source_type` and three `metadata_field` changes and search documents); two delete `birth_certificate`'s `issue_date` suggestion and expect 2 left: "a second install does not restore a deleted suggestion", "deleted suggestion join stays deleted without reinstall"); `core/database/sourcevocab/sourcevocabtest/sourcevocabtest.go` `Install` (the test helper, `writes.Call` around `Install`); `core/onboarding/complete_test.go` (asserts `len(types) == 1`); `core/onboarding/ready_test.go` (looks up `birth_certificate`); `core/database/sourcemetadata/sourcemetadata_test.go` `testWorld` (calls `sourcevocabtest.Install`), `birthOfAlice`, 7 lookups of `birth_certificate` and 33 lines naming `document_number`, `record_date` or `issue_date`, all assuming those three suggested in that order; `api/ffi/handlers/harness_test.go` `sourceFixture` (takes `types.Types[0]` of `ListSourceTypes`, ordered by label: Birth certificate today, Archived manuscript with this seed; about 90 handler tests use it; none names `document_number`, `record_date` or `issue_date`); `core/database/sourcemetadata/testdata/draft_board_scenarios.json` (shared with `macos/ProvenenciaTests/MetadataDraftHostParityTests.swift`); `core/database/evidencegraphs/evidencegraphstest/evidencegraphstest.go` (calls `sourcevocabtest.Install`, then looks up `birth_certificate`); test fixtures make types and fields through `core/database/sourcetypes/sourcetypestest` `Upsert`, `core/database/metadatafields/metadatafieldstest` `Upsert` and, inside `package sourcetypes`, `core/database/sourcetypes/upsert_test.go` `upsert` | All assume today's one-type, three-field seed |
| Docs | `docs/seeded-vocabulary.md` § 1 "Implementation (Source seed today)", §§ 2.1 – 2.3; `.agents/skills/add-seeded-vocabulary/SKILL.md` "Source vocabulary" | Describe the one-type starter and a horizon list that this seed replaces |

**Precedent.** S15-06 ([#782](https://github.com/Jake-Robins-Studios/provenencia/pull/782)) reshaped `seedSuggestion` to one entry per (type, level) with `FieldKeys` in order; keep that shape. S15-15 ([#871](https://github.com/Jake-Robins-Studios/provenencia/pull/871)) wrote `ToStored` "the one storage step for the editor's write and for seeding": call it, do not resolve keys by hand. `subjectvocab`'s `TestInstallMatchesRegistry` checks the installed rows against the registry; copy that style for AC-1.1.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | The registry splits into three files of `package sourcevocab`: `registry.go` keeps the three struct types and `seedTypes` (with their formats); `registry_fields.go` *(new)* holds `seedFields`; `registry_suggestions.go` *(new)* holds `seedSuggestions`. Order in each list follows map § 6.8's tables | About 700 lines of data; one file per list keeps diffs readable | One file — hard to review; a data file (JSON) — the registry is Go by the skill's rule |
| D-2 | The 26 types, in map § 6.8's order, with these labels, icons and descriptions: see **§ 6 Types table**. `birth_certificate` keeps its key; its description is replaced | Map § 6.8 gives keys and labels; icons come from the existing set | Leaving the old `birth_certificate` description — it ends in an abbreviation list and does not match the others |
| D-3 | The 63 fields, with these labels, data types, descriptions and unknown texts: see **§ 6 Fields table**. `url` is `url`; every other field is `text`. Only `publication_place` and `publisher` have unknown text, "n.p.". Two seeded fields are read by no seeded format, as map § 6.8 lists them: `database_title` (suggested on record types' Artifacts) and `record_id` (suggested nowhere; there for researchers' formats). `record_date` and `issue_date` leave the registry: a new catalog does not have them; an existing catalog keeps its rows because Install never deletes | Map § 6.8 "Fields" lists 63 keys and says the date keys are not seeded; "stay as fields so existing values are kept" holds without seeding them | Seeding them unused on every new project — 65 fields where the map counts 63, two that no format reads |
| D-4 | `seedSuggestions` are hand-listed, one entry per (type, level) with at least one field, in **§ 6 Suggestion rule** order. A test derives the same lists from the formats and fails on any difference (user, 2026-11-17: hand-listed plus a test) | The registry stays declarative and readable; the test makes the map's "cannot drift" true | Deriving at Install — the user chose the hand list |
| D-5 | Each type's three formats are its `Formats sourcetypes.Formats` field on `seedType`, written with keys, one line each. Twenty-two of the 26 are map § 6.8's text, taken line for line from `core/citationformat/testdata/seed-formats.txt` (the same text joined onto one line) before STEP-7 deletes it. The other four come from D-6's shared builders and **§ 6 Derived formats** | One source of truth; the corpus is already joined and parse-tested | Retyping from the wrapped map — line joins are where typos come in |
| D-6 | The three certificates share one text: `certificateFormats(word, plural string) sourcetypes.Formats` *(new, in `registry.go`)* builds `birth_certificate`'s formats from the corpus text with "birth certificate" / "Birth certificates" as parameters, and `marriage_certificate` and `death_certificate` call it with "marriage certificate", "Marriage certificates" and "death certificate", "Death certificates". `journal_article` and `broadcast` share one package var `journalArticleFormats`. `oral_testimony` is `interview`'s with the interviewer optional and its own word in the short note (§ 6 Derived formats) | Map § 6.8: "each with its own word", "with `interview by` inside an optional group", "broadcast: `published_in` is the programme, `publisher` the network". A later edit to the certificate or article pattern happens once (plan review M-4) | Three written-out certificate copies and two article copies — a fix to one misses the others; an oral testimony short note reading "interview" — informal testimony is not an interview |
| D-7 | Install stores formats on its transaction, after every field: for each `seedType`, `sourcetypes.ToStored(tx.Tx, t.Formats, nil, vocabkey.OriginProvenencia)`; any diagnostic returns `fmt.Errorf("sourcevocab: seed type %s: %v: %w", t.Key, diags, ErrInvalid)` and rolls the whole install back. The stored `Formats` go to `sourcetypes.UpsertTx` | `ToStored` is the one storage step (S15-15); `preferOrigin` `provenencia` makes AC-2.3 true; a bad seed must fail create loudly, and STEP-6's tests catch it first | Resolving keys in sourcevocab — a second copy of `ToStored`; skipping a bad format — a silent hole in the product seed |
| D-8 | `sourcetypes.UpsertTx` gains a third parameter `formats *Formats` (stored form). Nil leaves the stored formats as they are; non-nil sets all three. The write and its audit go through one unexported step pulled out of `UpdateFormats`' tail into `formats.go`, `writeStoredTx(tx *database.Tx, typeID []byte, next Formats) (map[string]rowchange.FieldDiff, error)` *(new)*: `StoredFormatsTx`, `formatFieldDiffs`, then `sqlUpdateFormats` only when something differs. `UpdateFormats` calls it. On insert, `UpsertTx` passes the formats (or none when nil) to `sqlInsert`, which already takes the three format columns, and builds its change with `createChange(t, formats)`, which already carries them; on an existing row, in this order: compute the format diffs with `writeStoredTx` (nil formats: no diffs), build the change with `updateChange(existing, next, diffs)`, and run `sqlUpdate` only when a row column (label, description, icon) differs; no change when neither differs. `updateChange` gains a third parameter `formats map[string]rowchange.FieldDiff` merged before its empty check, mirroring `createChange(t, formats)`: `Update` passes nil, and `UpdateFormats` keeps the `Type` `editableTx` returns and builds its change as `updateChange(existing, existing, fields)` instead of by hand, so each action has one builder (refresh review R-M1). `UpsertTx`'s doc comment says nil formats keep what is stored and non-nil sets all three. `metadatafields.UpsertTx` already writes `Field.UnknownText` (S15-52 D-2), so the seed only fills it. `sourcetypestest.Upsert`, `core/database/sourcetypes/upsert_test.go` `upsert`, the `run` helper of `sourcetypes_test.go` `TestUpsertTx` and `core/database/effects/source_type_search_test.go`'s upsert case pass nil formats (one line each); the test fixtures that upsert a `provenencia` type `book` (`evidencelayertest.go`, `graphcachetest.go`, `scaleseed.go`) leave formats alone. | One place writes and audits the format columns, so S15-17's editor and the seed cannot diverge; nil keeps a test fixture from wiping a seeded type's formats (plan review M-1). | A `Formats` value parameter written in `sqlUpsert` — a second read, compare and write of the format columns beside `UpdateFormats`, and a zero value that clears; a separate format call from Install — two changes for one type row |
| D-9 | `TestSeedCitations` *(new)* renders every type's three formats twice: from the **full fixture** (every field and built-in answered, **§ 6 Fixture**) and from the **bare fixture** (only `source.title` and `source.date`). It reads the stored (by-id) formats from an installed catalog through `StoredFormatsTx`, so it also proves Install's ids; the resolver maps a `#id` to its key through a map built from `metadatafields.List`. The text of a render is its runs in order, each italic run written `*text*` (`Render` already merges adjacent runs of one style and drops empty ones). Expected text lives in `core/database/sourcevocab/testdata/seed-citations.txt` *(new)*, one line per (type, fixture, form): `<type key><TAB><full|bare|nopage><TAB><form><TAB><text>`, the italic runs wrapped in `*…*`, in registry type order. A `-update` flag (`flag.Bool("update", …)` in the test file) rewrites the file; the PR reviewer reads the file | 157 expected lines written by hand would be retyped from the output anyway; a golden file is read once in review and then holds | Expected strings inline in Go — 156 literals that drown the test; one fixture only — the bare run is what shows which groups drop |
| D-10 | Install writes each seeded (type, level) list through `ensureSuggestionTx`, each field's index in `FieldKeys` as its sort order, as today. No reordering of existing rows: Install runs on new catalogs only, and the dogfood projects are updated by hand (user, 2026-11-17: "just make sure that new projects get the correct stuff") | A second run over unchanged rows returns no changes (`ToStored` gives the stored text again, `formatFieldDiffs` reads NULL and "" alike), so `writes.Run` rolls back the identical suggestion upserts and records nothing; T-4's revision count is the assertion that holds this (AC-4.1) | A pass that puts seed rows first on an existing catalog — only a re-run on an old project needs it, which the user ruled out (plan review M2-1, M2-2) |
| D-11 | `sourcemetadata_test.go`'s `testWorld` stops calling `sourcevocabtest.Install`. It writes its own vocabulary with `metadatafieldstest.Upsert`, `sourcetypestest.Upsert` and `sourcevocab.AppendSuggestion` (which numbers 0, 1, 2 in call order): `provenencia` fields `document_number`, `record_date`, `issue_date` (text, labels "Document number", "Record date", "Issue date") and a `provenencia` type `birth_certificate` (label "Birth certificate", icon `type_certificate`) suggesting those three at the Source level in that order. `draft_board_scenarios.json` and every assertion in that file stay as they are. `complete_test.go` replaces `len(types) != 1` with a `Lookup` of `census`. `harness_test.go` `sourceFixture` picks the type whose `key` is `birth_certificate` and `origin` `provenencia` instead of `Types[0]`, so the handler tests keep the type they had; a handler test that asserts that type's suggestion lists is updated to AC-1.3's lists. `api/ffi/handlers/sources_test.go` `metadataSetFixture` (first `text` field of `ListMetadataFields`) and the user fields and types whose keys now twin seeded ones ("Folio" in `source_defs_test.go`, "Census" in `TestCopySourceType`) stay: keys are unique per origin; `urlMetadataSetFixture`'s comment "the seeded fields are all text" is reworded to "the fixture's fields" only if its test fails. The other tests that take `Types[0]` (`api/ffi/handlers/cover_test.go`, `search_catalog_test.go`, `evidence_graphs_test.go` `graphFixture`, `evidence_graph_progress_test.go`, and `core/search/search_test.go` if it does) stay on `Types[0]`: they use the type as any type; one that fails because it asserts that type's label or suggestions switches to the `birth_certificate` lookup `sourceFixture` uses. `ready_test.go` and `evidencegraphstest.go` need no change (`birth_certificate` is still seeded) | Those tests are about the board's merge rules, not the product seed; pinning them to their own vocabulary keeps the Swift parity file untouched | Rewriting ~28 assertions to the new birth certificate — churn in tests that do not test the seed |
| D-12 | No command, flag or harness runs `Install` against an existing project, and the plan makes no promise about what a re-run on an old project does beyond AC-4.1 (user, 2026-11-17: the product owner updates the dogfood projects by hand) | The user's answer | A one-off command or a defined re-run behavior — not needed |
| D-13 | Delete `core/citationformat/testdata/seed-formats.txt`, `seedFormat`, `seedFormats` and `TestSeedFormatsParse` from `parse_test.go`, and the `seedFormats(f)` loop from `FuzzParse`, which instead adds `censusFull` and `censusShort` (already in `render_test.go`, same package) with `f.Add(…, string(citationformat.FormFull))` and `FormShort`. Drop `"os"` from `parse_test.go`'s imports if nothing else uses it. Reword the comment above `censusFull` in `render_test.go` to "a census format written out for the engine tests" | The map's Check deletes the corpus; `TestSeedCitations` and Install's D-7 error parse every seeded format; the fuzzer keeps two realistic nested seeds (`.cursor/rules/go-tests.mdc` "Fuzz targets"; plan review M-6) | Importing sourcevocab into the pure package's fuzz test — couples the engine's tests to the database |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `seedType.Formats`, `seedField.UnknownText` | struct fields | `sourcetypes.Formats`, `metadatafields.Field.UnknownText` | Reused: the seed fields are those types |
| `registry_fields.go`, `registry_suggestions.go` | files | `registry.go` | Split for size (D-1) |
| `writeStoredTx` | func | `UpdateFormats`' tail | Pulled out of it, not new logic (D-8) |
| `certificateFormats`, `journalArticleFormats` | func, var | — | Shared text for the types D-6 names |
| `formats *Formats` parameter of `sourcetypes.UpsertTx` | param | `CreateInput.Formats`, `UpdateFormats` | Extends S15-52's upsert; writes through `UpdateFormats`' extracted step |
| `TestSeedCitations`, `core/database/sourcevocab/testdata/seed-citations.txt` *(new)*, `-update` flag | test, golden | `core/citationformat/testdata/seed-formats.txt` (deleted here) | The corpus checked parsing only; no golden-flag precedent in the repo (`rg 'flag.Bool\("update"'`), so this adds the standard Go idiom |
| `TestSeedSuggestionsFollowFormats`, `TestSeedFieldsAreRead` (with its `unreadFields` set) | tests | `subjectvocab` `TestInstallMatchesRegistry` | Different rule; same style |
| `testWorld`'s own vocabulary | test fixture | `sourcevocabtest.Install` | D-11 |

**Builds on.** `add-seeded-vocabulary`'s registry and Install; S15-15's `ToStored`; S15-37's `unknown_text`; S15-52's `Install(tx)` and `UpsertTx`.
**Deletes.** `core/citationformat/testdata/seed-formats.txt`, `seedFormat`, `seedFormats`, `TestSeedFormatsParse`, the corpus loop in `FuzzParse` (D-13); the registry's `record_date` and `issue_date` entries (D-3); the old `birth_certificate` description; `docs/seeded-vocabulary.md`'s horizon lists in §§ 2.1 – 2.3 that this seed replaces.
**Next adds.** S15-16 renders these formats with no seed change. S15-17's Insert field lists these fields by level. S15-38 reads the requirements of these formats. A later seed edit is a registry edit; `TestSeedCitations -update` refreshes the golden.

### Types table

| Key | Label | Icon | Description |
| --- | --- | --- | --- |
| `census` | Census | `type_census` | A population, agricultural or other schedule from a government census. |
| `birth_certificate` | Birth certificate | `type_certificate` | A civil certificate or register entry of a birth. |
| `marriage_certificate` | Marriage certificate | `type_certificate` | A civil certificate or register entry of a marriage. |
| `death_certificate` | Death certificate | `type_certificate` | A civil certificate or register entry of a death. |
| `church_register` | Church register | `type_scroll` | A parish register, church book or bishop's transcript of baptisms, marriages and burials. |
| `record_book` | Record book | `type_book` | A deed, will, court, marriage or tax book kept by a public office. |
| `passenger_list` | Passenger list | `type_document` | A ship's manifest or passenger list. |
| `case_file` | Case file | `type_folder_archive` | The loose papers of one court, probate, naturalization or land case. |
| `manuscript` | Archived manuscript | `type_folder_archive` | Letters, diaries, business or institutional records held by an archive. |
| `government_file` | Government file | `type_folder_archive` | A military, pension, passport or agency file held by a national archive. |
| `cemetery_marker` | Grave marker | `type_grave` | A headstone or monument. |
| `family_bible` | Family Bible | `type_book` | The family record pages of a Bible. |
| `photograph` | Photograph | `type_photograph` | A photograph or portrait. |
| `private_papers` | Private papers | `type_document` | Letters, diaries, research notes or a compiled family file in private hands. |
| `dna_match_report` | DNA match report | `type_dna` | A DNA test result or match list. |
| `gedcom_file` | GEDCOM file | `type_gedcom` | A family file exported from genealogy software. |
| `interview` | Interview | `type_oral_history` | A recorded or published interview. |
| `oral_testimony` | Oral testimony | `type_oral_history` | Informal family testimony, told to the researcher or someone else. |
| `correspondence` | Correspondence | `type_email` | A letter or email written to the researcher. |
| `book` | Book | `type_book` | A book, chapter, map, CD or film. |
| `journal_article` | Journal article | `type_newspaper` | An article in a journal, magazine or newsletter. |
| `broadcast` | Broadcast | `type_oral_history` | A radio or television programme, or a podcast. |
| `newspaper_item` | Newspaper item | `type_newspaper` | An article, notice or obituary in a newspaper. |
| `website` | Website or online database | `type_website` | A web page, online database, online tree or memorial site. |
| `statute` | Statute | `type_document` | A statute, session law or code. |
| `court_report` | Court report | `type_book` | A published report of a court case. |

### Fields table

Description shape: what the field holds, then ", as it should appear in a citation", then one invented example in parentheses. Every description below is the exact text.

| Key | Label | Description | Unknown text |
| --- | --- | --- | --- |
| `creator` | Creator | The office, church, company or person that made the record, as it should appear in a citation (Calder County Clerk). | |
| `author` | Author | The author, as it should appear in a citation (Mabel Thorne). | |
| `author_sort` | Author for sorting | The author as a source list sorts it, as it should appear in a citation (Thorne, Mabel). | |
| `editor` | Editor | The editor, as it should appear in a citation (Owen Pryce). | |
| `compiler` | Compiler | The compiler, as it should appear in a citation (Lena Marsh). | |
| `translator` | Translator | The translator, as it should appear in a citation (Ivo Karsk). | |
| `photographer` | Photographer | Who took the photograph, as it should appear in a citation (Silas Pell). | |
| `studio` | Studio | The photographic studio, as it should appear in a citation (Pell Studio). | |
| `interviewer` | Interviewer | Who asked the questions, as it should appear in a citation (Ruth Abernant). | |
| `interviewee` | Interviewee | Who told the story, as it should appear in a citation (Clara Venn). | |
| `recipient` | Recipient | Who the letter or message was sent to, as it should appear in a citation (Harold Venn). | |
| `testing_company` | Testing company | The company that ran the DNA test, as it should appear in a citation (GeneLine Labs). | |
| `software` | Software | The program the file was exported from, as it should appear in a citation (FamilyLedger 4.2). | |
| `jurisdiction` | Jurisdiction | The place the record belongs to, smallest first, as it should appear in a citation (Calder County, Westmark). | |
| `published_in` | Published in | The newspaper, journal, programme or statute book, as it should appear in a citation (Calder Valley Gazette). | |
| `publisher` | Publisher | The publisher or network, as it should appear in a citation (Ashby Press). | n.p. |
| `publication_place` | Place of publication | Where it was published, as it should appear in a citation (Port Ellis). | n.p. |
| `edition` | Edition | The edition, as it should appear in a citation (2nd ed.). | |
| `series` | Series | The series, as it should appear in a citation (Calder County Records Series). | |
| `volume` | Volume | The volume, as it should appear in a citation (3). | |
| `issue` | Issue | The issue number, as it should appear in a citation (12). | |
| `page_range` | Pages | The pages the whole item runs over, as it should appear in a citation (41–58). | |
| `site_name` | Site name | The website's name, as it should appear in a citation (Calder Archives Online). | |
| `short_title` | Short title | A shorter title for later notes, as it should appear in a citation (Calder Register). | |
| `coverage` | Years covered | The span the record covers, as it should appear in a citation (1850–1899). | |
| `repository` | Repository | Who holds the original, and where, as it should appear in a citation (Calder County Archives, Port Ellis). | |
| `collection` | Collection | The collection or record series, as it should appear in a citation (Venn Family Papers). | |
| `record_group` | Record group | The archive's record group, as it should appear in a citation (45). | |
| `call_number` | Call number | The archive's call number or shelf mark, as it should appear in a citation (MS 1123). | |
| `box` | Box | The box, as it should appear in a citation (4). | |
| `folder` | Folder | The folder, as it should appear in a citation (17). | |
| `document_number` | Document number | The certificate or document number, as it should appear in a citation (1880-0412). | |
| `book` | Book | The record book's name, as it should appear in a citation (Deed Book F). | |
| `case_number` | Case number | The case or file number, as it should appear in a citation (no. 2231). | |
| `enumeration_district` | Enumeration district | The census enumeration district, as it should appear in a citation (236). | |
| `schedule` | Schedule | Which census schedule, as it should appear in a citation (population schedule). | |
| `piece` | Piece | The archive's piece number, as it should appear in a citation (1047). | |
| `chapter` | Chapter | The chapter, as it should appear in a citation (88). | |
| `section` | Section | The section, as it should appear in a citation (4). | |
| `lot` | Lot | The cemetery lot, as it should appear in a citation (112). | |
| `kit_number` | Kit number | The DNA kit number, as it should appear in a citation (GL-55120). | |
| `match_identifier` | Match | The match's name or kit as the report gives it, as it should appear in a citation (R. Venn). | |
| `holder` | Held by | Who holds a privately held original, and where, as it should appear in a citation (held in 2025 by Clara Venn, Port Ellis). | |
| `medium` | Medium | What the item is made of or how it was made, as it should appear in a citation (cabinet card). | |
| `format` | Format | What kind of copy you used, as it should appear in a citation (digital image). | |
| `provider` | Provider | Who provides the copy, as it should appear in a citation (Westmark Heritage). | |
| `database_title` | Database | The database or collection title at the provider, as it should appear in a citation (Calder County Censuses, 1850–1900). | |
| `url` | URL | The address of the copy you used, as it should appear in a citation (https://example.org/calder/1880). | |
| `accessed_date` | Accessed | When you viewed it, as it should appear in a citation (12 March 2025). | |
| `citing` | Citing | What the provider says its copy was made from, as it should appear in a citation (county film 7, item 3). | |
| `film_publication` | Film publication | The microfilm publication, as it should appear in a citation (Westmark microfilm publication W12). | |
| `roll` | Roll | The microfilm roll, as it should appear in a citation (393). | |
| `film_number` | Film number | The film number, as it should appear in a citation (1022345). | |
| `item_number` | Item | The item on the film, as it should appear in a citation (3). | |
| `item` | Item cited | What this graph is about, as it should appear in a citation (Ada Robins; baptism of Ada Smith, 3 March 1830). | |
| `entry_number` | Entry | The entry number, as it should appear in a citation (57). | |
| `line_number` | Line | The line number, as it should appear in a citation (14). | |
| `dwelling_number` | Dwelling | The dwelling number, as it should appear in a citation (112). | |
| `family_number` | Family | The family number, as it should appear in a citation (118). | |
| `schedule_number` | Schedule number | The schedule or household schedule number, as it should appear in a citation (9). | |
| `folio` | Folio | The folio, as it should appear in a citation (22). | |
| `column` | Column | The column, as it should appear in a citation (3). | |
| `record_id` | Record ID | The record's identifier at its source, as it should appear in a citation (R-77810). | |

**Usual level** (for D-4's rule and the fixture): the "The copy" group of map § 6.8 (`format`, `provider`, `database_title`, `url`, `accessed_date`, `citing`, `film_publication`, `roll`, `film_number`, `item_number`) is `artifact`; "The item" group (`item`, `entry_number`, `line_number`, `dwelling_number`, `family_number`, `schedule_number`, `folio`, `column`, `record_id`) is `graph`; every other field is `source`. The table lives in the test file (`usualLevel`, built from those two key lists, every other seeded key `source`), not in the registry: Install never reads it. `TestSeedCitations` opens its read transaction with `db.Begin()` on `c.DB()` (allowed inside `core/database`) for `StoredFormatsTx`.

### Suggestion rule

For each type, walk `citationformat.Requirements(Parse(full))` in order; for every target that is a metadata field (`Field.Key != ""`), take the field once, at its first appearance:

1. Its level is the field's usual level when the full format reads it at that level anywhere; otherwise the level of its first appearance (so `website` suggests `url` and `accessed_date` on the Source, map § 6.8's first exception).
2. Append it to that level's list. A field's position is its first appearance in the format at any level (its first target in `Requirements` order), not its first appearance at the chosen level.

Then, for the **record types** (`census`, `birth_certificate`, `marriage_certificate`, `death_certificate`, `church_register`, `record_book`, `passenger_list`, `case_file`, `manuscript`, `government_file`; map § 6.8's second exception), append to the Artifact list every copy-group field not yet in it, in the copy group's order above. AC-1.2 and AC-1.3 are this rule's output for two types. A (type, level) with no field has no `seedSuggestion` entry. The record-type set lives in the test (`recordTypes`); it is how the hand lists were written.

### Derived formats

```text
marriage_certificate
full:  [{source.meta.creator}, ]marriage certificate[ no. {source.meta.document_number}][ ({source.date:full})][, {graph.meta.item|source.meta.item}][, vol. {source.meta.volume}][, p. {citation.page}][, entry {graph.meta.entry_number|source.meta.entry_number}][; {artifact.meta.format}, *{artifact.meta.provider}*][ ({artifact.meta.url}[ : accessed {artifact.meta.accessed_date}])][; {source.meta.repository}].
short: [{source.meta.creator}, ]marriage certificate[ no. {source.meta.document_number}][, {graph.meta.item|source.meta.item}].
list:  {source.meta.jurisdiction}.[ {source.meta.creator}.] Marriage certificates.[ {source.meta.repository}.]

death_certificate: the same with "death certificate" and "Death certificates."

oral_testimony
full:  {source.meta.interviewee}[ ({source.meta.jurisdiction})][, interview by {source.meta.interviewer}], {source.date:full}[, {graph.meta.item|source.meta.item}][; {source.meta.holder}].
short: {source.meta.interviewee}, oral testimony, {source.date:full}.
list:  {source.meta.interviewee}.[ Interview by {source.meta.interviewer}.][ {source.meta.jurisdiction},] {source.date:full}.[ {source.meta.holder}.]

broadcast: journal_article's three lines unchanged.
```

### Fixture

`TestSeedCitations`'s resolver answers every field target **at every level** with the field's value below (so a chain takes its first option), `source.title` with the type's title, `source.date` with `datevaluetest.YMD(1880, 6, 14)`, `citation.page` with "14", and nothing else. The bare fixture answers only `source.title` and `source.date`, so every `{a|source.title}` chain shows its fallback there. A third, **page-range** case renders `court_report`'s full form with every field but no `citation.page`, so the golden shows its `page_range` fallback (one more golden line, fixture name `nopage`). Values are invented (rule "never copy the book").

- **Field values:** a 63-entry map in `render_test.go` (not parsed from descriptions) holding each field's example from the Fields table's description, in the parentheses, except `item` = "Ada Robins" and `creator` (per type below). `publisher` = "Ashby Press", `publication_place` = "Port Ellis".
- **`creator` per type:** `census` "Westmark"; the three certificates "Calder County Clerk"; `church_register` "St. Brendan's Church, Port Ellis"; `record_book` "Calder County Recorder"; `passenger_list` "Port Ellis Customs House"; `case_file` "Calder County Court"; `manuscript` "Ellis Trading Company"; `cemetery_marker` "Hillcrest Cemetery"; `private_papers`, `correspondence` "Clara Venn"; `gedcom_file` "Mabel Thorne"; `website` "Calder Historical Society"; every other type "Calder County Clerk".
- **`source.title` per type:** `census` "1880 census of Calder County"; certificates "Register of births" / "Register of marriages" / "Register of deaths"; `church_register` "Baptisms and burials, 1850–1899"; `record_book` "Deeds, 1878–1882"; `passenger_list` "Passengers of the SS Marigold, June 1880"; `case_file` "Venn v. Thorne"; `manuscript` "Letter book of Ellis Trading Company"; `government_file` "Pension file of Harold Venn"; `cemetery_marker` "Grave of Ada Robins"; `family_bible` "Venn family Bible"; `photograph` "Portrait of Ada Robins"; `private_papers` "Notes on the Venn family"; `dna_match_report` "Match list for Clara Venn"; `gedcom_file` "Venn family tree"; `interview`, `oral_testimony` "Clara Venn on her grandmother"; `correspondence` "Letter about Ada Robins"; `book` "The Families of Calder County"; `journal_article`, `broadcast` "Ada Robins and the Calder flood"; `newspaper_item` "Death of Ada Robins"; `website` "Ada Robins memorial"; `statute` "An act to divide Calder County"; `court_report` "Venn v. Thorne".

### Reach

None — no new path into existing code. A new catalog holds more types and fields, which every existing list and picker already reads.

### Scale

At create: 63 field upserts, 26 type upserts with one `ToStored` each (three parses, one batched key read), about 400 suggestion rows, all in `createCatalog`'s one `writes.Call`; search reprojects 89 documents through the effects registry. The map's Scale line (26 types, 63 fields) is the whole input; nothing grows with the researcher's data. The create path is measured once in STEP-5's check (the `TestInstall` subtest "empty catalog gets the seed" under `-v`; under one second).

### Edges

- **Assumptions.** `listSuggestions` assumes one row per sort order for a stable order; a new catalog's lists are numbered from 0 with no gap (T-12). `ToStored` assumes no key is held by two origins unless `preferOrigin` picks one; a user twin is the case (T-7). `formatFieldDiffs` treats "" as NULL; a seeded format is never empty (T-3).
- **Neighbors.** A user type with a seeded key (`census`, user origin) is left alone, as `TestInstall`'s "user origin twin" case shows for `birth_certificate` today.
- **Removed inputs.** None — Install runs on new catalogs only (D-12); a deleted product row stays deleted, as the kept `TestInstall` cases show.
- **Real data.** The whole shipped table is the test input: T-3 parses and stores every format, T-8 renders all 26 × 3 forms twice. Worth a second look in review: the certificates' and `statute`'s list formats read `jurisdiction`, which the full-format rule does not suggest; `book` writes `{citation.page}` with no "p."; `court_report` falls back from `{citation.page}` to `page_range`.
- **Untrusted size.** None — the seed is compiled-in data.

### Schema

None — no catalog change. S15-15 and S15-37 added the columns this writes.

### Go core

| Package | Change |
| --- | --- |
| `core/database/sourcevocab` | `registry.go`: `seedType` gains `Formats sourcetypes.Formats`; `seedField` gains `UnknownText string`; 26 `seedTypes` (D-2, D-5, D-6). `registry_fields.go` *(new)*: 63 `seedFields` (D-3). `registry_suggestions.go` *(new)*: `seedSuggestions` (D-4). `sourcevocab.go` `Install`: `UnknownText` into the field upsert; `ToStored` and the formats argument per type (D-7); the suggestion loop unchanged (D-10) |
| `core/database/sourcetypes` | `formats.go`: `writeStoredTx` *(new, unexported)* pulled out of `UpdateFormats`, which calls it and builds its change through `updateChange`. `sourcetypes.go`: `updateChange(prev, next, formats)` takes format diffs; `UpsertTx(tx, t, formats *Formats)` writes formats on insert and through `writeStoredTx` on update, and its doc comment says so (D-8) |
| `core/database/metadatafields` | None — S15-52's `UpsertTx` already writes `unknown_text` |
| `core/citationformat` | Test files only (D-13) |

Errors: none new. A seed format that does not store is `sourcevocab.ErrInvalid`, wrapped with the type key (D-7).

### FFI

None — no RPC changes.

### macOS

None — no Swift change. `MetadataDraftHostParityTests.swift` reads `draft_board_scenarios.json`, which D-11 leaves as is.

### Strings

None — catalog data, not app copy. The type and field labels and descriptions are researcher-editable rows, as today's seed.

## 7. Steps

**STEP-1 — The upserts write formats and unknown text**
Files: `core/database/sourcetypes/sourcetypes.go` (and `_test.go`), `core/database/sourcetypes/sourcetypestest/sourcetypestest.go` and `core/database/sourcetypes/upsert_test.go` and the `run` helper in `sourcetypes_test.go` `TestUpsertTx` (pass nil), `core/database/sourcetypes/formats.go`, `core/database/effects/source_type_search_test.go`; every other fixture calls `sourcetypestest.Upsert` and needs no change. Skill: `add-catalog-query`.
Do: D-8. Extract `writeStoredTx` from `UpdateFormats` and give `updateChange` its formats parameter first, and run `TestUpdateFormats` and `TestGetFormats` unchanged (they pass); then add `UpsertTx`'s parameter. `core/database/effects/source_type_search_test.go` (its "an upsert label change reprojects the type and its Sources" case calls `UpsertTx` directly) passes nil and gains a case: `UpsertTx` with only new formats → one change with only `citation_*` fields, and no type or Source search documents. `metadatafields` needs no change (S15-52 D-2).
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcetypes/... ./core/database/effects/...` passes, with T-9.

**STEP-2 — The fields**
Files: `core/database/sourcevocab/registry.go`, `registry_fields.go` *(new)*. Skill: `add-seeded-vocabulary`.
Do: `seedField.UnknownText`; the 63 fields of D-3 in the Fields table's order; `record_date` and `issue_date` removed. Pass `UnknownText` to `metadatafields.UpsertTx` in `Install`.
Check: `go build ./...` passes; `TestInstall` fails only on counts and the old `birth_certificate` suggestions (fixed in STEP-5).

**STEP-3 — The types and their formats**
Files: `registry.go`. Skill: `add-seeded-vocabulary`.
Do: `seedType.Formats`; the 26 types of D-2. Copy 22 format sets from `core/citationformat/testdata/seed-formats.txt` (D-5), the certificate text into `certificateFormats` and the journal text into `journalArticleFormats` once (D-6): lines 1–3 `census`, 4–6 `birth_certificate`, 7–9 `church_register`, 10–12 `record_book`, 13–15 `passenger_list`, 16–18 `case_file`, 19–21 `manuscript`, 22–24 `government_file`, 25–27 `cemetery_marker`, 28–30 `family_bible`, 31–33 `photograph`, 34–36 `private_papers`, 37–39 `dna_match_report`, 40–42 `gedcom_file`, 43–45 `interview`, 46–48 `correspondence`, 49–51 `book`, 52–54 `journal_article`, 55–57 `newspaper_item`, 58–60 `website`, 61–63 `statute`, 64–66 `court_report` (each full, short, list); write the four of § 6 Derived formats.
Check: `go build ./...` passes.

**STEP-4 — The suggestions**
Files: `registry_suggestions.go` *(new)*. Skill: `add-seeded-vocabulary`.
Do: one entry per (type, level) by § 6 Suggestion rule, in registry type order, levels Source, Artifact, graph.
Check: `go build ./...` passes (STEP-6 proves the lists).

**STEP-5 — Install stores formats**
Files: `core/database/sourcevocab/sourcevocab.go`, `sourcevocab_test.go`.
Do: D-7, D-10. In `TestInstall` (eight cases): replace "empty catalog gets trimmed seed" with T-12 (AC-1.1 – AC-1.5, AC-2.1, AC-2.2 against the registry; no restated counts except the map's 26 and 63, asserted once against `len(seedTypes)` and `len(seedFields)`); replace "install twice keeps same ids" with T-4. In "install records one revision", the expected changes and search documents become `len(seedTypes)` `source_type` and `len(seedFields)` `metadata_field`. In "a second install does not restore a deleted suggestion" and "deleted suggestion join stays deleted without reinstall", the deleted suggestion becomes `census`'s Source-level `piece` and the expected count 4. Keep "a seed entry naming an unknown type is rejected even with no fields", "deleted provenencia type stays deleted without reinstall" and "user origin twin left alone" as they are. Add T-7.
Check: `CGO_ENABLED=1 go test -tags fts5 -run TestInstall -v ./core/database/sourcevocab/` passes; the subtest "empty catalog gets the seed" (one Install on an empty catalog) reports under one second.

**STEP-6 — The registry follows its own rules**
Files: `core/database/sourcevocab/registry_test.go` *(new)*.
Do: T-1, T-2, T-3.
Check: `CGO_ENABLED=1 go test -tags fts5 -run 'TestSeed' ./core/database/sourcevocab/` passes. A deliberate swap of two fields in one census suggestion list fails T-1 (try it, then revert).

**STEP-7 — Render every seeded format; drop the corpus**
Files: `core/database/sourcevocab/render_test.go` *(new)*, `testdata/seed-citations.txt` *(new)*, `core/citationformat/parse_test.go`, `core/citationformat/fuzz_test.go`, `core/citationformat/testdata/seed-formats.txt` (deleted).
Do: T-8 (D-9); generate the golden with `-update`; read it; confirm the census lines equal AC-3.1 and AC-3.2. Then D-13.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcevocab/... ./core/citationformat/...` passes; `rg -n "seed-formats|seedFormats|TestSeedFormatsParse" core` finds nothing.

**STEP-8 — Tests that read the old seed**
Files: `core/database/sourcemetadata/sourcemetadata_test.go` (`testWorld`), `core/onboarding/complete_test.go`, `api/ffi/handlers/harness_test.go` (`sourceFixture`).
Do: D-11.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/... ./api/...` passes.

**STEP-9 — Docs**
Files: `docs/seeded-vocabulary.md`, `.agents/skills/add-seeded-vocabulary/SKILL.md`, `docs/deployment-plan/spike-15/completed.md`, `docs/deployment-plan/spike-15/deployment-plan.md` (map row), this plan, `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj`.
Do: `seeded-vocabulary.md` § 1 "Implementation": the seed is map § 6.8's citation vocabulary, installed at create only; existing projects are not updated. §§ 2.1 – 2.3: replace the horizon lists with the 26 type keys, the 63 field keys grouped by usual level, and the suggestion rule with its two exceptions, linking map § 6.8 for the formats. The skill: `seedTypes` carry `Formats` (by key, stored through `ToStored`), `seedFields` carry `UnknownText`, `seedTypes` lists `key`, `label`, `description`, `IconKey`, `Formats` (step 1); `TestSeedCitations -update` refreshes the golden after a format edit; step 6 lists the new `TestInstall` cases and the `TestSeed…` registry tests; "Install semantics (pinned)"'s "one over a renamed product row records an update" becomes "one over a renamed product row, or changed formats or unknown text, records an update"; step 1's `seedFields` line drops its sentence that date-named keys are `text` (no date key is seeded) and adds `UnknownText`; "Prefer a tiny starter set" and the "Do not" line "Expand the full horizon catalog in one PR" each say the Source seed is the exception the Spike 15 rule "The seed is the product default" decided. `docs/source-layer-data-model.md` and `docs/structured-date-model.md` mention `issue_date` as an example of a dated value and stay. Version bump per the header. Then the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-19-seed-citation-types.md` reports no errors; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/sourcevocab/registry_test.go` `TestSeedSuggestionsFollowFormats` *(new)* | For each `seedType`, § 6 Suggestion rule over its full format → equals its `seedSuggestions` entries (levels and order); no entry names an unknown type or field; no (type, level) appears twice | D-4, AC-1.2, AC-1.3 |
| T-2 | Go | `registry_test.go` `TestSeedFieldsAreRead` *(new)* | Every field key any seeded format reads is in `seedFields`; every `seedField` is read by some seeded format, except the two the test names in `unreadFields` (`database_title`, suggested on record types' Artifacts by the copy-group exception, and `record_id`, in map § 6.8's item group for researchers' own formats; no seeded format reads either); keys unique; `url` is the only `url` field; only `publication_place` and `publisher` have unknown text, "n.p." | D-3, AC-1.4, AC-1.5 |
| T-3 | Go | `registry_test.go` `TestSeedTypes` *(new)* | Each type: unique key, label and description non-empty, icon in `sourcetypes.ValidIconKeys`, three non-empty formats that `citationformat.Parse` takes with no diagnostics, and a list form that reads the Source only | D-2, D-5, D-6 |
| T-12 | Go | `sourcevocab_test.go` `TestInstall` "empty catalog gets the seed" (replaces "empty catalog gets trimmed seed") | Install → 26 types and 63 fields match the registry row for row (label, description, icon, data type, unknown text, origin `provenencia`); `census`'s stored formats are all `#id` tokens naming `provenencia` fields; `GetFormats(census)` equals the registry's key-form text with no choices or diagnostics | AC-1.1, AC-2.1, AC-2.2 |
| T-4 | Go | `sourcevocab_test.go` `TestInstall` "install twice changes nothing" (replaces "install twice keeps same ids") | Two `install(c)` calls → `dbtest.Revisions` is 1 after the second; ids, labels, stored formats and sort orders unchanged | AC-4.1 |
| T-7 | Go | `TestInstall` "a user field with a seeded key does not capture a format" *(new case)* | User-origin `author` created first, Install → every `#id` in `book`'s stored formats is a `provenencia` field | AC-2.3, D-7 |
| T-8 | Go | `core/database/sourcevocab/render_test.go` `TestSeedCitations` *(new)* | 26 types × {full, bare} × 3 forms, plus `court_report` `nopage` full → each equals its golden line; census lines equal AC-3.1, AC-3.2 (asserted literally as well) | AC-3.1 – AC-3.3, D-9 |
| T-9 | Go | `core/database/sourcetypes/sourcetypes_test.go` upsert cases *(new cases)* | `UpsertTx` with formats → stored, and one change carrying the type and the three format columns; same formats again → no change; different formats → one change naming only the changed columns; nil formats on a type that has formats → formats unchanged, no format diff | D-8 |
| T-11 | Go | `core/onboarding/complete_test.go` (edited) | `Complete` → `Lookup(census, provenencia)` succeeds | AC-1.6 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `core/database/sourcemetadata` (D-11), `core/onboarding`, `api/ffi/handlers` tests that count source types or fields on a project made by `Complete`, and search tests that query a fresh project's vocabulary.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none: catalog data only)
- [ ] Sweep: `seed-formats`, `seedFormats`, `TestSeedFormatsParse`, and the registry's `record_date` / `issue_date` entries `rg`'d across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no stale hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none)
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New (no UI)
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] docs/seeded-vocabulary.md §§ 1, 2 and add-seeded-vocabulary updated (STEP-9)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Build the app from this branch and create a new project. Open **Source types**: 26 types, among them Census, Grave marker and Website or online database, each with its icon.
2. Open **Census**: its page shows five Source suggestions (Creator, Jurisdiction, Schedule, Enumeration district, Piece), ten on each Artifact, six on each Evidence graph, in AC-1.2's order.
3. Add a census Source. Its Metadata section suggests the five Source fields. Add an Artifact: the sheet suggests Format, Provider, URL, Accessed and the other copy fields. Open the Default graph's form: it suggests Folio, Schedule number, Dwelling, Family, Line, Item cited.
4. Open **Metadata**: Publisher and Place of publication are listed with their descriptions. (Their unknown text is not shown until S15-46.)

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A typo in a 400-character format | T-3 parses each one; D-7 fails create; T-8's golden is read by a person |
| Golden text written without being read | DoD: the census lines are asserted literally too; the reviewer reads the file |
| A wording in the seed copies the book | Every value and example is invented (§ 6 Fixture); map § 6.8's formats were written for Provenencia; the edition check is the product owner's, before merge |
| Hidden tests depend on one seeded type | § 8 names the likely suites; Stop condition below |

**Stop and report if:**

- `sourcetypes.UpsertTx`, `metadatafields.UpsertTx`, `sourcevocab.Install` or `sourcevocabtest.Install` no longer has the shape § 4 says.
- `ToStored` returns a diagnostic for a format copied from the corpus (a corpus line no longer parses).
- `datevalue.CitationDisplay` prints 14 June 1880 other than "14 June 1880" in the long style or "1880" in the year style, so AC-3.1 cannot hold.
- More than the files § 4 and § 8 name fail because of the seed's shape, and the fix is more than a `Lookup` or a fixture line.
- A test needs `record_date` or `issue_date` as seeded fields outside `sourcemetadata_test.go`.

## 12. Open questions

None.

## 13. PR

**Title:** S15-19 — Seed the citation types, fields, suggestions and formats
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-19-seed-citation-types.md`.
