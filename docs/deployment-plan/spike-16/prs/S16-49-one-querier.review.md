# Review — S16-49 One read querier and one write querier for every catalog package

**Verdict:** round 1: Fits with changes — Ready with changes. Round 2: pending.
**Rounds:** 1 (round 2 pending). **Reviewers:** maintainability (Opus), executability (Sonnet)

## To user

- **M-1 · The IN-list rule in `add-catalog-query`.** Answered (user, 2026-11-19): the user asked which option is more robust and maintainable long-term. The writer recommended naming the two bounded exceptions (`graphcache`'s loads over one `sqlbatch.Each` chunk; `core/search`'s member count over one page of hits) and the bound any new list needs, so the skill describes the code and `fts.go` uses the shared helper. Taken: D-10 part 2, **Rules this plan bends**.
- **M-4 · Fold the `Scan` copies into S16-49.** Answered (user, 2026-11-19): fold in. D-2, D-3, D-12; STEP-6; the map scope entry's "Not this PR" line changes.
- **`blobArgs` and `uniqueIDs` (planning).** Answered (user, 2026-11-19): `blobArgs` moves, `uniqueIDs` stays.

## Writer's own calls

- D-1: the leaf package is `dbsql`.
- D-5: a function typed with a write copy that never calls `Exec` takes `Querier` (from M-2); subsets widen to `Querier`.
- D-6: `sqlbatch`'s inline placeholder build is a third copy and goes.
- D-7: `autoreconciler`'s read functions narrow to `Querier`, deleting `rowQuerier`.
- D-13 (from M-5): `database.NullInt(p *int) any` replaces `datevalues.nullInt`; the scan-side `intPtr`/`nullIntPtr` pair is Out.
- D-14 (from M-8): `LoadQueryCount` counts through `graphcache.Over`.
- D-15 (from M-3): a guard test in `dbsql` refuses a local querier or scanner.

## Round 1

### M-1 · blocker · D-11 adds a hand-built by-id IN list, which the skill forbids
`add-catalog-query` line 41 forbids a hand-built `SQLInPlaceholders` list; `fts.go` and `graphcache/load.go` are both that pattern.
**Answer:** To user → answered (above). D-10 part 2 rewrites the line with the two exceptions and the bound; **Rules this plan bends** records it.

### M-2 · blocker · `searchindex`'s read functions stay on `Execer`, contradicting D-10's sentence
Nine `searchindex` functions never call `Exec`.
**Answer:** Fixed — D-5 and STEP-3: the nine take `database.Querier`; the Out row is gone. §4 lists them.

### M-3 · major · The rule lives only in prose and a one-time `rg`
**Answer:** Fixed — D-15, T-6, T-7, STEP-8; AC-1.6.

### M-4 · major · Nineteen `Scan(dest ...any) error` copies stay
**Answer:** To user → fold in (above). D-12, STEP-6, AC-1.5; the guard covers `Scan`.

### M-5 · major · `datevalues.nullInt` stays beside `database.NullInt64`
**Answer:** Fixed — D-13, T-5, STEP-7. The scan-side pair is Out, not planned (a decoder, two copies).

### M-6 · minor · One function, two names (`SQLInPlaceholders` / `InPlaceholders`)
**Answer:** Fixed — D-3, D-6: `dbsql.SQLInPlaceholders`.

### M-7 · minor · `Execer` reads as Exec-only
**Answer:** Declined — the working rule (user, 2026-11-17) names `Execer`; the only Exec-only `execer` in the repo (`graphcachetest`) is deleted here; D-2's doc comment states the surface.

### M-8 · minor · `autoreconciler`'s `countingQuerier` copies the graph's counter
**Answer:** Fixed — D-14; a stop condition pins the count.

### M-9 · nit · `dbtest` gains a `core/database` import for a parameter type
**Answer:** Fixed — D-4: `dbtest` uses `dbsql.Querier`.

### X-1 · major · AC-1.1 / AC-1.2 commands match nothing as written (`\|` in a table)
**Answer:** Fixed — C-1, C-2 (and C-3) in code blocks in §2.

### X-2 · minor · Current state rows not true
**Answer:** Fixed — `conclusionsummaries.Querier` is unused: deleted, nothing to retype; counts dropped. Declined on the planning base: `origin/main` has no commit after `31d9902` (the reviewer's local `main` was stale).

### X-3 · major · The skill already forbids what D-6 and D-11 add
**Answer:** Fixed — same as M-1.

### X-4 · minor · Small choices left open
**Answer:** Fixed — the `effects` literal, imports added and removed (§7 preamble), test package `dbsql`, T-3 comparison, the STEP-3 check's interim hit.

### X-5 · minor · `check-pr.sh` cannot print PASS off macOS
**Answer:** Fixed — DoD and STEP-8 accept `FAIL xcode-test (needs macOS)` with no other failure.

### X-6 · minor · Map text goes stale
**Answer:** Fixed — STEP-9 names the row text and bar 24's wording.

### X-7 · nit · Overlap with S16-54 on `dbtest.go`
**Answer:** Fixed — a Risks row.
