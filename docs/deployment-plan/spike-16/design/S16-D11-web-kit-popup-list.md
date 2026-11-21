# S16-D11 — The web kit gains the popup list

**Kind:** Claude Design kit change (**enhancement** of the Provenencia design system: a PopupList component, and the ComboBox's open list composed from it; no app view)
**Spike:** Provenencia Spike 16 (odds and ends), batch 6
**View:** the design system's component library and its component sheet, not an app view
**Implements later as:** PR **S16-52** (its S16-D9 board instances these pieces, and it renames the Swift row to match KP-6). The rest of the Swift side already exists in the app's kit; this brief brings the web kit level with it, so boards instance a kit piece instead of drawing a local copy
**Board:** — (not drawn yet)
**Depends on:** the design system's current ComboBox (its open list), Callout, Thumbnail and Badge; the Spike 3 Omnibar Hit Row
**Related:** [S16-D9](S16-D9-omnibar-results.md) (the omnibar's results, drawn with a local copy of the card because this piece was missing); plan [`../prs/S16-52-omnibar-popup-list.md`](../prs/S16-52-omnibar-popup-list.md); kit README rows Popup, PopupList and ComboBox ([`macos/App/DesignSystem/README.md`](../../../../macos/App/DesignSystem/README.md)); [`docs/design-system-layers.md`](../../../design-system-layers.md) "Claude Design / web kit (parity)"
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

### This brief changes the kit, not a view

Work in the **design-system project itself** (the main project the boards pull from), not on an app board. Add a component folder `components/PopupList/` beside `components/ComboBox/`, refactor the ComboBox's open list to compose it, and add the pieces to the component sheet. Everything already drawn must look exactly as it does today: this is the same card, row and line the ComboBox's open list draws, pulled out so other popups can instance them. A popup list is not a page or a pane, so it has no Regular and Wide arrangement (see §4.1): draw its states on the component sheet.

When the kit is published, every board that pulls a fresh copy (S16-D9 first) gets PopupList in its fetched kit.

---

## 1. Objective

The app has one floating list, the **popup list**: the list a combo box opens under its field, the citation format editor's `{` completion list at the caret, and, from S16-52, the omnibar's search results under the toolbar's search field. In the app it is one kit component (Swift `PVPopupListCard`, `PVPopupListRow`, `PVPopupListLine`). The web kit has no such component: its card and rows live inside ComboBox's open list, so a board that needs a popup list (the omnibar's results, S16-D9) has to draw a local copy.

This brief adds **PopupList** to the web kit: the card, the row shell, the line that stands in for rows, and the searching line, with the exact values the app uses. The ComboBox's open list is rebuilt from it with no visible change. It also renames the Omnibar Hit Row to **SearchHitRow** and makes it a component, as the app does in S16-52.

**What stays.** Every value the ComboBox's open list draws today; the ComboBox's field, its check-mark column and its empty-line copy; every token. No new color, radius, spacing or type token.

## 2. Domain facts

| Fact | Meaning for the board |
| --- | --- |
| A popup list | A list that floats under a field (or at a text caret) while the field keeps the keyboard. It is its own window in the app, so it is never clipped by the page |
| Its callers in the app | ComboBox (under its field, the field's width); the TextArea's completion (at the caret, 360 pt wide, 40 pt rows, up to 8 rows); the omnibar's results (under the search field, 640 pt wide, hanging from the field's right edge) |
| The field keeps the keys | ↑/↓, Home/End, Page Up/Down move one highlight; the pointer moves the same highlight; there is no separate hover state. Return belongs to the field. These are behavior notes for the sheet's captions, not drawn states |
| Shadow | In the app the window casts its own shadow, and the card adds none. On the web there is no window, so the kit's overlay elevation stands in for it on the web only |
| Disabled rows | A row can be disabled (greyed): the highlight never lands on it |
| Lines | When there are no rows, one line stands in for them: the caller's empty line, the searching line while a remote search runs, or the caller's failure line (a Callout). Its text starts where a row's label starts |

### 2.1 What this board is not

- Not an app view or a board of one: no toolbar, page or pane.
- Not a change to ComboBox's field, Select, ContextMenu or the menus. A context menu is a different popup (actions, not a list under a field).
- Not new tokens, a new card style or a rounded row highlight.
- Not the omnibar's results frames (S16-D9 draws those, and instances PopupList once this lands).
- Not the Back and Forward history menu's board.

---

## 3. Implementation gate

| This brief ships (web kit) | Not this brief |
| --- | --- |
| KP-1 – KP-7 | The omnibar's results (S16-D9); the history menu's board; any Swift change beyond S16-52's (the app's kit already has the card, row and line) |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| KP-1 | **PopupList card** (`components/PopupList/PopupListCard`). Card surface fill (`surface-card`), a 1 pt default border drawn inside the edge (`border-default`), the medium radius (`radius-md`, 5 pt), 4 pt of air above the first row and below the last (`space-2`), no inset at the sides. Its content scrolls when taller than the list's maximum height; the highlighted row is kept in view. Shadow: the overlay elevation, marked in the component's notes as the web's stand-in for the app window's own shadow. Props: the rows or line inside, a maximum height (ComboBox: 288 pt; the omnibar: 420 pt), a width (default: the anchor field's) |
| KP-2 | **PopupList row** (`PopupListRow`). The row's shell only: full card width; active → the selected-surface fill (`surface-selected`) across the full width, square-edged, the card clipping the first and last rows at its corners; disabled → the whole row at 42 % opacity, never active; hover makes an enabled row active. The caller draws the row's content and its own padding inside it. Props: `active`, `selected` (for assistive tech), `disabled`, children |
| KP-3 | **PopupList line** (`PopupListLine`). Stands in for rows: its content starts `gutter` + 12 pt from the card's left edge (`space-5`), ends 12 pt from its right, with 8 pt above and below (`space-4`), or vertically centered in a fixed minimum height when one is given (the completion list's 40 pt). Props: `gutter` (default 0), `minHeight`, children |
| KP-4 | **Searching line** (`PopupListSearchingLine`). A PopupList line holding a small spinner and `Searching…` in body-small (`text-body-small`) muted ink (`text-muted`), 6 pt between them (`space-3`). Props: `gutter`. Draw it at gutter 0 (text 12 pt in) and at gutter 22 (the ComboBox's, text 34 pt in) |
| KP-5 | **ComboBox composes PopupList.** The ComboBox's open list is rebuilt from KP-1 – KP-4: the card, a PopupList row per option holding the ComboBox's own row (a 22 pt check-mark column, 12 pt to the label, 12 pt trailing, 6 pt top and bottom), its empty line (body-small italic, muted) in a PopupList line at gutter 22, and the searching line at gutter 22. Nothing about the open list looks different; put the old and the new side by side once to check, then delete the old |
| KP-6 | **SearchHitRow** (`components/SearchHitRow/`), the Spike 3 Omnibar Hit Row moved from recipes and renamed, unchanged: a 40 pt lead (Thumbnail or mark), the title (body-small semibold, one line) with a subtle neutral Badge for the kind, a muted caption secondary line with a mono micro ref (accent when the query was that exact ref, faint otherwise), an optional faint caption match line; its own inset 9 pt at the sides, 7 pt top and bottom. It draws inside a PopupList row; the omnibar's results and Promote's record search both use it. Delete the old recipe once nothing references it |
| KP-7 | **Component sheet.** Add a PopupList section showing every state in §5 with a caption of the keys (↑/↓, Home/End, ⌘↑/⌘↓, Page Up/Down move the highlight; the pointer moves the same highlight; Return is the field's). Note on the section: "One floating list for a field: ComboBox, TextArea completion, the omnibar's results. A menu of actions is ContextMenu, not this" |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| PopupList (component, not a view) | Drawn on the component sheet at its callers' widths | The same: a popup's width comes from its field (or its caller's fixed width), never from the pane | Nothing; KP-W1 |

| ID | Requirement |
| --- | --- |
| KP-W1 | **Wide.** A popup list does not change with the pane's width class: its width is its field's or its caller's (ComboBox: the field; completion: 360 pt; omnibar: 640 pt, narrowed to stay 16 pt inside the content column). No Wide frame is drawn |

---

## 5. Suggested frames

All frames are on the component sheet, not a pane. Draw each popup under a field instance (or a text caret for S5), at the widths given.

| Frame | Requirement | Draw |
| --- | --- | --- |
| S1 | KP-1, KP-2 | A 320 pt ComboBox field with its open list: six options, the third active, the fifth disabled, the first checked (the committed value) |
| S2 | KP-1 | The same list with fifteen options, scrolled at its 288 pt maximum, the active row the last fully shown |
| S3 | KP-3, KP-4 | Three 320 pt cards stacked: the searching line at gutter 22, the ComboBox's empty line (`No match for “zzz”`) at gutter 22, and a Callout (danger, `Catalog closed.`) in a line at gutter 0 |
| S4 | KP-5 | Old and new ComboBox open lists side by side, identical; caption "rebuilt from PopupList". Delete the old after checking |
| S5 | KP-1 – KP-3 | The TextArea completion at a caret: 360 pt wide, four 40 pt rows, the second active; and the same with no rows, its empty line in a 40 pt line |
| S6 | KP-1, KP-2, KP-6 | A 640 pt PopupList hanging from the right edge of a 420 pt search field: four SearchHitRows (a Source with its exact ref in accent, a Person with a photo likeness, a Place, a Source with a match line), the second active; and the searching line at gutter 0 under the same field |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| PopupList card | Component | New | web `components/PopupList/`; Swift `macos/App/DesignSystem/Components/PopupList/PVPopupList.swift` `PVPopupListCard` | KP-1. Second call site: already three (ComboBox, TextArea completion, the omnibar's results). Not Card: a popup card has no inner padding at its sides and a full-bleed highlight |
| PopupList row | Component | New | web `components/PopupList/`; Swift `PVPopupListRow` | KP-2. Shell only; the caller's content goes inside. Not a Button, not a ContextMenu item |
| PopupList line | Component | New | web `components/PopupList/`; Swift `PVPopupListLine` | KP-3. The empty, searching or failure line |
| Searching line | Component | New | web `components/PopupList/`; Swift `PVPopupListSearchingLine` (S16-52) | KP-4. Today drawn inside ComboBox |
| ComboBox open list | Component | Extend | web `components/ComboBox/`; Swift `macos/App/DesignSystem/Components/ComboBox/PVComboBox.swift` | KP-5. Composes PopupList; no visible change |
| SearchHitRow | Component | Rethink | web `recipes/OmnibarHitRow/` → `components/SearchHitRow/`; Swift `PVSearchHitRow` (S16-52) | KP-6. Moved and renamed; content and inset unchanged |
| Callout | Component | Ship | web `components/Callout/`; Swift `PVCallout` | The failure line's content (S3) |
| Thumbnail, Badge | Component | Ship | web `components/Thumbnail/`, `components/Badge/` | Inside SearchHitRow |

**Non-goals.** No new token, no second card style, no rounded row highlight, no change to ContextMenu, Select or the ComboBox's field, no Wide frame, no app board.

---

## 7. Handoff

When the kit change is agreed and published: record the design-system project's version or turn on the **Board** line here and in [`README.md`](README.md); tell the S16-D9 board to pull a fresh kit and swap its local card and rows for PopupList and SearchHitRow instances, with no visible change. The Swift side needs no PR (S16-51 shipped it; S16-52 adds `PVPopupListSearchingLine` and renames the row). When S16-52 lands, this brief moves to the spike's design archive with S16-D9.
