# S16-D15 — Add Source: the shared Source fields (Title, Type, Published date, Description, Private)

**Kind:** Claude Design board (**enhancement** of the Add Source dialog as shipped: a FormDialog with Title, Type and Description. The dialog gains the Source's published date, as the shared date form inline, and Private; the five fields become one shared set of Source fields that the Copy Source dialog takes up later)
**Spike:** Provenencia Spike 16 (odds and ends), batch 8, slice 8a
**View:** the Add Source dialog, opened by **Add Source** at the Sources list's top right
**Implements later as:** PR **S16-73** (Add Source takes the Published date and Private)
**Board:** agreed 2026-11-28 — [Claude Design — Source Detail](https://claude.ai/artifact/443NPNYmGErAmxgV1fBsFK), page *Dialogs*, section "Add Source" (it shares components with the Copy Source dialog): frames `add-today` (0), `add-open` (1a), `add-open-wide` (1b), `add-filled` (2), `add-range` (3), `add-field-error` (4, drawn with a range whose end is before its start), `add-incomplete` (5), `add-created` (6), `add-discard` (7), `add-more` (8), drawn by `Source.dc.html` near `S16-D15`. Board decisions: AS-4 is A; the date is the date dialog's form at 560 pt. After the board (user, 2026-11-28): Private is a kit Checkbox, not the board's switch (AS-7); frame 5 drew "Spring 1880" with no year as incomplete, but a phrase alone is a valid date in the app and the engine, so the app's rule stands and AS-5's example is a phrase with a time zone
**Depends on:** the Source date dialog and Private switch as agreed in S15-D1 (SD-3, SD-5) and shipped in S15-03; the Add Source dialog as shipped (Spike 2, moved into its own modifier in S16-66). Nothing open
**Related:** working rules "(Batch 8) The Add and Copy sheets share one set of Source fields" and "(Batch 8) A new Source and its parts are one write through one composer" in [`../deployment-plan.md`](../../deployment-plan.md#working-rules); scope entry [S16-73](../../deployment-plan.md#s16-73--add-source-takes-the-published-date-and-private); bar 44; board S16-D16 (the Copy sheet with these fields, S16-74), written after this one; [`macos-client-patterns.md` § 9](../../../../macos-client-patterns.md#9-window-widths-regular-and-wide)
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

Draw a new row "S16-D15 · Add Source" on the *Source page* page. Start from the Add Source dialog as it ships today (described in § 1; the board has no frame of it yet, so draw today's dialog once as frame 0 from that description and keep it only as the starting point), and from the Source date dialog's form as drawn in S15-D1 frame 3. Put the date form into the dialog inline, as it is drawn there; **do not redesign the date form**. Keep the dialog's title, subtitle, buttons, the Title and Type fields and their errors, and the Callouts above the fields.

---

## 1. Objective

Today **Add Source** opens a FormDialog, 480 pt wide: the title "Add source", the subtitle "A thin record now — artifacts, notes and metadata live on the Source page.", then **Title** (required, a text field that takes focus), **Type** (required, a searchable pick of the project's Source types; with one type it is filled in), and **Description** (optional, a one-line text field with the hint "Optional — a short note on what this record is"). The buttons are **Cancel** and **Create source**; Create is disabled until Title and Type are filled. A failed create shows a danger Callout above the fields. After Create the dialog closes, the new Source's page opens and a toast says it was made.

A Source's **published date** and its **Private** switch can only be set afterwards, on the Source page (the date through the Source date dialog, Private by the switch in the page header). So a researcher who knows both when adding the Source has to open the page and make two more edits.

What changes: **the dialog shows the five Source fields in order: Title, Type, Published date, Description, Private.** The published date is the app's shared date form, inline, empty on open; a blank date means the Source is undated. Private is a checkbox with the header switch's label and help, unticked on open (user, 2026-11-28). Create writes the Source with its date and Private in one step, and the page that opens shows both.

The five fields are **one shared set**, drawn once. The Copy Source dialog will show the same set, filled from the original (S16-D16, a later board). This board draws only Add Source.

What stays: the dialog's title, subtitle, buttons and the Callouts; Title and Type and their error rule (no error on open; after the researcher's first edit to either, both show their errors); Create's behaviour after it succeeds; the Source page; the date form itself.

---

## 2. Domain facts

| Fact | What it means on this board |
| --- | --- |
| The published date | One optional structured date per Source: when the record was made or first published. Its one name in the app is **Published** (the Sources list's Published column, "Published 1 Jun 1880"). It is not a metadata row. |
| The shared date form | The app's one date form, used by the Source date dialog and the citation composer: **Kind** (Point / Range, segmented), a **Qualifier** for a point (exact, about, before, after…), the **year, month, day** fields (a second row for a range's end), and a **More options** toggle that opens the calendar, time and phrase fields. It shows its own errors under a field (a month of 13, a range whose end is before its start). Drawn as S15-D1 frame 3 has it; this board does not change it. |
| Blank means undated | A date form with no year, month, day, time or phrase is blank. A blank date creates an undated Source, as today. Choosing Range, a Qualifier or a time zone alone, with no year and no phrase, is still blank. |
| A date that does not parse | A form that is not blank and not a valid date: a field out of range (month 13), a range that ends before it starts, or a combination the form refuses with no field to blame (a phrase "Spring 1880" with a time zone and no year). Create is disabled while the date does not parse. Today the Source date dialog disables Save with no word of why. |
| Reads as | The Source date dialog shows, under the form, a sunken strip "Reads as  1 Jun 1880": the date as the page header will show it, once it parses. |
| Private | A stored switch on every Source, off by default: "Private Sources will be kept out of sharing. Nothing else changes yet." (its help text). The Source page header draws it as a kit Switch labelled **Private** with that help. It changes nothing else in the app today. |
| Description | Optional free text about the record, trimmed; the Source page shows it as the Description section. |
| Dirty | The dialog asks before it closes when anything was entered. The sole type filled in by the app is not an entry. A typed date, or Private turned on, is. |
| Marks | A Source date can be marked unknown or supplied (Spike 15). Add Source sets no mark, and this board draws no mark control (S15-D23 draws it on the date dialog later). |

### 2.1 What this board is not

- The Copy Source dialog (S16-D16, S16-74). Do not redraw the Copy row.
- A redesign of the date form, its Kind control, qualifier, cascade or More options.
- An Unknown or Supplied control for the date, or a flag for a date the type needs (S15-D23, S15-42).
- Metadata, credibility, Artifacts or a cover on Add Source.
- The Source page, its header, the Source date dialog, or the Sources list.

---

## 3. Implementation gate

| S16-73 ships | Not S16-73 |
| --- | --- |
| AS-1 – AS-9, AS-W1 | The Copy Source dialog's fields (S16-74); a marks control (S15-42); metadata on a new Source |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| AS-1 | **Order.** The dialog shows, under the subtitle and any Callout: **Title**, **Type**, **Published date**, **Description**, **Private**, in that order, each as a kit Field (Private as a kit Checkbox). These five are one shared block; annotate it "Source fields (shared with Copy Source)". |
| AS-2 | **Width.** The dialog is as wide as the Source date dialog (560 pt), so the date form sits in it at its drawn width. Title, Type and Description take the dialog's field width. |
| AS-3 | **Published date.** A Field labelled **Published date** with the hint "Optional — leave blank for an undated Source", holding the shared date form inline, empty on open (Kind Point, no qualifier, empty fields, More options closed). Draw it at the same size as in the date dialog. The form takes no focus on open: Title keeps it. |
| AS-4 | **Reads as.** The date dialog's "Reads as" strip shows under the form, inside the Published date Field, once the date parses (a range too), and is hidden while the date is blank or does not parse (board: A). |
| AS-5 | **A date that does not parse.** The form's own field errors show as they do today. When the date does not parse and no field error shows, one line under the form says why Create is disabled: **"This date isn't complete. Finish it or clear its fields."** (the Field's error, danger ink). Create is disabled while the date does not parse, whatever Title and Type say. The line follows the same display rule as Title and Type: not on open. |
| AS-6 | **Description** keeps today's field, label and hint, now after the date. |
| AS-7 | **Private.** A kit Checkbox labelled **Private**, the header switch's help as its description ("Private Sources will be kept out of sharing. Nothing else changes yet."), unticked on open, under Description. A choice in a form saved later is a Checkbox, as the kit's Switch says; the Source page header keeps its Switch (user, 2026-11-28). |
| AS-8 | **Create.** Create source writes the Source with the date (if not blank) and Private. The dialog then closes and the new Source's page opens, as today: its header shows the date and Private on. A blank date and Private unticked create the Source exactly as today. While Create runs, every field is disabled. |
| AS-9 | **Dirty.** The dialog asks before it closes when Title, Description or the date has anything typed, a type was picked by the researcher, or Private is ticked. The Kind or Qualifier changed alone, with nothing typed, is not dirty. |
| AS-W1 | **Wide.** The dialog is a modal over the Sources list; at Wide it is the same 560 pt dialog, centered over the list. Nothing moves between widths. |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Add Source dialog | A 560 pt FormDialog centered over the Sources list; the five fields in one column; the body scrolls when the date form's More options or a range makes it taller than the window allows | The same dialog, centered over the Wide list | Nothing (AS-W1): a form keeps its measure (rule 2) and a short create form has nothing to add at Wide |

---

## 5. Suggested frames

Draw over the Sources list at Regular (pane 1102 × 900), the list dimmed behind the dialog; frame 1 also at Wide (pane 2296 × 1440). Use the Source "1880 census, Ward 4, Altona" of type Census.

| Frame | Requirement | What it shows |
| --- | --- | --- |
| 0 | — | Today's dialog (Title, Type, Description), drawn from § 1 as the starting point only |
| 1a / 1b | AS-1 – AS-3, AS-6, AS-7, AS-W1 | The dialog on open: Title focused and empty, Type empty, the date form blank, Description empty, Private unticked. Regular and Wide |
| 2 | AS-1, AS-3, AS-4, AS-7 | Filled: Title "1880 census, Ward 4, Altona", Type Census, the date 1 Jun 1880 (Point, exact), Description "Enumeration district 12", Private ticked; the Reads as strip (option A) |
| 3 | AS-3 | A range: Kind Range, from 1879 to 1880, the end row shown |
| 4 | AS-5 | A date that does not parse with a field error: month 13, the form's own error under the month, Create disabled |
| 5 | AS-5 | A date that does not parse with no field to blame: the phrase "Spring 1880" and a time zone in More options, no year; the AS-5 line under the form, Create disabled |
| 6 | AS-8 | The new Source's page header after Create from frame 2: the calendar icon and "1 Jun 1880", and Private on (draw only the header row, as S15-D1 frame 1a has it) |
| 7 | AS-9 | Cancel with Private ticked and nothing else entered: the kit's discard confirm |
| 8 | AS-2, AS-3 | More options open on a range: the dialog body scrolling inside the window at Regular |

Under each frame, note what the board changed from today's dialog.

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Add Source dialog | Snowflake | Extend | `macos/App/Features/Sources/SourcesListView.swift` `SourcesAddDialog` | The FormDialog host; its form becomes the Callouts and the shared Source fields. Width 560 (AS-2) |
| Form dialog | Component | Ship | `macos/App/DesignSystem/Components/FormDialog/PVFormDialog.swift` | Width, dirty confirm, the running state and the scrolling body are the kit's; from S16-73 the kit also disables the form's fields while it runs, for every form dialog (user, 2026-11-28) |
| Source fields | Snowflake | New | `macos/App/Features/Sources/` (the S16-73 plan names the file) | The five fields of AS-1 as one view, used by Add Source now and Copy Source from S16-74. It composes the pieces below; it draws no field of its own |
| Title and Type fields | Snowflake | Ship | `macos/App/Features/Sources/SourceTitleTypeFields.swift` `SourceTitleTypeFields` | Title (Field + Input) and Type (Field + ComboBox) with their display rule, unchanged |
| Date form | Snowflake | Ship | `macos/App/Features/Dates/DateValueEditorForm.swift` `DateValueEditorForm` | The shared date form, inline in a Field (AS-3); not redrawn |
| Date block | Snowflake | Extend | `macos/App/Features/Sources/SourceDateDialog.swift` (`SourceDateForm`'s form and `readsAs`, private today) | The date form and, if AS-4 is A, the Reads as strip under it (a sunken Card, micro caps "Reads as", the date as the header words it) become one small view that the date dialog and the Source fields both draw; S15-D23's marks control joins it later |
| Date error line | Component | Ship | `PVField` `error:` | AS-5's line is the Published date Field's error, not a Callout and not a new control; its words belong to the date form, beside its other date errors, so the date dialog can show the same line later |
| Description field | Snowflake | Ship | today's Field + Input in `SourcesAddDialog` | Moves into the Source fields, same label and hint |
| Private checkbox | Component | Extend | `macos/App/DesignSystem/Components/Checkbox/PVCheckbox.swift` `PVCheckbox` | The sheet's Private (AS-7), with the header switch's label and help as its description; the checkbox gains dimming when its form is disabled. The header's `PVSwitch` is unchanged |
| Copy | — | Extend | `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings` | New: the "Published date" label, its hint, the AS-5 line. Reused: Title, Type, Description, the Private label and help |

**Non-goals.** No new kit primitive, no new date control, no Callout for the date error, no disclosure that hides the date form, no Switch for Private on the sheet.

---

## 7. Handoff

When the board is agreed, write its choices into AS-4 (and any requirement the board changed) and the **Board** line, with the frame names. The S16-73 plan ([`../prs/S16-73-add-source-date-and-private.md`](../../prs/S16-73-add-source-date-and-private.md), [`plan-pr`](../../../../../.agents/skills/plan-pr/SKILL.md)) copies AS-1 – AS-9 and AS-W1 into its Scope and this inventory into its design, and moves from `Blocked — on board S16-D15` to `Planned`. When S16-73 lands, the brief moves to the spike's design archive. S16-D16 extends these frames for the Copy sheet.
