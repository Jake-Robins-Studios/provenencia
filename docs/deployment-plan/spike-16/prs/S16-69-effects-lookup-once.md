# S16-69 — A commit runs each effects lookup once

**Status:** Landed in [#979](https://github.com/Jake-Robins-Studios/provenencia/pull/979) (2026-11-26)
**Spike / slice:** Spike 16 · Slice 6g — Catalog query layer
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: engine-only, nothing a researcher sees changes)
**Board:** —
**Depends on:** —
**Blocks:** —
**Branch:** `s16-69-effects-lookup-once`
**Version bump:** none — no change a researcher can see, no wire and no catalog change, as for S16-11 ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-audit-scope`](../../../../.agents/skills/add-audit-scope/SKILL.md) (the registry paths `Resolve` walks and what reads `Set`)
**Rules that bind:** `.cursor/rules/go-tests.mdc`, `.cursor/rules/catalog-audit.mdc`
**Context:** [design § A commit runs the same effects lookup more than once](../catalog-query-layer.md#a-commit-runs-the-same-effects-lookup-more-than-once-s16-69); working rules "(Batch 6) The effects memo lives for one change", "(Batch 2) No new persisted projections, and no stored answer without a measurement"; map Scale line "Scale (Batch 6, slice 6g)"; the S15-05 ship log, PRF-1 ([`../../spike-15/prs/S15-05-person-sources-date.ship.md`](../../spike-15/prs/S15-05-person-sources-date.ship.md))
**Planned:** 2026-11-26 against `main` @ `f41c43b`
**Review:** [`S16-69-effects-lookup-once.review.md`](S16-69-effects-lookup-once.review.md) — Fits with changes · Ready with changes, 1 round; no blocker open; To user: none

**Landed.** Differences from the plan: none.

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

A write's effects are resolved by walking each changed row's registry paths, and two paths that share a query step run its SQL twice. After this PR, each lookup runs once per changed row: a Source date change looks up its Source once, not twice, and an Observation's value row runs its Observation and handle lookups once, not two to five times. The effects a write reports do not change.

**Why now.** S15-05's PRF-1 measured the repeat (`sources.date_value_id` looked up for both `SourceScope` and the `source_records` read), and an import of 10,000 dates pays 10,000 extra lookups for it. The user scoped the fix to a memo that lives for one change (working rule "(Batch 6) The effects memo lives for one change", 2026-11-24).

**What stays.** Every registry path, every `Set` field and its order, `writes.Run`'s single `Resolve` call, the audit scopes, and the wire.

## 2. User stories

**US-1.** As the engine, when I resolve one changed row, I run each distinct lookup (query text and input id) once, so that a large commit does not pay for the same indexed read twice.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A Source's date is set (`sources.SetDate`); `Resolve` runs over the `date_value` change | `SELECT id FROM sources WHERE date_value_id = ?` runs once for the date's id (today twice: `SourceScope` and `ReadSourceRecords`), and its `observations.value_date_id` lookup runs once (today five times, as AC-1.2) |
| AC-1.2 | An Observation with a date is created; `Resolve` runs over its `date_value` change | `SELECT id FROM observations WHERE value_date_id = ?` runs once (today five times: `EvidenceGraph`, the `citations` read, `SourceScope`, `Handles`, `HandleScope`), and the `identity_claims` lookup of its Subject runs once (today twice: `Handles`, `HandleScope`) |
| AC-1.3 | Either change above | No query text runs twice with the same arguments while one change is resolved |
| AC-1.4 | The same change appears twice in one `Resolve` call | Its `sources.date_value_id` lookup runs twice: once per change, since the memo is dropped with the change |
| AC-1.5 | Any write the package's tests cover today | `Resolve` reports the same `Set` as before; a test that read `effects.Handles(tx, changes)` reads `effects.Resolve(tx, changes)`'s `.Handles` and gets the same ids in the same order |

## 3. Scope

| In | Covered by |
| --- | --- |
| A memo on `walk`, owned by one lookup method that `inbound`, `across`, `sqlPath` and `readRowsColumn` call (D-1, D-2) | STEP-2, AC-1.1 – AC-1.3 |
| The memo lives for one change: one `walk` per change, as today (D-3) | STEP-2, AC-1.4 |
| `Resolve` takes a `dbsql.Querier`; `Handles` and `resolve`, a second batch-walk loop with no production caller, go (D-4) | STEP-1, AC-1.5 |
| One query-counting test double for the package, and a test with it that drives `Resolve` (D-5) | STEP-2, STEP-3, AC-1.1 – AC-1.4 |
| `core/database/effects/README.md` names the memo and the one lookup method; the docs that name `effects.Handles` name `Set.Handles` | STEP-1, STEP-4 |

| Out | Home |
| --- | --- |
| A memo shared across changes or commits | not planned — refused by rule "(Batch 6) The effects memo lives for one change" |
| New or changed registry paths | not planned — a later path reads through the memo with no change of its own |
| Batching lookups across ids into one `IN (…)` query | not planned — the per-id indexed lookup is what PRF-1 measured; the memo removes the repeat |
| A timing benchmark of a 10,000-date import | not planned — the claim is a query count per change, pinned by T-1 (§6 Scale) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Walk state | `core/database/effects/path.go` `walk` | `q`, `ch`, `ghosts`, `table`; no memo, so a step's result is not kept |
| Inbound step | `path.go` `inbound` | Builds `SELECT <pk> FROM <table> WHERE <col> = ?` and loops the input ids through `dbsql.QueryIDs`, keeping `uuidsOnly` |
| Across step | `path.go` `across` | The same loop as `inbound`, with its own query |
| SQL step | `path.go` `sqlPath` | The same loop again, for a fixed query |
| Column read | `path.go` `readRowsColumn` | Dedupes input ids with `seen`, reads each with `w.q.QueryRow(...).Scan`, falls back to `w.ghosts.id` when `raw` is not 16 bytes (no row, or a NULL column) and the table has an entity; no memo across calls, so `up` / `field` / `from` paths that share a hop read it again |
| Entry points | `core/database/effects/resolve.go` `Resolve`, `resolve`, `Handles` | Take `*sql.Tx`; build one `walk` per change (`&walk{q: tx, ch: ch, ghosts: ghosts, table: table}`), so a memo on `walk` dies with the change. `resolve` repeats `Resolve`'s loop for one path; `Handles` is its one caller, and only tests call `Handles` (`conclusion_handles_test.go`, `evidence_handles_test.go`, `handle_paths_test.go` `mustHandles`, `core/database/deleteimpact/facets_test.go`) |
| Test-only entry | `core/database/effects/export_test.go` `SourceScopeOfChange` | Takes `dbsql.Querier` already; builds its own `walk`; the file shows internal test code to `effects_test` |
| Repeats | `core/database/effects/registry.go` `ownedValue`, `valueGraph`, `valueMembers`, `valueSource`, `"date_values"` entry | `valueGraph(col)` runs for `EvidenceGraph` and the `citations` read; `valueMembers(col)` for `Handles` and `HandleScope`; `inbound("observations", col)` starts all three plus `valueSource`; the `date_values` entry passes `inbound("sources", "date_value_id")` as a Source owner, run by `SourceScope` and `ReadSourceRecords` |
| Caller | `core/writes/run.go` `Run` | `effects.Resolve(tx.Tx, changes)`: a `*sql.Tx`, which satisfies `dbsql.Querier` |
| Tests | `core/database/effects/path_test.go` `countingQuerier`, `TestReadRowsColumnLooksUpEachIDOnce` | The double overrides `QueryRow` only and counts into `rows`; the test asserts `rows == 2` for four ids with two distinct; once `readRowsColumn` reads through `Query` it would count 0 |
| Tests | `core/database/effects/reads_resolve_test.go` `readsFixture`, `only` | A Source with Default and Jones graphs and an Artifact in a rolled-back `*database.Tx`; T-1 builds on it |
| Tests | `core/database/effects/registry_completeness_test.go` `TestMetadataEffects`, and every other `*_test.go` in the package; `core/database/audit/scopes_test.go` | The effects each write reports today |

**Precedent.** `readRowsColumn`'s `seen` map and `TestReadRowsColumnLooksUpEachIDOnce` (`path_test.go`) already remove a repeat inside one step, with a counting `Querier`. Copy that shape (a counting double, an exact count); the memo widens it from one step to every step of one change.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | One method, `(*walk).lookup` (Codebase fit), owns the input selection, the memo and the id loop: it takes the change's id when `fromChange`, else `in`; for each 16-byte id it returns the memoised rows for `(query, id)` or runs `dbsql.QueryIDs` once and stores its `uuidsOnly` result; non-16-byte ids are skipped as today; an error is returned and not stored. It always returns a new outer slice; the id bytes are shared with the memo | Rule "(Batch 6) The effects memo lives for one change" names one method for the memo and the three copied loops; a fresh outer slice keeps a caller's `append` out of a memo entry | A memo per step type — three copies of the same cache |
| D-2 | `readRowsColumn` keeps its `seen` dedupe, and reads each id through `w.lookup(q, [][]byte{id}, false)`, taking the first row as `raw`. Its fallback is kept as written: when `raw` is not 16 bytes (no row, or a NULL column) and `entityOf(table) != ""`, `raw = w.ghosts.id(entity, id, col)` | The memo sits before the ghost fallback (the rule); one read path means one memo | Keeping `QueryRow` with a second memo accessor — two owners of one map |
| D-3 | The memo is a lazily made `map[memoKey][][]byte` field on `walk`, `memoKey` being the query text and the 16-byte id as `[16]byte`. No code resets it: each `walk` already lives for one change | The catalog does not change during `Resolve`, which only reads, and a `walk` never outlives its change; a struct key needs no separator | A joined string key — a separator to reason about and a string built per lookup |
| D-4 | `Resolve` takes `q dbsql.Querier` in place of `tx *sql.Tx`; its nil check becomes `q == nil` with the same `"effects: nil tx"` message. `Handles` and `resolve` are deleted: production reads `Set.Handles` from `Resolve` (`writes.Run`), and `resolve` repeats `Resolve`'s loop. Each test that called `effects.Handles(tx, changes)` calls `effects.Resolve(tx, changes)` and reads `.Handles` (same walk, same first-seen order through `appendIDs`) | A test can wrap the transaction in a counting double; one batch-walk loop, so a later change to it has no twin | Re-signing `Handles` and `resolve` — keeps a second loop no production code calls |
| D-5 | The package has one query-counting double, `QueryLog` *(new)* in `export_test.go`, replacing `countingQuerier` in `path_test.go` (Codebase fit). `TestReadRowsColumnLooksUpEachIDOnce` uses it and asserts `Total() == 2`, the same claim as `rows == 2`; `lookup_once_test.go` uses it as `effects.QueryLog` | An exported identifier in a `package effects` `_test.go` file is visible to `effects_test`, as `SourceScopeOfChange` is; `core/database` imports `effects`, so the test that drives `Resolve` over a catalog must be external | Two doubles in one package — one counts in total, one per query |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

Searched `core/` for an existing per-walk or per-query memo (`memo`, `cache`, `seen` in `core/database/effects`, `core/database/dbsql`, `core/database/graphcache`) and for query-counting test doubles (`countingQuerier`, `Querier` wrappers in `*_test.go`).

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `walk.memo` *(new)* field, `memoKey struct{ query string; id [16]byte }` *(new)* | field, type | `readRowsColumn`'s local `seen` map | `seen` lives for one call; the memo must span the steps of one change |
| `func (w *walk) lookup(query string, in [][]byte, fromChange bool) ([][]byte, error)` *(new)* | func | the loops and the `targets` prelude in `inbound`, `across`, `sqlPath` | It is those, moved into one place and memoised; each step's run becomes one `return w.lookup(q, in, fromChange)` |
| `QueryLog` *(new)* in `core/database/effects/export_test.go`: embeds `dbsql.Querier`; `Query` and `QueryRow` each count one call under the query text and the first argument when that is a `[]byte`; `Count(substr string, id []byte) int` sums the calls whose query text contains `substr` with that id; `Repeats() []string` lists the query texts called more than once with the same id; `Total() int` counts every call | test helper | `path_test.go` `countingQuerier` | Replaces it (D-5) |
| `core/database/effects/lookup_once_test.go` *(new)*, `TestResolveRunsEachLookupOnce` *(new)* | test file | `reads_resolve_test.go` | A separate claim (query counts), reusing that file's `readsFixture` and `only` |

**Builds on.** The per-change `walk` that `Resolve` already builds; `dbsql.QueryIDs` and `uuidsOnly`; `readRowsColumn`'s `seen` precedent; `export_test.go`'s way of showing test code to `effects_test`.
**Deletes.** The three copied `targets` preludes and id loops in `inbound`, `across` and `sqlPath`; `readRowsColumn`'s `QueryRow(...).Scan` and its `sql.ErrNoRows` branch, and with it `path.go`'s `database/sql` import (its one use); `effects.Handles` and `resolve`, and `resolve.go`'s `database/sql` import; `countingQuerier`; the prose that names `effects.Handles`: `docs/catalog-deletes.md` (the `Release` row and "Handles come from the released changes"), `.agents/skills/add-catalog-delete/SKILL.md` (the `// handles come from effects.Handles on changes` line), the comment in `core/database/deleteimpact/facets.go` (`effects.Handles on these changes`), and `core/database/effects/README.md` ("`Handles` and `Resolve` take `[]rowchange.Change`"), each saying `Set.Handles` from `Resolve` instead.
**Next adds.** Any registry path a later PR adds (Spike 15's S15-54 Citation level, S16-70's `Deleted` entries) reads through `lookup` with no change of its own; a later counting test uses `QueryLog`.

### Reach

None — no new path into existing code. `Resolve`'s callers and the `Set` it returns are unchanged; the memo is internal to one change.

### Scale

At the map's Scale (Batch 6, slice 6g: a commit writing 10,000 date values on the 16,000-person fixture with 3,000 Sources): each `date_value` change is its own `walk`, so its memo holds that change's distinct lookups (under 20 entries for an owned value row) and is garbage once the change is resolved. A Source date change drops from two `sources.date_value_id` lookups to one, so the import pays 10,000 lookups, not 20,000; an Observation date drops its `observations.value_date_id` lookup from five to one and its Subject's `identity_claims` lookup from two to one. Each lookup stays an indexed single-id read, so the per-change cost does not grow with the catalog. T-1 pins the per-change counts; the batch total is that count times the changes, which T-1's "twice in one batch" case shows is not shared across changes. No time budget is set, so no timing is measured.

### Edges

- **Assumptions.** The memo key (D-3) is complete because every step builds its query from `ident`-checked names and `sqlPath`'s queries are constants: the text names the table and columns. `from` and `chain` move `w.table` during a walk; the key does not read it, so a hop on another table never hits another table's entry.
- **Neighbors.** Duplicate input ids to `inbound` / `across` / `sqlPath` still yield duplicate output ids, as today (the memo answers the second); `appendIDs` dedupes them downstream (AC-1.5). Two changes in one `Resolve` that share a lookup each run it (AC-1.4).
- **Removed inputs.** A deleted row's column read stores an empty result and falls back to the ghost after the memo (D-2), so a later step reading the same row gets the same ghost (`TestScopeThroughDeletedParent`, `TestReleasedMetadataScopesThroughDeletedOwner`).
- **Real data.** None — no table, seed or configuration drives the memo.
- **Untrusted size.** None — the memo holds the lookups of one change, bounded by its registry paths' fan-out, which is unchanged.
- **Typed nil.** A nil `*sql.Tx` passed as `dbsql.Querier` is a non-nil interface and passes D-4's nil check; no caller passes one (`writes.Run` passes an open `tx.Tx`, tests pass open transactions).

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/effects` `path.go` | `walk.memo`, `memoKey`, `lookup` *(new)* (D-1, D-3); `inbound`, `across`, `sqlPath` return `w.lookup(q, in, fromChange)`; `readRowsColumn` reads through it (D-2) |
| `core/database/effects` `resolve.go` | `func Resolve(q dbsql.Querier, changes []rowchange.Change) (Set, error)`; `Handles` and `resolve` go (D-4) |

Errors: unchanged; a query error returns from `lookup` and is not memoised.

### FFI

None — no wire change.

### macOS

None — engine-only.

### Strings

None — no copy.

## 7. Steps

**STEP-1 — `Resolve` takes a `Querier`; `Handles` goes**
Files: `core/database/effects/resolve.go`; the tests that call `effects.Handles`: `core/database/effects/conclusion_handles_test.go`, `evidence_handles_test.go`, `handle_paths_test.go` (`mustHandles`), `core/database/deleteimpact/facets_test.go`; the four prose lines in Deletes. Skill: `add-catalog-delete` (its line).
Do: D-4.
Check: `rg -n 'effects\.Handles\b|func resolve\(' core docs .agents .cursor` prints nothing; `CGO_ENABLED=1 go build ./... && CGO_ENABLED=1 go test -tags fts5 ./core/database/effects/ ./core/database/deleteimpact/ ./core/writes/ ./core/database/audit/` passes with no expected id edited.

**STEP-2 — One memoised lookup per change**
Files: `core/database/effects/path.go`, `core/database/effects/path_test.go`, `core/database/effects/export_test.go`. Skill: `add-audit-scope`.
Do: D-1, D-2, D-3, D-5; the `path.go` and `countingQuerier` Deletes.
Check: `rg -n 'dbsql.QueryIDs|QueryRow' core/database/effects/path.go` prints one line, inside `lookup`; `CGO_ENABLED=1 go test -tags fts5 ./core/database/...` passes.

**STEP-3 — The counting test**
Files: `core/database/effects/lookup_once_test.go` *(new)*.
Do: T-1 (§8).
Check: `CGO_ENABLED=1 go test -tags fts5 -run TestResolveRunsEachLookupOnce -v ./core/database/effects/` passes. Then, locally only, make `lookup` skip its memo-hit return: the source-date case fails with count 2 and the observation-date case with count 5. Restore it; do not commit that.

**STEP-4 — Docs**
Files: `core/database/effects/README.md`, `docs/deployment-plan/spike-16/deployment-plan.md` (map row), `docs/deployment-plan/spike-16/completed.md`, this plan (status).
Do: in the README, after "Each scope path is walked once per write.", add that a query step reads through `walk.lookup`, which memoises each lookup (query text and id) for the one change being resolved, so paths that share a step run its SQL once, and that a new query step calls `lookup`. Then the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-69-effects-lookup-once.md` reports no errors; links resolve.

Commits: one per behavior. The subject is one full imperative sentence ending in a period, like the rest of `git log` ("Run each effects lookup once per changed row."). No WIP commits.

## 8. Tests

Each T-1 case starts from `tx, userID, _, jones, art := readsFixture(t)`, wraps `log := &effects.QueryLog{Querier: tx.Tx}`, and calls `effects.Resolve(log, …)`. New imports: `core/datevalue/datevaluetest`, `core/valuemark`.

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/effects/lookup_once_test.go` `TestResolveRunsEachLookupOnce` *(new)*, table-driven | **source date:** `_, changes, _ := sources.SetDate(tx, userID, art.SourceID, datevaluetest.YMD(1880, 0, 0), valuemark.Mark{})`; `dateID := only(changes, "date_value")[0].EntityID`; `Resolve` over `only(changes, "date_value")` → `log.Count("FROM sources WHERE date_value_id", dateID) == 1`, `log.Repeats()` empty | AC-1.1, AC-1.3 |
| | | | **observation date:** a Citation in Jones as `TestFirstObservationMovesNoOtherGraph` makes it (`citations.CreateWithObservations`); `placeType := subjecttypes.LookupTx(tx.Tx, "place", vocabkey.OriginProvenencia)`; `subjects.Create(tx, userID, subjects.CreateInput{GraphID: jones.ID, SubjectTypeID: placeType.ID, Label: "York"}, nil)`; `startDate := properties.LookupTx(tx.Tx, "start_date", vocabkey.OriginProvenencia)`; `observations.InsertManyTx(tx.Tx, citationID, []observations.Input{{SubjectID: place.ID, PropertyID: startDate.ID, Date: datevaluetest.YMD(1842, 0, 0)}}, observations.InsertOptions{})`; `dateID := only(obsChanges, "date_value")[0].EntityID`; `Resolve` over `only(obsChanges, "date_value")` → `log.Count("FROM observations WHERE value_date_id", dateID) == 1`, `log.Count("FROM identity_claims WHERE subject_id", place.ID) == 1`, `log.Repeats()` empty | AC-1.2, AC-1.3 |
| | | | **twice in one batch:** the source-date change listed twice in one `Resolve` → `log.Count("FROM sources WHERE date_value_id", dateID) == 2` | AC-1.4, D-3 |
| T-2 | Go | `core/database/effects/path_test.go` `TestReadRowsColumnLooksUpEachIDOnce` (existing; its double becomes `QueryLog`) | four ids, two distinct → `Total() == 2`, output 9s then 8s | D-2, D-5 |
| T-3 | Go | every existing test in `core/database/effects`, `core/database/audit`, `core/writes`, `core/database/evidencegraphs`, `core/database/artifacts`, `core/database/deleteimpact`, the `effects.Handles` callers reading `Resolve(…).Handles` | unchanged expectations → pass | AC-1.5 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `TestScopeThroughDeletedParent` and `TestReleasedMetadataScopesThroughDeletedOwner` (the ghost fallback, D-2), `TestMetadataEffects`, `audit.TestSourceScopes`, `conclusion_handles_test.go` (D-4).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left — none in this PR
- [ ] Sweep: `rg -n 'effects\.Handles\b|countingQuerier|Resolve\(tx \*sql.Tx' .agents/ .cursor/rules/ docs/*.md core/` has no hit; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated — none
- [ ] UI matches the brief inventory — no UI
- [ ] Version bump as the header says — none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated — not gated
- [ ] Domain doc: core/database/effects/README.md names the per-change memo and `lookup` (STEP-4), and `Set.Handles` in place of `effects.Handles` (STEP-1)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

None in the app — nothing a researcher sees changes. The reviewer runs `CGO_ENABLED=1 go test -tags fts5 -run TestResolveRunsEachLookupOnce -v ./core/database/effects/` and reads the three cases' counts, which make bar 39 true.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A memo hit hands a later step a stale result | D-3; T-3 holds every effect |
| A deleted row's empty read is memoised and hides the ghost | D-2; the deleted-parent tests in §8 |
| A caller appends into or writes through a memo entry | D-1 returns a fresh outer slice; every consumer that keeps ids copies them (`appendIDs`, `readRowsColumn`) |

**Stop and report if:**

- Any existing expectation in the packages T-3 names fails after STEP-1 or STEP-2: the change moved an effect, which AC-1.5 forbids.
- `Resolve` or a path step issues a write, or a registry path's query depends on `w.table` or `w.ch` beyond its input id: the memo key in D-3 is then incomplete.
- A T-1 count is more than 1 with the memo in place: a step reads around `lookup` (name the step).
- `readsFixture`'s catalog has no `place` subject type or no `start_date` Property, so the observation-date case cannot be built as §8 says.
- A production caller of `Resolve` must change to compile, or a production caller of `effects.Handles` exists.

## 12. Open questions

None.

## 13. PR

**Title:** S16-69 — A commit runs each effects lookup once
**Body:** objective in one sentence; what shipped against US-1; AC evidence (T-1's counts); deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-69-effects-lookup-once.md`.
