# S15-D11 — Event page: value rows open the provenance sheet

**Kind:** Claude Design board (**enhancement** of the Event page frames: draw on the [Event Detail board](https://claude.ai/artifact/5ciAxv86fYtrUvuCHPuuJ5), page *Event Detail*, as a new turn after "S16-D6 · As-of dates", starting from frames 8a and 8b. Keep every earlier frame as agreed)
**Spike:** Provenencia Spike 15, slice 8
**View:** the Event page's Details rows (Date, Place), and the provenance sheet over the Event page
**Implements later as:** PR **S15-31** (EP-1 – EP-7, EP-2a, EP-W1)
**Board:** agreed 2026-11-27 (user) — [Event Detail board](https://claude.ai/artifact/5ciAxv86fYtrUvuCHPuuJ5), page *Event Detail*, turn "S15-D11 · Value rows open the provenance sheet": frames 1a, 1b, 2, 3a, 3b, 4a, 4b, 5, 6 and the notes EP-1, EP-2, EP-4. Not built (user, 2026-11-27): the Period row's Merged Badge and count, the relationship rows' 28pt end cell, and focus returning to the control after Done; plan § 6
**Depends on:** S15-27 (landed [#1006](https://github.com/Jake-Robins-Studios/provenencia/pull/1006)): the provenance sheet as it is today, with its fold ([S15-D9](S15-D9-provenance-sheet-citations.md), [S15-D17](S15-D17-provenance-table-fold.md)); [S16-D6](../../../spike-16/design/archive/S16-D6-event-date-row.md): the Date row of an event dated by as-ofs
**Related:** working rule "The Why accordion goes" in [`../deployment-plan.md`](../../deployment-plan.md#working-rules); the sibling brief for the Place page, [S15-D12](S15-D12-place-page-provenance-sheet.md), which S15-31 also implements; plan [`../prs/S15-31-event-and-place-provenance-sheet.md`](../../prs/S15-31-event-and-place-provenance-sheet.md). The next brief on this sheet: S15-D18 (records loading on open)
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

Keep the Event page as frames 8a and 8b drew it: the header (event mark, title, date and place line), the Details heading, the Date row with its as-of lines, their Show more row and their Sources, the Place row with its open arrow, and the gallery. Change only the end of each Details row: the **Why** button goes, the sunken Why card that opened under the row goes, and a row with records ends with the provenance control the Person page's Vitals rows already have. Keep the provenance sheet as the Person page board draws it ([Person page board](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ), page *Vitals*, turns 20 and 21); this board shows it over the Event page and does not redraw it.

## 1. Objective

On the Event page, a researcher sees where a value came from the same way as on the Person page: each Details row with records ends with a small ⓘ control, and pressing it opens the provenance sheet for that row, with the formatted citations, the copy buttons and the 50-record fold. The Why disclosure and its inline table are removed from the page. The records are the same ones the Why listed.

**What stays.** The rows' labels, values, state badges, Source counts and disagreement lines; a mixed field's other-values disclosure; the as-of lines and their Show more row; the Place row's open arrow; the page's widths. The sheet itself is unchanged.

## 2. Domain facts

| Fact | Meaning for the board |
| --- | --- |
| **The Event page's Details** | Two rows. **Date**: the event's date, a span, or (S16-D6) its as-of lines with the start and end, each line with its Source count. **Place**: the first kept Place, with an open arrow to that Place's page. |
| **The Why today** | A text button "Why" after the row's value opens a sunken card under the row: a heading ("Why “as of 10 Jan 1990–10 Feb 2015”"), then a table Read as · Source · Outcome with an empty reserved column. It does not fold, so an event with thousands of as-ofs draws every record at once. |
| **The provenance control** | On the Person page's Vitals, each row ends with a 28pt slot holding a small icon-only button (`PVIconButton`, the info glyph). Its tooltip and spoken label are "Provenance of {label}", for example "Provenance of Date". A row with no records keeps the slot empty, so values in the column line up. |
| **The provenance sheet** | An 880pt panel (1280pt at Wide): title (the row's label), the value header (the shown value, state badge, summary such as "3 records"), column headings Read as · Citation · Outcome · Record, the record table that folds at 50 records with "Show 50 more", and Done. A record's citation, Observation and Subject open their places; a link closes the sheet first, so Back returns to the Event page. |
| **Which rows have records** | Date has the records of every property behind the dating (date, start, as-of, end), in one table. Place has none on the Event: its records live on the Place it opens, so its slot is empty and its open arrow stays. A Date with nothing recorded has no records and an empty slot. |
| **Scale** | An event dated by many as-ofs can carry hundreds of records on its Date row; 1,200 is the measured case. The sheet shows 50 and folds the rest. |
| **Example data** | Invented people, places and records only: the residence of "Ada Robins" at "Ottawa County, Kansas", "as of 10 Jan 1990" and "as of 10 Feb 2015" from a "Directory of Ottawa County, 1990" and a "Census of Ottawa County, 2015". Never a real person or a real published citation example. |

### 2.1 What this board is not

- The Place page (S15-D12, drawn on the Place Detail board).
- Records loading when the sheet opens, and their failure (S15-D18, S15-29).
- Any change to the sheet: its title, columns, fold, copy buttons, loading and failed states stay as the Person page board draws them.
- A new provenance control, a text "Sources" link, or a disclosure in place of the Why. The Person page's control as it is.
- A provenance control on the Place row: its records are on the Place.
- A "conclude this value" action in the empty column the Why reserved: that column goes with the Why.

## 3. Implementation gate

| PR | Ships | Not in this PR |
| --- | --- | --- |
| **S15-31** | EP-1 – EP-7, EP-W1 on the Event page, with S15-D12's Place page requirements | Records on open (S15-29), every other view |

## 4. Requirements

| ID | Requirement |
| --- | --- |
| EP-1 | **The control.** A Details row with records ends with the provenance control in a 28pt slot after the row's other controls, as on the Person page's Vitals: small icon-only button, info glyph, tooltip "Provenance of Date". It is centered vertically on the row, so on a Date row of several as-of lines it sits beside the middle of the lines. |
| EP-2 | **No records, empty slot.** A row with no records (the Place row; a Date with no record on any dating property) keeps the 28pt slot empty, so the values and state columns of both rows line up. The Place row keeps its open arrow before the empty slot. |
| EP-2a | **Empty value, records behind it.** A Date that reads "No date recorded" because every record was denied or not shown still has records: its row ends with the control, and the sheet lists those records. |
| EP-3 | **The Why goes.** No "Why" button on any row, and nothing opens under a row except a mixed field's other values and the as-of lines' Show more. |
| EP-4 | **The sheet over the Event page.** Pressing the control opens the provenance sheet for that row over the dimmed Event page: title "Date", the row's shown value in the value header (the span, or the as-of lines as the row lists them), the summary, and the records of every property behind the dating in one table. |
| EP-5 | **Long tables fold.** A Date row with more than 50 records opens on 50 records and the sheet's "Show 50 more", as the Person page's sheet does. |
| EP-6 | **Leaving the sheet.** Done closes the sheet. A record's link closes the sheet and opens its place; Back returns to the Event page. |
| EP-7 | **Keyboard and VoiceOver.** Tab in a row goes through its controls in order (other values, the open arrow, then the provenance control), as on the Person page. Return or Space on the control opens the sheet. VoiceOver reads it as the button "Provenance of Date". |
| EP-W1 | **Wide.** The Event page at Wide stays centered at its Regular measure, as today (it has one column of rows and nothing to add); the slot sits at the end of each row in both widths. The sheet is 1280pt at Wide, as on the Person page. |

### 4.1 Wide layout

| View | Regular | Wide | What moves |
| --- | --- | --- | --- |
| Event page | One column: header, Details rows ending with the 28pt slot, gallery | The same column, centered at the Regular measure | Nothing moves: the page has no supporting content for a second column |
| Provenance sheet over the Event page | 880pt panel | 1280pt panel | Nothing moves (the sheet is a modal panel) |

## 5. Suggested frames

Each frame is the pane only (no sidebar): 1102 × 900 at Regular, 2296 × 1440 at Wide.

| Frame | Shows |
| --- | --- |
| 1a — Regular | Frame 8a's as-of event with the Why gone: the Date row's lines with their Sources and the provenance control at the row's end; the Place row with its open arrow and an empty slot; values aligned |
| 1b — Wide | Frame 1a at Wide, centered |
| 2 — A dated event | An event with one date ("12 Mar 1851", 2 Sources): the Date row ends with the control; the Place row's slot empty |
| 3a — Nothing recorded | A Date with no records: "No date recorded" and an empty slot |
| 3b — Nothing shown, records behind it | A Date whose two records were both denied: "No date recorded" and the control |
| 4a — The sheet, Regular | Frame 1a with the sheet open on the Date row: title "Date", the as-of lines in the value header, "3 records", the table |
| 4b — The sheet, Wide | Frame 4a at Wide: the 1280pt panel |
| 5 — Folded | The sheet on a Date row with 1,200 records: 50 records and "Show 50 more" at the table's foot |
| 6 — Spoken | Annotations: Tab order in each row, the control's spoken label, the empty slot skipped by VoiceOver, and that Back after a link returns to the Event page |

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Details row | Snowflake | Ship | `macos/App/Features/Conclusions/ReconciledValueRow.swift` `ReconciledValueRow` | As the Person page draws it, now on every page: ends with the 28pt provenance slot; the Why button goes |
| Provenance control | Component | Ship | `macos/App/DesignSystem/Components/IconButton/PVIconButton.swift` (`.info`, `.sm`) | The Person page's control, as it is. Not a text button, a disclosure or a new glyph |
| Why disclosure | Component | Remove | `PVDisclosureButton` "Why" on the row | The disclosure itself stays in the kit for other values |
| Why card and its table | Snowflake | Remove | `Features/Conclusions/ReconciliationReasoningView.swift`, `ReconciliationRecordRows.swift` | Gone; the sheet's table replaces them |
| Reserved column | Recipe part | Remove | `PVProvenanceReservedCell` | The Why's empty fourth column; nothing else draws it |
| Provenance sheet | Recipe | Ship | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheet.swift` | As the Person page board draws it; opened from the Event page |
| Sheet presenter | Snowflake | Ship | `Features/Conclusions/ReconciledValueRow.swift` `ConclusionDetailRowsSection` (its sheet), with `ProvenanceSheetHost.swift` as the sheet's content | The Person page's presenter, now on every Details section |

**Non-goals.** No new kit primitive, no new string, no change to the sheet or to `PVIconButton`. No control on the Place row. No inline record table on the page.

## 7. Handoff

When the board is agreed: record the board link, its turn and agreed frames on the **Board** line above and in [`README.md`](../README.md); the plan [`../prs/S15-31-event-and-place-provenance-sheet.md`](../../prs/S15-31-event-and-place-provenance-sheet.md) copies any board decision into its Design and moves from `Blocked — on board S15-D11, S15-D12` to `Planned` once S15-D12 is agreed too. When S15-31 lands, move this brief to `design/archive/` and note it in `completed.md`.
