# Ship log — S16-25 Swift keys become plain values and follow their inputs

**Plan:** [`S16-25-keys-follow-inputs.md`](S16-25-keys-follow-inputs.md) · **Branch:** `s16-25-keys-follow-inputs` · **PR:** #847
**State:** ready

## Round 0 — implement
Head `36a0bd92e`. Gate PASS (orchestrator run, all nine checks). Report deviations:
- D-11 asked for four commits; three plus the landed commit (STEP-3 to STEP-6 interleave in `b88d0b651`).
- `core/database/effects/evidence_graphs_test.go` updated: an Artifact label edit now moves `source_records`.
- `CatalogQueryRegistryTests` `personFamilyRevalidateOnTouchedHandle` and `personEventsRevalidateOnTouchedHandle` follows lists updated (not named in §4).
- `aKeyInvalidatedAndRefreshedRevalidatesOnce` seeds claims with inputs for `e1`, `g1`.
- Five old follow tests deleted, replaced by T-6 to T-9; `personClaimsFollowHandlesAndGraphs` rewritten without its `.source` half.
- §10 manual check not run (needs the large fixture and two windows).
- `promotealign` `perf_test.go` once over its 2.5 s budget (3.15 s) under parallel load; passed in the gate.

## Round 1 — review
Base `844b5714b`, head `36a0bd92e`.
Reviewers: CON, MNT, UX (diff touches `macos/App/**`), SEC+PRF (`core/database/**`, `macos/App/Features/**` session models, `source_records` loads catalog-derived ids). Skipped: none.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 (+UX outside-lens note) | CON | major | Plan has Status Landed but no Landed note listing differences | Fix now → F-1 | verified: `git show 36a0bd92e` changes only the Status line; DoD §9 asks for the note |
| CON-2 | CON | minor | STEP-3 to STEP-6 in one commit, against D-11 | Fix now → F-1 (recorded in the Landed note) | verified: `b88d0b651` touches keys, follows, tests and docs; reviewer accepts the note as the fix |
| MNT-1 | MNT | minor | Smaller-set branch in `revalidatedKeys` repeats what `Set.isDisjoint` does | To user → Fix now → F-2 | verified in the macOS SDK `Swift.swiftinterface:19510` (`@inlinable`, iterates the smaller set). Contradicts D-7's wording; user chose to drop the branch (2026-11-15) |
| MNT-2 | MNT | minor | `citationGraphId` / `citationArtifactId` lack the check `id` has | Fix now → F-3 | verified: `CatalogQueryKey.swift:29-32`, no guard |
| MNT-3 | MNT | minor | `citedDetail` fixture still builds three unused cited Sources | Fix now → F-4 | read: `WorkspaceSessionTests.swift:1440-1453`; the test names only `src1`, `g1`, `g2` |
| SEC/PRF | SEC+PRF | — | No findings | — | outside-lens note (Source date via `SourceScopes`) is D-3 / Out, deferred to S15-05 |
| UX | UX | — | No findings | — | outside-lens note merged into CON-1 |

Nits (logged): `MNT-4 · WorkspaceSessionTests.swift:1406 · doc on named does not parse` · `MNT-5 · .agents/skills/add-audit-scope/SKILL.md:46 · "Reads only when a keyed read (citations, graph progress) does" omits source_records` · `MNT-6 · CatalogQueryRegistry.swift:94 · say why followsOwnId(.touchedHandles) stays (FakeStore empty inputs)` · `CON-3 · CatalogQueryRegistryTests.swift:1604,1651 · "through touchedHandles" → "its own handle"`

### Fix plan 1

**F-1 — Landed note** (from CON-1, CON-2)
Files: `docs/deployment-plan/spike-16/prs/S16-25-keys-follow-inputs.md`.
Do: under the header add a `**Landed.** Differences from the plan:` paragraph in the shape of `S16-24-reads-report-inputs.md:18`, listing: D-11's STEP-3 to STEP-6 landed in one commit (`b88d0b651`) because the registry, `CatalogLastUpdated.swift` and `WorkspaceSession.swift` edits interleave; D-7's smaller-set swap dropped since `Set.isDisjoint` already iterates the smaller set (MNT-1, user 2026-11-15); `effects/evidence_graphs_test.go` now expects an Artifact label edit to move `source_records`; `CatalogQueryRegistryTests` `personFamilyRevalidateOnTouchedHandle` / `personEventsRevalidateOnTouchedHandle` declared-follows lists updated (reload expectations unchanged); the five old follow tests replaced by T-6 to T-9; and T-8's final assertion. For T-8: restore `handle.value == renamed` (and the hidden-path value check) if the value type allows it; if it does not, say why in the note.
Check: `scripts/check-plan-docs.py` passes; scripts/check-pr.sh PASS.

**F-2 — Drop the redundant smaller-set branch** (from MNT-1)
Files: `macos/App/Features/Workspace/Session/WorkspaceSession.swift` (`revalidatedKeys`, ~330-345).
Do: replace the `deps.count <= reported.count ? … : …` expression with `!deps.isDisjoint(with: reported)` (keep the `reportedBySlot` memo). Doc comment: drop "a key's ids are met by looking up the smaller of the two sets"; say each slot's reported ids are read once per write. Grep the plan-adjacent docs you changed in STEP-6 (`docs/catalog-caches.md`, `docs/macos-client-patterns.md`, `cache-architecture.md`, skills) for "smaller of the two sets" / "smaller set" and align any that describe the swap as code the app writes.
Check: existing session tests pass; scripts/check-pr.sh PASS.

**F-3 — One rule for wrong-kind id reads** (from MNT-2)
Files: `macos/App/Features/Workspace/Session/CatalogQueryKey.swift`.
Do: give `citationGraphId` and `citationArtifactId` `precondition(kind == .citationsByArtifact, …)` matching `id`'s message style.
Check: tests pass; scripts/check-pr.sh PASS.

**F-4 — Trim the `citedDetail` fixture** (from MNT-3)
Files: `macos/ProvenenciaTests/WorkspaceSessionTests.swift` (~1440-1494).
Do: reduce it to a detail for `id` with `inputs = CatalogPageInputs(handles: [id], evidenceGraphs: ["g1"], sources: ["src1"])` (use the passed id, not a hard-coded `e1`); drop the `s-field` / `s-owner` / `s-pic` outcome and picture setup and its doc; rename if the name no longer fits.
Check: `sourceWordsNotSourceActivityReloadThePage` passes; scripts/check-pr.sh PASS.

**Ride-alongs (nits, same files):** MNT-4 doc wording; MNT-5 name `source_records` in the add-audit-scope sentence; MNT-6 one-line comment on the own-id follow; CON-3 doc wording.

## Round 1 — fix
Head `ea86171f2`. Gate PASS (orchestrator run). F-1 to F-4 done; ride-along nits done. T-8 restores `handle.value == renamed` on both visible and hidden paths (`CatalogConclusionDetail` is Equatable). No F-# not reproduced.
Minors read by the orchestrator: MNT-1 **Resolved** (`bc4100d8f`: plain `isDisjoint`, memo kept, doc trimmed) · MNT-2 **Resolved** (`e868d4bca`: both accessors check the kind) · MNT-3 **Resolved** (`3f09263aa`: `detailWithInputs`, unused Sources gone).

## Round 2 — review
Scope `36a0bd92e...ea86171f2`. Reviewers: CON (had a Fix-now major, CON-1). MNT, UX, SEC+PRF not sent (no Fix-now blocker or major).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | major | Landed note | Resolved | `fb19f7465` adds the note (plan line 20); check-plan-docs 0 errors; T-8 asserts `handle.value == renamed` visible and hidden |

No new blockers. No Fix plan 2.

## Finish
Merged `origin/main` @ `2fa6bc6ef` (S15-D27 brief and S15-48 plan, docs only; no reference to the old key enum or `.source` follows). Gate PASS against `2fa6bc6ef`.

## Result
Gate PASS · CI pending · open: none · follow-ups: none · to user: MNT-1 (answered: drop D-7's smaller-set branch, 2026-11-15)
