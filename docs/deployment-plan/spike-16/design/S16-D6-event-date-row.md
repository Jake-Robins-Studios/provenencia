# S16-D6 — The Event page's Date row for an event dated by as-ofs

**Kind:** Claude Design board (**enhancement** of the Event page frames (S9-D6): states are added to existing frames)
**Spike:** Provenencia Spike 16 (odds and ends), batch 5
**View:** the Event page: its Date row
**Implements later as:** PR **S16-44** (The Event page's Date row shows as-ofs)
**Board:** — (not drawn yet). Draw on [Claude Design — Event Detail](https://claude.ai/artifact/5ciAxv86fYtrUvuCHPuuJ5), page `project/Event Detail.dc.html`, as a new turn "S16-D6 · As-of dates" after frames 1 – 7
**Depends on:** S16-42 (landed [#876](https://github.com/mendahu/provenencia/pull/876)): the engine sends each event's dating, and the Event page header reads it (S16-D4's wording); the agreed Event page frames 1 – 7
**Related:** [S16-D4](archive/S16-D4-event-date-line.md) (the shared date line, whose wording this row reuses); feature doc [`../event-as-of.md`](../event-as-of.md); working rules "The engine sends the dating, not the as-ofs" and "As-ofs alone make a span open on both sides" in [`../deployment-plan.md`](../deployment-plan.md#batch-5--event-as-of-dates); [`macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide); plan [`../prs/S16-44-event-date-row.md`](../prs/S16-44-event-date-row.md)
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

### This brief is an enhancement

Draw as a new turn "S16-D6 · As-of dates" on the Event Detail board, starting from its agreed frames 1 (Regular) and 7 (Wide). Do not redraw the header, the gallery, the Place row or the page columns. Only the Date row of the events named below changes, and the header's date line shows the S16-D4 wording already agreed.

---

## 1. Objective

An event can record **As of** dates: a day a lasting fact (a residence, an occupation) was known to be under way. An obituary of 10 Jan 1990 says "survived by X of Town Y"; a directory of 10 Feb 2015 lists X in Town Y. Since S16-42 the Event page header dates such an event `as of 10 Jan 1990–10 Feb 2015`, but its Date row still says **No date recorded**: the two contradict.

This board decides **how the Date row shows an event dated by as-ofs**: each as-of the event keeps, with the Sources behind it, and the start or end that closes a side.

**What stays.** An event with a `date`, or with a start and an end and no as-of, shows its Date row exactly as today: the `date` field's value with its badge and Source count, or the start–end span with one Why for both. The row's place on the page, its label column, its Why button and its type stay.

## 2. Domain facts

| Fact | Meaning for the board |
| --- | --- |
| Four date Properties on an event | `date` (when it happened), `start_date`, `end_date`, and `as_of` (any number). A date can be exact, About, Before, After, or a range, and can carry the source's words ("in the spring") |
| The engine sends one dating per event | Its kind (occurrence, span, as-of), its earliest and latest date and whether each side is open. The header line formats it (S16-D4). The Date row reads the dating's kind to choose which recorded dates it shows |
| An occurrence wins | A kept `date` is the dating; the row shows the `date` field as today, even when the event also has as-ofs |
| As-of dating | No `date`, and at least one as-of. A start closes the low side and an end the high side; without them the side is open |
| Each as-of is kept separately | As of is a multi-valued Property: two as-ofs never compete, each is a kept value with its own Sources. The engine sends them earliest first |
| A record | One Citation's Observation. The Why lists the records behind the row, each with the date it read and its citation |
| Contradictory data | An as-of before the start or after the end opens that side of the dating (the header says so). The row still lists the start or end the researcher recorded; a notice for it is later work, not this board |
| VoiceOver | The row is one element: its label, then its value. A row with several values speaks them in order, separated as a multi-valued row is today ("Date, as of 10 Jan 1990; as of 10 Feb 2015") |

### 2.1 What this board is not

- Not the header's date line (S16-D4, shipped in S16-42).
- Not the Events list, the Timeline or any other surface.
- Not the date editor or the composer: As of is entered with today's date editor.
- Not a notice when an as-of falls outside the start or end ([idea](../../../ideas/event-as-of-followups.md)).
- Not a row for the as-ofs of an event that also has a `date`: the occurrence wins, as the start and end of such an event are not shown today.

---

## 3. Implementation gate

| S16-44 ships | Not S16-44 |
| --- | --- |
| DR-1 – DR-8, DR-W1 | The header line (S16-42); an out-of-bounds as-of notice ([idea](../../../ideas/event-as-of-followups.md)); as-ofs on an event with a `date` (not planned) |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| DR-1 | **Occurrence and span read as today.** `date` 14 May 1817: the row shows `14 May 1817` with its badge and Source count. Start 1849, end 1851, no as-of: `1849–1851`, one Why for both. Start alone: `1849` with that field's count. Draw them as reference rows beside the new ones |
| DR-2 | **As-of only.** As-ofs 10 Jan 1990 (an obituary, 1 Source) and 10 Feb 2015 (a city directory, 1 Source): the row lists one line per kept as-of, earliest first, each with its Source count beside it, as a multi-valued row lists its values today (`PVProvenanceValueList`). **The board decides** the wording of each line. Recommendation: `as of 10 Jan 1990` · `1 Source`, `as of 10 Feb 2015` · `1 Source`, reusing S16-D4's "as of". The row never reads **No date recorded** while the header dates the event |
| DR-3 | **As-of with a start, or an end.** Start 1985 and the two as-ofs: the start's line comes first, then the as-ofs. As-of 1990 and end 2015: the as-of, then the end's line. **The board decides** their wording; it must differ from an as-of line. Recommendation: `from 1985`, `until 2015`, matching S16-D4's `from …, as of …` and `as of …, until …` |
| DR-4 | **Qualified dates.** Each line keeps its date's own qualifier and the source's words, as every date line does: as-ofs `abt 1990` and `bef 2015` read `as of abt 1990`, `as of bef 2015`. The as-of wording never replaces a `bef` or `aft` |
| DR-5 | **One as-of.** One line, `as of 10 Jan 1990` · `1 Source` (DR-2's wording). It must not read like an occurrence (`10 Jan 1990`) |
| DR-6 | **The Why.** The row's Why lists every record behind its lines (the as-of records, and the start's and end's), each with the date it read and its citation, as the start–end row's Why does today. Its title names the row's dating as the header shows it (`Why “as of 10 Jan 1990–10 Feb 2015”`, today's Why title). No state badge on the row: each line carries its own Source count, as a multi-valued row does |
| DR-7 | **No new layout.** The row is today's reconciled-value row: label column, the value lines stacked in the value column, the Why disclosure at its end. No chip, badge or icon marks "as of"; the words do |
| DR-8 | **Many as-ofs.** A crafted or imported event can carry thousands of as-ofs. The row lists at most 20 lines (a directory run of real data has up to 20), then one muted line `9,980 more`, as the Place page's Contains list ends in `%lld more`; the Why still lists every record. **The board decides** that line's look; it is text, not a button. Draw it in frame 10 |
| DR-W1 | The Date row reads the same at Regular and Wide. The Event page keeps its agreed Wide arrangement (frame 7); nothing moves between widths |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Event page | As agreed (frame 1): header, the Date and Place rows, the gallery | As agreed (frame 7) | Nothing; only the Date row's value lines change for an as-of event |

---

## 5. Suggested frames

Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440); the others as they say.

| Frame | Requirement | Draw |
| --- | --- | --- |
| 8a / 8b | DR-2, DR-7, DR-W1 | Event page "Residence of X", in Town Y, header line `as of 10 Jan 1990–10 Feb 2015`; the Date row lists the two as-ofs (DR-2), the Why closed |
| 9 | DR-6 | Regular only: frame 8a with the Date row's Why open: the obituary's record (read as `10 Jan 1990`) and the directory's record (read as `10 Feb 2015`) |
| 10 | DR-1, DR-3, DR-4, DR-5, DR-8 | Regular only: a reference strip of Date rows, label to Why button, one per case: "Baptism of Anna Weber" `14 May 1817` (DR-1); "Residence of Ruth Smith" start 1849, end 1851 (DR-1); "Residence of John Smith" start 1985, as-ofs 10 Jan 1990 and 10 Feb 2015 (DR-3); "Residence of Peter Smith" as-of 1990, end 2015 (DR-3); "Occupation of X" as-ofs abt 1990 and bef 2015 (DR-4); "Residence of Mary Smith" as-of 10 Jan 1990 only (DR-5); "Residence of Z" with 10,000 as-ofs, its 20 lines then `9,980 more` (DR-8). Each with the header line it sits under, as a caption |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Reconciled value row | Snowflake | Ship | `macos/App/Features/Conclusions/ReconciledValueRow.swift` `ReconciledValueRow` | The Date row. Unchanged: label, value lines, badge slot, Why |
| Value lines | Recipe | Extend | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceParts.swift` `PVProvenanceValueList`, `PVProvenanceValueLine` | Each date line with its Source count, stacked, as a multi-valued row lists its values. Not a lead above a list: when the row lists lines, it shows only the lines. Extended with one muted remainder caption under the lines (DR-8), as the Place page's Contains ends |
| The Why | Recipe | Ship | `macos/App/Features/Conclusions/ReconciliationReasoningView.swift`, `PVProvenanceSheetContent.spanning` | The records of every field behind the lines, in one group, as the start–end row today |
| Row model | Snowflake | Extend | `macos/App/Features/Conclusions/ReconciledValueRowModel.swift` `ReconciledValueRowModel.spanning` | Takes the listed lines as well as the lead |
| Row date text | Shared Platform formatter | Ship | `macos/App/Platform/DateRowDisplay.swift` `DateRowDisplay`, `L10n.Dates.rowAsOf` | Each date in the list row's compact form; "as of" is S16-D4's copy. DR-3's start and end words and DR-8's remainder line are new copy |
| Page columns | Component | Ship | `PVPageColumns` | Unchanged |

**Non-goals.** No new kit primitive, no badge or chip for "as of", no icon, no new color or token, no second row for the as-ofs, no lead line above the listed lines, no tooltip.

---

## 7. Handoff

When the board is agreed: record the turn, its frames and the DR-2, DR-3 and DR-8 wording on the **Board** line here, in [`README.md`](README.md) and on the plan's **Board** line; the plan copies DR-1 – DR-8 and DR-W1 into its Scope, fills its Strings and moves from `Blocked` to `Planned`. When S16-44 lands, the brief moves to the spike's design archive.
