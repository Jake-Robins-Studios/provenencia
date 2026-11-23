# S16-D12 — The Sources list as a native outline of Sources and Evidence graphs

**Kind:** Claude Design board (**rethink** of the Sources list's body and rows, replacing their frames; the header and toolbar stay as drawn)
**Spike:** Provenencia Spike 16 (odds and ends), batch 6
**View:** the Sources list (header, toolbar, list)
**Implements later as:** PR **S16-66** (The Sources list is a native outline list)
**Board:** to draw, in place on [Claude Design — Sources List](https://claude.ai/artifact/JDm51QdorUvY79EFoci4cm), page *S2-04 Sources list*
**Depends on:** S16-67 ([#958](https://github.com/Jake-Robins-Studios/provenencia/pull/958)): the kit's native list, its selection, on-selection ink and page header
**Related:** [S16-D13](archive/S16-D13-conclusion-lists-native.md) (the same move for Persons, Events and Places: match it); [S15-D2](../../spike-15/design/archive/S15-D2-sources-list.md) (the frames this replaces); [`macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide)
**Rules this brief bends:** § 9 rule 3 (a list with nothing more to show keeps a maximum width at Wide), as S16-D13 did: the list fills the pane at every width, to judge on this board (SO-W1)
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

Replace the Sources list's caption band, rows and graph buttons. Keep the header and the toolbar (search, type, status, sort) as drawn. Do not keep the old three-column row as a before/after.

---

## 1. Objective

The Sources list shows each Source with its Evidence graphs in a column of buttons, so a row grows with its graphs and nothing in it takes the keyboard. It moves onto the **native macOS list**, as the Persons, Events and Places lists did, and is redrawn in the platform's own pattern for this data: an **outline**. Each Source is a row; each of its Evidence graphs is a thinner, indented row under it, as a folder's files are in Finder's list view.

**The one thing that must hold** (user, 2026-11-23): from the Sources list the researcher can go directly to every Evidence graph. Nothing else about today's row must be preserved.

**What stays.** The header and toolbar; sort and filter; what opens (a Source's page, a graph's canvas); Copy… on a Source; the empty, filter-empty and failure copy.

## 2. Domain facts

| Fact | Meaning for the board |
| --- | --- |
| Graphs per Source | Usually **one**. When more, usually **5 to 10** (user). Draw both; two or three is the rare case |
| Source row | Cover (44 pt), title (one line, ellipsis), Type (`Census`), published date (`1851`, or none), last update (`2 days ago`), ref `SRC-4K2QX` |
| Graph row | Network glyph, name (`Default`, `Household of John Robins`), counts as today (subjects and observations), status badge: **Not started**, **In progress** or **Promoted** |
| Source with no Artifact | No graph to open. The Source still opens. Today: "No evidence graph yet · Needs an artifact" |
| Graph with no Artifact linked | Selectable but does not open. Today: "Needs an artifact to open" |
| Loading | The Sources and their graph list are two reads, and the counts a third. The rows appear when the first two are in, so no row arrives late under the pointer; counts fill in afterwards in fixed slots |
| Graph list failed | Sources still show; their graphs cannot. Today: "Evidence graphs · Couldn’t be read" |
| Filters | A type, status or search filter chooses **Sources**. A chosen Source shows all its graphs, not only those with the filtered status |
| Size | Hundreds to several thousand Sources |
| Opening | Double-click a row, or select it and press Return: a Source row opens the Source page, a graph row opens its canvas. Back returns with the row opened from selected and in view |
| Keyboard | The platform's ↑/↓ and Page Up/Down cross Source and graph rows alike. The app adds Home and End (scroll, no selection change). → opens a closed Source and ← closes it, or moves from a graph row to its Source; **expected**, proven in S16-66 |
| Right-click | A Source row's menu holds Copy… and one Open item per graph. A graph row has Open |

### 2.1 What the native list can and cannot draw

As S16-D13 found. Stay inside this table.

| Part | For the board |
| --- | --- |
| Rows | Any kit views at a **fixed height per kind** of row: the Source row 66 pt, as a Persons row; the graph row one fixed height. No wrapping titles, no row that grows |
| Disclosure triangle | Drawn by us in the row's leading area in the platform's manner (a chevron that points down when open). SwiftUI's own disclosure group is **not** used: a spike (2026-11-23) found that rows opened in code arrive late, the arrow keys go wrong, and a deep selection is not restored. The rows are one flat native list |
| Selection | The system's full-width bar in the system accent, grey when unfocused. A selected row's text and triangle draw in the on-selection ink; the cover, badge and thumbnail keep their colors. One row at a time, Source or graph |
| Separators | System hairlines, `borderSubtle`, gutter to gutter, between Source groups. **The board decides** whether graph rows have none or an indented one |
| Surfaces | Rows and list area on `surfaceCard`; header and toolbar as today. No hover, no focus ring, no card, no vertical hairline |
| Insets | The page gutter: 32 pt Regular, 56 pt Wide. Graph rows indent to the title's leading edge |
| Animation | Opening and closing is not animated |

### 2.2 What this board is not

- Not the Source page, the graph canvas, the Add Source or Copy dialogs, or the tables (Source types, Metadata, Properties).
- Not new toolbar controls or columns of new data. Not multiple selection, drag, or editing in a row.

---

## 3. Implementation gate

| S16-66 ships | Not S16-66 |
| --- | --- |
| SO-1 – SO-12, SO-W1, SO-W2 | New filters or sorts, the dialogs, the tables |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| SO-1 | **The page.** Header and toolbar as drawn today, then the list edge to edge across the pane and down to its bottom, as the Persons page. The caption band goes |
| SO-2 | **Source row.** Triangle (or its empty slot), cover, title over one secondary line (Type · published date, what is missing left out), the updated column, the ref. Same geometry as a Persons row |
| SO-3 | **Graph row.** Indented under its Source: glyph, name (truncates first), counts, status badge in one trailing column so the badges line up. **The board decides** one line or two, and its height: prefer the thinnest that reads well |
| SO-4 | **Open or closed at first.** Draw both and let the user choose: **(a)** every Source open; **(b)** a Source with one graph open with no triangle, and a Source with more closed. Under (b) a closed Source shows its graph summary on its row (`8 graphs · 3 in progress`). Recommendation: (a), since a graph must be one step away |
| SO-5 | **Toggling.** Clicking the triangle opens or closes one Source and selects nothing. ⌥-click does all. Draw open and closed |
| SO-6 | **Selection.** A Source row and a graph row selected, focused and unfocused, light and dark. Selecting opens nothing |
| SO-7 | **Opening.** Double-click or Return (§ 2). Caption on SO-6 |
| SO-8 | **Cannot open.** A Source with no Artifact: no graph row, no triangle, and its reason on the secondary line. A graph with no Artifact: a quieter row that says why. Return and double-click do nothing on it |
| SO-9 | **Menu.** The right-click menus of § 2 |
| SO-10 | **Loading and late counts.** Skeleton rows filling the list area in the new geometry, as Persons; a graph row whose counts are not in yet, its badge slot held |
| SO-11 | **Failure and empty.** The graph list's failure as one danger Callout above the rows, the Sources still listed; the whole-list failure, the empty catalog and the no-match state as today, in the list area |
| SO-12 | **Arrival and Back.** The list has keyboard focus on arrival, nothing selected, at its top. Back selects the row opened from, in view, with its Source open. Caption only |
| SO-W1 | **Wide.** Header, toolbar and list span the pane. Draw both for the user: **(a)** the title takes the extra width, as Persons; **(b)** Type and Published become their own columns, on the Source row only |
| SO-W2 | **Wide states.** Skeleton, empty and failure as SO-10 and SO-11, centered or on the gutter as Persons does |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Sources list | Header, toolbar, list filling the pane; Type and date on the secondary line | The same; the row content per SO-W1 (a) or (b) | (b): Type and Published leave the secondary line for columns |

---

## 5. Suggested frames

| Frame | Requirement | Draw |
| --- | --- | --- |
| S1a / S1b | SO-1 – SO-4, SO-W1 | Regular 1102 × 900 and Wide 2296 × 1440, scrolled mid-list: mostly one-graph Sources, one with 8 graphs, one with none. Draw SO-4 (a) and (b) at Regular, and SO-W1 (a) and (b) at Wide under SO-4 (a) |
| S2 | SO-5 – SO-8 | Crops: a Source open, closed and with no Artifact; a Source and a graph selected, focused and unfocused, light and dark; a graph with no Artifact; a 90-character title |
| S3 | SO-9 | The Source menu with several graphs |
| S4a / S4b | SO-10, SO-W2 | Loading, and a crop with counts pending |
| S5a / S5b | SO-11, SO-W2 | Graph list failure; empty; no match |
| S6 | SO-2, SO-3 | Regular pane at 800 wide (a narrow window): nothing may overlap; the title and graph name truncate first |

Beside S1a, note how many Sources are visible against the old frame: the row pair must be judged for length.

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Native list | Component | Extend | `PVList` (`macos/App/DesignSystem/Components/List/PVList.swift`) | Its native list behavior (selection, ink, Home/End, focus) serves both kinds of row; the plan decides how the row slot opens |
| List page header | Component | Ship | `PVListPageHeader` | With description and Add, unchanged |
| Toolbar | Snowflake | Ship | `SourcesListView` | Unchanged: Input and Selects |
| Cover | Component | Ship | `CachedThumbnail` | 44 pt, the type's icon as fallback |
| Published date | Recipe | Ship | `PVPublishedDate` | On the secondary line or in its Wide column |
| Updated column | Recipe | Ship | `PVLastUpdated.detail`, `PVListDetailCell` | As Persons |
| Graph row | Snowflake | Rethink | `SourcesGraphButton` (`macos/App/Features/Sources/SourcesGraphButton.swift`) | Its content as a row, no button frame: Icon, text, Badge. Not a kit component |
| Status badge | Component | Ship | `PVBadge` (`EvidenceStatus`) | Keeps its colors on a selected row |
| Disclosure triangle | Component | Ship | `PVIcon` chevron in a plain button | No new control |
| Right-click menu | Platform | Ship | the list's own context menu | Copy… and the Open items |
| Loading rows | Component | Extend | `PVListSkeleton` | Graph-row skeletons under each |
| Empty, no match | Component | Ship | `PVEmptyState` | As today |
| Failure | Component | Ship | `PVCallout` (`.danger`) with `.pvListPageMessage` | As Persons |

**Non-goals.** No new kit primitive, color or token; no hand-drawn selection or focus ring; no buttons inside rows except the triangle; no row that changes height.

---

## 7. Handoff

When the board is agreed: record it on the **Board** line here and in [`README.md`](README.md), with each "the board decides" choice and the user's SO-4 and SO-W1 picks. The S16-66 plan copies SO-1 – SO-12, SO-W1 and SO-W2 into its Scope and the inventory into its Design, and proves the § 2 "expected" keys. When S16-66 lands, this brief moves to `archive/`.
