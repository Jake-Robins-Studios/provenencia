# S16-D13 — The Persons, Events and Places lists on the native list

**Kind:** Claude Design board (**rethink** of the three Conclusion list pages: header, list body and row, replacing their frames)
**Spike:** Provenencia Spike 16 (odds and ends), batch 6
**View:** the Persons, Events and Places list pages (one shared page view, `ConclusionListPage`)
**Implements later as:** PR **S16-67** (The Persons, Events and Places lists are native lists)
**Board:** agreed 2026-11-23: [Persons List](https://claude.ai/artifact/MQtjRymfDNraEx9roK69q4), page "Persons List" (L1a, L1b, L2 light and dark, L3a/L3b Events and Places, L4, L5a/L5b, L6a/L6b, L7a/L7b). The board decides: the **plain** selection style (full-width bar); **separators** shown, the system hairlines tinted `borderSubtle`; **no hover**; **no focus ring** around the list; the trailing **chevron dropped**; rows and the list area on `surfaceCard` (hidden content background, `listRowBackground`), the header on `surfacePage` above its `PVDivider`. CL-W1: the user picked **(a)**: at Wide the title column takes the extra width, the updated column and the ref stay at the trailing edge on the 56 pt gutter; (b) dropped, so L1b, L3b, L5b and L7b are drawn once. Proven in S16-67, not promised by the board: the board insets the separators to the page gutter on **both** sides, but § 2.1 offers only a leading inset (if the trailing inset is not available, the separator runs to the row's trailing edge); the iron selection in dark appearance (drawn at iron 500 as a guess); the empty state's mark and the failure message are stand-ins for today's strings
**Depends on:** —
**Related:** a code spike on branch `spike/persons-native-list` (2026-11-23, local) that drew the Persons rows in SwiftUI's `List`; the closed PR #951 (S16-65) and its ship log, which show why the hand-built list's keyboard is being replaced; the list pages' header (`VocabularyHeader` on Source types, Metadata and Properties); [`macos-client-patterns.md` § 9](../../../../macos-client-patterns.md#9-window-widths-regular-and-wide); kit README "The table tradeoff" (`macos/App/DesignSystem/README.md`)
**Rules this brief bends:** § 9 rule 3 (a list with nothing more to show keeps a maximum width at Wide): these three lists fill the whole pane at every width (user, 2026-11-23, to judge on this board). The Sources and Source types lists keep `pvListBand`.
**Design system layers:** [`docs/design-system-layers.md`](../../../../design-system-layers.md)
**Skill:** [`add-design-brief`](../../../../../.agents/skills/add-design-brief/SKILL.md); [`add-ui-component`](../../../../../.agents/skills/add-ui-component/SKILL.md); [`add-localized-string`](../../../../../.agents/skills/add-localized-string/SKILL.md)

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

### This brief is a rethink

Replace the Persons, Events and Places list frames. Today each is a section header and a rounded card of rows inside the content column, with page gutters around it and the whole page scrolling. The new frames draw the list pages' header across the top of the pane and, below it, a list that fills the rest of the pane, edge to edge, at every width. Do not keep the card-in-a-column layout as a before/after.

---

## 1. Objective

The Persons, Events and Places pages each list the catalog's records of one kind: tens to 16,000 rows. Today the list is a hand-built column of buttons, and its keyboard is our own code, which proved unreliable (PR #951, closed). The list moves onto the **native macOS list**: SwiftUI's `List`, an `NSTableView` underneath, so selection, scrolling at any size and most of the keyboard come from the platform.

This board **redesigns the three pages within what the native list can and cannot draw** (§ 2.1), so the build matches the board and nothing on it needs a hand-built list again. Three things change on purpose (user, 2026-11-23):

1. **A header that spans the content pane.** The page's title and count sit across the full width of the pane, above the list, as the Source types, Metadata and Properties pages already draw theirs.
2. **Click selects, double-click opens.** A single click selects a row and the system shows it selected, so the list visibly responds. Double-click or Return opens the record's page. Today a single click opens it.
3. **The list fills the pane.** The list runs edge to edge across the pane under the header, down to the pane's bottom, at every width. No inert margin sits beside it: a click anywhere in the list area lands in the list.

**What stays.** What a row says (§ 2). The order (the engine sorts). The empty, loading and failure states' meaning and copy. Every row opens the same page as today.

## 2. Domain facts

| Fact | Meaning for the board |
| --- | --- |
| Three kinds, one page | Persons, Events and Places draw through one page view with the same row shape; draw Persons in full and show Events and Places rows in their own frames (their titles and secondary lines differ) |
| Persons row | Thumbnail (44 pt portrait, or the Person mark), the name as the title (one line; a +N badge for further kept names), the life line under it (birth and death as today, with a +N badge for further kept places; **empty when nothing is recorded**), the updated column (`2 days ago`), the ref `PER-7K2QX` in mono |
| Events row | Event mark or picture, the event's title, the secondary line of its date, place and further places as today, the updated column, ref `EVT-…` |
| Places row | Place mark or picture, the place's name, the chain of enclosing places in **italic** (`West Riding, Yorkshire, England`; **empty for a place with no parents**), the updated column, ref `PLC-…` |
| Row height | Fixed by the 44 pt thumbnail and the row's 11 pt vertical padding (66 pt). A row with an empty secondary line keeps that height, its title centered on the thumbnail |
| Size | Tens to 16,000 rows. The list builds rows lazily; nothing on the board may need every row measured (no column sized to its widest row) |
| Count line | `1,204 persons`, `86 events · by date`, `412 places · by name`; during a reload, the count line reads `1,204 persons · refreshing` (the app's existing strings) |
| Opening a record | Double-click a row, or select it and press Return: that record's page opens. Back returns to the list with the row it opened selected and in view |
| Keyboard | The platform's: ↑/↓ move the selection, Page Up/Down scroll by a screen. The app adds Home and End, which **scroll** to the first and last row without changing the selection, as in Finder, because SwiftUI's `List` does not pass them through. The list takes keyboard focus when the page opens, so these keys work without a click or Tab (S16-67 claims it on the list's first appearance). Type-to-select, ⌥↑/⌥↓ and VoiceOver's table reading are **expected** of the native list and proven in S16-67, not promised by this board |

### 2.1 What the native list can and cannot draw

The board stays inside this table. Where it says **the board decides**, pick one and say which in the frame's caption.

| Part | Native list | For the board |
| --- | --- | --- |
| Row content | Any kit views | Free, at the fixed row height (§ 2) |
| Row background | One fill per row (`listRowBackground`); the list's own white can be removed (`scrollContentBackground(.hidden)`), as the kit's reorderable list (`PVReorderableList`) already does | Free in kit colors (recommendation: one surface, `surfaceCard`, for rows and the list area). Whether a row background leaves the system selection visible is proven in S16-67; draw the selection as visible |
| Row insets | Set per row (`listRowInsets`) | 11 pt vertical (the list's comfortable density). Horizontal: the page gutter on both sides (32 pt at Regular, 56 pt at Wide, `gutterPage` / `gutterPageWide`), so the thumbnail lines up with the header's title and the ref's trailing edge with the count line's, and the ref stays clear of the scroll bar |
| Separators | System hairlines between rows: shown or hidden, tinted, inset from the leading edge | **The board decides**: tinted `borderSubtle` system separators, or none |
| **Selection** | **Drawn by the system**, in the researcher's **own system accent color** (System Settings → Appearance); the app's iron accent only when that setting is Multicolor (user, 2026-11-23: accepted). Grey when the list or window is not focused. Its shape is the system's; it cannot be recolored | Draw it in a system blue and, in one crop, in iron (Multicolor). **The board decides** between the plain style (a full-width bar flush to the list's edges) and the inset style (a rounded bar inset from the list's sides). On a focused selection, the row's title, secondary line, updated column and ref switch to the system's on-selection ink (the platform marks the row's background prominence; `PVList` reads it once): draw them white on blue in light and dark appearance; the thumbnail and badges keep their colors. How the iron (Multicolor) selection reads in dark appearance is proven in S16-67 |
| Hover | None built in. A tint can be drawn inside a row's content only, under the selection | **The board decides**: no hover (as Finder and Mail), or a content-only tint |
| Focus | The selection's accent (focused) vs grey (unfocused) shows focus. The system may also ring the whole list; it can be turned off | Recommendation: no ring around the list. Draw both the focused and the unfocused selection |
| Scrolling | The list is its own scroll view. Its scroll bar sits at the list's right edge, overlaying the rows while scrolling | The header does not scroll with the rows. The rows' trailing inset leaves the ref clear of the scroll bar |
| Context menu, sections | Supported | Not on this board |
| Animation | Rows animate in and out | Not drawn; the build turns it off for a reload |

### 2.2 What this board is not

- Not the Sources list, the Source types list, Metadata or Properties: they keep their frames (whether the Sources list follows is decided after this ships).
- Not the record pages the rows open, and not the page keys on other pages.
- Not new row content: no new columns, filters, sort controls, search field or New button.
- Not a right-click menu on rows.

---

## 3. Implementation gate

| S16-67 ships | Not S16-67 |
| --- | --- |
| CL-1 – CL-10, CL-W1, CL-W2 | Context menus, filters, sorting, a search field, the Sources list, the tables |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| CL-1 | **Header.** The list pages' header, as Source types, Metadata and Properties draw it: the kind's title (`Persons`) in the display h1, the count line in mono micro at the trailing end, the page gutter as its inset, and a full-width hairline (`PVDivider`) under it across the pane. No description line and no Add button on these three pages |
| CL-2 | **The list fills the pane.** Under the header's hairline, the list runs from the pane's left edge to its right edge and down to the pane's bottom. No card border, no rounded corners, no gutter outside it |
| CL-3 | **Rows.** Left to right: the 44 pt thumbnail, the title (one line, truncated with an ellipsis) with its +N badge and the secondary line under it, the updated column at its fixed width, the mono ref. A row with no secondary line keeps its height, title centered. The row's leading inset is the page gutter, so the thumbnail aligns with the header's title; the trailing inset is the page gutter, so the ref's trailing edge aligns with the count line's (§ 2.1). **The board decides** whether the trailing chevron stays now that a click selects and a double-click opens; recommendation: drop it |
| CL-4 | **Selection.** A single click selects the row and the system draws its selection (§ 2.1), with the row's text in the system's on-selection ink. Selecting does not open the record. Draw: a row selected with the list focused (system blue), the same with the list unfocused (grey), the same in iron (Multicolor), and no selection |
| CL-5 | **Opening.** Double-click a row, or press Return with a row selected: the record's page opens. Caption on the CL-4 frame |
| CL-6 | **Arrival.** The list has keyboard focus. From the sidebar, nothing is selected and the list is at its top. On Back from a record, the row it was opened from is selected and in view. On Back after leaving the list another way (the sidebar, the omnibar) with a row selected, that row is selected and in view; with none, the list is at its top. Caption on L1a |
| CL-7 | **Loading.** First load, before rows arrive: the header with no count line, and skeleton rows filling the list area at row geometry and full width (the kit's list skeleton without its card), with the list's separators if the board keeps them |
| CL-8 | **Empty.** No records of the kind: the header with no count line, and the kit's EmptyState centered in the list area (each kind's existing mark, title and message) |
| CL-9 | **Failure.** The load failed: the header, and a danger Callout with today's message at the top of the list area, its leading edge on the rows' content edge, at the Callout's readable width |
| CL-10 | **Long content.** A 90-character Event title truncates with an ellipsis before the updated column; the updated column and the ref never move or truncate |
| CL-W1 | **Wide rows.** The header, its hairline and the list span the whole pane at Wide too, so the selection and the clickable row run edge to edge (§ 9 rule 3 is bent here, user 2026-11-23). **The board decides** the row content at Wide and draws both for the user to choose: (a) the title column takes the extra width, the updated column and the ref staying at the trailing edge; (b) the row content stops at 1600 pt and is centered in the full-width row; the header's content is capped and centered the same way, so its title and count line stay aligned with the thumbnail and the ref |
| CL-W2 | **Wide states.** The skeleton rows fill the width as the rows do (CL-W1's choice); the EmptyState stays centered in the list area; the failure Callout keeps its readable width, aligned as CL-9 says, or centered with the content under CL-W1 (b) |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Persons, Events and Places pages | Header across the pane; the list fills the pane under it | Header and list across the pane; the row content per CL-W1 (a) or (b) | Nothing moves between columns; the rows keep spanning the pane |

---

## 5. Suggested frames

Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440); the others as they say.

| Frame | Requirement | Draw |
| --- | --- | --- |
| L1a / L1b | CL-1 – CL-3, CL-6, CL-W1 | Persons, 1,204 rows, about 12 visible (Regular) or 19 (Wide), scrolled mid-list with the scroll bar showing, nothing selected, list focused; mixed portraits and marks, one row with a +2 name badge, one with no life line. L1b twice: CL-W1 (a) and (b) side by side. Caption on L1a: CL-6 |
| L2 | CL-4, CL-5 | Regular only: four crops of one Persons row with a +2 badge, in the selection style the board picks (plain or inset): selected and focused (system blue), selected and unfocused (grey), selected in iron (Multicolor), and the hover if the board picks one. Caption: double-click or Return opens |
| L3a / L3b | CL-3, CL-10 | Events rows (one with a 90-character title) and Places rows (italic place chains, one with none), stacked. L3b twice: under CL-W1 (a) and (b) |
| L4 | CL-1 | Regular only: the header with the count line in its refreshing form |
| L5a / L5b | CL-7, CL-W2 | The loading state. L5b twice: under CL-W1 (a) and (b) |
| L6a / L6b | CL-8, CL-W2 | The empty Persons page, Regular and Wide |
| L7a / L7b | CL-9, CL-W2 | The failure page, Regular and Wide; L7b twice: under CL-W1 (a) and (b) |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Browse list | Component | Rethink | `PVList` (`macos/App/DesignSystem/Components/List/PVList.swift`) | Stays the kit's browse list; its body becomes the native list (`List` with a selection), keeping its slots (thumbnail, title, secondary, detail column, ref). The native setup follows `PVReorderableList`'s (`listStyle(.plain)`, hidden content background, row insets). Draw within § 2.1 |
| List page header | Snowflake → kit | Extend | `VocabularyHeader` (`macos/App/Features/CatalogVocabulary/VocabularyChrome.swift`) | The header Source types, Metadata and Properties draw; these pages use it without its description and Add button. Not a SectionHeader |
| Thumbnail | Component | Ship | `CachedThumbnail` over `PVThumbnail`, the kind's mark as fallback | 44 pt |
| Title with +N | Component | Ship | `PVTitleText` | Unchanged; the on-selection ink on a selected row |
| Updated column | Recipe | Ship | `PVLastUpdated.detail`, `PVListDetailCell` | Fixed width (`PVLastUpdated.columnWidth`) |
| Selection | Platform | Ship (platform) | system | § 2.1; the row text takes the system's on-selection ink through `PVList`, no kit token |
| Loading rows | Component | Extend | `PVListSkeleton` | Without its card; rows fill the list area |
| Empty | Component | Ship | `PVEmptyState` (`glyph: .mark(kind)`) | Centered in the list area |
| Failure | Component | Ship | `PVCallout` (`.danger`) | Top of the list area |

**Non-goals.** No hand-built focus ring or selection drawing, no new kit primitive, no new color or token, no header controls, no context menu, no column the native list cannot size without measuring every row.

---

## 7. Handoff

When the board is agreed: record the board, its section and frames on the **Board** line here and in [`README.md`](../README.md), with each "the board decides" choice and the user's CL-W1 pick; the S16-67 plan copies CL-1 – CL-10, CL-W1 and CL-W2 into its Scope and the inventory into its Design, and proves the § 2 "expected" keyboard behaviors. When S16-67 lands, this brief moves to the spike's design archive.
