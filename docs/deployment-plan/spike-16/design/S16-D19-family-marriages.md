# S16-D19 — Family: when and where a couple married

**Kind:** Claude Design board (**enhancement** of S16-D18's agreed Family frames, which extend S13-D3: a marriage line is added between couples; nothing else is redrawn)
**Spike:** Provenencia Spike 16 (odds and ends), batch 6, slice 6l
**View:** the Person page's Family section: the parent blocks (left column) and the person's partners (right column)
**Implements later as:** PR **S16-82** (Family shows a couple's marriage)
**Board:** — (not drawn yet). Draw on [Claude Design — Person Detail](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ), page *Person Detail - Family*, as a new turn "S16-D19 · Marriages", after the agreed "S16-D18 · Parents once"
**Depends on:** S16-D18 agreed (its frames are this board's starting point); S13-D3 Family (shipped in S13-12, [#676](https://github.com/Jake-Robins-Studios/provenencia/pull/676))
**Related:** working rule "(Batch 6) Family shows a couple's marriage from its events" in [`../deployment-plan.md`](../deployment-plan.md#working-rules); scope entry [S16-82](../deployment-plan.md#s16-82--family-shows-a-couples-marriage); S16-D4's shared event date line ([archive](archive/S16-D4-event-date-line.md)); [`macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide)
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

Draw on the Person Detail board as a new turn "S16-D19 · Marriages", starting from the agreed S16-D18 frames (Regular and Wide), with the missing-parent mark, captions and spoken text S16-D18 chose. Add a marriage line between couples. Do not redraw the tiles, the parent blocks' order, the siblings, the missing-parent marks, the children's lines, the captions or the Show more rows; move lines and tiles only as far as the marriage line needs room.

**Some calls are the user's to make on this board.** Where a requirement says **Draw options**, draw each option as its own frame, side by side and labelled, on the same family, so the user can compare them and pick. Say which one you recommend and why, in one line under the frames. Do not pick silently.

---

## 1. Objective

Family shows who is married to whom, but not when or where. The researcher wants a couple's marriage date and place on the page, between the two people, whenever the project records a marriage. It shows for two couples: **the person's parents** (two parents paired in a set, stacked in the left column) and **the person and each partner** (the person's tile in the left column, each partner in the right column, joined by the bus).

What stays: everything S16-D18 agreed. The marriage line adds information; it does not change who is joined to whom.

---

## 2. Domain facts

| Fact | What it means on this board |
| --- | --- |
| A marriage | A marriage event in the project with both people as its subjects. It has a date (maybe none, maybe a range or "about"), a place (maybe none), and its own Event page. |
| Spouses without a marriage | Two people can be linked as spouses or partners with no marriage event (a relationship recorded directly, or a couple known only through a child). They show **no** marriage line: being partners is not being married, and no date is invented. The bus and the pairing are unchanged. |
| More than one marriage | A couple can have two marriage events: a remarriage, or two records the app has not merged. Each is a marriage of its own. Earliest first. |
| The date line | Every event date on the app is worded one way (S16-D4): "12 Jun 1841", "abt 1841", "bet 1840 and 1842", "as of 1845". This board draws those words; it does not word dates. |
| The date · place line | The kit's Date Place Line draws "date · place" after a leading abbreviation, as a tile's "b." and "d." lines do. A missing half is left out with its dot on a tile. |
| A parent set | Two parents stacked one above the other in a block (S16-D18). Only a set of two can carry a marriage; a one-parent set has no couple. A block with overlapping sets (Heinrich with Anna, Heinrich with Katharina) has two couples, each with its own marriage. |
| Partners | Each partner tile in the right column, with their children under them; the bus joins the person's tile to every partner. A person can have several partners, each with their own marriages. |
| Opening | An event line elsewhere opens its Event page. |

### 2.1 What this board is not

- Divorce, separation, banns, licences or any event other than a marriage. (A later union pattern would show the same way, with no new design.)
- Marriages of siblings or children: only the person's own partners and the parents' couple.
- A marriage's Sources, or a provenance sheet for it: the Event page has those.
- Adding a marriage from Family.
- Ages at marriage.

---

## 3. Implementation gate

| S16-82 ships | Not S16-82 |
| --- | --- |
| FM-1 – FM-7, FM-W1 | Any event but a marriage; siblings' or children's marriages; editing from Family |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| FM-1 | A couple with a marriage shows a **marriage line** between the two people: the marriage's date and place, worded as every event date and place is. A couple with no marriage shows nothing new. |
| FM-2 | **Parents.** The marriage line sits between the two parents of a set, tied to that pair. **Draw options** on frame 1: **(A)** in the gap between the two stacked tiles, which widens to hold it; **(B)** on the pair's own line in the left margin, beside the join between them; **(C)** as a line inside the second parent's tile, under their life lines. With overlapping sets (frame 4), each couple's line is tied to its own pair: draw how that reads when the pairs share a parent. |
| FM-3 | **The person and a partner.** The marriage line sits between the person and that partner. **Draw options** on frame 1: **(A)** on the bus, beside the horizontal that reaches the partner's tile; **(B)** as a line at the top of the partner's group, above the partner's tile; **(C)** as a line inside the partner's tile, under their life lines. With several partners, each line belongs visibly to its partner. Whichever option FM-2 and FM-3 pick, use one look for both couples where the geometry allows. |
| FM-4 | **Wording. Draw options** on frame 1: **(A)** the abbreviation "m." leading the date · place line, as "b." and "d." do: "m. 12 Jun 1841 · Hamburg"; **(B)** the word "Married": "Married 12 Jun 1841 · Hamburg". An undated marriage shows its place alone, an unplaced one its date alone; a marriage with neither shows "m." or "Married" alone (frame 2). |
| FM-5 | **Two marriages of one couple** (frame 3): **Draw options:** **(A)** both lines, earliest first; **(B)** the earliest, with a "+1" count after it, as the date · place line counts extra places. |
| FM-6 | The marriage line opens the marriage's Event page, by pointer and keyboard. It is one Tab stop, after the second person of its couple (the second parent; the partner's tile). Opening it and pressing Back returns to it, as Family's tiles do. |
| FM-7 | Spoken: the line is read as "Married, ⟨date⟩, ⟨place⟩" and its container names the couple ("Heinrich Weber and Anna Weber"; "Johann Weber and Maria Schulz"). A missing half is left out. |
| FM-W1 | At Wide the marriage lines sit where they sit at Regular; the wider columns give the place more room before it truncates. Nothing moves between widths. |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Person page, Family section | S16-D18's two columns, 48 pt gutter, with a marriage line between each couple | The same two columns with a 96 pt gutter; marriage lines in the same places | Nothing; the place truncates later (FM-W1) |

---

## 5. Suggested frames

Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440); the others at Regular only. Start from S16-D18's frame 1a / 1b family: parents Heinrich and Anna Weber, Johann Weber (b. 1817) the person, his siblings, and on the right Maria Schulz with her children, Sophie Brandt with Otto, Paul with no other parent.

| Frame | Requirement | Draw |
| --- | --- | --- |
| 1-A, 1-B, 1-C | FM-1 – FM-4 | One frame per FM-2 / FM-3 option (A with A, B with B, C with C), each in FM-4 A's wording, and one more of your recommended option in FM-4 B's wording. Heinrich and Anna married 3 May 1812 in Altona; Johann and Maria Schulz married 12 Jun 1841 in Hamburg; Johann and Sophie Brandt have **no** marriage (partners through Otto only) |
| 1a / 1b | FM-1 – FM-4, FM-7, FM-W1 | The recommended option at Regular and Wide, with FM-7's spoken text noted beside each marriage line |
| 2 | FM-4 | Partial marriages, in the recommended option: Heinrich and Anna's marriage has a place and no date ("m. Altona"); Johann and Maria's has a date and no place ("m. 12 Jun 1841"); Johann and Sophie's has neither ("m.") |
| 3-A, 3-B | FM-5 | Johann and Maria with two marriages: 12 Jun 1841 in Hamburg and abt 1845 in Lübeck, one frame per FM-5 option |
| 4 | FM-2 | S16-D18's overlapping sets (Heinrich with Anna, Heinrich with Katharina): Heinrich and Anna married 3 May 1812 in Altona, Heinrich and Katharina married 1822 in Kiel; each line tied to its own pair |
| 5 | FM-6 | Frame 1a with the Tab order numbered, the marriage lines among the tiles, and one marriage line with its focus ring |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Date · place line | Component | Ship | `macos/App/DesignSystem/Components/DatePlaceLine/PVDatePlaceLine.swift` | The marriage line's text: `leading` "m." (FM-4 A), the date and place already worded, `missing: .omitted`, `extraCount` for FM-5 B. No new text component |
| Link | Component | Ship | `macos/App/DesignSystem/Components/InkLink/` | Makes the marriage line open its Event (FM-6) with the kit's focus ring and hover, if the line stands on its own (FM-2 / FM-3 A, B). Not a Button, not a tile |
| Person tile | Recipe | Extend only for option C | `macos/App/DesignSystem/Recipes/PersonCard/PVPersonCard.swift` | Option C puts the marriage line inside the tile, which then gains an event line that opens something other than the tile: a tile with two targets. If C is chosen, the plan says how |
| Family diagram, layout and content | Snowflake | Extend | `macos/App/Features/Conclusions/PersonFamilySection.swift`, `PersonFamilyLayout.swift`, `PersonFamilyContent.swift` | The layout places the marriage lines and makes room for them; the content builds each couple's lines from what the engine sends. The engine finds the marriages; Swift does not look for events |
| Event date wording | — | Ship | `macos/App/Platform/DateRowDisplay.swift` and the shared event date line S16-42 shipped | The date words, as every event line has them |
| Copy | — | Extend | `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings` | "m." or "Married", the spoken "Married, …" and the couple's container label |

**Non-goals.** No new kit primitive, no new tile, no new color or stroke token. No event chip, Badge or Callout for a marriage. No marriage for a couple without a marriage event.

---

## 7. Handoff

When the board is agreed: record the frames and the chosen FM-2, FM-3, FM-4 and FM-5 options on the **Board** line here, in [`README.md`](README.md) and on S16-82's map row; strike the options not chosen. The S16-82 plan (`prs/S16-82-family-marriages.md`, [`plan-pr`](../../../../.agents/skills/plan-pr/SKILL.md)) copies FM-1 – FM-7 and FM-W1 into its Scope and the inventory into its design. When S16-82 lands, the brief moves to the spike's design archive.
