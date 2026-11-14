# Ship log — S16-36 A link from a record to itself is refused where links are read

**Plan:** [`S16-36-refuse-self-loops.md`](S16-36-refuse-self-loops.md) · **Branch:** `s16-36-refuse-self-loops` · **PR:** #841
**State:** ready

## Round 0 — implement
Branch cut from `origin/main` @ `2c84a7a9a`; work uncommitted in the working tree. Gate not run.

**Stopped on:** §11 "A test not named in §4 or §8 builds a link with equal ends and fails after STEP-1".
`core/database/graphcache/evidence_graph_walk_test.go` `TestWalkEvidenceGraphEdgeCap` fails after the D-1 Evidence guard:
`under the cap: got 49729 edges, want 49952`. Verified by the orchestrator: the fixture's `id(n)` gives the from-Subjects
ids 1..223 and the to-Subjects ids 1..224, so 223 bridge pairs have one Subject at both ends, and the guard drops exactly
those (49952 − 49729 = 223). The test means a product of disjoint ends; its fixture is a crafted self-loop by accident.

Done before the stop: T-1, T-2 (failed first, now pass), D-1 canon and Evidence guards, the T-9/T-10 deletions in
`conclusionsummaries`. Deviation: T-1 commits `k.Commit(loop, town, city, self, part)` (with association ids, as
`TestNodesOnBridges` does) instead of the plan's `k.Commit(loop, town, city)`.

Taken to the user: amend the plan (plan-pr) to name this test and give its to-Subjects ids disjoint from the from-Subjects.

User (2026-11-14): amend and resume. Plan amended: STEP-1 names the test; §8 T-11 gives the to-Subjects ids `id(1000 + i + 1)`.
Implementer resumed from STEP-1 on the uncommitted working tree.

Second stop (mid-STEP-5), §11 again. Head `7dee1b19b` (plan amendment, STEP-1 – STEP-4 committed); STEP-5 uncommitted in `core/kinship`.
Deviation: T-3 sits inside `TestCreateCitedBridge` (its `countBridges` is a closure there), as the plan placed it.
Full `go test ./core/... ./api/...` run by the orchestrator with STEP-5 in the tree; only two failures:
- `core/database/canonlinks/reader_test.go` `TestRelationshipsOptionsSiblings/AC-1.9` (lines 834–836): files a sibling link Bea→Bea
  and wants a Bea–Bea entry. Fails at `7dee1b19b` without STEP-5 too, so STEP-1's canon guard broke it (the STEP-1 check
  did not run `canonlinks`). The guard is doing what D-1 says.
- `core/kinship/families_test.go` `TestKinOf/a_link_to_self` (line 220): a hand-built `rel(1, 1, …)` link wants no kin; D-4
  removed the `readsTerm` equal-ends check, so `KinOf` now reads it. D-4 says no reader handles one.
Proposed amendment: T-12 rewrites AC-1.9's last case to file Bea→Bea and want no entry (the guard seen through `canonlinks`);
T-13 deletes `TestKinOf` "a link to self". Taken to the user.
User (2026-11-14): amend and resume. Plan amended: STEP-5 names both files; §8 T-12, T-13. Implementer resumed at STEP-5.

Head `a22201fe0`. Gate PASS (orchestrator, against `2c84a7a9a`). Report deviations: T-1 `k.Commit` with association ids;
T-3 inside `TestCreateCitedBridge`; STEP-6 `pageReads` inlined as `reads(id, hops.PartsOfPlace)` (D-7 allows). Plan amendments
committed as `8000398d1` and `9f4e80d6c`.

## Round 1 — review
Base `2c84a7a9a`, head `a22201fe0`.
Reviewers: CON, MNT, SEC+PRF (matching layers `core/kinship`, `core/graphalign`, `core/recordlinks`; `core/database/**`).
Skipped: UX (no `macos/App/**`, strings, `core/apperr`, or error codes).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | major | The guard makes `finishLinks`' `self\|assoc\|neighbor` dedupe dead | Fix now → F-1 | verified: `finishLinks` gets rows only from `loadLinks` → `linkRaws`; `bridgeEndpoints` keeps one endpoint pair; `auto_reconciler_values` keeps `PRIMARY KEY (entity_id, property_id, rank)` from 000034 (renamed in 000040, never rebuilt); so a repeated key needs `self` at both ends, which the guard drops. §4 row "Canonical link finish" names a self-loop as its only purpose |
| MNT-2 | MNT | nit → minor | `linkRaws` doc names only the registered-bridge skip | Fix now → F-2 | stale comment in a file this PR changes |

SEC+PRF: no findings. CON: no findings.

Nits (logged): `CON-1 · placeentries.go:294 · FiledPlaceLinks doc not rewrapped` (rides F-2) · `CON-2 · docs/promote-graph-alignment.md:198 · link text drops "§2.7"` · `MNT-3 · load.go:354, evidence_graph.go:212 · guard comments ~130 columns` (rides F-2) · `MNT-4 · placeentries.go:294 · same as CON-1` · `MNT-5 · graphalign/align.go:125-128 · newState loops where View and NewGraph write two calls`

### Fix plan 1
**F-1 — Delete the dead self-loop dedupe in `finishLinks`** (from MNT-1)
Files: `core/database/graphcache/load.go`, this plan's Landed note.
Failing test first: none (removes a branch no input reaches; behaviour unchanged).
Do: delete `seen`, `key` and its check in `(*Graph).finishLinks`. Add one line to `finishLinks`' doc (or the `linkRaws` doc): each `(self, association)` gives at most one row, since a bridge has two endpoints and a rank-1 value is one per property, and `linkRaws` drops a link from a record to itself. Add a line to the plan's Landed note: the `finishLinks` dedupe went with the guard (D-6's rationale now rests on the schema and the guard).
Check: `rg -n "seen\[" core/database/graphcache/load.go` shows no hit in `finishLinks`; `CGO_ENABLED=1 go test -tags fts5 ./core/database/...` passes; scripts/check-pr.sh PASS.

**F-2 — Doc riders** (from MNT-2, MNT-3, CON-1/MNT-4)
Files: `core/database/graphcache/load.go`, `core/database/graphcache/evidence_graph.go`, `core/database/conclusionsummaries/placeentries.go`.
Do: `linkRaws` doc says it keeps the rows a registered bridge accepts and drops a link from a record to itself. Wrap the two guard comments at the surrounding comments' width. Rewrap the `FiledPlaceLinks` doc paragraph.
Check: gofmt clean; scripts/check-pr.sh PASS.

## Round 1 — fix
Head `a901ac28c`. Gate PASS (orchestrator). F-1 done (`f65ccfcf7`, carries the `load.go` parts of F-2); F-2 done (`a901ac28c`).
Implementer's first gate run failed `promotealign` `TestLargeSourceBudgets` on timing while xcode-test overlapped (warm 3.85s,
cold 2.59s vs 2.5s); the package passed alone and the gate reran to PASS. Orchestrator's gate run also PASS.

## Round 2 — review
Scope `a22201fe0...a901ac28c`. Reviewers: MNT (had MNT-1 major). Not re-sent: CON, SEC+PRF (no findings).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | major | (round 1) dead `finishLinks` dedupe | Resolved | `seen`/`key` gone; doc states the invariant (rank-1 filter load.go:393/398, guard load.go:357) |

No new findings. MNT-2 (minor, F-2) read by the orchestrator in `f65ccfcf7`: Resolved.

## Result
Gate PASS · `origin/main` unmoved since `2c84a7a9a` · open: none · follow-ups: none (CON-2, MNT-5 logged nits) · to user: — (two plan stops, both answered: amend and resume)
