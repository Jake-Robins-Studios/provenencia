# S15-D28 — Source types list: its columns and its Wide layout

**Kind:** Claude Design board (**enhancement** of the Source types list as S15-48 left it: the header with Add type, and a table with Label, Key and Associated fields, across the whole pane with no side pane. Add one column at every width, one more at Wide, and give the list its first Wide frame)
**Spike:** Provenencia Spike 15, slice 2
**View:** the Source types list (the workspace's Source types destination: header, table, result footer)
**Implements later as:** PR **S15-49**
**Board:** agreed 2026-11-15 (user) — [Claude Design — Source Types](https://claude.ai/artifact/R94Wfp97eC9cBLaSNBQEga): page *S2-03 Source Types Board*, section "01 Columns, sort and the Wide band" (frames L1a – L4b with notes), component *Source Types List*. As the brief asked, with one addition: the full description is a hover tooltip on its cell
**Depends on:** S15-48 (landed [#848](https://github.com/Jake-Robins-Studios/provenencia/pull/848)): the list has no side pane, and a click or Return on a row opens the type's own page
**Related:** working rule "A Source type has its own page" in [`../deployment-plan.md`](../../deployment-plan.md#working-rules); S15-D2 (the Sources list's Wide frame, [archived](S15-D2-sources-list.md)), the nearest list of this kind; S15-D27 (the type's page, [archived](S15-D27-source-type-page.md)); S15-D6 (S15-12 makes Associated fields count all three suggestion levels; its header and cells are unchanged); [`macos-client-patterns.md` § 9](../../../../macos-client-patterns.md#9-window-widths-regular-and-wide); plan [`../prs/S15-49-source-types-list.md`](../../prs/S15-49-source-types-list.md)
**Design system layers:** [`docs/design-system-layers.md`](../../../../design-system-layers.md)
**Skill:** [`add-design-brief`](../../../../../.agents/skills/add-design-brief/SKILL.md); [`add-ui-component`](../../../../../.agents/skills/add-ui-component/SKILL.md)

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

### This brief is an enhancement

Add to the Source types list's frames. Keep the header (title, description, count line, Add type), the table's look (sunken header row, hairline rows, the keyboard highlight's accent bar), the footer and the Label cell (the type's mark, its label, the origin pill). Do not start a second list, and do not draw the type's page again: S15-D27's frames stand.

---

## 1. Objective

The Source types list lost its side pane in S15-48: a row now opens the type's own page. The list is left with three columns across the whole pane, and at Wide it stretches those three across 2296pt with nothing between them. After this board the list shows, at a glance, how much each type is used, and at Wide it reads each type's description too, centered in a band the way the Sources list is.

**What changes.**

- **Used by** *(new column, every width)*: how many Sources are classified as the type. Sortable (user, 2026-11-15).
- **Description** *(new column, Wide only)*: the type's description on one line (user, 2026-11-15).
- **Wide:** the header, the table and the footer center at 1600pt of content with a hairline down each side, as the Sources list does (user, 2026-11-15).

**What stays.** The origin stays a pill in the Label cell; it gets no column of its own (user, 2026-11-15). Sorting by Label, Key and Associated fields behaves as today: a click on a header sorts by it ascending, a second click reverses it. A click or Return on a row opens its page; the arrow keys only move the highlight. The footer's "30 types". The empty project and load-failure states. The Metadata page's list is not part of this board.

---

## 2. Domain facts

| Fact | What it means on this board |
| --- | --- |
| Source type | A kind of record (Census, Book, Letter, Parish register). A project has about 30 (the seed has 26). Origin "Provenencia" (seeded), the researcher's own (no pill) or a plugin's (a pill naming it). |
| Key | Minted from the label once (`census`); mono, truncated in the middle when long. |
| Associated fields | How many metadata fields the type suggests. A number, or "—" when none. |
| Used by | How many Sources are classified as the type: 0 to a few hundred. A number, or "—" when no Source uses it. A type in use cannot be deleted (the page says so); the list only shows the count. |
| Description | Optional; a line or two in the researcher's words. About a third of the seeded types have one longer than 80 characters. Empty for some of the researcher's own types. |
| Sort | One column at a time, ascending or descending, held while the list is open. Ties (two types with the same count) sort by label, in the column's direction, as Associated fields does today. |

### 2.1 Copy

Every string is today's unless marked *(new)*.

| Where | Text |
| --- | --- |
| Column headers | "Label", "Key", "Associated fields", "Used by" *(new)*, "Description" *(new, Wide only)* |
| Used by cell | "41"; "—" when 0 (the same dash Associated fields shows) |
| Description cell | The description on one line, cut with "…" at the column's end; nothing when the type has none |
| Footer | "30 types" |

### 2.2 What this board is not

- The Source type page (S15-D27, drawn).
- What Associated fields counts (S15-D6 → S15-12 counts all three suggestion levels; the column looks the same).
- A detail beside the list at Wide (§ 9's long-term "List → detail page" pattern): not planned for Source types; the page opens in place of the list.
- Filters, search in the list, or column resizing: the omnibar finds a type.
- The Metadata page's list.

---

## 3. Implementation gate

| PR | Ships | Not that PR |
| --- | --- | --- |
| **S15-49** | TL-1 – TL-4, TL-W1, TL-W2: the Used by column and its sort, the Wide band, the Description column at Wide | The type page (S15-48, landed); the three suggestion levels and their count (S15-12) |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| TL-1 | **Columns at Regular.** Label (the mark, the label, the origin pill; fills what is left), Key (about 160pt, mono), Associated fields (about 132pt, mono number or "—"), Used by *(new)* (about 120pt, mono number or "—"), in that order. Used by is the last column. |
| TL-2 | **Used by sorts.** Its header sorts like the others: first click ascending (least used first), second click descending; types with the same count by label, in the same direction (Associated fields' rule today). The header's sort arrow sits on Used by while it is the sort. |
| TL-3 | **Description is not a sort.** Its header has no sort arrow and does not respond to a click. |
| TL-4 | **States.** The empty project (no types yet), loading and a failed load keep today's look; at Wide they sit inside the band (TL-W1). Draw the empty project only (frames 4a / 4b): loading is a centered spinner and a failed load today's danger Callout under the header, neither redrawn. |
| TL-W1 | **Wide, the band.** At Wide the header, the table and the footer center at 1600pt of content plus the page gutters, with a hairline down each side of the band (the Sources list's band). Nothing stretches past it. |
| TL-W2 | **Wide, Description.** At Wide a Description column sits between Label and Key, sharing the free width with Label. One line, muted, cut with "…"; empty when the type has none. At Regular there is no Description column and nothing replaces it (the page shows the description). |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Source types list | Header, table and footer across the pane; Label · Key · Associated fields · Used by | Centered at 1600pt of content with hairlines; Label · Description · Key · Associated fields · Used by | Description is added at Wide (rule 1: more table columns); at Regular it is on the type's page |

---

## 5. Suggested frames

Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440). Pane only: no toolbar, no sidebar.

**Data.** About 30 types. Census (Provenencia, 3 fields, used by 41); Book (Provenencia, 3 fields, used by 18, description "A published monograph, read in print or as a scan of the printed edition."); Letter (Provenencia, no fields, used by 0); Family scrapbook (yours, 1 field, used by 3, no description); Grave memorial (plugin `findagrave`, 4 fields, used by 5); Parish register (yours, no fields, used by 0). Invent the rest, with a few long descriptions.

| Frame | Requirement | Draw |
| --- | --- | --- |
| 1a / 1b | TL-1, TL-W1, TL-W2 | The list sorted by Label, Book highlighted by the keyboard; include Grave memorial (plugin pill) with a long description, so Label and Description share the width |
| 2a / 2b | TL-2 | Sorted by Used by, descending: Census first; Parish register and Letter last, in that order (ties follow the direction) |
| 3 | TL-3 | Wide: the pointer over the Description header, with no sort affordance |
| 4a / 4b | TL-4 | The empty project, at both widths |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Header | Snowflake | Ship | `VocabularyHeader` in `macos/App/Features/CatalogVocabulary/VocabularyChrome.swift` | As today; inside the band at Wide |
| Table | Component | Ship | `macos/App/DesignSystem/Components/Table/PVTable.swift` (`PVTableColumn`, `PVTableSort`) | The new columns are `PVTableColumn`s; a column with no width shares the free width. No new table, no hand-drawn header |
| List shell and footer | Snowflake | Ship | `VocabularyListPane` in `macos/App/Features/CatalogVocabulary/VocabularyListPane.swift` | Its columns are parameters; the Metadata page shares it unchanged |
| Columns | Snowflake | Extend | `macos/App/Features/SourceTypes/SourceTypesListPane.swift` | Used by, and Description at Wide |
| Label cell | Component | Ship | `PVMark` + `OriginPill` (`macos/App/Features/Catalog/OriginMarkers.swift`) | As today; origin is not a column |
| Count cells | Snowflake | Extend (one cell for both count columns) | the Associated fields cell's text: the kit's mono type at the micro size (`PVFont.mono`, `PVTypeScale.micro`), secondary color, faint for "—" | Used by and Associated fields share one count cell; "—" for 0 |
| Wide band | Component | Ship (a second caller) | `.pvListBand(_:)` in `macos/App/DesignSystem/Components/PageColumns/PVPageColumns.swift`, `PVSpacing.widthListWideMax` | TL-W1; the Sources list is the first caller |
| Empty state | Component | Ship | `PVEmptyState` | As today |
| Load failure | Component | Ship | `PVCallout` (danger) | As today |

**Non-goals.** No new kit primitive. No Origin column. No detail beside the list. No column filter or resizing. No change to the Metadata page's list.

---

## 7. Handoff

When the board is agreed: record its link, frames and any answer the board gave on the **Board** line here and in [`README.md`](../README.md). S15-49's plan copies TL-1 – TL-4, TL-W1, TL-W2 and the inventory, checks D-2 and D-3 against the frames, and moves from `Blocked — on board S15-D28` to `Planned`. When S15-49 lands, this brief moves to the spike's design archive.
