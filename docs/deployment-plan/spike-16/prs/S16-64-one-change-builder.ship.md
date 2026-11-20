# Ship log — S16-64 One change builder and one change-only write call

**Plan:** [`S16-64-one-change-builder.md`](S16-64-one-change-builder.md) · **Branch:** `s16-64-one-change-builder` · **PR:** #920
**State:** ready

## Round 0 — implement
Base `main` @ `34c2b615`. Dispatched pr-implementer.
Head `d80369bb`. PR #920 (draft). Report deviations: (1) `sourcecopy_test.go` `writeOne` stays generic (five of six callers return a value); its one `struct{}` caller calls `writes.RunChanges` directly; (2) STEP-7 `rg UpdatedRow` also matches the unrelated `CatalogLastUpdatedRow` in `add-workspace-place`, left alone; (3) a comment in `deleteimpact/facets.go` now names `rowchange.Deleted`; (4) `TestBuilders` also round-trips each change through JSON for null columns; (5) `main` at `34c2b615` vs plan's `ff82a70`, no Current-state row changed, counts held (210, 43); (6) first three commits lack the Co-Authored-By trailer.
Gate (orchestrator) PASS on `d80369bb`: diff-check, gofmt, go-vet, go-test, localizable, guidance-names, plan-docs, xcode-test, swift-warnings.

## Round 1 — review
Reviewers: CON, MNT, SEC+PRF. Skipped: UX (no `macos/App/**`, strings, `core/apperr`, or error codes). SEC+PRF for `api/ffi/**`, `core/ingest`, `core/derivatives` (security) and `core/database/**` (performance).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | major | Field-by-field update diffs still sit beside `rowchange.Updated` in files this PR edits | Fix now → F-1 | verified: `subjects.Update` (subjects.go:173–192) and `artifacts.Update` (artifacts.go:185–209) compare each column with `!=` / `bytes.Equal` on the values they record and return nil when nothing differs, which is `updatedRow`'s rule. Same-pass cleanup: this PR changes the helper these copies duplicate and edits their files; the plan's Out line 1 recorded the debt and is superseded for the column-map-shaped sites. Audit JSON stays key for key, so nothing a researcher sees changes and no user call is needed |
| MNT-2, CON-2 | MNT, CON | minor | `RunChanges` doc and `core/writes/README.md` name `Run` for the reentry check, logging and session lock that now live in `RunChanges` | Fix now → F-2 | verified: `core/writes/run.go:34–35`, README lines 11, 13 |

Nits (logged): `MNT-3 · core/writes/run_test.go:56 · TestRunChanges rows repeat TestRunRollsBack / TestRunSkipsEmptyChanges` · `MNT-4 · core/writes/run.go:25 · Result doc says "the commit Run recorded"` · `CON-1 · core/writes/run_test.go:87 · compare the error/no-change Result with writes.Result{} whole`
SEC+PRF: no findings.

### Fix plan 1
Supersedes plan §3 Out line 1 for the update literals whose fields are a column-by-column `!=` diff; record that in the plan's Landed note.

**F-1 — Column-map update diffs move onto `rowchange.Updated`** (from MNT-1)
Files: `core/database/subjects/subjects.go` (`Update`), `core/database/artifacts/artifacts.go` (update), `core/database/evidencegraphs/evidencegraphs.go` (~275–292), `core/database/citations/citations.go` (~355–416), `core/database/sources/notes.go` (`UpdateNote`, ~123–136), `core/database/sourcemetadata/sourcemetadata.go` (value update, ~227–242), `core/ingest/file.go` (filename update, ~247–260). Also check `sources/sources.go` lines ~263, 348, 370, 439, `ingest/file.go` ~295 and `canonicalentities.go` ~295 against the same test and move each that passes. Skill: `add-audit-scope`.
The test for a site: every field is `if <old> != <new> { fields[k] = FieldDiff{Old: f(old), New: f(new)} }` (or `bytes.Equal` on ids recorded as `UUIDJSON`), with `f` returning only comparable values (string, number, bool, nil), and the change is dropped when no field differs. A site that records a column whether or not it changed, compares something other than what it records in a way `!=` on the recorded values would not reproduce, or holds a slice/map value, stays. Known stays: `namevalues.UpdateChange` (D-10), `sources` cover/date (`dateChange`, always records `cover_mode`), `subjectpositions` update branch, `observations.observationUpdateChange`, `subjectvocab.bindingOrderChange`, `sourcemetadata.layoutChange`, `sourcecredibility/assessments.go`, the `deleteimpact/facets.go` re-point.
Failing test first: none (behavior-preserving); the existing package tests that assert each update's audit fields are the check, and no `want` may change.
Do: build `old` / `now` `map[string]any` over the compared columns with the same value functions (`database.NullString`, `database.UUIDJSON`, raw value where the literal used raw), call `rowchange.Updated("<entity>", id, old, now)`, and gate any `tx.Exec` that today runs only when `len(fields) > 0` on the change being non-nil. Keep the same entity type string and id.
Check: `go test -tags fts5 ./api/... ./core/...` passes; `git diff d80369bb -- '*_test.go' | grep -E '^[-+].*want'` prints nothing; `rg -n "rowchange\.ActionUpdate" core --glob '!*_test.go'` lists only `dbtest/audit.go`, `audit/audit.go`, `effects/registry.go`, `sourcecredibility/assessments.go`, `sourcemetadata.go` layout lines, and the known stays above (report the final list with one reason per remaining line); scripts/check-pr.sh PASS.

**F-2 — `RunChanges` owns its doc** (from MNT-2, CON-2; riding nits MNT-4, CON-1 optional)
Files: `core/writes/run.go`, `core/writes/README.md`.
Do: the `RunChanges` comment says "A second write (`Run` or `RunChanges`) on the same catalog … returns database.ErrWriteReentry" and "`RunChanges` does not take the catalog session lock"; README lines 11, 13 likewise ("a second write", "`RunChanges` logs that error"). The `Result` doc names `RunChanges`.
Check: `rg -n "A second .Run|.Run. logs|.Run. does not take" core/writes` prints nothing; scripts/check-pr.sh PASS.

## Round 1 — fix
Head `076b3a8c`. Gate (orchestrator) PASS on `076b3a8c` (all nine checks). F-1 done (`bffa287b`): moved `subjects.Update`, `artifacts.Update`, the `evidencegraphs` update, `citations.Update`, `sources.Update`, `sources.SetPublic`, `sources.dateChange`, `sources.UpdateNote`, `sourcemetadata.updateValueTx`, the `canonicalentities` preferred likeness and `ingest.SetFilename`; no test `want` changed. Stays with reasons: `sources.SetCover` (always records `cover_mode`), `ingest.recordReuse` (records `ingested_as` unconditionally), and the known stays. Deviation: `dateChange` was on the known-stay list but passes the F-1 test (records only differing columns, nil when none), so it moved. F-2 done (`5533c1d4`), also MNT-4; CON-1 skipped (optional nit). MNT-2/CON-2 **Resolved** (orchestrator read the F-2 diff).

## Round 2 — review
Reviewers: MNT (round 1 had a Fix-now major). Not sent: CON, SEC+PRF (no Fix-now blocker or major). Scope: `d80369bb...076b3a8c`.
Verdict: Clean. MNT-1 **Resolved** (`bffa287b` moves eleven update diffs onto `rowchange.Updated`; every remaining `ActionUpdate` literal has a recorded reason). No new blockers. No Fix plan 2.

Nits (logged): `MNT-5 · core/database/sources/sources.go:351 · SetPublic dereferences *change relying on the earlier equality check; gate on change == nil instead` · `MNT-6 · core/database/canonicalentities/canonicalentities.go:286-295 · same for SetPreferredLikeness`

## Result
Gate PASS on `076b3a8c` (`origin/main` unchanged at `34c2b615`, no merge needed) · CI see PR #920 · open: none · follow-ups: none · to user: —
