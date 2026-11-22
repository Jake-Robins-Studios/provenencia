# Ship log — S15-61 Metadata levels are one declared list

**Plan:** [`S15-61-metadata-levels-list.md`](S15-61-metadata-levels-list.md) · **Branch:** `s15-61-metadata-levels-list` · **PR:** #943
**State:** ready

## Round 0 — implement
Head `6c1b1ab60`. Gate PASS (orchestrator run). Report: Status line reads "Landed in [#943](…) (2026-11-22)" (check-plan-docs rejects "Landed #943"); no plan **Landed** note written. No other deviations.

## Round 1 — review
Reviewers: CON, MNT, SEC+PRF (`core/database/**` is a performance path; the PR derives SQL from a declared list). Skipped: UX (no `macos/App/**`, strings, or error codes).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-2, MNT-1 | CON, MNT | minor | add-catalog-delete bullet's "except" reads as "metadata rows are not research" | Fix now → F-1 | verified: `.agents/skills/add-catalog-delete/SKILL.md:35`; a file this PR changes |
| CON-3 | CON | minor | `TestMetadataEffects` checks `len(Search)`, not its Kind and Path (T-6 asks for the value) | Fix now → F-2 | verified: `registry_completeness_test.go:237`; a test this PR adds |
| CON-1 | CON | minor | Plan has no Landed note (DoD) | Fix now → F-3 | verified: plan diff changes only the Status line |

Nits (logged): `CON-4 · core/database/catalogmodel/metadata.go:96 · "goes up to" error names the walked entry, not the asked level; record in the Landed note` · `MNT-2 · core/database/effects/registry_completeness_test.go:616 · test e.Up == nil, not "source"` · `MNT-3 · core/database/sourcemetadata/sourcemetadata_test.go:761 · Citation fixture repeats catalogmodel/metadata_test.go:181; point at the other copy` · `MNT-4 · docs/catalog-deletes.md:56 · still lists the three tables by name` · `MNT-5 · core/database/sourcemetadata/sourcemetadata.go:755 · eachLevel could iterate catalogmodel.MetadataTables`
SEC+PRF: no findings.

### Fix plan 1
No blocker or major: no round 2 (minors only; the orchestrator reads the fix commits).

**F-1 — Put the metadata exception on the facetRelease instruction** (from CON-2, MNT-1)
Files: `.agents/skills/add-catalog-delete/SKILL.md`.
Do: line 35 reads "**`Audited: true`**: the rows are research. Add exactly one `facetRelease` entry in `core/database/deleteimpact/facets.go` (a metadata level's tables are the exception: `metadataLevelFacets` builds theirs from `catalogmodel.MetadataTables`, see `add-catalog-model`):". In the checklist's "Resource inbound edges have count + list probes" line, add "(a metadata level's field probes come from `metadataFieldEdges`)".
Check: `python3 scripts/check-guidance-names.py` passes.

**F-2 — Assert the Source tables' Search value** (from CON-3)
Files: `core/database/effects/registry_completeness_test.go` (`TestMetadataEffects`, added by this PR).
Do: for each table with `wantSearch > 0`, also assert `eff.Search[0].Kind == DocSource` and that `eff.Search[0].Path.check(table)` returns `"sources"` with no error and the same columns as `field("source_id")` (compare the way the package's other path tests do). Also take MNT-2: test `e.Up == nil` instead of the string `"source"`.
Check: run it red first by temporarily changing the `source_metadata` literal's `Kind` locally (do not commit that); `CGO_ENABLED=1 go test -tags fts5 ./core/database/effects/` passes; scripts/check-pr.sh PASS.

**F-3 — Add the plan's Landed note** (from CON-1, CON-4)
Files: `docs/deployment-plan/spike-15/prs/S15-61-metadata-levels-list.md`.
Do: a `**Landed.**` line under the header naming the differences: the Status wording ("Landed in [#943](…)"), `SourcePath`'s "goes up to" error names the entry being walked, which may differ from the level asked for (§ 6 writes `level <l>`), and the F-1 wording of the add-catalog-delete bullet.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-61-metadata-levels-list.md` passes; scripts/check-pr.sh PASS.

## Round 1 — fix
Head `92e425b93`. Gate PASS (orchestrator run). F-1 done (`461a1005f`); F-2 done, red first with the Kind swapped (`9bc0b9ab9`), MNT-2 taken; F-3 done (`92e425b93`). Read by the orchestrator: CON-2/MNT-1 **Resolved**; CON-3 **Resolved** (asserts Kind and that the path ends at `sources`; `Path.check` exposes no columns, and on `source_metadata` the only path to `sources` is `source_id`); CON-1 **Resolved**. No round 2: no Fix-now blocker or major.

## Result
Gate PASS · CI green · open: none · follow-ups: none · to user: —
