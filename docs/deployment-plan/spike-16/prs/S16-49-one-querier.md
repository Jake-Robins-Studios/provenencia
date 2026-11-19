# S16-49 — One read querier and one write querier for every catalog package

**Status:** Draft
**Spike / slice:** Spike 16 · Slice 6c — Shared list helpers
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: Go types and helpers move; nothing the app draws or does changes)
**Board:** —
**Depends on:** —
**Blocks:** —
**Branch:** `s16-49-one-querier`
**Version bump:** none — no change a researcher can see, no wire and no catalog change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-catalog-query`](../../../../.agents/skills/add-catalog-query/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table-driven tests)
**Context:** working rule "(Batch 6) One read querier and one write querier, in a leaf package"; map scope entry [S16-49](../deployment-plan.md#s16-49--one-read-querier-and-one-write-querier-for-every-catalog-package); bar 24
**Planned:** 2026-11-19 against `main` @ `31d9902`
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

The catalog packages declare the same `database/sql` read surface (`Query`, `QueryRow`) and write surface (plus `Exec`) nineteen times: seven named `Querier` types, one private `querier`, one private `execer`, and ten inline `interface { … }` parameters. Three packages (`sqlbatch`, `graphcache`, `effects`) declare their own because `core/database` imports them, so they cannot import `database.Querier`. This PR puts the two interfaces, the IN-list placeholder builder and the id-args builder in one leaf package that imports nothing from the catalog, aliases them from `core/database`, and deletes every copy. It also moves the two identical trim-then-NULL binders to `database.NullTrimmed`. Nothing the app does changes.

**Why now.** The retired shared-list-helpers idea file named it (2026-11-17), and each new catalog package copies the nearest local `Querier` it finds.

**What stays.** Every function keeps its name, its parameter names, what it reads and writes, and which callers pass a `*sql.Tx`, a `*sql.DB`, a `*database.Tx` or a `*graphcache.Graph`. `database.NullString` keeps not trimming.

## 2. User stories

**US-1.** As a contributor adding a catalog package, I take `database.Querier` or `database.Execer` for the connection, so that I find one read surface and one write surface, not a local copy to imitate.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | `rg -n "[Qq]uerier interface\|q interface \{" core` (bar 24) | One hit: `core/database/dbsql/dbsql.go` *(new)* `type Querier interface` |
| AC-1.2 | `rg -n -B3 "^\s+(Query\|QueryRow\|Exec)\(\w* ?string, (\w+ )?\.\.\.any\)" --type go core \| rg "interface"` | Two hits, both in `core/database/dbsql/dbsql.go` *(new)*: `type Querier interface` and `type Execer interface` |
| AC-1.3 | `go list -deps ./core/database/dbsql \| rg provenencia` | Only `github.com/Jake-Robins-Studios/provenencia/core/database/dbsql` |
| AC-1.4 | `add-catalog-query` SKILL.md | Says a package never declares its own querier, names `database.Querier`, `database.Execer`, and `dbsql` for the three packages `core/database` imports |

**US-2.** As a contributor binding an optional text column, I call one helper for "trim, then NULL when empty".

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | `database.NullTrimmed("  abc ")` | `"abc"` |
| AC-2.2 | `database.NullTrimmed(" \t\n")` and `database.NullTrimmed("")` | `nil` |
| AC-2.3 | `rg "func nullIfEmpty" core` | No hit |

**US-3.** As the engine, every query, write and audit row is the same as before.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `CGO_ENABLED=1 go test -tags fts5 ./api/... ./core/...` | Passes with no test file's assertions changed (only types in test helpers) |
| AC-3.2 | `dbsql.InPlaceholders(0)`, `(1)`, `(3)` | `""`, `"?"`, `"?,?,?"` |

## 3. Scope

| In | Covered by |
| --- | --- |
| Leaf package `core/database/dbsql` with `Querier`, `Execer`, `InPlaceholders`, `BlobArgs` (D-1, D-2, D-6) | STEP-1, AC-1.3, AC-3.2 |
| `database.Querier` and `database.Execer` become aliases; `database.SQLInPlaceholders` and `database.BlobArgs` forward to the leaf (D-3) | STEP-1 |
| `sqlbatch`, `graphcache`, `effects` use `dbsql` directly; `core/database/graphcache/sql.go`'s `placeholders` and `blobArgs` and `sqlbatch`'s inline placeholder build go (D-4, D-6) | STEP-2 |
| `namealiases`, `nameformats`, `conclusionsummaries`, `searchindex` drop their `Querier` (D-5) | STEP-3 |
| `autoreconciler` drops its `Querier`; read functions take `database.Querier`, writes `database.Execer`; `truth.go`'s `rowQuerier` goes (D-7) | STEP-4 |
| Inline interfaces in `datevalues`, `namevalues`, `canonicalentities`, `sources.getOne`, `dbtest.Count`, `autoreconcilertest.dump`; `graphcachetest.execer`; `graphcache.Querier` users outside `graphcache` (D-5, D-8) | STEP-5 |
| `core/search/fts.go` builds its IN list with `database.SQLInPlaceholders` (map "Also") | STEP-5 |
| `database.NullTrimmed` replaces `datevalues` and `audit` `nullIfEmpty` (D-9) | STEP-6, AC-2.* |
| `add-catalog-query` names the two queriers, forbids a local one, names `NullTrimmed` beside `NullString` (D-10) | STEP-7, AC-1.4 |

| Out | Home |
| --- | --- |
| Trimming in the other `NullString` callers (changes what is saved) | not planned (map scope entry) |
| `rowScanner` interfaces in eleven packages (`Scan` only; a scan helper, not a querier) | not planned (map scope entry) |
| Context-taking methods (`QueryContext`, `ExecContext`) on the shared interfaces | not planned (map scope entry) |
| Changing which functions take `*sql.Tx`, `*sql.DB` or `*database.Tx` | not planned (map scope entry) |
| Narrowing write-typed parameters to `Querier` outside `autoreconciler` (`searchindex` keeps `Execer` on every function its `Querier` typed) | not planned: D-5 |
| `core/database/graphcache/sql.go` `uniqueIDs` (a near-copy of `database.UniqueBlobIDs` that does not copy the ids) | not planned (user, 2026-11-19) |
| Batching `core/search/fts.go`'s unbounded IN list through `sqlbatch` | not planned: it is on `QueryContext`, which `sqlbatch` does not take; a change of query count, not a cleanup |
| `ScaleSeed.Exec` (`evidencegraphstest`), `observationrow.Scanner`, `observations.StagedFile` | not planned: not a `database/sql` surface |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Shared read surface | `core/database/tx.go` `Querier` | `interface { Query; QueryRow }`, with the doc comment on reads inside `writes.Run`. 11 uses of `database.Querier` |
| Placeholders / args | `core/database/sqlin.go` `SQLInPlaceholders`, `BlobArgs` | `strings.Repeat("?,", n-1) + "?"`, `""` for `n <= 0`; `BlobArgs` copies ids into `[]any`. No test |
| Null binders | `core/database/null.go` `NullBlob`, `NullString`, `NullInt64`, `NullBool`; `null_test.go` table tests | No trimming binder |
| Import graph | `go list -deps ./core/database` | `core/database` imports `effects`, `graphcache`, `sqlbatch` (via `graphcache`), `catalogmodel`, `rowchange`, `scalarcols`, `apperr`, `ref`, and pure `core/*` packages. It does not import `audit` |
| `sqlbatch` | `core/database/sqlbatch/sqlbatch.go` `Querier` (Query only), `Query`, `Scan` | Own `Querier`; line 46 builds `strings.Repeat("?,", len(batch)-1)+"?"` (batch is never empty: `Each` skips empty) |
| `graphcache` | `core/database/graphcache/graph.go` `Querier` (Query, QueryRow); `verify.go` `TruthFunc`; `sql.go` `placeholders`, `blobArgs`, `uniqueIDs`; `load.go` four IN reads | Own `Querier`; `placeholders`/`blobArgs` are copies of `database.SQLInPlaceholders`/`BlobArgs` |
| `graphcache.Querier` users | `core/database/graphfill/load.go` (`graphcache.Querier(g)` line 64, five loaders); `core/database/sources/records.go` `loadRecords`; `core/database/autoreconciler/truth.go` `rowQuerier`, `truthRows`; `core/database/conclusionsummaries/conclusionsummariestest/inputs.go` `type Querier = graphcache.Querier`; `core/database/searchindex/export_test.go` `SetNewGraphForTest`, `inputs_test.go` (two) | 13 references |
| `effects` | `core/database/effects/path.go` `querier` (Query, QueryRow), `walk.q`, `queryIDs`; `path_test.go` `countingQuerier` embeds `querier`; `export_test.go` `SourceScopeOfChange(q querier, …)` | Private copy |
| `namealiases` | `namealiases.go` `Querier` | Read copy, 3 uses in package |
| `nameformats` | `nameformats.go` `Querier` | Read copy, 4 uses |
| `conclusionsummaries` | `conclusionsummaries.go` `Querier` | Read copy, 9 uses |
| `searchindex` | `searchindex.go` `Querier` (Exec, Query, QueryRow) | Write copy, 28 uses, among them `ReprojectChanged` |
| `autoreconciler` | `autoreconciler.go` `Querier` (Exec, Query, QueryRow) on `RecomputeReported`, `recompute`, `HandlesForSubjects`, `HandlesForSource`, `HandlesForCitation`, `HandlesForProperty`, `Rebuild`, `StoredVersion`, `NeedsRebuild`, `recomputeBatch`, `load`, `acceptedEntities`, `insertRow`, `listIDs`; `truth.go` `rowQuerier` (adapts the graph's read surface with a no-op `Exec` so `truthRows` can call `load`); `export_test.go` `countingQuerier` embeds `Querier`, `LoadQueryCount(q Querier, …)`; `autoreconciler_test.go` four helpers take `autoreconciler.Querier` | Write copy; the read functions demand `Exec` they never call |
| `datevalues` | `datevalues.go` `InsertTx`, `insert` (Exec-only inline), `LookupManyTx` (Query-only), `LookupTx` (QueryRow-only); `nullIfEmpty` (10 calls) | Inline copies; private trim binder |
| `namevalues` | `namevalues.go` `LookupTx` (QueryRow+Query inline, param `q`), `LookupManyTx` (Query-only inline, param `db`) | Inline copies |
| `canonicalentities` | `canonicalentities.go` `GetManyTx` (Query-only inline) | Inline copy |
| `sources` | `sources.go` `getOne` (QueryRow-only inline) | Inline copy; matched by bar 24 |
| `audit` | `audit.go` `nullIfEmpty` (2 calls in `Record`'s insert) | Private trim binder; imports `effects`, `rowchange`, `apperr`, not `core/database` |
| `core/search` | `fts.go` line 292 `marks := strings.TrimSuffix(strings.Repeat("?, ", len(ids)), ", ")`, guarded by `len(ids) == 0` return above | Hand-built IN list; already imports `core/database` |
| Test helpers | `core/database/dbtest/dbtest.go` `Count` (QueryRow-only inline; imports only `rowchange` today); `core/database/autoreconciler/autoreconcilertest/autoreconcilertest.go` `dump` (Query-only inline); `core/database/graphcache/graphcachetest/graphcachetest.go` `execer` (Exec-only) used by `member` with `k.db` and a `*sql.Tx` | Copies; `Count` and `dump` are matched by bar 24 |
| Skill | `.agents/skills/add-catalog-query/SKILL.md` "Reads inside a write" | Names `database.Querier`; no rule against a local copy; no `NullString` line |

**Precedent.** `core/database/sqlbatch` is the existing leaf: its package doc says "It imports nothing from the catalog, so the graph cache, which the database package depends on, can use it too." Copy that doc sentence's shape for `dbsql`. `database.Querier` itself (S12-01) is the shape the aliases keep.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | The leaf package is `core/database/dbsql` *(new)*, file `dbsql.go`, test `dbsql_test.go`. It imports only `database/sql` and `strings` from the standard library | Names what it holds (the `database/sql` surface the catalog packages share) without stuttering (`querier.Querier`) | `core/database/querier` — stutters and would also hold placeholders; putting the types in `sqlbatch` — a batching package is the wrong home for the connection surface |
| D-2 | `dbsql.Querier` = `Query(query string, args ...any) (*sql.Rows, error)` + `QueryRow(query string, args ...any) *sql.Row`. `dbsql.Execer` = `Querier` embedded + `Exec(query string, args ...any) (sql.Result, error)`. Compile-time assertions in `dbsql.go`: `var _ Execer = (*sql.DB)(nil)` and `var _ Execer = (*sql.Tx)(nil)` | Same method sets as today's copies, so every caller still compiles. `Execer` is the map's name | `Writer` / `ReadWriter` — the map's working rule names `Execer` |
| D-3 | In `core/database/tx.go`, the `Querier` interface becomes `type Querier = dbsql.Querier` (keeping today's doc comment) and `type Execer = dbsql.Execer` *(new)* follows with one line: "Execer is Querier plus Exec: a write's surface". In `sqlin.go`, `SQLInPlaceholders` and `BlobArgs` keep their names and doc comments and become one-line forwarders to `dbsql.InPlaceholders` and `dbsql.BlobArgs` | Callers outside the three leaf users keep `database.*`; no call site moves | Moving all callers to `dbsql` — 5 + 4 call sites churn, and two names for one thing across packages |
| D-4 | Only `sqlbatch`, `graphcache` and `effects` import `dbsql`. Every other package, test and helper uses `database.Querier` / `database.Execer` | `core/database` imports those three; everyone else can import `core/database` | Everyone on `dbsql` — the skill teaches `database.Querier`, and `dbsql` would become a second spelling |
| D-5 | Each local type is replaced by the shared type with the same method set: a read copy (Query, QueryRow, or a subset) → `Querier`; a copy with `Exec` → `Execer`. Subsets widen to `Querier` (`sqlbatch.Querier`, `datevalues.LookupManyTx`/`LookupTx`, `namevalues.LookupManyTx`, `canonicalentities.GetManyTx`, `sources.getOne`, `dbtest.Count`, `autoreconcilertest.dump`); Exec-only inline types (`datevalues.InsertTx`, `insert`, `graphcachetest.execer`) become `Execer`. No parameter is narrowed except in `autoreconciler` (D-7). Parameter names stay (`namevalues.LookupManyTx` keeps `db`) | Working rule: "a package needing less than the full read surface still takes `database.Querier`". Every caller today passes `*sql.DB`, `*sql.Tx`, `*database.Tx` or `*graphcache.Graph` (verified: the only other types with these methods are test wrappers that embed a full querier) | Narrowing each function to what it calls — a larger diff with no code deleted |
| D-6 | `dbsql.InPlaceholders(n int) string` and `dbsql.BlobArgs(ids [][]byte) []any` *(new)* take `database.SQLInPlaceholders`'s and `BlobArgs`'s bodies verbatim. `core/database/graphcache/sql.go` `placeholders` and `blobArgs` are deleted and `load.go`'s eight calls use `dbsql.InPlaceholders` / `dbsql.BlobArgs`. `sqlbatch.go` line 46 uses `dbsql.InPlaceholders(len(batch))` | Map "Also" for placeholders; `blobArgs` added by the user (2026-11-19); `sqlbatch`'s inline build is a third copy of the same body | Keeping the `sqlbatch` inline build — it is the copy bar 24's spirit names |
| D-7 | In `autoreconciler`, functions that only read take `database.Querier`: `HandlesForSubjects`, `HandlesForSource`, `HandlesForCitation`, `HandlesForProperty`, `StoredVersion`, `NeedsRebuild`, `load`, `acceptedEntities`, `listIDs`. Functions that write take `database.Execer`: `RecomputeReported`, `recompute`, `Rebuild`, `recomputeBatch`, `insertRow`. `truth.go` `rowQuerier` is deleted and `truthRows` calls `load(q, chunk)` with its `database.Querier`. `export_test.go` `countingQuerier` embeds `database.Querier` and `LoadQueryCount` takes `database.Querier`; the four `autoreconciler_test.go` helpers take `database.Querier` | Narrowing here deletes code: `rowQuerier` and its no-op `Exec` exist only because `load` demanded `Exec` | Keeping every function on `Execer` — keeps a fake `Exec` that returns `sql.ErrNoRows` |
| D-8 | `graphcache.Querier` users outside `graphcache`: `core/database/graphfill/load.go` (`database.Querier(g)` and the five loaders), `core/database/sources/records.go`, `core/database/autoreconciler/truth.go`, `core/database/searchindex/export_test.go`, `core/database/searchindex/inputs_test.go` take `database.Querier`. `core/database/conclusionsummaries/conclusionsummariestest/inputs.go`'s `type Querier = graphcache.Querier` line and its doc comment are deleted and its functions take `database.Querier`. `graphcache.TruthFunc` and `graphcache` internals take `dbsql.Querier` | One name per layer (D-4); the alias in `conclusionsummariestest` is a third name for the same type | Keeping `graphcache.Querier` as an alias — a second exported spelling |
| D-9 | `func NullTrimmed(s string) any` *(new)* in `core/database/null.go`, after `NullString`: `strings.TrimSpace`, then `nil` when empty, else the trimmed string. Doc: "NullTrimmed trims s and binds an empty result as SQL NULL. NullString does not trim." `datevalues` and `audit` delete `nullIfEmpty` and call it; `audit` imports `core/database` (no cycle: `core/database` does not import `audit`) | Working rule; identical bodies today | In `dbsql` — it is a binder beside the other `Null*`, and neither caller is a leaf |
| D-10 | `add-catalog-query` gains, in "Reads inside a write": "A package never declares its own querier interface, named or inline: a read takes `database.Querier`, a write `database.Execer`, even when it calls one method. `sqlbatch`, `graphcache` and `effects`, which `core/database` imports, take `dbsql.Querier` / `dbsql.Execer`, the types those alias." And under Functions: "Bind an optional value with `database.NullBlob`, `NullString`, `NullInt64`, `NullBool`; `NullTrimmed` when the text is trimmed first." | Bar 24 says the skill refuses a new copy | A new `.cursor/rules` line — the skill is where catalog query guidance lives |
| D-11 | `core/search/fts.go` builds `marks` with `database.SQLInPlaceholders(len(ids))`; the `strings` import stays only if another use remains | Map "Also"; `"?,?"` and `"?, ?"` are the same SQL | — |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `core/database/dbsql` *(new)* | package | `core/database/sqlbatch` (leaf) | `sqlbatch` is about batching by-id reads; the connection surface is not batching (D-1) |
| `dbsql.Querier` *(new)* | type | `database.Querier` | Moves it: `core/database` cannot be imported by `graphcache`/`effects`/`sqlbatch` |
| `dbsql.Execer`, `database.Execer` *(new)* | type | `autoreconciler.Querier`, `searchindex.Querier` | They become this one |
| `dbsql.InPlaceholders` *(new)* | func | `database.SQLInPlaceholders` | Moves its body; the old name forwards |
| `dbsql.BlobArgs` *(new)* | func | `database.BlobArgs` | Moves its body; the old name forwards |
| `database.NullTrimmed` *(new)* | func | `database.NullString` | `NullString` must keep not trimming (working rule) |
| `TestInPlaceholders`, `TestBlobArgs` *(new)* | test | none for `SQLInPlaceholders`/`BlobArgs` | First tests of the moved bodies |
| `TestNullTrimmed` *(new)* | test | `TestNullBlob` in `null_test.go` | Copies its table shape |

Searched: `rg "interface \{" core --type go`, the method-signature regex in AC-1.2, `rg "strings.Repeat\(\"\?"`, `rg "func nullIfEmpty"`, `rg "func blobArgs|func placeholders"`.

**Builds on.** `sqlbatch`'s leaf pattern; `database.Querier` (S12-01); `null.go`'s binders.
**Deletes.** `sqlbatch.Querier`; `graphcache.Querier`; `graphcache` `placeholders`, `blobArgs`; `effects` `querier`; `namealiases.Querier`; `nameformats.Querier`; `conclusionsummaries.Querier`; `searchindex.Querier`; `autoreconciler.Querier`; `autoreconciler` `rowQuerier`; `conclusionsummariestest.Querier`; `graphcachetest` `execer`; `datevalues` and `audit` `nullIfEmpty`; ten inline interface parameters; `sqlbatch`'s inline placeholder build; `fts.go`'s hand-built marks.
**Next adds.** A new catalog package takes `database.Querier` with nothing to copy; S16-62's seed writes, which take a `*database.Tx`, can hand helpers `database.Execer`.

### Reach

None — no new path into existing code, no new state reachable.

### Scale

None — no write, list or loop changes; every query text is the same except `fts.go`'s IN-list whitespace.

### Edges

- **Assumptions.** Interface method sets: every value passed today has `Query`, `QueryRow` and, where an `Execer` is now asked, `Exec` (`*sql.DB`, `*sql.Tx`, `*database.Tx` embeds `*sql.Tx`; `*graphcache.Graph` has `Query`/`QueryRow` and is only passed to read functions; `effects` and `autoreconciler` test wrappers embed a full querier). `go build ./...` and `go vet` hold this.
- **Neighbors.** `InPlaceholders(n)` for `n <= 0` → `""` (as today); `sqlbatch` only calls it with `n >= 1`; `fts.go` only with `len(ids) > 0`. `NullTrimmed` on text with inner spaces (`" a b "`) → `"a b"`. T-1, T-2 pin these.
- **Removed inputs.** None — nothing is decided, excluded or deleted.
- **Real data.** None — no table, seed or configuration drives a rule here.
- **Untrusted size.** None — no new list or loop.

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/dbsql` *(new)* | `type Querier interface`, `type Execer interface`, `func InPlaceholders(n int) string`, `func BlobArgs(ids [][]byte) []any`, two `var _ Execer` assertions (D-1, D-2, D-6). Package doc: what it holds, and "It imports nothing from the catalog, so `sqlbatch`, `graphcache` and `effects`, which `core/database` imports, can use it." |
| `core/database` | `tx.go` aliases (D-3); `sqlin.go` forwarders (D-3); `null.go` `NullTrimmed` (D-9) |
| `sqlbatch`, `graphcache`, `effects` | `dbsql` types and helpers (D-4, D-6) |
| `namealiases`, `nameformats`, `conclusionsummaries`, `searchindex`, `autoreconciler`, `datevalues`, `namevalues`, `canonicalentities`, `sources`, `graphfill`, `audit`, `dbtest`, `autoreconcilertest`, `graphcachetest`, `conclusionsummariestest` | `database.Querier` / `database.Execer` / `database.NullTrimmed` (D-5, D-7, D-8, D-9) |
| `core/search` | `fts.go` marks (D-11) |

```go
// Package dbsql …
package dbsql

type Querier interface {
	Query(query string, args ...any) (*sql.Rows, error)
	QueryRow(query string, args ...any) *sql.Row
}

type Execer interface {
	Querier
	Exec(query string, args ...any) (sql.Result, error)
}
```

Errors: none new.

### FFI

None — no wire change.

### macOS

None — no Swift change.

### Strings

None — no user-facing copy.

## 7. Steps

**STEP-1 — The leaf package and the aliases**
Files: `core/database/dbsql/dbsql.go` *(new)*, `core/database/dbsql/dbsql_test.go` *(new)*, `core/database/tx.go`, `core/database/sqlin.go`.
Do: D-1, D-2, D-3, D-6 (the two functions). T-2, T-3.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/dbsql ./core/database` passes; `go list -deps ./core/database/dbsql | rg provenencia` prints only `dbsql` (AC-1.3); `go build ./...` passes.

**STEP-2 — The three packages `core/database` imports**
Files: `core/database/sqlbatch/sqlbatch.go`; `core/database/graphcache/graph.go`, `verify.go`, `sql.go`, `load.go` and every other `graphcache` file naming `Querier`; `core/database/effects/path.go`, `path_test.go`, `export_test.go`.
Do: delete `sqlbatch.Querier`, `graphcache.Querier`, `effects.querier`, `graphcache` `placeholders` and `blobArgs`; use `dbsql.Querier`, `dbsql.InPlaceholders`, `dbsql.BlobArgs` (D-4, D-6). In `path_test.go`, `countingQuerier` embeds `dbsql.Querier` and calls `c.Querier.QueryRow`. Fix every `graphcache.Querier` reference outside `graphcache` in this step with D-8 so the tree builds: `core/database/graphfill/load.go`, `core/database/sources/records.go`, `core/database/autoreconciler/truth.go` (`truthRows` and `rowQuerier`'s field type only; `rowQuerier` goes in STEP-4), `core/database/conclusionsummaries/conclusionsummariestest/inputs.go`, `core/database/searchindex/export_test.go`, `core/database/searchindex/inputs_test.go`.
Check: `rg -n "graphcache\.Querier|sqlbatch\.Querier|func placeholders|func blobArgs" --type go .` prints nothing; `CGO_ENABLED=1 go test -tags fts5 ./core/database/...` passes.

**STEP-3 — The named read and write copies**
Files: `core/database/namealiases/namealiases.go`, `core/database/nameformats/nameformats.go`, `conclusionsummaries/*.go`, `searchindex/*.go`.
Do: delete each package's `Querier`; read copies use `database.Querier`, `searchindex` uses `database.Execer` on every function its `Querier` typed (D-5).
Check: `rg -n "type Querier" core --type go` prints only `core/database/dbsql/dbsql.go` *(new)* and `core/database/tx.go` (the alias) and `autoreconciler.go`; tests pass as in STEP-2.

**STEP-4 — `autoreconciler`**
Files: `core/database/autoreconciler/autoreconciler.go`, `truth.go`, `export_test.go`, `autoreconciler_test.go`.
Do: D-7. Delete `Querier` and `rowQuerier`.
Check: `rg -n "rowQuerier|autoreconciler\.Querier" --type go .` prints nothing; `CGO_ENABLED=1 go test -tags fts5 ./core/database/autoreconciler/... ./core/writes/...` passes.

**STEP-5 — Inline interfaces and the last IN list**
Files: `core/database/datevalues/datevalues.go`, `core/database/namevalues/namevalues.go`, `core/database/canonicalentities/canonicalentities.go`, `core/database/sources/sources.go`, `core/database/dbtest/dbtest.go`, `core/database/autoreconciler/autoreconcilertest/autoreconcilertest.go`, `core/database/graphcache/graphcachetest/graphcachetest.go`, `core/search/fts.go`.
Do: D-5 for each inline parameter and `execer`; D-11.
Check: AC-1.1 and AC-1.2 commands print exactly what they say; `CGO_ENABLED=1 go test -tags fts5 ./core/...` passes.

**STEP-6 — `NullTrimmed`**
Files: `core/database/null.go`, `null_test.go`, `core/database/datevalues/datevalues.go`, `core/database/audit/audit.go`.
Do: D-9; T-1.
Check: `rg "func nullIfEmpty|nullIfEmpty\(" core` prints nothing; `CGO_ENABLED=1 go test -tags fts5 ./core/database/... ./core/writes/...` passes.

**STEP-7 — Skill and gate**
Files: `.agents/skills/add-catalog-query/SKILL.md`.
Do: D-10.
Check: `python3 scripts/check-guidance-names.py` passes; `scripts/check-pr.sh` prints `check-pr: PASS` (on a non-macOS runner, every check but `xcode-test` and `swift-warnings` passes; report that).

**STEP-8 — Docs**
Files: `docs/deployment-plan/spike-16/completed.md`, `deployment-plan.md` (map row), this plan (status, Landed note).
Do: per the Definition of done.
Check: links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed, ending in a period, like the rest of `git log` ("Define the catalog's read and write queriers once, in a leaf package."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/null_test.go` `TestNullTrimmed` *(new)*, table | `""` → nil; `" \t\n"` → nil; `"abc"` → `"abc"`; `"  abc "` → `"abc"`; `" a b "` → `"a b"` | AC-2.1, AC-2.2, D-9 |
| T-2 | Go | `core/database/dbsql/dbsql_test.go` `TestInPlaceholders` *(new)*, table | -1 → `""`; 0 → `""`; 1 → `"?"`; 3 → `"?,?,?"` | AC-3.2, D-6 |
| T-3 | Go | `core/database/dbsql/dbsql_test.go` `TestBlobArgs` *(new)*, table | nil → empty slice of length 0; two 16-byte ids → `[]any` of length 2 whose elements are those ids in order | D-6 |
| T-4 | Go | existing suites, unchanged assertions | `CGO_ENABLED=1 go test -tags fts5 ./api/... ./core/...` passes | AC-3.1 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `core/database/autoreconciler` (D-7), `core/database/graphcache` and `graphfill` (D-8), `core/database/effects` (`countingQuerier`).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or the command and its output for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left — none in this PR
- [ ] Sweep: each deleted name `rg`'d by its old, qualified name (`sqlbatch.Querier`, `graphcache.Querier`, `searchindex.Querier`, `autoreconciler.Querier`, `nameformats.Querier`, `namealiases.Querier`, `conclusionsummaries.Querier`, `rowQuerier`, `nullIfEmpty`) across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated — none
- [ ] UI matches the brief inventory — no UI
- [ ] Version bump as the header says — none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated) — not gated
- [ ] Domain doc updated if a rule in docs/*.md changed — none changes
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

None in the app: nothing it draws or does changes. The reviewer runs the AC-1.1, AC-1.2, AC-1.3 and AC-2.3 commands and sees the outputs §2 names, and reads `.agents/skills/add-catalog-query/SKILL.md` for D-10's two sentences (AC-1.4).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| An import cycle from `audit` → `core/database` | Verified: `go list -deps ./core/database` has no `audit`. STEP-6 builds it |
| A caller passes a type with fewer methods than the widened parameter asks | Verified at the base (D-5); `go build ./...` in each step catches one |
| `effects` test wrapper's embedded field renames (`querier` → `Querier`) | STEP-2 names it |

**Stop and report if:**

- `go build ./...` fails because a caller passes a value without `QueryRow` or `Exec` to a widened parameter (D-5): name the caller and the type.
- `dbsql` would need to import any `github.com/Jake-Robins-Studios/provenencia/...` package.
- `audit` cannot import `core/database` without a cycle.
- An `autoreconciler` function listed in D-7 as read-only calls `Exec`, directly or through a callee.
- A test assertion (not a helper's parameter type) has to change for the suite to pass.

## 12. Open questions

None.

## 13. PR

**Title:** S16-49 — One read querier and one write querier for every catalog package
**Body:** objective in one sentence; the copies deleted (§6 Deletes); AC evidence (the four `rg`/`go list` outputs, the test run); deviations from the plan; `Plan: docs/deployment-plan/spike-16/prs/S16-49-one-querier.md`.
