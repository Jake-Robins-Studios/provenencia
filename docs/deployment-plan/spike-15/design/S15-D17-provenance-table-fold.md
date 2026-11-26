# S15-D17 — Provenance sheet: the record table's fold

**Kind:** Claude Design board (**enhancement** of the provenance sheet as S15-D9 left it: draw on the [Person page board](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ), page *Vitals*, as a new turn after turn 20 "S15-D9 · Provenance sheet — formatted citations", starting from frames 20a and 20c. Keep every S15-D9 frame as agreed)
**Spike:** Provenencia Spike 15, slice 8
**View:** the provenance sheet (a sheet over the Person page; the same sheet opens from Event and Place rows after S15-31)
**Implements later as:** PR **S15-27** (RF-1 – RF-8, RF-W1)
**Board:** agreed 2026-11-26 (user) — [Person page board](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ), page *Vitals*, turn 21 "S15-D17 · Provenance sheet — the record table's fold": frames 21a – 21g, 21i, 21j and the notes Kit, RF-4, RF-3, RF-6, Scroll area. Frame 3 shows "Show 20 more" after one press of 120 runs (the brief's "two presses" needed about 170 runs); frame 5, owner groups, is not drawn. Where the app departs from a note (the scroll after a keyboard press goes into view, not to the top; the row keeps the record row's padding): plan § 6
**Depends on:** S15-21 (landed [#930](https://github.com/Jake-Robins-Studios/provenencia/pull/930)): the formatted citations and their same-citation runs ([S15-D9](archive/S15-D9-provenance-sheet-citations.md)); S15-30 (landed [#996](https://github.com/Jake-Robins-Studios/provenencia/pull/996)): the kit's Show more row
**Related:** working rule "The provenance table folds a page at a time" in [`../deployment-plan.md`](../deployment-plan.md#working-rules); [`../provenance-loading.md`](../provenance-loading.md) "Cap the records a provenance table draws"; plan [`../prs/S15-27-provenance-table-fold.md`](../prs/S15-27-provenance-table-fold.md). The next brief on this sheet: S15-D18 (records loading on open)
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

Keep the sheet as S15-D9 drew it: the title, the value header (shown value, state badge, summary), the column headings, owner lines, value headings, the formatted citations with their Full and Short buttons, the same-citation runs with no rule inside them, the record area's loading and failed states, and Done. Add only the fold: where the table stops, the Show more row that ends it, and what one press reveals.

## 1. Objective

A value with hundreds or thousands of records opens its provenance sheet quickly. The record table shows its first 50 citations (a citation is a run of records whose full citations read the same, or a record alone) and ends with the kit's Show more row, "Show 50 more". Each press reveals the next 50 citations under the ones already shown. A citation is never split: all its records show, or none do. From the keyboard, a press moves focus to the first citation it revealed and scrolls it into view; a pointer click leaves focus and scroll where they are.

**What stays.** A table of 50 citations or fewer draws exactly as today, with no Show more row. The header's summary counts every record ("merged from 2 Sources · 1,200 records"), not only the shown ones. The sheet keeps its widths and its 560pt scroll area.

## 2. Domain facts

| Fact | Meaning for the board |
| --- | --- |
| **The sheet today** | S15-D9's frames: an 880pt panel (1280pt at Wide); header; column headings Read as · Citation · Outcome · Record; the record table scrolls inside at most 560pt; Done at the foot. Every record draws at once. |
| **A citation run** | Records whose full citations read the same (one household row of a census page) sit together with no rule between them. A record whose type has no format is a run of one. The fold counts runs, not records: 50 runs may hold 50 records or 140. |
| **Owner lines and value headings** | A derived row (a Birth date read off two Events) splits the table under owner lines; a field with several values splits it under value headings. The fold counts runs across the whole table, in table order, through these lines. A line draws when at least one of its runs shows, or when it holds no runs and nothing before it is folded. When the fold falls inside a value's runs, the heading shows over the shown runs, and the runs a press reveals continue under the same heading: the heading is not repeated. |
| **The kit's Show more row** | `PVShowMoreRow`: a ghost, small, borderless Button worded "Show N more", where N is the next page (50, or the remainder when fewer are left). It is the same row the Person page's Family, Timeline and Sources sections end with. Return and Space press it. |
| **Scale** | A Place's name row reads every Observation on that Place, so it grows with the catalog: 300 records is ordinary, 1,200 is the measured case. Today 1,200 records take seconds to draw. |
| **Example data** | Invented people, places and records only: "Ada Robins", "Ottawa County, Kansas", "Census of Canada West, 1851". Never a real person or a real published citation example. |

### 2.1 What this board is not

- Records loading when the sheet opens, and their failure (S15-D18, S15-29).
- The Event and Place pages (S15-D11, S15-D12).
- A fold inside a citation run, a "Show all" button, a page number, a count of hidden records, or a collapse back to 50.
- A new Show more control: the kit's row as it is.
- Any change to the copy buttons, the columns or the loading and failed states.

## 3. Implementation gate

| PR | Ships | Not in this PR |
| --- | --- | --- |
| **S15-27** | RF-1 – RF-8, RF-W1: the table shows 50 citation runs, the Show more row ends it, a press reveals the next 50, a keyboard press moves focus to the first revealed citation and scrolls to it | Records on open, the Event and Place pages, every other view |

## 4. Requirements

| ID | Requirement |
| --- | --- |
| RF-1 | **First page.** A table of more than 50 citation runs shows its first 50, in table order, then the Show more row. A table of 50 or fewer shows every run and no Show more row. |
| RF-2 | **Never split.** A citation run shows whole or not at all. A run of 6 records that is the 50th run shows all 6. |
| RF-3 | **Lines through the fold.** An owner line or value heading draws when one of its runs shows. When the fold falls inside a value's runs, its heading shows over the shown runs; what a press reveals continues under that heading, with no second heading. A group whose runs all lie past the fold draws no owner line until a press reveals one of them. |
| RF-4 | **The Show more row.** The kit's `PVShowMoreRow`, "Show 50 more" (or "Show N more" for the last, smaller page), as the last line inside the scroll area, after a normal row rule, at the table's leading edge (under the Read as column), with the row's usual vertical padding. It draws in the same place inside an owner group or after a value heading: it is never indented under a line. |
| RF-5 | **A press.** Each press adds the next 50 runs below the shown ones; nothing above moves. After the last page the row is gone. Closing the sheet and opening it again starts from the first 50. |
| RF-6 | **Keyboard.** Tab reaches the Show more row after the last shown row's controls, before Done. Return or Space presses it, moves focus to the citation link of the first revealed record, and scrolls that record into view inside the sheet's scroll area. A pointer click reveals the page and changes neither focus nor scroll. |
| RF-7 | **Spoken.** VoiceOver reads the row as the button "Show 50 more". After a keyboard press it reads the revealed citation it lands on, as that link reads today. No extra announcement. |
| RF-8 | **Summary.** The header's summary counts every record of the value, shown or folded ("merged from 2 Sources · 1,200 records"), as today. |
| RF-W1 | **Wide.** At Wide the sheet is 1280pt as today; the fold and the row are the same as at Regular. The row stays at the table's leading edge; it does not stretch or center. |

### 4.1 Wide layout

| View | Regular | Wide | What moves |
| --- | --- | --- | --- |
| Provenance sheet | 880pt panel; the Show more row at the table's leading edge, last in the scroll area | 1280pt panel; the same | Nothing moves (the sheet is a modal panel, so it does not fill the pane) |

## 5. Suggested frames

Each frame is the 1102 × 900 pane (Regular) or the 2296 × 1440 pane (Wide) dimmed behind the sheet, as the sheet sits over the Person page; draw only the sheet in detail.

| Frame | Shows |
| --- | --- |
| 1a — Regular, folded | Name of Ottawa County, Kansas: 1,200 records in 430 citation runs. The table scrolled to its foot: the 48th – 50th runs (the 50th a household run of three records with no rules between them), a rule, then "Show 50 more" at the leading edge. Summary "1,200 records" |
| 1b — Wide, folded | Frame 1a at 1280pt |
| 2 — After a keyboard press | Frame 1a after Return on the row: runs 51 onward below run 50, the first revealed citation link with its focus ring, scrolled into view; the row now ends run 100 |
| 3 — Last page | A table of 120 runs after two presses: the row reads "Show 20 more"; after the third press the table ends with its last run and no row |
| 4 — Fold inside a value | A field with two values: the first value's heading over 50 shown runs and the row after them; the second value's heading not drawn yet. After a press, the first value's remaining runs continue with no second heading, then the second value's heading |
| 5 — Owner groups | A derived Birth date with two owner lines: the first group's runs fill the first page, the row follows them, and the second owner line is not drawn yet |
| 6 — No fold | A table of 12 runs: as S15-D9's frame 20a, no row |
| 7 — Spoken | Annotations: the row's spoken label, the Tab order (last row's controls → Show more → Done), where focus lands after a keyboard press, and that a pointer click does not move it |

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Provenance sheet | Recipe | Ship | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheet.swift` | Its scroll area scrolls a keyboard reveal into view; no new chrome |
| Record table | Recipe | Extend | `…/ProvenanceSheet/PVProvenanceRecordTable.swift` | Shows the folded runs and ends with the Show more row. Owner lines, value headings and rules as S15-D9 drew them |
| Record row | Recipe | Extend | `…/ProvenanceSheet/PVProvenanceRecordRow.swift` | Gains an optional focus handle on its citation link, where focus lands after a press; nothing visible changes |
| Show more row | Component | Ship | `macos/App/DesignSystem/Components/ShowMoreRow/PVShowMoreRow.swift` | The kit's row and its "Show N more" wording, as the Person page sections use it. Not a new Show all control, a link, or a count of records |
| Rule before the row | Component | Ship | `PVDivider` | The same rule a normal row boundary draws |

**Non-goals.** No new kit primitive, no new string, no change to `PVShowMoreRow`. No fold inside a citation run, no collapse control, no count of folded records.

## 7. Handoff

When the board is agreed: record the board link, its turn and agreed frames on the **Board** line above and in [`README.md`](README.md); the plan [`../prs/S15-27-provenance-table-fold.md`](../prs/S15-27-provenance-table-fold.md) copies any board decision into its Design and moves from `Blocked — on board S15-D17` to `Planned`. When S15-27 lands, move this brief to `design/archive/` and note it in `completed.md`.
