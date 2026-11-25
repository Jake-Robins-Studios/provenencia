# Review — S16-72 Back returns to the scroll position

Plan: [`S16-72-scroll-offset-history.md`](S16-72-scroll-offset-history.md).

## Round 1 (2026-11-25)

Maintainability: **Fits with changes**. Executability: **Ready with changes**.

| ID | Severity | Finding | Answer |
| --- | --- | --- | --- |
| M-1 | blocker | Revisit fields carried and cleared one by one; a push (`withPageSection`) carries Vitals' y onto Family | **Fixed**: one `WorkspaceRevisit` value (D-9); `NavigationHistoryStore.go(to:)` strips it on a push (D-8); the hand clear goes (Deletes); T-2 `aPushStartsClean` |
| M-2 | blocker | `scrollResetKey` arrival keys are a second mechanism beside the restore | **Fixed**: the probe scrolls a reused view to the top on a new arrival with no y (D-6); `openPageSection`, `sourceID`, `typeID` keys go (STEP-4); the error-count key stays (D-12) |
| M-3 | blocker | One scalar y and claim-and-clear leave no slot for the composer's second column | **Fixed**: `scrollOffsets: [PVScrollSlot: Double]`, `pvRemembersScroll(_ slot:)` (D-4); T-5 `aSecondSlotIsRememberedApart` |
| M-4 | major | Arrival counter, arrival kind and `apply`'s reset disagree | **Fixed**: one `WorkspaceArrival { id, kind }` (D-7); the held revisit resets only on a new id (D-8) |
| M-5 | major | `listOpenRow` is general-sounding for a Sources-only fact | **Fixed**: `openSourceId`, stamped only on the Sources list root (D-8, D-9) |
| M-6 | major | STEP-8 misses `macos-client-patterns.md` and the skill's Step 5 | **Fixed**: STEP-8 lists both, and the kit README's PageColumns row |
| M-7 | minor | `ConclusionAnchorTarget` and `ListAnchor` left with one member | **Fixed**: both go (D-11, Deletes) |
| M-8 | minor | `PVPopupWindowHost.startFollowing` is the kit's clip-view observer | **Fixed**: Precedent, D-2, Codebase fit |
| M-9 | minor | The skill's ephemera row is a rule bent | **Fixed**: Rules this plan bends |
| M-10 | minor | D-12 repeats Deletes | **Fixed**: D-12 keeps only what stays |
| X-1 | blocker | Coalesced `go(to:)` and the new fields undecided | **Fixed**: D-8 (stamped before the move, coalesced included; selection copied as today) |
| X-2 | major | `completed.md` path | **Fixed**: STEP-8 names `docs/deployment-plan/spike-16/completed.md` |
| X-3 | major | Arrival kind per caller; `.onAppear` re-apply | **Fixed**: D-7 lists every caller |
| X-4 | major | Legacy decode fixture key | **Fixed**: T-2 keeps `"listScrollAnchor"` |
| X-5 | major | What stays of `PVNativeListBehavior`'s scroll | **Fixed**: D-12 |
| X-6 | major | Which Timeline `scroll:` goes, and the unbuilt card | **Fixed**: D-12 (the `conclusionAnchorRestore` one; every item is built); the Stop condition stays |
| X-7 | major | Which scroll view is the Person page's | **Fixed**: D-5 names every claimant |
| X-8 | minor | xcodebuild cannot run on Linux | **Declined**: the implementer runs on macOS (`scripts/check-pr.sh`), as every Spike 16 PR |
| X-9 | minor | Small choices (file of the enum, search order, visible height, `nan` in JSON) | **Fixed**: D-3, D-7, T-2 |
| X-10 | minor | Review log link dead | **Fixed**: this file |

## Round 2 (2026-11-25)

Maintainability: **Fits with changes**. Executability: **Not ready** (two blockers), answered below. Cap reached: no round 3.

| ID | Severity | Finding | Answer |
| --- | --- | --- | --- |
| M-11 / X-12 | blocker | The selection has two homes; a coalesced visit (the sort or filter clear) no longer clears it | **Fixed**: D-8's one `apply` rule (new arrival: the entry's revisit; same arrival: only the selection from the entry); the held `listSelection` is the one selection; T-2 `aCoalescedVisitClearsTheHeldSelection`, the two existing selection tests kept |
| X-11 | blocker | A quit writes no y, so AC-1.9 and AC-2.4 cannot hold | **Fixed**: `flush()` on `WorkspaceView` disappear and `willTerminate` (D-8); T-2 `flushWritesTheCurrentY` |
| X-13 | major | The kept selection scroll can disarm a restore on the reused Sources list | **Fixed**: D-12 skips a selection scroll in the update an arrival changes; T-5 `aSelectionSetByBackDoesNotScrollTheMountedList` |
| X-14 | major | `PVScrollRestore` cannot see the current y; scroll mapping unstated | **Fixed**: Codebase fit signatures (`arm(currentY:)`, `layout(currentY:…)`) and the `scroll(to:)` mapping; T-1 rows |
| X-15 | major | STEP-1 cannot compile before later steps | **Fixed**: STEP-1 moves every reader and writer with behavior unchanged; later steps delete; `ListAnchor.settle` named right; `sectionAnchor` in the `rg` |
| X-16 | minor | Remount mid-visit, dictionary encoding, `init` parameters, Source types, DoD kit box | **Fixed**: Edges, D-9, DoD |
| — | — | Host row: list roots have nil identity | **Fixed**: §4 Host row |

## Verdict

**Planned.** No open blocker; nothing To user. Two rounds.
