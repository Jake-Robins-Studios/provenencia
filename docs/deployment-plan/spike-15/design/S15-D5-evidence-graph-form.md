# S15-D5 — Evidence graph form and graph rows: the graph's metadata

**Kind:** Claude Design board (**enhancement** of the Source page: the Evidence graph form becomes a two-column form with a metadata board, and each graph row on the page shows its saved values read-only. Extend the existing frames; the rest of the Source page is unchanged)
**Spike:** Provenencia Spike 15, slice 2
**View:** the Evidence graph form (add and edit), and the graph rows in the Source page's Evidence graphs section
**Implements later as:** PR **S15-11**
**Board:** agreed 2026-11-14 — [Claude Design — Source Detail](https://claude.ai/artifact/443NPNYmGErAmxgV1fBsFK), page *Source page*: row "Evidence graphs" (g-values, g-values-wide, g-read-failed) and row "Evidence graph form" (gf-meta-add, gf-meta-edit, gf-meta-addrow, gf-meta-nosugg, gf-meta-discard, gf-meta-saving, gf-meta-refused, gf-meta-openfield, gf-meta-sixty, gf-meta-long, gf-meta-narrow). Board decisions (its S15-D5 note): 880pt in two equal columns, no divider; one 560pt column below a 960pt pane, chosen when the form opens; the body scrolls at 560pt between the fixed title and buttons, the checklist keeps its 264pt list and the kept list its 320pt; "+n more" opens the form at the metadata; the read-only column is one view for both owners and its "+n more" reads "n more details of <ref>". The board's body also caps at the viewport height minus 300pt, a web-page stand-in; the app keeps the kit's fixed 560pt
**Review:** [`S15-D5-evidence-graph-form.review.md`](S15-D5-evidence-graph-form.review.md)
**Depends on:** S15-08 (landed [#791](https://github.com/mendahu/provenencia/pull/791)): every Evidence graph holds its own metadata; S15-36 (landed #810): a metadata board can hold a draft; S15-34 (landed [#819](https://github.com/mendahu/provenencia/pull/819)): the inline Add field row, the kit's key order in a sheet, the read-only metadata value view; S15-35 (landed [#824](https://github.com/mendahu/provenencia/pull/824)): the Artifact row's read-only copy-details column; S15-10 (landed [#829](https://github.com/mendahu/provenencia/pull/829)): a new owner's form opens with its type's suggestions
**Related:** working rules "Metadata lives at three levels with one vocabulary", "One metadata board", "A board adds a field in an inline row", "Metadata saves with its owner's write", "The item is a graph field" in [`../deployment-plan.md`](../deployment-plan.md#working-rules); [`S15-D14-source-page-artifacts.md`](S15-D14-source-page-artifacts.md) (the Artifact sheet and the Artifact row this board follows: SA-4, SA-6, SA-8, SA-9, SA-13, SA-15); [`S15-D1-source-page.md`](S15-D1-source-page.md) (SD-W1's columns); [`../evidence-explained-citation-map.md`](../evidence-explained-citation-map.md) §§ 6.5, 6.6, 6.9; [`macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide)
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

Add to the Source page frames on this board. The Evidence graph form keeps its title, subtitle, Name, Description, Artifacts checklist and kept-linked list; it gains one section. The graph rows keep their name, ref, counts, description and actions; they gain one column. Draw the graph rows inside the existing Source page frames and the form over them. Do not redraw the Artifact sheet, the Artifacts section or the Source's own Metadata section.

---

## 1. Objective

A researcher who files a whole census page as one Source makes one Evidence graph per household. Each household has its own item details: who it is about, its line, dwelling and family numbers. Today there is nowhere to type them. After this board, the Evidence graph form holds them on the same metadata board the Artifact sheet uses, saved with the form's one Save, and each graph row on the Source page shows them read-only, the way each Artifact row shows its copy details.

**What changes.**

- **The graph form becomes two columns** (user, 2026-11-14): Name, Description and the metadata board on the left; the Artifacts checklist and the kept-linked list on the right. It is the app's first two-column form; if the user likes it, the other sheets follow ([`wide-layout.md`](../../../ideas/wide-layout.md) "Two-column form sheets").
- **The graph form** gains "Evidence graph metadata" under Description: the graph's saved values to edit, clear and reorder, the Source type's graph suggestions to fill or dismiss, and the inline Add field row. Nothing saves until Save.
- **A long Artifact list never makes the form scroll.** The Artifacts checklist scrolls inside its own capped list, as it does today, and so does the kept-linked list. The form's body scrolls between its fixed title and buttons only when a column is taller than the kit's scrolling body (560pt): many metadata values, or a long kept-linked list (user, 2026-11-14).
- **The form is 880pt wide** (today 520pt), two equal columns. When the Source page's pane is narrower than 960pt it falls back to one 560pt column, in the order of EG-1's fallback.
- **Each graph row** shows the graph's saved values read-only in a column, as the Artifact row does.

**What stays.** The form's title, subtitle and buttons, its Name and Description, the Artifacts checklist with its All row, locks, hints, loading and failure lines, the kept-linked list, and its error Callout. The graph row's name, ref, count line, description, Open, Edit and Delete. The Evidence graphs section's header, Add evidence graph and its loading and failure states. The Artifact sheet and every other part of the Source page.

---

## 2. Domain facts

| Fact | What it means on this board |
| --- | --- |
| Evidence graph | One item in the Source drawn as Subjects and their relationships: on a census page, one household. It has a ref (`GPH-` and five letters or digits, such as `GPH-3MW8R`), a name, an optional description, and the Source's Artifacts it links (at least one). A Source holds 1 to 60 graphs. |
| Evidence graph metadata | The graph's own metadata: field–value pairs from the same field list as the Source's and the Artifact's. Every value is text; a URL field's value is a link. Most graphs have 0 to 5. |
| Suggestions | The Source's type suggests fields for its graphs. On the board's Census type they are Item, Line, Dwelling and Family, in that order. Suggestions show only in the form, to fill or dismiss; the graph row shows saved values only, never an empty suggested field. A type with no graph suggestions shows none: the board is only its Add field row. |
| Item | The graph-level field `item`: what the graph is about, as a citation wants it ("Ada Robins", "household of Thomas Hale", "baptism of Ada Smith, 3 March 1830"). It is typed, never derived from the graph's Subjects. |
| Other fields | Any field from the project's field list can be added to a graph with Add field (for example Folio, Entry, Schedule). |
| Where the values come from | S15-11 makes the Source page's read carry each graph's saved values with its suggestions, as it already carries each Artifact's; today nothing on the page holds them. A Save answers the graph's rows, and the page shows them with no reload, as an Artifact Save does. |
| Opening the form | Add: the form opens with the type's graph suggestions, empty; a typeless Source has none. While they are read, a second click on Add evidence graph opens nothing; if they cannot be read, the form does not open and the page's error banner shows the error, with the same guard and message as Add artifact. Edit: the form reads the graph's values from the engine before it opens (another window may have changed them), with the same guard and banner; it has no loading state of its own. Which graphs the Source has stays with the graph list; the page read adds only each graph's values, keyed by graph. |
| Writes | Nothing saves until Save. One Save writes the name, description, Artifact links and metadata together, in add mode and in edit mode. The engine judges each value: a refused value comes back naming its field. |
| Scale | Up to 60 graphs on one Source and 60 Artifacts in the form's checklist. The graph rows stay scannable at 60. |

### 2.1 Copy

| Where | Text |
| --- | --- |
| Form section | "Evidence graph metadata" |
| Board | "Suggested by this type"; "Add field" (as in the Artifact sheet) |
| Form titles, subtitle, buttons | As today: "Add evidence graph" / "Edit evidence graph" with the ref; "Add" / "Save"; "Cancel" |
| Refused value | "This metadata change can't be saved." under its row (as in the Artifact sheet) |
| A field left open at Save | "Finish the open field first: save its value or clear it." in the top Callout: the board's open-field message, one string for every form that holds a board |
| Graph row, past four values | "+n more" (as on the Artifact row) |

### 2.2 What this board is not

- The Artifact sheet, the Artifact rows and the Source's own Metadata section (S15-D14, S15-D1).
- Needed and used marks on a row (S15-D20), the Unknown and Supplied control (S15-D22).
- The Source type page's graph suggestion list (S15-D6).
- The evidence graph canvas: it shows no metadata.
- Nudging researchers toward one graph per household (map § 7).
- Closing the form when another window deletes its graph: the form behaves as today (Save reports the failure in its top Callout).
- The Copy Source form's Artifact checklist: unchanged.

---

## 3. Implementation gate

| PR | Ships | Not that PR |
| --- | --- | --- |
| **S15-11** | EG-1 – EG-10, EG-W1: the board in the graph form in both modes, the two-column form and its fallback, the read-only values on each graph row | Needed-field marks (S15-39); Unknown and Supplied (S15-41); the type page's graph list (S15-12) |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| EG-1 | **Where everything sits.** The save error Callout (when there is one) spans the form's width at the top. Below it two columns side by side, top-aligned. **Left:** Name (required), Description, **Evidence graph metadata**. **Right:** the Artifacts checklist with its hint and its none-checked line, then on an edit the kept-linked list. No divider between the columns; their gap separates them. **One-column fallback** (pane below 960pt): the Callout, Name, Description, Evidence graph metadata, a divider, the checklist, the kept-linked list. The board is a Field labeled "Evidence graph metadata" holding the same metadata board as the Artifact sheet's "Artifact metadata". |
| EG-2 | **The board in the form.** The same board as the Artifact sheet (S15-D14 SA-6, SA-13): saved rows to edit, clear (the row's trash, no confirm) and reorder by drag, where a row being edited cannot be confirmed empty; "Suggested by this type" to fill or dismiss; the inline Add field row (a field ComboBox of the fields not on the board, a mono value Input, ✓ and ✕; ✓ disabled until a field is picked and a value typed). Draw add mode with the four Census suggestions empty; edit mode with Item, Line and Dwelling saved and Family suggested; and a type with no graph suggestions, where only Add field shows. |
| EG-3 | **Nothing saves until Save.** As SA-8: confirming a row, filling or dismissing a suggestion, clearing, reordering and adding change the draft and write nothing. Cancel closes the form at once and keeps nothing, as every dialog's Cancel does; Escape or a click outside asks with the kit's standard discard confirm when anything differs from what opened; a value typed and then put back counts as unchanged. |
| EG-4 | **Keys.** As SA-15: Escape closes an open row edit or the open Add field row first, then the form; Return in a row confirms the row, never the form's Add or Save. The kit already does this. |
| EG-5 | **Saving and failure.** While saving, the primary button shows its loading state and the fields and board are disabled. A refused value shows "This metadata change can't be saved." under its row; a field left open shows "Finish the open field first: save its value or clear it." in the top Callout; a missing name shows under Name, as today; any other failure shows today's top Callout. The form stays open with everything typed. After a save it closes and the graph row shows the new values. |
| EG-6 | **Only the lists scroll for length.** The Artifacts checklist scrolls inside its own list (the All row stays above it), capped as today at 264pt, and the kept-linked list inside its own cap of 320pt, as today, so 60 Artifacts never lengthen the form. The body uses the kit's scrolling body (at most 560pt between the fixed title and buttons): it scrolls only when the taller column passes that, and the two columns scroll together. In the one-column fallback the body scrolls more often; that is accepted. |
| EG-7 | **The form's width.** 880pt in two equal columns; 560pt in the one-column fallback, chosen when the sheet opens from the Source page pane's width (below 960pt: one column) and kept while it is open. The checklist's rows and the kept-linked list take their column's width. |
| EG-8 | **Graph row values, read-only.** Each graph row on the Source page shows its saved values only, in their saved order, as field name (muted caption, one 96pt column) and value (mono, one line, truncated; a URL is a link), in a column between the name block and the actions, drawn by the same read-only view as the Artifact row's copy-details column, at its width. At most four values, then "+n more", which opens the graph's edit form scrolled to Evidence graph metadata when the body scrolls (the pencil opens it at the top). A graph with none shows nothing there, and its row keeps today's height. Draw 0, 4 and 7 values (7 shows four and "+3 more"). |
| EG-9 | **VoiceOver.** A graph row's values read after its name block, each as "Line, 14". "+n more" reads "3 more details of GPH-7QD2K", one owner-neutral string for both rows (the Artifact row's "3 more copy details of ART-7QK2M" becomes "3 more details of ART-7QK2M"). The board in the form reads as it does in the Artifact sheet. |
| EG-10 | **Opening.** Add evidence graph and Edit each read before the form opens (Add: the type's suggestions; Edit: the graph's values). While a read runs, a second click opens nothing. If the read fails, no form opens and the page's error banner shows the engine's message, as Add artifact does. |
| EG-W1 | **Wide.** The Evidence graphs section stays in the Source page's main column (S15-D1 SD-W1: 1180pt beside the 480pt Metadata side column at a 2296 pane). The values column is 320pt at Regular and 440pt at Wide, the same width as the Artifact row's copy-details column. The form is the same at both widths. |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Source page Evidence graphs section | Graph rows at the main column's width; each row's values in a 320pt column between the name block and the actions | The same rows in the main column beside the Metadata side column (SD-W1); the values column is 440pt | Nothing moves between sections; the values column grows |
| Evidence graph form | Two columns at 880pt over the page (pane 960pt and up); one column at 560pt below that | The same two-column form | Nothing between Regular and Wide: the form's own fallback depends on the pane's 960pt, not on the 1600pt class |

---

## 5. Suggested frames

Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440); the others at Regular.

**Data.** The Source "1880 U.S. census, Ottawa County, Kansas, population schedule", ref `SRC-4KD2P`, type Census, twelve Artifacts "Sheet 14 (image 1)" to "Sheet 25 (image 12)" as on the S15-D14 frames (for the 60-Artifact checklist, continue to "Sheet 73 (image 60)"). Evidence graphs: "Robins household, dwelling 112" (`GPH-3MW8R`) with Item "household of William Robins", Line "14", Dwelling "112", Family "118"; "Hale household, dwelling 113" (`GPH-7QD2K`) with Item "household of Thomas Hale", Line "22", Dwelling "113", Family "119", Folio "236", Schedule "1", Entry "47" (seven values); "Ostrander household, dwelling 114" (`GPH-9HB4T`) with none. Census graph suggestions: Item, Line, Dwelling, Family. Invent every person and record.

| Frame | Requirement | Draw |
| --- | --- | --- |
| 1a / 1b | EG-8, EG-W1 | The Source page scrolled to the Evidence graphs section, the three graphs as rows (four values and "+3 more" on Hale, none on Ostrander), with the Artifacts section below as S15-D14 drew it |
| 2 | EG-1, EG-2, EG-7 | The two-column form in add mode: Name "Ostrander household, dwelling 114", the four suggestions empty, twelve Artifacts checked |
| 3a | EG-1, EG-2 | The form in edit mode for `GPH-3MW8R` before its Family was saved: Item, Line and Dwelling saved, Family suggested, the Line row being edited |
| 3b | EG-2 | The same form with the Add field row open on "Folio" (opening it ends the row edit) |
| 4 | EG-2 | Add mode on a type with no graph suggestions: the board is only its Add field button |
| 5 | EG-3 | The discard confirm after a click outside frame 3b's form (Escape would first close its open Add field row, EG-4) |
| 6 | EG-5 | The form saving; then "This metadata change can't be saved." under the Line row; then the top Callout with "Finish the open field first: save its value or clear it." |
| 7a | EG-6 | Three values and 60 Artifacts, the checklist scrolled to its middle, the body still |
| 7b | EG-6 | Eight values, the Add field row open and three kept-linked Artifacts: the body scrolled between the fixed title and buttons, both columns moving together |
| 7c | EG-1, EG-7 | The one-column fallback at a pane of 900pt: frame 3a's form at 560pt, scrolled |
| 8 | EG-10 | The page's error banner when Add evidence graph cannot read the type's suggestions (no form opens) |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Evidence graph form | Component | Ship | `macos/App/DesignSystem/Components/FormDialog/PVFormDialog.swift` `pvFormDialog`; `macos/App/Features/Sources/SourceGraphFormDialog.swift` | FormDialog with `isDirty`, 880pt (560pt fallback), with the kit's opt-in scrolling body (`scrollsBody: true`), its second caller after the Artifact sheet (EG-6). The two columns are an `HStack` inside this form, a snowflake: no kit layout until a second sheet takes two columns |
| Name, Description | Component | Ship | Field + Input; Field + TextArea | As today |
| Evidence graph metadata board | Snowflake | Ship (second form caller) | `macos/App/Features/Sources/MetadataBoardView.swift` `MetadataBoardView` placement `.form` | The same board as the Artifact sheet's "Artifact metadata", in a Field. Not a second board design |
| Inline Add field row | Snowflake | Ship | `macos/App/Features/Sources/MetadataBoardView.swift` | ComboBox (field) + Input (value) + IconButtons ✓ ✕, as S15-34 drew it |
| Artifacts checklist | Recipe | Ship | `macos/App/DesignSystem/Recipes/ArtifactChecklist/PVArtifactChecklist.swift`, `PVChecklistRows.swift` `PVChecklistFrame` | Already scrolls its rows inside a 264pt cap under a fixed All row (`PVChecklistFrame.maxRowsHeight`, one cap for every checklist); unchanged |
| Kept-linked list | Recipe | Ship | `macos/App/DesignSystem/Recipes/DeleteImpact/PVDeleteImpact.swift` `PVDeleteImpactGroupStack` | As today, capped at 320pt |
| Load and failure lines | Snowflake | Ship | `macos/App/Features/Sources/SourceFormLoadArea.swift` | As today, for the kept-linked read only |
| Errors | Component | Ship | `macos/App/DesignSystem/Components/Callout/`; Field error | EG-5 |
| Discard confirm | Component | Ship | The kit's standard discard confirm in `PVSheet` | As today |
| Graph row | Snowflake | Extend (a values column) | `macos/App/Features/Sources/SourcePageGraphsView.swift` `SourcePageGraphRow` | Card as today; the values column sits between the name block and the actions, sized as the Artifact row's |
| Read-only values | Snowflake | Extend (second caller; S15-11 renames it `MetadataDetailsColumn`, takes the owner and ref, builds its ids from the owner, owns its 320 / 440pt width (today `SourcePageArtifactRow.copyDetailsWidth`), and labels "+n more" with one owner-neutral string) | `macos/App/Features/Sources/ArtifactCopyDetailsView.swift` `ArtifactCopyDetailsView`; `MetadataValueText` in `MetadataBoardView.swift` | One view for the Artifact row and the graph row: field name Text + the metadata value view; "+n more" is a Button `.link`. Not a Table, not the board, not a copy |
| Page error banner | Component | Ship | The Source page's banner (`SourcePageContext.showFailure`), as Add artifact uses it | EG-10, frame 8; the engine's error message, no new copy |

**Non-goals.** No new kit primitive: the board, the inline Add field row and the read-only values are the ones the Artifact sheet and the Artifact row already use. No second metadata board design and no second read-only values view. No checklist cap of its own for this form. No kit two-column form layout yet: a second sheet that takes two columns promotes it. No metadata on the evidence graph canvas.

---

## 7. Handoff

When the board is agreed: record the frames and the board's decisions (the form's widths and columns, the fallback, the values column) on the **Board** line here and in [`README.md`](README.md). S15-11's plan copies EG-1 – EG-10, EG-W1 and the inventory and moves from `Blocked — on board S15-D5` to `Planned`. When S15-11 lands, the brief moves to the spike's design archive.
