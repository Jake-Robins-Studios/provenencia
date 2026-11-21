# Ship log — S15-24 Move a bundle to another Source in the engine

**Plan:** [`S15-24-move-bundle.md`](S15-24-move-bundle.md) · **Branch:** `s15-24-move-bundle` · **PR:** #935
**State:** ready

## Round 0 — implement
Base `eef680bfc`. Head `ddeffdbf0`. Gate PASS (orchestrator run). Report deviations:
- `VERSION` on `main` was 0.31.1, so the bump is 0.31.1 → 0.32.0 (the plan's "next minor" rule).
- T-2 `SetSourceTx` tests and `TestLookup` sit in new `setsource_test.go` / `lookup_test.go` files: the existing test files are internal packages and `evidencelayertest` would cycle.
- Manual check step 2 (scratch test against a dogfood copy) not run.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. Skipped: none (UX: `macos/App/**`, `Localizable.xcstrings`, `core/apperr`; SEC+PRF: `api/ffi/**`, `core/database/**`).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | major | Three copies of `SetSourceTx` | Fix now → F-1 | verified: `artifacts.go:428` and `subjects.go:318` bodies differ only in the entity name and the Exec key list. Same-pass cleanup: this PR adds all three copies; supersedes D-3's declined "shared change-building helper" (its premise was one map literal, the copy is the whole body). No researcher-visible behavior change |
| MNT-2 | MNT | major | `sourcemove.containsID` copies `database.ContainsBlobID` | Fix now → F-2 | verified: `sqlin.go:59` vs `sourcemove.go:218` |
| CON-1 | CON | minor | Artifact `Handles` path is redundant on a move; AC-2.8 test does not prove it | To user → **Drop it** (user, 2026-11-21) → F-3 | reviewer overlay run without `registry.go:412` passes `sourcemove`; `observations.requireSameGraph` keeps every citing Subject in the bundle. Supersedes D-10's `artifacts` entry and its "Subject's change does not name" reason |
| SEC-1 | SEC | minor | A crafted cross-Source link pulls a third Source's Artifact into the move unseen | Fix now → F-4 | verified: `sqlLinksSelect … WHERE g.source_id = ?` has no `a.source_id` filter; `Impact` filters via `ListBySource`, `Move` does not. Harm (silent data change), so fixed though crafted-only |
| SEC-2 | SEC | minor | `BundleOf`'s walk recurses with no depth bound | Fix now → F-5 | crafted-only, but a Go stack overflow is fatal past `ffi.Call`'s recover; a worklist costs nothing |
| MNT-3 | MNT | minor | `sources.GetTx` forwards to `Lookup`; private `getTx` is a third by-id read | Fix now → F-6 | verified `sources.go:216,321,473,629,633` |
| MNT-4 | MNT | minor | `add-catalog-query` does not mention `DeferForeignKeys` | Fix now → F-7 | `rg defer_foreign .agents .cursor` empty |
| UX-1 | UX | minor | A deleted target Source gets "This Source no longer exists." | Later PR | written into the S15-25 map scope entry (`deployment-plan.md` § S15-25 Ships); S15-25 has no plan yet |
| CON-2 | CON | minor | Manual check step 2 (dogfood copy) not run | To user (manual check) | carried into the report's Manual check; the user runs § 10 before merging |

Nits (logged): `UX-2 · L10n.swift error.sourcemove.not_found · "Evidence graph" capitalized vs neighbors` · `UX-3 · error.sourcemove.invalid · no next step (client-bug only)` · `MNT-5 · bundle.go:42 · visit(artifact bool) → two named closures` (moot after F-5) · `MNT-6 · sourcemove.go:102 · inBundle → idSet` · `CON-3 · setsource_test.go · "no query" not counted` · `CON-4 · sourcemove_test.go:196 · ref order uses bytes.Compare, ListBySource uses NOCASE`

### Fix plan 1

**F-1 — One `SetSourceTx` body for the three tables** (from MNT-1)
Files: new helper in `core/database/sqlbatch/sqlbatch.go` (or `rowchange`; whichever imports neither `core/database` nor a cycle), `core/database/{artifacts,evidencegraphs,subjects}/{<pkg>.go,setsource_test.go}`. Skill: `add-catalog-query`.
Failing test first: `sqlbatch.TestSetSource` (table test on a scratch table: moved rows, repeated keys, rows already on target, no keys → nil and no Exec, malformed sourceID) — red until the helper exists.
Do: add `SetSource(tx *sql.Tx, entity, selectHead, updateHead string, keys [][]byte, sourceID []byte) ([]rowchange.Change, error)` holding the whole current body (UniqueBlobIDs → Query `id, source_id` → skip rows on target → `rowchange.Updated(entity, …)` → sort by id → Exec the UPDATE over the input keys, which already filters `source_id != ?`). Each package's `SetSourceTx` keeps its `ErrInvalid` check, passes its own `sqlSourceRows`/`sqlSetSource` (SQL stays in the package), and wraps `mapConstraint`. Reduce each package's `setsource_test.go` to one row proving its entity name and key column (subjects: keyed by graph id). Note in the plan's Landed note that this supersedes D-3's declined shared helper.
Check: `grep -rn "rowchange.Updated(\"\(artifact\|evidence_graph\|subject\)\", id," core/database` prints no line inside a `SetSourceTx`; `grep -rn "func SetSourceTx" core/database` prints exactly the three thin wrappers; scripts/check-pr.sh PASS.

**F-2 — Use `database.ContainsBlobID`** (from MNT-2)
Files: `core/database/sourcemove/sourcemove.go`.
Do: replace `containsID(...)` with `database.ContainsBlobID(...)`; delete `containsID`.
Check: `rg -n "func \w+\(\w+ \[\]\[\]byte, \w+ \[\]byte\) bool" core` prints only `core/database/sqlin.go`; check-pr PASS.

**F-3 — Drop the Artifact `Handles` path** (from CON-1, user decision)
Files: `core/database/effects/registry.go`, `core/database/effects/handle_paths_test.go`, `core/database/sourcemove/sourcemove_test.go`, `core/database/effects/README.md`, the domain docs and plan Landed note if they name the Artifact path.
Do: remove `Handles: onField("source_id", sqlPath(sqlHandlesForArtifact))` from the `artifacts` entry and `sqlHandlesForArtifact`; fold `sqlHandlesCitingHead` back into `sqlHandlesForSource` if it is its only user, and restore the "Handle queries mirror autoreconciler" comment without the exception. Remove the `TestHandlePaths` artifact rows. In `TestMoveRecomputesHandles`, say the subjects path (`membersOf`) is what recomputes H, and why (`observations.requireSameGraph` keeps every citing Subject in the bundle). In the plan's Landed note record that D-10's `artifacts` entry was dropped on review (CON-1, user 2026-11-21).
Check: `rg -n "sqlHandlesForArtifact" core docs` prints nothing except the Landed note; `TestMoveRecomputesHandles` still passes (`weak` → `kept`); check-pr PASS.

**F-4 — `BundleOf` reads only same-Source links** (from SEC-1)
Files: `core/database/evidencegraphs/{evidencegraphs.go or bundle.go,bundle_test.go}`.
Failing test first: `TestBundleOf/a link to another Source's Artifact is not followed` — insert with raw SQL a link from a graph on S1 to an Artifact on S3; `BundleOf(seed on S1)` must not list that Artifact. Red at head.
Do: in the link rows `BundleOf` walks, skip a link whose Artifact's `source_id` is not the Source's. Prefer filtering where `BundleOf` reads (the per-Source link read used by `list`, adding `AND a.source_id = g.source_id`) only if every other reader of `list` is fine with it; otherwise filter inside `BundleOf` against the Source's own Artifact ids. Do not refuse the move.
Check: the new row passes; `TestBundleOf`, `TestMove` pass; check-pr PASS.

**F-5 — Iterative walk in `BundleOf`** (from SEC-2, MNT-5)
Files: `core/database/evidencegraphs/bundle.go`.
Do: replace the recursive `visit` closure with a worklist (slice used as a stack) over the same `seen` maps; same output order (ids sorted at the end as now).
Check: `TestBundleOf` passes unchanged; `grep -n "visit(" core/database/evidencegraphs/bundle.go` prints no self-call; check-pr PASS.

**F-6 — One by-id Source read** (from MNT-3)
Files: `core/database/sources/sources.go`, callers of `sources.GetTx` (`rg -n "sources\.GetTx\(" --type go`), `.agents/skills/add-catalog-query/SKILL.md:50`.
Do: move every `GetTx` caller (including `sourcemove.Move`) onto `sources.Lookup(tx.Tx, id)`; delete `GetTx` and private `getTx` (internal callers at `:216`, `:321` use `Lookup` or `getOne(tx.Tx, sqlGet, id)` directly). In the skill line that names `sources.GetTx` as a Tx-twin example, drop that example (keep `artifacts.ListBySourceTx`, `sourcemetadata.ReadDraftTx`).
Check: `rg -n "GetTx\b|func getTx" core/database/sources` prints nothing; check-pr PASS.

**F-7 — Name the deferred-key tool in `add-catalog-query`** (from MNT-4)
Files: `.agents/skills/add-catalog-query/SKILL.md` (the composing-package line, :56).
Do: add `core/database/sourcemove` to the composing-package examples, and one sentence: a write that changes both sides of a composite foreign key calls `tx.DeferForeignKeys()` before its first update and never issues a PRAGMA itself.
Check: `scripts/check-plan-docs.py` / check-pr PASS.

## Round 1 — fix
First attempt stopped: the implementer's `git stash` / `git stash pop` on a clean tree applied an unrelated user stash, leaving `core/database/effects/{registry,resolve}.go` conflicted; its repair was denied by the permission check. The user restored the two files to HEAD (and later cleared the stashes); a fresh implementer resumed with a no-stash rule.
Head `862f06c85`. Gate PASS (orchestrator run; the implementer's first run hit a `promotealign.TestListMergeMatchesReload` timing flake, 20.28 ms vs 20 ms, passed on re-run). F-1 to F-7 done.
Deviations: F-1's helper is `database.SetSource` in `core/database/setsource.go` (sqlbatch cannot import `database`); F-4 filters inside `BundleOf` with a new `sqlSourceArtifacts` read (a fourth query; D-2 said three), leaving `list` untouched; F-3's drop is recorded in the plan's Landed note, the D-10 body is unchanged.

Minors read by the orchestrator:
- SEC-1 / F-4 (`b20d69252`): **Resolved.** `BundleOf` drops links whose Artifact is not in `SELECT id FROM artifacts WHERE source_id = ?`; red-first row `TestBundleOf/a link to another Source's Artifact is not followed`.
- SEC-2 / F-5 (`b50eb28da`): **Resolved.** Worklist over the same `seen` maps; no self-call left. Also settles nit MNT-5.
- CON-1 / F-3 (`d8e76616c`): **Resolved.** `rg "sqlHandlesForArtifact|sqlHandlesCitingHead" core` is empty; `TestMoveRecomputesHandles` still weak → kept, now via `membersOf`.
- MNT-3 / F-6 (`04628f3e5`): **Resolved.** `GetTx` and `getTx` gone; callers in `sourcecopy`, `sourcemetadata`, `sourcemove` use `Lookup`; skill example dropped.
- MNT-4 / F-7 (`d103184f6`): **Resolved.** Skill names `sourcemove` and the `tx.DeferForeignKeys()` rule.

## Round 2 — review
Reviewers: MNT (had majors MNT-1, MNT-2). Not sent: CON, UX, SEC+PRF (no Fix-now blocker or major in round 1).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | major | Three copies of `SetSourceTx` | Resolved | one body in `database.SetSource`; three thin wrappers; table test on the helper |
| MNT-2 | MNT | major | `containsID` copy | Resolved | `sourcemove.go:202` calls `database.ContainsBlobID` |

No new blockers. Nits (logged): `MNT-7 · evidencegraphs/bundle.go:10 · sqlArtifactSource's comment now sits over a const block that also holds sqlSourceArtifacts`

## Finish
Merged `origin/main` @ `d1db2e3a7` (docs only: S16-53 plan). Gate PASS after the merge.

## Result
Gate PASS · CI see PR #935 · open: none · follow-ups: none · to user: CON-1 (answered: drop the Artifact handle path), CON-2 (manual check step 2 on a dogfood copy, before merge)
