# S16-66 — The Sources list is a native outline list

**Status:** Blocked — on board S16-D12
**Spike / slice:** Spike 16 · Slice 6f — List keyboard
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S16-D12](../design/S16-D12-sources-list-outline.md), board not agreed yet
**Board:** [Sources List](https://claude.ai/artifact/JDm51QdorUvY79EFoci4cm), page *S2-04 Sources list* (frames S1a–S6). The implementer opens the link; §6 macOS also describes each frame in words (user, 2026-11-23: link and words). The frame-dependent choices are §12's open questions, answered when the board is agreed
**Depends on:** S16-67 (landed [#958](https://github.com/Jake-Robins-Studios/provenencia/pull/958)), S16-D12 (board to draw)
**Blocks:** —
**Branch:** `s16-66-sources-outline-list`
**Version bump:** minor, 0.36.0 → 0.37.0 — the Sources list changes how a researcher works it (a click selects, a double-click or Return opens, graphs open under their Source), no wire or catalog change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-workspace-location`](../../../../.agents/skills/add-workspace-location/SKILL.md), [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md) (the session's derived values), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** —
**Context:** map scope entry [S16-66](../deployment-plan.md#s16-66--the-sources-list-is-a-native-outline-list); working rule "(Batch 6) The Conclusion lists are native lists"; [`docs/macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide); the S16-67 plan and its **Landed** note ([`S16-67-native-conclusion-lists.md`](S16-67-native-conclusion-lists.md)): the platform's cell inset, the row height and wheel step, the row modifiers on the `ForEach`; the map's spike note under S16-66 (a `DisclosureGroup` in a `List` fails; flat rows work)
**Runs on:** macOS with Xcode. The Swift checks (`xcodebuild test`, `scripts/check-pr.sh`, previews) need a Mac; STEP-8 and §10 need a person at the Mac. An agent on another platform hands those checks to the user and says which it could not run.
**Planned:** 2026-11-23 against `main` @ `2f1a459`
**Review:** [`S16-66-sources-outline-list.review.md`](S16-66-sources-outline-list.review.md) — round 1: Fits with changes / Not ready; every blocker Fixed; round 2 runs once the board is agreed and §12 answered

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

The Sources list shows each Source with its Evidence graphs as a column of buttons, so a row grows with its graphs, and the list has no selection and no arrow keys. It moves onto the kit's native list, as the Persons, Events and Places lists did in S16-67, drawn as an outline: a row per Source, and a thinner, indented row per Evidence graph under an open Source. Every Source and every graph is reached, selected and opened alike by mouse and keyboard, and Back returns to the row opened.

**Why now.** The user asked for Page Up, Page Down, Home and End on the Sources list (2026-11-22). S16-65's hand-built keyboard failed; S16-67 put the other lists on the native list, and the user decided the Sources list follows as an outline (2026-11-23).

**What stays.** The header and the toolbar (search, type, status, sort) and what they do; the settings saved per project and user; what opens (a Source's page, a graph's canvas); Copy…; the empty, no-match and failure copy; the reads (the Sources list, the graph list, the graph progress map). The one requirement kept from today's row: the list reaches every Evidence graph (user, 2026-11-23).

## 2. User stories

**US-1.** As a researcher on the Sources page, I see the header and toolbar, then the list filling the pane, with one row per Source.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | 240 Sources, pane 1102 pt (Regular) | `PVListPageHeader` (title `Sources`, the description, `240 sources`, Add source) inset 32 pt on `surfacePage`, a full-width hairline, the toolbar inset 32 pt on `surfaceCard` with its hairline, then the list from the pane's left edge to its right edge and down to its bottom. No caption band, no side hairlines, no card (SO-1) |
| AC-1.2 | The same, pane 2296 pt (Wide) | Header, toolbar and rows inset 56 pt; the title column takes the extra width; the updated column and the ref stay at the trailing edge (SO-W1, per §12 Q-3) |
| AC-1.3 | A Source `1851 Census — Robins household`, type `Census`, published 1851, updated 2 days ago, ref `SRC-4K2QX`, one graph `Default` In progress, closed | Left to right: the closed triangle in the gutter, the 44 pt cover on the gutter, the title (one line, ellipsis) over `Census · 1851 · 1 graph · In progress`, the updated column (`2 days ago`), the mono ref. The row is 66 pt (SO-2, SO-4) |
| AC-1.4 | The same Source, undated | Its secondary line reads `Census · 1 graph · In progress`: the date and its dot are left out (SO-2) |
| AC-1.5 | A 90-character title and a 40-character type at 800 pt pane | The title truncates first; the type truncates next; the date and the summary do not truncate; nothing overlaps (SO-2, SO-4, frame S6) |
| AC-1.6 | A Source with no Artifact, `Passport of J. Robins`, type `Passport` | No triangle; its secondary line reads `Passport · Needs an artifact`; `Needs an artifact` never truncates; the row opens the Source page (SO-8) |
| AC-1.7 | A hover over any row | Nothing changes |

**US-2.** As a researcher, I open a Source to see its Evidence graphs as rows under it, and close it again.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Arrive on the list | Every Source is closed, whether it has one graph or ten (SO-4) |
| AC-2.2 | Click the triangle of a Source with 8 graphs | It turns down; 8 graph rows appear under it in the graph list's order (by name), each indented so its glyph sits under the Source's title; nothing animates; the selection does not change; nothing opens; the Source's summary leaves its secondary line (SO-3, SO-4, SO-5) |
| AC-2.3 | Click the triangle again | The graph rows go; the summary returns (SO-5) |
| AC-2.4 | ⌥-click a closed Source's triangle | Every Source in the list with a triangle opens. ⌥-click an open one: every Source closes (SO-5) |
| AC-2.5 | A graph row is selected; close its Source by the triangle | The Source row is selected (brief § 2) |
| AC-2.11 | The triangle's click on an unselected row | Selects nothing, or (if STEP-8 finds the platform selects the row first: D-13's fallback, brief § 2.1) selects that row; AC-2.2's "the selection does not change" holds only in the first case |
| AC-2.6 | Open two Sources, open Persons from the sidebar, come back to Sources | The two are still open (held for the session) |
| AC-2.7 | Open a Source, then change the sort or a filter | It stays open; the selection clears; the list is at its top (brief § 2) |
| AC-2.8 | Open a Source, quit, relaunch | Every Source is closed |
| AC-2.9 | A graph row of `Jones household`, 12 subjects, 40 observations, In progress | Network glyph, `Jones household` (truncates first), `12 subjects · 40 observations`, the `In progress` badge in a trailing column shared by every graph row, so the badges line up (SO-3) |
| AC-2.10 | Closed Sources' summaries | 1 graph In progress → `1 graph · In progress`; 8 graphs, 3 In progress → `8 graphs · 3 in progress`; 8 graphs all Not started → `8 graphs · Not started`; 8 graphs, 5 Promoted and 3 Not started → `8 graphs · 5 promoted` (D-17, §12 Q-5); counts loading or failed → `8 graphs` (SO-4) |

**US-3.** As a researcher, a click selects a Source or a graph row, and a double-click or Return opens it.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Click a Source row, then a graph row | Each in turn takes the system's full-width bar; the row's text and the triangle draw in the on-selection ink; the cover, the badge and the danger mark keep their colors; nothing opens (SO-6) |
| AC-3.2 | The window loses focus with a row selected | The bar turns grey; the text keeps its own ink (SO-6) |
| AC-3.3 | Double-click a Source row, or select it and press Return | The Source page opens (SO-7) |
| AC-3.4 | Double-click a graph row that links an Artifact, or select it and press Return | Its canvas opens (SO-7) |
| AC-3.5 | A graph that links no Artifact | Its row is faint, `Needs an artifact to open` in its counts slot, no badge; it selects; double-click and Return do nothing (SO-8) |

**US-4.** As a researcher using the keyboard, I move through Sources and graphs alike.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | Open Sources from the sidebar, press ↓ without clicking | The first row is selected (keyboard focus on arrival, no ring) (SO-12) |
| AC-4.2 | ↓ / ↑ with an open Source | The selection crosses Source rows and graph rows alike, one row a press (the platform's) |
| AC-4.3 | 3,000 Sources: End, then Home, nothing selected | The last row shows at the bottom, then the first at the top; the selection does not change |
| AC-4.4 | Page Down / Page Up | The list scrolls a screen; the selection does not move (the platform's) |
| AC-4.5 | A closed Source with graphs selected: → | It opens; the selection stays on the Source |
| AC-4.6 | An open Source selected: ← | It closes |
| AC-4.7 | A graph row selected: ← | Its Source is selected; the Source stays open |
| AC-4.8 | → on an open Source or a graph row; ← on a closed Source; → or ← on a Source with no triangle | Nothing happens |

**US-5.** As a researcher, a right-click on a row offers what the row can do.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-5.1 | Right-click an open Source row | A menu: Open, Copy… (SO-9) |
| AC-5.2 | Right-click a closed Source with 8 graphs, one without an Artifact | Open, Copy…, a separator, then `Open Default`, `Open Jones household`, … in row order, the graph with no Artifact disabled (SO-9, §12 Q-4) |
| AC-5.3 | The same while the graph list loads or after it failed | Open, Copy… only (SO-9) |
| AC-5.4 | Right-click a graph row | Open, disabled when the graph links no Artifact (SO-9) |
| AC-5.5 | Choose `Open Jones household` from a closed Source's menu, then Back | The Source is open and `Jones household` is selected and in view (SO-9, SO-12) |
| AC-5.6 | Choose Copy… | The Copy Source form opens for that Source, as today |
| AC-5.7 | Right-click a row other than the selected one, choose Open, then Back | The row right-clicked is selected and in view |

**US-6.** As a researcher, the list says what it is waiting for and what failed.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-6.1 | First load (the Sources list or the graph list not read yet) | The header without a count line; no toolbar; skeleton Source rows fill the list area, full width (SO-10, D-6) |
| AC-6.2 | A status filter set while the counts load, or a saved type filter while the types load | The toolbar shows; skeleton Source rows fill the list area under it (SO-10) |
| AC-6.3 | An open Source whose graph counts have not arrived | Each graph row shows a skeleton bar in its counts slot and holds its badge slot (SO-10) |
| AC-6.4 | The counts failed, no status filter | Each graph row says `Counts could not load` with the danger mark and no badge; closed summaries read `N graphs` (SO-10, SO-11) |
| AC-6.5 | An open Source whose graphs are not in the graph list yet (a new Source) | One graph row with a skeleton bar under it; it selects and opens nothing (SO-10) |
| AC-6.6 | The graph list failed, no status filter | Sources listed with no triangles and no graph rows; one danger Callout with the error above the rows (SO-11, §12 Q-4) |
| AC-6.7 | The graph list or the counts failed with a status filter set | The toolbar, then the danger Callout alone, as today (SO-11) |
| AC-6.8 | The Sources list fails with nothing to show | The header without a count line; no toolbar; the danger Callout at the top of the list area on the gutter, at most 560 pt wide (SO-11) |
| AC-6.9 | No Sources | The header without a count line; no toolbar; `PVEmptyState` with today's icon, title and message centered in the list area (SO-11) |
| AC-6.10 | Filters match nothing | The toolbar, then today's no-match state with Clear filters, centered in the list area (SO-11) |

**US-7.** As a researcher, Back returns me to the row I left.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-7.1 | Sources from the sidebar | Nothing selected; the list at its top (SO-12) |
| AC-7.2 | Double-click Source row 800 of 3,000, then Back | Row 800 selected and in view (SO-12) |
| AC-7.3 | Open a Source, double-click its third graph, then Back | The Source open, the graph row selected and in view (SO-12) |
| AC-7.4 | Back to a graph whose Source is closed now (⌥-click closed all meanwhile, from another history entry) | The Source opens; the graph row is selected and in view (brief § 2) |
| AC-7.5 | Back to an entry whose row was deleted meanwhile | Nothing selected; the list at its top (brief § 2) |
| AC-7.6 | Back to an entry whose Source a filter now hides | Nothing selected; the list at its top |
| AC-7.7 | A history file written before this PR (a top-row Source id) | That Source row is selected and in view |

## 3. Scope

| In | Covered by |
| --- | --- |
| SO-1 the page: header, toolbar, list filling the pane; caption band and band hairlines go | STEP-2, STEP-5, AC-1.1, AC-1.2 |
| SO-2 the Source row on the Persons row's geometry, the triangle in the gutter | STEP-1, STEP-4, AC-1.3 – AC-1.5 |
| SO-3 the graph row | STEP-4, AC-2.2, AC-2.9 |
| SO-4 closed at first; the closed summary | STEP-3, STEP-4, AC-2.1, AC-2.10 |
| SO-5 toggling, ⌥-click | STEP-6, AC-2.2 – AC-2.5 |
| SO-6 selection and its ink | STEP-1, STEP-4, AC-3.1, AC-3.2 |
| SO-7 opening by double-click and Return | STEP-5, AC-3.3, AC-3.4 |
| SO-8 cannot open: a Source with no Artifact, a graph with none | STEP-3, STEP-4, AC-1.6, AC-3.5 |
| SO-9 the right-click menus | STEP-7, AC-5.1 – AC-5.7 |
| SO-10 loading and late counts | STEP-4, STEP-5, AC-6.1 – AC-6.5 |
| SO-11 failure and empty | STEP-5, AC-6.6 – AC-6.10 |
| SO-12 arrival and Back | STEP-5, AC-4.1, AC-7.1 – AC-7.7 |
| SO-W1 Wide (option per §12 Q-3) | STEP-5, AC-1.2 |
| SO-W2 the states at Wide | STEP-5, AC-6.1 – AC-6.10 |
| Open and closed held for the session | STEP-3, AC-2.6 – AC-2.8 |
| → and ← (brief § 2 "expected") | STEP-6, STEP-8, AC-4.5 – AC-4.8 |
| Home and End; ↑/↓ and Page keys (platform) | STEP-1, AC-4.2 – AC-4.4 |
| The kit's native list body split from `PVList`'s row; the row's leading slot | STEP-1 |
| `ConclusionListFrame` becomes the kit's list page frame | STEP-2 |
| Prove the brief's § 2.1 rows marked * and the § 2 "expected" keys, and record the result | STEP-8 |
| The new bar 38 in the map | STEP-10 |
| Docs and skills the scope entry names | STEP-10 |

| Out | Home |
| --- | --- |
| The header's and toolbar's controls, new filters or sorts, new columns of new data | not planned (brief § 2.2) |
| The Add Source and Copy dialogs, the Source page, the canvas | not planned (brief § 2.2) |
| The tables (Source types, Metadata, Properties) on the native list | [`docs/ideas/kit-layering.md`](../../../ideas/kit-layering.md) (S16-67's entry) |
| Page keys on other pages | re-planned after S16-67 (map, S16-65 entry) |
| Multiple selection, drag, editing in a row | not planned (brief § 2.2) |
| → and ← written with an `NSEvent` monitor or an `NSViewRepresentable` if `.onKeyPress` does not receive them | [`docs/ideas/kit-layering.md`](../../../ideas/kit-layering.md) entry this PR adds when STEP-8 finds them missing |
| Opening and closing animated | not planned (brief § 2.1) |
| A keyboard command that opens or closes every Source (⌥→ / ⌥←) | not planned (the brief names ⌥-click only) |
| `ListScrollAnchorModifier` on the Source types list | stays as it is (its own page) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Native list | `macos/App/DesignSystem/Components/List/PVList.swift` `PVList` | `List(selection:)` over `ForEach(items)` of the private `PVListRow`; row modifiers on the `ForEach` (`listRowInsets` with `density.vertical` top and bottom and `rowInset` = `horizontalInset − platformCellInset` (8) on the sides, `listRowSeparator(.visible)`, `listRowSeparatorTint(PVColor.borderSubtle)`, `transaction { $0.animation = nil }`); `.listStyle(.plain)`, `.scrollContentBackground(.hidden)`, `defaultMinListRowHeight` = `thumbnailSize + 2 × density.vertical` (the wheel step), `.focusEffectDisabled()`, `FocusClaim.claim` on appear, `.contextMenu(forSelectionType:menu: { EmptyView() }, primaryAction:)` (double-click, Return), `.onKeyPress(keys: [.home, .end])` scrolling through `.pvScrollsRowIntoView(edgeRow, …, whenRequested: edgeRequest)`, `.pvScrollsRowIntoView(selection, animated: false, scrollsOnAppear: true)`. One caller: `ConclusionListPage.swift` |
| Row | `PVList.swift` `PVListRow` (private) | `HStack(spacing: space6)`: thumbnail framed to `thumbnailSize`, the title over the secondary line (inks through `PVColor.onSelection`), `PVListDetailCell`, the mono ref; `.frame(height: thumbnailSize)`; separator guides at 0 and the content's width; `accessibilityElement(children: .ignore)` with the label and identifier |
| Detail cell | `PVList.swift` `PVListDetailCell` | `iconSize` default 14; the only caller passing another is `SourcesListRow.swift:248` (`iconSize: 12`) |
| Skeleton | `PVList.swift` `PVListSkeleton` | Rows at row geometry, `detailWidth`, `horizontalInset` |
| Page frame | `macos/App/Features/Conclusions/ConclusionListPage.swift` `ConclusionListFrame` (private) | `PVListPageHeader` (no description, no Add) on `surfacePage`, `PVDivider`, the content on `surfaceCard` filling the pane; gutter from `widthClass.fullPaneGutter`; accessibility container `<root>.list`. `ConclusionListPage.loadingArea(gutter:)` (30 skeleton rows, `minHeight: 0`, clipped), `emptyArea()`, `failureArea(_:gutter:)` (`.pvListPageMessage(gutter:maxWidth: measureForm)`) |
| Selection and Back | `macos/App/Features/Workspace/WorkspaceNavigation.swift` `listAnchor`, `noteListAnchor(_:)`, `apply` (`listAnchor = location.isListRoot ? location.listScrollAnchor : nil`), `ListAnchor.resolved`, `ListSelectionAnchorModifier(rowIDs:isSettled:)`, `ListScrollAnchorModifier` | The Conclusion lists bind `listAnchor` as the selection; the modifier clears an anchor with no row once the read settles. Sources and Source types wear `ListScrollAnchorModifier` (top row) |
| Sources page | `macos/App/Features/Sources/SourcesListView.swift` `SourcesListView`, `SourcesListContent` | `VStack`: `header(visibleCount:)` (`PVListPageHeader` at `gutterPage`), `PVDivider`, then: `ProgressView` while loading; `PVCallout` + `.pvListPageMessage()` on `model.loadError`; `emptyState` (top-aligned, `space8` top); else `toolbar` (`gutterPage`) and `listBody(rows:)`. The whole is `.pvListBand(widthClass)`. `listBody`: `statusCountsError` Callout; `ProgressView` while `isAwaitingFilterData`; the no-match `PVEmptyState(compact: true)` with Clear filters (top-aligned); else `PVWidthBreakpoints(SourcesListColumns.breakpoints)` → `ScrollView` → `LazyVStack` with a pinned `captionBand` and a `SourcesListRow` per Source, wearing `ListScrollAnchorModifier`. `.onChange(of: model.settings)` → `navigation.go(to: navigation.currentLocation.withListScrollAnchor(nil))`. Add Source dialog, Copy dialog |
| Source row | `macos/App/Features/Sources/SourcesListRow.swift` `SourcesListRow`, `SourcesLinkLabel`, `SourcesListRowButtonStyle`, `SourcesListRowButtonBody`, the `SourcesModel.EvidenceStatus` badge extension (`badgeTone`, `badgeIcon`, `badgeSubtle`, `badge`) | A `Button` (the Source link: 40 pt cover, wrapping title, record line, ref · updated line) with `.pvRightClickMenu` (Copy…), the Type and date cells by `SourcesListColumns.datePlacement`, and a stack of `SourcesGraphButton`s; `entries` builds one per graph, or `needsArtifact` / `listLoading` / `listFailed` |
| Graph button | `macos/App/Features/Sources/SourcesGraphButton.swift` `SourcesGraphButton` (`Kind`, `Open`, `height` 52, `statusSlotWidth` 112), `SourcesGraphButtonLook`, `SourcesGraphButtonFrame`, `SourcesGraphButtonStyle`, `SourcesGraphButtonBody` | Bordered buttons with hover; status slot (badge, or a skeleton bar while counts load); chevron |
| Columns | `macos/App/Features/Sources/SourcesListColumns.swift` `SourcesListColumns`, `sourcesSourceCell()`, `sourcesTypeCell(_:)`, `sourcesPublishedCell(_:)`, `sourcesGraphCell(_:)` | Caption band and row widths; callers are the two files above |
| Counts | `macos/App/Features/Sources/SourcesGraphCounts.swift` `SourcesGraphCounts`; `SourcesGraphCountLine.swift` `SourcesGraphCountLine` (`Style.card`, `.button`) | `.card` callers: `SourcePageGraphsView.swift:85`, `SourceMoveDialog.swift:163`; `.button`: `SourcesGraphButton.swift:116`. Inks are `textMuted`, the mark `danger` |
| Navigation helpers | `macos/App/Features/Sources/SourcesListNavigation.swift` `pageLocation(for:)`, `graphLocation(for:graph:)`, `graphBlockedReason(for:)` | Pure; tested in `SourcesListNavigationTests.swift` |
| Model | `macos/App/Features/Sources/SourcesModel.swift` `SourcesModel` | `visibleSources` (derived `.visibleSources`), `statusCountsError`, `isAwaitingFilterData`, `loadError`, `isCatalogEmpty`, `countLine(visibleCount:)`, `openCopy(_:)`, `typeLabel(for:)`, `typeIconKey(for:)`, `pageProjectDir`. Held in the view's `@State`: rebuilt when the page is rebuilt |
| Graph reads | `macos/App/Features/Workspace/Session/WorkspaceSession+EvidenceGraphs.swift` `evidenceGraphsRead(sourceID:)` (`.loading` while the list loads or lacks the Source), `evidenceGraph(id:)` (carries `sourceID`), `evidenceGraphProgress(graphID:)`, `evidenceGraphCountsLoading`, `evidenceGraphCountsError`, `evidenceGraphsHandle` | Indexed once per list revision (derived `.evidenceGraphIndex`) |
| Session view state | `macos/App/Features/Workspace/Session/WorkspaceSession.swift` `graphCameras`, `graphCamera(for:)`, `setGraphCamera(_:for:)` | Per-graph pan and zoom, "not catalog data; quit drops it" |
| Derived values | `macos/App/Features/Workspace/Session/WorkspaceSession+Derived.swift` `DerivedValueID`, `derived(_:inputs:extra:build:)`, `DerivedInput.derived(_:)` | `.visibleSources` is one |
| Published date | `macos/App/DesignSystem/Recipes/PublishedDate/PVPublishedDate.swift` `PVPublishedDate` (`Style.labeled`, `.bare`) | `.labeled` callers are all in `SourcesListRow.swift` (lines 114, 230); `.bare`: `SourcesListRow.swift:122`, `PersonSourcesSection.swift:391`. Inks `textMuted`, `textSecondary` |
| Band | `macos/App/DesignSystem/Components/PageColumns/PVPageColumns.swift` `pvListBand(_:)` | Callers: `SourcesListView.swift:77`, `SourceTypesView.swift:60` |
| Disclosure | `macos/App/DesignSystem/Components/Disclosure/PVDisclosureButton.swift` `pvExpandedState(_:)` | VoiceOver custom content for an expandable control |
| Copy | `macos/App/Platform/L10n.swift` `L10n.Sources` | Keys only the deleted views use: `columnSource`, `columnType`, `columnPublished`, `columnEvidenceGraph`, `openSourcePage`, `graphsFailedTitle`, `graphsFailedDetail`, `graphsLoading`, `noGraphYet`, `needsArtifactTooltip`, `graphBlockLabel`, `graphButtonLabel` (both forms), `graphButtonHelp`, `listAccessibilityLabel`; `L10n.PublishedDate.label`, `.none` (only `.labeled`). Kept: `needsArtifact`, `graphNeedsArtifactToOpen`, `graphNeedsArtifactTooltip`, `copySourceEntry`, `openEvidenceGraphLabel`, `graphCounts` |
| Tests | `macos/ProvenenciaTests/PVListTests.swift` (`aWheelStepScrollsOneRow` expects 66); `PersonsListTests.swift` (`loadingAreaFitsTheListArea`); `SourcesModelTests.swift` (`listColumnsMatchBoard`, `columnsPlaceTheDateByWidth`, `graphButtonCopyMatchesBoard`, `statusBadgeMatchesBoard`, `graphProgressCopyMatchesBoard`, the filter and status tests); `SourcesListNavigationTests.swift`; `WorkspaceNavigationTests.swift` | |

**Precedent.** S16-67 ([#958](https://github.com/Jake-Robins-Studios/provenencia/pull/958)) moved the Conclusion lists onto `PVList`: copy its `List` setup, its row modifiers on the `ForEach`, its `listAnchor` binding with `ListSelectionAnchorModifier`, its loading and failure areas, and its Landed note's fixes (the 8 pt cell inset, the content height, the minimum row height as the wheel step). The session-held view state copies `graphCameras` (S15-38), but observed, since the list draws from it. Do not copy `DisclosureGroup`: the map's spike found it fails in a `List`.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | The native list body leaves `PVList` as `PVListBody<Item: Identifiable, Row: View>` *(new)* in `macos/App/DesignSystem/Components/List/PVListBody.swift`: `init(items:, selection: Binding<Item.ID?>, minimumRowHeight: CGFloat, horizontalInset: CGFloat, leadingHang: CGFloat = 0, label: LocalizedStringResource, onActivate: @escaping (Item) -> Void, menu: @escaping (Item) -> [[PVActionMenuItem]] = { _ in [] }, @ViewBuilder row: @escaping (Item) -> Row)` (no `Menu` generic: `PVListBody<Item, Row>`). It owns everything `PVList.body` does today: the `List`, the row modifiers on the `ForEach` with **horizontal insets only** (top and bottom 0; leading `PVListBody.leadingInset(horizontalInset:leadingHang:)` = `max(0, horizontalInset − 8 − leadingHang)`, trailing `max(0, horizontalInset − 8)`), separators and tint, no animation, plain style, hidden background, `defaultMinListRowHeight = minimumRowHeight`, focus, the primary action, Home/End, the selection's scroll on appear, the label. The menu is the `.contextMenu(forSelectionType:menu:primaryAction:)`'s `menu`: for the first id of the right-clicked set that has an item, `menu(item)` drawn as one native `Button` per `PVActionMenuItem` (its `title`, `.disabled(!isEnabled)`, its `accessibilityIdentifier`, its `action`) with a `Divider` between sections; nothing for an empty set, an id with no item, or no items. The selection's scroll: `.pvScrollsRowIntoView(selection, animated: false, scrollsOnAppear: true)` as today, plus a `@State` request token bumped when the selected id is in `items` now and was not in the last `items` (`.onChange(of: items.map(\.id))`), driving a second `.pvScrollsRowIntoView(selection, animated: false, whenRequested:)` (a selection set before its row exists scrolls a turn after the row appears). The body applies no accessibility label or identifier to a row: each row view applies its own (`accessibilityElement(children: .ignore)`, label, identifier, hint). `PVList` keeps its API and becomes `PVListBody` over `PVListRow`, which keeps applying its label and identifier closures | The brief's inventory: one body, `PVList` the homogeneous row on it, Sources the second caller. Rows own their height (D-2), so one body serves 66 pt and thinner rows. The insets' arithmetic is the S16-67 Landed fix, kept in one function | `PVList` growing an enum of row kinds (the kit learns Sources); a second `List` setup in Sources (the S16-67 fixes copied); a `@ViewBuilder` menu slot (a second item model beside `PVActionMenuItem`, review M-1); a page-level scroll for a late row (review M-2) |
| D-2 | `PVListRow` becomes internal (`PVListRow<Item, Leading: View, Thumbnail, Primary, Secondary>`) in `PVList.swift`, with a leading slot: `leading: (Item) -> Leading`, `leadingWidth: CGFloat` (0: no slot). With a slot, the row starts with the slot framed `leadingWidth` × `thumbnailSize`, then `PVSpacing.space2` (4 pt), then the thumbnail; `PVListRow.hang(leadingWidth:)` = `leadingWidth + 4` (0 with no slot) and `PVListRow.titleLeading(leadingWidth:thumbnailSize:)` *(new)* = `hang(leadingWidth:) + thumbnailSize + PVSpacing.space6` (the title's leading edge, which the row's `HStack` spacing sets); the row's separator leading guide is `.alignmentGuide(.listRowSeparatorLeading) { _ in hang(leadingWidth:) }` (the thumbnail's leading edge; 0 with no slot, as today). The row pads itself `density.vertical` top and bottom (it was the list's inset), so a `PVList` row stays 66 pt | The Persons row layout is reused for the Source row (brief inventory). The slot inside the row's frame cannot be clipped by the table's cell; the body's smaller leading inset (D-1) puts the thumbnail back on the gutter. The hang is one number both sides read | A negative offset hanging the triangle outside the cell (the cell may clip it) |
| D-3 | `ConclusionListFrame` leaves Conclusions as the kit recipe `PVListPage<Toolbar: View, Content: View>` *(new)* at `macos/App/DesignSystem/Recipes/ListPage/PVListPage.swift`: `init(title:, description: LocalizedStringResource? = nil, countLine: String?, add: PVListPageHeader.Add? = nil, identifierRoot: String, @ViewBuilder toolbar: (CGFloat) -> Toolbar, @ViewBuilder content: (CGFloat) -> Content)`, plus an initializer with no toolbar. Body: the header (`identifierPrefix: identifierRoot`, `gutter`) on `surfacePage`, `PVDivider`, the toolbar (when given) on `surfaceCard` with its bottom `PVDivider`, then the content on `surfaceCard` filling the pane; `accessibilityElement(children: .contain)`, identifier `<root>.list`. It reads `\.pvWidthClass` once and hands `fullPaneGutter` to the toolbar and the content. `ConclusionListPage.loadingArea(gutter:)` and `failureArea(_:gutter:)` move onto it as `PVListPage.loadingArea(gutter:, detailWidth:)` (callers pass `PVLastUpdated.columnWidth`) and `PVListPage.failureArea(_:gutter:)`; `emptyArea()` stays per page (a bare `PVEmptyState`) | Brief inventory ("lifted out of Conclusions, with a toolbar slot; picks `fullPaneGutter` once; its loading, empty and failure areas too"). Two callers make it kit. The empty state is one kit call with each page's own glyph and copy, so a wrapper adds nothing | Sources building its own `VStack` (two copies of the gutter choice); an empty-area helper |
| D-4 | The list's rows are one flat array of `SourcesOutlineRow` *(new)*, built by the pure `SourcesOutline.rows(sources: [CatalogSource], graphs: (String) -> QueryRead<[CatalogEvidenceGraph]>, expanded: Set<String>)` in `macos/App/Features/Sources/SourcesOutline.swift` *(new)*. `SourcesOutlineRow` is `Identifiable, Equatable` with `id: String` and `kind`: `.source(CatalogSource, disclosure: .none / .collapsed / .expanded)`, `.graph(CatalogEvidenceGraph, source: CatalogSource)`, `.pendingGraph(source: CatalogSource)`. For each visible Source in order: no Artifact → `.none`, no graph rows; else its graph read: `.failed` → `.none`; `.loaded(graphs)` → `.collapsed` or `.expanded` by the set, and when expanded a `.graph` row per graph in read order; `.loading` → `.collapsed` or `.expanded`, and when expanded one `.pendingGraph`. Ids: a Source's and a graph's own id; a pending row's `"<sourceID>#graphs"` | The spike: flat rows in one `List`, our own disclosure. One pure function is testable without a view. Raw ids keep history files compatible (AC-7.7). A Source always has a graph, so a loading read still gets a triangle (brief § 2) | `DisclosureGroup` (spike: late children, broken keys, no deep restore); prefixed ids (old history anchors would stop resolving) |
| D-5 | `SourcesModel.outline` *(new)* returns `SourcesOutline` *(new struct: `rows: [SourcesOutlineRow]`, `ownerByGraphID: [String: CatalogSource]`)*, built through `session.derived(.sourcesOutline, inputs: [.derived(.visibleSources), .key(session.evidenceGraphsKey)], extra: session.expandedSourceIDs) { SourcesOutline(sources: visibleSources, graphs: session.evidenceGraphsRead(sourceID:), expanded: session.expandedSourceIDs) }`. `ownerByGraphID` maps every graph id of a visible Source in the loaded graph list, expanded or collapsed, to its Source. `DerivedValueID.sourcesOutline` *(new)*. If the debug undeclared-read check fires on the build, stop (§11) | Built once per change of what it reads (the derived-value rule); counts are read by each row as it draws, so a counts update rebuilds nothing | Building in the view body on every pass (3,000 Sources) |
| D-6 | The list shows rows once the Sources list has a value and the graph list has read (a value or a failure): `SourcesModel.isAwaitingGraphList` *(new)* = the graph list handle missing or `read.isLoading`. While it is true, and while `isAwaitingFilterData` is, the list area is `PVListPage.loadingArea(gutter:)`. The toolbar shows exactly when today's code shows it (rows, filters waiting, no match, status failure) | "The rows appear when the first two are in, so none arrives late under the pointer" (brief § 2) | Rows first, triangles arriving later |
| D-7 | Expanded and collapsed live on the session: `WorkspaceSession.expandedSourceIDs: Set<String>` *(new; `private(set)`, observed: without `graphCameras`' `@ObservationIgnored`)* in `WorkspaceSession.swift` beside `graphCameras`, with `setSourcesExpanded(_ ids: [String], _ expanded: Bool)` *(new; one function for one Source and for ⌥-click)* in `WorkspaceSession+Sources.swift`. Never written to history, the settings file or the catalog; a new session (relaunch, another project) starts empty | "Held for the session; Back and the sidebar keep it; a relaunch starts over" (brief § 2). `SourcesModel` is rebuilt with the page, the session is not. `graphCameras` is the precedent; observed because the list draws from it | On `SourcesModel` (lost on every visit); on `SourcesListSettings` (saved to disk) |
| D-8 | Selection is navigation's `listAnchor`, bound as on the Conclusion lists: `PVListBody(selection: Binding(get: { navigation.listAnchor }, set: { navigation.noteListAnchor($0) }))`. The page wears `ListSelectionAnchorModifier(rowIDs: outline.rows.map(\.id), isSettled:, reveal:)` with `isSettled` = the Sources handle `isSettled` and the graph list handle settled or failed, and `reveal` of D-9. `ListScrollAnchorModifier` leaves the page. `.onChange(of: model.settings)` keeps today's coalesced `go(to:)` with a nil anchor, which clears the selection and puts the list at its top; expanded and collapsed are kept | One owner of the selected row, as S16-67 (D-7 there). `rowIDs` keeps its meaning, the drawn rows | Passing ids that are not drawn (review M-2) |
| D-9 | Back reveals a graph. `ListSelectionAnchorModifier` gains `reveal: (String) -> Bool = { _ in false }` *(new)*: in `clearIfGone()`, when settled, the anchor resolves through `ListAnchor.settle(_ anchor: String?, in rowIDs: [String], reveal: (String) -> Bool) -> String?` *(new, pure, beside `resolved`)*: an anchor in `rowIDs` stays; one not in it stays when `reveal(anchor)` returns true, else nil. The Sources page passes `{ anchor in guard let id = outline.sourceToReveal(anchor) else { return false }; session.setSourcesExpanded([id], true); return true }`, where `SourcesOutline.sourceToReveal(_ anchor: String) -> String?` *(new, pure)* returns `ownerByGraphID[anchor]?.id` when that Source is collapsed, else nil. The graph row is drawn on the next outline; `PVListBody`'s late-row scroll (D-1) brings it into view. A collapse never reaches the reveal: D-15 moves a collapsing Source's graph selection to the Source before it collapses | "Back to a graph in a closed Source opens it" (brief § 2); one restore path and one scroll path, in the shared types (review M-2); the order fixes review X-1 | A page-level `onChange` and second scroll modifier (review M-2); expanding every Source on Back |
| D-10 | Opening: `SourcesListNavigation.location(for row: SourcesOutlineRow) -> WorkspaceLocation?` *(new, pure)*: `.source` → `SourcesListNavigation.pageLocation(for:)`; `.graph(graph, source)` → `graphLocation(for: source, graph: graph)` (nil without an Artifact); `.pendingGraph` → nil. `onActivate` calls `navigation.go(to:)` when non-nil and does nothing otherwise | One rule for double-click, Return and the menu's Open; the existing helpers stay the one place a graph's gate is read | Return handled per row view |
| D-11 | The Source row is `SourcesSourceRow` *(new, private view)* in `macos/App/Features/Sources/SourcesOutlineRows.swift` *(new)*: `PVListRow` with the leading slot (`leadingWidth: 16`; the triangle of D-13, or empty when `.none`), `CachedThumbnail(projectDir:, relPath: source.thumbnailRelPath, typeIconKey: model.typeIconKey(for:), size: 44)`, primary `Text(verbatim: source.title)`, secondary `SourcesSecondaryLine` *(new, private)*, detail `PVLastUpdated.column { $0.updated.at }` (D-26), meta the ref, density `.comfortable`. `SourcesSecondaryLine`: an `HStack(spacing: space3)` of up to three parts, a `·` between each two present parts and none at either end: the type (lineLimit 1, `layoutPriority(0)`, `.help`; left out when the label is empty), `PVPublishedDate(date:)` (left out when `SourceDateText.line(date)` is nil; `fixedSize`), and the tail: `L10n.Sources.needsArtifact` with no Artifact, else the summary (D-17) on a collapsed Source whose graphs are loaded, else nothing (`fixedSize`, `layoutPriority(2)`). So: `Census`, `Census · 1851`, `Census · 1 graph · In progress`, `Census · 1851 · 8 graphs`. Every ink through `PVColor.onSelection`; the dots `textFaint` through it | SO-2: the Persons geometry with a leading slot; the type truncates first, the date and summary never (AC-1.5) | A Sources-only row copy of `PVListRow`. The updated icon is 14 pt, as Persons (it was 12 on today's second line; the brief: "as Persons") |
| D-12 | The graph row is `SourcesGraphRow` *(new, private view)* in the same file, its content `SourcesGraphButton`'s without a button, frame, border, hover or chevron. Layout: horizontal content from the row's leading edge, a clear spacer of `PVListRow.titleLeading(leadingWidth: 16, thumbnailSize: 44)` (84 pt: the glyph under the title), `PVIcon(.network, size: 15)`, then per §12 Q-1 the name (lineLimit 1, truncates first) and `SourcesGraphCountLine(counts:, style: .row)`, then the status slot (`statusSlotWidth` 112, trailing): the badge, a skeleton bar while counts load, empty when failed. The row is `.frame(height: SourcesGraphRow.height)` *(new; value per §12 Q-1)*, content centered vertically. States: `.graph` with an Artifact (live inks); without one (glyph and name `textFaint`, `L10n.Sources.graphNeedsArtifactToOpen` italic micro in the counts slot, no badge); `.pendingGraph` (glyph faint, a 72 × 6 skeleton bar for the name, no badge). The separator's leading guide is `.alignmentGuide(.listRowSeparatorLeading) { _ in PVListRow.titleLeading(leadingWidth: 16, thumbnailSize: 44) }`. The row applies its own accessibility (D-25) | SO-3, SO-8, SO-10; the badges line up in one trailing column; reusing the button's content keeps the copy | A kit graph row (one domain caller, brief: "Not a kit component") |
| D-13 | The disclosure triangle is a private view in `SourcesOutlineRows.swift`: a `Button` with `.buttonStyle(.plain)` and `.focusable(false)`, label `PVIcon(PVExpandedState.outlineChevron(isExpanded:), size: 12)` (*new* in `PVDisclosureButton.swift` beside `chevron(isExpanded:)`: `.chevronForward` collapsed, `.chevronDown` expanded) centered in the 16 × 44 slot with `.contentShape(Rectangle())` over the row's height; ink `PVColor.onSelection(PVColor.textMuted)`. Its action, with `target` = the Source's ids (`NSEvent.modifierFlags.contains(.option)`: every Source in the outline with a triangle) and `expand` = `!isExpanded`: when collapsing, first D-15 (`noteListAnchor` with its result), then `session.setSourcesExpanded(target, expand)`. Not animated (the `ForEach`'s transaction) | Brief § 2.1 and inventory: `PVIcon` chevron in a plain button, right closed and down open, not `PVDisclosureButton` (down and up). `NSEvent.modifierFlags` is how `GraphCanvasDocumentView` reads a modifier at the event | A `TapGesture` with modifiers (does not read ⌥ on a `Button`) |
| D-14 | → and ← are `.onKeyPress(keys: [.rightArrow, .leftArrow], phases: .down)` on the `PVListBody`, through the pure `SourcesOutline.keyAction(_ key: KeyEquivalent, selected: SourcesOutlineRow?) -> SourcesOutlineKeyAction` *(new: `.expand(sourceID)`, `.collapse(sourceID)`, `.select(id)`, `.ignore`)*: → on a `.collapsed` Source → `.expand`; ← on an `.expanded` Source → `.collapse` (run in D-15's order); ← on a `.graph` or `.pendingGraph` row → `.select(sourceID)`; else `.ignore`. `.ignore` returns `.ignored`; the rest `.handled`. If STEP-8 finds the keys never reach the handler, the PR ships without them and records it (Out line) | Brief § 2: expected, proven here. The S16-67 Home/End handler is the same shape on the same list | An `NSEvent` monitor (Out) |
| D-15 | Collapsing a Source whose graph is selected selects the Source: `SourcesOutline.selectionAfterCollapsing(_ collapsing: Set<String>, selection: String?) -> String?` *(new, pure, reading the outline's rows)* returns the Source's id when the selection is a graph or pending row of a collapsing Source, else the selection unchanged; the triangle and ← both call it and `navigation.noteListAnchor` with a changed result **before** they collapse (so the reveal of D-9 never sees a graph anchor in a Source just collapsed) | Brief § 2; one rule for the two ways to close | Leaving the selection on a row that is gone |
| D-16 | The menu is `PVListBody`'s `menu` slot, sections of `PVActionMenuItem`, built by `SourcesRowMenu.items(for row: SourcesOutlineRow, graphs: QueryRead<[CatalogEvidenceGraph]>, actions: SourcesRowMenu.Actions) -> [[PVActionMenuItem]]` *(new, in `SourcesOutline.swift`)*; the page passes `session.evidenceGraphsRead(sourceID:)` of the row's Source. `.source` → section 1: `menuOpen`, `copySourceEntry`; then, when `.collapsed` and the graphs are loaded, section 2: `menuOpenGraph(name)` per graph in read order, `isEnabled: graph.hasArtifact`. `.graph` → `menuOpen`, `isEnabled: graph.hasArtifact`. `.pendingGraph` → none. Identifiers `sources.row.<sourceID>.menu.open`, `.copy`, `.openGraph.<graphRef>`. `SourcesRowMenu.Actions` *(new)* holds `open: (SourcesOutlineRow) -> Void`, `openGraph: (CatalogEvidenceGraph, CatalogSource) -> Void`, `copy: (CatalogSource) -> Void`. Every entry selects its row first (`noteListAnchor(row id)`; Copy too); `openGraph` also expands the Source and selects the graph's id; then Open goes to D-10's location and Copy calls `model.openCopy(source)` | SO-9; the brief's inventory names the platform's own menu on a native list, so the row stays one native element. One item type for every action menu (review M-1); pure entries are tested without a menu | `.pvRightClickMenu` on each row (a custom popup over the table's own right-click); a menu enum of its own |
| D-17 | The closed summary is `SourcesGraphSummary.text(_ counts: [SourcesGraphCounts]) -> String` *(new, pure, in `SourcesOutline.swift`)*: N = the count. Any count `.loading` or `.unavailable` → `N graphs`. Else every status the same → `N graphs · <Status label>`; else any In progress → `N graphs · K in progress`; else → `N graphs · K promoted`. `N graphs` is a plural (`1 graph`). Drawn only on a `.collapsed` Source whose graphs are loaded; left out (with its dot) while they are not | SO-4's examples, extended to the mix it does not name (§12 Q-5 asks the user) | Listing every status (`3 in progress, 2 promoted, 3 not started`: too long to never truncate) |
| D-18 | Failures: the graph list failed and no status filter → a danger `PVCallout` with `L10n.Errors.message(for:)` above the list, `.padding(.horizontal, gutter)`, `.padding(.vertical, PVSpacing.space6)`, at most `measureForm` wide, leading, identifier `sources.graphsError`, then the list (no triangles, D-4); with a status filter, today's `statusCountsError` Callout alone, now through `PVListPage.failureArea(_:gutter:)` (identifier `sources.statusError` kept). The counts failed and no filter → per row (D-12, AC-6.4). The Sources list failed with nothing to show → `PVListPage.failureArea` (identifier `sources.loadError` kept) | SO-11 and brief § 2 Failures | A per-row error (today's) |
| D-19 | Empty and no-match: the empty catalog is `PVEmptyState(icon: .scrollText, …)` centered in the list area (it was top-aligned); the no-match state keeps its `PVEmptyState(compact: true)` and Clear filters, centered in the list area. Identifiers `sources.empty`, `sources.filterEmpty` kept | SO-11 ("centered, as Persons"; "centered under the toolbar") | — |
| D-20 | The page fills the pane at every width: `pvListBand` leaves the Sources list; the toolbar's horizontal padding is the frame's gutter (32 / 56 pt); `PVWidthBreakpoints` and `SourcesListColumns` leave the page. SO-W1 per §12 Q-3; this draft is (a): the Wide row is the Regular row with a wider title column | SO-1, SO-W1; the rule bend of § 9 rule 3 (below) | — |
| D-21 | Row heights: the Source row 66 pt (`PVListRow` at 44 + 2 × 11); the graph row `SourcesGraphRow.height`; the list's `minimumRowHeight` is `SourcesGraphRow.height`, so a wheel step scrolls one graph row. If STEP-8 finds rows of two heights drawn at the wrong height or overlapping, every row takes 66 pt (brief § 2.1 fallback) and the graph row centers its content | Brief § 2.1 Rows* and its fallback, decided here so the implementer does not stop | — |
| D-22 | Separators per §12 Q-2. This draft: one rule for every row (the `ForEach`'s `listRowSeparator(.visible)`), the Source row's guide at its cover, the graph row's at its glyph | Brief § 2.1 Separators* fallback | — |
| D-23 | `PVPublishedDate` loses `Style` and `style:`: it always reads the bare date (or `Undated`, for the Person page's Sources section), and its inks go through `PVColor.onSelection` (unchanged outside a selected row). `L10n.PublishedDate.label` and `.none` go with `.labeled`, and their catalog entries | `.labeled`'s callers all leave; the brief: "takes the on-selection ink, can be left out when missing, and reads bare" | Keeping a style with one case |
| D-24 | `SourcesGraphCountLine.Style.button` is renamed `.row`; the count line's text ink goes through `PVColor.onSelection`; the danger mark keeps `PVColor.danger` | Brief inventory | — |
| D-26 | The list's updated column moves into the recipe that owns it: `PVLastUpdated.column<Item>(_ updatedAt: @escaping (Item) -> String) -> PVListDetailColumn<Item>` *(new)* = `PVListDetailColumn(width: columnWidth) { detail(updatedAt($0), in: .current) }`. `ConclusionListRow.updatedColumn(_:)` goes; `ConclusionListPage` calls `PVLastUpdated.column { Kind.updatedAt($0) }` | One definition of the column (review M-4) | A second inline copy |
| D-27 | The `EvidenceStatus` badge extension moves to `macos/App/Features/Sources/SourcesEvidenceStatus+Badge.swift` *(new)*, beside no view | One place for how a status is drawn (review M-8) | The rows file |
| D-25 | VoiceOver: a Source row is one element labelled `PVLastUpdated.label(SourceDateText.spokenRow(title:type:ref:date:) + the summary or "Needs an artifact", updatedAt:, in: .current)`, with `.pvExpandedState(isExpanded)` and one `accessibilityAction(named:)` when it has a triangle: `L10n.Sources.showGraphs` / `hideGraphs` *(new)*. A graph row is one element labelled `L10n.Sources.graphRowLabel(name:counts:status:)` *(new; the button label without "Open graph")*, with `graphNeedsArtifactTooltip` as its hint when it cannot open; a pending row `L10n.Sources.graphsLoading` (kept). Identifiers: `sources.row.<sourceID>`, `sources.row.<sourceID>.graph.<graphRef>`, `sources.row.<sourceID>.graphsPending`, `sources.row.<sourceID>.disclosure` | The row is the element (S16-67 D-13); the triangle, outside the key loop, needs an action | — |

**Rules this plan bends.**

- `docs/macos-client-patterns.md` § 9 rule 3 names the Sources list as its example of a list centered at `widthListWideMax`. The Sources list now fills the pane, as the Conclusion lists do → the graphs sit under the title, so no band lies empty between them (brief **Rules this brief bends**) → the user's answer: scope entry "Decided (user, 2026-11-23)" and the working rule "(Batch 6) The Conclusion lists are native lists" ("S16-66 moves the Sources list onto the native list too"); the board's SO-W1 confirms it at Wide (§12 Q-3) → STEP-10 updates § 9.
- The kit README's ContextMenu row: "a right-click menu that opens at the pointer is one `.pvRightClickMenu`". On a native list the list's own menu presents the same `PVActionMenuItem` lists (D-16) → brief S16-D12 inventory, "Right-click menu | Platform | the list's own context menu" (user, 2026-11-23) → STEP-10 adds the exception to the row and to [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md) if it names the rule.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `PVListBody` *(new)* | component | `PVList` | Extends it: `PVList.body` moves into it unchanged but for the row builder, the menu slot and horizontal-only insets; `PVList` is its first caller (D-1) |
| `PVListBody.leadingInset(horizontalInset:leadingHang:)` *(new)* | func | `PVList.rowInset` (private) | The same arithmetic, moved and given the hang |
| `PVListRow` leading slot, `PVListRow.hang(leadingWidth:)` *(new)* | component | `PVListRow` (private) | Extended, made internal (D-2) |
| `PVListPage` *(new)*, `loadingArea`, `failureArea` | recipe | `ConclusionListFrame`, `ConclusionListPage.loadingArea` / `failureArea` | Moved and given a toolbar slot (D-3) |
| `SourcesOutline`, `SourcesOutlineRow`, `SourcesOutlineKeyAction`, `SourcesRowMenu` (builds `PVActionMenuItem` sections), `SourcesGraphSummary` *(new)* in `SourcesOutline.swift`; `SourcesListNavigation.location(for:)` *(new)* | types, pure funcs | `SourcesListNavigation` (pure helpers), `ConclusionListPresentation` | Different jobs; searched `rg -n "enum Sources" macos/App/Features/Sources`: none flattens or summarizes graphs |
| `DerivedValueID.sourcesOutline` *(new)* | key | `.visibleSources` | A second derived value on top of it (D-5) |
| `SourcesModel.outline`, `isAwaitingGraphList` *(new)* | func | `visibleSources`, `isAwaitingFilterData` | Same model, same pattern |
| `WorkspaceSession.expandedSourceIDs`, `setSourcesExpanded(_:_:)` *(new)* | state | `graphCameras` | The precedent; observed (D-7) |
| `SourcesSourceRow`, `SourcesSecondaryLine`, `SourcesGraphRow`, the triangle view *(new)* in `SourcesOutlineRows.swift` | views | `SourcesListRow`, `SourcesLinkLabel`, `SourcesGraphButton` | Replace them (Deletes) |
| `SourcesGraphRow.height`, `statusSlotWidth` (moved) | constants | `SourcesGraphButton.height`, `.statusSlotWidth` | Moved |
| L10n `Sources.graphSummaryCount`, `graphSummary`, `graphSummaryInProgress`, `graphSummaryPromoted`, `showGraphs`, `hideGraphs`, `graphRowLabel`, `menuOpen`, `menuOpenGraph` *(new)* (§6 Strings) | keys | `graphButtonLabel`, `openEvidenceGraphLabel`, `graphSubjectCount` (plural) | New copy; `graphRowLabel` replaces `graphButtonLabel` |
| `ListSelectionAnchorModifier.reveal`, `ListAnchor.settle` *(new)* | func | `ListAnchor.resolved`, `clearIfGone()` | Extends the one restore path (D-9) |
| `PVExpandedState.outlineChevron(isExpanded:)`, `PVListRow.titleLeading` *(new)* | func | `PVExpandedState.chevron(isExpanded:)`, `PVListRow.hang` | Beside them (review M-3, M-6) |
| `PVLastUpdated.column` *(new)*, `SourcesEvidenceStatus+Badge.swift` *(new)* | func, file | `ConclusionListRow.updatedColumn`, the extension in `SourcesListRow.swift` | Replace them (D-26, D-27) |
| `SourcesOutlineTests.swift` *(new)* | tests | `SourcesListNavigationTests.swift` | One file per pure type, as there |

**Builds on.** S16-67's native list, `listAnchor`, `ListSelectionAnchorModifier`, `ListAnchor.resolved`, `PVListPageHeader`, `.pvListPageMessage`, `PVWidthClass.fullPaneGutter`; the session's derived values; `pvScrollsRowIntoView(whenRequested:)`; `SourcesListNavigation`; `SourcesGraphCounts`; `PVLastUpdated`; `pvExpandedState`.
**Deletes.** `SourcesListRow.swift` (`SourcesListRow`, `SourcesLinkLabel`, `SourcesListRowButtonStyle`, `SourcesListRowButtonBody`; the `EvidenceStatus` badge extension moves to `SourcesOutlineRows.swift`); `SourcesGraphButton.swift` (`SourcesGraphButton`, `Kind`, `Open`, `SourcesGraphButtonLook`, `SourcesGraphButtonFrame`, `SourcesGraphButtonStyle`, `SourcesGraphButtonBody`); `SourcesListColumns.swift` (`SourcesListColumns` and the four `sources…Cell` modifiers); in `SourcesListView.swift` `captionBand(_:)`, `caption(_:)`, `listBody(rows:)`'s `ScrollView`, the `ListScrollAnchorModifier` use, `.pvListBand`; `ConclusionListFrame`, `ConclusionListPage.loadingArea` and `failureArea`; `PVList.rowInset`, `platformCellInset` (moved); `PVListDetailCell.iconSize` (its last non-default caller goes); `PVPublishedDate.Style`; L10n `Sources.columnSource`, `columnType`, `columnPublished`, `columnEvidenceGraph`, `openSourcePage`, `graphsFailedTitle`, `graphsFailedDetail`, `noGraphYet`, `needsArtifactTooltip`, `graphBlockLabel`, `graphButtonLabel` (both keys), `graphButtonHelp`, `listAccessibilityLabel`, `PublishedDate.label`, `PublishedDate.none` and their `Localizable.xcstrings` entries; `ConclusionListRow.updatedColumn` (D-26); the tests `listColumnsMatchBoard`, `columnsPlaceTheDateByWidth` and their private helper `SourcesModelTests.columns(at:_:)`, `graphButtonCopyMatchesBoard` (replaced by T-16). `pvListBand` keeps its Source types caller.
**Next adds.** A later list of mixed rows uses `PVListBody` with its own row builder. `PVTable` on the native list (kit-layering idea) reuses `PVListBody`. The Source types list can move off `ListScrollAnchorModifier` onto `listAnchor` the same way.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A history entry whose anchor is a graph id | `ListSelectionAnchorModifier`, D-9 | Not drawn, so the modifier calls `reveal`; a graph in a collapsed visible Source expands it (AC-7.4); a deleted graph or a hidden Source clears it once settled (AC-7.5, AC-7.6) |
| A history entry from before this PR (a top-row Source id) | the same | Resolves as a selected Source (AC-7.7) |
| Expanded state for a Source deleted, filtered out, or without an Artifact now | `SourcesOutline.rows` | Ignored: only visible Sources with graphs read the set; the id stays, harmless (T-3) |
| A menu Open of a graph in a collapsed Source | `navigation`, D-16 | Expands the Source, selects, then goes; Back finds the row listed (AC-5.5) |
| Return on a pending or Artifact-less graph row | `onActivate` | D-10 returns nil: nothing happens (AC-3.5, AC-6.5) |
| The graph list re-reads (a write) while a graph is selected | the modifier | `isSettled` false during the read; the anchor resolves on settle |

### Scale

At the Batch 2 Scale (3,000 Sources, 10,000 Evidence graphs): `SourcesOutline.rows` is O(visible Sources + graphs of expanded Sources), `ownerByGraphID` O(visible Sources' graphs) ≤ 10,000 entries, both built once per change of `visibleSources`, the graph list or the expanded set (D-5), not per body pass; the modifier's `rowIDs` are the drawn rows only. ⌥-click opening every Source lists up to 13,000 rows; `NSTableView` builds rows on screen only, and the row modifiers sit on the `ForEach` (S16-67 Landed). `ListAnchor.resolved` is one O(n) search and `sourceToReveal` one dictionary read per anchor or outline change. A graph row reads its counts from the session's progress map per draw (a dictionary read). Budget: on the user's largest catalog, and in T-10 at 3,000 / 10,000, ⌥-click open-all and close-all draw without a visible stall, and the outline builds once per toggle (`session.derivedBuildCount(.sourcesOutline)`).

### Edges

- **Assumptions.** Source ids and graph ids are distinct (UUIDv7 of two tables); a pending row's id adds `#graphs`, which no UUID contains. The graph list's order within a Source is the list's (by name), as `evidenceGraphsRead` returns it. A loaded graph list with no entry for a Source means "not refreshed yet" (`evidenceGraphsRead`'s rule), so the row is pending, not empty: a Source never has zero graphs (`core/database/evidencegraphs/evidencegraphs.go` `ErrLastGraph`, the delete gate `deleteimpact.GateLastGraph`).
- **Neighbors.** A Source with one graph gets a triangle and closes like one with ten (AC-2.1). A Source with an Artifact whose graph read failed: no triangle (D-4). The Persons, Events and Places lists keep 66 pt rows, insets and wheel step (T-1, T-2). The Source types list keeps `pvListBand` and `ListScrollAnchorModifier`.
- **Removed inputs.** A graph deleted while selected: cleared on settle (AC-7.5). A Source losing its last Artifact: its row loses the triangle and its graph rows; a selected graph row of it clears (not reachable). A filter hiding the selected Source's row: the settings change clears the selection first (D-8).
- **Real data.** None — no table-driven rule.
- **Untrusted size.** None — rows come from the app's own catalog reads.

### Schema

None — no catalog change.

### Go core

None — Go already serves the three reads.

### FFI

None — no wire change.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Native list | `PVListBody` *(new)*, `PVList` on it | `macos/App/DesignSystem/Components/List/PVListBody.swift`, `PVList.swift` | D-1, D-2 |
| Page frame | `PVListPage` *(new)* | `macos/App/DesignSystem/Recipes/ListPage/PVListPage.swift` | D-3 |
| List page header | `PVListPageHeader` | as today | description and Add as today |
| Toolbar | snowflake in `SourcesListView` | as today | gutter from the frame (D-20) |
| Cover | `CachedThumbnail` | as today | 44 pt (was 40), type icon fallback |
| Published date | `PVPublishedDate` | as today | D-23 |
| Updated column | `PVLastUpdated.detail`, `PVListDetailCell` | as today | as Persons |
| Source row | `PVListRow` + `SourcesSecondaryLine` | `SourcesOutlineRows.swift` *(new)* | D-11 |
| Graph row | `SourcesGraphRow` | `SourcesOutlineRows.swift` | D-12 |
| Graph counts | `SourcesGraphCountLine(.row)` | as today | D-24 |
| Status badge | `PVBadge` via `EvidenceStatus.badge` | moves to `SourcesOutlineRows.swift` | keeps its colors when selected |
| Disclosure triangle | `PVIcon` chevron in a plain `Button`, `pvExpandedState` on the row | `SourcesOutlineRows.swift` | D-13, D-25 |
| Right-click menu | the list's own context menu | `PVListBody` menu slot | D-16 |
| Loading rows | `PVListSkeleton` via `PVListPage.loadingArea` | as today | Source rows only |
| Empty, no match | `PVEmptyState` | as today | D-19 |
| Failure | `PVCallout(.danger)` + `.pvListPageMessage` | as today | D-18 |

Frames in words (the board, once drawn; update this paragraph when it is agreed): **S1a/S1b** the page scrolled mid-list at Regular and Wide, mostly one-graph Sources, one with 8 graphs and one with none; every Source closed, then the 8-graph one and a one-graph one open; the graph rows indented under the title, badges in one trailing column. **S2** crops: open, closed, no Artifact; a Source and a graph selected, focused and unfocused, light and dark; a graph with no Artifact faint; a 90-character title truncating. **S3** the Source menu (open, and closed with eight graphs) and the graph menu. **S4** loading skeletons; a graph row's counts loading, failed, and a pending graph row. **S5** the graph list failure with and without a status filter; the whole-list failure; empty; no match. **S6** the Regular pane at 800 pt: nothing overlaps.

States: loading (AC-6.1, AC-6.2), late counts (AC-6.3 – AC-6.5), failures (AC-6.4, AC-6.6 – AC-6.8), empty (AC-6.9), no match (AC-6.10), 3,000 Sources and open-all (Scale). Accessibility: D-25; keyboard: US-4.

### Strings

L10n keys *(new)*, in `L10n.Sources`:

- `graphSummaryCount(_ n: Int)` = `sources.list.graphSummaryCount`, plural: "%lld graphs" (one: "%lld graph").
- `graphSummary(count: String, detail: String)` = `sources.list.graphSummary`: "%1$@ · %2$@".
- `graphSummaryInProgress(_ n: Int)` = `sources.list.graphSummaryInProgress`: "%lld in progress".
- `graphSummaryPromoted(_ n: Int)` = `sources.list.graphSummaryPromoted`: "%lld promoted".
- `showGraphs` = `sources.list.showGraphs`: "Show evidence graphs"; `hideGraphs` = `sources.list.hideGraphs`: "Hide evidence graphs".
- `graphRowLabel(name:counts:status:)` = `sources.list.graphRowLabel` "%1$@, %2$@, %3$@" and `sources.list.graphRowLabelNoStatus` "%1$@, %2$@".
- `menuOpen` = `sources.list.menu.open`: "Open"; `menuOpenGraph(_ name: String)` = `sources.list.menu.openGraph`: "Open %@".

The status words in a summary reuse `EvidenceStatus.label` ("Not started", "In progress", "Promoted"). The Copy entry reuses `L10n.Sources.copySourceEntry`; its comment gains "and the Sources list's row menu". `needsArtifact`'s comment becomes "End of a Sources list row's secondary line for a Source with no Artifact". Removed: the keys under **Deletes**.

## 7. Steps

**STEP-1 — The kit's native list body**
Files: `macos/App/DesignSystem/Components/List/PVListBody.swift` *(new)*, `macos/App/DesignSystem/Components/List/PVList.swift`, `macos/App/Features/Workspace/WorkspaceNavigation.swift`, `macos/App/DesignSystem/Components/Disclosure/PVDisclosureButton.swift`, `macos/App/DesignSystem/Recipes/LastUpdated/PVLastUpdated.swift`, `macos/App/Features/Conclusions/ConclusionListRow.swift`, `macos/App/Features/Conclusions/ConclusionListPage.swift`, `macos/ProvenenciaTests/PVListTests.swift`, `PVLastUpdatedTests.swift`, `WorkspaceNavigationTests.swift`. Skills: `add-ui-component`, `add-workspace-location`.
Do: D-1 and D-2. `PVList.body` becomes `PVListBody(items:, selection:, minimumRowHeight: thumbnailSize + 2 * density.vertical, horizontalInset:, label:, onActivate:) { PVListRow(…, leadingWidth: 0) }`. Move `platformCellInset` and the inset arithmetic into `PVListBody.leadingInset`. Delete `PVListDetailCell.iconSize`'s parameter only in STEP-5, when its caller goes. Add `ListAnchor.settle` and `reveal` to `ListSelectionAnchorModifier` (D-9; the Conclusion lists pass none), `PVExpandedState.outlineChevron`, `PVLastUpdated.column` (D-26). Add T-2, T-6's navigation half, T-18.
Check: `PVListTests`, `PVLastUpdatedTests`, `WorkspaceNavigationTests` pass, `aWheelStepScrollsOneRow` still reads 66; in the app the Persons list looks and behaves as at the base (a row 66 pt, the thumbnail on the 32 pt gutter, separators, double-click, Return, Home/End).

**STEP-2 — The kit's list page frame**
Files: `macos/App/DesignSystem/Recipes/ListPage/PVListPage.swift` *(new)*, `macos/App/Features/Conclusions/ConclusionListPage.swift`, `macos/ProvenenciaTests/PersonsListTests.swift`. Skill: `add-ui-component`.
Do: D-3. `ConclusionListPage` and `ConclusionListBody` call `PVListPage` with no toolbar; its previews draw `PVListPage`. `loadingAreaFitsTheListArea` calls `PVListPage.loadingArea(gutter:)`.
Check: `rg -n "ConclusionListFrame" macos` prints nothing; `PersonsListTests` pass; Persons, Events and Places look as at the base.

**STEP-3 — The outline, the summary and the session's expanded set**
Files: `macos/App/Features/Sources/SourcesOutline.swift` *(new)*, `macos/App/Features/Sources/SourcesModel.swift`, `macos/App/Features/Workspace/Session/WorkspaceSession.swift`, `macos/App/Features/Workspace/Session/WorkspaceSession+Sources.swift`, `macos/App/Features/Workspace/Session/WorkspaceSession+Derived.swift`, `macos/App/Features/Sources/SourcesListNavigation.swift`, `macos/App/Features/Sources/SourcesEvidenceStatus+Badge.swift` *(new)*, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `macos/ProvenenciaTests/SourcesOutlineTests.swift` *(new)*, `macos/ProvenenciaTests/SourcesModelTests.swift`, `SourcesListNavigationTests.swift`. Skills: `add-workspace-place`, `add-localized-string`, `add-swift-test`.
Do: D-4, D-5, D-6, D-7, D-9's and D-15's pure functions, D-10 (in `SourcesListNavigation.swift`), D-14's `keyAction`, D-16's `items`, D-17 with its keys, D-27. T-3 – T-16 (T-6's outline half).
Check: `SourcesOutlineTests`, `SourcesModelTests` and `SourcesListNavigationTests` pass; `python3 scripts/check-localizable-xcstrings.py` passes.

**STEP-4 — The Source row and the graph row**
Files: `macos/App/Features/Sources/SourcesOutlineRows.swift` *(new)*, `macos/App/Features/Sources/SourcesGraphCountLine.swift`, `macos/App/DesignSystem/Recipes/PublishedDate/PVPublishedDate.swift`, `macos/App/Features/Conclusions/PersonSourcesSection.swift` (drops `style: .bare`), `L10n.swift`, `Localizable.xcstrings`. Skills: `add-ui-component`, `add-localized-string`.
Do: D-11, D-12, D-13's view (its action wired in STEP-6), D-23, D-24, D-25's labels; each row view applies its own accessibility element, label, identifier and hint. `#Preview`s: a closed and an open Source with 8 graphs, a Source with no Artifact, the three graph-row count states and a pending row, each at 1102 pt, and one selected on an accent background with `\.backgroundProminence` `.increased`.
Check: builds; the previews match frames S1a, S2 and S4 in §6's words; `rg -n "style: \.(labeled|bare)" macos/App --glob '*.swift'` and `rg -n "style: \.button" macos/App/Features/Sources` print nothing.

**STEP-5 — The page on the native list**
Files: `macos/App/Features/Sources/SourcesListView.swift`; delete `SourcesListRow.swift`, `SourcesGraphButton.swift`, `SourcesListColumns.swift`; `PVList.swift` (`PVListDetailCell.iconSize`); `L10n.swift`, `Localizable.xcstrings` (Deletes); `SourcesModelTests.swift`. Skills: `add-workspace-location`, `add-localized-string`.
Do: `SourcesListContent` draws `PVListPage(title: L10n.Workspace.sourcesTitle, description: L10n.Sources.description, countLine:, add:, identifierRoot: "sources", toolbar: { gutter in toolbar(gutter) }, content:)`, the toolbar only in the states that draw it today (D-6). The content: D-6's loading, D-18's failures, D-19's empty and no match, else the graph Callout (D-18) over `PVListBody(items: outline.rows, selection: (D-8), minimumRowHeight: SourcesGraphRow.height, horizontalInset: gutter, leadingHang: PVListRow.hang(leadingWidth: 16), label: L10n.Workspace.sourcesTitle, onActivate: (D-10), menu: (STEP-7), row: (STEP-4))` with `itemAccessibilityIdentifier`s of D-25; the modifier and reveal of D-8, D-9; delete `.pvListBand`, `ListScrollAnchorModifier`, the caption band and the deleted files' keys; T-16.
Check: `rg -n "SourcesListRow|SourcesGraphButton|SourcesListColumns|sourcesGraphCell|columnEvidenceGraph|sources\.captionBand" macos` prints nothing (the docs sweep is STEP-10's and the DoD's); `SourcesModelTests`, `SourcesListNavigationTests`, `WorkspaceNavigationTests` pass; in the app AC-1.1 – AC-1.7, US-3, AC-4.1 – AC-4.4, US-6 and US-7 hold.

**STEP-6 — Open and close by triangle and keys**
Files: `SourcesOutlineRows.swift`, `SourcesListView.swift`.
Do: D-13's action, D-14's handler, D-15 on both, in D-15's order (select, then collapse). The Source row's `accessibilityAction(named:)` calls the same toggle.
Check: in the app AC-2.1 – AC-2.8 and AC-4.5 – AC-4.8 hold, or STEP-8 records which do not (D-14, D-13's fallback).

**STEP-7 — The right-click menus**
Files: `SourcesListView.swift` (the `menu:` builder). 
Do: D-16.
Check: in the app AC-5.1 – AC-5.7 hold.

**STEP-8 — Prove the brief's unproven rows**
Do: run §10 steps 7–10 and write nine lines in the PR description and this plan's Landed note, `<behavior>: works | missing | differs — <what happened>`: (1) two row heights (each drawn at its height, no overlap); (2) the wheel step with two heights; (3) the triangle's click (selects or not); (4) →; (5) ←; (6) the separator branch shipped (Q-2); (7) VoiceOver on a Source row (its expanded state and Show/Hide action); (8) VoiceOver on a graph row; (9) Return on a graph row. A missing behavior takes its fallback (D-13, D-14, D-21, D-22) and is recorded, not worked around.
Check: nine lines written.

**STEP-9 — Version**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj` (`MARKETING_VERSION`).
Do: the next minor after `VERSION` on `main` when the branch starts (0.36.0 → 0.37.0 at the planning base), in all three together; a different number goes in the Landed note.
Check: the old version string no longer appears in `VERSION`, `core/version.go` or `macos/Provenencia.xcodeproj/project.pbxproj`.

**STEP-10 — Docs**
Files: `macos/App/DesignSystem/README.md` (the List row: `PVListBody` under `PVList`, rows own their height, the leading slot and hang, the menu slot; a ListPage row for `PVListPage`; the ContextMenu row's native-list exception; the PublishedDate recipe row if it names `.labeled`; the WidthClass row's "the Sources list's compact rows" goes; the PageColumns row: `pvListBand` serves the Source types list), `docs/macos-client-patterns.md` (§ 9 rule 3's paragraph: the Source types list is the example, the Sources list fills the pane as the Conclusion lists do; the "List → detail page" row; the `Features/Sources/` line if it names the rows), `docs/ideas/wide-layout.md` (the Sources list line: now fills the pane, S16-66), `docs/ideas/kit-layering.md` ("Hovering focus rings built by hand": `SourcesGraphButtonBody` leaves the list of cases, `CircularLinkNodeStyle` remains; an entry for → / ← if STEP-8 found them missing), `.agents/skills/add-workspace-location/SKILL.md` (the anchor line: Sources on `ListSelectionAnchorModifier` with a graph reveal; Source types alone on `ListScrollAnchorModifier`; the pattern line's `SourcesListView`), `.agents/skills/add-ui-component/SKILL.md` (if it states the `.pvRightClickMenu` rule), doc comments naming the Sources row (`PVListDetailCell`, `PVPublishedDate`, `PVLastUpdated` line 4 (its "it draws the cell on the row's second line" → "the Sources list's updated column"), `SourcesGraphCountLine`, `SourcesGraphCounts`, `SourcesListNavigation`, `L10n.Sources.NotStartedReading`'s comment ("graph button" → "graph row"), the `L10n.PublishedDate` comments (the labeled form goes), `PVStroke`'s README line on the blocked graph buttons), `docs/deployment-plan/spike-16/deployment-plan.md` (bar 38 under Batch 6's bars: "**The Sources list is a native outline.** Every Source and Evidence graph is reached, selected and opened by mouse and keyboard from the list: a click selects, a double-click or Return opens a Source's page or a graph's canvas, the triangle or → and ← open and close a Source, and Back returns to the row opened, selected and in view with its Source open. (S16-D12.)"; the S16-66 row's status), `completed.md`, this plan, `design/` (S16-D12 → `design/archive/`, `design/README.md`).
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-66-sources-outline-list.md` reports no errors; `scripts/check-guidance-names.py` passes; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period ("Open a Source's Evidence graphs as rows under it in the Sources list."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `PVListTests.swift` `aWheelStepScrollsOneRow` (unchanged) | `PVList` of 5 rows → `verticalLineScroll == 66` | D-1, D-2 |
| T-2 | Swift | `PVListTests.swift` `leadingInsetLeavesTheHangAndTheCellInset` *(new)* | `PVListBody.leadingInset(horizontalInset: 32, leadingHang: 0)` → 24; `(32, 20)` → 4; `(56, 20)` → 28; `(8, 20)` → 0; `PVListRow.hang(leadingWidth: 16)` → 20, `(0)` → 0 | D-1, D-2, AC-1.3 |
| T-3 | Swift | `SourcesOutlineTests.swift` `rowsFollowTheExpandedSet` *(new)* | `SourcesOutline(sources: [s1, s2, s3], graphs: { ["s1": .loaded([g1a, g1b]), "s2": .loaded([g2])][$0] ?? .loading }, expanded: [s1, s9])`, s1 (graphs g1a, g1b), s2 (g2), s3 (no Artifact) → ids `[s1, g1a, g1b, s2, s3]`; disclosures s1 `.expanded`, s2 `.collapsed`, s3 `.none` | D-4, AC-2.1, AC-2.2, AC-1.6 |
| T-4 | Swift | `SourcesOutlineTests.swift` `aFailedGraphListDropsTheTriangles` *(new)* | the same with every read `.failed` → `[s1, s2, s3]`, all `.none` | D-4, AC-6.6 |
| T-5 | Swift | `SourcesOutlineTests.swift` `aSourceNotInTheGraphListYetIsPending` *(new)* | s4 read `.loading`, expanded {s4} → `[s4, "s4#graphs"]`, s4 `.expanded`; collapsed → `[s4]`, `.collapsed` | D-4, AC-6.5 |
| T-6 | Swift | `WorkspaceNavigationTests.swift` `aRevealKeepsAnAnchorItDraws` *(new)*; `SourcesOutlineTests.swift` `ownersCoverCollapsedGraphs` *(new)* | `ListSelectionAnchorModifier` decision as a pure `ListAnchor.settle(_ anchor:, in: rowIDs, reveal:) -> String?` *(new, the modifier's one rule)*: anchor `g1a` not in rows, reveal true → `g1a` kept; reveal false → nil; anchor in rows → kept, reveal not called. Outline of T-3 with expanded {} → `ownerByGraphID` = {g1a: s1, g1b: s1, g2: s2} | D-5, D-8, D-9 |
| T-7 | Swift | `SourcesOutlineTests.swift` `backRevealsAGraphsClosedSource` *(new)* | `sourceToReveal("g1a")` with s1 collapsed → s1; s1 expanded → nil; `"s2"` → nil; `"g9"` (a graph of a hidden s9) → nil | D-9, AC-7.4, AC-7.6 |
| T-8 | Swift | `SourcesOutlineTests.swift` `collapsingASourceSelectsItInsteadOfItsGraph` *(new)* | `selectionAfterCollapsing([s1], selection:)`: g1a → s1; `"s1#graphs"` → s1; g2 → g2; s1 → s1; nil → nil | D-15, AC-2.5, AC-4.7 |
| T-9 | Swift | `SourcesOutlineTests.swift` `arrowKeysExpandCollapseAndClimb` *(new)* | → on `.collapsed` s1 → `.expand(s1)`; ← on `.expanded` s1 → `.collapse(s1)`; ← on g1a → `.select(s1)`; → on `.expanded`, on g1a, ← on `.collapsed`, either on `.none`, any key with no selection, `.downArrow` → `.ignore` | D-14, AC-4.5 – AC-4.8 |
| T-10 | Swift | `SourcesOutlineTests.swift` `outlineBuildsOncePerChangeAtScale` *(new)* | `FakeStore` with 3,000 Sources and 10,000 graphs: read `model.outline` twice → one build; `setSourcesExpanded(all, true)` → one more build, 13,000 rows; reading a graph's progress changes no build count | D-5, Scale |
| T-11 | Swift | `SourcesOutlineTests.swift` `expandedSourcesOutliveTheModel` *(new)* | `session.setSourcesExpanded(["s1"], true)`; a new `SourcesModel` on the same session → `s1` expanded; a new session → empty; the settings file holds no Source ids | D-7, AC-2.6, AC-2.8 |
| T-12 | Swift | `SourcesOutlineTests.swift` `summaryNamesTheGraphsStatuses` *(new)* | one `.counts(subjects: 3, observations: 5, filed: 0)` → `1 graph · In progress`; 8 with 3 in progress, 5 not started → `8 graphs · 3 in progress`; 8 `.notStarted` → `8 graphs · Not started`; 5 promoted + 3 not started → `8 graphs · 5 promoted`; any `.loading` or `.unavailable` → `8 graphs` | D-17, AC-2.10 |
| T-13 | Swift | `SourcesOutlineTests.swift` `menusOfferWhatARowCanDo` *(new)* | compared as `(L10n.string(title), isEnabled)` per section: expanded s1 → `[[(Open, true), (Copy…, true)]]`; collapsed s1 with g1a (Artifact), g1b (none), graphs loaded → `[[(Open, true), (Copy…, true)], [(Open Default, true), (Open Jones household, false)]]`; the same with graphs `.loading` or `.failed` → the first section only; g1b → `[[(Open, false)]]`; pending → `[]`; calling g1a's entry calls `actions.openGraph` with g1a and s1 | D-16, AC-5.1 – AC-5.4 |
| T-14 | Swift | `SourcesListNavigationTests.swift` `aRowOpensItsPlaceOrNothing` *(new)* | s1 → `.sourcePage(s1)`; g1a → its canvas; g1b → nil; `"s1#graphs"` → nil | D-10, AC-3.3 – AC-3.5 |
| T-15 | Swift | `SourcesModelTests.swift` `rowsWaitForTheGraphList` *(new)* | graph list loading → `isAwaitingGraphList` true; loaded → false; failed → false | D-6, AC-6.1 |
| T-16 | Swift | `SourcesModelTests.swift` `graphRowCopyMatchesBoard` *(new, replaces `graphButtonCopyMatchesBoard`)* | `graphRowLabel(name: "Jones household", counts: "12 subjects, 40 observations", status: "In progress")` → `Jones household, 12 subjects, 40 observations, In progress`; no status → `Jones household, counts loading`; `menuOpenGraph("Default")` → `Open Default`; `showGraphs`, `hideGraphs`, `graphNeedsArtifactToOpen`, `needsArtifact` read as §6 Strings | D-16, D-25 |
| T-17 | Swift | `PersonsListTests.swift` `loadingAreaFitsTheListArea` (calls `PVListPage.loadingArea(gutter:detailWidth:)`) | unchanged → unchanged | D-3, AC-6.1 |
| T-18 | Swift | `PVListTests.swift` `outlineChevronPointsRightThenDown` *(new)*; `PVLastUpdatedTests.swift` `listColumnIsTheRecipes` *(new)* | `PVExpandedState.outlineChevron(isExpanded: false)` → `.chevronForward`, `true` → `.chevronDown`; `PVLastUpdated.column { $0 }` width 136 and its content for `""` is the faint `—` detail | D-13, D-26 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `PVListTests`, `PersonsListTests`, `PlacesListTests`, `SourcesModelTests` (the status filter and failure tests), `SourcesListNavigationTests`, `WorkspaceNavigationTests`, `WorkspaceSessionDerivedTests` (a new derived id).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (the Deletes keys gone from both)
- [ ] Sweep: `SourcesListRow`, `SourcesLinkLabel`, `SourcesListRowButtonStyle`, `SourcesGraphButton`, `ConclusionListRow.updatedColumn`, `openSourceIDs`, `SourcesListColumns`, `sourcesSourceCell`, `sourcesTypeCell`, `sourcesPublishedCell`, `sourcesGraphCell`, `sources.captionBand`, `ConclusionListFrame` (outside `docs/deployment-plan/`, whose plans and logs keep history), `PVPublishedDate.Style`, `style: .labeled`, `graphButtonLabel`, `graphBlockLabel`, `columnEvidenceGraph` `rg`'d across `.agents/`, `.cursor/rules/`, `docs/*.md`, `docs/ideas/`, `macos/App/DesignSystem/README.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (§ 9 rule 3's example; the kit README's ContextMenu row)
- [ ] UI matches the brief inventory; no new kit primitive beyond the split `PVListBody` and the lifted `PVListPage` the brief names
- [ ] Version (0.37.0 at the base) in VERSION, core/version.go, MARKETING_VERSION together
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan and STEP-8's nine findings
- [ ] docs/deployment-plan/spike-16/deployment-plan.md: bar 38 added; map row status; docs/deployment-plan/spike-16/completed.md: one short paragraph of what shipped
- [ ] Brief S16-D12 moved to design/archive/ and design/README.md updated
- [ ] Domain doc updated: docs/macos-client-patterns.md § 9; docs/ideas/wide-layout.md; .agents/skills/add-workspace-location/SKILL.md
- [ ] PR description: what shipped, AC evidence, deviations, manual check, STEP-8 findings
```

## 10. Manual check

Use a project with Sources of each kind: one with 8 graphs (one without an Artifact), several with one graph, one with no Artifact, one with a 90-character title. For the Scale steps, the user's largest catalog.

1. Open Sources from the sidebar at Regular: header, toolbar, list to the pane's edges, every Source closed with its summary, nothing selected, list at its top. Press ↓: the first row is selected (AC-1.1, AC-1.3, AC-2.1, AC-2.10, AC-4.1, AC-7.1).
2. Click the 8-graph Source's triangle: 8 graph rows, badges aligned, nothing selected or opened; click again: closed. ⌥-click: every Source opens; ⌥-click: every Source closes. Open two, go to Persons and back: still open. Change the sort: still open, selection cleared, list at top. Undated Source: no date and no dot (AC-1.4, AC-2.2, AC-2.3, AC-2.4, AC-2.5, AC-2.6, AC-2.7, AC-2.9).
3. Click a Source row, then a graph row: system bar, white text, colored badge and cover. Click another app: grey bar. Hover: nothing. Double-click the Source: its page; Back: selected, in view. Select a graph, Return: its canvas; Back: the Source open, the graph selected. Select the graph without an Artifact: faint; Return and double-click do nothing (AC-1.7, AC-3.1, AC-3.2, AC-3.3, AC-3.4, AC-3.5, AC-7.2, AC-7.3).
4. With an open Source: ↓ / ↑ cross Source and graph rows; End, Home, Page Down, Page Up as AC-4.3, AC-4.4. → and ← as AC-4.5, AC-4.6, AC-4.7, AC-4.8. Select a graph and close its Source by the triangle: the Source is selected (AC-2.5, AC-4.2).
5. Right-click: an open Source (Open, Copy…), the closed 8-graph Source (Open, Copy…, a separator, eight `Open <name>`, one disabled), a graph row. While the graph list loads on a fresh launch, the closed Source's menu: Open, Copy… only. Choose `Open Jones household` from the closed Source, then Back: the Source open, the graph selected and in view. Right-click an unselected row, Open, Back: that row selected. Copy…: the Copy form (AC-5.1, AC-5.2, AC-5.3, AC-5.4, AC-5.5, AC-5.6, AC-5.7).
6. Widen past 1600 pt with a row selected: 56 pt insets, the title wider, selection, scroll and focus kept. Narrow the window to an 800 pt pane: nothing overlaps, title then type truncate (AC-1.2, AC-1.5).
7. Two row heights: scroll the open-all list fast and slowly; record whether each row draws at its height. Scroll one wheel notch: record how far it moves.
8. Click a triangle on an unselected row: record whether the row is selected (AC-2.11). Press → and ←: record whether they act (D-14).
9. Record which separator branch draws (§12 Q-2).
10. VoiceOver on: a Source row reads its title, type, date, summary, ref and update, and "collapsed" or "expanded"; the Show/Hide action toggles it; a graph row reads name, counts and status. Record each.
11. States: watch first load on the largest catalog (skeleton, no rows arriving later); set a status filter on a fresh launch (skeleton under the toolbar); an empty project (centered); a search matching nothing (centered, Clear filters). Open a Source while its counts load (skeleton bars, badge slots held). Failures: the `#Preview`s of STEP-4 and STEP-5 for counts failed, graph list failed with and without a status filter, and the whole-list failure (AC-6.1, AC-6.2, AC-6.3, AC-6.4, AC-6.5, AC-6.6, AC-6.7, AC-6.8, AC-6.9, AC-6.10).
12. Back edges: select a graph, go to Persons, delete that graph from its Source page (or delete the Source), Back to Sources: nothing selected, top. Select a graph, close every Source with ⌥-click, open Persons, Back: its Source open, the graph selected. Launch on a history file from the base whose Sources entry holds a top-row id, Back to it: that Source selected and in view (AC-7.4, AC-7.5, AC-7.7).
13. Scale: on the largest catalog, ⌥-click open-all and close-all; record any stall.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A `List` with two row heights misdraws or scrolls unevenly | D-21's fallback, recorded in STEP-8 |
| A `Button` in a row selects the row on click | D-13 accepts it (brief § 2.1 fallback), recorded |
| `.onKeyPress` never sees → and ← (the table eats them) | D-14: shipped without, recorded, Out line's idea entry |
| The reveal scroll lands before the inserted row exists | `whenRequested` scrolls a turn later (D-9); stop below if it still misses |
| The session's expanded set grows with ids of deleted Sources | Harmless; bounded by the catalog's Sources in one session |

**Stop and report if:**

- `PVList` has a caller besides `ConclusionListPage` at the base (`rg -n "PVList\(" macos/App --glob '!**/List/*.swift'`), or `ConclusionListFrame` has one besides `ConclusionListPage.swift`.
- A Persons row is not 66 pt, or its thumbnail is not on the gutter, after STEP-1 (T-1, §10 step 1 on Persons).
- Back to a graph row does not select it in view after D-9's reveal, on two tries.
- The graph list's `isSettled` stays false while it shows a value (a refetch that never ends), so the anchor never resolves.
- The outline builds more than once per change at Scale (T-10), or ⌥-click open-all stalls visibly on the user's largest catalog.
- A selected row's `backgroundProminence` is not `.increased` on a graph row (its ink stays dark on the bar).
- The board and an AC disagree, or the board answers §12 differently than this draft assumes in a way the Decisions do not cover.

## 12. Open questions

The board settles Q-1 – Q-4; the user answers Q-5 and Q-6. Each answer updates the named Decisions and ACs before status Planned.

- **Q-1 (board, SO-3).** The graph row: one line or two, and its height. Recommendation: one line (name, then the counts, then the badge), 36 pt. Updates D-12, D-21, AC-2.9.
- **Q-2 (board, § 2.1 Separators).** Whether graph rows go without a separator. Recommendation: one rule for all rows (the build may not draw per-row rules). Updates D-22.
- **Q-3 (board, SO-W1).** Wide option (a) the title takes the width, or (b) Type and Published become columns. Recommendation: (a), the brief's. Updates D-20, AC-1.2.
- **Q-4 (board, SO-9, SO-11).** The separator between Copy… and the per-graph Opens, and where the graph list failure's Callout sits above the rows. Recommendation: a separator; the Callout on the gutter with 16 pt above and below. Updates D-16, D-18, AC-5.2, AC-6.6.
- **Q-6 (user, review M-9).** `PVListPage`'s layer: the brief's inventory says Recipe (`macos/App/DesignSystem/Recipes/ListPage/PVListPage.swift` *(new)*); the review suggests a component beside `PVListPageHeader` (`macos/App/DesignSystem/Components/ListPageHeader/PVListPage.swift` *(new)*), since `loadingArea` takes `detailWidth` and nothing product-specific remains. Recommendation: the component, beside its header. Updates D-3, Codebase fit, STEP-2.
- **Q-5 (user).** A closed Source's summary when its graphs mix Promoted and Not started with none In progress. Recommendation: `8 graphs · 5 promoted` (D-17). Alternative: `8 graphs · 3 not started`.

## 13. PR

**Title:** S16-66 — The Sources list is a native outline list
**Body:** objective in one sentence; what shipped against US-1 – US-7; AC evidence; STEP-8's findings; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-66-sources-outline-list.md`.
