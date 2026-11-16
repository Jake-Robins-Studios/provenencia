# S16-D3 — Citation composer: the date editor on an As of observation

**Kind:** Claude Design board (**enhancement** of the citation composer: the date editor inside the authoring box, for one Property. Extend the composer frames left by the S15-D8 turn; everything else is unchanged)
**Spike:** Provenencia Spike 16 (odds and ends), Batch 5
**View:** the citation composer (`CitationComposerView`): the authoring box's Value field when the chosen Property is **As of** (`CitationPropertyFields`, `DateValueEditorForm`)
**Implements later as:** PR **S16-40** (An event records when it was known to be under way)
**Board:** not drawn yet — to be drawn on [Claude Design — Citation Composer](https://claude.ai/artifact/3GSFQZjqdQjL8v2rpgMiDc), page *Citation Composer*, as a new section "S16-D3 · As of"
**Depends on:** the agreed S15-D8 turn on the same board (the composer on Regular and Wide). The date editor is the one the Source page's date dialog and the composer already share (`macos/App/Features/Dates/DateValueEditorForm.swift`)
**Related:** Batch 5 working rules in [`../deployment-plan.md`](../deployment-plan.md#batch-5--event-as-of-dates); [`../event-as-of.md`](../event-as-of.md); [`structured-date-model.md`](../../../structured-date-model.md); [`macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide)
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

Extend the citation composer as the S15-D8 turn left it. The file viewer, the locator strip, the citation form, the Observations column and its width, the Artifact and Citation menus, the edit dialog, and the authoring box's Subject, Property, Negative and Save controls all stay. One thing changes: when the authoring box's Property is **As of**, its date editor offers fewer qualifiers.

---

## 1. Objective

A record often shows that a lasting event was under way on one day without saying when it began or ended: an obituary of 10 Jan 1990 says a son lived "of Town Y". The researcher records that on the son's residence as **As of 10 Jan 1990**, a new event date beside Date, Start date and End date. Several as-ofs sit on one event (a directory of 2015 adds another), and none of them says when the residence began or ended.

On an As of observation, the date editor offers **As stated** and **About**, as a point or a range. It does not offer **Before** or **After**: those say the event began or ended around then, which is what Start date and End date are for. Every other date Property keeps all four qualifiers.

**What stays.** The date editor's layout, its Kind control (Point, Range), its year, month and day fields, its time and phrase section, and its copy. The Property menu lists As of like any other Property (its label, its key as subtext). The Source page's date dialog is not on this board and does not change.

## 2. Domain facts

| Fact | Means for the board |
| --- | --- |
| As of is a seeded event Property: key `as_of`, label "As of", value type date, more than one allowed | It appears in the Property menu for an Event Subject, after End date |
| A date is one moment: a point (with a qualifier) or a range (between two bounds, no qualifier) | Range hides the qualifier row today; it still does |
| The qualifiers are As stated (exact), About, Before, After | As of offers the first two |
| A date written outside the composer (an import, an older edit) can already hold Before or After on As of | The editor shows that chip, selected, so opening and saving never changes the value silently |
| Each observation holds one value; a second as-of is a second observation | No multi-value control in the editor |

### 2.1 What this board is not

- No new date editor, no As of–specific control, no hint or help line about what As of means.
- No change to the Event page, the Events list or the Timeline (later briefs S16-D4, S16-D5).
- No change for Date, Start date, End date or any researcher-created date Property.
- No warning when a researcher picks a Before or After that is already stored; the chip is simply shown.

## 3. Implementation gate

| Ships in S16-40 | Not in S16-40 |
| --- | --- |
| As of in the Property menu (from the seed, no new control) | Event page Date row (S16-42) |
| Qualifier row with As stated and About on As of | Lifeline span (S16-43) |
| A stored Before or After on As of shown selected | Any change to the Source date dialog |

## 4. Requirements

- **AO-1.** With Property **As of** and Kind **Point**, the qualifier row shows two chips: As stated, About. Before and After are absent, not disabled.
- **AO-2.** With Property **As of** and Kind **Range**, the editor looks as any range does today: no qualifier row.
- **AO-3.** Editing an As of observation whose stored qualifier is Before (or After) shows three chips: As stated, About and that one, selected. Picking As stated or About removes the extra chip on the next draw.
- **AO-4.** The qualifier row follows the Property chosen now: switching an open draft from Start date, with Before selected, to As of keeps Before shown and selected, as AO-3. The composer's handling of the typed date on a Property switch is unchanged.
- **AO-5.** Every other date Property shows the four chips, as today.

### 4.1 Wide layout

| View | Regular | Wide | What moves |
| --- | --- | --- | --- |
| Citation composer, authoring box | The authoring box in the 520pt Observations column | The same box in the same 520pt column | Nothing: the change is inside a form that keeps its measure (rule 2) |

- **AO-W1.** At Wide the authoring box and its date editor keep their Regular width; the qualifier row is the same two chips.

## 5. Suggested frames

- **Frame 1a** Regular pane 1102 × 900: an image Citation open, an Event Subject chosen, Property As of, Kind Point, As stated selected, 10 Jan 1990 typed.
- **Frame 1b** Wide pane 2296 × 1440: the same.
- **Frame 2** (box only): Property As of, Kind Range, 1990 to 1992.
- **Frame 3** (box only): editing an As of observation stored as Before 1990: As stated, About, Before (selected).
- **Frame 4** (box only, reference): Property Start date, Kind Point: the four chips, unchanged.

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Date editor | Snowflake | Extend | `macos/App/Features/Dates/DateValueEditorForm.swift` (`qualifierSection`) | Shows a chip for Before and After only when the caller allows them or the draft holds one |
| Qualifier chips | Component | Ship | `PVChipGroup` + `PVChip` (`DesignSystem/Components/Chip/`) | The same chips; fewer of them. No Segmented control swap |
| Property field | Snowflake | Ship (unchanged) | `CitationPropertyFields` (`CitationComposerAuthoringBox.swift`) | Passes whether the Property is As of |
| Property menu | Component | Ship (unchanged) | `PVComboBox` in `CitationComposerAuthoringBox.propertyOptions` | Lists As of from the seed |

**Non-goals.** No new kit primitive. No disabled chips. No explanation copy. No change to the Kind control or the cascade fields.

---

## 7. Handoff

When the board is agreed: record the board's link, its frames and any decision on the **Board** line here and in [`README.md`](README.md). S16-40's plan copies AO-1 – AO-5 and AO-W1 and the inventory, and moves from `Blocked — on board S16-D3` to `Planned`. When S16-40 lands, this brief moves to `design/archive/`.
