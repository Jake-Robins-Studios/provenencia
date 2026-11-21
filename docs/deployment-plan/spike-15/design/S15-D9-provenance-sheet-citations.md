# S15-D9 — Provenance sheet: formatted citations

**Kind:** Claude Design board (**enhancement** of the provenance sheet as shipped: S13-36's recipe, the value header, the record table with its owner lines and value headings. Draw on the [Person page board](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ); when the board has no provenance sheet frames, add a page *Provenance sheet* to it, built from the shipped sheet described in § 2)
**Spike:** Provenencia Spike 15, slice 6
**View:** the provenance sheet (a sheet over the Person page; the same sheet opens from Event and Place rows after S15-31)
**Implements later as:** PR **S15-21** (PC-1 – PC-9, PC-W1)
**Board:** — (not drawn yet)
**Depends on:** S15-16 (landed [#914](https://github.com/Jake-Robins-Studios/provenencia/pull/914)): the engine renders each Citation's full and short citation, as styled runs, with a group key; S16-30 (landed [#812](https://github.com/Jake-Robins-Studios/provenencia/pull/812)): the sheet's records
**Related:** [`../provenance-loading.md`](../provenance-loading.md); working rules "Grouping is by the rendered full citation, computed when read", "Citations render on demand, from SQL", "Today's line stays the fallback, in Swift", "Follow the *Evidence Explained* style; never copy the book" in [`../deployment-plan.md`](../deployment-plan.md#working-rules); plan [`../prs/S15-21-provenance-sheet-citations.md`](../prs/S15-21-provenance-sheet-citations.md). Later briefs on this sheet: S15-D17 (the fold), S15-D18 (records loading on open)
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

Keep the sheet as shipped: its title, the value header (the shown value, its state badge, the summary line), the column headings (Read as · Citation · Outcome · Record · a reserved column), owner group lines, value headings, the Source and Observation links under each citation, the Record cell's two refs, and Done. Change only the Citation cell, the copy buttons beside it, the rules between rows that share a citation, and the record area's loading and failed states.

## 1. Objective

A record's citation on the provenance sheet reads like a citation. Where a Source's type has a full citation format, the Citation cell shows the citation the engine renders from the Source, its Artifact and the Evidence graph, with its italics ("1880 U.S. census, Ottawa County, Kansas, population schedule, ED 236, p. 14, dwelling 112, family 118, Ada Robins; digital image, *Ancestry* (… : accessed 12 March 2025)"). Two copy buttons copy the full and the short form, as rich text (italics kept) and plain text. Records whose full citations read the same (the pieces of one household row) sit together, with no rule between them, so the eye reads them as one citation. The citations are fetched when the sheet opens: until they arrive the record area shows the kit's load area, and if they cannot be read it shows that area's notice with Read again.

**What stays.** Where a Source's type has no full format, the cell shows today's line ("Census of Canada West, 1851, Vol. 3, p. 23") with one copy button, as today. The header, the links, the Outcome and Record cells, and the sheet's widths do not change.

## 2. Domain facts

| Fact | Meaning for the board |
| --- | --- |
| **The sheet today** | A panel 880pt wide at Regular and 1280pt at Wide, titled with the value's label ("Birth date"). A header line: the shown value, a state badge (merged, mixed, concluded), a summary ("merged from 2 Sources · 2 records"). Then column headings and a scrolling record table, at most 560pt tall; Done at the foot. |
| **A record row** | Read as (140pt; 220pt at Wide) · Citation (takes the rest) · Outcome (190pt; 280pt at Wide: a mark and a phrase, "Kept", "Outvoted by 2 Sources") · Record (112pt: the Observation ref over the Subject ref, mono) · a reserved 88pt column. The Citation cell: the citation line as an ink link (opens the Citation), a copy icon button level with its first line, and under it the links **Source** and **Observation OBS-…**. A record that went into the shown value is primary ink; the rest secondary. |
| **Groups in the table** | Owner lines (a derived row's Event or Place) and value headings (a run of records under one displayed value) already split the table; a rule separates rows. |
| **Full and short citation** | Each Citation has a full citation (the first footnote) and a short one (later notes), each rendered by the engine as runs of plain and italic text. A type may have a full format and no short one. |
| **Same citation** | Records whose full citations render the same (Citations drawn on one household row of a census page) belong together: the engine gives them the same group key. Records of different Citations with no full citation never group; two records of one such Citation do. |
| **Today's line** | "Source title, Artifact label, Citation label, p. 23" (else "image 37"): the app's own line, used where the type has no full format. |
| **On-open read** | The citations come from one call the sheet makes when it opens; the records themselves are already on the page. At Scale a sheet shows up to 300 citations; the call is fast but not instant. |
| **Copy** | Rich text keeps the italics when pasted into a word processor; plain text is written alongside for plain fields. |
| **Example data** | Invented people, places and records only: "Ada Robins", "Ottawa County, Kansas", "Census of Canada West, 1851". Never a real person or a real published citation example. |

### 2.1 What this board is not

- The fold of a long table with Show more (S15-D17, S15-27).
- Records loading on open and their own failure (S15-D18, S15-29): the records still arrive with the page.
- The Person page's Sources section and its grouping (S15-D15, S15-22).
- Copy source-list entry on the Source page (S15-D19, S15-23).
- The Event and Place pages (S15-D11, S15-D12).
- A heading line over a group, a disclosure per group, or a count of a group's Citations.
- Editing a format, or flagging missing fields (the format editor and the boards do that).

## 3. Implementation gate

| PR | Ships | Not in this PR |
| --- | --- | --- |
| **S15-21** | PC-1 – PC-9, PC-W1: the formatted citation in the Citation cell with its italics, today's line as the fallback, Copy full and Copy short (rich and plain), the same-citation run with no rule inside it, the load area while loading and its failed notice with Read again | The fold, records on open, every other view |

## 4. Requirements

| ID | Requirement |
| --- | --- |
| PC-1 | **Formatted citation.** The Citation cell's link shows the record's full citation as rendered, with its italic runs in italic, in the cell's current type (body small) and ink (primary when the record counted, secondary otherwise). It wraps in the Citation column; it never truncates. Clicking it opens the Citation, as today. |
| PC-2 | **Fallback.** A record whose Source type has no full format shows today's line, as today. A sheet can mix both kinds of row. |
| PC-3 | **Two copy buttons.** Beside the first line of a formatted citation sit two icon buttons: **Copy full citation** and **Copy short citation**, in that order, each with its tooltip and spoken label. Each turns to a check for 1.6 seconds after a click (the kit's ClipboardButton). When the type has no short format, only Copy full citation shows, in the first slot. A fallback row shows one button, **Copy citation**, in the first slot. The copy track keeps the width of two buttons on every row, so the Citation column's text edge lines up down the table. |
| PC-4 | **Rich and plain.** A copy writes the citation as rich text with its italics and as plain text. The board notes it; there is nothing to draw. |
| PC-5 | **Same citation, no rule.** Within a value run (and within an owner group), records with the same full citation sit next to each other, in the order the first of them appeared, and no rule is drawn between them. Each row still shows its own full citation, copy buttons and links. A run of one is an ordinary row. Draw the rule a normal row boundary keeps against the hairline a same-citation pair drops, so the difference is visible at 100%. No background, heading or count marks a run. |
| PC-6 | **Loading.** When the sheet opens and the citations are not yet read, the header and column headings draw at once; the record area under the headings shows the kit's FormLoadArea in its loading state (three skeleton bars and the caption "Loading citations", spoken the same). No record row draws until the citations arrive; then the table draws once. |
| PC-7 | **Failed.** If the citations cannot be read, the record area shows only the FormLoadArea's failed state (its compact danger Callout): title "Citations could not be read", the error's message, and **Read again**; while the read runs again the area shows its loading state. No record row draws. The notice is announced. |
| PC-8 | **Spoken.** A row's spoken line reads the plain text of its full citation (else today's line) where it reads the citation line today. The two copy buttons speak "Copy full citation" and "Copy short citation"; after a copy VoiceOver says "Full citation copied" or "Short citation copied". |
| PC-9 | **Long citation.** A formatted citation of five lines at Regular stays aligned: the copy buttons sit level with its first line, the Source and Observation links follow its last line. |
| PC-W1 | **Wide.** At Wide the sheet is 1280pt as today; the Citation column takes the extra width, so a long citation wraps to fewer lines. The copy track, links, loading area and notice are the same as Regular. |

### 4.1 Wide layout

| View | Regular | Wide | What moves |
| --- | --- | --- | --- |
| Provenance sheet | 880pt panel over the pane; Citation column about 300pt | 1280pt panel; Read as 220pt, Outcome 280pt, Citation column about 500pt | Nothing moves; the citation wraps to fewer lines (the sheet is a modal panel, so it does not fill the pane) |

## 5. Suggested frames

Each frame is the 1102 × 900 pane (Regular) or the 2296 × 1440 pane (Wide) dimmed behind the sheet, as the sheet sits over the Person page; draw only the sheet in detail.

| Frame | Shows |
| --- | --- |
| 1a — Regular | Birth date of Ada Robins: three records. Two from one household of the 1880 census (same full citation, no rule between them, each with its two copy buttons), one from a parish register whose type has no format (today's line, one Copy citation button) |
| 1b — Wide | Frame 1a at 1280pt |
| 2 — Copied | Frame 1a with Copy short citation in its check state |
| 3 — Owner groups | A derived Birth date row with two owner lines; a same-citation pair inside the first group and a value heading in the second |
| 4 — Loading | The header and column headings, the FormLoadArea's loading state in the record area |
| 5 — Failed | The header and column headings, the FormLoadArea's failed callout with Read again in the record area |
| 6 — Long citation | A five-line citation at Regular: buttons level with its first line, links under its last |
| 7 — No short format | A formatted row whose type has no short format: one button in the first slot |
| 8 — Spoken | Annotations: a row's spoken line, the two buttons' labels and their copied announcements, the loading label |

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Provenance sheet | Recipe | Extend | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheet.swift` | Gains the record area's three states (loading, failed, ready). No new panel |
| Record table | Recipe | Extend | `…/ProvenanceSheet/PVProvenanceRecordTable.swift` | Drops the rule inside a same-citation run (PC-5); same Divider elsewhere |
| Record row, Citation cell | Recipe | Extend | `…/ProvenanceSheet/PVProvenanceRecordRow.swift` | The link label is the formatted citation (PC-1); the copy track holds two buttons |
| Formatted citation text | Platform formatter + component | Ship | `CatalogCitationRender.styled` (Platform) drawn through `PVTitleText.italicizingEmphasis` (`…/Components/TitleText/`) | The engine's runs as text, italic runs in italic, the way a name's emphasis is drawn. The format editor's preview draws the same. Not a new kit component |
| Copy full / Copy short / Copy citation | Component | Extend | `macos/App/DesignSystem/Components/ClipboardButton/PVClipboardButton.swift` | One kit button per copy, each the existing ClipboardButton; it gains a rich-text payload. Not a new split or menu control |
| Citation link | Component | Ship | `…/Components/InkLink/` `PVInkLink` | As today |
| Source, Observation links | Component | Ship | `PVButton` `.link` | As today |
| Record area load state | Component | Ship | `…/Components/FormLoadArea/` `PVFormLoadArea` | Loading and failed in one kit body, as the Copy forms and the Artifact sheet use it; Read again reads the citations again. Not a spinner or a second notice (user, 2026-11-21) |
| Rule between rows | Component | Ship | `PVDivider` | Omitted inside a same-citation run |

**Non-goals.** No new kit primitive: no split button, copy menu, group header, group card or citation chip. No new column. The Wide sheet stays 1280pt.

## 7. Handoff

When the board is agreed: record the board link and the agreed frames on the **Board** line above and in [`README.md`](README.md); the plan [`../prs/S15-21-provenance-sheet-citations.md`](../prs/S15-21-provenance-sheet-citations.md) copies any change into its Design and moves from `Blocked — on board S15-D9` to `Planned`. When S15-21 lands, move this brief to `design/archive/` and note it in `completed.md`.
