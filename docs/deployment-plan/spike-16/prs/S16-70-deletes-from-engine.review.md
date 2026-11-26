# Review — S16-70 A Source or Source type delete is learned from the engine

**Verdict:** Fits with changes — Ready with changes
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet)

## To user

- ~~M-1: follow the Source types list's `usedBy` through a client "any id" refresh, as the working rule said, or through an engine usage list?~~ **Answered (user, 2026-11-26): the engine usage list `source_type_usage`.** The working rule, the S16-70 scope entry and the slice design are reworded.
- ~~If the usage list is taken, drop `.createdSource` from the Source types list's `invalidateOn` now?~~ **Answered (user, 2026-11-26): drop it in S16-70.** The mutation stays for the Sources list's new row.
- ~~M-8: the Sources list's row would drop twice on a Source delete (the removal patch and the existing `source_holdings` re-read). Keep which?~~ **Answered (user, 2026-11-26): the re-read.** No removal patch on the Sources list (D-9).
- ~~M-9: report `source_type_usage` on a Source type change too, at the cost of one sidebar recount per type change?~~ **Answered (user, 2026-11-26): yes.** `sources` takes `ListsOnField: "source_type_id"`; the types list names no mutation (D-4, D-8).

## Writer's own calls

- D-2: the removal patch takes the deleted entity, not any follow slot.
- D-3: the activity guard moves from `applyPatches` into `lastUpdated`, so a removal never depends on a revision.
- D-6: Go lands first, carrying the Swift enum cases the vocabulary test pins.
- D-7: tests that used `.deletedSource` only to mark a key stale call `session.invalidate(key)`.
- Out: the `engine.proto` comment on `WriteEffects.deleted` stays (still true; an edit regenerates the bindings).
- Version: none.

## Round 1

### X-1 · blocker · STEP-4 writes T-9, which fails until STEP-5
T-9 asserted `.sourcesList` `invalidateOn.isEmpty` (D-5) while STEP-4 kept `.deletedSource` in place.
**Answer:** Fixed. STEP-4 writes T-9 without its `invalidateOn` lines; STEP-5 adds them with D-5 and D-8.

### X-2 · major · The `deleted: [.source: ["s1"]]` form does not exist
**Answer:** Fixed. Every AC and test spells `[CatalogWriteEffectsDeleted(entity:ids:)]`.

### X-3 · major · AC-2.10's third clause has no test and is false as worded
`.sourceWorkspace` still names `.deletedMetadataField`.
**Answer:** Fixed. AC-2.10 now checks `.sourcesList`'s `invalidateOn` is empty and `.sourceTypesList`'s is `[.changedSourceType]`; T-9 asserts both.

### X-4 · minor · T-1 gives no fields for the `source_type` delete
**Answer:** Fixed. T-1 names each change with its fields (`rowchange.Updated` returns a pointer).

### X-5 · minor · `resolveChanges` joins eight inline copies
**Answer:** Fixed with M-3: no helper; T-1 extends the existing table. The package's other inline setups stay (T-1 says so).

### X-6 · minor · `staleKeyQueriedDuringLoadReloads` may stop going stale
**Answer:** Fixed. T-13 names the cause (`fallbacks` for an in-flight first load) and a stop if it does not hold.

### X-7 · nit · AC-3.1 skips the tests folder
**Answer:** Fixed. T-15 adds `rg -n "\.deletedSource(Type)?\b" macos/ProvenenciaTests`.

### M-1 · blocker · `usedBy` should follow an engine usage list, not a client "any id" refresh
The plan put "a Source delete moves the types' `usedBy`" in Swift through a new `applyHiddenPolicy(followsAnyId:)`, beside the engine's `property_usage` and `metadata_field_usage` lists, and could not cover a create.
**Answer:** Fixed with the user's answer. D-4: `ListSourceTypeUsage` / `CatalogList.sourceTypeUsage`, moved by `sources` on create and delete; `.sourceTypesList` follows it with `applyHiddenPolicyOnAny`. `followsAnyId` is gone. D-8 drops `.createdSource` from the types list (user). **Rules this plan bends** records the reworded rule.

### M-2 · major · `.typeSuggestions` should declare `deletedWith: .sourceType`
**Answer:** Fixed. Scope, the Suggestions key row, AC-2.10, AC-2.11 and T-6, T-9; the Out row is gone.

### M-3 · minor · Extend `TestResolveReportsDeleted` instead of a new test and helper
**Answer:** Fixed. T-1 re-keys the table's `want` to `[]effects.DeletedIDs` and adds rows.

### M-4 · minor · `followsAnyId` needs a skill line
**Answer:** Moot: M-1 removed it.

### M-5 · minor · Facts written twice
**Answer:** Fixed in part. The test lines left **Deletes**; `followsAnyId`'s rows are gone with M-1. The Codebase fit "Why not" cells cite the D-# in a clause, which the template asks for.

### M-6 · nit · `isEntityPage` relies on `deletedWith == .handle`
**Answer:** Fixed. The Delete eviction row adds a doc line to `deletedWith`.

### M-7 · minor · Log the handle lists' way of dropping a deleted row
**Answer:** Fixed. An Out row and a STEP-7 line in `docs/ideas/catalog-query-layer.md`.

## Round 2

### X-8 · major · `.createdSource` is left as a kind no descriptor names
**Answer:** Fixed. **Deletes** removes `CatalogMutationKind.createdSource` and its arm; `.createdSource` joins the patch-only nil arm (D-8).

### X-9 · minor · T-8 does not test what D-3 protects
**Answer:** Fixed. T-8 holds the first load, as `patchDuringFirstLoadFallsBack` does, and expects no restart at revision 0.

### X-10 · minor · AC-2.4 and AC-2.5 fixtures do not match `seedStore`
**Answer:** Fixed. T-5 builds its own two-type store.

### X-11 · minor · STEP-7 doc edits leave wording to the implementer
**Answer:** Fixed. STEP-7 quotes the patterns doc's patch-only list before and after, names `.sourceType` on the skill's Mark stale row, and quotes the idea file's line 7.

### X-12 · minor · `.sourcesList`'s `whenHidden` unspecified
**Answer:** Fixed. The Sources list row keeps `whenHidden: .markStale` and its `.merged` refresh.

### M-8 · blocker · A Source delete drops the Sources-list row twice
Every Source delete releases its graph, whose `evidence_graphs` entry reports `source_holdings` for the Source; with `.deletedSource` gone the list's `.merged` re-read runs beside the removal patch. Checked: `onField` reads a delete's old fields, and `releaseGraph` carries `source_id`.
**Answer:** Fixed with the user's answer. D-9: the Sources list keeps its re-read and gets no removal patch; AC-2.1 and T-4 apply the effects a delete really reports; Scale says one by-id read; T-2 pins the `source_holdings` read; a stop condition guards it. The working rule, scope entry and design say so.

### M-9 · blocker · A type change leaves the types list's `usedBy` on a client mutation
**Answer:** Fixed with the user's answer. D-4: `ListsOnField: "source_type_id"` in place of `ListsOnCreateDelete`; D-8: `.sourceTypesList` has no `invalidateOn`; T-16 adds a type-change row; manual check step 5. The Out and Next adds lines for it are gone.

### Round 2 · major · `CatalogMutationKind.createdSource` is dead after D-8
**Answer:** Fixed (same as X-8).

### Round 2 · log · A Source create also reaches the Sources list twice (`sourceRow()` and the `source_holdings` re-read)
**Answer:** Logged: predates this PR; STEP-7's idea-file edit is the home. Not added to the plan's scope.

## Cost

Plan: 4,976 words at round 1, 6,266 at the verdict (check-plan-docs info line).

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| 1 | maintainability | opus | — |
| 1 | executability | sonnet | 146k |
| 2 | maintainability | opus | 160k |
| 2 | executability | sonnet | 177k |
