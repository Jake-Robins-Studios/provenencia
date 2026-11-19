# Review — S15-52 The Source seed writes through `writes.Run`

Plan: [`S15-52-source-seed-through-writes-run.md`](S15-52-source-seed-through-writes-run.md). Lint: `scripts/check-plan-docs.py` clean once this log exists.

## Round 1 (2026-11-19)

Maintainability: **Fits with changes** (three blockers). Executability: **Ready with changes**.

### Maintainability

| ID | Severity | Finding | Answer |
| --- | --- | --- | --- |
| M-1 | blocker | `UpsertTx` inserted through `sqlUpsert` beside `Create`'s `sqlInsert`; both packages' `ON CONFLICT` clauses would be dead | **Fixed.** D-1: types insert with `sqlInsert`, `sqlUpsert` deleted. D-2: fields' `sqlUpsert` renamed `sqlInsert` without the conflict clause. The Out row went. S15-19 D-8 now puts formats in that insert |
| M-2 | blocker | A second field UPDATE (`sqlUpsertUpdate`) and a diff split in two | **Fixed.** D-2: one `sqlUpdate` with `data_type`; `Update` passes the stored type |
| M-3 | blocker | `ensureSuggestionTx` beside `EnsureSuggestion`, kept only for tests, checks copied | **Fixed.** D-4: `EnsureSuggestion` deleted; its two test callers move to `AppendSuggestion` and to `ensureSuggestionTx` in `writes.Call` |
| M-4 | major | Positional change builders instead of the repo's row-map shape; `Delete` a third copy | **Fixed.** D-9: `rowFields` and `updateChange` per package, as `datevalues`; `Create`, `Update`, `Delete`, `UpsertTx` use them; audit JSON keys unchanged |
| M-5 | major | The skill's "Upsert APIs" line stays false | **Fixed.** STEP-6 rewrites it; the DoD sweep names it |
| M-6 | minor | `Type.ID` / `Field.ID` an input nobody sets | **Fixed.** D-1: a non-empty ID is `ErrInvalid`; T-1 checks it |
| M-7 | minor | D-4's Rejected column misstated the registry (`None` with an `Entity` does not audit) | **Fixed.** D-4's reason is now "rows ride the transaction, as `CopyType`'s join copy does"; the Out row with the wrong claim went |
| M-8 | minor | Two Spike 16 rows numbered S16-60 | **Fixed.** The seed row is S16-62 in both maps, this plan and S15-19 |
| M-9 | nit | Exported `ActionUpsert` constants only tests use | **Fixed.** D-5: string literals, as `artifactstest.Create` |

### Executability

| ID | Severity | Finding | Answer |
| --- | --- | --- | --- |
| X-1 | major | The sweep pattern used `\|`, which ripgrep reads as a literal pipe: zero hits today | **Fixed.** AC-3.1, § 4, T-8 and STEP-4 use `(sourcetypes|metadatafields)\.Upsert\(` plus the unqualified `\bUpsert\(c, Type\{` in `core/database/sourcetypes` |
| X-2 | major | Temporary wrappers in STEP-1/2 needed names, imports and helpers that came later | **Fixed.** D-7: no wrapper; `Upsert` untouched until STEP-4; `TestUpsertTx` calls `UpsertTx` in `writes.Call` |
| X-3 | major | A suggestion-only difference on a re-run is rolled back silently | **Fixed.** D-11 states it and why (create-only rule); T-4 pins it |
| X-4 | major | `goimports` is not installed | **Fixed.** STEP-4 adds imports by hand, `go build ./...` as the check, and drops the unused `searchindex` imports |
| X-5 | major | The Review link was broken until this log | **Fixed** by this log |
| X-6 | minor | T-6's label, origin and position | **Fixed.** Last case, the test's `user` type, label "Census schedule"; AC-1.3 is origin-free |
| X-7 | minor | `UpsertTx` icon semantics, `data_type` diff placement | **Fixed.** D-10 |
| X-8 | minor | How T-2 sets unknown text | **Fixed.** T-2 uses `metadatafields.Update` in `writes.Call` |
| X-9 | minor | `propertyterms.go`'s "un-audited seed path" comment stays true | **Fixed.** The DoD sweep is scoped to the two packages' lines |
| X-10 | nit | A new project now starts at revision 1 with a NULL user | **Fixed.** § 6 Edges "New state" names the readers checked |

## Round 2 (2026-11-19)

Maintainability: **Fits with changes** (two new blockers). Executability: **Not ready** (three new blockers). Every round-1 answer holds except where a round-2 finding below names it.

| ID | Severity | Finding | Answer |
| --- | --- | --- | --- |
| M2-1 | blocker | `Install` calling `writes.Run` itself breaks `add-catalog-query`'s rule for composing writes, and S16-62 could not copy it for `sourcecredibilitygrades` (which `core/writes` depends on: an import cycle) | **Fixed.** D-4: `Install(tx) ([]rowchange.Change, error)` composes on the caller's transaction; `onboarding.createCatalog` runs it in one `writes.Call`; `evidencegraphstest`, `sourcemetadata_test` and `sourcevocab_test` (helper `install`) wrap it the same way. STEP-5, Scope, Go core, STEP-6's skill text and the map entry updated |
| M2-2 | blocker | This plan kept the stored unknown text in `UpsertTx`, while S15-19 writes the input's; `sqlInsert` lacked the column | **Fixed.** D-2: `UpsertTx` writes `f.UnknownText` on insert and update; `sqlInsert` carries it; AC-1.5 and T-2 rewritten. S15-19 D-8, STEP-1, § 4 and Go core now only fill it in; its T-10 is gone (S15-52's T-2 covers it) |
| X2-1 | blocker | STEP-4 deleted `Upsert` while `Install` still called it | **Fixed.** STEP-4 moves test callers only (its sweep may list only `sourcevocab.go`); STEP-5 rewrites `Install`, then deletes both `Upsert`s and `sqlUpsert`s and runs AC-3.1's sweep |
| X2-2 | blocker | STEP-2 renamed `sqlUpsert` while `Upsert` still used its conflict clause | **Fixed.** D-2 and STEP-2: `sqlInsert` *(new)* beside `sqlUpsert`, which goes in STEP-5 |
| X2-3 | blocker | T-6 inside `writes.Call` would hit the test's own open `BeginWrite` | **Fixed.** T-6 calls `UpsertTx` on the test's `tx`, with the description and icon the earlier cases leave, so the change holds only `label` |
| X2-4 | minor | STEP-5 check missed `sourcecopy`; the moved loop's unused index; `dbtest` helpers; Delete's `icon_key` | **Fixed.** STEP-5 runs the whole suite; D-4 drops the index; T-3 uses `dbtest.Revisions` and `LatestRevision`; D-9 notes `icon_key` is `NOT NULL` |
| X2-5 | minor | Map row text stale (~90 sites, re-run Check) | **Fixed.** The S15-52 row and scope entry: ~140 sites, `EnsureSuggestion` goes, Check names the `UpsertTx` label change and the corrected `rg` |
| (note) | — | `rowFields` vs the precedents' `RowMap` name | **Logged.** The precedents' `RowMap` takes an id and a value type; here the row is the struct, so `rowFields` stays |

## Verdict

**Planned.** No blocker open; nothing To user open. Two rounds done.
