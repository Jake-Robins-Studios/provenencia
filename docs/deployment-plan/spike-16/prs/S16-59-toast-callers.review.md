# Review — S16-59 Workspace callers add to the toast stack

**Verdict:** Fits with changes — Ready with changes
**Rounds:** 1. **Reviewers:** maintainability (opus), executability (sonnet)

## To user
None.

## Writer's own calls
- D-1, D-2: `VocabularyToast` and its `add(_:)` forward are deleted, not kept as a parameter bag; every site calls `add(tone:title:message:)`.
- D-5: `WorkspaceSession.noticeToast` goes; its four setters (Source type page, `LeavesForSectionRoot`, Promote, Source move) add to `session.toasts`.
- D-6: `ConclusionLeadModel` holds the viewer's sheet list (`viewerOpened(toasts:)`) instead of a `toastInViewer` flag.
- D-7 (from M-1): `\.pvToastList` is renamed `\.pvSheetToasts` and moves into `PVSheet.swift`; `add-ui-component` gains one sentence on it.
- D-9 (from M-3): a test fixture `ToastCard` / `PVToastList.cards`, and the three existing list-reading suites move onto it.
- Version bump none, as S16-64 (preparatory, no visible change).
- Reach: a toast from a page save that finishes after the page was left now shows at once in the window's stack, where today it waited in the model for the page to mount again. Kept as the working rule's intent.

## Round 1

### M-1 · major · After D-7 `\.pvToastList` means only "this sheet's toasts" — rename and move it beside the sheet keys
The key's one setter is `PVSheetChrome` and its one reader the viewer; `PVSheet.swift` already holds `pvSheetClose` and `pvSheetInnerEditOpen`; `add-ui-component` teaches nothing of the pattern D-6 asks the next sheet to copy.
**Answer:** Fixed — D-7 renames it `\.pvSheetToasts`, moves it to `PVSheet.swift` and adds the skill sentence; STEP-7 files and checks, Codebase fit row, §6 signature block, STEP-8 README wording, DoD sweep (`pvToastList`).

### M-2 · major · The sweep misses `stacked-toasts.md` and `macos-client-patterns.md:105`
Both name `noticeToast`, `toastInViewer`, `vocabularyToastOverlay` or "the page owns … its toast" as current; `docs/*.md` does not reach the spike folder.
**Answer:** Fixed — STEP-9 rewrites both (exact sentence for `macos-client-patterns.md:105`); §4 row "Feature docs"; DoD sweep is recursive over `docs/` except history; the domain-doc DoD line names both.

### M-3 · major · One test-side snapshot instead of ~50 hand-written field checks; keep the count
**Answer:** Fixed — D-9 adds `ToastFixtures.swift` (`ToastCard`, `PVToastList.cards`) and whole-list comparisons; STEP-1 adds it and moves `CatalogCountsTests`, `CitationComposerModelTests` and `PVToastListTests.titles(_:)` onto it (T-0); T-1, T-5, T-6 reworded.

### M-4 · minor · D-4's tuple return is a new shape; a function that adds is simpler
**Answer:** Fixed — D-4 is `addSavedToast(_:detailsChanged:formatsSaved:)`, which adds in each case.

### M-5 · nit · Ten vs nine overlay ids
**Answer:** Fixed with X-1.

### X-1 · major · "Ten" overlay ids is wrong; there are nine
**Answer:** Fixed — §1 and §3 say nine (§1 notes the ship log said ten).

### X-2 · minor · Stop condition trips on the viewer's `#Preview`
**Answer:** Fixed — §11 exempts the preview and says where its add goes.

### X-3 · minor · STEP-5 removes the window's key while two overlays still forward through it
**Answer:** Fixed — the window's `.environment` removal moves to STEP-7, after the last overlay goes in STEP-6; STEP-5 says it stays.

### X-4 · minor · Titles are `LocalizedStringResource`; `add` takes `String`
**Answer:** Fixed — AC-1.1 uses `L10n.string(…)`; D-1 says each argument is the expression passed to `VocabularyToast` today, so its conversion stays.

### X-5 · minor · A two-add test reading `entries.first`
**Answer:** Fixed — D-9: a test that adds twice compares the whole list after each add.

### X-6 · minor · Tests with no session in scope
**Answer:** Fixed — D-9 names the three `SourcePageModelTests` sites and the session to build.

### X-7 · nit · `PromoteModelTests` has no toast assertion
**Answer:** Fixed — §8 says so; manual check 3 covers the Promote card.

### X-8 · nit · Sweep scope and historical docs
**Answer:** Fixed with M-2 — history (`prs/`, `archive/`, `completed.md`, review logs) is excluded; `stacked-toasts.md` is rewritten.

No blocker was raised and no reshape, so no round 2.
