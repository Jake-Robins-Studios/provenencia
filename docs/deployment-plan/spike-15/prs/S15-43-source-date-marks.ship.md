# Ship log — S15-43 The Source date can be marked unknown or supplied

**Plan:** [`S15-43-source-date-marks.md`](S15-43-source-date-marks.md) · **Branch:** `s15-43-source-date-marks` · **PR:** #900
**State:** ready

## Round 0 — implement
Head `8444750fd`. Gate PASS (orchestrator re-ran: all 9 checks). Report deviations: `List` scans `has_artifact` into a local and sets it on the returned Source (D-2's `&s.HasArtifact` cannot work since `scanSource` returns a new Source; noted in the Landed note); `engine.pb.swift` diff is large because the generator switched `Source` to storage-backed accessors; manual check (§ 10) not run. VERSION 0.24.1 → 0.25.0 (main was 0.24.1).

## Round 1 — review
Reviewers: CON, MNT, SEC+PRF. Skipped: UX (the only `macos/App/**` file is the generated `engine.pb.swift`; no strings, no `Localizable.xcstrings`, no new error codes).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| SEC-1 | SEC | major (re-rated from blocker) | `settleDate` passes a stored `{Unknown}` or `{Unknown, Supplied}` through when the date row exists | Fix now → F-1 | verified: `sources.go:623` returns `stored` unchanged when the date is found; D-3's own reason is "a read must never carry a pair `valuemark.Validate` refuses". Reviewer's overlay probe read `{Unknown:true Supplied:true}` after `ignore_check_constraints`. Rated major: only a crafted catalog reaches it, and the result is a refused Copy Source, not lost data. Fix fulfils D-3 (no Decision change): with a date, the read clears `Unknown` |
| CON-1 | CON | minor | Step table checks `date_value_id` by key only, not old → new | Fix now → F-2 | verified: step loop does `_, idMoved := ch.Fields["date_value_id"]` |
| MNT-1 | MNT | minor | Three copies of the pinned-connection pragma fixture, plus `autoreconciler_test.go`'s `damage` | Fix now → F-3 (same-pass cleanup) | verified: `grep -rniE "foreign_keys *= *(OFF\|0)\|ignore_check_constraints" --include='*_test.go' core api` prints `sourcecopy_test.go:798`, `sources_test.go:1158`, `sources_test.go:1327`, `autoreconciler_test.go:2051`; F-1's test would be a fifth |
| MNT-2 | MNT | minor | `TestSourceDate`'s `set` and the delete-change capture repeat `runSetDateChanges` / a capture block | Fix now → F-4 | minor in a file this PR changes |
| SEC-2 | SEC | minor | The phrase cap bounds writes only; a crafted long phrase still reads | Rejected | D-9 decides "Reads do not validate, so a stored long phrase still reads"; the write cap is the one high cap ([[caps-for-adversarial-only]]); the read is bounded by SQLite's blob limit and the row count |
| SEC-3 (outside-lens note) | SEC | minor | `sourcemetadata.go:1024` (S15-37) reads its stored pair from a crafted row unsettled, same class as SEC-1 | Follow-up | code this PR does not add or change |

Nits (logged): `CON-2 · api/ffi/handlers/sources_test.go TestSetSourceDate/marks · check no date_mark on a read after the last write` · `CON-3 · core/database/sourcecopy/sourcecopy_test.go "a stored phrase over the cap is refused" · also count date_values` · `MNT-3 · core/database/sources/sources_test.go:1493 · use dbtest.Revisions` · `MNT-4 · core/database/sources/sources.go:332 · dateChange and sourcemetadata.updateValueTx both diff the pair; extract when a third column pair appears` · `MNT-5 · api/ffi/handlers/sources_test.go:1129 · variadic mark stands in for an optional argument`

### Fix plan 1

**F-1 — A read never carries a date marked unknown** (from SEC-1)
Files: `core/database/sources/sources.go`, `core/database/sources/sources_test.go`.
Failing test first: `TestSourceDateMarks/"a damaged unknown mark on a dated source reads supplied"` (or a table of damaged pairs): set a Source dated 1880 and supplied, then `dbtest.Damage` (F-3) `UPDATE sources SET date_unknown = 1 WHERE id = ?`; assert `Get` and `List` read `DateMark == valuemark.Mark{Supplied: true}` with the date, and a second case from a dated, unmarked Source damaged to `date_unknown = 1` reads the zero mark. Then Copy Source of the damaged Source (`sourcecopy` test, Date tick on) succeeds and the copy carries `{Supplied: true}` for the first case.
Do: in `settleDate`, when the date is found, return `stored` with `Unknown` cleared; when not found, keep clearing `Supplied`. Update its doc comment and D-3's wording in the plan's Landed note ("the read clears Unknown when the date row exists"). `storedDateMark` stays raw.
Check: the test passes; `scripts/check-pr.sh` PASS.

**F-2 — Assert `date_value_id` old → new in the step table** (from CON-1)
Files: `core/database/sources/sources_test.go`.
Do: in `TestSourceDateMarks`'s step loop, "dated to unknown" asserts `ch.Fields["date_value_id"]` equals `{Old: database.UUIDJSON(<prior id>), New: nil}`; "unknown to supplied date" asserts `{Old: nil, New: database.UUIDJSON(got.DateValueID)}`. Take the prior id from the step before.
Check: run it once red by breaking the expected value, then green.

**F-3 — One `dbtest.Damage` helper for writes the schema would refuse** (from MNT-1; same-pass cleanup)
Files: `core/database/dbtest/dbtest.go`, `core/database/sources/sources_test.go`, `core/database/sourcecopy/sourcecopy_test.go`, `core/database/autoreconciler/autoreconciler_test.go`.
Do: add `func Damage(t testing.TB, db *sql.DB, query string, args ...any)`: pins one connection with `db.Conn`, sets `PRAGMA foreign_keys=OFF` and `PRAGMA ignore_check_constraints=ON`, runs the statement, restores both pragmas, and closes the connection before returning (the catalog holds one connection). Doc comment: "Damage runs one statement the schema would refuse, as a crafted or damaged catalog holds it." Move onto it: `dangleDate` (sources_test.go ~1317; keep `dangleDate` as a one-line wrapper or inline it), `TestSourceDate`'s `dangle` (~1150), `sourcecopy_test.go` "date row missing" (~789), `autoreconciler_test.go`'s `damage` closure (~2046), and F-1's new test.
Check: `grep -rniE "foreign_keys *= *(OFF|0)|ignore_check_constraints" --include='*_test.go' core api | grep -v migrate_test` prints nothing; `grep -rn "PRAGMA" core/database/dbtest` prints only `Damage`'s lines; all four packages' tests pass.

**F-4 — One capture helper per write in `sources_test.go`** (from MNT-2)
Files: `core/database/sources/sources_test.go`.
Do: point `TestSourceDate`'s `set` closure at `runSetDateChanges`. Add `runDeleteChanges` beside `runDelete` (line ~51) returning the changes; "dated source releases its date" and "a date mark is in the delete change" both use it; `runDelete` calls it and drops the changes.
Check: `go test ./core/database/sources/` passes; scripts/check-pr.sh PASS.

## Round 1 — fix
Head `131eda959`. Gate PASS (orchestrator re-ran). F-1 done (both new tests red first: `Get` read `{Unknown:true}`; Copy Source failed `valuemark.invalid`); F-2 done (red by a wrong expected `New`); F-3 done (grep prints nothing; `dbtest.Damage` restores both pragmas even when the statement fails); F-4 done. One commit for all four (they share `sources_test.go`). Landed note and `completed.md` gain one clause; no Decision text edited.

Minors checked by the orchestrator (no round-2 reviewer):
- CON-1 → **Resolved**: `sources_test.go:1400-1408` compares `date_value_id` to `{Old: UUIDJSON(prevID), New: nil}` and `{Old: nil, New: UUIDJSON(got.DateValueID)}`.
- MNT-1 → **Resolved**: one `dbtest.Damage` (`dbtest.go`); the pragma grep over `*_test.go` (minus `migrate_test`) prints nothing; `autoreconciler_test.go` moved onto it.
- MNT-2 → **Resolved**: `runDeleteChanges` beside `runDelete` (line 55), used by three delete subtests; `TestSourceDate`'s `set` calls `runSetDateChanges` (line 1034).

## Round 2 — review
Reviewers: SEC+PRF (SEC-1 was a Fix-now major). Skipped: CON, MNT (minors only; checked above). Scope `8444750fd...131eda959`.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| SEC-1 (re-check) | SEC | — | `settleDate` clears `Unknown` when the date row exists | Resolved | `sources.go:624-633`; every read mark is now a pair `valuemark.Validate` accepts; `Get`, `List` and Copy Source covered by the new tests |

No new findings. Verdict: Clean.

## Result
Gate PASS · CI green (test ×2, localizable) · open: none · follow-ups: SEC-3 (S15-37's `sourcemetadata` reads its stored pair unsettled, same class as SEC-1) · to user: —
