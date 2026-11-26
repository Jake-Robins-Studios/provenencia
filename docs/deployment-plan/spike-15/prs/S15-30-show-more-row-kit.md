# S15-30 — The paged fold moves to the kit

**Status:** Draft
**Spike / slice:** Spike 15 · Slice 8 — Provenance loading
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: the row, its copy and its layout are drawn as today; the only change is that a pointer click on Show more no longer scrolls)
**Board:** —
**Depends on:** S16-07 (landed [#761](https://github.com/Jake-Robins-Studios/provenencia/pull/761)), S16-46 (landed [#890](https://github.com/Jake-Robins-Studios/provenencia/pull/890))
**Blocks:** S15-27
**Branch:** `s15-30-show-more-row-kit`
**Version bump:** patch, 0.46.0 (today's `VERSION`) → **0.46.1** (or the next patch after `main`'s `VERSION` when you rebase): a pointer click on Show more stops scrolling, a fix ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/design-system-layers.mdc` (the kit names no `Features/` type)
**Context:** map scope entry S15-30 ([`../deployment-plan.md`](../deployment-plan.md)); working rule "The provenance table folds a page at a time"; [`docs/design-system-layers.md`](../../../design-system-layers.md); [`macos/App/DesignSystem/README.md`](../../../../macos/App/DesignSystem/README.md); [`docs/macos-client-patterns.md`](../../../macos-client-patterns.md) "One sectioned detail page"; S16-07 ship log [`../../spike-16/prs/S16-07-paged-fold-focus.ship.md`](../../spike-16/prs/S16-07-paged-fold-focus.ship.md) (MNT-3, UX-5)
**Planned:** 2026-11-26 against `main` @ `452e61d`
**Review:** — (not reviewed yet)

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

The Person page's paged fold (a first limit, then pages of 50, a "Show N more" row that moves the keyboard to the first revealed item) lives in `Features/Conclusions/`, so the provenance table, a recipe, cannot use it. This PR moves the fold rule and its state to `macos/App/Platform/` and the Show more row into the kit as `PVShowMoreRow`, so S15-27 can fold `PVProvenanceRecordTable`. The row also takes over the scroll that follows a keyboard Show more, which Family and Sources each hand-roll today and which also fires on a pointer click (S16-07 ship log MNT-3, UX-5).

**Why now.** S15-27 is next in slice 8 and needs a fold a recipe may name.

**What stays.** Every fold's limits, page size and copy; the focus moves; the Back anchor restore (S16-46); the Timeline's own anchor-top scroll; the Gallery's scroll.

## 2. User stories

**US-1.** As a researcher reading a long Family, Timeline or Sources list, when I press Show more, I see the next page as today, so nothing I rely on changes.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A Person with 31 children; Family | "Show 1 more" under the children, as today |
| AC-1.2 | A Person with 120 dated events; Timeline; Show more pressed once | 100 events shown, "Show 20 more" |
| AC-1.3 | A list folded by `limit: 5, minimumHidden: 2` with 6 items | All 6 shown, no Show more (the fold rule is unchanged) |

**US-2.** As a keyboard user, when I press Return or Space on Show more in Family or Sources, the keyboard and the scroll move to the first item the page adds, also when that page is the last one.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Family with 31 children, the window short enough that the Show more row sits at the bottom edge; Tab to "Show 1 more", Return | The 31st child's tile has the focus ring and is scrolled into view; the Show more row is gone |
| AC-2.2 | Sources with a Source holding 9 record lines; Tab to its "Show 4 more", Space | The 6th line's graph link has the keyboard and is in view |
| AC-2.3 | Sources with 60 Sources; Tab to the rows' "Show 10 more", Return | The first record line of the 51st Source has the keyboard and is in view |

**US-3.** As a pointer user, when I click Show more, the page does not jump.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Family or Sources; click "Show N more" with the pointer | The list grows below; the scroll offset does not change; focus stays where it was |
| AC-3.2 | Timeline; click the events' "Show N more" | As today: the first revealed row scrolls to the top once placed (the Timeline's own scroll) |

## 3. Scope

| In | Covered by |
| --- | --- |
| `ConclusionFold` and `ConclusionFoldState` move to `Platform/` as `PagedFold` and `PagedFoldState`, unchanged in behavior | STEP-1, AC-1.1–1.3 |
| `ConclusionShowMoreRow` becomes the kit's `PVShowMoreRow` with an `L10n.DesignSystem` string | STEP-2, STEP-3 |
| The kit modifier `.pvScrollsShowMoreReveals()` owns the keyboard Show more scroll; Family's and Sources' `scrollTarget`/`scrollRequest` pairs and their `pvScrollsRowIntoView` go | STEP-2, STEP-4, AC-2.1–2.3, AC-3.1 |
| Timeline and `ReconciledValueRow` use `PVShowMoreRow` with no scroll | STEP-3, AC-1.2, AC-3.2 |
| Docs: DesignSystem README row, `macos-client-patterns.md`, map, completed | STEP-6 |

| Out | Home |
| --- | --- |
| Folding `PVProvenanceRecordTable` | S15-27 |
| Moving the Timeline's anchor-top scroll or the Gallery's scroll into the kit modifier | not planned (each scrolls on a lifeline click or a width change, not a fold) |
| Removing the Why accordion and `ReconciledValueRow.Provenance` | S15-31 |
| Restoring folds on Back | not planned (Spike 16 working rule "Back restores a section's scroll and focus, not its folds") |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Fold rule, state, row | `macos/App/Features/Conclusions/ConclusionShowMoreRow.swift` `ConclusionShowMoreRow`, `ConclusionFold`, `ConclusionFoldState` | All three in `Features/`; a recipe may not name them |
| Copy | `macos/App/Platform/L10n.swift` `L10n.Conclusions.showMore(_:)`, key `conclusions.showMore` in `macos/App/Resources/Localizable.xcstrings` (plural, one and other "Show %lld more") | Lives in the Conclusions namespace |
| Family | `macos/App/Features/Conclusions/PersonFamilySection.swift` `PersonFamilyDiagram` (`scrollTarget`, `scrollRequest`, `.pvScrollsRowIntoView(scrollTarget, whenRequested: scrollRequest)`, the Show more's `expand` closure) | Scrolls after every press, pointer included |
| Sources | `macos/App/Features/Conclusions/PersonSourcesSection.swift` `PersonSourcesList` (the view holding `focus`, `hover`, `scrollTarget`, `scrollRequest`, `unfold(_:)`, `rows`), `PersonSourcesRowsShowMore`, `PersonSourcesRowView` | `unfold(_:)` scrolls after every press, pointer included; both Show mores get `revealed` as a `PersonSourcesFocus` |
| Timeline | `macos/App/Features/Conclusions/PersonTimelineSection.swift` `PersonTimelineList` (`pendingReveal`, `scrollTarget`, `scrollRequest`, `rebuild()`, `select(_:)`), `PersonTimelineItemView`, `PersonTimelineEventRow` | Its pair serves the lifeline click and the placed reveal; stays |
| Value row | `macos/App/Features/Conclusions/ReconciledValueRow.swift` `ReconciledValueRow` (`folds`, the Show more with `revealed: revealsLastPage ? firstStop : nil`) | No scroll; `revealed` is a disclosure stop, not a revealed item |
| Other fold users | `PersonFamilyContent.swift`, `PersonSourcesContent.swift`, `PersonTimelineContent.swift`, `ReconciledValueRowModel.swift` (`listFold`) | Name `ConclusionFold` / `ConclusionFoldState` |
| Kit scroll | `macos/App/DesignSystem/Components/ScrollRowIntoView/PVScrollRowIntoView.swift` `pvScrollsRowIntoView(_:anchor:animated:…whenRequested:)` | The one way the kit scrolls a row into view; the README row says not to add another `ScrollViewReader` for this |
| AnyHashable ids | `macos/App/DesignSystem/Components/FormDialog/PVFormDialog.swift` `scrollTarget: AnyHashable?` into `pvScrollsRowIntoView` | Shows an `AnyHashable` target finds a view tagged `.id(_:)` with the wrapped value |
| Environment precedent | `macos/App/DesignSystem/Components/ScrollMemory/PVScrollMemory.swift` `PVScrollMemoryKey`, `EnvironmentValues.pvScrollMemory` | How the kit hands a scroll helper down through the environment |
| Tests | `macos/ProvenenciaTests/ConclusionFoldTests.swift`; `PersonFamilyContentTests`, `PersonFamilyLayoutTests`, `PersonSourcesContentTests`, `PersonTimelineContentTests`, `PersonTimelineLifelineTests`, `ConclusionContentTests` (name `ConclusionFoldState`); `L10nPluralTests.everyCatalogPluralPicksAFormPerCount` | Pin the fold rule and the plural |

**Precedent.** S13-34 moved `PVDatePlaceLine` and `PVTitleText` out of `Features/Conclusions/` into `DesignSystem/Components/` (`d2120d0`): a folder per component, a README row saying "moved out of `Features/Conclusions`", call sites renamed. Copy that shape. The environment helper copies `PVScrollMemory`'s key and `EnvironmentValues` extension.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | The fold rule and state are renamed `PagedFold` and `PagedFoldState` and move, code unchanged, to `macos/App/Platform/PagedFold.swift` *(new)* | `Platform/` holds what a recipe may compose; "Conclusion" would be false once the provenance table uses it | Keeping the names (wrong for a recipe); putting them in `DesignSystem/Components/` (they are rules, not views, like `FocusClaim`) |
| D-2 | `PVShowMoreRow` keeps `ConclusionShowMoreRow`'s parameters and behavior (`hidden`, `fold`, `focus`, `stop`, `revealed`, `expand`; focus claimed only when the press began with the row focused) and adds `revealedRow: AnyHashable? = nil`, the `.id` of the first item the page adds | One row for every fold; the focus value and the scroll id differ in Sources (`.graph(claimID:)` vs the line's `.id(line.id)`) | Deriving the id from `revealed` (wrong in Sources); a second generic parameter (callers that never scroll would spell it) |
| D-3 | The scroll lives in a kit modifier `.pvScrollsShowMoreReveals()` that a section applies once around its rows. It holds the target and request token as `@State`, applies `pvScrollsRowIntoView(target, whenRequested: request)` (anchor nil, animated), and puts a `PVShowMoreReveal` in the environment. `PVShowMoreRow` calls it with `revealedRow` in the branch that claims focus, after `expand()`. With no modifier above it, or a nil `revealedRow`, the row scrolls nothing | The row disappears when its press reveals the last page, so state held in the row would never scroll (AC-2.1); calling only from the keyboard branch ends the pointer scroll (AC-3.1); built on the one kit scroller | A `ScrollViewReader` or `@State` in the row (the map's first wording: lost on the last page); keeping each section's pair (the duplication MNT-3 names) |
| D-4 | Family and Sources apply `.pvScrollsShowMoreReveals()` where they apply `pvScrollsRowIntoView` today, and pass `revealedRow`: Family the revealed tile id, Sources the revealed claim id (`content.firstRevealed(by:)`) | Same views, same targets, same scroll as today | — |
| D-5 | Timeline and `ReconciledValueRow` pass no `revealedRow` and apply no modifier | The Timeline scrolls a revealed row only once placed, to the top, also on a pointer click, through its own pair (unchanged); the value row has never scrolled | Routing the Timeline through the modifier (it scrolls before placement, to the wrong spot) |
| D-6 | `PersonSourcesRowsShowMore` and `PersonSourcesRowView` take the revealed claim id as `revealed: String?` and build the focus value `.graph(claimID:)` themselves | One input instead of two that must agree | Passing both the focus value and the id |
| D-7 | The copy moves to `L10n.DesignSystem.showMore(_:)`, key `designSystem.showMoreRow.showMore`, plural one and other "Show %lld more" as today; `conclusions.showMore` is deleted | A kit string; same English | Keeping the Conclusions key in the kit (a kit row would name a feature namespace) |
| D-8 | `PVShowMoreRow` and the modifier live in `macos/App/DesignSystem/Components/ShowMoreRow/PVShowMoreRow.swift` *(new)*, one file, ending in a `#Preview` of a 12-item list folded at 5 inside a `ScrollView` with the modifier | A component folder per the README; the modifier exists only for the row | A second file for a 20-line modifier |

**Rules this plan bends.** None. The map's scope entry wording ("a `ScrollViewReader` in the row") is changed in the map by STEP-6 to D-3's shape.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `macos/App/Platform/PagedFold.swift` `PagedFold`, `PagedFoldState` *(new)* (moved) | file / type | `ConclusionFold`, `ConclusionFoldState` | It is them, renamed and moved |
| `macos/App/DesignSystem/Components/ShowMoreRow/PVShowMoreRow.swift` `PVShowMoreRow` *(new)* (moved) | component | `ConclusionShowMoreRow` | It is it, plus `revealedRow` |
| `pvScrollsShowMoreReveals()`, `PVShowMoreReveal`, `EnvironmentValues.pvShowMoreReveal` *(new)* | modifier / type / env | `pvScrollsRowIntoView` (used inside it), `pvScrollMemory` (env shape) | Holds the token above the row, which `pvScrollsRowIntoView` alone cannot |
| `L10n.DesignSystem.showMore(_:)` *(new)* (moved) | key | `L10n.Conclusions.showMore(_:)` | It is it, in the kit namespace |
| `macos/ProvenenciaTests/PagedFoldTests.swift` `PagedFoldTests` *(new)* (renamed) | test | `ConclusionFoldTests` | It is it |

Sketch:

```swift
struct PVShowMoreRow<Focus: Hashable>: View {
    let hidden: Int
    let fold: PagedFold
    let focus: FocusState<Focus?>.Binding
    let stop: Focus
    let revealed: Focus?
    var revealedRow: AnyHashable? = nil
    let expand: () -> Void
    @Environment(\.pvShowMoreReveal) private var reveal
    // press(): let claims = focus.wrappedValue == stop; expand();
    //          guard claims else { return }
    //          if let revealed { FocusClaim.claim(focus, revealed) }
    //          if let revealedRow { reveal?(revealedRow) }
}

struct PVShowMoreReveal { let scroll: (AnyHashable) -> Void; func callAsFunction(_ row: AnyHashable) { scroll(row) } }

extension View { func pvScrollsShowMoreReveals() -> some View }  // private ViewModifier with @State target: AnyHashable?, @State request = 0
```

`PVShowMoreRow`'s memberwise order puts `revealedRow` before `expand`, so trailing-closure call sites keep working.

**Builds on.** `pvScrollsRowIntoView`'s request token (scrolls on the next main-actor turn, so the inserted rows exist); `FocusClaim`; the `PVScrollMemory` environment shape; S13-34's move shape.
**Deletes.** `macos/App/Features/Conclusions/ConclusionShowMoreRow.swift`; `ConclusionFoldTests.swift` (renamed); `L10n.Conclusions.showMore` and `conclusions.showMore`; `PersonFamilyDiagram.scrollTarget`, `.scrollRequest` and its `pvScrollsRowIntoView`; `PersonSourcesList.scrollTarget`, `.scrollRequest`, its `pvScrollsRowIntoView`, and the two scroll lines in `unfold(_:)` (it keeps `expand(fold)`; if nothing else is left in it, call `expand` directly and delete `unfold`).
**Next adds.** S15-27 folds `PVProvenanceRecordTable` with `PagedFold`, `PagedFoldState` and `PVShowMoreRow`, and applies `.pvScrollsShowMoreReveals()` in the sheet's scroll view.

### Reach

None — no new path into existing code; the same views draw the same rows.

### Scale

At the map's Scale (up to 1,200 records, 30 Sources, 50 per page): no list, loop or write changes. The modifier changes its environment value only when a keyboard press reveals a page, so the rows under it rebuild then and at no other time.

### Edges

- **Assumptions.** `pvScrollsRowIntoView`'s request path assumes the target exists on the next main-actor turn; the page `expand()` inserted is drawn by then, as today. The modifier holds the state, so the row leaving the tree in the same update does not drop the scroll (manual check 2).
- **Neighbors.** Keyboard press on a page that is not the last: scroll as today. Keyboard press on the last page: scroll (today too, from the section). Pointer click: no scroll (today: scroll). `revealed` nil: no focus claim, no scroll. Value row's last page: focus to its first disclosure stop, no scroll, as today. Timeline participants: no scroll, as today.
- **Removed inputs.** None — the fold rule is moved, not changed.
- **Real data.** None — no table-driven rule.
- **Untrusted size.** None — no new list.

### Schema

None — no catalog change.

### Go core

None — Swift only.

### FFI

None —.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Show more row | `PVShowMoreRow` | `macos/App/DesignSystem/Components/ShowMoreRow/` *(new)* | `.buttonStyle(.pv(.ghost, size: .sm))`, `.focused(focus, equals: stop)`, `.pvActivatesOnReturn(when:_:)`, as today |
| Keyboard reveal scroll | `.pvScrollsShowMoreReveals()` | same file | Family on `PersonFamilyDiagram`'s body, Sources on `PersonSourcesList.rows` |
| Fold rule and state | `PagedFold`, `PagedFoldState` | `macos/App/Platform/PagedFold.swift` *(new)* | Doc comments drop "Conclusion page" for "a folded list" |

Accessibility identifiers stay on the call sites, unchanged.

### Strings

L10n key *(new)*: `L10n.DesignSystem.showMore(_:)` = `designSystem.showMoreRow.showMore`, "Show %lld more" (plural one and other), comment "Button under a folded list that shows the next page of it; argument is how many that page adds". Removed: `L10n.Conclusions.showMore`, `conclusions.showMore`.

## 7. Steps

**STEP-1 — Move the fold rule**
Files: `macos/App/Platform/PagedFold.swift` *(new)*, `ConclusionShowMoreRow.swift`, the six `Features/Conclusions` files and seven test files in §4, `macos/ProvenenciaTests/PagedFoldTests.swift` *(renamed from `ConclusionFoldTests.swift`)*. Skill: `add-swift-test`.
Do: move `ConclusionFold` and `ConclusionFoldState` into the new file as `PagedFold`, `PagedFoldState` (D-1); rename every use; rename the test file and struct; add T-2.
Check: `rg -n "ConclusionFold" macos` finds nothing; `xcodebuild test` passes `PagedFoldTests` and the content tests.

**STEP-2 — Add `PVShowMoreRow` and the modifier**
Files: `macos/App/DesignSystem/Components/ShowMoreRow/PVShowMoreRow.swift` *(new)*, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`. Skills: `add-ui-component`, `add-localized-string`.
Do: write the row and the modifier per D-2, D-3, D-8 and the sketch; add the key per D-7 (copy the plural variations); add T-3.
Check: the app builds; the preview shows "Show 7 more" under 5 items.

**STEP-3 — Timeline and value row use the kit row**
Files: `PersonTimelineSection.swift`, `ReconciledValueRow.swift`.
Do: replace `ConclusionShowMoreRow(` with `PVShowMoreRow(`, no `revealedRow` (D-5).
Check: builds; `rg -n "ConclusionShowMoreRow" macos/App/Features/Conclusions/PersonTimelineSection.swift macos/App/Features/Conclusions/ReconciledValueRow.swift` finds nothing.

**STEP-4 — Family and Sources hand their scroll to the kit**
Files: `PersonFamilySection.swift`, `PersonSourcesSection.swift`.
Do: per D-4 and D-6, and **Deletes**.
Check: `rg -n "scrollTarget|scrollRequest" macos/App/Features/Conclusions/PersonFamilySection.swift macos/App/Features/Conclusions/PersonSourcesSection.swift` finds nothing; manual checks 1–3.

**STEP-5 — Remove the old row and string**
Files: `ConclusionShowMoreRow.swift` (delete), `L10n.swift`, `Localizable.xcstrings`.
Do: per **Deletes**.
Check: `rg -n "ConclusionShowMoreRow|Conclusions.showMore|conclusions.showMore" macos` finds nothing; `python3 scripts/check-localizable-xcstrings.py` passes.

**STEP-6 — Docs and version**
Files: `macos/App/DesignSystem/README.md` (a `ShowMoreRow` row naming `Components/ShowMoreRow/PVShowMoreRow.swift` *(new)*: the row and `.pvScrollsShowMoreReveals()`, "moved out of `Features/Conclusions`" in S15-30), `docs/macos-client-patterns.md` ("One sectioned detail page": `ConclusionFold` → `PagedFold`, `ConclusionFoldState` → `PagedFoldState`, `ConclusionShowMoreRow` → `PVShowMoreRow`, and one clause that the section applies `.pvScrollsShowMoreReveals()` so a keyboard Show more scrolls its first revealed item into view), `../deployment-plan.md` (map row status; the S15-30 scope entry's scroll sentence says D-3's modifier), `../completed.md`, this plan, `VERSION`, `core/version.go`, `MARKETING_VERSION` lines.
Do: per the Definition of done.
Check: `scripts/check-pr.sh` prints `check-pr: PASS`.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `macos/ProvenenciaTests/PagedFoldTests.swift` *(new)* `PagedFoldTests` (all cases kept from `ConclusionFoldTests`) | 31 items at `limit: 30, minimumHidden: 1` → 30 shown, 1 hidden; 6 at `5, 2` → all shown; pages of 50 | AC-1.1, AC-1.3, D-1 |
| T-2 | Swift | `macos/ProvenenciaTests/PagedFoldTests.swift` *(new)* `eventsFoldPagesOf120` *(new)* | `PagedFold(limit: 50, minimumHidden: 1)` over 120 items: pages 0 → 50 shown, 1 → 100 shown, `nextPageCount(hidden: 20)` → 20 | AC-1.2 |
| T-3 | Swift | `macos/ProvenenciaTests/PagedFoldTests.swift` *(new)* `showMoreWordsThePage` *(new)* | `L10n.DesignSystem.showMore(1)` → "Show 1 more"; `(50)` → "Show 50 more" | D-7 |
| T-4 | Swift | `macos/ProvenenciaTests/L10nPluralTests.swift` `everyCatalogPluralPicksAFormPerCount` (existing) | The new plural key resolves for 1 and 2 | D-7 |

The scroll and focus (AC-2.x, AC-3.x) are checked by hand: Swift Testing does not drive focus or scroll (README "`#Preview` doesn't exercise focus").

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `PersonFamilyContentTests`, `PersonSourcesContentTests`, `PersonTimelineContentTests` (renames).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: `ConclusionFold`, `ConclusionFoldState`, `ConclusionShowMoreRow`, `L10n.Conclusions.showMore`, `conclusions.showMore` `rg`'d across `.agents/`, `.cursor/rules/`, `docs/*.md`, `macos/` and `L10n.swift` with no hit left outside `docs/deployment-plan/`; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches today's; no new kit primitive beyond `PVShowMoreRow` and its modifier
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status and the scope entry's scroll sentence; completed.md: one short paragraph of what shipped
- [ ] Domain doc updated: docs/macos-client-patterns.md "One sectioned detail page"; macos/App/DesignSystem/README.md ShowMoreRow row
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

Use a Debug build and the dogfood project, or build the fixtures below in a scratch project. Regular width, then Wide.

1. A Person with 31 children: Family shows "Show 1 more" (AC-1.1). Click it with the pointer: the page does not scroll (AC-3.1).
2. Same Person, reopened, window short so "Show 1 more" is at the bottom edge: Tab to it, Return. The 31st tile has the focus ring and is in view; the row is gone (AC-2.1).
3. Sources: a Source with 9 record lines: Tab to "Show 4 more", Space: the 6th line's link has the keyboard and is in view (AC-2.2). With 60 Sources: Tab to the rows' "Show 10 more", Return: the 51st Source's first line has the keyboard and is in view (AC-2.3). A pointer click on either does not scroll (AC-3.1).
4. Timeline with 120 dated events: click "Show 50 more": the 51st event scrolls to the top once placed (AC-3.2); press it by keyboard: the next page, the keyboard on the first revealed title (AC-1.2).
5. An Event or Place row with more than 21 listed lines: Show more by keyboard to the last page: the keyboard lands on the row's first disclosure, no scroll, as today.
6. Open a row from Family, then Back: the row has the keyboard (S16-46 unchanged).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| An `AnyHashable` target does not find a tile tagged `.id(String)` | `PVFormDialog` already scrolls this way; manual checks 2 and 3 |
| The environment value's closure rebuilds the rows on every body pass | It changes only when `target` or `request` changes (a keyboard press) |

**Stop and report if:**

- Manual check 2 or 3 shows the revealed item not scrolled into view after a keyboard press (D-3 does not hold).
- A file under §4 no longer declares the symbol the row names.
- `scripts/check-guidance-names.py` reports a kit file naming a `Features/` type after STEP-2.
- Any fold count in §2 differs from today's after STEP-1.

## 12. Open questions

None.

## 13. PR

**Title:** S15-30 — The paged fold moves to the kit
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-30-show-more-row-kit.md`.
