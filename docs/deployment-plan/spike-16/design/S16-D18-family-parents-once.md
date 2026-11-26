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

What stays: the tiles themselves, the two columns, the siblings' order, the person's raised tile among the siblings, the right column, the Show more rows, and the Wide arrangement S13-D3 agreed.

**The siblings' order is the engine's, not the board's.** It is: the children of every set (the person among them), then the children of each other set walking from the last set to the first, then siblings recorded with no shared parent; each group in birth order, undated last. So a sibling recorded with only the mother is drawn **before** the brothers and sisters recorded with both parents. Every frame below lists its siblings in that order; draw them so. If the order looks wrong once the parents are drawn once, say so under the frame as a note for the user; do not reorder.

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
| FP-1 – FP-8, FP-W1 | Any Go, proto or data change; an action to record the missing parent; the right column |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| FP-1 | Each of the person's parents is one tile, one Tab stop and spoken once, however many sets they are in. |
| FP-2 | Sets that share a parent, directly or through another set, are drawn as one **block** of parent tiles. Within a block the parents keep the engine's order of first appearance (the first set's parents, then each later set's new parents). Sets that share no parent stay separate blocks, as today: two parents not recorded as partners are two one-parent sets and so two blocks (frame 6), and a person with more than ten parents recorded (crafted data, where none is paired) keeps one block per parent, as today. |
| FP-3 | Each sibling is joined only to the parents of their set(s). A sibling in the full set is joined to all of its parents, as today. **The missing-parent mark.** A sibling is marked against a parent only when the sibling's set lies **inside** another set of the block, and only against the parents that other set adds: Christian, recorded with {Anna}, beside {Heinrich, Anna}, is marked against Heinrich. When the sibling's set lies inside several sets, the mark is against every parent those sets add (frame 2 plus a sibling recorded with Heinrich only is marked against Anna and Katharina: "Other parents not recorded"). Overlapping sets that disagree (frame 2: {Heinrich, Anna} and {Heinrich, Katharina}) mark nobody: Margarethe is not "missing" Katharina; the records disagree, and FP-5 says so. **Draw options** for how the mark looks, on frame 1: **(A) dashed stub:** the partial set's line runs from the parents it has, and at each parent it is marked against a short dashed stub stops short of the line, meaning "not recorded". This is the Person page's existing "not recorded" mark: the Timeline already draws a missing birth or death date as a dashed stub on its lifeline. **(B) join dots:** a small dot wherever a line joins a tile or another line, so a line that only crosses another (Christian's passing Heinrich's row) has no dot and reads as no join. The dots then mark every join in the diagram, the right column's bus and child lines too, so one diagram keeps one line style; draw the right column with them in this option. **(C) per-parent lines:** one vertical line per parent instead of one per set; each sibling's horizontal meets the lines of their recorded parents with a dot and crosses the others. Choosing C changes the spike's working rule, which draws one line per set; the user decides that here. **(D) a tile note:** lines as in (A) or (B), plus a muted text line inside Christian's tile: "Other parent not recorded" ("Other parents not recorded" for several). Options may combine; say which combination you recommend. Whatever the option, where two sets' lines both reach a shared parent (Anna in frame 1, Heinrich in frame 2), they must not read as one line joining the two sets: draw how. |
| FP-4 | The person's own tile is joined to every set's parents (the person is a child of every set). A sibling in several sets (Friedrich, in both of frame 2's sets) is joined to every parent of those sets; draw whether that is one horizontal per set or one line that meets both sets' lines. |
| FP-5 | Captions keep today's rule. The first block is captioned **Parents**, or **Parent** when it holds one tile and is the only block. A later block is captioned **Other parents**, or **Other parent** when it holds one tile. **Draw options** for a block of overlapping sets (frame 2: three parents in one block): **(A)** the caption **Parents** only, the lines show the two sets; **(C)** a thin rule inside the block between the parents only the first set has and those only a later set has (in frame 2, between Anna and Katharina; Heinrich, in both, sits first). No badge or words saying the records disagree: the page cannot tell a disagreement from a step or adoptive parent recorded as a parent, and "records disagree" already means a field's votes against its value elsewhere on the page. |
| FP-6 | Spoken. Each parent is spoken once, as today: "Parent, ⟨name⟩, ⟨life lines⟩". VoiceOver must say which parents each sibling is recorded with, since the lines are not spoken. A sibling in every set of their block is spoken as today (the block's caption already names their parents). Every other sibling adds one phrase after the name, before the life lines: "child of ⟨their parents⟩": "Sibling, Christian Weber, child of Heinrich Weber and Katharina Weber, born 1823" (frame 2). **Draw options** for a sibling with a mark (FP-3), as a VoiceOver annotation on frame 1 (no pixels): **(A)** that phrase only: "Sibling, Christian Weber, child of Anna Weber, born 1823"; **(B)** that phrase plus what is missing: "Sibling, Christian Weber, child of Anna Weber, other parent not recorded, born 1823". If FP-3 option D is chosen, the drawn tile line is the missing part ("Other parent not recorded") and the spoken phrase is B. Annotate frame 2's spoken text for Christian and Margarethe too. |
| FP-7 | Tab order runs the blocks top to bottom, each block's parents in order, then the siblings, then the right column, as today; a parent is never reached twice. |
| FP-8 | The parents' Show more row looks as today, under the last shown parent. It counts parent tiles, not sets. The plan settles what a folded parent does to its sets' lines; the board need not draw it. |
| FP-W1 | At Wide the left column keeps the arrangement S13-D3 agreed (the two columns, the wider gutter); the blocks, lines and marks are the same at both widths. Nothing moves between widths. |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Person page, Family section | Two columns as S13-D3 agreed: origin left (parent blocks, then siblings indented), the person's partners and children right, a 48 pt gutter between | As S13-D3 agreed: the same two columns, each wider, with a 96 pt gutter; the extra width goes to the tiles' text so names and places truncate less | Nothing; this board redraws the parent blocks and their lines in the left column at both widths (FP-W1). The lines sit in the left margin, so their geometry is the same at both widths |

---

## 5. Suggested frames

Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440); the others at Regular only. Every frame shows the whole Family section, both columns; the person is **Johann Weber, b. 1817**, and the right column is 11a's, unchanged (Maria Schulz with her children, Sophie Brandt with Otto, Paul with no other parent).

| Frame | Requirement | Draw |
| --- | --- | --- |
| 0 | — | Today, for reference only (not to ship): frame 1's family as the app draws it now: Heinrich and Anna under Parents, Anna again under Other parent, Christian's line from the second Anna. Siblings in the order frame 1 gives |
| 1-A, 1-B, 1-C, 1-D | FP-1, FP-3, FP-4, FP-6 | **A set inside another**, one frame per FP-3 option. Sets {Heinrich, Anna} and {Anna}: one block, Heinrich then Anna. Siblings in the engine's order: **Johann** (the person, b. 1817, child of both), **Christian** (b. 1823, Anna's son only, marked against Heinrich), **Margarethe** (b. 1815), **Friedrich** (b. 1820), **Wilhelm** (undated), the last three children of both. FP-6's spoken text noted beside Christian's tile |
| 1a / 1b | FP-1 – FP-4, FP-W1 | The recommended FP-3 option from frame 1, at Regular and Wide |
| 2-A, 2-C | FP-2, FP-3, FP-4, FP-5, FP-6 | **Overlapping sets** (11c redrawn), one frame per FP-5 option, with the recommended FP-3 line style and **no** missing-parent mark (FP-3). Sets {Heinrich, Anna} and {Heinrich, Katharina}: one block, Heinrich, Anna, Katharina. Siblings in the engine's order: **Johann** (the person) and **Friedrich** (b. 1820), children of both sets; **Christian** (b. 1823), Heinrich and Katharina's; **Margarethe** (b. 1815) and **Wilhelm** (undated), Heinrich and Anna's |
| 2a / 2b | FP-2, FP-5, FP-W1 | The recommended FP-5 option, at Regular and Wide |
| 3 | FP-2, FP-3 | **Two sets inside another**: sets {Heinrich, Anna}, {Anna} (Christian's link recorded first) and {Heinrich}: one block, Heinrich then Anna. Siblings in the engine's order: **Johann** (the person); **Wilhelm** (undated, Heinrich's son only, marked against Anna); **Christian** (b. 1823, Anna's son only, marked against Heinrich); **Margarethe** (b. 1815) and **Friedrich** (b. 1820), children of both. Shows the chosen mark on two different missing parents at once |
| 4 | FP-2, FP-5 | **Unrelated sets** (no change expected; drawn to confirm): {Heinrich, Anna} under Parents, then {Georg Becker, Katharina Becker} under Other parents. Siblings in the engine's order: **Johann** (the person, a child of both sets); **Christian** (b. 1823), Georg and Katharina's; **Margarethe** and **Friedrich**, Heinrich and Anna's; then **Elisabeth**, recorded as Johann's sister with no parent on file, joined by the bracket as today |
| 5 | FP-7 | Frame 1a with the Tab order numbered on the tiles: Heinrich 1, Anna 2, then the siblings (Christian is the first stop after the parents, since the person's tile takes no stop), then the right column |
| 6 | FP-2, FP-5 | **Two parents not recorded as partners** (no change expected; drawn to confirm): sets {Heinrich} and {Anna}, so two blocks: Heinrich under **Parents**, Anna under **Other parent**. Siblings: **Johann** (the person, a child of both); **Margarethe** (b. 1815), Heinrich's only. No mark: the sets share no parent |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Family diagram | Snowflake | Extend | `macos/App/Features/Conclusions/PersonFamilySection.swift` `PersonFamilyDiagram` | Draws the lines as one-point rectangles in `PVColor.borderStrong`. The FP-3 mark is part of this drawing, in the same color: a dashed stub uses a new stroke token for "not recorded", `PVStroke.notRecordedDash` = [3, 3], in `macos/App/DesignSystem/Tokens/PVStroke.swift`, beside the outline token `dashPattern` ([4, 3], which keeps meaning a provisional outline). S16-81 moves the Timeline's three `[3, 3]` literals in `PersonTimelineSection.swift` (the lifeline's missing-date stub, the undated age flag and the placeholder cap) onto it with no visual change, so "not recorded" has one look and one token on the page |
| Family layout | Snowflake | Extend | `macos/App/Features/Conclusions/PersonFamilyLayout.swift` | Reads the blocks from the content and places them; draws each set's line to its own tiles and each mark. Geometry only: it does not work out what a block is. Tested without a view |
| Family content | Snowflake | Extend | `macos/App/Features/Conclusions/PersonFamilyContent.swift` | The one place the grouping is worked out: the distinct parent tiles, each set as indexes into them, the blocks (each with its parents and its caption) and each sibling's missing parents (FP-3) |
| Person tile | Recipe | Extend | `macos/App/DesignSystem/Recipes/PersonCard/PVPersonCard.swift` (`PVPersonCardContent`) on `PVTileCard`; built by `PersonCardLink.link` | Gains one optional **note**: a short phrase the caller passes. It is always spoken after the name (FP-6); it is drawn as a muted text line under the life lines only if FP-3 option D is chosen. Not the life `lines` (those are dated event lines drawn by `PVDatePlaceLine`), and no Family-only tile. Nothing else about the tile changes |
| Caption | Snowflake | Ship | `PersonFamilyDiagram` captions (`pvMicroCaps`, `PVColor.textMuted`) | "Parents", "Parent", "Other parents", "Other parent" are existing strings |
| Show more row | Component | Ship | `macos/App/DesignSystem/Components/ShowMoreRow/` `PVShowMoreRow` | Unchanged look; counts parent tiles (FP-8) |
| Previews | Snowflake | Extend | `macos/App/Features/Conclusions/PersonFamilyPreviewData.swift`; the `#Preview`s in `PersonFamilySection.swift` | A preview per frame 1, 3 and 6; 11c redrawn as frame 2 |
| Copy | — | Extend | `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings` | FP-6's phrase (FP-3 D's tile line uses the same string). The captions are existing strings |

The tests that assume one tile per set and one rail per set (`macos/ProvenenciaTests/PersonFamilyContentTests.swift`, `PersonFamilyLayoutTests.swift`) change with S16-81; the plan names them.

**Non-goals.** No new kit primitive. The dashed stub and join dot are Family's own drawing, not a kit line style: no second call site is known. No new tile size, no new focus ring, no new color token. One new stroke token, `PVStroke.notRecordedDash`, because the Timeline already draws "not recorded" three times with a literal and Family would be the fourth. New copy only for FP-6's spoken phrase, which FP-3 D's tile line reuses.

---

## 7. Handoff

When the board is agreed: record the frames and the chosen FP-3, FP-5 and FP-6 options on the **Board** line here, in [`README.md`](README.md) and on S16-81's map row; strike the options not chosen from FP-3, FP-5 and FP-6 so the requirements read as decided. The S16-81 plan (`prs/S16-81-family-parents-once.md`, [`plan-pr`](../../../../.agents/skills/plan-pr/SKILL.md)) copies FP-1 – FP-8 and FP-W1 into its Scope and the inventory into its design. The plan also: has the layout return its lines as one typed list (solid line, not-recorded stub, join) so combined options are more entries, not more fields; and updates the doc comments the change makes false (`PersonFamilyContent`'s "with no regrouping", `PersonFamilyLayout`'s "each parent set under its caption") and the fold's name if it no longer counts sets (`Fold.parentSets`, `more.parentSets`). When S16-81 lands, the brief moves to the spike's design archive.
