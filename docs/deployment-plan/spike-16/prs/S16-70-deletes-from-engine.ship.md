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

## User decision (2026-11-26)
MNT-2's follow-up is not parked: slice 6g exists to finish the catalog-query-layer idea, so the user asked for the fix on this PR ("don't add new tasks to it. Just do it."). Supersedes MNT-2's Follow-up decision and the Scale line's "as `.deletedSourceType` does today" reading.

Traced by the orchestrator: on a type delete `source_vocabulary` has three followers. `.sourceTypesList` already drops the row through `deletedRows`. `.typeSuggestions` for that type is evicted through `deletedWith`. `.metadataFieldsList` still needs a signal, because a field's `usedBy` counts the Source types that name it in a citation format. So the delete can stop reporting the list once `.metadataFieldsList` follows `.deleted(.sourceType)` instead.

### Fix plan 1b
**F-5 — A Source type delete moves no `source_vocabulary`** (from MNT-2, CON-1; user)
Files: `core/database/effects/registry.go`, `core/database/effects/lists_test.go` (or wherever `TestResolveLists` lives), `api/ffi/handlers/source_defs_test.go`, `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift`, `macos/App/Features/Workspace/Session/CatalogQueryRefresh.swift` (only if no constructor fits), `macos/ProvenenciaTests/CatalogQueryRegistryTests.swift`, `macos/ProvenenciaTests/SourceTypePageModelTests.swift`, `core/database/effects/README.md`, `docs/deployment-plan/spike-16/completed.md`, the plan's Landed note.
Failing tests first:
- `TestResolveLists`, new row "source type delete": a `rowchange.Deleted("source_type", …)` reports no `source_vocabulary`. A type create, and an update of `label`, still report it.
- `TestDeleteSourceType` "deletes unused user type": the response's lists do not contain `source_vocabulary`, and `deleted` still names the type.
- Swift `updatedAndDeletedSourceTypePatchTheTypesList`: apply the delete with the effects the engine now sends (`deleted` only). Assert the row is gone, `!handle.isStale` and `!handle.isFetching`, which restores the round-0 assertions.
- New Swift test: a warmed `.metadataFieldsList` is marked stale by `CatalogWriteEffects(deleted: [.sourceType ["t-book"]])`.
Do:
- Go: add one opt-out knob on `Effect`, next to `ListsOnCreateDelete` and `ListsOnField`. Call it `ListsNotOnDelete bool` and document it: "a delete does not move Lists; its followers learn it from `Deleted`". Make `movesLists` honour it. Set it on `source_types` only. Keep `source_metadata_fields` as it is.
- Swift: `.metadataFieldsList` adds a refresh on `.deleted(.sourceType)` for any id. Reuse an existing `CatalogQueryRefresh` constructor if one re-applies the hidden policy on any id of a row slot. If none does, add one beside `applyHiddenPolicyOnAny`. Update the key's comment.
- Update the `.sourceTypesList` comment. A type delete now reaches it only through `deletedRows`.
- Revert F-1's script in the page test `deletingLeavesAndDropsTheRow` to `deleted` only.
- Docs:
  - effects README: the knob, and that a `source_types` delete reports `Deleted` with no list.
  - `completed.md`: the types list drops the row with one patch and no reload.
  - The Landed note: F-5, superseding the F-1 wording and MNT-2's follow-up.
Stop if: some other follower of `source_vocabulary` (Swift or Go) needs a type delete and is not covered above. Report it; do not widen the change.
Check: the tests above pass, `rg -n 'sourceVocabulary' macos/App` shows the three followers unchanged, and scripts/check-pr.sh PASS.

## Round 1b — fix
Head `23f5165e5`. Gate PASS (orchestrator run). F-5 done, with the new tests run red first. Deviation: `vocabulary_write_effects_test.go` `TestVocabularyWritesReturnEffects` expected `source_vocabulary` on a type delete and was updated to match.

## Round 2 — review
Scope `362e82f91...23f5165e5`. Reviewers: CON, MNT. These two because F-5 is new design added after round 1 on the user's direction. Skipped: UX (no visible change, no strings), SEC+PRF (the change only removes a reload and adds no input or loop). CON: clean.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-8 | MNT | blocker | The field list's `usedBy` follows a Swift "any deleted type id" refresh, where it should follow an engine usage list | Fix now → F-6 | verified: `S16-70…review.md:48-50` M-1 rejected `followsAnyId` for `usedBy`. `CatalogQueryRefresh.swift:146-151` `applyHiddenPolicyOnAnyID` has the same body as the removed shape. `registry.go:129-132` `ListMetadataFieldUsage` exists so that "the field list's usedBy counts changed". This is an orchestrator error in Fix plan 1b, which offered "add one beside `applyHiddenPolicyOnAny`" |

Nits (logged): `CON-4 · registry.go:121 · ListSourceVocabulary doc: a type delete reports Deleted instead` · `CON-5 · add-workspace-place SKILL.md:181, macos-client-patterns.md:89 · say a key counting types learns a type delete another way` · `CON-6 · registry.go:330 · rewrap movesLists comment` · `MNT-9 · registry.go:200-214 · three Effect fields for "which changes move Lists"; README "one choice per entry"` · `MNT-10 · moot once F-6 deletes applyHiddenPolicyOnAnyID`. F-6 rewrites the lines CON-4, CON-5 and MNT-9 name, so it covers them.

### Fix plan 2
**F-6 — A Source type delete reports `metadata_field_usage`, not a client "any id" refresh** (from MNT-8; covers CON-4, CON-5, CON-6, MNT-9, MNT-10)
Files: `core/database/effects/registry.go`, `core/database/effects/lists_test.go`, `core/database/effects/README.md`, `api/ffi/handlers/source_defs_test.go`, `api/ffi/handlers/vocabulary_write_effects_test.go`, `macos/App/Features/Workspace/Session/CatalogQueryRefresh.swift`, `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift`, `macos/ProvenenciaTests/CatalogQueryRegistryTests.swift`, `.agents/skills/add-workspace-place/SKILL.md`, `docs/macos-client-patterns.md`, the plan's Landed note.
Failing tests first:
- `TestResolveLists` "source type delete" expects `[metadata_field_usage]`.
- `TestDeleteSourceType` "deletes unused user type" and `TestVocabularyWritesReturnEffects` (type delete) expect lists `[metadata_field_usage]` and `deleted` naming the type.
- Swift `sourceTypeDeleteMarksTheFieldsListStale` scripts `CatalogWriteEffects(lists: [.metadataFieldUsage], deleted: [.sourceType ["t-book"]])` and expects the field list stale.
- `updatedAndDeletedSourceTypePatchTheTypesList` applies those same effects and still asserts `!isStale` and `!isFetching`, since the types list does not follow `metadata_field_usage`.
Do:
- Go: replace `ListsNotOnDelete bool` with `ListsOnDelete []List`, documented as "when set, a delete moves these lists in place of `Lists`". `movesLists` and the effect assembly use it for `ActionDelete`. Validate it as before: it needs `Lists` and `Deleted`, and `metadataEffects` refuses it. On `source_types` set `ListsOnDelete: []List{ListMetadataFieldUsage}`.
- Extend the `ListMetadataFieldUsage` doc: "or a Source type whose citation formats can name fields was deleted". Extend the `ListSourceVocabulary` doc: a type delete reports `Deleted` and `metadata_field_usage` instead (CON-4). Rewrap the `movesLists` comment (CON-6).
- Swift: delete `applyHiddenPolicyOnAnyID` and the `.deleted(.sourceType)` refresh on `.metadataFieldsList`. The existing `.applyHiddenPolicyOnAny(follows: .list(.metadataFieldUsage))` covers the delete. Update the key's comment.
- Docs: README "which changes move Lists" wording names the three knobs (MNT-9). Add the sentence CON-5 asks for to the `add-workspace-place` Vocabulary CRUD line and `macos-client-patterns.md:89`: a type delete reports `Deleted` and `metadata_field_usage`, not `source_vocabulary`. Update the Landed note: F-6 replaces F-5's Swift refresh.
Check: the tests above pass. `rg -n 'applyHiddenPolicyOnAnyID|ListsNotOnDelete' core api macos .agents docs` prints only the ship log's history. scripts/check-pr.sh PASS.

## Round 2 — fix
Head `af2f2eb72`. Gate PASS (orchestrator run). F-6 done. The Go tests ran red first (`TestResolveLists/source_type_delete`, `TestDeleteSourceType/deletes_unused_user_type`, `TestVocabularyWritesReturnEffects`). The Swift tests could not go red, because the F-5 refresh still marked the list stale; they now pass on `metadata_field_usage` alone. Deviation: `validate` also checks that `ListsOnDelete` names declared lists.
Read by the orchestrator: MNT-8 **Resolved**. `ListsOnDelete: []List{ListMetadataFieldUsage}` on `source_types`; `listsFor` in `resolve.go`; `applyHiddenPolicyOnAnyID` and its refresh are deleted. CON-4, CON-6 and MNT-9 are covered by the doc rewrites. `completed.md:7` still said the field list "follows `deleted`" (the implementer looked for `docs/deployment-plan/completed.md`); the orchestrator fixed that line in `ce4249b60`.
Then merged `origin/main` (`d57b0d9e5`, S15-59 plan docs only): `9adca9927`. Gate PASS.

## Result
Gate PASS · CI green (test ×2, localizable) on `0a5ca6e6f` · open: none · follow-ups: none (MNT-2 fixed on this PR on the user's direction) · to user: —

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
| 1b | implementer (fix) | sonnet | 100k |
| 2 | CON | opus | 56k |
| 2 | MNT | opus | 62k |
| 2 | implementer (fix, stopped: plan missing) | sonnet | 74k |
| 2 | implementer (fix) | sonnet | 96k |
| | **Total** | | **1,008k** |
