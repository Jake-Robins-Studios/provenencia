# S16-39 — One container measures its own width and tells its content which layout fits

**Status:** Planned
**Spike / slice:** Spike 16 · Slice 4a — Layout by a container's own width
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: every view switches layout at the same widths as today and draws the same on each side of them)
**Board:** —
**Depends on:** S15-49 (landed [#852](https://github.com/mendahu/provenencia/pull/852))
**Blocks:** —
**Branch:** `s16-39-own-width-breakpoints`
**Version bump:** none — no change a researcher can see in the shipped app ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/swift-tests.mdc`, `.cursor/rules/versioning.mdc`
**Context:** user, 2026-11-15, on S15-49 ([#852](https://github.com/mendahu/provenencia/pull/852)): unify the table's own-width breakpoint into a general-purpose tool; [S15-49's ship log](../../spike-15/prs/S15-49-source-types-list.ship.md) (F-7, F-10, F-11, the MNT round 3 note on `compactBelow`, UX-5 "Description may pop in a pass late"); [§ 9 of macos-client-patterns.md](../../../macos-client-patterns.md#9-window-widths-regular-and-wide) rule 3; working rule "(Batch 3) A test run shows no window and touches no install"
**Planned:** 2026-11-16 against `main` @ `5b64138`
**Review:** [`S16-39-own-width-breakpoints.review.md`](S16-39-own-width-breakpoints.review.md) — Fits with changes — Ready with changes, 2 rounds; no open blocker; To user: M-1 (answered 2026-11-16: rebuild the pane measure on the container)

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

Four views choose a layout from a width they measure themselves, each with its own `onGeometryChange` or `GeometryReader` and its own state: the Source types table's Description column (`PVTable`, from 1200pt), the Sources list's compact rows (below 880pt), the Person Timeline's people cards stacked under the title (below 772pt at Regular, 1402pt at Wide), and the Citation composer's three-up evidence split (from 1400pt). This PR gives the kit one container, `PVWidthBreakpoints`, that measures the width it fills and hands its content which of the caller's breakpoints that width meets, and moves all four onto it. The researcher sees each view switch at the same widths as before, with the right layout on the first frame and no redraw while a resize stays between two breakpoints.

**Why now.** S15-49 gave `PVTable` its own width gate the day after the Sources list's; the user asked on [#852](https://github.com/mendahu/provenencia/pull/852) for one tool before a third copy lands (2026-11-15).

**What stays.** The pane's width class (`PVWidthClass`, read from `\.pvWidthClass`, measured once at `WorkspaceDestinationHost`) and its 1600pt breakpoint; `pvMeasuresWidthClass()` keeps its name and behavior and is rebuilt on the container (user, 2026-11-16, plan review M-1). Every breakpoint's value. Views that use a measured size as geometry (§ 6 Codebase fit, survey table).

## 2. User stories

**US-1.** As a researcher, when I open the Source types list, the Sources list, a Person's Timeline or the Citation composer, each shows the layout its width calls for from the first frame, and switches at the same widths as before when I resize the window.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | The Source types table is 1199pt wide · 1200pt | No Description column · a Description column (as today) |
| AC-1.2 | The Sources list is 879.5pt wide · 880pt | Compact rows (no Type column, 380pt graphs) · full rows (Type column, 420pt graphs) (as today) |
| AC-1.3 | The Timeline's items column is 771pt · 772pt wide at Regular; 1401pt · 1402pt at Wide | People stacked under the title · people beside it (as today) |
| AC-1.4 | The Citation composer's split is 1399pt · 1400pt wide | Evidence column over the viewer · viewer, evidence column and observations side by side (as today) |
| AC-1.5 | A `PVWidthBreakpoints` with breakpoint 1200 is hosted at 1300pt and laid out once | Its content was built for "at least 1200" by the end of that one pass: no second layout and no wait |

**US-2.** As a contributor, when a view needs to choose a layout from its own width, I reach for one kit container whose rule (it fills the width it is given) cannot be broken by its content.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Breakpoints `[880, 1200]` and widths 0, 879.5, 880, 1199, 1200, 5000 | `isAtLeast(880)` false, false, true, true, true, true; `isAtLeast(1200)` false, false, false, false, true, true |
| AC-2.2 | Breakpoints `[880]`, widths 900 and 1100 | The two readings are equal (a resize between them reports nothing); 870 differs from 900 |
| AC-2.3 | A `PVWidthBreakpoints([1200])` whose content is a short `Text`, hosted in a 2000pt window | The content is built for "at least 1200": the container measured the width it fills, not its content |
| AC-2.4 | Breakpoints `[1200, 880, 1200]` | Read the same as `[880, 1200]` |
| AC-2.6 | `pvMeasuresWidthClass()` at panes of 1599.5 and 1600pt | `.regular` · `.wide`, as today, through `PVWidthBreakpoints` (`PVWidthClassTests` unchanged in outcome) |
| AC-2.5 | `rg -n -e onGeometryChange -e GeometryReader macos/App` | Prints only `PVWidthBreakpoints.swift` and the geometry uses D-7 names |

## 3. Scope

| In | Covered by |
| --- | --- |
| `PVBreakpointsMet` *(new)* and `PVWidthBreakpoints` *(new)* in `Components/WidthClass/PVWidthBreakpoints.swift` | STEP-1, AC-1.5, AC-2.1 – AC-2.4 |
| `PVTable`'s `minTableWidth` gate moves onto the container; `PVTableColumnGate` and `shownIDs` go | STEP-2, AC-1.1 |
| The Sources list's `compactBelow` moves onto the container; `listWidth` goes | STEP-3, AC-1.2 |
| The Timeline's people-stacking width moves onto the container; `itemsWidth` goes | STEP-4, AC-1.3 |
| The Citation composer's three-up width moves onto the container | STEP-5, AC-1.4 |
| `PVMeasuresWidthClass` is rebuilt on the container; `PVWidthClass.init(paneWidth:)` wraps the reading, and four previews use it | STEP-1, AC-2.6 |
| The survey: every other measure in `macos/App` is named as geometry, or as not this container's (D-7) | STEP-6, AC-2.5 |
| § 9, the DesignSystem README, `add-ui-component` and `PVTable`'s contract teach the container | STEP-6 |

| Out | Home |
| --- | --- |
| The pane's width class, where it is measured (`WorkspaceDestinationHost`) and its 1600pt breakpoint | not planned (map: Not this PR) |
| Any change to a breakpoint's value | not planned (map: Not this PR) |
| `ViewThatFits` or a custom `Layout` in place of measuring | not planned (map: Not this PR) |
| The Evidence graph header's icon-only switch (`EvidenceGraphView` `iconOnly`, a content fit: its threshold is the labeled row's own measured width, not a breakpoint) | not planned (D-7: a fit to content is `ViewThatFits`' shape, which the map rules out here) |
| Breakpoints that change while a container is on screen | not planned (D-4: every caller's breakpoints are fixed) |

## 4. Current state

Verified at `5b64138`.

| Area | Where | Today |
| --- | --- | --- |
| Pane class | `macos/App/DesignSystem/Components/WidthClass/PVWidthClass.swift` `PVWidthClass`, `PVMeasuresWidthClass`, `pvMeasuresWidthClass()` | Measures the pane once; `onGeometryChange(for: PVWidthClass.self)` so the action fires only on a class change. The same job as the container with one breakpoint; its fill rule is only a doc comment. `init(paneWidth:)` has no other production caller |
| Table gate | `macos/App/DesignSystem/Components/Table/PVTable.swift` `PVTableColumnGate.shownIDs(gates:tableWidth:)` (line 32–37) | Plain-value rule so the Sendable geometry closure captures no generic columns |
| Table gate | `PVTable.swift` `PVTable.shownIDs` (`@State [String]?`, line 192), `static func shownColumns(_:tableWidth:)` (229), `private var shownColumns` (234), `body`'s `.onGeometryChange(for: [String].self)` (241–247) | Measures the shown ids; nil until the first measure, so a gated column is absent until then (S15-49 UX-5). `header` (277) and `rowView(_:)` (353) read `shownColumns` |
| Table contract | `PVTable.swift` doc comment lines 13–24 | "Columns also decide whether they show (`minTableWidth`)" |
| Table caller | `macos/App/Features/SourceTypes/SourceTypesListPane.swift` `descriptionMinTableWidth` (1200), `static func columns()` | The only caller passing `minTableWidth`; its columns are static. Unchanged by this PR |
| Other tables | `macos/App/Features/CatalogVocabulary/VocabularyListPane.swift` `table`, `macos/App/Features/Properties/PropertiesView.swift` `propertyTable` | `PVTable` callers with no `minTableWidth`; both sit in a `VStack` or branch that fills, and the table's `ScrollView` fills, so the container's width frame changes nothing |
| Sources list | `macos/App/Features/Sources/SourcesListView.swift` `SourcesListContent.listWidth` (`@State CGFloat = .infinity`, line 57), `columns` (59–61), `listBody(rows:)`'s `.onGeometryChange(for: CGFloat.self)` on the `ScrollView` (313–315), `captionBand` (327) | Re-renders on every point of width change; first frame is non-compact, corrected by the first report |
| Sources columns | `macos/App/Features/Sources/SourcesListColumns.swift` `compactBelow` (880), `init(listWidth:widthClass:)` | `isCompact = listWidth < compactBelow` |
| Timeline | `macos/App/Features/Conclusions/PersonTimelineSection.swift` `itemsWidth` (`@State`, line 77), `stacksPeople:` argument (98), `.onGeometryChange` on the stack (112) | Re-renders the whole stack on every point of width change; `itemsWidth` has no other reader |
| Timeline rule | `macos/App/Features/Conclusions/PersonTimelinePlacement.swift` `textWidth(itemsWidth:widthClass:)` (98), `stacksPeople(itemsWidth:widthClass:)` (108), `minimumTextWidth` (280), `gutterWidth`, `rowPicture` (72), `rowGap` (16), `peopleWidth(_:)` | Stacks when `itemsWidth - 56 - 72 - people - 64 < 280`: below 772 at Regular (people 300), below 1402 at Wide (people 930). `textWidth` has no other caller |
| Composer | `macos/App/Features/CitationComposer/CitationComposerView.swift` `composeSplit` (300–311), `evidence(threeUp:height:)` (315–345) | `GeometryReader`; `threeUp = geo.size.width >= 1400`; the panel branch caps the evidence column at `height * 0.55` |
| Kit precedent | `macos/App/DesignSystem/Components/PageColumns/PVPageColumns.swift` `PVPageVisibleRect` (441) | A container that holds its own reading in `@State` and hands it to a `@ViewBuilder` content closure |
| Tests | `macos/ProvenenciaTests/PVTableTests.swift` `PVTableShownColumnsTests.optionalColumnShowsFromItsMinimumTableWidth` | Calls `shownColumns(_:tableWidth:)` at 1199, 1200, 0 |
| Tests | `macos/ProvenenciaTests/SourcesModelTests.swift` `listColumnsMatchBoard`, `columnsPlaceTheDateByWidth` (668–700) | Build `SourcesListColumns(listWidth:widthClass:)` |
| Tests | `macos/ProvenenciaTests/PersonTimelinePlacementTests.swift` `narrowListStacksPeople` (103–110) | `stacksPeople(itemsWidth:)` at 771/772 Regular, 1401/1402 Wide |
| Tests | `macos/ProvenenciaTests/PVWidthClassTests.swift` `modifierFollowsTheWindow`, `aFilledHostMeasuresTheSpaceNotTheChild` | The hosted, forced-layout pattern (S16-35) to copy |
| Test host | `macos/ProvenenciaTests/HostedWindow.swift` `hostInBorderlessWindow(_:windowSize:hostSize:)`, `.hostedWindows` | Window never shown; trait closes it |

**Precedent.** S15-49's F-10 (`23d5464`) and F-11 (`5135fb8`) measured `PVTable`'s result instead of its width, so a resize redraws only at the threshold: copy that (the container measures a `PVBreakpointsMet`, which is `Equatable`). `PVPageVisibleRect` is the container shape: `@State` reading, `@ViewBuilder` content closure. `PVWidthClassTests` (`modifierFollowsTheWindow`) is the test shape: host, `layoutSubtreeIfNeeded()` once, assert at once.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | The tool is a container view, `PVWidthBreakpoints(_ breakpoints: [CGFloat], @ViewBuilder content: @escaping (PVBreakpointsMet) -> Content)`, not an environment modifier. Its body is `content(reading).frame(maxWidth: .infinity, alignment: .leading).onGeometryChange(for: PVBreakpointsMet.self) { … } action: { reading = $0 }` | Every caller reads the result in the same `body` that would apply the measure (`PVTable.header`, `SourcesListContent.captionBand`, the Timeline's item builder, `composeSplit`), and a view cannot read an environment value set by its own modifier: an environment modifier would need a new child view at each of the four. The frame makes the container fill its width by construction, so § 9's rule ("measure a filling container, never one sized by its content") cannot be broken by the content. `PVPageVisibleRect` is the same shape | An environment modifier beside `pvMeasuresWidthClass` (the map's first wording) — because each caller would split its body into a reader view, and nothing stops it being applied to a content-sized view; a `Binding` out-parameter modifier — because the measured state then lives in every caller again |
| D-2 | `PVBreakpointsMet` *(new)* is a pure `Equatable, Sendable` value with two stored fields: `let breakpoints: Set<CGFloat>` (all the caller's breakpoints) and `let met: Set<CGFloat>` (those `<= width`); synthesized `Equatable` compares both, so order and duplicates in the caller's list do not matter (AC-2.4). `init(breakpoints: [CGFloat], width: CGFloat)` builds them. `func isAtLeast(_ breakpoint: CGFloat) -> Bool` is `met.contains(breakpoint)`, after `assert(breakpoints.contains(breakpoint))`: asking about a value not in the list is a programmer error. An empty list has both sets empty. `PVWidthBreakpoints` holds `@State private var reading: PVBreakpointsMet?` (nil until the first measure) and builds its content from `reading ?? PVBreakpointsMet(breakpoints: breakpoints, width: 0)` (D-3) | The value, not the width, is what `onGeometryChange` compares, so the action fires only when a breakpoint is crossed (AC-2.2). `>=` is the rule all four views use today (`PVTable` `>=`, Sources `<` compact, Timeline `<` stacks, composer `>=`) | Publishing the raw width — because it redraws on every point of a resize (the MNT-R3-1 finding); an index or count the caller decodes — because `isAtLeast(SourcesListColumns.compactBelow)` reads at the call site |
| D-3 | Before the first measure the reading is `PVBreakpointsMet(breakpoints:, width: 0)`: no breakpoint met | One rule for every caller (today `PVTable` starts with none met and the Sources list with all met). The first layout pass corrects it before the frame is drawn (AC-1.5, T-3) | `.infinity` — because a Wide layout built in a narrow pane can overflow the frame for that pass |
| D-4 | Breakpoints are fixed for a container's life. A choice that depends on the width class lists one breakpoint per class (the Timeline: `[772, 1402]`) and picks with `isAtLeast(stacksBelow(widthClass))`. The container checks the rule in debug: `.onChange(of: Set(breakpoints)) { assertionFailure("PVWidthBreakpoints: breakpoints changed") }`, so a caller with changing breakpoints fails loudly | The geometry transform captures the breakpoints; whether SwiftUI re-runs it when only the captured list changes is not verified, and no caller needs it: `SourceTypesListPane.columns()` is static, the other three are constants | Breakpoints computed from the width class — because a class change without a width change might not re-report. |
| D-5 | `PVTable` keeps a pure `static func shownColumns(_ columns: [PVTableColumn<Row>], met: PVBreakpointsMet) -> [PVTableColumn<Row>]` and adds `static func breakpoints(_ columns: [PVTableColumn<Row>]) -> [CGFloat]` (the columns' `minTableWidth`s). `body` is `PVWidthBreakpoints(Self.breakpoints(columns)) { met in let shown = Self.shownColumns(columns, met: met); VStack(spacing: 0) { header(shown); rowList(shown) } }`; `breakpoints(_:)` is `columns.compactMap(\.minTableWidth)` (de-duplication is `PVBreakpointsMet`'s). The `private var header` and `private var rowList` become `private func header(_ shown: [PVTableColumn<Row>]) -> some View` and `private func rowList(_ shown: [PVTableColumn<Row>]) -> some View`; `rowView(_ row: Row)` becomes `rowView(_ row: Row, shown: [PVTableColumn<Row>])`. Every other modifier stays where it is | The column rule stays testable without a view; one list of shown columns per build feeds the header and every row, so they cannot disagree | Keeping `PVTableColumnGate` — because its only job was a Sendable closure, which the container now owns |
| D-6 | `SourcesListColumns` gains `static let breakpoints: [CGFloat] = [compactBelow]` and replaces `init(listWidth:widthClass:)` with `init(met: PVBreakpointsMet, widthClass: PVWidthClass)` (`isCompact = !met.isAtLeast(compactBelow)`). `listBody(rows:)` wraps its `ScrollView` in `PVWidthBreakpoints(SourcesListColumns.breakpoints) { met in … }` and builds `columns` there; the `ScrollView`'s own modifiers (`ListScrollAnchorModifier`, `accessibilityElement`, `accessibilityLabel`, `accessibilityIdentifier("sources.list")`) stay on the `ScrollView`, inside the closure, so the list's accessibility element and scroll anchor are unchanged. `captionBand` becomes `captionBand(_ columns: SourcesListColumns)` | The measure stays where it is today (the `ScrollView`, which fills); the columns are built once per crossing and passed down as today | Keeping `init(listWidth:)` beside the new init — because only tests would call it (S16-37 removed test-only parameters) |
| D-7 | The survey's verdicts, binding: the four views in §1 move. Every other measure is geometry and stays: `PersonFamilySection` (`PersonFamilyDiagram.width` → `PersonFamilyLayout` sizes, no branch on width), `PersonRecordLinksColumn` (width → `CircularLinkDiagram` size; `headerHeight`), `WorkspaceContent` (`contentWidth` → `fittedPanelWidth` overlay placement), `CircularLinkDiagram` (node size), `ConclusionPinnedSideColumn` (side height; its `stacked` reads `PVPageColumnsMetrics.sideColumnWidths(…).stacked`, the pure rule `PVPageColumnsLayout` places by, so the choice is the `Layout`'s), the remaining `PersonTimelineSection` measure (item heights), `PVPageColumns` (viewport size, `PVPageVisibleRect` frame; its beside-or-stacked choice is `PVPageColumnsLayout` and `PVColumnSplit.stacks(available:widthClass:)`, a `Layout` sizing from its proposal, not a measure), `PVFittedScroll` (content height), `PVTextArea` (line and content heights), `PVList` and `SourceFormLoadArea` (skeleton bar widths as a fraction), `PVComboBox` (rows height), `PVReorderableList` (row heights), `WorkspaceToolbar` (anchor frames), `WorkspaceSidebar` (height), and the composer's new panel-branch `GeometryReader` (height share, D-8). `EvidenceGraphView`'s header is a fit to content (`iconOnly` compares the header's width with the labeled row's own measured width) and stays: its threshold is not a breakpoint | The map asks each measure to be moved or named. A fit to content is what `ViewThatFits` does, which the map rules out for this PR, and its threshold changes with the title, against D-4 | Moving the Evidence graph header with a measured threshold — because it breaks D-4 |
| D-8 | `CitationComposerView` gains `static let threeUpFrom: CGFloat = 1400` (internal, doc: "From this split width the viewer, the evidence column and the observations sit side by side."). `composeSplit` becomes `PVWidthBreakpoints([Self.threeUpFrom]) { met in HStack(alignment: .top, spacing: 0) { evidence(threeUp: met.isAtLeast(Self.threeUpFrom)); …observations column as today… } }`. `evidence(threeUp:height:)` becomes `evidence(threeUp:)`; its panel branch wraps today's bare `VStack(spacing: 0) { … }` in a `GeometryReader { geo in … }` and caps the evidence column at `geo.size.height * 0.55`; the `VStack`'s modifiers today (`.frame(maxWidth: .infinity, maxHeight: .infinity)`, `accessibilityElement`, `accessibilityLabel`, the trailing divider `overlay`) move onto the `GeometryReader`, in the same order | The width choice moves; the height share is geometry and keeps a reader, inside the only branch that uses it. The panel `VStack` already fills the split's height, so the height is today's | `containerRelativeFrame` for the height — because its container is the window or scroll view, not the split |
| D-9 | Tests: pure tests of `PVBreakpointsMet` (AC-2.1, 2.2, 2.4), two hosted forced-layout tests of `PVWidthBreakpoints` on a `.hostedWindows` suite (AC-1.5, AC-2.3), and the three existing pure tests moved onto the new signatures with the same widths and results. No hosted test of the four views; the composer has no test (it has none today) and is in the manual check | Batch 3 rule: tests stay low-cost; S16-35's pattern (force layout, assert at once) | Hosting the Sources list or the Timeline — because their rules are pure and tested pure |

| D-10 | `PVWidthClass` gains `static let breakpoints: [CGFloat] = [PVSpacing.widthWideBreakpoint]` and `init(_ met: PVBreakpointsMet)` (`.wide` when `met.isAtLeast(PVSpacing.widthWideBreakpoint)`), and keeps `init(paneWidth: CGFloat)` as a one-line wrapper (`self.init(PVBreakpointsMet(breakpoints: Self.breakpoints, width: paneWidth))`), so the rule is written once; the four previews that copy `width >= PVSpacing.widthWideBreakpoint ? .wide : .regular` (`PersonTimelineSection.swift` `PersonTimelinePreview` ×2, `PersonDetailNoticePreviews.swift`, `PersonSourcesSection.swift`) call `PVWidthClass(paneWidth: width)` instead. `PVMeasuresWidthClass.body` becomes `PVWidthBreakpoints(PVWidthClass.breakpoints) { met in content.environment(\.pvWidthClass, PVWidthClass(met)) }`; its `@State` goes. `pvMeasuresWidthClass()`'s name, doc and one call site stay | One measuring mechanism in the kit (user, 2026-11-16, review M-1). The pane host already fills the detail area, so the container's frame changes nothing; D-3's none-met start is today's `.regular` | Leaving the pane on its own `onGeometryChange` — because the next fix to the first-frame reading or the fill rule would be made twice |

**Rules this plan bends.** None. The map's scope entry said "modifier"; D-1 makes it a container, and the map row and scope entry were changed with this plan (a technical shape, reported to the user).

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `PVBreakpointsMet` *(new)* | type | `PVWidthClass` (`PVWidthClass.swift`) | `PVWidthClass` is the pane's one fixed breakpoint (1600); this takes the caller's list. Searched `rg "breakpoint" macos/App`: only `widthWideBreakpoint` |
| `PVWidthBreakpoints` *(new)* | component | `PVMeasuresWidthClass` (pane, environment), `PVPageVisibleRect` (container with a reading) | D-1: the environment shape does not reach a reader in the same body; it follows `PVPageVisibleRect`'s shape |
| `Components/WidthClass/PVWidthBreakpoints.swift` *(new)* | file | `Components/WidthClass/PVWidthClass.swift` | Same folder, so no new README row: the WidthClass row names both |
| `PVTable.breakpoints(_:)` *(new)*, `shownColumns(_:met:)` (replaces `shownColumns(_:tableWidth:)`) | func | `PVTableColumnGate.shownIDs` | Replaces it (Deletes) |
| `SourcesListColumns.breakpoints` *(new)*, `init(met:widthClass:)` (replaces `init(listWidth:widthClass:)`) | static, init | `compactBelow` | The list is `[compactBelow]`; one source for the value |
| `PersonTimelinePlacement.stacksBelow(_:)` *(new)*, `stackBreakpoints` *(new)*, `stacksPeople(_:widthClass:)` (replaces `stacksPeople(itemsWidth:widthClass:)`) | func, static | `textWidth(itemsWidth:widthClass:)` | `stacksBelow` is the same sum solved for the width: `minimumTextWidth + gutterWidth + rowPicture + peopleWidth(widthClass) + 4 * rowGap` |
| `CitationComposerView.threeUpFrom` *(new)* | static | the literal `1400` | Names the breakpoint the container is given |
| `macos/ProvenenciaTests/PVWidthBreakpointsTests.swift` *(new)* | test file | `PVWidthClassTests.swift` | Copies its probe and forced-layout pattern |

**Builds on.** `PVPageVisibleRect`'s container shape; S15-49's "measure the result, not the width"; `hostInBorderlessWindow` + `.hostedWindows` + `layoutSubtreeIfNeeded()` (S16-34, S16-35).
**Deletes.** `PVTableColumnGate` (the enum and `shownIDs(gates:tableWidth:)`); `PVTable.shownIDs` and the private `shownColumns` property; `PVTable.shownColumns(_:tableWidth:)`; `SourcesListContent.listWidth`, its `columns` property and the `ScrollView`'s `onGeometryChange`; `SourcesListColumns.init(listWidth:widthClass:)`; `PersonTimelineSection.itemsWidth` and its `onGeometryChange`; `PersonTimelinePlacement.textWidth(itemsWidth:widthClass:)` (its last caller goes) and `stacksPeople(itemsWidth:widthClass:)`; the composer's whole-split `GeometryReader` and the `height:` parameter of `evidence`.
**Next adds.** The Person page Sources rows' narrow arrangement ([`docs/ideas/wide-layout.md`](../../../ideas/wide-layout.md) "Narrow panes", `PersonSourcesColumns`) is a compact-row breakpoint like `SourcesListColumns.compactBelow`: one `PVWidthBreakpoints` around its rows. A view that switches layout at its own width wraps itself in `PVWidthBreakpoints` with its constants; a new optional table column is one more `minTableWidth` (S15-49's slot, unchanged).

### Reach

None — no new path into existing code and no new state: each view is built from the same inputs, at the same widths.

### Scale

At the map's Scale (a Person with 200 events, 3,000 Sources): no write, list or query changes. The work per resize drops: today the Sources list and the Timeline store a `CGFloat` and rebuild their rows on every point of width change; after, they rebuild only when a breakpoint is crossed. No budget is set or leaned on.

### Edges

- **Assumptions.** The container fills the width it is offered (held by its own `.frame(maxWidth: .infinity)`; T-4). Breakpoints are fixed for its life (D-4; all callers' lists are constants or static columns, checked in §4). The first layout pass delivers the reading before drawing (T-3; Stop condition).
- **Neighbors.** Exactly at a breakpoint is met (880 → full rows, 1200 → Description, 772 → beside, 1400 → three-up); just under is not (879.5, 1199, 771, 1399). Held by T-1, T-5, T-6, T-7.
- **Removed inputs.** None — no input can be decided, excluded or deleted; the width is the only input.
- **Real data.** None — no table, seed or configuration drives the rule.
- **Untrusted size.** None — breakpoints come from code, not data. Duplicates and order are normalized (AC-2.4); an empty list reads "none met" and never reports again.

### Schema

None — no catalog change.

### Go core

None — Swift only.

### FFI

None — no engine call changes.

### macOS

```swift
// Components/WidthClass/PVWidthBreakpoints.swift (new)

/// Which of a container's breakpoints its width meets. Equal readings for two
/// widths mean no breakpoint lies between them.
struct PVBreakpointsMet: Equatable, Sendable {
    init(breakpoints: [CGFloat], width: CGFloat)
    /// `breakpoint` is one of those this reading was built with.
    func isAtLeast(_ breakpoint: CGFloat) -> Bool
}

/// Fills the width it is given, measures it, and builds its content for the
/// breakpoints that width meets; content is rebuilt only when one is crossed.
struct PVWidthBreakpoints<Content: View>: View {
    init(_ breakpoints: [CGFloat], @ViewBuilder content: @escaping (PVBreakpointsMet) -> Content)
}
```

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Own-width breakpoints | `PVWidthBreakpoints` *(new)* | `macos/App/DesignSystem/Components/WidthClass/PVWidthBreakpoints.swift` | Component layer: no catalog or feature types. Two `#Preview`s, "800pt" and "1300pt": `PVWidthBreakpoints([1200]) { met in Text(verbatim: "≥ 1200: \(met.isAtLeast(1200))") }.frame(width: 800)` and the same at 1300 |
| Table | `PVTable` | `macos/App/DesignSystem/Components/Table/PVTable.swift` | D-5 |
| Sources list | `SourcesListContent` | `macos/App/Features/Sources/SourcesListView.swift` | D-6 |
| Timeline | `PersonTimelineSection` | `macos/App/Features/Conclusions/PersonTimelineSection.swift` | The `PersonTimelineStack` (with its `.frame(maxWidth: .infinity, alignment: .leading)` removed, the container provides it) goes inside `PVWidthBreakpoints(PersonTimelinePlacement.stackBreakpoints) { met in … }`; `stacksPeople: PersonTimelinePlacement.stacksPeople(met, widthClass: widthClass)`; `.pvScrollsRowIntoView(…)` stays on the outside |
| Composer | `CitationComposerView` | `macos/App/Features/CitationComposer/CitationComposerView.swift` | D-8 |

States: unmeasured → D-3. Accessibility: unchanged; the container adds no element.

### Strings

None — no copy changes.

## 7. Steps

**STEP-1 — The container and its reading, and the pane measure on it**
Files: `macos/App/DesignSystem/Components/WidthClass/PVWidthBreakpoints.swift` *(new)*, `macos/ProvenenciaTests/PVWidthBreakpointsTests.swift` *(new)*, `macos/App/DesignSystem/Components/WidthClass/PVWidthClass.swift`, `macos/ProvenenciaTests/PVWidthClassTests.swift`. Skills: `add-ui-component`, `add-swift-test`.
Do: write T-1 – T-4 first, then `PVBreakpointsMet` and `PVWidthBreakpoints` per D-1 – D-3 and the § 6 sketch. Doc comments state the fill rule and D-4. Then D-10, including the four previews (`macos/App/Features/Conclusions/PersonTimelineSection.swift`, `PersonDetailNoticePreviews.swift`, `PersonSourcesSection.swift`); `PVWidthClassTests` stay as they are (T-8).
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/PVWidthBreakpointsTests -only-testing:ProvenenciaTests/PVWidthClassTests CODE_SIGNING_ALLOWED=NO` passes; `rg -n "widthWideBreakpoint \? \.wide" macos/App` prints nothing.

**STEP-2 — The table's column gate**
Files: `macos/App/DesignSystem/Components/Table/PVTable.swift`, `macos/ProvenenciaTests/PVTableTests.swift`.
Do: D-5. `PVTableColumn.minTableWidth`'s doc gains "Fixed for the table's life: a table's columns do not change their `minTableWidth` while it is shown." Delete `PVTableColumnGate`, `shownIDs` and the private `shownColumns`. The contract bullet (line 22–23) reads "Columns also decide whether they show (`minTableWidth`, read through `PVWidthBreakpoints`), so the header and the rows always agree." Rewrite T-5.
Check: `-only-testing:ProvenenciaTests/PVTableShownColumnsTests` passes; `rg -n "PVTableColumnGate|shownIDs" macos` prints nothing.

**STEP-3 — The Sources list**
Files: `macos/App/Features/Sources/SourcesListColumns.swift`, `macos/App/Features/Sources/SourcesListView.swift`, `macos/ProvenenciaTests/SourcesModelTests.swift`.
Do: D-6. Keep the struct's doc comment; delete the doc comment on `listWidth` with the property. T-6.
Check: `-only-testing:ProvenenciaTests/SourcesModelTests` passes; `rg -n "listWidth" macos` prints nothing.

**STEP-4 — The Timeline**
Files: `macos/App/Features/Conclusions/PersonTimelinePlacement.swift`, `macos/App/Features/Conclusions/PersonTimelineSection.swift`, `macos/ProvenenciaTests/PersonTimelinePlacementTests.swift`.
Do: add `static func stacksBelow(_ widthClass: PVWidthClass) -> CGFloat`, `static let stackBreakpoints: [CGFloat] = [stacksBelow(.regular), stacksBelow(.wide)]`, `static func stacksPeople(_ met: PVBreakpointsMet, widthClass: PVWidthClass) -> Bool` (`!met.isAtLeast(stacksBelow(widthClass))`); delete `textWidth(itemsWidth:widthClass:)` and `stacksPeople(itemsWidth:widthClass:)` (`textCap` and `minimumTextWidth` stay); the section per § 6 macOS. T-7.
Check: `-only-testing:ProvenenciaTests/PersonTimelinePlacementTests` passes; `rg -n "itemsWidth|textWidth" macos` prints nothing.

**STEP-5 — The Citation composer**
Files: `macos/App/Features/CitationComposer/CitationComposerView.swift`.
Do: D-8.
Check: the app builds (`scripts/check-pr.sh`'s Xcode step, or `xcodebuild build -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO`); `rg -n "1400" macos/App/Features/CitationComposer` prints only `threeUpFrom`.

**STEP-6 — Teach it, and check the survey**
Files: `docs/macos-client-patterns.md` (§ 9), `docs/ideas/wide-layout.md`, `macos/App/DesignSystem/README.md` (WidthClass row), `.agents/skills/add-ui-component/SKILL.md`.
Do: § 9 — after the paragraph that introduces `PVWidthClass` (line 266), one paragraph: a view that chooses its own layout from its own width and builds different content for it (a table column shown or hidden, compact rows, cards inside or under a title, the composer's side or panel evidence column) wraps itself in `PVWidthBreakpoints` with its breakpoints and reads `isAtLeast`; the container fills the width it is given, so the layout it builds cannot change the width that chose it; it redraws only when a breakpoint is crossed; breakpoints are constants (one per width class when the choice depends on it); the width class still decides bands and page layout; a fit to content (does this row fit) is not a breakpoint; placing the same subviews beside or stacked is a `Layout`'s job (`PVPageColumnsLayout` with `PVColumnSplit` `.whenNarrow`, or a page `Layout` with a static `arrange`), which keeps view identity and holds no state. The `add-ui-component` example's GOOD block opens with this comment line, inside the code block: `// For a choice of content by width. A fit to content is ViewThatFits; the same subviews beside or stacked are a Layout.` Rule 3's sentence: "(`PVTableColumn.minTableWidth`, read through `PVWidthBreakpoints`)". README WidthClass row: append "; `PVWidthBreakpoints.swift`: a view's own width against its breakpoints (`PVBreakpointsMet.isAtLeast`), for a layout choice inside a page — the table's optional columns, the Sources list's compact rows". `docs/ideas/wide-layout.md`: the Citation composer row → "Its 1400pt two-up / three-up switch reads its own width through `PVWidthBreakpoints` (`CitationComposerView.threeUpFrom`, S16-39); its brief decides whether the width class also changes it (S14-24 review M-2)"; the Narrow panes bullet on the Person page Sources rows ends "; the narrow rows switch at their own width with `PVWidthBreakpoints`, as the Sources list does". `add-ui-component`: one Anti-patterns example, a new code block appended after the last one (before "## Steps when adding a component") — `// ❌ BAD` an `@State var width` set by `onGeometryChange` and compared with a constant in `body`; `// ✅ GOOD` `PVWidthBreakpoints([880]) { met in … met.isAtLeast(880) … }`.
Check: AC-2.5's `rg` prints only the files D-7 names; `python3 scripts/check-guidance-names.py` passes.

**STEP-7 — Full check**
Do: run `scripts/check-pr.sh` once (one `xcodebuild` at a time: Batch 3 rule).
Check: `check-pr: PASS`.

**STEP-8 — Docs**
Files: `docs/deployment-plan/spike-16/completed.md`, `docs/deployment-plan/spike-16/deployment-plan.md` (map row status), this plan (status, Landed note).
Do: per the Definition of done.
Check: links resolve; `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-39-own-width-breakpoints.md` reports no errors.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `macos/ProvenenciaTests/PVWidthBreakpointsTests.swift` `PVBreakpointsMetTests.meetsABreakpointFromItsWidth` *(new)* | `[880, 1200]` at 0, 879.5, 880, 1199, 1200, 5000 → AC-2.1's table | AC-2.1, D-2 |
| T-2 | Swift | same file · `readingsBetweenTwoBreakpointsAreEqual` *(new)* | `[880]`: 900 == 1100; 870 != 900. `[1200, 880, 1200]` at 1000 == `[880, 1200]` at 1000. `[]` at 0 == `[]` at 5000 | AC-2.2, AC-2.4 |
| T-3 | Swift | same file · `PVWidthBreakpointsTests.contentIsBuiltForTheWidthAfterOneLayout` *(new)*, suite `.hostedWindows` | The content is a private `BreakpointsProbe` view *(new, test file)* given `met`: a `Text(verbatim: "probe")` with `.onAppear` and `.onChange(of: met)` writing `met.isAtLeast(1200)` into a private `@MainActor final class` box, as `PVWidthClassTests.WidthClassProbe` does; the host view is the bare `PVWidthBreakpoints` (no outer frame: the container fills); `hostInBorderlessWindow(…, windowSize: 1300 × 400)`; one `layoutSubtreeIfNeeded()` → `true`. `window.setContentSize(1100 × 400)`; one more pass → `false` | AC-1.5, D-3 |
| T-4 | Swift | same suite · `measuresTheWidthItFillsNotItsContent` *(new)* | Content is the same `BreakpointsProbe`; the bare container, no outer frame; host 2000 × 400; one pass → `isAtLeast(1200)` is `true` | AC-2.3, D-1 |
| T-5 | Swift | `macos/ProvenenciaTests/PVTableTests.swift` `PVTableShownColumnsTests.optionalColumnShowsFromItsMinimumTableWidth` (rewritten) | `breakpoints(columns) == [1200]`; `shownColumns(columns, met: PVBreakpointsMet(breakpoints: breakpoints(columns), width: 1199))` → `["a","c"]`; 1200 → `["a","b","c"]`; 0 → `["a","c"]` | AC-1.1, D-5 |
| T-6 | Swift | `macos/ProvenenciaTests/SourcesModelTests.swift` `listColumnsMatchBoard`, `columnsPlaceTheDateByWidth` (rewritten) | Same widths and expectations, built with `SourcesListColumns(met: PVBreakpointsMet(breakpoints: SourcesListColumns.breakpoints, width: w), widthClass:)` | AC-1.2, D-6 |
| T-7 | Swift | `macos/ProvenenciaTests/PersonTimelinePlacementTests.swift` `narrowListStacksPeople` (rewritten) | `stacksBelow(.regular) == 772`, `stacksBelow(.wide) == 1402`; `stacksPeople(PVBreakpointsMet(breakpoints: stackBreakpoints, width: 771), widthClass: .regular)` true, 772 false; Wide 1401 true, 1402 false | AC-1.3, D-4 |
| T-8 | Swift | `macos/ProvenenciaTests/PVWidthClassTests.swift` `classFollowsPaneWidth`, `modifierFollowsTheWindow`, `aFilledHostMeasuresTheSpaceNotTheChild` (unchanged) | Same arguments and results, now through the reading and the container | AC-2.6, D-10 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `PVTableTests`, `SourcesModelTests`, `PersonTimelinePlacementTests`, any test hosting `SourceTypesListPane` or the Sources list.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none expected)
- [ ] Sweep: `PVTableColumnGate`, `shownIDs`, `shownColumns(_:tableWidth:)`, `init(listWidth:`, `listWidth`, `itemsWidth`, `textWidth(itemsWidth:`, `stacksPeople(itemsWidth:`, `PVBreakpointWidth` each `rg`'d across `.agents/`, `.cursor/rules/`, `docs/*.md`, `docs/ideas/`, `macos/App/DesignSystem/README.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] `rg -n "composeSplit|1400pt" docs/ideas` shows only the rewritten Citation composer row
- [ ] AC-2.5's rg prints only the files D-7 names
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none)
- [ ] UI matches today's at both sides of each breakpoint; no new kit primitive beyond `PVWidthBreakpoints`
- [ ] Version bump: none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief: none (not gated)
- [ ] Domain doc updated: § 9 of docs/macos-client-patterns.md (STEP-6)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

Use any project with a few Sources, a Person with a Timeline that has participants, and a Source with an Artifact.

1. (AC-1.1, AC-1.5) Open **Source types** with the window at its default size (pane ~1102pt): no Description column. Widen the window until the table is at least 1200pt wide: Description appears; narrow it again: it goes. Close and reopen the list at the wide size: Description is there on the first frame.
2. (AC-1.2, AC-1.5) Open **Sources** at the default size (list over 880pt): Type column shown. Narrow the window until the list is under 880pt: rows go compact (type and date on a line under the title). Reopen the list at the narrow size: compact on the first frame; reopen at the default size: full rows on the first frame, with no compact frame before them.
3. (AC-1.3) Open the Person's page, **Timeline**: at the default window the people cards sit beside or under the title as they did before this PR (compare with `main` at the same window size); narrow the window: they move under the title at the same point as on `main`.
4. (AC-1.4) Open the **Citation composer** on the Source: under 1400pt of split the evidence column sits over the viewer; widen past 1400pt: viewer, evidence column and observations sit side by side.
5. Open **Metadata** (a vocabulary list) and **Properties**: each table fills the pane as on `main`.
6. (AC-2.5) Run `rg -n -e onGeometryChange -e GeometryReader macos/App`: every file it prints is `PVWidthBreakpoints.swift` or named in D-7.
7. (AC-2.6) Resize the window across a 1600pt pane (collapse and expand the sidebar near it): the Sources list's Published column and the Person page's side column come and go as on `main`.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| The first frame draws before the reading arrives (a pop-in on open) | T-3 asserts the reading after one pass; manual check steps 1–2 reopen at the wide and narrow sizes |
| The container's `.frame(maxWidth: .infinity)` changes a caller's horizontal size | Every wrapped view already fills its width (`ScrollView`s, `.frame(maxWidth: .infinity)` stack, the composer's split); manual check compares with `main` |
| The composer's panel branch reads a different height | D-8: its `VStack` already fills the split's height |

**Stop and report if:**

- No macOS machine with Xcode is available to run `xcodebuild` (STEP-1 – STEP-7 and T-3 need one; a Linux session cannot give the evidence). Stop before STEP-1.
- T-3 needs a second `layoutSubtreeIfNeeded()` or a wait to see the right reading (D-3's "corrected before the frame is drawn" is wrong).
- A wrapped view draws narrower or wider than on `main` at the same window size (the container's frame changed its layout).
- A measure in `macos/App` that is not in D-7's list turns a width into a layout choice.
- `PersonTimelinePlacement.stacksBelow(.regular)` is not 772 or `stacksBelow(.wide)` is not 1402.
- The Swift compiler warns on the `@escaping` content closure or the geometry closure's Sendable capture and the warning cannot be fixed inside `PVWidthBreakpoints.swift`.

## 12. Open questions

None.

## 13. PR

**Title:** S16-39 — One container measures its own width and tells its content which layout fits
**Body:** objective in one sentence; what shipped against US-1 and US-2; AC evidence; the survey (D-7); deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-39-own-width-breakpoints.md`.
