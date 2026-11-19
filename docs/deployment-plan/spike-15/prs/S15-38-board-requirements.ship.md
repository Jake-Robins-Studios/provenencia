# Ship log — S15-38 Boards carry their citation's requirements

**Plan:** [`S15-38-board-requirements.md`](S15-38-board-requirements.md) · **Branch:** `s15-38-board-requirements` · **PR:** #910
**State:** fixing 1

Base: `main` @ `ca6790b83` (plan planned against `5bf7cbd`). `VERSION` on `main` is 0.26.2, so the bump is 0.27.0 as planned.

## Round 0 — implement
Head `03f310a16`. Gate PASS (orchestrator run). Report deviations:
1. `listWorkspaces` returns `map[string]Board`; the `.Entries` read changed in `TestListWorkspacesExported`, `TestListWorkspaces` and `TestListByOwnersTx`'s "workspaces read every owner" (plan allowed one edit). No assertion weakened.
2. Whole-board handler tests on artifact and graph boards picked up empty used entries (the fixture's `clearBoardSuggestions` detaches seeded suggestions, so the birth certificate's format heads surface). Added `withoutFormatRows` in `metadata_test.go`, applied in `TestMetadataOwners`, `TestGetMetadataBoard`, `TestMetadataBoardsKeepTheirLevel`, `TestUpdateArtifactMetadata`, `TestCreateEvidenceGraph` and the artifact and graph cases of `TestGetSourceWorkspace` (two files outside STEP-6's list).
3. `testWorld` split into `emptyWorld` + `testWorld`; `seededWorld` is `emptyWorld` + seed.
4. § 5.4 doc text rides the version-bump commit.
5. Version 0.26.2 → 0.27.0 (header said 0.26.0).

## Round 1 — review
Reviewers: CON, MNT, SEC+PRF (security: `api/ffi/**`, code that loads stored citation formats from the catalog and parses them; performance: `core/database/**`). Skipped: UX — the only `macos/App/**` file is the generated `engine.pb.swift`; no `Localizable.xcstrings`, no `core/apperr`, no new error code (the dismiss refusal reuses `sourcemetadata.invalid` with a param).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | blocker | The dismiss X on an empty, suggested, needed field now fails with an error | To user → accepted gap until S15-39 (user, 2026-11-19) → F-1 | verified: `MetadataBoardModel.suggested` is `!hasValue && suggested`, and `MetadataBoardSuggestionRow` always draws `PVIconButton(.dismiss)` (`MetadataBoardView.swift:246`), so the X shows on 24 seeded needed suggestions (census `jurisdiction`, book `author`, …). D-8's refusal returns `sourcemetadata.invalid`. D-8's premise ("S15-39 never offers the X") and Reach row are wrong for suggested heads. The fix (hide the X now) contradicts D-12 and the Out line that gives it to S15-39 |
| MNT-1 | MNT, CON (outside lens) | major (reviewer: blocker) | `fieldsByID` copies `loadFields`; `listWorkspaces` copies its missing-id check | Fix now → F-2 | verified: `sourcemetadata.go:1077` and `:1254` share the read and map build; `:1041-1045` repeats the check. Same-pass cleanup. Re-rated major: a duplicate in one package, no wrong behavior |
| MNT-3 | MNT | minor | `ListDraftWorkspace` repeats `listWorkspaces`' per-(type, level) assembly | Fix now → F-3 | same-pass cleanup: both copies are added by this PR |
| MNT-2 | MNT | minor | needed-beats-used ordering lives in `citationformat.add` and `sourcemetadata.stronger` | Fix now → F-4 | verified `annotation.go:126`; same-pass cleanup |
| MNT-5 | MNT | minor | third seeded-type-by-key scan in handler tests; fifth inline `UpdateFormats` write in core tests | Fix now → F-5 | same-pass cleanup: this PR adds a copy of each; move every copy |
| SEC-1 | SEC | minor | no fuzz target over `Requirements` → `needsAt` → `annotate` | Fix now → F-6 | code this PR adds keys and slices chains from stored text; rubric asks for a fuzz target |
| MNT-4 | MNT | minor | § 5.4 Order bullet and lead sentence are stale | Fix now → F-7 | doc this PR changes |
| CON-2 | CON | minor | PR body says the § 10 manual check was replaced by the Xcode tests | Fix now (orchestrator, PR body) | the manual check is the user's at finish; the body will say it is pending for the user, not replaced |

Nits (logged): `CON-3 · S15-38-board-requirements.md:16 · Landed note counts 4 commits; there are 5` · `MNT-6 · annotation.go:45 · comment names boardBuiltins; vars are dateHead/pageHead` · `MNT-7 · annotation.go:48-49 · "date"/"page" bare strings repeat citationformat builtins` · `MNT-8 · MetadataDraftHostParityTests.swift:98 · say the needed case checks nothing so S15-39 restores both checks`

### Fix plan 1

**F-1 — Record the dismiss-X gap the plan called unreachable** (from CON-1; user chose "accept gap until S15-39", 2026-11-19)
Files: `docs/deployment-plan/spike-15/prs/S15-38-board-requirements.md` (§ 6 Reach row for `DismissMetadataSuggestion` on a needed field, § 11 Risks table, § 10 step 2, the Landed note).
Do: correct the Reach row: a needed field the type also suggests is drawn today as a suggestion row with a dismiss X (`MetadataBoardModel.suggested`, `MetadataBoardView.swift` `MetadataBoardSuggestionRow`); after this PR that X shows "This metadata change can't be saved." (24 seeded needed suggestions, e.g. census `jurisdiction`) until S15-39 hides it. Add the same as a Risks row (accepted by the user, 2026-11-19; S15-39 hides the X). Manual check step 2: dismissing an empty suggestion the type does not need saves as before; dismissing a needed one shows the save error (known, S15-39). Do not edit any Decision or the Out table. No code change.
Check: `scripts/check-plan-docs.py` (via check-pr) PASS.

**F-2 — One field read by id** (from MNT-1, CON outside-lens)
Files: `core/database/sourcemetadata/sourcemetadata.go`.
Do: keep `fieldsByID` as the only `metadatafields.ListByIDsTx` + map build in the package. Add `requireFields(fields map[string]metadatafields.Field, ids [][]byte) error` (ErrInvalid on a missing id). `loadFields` becomes `fieldsByID` then `requireFields` (or is removed with its callers `Set`, `Apply`, `DismissSuggestion`, `Reorder` calling the pair; their behavior unchanged). `listWorkspaces` calls `requireFields(fields, extraIDs)` instead of its own loop.
Check: `grep -n "ListByIDsTx" core/database/sourcemetadata/*.go | grep -v _test` prints exactly one line (inside `fieldsByID`); existing sourcemetadata tests pass; scripts/check-pr.sh PASS.

**F-3 — One per-(type, level) board-input read** (from MNT-3)
Files: `core/database/sourcemetadata/sourcemetadata.go`.
Do: extract the sequence both `listWorkspaces` and `ListDraftWorkspace` run per (type, level) — `sourcetypes.RequirementsTx`, `ListSuggestionsTx`, `needsAt`, then `fieldsByID` over the heads' ids (plus the caller's extras) — into one helper both call, and build `ownerValues` through one constructor. `ListDraftWorkspace` is the one-key case. No behavior change.
Check: `grep -n "RequirementsTx\|ownerValues{" core/database/sourcemetadata/sourcemetadata.go` shows one call site of each, inside the helper / constructor; `TestGetDraftMetadataBoard`, `TestListWorkspacesAnnotations`, `TestDraftBoardScenarios` pass; scripts/check-pr.sh PASS.

**F-4 — One need ordering** (from MNT-2)
Files: `core/citationformat/requirements.go` (+ its test), `core/database/sourcemetadata/annotation.go`.
Failing test first: `TestNeedMax` in `core/citationformat` — table over every pair of `NeedNeeded`, `NeedUsed`, `""`.
Do: add `func (n Need) Max(o Need) Need` (needed > used > none). `add` uses it; delete `stronger` and call `Max` at its sites.
Check: `grep -rn "func stronger" core` prints nothing; scripts/check-pr.sh PASS.

**F-5 — Shared test helpers for a seeded type and a format write** (from MNT-5)
Files: `api/ffi/handlers/harness_test.go`, `api/ffi/handlers/evidence_graphs_test.go`; `core/database/sourcetypes/sourcetypestest/` (new `SetFormats`); the five `update_citation_formats` test sites: `core/database/sourcemetadata/sourcemetadata_test.go` (two), `core/database/sourcevocab/copy_test.go`, `core/database/sourcetypes/formats_test.go`, `core/database/metadatafields/metadatafields_test.go`.
Do: extract `seededTypeID(t, dir, key)` in `harness_test.go` for the "scan `ListSourceTypes` for Key + `OriginProvenencia`" body; `sourceFixture`, `seededSourceOfType` and the copy in `evidence_graphs_test.go:40` call it. Add `sourcetypestest.SetFormats(...)` wrapping `writes.Run(..."update_citation_formats"... sourcetypes.UpdateFormats ...)` and move every one of the five sites onto it (same-pass: all copies). Watch for an import cycle (a `sourcetypestest` import from `sourcetypes`' own internal test is fine only as an external `_test` package; keep that site inline if it would cycle and say so).
Check: `rg -n '"update_citation_formats"' core api -g '*_test.go'` prints only the helper's line (plus any site kept for a cycle, named in the report); `rg -n 'OriginProvenencia' api/ffi/handlers/*_test.go` shows the scan only in `seededTypeID`; scripts/check-pr.sh PASS.

**F-6 — Fuzz the chain-to-board mapping** (from SEC-1)
Files: `core/database/sourcemetadata/annotation_fuzz_test.go` (new) or beside `annotation_test.go`.
Do: `FuzzAnnotate`, seeded from `core/citationformat`'s `FuzzParse` corpus seeds (reuse its seed list; export or copy the seed strings only if no shared seed list exists — prefer a shared one). Body: parse three format strings with `sourcetypes` `Formats.Parse` (or `citationformat.Parse`), `citationformat.Requirements`, `needsAt` at each level, then `annotate` every head with a resolver answering from the fuzz bytes; assert no panic.
Check: `go test -run=^$ -fuzz=FuzzAnnotate -fuzztime=30s ./core/database/sourcemetadata/` (CGO and fts5 tags as the repo uses) runs clean; scripts/check-pr.sh PASS.

**F-7 — § 5.4 order and readers** (from MNT-4)
Files: `docs/source-layer-data-model.md`.
Do: Order bullet: "suggestion, head, then extra" where it says suggestion-then-extra (both places). Lead sentence: name `ListDraftWorkspace` as the second reader of the merge — the draft board of a new Artifact or graph, built against its Source.
Check: scripts/check-pr.sh PASS.
