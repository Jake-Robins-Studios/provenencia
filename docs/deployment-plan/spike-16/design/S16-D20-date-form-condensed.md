# S16-D20 — The date form, condensed and keyboard-first

**Kind:** Claude Design board (**enhancement** of the shared date form as S16-D15 left it. The form keeps every control it has, takes less height in its own dialog and inline in another form, and turns its qualifier into a segmented control beside Kind)
**Spike:** Provenencia Spike 16 (odds and ends), batch 9, slice 9a
**View:** the shared date form, in three hosts: the Source date dialog (opened from a Source page header's date), the Add Source dialog's Published date field, and the Citation composer's inline value box for a date Property
**Implements later as:** PR **S16-83** (The date form is smaller and keyboard-first)
**Board:** — (to draw)
**Depends on:** the S16-D15 board as agreed 2026-11-28 and shipped in S16-73 (#1019): Add Source's order Title, Type | Private, Description, Published date; the date form's can't-be-saved lines; "Remove time"
**Related:** the Batch 9 working rules in [`../deployment-plan.md`](../deployment-plan.md#working-rules) ("One date form, every host", "The latest bound follows the earliest until it is typed into", "Remove time clears the time", "The date form's Tab starts at Year"); scope entry [S16-83](../deployment-plan.md#s16-83--the-date-form-is-smaller-and-keyboard-first); bar 52 and 54; feature doc [`../date-value-form.md`](../date-value-form.md); board S16-D16 (the Copy sheet, S16-74), drawn after this one on its frames; [`macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide)
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

Draw a new row "S16-D20 · Date form" on the *Dialogs* page, beside S16-D15's "Add Source" section. Start from the date form as the S16-D15 frames and the shipped app draw it (§ 1 describes it; draw it once as frame 0, the Source date dialog as it is today, and keep it only as the starting point). Then draw the condensed form in every frame below. Extend the S16-D15 Add Source frames with the condensed form; do not redraw the rest of Add Source. The Source page header, the Sources list and the composer around its value box stay as they are.

---

## 1. Objective

The shared date form is one view, drawn in every place the app edits a date. Top to bottom, it stacks:

1. **Kind.** A caption "Kind", then a segmented control **Single date** | **Between two bounds**. On a range, an italic line under it: "A single date somewhere in this window — not how long something lasted".
2. **Qualifier**, on a Single date only. A caption "Qualifier", then four separate chips: **As stated**, **About**, **Before**, **After**.
3. A divider.
4. **Each side.** A micro-caps heading ("Date", or on a range "Earliest — not before" and "Latest — not after") with an italic hint at the right, "Leave a part empty when the record does not say". Under it, **Year** (a short mono input), **Month** (a select: none, January … December) and **Day** (a short mono input), each with its own label above. Under them sits a link, **Add time…**, which opens a sunken block with **Hour**, **Min**, **Sec**, **Ms** and **Time zone**; the link then reads **Remove time** and clears that side's time. A range has a second side below the first.
5. A divider.
6. A link, **Calendar and phrase…**. It opens **Calendar** (a select) and **Phrase** (an input with the hint "A short gloss carried on the date itself — not the source's wording"), and then reads **Hide calendar and phrase**.

The Source date dialog and Add Source add a sunken **Reads as** strip under the form once the date parses ("Reads as  1 Jun 1880"). A field out of range shows its error under its side ("Month must be between 1 and 12."; a range's latest before its earliest has its own line). The host shows one more line when the date can't be saved and no field is to blame. In Add Source that line is the Published date field's error, for example "Add the latest bound."

In Add Source the form is most of the sheet; in the Source date dialog it is the whole dialog; in the composer's value box it is taller than everything else in the box.

**What changes:**

- **The form takes less height, in every host** (bar 52). Take room back by layout: Kind and the qualifier on one row, captions dropped where the control's own options already say what it is, no dividers, the side hint moved off the heading line, the time and the calendar-and-phrase links on one line. Those are suggestions. The board decides, and says under each frame how much height it saved against frame 0.
- **The qualifier becomes a segmented control**, the same kit control as Kind, with four segments: As stated | About | Before | After.
- **On a range, the latest bound follows the earliest.** As the researcher types the earliest year, month, day or time, the matching latest field takes the same value, until the researcher types into that latest field. A latest field already filled, typed or loaded from a saved range, keeps its value. So 1880 typed as the earliest year reads 1880 to 1880 at once.
- **Typing a date starts at Year** (bar 54). Tab into the form lands on Year, then Month, Day, and the time fields when shown, then leaves the form. Shift-Tab from Year goes to the qualifier (on a Single date), then to Kind; Tab from Kind comes back to Year. The board draws this loop as an annotated frame. It does not change the layout's reading order.

**What stays:** every control and option listed above, with its words; Remove time clearing the time; the errors and their words; Reads as; the hosts around the form (the dialog's title "Published date", subtitle "When the record was made or first published.", **Clear date** for a Source that has a date, **Cancel** and **Save**; Add Source's other fields; the composer's box).

---

## 2. Domain facts

| Fact | What it means on this board |
| --- | --- |
| A genealogical date | Any part may be missing: 1880, June 1880 and 1 Jun 1880 are all whole dates. A phrase alone ("Michaelmas term") is a date too. The form never asks for a full day. |
| Single date and Between two bounds | A Single date is one moment, possibly hedged with About, Before or After. Between two bounds is one moment somewhere inside a window. It is not a span or a duration, and it takes no qualifier. |
| The latest bound follows the earliest | Most ranges share most of their parts (1880 to 1881; June to August 1880). Mirroring the earliest side's parts saves typing and keeps the range whole while it is typed. Only the parts that differ are typed on the latest side. |
| Remove time | Clears that side's hour, minute, second, millisecond and time zone. A value hidden from view never stays in the date. |
| Can't-be-saved lines | Shown by the host, not the form: a range with no earliest bound ("Add the earliest bound."), no latest bound ("Add the latest bound, or choose Single date."), a time zone or millisecond with no date or time. Field errors (month 13) are the form's own. |
| Reads as | The date as the Source page header will word it, in a sunken strip under the form. The Source date dialog and Add Source show it; the composer does not. |
| Keyboard-first | Nine dates in ten are typed straight into Year, Month and Day. Kind and the qualifier are set less often, and stay one Shift-Tab away. |

### 2.1 What this board is not

- The Copy Source dialog (S16-D16, drawn later on these frames).
- A marks control (Unknown, Supplied) for the date (S15-D23).
- A new date control, a calendar picker, or a date typed as one free-text field.
- Changes to Add Source's other fields, the Source page header or the composer outside its value box.
- Type-select in the Month select (J, J, J walking January, June, July). S16-83 ships it in the kit, and nothing about it is visible on a still frame.

---

## 3. Implementation gate

| S16-83 ships | Not S16-83 |
| --- | --- |
| DF-1 – DF-10, DF-W1 | The Copy sheet's fields (S16-74); a marks control (S15-42); keyboard focus for the Reads as strip |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| DF-1 | **One form.** Draw one condensed form and instance it in all three hosts (frames 1–9). Annotate it "Date form (shared: Source date, Add Source, Copy Source, composer)". No host draws its own variant; the composer's box may only be narrower. |
| DF-2 | **Kind and qualifier.** Two kit segmented controls: **Kind** (Single date / Between two bounds) and, on a Single date, **Qualifier** (As stated / About / Before / After), on one row when the form's width allows, otherwise stacked. Both keep an accessible name ("Kind", "Qualifier") even if their visible caption goes. On a range the qualifier is gone, and the range gloss ("A single date somewhere in this window — not how long something lasted") stays reachable: as a field hint, a help icon (the kit's HelpIcon, which opens on hover, Tab and Space), or a line. The board picks one. |
| DF-3 | **The parts.** Year, Month and Day stay three controls (Input, Select, Input) at their current widths or narrower. A range's two sides stay one row each, labelled so the researcher can tell earliest from latest ("Earliest — not before", "Latest — not after", or a shorter wording the board proposes for the user to approve). The hint "Leave a part empty when the record does not say" stays on the form, but not on each side's heading line. |
| DF-4 | **Latest follows earliest.** Frame 3 shows a range with only the earliest year typed (1880): the latest year shows 1880, drawn as an ordinary value. Frame 4 shows the latest year then typed as 1881, and the earliest month June mirrored into the latest month while the latest year keeps 1881. If the board thinks a mirrored value should look different from a typed one, it draws both and the user chooses. |
| DF-5 | **Time.** Each side keeps its **Add time…** / **Remove time** link and its time block (Hour, Min, Sec, Ms, Time zone), drawn more compactly if the board can (for example, one row). |
| DF-6 | **Calendar and phrase.** The **Calendar and phrase…** link stays, on the same line as the time link where the board can fit it, and opens Calendar and Phrase with the phrase's hint. |
| DF-7 | **Errors.** A field error shows under its side, as today (frame 6). The host's can't-be-saved line shows as today: in Add Source as the Published date field's error (frame 8). Neither moves the layout more than one line. |
| DF-8 | **Reads as.** The strip stays under the form in the Source date dialog and Add Source, once the date parses. |
| DF-9 | **Tab order.** Frame 10 annotates the loop on a Single date with time shown, in Add Source. The numbered stops are Description → **Year** → Month → Day → Hour → Min → Sec → Ms → Time zone → (out: the dialog's buttons). The Shift-Tab arrows run Year → **Qualifier** → **Kind**, and Tab from Kind runs → Year. Each segmented control is one stop, with ← and → between its options. The board marks two stops as **open (plan decides)**: where a range's latest side and the Calendar and Phrase fields fall in the loop, and whether the two links are stops. It does not decide them. |
| DF-10 | **Source date dialog.** The dialog keeps its title, subtitle, Clear date, Cancel and Save. Its width (560 pt today) may come down if the condensed form allows; the board says the width it draws. |
| DF-W1 | **Wide.** Every host is a modal (the two dialogs) or sits in a page column (the composer). At Wide each is the same size as at Regular: the dialogs centered over the page, the composer's box in its column. Nothing moves between widths. |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Source date dialog | A FormDialog centered over the Source page, the condensed form inside | The same dialog, centered | Nothing (DF-W1): a short form keeps its measure (rule 2) |
| Add Source dialog | The 560 pt FormDialog over the Sources list, with the date form inline after Description | The same dialog, centered | Nothing (DF-W1) |
| Composer value box | The date form in the composer's authoring column | The same box; the column keeps its width | Nothing (DF-W1) |

---

## 5. Suggested frames

Draw at Regular (pane 1102 × 900), the host's page dimmed behind a dialog; frames 1 and 7 also at Wide (pane 2296 × 1440). Use the Source "1880 census, Ward 4, Altona" of type Census. Under each frame, note how much height it saved against frame 0.

| Frame | Requirement | What it shows |
| --- | --- | --- |
| 0 | — | Today's Source date dialog with a blank Single date, drawn from § 1 as the starting point only |
| 1a / 1b | DF-1, DF-2, DF-3, DF-10, DF-W1 | The condensed Source date dialog, blank Single date, focus on Year. Regular and Wide |
| 2 | DF-2, DF-3, DF-8 | Filled: About, 1 Jun 1880; Reads as "abt 1 Jun 1880" (the header's words) |
| 3 | DF-2, DF-4 | Between two bounds with only the earliest year typed (1880); the latest year shows 1880; the range gloss as DF-2's choice |
| 4 | DF-4, DF-5 | Between two bounds: earliest June 1880, latest 1881, the latest month mirrored to June; time shown on the earliest side (14:30, Europe/London) |
| 5 | DF-6 | Calendar and phrase open on a Single date (Calendar Gregorian, Phrase "Michaelmas term") |
| 6 | DF-7 | A field error: Month 13, the error under the side, Save disabled |
| 7a / 7b | DF-1, DF-W1 | Add Source with the condensed form inline after Description, blank. Regular and Wide |
| 8 | DF-7 | Add Source on a range whose latest side was cleared: the field error "Add the latest bound, or choose Single date.", Create disabled |
| 9 | DF-1 | The composer's value box for a date Property, at about 400 pt wide (the plan checks the real width): a Single date, 1880 |
| 10 | DF-9 | Frame 7a with time shown, annotated with the numbered Tab stops and the Shift-Tab arrows, and the two open stops marked |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Date form | Snowflake | Extend | `macos/App/Features/Dates/DateValueEditorForm.swift` `DateValueEditorForm` | The one form, condensed (DF-1); owns its Tab loop (DF-9) |
| Date draft | — | Extend | `macos/App/Platform/DateValueDraft.swift` | Remembers which latest fields were typed, for DF-4 |
| Kind | Component | Ship | `PVSegmentedControl` (`macos/App/DesignSystem/Components/Chip/PVSegmentedControl.swift`) | Unchanged control; one Tab stop |
| Qualifier | Component | Rethink | `PVSegmentedControl`, replacing the `PVChipGroup` of four `PVChip`s | Same control as Kind (DF-2); one Tab stop, ← / → between options |
| Year, Day, time fields | Component | Ship | `PVField` + `PVInput` (size sm, mono) | Narrower if the board wants; no new input |
| Month, Calendar | Component | Ship | `PVSelect` (size sm) | Unchanged |
| Time block | Snowflake | Extend | inside `DateValueEditorForm` | A sunken group; a tighter arrangement only |
| Add time / Remove time, Calendar and phrase links | Component | Ship | `PVButton` link style, as today | One line if they fit (DF-5, DF-6) |
| Range gloss and leave-empty hint | Component | Extend | `PVField` hint, or `PVHelpIcon` (`macos/App/DesignSystem/Components/HelpIcon/PVHelpIcon.swift`) | DF-2, DF-3: the board picks one, not a new control |
| Field errors | Component | Ship | `PVErrorText` | Unchanged words and place |
| Can't-be-saved line | Component | Ship | the host's `PVField` `error:` (Add Source's Published date) | Unchanged |
| Reads as | Snowflake | Ship | `macos/App/Features/Sources/SourceDateEditor.swift` | Unchanged |
| Source date dialog | Snowflake | Extend | `macos/App/Features/Sources/SourceDateDialog.swift` | Width may come down (DF-10) |
| Add Source fields | Snowflake | Ship | `macos/App/Features/Sources/SourceFields.swift` | Takes the condensed form; its order from S16-D15 is unchanged |
| Composer value box | Snowflake | Ship | `macos/App/Features/CitationComposer/CitationComposerAuthoringBox.swift` `inlineValue` | Hosts the same form (DF-1) |
| Copy | — | Remove / Extend | `macos/App/Platform/L10n.swift`, `Localizable.xcstrings` | Captions and headings the board drops are removed (or kept as accessible names); any new shorter side label is new copy for the user to approve |

**Non-goals.** No new kit primitive. No calendar popover. No free-text date entry. No disclosure that hides Year, Month and Day. No per-host variant of the form. No change to the errors' words.

---

## 7. Handoff

When the board is agreed, write its choices into DF-2 (the range gloss), DF-3 (the side labels and the hint's home), DF-4 (mirrored values' look), DF-10 (the dialog's width) and the **Board** line with the frame names. The S16-83 plan ([`plan-pr`](../../../../.agents/skills/plan-pr/SKILL.md)) copies DF-1 – DF-10 and DF-W1 into its Scope and this inventory into its design, and moves from `Blocked — on board S16-D20` to `Planned`. When S16-83 lands, the brief moves to the spike's design archive. S16-D16 draws the Copy sheet on these frames.
