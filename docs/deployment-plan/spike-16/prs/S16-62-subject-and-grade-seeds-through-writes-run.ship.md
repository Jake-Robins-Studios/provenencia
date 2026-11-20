# Ship log — S16-62 The subject and grade seeds write through `writes.Run`

**Plan:** [`S16-62-subject-and-grade-seeds-through-writes-run.md`](S16-62-subject-and-grade-seeds-through-writes-run.md) · **Branch:** `s16-62-subject-and-grade-seeds-through-writes-run` · **PR:** #912
**State:** ready

## Round 0 — implement
Base `main` @ `ef66e216`. Dispatched pr-implementer.
Head `3ffab590`. PR #912 (draft). Report deviations: (1) T-5/T-6 are separate test functions (`TestEnsureBindingTx`, `TestInstallRecordsOneRevision`, `TestInstallFailureLeavesNothing`) rather than a case in `TestBindingChanges`; (2) T-7 is new `TestCreateUpdateDeleteChanges` / `TestChangeKeys`; (3) no D-11 delta needed, no revision-count test changed; (4) code and tests landed in one commit (no buildable intermediate state where old and new coexist), noted in the plan's Landed note; (5) `main` at `ef66e216` vs plan's `ca6790b`, no Current-state row changed; (6) §10 manual check not run.
Gate (orchestrator) PASS on `3ffab590`: diff-check, gofmt, go-vet, go-test, localizable, guidance-names, plan-docs, xcode-test, swift-warnings.

## Round 1 — review
Reviewers: CON, MNT, SEC+PRF. Skipped: UX (no `macos/App/**`, strings, `core/apperr`, or error codes). SEC+PRF for `core/database/**` (performance) and `api/ffi/**` tests (security).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | major | `add-seeded-vocabulary` skill says an all-`None` domain keeps `Install(c) error`, but grades (all `None`) now use `Install(tx)` | Fix now → F-1 | verified: SKILL.md:21 and step 3 (:146) vs `sourcecredibilitygrades.Install(tx)` run through `installSeed` (`ready.go`); `source_credibility_grades` is `None` in `effects/registry.go` |
| MNT-2 | MNT | major | `propertyterms.inverseArg` copies `database.NullString` | Fix now → F-2 (same-pass cleanup) | verified: identical body, `propertyterms.go:135` vs `core/database/null.go:16`; grep over `^func \w+\(\w+ string\) any \{` in `core api` finds only `NullString`, `NullTrimmed`, `inverseArg` |
| MNT-3 | MNT | minor | Second hand-written binding create-change literal | Fix now → F-3 | file this PR changes; `subjectvocab.go:135` (`EnsureBindingTx`) and `:206` (`AppendBinding`) |
| MNT-4 | MNT | minor | Lookups uneven: grades trims twice; `properties`/`subjecttypes` keep two full `Lookup`/`LookupTx` bodies | Fix now → F-4 | files this PR changes; `properties.go:298-319`, `subjecttypes.go:180-201`, `grades.go:121-137`. Precedent: `datevalues.Lookup` delegates to `LookupTx(db, …)` |
| CON-1 | CON | minor | New tests' invalid-input loops are maps without `t.Run` | Fix now → F-5 | `.cursor/rules/go-tests.mdc`; tests this PR adds |
| CON-2 | CON | minor | T-7 pins researcher change keys, not values (AC-1.12 says keys and values) | Fix now → F-6 | `TestCreateUpdateDeleteChanges`, `TestChangeKeys` compare sorted key sets only |
| SEC/PRF | SEC+PRF | — | No findings | — | create-only, compiled-in seed, bound params; one indexed lookup per Property delete |

Nits (logged): `MNT-5 · core/database/subjectvocab/subjectvocab.go:49 · rename sqlEnsureBinding → sqlInsertBinding` · `MNT-6 · core/database/propertyterms/propertyterms.go:1-3 · package comment says "run inside writes.Run" twice` · `MNT-7 · subjecttypes.UpsertTx · local id variable instead of writing into zero-valued existing` · `CON-3 · plan AC-3.1 · the AC's rg glob does not exclude nested *test dirs; 5 hits, all helpers — report real output in PR body` · `CON-4 · subjectvocab_test.go TestInstallFailureLeavesNothing · COUNT property_terms and subject_type_properties too`

### Fix plan 1

**F-1 — One Install rule in the seeded-vocabulary skill** (from MNT-1)
Files: `.agents/skills/add-seeded-vocabulary/SKILL.md`.
Failing test first: none (docs).
Do: Rewrite line 21 and "Future vocabulary domains" step 3 (and any other line stating the old rule) to one rule: a seed domain writes `Install(tx) ([]rowchange.Change, error)` + `ActionInstall` and runs through `installSeed` in `createCatalog` (atomic; audited unless every table is `None`, as the grades are). `nameformats` and `namealiases` still use `Install(c) error` only because S16-62's Out line left them; new domains do not follow them.
Check: `rg -n "Install\(c\)|all .None." .agents/skills/add-seeded-vocabulary/SKILL.md` prints only the `nameformats`/`namealiases` exception line; scripts/check-pr.sh PASS.

**F-2 — Drop `inverseArg` for `database.NullString`** (from MNT-2)
Files: `core/database/propertyterms/propertyterms.go`.
Failing test first: none (behavior-preserving; existing `TestUpsertTx` / `TestChangeKeys` cover the NULL inverse key).
Do: Replace every `inverseArg(...)` with `database.NullString(...)`; delete `inverseArg`.
Check: `grep -rnE "^func \w+\(\w+ string\) any \{" core api | grep -v _test.go` prints exactly `core/database/null.go` `NullString` and `NullTrimmed`; scripts/check-pr.sh PASS.

**F-3 — One binding create-change builder** (from MNT-3)
Files: `core/database/subjectvocab/subjectvocab.go`.
Failing test first: none (behavior-preserving; `TestEnsureBindingTx` and the existing `AppendBinding` audit tests cover it).
Do: Add `bindingCreateChange(typeID, propertyID []byte, order int) rowchange.Change` beside `bindingOrderChange`, built from `bindingFields`; use it in `EnsureBindingTx` and `AppendBinding`.
Check: `grep -n "rowchange.ActionCreate" core/database/subjectvocab/subjectvocab.go` prints one line (inside `bindingCreateChange`); scripts/check-pr.sh PASS.

**F-4 — One lookup body per package** (from MNT-4)
Files: `core/database/properties/properties.go`, `core/database/subjecttypes/subjecttypes.go`, `core/database/sourcecredibilitygrades/grades.go`.
Failing test first: none (behavior-preserving; existing `Lookup` tests cover trim and `ErrInvalid`).
Do: `properties.LookupTx` and `subjecttypes.LookupTx` take `database.Querier` (as `datevalues.LookupTx` does) and hold the only trim / empty-check / scan body; `Lookup` gets `c.DB()` and returns `LookupTx(db, key, origin)`. Fix the `subjecttypes.UpsertTx` call (`LookupTx(tx.Tx, …)`) and any `properties` caller to match. In `sourcecredibilitygrades`, trim and empty-check in `lookupTx` only; `Lookup` delegates.
Check: each of the three files has one `strings.TrimSpace(key)` in its lookup path; scripts/check-pr.sh PASS.

**F-5 — Table shape for the new invalid-input cases** (from CON-1)
Files: `core/database/properties/properties_test.go`, `core/database/propertyterms/propertyterms_test.go`, `core/database/subjecttypes/subjecttypes_test.go`, `core/database/subjectvocab/subjectvocab_test.go`, and any other test this PR added with a `for name, … := range map[…]` loop.
Do: Turn each invalid-input map loop into `[]struct{ name string; … }` with `t.Run(tt.name, …)`. Sequential create → same → update steps stay sequential.
Check: `git diff ef66e2168 -- '*_test.go' | grep -nE "^\+.*for name, .* := range map"` prints nothing; scripts/check-pr.sh PASS.

**F-6 — Pin researcher change values, not only keys** (from CON-2)
Files: `core/database/properties/properties_test.go` (`TestCreateUpdateDeleteChanges`), `core/database/propertyterms/propertyterms_test.go` (`TestChangeKeys`).
Failing test first: none (pins the pre-PR shape; must pass at head).
Do: Compare each change's `Fields` against an expected `map[string]rowchange.FieldDiff` literal in the pre-PR form (`id` as `database.UUIDString`, `origin` `"user"`, term `property_id` as UUID string, cleared description nil, Property delete including `cardinality` per D-3).
Check: the tests pass; scripts/check-pr.sh PASS.

## Round 1 — fix
Head `9f81ef79`. Gate (orchestrator) PASS. F-1 to F-6 done; no deviations. The pre-PR `for name, list := range map` loop in `subjectvocab_test.go` (~line 691) left as is (not added by this PR).
CON-1: **Resolved** — invalid-input loops are `[]struct{name…}` + `t.Run` (read in `9f81ef79`). CON-2: **Resolved** — `TestCreateUpdateDeleteChanges` and `TestChangeKeys` compare full `Fields` maps against pre-PR literals.

## Round 2 — review
Reviewers: MNT (had Fix-now majors MNT-1, MNT-2). Not sent: CON (minors only, read and resolved above), SEC+PRF (no findings). Scope `3ffab590...9f81ef79`.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | — | Round-1 major | Resolved | SKILL.md:21 and :146 state one rule; `rg "Install\(c\)\|all .None"` over guidance prints only the two exception lines |
| MNT-2 | MNT | — | Round-1 major | Resolved | `inverseArg` gone; signature grep prints only `NullString`, `NullTrimmed` |

No new findings. No Fix plan 2.

## Result
Gate PASS on `9f81ef79` · `origin/main` unchanged since branch cut (`ef66e216`) · CI green · open: none · follow-ups: none · to user: —
