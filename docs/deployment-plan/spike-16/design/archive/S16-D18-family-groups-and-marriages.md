# S16-D18 — Family: siblings grouped by their parents, and each couple's marriage

**Kind:** Claude Design board (**enhancement** of the Spike 13 Person page board, S13-D3 Family, as S16-D2 extended it: the left column is redrawn as sibling groups and marriage lines are added; the right column is otherwise kept)
**Spike:** Provenencia Spike 16 (odds and ends), batch 6, slice 6l
**View:** the Person page's Family section: the left column (the person's siblings, the person among them, grouped by their parents) and, for marriages, the right column's partners
**Implements later as:** PR **S16-81** (Family groups siblings by their parents and shows each couple's marriage)
**Board:** agreed 2026-11-27 — [Claude Design — Person Detail](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ#page-Person-Detail---Family), turn "S16-D18 · Sibling groups and marriages" on the page *Person Detail - Family* (F1a, F1b, F2, F3, F4, F6, F5a, F5b, M1a, M1b, M2, M3, M4, M5). FG-3 B ("Shared parent" / "Shared parents"); FM-2 A (the gap between the two parents widens one line, 21 pt, per marriage); FM-3 B (a line over the partner's group, which moves down one line, 21 pt, per marriage, plus 4 pt); FM-4 A ("m."). Every tile keeps its fixed 92 pt. One line per group at x 10 in the 20 pt margin, groups 20 pt apart
**Depends on:** the agreed S13-D3 Family frames (shipped in S13-12, [#676](https://github.com/Jake-Robins-Studios/provenencia/pull/676)) and S16-D2's folds on them (S16-07, landed #761). The groups and the marriages come from S16-82 (engine only); the board needs nothing from it
**Related:** working rules "(Batch 6) Family groups siblings by their parents" and "(Batch 6) Family shows a couple's marriage from its events" in [`../deployment-plan.md`](../deployment-plan.md#working-rules); scope entries [S16-81](../deployment-plan.md#s16-81--family-groups-siblings-by-their-parents-and-shows-each-couples-marriage) and [S16-82](../deployment-plan.md#s16-82--the-family-read-sends-sibling-groups-and-each-couples-marriages); [`macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide)
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

Draw on the Person Detail board as a new turn "S16-D18 · Sibling groups and marriages", starting from the S13-D3 Family frames (11a full family, 11c conflicting parents) at Regular and Wide, with S16-D2's Show more rows. Redraw the left column as sibling groups, with their captions and lines, and add a marriage line for each married couple in both columns. Keep the tiles, the right column's partners and children (beyond their marriage lines), the bus from the person to the partners, the Show more rows and the section header; move tiles and lines only as far as the groups and the marriage lines need room, and say under each frame what moved.

**The board is agreed.** Its choices are written into the requirements below; the options not chosen are struck.

---

## 1. Objective

Today the left column stacks every parent set first, then lists every sibling once below them, with one line per set running down the margin from its parents to its children. When a sibling shares only one parent with the person, that parent is drawn a second time in a set of their own, and the lines from the two sets run past each other's tiles and cross. A person whose parents are Heinrich and Anna, with a brother Christian recorded as Anna's son only, shows Heinrich and Anna under **Parents**, Anna again under **Other parent**, and then every sibling below, with Christian's line coming down from the second Anna past the others.

What changes: **the left column is the person's siblings, the person among them, each once, grouped by their parents.** Each sibling is recorded with some of the person's parents. Siblings recorded with exactly the same parents are one **group**; any difference starts a new group. A group is drawn as its parents' tiles, then its children indented beneath, joined by one line that stays inside the group. So the lines never cross, and each family unit reads on its own. A parent in two groups (Anna, the mother in both) is drawn in each: she is that group's parent.

**Marriages.** Family shows who is married to whom, but not when or where. The researcher wants a couple's marriage date and place on the page whenever the project records a marriage: for **the parents of a group** and for **the person and each partner** (the person's tile in the left column, each partner in the right column, joined by the bus). The marriage line is **information, not a control**: it opens nothing and takes no Tab stop; the person's Timeline already opens the marriage.

What stays: the tiles, the two columns, the right column's partners and children, the Show more rows, and the Wide arrangement S13-D3 agreed.

---

## 2. Domain facts

| Fact | What it means on this board |
| --- | --- |
| The person's parents | Everyone recorded as the person's parent. Usually one or two; three or more means the records disagree (two mothers recorded), or a step or adoptive parent was recorded as a parent. The app does not choose between them. |
| A sibling's parents | The person's parents a sibling is recorded with. The page knows only which of **the person's** parents a sibling shares: if Christian's father is recorded but is not Johann's parent, Family does not read him. So a group with Anna alone says Christian shares Anna with Johann; it must not say his other parent is unrecorded, and must not call him a half-brother. |
| The person's group | The person's own parents, with the person and every sibling recorded with exactly those parents. It always comes first. With three parents recorded for the person, it has three parents. |
| Other groups | Every other set of shared parents, each with its siblings. After the person's group: groups with more parents first, then in the order of the person's parents. |
| Siblings with no shared parent | Someone recorded as the person's sibling with none of the person's parents on file (they may have parents of their own that Family does not read). They come last, as a group with no parent tiles, captioned **Other siblings**. |
| A person with no parents recorded | Then every sibling shares no parent with them, and there is one group: the person and their siblings, with no parent tiles, captioned **Siblings**, as today (11d). A person with no parents, no siblings, no partners and no children shows the section's empty state, as today (11h). |
| A group with no parents | Its members are joined by one line among themselves when there are two or more, as today's siblings-only list is (11d). |
| Children in a group | In birth order, undated last; the person in their place among them. |
| Lines are not spoken | VoiceOver hears the tiles, not the lines. Today it hears no grouping at all: the siblings are one group, "This person and siblings". |
| The tile's role | A tile's role ("Parent", "Sibling") is spoken before its name; at the regular size it is not drawn. |
| Today's lines | One vertical line per parent set in the left 20 pt margin (x 4–16 pt), a short horizontal to each of its parents and to each sibling it is the first set of; siblings with no shared parent are joined to the person by a bracket. |
| A marriage | A marriage event in the project with both people as its subjects. It has a date (maybe none, maybe "abt 1841" or "bet 1840 and 1842"), a place (maybe none, maybe several), and its own Event page. |
| Spouses without a marriage | Two people can be linked as spouses or partners with no marriage event (a relationship recorded directly, or a couple known only through a child). They show **no** marriage line: being partners is not being married, and no date is invented. |
| More than one marriage | A couple can have two marriage events: a remarriage, or two records the app has not merged. Each is a line of its own, earliest first, undated last. |
| Couples in a group | A group with two parents is one couple. A group with three or more parents (records that disagree) has a couple for each two of its parents that married. A one-parent group has none. A couple in two groups (Heinrich and Anna, the parents of two groups) shows its marriage in each. |
| Life lines | A person tile already shows its life as lines: "b. 3 Jul 1817 · Bremen", "d. 1851". A marriage line is the same kind of line with the event type's abbreviation, "m.": the same date and place words, the same muted place, cut at the tail. A tile line shows one place and no "+N" count, and so does a marriage line. A line with no date shows the place alone, with no dot; one with no place shows the date alone. |
| Partners | Each partner tile in the right column, with their children under them; the bus joins the person's tile to every partner. A person can have several partners, each with their own marriages. |
| Room | The left margin is 20 pt and the gutter between the columns is 48 pt at Regular and 96 pt at Wide; neither holds text. A tile has a fixed height for two life lines today. |

### 2.1 What this board is not

- Choosing between conflicting parents, or marking one as preferred: that is a reconciliation feature, not drawing.
- New relationship kinds (step, adoptive, half). The page draws what is recorded.
- A sibling's parents who are not the person's parents; a way to add a missing parent from Family.
- Grandparents, or any parent's other children who are not the person's siblings.
- Divorce, separation, banns, licences or any event other than a marriage. (A later union pattern would show the same way, worded by its own type.)
- Opening the marriage from Family; Family's marriage line is not a link (the Timeline opens it).
- Marriages of siblings or children: only the parents' couples and the person's own partners.
- A marriage's Sources, a provenance sheet, ages at marriage, or adding a marriage from Family.

---

## 3. Implementation gate

| S16-81 ships | Not S16-81 |
| --- | --- |
| FG-1 – FG-7, FG-W1, FM-1 – FM-7, FM-W1 | The engine grouping the siblings and sending the marriages (S16-82); any event but a marriage; opening the marriage from Family; siblings' or children's marriages |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| FG-1 | The left column draws the sibling groups in order: the person's group, the other groups, then siblings with no shared parent. Each sibling, the person among them, appears once. Each group is its parents' tiles, then its children indented beneath, joined by one line in the margin that starts at the group's parents and ends at its last child; a group with no parents joins its members among themselves. No line leaves its group, so no two lines cross. |
| FG-2 | A parent in several groups has a tile in each, one Tab stop each, spoken as "Parent, ⟨name⟩, ⟨life lines⟩" each time. |
| FG-3 | **Captions.** The person's group is captioned **Parents** (**Parent** with one). Every other group with parents is captioned **Shared parents** (**Shared parent** with one): it says what the group shares with the person, never that a sibling's other parent is unrecorded or that the siblings are half-siblings. The no-shared-parent group is captioned **Other siblings**; with no parents recorded for the person, the one group is captioned **Siblings** (frame 6). No bracket joins a group to the person's tile. |
| FG-4 | **Spoken.** Each group is one VoiceOver container labelled with its parents, the names joined as a list ("Children of Anna Weber"; "Children of Heinrich Weber and Anna Weber"; "Children of Heinrich Weber, Anna Weber and Katharina Weber"). The person's group says who is in it: "This person, siblings and parents", "This person and parents" (no siblings, frame 4), "This person and siblings" (no parents, frame 6) or "This person". The no-shared-parent group is "Other siblings". A sibling is spoken as today inside it, so the group says which parents each sibling is recorded with. Annotate the labels on frames 1a, 2 and 4. |
| FG-5 | Tab order runs the groups top to bottom, each group's parents then its children (the person's tile takes no stop), then the right column. |
| FG-6 | The siblings fold as today: the first 30 siblings across the groups, in order, then a page at a time. A group is shown when its first child is; its parents show with it. The Show more row sits under the last shown child, in that child's group. |
| FG-7 | Today's per-set lines, the bracket from the person to siblings with no shared parent, and the "Other parent" block with no children under it are gone. |
| FG-W1 | At Wide the left column keeps the arrangement S13-D3 agreed (the two columns, the wider gutter); the groups and lines are the same at both widths. Nothing moves between widths. |
| FM-1 | A couple with a marriage shows one **marriage line** per marriage: the event type's abbreviation, then the marriage's date and place, worded as a tile's life lines are ("m. 12 Jun 1841 · Hamburg"). A couple with no marriage shows nothing new. |
| FM-2 | **A group's parents.** The marriage line sits in the gap between the two parents' tiles, which widens one line (21 pt) per marriage, so it reads as belonging to both. In a group with more than two parents (frame M4), a couple whose tiles are not next to each other (Heinrich and Katharina, Anna between them) has its line under its lower parent's tile, and each marriage line **names the other spouse**, drawn and spoken ("m. abt 1816 · Kiel, with Heinrich Weber"); the place is cut first. In a two-parent group the line names nobody. |
| FM-3 | **The person and a partner.** The line sits at the top of the partner's group, above the partner's tile; the group moves down one line (21 pt) per marriage, plus 4 pt. With several partners, each line belongs to its own partner's group. |
| FM-4 | **Wording.** The leading word comes from the marriage's event type, not from Family: its abbreviation, as "b." and "d." do: "m. 12 Jun 1841 · Hamburg". A marriage with neither a date nor a place shows the abbreviation alone ("m."), since the marriage itself is recorded (frame M2): a line built from an event that exists is kept with both halves missing, where a missing birth or death is left out as today. |
| FM-5 | **Two marriages of one couple** (frame M3): both lines, earliest first, each its own line; an undated one last. |
| FM-6 | **Spoken.** The line is not a Tab stop. It is one VoiceOver element that names its couple, in reading order where it is drawn: a parents' line just after the second parent ("Heinrich Weber and Anna Weber, married 3 May 1812, Altona"), a partner's line at the top of the partner's group, before the partner's tile ("Johann Weber and Maria Schulz, married 12 Jun 1841, Hamburg"). A missing half is left out as in life lines ("married in Altona", as a tile says "born in Bremen"; user, 2026-11-27); with both missing, the word alone ("…, married"). A line that names the other spouse (FM-2) is spoken as drawn, with no couple before it, since the tile just before it names the lower spouse: "married abt 1816, Kiel, with Heinrich Weber" (user, 2026-11-27). |
| FM-7 | A line goes with its tiles: when a fold hides a couple's group or partner, the marriage line is hidden too, and Show more reveals it with them. |
| FM-W1 | At Wide the marriage lines sit where they sit at Regular; the wider columns give the place more room before it is cut. Nothing moves between widths. |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Person page, Family section | Two columns as S13-D3 agreed: the sibling groups left (each group's parents, then its children indented), the person's partners and children right, a 48 pt gutter between; marriage lines between or inside the couples | As S13-D3 agreed: the same two columns, each wider, with a 96 pt gutter; the extra width goes to the tiles' text and the marriage lines' places so they are cut less | Nothing; the groups, their lines and the marriage lines are the same at both widths (FG-W1, FM-W1) |

---

## 5. Frames (agreed)

Drawn on the board's turn "S16-D18 · Sibling groups and marriages", Regular (pane 1102 × 900) and Wide (pane 2296 × 1440) where marked. The person is **Johann Weber, b. 1817**; the right column is 11a's (Maria Schulz with her children, Sophie Brandt with Otto, Paul with no other parent). Frame 0 (today) and the option frames were not kept.

| Frame | Requirement | What it shows |
| --- | --- | --- |
| F1a / F1b | FG-1 – FG-4, FG-W1 | The person's group (Heinrich and Anna; Margarethe, Johann, Friedrich, Wilhelm), then Anna under **Shared parent** with Christian; container labels noted |
| F2 | FG-1, FG-3, FG-4 | Records that disagree (11c redrawn): Heinrich, Anna and Katharina with Johann and Friedrich; Heinrich and Anna with Margarethe and Wilhelm; Heinrich and Katharina with Christian |
| F3 | FG-1, FG-3 | Two one-parent groups: Heinrich alone with Wilhelm, Anna alone with Christian |
| F4 | FG-1, FG-3, FG-4 | Unrelated sets: Johann's four-parent group, Johann alone ("This person and parents"); Heinrich and Anna; Georg and Katharina Becker with Christian; Elisabeth under Other siblings, no bracket |
| F6 | FG-1, FG-3, FG-4 | No parents recorded (11d redrawn): one group captioned Siblings, Clara, Johann, Karl on one line |
| F5a | FG-5 | Tab order on F1a: Heinrich 1, Anna 2, Margarethe 3, Friedrich 4, Wilhelm 5, then Anna 6, Christian 7, then the right column |
| F5b | FG-6 | 40 siblings in two groups, one fold across them: Anna's group shown, folded after the 30th sibling, "Show 10 more" in that group |
| M1a / M1b | FM-1 – FM-3, FM-6, FM-W1 | Heinrich and Anna m. 3 May 1812 · Altona between their tiles; Johann and Maria m. 12 Jun 1841 · Hamburg over Maria's group; Johann and Sophie no marriage |
| M2 | FM-4 | "m. Altona", "m. 12 Jun 1841", "m." alone |
| M3 | FM-5 | Two marriages of one couple, two lines over Maria's group, the undated one second |
| M4 | FM-2 | A three-parent group: Heinrich and Anna's line between them, Heinrich and Katharina's under Katharina, each ending ", with Heinrich Weber"; the two-parent groups' lines name nobody |
| M5 | FM-7 | Partners drawn as if folded after the first: Maria's line shown, the hidden partners' lines hidden with them |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Family diagram | Snowflake | Extend | `macos/App/Features/Conclusions/PersonFamilySection.swift` `PersonFamilyDiagram` | Draws one line per group (x 10 in the 20 pt margin) as one-point rectangles in `PVColor.borderStrong`, as today; no new token |
| Family layout | Snowflake | Extend | `macos/App/Features/Conclusions/PersonFamilyLayout.swift` | Places the groups top to bottom, each its parents then its children, and one line per group; the per-set rails (`railX`) and the bracket go. A marriage line is a placed entry in its group, beside the tiles and Show more rows, in reading order: in the widened gap between a group's two parents (or under the lower parent's tile for a couple not next to each other), and at the top of a partner's group. Every tile keeps one fixed height. Geometry only; tested without a view |
| Family content | Snowflake | Extend | `macos/App/Features/Conclusions/PersonFamilyContent.swift` | Draws the engine's groups in the engine's order, with no regrouping: each group's parents, children, caption and container label, and each couple's marriage lines. Swift does not work out groups or look for events |
| Caption | Snowflake | Ship | `PersonFamilyDiagram` captions (`pvMicroCaps`, `PVColor.textMuted`) | "Parents", "Parent" and "Siblings" are existing strings; "Shared parent", "Shared parents" and "Other siblings" are new; "Other parent" and "Other parents" go if nothing else reads them |
| Show more row | Component | Ship | `macos/App/DesignSystem/Components/ShowMoreRow/` `PVShowMoreRow` | Unchanged look; one siblings fold across the groups (FG-6) |
| Life line | Platform type | Extend | `macos/App/Platform/PersonLifeDisplay.swift` `PersonLifeDisplay.LifeLine` | The marriage line **is** a life line: abbreviation, date, place and spoken label, plus one optional part, the other spouse (FM-2). Its builder takes an event's worded date and places, so b., d. and m. lines are built and spoken one way (the `L10n.Conclusions.a11yLifeLine*` formats). A line from an event that exists is kept with both halves missing (FM-4); a missing birth or death is still left out. No new line type |
| Event date and place wording | Feature helper | Ship | `macos/App/Features/Conclusions/EventsListView.swift` `EventSecondaryDisplay.content` | Words the marriage's date and places as the Events list and Timeline do |
| Date · place line | Component | Extend | `macos/App/DesignSystem/Components/DatePlaceLine/PVDatePlaceLine.swift` | Draws the line, `leading` the abbreviation, `missing: .omitted`. Gains one optional trailing part for the other spouse (FM-2), drawn after the place ("…, with Heinrich Weber"); the place is cut first, the name is kept. Spoken by the caller's label, one "with %@" clause joined by `L10n.DesignSystem.spokenJoin` |
| Life-line words | — | Extend | `macos/App/Platform/L10n.swift`, beside the seeded event type terms (`L10n.PropertyTerm`) | **One table** of the words a life line leads with, keyed by event type: the abbreviation ("b.", "d.", "m."), the display word ("Born", "Married") and the inline spoken word ("born", "married"). Birth and death move into it from `personBornAbbr`, `personDiedAbbr` and the `a11yBorn*` / `a11yDied*` words, so `PersonLifeDisplay` reads every line's words from one place. A Go-parity test row beside `TestSwiftVocabularyMatchesGo` (`api/ffi/swift_vocabulary_test.go`) requires an entry for every event type in `kinship.SpouseEventTypes()`, the accessor S16-82 adds; the row lands in S16-81 with the table, a test-only Go edit. Family has no marriage string of its own |
| Previews | Snowflake | Extend | `macos/App/Features/Conclusions/PersonFamilyPreviewData.swift`; the `#Preview`s in `PersonFamilySection.swift` | A preview per frame F1 to F4 and F6, and M1 to M4; 11c redrawn as F2, 11d as F6; 11h unchanged |
| Copy | — | Extend | `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings` | The group container labels (FG-4: "Children of %@" and the person's-group variants, the existing "This person and siblings" and "This person" among them), the new captions ("Shared parent", "Shared parents", "Other siblings"), the marriage words in the life-line words table, and one "with %@" clause. Names are joined with the list formatter (`ListFormatter`, as `ReconciledValueDisplay` does), for a couple's spoken label too: no hand-made "and" format |

The tests that assume parent sets with rails (`macos/ProvenenciaTests/PersonFamilyContentTests.swift`, `PersonFamilyLayoutTests.swift`) change with S16-81; the plan names them.

**Non-goals.** No new kit primitive, no new tile size, no new focus ring, no new color or stroke token. No link, event chip, Badge or Callout for a marriage, and no marriage for a couple without a marriage event. No words that call a sibling a half-sibling or a parent unrecorded.

---

## 7. Handoff

The board is agreed (2026-11-27) and its choices are written into FG-3, FM-2, FM-3, FM-4 and FM-6 above. The S16-81 plan (`prs/S16-81-family-groups-and-marriages.md`, [`plan-pr`](../../../../.agents/skills/plan-pr/SKILL.md)) copies FG-1 – FG-7, FG-W1, FM-1 – FM-7 and FM-W1 into its Scope and the inventory into its design, and updates the doc comments the change makes false (`PersonFamilyLayout`'s "each parent set under its caption", `PersonFamilyContent`'s parent-set fold). When S16-81 lands, the brief moves to the spike's design archive.
