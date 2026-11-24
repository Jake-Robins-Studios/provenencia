# S16-71 — The Sources list is a native table

**Status:** Landed in #969 (2026-11-24)
**Spike / slice:** Spike 16 · Slice 6h — Sources table
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S16-D14](../design/archive/S16-D14-sources-table.md), board agreed 2026-11-24
**Board:** [Sources List](https://claude.ai/artifact/JDm51QdorUvY79EFoci4cm), page *S2-04 Sources list* (frames T1a–T6). §6 macOS describes each frame in words for an implementer who cannot open it. The board's header band, sort arrow, selection bar and sample Callout copy are stand-ins: the platform's chrome and today's copy win
**Depends on:** S16-66 (landed [#962](https://github.com/Jake-Robins-Studios/provenencia/pull/962)), S16-D14 (agreed 2026-11-24)
**Blocks:** —
**Branch:** `s16-71-sources-table`
**Version bump:** minor, 0.38.0 → 0.39.0 at the base — the Sources list changes how a researcher sorts and opens it, and `Source` gains an additive wire field ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-workspace-location`](../../../../.agents/skills/add-workspace-location/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md), [`add-catalog-query`](../../../../.agents/skills/add-catalog-query/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`, `.cursor/rules/swift-tests.mdc`
**Context:** map scope entry [S16-71](../deployment-plan.md#s16-71--the-sources-list-is-a-native-table); working rule "(Batch 6) The Sources list is a native table"; the S16-66 plan's **Landed** note ([`S16-66-sources-outline-list.md`](S16-66-sources-outline-list.md)); the throwaway spike on the local branch `spike/sources-table` (`git show spike/sources-table:macos/App/Features/Sources/SourcesTableSpike.swift`): read it for the `Table` calls that compile and work, do not copy its shortcuts
**Runs on:** macOS with Xcode. §10 needs a person at the Mac with a real mouse; hosted tests cannot send clicks
**Planned:** 2026-11-24 against `main` @ `01c6990fd`
**Review:** [`S16-71-sources-table.review.md`](S16-71-sources-table.review.md) — Fits with changes / Ready with changes, 2 rounds; every blocker Fixed; no To user item open
**Landed:** `works | differs | not checked`. **Works:** header redraw on sort (D-5: the sorted header is brighter and moves, hosted `theSortedHeaderIsBrighter`); Regular and Wide widths and the 1102 to 2296 to 1102 round trip with selection kept (`columnsFitTheirWidths`); the second press of a double-click is ignored and the first row opens by `rowForSecondPress` (hosted `select`); skeleton rows under the header render. **Differs:** (1) the version bump is 0.39.0 to 0.40.0: main was already 0.39.0. (2) Not started's natural badge width is 128 pt in this build (In progress 123, Promoted 110), so `minWidth: 126` holds the other two at 126 and Not started is 2 pt wider; AC-3.5's single width needs the constant (`EvidenceStatus.badgeWidth`) raised to 128 if the user wants it exact. (3) Added and Updated read the existing `TimestampFormat` relative words (`Today, 3:15 PM`, `Yesterday`, then a short date), not `2 days ago` (AC-1.5). (4) A graph row's wheel step is its 26 pt of content, not 34 pt: the table adds its 8 pt padding to the least row height it is given. (5) `PVNativeListBehavior.settleDelay` is a computed static on the generic type. (6) `SourcesOutline` also holds `items`, the table's rows built once. (7) `SourcesOutlineHostedTests` and `SourcesTableHostedTests` are `.serialized`: run in parallel, 14 hosted tables starved the main actor for the whole suite. (8) `PVPublishedDate` draws `Undated` faint (AC-1.5), which the Person page's Sources section shares. (9) The plain list's rules test stays in `SourcesOutlineHostedTests` beside its helper, not in `PVListTests`. (10) AC-1.9 (no drag, reorder or hide) is a manual check: the platform's own `NSTableView` flags stay on, SwiftUI's `disabledCustomizationBehavior(.all)` is what holds. **Not checked:** Page Up and Page Down, a real double-click, a triangle click, VoiceOver by column, drag and right-click on a header, opening one Source at the user's largest catalog (§10). **Round 1 differences (the user approved each, 2026-11-24):** (11) difference (2) is closed: `EvidenceStatus.badgeWidth` is 128, one width for every status (`everyStatusBadgeIsOneWidth`). (12) Added and Updated are 98 pt at Regular and the cells truncate with a tail, so Title is 352 at 1102 pt (Wide unchanged); the Updated cell and a Source whose graph list failed to read now carry VoiceOver labels (`PVLastUpdated.spoken`; the new string `sources.list.graphsUnavailable`). (13) D-15's time limit between the presses is gone: a press with `clickCount` 2 or more is the first row's second press while that row is still the selection and the event is under a second old; a second press that lands on no row opens the first row, and the press is consumed so a row opens once. (14) "Schema: None" is superseded: migration `000071.sql` adds `audit_changes_created_idx`, a partial index of creates, so the create read no longer walks a Source's history; `BenchmarkList` runs at 20 and 80 changes a Source, before 17.2 and 35.0 ms, after 13.2 and 18.2 ms. (15) A Source that opens is scrolled back into view (the Source above it closes and the rows move); the page requests it from `apply(.expand)` with `pvScrollsRowIntoView(_:animated:whenRequested:)`, and the triangle shares that line (no hosted test clicks the triangle). (16) STEP-10's `kit-layering.md` entry for nine hand-written micro-caps sites is superseded: they read `PVMicroCaps` and the entry is gone. (17) Clicking the open Source when it has no triangle leaves it open. (18) The kit's second selection scroll also requires the row in `ids` (D-10). (19) A resize across the Wide breakpoint and back keeps the scroll position, the keyboard, the selection and the open Source (`resizingAcrossTheWideBreakpointKeepsTheScrollTheSelectionAndTheOpenSource`; the platform moved the scroll by no more than a row). (20) At 3,000 Sources a throwaway hosted timing read: the page and its table up in 0.68 s, opening one Source 45 to 73 ms, moving the selection across the list 19 to 104 ms, closing the Source 94 to 112 ms (not committed). **User test differences (2026-11-24):** (21) A graph row drew as tall as a Source (66 pt) after Sources opened and closed: the platform reuses a Title cell's view for a row of the other height, and the view does not shrink below the height it was first measured at. `SourcesRowHeight` has every Title cell measured at a graph row's height first; a Source's grows as it appears, before it is drawn (`everyRowIsItsOwnHeightHoweverTheRowsMove`). A row never drawn keeps the platform's estimate, now 34 pt. (22) Difference (4) is closed: the table's least row height, and so the wheel's step, is a graph row's 34 pt (a table adds no padding to it). (23) Because rows grow as they are drawn, the scroll of difference (15) is asked for once more after `settleDelay`. (24) AC-4.7's and AC-4.8's "in view" moved to the new Spike 16 PR that records a scroll offset in history (user, 2026-11-24): with right heights the viewport still stopped short in 1 of 120 runs, so `anAnchorSetBeforeThePageIsHostedOpensTheSourceAndSelectsTheGraph` keeps the open Source and the selection and drops the scroll. (25) The badge ink test compares pixels within one level of 255: a process's first renders of a rounded corner round two antialiased pixels differently (not the fonts).

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

The Sources list draws Type, Published, updated and ref as columns with no headers, because a list has none. It moves onto the native macOS table: the same outline of Sources and Evidence graphs, under named columns that sort when clicked. One Source is open at a time, a Source shows one status badge, and the date it was added is a column.

**Why now.** The user reviewed S16-66 (2026-11-24), tried a table spike, and asked for it with these changes.

**What stays.** The page header; search, type and status; what opens and how (a click on a closed Source selects and opens it, the triangle only toggles, a double-click or Return opens the page or canvas, → and ←, the menus, Back); the empty, no-match and failure copy; the reads.

## 2. User stories

**US-1.** As a researcher, I see Sources in named columns at either width.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A 1102 pt pane | Columns Title, Evidence 168, Status 128, Published 96, Added 92, Updated 92; the title takes the rest (364 in the probe, at least 360); no Type, no Ref column; no sideways scrolling; the `TITLE` header's text on the 32 pt gutter |
| AC-1.2 | A 2296 pt pane | Evidence 240, Status 140, Type 220, Published 160, Added 120, Updated 120; the title takes the rest (about 1069); the gutter is 56 |
| AC-1.3 | An 800 pt pane | Title 240, the others as at Regular; the table scrolls sideways, Title first |
| AC-1.4 | A Source `SRC-4K2QX`, `Census`, 1851 | Title cell: triangle, 44 pt cover, title on one line (ellipsis, full title on hover) over the mono ref; at Regular ` · Census` after the ref. The type truncates, the ref never. No date in the subtext |
| AC-1.5 | The same, added and updated 2 days ago | Added `2 days ago`, Updated `2 days ago`, no icon; hover `Added <stamp>` and `Last updated <stamp>`; a faint `—` when unknown. Undated: Published reads faint italic `Undated` |
| AC-1.6 | A graph row, 12 subjects, 40 observations, In progress | Glyph and name indented under its Source's title; `12 subjects · 40 observations` in Evidence; the badge in Status; its other cells empty. Rows are 66 pt (Source) and 34 pt (graph) |
| AC-1.7 | A Source with one graph, with 8, with no Artifact | Evidence `1 graph`, `8 graphs`, italic muted `Needs an artifact` |
| AC-1.8 | Resize across 1600 pt, with a row selected mid-list, and back | Widths as AC-1.1 and AC-1.2 each time; selection, scroll position, focus and the open Source stay |
| AC-1.9 | Drag a header edge or a header; right-click a header | Nothing resizes, reorders or hides |

**US-2.** As a researcher, I sort by clicking a header.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | First visit | Sorted by Added, newest first; the system arrow on Added; its header text one step brighter |
| AC-2.2 | Click Title, then again | A to Z, then Z to A. Published, Added and Updated start newest first, then oldest first |
| AC-2.3 | Sort by Published either way | Undated Sources last, by title A to Z |
| AC-2.4 | Click Evidence, Status or Type | Nothing |
| AC-2.5 | Any sort or filter change with a row selected | Nothing is selected, the table is at its top, the open Source stays open with its graphs under it |
| AC-2.6 | Leave and come back; relaunch | The sort is kept. A settings file from before (`"sort":"az"`) reads as Added, newest first, its other fields kept |
| AC-2.7 | The toolbar | Search, type and status; no sort menu |

**US-3.** As a researcher, I see one status for a Source and filter by it.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Graphs all Promoted; all Not started; Promoted + Not started; one In progress of 8 | Promoted; Not started; In progress; In progress |
| AC-3.2 | A graph with no Artifact beside a Promoted one; alone | In progress; Not started |
| AC-3.3 | No Artifact; counts loading; counts failed; the graph list failed | No badge |
| AC-3.4 | Status filter Promoted, a Source with one Promoted and one Not started graph | Not listed; with In progress it is, with both graphs when open |
| AC-3.5 | Any rows with badges | Every badge is 126 pt wide, icon and label leading, Source and graph badges on one line down the column; the same open or closed |

**US-4.** As a researcher, I have one Source open.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | Arrive | Every Source is closed |
| AC-4.2 | Source A open; click closed Source B | B is selected and open, A closed |
| AC-4.3 | A open; click a Source with no triangle | It is selected, A closes |
| AC-4.4 | A open; click one of its graphs; arrow to another Source; change the sort | A stays open |
| AC-4.5 | A open, a graph of A selected; close A by its triangle | A is selected |
| AC-4.6 | A open with its graph selected; open B by B's triangle | A closes and is selected; B is open |
| AC-4.7 | B closed; choose `Open <graph>` from B's menu, then Back | B open, the graph selected and in view, A closed |
| AC-4.8 | Back to a graph of a closed Source while A is open | That Source open, A closed, the graph selected and in view |
| AC-4.9 | ⌥-click a triangle | As a click |
| AC-4.10 | A filter hides A, then is cleared | A is open |
| AC-4.11 | A open above B; double-click B (B moves up after the first press) | B's page opens; no other row is selected or opened |
| AC-4.12 | Open A, go to Persons, come back; relaunch | A open; every Source closed |

**US-5.** As a researcher, the rest works as before.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-5.1 | Selected Source or graph row, focused and not | The system's rounded bar, grey unfocused; text and triangle in the on-selection ink; cover and filled badges keep their colors; Not started's outline and text take the on-selection ink on a focused bar |
| AC-5.2 | Double-click or Return; ↑ ↓; Page Up and Down; Home and End; → and ← | As S16-66: open, move, scroll a screen, scroll to an end with the selection unchanged, open a closed Source, close or climb |
| AC-5.3 | Arrive from the sidebar; press ↓ | Keyboard focus in the table with no ring; the first row is selected |
| AC-5.4 | Search to no match, then back to a match | Focus stays in the search field |
| AC-5.5 | Right-click a Source, a closed Source, a graph | Today's menus and entries |
| AC-5.6 | First load; a filter waiting | The header over skeleton rows in their columns; toolbar withheld, then shown. VoiceOver skips the skeletons |
| AC-5.7 | Counts late, counts failed, graph list failed with and without a status filter, whole-list failure, empty, no match | As S16-66; failures, empty and no match show no table header, but a failed graph list with rows keeps it, and its Source rows read a faint `—` in Evidence |
| AC-5.8 | VoiceOver on a Source's Title cell; a graph's | Title, ref, type, `expanded` or `collapsed`, and a Show or Hide graphs action; name and, when it cannot open, why. The other cells read their words under their column's name |

## 3. Scope

| In | Covered by |
| --- | --- |
| TB-1 page, TB-2 columns, TB-7 widths, TB-W1 Wide | STEP-7, AC-1.1 – AC-1.3, AC-1.8, AC-1.9 |
| TB-3 Title cell, TB-6 graph row | STEP-7, AC-1.4, AC-1.6 |
| TB-4 Evidence and Status, the aggregate badge, the status filter | STEP-3, STEP-5, STEP-7, AC-1.7, US-3 |
| TB-5 dates; `created_at` from the engine | STEP-1, STEP-3, STEP-7, AC-1.5 |
| TB-8 sort by headers; the sort menu goes | STEP-4, STEP-7, US-2 |
| TB-9 one open | STEP-6, STEP-8, US-4 |
| TB-10 selection | STEP-3, STEP-7, AC-5.1 |
| TB-11 menus | STEP-7, AC-5.5 |
| TB-12, TB-W2 states | STEP-7, AC-5.6, AC-5.7 |
| The native list's behaviors in one kit modifier; `PVListBody` folds into `PVList` | STEP-2, STEP-9, AC-5.2 – AC-5.4 |

| Out | Home |
| --- | --- |
| Properties, Metadata and Source types on a native table | [`docs/ideas/kit-layering.md`](../../../ideas/kit-layering.md) |
| Persons, Events and Places as tables | not planned |
| Draggable, reorderable or saved columns | not planned (user, 2026-11-24) |
| Sorting by Type, Evidence or Status | not planned |
| A header fill, height, divider or arrow of our own (AppKit) | not planned (brief § 2.1) |
| `waitUntil`'s two-second limit | not planned (dropped by the user, 2026-11-24) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Go Source reads | `core/database/sources/sources.go` `Source`, `List`, `ListByIDs`, `fillListed`, `getOne`, `fillDates` | `Updated` from the display cache; no create time. `getOne` fills dates for one row |
| Create time precedent | `core/database/sources/notes.go` `sqlListNotes` | A note's `created_at` is `audit_transactions.created_at` of its `audit_changes` row with `action = 'create'`; index `audit_changes_entity_id_idx` (migration 000057). `Create` records `rowchange.Created("source", …)` |
| Proto | `api/proto/engine.proto` `Source` (fields 1–17); `api/ffi/handlers/sources.go` `sourceProto` (callers: the list at line 47, `thumbnails.go` `enrichSourceProto`) | `updated_revision` 12, `updated_at` 13; no created field |
| Swift Source | `macos/App/Platform/GenealogyStore.swift` `CatalogSource`; `GoStore.swift` `mapSource`; `FakeStore.swift` | `updated: CatalogActivity`; no created time |
| List body | `macos/App/DesignSystem/Components/List/PVListBody.swift` `PVListBody`, `PVListBodyRow` | One caller pair: `PVList` and `SourcesListView`. Owns the `List`, focus, Home/End, the scrolls, the menu, the primary action. `leadingHang`, `separator`, `menu`, `restartKey`, `claimsFocus` are passed only by Sources |
| List row | `PVList.swift` `PVListRow` (`leading`, `leadingWidth`, `details`), `PVListMetrics` (`hang`, `titleLeading`, `leadingInset`) | The leading slot and more than one detail have only the Sources row as caller |
| Outline | `macos/App/Features/Sources/SourcesOutline.swift` | `SourcesOutline(sources:graphs:expanded: Set<String>)`, `endsGroup`, `togglableSourceIDs`, `selectionAfterCollapsing`, `sourceToOpen`, `isPlainLeftClick`, `setExpanded`, `keyAction`, `sourceToReveal`, `secondaryParts`, `SourcesSecondaryPart`, `SourcesRowColumns`, `SourcesGraphSummary`, `SourcesRowMenu` |
| Rows | `SourcesOutlineRows.swift` | `SourcesSourceRow`, `SourcesExpandedState`, `SourcesDisclosureTriangle`, `SourcesSecondaryLine`, `SourcesGraphRow` |
| Page | `SourcesListView.swift` | `SourcesPage.frame`, `SourcesListLoadingArea`, `SourcesListContent` (`content`, `rows`, `handle`, `outlineRow`, `select`, `toggle`, `menuActions`, `toolbar`, `sortMenu`), `SourcesAddDialog`, `SourcesTriangleHover`, `SourcesEventSource` |
| Model | `SourcesModel.swift` `Sort` (six cases, `label`), `statuses(for:)`, `buildVisibleSources`, `updatedOrder`, `dateOrder`, `titleOrder`, `sortControlLabel`, `outline`, `outlineIsSettled`, `listState` | The status filter keeps a Source when any graph has the status |
| Settings | `SourcesListSettings.swift` `sort: SourcesModel.Sort` | Each field falls back to its default by itself |
| Session | `WorkspaceSession.swift` `expandedSourceIDs: Set<String>`, `setSourcesExpanded` | Direct callers besides `SourcesOutline.setExpanded`: the reveal and `openGraph` in `SourcesListView`, `SourcesListPreviews` |
| Badge | `macos/App/DesignSystem/Components/Badge/PVBadge.swift`; `SourcesEvidenceStatus+Badge.swift` `badge` | `.fixedSize()`, no width; `.neutral` subtle ink is `textSecondary` on `borderDefault` |
| Dates | `PVPublishedDate` (`body`, `detail`, `column`), `PVLastUpdated` (`detail`, `column`, `columnWidth`, `label`), `PVListDetailCell` | `PVPublishedDate.column`'s only caller is `SourcesRowColumns` |
| Micro caps | `macos/App/DesignSystem/Tokens/PVTypography.swift` `pvMicroCaps()` | A `View` modifier ending in `.textCase`, which `Text` has not |
| Sort direction precedent | `macos/App/Features/SourceTypes/SourceTypesModel.swift` `SortColumn`, `sortAscending` | A column and a direction |
| Copy | `L10n.Sources`: `sortMenu`, `sortAdded`, `sortUpdated`, `sortAZ`, `sortZA`, `sortDateOldest`, `sortDateNewest`, `sortedBy`, `graphSummary`, `graphSummaryInProgress`, `graphSummaryPromoted`, `graphSummaryCount`, `showGraphs`, `hideGraphs` | The sort names and summary words have no other caller |
| Tests | `SourcesOutlineTests`, `SourcesOutlineHostedTests`, `SourcesModelTests`, `SourcesListSettingsTests`, `SourcesListStateTests`, `PVListTests`, `PVLastUpdatedTests`, `PVPublishedDateTests`, `PersonsListTests` | Cover the list |

**Precedent.** S16-66 ([#962](https://github.com/Jake-Robins-Studios/provenencia/pull/962)) for the page and its hosted tests; the spike for the `Table` calls (`Table(of:selection:sortOrder:columnCustomization:)`, `TableRow`, `contextMenu(forSelectionType:menu:primaryAction:)`, styled `Text` headers, all at macOS 14.0). Do not copy the spike's `SourcesTableTuner`-style AppKit reach-ins, its key paths, or its restated menu builder. `DisclosureTableRow` fails (a Source opened in code deep in the table draws no graphs) and an `if` around a `TableColumn` needs 14.4.

**Probe (2026-11-24, offscreen, macOS 27.2).** With every column but Title at one fixed width per width class and Title `min: 240, ideal: 240, max: <what is left>`, the widths were the board's on arrival and after every resize (1074 → 1560 → 2220 → 1074 → 772). Title with no maximum kept its Wide width on the way back; columns with a range drifted. The platform puts 17 pt between columns, 18 pt before the Title header's text, and 8 pt of cell padding in a row's height.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `audit.Created(q database.Querier, entityType string, ids [][]byte) (map[string]Creation, error)`, keyed by `string(id)` as `lookupDates` is, *(new, `core/database/audit/created.go` (new))*: one `sqlbatch.Query` over `audit_changes` joined to `audit_transactions` and, left, `users`, for `entity_type = ? AND action = 'create' AND entity_id IN (`ids`)`; `Creation{At, UserDisplayName string}` *(new)*, the lowest revision's when an id has several; an id with none is absent. `sources.Source` gains `CreatedAt string`, filled where `Updated` is: `fillListed` (one batch) and, for a single response, `enrichSourceProto` through `sources.AttachCreated(c, *Source)` *(new, beside `AttachActivity`; it reads only when the field is empty)*. `getOne` does not change. `CreateSource` and `CopySource` get it from `enrichSourceProto`, after their commit. The note reads (`sqlListNotes`, `sqlGetNoteAttributed`) drop their four subqueries and read `audit.Created`. Proto `string created_at = 18`; Swift `CatalogSource.createdAt: String = ""` | One rule for who and when a row was made; `Lookup` stays a row read; new and copied Sources, which Swift appends to the list, carry it (review M-1, M-2, X-1) | Decoding the UUIDv7 in Swift; `getOne` filling it (every write's read would pay); a fifth copy of the subquery |
| D-2 | The sort is `struct SourcesSort: Codable, Hashable` *(new, in `SourcesListSettings.swift`, Foundation only)*: `var column: Column`, `var order: SortOrder`. `enum Column: String, Codable` `title, published, added, updated`, with `firstOrder` (`title` forward, the others reverse). `static let initial = SourcesSort(column: .added, order: .reverse)`. `SourcesModel.Sort` goes. Orders: **Title** by title in the order, equal titles by id descending both ways (today's `titleOrder`); **Published** by `dateSortKey` in the order, undated last both ways, ties and undated by title A to Z (today's `dateOrder`); **Added** by id in the order; **Updated** by `updated.revision` then id, both in the order. `SourcesModel.updatedOrder` keeps its two arguments and newest-first meaning, since `WorkspaceSession.sourcesByUpdated` passes it; the sort calls it, swapped for forward | One value for the settings and the headers; one case and one comparator per new sort (review M-4) | A second comparator type and a two-way mapping; eight flat cases |
| D-3 | Stored settings: `SourcesListSettings.init(from:)` decodes `SourcesSort` with `try?` and falls back to `.initial`; no migration and no reading of the old string | Dev phase; the fields fall back one by one already | Mapping the old strings |
| D-4 | Headers: `extension SourcesSort: SortComparator` *(new, in `SourcesTable.swift`, STEP-7)*, `Compared = SourcesTableItem`, `compare` returning `.orderedSame` (the model sorts; the table only reports clicks). Sortable columns use `TableColumn(_:sortUsing:content:)` with `SourcesSort(column:, order: column.firstOrder)`. The table's `sortOrder` binding is `[model.settings.sort]`; its `set` writes the first element, when there is one | The table never reorders rows, so graphs stay under their Source | Key paths with no meaning (the spike) |
| D-5 | Header text is `PVMicroCaps.text(_ title: LocalizedStringResource) -> Text` *(new, `enum PVMicroCaps` in `PVTypography.swift`)*: `Text(verbatim: L10n.string(title).localizedUppercase)` with `PVMicroCaps.font` and `PVMicroCaps.tracking` *(new, internal)*, which `pvMicroCaps()` and `PVBadge` read too. Ink `textMuted`; `textSecondary` for the sorted column. If a header does not redraw when the sort changes (T-12), every header is `textMuted`, recorded in the Landed note | A column title takes only `Text`, which has no `textCase` | A second definition |
| D-6 | Columns (`SourcesTable`, in `macos/App/Features/Sources/SourcesTable.swift` *(new)*): widths from `SourcesTableWidths` *(new, pure)*: `init(isWide: Bool, tableWidth: CGFloat)`; Regular evidence 168, status 128, published 96, added 92, updated 92; Wide 240, 140, type 220, 160, 120, 120; `titleMaximum = max(240, tableWidth − sum of the others − 17 × their count − 49)` (49: the table's own insets and a legacy scroller, probe). Fixed columns `.width(w)`; Title `.width(min: 240, ideal: 240, max: titleMaximum)`. `tableWidth` is the table's own width, inside D-9's padding (pane width − 2 × (gutter − 18)), from a `GeometryReader` placed inside that padding. The measured platform numbers (17 column gap, 18 header inset, 8 cell padding, 49 table insets) are named constants on `SourcesTableWidths`, with one comment naming macOS 27.2 | Matches the board at every width tried; drift is the platform's (user: fixed widths) | min / ideal / max ranges |
| D-7 | The Type column is always declared, hidden at Regular through `TableColumnCustomization` (`customizationID` on every column, the state initialized for the current width class in `init` and updated in `.onChange(of: isWide)`); every column wears `.disabledCustomizationBehavior(.all)` | An `if` in columns needs 14.4; initializing in `init` keeps the hidden column's width out of the first layout (spike) | Raising the minimum OS |
| D-8 | `Table` rows are `SourcesTableItem: Identifiable` *(new)*: `.row(SourcesOutlineRow)` or `.skeleton(Int)` (ids `skeleton-0` to `skeleton-29`). Loading draws the same `SourcesTable` with 30 skeletons, `.scrollDisabled(true)`, `.allowsHitTesting(false)`, `.accessibilityHidden(true)`, a constant nil selection and no behavior modifier; its `sortOrder` is the settings' value, read only. `PVListPageArea.loadingArea` stays for the Conclusion lists. Each cell draws its skeleton bar (Title: 44 pt thumb, bars 240 × 8 and 140 × 6; Evidence 56, Status 72, Type 80, Published 40, Added 60, Updated 60 wide, 6 tall) | TB-12: the header over skeletons in their columns, one column definition | A second table; a drawn header |
| D-9 | `.tableStyle(.inset(alternatesRowBackgrounds: false))`, `.scrollContentBackground(.hidden)`, `.padding(.horizontal, gutter − 18)`, `.transaction { $0.animation = nil }`. Row content heights: 58 pt (Source) and 26 pt (graph) in the Title cell; the platform's 8 pt makes 66 and 34 | Spike, hosted: the `TITLE` text lands on the gutter | — |
| D-10 | Native list behavior: `PVNativeListBehavior<ID: Hashable>: ViewModifier` *(new, `macos/App/DesignSystem/Components/List/PVNativeListBehavior.swift` (new))*, applied by `.pvNativeListBehavior(ids: [ID], selection: Binding<ID?>, minimumRowHeight: CGFloat, label: LocalizedStringResource, onActivate: @escaping (ID) -> Void, menu: @escaping (ID) -> [[PVActionMenuItem]] = { _ in [] }, restartKey: AnyHashable? = nil, claimsFocus: Bool = true)`. Moved from `PVListBody`: `defaultMinListRowHeight`, `focusEffectDisabled`, focus and its claim, the context menu with the primary action and `menuContent`, Home/End through `PVListKeyboard.moveIndex`, the scrolls, the label. `onActivate` and `menu` are called only with an id in `ids`; the caller maps an id to its item. Arrival and a late row share one request path, which scrolls a turn later and once more after `PVNativeListBehavior.settleDelay` (150 ms, *new*), when the selection is still the one requested and is in `ids`; a row already in view does not move, so `PVList` has it too | One copy (brief review M-1). A table's first scroll to a deep row stops a row short with two row heights; the spike's second one at 150 ms passed the hosted Back test | Copying the block into the feature; a Bool for one caller (review M-5) |
| D-11 | `PVListBody` folds into `PVList.body` (its only caller) and the file goes. `PVList` keeps its API. `PVListRow` loses `leading`, `leadingWidth` and the `details` array (back to one `detail`); `PVListMetrics` keeps `platformCellInset` and one `rowInset(horizontalInset:)` (`max(0, horizontalInset − 8)`); separators are visible on every row, with `PVListRow` setting `.alignmentGuide(.listRowSeparatorLeading) { _ in 0 }` and `.alignmentGuide(.listRowSeparatorTrailing) { $0.width }` as it did before S16-66. `PVListPageArea.loadingArea` and `PVListSkeleton` go back to one `detailWidth: CGFloat?` | The slots had one caller (brief review M-5) | Keeping a kit API with no user |
| D-12 | The badge rule: `SourcesModel.EvidenceStatus.aggregate(_ statuses: [EvidenceStatus]) -> EvidenceStatus?` *(new, pure)*: nil when empty, the common value when all are equal and it is `.promoted` or `.empty`, else `.inProgress`. `SourcesModel.status(for: CatalogSource) -> EvidenceStatus?` *(new)*: nil with no Artifact or no graph, while the Source's graphs are not `.loaded`, or when any graph **with an Artifact** has counts loading or failed; a graph with no Artifact contributes `.empty`. `statuses(for:)` goes; the filter is `status(for: $0) == wanted` | One rule for the cell and the filter. The board: a graph with no Artifact is Not started whatever its counts | Two rules |
| D-13 | The session holds `openSourceID: String?` and `setOpenSource(_ id: String?)`; `expandedSourceIDs` and `setSourcesExpanded` go. `SourcesOutline(…, open: String?)`. The one writer is `SourcesOutline.setOpen(_ id: String?, selecting: String? = nil, session:, navigation:)` *(replaces `setExpanded`)*: it notes `selecting` when given; otherwise, when the selected row is a graph or placeholder of the Source that closes, it notes that Source; then sets the open id. Its pure half is `selection(afterOpening id: String?, selecting: String?, current: String?) -> String?` (replaces `selectionAfterCollapsing`; it reads the open Source from the outline's rows). The triangle, → and ←, a click, the reveal (`selecting: anchor`) and the menu's `openGraph` (`selecting: graph.id`) all call it; `SourcesListPreviews` and tests set the session directly | AC-4.5 – AC-4.8; one owner (brief review M-7) | Three writers |
| D-14 | A plain click: `SourcesOutline.clickAction(selecting new: String?, from old: String?, isPlainClick: Bool, onTriangle: Bool) -> SourcesOutlineAction` *(replaces `sourceToOpen`; `SourcesOutlineKeyAction` is renamed `SourcesOutlineAction`)*: a plain click, not on a triangle, moving the selection to a Source row that is not the open one → `.expand(id)` when it has a triangle, `.collapse(openID)` when it has none and a Source is open; anything else `.ignore`. One `apply(_ action:)` on the page runs a key's and a click's action through `setOpen` (a click's a turn later, as today, and with `selecting:` the clicked row). ⌥-click goes: the triangle's `toggle` takes no argument; `isPlainLeftClick` is unchanged (a ⌥-click on a row still only selects) | AC-4.2 – AC-4.4, AC-4.9; one outcome type for keys and clicks (review M-6) | A double optional |
| D-15 | The double-click: `SourcesPointer` *(new, plain class in `SourcesListView.swift`, page-local, not observed; replaces `SourcesTriangleHover` and keeps its `note(_:inside:)`)* also keeps the row id and time of the last plain click whose `clickCount` is 1. Its `rowForSecondPress(clickCount: Int, now: TimeInterval, interval: TimeInterval) -> String?` *(pure)* returns that id when `clickCount ≥ 2` and it is within `NSEvent.doubleClickInterval`. `select`: when it returns a row, ignore the write (no anchor, no open). `onActivate(row)`: when the current event is a left mouse event and it returns an id the outline still has, activate that row instead. A first press on the row already selected records nothing and moves no row. Return and the menu never match | AC-4.11 without delaying the open. The event comes through `\.sourcesCurrentEvent`, as today | Delaying the close by the double-click interval (the fallback, §11) |
| D-16 | Cells: Title as AC-1.4 and AC-1.6, the indent `16 + 4 + 44 + 12 = 76` pt; `SourcesDisclosureTriangle` in a 16 pt slot. Evidence: `L10n.Sources.graphSummaryCount`, `needsArtifact` (italic, `textMuted`), `—` (`textFaint`) when the graph list failed, nothing while it is pending; a graph: `SourcesGraphCountLine(.row)` or italic `graphNeedsArtifactToOpen`. Status: `badge`, or a 72 × 6 skeleton bar on a graph whose counts load; a graph with no Artifact shows neither. Type `caption`. Published `PVPublishedDate`. Updated and Added: `PVListDetail.relative(_ at: String, in:, help: (String) -> String) -> PVListDetail` *(new, in `PVLastUpdated.swift`: the relative words, the stamp through `help`, a faint dash, no icon)* in `PVListDetailCell(width: nil)`, with `L10n.LastUpdated.help` and `L10n.Sources.addedHelp`. `PVLastUpdated.detail` becomes that plus its icon. Every ink through `PVColor.onSelection` | TB-3 – TB-6; "last updated" words never mean added (brief review M-4) | — |
| D-17 | `PVBadge` gains `minWidth: CGFloat? = nil` on its `LocalizedStringResource` initializer (the frame, leading, inside the fill and outline). A badge with no fill (`subtle`, any tone) takes its ink and outline through `PVColor.onSelection`, a `foreground` override too; filled badges keep theirs. `EvidenceStatus.badge` passes `minWidth: 126` from STEP-7, when the old 112 pt slot goes | TB-10 and the board's one width; the outlined `+N` on selected Persons, Events and Places rows becomes readable too (user, 2026-11-24). Outside a selected native row `onSelection` returns the ink unchanged | A tone special case; an option only Sources sets |
| D-18 | Accessibility: the Title cell is one element (`children: .ignore`): a Source's label `spokenJoin([title, ref, type])`, `pvExpandedState`, the Show / Hide action (`SourcesExpandedState`), identifier `sources.row.<id>`; a graph's label its name, its hint the blocked reason, identifier `sources.row.<sourceID>.graph.<ref>`; a pending row `graphsLoading`. The badge stays hidden and the Status cell is labelled with the status words; the Added cell is labelled `L10n.Sources.addedSpoken` (`addedUnknown` when empty). Other cells read their text. The table's label is `L10n.Workspace.sourcesTitle` | The platform reads a cell with its column's name | One element per row (a table has none) |

**Rules this plan bends.** "Persons, Events and Places do not change" (brief § 2.2) → their outlined `+N` badge takes the on-selection ink on a selected row → user, 2026-11-24: every outlined badge → §10 step 11. The brief said column edges can be dragged → they drift (probe) → user, 2026-11-24: fixed widths → brief § 2.1 and its Board line updated with this plan. The `add-ui-component` line and `PVActionMenu.swift`'s header, which name `PVListBody`'s `menu` slot, become the native list behavior's menu (STEP-10).

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `audit.Created`, `Creation` *(new)* | Go func, type | the create subqueries of `sources/notes.go` | They move onto it; nothing in `audit` reads creations |
| `sources.AttachCreated` *(new)* | Go func | `AttachActivity` | Beside it, for the other audit fact |
| `PVListDetail.relative` *(new)* | helper | `PVLastUpdated.detail` | Taken out of it; two callers |
| `SourcesPointer` *(new)* | class | `SourcesTriangleHover` | Replaces it |
| `Source.created_at` *(new)* | proto field | `updated_at` | — |
| `SourcesSort` *(new)* | type | `SourceTypesModel.SortColumn` + `sortAscending` | That page's columns, not stored; the table needs a `SortComparator` |
| `SourcesTable`, `SourcesTableItem`, `SourcesTableWidths` *(new)* | snowflake, one file | `PVTable` | Its own chrome and keyboard; the point is the platform's |
| `PVNativeListBehavior` *(new)* | kit modifier | `PVListBody` | Moved out of it; two callers |
| `PVMicroCaps.text` *(new)* | token helper | `pvMicroCaps()` | Shares its constants |
| `EvidenceStatus.aggregate`, `status(for:)` *(new)* | funcs | `SourcesGraphSummary`, `statuses(for:)` | They replace both |
| `addedHelp`, `addedSpoken`, `addedUnknown`, seven column titles *(new)* | L10n | `L10n.LastUpdated.help`, `a11yUpdated` | Their words say updated |

**Builds on.** `SourcesOutline`, `SourcesRowMenu`, `SourcesListState`, `ListSelectionAnchorModifier`, `PVListPage`, the hosted harness in `SourcesOutlineHostedTests`.
**Deletes.** `PVListBody.swift` (`PVListBody`, `PVListBodyRow`); `PVListRow.leading`, `leadingWidth`, `details`; `PVListMetrics.hang`, `titleLeading`, `leadingInset`, `trailingInset`; `PVPublishedDate.column`; `SourcesSourceRow`, `SourcesGraphRow`, `SourcesSecondaryLine`, `SourcesSecondaryPart`, `SourcesOutline.secondaryParts`, `SourcesRowColumns`, `SourcesGraphSummary`, `SourcesOutlineRow.endsGroup`, `togglableSourceIDs`, `selectionAfterCollapsing`, `sourceToOpen`, `setExpanded`, `SourcesOutlineKeyAction` (renamed), `SourcesTriangleHover`, `SourcesModel.EvidenceStatus.init(_ progress:)` and its assertions, `PVSymbol.sort`, the `detailWidths` arrays of `PVListPageArea.loadingArea` and `PVListSkeleton`, `SourcesModel.Sort`, `sortControlLabel`, `statuses(for:)`, the page's `sortMenu`; `expandedSourceIDs`, `setSourcesExpanded`; `L10n.Sources.sortMenu`, `sortAdded`, `sortUpdated`, `sortAZ`, `sortZA`, `sortDateOldest`, `sortDateNewest`, `sortedBy`, `graphSummary`, `graphSummaryInProgress`, `graphSummaryPromoted` with their catalog keys; the tests of each. `SourcesOutlineRows.swift` keeps `SourcesExpandedState` and `SourcesDisclosureTriangle` and is renamed `SourcesDisclosureTriangle.swift`.
**Next adds.** A sort by another column is one `Column` case and one comparator; another native table applies `PVNativeListBehavior`.

### Reach

| New path or state | Destination | Checked |
| --- | --- | --- |
| Opening B closes A with A's graph selected | `setOpen` | D-13: A is selected; T-6 |
| The open Source is filtered out or deleted | `SourcesOutline.init` | An id with no Source draws nothing; it costs one string (T-6) |
| A header click while a row is selected | `.onChange(of: model.settings)` | Today's clear and restart (AC-2.5) |

### Scale

Batch 6: 3,000 Sources, 10,000 graphs. `audit.Created` reads 3,000 indexed rows in `sqlbatch` batches; `BenchmarkList` *(new, beside `BenchmarkSourceRecords`: 3,000 Sources with 20 audit changes each)* is committed and reported before and after (stop above 30 ms added, the mean of `-benchtime 10x`). The outline holds at most 3,000 rows plus one Source's graphs: opening every Source is no longer possible, so the spike's 2.4 s close-all cannot happen. The badge is computed per on-screen row (`evidenceGraphsRead` is indexed once, `graphCounts` is a dictionary read); the status filter computes it per Source once per change (`derived(.visibleSources)`). STEP-10 records opening one Source and moving the selection at the user's largest catalog.

### Edges

- **Assumptions.** `visibleSources` strict order: every comparator ends in id (title, updated) or is id; with a direction flipped it stays strict (T-3). `outline.row(id:)` ids are unique: Source and graph ids are UUIDs, the placeholder and skeleton ids cannot collide with them.
- **Neighbors.** Promoted + In progress → In progress; a lone graph → its own status; a Source whose counts are half loaded → no badge, then one; a search match inside a filtered set is unchanged.
- **Removed inputs.** A graph deleted: the badge is the remaining graphs'; the last graph of a Source with an Artifact gone → `aggregate([])` nil, `0 graphs` cannot occur today (every Source has one).
- **Real data.** None — no table-driven rule.
- **Untrusted size.** A stored `sort` of any shape decodes to a known column or the default; the create read is bounded by the Sources read.

### Schema

None — no catalog change; `audit_changes_entity_id_idx` exists.

### Go core

| Package | Change |
| --- | --- |
| `core/database/audit` | `Created`, `Creation` (D-1) |
| `core/database/sources` | `Source.CreatedAt`, `AttachCreated`; `fillListed` fills it; notes read `audit.Created`; the `sqlListHead` comment ("no list load scans the audit history") says the create time is one indexed batch |

Errors: none new.

### FFI

`api/proto/engine.proto` `Source`: `// When the Source was made (RFC3339 UTC, from its create audit transaction); empty when unknown.` `string created_at = 18;`. `sourceProto` sets `CreatedAt`; `enrichSourceProto` calls `AttachCreated`. Regenerate with `./scripts/generate-proto.sh`.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Table | `SourcesTable` | `macos/App/Features/Sources/SourcesTable.swift` *(new)* | D-4 – D-9, D-16, D-18 |
| Behavior | `PVNativeListBehavior` | `macos/App/DesignSystem/Components/List/` | D-10 |
| Page | `SourcesListContent` | `SourcesListView.swift` | `rows` draws the Callout (as today) over `SourcesTable` with `.pvNativeListBehavior` (`ids: outline.rows.map(\.id)`, the rest as `PVListBody` is called today) and `.onKeyPress` for → and ← |
| Badge | `PVBadge` | kit | D-17 |

Frames in words. **T1a** Regular: header and toolbar (search, type, status) as today, then the table: 28 pt micro-caps header, Source rows with triangle, cover, title over `SRC-4K2QX · Census`, the 8-graph Source open with its graphs indented 76 pt. **T1b** Wide: the same with a Type column and the subtext the ref alone. **T2** opening a second Source closes the first. **T3** rows plain and selected. **T4** menus as today. **T5** skeletons under the header; failures without it. **T6** the header with its widths.

States: §2 US-5. Accessibility: D-18.

### Strings

New `L10n.Sources`: `columnTitle` "Title", `columnEvidence` "Evidence", `columnStatus` "Status", `columnType` "Type", `columnPublished` "Published", `columnAdded` "Added", `columnUpdated` "Updated"; `addedHelp(stamp:)` "Added %@"; `addedSpoken(_:)` "added %@"; `addedUnknown` "date added unknown". Removed: Deletes above. No other copy names the sort menu or the summaries (`rg -n "Sorted by" macos/App` finds only the deleted keys).

## 7. Steps

Swift checks run with `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/<Suite> CODE_SIGNING_ALLOWED=NO`.

**STEP-1 — When a Source was made**
Files: `core/database/audit/created.go` (new) and its test, `core/database/sources/sources.go`, `notes.go`, their tests (`notes_test.go` checks the note queries' plans: it now checks `Created`'s), `records_bench_test.go`'s neighbor, `api/ffi/handlers/thumbnails.go`, `api/proto/engine.proto`, generated code, `api/ffi/handlers/sources.go`, `macos/App/Platform/GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift`. Skills: `add-catalog-query`, `add-ffi-handler`.
Do: D-1. `FakeStore.insertSource` sets an empty `createdAt` to `FakeStore.createdAtStamp` *(new, `"2026-11-24T10:00:00Z"`)*, which covers create and copy; `SourcesListPreviews` sets it on its Sources. T-1, T-2.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/... ./api/...` passes; `BenchmarkList` before and after (Scale).

**STEP-2 — One native list behavior**
Files: `macos/App/DesignSystem/Components/List/PVNativeListBehavior.swift` *(new)*, `PVListBody.swift`, `PVListTests.swift`. Skill: `add-ui-component`.
Do: D-10, with `PVListBody` applying it; no visible change.
Check: `PVListTests`, `PersonsListTests`, `SourcesOutlineHostedTests` pass.

**STEP-3 — Kit pieces**
Files: `PVTypography.swift`, `PVBadge.swift`, `SourcesEvidenceStatus+Badge.swift`, `PVLastUpdated.swift` and their tests. Skill: `add-ui-component`.
Do: D-5's `PVMicroCaps`, D-17 but `badge`'s `minWidth`, D-16's `PVListDetail.relative`. T-9.
Check: their tests pass; `PVTable` looks as before.

**STEP-4 — Sort is a column and a direction**
Files: `SourcesListSettings.swift`, `SourcesModel.swift`, `SourcesListView.swift` (the sort Select goes), `L10n.swift`, `Localizable.xcstrings`, tests. Skill: `add-localized-string`.
Do: D-2, D-3 and their Deletes. T-3, T-4.
Check: `SourcesModelTests`, `SourcesListSettingsTests` pass; `python3 scripts/check-localizable-xcstrings.py` passes.

**STEP-5 — One status a Source**
Files: `SourcesModel.swift`, `SourcesOutline.swift` (`SourcesGraphSummary` goes), `SourcesOutlineRows.swift` (the row's tail reads `graphSummaryCount` until STEP-7), `L10n.swift` and `Localizable.xcstrings` (`graphSummary`, `graphSummaryInProgress`, `graphSummaryPromoted`), tests.
Do: D-12. T-5.
Check: `SourcesModelTests`, `SourcesOutlineTests` pass.

**STEP-6 — One open Source**
Files: `WorkspaceSession.swift`, `SourcesOutline.swift`, `SourcesModel.swift` (`outline`'s derived `extra` is `session.openSourceID`), `SourcesListView.swift`, `SourcesListPreviews.swift`, `SourcesOutlineRows.swift`, tests. Skill: `add-workspace-location`.
Do: D-13, D-14. T-6, T-7.
Check: `SourcesOutlineTests`, `SourcesOutlineHostedTests` pass; `rg -n "expandedSourceIDs|setSourcesExpanded" macos` prints nothing.

**STEP-7 — The table**
Files: `SourcesTable.swift` *(new)*, `SourcesListView.swift`, `SourcesOutline.swift`, `SourcesOutlineRows.swift` → `SourcesDisclosureTriangle.swift`, `SourcesListPreviews.swift`, `L10n.swift`, `Localizable.xcstrings`, tests. Skills: `add-ui-component`, `add-localized-string`.
Do: D-4 – D-9, D-16, D-18, `badge`'s `minWidth` and the row Deletes; `SourcesDisclosureTriangle` and `SourcesExpandedState` become internal. Previews: the page's states as today's file has them, at 1102 and 2296, the rows with each badge, one selected. T-8, T-10 – T-12.
Check: the tests pass; render the previews once through a throwaway hosted test (`hostInBorderlessWindow`, `cacheDisplay` to a PNG, as S16-66 did; delete it, commit no image) and report them against T1a, T1b, T3 and T5 in §6's words, widths by AC-1.1 and AC-1.2.

**STEP-8 — A double-click opens the row first pressed**
Files: `SourcesListView.swift`, `SourcesOutlineHostedTests.swift` or `SourcesPointerTests.swift` *(new)*.
Do: D-15. T-13.
Check: the tests pass.

**STEP-9 — The kit sheds what only Sources used**
Files: `PVListBody.swift` (deleted), `PVList.swift`, `macos/App/DesignSystem/Components/ListPageHeader/PVListPage.swift`, `ConclusionListPage.swift`, `PersonsListTests.swift`, `PVIcon.swift` (`PVSymbol.sort`), `PVPublishedDate.swift`, `PVListTests.swift`, `PVPublishedDateTests.swift`. Skill: `add-ui-component`.
Do: D-11 and the kit Deletes. T-14.
Check: `rg -n "PVListBody|leadingHang|titleLeading|PVListMetrics\.hang" macos .agents docs/*.md docs/ideas` prints nothing but STEP-10's docs; `PVListTests`, `PersonsListTests` pass; a Persons row is 66 pt and its thumbnail on the gutter.

**STEP-10 — Version, findings and docs**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj`; `macos/App/DesignSystem/README.md` (List, ListPage, ContextMenu, Badge, LastUpdated and Table rows), `PVActionMenu.swift`'s header, `docs/macos-client-patterns.md` (the `Features/Sources/` line and § 9's Sources lines), `docs/ideas/wide-layout.md`, `docs/ideas/international-names.md` (its `sources.sortedBy` line), `docs/ideas/kit-layering.md` (an entry: nine sites still write `PVTypeScale.micro * PVTracking.caps` by hand; and "Whether `PVTable` follows the native list": a native table exists, its limits), `.agents/skills/add-workspace-location/SKILL.md`, `.agents/skills/add-ui-component/SKILL.md`, the deployment-plan map row, `completed.md`, this plan, `design/` (S16-D14 and its review → `design/archive/`, `design/README.md`).
Do: the next minor after `VERSION` on `main`; per the Definition of done. The Landed note lists, as `works | differs | not checked`: header redraw on sort (D-5), columns fixed (AC-1.9), Page Up/Down, real double-click (AC-4.11), triangle click, VoiceOver by column, opening one Source at the largest catalog.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-71-sources-table.md` reports no errors; `scripts/check-guidance-names.py` passes; `scripts/check-pr.sh` PASS.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period ("Open one Source at a time in the Sources list."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/audit/created_test.go` (new) `TestCreated`; `core/database/sources/sources_test.go` `TestCreatedAt` *(new, tables)* | several ids, one with no create, one created then updated, an id with two creates → the first create's time and user; `List` and `ListByIDs` → the same, unchanged by an update; notes keep their author and time | AC-1.5, D-1 |
| T-2 | Go | `api/ffi/handlers` tests *(extended)* | `created_at` set by `ListSources`, `CreateSource`, `CopySource` and `UpdateSource`, and the same before and after an update | D-1 |
| T-3 | Swift | `SourcesModelTests` `sortsByColumnAndDirection` *(new, table; replaces the sort tests)* | each column both ways over equal titles, undated rows and equal revisions → D-2's order for each; reversing Added and Updated reverses them; equal titles stay id descending; undated last both ways | AC-2.2, AC-2.3 |
| T-4 | Swift | `SourcesListSettingsTests` `anOldSortReadsAsTheDefault` *(new)*, `roundTrip` *(extended)* | `{"sort":"az","query":"x"}` → Added newest first, query `x`; `SourcesSort(column: .published, order: .forward)` round-trips | AC-2.6, D-3 |
| T-5 | Swift | `SourcesModelTests` `oneStatusPerSource` *(new, table)*, `statusFilterMatchesTheBadge` *(new)* | AC-3.1 – AC-3.4's rows; counts loading, failed, graph list failed, no Artifact → nil | US-3, D-12 |
| T-6 | Swift | `SourcesOutlineTests` `oneSourceOpens`, `openingMovesASelectionOffTheClosedGroup` *(new, table)* | AC-4.1, AC-4.5 – AC-4.8, AC-4.10; an open id with no Source draws nothing; `selecting` wins | US-4, D-13 |
| T-7 | Swift | `SourcesOutlineTests` `aPlainClickOpensOneSource` *(replaces `aPlainClickOnAClosedSourceOpensIt`)* | every line of D-14 | AC-4.2 – AC-4.4, AC-4.9 |
| T-8 | Swift | `SourcesTableTests` `widthsFollowTheBoard` *(new, table)* | 1074 → 364 and the Regular widths; 2220 → 1069 and the Wide widths; 772 → 240 | AC-1.1 – AC-1.3, D-6 |
| T-9 | Swift | `PVBadgeTests` `aMinimumWidthHoldsTheBadge` *(new or extended)*, `PVLastUpdatedTests` *(extended)* | fitting width of each badge with `minWidth: 126` is 126; an outlined badge's ink with `\.backgroundProminence` `.increased` is the on-selection ink and a filled one's is not; `PVListDetail.relative` → no icon, the help passed | AC-3.5, AC-1.5 |
| T-10 | Swift | `SourcesOutlineHostedTests` *(moved to the table)*: row heights 66 and 34, → and ←, Return, focus on arrival, search keeps focus, Back to a deep graph in view, a key or modified click opens nothing | each passes on the table; `theRulesRunGutterToGutter` goes (its Persons twin stays) | AC-5.2 – AC-5.4, AC-4.8 |
| T-11 | Swift | `SourcesTableHostedTests` `columnsFitTheirWidths` *(new)* | hosted at 1102, 2296, 1102 again and 800 → the visible columns' titles and widths (±1), no sideways overflow at the first three, the same `NSTableView` throughout, selection kept | AC-1.1 – AC-1.3, AC-1.8 |
| T-12 | Swift | `SourcesTableTests` `headersConvertToTheSort` *(new, table)*; `SourcesTableHostedTests` `theSortedHeaderIsBrighter` *(new)* | each column's first order, a second click's order, an empty set leaves the sort; hosted: the sorted column's `headerCell.attributedStringValue` foreground color differs from the others', and moves to the new column after `settings.sort` changes (D-5's fallback when it does not) | AC-2.1, AC-2.2, AC-2.4 |
| T-13 | Swift | `SourcesPointerTests` *(new, table)* | press then second press within the interval → the first row; after it, `clickCount` 1, or no press → nil; the hosted `select` with a `clickCount` 2 event leaves the anchor and the open Source | AC-4.11, D-15 |
| T-14 | Swift | `PVListTests` *(trimmed)* | `rowInset`; one `detailWidth`; the plain list's rules run gutter to gutter; a wheel step is 66 | D-11 |

Hosted tests keep synchronous main-thread work short and never walk the accessibility tree (S16-66's CI stall). Must stay green: everything `scripts/check-pr.sh` runs; most likely to break: `SourcesOutlineHostedTests`, `PersonsListTests`, `SourcesListStateTests`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (the Deletes keys gone from both)
- [ ] Sweep: every name in Deletes `rg`'d by its qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md`, `docs/ideas/`, `macos/App/DesignSystem/README.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches the brief inventory; no new kit primitive
- [ ] Version in VERSION, core/version.go, MARKETING_VERSION together
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief and its review moved to design/archive/; design/README.md updated
- [ ] Domain docs: the STEP-10 list
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

A project with a Source of 8 graphs (one with no Artifact), several with one, one with no Artifact, one undated, one with a 90-character title; then the user's largest catalog.

1. Regular: columns and widths, header over the gutter, default sort, no sort menu (AC-1.1, AC-1.4, AC-1.5, AC-1.6, AC-1.7, AC-2.1, AC-2.7). Wide, and back across 1600 with a row selected; 800 pt; try to drag and right-click headers (AC-1.2, AC-1.3, AC-1.8, AC-1.9).
2. Click each header twice; the open Source stays open, the selection clears (AC-2.2, AC-2.3, AC-2.4, AC-2.5). Leave, return, relaunch (AC-2.6, AC-4.12).
3. Badges and the status filter over each mix (AC-3.1, AC-3.2, AC-3.3, AC-3.4, AC-3.5).
4. Click closed Sources in turn, one with no triangle, a graph, the triangle of an unselected Source; ⌥-click; close a Source with its graph selected; open another by its triangle (AC-4.1, AC-4.2, AC-4.3, AC-4.4, AC-4.5, AC-4.6, AC-4.9, AC-4.10).
5. **Open the 8-graph Source, then double-click a Source below it, slowly and fast: that Source's page opens and nothing else is selected or opened** (AC-4.11). Repeat near the list's top and bottom.
6. Menus, `Open <graph>` then Back, Back to a graph with another Source open (AC-4.7, AC-4.8, AC-5.5).
7. Selection focused and unfocused, light and dark, each badge on the bar (AC-5.1). ↑ ↓, Page Up, Page Down, Home, End, → and ←, Return, focus on arrival, search focus (AC-5.2, AC-5.3, AC-5.4).
8. First load and a waiting filter on the largest catalog; the failure previews (AC-5.6, AC-5.7).
9. VoiceOver across a Source row and a graph row (AC-5.8).
10. Largest catalog: scroll fast, open and close a Source, move the selection; record any stall.
11. Persons, Events and Places look and work as before, but a selected row's outlined `+N` reads in the on-selection ink.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A second press on a moved row does not reach `onActivate` (AC-4.11) | §10 step 5. Fallback: `openAfterClick` is applied after `NSEvent.doubleClickInterval` when the open Source is above the clicked one; recorded |
| Header text does not redraw with the sort | D-5's fallback |
| A future macOS lays columns out differently | T-11 fails first |

**Stop and report if:**

- `Table`, its customization or its `SortComparator` headers do not compile at macOS 14.0 as D-4 and D-7 say.
- T-11 cannot hold the widths, or the table scrolls sideways at 1102 pt.
- A Back test fails with D-10's second scroll, on two tries.
- STEP-1 adds more than 30 ms to `List` at 3,000 Sources.
- `PVList` has a caller besides `ConclusionListPage` at the base, or `PVListBody` one besides `PVList` and `SourcesListView`.
- Persons, Events or Places change look after STEP-2, STEP-3 or STEP-9, but for the outlined badge on a selected row (D-17).

## 12. Open questions

None. The board settled TB-7 and TB-W1; the user chose fixed column widths, that the status filter matches the badge, and that every outlined badge takes the on-selection ink (2026-11-24).

## 13. PR

**Title:** S16-71 — The Sources list is a native table
**Body:** objective in one sentence; what shipped against US-1 – US-5; AC evidence; STEP-10's findings; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-71-sources-table.md`.
