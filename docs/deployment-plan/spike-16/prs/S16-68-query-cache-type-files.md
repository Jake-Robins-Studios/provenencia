# S16-68 — The query-cache types have files of their own

**Status:** Planned
**Spike / slice:** Spike 16 · Slice 6g — Catalog query layer
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: four types move between files; nothing a researcher sees changes)
**Board:** —
**Depends on:** —
**Blocks:** S16-70
**Branch:** `s16-68-query-cache-type-files`
**Version bump:** none — no behavior changes, as for S16-37's move ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md) (its Patch and Refresh rows, for the names it cites)
**Rules that bind:** `.cursor/rules/macos-client.mdc`, `.cursor/rules/swift-tests.mdc`
**Context:** [design § CatalogLastUpdated.swift holds four other types](../catalog-query-layer.md#cataloglastupdatedswift-holds-four-other-types-s16-68); working rule "(Batch 6) The query-cache types move verbatim"; S16-37's plan ([`S16-37-list-merge-file.md`](S16-37-list-merge-file.md)), the precedent
**Planned:** 2026-11-24 against `main` @ `6e18533`
**Review:** [`S16-68-query-cache-type-files.review.md`](S16-68-query-cache-type-files.review.md) — Fits with changes · Ready with changes, 1 round; no blocker open; To user: M-1/M-2, answered 2026-11-24

**Runs on macOS.** STEP-2 needs `xcodebuild`. STEP-1's move checks (`git diff`, `rg`) run anywhere. On a machine without `xcodebuild`, finish STEP-1, then stop and report that STEP-2 needs a macOS runner.

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

`CatalogLastUpdated.swift` is named for the last-updated rows but mostly holds four other types: the page-value protocol, the follow slots, the patches and the refreshes of the Swift query cache. Each moves, unchanged, to a file named for it, so the next reader finds a type by its file name and S16-70's edits to the follows and patches read as edits, not as moves. From the catalog query layer idea (P-29, S16-26 ship log MNT-5, S16-37 review M-2).

**Why now.** S16-70 adds a follow slot and a removal patch. Moving first keeps that diff small and reviewable (rule "(Batch 6) The query-cache types move verbatim").

**What stays.** Every type, member, doc comment and behavior. The last-updated rows stay in `CatalogLastUpdated.swift`.

## 2. User stories

**US-1.** As a contributor, when I look for `CatalogQueryPatch`, `CatalogQueryRefresh`, `CatalogQueryFollows` or `CatalogPageValue`, I open the file named for it, so that the file I open holds the type I am after.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | `rg -n -e "^struct " -e "^enum " -e "^protocol " macos/App/Features/Workspace/Session/CatalogLastUpdated.swift` | Three lines: `struct CatalogActivity`, `protocol CatalogLastUpdatedRow`, `protocol CatalogLastUpdatedRows` |
| AC-1.2 | `rg -n -e "^protocol CatalogPageValue\b" -e "^enum CatalogQueryFollows\b" -e "^struct CatalogQueryPatch\b" -e "^struct CatalogQueryRefresh\b" macos/App` | Four lines, each in `macos/App/Features/Workspace/Session/<TypeName>.swift` |
| AC-1.3 | After the STEP-1 commit, the AC-1.3 command below (it prints the added and removed lines git did not colour as moved) | It prints only: the `---`/`+++` file headers; `+import Foundation` once in each new file; and D-2's lines — the free function's comment, signature and `precondition` removed, the member's comment, signature and `precondition` added, and the five call sites (`-        requireRowIDs(follows)` five times, `+        follows.requireRowIDs()` five times). Blank lines and lone braces may also print: git colours short lines as moved or not by context. Checked on a scratch copy at the planning base, 2026-11-24 |
| AC-1.4 | `git diff --stat main -- macos/ProvenenciaTests` | Prints nothing; the Swift tests pass unchanged |

AC-1.3 command (bash):

```bash
git diff --color=always --color-moved=plain "$(git merge-base main HEAD)" HEAD -- macos/App | grep -E $'^(\x1b\\[[0-9;]*m)?[+-]' | grep -v $'\x1b\\[1;3[56]m'
```

## 3. Scope

| In | Covered by |
| --- | --- |
| `CatalogPageValue` and its six conformances move to `CatalogPageValue.swift` *(new)* | STEP-1, AC-1.2, D-1 |
| `CatalogQueryFollows` moves to `CatalogQueryFollows.swift` *(new)*; the free `requireRowIDs(_:)` becomes the enum's member `requireRowIDs()`, and its five callers call it on their slot | STEP-1, AC-1.2, AC-1.3, D-1, D-2 |
| `CatalogQueryPatch` moves to `CatalogQueryPatch.swift` *(new)* | STEP-1, AC-1.2, D-1 |
| `CatalogQueryRefresh` moves to `CatalogQueryRefresh.swift` *(new)* | STEP-1, AC-1.2, D-1 |
| `CatalogLastUpdated.swift` keeps `CatalogActivity`, `CatalogLastUpdatedRow` (with its four conformances) and `CatalogLastUpdatedRows` (with its `Array` extension) | STEP-1, AC-1.1 |
| The map's working rule names the one edit the split forces (user, 2026-11-24) | STEP-3, D-2 |

| Out | Home |
| --- | --- |
| Any other edit to the moved code: the `.deleted(entity)` follow slot, the removal patch, the `removes:` closure's removal | S16-70 |
| A `requireCatalogWide()` member for the inline `precondition(follows.isCatalogWide, …)` in `CatalogQueryRefresh.applyHiddenPolicyOnAny` | not planned (one caller; S16-70's plan may take it when it decides whether `.deleted` is catalog-wide) |
| Splitting `CatalogQueryPatch` or `CatalogQueryRefresh` further, or moving their static constructors into extensions | not planned |
| Renaming `CatalogLastUpdated.swift` | not planned (it holds what its name says once the four leave) |
| Repointing landed plans and ship logs that cite `CatalogLastUpdated.swift` with line numbers | not planned (landed plans are history; `archive-docs` deletes them at spike close) |

## 4. Current state

Verified at `6e18533`. All paths are under `macos/App/Features/Workspace/Session/`.

| Area | Where | Today |
| --- | --- | --- |
| Last-updated rows | `CatalogLastUpdated.swift` lines 1–42: `import Foundation`, `struct CatalogActivity`, `protocol CatalogLastUpdatedRow` and its four conformances (`CatalogPersonSummary`, `CatalogEventSummary`, `CatalogPlaceSummary`, `CatalogSource`), `protocol CatalogLastUpdatedRows`, `extension Array: CatalogLastUpdatedRows` | What the file's name says; stays |
| Page value | same file, lines 44–55: `protocol CatalogPageValue` and six conformances (`CatalogConclusionDetail`, `CatalogPersonClaims`, `CatalogProvenanceSheetRead`, `CatalogPersonFamily`, `CatalogPersonTimeline`, `CatalogPersonRecordLinks`) | Not a last-updated row |
| Follow slots | same file, lines 57–108: `enum CatalogQueryFollows` (`handle`, `source`, `reads`, `touchedHandles`, `evidenceGraphs`, `list`, `structure`; `isCatalogWide`, `ids(in:)`) | Not a last-updated row |
| Row-id guard | same file, lines 110–113: `fileprivate func requireRowIDs(_ follows: CatalogQueryFollows)`, a `precondition(!follows.isCatalogWide, …)` | Called as `requireRowIDs(follows)` by `CatalogQueryPatch.lastUpdated` (line 130) and four `CatalogQueryRefresh` constructors (lines 298, 334, 352, 369). `fileprivate`, so it cannot serve two files as it is. Every other top-level function in `macos/App` is `private` or `fileprivate` except the FFI entry points in `Platform/CoreInvoke.swift` |
| Patches | same file, lines 115–251: `struct CatalogQueryPatch` (`lastUpdated`, `sourceRow`, `row(_:patched:appendsOn:removes:)`, `sourceTypeRow`, `typeSuggestions`, `typeSuggestionCount` and the rest) | Not a last-updated row. Has no `private` or `fileprivate` member |
| Refreshes | same file, lines 253–398: `struct CatalogQueryRefresh` (`Action`, two `fileprivate init`s, `merged`, `mergedRows`, `revalidate`, `followsInputs`, `applyHiddenPolicyOnAny`) | Not a last-updated row. Its two `fileprivate init`s are called only from its own static constructors (lines 279, 299, 335, 353, 370, 393), so they move with it unchanged |
| Project file | `macos/Provenencia.xcodeproj/project.pbxproj` | The App group is synchronized (`PBXFileSystemSynchronizedBuildFileExceptionSet`): a new file in the folder is built with no project edit, as S16-37 found |
| Mentions | `rg -n "CatalogLastUpdated" macos core` | No hit outside the file itself. `add-workspace-place` cites the types by symbol, not by file. Only landed plans and ship logs cite the file |
| Tests | `macos/ProvenenciaTests/CatalogQueryRegistryTests.swift`, `WorkspaceSessionTests.swift`, `CatalogListMergeTests.swift` | Exercise the patches, refreshes and follows through the registry and the session; none names the file |

**Precedent.** S16-37 ([#858](https://github.com/Jake-Robins-Studios/provenencia/pull/858)) moved the list merge out of this same file into `CatalogListMerge.swift`: one move commit, checked with `git diff -M --color-moved=zebra`, no project edit. Copy its STEP-1 shape. Do not copy its later steps, which changed code.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | Four new files in `macos/App/Features/Workspace/Session/`, each starting with `import Foundation` and a blank line, then the lines below in today's order, with their doc comments, taken from `git show main:macos/App/Features/Workspace/Session/CatalogLastUpdated.swift` so a cut does not shift the next range: `CatalogPageValue.swift` lines 44–55; `CatalogQueryFollows.swift` lines 57–108; `CatalogQueryPatch.swift` lines 115–251; `CatalogQueryRefresh.swift` lines 253–398. Lines 110–113 become D-2's member. `CatalogLastUpdated.swift` keeps lines 1–42 and ends after the `Array` extension's closing brace with one newline | One file per type, named for it (rule "(Batch 6) The query-cache types move verbatim") | Keeping `CatalogPageValue` beside its reader `CatalogQueryDescriptor.entityPage(kind:load:)` in `CatalogQueryRegistry.swift`, which already holds four types, or beside `CatalogPageInputs` in `Platform/GenealogyStore.swift`, which is not the cache layer |
| D-2 | The free function becomes a member of `CatalogQueryFollows`, after `ids(in:)`: `func requireRowIDs()` with today's doc comment and body, reading `self` (`precondition(!isCatalogWide, "a catalog-wide slot names no ids; use applyHiddenPolicyOnAny(follows:)")`). The five call sites change from `requireRowIDs(follows)` to `follows.requireRowIDs()`. Nothing else in the moved code changes (user, 2026-11-24) | Its callers end up in two other files, so `fileprivate` cannot stay. A member keeps the guard with the type it checks, adds no module-wide free function, and sits in the file S16-70 edits for its sixth caller (review M-2) | Dropping only `fileprivate` — the app's only internal free function for a type's own rule (offered to the user, declined); a copy in each file — a near-copy |
| D-3 | One commit for the move: "Give the query-cache types files of their own." | AC-1.3 reads the move in one diff, as S16-37's STEP-1 did | One commit per file — four diffs that each show half a move |
| D-4 | No new tests | No behavior changes; the registry and session suites already cover every moved type, and AC-1.4 holds them unchanged | A test per file — tests nothing a build does not |

**Rules this plan bends.** D-2 edits moved code, against rule "(Batch 6) The query-cache types move verbatim" ("with no edit to their code") → the split leaves `requireRowIDs`'s callers in two files, so it cannot stay `fileprivate` → the user chose the member on the enum (2026-11-24, review M-1, M-2) → STEP-3 rewords the rule.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `CatalogPageValue.swift` *(new)* | file | `CatalogLastUpdated.swift` (holds the type today) | The file is named for the last-updated rows |
| `CatalogQueryFollows.swift` *(new)* | file | same | same |
| `CatalogQueryPatch.swift` *(new)* | file | same | same |
| `CatalogQueryRefresh.swift` *(new)* | file | same | same |

Searched: `rg --files macos/App -g "*CatalogQuery*" -g "*PageValue*"` finds `CatalogQueryKey.swift` and `CatalogQueryRegistry.swift` only. By behavior: `CatalogPageValue`'s reader `CatalogQueryDescriptor.entityPage(kind:load:)` (`CatalogQueryRegistry.swift`) and the type it exposes, `CatalogPageInputs` (`macos/App/Platform/GenealogyStore.swift`), were weighed as homes and rejected in D-1.

| `CatalogQueryFollows.requireRowIDs()` *(new member)* | func | the free `requireRowIDs(_:)` (deleted) and the inline `precondition(follows.isCatalogWide, …)` in `CatalogQueryRefresh.applyHiddenPolicyOnAny` | It is the free function, moved onto the type (D-2); the inline mirror guard stays (Out) |

**Builds on.** S16-37's move of the list merge to `CatalogListMerge.swift`; the folder's files named for the concept they hold (`CatalogQueryKey.swift`, `CatalogRowPresence.swift`, `CatalogListMerge.swift`).
**Deletes.** The free `fileprivate func requireRowIDs(_:)` (replaced by the member, D-2). Nothing else becomes dead.
**Next adds.** S16-70's whole cache edit lands in two of these files: `CatalogQueryFollows.deleted(CatalogDeletedEntity)` with its cases in `isCatalogWide` and `ids(in:)` in `CatalogQueryFollows.swift`, and in `CatalogQueryPatch.swift` a row-removal patch (a sixth `requireRowIDs()` caller) and the removal of `row`'s `removes:` closure and `sourceTypeRow()`'s `.deletedSourceType` arm.

### Reach

None — no new path into existing code, no new state reachable.

### Scale

None — no write, list or loop changes.

### Edges

None — no rule, comparison or algorithm changes. The one access edge (`requireRowIDs`, `fileprivate` with callers in two files) is D-2; the member checks the same condition on the same value.

### Schema

None — no catalog change.

### Go core

None — Swift only.

### FFI

None — no FFI change.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Page value protocol | `CatalogPageValue` | `CatalogPageValue.swift` *(new)* | Moved, D-1 |
| Follow slots and row-id guard | `CatalogQueryFollows`, `requireRowIDs()` | `CatalogQueryFollows.swift` *(new)* | Moved, D-1; the guard a member, D-2 |
| Patches | `CatalogQueryPatch` | `CatalogQueryPatch.swift` *(new)* | Moved, D-1 |
| Refreshes | `CatalogQueryRefresh` | `CatalogQueryRefresh.swift` *(new)* | Moved, D-1 |

States: none change. Accessibility: none changes.

### Strings

None — no copy.

## 7. Steps

**STEP-1 — Move the four types**
Files: `macos/App/Features/Workspace/Session/CatalogLastUpdated.swift`, the four new files of D-1.
Do: per D-1 and D-2. Copy each range from `git show main:macos/App/Features/Workspace/Session/CatalogLastUpdated.swift` into its file, then delete lines 43–398 from `CatalogLastUpdated.swift`. Make D-2's member and its five call-site edits.
Commit: D-3, then check.
Check: `git show --stat HEAD` lists the five files only; AC-1.1, AC-1.2 and AC-1.3 print what they say (these run anywhere). If AC-1.3 prints a line its row does not allow, fix it in an amended STEP-1 commit.

**STEP-2 — Build and test**
Files: none.
Do: run `scripts/check-pr.sh`.
Check: it prints `check-pr: PASS` with no Swift warning; AC-1.4 prints nothing.

**STEP-3 — Docs**
Files: `docs/deployment-plan/spike-16/deployment-plan.md`, `docs/deployment-plan/spike-16/completed.md`, this plan.
Do, after the PR is open so its number is known:
- The rule "(Batch 6) The query-cache types move verbatim": after "with no edit to their code" add ", except that the free `requireRowIDs(_:)` becomes `CatalogQueryFollows.requireRowIDs()`, since its callers end up in two files (user, 2026-11-24)".
- The S16-68 scope entry: its Ships gains "`requireRowIDs` becomes a member of `CatalogQueryFollows` (D-2)."
- The S16-68 map row: Status `Landed [#N](https://github.com/Jake-Robins-Studios/provenencia/pull/N)`, the form S16-67's row uses.
- `completed.md`: a new entry at the top of the file (entries run newest first), in the shape of S16-37's entry (the paragraph that opens "**Landed 2026-11-16** in [#858]"), saying the four types moved to files named for them and `requireRowIDs` became a member, and that nothing a researcher sees changed.
- This plan: Status `Landed in [#N](https://github.com/Jake-Robins-Studios/provenencia/pull/N) (YYYY-MM-DD)` and a **Landed.** line under the header listing each difference from this plan, or "none".
Check: links resolve; `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-68-query-cache-type-files.md` reports no errors.
Commit: "Record S16-68 as landed."

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `macos/ProvenenciaTests/CatalogQueryRegistryTests.swift` (all, unchanged) | Every descriptor's patches, refreshes and follows → as today | AC-1.4, D-4 |
| T-2 | Swift | `macos/ProvenenciaTests/WorkspaceSessionTests.swift` (all, unchanged) | `apply` over effects and mutations → as today | AC-1.4, D-4 |
| T-3 | Shell | AC-1.1 – AC-1.3 commands | the move → the outputs AC-1.1 – AC-1.3 name | AC-1.1, AC-1.2, AC-1.3 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: the Xcode build, if a moved block lost a line at a cut.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none added)
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it) (no name changes)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none; STEP-3 updates the rule's wording)
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New (no UI)
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated) (not gated)
- [ ] Domain doc updated if a rule in docs/*.md changed: none
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Open any project. Open a Source, rename it, and go back to the Sources list: its row shows the new title and a fresh last-updated time, as before.
2. Open a Person, edit one of their event dates, and press Back: the Person page shows the new date, as before.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A cut drops or duplicates a line | STEP-1 is its own commit, checked with `--color-moved` (AC-1.3) |
| Another member is file-private and called across the new files | §4 lists every `private` and `fileprivate` in the file; STEP-2's build catches the rest |

**Stop and report if:**

- `CatalogLastUpdated.swift` at your base declares a type, or a `private` or `fileprivate` member, that §4 does not list.
- The build needs an access change other than D-2's.
- The build needs an edit to `project.pbxproj`.
- AC-1.3 shows a changed line other than the four imports and D-2.

## 12. Open questions

None.

## 13. PR

**Title:** S16-68 — The query-cache types have files of their own
**Body:** objective in one sentence; what moved (D-1) and the one access change (D-2); AC-1.1 – AC-1.4 output; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-68-query-cache-type-files.md`.
