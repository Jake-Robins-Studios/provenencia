# S16-D18 — Family: each parent drawn once, and a sibling's missing parent shown as not recorded

**Kind:** Claude Design board (**enhancement** of the Spike 13 Person page board, S13-D3 Family, as S16-D2 extended it: the parent blocks and their lines are redrawn, everything else is kept)
**Spike:** Provenencia Spike 16 (odds and ends), batch 6, slice 6l
**View:** the Person page's Family section, left column (the origin: parents, then siblings with the person among them)
**Implements later as:** PR **S16-81** (Family draws each parent once)
**Board:** — (not drawn yet). Draw on [Claude Design — Person Detail](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ), page *Person Detail - Family*, as a new turn "S16-D18 · Parents once"
**Depends on:** the agreed S13-D3 Family frames (shipped in S13-12, [#676](https://github.com/Jake-Robins-Studios/provenencia/pull/676)) and S16-D2's folds on them (S16-07, landed #761)
**Related:** working rule "(Batch 6) The Family section draws each parent once" in [`../deployment-plan.md`](../deployment-plan.md#working-rules); scope entry [S16-81](../deployment-plan.md#s16-81--family-draws-each-parent-once); [`macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide)
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

Draw on the Person Detail board as a new turn "S16-D18 · Parents once", starting from the S13-D3 Family frames (11a full family, 11c conflicting parents) at Regular and Wide, with S16-D2's Show more rows. Redraw only the left column's parent blocks, their captions and the lines from the parents to the siblings. Do not redraw the person tiles, the siblings' order, the right column (partners and children), the bus from the person to the partners, the Show more rows or the section header.

**Some calls are the user's to make on this board.** Where a requirement says **Draw options**, draw each option as its own frame, side by side and labelled, on the same family, so the user can compare them and pick. Say which one you recommend and why, in one line under the frames. Do not pick silently.

---

## 1. Objective

Today a parent who belongs to two parent sets is drawn twice. A person whose parents are Heinrich and Anna, with a brother recorded as Anna's son only, shows Heinrich and Anna under **Parents**, then Anna again under **Other parent**, with the brother's line coming from the second Anna. The same happens when two records disagree about one parent: with Heinrich and Anna in one set and Heinrich and Katharina in another (frame 11c), Heinrich is drawn twice.

The app is right that the brother is not shown to be Heinrich's son, and that fact must stay visible. What changes: **every parent is one tile**, and each parent set becomes the lines that join a sibling to the parents they are recorded with. A sibling recorded with only some of the parents is visibly joined to those alone, and the page shows that the other parent is **not recorded** (not that the sibling is unrelated to them).

What stays: the tiles themselves, the two columns, the siblings' order (Go's: the children of every set first, then each set's other children, then siblings recorded with no shared parent), the person's raised tile among the siblings, the right column, the Show more rows, and the Wide arrangement S13-D3 agreed.

---

## 2. Domain facts

| Fact | What it means on this board |
| --- | --- |
| The person's parents | Everyone recorded as the person's parent. Usually one or two; three or more means the records disagree (two mothers recorded), or a step or adoptive parent was recorded as a parent. The app does not choose between them. |
| A parent set | A group of the person's parents that a child is recorded with together. Two parents are one set when they are recorded as partners or as the parents in one birth. The person is a child of every set. |
| A set inside another | A sibling recorded with only some of the person's parents (Christian, Anna's son only) makes a set of those parents ({Anna}) beside the full set ({Heinrich, Anna}). Its parents are all already drawn. |
| Overlapping sets | Two sets that share a parent but differ in another ({Heinrich, Anna} and {Heinrich, Katharina}): the records disagree about the mother. |
| Unrelated sets | Two sets that share no parent ({Heinrich, Anna} and {Georg, Katharina}): two records name entirely different parents. These stay apart as today. |
| A sibling recorded with no shared parent | Someone recorded as the person's sibling with no parent on file. Today they sit after the others, joined to the person by a bracket, not to any parent. Unchanged. |
| Not recorded ≠ not a parent | No record says Heinrich is Christian's father, and none says he is not. The page must not read as "Christian is Heinrich's stepson" or "half-brother". |
| Lines are not spoken | VoiceOver hears the tiles, not the lines. Today it hears no set membership at all: the siblings are one group, "This person and siblings". |
| The tile's role | A tile's role ("Parent", "Sibling") is spoken before its name; at the regular size it is not drawn. |
| Today's lines | Each set has its own vertical rail in the left margin (x 4–16pt, one per set); a short horizontal joins the rail to each parent tile of the set and to each sibling the set is the first set of. |

### 2.1 What this board is not

- The right column: a partner who is also another child's co-parent is already drawn once. Children recorded with only the person are unchanged.
- Choosing between conflicting parents, or marking one as preferred: that is a reconciliation feature, not drawing.
- New relationship kinds (step, adoptive, half). The page draws what is recorded.
- A way to add the missing link from Family (no "Add parent" action).
- Grandparents, or any parent's other children who are not the person's siblings.

---

## 3. Implementation gate

| S16-81 ships | Not S16-81 |
| --- | --- |
| FP-1 – FP-7, FP-W1 | Any Go, proto or data change; an action to record the missing parent; the right column |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| FP-1 | Each of the person's parents is one tile, one Tab stop and spoken once, however many sets they are in. |
| FP-2 | Sets that share a parent, directly or through another set, are drawn as one **block** of parent tiles. Within a block the parents keep Go's order of first appearance (the first set's parents, then each later set's new parents). Sets that share no parent stay separate blocks, as today. |
| FP-3 | Each sibling is joined only to the parents of their set(s). A sibling in the full set is joined to all of its parents, as today. A sibling recorded with only some of the block's parents (Christian) is joined to those, and is **not** joined to the others, without reading as unrelated to them. **Draw options** for how the missing link shows, on frame 1: **(A) dashed stub:** the partial set's line runs from the parents it has, and at each parent it lacks a short dashed stub ends short of the line, meaning "not recorded". **(B) join dots:** a small dot wherever a line joins a tile or another line, so a line that only crosses another (Christian's passing Heinrich's) has no dot and reads as no join. **(C) per-parent lines:** one vertical line per parent instead of one per set; each sibling's horizontal meets the lines of their recorded parents with a dot and crosses the others. **(D) a tile note:** lines as in (A) or (B), plus a muted line inside Christian's tile, e.g. "Anna's child; other parent not recorded". Options may combine; say which combination you recommend. |
| FP-4 | The person's own tile is joined to every set's parents (the person is a child of every set). A sibling in several sets (Friedrich, in both of frame 2's sets) is joined to every parent of those sets. |
| FP-5 | Captions. The first block is captioned **Parents** (**Parent** when it holds one tile). A later, unrelated block is captioned **Other parents** / **Other parent**, as today. **Draw options** for a block whose sets disagree (frame 2: three parents in one block): **(A)** the caption **Parents** only, the lines show the two sets; **(B)** **Parents** with a Badge beside it, e.g. "Records disagree"; **(C)** the block split by a thin rule or a subheading between the parents only one set has. |
| FP-6 | Spoken. Each parent is spoken once, as "Parent, ⟨name⟩". A sibling in the full set is spoken as today ("Sibling, ⟨name⟩"). **Draw options** (as a VoiceOver annotation on frame 1, no pixels) for a partial sibling: **(A)** names the parents they are recorded with: "Sibling, Christian Weber, child of Anna Weber"; **(B)** names what is missing: "Sibling, Christian Weber, other parent not recorded". If FP-3 option D is chosen, its tile text and this spoken text say the same thing. |
| FP-7 | Tab order runs each block's parents top to bottom, then the siblings, then the right column, as today; a parent is never reached twice. |
| FP-W1 | At Wide the left column keeps the arrangement S13-D3 agreed (the two columns, the wider gutter); the blocks, lines and marks are the same at both widths. Nothing moves between widths. |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Person page, Family section | Two columns as S13-D3 agreed: origin left (parent blocks, then siblings indented), the person's partners and children right | As S13-D3 agreed: the same two columns with the wider gutter | Nothing; this board redraws the parent blocks and their lines in the left column at both widths (FP-W1) |

---

## 5. Suggested frames

Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440); the others at Regular only. Every frame shows the whole Family section, both columns; the person is **Johann Weber, b. 1817**, with one partner, Maria Weber, and two children, so the right column is as in 11a.

| Frame | Requirement | Draw |
| --- | --- | --- |
| 0 | — | Today, for reference only (not to ship): 11a's family plus Christian Weber (b. 1823) recorded as Anna's son only, as the app draws it now: Heinrich and Anna under Parents, Anna again under Other parent, Christian's line from the second Anna |
| 1-A, 1-B, 1-C, 1-D | FP-1, FP-3, FP-4, FP-6 | **A set inside another**, one frame per FP-3 option. Parents Heinrich Weber and Anna Weber in one block. Siblings, in order: Margarethe (b. 1815), Johann (the person), Friedrich (b. 1820), Wilhelm (undated), all children of both; then Christian (b. 1823), Anna's son only. FP-6's spoken text noted beside Christian's tile |
| 1a / 1b | FP-1 – FP-4, FP-W1 | The recommended FP-3 option from frame 1, at Regular and Wide |
| 2-A, 2-B, 2-C | FP-2, FP-4, FP-5 | **Overlapping sets** (11c redrawn), one frame per FP-5 option, using the recommended FP-3 mark. Sets {Heinrich, Anna} and {Heinrich, Katharina}: one block of Heinrich, Anna, Katharina. Margarethe and Wilhelm are children of Heinrich and Anna; Friedrich of both sets; Christian of Heinrich and Katharina; Johann of every set |
| 2a / 2b | FP-2, FP-5, FP-W1 | The recommended FP-5 option, at Regular and Wide |
| 3 | FP-2, FP-3 | **Two partial sets in one block**: Heinrich and Anna; Margarethe and Friedrich children of both; Christian Anna's son only; Wilhelm Heinrich's son only. Shows the chosen mark on two different missing parents at once |
| 4 | FP-2, FP-5 | **Unrelated sets** (no change expected; drawn to confirm): {Heinrich, Anna} under Parents, then {Georg Becker, Katharina Becker} under Other parents, with Christian a child of the second; plus Elisabeth recorded as Johann's sister with no parent on file, joined by the bracket as today |
| 5 | FP-7 | Frame 1a with the Tab order numbered on the tiles: Heinrich 1, Anna 2, then the siblings, then the right column |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Family diagram | Snowflake | Extend | `macos/App/Features/Conclusions/PersonFamilySection.swift` `PersonFamilyDiagram` | Draws the lines as one-point rectangles in `PVColor.borderStrong`. The FP-3 mark is part of this drawing: a dashed stub or a join dot uses the same color and weight; no new token unless the board shows the dashed stub needs a muted ink, then `PVColor.borderSubtle` |
| Family layout | Snowflake | Extend | `macos/App/Features/Conclusions/PersonFamilyLayout.swift` | Places blocks of distinct parents and each set's line to its own tiles; the geometry is tested without a view |
| Family content | Snowflake | Extend | `macos/App/Features/Conclusions/PersonFamilyContent.swift` | Distinct parent tiles and each set as indexes into them; captions per block |
| Person tile | Recipe | Ship (Extend only if FP-3 D) | `macos/App/DesignSystem/Recipes/PersonCard/PVPersonCard.swift` on `PVTileCard` | Unchanged for options A–C. Option D adds one muted text line to the regular-size tile through the recipe's existing `lines`, not a Family-only tile |
| Caption | Snowflake | Ship | `PersonFamilyDiagram` captions (`pvMicroCaps`, `PVColor.textMuted`) | "Parents", "Parent", "Other parents", "Other parent" are existing strings |
| "Records disagree" mark (FP-5 B only) | Component | Ship | `macos/App/DesignSystem/Components/Badge/` | A Badge beside the caption; not a Callout, not a new chip |
| Show more row | Component | Ship | `macos/App/DesignSystem/Components/ShowMoreRow/` `PVShowMoreRow` | Unchanged look |

**Non-goals.** No new kit primitive. The dashed stub and join dot are Family's own drawing, not a kit line style: no second call site is known. No new tile size, no new focus ring, no new color token unless FP-3's chosen option needs a muted ink, which is an existing token. New copy only for FP-6's spoken text, FP-3 D's tile line and FP-5 B's badge, if chosen.

---

## 7. Handoff

When the board is agreed: record the frames and the chosen FP-3, FP-5 and FP-6 options on the **Board** line here, in [`README.md`](README.md) and on S16-81's map row; strike the options not chosen from FP-3, FP-5 and FP-6 so the requirements read as decided. The S16-81 plan (`prs/S16-81-family-parents-once.md`, [`plan-pr`](../../../../.agents/skills/plan-pr/SKILL.md)) copies FP-1 – FP-7 and FP-W1 into its Scope and the inventory into its design. When S16-81 lands, the brief moves to the spike's design archive.
