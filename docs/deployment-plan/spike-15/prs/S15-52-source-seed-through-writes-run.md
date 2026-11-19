# S15-52 — The Source seed writes through `writes.Run`

**Status:** Landed in [#891](https://github.com/mendahu/provenencia/pull/891) (2026-11-19)
**Spike / slice:** Spike 15 · Slice 4 — Formats as data
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: a Go refactor of the seed's write path; no view draws anything different)
**Board:** —
**Depends on:** —
**Blocks:** S15-19, S16-62
**Branch:** `s15-52-source-seed-through-writes-run`
**Version bump:** none — a preparatory refactor with no change a researcher can see, no wire and no catalog change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-seeded-vocabulary`](../../../../.agents/skills/add-seeded-vocabulary/SKILL.md), [`add-catalog-query`](../../../../.agents/skills/add-catalog-query/SKILL.md), [`add-audit-scope`](../../../../.agents/skills/add-audit-scope/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests)
**Context:** map scope entry S15-52 ([`../deployment-plan.md`](../deployment-plan.md)); working rule "The seed is the product default"; [`core/writes/README.md`](../../../../core/writes/README.md); [`S15-19-seed-citation-types.md`](S15-19-seed-citation-types.md) (the next PR, which builds on this one)
**Planned:** 2026-11-19 against `main` @ `f757b45` (compare with `origin/main` after `git fetch origin main`)
**Review:** [`S15-52-source-seed-through-writes-run.review.md`](S15-52-source-seed-through-writes-run.review.md) — Fits / Ready after 2 rounds; every finding Fixed or Logged; nothing open

**Landed.** `Upsert` was deleted in the same commit that moved its callers, not in STEP-5, and Steps 1-5 landed as one commit; no other difference from the plan.

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

The Source vocabulary seed stops writing beside the catalog's one write path. `sourcetypes.Upsert(c, …)` and `metadatafields.Upsert(c, …)` each write on the catalog's connection outside any transaction and reproject their search document by hand, so the effects registry never sees them: a renamed product type leaves its Sources' search documents with the old type label, nothing is audited, and a failing `Install` leaves half a seed. This PR replaces both with `UpsertTx` functions that run inside `writes.Run` and return row changes, and runs `sourcevocab.Install` as one `writes.Run`. Search follows from the registry, the seed is one audited revision, and a failed install leaves nothing.

**Why now.** S15-19 seeds 26 types and 63 fields and passes formats and unknown text through these upserts (user, 2026-11-17: this PR first). [`core/writes/README.md`](../../../../core/writes/README.md) already names these two as the hand-reprojecting exceptions.

**What stays.** The seed's content (one type, three fields, one suggestion entry). Install runs at create only, from `onboarding.createCatalog`. The subject vocabulary, grade and property seeds keep their own `Upsert`s (S16-62). Every test keeps the fixtures it has: only the function it calls to make them changes.

## 2. User stories

**US-1.** As the engine, every write of a seeded type or field goes through `writes.Run`, so search, audit and the vocabulary list follow from the effects registry.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | `UpsertTx` on a `source_types` key/origin that does not exist (`census`, `provenencia`, label "Census", icon `type_census`) | The row is inserted; one change: `source_type`, `create`, fields `id`, `key`, `origin`, `label`, `icon_key` (and `description` when not empty), as `sourcetypes.Create` records |
| AC-1.2 | `UpsertTx` again with the same values | The same id; no change |
| AC-1.3 | `UpsertTx` with label "Census schedule" on a type (any origin) that has two Sources | One `update` change holding only `label` {"Census" → "Census schedule"}; after the `writes.Run`, the type's search document and both Sources' search documents carry "Census schedule" |
| AC-1.4 | `metadatafields.UpsertTx` on a new `provenencia` field `piece` | One `metadata_field` `create` change with `id`, `key`, `origin`, `label`, `data_type` (and `description` when not empty), as `metadatafields.Create` records |
| AC-1.5 | `metadatafields.UpsertTx` on a field whose stored unknown text is "n.p.", with the same label and description and `UnknownText` "" | One `update` change holding only `unknown_text` {"n.p." → nil}; the column is NULL. With `UnknownText` " n.p. " instead: no change |
| AC-1.6 | Either `UpsertTx` with a blank key or label, or origin `bogus` | `ErrInvalid`; nothing written |
| AC-1.7 | `sourcetypes.UpsertTx` with origin `plugin:acme` | Accepted, as `Upsert` accepts it today |

**US-2.** As the engine, `sourcevocab.Install` is one transaction and one revision.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | `Install` on an empty catalog, inside `writes.Call` with `ActionInstall` as `createCatalog` runs it | One `audit_transactions` row, action `install_source_vocabulary`, `user_id` NULL, holding one create change per seeded type and field; the suggestion rows are written and are not changes |
| AC-2.2 | `Install` a second time, the same way, over unchanged rows | No new `audit_transactions` row; ids, labels and suggestions unchanged |
| AC-2.3 | `Install` with a seed suggestion naming an unknown type | `ErrInvalid`, and the catalog holds no seeded type, field or suggestion |
| AC-2.4 | `onboarding.Complete` | The new project holds `birth_certificate` with its three suggestions, as today |

**US-3.** As a contributor, a test makes a type or a field with the call it made before, through the same path the app writes.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `rg -n "(sourcetypes|metadatafields)\.Upsert\(" core api` and `rg -n "\bUpsert\(c, Type\{" core/database/sourcetypes` | No hit |
| AC-3.2 | `CGO_ENABLED=1 go test -tags fts5 ./core/... ./api/...` | Passes |

## 3. Scope

| In | Covered by |
| --- | --- |
| `sourcetypes.UpsertTx` *(new)*; `Upsert` deleted (D-1, D-3) | STEP-1, AC-1.1 – AC-1.3, AC-1.6, AC-1.7 |
| `metadatafields.UpsertTx` *(new)*; `Upsert` deleted (D-2, D-3) | STEP-2, AC-1.4 – AC-1.6 |
| `sourcetypestest.Upsert`, `metadatafieldstest.Upsert` *(new)*; every test and test-helper caller moved (D-5, D-6) | STEP-3, STEP-4, AC-3.1, AC-3.2 |
| `sourcevocab.Install(tx)` composes on the caller's transaction; `createCatalog` and the test callers run it in one `writes.Call`; `ensureSuggestionTx` *(new)*; `EnsureSuggestion` and both `Upsert`s deleted (D-3, D-4) | STEP-5, AC-2.1 – AC-2.4, AC-3.1 |
| Docs: `core/writes/README.md`, the two package comments, `add-seeded-vocabulary` | STEP-6 |

| Out | Home |
| --- | --- |
| Formats and unknown text in the seed; the new seed content | S15-19 |
| The subject vocabulary, grade and property seeds' `Upsert`s and `subjectvocab.EnsureBinding` | S16-62 |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Type upsert | `core/database/sourcetypes/sourcetypes.go` `Upsert`, `sqlUpsert`, `Lookup` | `Upsert(c, t) ([]byte, error)` trims, checks key, label and `vocabkey.ValidOrigin`, normalizes the icon, looks up by (key, origin) on `c.DB()`, then `INSERT … ON CONFLICT(key, origin) DO UPDATE` label, description, icon; then `searchindex.ReprojectSourceType(db, id)`. No change, no audit, no transaction |
| Type create and update | same file `Create`, `Update`, `lookupTx`, `getByIDTx`, `editableTx`, `sqlInsert`, `sqlUpdate` | `Create` builds its create change inline (`id`, `key`, `origin`, `label`, `icon_key`, `description` when set, plus `formatFieldDiffs(Formats{}, in.Formats)`). `Update` builds `label`, `description`, `icon_key` diffs inline with `database.NullString` and returns no change when none differs |
| Field upsert | `core/database/metadatafields/metadatafields.go` `Upsert`, `sqlUpsert`, `Lookup` | Same shape as the type upsert; `sqlUpsert` also sets `data_type` on conflict; then `searchindex.ReprojectMetadataField(db, id)` |
| Field create and update | same file `Create`, `Update`, `lookupTx`, `getByID` | `Create` writes through `sqlUpsert` and builds its change inline (`id`, `key`, `origin`, `label`, `data_type`, `description` when set). `Update` diffs `label`, `description`, `unknown_text` inline (trim; `database.NullString`) |
| Install | `core/database/sourcevocab/sourcevocab.go` `Install`, `EnsureSuggestion`, `sqlEnsureSuggestion` | Calls `metadatafields.Upsert`, `sourcetypes.Upsert`, then `EnsureSuggestion(c, …)` (raw `db.Exec`) per field. Not transactional: an error leaves the earlier rows |
| Write path | `core/writes/run.go` `Run`, `Call`, `Op` | One transaction; an empty change list rolls back; changes are audited (`audit.Record`, nil `UserID` → NULL) and search reprojected from `effects.Resolve` |
| Effects | `core/database/effects/registry.go` `"source_types"`, `"source_metadata_fields"`, `"source_type_metadata_fields"` | Types: `DocSourceType` on label, description or icon; `DocSource` of the type's Sources on label or icon; `ListSourceVocabulary`. Fields: `DocMetadataField` `self()`. The suggestion join is `None` with no `Entity` |
| Callers | `rg -n "(sourcetypes|metadatafields)\.Upsert\(" core api` and `rg -n "\bUpsert\(c, Type\{" core/database/sourcetypes` and unqualified `Upsert(c, Type{` in `core/database/sourcetypes/*_test.go` | About 143 calls: one production (`Install`); four in non-test helper packages (`core/database/evidencelayer/evidencelayertest/evidencelayertest.go` ×2, `core/database/graphcache/graphcachetest/graphcachetest.go`, `core/database/evidencegraphs/evidencegraphstest/scaleseed.go`); the rest in 43 `_test.go` files across `core/database/*`, `core/search`, `core/writes` and `api/ffi/handlers`. `core/database/sourcetypes/sourcetypes_test.go` and `formats_test.go` are `package sourcetypes` and call `Upsert` unqualified |
| Upsert's own tests | `core/database/sourcetypes/sourcetypes_test.go` `TestUpsertLookupList`; `core/database/metadatafields/metadatafields_test.go` `TestUpsertLookupList` | Test insert, same id on a second call, origin twins and invalid input through `Upsert` |
| Install tests | `core/database/sourcevocab/sourcevocab_test.go` `TestInstall` | Six cases; "a seed entry naming an unknown type is rejected even with no fields" checks only the error |
| Search gate test | `core/database/effects/source_type_search_test.go` `TestSourceTypeSearchGates` | Resolves `Update` and `UpdateFormats` changes; never an upsert |
| Docs | `core/writes/README.md` (last paragraph: "Source-type and metadata-field `Upsert` stay the un-audited seed path and still reproject by hand"); package comments of `sourcetypes` and `metadatafields` ("Upsert is the un-audited seed path"); `.agents/skills/add-seeded-vocabulary/SKILL.md` "Install semantics (pinned)" | Describe today's path |

**Precedent.** `core/database/artifacts/artifactstest` `Create(c, userID, in) (Artifact, error)`: a test helper package that wraps the tx function in `writes.Call` and returns the error, so callers keep their own `if err != nil`. Copy that shape. `core/database/subjectvocab/subjectvocab.go` `ActionAssign` for an exported action constant.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `sourcetypes.UpsertTx(tx *database.Tx, t Type) ([]byte, []rowchange.Change, error)` *(new)*. Same validation as today's `Upsert` (trim; key, label non-empty; `vocabkey.ValidOrigin`; `NormalizeIconKey`); a non-empty `t.ID` is `ErrInvalid` (no caller sets it, and the row is found by key and origin). Looks up by (key, origin) with `lookupTx`. **Missing:** mint a UUIDv7 and insert with `sqlInsert`, the one insert `Create` already uses, formats NULL; `sqlUpsert` is deleted. **Present:** build `next` from the stored row plus the input's label, description and icon, write with `sqlUpdate` only when the update change is not nil. Changes come from one column list (D-9). No hand reprojection | One insert and one update statement per table; the effects registry reprojects the type and, on a label or icon change, its Sources (AC-1.3); S15-19 puts a new type's formats in the same insert (plan review M-1) | Reusing `Create` — it mints a user-origin kebab key and refuses duplicates; keeping `sqlUpsert` — a second insert statement whose conflict branch can no longer fire |
| D-2 | `metadatafields.UpsertTx(tx *database.Tx, f Field) ([]byte, []rowchange.Change, error)` *(new)*, the same shape. It writes every column the input carries: `label`, `data_type`, `description` and `unknown_text` (`f.UnknownText`, trimmed, "" stored as NULL), on insert and on update, so `updateChange` diffs them all from D-9's column list. A new `sqlInsert` *(new)* without an `ON CONFLICT` clause takes `(id, key, origin, label, data_type, description, unknown_text)`; `Create` (passing "" unknown text) and `UpsertTx` use it, while today's `Upsert` keeps `sqlUpsert` until STEP-5 deletes both. `sqlUpdate` grows to `UPDATE source_metadata_fields SET label = ?, data_type = ?, description = ?, unknown_text = ? WHERE id = ?`, the one update statement: `Update` passes the stored data type (it already refuses a different one) | One insert, one update and one diff for the table; one meaning per function, as D-10 gives the icon (plan review M2-2). S15-19 then only fills `UnknownText` in its seed fields. The only callers are Install on new catalogs and test fixtures, so writing the input's unknown text clears nothing a researcher typed | Keeping the stored unknown text — `Field.UnknownText` would be an input `UpsertTx` ignores, and S15-19 would reverse it; a second `UPDATE` for the upsert — two writes of one row shape |
| D-3 | `sourcetypes.Upsert` and `metadatafields.Upsert` are deleted, with their `searchindex.ReprojectSourceType` / `ReprojectMetadataField` calls. Those two reprojection functions stay: `searchindex.Reproject` and `RebuildAll` call them | No caller is left once tests move (D-5) | Keeping `Upsert` as a wrapper — a second path the README would still have to name |
| D-4 | `sourcevocab.Install` becomes `Install(tx *database.Tx) ([]rowchange.Change, error)`: a composing write that takes the transaction and never calls `writes.Run`, as `add-catalog-query` says of `core/database/sourcecopy` and `add-seeded-vocabulary` says of `CopyType`. It writes fields (`metadatafields.UpsertTx`), types (`sourcetypes.UpsertTx`) and suggestions through `ensureSuggestionTx(tx *database.Tx, typeID, fieldID []byte, level vocabkey.Level, sortOrder int) error` *(new, unexported)*, which holds `EnsureSuggestion`'s level and id checks and runs `sqlEnsureSuggestion` on the tx, and returns every change. `ActionInstall = "install_source_vocabulary"` *(new, exported const in `sourcevocab.go`)*. `core/onboarding/ready.go` `createCatalog` owns the transaction: `writes.Call(c, writes.Op{Action: sourcevocab.ActionInstall}, …)` around `Install`, no user. `core/database/evidencegraphs/evidencegraphstest/evidencegraphstest.go` and `core/database/sourcemetadata/sourcemetadata_test.go` `testWorld` wrap it the same way; `sourcevocab_test.go` wraps it in a test-file helper `install(c *database.Catalog) error` *(new, in `sourcevocab_test.go`)*. `EnsureSuggestion(c, …)` is deleted: `core/database/sourcecopy/sourcecopy_test.go` appends its three fields with `sourcevocab.AppendSuggestion` (same order 0, 1, 2; its loop index goes), and the refusal check calls `ensureSuggestionTx` inside `writes.Call` | One transaction, one revision, atomic; one suggestion write. A composing package never calls `Run` (plan review M2-1), so S16-62 can copy the shape for `sourcecredibilitygrades`, which `core/writes` itself depends on. Suggestion rows ride the transaction beside the changes, as `CopyType`'s join copy does. A second Install over unchanged rows returns no changes, so `Run` rolls back and records nothing (AC-2.2) | `Install` calling `writes.Run` itself — against `add-catalog-query`, and an import cycle for S16-62's grades; one `writes.Run` per row — four revisions, partial failure stays; keeping `EnsureSuggestion` for tests — product code only tests call |
| D-5 | Test helper packages *(new)*: `core/database/sourcetypes/sourcetypestest/sourcetypestest.go` `Upsert(c *database.Catalog, t sourcetypes.Type) ([]byte, error)` and `core/database/metadatafields/metadatafieldstest/metadatafieldstest.go` `Upsert(c *database.Catalog, f metadatafields.Field) ([]byte, error)`. Each is `writes.Call(c, writes.Op{Action: "upsert_source_type"}, …UpsertTx…)` (`"upsert_metadata_field"` for fields), the action a string literal as in `artifactstest.Create`, no user. The signatures equal the deleted functions', so a caller changes only its package qualifier and import | Precedent `artifactstest.Create`; the move is mechanical and reviewable | A fatal `t`-taking helper — every caller's error handling would change |
| D-6 | `core/database/sourcetypes`' internal tests (`sourcetypes_test.go`, `formats_test.go`, `package sourcetypes`) cannot import `sourcetypestest` (import cycle). They call `upsert(c *database.Catalog, t Type) ([]byte, error)` *(new)*, a test-file helper in `core/database/sourcetypes/upsert_test.go` with the same body as `sourcetypestest.Upsert`. Their calls to `metadatafields.Upsert` use `metadatafieldstest.Upsert` | Go forbids the cycle; one five-line test-only copy is the cost | An exported non-test `UpsertCatalog` in `sourcetypes` — product code that only tests call |
| D-7 | `TestUpsertLookupList` in both packages keeps its cases; STEP-4 moves its calls to the helper like every other caller. New `TestUpsertTx` table cases cover AC-1.1 – AC-1.7 by calling `UpsertTx` inside `writes.Call` directly, so they need no helper and run in STEP-1 and STEP-2. `Upsert` stays exactly as it is until STEP-4 deletes it: no temporary wrapper, so no step leaves another package red | Each step builds and passes on its own (plan review X-2) | A wrapper over `UpsertTx` in STEP-1 — product code importing `writes` for two steps, and fixtures audited before their counts are fixed |
| D-8 | A test that counts `audit_transactions` or asserts a revision number and now sees extra revisions from a fixture's upsert takes its count as a delta from after the fixture (the pattern `core/database/observations/observations_test.go` uses at its `before` / `after`), not a new literal | Fixtures now audit; a delta does not depend on how many | Bumping literals — breaks again when a fixture changes |
| D-9 | Each package's changes come from one column list, as `core/database/datevalues/datevalues.go` `RowMap`, `CreateChange` and `UpdateChange` do: `rowFields(t Type) map[string]any` *(new, unexported)* (`id` as `database.UUIDString`, `key`, `origin`, `label`, `icon_key`, and `description` only when not empty; for fields `data_type`, and `description` and `unknown_text` only when not empty), so today's audit JSON keys are unchanged (`icon_key` is always present: the column is `NOT NULL`). Create change: `rowchange.FullRow(rowFields(t))` (types add `formatFieldDiffs(Formats{}, formats)`). Delete change: `rowchange.DeletedRow(rowFields(prev))` (types keep their format diffs). Update change: `updateChange(prev, next) *rowchange.Change` *(new, unexported)*, a diff over the union of both maps' keys, a missing key reading nil, `id`, `key` and `origin` never compared; nil when nothing differs. `Create`, `Update`, `Delete` and `UpsertTx` all use them; the inline field maps go | One column list per table drives create, update and delete; S15-19's unknown text and S16-62's copies inherit it (plan review M-4) | Positional `createChange(id, key, origin, label, …)` builders — a seven-string signature, and `Delete` keeps a third copy |
| D-10 | `UpsertTx`'s icon keeps today's `Upsert` meaning: an empty icon is `NormalizeIconKey`'s `DefaultIconKey`, written and diffed like any other value (unlike `Update`, where empty keeps the stored icon). `data_type` is in `metadatafields.rowFields`, so `updateChange` diffs it with the other columns | Callers today rely on `Upsert`'s default; one meaning per function (plan review X-7) | `Update`'s keep-on-empty for the upsert — a re-upsert with no icon would then mean two things |
| D-11 | On a catalog `Install` already wrote, a suggestion row that is missing while every type and field matches is not written back: the closure's suggestion upsert rides a transaction with no changes, which `Run` rolls back. That is the create-only rule ("The seed is the product default": no healing on a later run); on a new catalog every type and field is a create, so the suggestions always commit | No change list carries suggestion rows, by design (D-4); healing is out of scope by rule (plan review X-3) | Making a suggestion row a change — audits rows the app never audits |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `sourcetypes.UpsertTx` | func | `sourcetypes.Upsert`, `Create`, `Update` | Replaces `Upsert`; shares `Create`'s and `Update`'s change builders (D-1) |
| `sourcetypes.rowFields`, `updateChange` | func | `datevalues.RowMap`, `CreateChange`, `UpdateChange`; inline maps in `Create`, `Update`, `Delete` | Same shape as `datevalues` (D-9) |
| `metadatafields.UpsertTx`, `rowFields`, `updateChange` | func | `Upsert`, `Create`, `Update`, `Delete` | Same as above; `sqlUpsert` → `sqlInsert`, `sqlUpdate` gains `data_type` (D-2, D-9) |
| `sourcevocab.ActionInstall`, `ensureSuggestionTx`, `Install(tx)`; `sourcevocab_test.go` `install` | const, func | `EnsureSuggestion` (deleted), `subjectvocab.ActionAssign` | Replaces `EnsureSuggestion` (D-4) |
| `sourcetypestest`, `metadatafieldstest` | packages | `artifactstest`, `subjectvocabtest` | Same pattern (D-5) |
| `core/database/sourcetypes/upsert_test.go` *(new)* `upsert` | test helper | `sourcetypestest.Upsert` | Import cycle (D-6) |

**Builds on.** `writes.Run` and the effects registry's `source_types` and `source_metadata_fields` entries, unchanged.
**Deletes.** `sourcetypes.Upsert` and `sqlUpsert`, `metadatafields.Upsert` and `sqlUpsert` (STEP-5), their hand reprojection; `sourcevocab.EnsureSuggestion`; the inline change maps in `Create`, `Update` and `Delete` of both packages (D-9); the README and package-comment lines that name the un-audited seed path.
**Next adds.** S15-19 passes formats (`*Formats`) and unknown text through these `UpsertTx`s. S16-62 copies this shape for `subjectvocab`, grades and properties.

### Reach

None — no new path into existing code. Fixtures and the seed now reach `writes.Run`, which every researcher write already takes.

### Scale

At create: today's 1 type, 3 fields and 3 suggestion rows in one transaction, one revision, 4 search documents. S15-19's seed (89 rows) is one transaction with 89 changes; `effects.Resolve` handles that per change. Tests: each fixture upsert is one `writes.Call` instead of one `Exec`, about 143 calls across the suite.

### Edges

- **Assumptions.** `writes.Run` assumes no other write is open on the catalog (`database.ErrWriteReentry`); a fixture upsert called inside another write's closure would fail (Stop condition). `effects.Resolve` maps `EntityType` to a table; both changes use the entity names the registry declares (`source_type`, `metadata_field`).
- **Neighbors.** A plugin-origin type or field still upserts (AC-1.7). An existing row upserted with identical values is no change and no revision (AC-1.2, AC-2.2). A field upsert keeps its unknown text (AC-1.5).
- **Removed inputs.** A failed Install no longer leaves partial rows (AC-2.3). A deleted suggestion on a catalog Install already wrote stays deleted on a second Install (D-11, T-4).
- **New state.** A new project now starts at revision 1, an `install_source_vocabulary` revision with a NULL user. The non-test readers of `audit_transactions` (`MAX(revision)` in `core/database/promotealign/promotealign.go` and `core/database/promote/batch.go`, and the activity join in `core/database/graphcache/sql.go`) neither join `users` nor need a user; a `source_type` or `metadata_field` change carries no audit scope, so no Source's "last updated" moves.
- **Real data.** The seed is one type and three fields here; S15-19 runs the full table.
- **Untrusted size.** None — the seed is compiled-in data.

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/sourcetypes` | `UpsertTx`, `rowFields`, `updateChange` *(new)*; `Create`, `Update`, `Delete` build their changes from them; `Upsert` and `sqlUpsert` deleted; package comment: "UpsertTx is the seed's write, run inside writes.Run" |
| `core/database/metadatafields` | `UpsertTx`, `rowFields`, `updateChange` *(new)*; `sqlUpsert` → `sqlInsert`; `sqlUpdate` writes `data_type`; `Create`, `Update`, `Delete` build their changes from them; `Upsert` deleted; package comment as above |
| `core/database/sourcevocab` | `ActionInstall`, `ensureSuggestionTx` *(new)*; `EnsureSuggestion` deleted; `Install(tx) ([]rowchange.Change, error)`; package comment says Install composes on the caller's transaction, which `onboarding.createCatalog` opens |
| `core/database/sourcetypes/sourcetypestest`, `core/database/metadatafields/metadatafieldstest` | *(new)* D-5 |

Errors: none new.

### FFI

None — no RPC change.

### macOS

None — no Swift change.

### Strings

None — no user-facing copy.

## 7. Steps

**STEP-1 — Types upsert inside a transaction**
Files: `core/database/sourcetypes/sourcetypes.go`, `sourcetypes_test.go`. Skill: `add-catalog-query`.
Do: D-1, D-9. Build `rowFields` and `updateChange` and move `Create`, `Update` and `Delete` onto them first, and run the package tests (audit JSON unchanged); then add `UpsertTx`, leaving `Upsert` exactly as it is (D-7); `TestUpsertTx` calls `UpsertTx` inside `writes.Call`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcetypes/...` passes with T-1.

**STEP-2 — Fields upsert inside a transaction**
Files: `core/database/metadatafields/metadatafields.go`, `metadatafields_test.go`. Skill: `add-catalog-query`.
Do: D-2, D-9, in the same order as STEP-1 (column list; `sqlInsert` *(new)* beside `sqlUpsert`, used by `Create`; `sqlUpdate` with `data_type` and `unknown_text`; then `UpsertTx`). `Upsert` and `sqlUpsert` are untouched.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/metadatafields/...` passes with T-2.

**STEP-3 — The helper packages**
Files: `core/database/sourcetypes/sourcetypestest/sourcetypestest.go` *(new)*, `core/database/metadatafields/metadatafieldstest/metadatafieldstest.go` *(new)*, `core/database/sourcetypes/upsert_test.go` *(new)*.
Do: D-5, D-6.
Check: `go vet ./core/database/sourcetypes/... ./core/database/metadatafields/...` passes.

**STEP-4 — Move every test caller**
Files: every `_test.go` and test-helper file from § 4 "Callers"; not `core/database/sourcevocab/sourcevocab.go`.
Do: replace `sourcetypes.Upsert(` with `sourcetypestest.Upsert(` and `metadatafields.Upsert(` with `metadatafieldstest.Upsert(`, adding each import by hand (`goimports` is not installed here; `go build ./...` finds a missing or unused import); in `package sourcetypes` tests, `Upsert(` → `upsert(`. Apply D-8 to any count that moves.
Check: `rg -n "(sourcetypes|metadatafields)\.Upsert\(" core api` lists only `core/database/sourcevocab/sourcevocab.go`; `go build ./... && CGO_ENABLED=1 go test -tags fts5 ./core/... ./api/...` passes.

**STEP-5 — Install composes on the caller's transaction; delete `Upsert`**
Files: `core/database/sourcevocab/sourcevocab.go`, `sourcevocab_test.go`, `core/onboarding/ready.go`, `core/database/evidencegraphs/evidencegraphstest/evidencegraphstest.go`, `core/database/sourcemetadata/sourcemetadata_test.go`, `core/database/sourcecopy/sourcecopy_test.go`, `core/database/effects/source_type_search_test.go`, `core/database/sourcetypes/sourcetypes.go`, `core/database/metadatafields/metadatafields.go`. Skill: `add-seeded-vocabulary`, `add-audit-scope`.
Do: D-4: rewrite `Install`, wrap its four callers, move the two `EnsureSuggestion` test callers. Then delete `sourcetypes.Upsert`, `metadatafields.Upsert` and both `sqlUpsert` constants, and the `searchindex` imports they leave unused. Add T-3 – T-6.
Check: AC-3.1's two `rg` commands find nothing; `go build ./... && CGO_ENABLED=1 go test -tags fts5 ./core/... ./api/...` passes (it covers `sourcevocab`, `sourcecopy`, `effects` and `onboarding`).

**STEP-6 — Docs**
Files: `core/writes/README.md`, `.agents/skills/add-seeded-vocabulary/SKILL.md`, `docs/deployment-plan/spike-15/completed.md`, `docs/deployment-plan/spike-15/deployment-plan.md` (map row), this plan.
Do: README's last paragraph: the Source seed writes through `writes.Run` (`UpsertTx`); the subject-type, property and grade `Upsert`s and `EnsureBinding` remain the hand-reprojecting seed paths (S16-62). The skill's "Install semantics (pinned)": `Install(tx)` composes on the caller's transaction and never calls `writes.Run`; `createCatalog` runs it in one `writes.Call` (action `install_source_vocabulary`, no user), so it is atomic; a second run over unchanged rows records nothing, and one over a renamed product row records an update; tests make types and fields through `sourcetypestest.Upsert` / `metadatafieldstest.Upsert`. Also its Source vocabulary step 3, "Researcher/plugin rows use Upsert APIs with `user` / `plugin:<id>`": researcher rows use `Create`, plugin rows `UpsertTx`. Then the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-52-source-seed-through-writes-run.md` reports no errors.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/sourcetypes/sourcetypes_test.go` `TestUpsertTx` *(new)* | Table: insert → create change with Create's fields; same values → no change; label change → `update` with only `label`; icon change → only `icon_key`; `plugin:acme` → accepted; blank key, blank label, origin `bogus`, a non-empty ID → `ErrInvalid`; the create change's keys equal today's `Create` audit keys | AC-1.1, AC-1.2, AC-1.6, AC-1.7, D-1 |
| T-2 | Go | `core/database/metadatafields/metadatafields_test.go` `TestUpsertTx` *(new)* | Table: insert → create change with Create's fields; same → no change; a field inserted with `UnknownText` "n.p.", then upserted with "" → only `unknown_text` {"n.p." → nil}, then with " n.p. " after re-setting → no change; description change → only `description`; data type change → `data_type` diff; invalid inputs → `ErrInvalid` | AC-1.4, AC-1.5, AC-1.6, D-2 |
| T-3 | Go | `core/database/sourcevocab/sourcevocab_test.go` `TestInstall` "install records one revision" *(new case)* | Empty catalog, `install(c)` → `dbtest.Revisions` is 1; `dbtest.LatestRevision` gives action `install_source_vocabulary` and four create changes (one `source_type`, three `metadata_field`); `user_id` is NULL | AC-2.1, D-4 |
| T-4 | Go | `TestInstall` "install twice keeps same ids" (extended) | Second Install → `audit_transactions` count unchanged; a suggestion deleted with `DeleteSuggestion` between the two Installs is still missing after the second (D-11) | AC-2.2, D-11 |
| T-5 | Go | `TestInstall` "a seed entry naming an unknown type is rejected even with no fields" (extended) | Also: with a valid field and type ahead of the bad suggestion, nothing is left (`metadatafields.List` and `sourcetypes.List` empty) | AC-2.3, D-4 |
| T-6 | Go | `core/database/effects/source_type_search_test.go` `TestSourceTypeSearchGates` "an upsert label change reprojects the type and its Sources" *(new case)* | Last case: `sourcetypes.UpsertTx(tx, …)` on the test's own open `tx` (the test holds `BeginWrite`, so no `writes.Call`), key `census`, origin `user`, label "Census schedule" (no earlier case sets it), description "Decennial" and icon `type_book` (what the earlier cases leave), then `resolve(changes)` → one change holding only `label`; `DocSourceType` holds the type, `DocSource` holds both Sources | AC-1.3 |
| T-8 | Go | Whole suite, plus the sweep | `rg -n "(sourcetypes|metadatafields)\.Upsert\(" core api` and `rg -n "\bUpsert\(c, Type\{" core/database/sourcetypes` → no hit; `CGO_ENABLED=1 go test -tags fts5 ./core/... ./api/...` → passes | AC-3.1, AC-3.2, D-3, D-5 |
| T-7 | Go | `core/onboarding/ready_test.go`, `complete_test.go` (unchanged) | `birth_certificate` and its suggestions exist after `Complete` | AC-2.4 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: tests that count `audit_transactions` (D-8), and any test that calls a fixture upsert inside an open write.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none)
- [ ] Sweep: `sourcetypes.Upsert`, `metadatafields.Upsert`, `EnsureSuggestion`, "Upsert APIs" and "un-audited seed path" (for the `sourcetypes` and `metadatafields` lines; `core/database/propertyterms/propertyterms.go`'s stays true until S16-62) `rg`'d across `.agents/`, `.cursor/rules/`, `docs/*.md`, `core/**/README.md` and `L10n.swift` with no stale hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none)
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New (no UI)
- [ ] Version bump as the header says (none)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] core/writes/README.md and add-seeded-vocabulary updated (STEP-6)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Build the app from this branch and create a new project. Open **Source types**: Birth certificate is there with its three suggested fields, as before.
2. Rename Birth certificate on its page, add a Source of that type, and search the omnibar for the new type name: the Source is found. (Researcher path, unchanged; confirms nothing regressed around the type's search documents.)

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A mechanical replace misses an unqualified call | AC-3.1's `rg` plus the build |
| Audit counts move in fixtures | D-8 |
| A fixture upsert runs inside another write | Stop condition |

**Stop and report if:**

- A test calls a fixture upsert while a `writes.Run` is open on the same catalog (`database.ErrWriteReentry`).
- `effects.Resolve` refuses a `source_type` or `metadata_field` create change from `UpsertTx` (an entity-name mismatch).
- A test fails because it asserted that `Upsert` did not audit, or counted revisions in a way D-8's delta cannot express.
- More than the files § 4 names call `Upsert`.

## 12. Open questions

None.

## 13. PR

**Title:** S15-52 — The Source seed writes through `writes.Run`
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-52-source-seed-through-writes-run.md`.

