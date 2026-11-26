# Ship log — S16-70 A Source or Source type delete is learned from the engine

**Plan:** [`S16-70-deletes-from-engine.md`](S16-70-deletes-from-engine.md) · **Branch:** `s16-70-deletes-from-engine` · **PR:** #988
**State:** ready

## Round 0 — implement
Head `ac8306de8`. Gate PASS (orchestrator run). Report deviations: STEP-3/4 and STEP-5 in one commit; three existing tests edited beyond §8 as direct consequences (`lastUpdatedPatchesAreDeclaredOnTheFourLists`, `invalidationsComeFromRegistrySpecs`, `SourceTypesModelTests.createAndDeleteCommitThroughWorkspaceNavigation`); `evidenceGraphEffectsReloadOnlyThatGraph` checks `.changedSourceType` in place of the removed `.deletedSource`; manual check not run.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. Skipped: none (route-reviewers RUN on all four). UX and SEC+PRF: no findings.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1, MNT-2 | CON, MNT | minor | A type delete still reloads the types list through `source_vocabulary`; `completed.md` and the plan say "no reload", and the AC-2.2/2.7 tests use effects the engine never sends | Fix now → F-1 (docs wording, tests use real effects); MNT-2's idea-file line → Follow-up | verified: `registry.go:476-479` `source_types` reports `ListSourceVocabulary` on every delete (no `ListsOnCreateDelete`/`ListsOnField`); `completed.md:7` "and no reload"; plan §Scale line 181. Not a regression: the list reloaded on a type delete before too |
| CON-2, MNT-3 | CON, MNT | minor | Garbled sentence at `macos-client-patterns.md:92` | Fix now → F-2 | verified: `sed -n 92p` |
| MNT-1 | MNT | minor | `.deleted(entity)` slot repeats `deletedHandles`' lookup | Fix now → F-3 (same-pass cleanup; supersedes the plan's Out line "`deletedHandles` read through the new slot") | verified: `CatalogQueryFollows.swift:55`, `CatalogMutation.swift:199`; only two copies in `macos/App` (`rg 'deleted.first'`) |
| MNT-4, CON-3 | MNT, CON | minor | Two edited tests no longer test what their name/comment says | Fix now → F-4 | verified: `CatalogQueryRegistryTests.swift:590-604`, `:859-861` |

Nits (logged): `MNT-5 · CatalogQueryRegistry.swift:28-30 · deletedWith doc says the .handle cap twice` · `MNT-6 · WorkspaceSession.swift:303-304 · apply doc patch order omits deletedRows` · `MNT-7 · CatalogQueryRegistryTests.swift ownIdNamesTheKeysOneRow · checks unrelated to ownId; own test for the slot`

### Fix plan 1
No blocker or major; all four are minors in files this PR adds or changes.

**F-1 — Say that a type delete still reloads the types list** (from CON-1, MNT-2)
Files: `docs/deployment-plan/spike-16/completed.md`, `docs/deployment-plan/spike-16/prs/S16-70-deletes-from-engine.md` (Landed note only; do not edit §Scale or any Decision), `macos/ProvenenciaTests/CatalogQueryRegistryTests.swift`, `macos/ProvenenciaTests/SourceTypePageModelTests.swift`.
Do: `completed.md` S16-70 entry: the types list drops the row at once with one patch (`deletedRows(_:of:)`) and still reloads on the delete's `source_vocabulary` list, as before this PR. Add to the plan's Landed note: the Scale line's "one `removeAll`" is followed by the `source_vocabulary` reload the list already did. In the type-delete tests (`updatedAndDeletedSourceTypePatchTheTypesList` delete case and the page test `deletingLeavesAndDropsTheRow`), script the effects the engine sends: `lists: [.sourceVocabulary]` beside `deleted`. Assert the row is gone from the cached value; drop any "not stale / not fetching" claim that only held for the crafted input, and assert instead that the list is stale or refetching per its `.revalidate` policy.
Check: the tests pass; scripts/check-pr.sh PASS.

**F-2 — Fix the broken sentence** (from CON-2, MNT-3)
Files: `docs/macos-client-patterns.md:92`.
Do: "...the generic `CatalogQueryPatch.row`, which appends only when the mutation creates it; a delete drops its row through `deletedRows(_:of:)` on the `.deleted(entity)` slot)."
Check: `sed -n 92p` reads as one parsed sentence.

**F-3 — One lookup for an entity's deleted ids** (from MNT-1; same-pass cleanup)
Files: `macos/App/Features/Workspace/Session/CatalogMutation.swift`, `macos/App/Features/Workspace/Session/CatalogQueryFollows.swift`.
Do: add `func deletedIDs(of entity: CatalogDeletedEntity) -> [String]` on `CatalogWriteEffects` (beside `deletedHandles`) holding the `first { $0.entity == entity }?.ids ?? []` body; `deletedHandles` returns `deletedIDs(of: .handle)`; the `.deleted(let entity)` case returns `effects.deletedIDs(of: entity)`. Supersedes the plan's Out line on `deletedHandles`; note it in the Landed note.
Check: `rg -n 'deleted\.first' macos/App` prints only the one line inside `deletedIDs(of:)`; scripts/check-pr.sh PASS.

**F-4 — Tests say what they test** (from MNT-4, CON-3)
Files: `macos/ProvenenciaTests/CatalogQueryRegistryTests.swift`.
Do: `lastUpdatedPatchesAreDeclaredOnTheFourLists`: assert the types list has no `lastUpdated` patch (no patch follows `.handle` or `.source` ids), and move the `.deleted(.sourceType)` follow assertion into `updatedAndDeletedSourceTypePatchTheTypesList`. `evidenceGraphEffectsReloadOnlyThatGraph`: delete the "A Source delete names its graphs…" comment and the `.changedSourceType` assertion that replaced the `.deletedSource` line (T-13 said drop). Drop this test from the Landed note's list if it was there; the Landed note's list of tests changed beyond §8 stays accurate.
Check: the tests pass; scripts/check-pr.sh PASS.

## Round 1 — fix
Head `bd74479cf`. Gate PASS (orchestrator run; `origin/main` unmoved at `8d95af5e2`). F-1 to F-4 done; F-1 and F-4 share a commit. Read by the orchestrator: F-1 Resolved (`completed.md:7` and the Landed note name the `source_vocabulary` reload; both type-delete tests script `lists: [.sourceVocabulary]`, assert the row drops before and after the reload). F-2 Resolved (`macos-client-patterns.md:92` parses). F-3 Resolved (`deletedIDs(of:)`; `rg 'deleted\.first' macos/App` prints only its body). F-4 Resolved (types-list test asserts no patch follows `.handle`/`.source`; the stray `.changedSourceType` assertion and comment are gone).

## Round 2 — review
Not run: round 1 had no Fix-now blocker or major.

## Result
Gate PASS · CI pending · open: none · follow-ups: MNT-2 (idea-file line: the types list reloads on its own row's delete through `source_vocabulary`) · to user: —

## Cost
Plan: 6,300 words (check-plan-docs info line).

| Round | Agent | Model | Tokens |
| --- | --- | --- | --- |
| 0 | implementer | sonnet | 193k |
| 1 | CON | opus | 103k |
| 1 | MNT | opus | 103k |
| 1 | UX | opus | 62k |
| 1 | SEC+PRF | opus | 73k |
| 1 | implementer (fix) | sonnet | 86k |
| | **Total** | | **619k** |
