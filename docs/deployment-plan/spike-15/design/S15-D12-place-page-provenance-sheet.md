# S15-D12 — Place page: value rows open the provenance sheet

**Kind:** Claude Design board (**enhancement** of the Place page frames: draw on the [Places Detail board](https://claude.ai/artifact/WTfDyrGRH2PEtXyhY2KJtt), page *Place Detail*, as a new turn after the last agreed one, starting from its Regular and Wide Place page frames. Keep every earlier frame as agreed)
**Spike:** Provenencia Spike 15, slice 8
**View:** the Place page's Details rows (Names, Period), and the provenance sheet over the Place page
**Implements later as:** PR **S15-31** (PP-1 – PP-7, PP-W1)
**Board:** agreed 2026-11-27 (user) — [Places Detail board](https://claude.ai/artifact/WTfDyrGRH2PEtXyhY2KJtt), page *Place Detail*, turn "S15-D12 · Place page — value rows open the provenance sheet": frames 1a, 1b, 2a, 2b, 3a, 3b, 3c, 4, 5 and the notes PP-1, PP-3, PP-4. Not built (user, 2026-11-27): the Period row's Merged Badge and count, the relationship rows' 28pt end cell, and focus returning to the control after Done; plan § 6
**Depends on:** S15-27 (landed [#1006](https://github.com/Jake-Robins-Studios/provenencia/pull/1006)): the provenance sheet as it is today, with its fold ([S15-D9](archive/S15-D9-provenance-sheet-citations.md), [S15-D17](archive/S15-D17-provenance-table-fold.md))
**Related:** working rule "The Why accordion goes" in [`../deployment-plan.md`](../deployment-plan.md#working-rules); the sibling brief for the Event page, [S15-D11](S15-D11-event-page-provenance-sheet.md), which S15-31 also implements; plan [`../prs/S15-31-event-and-place-provenance-sheet.md`](../prs/S15-31-event-and-place-provenance-sheet.md); [`../provenance-loading.md`](../provenance-loading.md) (a Place's name row grows with the catalog). The next brief on this sheet: S15-D18 (records loading on open)
**Design system layers:** [`docs/design-system-layers.md`](../../../design-system-layers.md)
**Skill:** [`add-design-brief`](../../../../.agents/skills/add-design-brief/SKILL.md); [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md)

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

Keep the Place page as its agreed frames draw it: the header (place mark, name, parent chain), the Details heading, the Names row with every kept name and its Sources, its Show more row past 20 names, the Period row, the gallery, and the Part of, Contains and Succession sections. Change only the end of each Details row: the **Why** button goes, the sunken Why card that opened under the row goes, and a row with records ends with the provenance control the Person page's Vitals rows already have. Keep the provenance sheet as the Person page board draws it ([Person page board](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ), page *Vitals*, turns 20 and 21); this board shows it over the Place page and does not redraw it.

## 1. Objective

On the Place page, a researcher sees where a name or the period came from the same way as on the Person page: each Details row with records ends with a small ⓘ control, and pressing it opens the provenance sheet for that row, with the formatted citations, the copy buttons and the 50-record fold. The Why disclosure and its inline table are removed from the page. The records are the same ones the Why listed. A Place cited by hundreds of records opens on 50 instead of drawing all of them inline.

**What stays.** The rows' labels, values, Source counts and badges; the Names row's list of kept names and its Show more row; the relationship sections and their rows; the page's widths. The sheet itself is unchanged.

## 2. Domain facts

| Fact | Meaning for the board |
| --- | --- |
| **The Place page's Details** | Two rows. **Names**: every kept name, each with its Source count ("Toronto · 3 Sources", "Tkaronto · 1 Source"); past 20 names a Show more row. **Period**: the span from the Place's start and end dates ("1793–1834"), or "No period recorded". |
| **The Why today** | A text button "Why" opens a sunken card under the row: a heading ("Why these 2 names", "Why “1793–1834”"), then a table Read as · Source · Outcome with an empty reserved column. It does not fold, so a Place whose name every record cites draws every record inline. |
| **The provenance control** | On the Person page's Vitals, each row ends with a 28pt slot holding a small icon-only button (`PVIconButton`, the info glyph). Its tooltip and spoken label are "Provenance of {label}", for example "Provenance of Names". A row with no records keeps the slot empty, so values in the column line up. |
| **The provenance sheet** | An 880pt panel (1280pt at Wide): title (the row's label, "Names"), the value header (the shown values, state badge, summary such as "merged from 3 Sources · 4 records"), column headings Read as · Citation · Outcome · Record, the record table under one heading per kept name, then the records that count under no shown name (a weak spelling), folded at 50 records with "Show 50 more", and Done. A record's links close the sheet first, so Back returns to the Place page. |
| **Which rows have records** | Names has every record of the Place's name property; Period has the records of its start and end dates in one table. A row with nothing recorded has no records and an empty slot. The relationship rows (Part of, Contains, Succession) have no Why today and get no control. |
| **Scale** | A Place's name row reads every Observation on that Place, so it grows with the catalog: 300 records is ordinary, 1,200 is the measured case. The sheet shows 50 and folds the rest. |
| **Example data** | Invented places and records only: "York" with the names "Toronto" (3 Sources), "Tkaronto" (1 Source) and a weak spelling "Torento" from "Letter, 1793"; a period "1793–1834". Never a real published citation example. |

### 2.1 What this board is not

- The Event page (S15-D11, drawn on the Event Detail board).
- Records loading when the sheet opens, and their failure (S15-D18, S15-29).
- Any change to the sheet: its title, columns, fold, copy buttons, loading and failed states stay as the Person page board draws them.
- A new provenance control, a text "Sources" link, or a disclosure in place of the Why. The Person page's control as it is.
- A control on the relationship rows, or any change to the Part of, Contains and Succession sections.
- A "conclude this value" action in the empty column the Why reserved: that column goes with the Why.

## 3. Implementation gate

| PR | Ships | Not in this PR |
| --- | --- | --- |
| **S15-31** | PP-1 – PP-7, PP-W1 on the Place page, with S15-D11's Event page requirements | Records on open (S15-29), every other view |

## 4. Requirements

| ID | Requirement |
| --- | --- |
| PP-1 | **The control.** A Details row with records ends with the provenance control in a 28pt slot after the row's other controls, as on the Person page's Vitals: small icon-only button, info glyph, tooltip "Provenance of Names" or "Provenance of Period". It is centered vertically on the row, so on a Names row of many names it sits beside the middle of the list. |
| PP-2 | **No records, empty slot.** A row with no records ("No period recorded") keeps the 28pt slot empty, so the values of both rows line up. A row whose value is empty but which holds records (every record denied) ends with the control. |
| PP-3 | **The Why goes.** No "Why" button on any row, and nothing opens under a row except the Names row's Show more, and a field's other values when it has them. |
| PP-4 | **The sheet over the Place page.** Pressing the control opens the provenance sheet for that row over the dimmed Place page. Names: title "Names", the kept names in the value header, one value heading per kept name over its records, then the records under no shown name (the weak "Torento"). Period: title "Period", the span in the value header, the start and end dates' records in one table. |
| PP-5 | **Long tables fold.** A Names row with more than 50 records opens on 50 records and the sheet's "Show 50 more", as the Person page's sheet does. |
| PP-6 | **Leaving the sheet.** Done closes the sheet. A record's link closes the sheet and opens its place; Back returns to the Place page. |
| PP-7 | **Keyboard and VoiceOver.** Tab in a row goes through its controls in order, the provenance control last, then the row's Show more, as on the Person page. Return or Space on the control opens the sheet. VoiceOver reads it as the button "Provenance of Names". |
| PP-W1 | **Wide.** The Place page at Wide stays centered at its Regular measure, as today (its Details and relationship sections are one column of rows with nothing to add); the slot sits at the end of each Details row in both widths. The sheet is 1280pt at Wide, as on the Person page. |

### 4.1 Wide layout

| View | Regular | Wide | What moves |
| --- | --- | --- | --- |
| Place page | One column: header, Details rows ending with the 28pt slot, gallery, relationship sections | The same column, centered at the Regular measure | Nothing moves: the page has no supporting content for a second column |
| Provenance sheet over the Place page | 880pt panel | 1280pt panel | Nothing moves (the sheet is a modal panel) |

## 5. Suggested frames

Each frame is the pane only (no sidebar): 1102 × 900 at Regular, 2296 × 1440 at Wide.

| Frame | Shows |
| --- | --- |
| 1a — Regular | York with the Why gone: the Names row listing "Toronto" and "Tkaronto" with their Sources and the provenance control at the row's end; the Period row "1793–1834" with its control; values aligned; the relationship sections unchanged |
| 1b — Wide | Frame 1a at Wide, centered |
| 2 — No period | A Place with no start or end date: "No period recorded" and an empty slot |
| 3a — The sheet, Regular | Frame 1a with the sheet open on Names: title "Names", both names in the value header, a heading per name over its records, the weak "Torento" record under the records that count under no shown name |
| 3b — The sheet, Wide | Frame 3a at Wide: the 1280pt panel |
| 4 — Folded | The sheet on a Names row with 1,200 records: 50 records and "Show 50 more" at the table's foot |
| 5 — Spoken | Annotations: Tab order in each row, the control's spoken label, the empty slot skipped by VoiceOver, and that Back after a link returns to the Place page |

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Details row | Snowflake | Ship | `macos/App/Features/Conclusions/ReconciledValueRow.swift` `ReconciledValueRow` | As the Person page draws it, now on every page: ends with the 28pt provenance slot; the Why button goes |
| Provenance control | Component | Ship | `macos/App/DesignSystem/Components/IconButton/PVIconButton.swift` (`.info`, `.sm`) | The Person page's control, as it is. Not a text button, a disclosure or a new glyph |
| Why disclosure | Component | Remove | `PVDisclosureButton` "Why" on the row | The disclosure itself stays in the kit |
| Why card and its table | Snowflake | Remove | `Features/Conclusions/ReconciliationReasoningView.swift`, `ReconciliationRecordRows.swift` | Gone; the sheet's table replaces them |
| Reserved column | Recipe part | Remove | `PVProvenanceReservedCell` | The Why's empty fourth column; nothing else draws it |
| Provenance sheet | Recipe | Ship | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheet.swift` | As the Person page board draws it; opened from the Place page |
| Sheet presenter | Snowflake | Ship | `Features/Conclusions/ReconciledValueRow.swift` `ConclusionDetailRowsSection` (its sheet), with `ProvenanceSheetHost.swift` as the sheet's content | The Person page's presenter, now on every Details section |
| Relationship rows | Snowflake | Ship | `Features/Conclusions/PlaceRelationshipRow.swift` | Unchanged; no control |

**Non-goals.** No new kit primitive, no new string, no change to the sheet or to `PVIconButton`. No control on the relationship rows. No inline record table on the page.

## 7. Handoff

When the board is agreed: record the board link, its turn and agreed frames on the **Board** line above and in [`README.md`](README.md); the plan [`../prs/S15-31-event-and-place-provenance-sheet.md`](../prs/S15-31-event-and-place-provenance-sheet.md) copies any board decision into its Design and moves from `Blocked — on board S15-D11, S15-D12` to `Planned` once S15-D11 is agreed too. When S15-31 lands, move this brief to `design/archive/` and note it in `completed.md`.
