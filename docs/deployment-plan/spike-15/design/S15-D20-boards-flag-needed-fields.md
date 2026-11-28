# S15-D20 — Metadata board row: a needed and a used entry, on every board

**Kind:** Claude Design board (**enhancement** of the board rows S15-D33 and S15-D29 left: an empty board row gains a mark that says the citation needs or uses its field, and a needed row loses its dismiss. Extend the existing frames; the sheets' and the page's other parts are unchanged)
**Spike:** Provenencia Spike 15, slice 9
**View:** the metadata board row on every board: the Source page's Metadata section, the Artifact sheet (edit and add), the Evidence graph form (edit and add), and the citation composer's Citation metadata sheet
**Implements later as:** PR **S15-39**
**Board:** not drawn yet. When agreed, it reaches the implementer as Claude Design links (user, 2026-11-28): [Claude Design — Source Detail](https://claude.ai/artifact/443NPNYmGErAmxgV1fBsFK) for the Source page, the Artifact sheet and the graph form, and [Claude Design — Citation Composer](https://claude.ai/artifact/3GSFQZjqdQjL8v2rpgMiDc) for the Citation metadata sheet, with the frame names recorded here
**Review:** with the plan, in [`../prs/S15-39-boards-flag-needed-fields.review.md`](../prs/S15-39-boards-flag-needed-fields.review.md)
**Depends on:** S15-38 (landed #910): every board entry carries what the formats ask of it; S15-64 (landed [#959](https://github.com/Jake-Robins-Studios/provenencia/pull/959)) and [S15-D33](archive/S15-D33-inherited-values.md): the inherited row; S15-56 (landed #982) and [S15-D29](archive/S15-D29-citation-composer-metadata.md): the Citation metadata sheet; [S15-D14](archive/S15-D14-source-page-artifacts.md) and [S15-D5](archive/S15-D5-evidence-graph-form.md): the Artifact sheet and the graph form
**Related:** working rules "A format's fields are needed or used", "Boards flag needed fields; the engine decides the rows", "One metadata board", "A board shows what its owner inherits" in [`../deployment-plan.md`](../deployment-plan.md#working-rules); [`evidence-explained-citation-map.md` § 6.10](../evidence-explained-citation-map.md); [`macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide)
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

This brief is an **enhancement**: draw on the board rows S15-D33 left on the Source Detail board (the Source page's Metadata section, page *Artifacts* section "Artifact sheet" and "Add artifact", page *Evidence graphs* section "Evidence graph form") and on the rows S15-D29 left on the Citation Composer board (section "S15-D29 · The Citation's metadata", the Citation metadata sheet). Change the rows in place; do not keep a before frame.

---

## 1. Objective

A Source type's citation formats read some fields outside any optional part (**needed**: an empty one leaves a hole in the citation) and others inside one (**used**: an empty one drops its part). The engine already sends, on every board entry, which of the two the field is, whether its need is already met somewhere else, and the other fields that would answer it. No board draws it: a census Source with no Jurisdiction looks like one with nothing missing, and a researcher finds the hole only in a printed citation.

After this board, an **empty** row says what the citation wants of it. A needed field that nothing answers is **flagged**, and its row has no dismiss: only a value answers it. When the citation would also accept another field ("Author for sorting" falls back to Author), a hint names it. A used field, or a needed one already answered elsewhere, carries a **quieter mark**. A row with a value carries no mark.

**What changes.**

- **The needed flag.** An empty needed row nothing answers carries a flag that reads at a glance, and its dismiss ✕ goes.
- **The chain hint.** A flagged row whose citation also accepts other fields names them under the input.
- **The used mark.** An empty used row, and an empty needed row already answered (by the Source's value, or by another field the citation accepts), carry a quieter mark. A used row keeps its dismiss; a needed one never has it.
- **Filling clears it.** Once a row holds a value, it is a saved row with no mark. Clearing it brings the mark back.

**What stays.** Which rows a board holds and their order (the engine decides both), the "Suggested by this type" heading, the saved rows (reorder handle, inline edit, trash), the empty row's input and Save, the inherited row ("From Source", the override pencil), the inline Add field row, the sheets' widths and columns, the Source page's sections.

---

## 2. Domain facts

| Fact | What it means on this board |
| --- | --- |
| Needed | The field is read outside every optional part of the type's formats. Empty, it leaves a hole in the citation. Census needs Jurisdiction; Book needs Author and, for its list entry, Author for sorting |
| Used | The field is read inside an optional part. Empty, its part is left out. On the seeded types most suggested fields are used (15 of the census's 16 suggestions on an Artifact), so the used mark sits on most empty rows: it must read as quiet as a caption |
| Chain | A placeholder can name several fields, first one first: Book's list entry reads Author for sorting, else Author. The chain is met when any of them has a value. The engine flags it on its first field and names the others; every later field is used |
| Met elsewhere | A needed field with no value here whose need is already answered: by the value this owner inherits from its Source (an Artifact's Jurisdiction), or by another field of its chain (Author filled answers Author for sorting). It is not flagged; it carries the used mark and has no dismiss (user, 2026-11-28) |
| Every board | Most fields are read from the nearest level that holds a value, so a needed field shows on every board: the Source page, each Artifact sheet, each graph form and each Citation metadata sheet. A census Source with no Jurisdiction is flagged on all of them, and filling it on any one answers that one's citation (user, 2026-11-28) |
| Dismiss | A used suggestion can be dismissed as today. A needed field cannot: the engine refuses, so the row offers no ✕, flagged or not |
| Filled | A value of any kind (typed, or marked unknown later in this spike) answers the field: a saved row draws no mark |
| Sizes | A board of up to 30 rows, up to every one marked. A chain of up to 3 fields. Field names up to about 30 characters ("Enumeration district") in the 132pt label column |
| Where | The Source page's Metadata section (writes at once); the Artifact sheet and the graph form, 880pt sheets with the board in the right column (about 400pt); the Citation metadata sheet, 600pt. The sheets save with their owner's Save |

### 2.1 Copy

The board may refine wording; the PR copies what the board shows. *(today)* marks a string that exists and stays.

| Where | Text |
| --- | --- |
| Needed flag | "Needed" |
| Used mark | "Used" |
| Chain hint, one other field | "Or fill in Author" |
| Chain hint, several | "Or fill in Folio, or Pages" (the names joined with ", or ") |
| Flagged row, spoken (VoiceOver, on its input) | "Jurisdiction, needed for citation" |
| Used row, spoken | "URL, used in citation" |
| Inherited used row, spoken | "Jurisdiction, used in citation. Inherited from Source: Calder County" |
| Chain hint, spoken (the input's hint) | "Or fill in Author" |
| Empty row's input | "Add a value…" *(today)* |
| Where an inherited value comes from | "From Source" *(today)* |
| Suggestions heading | "Suggested by this type" *(today)* |

### 2.2 What this board is not

- The Artifacts list's mark for an Artifact missing a needed field (S15-D21 → S15-40).
- The Unknown and Supplied control (S15-D22 → S15-41), and the Source date's flag in the page header (S15-D23 → S15-42).
- The ⓘ beside a described field's name (S15-D40 → S15-73).
- The list-below hint and Move to Source (S15-D35 → S15-66).
- The Copy Source sheet's board (Spike 16, S16-75).
- Sorting needed rows first, or a "Needed for citation" heading: the rows keep the engine's order under today's heading.
- A citation preview (refused in this spike).

---

## 3. Implementation gate

| PR | Ships | Not that PR |
| --- | --- | --- |
| **S15-39** | NF-1 – NF-7, NF-W1 on the Source page, the Artifact sheet (edit and add), the graph form (edit and add) and the Citation metadata sheet | The Artifacts list's mark (S15-40); Unknown and Supplied (S15-41); the date's flag (S15-42); the ⓘ (S15-73); the list-below hint (S15-66) |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| NF-1 | **The needed flag.** An empty row whose field is needed and not met elsewhere is today's dashed suggestion row (label, input, Save) with a **Needed** Badge in the warning tone under the field name, in the 132pt label column. A field name that wraps pushes the Badge down; the Badge never covers the input. No ✕. |
| NF-2 | **The chain hint.** A flagged row whose chain has other fields shows "Or fill in Author" under its input in the caption style the inherited row's "From Source" uses. Several fields: "Or fill in Folio, or Pages". Its text truncates on one line with the whole text on hover. |
| NF-3 | **The used mark.** An empty row whose field is used, or needed and met elsewhere, shows a **Used** Badge, neutral and subtle (outlined), in the same place as NF-1's. It reads quieter than NF-1's and no louder than the "From Source" caption: on a census Artifact sheet most rows carry it. A used row keeps its ✕; a needed one met elsewhere has none. |
| NF-4 | **Inherited rows.** An inherited row (S15-D33) whose field is needed or used keeps its value, "From Source" and its override pencil, and shows NF-3's mark in the label column. A needed one has no ✕. Overriding it makes it a saved row with no mark; the trash brings the mark back. |
| NF-5 | **Filling clears it.** A row with a value is a saved row and shows no mark, whatever its field's need. On the Source page, saving a flagged row's value clears its flag at once, and a field its chain names loses its flag too (filling Author takes Author for sorting from Needed to Used). In a sheet, the row's Save does the same before the sheet's Save. Clearing a saved value brings the row's mark back. |
| NF-6 | **Where.** The same rows on the Source page's Metadata section, the Artifact sheet in edit and in add, the Evidence graph form in edit and in add, and the Citation metadata sheet. Rows keep the engine's order under "Suggested by this type"; the heading does not change. |
| NF-7 | **VoiceOver.** The Badge is not its own element: a flagged row's input reads "Jurisdiction, needed for citation", a used row's "URL, used in citation", and NF-2's hint is the input's hint. An inherited row's value reads its field, the mark, then today's "Inherited from Source: Calder County". |
| NF-W1 | **Wide.** Nothing moves. The Source page's Metadata section keeps its place and width at Wide, and the sheets are the same fixed width at both widths, centred over the pane. A typed value, an open edit and the scroll survive a resize across 1600pt. |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Source page, Metadata section | As today | As today (its Page columns place) | Nothing |
| Artifact sheet (edit, add) | 880pt sheet, two columns; the board in the right column | The same sheet, centred over the pane | Nothing |
| Evidence graph form (edit, add) | 880pt sheet, two columns; the board in the right column | The same sheet, centred over the pane | Nothing |
| Citation metadata sheet | 600pt sheet over the composer | The same sheet, centred over the composer | Nothing |

---

## 5. Suggested frames

Draw from the existing frames. Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440); the others at Regular.

**Data** (invent every record). Source **1880 census, Calder County** of type **Census**, suggesting, in order: Creator, Jurisdiction, Schedule, Enumeration district, Piece, Folio, Schedule number, Dwelling, Family, Line, Item, Format, Provider, URL, Accessed, Citing. Jurisdiction is needed; the other fifteen are used. The Source holds Creator "Calder County enumerator" and Provider "Ancestry", and Jurisdiction "Calder County" only where a frame says so. Its Artifact **Page 12, image 1** holds Line "14"; its graph **Household of Ada Robins** holds Item "Ada Robins". Source **History of Calder County** of type **Book**: Author and Author for sorting are needed (Author for sorting's chain also accepts Author), Editor, Edition, Place of publication, Publisher, Format, Provider, URL and Accessed are used. Source **Kansas Reports, vol. 12** of type **Court report**: Published in is needed and holds "Kansas Reports"; its Citations need Page, whose chain also accepts Pages.

| Frame | Requirement | Draw |
| --- | --- | --- |
| D20-1a / 1b | NF-1, NF-3, NF-6, NF-W1 | The census Source page with no Jurisdiction: Creator and Provider saved, no mark; Jurisdiction flagged (Needed, no ✕); the other empty suggestions Used, each with its ✕. 1b at Wide |
| D20-2 | NF-1, NF-2 | The Book Source page with no Author: Author flagged; Author for sorting flagged with "Or fill in Author" under its input |
| D20-3 | NF-3, NF-5 | After Author "Ashby, Ruth" is saved: Author a saved row, no mark; Author for sorting Used, no ✕ |
| D20-4 | NF-5 | D20-1 after "Calder County" is saved in Jurisdiction: a saved row, no mark |
| D20-5 | NF-3, NF-4 | Artifact sheet, edit, with the Source holding Jurisdiction: Line saved, no mark; Jurisdiction inherited ("Calder County", "From Source"), Used, no ✕; Creator and Provider inherited, Used, each with its ✕; URL and the rest empty, Used, with ✕ |
| D20-6 | NF-1, NF-6 | The same sheet with the Source holding no Jurisdiction: Jurisdiction flagged on the Artifact sheet |
| D20-7 | NF-6 | Add an Artifact: the draft board as D20-5, before anything is typed |
| D20-8a / 8b | NF-6, NF-W1 | Evidence graph form, edit: Item saved, no mark; Jurisdiction inherited, Used, no ✕; the rest as D20-5. 8b at Wide |
| D20-9 | NF-1, NF-2, NF-4, NF-6 | Citation metadata sheet of a Kansas Reports Citation with no Page: Page flagged with "Or fill in Pages"; Published in inherited ("Kansas Reports", "From Source"), Used, no ✕ |
| D20-10 | NF-1 | A flagged row whose field name wraps ("Enumeration district" on a type that needs it): the Badge under both lines, the row taller, the input aligned to the first line |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Metadata board | Snowflake | Extend | `macos/App/Features/MetadataBoard/MetadataBoardView.swift` `MetadataBoardView` | One board on every owner (rule "One metadata board"): the marks are on its rows, not a second board or a per-host row |
| Empty suggestion row | Snowflake | Extend | `MetadataBoardView.swift` `MetadataBoardSuggestionRow` | Gains the mark in its label column and the chain hint under its input; its ✕ goes on a needed field |
| Inherited row | Snowflake | Extend | `MetadataBoardView.swift` `MetadataBoardInheritedRow` | Gains the mark in its label column; its ✕ goes on a needed field |
| Label column | Snowflake | Extend | `MetadataBoardView.swift` `MetadataBoardLabel` | Holds the field name and, under it, the mark; 132pt as today |
| Needed flag, used mark | Component | Ship | `macos/App/DesignSystem/Components/Badge/PVBadge.swift` `PVBadge` | Needed: `tone: .warning`. Used: `tone: .neutral, subtle: true`. A status mark is a Badge (kit reach-for); no local pill, no icon-only mark |
| Chain hint | Snowflake | Ship | `MetadataBoardView.swift` `MetadataBoardCaption` | The board's one caption view, as "From Source" and "Overrides Source: …" use it. Text, not a Callout: one quiet line, not a warning box |
| Value input, Save | Component | Ship | `PVInput`, `PVButton` ghost sm | Unchanged |
| Dismiss | Component | Ship | `PVIconButton(.dismiss)` via `MetadataBoardSuggestionDismiss` | Not drawn on a needed field |
| Saved row | Snowflake | Ship | `MetadataBoardView.savedRow` | Unchanged: no mark on a value |
| Sheets and the page | Component | Ship | `PVFormDialog`, `PVFormColumns`; `ArtifactSheet.swift`, `SourceGraphFormDialog.swift`, `CitationMetadataSheet.swift`, `SourcePageMetadataView.swift` | Unchanged widths and columns |

**Non-goals.** No new kit primitive. No new row type. No section or heading for needed rows, no re-sorting. No mark on a saved value. No preview of the citation. No change to the Add field row, reorder, the Artifacts list or the graph cards.

---

## 7. Handoff

When the board is agreed: record the frames and the board's decisions (the mark's place, its tone, any copy change) on the **Board** line here and in [`README.md`](README.md). S15-39's plan copies NF-1 – NF-7, NF-W1, the copy and the inventory, fills its macOS and Strings sections from the board, and moves from `Blocked — on board S15-D20` to `Planned`. When S15-39 lands, this brief moves to the spike's design archive.
