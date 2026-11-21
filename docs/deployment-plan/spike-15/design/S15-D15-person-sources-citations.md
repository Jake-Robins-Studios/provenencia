# S15-D15 — Person page Sources section: Citations grouped under one citation

**Kind:** Claude Design board (**enhancement** of the Person page's Sources section as S15-D3 left it: S13-D6 rows, S13-D10 record links diagram beside them, S16-D2 folds, the Published column. Draw on the existing Person page board, page *Sources*, as a new turn after turn 19 "S15-D3 · Published date")
**Spike:** Provenencia Spike 15, slice 6
**View:** the Person page's Sources section (the record lines under each Source, and one notice above the rows; the caption line, the Source cells and the record links diagram are unchanged)
**Implements later as:** PR **S15-22** (SC-1 – SC-11, SC-W1)
**Board:** — (not drawn yet)
**Depends on:** S15-16 (landed [#914](https://github.com/Jake-Robins-Studios/provenencia/pull/914)): the engine renders each Citation's full and short citation, as styled runs, with a group key; S15-05 (landed [#919](https://github.com/Jake-Robins-Studios/provenencia/pull/919)): the section's Published column; S15-21 (landed [#930](https://github.com/Jake-Robins-Studios/provenencia/pull/930)): the provenance sheet draws the same formatted citation and the same labelled Full and Short copy buttons (S15-D9, page *Vitals*, turn 20)
**Related:** working rules "Grouping is by the rendered full citation, computed when read", "Citations render on demand, from SQL", "Follow the *Evidence Explained* style; never copy the book" in [`../deployment-plan.md`](../deployment-plan.md#working-rules); map § 6.9 "One EE citation, many Provenencia Citations" ([`../evidence-explained-citation-map.md`](../evidence-explained-citation-map.md)); the sheet's brief [S15-D9](archive/S15-D9-provenance-sheet-citations.md) (PC-1, PC-3, PC-7, PC-8: the citation text, the copy track and the failed notice this board reuses); plan [`../prs/S15-22-person-sources-citations.md`](../prs/S15-22-person-sources-citations.md)
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

Draw on the Person page board, page *Sources*, as a new turn "S15-D15 · Grouped citations", starting from turn 19's frames (S15-D3's Published column) at Regular and Wide. Keep the page header, the section switcher, the caption line (SOURCE · TYPE · PUBLISHED · REF), each Source row's title link, type pill, published date and ref, each record line as it is (graph link · graph ref · Subject name · Subject ref · Unpromote), the Show more rows, and the record links diagram and its column. Add only the citation blocks under record lines and one notice above the rows.

---

## 1. Objective

The Person page's Sources section lists the Sources a person's records come from. Under each Source, one **record line** per record of this person on that Source: the Evidence graph's name as a link, then "· graph ref · Subject name · Subject ref" in secondary caption text, and a ghost Unpromote button. Five lines show before "Show N more".

A record is drawn from several Citations: the highlighted pieces of a page (on a census row, the name, the age, the birthplace, the occupation, the relationship). The section shows none of them today.

**What changes.** Under each record line, the record's citation reads like a citation: the full citation the engine renders from the Source, its Artifact and the Evidence graph, with its italics, **once** for all the record's Citations that render the same full citation. Beneath it, its **pieces**: what each of those Citations says about this person ("Name Johann Weber · Age 34 · Birthplace Bremen"). Beside it, the provenance sheet's two labelled copy buttons, **Full** and **Short**. The citations are fetched when the section appears; the rows do not wait for them. If they cannot be read, one notice with **Try again** (the Person page's retry word) sits above the rows.

**What stays.** The caption line, the Source cells, the record lines, Unpromote, the folds, the record links diagram and its highlight, the empty, loading and error states of the section's own read. A record whose Source type has no full citation format looks as it does today: no block under its line.

---

## 2. Domain facts

| Fact | What it means on this board |
| --- | --- |
| A record line | One Subject on one Evidence graph that this person was promoted from. Its Observations (name, age, birthplace…) each cite one Citation on that graph. |
| Full and short citation | Each Citation has a full citation (the first footnote) and a short one (later notes), each rendered by the engine as runs of plain and italic text. A type may have a full format and no short one. |
| Same citation | Citations whose full citations render the same (the pieces of one census household row: same graph, same Artifact, same printed page) are one citation. The engine gives them the same group key. A record usually has one; a record whose Citations sit on two printed pages has two. |
| A piece | One Observation behind the citation, as its property and value: "Name Johann Weber", "Age 34". A negative Observation reads "Birthplace not Bremen". An Observation with no text value (a likeness) reads its property alone: "Likeness". The same text twice shows once. |
| No format | A Source whose type has no full citation format renders no text. That record shows no block, as today. The section never shows today's citation line ("Source, Artifact, Citation, p. 23"). |
| When citations arrive | The section's rows come from the page's own read and draw at once. The citations come from one call the section makes when it appears; at Scale (30 Sources, 300 citations) it answers in a few milliseconds. Nothing is drawn in their place while it runs. |
| After Unpromote | The section reads again; the remaining records' blocks stay drawn while the citations are read again, so nothing blinks or jumps. |
| Copy | Rich text keeps the italics when pasted into a word processor; plain text is written alongside for plain fields. As on the provenance sheet. |
| Example data | Invented people, places and records only. Never a real person or a real published citation example. |

### 2.1 What this board is not

- The provenance sheet (S15-D9, shipped); its fold (S15-D17) and records on open (S15-D18).
- Re-ordering or grouping Sources, or sorting record lines by citation.
- Today's citation line for a type with no format (the section does not show it).
- A count of a citation's Citations, a disclosure per block, a group card or heading.
- A link on the citation text (the record line's graph link opens the record).
- Editing a format or flagging missing fields (the format editor and the boards do that).
- Copy source-list entry (S15-D19, Source page).

---

## 3. Implementation gate

| PR | Ships | Not that PR |
| --- | --- | --- |
| **S15-22** | SC-1 – SC-11, SC-W1: the citation block under each record line (formatted citation, pieces, Full and Short), several blocks for a record on two pages, no block without a format, the failed notice with Try again, no blink after Unpromote | Everything in § 2.1 |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| SC-1 | **The citation.** Under a record line, the record's full citation as the engine renders it, its italic runs in italic: body small, primary ink. Its left edge aligns with the graph link's text above it. It wraps; it never truncates; it keeps a measure of at most 680pt (a citation measure token, beside the kit's prose and form measures). It is text, not a link. It is selectable. |
| SC-2 | **The pieces.** Directly under the citation, one caption line in secondary ink: each Observation behind that citation as "{Property} {value}", joined by " · ", in the order the record's Observations come; it wraps within the citation's measure. Negative: "{Property} not {value}". No text value: the property alone. The same text twice shows once. |
| SC-3 | **Same citation once.** All of a record's Citations that render the same full citation make one block: the citation once, all their pieces beneath it. A record whose Citations render two different full citations (two printed pages) shows two blocks, in the order their first Observation comes, 8pt apart. |
| SC-4 | **Copy buttons.** As on the provenance sheet (S15-D9 PC-3, as shipped): two labelled kit Buttons, ghost, small, stacked in an 84pt track 8pt right of the citation text, the top one level with the citation's first line: **Full** and **Short**, each with the copy glyph; spoken and tooltipped "Copy full citation" and "Copy short citation". A type with no short format shows Full alone. A copy turns the glyph to a check in success ink for 1.6 seconds. |
| SC-5 | **No format.** A record whose Citations have no full format shows no block; its line reads as today. A record with some formatted and some unformatted Citations shows blocks for the formatted ones only. |
| SC-6 | **Loading.** The rows draw at once. Until the citations arrive no block is drawn and nothing stands in its place (no skeleton, no spinner, no caption). Back to the page puts the keyboard and scroll on the row it left from once the citations have arrived or failed, so the blocks do not push it away. |
| SC-7 | **Failed.** If the citations cannot be read, one compact danger callout sits under the caption line, above the first row: title "Citations could not be read", the error's message, and **Try again** (secondary, small: the word every Person page section's read notice uses). The rows draw without blocks. The callout is announced. While the read runs again, Try again shows its busy state; on success the callout goes and the blocks draw. |
| SC-8 | **No blink.** After Unpromote, or any change that reads the citations again, the blocks already drawn stay until the new answer replaces them. |
| SC-9 | **Spoken.** The citation reads its plain text. The pieces line reads its pieces joined by commas: "Name Johann Weber, Age 34, Birthplace Bremen". The buttons speak "Copy full citation" and "Copy short citation"; after a copy VoiceOver says "Full citation copied" or "Short citation copied". Tab order: the record line's graph link, its Unpromote, then each block's Full and Short, then the next record line. |
| SC-10 | **Highlight.** The record links diagram's highlight (a node pointed at or focused) covers the record line only, as today; its blocks take no highlight and do not answer the pointer. |
| SC-11 | **Folds.** A record's blocks fold with its line: the five-line fold counts record lines, not blocks. |
| SC-W1 | **Wide.** At Wide the arrangement is the same (S13-D10, S16-D2, S15-D3: the Source cell fills, Type 176, Published 120, Ref 104, the diagram beside). The citation and its pieces keep their 680pt measure; the copy track follows the citation's text, 8pt right of it, not the row's right edge. The failed callout spans the rows' width. |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Person page, Sources section | Rows beside the record links diagram (or under it when the rows lack room); a record's blocks under its line, the citation wrapping in the room left of its 84pt copy track | The same columns; the Source cell takes the extra width; blocks keep a 680pt measure, so a citation wraps to fewer lines than at Regular | Nothing moves: blocks sit under their record lines at both widths (the section's Wide arrangement is S13-D10's) |

---

## 5. Suggested frames

Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440). Data: the Person page of Johann Weber (invented), as in turn 19, in title order:

- "Hamburg census 1867" (Census, `1867`): one record line "Household 214 · EVG-4H2KD · Johann Weber · CPR-7Q2KD". Its five Citations render one full citation: "Hamburg, Germany, 1867 census, Altstadt district 4, household 214, line 12, Johann Weber; digital image, *Nordarchiv Online* (… : accessed 12 March 2025)" (*Nordarchiv Online* italic), short "1867 census, Altstadt district 4, household 214, Johann Weber". Pieces: "Name Johann Weber · Age 34 · Birthplace Bremen · Occupation Cooper · Relationship Head".
- "Hamburger Adressbuch 1861" (`abt 1861`): its type has no format: the line as today, no block.
- "Konfirmandenbuch St. Ansgarii 1831" (phrase date): one record whose Citations sit on two pages: two blocks, "*Konfirmandenbuch St. Ansgarii*, 1831, p. 14" (pieces "Name Johann Weber · Confirmation 1831") and "…, p. 15" (pieces "Father Heinrich Weber"); the type has no short format, so each shows Full alone.

Invent every person and record.

| Frame | Requirement | Draw |
| --- | --- | --- |
| 1a / 1b | SC-1 – SC-5, SC-10, SC-W1 | Johann's Sources section, the diagram beside the rows: the census block with Full and Short, the address book with no block, the confirmation record with two blocks. In 1a, point at the census node in the diagram: the record line highlights, its block does not |
| 2 | SC-4 | Regular, the census block with **Short** in its copied state |
| 3a / 3b | SC-7, SC-W1 | The failed callout under the caption line, rows without blocks; at Wide it spans the rows' width |
| 4 | SC-1, SC-4 | Regular, a five-line citation: Full and Short level with its first line, the pieces under its last line |
| 5 | SC-6 | Regular, the first frame of a visit: rows drawn, no blocks yet (to show nothing stands in for them) |
| 6 | SC-9 | Regular, a VoiceOver caption under frame 1a: the citation's spoken text, the pieces line, the two buttons' labels and announcements, the Tab order through one record |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Sources section rows and record lines | Snowflake | Extend | `macos/App/Features/Conclusions/PersonSourcesSection.swift` `PersonSourcesRowView`, `PersonSourcesLineView` | A line gains its blocks under it (SC-1). The line itself, its highlight and Unpromote are unchanged |
| Citation block | Snowflake | New | `macos/App/Features/Conclusions/PersonSourcesSection.swift` | The formatted citation, its copy track beside it, the pieces line under it. Only this section draws it; not a kit component |
| Formatted citation with Copy Full / Copy Short | Recipe | New (promoted) | `macos/App/DesignSystem/Recipes/CitationCopy/` *(new)*, from the provenance sheet's citation cell and copy track in `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceRecordRow.swift` | One interaction, one piece: the citation text (`CatalogCitationRender.styled` drawn through `PVTitleText.italicizingEmphasis`, as S15-D9 PC-1) with the labelled Full and Short `PVClipboardButton`s stacked in the 84pt track beside it, the top one level with its first line. Second call site: this section; the sheet keeps drawing it (its citation is a link there, text here). Not a split button, menu or new copy control |
| Clipboard button | Component | Ship | `macos/App/DesignSystem/Components/ClipboardButton/PVClipboardButton.swift` | Its `word:` and `rich:` from S15-21 |
| Failed notice | Component | Ship | `macos/App/DesignSystem/Components/Callout/PVRetryCallout.swift` | Compact, danger, Try again, as every Person page section's read notice. Not a toast, not `PVFormLoadArea` (the rows are not waiting on it) |
| Show more | Snowflake | Ship | `macos/App/Features/Conclusions/ConclusionShowMoreRow.swift` | Unchanged; counts record lines |
| Divider | Component | Ship | `macos/App/DesignSystem/Components/Divider/` `PVDivider` | Unchanged; no rule between a line and its blocks |

**Non-goals.** No new kit component: the citation with its copy track is the provenance sheet's, promoted to a recipe because it gains this second caller. No group card, heading, count, disclosure or chip for a block. No skeleton or spinner for the blocks. No change to the caption line, the Source cells, the record line, the diagram or the folds.

---

## 7. Handoff

When the board is agreed: record the link, the frames and the board's decisions on the **Board** line here, in [`README.md`](README.md) and on S15-22's plan **Board** line; the plan copies SC-1 – SC-11 and SC-W1 as drawn and moves from `Blocked — on board S15-D15` to `Planned`. When S15-22 lands, the brief moves to the spike's design archive.
