# S16-83 — The date form is smaller and keyboard-first

**Status:** Draft
**Spike / slice:** Spike 16 · Slice 9a — The date form
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S16-D20](../design/S16-D20-date-form-condensed.md), board agreed 2026-11-28
**Board:** the Provenencia design system artifact (`https://claude.ai/artifact/7AZ8cscWF3f5Wz7gQ39cMe`), template "DateValue editor". The brief's **Board** line lists what it decides, and **Design → macOS** below describes every part of it in words, so this plan does not need the artifact open. Where the board and this plan differ (no field fills itself in, no Stored as / Reads as), this plan wins: the user dropped both after the board
**Depends on:** S16-73 (landed [#1019](https://github.com/Jake-Robins-Studios/provenencia/pull/1019)), S16-D20 (agreed 2026-11-28)
**Blocks:** S16-74
**Branch:** `s16-83-date-form-condensed`
**Version bump:** patch — a UI polish and a kit keyboard fix, no schema or wire change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md), [`add-date-value`](../../../../.agents/skills/add-date-value/SKILL.md) (the draft's rules only; no Go change)
**Rules that bind:** `docs/design-system-layers.md`; `macos/App/DesignSystem/README.md` (Field focus, SegmentedControl, Button rows)
**Context:** [feature doc](../date-value-form.md), working rules: "One date form, every host", "The latest bound is typed, never filled in", "The time fields always show", "The date form shows no Reads as", "A kit button takes the field focus handle", "A repeated letter walks its matches", "The date form's Tab starts at Year"; bar 52 – 54
**Planned:** 2026-11-28 against `main` @ `a39185a`
**Review:** — (not reviewed yet)

### Implementer — read this first

1. **This file is the whole task.** Read it top to bottom before you change code. Then read every file under **Current state** and load every skill under **Skills to load**.
2. **Check the base.** Compare `main` with the **Planned** commit. If a file under **Current state** has changed so a row is no longer true, stop and report which rows.
3. **Decisions are made.** Do not reopen a **Decision** or a **Scope** line, and do not swap in a design you like better. If one cannot work, stop: say which ID it is, what you found (path, line, output), and what you would need. Do not improvise around it.
4. **Do only In.** Out stays out, even when it is one line away. Do not refactor, rename, or tidy code the plan does not name.
5. **Work the Steps in order.** Run each step's check before you start the next. A failing check is fixed in that step.
6. **Hit a Stop condition → stop.** Report it. Do not work around it.
7. **Done is the Definition of done.** Report each box with its evidence: the command and its result, the test name, or the manual check you ran.
8. **Docs-only lines in the DoD are part of the PR.** Do not skip them.

---

## 1. Objective

The shared date form takes less height in every host and is typed from the keyboard: Tab lands on Year, the time fields are always on the form, and Kind and the qualifier sit one Shift-Tab behind Year. In any kit select, menu or table, pressing one letter quickly several times walks the options that start with it (J, J, J → January, June, July). From the user's Batch 9 notes (bar 52 – 54) and the S16-D20 board.

**Why now.** The date form is most of the Add Source sheet, and S16-74 puts it in the Copy sheet next; it should be small and keyboard-first before a third host takes it.

**What stays.** Every value a researcher can set today, the field errors and their words, the host's can't-be-saved line in Add Source, Clear date and the refused-save callout in the Source date dialog, the composer's value box, and `SourceDateText` for the Source page header.

## 2. User stories

**US-1.** As a researcher, when I open the Source date dialog or Add Source, I see a shorter date form so that the sheet fits without scrolling.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Source date dialog, blank Single date | Kind (Single date / Between two bounds) and the qualifier (As stated / About / Before / After) are two segmented controls on one row with no captions above them; then Year, Month, Day on one row; then Hour, Min, Sec, Ms, Time zone on one row; then one line "Leave a part empty when the record does not say" with **Calendar and phrase…** after it. No divider, no "Date" heading, no Add time link, no Reads as. The dialog is 520 pt wide |
| AC-1.2 | Choose Between two bounds | The qualifier goes; the line "A single date somewhere in this window — not how long something lasted" shows under the Kind row; two sides show, each labelled in a left column "Earliest" over "not before" and "Latest" over "not after", each with its date row and time row |
| AC-1.3 | Range, earliest year 1880 typed, latest empty | The latest fields stay empty; Add Source shows "Add the latest bound, or choose Single date." under the form, as today |
| AC-1.4 | Day 32 on a Single date | "Day must be between 1 and 31." under that side; Save disabled |
| AC-1.5 | Load a saved date with only a time zone (Europe/London) | The Time zone field shows Europe/London; nothing is hidden |
| AC-1.6 | Click **Calendar and phrase…** | Calendar and Phrase show under that line and the link reads **Hide calendar and phrase**; VoiceOver reports expanded |

**US-2.** As a researcher typing a date, I Tab straight into Year and through the parts, and reach Kind and the qualifier with Shift-Tab, so that nine dates in ten take no mouse.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Add Source, focus in Description, press Tab | Focus is on Year |
| AC-2.2 | Single date, Tab from Year repeatedly | Month → Day → Hour → Min → Sec → Ms → Time zone → Calendar and phrase… → out of the form (the system key loop: the sheet's buttons with Full Keyboard Access, else the first field) |
| AC-2.3 | Range, Tab from the earliest Time zone | Latest Year → Month → … → latest Time zone → Calendar and phrase… |
| AC-2.4 | Calendar and phrase open, Tab from the link | Calendar → Phrase → out |
| AC-2.5 | Single date, Shift-Tab from Year | Qualifier, then Kind; on a range Shift-Tab from Year goes straight to Kind |
| AC-2.6 | Tab from Kind; Tab from the qualifier | Year in both cases |
| AC-2.7 | Shift-Tab from Kind in Add Source | Description. In the Source date dialog and the composer (no field before the form) the key goes to the system key loop |
| AC-2.8 | Focus on the qualifier, press → | About is chosen, focus stays on the control; Space chooses the focused segment |
| AC-2.9 | Full Keyboard Access off | Every stop above is still reached |

**US-3.** As a researcher in any kit select, menu or table, I press one letter quickly several times to walk the items that start with it.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Month select on January, J J J within 0.8 s each | June, then July, then January |
| AC-3.2 | `["Aaron", "Abel", "Adam"]` from none, `a` `a` quickly | Aaron, then Abel (not a prefix search for "aa") |
| AC-3.3 | Table rows `["10", "11", "12"]` on `10`, `1` `1` quickly | `11`, then `12` |
| AC-3.4 | `["January", "June", "July"]`, `j` `j` `o` quickly | -1 (`jjo` is a prefix search) |
| AC-3.5 | `["Jane", "Jones"]`, `j` `o` quickly | Jones (a buffer of different letters stays a prefix search, as today) |

## 3. Scope

| In | Covered by |
| --- | --- |
| DF-1 one form in every host; no host variant | STEP-5, STEP-7, AC-1.1 |
| DF-2 Kind and the qualifier as two segmented controls on one row, the range gloss as a caption line | STEP-5, AC-1.1, AC-1.2 |
| DF-3 the parts' rows, the side labels in a left column, the hint on the link's line | STEP-5, AC-1.1, AC-1.2 |
| DF-5 time fields always shown, Sec and Ms on the latest side too | STEP-4, STEP-5, AC-1.5 |
| DF-6 Calendar and phrase… as a `PVButton` link | STEP-3, STEP-5, AC-1.6 |
| DF-7 field errors one line under their side; Add Source's can't-be-saved line unchanged | STEP-5, AC-1.3, AC-1.4 |
| DF-8 dropped: Reads as goes (`SourceDateEditor` deleted) | STEP-7 |
| DF-9 the Tab loop | STEP-2, STEP-3, STEP-6, STEP-7, US-2 |
| DF-10 the Source date dialog at 520 pt | STEP-7, AC-1.1 |
| DF-W1 every host a modal, the same at Regular and Wide | STEP-7, §10 |
| `PVTypeSelectMatcher` walks a repeated letter | STEP-1, US-3 |
| `PVFieldFocus` neighbour replacement; `PVSegmentedControl` and `PVButton` claim Tab | STEP-2, STEP-3 |

| Out | Home |
| --- | --- |
| DF-4 the latest bound following the earliest, and filling the latest side on switching to Between | not planned (user, 2026-11-28: working rule "The latest bound is typed, never filled in") |
| The Copy sheet's own fields and its focus order | S16-74 (inherits the form and `SourceFields`' order) |
| A marks control on the date (No date, Supplied) | S15-42 |
| Type-select in `PVList` | not planned (the list has none; feature doc) |
| Per-side accessible names on each part ("Earliest, year") | not planned (fields read their part's name, "Year", today; the side group carries the side's name, D-6) |
| A chevron or `PVDisclosureButton` for Calendar and phrase… | not planned (the board draws a text link whose words change) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Form | `macos/App/Features/Dates/DateValueEditorForm.swift` `DateValueEditorForm` | Stacks a captioned Kind `PVSegmentedControl`, a captioned qualifier `PVChipGroup` of four `PVChip`s, three `PVDivider`s, a micro-caps heading per side with the hint on the first, captioned Year / Month / Day, an Add time / Remove time plain button and a sunken `timeBlock` (latest side has no Sec / Ms), a plain-button Calendar and phrase toggle. Two `@FocusState` Bools (`startHourFocused`, `endHourFocused`) serve the time toggle. `yearFocus: PVFieldFocus?` is the host's handle on the earliest Year; no other field has a handle, so Kind, the chips and the links are Tab stops only with Full Keyboard Access, before Year |
| Draft | `macos/App/Platform/DateValueDraft.swift` `DateValueDraft` | `showStartTime`, `showEndTime`, `hideTime(start:)` hide and clear time; `init(from:)` sets the show flags. `applyStartCascade()` / `applyEndCascade()` are no-ops every binding calls. `canSetStart*`, `canSetEnd*`, `hasFullStartDay`, `hasFullEndDay` have no caller. `setKind` clears the qualifier (to range) or the end side and `showEndTime` (to point) |
| Reads as | `macos/App/Features/Sources/SourceDateEditor.swift` `SourceDateEditor` | Wraps the form and adds the sunken Reads as card (`L10n.Sources.sourceDateReadsAs`); its only job besides the pass-through |
| Source date dialog | `macos/App/Features/Sources/SourceDateDialog.swift` `SourceDateDialogModifier`, `SourceDateForm` | Width `SourceFields.dialogWidth` (560); `SourceDateForm` holds `@FocusState Field { year }`, claims Year on appear, passes `PVFieldFocus($focus, equals: .year)` |
| Add Source fields | `macos/App/Features/Sources/SourceFields.swift` `SourceFields` | No focus state: Description's `PVInput` has no handle, the date form gets no `yearFocus`, so Tab from Description goes by the system order. Doc comment lists `.date.readsAs` |
| Composer | `macos/App/Features/CitationComposer/CitationComposerAuthoringBox.swift` `inlineValue`, `case .date` | Hosts `DateValueEditorForm` directly with `yearFocus: PVFieldFocus(focus, equals: .value)`; `CitationAuthoringNavigation.next(after: .property)` already sends Tab to `.value`, so Tab lands on Year today. No change needed beyond the form |
| Field focus | `macos/App/DesignSystem/Components/Input/PVFieldFocus.swift` `PVFieldFocus` | Neighbours come only from `init(_:equals:in:)`; nothing can replace a handle's `next` / `previous` |
| Focus claim | `macos/App/Platform/FocusClaim.swift` `FocusClaim.claim(_:_:then:)` | Deferred two-turn write for a `FocusState` binding only, not for a `PVFieldFocus` |
| Segmented control | `macos/App/DesignSystem/Components/Chip/PVSegmentedControl.swift` `segment(_:)` | With a handle the focus target is one stop with Space and ← / →, and "does not read the handle's `next` / `previous`": no Tab claim |
| Button | `macos/App/DesignSystem/Components/Button/PVButton.swift` `PVButton` | No focus parameter: a Tab stop only with Full Keyboard Access |
| Type-select | `macos/App/DesignSystem/Components/FloatingMenuSelection/PVFloatingMenuSelection.swift` `PVTypeSelectMatcher.advance` | `jj` is a prefix search from the current row and matches nothing; callers `PVSelectSession.applyTypeSelect`, `PVContextMenu` `applyTypeSelect`, `PVTable` (line ~434) |
| Tests | `macos/ProvenenciaTests/DateValueDraftTests.swift` `hidingTimeClearsIt`, `loadShowsTimeWithZoneOnly`, `applyStartCascadeDoesNotWipeIndependentFields`; `DateValueSelectTests.swift` (calls `applyStartCascade()` at lines 33, 42); `PVFieldFocusTests.swift`; `PVSegmentedControlTests.swift`; `PVFloatingMenuSelectionTests.swift` `typeSelectSkipsDisabledRows` | Cover what this PR deletes or extends |

**Precedent.** S16-73 ([#1019](https://github.com/Jake-Robins-Studios/provenencia/pull/1019)) last reshaped this form and `SourceFields`; copy its commit-per-behavior split. For a form owning a Tab order through `PVFieldFocus($focus, equals:, in: order)`, copy `macos/App/Features/Names/NameValueEditorForm.swift` (it takes a host `formFocus` and gives its own fields handles). For a kit field claiming Tab from its handle, copy `PVInputTabClaim` in `macos/App/DesignSystem/Components/Input/PVInput.swift` (`.onKeyPress(keys: [.tab, .backTab], phases: .down) { focus.claimTab(shift: press.key == .backTab) }`).

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | A type-select buffer made of one character repeated (`j`, `jj`, `jjj`, case-folded through `TextMatch.key`) searches for that single character from `current + 1`; any other buffer keeps today's prefix search from `max(0, current)`. The change is inside `PVTypeSelectMatcher.advance`, so its three callers gain it unchanged | Working rule "A repeated letter walks its matches"; one matcher, every caller | A per-caller rule — three copies |
| D-2 | `PVFieldFocus.replacingNeighbours(next:previous:)` *(new)* returns a copy of the handle with both claims replaced (nil clears one). `FocusClaim.claim(_ handle: PVFieldFocus)` *(new)* writes `handle.focus()` on the next main-queue turn and again a turn later if `!handle.isActive()`, as the binding overload does. A claim that lands on a handle the form does not own goes through it | The loop crosses the host's binding (Year) and the form's own (the rest) without hand-built closures in each host | Passing the host's `FocusState` binding into the form — the form would need the host's value type |
| D-3 | `PVInput.swift`'s private `PVInputTabClaim` moves to `PVFieldFocus.swift` as the internal `PVFieldTabClaim` *(renamed)*, unchanged (it claims only when the handle has a neighbour). `PVInput` and `PVSegmentedControl`'s focus target apply it; a handle with no neighbours adds nothing, so existing callers do not change | Kind and the qualifier must send Tab to Year; one claim modifier for every kit field | A second copy in the control |
| D-4 | `PVButton` gains `focus: PVFieldFocus? = nil` as its last parameter before `action`. With a handle the button is `.focusable()`, applies the handle, and applies `PVFieldTabClaim` (D-3); Space and Return press it (`.onKeyPress(.space)` / `.return` run `action`). With none it renders exactly as today. Its focus ring is the one it already draws | Working rule "A kit button takes the field focus handle" (user, 2026-11-28) | `PVDisclosureButton` — adds a chevron the board does not draw; a local focusable button in the form — a snowflake for a kit gap |
| D-5 | The form owns one `@FocusState private var focus: DateValueEditorForm.Field?` *(new enum)*: `kind`, `qualifier`, `startYear`, `startMonth`, `startDay`, `startHour`, `startMinute`, `startSecond`, `startMillisecond`, `startZone`, the same ten-minus-kind/qualifier for `end…`, `advancedToggle`, `calendar`, `phrase`. Year uses the host's `yearFocus` when given, else `.startYear`. The forward order is `DateValueEditorForm.tabOrder(isRange:isAdvancedOpen:)` *(new, static, pure)*: start parts, end parts on a range, `advancedToggle`, then `calendar`, `phrase` when open. Each field's handle is `PVFieldFocus($focus, equals: field, in: tabOrder)` with these replacements: the Year handle's `previous` is the qualifier on a Single date and Kind on a range, and its `next` is `.startMonth`; `.startMonth`'s `previous` claims the Year handle; the qualifier's `next` and Kind's `next` claim Year; the qualifier's `previous` is Kind; Kind's `previous` is the host Year handle's original `previous` (nil → key loop); the last field in `tabOrder` takes the host Year handle's original `next` (nil → key loop) | Working rule "The date form's Tab starts at Year"; the board's stop order; one order function the test reads | A Tab order per host — breaks "One date form, every host" |
| D-6 | Layout as **Design → macOS**: `ViewThatFits(in: .horizontal)` over an `HStack` and a `VStack` of the two segmented controls (both `size: .sm`), so the composer's narrow box stacks them. On a range each side is a group with `.accessibilityElement(children: .contain)` and the label `dateEarliestHeading` / `dateLatestHeading`; a Single date's side has no group label. Kind and the qualifier keep `dateKindLabel` / `dateQualifierLabel` as their `PVSegmentedControl` label (spoken, not drawn) | Board; accessible names stay (DF-2) | A fixed row — clips at 452 pt |
| D-7 | The qualifier is `PVSegmentedControl<String>` over `""`, `ABT`, `BEF`, `AFT`, the segments keeping today's identifiers `<prefix>.qualifier.exact|abt|bef|aft` | DF-2 | — |
| D-8 | The time fields always show on both sides; `DateValueDraft` loses `showStartTime`, `showEndTime` and `hideTime(start:)`; the latest side gains Sec and Ms. An empty time field is no time; validation and `toInput()` are unchanged | Working rule "The time fields always show" | — |
| D-9 | No field fills itself in. `setKind("range")` still only clears the qualifier; the latest side starts empty | Working rule "The latest bound is typed, never filled in" (user, 2026-11-28) | The board's mirroring — dropped by the user |
| D-10 | `SourceDateEditor` is deleted; the Source date dialog and `SourceFields` host `DateValueEditorForm` directly. Its doc sentence "The form shows its own field errors; the host shows any other line" moves to `DateValueEditorForm`'s doc comment | Working rule "The date form shows no Reads as"; the wrapper has no other job | Keeping an empty wrapper |
| D-11 | The Source date dialog's width is `SourceDateDialog.width = 520` *(new constant in `SourceDateDialog.swift`)*; `SourceFields.dialogWidth` stays 560 for Add Source and its doc comment drops "and the Source date dialog" | DF-10: a narrower width is the date dialog's alone | — |
| D-12 | `SourceFields` gains `@FocusState private var focus: Field?` with `enum Field { case description, date }` and the order `[.description, .date]`: Description's `PVInput` takes `PVFieldFocus($focus, equals: .description, in: order)`, the form takes `yearFocus: PVFieldFocus($focus, equals: .date, in: order)`. Title and Type stay outside this order | The field before the form claims Tab into Year (AC-2.1); Shift-Tab from Kind returns to Description (AC-2.7) | Ordering Title and Type too — S16-74 owns the sheet's full order |
| D-13 | The dead draft helpers go: `applyStartCascade()`, `applyEndCascade()` (and every call), `canSetStart*`, `canSetEnd*`, `hasFullStartDay`, `hasFullEndDay`. `CascadeComponent` keeps its name | They do nothing or have no caller; the bindings change here anyway | Renaming `CascadeComponent` — churn with no behavior |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `PVFieldFocus.replacingNeighbours(next:previous:)` *(new)* | func | `PVFieldFocus.init(_:equals:in:)` | The init builds neighbours from one binding's order; a host handle has none to give |
| `FocusClaim.claim(_ handle: PVFieldFocus)` *(new)* | func | `FocusClaim.claim(_:_:then:)` | Same deferred write, for a handle instead of a binding |
| `PVFieldTabClaim` *(renamed from `PVInputTabClaim`, moved to `PVFieldFocus.swift`)* | modifier | `PVInputTabClaim` | It is the claim itself, now shared by three kit fields |
| `PVButton(…, focus:)` *(new parameter)* | component param | `PVSegmentedControl(…, focus:)` | Extends the kit's one focus handle to buttons |
| `DateValueEditorForm.Field` *(new)*, `DateValueEditorForm.tabOrder(isRange:isAdvancedOpen:)` *(new)* | enum, static func | `NameValueEditorForm`'s own field enum and order | The date form's own fields |
| `SourceDateDialog.width` *(new)* | constant | `SourceFields.dialogWidth` | The two widths now differ (D-11) |
| `SourceFields.Field` *(new)* | enum | `SourceDateForm.Field` | Add Source's own focus |
| `L10n.Sources.dateEarliestShort` = "Earliest", `dateEarliestNote` = "not before", `dateLatestShort` = "Latest", `dateLatestNote` = "not after" *(new)* | keys | `dateEarliestHeading` ("Earliest — not before") | The board sets the label on two lines; the heading stays as the spoken name |
| `macos/ProvenenciaTests/DateValueEditorFormTests.swift` *(new)* | test file | `DateValueDraftTests.swift` | Tests the form's pure `tabOrder` |

**Builds on.** `PVFieldFocus` and its `claimTab(shift:)`; `PVInputTabClaim`'s key handling; `PVSegmentedControl`; `PVTypeSelectMatcher`; the design-system README's Field focus, SegmentedControl, Button and FloatingMenuSelection rows.

**Deletes.**
- `macos/App/Features/Sources/SourceDateEditor.swift` (whole file); `L10n.Sources.sourceDateReadsAs` and its catalog entry `sources.page.sourceDate.readsAs`.
- `DateValueDraft`: `showStartTime`, `showEndTime`, `hideTime(start:)`, `applyStartCascade()`, `applyEndCascade()`, the twelve `canSetStart*` and `canSetEnd*` properties (month to millisecond), `hasFullStartDay`, `hasFullEndDay`; the show flags in `empty()` and `init(from:)`.
- `DateValueEditorForm`: the captions above Kind and the qualifier, the qualifier's `PVChipGroup`, the three `PVDivider`s, the per-side micro-caps heading, the Add time / Remove time button and `timeBlock`'s sunken card, the plain-button `advancedToggle`, `startHourFocused` and `endHourFocused`, `cascadeField`'s `focused:` parameter (its last caller goes).
- L10n keys and catalog entries: `datePointHeading`, `dateAddTime`, `dateHideTime`.
- Tests: `hidingTimeClearsIt`, `loadShowsTimeWithZoneOnly`, `applyStartCascadeDoesNotWipeIndependentFields`; the two `applyStartCascade()` calls in `DateValueSelectTests.swift`.
- `SourceFields` doc comment's `.date.readsAs`; the `#Preview` title "Filled, Private, Reads as: frame 2" becomes "Filled, Private: frame 2".

**Next adds.** S16-74's Copy sheet takes `SourceFields` and inherits D-12's Description → Year claim. Any later dialog link or button joins a Tab order by passing `focus:` (D-4).

### Reach

| New path or state | Destination | Checked |
| --- | --- | --- |
| Tab into Year from Description (Add Source) | `DateValueEditorForm` Year | The form's own `focus` is nil there; the Year handle is the host's, so the first write lands on the host binding (D-5) |
| A loaded date with time and no Add time click | the always-shown time row | Fields show their value; nothing depends on the removed show flags (AC-1.5) |
| `PVButton` with a focus handle | every `PVButton` caller | Default `nil` keeps today's code path (every existing caller passes none) |
| `PVSegmentedControl` claiming Tab | every caller with a handle | `PVFieldTabClaim` adds nothing for a handle without neighbours; today's callers (the composer's Yes / No, and others with `focus:`) pass handles without neighbours |

### Scale

None — no write, list or loop changes; the form has at most 25 fields.

### Edges

- **Assumptions.** `PVTypeSelectMatcher.index` wraps and skips disabled rows; a single-character search from `current + 1` relies on that (T-1 covers wrap at July → January). The Tab claims assume a field's handle is applied only on the focused element: `PVSegmentedControl` applies it to the focus target only, and the claim sits on that same view.
- **Neighbors.** `aa` walks, `ab` is a prefix search (AC-3.2, AC-3.5); a pause between two J's starts a new single-character search from the current row, as today. On a Single date Year's `previous` is the qualifier; on a range it is Kind (AC-2.5). Calendar and Phrase join the order only while open (AC-2.4).
- **Removed inputs.** Switching range → point clears the end side as today, so `end…` fields leave the order with their views (D-5's order is recomputed from `isRange`). Closing Calendar and phrase removes `calendar` and `phrase` from the order; their values stay in the draft, as today.
- **Real data.** None — no table or seed drives a rule.
- **Untrusted size.** None — no data the app did not write.

### Schema

None — no catalog change.

### Go core

None — no engine change.

### FFI

None — no wire change.

### macOS

The board, in words (Regular and Wide identical: every host is a modal, DF-W1). Spacing is `PVSpacing` tokens; widths in pt.

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Kind + qualifier row | two `PVSegmentedControl(size: .sm)` in `ViewThatFits` (D-6) | `DateValueEditorForm` | Row spacing `space4`; no captions; under it on a range the gloss `dateKindRangeHint` (micro, italic, `textMuted`, as today) |
| A side | `VStack(spacing: space3)` of a date row and a time row | `DateValueEditorForm` | On a range a leading column 86 pt wide holds `dateEarliestShort` over `dateEarliestNote` (or Latest), caption size: the first `textSecondary` medium, the second micro italic `textMuted`; the rows sit after it. A Single date has no column |
| Date row | `PVInput(size: .sm, mono: true)` Year 64, `PVSelect` Month 124 (menu width 160), `PVInput` Day 48 | `DateValueEditorForm` | Each with today's micro caption above (`dateYear`, `dateMonth`, `dateDay`) |
| Time row | `PVInput(size: .sm, mono: true)` Hour, Min, Sec, Ms each 57; Time zone `PVInput(size: .sm)` filling the rest | `DateValueEditorForm` | Captions `dateHour`, `dateMinute`, `dateSecond`, `dateMillisecond`, `dateTimeZone`; both sides draw all five; no sunken card |
| Field error | `PVErrorText` | `DateValueEditorForm` | One line under its side, indented 86 pt on a range; identifiers unchanged |
| Hint + link line | `HStack`: `dateLeaveEmptyHint` (micro, italic, `textFaint`), `Spacer`, `PVButton(variant: .link, size: .sm, focus:)` titled `dateShowAdvanced` / `dateHideAdvanced` with `.pvExpandedState(draft.showAdvanced)` | `DateValueEditorForm` | Identifier `<prefix>.advancedToggle` unchanged |
| Calendar and Phrase | as today | `DateValueEditorForm` | Under the line when open; each takes its `Field` handle |
| Form stack | `VStack(alignment: .leading, spacing: space5)` | `DateValueEditorForm` | No `PVDivider` |
| Source date dialog | `pvFormDialog(width: SourceDateDialog.width)` | `SourceDateDialog.swift` | 520 pt; Clear date and callouts as today |
| Add Source | `SourceFields` | `SourceFields.swift` | 560 pt; the form inside the Published date `PVField` as today |
| Composer | unchanged call | `CitationComposerAuthoringBox.swift` | The row stacks in the 452 pt box |

States: blank, filled, range, open Calendar and phrase, field error (AC-1.*). Accessibility: Kind and the qualifier speak their labels; each range side speaks its full heading; the link reports expanded / collapsed.

### Strings

L10n keys *(new)*: `L10n.Sources.dateEarliestShort` = "Earliest", `dateEarliestNote` = "not before", `dateLatestShort` = "Latest", `dateLatestNote` = "not after" (catalog keys `sources.page.dateEarliestShort`, `.dateEarliestNote`, `.dateLatestShort`, `.dateLatestNote`). Removed: `datePointHeading`, `dateAddTime`, `dateHideTime`, `sourceDateReadsAs`. Kept: `dateKindLabel`, `dateQualifierLabel` (spoken), `dateEarliestHeading`, `dateLatestHeading` (spoken), `dateKindRangeHint`, `dateLeaveEmptyHint`.

## 7. Steps

**STEP-1 — A repeated letter walks its matches**
Files: `PVFloatingMenuSelection.swift`, `macos/ProvenenciaTests/PVFloatingMenuSelectionTests.swift`, `macos/App/DesignSystem/README.md` (FloatingMenuSelection row, the table keys table, the Select contract's closed keys). Skill: `add-swift-test`.
Do: D-1 in `advance`; update its doc comment; T-1, T-2.
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/PVFloatingMenuSelectionTests` passes.

**STEP-2 — Field focus handles can be rewired, and segmented controls claim Tab**
Files: `PVFieldFocus.swift`, `FocusClaim.swift`, `PVInput.swift`, `PVSegmentedControl.swift`, `PVFieldFocusTests.swift`, README Field focus and SegmentedControl rows, `.agents/skills/add-ui-component/SKILL.md` field-focus line ("a handle's neighbours can be replaced"). Skill: `add-ui-component`.
Do: D-2, D-3; remove "does not read the handle's `next` / `previous`" from the control's doc and README row; T-3, T-4.
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/PVFieldFocusTests` passes, and Tab still moves between fields in a form that orders them (the composer's Subject → Property).

**STEP-3 — A kit button takes a focus handle**
Files: `PVButton.swift`, README Button row. Skill: `add-ui-component`.
Do: D-4.
Check: the app builds with no warning; the button previews render as before.

**STEP-4 — The draft has no hidden time and no dead helpers**
Files: `DateValueDraft.swift`, `DateValueDraftTests.swift`, `DateValueSelectTests.swift`. Skill: `add-date-value`.
Do: D-8, D-9, D-13; delete the three tests in Deletes; T-5.
Check: `DateValueDraftTests` and `DateValueSelectTests` pass. The form does not compile until STEP-5; do STEP-4 and STEP-5 in one commit.

**STEP-5 — The condensed form**
Files: `DateValueEditorForm.swift`, `L10n.swift`, `Localizable.xcstrings`. Skills: `add-ui-component`, `add-localized-string`.
Do: the layout in **Design → macOS**; D-6, D-7; the strings in §6 Strings.
Check: the app builds with no warning; the `#Preview`s of `SourceFields` render (Xcode previews or a run).

**STEP-6 — The form's Tab loop**
Files: `DateValueEditorForm.swift`, `macos/ProvenenciaTests/DateValueEditorFormTests.swift` *(new)*.
Do: D-5; T-6.
Check: `DateValueEditorFormTests` passes.

**STEP-7 — The hosts**
Files: `SourceDateEditor.swift` (delete), `SourceDateDialog.swift`, `SourceFields.swift`, `L10n.swift`, `Localizable.xcstrings`.
Do: D-10, D-11, D-12; remove `sourceDateReadsAs`.
Check: `scripts/check-pr.sh` prints `check-pr: PASS`; the manual check §10 passes.

**STEP-8 — Docs**
Files: `docs/deployment-plan/spike-16/completed.md`, `deployment-plan.md` (map row), this plan (status), `design/S16-D20-date-form-condensed.md` → `design/archive/`, `design/README.md`, `date-value-form.md` (mark it shipped in its first paragraph), `VERSION`, `core/version.go`, `MARKETING_VERSION`.
Do: per the Definition of done; patch bump.
Check: links resolve; `python3 scripts/check-plan-docs.py` reports no errors.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `PVFloatingMenuSelectionTests` `repeatedLetterWalksItsMatches` *(new)* | months on January (0), `j` at t, t+0.1, t+0.2, t+0.3 → 5, 6, 0 (wraps), 5; `["Aaron","Abel","Adam"]` from -1, `a`,`a` quickly → 0, 1; `["10","11","12"]` from 0, `1`,`1` → 1, 2 | AC-3.1, AC-3.2, AC-3.3, D-1 |
| T-2 | Swift | `PVFloatingMenuSelectionTests` `mixedLettersStayAPrefixSearch` *(new)* | `["January","June","July"]`, `j`,`j`,`o` quickly → third returns -1; `["Jane","Jones"]` from -1, `j`,`o` → 0, 1 | AC-3.4, AC-3.5 |
| T-3 | Swift | `PVFieldFocusTests` `replacingNeighboursSwapsBothClaims` *(new)* | handle with next/previous counters; `replacingNeighbours(next: B, previous: nil)` → Tab runs B, Shift-Tab `.ignored`; original unchanged | D-2 |
| T-4 | Swift | `PVFieldFocusTests` `focusClaimOnAHandleWritesNextTurn` *(new)* | `FocusClaim.claim(handle)` → `focus` not called synchronously, called after one main-queue turn (await `Task.yield` / a continuation) | D-2 |
| T-5 | Swift | `DateValueDraftTests` `loadKeepsTimeAndRangeTyped` *(new)* | `init(from:)` of a range 1880 – 1885 with `endTZ` "Europe/London" → end fields as saved, `setKind("range")` on a point with year 1880 → `endYear == nil` | D-8, D-9, AC-1.3, AC-1.5 |
| T-6 | Swift | `DateValueEditorFormTests` `tabOrder` *(new)* | point closed → start parts + `advancedToggle`; range closed → start parts, end parts, `advancedToggle`; point open → … `advancedToggle`, `calendar`, `phrase`; Kind and qualifier never in the forward order | D-5, AC-2.2, AC-2.3, AC-2.4 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `DateValueDraftTests`, `CitationComposerModelTests` (date values in the composer), `SourcesModelTests`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — or none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated)
- [ ] Domain doc updated if a rule in docs/*.md changed: none expected (no core/datevalue rule changes)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

Turn Full Keyboard Access off (System Settings → Keyboard → Keyboard navigation).

1. Open a Source page ("1880 census, Ward 4, Altona"), click its date to open the Source date dialog. See AC-1.1 at 520 pt. Click Calendar and phrase…: AC-1.6; Tab from the link per AC-2.4. Type 1880, Tab, J J J quickly: the Month reads July after June (AC-3.1). Walk Tab and Shift-Tab per AC-2.2, AC-2.5, AC-2.6, AC-2.8.
2. Choose Between two bounds: AC-1.2; Tab per AC-2.3. Type Day 32: AC-1.4.
3. Open Add Source (Sources list → Add). Tab from Description: Year (AC-2.1); Shift-Tab back to Kind, then Description (AC-2.7). On a range with only the earliest year: AC-1.3.
4. Open the Citation composer, New observation, a date Property: the Kind and qualifier stack in the value box; Tab from Property lands on Year.
5. Stretch the window past 1600 pt: each dialog is unchanged and centered (DF-W1).
6. Every Tab and Shift-Tab above ran with Full Keyboard Access off (AC-2.9).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A Tab claim crossing from the form's `FocusState` to the host's is swallowed while the key event is handled | D-2's `FocusClaim.claim(handle)` defers two turns, as the binding claim does |
| `ViewThatFits` picks the stacked layout in the 520 pt dialog | Kind (sm) and the qualifier (sm) measure under the dialog's content width; if not, see stop conditions |
| `PVButton(focus:)` changes rendering for existing callers | The default `nil` path is the unchanged code path; every existing preview still renders |

**Stop and report if:**

- `DateValueEditorForm`, `DateValueDraft`, `SourceFields`, `SourceDateDialog` or `PVTypeSelectMatcher.advance` no longer match §4 at your base.
- Kind and the qualifier do not fit one row in the 520 pt Source date dialog at `size: .sm` (they stack there).
- Tab from Description does not land on Year with Full Keyboard Access off after D-12, or Shift-Tab from Year does not reach the qualifier.
- A `PVSegmentedControl` or `PVButton` caller outside the date form changes its Tab behavior.
- `SourceDateText` or `sourceDateReadsAs` has a caller outside `SourceDateEditor.swift` that this plan does not name (`SourceDateText` has, and stays).

## 12. Open questions

None.

## 13. PR

**Title:** S16-83 — The date form is smaller and keyboard-first
**Body:** objective in one sentence; what shipped against US-1 – US-3; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-83-date-form-condensed.md`.
