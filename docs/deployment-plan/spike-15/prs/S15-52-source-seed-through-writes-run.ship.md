# Ship log — S15-52 The Source seed writes through `writes.Run`

**Plan:** [`S15-52-source-seed-through-writes-run.md`](S15-52-source-seed-through-writes-run.md) · **Branch:** `s15-52-source-seed-through-writes-run` · **PR:** #891
**State:** ready

## Round 0 — implement
Base `main` @ `4e1a779ae`. Head `0bf6a8e24`. Gate PASS (orchestrator run). Report deviations:
- Steps 1–5 landed in one code commit (`71e54f717`) plus the landing commit, not one commit per step.
- `Upsert`, `sqlUpsert` and `EnsureSuggestion` deleted in the same pass that moved the callers (plan kept them until STEP-5, D-7).
- Added test "a second install does not restore a deleted suggestion" beyond T-4 (covers D-11).
- The remaining "un-audited seed path" note in `core/database/propertyterms/propertyterms.go` stays until S16-62, per plan.

## Round 1 — review
Reviewers: CON, MNT, SEC+PRF. Skipped: UX (no `macos/App/**`, strings, `core/apperr`, or error codes). SEC+PRF routed on `core/database/**` (performance paths); no security path matched, run combined per the rule.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | blocker | Row-map update-diff loop now in three places (`datevalues.UpdateChange`, `sourcetypes.updateChange`, `metadatafields.updateChange`) | Fix now → F-1 | Same-pass cleanup: this PR adds two copies. Verified by body grep `rowchange.FieldDiff{Old: old[k]` / `Old: o,`: exactly those three loops; the other `FieldDiff{Old:` hits are per-field ifs, a different shape. `datevalues.RowMap` always returns the same key set, so a union-of-keys helper does not change its audit output |
| MNT-2 | MNT | major | Create change built twice per package; only `Create`'s carries format diffs | Fix now → F-2 | verified: `sourcetypes.go` `UpsertTx` and `Create` each build the literal; `formatFieldDiffs` not called from `UpsertTx`. Code this PR adds; S15-19 passes formats through `UpsertTx` |
| MNT-3 | MNT | minor | "Install the seed in one `writes.Call`" adapter written four times | Fix now → F-3 | Same-pass cleanup: this PR adds every copy. `sourcevocab_test.go`'s internal `install` stays (import cycle, as D-6) |
| CON-1 | CON | minor | No test pins the seed's search documents after the hand reprojection went | Fix now → F-4 | verified: no test reads the seeded type's search doc; minor in a file this PR changes |

Nits (logged): `MNT-4 · sourcetypes.go:1-3 (+ metadatafields package comment) · "run inside writes.Run" said twice` · `MNT-5 · sourcetypes_test.go:665, metadatafields_test.go:1029 · TestUpsertTx's run repeats the "upsert_*" action literal` · `CON-2 · metadatafields_test.go TestUpsertTx/insert · check keys against Create's change as the sourcetypes twin does` · `CON-3 · sourcevocab_test.go install twice keeps same ids · AC-2.2 also says labels and suggestions unchanged` · `CON-4 · deployment-plan.md:116 · S15-19 row still "Blocked — on S15-52"; flips when this PR merges`

SEC+PRF: no findings.

### Fix plan 1

**F-1 — One update-diff helper in `rowchange`** (from MNT-1)
Files: `core/database/rowchange/change.go`, `core/database/rowchange/README.md`, `core/database/sourcetypes/sourcetypes.go`, `core/database/metadatafields/metadatafields.go`, `core/database/datevalues/datevalues.go`; a test file in `core/database/rowchange`.
Failing test first: `TestUpdatedRow` (table test in `rowchange`): equal maps → empty; a changed key → one diff; a key present only in `now` → diff with Old nil; a key present only in `old` → diff with New nil; a `fixed` key that differs → skipped.
Do: add `UpdatedRow(old, now map[string]any, fixed ...string) map[string]FieldDiff` beside `FullRow` and `DeletedRow` (union of keys, missing key reads nil, skip `fixed`, empty map when nothing differs). Move `sourcetypes.updateChange`, `metadatafields.updateChange` and `datevalues.UpdateChange` onto it (`fixed` = `"id","key","origin"` for the two vocab tables, `"id"` for date values). Keep each wrapper's nil-when-empty return and entity fields. Add one sentence on `UpdatedRow` to the README's paragraph that names `FullRow` and `DeletedRow`.
Check: `grep -rnE "FieldDiff\{Old: (old\[k\]|o)," core api` prints only `core/database/rowchange/change.go`; existing `datevalues`, `sourcetypes`, `metadatafields` tests pass unchanged; scripts/check-pr.sh PASS.

**F-2 — One create-change builder per package** (from MNT-2)
Files: `core/database/sourcetypes/sourcetypes.go`, `core/database/metadatafields/metadatafields.go`.
Failing test first: none (refactor; existing `TestUpsertTx` and `Create` tests pin the output).
Do: add `createChange(t Type, formats Formats) rowchange.Change` in `sourcetypes` (`FullRow(rowFields(t))` plus `formatFieldDiffs(Formats{}, formats)`) and `createChange(f Field) rowchange.Change` in `metadatafields`, following `datevalues.CreateChange`. Call them from both `Create` and `UpsertTx`; `UpsertTx` passes `Formats{}` today.
Check: `grep -n "ActionCreate" core/database/sourcetypes/sourcetypes.go core/database/metadatafields/metadatafields.go` prints one line per package (inside `createChange`); tests pass; scripts/check-pr.sh PASS.

**F-3 — `sourcevocabtest.Install`** (from MNT-3)
Files: new `core/database/sourcevocab/sourcevocabtest/sourcevocabtest.go`; `core/database/evidencegraphs/evidencegraphstest/evidencegraphstest.go`; `core/database/sourcemetadata/sourcemetadata_test.go`.
Failing test first: none (test helper).
Do: add `Install(c *database.Catalog) error` running `sourcevocab.Install(tx)` in one `writes.Call` with `sourcevocab.ActionInstall`, following `sourcetypestest`. Use it from `evidencegraphstest` and `sourcemetadata_test`. `core/onboarding/ready.go` keeps its own call (product code does not import a `*test` package); `sourcevocab_test.go` keeps its local `install` (import cycle, as D-6).
Check: `grep -rn "ActionInstall" core --include='*.go'` (or `grep -rn "ActionInstall" core`) prints only `sourcevocab.go`, `sourcevocabtest.go`, `onboarding/ready.go`, and `sourcevocab_test.go`; tests pass.

**F-4 — Pin the seed's search documents** (from CON-1)
Files: `core/database/sourcevocab/sourcevocab_test.go`.
Failing test first: n/a (guard; passes today).
Do: in `TestInstall/install records one revision`, assert `catalog_search_docs` holds one `source_type` and three `metadata_field` documents after Install.
Check: test passes; scripts/check-pr.sh PASS.

Nits may ride along at the implementer's discretion (MNT-4, CON-2, CON-3); none is required.

## Round 1 — fix
Head `6b37155a4`. Gate PASS (orchestrator run). F-1 and F-2 in `bf0096c67` (same files); F-3 `be5f18aab`; F-4 `6b37155a4`. Nits not taken. The implementer left the checkout on a detached HEAD at the pushed tip; the orchestrator put the local branch back on it.
- CON-1 (minor): **Resolved** — read by the orchestrator: `TestInstall/install records one revision` asserts `catalog_search_docs` has exactly 1 `source_type` and 3 `metadata_field` documents.
- MNT-3 (minor): goes with MNT-1/MNT-2 to the round-2 maintainability reviewer.

## Round 2 — review
Reviewers: MNT (had a Fix-now blocker and major). Not sent: CON (only a minor, resolved above), SEC+PRF (no findings).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | blocker | (round 1) | Resolved | `rowchange.UpdatedRow`; all three callers on it; grep check prints only `rowchange/change.go` |
| MNT-2 | MNT | major | (round 1) | Resolved | one `createChange` per package; `ActionCreate` once per package |
| MNT-3 | MNT | minor | (round 1) | Resolved | `sourcevocabtest.Install`; `ActionInstall` grep prints only the expected sites |

No new findings. No Fix plan 2.

## Result
Gate PASS (head `6b37155a4`; `main` unchanged at `4e1a779ae`, no merge needed) · CI pending · open: none · follow-ups: none · to user: — · nits logged: MNT-4, MNT-5, CON-2, CON-3, CON-4
