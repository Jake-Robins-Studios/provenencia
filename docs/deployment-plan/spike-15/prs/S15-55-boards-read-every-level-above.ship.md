# Ship log — S15-55 Boards read every level above

**Plan:** [`S15-55-boards-read-every-level-above.md`](S15-55-boards-read-every-level-above.md) · **Branch:** `s15-55-boards-read-every-level-above` · **PR:** [#970](https://github.com/Jake-Robins-Studios/provenencia/pull/970)
**State:** fixing 1

## Round 0 — implement
Head `356bcead8`. Gate PASS (run by the orchestrator). Report: AC-3.6 deviation (a nil repeated element marshals as an empty message, so the answer is `request.invalid_id`); version 0.41.0 (`main` was at 0.40.1); in-app manual check not run.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. Skipped: none.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | major | Swift-to-wire `MetadataOwner` mapping is copied five times | Fix now → F-1 | verified: `GoStore.swift` 144, 374, 391, 410, 429; same-pass cleanup |
| MNT-2 (and CON's note) | MNT | major | `needOfTx` keeps a store argument this PR made dead | Fix now → F-2 | verified: one definition, one call, `st` unused in the body |
| CON-1 (and MNT's note) | CON | minor (raised from nit) | AC-3.2's check passes when the entry is missing | Fix now → F-3 | verified: `ok && (…)` at `sourcemetadata_test.go` 3922 |
| UX-1 | UX | minor | A deleted parent answers a save-worded error | Later PR | S15-56's map scope entry (Also). D-6 sets the code and no Citation draft surface exists; the Source parent answers as on `main` |
| UX-2 | UX | nit | Translator comment names only the Source | Later PR | S15-56's map scope entry (Also) |

SEC+PRF: no findings. CON-2 (in-app manual check not run) goes to the user with §10.

Nits (logged): `MNT-3 · annotation.go:60 · CitationValues comment could name ValuesOf` · `MNT-4 · sourcemetadata_test.go:3911 · AC-3.2 subtest largely repeats TestListDraftWorkspaceInherited` · `MNT-5 · sourcemetadata.go · buildBoards computes b.ancestors() twice per board`

### Fix plan 1
**F-1 — One Swift mapper for a wire `MetadataOwner`** (from MNT-1)
Files: `macos/App/Platform/GoStore.swift`.
Failing test first: none (a refactor with no behavior change; the Xcode tests stay green).
Do: add one private static mapper from `MetadataOwner` to `Provenencia_Engine_V1_MetadataOwner`; `getDraftMetadataBoard` uses `parents.map`, and `setMetadata`, `clearMetadata`, `dismissMetadataSuggestion`, `reorderMetadata` and any other site set `req.owner` from it.
Check: `grep -nE "MetadataOwner\(\)|owner\.(level|id) = " macos/App/Platform/GoStore.swift` prints only lines inside the mapper; scripts/check-pr.sh PASS.

**F-2 — Drop `needOfTx`'s store argument** (from MNT-2)
Files: `core/database/sourcemetadata/annotation.go`, `sourcemetadata.go`, the plan.
Failing test first: none (dead parameter).
Do: `needOfTx(tx *sql.Tx, owner Owner, fieldID []byte)`; update its one call; remove the plan's Landed line that says it keeps `st`.
Check: `go vet` and the package's tests pass; no unused variable at the call site.

**F-3 — AC-3.2's check fails on a missing entry** (from CON-1)
Files: `core/database/sourcemetadata/sourcemetadata_test.go`.
Do: `!ok ||` in place of `ok &&`. If it then fails, the entry is legitimately absent at that level for the fixture: assert on a field the draft board does hold, never skip.
Check: the subtest passes and fails when the Source's value is not read.

## Cost
Plan: 6,150 words (check-plan-docs info line).

| Round | Agent | Model | Tokens |
| --- | --- | --- | --- |
| 0 | implementer | agent default | 209k |
| 1 | CON | opus | 95k |
| 1 | MNT | opus | 99k |
| 1 | UX | opus | 73k |
| 1 | SEC+PRF | opus | 70k |
