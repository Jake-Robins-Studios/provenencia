# S15-D33 — Metadata board row: an inherited value, where it comes from, override and fall back

**Kind:** Claude Design board (**enhancement** of the Source page board's **Artifact sheet** and **Evidence graph form** frames: a board row gains the value its owner inherits from the Source. Extend the existing frames; the sheet's and the form's other parts, the Source's own Metadata section and the Artifacts list are unchanged)
**Spike:** Provenencia Spike 15, slice 11
**View:** the metadata board inside the Artifact sheet (edit and add) and the Evidence graph form (edit and add)
**Implements later as:** PR **S15-64**
**Board:** — (not drawn yet)
**Review:** with the plan, in [`../prs/S15-64-inherited-values.review.md`](../prs/S15-64-inherited-values.review.md)
**Depends on:** S15-63 (landed [#955](https://github.com/Jake-Robins-Studios/provenencia/pull/955)): every board offers the type's one list; S15-34 (landed [#819](https://github.com/Jake-Robins-Studios/provenencia/pull/819)) and S15-11 (landed [#834](https://github.com/Jake-Robins-Studios/provenencia/pull/834)): the Artifact sheet and the graph form with their draft boards ([S15-D14](archive/S15-D14-source-page-artifacts.md), [S15-D5](archive/S15-D5-evidence-graph-form.md))
**Related:** working rules "A board shows what its owner inherits", "A format reads a field from the nearest level that holds it", "One metadata board", "A value can be marked unknown or supplied" in [`../deployment-plan.md`](../deployment-plan.md#working-rules); [`macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide)
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

This brief is an **enhancement**: draw on the Source page board's *Artifact sheet* and *Evidence graph form* frames (S15-D14's rows "Artifact sheet" and "Add an Artifact", S15-D5's row "Evidence graph form"). Change the board rows in place; do not keep a before frame.

---

## 1. Objective

A citation reads each field from the nearest level that holds a value: the Citation, its Evidence graph, its Artifact, then the Source (S15-62). So a value typed once on the Source (Provider "Ancestry") already serves every Artifact and graph of that Source. Today the Artifact sheet and the graph form do not show it: their Provider row sits empty, and a researcher types Ancestry again, or wonders whether the citation will have one.

After this board, a board row shows the value its owner **inherits**: read only, with where it comes from ("From Source"). Typing a value in the row overrides it for this Artifact or graph only. Clearing that value falls back to the inherited one.

**What changes.**

- **An inherited row.** A field with no value of its own here and a value on the Source shows the Source's value, visibly read only and visibly not this owner's, with the level it comes from. Clicking it opens an empty input to type this owner's own value.
- **Override.** Typing in that input and saving it (Save, or Return) makes it this owner's own value, a saved row as today. The citation of this Artifact or graph reads the new value; the Source and its other Artifacts and graphs keep theirs.
- **What an override hides.** A saved row whose field also has an inherited value says what it overrides, so the researcher knows that clearing falls back rather than empties.
- **Fall back.** Clearing the own value (the row's trash) returns the row to the inherited value. In the sheet and the form this changes only the draft, as today: nothing saves until Save, and Cancel restores.

**What stays.** The rows' layout (label column, value, actions), the "Suggested by this type" heading, the saved rows' reorder handle and inline edit, the inline Add field row, dismiss on an empty suggestion, the sheet's and the form's columns, Save, Cancel and their leave confirm. The Source's own Metadata section: nothing is above a Source, so its rows never inherit.

---

## 2. Domain facts

| Fact | What it means on this board |
| --- | --- |
| Levels | A Source holds Artifacts (copies: an image, a PDF) and Evidence graphs. Each of the three holds its own metadata values. An Artifact and a graph each inherit from their Source only; neither inherits from the other |
| Inherited value | The Source's value for the same field. It is not copied: changing the Source's value changes what every Artifact and graph without its own value inherits |
| Own value | A value typed on this Artifact or graph. It overrides the Source's for this owner only. A citation of this Artifact or graph reads it |
| Which rows | Only rows the board already shows: the type's suggested fields, the fields its citation formats read, and this owner's own values. A Source value for a field none of those name adds no row |
| Dismissed | A suggestion dismissed on this owner stays hidden even when the Source holds a value; its citation still reads the Source's value |
| Marks | A value can be marked **unknown** (the record does not give it; no text; prints the field's unknown text, "n.p." for Publisher, or nothing when the field has none) or **supplied** (not on the record; prints in square brackets, "[Calder County]"). An inherited value carries the Source's mark and reads as a citation prints it; the engine gives the printed text |
| Links | A URL value opens in the browser from a saved row today. An inherited URL opens the same way |
| Sizes | A board of up to 30 rows; up to every one of them inheriting. Values up to a long URL (about 200 characters) |
| Where | The Artifact sheet and the graph form are 880pt sheets in two columns (`PVFormColumns`), the board in the left column at about 400pt. There is no one-column form (S15-D5: not built). The sheet is the same at Regular and Wide |

### 2.1 Copy

The board may refine wording; the PR copies what the board shows. *(today)* marks a string that exists and stays. `{level}` is the level's name as the format editor writes it ("Source", "Artifact", "Evidence graph"); on this board it is always "Source".

| Where | Text |
| --- | --- |
| Where an inherited value comes from | "From {level}" ("From Source") |
| Inherited row, spoken (VoiceOver, on the value input) | "Provider. Inherited from Source: Ancestry" |
| Inherited value marked unknown, with no unknown text | "Unknown" |
| Inherited row's input, once opened | "Add a value…" *(today's prompt)* |
| What a saved row overrides, and an opened inherited row | "Overrides {level}: {value}" ("Overrides Source: Ancestry") |
| Inherited row's spoken hint | "Opens a field to type a value that overrides it" |
| Empty suggestion's input, nothing inherited | "Add a value…" *(today)* |
| Suggestion's save | "Save" *(today)* |
| Suggestions heading | "Suggested by this type" *(today)* |

### 2.2 What this board is not

- The citation composer's Citation board, whose rows inherit from the graph, the Artifact or the Source (S15-D29 → S15-56).
- Hiding inherited rows behind a control (a later choice, once the boards are in use).
- Values below an owner (a Source's Artifacts' values on the Source's section).
- The Artifacts list's read-only copy details on the Source page: they show each Artifact's own values only.
- The needed and used flags (S15-D20 → S15-39), the Unknown and Supplied control (S15-D22 → S15-41), the list-below hint (S15-D35 → S15-66).
- A citation preview (refused in this spike).

---

## 3. Implementation gate

| PR | Ships | Not that PR |
| --- | --- | --- |
| **S15-64** | IH-1 – IH-8, IH-W1: the inherited row, override, what an override hides, fall back, marks and links on an inherited value, on the Artifact sheet (edit and add) and the graph form (edit and add) | The composer's board (S15-56); the flags (S15-39); the mark control (S15-41); the list-below hint (S15-66) |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| IH-1 | **The inherited row.** A row with no own value and an inherited value is the dashed suggestion row (label, value column, dismiss) with its value column at rest showing the inherited value on one line, in the saved value's mono caption face but secondary colour, then "From Source" as a caption after it. No input shows at rest. It sits where an empty suggestion sits (under "Suggested by this type"). The board may refine spacing and colour; it keeps this composition: the value drawn as a saved value is drawn, quieter, not inside an input's placeholder (a placeholder cannot hold a link, italics or the whole value on hover). |
| IH-2 | **Override.** Clicking the inherited value (or tabbing to it and pressing Return or Space) opens the row's input, empty, with today's prompt, Save and dismiss, as a saved row opens its inline edit; the inherited value shows as the caption "Overrides Source: Ancestry" under the input while it is open. Save (or Return) moves the row to the saved rows as this owner's value, as an empty suggestion's save does today. Escape, or Save with nothing typed, closes the input and shows the inherited value again. |
| IH-3 | **What an override hides.** A saved row whose field has an inherited value shows, under its value, "Overrides Source: Ancestry" in the caption style. Shown at rest and in edit. A saved row with nothing inherited is unchanged. |
| IH-4 | **Fall back.** The trash on a saved row that overrides an inherited value takes the row back to the inherited row (IH-1) with no confirm, as clearing in a draft is today, when the field is one the board lists without a value (a suggestion, or a field the formats read). A field added through Add field that the board would not otherwise list is removed, as today; the citation then reads the Source's value. A saved row with nothing inherited clears as today. |
| IH-5 | **Marks.** An inherited value reads as its citation prints it: marked unknown, the field's unknown text ("n.p."), else "Unknown", in italics; marked supplied, its text in square brackets ("[Calder County]"). The same in IH-2's and IH-3's caption ("Overrides Source: n.p."). |
| IH-6 | **Links and length.** An inherited URL is a link, as a saved URL is, and opens in the browser; clicking elsewhere in the value column opens the input (IH-2). A long inherited value truncates on one line with the whole value on hover; it never pushes the row's actions out. |
| IH-7 | **Where.** The Artifact sheet in edit and in add, and the Evidence graph form in edit and in add, show IH-1 – IH-6 on the same rows. The Source's own Metadata section shows no inherited row. |
| IH-8 | **VoiceOver.** An inherited row at rest is one element: its field label, then "Inherited from Source: Ancestry", with the hint "Opens a field to type a value that overrides it"; its link (IH-6) is its own element, labelled as a saved URL's is. Once opened, the input reads its field label and the caption is read after it. IH-3's caption is read with the saved value ("FamilySearch. Overrides Source: Ancestry"). |
| IH-W1 | **Wide.** The Artifact sheet and the graph form are 880pt sheets at both widths and nothing in them moves: the sheet centres over the pane at Wide as at Regular. A typed override and the scroll survive a resize across 1600pt. |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Artifact sheet (edit, add) | 880pt sheet, two columns; the board in the left column | The same sheet, centred over the pane | Nothing |
| Evidence graph form (edit, add) | 880pt sheet, two columns; the board in the left column | The same sheet, centred over the pane | Nothing |

---

## 5. Suggested frames

Draw the sheets over the Source page, from the existing Artifact sheet and graph form frames. Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440); the others at Regular.

**Data** (invent every record). Source **1880 census, Calder County** of type **Census**, whose own Metadata holds Creator "Calder County enumerator", Jurisdiction "Calder County", Provider "Ancestry" and URL "https://example.org/calder/1880/census-population-schedules-district-4". Its Artifact **Page 12, image 1** holds its own Line "14" and its own Provider "FamilySearch" only in frames that say so. Its graph **Household of Ada Robins** holds Item "Ada Robins". Census suggests, in this order: Creator, Jurisdiction, Schedule, Enumeration district, Piece, Folio, Schedule number, Dwelling, Family, Line, Item, Format, Provider, URL, Accessed, Citing (16; draw them all, scrolled where the frame needs). For marks, Source **History of Calder County** of type **Book** (suggesting Author, Editor, Compiler, Translator, Edition, Volume, Series, Place of publication, Publisher, Format, Provider, URL, Accessed) with Publisher marked unknown (unknown text "n.p.") and Place of publication "Calder County" marked supplied.

| Frame | Requirement | Draw |
| --- | --- | --- |
| D33-1a / 1b | IH-1, IH-6, IH-W1 | Artifact sheet, edit: Line its own, a saved row; Creator, Jurisdiction, Provider and URL inherited ("From Source"); Schedule and the rest empty with nothing inherited ("Add a value…"). In 1b, the same sheet centred over the Wide pane |
| D33-2 | IH-2 | Provider opened and "FamilySearch" typed: the input, "Overrides Source: Ancestry" under it, Save enabled |
| D33-3 | IH-3 | After Save: Provider "FamilySearch" a saved row with "Overrides Source: Ancestry" under it; in edit as well |
| D33-4 | IH-4 | After the trash on Provider: the row back to "Ancestry", "From Source"; the sheet's Save enabled (the draft changed) |
| D33-5 | IH-5 | An Artifact of the Book Source: Publisher inherited as unknown ("n.p." in italics), Place of publication inherited as supplied ("[Calder County]"); and Publisher overridden ("Overrides Source: n.p.") |
| D33-6 | IH-6 | The Source's long URL inherited, truncated, hover showing it whole, the link opening it |
| D33-7 | IH-7 | Add an Artifact: the draft board with the inherited rows before anything is typed |
| D33-8a / 8b | IH-7, IH-W1 | Evidence graph form, edit: Item its own value, Creator, Jurisdiction, Provider and URL inherited. 8b at Wide |
| D33-9 | IH-7 | The Source page's own Metadata section unchanged (no inherited rows), for comparison only |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Metadata board | Snowflake | Extend | `macos/App/Features/Sources/MetadataBoardView.swift` `MetadataBoardView` | One board on every owner (rule "One metadata board"); this board extends its rows, not a second board |
| Empty / inherited suggestion row | Snowflake | Extend | `MetadataBoardView.swift` `MetadataBoardSuggestionRow` | The inherited row is this row: at rest its value column is the inherited value and its caption; opened, today's input, Save and dismiss. Not a new row type |
| Saved row | Snowflake | Extend | `MetadataBoardView.swift` `MetadataBoardView.savedRow`, `MetadataBoardTextEditor` | Gains IH-3's caption |
| Value text and link | Snowflake | Extend | `MetadataBoardView.swift` `MetadataValueText` | The inherited value and its link draw through it, quieter (secondary colour, italic when unknown); one value view, as S15-35 made it |
| Value input | Component | Ship | `macos/App/DesignSystem/Components/Input/PVInput.swift` `PVInput` | Today's prompt "Add a value…"; shown once the inherited row is opened |
| Caption line ("From Source", "Overrides …") | Snowflake | Extend | `MetadataBoardView.swift` `MetadataBoardAddRowView`'s taken notice, extracted as a file-private caption view; the caption tokens `PVFont.body(size: PVTypeScale.caption)` in `PVColor.textMuted`, as the add row's "taken" notice | One private caption view for the three captions in the file. Text, not a Badge or Chip: it is a sentence, not a status |
| Inline edit | Component | Ship | `macos/App/DesignSystem/Components/InlineEdit/PVInlineEdit.swift` `PVInlineEdit` | Unchanged |
| Save / dismiss / trash | Component | Ship | `PVButton` ghost sm, `PVIconButton` `.dismiss`, `.trash` | Unchanged |
| Dashed row card | Component | Ship | `PVCard(border: .dashed)` | Unchanged |
| Sheet | Component | Ship | `macos/App/DesignSystem/Components/FormDialog/PVFormDialog.swift`, `PVFormColumns`; `macos/App/Features/Sources/ArtifactSheet.swift`, `SourceGraphFormDialog.swift` | Unchanged widths |

**Non-goals.** No new kit primitive. No new row type beside the suggestion and saved rows. No Badge for "inherited". No toggle to show or hide inherited rows. No change to the Source's own Metadata section, the Artifacts list, the graph cards, the Add field row, reorder or the sheets' columns. No preview of the citation.

---

## 7. Handoff

When the board is agreed: record the frames and the board's decisions (the row's composition, any copy change) on the **Board** line here and in [`README.md`](README.md). S15-64's plan copies IH-1 – IH-8, IH-W1, the copy and the inventory, fills D-10 and § 6 macOS and Strings from the board, and moves from `Blocked — on board S15-D33` to `Planned`. When S15-64 lands, this brief moves to the spike's design archive.
