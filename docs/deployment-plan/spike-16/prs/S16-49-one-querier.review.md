# Review — S16-49 One read querier and one write querier for every catalog package

**Verdict:** Fits with changes — Ready with changes (both rounds); no blocker open.
**Rounds:** 2. **Reviewers:** maintainability (Opus), executability (Sonnet)

## To user

- **M-1 · The IN-list rule in `add-catalog-query`.** Answered (user, 2026-11-19): the user asked which option is more robust and maintainable long-term. The writer recommended naming the two bounded exceptions (`graphcache`'s loads over one `sqlbatch.Each` chunk; `core/search`'s member count over one page of hits) and the bound any new list needs, so the skill describes the code and `fts.go` uses the shared helper. Taken: D-10 part 2, **Rules this plan bends**.
- **M-4 · Fold the `Scan` copies into S16-49.** Answered (user, 2026-11-19): fold in. D-2, D-3, D-12; STEP-6; the map scope entry's "Not this PR" line changes.
- **`blobArgs` and `uniqueIDs` (planning).** Answered (user, 2026-11-19): `blobArgs` moves, `uniqueIDs` stays.

- **M-10 · The IN-list rule, corrected.** Round 1's answer rested on a count of two hand-built lists; there are eight. Answered again (user, 2026-11-19), after a plain explanation with examples: the rule is a condition (a hand-built list only over a set already bounded, its function comment naming the bound); the bounded ones stay; the test-only `Verify` one is fine; the unbounded delete query (`deleteimpact.handleGoesWithout`) is fixed. The writer put that fix in its own map row, S16-63, so S16-49 stays a no-behaviour change; the user can move it into S16-49.

## Writer's own calls

- S16-63 as its own PR rather than inside S16-49 (above).
- D-16: every bounded hand-built list gets a comment naming its bound in this PR, so D-10's rule is true on landing.
- D-15: `begin_test.go`'s walk is fixed in this PR (one line), with a zero-files check in both guards.

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

## Round 2

The round-1 answers held against the code (both reviewers: an AST pass with D-15's rule finds exactly §4's 39 interfaces; every scanner package already imports `core/database`; D-14's counter counts the same statements).

### M-10 · blocker · D-10 part 2 names two hand-built lists; there are eight
**Answer:** To user → answered (above). D-10 part 2 is a condition; §4's Skill row lists the eight; D-16 adds the bound comments; **Rules this plan bends** updated; the unbounded one is S16-63.

### M-11 · blocker · The guard walk copied from `begin_test.go` skips its own root and checks nothing
Verified: `begin_test.go` walks from `../..`, whose name starts with `.`, so `WalkDir` skips it.
**Answer:** Fixed — D-15 walks `core` and `api` by name, skips dot directories only below the root, fails on zero files; `begin_test.go` gets the same fix (T-8); a Known traps line in `maintainability.md`.

### X-8 · major · The map's scope entry contradicts the plan
**Answer:** Fixed — the scope entry, the map row and the Batch 6 rule were updated at planning time; STEP-9 says so.

### X-9 · major · "over one `sqlbatch.Each` chunk" is false for test-only `Verify`
**Answer:** Fixed — same as M-10; §4 and D-16 name `Verify`.

### X-10 · minor · The `LoadQueryCount` stop condition has no baseline
**Answer:** Fixed — STEP-4 records the counts for 1 and 60 handles before editing.

### X-11 · minor · `searchindex` `export_test.go` wrappers get no type
**Answer:** Fixed — D-8 names them, `database.Querier`.

### X-12 · minor · D-4 omits `core/database`; `dbtest.Count` listed in STEP-5
**Answer:** Fixed — D-4 and §3.

### X-13 · minor · `\|` still in AC-1.3 and AC-2.3
**Answer:** Fixed — C-4 and C-5 in code blocks.

### X-14 · minor · D-15's walk shape open
**Answer:** Fixed — with M-11.

### X-15 · minor · Two §4 counts did not reproduce
**Answer:** Fixed — counts dropped.
