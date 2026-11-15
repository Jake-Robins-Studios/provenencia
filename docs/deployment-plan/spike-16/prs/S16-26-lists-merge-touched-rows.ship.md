# Ship log — S16-26 Conclusion lists merge the rows a write touched

**Plan:** [`S16-26-lists-merge-touched-rows.md`](S16-26-lists-merge-touched-rows.md) · **Branch:** `s16-26-lists-merge-touched-rows` · **PR:** #851
**State:** fixing 1

## Round 0 — implement
Base `887339a` (`main`; plan was written against `3667125`).
Head `6dc0666`. Gate PASS (orchestrator run: all nine checks). PR #851 (draft).
Report deviations (also in the plan's Landed note): STEP-2/3 as two commits; STEP-5–7 as one commit (store signature change breaks every Swift test until rewritten); version bump rides the docs commit; Go tests reach key functions through `export_test.go` hooks; `list_keys.json` also stores each row's input; extra Swift test `mergeSortedKeepsFreshRowsInKeyOrder`; T-14 hidden half on a second session in the same test; benchmark reports first read after each write; base moved `3667125` → `887339a` with no Current-state row affected. §10 manual check not run (needs the user).
Implementer's earlier gate runs: one `persondetail.TestLifelineOrderLargeBudget` timing miss (2.59 ms vs 2 ms, under load, unrelated code) and one hung xcode-test after suites passed; neither recurred.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. UX: diff touches `macos/App/**`. SEC+PRF: `api/ffi/**` (new id filter on list RPCs), `core/database/**` (filtered list reads and sort keys).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| PRF-1 | PRF | major | Swift merge visits every row of every loaded list per write on the main actor (hidden lists too, D-9); never measured | Split: measurement **Fix now → F-4**; index **To user → Fix now → F-6** (user, 2026-11-15: index in this PR, supersedes D-8's one-pass shape) | Verified: `mergeSorted` (`CatalogLastUpdated.swift:38-63`) filters and rebuilds the whole array; reviewer's `swiftc -O` copy: 4.1–6.8 ms at 20,115 rows, 17–21 ms at 80,000. Plan §6 Scale gives no Swift time. An id→key index contradicts D-8's chosen shape and re-weighs the user's D-9 choice → user |
| CON-1 | CON | major | add-workspace-place still sends "any id" keys to `applyHiddenPolicyOnAny`, which D-10 now refuses for row slots; the function's doc says the same | Fix now → F-1 | Verified: `SKILL.md:63` "or `applyHiddenPolicyOnAny(follows:)` when any id will do"; `CatalogLastUpdated.swift:415-419` doc vs `precondition(follows.isCatalogWide, …)` |
| CON-2, MNT-1 | CON, MNT | minor | `listKeyProto` inserted under `termProto`'s doc comment | Fix now → F-2 | Verified: `conclusion_summaries.go:104-110` |
| SEC (outside lens, MNT) | MNT | minor | `CatalogListKey`'s synthesized `==` compares `ref` as a Swift `String` (canonical equivalence) while `<` compares UTF-8 bytes, so `==` and `<` can both hold | Fix now → F-3 | Verified: `GenealogyStore.swift:476-485`, `Equatable` synthesized; code this PR adds. Crafted refs only, order only; cheap to make agree |
| CON-3 | CON | nit → minor | T-19 drops `listsAreQuiet()` and the Events/Places recorders the plan's T-19 names | Fix now → F-5 (rides along) | Verified: `WorkspaceSessionTests.swift:1108-`; plan T-19 row |
| MNT-4 | MNT | nit | `sourceWriteEffectsPatchSourcesAndLeaveListsAlone` no longer leaves lists alone | Fix now → F-5 (same test) | |
| MNT-3 | MNT | nit | Back-to-back parentheticals in the skill's Mark stale row | Fix now → F-1 (same skill edit) | |
| MNT-2 | MNT | minor | FakeStore keeps `listPersonSummariesCalls` beside `listPersonSummariesEntityIDs`, which always agree | **To user → Fix now → F-7** (user, 2026-11-15: remove; supersedes D-12's "keeps counting") | D-12 says "`listPersonSummariesCalls` keeps counting every call"; removing it contradicts a Decision |
| UX → CON (outside lens) | CON | — | Does a Person rename reach the Event rows that name it? | Rejected | The merge follows `.touchedHandles` = `handles ∪ summaryHandles` (`CatalogMutation.swift:152`), where `summaryHandles` is S14-42's input-index `SummaryDeps` (`core/writes/run.go:88`), the same set Go's display cache drops (`graphcache/commit.go:128`); T-9 checks five writes against a full reload |
| SEC → CON (outside lens) | CON | — | Plan §6 Edges (b): lowercased refs may collide (`PRS-1` vs `prs-1`) | Rejected | Crafted catalog only; result is a tie broken differently, order only, no crash (working rule: adversarial-only costs get no design) |

Nits (logged): `UX-1 · ConclusionListPage.swift:18 · empty list with a merge in flight shows a blank body for a few ms (predates the PR)` · `MNT-5 · CatalogLastUpdated.swift:24 · file name no longer fits its contents; later tidy`

### Fix plan 1

**F-1 — Skill and doc send row slots to `applyHiddenPolicy(follows:ids:)`** (from CON-1, MNT-3)
Files: `.agents/skills/add-workspace-place/SKILL.md`, `macos/App/Features/Workspace/Session/CatalogLastUpdated.swift`. Skill: `add-workspace-place`.
Failing test first: none (a precondition trap; the evidence is the grep).
Do: In the Refresh row, replace "or `applyHiddenPolicyOnAny(follows:)` when any id will do" so a row slot uses `applyHiddenPolicy(follows:ids:)` (or `followsValue` / `followsOwnId`) and `applyHiddenPolicyOnAny(follows:)` is for catalog-wide slots (`.list(…)`, `.structure`) only; merge that with the following sentence so the rule is said once. In the Mark stale row, fold the two back-to-back parentheticals into one sentence. Reword `applyHiddenPolicyOnAny`'s doc to "whenever the write reports the catalog-wide slot".
Check: `rg -n "when any id will do|names any id" .agents macos/App docs` prints nothing; scripts/check-pr.sh PASS.

**F-2 — `termProto` gets its doc comment back** (from CON-2, MNT-1)
Files: `api/ffi/handlers/conclusion_summaries.go`.
Do: move "// termProto is the one Go mapper …" from above `listKeyProto` to directly above `func termProto`.
Check: `go vet ./api/...`; scripts/check-pr.sh PASS.

**F-3 — `CatalogListKey`'s `==` agrees with its `<`** (from SEC outside-lens note)
Files: `macos/App/Platform/GenealogyStore.swift`, `macos/ProvenenciaTests/CatalogListMergeTests.swift`.
Failing test first: `CatalogListMergeTests/listKeyEqualityIsByteWise` — two keys equal but for `ref` "\u{e9}" vs "e\u{301}" → `!(a == b)` and exactly one of `a < b`, `b < a`.
Do: write `static func ==` comparing `last`, `primary`, and `ref.utf8` elementwise (`a.ref.utf8.elementsEqual(b.ref.utf8)`), beside the existing `<`.
Check: the test passes; scripts/check-pr.sh PASS.

**F-4 — Measure the Swift merge at Scale** (from PRF-1, measurement part; working rule "Measure growth")
Files: `macos/ProvenenciaTests/CatalogListMergeTests.swift`, the plan's §6 Scale, this ship log (orchestrator records the figures you report).
Do: add `mergeSortedAtScaleStaysUnderCeiling`: build 20,115 `CatalogPersonSummary` rows in key order (UUID ids, `Data` keys shaped like real collation keys), then time `mergeSorted` with one fresh row replacing two ids, best of 5; assert under a named ceiling `// decided: S16-26 F-4` set from the Debug measurement with headroom to catch a slip to O(n·k) (say 5× measured). Also run the same body once at 80,000 rows (report only, no assert). Report the Debug figures, and Release figures from a `swiftc -O` harness in your scratch space that copies `mergeSorted` and `CatalogListKey` as they are at head (do not commit the harness). Add one bullet to the plan's §6 Scale: "Swift merge, per loaded list per write: <Debug> / <Release> at 20,115 rows, <…> at 80,000; linear in the list, now paid by hidden lists too (D-9)." Do not change the merge itself.
Check: the test passes; scripts/check-pr.sh PASS.

**F-5 — T-19 checks what the plan's T-19 names** (from CON-3, MNT-4)
Files: `macos/ProvenenciaTests/WorkspaceSessionTests.swift`.
Do: rename `sourceWriteEffectsPatchSourcesAndLeaveListsAlone` to `sourceWriteEffectsPatchSourcesAndMergeOnlyTouchedListRows`; after `settleWrites()` assert `listsAreQuiet()` and check `listEventSummariesEntityIDs` and `listPlaceSummariesEntityIDs` as well as the Persons recorder, per the plan's T-19 row.
Check: the test passes; scripts/check-pr.sh PASS.

### Fix plan 1b (after the user's answers, 2026-11-15)

Runs after Fix plan 1 lands, on top of its head.

**F-6 — The three lists hold an id→key index, so a write costs its rows, not the list** (from PRF-1; user chose "index in this PR"; supersedes D-8's "one pass over the list")
Files: `macos/App/Features/Workspace/Session/CatalogLastUpdated.swift`, `CatalogQueryRegistry.swift`, `WorkspaceSession.swift` if `refreshCached`'s generic needs it, `macos/App/Features/Conclusions/ConclusionListPage.swift` (reads `QueryRead<CatalogListRows<Row>>`, hands `.rows` to the presentation it has today), `macos/ProvenenciaTests/CatalogListMergeTests.swift`, `WorkspaceSessionTests.swift`, `CatalogQueryRegistryTests.swift`, `PersonsListTests.swift` and any other test that types these three keys' value. Skill: `add-workspace-place`, `add-swift-test`.
Failing tests first, in `CatalogListMergeTests`:
- `listRowsMergeMatchesMergeSorted`: a seeded random generator (fixed seed, 500 cases): random sorted rows (0–200, some equal keys), random `ids` and `fresh` (0–20 each, some overlapping, some unknown ids) → `CatalogListRows(rows).merging(fresh, replacing: ids).rows == { var a = rows; a.mergeSorted(fresh, replacing: ids); return a }()`, on both the indexed path and the fallback (force each with a test-only threshold parameter).
- `listRowsMoveActivityTouchesOnlyNamedRows`: `moveActivity(ids:activity:)` moves only the named rows with an older revision and returns whether any moved, the same as the array scan.
- `listRowsAtScaleStaysUnderCeiling`: replaces F-4's ceiling test's subject: at 20,115 rows, one fresh row replacing two ids, best of 5, asserts under a ceiling `// decided: S16-26 F-6` (set from the Debug measurement, 5× headroom); keep F-4's `mergeSortedAtScale…` test as the fallback's measurement.
Do:
1. `struct CatalogListRows<Row: CatalogListRow>: Sendable, Equatable (where Row: Equatable), RandomAccessCollection, ExpressibleByArrayLiteral` *(new)* in `CatalogLastUpdated.swift`, beside `mergeSorted`: `private(set) var rows: [Row]` and `private var keys: [String: CatalogListKey]` (id → the row's current `listKey`), built in `init(_ rows: [Row])` (rows arrive in Go's key order; the init does not sort). Collection conformance forwards to `rows` (`startIndex`, `endIndex`, `subscript`), so readers that iterate, count or index keep working. Every mutation goes through the methods below, which keep `keys` in step.
2. `mutating func merge(_ fresh: [Row], replacing ids: [String])`: let `touched = Set(ids) ∪ fresh ids`. If `touched.count > max(32, rows.count / 16)` (`static let indexedMergeLimit`, `// decided: S16-26 F-6`: past it, k removals' memmoves cost more than one pass), run `rows.mergeSorted(fresh, replacing: ids)` and rebuild `keys`. Otherwise, for each id in `touched` with an entry in `keys`: binary-search the lower bound of its key in `rows` (`CatalogListKey.<`), walk the equal-key run to the row with that id, `remove(at:)`, drop the `keys` entry. Then for each `fresh` row in stable key order (as `mergeSorted` sorts `added`): binary-search the upper bound of its key (a fresh row goes after kept rows with an equal key, and after earlier fresh rows with an equal key), `insert(_:at:)`, set `keys[row.id]`. The result equals `mergeSorted`'s (the first test proves it).
3. `mutating func moveActivity(ids: Set<String>, activity: CatalogActivity) -> Bool` for `CatalogListRows` where `Row: CatalogLastUpdatedRow`: for each id with a key, binary-search to the row and move `updated` forward as `lastUpdated` does today. Give `[Row]` the same method (the scan `lastUpdated` has now) through one protocol `CatalogLastUpdatedRows` *(new)*, and change `CatalogQueryPatch.lastUpdated` to be generic over `Rows: CatalogLastUpdatedRows` (`lastUpdated([CatalogSource].self, …)`, `lastUpdated(CatalogListRows<CatalogPersonSummary>.self, …)`), so there is still one `lastUpdated` constructor and the Sources list keeps its scan.
4. `mergedRows` caches `CatalogListRows<Row>` and merges through `merge(_:replacing:)`; the three list descriptors' `load` returns `CatalogListRows(try await store.list…Summaries(…, entityIDs: nil))`, and their `lastUpdated` patch names `CatalogListRows<…>.self`. `Array.mergeSorted` stays as the fallback and the reference the tests compare against.
5. Update F-4's Scale bullet in the plan with the indexed figure beside the one-pass figure, and add one line to the plan's Landed note: "F-6 (user, 2026-11-15): the lists hold an id→key index (`CatalogListRows`); supersedes D-8's one-pass merge, which stays as the fallback past `indexedMergeLimit`." Update `add-workspace-place`'s Refresh row ("`CatalogQueryRefresh.mergedRows` … rows placed by `CatalogListKey`") to name `CatalogListRows` as the value a Go-ordered list caches, and `docs/macos-client-patterns.md` if it names the list value type.
Check: the three tests pass; `rg -n "QueryHandle<\[Catalog(Person|Event|Place)Summary\]>" macos` prints nothing; scripts/check-pr.sh PASS. Report the Debug and Release (`swiftc -O` scratch harness, not committed) figures at 20,115 and 80,000 rows for the indexed path and the fallback.

**F-7 — FakeStore has one recorder per list read** (from MNT-2; user chose "remove"; supersedes D-12's "`listPersonSummariesCalls` keeps counting every call")
Files: `macos/App/Platform/FakeStore.swift`, `macos/ProvenenciaTests/WorkspaceSessionTests.swift`.
Do: delete `listPersonSummariesCalls` and its increment; its one reader (now in `sourceWriteEffectsPatchSourcesAndMergeOnlyTouchedListRows` after F-5) asserts on `listPersonSummariesEntityIDs` exactly. Add one line to the plan's Landed note: "F-7 (user, 2026-11-15): `listPersonSummariesCalls` removed; supersedes D-12's wording."
Check: `rg -n listPersonSummariesCalls macos docs .agents .cursor` prints nothing outside the plan's D-12 row and Landed note; scripts/check-pr.sh PASS.

## Round 1 — fix (Fix plan 1)
Head `178c241`. Gate PASS (orchestrator run). F-1 to F-5 done. F-3 test ran red first (`!(a == b)` false for "é" vs "e\u{301}"). F-4 figures, `mergeSorted` one fresh row replacing two ids: Debug 23.0 ms at 20,115 rows, 106.5 ms at 80,000; Release (`swiftc -O` harness) 3.6–4.3 ms at 20,115, 13.9–14.1 ms at 80,000. Ceiling 120 ms (`// decided: S16-26 F-4`). Scale bullet added to the plan.
