# S15-D16 — Source type page: citation formats

**Kind:** Claude Design board (**enhancement** of S15-D27's Source type page: a Citation formats section and its preview join the main column under Details, and Details' Save changes and Revert move below them to save both. Extend the existing page frames; the header (with Copy), the three Suggested fields lists, the locked note, Delete, the leave confirm, the list and the dialogs are unchanged)
**Spike:** Provenencia Spike 15, slice 5
**View:** the Source type page's main column, on an editable and on a locked type
**Implements later as:** PR **S15-17**
**Board:** agreed 2026-11-20 (user) — [Claude Design — Source Type Page](https://claude.ai/artifact/42ZuWus4ynyz7xUDwcF6zG): artboard *S15-D27 · S15-D6 · S15-D7 · S15-D16 · Source type page board*, frames "S15-D16 · D16-1a – D16-15" (7 split into 7 and 7b, 10 into 10 and 10b) with decision notes, drawn by *Source type page · component*. Board decisions: each format's preview sits above its text area, in a sunken block with an accent rule, under one "Preview with" picker above the three (user, 2026-11-20); previews follow typing 250 ms after it stops; the completion list is the ComboBox's, 360pt; a warning is a danger caption line with its quote in mono, underlined on hover; Save and Revert under a rule at the column's foot; copy added: the syntax strip "{ } a field · | or, if empty, the next · [ ] drops out when empty · * * italic · \\ a literal { [ * or \\", "Not shown while the format has a warning", "Unclosed field", "Unclosed italic", "Too long: 4,012 characters, 12 over". **Not taken from the board:** its CF-3 ranking (suggested fields first; the same field first after `|`): rows follow the typed query only (user, 2026-11-20)
**Review:** with the plan, in [`../prs/S15-17-format-editor.review.md`](../../prs/S15-17-format-editor.review.md)
**Depends on:** S15-48 (landed [#848](https://github.com/Jake-Robins-Studios/provenencia/pull/848)): the page (S15-D27, [archived](S15-D27-source-type-page.md); TP-7 puts the formats under Details in the main column); S15-12 (landed [#856](https://github.com/Jake-Robins-Studios/provenencia/pull/856)): the three Suggested fields lists and the micro-caps list header (S15-D6, [archived](S15-D6-source-type-suggestion-levels.md)); S15-18 (landed [#877](https://github.com/Jake-Robins-Studios/provenencia/pull/877)): Copy in the header (S15-D7, [archived](S15-D7-copy-source-type.md)); S15-15 and S15-16 (landed): a type stores three formats, and the engine previews a format and reports its mistakes
**Related:** working rules "Citation formats are data on the Source type", "Every placeholder names its level; fallback is written", "Built-in placeholders are one table", "One render request for previews and the list entry", "A Source type has its own page" in [`../deployment-plan.md`](../../deployment-plan.md#working-rules); [`../evidence-explained-citation-map.md`](../../evidence-explained-citation-map.md) § 6.3 "The editor"; [`docs/citation-formats.md`](../../../../citation-formats.md) (the syntax, the built-ins, the diagnostics); [`macos-client-patterns.md` § 9](../../../../macos-client-patterns.md#9-window-widths-regular-and-wide)
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

Add to the Source type page frames on this board (S15-D27 frame 2b, S15-D6's and S15-D7's frames, and the page component). The header with Copy and Delete, the side column's three Suggested fields lists, the locked note, the leave confirm, the types list and the Add type and Copy type dialogs stay as they are. S15-D27 TP-7 named the slot: Citation formats sit under Details in the main column. This board draws that section, its preview, and moves Details' Save changes and Revert to the foot of the main column, where they save Details and the formats together (user, 2026-11-20).

---

## 1. Objective

A Source type holds three citation formats: the **full** note (the first time a source is cited), the **short** note (later citations) and the **source list** entry. Each is a line of text in a small syntax: literal text, placeholders in braces such as `{source.meta.jurisdiction}` or `{citation.page}`, optional groups in square brackets that drop out when a placeholder inside is empty, and `*italic*`. Today the seed writes them and nothing shows them. After this board, a researcher edits a type's three formats on its page, inserts fields without remembering the syntax, sees each format filled in against a real Source of the type as they type, and sees what is wrong with a format at the place it is wrong.

**What changes.**

- **Citation formats section.** Under Details in the main column: the three formats, each a text area in mono type with its title, its character count, and its warnings.
- **Fields complete as you type** (user, 2026-11-20). Typing `{` in a format opens a list at the cursor of every placeholder that format can hold; the list narrows as the researcher keeps typing ("li" → Line at each level), and Return or Tab puts the whole placeholder in (`{graph.meta.line_number}`). Typing `|` inside a placeholder opens it again for the next option of a chain. There is no separate Insert field control: the researcher never leaves the text.
- **Warnings at their place.** Each mistake the engine finds is a line under its format: what is wrong and the text it is about. Clicking it selects that text in the format. The format's border turns red.
- **A key two fields share.** When a project has two fields with the same key, the format asks which one it means, in a Select on the warning line.
- **Preview.** Under the three formats: a picker of the type's Sources, then each form filled in against the picked Source. Full and short use the Source's first citation; the source list uses the Source. Under each, what the Source is missing that the format needs.
- **One Save.** Save changes and Revert sit at the foot of the main column and cover Label, Icon, Description and the three formats. Leaving with any of them unsaved shows today's discard confirm.

**What stays.** Details' fields, the side column, the header and Delete. A plugin's type stays read only: its formats show as text with no editing, and its preview still works.

---

## 2. Domain facts

| Fact | What it means on this board |
| --- | --- |
| Three forms | **Full note** (first citation of a source), **Short note** (later citations), **Source list** (the bibliography entry). Each may be empty. A type with no full note gives its citations today's plain citation line. |
| The syntax | `{level.meta.key}` a metadata field at a level; `{level.name}` a built-in; `{a\|b}` the first that has a value; `[ … ]` an optional group; `*…*` italic; `\{` `\[` `\*` `\\` a literal character. Everything else is literal. |
| Levels | **Source** (the record), **Artifact** (the copy used), **Evidence graph** (the item cited), **Citation** (the place in it). The source list form reads the Source only: any other level is a warning there. |
| Built-ins | Source: Title, Type, Date (also "year only"); Artifact: Label; Evidence graph: Name; Citation: Page, Image, Label. |
| Fields | About 60 metadata fields in a project's vocabulary; any can be placed at any of the three metadata levels. |
| Lengths | A format holds up to 4,000 characters. The seeded census full note is about 560 characters, so it wraps to 6 to 8 lines in the main column. |
| Warnings | About 20 kinds: an unclosed group, a stray bracket, a field no one has, a level name misspelt, a field at the wrong level for the list form, a key two fields share, and so on. Each points at a stretch of the format's text. |
| Preview | Rendered by the engine, never by the view: plain text with italic stretches. A Source with no citations yet fills only its own values; Artifact, Evidence graph and Citation placeholders stay empty, and their groups drop. |
| Sizes | A type has 0 to 500 Sources; the project up to 3,000. |
| Saving | One Save writes the Details and the three formats. A save with a warning in any format is refused: nothing saves, and the warnings show. |

### 2.1 Copy

The board may refine wording; the PR copies what the board shows. Strings marked *(today)* exist and stay.

| Where | Text |
| --- | --- |
| Section title | "Citation formats" |
| Syntax strip (editable type) | One line under the section hint, each piece in mono with its meaning: `{ }` a field · `[ ]` drops out when empty · `|` the first that has a value · `* *` italic · `\` a literal character |
| Section hint (editable type) | "How citations of this type are written. Fields in braces fill from the Source, its Artifact, its Evidence graph and the citation; text in square brackets drops out when a field in it is empty." |
| Form titles / meanings | "Full note" / "The first time a source is cited"; "Short note" / "Each later citation"; "Source list" / "The entry in a list of sources" |
| Character count | "560 / 4,000"; over the limit it reads in the danger tone |
| Empty format placeholder | Full: "No full note: citations of this type show their plain citation line. Type { to add a field."; Short: "No short note. Type { to add a field."; Source list: "No source list entry. Type { to add a field." |
| Completion list | No title. Its rows only; a list with no match shows one muted line "No field matches “jurisdicton”" and stays open while the researcher types. Spoken on open: "Field suggestions, 12. Up and down to choose, Return to insert." |
| Completion row | The label ("Line"), the field's origin pill when it is a field (so two fields with one key read apart), the level as a Chip ("Evidence graph"), the placeholder in mono under the label (`{graph.meta.line_number}`); the year-only date reads "Date, year only" |
| Warning line | The message, then "at" and the quoted text: "Unclosed group at “[, p. {citation.page}”". One message per kind; for example "Unclosed group", "This bracket closes no group", "No field has the key nope", "Two fields have the key page: choose one", "The source list reads the Source only", "Name a level before meta: source, artifact or graph" |
| Shared key Select | Label "Which page field?"; each option the field's label and its origin ("Page · Provenencia", "Page · yours") |
| Preview title | "Preview" |
| Preview picker | Label "Preview with"; placeholder "Choose a Census Source"; hint "Full and short notes use the Source's first citation." |
| Preview row labels | "Full note", "Short note", "Source list" |
| No format to preview | "No format" (muted) |
| Missing line | One line per missing chain: "Missing: Jurisdiction on the Source"; a chain: "Missing: Line on the Evidence graph, or on the Source" |
| No Sources of the type | "No Census Source yet. Add one to preview these formats; warnings still show." |
| Preview failed | Callout: "The preview could not be shown", the error, "Try again" |
| Save and Revert | "Save changes", "Revert" *(today, moved)* |
| Save refused by a warning | Danger Callout beside Save: "Fix the marked formats, then save." |
| Toast after a save | Details only: today's. Formats only: "Citation formats saved" / "Census's citations now use these formats." Both: "Source type updated" / "Census and its citation formats are saved." |
| Locked type | Each format read only in a sunken Card; an empty one reads "No format" |

### 2.2 What this board is not

- The citations themselves on the provenance sheet, the Person page or the Source page (S15-21, S15-22, S15-23).
- Needed and used marks on metadata boards (S15-39).
- Choosing which citation of the Source the preview uses (the first one, always; user, 2026-11-20).
- Syntax colouring or underlining inside the text area: warnings are lines under the format.
- A fuller syntax guide (a detachable popover, a docked panel or a window): not planned for now; the strip, completion and warnings teach the syntax (user, 2026-11-20).
- Copy from another type (Copy in the header, S15-18, unchanged).
- A fourth form, per-Source formats (refused this spike).

---

## 3. Implementation gate

| PR | Ships | Not that PR |
| --- | --- | --- |
| **S15-17** | CF-1 – CF-12, CF-W1: the section, field completion at the cursor, warnings with their place, the shared-key choice, the character count, the preview with its Source picker and missing lines, one Save for Details and formats, the locked type, the leave confirm | Citations on other screens (S15-21 – S15-23); board marks (S15-39) |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| CF-1 | **The section.** Under Details in the main column: the section title and hint, the syntax strip (editable type; § 2.1: five pieces of syntax, each its mono token and a few words; it wraps to two lines at Regular and is never folded away), then the three forms stacked in the order Full note, Short note, Source list. Each form has a micro-caps title with its character count trailing (the inventory's subsection header, as the suggestion lists' headers), its meaning in italic under it, then its text area. |
| CF-2 | **The text area.** Mono, wrapping, 3 lines tall when empty and growing to 10 before it scrolls inside itself. An empty form shows its placeholder (§ 2.1). Typing never reformats the text. |
| CF-3 | **Fields complete at the cursor** (user, 2026-11-20). In an editable format, typing `{` (not after a `\`) opens a completion list anchored just below the cursor, over the page; typing `|` inside an open placeholder opens it for the chain's next option. The list holds every placeholder that form can hold, as the engine lists them (level order Source, Artifact, Evidence graph, Citation; built-ins first, then the fields; the source list form holds the Source level only). What the researcher types after the `{` or `|` narrows it, matching the label, the key, the level name and the placeholder text ("li", "line", "graph li", "graph.meta.li"); the first match is highlighted. Up and Down move the highlight; Return, Tab or a click puts the highlighted placeholder in place of what was typed since the `{` or `|`, and adds the closing `}` unless one or a `|` already follows; the cursor lands after it. Escape closes the list and keeps the typed text. The list also closes when the cursor leaves the placeholder, on `}`, on a space, or when the area loses focus. No match: one muted line, the list stays open. The list is at most 8 rows tall and scrolls; it never covers the line being typed (it opens above the line when there is no room below). Choosing one of two fields that share a key records which (no warning follows). |
| CF-4 | **Warnings.** Under a form, one line per mistake, in text order: a warning icon, the message, "at" and the quoted text it points at (cut to about 40 characters with an ellipsis). The form's text area border turns danger. Clicking a line selects that stretch in the text area. Warnings update as the researcher types (a moment after typing stops), and come back with a refused Save. A form with no mistakes shows no line. |
| CF-5 | **A key two fields share.** When a placeholder names a key that two fields hold, its warning line carries a Select of those fields (label and origin). Choosing one clears that warning; the choice is part of the unsaved formats and saves with them. A format read back with a stored choice shows no warning. |
| CF-6 | **Character count.** Each form's header shows "used / 4,000". Over 4,000 it reads in the danger tone and the engine's "Too long" warning shows. |
| CF-7 | **Preview** (revised on the board, user 2026-11-20). One "Preview with" picker of the type's Sources (searchable by title and ref; the most recently changed Source picked when the page opens) and its hint sit above the three forms. Each form's preview sits right above its text area, under the form's title: the form filled in for that Source with its italics, then the missing line when the format needs something the Source does not have. A form with no format reads "No format"; a form with warnings reads "Not shown while the format has a warning". The previews follow the unsaved text 250 ms after typing stops. |
| CF-8 | **Preview states.** Rendering: the previous render stays, with a small spinner by the subsection title. Failed: a retry Callout in place of the three rows. A type with no Sources: the picker is absent and the subsection shows its note (§ 2.1); warnings still show. |
| CF-9 | **One Save.** Save changes and Revert sit once, at the foot of the main column, under the preview. Save is enabled when Label, Icon, Description or any format differs from what is saved and Label is valid; it saves the changed parts. A save refused for a format warning saves nothing, shows the warnings at their forms and the Callout beside Save, and keeps every edit. Revert restores Details and the three formats. One toast names what saved (§ 2.1). |
| CF-10 | **Leaving.** Leaving the page with an unsaved format shows today's discard confirm, as unsaved Details do. |
| CF-11 | **A plugin's type.** The section title shows without its hint; each form shows its title, its meaning and its text read only in a sunken Card ("No format" when empty); no picker, no count, no warnings. The preview works as on an editable type, from the stored formats. No Save or Revert shows. |
| CF-12 | **VoiceOver.** Each form's text area is named by its title ("Full note"); its count reads "560 of 4,000 characters". A warning line reads its message and quoted text and is a button: "Unclosed group at “[, p. {citation.page}”, select". When the completion list opens, VoiceOver hears its count and how to use it; each highlight change reads the row ("Line, Evidence graph, graph.meta.line_number"); inserting reads the placeholder put in. Each preview row reads its label then its text. |
| CF-W1 | **Wide.** The page keeps S15-D27's centred pair at Wide (TP-W1): the formats and the preview stay in the main column at its 560pt measure, under Details, and the side column keeps the suggestion lists. A format is text to read and edit, so it keeps its measure (rule 2); a wider preview column would leave the format and its render apart. A focused text area, its cursor, a pick and the preview's Source survive a resize across 1600pt. |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Source type page | Details, then Citation formats, then Preview, then Save and Revert, in the main column (560pt), beside Suggested fields (340 – 480pt), the pair centred; below about 880pt the side column goes under the main column | The same centred pair | Nothing |

---

## 5. Suggested frames

Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440), each with the toolbar above; the others at Regular, scrolled to the section. Draw them from the page component beside S15-D6's frames.

**Data.** Invent every record. Type **Census** (Provenencia, editable, 14 Sources) with:

- Full note: `{source.date:year} census, {source.meta.jurisdiction}[, {source.meta.schedule}][, ED {source.meta.enumeration_district}][, p. {citation.page}][, dwelling {graph.meta.dwelling_number|source.meta.dwelling_number}][, {graph.meta.item|source.meta.item}][; {artifact.meta.format}, *{artifact.meta.provider}*].`
- Short note: `{source.date:year} census, {source.meta.jurisdiction}[, p. {citation.page}][, {graph.meta.item|source.meta.item}].`
- Source list: `{source.meta.jurisdiction}. {source.date:year} census[, {source.meta.schedule}].`
- Sources: "1880 census, Calder County" (`SRC-7KQ2M`, most recently changed), "1870 census, Calder County", and twelve more.
- Its preview: Full "1880 census, Calder County, Westmark, population schedule, ED 236, p. 14, dwelling 112, Ada Robins; digital image, *Westmark Heritage*." Short "1880 census, Calder County, Westmark, p. 14, Ada Robins." Source list "Calder County, Westmark. 1880 census, population schedule."

Type **Letter** (yours, 0 Sources, no formats). Type **Grave memorial** (plugin `findagrave`, locked) with a full note and nothing else. Fields include two with the key `page` (Provenencia's "Page" and the researcher's "Page").

| Frame | Requirement | Draw |
| --- | --- | --- |
| 1a / 1b | CF-1, CF-2, CF-7, CF-9, CF-W1 | Census's page scrolled to the section: Details, the hint and the syntax strip, the three forms with counts, the preview of the 1880 Source, Save and Revert at the foot, disabled. In 1b the cursor sits in the full note, to show it survives the resize |
| 2 | CF-3 | The full note with `{line` just typed before the closing period: the completion list under the cursor, Line at the Evidence graph highlighted, then Line at the Source and the Artifact, each with its Chip and placeholder |
| 2b | CF-3 | A chain in progress: `{graph.meta.line_number|` typed, the list open again for the next option with Line at the Source first |
| 2c | CF-3 | `{jurisdicton` typed: the list's one muted no-match line |
| 3 | CF-3, CF-7, CF-9 | After Return in frame 2, `{graph.meta.line_number}` in place of `{line`: the cursor after it, the count up, the preview showing ", line 14", Save enabled |
| 4 | CF-4 | The short note with `[, p. {citation.page}` (its `]` deleted) and `{source.meta.jurisdicton}` misspelt: two warning lines, the border danger, the short note's preview row empty, the other two still rendered |
| 5 | CF-4 | Frame 4 after clicking the first warning: the `[` through the end selected in the text area |
| 6 | CF-5 | The full note naming `{citation.page}` changed to `{source.meta.page}`: its warning "Two fields have the key page: choose one" with the Select open on the two Page fields |
| 7 | CF-4 | The source list holding `{citation.page}`: "The source list reads the Source only at “citation.page”"; and, separately, `{` typed in the source list: the completion list offering only Source rows |
| 8 | CF-6 | A full note at 4,012 characters: the count in danger, the "Too long" warning |
| 9 | CF-7 | The preview with the missing line under the full note ("Missing: Jurisdiction on the Source") for a Source with no jurisdiction |
| 10 | CF-8 | Letter: three empty forms with their placeholders, no Sources so the preview note shows; and, separately, Census's preview failed with its retry Callout |
| 11 | CF-9 | Save refused: the warnings at the short note and the Callout beside Save, every edit kept |
| 12 | CF-9 | After a save of the formats only: the toast |
| 13 | CF-10 | Back with an unsaved format: today's discard confirm over the page |
| 14a / 14b | CF-11 | Grave memorial: the locked note in Details, the read-only full note, "No format" for the other two, its preview; no Save or Revert |
| 15 | CF-1, CF-W1 | Census at a pane of 860pt: the side column under the main column |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Page and its columns | Component | Ship | `macos/App/DesignSystem/Components/PageColumns/PVPageColumns.swift` with `PVColumnSplit.sourceTypePage` (`macos/App/Features/SourceTypes/SourceTypePageView.swift`) | Unchanged widths; the main column grows |
| Citation formats section | Snowflake | New | `macos/App/Features/SourceTypes/SourceTypeFormatsSection.swift` *(new)* | The section, three forms, the preview. One form view drawn three times, not three copies. No second call site: a snowflake |
| Section title | Component | Ship | `PVSectionHeader` | "Citation formats", as "Details" |
| Syntax strip | Snowflake | New | in `SourceTypeFormatsSection.swift` | Mono tokens and micro text in a wrapping row (`PVFlowLayout`); not a Callout, not a table. No second call site: a snowflake |
| A form's title and count | Component | Extend | `macos/App/DesignSystem/Components/SubsectionHeader/PVSubsectionHeader.swift` `PVSubsectionHeader(title:meta:)` | Title in micro caps, the count as its mono meta, the meaning under it: the suggestion lists' header. Gains a meta tone (muted, danger) for the count over the limit, and a trailing accessory for the preview's spinner |
| Format text | Component | Extend | `macos/App/DesignSystem/Components/TextArea/PVTextArea.swift` `PVTextArea` (typography `.mono`) | Gains a cursor handle so a warning selects its stretch; not a new text control |
| Completion list | Component | Extend | `PVTextArea` (a completion source it asks at the cursor) over the popup list `PVComboBox` draws (`macos/App/DesignSystem/Components/ComboBox/PVComboBox.swift`), moved out of the ComboBox so both use it | The ComboBox's list look: rows, highlight, max height, scroll. A row: label, origin pill (`OriginPill`, `macos/App/Features/Catalog/OriginMarkers.swift`) for a field, the level as a Chip, the placeholder in mono. Not a native completion menu (plain strings, no level), not a second list design |
| Level mark in a row | Component | Ship | `PVChip` | The level's name |
| Warning line | Snowflake | New | in `SourceTypeFormatsSection.swift`, composed of `PVFocusRingButtonStyle`, `PVIcon` warning and `PVErrorText`'s type | A button with the kit focus ring and Return; not a Callout per warning (a format with five mistakes would stack five boxes). No second call site: a snowflake |
| Shared key choice | Component | Ship | `PVSelect` | On the warning line |
| Read-only format | Component | Ship | `PVCard` tone sunken | Mono text, locked type only |
| Preview subsection title | Component | Extend | `PVSubsectionHeader` | "Preview", the spinner as its trailing accessory while rendering |
| The formats' read | Component | Ship | `macos/App/DesignSystem/Components/FormLoadArea/PVFormLoadArea.swift` `PVFormLoadArea` | Loading and a failed read of the formats, with its retry |
| Preview Source picker | Component | Ship | `PVComboBox` (plain rows: title, ref) | Searchable; the type's Sources only |
| A rendered citation | Snowflake | New | in `SourceTypeFormatsSection.swift` | `Text` built from the engine's runs, italics kept. Second call site: S15-21, which moves it to `Platform/` |
| Missing line | Component | Ship | `PVCallout` tone neutral, compact | One per form with missing fields |
| Preview failure | Component | Ship | `PVRetryCallout` | In place of the three rows |
| No Sources note | Component | Ship | `PVCallout` tone neutral, compact | Not EmptyState: the page is not empty |
| Save and Revert | Recipe | Ship (moved) | `VocabularyFormActions` | Once, at the foot of the main column |
| Save refused | Component | Ship | `PVCallout` tone danger | Beside Save, as today's save error |
| Leave confirm | Component | Ship | `pvConfirm(item:copy:)` with `PVConfirmCopy.discardChanges` | Today's, now also for formats |
| Toast | Snowflake | Ship | `VocabularyToast` / `vocabularyToastOverlay` | Copy per § 2.1 |

**Non-goals.** No new kit primitive (`PVTextArea` gains a cursor handle and completion at the cursor, over the ComboBox's list; `PVSubsectionHeader` a meta tone and an accessory; the rest is composed). No Insert field button or picker beside the text (user, 2026-11-20). No syntax colouring, inline underline or code editor. No form switcher, tab or segmented control over the three forms (all three show). No completion list of our own design: it is the ComboBox's list, at the cursor. No choice of citation in the preview. No change to Details' fields, the side column, the header or the dialogs.

---

## 7. Handoff

When the board is agreed: record the artboard, its frames and the board's decisions (the completion list at the cursor, the warning line's look, the preview's spacing, any copy change) on the **Board** line here and in [`README.md`](../README.md). S15-17's plan copies CF-1 – CF-12, CF-W1, the copy and the inventory, fills its view Decision and § Strings from the board, and moves from `Blocked — on board S15-D16` to `Planned`. When S15-17 lands, this brief moves to the spike's design archive.
