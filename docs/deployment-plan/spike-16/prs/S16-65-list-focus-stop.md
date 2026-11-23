# S16-65 — Page keys belong to the page's scroll view

**Status:** Landed in [#951](https://github.com/Jake-Robins-Studios/provenencia/pull/951) (2026-11-23)
**Spike / slice:** Spike 16 · Slice 6f — Page and list keyboard
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: no view draws anything new; keys that did nothing now scroll)
**Board:** —
**Depends on:** —
**Blocks:** S16-66, S16-67
**Branch:** `s16-65-list-focus-stop` (PR [#951](https://github.com/Jake-Robins-Studios/provenencia/pull/951), back to draft for this plan; its first round extracted `.pvListFocusStop`, which this plan keeps)
**Version bump:** none — a keyboard behavior in the app with no wire or catalog format change, as S16-59 ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** —
**Context:** map scope entry [S16-65](../deployment-plan.md#s16-65--page-keys-belong-to-the-pages-scroll-view); bar 37; working rule "(Batch 6) Page keys belong to the page's scroll view"; ship log [`S16-65-list-focus-stop.ship.md`](S16-65-list-focus-stop.ship.md) (the first round and the manual check that stopped it); kit README [`macos/App/DesignSystem/README.md`](../../../../macos/App/DesignSystem/README.md) List and ScrollRowIntoView rows
**Planned:** 2026-11-22 against branch `s16-65-list-focus-stop` @ `17fb862dd` (`main` @ `a0923028f` plus the first round's commits)
**Review:** [`S16-65-list-focus-stop.review.md`](S16-65-list-focus-stop.review.md) — re-plan: Fits with changes / Ready with changes, 2 rounds; M-7 answered by the user (2026-11-23)

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

Page Up, Page Down, Home and End scroll the page a researcher is looking at, whatever the page holds and whether or not anything on it has keyboard focus, as they do in Safari, Preview and Finder. Today they do nothing on most pages: a SwiftUI `ScrollView` on macOS handles none of them, and on a page with nothing focusable no view receives them. The one place they work, `PVList`, moves its focused row instead of scrolling. That is not the Mac's behavior: there, ↑/↓ move a list's selection and the page keys scroll the view without moving it.

This PR adds one kit scroll view, `PVPageScrollView`, that every workspace page scrolls in, `PVTable`'s row list included. A key that no focused view, text field or menu used travels up the window's responder chain to one kit responder, which scrolls the window's page the AppKit way. Sending a page back to its top on a section change moves into the same view, so the kit has one way to scroll a page to its top. `PVList`'s focus stop keeps ↑/↓ (⌥ to an end) and Return/Space and passes the page keys on.

**Why now.** The user asked for Page Up, Page Down, Home and End in the Sources list (2026-11-22). The first round of this PR made them a list feature; the manual check and the user's review (2026-11-22) moved them to the scroll view: "It's a function of the scroll view and has nothing to do with the content."

**What stays.** Every page looks as it does today. ↑/↓, ⌥↑/⌥↓, Return and Space in the Persons, Events and Places lists behave as today. A record page still returns to its top when its section changes. Text fields, text areas, popup lists, menus, a focused `PVTable` and the Evidence graph canvas keep their own keys.

**Not here.** The every-other-↓ bounce on the Persons list (it happens on `main` too) and the page's remembered scroll position: S16-67.

## 2. User stories

**US-1.** As a researcher on any page longer than the window, I press Page Down, Page Up, Home or End and the page scrolls, without clicking or tabbing first.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A Person page taller than the window, nothing focused; Page Down | The page scrolls down by one window height less AppKit's page overlap (`NSScrollView.pageDown`) |
| AC-1.2 | Same page; End; then Home | The page's bottom is in view; then its top |
| AC-1.3 | Same page; Page Up at the top, Page Down at the bottom, or any page key on a page shorter than the window | Nothing moves |
| AC-1.4 | The Persons list with 30 people, nothing focused; Page Down | The list page scrolls; no row gains the focus ring |
| AC-1.5 | A text field holding the cursor (the omnibar, a form field); Home, End | The field handles the key as today; the page does not scroll |
| AC-1.6 | Any page; ⌘↓, ⇧Page Down, ⌥Page Down, ⌃End | The page keys do not act; the key goes where it went before |
| AC-1.7 | The Source page, the Sources list, the Metadata page with a field selected, a Property's inspector, the Promote page, the Source types list with nothing focused | AC-1.1 and AC-1.2 hold on each (with the table not focused: click in the detail pane first; a focused table keeps its own page keys, Out); on Metadata and Properties, the list when the pointer is over it, else the detail pane |
| AC-1.8 | A Person page scrolled down; open another section from its section bar (`scrollResetKey` changes) | The page is at its top, as today |

**US-2.** As a researcher in the Persons, Events or Places list, ↑/↓ move the focused row and the page keys scroll the page, as in Finder.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Persons list, Tab until the first row has the ring; ↓ twice | The third row has the ring (as today) |
| AC-2.2 | Same; Page Down | The page scrolls one window; the ring stays on the third row, now off screen |
| AC-2.3 | Same; ↓ | The fourth row has the ring and scrolls into view |
| AC-2.4 | Same; ⌥↓; then Return | The last row has the ring (as today); then that person's page opens |
| AC-2.5 | `PVListKeyboard.action(for:option:index:count:)` with `.home`, `.end`, `.pageUp`, `.pageDown` | `.ignore` |

**US-3.** As a contributor, a new page scrolls in `PVPageScrollView` and gets the page keys and the reset to its top with no key code and no marker id of its own.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `rg -n "(^|[^A-Za-z])ScrollView \{" macos/App/Features/Conclusions/ConclusionListPage.swift macos/App/Features/Sources/SourcesListView.swift macos/App/Features/Metadata/MetadataDetailPane.swift macos/App/Features/Promote/PromoteView.swift macos/App/Features/Properties/PropertiesView.swift macos/App/DesignSystem/Components/PageColumns/PVPageColumns.swift macos/App/DesignSystem/Components/Table/PVTable.swift` | Prints nothing |
| AC-3.2 | `PVPageKeys.command(keyCode:modifiers:)` for each key code and modifier set in T-1 | The command T-1 lists |
| AC-3.3 | `rg -n "restartsAt|restartTop|restartKey|topAnchor" macos/App -g '*.swift' -g '*.md'` | Prints only lines in `macos/App/Features/ArtifactViewer/ArtifactPDFViewport.swift` (AppKit's `NSView.topAnchor`) |

## 3. Scope

| In | Covered by |
| --- | --- |
| `PVPageScrollView` *(new)*: a vertical `ScrollView` whose content carries a zero-size `PVPageScrollProbe` *(new)*; `startsAtTopWhen:` sends it to its top | STEP-2, AC-1.1 – AC-1.3, AC-1.8 |
| `PVPageKeys` *(new)*: the pure key rule (`command(keyCode:modifiers:)`), the edge scroll; `PVPageKeyResponder` *(new)*, the window responder | STEP-1, STEP-2, AC-1.1 – AC-1.6, AC-3.2 |
| The page sites move onto `PVPageScrollView`: `ConclusionListPage.page`, `PVPageColumns.scroll`, `SourcesListView` (the list's `ScrollView`), `MetadataDetailPane`, `PropertiesView.inspectorCard`, `PromoteView`, `PVTable.rowList` | STEP-3, AC-1.7, AC-3.1 |
| The reset to the top moves from `PVScrollRowIntoView`'s `restartsAt:whenChanged:` and `PVPageColumnsMetrics.topAnchor` to `PVPageScrollView(startsAtTopWhen:)`; the old path is deleted | STEP-3, AC-1.8, AC-3.3 |
| `PVListKeyboard.action` returns `.ignore` for the four page keys; `moveIndex` is unchanged | STEP-1, STEP-4, AC-2.1 – AC-2.5 |
| Docs: kit README (List, ScrollRowIntoView and a new PageScroll row), `add-ui-component` anti-pattern, `PVList` and `.pvListFocusStop` doc comments | STEP-4, STEP-5 |

| Out | Home |
| --- | --- |
| The bounce on ↓ past the window edge, and remembering the page's scroll offset instead of its top row (`ListScrollAnchorModifier`) | S16-67 |
| The Sources list's focus stop | S16-66 |
| The sidebar and the Citation composer's two columns: page keys reach only the window's page (D-4) | not planned |
| A focused `PVTable` scrolling by the page keys (it moves its selection by them) | [`docs/ideas/kit-layering.md`](../../../ideas/kit-layering.md) "The table writes its own movement keys" |
| Space and ⇧Space paging (Safari's) | not planned: the user named four keys; Space opens a focused row |
| Dialogs, sheets, popups, text areas, the graph canvas | not planned: they own their keys or are not pages |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| List focus stop | `macos/App/DesignSystem/Components/List/PVListFocusStop.swift` `pvListFocusStop(count:rowID:focusIndex:isFocused:onActivate:)`; its `PVListFocusStopPreview` (a bare `ScrollView`) | Landed in this branch's first round. `.onKeyPress` maps `PVListKeyboard.action` to `.move` / `.activate` / `.ignore`. Page Up/Down and Home/End come back `.move`, so the list moves its focused row and scrolls to it. Wrong for this PR: those keys belong to the page |
| Ring and clamp | `macos/App/DesignSystem/Components/List/PVList.swift` `PVListKeyboard.clampedIndex(_:count:)`, `isFocusedRow(_:focusIndex:count:listFocused:)` | First round; unchanged by this plan |
| Movement rule | `PVList.swift` `PVListKeyboard.action(for:option:index:count:isDisabled:)` (line 344), `moveIndex(for:option:index:count:isDisabled:pageStep:)` | `moveIndex` maps ↑/↓, Home/End, Page Up/Down. `action` returns `.move` for any of them. `action` is called by `PVListFocusStop.swift:41` and `PVTable.swift:44` (`PVTableSelection.activationTarget`, which reads only `.activate`); `moveIndex` by `PVContextMenu.swift:62` and `PVPopupList.swift:423`, `:429` |
| List tests | `macos/ProvenenciaTests/PVListTests.swift` | Helper `action(_:option:at:of:)` (count 25). `optionArrowsAndHomeEndJumpToTheEnds`, `pageKeysMoveByTenAndClamp`, `pageStepIsTheCallers` (third line) and `homeAndEndSkipDisabledRows` (first two `#expect`s) test Home/End and the page keys through `action` |
| Doc text that names the page keys on the list | `PVList.swift` doc comment lines 17–20 ("The list does not scroll itself; put it in the page's `ScrollView`. … Page Down move by ten, Return / Space activate."); `macos/App/DesignSystem/README.md` List row; `.agents/skills/add-ui-component/SKILL.md` `## Anti-patterns`, the fenced block at lines 147–151 | Say the list moves by Home/End and Page Up/Down; the README row also says "action menus use `action` too" and "`PVListKeyboard.action` takes `isDisabled`", neither true of an app caller |
| List page | `macos/App/Features/Conclusions/ConclusionListPage.swift` `ConclusionListPage.page(meta:body:)` (line 117) | A bare `ScrollView`; `ConclusionListBody` applies `ListScrollAnchorModifier` (`.scrollPosition(id:anchor:)`) outside it |
| Record pages | `macos/App/DesignSystem/Components/PageColumns/PVPageColumns.swift` `scroll(content:)` (line 370) | A bare `ScrollView` whose content starts with `Color.clear.frame(height: 0).id(PVPageColumnsMetrics.topAnchor)` (lines 375–377); `.coordinateSpace`, `.onGeometryChange`, `.environment` and `.pvScrollsRowIntoView(Optional<String>.none, restartsAt: PVPageColumnsMetrics.topAnchor, whenChanged: scrollResetKey)` on it. `scrollResetKey` is passed by `SourcePageView`, `SourceTypePageView` and `ConclusionDetailPage` |
| Reset to top | `macos/App/DesignSystem/Components/ScrollRowIntoView/PVScrollRowIntoView.swift` `PVScrollRowIntoView.restartTop`, `restartKey`, the `.onChange(of: restartKey)` (`proxy.scrollTo(restartTop, anchor: .top)`), and `pvScrollsRowIntoView(…restartsAt:whenChanged:…)` (lines 87–88); `PVPageColumnsMetrics.topAnchor` (line 67) | `PVPageColumns.scroll` is the only caller |
| Sources list | `macos/App/Features/Sources/SourcesListView.swift` (line 294) | A bare `ScrollView` around a `LazyVStack` with a pinned caption band; `ListScrollAnchorModifier` at line 307 |
| Metadata page | `macos/App/Features/Metadata/MetadataDetailPane.swift` `body` (line 11) | A bare `ScrollView` |
| Property inspector | `macos/App/Features/Properties/PropertiesView.swift` `inspectorCard` (line 433) | A bare `ScrollView` around `inspectorBody(property)`; the file's only `ScrollView` |
| Promote page | `macos/App/Features/Promote/PromoteView.swift` (line 29) | A bare `ScrollView` under `PromoteHeader` |
| Table | `macos/App/DesignSystem/Components/Table/PVTable.swift` `rowList(_:)` (line 240) | A bare `ScrollView` with `.pvScrollsRowIntoView(selection)`, `.focusable()`, `.focusEffectDisabled()`, `.focused`, `.onKeyPress(action: handleKey)`, `.pvFocusRing`, accessibility on it. The main scrolling column of the Source types list, the Metadata list (`VocabularyListPane`) and the Properties list |
| AppKit precedent | `macos/App/DesignSystem/Components/Popup/PVPopup.swift` (`viewDidMoveToWindow`, line 214); `PVPopupWindowHost.swift` line 116 (`anchor?.enclosingScrollView`) | The kit already bridges to AppKit from a zero-size `NSView` and reads `enclosingScrollView` |

**Evidence for the design** (spike, 2026-11-22, run by the user on macOS in a throwaway app; the code is not in the repo):

- A plain SwiftUI `ScrollView` with nothing focusable: Page Up/Down, Home and End do nothing.
- The same view with a zero-size `NSViewRepresentable` in its content's `background`, whose `viewDidMoveToWindow` sets `responder.nextResponder = window.nextResponder; window.nextResponder = responder`, and a responder whose `keyDown` calls `enclosingScrollView.pageDown(nil)` / `pageUp(nil)`: Page Up/Down scroll with nothing focused.
- `NSScrollView` has no Home/End action (`scrollToBeginningOfDocument(_:)` is `NSResponder`'s and passes up). `documentView.scrollToVisible(NSRect(x: 0, y: isFlipped ? 0 : height - 1, width: 1, height: 1))` and its mirror scroll to the top and the bottom: both work.
- A focused SwiftUI list whose `.onKeyPress` returns `.ignored` for the page keys and `.handled` for ↑/↓: ↑/↓ move its row; Page Down and End reach the responder and scroll the page; the row stays; ↓ moves on from it and scrolls back.

**Precedent.** `PVPopup.swift`'s zero-size `NSView` bridge (lines 200–260) for the AppKit side; `131abdb` (one kit popup list's keys) for moving key handling out of callers into one kit piece.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `PVPageScrollView<Content: View>: View` *(new)*, `init(startsAtTopWhen resetKey: AnyHashable? = nil, isSideList: Bool = false, @ViewBuilder content: () -> Content)`, in `macos/App/DesignSystem/Components/PageScroll/PVPageScroll.swift` *(new)*. It holds `@State private var handle = PVPageScrollHandle()` (*new*: a `@MainActor final class` with `weak var probe: NSView?` and `func scrollToTop()`). Its body is `ScrollView(.vertical) { content.background(PVPageScrollProbe(handle: handle, isSideList: isSideList).frame(width: 0, height: 0)) }.onChange(of: resetKey) { handle.scrollToTop() }`. `scrollToTop()` calls `PVPageKeys.scrollToEdge(probe?.enclosingScrollView, top: true)`. A caller's other modifiers go on it as they went on the `ScrollView` | One kit view every page scrolls in, with one way to its top; S16-67's offset memory joins it (user, 2026-11-22: content-agnostic) | A modifier on the caller's `ScrollView` — it sits outside the scroll view, so its `NSView` has no `enclosingScrollView`; keeping `restartsAt:whenChanged:` beside the edge scroll — two ways to the top (review M-2) |
| D-2 | Keys reach the page through one `PVPageKeyResponder: NSResponder` *(new)* per window, inserted directly after the window: `responder.nextResponder = window.nextResponder; window.nextResponder = responder`. `static func install(in window: NSWindow) -> PVPageKeyResponder` walks the chain from `window.nextResponder`; it returns the first `PVPageKeyResponder` it meets, or inserts a new one and sets its `weak var window`. `nextResponder` does not retain, so `install` makes the window own the responder: `objc_setAssociatedObject(window, &PVPageKeyResponder.associationKey, responder, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)` (`import ObjectiveC`); a probe holds it `weak`. The responder stays in the chain for the window's life and passes every key on when it has no page. `keyDown(with:)` acts when `PVPageKeys.command` returns a command and the window has a page (D-4), and otherwise calls `super.keyDown(with:)` | The responder chain hands it only keys every focused view, text field and menu left (spike evidence) | `NSEvent.addLocalMonitorForEvents` — sees keys before focused views, so it would take Page Down from a text area, a focused `PVTable` and the popup list; SwiftUI `.onKeyPress` on the page — needs focus, which a page of text never has; macOS 15 `ScrollPosition` — the deployment target is 14.0 |
| D-3 | `enum PVPageKeyCommand: Equatable { case pageUp, pageDown, top, bottom }` *(new)* and `PVPageKeys.command(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> PVPageKeyCommand?` *(new)*: key codes 116 → `.pageUp`, 121 → `.pageDown`, 115 → `.top`, 119 → `.bottom`; nil for any other code, and nil when `modifiers.intersection([.command, .option, .control, .shift])` is not empty. `.function` and `.numericPad` do not matter (fn + arrow on a laptop sets `.function`) | Pure and testable without a window; plain keys only, so ⌘↓ and ⇧Page Down keep their meanings elsewhere | Matching `KeyEquivalent` — the responder gets an `NSEvent`, not a SwiftUI key press |
| D-4 | The window's page is chosen on each key from the live probes in that window. The responder keeps `private var probes: [WeakProbe]`, `struct WeakProbe { weak var view: NSView? }`. `register(_:)` removes any entry for that view, drops entries whose view is nil, then appends. `unregister(_:)` removes that view's entry. On a key: (1) the candidates are the entries whose `view?.window` is the responder's `window` and whose `view?.enclosingScrollView` can scroll (`documentView.frame.height > contentView.bounds.height`); (2) if the pointer (`window.mouseLocationOutsideOfEventStream`, converted into each scroll view) is inside one candidate's scroll view, that one; (3) else the last registered candidate whose probe is not `isSideList`; (4) else the last registered candidate; (5) none → `super.keyDown`. The probe keeps `weak var responder: PVPageKeyResponder?` and its `isSideList`. Its `viewWillMove(toWindow:)` unregisters from `responder` when the new window differs from the current one; its `viewDidMoveToWindow` registers with `PVPageKeyResponder.install(in: window)` when `window` is non-nil and stores that responder. `PVTable.rowList` passes `isSideList: true` | One page per place: the pane under the pointer, as the scroll wheel picks (user, 2026-11-23); with the pointer elsewhere, the detail pane beside a list on Metadata and Properties, which does not depend on mount order (review M-7); a pane with nothing to scroll never takes the keys. A focused table takes them itself (`handleKey` returns `.handled`). The sidebar and the composer's columns do not wear `PVPageScrollView` (Out) | The last registered probe alone — two panes mounted in one pass have no defined order (review M-7); finding the scroll view that holds focus — SwiftUI focus inside one `NSHostingView` has no `NSView` to look up; `NSHashTable.weakObjects()` — no order |
| D-5 | The commands: `.pageDown` → `scrollView.pageDown(nil)`; `.pageUp` → `scrollView.pageUp(nil)`; `.top` / `.bottom` → `PVPageKeys.scrollToEdge(_ scrollView: NSScrollView?, top: Bool)` *(new)*: `guard let doc = scrollView?.documentView else { return }`; `let y: CGFloat = doc.isFlipped == top ? 0 : doc.bounds.height - 1`; `doc.scrollToVisible(NSRect(x: 0, y: y, width: 1, height: 1))`. No animation of our own | AppKit's own page amount and overlap; the spike's edge scroll; the same call serves D-1's reset | `ScrollViewReader.scrollTo` with an id — needs content ids, which a page of text has none of |
| D-6 | `PVListKeyboard.action` returns `.ignore` for `.home`, `.end`, `.pageUp` and `.pageDown`, checked after `guard count > 0` and before `moveIndex` runs. No parameter. `moveIndex` is unchanged | `action` is the focus stop's rule; its other caller (`PVTable`) reads only `.activate`. Menus and the popup list move by `moveIndex`, which keeps the page keys (review M-3) | A `pageKeys: Bool` parameter — no caller would pass the default's behavior |
| D-7 | The page sites in Scope's third In row swap `ScrollView {` for `PVPageScrollView {` and keep every modifier they had, in the same order. In `PVPageColumns.scroll`, the `Color.clear … .id(PVPageColumnsMetrics.topAnchor)` marker and the `.pvScrollsRowIntoView(…restartsAt:whenChanged:)` call go, and `scrollResetKey` is passed as `PVPageScrollView(startsAtTopWhen: scrollResetKey)`; `.coordinateSpace`, `.onGeometryChange` and `.environment` stay | No visible change beyond the keys | — |
| D-8 | `PVPageScroll.swift` holds `PVPageScrollView`, `PVPageScrollHandle`, `PVPageScrollProbe` (a `private struct … : NSViewRepresentable` whose `makeNSView` returns a `final class Probe: NSView` and sets `handle.probe`), `PVPageKeyResponder`, `PVPageKeyCommand` and `PVPageKeys`. One file (add-ui-component: one folder per control, helpers colocated) | The pieces exist only for each other | Putting the responder in `Platform/` — it serves one kit control |

**Rules this plan bends.** None. The working rule "(Batch 6) A list of rows is one kit focus stop" is rewritten by the user's answer of 2026-11-22 as "(Batch 6) Page keys belong to the page's scroll view" (map Working rules).

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `PVPageScrollView` | component | `PVPageColumns.scroll` (private), `PVFittedScrollView` | `scroll` is private to the record-page layout; the fitted scroll view sizes to its content for dialogs. `PVPageColumns.scroll` and `PVTable.rowList` now build on `PVPageScrollView`; the name pairs with `PVFittedScrollView` |
| `startsAtTopWhen:` | parameter | `PVScrollRowIntoView`'s `restartsAt:whenChanged:` | Replaces it: same trigger (a key change), no marker id (review M-2) |
| `PVPageScrollProbe`, `PVPageScrollHandle` | `NSViewRepresentable`, reference | `PVPopup`'s anchor view | Same bridge shape; a different job |
| `PVPageKeyResponder` | `NSResponder` | none: no responder in the app sits in the chain | — |
| `PVPageKeys.command`, `PVPageKeyCommand` | pure rule | `PVListKeyboard.moveIndex` | That rule moves an index through rows; this one names a scroll command from a key code |

Searched: `rg -n "nextResponder|enclosingScrollView|addLocalMonitorForEvents" macos/App` (PVPopup, PVPopupWindowHost, WindowDragRegion, GraphCanvasDocumentView: none handle page keys); `rg -l "ScrollView(\(|\s*\{)" macos/App -g '*.swift'` (26 files; the seven page sites are In, the rest are Out); `rg -n "restartsAt|topAnchor" macos/App` (`PVPageColumns` the only caller).

**Builds on.** `PVListKeyboard`, `.pvListFocusStop` (this branch), `PVPopup`'s bridge shape.
**Deletes.** `.pvListFocusStop` moving the focused row by Home/End and Page Up/Down; seven bare page `ScrollView`s; `PVPageColumnsMetrics.topAnchor` and its marker view; `PVScrollRowIntoView`'s `restartTop`, `restartKey`, their `.onChange` and the `restartsAt:whenChanged:` parameters.
**Next adds.** S16-67 gives `PVPageScrollView` its remembered offset and removes `ListScrollAnchorModifier` (every list it names already scrolls in `PVPageScrollView`); S16-66 puts the Sources list's rows on `.pvListFocusStop`. A new workspace page scrolls in `PVPageScrollView`.

### Reach

The responder sees every key event no view handled in a workspace window. It acts on four plain keys and passes everything else to `super`, which ends where it ends today.

### Scale

O(1) per key press: one key-code switch and a walk over the window's probes (one to three). No per-row work.

### Edges

- **Assumptions.** One scroll view takes each key (D-4): the one under the pointer, else the non-side-list one, else the last registered. During a place change both places' probes may be registered for one layout pass; the old one unregisters when it leaves its window.
- **Neighbors.** A focused text field or text area handles the page keys itself (`NSTextView` implements `scrollPageDown:`, `moveToBeginningOfDocument:`), so they never reach the responder (AC-1.5). A focused `PVTable`, popup list or context menu handles them through its own `.onKeyPress` (`.handled`). A focused `PVList` returns `.ignored` (D-6), so they reach the page. Sheets and popup windows are other windows with no probe, so the responder is not in their chain. A place with a table and a detail pane (Metadata, Properties): the pane under the pointer pages; with the pointer elsewhere, the detail pane; a pane that fits its window never takes the keys (D-4).
- **Removed inputs.** None.
- **Real data.** None — no table-driven rule.
- **Untrusted size.** None — the key codes are the system's.

### Schema

None — no catalog change.

### Go core

None — Swift only.

### FFI

None — no engine call.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Page scroll view | `PVPageScrollView` *(new)* | `macos/App/DesignSystem/Components/PageScroll/PVPageScroll.swift` | Component layer, content-agnostic, no `Features/` type |
| Page keys | `PVPageKeyResponder`, `PVPageKeys` *(new)* | same file | AppKit bridge; pure rule tested |
| Browse list | `PVList`, `.pvListFocusStop` | `macos/App/DesignSystem/Components/List/` | Passes the page keys on |
| Table | `PVTable` | `macos/App/DesignSystem/Components/Table/PVTable.swift` | Scrolls in `PVPageScrollView`; its keys unchanged |

Sketch (signatures only):

```swift
struct PVPageScrollView<Content: View>: View {
    init(startsAtTopWhen resetKey: AnyHashable? = nil, isSideList: Bool = false, @ViewBuilder content: () -> Content)
}

enum PVPageKeyCommand: Equatable { case pageUp, pageDown, top, bottom }

enum PVPageKeys {
    static func command(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> PVPageKeyCommand?
    static func scrollToEdge(_ scrollView: NSScrollView?, top: Bool)
}

final class PVPageKeyResponder: NSResponder {
    static func install(in window: NSWindow) -> PVPageKeyResponder
    weak var window: NSWindow?
    func register(_ probe: NSView)
    func unregister(_ probe: NSView)
}
```

States: a page shorter than the window (nothing moves, AC-1.3); no probe in the window (the responder passes every key on). Accessibility: unchanged; VoiceOver keeps its own scrolling.

### Strings

None — no copy.

## 7. Steps

**STEP-1 — The pure rules**
Files: `macos/App/DesignSystem/Components/PageScroll/PVPageScroll.swift` *(new)*, `macos/App/DesignSystem/Components/List/PVList.swift`, `macos/ProvenenciaTests/PVPageKeysTests.swift` *(new)*, `macos/ProvenenciaTests/PVListTests.swift`. Skill: `add-swift-test`.
Failing tests first: T-1, T-2.
Do: add `PVPageKeyCommand` and `PVPageKeys.command(keyCode:modifiers:)` per D-3 in the new file (`import AppKit`, `import SwiftUI`). Change `PVListKeyboard.action` per D-6; its doc comment gains "Home, End, Page Up and Page Down are ignored: they scroll the page (`PVPageScrollView`)." Move the existing page-key checks that go through `action` onto `moveIndex`, same expected indices: in `optionArrowsAndHomeEndJumpToTheEnds`, `action(.home, at: 12) == .move(to: 0)` becomes `PVListKeyboard.moveIndex(for: .home, option: false, index: 12, count: 25) == 0`, and `.end` likewise `== 24`; the four lines of `pageKeysMoveByTenAndClamp` become `moveIndex(…count: 25)` with results 13, 24, 3, 0; delete `pageStepIsTheCallers`' third line (its second line checks the same through `moveIndex`); the `.home` and `.end` `#expect`s of `homeAndEndSkipDisabledRows` call `moveIndex(for:option:index:count:isDisabled:)` and expect `1` and `2`; its `.downArrow` line stays on `action`.
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/PVPageKeysTests -only-testing:ProvenenciaTests/PVListTests` passes.

**STEP-2 — The page scroll view and its responder**
Files: `PVPageScroll.swift`. Skill: `add-ui-component` (component; `PV` prefix; no `Features/` type).
Do: write `PVPageScrollView`, `PVPageScrollHandle`, `PVPageScrollProbe`, `PVPageKeyResponder` and `PVPageKeys.scrollToEdge` per D-1, D-2, D-4, D-5, D-8. `keyDown(with:)`: `guard let command = PVPageKeys.command(keyCode: event.keyCode, modifiers: event.modifierFlags), let scrollView = <the D-4 page>?.enclosingScrollView else { return super.keyDown(with: event) }`, then D-5's call. Add `private struct PVPageScrollPreview: View`: `PVPageScrollView` around a `VStack(alignment: .leading)` of 120 `Text(verbatim: "Line \(i)")` rows, and `#Preview { PVPageScrollPreview().frame(width: 320, height: 360) }`. Doc comment on `PVPageScrollView`: "The scroll view a workspace page scrolls in. Page Up, Page Down, Home and End scroll it whenever no focused view, text field or menu takes them (`PVPageKeyResponder`), and a change of `startsAtTopWhen` sends it to its top (a page's reset; `pvScrollsRowIntoView`'s `startsAtTopWhenRowsChange:` is a list's first row); the content needs no key code and no ids."
Check: the app builds with no new warning (`scripts/check-pr.sh` swift-warnings).

**STEP-3 — Every page scrolls in it; one way to the top**
Files: `macos/App/Features/Conclusions/ConclusionListPage.swift`, `macos/App/DesignSystem/Components/PageColumns/PVPageColumns.swift`, `macos/App/Features/Sources/SourcesListView.swift`, `macos/App/Features/Metadata/MetadataDetailPane.swift`, `macos/App/Features/Properties/PropertiesView.swift`, `macos/App/Features/Promote/PromoteView.swift`, `macos/App/DesignSystem/Components/Table/PVTable.swift`, `macos/App/DesignSystem/Components/ScrollRowIntoView/PVScrollRowIntoView.swift`, `macos/App/DesignSystem/Components/List/PVListFocusStop.swift`.
Do: per D-7, `ScrollView {` → `PVPageScrollView {` at each site named in §4 (`PVTable.rowList`: `PVPageScrollView(isSideList: true) {`), nothing else changed, except `PVPageColumns.scroll` (D-7: marker and restart call go, `startsAtTopWhen: scrollResetKey`). Delete `PVPageColumnsMetrics.topAnchor`. In `PVScrollRowIntoView`, delete `restartTop`, `restartKey`, the `.onChange(of: restartKey)` block, the `restartsAt restartTop:` and `whenChanged restartKey:` parameters and their doc lines. `PVPageColumns`' doc sentence on `scrollResetKey` stays as it is. `PVListFocusStopPreview`'s `ScrollView {` becomes `PVPageScrollView {`.
Check: AC-3.1 and AC-3.3's `rg` print as stated; `scripts/check-pr.sh` PASS.

**STEP-4 — The list passes the page keys on**
Files: `macos/App/DesignSystem/Components/List/PVListFocusStop.swift`, `PVList.swift`.
Do: `.pvListFocusStop`'s doc comment's first sentence becomes "One focus stop over a column of rows tagged `.id(rowID(i))`: ↑/↓ (⌥ to an end) move `focusIndex` (`PVListKeyboard`), the list scrolls to keep that row in view, and Return or Space calls `onActivate` with it; Page Up/Down and Home/End go on to the page (`PVPageScrollView`)." In `PVList.swift`, replace doc lines 17–20 with:

```swift
/// The list does not scroll itself; put it in the page's `PVPageScrollView`.
/// Rows are lazy, so hundreds stay cheap. Keyboard (`.pvListFocusStop`): the
/// list is one focus stop; ↑ / ↓ move the focused row (⌥ jumps to the ends),
/// Return / Space activate; the page keys scroll the page.
```

Check: T-2 passes; §10 steps 4–6.

**STEP-5 — Docs**
Files: `macos/App/DesignSystem/README.md`, `.agents/skills/add-ui-component/SKILL.md`, `docs/deployment-plan/spike-16/completed.md`, `docs/deployment-plan/spike-16/deployment-plan.md` (map row), this plan (status).
Do:
- README List row: from "one focus stop with ↑/↓ · Home/End · Page Up/Down · Return/Space" up to "; `PVListSkeleton` for first load", the text becomes: "one focus stop with ↑/↓ (⌥ to an end) · Return/Space through `.pvListFocusStop` (`PVListFocusStop.swift`), which any column of button rows tagged `.id` wears and which hands Page Up/Down and Home/End to the page; the caller owns `focusIndex` and the `FocusState`, and draws its ring with `PVListKeyboard.isFocusedRow`. `PVListKeyboard.action` is the focus stop's key rule; `PVListKeyboard.moveIndex` is the list of movement keys (with the caller's `pageStep`) that the context menu, the popup list and `PVTable` call (`PVTable` still writes its own selection keys: KIT-LAYERING-LINK)", where KIT-LAYERING-LINK is the row's existing link to `kit-layering.md`, kept as it is.
- README ScrollRowIntoView row: delete the clause on restarting a page at its top (`restartsAt:whenChanged:`) and mend the sentence around it.
- README: a new row after ScrollRowIntoView: `| PageScroll | `Components/PageScroll/PVPageScroll.swift` (`PVPageScrollView`: the scroll view every workspace page scrolls in, `PVTable`'s rows included; Page Up/Down and Home/End scroll it whenever no focused view takes them, through one `PVPageKeyResponder` after the window in the responder chain; `startsAtTopWhen:` sends it to its top; do not build a page on a bare `ScrollView`) |`.
- `add-ui-component` `## Anti-patterns`, the block at lines 147–151 becomes:

```swift
// ❌ BAD — a list of button rows with its own .focusable() and .onKeyPress moving a focused row
// ❌ BAD — a page on a bare ScrollView, or a list that moves its row by Page Down

// ✅ GOOD — the page scrolls in PVPageScrollView; the list's rows wear .pvListFocusStop (↑/↓, Return/Space)
```

- `completed.md`: a new section directly under the intro line, above `## S16-59`: `## S16-65 — Page keys belong to the page's scroll view`, then a `**Landed YYYY-MM-DD** in [#951](https://github.com/Jake-Robins-Studios/provenencia/pull/951).` paragraph of what shipped.
- Map row Status `Landed #951`; this plan `Landed in [#951](…) (YYYY-MM-DD)` with a Landed note.

Check: links resolve; `python3 scripts/check-guidance-names.py` passes.

**Commits** (subjects are full imperative sentences ending in a period):
1. STEP-1 – STEP-3: "Scroll every page by Page Up, Page Down, Home and End through one kit scroll view."
2. STEP-4: "Hand the page keys from a list's focus stop on to the page."
3. STEP-5: "Name the page scroll view in the kit README and add-ui-component, and record S16-65."

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `macos/ProvenenciaTests/PVPageKeysTests.swift` `pageKeysNameTheirCommand` *(new)* | (116, []) → `.pageUp`; (121, []) → `.pageDown`; (115, []) → `.top`; (119, []) → `.bottom`; (121, [.function]) → `.pageDown`; (121, [.function, .numericPad]) → `.pageDown`; (125, []) → nil (↓); (49, []) → nil (Space); (121, [.shift]) → nil; (119, [.command]) → nil; (115, [.option]) → nil; (116, [.control]) → nil | AC-1.6, AC-3.2, D-3 |
| T-2 | Swift | `macos/ProvenenciaTests/PVListTests.swift` `aListHandsThePageKeysOn` *(new)* | `action(_, at: 3)` with `.home`, `.end`, `.pageUp`, `.pageDown` → `.ignore`; `.downArrow` → `.move(to: 4)`; `.return` → `.activate(3)` | AC-2.5, D-6 |
| T-3 | Swift | `PVListTests` (existing, with STEP-1's moves onto `moveIndex`) | → pass | AC-2.1, AC-2.4, D-6 |
| T-4 | Check | AC-3.1 and AC-3.3's `rg` | → as stated | AC-3.1, AC-3.3 |

The responder, the probe, the reset and the scroll calls have no unit test: they need a window and key events, and the test host runs none (Batch 3). §10 covers them.

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `PVListTests` cases still calling `action` with a page key (STEP-1 moves them), and a site whose modifier chain needs a `ScrollView` (none found; every modifier at the seven sites is a `View` modifier).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: T-1, T-2, T-4, and §10 for AC-1.1 – AC-1.8 and AC-2.1 – AC-2.4
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left — none added
- [ ] Sweep: AC-3.1 and AC-3.3's rg; `rg -n "Home/End · Page Up/Down|action menus use" macos/App/DesignSystem/README.md` prints nothing; scripts/check-guidance-names.py passes
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated — none
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New — no brief; `PVPageScrollView` is the one new component, with S16-67 as its next caller
- [ ] Version bump as the header says — none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated) — not gated
- [ ] Domain doc updated if a rule in docs/*.md changed — none; the kit README and add-ui-component per STEP-5
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Open a project with at least 30 Persons. Open a Person whose page is taller than the window. Click nothing. Press Page Down: the page scrolls by a window. End: its bottom. Page Up. Home: its top. Page Up again: nothing moves (AC-1.1, AC-1.2, AC-1.3).
2. Repeat step 1 on the Source page, the Sources list, the Metadata page with a field selected, a Property's inspector (Properties, select one), the Promote page, and the Source types list with nothing focused (AC-1.7). On Metadata and Properties, click in the detail pane so the table is not focused; then, with the pointer over the list, Page Down scrolls the list; over the detail pane or the sidebar, it scrolls the detail pane.
3. Click in the omnibar and type a word; press Home and End: the page does not scroll (the field keeps the key) (AC-1.5). On a page, press ⌘↓ and ⇧Page Down: the page keys do not act (AC-1.6).
4. Open Persons. Click nothing; Page Down: the list page scrolls and no row has the ring (AC-1.4).
5. Press Tab until the first row has the ring. ↓ twice: the third row (AC-2.1). Page Down: the page scrolls; the ring stays on the third row (AC-2.2). ↓: the fourth row has the ring and is in view (AC-2.3). ⌥↓: the last row; Return: that person's page opens (AC-2.4).
6. Repeat step 5 on Events and Places. Open the omnibar's results and a row's context menu: Page Down and Home/End still move their highlight. Click a row in the Source types list, then Page Down: its selection moves, as today.
7. On a Person page, scroll down, then open another section from its section bar: the page is at its top (AC-1.8). Do the same on a Source page by opening another Source.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| SwiftUI's hosting window replaces `window.nextResponder` after the probe inserts the responder | `install(in:)` runs on every `viewDidMoveToWindow`; the spike ran the same insertion; Stop condition below |
| The reset runs before the new section's content lays out, so the page lands short of its top | The top of a flipped document view is y = 0 whatever its height; §10 step 7; Stop condition below |
| `.function` on fn + arrow, or a page key arriving with another flag set | T-1 covers `.function` and `.numericPad`; §10 step 1 on a laptop keyboard |

**Stop and report if:**

- With `PVPageScrollView` in place, Page Down on a Person page with nothing focused does not scroll it (§10 step 1).
- A focused text field or the omnibar scrolls the page on Page Down, Home or End (§10 step 3).
- `PVPageScrollView` cannot replace a site's `ScrollView` without dropping or reordering one of its modifiers.
- A focused `PVTable`, `PVPopupList` or `PVContextMenu` stops moving its highlight or selection by Page Up/Down or Home/End (§10 step 6).
- A record page does not return to its top on a section change (§10 step 7).

## 12. Open questions

None.

## 13. PR

**Title:** S16-65 — Page keys belong to the page's scroll view
**Body:** objective in one sentence; what shipped against US-1 – US-3; AC evidence; deviations; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-65-list-focus-stop.md`.

## Landed

- STEP-4's doc comments (`PVList`, `.pvListFocusStop`, `PVListKeyboard.action`) landed in the first commit with STEP-1 – STEP-3, so there is no separate STEP-4 commit.
- `PVPageKeyResponder` is `@MainActor` and `PVPageKeys.scrollToEdge` is `@MainActor`, since AppKit's scroll calls are main-actor isolated.
- Review round 1 (re-plan) fixes. D-4 and D-1 named `isSideList`; it is `yieldsPageKeys` (a parameter and probe property, documented as: when another page scroll view in the window can scroll and the pointer is over neither, the page keys go to that one; a focused view that handles the keys keeps them). D-6's Why named the table among `moveIndex`'s callers; `PVTable` moves by its own `PVTableSelection.moveIndex`, so the README names only the context menu and the popup list. An open context menu or select popup now takes Page Up/Down (`PVPopupInput.keyEquivalent` maps 116 and 121; `PVContextMenuState.handle` and `PVSelectSession` move the highlight by a page). `PVKeyCode` (`Components/KeyCode/PVKeyCode.swift`) is the one named set of hardware key codes that `PVPopupInput`, `PVPageKeys` and `ArtifactRegionOverlay` read. AC-1.7 and §10 steps 2 and 3 gained wording that says what state is tested (table not focused; Home/End stay with a text field); these are wording fixes from review.
