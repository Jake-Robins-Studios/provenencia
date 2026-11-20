# S15-D3 — Person page Sources section: each Source's published date

**Kind:** Claude Design board (**enhancement** of the Person page's Sources section as shipped: S13-D6 rows, S13-D10 record links diagram beside them, S16-D2 folds. Draw on the existing Person page board; fill the Date column that today shows a dash, and rename its caption)
**Spike:** Provenencia Spike 15, slice 5
**View:** the Person page's Sources section (the rows and their caption line; the record links diagram beside them is unchanged)
**Implements later as:** PR **S15-05** (PS-1 – PS-6, PS-W1)
**Board:** agreed 2026-11-20 — [Person page board](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ), page *Sources*, turn 19 "S15-D3 · Published date": frames F1a (Regular), F1b (Wide), F2 (the phrase truncated with its hover). Read it with the Artifact tool's `read` on that link, `path` "project/Person Detail - Sources.dc.html" (turn 19 and the row template's Date cell). Board decision (user, 2026-11-20), which replaces the brief's PS-3: "Undated" is italic, secondary ink, caption size (6.9:1 on the page in light, 10.8:1 in dark; faint ink is 2.6:1), and because the published date is one shared view the Sources list's undated text ("Undated", "No published date") takes the same look. The date is the body face, not mono. Frame 3 (the spoken labels) was not drawn; PS-5 stands as written. § 4 PS-3 below is the requirement as drawn
**Depends on:** S15-02 (landed [#762](https://github.com/Jake-Robins-Studios/provenencia/pull/762)): every Source carries an optional date; S15-04 (landed [#774](https://github.com/Jake-Robins-Studios/provenencia/pull/774)): the Sources list shows that date as the **published** date; S15-43 (landed [#900](https://github.com/Jake-Robins-Studios/provenencia/pull/900)): a date can be marked unknown or supplied
**Related:** [`../source-provenance-date.md`](../source-provenance-date.md); the Sources list brief [S15-D2](archive/S15-D2-sources-list.md) SL-1 – SL-3 (how the list draws the date); working rules in [`../deployment-plan.md`](../deployment-plan.md#working-rules); plan [`../prs/S15-05-person-sources-date.md`](../prs/S15-05-person-sources-date.md)
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

Draw on the Person page board as a new turn "S15-D3 · Published date", starting from the S13-D6 Sources frames with the S13-D10 record links diagram beside the rows, at Regular and Wide, as S16-D2 left them. Keep the page header, the section switcher, the caption line's other three captions, each row's title link, type pill and ref, the record lines under the title with their Unpromote buttons, the Show more rows, and the diagram and its column. Change only the Date column: its caption and its cell.

---

## 1. Objective

The Person page's Sources section lists the Sources a person's records come from, one row each, in title order. Today, from the top: a caption line in muted micro caps (SOURCE · TYPE · DATE · REF) over a strong hairline; then the rows, divided by hairlines. A row's first line has four cells: the **Source** cell (the title as a link, at most two lines, filling the row), the **Type** cell (the type as a pill, 176pt), the **Date** cell (120pt) and the **Ref** cell (the mono ref, 104pt). Under the title, indented 16pt, one line per record: the graph's name as a link, then "· graph ref · Subject name · Subject ref" in secondary caption text, and a ghost Unpromote button. Five lines show before "Show N more"; fifty Sources before the rows' own Show more. The record links diagram sits beside the rows, pinned while they scroll; when the pane leaves the rows less than their narrowest width (the four columns at their minimum), it moves under them.

The Date cell is a placeholder: every row shows a muted dash "—", and VoiceOver reads "date not recorded". Sources have carried a date since S15-02, and the Sources list has shown it as the **published** date since S15-04.

**What changes.**
- **The caption reads PUBLISHED.** "Published" is the date's one name in the app (user, 2026-11-10): the Sources list, its sorts and the Source page header all use it.
- **The cell shows the published date** as the Sources list's Published column draws it at Wide: the date alone, caption size, secondary ink, no label and no icon; "Undated" in italic secondary ink when there is none (as drawn; the Sources list's undated text takes the same look).

**What stays.** Everything else in the section and on the page: the other three columns and their widths, the record lines, the folds, the diagram, the empty, loading and error states.

---

## 2. Domain facts

| Fact | What it means on this board |
| --- | --- |
| The Source date | One optional structured date per Source: the original publication, or when the record was made. Set on the Source page only; the Person page never edits it. |
| How a date reads | As the Sources list and the Source page header write it: "1880", "12 Mar 1880", "abt 1880", "bef 3 Mar 1830", "bet 1834 and 1840", or the phrase as the researcher typed it ("in the reign of Victoria"). |
| Undated | Most Sources start undated; there is no backfill. A person citing 30 Sources may have 25 undated rows. Each reads "Undated", italic. |
| Unknown and supplied | A date marked **unknown** has no date: the row reads "Undated". A date marked **supplied** (not on the record) reads as the plain date, as the Sources list reads it (user, 2026-11-20). Neither mark is drawn on this section. |
| The row order | Sources stay in title order. The date does not sort the section. |
| A date set elsewhere | Setting, changing or clearing a date on the Source page updates the row's date the next time the Person page reads its Sources, with no reload of the page. |
| Scale | A Person page cites up to 30 Sources; a crafted page holds more, folded at 50. |

### 2.1 What this board is not

- Citations grouped under one formatted citation (S15-D15, PR S15-22).
- Sorting or grouping the section by date.
- Drawing the unknown or supplied mark on a row (not planned; the Source page header draws it, S15-D23).
- Editing the date from the Person page.
- The Sources list (S15-D2, shipped), the Source page (S15-D1), the provenance sheet (S15-D9).

---

## 3. Implementation gate

| PR | Ships | Not that PR |
| --- | --- | --- |
| **S15-05** | PS-1 – PS-6, PS-W1 | Grouped citations (S15-22); the marks on a row (not planned) |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| PS-1 | **The caption.** The caption line reads SOURCE · TYPE · PUBLISHED · REF, the same micro caps and muted ink. The Date column keeps its 120pt; "PUBLISHED" fits it. |
| PS-2 | **A dated Source.** The cell shows the date alone, as the Sources list's Published column does at Wide: caption size, secondary ink (like the ref), first-baseline aligned with the title, no "Published" label in the cell (the caption names it), no icon. Hover shows "Published {date}". Not a Chip, Badge or pill. |
| PS-3 | **An undated Source.** "Undated" in italic, secondary ink, caption size (as drawn, user 2026-11-20: faint ink is 2.6:1 in light, below 4.5:1). Also for a date marked unknown. No hover text. The published date is one shared view, so the Sources list's "Undated" and "No published date" take the same look. |
| PS-4 | **A long date.** One line; the date truncates with an ellipsis inside its 120pt; the hover text shows it whole. A phrase date ("in the reign of Victoria") is the usual long case. |
| PS-5 | **VoiceOver.** The row's one spoken element reads record facts in the row's order, the date in third place: "Hamburg census 1867, Census, published 1867, SRC-9TQ2M"; an undated Source says "no published date" in the date's place: "Letter, no published date, SRC-4KQ7M". The same words the Sources list speaks. |
| PS-6 | **A date set elsewhere.** After the date is set, changed or cleared on the Source page, the row shows the new date when the Person page is shown again, with its folds, scroll position and the diagram as they were. |
| PS-W1 | **Wide: unchanged.** At Wide the rows and the diagram keep the arrangement S13-D10 and S16-D2 drew (the Source cell fills; Type 176, Published 120, Ref 104; the diagram beside); the date cell is the same 120pt and does not grow. The extra width already goes to the title and the diagram. |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Person page, Sources section | Caption line and rows: Source fills, Type 176, Published 120, Ref 104; the record links diagram beside the rows, or under them when the rows lack room | The same columns; the Source cell takes the extra width; the diagram beside | Nothing moves: the Published cell replaces the dash in place at both widths (the section's Wide arrangement is S13-D10's) |

---

## 5. Suggested frames

Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440). Data: the Person page of Johann Weber (invented), citing five Sources, each with one to three record lines, in title order: "Hamburg census 1867" (Census, `1867`), "Hamburger Adressbuch 1861" (`abt 1861`), "Hamburger Nachrichten, obituary 1880" (undated), "Konfirmandenbuch St. Ansgarii 1831" (phrase "in the reign of Wilhelm I"), and "Verzeichniß der Mitglieder des Vereins für Hamburgische Geschichte, nebst einem Anhang über die Statuten" (its date marked unknown). These are the app's own preview Sources for this section. Invent every person and record.

| Frame | Requirement | Draw |
| --- | --- | --- |
| 1a / 1b | PS-1, PS-2, PS-3, PS-W1 | The Sources section of Johann's page, the diagram beside the rows: the caption line with PUBLISHED, dated and undated rows mixed in title order |
| 2 | PS-4 | Regular, the row "Konfirmandenbuch St. Ansgarii 1831": the phrase truncated in its cell, the hover text "Published in the reign of Wilhelm I" shown |
| 3 | PS-5 | Regular, a VoiceOver caption under frame 1a giving the spoken label of one dated and one undated row |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Sources section rows | Snowflake | Extend | `macos/App/Features/Conclusions/PersonSourcesSection.swift` `PersonSourcesList`, `PersonSourcesRowView` | The Date cell draws the published date; the caption reads Published |
| Published date | Recipe | New (promoted) | `macos/App/DesignSystem/Recipes/PublishedDate/` *(new)*, from the Sources list's private `SourcesPublishedDate` | The Sources list's published date, composing the Platform formatter `SourceDateText` (`macos/App/Platform/SourceDateText.swift` *(new)*), its `.bare` style here: the date alone in secondary ink, or "Undated" in italic secondary ink (the list's undated text takes the same look); "Published {date}" as hover. Second call site: the Sources list (`SourcesListRow.swift`), which draws it today; this section is the other, so it moves from the list's file to a recipe. Not a Chip, Badge or List detail cell (icon + muted text is the last update's look) |
| Caption line | Snowflake | Extend | `PersonSourcesList` `header` | One caption's copy |
| Columns | Snowflake | Ship | `PersonSourcesColumns` | Widths unchanged |
| Type pill | Recipe | Ship | `CatalogSourceTypePill` | Unchanged |
| Tooltip | Platform | Ship | `.help` | "Published {date}" |

**Non-goals.** No new kit component: the published date is the Sources list's, promoted because it gains this second caller. No mark, icon or sort on the date; no change to the columns' widths or to the record lines.

---

## 7. Handoff

When the board is agreed: record the link, the frames and the board's decisions on the **Board** line here, in [`README.md`](README.md) and on S15-05's plan **Board** line; the plan copies PS-1 – PS-6 and PS-W1 and moves from `Blocked — on board S15-D3` to `Planned`. When S15-05 lands, the brief moves to the spike's design archive.
