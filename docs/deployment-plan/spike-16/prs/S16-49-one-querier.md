# S16-49 — One read querier and one write querier for every catalog package

**Status:** Landed in [#903](https://github.com/Jake-Robins-Studios/provenencia/pull/903) (2026-11-19)
**Spike / slice:** Spike 16 · Slice 6c — Shared list helpers
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: Go types and helpers move; nothing the app draws or does changes)
**Board:** —
**Depends on:** —
**Blocks:** — (S16-63 is independent: it replaces a query this PR leaves alone)
**Branch:** `s16-49-one-querier`
**Version bump:** none — no change a researcher can see, no wire and no catalog change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-catalog-query`](../../../../.agents/skills/add-catalog-query/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table-driven tests)
**Context:** working rule "(Batch 6) One read querier and one write querier, in a leaf package"; map scope entry [S16-49](../deployment-plan.md#s16-49--one-read-querier-and-one-write-querier-for-every-catalog-package); bar 24
**Planned:** 2026-11-19 against `main` @ `31d9902`
**Landed:** Differences from the plan: `sources.fillDates` also carried an inline Query-only interface that C-2 matches, so it takes `database.Querier` with the others (D-5). `main` had moved from the Planned commit without changing a Current state row. Otherwise none.
**Review:** [`S16-49-one-querier.review.md`](S16-49-one-querier.review.md) — Fits with changes — Ready with changes, 2 rounds; no blocker open; To user answered (2026-11-19)

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

The catalog packages declare the same `database/sql` surfaces over and over. The read surface (`Query`, `QueryRow`) and write surface (plus `Exec`) appear nineteen times: seven named `Querier` types, one private `querier`, one private `execer`, and ten inline `interface { … }` parameters. The row surface (`Scan(dest ...any) error`, shared by `*sql.Row` and `*sql.Rows`) appears nineteen times: fourteen `rowScanner` types, `observationrow.Scanner`, and four inline parameters. Three packages (`sqlbatch`, `graphcache`, `effects`) declare their own because `core/database` imports them, so they cannot import `database.Querier`. This PR puts the three interfaces, the IN-list placeholder builder and the id-args builder in one leaf package that imports nothing from the catalog, aliases them from `core/database`, deletes every copy, and adds a test that refuses a new one. It also moves the private trim-then-NULL and `*int` binders to `database.NullTrimmed` and `database.NullInt`. Nothing the app does changes.

**Why now.** The retired shared-list-helpers idea file named it (2026-11-17), and each new catalog package copies the nearest local `Querier` or `rowScanner` it finds. The `Scan` copies were added on review (user, 2026-11-19).

**What stays.** Every function keeps its name, its parameter names, what it reads and writes, and which callers pass a `*sql.Tx`, a `*sql.DB`, a `*database.Tx` or a `*graphcache.Graph`. `database.NullString` keeps not trimming.

## 2. User stories

**US-1.** As a contributor adding a catalog package, I take `database.Querier`, `database.Execer` or `database.Scanner`, so that I find one surface of each kind, not a local copy to imitate, and a copy I add fails `go test`.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Command C-1 below (bar 24) | One line: `core/database/dbsql/dbsql.go` *(new)* `type Querier interface` |
| AC-1.2 | Command C-2 below | Two lines, both in `core/database/dbsql/dbsql.go` *(new)*: `type Querier interface` and `type Execer interface` |
| AC-1.3 | Command C-4 below, and T-7 | Only `github.com/Jake-Robins-Studios/provenencia/core/database/dbsql` |
| AC-1.4 | `add-catalog-query` SKILL.md | Says a package never declares its own querier or scanner; names `database.Querier`, `database.Execer`, `database.Scanner`, and `dbsql` for the four packages that cannot import `core/database` |
| AC-1.5 | Command C-3 below | One line: `core/database/dbsql/dbsql.go` *(new)* `type Scanner interface` |
| AC-1.6 | A new file under `core/` declares `type q interface { QueryRow(string, ...any) *sql.Row }` (or an inline `interface{ Scan(dest ...any) error }` parameter) | T-6 fails and names the file and line |

The commands, written outside the table so the pipes are literal regex alternation:

```bash
# C-1 (bar 24): expect one line
rg -n "[Qq]uerier interface|q interface \{" core
```

```bash
# C-2: expect two lines, both in core/database/dbsql/dbsql.go
rg -n -B3 "^\s+(Query|QueryRow|Exec)\(\w* ?string, (\w+ )?\.\.\.any\)" --type go core | rg "interface"
```

```bash
# C-3: expect one line, in core/database/dbsql/dbsql.go
rg -n -B1 "^\s+Scan\(\w* ?\.\.\.any\) error|interface\{ ?Scan\(" --type go core api | rg "interface"
```

```bash
# C-4: expect only github.com/Jake-Robins-Studios/provenencia/core/database/dbsql
go list -deps ./core/database/dbsql | rg provenencia
```

```bash
# C-5: expect no line
rg "func nullIfEmpty|func nullInt\b" core
```

**US-2.** As a contributor binding an optional column, I call one helper per shape.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | `database.NullTrimmed("  abc ")` | `"abc"` |
| AC-2.2 | `database.NullTrimmed(" \t\n")` and `database.NullTrimmed("")` | `nil` |
| AC-2.3 | Command C-5 below | No hit |
| AC-2.4 | `database.NullInt(nil)`, `NullInt(&0)`, `NullInt(&1890)` | `nil`, `0`, `1890` (as `int`) |

**US-3.** As the engine, every query, write and audit row is the same as before.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `CGO_ENABLED=1 go test -tags fts5 ./api/... ./core/...` | Passes with no test file's assertions changed (only types in test helpers, and D-14's query counter) |
| AC-3.2 | `dbsql.SQLInPlaceholders(0)`, `(1)`, `(3)` | `""`, `"?"`, `"?,?,?"` |

## 3. Scope

| In | Covered by |
| --- | --- |
| Leaf package `core/database/dbsql` with `Querier`, `Execer`, `Scanner`, `SQLInPlaceholders`, `BlobArgs` (D-1, D-2, D-6) | STEP-1, AC-1.3, AC-3.2 |
| `database.Querier`, `database.Execer`, `database.Scanner` are aliases; `database.SQLInPlaceholders` and `database.BlobArgs` forward to the leaf (D-3) | STEP-1 |
| `sqlbatch`, `graphcache`, `effects` use `dbsql` directly; `core/database/graphcache/sql.go`'s `placeholders` and `blobArgs` and `sqlbatch`'s inline placeholder build go (D-4, D-6) | STEP-2 |
| `namealiases`, `nameformats`, `conclusionsummaries`, `searchindex` drop their `Querier`; `searchindex`'s nine read functions take `database.Querier` (D-5) | STEP-3 |
| `autoreconciler` drops its `Querier`, `rowQuerier` and test `countingQuerier` (D-7, D-14) | STEP-4 |
| Inline querier interfaces in `datevalues`, `namevalues`, `canonicalentities`, `sources.getOne`, `autoreconcilertest.dump` (`dbtest.Count` is STEP-2); `graphcachetest.execer`; `core/search/fts.go`'s IN list (D-5, D-11) | STEP-5 |
| The nineteen `Scan` copies become `database.Scanner` (D-12) | STEP-6, AC-1.5 |
| `database.NullTrimmed` and `database.NullInt` replace `nullIfEmpty` (`datevalues`, `audit`) and `nullInt` (`datevalues`) (D-9, D-13) | STEP-7, AC-2.* |
| Guard test refuses a local querier or scanner, and an import into `dbsql` (D-15) | STEP-8, AC-1.6, AC-1.3 |
| `add-catalog-query` names the surfaces, forbids a local one, names the IN-list exceptions and the binders (D-10) | STEP-8, AC-1.4 |

| Out | Home |
| --- | --- |
| Trimming in the other `NullString` callers (changes what is saved) | not planned (map scope entry) |
| Context-taking methods (`QueryContext`, `ExecContext`) on the shared interfaces | not planned (map scope entry) |
| Changing which functions take `*sql.Tx`, `*sql.DB` or `*database.Tx` | not planned (map scope entry) |
| `core/database/graphcache/sql.go` `uniqueIDs` (a near-copy of `database.UniqueBlobIDs` that does not copy the ids) | not planned (user, 2026-11-19) |
| The scan-side `sql.NullInt64 → *int` pair (`datevalues.intPtr`, `observations.nullIntPtr`) | not planned: a decoder, not a binder; two copies |
| `deleteimpact.handleGoesWithout`'s unbounded `NOT IN` over every Subject leaving a handle | S16-63 (user, 2026-11-19: fix it) |
| Batching `core/search/fts.go`'s IN list through `sqlbatch` | not planned: one page of hits on `QueryContext`, which `sqlbatch` does not take (bounded by the page, D-16) |
| `ScaleSeed.Exec` (`evidencegraphstest`), `observations.StagedFile` | not planned: not a `database/sql` surface |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Shared read surface | `core/database/tx.go` `Querier` | `interface { Query; QueryRow }`, with the doc comment on reads inside `writes.Run`; used across the catalog packages |
| Placeholders / args | `core/database/sqlin.go` `SQLInPlaceholders`, `BlobArgs` | `strings.Repeat("?,", n-1) + "?"`, `""` for `n <= 0`; `BlobArgs` copies ids into `[]any`. No test |
| Null binders | `core/database/null.go` `NullBlob`, `NullString`, `NullInt64`, `NullBool`; `null_test.go` table tests | No trimming binder, no `*int` binder |
| Import graph | `go list -deps ./core/database` | `core/database` imports `effects`, `graphcache`, `sqlbatch` (via `graphcache`), `catalogmodel`, `rowchange`, `scalarcols`, `apperr`, `ref`, and pure `core/*` packages. It does not import `audit` or `observationrow` |
| `sqlbatch` | `core/database/sqlbatch/sqlbatch.go` `Querier` (Query only), `Query`, `Scan` | Own `Querier`; line 46 builds `strings.Repeat("?,", len(batch)-1)+"?"` (batch is never empty: `Each` skips empty) |
| `graphcache` | `core/database/graphcache/graph.go` `Querier` (Query, QueryRow), `Over`, `SetQueryCounterForTest`; `verify.go` `TruthFunc`; `sql.go` `placeholders`, `blobArgs`, `uniqueIDs`; `load.go` four IN reads, each over one `sqlbatch.Each` chunk from `loadIDs`, and over every loaded node from test-only `verifyIDs` | Own `Querier`; `placeholders`/`blobArgs` are copies of `database.SQLInPlaceholders`/`BlobArgs` |
| `graphcache.Querier` users | `core/database/graphfill/load.go` (`graphcache.Querier(g)` line 64, five loaders); `core/database/sources/records.go` `loadRecords`; `core/database/autoreconciler/truth.go` `rowQuerier`, `truthRows`; `core/database/conclusionsummaries/conclusionsummariestest/inputs.go` `type Querier = graphcache.Querier`; `core/database/searchindex/export_test.go` `SetNewGraphForTest`, `core/database/searchindex/inputs_test.go` (two) | 13 references |
| `effects` | `core/database/effects/path.go` `querier` (Query, QueryRow), `walk.q`, `queryIDs`; `path_test.go` `countingQuerier` embeds `querier`, literal at line 42; `export_test.go` `SourceScopeOfChange(q querier, …)` | Private copy |
| `namealiases` | `core/database/namealiases/namealiases.go` `Querier` | Read copy, used in the package |
| `nameformats` | `core/database/nameformats/nameformats.go` `Querier` | Read copy, used in the package |
| `conclusionsummaries` | `core/database/conclusionsummaries/conclusionsummaries.go` `Querier` | Declared and never used: deleted, nothing to retype |
| `searchindex` | `core/database/searchindex/searchindex.go` `Querier` (Exec, Query, QueryRow) | Write copy on every function. Nine call no `Exec`, directly or through a callee: `ProjectionVersionStored`, `NeedsRebuild`, `SourceIDsForFile`, `listIDs`, `existingSourceCoverThumb` (`searchindex.go`), `loadHandleValues` (`handles.go`), `dependentsOf`, `dependentsOfHandles`, `oldEnds` (`inputs.go`) |
| `autoreconciler` | `core/database/autoreconciler/autoreconciler.go` `Querier` (Exec, Query, QueryRow) on `RecomputeReported`, `recompute`, `HandlesForSubjects`, `HandlesForSource`, `HandlesForCitation`, `HandlesForProperty`, `Rebuild`, `StoredVersion`, `NeedsRebuild`, `recomputeBatch`, `load`, `acceptedEntities`, `insertRow`, `listIDs`; `truth.go` `rowQuerier` (adapts the graph's read surface with a no-op `Exec` so `truthRows` can call `load`); `export_test.go` `countingQuerier` (counts `Query`/`QueryRow`), `LoadQueryCount(q Querier, …)`; `autoreconciler_test.go` four helpers take `autoreconciler.Querier`, and line 1098 calls `LoadQueryCount(db, …)` | Write copy; the read functions demand `Exec` they never call; a second query counter beside the graph's |
| `datevalues` | `core/database/datevalues/datevalues.go` `InsertTx`, `insert` (Exec-only inline), `LookupManyTx` (Query-only), `LookupTx` (QueryRow-only), `scanValue` (inline `Scan`); `nullIfEmpty` (10 calls); `nullInt` (`*int` → `*p` or nil) | Inline copies; private binders |
| `namevalues` | `core/database/namevalues/namevalues.go` `LookupTx` (QueryRow+Query inline, param `q`), `LookupManyTx` (Query-only inline, param `db`) | Inline copies |
| `canonicalentities` | `core/database/canonicalentities/canonicalentities.go` `GetManyTx` (Query-only inline); `rowScanner` | Inline copy; scanner copy |
| `sources` | `core/database/sources/sources.go` `getOne` (QueryRow-only inline); `rowScanner` | Inline copy matched by bar 24; scanner copy |
| Scanner copies | `type rowScanner interface { Scan(dest ...any) error }` in `core/database/subjecttypes/subjecttypes.go`, `core/database/identityclaims/identityclaims.go`, `core/database/observations/write.go`, `core/database/canonicalentities/canonicalentities.go`, `core/database/citations/citations.go`, `core/database/sources/sources.go`, `core/database/sourcecredibility/assessments.go`, `core/database/filederivatives/filederivatives.go`, `core/database/artifacts/artifacts.go`, `core/database/sourcecredibilitygrades/grades.go`, `core/database/sourcemetadata/sourcemetadata.go`, `core/database/properties/properties.go`, `core/database/subjects/subjects.go`, `core/database/subjectpositions/subjectpositions.go`; `core/database/observationrow/observationrow.go` `Scanner` (exported, used by `observationrow.Scan`); inline `interface{ Scan(dest ...any) error }` in `metadatafields.ScanField`, `datevalues.scanValue`, `files.scanFile`, `evidencegraphs.scanGraph` | Nineteen copies |
| `audit` | `core/database/audit/audit.go` `nullIfEmpty` (2 calls in `Record`'s insert) | Private trim binder; imports `effects`, `rowchange`, `apperr`, not `core/database` |
| `core/search` | `core/search/fts.go` `fillMemberCounts` line 292 `marks := strings.TrimSuffix(strings.Repeat("?, ", len(ids)), ", ")`, over one page of hits, guarded by `len(ids) == 0` return above | Hand-built IN list; already imports `core/database` |
| Test helpers | `core/database/dbtest/dbtest.go` `Count` (QueryRow-only inline; imports only `rowchange` today); `core/database/autoreconciler/autoreconcilertest/autoreconcilertest.go` `dump` (Query-only inline); `core/database/graphcache/graphcachetest/graphcachetest.go` `execer` (Exec-only) used by `member` with `k.db` and a `*sql.Tx` | Copies; `Count` and `dump` are matched by bar 24 |
| Guard precedent | `core/writes/begin_test.go` `TestBeginOnlyInDatabaseAndWrites` | `go/parser` walk from `../..` that refuses `Begin` outside named trees. Its skip of names starting with `.` also skips the root `..`, so it parses zero files and always passes |
| Skill | `.agents/skills/add-catalog-query/SKILL.md` "Functions" (line 41: a by-id `IN` read goes through `sqlbatch`, never a hand-built `SQLInPlaceholders` list) and "Reads inside a write" | Names `database.Querier`; no rule against a local copy; no binder line; the IN-list rule names no exception. Eight functions build a list by hand: `autoreconciler.recomputeBatch`, `searchindex.reprojectHandleBatch` and `writeInputs`, `core/database/graphcache/load.go`'s four loads (also reached unbounded from test-only `verify.go` `verifyIDs`), `core/database/sourcevocab/copy.go` (levels), `identityclaims.bridgeHeadsSQL` (type keys), `core/search` `fillMemberCounts` (one page), `deleteimpact.handleGoesWithout` (unbounded: every Subject leaving a handle) |

**Precedent.** `core/database/sqlbatch` is the existing leaf: its package doc says "It imports nothing from the catalog, so the graph cache, which the database package depends on, can use it too." Copy that doc sentence's shape for `dbsql`. `database.Querier` itself (S12-01) is the shape the aliases keep. `core/writes/begin_test.go` is the AST check to copy for T-6, but not its walk: it skips its own root (D-15).

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | The leaf package is `core/database/dbsql` *(new)*, files `dbsql.go`, `dbsql_test.go`, `guard_test.go`, all in package `dbsql`. `dbsql.go` imports only `database/sql` and `strings` | Names what it holds (the `database/sql` surface the catalog packages share) without stuttering (`querier.Querier`) | `core/database/querier` — stutters and would also hold placeholders; putting the types in `sqlbatch` — a batching package is the wrong home for the connection surface |
| D-2 | `dbsql.Querier` = `Query(query string, args ...any) (*sql.Rows, error)` + `QueryRow(query string, args ...any) *sql.Row`. `dbsql.Execer` = `Querier` embedded + `Exec(query string, args ...any) (sql.Result, error)`; its doc says "Execer is Querier plus Exec: the surface a write takes". `dbsql.Scanner` = `Scan(dest ...any) error`; doc "Scanner is *sql.Row or *sql.Rows". Compile-time assertions in `dbsql.go`: `var _ Execer = (*sql.DB)(nil)`, `(*sql.Tx)(nil)`; `var _ Scanner = (*sql.Row)(nil)`, `(*sql.Rows)(nil)` | Same method sets as today's copies, so every caller still compiles. `Execer` is the working rule's name; its doc removes the Exec-only reading | `Writer` / `QueryExecer` — the rule names `Execer`, and the one Exec-only `execer` in the repo is deleted here |
| D-3 | In `core/database/tx.go`, the `Querier` interface becomes `type Querier = dbsql.Querier` (keeping today's doc comment), followed by `type Execer = dbsql.Execer` and `type Scanner = dbsql.Scanner` *(new)*, each with a one-line doc. In `sqlin.go`, `SQLInPlaceholders` and `BlobArgs` keep their names and doc comments and become one-line forwarders to `dbsql.SQLInPlaceholders` and `dbsql.BlobArgs` | Callers outside the leaf users keep `database.*`; no call site moves; each concept has one identifier in both packages | Moving all callers to `dbsql` — 6 + 4 call sites churn, and `dbsql` becomes a second spelling |
| D-4 | Only `core/database` itself (the aliases), `sqlbatch`, `graphcache`, `effects` (which `core/database` imports) and `dbtest` import `dbsql`. Every other package, test and helper uses `database.Querier` / `Execer` / `Scanner` | Those three cannot import `core/database`; `dbtest` keeps importing nothing from `core/database` so an internal test of the three can still use it | Everyone on `dbsql` — the skill teaches `database.Querier` |
| D-5 | Each local querier type is replaced by the shared type with the same method set: a read copy (Query, QueryRow, or a subset) → `Querier`; a copy with `Exec` → `Execer`. Subsets widen to `Querier` (`sqlbatch.Querier`, `datevalues.LookupManyTx`/`LookupTx`, `namevalues.LookupManyTx`, `canonicalentities.GetManyTx`, `sources.getOne`, `dbtest.Count`, `autoreconcilertest.dump`); Exec-only types (`datevalues.InsertTx`, `insert`, `graphcachetest.execer`) become `Execer`. A function typed with a write copy that never calls `Exec`, directly or through a callee, takes `Querier`: `searchindex`'s nine (§4) and `autoreconciler`'s (D-7). Every other `searchindex` function takes `database.Execer`. Parameter names stay (`namevalues.LookupManyTx` keeps `db`) | Working rule: "a package needing less than the full read surface still takes `database.Querier`"; D-10's sentence "a read takes `Querier`, a write `Execer`" is then true everywhere. Every caller passes `*sql.DB`, `*sql.Tx`, `*database.Tx` or `*graphcache.Graph` | Narrowing every function to the methods it calls — a larger diff for no rule anyone states |
| D-6 | `dbsql.SQLInPlaceholders(n int) string` and `dbsql.BlobArgs(ids [][]byte) []any` *(new)* take `database.SQLInPlaceholders`'s and `BlobArgs`'s bodies verbatim. `core/database/graphcache/sql.go` `placeholders` and `blobArgs` are deleted and `load.go`'s eight calls use the `dbsql` pair. `sqlbatch.go` line 46 uses `dbsql.SQLInPlaceholders(len(batch))` | Map "Also" for placeholders; `blobArgs` added by the user (2026-11-19); `sqlbatch`'s inline build is a third copy | Keeping the `sqlbatch` inline build |
| D-7 | In `autoreconciler`, functions that only read take `database.Querier`: `HandlesForSubjects`, `HandlesForSource`, `HandlesForCitation`, `HandlesForProperty`, `StoredVersion`, `NeedsRebuild`, `load`, `acceptedEntities`, `listIDs`. Functions that write take `database.Execer`: `RecomputeReported`, `recompute`, `Rebuild`, `recomputeBatch`, `insertRow`. `truth.go` `rowQuerier` is deleted and `truthRows` calls `load(q, chunk)` with its `database.Querier`. The four `autoreconciler_test.go` helpers take `database.Querier` | `rowQuerier` and its no-op `Exec` exist only because `load` demanded `Exec` | Keeping every function on `Execer` — keeps a fake `Exec` that returns `sql.ErrNoRows` |
| D-8 | `graphcache.Querier` users outside `graphcache`: `core/database/graphfill/load.go` (`database.Querier(g)` and the five loaders), `core/database/sources/records.go`, `core/database/autoreconciler/truth.go`, `core/database/searchindex/export_test.go` (`SetNewGraphForTest`, and `DependentsOfForTest`, `DependentsOfHandlesForTest`, `OldEndsForTest`, which wrap read functions), `core/database/searchindex/inputs_test.go` take `database.Querier`. `core/database/conclusionsummaries/conclusionsummariestest/inputs.go`'s `type Querier = graphcache.Querier` line and its doc comment are deleted and its functions take `database.Querier`. `graphcache.TruthFunc` and `graphcache` internals take `dbsql.Querier` | One name per layer (D-4) | Keeping `graphcache.Querier` as an alias — a second exported spelling |
| D-9 | `func NullTrimmed(s string) any` *(new)* in `core/database/null.go`, after `NullString`: `strings.TrimSpace`, then `nil` when empty, else the trimmed string. Doc: "NullTrimmed trims s and binds an empty result as SQL NULL. NullString does not trim." `datevalues` and `audit` delete `nullIfEmpty` and call it; `audit` imports `core/database` (no cycle) | Working rule; identical bodies today | In `dbsql` — it is a binder beside the other `Null*`, and neither caller is a leaf |
| D-10 | `add-catalog-query` changes in three places. (1) "Reads inside a write" gains: "A package never declares its own querier or scanner interface, named or inline: a read takes `database.Querier`, a write `database.Execer`, a row scan `database.Scanner`, even when it calls one method. `sqlbatch`, `graphcache`, `effects` and `dbtest`, which cannot import `core/database`, take the `dbsql` types those alias. `dbsql`'s guard test refuses a copy." (2) Functions line 41 becomes: "A by-id `IN` read goes through `core/database/sqlbatch` (`sqlbatch.Query`). A hand-built `SQLInPlaceholders` list is allowed only over a set something else already bounds: one `sqlbatch.Each` chunk, one page of search hits, or a fixed vocabulary of keys or levels. The function's comment names that bound. SQLite binds at most 32,766 values per statement." (3) Functions gains: "Bind an optional value with `database.NullBlob`, `NullString`, `NullInt`, `NullInt64` or `NullBool`; `NullTrimmed` when the text is trimmed first." | Bar 24; review M-1 and M-10: the rule is a condition every site meets, not a list of files (user, 2026-11-19) | Naming the allowed files — false on landing (eight sites, not two) and silent on the next one |
| D-11 | `core/search/fts.go` builds `marks` with `database.SQLInPlaceholders(len(ids))`; the `strings` import stays only if another use remains | Map "Also"; `"?,?"` and `"?, ?"` are the same SQL | — |
| D-12 | The nineteen `Scan` copies (§4 Scanner copies) are deleted. Every function that took `rowScanner`, `observationrow.Scanner` or an inline `interface{ Scan(dest ...any) error }` takes `database.Scanner`; parameter names stay. `observationrow.Scanner` is deleted outright (no alias); its callers outside the package, if any, move too (`rg "observationrow\.Scanner"` finds none at the base) | User, 2026-11-19: fold the scanner into S16-49. `*sql.Row` and `*sql.Rows` share `Scan` as `*sql.DB` and `*sql.Tx` share `Query` | A `dbsql.Scanner` with the copies left in place — not a cleanup |
| D-13 | `func NullInt(p *int) any` *(new)* in `core/database/null.go`, before `NullInt64`: nil → `nil`, else `*p` (an `int`, as `datevalues.nullInt` returns today). `datevalues` deletes `nullInt` and calls it | The binder list the skill names (D-10) is complete in the file STEP-7 edits | A generic `NullInt64` over `~int \| ~int64` — changes the bound value's type for today's `*int64` callers |
| D-14 | `autoreconciler`'s `export_test.go` `countingQuerier` is deleted. `LoadQueryCount(q database.Querier, ids [][]byte) (int, error)` builds `g := graphcache.Over(q)`, sets `g.SetQueryCounterForTest(func() { n++ })`, calls `load(g, ids)` and returns `n` | The graph already counts `Query` and `QueryRow`; `persondetail` and `evidencelayer` tests use it. `effects`' own counter stays: `graphcache` imports `effects` | Keeping a second counter |
| D-15 | `core/database/dbsql/guard_test.go` *(new)*: `TestNoLocalSQLSurface` runs two `filepath.WalkDir` calls, on `filepath.Join("..", "..", "..", "core")` and `filepath.Join("..", "..", "..", "api")`, skipping `vendor`, `testdata` and dot directories other than the walk's own root. It parses every `.go` file, test files included, and builds `rel` with `filepath.Rel` from the repo root and `filepath.ToSlash`. It fails on each `*ast.InterfaceType` (named or inline) in a file whose `rel` does not start with `core/database/dbsql/` that has at least one named method and whose named methods are all in {`Query`, `QueryRow`, `Exec`, `Scan`}; the message names `rel:line` and says to use `database.Querier`, `Execer` or `Scanner`. It also fails when it parsed zero files. `TestImportsNoModulePackage` parses `dbsql`'s non-test files and fails on any import with the prefix `github.com/Jake-Robins-Studios/provenencia/`. In the same step, `core/writes/begin_test.go` `TestBeginOnlyInDatabaseAndWrites` gets the same fix: its dot-directory skip applies only when `path != root`, and it fails when it parsed zero files (today it skips its root `../..` and parses none; no non-test file outside `core/database/` and `core/writes/` calls `.Begin()`, so it passes) | Bar 24 holds every day (review M-3); the walk `begin_test.go` uses never ran (review M-11) | A script in `check-pr.sh` — CI already runs `go test` |
| D-16 | Each hand-built `SQLInPlaceholders` list gets a one-line comment on its function naming its bound: `autoreconciler.recomputeBatch` (one `sqlbatch.Each` chunk from `recompute`), `searchindex.reprojectHandleBatch` and `writeInputs` (one chunk from `reprojectOn`), `graphcache` `StoredValues`, `loadMembers`, `loadOutcomes`, `linkLoadSQL` (one chunk from `loadIDs`, or every loaded node in test-only `Verify`), `sourcevocab` `CopyType`'s suggestion copy (the record levels), `identityclaims.bridgeHeadsSQL` (the bridge type keys), `core/search` `fillMemberCounts` (one page of hits). `deleteimpact.handleGoesWithout` gets no comment: S16-63 replaces its query | D-10's rule is true at every site on landing | Comments at call sites — the bound belongs to the function that builds the list |

**Rules this plan bends.** `add-catalog-query` line 41 ("never a hand-built `SQLInPlaceholders` list") → the code keeps eight hand-built lists; six are bounded by a chunk, a page or a fixed vocabulary, `graphcache.Verify` is test-only, and `deleteimpact.handleGoesWithout` is unbounded → the user accepted the rule as a condition: a hand-built list only over a set already bounded, its comment naming the bound; the unbounded delete query is fixed (2026-11-19) → STEP-8 (D-10 part 2, D-16); the delete query is S16-63.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `core/database/dbsql` *(new)* | package | `core/database/sqlbatch` (leaf) | `sqlbatch` is about batching by-id reads; the connection surface is not batching (D-1) |
| `dbsql.Querier` *(new)* | type | `database.Querier` | Moves it: `core/database` cannot be imported by `graphcache`/`effects`/`sqlbatch` |
| `dbsql.Execer`, `database.Execer` *(new)* | type | `autoreconciler.Querier`, `searchindex.Querier` | They become this one |
| `dbsql.Scanner`, `database.Scanner` *(new)* | type | `observationrow.Scanner`, fourteen `rowScanner` | They become this one (D-12) |
| `dbsql.SQLInPlaceholders` *(new)* | func | `database.SQLInPlaceholders` | Moves its body; the old one forwards |
| `dbsql.BlobArgs` *(new)* | func | `database.BlobArgs` | Moves its body; the old one forwards |
| `database.NullTrimmed` *(new)* | func | `database.NullString` | `NullString` must keep not trimming (working rule) |
| `database.NullInt` *(new)* | func | `database.NullInt64` | Takes `*int`, binds an `int` as `nullInt` does today |
| `TestSQLInPlaceholders`, `TestBlobArgs` *(new)* | test | none | First tests of the moved bodies |
| `TestNullTrimmed`, `TestNullInt` *(new)* | test | `TestNullBlob` in `null_test.go` | Copies its table shape |
| `TestNoLocalSQLSurface`, `TestImportsNoModulePackage` *(new)* | test | `core/writes/begin_test.go` `TestBeginOnlyInDatabaseAndWrites` | A different rule; both walks get the root fix (D-15) |

Searched: `rg "interface \{" core --type go`, C-2, C-3, `rg "strings.Repeat\(\"\?"`, `rg "func nullIfEmpty|func nullInt"`, `rg "func blobArgs|func placeholders"`, `rg "SetQueryCounterForTest"`, `rg "go/parser" core`.

**Builds on.** `sqlbatch`'s leaf pattern; `database.Querier` (S12-01); `null.go`'s binders; `graphcache.Over` and its query counter; `begin_test.go`'s walk.
**Deletes.** `sqlbatch.Querier`; `graphcache.Querier`; `graphcache` `placeholders`, `blobArgs`; `effects` `querier`; `namealiases.Querier`; `nameformats.Querier`; `conclusionsummaries.Querier`; `searchindex.Querier`; `autoreconciler.Querier`; `autoreconciler` `rowQuerier` and test `countingQuerier`; `conclusionsummariestest.Querier`; `graphcachetest` `execer`; fourteen `rowScanner` types; `observationrow.Scanner`; fourteen inline interface parameters (ten querier, four scanner); `datevalues` and `audit` `nullIfEmpty`; `datevalues` `nullInt`; `sqlbatch`'s inline placeholder build; `fts.go`'s hand-built marks.
**Next adds.** A new catalog package takes `database.Querier` / `Scanner` with nothing to copy, and T-6 refuses a copy; S16-62's seed writes, which take a `*database.Tx`, can hand helpers `database.Execer`.

### Reach

None — no new path into existing code, no new state reachable.

### Scale

None — no write, list or loop changes; every query text is the same except `fts.go`'s IN-list whitespace. T-6 parses the repo's Go files once per `go test` run, as `begin_test.go` does.

### Edges

- **Assumptions.** Interface method sets: every value passed today has `Query`, `QueryRow` and, where an `Execer` is now asked, `Exec` (`*sql.DB`, `*sql.Tx`, `*database.Tx` embeds `*sql.Tx`; `*graphcache.Graph` has `Query`/`QueryRow` and is only passed to read functions; `effects`' test wrapper embeds a full querier). Every scanner argument is a `*sql.Row` or `*sql.Rows`. `go build ./...` and `go vet` hold this.
- **Neighbors.** `SQLInPlaceholders(n)` for `n <= 0` → `""` (as today); `sqlbatch` only calls it with `n >= 1`; `fts.go` only with `len(ids) > 0`. `NullTrimmed(" a b ")` → `"a b"`. `NullInt(&0)` → `0`, not nil. T-6 does not flag an interface that embeds another plus one of the four names (none exists; an embedding interface is a new surface the reviewer sees), nor `observations.StagedFile` or `ScaleSeed` (other method names, or a struct). T-1, T-2, T-5 pin the values.
- **Removed inputs.** None — nothing is decided, excluded or deleted.
- **Real data.** None — no table, seed or configuration drives a rule here.
- **Untrusted size.** None — no new list or loop.

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/dbsql` *(new)* | `Querier`, `Execer`, `Scanner`, `SQLInPlaceholders`, `BlobArgs`, four `var _` assertions (D-1, D-2, D-6). Package doc: what it holds, and "It imports nothing from the catalog, so `sqlbatch`, `graphcache` and `effects`, which `core/database` imports, can use it." Guard tests (D-15) |
| `core/database` | `tx.go` aliases (D-3); `sqlin.go` forwarders (D-3); `null.go` `NullTrimmed`, `NullInt` (D-9, D-13) |
| `sqlbatch`, `graphcache`, `effects`, `dbtest` | `dbsql` types and helpers (D-4, D-6) |
| `namealiases`, `nameformats`, `conclusionsummaries`, `searchindex`, `autoreconciler`, `datevalues`, `namevalues`, `canonicalentities`, `sources`, `graphfill`, `audit`, `autoreconcilertest`, `graphcachetest`, `conclusionsummariestest`, and the scanner packages (§4) | `database.Querier` / `Execer` / `Scanner` / `NullTrimmed` / `NullInt` (D-5, D-7, D-8, D-9, D-12, D-13, D-14) |
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

type Scanner interface {
	Scan(dest ...any) error
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

In every step, add the `core/database` (or `dbsql`) import where a file now names it, and remove an import (`database/sql`, `strings`) the compiler reports unused.

**STEP-1 — The leaf package and the aliases**
Files: `core/database/dbsql/dbsql.go` *(new)*, `core/database/dbsql/dbsql_test.go` *(new)*, `core/database/tx.go`, `core/database/sqlin.go`.
Do: D-1, D-2, D-3, D-6 (the two functions). T-2, T-3.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/dbsql ./core/database` passes; `go list -deps ./core/database/dbsql | rg provenencia` prints only `dbsql` (AC-1.3); `go build ./...` passes.

**STEP-2 — The packages that cannot import `core/database`**
Files: `core/database/sqlbatch/sqlbatch.go`; `core/database/graphcache/graph.go`, `verify.go`, `sql.go`, `load.go` and every other `graphcache` file naming `Querier`; `core/database/effects/path.go`, `path_test.go`, `export_test.go`; `core/database/dbtest/dbtest.go`.
Do: delete `sqlbatch.Querier`, `graphcache.Querier`, `effects.querier`, `graphcache` `placeholders` and `blobArgs`; use `dbsql.Querier`, `dbsql.SQLInPlaceholders`, `dbsql.BlobArgs` (D-4, D-6). In `path_test.go`, `countingQuerier` embeds `dbsql.Querier`, calls `c.Querier.QueryRow`, and line 42's literal becomes `&countingQuerier{Querier: db}`. `dbtest.Count` takes `dbsql.Querier`. Fix every `graphcache.Querier` reference outside `graphcache` in this step with D-8 so the tree builds: `core/database/graphfill/load.go`, `core/database/sources/records.go`, `core/database/autoreconciler/truth.go` (`truthRows` and `rowQuerier`'s field type only; `rowQuerier` goes in STEP-4), `core/database/conclusionsummaries/conclusionsummariestest/inputs.go`, `core/database/searchindex/export_test.go`, `core/database/searchindex/inputs_test.go`.
Check: `rg -n "graphcache\.Querier|sqlbatch\.Querier|func placeholders|func blobArgs" --type go .` prints nothing; `CGO_ENABLED=1 go test -tags fts5 ./core/database/...` passes.

**STEP-3 — The named read and write copies**
Files: `core/database/namealiases/namealiases.go`, `core/database/nameformats/nameformats.go`, `core/database/conclusionsummaries/conclusionsummaries.go`, `core/database/searchindex/searchindex.go`, `handles.go`, `inputs.go` and the other `searchindex` files naming `Querier`.
Do: delete each package's `Querier`; read copies use `database.Querier`; in `searchindex`, the nine functions §4 names take `database.Querier`, the rest `database.Execer` (D-5).
Check: `rg -n "type Querier" core --type go` prints only `core/database/dbsql/dbsql.go` *(new)*, `core/database/tx.go` (the alias) and `core/database/autoreconciler/autoreconciler.go` (gone in STEP-4); tests pass as in STEP-2.

**STEP-4 — `autoreconciler`**
Files: `core/database/autoreconciler/autoreconciler.go`, `truth.go`, `export_test.go`, `autoreconciler_test.go`.
Do: first, before any edit in this step, record `LoadQueryCount` for 1 and for 60 handles on the fixture `TestLoaderQueryCountIsConstant` builds (a throwaway `t.Logf`, not committed). Then D-7, D-14. Delete `Querier`, `rowQuerier` and `countingQuerier`.
Check: `rg -n "rowQuerier|countingQuerier|autoreconciler\.Querier" core/database/autoreconciler` prints nothing; `CGO_ENABLED=1 go test -tags fts5 ./core/database/autoreconciler/... ./core/writes/...` passes, and `LoadQueryCount` returns the two numbers recorded before the edit.

**STEP-5 — Inline querier interfaces and the last IN list**
Files: `core/database/datevalues/datevalues.go`, `core/database/namevalues/namevalues.go`, `core/database/canonicalentities/canonicalentities.go`, `core/database/sources/sources.go`, `core/database/autoreconciler/autoreconcilertest/autoreconcilertest.go`, `core/database/graphcache/graphcachetest/graphcachetest.go`, `core/search/fts.go`.
Do: D-5 for each inline parameter and `execer`; D-11.
Check: C-1 and C-2 (§2) print exactly what they say; `CGO_ENABLED=1 go test -tags fts5 ./core/...` passes.

**STEP-6 — Scanners**
Files: the nineteen sites in §4 "Scanner copies".
Do: D-12.
Check: C-3 (§2) prints one line; `rg -n "rowScanner|observationrow\.Scanner" --type go .` prints nothing; `CGO_ENABLED=1 go test -tags fts5 ./core/...` passes.

**STEP-7 — Binders**
Files: `core/database/null.go`, `core/database/null_test.go`, `core/database/datevalues/datevalues.go`, `core/database/audit/audit.go`.
Do: D-9, D-13; T-1, T-5.
Check: `rg "func nullIfEmpty|nullIfEmpty\(|func nullInt\b|nullInt\(" core` prints nothing; `CGO_ENABLED=1 go test -tags fts5 ./core/database/... ./core/writes/...` passes.

**STEP-8 — Guard and skill**
Files: `core/database/dbsql/guard_test.go` *(new)*, `core/writes/begin_test.go`, `.agents/skills/add-catalog-query/SKILL.md`, `.agents/skills/review-pr/lenses/maintainability.md`, and the D-16 files.
Do: D-15 (T-6, T-7, T-8); D-10; D-16. Add to **Known traps** in `maintainability.md`: "A repo walk from `..` that skips names starting with `.` skips its own root and checks nothing: skip only below the root, and fail on zero files (S16-49)."
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/dbsql` passes; adding a scratch `type q interface { QueryRow(string, ...any) *sql.Row }` to any `core/` file makes T-6 fail with that `path:line`, and a scratch `db.Begin()` in a `core/search` non-test file makes T-8 fail (remove both after); `CGO_ENABLED=1 go test -tags fts5 ./core/writes` passes; `python3 scripts/check-guidance-names.py` passes; `scripts/check-pr.sh` per the DoD.

**STEP-9 — Docs**
Files: `docs/deployment-plan/spike-16/completed.md`, `docs/deployment-plan/spike-16/deployment-plan.md`, this plan (status, Landed note).
Do: per the Definition of done. In `deployment-plan.md`: the S16-49 map row status; bar 24 says the `rg` finds one line, `dbsql`'s `Querier` (C-1). The row text, scope entry and Batch 6 rule were brought in line with this plan at planning time.
Check: links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed, ending in a period, like the rest of `git log` ("Define the catalog's read and write queriers once, in a leaf package."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/null_test.go` `TestNullTrimmed` *(new)*, table | `""` → nil; `" \t\n"` → nil; `"abc"` → `"abc"`; `"  abc "` → `"abc"`; `" a b "` → `"a b"` | AC-2.1, AC-2.2, D-9 |
| T-2 | Go | `core/database/dbsql/dbsql_test.go` `TestSQLInPlaceholders` *(new)*, table | -1 → `""`; 0 → `""`; 1 → `"?"`; 3 → `"?,?,?"` | AC-3.2, D-6 |
| T-3 | Go | `core/database/dbsql/dbsql_test.go` `TestBlobArgs` *(new)*, table | nil → `len` 0; two 16-byte ids → `len` 2, and each element type-asserts to `[]byte` and is `bytes.Equal` to its id, in order | D-6 |
| T-4 | Go | existing suites, unchanged assertions | `CGO_ENABLED=1 go test -tags fts5 ./api/... ./core/...` passes | AC-3.1 |
| T-5 | Go | `core/database/null_test.go` `TestNullInt` *(new)*, table | nil → nil; `&0` → `0`; `&1890` → `1890`, each compared with `==` against an `int` | AC-2.4, D-13 |
| T-6 | Go | `core/database/dbsql/guard_test.go` `TestNoLocalSQLSurface` *(new)* | the repo after STEP-6 → passes; STEP-8's scratch interface → fails naming its `path:line` | AC-1.6, AC-1.1, AC-1.2, AC-1.5, D-15 |
| T-7 | Go | `core/database/dbsql/guard_test.go` `TestImportsNoModulePackage` *(new)* | `dbsql.go` imports only standard library → passes | AC-1.3, D-15 |
| T-8 | Go | `core/writes/begin_test.go` `TestBeginOnlyInDatabaseAndWrites` (fixed) | the repo → passes having parsed more than zero files; STEP-8's scratch `Begin` → fails | D-15 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `core/database/autoreconciler` (D-7, D-14), `core/database/graphcache` and `graphfill` (D-8), `core/database/effects` (`countingQuerier`), `core/database/observations` (D-12).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or the command and its output for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks); off macOS, `check-pr: FAIL xcode-test (needs macOS)` with no other failure, reported as such
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left — none in this PR
- [ ] Sweep: each deleted name `rg`'d by its old, qualified name (`sqlbatch.Querier`, `graphcache.Querier`, `searchindex.Querier`, `autoreconciler.Querier`, `nameformats.Querier`, `namealiases.Querier`, `conclusionsummaries.Querier`, `rowQuerier`, `rowScanner`, `observationrow.Scanner`, `nullIfEmpty`, `nullInt`) across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated: add-catalog-query line 41 (D-10 part 2)
- [ ] UI matches the brief inventory — no UI
- [ ] Version bump as the header says — none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status and text, bar 24 wording; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated) — not gated
- [ ] Domain doc updated if a rule in docs/*.md changed — none changes
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

None in the app: nothing it draws or does changes. The reviewer runs C-1 (AC-1.1), C-2 (AC-1.2), C-3 (AC-1.5) C-4 (AC-1.3) and C-5 (AC-2.3) and sees the outputs §2 names; adds the scratch interface from STEP-8 and sees T-6 fail (AC-1.6); and reads `.agents/skills/add-catalog-query/SKILL.md` for D-10's three changes (AC-1.4).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| An import cycle from `audit` → `core/database` | Verified: `go list -deps ./core/database` has no `audit`. STEP-7 builds it |
| A caller passes a type with fewer methods than the widened parameter asks | Verified at the base (D-5); `go build ./...` in each step catches one |
| `effects` test wrapper's embedded field renames (`querier` → `Querier`) | STEP-2 names it |
| T-6 flags an interface the plan did not list | It lists every match at the base (C-2, C-3); a new hit is a stop condition |
| S16-54 (`dbtest.WritePNG`) also edits `core/database/dbtest/dbtest.go` | Different functions; rebase on whichever lands first |

**Stop and report if:**

- `go build ./...` fails because a caller passes a value without `QueryRow` or `Exec` to a widened parameter (D-5), or a non-`*sql.Row`/`*sql.Rows` value without `Scan` (D-12): name the caller and the type.
- `dbsql` would need to import any `github.com/Jake-Robins-Studios/provenencia/...` package.
- `audit` cannot import `core/database` without a cycle.
- A function D-5 or D-7 lists as read-only calls `Exec`, directly or through a callee.
- T-6 fails on an interface that §4 does not list.
- `LoadQueryCount` through `graphcache.Over` returns a different count than the one STEP-4 recorded before its edit.
- A test assertion (not a helper's parameter type) has to change for the suite to pass.

## 12. Open questions

None.

## 13. PR

**Title:** S16-49 — One read querier and one write querier for every catalog package
**Body:** objective in one sentence; the copies deleted (§6 Deletes); AC evidence (the `rg`/`go list` outputs, the guard tests, the test run); deviations from the plan; `Plan: docs/deployment-plan/spike-16/prs/S16-49-one-querier.md`.
