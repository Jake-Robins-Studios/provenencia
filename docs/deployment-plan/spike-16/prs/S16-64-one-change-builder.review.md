# Review — S16-64 One change builder and one change-only write call

**Verdict:** Fits with changes — Ready with changes (round 2); every blocker Fixed
**Rounds:** 2. **Reviewers:** maintainability (Opus), executability (Sonnet)

## To user

None.

## Writer's own calls

- **`writes.RunChanges` returns `(Result, error)`** (D-5), not the `error` the map sketched: the FFI handlers read the `Result` (`writeEffectsProto(wrote)`). `RunChanges` holds today's body of `Run`, and `Run[T]` wraps it, so no `struct{}` adaptor is left, `core/writes` included.
- **The sweep is wider than the map's list** (D-2, D-6, D-11): every `FullRow` / `UpdatedRow` / `DeletedRow` literal, every hand-written full-row create or delete literal, and all 210 `struct{}` closures, not only the nine packages and the 127 exact adaptors. The map's scope entry and bar 36 were updated in planning.
- **`sourcetypes` keeps two private wrappers** (D-4) for its format columns.
- **Entity names and fixed keys stay literal at each call site** (D-3): no per-package constant.

## Round 1

### X-1 · blocker · `namevalues.UpdateChange` is not a column-map diff; the planned `Updated` call panics
`RowMap`'s `parts` is a `[]map[string]any`; `updatedRow` compares with `!=`.
**Answer:** Fixed — D-10 *(new)*: `namevalues.UpdateChange` stays hand-built (Out); only `CreateChange` moves. §3, §4, §6 Go core, Deletes, Edges, STEP-2 and STEP-7 checks updated.

### X-2 · major · AC-2.4 contradicts D-5's adaptor inside `writes`
**Answer:** Fixed — D-5 reshaped before the finding arrived: `RunChanges` holds `Run`'s body and `Run` wraps it with a value-capturing closure, so no `struct{}` closure exists in `core/writes`. AC-2.4 points at STEP-6's two `rg` commands, which include `core/writes`.

### X-3 · major · D-3 gives the wrong fixed keys for `propertyterms`
**Answer:** Fixed — D-3 lists each package's fixed keys; `propertyterms` is `"id", "property_id", "key", "origin"`. §4 row and §6 updated.

### X-4 · minor · README paragraph positions are off
**Answer:** Fixed — STEP-3, STEP-4 name each paragraph by its first words.

### X-5 · minor · AC-1.6 / AC-2.4 `rg` with `\|` in a table cell
**Answer:** Fixed — the ACs point at the STEP-3 and STEP-6 check commands.

### X-6 · minor · Xcode leg cannot run on Linux
**Answer:** Fixed — the DoD line says the Xcode leg is skipped on Linux and CI runs it; no Swift file changes.

### X-7 · minor · Open choices (T-2 assertions, `release.go` local, other helpers' returns, STEP-6 size)
**Answer:** Fixed — T-2 names `recListener` and `SELECT COUNT(*) FROM audit_transactions`; §6 gives `release.go`'s two lines; STEP-6 says other helpers keep their return types and runs each package's tests as it goes.

### M-1 · blocker · About nine full-row create/delete literals stay hand-built beside `Created` / `Deleted`
`sources` (create, delete), notes (create, delete), `artifacts` (create, delete), `subjects` (delete), `ingest` (file create), `derivatives` (`fileDerivativeChange`).
**Answer:** Fixed — D-11 *(new)* moves every literal whose every field is `{Old: nil, New: v}` or `{Old: v, New: nil}`; AC-1.8 *(new)* lists the mixed literals that stay (`sourcemetadata`, `sourcecredibility` assessments, the `deleteimpact/facets.go` re-point). The Out row no longer names `derivatives`. AC-1.7 adds `sources`, `artifacts`, `ingest`, `derivatives`. STEP-3 does it.

### M-2 · major · `add-catalog-query` line 46 and `core/writes/README.md` contradict the new path
**Answer:** Fixed — STEP-7 replaces line 46's `audit.Record` sentence, rewords the README's last paragraph ("`Run` or `RunChanges`"); STEP-4 drops "(or nothing, for a delete)"; STEP-7's check `rg`s both old phrases.

### M-3 · minor · D-3's fixed keys disagree with `propertyterms`
**Answer:** Fixed — with X-3. The per-package `fixedColumns` variable is declined: at most two `Updated` calls per package, and D-3 keeps the scaffolding the map's "keeps only its rowFields" excludes.

### M-4 · minor · `Apply` already names a cache entry's commit step and `sourcemetadata.Apply`
**Answer:** Fixed — renamed `writes.RunChanges` throughout the plan, the map row, its scope entry and S16-62's "Not this PR" line.

### M-5 · nit · Test helpers that return the changes as their value
**Answer:** Logged — legitimate uses of `Run`'s value; not this PR.

## Round 2

### X-8 · minor · STEP-7 leaves `add-seeded-vocabulary` line 95 naming `writes.Call`
**Answer:** Fixed — STEP-7 names lines 89 and 95; its check adds `rg -n "writes\.Call" .agents .cursor` (no hit).

### X-9 · nit · D-5 typo
**Answer:** Fixed.

### M-6 · blocker · `subjectpositions` builds a full-row create spelled `{New: v}`, outside D-11 and AC-1.8's regex
**Answer:** Fixed — D-11 adds the create branch of `core/database/subjectpositions/subjectpositions.go` (an early `rowchange.Created` return; the update literal stays). AC-1.8's regex is `\{(Old: nil, )?New:|New: nil\}`; AC-1.7 and STEP-3's check add `subjectpositions`.

### M-7 · blocker · Test fixtures that pass a bare field map have no rule once the helpers are private
**Answer:** Fixed — D-12 *(new)*: create and delete fixture rows in `effects/lists_test.go` call `Created` / `Deleted` directly (wants unchanged), `path_test.go`'s `del` becomes `Deleted`, and `audit_test.go`'s two null-key cases move into T-1.

### Below blocker · the `sourcetypes` delete merges format diffs
**Answer:** Fixed — §6 gives its two lines.

### Below blocker · T-2 repeats the converted `run_test.go` cases
**Answer:** Declined — T-2 states `RunChanges`' contract (AC-2.1 – AC-2.3) in one table; the converted tests keep testing their own cases. Cost is one short table.
