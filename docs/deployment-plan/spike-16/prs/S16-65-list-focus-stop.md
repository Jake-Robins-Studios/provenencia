# S16-65 — One kit focus stop for a list of rows

**Status:** Landed in [#951](https://github.com/Jake-Robins-Studios/provenencia/pull/951) (2026-11-22)

**Landed:** the kit README link to `kit-layering.md` is `../../../docs/ideas/kit-layering.md` (the step's `../../../../` does not resolve from that folder); the README and `add-ui-component` edits ride in their own commit.
**Spike / slice:** Spike 16 · Slice 6f — Sources list keyboard
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: the Persons, Events and Places lists look and behave as today; the code that draws their focus moves, not the drawing)
**Board:** —
**Depends on:** —
**Blocks:** S16-66
**Branch:** `s16-65-list-focus-stop`
**Version bump:** none — a preparatory refactor with no change a researcher can see, no wire change and no catalog format change, as S16-59 and S16-64 ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** —
**Context:** map scope entry [S16-65](../deployment-plan.md#s16-65--one-kit-focus-stop-for-a-list-of-rows); bar 37; working rules: "(Batch 6) A list of rows is one kit focus stop"; kit README [`macos/App/DesignSystem/README.md`](../../../../macos/App/DesignSystem/README.md) List and ScrollRowIntoView rows
**Planned:** 2026-11-22 against `main` @ `8fcb625`
**Review:** [`S16-65-list-focus-stop.review.md`](S16-65-list-focus-stop.review.md) — Fits with changes / Ready with changes, 1 round

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

`PVList` is the kit's browse list: one focus stop whose focused row moves with ↑/↓ (⌥ to an end), Home/End and Page Up/Down, scrolls into view, and opens on Return or Space. That keyboard lives inside `PVList.body`, so a list whose rows are not `PVList`'s fixed shape cannot have it. The Sources list is such a list (a row holds the Source link and one button per Evidence graph), so today Page Up, Page Down, Home and End do nothing there. This PR moves the focus stop out of `PVList.body` into a kit modifier, `.pvListFocusStop`, that any column of rows can wear, and `PVList` wears it. S16-66 then puts the Sources list on it.

**Why now.** The user asked for Page Up, Page Down, Home and End in the Sources list (2026-11-22) and chose to fix the list's setup over a Sources-only key handler (rule "(Batch 6) A list of rows is one kit focus stop").

**What stays.** Every `PVList` (the Persons, Events and Places lists through `ConclusionListPage`) looks and behaves exactly as today: the same keys, the same focus ring on the focused row, the same scrolling, the same VoiceOver. `PVListKeyboard` keeps its movement rule. `PVTable` keeps its own selection keys.

## 2. User stories

**US-1.** As a researcher on the Persons, Events or Places list, I move through the list with the keyboard exactly as before, so nothing I rely on changes.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Persons list with 30 people; Tab until the list is focused; press ↓ twice | The third row shows the focus ring |
| AC-1.2 | Same list, third row focused; Page Down; then End; then Home | The 13th row is focused; then the 30th, scrolled into view; then the first |
| AC-1.3 | Same list, a row focused; Return | That person's page opens |
| AC-1.4 | Same list; ⌥↓ | The last row is focused |

**US-2.** As a contributor building a list of custom rows, I wear one kit modifier and get the list keyboard, so I never write a second focus stop.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | `focusIndex` 7 and a list of 3 rows (the list shrank) | The ring and the keys use index 2 (`PVListKeyboard.clampedIndex(7, count: 3)` = 2); the scroll row stays nil, as today (D-5) |
| AC-2.2 | `focusIndex` 0 and a list of 0 rows | `PVListKeyboard.clampedIndex(0, count: 0)` = 0, and no key is handled (`PVListKeyboard.action` returns `.ignore` for count 0) |
| AC-2.3 | `rg -n "\.onKeyPress" macos/App/DesignSystem/Components/List/PVList.swift` | Prints nothing: `PVList` has no key handler of its own |

## 3. Scope

| In | Covered by |
| --- | --- |
| `.pvListFocusStop` *(new)* in `Components/List/PVListFocusStop.swift` *(new)*: `.pvScrollsRowIntoView` on the focused row, `.focusable()`, `.focusEffectDisabled()`, `.focused`, `.onKeyPress` through `PVListKeyboard.action` | STEP-2, AC-1.1 – AC-1.4 |
| `PVListKeyboard.clampedIndex(_:count:)` *(new)*, the clamp `PVList.currentIndex` does today; `currentIndex` goes | STEP-1, STEP-3, AC-2.1, AC-2.2 |
| `PVList` wears the modifier; its own key handler, scroll and focus modifiers go | STEP-3, AC-2.3 |
| The kit README's List row and `add-ui-component`'s anti-patterns name the modifier | STEP-4 |

| Out | Home |
| --- | --- |
| The Sources list on the modifier | S16-66 |
| `PVTable` on the modifier (it has a selection, type-to-select and Escape, and rings the whole table) | not planned |
| `PVTable.handleKey`'s movement keys onto `PVListKeyboard.moveIndex`, and `PVTableSelection.moveIndex` deleted | [`docs/ideas/kit-layering.md`](../../../ideas/kit-layering.md) "The table writes its own movement keys" |
| ←/→ into a row's secondary buttons | S16-66's Out (not planned) |
| A `pageStep` other than `PVListKeyboard.pageStep` (10) for a caller | not planned: no caller needs one |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| List focus stop | `macos/App/DesignSystem/Components/List/PVList.swift` `PVList.body` (lines 99–134) | `LazyVStack` of rows → `.scrollTargetLayout()` → `.pvScrollsRowIntoView(items[focusIndex].id, animated: false)` → `.pvListChrome()` → `.focusable()` → `.focusEffectDisabled()` → `.focused($isFocused)` → `.onKeyPress` that maps `PVListKeyboard.action(for:option:index:count:)` to `focusIndex = index` (`.move`), `onActivate(items[index])` (`.activate`) or `.ignored` → `.accessibilityElement(children: .contain)` and `.accessibilityLabel`. Wrong for this PR: none of it is reachable by a list that is not a `PVList` |
| Focus state | `PVList` `@FocusState private var isFocused`, `@State private var focusIndex = 0`, `currentIndex` (`min(focusIndex, max(0, items.count - 1))`) | Owned by the view; the row style reads `isFocused && index == currentIndex`; a click on a row sets `focusIndex = index` before `onActivate` |
| Movement rule | same file `PVListKeyboard.action`, `moveIndex`, `pageStep` | Pure; stays as is |
| Row chrome | same file `PVListRowStyle(focused:)`, `PVListRowBody` | Draws the focus ring from `focused` (or the button's own focus when nil, which the Sources list passes) |
| Scroll into view | `macos/App/DesignSystem/Components/ScrollRowIntoView/PVScrollRowIntoView.swift` `.pvScrollsRowIntoView` | The one kit way to keep a row in view; the README says not to add another `ScrollViewReader` for this |
| Caller | `macos/App/Features/Conclusions/ConclusionListPage.swift` `PVList(…)` (line 163) | The only `PVList` caller: the Persons, Events and Places lists. No change |
| Tests | `macos/ProvenenciaTests/PVListTests.swift` `PVListTests` | Pure tests of `PVListKeyboard.action` and `moveIndex`; nothing tests `PVList.body` |

**Precedent.** `131abdb` ("Move a popup list's highlight, its landing and its movement keys onto one kit rule.") moved the popup list's keys out of its callers into one kit piece that the combo box and the omnibar both wear. Copy its shape: the pure rule stays in `PVListKeyboard`, the view glue becomes one kit piece, and the old copy goes in the same commit.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | A `View` extension `pvListFocusStop(count:rowID:focusIndex:isFocused:onActivate:)` *(new)* backed by a `private struct PVListFocusStop: ViewModifier` *(new)* in `Components/List/PVListFocusStop.swift` *(new)* | A modifier is the kit's shape for behaviour a caller's own views wear (`.pvScrollsRowIntoView`, `.pvPopup`); it lives beside `PVList` in the List folder (add-ui-component: one folder per control, helpers colocated) | A generic `PVRowList<Row>` container view — it would fix the stack and the chrome, which the Sources list (a `LazyVStack` with a pinned caption band) does not share; a Sources-only handler — the user chose the kit fix |
| D-2 | The caller owns the state: `focusIndex: Binding<Int>` and `isFocused: FocusState<Bool>.Binding`. The modifier owns none | The row view must read both to draw its ring (`PVListRowStyle(focused:)`) and a click sets `focusIndex`; `@FocusState` can only be declared in a `View` | State inside the modifier with a preference back out — two sources of truth for one focused row |
| D-3 | The modifier takes `count: Int` and `rowID: (Int) -> ID` (`ID: Hashable`), not an array of ids | A `PVList` holds up to 16,000 persons at the Batch 2 Scale; building an id array on every body pass would be a second O(n) copy beside the `ForEach`. `rowID` is called once per pass, for the focused row only | `ids: [ID]` — an allocation per render for nothing |
| D-4 | `onActivate: (Int) -> Void` takes the row index; the caller maps it to its item | The modifier knows indices, not items; `PVList` passes `{ onActivate(items[$0]) }` | A generic `Item` — ties the modifier to `Identifiable` items the Sources list builds differently |
| D-5 | The modifier applies, in order: `.pvScrollsRowIntoView((0..<count).contains(focusIndex) ? rowID(focusIndex) : nil, animated: false)`, `.focusable()`, `.focusEffectDisabled()`, `.focused(isFocused)`, `.onKeyPress { … }`. The `.onKeyPress` body is today's with `index: PVListKeyboard.clampedIndex(focusIndex, count: count)`: `.move(let i)` sets `focusIndex.wrappedValue = i` and returns `.handled`; `.activate(let i)` calls `onActivate(i)` and returns `.handled`; `.ignore` returns `.ignored` | Today's behaviour, moved, scroll row included: a list that shrinks under the focused index does not scroll, as today (review X-3: clamping it would make a filtered list jump to its end) | A clamped scroll row — a visible change in a PR that promises none; a modifier that writes the clamp back on a count change (review M-1) — same jump, since the scroll follows the written row |
| D-6 | `PVList` keeps `.scrollTargetLayout()`, `.pvListChrome()`, the accessibility element and label, and applies them around the modifier in this order: `LazyVStack` → `.scrollTargetLayout()` → `.pvListChrome()` → `.pvListFocusStop(…)` → accessibility | The only reorder is `.pvScrollsRowIntoView` moving outside `.pvListChrome()`; `ScrollViewReader` lays out its content unchanged, so nothing drawn moves | Keeping chrome between the scroll and the focus modifiers — would split the modifier in two |
| D-7 | `PVListKeyboard.clampedIndex(_ index: Int, count: Int) -> Int` *(new)* = `min(index, max(0, count - 1))`, on `PVListKeyboard`. `PVList.currentIndex` goes; its row reads `PVListRowStyle(focused: isFocused && index == PVListKeyboard.clampedIndex(focusIndex, count: items.count))` | The clamp is the one rule the caller's ring and the modifier must share; it belongs beside the movement rule it feeds, and pure code is tested without a view | Each caller clamps on its own — the Sources list would write a second copy; keeping `currentIndex` as a one-line pass-through (review M-2) |
| D-8 | The focus is an index, as today: a re-sort, or a row added or removed above it, leaves the ring at the same index on another row | `PVList`'s behaviour today; the Persons, Events and Places lists are sorted by Go and do not re-sort under the ring. Whether the Sources list (which re-sorts on its settings) wants focus to follow the item is S16-66's decision, which can key its `focusIndex` from an id without changing this modifier | An id-keyed focus in the kit now — no caller needs it yet |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `pvListFocusStop(count:rowID:focusIndex:isFocused:onActivate:)` and `PVListFocusStop` *(new)* | modifier | `PVList.body`'s focus stop (moved, not copied); `PVPopupList`'s key glue (`131abdb`) | It is `PVList`'s own code, extracted; the popup list moves a highlight in a floating window, not a focused row in the page |
| `PVListFocusStop.swift` *(new)* | file | `Components/List/PVList.swift` | `PVList.swift` is 513 lines; the modifier is its own concern in the same folder |
| `PVListKeyboard.clampedIndex` *(new)* | func | `PVList.currentIndex`, `PVFloatingMenuSelection.moveIndex` (moves and clamps) | `currentIndex` is the same rule, private to the view, and goes; the movers move an index and clamp the result, while this holds a stale index in range without moving it |

Searched: `rg -n "focusable\(\)" macos/App` (PVList, PVTable, CitationComposerSubjectGroups, ConclusionPictureViewer, SourceTypeIconGrid — none a list of button rows besides PVList), `rg -n "PVListKeyboard\.(action|moveIndex)" macos/App` (PVList, PVTable's activation, PVContextMenu, PVPopupList).

**Builds on.** `PVListKeyboard` (the one movement rule), `.pvScrollsRowIntoView` (the one scroll-into-view), the List folder.
**Deletes.** `PVList.currentIndex` (replaced by `PVListKeyboard.clampedIndex`), and `PVList.body`'s `.pvScrollsRowIntoView`, `.focusable()`, `.focusEffectDisabled()`, `.focused` and `.onKeyPress` (replaced by the modifier).
**Next adds.** S16-66: the Sources list wears `.pvListFocusStop` on its `LazyVStack` and passes `focused:` to its Source link's `PVListRowStyle`. Any later list of button rows does the same.

### Reach

None — no new path into existing code; `PVList` reaches the same code through the modifier.

### Scale

At the Batch 2 Scale (16,000 persons in the Persons list): the modifier does O(1) work per body pass (one `rowID` call for the focused row, one clamp); the `ForEach` over the rows is `PVList`'s, unchanged.

### Edges

- **Assumptions.** The focused index can outlive the list it was set on (a filter or a reload shrinks it): `clampedIndex` holds it in range (T-1). An empty list: `PVListKeyboard.action` returns `.ignore` for count 0 (T-2, today's `PVListTests`), and the scroll row is nil.
- **Neighbors.** A list of one row: every movement key lands on 0 (T-2). Keys that are not list keys (letters, Tab, Escape) return `.ignored` as today, so Tab still leaves the list. A re-sort or a row added above the focused one: the ring stays on the index (D-8), as today.
- **Removed inputs.** None — no data is decided or deleted.
- **Real data.** None — no table-driven rule.
- **Untrusted size.** None — the rows are the app's own list.

### Schema

None — no catalog change.

### Go core

None — Swift only.

### FFI

None —

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| List focus stop | `.pvListFocusStop` *(new)* | `macos/App/DesignSystem/Components/List/PVListFocusStop.swift` | Component layer, content-agnostic; no catalog type |
| Browse list | `PVList` | `macos/App/DesignSystem/Components/List/PVList.swift` | Wears the modifier; draws as today |

Sketch (signature only):

```swift
extension View {
    /// One focus stop over a column of rows tagged `.id(rowID(i))`: ↑/↓ (⌥ to an end),
    /// Home/End and Page Up/Down move `focusIndex` (`PVListKeyboard`), the list scrolls
    /// to keep that row in view, and Return or Space calls `onActivate` with it.
    /// The caller draws the focused row from `isFocused` and
    /// `PVListKeyboard.clampedIndex(focusIndex, count:)`.
    func pvListFocusStop<ID: Hashable>(
        count: Int,
        rowID: @escaping (Int) -> ID,
        focusIndex: Binding<Int>,
        isFocused: FocusState<Bool>.Binding,
        onActivate: @escaping (Int) -> Void
    ) -> some View
}
```

States: empty (no key handled, nothing scrolled), shrunk (clamped). Accessibility: unchanged; the accessibility element and label stay on `PVList`, after the modifier.

### Strings

None — no copy.

## 7. Steps

**STEP-1 — The clamp joins the movement rule**
Files: `macos/App/DesignSystem/Components/List/PVList.swift`, `macos/ProvenenciaTests/PVListTests.swift`. Skill: `add-swift-test`.
Do: add `static func clampedIndex(_ index: Int, count: Int) -> Int` to `PVListKeyboard` (D-7) with the doc comment "Holds a focused index that may outlive its list (a filter, a reload) inside it; 0 for an empty list." `PVList.currentIndex` returns `PVListKeyboard.clampedIndex(focusIndex, count: items.count)` until STEP-3. Add T-1.
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/PVListTests` passes.

**STEP-2 — The modifier**
Files: `macos/App/DesignSystem/Components/List/PVListFocusStop.swift` *(new)*. Skill: `add-ui-component` (component; `PV` prefix; tokens only; no `Features/` type).
Do: write `PVListFocusStop` and `pvListFocusStop(…)` per D-1 – D-5 and the sketch. The `.onKeyPress` body is `PVList.body`'s, reading `focusIndex.wrappedValue` through the clamp and writing `focusIndex.wrappedValue = index` on `.move`. The doc comment on the extension is the sketch's. Add `private struct PVListFocusStopPreview: View` holding `@State private var focusIndex = 0` and `@FocusState private var isFocused: Bool`: a `ScrollView` around a `LazyVStack(spacing: 0)` of 30 rows, each a `Button { focusIndex = i } label: { Text(verbatim: "Row \(i + 1)").frame(maxWidth: .infinity, alignment: .leading).padding(PVSpacing.space5) }` with `.buttonStyle(PVListRowStyle(focused: isFocused && i == PVListKeyboard.clampedIndex(focusIndex, count: 30)))` and `.id(i)`; the stack wears `.pvListFocusStop(count: 30, rowID: { $0 }, focusIndex: $focusIndex, isFocused: $isFocused, onActivate: { focusIndex = $0 })`; no list chrome (`pvListChrome` is private to `PVList.swift`). End with `#Preview { PVListFocusStopPreview().frame(width: 320, height: 360) }`.
Check: the app builds (`xcodebuild build -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS'`) with no new warning.

**STEP-3 — `PVList` wears it**
Files: `macos/App/DesignSystem/Components/List/PVList.swift`.
Do: replace `PVList.body`'s `.pvScrollsRowIntoView`, `.focusable()`, `.focusEffectDisabled()`, `.focused($isFocused)` and `.onKeyPress { … }` with `.pvListFocusStop(count: items.count, rowID: { items[$0].id }, focusIndex: $focusIndex, isFocused: $isFocused, onActivate: { onActivate(items[$0]) })`, in D-6's order. Delete `currentIndex`; the row's style reads `PVListRowStyle(focused: isFocused && index == PVListKeyboard.clampedIndex(focusIndex, count: items.count))` (D-7). In the `PVList` doc comment, the keyboard sentence becomes "Keyboard (`.pvListFocusStop`): the list is one focus stop; ↑ / ↓ move the focused row (⌥ jumps to the ends), Home / End, Page Up / Page Down move by ten, Return / Space activate." Leave `focusIndex`, `isFocused` and the row's click (`focusIndex = index; onActivate(item)`) as they are.
Check: AC-2.3's `rg` prints nothing; `PVListTests` pass; the Persons list behaves per §10.

**STEP-4 — Docs**
Files: `macos/App/DesignSystem/README.md` (List row), `.agents/skills/add-ui-component/SKILL.md` (Anti-patterns), `docs/deployment-plan/spike-16/completed.md`, `deployment-plan.md` (map row), this plan (status).
Do: in the README List row, after "one focus stop with ↑/↓ · Home/End · Page Up/Down · Return/Space", add "through `.pvListFocusStop` (`PVListFocusStop.swift`), which any column of button rows tagged `.id` wears; the caller owns `focusIndex` and the `FocusState`, and draws its ring at `PVListKeyboard.clampedIndex`"; and change "`PVListKeyboard.moveIndex` is the one list of movement keys" to "`PVListKeyboard.moveIndex` is the list of movement keys (`PVTable` still writes its own: [`docs/ideas/kit-layering.md`](../../../../docs/ideas/kit-layering.md))". In `add-ui-component`'s `## Anti-patterns`, after its last fenced block and before `## Steps when adding a component`, add a `swift` block: `// ❌ BAD — a list of button rows with its own .focusable() and .onKeyPress moving a focused row` then `// ✅ GOOD — the rows' stack wears .pvListFocusStop(count:rowID:focusIndex:isFocused:onActivate:)`. Then per the Definition of done: `completed.md` gets a `### S16-65 — One kit focus stop for a list of rows` heading and a `**Landed YYYY-MM-DD** in [#N](…).` paragraph, as the entries above it; the map row Status is `Landed #N`; this plan's Status is `Landed in [#N](…) (YYYY-MM-DD)`.
Check: links resolve; `python3 scripts/check-guidance-names.py` passes.

Commits: one per behavior. The subject is one full imperative sentence that says what changed, ending in a period, like the rest of `git log` ("Move the list's focus stop and keys into a kit modifier any list of rows can wear."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `macos/ProvenenciaTests/PVListTests.swift` `clampedIndexStaysInTheList` *(new)* | (7, count 3) → 2; (2, count 3) → 2; (0, count 3) → 0; (0, count 0) → 0; (5, count 0) → 0 | AC-2.1, AC-2.2, D-7 |
| T-2 | Swift | `PVListTests` (existing: `arrowsMoveOneAndClampWithoutWrapping`, `optionArrowsAndHomeEndJumpToTheEnds`, the page and empty cases) | unchanged → pass | AC-1.1, AC-1.2, AC-1.4 (the rule), AC-2.2 |
| T-3 | Check | `rg -n "\.onKeyPress" macos/App/DesignSystem/Components/List/PVList.swift` | → no output | AC-2.3 |

The modifier's view glue (focus, key routing, scrolling) has no unit test: SwiftUI focus and key presses need a window, and the test host runs none (Batch 3). The manual check covers it.

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `PVListTests`, and a Swift warning from an unused `PVList` property after STEP-3.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: T-1 / T-2, AC-2.3's rg, and §10 for AC-1.1 – AC-1.4
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left — none added
- [ ] Sweep: `rg -n "currentIndex" macos/App/DesignSystem/Components/List` prints nothing; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated — none
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New — no brief; the modifier is the one new kit piece, with S16-66 as its second caller
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated) — not gated
- [ ] Domain doc updated if a rule in docs/*.md changed — none; the kit README and add-ui-component per STEP-4
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Open a project with at least 30 Persons. Open Persons. Press Tab until the list shows a focus ring on its first row (AC-1.1).
2. Press ↓ twice: the third row has the ring (AC-1.1). Page Down: the 13th. End: the last row, scrolled into view. Home: the first, scrolled back (AC-1.2). ⌥↓: the last. ⌥↑: the first (AC-1.4).
3. Press Return: that person's page opens (AC-1.3). Back: the Persons list.
4. Click a row: its page opens, as today. Back, then Tab into the list: the ring is on the clicked row.
5. Repeat step 2 on Events and Places. Nothing looks different from `main` on any of the three lists.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| Moving `.pvScrollsRowIntoView` outside `.pvListChrome()` changes the list's clip or scroll | D-6 reasons it does not; §10 step 2 checks it; Stop condition below |
| `FocusState<Bool>.Binding` passed into a modifier does not drive `.focused` the same way | It is the documented SwiftUI pattern (`PVFieldFocus` passes focus bindings across views); §10 step 1 checks the ring |

**Stop and report if:**

- `PVList.body` no longer matches §4's chain (another PR changed it).
- After STEP-3, §10 shows any difference from `main`: the ring on the wrong row, a key that no longer moves, or the list scrolling or clipping differently.
- `.focused(isFocused)` with a passed `FocusState<Bool>.Binding` does not focus the list on Tab.
- `PVList` has a caller other than `ConclusionListPage` (`rg -n "PVList\(" macos/App` shows another).

## 12. Open questions

None.

## 13. PR

**Title:** S16-65 — One kit focus stop for a list of rows
**Body:** objective in one sentence; what shipped against US-1 and US-2; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-65-list-focus-stop.md`.
