# S16-D8 — Properties: a search with no match, and a type with no Properties

**Kind:** Claude Design board (**enhancement** of the Properties page frames: two states are added to the property table's body)
**Spike:** Provenencia Spike 16 (odds and ends), batch 6
**View:** the Properties page: the body of its property table
**Implements later as:** PR **S16-48** (A Properties search with no match shows the kit's empty state)
**Board:** [agreed 2026-11-19](https://claude.ai/artifact/XRS4WQDZbaDa7jAzVKYQdc) — Claude Design "Properties View", page `S7-D2 Subject Fields`, section "S16-D8 · No match" (frames N1a, N1b, N2, N3a, N3b, N4). Copy, icons (`text-search`, `list-tree`), the `space6` top-aligned inset and the wrapping title as briefed; Clear search drawn at the small size (`sm`), like the toolbar's controls
**Depends on:** the agreed Properties page frames on the same board (type strip, the property table card with its search field and Add combo, the inspector card)
**Related:** the Sources list's no-filter-match state (`SourcesListView.listBody`, the precedent); plan [`../prs/S16-48-properties-no-match.md`](../prs/S16-48-properties-no-match.md); [`macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide)
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

### This brief is an enhancement

Draw as a new turn "S16-D8 · No match" on the board that holds the Properties page frames, starting from its agreed Regular and Wide frames. Do not redraw the type strip, the table's toolbar, the table's rows or the inspector card. Only the table card's body changes, in the two states named below.

---

## 1. Objective

The Properties page lists every Property in a table card, with a search field and, when a type is selected, an **Add a property to {Type}** combo box in the card's toolbar. When the search matches nothing, the table body today is two hand-built lines of text (`No property matches “zzz”` and `Clear the search, or create it as a user property`) with no button: it looks like no other empty list in the app, and the researcher clears the field by hand.

This board draws that state as the kit's **EmptyState**, compact, with a **Clear search** button, laid out as the Sources list draws its no-filter-match state. It also draws the one other way the table body is empty: a selected type with no Properties bound to it and an empty search (the Source type, after its two unlocked Properties, Mentions and Remark, are removed from it). Today that case reads `No properties match`, which is wrong: nothing was searched.

**What stays.** The type strip, the toolbar (search field, Add combo), the table's columns and rows, the inspector card and its states, the page header. A search that matches shows the table as today. There is no Create property button in either state (user, 2026-11-19); the page header's **New property** and ⌘N stay the way to create one.

## 2. Domain facts

| Fact | Meaning for the board |
| --- | --- |
| A Property | A field a record can hold (Name, Date, Remark). The table lists them, filtered by the selected type and the search |
| The type strip | **All properties** and one card per subject type (Person, Event, Place, Source, the bridges). Selecting a type shows only the Properties bound to it |
| Search | Matches a Property's label or key, ignoring accents, case, spaces and punctuation. A search of only spaces or punctuation is no search: every row shows |
| Bound Properties | Most bindings are locked by the product (a Person's Name, an Event's Date). The Source type's two, Mentions and Remark, are not: a researcher can remove both, and then the Source type has none |
| Search wins | With a type selected that has no Properties and a search typed, the table shows the no-match state: the search is what the researcher can change from the toolbar |
| The inspector | Shows the selected Property, or its own empty state. It does not change on this board |
| VoiceOver | The empty state's title, message and button are read in order; Clear search is a button labelled "Clear search" |

### 2.1 What this board is not

- Not the page's load failure (its danger Callout) or a catalog with no Properties at all (it cannot happen: the product's Properties cannot be deleted).
- Not a Create property button in the empty state (user, 2026-11-19: Clear search only).
- Not a change to the search field, the Add combo, the type strip or the inspector.
- Not the Sources list or any other list's empty state.

---

## 3. Implementation gate

| S16-48 ships | Not S16-48 |
| --- | --- |
| PN-1 – PN-6, PN-W1 | The load failure and an empty catalog (unchanged); Create property from the empty state (not planned, user 2026-11-19) |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| PN-1 | **No match.** All properties selected, search `zzz`: the table card keeps its toolbar (the search field reads `zzz`) and its body shows a compact EmptyState: the search-empty icon (`text.magnifyingglass`), the title `No property matches “zzz”`, the message `Try another word, or clear the search.`, and a secondary **Clear search** button. No column header, no rows. The same with a type selected (Person, search `zzz`), where the toolbar also shows the Add combo |
| PN-2 | **Clear search.** Pressing Clear search empties the field and the rows come back; focus moves to the search field. Draw the after state as a caption on the PN-1 frame; no frame of its own |
| PN-3 | **A type with no Properties.** The Source type selected with Mentions and Remark removed, search empty: the body shows a compact EmptyState: the Properties icon (`list.bullet.indent`, the sidebar's), the title `No properties on Source`, the message `Add one with the field above.`, and no button. The Add combo in the toolbar is the field the message points at |
| PN-4 | **Search wins.** The PN-3 type with `zzz` typed: the PN-1 state, not PN-3 |
| PN-5 | **Placement.** Each state is the kit's EmptyState box as it is (sunken fill, dashed border, its own inner padding); do not redraw it as plain text. It sits in the table card's body under the toolbar's divider, top-aligned, inset from the card's edges, as the Sources list sits its no-filter-match state under its toolbar. **The board decides** the inset; recommendation: 24 pt (`space6`) on every side. The card keeps its height; the space below the state is the card's surface |
| PN-6 | **A long query.** A 120-character query wraps the title inside the empty state's box, never truncated and never wider than the box; the message keeps its narrow measure |
| PN-W1 | **Wide.** The page keeps its agreed Wide arrangement: the table card fills the pane beside the fixed-width inspector. The EmptyState box spans the card body's width; its icon, title, message and button stay centered in it at their Regular sizes, the message at its narrow measure. Nothing moves between widths |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Properties page | As agreed: header, type strip, the table card beside the inspector card; PN-1 or PN-3 in the table card's body | As agreed: the table card takes the extra width; the state's box spans it, its content centered | Nothing; the inspector keeps its width |

---

## 5. Suggested frames

Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440); the others as they say.

| Frame | Requirement | Draw |
| --- | --- | --- |
| N1a / N1b | PN-1, PN-2, PN-5, PN-W1 | All properties selected, search `zzz`, no Property selected (the inspector's own empty state); the table body shows the no-match state. Caption: after Clear search, the rows and the focused field |
| N2 | PN-1 | Regular only: Person selected, search `zzz`, the Add combo `Add a property to Person` in the toolbar |
| N3a / N3b | PN-3, PN-5, PN-W1 | Source selected, its strip card reading `0 fields`, search empty; the table body shows the empty-type state |
| N4 | PN-4, PN-6 | Regular only: two table cards stacked: Source selected with `zzz` (the no-match state), and All properties with a 120-character query (the title wrapping) |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Empty state | Component | Extend | `macos/App/DesignSystem/Components/EmptyState/PVEmptyState.swift` `PVEmptyState` (`icon:verbatimTitle:…`; S16-48 adds the missing `glyph:verbatimTitle:…` init, no visual change) | Both states, compact. The title carries the query or the type's label, so it is a verbatim title |
| Clear search | Component | Ship | `PVButton`, `.secondary`, `.sm` (agreed board) | The no-match state's only action, as Clear filters on the Sources list. Not an IconButton, not a link |
| Icons | Component | Ship | `PVSymbol.searchEmpty`; `WorkspaceSection.properties.glyph` (`list.bullet.indent`) | Search-empty for no match; the Properties section's own glyph for an empty type, read from the section as the Metadata and Source types lists do. No type mark: the strip card above already shows it |
| Property table body | Snowflake | Extend | `macos/App/Features/Properties/PropertiesView.swift` `PropertiesContent.propertyTable` | Its hand-built no-match text goes; it shows the table, PN-1 or PN-3 |
| Table card and toolbar | Snowflake | Ship | `PropertiesContent.listCard`, `listToolbar` (`PVCard`, `PVInput`, `PVComboBox`) | Unchanged; the toolbar stays above both states |
| Sources no-match state | Precedent | Ship | `macos/App/Features/Sources/SourcesListView.swift` `listBody` | The shape to copy: compact EmptyState, one secondary button, top-aligned under the toolbar |

**Non-goals.** No new kit primitive, no Callout in place of the EmptyState, no Create property button, no second button, no illustration, no new icon, color or token, no change to the search field.

---

## 7. Handoff

When the board is agreed: record the turn and its frames on the **Board** line here, in [`README.md`](README.md) and on the plan's **Board** line, with any copy or inset the board changed; the plan copies PN-1 – PN-6 and PN-W1 into its Scope (already there), fixes its Strings and D-4 to the board, and moves from `Blocked` to `Planned`. When S16-48 lands, the brief moves to the spike's design archive.
