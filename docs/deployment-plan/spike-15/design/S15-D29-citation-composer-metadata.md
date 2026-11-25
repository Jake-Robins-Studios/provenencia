# S15-D29 — Citation composer: the Citation's metadata board in place of Printed page

**Kind:** Claude Design board (**enhancement** of the citation composer frames S15-D8 left: the citation form's **Printed page** field is replaced by the Citation's metadata board, drawn with the board rows S15-D33 drew. Extend the composer frames; the file viewer and its locator strip, the Observations column, the authoring box, the edit dialog and the composer's split are unchanged)
**Spike:** Provenencia Spike 15, slice 11
**View:** the citation composer (`CitationComposerView`): its citation form in both arrangements (Regular, stacked above the viewer; Wide, the 440pt side form), and its Citation menu rows
**Implements later as:** PR **S15-56**
**Board:** — (not drawn yet). Draw on [Claude Design — Citation Composer](https://claude.ai/artifact/3GSFQZjqdQjL8v2rpgMiDc), page *Citation Composer*, in a new section "S15-D29 · The Citation's metadata", from the S15-D8 frames; take the board rows from [Claude Design — Source Detail](https://claude.ai/artifact/443NPNYmGErAmxgV1fBsFK), page *Artifacts*, frames `d33-*` (the inherited row, the override caption, the Add field row)
**Review:** with the plan (Q1, Q3, Q5, Q6: fits; the board's files move, M-4), in [`../prs/S15-56-composer-citation-metadata.review.md`](../prs/S15-56-composer-citation-metadata.review.md)
**Depends on:** S15-55 (landed [#970](https://github.com/Jake-Robins-Studios/provenencia/pull/970)): a new Citation's draft board names its graph and Artifact; S15-64 (landed [#959](https://github.com/Jake-Robins-Studios/provenencia/pull/959)) and [S15-D33](archive/S15-D33-inherited-values.md): the inherited row; S15-60 (landed [#975](https://github.com/Jake-Robins-Studios/provenencia/pull/975)): the seeded field **Page**; [S15-D8](archive/S15-D8-citation-composer-printed-page.md) (S15-13, landed): the composer frames this brief extends
**Related:** working rules "One metadata board", "A board shows what its owner inherits", "The printed page is a metadata field", "A board adds a field in an inline row", "Metadata saves with its owner's write" in [`../deployment-plan.md`](../deployment-plan.md#working-rules); [`macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide)
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

Extend the composer as S15-D8 left it. Replace the **Printed page** field in place: do not keep it beside the new board. Everything else in the composer stays: the file viewer and its locator strip, the Artifact and Citation menus' layout, Label, the transcription with Uncertain, Paste transcription and Auto transcribe, Delete and Save, the Observations column (520pt), the authoring box, and the split (Regular stacks the form above the viewer; Wide puts a 440pt form beside it). The board's rows are the rows the Artifact sheet and the graph form already draw (S15-D33): instance them, do not redraw them.

---

## 1. Objective

A citation names where in the record a fact sits: "p. 14, line 7" of a census enumeration book, "p. 2, col. 4" of a newspaper issue. Since slice 11 a Citation holds metadata of its own, as its Source, its Artifacts and its Evidence graphs do, and a citation reads each field from the nearest level that holds it: the Citation, its Evidence graph, its Artifact, then its Source. The printed page is now one of those fields (**Page**). But the composer, where a researcher makes and edits Citations, has no board: it still offers the old **Printed page** field, which the citation no longer reads.

After this board, the citation form holds the Citation's metadata board, the same board every other owner has: the type's suggested fields, the values the Citation inherits from its graph, Artifact or Source ("From Evidence graph"), its own values, and the inline **Add field** row. The values save with the Citation's **Save**, with Label and the transcription.

**What changes.**

- **The board.** The citation form gains a **Citation metadata** board, with Label and the transcription. A new Citation's board starts from the type's suggestions and what it would inherit; an existing Citation's board shows its own values first, as every board does.
- **Printed page goes.** The page is the board's **Page** row: typed there, inherited there ("p. 2" from the clipping's Evidence graph), and marked there by later PRs. There is no separate Printed page field.
- **One Save.** The citation form's Save stores Label, the transcription and the board together; a board change makes the form unsaved, as a Label change does; leaving or switching Citation with unsaved board changes asks, as today.
- **The Citation menu rows.** A row's "p. 14" now comes from the Citation's own **Page** value, never an inherited one ("p. 14 · image 37 · region"; "image 40" when the Citation has no Page of its own).

**What stays.** Label keeps its name and place. The locator strip shows the page **in the file** ("Page 37"), never the printed page. The board's rows, captions, Add field row, dismiss and reorder are the shared board's, unchanged. Nothing is saved per keystroke.

---

## 2. Domain facts

| Fact | What it means on this board |
| --- | --- |
| Levels | A Source holds Artifacts (an image, a PDF) and Evidence graphs. A Citation sits on one Artifact and in one graph. Each of the four holds its own metadata values. A Citation inherits from its graph, else its Artifact, else its Source |
| Board | One owner's metadata: its own values (reorderable rows), then the type's suggested fields and the fields its citation formats read ("Suggested by this type"), then **Add field**. The same board on the Source page, the Artifact sheet and the graph form |
| Inherited row | A row with no value of its own and a value above: the value read only, "From Evidence graph" (or Artifact, or Source) under it, a pencil that opens an empty input to override it (S15-D33). Clearing an override falls back |
| Page | The seeded field "Page" (unknown text "unpaginated"). A citation prints it "p. 14". A whole-issue newspaper PDF's Citations each carry their own page; a clipping's five Citations take theirs from their graph |
| New Citation | Has no id until its first Save (or its first Observation, which saves it). Its board is read from its graph and Artifact when the composer opens it, and its values save in that first write |
| Sizes | A board of up to 30 rows (the type's suggestions, 16 for a census); typically 3 to 8 hold a value. An Artifact of up to 60 Citations |
| Kinds | The board is offered on every Artifact kind: image, PDF, audio, video and a file the app cannot show. Metadata is about the record, not the file |
| Widths | Regular: 1102pt by default, up to 1599pt; the form stacked above the viewer takes up to 55% of the height and scrolls. Wide: the form is a 440pt column that scrolls |

### 2.1 Copy

The board may refine wording; the PR copies what the board shows. *(today)* marks a string that exists and stays.

| Where | Text |
| --- | --- |
| Board label | "Citation metadata" |
| Inherited caption | "From Evidence graph", "From Artifact", "From Source" *(today, "From {level}")* |
| Override caption | "Overrides Evidence graph: 2" *(today, "Overrides {level}: {value}")* |
| Empty suggestion's input | "Add a value…" *(today)* |
| Add field | "Add field" *(today)* |
| The Citation's board could not be read (its graph or Artifact was deleted meanwhile) | "The Citation's metadata can't be shown. Close the composer and open it again from the Source." |
| Citation menu row, own Page | "p. 14" *(today)*, joined "p. 14 · image 37 · region" *(today)* |
| Label field | "Label", "A short name, e.g. Schedule 18 · Alderwick household" *(today)* |

### 2.2 What this board is not

- The needed and used flags on the board's rows (S15-D20 → S15-39); the Unknown and Supplied control (S15-D22 → S15-41). This board draws no flag and no mark control, also not on Page.
- A citation preview in the composer (refused in this spike).
- Values below an owner; hiding inherited rows behind a control.
- Any change to the locator strip, the file viewer, the Observations column, the authoring box or the edit dialog.
- The Conclusion detail's citation line: it already prints "p. 2"; after this PR it reads the Citation's Page value, with no chrome change.

---

## 3. Implementation gate

| PR | Ships | Not that PR |
| --- | --- | --- |
| **S15-56** | CB-1 – CB-8, CB-W1, CB-W2: the board in both form arrangements, a new Citation's and a saved Citation's board, inherited rows, one Save, the leave confirm, the read failure, the Citation menu row, Tab order and VoiceOver; Printed page removed | Flags (S15-39); the mark control (S15-41); `{citation.page}` (S15-58) |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| CB-1 | **The board.** The citation form holds a **Citation metadata** Field whose content is the shared metadata board in its form placement (its own ghost **Add field** at the foot), as in the Artifact sheet. It sits under Label in both arrangements (CB-W1). The Printed page field is gone, with no gap where it stood. |
| CB-2 | **A new Citation.** **New citation**, opening the composer on an Artifact with no Citation, and switching Artifact show the board of a Citation not yet saved: the type's suggestions, each empty or inherited from the graph, Artifact or Source. Typing a value there and pressing Save stores the Citation with its values. |
| CB-3 | **A saved Citation.** Picking a Citation in the Citation menu shows its board: its own values as saved rows, then its suggestions, inherited or empty. Overriding an inherited value and pressing Save stores the Citation's own; clearing an override falls back to the inherited value (S15-D33's rows). |
| CB-4 | **One Save.** A board change (a value typed and confirmed, cleared, a suggestion dismissed, a field added, rows reordered) makes the form unsaved: the citation form's Save is enabled. Save stores Label, the transcription and the board in one write. Leaving the composer, switching Citation or Artifact with unsaved board changes asks, as it asks for an unsaved Label today. No Save of its own on the board. |
| CB-5 | **The read failure.** When a new Citation's board cannot be read because its graph or its Artifact was deleted meanwhile, the board's place shows one error line (§ 2.1), and Save stays as it is for Label and the transcription. |
| CB-6 | **The Citation menu row.** A row's printed page is the Citation's own **Page** value ("p. 14"), shown as today's row shows it; a Citation whose Page is inherited or empty shows no printed page in its row ("image 40"). Row layout unchanged, in both menus. |
| CB-7 | **Tab order.** The form's Tab list is Label and the transcription, in today's order for each arrangement; the Printed page stop is gone. The board's own controls take the focus as they do on the Artifact sheet, whose Tab list also names only its text fields. |
| CB-8 | **VoiceOver.** The board is announced by its label, "Citation metadata", and each row reads as on the Artifact sheet (S15-D33: "Page. Inherited from Evidence graph: 2"). |
| CB-W1 | **Regular and Wide.** **Regular** (1102pt): the stacked form's two inner columns as today (the transcription at 1.5, the right column at 1); the right column holds Label, then the board under it, and scrolls with the form. **Wide** (2296pt): the 440pt side form holds the menus, Label, the board, then the transcription and the footer; the board decides whether the board sits before or after the transcription, and keeps the transcription and Save reachable by scrolling the one form. Neither column widens. |
| CB-W2 | **Crossing 1600pt keeps state.** A resize across 1600pt keeps the open Citation, an unsaved board (a typed override, a dismissed suggestion), an open row editor's text and the keyboard focus. |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Citation composer | Form stacked above the viewer (up to 55% of the height, scrolling), Observations (520pt) at the right; the form's right inner column holds Label and the board | Viewer, the 440pt form, Observations (520pt) side by side; the form holds Label, the board and the transcription in one scrolling column | The board moves with Label from the stacked form's right column into the side form; its rows are the same |

---

## 5. Suggested frames

Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440); the others at Regular. Draw them from the S15-D8 frames, with the toolbar above (breadcrumb "Calder Gazette, 14 March 1891 › Front-page notices › Citation").

**Data.** Invent every record. Source **Calder Gazette, 14 March 1891** (type Newspaper item), its own Published in "Calder Gazette" and Provider "Chronicling America". Artifacts: **Whole issue** (a PDF of 8 pages) and **Clipping, Rudd marriage** (an image). Graph **Front-page notices** holds its own Page "2" and Column "4". Newspaper item suggests Published in, Place of publication, Page, Column, Format, Provider, URL, Accessed. Citations on Whole issue: CIT-4QJ7R "Alderwick death notice", its own Page "2" and Column "4", file page 2; CIT-8HN2W "Pell auction", its own Page "7" and Column "1", file page 7. On Clipping: CIT-2DM5K "Rudd marriage", no own values (Page "2" and Column "4" inherited from the graph). For the read failure, a new Citation on **Clipping** after the graph was deleted.

| Frame | Requirement | Draw |
| --- | --- | --- |
| D29-1a / 1b | CB-1, CB-3, CB-W1 | CIT-4QJ7R open on Whole issue: Page "2" and Column "4" saved rows; Published in and Provider inherited "From Source"; Place of publication, Format, URL and Accessed empty; the form saved. 1a stacked, 1b side form |
| D29-2 | CB-3 | CIT-2DM5K on Clipping: Page "2" and Column "4" inherited "From Evidence graph", Published in and Provider "From Source" |
| D29-3 | CB-3, CB-4 | CIT-2DM5K after overriding Page with "3": a saved row with "Overrides Evidence graph: 2" under it, the form's Save enabled |
| D29-4a / 4b | CB-2, CB-W1 | **New citation** on Whole issue: the board before anything is typed (Page and Column inherited from the graph, Published in and Provider from the Source), Label empty, Save enabled as today for a new Citation |
| D29-5 | CB-4 | CIT-8HN2W with Column changed to "2", then the Citation menu's pick of CIT-4QJ7R: the kit's leave confirm, as it shows for an unsaved Label |
| D29-6 | CB-5 | A new Citation on Clipping after its graph was deleted: the error line in the board's place, Label and the transcription as usual |
| D29-7a | CB-6 | On Whole issue, the Citation menu open: "p. 2 · image 2" (CIT-4QJ7R), "p. 7 · image 7" (CIT-8HN2W) |
| D29-7b | CB-6 | On Clipping, the Citation menu open: CIT-2DM5K with no printed page in its row (its Page is inherited) |
| D29-8 | CB-1 | A Citation on an audio Artifact: the board shown as on any other Artifact |
| D29-9 | CB-W2 | The same unsaved Citation (an override "3" typed, the row editor open) at 1599pt and 1600pt: the text, the open editor and the focus unchanged |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Citation form | Snowflake | Extend | `macos/App/Features/CitationComposer/CitationComposerEvidenceColumn.swift` (`sideForm`, `panelForm`) | Label, then the board, in place of `labelAndPrintedPage`; the transcription and footer as today |
| Metadata board in a form | Snowflake | Ship (moved) | `macos/App/Features/MetadataBoard/` `DraftMetadataBoardField` → `MetadataBoardView` (`placement: .form`); moved from `Features/Sources` now that two features use it (user, 2026-11-25) | The Artifact sheet's and the graph form's board, as is: one board on every owner (rule "One metadata board"). Not a composer copy |
| Inherited row, override caption | Snowflake | Ship | `macos/App/Features/MetadataBoard/MetadataBoardView.swift` `MetadataBoardSuggestionRow`, `savedRow` | S15-D33's rows; "From Evidence graph" and "From Artifact" are the same caption with another level |
| Row editor, Add field | Component / snowflake | Ship | `PVInlineEdit`, `MetadataBoardView`'s Add field row | Unchanged |
| Read failure line | Component | Ship | `PVErrorText` (as `citationLoadErrorLine` uses it) | One line in the board's place; not a Callout, not an EmptyState |
| Leave confirm | Component | Ship | The composer's existing discard confirm | Board changes count as unsaved citation fields |
| Citation menu row | Snowflake | Extend | `CitationStepMenuRow` (`CitationComposerEvidenceColumn.swift`) | Its printed page comes from the Citation's own Page value; layout unchanged |
| Printed page field | Snowflake | Remove | `CitationComposerEvidenceColumn.printedPageField`, `labelAndPrintedPage` | Gone; Label stands alone above the board |
| Locator strip | Snowflake | Ship (unchanged) | `CitationComposerViewerPane.locatorStrip` | Keeps "Page 37" |

**Non-goals.** No new kit primitive. No composer-only board, row or caption. No Save button on the board. No flag or mark control (later PRs). No citation preview. No change to the split's columns, the viewer, the Observations column or the authoring box.

---

## 7. Handoff

When the board is agreed: record the board's link, its frames and its decisions (where the board sits against the transcription in the side form, any copy change) on the **Board** line here and in [`README.md`](README.md). S15-56's plan copies CB-1 – CB-8, CB-W1, CB-W2 and the inventory, fills D-12 and § 6 macOS from the board, and moves from `Blocked — on board S15-D29` to `Planned`. When S15-56 lands, this brief moves to the spike's design archive.
