# S16-83 — The date form is smaller and keyboard-first

**Status:** Landed in [#1027](https://github.com/Jake-Robins-Studios/provenencia/pull/1027) (2026-11-28)
**Landed:** As planned, except: the version is 0.53.1 (main was 0.53.0); `DateValueSelectTests`' second test, `monthAndDayCanBeSetWithoutAYear`, also lost its `applyStartCascade()` call (the method is gone); `Field.neighbours` is `@MainActor` because the kit's `PVFieldFocus.neighbours` is; `DateValueDraft.part(_:start:)` is static. The brief and its review moved to `design/archive/` with their relative links one level deeper. Historical landed plans under `spike-15/` and `spike-16/` still name deleted symbols (`PVInputTabClaim`, `sourceDateReadsAs`, `timeToggle`) as a record of what shipped then and were left as written. §10's manual check (and the view-level evidence for D-3, D-4, D-6, D-13) is the user's, run before merge
**Spike / slice:** Spike 16 · Slice 9a — The date form
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S16-D20](../design/archive/S16-D20-date-form-condensed.md), board agreed 2026-11-28
**Board:** the Provenencia design system artifact (`https://claude.ai/artifact/7AZ8cscWF3f5Wz7gQ39cMe`), template "DateValue editor". The brief's **Board** line lists what it decides, and **Design → macOS** below describes every part of it in words, so this plan does not need the artifact open. Where the board and this plan differ (no field fills itself in, no Stored as / Reads as), this plan wins: the user dropped both after the board
**Depends on:** S16-73 (landed [#1019](https://github.com/Jake-Robins-Studios/provenencia/pull/1019)), S16-D20 (agreed 2026-11-28)
**Blocks:** S16-74
**Branch:** `s16-83-date-form-condensed`
**Version bump:** patch — a UI polish and a kit keyboard fix, no schema or wire change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md), [`add-date-value`](../../../../.agents/skills/add-date-value/SKILL.md) (the draft's rules only; no Go change)
**Rules that bind:** `docs/design-system-layers.md`; `macos/App/DesignSystem/README.md` (Field focus, SegmentedControl, Button, FloatingMenuSelection rows)
**Context:** [feature doc](../date-value-form.md), working rules: "One date form, every host", "The latest bound is typed, never filled in", "The time fields always show", "The date form shows no Reads as", "A kit button takes the field focus handle", "A repeated letter walks its matches", "The date form's Tab starts at Year"; bar 52 – 54
**Planned:** 2026-11-28 against `main` @ `a39185a`
**Review:** [`S16-83-date-form-condensed.review.md`](S16-83-date-form-condensed.review.md) — Fits with changes / Ready with changes, 2 rounds, every finding fixed

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

**What stays.** Every value a researcher can set today, the field errors and their words, the host's can't-be-saved line in Add Source, Clear date and the refused-save callout in the Source date dialog, the composer's value box, `SourceDateEditor` as the Source date block (S15-42 adds its marks control there), and `SourceDateText` for the Source page header.

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
| AC-2.2 | Single date, Tab from Year repeatedly | Month → Day → Hour → Min → Sec → Ms → Time zone → Calendar and phrase… → out of the form (the system key loop) |
| AC-2.3 | Range, Tab from the earliest Time zone; Shift-Tab from the latest Year | Tab: latest Year → Month → … → latest Time zone → Calendar and phrase…. Shift-Tab from the latest Year: the earliest Time zone |
| AC-2.4 | Calendar and phrase open, Tab from the link | Calendar → Phrase → out |
| AC-2.5 | Single date, Shift-Tab from Year | Qualifier, then Kind; on a range Shift-Tab from Year goes straight to Kind |
| AC-2.6 | Tab from Kind; Tab from the qualifier | Year in both cases |
| AC-2.7 | Shift-Tab from Kind in Add Source | Description. In the Source date dialog and the composer (no field before the form) the key goes to the system key loop |
| AC-2.8 | Focus on the qualifier, press →; focus on Kind, press → | About is chosen and focus stays on the qualifier; Between two bounds is chosen, the qualifier goes, focus stays on Kind |
| AC-2.9 | Full Keyboard Access off | Every stop above is still reached; Return on the focused link opens Calendar and phrase |

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
| DF-8 dropped: Reads as goes from `SourceDateEditor` | STEP-7 |
| DF-9 the Tab loop | STEP-2, STEP-3, STEP-6, STEP-7, US-2 |
| DF-10 the Source date dialog at 520 pt | STEP-7, AC-1.1 |
| DF-W1 every host a modal, the same at Regular and Wide | STEP-7, §10 |
| `PVTypeSelectMatcher` walks a repeated letter | STEP-1, US-3 |
| `PVFieldFocus` neighbour replacement; one `FocusClaim` core; `PVSegmentedControl` and `PVButton` claim Tab | STEP-2, STEP-3 |

| Out | Home |
| --- | --- |
| DF-4 the latest bound following the earliest, and filling the latest side on switching to Between | not planned (user, 2026-11-28: working rule "The latest bound is typed, never filled in") |
| The Copy sheet's own fields and its focus order | S16-74 (inherits the form and `SourceFields`' order) |
| A marks control on the date (No date, Supplied) | S15-42 (into `SourceDateEditor`) |
| Moving the form's `L10n.Sources.date*` keys to `L10n.Dates` | S15-42 ("Also (structural debt)"; its entry now names the five keys this PR adds) |
| Type-select in `PVList` | not planned (the list has none; feature doc) |
| Per-side accessible names on each part ("Earliest, year") | not planned (fields read their part's name, "Year", today; the side group carries the side's name, D-6) |
| A chevron, or `PVDisclosureButton` gaining a link form | not planned (the board draws a text link whose words change; a second chevron-less disclosure link should give `PVDisclosureButton` a link form) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Form | `macos/App/Features/Dates/DateValueEditorForm.swift` `DateValueEditorForm` | Stacks a captioned Kind `PVSegmentedControl`, a captioned qualifier `PVChipGroup` of four `PVChip`s, three `PVDivider`s, a micro-caps heading per side with the hint on the first, captioned Year / Month / Day, an Add time / Remove time plain button and a sunken `timeBlock` (latest side has no Sec / Ms), a plain-button Calendar and phrase toggle. Seven per-part bindings (`yearBinding` … `millisecondBinding`) differ only in the property they touch. Two `@FocusState` Bools serve the time toggle. `yearFocus: PVFieldFocus?` is the host's handle on the earliest Year; no other field has a handle, so Kind, the chips and the links are Tab stops only with Full Keyboard Access, before Year. `cascadeField`'s `disabled:` and `activateOnAppear:` have no caller; `DateOptionalAccessibilityIdentifier` exists for a nil identifier no caller passes |
| Draft | `macos/App/Platform/DateValueDraft.swift` `DateValueDraft` | `showStartTime`, `showEndTime`, `hideTime(start:)` hide and clear time; `init(from:)` sets the show flags. `applyStartCascade()` / `applyEndCascade()` are no-ops every binding calls. The `canSetStart*` / `canSetEnd*` properties and `hasFullStartDay` / `hasFullEndDay` have no caller. `CascadeComponent` (year … millisecond) has its order written out in `cascadeFieldError`. `setKind` clears the qualifier (to range) or the end side and `showEndTime` (to point) |
| Source date block | `macos/App/Features/Sources/SourceDateEditor.swift` `SourceDateEditor` | The form plus the sunken Reads as card (`L10n.Sources.sourceDateReadsAs`). S16-73 D-13 made it the one Source date block, where S15-42's marks control lands |
| Source date dialog | `macos/App/Features/Sources/SourceDateDialog.swift` `SourceDateDialogModifier`, `SourceDateForm` | Width `SourceFields.dialogWidth` (560); `SourceDateForm` holds `@FocusState Field { year }`, claims Year on appear, passes `PVFieldFocus($focus, equals: .year)`; its doc mentions "what the date reads as" |
| Add Source fields | `macos/App/Features/Sources/SourceFields.swift` `SourceFields` | No focus state: Description's `PVInput` has no handle, the date block gets no `yearFocus`, so Tab from Description goes by the system order. Doc comment lists `.date.readsAs` |
| Composer | `macos/App/Features/CitationComposer/CitationComposerAuthoringBox.swift` `case .date` | Hosts `DateValueEditorForm` in `inlineValue` with `yearFocus: PVFieldFocus(focus, equals: .value)`; `CitationAuthoringNavigation.next(after: .property)` already sends Tab to `.value`. No change |
| Field focus | `macos/App/DesignSystem/Components/Input/PVFieldFocus.swift` `PVFieldFocus` | Neighbours come only from `init(_:equals:in:)` (S15-50 made the neighbour init private for that); nothing replaces a handle's `next` / `previous` |
| Tab claim | `macos/App/DesignSystem/Components/Input/PVInput.swift` private `PVInputTabClaim` | Claims Tab / Shift-Tab when the handle has a neighbour; only `PVInput` uses it. `PVSelect.handleTriggerKey` and `PVComboBox` claim Tab in their own key handlers |
| Focus claim | `macos/App/Platform/FocusClaim.swift` `FocusClaim.claim(_:_:then:)` | The deferred two-turn write, for a `FocusState` binding only |
| Segmented control | `macos/App/DesignSystem/Components/Chip/PVSegmentedControl.swift` `segment(_:)` | With a handle the selected segment is one stop with Space and ← / →; no Tab claim; "a host whose handle follows the selection re-claims it" after a choice |
| Button | `macos/App/DesignSystem/Components/Button/PVButton.swift` `PVButton` | No focus parameter: a Tab stop only with Full Keyboard Access |
| Return activation | `macos/App/DesignSystem/Components/ReturnActivation/PVReturnActivation.swift` `pvActivatesOnReturn(when:_:)` | The kit's one Return rule; `PVShowMoreRow` and `PVInkLink` use it; Space stays the `Button`'s |
| Type-select | `macos/App/DesignSystem/Components/FloatingMenuSelection/PVFloatingMenuSelection.swift` `PVTypeSelectMatcher.advance` | `jj` is a prefix search from the current row and matches nothing; callers `PVSelectSession.applyTypeSelect`, `PVContextMenu` `applyTypeSelect`, `PVTable` |
| Qualifier vocabulary | `macos/App/Platform/ConclusionVocabulary.swift` `DateQualifier` | `about`, `before`, `after`, checked against Go by `api/ffi/swift_vocabulary_test.go` |
| Tests | `macos/ProvenenciaTests/DateValueDraftTests.swift` `hidingTimeClearsIt`, `loadShowsTimeWithZoneOnly`, `applyStartCascadeDoesNotWipeIndependentFields`; `DateValueSelectTests.swift` `applyingAMonthOptionStillCascadesTheDraft` (calls `applyStartCascade()`); `PVFieldFocusTests.swift`; `PVSegmentedControlTests.swift`; `PVFloatingMenuSelectionTests.swift` `typeSelectSkipsDisabledRows` | Cover what this PR deletes or extends |

**Precedent.** S16-73 ([#1019](https://github.com/Jake-Robins-Studios/provenencia/pull/1019)) last reshaped this form and `SourceFields`; copy its commit-per-behavior split. For a focus enum that owns its order as a pure static, copy `CitationFormFocus.order(_:)` in `macos/App/Features/CitationComposer/CitationComposerEvidenceColumn.swift`. For a focusable `Button` that takes Return through the kit, copy `PVShowMoreRow` (`.focused(…)` plus `.pvActivatesOnReturn(when:)`).

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | A type-select buffer made of one character repeated (`j`, `jj`, `jjj`, compared through `TextMatch.key`) searches for that single character from `current + 1`; any other buffer keeps today's prefix search from `max(0, current)`. The change is inside `PVTypeSelectMatcher.advance`, so its three callers gain it unchanged | Working rule "A repeated letter walks its matches" | A per-caller rule — three copies |
| D-2 | `PVFieldFocus.replacingNeighbours(next: (@MainActor () -> Void)?, previous: (@MainActor () -> Void)?) -> PVFieldFocus` returns a copy with both claims replaced (nil clears one). `FocusClaim` gets one core, `@MainActor static func claim(write: @escaping @MainActor () -> Void, isDone: @escaping @MainActor () -> Bool, then: @escaping @MainActor () -> Void = {})`: write on the next main-queue turn, run `then`, write again a turn later unless `isDone()`. The binding overload calls it (`write: { binding.wrappedValue = value }`, `isDone: { binding.wrappedValue == value }`), and a new `claim(_ handle: PVFieldFocus)` calls it with `handle.focus` / `handle.isActive` | The loop crosses the host's binding (Year) and the form's own; the two-turn rule stays in one place | A second copy of the two-turn write |
| D-3 | `PVInputTabClaim` moves out of `PVInput.swift` into `PVFieldFocus.swift` as the internal `PVFieldTabClaim`, unchanged. It is the Tab claim for kit fields with no key handler of their own: `PVInput`, `PVSegmentedControl`'s focus target (new), `PVButton` (D-4). `PVSelect` and `PVComboBox` keep their own Tab handling, so Month and Calendar need no change. A handle with no neighbours adds nothing | Kind and the qualifier must send Tab to Year | A second claim modifier in the control |
| D-4 | `PVButton` gains `focus: PVFieldFocus? = nil`, the last parameter before `action`. With a handle the button is `focus.apply(AnyView(control.focusable().modifier(PVFieldTabClaim(focus: focus)).pvActivatesOnReturn(when: focus.isActive(), action)))`; Space stays the `Button`'s own. The handle wraps `control` (the `Button` with its style and `.disabled(loading)`) before the `iconOnly` / `flushLeading` branch. With none the body is today's, unchanged | Working rule "A kit button takes the field focus handle" (user, 2026-11-28); the kit's one Return rule | Own `.onKeyPress(.space / .return)` — a second Return rule and a double Space; `PVDisclosureButton` — draws a chevron the board does not |
| D-5 | The form's focus is one `@FocusState private var focus: DateValueEditorForm.Field?`. `Field` is `kind`, `qualifier`, `part(DateValueDraft.CascadeComponent, start: Bool)`, `zone(start: Bool)`, `advancedToggle`, `calendar`, `phrase`; it never names a host's field. `Field.order(isRange:isAdvancedOpen:) -> [Field]` (pure, as `CitationFormFocus.order(_:)`) is each side's parts (`CascadeComponent.allCases`) then its zone, the start side, then the end side on a range, then `advancedToggle`, then `calendar`, `phrase` while open. `Field.neighbours(of:isRange:isAdvancedOpen:) -> (next: Target?, previous: Target?)` (`Target` = `.field(Field)`, `.hostNext`, `.hostPrevious`) starts from `PVFieldFocus.neighbours(of:in: order)` and applies only these exceptions: start Year's `previous` is `qualifier` on a Single date and `kind` on a range; `qualifier`'s `next` is start Year, its `previous` `kind`; `kind`'s `next` is start Year, its `previous` `.hostPrevious`; the last field's `next` is `.hostNext`. Handles: start Year is `yearFocus` (or `PVFieldFocus($focus, equals: .part(.year, start: true))` when the host passes none), every other field `PVFieldFocus($focus, equals: field)`, each then `.replacingNeighbours(…)` with closures from `PVFieldFocus.claims(next:previous:claim:)` over its two targets. The claim resolves a target when the key is pressed, never by building handles: `.field(start Year)` → `FocusClaim.claim(yearHandle)`; any other `.field(f)` → `FocusClaim.claim($focus, f)`; `.hostNext` / `.hostPrevious` → the host Year handle's original `next` / `previous` (nil → no claim, the key loop) | Working rule "The date form's Tab starts at Year"; the kit's own neighbour and claim helpers; the exceptions are all the table owns | A second order walk in the feature; hand-placed closures in `body`; a Tab order per host |
| D-6 | Kind's and the qualifier's `select` read `let wasFocused = focus == .kind` (or `.qualifier`) before the choice, apply it, and when `wasFocused` call `FocusClaim.claim($focus, .kind)` (or `.qualifier`), as `ConclusionDetailPage.choose` claims its switcher only when it was focused. A click while focus is elsewhere does not move focus. Switching Kind keeps focus on Kind while the qualifier appears or goes | `PVSegmentedControl` moves its handle to the new segment and leaves re-claiming to the host | — |
| D-7 | Layout as **Design → macOS**: a `ViewThatFits(in: .horizontal)` over an `HStack` and a `VStack` of the two segmented controls (`size: .sm`), so the row stacks wherever it does not fit (the composer's 452 pt box; the 520 pt dialog, about 472 pt of content, may stack too, which DF-2 allows). On a range each side is a group with `.accessibilityElement(children: .contain)` labelled `dateEarliestHeading` / `dateLatestHeading`; a Single date's side has no group label. Kind and the qualifier keep `dateKindLabel` / `dateQualifierLabel` as their spoken label, not drawn | Board; accessible names stay (DF-2) | A fixed row — clips at 452 pt |
| D-8 | The qualifier is `PVSegmentedControl<String>` over `""`, `DateQualifier.about`, `DateQualifier.before`, `DateQualifier.after`, the segments keeping today's identifiers `<prefix>.qualifier.exact`, `.abt`, `.bef`, `.aft` | DF-2; the checked vocabulary | String literals |
| D-9 | `DateValueDraft.part(_:start:) -> WritableKeyPath<DateValueDraft, Int32?>` is the draft's one (part, side) → field mapping: the form's one `partBinding(_:start:)` uses it, `fieldError(_:start:)` reads `self[keyPath: part(component, start: start)]` (keeping each component's range), `setKind("point")` clears the end side over `CascadeComponent.allCases`, and the private `startSide` / `endSide` stay the validation-only `Int` view, built from `part`. The zone binds to `startTZ` / `endTZ`. `CascadeComponent` becomes `CaseIterable`, and `cascadeFieldError` reads `allCases` | One mapping for every reader of a part of a side | Seven bindings that differ by one property |
| D-10 | The time fields always show on both sides and the draft fills nothing in (working rules "The time fields always show", "The latest bound is typed, never filled in"); validation and `toInput()` are unchanged. The draft's removals are in **Deletes** | Working rules | — |
| D-11 | `SourceDateEditor` stays the Source date block and loses only Reads as; its doc says S15-42's marks control is the next thing it holds. The form's doc comment gains "The form shows its own field errors; the host shows any other line" | Working rule "The date form shows no Reads as"; S16-73 D-13 and S15-42 name this view | Deleting it — S15-42 would edit two hosts or bring it back |
| D-12 | `SourceDateForm` gets `static let dialogWidth: CGFloat = 520` (the convention of `SourceFields.dialogWidth`, `SourceOwnerForm.dialogWidth`), read by `SourceDateDialogModifier`; `SourceFields.dialogWidth` stays 560 for Add Source and its doc drops "and the Source date dialog". `SourceDateForm`'s focus (`Field { year }`, the claim on appear) is unchanged | DF-10: a narrower width is the date dialog's alone | — |
| D-13 | `SourceFields` gains `@FocusState private var focus: Field?`, `enum Field { case description, date }`, order `[.description, .date]`: Description's `PVInput` takes `PVFieldFocus($focus, equals: .description, in: order)`; `SourceDateEditor` takes `yearFocus: PVFieldFocus($focus, equals: .date, in: order)`. Title and Type stay outside this order | AC-2.1, AC-2.7 | Ordering Title and Type — S16-74 owns the sheet's full order |
| D-14 | The Time zone field's prompt is `L10n.Sources.dateTimeZonePrompt` = "Europe/London, +01:00…" | The board draws it | — |

**Rules this plan bends.**

| Rule | Where | Why | User's answer | Updated in |
| --- | --- | --- | --- | --- |
| A field's Tab neighbours come only from its form's order (S15-50) | `macos/App/DesignSystem/README.md` Field focus row; `.agents/skills/add-ui-component/SKILL.md` line "When Tab must move from a field that claims Tab …"; `PVFieldFocus` doc | D-2 adds `replacingNeighbours` so a host's handle joins the form's loop | Working rule "The date form's Tab starts at Year" (user, 2026-11-28): "one new `PVFieldFocus` operation that replaces a handle's Tab neighbours" | STEP-2 |

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `PVFieldFocus.replacingNeighbours(next:previous:)` | func | `PVFieldFocus.init(_:equals:in:)` | The init builds neighbours from one binding's order; a host handle has none to give |
| `FocusClaim.claim(write:isDone:then:)`, `FocusClaim.claim(_ handle:)` | funcs | `FocusClaim.claim(_:_:then:)` | It becomes a caller of the core |
| `PVFieldTabClaim` (renamed from `PVInputTabClaim`, moved) | modifier | `PVInputTabClaim` | The same claim, shared by three fields |
| `PVButton(…, focus:)` | parameter | `PVSegmentedControl(…, focus:)` | Extends the kit's one focus handle to buttons |
| `DateValueEditorForm.Field`, `Field.order(isRange:isAdvancedOpen:)`, `Field.Target`, `Field.neighbours(of:isRange:isAdvancedOpen:)` | enum, static funcs | `CitationFormFocus.order(_:)`; `PVFieldFocus.neighbours(of:in:)` and `PVFieldFocus.claims(next:previous:claim:)` | The order copies `CitationFormFocus`; the neighbours and claims reuse the kit helpers; only the exceptions are new |
| `DateValueDraft.part(_:start:)` | func | `startSide` / `endSide`, `fieldError`'s switch, `setKind`'s list | It becomes the one mapping they all read (D-9) |
| `SourceDateForm.dialogWidth`, `SourceFields.Field` | constant, enum | `SourceFields.dialogWidth`, `SourceDateForm.Field` | The widths differ now; Add Source's own focus |
| `L10n.Sources.dateEarliestShort` = "Earliest", `dateEarliestNote` = "not before", `dateLatestShort` = "Latest", `dateLatestNote` = "not after", `dateTimeZonePrompt` | keys | `dateEarliestHeading` | Two-line labels; the heading stays as the spoken name. They sit beside the form's other `Sources.date*` keys until S15-42 moves them all |
| `macos/ProvenenciaTests/DateValueEditorFormTests.swift` *(new)* | test file | `DateValueDraftTests.swift` | Tests the form's neighbour table |

**Builds on.** `PVFieldFocus` (with `neighbours(of:in:)` and `claims(next:previous:claim:)`), `FocusClaim`, `pvActivatesOnReturn`, `PVSegmentedControl`, `PVTypeSelectMatcher`, `CitationFormFocus`'s static order, the design-system README rows.

**Deletes.**
- `SourceDateEditor`'s Reads as card; `L10n.Sources.sourceDateReadsAs` and its catalog entry `sources.page.sourceDate.readsAs`.
- `DateValueDraft`: `showStartTime`, `showEndTime`, `hideTime(start:)`, `applyStartCascade()`, `applyEndCascade()`, the twelve `canSetStart*` / `canSetEnd*` properties, `hasFullStartDay`, `hasFullEndDay`; the show flags in `empty()` and `init(from:)`; `cascadeFieldError`'s written-out order.
- `DateValueEditorForm`: the captions above Kind and the qualifier, the qualifier's `PVChipGroup`, the three `PVDivider`s, the per-side micro-caps heading, the Add time / Remove time button, `timeBlock`'s sunken card, the plain-button `advancedToggle`, `startHourFocused`, `endHourFocused`, the seven bindings `yearBinding` to `millisecondBinding` (one `partBinding` remains), `cascadeField`'s `focused:`, `disabled:` and `activateOnAppear:` parameters, `DateOptionalAccessibilityIdentifier`.
- L10n keys and catalog entries: `datePointHeading`, `dateAddTime`, `dateHideTime`.
- Tests: `hidingTimeClearsIt`, `loadShowsTimeWithZoneOnly`, `applyStartCascadeDoesNotWipeIndependentFields`; `DateValueSelectTests.applyingAMonthOptionStillCascadesTheDraft` is renamed `applyingAMonthOptionKeepsTheDraftValid` and loses its `applyStartCascade()` calls.
- Doc text: `SourceFields`' `.date.readsAs`; `SourceDateForm`'s "what the date reads as"; the `SourceFields` preview title "Filled, Private, Reads as: frame 2" becomes "Filled, Private: frame 2"; `PVSegmentedControl`'s "does not read the handle's `next` / `previous`".

**Next adds.** S15-42's No date and Supplied stay in `SourceDateEditor`: they join the Tab loop through the `yearFocus` handle it passes in (its own order, or `replacingNeighbours`), so the form's `.hostPrevious` / `.hostNext` reach them; the form's `Field` table gets no host case. S16-74's Copy sheet takes `SourceFields` and inherits D-13. Any button joins a Tab order by passing `focus:`.

### Reach

| New path or state | Destination | Checked |
| --- | --- | --- |
| Tab into Year from Description (Add Source) | `DateValueEditorForm` Year | The form's own `focus` is nil there; the Year handle is the host's (D-5) |
| A loaded date with time and no Add time click | the always-shown time row | Fields show their value; nothing depends on the removed flags (AC-1.5) |
| `PVButton` with a focus handle | every `PVButton` caller | Default `nil` keeps today's body; every existing caller passes none |
| `PVSegmentedControl` claiming Tab | every caller with a handle | `PVFieldTabClaim` adds nothing without neighbours; today's callers (the composer's Yes / No and others) pass handles without neighbours |
| The binding `FocusClaim.claim` through the new core | every caller | Same timing and writes (T-4) |

### Scale

None — no write, list or loop changes; the form has at most 23 fields.

### Edges

- **Assumptions.** `PVTypeSelectMatcher.index` wraps and skips disabled rows; the single-character search from `current + 1` relies on that (T-1: July → January). A handle is applied only to the focused element: `PVSegmentedControl` applies it to its focus target, and the Tab claim sits on that same view. `Field.neighbours` is pure, so the loop is the table's.
- **Neighbors.** `aa` walks, `ab` is a prefix search (AC-3.2, AC-3.5); a pause between two J's starts a single-character search from the current row, as today. On a Single date Year's `previous` is the qualifier; on a range it is Kind (AC-2.5). The end Year's `previous` is the start zone (AC-2.3). Calendar and Phrase join while open (AC-2.4).
- **Removed inputs.** Switching range → point clears the end side as today, and the end fields leave the table with their views. Closing Calendar and phrase removes `calendar` and `phrase`; their values stay in the draft, as today.
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
| Kind + qualifier row | two `PVSegmentedControl(size: .sm)` in `ViewThatFits` (D-7) | `DateValueEditorForm` | Row spacing `space4`; no captions; under it on a range the gloss `dateKindRangeHint` (micro, italic, `textMuted`, as today) |
| A side | `VStack(spacing: space3)` of a date row and a time row | `DateValueEditorForm` | On a range a leading column 86 pt wide holds `dateEarliestShort` over `dateEarliestNote` (or Latest): the first caption size, medium, `textSecondary`; the second micro, italic, `textMuted`. A Single date has no column |
| Date row | `PVInput(size: .sm, mono: true)` Year 64, `PVSelect` Month 124 (menu width 160), `PVInput` Day 48 | `DateValueEditorForm` | Each with today's micro caption above (`dateYear`, `dateMonth`, `dateDay`) |
| Time row | `PVInput(size: .sm, mono: true)` Hour, Min, Sec 48 each, Ms 52; Time zone `PVInput(size: .sm, prompt: dateTimeZonePrompt)` filling the rest, `minWidth` 96 (a range in the composer's box leaves it about 118) | `DateValueEditorForm` | Captions `dateHour`, `dateMinute`, `dateSecond`, `dateMillisecond`, `dateTimeZone`; both sides draw all five; no sunken card |
| Field error | `PVErrorText` | `DateValueEditorForm` | One line under its side, indented 86 pt on a range; identifiers unchanged |
| Hint + link line | `HStack`: `dateLeaveEmptyHint` (micro, italic, `textFaint`), `Spacer`, `PVButton(variant: .link, size: .sm, focus:)` titled `dateShowAdvanced` / `dateHideAdvanced`, with `.pvExpandedState(draft.showAdvanced)` | `DateValueEditorForm` | Identifier `<prefix>.advancedToggle` unchanged |
| Calendar and Phrase | as today | `DateValueEditorForm` | Under the line when open; each takes its `Field` handle |
| Form stack | `VStack(alignment: .leading, spacing: space5)` | `DateValueEditorForm` | No `PVDivider` |
| Source date block | `SourceDateEditor` | `SourceDateEditor.swift` | The form only, until S15-42 |
| Source date dialog | `pvFormDialog(width: SourceDateForm.dialogWidth)` | `SourceDateDialog.swift` | 520 pt; Clear date and callouts as today |
| Add Source | `SourceFields` | `SourceFields.swift` | 560 pt; the block inside the Published date `PVField` as today |
| Composer | unchanged call | `CitationComposerAuthoringBox.swift` | The row stacks in the 452 pt box |

States: blank, filled, range, open Calendar and phrase, field error (AC-1.*). Accessibility: Kind and the qualifier speak their labels; each range side speaks its full heading; the link reports expanded / collapsed.

### Strings

L10n keys: the five in Codebase fit (catalog keys `sources.page.dateEarliestShort`, `sources.page.dateEarliestNote`, `sources.page.dateLatestShort`, `sources.page.dateLatestNote`, `sources.page.dateTimeZonePrompt`). Removed: `datePointHeading`, `dateAddTime`, `dateHideTime`, `sourceDateReadsAs`. Kept: `dateKindLabel`, `dateQualifierLabel`, `dateEarliestHeading`, `dateLatestHeading` (spoken), `dateKindRangeHint`, `dateLeaveEmptyHint`.

## 7. Steps

**STEP-1 — A repeated letter walks its matches**
Files: `PVFloatingMenuSelection.swift`, `macos/ProvenenciaTests/PVFloatingMenuSelectionTests.swift`, `macos/App/DesignSystem/README.md` (the FloatingMenuSelection row; the closed-keys table under "## The Select contract"; the table keys table under "## The table tradeoff", its "a–z, 0–9" row). Skill: `add-swift-test`.
Do: D-1; its doc comment; T-1, T-2.
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/PVFloatingMenuSelectionTests` passes.

**STEP-2 — Field focus handles can be rewired and claimed, and segmented controls claim Tab**
Files: `PVFieldFocus.swift`, `FocusClaim.swift`, `PVInput.swift`, `PVSegmentedControl.swift`, `PVFieldFocusTests.swift`, README Field focus, Input, TextArea and SegmentedControl rows (the Input and TextArea rows' list of fields that claim Tab gains `PVSegmentedControl`), `.agents/skills/add-ui-component/SKILL.md` (the line beginning "When Tab must move from a field that claims Tab": add "a host's handle joins a form's loop through `replacingNeighbours`"). Skill: `add-ui-component`.
Do: D-2, D-3; the row in **Rules this plan bends**; T-3, T-4.
Check: the `PVFieldFocusTests` suite passes (command as STEP-1), and §10 step 4's Subject → Property Tab still works.

**STEP-3 — A kit button takes a focus handle**
Files: `PVButton.swift`, README Button row, the Field focus row's list of takers and the Input and TextArea rows' list of fields that claim Tab; the `add-ui-component` line "When Tab must move from a field that claims Tab" lists `PVSegmentedControl` and `PVButton` too. Skill: `add-ui-component`.
Do: D-4.
Check: the app builds with no warning; the button previews render as before.

**STEP-4 — The draft has no hidden time and one key path per part**
Files: `DateValueDraft.swift`, `DateValueDraftTests.swift`, `DateValueSelectTests.swift`. Skill: `add-date-value`.
Do: D-9's draft half, D-10; the draft and test lines in Deletes; T-5.
Check: none on its own: the test target builds the app, and the form does not compile until STEP-5. Commit STEP-4 and STEP-5 together; STEP-5's check runs these suites.

**STEP-5 — The condensed form**
Files: `DateValueEditorForm.swift`, `L10n.swift`, `Localizable.xcstrings`. Skills: `add-ui-component`, `add-localized-string`.
Do: the layout in **Design → macOS**; D-7, D-8, D-9's form half, D-14; the form lines in Deletes.
Check: the app builds with no warning; `DateValueDraftTests` and `DateValueSelectTests` pass; the `SourceFields` previews render.

**STEP-6 — The form's Tab loop**
Files: `DateValueEditorForm.swift`, `macos/ProvenenciaTests/DateValueEditorFormTests.swift` *(new)*.
Do: D-5, D-6; T-6.
Check: `DateValueEditorFormTests` passes.

**STEP-7 — The hosts**
Files: `SourceDateEditor.swift`, `SourceDateDialog.swift`, `SourceFields.swift`, `L10n.swift`, `Localizable.xcstrings`.
Do: D-11, D-12, D-13; remove `sourceDateReadsAs`; the doc lines in Deletes.
Check: `scripts/check-pr.sh` prints `check-pr: PASS`; §10 passes.

**STEP-8 — Docs**
Files: `docs/deployment-plan/spike-16/completed.md`, `deployment-plan.md` (map row), this plan (status), `design/S16-D20-date-form-condensed.md` → `design/archive/`, `design/README.md`, `date-value-form.md` (its first paragraph says it shipped), `VERSION`, `core/version.go`, `MARKETING_VERSION`.
Do: per the Definition of done; patch bump.
Check: links resolve; `python3 scripts/check-plan-docs.py` reports no errors.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `PVFloatingMenuSelectionTests` `repeatedLetterWalksItsMatches` *(new)* | twelve month names (no empty option), current 0 (January), `j` at t, t+0.1, t+0.2, t+0.3 → 5, 6, 0, 5; `["Aaron","Abel","Adam"]` from -1, `a`,`a` quickly → 0, 1; `["10","11","12"]` from 0, `1`,`1` → 1, 2 | AC-3.1, AC-3.2, AC-3.3, D-1 |
| T-2 | Swift | `PVFloatingMenuSelectionTests` `mixedLettersStayAPrefixSearch` *(new)* | `["January","June","July"]`, `j`,`j`,`o` quickly → third returns -1; `["Jane","Jones"]` from -1, `j`,`o` → 0, 1 | AC-3.4, AC-3.5 |
| T-3 | Swift | `PVFieldFocusTests` `replacingNeighboursSwapsBothClaims` *(new)* | handle with next/previous counters; `replacingNeighbours(next: B, previous: nil)` → Tab runs B, Shift-Tab `.ignored`; the original unchanged | D-2 |
| T-4 | Swift | `PVFieldFocusTests` `focusClaimWritesOnTheNextTurn` *(new)* | the core with counting `write` and `isDone` → no write synchronously; one write after a main-queue turn; a second only while `isDone()` is false; the handle overload calls `focus` the same way | D-2 |
| T-5 | Swift | `DateValueDraftTests` `loadKeepsTimeAndNothingFillsIn` *(new)* | `init(from:)` with only `startTZ` "Europe/London" → `startTZ` kept, `isValid` false as today; a point with year 1880, `setKind("range")` → `endYear == nil`; `part(.month, start: false)` writes `endMonth`; `endDay = 32` → `fieldError(.day, start: false)` is the day message; `setKind("point")` on a range clears every end part | D-9, D-10, AC-1.3, AC-1.5 |
| T-6 | Swift | `DateValueEditorFormTests` `neighbourTable` *(new, `@MainActor` suite)* | `Field.order` for each of the four cases; then for Single date and range, Calendar and phrase closed and open, walk `next` from start Year and `previous` from start Year: point closed → Month, Day, Hour, Min, Sec, Ms, zone, `advancedToggle`, `.hostNext`; Shift-Tab → `qualifier`, `kind`, `.hostPrevious`; range → end side after start zone, end Year's `previous` is start zone, start Year's `previous` is `kind`; open → `advancedToggle`, `calendar`, `phrase`, `.hostNext`; `kind.next` and `qualifier.next` are start Year | D-5, AC-2.2, AC-2.3, AC-2.4, AC-2.5, AC-2.6, AC-2.7 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `DateValueDraftTests`, `CitationComposerModelTests` (date values in the composer), `SourcesModelTests`, `PVFieldFocusTests`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes; D-3, D-4 and D-6 are view-level key handling with no test seam beyond `claimTab` (already tested): their evidence is §10 steps 1, 3 and 4
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md`, `docs/deployment-plan/spike-15/`, `docs/deployment-plan/spike-16/` (not `archive/`) and `L10n.swift` with no hit left, and "come only from" in the README and skills; `scripts/check-guidance-names.py` passes (check-pr runs it)
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

1. Open a Source page ("1880 census, Ward 4, Altona"), click its date to open the Source date dialog. See AC-1.1 at 520 pt. Type 1880, Tab to Month, press J (January), pause, then J J quickly: June, July (AC-3.1). Walk Tab and Shift-Tab per AC-2.2, AC-2.5, AC-2.6; press → on the qualifier and on Kind (AC-2.8). Tab to the link and press Return: AC-1.6; Tab on per AC-2.4.
2. Choose Between two bounds: AC-1.2; Tab and Shift-Tab per AC-2.3. Type Day 32: AC-1.4.
3. Open Add Source (Sources list → Add). Tab from Description: Year (AC-2.1); Shift-Tab back to Kind, then Description (AC-2.7). On a range with only the earliest year: AC-1.3. Load a Source whose date has only a time zone: AC-1.5.
4. Open the Citation composer, New observation: Tab from Subject to Property still works; choose a date Property: Kind and the qualifier stack in the value box; Tab from Property lands on Year; a range keeps Time zone readable.
5. Stretch the window past 1600 pt: each dialog is unchanged and centered (DF-W1).
6. Every step above ran with Full Keyboard Access off (AC-2.9).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A Tab claim crossing from the form's `FocusState` to the host's is swallowed while the key event is handled | D-2's handle claim uses the two-turn core |
| `PVButton(focus:)` changes rendering for existing callers | The `nil` path is today's body; existing previews render as before |

**Stop and report if:**

- `DateValueEditorForm`, `DateValueDraft`, `SourceDateEditor`, `SourceFields`, `SourceDateDialog`, `FocusClaim` or `PVTypeSelectMatcher.advance` no longer match §4 at your base.
- Focus leaves Kind or the qualifier after → or Space (D-6).
- Tab from Description does not land on Year with Full Keyboard Access off after D-13, or Shift-Tab from Year does not reach the qualifier.
- A `PVSegmentedControl`, `PVButton` or `FocusClaim` caller outside the date form changes its focus behavior.
- Return on the focused link fires its action twice, or Space does nothing.

## 12. Open questions

None.

## 13. PR

**Title:** S16-83 — The date form is smaller and keyboard-first
**Body:** objective in one sentence; what shipped against US-1 – US-3; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-83-date-form-condensed.md`.
