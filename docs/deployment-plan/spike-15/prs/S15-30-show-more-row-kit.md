# S15-30 — The paged fold moves to the kit

**Status:** Landed in [#996](https://github.com/Jake-Robins-Studios/provenencia/pull/996) (2026-11-26)
**Spike / slice:** Spike 15 · Slice 8 — Provenance loading
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: the row, its copy and its layout are drawn as today; the only change is that a pointer click on Show more no longer scrolls)
**Board:** —
**Depends on:** S16-07 (landed [#761](https://github.com/Jake-Robins-Studios/provenencia/pull/761))
**Blocks:** S15-27
**Branch:** `s15-30-show-more-row-kit`
**Version bump:** patch, 0.46.0 (today's `VERSION`) → **0.46.1** (or the next patch after `main`'s `VERSION` when you rebase): a pointer click on Show more stops scrolling, a fix ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/design-system-layers.mdc` (the kit names no `Features/` type)
**Context:** map scope entry S15-30 ([`../deployment-plan.md`](../deployment-plan.md)); working rule "The provenance table folds a page at a time"; [`docs/design-system-layers.md`](../../../design-system-layers.md); [`macos/App/DesignSystem/README.md`](../../../../macos/App/DesignSystem/README.md); [`docs/macos-client-patterns.md`](../../../macos-client-patterns.md) "One sectioned detail page"; S16-07 ship log [`../../spike-16/prs/S16-07-paged-fold-focus.ship.md`](../../spike-16/prs/S16-07-paged-fold-focus.ship.md) (MNT-3, UX-5)
**Host:** macOS with Xcode. Tests: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS'`, narrowed with `-only-testing:ProvenenciaTests/<Suite>` where a Step says so. The implementer runs the manual check in §10.
**Planned:** 2026-11-26 against `main` @ `452e61d`
**Review:** [`S15-30-show-more-row-kit.review.md`](S15-30-show-more-row-kit.review.md) — Fits with changes / Ready with changes, one round; every finding Fixed, Declined or answered by the user

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

The Person page's paged fold (a first limit, then pages of 50, a "Show N more" row that moves the keyboard to the first revealed item) lives in `Features/Conclusions/`, so the provenance table, a recipe, cannot use it. This PR moves the fold rule and its state to `macos/App/Platform/` and the Show more row into the kit as `PVShowMoreRow`, so S15-27 can fold `PVProvenanceRecordTable`. The kit also takes over the scroll that follows a Show more, which Family, Sources and the Timeline each hand-roll today and which also fires on a pointer click (S16-07 ship log MNT-3, UX-5). After this PR every Show more scrolls only after a keyboard press, through one route (user, 2026-11-26).

**Why now.** S15-27 is next in slice 8 and needs a fold a recipe may name.

**What stays.** Every fold's limits, page size and copy; the focus moves; the Back anchor restore (S16-46); the Timeline's lifeline-click scroll and its scroll-to-top once a revealed row is placed; the Gallery's scroll.

## 2. User stories

**US-1.** As a researcher reading a long Family, Timeline or Sources list, when I press Show more, I see the next page as today, so nothing I rely on changes.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A Person with 31 children; Family | "Show 1 more" under the children, as today |
| AC-1.2 | A Person with 120 dated events; Timeline; Show more pressed once | 100 events shown, "Show 20 more" |
| AC-1.3 | A list folded by `limit: 5, minimumHidden: 2` with 6 items | All 6 shown, no Show more (the fold rule is unchanged) |

**US-2.** As a keyboard user, when I press Return or Space on Show more, the keyboard and the scroll move to the first item the page adds, also when that page is the last one.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Family with 31 children, the window short enough that the Show more row sits at the bottom edge; Tab to "Show 1 more", Return | The 31st child's tile has the focus ring and is scrolled into view; the Show more row is gone |
| AC-2.2 | Sources with a Source holding 9 record lines; Tab to its "Show 4 more", Space | The 6th line's graph link has the keyboard and is in view |
| AC-2.3 | Sources with 60 Sources; Tab to the rows' "Show 10 more", Return | The first record line of the 51st Source has the keyboard and is in view |
| AC-2.4 | Timeline with 120 dated events; Tab to "Show 50 more", Return | The 51st event's title has the keyboard and, once placed, scrolls to the top, as today |

**US-3.** As a pointer user, when I click Show more, the page does not jump.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Family, Sources or Timeline; click "Show N more" with the pointer | The list grows below; the scroll offset does not change; focus stays where it was |

## 3. Scope

| In | Covered by |
| --- | --- |
| `ConclusionFold` and `ConclusionFoldState` move to `Platform/` as `PagedFold` and `PagedFoldState`, unchanged in behavior | STEP-1, AC-1.1–1.3 |
| `ConclusionShowMoreRow` becomes the kit's `PVShowMoreRow` with an `L10n.DesignSystem` string | STEP-2, STEP-3 |
| The kit's `PVShowMoreReveal` environment action and its default provider `.pvScrollsShowMoreReveals()` own the keyboard Show more scroll; Family's and Sources' scroll pairs and the Timeline's fold `pendingReveal` write go | STEP-2, STEP-4, STEP-5, AC-2.1–2.4, AC-3.1 |
| `ReconciledValueRow` uses `PVShowMoreRow` with no scroll | STEP-3 |
| Docs: DesignSystem README row, `macos-client-patterns.md`, map, completed | STEP-2, STEP-7 |

| Out | Home |
| --- | --- |
| Folding `PVProvenanceRecordTable` | S15-27 |
| Moving the Timeline's lifeline-click scroll or the Gallery's scroll into the kit | not planned (neither follows a Show more) |
| Scrolling after the Timeline's participants Show more | not planned (it never scrolled; its cards sit beside the row) |
| Removing the Why accordion and `ReconciledValueRow.Provenance` | S15-31 |
| Restoring folds on Back | not planned (Spike 16 working rule "Back restores a section's scroll and focus, not its folds") |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Fold rule, state, row | `macos/App/Features/Conclusions/ConclusionShowMoreRow.swift` `ConclusionShowMoreRow`, `ConclusionFold`, `ConclusionFoldState` | All three in `Features/`; a recipe may not name them |
| Fold users | Every file `rg -l "ConclusionFold" macos` lists: eight under `macos/App/Features/Conclusions/` and seven under `macos/ProvenenciaTests/` (including `ConclusionFoldTests.swift`) | Name the old types |
| Copy | `macos/App/Platform/L10n.swift` `L10n.Conclusions.showMore(_:)`, key `conclusions.showMore` in `macos/App/Resources/Localizable.xcstrings` (plural, one and other "Show %lld more") | Lives in the Conclusions namespace |
| Family | `macos/App/Features/Conclusions/PersonFamilySection.swift` `PersonFamilyDiagram` (`scrollTarget`, `scrollRequest`, `.pvScrollsRowIntoView(scrollTarget, whenRequested: scrollRequest)`, the Show more's `expand` closure) | Scrolls after every press, pointer included |
| Sources | `macos/App/Features/Conclusions/PersonSourcesSection.swift` `PersonSourcesList` (`scrollTarget`, `scrollRequest`, `unfold(_:)`, `rows`), `PersonSourcesRowsShowMore`, `PersonSourcesRowView` | `unfold(_:)` scrolls after every press, pointer included; both Show mores get `revealed` as a `PersonSourcesFocus` |
| Timeline | `macos/App/Features/Conclusions/PersonTimelineSection.swift` `PersonTimelineList` (`pendingReveal`, `scrollTarget`, `scrollRequest`, `rebuild()`, `unfold(_:)`, `select(_:)`), `PersonTimelineItemView` (`.more`), `PersonTimelineEventRow` (participants) | `unfold(_:)` sets `pendingReveal` for every non-participant fold, pointer included; `rebuild()` scrolls it to the top once placed; `select(_:)` serves the lifeline |
| Value row | `macos/App/Features/Conclusions/ReconciledValueRow.swift` `ReconciledValueRow` (the Show more with `revealed: revealsLastPage ? firstStop : nil`) | No scroll; `revealed` is a disclosure stop, not a revealed item |
| Kit scroll | `macos/App/DesignSystem/Components/ScrollRowIntoView/PVScrollRowIntoView.swift` `pvScrollsRowIntoView(_:anchor:animated:…whenRequested:)` | The one way the kit scrolls a row into view |
| AnyHashable ids | `macos/App/DesignSystem/Components/FormDialog/PVFormDialog.swift` `scrollTarget: AnyHashable?` into `pvScrollsRowIntoView` | An `AnyHashable` target finds a view tagged `.id(_:)` with the wrapped value |
| Environment action | `macos/App/DesignSystem/Components/Panel/PVSheet.swift` `PVSheetClose`, `PVSheetCloseKey`, `EnvironmentValues.pvSheetClose`; `macos/App/DesignSystem/Components/ScrollMemory/PVScrollMemory.swift` `PVScrollMemory` (`==`) | The kit's action-in-environment shape, and a closure-carrying value made `Equatable` |
| Tests | `ConclusionFoldTests.swift`; content tests naming `ConclusionFoldState`; `L10nPluralTests.everyCatalogPluralPicksAFormPerCount`; `macos/ProvenenciaTests/HostedWindow.swift` `hostInBorderlessWindow`, `descendant(_:in:)`, `eventually`; `PVScrollMemoryHostedTests` (a hosted scroll test, `.hostedWindows` trait) | Pin the fold rule and the plural; the hosted helpers drive a real scroll view |

**Precedent.** S13-34 moved `PVDatePlaceLine` and `PVTitleText` out of `Features/Conclusions/` into `DesignSystem/Components/` (`d2120d0`): a folder per component, a README row saying "moved out of `Features/Conclusions`", call sites renamed. Copy that shape. The environment action copies `PVSheetClose`; its `Equatable` copies `PVScrollMemory`'s. The hosted test copies `PVScrollMemoryHostedTests`.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | The fold rule and state are renamed `PagedFold` and `PagedFoldState` and move, code unchanged, to `macos/App/Platform/PagedFold.swift` *(new)*; doc comments say "a folded list" for "a Conclusion page's lists" | The map's working rule puts them in `Platform/`; content types in `Features/` use them as pure rules; "Conclusion" would be false for the provenance table | The row's folder (a working rule names `Platform/`); keeping the names |
| D-2 | `PVShowMoreRow` keeps `ConclusionShowMoreRow`'s parameters and behavior (`hidden`, `fold`, `focus`, `stop`, `revealed`, `expand`) and adds `revealedRow: AnyHashable? = nil` before `expand`, the `.id` of the first item the page adds. Call sites build it with `.map(AnyHashable.init)` | One row for every fold; the focus value and the scroll id differ in Sources | Deriving the id from `revealed` (wrong in Sources) |
| D-3 | A press is decided by `PVShowMorePress` *(new)*, a pure rule: when the press began with the row focused, it moves focus to `revealed` and asks for a scroll to `revealedRow`; otherwise neither. The row runs `expand()`, then `FocusClaim.claim` for the focus, then the environment's `pvShowMoreReveal` for the scroll | The pointer rule is one testable line; the scroll is asked of something that outlives the row, which leaves the tree when it reveals the last page | Branching inline in the view (untestable) |
| D-4 | `PVShowMoreReveal` copies `PVSheetClose`: a struct with `let scroll: @MainActor (AnyHashable) -> Void` and a `@MainActor callAsFunction(_:)`, non-optional, default a no-op (no provider: nothing scrolls). It is `Equatable` with `==` always true, as `PVScrollMemory` compares only what it must: a new copy writes to the same provider's state | One action shape in the kit; an equal value does not rebuild the rows under it | An optional closure (a second shape beside `PVSheetClose`) |
| D-5 | `.pvScrollsShowMoreReveals()` *(new)* is the default provider: a private modifier with `@State private var target: AnyHashable?` and `@State private var request = 0`, whose body is `content.environment(\.pvShowMoreReveal, PVShowMoreReveal { target = $0; request += 1 }).pvScrollsRowIntoView(target, whenRequested: request)` (anchor nil, animated) | Built on the one kit scroller; the state survives the row | A `ScrollViewReader` or state in the row (lost on the last page) |
| D-6 | Family applies `.pvScrollsShowMoreReveals()` where `PersonFamilyDiagram` applies `pvScrollsRowIntoView` today and passes `revealedRow` = the revealed tile id. Sources applies it where `PersonSourcesList.rows` does and passes the revealed claim id; `PersonSourcesRowsShowMore` and `PersonSourcesRowView` take `revealed: String?` and build both `.graph(claimID:)` and `revealedRow` from it | Same views, same targets, same scroll as a keyboard press today | Passing both values (two inputs that must agree) |
| D-7 | The Timeline is its own provider: `PersonTimelineList` sets `.environment(\.pvShowMoreReveal, PVShowMoreReveal { pendingReveal = $0.base as? String })` on its list, and the `.more` row in `PersonTimelineItemView` passes `revealedRow: revealed(fold).map(AnyHashable.init)`. `rebuild()` keeps scrolling `pendingReveal` to the top once placed; `select(_:)` and its pair stay. The participants row passes no `revealedRow` (user, 2026-11-26) | One route for every Show more scroll; the Timeline keeps its own placement timing; a pointer click no longer scrolls | Keeping `unfold(_:)`'s `pendingReveal` write (a second route that fires on a pointer click) |
| D-8 | `ReconciledValueRow` passes no `revealedRow` and has no provider | It has never scrolled | — |
| D-9 | The copy moves to `L10n.DesignSystem.showMoreRowLabel(_:)`, key `designSystem.showMoreRow.label`, plural one and other "Show %lld more" as today, added after `datePlaceLineDateUnknown` in `enum DesignSystem`; the catalog entry is a copy of `conclusions.showMore`'s plural block with the new comment, placed after the last `designSystem.` key | A kit string named by its component, like `badgeMoreCount`; same English | Keeping the Conclusions key |
| D-10 | `PVShowMoreRow`, `PVShowMorePress`, `PVShowMoreReveal` and the modifier live in `macos/App/DesignSystem/Components/ShowMoreRow/PVShowMoreRow.swift` *(new)*. Its `#Preview` is a 200 pt `ScrollView` of 12 rows (`Text("Row \(i)")`, 60 pt, `.id(i)`) folded by `PagedFold(limit: 5, minimumHidden: 2)` with a `PagedFoldState<Int>`, `Focus = Int`, `stop = -1`, `revealed` and `revealedRow` the first revealed index, under `.pvScrollsShowMoreReveals()` | One component folder per the README | A file per type |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `macos/App/Platform/PagedFold.swift` *(new)* `PagedFold`, `PagedFoldState` (moved) | file / type | `ConclusionFold`, `ConclusionFoldState` | It is them, renamed and moved |
| `macos/App/DesignSystem/Components/ShowMoreRow/PVShowMoreRow.swift` *(new)* `PVShowMoreRow` (moved) | component | `ConclusionShowMoreRow` | It is it, plus `revealedRow` |
| `PVShowMorePress` *(new)* | rule | `PVSheetCloseRule` (a kit decision as a pure rule) | Its own decision |
| `PVShowMoreReveal`, `EnvironmentValues.pvShowMoreReveal` *(new)* | type / env | `PVSheetClose`, `pvSheetClose` | Same shape, a different action |
| `pvScrollsShowMoreReveals()` *(new)* | modifier | `pvScrollsRowIntoView` (used inside it) | Holds the token above the row |
| `L10n.DesignSystem.showMoreRowLabel(_:)` *(new)* (moved) | key | `L10n.Conclusions.showMore(_:)` | It is it, in the kit namespace |
| `macos/ProvenenciaTests/PagedFoldTests.swift` *(new)* (renamed) | test | `ConclusionFoldTests` | It is it |
| `macos/ProvenenciaTests/PVShowMoreRowTests.swift` *(new)* `PVShowMoreRowTests`, `PVShowMoreRowHostedTests` | test | `PVScrollMemoryHostedTests` | New behavior to pin |

```swift
struct PVShowMorePress<Focus: Hashable>: Equatable {
    let focus: Focus?
    let scroll: AnyHashable?
    init(startedOnRow: Bool, revealed: Focus?, revealedRow: AnyHashable?)  // both nil unless startedOnRow
}
```

**Builds on.** `pvScrollsRowIntoView`'s request token (scrolls on the next main-actor turn, so the inserted rows exist); `FocusClaim`; `PVSheetClose`'s action shape; S13-34's move shape.
**Deletes.** `macos/App/Features/Conclusions/ConclusionShowMoreRow.swift`; `ConclusionFoldTests.swift` (renamed); `L10n.Conclusions.showMore` and `conclusions.showMore`; `PersonFamilyDiagram.scrollTarget`, `.scrollRequest` and its `pvScrollsRowIntoView`; `PersonSourcesList.scrollTarget`, `.scrollRequest`, its `pvScrollsRowIntoView` and `unfold(_:)` (its callers call `expand` directly); `PersonTimelineList.unfold(_:)` (its callers pass `expand` directly).
**Next adds.** S15-27 folds `PVProvenanceRecordTable` with `PagedFold`, `PagedFoldState` and `PVShowMoreRow`, and applies `.pvScrollsShowMoreReveals()` in the sheet's scroll view. A list that places rows late supplies its own `PVShowMoreReveal`, as the Timeline does.

### Reach

None — no new path into existing code; the same views draw the same rows.

### Scale

At the map's Scale (up to 1,200 records, 30 Sources, 50 per page): no list, loop or write changes. `PVShowMoreReveal` compares equal across body passes, so the rows under a provider do not rebuild for it.

### Edges

- **Assumptions.** `pvScrollsRowIntoView`'s request path assumes the target exists on the next main-actor turn; the page `expand()` inserted is drawn by then, as today. The provider holds the state, so the row leaving the tree in the same update does not drop the scroll (T-4). An always-equal `PVShowMoreReveal` assumes its closure only writes to the provider's own state (D-4).
- **Neighbors.** Keyboard press on a page that is not the last: scroll as today. Keyboard press on the last page: scroll. Pointer click: no focus move, no scroll, in every section (today: Family, Sources and the Timeline scroll). `revealed` nil: no focus claim; scroll still asked when `revealedRow` is set. Value row's last page: focus to its first disclosure stop, no scroll, as today. Timeline participants: no scroll, as today.
- **Removed inputs.** None — the fold rule is moved, not changed.
- **Real data.** None — no table-driven rule.
- **Untrusted size.** None — no new list.

### Schema

None — no catalog change.

### Go core

None — Swift only.

### FFI

None — Swift only.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Show more row | `PVShowMoreRow` | `macos/App/DesignSystem/Components/ShowMoreRow/` *(new)* | `.buttonStyle(.pv(.ghost, size: .sm))`, `.focused(focus, equals: stop)`, `.pvActivatesOnReturn(when:_:)`, as today |
| Reveal scroll | `.pvScrollsShowMoreReveals()` / `PVShowMoreReveal` | same file | Family and Sources apply the modifier; the Timeline sets its own value |
| Fold rule and state | `PagedFold`, `PagedFoldState` | `macos/App/Platform/PagedFold.swift` *(new)* | — |

Accessibility identifiers stay on the call sites, unchanged.

### Strings

L10n key *(new)*: `L10n.DesignSystem.showMoreRowLabel(_:)` = `designSystem.showMoreRow.label`, "Show %lld more" (plural one and other), comment "Button under a folded list that shows the next page of it; argument is how many that page adds". Removed: `L10n.Conclusions.showMore`, `conclusions.showMore`.

## 7. Steps

**STEP-1 — Move the fold rule**
Files: `macos/App/Platform/PagedFold.swift` *(new)*, every file `rg -l "ConclusionFold" macos` lists, `macos/ProvenenciaTests/PagedFoldTests.swift` *(new)* (renamed from `ConclusionFoldTests.swift`). Skill: `add-swift-test`.
Do: per D-1; rename every use; rename the test file and struct; add T-2.
Check: `rg -n "ConclusionFold" macos` finds nothing; `xcodebuild test … -only-testing:ProvenenciaTests/PagedFoldTests` passes.

**STEP-2 — Add the kit row, its press rule and its scroll**
Files: `macos/App/DesignSystem/Components/ShowMoreRow/PVShowMoreRow.swift` *(new)*, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `macos/App/DesignSystem/README.md`, `macos/ProvenenciaTests/PVShowMoreRowTests.swift` *(new)*. Skills: `add-ui-component`, `add-localized-string`, `add-swift-test`.
Do: per D-2 to D-5, D-9, D-10. Add the README row after `ScrollRowIntoView`'s: `ShowMoreRow` | `Components/ShowMoreRow/PVShowMoreRow.swift` *(new)* (S15-30: the "Show N more" row under a list folded by `PagedFold`; after a key press it claims focus for the first revealed item and asks `\.pvShowMoreReveal` to scroll it into view; `.pvScrollsShowMoreReveals()` is the default provider; a pointer click neither moves focus nor scrolls; moved out of `Features/Conclusions`). Add T-3, T-4, T-5.
Check: `xcodebuild test … -only-testing:ProvenenciaTests/PVShowMoreRowTests -only-testing:ProvenenciaTests/PVShowMoreRowHostedTests` passes; `python3 scripts/check-guidance-names.py` passes.

**STEP-3 — The value row uses the kit row**
Files: `macos/App/Features/Conclusions/ReconciledValueRow.swift`.
Do: per D-8.
Check: builds.

**STEP-4 — Family and Sources hand their scroll to the kit**
Files: `PersonFamilySection.swift`, `PersonSourcesSection.swift`.
Do: per D-6 and **Deletes**.
Check: `rg -n "scrollTarget|scrollRequest|unfold" macos/App/Features/Conclusions/PersonFamilySection.swift macos/App/Features/Conclusions/PersonSourcesSection.swift` finds nothing; manual checks 1–3.

**STEP-5 — The Timeline provides its own reveal**
Files: `PersonTimelineSection.swift`.
Do: per D-7 and **Deletes**.
Check: `rg -n "ConclusionShowMoreRow|func unfold" macos/App/Features/Conclusions/PersonTimelineSection.swift` finds nothing; manual check 4.

**STEP-6 — Remove the old row and string**
Files: `ConclusionShowMoreRow.swift` (delete), `L10n.swift`, `Localizable.xcstrings`.
Do: per **Deletes**.
Check: `rg -n "ConclusionShowMoreRow|Conclusions.showMore|conclusions.showMore" macos` finds nothing; `python3 scripts/check-localizable-xcstrings.py` passes.

**STEP-7 — Docs and version**
Files: `docs/macos-client-patterns.md` ("One sectioned detail page": `ConclusionFold` → `PagedFold`, `ConclusionFoldState` → `PagedFoldState`, `ConclusionShowMoreRow` → `PVShowMoreRow`, and one clause: a section applies `.pvScrollsShowMoreReveals()`, or sets its own `PVShowMoreReveal` as the Timeline does, so a keyboard Show more scrolls its first revealed item into view), `../deployment-plan.md` (map row status), `../completed.md`, this plan, `VERSION`, `core/version.go`, `MARKETING_VERSION` lines.
Do: per the Definition of done.
Check: `scripts/check-pr.sh` prints `check-pr: PASS`.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `macos/ProvenenciaTests/PagedFoldTests.swift` *(new)* `PagedFoldTests` (all cases kept from `ConclusionFoldTests`) | 31 items at `limit: 30, minimumHidden: 1` → 30 shown, 1 hidden; 6 at `5, 2` → all shown; pages of 50 | AC-1.1, AC-1.3, D-1 |
| T-2 | Swift | `macos/ProvenenciaTests/PagedFoldTests.swift` *(new)* `eventsFoldPagesOf120` *(new)* | `PagedFold(limit: 50, minimumHidden: 1)` over 120 items: pages 0 → 50 shown, 1 → 100 shown, `nextPageCount(hidden: 20)` → 20 | AC-1.2 |
| T-3 | Swift | `macos/ProvenenciaTests/PVShowMoreRowTests.swift` *(new)* `PVShowMoreRowTests.pressMovesOnlyFromTheRow` *(new)* | `PVShowMorePress<Int>(startedOnRow: true, revealed: 6, revealedRow: 6)` → focus 6, scroll 6; `startedOnRow: false` → both nil; `startedOnRow: true, revealed: nil, revealedRow: 6` → focus nil, scroll 6 | D-3, AC-3.1 |
| T-4 | Swift | `macos/ProvenenciaTests/PVShowMoreRowTests.swift` *(new)* `PVShowMoreRowHostedTests.revealScrollsAfterTheCallerLeaves` *(new)*, suite `.serialized, .hostedWindows` | A 200 pt `ScrollView` of 12 rows of 60 pt tagged `.id(i)`, under `.pvScrollsShowMoreReveals()`, with a probe view that reads `\.pvShowMoreReveal`; on a trigger the probe calls it with `AnyHashable(11)` and the harness removes the probe in the same update → `eventually`, the `NSScrollView` (`descendant(_:in:)`) has `documentVisibleRect` containing y 660…720 | D-5, AC-2.1 |
| T-5 | Swift | `macos/ProvenenciaTests/PVShowMoreRowTests.swift` *(new)* `PVShowMoreRowTests.labelWordsThePage` *(new)* | `L10n.DesignSystem.showMoreRowLabel(1)` → "Show 1 more"; `(50)` → "Show 50 more" | D-9 |
| T-6 | Swift | `macos/ProvenenciaTests/L10nPluralTests.swift` `everyCatalogPluralPicksAFormPerCount` (existing) | The new plural key resolves for 1 and 2 | D-9 |

Each section's focus landing (AC-2.x) is the manual check: the hosted test pins the kit's scroll, not every section's ids.

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `PersonFamilyContentTests`, `PersonSourcesContentTests`, `PersonTimelineContentTests` (renames).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: `ConclusionFold`, `ConclusionFoldState`, `ConclusionShowMoreRow`, `L10n.Conclusions.showMore`, `conclusions.showMore` `rg`'d across `.agents/`, `.cursor/rules/`, `docs/*.md`, `macos/` and `L10n.swift` with no hit left outside `docs/deployment-plan/`; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none)
- [ ] UI matches today's; no new kit primitive beyond the ShowMoreRow folder's types
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Domain doc updated: docs/macos-client-patterns.md "One sectioned detail page"; macos/App/DesignSystem/README.md ShowMoreRow row
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

Use a Debug build and the dogfood project, or build the fixtures below in a scratch project. Regular width, then Wide.

1. A Person with 31 children: Family shows "Show 1 more" (AC-1.1). Click it with the pointer: the page does not scroll (AC-3.1).
2. Same Person, reopened, window short so "Show 1 more" is at the bottom edge: Tab to it, Return. The 31st tile has the focus ring and is in view; the row is gone (AC-2.1).
3. Sources: a Source with 9 record lines: Tab to "Show 4 more", Space: the 6th line's link has the keyboard and is in view (AC-2.2). With 60 Sources: Tab to the rows' "Show 10 more", Return: the 51st Source's first line has the keyboard and is in view (AC-2.3). A pointer click on either does not scroll (AC-3.1).
4. Timeline with 120 dated events: click "Show 50 more": 100 events, no scroll (AC-1.2, AC-3.1). Reopen; Tab to it, Return: the 51st title has the keyboard and scrolls to the top once placed (AC-2.4). A lifeline click on a folded point still opens through its page and scrolls (unchanged).
5. An Event or Place row with more than 21 listed lines: Show more by keyboard to the last page: the keyboard lands on the row's first disclosure, no scroll, as today.
6. Open a row from Family, then Back: the row has the keyboard (S16-46 unchanged).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| An `AnyHashable` target does not find a tile tagged `.id(String)` | `PVFormDialog` already scrolls this way; T-4 tags `Int` ids; manual checks 2 and 3 |
| The always-equal `PVShowMoreReveal` keeps a stale closure | The closure writes only to its provider's `@State`, whose storage outlives body passes (D-4) |

**Stop and report if:**

- T-4 fails because the scroll does not run once the caller left the tree (D-5 does not hold).
- Manual check 2, 3 or 4 shows the revealed item not scrolled into view after a keyboard press.
- `scripts/check-guidance-names.py` reports a kit file naming a `Features/` type after STEP-2.
- Any fold count in §2 differs from today's after STEP-1.

## 12. Open questions

None.

## 13. PR

**Title:** S15-30 — The paged fold moves to the kit
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-30-show-more-row-kit.md`.

## Landed

- The kit commit `98d25b8ce` does not build alone: the strings it needs land in `9a003305f`.
- An extra T-4 commit, `d333cc4f2`, lays the test's list out before the caller asks for the scroll.
- `pvScrollsShowMoreReveals` takes `animated:` (default `true`, passed on to `pvScrollsRowIntoView`), and the T-4 harness passes `false`: an unshown window, or a CI runner with no display, steps no animation, so an animated scroll may never land. A first try, `.transaction { $0.disablesAnimations = true }` on the harness, left the scroll animated (traced: about 200 ms from 0 to 520) and CI failed on it.
- After the fix round, T-4's probe is shown from the start; on appear it asks `reveal(AnyHashable(11))` and then calls a `leave()` closure from the harness that clears `probing` in the same action, as `PVShowMoreRow.press` does on the last page. It no longer defers the leave with `DispatchQueue.main.async`.
- The Timeline's `.environment(\.pvShowMoreReveal, …)` sits on the `PVWidthBreakpoints` list beside `pvScrollsRowIntoView`.
- The manual check (section 10) was not run by the implementer.
