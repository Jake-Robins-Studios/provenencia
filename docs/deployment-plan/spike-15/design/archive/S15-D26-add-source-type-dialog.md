# S15-D26 — Source types: Add type opens a dialog

**Kind:** Claude Design board (**enhancement** of the Source types page: Add type opens a form dialog instead of turning the side pane into a "New type" form. Extend the existing Source types frames; the list, the header and the side pane's view and edit modes are unchanged)
**Spike:** Provenencia Spike 15, slice 2
**View:** the Source types page (its header's Add type), the new Add type dialog over it, and the side pane after a type is added
**Implements later as:** PR **S15-47**
**Board:** redrawn and agreed 2026-11-14 (user) — [Claude Design — Source Types](https://claude.ai/artifact/R94Wfp97eC9cBLaSNBQEga), page *S2-03 Source Types Board*, section 05 "Add a type — a dialog, not a pane mode": frames 1a (Regular, empty dialog), 1b (Wide, the same 840pt sheet), 2 (key minted live), 3 (icon picked inline, its meaning under the grid), 4 (duplicate key under Label), 4b (danger Callout "The type was not added"), 5 (saving), 6 (discard confirm), 7 (after Add); the dialog's markup is in the component page *Source Types Pane*. Board decision AT-3: a two-column sheet, 840pt, Label, Key and Description on the left and the icon grid always open on the right (one component, *Source Type Icon Grid*, also the body of the side pane's "Choose an icon" sheet); picking is live, with no second confirm. Not built (user, 2026-11-14): AT-9's Return-adds in Description (Return there is a new line) and AT-W1's wrap below 790pt (two columns at every width)
**Review:** — (not reviewed yet)
**Depends on:** — (today's Source types page and its create write)
**Related:** working rule "A Source type has its own page" in [`../deployment-plan.md`](../../deployment-plan.md#working-rules); the Sources list's Add source dialog (the model for this one); S15-D27 (the Source type page, S15-48, which opens after Add once it exists); S15-D7 (Copy from, S15-18, which joins this dialog later); [`macos-client-patterns.md` § 9](../../../../macos-client-patterns.md#9-window-widths-regular-and-wide)
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

Add to the Source types page frames on this board. If the board has no Source types frames yet, draw the page as it is today first: the header (title, description, count line, Add type at the top right), the types list on the left, and the 380pt side pane on the right showing the selected type (header with icon, label, key, origin, usage and delete; Label, Icon and Description with Save and Revert; Suggested fields). Then add this brief's dialog over it. Do not redraw the list or the side pane's view and edit modes.

---

## 1. Objective

Today **Add type** turns the side pane into a "New type" form: the selected type disappears from the pane, a note says suggestions come later, and Cancel puts the old selection back. The side pane is going away (S15-48 gives each type its own page), so adding a type needs its own home. After this board, Add type opens a short dialog, the same kind the Sources list uses for Add source: Label, Icon and Description. Add creates the type and shows it; suggested fields and, later, citation formats are added on the type itself, and all of them are optional.

**What changes.**

- **Add type opens a dialog** over the page. The side pane keeps showing what it showed before.
- **The side pane has no "New type" mode** any more: no "New type" header, no add note ("Suggested fields are assigned after the type is saved."), no Cancel that restores a selection.
- **After Add,** the dialog closes and the new type is selected and shown, with today's "Type added" toast. Once S15-48 lands the same Add opens the type's own page instead; this board draws today's side pane.

**What stays.** The page header, its count line and the Add type button's place (top right). The list, its sort and the side pane's view and edit modes. The key is still minted from the label by Provenencia, and a duplicate key is still refused.

---

## 2. Domain facts

| Fact | What it means on this board |
| --- | --- |
| Source type | A kind of record (Census, Book, Letter, Parish register). The researcher's own types have origin "yours"; seeded ones "Provenencia"; a plugin's are locked. A project has about 30. |
| Label | Required. How the type reads on a Source. Any text with at least one letter or number. |
| Key | Minted by Provenencia from the label when the type is added (Parish register → `parish-register`). It cannot be typed or changed. Two of the researcher's types cannot share a key. |
| Icon | One of 23 type marks (a book, a certificate, a census sheet, a gravestone, a letter and so on), each with a name and a one-line meaning. A new type starts on the default mark. The same icon field will sit on the type's own page (S15-48), so this board draws it once. |
| Description | Optional. One line in the researcher's words. |
| What is not asked here | Suggested fields at any level and citation formats. They are added on the type afterwards, all optional. Copy from another type joins this dialog later (S15-D7); leave room for one more field above Label but do not draw it. |
| Writes | One create when Add is pressed; nothing before. |

### 2.1 Copy

| Where | Text |
| --- | --- |
| Header button | "Add type" (as today) |
| Dialog title | "Add source type" |
| Dialog subtitle | "A kind of record. Suggested fields and citation formats are added on the type afterwards." |
| Label | "Label" (required); placeholder "Parish register" |
| Key | A read-only field "Key" showing "parish-register"; placeholder "Minted from the label"; hint "Provenencia mints the key from the label when the type is added" (today's) |
| Icon | "Icon"; hint "The mark that stands for this type wherever a source of it is listed" (today's) |
| Description | "Description"; hint "What kind of record belongs to this type, in your own words"; placeholder "A bound register of baptisms, marriages or burials kept by a parish" (today's) |
| Buttons | "Add type" / "Cancel" |
| Blank label | "A label is required — it is how the type reads on a source." (today's) |
| No letter or number | "That label cannot be turned into a key. Use at least one letter or number." (today's) |
| Duplicate key | Today's engine message, under Label |
| Toast | "Type added" / "Parish register is in this project’s vocabulary as parish-register." (today's) |

### 2.2 What this board is not

- The Source type page (S15-D27); the list's redesign (S15-D28).
- Copy from (S15-D7).
- Suggested fields and citation formats (S15-D6, S15-D16).
- The Metadata page's Add field: it keeps its side pane form (working rule "A Source type has its own page").

---

## 3. Implementation gate

| PR | Ships | Not that PR |
| --- | --- | --- |
| **S15-47** | AT-1 – AT-9, AT-W1: the Add type dialog, the side pane without its add mode, the new type shown after Add | The type page (S15-48); Copy from (S15-18) |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| AT-1 | **Opening.** Add type, at the header's top right as today, opens a FormDialog over the page with the title and subtitle of § 2.1. The side pane behind it keeps the selected type (or its empty prompt). |
| AT-2 | **Fields, in order:** Label (required, placeholder), Key (a read-only mono field, as the Create Property dialog shows its minted key, updated as the label is typed; its placeholder while blank), Icon, Description. Width as the Sources list's Add source dialog. |
| AT-3 | **Icon.** The icon field shows the chosen mark, its name and key, and a Change link, as the side pane's Icon field does today. It starts on the default mark. **The board decides how the 23 marks are picked from inside this dialog:** today's "Choose an icon" picker as a sheet over the dialog (its grid, its meaning line, "Use icon" and Cancel), or the grid inline in the dialog under a disclosure. Whichever it picks is the one icon field the type page reuses (S15-48); draw it once. The dialog never scrolls the whole form for the grid: if inline, the grid is folded until opened and the dialog's body scrolls only between its fixed title and buttons. |
| AT-4 | **Add.** The primary button reads "Add type", is disabled while Label is blank, and shows its loading state while saving, with every field (the icon field included) disabled. |
| AT-5 | **Errors.** A blank label, a label with no letter or number, and a duplicate key show under Label; any other failure shows a danger Callout at the top of the dialog. The dialog stays open with everything typed. |
| AT-6 | **Leaving.** Cancel closes at once and keeps nothing, as every dialog's Cancel does. Escape or a click outside asks with the kit's standard discard confirm when anything was typed or a mark other than the default was chosen. |
| AT-7 | **After Add.** The dialog closes; the new type is selected in the list and shown in the side pane in its edit mode with its empty Suggested fields; the "Type added" toast shows. An unsaved edit in the side pane is replaced, as selecting another type replaces it today. |
| AT-8 | **No add mode in the side pane.** The pane never shows "New type", the add note or the add-mode Cancel. While the dialog is open, the list keeps its selection highlighted and the pane keeps what it showed, unsaved edits included; Add type is disabled. |
| AT-9 | **Keys and VoiceOver.** Return in Label or Description adds when Add is enabled; the Key field reads by its label and value; the icon field reads as today ("Icon: <mark name> — choose a different one"). |
| AT-W1 | **Wide.** The dialog is the same at both widths (a sheet does not change with the window). The page behind it is today's at both widths; this board draws it at both so the dialog's place is seen. |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Source types page with the Add type dialog | Today's page; the dialog centered over it | Today's page at Wide; the same dialog | Nothing: a sheet does not change with the window |

---

## 5. Suggested frames

Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440); the others at Regular.

**Data.** About 30 types, Census selected in the side pane. The new type is "Parish register" (invent every record).

| Frame | Requirement | Draw |
| --- | --- | --- |
| 1a / 1b | AT-1, AT-2, AT-W1 | The page with Census selected and the empty dialog over it |
| 2 | AT-2, AT-4 | "Parish register" typed, the key preview "parish-register", Add enabled |
| 3 | AT-3 | Choosing the icon in the board's chosen way (the picker over the dialog, or the grid opened inline) with a mark other than the default selected |
| 4 | AT-5 | "Family scrapbook" refused as a duplicate key under Label |
| 5 | AT-4 | Saving: Add loading, fields disabled |
| 6 | AT-6 | The discard confirm after a click outside frame 2 |
| 7 | AT-7, AT-8 | After Add: Parish register selected in the list, the side pane in edit mode with no suggestions, the toast |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Add type button | Snowflake | Ship | `macos/App/Features/CatalogVocabulary/VocabularyChrome.swift` `VocabularyHeader` | Where it is; it now opens the dialog |
| Add type dialog | Component | Ship (a new caller) | `macos/App/DesignSystem/Components/FormDialog/PVFormDialog.swift` `pvFormDialog` | As the Sources list's Add source (`SourcesListView`): `isDirty`, `confirmDisabled`, `isRunning` |
| Label, Description | Component | Ship | Field + Input | As the side pane's today |
| Key | Component | Ship | Field + Input (read-only, mono) | As the Create Property dialog (`PropertiesView` create form) shows its minted key |
| Icon field | Snowflake | Extend (second caller; moves to its own file) | today `SourceTypesDetailPane.iconFieldButton(selection:)` | One icon field for the dialog now and the type page (S15-48) |
| Icon grid | Snowflake | Ship or Extend (per AT-3) | today `SourceTypesDetailPane.swift` `SourceTypeIconPickerForm` in its own `pvFormDialog` | `docs/design-system-layers.md` names it as its snowflake example; if the board puts it inline, it is the same grid under a Disclosure (`PVDisclosureButton`) |
| Errors | Component | Ship | Field error; `PVCallout` tone danger | AT-5 |
| Discard confirm | Component | Ship | The kit's standard discard confirm in `PVSheet` | AT-6 |
| Toast | Snowflake | Ship | `VocabularyToast` | As today |
| Side pane | Snowflake | Remove (add mode only) | `macos/App/Features/SourceTypes/SourceTypesDetailPane.swift` | View and edit modes unchanged |

**Non-goals.** No new kit primitive. No second icon picker. No add mode left in the side pane. No suggested fields or formats in the dialog.

---

## 7. Handoff

When the board is agreed: record the frames and the board's AT-3 answer on the **Board** line here and in [`README.md`](README.md). S15-47's plan copies AT-1 – AT-9, AT-W1, the copy and the inventory, fills its icon Decision from AT-3, and moves from `Blocked — on board S15-D26` to `Planned`. When S15-47 lands, the brief moves to the spike's design archive.
