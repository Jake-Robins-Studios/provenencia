# Ship log — S16-27 One primitive for values derived from cached data

**Plan:** [`S16-27-derived-values.md`](S16-27-derived-values.md) · **Branch:** `s16-27-derived-values` · **PR:** #854
**State:** ready

## Round 0 — implement
Head `763bc0e7c`. Gate PASS (orchestrator run, against `180ab7233`). Report deviations: version bumped 0.15.5 → 0.15.6 (S15-49 had already taken 0.15.5; plan header updated); STEP-1 and STEP-2 in one commit (neither compiles alone); T-10 writes the term through `confirmCustomTerm` with the term-valued `role` Property; base moved 38 commits past `1f52b60`, Current state rows rechecked and unchanged. AC-1.7 (T-15) and the §10 manual check not run (need a person at the app).

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. Skipped: none. UX for `macos/App/**`; SEC+PRF for `macos/App/Features/**` models and session cache code (performance paths).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| SEC-1 | SEC | major | One entity id opened as two Conclusion page kinds traps in `typed` | Fix now → F-1 | verified: `DerivedValueID.conclusionContent(CatalogQueryKey)` carries no content type; Person/Event/Place detail pages share `.conclusionDetail(entityId:)` and the `NameFormatOrders` extra, so a hit on the other kind reaches `preconditionFailure` (`WorkspaceSession+Derived.swift:175-179`) |
| CON-1 | CON | major | AC-1.7 unproven; §10 step 8 crashes on `keys[2]` before the D-10 assertion | Fix now → F-2 | verified: `cachedEvidenceGraphSnapshot` indexes `keys[2]` of the same array step 8 shortens |
| MNT-1 | MNT | major | `Memo.value(for:build:)` dead after this PR | Fix now → F-3 | verified: only caller left is `MemoTests.buildsOncePerKey` |
| UX-1, CON-2 | UX, CON | minor | `Locale.autoupdatingCurrent` in section extras never compares unequal; detail pages carry no locale | Rejected (user) | user, 2026-11-15: a Region or date-format change is very rare; no per-value locale plumbing. When a locale option exists in the app, it rebuilds the whole cache as if the project were opened fresh. D-19 stands |
| MNT-2 | MNT | minor | Third identical `detail(_:)` test fixture | Fix now → F-4 | same-pass cleanup; three copies at `WorkspaceSessionTests.swift:1221`, `ConclusionContentTests.swift:16`, `WorkspaceSessionDerivedTests.swift:16` |
| CON-3 | CON | minor | "Write to a non-input key" steps never move a revision | Fix now → F-5 | verified: `.entityPage` keys are `whenHidden: .markStale`; `markStale()` only sets `isStale` |
| PRF-1 | PRF | minor | Per-graph derived entries never drop: `evidenceGraph` keys are never evicted | Fix now (doc correction) → F-6; Follow-up (graph key lifetime) | verified: `.evidenceGraph` descriptor has no `deletedWith`; `evict(_:)` is the only `dropDerived` caller |
| CON (outside lens, PRF) | PRF | minor | Two windows share one `.conclusionContent` slot and thrash | Rejected | `WorkspaceSession` is created per `WorkspaceView` (`WorkspaceView.swift:32`); windows do not share slots |

Nits (logged): `UX-2/MNT-5 · EvidenceGraphModel.swift:1352 · guard let _ … reads as a leftover` · `MNT-3 · CitationComposerContext.swift:59,179 · termKeys(in:) recomputes termIDs` · `MNT-4 · WorkspaceSession+EvidenceGraphs.swift:179-198 · keys[0..2] by position` · `MNT-6 · macos-client-patterns.md:93 · rule 5 omits connectRules` · `MNT-7 · WorkspaceSession+Derived.swift:145 · conclusionContent forwarder in the generic file` · `CON-4 · theHiddenEntityCapDropsValuesAndTheirDependants · assert entries exist first` · `CON-5 · aTermWriteRebuildsTheVocabularyOnce · pin before count`

### Fix plan 1

**F-1 — The content id names its content type** (from SEC-1)
Files: `macos/App/Features/Workspace/Session/WorkspaceSession+Derived.swift`, `macos/ProvenenciaTests/WorkspaceSessionDerivedTests.swift`.
Failing test first: `WorkspaceSessionDerivedTests.oneKeyHoldsOneValuePerContentType` *(new)* — on one `.conclusionDetail` key, call `conclusionContent` with the same `extra` and two different `Content` types (for example `String` then `Int`); today the second call traps in `typed`. Expect both values, each built once.
Do: change `DerivedValueID.conclusionContent(CatalogQueryKey)` to `conclusionContent(CatalogQueryKey, ObjectIdentifier)` and have `conclusionContent` pass `ObjectIdentifier(Content.self)`. Keep `typed`'s `preconditionFailure` for real programming errors. Update every match on the case (`rg -n "conclusionContent\(" macos`).
Check: the test passes; scripts/check-pr.sh PASS.

**F-2 — Prove the undeclared-read check fires** (from CON-1; takes nit MNT-4)
Files: `WorkspaceSession+Derived.swift`, `WorkspaceSession+EvidenceGraphs.swift`, `WorkspaceSessionDerivedTests.swift`, the plan's §10 step 8.
Failing test first: `WorkspaceSessionDerivedTests.aBuildThatReadsAnUndeclaredKeyIsReported` *(new)* — a `derived` build whose closure calls `session.queryHandle` on a key that is not in `inputs`; expect the debug-only record of undeclared reads for that id to name the key.
Do: in `#if DEBUG`, factor the D-10 comparison into an internal helper that returns the undeclared keys (for example `derivedUndeclaredReads`), store the last result per id, and have `derived` call `assertionFailure` when it is non-empty, as today. The test reads the stored result; give the helper a way to skip the assertion under test only if the assertion would otherwise stop the test process (a test-only flag on the session is fine). In `cachedEvidenceGraphSnapshot`, replace `keys[0]`/`keys[1]`/`keys[2]` with named keys (a small struct or tuple of rows, properties, rules, plus its `inputs` list) so removing an input cannot index out of range. Rewrite §10 step 8 to remove the rules key from the inputs list only, and note the change in the plan's Landed note.
Check: the test passes; `rg -n "keys\[[0-9]\]" macos/App/Features/Workspace/Session/WorkspaceSession+EvidenceGraphs.swift` prints nothing; scripts/check-pr.sh PASS.

**F-3 — Delete `Memo.value(for:build:)`** (from MNT-1)
Files: `macos/App/Platform/Memo.swift`, `macos/ProvenenciaTests/MemoTests.swift`.
Do: delete the build overload; rewrite `MemoTests` to cover `value(for:)` and `store(_:for:)`; narrow `Memo`'s doc to the one-slot store `derived` and the depiction preview keep.
Check: `rg -n "value\(for:.*build:|func value\(for key: Key, build" macos` prints nothing; scripts/check-pr.sh PASS.

**F-4 — One `catalogConclusionDetail` fixture** (from MNT-2, same-pass cleanup)
Files: `macos/ProvenenciaTests/CatalogFixtures.swift`, `WorkspaceSessionTests.swift`, `ConclusionContentTests.swift`, `WorkspaceSessionDerivedTests.swift`.
Do: add `func catalogConclusionDetail(_ id: String) -> CatalogConclusionDetail` beside `catalogArtifact(_:)` with the shared body; move all three copies onto it.
Check: `rg -n "CatalogConclusionDetail\(entity: CatalogCanonicalEntity\(id: id, ref: \"PER-" macos/ProvenenciaTests` prints only the line in `CatalogFixtures.swift`; scripts/check-pr.sh PASS.

**F-5 — The non-input write moves a revision** (from CON-3; takes nits CON-4, CON-5)
Files: `WorkspaceSessionDerivedTests.swift` (`anApplyThatRefreshesAnInputBuildsAgain`, `theHiddenEntityCapDropsValuesAndTheirDependants`), `ConclusionContentTests.swift` (`sectionContentBuildsOncePerReadAndFold`), `CitationComposerModelTests.swift` (`aTermWriteRebuildsTheVocabularyOnce`).
Do: in the "e2" steps, move e2's key for real (`setQueryValue` on e2's `.conclusionDetail` / `.personEvents` key), first `#expect` its `inputRevision` changed, then assert the build count is unchanged. Assert both entries exist before the cap evicts in T-5. Pin the exact `before` count in the composer test.
Check: the tests pass; scripts/check-pr.sh PASS.

**F-6 — Say how long per-graph entries live** (from PRF-1, doc part)
Files: the plan's Design "Removed inputs" line and Scale paragraph (via the Landed note), `docs/catalog-caches.md` "Derived values" row.
Do: state that `evidenceGraph` keys are never evicted, so a graph's snapshot, card text and composer vocabulary last for the window's session, like its rows handle. No code change.
Check: scripts/check-pr.sh PASS (plan-docs).

## Round 1 — fix
Head `d398fe692`. Gate PASS (orchestrator run). F-1 – F-6 done. Deviations: F-2's debug record and test flag are `#if DEBUG` stored properties on `WorkspaceSession` (`derivedUndeclaredReads`, `derivedAssertsUndeclaredReads`); F-5 pins the composer's `before == 2` from the first run.

## Round 2 — review
Reviewers: CON (CON-1), MNT (MNT-1), SEC+PRF (SEC-1). Scope `763bc0e7c...d398fe692`. Skipped: UX (no Fix-now blocker or major; UX-1 rejected by the user).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| SEC-1 | SEC | major | (round 1) | Resolved | `conclusionContent(CatalogQueryKey, ObjectIdentifier)`; `oneKeyHoldsOneValuePerContentType` |
| CON-1 | CON | major | (round 1) | Resolved | `aBuildThatReadsAnUndeclaredKeyIsReported`; `EvidenceGraphSnapshotKeys` named fields; §10 step 8 rewritten |
| MNT-1 | MNT | major | (round 1) | Resolved | overload deleted; `MemoTests.holdsTheValueOnlyForItsKey` |
| MNT-2 | MNT | minor | (round 1) | Resolved | orchestrator read `29545e66a`: one `catalogConclusionDetail` in `CatalogFixtures.swift`, three copies gone (MNT round 2 agrees) |
| CON-3 | CON | minor | (round 1) | Resolved | orchestrator read `29545e66a`: e2 steps `setQueryValue` and expect `inputRevision` to move first (CON round 2 agrees) |
| PRF-1 | PRF | minor | (round 1, doc part) | Resolved | orchestrator read `d398fe692`: `catalog-caches.md` row and plan "Removed inputs"/Scale say `evidenceGraph` keys are never evicted. Lifetime part stays a Follow-up |

No new findings. Nits (logged): `MNT-8 · WorkspaceSession+Derived.swift:72 · derivedUndeclaredReads[id] not cleared by dropDerived (debug only)`

## Result
Gate PASS (`d398fe692`, `origin/main` unmoved at `180ab7233`) · CI see PR · open: none · follow-ups: PRF-1 (give `evidenceGraph` keys a lifetime: evict on Source delete or cap hidden graphs) · to user: UX-1/CON-2 answered (Rejected; D-19 stands)
