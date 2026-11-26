# S16-D19 — Family: when and where a couple married

**Kind:** Claude Design board (**enhancement** of S16-D18's agreed Family frames, which extend S13-D3: a marriage line is added between couples; nothing else is redrawn)
**Spike:** Provenencia Spike 16 (odds and ends), batch 6, slice 6l
**View:** the Person page's Family section: the parent blocks (left column) and the person's partners (right column)
**Implements later as:** PR **S16-82** (Family shows a couple's marriage)
**Board:** — (not drawn yet). Draw on [Claude Design — Person Detail](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ), page *Person Detail - Family*, as a new turn "S16-D19 · Marriages", after the agreed "S16-D18 · Parents once"
**Depends on:** S16-D18 agreed (its frames are this board's starting point); S13-D3 Family (shipped in S13-12, [#676](https://github.com/Jake-Robins-Studios/provenencia/pull/676))
**Related:** S16-D18 ([brief](S16-D18-family-parents-once.md)); working rule "(Batch 6) Family shows a couple's marriage from its events" in [`../deployment-plan.md`](../deployment-plan.md#working-rules); scope entry [S16-82](../deployment-plan.md#s16-82--family-shows-a-couples-marriage); [`macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide)
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

This brief is pasted **after S16-D18 is agreed**. Draw on the Person Detail board as a new turn "S16-D19 · Marriages", starting from the agreed S16-D18 frames (Regular and Wide), with the line style, missing-parent mark, captions and spoken text S16-D18 chose. Add a marriage line for each married couple. Do not redraw the parent blocks' order, the siblings, the missing-parent marks, the children's lines, the captions or the Show more rows; move tiles and lines only as far as the marriage line needs room, and say under each frame what moved.

**Some calls are the user's to make on this board.** Where a requirement says **Draw options**, draw each option as its own frame, side by side and labelled, on the same family, so the user can compare them and pick. Say which one you recommend and why, in one line under the frames. Do not pick silently.

---

## 1. Objective

Family shows who is married to whom, but not when or where. The researcher wants a couple's marriage date and place on the page whenever the project records a marriage. It shows for two couples: **the person's parents** (two parents paired in a set, stacked in the left column) and **the person and each partner** (the person's tile in the left column, each partner in the right column, joined by the bus).

The marriage line is **information, not a control**: it opens nothing and takes no Tab stop. The marriage is already reachable from the person's Timeline, which opens it. What stays: everything S16-D18 agreed. The marriage line does not change who is joined to whom.

---

## 2. Domain facts

| Fact | What it means on this board |
| --- | --- |
| A marriage | A marriage event in the project with both people as its subjects. It has a date (maybe none, maybe "abt 1841" or "bet 1840 and 1842"), a place (maybe none, maybe several), and its own Event page. |
| Spouses without a marriage | Two people can be linked as spouses or partners with no marriage event (a relationship recorded directly, or a couple known only through a child). They show **no** marriage line: being partners is not being married, and no date is invented. |
| More than one marriage | A couple can have two marriage events: a remarriage, or two records the app has not merged. Each is a line of its own, earliest first, undated last. |
| Life lines | A person tile already shows its life as lines: "b. 3 Jul 1817 · Bremen", "d. 1851". A marriage line is the same kind of line with the event type's abbreviation, "m.": the same date and place words, the same muted place, cut at the tail. A tile line shows one place and no "+N" count, and so does a marriage line. A line with no date shows the place alone, with no dot; one with no place shows the date alone. |
| A parent set | Two parents stacked one above the other in a block (S16-D18). Only a set of two can carry a marriage; a one-parent set has no couple. A block of overlapping sets (Heinrich with Anna, Heinrich with Katharina) has two couples, each with its own marriage, and Heinrich and Katharina are not next to each other (Anna is between them). |
| Partners | Each partner tile in the right column, with their children under them; the bus joins the person's tile to every partner. A person can have several partners, each with their own marriages. |
| Room | The left column's lines sit in a 20 pt margin; the gutter between the columns is 48 pt at Regular and 96 pt at Wide. Neither holds text. A tile has a fixed height for two life lines today. |

### 2.1 What this board is not

- Divorce, separation, banns, licences or any event other than a marriage. (A later union pattern would show the same way, worded by its own type.)
- Opening the marriage from Family; Family's marriage line is not a link (the Timeline opens it).
- Marriages of siblings or children: only the person's own partners and the parents' couple.
- A marriage's Sources, a provenance sheet, ages at marriage, or adding a marriage from Family.

---

## 3. Implementation gate

| S16-82 ships | Not S16-82 |
| --- | --- |
| FM-1 – FM-7, FM-W1 | Any event but a marriage; opening the marriage from Family; siblings' or children's marriages; editing from Family |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| FM-1 | A couple with a marriage shows one **marriage line** per marriage: the event type's abbreviation, then the marriage's date and place, worded as a tile's life lines are ("m. 12 Jun 1841 · Hamburg"). A couple with no marriage shows nothing new. |
| FM-2 | **Parents.** **Draw options** on frame 1: **(A) between the tiles:** the gap between the two parents of a pair widens to hold the line, centered on the gap, so it reads as belonging to both; **(C) inside a tile:** the line is a third life line inside the lower parent's tile, which grows to hold it. Frame 4 shows each option with a couple that is not adjacent (Heinrich and Katharina, Anna between them): in A, say how the line names or reaches its couple; in C, the line sits in the lower parent of the couple (Katharina's tile). **In a block with more than one couple, a marriage line names the other spouse**, drawn and spoken ("m. abt 1816 · Kiel, with Heinrich Weber" or a better look the board finds), in either option, so a line never depends on its position to make sense. A block with one couple does not name the spouse. |
| FM-3 | **The person and a partner.** **Draw options** on frame 1: **(B) over the partner's group:** a line at the top of the partner's group, above the partner's tile, in the right column; **(C) inside the partner's tile:** a third life line, the tile growing to hold it. With several partners, each line belongs to its own partner. Not on the bus or in the gutter: there is no room for text there. Where FM-2 and FM-3 can share one look, prefer it. |
| FM-4 | **Wording.** The leading word comes from the marriage's event type, not from Family. **Draw options** on frame 1: **(A)** the type's abbreviation, as "b." and "d." do: "m. 12 Jun 1841 · Hamburg"; **(B)** the type's word: "Married 12 Jun 1841 · Hamburg". A marriage with neither a date nor a place shows the word alone ("m."), since the marriage itself is recorded (frame 2): a line built from an event that exists is kept with both halves missing, where a missing birth or death is left out as today. |
| FM-5 | **Two marriages of one couple** (frame 3): both lines, earliest first, each its own line; an undated one last. |
| FM-6 | **Spoken.** The line is not a Tab stop. Inside a tile (option C) it is read with the tile, as its life lines are: "Partner, Maria Schulz, born 1819, married 12 Jun 1841, Hamburg". Standing alone (options A, B) it is one VoiceOver element that names its couple: "Johann Weber and Maria Schulz, married 12 Jun 1841, Hamburg", read in the column's order just after the couple's second person. A missing half is left out as in life lines ("married in Altona"); with both missing, the word alone ("…, married"). A line that names the other spouse (FM-2) says it after the word: "married Heinrich Weber, abt 1816, Kiel". |
| FM-7 | A line goes with its tiles: when a fold hides one person of a couple, the couple's marriage line is hidden too, and Show more reveals it with the tile. |
| FM-W1 | At Wide the marriage lines sit where they sit at Regular; the wider columns give the place more room before it is cut. Nothing moves between widths. |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Person page, Family section | S16-D18's two columns, 48 pt gutter, with marriage lines between or inside the couples | The same two columns with a 96 pt gutter; marriage lines in the same places | Nothing; the place is cut later (FM-W1) |

---

## 5. Suggested frames

Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440); the others at Regular only. Start from S16-D18's frame 1a / 1b family: parents Heinrich and Anna Weber, Johann Weber (b. 1817) the person, his siblings, and on the right Maria Schulz with her children, Sophie Brandt with Otto, Paul with no other parent.

| Frame | Requirement | Draw |
| --- | --- | --- |
| 1-A/B | FM-1 – FM-3 | Parents option A with partners option B, in FM-4 A's wording. Heinrich and Anna married 3 May 1812 in Altona; Johann and Maria Schulz married 12 Jun 1841 in Hamburg; Johann and Sophie Brandt have **no** marriage (partners through Otto only) |
| 1-C | FM-1 – FM-3 | The same family with option C in both columns |
| 1-W | FM-4 | Your recommended frame 1 in FM-4 B's wording ("Married …"), beside it |
| 1a / 1b | FM-1 – FM-4, FM-6, FM-W1 | The recommended options at Regular and Wide, with FM-6's spoken text noted beside each marriage line |
| 2 | FM-4 | Partial marriages, in the recommended options: Heinrich and Anna's has a place and no date ("m. Altona"); Johann and Maria's has a date and no place ("m. 12 Jun 1841"); Johann and Sophie are given a marriage with neither ("m.") |
| 3 | FM-5 | Johann and Maria with two marriages: 12 Jun 1841 in Hamburg, and an undated one in Lübeck, drawn second |
| 4-A, 4-C | FM-2 | S16-D18's overlapping sets (Heinrich with Anna, Heinrich with Katharina): Heinrich and Anna married 3 May 1812 in Altona, Heinrich and Katharina married abt 1816 in Kiel; one frame per FM-2 option |
| 5 | FM-7 | Frame 1a with the partners folded behind Show more: the hidden partners' marriage lines hidden with them |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Life line | Platform type | Extend | `macos/App/Platform/PersonLifeDisplay.swift` `PersonLifeDisplay.LifeLine` | The marriage line **is** a life line: abbreviation, date, place and spoken label, plus one optional part, the other spouse (FM-2). Its builder takes an event's worded date and places, so b., d. and m. lines are built and spoken one way (the `L10n.Conclusions.a11yLifeLine*` formats). A line from an event that exists is kept with both halves missing (FM-4); a missing birth or death is still left out. No new line type |
| Event date and place wording | Feature helper | Ship | `macos/App/Features/Conclusions/EventsListView.swift` `EventSecondaryDisplay.content` | Words the marriage's date and places as the Events list and Timeline do |
| Date · place line | Component | Ship | `macos/App/DesignSystem/Components/DatePlaceLine/PVDatePlaceLine.swift` | Draws the line, `leading` the abbreviation, `missing: .omitted`, `extraCount` for the marriage's own extra places only |
| Life-line words | — | Extend | `macos/App/Platform/L10n.swift`, beside the seeded event type terms (`L10n.PropertyTerm`) | **One table** of the words a life line leads with, keyed by event type: the abbreviation ("b.", "d.", "m."), the display word ("Born", "Married") and the inline spoken word ("born", "married"). Birth and death move into it from `personBornAbbr`, `personDiedAbbr` and the `a11yBorn*` / `a11yDied*` words, so `PersonLifeDisplay` reads every line's words from one place. A Go-parity test beside `TestSwiftVocabularyMatchesGo` requires an entry for every event type `kinship`'s patterns pair with the spouse term, so a new union pattern fails a test until it has words. Family has no marriage string of its own |
| Person tile | Recipe | Extend only for option C | `macos/App/DesignSystem/Recipes/PersonCard/PVPersonCard.swift` | Option C passes more life lines than the two a tile shows today; each line is keyed by its position, not its abbreviation (two marriages share "m."). The line is text, not a button, so the tile keeps one target |
| Tile card | Component | Extend only for option C | `macos/App/DesignSystem/Components/TileCard/PVTileCard.swift` `PVTileCardSize` | A regular tile is a fixed 92 pt with two lines today. Option C makes a tile's height follow its line count, a change to the kit component every tile uses: the board draws a three- and a four-line tile |
| Family layout and content | Snowflake | Extend | `macos/App/Features/Conclusions/PersonFamilyLayout.swift`, `PersonFamilyContent.swift`, `PersonFamilySection.swift` | For options A and B, the line is a placed entry in the group that holds its couple, beside the tiles and Show more rows, in reading order; for C it is part of the tile, and the layout gives each tile its own height (today one shared tile height). The engine finds the marriages; Swift does not look for events |
| Copy | — | Extend | `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings` | The marriage words, in the life-line words table; for options A and B one couple format ("%1$@ and %2$@") for the standalone line's spoken label |

**Non-goals.** No new kit primitive, no new tile, no link, no new color or stroke token. No event chip, Badge or Callout for a marriage. No marriage for a couple without a marriage event.

---

## 7. Handoff

When the board is agreed: record the frames and the chosen FM-2, FM-3 and FM-4 options on the **Board** line here, in [`README.md`](README.md) and on S16-82's map row; strike the options not chosen. The S16-82 plan (`prs/S16-82-family-marriages.md`, [`plan-pr`](../../../../.agents/skills/plan-pr/SKILL.md)) copies FM-1 – FM-7 and FM-W1 into its Scope and the inventory into its design. When S16-82 lands, the brief moves to the spike's design archive.
