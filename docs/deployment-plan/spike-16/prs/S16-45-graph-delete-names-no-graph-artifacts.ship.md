# Ship log — S16-45 A graph delete names the Artifacts it leaves in no graph

**Plan:** [`S16-45-graph-delete-names-no-graph-artifacts.md`](S16-45-graph-delete-names-no-graph-artifacts.md) · **Branch:** `s16-45-graph-delete-names-no-graph-artifacts` · **PR:** [#888](https://github.com/mendahu/provenencia/pull/888)
**State:** fixing 1

## Round 0 — implement
Base: `docs/s16-45-plan-refresh` @ `4d571aa0a` (the plan refresh, PR #887, not yet merged; `main` @ `505d1222c` below it).
Head `34ea92970`. Gate PASS (orchestrator run; xcode-test 60s). Report: deviations none.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. Skipped: none (diff touches `core/database/**`, `macos/App/**`, `Localizable.xcstrings`). Review base `4d571aa0a`, so the plan-refresh commit (PR #887) is out of the diff.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1, UX-1, MNT (outside lens) | CON, UX | blocker | The confirm sentence uses straight apostrophes; AC-1.1, AC-1.2, D-6 and `artifactGraphsNone` use `’` | Fix now → F-1 | verified: `Localizable.xcstrings` 16997, 17003 vs 23891; T-4–T-7 pin the straight form |
| CON-2, MNT-1, SEC+PRF (outside lens) | CON, MNT | major | The list query repeats the sole-link predicate instead of building on `soleLinkFrom` (D-3) | Fix now → F-2 | verified: `cascades.go` 64–69; the const's comment claims the list uses it |
| MNT-2 | MNT | major | `CascadeVias` re-derives the Named-facet + `cascadeEdgeList` rule `cascadesFor` owns | Fix now → F-3 | verified: `facets.go` `cascadesFor` vs `cascades.go` `CascadeVias`; same-pass cleanup |
| MNT-3 | MNT | major | T-2 inlines the `artifactRef` query the package's helper runs | Fix now → F-4 | verified: `evidencegraphs_test.go` 873 (helper) and 1584 (copy) |
| CON-3 | CON | minor | T-1 is eight hand-written subtests, not the table the plan and `go-tests.mdc` ask for | Fix now → F-5 | file this PR adds to |
| CON-4 | CON | minor | "two sole links" never checks which refs are listed | Fix now → F-5 | file this PR adds to |
| MNT-4 | MNT | minor | `newBase` repeats `mustSource`; `unlinkDef` repeats `Split`'s loop body | Fix now → F-6 | same-pass cleanup: this PR adds a copy |
| CON-5 | CON | minor | The Landed note says "No differences from the plan" | Fix now → F-7 | true only once F-1 and F-2 land |
| CON-6, MNT-5 | CON, MNT | nit | `CascadeVias` doc comment cites "(D-9)" | Fix now → F-3 | stale comment in a file this PR adds |

SEC+PRF: clean (bound parameters; `EXPLAIN QUERY PLAN` uses the PK and `evidence_graph_artifacts_artifact_id_idx`; list capped at 20).

Nits (logged): `MNT-6 · impact_test.go:1572 · failure message says "leaves_no_graph"; print ViaLeavesNoGraph` · `UX-2 · L10n.swift:9191 · doc comment lists count before refs; the format puts refs first`

### Fix plan 1
**F-1 — The confirm sentence uses the Artifact sheet's apostrophes** (from CON-1, UX-1)
Files: `macos/App/Resources/Localizable.xcstrings`, `macos/App/Platform/L10n.swift` (the `leavesNoGraph` `defaultValue`, if it has one), `macos/ProvenenciaTests/PVDeleteImpactTests.swift`. Skill: `add-localized-string`.
Failing test first: change T-4, T-5, T-6 (suffix) and T-7 expectations to the AC text with `’` ("won’t", "can’t"); they fail.
Do: replace `'` with `’` in both variations of `deleteImpact.confirm.leavesNoGraph`.
Check: `rg -n "won't|can't" macos/App/Resources/Localizable.xcstrings macos/App/Platform/L10n.swift` prints no `leavesNoGraph` line; the four tests pass.

**F-2 — Count and list share one predicate** (from CON-2, MNT-1)
Files: `core/database/deleteimpact/cascades.go`.
Do: the list becomes `listSQLFn(\`SELECT a.id, a.ref FROM artifacts a WHERE a.id IN (SELECT l.artifact_id \` + soleLinkFrom + \`) ORDER BY a.ref COLLATE NOCASE LIMIT ?\`)`; the argument order stays graph id, then limit. Rewrite `soleLinkFrom`'s comment to say what both queries do with it.
Check: `rg -c "NOT EXISTS" core/database/deleteimpact/cascades.go` prints 1; T-1 passes unchanged.

**F-3 — One cascade edge set for `cascadesFor` and `CascadeVias`** (from MNT-2, CON-6, MNT-5)
Files: `core/database/deleteimpact/cascades.go`, `core/database/deleteimpact/facets.go`.
Do: add `cascadeEdges() []inboundEdge` *(new)* in `cascades.go`: every `Named` facet release converted to an edge as `cascadesFor` does today, then `cascadeEdgeList`. `cascadesFor(kind)` filters `cascadeEdges()` by `Parent`, keeping today's order (Named facets first). `CascadeVias` returns `slices.Sorted(maps.Keys(...))` over `cascadeEdges()`' vias, shaped like `ResourceInboundVias`. Drop "(D-9)" from its doc comment.
Check: T-1 "with Citations" (order) and `TestSwiftVocabularyMatchesGo` pass; `TestImpactEvidenceGraph`, `TestImpact*` pass.

**F-4 — T-2 uses `artifactRef`** (from MNT-3)
Files: `core/database/evidencegraphs/evidencegraphs_test.go`.
Do: replace the inline query at 1580–1586 with `aRef := artifactRef(t, f.c, a)`.
Check: `rg -c "SELECT ref FROM artifacts WHERE id = \?" core/database/evidencegraphs` prints 1.

**F-5 — T-1 is a table, and the plural case checks its refs** (from CON-3, CON-4)
Files: `core/database/deleteimpact/impact_test.go`.
Do: turn `TestImpactEvidenceGraphLeavesNoGraph`'s cases into one `[]struct` table: fields for the Artifacts put in Jones only, the ones in Jones and Default, an unlinked count, whether X is deleted (empty graph), Citations in Jones, a Subject in Jones, and the wanted total, listed refs (exact, sorted) or no group, the Citations-first order, and `Allowed`. "two sole links" asserts the listed refs equal the sorted refs of its two Artifacts. Same eight cases, same expectations.
Check: `go test -tags fts5 -run TestImpactEvidenceGraphLeavesNoGraph -v ./core/database/deleteimpact/` lists the eight cases, all passing.

**F-6 — T-1's setup reuses the package's helpers** (from MNT-4)
Files: `core/database/deleteimpact/impact_test.go`, `core/database/evidencegraphs/evidencegraphstest/evidencegraphstest.go`.
Do: T-1's base setup calls `subjectvocab.Install`, `mustSource` (`handle_release_test.go` 322) and `evidencegraphstest.SoleGraph` instead of its own copy. Add `evidencegraphstest.Unlink(t testing.TB, c *database.Catalog, userID, graphID, artifactID []byte)` *(new)*, which runs `evidencegraphs.Unlink` in `writes.Run` (Action `unlink_artifact`) and fails the test on error; `Split`'s loop calls it, and T-1 calls it in place of `unlinkDef`. Other `evidencegraphs.Unlink` call sites in tests stay: they assert on the error or the changes.
Check: `rg -n "func unlinkDef|func newBase" core/database/deleteimpact` prints nothing; `go test -tags fts5 ./core/database/...` passes.

**F-7 — The Landed note lists the review changes** (from CON-5)
Files: `docs/deployment-plan/spike-16/prs/S16-45-graph-delete-names-no-graph-artifacts.md`.
Do: the Landed note lists the differences from the plan after this round: `cascadeEdges()` shared by `cascadesFor` and `CascadeVias` (MNT-2), and `evidencegraphstest.Unlink` (MNT-4). F-1 and F-2 bring the code back to the plan and are not differences.
Check: scripts/check-pr.sh PASS.
