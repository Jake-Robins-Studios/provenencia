# S16-67 — The Persons, Events and Places lists are native lists

**Status:** Landed in [#958](https://github.com/Jake-Robins-Studios/provenencia/pull/958) (2026-11-23)
**Spike / slice:** Spike 16 · Slice 6f — List keyboard
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S16-D13](../design/archive/S16-D13-conclusion-lists-native.md), board agreed 2026-11-23
**Board:** [Persons List](https://claude.ai/artifact/MQtjRymfDNraEx9roK69q4), page "Persons List" (frames L1a–L7b). The implementer opens the link; §6 macOS also describes each frame in words, and the brief's **Board** line records every choice the board made
**Depends on:** S16-D13 (agreed 2026-11-23)
**Blocks:** S16-66
**Branch:** `s16-67-native-conclusion-lists`
**Version bump:** minor, 0.34.1 → 0.35.0 — three pages change how a researcher works them (a click selects, a double-click or Return opens), no wire or catalog change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-workspace-location`](../../../../.agents/skills/add-workspace-location/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md) (no new key; the Sources header's copy moves)
**Rules that bind:** —
**Context:** map scope entry [S16-67](../deployment-plan.md#s16-67--the-persons-events-and-places-lists-are-native-lists); bar 37; working rule "(Batch 6) The Conclusion lists are native lists"; [`docs/macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide); kit README "The table tradeoff" (`macos/App/DesignSystem/README.md`); the S16-65 ship log on branch `origin/s16-65-list-focus-stop` (S16-65-list-focus-stop.ship.md there: why Home/End on a `LazyVStack` raced its estimated height)
**Runs on:** macOS with Xcode. The Swift checks (`xcodebuild test`, `scripts/check-pr.sh`, previews) need a Mac; STEP-8 and §10 need a person at the Mac. An agent on another platform hands those checks to the user and says which it could not run.
**Planned:** 2026-11-23 against `main` @ `f9114de40`
**Review:** [`S16-67-native-conclusion-lists.review.md`](S16-67-native-conclusion-lists.review.md) — Fits with changes / Ready with changes, 2 rounds; every blocker Fixed; no To user item

**Landed:** differences from the plan. (1) The version bump is 0.35.0 → 0.36.0: main was already 0.35.0 when the PR began (S15-63 landed after the plan; the coordinator's course correction). (2) AC-1.3's 66 pt row needed `.frame(height: thumbnailSize)` on the row's content: the text column's natural height is 47 pt, which made a row with a secondary line 69 pt. (3) D-1's `listRowInsets` take `horizontalInset` less 8 pt (`PVList.platformCellInset`): the platform's table lays each cell in 8 pt on each side, so the plan's insets put the content at 40 pt, not 32. (4) T-1 compares the colors as drawn under each appearance (`NSAppearance.performAsCurrentDrawingAppearance`) on the main actor; resolving a dynamic color through `Color.resolve(in:)` hung the test run. (5) The map row's scope text names `PVListPageHeader` and navigation's `listAnchor`. STEP-8 (the implementer ran what a hosted window allows; the rest is the user's manual check):
- type-select: not yet checked (user's manual check)
- ⌥↑/⌥↓: not yet checked (user's manual check)
- VoiceOver reading a row and Return opening it: VoiceOver not yet checked (user's manual check); Return opens the selected row — works (hosted `NSTableView`, the table's own key handling reached the primary action; D-2's `.onKeyPress(.return)` fallback was not needed)
- iron selection in dark appearance: not yet checked (user's manual check); a selected row's `backgroundProminence` is `.increased` once its row view is emphasized (hosted), `.standard` while not
- D-12 separator branch: the system separators (`.listRowSeparator`) shipped; they draw a hairline under each row (hosted bitmap), starting at the title's leading edge and running to the trailing edge
Also found: the platform's own table scrolls to the first and last row on Home and End with the selection unchanged, so `PVList`'s D-5 handler may be redundant on this macOS (kept as planned; noted in `docs/ideas/kit-layering.md`).

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

The Persons, Events and Places pages list a catalog's records of one kind, from tens to 16,000 rows. Their list moves onto the native macOS list (SwiftUI's `List`, an `NSTableView`), so selection, ↑/↓, Page Up/Down and scrolling come from the platform at any size. The pages are redrawn to the agreed S16-D13 board: the list pages' header across the pane, the list filling the pane under it at every width, a click that selects and a double-click or Return that opens. Back returns to the list with the row it opened selected and in view.

**Why now.** S16-65's hand-built keyboard on a `LazyVStack` failed its manual checks: Home and End stopped short because AppKit scrolled to a lazy stack's estimated height, nondeterministically (PR #951, closed). The user moved these lists to the native list (working rule "(Batch 6) The Conclusion lists are native lists", 2026-11-23).

**What stays.** What a row says (thumbnail, title with +N, secondary line, updated column, ref); the order (Go sorts); the empty, loading and failure copy; the page each row opens; the query per page. The Sources, Source types, Metadata and Properties pages look the same, except the Sources header's 4 pt (D-3).

## 2. User stories

**US-1.** As a researcher on the Persons, Events or Places page, I see the page's header across the pane and the list filling the pane under it, at Regular and Wide, so the list reads as the page.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Persons with 1,204 rows, pane 1102 pt (Regular) | The header shows `Persons` (display h1) and `1,204 persons` (mono micro) at its trailing end, inset 32 pt, with a full-width hairline under it; the list runs from the pane's left edge to its right edge and down to its bottom, with no card border, no rounded corners and no gutter outside it (CL-1, CL-2) |
| AC-1.2 | The same, pane 2296 pt (Wide) | Header and rows inset 56 pt (`gutterPageWide`); the title column takes the extra width; the updated column and the ref stay at the trailing edge (CL-W1 (a)) |
| AC-1.3 | A row | Left to right: the 44 pt thumbnail, the title (one line, ellipsis) with its +N badge over the secondary line, the 136 pt updated column, the mono ref; no chevron; the row is 66 pt tall; a row with no secondary line keeps 66 pt with its title centered on the thumbnail (CL-3) |
| AC-1.4 | An Event titled `Marriage of Hannah Wilhelmina Fitzgerald-Montmorency de Saint-Ours and Jean-Baptiste Leduc` at Regular | The title truncates with an ellipsis before the updated column; the updated column and the ref do not move or truncate (CL-10) |
| AC-1.5 | First load | The header with no count line; skeleton rows at row geometry fill the list area, full width, separated as the rows are (CL-7, CL-W2) |
| AC-1.6 | No Persons | The header with no count line; `PVEmptyState` with the Person mark, `No persons yet` and today's message, centered in the list area (CL-8, CL-W2) |
| AC-1.7 | The read fails | The header with no count line; a danger `PVCallout` with today's message at the top of the list area, its leading edge on the gutter, at most `PVSpacing.measureForm` wide (CL-9, CL-W2) |
| AC-1.8 | A reload while rows show | The count line reads `1,204 persons · refreshing`; rows stay; nothing animates in or out (CL-1, brief § 2.1 Animation) |
| AC-1.9 | The window is resized across 1600 pt with a row selected, scrolled mid-list | The selection, the scroll position and keyboard focus stay; only the insets change (§ 9 rule 5) |

**US-2.** As a researcher, a click selects a row and the list shows it selected; a double-click or Return opens its page.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Click `Josephine Marchand` | The row is selected with the system's full-width bar in the system accent; its title, secondary line, updated column and ref draw in the system's on-selection ink (white, in light and dark appearance); the thumbnail and the +2 badge keep their colors; no page opens (CL-4) |
| AC-2.2 | The window loses focus with that row selected | The bar turns grey; the row's text keeps its own ink (CL-4) |
| AC-2.3 | Double-click a row | Its record page opens (CL-5) |
| AC-2.4 | Select a row, press Return | Its record page opens (CL-5) |
| AC-2.5 | Hover a row | Nothing changes (no hover tint) |
| AC-2.6 | Right-click a row | No menu appears |

**US-3.** As a researcher using the keyboard, the list takes the keys on arrival, at any size.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Open Persons from the sidebar, press ↓ without clicking | The first row is selected (the list had keyboard focus on arrival; no focus ring around the list) (CL-6) |
| AC-3.2 | 16,000 persons, nothing clicked: End | The list shows its last row at the bottom; the selection does not change. Home shows the first row at the top. Every time, on a fresh load too |
| AC-3.3 | Page Down / Page Up | The list scrolls by a screen (the platform's) |
| AC-3.4 | ↓ / ↑ with a row selected | The selection moves one row and stays in view (the platform's) |

**US-4.** As a researcher, Back returns me to the row I left.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | Persons from the sidebar | Nothing selected; the list at its top (CL-6) |
| AC-4.2 | Double-click row 800 of 1,204, then Back | Row 800 is selected and in view (CL-6) |
| AC-4.3 | Select row 800, then open Events from the sidebar, then Back | Row 800 is selected and in view (CL-6) |
| AC-4.4 | Select row 800, click the empty area under the last row (or ⌘-click the row) so nothing is selected, open Events, then Back | Nothing selected; the list at its top (CL-6) |
| AC-4.5 | Back to an entry whose row was deleted meanwhile | Nothing selected; the list at its top |
| AC-4.6 | The Sources and Source types lists | Back restores their top row as today |
| AC-4.7 | Select row 800, click Persons in the sidebar again, open Events, then Back | Nothing selected after the second click, and nothing selected on Back: the screen and the history agree |

## 3. Scope

| In | Covered by |
| --- | --- |
| CL-1 header (`PVListPageHeader`, from `VocabularyHeader`) | STEP-1, STEP-6, AC-1.1, AC-1.8 |
| CL-2 the list fills the pane | STEP-3, STEP-6, AC-1.1 |
| CL-3 rows on the native list, no chevron | STEP-3, AC-1.3 |
| CL-4 system selection, on-selection ink | STEP-2, STEP-3, AC-2.1, AC-2.2 |
| CL-5 double-click and Return open | STEP-3, AC-2.3, AC-2.4 |
| CL-6 focus on arrival; Back restores the selected row | STEP-3, STEP-5, STEP-6, AC-3.1, AC-4.1 – AC-4.5, AC-4.7 |
| CL-7 loading skeleton without its card | STEP-4, STEP-6, AC-1.5 |
| CL-8 empty state centered in the list area | STEP-6, AC-1.6 |
| CL-9 failure Callout at the top of the list area (`.pvListPageMessage`, shared with four list pages) | STEP-1, STEP-6, AC-1.7 |
| CL-10 long titles truncate | STEP-3, AC-1.4 |
| CL-W1 (a) the title column takes the Wide width, 56 pt gutters | STEP-6, AC-1.2 |
| CL-W2 the states at Wide | STEP-4, STEP-6, AC-1.5 – AC-1.7 |
| Home and End scroll to the first and last row | STEP-3, AC-3.2 |
| The Sources header moves onto `PVListPageHeader` | STEP-1 |
| Prove type-select, ⌥↑/⌥↓, VoiceOver and the iron selection in dark (brief § 2 "expected") and record the result | STEP-8 |
| Docs and skills the scope entry names | STEP-9 |

| Out | Home |
| --- | --- |
| The Sources list's rows and keyboard | S16-66 |
| `PVTable` (Source types, Metadata, Properties) on the native list | [`docs/ideas/kit-layering.md`](../../../ideas/kit-layering.md) entry this PR adds (STEP-9) |
| Page keys on other pages | re-planned after S16-67 (map, S16-65 entry) |
| A context menu, filters, sorting, a search field or a New button on these lists | not planned (brief § 2.2) |
| Type-select or ⌥↑/⌥↓ written by the app if the platform lacks them | [`docs/ideas/kit-layering.md`](../../../ideas/kit-layering.md) entry this PR adds (STEP-9), with STEP-8's finding |
| A separator inset on the trailing side when the platform offers only a leading one | not planned (brief **Board** line: the separator then runs to the row's trailing edge) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Browse list | `macos/App/DesignSystem/Components/List/PVList.swift` `PVList` | A `LazyVStack` of `Button` rows inside the caller's `ScrollView`, in a card (`pvListChrome`); its own focus stop with `@FocusState isFocused`, `focusIndex`, `.onKeyPress` through `PVListKeyboard.action`, and `.pvScrollsRowIntoView`. A click opens (`onActivate`). Slots: optional `thumbnail`, `primary`, `secondary`, `meta` (the ref), `detail` (`PVListDetailColumn`), `chevron` (default true), `density`. One caller: `ConclusionListPage`. Its keyboard is the S16-65 failure |
| Row chrome | `PVList.swift` `PVListRowStyle`, `PVListRowBody` | Card at rest, hover and pressed tints, focus ring. Callers: `PVList` (`focused:` its own) and `macos/App/Features/Sources/SourcesListRow.swift:74` (`focused: nil`) |
| Detail cell | `PVList.swift` `PVListDetailCell` | Icon and text in `textMuted` / `textFaint`. Also used by the Sources row's second line |
| Keys | `PVList.swift` `PVListKeyboard.moveIndex`, `.action` | `moveIndex` is called by `PVContextMenu`, `PVPopupList`; `action` by `PVTable.swift:44` (activation) and `PVList` |
| Skeleton | `PVList.swift` `PVListSkeleton` | Rows in a card (`pvListChrome`), `PVDivider` overlays at each row's full width. One caller: `ConclusionListPage.skeleton()` |
| Card chrome | `PVList.swift` `pvListChrome()` (private) | Callers: `PVList`, `PVListSkeleton` |
| Native list precedent | `macos/App/DesignSystem/Components/ReorderableList/PVReorderableList.swift` `PVReorderableList` | `List` + `ForEach`, `.listRowInsets(EdgeInsets())`, `.listRowSeparator(.hidden)`, `.listRowBackground(Color.clear)`, `.listStyle(.plain)`, `.scrollContentBackground(.hidden)`, `defaultMinListRowHeight` 1 |
| Page | `macos/App/Features/Conclusions/ConclusionListPage.swift` `ConclusionListPage`, `ConclusionListBody` | `page(meta:body:)`: a `ScrollView` with `PVSectionHeader` and the body in a 1180 pt column (`widthContentMax`) with `gutterPage` padding; reads no width class. States from `ConclusionListPresentation` (tested). `onActivate` → `navigation.go(to: Kind.location(…))`. Wears `ListScrollAnchorModifier` with every row id (`scrollRowIDs`) |
| Kinds | `PersonsListView.swift` `PersonsList`, `PersonLifeLine`; `EventsListView.swift` `EventsList`, `EventSecondaryLine`; `PlacesListView.swift` `PlacesList`, `PlaceChainLine`; `ConclusionListRow.swift` `ConclusionListRow.updatedColumn` | Supply the slots. Their doc comments name `PVList` ("so `PVList` lays out no second line") |
| Title | `macos/App/DesignSystem/Components/TitleText/PVTitleText.swift` `PVTitleText` | In row style, the `.ref` branch sets its own `textSecondary` (lines 122–127); `.name` and `.label` inherit the caller's style. Lines 147–158 are the display style, not used in rows |
| Date and place | `macos/App/DesignSystem/Components/DatePlaceLine/PVDatePlaceLine.swift` `PVDatePlaceLine` | Draws its own ink (`textMuted`, `textFaint`, `textSecondary`, `dateTone`) |
| List page header | `macos/App/Features/CatalogVocabulary/VocabularyChrome.swift` `VocabularyHeader` | Title (display h1), description (required), count line, Add button (required); `gutterPage` horizontal, `space8` top, `space6` bottom. Callers: `MetadataView.swift:114`, `PropertiesView.swift:144`, `SourceTypesView.swift:69` |
| Sources header | `macos/App/Features/Sources/SourcesListView.swift:131` `header(visibleCount:)` | A copy of `VocabularyHeader`'s layout with `space7` bottom, the count line hidden when the catalog is empty, `sources.countLine` / `sources.add` |
| Back to a list | `macos/App/Features/Workspace/WorkspaceNavigation.swift` `noteListScroll(_:)` (definition line 99; the modifier calls it at lines 305, 316, 334), `performGo` / `performBack` / `performForward` / `performIndex`, `ListScrollAnchorModifier` | A list reports a row id (`noteListScroll`) into `pendingListScrollAnchor`; leaving the entry stamps it (`NavigationHistoryStore.stampListScrollAnchor`) onto `WorkspaceLocation.listScrollAnchor`; `apply` resets the pending id to the entry's anchor. `ListScrollAnchorModifier` scrolls a `ScrollView` to the anchor and reports the top row as the researcher scrolls. Callers: `ConclusionListPage`, `SourceTypesListPane.swift:50`, `SourcesListView.swift:307` |
| Focus claim | `macos/App/Platform/FocusClaim.swift` `FocusClaim.claim` | The app's one deferred focus writer (next turn, again a turn later); kit caller `PVFieldFocus.swift:40` |
| Settled read | `macos/App/Features/Workspace/Session/QueryHandle.swift` `isSettled` | Ready, not fetching, not stale |
| Failure placement | `SourceTypesView.swift:50–54`, `MetadataView.swift:55–59`, `PropertiesView.swift` `PropertiesContent`, `SourcesListView.swift:66–70` | The same `PVCallout(.danger)` padding and top-aligned frame written four times |
| On-selection ink | `macos/App/DesignSystem/Tokens/PVColor.swift:25` `textInverse` | `paper0` light, `paper950` (near-black) dark: not white on a dark-mode selection |
| Section anchor (not used here) | `WorkspaceNavigation.go(to:from:)`, `ConclusionAnchorRestore.swift` | A record page's row anchor; not a list's |
| Width class | `@Environment(\.pvWidthClass)` (`SourceTypesView.swift:44`); `PVSpacing.gutterPage` 32, `gutterPageWide` 56 (no caller yet), `measureForm` 560 | |
| Tests | `macos/ProvenenciaTests/PVListTests.swift`; `PersonsListTests.swift` (presentation, meta, locations, labels); `PlacesListTests.swift`; `WorkspaceNavigationTests.swift` (`notingListScrollDoesNotPushHistory`, `leavingAListStampsTheOutgoingEntry`, `sourceTypesListIsAListRoot`, lines 590–665) | |

**Precedent.** `PVReorderableList` (S2-25) is the kit's native-list setup: copy its `List` modifiers (plain style, hidden content background, row insets). Do not copy its height measuring or `scrollDisabled`: this list is its own scroll view and fills the pane. For the header move, `VocabularyHeader` itself is the code; it moves and generalizes.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `PVList` is rebuilt on `List(selection:)` with `ForEach(items)`. One initializer remains: today's thumbnail-and-secondary one (`items`, `thumbnail` now required, `thumbnailSize`, `meta`, `detail`, `density`, `label`, `itemAccessibilityLabel`, `itemAccessibilityIdentifier`, `onActivate`, `primary`, `secondary`), plus `selection: Binding<Item.ID?>` and `horizontalInset: CGFloat` (default `density.horizontal`); `chevron`, the two `EmptyView` convenience initializers and the `optionalThumbnail` path are deleted. Setup: `.listStyle(.plain)`, `.scrollContentBackground(.hidden)`, `.listRowInsets(EdgeInsets(top: density.vertical, leading: horizontalInset, bottom: density.vertical, trailing: horizontalInset))`, `.listRowSeparator(.visible)`, `.listRowSeparatorTint(PVColor.borderSubtle)`, `.focusEffectDisabled()`, no `listRowBackground`, `.transaction { $0.animation = nil }` on the `ForEach` | The platform owns selection, ↑/↓, Page keys and scrolling (working rule). No row background leaves nothing over the system selection; the area's `surfaceCard` is drawn behind the transparent list. The rebuild rewrites every line, so paths with no app caller go (only the previews used them) | Keeping the unused initializers and `chevron`; a `listRowBackground(surfaceCard)` that risks covering the selection |
| D-2 | Double-click and Return open through `.contextMenu(forSelectionType: Item.ID.self, menu: { _ in EmptyView() }, primaryAction: { ids in … })`. The list is single-selection, so `ids` holds at most one id; `PVList` opens `items.first { $0.id == id }` for the first id and does nothing when no item has it. If Return does not reach the primary action on macOS 14 (STEP-3's check), `PVList` adds `.onKeyPress(.return)` on the `List` that opens the selected item the same way and returns `.handled` (`.ignored` with no selection); double-click stays on the primary action | The platform's primary action is double-click and Return on a `List`; an empty menu shows no menu (AC-2.6). The fallback is decided here so the implementer does not stop on it | `onTapGesture(count: 2)` — fights the click selection |
| D-3 | `VocabularyHeader` moves into the kit as `PVListPageHeader` *(new)* at `macos/App/DesignSystem/Components/ListPageHeader/PVListPageHeader.swift`: `title`, `description: LocalizedStringResource?`, `countLine: String?`, `add: PVListPageHeader.Add?` (`label`, `isDisabled = false`, `size: PVControlSize = .md`, `action`), `identifierPrefix`, `descriptionItalic = false`, `gutter: CGFloat = PVSpacing.gutterPage`. Metrics are `VocabularyHeader`'s (`space8` top, `space6` bottom). Metadata, Properties, Source types and Sources call it; the Sources header loses 4 pt under it (`space7` → `space6`). The Conclusion pages pass `identifierPrefix: Kind.identifierRoot`, so they mint `persons.countLine` and so on | CL-1 says "as Source types, Metadata and Properties draw it", so their metrics win; three pages unchanged and one 4 pt change beats the reverse. One header for every list page | A padding knob for Sources' 4 pt; a Conclusion-only third copy |
| D-4 | The on-selection ink is one token-level style: `PVColor.onSelection(_ base: Color) -> PVOnSelectionStyle` *(new, `macos/App/DesignSystem/Tokens/PVColor.swift`)*, a `ShapeStyle` whose `resolve(in:)` returns `Color(nsColor: .alternateSelectedControlTextColor)` when `environment.backgroundProminence == .increased`, else `base`. Every ink a row draws is passed through it: `PVList`'s secondary and ref, `PVListDetailCell` (both its colors), `PVTitleText`'s `textSecondary` (set for every style but `.rowLink`, which inherits the caller's style; `PVList` passes `.rowLink`, whose ink is `PVList`'s wrapped style), and every ink in `PVDatePlaceLine` including the caller's `dateTone`. `PVBadge` and `PVThumbnail` keep theirs. No view adds an `@Environment` property | The platform sets `.increased` on a focused selected row and its text color for that state is `alternateSelectedControlTextColor` (white in light and dark: brief CL-4). `PVColor.textInverse` is near-black in dark appearance, so it is not used. One style reads the environment once per resolve; no new palette token | `textInverse` — wrong in dark; four `@Environment` reads with a helper in `PVList.swift` |
| D-5 | Home and End: `.onKeyPress(keys: [.home, .end])` on the `List`. The handler calls `PVListKeyboard.moveIndex(for: press.key, option: false, index: 0, count: items.count)`; for a result in `items.indices` it sets `@State edgeRow: Item.ID?` to that row's id and `edgeAnchor` to `.top` (Home) or `.bottom` (End), increments `@State edgeRequest: Int`, and returns `.handled`; with no rows it returns `.ignored`. One modifier scrolls: `.pvScrollsRowIntoView(edgeRow, anchor: edgeAnchor, animated: false, whenRequested: edgeRequest)`. The selection does not change | Brief § 2 (Finder's Home/End). A native list scrolls to a row by index, not to an estimated height, so the S16-65 race does not occur. The counter makes every press scroll | A new `edgeIndex` wrapper — `moveIndex` already answers Home and End (`PVListTests.optionArrowsAndHomeEndJumpToTheEnds`); setting the selection — not Finder's |
| D-6 | Focus on arrival: `PVList` holds `@FocusState isFocused`, `.focused($isFocused)` on the `List`, and `.onAppear { FocusClaim.claim($isFocused, true) }` | `FocusClaim` is the app's one deferred focus writer (`macos/App/Platform/FocusClaim.swift`), with the second-turn retry a freshly mounted list needs; `PVFieldFocus` already calls it from the kit | A hand-written `Task { @MainActor … }` |
| D-7 | The selected row has one owner: navigation. `WorkspaceNavigation.listAnchor: String?` (D-8; `private(set)`, observed, no longer `@ObservationIgnored`) is the live list anchor: `apply` sets it to the entry's `listScrollAnchor` on every commit (a push, a coalesced visit, Back, Forward, a jump), and `noteListAnchor(_:)` writes it. `ConclusionListBody` holds no selection state: it passes `PVList` `selection: Binding(get: { navigation.listAnchor }, set: { navigation.noteListAnchor($0) })`. `ListSelectionAnchorModifier` *(new, `WorkspaceNavigation.swift`)* `(rowIDs: [String], isSettled: Bool)` has one job: `.onChange(of: isSettled, initial: true)` and `.onChange(of: rowIDs)`, when `isSettled` is true and `navigation.listAnchor` is not nil, set `navigation.noteListAnchor(ListAnchor.resolved(navigation.listAnchor, in: rowIDs))`, which clears an anchor whose row is gone and leaves a listed one. `ListAnchor.resolved(_ anchor: String?, in ids: [String]) -> String?` *(new, same file)* is the one resolve rule; `ListScrollAnchorModifier`'s two inline copies call it. `PVList` scrolls the selection into view when it first appears with one: `.pvScrollsRowIntoView(selection.wrappedValue, animated: false, scrollsOnAppear: true)` (a second modifier on the `List`, no token). `ListScrollAnchorModifier` leaves this page | One stored value: the row drawn selected is the row history stamps, on every path (a coalesced visit resets it through `apply`, AC-4.7; a click during a refetch is never overwritten by a later restore). A row opens only through the selected row, so the opened row is the anchor; no new field and no `go(to:)` overload. Clearing waits for a settled read, as `conclusionAnchorRestore` does. S16-66 gets a binding and one modifier | View `@State` synchronised with navigation's pending anchor (round 2, M-11: a coalesced visit from nil to nil fires no change, so the two disagree); the map's `go(to:)` overload |
| D-8 | The list anchor's names lose "scroll" where they are not persisted: `pendingListScrollAnchor` → `listAnchor` (observed, `private(set)`, D-7), `noteListScroll` → `noteListAnchor`, `normalizedScrollAnchor` → `normalizedListAnchor`, `NavigationHistoryStore.stampListScrollAnchor` → `stampListAnchor`. The persisted `WorkspaceLocation.listScrollAnchor` and `withListScrollAnchor(_:)` keep their names; their docs and the renamed ones say a list's anchor row is its top row (Sources, Source types) or its selected row (Persons, Events, Places). Observing `listAnchor` invalidates only views that read it: the Conclusion list body; the Sources and Source types scroll reports write it with no reader | One concept, one name; the stored key stays so history files still decode | Renaming the persisted key |
| D-9 | `PVListSkeleton` loses its card and takes `horizontalInset`; its rows separate with a `PVDivider` inset by `horizontalInset` on both sides. The page shows `PVListSkeleton(rows: 30, detailWidth: PVLastUpdated.columnWidth, horizontalInset: gutter)` in `.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).clipped()` | 30 × 66 pt covers a 1,980 pt area; the board draws inset separators | A `GeometryReader` to count rows |
| D-10 | The page chrome is a view: `ConclusionListFrame<Content: View>` *(new, private to `ConclusionListPage.swift`)* `(title:, meta:, identifierRoot:, content: (CGFloat) -> Content)` reads `@Environment(\.pvWidthClass)` once, takes `gutter = widthClass.fullPaneGutter`, and draws a `VStack(spacing: 0)`: `PVListPageHeader(gutter:)` on `PVColor.surfacePage`, `PVDivider()`, then `content(gutter)` in `.frame(maxWidth: .infinity, maxHeight: .infinity)` on `PVColor.surfaceCard`. It carries `<root>.list`. Both `ConclusionListPage.body`'s no-handle branch and `ConclusionListBody` use it, replacing `static page(meta:body:)`. `PVWidthClass.fullPaneGutter` *(new, `PVWidthClass.swift`)*: `gutterPageWide` at `.wide`, else `gutterPage`; its doc says it is the gutter of a list that fills the pane, and other pages keep `gutterPage`. No outer `ScrollView` | One place chooses the gutter for every state; the width class owns the width-to-gutter rule (`gutterPageWide` has no caller yet) | `pvListBand` — the brief bends § 9 rule 3 here; recomputing the gutter in each state |
| D-11 | The state contents are static builders on `ConclusionListPage` so the previews and the body draw the same: `loadingArea(gutter:)` (D-9), `emptyArea()` (`PVEmptyState` as today, centered by the frame's area), `failureArea(_ message:, gutter:)`. The failure placement is one kit modifier the four list pages already write by hand: `.pvListPageMessage(gutter: CGFloat = PVSpacing.gutterPage, maxWidth: CGFloat? = nil)` *(new, `PVListPageHeader.swift`)* = `.frame(maxWidth: maxWidth ?? .infinity, alignment: .leading).padding(.horizontal, gutter).padding(.top, PVSpacing.space8).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)`. Source types, Metadata, Properties and Sources move onto it with no `maxWidth` (unchanged look); the Conclusion pages pass `maxWidth: PVSpacing.measureForm` | Five copies become one; the board's cap stays on the board's pages only, so no other page changes; `measureForm` is the nearest readable width and the brief forbids a new token (the board's 640 pt is not one) | A 640 literal; capping all five pages — a visual change no board drew |
| D-12 | Separators: STEP-3 ships the system separators (D-1) and looks at a Persons row in the app or the preview before STEP-4. If `.listRowSeparator(.visible)` draws no hairline in the plain style on macOS 14, the row draws a `PVDivider` at its bottom inside the row insets, as the skeleton does (D-9), and the system separator calls are dropped, in STEP-3 | Decided now, with the moment to look; the board's look is the same | Rows without separators |
| D-13 | Accessibility: each row stays one element with today's label and identifier (`<root>.row.<ref>`), without `.isButton`; the list keeps `label` as its accessibility label | A selectable row is not a button; Return opens it (the platform's) | A custom "Open" action and a new string for what Return does |
| D-14 | `PVListRowStyle` and `PVListRowBody` move to `SourcesListRow.swift` as `private` `SourcesListRowButtonStyle` and its body, without the `focused` parameter (its one caller passed nil) | The scope entry: beside its one remaining caller | A kit type with one feature caller |

**Rules this plan bends.** [`docs/macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide) rule 3 (a list with nothing more to show keeps a 1600 pt maximum at Wide): these three lists fill the pane at every width → the selection and the clickable row run edge to edge → the user, 2026-11-23 (working rule "(Batch 6) The Conclusion lists are native lists"; CL-W1 (a) picked on the board) → STEP-9 records the exception in § 9 and its "List → detail page" row; rule 3's text is not changed.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `PVListPageHeader` *(new)* | component | `VocabularyHeader`, `SourcesListView.header(visibleCount:)` | It **is** `VocabularyHeader`, moved into the kit with description and Add optional; the Sources copy is deleted onto it |
| `.pvListPageMessage(gutter:maxWidth:)` *(new)* | modifier | the hand-written placement in `SourceTypesView.swift:50–54`, `MetadataView.swift:55–59`, `PropertiesView.swift` (`PropertiesContent`), `SourcesListView.swift:66–70` | Those four move onto it |
| `PVColor.onSelection(_:)` / `PVOnSelectionStyle` *(new)* | token style | `PVColor.textInverse` (near-black in dark); no `backgroundProminence` read in the app | One rule for every ink a selected row draws |
| `PVWidthClass.fullPaneGutter` *(new)* | property | `PVSpacing.gutterPageWide` (no caller), `PVTable`'s `gutter:` parameter | The first reach for the token goes through the width class; named for the lists that fill the pane, since every other page keeps `gutterPage` at Wide |
| `ListSelectionAnchorModifier` *(new)* | modifier | `ListScrollAnchorModifier` | That one scrolls a `ScrollView` and reports its top row, with pinning for estimated heights; this one only clears a vanished anchor. Both share `ListAnchor.resolved`; navigation's `listAnchor` is the selection |
| `ListAnchor.resolved(_:in:)` *(new)* | func | `ListScrollAnchorModifier.applyIfReady` and its `.onChange(of: rowIDs)` (two inline copies) | Extracted, not new: the two copies call it |
| `ConclusionListFrame` *(new, private)* | view | `ConclusionListPage.page(meta:body:)` (static) | Replaces it; a view can read the width class |
| `SourcesListRowButtonStyle` *(moved)* | type | `PVListRowStyle` | Moved |

**Builds on.** `PVReorderableList`'s native setup; `pvScrollsRowIntoView` (`scrollsOnAppear`, `whenRequested`); `FocusClaim`; the history's pending list anchor; `QueryHandle.isSettled`; `ConclusionListPresentation` unchanged.
**Deletes.** `VocabularyHeader`; the layout in `SourcesListView.header(visibleCount:)`; the four hand-written failure placements; `pvListChrome()`; in `PVList`: `chevron`, the two `EmptyView` initializers, `optionalThumbnail`, `focusIndex`, `currentIndex`, the `.onKeyPress` body and the `Button` row; `PVListRowStyle` / `PVListRowBody` from the kit (moved); `ConclusionListPage.page(meta:body:)` and `skeleton()`; `ConclusionListBody.scrollRowIDs`, `scrollIsLoaded` and its `ListScrollAnchorModifier`; the old anchor names (D-8). `PVListKeyboard.action` stays (`PVTable`).
**Next adds.** S16-66: the Sources list either moves onto `PVList` with `ListSelectionAnchorModifier` (one call) and already has `PVListPageHeader` and `.pvListPageMessage`, or keeps its rows with `SourcesListRowButtonStyle`. A later `PVTable` on the native list reuses `PVColor.onSelection`.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A list entry whose anchor is a selected row, not a top row | `navigation.listAnchor` bound to `PVList` | Missing row → cleared once the read settles, list at top (AC-4.5, T-3); a history file written before this PR holds a top-row id, which restores as a selection of that row, a row the researcher saw |
| A coalesced visit to the same list (sidebar click on Persons while on Persons) | `WorkspaceNavigation.apply` | `listAnchor` becomes the entry's anchor (nil from the sidebar), so the selection clears with no Back (AC-4.7, T-4) |
| A selected row whose record a reload removes | `ListSelectionAnchorModifier` | Cleared when the new rows settle, anchor nil |
| Return or double-click while a reload replaces rows | `PVList` primary action | An id with no item does nothing (D-2) |

### Scale

At the Batch 2 Scale (16,000 persons): `NSTableView` builds rows lazily at a fixed 66 pt; `ForEach(items)` takes the array without `enumerated()`. `ConclusionListBody` builds the row-id array the modifier takes once per body pass, as today's `scrollRowIDs` does (16,000 strings, the same cost as today, no new pass). `ListAnchor.resolved` and the primary action each do one O(n) search per restore, anchor change or open. The budget: Persons at 16,000 shows rows no slower than at the base, and End shows the last row on the first press after a fresh load (AC-3.2), on the user's 16,000-person project.

### Edges

- **Assumptions.** The opened row is the selected row (D-2, D-7): the primary action receives the selection. Row ids are unique per list (entity ids).
- **Neighbors.** Sources and Source types keep `ListScrollAnchorModifier` and a top-row anchor, now resolved through `ListAnchor.resolved` (AC-4.6; `sourceTypesListIsAListRoot`). `PVTable` still calls `PVListKeyboard.action` (`PVListTests`, `PVTableTests` unchanged).
- **Removed inputs.** A deselect writes nil (AC-4.4); a deleted row restores nil (AC-4.5); a coalesced visit clears (AC-4.7).
- **Real data.** None — no table-driven rule.
- **Untrusted size.** None — rows come from the app's own catalog read.

### Schema

None — no catalog change.

### Go core

None — Go already sorts and serves the rows.

### FFI

None — no wire change.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Browse list | `PVList` (rebuilt) | `macos/App/DesignSystem/Components/List/PVList.swift` | D-1, D-2, D-5, D-6, D-13 |
| List page header | `PVListPageHeader` *(new)* | `macos/App/DesignSystem/Components/ListPageHeader/PVListPageHeader.swift` | D-3; these pages pass no description and no Add |
| Thumbnail | `CachedThumbnail` over `PVThumbnail` | as today | 44 pt |
| Title with +N | `PVTitleText` | as today | D-4 ink |
| Updated column | `PVListDetailCell`, `PVLastUpdated.columnWidth` | as today | D-4 ink |
| Selection | platform | — | plain style: full-width bar |
| Loading rows | `PVListSkeleton` | `PVList.swift` | D-9 |
| Empty | `PVEmptyState(glyph: .mark(Kind.mark))` | as today | centered in the area |
| Failure | `PVCallout(.danger)` + `.pvListPageMessage` | as today | D-11 |

Frames in words (the board): **L1a/L1b** Persons, scrolled mid-list, header on `surfacePage` above a full-width hairline, rows on `surfaceCard`, nothing selected; at Wide the title column takes the width. **L2** selected rows: blue bar with white text, grey bar with normal text, iron bar (Multicolor), at rest; dark appearance the same. **L3** Events (a 90-character title truncating) and Places (italic chains, `England` with none). **L4** count line `… · refreshing`. **L5** skeleton filling the area. **L6** empty state centered. **L7** danger Callout at the top-leading corner of the area.

States: empty (AC-1.6), loading (AC-1.5), failure (AC-1.7), refreshing (AC-1.8), 16,000 rows (AC-3.2). Accessibility: D-13; keyboard: AC-3.x.

### Strings

None — no new key. The Sources header's copy (`L10n.Workspace.sourcesTitle`, `L10n.Sources.description`, `L10n.Sources.addSource`) moves onto `PVListPageHeader` unchanged.

## 7. Steps

**STEP-1 — The kit's list page header and message placement**
Files: `macos/App/DesignSystem/Components/ListPageHeader/PVListPageHeader.swift` *(new)*, `macos/App/Features/CatalogVocabulary/VocabularyChrome.swift`, `macos/App/Features/Metadata/MetadataView.swift`, `macos/App/Features/Properties/PropertiesView.swift`, `macos/App/Features/SourceTypes/SourceTypesView.swift`, `macos/App/Features/Sources/SourcesListView.swift`. Skill: `add-ui-component`.
Do: move `VocabularyHeader` to `PVListPageHeader` per D-3; the description and the Add button draw only when given. The three vocabulary pages pass what they pass today. `SourcesListView.header(visibleCount:)` returns `PVListPageHeader(title: L10n.Workspace.sourcesTitle, description: L10n.Sources.description, countLine: model.isCatalogEmpty ? nil : model.countLine(visibleCount: visibleCount), add: .init(label: L10n.Sources.addSource) { model.openAdd() }, identifierPrefix: "sources")`. Add `.pvListPageMessage` (D-11) and move the four failure placements onto it, keeping each one's `announces:` and identifier. Delete `VocabularyHeader`.
Check: `rg -n "VocabularyHeader" macos` prints nothing; `rg -nF 'identifierPrefix).countLine' macos/App/DesignSystem/Components/ListPageHeader` and `rg -nF 'identifierPrefix).add' macos/App/DesignSystem/Components/ListPageHeader` each print one line; `xcodebuild test` passes.

**STEP-2 — One on-selection ink**
Files: `macos/App/DesignSystem/Tokens/PVColor.swift`, `macos/App/DesignSystem/Components/List/PVList.swift` (`PVListDetailCell`), `macos/App/DesignSystem/Components/TitleText/PVTitleText.swift`, `macos/App/DesignSystem/Components/DatePlaceLine/PVDatePlaceLine.swift`, `macos/ProvenenciaTests/PVListTests.swift`.
Do: add `PVColor.onSelection` (D-4) and T-1; pass the named inks through it. Add a `#Preview("Selected row ink")` in `PVList.swift` that draws one Persons-like row (a `PVThumbnail` mark, `PVTitleText` of a name with `extraCount: 2`, a `PVDatePlaceLine` with a date, a place and `extraCount: 1`, a `PVListDetailCell` with `Yesterday`, the ref `PER-7K2QX`) with `.environment(\.backgroundProminence, .increased)` on an accent background.
Check: T-1 passes; the new preview shows white title, secondary, updated column and ref, and colored badges.

**STEP-3 — `PVList` on the native list**
Files: `PVList.swift`, `macos/App/Features/Sources/SourcesListRow.swift`. Skill: `add-ui-component`.
Do: rebuild `PVList` per D-1, D-2, D-5, D-6, D-13, and the selection scroll of D-7; rows keep today's `HStack` content (spacing `space6`, the title and secondary `VStack` with spacing 3, the detail cell, the ref) without the chevron and the `Button`; `PVList`'s secondary and ref inks go through `PVColor.onSelection`. Move `PVListRowStyle` per D-14. Update the previews (one initializer; a `@State` selection).
Check: in the app, a Persons row double-clicked and a selected row with Return each open the page (else D-2's fallback, in this step), and a separator draws (else D-12's branch, in this step); `PVListTests` pass; `rg -n "PVListRowStyle" macos/App --glob '*.swift'` and `rg -n "chevron:" macos/App/DesignSystem/Components/List macos/App/Features/Conclusions` print nothing; `xcodebuild test` passes.

**STEP-4 — The skeleton without its card**
Files: `PVList.swift`.
Do: per D-9; delete `pvListChrome()`.
Check: `rg -n "pvListChrome" macos` prints nothing; builds.

**STEP-5 — Navigation owns the list's selected row**
Files: `macos/App/Features/Workspace/WorkspaceNavigation.swift`, `macos/App/Features/Workspace/NavigationHistoryStore.swift`, `macos/App/Features/Workspace/WorkspaceLocation.swift` (docs only), `macos/ProvenenciaTests/WorkspaceNavigationTests.swift`. Skill: `add-workspace-location`.
Do: the renames, docs and observation of D-8; `ListAnchor.resolved` with `ListScrollAnchorModifier` calling it; `ListSelectionAnchorModifier` (D-7); T-3, T-4.
Check: `rg -n "noteListScroll|pendingListScrollAnchor|stampListScrollAnchor|normalizedScrollAnchor" macos` prints nothing; `WorkspaceNavigationTests` pass.

**STEP-6 — The page draws S16-D13**
Files: `macos/App/Features/Conclusions/ConclusionListPage.swift`, `macos/App/DesignSystem/Components/WidthClass/PVWidthClass.swift`.
Do: `PVWidthClass.fullPaneGutter`, `ConclusionListFrame` and the state builders (D-10, D-11); `ConclusionListBody` passes `PVList` the navigation binding of D-7 with `horizontalInset: gutter` and `onActivate` as today, and wears `ListSelectionAnchorModifier(rowIDs:, isSettled: handle.isSettled)` in place of `ListScrollAnchorModifier`. Add `#Preview("Empty")` and `#Preview("Failed")` that draw `ConclusionListFrame` over `emptyArea()` and `failureArea(_:gutter:)`, each at 1102 and 2296 pt wide with the matching `pvWidthClass`. The kinds' doc comments ("so `PVList` lays out no second line") stay true; leave them.
Check: `PersonsListTests` and `PlacesListTests` still pass (unchanged); the app and the previews show the L1–L7 frames.

**STEP-7 — Version**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj` (`MARKETING_VERSION`, four lines).
Do: 0.34.1 → 0.35.0, together.
Check: `rg -n "0\.34\.1" VERSION core/version.go macos/Provenencia.xcodeproj/project.pbxproj` prints nothing.

**STEP-8 — Prove the expected behaviors**
Do: run §10 steps 6–9 and write five lines in the PR description and this plan's Landed note, each `<behavior>: works | missing | differs — <what happened>`: type-select; ⌥↑/⌥↓; VoiceOver reading a row and Return opening it; the iron selection in dark appearance; which D-12 separator branch shipped. A behavior the platform lacks is recorded, not built (Out).
Check: five lines written.

**STEP-9 — Docs**
Files: `macos/App/DesignSystem/README.md` (the List row rewritten: the native browse list with a selection, the platform's keys plus Home/End by row, double-click and Return through the primary action, `PVListSkeleton`; no `PVListRowStyle` and no chevron; a ListPageHeader row naming `.pvListPageMessage`; the ScrollRowIntoView row: it serves the native list too, scrolling by row; "The table tradeoff": `PVList` is the native counterpart), the `PVScrollRowIntoView` doc comment ("the enclosing `ScrollView`" → "the enclosing `ScrollView` or `List`"), `docs/macos-client-patterns.md` § 9 (after rule 3, one sentence: "The Persons, Events and Places lists fill the pane at every width (S16-67, user 2026-11-23): the selection and the clickable row run edge to edge."; its "List → detail page" row names them as the exception), `docs/ideas/wide-layout.md` (the Conclusion lists' row answered: they fill the pane, S16-67), `docs/ideas/kit-layering.md` (line 35: delete the clause ", so it does not wear `.pvListFocusStop`" and keep the sentence; add an entry: whether `PVTable` follows the native list, given two selection looks and two Page-key meanings, with STEP-8's type-select and ⌥ findings), `.agents/skills/add-workspace-location/SKILL.md` (line 34: a list's anchor row in `listScrollAnchor`, its top row on Sources and Source types through `ListScrollAnchorModifier`, its selected row on the Conclusion lists through `ListSelectionAnchorModifier`), `docs/deployment-plan/spike-16/completed.md`, `docs/deployment-plan/spike-16/deployment-plan.md` (map row: status, and its scope text matched to D-3 and D-7), this plan (status), `docs/deployment-plan/spike-16/design/S16-D13-conclusion-lists-native.md` → `docs/deployment-plan/spike-16/design/archive/`, `docs/deployment-plan/spike-16/design/README.md`.
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py` reports no errors; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period ("Select a row on the Persons, Events and Places lists with a click and open it with a double-click or Return."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `PVListTests.swift` `onSelectionInkIsTheSystemsOnlyWhenProminent` *(new)* | `PVColor.onSelection(PVColor.textMuted).resolve(in:)` with `backgroundProminence = .increased` → the resolved `Color(nsColor: .alternateSelectedControlTextColor)`; with `.standard` → the resolved `PVColor.textMuted`; both in light and dark `colorScheme` | AC-2.1, AC-2.2, D-4 |
| T-2 | Swift | `PVListTests.swift` `optionArrowsAndHomeEndJumpToTheEnds` (extended) | `moveIndex(for: .end, option: false, index: 0, count: 0)` → -1 (not in `indices`, so D-5 ignores the key); `.home`/`.end` at 16,000 → 0 / 15,999 | AC-3.2, D-5 |
| T-3 | Swift | `WorkspaceNavigationTests.swift` `listAnchorResolvesOnlyAListedRow` *(new)* | `ListAnchor.resolved("p2", in: ["p1","p2","p3"])` → `"p2"`; `"p9"` → nil; nil → nil; `"p1"` in `[]` → nil | AC-4.1 – AC-4.5, D-7 |
| T-4 | Swift | `WorkspaceNavigationTests.swift` `theListAnchorIsTheSelectionAndFollowsHistory` *(new; fails at the base, where `listAnchor` does not exist)* | Persons from the sidebar → `listAnchor == nil`; `noteListAnchor("person-1")` → `listAnchor == "person-1"`; `go(to: .sectionRoot(.persons))` (coalesced) → `listAnchor == nil` with no Back; `noteListAnchor("person-2")`, go to Events → `listAnchor == nil`; Back → `listAnchor == "person-2"` | AC-4.2, AC-4.4, AC-4.7, D-7, D-8 |
| T-5 | Swift | `WorkspaceNavigationTests.swift` `leavingAListStampsTheOutgoingEntry`, `sourceTypesListIsAListRoot` (renamed calls) | unchanged → unchanged | AC-4.2, AC-4.3, AC-4.6 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `PersonsListTests`, `PlacesListTests`, `WorkspaceNavigationTests`, `PVListTests`, `PVTableTests` (it calls `PVListKeyboard.action`).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none added)
- [ ] Sweep: `VocabularyHeader`, `PVListRowStyle`, `pvListChrome`, `noteListScroll`, `pendingListScrollAnchor`, `stampListScrollAnchor`, `normalizedScrollAnchor`, `ConclusionListPage.page`, `.pvListFocusStop` `rg`'d across `.agents/`, `.cursor/rules/`, `docs/*.md`, `docs/ideas/`, `macos/App/DesignSystem/README.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (§ 9 exception recorded)
- [ ] UI matches the brief inventory; no new kit primitive beyond the moved header
- [ ] Version 0.35.0 in VERSION, core/version.go, MARKETING_VERSION together
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan and STEP-8's five findings
- [ ] docs/deployment-plan/spike-16/deployment-plan.md: map row status; docs/deployment-plan/spike-16/completed.md: one short paragraph of what shipped
- [ ] Brief S16-D13 moved to design/archive/ and design/README.md updated
- [ ] Domain doc updated: docs/macos-client-patterns.md § 9; .agents/skills/add-workspace-location/SKILL.md
- [ ] PR description: what shipped, AC evidence, deviations, manual check, STEP-8 findings
```

## 10. Manual check

Use a project with Persons, Events and Places, and the user's 16,000-person project for steps 3 and 4.

1. Open Persons from the sidebar at the default window (Regular): the header across the pane, the list to the pane's edges and bottom, no chevrons, nothing selected, list at its top. Press ↓: the first row is selected (AC-1.1, AC-1.3, AC-3.1, AC-4.1).
2. Click a row: selected, white text on the accent, nothing opens. Click the window's title bar area of another app: the bar turns grey. Hover: nothing. Right-click: no menu. Double-click: the page opens; Back: the row selected and in view. Select another, press Return: it opens. Press ↓ and ↑: the selection moves one row and stays in view (AC-2.1, AC-2.2, AC-2.3, AC-2.4, AC-2.5, AC-2.6, AC-3.4, AC-4.2).
3. At 16,000 persons, fresh launch, before clicking: End, Home, End again — the last and first rows show each time; the selection does not change. Page Down/Up scroll a screen (AC-3.2, AC-3.3).
4. Scroll to row ~800, select it, open Events from the sidebar, Back: row ~800 selected and in view. Deselect, Events, Back: top, nothing selected. Select a row, click Persons in the sidebar again: the selection clears; Events, Back: nothing selected (AC-4.3, AC-4.4, AC-4.7).
5. Widen the window past 1600 pt of pane with a row selected: 56 pt insets, title column wider, selection, scroll and focus kept. Events with a 90-character title at Regular truncates (AC-1.2, AC-1.4, AC-1.9). Sources and Source types: Back restores their top row; their headers look as before (Sources 4 pt tighter under the header) (AC-4.6).
6. Type the first letters of a name with the list focused: record whether the selection jumps (type-select).
7. Press ⌥↓ / ⌥↑: record what happens.
8. VoiceOver on: move through rows; record what it reads; press Return on a row: record whether it opens.
9. System Settings → Appearance → Multicolor, dark appearance: select a row; record how the iron bar and its white text read. Note which D-12 separator branch draws.
10. Empty project: the empty state centered (AC-1.6). Loading: watch first load on the 16,000-person project (AC-1.5). Edit a Person's name, Back to Persons while it reloads: the count line reads `· refreshing`, rows do not animate (AC-1.8). Failure: the page's `#Preview("Failed")` (STEP-5) at Regular and Wide shows the danger Callout at the top-leading corner on the gutter, at most 560 pt wide; `PersonsListTests.presentationFollowsTheHandleState` holds the state (AC-1.7).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| `List` rows on macOS 14 measure every row's height at 16,000 rows | Fixed 66 pt content; step 3 of §10 at 16,000; stop below |
| `backgroundProminence` is not `.increased` on a selected macOS `List` row | Stop below; the ink then needs another signal |
| The S16-65 race returns on Home/End | Stop below |

**Stop and report if:**

- `PVList` has a caller besides `ConclusionListPage` at the base (`rg -n "PVList\(" macos/App --glob '!**/PVList.swift'`).
- At 16,000 persons the Persons page takes visibly longer to show rows than at the base, or End does not show the last row on the first press after a fresh load.
- The primary action does not fire on Return, or a double-click also fires it on a row other than the clicked one.
- A focused selected row's `backgroundProminence` is not `.increased` (the white ink does not appear).
- `pvScrollsRowIntoView` or the focus claim cannot be made to work on the `List` without an `NSViewRepresentable`.
- The row background behind a transparent list hides or tints the system selection.
- Rows or the selection still animate on a reload with the `ForEach`'s animation set to nil (AC-1.8).
- The restore never runs on Back because `handle.isSettled` stays false while the list shows rows (a refetch that does not end).
- The brief's frame and an AC disagree.

## 12. Open questions

None.

## 13. PR

**Title:** S16-67 — The Persons, Events and Places lists are native lists
**Body:** objective in one sentence; what shipped against US-1 – US-4; AC evidence; STEP-8's findings; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-67-native-conclusion-lists.md`.
