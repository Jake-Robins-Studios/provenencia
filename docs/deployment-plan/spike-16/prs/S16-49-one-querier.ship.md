# Ship log — S16-49 One read querier and one write querier for every catalog package

**Plan:** [`S16-49-one-querier.md`](S16-49-one-querier.md) · **Branch:** `s16-49-one-querier` · **PR:** #903
**State:** ready

## Round 0 — implement
Head `57982b9c3`. Gate PASS (orchestrator run). Report deviations: `sources.fillDates` carried an unlisted inline Query-only interface; it now takes `database.Querier` (noted in the plan's Landed note). D-16 bound comments ride in the querier and scanner commits rather than one of their own; commits 2 and 3 mix behaviors in a few files.

## Round 1 — review
Reviewers: CON, MNT, SEC+PRF. Skipped: UX (no `macos/App/**`, strings, `core/apperr` or error codes).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | major | Three copies of "query a column of ids" (`autoreconciler.listIDs`, `searchindex.listIDs`, `effects.queryIDs`), each re-typed by this PR | Fix now → F-1 | verified: `rg` over the signature prints exactly the three; bodies identical except `effects`' 16-byte filter and a redundant copy. Same-pass cleanup: this PR edits all three |
| MNT-2 | MNT | major | `TestNoLocalSQLSurface` is a fourth hand-written repo walk (`begin_test`, `audit/scopes_internal_test`, `catalogsession/cache_doc_test`); two copies of the module-path constant added/kept | Fix now → F-2 | verified: `rg -ln go/parser` + read of each loop; they differ in root, skip and empty-scan handling. Same-pass cleanup: this PR adds one copy and edits another. Supersedes D-15's walk wording (the guard's rules stand; only the walk moves) |
| MNT-4 + SEC note | MNT, SEC | minor | `graphcache/load.go` bound comments say "bounded" then name test-only `Verify`'s unbounded set; `StoredValues`' comment omits `autoreconciler.recomputeBatch` | Fix now → F-3 | verified by reading `load.go:202,256,287,391` and `autoreconciler.go:293`. Stale comment in code this PR adds |
| MNT-3 | MNT | nit | `loadMembers` bound comment is one long line | Fix now → F-3 (rides along) | same comment block as F-3 |

Nits (logged): `CON-1 · core/database/autoreconciler/autoreconciler_test.go:1102 · assert one > 0 so the count test cannot pass at 0 == 0 (pre-existing)`

SEC+PRF: clean. CON: clean (T-8's failing case was checked by reading, not run; the implementer's report covers the scratch run).

### Fix plan 1

**F-1 — One id-column reader in the leaf** (from MNT-1)
Files: `core/database/dbsql/dbsql.go`, `dbsql_test.go`, `core/database/autoreconciler/autoreconciler.go`, `core/database/searchindex/searchindex.go`, `core/database/effects/path.go`, `.agents/skills/add-catalog-query/SKILL.md` (one line naming it).
Failing test first: `dbsql.TestQueryIDs` (table-driven over an in-memory SQLite: two rows → both ids in order; no rows → empty; a query error → the error).
Do: add `dbsql.QueryIDs(q Querier, query string, args ...any) ([][]byte, error)` with the shared body (Query, defer Close, scan one `[]byte` per row, return `rows.Err()`), no length filter and no extra copy, so the two `listIDs` callers keep exactly today's behavior. Delete both `listIDs`; callers use `dbsql.QueryIDs` (or a `database.QueryIDs` forwarder if `core/database` already forwards the other leaf helpers; follow D-1's pattern). In `effects`, delete `queryIDs`'s body: the three call sites call `dbsql.QueryIDs` and keep the 16-byte rule through one small `effects`-local filter over the result (name it for what it keeps, e.g. `uuidsOnly`); behavior at those sites is unchanged.
Check: `rg -n "func \w+\(q [\w.]+, query string, args \.\.\.any\) \(\[\]\[\]byte, error\)" --type go core api` prints only the `dbsql.go` line; `go test` for the three packages passes; scripts/check-pr.sh PASS.

**F-2 — One repo-file walker for the guard tests** (from MNT-2)
Files: new `core/internal/gosrc/gosrc.go` + `gosrc_test.go`; `core/database/dbsql/guard_test.go`, `core/writes/begin_test.go`, `core/database/audit/scopes_internal_test.go`, `core/catalogsession/cache_doc_test.go`, `core/matchregistry/guard_test.go` (constant only), `.agents/skills/review-pr/lenses/maintainability.md` (Known traps line).
Failing test first: `gosrc.TestFiles` — over a `t.TempDir()` tree with a `go.mod`, a dot dir, `vendor/`, `testdata/` and nested `.go` files: returns only the nested files with slash-separated repo-relative `Rel`; an empty root fails the test (use a fake `testing.TB` or a sub-helper returning an error to assert it).
Do: `package gosrc` exports `const Module = "github.com/Jake-Robins-Studios/provenencia/"`, `type File struct{ Rel, Path string }`, and `Files(t testing.TB, roots ...string) []File`: finds the repo root by walking up from the working directory to `go.mod`, walks each root (relative to the repo root) skipping `vendor`, `testdata` and dot directories below the root only, returns every `.go` file (test files included; callers filter `_test.go` themselves), and `t.Fatal`s on a walk error or zero files. Move the four guards onto it, each keeping its own filter and check (audit and cache_doc skip `_test.go`; dbsql and begin keep what they do today). Replace the two `modulePath` constants and cache_doc's `module` with `gosrc.Module`. Remove the hand-added `path != root` / `parsed == 0` code from `begin_test` and `guard_test` (the walker owns it); audit's `len(found) < 10` check stays (it guards its own scan, not the walk). Rewrite the Known traps line to: "A guard test that walks the repo uses `core/internal/gosrc.Files`; a hand-written walk from `..` can skip its own root and check nothing (S16-49)." `core/internal` must import nothing from the module (it is test support used across packages).
Check: `rg -ln "filepath.WalkDir" core api --glob '*_test.go'` prints only `core/internal/gosrc` (and any walk that is not over repo Go source, each named in the report); `rg -n '"github.com/Jake-Robins-Studios/provenencia/"' core --type go` prints only `gosrc.go`; re-run AC-1.6's scratch interface and T-8's scratch `Begin()` and report both fail; scripts/check-pr.sh PASS.

**F-3 — Bound comments say what bounds them** (from MNT-4, MNT-3, SEC outside-lens note)
Files: `core/database/graphcache/load.go`.
Do: at lines ~202, 256, 287, 391 reword each to "bounded in production: one `sqlbatch.Each` chunk (callers: …); test-only `Verify` passes every loaded node". `StoredValues`' list of callers adds `autoreconciler.recomputeBatch` (one `recompute` chunk). Wrap `loadMembers`' comment as a separate paragraph like its siblings.
Check: read; scripts/check-pr.sh PASS.

## Round 1 — fix
Head `8007b7983`. Gate PASS (orchestrator run). F-1 done (`dbsql.QueryIDs`, `database.QueryIDs` var forwarder so the signature grep prints one line; `effects` keeps its 16-byte rule as `uuidsOnly`; the redundant id copy dropped). F-2 done (`core/internal/gosrc.Files` + `Module`; four guards moved; `begin_test` now walks `core` and `api` only; remaining `WalkDir` test hits walk catalog `objects/` dirs, not Go source; scratch interface and scratch `Begin()` both fail). F-3 done. Extra: `add-catalog-query` line reworded to pass guidance-names; `completed.md` paragraph updated.
F-3 (MNT-4, MNT-3, SEC note): **Resolved** — orchestrator read `f67e71cde`; each comment names the production chunk and `Verify` separately; `StoredValues` names `recomputeBatch`; `loadMembers` wrapped.

## Round 2 — review
Reviewers: MNT (scope `57982b9c3...8007b7983`). CON and SEC+PRF not re-run: no Fix-now blocker or major in round 1.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | major | (round 1) three id-column readers | Resolved | one `dbsql.QueryIDs`; signature grep prints one line |
| MNT-2 | MNT | major | (round 1) fourth repo walk | Resolved | `gosrc.Files` only; module literal only in `gosrc.go` |

No new blocker.

Nits (logged): `MNT-5 · core/database/sqlin.go:45 · var forwarder vs neighbors' func wrappers (the var form was chosen so F-1's signature grep prints one line)` · `MNT-6 · core/internal/gosrc/gosrc.go:18 · File.Path comment should say "absolute path"`

## Finish
Merged `origin/main` @ `326261bb8` (docs only: S15-44 plan). Gate PASS against `326261bb8`.

## Result
Gate PASS · CI pending at commit · open: none · follow-ups: none · to user: —
