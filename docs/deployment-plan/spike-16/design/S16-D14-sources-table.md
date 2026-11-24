# S16-D14 — The Sources list as a native table

**Kind:** Claude Design board (**rethink** of the Sources page's rows, replacing the outline list's frames; the page header stays as drawn, the toolbar loses one control)
**Spike:** Provenencia Spike 16 (odds and ends), batch 6
**View:** the Sources list (header, toolbar, table)
**Implements later as:** PR **S16-71** (The Sources list is a native table)
**Board:** [agreed 2026-11-24](https://claude.ai/artifact/JDm51QdorUvY79EFoci4cm), page *S2-04 Sources list*, frames T1a–T6. The user picked TB-7 **(a)** (Published is a column at Regular too) and TB-W1 **(a)** (the table fills the pane). The board decides: every status badge is one width, 126 pt, its icon and label leading; on a focused selection Not started draws its outline and text in the on-selection ink; the sorted header is one step brighter (`textSecondary`); the header shows over skeleton rows drawn in their columns; Evidence reads a faint `—` while the graph list has failed; the Status minimum is 126. Column edges are not draggable: the widths are fixed per width class (user, 2026-11-24)
**Depends on:** S16-66 ([#962](https://github.com/Jake-Robins-Studios/provenencia/pull/962)): the outline, its open state, its menus and its page states
**Related:** [S16-D12](archive/S16-D12-sources-list-outline.md) (the frames this replaces); [S16-D13](archive/S16-D13-conclusion-lists-native.md) (the native lists); the code spike on branch `spike/sources-table` (2026-11-24, local), which the user tried and liked
**Rules this brief bends:** none. [`macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide) rule 3 is judged on TB-W1
**Design system layers:** [`docs/design-system-layers.md`](../../../design-system-layers.md)
**Skill:** [`add-design-brief`](../../../../.agents/skills/add-design-brief/SKILL.md); [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md); [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md)

Paste this entire document into Claude Design as the requirements for one board. This file is the whole prompt.

### Claude Design — do this first (in order)

Work **in place** on this board. Do not fork a parallel copy of the surface.
- **Rethink** (this brief says replace): throw away the old frames. Do not keep a before/after to ship.
- **Enhancement**: add to the existing frames. Do not start a second composer / graph / page.

1. **Clear this board’s local design-system cache.** Claude Design keeps a stale pack; drawing against it invents local copies of kit controls.
2. **Delete this board’s reference** to the design-system bundle.
3. **Pull a fresh copy** of the Provenencia design system from the main project. Do not continue until the fetched kit lists current components. If the kit looks stale or empty, delete the cache and refetch. Do **not** draw a replacement kit locally.
4. **Compose from that kit.** Instance existing components. Reach for a **bespoke / local** control only when the use is truly this domain. One call site is not a new design-system primitive.

**Reach for (kit).** Instance these first. The **UI building-block inventory** later in this brief names the snowflakes and which kit piece each situation should use.

| Situation | Use |
| --- | --- |
| Labeled value, textarea, or trailing control | Field + TextArea / Input |
| Primary / secondary / ghost action | Button; icon-only → IconButton |
| Choose one from a short list | Select |
| Searchable pick | ComboBox |
| Warning, error, or inline hint | Callout |
| Page- or pane-level empty | EmptyState |
| Confirm replace or destroy | Confirm (`item:` snapshot, not a Bool) |
| Resource delete with inbound check | DeleteImpact recipe (S8-D9 / **S8-13**) — confirm if allowed, notice if blocked |
| Short create / edit form | FormDialog |
| Status / count / polarity mark | Badge; compact token → Chip |
| Cover or file thumb | Thumbnail |
| Grouping / raised or sunken row | Card |
| Section title | SectionHeader |
| Transient after-save notice | Toast |
| Native menu of actions | ContextMenu |
| Record or detail page at Regular and Wide | Page columns |
| Choose one of a few options inline | Segmented control (ChipGroup segmented) |

Do **not** invent a local Field, Button, Card, Select, Callout, or Confirm.

### Two widths — draw both

The window opens at 1366 × 900pt but is often stretched across a large monitor.
Every view has two width classes, measured on the view's own pane (the window
minus the sidebar), not the screen. A view with a side pane (an inspector, a detail
pane) plans that pane inside its Wide frame:

- **Regular** — pane below 1600pt. Draw the pane at 1102 × 900 (the default 1366pt window minus the open sidebar).
- **Wide** — pane 1600pt and up. Draw the pane at 2296 × 1440 (a 2560pt window minus the sidebar).

Draw only the view's own pane. Do not draw the app's sidebar, its navigation items or the window's title bar: they are not part of the board. A frame that needs the toolbar (breadcrumbs, Back and Forward) says so in the brief, and draws only the toolbar above the pane.

Rules for Wide:

1. **The extra space does a job.** Show more at once: a second column of supporting content, the detail beside its list, more grid or table columns, an inspector docked open. If the view truly has nothing to add, center its content. Content jammed to one side with empty space beside it is never the Wide design.
2. **Readable things keep their measure.** Prose, forms and the primary column keep their Regular maximum widths, unless the section opts into Page columns' full-width mode (`primaryFill`: at Wide, with no secondary, the primary fills the pane between the gutters and the header keeps its band; with `fillSplitSideMax` the primary and the band are the main-and-side group the page lays out inside it, as the Source page does); its text still keeps its measure. Wide adds columns; it does not stretch text or fields.
3. **Fill the width only with something useful.** A list, table, grid or canvas takes the extra width when Wide has more to show in it: more columns, more cards, the detail beside the list. When it has nothing more to show, it keeps a maximum width (1600pt of content for a list) and is centered, with the page gutters outside it. Empty space stretched between a row's columns is never the Wide design. Cards keep their size and add columns.
4. **Same content, same actions.** Width changes arrangement only. Anything in the Wide second column is stacked below, in an inspector, or behind a disclosure at Regular.
5. **Crossing the line keeps state.** Selection, scroll position, focus and unsaved edits survive a resize across 1600.
6. **Past every column's maximum, center the group.** Page gutters are never narrower than at Regular; they take what is left.

Draw the **Regular** and **Wide** frame of each view side by side, using the same kit pieces in both.

Replace the Sources list's rows with a table. Keep the page header as drawn. In the toolbar keep search, type and status; the sort menu goes. Do not keep the outline list as a before/after.

---

## 1. Objective

The Sources list is an outline of Sources with their Evidence graphs under them. At Wide it draws Type, Published, updated and ref as columns with nothing to say what they are, because a list has no column headers. It becomes the **native macOS table**: the same outline, with named columns that sort when clicked.

**What stays.** The page header; search, type and status; the outline (a Source row, its graph rows under it); a click on a closed Source selects it and opens its graphs, and a click on the triangle only toggles; a double-click or Return opens a Source's page or a graph's canvas; → and ←; the right-click menus; Back; the empty, no-match, loading and failure states and their copy.

**What changes** (user, 2026-11-24): one Source open at a time; one status badge for a Source, which the status filter matches; a date added column; tighter columns, so the title has the room; no icon on the updated date; the ref under the title; sorting by the headers.

## 2. Domain facts

| Fact | Meaning for the board |
| --- | --- |
| Graphs per Source | Usually one. When more, usually 5 to 10. Hundreds to several thousand Sources |
| Source | Cover (44 pt), title, ref `SRC-4K2QX`, Type (`Census`), published date (`1851`, or `Undated`), date added, last update |
| Graph | Network glyph, name, counts (`12 subjects · 40 observations`), badge: **Not started**, **In progress** or **Promoted**. No type, dates or ref of its own: those cells are empty |
| **One open at a time** | Opening a Source closes the one that was open, however it opens: a click, the triangle, →, the menu's `Open <graph>`, or Back to a graph. A click that selects any other Source row also closes the open one, even when the clicked Source has no triangle. A click on a graph row of the open Source, arrow keys moving the selection, and a sort change close nothing. Closing a Source whose graph is selected selects the Source, unless the same action selects another row (a click on another Source, the menu, Back). ⌥-click no longer opens or closes every Source: it is a click. Every Source starts closed; the open one is held for the session. A filter that hides the open Source leaves it open for when it returns |
| **The rows under the pointer** | When the open Source sits above the one clicked, closing it moves the clicked row up. A double-click still opens the Source first pressed, and its second press opens and selects nothing else; expected, proven in S16-71 (fallback: the rows change only once the double-click time has passed). The board draws nothing for this |
| **A Source's status** | Every graph Promoted → **Promoted**. Every graph Not started → **Not started**. Anything else → **In progress**. The badge is the same open or closed. No badge with no Artifact, while its counts load, or when they failed. A graph with no Artifact counts as Not started, as today's filter reads it |
| **Status filter** | Lists the Sources whose badge is that status (today: any one graph's). Every graph of a listed Source shows |
| **Sort** | Title, Published, Added and Updated sort, both ways, by their headers. Added, newest first, is the default, as today. Graphs stay under their Source in their own order. Undated Sources sort last both ways, as today. A sort or filter change clears the selection and puts the table at its top, as today |
| Date added | The word is **Added**, as the sort menu says today. It is the time the Source was made, from the record of that change, as Updated is from the record of the last one |
| Cannot open | A Source with no Artifact has no triangle; its Evidence cell says `Needs an artifact`. A graph with no Artifact is a faint row, `Needs an artifact to open` in Evidence, no badge; it selects and does not open |
| Late data | The rows appear when the Sources and the graph list are in. Counts fill in afterwards. A Source whose graphs are not in the list yet draws one skeleton graph row when open |
| Failures | Graph list: Sources with no triangles, one Callout above the table; with a status filter, the Callout alone. Counts: `Counts could not load` with the danger mark in each graph's Evidence, no badges; with a status filter, the Callout alone |

### 2.1 What the native table can and cannot draw

Stay inside this table. Rows marked * are S16-71's to prove, with the fallback given; the rest are the spike's findings on macOS 27, with the app's macOS 14.0 minimum.

| Part | For the board |
| --- | --- |
| Header text | Our typeface, weight, color, letter spacing and capitals, set as the kit's micro-caps header. Text only: no icon, menu, filter or button in a header. Leading-aligned, as every cell is |
| Header band | The system's: 28 pt, no fill, a hairline under it, short dividers between columns, the system's sort arrow at the right of the sorted column. The sorted column's text may be brighter*. Do not draw a fill, another height or our own arrow: those need AppKit code this PR does not take on |
| Right end of the header | The system draws a small square over the scroll bar. It stays |
| Rows | Two fixed heights: Source 66 pt, graph 34 pt. No wrapping, no row that grows. A cell holds any kit view in **one column**: nothing spans columns, so a graph's name stays in Title and its counts in Evidence |
| Triangle | Ours, in the Title column before the cover, a 16 pt slot by the row height. It points right closed and down open; not animated |
| Indent | Graph glyph under the Source's title |
| Selection | The system's rounded bar, inset about 10 pt from the table's edges, in the system accent, grey when unfocused. One row. Text and triangle take the on-selection ink; the cover and badges keep their colors. **Not started must read on the bar**: in the spike its outline and text are faint. The board decides how: another existing Badge tone, or that badge's outline and text in the on-selection ink. No new Badge |
| Rules | A system hairline under **every** row, from that row's title edge to the table's right. They cannot be left out between graph rows |
| Background | `surfaceCard`. No stripes, hover, focus ring, card or vertical line in the rows |
| Insets | The whole table, with its header, is inset so the **Title** header's text sits on the page gutter: 32 pt Regular, 56 pt Wide. Triangles start there too |
| Columns | Each has one width at Regular (its ideal) and one at Wide (its maximum); the title takes the rest, from 240. Their edges cannot be dragged: with a range, the platform spreads spare width evenly and the columns drift (probe; user, 2026-11-24). Columns cannot be reordered or hidden by the researcher*. A column can appear at Wide only |
| Keyboard | The platform's ↑ / ↓ and Page Up / Down*; the app's Home and End (scroll, no selection change), → and ←, Return. Focus on arrival; no ring |
| Narrow | When the columns' minimums do not fit, the table scrolls sideways, Title first. At an 800 pt pane it does under TB-7 (a) |

### 2.2 What this board is not

- Not Properties, Metadata or Source types: they keep their own table. Not Persons, Events or Places: they stay lists.
- Not new filters, a search in the window's toolbar, saved column widths, sorting by Type, Evidence or Status, multiple selection, drag, or editing in a row.

---

## 3. Implementation gate

| S16-71 ships | Not S16-71 |
| --- | --- |
| TB-1 – TB-12, TB-W1, TB-W2 | The other tables, the lists, the page header, the dialogs |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| TB-1 | **The page.** Header as drawn; toolbar with search, type and status; the table to the pane's bottom |
| TB-2 | **Columns**, in order: Title, Evidence, Status, Type (Wide only), Published (Wide only under TB-7 (b)), Added, Updated. No Ref column |
| TB-3 | **Title cell, Source.** Triangle, cover, title (one line, ellipsis) over a subtext: the mono ref, and at Regular the type (and, under TB-7 (b), the published date, left out when undated), with a ` · ` between. The type truncates first; the ref and date never truncate |
| TB-4 | **Evidence and Status cells, Source.** `1 graph`, `8 graphs`, or `Needs an artifact`; the one badge (§ 2). No words such as `2 in progress` |
| TB-5 | **Dates.** Published as today (`1851`, faint italic `Undated`). Added and Updated as today's relative words (`2 days ago`, then the date alone: `Nov 21, 2026`; `TimestampFormat` `.relative`), no icon, a faint dash when unknown. Hover: `Last updated …` as today, and `Added …` with the full time |
| TB-6 | **Graph row.** Glyph and name in Title; counts in Evidence; badge in Status, under the Source's badge; the rest empty |
| TB-7 | **Tight columns.** Each column is as wide as its longest usual value; the title takes the rest. Starting points, minimum / ideal / maximum: Evidence 140 / 168 / 240, Status 120 / 128 / 140, Type 100 / 140 / 220, Published 80 / 96 / 160, Added 76 / 92 / 120, Updated 76 / 92 / 120; Title from 240, which counts its triangle and cover. The system puts about 17 pt between columns. The board measures each on the real typefaces and may move them: `12 subjects · 40 observations` and `NOT STARTED` do not truncate at the ideal, and at Regular the title column is at least 360. At Regular draw **(a)** Published as a column and **(b)** Published in the subtext, its column at Wide only; the user picks. (b) cannot sort by date at Regular |
| TB-8 | **Sorted header.** Added newest first (the default), then Title ascending. Sorting leaves rows in the same shapes |
| TB-9 | **One open.** The 8-graph Source open; then another opened and the first closed |
| TB-10 | **Selection.** A Source and a graph selected, focused and unfocused, light and dark, with each of the three badges on the bar |
| TB-11 | **Menus**, as today: Open and Copy…, and on a closed Source `Open <graph name>` per graph. A graph: Open. The per-graph entries stay with one Source open at a time |
| TB-12 | **States.** First load, a waiting filter and late counts: skeletons in the cells, badge slots held. **The board decides** whether the header shows over skeleton rows (fallback: the list's skeleton rows, no header). Failures, empty and no match: today's, with no table header |
| TB-W1 | **Wide.** Type joins as a column. Draw **(a)** the table filling the pane, columns up to their maximums and the title taking the rest, and **(b)** the table centered at 1600 pt of content. Judge the gap between a short title and its Evidence at 2296 (§ 9 rule 3). Recommendation: (a), as the lists do |
| TB-W2 | **Wide states.** As TB-12 |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Sources list | Title (ref and type under it), Evidence, Status, Published (TB-7), Added, Updated | The same with a Type column; TB-W1 (a) or (b) | Type leaves the subtext for its column |

---

## 5. Suggested frames

| Frame | Requirement | Draw |
| --- | --- | --- |
| T1a / T1b | TB-1 – TB-8, TB-W1 | Four frames. T1a, Regular 1102 × 900: TB-7 (a) and (b). T1b, Wide 2296 × 1440, always with the Type and Published columns: TB-W1 (a) and (b). Mostly one-graph Sources, the 8-graph Source open, one with no Artifact, one undated, a 90-character title |
| T2 | TB-9 | Two crops: one Source open, then another |
| T3 | TB-3, TB-6, TB-10 | Crops of a Source and a graph row: plain and selected, focused and unfocused, light and dark, all three badges |
| T4 | TB-11 | The menus |
| T5a / T5b | TB-12, TB-W2 | Loading; late and failed counts; graph list failure with and without a status filter; whole-list failure; empty; no match |
| T6 | TB-7 | The header alone at Regular and Wide with each column's minimum, ideal and maximum written under it, and an 800 pt pane (under TB-7 (a) scrolled to its left) |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Table rows and columns | Snowflake | Rethink | `SourcesListView` (`macos/App/Features/Sources/`) | SwiftUI's `Table` and its columns over the outline's flat rows. One call site: not a kit component. `PVTable` keeps its pages ([`kit-layering.md`](../../../ideas/kit-layering.md) holds whether they follow) |
| Native list behavior | Component | Extend | `PVListBody` (`macos/App/DesignSystem/Components/List/PVListBody.swift`) | Focus on arrival, Home and End, scroll into view, restart at the top, Return and double-click, and the right-click menu move to one kit modifier that `PVListBody` and the Sources table both apply, with the second scroll a deep row needs. Nothing to draw |
| Header text | Token | Extend | `pvMicroCaps()` (`macos/App/DesignSystem/Tokens/PVTypography.swift`) | A `Text` form, which a column title takes; it and the `View` form share one size, weight and tracking, and the capitals follow the locale. `PVTable` does not change |
| Outline, open state, menus, page state | Snowflake | Extend | `SourcesOutline`, `SourcesRowMenu`, `SourcesListState` (`macos/App/Features/Sources/`) | One open id instead of a set, written by one operation; the badge rule, which the status filter reads too; the menus unchanged |
| Page frame, loading and failure areas | Component | Ship | `PVListPage`, `PVListPageArea`, `PVListSkeleton` | Skeleton rows may take the table's columns (TB-12) |
| Toolbar | Snowflake | Extend | `SourcesListView` | Input and two Selects; the sort Select goes |
| Cover | Component | Ship | `CachedThumbnail` | 44 pt |
| Triangle | Snowflake | Extend | `SourcesDisclosureTriangle` | Unchanged look; no ⌥-click |
| Status badge | Component | Extend | `PVBadge` (`EvidenceStatus`) | Source and graph rows; readable on the selection bar |
| Graph counts | Snowflake | Ship | `SourcesGraphCountLine` | `.row` |
| Published date | Recipe | Ship | `PVPublishedDate` | In its cell |
| Updated | Recipe | Extend | `PVLastUpdated` | A form with no icon; the lists keep theirs |
| Added | Component | Ship | `PVListDetailCell` over `TimestampFormat` | Its own hover and spoken words: not `PVLastUpdated`, whose words say "last updated" |
| Right-click menu | Platform | Ship | the table's own context menu | As the list's |
| Empty, no match, failure | Component | Ship | `PVEmptyState`, `PVCallout` | As today |
| List rows of the outline | Snowflake | Remove | `SourcesSourceRow`, `SourcesGraphRow`, `SourcesRowColumns` | With the summary words and the list slots only they used (the map's S16-71 Deletes) |

**Non-goals.** No new kit primitive, color or token; no hand-drawn header, sort arrow, selection or focus ring; no AppKit reach-in; no row that changes height.

---

## 7. Handoff

When the board is agreed: record it on the **Board** line here and in [`README.md`](README.md), with the user's picks (TB-7, TB-W1), the column widths, and each "the board decides" choice. The S16-71 plan copies TB-1 – TB-12, TB-W1 and TB-W2 into its Scope and the inventory into its Design, proves the § 2.1 rows marked * and the double-click row of § 2, and measures opening and closing a Source at the map's Scale. When S16-71 lands, this brief moves to `archive/` and the spike branch is deleted.
