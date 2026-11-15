# S15-D27 — Source types: each type opens on its own page

**Kind:** Claude Design board (**rethink** of the Source types side pane: the 380pt side pane is thrown away and each type gets its own page. The list's header, its Add type dialog (S15-D26, section 05) and its columns stay as drawn; only the side pane's frames are replaced)
**Spike:** Provenencia Spike 15, slice 2
**View:** the Source type page (new, a deep place under Source types, with the toolbar's breadcrumbs above it); the Source types list without its side pane, as far as a row opening the page
**Implements later as:** PR **S15-48**
**Board:** — (not drawn yet). Draw on [Claude Design — Source Types](https://claude.ai/artifact/R94Wfp97eC9cBLaSNBQEga), page *S2-03 Source Types Board*, as a new section 06 "A type's own page"
**Review:** — (not reviewed yet)
**Depends on:** S15-47 (landed [#843](https://github.com/mendahu/provenencia/pull/843)): Add type is a dialog, and the side pane has no add mode
**Related:** working rule "A Source type has its own page" in [`../deployment-plan.md`](../deployment-plan.md#working-rules); the Source page (`SourcePageView`, the nearest page of this kind); S15-D26 (the Add type dialog and its icon grid, [archived](archive/S15-D26-add-source-type-dialog.md)); S15-D28 (the list's columns and Wide, S15-49); S15-D6 (the Artifact and Evidence graph suggestion lists, S15-12); S15-D16 (citation formats, S15-17); [`macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide)
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

### This brief is a rethink

Replace the side pane frames on this board (sections 01 – 04's 380pt pane in its view, edit and locked modes). Keep the list's header with Add type (section 05's dialog stays as drawn) and the list's columns. Draw the type's own page from scratch on Page columns, the way the Source page is a page of its own. Do not keep a side pane beside the list, and do not keep a before/after.

---

## 1. Objective

Today a Source type is read and edited in a 380pt side pane beside the list. That pane has no room for what a type is about to hold: three suggestion lists (Source, Artifact, Evidence graph; S15-12) and three citation formats with a live preview (S15-17). After this board, clicking a type in the list opens **its own page**, a deep place under Source types with the breadcrumb "Source types › Census", reached the same way from the omnibar, Back and Forward, a relaunch, and a field's delete-impact list.

**What changes.**

- **The type's own page:** a header (icon, label, key, origin, usage, delete), its details (Label, Icon, Description with Save and Revert), the locked note on a plugin's type, and today's suggested fields (the Source level only).
- **The list has no side pane.** A row opens the page. The list fills the pane under its header; its columns and its Wide layout are redrawn later (S15-D28).
- **Leaving with unsaved details asks first.** Back, a crumb, the sidebar, the omnibar or any link away from a page with unsaved details shows the kit's discard confirm (user, 2026-11-15).
- **After Add type** (S15-D26's dialog) the new type's page opens. No "Type added" toast: the page opening is the confirmation, as Add source opens the Source page (user, 2026-11-15).
- **After Delete** the list shows again, without the type and with no toast, as deleting a Source returns to the Sources list (user, 2026-11-15).

**What stays.** Every field, rule and word of today's side pane: the key cannot change, Save is disabled until something changed, Revert puts the saved values back, a plugin's type is read-only, the delete check (DeleteImpact) and its blocked notice, the suggestion picker (a combo box over the project's fields) and its hints, the "Type updated", "Field assigned" and "Suggestion removed" toasts. The Metadata page keeps its own list and side pane (working rule).

---

## 2. Domain facts

| Fact | What it means on this board |
| --- | --- |
| Source type | A kind of record (Census, Book, Letter, Parish register). A project has about 30 (the seed has 26). Origin "yours" (the researcher's), "Provenencia" (seeded; editable) or a plugin's (locked: read only, with a note naming the plugin). |
| Label | Required; how the type reads on a Source. Any text with at least one letter or number. |
| Key | Minted from the label when the type was added (`census`). Never changes, even when the label does. Shown in mono. |
| Icon | One of 23 type marks, each with a name and a one-line meaning; picked with the icon grid (S15-D26 drew it once for the Add dialog and the side pane's "Choose an icon" sheet). |
| Description | Optional; one line in the researcher's words. |
| Usage | How many Sources use the type ("in use on 41 sources"). A type that is in use cannot be deleted: DeleteImpact shows what uses it, each row a link. |
| Suggested fields | Metadata fields the type offers on its Sources, in a stored order (a numbered list, no reorder). Today only the Source level is edited. Each row: label, mono key, data type badge, remove (×). Below: a combo box to pick a field from the project's Metadata vocabulary and an add button; a hint says new fields are made on the Metadata page. |
| Later on this page | **S15-12:** the Artifact and Evidence graph suggestion lists beside today's Source list. **S15-17:** three citation formats (full, short, source list) with a live preview. Neither is drawn here; § 4 TP-7 says where each will sit so this page has room for them. |
| Writes | Save writes label, icon and description in one write. Each suggestion add or remove is its own write, at once. Delete is one write after its confirm. |

### 2.1 Copy

Every string is today's unless marked *(new)*.

| Where | Text |
| --- | --- |
| Breadcrumb | "Source types › Census" (the type's label; it follows a rename at once) |
| Header eyebrow | "Source type" |
| Header | Icon, label, origin badge, mono key, "in use on 41 sources"; key hint "The key is minted once from the label and never changes — renaming the type keeps existing sources attached" |
| Delete | Trash icon button "Delete type"; VoiceOver "Delete Census" |
| Details | "Label" (required), "Icon" with its hint and "Change", "Description" with its hint; buttons "Save changes" / "Revert"; saving "Saving…" |
| Locked note | Today's: the type comes from the plugin and is read only |
| Suggested fields | "Suggested fields", the count ("3 fields"), today's hint, today's empty text ("No suggested fields yet — a source of this type will offer nothing but the standard citation. …"), picker placeholder, pool hints |
| Leave confirm | "Discard changes?" / "Your changes will be lost." / "Discard" / "Keep editing" (the kit's discard confirm) |
| Toasts | "Type updated", "Field assigned", "Suggestion removed" (today's) |

### 2.2 What this board is not

- The list's columns, its sort and its Wide layout (S15-D28 → S15-49). This board draws the list only to show that the side pane is gone and that a row opens the page.
- The Artifact and Evidence graph suggestion lists (S15-D6 → S15-12) and citation formats (S15-D16 → S15-17): named slots only, not drawn.
- Copy from in the Add dialog (S15-D7 → S15-18).
- The Metadata page: it keeps its list and side pane.

---

## 3. Implementation gate

| PR | Ships | Not that PR |
| --- | --- | --- |
| **S15-48** | TP-1 – TP-10, TP-W1, TP-W2: the type page, the list without its side pane, rows opening the page, leaving with unsaved details | The list's columns and Wide (S15-49); three suggestion lists (S15-12); formats (S15-17) |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| TP-1 | **The list opens pages.** The Source types list shows only its header (title, description, count line, Add type) and its table, across the whole pane: no side pane. The arrow keys move a highlight without opening anything; a click on a row, or Return on the highlighted row, opens that type's page. Back from a page returns to the list where it was scrolled, with no row highlighted. |
| TP-2 | **Toolbar.** On the page, the toolbar's breadcrumb reads "Source types › Census"; "Source types" goes to the list. Draw the toolbar above the page frames (only the toolbar, not the window). |
| TP-3 | **Header.** On Page columns, a pinned header: the eyebrow "Source type" with Delete at its trailing edge, the icon mark beside the label in display type, the origin badge, the mono key and the usage line, then the key hint. Draw it from the kit; today's side pane header is the content, not the layout to copy. |
| TP-4 | **Details.** A "Details" section: Label (required), Icon (the icon field: the board decides between today's mark + name + key + Change opening the "Choose an icon" sheet, and the S15-D26 grid inline on the page; whichever it picks is drawn once and is the same grid S15-D26 drew), Description; Save changes (disabled until something changed, loading while saving, every field disabled meanwhile) and Revert (disabled until something changed). A blank label, a label with no letter or number, or any failed save shows under Label; nothing is lost. |
| TP-5 | **A plugin's type.** The header as TP-3 (Delete included, as today); in place of the Details form, the locked note and the description read only; the suggested fields read only (no remove, no picker, no hint). |
| TP-6 | **Suggested fields.** Today's section as a page section: title and count, hint, the numbered rows (label, key, data type badge, remove), its empty card, its loading spinner, an error Callout, the picker and its hints. Removing a row and adding a field save at once, as today. |
| TP-7 | **Room for what comes next.** The page's sections, top to bottom: Details; Suggested fields (Source); *(S15-12)* the Artifact and Evidence graph suggestion lists; *(S15-17)* Citation formats. Draw only the first two. Lay the page out so the later sections are added below or beside Suggested fields without moving Details (see TP-W1). |
| TP-8 | **Leaving with unsaved details.** When Label, Icon or Description differs from what is saved, leaving the page (Back, Forward, a crumb, the sidebar, the omnibar, a delete-impact link, the history menu) shows the kit's discard confirm (§ 2.1). Discard leaves and drops the edits; Keep editing stays with them. Saving or Revert first means no confirm. Suggestion writes save at once and never ask. |
| TP-9 | **Delete.** Delete asks DeleteImpact for the type: in use, it shows the blocked notice with the Sources and fields that use the type, each a link that opens its place; not in use, it confirms; on confirm the type is deleted and the list shows, without the type and with no toast. A failed delete shows a danger Callout under the header. |
| TP-10 | **States.** Loading the page shows the header's place and a spinner. A type that no longer exists (deleted elsewhere, an old history entry) shows the list instead. After Add type (S15-D26) the new type's page opens with its empty suggested fields and no toast. After Save, "Type updated" shows at the top right, and the breadcrumb and the header follow the new label. |
| TP-W1 | **Wide, the page.** At Regular one column: the header, Details, then Suggested fields. At Wide two columns on Page columns: Details in the primary column (later joined by Citation formats, S15-17), Suggested fields in the secondary column (later joined by the Artifact and Evidence graph lists, S15-12). The header spans both. Draw the Wide frame so the secondary column visibly has room for two more lists below the Source list. |
| TP-W2 | **Wide, the list.** The list at Wide is today's table without the side pane. It is redrawn by S15-D28; this board draws it at Wide only to show the side pane is gone. |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Source type page | One column: header, Details, Suggested fields | Header across; Details primary; Suggested fields secondary | Suggested fields moves from below Details to the secondary column |
| Source types list | Header and table across the pane | The same, until S15-D28 | Nothing on this board |

---

## 5. Suggested frames

Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440), each with the toolbar above; the others at Regular.

**Data.** About 30 types. Census (Provenencia, used by 41 sources, 3 suggested fields: Author, Publisher, Publication date); Family scrapbook (yours, used by 3, 1 field); Grave memorial (from a plugin `findagrave`, used by 5); Parish register (yours, new, unused, no fields). Invent every record.

| Frame | Requirement | Draw |
| --- | --- | --- |
| 1a / 1b | TP-1, TP-W2 | The list with no side pane, the pointer on the Census row |
| 2a / 2b | TP-2, TP-3, TP-4, TP-6, TP-7, TP-W1 | Census's page, nothing changed: Save and Revert disabled |
| 3 | TP-4 | Census's page with Label changed to "Population census": Save and Revert enabled |
| 4 | TP-4 | The icon picked in the board's chosen way (TP-4) |
| 5 | TP-4 | Saving: Save loading, fields disabled |
| 6 | TP-8 | Frame 3 after Back: the discard confirm over the page |
| 7a / 7b | TP-5 | Grave memorial's page (a plugin's type), read only |
| 8 | TP-6, TP-10 | Parish register's page just after Add type: empty suggested fields, no toast |
| 9 | TP-6 | Census with the picker open on "Archive reference" |
| 10 | TP-9 | Delete on Census: DeleteImpact blocked, the Sources that use it listed |
| 11 | TP-9 | Delete on Parish register: the confirm |
| 12 | TP-10 | After Save: the toast, the breadcrumb "Source types › Population census" |
| 13 | TP-10 | Loading: the header's place and the spinner |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Page layout | Component | Ship (a new caller) | `macos/App/DesignSystem/Components/PageColumns/PVPageColumns.swift` `PVPageColumns` | Pinned header, primary and secondary as TP-W1; as `SourcePageView` uses it |
| Breadcrumbs | Component | Ship | `PVBreadcrumbs` via `WorkspaceToolbar.breadcrumbItems` | The leaf is the type's live label |
| Page header | Snowflake | Rethink | today `VocabularyPanelHeader` in `macos/App/Features/CatalogVocabulary/VocabularyChrome.swift` | Reuse it if the board's header is its content at page width; otherwise a type page header in `Features/SourceTypes/` |
| Delete | Recipe | Ship | `PVIconButton` (trash, danger) + `pvDeleteImpact` (`macos/App/DesignSystem/Recipes/DeleteImpact/PVDeleteImpact.swift`) | As today |
| Section title | Component | Ship | `PVSectionHeader` | "Details", "Suggested fields" |
| Label, Description | Component | Ship | `PVField` + `PVInput` | As the side pane |
| Icon field | Snowflake | Ship or Extend (per TP-4) | today `SourceTypesDetailPane.iconFieldButton(selection:)` and `macos/App/Features/SourceTypes/SourceTypeIconGrid.swift` | One icon grid; no second picker |
| Save / Revert | Snowflake | Ship | `VocabularyFormActions` (`VocabularyChrome.swift`) | Primary + ghost |
| Locked note | Component | Ship | `PVCallout` (neutral, lock) | As today |
| Suggestion rows | Snowflake | Ship | today `SourceTypesDetailPane.suggestionRows` in a `PVCard` | Numbered, data type badge, remove `PVIconButton` |
| Suggestion picker | Component | Ship | `PVComboBox` + `PVIconButton` (plus) | As today |
| Empty suggestions | Component | Ship | `PVCard` (sunken, dashed) | As today |
| Errors | Component | Ship | `PVField` error; `PVCallout` danger | TP-4, TP-6, TP-9 |
| Leave confirm | Component | Ship (a new caller) | `pvConfirm(item:…)` with the kit's discard copy (`L10n.DesignSystem.formDialogDiscardTitle` … `formDialogDiscardKeep`) | As the citation composer's leave confirm |
| Toast | Snowflake | Ship | `VocabularyToast` + `vocabularyToastOverlay` | Updated, suggested, removed |
| List | Snowflake | Ship (no side pane) | `macos/App/Features/SourceTypes/SourceTypesListPane.swift` on `VocabularyListPane` and `PVTable` | A click or Return opens a row (TP-1); the arrows only move the highlight. Redrawn by S15-D28 |
| Side pane | Snowflake | Remove | `macos/App/Features/SourceTypes/SourceTypesDetailPane.swift` | Its pieces move onto the page |

**Non-goals.** No new kit primitive. No side pane or inspector on the page. No second icon picker. No suggestion lists for the Artifact or graph level and no formats (later briefs). No reorder of suggestions (not planned). No change to the Metadata page.

---

## 7. Handoff

When the board is agreed: record the section, its frames and the board's TP-4 answer (the icon field) on the **Board** line here and in [`README.md`](README.md). S15-48's plan copies TP-1 – TP-10, TP-W1, TP-W2, the copy and the inventory, fills its icon field and header Decisions from the board, and moves from `Blocked — on board S15-D27` to `Planned`. When S15-48 lands, this brief moves to the spike's design archive. S15-D6 (S15-12) and S15-D16 (S15-17) extend this board's page frames.
