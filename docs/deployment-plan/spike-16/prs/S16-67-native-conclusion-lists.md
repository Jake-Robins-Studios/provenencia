# S16-67 — The Persons, Events and Places lists are native lists

**Status:** Draft
**Spike / slice:** Spike 16 · Slice 6f — List keyboard
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S16-D13](../design/S16-D13-conclusion-lists-native.md), board agreed 2026-11-23
**Board:** [Persons List](https://claude.ai/artifact/MQtjRymfDNraEx9roK69q4), page "Persons List" (frames L1a–L7b). The implementer opens the link; §6 macOS also describes each frame in words, and the brief's **Board** line records every choice the board made
**Depends on:** S16-D13 (agreed 2026-11-23)
**Blocks:** S16-66
**Branch:** `s16-67-native-conclusion-lists`
**Version bump:** minor, 0.34.1 → 0.35.0 — three pages change how a researcher works them (a click selects, a double-click or Return opens), no wire or catalog change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-workspace-location`](../../../../.agents/skills/add-workspace-location/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md) (no new key; the Sources header's copy moves)
**Rules that bind:** —
**Context:** map scope entry [S16-67](../deployment-plan.md#s16-67--the-persons-events-and-places-lists-are-native-lists); bar 37; working rule "(Batch 6) The Conclusion lists are native lists"; [`docs/macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide); kit README "The table tradeoff" (`macos/App/DesignSystem/README.md`); the S16-65 ship log on branch `origin/s16-65-list-focus-stop` (S16-65-list-focus-stop.ship.md there: why Home/End on a `LazyVStack` raced its estimated height)
**Planned:** 2026-11-23 against `main` @ `f9114de40`
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
| AC-2.1 | Click `Josephine Marchand` | The row is selected with the system's full-width bar in the system accent; its title, secondary line, updated column and ref draw in `PVColor.textInverse`; the thumbnail and the +2 badge keep their colors; no page opens (CL-4) |
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

## 3. Scope

| In | Covered by |
| --- | --- |
| CL-1 header (`PVListPageHeader`, from `VocabularyHeader`) | STEP-1, STEP-5, AC-1.1, AC-1.8 |
| CL-2 the list fills the pane | STEP-3, STEP-5, AC-1.1 |
| CL-3 rows on the native list, no chevron | STEP-3, AC-1.3 |
| CL-4 system selection, on-selection ink | STEP-2, STEP-3, AC-2.1, AC-2.2 |
| CL-5 double-click and Return open | STEP-3, AC-2.3, AC-2.4 |
| CL-6 focus on arrival; Back restores the selected row | STEP-3, STEP-5, STEP-6, AC-3.1, AC-4.1 – AC-4.5 |
| CL-7 loading skeleton without its card | STEP-4, AC-1.5 |
| CL-8 empty state centered in the list area | STEP-5, AC-1.6 |
| CL-9 failure Callout at the top of the list area | STEP-5, AC-1.7 |
| CL-10 long titles truncate | STEP-3, AC-1.4 |
| CL-W1 (a) the title column takes the Wide width, 56 pt gutters | STEP-5, AC-1.2 |
| CL-W2 the states at Wide | STEP-4, STEP-5, AC-1.5 – AC-1.7 |
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
| Title | `macos/App/DesignSystem/Components/TitleText/PVTitleText.swift` `PVTitleText` | Draws its own ink (`textDisplay`, `textSecondary` at lines 127–158), so an outer `foregroundStyle` does not reach it |
| Date and place | `macos/App/DesignSystem/Components/DatePlaceLine/PVDatePlaceLine.swift` `PVDatePlaceLine` | Draws its own ink (`textMuted`, `textFaint`, `textSecondary`, `dateTone`) |
| List page header | `macos/App/Features/CatalogVocabulary/VocabularyChrome.swift` `VocabularyHeader` | Title (display h1), description (required), count line, Add button (required); `gutterPage` horizontal, `space8` top, `space6` bottom. Callers: `MetadataView.swift:114`, `PropertiesView.swift:144`, `SourceTypesView.swift:69` |
| Sources header | `macos/App/Features/Sources/SourcesListView.swift:131` `header(visibleCount:)` | A copy of `VocabularyHeader`'s layout with `space7` bottom, the count line hidden when the catalog is empty, `sources.countLine` / `sources.add` |
| Back to a list | `macos/App/Features/Workspace/WorkspaceNavigation.swift` `noteListScroll(_:)`, `performGo` / `performBack` / `performForward` / `performIndex`, `ListScrollAnchorModifier` | A list reports a row id (`noteListScroll`) into `pendingListScrollAnchor`; leaving the entry stamps it (`NavigationHistoryStore.stampListScrollAnchor`) onto `WorkspaceLocation.listScrollAnchor`; `apply` resets the pending id to the entry's anchor. `ListScrollAnchorModifier` scrolls a `ScrollView` to the anchor and reports the top row as the researcher scrolls. Callers: `ConclusionListPage`, `SourceTypesListPane.swift:50`, `SourcesListView.swift:307` |
| Section anchor (not used here) | `WorkspaceNavigation.go(to:from:)`, `ConclusionAnchorRestore.swift` | A record page's row anchor; not a list's |
| Width class | `@Environment(\.pvWidthClass)` (`SourceTypesView.swift:44`); `PVSpacing.gutterPage` 32, `gutterPageWide` 56 (no caller yet), `measureForm` 560 | |
| Tests | `macos/ProvenenciaTests/PVListTests.swift`; `PersonsListTests.swift` (presentation, meta, locations, labels); `PlacesListTests.swift`; `WorkspaceNavigationTests.swift` (`notingListScrollDoesNotPushHistory`, `leavingAListStampsTheOutgoingEntry`, `sourceTypesListIsAListRoot`, lines 590–665) | |

**Precedent.** `PVReorderableList` (S2-25) is the kit's native-list setup: copy its `List` modifiers (plain style, hidden content background, row insets). Do not copy its height measuring or `scrollDisabled`: this list is its own scroll view and fills the pane. For the header move, `VocabularyHeader` itself is the code; it moves and generalizes.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `PVList` is rebuilt on `List(selection:)` with `ForEach(items)` and its slots kept. It gains `selection: Binding<Item.ID?>` and `horizontalInset: CGFloat` (default `density.horizontal`); it loses `chevron`. Setup: `.listStyle(.plain)`, `.scrollContentBackground(.hidden)`, `.listRowInsets(EdgeInsets(top: density.vertical, leading: horizontalInset, bottom: density.vertical, trailing: horizontalInset))`, `.listRowSeparator(.visible)`, `.listRowSeparatorTint(PVColor.borderSubtle)`, `.focusEffectDisabled()`, no `listRowBackground`, `.transaction { $0.animation = nil }` on the rows' `ForEach` | The platform owns selection, ↑/↓, Page keys and scrolling (working rule). No row background keeps the system selection visible (the brief's open question) by having nothing over it; the area's `surfaceCard` comes from the page behind the transparent list. Rows never animate (brief § 2.1) | Keeping `chevron` — no caller wants it (board); a `listRowBackground(surfaceCard)` — risks covering the selection for nothing |
| D-2 | Double-click and Return open through `.contextMenu(forSelectionType: Item.ID.self, menu: { _ in EmptyView() }, primaryAction: …)`; the primary action opens the one id it gets (`onActivate`) | The platform's primary action is exactly double-click and Return on a `List`. An empty menu shows no menu (AC-2.6) | `onTapGesture(count: 2)` — fights the list's click selection, and Return needs its own key handler |
| D-3 | `VocabularyHeader` moves into the kit as `PVListPageHeader` *(new)* at `macos/App/DesignSystem/Components/ListPageHeader/PVListPageHeader.swift`: `title`, `description: LocalizedStringResource?`, `countLine: String?`, `add: PVListPageHeader.Add?` (label, `isDisabled`, `size`, action), `identifierPrefix`, `descriptionItalic`, `gutter: CGFloat = PVSpacing.gutterPage`. Metrics are `VocabularyHeader`'s (`space8` top, `space6` bottom). Metadata, Properties, Source types and Sources call it. The Sources header therefore loses 4 pt under it (`space7` → `space6`) | CL-1 says "as Source types, Metadata and Properties draw it", so their metrics win; three pages unchanged and one 4 pt change beats the reverse. One header type for every list page | Keeping `space7` for Sources with a padding parameter — a knob for one caller; a Conclusion-only header — a third copy |
| D-4 | The on-selection ink is one kit rule: `PVListInk.color(_ base: Color, prominence: BackgroundProminence) -> Color` *(new, in `PVList.swift`)* returns `PVColor.textInverse` when `prominence == .increased`, else `base`. `PVList`'s own texts, `PVListDetailCell`, `PVTitleText` and `PVDatePlaceLine` read `@Environment(\.backgroundProminence)` and pass each ink through it. `PVBadge` and `PVThumbnail` do not | The platform sets `.increased` on a focused selected row; components that draw their own ink cannot be recolored from outside, so each reads the environment through one function (brief: no new token, `textInverse`) | A `PVList`-only override — `PVTitleText` and `PVDatePlaceLine` set explicit colors the override cannot reach |
| D-5 | Home and End: `PVList` handles them with `.onKeyPress(keys: [.home, .end])` on the `List`, maps the key with `PVListKeyboard.edgeIndex(for:count:)` *(new; `0` for Home, `count - 1` for End, through `moveIndex`; nil otherwise or when empty)*, and scrolls to that row's id through `.pvScrollsRowIntoView(edgeRow, anchor: key == .home ? .top : .bottom, animated: false, whenRequested: edgeRequest)`. The selection does not change | Brief § 2 (Finder's Home/End); a native list scrolls to a row by index, not to an estimated height, so the S16-65 race does not occur. `whenRequested` lets the same key scroll again | Setting the selection — not Finder's behavior; AppKit `scrollToBeginningOfDocument` — the S16-65 path |
| D-6 | Focus on arrival: `PVList` holds `@FocusState isFocused`, `.focused($isFocused)` on the `List`, and in `.onAppear` sets it on the next main-actor turn (`Task { @MainActor in isFocused = true }`) | `PVList` mounts once rows exist, which is the page's arrival; a same-turn assignment is dropped before the list is in the window | `.defaultFocus` — scoped to a focus section the workspace does not declare |
| D-7 | Back on these lists: the list's anchor is its **selected row**. `ConclusionListBody` holds `@State selection: String?`, reports every change with `navigation.noteListAnchor(selection)` (renamed from `noteListScroll`), and on its first `.rows` presentation sets `selection = ConclusionListSelection.restored(anchor: navigation.currentLocation.listScrollAnchor, rows:)` *(new pure function)*, nil when the anchor is nil or no row has it. `PVList` scrolls the selection into view on appear (`.pvScrollsRowIntoView(selection, scrollsOnAppear: true, animated: false)`). `ListScrollAnchorModifier` leaves this page | A row opens only by double-click or Return on the selected row, so the opened row is always the selected row and the existing stamp on leaving writes it; leaving another way writes the selected row; no selection writes nil. No new field and no `go(to:)` overload | The map's `go(to:)` overload stamping as it opens — it would write the same id the pending anchor already holds; a second field — the map says none |
| D-8 | `noteListScroll(_:)` is renamed `noteListAnchor(_:)`; its doc says a list reports its anchor row: the top row (Sources, Source types) or the selected row (Persons, Events, Places) | The name would be wrong for the new caller | Keeping the name |
| D-9 | `PVListSkeleton` loses its card and takes `horizontalInset`; its rows separate with a `PVDivider` inset by `horizontalInset` on both sides. `ConclusionListPage` passes 30 rows in a top-aligned, clipped frame | 30 × 66 pt covers a 1,980 pt list area; the board draws inset separators | Measuring the area with a `GeometryReader` — one more layout pass for a placeholder |
| D-10 | The page: a `VStack(spacing: 0)` of `PVListPageHeader` (gutter by width class: `gutterPageWide` at Wide, else `gutterPage`; background `PVColor.surfacePage`), `PVDivider`, and the state area filling the rest on `surfaceCard`. The list passes the same gutter as `horizontalInset`. No outer `ScrollView` | CL-1, CL-2, CL-W1 (a) | `pvListBand` — the brief bends § 9 rule 3 for these lists |
| D-11 | The failure Callout: `.frame(maxWidth: PVSpacing.measureForm, alignment: .leading)` at the top of the area, padded `space8` top and the gutter leading | The board's 640 pt is not a token; the brief's non-goals forbid a new one; `measureForm` is the nearest readable width | A 640 literal |
| D-12 | Separators: if `.listRowSeparator(.visible)` draws no hairline in the plain style on macOS 14, the row draws a `PVDivider` at its bottom inside the row insets instead, as the skeleton does (D-9) | Decided now so the implementer does not choose; the board's look is the same | Leaving rows unseparated |
| D-13 | Accessibility: each row stays one element with today's label (`itemAccessibilityLabel`) and identifier (`<root>.row.<ref>`), without `.isButton`; the list keeps `label` as its accessibility label and the page keeps `<root>.list` | A selectable row is not a button; Return opens it (the platform's) | A custom "Open" action — a new string for what Return already does |
| D-14 | `PVListRowStyle` and `PVListRowBody` move to `SourcesListRow.swift` as `private` `SourcesListRowButtonStyle` / its body, without the `focused` parameter (its one caller passed nil) | The scope entry: beside its one remaining caller | Leaving a kit type with one feature caller |

**Rules this plan bends.** [`docs/macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide) rule 3 (a list with nothing more to show keeps a 1600 pt maximum at Wide): these three lists fill the pane at every width → the selection and the clickable row run edge to edge → the user, 2026-11-23 (working rule "(Batch 6) The Conclusion lists are native lists"; CL-W1 (a) picked on the board) → STEP-9 records the exception in § 9 and its "List → detail page" row; rule 3's text is not changed.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `PVListPageHeader` *(new)* | component | `VocabularyHeader` (`VocabularyChrome.swift`), `SourcesListView.header(visibleCount:)` | It **is** `VocabularyHeader`, moved into the kit with description and Add optional; the Sources copy is deleted onto it. Searched `rg "font\(PVFont.display\(size: PVTypeScale.h1"` |
| `PVListInk` *(new)* | func | `PVColor.textInverse`; no existing prominence read (`rg backgroundProminence` finds none) | One rule for four components instead of four copies |
| `PVListKeyboard.edgeIndex(for:count:)` *(new)* | func | `PVListKeyboard.moveIndex` | Wraps `moveIndex` for the two keys the native list lacks; no new key list |
| `ConclusionListSelection.restored(anchor:rows:)` *(new)* | func | `ListScrollAnchorModifier.applyIfReady` | That resolves a scroll target inside a `ScrollView` modifier with pinning for estimated heights; a selection needs only "is this id in the rows" |
| `SourcesListRowButtonStyle` *(moved)* | type | `PVListRowStyle` | Moved, not new |

**Builds on.** `PVReorderableList`'s native setup; `pvScrollsRowIntoView` (`whenRequested`, `scrollsOnAppear`); the history's pending list anchor (`pendingListScrollAnchor`, `stampListScrollAnchor`); `@Environment(\.pvWidthClass)`; `ConclusionListPresentation` unchanged.
**Deletes.** `VocabularyHeader` (and its file's header section; `VocabularyPanelHeader` stays); `SourcesListView.header(visibleCount:)`'s layout (it becomes a `PVListPageHeader` call); `pvListChrome()`; `PVList`'s `chevron` parameter, `focusIndex`, `currentIndex`, `.onKeyPress` body and its `Button` row; `PVListRowStyle` / `PVListRowBody` in the kit (moved); `ConclusionListPage.page(meta:body:)`'s `ScrollView` and content column; `ConclusionListBody.scrollRowIDs`, `scrollIsLoaded` and its `ListScrollAnchorModifier`; `noteListScroll` (renamed). `PVListKeyboard.action` stays (`PVTable`). The kit README's List row sentence about buttons and the focus stop.
**Next adds.** S16-66: the Sources list moves onto `PVList` with `selection` and `PVListPageHeader` already in place, or keeps its rows with `SourcesListRowButtonStyle`. A later `PVTable` move follows `PVList`'s setup (the kit-layering entry).

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A list entry whose anchor is a selected row, not a top row | `ConclusionListBody` restore | Missing row → nil selection, list at top (AC-4.5, T-3); history files written before this PR hold a top-row id, which restores as a selection of that row — acceptable, it is a row the researcher saw |
| A selected row with the record deleted by a reload | `List(selection:)` | The id leaves `items`; the selection is cleared by `ConclusionListBody` when its rows change and the id is gone (STEP-5), and the anchor reported is nil |
| Return / double-click while a reload replaces rows | `onActivate` | The primary action receives the id; `PVList` finds its item in `items`; a missing id does nothing |

### Scale

At the Batch 2 Scale (16,000 persons): rows are built lazily by `NSTableView` at a fixed 66 pt height; `ForEach(items)` takes the array without `enumerated()`. Per body pass `PVList` does O(1) work besides the `ForEach`. The primary action and the restore each do one O(n) id search, once per open or per load (16,000 comparisons). `ConclusionListBody` no longer maps every row to an id array per pass (`scrollRowIDs` is deleted). The budget: opening Persons at 16,000 shows rows no slower than today, and End shows the last row on the first press (AC-3.2), measured on the user's 16,000-person project.

### Edges

- **Assumptions.** The opened row is the selected row (D-7): holds because `primaryAction` fires only on the selection (T-3 holds the restore, the manual check AC-4.2 the open). Row ids are unique per list (`CatalogListRow.id`, entity ids).
- **Neighbors.** Sources and Source types keep `ListScrollAnchorModifier` and a top-row anchor (AC-4.6; the existing `sourceTypesListIsAListRoot`). `PVTable` still calls `PVListKeyboard.action` (`PVListTests` unchanged).
- **Removed inputs.** A deselect writes nil (AC-4.4); a deleted row restores nil (AC-4.5).
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
| Failure | `PVCallout(.danger)` | as today | D-11 |

Frames in words (the board): **L1a/L1b** Persons, scrolled mid-list, header on `surfacePage` above a full-width hairline, rows on `surfaceCard`, nothing selected; at Wide the title column takes the width. **L2** selected rows: blue bar with white text, grey bar with normal text, iron bar (Multicolor), at rest; dark appearance the same. **L3** Events (a 90-character title truncating) and Places (italic chains, `England` with none). **L4** count line `… · refreshing`. **L5** skeleton filling the area. **L6** empty state centered. **L7** danger Callout at the top-leading corner of the area.

States: empty (AC-1.6), loading (AC-1.5), failure (AC-1.7), refreshing (AC-1.8), 16,000 rows (AC-3.2). Accessibility: D-13; keyboard: AC-3.x.

### Strings

None — no new key. The Sources header's copy (`L10n.Workspace.sourcesTitle`, `L10n.Sources.description`, `L10n.Sources.addSource`) moves onto `PVListPageHeader` unchanged.

## 7. Steps

**STEP-1 — The kit's list page header**
Files: `macos/App/DesignSystem/Components/ListPageHeader/PVListPageHeader.swift` *(new)*, `macos/App/Features/CatalogVocabulary/VocabularyChrome.swift`, `macos/App/Features/Metadata/MetadataView.swift`, `macos/App/Features/Properties/PropertiesView.swift`, `macos/App/Features/SourceTypes/SourceTypesView.swift`, `macos/App/Features/Sources/SourcesListView.swift`. Skill: `add-ui-component`.
Do: move `VocabularyHeader` to `PVListPageHeader` per D-3 (`Add` is a nested struct: `label`, `isDisabled = false`, `size = .md`, `action`); the description line and the Add button draw only when given. The three vocabulary pages pass what they pass today. `SourcesListView.header(visibleCount:)` returns `PVListPageHeader(title: L10n.Workspace.sourcesTitle, description: L10n.Sources.description, countLine: model.isCatalogEmpty ? nil : model.countLine(visibleCount:), add: .init(label: L10n.Sources.addSource) { model.openAdd() }, identifierPrefix: "sources")`. Delete `VocabularyHeader`.
Check: `rg -n "VocabularyHeader" macos` prints nothing; the identifiers `metadata.add`, `sourceTypes.countLine`, `sources.countLine`, `sources.add` are still minted (`rg -n '"\\(identifierPrefix)' macos/App/DesignSystem/Components/ListPageHeader`); `xcodebuild test` passes.

**STEP-2 — One on-selection ink**
Files: `PVList.swift`, `PVTitleText.swift`, `PVDatePlaceLine.swift`, `macos/ProvenenciaTests/PVListTests.swift`.
Do: add `PVListInk.color(_:prominence:)` (D-4) and T-1. `PVTitleText`, `PVDatePlaceLine` and `PVListDetailCell` read `@Environment(\.backgroundProminence)` and pass every ink they draw through it.
Check: T-1 passes; the previews look as before.

**STEP-3 — `PVList` on the native list**
Files: `PVList.swift`, `macos/App/Features/Sources/SourcesListRow.swift`, `PVListTests.swift`. Skill: `add-ui-component`.
Do: rebuild `PVList` per D-1, D-2, D-5, D-6, D-13; rows keep today's `HStack` content (spacing `space6`, the title and secondary `VStack` with spacing 3, the detail cell, the ref) without the chevron and without the `Button`; the title and secondary inks go through `PVListInk`. Add `PVListKeyboard.edgeIndex` and T-2. Move `PVListRowStyle` per D-14. Update both previews (a `@State` selection).
Check: T-2 and `PVListTests` pass; `rg -n "PVListRowStyle|chevron:" macos/App` prints nothing; `xcodebuild test` passes.

**STEP-4 — The skeleton without its card**
Files: `PVList.swift`.
Do: per D-9; delete `pvListChrome()`.
Check: `rg -n "pvListChrome" macos` prints nothing; builds.

**STEP-5 — The page draws S16-D13**
Files: `macos/App/Features/Conclusions/ConclusionListPage.swift`, `PersonsListView.swift`, `EventsListView.swift`, `PlacesListView.swift`, `ConclusionListRow.swift`, `macos/ProvenenciaTests/PersonsListTests.swift`. Skill: `add-workspace-location`.
Do: per D-7, D-10, D-11. `page(meta:body:)` becomes the header-hairline-area stack and takes the gutter; the body passes `selection: $selection`, `horizontalInset: gutter`, and `onActivate` as today. Add `ConclusionListSelection.restored` and T-3. Restore once, on the first `.rows`; on a later rows change, set `selection = nil` when no row has it. Remove `ListScrollAnchorModifier`, `scrollRowIDs` and `scrollIsLoaded` from this page. Add `#Preview("Failed")` and `#Preview("Empty")` for `ConclusionListPage<PersonsList>.page` with the failed and empty bodies (a preview of the page chrome over `PVCallout` and `PVEmptyState`, no session). The kinds' doc comments ("so `PVList` lays out no second line") stay true; leave them.
Check: T-3 and `PersonsListTests` pass; the app shows the L1–L7 frames.

**STEP-6 — The list reports its anchor**
Files: `macos/App/Features/Workspace/WorkspaceNavigation.swift`, `macos/ProvenenciaTests/WorkspaceNavigationTests.swift`.
Do: rename per D-8 (the modifier's two calls, the tests); add T-4.
Check: `rg -n "noteListScroll" macos` prints nothing; `WorkspaceNavigationTests` pass.

**STEP-7 — Version**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj` (`MARKETING_VERSION`).
Do: 0.34.1 → 0.35.0, together.
Check: the three agree (`rg -n "0\.35\.0" VERSION core/version.go macos/Provenencia.xcodeproj/project.pbxproj`).

**STEP-8 — Prove the expected behaviors**
Do: run §10 steps 6–9 and record in the PR description and this plan's Landed note, for each: type-select, ⌥↑/⌥↓, VoiceOver reading a row and Return opening it, the iron selection in dark appearance (its contrast, white on iron 500), and which separator branch of D-12 shipped. A behavior the platform lacks is recorded, not built (Out).
Check: four lines written.

**STEP-9 — Docs**
Files: `macos/App/DesignSystem/README.md` (List row; a ListPageHeader row; "The table tradeoff" names `PVList` as the native counterpart), `docs/macos-client-patterns.md` § 9 (the Conclusion lists' exception to rule 3; its "List → detail page" row), `docs/ideas/wide-layout.md` (the Conclusion lists' row answered: they fill the pane, S16-67), `docs/ideas/kit-layering.md` (remove the `.pvListFocusStop` mention; add an entry: whether `PVTable` follows the native list, given two selection looks and two Page-key meanings, with STEP-8's type-select and ⌥ findings), `.agents/skills/add-workspace-location/SKILL.md` (line 34: a list's anchor row in `listScrollAnchor`, top row on Sources and Source types, selected row on the Conclusion lists through `noteListAnchor`), `completed.md`, `deployment-plan.md` (map row), this plan (status), `design/S16-D13-…` → `design/archive/`, `design/README.md`.
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py` reports no errors; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period ("Select a row on the Persons, Events and Places lists with a click and open it with a double-click or Return."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `PVListTests.swift` `onSelectionInkIsInverseOnlyWhenProminent` *(new)* | `PVListInk.color(PVColor.textMuted, prominence: .increased)` → `PVColor.textInverse`; `.standard` → `PVColor.textMuted` | AC-2.1, AC-2.2, D-4 |
| T-2 | Swift | `PVListTests.swift` `homeAndEndNameTheEdgeRows` *(new)* | `edgeIndex(for: .home, count: 16000)` → 0; `.end` → 15999; `.downArrow` → nil; `.end` with count 0 → nil | AC-3.2, D-5 |
| T-3 | Swift | `PersonsListTests.swift` `restoredSelectionIsTheAnchorWhenItsRowIsListed` *(new)* | anchor `p2`, rows `p1 p2 p3` → `p2`; anchor `p9` → nil; anchor nil → nil; rows empty → nil | AC-4.1 – AC-4.5, D-7 |
| T-4 | Swift | `WorkspaceNavigationTests.swift` `aClearedSelectionLeavesNoAnchor` *(new)* | Persons; `noteListAnchor("person-1")`; `noteListAnchor(nil)`; go to Events; Back → `listScrollAnchor == nil` | AC-4.4, D-7, D-8 |
| T-5 | Swift | `WorkspaceNavigationTests.swift` `leavingAListStampsTheOutgoingEntry`, `sourceTypesListIsAListRoot` (renamed calls) | unchanged → unchanged | AC-4.2, AC-4.3, AC-4.6 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `PersonsListTests`, `PlacesListTests`, `WorkspaceNavigationTests`, `PVListTests`, `PVTableTests` (it calls `PVListKeyboard.action`).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none added)
- [ ] Sweep: `VocabularyHeader`, `PVListRowStyle`, `pvListChrome`, `noteListScroll`, `.pvListFocusStop` `rg`'d across `.agents/`, `.cursor/rules/`, `docs/*.md`, `docs/ideas/`, `macos/App/DesignSystem/README.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (§ 9 exception recorded)
- [ ] UI matches the brief inventory; no new kit primitive beyond the moved header
- [ ] Version 0.35.0 in VERSION, core/version.go, MARKETING_VERSION together
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan and STEP-8's four findings
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief S16-D13 moved to design/archive/ and design/README.md updated
- [ ] Domain doc updated: docs/macos-client-patterns.md § 9; .agents/skills/add-workspace-location/SKILL.md
- [ ] PR description: what shipped, AC evidence, deviations, manual check, STEP-8 findings
```

## 10. Manual check

Use a project with Persons, Events and Places, and the user's 16,000-person project for steps 3 and 4.

1. Open Persons from the sidebar at the default window (Regular): the header across the pane, the list to the pane's edges and bottom, no chevrons, nothing selected, list at its top. Press ↓: the first row is selected (AC-1.1, AC-1.3, AC-3.1, AC-4.1).
2. Click a row: selected, white text on the accent, nothing opens. Click the window's title bar area of another app: the bar turns grey. Hover: nothing. Right-click: no menu. Double-click: the page opens; Back: the row selected and in view. Select another, press Return: it opens. Press ↓ and ↑: the selection moves one row and stays in view (AC-2.1, AC-2.2, AC-2.3, AC-2.4, AC-2.5, AC-2.6, AC-3.4, AC-4.2).
3. At 16,000 persons, fresh launch, before clicking: End, Home, End again — the last and first rows show each time; the selection does not change. Page Down/Up scroll a screen (AC-3.2, AC-3.3).
4. Scroll to row ~800, select it, open Events from the sidebar, Back: row ~800 selected and in view. Deselect, Events, Back: top, nothing selected (AC-4.3, AC-4.4).
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

- `PVList` has a caller besides `ConclusionListPage` at the base (`rg -n "PVList\(" macos/App`).
- At 16,000 persons the Persons page takes visibly longer to show rows than at the base, or End does not show the last row on the first press after a fresh load.
- The primary action does not fire on Return, or a double-click also fires it on a row other than the clicked one.
- A focused selected row's `backgroundProminence` is not `.increased` (the white ink does not appear).
- `scrollPosition`, `pvScrollsRowIntoView` or the focus claim cannot be made to work on the `List` without an `NSViewRepresentable`.
- The row background behind a transparent list hides or tints the system selection.
- The brief's frame and an AC disagree.

## 12. Open questions

None.

## 13. PR

**Title:** S16-67 — The Persons, Events and Places lists are native lists
**Body:** objective in one sentence; what shipped against US-1 – US-4; AC evidence; STEP-8's findings; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-67-native-conclusion-lists.md`.
