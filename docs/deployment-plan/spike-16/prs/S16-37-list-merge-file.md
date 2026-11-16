# S16-37 — The list merge has a file of its own and no test-only parameters

**Status:** Landed in [#858](https://github.com/mendahu/provenencia/pull/858) (2026-11-16)
**Spike / slice:** Spike 16 · Slice 2e — The app's cache
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: code moves between files and a test-only parameter goes; nothing a researcher sees changes)
**Board:** —
**Depends on:** S16-26 (landed [#851](https://github.com/mendahu/provenencia/pull/851): `CatalogListRows`, `indexedMergeLimit`, `CatalogListMergeTests`)
**Blocks:** —
**Branch:** `s16-37-list-merge-file`
**Version bump:** none — no behavior changes, as for S16-03's file split ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md), [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md) (Refresh row, for the names it cites)
**Rules that bind:** `.cursor/rules/macos-client.mdc`, `.cursor/rules/swift-tests.mdc`
**Context:** S16-26 ship log ([`S16-26-lists-merge-touched-rows.ship.md`](S16-26-lists-merge-touched-rows.ship.md), nits MNT-5 and MNT-7, fix F-9); working rule "(Batch 2) The point of this batch is simpler code"
**Planned:** 2026-11-16 against `main` @ `04e76c4`
**Review:** [`S16-37-list-merge-file.review.md`](S16-37-list-merge-file.review.md) — Fits with changes — Ready with changes, 1 round; no blocker; To user: none

**Runs on macOS.** STEP-1's build check, STEP-3 and STEP-4 need `xcodebuild`; STEP-1's move checks (`git diff`, `rg`) run anywhere. On a machine without it, stop after reading and report that the steps need a macOS runner.

### Implementer — read this first

1. **This file is the whole task.** Read it top to bottom before you change code. Then read every file under **Current state** and load every skill under **Skills to load**.
2. **Check the base.** Compare `main` with the **Planned** commit. If a file under **Current state** has changed so a row is no longer true, stop and report which rows.
3. **Decisions are made.** Do not reopen a **Decision** or a **Scope** line, and do not swap in a design you like better. If one cannot work, stop: say which ID it is, what you found (path, line, output), and what you would need. Do not improvise around it.
4. **Do only In.** Out stays out, even when it is one line away. Do not refactor, rename, or tidy code the plan does not name.
5. **Work the Steps in order.** Run each step's check before you start the next. A failing check is fixed in that step.
6. **Hit a Stop condition → stop.** Report it. Do not work around it.
7. **Done is the Definition of done.** Report each box with its evidence: the command and its result, the test name, or the manual check you ran.
8. **Docs-only lines in the DoD are part of the PR.** Do not skip them.

---

## 1. Objective

The Conclusion lists' merge (S16-26) landed inside `CatalogLastUpdated.swift`, a file named for last-updated cells, and its `merge` takes an `indexedLimit:` parameter that only tests pass, with a `merging` copy that only tests call. This PR moves the merge to a file named for it (MNT-5's list-merge half; the rest of that file is logged, see Out) and removes the test-only parameter and method: the tests choose a path with the inputs the app's own rule reads, the number of ids a write touches. The S16-26 review logged both as nits (MNT-5, MNT-7) and the user put them in the map on 2026-11-15.

**Why now.** S16-26 just landed; the next reader of the list merge (S16-38, the lists' empty state, or a fourth Go-ordered list) should find it by its name and see one way to call it.

**What stays.** The merge's behavior, `indexedMergeLimit` (16), the measured ceilings and every assertion's claim in `CatalogListMergeTests`. `CatalogLastUpdated.swift` keeps everything else it holds today (last-updated rows, page values, follows, patches, refreshes); that file's other contents are not this PR's.

## 2. User stories

**US-1.** As a contributor, when I look for the code that merges a write's rows into a Conclusion list, I find it in a file named for the list merge, so I do not read a last-updated file to change a merge.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | The AC-1.1 command below | Every hit is in `macos/App/Features/Workspace/Session/CatalogListMerge.swift` *(new)* |
| AC-1.2 | The AC-1.2 command below | Hits only in the doc comment on `protocol CatalogLastUpdatedRows` and in `CatalogQueryRefresh.mergedRows` (which calls the merge); no definition |
| AC-1.3 | The app builds and the full Swift suite runs | Green; no file other than the two Session files and the test file changed in `macos/` |

```bash
# AC-1.1
rg -n 'struct CatalogListRows|protocol CatalogListRow\b|func mergeSorted|func sortedByListKey' macos/App
# AC-1.2
rg -n 'CatalogListRow\b|CatalogListRows|mergeSorted|sortedByListKey|indexedMergeLimit' macos/App/Features/Workspace/Session/CatalogLastUpdated.swift
# AC-2.1
rg -n 'indexedLimit|func merging' macos/App
```

**US-2.** As a contributor, when I call the list merge, it has one signature, and its tests exercise the paths the app takes, so a test cannot pass on a path the app never runs.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | The AC-2.1 command above | No hit |
| AC-2.2 | `listRowsMergeMatchesMergeSorted`: random sorted lists, at most 8 dropped ids and 8 fresh rows (≤ 16 touched) | `merge` equals `Array.mergeSorted` with no forcing: the indexed path, by the app's rule |
| AC-2.3 | The same inputs with the first `indexedMergeLimit + 1` (17) row ids of the list added to `replacing`, on a list of more than 17 rows | Equals `Array.mergeSorted(fresh, replacing: ids + those 17)`: the one pass, by the app's rule |
| AC-2.4 | `listRowsLargeWriteTakesTheOnePass`: 200 ids touched at 20,115 rows | `merge` is under (the one pass, timed as `Array.mergeSorted` on a copy of `list.rows`) × 2 + 5 ms, the F-9 bound |
| AC-2.5 | `listRowsAtScaleStaysUnderCeiling`: one fresh row replacing two ids | The indexed figure is under 50 ms as today; the fallback figures print, forced by dropping 17 known rows (D-7) |

## 3. Scope

| In | Covered by |
| --- | --- |
| `CatalogListRow`, its three conformances, `sortedByListKey`, `Array.mergeSorted`, `CatalogListRows` and its `Equatable` and `CatalogLastUpdatedRows` extensions move verbatim to `CatalogListMerge.swift` *(new)* | STEP-1, AC-1.1, AC-1.2, D-1, D-2, D-3 |
| `merge(_:replacing:indexedLimit:)` loses `indexedLimit:`; `merging(_:replacing:indexedLimit:)` is deleted | STEP-2, AC-2.1, D-4 |
| `CatalogListMergeTests` forces each path through the touched-id count; a test-file helper replaces `merging` | STEP-2, STEP-3, AC-2.2 – AC-2.5, D-5, D-6, D-7 |
| Map scope entry: "the project file lists the new file" corrected (the App group is synchronized), and its Check reworded to the claims the tests keep | STEP-4, D-8 |
| `add-workspace-place` line 178 names the `CatalogListRow` conformance and its file | STEP-4, D-9 |

| Out | Home |
| --- | --- |
| Renaming `CatalogLastUpdated.swift` or moving its follows, patches, refreshes or page values (MNT-5's other half) | [`docs/ideas/structural-debt.md`](../../../ideas/structural-debt.md) row P-29 (added with this plan) |
| Other doc comments in the moved code (`merge`'s remaining text, `CatalogListRows`' header) and `CatalogListMergeTests`' file header, which cites S16-26's IDs | not planned (still true after the move) |
| Any change to the merge's behavior or `indexedMergeLimit` | not planned (map "Not this PR") |
| The empty list while a merge runs | S16-38 |
| The Conclusion lists' failure notice | [`docs/ideas/person-page-followups.md`](../../../ideas/person-page-followups.md) |

## 4. Current state

Verified at `04e76c4`.

| Area | Where | Today |
| --- | --- | --- |
| Row protocol | `macos/App/Features/Workspace/Session/CatalogLastUpdated.swift` `CatalogListRow` (lines 44–52, with conformances for `CatalogPersonSummary`, `CatalogEventSummary`, `CatalogPlaceSummary`) | A row Go placed with a `listKey`. Lives in the last-updated file (MNT-5) |
| Stable sort | same file, `fileprivate func sortedByListKey` (54–61) | Used by `Array.mergeSorted` and by `CatalogListRows.merge`; `fileprivate`, so it must move with both |
| One pass | same file, `extension Array where Element: CatalogListRow` `mergeSorted(_:replacing:)` (63–89) | The full-pass merge |
| Indexed rows | same file, `struct CatalogListRows` (91–192), `extension CatalogListRows: Equatable` (193–195) | `merging(_:replacing:indexedLimit:)` (121–126) is called only by tests. `merge(_:replacing:indexedLimit:)` (128–158): `indexedLimit ?? Self.indexedMergeLimit`; the comment says the parameter is for tests (MNT-7). `position(of:key:)`, `lowerBound`, `upperBound` and `keys` are `private` |
| Last-updated conformance | same file, `extension CatalogListRows: CatalogLastUpdatedRows` (197–209) | `moveActivity` reads `keys` and `position(of:key:)`, both `private` to `CatalogListRows`, so it must sit in the same file as the struct |
| App caller | same file, `CatalogQueryRefresh.mergedRows` (495–509) | `rows.merge(fresh, replacing: ids)`: never passes `indexedLimit` |
| Other app callers | `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift` (the three lists' descriptors), `macos/App/Platform/GoStore.swift`, `FakeStore.swift` | Use `CatalogListRows` by type name only; unaffected by a file move. `CatalogListKey` itself is in `macos/App/Platform/GenealogyStore.swift` and stays |
| Tests | `macos/ProvenenciaTests/CatalogListMergeTests.swift` | `listRowsMergeMatchesMergeSorted` (132–160): up to 20 ids and 20 fresh rows, forces each path with `indexedLimit: Int.max` / `0`, and a second merge re-merges up to 200 `rows` with `Int.max`. `listRowsLargeWriteTakesTheOnePass` (213–232): `best(0)` against `best(nil)`, both of which take the one pass at 200 touched ids today. `bestMilliseconds(rows:indexed:)` (325–340): `indexedLimit: indexed ? Int.max : 0`. Every other test calls no parameter |
| Project file | `macos/Provenencia.xcodeproj/project.pbxproj` | `PBXFileSystemSynchronizedRootGroup`: a new file in `macos/App` is in the target with no project edit (as S16-03's split, #769) |
| Another spike's plan | `docs/deployment-plan/spike-15/prs/S15-12-type-suggestions-at-each-level.md` line 106 | Cites `CatalogQueryPatch.typeSuggestions()` at "~378" and `.typeSuggestionCount()` at "~392" in `CatalogLastUpdated.swift`; STEP-1 shifts them up by about 166 lines. The symbols stay; the map's "Shared with Spike 15" table says so |
| Docs | `.agents/skills/add-workspace-place/SKILL.md` lines 63 and 178, `docs/macos-client-patterns.md` line 101 | Name `CatalogListRows`, `indexedMergeLimit`, `Array.mergeSorted` by type, not by file: true after the move. `rg "CatalogLastUpdated.swift"` finds no doc that places the merge there outside Spike 15/16 plans |

**Precedent.** S16-03 ([#769](https://github.com/mendahu/provenencia/pull/769)) split `ConclusionDetailPage.swift` into the files its types belong to, verbatim, with no version bump. Copy that: move the declarations byte for byte, then change them in a separate commit, so the move's diff is a pure move.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | The new file is `macos/App/Features/Workspace/Session/CatalogListMerge.swift` *(new)* | Named for what it does, matching `CatalogListMergeTests.swift`; the map asks for "a file named for the list merge" | `CatalogListRows.swift` — names one of three types the file holds, and the test file is already named for the merge |
| D-2 | It holds, in this order and verbatim: `CatalogListRow` with its three conformances, `sortedByListKey` (still `fileprivate`), `Array.mergeSorted`, `CatalogListRows`, `extension CatalogListRows: Equatable`, `extension CatalogListRows: CatalogLastUpdatedRows` | Their order in the old file; `sortedByListKey` stays file-private because both its callers move | Widening `sortedByListKey` to internal — a third caller is not wanted |
| D-3 | The `CatalogLastUpdatedRows` conformance of `CatalogListRows` moves with the struct | `moveActivity` reads `keys` and `position(of:key:)`, which are `private`; Swift lets only an extension in the same file read them | Keeping it in `CatalogLastUpdated.swift` and widening `keys` and `position` to internal — opens the index to every caller, the thing `CatalogListRows`' doc says it guards ("every change goes through `init`, `merge` and `moveActivity`") |
| D-4 | `merge(_ fresh: [Row], replacing ids: [String])` is the one signature; `var indexed = touched.count <= Self.indexedMergeLimit`. `merging(_:replacing:indexedLimit:)` is deleted from app code. The doc comment's sentence "`indexedLimit` is for tests that force one path." goes | MNT-7; the batch rule's "simpler code": one way to call the merge | A `static var` the tests set — a global seam the app could flip; an `#if DEBUG` parameter — still a test-only parameter |
| D-5 | Tests choose the path by the touched-id count, which is what the app's rule reads: ≤ `indexedMergeLimit` touched ids takes the indexed path; `indexedMergeLimit + 1` touched ids that are rows of the list takes the one pass | Each test runs a path the app runs for the same input. Known ids keep forcing the one pass even if the merge later counts only ids it holds (review M-3); unknown ids stay covered by `pickID`'s `"u…"` ids | Ids that name no row ("pads") — they force the one pass only while unknown ids count as touched; a test hook — adds code to the app for tests |
| D-6 | `listRowsMergeMatchesMergeSorted` draws at most 8 dropped ids (`0...8`) and at most 8 fresh rows (`0...8`), 500 seeds as today. Per seed it asserts: `merged(list, fresh, ids) == expected` (indexed); when `rows.count > CatalogListRows<Row>.indexedMergeLimit`, with `wide = ids + rows.prefix(17).map(\.id)`, `merged(list, fresh, wide)` equals `rows` after `mergeSorted(fresh, replacing: wide)` (one pass); and the follow-up check: `fresh2` = the same fresh ids at new random keys (`0...80`), `note: "fresh2"`, drawn after `fresh` (so the seed's stream for `rows`, `ids` and `fresh` is today's order), `again` = `expected` after `mergeSorted(fresh2, replacing: ids)`, and `merged(merged(list, fresh, ids), fresh2, ids) == again` (two indexed merges in a row, so the index follows the merge) | Keeps every claim of the test (both paths equal `mergeSorted`, the index follows the merge) on paths the app takes. Today's second merge re-merged up to 200 rows, which by the rule is the one pass; `fresh2` keeps it indexed | Keeping 20 + 20 — past 16 touched the "indexed" assertion would silently run the one pass |
| D-7 | A `private func merged(_ list: CatalogListRows<Row>, _ fresh: [Row], _ ids: [String]) -> CatalogListRows<Row>` *(new)* in `CatalogListMergeTests`, over the test's private `Row` only, not generic (`var copy = list; copy.merge(fresh, replacing: ids); return copy`), replaces every test call of `merging`. `bestMilliseconds(rows:indexed:)` keeps `dropped` (two ids) for indexed; for the fallback, `dropped` plus 15 more real row ids (`list[count / 4 + n].id` for `n` in `0..<15`), so 17 are touched, and its count check becomes `copy.count == count - 16`. `listRowsLargeWriteTakesTheOnePass` times `merge(fresh, replacing: ids)` (the chosen path) against the one pass timed as `plain.mergeSorted(fresh, replacing: ids)` on `var plain = list.rows`; in both, the copy is made outside `ContinuousClock().measure` and the mutation inside, as `best` does today; each best of 3; it keeps `#expect(chosen < onePass * 2 + 5)` and the `copy.count` check | The large-write test's claim (F-9: a 200-id write is no slower than the one pass, so raising the limit past the break-even fails) stays true and meaningful; today its `best(0)` and `best(nil)` take the same path | A `merging` extension in the test target — a second spelling of `merge` that the next test copies |
| D-8 | No project file edit; the map's scope entry is corrected in this PR: **Context** "the project file lists the new file" → "the App group is synchronized, so the new file needs no project edit"; **Check** "`CatalogListMergeTests` unchanged in what it asserts and green" → "`CatalogListMergeTests` keeps every claim it asserts, on the paths the app takes, and is green" | The App group is a `PBXFileSystemSynchronizedRootGroup`; D-6 changes the tests' sizes, not their claims | Editing the project file — would add a duplicate reference |
| D-9 | `add-workspace-place` line 178 gains: "and, for a list Go orders, to `CatalogListRow` (`CatalogListMerge.swift`)" | A new Go-ordered list now conforms in two files; the skill names both (review M-4) | Leaving it to the compile error |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `macos/App/Features/Workspace/Session/CatalogListMerge.swift` *(new)* | file | `CatalogLastUpdated.swift` | The map moves the merge out of it (MNT-5); nothing else is new in it, only moved code |
| `CatalogListMergeTests.merged(_:_:_:)` *(new)* | test helper | `CatalogListRows.merging` (deleted) | Moves the copy-and-merge the app never calls from app code into the one test file that uses it |

**Builds on.** S16-26's `CatalogListRows` and `indexedMergeLimit` unchanged; S16-03's verbatim-move precedent.
**Deletes.** `CatalogListRows.merging(_:replacing:indexedLimit:)`; the `indexedLimit:` parameter of `merge`; the doc sentence about it; the test's `indexedLimit: Int.max` / `0` arguments and `best(0)` / `best(nil)`. No pad-id helper is added.
**Next adds.** A fourth Go-ordered list conforms its row to `CatalogListRow` in `CatalogListMerge.swift` and to `CatalogLastUpdatedRow` in `CatalogLastUpdated.swift`, as the skill now says (D-9), and caches a `CatalogListRows`; S16-38 reads the lists' presentation, not this file.

### Reach

None — no new path into existing code, no new state reachable.

### Scale

None — no write, list or loop changes. The merge runs the same code; the scale tests keep their row counts (20,115 and 80,000) and ceilings.

### Edges

None — no rule, comparison or algorithm changes. The path choice (`touched.count <= indexedMergeLimit`) is the same rule with the default no longer overridable; D-5 forces the one pass with ids the list holds, so the tests do not depend on how unknown ids are counted.

### Schema

None — no catalog change.

### Go core

None — Swift only.

### FFI

None — no engine call changes.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| List merge types | moved code | `macos/App/Features/Workspace/Session/CatalogListMerge.swift` *(new)* | D-1 – D-3 |
| One merge signature | `CatalogListRows.merge(_:replacing:)` | same | D-4 |

No view changes.

### Strings

None — no user-facing copy.

## 7. Steps

**STEP-1 — Move the merge to its own file**
Files: `macos/App/Features/Workspace/Session/CatalogLastUpdated.swift`, `macos/App/Features/Workspace/Session/CatalogListMerge.swift` *(new)*.
Do: cut lines 44–209 of `CatalogLastUpdated.swift` (from `/// A cached list row that Go placed with a list key` through the end of `extension CatalogListRows: CatalogLastUpdatedRows`) and paste them, unchanged, into the new file under `import Foundation` (D-1 – D-3). Leave one blank line between `CatalogLastUpdated.swift`'s Array `moveActivity` extension and `CatalogPageValue`.
Check: `git diff --stat` shows only these two files; `git diff -M --color-moved=zebra` shows the block as moved with no changed line; the AC-1.1 and AC-1.2 commands print what those ACs say (these run anywhere). The app builds (`xcodebuild build`, as `scripts/check-pr.sh` runs it; macOS only).

Commit: "Move the Conclusion list merge to a file of its own."

**STEP-2 — One merge signature**
Files: `CatalogListMerge.swift`, `macos/ProvenenciaTests/CatalogListMergeTests.swift`. Skill: `add-swift-test`.
Do: per D-4, delete `merging`, drop `indexedLimit:` from `merge` and its sentence from the doc comment. In the tests add `merged` (D-7) and replace every `merging` call. The tests do not compile again until STEP-3 removes the forced-path arguments, so STEP-2 and STEP-3 are one commit.
Check: the AC-2.1 command prints nothing.

**STEP-3 — Tests choose the path the app's rule chooses**
Files: `macos/ProvenenciaTests/CatalogListMergeTests.swift`. Skill: `add-swift-test`.
Do: D-5 – D-7: rewrite `listRowsMergeMatchesMergeSorted`, `bestMilliseconds(rows:indexed:)` and `listRowsLargeWriteTakesTheOnePass` as D-6 and D-7 say. Keep every test name, seed, row count, ceiling and `// decided:` comment.
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -only-testing:ProvenenciaTests/CatalogListMergeTests` passes; the printed figures are in the PR body.

Commit (STEP-2 and STEP-3): "Give the list merge one signature and test the paths the app takes."

**STEP-4 — Docs**
Files: `docs/deployment-plan/spike-16/deployment-plan.md` (S16-37 row and scope entry), `docs/deployment-plan/spike-16/completed.md`, `.agents/skills/add-workspace-place/SKILL.md`, this plan.
Do: per the Definition of done. The scope entry's Context and Check lines as D-8 says; the skill line as D-9 says. The map row's **Status** becomes `Landed #N` and this plan's **Status** `Landed in [#N](…) (date)`, written after the PR is open so `N` is known (precedent: the S16-26 row). The `completed.md` paragraph goes at the top of the file (newest first), in the shape of S16-26's.
Check: `git diff docs/deployment-plan/spike-16/deployment-plan.md` changes only the S16-37 row and its scope entry; `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-37-list-merge-file.md` reports no errors; `scripts/check-pr.sh` prints `check-pr: PASS`.

Commits: one per behavior, as above. The subject is one full imperative sentence ending in a period. No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `macos/ProvenenciaTests/CatalogListMergeTests.swift` `listRowsMergeMatchesMergeSorted` (rewritten) | 500 seeds, ≤ 8 ids, ≤ 8 fresh rows → `merged` equals `mergeSorted`; with 17 of the list's ids added (lists past 17 rows) → equals `mergeSorted` with the same ids; two indexed merges in a row → equal to `again` | AC-2.2, AC-2.3, D-5, D-6 |
| T-2 | Swift | same file `listRowsLargeWriteTakesTheOnePass` (rewritten) | 200 ids at 20,115 rows → chosen `merge` < `mergeSorted` × 2 + 5 ms; 20,015 rows left | AC-2.4, D-7 |
| T-3 | Swift | same file `listRowsAtScaleStaysUnderCeiling` (through `bestMilliseconds`) | Two ids at 20,115 rows → indexed < 50 ms; fallback (17 known ids) prints | AC-2.5, D-7 |
| T-4 | Swift | every other `CatalogListMergeTests` test, unchanged | As today | AC-1.3 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `CatalogListMergeTests`, and any suite whose Persons, Events or Places list goes through `mergedRows` (`WorkspaceSessionTests`, `CatalogQueryRegistryTests`, `PersonsListTests`).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or rg output for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none expected)
- [ ] Sweep: `rg -n "indexedLimit|merging\(_:replacing" .agents .cursor/rules docs/*.md macos/App` finds nothing; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none)
- [ ] UI matches the brief inventory; no new kit primitive (no UI change)
- [ ] Version bump as the header says: none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status and the scope entry's Context line (D-8); completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (no brief: n/a)
- [ ] Domain doc updated if a rule in docs/*.md changed: none changes (the docs name types, not files)
- [ ] PR description: what shipped, AC evidence (rg output, test figures), deviations, manual check
```

## 10. Manual check

1. Run the AC-1.1, AC-1.2 and AC-2.1 commands (§2) from the repo root; each prints what its AC says. Paste the output in the PR body.
2. Open a project with people. Rename a person from their page, go back to the Persons list: the row sits in its new place, as before.
3. Promote a new person from an Evidence graph, then open Events and Places: each list shows the touched rows where they belong, with no spinner, as before.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| The move changes a line by accident | STEP-1 is its own commit, checked with `--color-moved` |
| Fewer random touched ids weaken the equivalence test | 500 seeds at ≤ 16 touched cover the indexed path the app takes; the run with 17 of the list's ids added covers the one pass with the same inputs |
| A timing test turns flaky once the forced path is gone | Same row counts and bounds; the one pass in T-2 is `mergeSorted` on a copy, the code `merge` falls back to |

**Stop and report if:**

- `CatalogLastUpdated.swift` lines 44–209 no longer hold exactly the declarations §4 lists, or something outside them reads `sortedByListKey`, `keys` or `position(of:key:)`.
- An app file other than `CatalogLastUpdated.swift` passes `indexedLimit:` or calls `merging`.
- A rewritten test fails on the code as moved (the merge is unchanged, so a failure means D-5's path rule or D-6's bounds are wrong): report the seed and the two results.
- T-2 fails its bound on two runs in a row: report both figures; do not change the bound or `indexedMergeLimit`.

## 12. Open questions

None.

## 13. PR

**Title:** S16-37 — The list merge has a file of its own and no test-only parameters
**Body:** objective in one sentence; what shipped against US-1 and US-2; AC evidence (the `rg` lines, the test figures); deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-37-list-merge-file.md`.
