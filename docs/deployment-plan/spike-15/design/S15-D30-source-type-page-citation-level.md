# S15-D30 — Source type page: the Citation level

**Kind:** Claude Design board (**enhancement** of the Source type page as S15-D6, S15-D7 and S15-D16 left it: a fourth suggestion list joins the side column, a fourth tick joins the Copy type sheet, and the format editor's completion lists the Citation's fields. Extend the existing page frames; the header, Details, the formats section's layout, the locked note, Delete, the leave confirm, the types list and the dialogs are unchanged. One frame of the Metadata page's field delete notice, which gains a fourth group line)
**Spike:** Provenencia Spike 15, slice 11
**View:** the Source type page's side column (Suggested fields), the Copy type sheet, the format editor's completion list and one of its warnings; the Metadata page's notice when a field cannot be deleted
**Implements later as:** PR **S15-54**
**Board:** agreed 2026-11-22 (user) — [Claude Design — Source Type Page](https://claude.ai/artifact/42ZuWus4ynyz7xUDwcF6zG): artboard *S15-D27 · S15-D6 · S15-D7 · S15-D16 · S15-D30 · Source type page board*, frames "S15-D30 · D30-1a – D30-13" (10 split into 10 and 10b), drawn by *Source type page · component*, and the new artboard *S15-D30 · Metadata field delete notice · component* (frame D30-12). Board decisions taken: four lists stacked, Citation last; the copy of § 2.1, the Evidence graph list reworded as drawn; Citation fields after the Evidence graph rows; the delete notice's Citation group from the kit's DeleteImpact recipe (the kit gained the three metadata vias). **Not taken from the board** (user, 2026-11-22): its CL-5 ranking (a field the type suggests at a level leads, frame 10's highlight): rows follow the typed query only, as S15-17; and multi-word completion ("cit li", frame 10b): the list still closes on a space
**Review:** with the plan, in [`../prs/S15-54-citations-hold-metadata.review.md`](../prs/S15-54-citations-hold-metadata.review.md)
**Depends on:** S15-12 (landed [#856](https://github.com/Jake-Robins-Studios/provenencia/pull/856)): the three Suggested fields lists ([S15-D6](archive/S15-D6-source-type-suggestion-levels.md)); S15-18 (landed [#877](https://github.com/Jake-Robins-Studios/provenencia/pull/877)): the Copy type sheet ([S15-D7](archive/S15-D7-copy-source-type.md)); S15-17 (landed [#924](https://github.com/Jake-Robins-Studios/provenencia/pull/924)): the format editor and its completion at the cursor ([S15-D16](archive/S15-D16-source-type-citation-formats.md)); S15-61 (landed [#943](https://github.com/Jake-Robins-Studios/provenencia/pull/943)): the metadata levels are one declared list
**Related:** working rules "Metadata lives at four levels with one vocabulary", "One level type", "Suggestions have a level", "A Citation holds metadata" in [`../deployment-plan.md`](../deployment-plan.md#working-rules); [`../evidence-explained-citation-map.md`](../evidence-explained-citation-map.md) § 6.6; [`macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide)
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

Add to the Source type page frames on this board (S15-D6's lists, S15-D7's sheet, S15-D16's completion list). Everything they drew stays. This board draws S15-D6's list block a fourth time, S15-D7's tick a fourth time, and S15-D16's completion list with Citation field rows in it. Draw nothing else new.

---

## 1. Objective

A Citation is the spot cited in a record: a page, a line, an entry. Until now only the Source, each Artifact and each Evidence graph could hold metadata values; the Citation held only its built-ins (its label, its file page). From this PR the Citation is the fourth level that holds metadata (user, 2026-11-22), with the same project vocabulary, so a type can suggest fields for each of its Citations, and a citation format can name a Citation's field (`{citation.meta.line_number}`). Where a Citation's values are typed is a later board (S15-D29, the citation composer); this board draws only where a Source type says which fields its Citations carry.

**What changes.**

- **A fourth list.** Suggested fields holds a Citation list under the Evidence graph list: "On each Citation". It behaves exactly as the other three: its own picker, plus, remove, count, empty, loading and failure states, read only on a plugin's type.
- **A fourth tick.** The Copy type sheet's "Copy from the original" gains "Suggested fields on each Citation" after the Evidence graph tick, with the same hint and absent state.
- **Completion lists Citation fields.** In the full and short notes, typing `{` lists, after the Citation's built-ins (Page, Image, Label), every metadata field at the Citation level, as it already lists them at the Source, Artifact and Evidence graph. The source list form is unchanged: it reads the Source only.
- **A warning goes and one changes.** `{citation.meta.line_number}` is no longer a mistake, so the warning "A citation has no metadata fields" never shows again. The warning for `{meta.page}` names the four levels.
- **The Metadata page's notice.** A field cannot be deleted while a value uses it. Its notice gains a fourth group, "3 citations record a value for this field", listed with the Source, Artifact and Evidence graph groups.

**What stays.** Every list, tick, row, toast and completion row looks as it does today. A field may be suggested at any number of the four levels. The Associated fields column counts all four lists with no layout change. The page's columns, header, Details, formats layout, Save and the leave confirm are unchanged at both widths.

---

## 2. Domain facts

| Fact | What it means on this board |
| --- | --- |
| Level | Where a field's value lives. **Source**: the record as a whole. **Artifact**: one copy used. **Evidence graph**: the researcher's grouping of evidence (a household, a family). **Citation**: one spot cited in an Artifact (a page, a line, an entry on the page). The fields come from one project vocabulary; the level is only where a type suggests them and where a value is kept. |
| A Citation's suggested field | A field a type offers, empty, on each Citation of its Sources. Seeded types suggest none at this level yet (a later PR seeds Page, Column, Line and others); a new project's Citation lists are empty. |
| Where the suggestions show | A later board (S15-D29) puts a Citation's fields in the citation composer. On this board the Citation list is edited only; nothing shows it elsewhere yet. |
| Sizes | A Citation list holds 0 to about 8 fields (page, column, line, dwelling, family, schedule, entry, folio). The other lists 0 to about 12. Four lists of 12 must still read. |
| Completion | The list holds every placeholder a form can hold, level by level in the order Source, Artifact, Evidence graph, Citation; each level's built-ins first, then every field of the project. With about 60 fields, Citation rows add about 60 rows after the Citation built-ins. Typing narrows the list as today ("line" → Line at each level, in level order). |
| Copy type | Copies each ticked level's list in its order. A level the original has no fields at reads unticked and disabled with "None on this type". |
| Field delete | A field is refused while any Source, Artifact, Evidence graph or Citation holds a value for it. The notice lists one group per level holding values, in that order, each with its count and up to a few named rows; a Citation is named as the other delete notices name it today: the start of its transcription, else the person it names, else its ref. |

### 2.1 Copy

The board may refine wording; the PR copies what the board shows. Strings marked *(today)* exist and stay.

| Where | Text |
| --- | --- |
| Citation list title / meaning | "On each Citation" / "The spot you cite: a page, a line, an entry" |
| Evidence graph list meaning (reworded) | "Your grouping of evidence: a household, a family" (today "One item in the record: a household, an entry"; a graph is the researcher's grouping, not an item, and "line" and "entry" now belong to the Citation) |
| Empty Evidence graph list (reworded) | "No Evidence graph fields yet. Assign what you note about each grouping, such as its household or family." (today "…about each item, such as its line or household.") |
| Empty Citation list | "No Citation fields yet. Assign what you note about each spot you cite, such as its page or line." |
| How the list is named in a sentence | "on each Citation of Census Sources" (the other three as today: "on each Census Source", "on each Artifact of Census Sources", "on each Evidence graph of Census Sources") |
| Picker label (spoken) | "Metadata field to assign on each Citation" |
| Add tooltip / spoken, with a pick | "Suggest Line on each Citation of Census Sources" *(today's sentence, the new phrase)* |
| Remove (tooltip, spoken) | "Stop suggesting Line on each Citation of Census Sources" |
| Toast after add | "Field assigned" / "Line is now suggested on each Citation of Census Sources." |
| Toast after remove, values kept | "Suggestion removed" / "Line is no longer suggested on each Citation of Census Sources. The field stays in this project’s vocabulary, and the 6 Sources, Artifacts, graphs, Citations and Source types that use it are unchanged." (today's sentence names "Sources, Artifacts, graphs and Source types"; every list's toast gains "Citations") |
| Copy type tick | "Suggested fields on each Citation", hint "3 fields" *(today's hint)*; absent "None on this type" *(today)* |
| Completion row, a Citation field | Label "Line", the origin pill, Chip "Citation" *(today's level name)*, `{citation.meta.line_number}` in mono |
| Warning for `meta` with no level | "Name a level before meta: source, artifact, graph or citation" (today ends "source, artifact or graph") |
| Field delete notice, Citation group | "3 citations record a value for this field" (beside today's "… sources record a value for this field", "… artifacts record …", "… Evidence graphs record …") |

### 2.2 What this board is not

- Where a Citation's values are typed (the citation composer's board: S15-D29 → S15-56).
- Needed and used marks on any board (S15-D20 → S15-39).
- The seeded Citation suggestions and the page chain (S15-60).
- Any change to the three existing lists, ticks or completion rows beyond the copy in § 2.1 (the Evidence graph list's meaning and empty copy are reworded there).
- Reordering a list, creating a field from the picker, a tab or fold over the lists: none, as S15-D6 decided.
- The rest of the Metadata page: only the notice's new group line.

---

## 3. Implementation gate

| PR | Ships | Not that PR |
| --- | --- | --- |
| **S15-54** | CL-1 – CL-7, CL-W1: the Citation list on an editable and a locked type, the fourth Copy type tick, Citation fields in completion, the two warning changes, the notice's Citation group, the toast copy | The composer's Citation board (S15-56); requirements on a Citation board (S15-55, S15-39); seeded Citation suggestions (S15-60) |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| CL-1 | **A fourth list.** Suggested fields shows four lists stacked in the order Source, Artifact, Evidence graph, Citation, each as S15-D6 drew them (micro-caps title, mono count trailing, the meaning under it, a hairline and 28pt between lists, the pool hint once). The Citation list's title, meaning and empty copy are § 2.1's, and so are the Evidence graph list's reworded meaning and empty copy, so that no word names two levels. No list is hidden behind a tab or a fold. |
| CL-2 | **The Citation list behaves as the others.** Its picker offers every field not already in the Citation list (Line in the Evidence graph list is still offered). Return adds, as S15-D6 SL-4. Remove takes the field out of the Citation list only. Its loading, read failure and write failure show in its own place; the other three lists keep working. While any add or remove runs, every list's plus and remove are disabled, the Citation list's included. A plugin's type shows the Citation list read only. |
| CL-3 | **Copy names the list.** Every tooltip, spoken label and toast that names a list uses § 2.1's phrase for the Citation list. The toast after a remove that keeps values names Citations in every list's sentence. VoiceOver reads the list as a group "On each Citation, 3 fields". |
| CL-4 | **Copy type's fourth tick.** In the Copy type sheet, "Suggested fields on each Citation" follows "Suggested fields on each Evidence graph", ticked when the sheet opens, with its count as the hint; disabled with "None on this type" when the original's Citation list is empty. Tab order follows the ticks. Nothing else in the sheet changes. |
| CL-5 | **Completion.** In the full and short notes, the completion list shows the Citation's built-ins, then every field at the Citation level, after the Evidence graph's rows. A Citation field row reads as every field row: label, origin pill, Chip "Citation", the placeholder `{citation.meta.<key>}` in mono. The source list form's list is unchanged (Source rows only). Typing "line" lists Line at each level, the Citation's last. |
| CL-6 | **Warnings.** `{citation.meta.line_number}` in the full or short note draws no warning. In the source list it draws today's "The source list reads the Source only". `{meta.page}` draws § 2.1's reworded warning. |
| CL-7 | **The field delete notice.** On the Metadata page, deleting a field that Citations hold a value for shows the notice with a Citation group after the Evidence graph group: § 2.1's heading with its count, then the named rows (the start of a Citation's transcription, else the person it names, else its ref), as the other groups list theirs. |
| CL-W1 | **Wide.** As S15-D6 SL-W1: at Wide the side column keeps its 340 – 480pt and the four lists stay stacked in it; Details and Suggested fields stay the centred pair. Side-by-side lists would need a column wider than the side column. The Copy type sheet and the delete notice are the same at both widths. A pick in progress and the page's scroll survive a resize across 1600pt. |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Source type page | Details (560pt) and the formats in the main column, Suggested fields (340 – 480pt) beside it with four lists stacked, the pair centred; the side column under the main below about 880pt | The same centred pair | Nothing |
| Copy type sheet | 520pt sheet over the page | The same sheet | Nothing |
| Metadata page field delete notice | The DeleteImpact notice as today, one more group | The same notice | Nothing |

---

## 5. Suggested frames

Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440), each with the toolbar above; the others at Regular. Draw them beside S15-D6's frames, from the page component.

**Data.** Types (invent every record): **Census** (Provenencia, `census`, used by 14 Sources) with Source list Jurisdiction, Schedule, Roll number; Artifact list Provider, URL, Accessed, Image; Evidence graph list Item, Dwelling, Family; Citation list Page, Column, Line. **Letter** (yours, `letter`, used by 0) with Source list Author, Recipient and nothing at the other three levels. **Grave memorial** (plugin `findagrave`, locked) with Source list Cemetery, Plot and Artifact list Photographer. Vocabulary: about 60 fields, including Page, Column, Line, Folio, Entry and Provider. Field **Line** is held by 2 Sources, 1 Artifact, 0 Evidence graphs and 3 Citations (one transcribed "John Ward, head, 42, farmer", one naming Mary Ward with no transcription, `CIT-7QK2M` with neither).

| Frame | Requirement | Draw |
| --- | --- | --- |
| 1a / 1b | CL-1, CL-W1 | Census's page: Details and the formats beside Suggested fields with its four lists, scrolled so the Evidence graph list (its reworded meaning) and the Citation list show side by side in the column. In 1b, a pick in progress in the Citation list's picker, to show it survives the resize |
| 2 | CL-2 | Census, the Citation list's picker open with "fo" typed (Folio highlighted; Column absent because the list has it) |
| 3 | CL-2, CL-3 | Right after adding Folio to the Citation list by Return: Folio fourth, "4 fields", the picker empty and focused, the toast "Folio is now suggested on each Citation of Census Sources." |
| 4 | CL-2, CL-3 | After removing Line from the Citation list: the toast with the values clause naming Citations |
| 5 | CL-1, CL-2 | Letter: the Source list with two rows; the Artifact, Evidence graph and Citation lists empty, each with its own copy |
| 6 | CL-2 | Census with the Citation list's read failed (retry Callout in its place) and the other three lists unaffected |
| 7a / 7b | CL-2 | Grave memorial: the locked note in Details; four read-only lists (Evidence graph and Citation empty) |
| 8 | CL-4 | The Copy type sheet over Census: six ticks plus the Citation tick, all on, hint "3 fields" |
| 9 | CL-4 | The Copy type sheet over Letter: the Citation tick disabled with "None on this type" |
| 10 | CL-5 | The full note with `{line` just typed: the completion list with Line at the Source, the Artifact, the Evidence graph and the Citation, the Citation row last |
| 11 | CL-6 | The full note holding `{meta.page}`: the warning line with § 2.1's wording |
| 12 | CL-7 | The Metadata page with Line selected and its delete refused: the notice listing "2 sources record …", "1 artifact records …", "3 citations record a value for this field" with "John Ward, head, 42, farmer", "Mary Ward", `CIT-7QK2M` |
| 13 | CL-1 | A type with 12 fields in each of the four lists, the page scrolled to the Citation list |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Page and its columns | Component | Ship | `macos/App/DesignSystem/Components/PageColumns/PVPageColumns.swift` with `PVColumnSplit.sourceTypePage` (`macos/App/Features/SourceTypes/SourceTypePageView.swift`) | Unchanged widths |
| Suggested fields section | Snowflake | Ship | `macos/App/Features/SourceTypes/SourceTypeSuggestionList.swift` | Draws one list per metadata level; a fourth level gives a fourth list. Not a fourth copy of the list view |
| One level's list | Snowflake | Ship (a fourth instance) | `SourceTypeSuggestionList` in the same file | Title, meaning, count, rows, empty, spinner, retry, error, picker; § 2.1's copy for the Citation |
| A list's title and count | Component | Ship | `PVSubsectionHeader` as S15-D6 drew it | Not a new header |
| Rows | Component | Ship | `PVCard` + `PVDivider`, `CatalogFieldDataTypeBadge` | As today |
| Field picker | Component | Ship | `macos/App/DesignSystem/Components/ComboBox/PVComboBox.swift` `PVComboBox` | One per list |
| Add / remove | Component | Ship | `PVIconButton` `.plus` / `.dismiss` | Tooltips name the list |
| Toast | Snowflake | Ship | `VocabularyToast` / `vocabularyToastOverlay` | § 2.1's copy |
| Copy type sheet | Component | Ship | `macos/App/Features/SourceTypes/SourceTypeCopyDialog.swift` over `PVFormDialog` | One more tick from the same loop |
| Part tick | Component | Ship | `PVCheckbox` with a description | As the other level ticks |
| Completion list | Component | Ship | `PVTextArea`'s completion over the ComboBox's list (`macos/App/Features/SourceTypes/SourceTypeFormatsSection.swift`) | More rows, same row design; the level Chip reads "Citation" |
| Warning line | Snowflake | Ship | in `SourceTypeFormatsSection.swift` | Copy only |
| Field delete notice | Recipe | Ship | `macos/App/DesignSystem/Recipes/DeleteImpact/` (`pvDeleteImpact`, from `macos/App/Features/Metadata/MetadataView.swift`) | One more group heading; no layout change |

**Non-goals.** No new kit primitive. No tab, segmented chooser, fold or second column over the lists. No reorder. No change to the existing lists', ticks' or completion rows' look. No change to the page's column widths. No Citation board anywhere on this board.

---

## 7. Handoff

When the board is agreed: record the artboard, its frames and the board's decisions (any copy change for the Citation list, the tick, the warning or the notice) on the **Board** line here and in [`README.md`](README.md). S15-54's plan copies CL-1 – CL-7, CL-W1, the copy and the inventory, fills D-15 and § 6 Strings from the board, and moves from `Blocked — on board S15-D30` to `Planned`. When S15-54 lands, this brief moves to the spike's design archive.
