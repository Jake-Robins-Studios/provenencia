# S15-D32 — Source type page and Copy type sheet: one Suggested fields list

**Kind:** Claude Design board (**enhancement** of the Source type page board: the three Suggested fields lists of S15-D6 become one list, and the Copy type sheet's three suggestion ticks of S15-D7 become one. Extend the existing frames; the header, Details, the formats, the locked note, Delete, the list and the Add type dialog are unchanged)
**Spike:** Provenencia Spike 15, slice 11
**View:** the Source type page's side column (Suggested fields), on an editable and on a locked type; the Copy type sheet's ticks; the Source types list's Associated fields number
**Implements later as:** PR **S15-63**
**Board:** — (not drawn yet)
**Review:** with the plan, in [`../prs/S15-63-type-suggests-fields-once.review.md`](../prs/S15-63-type-suggests-fields-once.review.md)
**Depends on:** S15-12 (landed [#856](https://github.com/Jake-Robins-Studios/provenencia/pull/856)): the three lists ([S15-D6](archive/S15-D6-source-type-suggestion-levels.md)); S15-18 (landed [#877](https://github.com/Jake-Robins-Studios/provenencia/pull/877)): the Copy type sheet ([S15-D7](archive/S15-D7-copy-source-type.md)); S15-17 (landed [#924](https://github.com/Jake-Robins-Studios/provenencia/pull/924)): the formats under Details ([S15-D16](archive/S15-D16-source-type-citation-formats.md)); S15-62 (landed [#950](https://github.com/Jake-Robins-Studios/provenencia/pull/950)): a format names a field with no level
**Related:** working rule "A type suggests fields, not levels" (user, 2026-11-22) in [`../deployment-plan.md`](../deployment-plan.md#working-rules); S15-D27 TP-7 (the one list this page had before S15-12, [archived](archive/S15-D27-source-type-page.md)); [`macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide)
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

This brief is an **enhancement**: draw on the Source type page board's existing frames (S15-D6's lists, S15-D7's sheet). Replace the three stacked lists with one list in place; do not keep the three-list frames as a before.

---

## 1. Objective

A Source type suggests the fields its records usually carry. Since S15-12 the type page has held three lists, one per level (on the Source, on each Artifact, on each Evidence graph), because a suggestion said where a value lives. Researchers kept putting values at the "wrong" level, so a citation format now reads each field from the nearest level that holds a value (S15-62), and a suggestion no longer has a level: a type suggests a field once, and every board (the Source's Metadata section, the Artifact sheet, the Evidence graph form) offers all of the type's suggestions. After this board, the type page shows **one** Suggested fields list, and the Copy type sheet has **one** suggestions tick.

**What changes.**

- **One list.** The Suggested fields column holds one ordered list: no level titles, no meanings, no hairlines between lists. It reads as S15-D27's single list did, with today's rows, picker and states.
- **Copy says where the suggestion shows.** Toasts, tooltips and spoken labels name the type, not a level: "Line is now suggested for Census Sources."
- **One Copy tick.** The Copy type sheet's three ticks ("Suggested fields on the Source", "… on each Artifact", "… on each Evidence graph") become one, "Suggested fields", with the list's count.
- **Associated fields** counts the list's fields: each field once.

**What stays.** A row is ordinal, label over mono key, data type badge, and the remove IconButton on an editable type. A new field goes last; there is no reorder (user, 2026-11-14 and 2026-11-23). The picker is today's ComboBox with the plus beside it; Return adds a picked field (S15-D6 SL-4). A plugin's type shows the list read only. Details beside Suggested fields, the pair centred, at every width. The Copy sheet's other ticks, its reading and failure states and its leave rules.

---

## 2. Domain facts

| Fact | What it means on this board |
| --- | --- |
| Source type | A kind of record (Census, Book, Letter, Grave memorial). Seeded types and the project's own are editable; a plugin's type is locked and read only. A project has about 30 types |
| Suggested field | A field the type offers, empty, on every board of a Source of that type: the Source's Metadata section, each Artifact's sheet, each Evidence graph's form. Not required: a researcher leaves it blank or dismisses it on one board. Removing a suggestion never deletes the field or a value already typed |
| No level | A field's value can live on the Source, an Artifact or a graph; a citation reads the nearest one. The type no longer says which: it suggests the field, and the researcher types the value where it fits |
| Order | One order, the order the rows show on every board. A new suggestion goes last. No reorder |
| Sizes | A seeded list holds 3 to 21 fields (Census 21); the vocabulary has about 70. A list of 30 must still read |
| Writes | Adding and removing save at once, one field at a time, as today; never part of the Details draft |
| Existing projects | A type's three lists merge into one, in the order Source, then Artifact, then graph, a field's first place winning. No frame draws the merge |

### 2.1 Copy

The board may refine wording; the PR copies what the board shows. *(today)* marks a string that exists and stays.

| Where | Text |
| --- | --- |
| Section title | "Suggested fields" *(today)* |
| Section hint (editable type) | "Suggestions, not a schema — a record may leave any of them blank" *(today)* |
| Pool hint (editable type) | "The pool is the Metadata vocabulary — add a new field there first if it is missing" *(today)*; under a full list's picker, "Every field in the vocabulary is already in this list" *(today)* |
| Meaning under the section hint | "Offered on every Source, Artifact and Evidence graph of this type" |
| Count | "21 fields" *(today's string)* |
| Empty list | "No suggested fields yet. Assign the fields these records usually carry." |
| Read failed | "Suggested fields could not be loaded", the error, "Try again" *(today)* |
| Picker label (spoken) | "Metadata field to suggest" |
| Plus, before a pick | "Choose a field to assign" *(today)*; spoken "Suggest a field for Census Sources" |
| Plus, with a pick | "Suggest Line for Census Sources" |
| Remove | "Stop suggesting Line for Census Sources" |
| Toast after add | "Field assigned" *(today)* / "Line is now suggested for Census Sources." |
| Toast after remove | "Suggestion removed" *(today)* / "Line is no longer suggested for Census Sources. The field stays in this project’s vocabulary." plus today's clause on values already typed |
| Copy tick | "Suggested fields"; hint "21 fields"; absent "None on this type" *(today)* |
| Copy reading caption | "Reading the original's formats and suggested fields" *(today)* |

### 2.2 What this board is not

- The metadata boards themselves (the Source's Metadata section, the Artifact sheet, the graph form): they draw the same rows as today, only more of them. Their "Suggested by this type" heading stays (user, 2026-11-23).
- Inherited values on a board's rows (S15-D33 → S15-64).
- Reordering suggestions (not planned).
- The citation formats, Insert field and the preview (unchanged).
- Creating a field from the picker (not planned).

---

## 3. Implementation gate

| PR | Ships | Not that PR |
| --- | --- | --- |
| **S15-63** | OL-1 – OL-8, OL-W1: the one list on an editable and a locked type, its states, the copy, one Copy tick, Associated fields counting each field once | Inherited values (S15-64); reorder (not planned) |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| OL-1 | **One list.** The Suggested fields column shows the section title, the hint, the meaning line (§ 2.1) and the pool hint once, then one list. The count sits where the board puts it: on the section title or trailing a single micro-caps header; the board decides, and there is exactly one count. No level title, no level meaning, no divider inside the list. |
| OL-2 | **Rows.** As today: ordinal from 1, label over mono key, data type badge, and on an editable type the remove IconButton. Stored order. No drag handle. |
| OL-3 | **Adding.** One picker (the ComboBox over the vocabulary, label and key searchable) and one plus. The picker leaves out the fields already in the list. The added field goes last, the count goes up, the picker clears and keeps focus, and the toast names the field and the type. Return adds a picked field, as today. |
| OL-4 | **Removing.** A row's remove takes the field out at once with no confirm; the toast says the field stays in the vocabulary and, when values were typed, that they stay. While an add or remove runs, the plus and every remove are disabled. |
| OL-5 | **States.** Empty: § 2.1's copy in today's dashed sunken Card. Reading: today's spinner. Read failed: the retry Callout in place of the rows. Write failed: a danger Callout above the rows, the pick kept. |
| OL-6 | **A plugin's type.** The list read only: no picker, plus, remove, hint or pool hint; the title, count, meaning and empty copy still show. |
| OL-7 | **Copy type sheet.** The six ticks become four, in this order: Icon, Description, Citation formats, Suggested fields. The Suggested fields tick's hint is the list's count; an original with no suggestions shows it unticked and disabled with "None on this type". Everything else in the sheet is as S15-D7 drew it. |
| OL-8 | **Associated fields and VoiceOver.** The types list's Associated fields column counts each suggested field once (Census reads 21) and sorts by it; none shows today's dash. The list is a group spoken "Suggested fields, 21 fields"; a row reads "2, Jurisdiction, jurisdiction, Text"; the plus and remove speak § 2.1's labels. |
| OL-W1 | **Wide.** The side column keeps S15-D27's width (340 – 480pt) and the one list stays in it; Details and Suggested fields stay the centred pair (rule 6): one list of narrow rows reads best in one column. The Copy sheet is a 520pt FormDialog at both widths. A pick in progress and the scroll survive a resize across 1600pt. |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Source type page | Details (560pt) beside Suggested fields (340 – 480pt), centred; one list; the side column under Details below about 880pt | The same centred pair | Nothing |
| Copy type sheet | 520pt FormDialog over the page | The same sheet, centred over the page | Nothing |
| Source types list | As S15-D28 drew it; the number counts each field once | As S15-D28 drew it | Nothing |

---

## 5. Suggested frames

Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440), with the toolbar above; the others at Regular. Draw them beside S15-D6's frames, from the *Source type page · component*.

**Data** (invent every record). **Census** (Provenencia, `census`, used by 14 Sources) suggesting, in order: Creator, Jurisdiction, Schedule, Enumeration district, Piece, Folio, Schedule number, Dwelling, Family, Line, Item, Format, Provider, URL, Accessed, Citing, Database title, Film publication, Roll, Film number, Item number (21). **Letter** (yours, `letter`, used by 0) suggesting nothing. **Grave memorial** (plugin `findagrave`, locked) suggesting Cemetery, Plot, Photographer. Vocabulary: about 70 fields, including Page and Column.

| Frame | Requirement | Draw |
| --- | --- | --- |
| D32-1a / 1b | OL-1, OL-2, OL-W1 | Census's page: Details beside the one list of 21, the page scrolled so the list's end shows. In 1b, a pick in progress |
| D32-2 | OL-3 | The picker open with "col" typed: Column highlighted |
| D32-3 | OL-3 | Right after adding Column by Return: Column 22nd, "22 fields", picker empty and focused, the toast |
| D32-4 | OL-4 | After removing URL: the toast with today's values clause ("…and the 6 Sources, Artifacts and graphs already carrying a value keep it") |
| D32-5 | OL-5 | Letter: the empty list with its copy |
| D32-6 | OL-5 | Census: the retry Callout in place of the rows; and, separately, an add refused with its danger Callout and the pick kept |
| D32-7a / 7b | OL-6 | Grave memorial: the locked note in Details; its three rows read only |
| D32-8a / 8b | OL-7 | The Copy type sheet over Census: four ticks, Suggested fields "21 fields" |
| D32-9 | OL-7 | The sheet over Letter: Description, Citation formats and Suggested fields disabled with "None on this type" |
| D32-10 | OL-8 | The types list with Census's Associated fields reading 21 and Letter's dash |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Page and its columns | Component | Ship | `macos/App/DesignSystem/Components/PageColumns/PVPageColumns.swift` with `PVColumnSplit.sourceTypePage` (`macos/App/Features/SourceTypes/SourceTypePageView.swift`) | Unchanged widths |
| Suggested fields section | Snowflake | Rethink | `macos/App/Features/SourceTypes/SourceTypeSuggestionList.swift` `SourceTypeSuggestedFields` | Title, hint, meaning, pool hint once, then the one list; no `ForEach` over levels |
| The list | Snowflake | Rethink | `macos/App/Features/SourceTypes/SourceTypeSuggestionList.swift` `SourceTypeSuggestionList` | One instance, no level: rows, empty, spinner, retry, error, picker |
| Section title | Component | Ship | `PVSectionHeader` | "Suggested fields"; carries the count when the board puts it there |
| List header | Component | Remove or Ship | `PVSubsectionHeader` | Kept only if the board puts the count on a micro-caps header; no level title |
| Rows | Component | Ship | `PVCard` + `PVDivider`, `CatalogFieldDataTypeBadge` | As today |
| Field picker | Component | Ship | `macos/App/DesignSystem/Components/ComboBox/PVComboBox.swift` `PVComboBox` | One |
| Add / remove | Component | Ship | `PVIconButton` `.plus` / `.dismiss` | Labels name the type (§ 2.1) |
| Empty list | Component | Ship | `PVCard` tone sunken, border dashed | Not EmptyState: the page is not empty |
| Failure (read) | Component | Ship | `macos/App/DesignSystem/Components/Callout/PVRetryCallout.swift` `PVRetryCallout` | In place of the rows |
| Failure (write) | Component | Ship | `PVCallout` tone danger | Above the rows |
| Toast | Component | Ship | `macos/App/DesignSystem/Components/Toast/PVToast.swift` | Copy names the type |
| Copy type sheet | Component | Ship | `macos/App/DesignSystem/Components/FormDialog/PVFormDialog.swift`, `macos/App/Features/SourceTypes/SourceTypeCopyDialog.swift` | Four ticks |
| Part tick | Component | Ship | `macos/App/DesignSystem/Components/CopyPartTick/PVCopyPartTick.swift` `PVCopyPartTick` | One Suggested fields tick in place of three |
| Associated fields column | Snowflake | Ship (number changes) | `macos/App/Features/SourceTypes/SourceTypesListPane.swift` | The engine's count of distinct fields |

**Non-goals.** No new kit primitive. No reorder control or drag handle. No grouping or fold inside the list. No field creation from the picker. No change to the header, Details, formats, Delete, the leave confirm, the list's columns, the Add type dialog or the metadata boards. No change to the page's column widths.

---

## 7. Handoff

When the board is agreed: record the frames and the board's decisions (where the count sits, whether a list header stays, any copy change) on the **Board** line here and in [`README.md`](README.md). S15-63's plan copies OL-1 – OL-8, OL-W1, the copy and the inventory, fills D-9 and § 6 Strings from the board, and moves from `Blocked — on board S15-D32` to `Planned`. When S15-63 lands, this brief moves to the spike's design archive.
