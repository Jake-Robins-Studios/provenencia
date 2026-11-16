# S15-D8 — Citation composer: the printed page, on the app's width classes

**Kind:** Claude Design board (**enhancement** of the citation composer: one field added to the citation form, and the composer's split moves onto the app's Regular and Wide classes. Extend the composer frames; the file viewer, the locator strip, the Observations column, the authoring box and the edit dialog are unchanged)
**Spike:** Provenencia Spike 15, slice 3
**View:** the citation composer (`CitationComposerView`): its citation form in both arrangements, its Citation menu rows, and its split at Regular and Wide
**Implements later as:** PR **S15-13**
**Board:** — (not drawn yet). When agreed: the Claude Design link and frame names go here (user, 2026-11-16: the board reaches the implementer as a Claude Design link)
**Review:** with the plan, in [`../prs/S15-13-composer-printed-page.review.md`](../prs/S15-13-composer-printed-page.review.md)
**Depends on:** S15-50 (a form lists its fields' Tab order on the kit's focus handle, `PVFieldFocus(_:equals:in:)`). The locator already has `page_label` on its `page` selector ([`interpretation-layer-data-model.md`](../../../interpretation-layer-data-model.md) § 3.2); today's citation line already prints it as "p. 23" (`CitationLineDisplay`); S14-24 (landed) gave every view a Regular and Wide class
**Related:** working rule "Citations carry no metadata" in [`../deployment-plan.md`](../deployment-plan.md#working-rules); [`../evidence-explained-citation-map.md`](../evidence-explained-citation-map.md) § 1 (the two kinds of page) and § 6.9 (the printed page stays on the Citation); [`macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide); [`docs/ideas/wide-layout.md`](../../../ideas/wide-layout.md) (the Citation composer row); S15-D24 (later: Unknown, Supplied and the needed flag on this field)
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

Extend the citation composer as it is today. The file viewer and its locator strip (Entire artifact › Page 37 › Rectangle, the Clear menu, the draw hint), the Observations column (520pt), the authoring box, the Artifact and Citation menus' layout, the transcription, its Uncertain box, Paste transcription and Auto transcribe, Delete and Save all stay. Two things change: the citation form gains a **Printed page** field next to **Label**, and the composer chooses its arrangement by the app's width class instead of its own 1400pt rule.

---

## 1. Objective

A citation names the page of the original record: "p. 14" of a census enumeration book, "fol. 17r" of a register, "iv" of a preface. The composer records only where the Citation sits **in the file** (page 37 of a PDF, a region of an image), which means nothing to a reader holding the book or the film. The locator has always had room for the printed page (`page_label`), but nothing writes it, so every citation line reads "image 37".

**What changes.**

- **Printed page.** The citation form has a one-line **Printed page** field beside **Label**. The researcher types the page as printed ("14", "iv", "23a", "folio 17r"). It saves with the Citation's Save, as Label and the transcription do, and the citation line on the Person, Event and Place pages then reads "p. 14".
- **Images too.** It is offered on image Artifacts (a census page saved as a JPEG, the commonest case) and on PDFs, whatever the locator is: the entire file, a page, a region. It is not tied to the file page: a PDF's page 37 can be printed page 23, and an image has no file page at all (user, 2026-11-16).
- **The Citation menu reads like the citation line.** A Citation's row in the Citation menu shows "p. 14" for a printed page and "image 37" for the page in the file, the words today's citation line already uses, so "p." always means the printed page. Today that row says "p. 37" for the file page.
- **Width classes.** Today the composer switches on its own rule: from a 1400pt pane it shows three columns (the file viewer, a 440pt citation form, the 520pt Observations column); below that, two (the citation form stacked above the viewer, then Observations). After this board it follows the app's classes: **Regular** (pane below 1600pt) and **Wide** (1600pt and up), so a 1464pt pane (a 16" MacBook Pro full screen) is Regular like every other view (user, 2026-11-16).

**What stays.** Label keeps its name and prompt. The printed page is never computed or checked: no number parsing, no "p." typed for the researcher, no page map. The locator strip still shows the file page as "Page 37" (it shows where the Citation is drawn on the file, not the printed page). Leaving the composer with unsaved citation fields asks, as today; the printed page is one of those fields.

---

## 2. Domain facts

| Fact | What it means on this board |
| --- | --- |
| Citation | One reading of one spot in one Artifact: its locator (where), its transcription (what it says), a short Label ("Schedule 18 · Alderwick household"), and the Observations drawn from it. |
| Artifact kinds | **Image** (a JPEG or PNG of a page; no file pages), **PDF** (pages), **audio** and **video** (no pages; not yet viewable), and files the app cannot show. |
| Page in the file | The locator's page selector (`artifact_page`): which PDF page the Citation is on. Set by drawing on a page or picking one; shown in the locator strip as "Page 37". Images have none. |
| Printed page | `page_label` on the same selector: the number the original prints on that page. Text, never a number: "iv", "23a", "A-3", "folio 17r". Empty means the researcher has not given one (a later PR, S15-45, lets them say "the page is unnumbered"). |
| Citation line | How a record names its Citation on the Person, Event and Place pages: "1881 census, Thornham, Schedule 18 · Alderwick household, p. 14". It prints the printed page as "p. 14", else the file page as "image 37". Already built; this board does not draw it. |
| Saving | The citation form (Label, Printed page, transcription, Uncertain) saves on its Save button; nothing saves per keystroke. Save is enabled while the form differs from what is stored. |
| Widths | The composer fills the whole pane. Regular: 1102pt by default, up to 1599pt. Wide: 1600pt and up, typically 2296pt. |

### 2.1 Copy

The board may refine wording; the PR copies what the board shows. Strings marked *(today)* exist and stay.

| Where | Text |
| --- | --- |
| Field label | "Printed page" |
| Field prompt | "As printed, such as 14 or iv" |
| Field hint, or the field's tooltip (the board decides which, or neither) | "The page number the original prints. It goes in the citation; the page in the file does not." |
| Label field | "Label", "A short name, e.g. Schedule 18 · Alderwick household" *(today)* |
| Citation menu row, printed page | "p. 14" (the citation line's own words, the same string) |
| Citation menu row, page in the file | "image 37" (the citation line's own words, the same string; today the menu says "p. 37") |
| Citation menu row, region | "region" *(today)* |
| Citation menu row, joined | "p. 14 · image 37 · region"; each part only when present |
| VoiceOver, the field | "Printed page", its value, and the hint above as its help |

### 2.2 What this board is not

- Unknown, Supplied and the needed flag on the printed page (S15-D24 → S15-45).
- A per-Artifact page map ("image 37 is page 23"), entered once (not planned this spike: map § 7).
- Citation formats and rendered citations (S15-16, S15-21).
- Any change to the locator strip, the file viewer, the Observations column, the authoring box, the edit dialog or the menus' layout.
- Any change to the citation line on the Person, Event and Place pages: it already prints "p. 14".

---

## 3. Implementation gate

| PR | Ships | Not that PR |
| --- | --- | --- |
| **S15-13** | CP-1 – CP-7, CP-W1, CP-W2: the Printed page field in both form arrangements, when it is offered, saving, the Citation menu rows, VoiceOver and Tab order, the composer on Regular and Wide | Unknown, Supplied, the needed flag (S15-45); a page map (not planned) |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| CP-1 | **The field.** The citation form has a **Printed page** Field with a one-line Input, next to **Label**: in the same row as Label where the form is wide enough (Label takes the width, Printed page about 140pt), else directly under Label. Never separated from Label by the transcription. Draw it in both form arrangements (CP-W1). |
| CP-2 | **When it is offered.** On an image or a PDF Artifact, always, whatever the locator holds: Entire artifact, a page, a page and a region, a region on an image. Not on an audio or video Artifact or a file the app cannot show: no field and no gap where it would be. |
| CP-3 | **It is not part of the locator strip.** Picking another file page, drawing or clearing a region, removing the page and **Reset to entire artifact** leave the printed page as typed. The strip's chips do not show it. |
| CP-4 | **Saving.** Typing in Printed page makes the form unsaved (Save enabled), as typing in Label does; Save stores it with the rest; leaving with it unsaved asks, as today. Opening another Citation from the Citation menu shows that Citation's printed page; **New citation** starts with it empty. Leading and trailing spaces are dropped; a field of only spaces is empty. |
| CP-5 | **The Citation menu rows.** The composer's Citation menu and the Observation dialog's Citation menu share one row. Each row's locator text shows the printed page as "p. 14", the page in the file as "image 37", and "region", joined by " · ", each only when present (§ 2.1). Draw the open menu on each Artifact of the data (frames 4a, 4b). |
| CP-6 | **VoiceOver.** The field reads "Printed page" with its value and its help (§ 2.1). The menu row reads its parts as shown. |
| CP-7 | **Tab order.** Tab moves through the form's fields in the order they are drawn (Label, Printed page, transcription in the side form; the board's order in the stacked form), and Shift-Tab back. |
| CP-W1 | **Regular and Wide.** The composer chooses its arrangement by the width class, not by 1400pt. **Regular** (1102pt, up to 1599pt): today's two-column arrangement, the citation form stacked above the file viewer, the Observations column (520pt) beside them; the form keeps today's two inner columns (the transcription at 1.5, Label at 1) with Printed page beside or under Label. **Wide** (2296pt; from 1600pt): today's three-column arrangement, the file viewer taking the extra width (it is the canvas), the citation form a 440pt column beside it, the Observations column (520pt) at the right; Label and Printed page in one row above the transcription. The board decides whether either column is wider at Wide; the viewer always takes what is left. |
| CP-W2 | **Crossing 1600pt keeps state.** Resizing across 1600pt keeps the open Citation, unsaved citation fields (the printed page included), the file viewer's page and zoom, a region being drawn, and the keyboard focus on the same field. |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Citation composer | The citation form stacked above the file viewer (the form takes up to 55% of the height), the Observations column (520pt) at the right; Printed page beside or under Label in the form's right inner column | The file viewer, the citation form (440pt), the Observations column (520pt), side by side; Label and Printed page in one row | The citation form moves from above the viewer to a column beside it; the field order is unchanged |

---

## 5. Suggested frames

Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440); the others at Regular, because their content does not change with width (frame 1b shows the 440pt form at Wide). A menu lists only the open Artifact's Citations, so frame 4 has one frame per Artifact. Draw them from the composer as it is, with the toolbar above (its breadcrumb "Thornham 1881 › Alderwick household › Citation").

**Data.** Invent every record. Source **Thornham 1881 census** (type Census). Artifacts: **Folio 23** (an image, a JPEG of one enumeration page, 2400 × 3400 pixels); **Enumeration book 4** (a PDF of 62 pages); **Interview with M. Alderwick** (audio). Citations on Folio 23: CIT-7KQ2M "Schedule 18 · Alderwick household", printed page "14", a rectangle on the page; CIT-5MV2N "Schedule 20 · Rudd household", printed page "15", no region; CIT-9RX4T "Schedule 19 · Pell household", no printed page, no region. On Enumeration book 4: CIT-3HW8D "Ellen Alderwick, baptism", page 37 in the file, printed page "23", a rectangle; CIT-6TN1B "Banns, Alderwick and Rudd", page 40, no printed page; CIT-8PL3C "Book 4, the whole register", Entire artifact, no printed page.

| Frame | Requirement | Draw |
| --- | --- | --- |
| 1a / 1b | CP-1, CP-2, CP-W1 | CIT-7KQ2M open on Folio 23 (an image), Printed page "14", the form saved. 1a two columns, the form stacked above the viewer; 1b three columns |
| 2a / 2b | CP-1, CP-3 | CIT-3HW8D on Enumeration book 4: the strip "Entire artifact › Page 37 › Rectangle", Printed page "23" |
| 3 | CP-4 | CIT-9RX4T: Printed page empty with its prompt, the cursor in it; then "iv" typed and Save enabled |
| 4a | CP-5 | On Enumeration book 4, the Citation menu open: rows "p. 23 · image 37 · region" (CIT-3HW8D), "image 40" (CIT-6TN1B), and CIT-8PL3C with no locator text |
| 4b | CP-5 | On Folio 23, the Citation menu open: rows "p. 14 · region" (CIT-7KQ2M), "p. 15" (CIT-5MV2N), and CIT-9RX4T with no locator text |
| 5 | CP-2 | **New citation** on Interview with M. Alderwick (audio): no Printed page field and no gap |
| 6 | CP-3 | CIT-3HW8D after **Reset to entire artifact**: the strip back to "Entire artifact", Printed page still "23", Save enabled |
| 7 | CP-W1 | A 1464pt pane (Regular): two columns, the form stacked above the viewer (today this width shows three) |
| 8 | CP-W2 | The same unsaved Citation (Printed page "23a", the cursor in it) in 8a at 1599pt and 8b at 1600pt: the field, its text and the cursor unchanged |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Composer split | Snowflake | Extend | `macos/App/Features/CitationComposer/CitationComposerView.swift` (`composeSplit`, `evidence(threeUp:height:)`) | Reads `@Environment(\.pvWidthClass)` instead of measuring 1400pt; the two arrangements are today's |
| Width class | Component | Ship | `macos/App/DesignSystem/Components/WidthClass/PVWidthClass.swift` | Measured once by `WorkspaceDestinationHost`; the composer never measures |
| Citation form | Snowflake | Extend | `macos/App/Features/CitationComposer/CitationComposerEvidenceColumn.swift` (`sideForm`, `panelForm`, `labelField`) | Gains the Printed page field next to Label in both arrangements |
| Printed page field | Component | Ship | `PVField` (`DesignSystem/Components/Field/PVField.swift`) + `PVInput` (`DesignSystem/Components/Input/PVInput.swift`) | The same Field and Input as Label, size `.sm`; its help as the Field's hint or the Input's tooltip (the board's call); no new control |
| Tab order | Component | Ship (from S15-50) | `PVFieldFocus(_:equals:in:)` (`DesignSystem/Components/Input/PVFieldFocus.swift`; S15-50 replaces `PVTabPair` with it) | The form lists its fields in order; Tab and Shift-Tab follow the list; the composer holds the focus state so it survives the layout switch |
| Citation menu row | Snowflake | Extend | `CitationStepMenuRow` (`CitationComposerEvidenceColumn.swift`), in the `PVSelect` of `CitationComposerEvidenceColumn.citationSelect` and of `CitationComposerAuthoringBox` | Row layout unchanged; only its locator text changes, in both menus |
| Locator strip | Snowflake | Ship (unchanged) | `CitationComposerViewerPane.locatorStrip` | Keeps "Page 37"; does not show the printed page |
| Citation line | Snowflake | Ship (unchanged) | `macos/App/Platform/CitationLineDisplay.swift` | Already prints "p. 14"; not drawn |

**Non-goals.** No new kit primitive. No page picker, stepper or number field: the printed page is text. No printed page in the locator strip. No "p." typed into the value. No change to the Observations column's width, the authoring box (beyond its Citation menu's row text) or the edit dialog. No third arrangement of the composer.

---

## 7. Handoff

When the board is agreed: record the board's link, its frames and its decisions (where Printed page sits in the stacked form; hint, tooltip or neither; whether a column widens at Wide; any copy change) on the **Board** line here and in [`README.md`](README.md). S15-13's plan copies CP-1 – CP-7, CP-W1, CP-W2, the copy and the inventory, fills its board-dependent Decisions and Strings, and moves from `Blocked — on board S15-D8` to `Planned`. When S15-13 lands, this brief moves to the spike's design archive and the composer's row in `docs/ideas/wide-layout.md` is marked landed.
