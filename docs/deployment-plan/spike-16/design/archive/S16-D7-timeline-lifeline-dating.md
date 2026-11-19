# S16-D7 — The Person page Timeline: the lifeline draws every event's dating

**Kind:** Claude Design board (**enhancement** of the Person page Timeline frames, S13-D4 and S16-D2: marks are added to the existing lifeline)
**Spike:** Provenencia Spike 16 (odds and ends), batch 5
**View:** the Person page, Timeline section: the lifeline beside the event rows
**Implements later as:** PR **S16-42** (Every event date line reads the engine's dating)
**Board:** agreed 2026-11-17 — [Claude Design — Person Detail](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ), page *Person Detail - Timeline*, turn 18 "S16-D7 · Lifeline dating" (frames 18a, 18b, 18c). TL-2: a 32 pt bar centred on the day; TL-3: a bar open both ends or closed both ends tethers from its middle. Its row date texts are stand-ins; S16-D4 holds the wording
**Depends on:** S16-40 (landed [#869](https://github.com/Jake-Robins-Studios/provenencia/pull/869)): events record **As of** dates; the agreed S13-D4 and S16-D2 Timeline frames on the Person page board ([Claude Design — Person Detail](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ), page *Person Detail - Timeline*)
**Related:** [S16-D4](S16-D4-event-date-line.md) (the date line's wording, which the Timeline rows show); feature doc [`../event-as-of.md`](../../event-as-of.md); working rules "As-ofs alone make a span open on both sides" and "One dating for every event, on the Timeline and in order too" in [`../deployment-plan.md`](../../deployment-plan.md#batch-5--event-as-of-dates); [`macos-client-patterns.md` § 9](../../../../macos-client-patterns.md#9-window-widths-regular-and-wide); plan [`../prs/S16-42-event-dating-line.md`](../../prs/S16-42-event-dating-line.md)
**Design system layers:** [`docs/design-system-layers.md`](../../../../design-system-layers.md)
**Skill:** [`add-design-brief`](../../../../../.agents/skills/add-design-brief/SKILL.md); [`add-ui-component`](../../../../../.agents/skills/add-ui-component/SKILL.md)

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

Draw as a new turn "S16-D7 · Lifeline dating" on the Person page board's *Person Detail - Timeline* page, starting from the S13-D4 / S16-D2 Timeline frames (Regular and Wide). Change only the lifeline marks of the events named below. Do not redraw the rows, the cards, the folds, the lifeline's ticks or its tethers' style. Each row's date text is S16-D4's: draw it with S16-D4's recommendation and do not decide its wording here.

---

## 1. Objective

An event can now record **As of** dates: a day a lasting fact (a residence, an occupation) was known to be under way, without saying when it began or ended. Today such an event is not on the lifeline at all. After S16-42 the engine dates every event once, and the lifeline draws that dating: an as-of residence spans its earliest to its latest as-of with each open side faded, a start or an end closes its side, and a start-and-end event spans its whole range.

This board decides **how the lifeline marks an open side** on a one-day span, which today is a dot that cannot show one.

**What stays.** A dated occurrence is a dot (a closed day) or a bar (a longer date), as today. The bar's fade, colours, width, click target and tether style stay. Rows and cards are unchanged.

## 2. Domain facts

| Fact | Meaning for the board |
| --- | --- |
| The engine sends each row's span | From, To on the year line, and whether each side is open. The lifeline draws what it is given |
| As-of only | From the earliest as-of to the latest, **open on both sides**: the residence began at some unknown day before the first and ended at some unknown day after the last |
| As-of with a start, or an end | The start (or end) closes its side; the other side stays open |
| Start and end, no as-of | Spans start to end, closed both sides. Today the lifeline draws it at its start only (user, 2026-11-17: the whole span) |
| Start only, or end only | Drawn at that date, open on the side not recorded (user, 2026-11-17). An end-only event is now on the lifeline, sorted at its end |
| One as-of | One day, open on both sides |
| Today's marks | A span of one day or less is a dot. A longer one is a bar whose open side fades out over up to 16 pt. A bar's tether leaves from its middle, or 8 pt in from its known end when one side is open |
| A dot means a closed day | After this board a day with an open side is never a dot. That includes a day-precision `bef 14 May 1880` occurrence, which is open before (a year-precision `bef 1880` is already a faded bar) |

### 2.1 What this board is not

- Not the date text on the rows: that is S16-D4's wording.
- Not the Event page (S16-D6).
- Not a new kind of mark: the bar and its fade already exist.

---

## 3. Implementation gate

| S16-42 ships | Not S16-42 |
| --- | --- |
| TL-1 – TL-3, TL-W1 | The date line's wording (S16-D4, also S16-42); the Event page Date row (S16-44, S16-D6) |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| TL-1 | **Spans.** An as-of event's bar spans its dating with each open side faded as today's open sides are: two as-ofs → a bar faded at both ends; a start of 1985 closes its left end; an end closes its right end. A start-and-end event draws its whole span, both ends closed. A start-only or end-only event draws its bar faded on the side it does not record |
| TL-2 | **One day with an open side.** A single as-of (one day, open both sides) is the TL-1 bar at a short fixed length centred on the day, faded on each open side. **The board decides** that length: at least twice the 16 pt fade, so the two fades do not cross; 32 pt recommended. The same rule draws a day-precision `bef` / `aft` occurrence, faded on its one open side. A closed day stays a dot |
| TL-3 | **Tethers.** A bar open at both ends tethers from its middle (today it tethers 8 pt in from its end). A bar open on one side keeps today's tether, 8 pt in from its known end |
| TL-W1 | The marks are the same at Regular and Wide; the Timeline keeps the Wide arrangement S13-D4 and S16-D2 agreed. Nothing moves between widths |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Person page, Timeline section | The lifeline beside the rows, as S13-D4 and S16-D2 agreed | As agreed | Nothing; the lifeline gains the TL-1 – TL-3 marks |

---

## 5. Suggested frames

Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440); the others as they say.

| Frame | Requirement | Draw |
| --- | --- | --- |
| 1a / 1b | TL-1, TL-3, TL-W1 | Person page Timeline for X, born 1955: a birth (dot); a residence with as-ofs 1990 and 2015 (bar 1990–2015 faded both ends, tether from its middle); a residence with start 1985 and as-ofs 1990, 2015 (bar 1985–2015, left closed, right faded); a start-only occupation 1975 (faded after); an end-only residence 1980 (faded before); a start-and-end residence 1960–1970 (closed both). Tethers from each mark to its row |
| 2 | TL-2, TL-3 | Regular only, zoomed on the lifeline: a single as-of 10 Jan 1990 (the TL-2 bar, faded both ends, tethered from its middle), a `bef 14 May 1880` day (faded before only), a closed `14 May 1880` dot and an `aft 1990` bar, so the four read apart |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Lifeline mark | Snowflake | Extend | `macos/App/Features/Conclusions/PersonTimelineLifeline.swift` `PersonTimelineLifeline.Shape` `.bar`; drawing in `PersonTimelineSection.swift` | TL-1 and TL-2 are the existing bar and fade; TL-2 adds a fixed short length; TL-3 moves a both-open tether. No new `Shape` case, color or token |
| Timeline row | Snowflake | Ship | `macos/App/Features/Conclusions/PersonTimelineSection.swift` | Unchanged; its date text is S16-D4's |

**Non-goals.** No new kit primitive, no new kind of mark, no icon or badge for "as of", no new color or token, no tooltip.

---

## 7. Handoff

When the board is agreed: record the turn, its frames and the TL-2 length on the **Board** line here, in [`README.md`](README.md) and on the plan's **Board** line; the plan copies TL-1 – TL-3 and TL-W1 into its Scope. The plan moves from `Blocked` to `Planned` when this board and S16-D4 are both agreed. When S16-42 lands, the brief moves to the spike's design archive.
