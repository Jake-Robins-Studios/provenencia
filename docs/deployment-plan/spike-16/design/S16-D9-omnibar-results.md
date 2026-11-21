# S16-D9 — The omnibar's results on the kit popup list

**Kind:** Claude Design board (**rethink** of the omnibar results panel's card and row shell; the hit row's content, the omnibar field and the toolbar stay)
**Spike:** Provenencia Spike 16 (odds and ends), batch 6
**View:** the workspace toolbar's omnibar: the results list under the field
**Implements later as:** PR **S16-52** (The omnibar's results use the kit popup list)
**Board:** [agreed 2026-11-21](https://claude.ai/artifact/1UzGb9TQCd7ZQrmuAN5AY8), page "S3-01 Omnibar Results" (frames R1a, R2, R1b, R3, R4): every piece instanced from the S16-D11 kit; width and placement as OR-3 recommended (640 pt, trailing edges aligned, 388 pt at the narrowest window); the no-match hint 6 pt under the title; the web card's overlay shadow stands in for the app window's own shadow
**Depends on:** [S16-D11](S16-D11-web-kit-popup-list.md) (the web kit's PopupList and SearchHitRow; until it is published, draw the card and rows to match the ComboBox's open list exactly); the agreed Omnibar Results frames (Spike 3: the field, the rich hit row, the flat ranked list); the combo box's list as it is drawn today (the Source type picker's list on a Source type page)
**Related:** plan [`../prs/S16-52-omnibar-popup-list.md`](../prs/S16-52-omnibar-popup-list.md); working rule "(Batch 6) One kit popup list under the combo box and the omnibar" in [`../deployment-plan.md`](../deployment-plan.md#batch-6--idea-follow-ups); [`omnibar-search.md`](../../archive/spike-3/omnibar-search.md); [`macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide)
**Design system layers:** [`docs/design-system-layers.md`](../../../design-system-layers.md)
**Skill:** [`add-design-brief`](../../../../.agents/skills/add-design-brief/SKILL.md); [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md); [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md)

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

### This brief is a rethink of the results' card

Draw as a new turn "S16-D9 · Omnibar on the popup list" on the board that holds the Omnibar Results frames. Replace the results panel's card and its row highlight with the kit popup list's; do not keep the old panel as a variant. Before you clear the old frames, keep one instance of the agreed hit row (thumbnail, title, kind badge, secondary line, ref, match line) and the toolbar row: they are reused unchanged in every new frame. The omnibar field and the toolbar stay as agreed. These frames need the toolbar: draw the toolbar row (Back and Forward, breadcrumbs, the omnibar field) and the top of a page under it, with the results floating over the page.

---

## 1. Objective

The omnibar is the search field at the right of the workspace toolbar (⌘K). Typing two or more characters searches the catalog and shows the hits in a list under the field. Today that list is its own panel: 640 pt wide, painted over the content column, with a small inset around rounded row highlights, a subtle border and a soft shadow. It is the only floating list in the app that is not the kit popup list the combo boxes use.

This board draws the omnibar's results **on the kit popup list**, the list a combo box shows under its field: the same card, the same full-width row highlight, the same searching line. The list is its own window under the field, so it can never be clipped by the page, and it stays inside the content column at a narrow window instead of running over the sidebar.

**What stays.** Each hit row's content, its own inset and its order (the engine's rank); the field, its placeholder and ⌘K; the copy of the no-match line; Return opens the highlighted hit and clears the field; Escape closes the list and keeps the query; a click on a hit opens it.

## 2. Domain facts

| Fact | Meaning for the board |
| --- | --- |
| The omnibar field | `PVInput` small, search icon, `⌘K` suffix, 200–420 pt wide at the toolbar's right end, its trailing edge 32 pt from the content column's right edge, at Regular and at Wide. It does not change |
| A hit row's size | 40 pt thumbnail plus 7 pt above and below: about 54 pt tall, a little more with a match line. A 420 pt list shows about seven rows |
| A hit | One catalog record the search found: a Source, a source type, a metadata field, a Person, an Event, a Place or an Evidence graph. The row shows a 40 pt thumbnail or mark, the title, a kind badge (`Source`, `Person`…), a muted secondary line, a mono ref (`SRC-3K9M2`, accent when the query was that exact ref) and, when the match was in a note or a field, a faint match line (`note: …`) |
| Rank | Hits are listed in the engine's order. The first hit is highlighted when results arrive, so Return opens it |
| Searching | The search runs 180 ms after the last keystroke. With no hits on screen yet, the list shows the searching line. Hits already on screen stay while the next search runs |
| No match | A finished search with no hits: `No matches for “zzz”.` and `Check the spelling, or paste a catalog reference such as SRC-3K9M2` |
| Failure | A search that could not finish: a danger message carrying the error's own words, for example `Catalog closed.`, or `Something went wrong. Please try again.` for an unknown error |
| Keys | The field keeps focus. ↑/↓ move the highlight one row, Home/End and ⌘↑/⌘↓ to the first or last, Page Up/Down eight rows; the pointer moves the same highlight. Return opens the highlighted hit; Escape closes the list and keeps the query; typing changes the query and searches again |
| Closing | Escape, a click outside the list and the field, switching to another app, or opening a hit closes it. A click in the field keeps it open |
| The combo box's list | Today's kit popup list (in the kit, the ComboBox's open list): a card with the card surface, a 1 pt default border, the medium radius and the window's own shadow; 4 pt of air above the first row and below the last; rows full width with the selected-surface fill as the highlight; the searching line is a small spinner and `Searching…` in muted body-small |
| VoiceOver | The list is announced as "Search results"; each row reads its title, kind, secondary line and ref; the searching, no-match and failure lines are read as text |

### 2.1 What this board is not

- Not the omnibar field, its placeholder, its width or the toolbar.
- Not the hit row's content, the hit kinds, the ranking or the match line's wording.
- Not a grouping of hits by kind, a section header, a "show all" row or a footer.
- Not a new visible kit component: the card, the row shell and the lines are the kit popup list's.
- Not the Back and Forward history menu (S16-53) or any combo box.

---

## 3. Implementation gate

| S16-52 ships | Not S16-52 |
| --- | --- |
| OR-1 – OR-9, OR-W1 | Reopening the list after Escape without typing (not planned: as today, the list comes back when the query changes); grouping or a footer (not planned) |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| OR-1 | **The card.** The results are the kit popup list's card, exactly as a combo box's list draws it: card surface, 1 pt default border, medium radius, the window's own shadow, 4 pt of air above the first row and below the last, no inset at the sides. Today's panel (small radius, subtle border, the 4 pt inset on every side, the overlay shadow) goes |
| OR-2 | **The rows.** Each hit row keeps its agreed content, layout and its own inset (9 pt at each side, 7 pt top and bottom): the same row draws in Promote's record search, which this board does not change. Its highlight is the kit popup list row's: the selected-surface fill across the card's full width, square-edged, the card clipping the first and last rows at its corners; today's inset, rounded highlight goes |
| OR-3 | **Placement and width.** The list sits 4 pt under the field. Its trailing edge lines up with the field's trailing edge, and it extends leftward. Its width is 640 pt, narrowed so its leading edge stays at least 16 pt inside the content column's left edge, and never narrower than the field. At the default window (pane 1102 pt) it is 640 pt; at the narrowest window (700 pt) the field is about 404 pt from the column's left edge and the list is about 388 pt wide. **The board decides** the width; recommendation: 640 pt, as today |
| OR-4 | **Height.** The list is as tall as its rows, up to 420 pt; past that it scrolls inside the card and keeps the highlighted row in view |
| OR-5 | **The highlight.** When results arrive the first hit is highlighted. Draw a list of eight hits with the third highlighted by the pointer. Caption the keys from §2 on that frame; no frame per key |
| OR-6 | **Searching.** With no hits on screen and a search running, the card holds one line: the kit searching line, a small spinner and `Searching…` in muted body-small, starting 12 pt in (the omnibar's rows have no check gutter, so the line starts where a combo box's would without one). A search running while hits are on screen shows the hits, no line (draw this as a caption on the OR-5 frame) |
| OR-7 | **No match.** The card holds one line, laid out as the searching line is: `No matches for “zzz”.` in body-small medium, primary ink, and under it `Check the spelling, or paste a catalog reference such as SRC-3K9M2` in muted caption. A 120-character query wraps the first line inside the card; the line never widens the card |
| OR-8 | **Failure.** The card holds one line, laid out as the searching line is, holding the kit's danger Callout with the error's message (draw `Catalog closed.`). A failure is never drawn as an empty list or as the no-match line |
| OR-9 | **Open and close.** Draw no frame for closing. Caption the OR-5 frame: Return or a click opens the highlighted hit and clears the field; Escape closes the list and keeps the query in the field; a click in the field keeps the list open |
| OR-W1 | **Wide.** The toolbar at 2296 pt: Back and Forward at the left, the breadcrumbs taking the space between, the field at most 420 pt wide at the right end, 32 pt from the pane's right edge, as at Regular. The list keeps its Regular width and placement (OR-3): it is a popup under a field, and wider rows add nothing (Wide rule 2). Nothing moves between widths |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Omnibar results | 640 pt list under the field, trailing edges aligned, over the page | The same 640 pt list under the same field | Nothing; the list does not widen with the pane |

---

## 5. Suggested frames

Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440); the others as they say. Each frame draws the toolbar row and the top of a Sources list page under it.

| Frame | Requirement | Draw |
| --- | --- | --- |
| R1a / R1b | OR-1 – OR-5, OR-9, OR-W1 | Query `ilmin`: eight hits (two Sources, one with its exact ref in accent; a source type; a Person with a likeness; an Event; a Place; an Evidence graph; a Source matched in a note with its match line), the third highlighted by the pointer; the Person's lead is a photo likeness. Captions: the keys, Return, Escape, a click in the field, a search running with hits on screen |
| R2 | OR-3 | The narrowest window (pane about 436 pt): the toolbar with the field at its 200 pt floor, the list about 388 pt wide, its leading edge 16 pt inside the column |
| R3 | OR-4 | Regular only: query `smith`, twenty Person hits (rows about 54 pt), scrolled so the highlighted row (the twelfth) is the last fully shown row at the 420 pt height |
| R4 | OR-6, OR-7, OR-8 | Regular only: three cards stacked under one toolbar for comparison: the searching line (query `il`), the no-match line (query `zzz`, and a 120-character query wrapping), and the failure line |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes | Kit piece to instance |
| --- | --- | --- | --- | --- | --- |
| The list's card and scroller | Component | Ship | `macos/App/DesignSystem/Components/PopupList/PVPopupList.swift` `PVPopupListCard` | OR-1, OR-4. The same card a combo box's list draws. Not a new card, not a `PVCard` | PopupList card (S16-D11) |
| The row shell | Component | Ship | `PVPopupList.swift` `PVPopupListRow` | OR-2: the highlight, the hit area, the pointer moving the highlight. Replaces the omnibar's `PVMenuRowButtonStyle` rows | PopupList row (S16-D11) |
| The line in place of rows | Component | Ship | `PVPopupList.swift` `PVPopupListLine` | OR-6 – OR-8: the searching, no-match and failure lines all sit in it, so their text starts where a combo box's lines do | PopupList line (S16-D11) |
| The searching line | Component | Extend | `PVPopupList.swift` (today drawn inside `PVComboBox.swift` `rowsStack`) | OR-6: the combo box's spinner and `Searching…`, lifted into the kit list so both fields draw one line | PopupList searching line (S16-D11) |
| The hit row | Component | Extend | `macos/App/DesignSystem/Recipes/OmnibarHitRow/PVOmnibarHitRow.swift` → `macos/App/DesignSystem/Components/SearchHitRow/PVSearchHitRow.swift` *(new)* | OR-2. Content and inset unchanged. It moves to the kit's components as `PVSearchHitRow`, because it is content-agnostic and draws in the omnibar and in Promote's record search, as `PVTitleText` moved | SearchHitRow (S16-D11) |
| The list's window and placement | Component | Extend | `PVPopupList.swift` `.pvPopupList`, `PVPopupListPlacement` | OR-3: a list wider than its field hangs from the field's trailing edge, and one width rule keeps a popup 16 pt inside the content column. No visible piece | ComboBox's open list |
| Measured height | Component | New | `PVPopupList.swift` `PVPopupListMeasure` *(new)* | Sizes the window to its rows before it shows; the omnibar is one caller; second call site: `PVComboBox` (today's `measuringRows`). No visible piece | — |
| The hit's content | Snowflake | Ship | `macos/App/Features/Catalog/Search/CatalogSearchHitRow.swift` `CatalogSearchHitRow` | The thumbnail, title, kind, secondary line, ref and match line for one hit. Unchanged | Thumbnail, Badge (inside the hit row) |
| Failure message | Component | Ship | `PVCallout` (`tone: .danger`) | OR-8. Not italic muted text: a failure reads as one | Callout |
| The omnibar field | Component | Ship | `PVInput` in `macos/App/Features/Workspace/WorkspaceToolbar.swift` `omnibarField` | Unchanged; the list's anchor | Input |
| The old results panel | Snowflake | Remove | `macos/App/Features/Workspace/OmnibarResultsHost.swift` `OmnibarResultsPanel` | Its card, inset, rounded row highlights and overlay shadow go | — |

**Non-goals.** No new visible kit primitive, no second card style, no rounded row highlight, no section headers, no footer or "show all" row, no change to the field or to the hit row's content, no new icon, color or token.

---

## 7. Handoff

When the board is agreed: record the turn and its frames on the **Board** line here, in [`README.md`](README.md) and on the plan's **Board** line, with the width (OR-3) the board chose; the plan copies OR-1 – OR-9 and OR-W1 into its Scope (already there), fixes D-6 and D-7 to the board, and moves from `Blocked` to `Planned`. When S16-52 lands, the brief moves to the spike's design archive.
