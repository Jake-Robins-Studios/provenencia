# S16-D4 — The event date line: every dating case, on an Events list row

**Kind:** Claude Design board (**enhancement** of the Events list frames (Spike 9): states are added to existing frames)
**Spike:** Provenencia Spike 16 (odds and ends), batch 5
**View:** the Events list: the shared event date line on a row. The same line shows on the Event page header, the Timeline's event rows, search hits, Promote's candidate menus and Promote's record rows; this board draws it on the list row and names the others
**Implements later as:** PR **S16-42** (Every event date line reads the engine's dating)
**Board:** agreed 2026-11-17 — [Claude Design — Events List](https://claude.ai/artifact/HP8p5mK3BFhNzFRrP5UK9w), section "S16-D4 · Event dates" (frames 1a, 1b, 2). ED-2 – ED-5: `as of %@`, `as of %1$@–%2$@`, `from %1$@, as of %2$@`, `as of %1$@, until %2$@` ("known …" and an ellipsis were weighed and dropped: the ellipsis reads as truncation and VoiceOver says nothing)
**Depends on:** S16-40 (landed [#869](https://github.com/mendahu/provenencia/pull/869)): events record **As of** dates; the agreed Events list frames
**Related:** [S16-D7](S16-D7-timeline-lifeline-dating.md) (the Timeline lifeline, the same PR); feature doc [`../event-as-of.md`](../../event-as-of.md); working rules "One dating, in Go, derived on read", "The engine sends the dating, not the as-ofs" and "As-ofs alone make a span open on both sides" in [`../deployment-plan.md`](../../deployment-plan.md#batch-5--event-as-of-dates); [`macos-client-patterns.md` § 9](../../../../macos-client-patterns.md#9-window-widths-regular-and-wide); plan [`../prs/S16-42-event-dating-line.md`](../../prs/S16-42-event-dating-line.md)
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

### This brief is an enhancement

Draw as a new turn "S16-D4 · Event dates" on the Events list board, starting from its agreed list frames (Regular and Wide). Add rows. Do not redraw the list's toolbar, columns, row layout or titles. Only the date text of the events named below changes.

---

## 1. Objective

An event can now record **As of** dates: a day a lasting fact (a residence, an occupation) was known to be under way, without saying when it began or ended. An obituary of 10 Jan 1990 says "survived by X of Town Y"; a directory of 10 Feb 2015 lists X in Town Y. Today such an event shows no date anywhere and sorts last. After S16-42 every surface dates it from its earliest as-of to its latest, open on each side no start or end closes. (The Timeline's lifeline is S16-D7.)

This board decides **how the date line reads** in each dating case.

**What stays.** An event with a `date`, with a start and an end, with only a start or only an end reads exactly as today on every line. The line's place in each row, its type size and tone, the place after it and its "+N" stay. The Event page's Date row is not this board (S16-D6).

## 2. Domain facts

| Fact | Meaning for the board |
| --- | --- |
| Four date Properties on an event | `date` (when it happened), `start_date`, `end_date`, and `as_of` (any number). A date can be exact, About, Before, After, or a range, and can carry the source's words ("in the spring") |
| The engine sends one dating per event | Its kind (occurrence, span, as-of), its earliest and latest date (two dates however many as-ofs), and whether each side is open. The app formats that; it never sees the as-ofs themselves |
| Occurrence | A `date` wins: the event happened then. Shown as today: `14 May 1817`, `abt 1846`, `bef 1880` |
| Span | A start and/or an end, no as-of. Shown as today: `1985–2015`, or the one date recorded |
| As-of only | From the earliest as-of to the latest, **open on both sides**: the residence began at some unknown day before the first and ended at some unknown day after the last |
| As-of with a start, or an end | The start (or end) closes its side; the other side stays open beyond the as-of. `start 1985`, `as of 10 Jan 1990` → 1985 to 10 Jan 1990, open after |
| One as-of | One day, open on both sides |
| An as-of before the start, or after the end | Contradictory data. The line dates from the as-of, that side open; a notice for it is later work, not this board |
| Sort | An as-of event sorts at its earliest date (10 Jan 1990), between the events dated that day as any date does |
| VoiceOver | The row's own label speaks the date line; the line itself is hidden from VoiceOver. Whatever marks an open side must be in words, not only a glyph or a fade |

### 2.1 What this board is not

- Not the Event page's Date row, which lists each as-of with its records (S16-D6, PR S16-44).
- Not the date editor or the composer: As of is entered with today's date editor (S16-40).
- Not a notice when an as-of falls outside the researcher's start or end ([idea](../../../../ideas/event-as-of-followups.md)).
- Not a new layout for any row: only the date text changes.
- Not the Timeline's lifeline (S16-D7).

---

## 3. Implementation gate

| S16-42 ships | Not S16-42 |
| --- | --- |
| ED-1 – ED-7, ED-W1 | The Timeline lifeline (S16-D7, also S16-42); the Event page Date row (S16-44, S16-D6); an out-of-bounds as-of notice ([idea](../../../../ideas/event-as-of-followups.md)) |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| ED-1 | An occurrence and a span read exactly as today, on every surface: `14 May 1817`; `abt 1846`; `1985–2015`; a start alone `1985`; an end alone `2015`. Draw them as reference rows beside the new ones |
| ED-2 | **As-of only, two or more.** The line names both dates and shows that both sides are open. **The board decides** the wording. Recommendation: the word "as of" before the span, `as of 10 Jan 1990–10 Feb 2015`; other candidates to weigh: `… 10 Jan 1990–10 Feb 2015 …`, `known 10 Jan 1990–10 Feb 2015`. Words over glyphs, so VoiceOver says it (ED-7) |
| ED-3 | **One as-of.** The line names the one date and shows it is an attestation, not when it happened. Recommendation, consistent with ED-2: `as of 10 Jan 1990`. It must not read like an occurrence (`10 Jan 1990`) |
| ED-4 | **As-of with a start.** `start_date` 1985, as-ofs 10 Jan 1990 and 10 Feb 2015: closed at 1985, open after 10 Feb 2015. The board decides the wording; it must differ from the closed span `1985–10 Feb 2015` |
| ED-5 | **As-of with an end.** As-of 1990, `end_date` 2015: open before 1990, closed at 2015. Wording by the board, mirroring ED-4 |
| ED-6 | **Qualified as-ofs.** Each date keeps its own qualifier and the words the source gave, as today: as-ofs `abt 1990` and `bef 2015` read `as of abt 1990–bef 2015` (with the ED-2 recommendation). The open-side wording never replaces a date's own `bef` / `aft` |
| ED-7 | **Every surface reads the same line.** The Events list row, the Event page header's date and place line, the Timeline's event row, a search hit's second line, Promote's candidate menus and Promote's record rows all show the ED-1 – ED-6 text; the board draws the Events list row and names the others in a note. A long line truncates at its end as today; the place after it keeps its "+N". VoiceOver hears the row label with the same words |
| ED-W1 | The line's wording is the same at Regular and Wide. The Events list keeps the Wide arrangement already agreed; nothing moves between widths |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Events list | The list as agreed, the date and place on each row's second line | As agreed (the list keeps its maximum width, centred) | Nothing; only the date text of as-of rows changes |

---

## 5. Suggested frames

Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440); the others as they say.

| Frame | Requirement | Draw |
| --- | --- | --- |
| 1a / 1b | ED-1 – ED-6, ED-7, ED-W1 | Events list, sorted by date, with these rows in order: "Baptism of Anna Weber" `14 May 1817`; "Residence of John Smith" start 1985 and as-ofs 10 Jan 1990, 10 Feb 2015 (ED-4) in Town Y; "Residence of Mary Smith" as-of 10 Jan 1990 only (ED-3) in Town Y; "Residence of X" as-ofs 10 Jan 1990 and 10 Feb 2015 (ED-2) in Town Y; "Occupation of X" as-of abt 1990 and bef 2015 (ED-6); "Residence of Peter Smith" as-of 1990, end 2015 (ED-5); "Residence of Ruth Smith" start 1990, end 2015 (ED-1). Each as-of row sorts at its earliest date |
| 2 | ED-7 | Regular only: one row of each surface named in ED-7 with the ED-2 event, side by side, as a reference (Event page header line, Timeline row, search hit, Promote menu item, Promote record row) |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Date and place line | Component | Ship | `macos/App/DesignSystem/Components/DatePlaceLine/PVDatePlaceLine.swift` `PVDatePlaceLine` | Unchanged; it takes the date text S16-42 formats. No new parameter |
| Event secondary line | Snowflake | Ship | `macos/App/Features/Conclusions/EventsListView.swift` `EventSecondaryLine`, `EventSecondaryDisplay` | The Events list, Event page header, Timeline rows, search hits and Promote's menus build their line here; only where the date text comes from changes |
| Graph Event line | Snowflake | Extend | `macos/App/Features/Workspace/Session/EvidenceGraphSnapshot.swift` `EvidenceGraphPlacedSubject.dateLine` | Promote's record rows; reads the engine's dating for the graph Subject instead of its Observations |
| Row date text | Shared Platform formatter | Extend | `macos/App/Platform/DateRowDisplay.swift` `DateRowDisplay` | Formats the engine's dating (ED-1 – ED-6); the as-of wording is new `L10n.Dates` copy |
| List row | Component | Ship | `PVList` | Unchanged |

**Non-goals.** No new kit primitive, no badge or chip for "as of", no icon, no new color or token, no tooltip listing the as-ofs (the Event page Date row lists them, S16-44).

---

## 7. Handoff

When the board is agreed: record the turn, its frames, the ED-2 – ED-5 wording on the **Board** line here, in [`README.md`](README.md) and on the plan's **Board** line; the plan copies ED-1 – ED-7 and ED-W1 into its Scope and fills its Strings; it moves from `Blocked` to `Planned` when this board and S16-D7 are both agreed. When S16-42 lands, the brief moves to the spike's design archive.
