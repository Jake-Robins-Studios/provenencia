# S15-D6 — Source type page: suggested fields at three levels

**Kind:** Claude Design board (**enhancement** of S15-D27's Source type page: the one "Suggested fields" list in the page's side column becomes three lists, one per level. Extend the existing page frames; the header, Details, the locked note, Delete, the list and the Add type dialog are unchanged)
**Spike:** Provenencia Spike 15, slice 2
**View:** the Source type page's side column (Suggested fields), on an editable and on a locked type; the Source types list's Associated fields number
**Implements later as:** PR **S15-12**
**Board:** agreed 2026-11-16 (user) — [Claude Design — Source Type Page](https://claude.ai/artifact/42ZuWus4ynyz7xUDwcF6zG): artboard *S15-D27 · S15-D6 · Source type page board*, frames "S15-D6 · D6-1a – D6-11" (7b split into 7b and 7c) with decision notes, drawn by *Source type page · component*. Board decisions: a list's header is a micro-caps title, mono count trailing, meaning in italic under it; a hairline and 28pt between lists; no section count; the pool hint once under the section hint (only "Every field in the vocabulary is already in this list" under a full list's picker); copy as § 2.1, plus "Suggest a field on each …" as the plus's spoken label before a pick
**Review:** with the plan, in [`../prs/S15-12-type-suggestions-at-each-level.review.md`](../../prs/S15-12-type-suggestions-at-each-level.review.md) — Fits with changes, rounds 1 – 2
**Depends on:** S15-48 (landed [#848](https://github.com/Jake-Robins-Studios/provenencia/pull/848)): the Source type page, with Details beside one Suggested fields list (S15-D27, [archived](S15-D27-source-type-page.md)); S15-49 (landed [#852](https://github.com/Jake-Robins-Studios/provenencia/pull/852)): the list's columns; S15-06 (landed): every suggestion has a level (`source`, `artifact`, `graph`), and each level is its own ordered list; S15-08 – S15-11 (landed): Artifacts and Evidence graphs hold metadata and show their type's suggestions at their level
**Related:** working rules "Metadata lives at three levels with one vocabulary", "Suggestions have a level", "A Source type has its own page" in [`../deployment-plan.md`](../../deployment-plan.md#working-rules); S15-D27 TP-6 and TP-7 (one list drawn as a block that this board repeats; the S15-12 lists go under Suggested fields in the side column); [`archive/S15-D5-evidence-graph-form.md`](S15-D5-evidence-graph-form.md) (where graph suggestions show); [`S15-D14-source-page-artifacts.md`](../S15-D14-source-page-artifacts.md) (where Artifact suggestions show); [`../evidence-explained-citation-map.md`](../../evidence-explained-citation-map.md) § 6.6; [`macos-client-patterns.md` § 9](../../../../macos-client-patterns.md#9-window-widths-regular-and-wide)
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

Add to S15-D27's Source type page frames on this board (frame 2b and the page component). The page header, Details (Label, Icon, Description, Save and Revert), the locked note, Delete, the leave confirm, the types list and the Add type dialog stay as they are. Only the side column's "Suggested fields" is redrawn: S15-D27 drew it as one block for the Source level (TP-6) and named the place of the other two (TP-7: under it, in the side column). This board draws that block three times, once per level, and the states each list has on its own.

---

## 1. Objective

A Source type suggests the fields its records usually carry, so a new Source of that type opens with them on its metadata board. Since S15-08 a type also suggests fields for each **Artifact** (the copy used: provider, URL, accessed date) and each **Evidence graph** (the item cited: who it is about, line, dwelling, family). The Artifact sheet and the Evidence graph form already show those suggestions, but the Source type page edits only the Source's list, so no researcher can set them. After this board, a type's page shows three lists in its Suggested fields column, one per level, each edited the way the one list is today.

**What changes.**

- **Three lists.** Suggested fields holds a Source list, an Artifact list and an Evidence graph list, stacked in that order in the side column. Each is its own ordered list with its own title, meaning, count, picker, and empty, loading and failure states.
- **A field can be in more than one list.** Page can be suggested on the Source and on each Artifact. Adding a field to one list leaves the other lists alone, and each list's picker offers every field not already in that list.
- **Return adds.** In a list's picker, Return on a highlighted field picks it (as today), and a second Return adds it, as the plus button does; the picker is then empty and still focused, so the next field takes only typing and two Returns (user, 2026-11-15).
- **The list's Associated fields number** counts the fields in all three lists (user, 2026-11-14).
- **Copy names the list.** Toasts, tooltips and spoken labels say which list: "Line is now suggested on each Evidence graph of Census Sources."

**What stays.** Each list's rows look as today's do: ordinal, label over mono key, data type badge, and the remove button on an editable type. A new field goes last in its list; there is no reorder (user, 2026-11-14). The picker is today's searchable ComboBox over the project's metadata fields with the plus button beside it; it never creates a field. A plugin's type shows the three lists read only. Details beside Suggested fields, the pair centred, at every width (S15-D27 TP-W1).

---

## 2. Domain facts

| Fact | What it means on this board |
| --- | --- |
| Source type | A kind of record (Census, Book, Letter, Grave memorial). Seeded types and the project's own are editable; a plugin's type is locked and read only. A project has about 30 types. |
| Level | Where a field's value lives. **Source**: the record as a whole (jurisdiction, schedule, roll number). **Artifact**: one copy of it the researcher used (provider, URL, accessed date, image number). **Evidence graph**: one item in it (who it is about, line, dwelling, family). The fields come from one project vocabulary; the level is only where a type suggests them. |
| Suggested field | A field the type offers, empty, on every Source (or Artifact, or graph) of that type. Not required: the researcher may leave it blank or dismiss it. Removing a suggestion never deletes the field or a value already typed. |
| Order | Each list has its own order, which is the order the rows show on the Source page, the Artifact sheet and the graph form. A new suggestion goes last. There is no way to reorder here. |
| Sizes | A list holds 0 to about 12 fields; the vocabulary has about 60. A list of 20 must still read. |
| Where the suggestions show | Source list: the Source page's Metadata section. Artifact list: the Artifact sheet's copy details (add and edit). Evidence graph list: the Evidence graph form's metadata. An open Source page picks the change up when it is next shown; a sheet or form already open keeps what it opened with. |
| Writes | Adding and removing save at once, one field at a time, as today. They are not part of the Details draft: they never wait for Save changes and never trigger the leave confirm. |
| The side column | 340 – 480pt wide beside Details (560pt), the pair centred; below about 880pt of pane it goes under Details (S15-D27 TP-W1). The page scrolls as one. |

### 2.1 Copy

The board may refine wording; the PR copies what the board shows. Strings marked *(today)* exist and stay.

| Where | Text |
| --- | --- |
| Section title | "Suggested fields" *(today)* |
| Section hint (editable type) | "Suggestions, not a schema — a record may leave any of them blank" (today's says "a source of this type") |
| Source list title / meaning | "On the Source" / "The record as a whole" |
| Artifact list title / meaning | "On each Artifact" / "The copy you used: an image, a scan, a transcript" |
| Evidence graph list title / meaning | "On each Evidence graph" / "One item in the record: a household, an entry" |
| Count beside a list | "3 fields" *(today's string, now per list)* |
| A list's read failed | "Suggested fields could not be loaded", the error, "Try again" *(today, now per list)* |
| Empty Source list | "No Source fields yet. Assign the fields these records usually carry." |
| Empty Artifact list | "No Artifact fields yet. Assign what you note about each copy, such as its provider or URL." |
| Empty Evidence graph list | "No Evidence graph fields yet. Assign what you note about each item, such as its line or household." |
| Picker placeholder, no-match | "Field label or key", "No field in the vocabulary matches that — add it in Metadata first" *(today)* |
| Pool hint | "The pool is the Metadata vocabulary — add a new field there first if it is missing" *(today)*; when the list already holds every field, "Every field in the vocabulary is already in this list" |
| Add button tooltip | Before a pick "Choose a field to assign" *(today)*; with a pick "Suggest Line on each Evidence graph of Census Sources"; when the list holds every field "Every field is already in this list" |
| Remove button | "Stop suggesting Line on each Evidence graph of Census Sources" |
| How a list is named in a sentence | Source: "on each Census Source"; Artifact: "on each Artifact of Census Sources"; Evidence graph: "on each Evidence graph of Census Sources" |
| Toast after add | "Field assigned" / "Line is now suggested on each Evidence graph of Census Sources." |
| Toast after remove | "Suggestion removed" / "Line is no longer suggested on each Evidence graph of Census Sources. The field stays in this project’s vocabulary." (plus today's clause on values already typed, when there are any) |
| List column header | "Associated fields" *(today)*; its value counts all three lists |

### 2.2 What this board is not

- Citation formats and Insert field (S15-D16 → S15-17).
- Reordering suggestions (not planned: user, 2026-11-14).
- Copy from another type in the Add type dialog (S15-D7 → S15-18).
- The seeded suggestions themselves (S15-19 seeds them; this board draws invented data).
- Creating a metadata field from the picker: fields are made on the Metadata page, as today.
- Needed and used marks (S15-D20 → S15-39).
- The page's header, Details, Delete, the leave confirm, the types list and the Add type dialog: unchanged.

---

## 3. Implementation gate

| PR | Ships | Not that PR |
| --- | --- | --- |
| **S15-12** | SL-1 – SL-10, SL-W1: the three lists on an editable and a locked type, their states, Return to add, the copy, the Associated fields count over all three | Formats (S15-17); reorder (not planned); Copy from (S15-18) |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| SL-1 | **Three lists.** The page's Suggested fields column shows the section title and hint once, then three lists stacked in the order Source, Artifact, Evidence graph. Each list has its title, its one-line meaning and its own count. Each list's header is a micro-caps title with its count trailing in mono (the inventory's row), the meaning under it; the board decides the spacing and dividers between lists and whether the section title keeps a count of its own; each list must read as one group, so a researcher always sees which list a picker adds to. No list is hidden behind a tab or a fold: all three are visible on the page. |
| SL-2 | **A list's rows.** As today: ordinal (its place in the list, from 1), field label over mono key, data type badge, and on an editable type a remove IconButton. Rows show in the list's stored order. No drag handle and no reorder control. |
| SL-3 | **Adding.** Each list has its own picker (the ComboBox over the project's metadata fields; label and key both searchable) and its own plus IconButton, disabled until a field is picked. A list's picker leaves out only the fields already in **that** list: Page in the Source list is still offered in the Artifact list. The added field appears last in its list, the list's count goes up by one, the list's picker clears, and the toast names the field, the list and the type. Picking in one list does not change another list's pick. The board decides whether each list carries the pool hint or the section carries it once. |
| SL-4 | **Return adds.** With a field highlighted in a picker's open list, Return picks it (today's ComboBox behaviour). Return again, with the list closed and a field picked, adds it, exactly as the plus button. The picker is then empty and keeps focus. Return in an empty picker adds nothing. Draw one frame showing the picker focused and empty right after a Return add, the new row last in its list. |
| SL-5 | **Removing.** A row's remove button takes it out of that list only, at once and with no confirm (as today); the other lists keep the field. The toast says the field stays in the vocabulary, and, when values were typed, that they stay. While one add or remove runs, every list's plus and remove buttons are disabled. |
| SL-6 | **Empty, loading and failure, per list.** A list with no fields shows its own empty copy (§ 2.1) in today's dashed sunken Card. A list still reading shows today's small spinner in its place. A failed read shows the kit's retry Callout ("Suggested fields could not be loaded", the error, Try again) in place of that list's rows. A failed add or remove shows a danger Callout above that list's rows, and the pick stays. A failure is never shown across all three; the other lists keep working. |
| SL-7 | **A plugin's type.** The three lists show their rows read only: no picker, no plus, no remove, no hint; titles, meanings, counts and empty copy still show. |
| SL-8 | **The list's Associated fields column** shows the total of the three lists for each type (Census with 3 + 4 + 4 shows 11), and sorts by that total. A type with none shows today's dash. |
| SL-9 | **VoiceOver.** Each list is a group whose label is its title and count ("On each Evidence graph, 4 fields"). A row reads "2, Line, line, Text". Each picker's label names its list ("Metadata field to assign on each Evidence graph"). The plus and remove buttons name the field and the list: "Suggest Line on each Evidence graph of Census Sources", "Stop suggesting Line on each Evidence graph of Census Sources". |
| SL-10 | **Length.** A list of 20 fields and two lists of 12 still read: the page scrolls as one; no list scrolls inside itself. |
| SL-W1 | **Wide.** The side column keeps S15-D27's width (340 – 480pt) at Wide and the three lists stay stacked in it; Details and Suggested fields stay the centred pair (TP-W1, rule 6): the lists are narrow rows that read best in one column, and side-by-side lists would need a column of their own wider than the side column. A pick in progress and the page's scroll survive a resize across 1600pt. |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Source type page | Details (560pt) beside Suggested fields (340 – 480pt), centred; the three lists stacked in Suggested fields; the side column under Details below about 880pt | The same centred pair | Nothing |
| Source types list | As S15-D28 drew it; only the Associated fields number changes meaning | As S15-D28 drew it | Nothing |

---

## 5. Suggested frames

Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440), each with the toolbar above; the others at Regular. Draw them beside S15-D27's frame 2b, from its page component.

**Data.** Types (invent every record): **Census** (Provenencia, `census`, used by 14 Sources) with Source list Jurisdiction, Schedule, Roll number; Artifact list Provider, URL, Accessed, Image; Evidence graph list Item, Line, Dwelling, Family. **Letter** (yours, `letter`, used by 0) with Source list Author, Recipient and nothing at the other two levels. **Grave memorial** (plugin `findagrave`, locked) with Source list Cemetery, Plot and Artifact list Photographer. Vocabulary: about 60 fields, including Page, Folio, Entry, Accessed, Provider and Line.

| Frame | Requirement | Draw |
| --- | --- | --- |
| 1a / 1b | SL-1, SL-2, SL-W1 | Census's page, nothing changed: Details beside Suggested fields with its three lists. In 1b, a pick in progress in the Artifact list's picker, to show it survives the resize |
| 2 | SL-3 | Census, the Evidence graph list's picker open with "fol" typed (Folio highlighted; Line absent because the list has it) |
| 3 | SL-3, SL-4 | Right after adding Folio to the Evidence graph list by Return: Folio fifth in that list, the count "5 fields", the picker empty and focused, the toast showing |
| 4 | SL-3 | The Artifact list's picker offering Page while Page is in the Source list |
| 5 | SL-5 | After removing URL from the Artifact list: the toast with today's values clause ("…and the 6 Sources, Artifacts and graphs already carrying a value keep it") |
| 6 | SL-6 | Letter: the Source list with two rows; the Artifact and Evidence graph lists empty, each with its own copy |
| 7 | SL-6 | Census with the Artifact list still reading (spinner) and the retry Callout in place of the Evidence graph list's rows; the Source list's rows unaffected |
| 7b | SL-5, SL-6 | An add to the Artifact list refused: its danger Callout above that list's rows, its pick kept; and, separately, a remove in progress with every plus and remove disabled |
| 8a / 8b | SL-7 | Grave memorial: the locked note in Details; three read-only lists (the Evidence graph list empty) |
| 9 | SL-8 | The types list with Census's Associated fields reading 11 and a type with none showing the dash (S15-D28's list, the number only) |
| 10 | SL-10 | A type with 20 Source fields and 12 in each other list, the page scrolled to the Evidence graph list |
| 11 | SL-1, SL-W1 | Census at a pane of 860pt: Suggested fields under Details, the three lists stacked |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Page and its columns | Component | Ship | `macos/App/DesignSystem/Components/PageColumns/PVPageColumns.swift` with `PVColumnSplit.sourceTypePage` (`macos/App/Features/SourceTypes/SourceTypePageView.swift`) | Unchanged widths; the side column holds the three lists |
| Suggested fields section | Snowflake | Extend | `macos/App/Features/SourceTypes/SourceTypeSuggestionList.swift` | Today one list with the section's title, count and hint. It splits: the section (title, hint) once, then one list view drawn per level |
| One level's list | Snowflake | Extend (one view, three instances) | `SourceTypeSuggestionList` in the same file, given a level | Title, meaning, count, rows, empty, spinner, retry, error, picker. One view drawn three times, not three copies |
| Section title | Component | Ship | `PVSectionHeader` | "Suggested fields", as today |
| A list's title and count | Snowflake | Ship | micro-caps title with a trailing mono count, the shape of the citation composer's step header (`CitationComposerEvidenceColumn.stepper`) | Not a nested SectionHeader: its large title and rule mark a page section, and four of them would read flat. Not a new kit control |
| Rows | Component | Ship | `PVCard` + `PVDivider`, `CatalogFieldDataTypeBadge` | As today |
| Field picker | Component | Ship | `macos/App/DesignSystem/Components/ComboBox/PVComboBox.swift` `PVComboBox` | One per list; today's row (label, key, badge) and list height. Return to add is the form's submit around it, not a new ComboBox behaviour |
| Add / remove | Component | Ship | `PVIconButton` `.plus` / `.dismiss` | Tooltips and spoken labels name the list (§ 2.1) |
| Empty list | Component | Ship | `PVCard` tone sunken, border dashed | Per list, its own copy; not EmptyState (the page is not empty) |
| Loading | Platform | Ship | `ProgressView` | Per list, as today |
| Failure (read) | Component | Ship | `macos/App/DesignSystem/Components/Callout/PVRetryCallout.swift` `PVRetryCallout` | Per list, in place of its rows |
| Failure (write) | Component | Ship | `PVCallout` tone danger | Above that list's rows |
| Toast | Snowflake | Ship | `VocabularyToast` / `vocabularyToastOverlay` | Copy names the list |
| Associated fields column | Snowflake | Ship (number changes) | `macos/App/Features/SourceTypes/SourceTypesListPane.swift` | The engine's total over three lists; no layout change |

**Non-goals.** No new kit primitive. No tab, segmented chooser or fold over the lists (SL-1). No reorder control or drag handle. No second picker design. No field creation from the picker. No per-list scroll. No change to the header, Details, Delete, the leave confirm, the list's columns or the Add type dialog. No change to the page's column widths.

---

## 7. Handoff

When the board is agreed: record the section, its frames and the board's decisions (how a list's title, meaning and count sit; whether the section keeps a count; where the pool hint sits; any copy change) on the **Board** line here and in [`README.md`](../README.md). S15-12's plan copies SL-1 – SL-10, SL-W1, the copy and the inventory, fills D-6 and § 6 Strings from the board, and moves from `Blocked — on board S15-D6` to `Planned`. When S15-12 lands, this brief moves to the spike's design archive.
