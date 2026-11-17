# S15-D7 — Source type page: Copy a type

**Kind:** Claude Design board (**enhancement** of S15-D27's Source type page: a Copy button joins the page header, and a new Copy type sheet opens over the page. Extend the existing page frames; Details, the three Suggested fields lists, the locked note, Delete, the list and the Add type dialog are unchanged)
**Spike:** Provenencia Spike 15, slice 4
**View:** the Source type page's header (its top row), the new Copy type sheet over the page, and the new type's page after Save
**Implements later as:** PR **S15-18**
**Board:** agreed 2026-11-17 (user) — [Claude Design — Source Type Page](https://claude.ai/artifact/42ZuWus4ynyz7xUDwcF6zG), artboard *S15-D27 · S15-D6 · S15-D7 · Source type page board*, the frames named "S15-D7" in its menu (D7-1a, D7-1b, D7-2a, D7-2b, D7-3 – D7-6, D7-7, D7-7b, D7-8 – D7-10) and its decision notes (CT-1 the button, CT-4 ticks, CT-9 leaving, CT-5, CT-3 · CT-8, CT-10, Handoff), drawn by *Source type page · component* (`Source-Type-Page.dc.html`). Board decisions: the kit's `copy` glyph (the app's `.duplicate`), shown disabled while the page loads; Escape or a click outside closes at once when nothing changed; frame 7 split into 7 (duplicate key) and 7b (save failed). The board writes its own duplicate-key sentence; the app keeps the engine's message, as Add type does (D-8)
**Review:** — (not reviewed yet; reviewed with S15-18's plan)
**Depends on:** S15-48 (landed [#848](https://github.com/mendahu/provenencia/pull/848)): the page and its header (S15-D27, [archived](archive/S15-D27-source-type-page.md)); S15-12 (landed [#856](https://github.com/mendahu/provenencia/pull/856)): the three Suggested fields lists (S15-D6, [archived](archive/S15-D6-source-type-suggestion-levels.md)); S15-15 (landed [#871](https://github.com/mendahu/provenencia/pull/871)): a type stores three citation formats; the Copy Source dialog as shipped (S15-D13, [archived](archive/S15-D13-copy-source-dialog.md)), the model for this sheet
**Related:** working rule "A Source type has its own page" in [`../deployment-plan.md`](../deployment-plan.md#working-rules) (Copy sits in the page header, user 2026-11-17); [`../evidence-explained-citation-map.md`](../evidence-explained-citation-map.md) § 6.3 "The editor"; S15-D16 (the format editor, S15-17, drawn by its own brief); [`macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide)
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

Add to the S15-D27 Source type page frames on this board (with S15-D6's three Suggested fields lists). Do not redraw Details, the lists or the locked note. Draw the Copy type sheet as a new turn "S15-D7 · Copy type", on the model of the Copy Source dialog this kit already has (S15-D13's frames, if this board has them; otherwise as § 1 describes it).

---

## 1. Objective

A researcher who wants a type close to one they have (a state census beside the federal census, a second parish register) today adds a blank type and rebuilds its suggested fields at three levels and, soon, its three citation formats by hand. After this board, **Copy** on a type's page opens a short sheet: name the new type, tick what it starts with, and Copy type creates it and opens its page, ready to edit.

The sheet copies the shape of **Copy Source**, which researchers already know: on the Source page a Copy button beside Delete opens a 520pt FormDialog titled "Copy Source" with the title and type fields, a divider, a "Copy from the original" heading and one tick per part, all on; a part the original lacks reads unticked and disabled with "None on this Source"; the parts wait on a read with skeleton bars, and a failed read shows a compact danger Callout with **Read again**.

**What changes.**

- **Copy** joins the page header's top row, before the Delete trash, on every type: the researcher's, Provenencia's and a locked plugin type (copying only reads the original; the copy is the researcher's and editable).
- **The Copy type sheet** (new): Label and its minted Key, then "Copy from the original" with six ticks.
- **After Copy type,** the sheet closes and the new type's own page opens, with no toast, as Add type does.

**What stays.** Everything else on the page; the Add type dialog on the list (it has no Copy).

---

## 2. Domain facts

| Fact | What it means on this board |
| --- | --- |
| Source type | A kind of record (Census, Book, Parish register). Origin "yours", "Provenencia" or a plugin's (locked). A project has about 30. |
| Label and key | The new type's label is required and starts **blank**: the researcher names it. Provenencia mints the key from it as it is typed (State census → `state-census`); the key can never change, so the sheet does not prefill "Copy of Census". Two of the researcher's types cannot share a key. |
| Icon | One of 23 marks. Ticked, the copy takes the original's mark; unticked, the default mark. Changed afterwards on the new page. |
| Description | Ticked, the copy takes the original's description as written; unticked, none. |
| Citation formats | Three forms, each optional: the full note, the short note, the source-list entry. Ticked, the copy starts with the forms the original has. The hint names them. |
| Suggested fields | Ordered lists at three levels: on the Source, on each Artifact, on each Evidence graph. One tick per level, each with its count. The fields themselves are shared vocabulary; only the suggestion is copied. |
| What is not copied | Sources of the type, metadata values, the key. |
| Saved values only | The sheet copies what the original has saved. An unsaved edit in Details is not copied, and leaving the page after Copy type asks about it with the page's existing discard confirm. |
| Writes | One create when Copy type is pressed; nothing before. |

### 2.1 Copy

| Where | Text |
| --- | --- |
| Header button | Icon-only (the duplicate glyph), tooltip and spoken label "Copy…", as on the Source page |
| Sheet title | "Copy source type" |
| Sheet subtitle | "Start a new type of yours from {label}. Its Sources and their values are not copied." |
| Label | "Label" (required); placeholder "State census" |
| Key | Read-only mono field "Key"; placeholder "Minted from the label"; hint "Provenencia mints the key from the label when the type is added" (Add type's) |
| Heading | "Copy from the original" |
| Tick: Icon | "Icon"; hint the mark's name ("Census sheet") |
| Tick: Description | "Description"; hint "The original's description, as written" |
| Tick: Citation formats | "Citation formats"; hint the forms it has, each by its name, joined as a list ("Full note, Short note and Source-list entry"; "Full note and Short note"; "Source-list entry") |
| Tick: Source | "Suggested fields on the Source"; hint "1 field" / "4 fields" |
| Tick: Artifact | "Suggested fields on each Artifact"; hint as above |
| Tick: Evidence graph | "Suggested fields on each Evidence graph"; hint as above |
| A part the original lacks | Unticked, disabled; hint "None on this type" |
| Reading | "Reading the original's formats and suggested fields" |
| Read failed | Title "The original's parts could not be read."; button "Read again" |
| Buttons | "Copy type" / "Cancel" |
| Label errors | Add type's: "A label is required — it is how the type reads on a source."; "That label cannot be turned into a key. Use at least one letter or number."; a duplicate key, the engine's message under Label |
| Save failed | Danger Callout titled "The type was not copied", the engine's message |

### 2.2 What this board is not

- The format editor (S15-D16): the copy's formats are edited there later.
- The Add type dialog (S15-D26): unchanged, no Copy from.
- Copying a Source (S15-D13) or metadata values.

---

## 3. Implementation gate

| PR | Ships | Not that PR |
| --- | --- | --- |
| **S15-18** | CT-1 – CT-10, CT-W1: Copy in the header, the Copy type sheet, the new type's page after Copy type | The format editor (S15-17) |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| CT-1 | **Copy in the header.** An icon-only Copy button (the duplicate glyph, size small) sits in the header's top row immediately before the Delete trash, on every type, locked plugin types included. It is disabled while the type is loading or gone. |
| CT-2 | **The sheet.** Copy opens a FormDialog, 520pt wide as Copy Source, with § 2.1's title and subtitle. From the top: the save-failed Callout when there is one, Label, Key, a divider, the "Copy from the original" heading (micro caps), the six ticks in § 2.1's order. |
| CT-3 | **Label and Key** behave as in the Add type dialog: Label starts blank and focused; Key mints live; the label errors show under Label as the researcher types, and a duplicate key after Copy type. |
| CT-4 | **Ticks.** Each tick is a Checkbox with its label and a hint line, all on when the sheet opens. A part the original lacks is unticked and disabled with "None on this type". The icon is never lacking. |
| CT-5 | **Reading.** Until the original's formats and its three suggestion lists are read, the ticks area shows Copy Source's skeleton bars and caption; Copy type is disabled. A failed read shows the compact danger Callout with Read again in the ticks area; Label stays usable. |
| CT-6 | **Copy type.** The primary button reads "Copy type"; it is disabled while the label has an error or the parts are not read, and shows its loading state while saving, with Label and every tick disabled. |
| CT-7 | **After Copy type.** The sheet closes and the new type's page opens (breadcrumb "Source types › State census"), with no toast, showing the ticked parts: its icon and description in the header and Details, its suggested fields in the three lists. If the original's Details had unsaved edits, the page's existing discard confirm asks before leaving. |
| CT-8 | **Failure.** Any failure other than a label error shows the danger Callout at the top of the sheet; the sheet stays open with everything typed and ticked. |
| CT-9 | **Leaving.** Cancel closes at once. Escape or a click outside asks with the kit's standard discard confirm when a label was typed or a tick was changed. |
| CT-10 | **Keys and VoiceOver.** The Copy button speaks "Copy…"; Return in Label copies when Copy type is enabled; each tick reads its label, its hint and its state; Tab runs Label, then the ticks in order. |
| CT-W1 | **Wide.** The sheet is the same at both widths. The page behind it keeps its one layout at every width (S15-D27 TP-W1: Details beside the Suggested fields lists, the pair centred); draw it at both so the sheet's place is seen. |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Source type page header | Copy before Delete in the top row | The same, in the header's band | Nothing |
| Copy type sheet | 520pt, centred over the page | The same sheet | Nothing: a sheet does not change with the window |

---

## 5. Suggested frames

Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440); the others at Regular. The toolbar's breadcrumb is drawn above the pane in frame 7 only.

**Data.** The original is "Census" (yours): the census-sheet mark; description "A government enumeration of a place's households on one day"; all three formats; 4 fields on the Source, 3 on each Artifact, 5 on each Evidence graph. A second original, "Letter" (Provenencia's): no description, no formats, 2 fields on the Source, none on the other levels. The new type is "State census". Invent every record.

| Frame | Requirement | Draw |
| --- | --- | --- |
| 1a / 1b | CT-1, CT-W1 | The Census page with Copy beside Delete in the header |
| 2a / 2b | CT-2, CT-4, CT-W1 | The sheet over the Census page: Label blank, every tick on, hints from the data |
| 3 | CT-3, CT-6 | "State census" typed, Key `state-census`, the Artifact tick off, Copy type enabled |
| 4 | CT-4 | The sheet over the Letter page: Description, Citation formats, Artifact and Evidence graph ticks disabled with "None on this type" |
| 5 | CT-5 | Reading: the skeleton bars in the ticks area, Copy type disabled |
| 6 | CT-5 | Read failed: the compact Callout with Read again |
| 7 | CT-3, CT-8 | "Census" refused as a duplicate key under Label; a second state with the "The type was not copied" Callout |
| 8 | CT-6 | Saving: Copy type loading, fields and ticks disabled |
| 9 | CT-9 | The discard confirm after a click outside frame 3 |
| 10 | CT-7 | After Copy type: the State census page, the census-sheet mark, the description, 4 Source and 5 Evidence graph suggestions, no Artifact suggestions |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Copy button | Component | Ship (a new caller) | IconButton (`PVIconButton`, `.duplicate`, size small) in `macos/App/Features/SourceTypes/SourceTypePageHeader.swift` | As `SourcePageIdentityHeader.copySourceButton`; before the trash |
| Copy type sheet | Component | Ship (a new caller) | FormDialog (`macos/App/DesignSystem/Components/FormDialog/PVFormDialog.swift` `pvFormDialog`) | As `SourceCopyDialog.swift`: `isDirty`, `confirmDisabled`, `isRunning` |
| Label, Key | Component | Ship | Field + Input | As the Add type dialog's (`SourceTypeAddDialog.swift`), key read-only mono |
| Divider, heading | Component | Ship | Divider; micro-caps text | As Copy Source's "Copy from the original" |
| Part ticks | Component | Ship | Checkbox (`PVCheckbox` with a description) | As Copy Source's `partTick`; a lacking part disabled with its absent hint |
| Reading and its failure | Snowflake | Ship (a new caller) | `macos/App/Features/Sources/SourceFormLoadArea.swift` `SourceFormLoadArea` | The Copy form's read area: skeleton bars, compact danger Callout with Read again |
| Errors | Component | Ship | Field error; Callout tone danger | CT-3, CT-8 |
| Discard confirm | Component | Ship | The kit's standard discard confirm in the sheet | CT-9 |
| Type page header | Snowflake | Extend | `SourceTypePageHeader` | One more button in its top row |

**Non-goals.** No new kit primitive. No icon grid, description field or format text in the sheet: the copy is edited on its page. No Copy from in the Add type dialog. No toast.

---

## 7. Handoff

When the board is agreed: record the frames and any board decision on the **Board** line here and in [`README.md`](README.md). S15-18's plan copies CT-1 – CT-10, CT-W1, the copy and the inventory, and moves from `Blocked — on board S15-D7` to `Planned`. When S15-18 lands, the brief moves to the spike's design archive.
