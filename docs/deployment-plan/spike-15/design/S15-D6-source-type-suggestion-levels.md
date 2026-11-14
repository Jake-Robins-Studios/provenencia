# S15-D6 — Source type page: suggested fields at three levels

**Kind:** Claude Design board (**enhancement** of the Source types page: a type's one "Suggested fields" list becomes three lists, one per level. Extend the existing frames; the types list, the header, the type form and the delete flow are unchanged)
**Spike:** Provenencia Spike 15, slice 2
**View:** the Source types page's detail pane (a selected type, editable or locked), and the Associated fields column of its list
**Implements later as:** PR **S15-12**
**Board:** — (not drawn yet)
**Review:** — (not reviewed yet)
**Depends on:** S15-06 (landed): every suggestion has a level (`source`, `artifact`, `graph`), and each level is its own ordered list; S15-08 – S15-11 (landed): Artifacts and Evidence graphs hold metadata and show their type's suggestions at their level
**Related:** working rules "Metadata lives at three levels with one vocabulary", "Suggestions have a level" in [`../deployment-plan.md`](../deployment-plan.md#working-rules); [`S15-D14-source-page-artifacts.md`](S15-D14-source-page-artifacts.md) (where Artifact suggestions show); [`archive/S15-D5-evidence-graph-form.md`](archive/S15-D5-evidence-graph-form.md) (where graph suggestions show); [`../evidence-explained-citation-map.md`](../evidence-explained-citation-map.md) § 6.6; [`macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide); [`docs/ideas/wide-layout.md`](../../../ideas/wide-layout.md) (Source types row)
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

Add to the Source types page frames on this board. The page header, the types list (label, key, origin, Associated fields, usage), the detail pane's header, the type form (Label, Icon, Description, Save and Revert), the locked note on a plugin type, the add-type note and the delete flow stay as they are. Only the "Suggested fields" part of the detail pane is redrawn, and the Associated fields number in the list changes meaning (SL-8). **How the three lists sit in the pane is the board's call** (stacked sections, a segmented control over one list, disclosures, or another arrangement built from kit pieces): the requirements below say what each list must show and do, not where it goes.

---

## 1. Objective

A Source type suggests the fields its records usually carry, so a new Source of that type opens with them on its metadata board. Since S15-08 a type also suggests fields for each **Artifact** (the copy used: provider, URL, accessed date) and each **Evidence graph** (the item cited: who it is about, line, dwelling, family). Those suggestions already show on the Artifact sheet and the Evidence graph form, but the Source types page can only edit the Source's list, so today no researcher can set them. After this board, a researcher picks a type and edits three lists, one per level, the same way they edit the one list today.

**What changes.**

- **Three lists.** "Suggested fields" holds a Source list, an Artifact list and an Evidence graph list. Each is its own ordered list with its own count, its own add control and its own empty, loading and failure states.
- **A field can be in more than one list.** `page` can be suggested on the Source and on each Artifact. Adding a field to one list does not remove it from another, and each list's picker offers every field not already in that list.
- **The list's Associated fields number** counts the fields in all three lists (user, 2026-11-14).
- **Toasts name the list.** "Line is now suggested on each Evidence graph of a Census Source."

**What stays.** Each list's rows look as today's do: ordinal, label over mono key, data type badge, and the remove button on an editable type. New fields go at the end of their list; there is no reorder control (user, 2026-11-14). The picker is today's searchable ComboBox over the project's metadata fields with the plus button beside it; it never creates a field. A plugin type shows the lists read-only. While adding a new type, the pane shows today's note instead of the lists ("Suggested fields are assigned after the type is saved.").

---

## 2. Domain facts

| Fact | What it means on this board |
| --- | --- |
| Source type | A kind of record (Census, Book, Letter, Grave memorial). Seeded types and the project's own are editable; a plugin's type is locked and read-only. A project has about 30 types. |
| Level | Where a field's value lives. **Source**: the record as a whole (jurisdiction, schedule, roll number). **Artifact**: one copy of it the researcher used (provider, URL, accessed date, image number). **Evidence graph**: one item in it (who it is about, line, dwelling, family). The fields come from one project vocabulary; the level is only where a type suggests them. |
| Suggested field | A field the type offers, empty, on every Source (or Artifact, or graph) of that type. A suggestion is not required: the researcher may leave it blank or dismiss it. Removing a suggestion never deletes the field or any value already typed. |
| Order | Each list has its own order, which is the order the board rows show on the Source page, the Artifact sheet and the graph form. A new suggestion goes last. There is no way to reorder on this page. |
| Sizes | A list holds 0 to about 12 fields; the vocabulary has about 60 fields. A list of 20 must still read. |
| Where the suggestions show | Source list: the Source page's Metadata section. Artifact list: the Artifact sheet's copy details (add and edit). Evidence graph list: the Evidence graph form's metadata. An open Source page picks the change up when it is next shown; a sheet or form already open keeps what it opened with. |
| Writes | Adding and removing save at once, one field at a time, as today. Nothing else on the page is a draft for them: they do not wait for the type form's Save. |

### 2.1 Copy

The board may refine wording; the PR copies what the board shows.

| Where | Text |
| --- | --- |
| Section label | "Suggested fields" (as today) |
| Section hint (editable type) | "Suggestions, not a schema — a record may leave any of them blank" |
| Source list title / meaning | "On the Source" / "The record as a whole" |
| Artifact list title / meaning | "On each Artifact" / "The copy you used: an image, a scan, a transcript" |
| Evidence graph list title / meaning | "On each Evidence graph" / "One item in the record: a household, an entry" |
| Count beside a list | "3 fields" (as today, per list) |
| Empty Source list | "No Source fields yet. Assign the fields these records usually carry." |
| Empty Artifact list | "No Artifact fields yet. Assign what you note about each copy, such as its provider or URL." |
| Empty Evidence graph list | "No Evidence graph fields yet. Assign what you note about each item, such as its line or household." |
| Picker placeholder, no-match, pool hints | As today |
| Add button tooltip and spoken label | "Suggest Line on each Evidence graph of a Census Source" (names the field and the list); before a pick, today's "Choose a field to assign" |
| Remove button | "Stop suggesting Line on each Evidence graph of a Census Source" |
| How a list is named in a sentence | Source: "on each Census Source"; Artifact: "on each Artifact of a Census Source"; Evidence graph: "on each Evidence graph of a Census Source" |
| Toast after add | "Field assigned" / "Line is now suggested on each Evidence graph of a Census Source." |
| Toast after remove | "Suggestion removed" / "Line is no longer suggested on each Evidence graph of a Census Source. The field stays in this project’s vocabulary." (plus today's clause on values already typed, when there are any) |
| List column header | "Associated fields" (as today); its value counts all three lists |

### 2.2 What this board is not

- Citation formats and Insert field (S15-D16, S15-17).
- Reordering suggestions (not planned: user, 2026-11-14).
- Copying another type's suggestions to a new type (S15-D7, S15-18).
- The seeded suggestions themselves (S15-19 seeds them; this board draws invented data).
- Creating a metadata field from the picker: fields are made on the Metadata page, as today.
- Needed and used marks (S15-D20).
- The types list's own Wide layout beyond the Associated fields number (the list keeps today's columns).

---

## 3. Implementation gate

| PR | Ships | Not that PR |
| --- | --- | --- |
| **S15-12** | SL-1 – SL-10, SL-W1: the three lists on an editable and a locked type, their states, the toasts, the Associated fields count over all three | Formats (S15-17); reorder (not planned); Copy from (S15-18) |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| SL-1 | **Three lists.** A selected type's "Suggested fields" shows three lists in the order Source, Artifact, Evidence graph, each with its title, its one-line meaning and its count. The board decides how they sit in the 380pt pane (all visible, one at a time, or folded), with one rule: a researcher can see which list they are adding to before they add, and can reach every list without leaving the type. When the board shows one list at a time, the chosen list survives a type switch and a resize (SL-W1). |
| SL-2 | **A list's rows.** As today: ordinal (its place in the list, from 1), field label over mono key, data type badge, and on an editable type a remove IconButton. Rows show in the list's stored order. No drag handle and no reorder control. |
| SL-3 | **Adding.** Each list has its own picker (the ComboBox over the project's metadata fields, label and key both searchable) and its own plus IconButton, which stays disabled until a field is picked, with today's tooltips. A list's picker leaves out the fields already in **that** list only: Page in the Source list is still offered in the Artifact list. The added field appears last in its list, its count goes up by one, the list's picker clears, and the toast names the field, the list and the type. Picking in one list does not change another list's pick. |
| SL-4 | **Removing.** A row's remove button takes it out of that list only, at once and with no confirm (as today); the other lists keep the field. The toast says the field stays in the vocabulary, and, when values were typed, that they stay. While one remove runs, every list's remove buttons are disabled. |
| SL-5 | **Empty, loading and failure, per list.** A list with no fields shows its own empty copy (§ 2.1) in today's dashed sunken card. A list still reading shows today's small spinner in its place. A failed read or write shows a danger Callout inside the list it belongs to, never across all three; the other lists keep working. |
| SL-6 | **Locked (plugin) type.** The three lists show their rows read-only: no picker, no plus, no remove, no hint; counts and empty copy still show. |
| SL-7 | **Adding a type.** While the pane holds the new-type form, the lists do not show; today's note shows in their place. After Add type the pane shows the three lists, all empty. |
| SL-8 | **The list's Associated fields column** shows the total of the three lists for each type (Census with 3 + 4 + 4 shows 11), and sorts by that total. A type with none shows today's dash. |
| SL-9 | **VoiceOver.** Each list is a group whose label is its title ("On each Evidence graph, 4 fields"). A row reads "2, Line, line, Text". The plus and remove buttons name the field and the list: "Suggest Line on each Evidence graph of a Census Source", "Stop suggesting Line on each Evidence graph of a Census Source". |
| SL-10 | **Length.** A list of 20 fields and two lists of 12 still read: the detail pane scrolls as one; no list scrolls inside itself. |
| SL-W1 | **Wide.** Today the detail pane is 380pt at both widths and the types list takes the rest. The board decides whether at Wide the pane widens so the three lists sit side by side (each list keeps its Regular row width), or stays 380pt and says why in one clause on the board. The types list keeps its columns and its maximum width either way. Whatever the arrangement, a pick in progress, the chosen list (when one list shows at a time) and the pane's scroll survive a resize across 1600pt. |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Source types page | Types list beside a 380pt detail pane; the three lists inside the pane in the board's arrangement | The board's call (SL-W1): the pane widens for three side-by-side lists, or stays 380pt | At most the three lists move from stacked to side by side; nothing moves out of the pane |

---

## 5. Suggested frames

Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440); the others at Regular.

**Data.** Types (invent every record): **Census** (seeded, `census`, used by 14 Sources) with Source list Jurisdiction, Schedule, Roll number; Artifact list Provider, URL, Accessed, Image; Evidence graph list Item, Line, Dwelling, Family. **Letter** (yours, `letter`, used by 0) with Source list Author, Recipient and nothing at the other two levels. **Grave memorial** (plugin `memorial-kit`, locked) with Source list Cemetery, Plot and Artifact list Photographer. Vocabulary: about 60 fields, including Page, Folio, Entry, Accessed, Provider and Line.

| Frame | Requirement | Draw |
| --- | --- | --- |
| 1a / 1b | SL-1, SL-2, SL-8, SL-W1 | The page with Census selected: the list (Census shows 11 under Associated fields) and the detail pane with its three lists |
| 2 | SL-3 | Census, the Evidence graph list's picker open with "fol" typed (Folio shown; Line absent because the list has it), then the plus enabled |
| 3 | SL-3 | Right after adding Folio to the Evidence graph list: it is fifth in that list, the count reads 5, the toast shows |
| 4 | SL-3 | The Artifact list's picker offering Page while Page is already in the Source list |
| 5 | SL-4 | After removing URL from the Artifact list: the toast with today's values clause ("…and the 6 Sources, Artifacts and graphs already carrying a value keep it") |
| 6 | SL-5 | Letter: Source list with two rows, Artifact and Evidence graph lists empty with their own copy |
| 7 | SL-5 | Census with the Artifact list still reading (spinner) and a failure Callout in the Evidence graph list only |
| 8 | SL-6 | Grave memorial: three read-only lists (one empty) under the locked note |
| 9 | SL-7 | The new-type form with the note in place of the lists |
| 10 | SL-10 | A type with 20 Source fields and 12 in each other list, the pane scrolled to its middle |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Detail pane | Snowflake | Extend | `macos/App/Features/SourceTypes/SourceTypesDetailPane.swift` `SourceTypesDetailPane` | Header, form, locked note and add note unchanged; the suggested-fields part composes three lists |
| One level's suggestion list | Snowflake | Rethink (one per level) | today `SourceTypesDetailPane.suggestedFields(isLocked:)`, `suggestionRows`, `assignControl` | One view drawn three times with a level, not three copies. Rows inside a Card, as today |
| List title and count | Component | Ship | `pvMicroCaps` label + mono count, as today's section header | Not a new header control. If the board shows one list at a time, the chooser is the Segmented control (ChipGroup segmented), not a local tab bar |
| Data type badge | Snowflake | Ship | `CatalogFieldDataTypeBadge` | As today |
| Field picker | Component | Ship | `macos/App/DesignSystem/Components/ComboBox/` `PVComboBox` | One per list; today's row (label, key, badge) and list height |
| Add / remove | Component | Ship | `PVIconButton` `.plus` / `.dismiss` | Tooltips name the list (§ 2.1) |
| Empty list | Component | Ship | `PVCard` tone sunken, border dashed | Per list, its own copy; not EmptyState (the pane is not empty) |
| Loading | Platform | Ship | `ProgressView` | Per list, as today |
| Failure | Component | Ship | `PVCallout` tone danger | Inside the list it belongs to |
| Toast | Snowflake | Ship | `VocabularyToast` / `vocabularyToastOverlay` | Copy names the list |
| Associated fields column | Snowflake | Ship (number changes) | `macos/App/Features/SourceTypes/SourceTypesListPane.swift` | The engine's total over three lists |
| Disclosure (only if the board folds lists) | Component | Ship | `macos/App/DesignSystem/Components/Disclosure/PVDisclosureButton.swift` `PVDisclosureButton` | No local chevron control |

**Non-goals.** No new kit primitive. No reorder control or drag handle. No second picker design. No field creation from the picker. No per-list scroll. No change to the types list's columns or the type form.

---

## 7. Handoff

When the board is agreed: record the frames and the board's decisions (the arrangement of the three lists, the Wide answer, any copy change) on the **Board** line here and in [`README.md`](README.md). S15-12's plan copies SL-1 – SL-10, SL-W1, the copy and the inventory, and moves from `Blocked — on board S15-D6` to `Planned`. When S15-12 lands, the brief moves to the spike's design archive.
