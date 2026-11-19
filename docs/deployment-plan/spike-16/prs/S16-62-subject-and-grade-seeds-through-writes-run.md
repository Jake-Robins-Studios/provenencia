# S16-62 — The subject and grade seeds write through `writes.Run`

**Status:** Draft
**Spike / slice:** Spike 16 · Slice 6c — Shared list helpers
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: a Go refactor of the create-time seed's write path; no view draws anything different)
**Board:** —
**Depends on:** S15-52 (landed [#891](https://github.com/Jake-Robins-Studios/provenencia/pull/891))
**Blocks:** —
**Branch:** `s16-62-subject-and-grade-seeds-through-writes-run`
**Version bump:** none — a preparatory refactor with no change a researcher can see, no wire and no catalog format change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-seeded-vocabulary`](../../../../.agents/skills/add-seeded-vocabulary/SKILL.md), [`add-catalog-query`](../../../../.agents/skills/add-catalog-query/SKILL.md), [`add-audit-scope`](../../../../.agents/skills/add-audit-scope/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests)
**Context:** map scope entry S16-62 ([`../deployment-plan.md`](../deployment-plan.md#s16-62--the-subject-and-grade-seeds-write-through-writesrun)); bar 33 (Batch 6); [`core/writes/README.md`](../../../../core/writes/README.md); the precedent plan [`S15-52-source-seed-through-writes-run.md`](../../spike-15/prs/S15-52-source-seed-through-writes-run.md) (Spike 15)
**Planned:** 2026-11-19 against `main` @ `ca6790b` (compare with `origin/main` after `git fetch origin main`)
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

The last create-time seeds that write beside the catalog's one write path move onto it. `subjectvocab.Install` and `sourcecredibilitygrades.Install` call `subjecttypes.Upsert`, `properties.Upsert`, `propertyterms.Upsert`, `sourcecredibilitygrades.Upsert` and `subjectvocab.EnsureBinding`, each of which writes on `c.DB()` outside any transaction and returns no row change: nothing is audited, the effects registry never sees the rows, and a failing install leaves half a vocabulary. This PR replaces each with a `…Tx` function that runs on the caller's transaction and returns row changes, and makes both `Install`s compose on a transaction `onboarding.createCatalog` opens with `writes.Call`, as S15-52 did for the Source seed.

**Why now.** Bar 33 (Batch 6). S15-52 named these as the remaining seed paths off `writes.Run`; the map row came from S15-19's planning (user, 2026-11-17).

**What stays.** The seed's content. Install runs at create only. `nameformats.Install` and `namealiases.Install` keep writing as today (Out). Every researcher path (property, term and binding create, update, delete, reorder) keeps its audit JSON key for key, except that a Property delete now also records `cardinality` (D-3). Every test keeps the fixtures it has: only the function it calls to make them changes.

**A correction to the map.** The map row and `core/writes/README.md` call these the "hand-reprojecting" seed paths. They are not: none of the five calls `searchindex`, and no Subject type, Property, term or grade has a search document. What they lack is the transaction, the audit and the effects (`ListPropertyVocabulary`, the term `Structure` and `Reads`). STEP-8 rewords the map row, its Check and bar 33's `rg` (§ 9).

## 2. User stories

**US-1.** As the engine, every write of a seeded Subject type, Property, term, binding or grade returns row changes from one column list, so `writes.Run` can audit it and resolve its effects.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | `properties.UpsertTx` on a missing key (`occupation`, `provenencia`, label "Occupation", `text`) | Inserted; one change `property` `create` with `id`, `key`, `origin`, `label`, `value_type`, `cardinality` = `single` (and `description` when not empty), the keys `properties.Create` records today |
| AC-1.2 | `properties.UpsertTx` again, same values | Same id; no change |
| AC-1.3 | `properties.UpsertTx` with label "Occupations" and cardinality `multiple` on that row | One `update` change holding only `label` and `cardinality` |
| AC-1.4 | `properties.UpsertTx` on that row with value type `integer` | `ErrInvalid`; nothing written (D-2) |
| AC-1.5 | `propertyterms.UpsertTx` on a new seeded term `parent` (directed, inverse `child`) | One `property_term` `create` with `id`, `property_id`, `key`, `origin`, `label`, `directed` = true, `inverse_key` = "child"; no `neutral` key |
| AC-1.6 | `propertyterms.UpsertTx` with `Neutral` true on a stored term with `Neutral` false | One `update` holding only `neutral` {nil → true} |
| AC-1.7 | `subjecttypes.UpsertTx` on a new type `person` (`PER`, `PEC`) | One `subject_type` `create` with `id`, `key`, `origin`, `label`, `ref_prefix`, `candidate_ref_prefix` (and `description` when not empty) |
| AC-1.8 | `subjecttypes.UpsertTx` on a second type reusing `PER` in either prefix | `ErrDuplicatePrefix`, as today's `Upsert` |
| AC-1.9 | `subjectvocab.EnsureBindingTx` on an unbound pair at order 3, then again at 3, then at 5 | `subject_type_property` `create` (`subject_type_id`, `property_id`, `sort_order` 3); no change; `update` holding only `sort_order` {3 → 5} |
| AC-1.10 | `sourcecredibilitygrades.UpsertTx` on a new grade, then the same, then a new label | `source_credibility_grade` `create`; no change; `update` holding only `label` |
| AC-1.11 | Any `UpsertTx` with a blank key or label, origin `bogus`, or a non-empty `ID` | `ErrInvalid`; nothing written |
| AC-1.12 | A researcher's `properties.Create` / `Update`, `propertyterms.Create` / `Update` / `Delete` | The same change keys and values as before this PR. `properties.Delete` adds `cardinality` to its delete change |

**US-2.** As the engine, each `Install` is one transaction.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | `subjectvocab.Install` on an empty catalog, inside `writes.Call` with `subjectvocab.ActionInstall` as `createCatalog` runs it | One new `audit_transactions` row, action `install_subject_vocabulary`, `user_id` NULL, with one create change per seeded type (8), Property (27), term (41) and binding (33) at the planning base: 109 |
| AC-2.2 | The same Install a second time over unchanged rows | No new `audit_transactions` row; ids, labels, terms and binding orders unchanged |
| AC-2.3 | `sourcecredibilitygrades.Install` on an empty catalog, inside `writes.Call` with `sourcecredibilitygrades.ActionInstall` | The three grades exist; no `audit_transactions` row (the table's effect is `None`, D-6) |
| AC-2.4 | `subjectvocab.Install` where a binding names a type key the seed does not have | `ErrInvalid`, and the catalog holds no seeded Subject type, Property, term or binding |
| AC-2.5 | `onboarding.Complete` | The new project's vocabulary equals the registry (`TestInstallMatchesRegistry`), the grades are `low_trust`, `standard`, `high_trust`, and `audit_transactions` holds one `install_subject_vocabulary` revision and no `install_source_credibility_grades` revision |

**US-3.** As a contributor, a test makes a type, Property, term, binding or grade with the call it made before, through the path the app writes.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `rg -n "func (Upsert\|EnsureBinding\|Install)\(c \*database\.Catalog" core/database/properties core/database/propertyterms core/database/subjecttypes core/database/sourcecredibilitygrades core/database/subjectvocab --glob '!*_test.go' --glob '!*test/**'` | No hit |
| AC-3.2 | `go build ./... && CGO_ENABLED=1 go test -tags fts5 ./core/... ./api/...` | Passes |

## 3. Scope

| In | Covered by |
| --- | --- |
| `properties.UpsertTx`, `rowFields`, `updateChange` *(new)*; `Create`, `Update`, `Delete` build their changes from the column list; `sqlUpsert` → `sqlInsert`; `Upsert` deleted (D-1 – D-3) | STEP-1, STEP-7, AC-1.1 – AC-1.4, AC-1.11, AC-1.12 |
| `propertyterms.UpsertTx`, `rowFields`, `updateChange` *(new)*; `Create`, `Update`, `Delete` onto the column list; `sqlUpsert` → `sqlInsert`, `sqlSeedUpdate` *(new)*; `Upsert` deleted (D-1, D-4) | STEP-2, STEP-7, AC-1.5, AC-1.6, AC-1.11, AC-1.12 |
| `subjecttypes.UpsertTx`, `rowFields` *(new)*; `sqlUpsert` → `sqlInsert`, `sqlUpdate` *(new)*; `Upsert` deleted; effects entry `subject_types` gains `Entity: "subject_type"` (D-1, D-5) | STEP-3, STEP-7, AC-1.7, AC-1.8, AC-1.11 |
| `sourcecredibilitygrades.UpsertTx`, `rowFields` *(new)*; `Upsert` deleted; effects entry `source_credibility_grades` gains `Entity: "source_credibility_grade"` and stays `None`; `grades_test.go` becomes an external test package (D-1, D-6, D-9) | STEP-4, STEP-7, AC-1.10, AC-1.11 |
| `subjectvocab.EnsureBindingTx` *(new)*; `EnsureBinding` deleted (D-7) | STEP-5, STEP-7, AC-1.9 |
| `subjectvocab.Install(tx)` and `sourcecredibilitygrades.Install(tx)` compose on the caller's transaction; `ActionInstall` in each *(new)*; `onboarding.createCatalog` runs each in one `writes.Call` through `installSeed` *(new)* (D-8) | STEP-6, AC-2.1 – AC-2.5 |
| Test helpers *(new)*: `propertiestest.Upsert`, `subjecttypestest.Upsert`, `sourcecredibilitygradestest.Install`, `subjectvocabtest.Install`, `subjectvocabtest.EnsureBinding`; in-package test-file helpers; every caller moved (D-9, D-10) | STEP-5, STEP-6, STEP-7, AC-3.1, AC-3.2 |
| Docs: `core/writes/README.md`, package comments, `add-seeded-vocabulary`, the map row, its Check and bar 33 | STEP-8 |

| Out | Home |
| --- | --- |
| `nameformats.Install` and `namealiases.Install` on `writes.Run` | not planned — every table they write is `None` in the effects registry, so `Run` would add a transaction and nothing else (map scope entry, "Not this PR") |
| Auditing grade writes (dropping `None` from `source_credibility_grades`) | not planned — no researcher writes a grade, and the registry entry says a grade write moves nothing (D-6) |
| One transaction for the whole create-time seed (all five Installs) | not planned — the map keeps one write per domain; a failed later Install still leaves the earlier domains, as today |
| Any seed content | not planned |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Property upsert | `core/database/properties/properties.go` `Upsert`, `sqlUpsert`, `Lookup` | `Upsert(c, p) ([]byte, error)`: trims; checks key, label, `vocabkey.ValidOrigin`, `valueTypeOK`, `cardinalityAllowed` (empty cardinality → `single`); looks up on `c.DB()`; `INSERT … ON CONFLICT(key, origin) DO UPDATE` label, description, value_type, cardinality. No change, no transaction |
| Property create, update, delete | same file `Create`, `Update`, `Delete`, `sqlUpdate` (`label, description, cardinality`), `LookupTx`, `GetByIDTx` | `Create` inserts through `sqlUpsert` and builds its change inline (`id`, `key`, `origin`, `label`, `value_type`, `cardinality`, `description` when set). `Update` diffs `label`, `description`, `cardinality` with `database.NullString`. `Delete` records `id`, `key`, `origin`, `label`, `value_type`, `description` when set (no `cardinality`) |
| Term upsert | `core/database/propertyterms/propertyterms.go` `Upsert`, `sqlUpsert`, `Lookup`, `directedBit` | Same shape; writes `directed`, `inverse_key` (NULL when empty), `neutral` on insert and conflict. Package comment: "Upsert is the un-audited seed path" |
| Term create, update, delete | same file `Create`, `Update`, `Delete`, `sqlUpdate` (`label, description`), `sqlGetByID`, `scanTerm` | Inline change maps: create and delete `id`, `property_id`, `key`, `origin`, `label`, `description` when set; update `label`, `description` with `NullString`. User terms are always `directed` 0, no inverse, `neutral` 0 |
| Subject type upsert | `core/database/subjecttypes/subjecttypes.go` `Upsert`, `sqlUpsert`, `sqlPrefixTaken`, `LookupTx` | Validates prefixes (`ref.ValidatePrefix`, the two must differ, `sqlPrefixTaken` across both columns excluding this row); upserts label, description, both prefixes. No other write exists in the package |
| Grade upsert | `core/database/sourcecredibilitygrades/grades.go` `Upsert`, `sqlUpsert` | Upserts label, sort_order. No other write |
| Grade install | `core/database/sourcecredibilitygrades/registry.go` `Install`, `seedGrades` | `Install(c)` loops three grades through `Upsert` |
| Binding ensure | `core/database/subjectvocab/subjectvocab.go` `EnsureBinding`, `sqlEnsureBinding`, `bindingFields`, `bindingEntity`, `sqlBindingOrder` | `EnsureBinding(c, typeID, propertyID, sortOrder) error` inserts or sets `sort_order` with raw `db.Exec`. `AppendBinding` / `DeleteBinding` already return `subject_type_property` changes keyed by property id, built from `bindingFields` |
| Subject install | same file `Install`; `registry.go` `seedTypes`, `seedProperties`, `seedTerms`, `allBindings` | `Install(c) error`: types, then Properties, then terms, then bindings, each through the `Upsert`s above. Not transactional. Seed size at the base: 8 types, 27 Properties, 41 terms, 33 bindings |
| Create path | `core/onboarding/ready.go` `createCatalog` | `writes.Call(c, writes.Op{Action: sourcevocab.ActionInstall}, …)` around `sourcevocab.Install(tx)`, then `sourcecredibilitygrades.Install(c)`, `subjectvocab.Install(c)`, `nameformats.Install(c)`, `namealiases.Install(c)`, each closing `c` on error |
| Effects | `core/database/effects/registry.go` `registry` | `"subject_types": {Lists: []List{ListPropertyVocabulary}}` (no `Entity`); `"properties"` `Entity: "property"`, Lists, `Handles: onField("cardinality", …)`; `"property_terms"` `Entity: "property_term"`, Lists, `Reads` `ReadPropertyTerms`, `Handles: onField("neutral", …)`, `Structure` on `directed`, `inverse_key`, `neutral`; `"source_credibility_grades": {None: true}` (no `Entity`); `"subject_type_properties"` `Entity: "subject_type_property"`, Lists. `effects.AllNone` / `WithoutNone` / `Resolve` return `effects: no entry for <type>` for a change whose `EntityType` names no entry's `Entity` (`core/database/effects/resolve.go`) |
| Write path | `core/writes/run.go` `Run`, `Call`, `Op` | Empty change list rolls back; a `None`-only list commits with no revision and no notice; otherwise audits (`UserID` nil → NULL), resolves, commits, notifies |
| Import graph | `go list -deps ./core/writes` | Includes `core/database/sourcecredibilitygrades` (through `autoreconciler` and `sources`). Does not include `properties`, `propertyterms`, `subjecttypes` or `subjectvocab` |
| Callers | `rg -n "properties\.Upsert\(" core api` | 24 test calls in 8 `_test.go` files (`api/ffi/handlers/citations_test.go`, `core/database/{propertyterms,properties ×2,deleteimpact/impact,conclusiondetails,observations,autoreconciler}…_test.go`) plus `subjectvocab.Install` |
| | `rg -n "subjecttypes\.Upsert\(" core` | `core/database/properties/properties_delete_test.go` ×2, `core/database/graphcache/vocab_test.go` ×2, plus `subjectvocab.Install`; `core/database/subjecttypes/subjecttypes_test.go` (`package subjecttypes`) calls `Upsert(c, Type{…})` unqualified about 11 times |
| | `rg -n "propertyterms\.Upsert\(\|\bUpsert\(c, Term\{" core` | `subjectvocab.Install`; `core/database/propertyterms/propertyterms_test.go` (`package propertyterms`) ×3 unqualified |
| | `rg -n "sourcecredibilitygrades\.Upsert\(\|\bUpsert\(c, Grade\{" core` | `core/database/sources/records_test.go:132` (crafted grade, `SortOrder` MaxInt64); `core/database/sourcecredibilitygrades/grades_test.go` (`package sourcecredibilitygrades`) ×2, plus `Install(c)` ×3 |
| | `rg -n "subjectvocab\.EnsureBinding\(" core` | `core/database/conclusionsummaries/conclusionsummaries_test.go:1240` (order 99), `core/database/conclusiondetails/placerecords_test.go:184` (order 9), `core/database/graphcache/vocab_test.go:53` (order 0), plus `Install` |
| | `rg -n "subjectvocab\.Install\(" core api` | 51 calls in 31 files: non-test helpers `core/database/evidencelayer/evidencelayertest/evidencelayertest.go`, `core/database/graphcache/graphcachetest/graphcachetest.go`; the rest in `_test.go` files under `core/database/*`, `core/writes/run_test.go` and `api/ffi/swift_vocabulary_test.go`; plus 8 unqualified `Install(c)` in `core/database/subjectvocab/subjectvocab_test.go` (`package subjectvocab`) |
| | `rg -n "sourcecredibilitygrades\.Install\(" core` | 12 calls in 12 `_test.go` files, plus `core/onboarding/ready.go` |
| Tests | `core/database/subjectvocab/subjectvocab_test.go` `TestSubjectVocab`, `TestInstallStoresInverses`, `TestInstallFlagsNeutralTerms`, `TestInstallLetsAUserTermJoinASeededProperty`, `TestInstallMatchesRegistry`, `TestBindingChanges`; `core/database/sourcecredibilitygrades/grades_test.go` `TestGrades`; `core/database/subjecttypes/subjecttypes_test.go`; `core/database/properties/properties_test.go` ("upsert lookup list", "rejects bad value type"); `core/database/propertyterms/propertyterms_test.go`; `core/onboarding/ready_test.go`, `complete_test.go` | Cover today's Upserts and Installs; none asserts a revision |
| Docs | `core/writes/README.md` (paragraph 6: "Property, subject-type, and grade `Upsert` and `subjectvocab.EnsureBinding`, which only `Install` calls, remain the hand-reprojecting seed paths"); `propertyterms` and `subjecttypes` package comments; `subjectvocab` package comment ("Install upserts …"); `.agents/skills/add-seeded-vocabulary/SKILL.md` "Install semantics (pinned)" and "Where create vs open run" | Describe today's path |

**Precedent.** S15-52 ([#891](https://github.com/Jake-Robins-Studios/provenencia/pull/891)): `core/database/sourcetypes/sourcetypes.go` `UpsertTx`, `rowFields`, `updateChange`, `createChange`; `core/database/sourcevocab/sourcevocab.go` `Install(tx)` and `ActionInstall`; `core/database/sourcevocab/sourcevocabtest/sourcevocabtest.go` `Install`; `core/database/sourcetypes/sourcetypestest/sourcetypestest.go` `Upsert`. Copy those shapes, function for function. Do not copy `sourcetypes`' format handling (no format columns here). `rowchange.UpdatedRow(old, now, "id", "key", "origin")` is the diff; `rowchange.FullRow` and `DeletedRow` the create and delete.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | Each of `properties`, `propertyterms`, `subjecttypes`, `sourcecredibilitygrades` gets `UpsertTx(tx *database.Tx, x T) ([]byte, []rowchange.Change, error)` *(new)* with the shape of `sourcetypes.UpsertTx`: `tx == nil` or a non-empty `x.ID` → `ErrInvalid`; the same trims and checks as today's `Upsert`; look up by its unique key on the tx (`LookupTx`; terms by `(property_id, key, origin)` with `sqlLookup` on `tx`; grades by `sqlLookup` on `tx`). **Missing:** mint a UUIDv7, insert with `sqlInsert` (no `ON CONFLICT`), return one create change `rowchange.FullRow(rowFields(x))`. **Present:** build `next` from the stored row plus the input's writable columns, compute `updateChange(prev, next)`; nil → return the id and no change, writing nothing; otherwise write with the package's update statement and return the change. Each package's `sqlUpsert` is deleted (STEP-7) | One insert, one update and one diff per table, as S15-52 left `sourcetypes`; a re-run over unchanged rows returns nothing, so `Run` rolls back (AC-2.2) | Keeping `INSERT … ON CONFLICT` — a second insert statement whose conflict branch the lookup makes dead; reusing `Create` — mints a user key and refuses duplicates |
| D-2 | `properties.UpsertTx` writes `label`, `description`, `cardinality` with today's `sqlUpdate`. A stored row whose `value_type` differs from the input's is `ErrInvalid` and nothing is written | `Update` already refuses a value-type change; an Observation stores its value by type, so rewriting it under existing Observations corrupts them. Only create-time seeds and fixtures call this, so nothing relies on the overwrite | Writing `value_type` as today's `Upsert` does — one `UPDATE` more, and a dangerous meaning no caller uses |
| D-3 | `properties.rowFields(p Property) map[string]any` *(new)*: `id` (`database.UUIDString`), `key`, `origin`, `label`, `value_type`, `cardinality`, and `description` only when not empty. `updateChange(prev, next Property) *rowchange.Change` *(new)* = `UpdatedRow(rowFields(prev), rowFields(next), "id", "key", "origin")`, entity `property`, nil when empty. `Create` uses `FullRow(rowFields(…))`; `Update` uses `updateChange` (same keys and values as today: `value_type` never differs there); `Delete` uses `DeletedRow(rowFields(prev))`, which adds `cardinality` | One column list drives create, update and delete (S15-52 D-9). The delete record gains the one column it omitted; `properties`' `Handles` path on `cardinality` then runs for a deleted Property, whose Observations `Delete` already refused, so it finds none | Leaving `Delete`'s inline map — a third copy of the column list; dropping `cardinality` from `rowFields` — the seed's cardinality would go unaudited |
| D-4 | `propertyterms.rowFields(t Term) map[string]any` *(new)*: `id`, `property_id` (`database.UUIDString`), `key`, `origin`, `label`; `description` only when not empty; `directed` = `true` only when set; `inverse_key` only when not empty; `neutral` = `true` only when set. `updateChange` *(new)* as D-3, entity `property_term`. `Create`, `Update`, `Delete` use them. `UpsertTx` writes `label`, `description`, `directed`, `inverse_key`, `neutral` with `sqlSeedUpdate` *(new)*: `UPDATE property_terms SET label = ?, description = ?, directed = ?, inverse_key = ?, neutral = ? WHERE id = ?`; `Update` keeps `sqlUpdate` | Omitting the zero flags keeps every user term's create, update and delete change identical to today (AC-1.12); a create carrying `directed` or `neutral` would fire the registry's `Structure` and `Handles` paths on every researcher term create. The seed's flags are what the `Structure` path exists for, so the seed records them | Writing the flags as `0`/`1` always — changes researcher audit JSON and drops the graph cache on each term create; a separate seed-only diff — two column lists |
| D-5 | `subjecttypes.rowFields(t Type) map[string]any` *(new)*: `id`, `key`, `origin`, `label`, `ref_prefix`, `candidate_ref_prefix`, `description` only when not empty. `UpsertTx` keeps today's prefix checks (`ref.ValidatePrefix` on both, equal → `ErrDuplicatePrefix`, then `sqlPrefixTaken` on `tx` excluding the row's id, which for a new row is the freshly minted id) and writes label, description and both prefixes with `sqlUpdate` *(new)*: `UPDATE subject_types SET label = ?, description = ?, ref_prefix = ?, candidate_ref_prefix = ? WHERE id = ?`. The effects entry becomes `"subject_types": {Entity: "subject_type", Lists: []List{ListPropertyVocabulary}}`; `"subject_type"` equals `catalogmodel.KindSubjectType` | `Resolve` refuses a change whose entity no entry names; the registry gains no new effect, only the name. Same column-list shape | A separate create/update builder per caller — there is only this one |
| D-6 | `sourcecredibilitygrades.rowFields(g Grade) map[string]any` *(new)*: `id`, `key`, `origin`, `label`, `sort_order`. `UpsertTx` writes `label`, `sort_order` with `sqlUpdate` *(new)*: `UPDATE source_credibility_grades SET label = ?, sort_order = ? WHERE id = ?`. The effects entry becomes `{Entity: "source_credibility_grade", None: true}` (the shape of `subject_positions`). A grades-only change list therefore commits with no revision (`writes.Run`'s None path): the grades install is one transaction and is not audited | `None` is the registry's statement that a grade write moves nothing, and no researcher writes a grade; the Entity is what lets `AllNone` classify the change. Atomic install is what the seed needs | Dropping `None` so grades are audited — an entry with no effects that is not `None`, and an audit row nobody reads (Out) |
| D-7 | `subjectvocab.EnsureBindingTx(tx *database.Tx, typeID, propertyID []byte, sortOrder int) ([]rowchange.Change, error)` *(new)*. `tx == nil` or an id not 16 bytes → `ErrInvalid`. Reads `sqlBindingOrder` on `tx`: missing → `INSERT` with `sqlEnsureBinding` and a create change `FullRow(bindingFields(…))`; same order → no write, no change; other order → `sqlSetBindingOrder` and an update change built by `UpdatedRow(bindingFields(old), bindingFields(new), "subject_type_id", "property_id")`. Entity `bindingEntity`, `EntityID` the property id, as `AppendBinding`. `EnsureBinding` is deleted. `sqlEnsureBinding` loses its `ON CONFLICT` clause | Same entity and fields as the researcher binding writes; exported because the three test fixtures set a binding at a chosen order and `AppendBinding` appends (D-10) | Fixtures through `AppendBinding` + `ReorderBindings` — changes what three tests set up; an unexported function — the fixtures would need a second copy |
| D-8 | `subjectvocab.Install(tx *database.Tx) ([]rowchange.Change, error)` and `sourcecredibilitygrades.Install(tx *database.Tx) ([]rowchange.Change, error)` compose on the caller's transaction and never call `writes.Run` (`sourcecredibilitygrades` cannot: `core/writes` imports it). They keep today's order (types, Properties, terms, bindings) and errors (`ErrInvalid` for a seed row naming an unknown key) and return every change. `ActionInstall = "install_subject_vocabulary"` and `ActionInstall = "install_source_credibility_grades"` *(new, exported consts)*. `core/onboarding/ready.go` gets `installSeed(c *database.Catalog, action string, install func(*database.Tx) ([]rowchange.Change, error)) error` *(new, unexported)* — `writes.Call` with `writes.Op{Action: action}`, no user — and `createCatalog` runs `sourcevocab.Install`, `sourcecredibilitygrades.Install` and `subjectvocab.Install` through it, in today's order, each closing `c` on error as today | S15-52 D-4's shape, two more times; `installSeed` keeps `createCatalog` from holding three copies of the same closure | One `writes.Call` around all three — one revision for three domains and a map change (Out); `Install` calling `Run` — an import cycle for grades and against `add-catalog-query` |
| D-9 | Test helper packages *(new)*, each wrapping the tx function in `writes.Call` with no user and returning the error, signatures equal to the deleted functions' so a caller changes only its qualifier and import: `core/database/properties/propertiestest/propertiestest.go` `Upsert(c *database.Catalog, p properties.Property) ([]byte, error)` (action `"upsert_property"`); `core/database/subjecttypes/subjecttypestest/subjecttypestest.go` `Upsert(c *database.Catalog, t subjecttypes.Type) ([]byte, error)` (action `"upsert_subject_type"`); `core/database/sourcecredibilitygrades/sourcecredibilitygradestest/sourcecredibilitygradestest.go` `Install(c *database.Catalog) error` (`ActionInstall`); in the existing `core/database/subjectvocab/subjectvocabtest/subjectvocabtest.go`: `Install(c *database.Catalog) error` (`ActionInstall`) and `EnsureBinding(c *database.Catalog, typeID, propertyID []byte, sortOrder int) error` (action `"ensure_subject_type_property"`) | Precedent `sourcetypestest.Upsert`, `sourcevocabtest.Install`; a mechanical, reviewable move | A `t`-taking fatal helper — every caller's error handling changes; one shared seed-test package — an import cycle for `propertyterms`' in-package tests (D-10) |
| D-10 | In-package tests that cannot import a helper get a test-file helper *(new)* with the same body: `core/database/subjecttypes/upsert_test.go` `upsert(c, t Type) ([]byte, error)`; `core/database/propertyterms/upsert_test.go` `upsert(c, t Term) ([]byte, error)` (its `properties.Upsert` calls use `propertiestest.Upsert`); `core/database/subjectvocab/install_test.go` `install(c) error` (the 8 `Install(c)` calls become `install(c)`). `core/database/sourcecredibilitygrades/grades_test.go` cannot import `core/writes` from `package sourcecredibilitygrades` (cycle), so it becomes `package sourcecredibilitygrades_test`, qualifies its names, calls `sourcecredibilitygradestest.Install`, and runs its invalid-input case through `UpsertTx` inside `writes.Call`. `core/database/sources/records_test.go:132` makes its crafted grade with `sourcecredibilitygrades.UpsertTx` inside `writes.Call` (one caller; no helper) | Go forbids the cycles; S15-52 D-6's shape | Exported `*Catalog` wrappers in product code — functions only tests call |
| D-11 | A test that counts `audit_transactions` or asserts a revision number and now sees one more revision from `subjectvocabtest.Install` (or from a `propertiestest` / `subjecttypestest` / `subjectvocabtest.EnsureBinding` fixture) takes its count as a delta from after the fixture, the pattern of `core/database/observations/observations_test.go` `before` / `after`, not a new literal | Fixtures now audit; a delta does not depend on how many | Bumping literals |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `properties.UpsertTx`, `rowFields`, `updateChange`, `sqlInsert` | func, const | `sourcetypes.UpsertTx`, `rowFields`, `updateChange`; `properties.Upsert` (deleted) | Same shape per table (D-1, D-3); `rowchange.UpdatedRow` is the shared diff |
| `propertyterms.UpsertTx`, `rowFields`, `updateChange`, `sqlInsert`, `sqlSeedUpdate` | func, const | as above; `propertyterms.Upsert` (deleted) | D-1, D-4 |
| `subjecttypes.UpsertTx`, `rowFields`, `sqlInsert`, `sqlUpdate` | func, const | `subjecttypes.Upsert` (deleted) | D-1, D-5; no other write in the package, so no `updateChange` beyond the inline `UpdatedRow` call in `UpsertTx` |
| `sourcecredibilitygrades.UpsertTx`, `rowFields`, `sqlUpdate`, `ActionInstall`, `Install(tx)` | func, const | `sourcecredibilitygrades.Upsert` (deleted), `sourcevocab.ActionInstall` | D-1, D-6, D-8 |
| `subjectvocab.EnsureBindingTx`, `ActionInstall`, `Install(tx)` | func, const | `AppendBinding`, `bindingFields`, `EnsureBinding` (deleted), `sourcevocab.Install` | D-7, D-8 |
| `onboarding.installSeed` | func | the inline `writes.Call` in `createCatalog` | Three callers (D-8) |
| `propertiestest`, `subjecttypestest`, `sourcecredibilitygradestest` packages *(new)*; `subjectvocabtest.Install`, `EnsureBinding` | test helpers | `sourcetypestest`, `sourcevocabtest`, `subjectvocabtest.Assign` | Same pattern (D-9) |
| `core/database/subjecttypes/upsert_test.go`, `core/database/propertyterms/upsert_test.go`, `core/database/subjectvocab/install_test.go` *(new)* | test-file helpers | `core/database/sourcetypes/upsert_test.go` | Import cycles (D-10) |

Searched for: an existing generic "seed upsert" or diff helper (`rg -n "func UpdatedRow|func FullRow" core` — `rowchange` has them, used); an existing `propertiestest` / `subjecttypestest` (none); another writer of `subject_types` or `source_credibility_grades` (none).

**Builds on.** `writes.Run` and `Call`; the effects registry's entries for these five tables (two gain only an `Entity`); `rowchange.FullRow`, `DeletedRow`, `UpdatedRow`; S15-52's `UpsertTx` / `Install(tx)` / helper-package shape.
**Deletes.** `properties.Upsert`, `propertyterms.Upsert`, `subjecttypes.Upsert`, `sourcecredibilitygrades.Upsert`, `subjectvocab.EnsureBinding`, the four `sqlUpsert` constants; `subjectvocab.Install(c)` and `sourcecredibilitygrades.Install(c)` (replaced by the tx forms); the inline change maps in `properties.Create` / `Update` / `Delete` and `propertyterms.Create` / `Update` / `Delete`; the README sentence and package-comment lines that name the un-audited seed path. `propertyterms.Lookup`, `subjecttypes.Lookup`, `properties.Lookup`, `sourcecredibilitygrades.Lookup` keep their other callers (`rg` them in STEP-7; delete only one left with no caller).
**Next adds.** A `plugin:<id>` module installs its rows through these `UpsertTx`s on its own `writes.Call`. Every create-time seed that has effects is then on `Run`.

### Reach

None — no new path into existing code. The seed and fixtures now reach `writes.Run`, which every researcher write takes. New state: a new project holds one more revision, `install_subject_vocabulary` (D-8; AC-2.5).

### Scale

At create: 109 changes in one `writes.Run` (8 types, 27 Properties, 41 terms, 33 bindings); `effects.Resolve` walks each change's paths once. The only SQL-backed paths that fire are `properties`' `Handles` on `cardinality` (27 lookups of `sqlHandlesForProperty`) and `property_terms`' `Handles` on `neutral` (one per neutral term), each against empty tables. The grades are 3 rows on the None path (no resolve). Tests: about 63 Install calls and about 35 fixture upserts each become one `writes.Call`; no budget is set.

### Edges

- **Assumptions.** `writes.Run` assumes no other write is open (`database.ErrWriteReentry`): a helper called inside another write's closure fails (Stop condition). `effects` maps every `EntityType` to a table: `subject_type` and `source_credibility_grade` are added (D-5, D-6); a missing one fails the first install with `effects: no entry for …`. Listeners: a test that registers the graph cache before installing now gets a notice with `ListPropertyVocabulary` and, from seeded terms, `Structure` — the cache drops and reloads, which the old un-notified writes skipped.
- **Neighbors.** A plugin-origin type, Property or term still upserts (`vocabkey.ValidOrigin`). A re-run over identical rows records nothing (AC-2.2). A changed seeded binding order records an update (AC-1.9). A Property upsert with a different value type is refused (D-2) — today it overwrote.
- **Removed inputs.** A failed subject install leaves none of its rows (AC-2.4); the Source seed and grades, each committed first, stay, as today.
- **New state.** `audit_transactions` gains an `install_subject_vocabulary` revision with a NULL user and no audit scopes (no change here names a Source or a handle scope). Readers of revisions without a user (`core/database/promotealign/promotealign.go`, `core/database/promote/batch.go`, `core/database/graphcache/sql.go`) already accept S15-52's NULL-user revision.
- **Real data.** The seed tables at the base, through `TestInstallMatchesRegistry` and `TestSeedProductValues`, unchanged.
- **Untrusted size.** None — the seed is compiled-in data.

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/properties` | D-1 – D-3; `propertiestest` *(new)* |
| `core/database/propertyterms` | D-1, D-4; package comment: "UpsertTx is the seed's write, run inside writes.Run" |
| `core/database/subjecttypes` | D-1, D-5; `subjecttypestest` *(new)*; package comment: "UpsertTx is for create-time Install and plugin Install, run inside writes.Run" |
| `core/database/sourcecredibilitygrades` | D-1, D-6, D-8; `sourcecredibilitygradestest` *(new)*; `Install` comment says it composes on the caller's transaction |
| `core/database/subjectvocab` | D-7, D-8; `subjectvocabtest.Install`, `EnsureBinding` *(new)*; package comment: "Install writes the shipped types, Properties, terms and bindings on the caller's transaction, which onboarding.createCatalog opens" |
| `core/database/effects` | `registry.go`: the two `Entity` names (D-5, D-6) |
| `core/onboarding` | `ready.go` `installSeed` *(new)*; `createCatalog` (D-8) |

Errors: none new.

### FFI

None — no RPC change.

### macOS

None — no Swift change.

### Strings

None — no user-facing copy.

## 7. Steps

**STEP-1 — Properties upsert inside a transaction**
Files: `core/database/properties/properties.go`, `properties_test.go`. Skill: `add-catalog-query`.
Do: D-3 first: `rowFields`, `updateChange`; move `Create`, `Update`, `Delete` onto them; rename `sqlUpsert` → `sqlInsert` without `ON CONFLICT` for `Create` and keep a private copy of the old upsert statement for `Upsert` until STEP-7. Run the package tests. Then D-1, D-2: `UpsertTx`. `Upsert` stays as it is. T-1 calls `UpsertTx` inside `writes.Call`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/properties/...` passes with T-1, T-7.

**STEP-2 — Terms upsert inside a transaction**
Files: `core/database/propertyterms/propertyterms.go`, `propertyterms_test.go`. Skill: `add-catalog-query`.
Do: D-4 in STEP-1's order (column list; `Create`, `Update`, `Delete` onto it; `sqlInsert`, `sqlSeedUpdate`; then `UpsertTx`). `Upsert` stays.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/propertyterms/...` passes with T-2, T-7.

**STEP-3 — Subject types upsert inside a transaction**
Files: `core/database/subjecttypes/subjecttypes.go`, `subjecttypes_test.go`, `core/database/effects/registry.go`.
Do: D-5: `Entity: "subject_type"` on the `subject_types` entry; `rowFields`, `sqlInsert`, `sqlUpdate`, `UpsertTx`. `Upsert` stays.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/subjecttypes/... ./core/database/effects/...` passes with T-3.

**STEP-4 — Grades upsert inside a transaction**
Files: `core/database/sourcecredibilitygrades/grades.go`, `grades_test.go`, `core/database/effects/registry.go`.
Do: D-6: `Entity: "source_credibility_grade"` on the None entry; `rowFields`, `sqlUpdate`, `UpsertTx` (insert keeps the columns of today's statement, without `ON CONFLICT`). Convert `grades_test.go` to `package sourcecredibilitygrades_test` (D-10) and add T-4; its install cases keep calling the old `Install(c)` (exported) until STEP-6.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcecredibilitygrades/... ./core/database/effects/...` passes with T-4.

**STEP-5 — Binding ensure inside a transaction; the fixture helpers**
Files: `core/database/subjectvocab/subjectvocab.go`, `subjectvocab_test.go`, `core/database/properties/propertiestest/propertiestest.go` *(new)*, `core/database/subjecttypes/subjecttypestest/subjecttypestest.go` *(new)*, `core/database/subjecttypes/upsert_test.go` *(new)*, `core/database/propertyterms/upsert_test.go` *(new)*, `core/database/subjectvocab/subjectvocabtest/subjectvocabtest.go`.
Do: D-7 (`EnsureBindingTx`; `EnsureBinding` stays, still on `db.Exec`, until STEP-7). D-9's `propertiestest.Upsert`, `subjecttypestest.Upsert`, `subjectvocabtest.EnsureBinding`; D-10's two test-file `upsert` helpers. Add T-5.
Check: `go vet ./core/database/...` passes; `CGO_ENABLED=1 go test -tags fts5 ./core/database/subjectvocab/...` passes with T-5.

**STEP-6 — Both Installs compose on the caller's transaction**
Files: `core/database/subjectvocab/subjectvocab.go`, `core/database/subjectvocab/install_test.go` *(new)*, `subjectvocab_test.go`, `core/database/sourcecredibilitygrades/registry.go`, `core/database/sourcecredibilitygrades/sourcecredibilitygradestest/sourcecredibilitygradestest.go` *(new)*, `grades_test.go`, `core/database/subjectvocab/subjectvocabtest/subjectvocabtest.go`, `core/onboarding/ready.go`, and every `subjectvocab.Install(` / `sourcecredibilitygrades.Install(` caller from § 4 "Callers". Skills: `add-seeded-vocabulary`, `add-audit-scope`.
Do: D-8: rewrite both `Install`s over the `UpsertTx`s and `EnsureBindingTx`; `ActionInstall` consts; `installSeed` and `createCatalog`. D-9: `subjectvocabtest.Install`, `sourcecredibilitygradestest.Install`; D-10: `install_test.go`. Move every Install caller to the helper (`subjectvocab.Install(c)` → `subjectvocabtest.Install(c)`, `sourcecredibilitygrades.Install(c)` → `sourcecredibilitygradestest.Install(c)`, `Install(c)` → `install(c)` inside `package subjectvocab`), adding imports by hand (`go build ./...` finds a missing or unused one). Apply D-11. Add T-6, T-8.
Check: `rg -n "(subjectvocab|sourcecredibilitygrades)\.Install\(c" core api` → only `*test` helper bodies; `go build ./... && CGO_ENABLED=1 go test -tags fts5 ./core/... ./api/...` passes.

**STEP-7 — Move the fixture callers; delete the old writes**
Files: every caller in § 4 "Callers" of `properties.Upsert`, `subjecttypes.Upsert`, `propertyterms.Upsert` / unqualified `Upsert(c, Term{`, `sourcecredibilitygrades.Upsert` / `Upsert(c, Grade{`, `subjectvocab.EnsureBinding`; `core/database/sources/records_test.go`; then `properties.go`, `propertyterms.go`, `subjecttypes.go`, `grades.go`, `subjectvocab.go`.
Do: replace each call with its D-9 / D-10 helper (`subjecttypes_test.go` `Upsert(` → `upsert(`; `propertyterms_test.go` `Upsert(c, Term{` → `upsert(c, Term{`); `records_test.go` per D-10. Apply D-11. Then delete the five old functions and every `sqlUpsert` copy; `rg` each package's `Lookup` for a remaining caller. Add T-9.
Check: AC-3.1's `rg` finds nothing; `go build ./... && CGO_ENABLED=1 go test -tags fts5 ./core/... ./api/...` passes.

**STEP-8 — Docs**
Files: `core/writes/README.md`, `.agents/skills/add-seeded-vocabulary/SKILL.md`, `docs/deployment-plan/spike-16/deployment-plan.md` (map row, scope entry, bar 33), `docs/deployment-plan/spike-16/completed.md`, this plan.
Do: README paragraph 6: replace the "remain the hand-reprojecting seed paths" sentence with: "The subject vocabulary and the credibility grades seed the same way: `properties`, `propertyterms`, `subjecttypes` and `sourcecredibilitygrades` `UpsertTx` and `subjectvocab.EnsureBindingTx` return row changes, and each `Install(tx)` composes on a transaction `createCatalog` opens (`install_subject_vocabulary`, one revision; `install_source_credibility_grades`, none: its table is `None`)." Skill "Install semantics (pinned)": the bullet on `sourcevocab.Install(tx)` names all three tx Installs and `installSeed`; tests install through `sourcevocabtest.Install`, `sourcecredibilitygradestest.Install`, `subjectvocabtest.Install`, and make rows through `propertiestest.Upsert`, `subjecttypestest.Upsert`, `subjectvocabtest.EnsureBinding`. "Where create vs open run": unchanged order. Map: scope entry **Ships** drops "hand reprojection" and names the terms and the None grades; **Check** reads "Bar 33; a second subject `Install` records no revision; `TestInstallMatchesRegistry` stays green"; bar 33's command becomes AC-3.1's `rg`. Then the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-62-subject-and-grade-seeds-through-writes-run.md` reports no errors.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/properties/properties_test.go` `TestUpsertTx` *(new)* | Table, each inside `writes.Call`: new `occupation` → one create, keys equal `Create`'s; same → no change; label "Occupations" + cardinality `multiple` → update with only `label`, `cardinality`; value type `integer` → `ErrInvalid` and the row unchanged; `plugin:acme` → accepted; blank key, blank label, origin `bogus`, bad value type `real`, non-empty ID → `ErrInvalid` | AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.11, D-1, D-2 |
| T-2 | Go | `core/database/propertyterms/propertyterms_test.go` `TestUpsertTx` *(new)* | New directed `parent` with inverse `child` → create with `directed` true, `inverse_key` "child", no `neutral`; same → no change; `Neutral` true → update with only `neutral`; blank key, blank label, bogus origin, short property id, non-empty ID → `ErrInvalid` | AC-1.5, AC-1.6, AC-1.11, D-4 |
| T-3 | Go | `core/database/subjecttypes/subjecttypes_test.go` `TestUpsertTx` *(new)* | New `person` (`PER`, `PEC`) → create with both prefixes; same → no change; label change → only `label`; a second type taking `PER` in either column → `ErrDuplicatePrefix`; equal prefixes → `ErrDuplicatePrefix`; bad prefix, blank key, bogus origin, non-empty ID → errors as today's `Upsert` | AC-1.7, AC-1.8, AC-1.11, D-5 |
| T-4 | Go | `core/database/sourcecredibilitygrades/grades_test.go` `TestGrades` (now external) + "upsert changes" *(new case)* | New grade → create; same → no change; label → only `label`; inside `writes.Call` the grade commits and `dbtest.Revisions` stays 0; blank key or label → `ErrInvalid` | AC-1.10, AC-1.11, D-6 |
| T-5 | Go | `core/database/subjectvocab/subjectvocab_test.go` `TestBindingChanges` "ensure creates, keeps, reorders" *(new case)* | Unbound pair at 3 → create (`sort_order` 3); at 3 again → no change; at 5 → update `sort_order` {3 → 5}; short id → `ErrInvalid` | AC-1.9, D-7 |
| T-6 | Go | `core/database/subjectvocab/subjectvocab_test.go` `TestInstallRecordsOneRevision` *(new)* | Empty catalog, `install(c)` → `dbtest.Revisions` 1; `dbtest.LatestRevision` action `install_subject_vocabulary`, `len(seedTypes)+len(seedProperties)+len(seedTerms)+len(allBindings())` create changes, `user_id` NULL; `install(c)` again → still 1; a seed with a binding to type key `nope` (swap `seedBindings` in the test, restored with `t.Cleanup`) → `ErrInvalid` and `subjecttypes.List`, `properties.List` empty | AC-2.1, AC-2.2, AC-2.4, D-8 |
| T-7 | Go | `properties_test.go` "create update delete audited user property" and `propertyterms_test.go` audited cases (extended) | The changes `Create` / `Update` return hold exactly today's keys and values; `properties.Delete`'s delete change holds today's keys plus `cardinality` | AC-1.12, D-3, D-4 |
| T-8 | Go | `core/onboarding/complete_test.go` `TestComplete` (extend the case that creates a project) | After `Complete`: exactly one `audit_transactions` row with action `install_subject_vocabulary`, none with `install_source_credibility_grades`; three grades listed | AC-2.3, AC-2.5 |
| T-9 | Go | Whole suite plus the sweep | AC-3.1's `rg` → no hit; `CGO_ENABLED=1 go test -tags fts5 ./core/... ./api/...` passes (it holds `TestInstallMatchesRegistry`, `TestSeedProductValues`, `TestSwiftVocabularyMatchesGo`) | AC-3.1, AC-3.2 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: tests that count `audit_transactions` after a subject install (D-11 — `core/writes/run_test.go`, `core/database/audit/scopes_test.go`, `core/database/deleteimpact/facets_test.go`, `core/database/sources/sources_test.go` assert revisions), and `core/database/graphcache/vocab_test.go`, whose fixtures now notify the graph cache.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none)
- [ ] Sweep: `properties.Upsert`, `propertyterms.Upsert`, `subjecttypes.Upsert`, `sourcecredibilitygrades.Upsert`, `subjectvocab.EnsureBinding(`, `subjectvocab.Install(c`, `sourcecredibilitygrades.Install(c`, "un-audited seed path" and "hand-reprojecting" `rg`'d across `.agents/`, `.cursor/rules/`, `docs/*.md`, `core/**/README.md` and `L10n.swift` with no stale hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none)
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New (no UI)
- [ ] Version bump as the header says (none)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status, scope entry and bar 33 (STEP-8); completed.md: one short paragraph of what shipped
- [ ] core/writes/README.md and add-seeded-vocabulary updated (STEP-8)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Build the app from this branch and create a new project. Open **Properties**: the seeded Properties are listed, and a term-valued one (Role) shows its terms, as before.
2. Open an Evidence graph, add a Person Subject and record a Gender: the picker offers the seeded terms. Open the Source's credibility menu: Low trust, Standard, High trust.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A mechanical replace misses an unqualified call | AC-3.1's `rg` plus the build |
| A revision-counting test fails on the extra install revision | D-11: a delta from after the fixture |
| A changed audit key on a researcher path | T-7 pins every key |

**Stop and report if:**

- A helper call runs inside another write's closure and returns `database.ErrWriteReentry`; the fix is not to open a second transaction.
- `effects.Resolve` fails on a seed change for a reason other than the two missing `Entity` names, or resolving the seed's changes needs a registry change beyond D-5 and D-6.
- Keeping a researcher change's keys (AC-1.12, T-7) needs a field outside D-3's or D-4's column lists.
- A test depends on `properties.Upsert` rewriting a stored value type (D-2).
- `TestInstallMatchesRegistry`, `TestSeedProductValues` or `TestSwiftVocabularyMatchesGo` fails after STEP-6 with no test change: the seed content changed, which is Out.
- An import cycle appears that D-10 does not name.

## 12. Open questions

None.

## 13. PR

**Title:** S16-62 — The subject and grade seeds write through `writes.Run`
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-62-subject-and-grade-seeds-through-writes-run.md`.
