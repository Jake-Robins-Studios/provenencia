# S16-64 — One change builder and one change-only write call

**Status:** Landed in [#920](https://github.com/Jake-Robins-Studios/provenencia/pull/920) (2026-11-20)
**Spike / slice:** Spike 16 · Slice 6c — Shared list helpers
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: a Go refactor of how writes build and record their row changes; no view draws anything different)
**Board:** —
**Depends on:** S16-62 (landed [#912](https://github.com/Jake-Robins-Studios/provenencia/pull/912))
**Blocks:** —
**Branch:** `s16-64-one-change-builder`
**Version bump:** none — a preparatory refactor with no change a researcher can see, no wire change and no catalog format change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-catalog-query`](../../../../.agents/skills/add-catalog-query/SKILL.md), [`add-audit-scope`](../../../../.agents/skills/add-audit-scope/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests), `.cursor/rules/catalog-audit.mdc`
**Context:** map scope entry S16-64 ([`../deployment-plan.md`](../deployment-plan.md#s16-64--one-change-builder-and-one-change-only-write-call)); bar 36 (Batch 6); the S16-62 plan [`S16-62-subject-and-grade-seeds-through-writes-run.md`](S16-62-subject-and-grade-seeds-through-writes-run.md) §6 *Next adds* and its review log [`S16-62-subject-and-grade-seeds-through-writes-run.review.md`](S16-62-subject-and-grade-seeds-through-writes-run.review.md) (M-3, M-5); [`core/writes/README.md`](../../../../core/writes/README.md); [`core/database/rowchange/README.md`](../../../../core/database/rowchange/README.md)
**Planned:** 2026-11-20 against `main` @ `ff82a70` (compare with `origin/main` after `git fetch origin main`)
**Review:** [`S16-64-one-change-builder.review.md`](S16-64-one-change-builder.review.md) — round 1 Fits with changes / Not ready, round 2 Fits with changes / Ready with changes; every blocker Fixed; no To user item

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

Every catalog write builds its audit changes and runs its transaction the same way. Today nine packages carry their own `createChange` / `updateChange` (or exported `CreateChange` / `UpdateChange`) that wrap `rowchange.FullRow` / `UpdatedRow` in a `rowchange.Change` literal, and about twenty more sites build the same literal by hand. And 210 closures handed to `writes.Run` or `writes.Call` return a meaningless `struct{}{}` beside their changes. This PR adds three builders to `core/database/rowchange` (`Created`, `Updated`, `Deleted`) that take the entity type, the id and the column map, moves every builder and literal around `FullRow` / `UpdatedRow` / `DeletedRow` onto them, and adds `writes.RunChanges`, a `Run` for a closure that returns only changes, which every `struct{}` closure moves onto.

**Why now.** Bar 36 (Batch 6). S16-62's plan review (M-3, M-5) found it was adding the seventh to tenth copy of the builder pair and more adaptors; the user put the extraction in its own PR (2026-11-19).

**What stays.** Every write records the same audit JSON, key for key, under the same entity type, id and action: no test that asserts a change's fields changes its expected values. `writes.Run` and `writes.Call` stay for closures that return a value. Changes whose fields are hand-built diffs (not a column map), such as `sources.dateChange`, `observations.observationUpdateChange` and `subjectvocab.bindingOrderChange`, keep their `rowchange.Change` literal (Out). Nothing in the app changes.

## 2. User stories

**US-1.** As a contributor, when I add an audited write to a catalog package, I write its column map once and call one `rowchange` builder for its create, update and delete, so that I never copy a change-literal pair from another package.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | `rowchange.Created("property", id, {"id": "a", "label": "Born"})` | `Change{EntityType: "property", EntityID: <copy of id>, Action: "create", Fields: {"id": {nil, "a"}, "label": {nil, "Born"}}}` |
| AC-1.2 | `rowchange.Updated("property", id, {"id": 1, "label": "A"}, {"id": 1, "label": "B"}, "id")` | `&Change{…, Action: "update", Fields: {"label": {"A", "B"}}}` |
| AC-1.3 | `rowchange.Updated` with equal maps, or with only a `fixed` key differing | `nil` |
| AC-1.4 | `rowchange.Deleted("observation_note", id, {"id": "n", "body": "x"})` | `Change{…, Action: "delete", Fields: {"id": {"n", nil}, "body": {"x", nil}}}` |
| AC-1.5 | The id slice passed in is changed after the call | The returned `EntityID` is unchanged (the builder copies it) |
| AC-1.6 | The STEP-3 check command after the PR | No hit: the three helpers are unexported (`fullRow`, `updatedRow`, `deletedRow`) and only `rowchange` calls them |
| AC-1.8 | `rg -n "\{(Old: nil, )?New:|New: nil\}" core --glob '!*_test.go'` after the PR | Lists only `core/database/rowchange/change.go`, `core/database/sourcemetadata/sourcemetadata.go`, `core/database/sourcecredibility/assessments.go` and `core/database/deleteimpact/facets.go` (D-11) |
| AC-1.7 | Every catalog test that asserts an audit change's entity, action or fields (`properties`, `propertyterms`, `subjecttypes`, `sourcecredibilitygrades`, `metadatafields`, `sourcetypes`, `datevalues`, `namevalues`, `citations`, `observations`, `subjects`, `canonicalentities`, `evidencegraphs`, `sourcemetadata`, `subjectvocab`, `deleteimpact`, `audit`, `effects`, `sources`, `artifacts`, `subjectpositions`, `core/ingest`, `core/derivatives`) | Passes with no change to its expected values |

**US-2.** As a contributor, when a write returns only its changes, I hand the closure straight to `writes.RunChanges`, so that no `struct{}{}` adaptor wraps it.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | `writes.RunChanges(c, op, fn)` where `fn` returns one audited change | Same as `writes.Run` with a `struct{}` closure: one revision, the `Result` it returns names the revision and effects, listeners notified |
| AC-2.2 | `fn` returns an error | `RunChanges` returns `(Result{}, err)`; nothing is written |
| AC-2.3 | `fn` returns no change | `RunChanges` returns `(Result{}, nil)`; rolled back, no revision |
| AC-2.4 | The two STEP-6 `rg` commands after the PR (including `core/writes`) | No hit |
| AC-2.5 | The whole Go suite | Passes |

## 3. Scope

| In | Covered by |
| --- | --- |
| `rowchange.Created`, `Updated`, `Deleted` *(new)*; `FullRow`, `UpdatedRow`, `DeletedRow` unexported | STEP-1, AC-1.1 – AC-1.6 |
| The nine packages' builders move onto them and are deleted: `properties`, `propertyterms`, `subjecttypes`, `sourcecredibilitygrades`, `metadatafields` (`createChange`, `updateChange`); `datevalues` (`CreateChange`, `UpdateChange`); `namevalues` (`CreateChange`; `UpdateChange` stays, D-10); `depictionvalues` (`CreateChange`); `sourcetypes` keeps its two wrappers over the new builders (D-4) | STEP-2, AC-1.7 |
| Every other non-test `rowchange.Change{…, Fields: rowchange.FullRow/UpdatedRow/DeletedRow(…)}` literal moves onto the builders: `citations`, `observations` (`observations.go`, `write.go`), `canonicalentities`, `identityclaims`, `evidencegraphs`, `subjectvocab` (`bindingCreateChange` and its delete), `sourcemetadata`, `subjects`, `deleteimpact` (`facets.go`, `handle_gone.go`, `release.go`) | STEP-3, AC-1.6, AC-1.7 |
| Hand-written full-row create and delete literals move onto the builders (D-11) | STEP-3, AC-1.8 |
| Test files that call `FullRow` / `UpdatedRow` / `DeletedRow` move onto the builders: `core/database/effects/{deleted_handles,evidence_graphs,lists,path}_test.go`, `core/database/audit/audit_test.go` | STEP-3, AC-1.6 |
| `writes.RunChanges` *(new)* | STEP-4, AC-2.1 – AC-2.3 |
| Every `struct{}` closure handed to `writes.Run` / `writes.Call` (210 at the planning base, in 73 files: 26 in `api/ffi/handlers`, `onboarding.installSeed`, the rest in tests and test helpers) moves onto `RunChanges`; `promote.SaveBatch` returns `([]rowchange.Change, error)`; test helpers that take a `struct{}` closure take a change-only closure | STEP-5, STEP-6, AC-2.4, AC-2.5 |
| Guidance names the new builders and `RunChanges` | STEP-7 |

| Out | Home |
| --- | --- |
| Change literals whose fields are hand-built `FieldDiff`s, not a column map: `namevalues.UpdateChange` (D-10), `sources.dateChange`, `observations.observationUpdateChange`, `subjectvocab.bindingOrderChange`, `sourcemetadata.layoutChange`, `sourcecredibility` assessments, the `core/database/deleteimpact/facets.go` re-point and the other `rowchange.Change{` literals that diff chosen fields | not planned — they diff chosen fields, which a column-map builder does not express; a later PR that touches one may move it if its fields become a map |
| Any change to what a write records, resolves or returns | not planned (map: "Not this PR") |
| A `writes.Call`-style variant of `RunChanges` that drops the `Result` | not planned (D-5) |
| Package constants naming each entity type | not planned (D-3) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Row helpers | `core/database/rowchange/change.go` `FullRow`, `DeletedRow`, `UpdatedRow` | Build only the `Fields` map; every caller wraps it in a `Change{EntityType, EntityID, Action, Fields}` literal by hand. `UpdatedRow(old, now, fixed...)` came from `9341656` |
| Row helper tests | `core/database/rowchange/change_test.go` `TestUpdatedRow` | Table test of `UpdatedRow` (equal, changed, only in now, only in old, fixed skipped) |
| Builders (pair) | `core/database/properties/properties.go` `createChange`, `updateChange` (fixed `"id", "key", "origin"`; callers lines 145, 155, 217, 262) | Literal around `FullRow` / `UpdatedRow`, entity `"property"`, id copied from `p.ID` / `prev.ID` |
| | `core/database/propertyterms/propertyterms.go` `createChange`, `updateChange` (callers 162, 170, 222, 258) | Same shape, entity `"property_term"`, fixed `"id", "property_id", "key", "origin"` |
| | `core/database/subjecttypes/subjecttypes.go` `createChange`, `updateChange` (callers 164, 169) | Same shape |
| | `core/database/sourcecredibilitygrades/grades.go` `createChange`, `updateChange` (callers 103, 110) | Same shape |
| | `core/database/metadatafields/metadatafields.go` `createChange`, `updateChange` (callers 157, 164, 211, 247); its delete builds a `DeletedRow` literal | Same shape, entity `"metadata_field"`, fixed `"id", "key", "origin"` |
| | `core/database/sourcetypes/sourcetypes.go` `createChange(t, formats)`, `updateChange(prev, next, formats)` (callers `sourcetypes.go` 187, 200, 201, 322, 355; `formats.go` 468); delete builds a `DeletedRow` literal | Like the others, plus the format columns: `createChange` adds `formatFieldDiffs(Formats{}, formats)` into the create fields; `updateChange` adds the passed format diffs, then returns nil when the merged map is empty |
| | `core/database/datevalues/datevalues.go` `CreateChange`, `UpdateChange` (callers `PutTx` 189, 198 only) | `UpdateChange` takes the id from `prev.ID`, else `next.ID`; in `PutTx` both are `prevID` |
| | `core/database/namevalues/namevalues.go` `CreateChange`, `UpdateChange` (callers `PutTx` 188, 197 only) | `CreateChange` is the same shape as `datevalues`'. `UpdateChange` is not a column-map diff: it compares `form` with `!=` and `parts` with `partsEqual`, because `RowMap`'s `"parts"` is a `[]map[string]any` that `UpdatedRow`'s `!=` would panic on |
| | `core/database/depictionvalues/depictionvalues.go` `CreateChange` | Called once, from `core/database/observations/depiction.go` line 68 |
| Literals | `core/database/citations/citations.go` (2 `FullRow`), `core/database/observations/observations.go` (2 `FullRow`), `core/database/observations/write.go` (1 `FullRow`, 2 `DeletedRow`), `core/database/canonicalentities/canonicalentities.go` (1), `core/database/identityclaims/identityclaims.go` (1), `core/database/evidencegraphs/evidencegraphs.go` (2 `FullRow`, 1 `DeletedRow`), `core/database/subjectvocab/subjectvocab.go` (`bindingCreateChange` and the delete at 370), `core/database/sourcemetadata/sourcemetadata.go` (1 `FullRow`, 1 `DeletedRow`), `core/database/subjects/subjects.go` (1), `core/database/deleteimpact/facets.go` (4 `DeletedRow`), `core/database/deleteimpact/handle_gone.go` (1), `core/database/deleteimpact/release.go` (1, returns `*rowchange.Change`) | A `rowchange.Change{…}` literal around one of the helpers. Find them all with `rg -n "rowchange\.(FullRow\|UpdatedRow\|DeletedRow)\(" core api --glob '!core/database/rowchange/**'` |
| Literals in tests | `core/database/effects/deleted_handles_test.go` (3), `evidence_graphs_test.go` (1), `lists_test.go` (11), `path_test.go` (1), `core/database/audit/audit_test.go` (2) | Build fixture changes with the exported helpers |
| Write call | `core/writes/run.go` `Run[T]`, `Call[T]` | Generic over the closure's value; a closure with no value returns `struct{}{}` |
| Adaptors (non-test) | `api/ffi/handlers/*.go` (26 closures in `subjects.go`, `source_defs.go`, `subject_defs.go`, `property_terms.go`, `conclusion_detail.go`, `citations.go`, `observations.go`, `evidence_graphs.go`, `promote.go`, `promote_batch.go`, `metadata.go`, `artifacts.go`, `sources.go`); `core/onboarding/ready.go` `installSeed`; `core/database/promote/batch.go` `SaveBatch` (returns `(struct{}, []rowchange.Change, error)` and is passed straight to `writes.Run` in `promote_batch.go`) | `_, wrote, err := writes.Run(…, func(tx) (struct{}, []rowchange.Change, error) { changes, err := pkg.Fn(tx, …); return struct{}{}, changes, err })` |
| Adaptors (tests) | 182 closures in tests and test helpers; helpers that take a `struct{}` closure: `core/database/evidencelayer/evidencelayertest/evidencelayertest.go` (`Records.Run` → private `run`), `core/database/sourcecopy/sourcecopy_test.go` `writeOne`, `core/database/observations/observationstest/observationstest.go`, `core/database/subjectvocab/subjectvocabtest`, `sourcevocab/sourcevocabtest`, `sourcecredibilitygrades/sourcecredibilitygradestest`, `evidencegraphs/evidencegraphstest` | Same adaptor. Find them all with `rg -n "\(struct\{\}, \[\]rowchange\.Change, error\)" core api` (210 lines, 73 files) |
| Guidance | `core/database/rowchange/README.md` (names `FullRow`, `DeletedRow`, `UpdatedRow`); `core/writes/README.md` (`Run` / `Call` paragraph); `.agents/skills/add-audit-scope/SKILL.md` line 61 and `.agents/skills/add-catalog-delete/SKILL.md` line 58 and `.cursor/rules/catalog-audit.mdc` line 13 (`DeletedRow`); `.agents/skills/add-date-value/SKILL.md` line 66, `.agents/skills/add-name-value/SKILL.md` line 65, `.cursor/rules/name-values.mdc` line 11 (`CreateChange` / `UpdateChange`); `.agents/skills/add-depiction-value/SKILL.md` line 39 (`depictionvalues.CreateChange`); `.agents/skills/add-seeded-vocabulary/SKILL.md` lines 89, 95 (`installSeed`, one `writes.Call`) | Name the functions this PR replaces |
| Tests that pin audit JSON | `*_test.go` in `properties`, `propertyterms`, `subjecttypes`, `sourcecredibilitygrades`, `metadatafields`, `sourcetypes`, `datevalues`, `namevalues`, `citations`, `observations`, `subjects`, `canonicalentities`, `evidencegraphs`, `sourcemetadata`, `subjectvocab`, `deleteimpact`, `audit`, `effects` | Assert entity, action and fields of the changes these builders make. They are the proof that nothing moved (AC-1.7) |

**Precedent.** `9341656` ("Share one row-diff helper across the date value, Source type and metadata field update audit changes") moved three packages' hand-written diffs onto `rowchange.UpdatedRow` and added its table test. Copy its shape: one helper in `rowchange`, a table test beside it, call sites rewritten without touching any test's expected values. S16-62 ([#912](https://github.com/Jake-Robins-Studios/provenencia/pull/912)) made the per-package `createChange` / `updateChange` this PR removes; do not copy those.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `rowchange` gains `func Created(entity string, id []byte, fields map[string]any) Change`, `func Updated(entity string, id []byte, old, now map[string]any, fixed ...string) *Change` and `func Deleted(entity string, id []byte, fields map[string]any) Change`. Each copies `id` (`append([]byte(nil), id...)`). `Updated` returns nil when `updatedRow` is empty. | The map's scope entry ("take the entity type, the id and the column map"). Value for create and delete, pointer for update, matches what every caller holds today (`createChange` returns a value, `updateChange` a pointer). Copying is what most callers already do; for the rest (`facets.go`, `write.go`) a copy changes no byte stored | A `rowchange.Table{Entity, Fixed}` value with methods — because `deleteimpact` names its entity per row and would build a throwaway `Table` each time; one more concept for four packages' fixed keys. An `Action` parameter on one function — because the update path's nil return differs |
| D-2 | `FullRow`, `UpdatedRow`, `DeletedRow` become unexported (`fullRow`, `updatedRow`, `deletedRow`) once their last outside caller moves (STEP-3). `TestUpdatedRow` becomes `TestBuilders` *(new name)*, a table over the three builders that keeps all five of today's `UpdatedRow` cases through `Updated`. | Bar 36 says no package builds its own change around its column list; unexporting makes the compiler hold that, and AC-1.6's `rg` checks it | Keeping them exported — because the next package would wrap them in a literal again |
| D-3 | The entity type stays a string literal at each call site, as the code writes it today. No package gains an entity constant; `subjectvocab` keeps `bindingEntity`. Fixed keys are passed literally at each `Updated` call, copied from the deleted function: `"id", "key", "origin"` in `properties`, `subjecttypes`, `sourcecredibilitygrades` and `metadatafields`; `"id", "property_id", "key", "origin"` in `propertyterms`; `"id"` in `datevalues`. | The literals already exist one per builder; a constant per package is new boilerplate the map's "keeps only its rowFields" excludes. At most two `Updated` calls per package repeat the fixed keys | A package `const entityType` — because it re-creates the per-package scaffolding this PR removes |
| D-4 | `sourcetypes` keeps `createChange` and `updateChange` as private wrappers over `Created` / `Updated`, because the format columns are extra fields. `createChange` builds `rowchange.Created("source_type", t.ID, rowFields(t))` and then adds `formatFieldDiffs(Formats{}, formats)` into its `Fields`. `updateChange` copies `rowFields(prev)` and `rowFields(next)` into `old` / `now`, sets `old[col], now[col] = d.Old, d.New` for each passed format diff, and returns `rowchange.Updated("source_type", prev.ID, old, now, "id", "key", "origin")`. | A format diff exists only when the texts differ, and `database.NullString` maps them to distinct values, so `updatedRow` reproduces each diff exactly and the nil-when-empty rule still holds. Six call sites keep one wrapper each instead of repeating the merge | Inlining the merge at six call sites — because it repeats four lines six times. Adding a "plus extra diffs" parameter to `Updated` — because only this package needs it |
| D-5 | `core/writes` gains `func RunChanges(c *database.Catalog, op Op, fn func(tx *database.Tx) ([]rowchange.Change, error)) (Result, error)`. It holds today's body of `Run` (begin, the closure, `AllNone`, `Resolve`, `audit.Record`, recompute, reproject, commit, `AfterCommit`, `Notify`) unchanged, and `Run[T]` becomes a wrapper that calls `RunChanges` with a closure capturing the closure's value (`v, ch, err := fn(tx); value = v; return ch, err`) and returns `(value, res, nil)`, or `(zero, Result{}, err)` on error. `Call` is unchanged. It returns `Result`, not only `error`. | Every handler closure but `installSeed`'s read the `Result` (`writeEffectsProto(wrote)`), so an `error`-only `RunChanges` would leave them on `Run` with the adaptor. Sites that drop it write `_, err :=` as they drop `Call`'s value today. This differs from the map's sketch (`… error`); STEP-8 updates the scope entry | A `RunChanges` returning `error` plus a second name returning `Result` — because one function covers both, and a second name is a second thing to choose between |
| D-6 | Every closure of type `func(*database.Tx) (struct{}, []rowchange.Change, error)` moves, not only the 131 that end `return struct{}{}, changes, err`. A closure body that only forwards (`changes, err := pkg.Fn(tx, …); return struct{}{}, changes, err`) becomes `return pkg.Fn(tx, …)`. Multi-statement bodies keep their statements and return `(changes, err)` / `(nil, err)`. | The other 79 (variable names `ch`, `nil` early returns, `append(...)`) are the same adaptor; leaving them would keep the pattern bar 36 removes | Moving only the exact text — because the next reader copies the survivors |
| D-7 | `promote.SaveBatch` returns `([]rowchange.Change, error)`, and `promote_batch.go` passes it to `RunChanges` through a closure that binds its arguments. | It is a `Run` closure in disguise; the `struct{}` in a package API is the same adaptor | Leaving its signature — because `rg` AC-2.4 would still hit it |
| D-8 | Test helpers that take a `struct{}` closure take `func(*database.Tx) ([]rowchange.Change, error)` and call `writes.RunChanges`. Their names and other parameters do not change. `evidencelayertest`'s `Records.Run`, which already takes a change-only closure and wraps it for the generic `run`, calls `writes.RunChanges` itself (`res, err := writes.RunChanges(r.C, writes.Op{Action: action, UserID: UserID}, fn)`, `Must(r.T, err)`, `r.Reported = res.Effects.SummaryDeps`); `run` stays for the value-returning helpers. | Same adaptor, one level down | Leaving test helpers generic over `T` — because no caller passes a value |
| D-11 | A hand-written create or delete literal whose every field is `{Old: nil, New: v}` (create) or `{Old: v, New: nil}` (delete) moves onto `Created` / `Deleted`: its `map[string]rowchange.FieldDiff` becomes a `map[string]any` with the same keys, the same values and the same conditions. The sites at the planning base: `core/database/sources/sources.go` (`Create`, lines 145–161; the delete, 483–505), `core/database/sources/notes.go` (create near 104, delete near 166), `core/database/artifacts/artifacts.go` (create 118–137, delete 272–287), `core/database/subjects/subjects.go` (delete 238–254), `core/ingest/file.go` (file create near 145), `core/derivatives/ensure.go` `fileDerivativeChange` (326), and the create branch of `core/database/subjectpositions/subjectpositions.go` (lines 61–79, written `{New: v}`), which becomes an early `return pos, []rowchange.Change{rowchange.Created("subject_position", subjectID, map[string]any{"subject_id": …, "grid_x": gridX, "grid_y": gridY})}, nil` after the update branch, whose literal stays (it always records both grid columns). Mixed literals stay: `core/database/sourcemetadata/sourcemetadata.go` `layoutChange` and its layout fields, `core/database/sourcecredibility/assessments.go` (one map for a create or an update), `core/database/deleteimpact/facets.go` line 648 (a re-point that clears one FK). | Bar 36: no package builds its own create or delete around its column list; these are the same full-row changes the builders make, so the audit JSON is byte-identical (maintainability review M-1) | Leaving them — because `sources.Create`, the write most copied, would keep teaching the literal |
| D-12 | Test fixtures that pass a bare field map move as whole changes. In `core/database/effects/lists_test.go`, each table row that passes `full` or a `rowchange.FullRow(…)` map to `held`, `source` or `entity` calls the builder directly instead: a create row `rowchange.Created("<that helper's entity>", id(<b>), map[string]any{…})`, a delete row `rowchange.Deleted(…)` with the same map; `full` goes, and `held`, `source` and `entity` keep their signatures for the update rows. Every `want` stays. In `core/database/effects/path_test.go` `del` becomes `rowchange.Deleted(entity, entityID, old)`. `deleted_handles_test.go` and `evidence_graphs_test.go` use the same rule. The two cases "FullRow keeps null keys" and "DeletedRow keeps null keys" in `core/database/audit/audit_test.go` move into T-1 as `Created` / `Deleted` cases with the same maps and wants, and leave `audit_test.go`. | A builder returns a whole `Change`, so a fixture that only wanted its `Fields` would otherwise grow a `.Fields`-of-a-builder idiom; `rowchange` is tested in one place (round-2 review M-7). The two delete rows built from full-row fields keep their `want`: `core/database/effects/registry.go` picks `ListMetadataFieldUsage` and `ListCounts` by entity and action, not by field values | `rowchange.Created("", nil, m).Fields` in fixtures — because it is an idiom nobody should copy |
| D-10 | `namevalues.UpdateChange` stays as it is, a hand-built diff. Only `namevalues.CreateChange` moves (onto `Created`). | Its `parts` column is a slice; `updatedRow` compares with `!=` and would panic on it. Teaching `Updated` deep equality for one package's column is a second comparison rule in `rowchange` | `reflect.DeepEqual` in `updatedRow` — because it changes how every other map compares for one caller |
| D-9 | Test files and assertions change only where they build a closure or call a removed helper. No expected value in any test changes. | AC-1.7 is the proof that the audit JSON is unchanged | — |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `rowchange.Created` *(new)* | func | `rowchange.FullRow` + nine `createChange` / `CreateChange` | It is the extension: `FullRow` becomes its private body |
| `rowchange.Updated` *(new)* | func | `rowchange.UpdatedRow` + eight `updateChange` / `UpdateChange` | Same: `UpdatedRow` becomes its private body |
| `rowchange.Deleted` *(new)* | func | `rowchange.DeletedRow` + ~12 literals | Same |
| `writes.RunChanges` *(new)* | func | `writes.Run`, `writes.Call` | It takes `Run`'s body; `Run` becomes the wrapper that carries a value, so no `struct{}` adaptor is left anywhere, `core/writes` included |
| `TestBuilders` *(renamed from `TestUpdatedRow`)* | test | `core/database/rowchange/change_test.go` `TestUpdatedRow` | Extended in place |
| `TestRunChanges` *(new)* | test | `core/writes/run_test.go` | Added beside the `Run` tests, reusing their fixture |

**Builds on.** `9341656`'s `UpdatedRow`; `writes.Run`; the column maps each package already has (`rowFields`, `RowMap`, `AuditFields`, `graphFields`, `linkFields`, `bindingFields`, `auditFields`).
**Deletes.** `createChange` and `updateChange` in `properties`, `propertyterms`, `subjecttypes`, `sourcecredibilitygrades`, `metadatafields`; `CreateChange` and `UpdateChange` in `datevalues`; `namevalues.CreateChange`; `depictionvalues.CreateChange`; `subjectvocab.bindingCreateChange` (its two callers, `subjectvocab.go` lines 132 and 208, call `rowchange.Created(bindingEntity, propertyID, bindingFields(typeID, propertyID, order))`); the exported `FullRow`, `UpdatedRow`, `DeletedRow`; 210 `struct{}` adaptors. Every doc comment on a deleted function goes with it.
**Next adds.** A new audited catalog package writes a column map and calls `rowchange.Created` / `Updated` / `Deleted`; a new FFI write handler calls `writes.RunChanges`. `add-catalog-query` and `add-audit-scope` name both (STEP-7).

### Reach

None — no new path into existing code, no new state reachable.

### Scale

None — no write, list or loop changes: each write builds the same changes in the same transaction. One extra slice copy per change where a caller did not copy before (`facets.go`, `write.go`, `citations.go`): 16 bytes each.

### Edges

- **Assumptions.** `updatedRow` compares values with `!=`, so every value in a column map must be comparable (strings, numbers, bools, nil); every map this PR passes to `Updated` holds only those (`database.UUIDString` / `UUIDJSON` return strings); `namevalues.RowMap`'s `parts` slice is the one non-comparable value, which is why its update stays hand-built (D-10). `Created` and `Deleted` never compare, so `namevalues.RowMap` is safe there. D-4's format merge adds strings or nil only. Held by the existing package tests (AC-1.7).
- **Neighbors.** `Updated` with a map where only a fixed key differs → nil (AC-1.3, T-1). `sourcetypes` update with no column change but a format change → a change naming only the format column (`sourcetypes_test.go` today; T-4 must stay green). A `datevalues.PutTx` with an equal value → no change, no write (`datevalues_test.go`).
- **Removed inputs.** None — the builders take the same inputs the literals did.
- **Real data.** None — no table-driven rule changes.
- **Untrusted size.** None — no list read from data the app did not write.

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/rowchange` | `Created`, `Updated`, `Deleted` *(new)* per D-1; `FullRow` → `fullRow`, `UpdatedRow` → `updatedRow`, `DeletedRow` → `deletedRow` (D-2) |
| `core/database/{properties,propertyterms,subjecttypes,sourcecredibilitygrades,metadatafields}` | `createChange` / `updateChange` deleted; call sites `rowchange.Created("<entity>", x.ID, rowFields(x))` and `rowchange.Updated("<entity>", prev.ID, rowFields(prev), rowFields(next), <fixed keys per D-3>)`, with the entity and fixed keys copied from the deleted function. Delete literals → `rowchange.Deleted` |
| `core/database/sourcetypes` | `createChange` / `updateChange` rewritten per D-4; the delete (line 429) builds `ch := rowchange.Deleted("source_type", id, rowFields(prev))` and then adds `formatFieldDiffs(formats[string(id)], Formats{})` into `ch.Fields`, as `createChange` does |
| `core/database/datevalues` | `CreateChange` / `UpdateChange` deleted; `PutTx` calls `rowchange.Created("date_value", id, RowMap(id, v))` and `rowchange.Updated("date_value", prevID, RowMap(prev.ID, prev), RowMap(next.ID, next), "id")` |
| `core/database/namevalues` | `CreateChange` deleted; `PutTx` calls `rowchange.Created("name_value", id, RowMap(id, v))`; `UpdateChange` unchanged (D-10) |
| `core/database/depictionvalues` | `CreateChange` deleted; `core/database/observations/depiction.go` calls `rowchange.Created("depiction_value", id, depictionvalues.RowMap(id, v))` |
| Literal sites (§4 "Literals") | Each `rowchange.Change{EntityType: e, EntityID: id, Action: create/delete, Fields: rowchange.FullRow/DeletedRow(m)}` → `rowchange.Created/Deleted(e, id, m)`; a site that returns `*rowchange.Change` (`core/database/deleteimpact/release.go`) writes `ch := rowchange.Deleted(entity, prevID, row); return &ch, nil` |
| `core/writes` | `RunChanges` *(new)* per D-5 takes `Run`'s body and doc comment (its first sentence names `RunChanges`; the rest is unchanged); `Run`'s doc comment becomes "Run is RunChanges for a closure that also returns a value: the created or updated row." |
| `core/database/promote` | `SaveBatch(tx, userID, in) ([]rowchange.Change, error)` (D-7) |
| `core/onboarding/ready.go` | `installSeed` calls `writes.RunChanges(c, writes.Op{Action: action}, install)` and returns its error |

```go
// Created is the create change of one row: every column, old nil, new the value.
func Created(entity string, id []byte, fields map[string]any) Change

// Updated is the update change from old to now, naming only the columns that
// differ (a key missing from one side reads nil) and never the fixed ones;
// nil when none does.
func Updated(entity string, id []byte, old, now map[string]any, fixed ...string) *Change

// Deleted is the delete change of one row: every column, old the value, new nil.
func Deleted(entity string, id []byte, fields map[string]any) Change

// RunChanges begins a transaction, runs fn, and on a non-empty change list records
// audit (the rest of today's Run comment, unchanged).
func RunChanges(c *database.Catalog, op Op, fn func(tx *database.Tx) ([]rowchange.Change, error)) (Result, error)
```

Errors: none new.

### FFI

None — no proto change. The handlers in `api/ffi/handlers` change only their closures (STEP-5).

### macOS

None — no Swift change.

### Strings

None — no user-facing copy.

## 7. Steps

**STEP-1 — The three builders**
Files: `core/database/rowchange/change.go`, `change_test.go`. Skill: `add-audit-scope`.
Do: add `Created`, `Updated`, `Deleted` (D-1) beside the exported helpers; leave the helpers exported for now. Turn `TestUpdatedRow` into `TestBuilders` (T-1).
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/rowchange/` passes.

**STEP-2 — The nine packages' builders**
Files: the packages in §6 Go core rows 2–5, and `core/database/observations/depiction.go`.
Do: delete each `createChange` / `updateChange` / `CreateChange` / `UpdateChange` (except `sourcetypes`, D-4), rewrite each caller per §6, and move each package's delete literal onto `Deleted`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/properties/ ./core/database/propertyterms/ ./core/database/subjecttypes/ ./core/database/sourcecredibilitygrades/ ./core/database/metadatafields/ ./core/database/sourcetypes/ ./core/database/datevalues/ ./core/database/namevalues/ ./core/database/depictionvalues/ ./core/database/observations/ ./core/database/subjectvocab/ ./core/database/sourcevocab/` passes with no test's expected value edited; `rg -n "func (createChange|updateChange|CreateChange|UpdateChange)\(" core` finds only the two in `sourcetypes` and `namevalues.UpdateChange`.

**STEP-3 — Every other helper literal, then unexport**
Files: §4 "Literals" and "Literals in tests"; `core/database/rowchange/change.go`, `README.md`.
Do: move each literal onto `Created` / `Deleted` (and `Updated` if any), the D-11 literals, and the test fixtures per D-12; then rename `FullRow` → `fullRow`, `UpdatedRow` → `updatedRow`, `DeletedRow` → `deletedRow` (D-2), and reword the README paragraph starting "`FullRow` is a create" to name `Created`, `Updated`, `Deleted`.
Check: `rg -n "rowchange\.(FullRow|UpdatedRow|DeletedRow)\b" core api` finds nothing; AC-1.8's `rg` lists only its four files; `CGO_ENABLED=1 go test -tags fts5 ./core/ingest/ ./core/derivatives/ ./core/database/subjectpositions/` passes; `CGO_ENABLED=1 go build -tags fts5 ./api/... ./core/...` and `CGO_ENABLED=1 go test -tags fts5 ./core/database/...` pass.

**STEP-4 — `writes.RunChanges`**
Files: `core/writes/run.go`, `run_test.go`, `README.md`.
Do: move `Run`'s body into `RunChanges` and make `Run` its wrapper (D-5); add `TestRunChanges` (T-2). Reword the paragraphs starting "`Run` begins one transaction" and "`Run` is generic" (dropping "(or nothing, for a delete)") to say `RunChanges` begins the transaction, that its closure returns the changes, and that `Run` is `RunChanges` for a closure that also returns the created or updated row; `Call` is `Run` with the revision discarded.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/writes/` passes, the existing `Run` tests unchanged.

**STEP-5 — Non-test adaptors**
Files: `api/ffi/handlers/*.go` (the 26 closures in §4), `core/onboarding/ready.go`, `core/database/promote/batch.go`, `api/ffi/handlers/promote_batch.go`.
Do: each `_, wrote, err := writes.Run(…, struct{} closure)` → `wrote, err := writes.RunChanges(…, change-only closure)`; `_, err := writes.Call(…)` → `_, err := writes.RunChanges(…)`; closure bodies per D-6. `SaveBatch` per D-7, its error returns becoming `return nil, err`.
Check: `rg -n "\(struct\{\}, \[\]rowchange\.Change, error\)" api core --glob '!*_test.go' --glob '!*test/**'` finds nothing; `CGO_ENABLED=1 go test -tags fts5 ./api/... ./core/onboarding/ ./core/database/promote/` passes.

**STEP-6 — Test adaptors and helpers**
Files: every file `rg -n "\(struct\{\}, \[\]rowchange\.Change, error\)" core api` still lists (the test helpers named in §4 first, then their callers).
Do: per D-6, D-8, D-9, one package at a time; after each package run `CGO_ENABLED=1 go test -tags fts5 ./<that package>/...`. Other test helpers keep their return types; only their closure parameter and the `writes` call inside change. A `_, _, err := writes.Run(…)` becomes `_, err := writes.RunChanges(…)`; a `_, res, err := writes.Run(…)` becomes `res, err := writes.RunChanges(…)`.
Check: `rg -n "return struct\{\}\{\}, " core api` and `rg -n "\(struct\{\}, \[\]rowchange\.Change, error\)" core api` find nothing; `CGO_ENABLED=1 go vet -tags fts5 ./api/... ./core/...` and `CGO_ENABLED=1 go test -tags fts5 ./api/... ./core/...` pass.

**STEP-7 — Guidance**
Files: `.agents/skills/add-audit-scope/SKILL.md`, `.agents/skills/add-catalog-delete/SKILL.md`, `.cursor/rules/catalog-audit.mdc` (`DeletedRow` → `rowchange.Deleted`); `.agents/skills/add-date-value/SKILL.md` (`RowMap` builds the audit row; `rowchange.Created` / `Updated` make the change); `.agents/skills/add-name-value/SKILL.md`, `.cursor/rules/name-values.mdc` (`RowMap` builds the audit row; `rowchange.Created` makes the create change and `UpdateChange` the update, which diffs `form` and `parts` itself); `.agents/skills/add-depiction-value/SKILL.md` (`rowchange.Created` over `depictionvalues.RowMap`); `.agents/skills/add-seeded-vocabulary/SKILL.md` lines 89 and 95 (`writes.Call` → `writes.RunChanges`: `installSeed`, one `writes.RunChanges`); `.agents/skills/add-catalog-query/SKILL.md` line 46: replace its first sentence ("Research writes call `audit.Record` in the same tx.") with "A research write builds each change with `rowchange.Created`, `Updated` or `Deleted` over the package's column map and returns it; `writes.Run` (a write with a value) or `writes.RunChanges` (a write with none) records it in the same transaction."; `core/writes/README.md` last paragraph: "The FFI handlers call `Run`" becomes "The FFI handlers call `Run` or `RunChanges`".
Do: replace each old name with the new one, keeping the surrounding sentence.
Check: `rg -n "FullRow|UpdatedRow|DeletedRow|CreateChange|bindingCreateChange" .agents .cursor docs/*.md core --glob '*.md' --glob '*.mdc'` finds nothing, and `rg -n "UpdateChange" .agents .cursor docs/*.md core --glob '*.md' --glob '*.mdc'` finds only the two `namevalues` lines; `rg -n "writes\.Call" .agents .cursor` finds nothing; `rg -n "call .audit\.Record. in the same tx|or nothing, for a delete" .agents core --glob '*.md'` finds nothing; `python3 scripts/check-guidance-names.py` passes.

**STEP-8 — Docs**
Files: `docs/deployment-plan/spike-16/completed.md`, `deployment-plan.md` (map row status), this plan (status, Landed note).
Do: per the Definition of done.
Check: links resolve; `scripts/check-pr.sh` prints `check-pr: PASS`.

Commits: one per behavior. The subject is one full imperative sentence ending in a period, like the rest of `git log` ("Build every create, update and delete audit change through one rowchange builder.", "Run change-only writes through writes.RunChanges."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/rowchange/change_test.go` `TestBuilders` *(renamed from `TestUpdatedRow`)* | Table: the five `UpdatedRow` cases through `Updated` (equal → nil; changed → one diff; only in now; only in old; fixed skipped → nil); `Created` of a two-key map → create change, entity and id set, every old nil; `Deleted` → every new nil; id mutated after the call → `EntityID` unchanged; the two null-key cases moved from `audit_test.go` (D-12) | AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5, D-1 |
| T-2 | Go | `core/writes/run_test.go` `TestRunChanges` *(new)* | Table on the `Run` tests' fixture (copy its catalog setup and `recListener` from `run_test.go`): one audited change → non-zero `Result.Activity.Revision` and `recListener.OnCommit` called once; closure error → `Result{}` and the error, and `SELECT COUNT(*) FROM audit_transactions` unchanged; no change → `Result{}`, nil, and the same count unchanged | AC-2.1, AC-2.2, AC-2.3, D-5 |
| T-3 | Go | Every existing package test named in AC-1.7, unchanged | Same expected entity, action and fields as at `ff82a70` | AC-1.7, AC-1.8, D-9, D-11 |
| T-4 | Go | `core/database/sourcetypes/sourcetypes_test.go` (existing, unchanged) | Format-only update → change naming only the format column; create with formats → create fields plus the non-empty format columns | D-4 |
| T-5 | Go | `api/ffi/handlers` suite (existing, unchanged) | Every write handler returns the same effects | AC-2.5, D-5 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `core/database/deleteimpact` (pointer return in `release.go`), `core/database/sourcetypes` (D-4), `core/database/evidencelayer` (`evidencelayertest` helper), `api/ffi/handlers`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or the rg command and its empty output for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks); on Linux the Xcode leg is skipped and CI runs it — no Swift file changes
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] No test's expected value changed (git diff on *_test.go shows only closures, helper signatures and builder calls)
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left — none in this PR
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated — none
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New — no UI
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated) — not gated
- [ ] Domain doc updated if a rule in docs/*.md changed — none; the package READMEs (rowchange, writes) are STEP-3 and STEP-4
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Run `rg -n "return struct\{\}\{\}, " core api`, `rg -n "\(struct\{\}, \[\]rowchange\.Change, error\)" core api` and `rg -n "rowchange\.(FullRow|UpdatedRow|DeletedRow)\b" core api`. Each prints nothing (bar 36; AC-1.6, AC-2.4).
2. Run `git diff main -- '*_test.go' | grep '^[-+].*want'`. No expected value moved.
3. Create a new project in the app, add a Source, edit its title, delete it. The Sources list and its Updated column behave as before.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A mechanical rewrite of 210 closures drops a statement from a multi-statement body | D-6 keeps every statement; STEP-6's full Go suite; DoD line on unchanged expected values |
| `sourcetypes`' format merge (D-4) differs from today's diff for some column | T-4 (existing tests) pins create and format-only update; Stop condition below |
| A literal site relied on not copying the id (an alias later mutated) | No site mutates `EntityID` after building a change at the planning base; Stop condition below |

**Stop and report if:**

- A test assertion's expected entity, action or fields must change to pass (the builders changed what is recorded; D-9).
- `rg -n "\(struct\{\}, \[\]rowchange\.Change, error\)" core api` at your base counts other than 210 lines, or `rg -n "rowchange\.(FullRow|UpdatedRow|DeletedRow)\(" core api --glob '!core/database/rowchange/**' --glob '!*_test.go'` other than 43 lines — `main` moved; report the new sites before starting.
- A `struct{}` closure's value is read by its caller (a site that uses the first return of `Run` / `Call`).
- A column map passed to a builder holds a non-comparable value (a slice or map), so `updatedRow` would panic.
- Any code writes to a change's `EntityID` after building it.
- A D-12 fixture row in `core/database/effects/lists_test.go` fails with its `want` unchanged once its fields move from `{nil → v}` to the builder's shape (the registry reads field values there).

## 12. Open questions

None.

## 13. PR

**Title:** S16-64 — One change builder and one change-only write call
**Body:** objective in one sentence; what shipped against US-1 and US-2; the three `rg` outputs of the manual check; deviations from the plan; `Plan: docs/deployment-plan/spike-16/prs/S16-64-one-change-builder.md`.

---

## Landed

- `main` had moved from the Planned commit to `34c2b6155`; no **Current state** row changed, and the 210 and 43 line counts held.
- `core/database/sourcecopy/sourcecopy_test.go` `writeOne` stayed generic over the closure's value (five of its six callers return one); its one `struct{}` caller calls `writes.RunChanges` directly. D-8's other helpers moved as planned.
- `TestBuilders` also decodes each built change's fields through JSON and checks a null column stays null (the check `audit_test.go` held for the two moved cases).
- The STEP-7 `rg` for `UpdatedRow` also matches the unrelated name `CatalogLastUpdatedRow` in `.agents/skills/add-workspace-place/SKILL.md`; left as is.
- A comment in `core/database/deleteimpact/facets.go` that named `DeletedRow` now names `rowchange.Deleted`.
