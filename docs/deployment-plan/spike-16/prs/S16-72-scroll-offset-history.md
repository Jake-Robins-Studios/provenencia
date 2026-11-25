# S16-72 — Back returns to the scroll position

**Status:** Planned
**Spike / slice:** Spike 16 · Slice 6i — Back and scroll
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: every page draws the same; only where it is scrolled on arrival changes)
**Board:** —
**Depends on:** S16-71 (landed [#969](https://github.com/Jake-Robins-Studios/provenencia/pull/969))
**Blocks:** —
**Branch:** `s16-72-scroll-offset-history`
**Version bump:** minor — Back restores where every main page was scrolled, a feature ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-workspace-location`](../../../../.agents/skills/add-workspace-location/SKILL.md), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** —
**Context:** working rules "(Batch 6) History restores a scroll offset, not a row", "(Batch 6) Back restores a section's scroll and focus, not its folds", "(Batch 6) The Sources list is a native table"; [`navigation-history.md`](../../archive/spike-3/navigation-history.md); S16-71's Landed note (13) and (14) and [ship log](S16-71-sources-table.ship.md) U-5
**Planned:** 2026-11-25 against `main` @ `09774bb`
**Review:** [`S16-72-scroll-offset-history.review.md`](S16-72-scroll-offset-history.review.md) — Fits with changes / Ready with changes, round 1 answered; round 2 pending

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

Back, Forward and a jump in the history menu put every main page back at the y position it was scrolled to, with what it had open (on Sources, the open Source). The record is a plain number taken from the page's scroll view; nothing in it knows rows, sections or heights. A position the page can no longer show opens the page at its top, as if never visited. The user asked for this after testing S16-71 (2026-11-24): Back scrolled to a remembered row, so it depended on the list's content.

**Why now.** S16-71 moved its checks 4.7's and 4.8's "in view" here; its anchor test lost its scroll assertions, and Back to a deep graph stopped short.

**What stays.** The selected row of a list is still restored, and so is the keyboard on a record page's anchored row. Folds open closed. The Evidence graph keeps its own camera. Identity, coalescing and the history file's format version are unchanged.

## 2. User stories

**US-1.** As a researcher, when I go back to a page I scrolled, I see it scrolled where I left it.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Persons list scrolled to y 1,800; open a Person; Back | The list is at y 1,800, the Person's row selected |
| AC-1.2 | Source page scrolled to y 600; open a graph; Back | The Source page is at y 600 |
| AC-1.3 | Person page, Sources section, scrolled to y 900; open a Source from a row; Back | The section is at y 900 and its row has the keyboard |
| AC-1.4 | Source types list at y 300 → Source type page → Properties → history menu jump to the list | The list is at y 300 |
| AC-1.5 | A page at y 0 (never scrolled) | Back opens it at y 0 |
| AC-1.6 | A list at y 2,000 left; 40 rows deleted elsewhere so the list is 900 pt tall; Back | The list opens at the top |
| AC-1.7 | Back to a list at y 1,200 whose rows load in 600 ms | It opens at the top, then moves to y 1,200 once the rows are laid out, once |
| AC-1.8 | Back to a list at y 1,200 whose rows are slow; the researcher scrolls before they arrive | The list does not jump when they arrive |
| AC-1.9 | Quit at the Places list scrolled to y 700; relaunch | The list opens at y 700 |
| AC-1.10 | A page scrolled, then a section switch on the same record page (Vitals → Family); Back | Vitals at the y it had; the Family visit opened at its top |
| AC-1.11 | Promote page scrolled to y 500; open the Source page from its header; Back | Promote at y 500 |

**US-2.** As a researcher, when I go back to the Sources list, I see the Source I had open, still open.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | B closed; `Open <graph>` from B's menu; Back | B open, the graph selected, the list at the y it was left (S16-71's check 4.7) |
| AC-2.2 | A open; Back to an entry left with B open and a graph of B selected | B open, A closed, the graph selected, the list at that entry's y (S16-71's check 4.8) |
| AC-2.3 | A open; go to Persons; the sidebar's Sources | A open; the list at the top (a new visit) |
| AC-2.4 | A open; relaunch | Every Source closed (S16-71's check 4.12); the list at its saved y when it fits |
| AC-2.5 | Back to an entry left with no Source open while A is open | A closes |

## 3. Scope

| In | Covered by |
| --- | --- |
| A history entry records the main scroll view's y on leaving any page, written to the history file | STEP-1, AC-1.1 – AC-1.11 |
| A Sources list entry records its open Source apart from the y, never written to the file | STEP-1, STEP-2, US-2 |
| One kit modifier reads and restores a y on any kit scroll container, once the content is tall enough | STEP-3, STEP-4, AC-1.5 – AC-1.8 |
| Every main page's scroll view adopts it: the Sources, Source types, Persons, Events and Places lists, Metadata's and Properties' tables, the Source page, Source type page, Person, Event and Place pages, Promote | STEP-4, STEP-7 |
| Arrival scrolls to a row go: the native list's scroll to its selection, Source types' top-row anchor, a record section's scroll to its anchored row; the record section's anchor keeps the keyboard | STEP-5, STEP-6 |
| The Sources reveal (open the closed Source that holds a selected graph) goes; the recorded open Source does it | STEP-2 |
| The things an entry keeps of how it was left (selection, open Source, offsets, section anchor) become one value that a push starts clean | STEP-1 |

| Out | Home |
| --- | --- |
| Exact Sources row heights, so a far scroll lands on the same rows (today a never-drawn row is estimated at 34 pt, a Source row is 66) | [`docs/ideas/source-page-followups.md`](../../../ideas/source-page-followups.md) (STEP-8 adds it) |
| The citation composer's two scrolling columns | [`docs/ideas/citation-composer-followups.md`](../../../ideas/citation-composer-followups.md) (STEP-8 adds it) |
| Secondary panes: Metadata's detail pane, Properties' inspector | not planned |
| The Evidence graph canvas | not planned: it keeps `GraphCanvasCamera` |
| Restoring folds | not planned (S13-16 UX-5) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Entry | `macos/App/Features/Workspace/WorkspaceLocation.swift` `listScrollAnchor`, `withListScrollAnchor`, `sectionAnchor`, `withPageSection`, `CodingKeys`, `==` | A row id that is the top row on Source types and the selection elsewhere; no y; no open state; `withPageSection` clears `sectionAnchor` by hand, and a push carries whatever the copy held (`ConclusionDetailPage.choose`, `WorkspaceToolbar` breadcrumb) |
| History | `macos/App/Features/Workspace/NavigationHistoryStore.swift` `stampListAnchor`, `stampSectionAnchor`, `go(to:)` | Stamps the list row on leaving a list root only |
| Navigation | `macos/App/Features/Workspace/WorkspaceNavigation.swift` `listAnchor`, `noteListAnchor`, `performGo/Back/Forward/Index`, `apply`, `onLocationCommit` | Holds the selection; stamps it on leave; no y; no way to tell a history move from a push |
| Row rules | same file `ListAnchor.resolved`, `ListAnchor.settle`, `ListSelectionAnchorModifier` (`reveal`), `ListScrollAnchorModifier` | `settle`/`reveal` open a closed Source for a selected graph; `ListScrollAnchorModifier` pins Source types' top row through `.scrollPosition(id:)` |
| Commit hook | `macos/App/Features/Workspace/WorkspaceView.swift` `navigation.onLocationCommit` | Calls `session.apply(location:)` |
| Open Source | `macos/App/Features/Workspace/Session/WorkspaceSession.swift` `openSourceID`, `setOpenSource` | Session only; Back does not set it |
| Sources page | `macos/App/Features/Sources/SourcesListView.swift` `SourcesListContent` | Passes `reveal` to `ListSelectionAnchorModifier`; `opened` scroll on an open |
| Outline | `macos/App/Features/Sources/SourcesOutline.swift` `sourceToReveal`, `closedOwnerID`, `setOpen` | Reveal lookup, only for the reveal |
| Native list | `macos/App/DesignSystem/Components/List/PVNativeListBehavior.swift` | On appear scrolls to the selection (`onAppear`, `scrollsOnAppear: true`) and when the selected row arrives (`onChange(of: ids)`) |
| Page scroll | `macos/App/DesignSystem/Components/PageColumns/PVPageColumns.swift` `scroll(content:)` | The page's `ScrollView`; resets to its top on `scrollResetKey`, whose arrival keys are `openPageSection` (`ConclusionDetailPage.swift`), `sourceID` (`SourcePageView.swift`, first page), `typeID` (`SourceTypePageView.swift`) |
| Table | `macos/App/DesignSystem/Components/Table/PVTable.swift` `rowList` | `ScrollView` + `LazyVStack`; `.scrollTargetLayout()` serves only `ListScrollAnchorModifier` |
| Source types | `macos/App/Features/SourceTypes/SourceTypesListPane.swift` | Applies `ListScrollAnchorModifier` |
| Record sections | `macos/App/Features/Conclusions/ConclusionAnchorRestore.swift` `conclusionAnchorRestore`, `ConclusionAnchorTarget.scrollID` | Scrolls to the anchored row and focuses it; seven call sites, `PersonTimelineSection` passes `scroll:` |
| Promote | `macos/App/Features/Promote/PromoteView.swift` `body` | A plain `ScrollView` |
| Host | `macos/App/Features/Workspace/WorkspaceDestinationHost.swift` `body` | `.id(place?.viewIdentity)` remounts per place |
| Tests | `macos/ProvenenciaTests/WorkspaceNavigationTests.swift` (`listScrollAnchorRoundTrips`, `aRevealKeepsAnAnchorItDraws`, `theListAnchorIsTheSelectionAndFollowsHistory`, …), `SourcesOutlineHostedTests.swift` (`anAnchorOnAGraphOfAClosedSource…`, `anAnchorSetBeforeThePageIsHosted…`), `SourcesOutlineTests.swift`, `ConclusionAnchorRestoreTests.swift`, `HostedWindow.swift` (`hostInBorderlessWindow`, `descendant`) | Cover the row anchors |

**Precedent.** S16-46 ([`S16-46-section-anchor.md`](S16-46-section-anchor.md)) added `sectionAnchor`: an identity-ignored, leniently decoded field stamped on the entry being left. Copy its field shape and its stamp-on-leave tests. `PVPopupWindowHost.startFollowing` / `stopFollowing` (`macos/App/DesignSystem/Components/Popup/PVPopupWindowHost.swift`) is the kit's clip-view observer: copy its `postsBoundsChangedNotifications`, observer and removal.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | The y is `contentView.bounds.minY + contentInsets.top` of a scroll view's `NSScrollView`, a `Double`, 0 at the top. Nothing reads rows or heights | Working rule; content-agnostic (user, 2026-11-25) | A row plus a delta: knows content |
| D-2 | The y is read and written through AppKit: a probe `NSView` finds the `NSScrollView` and observes its clip view's bounds and its document view's frame, with the idiom of `PVPopupWindowHost.startFollowing` / `stopFollowing` | SwiftUI's `onScrollGeometryChange` and `ScrollPosition` are macOS 15; the minimum is 14.0; the rule allows a little AppKit; one kit way to watch a clip view | Raising the minimum macOS |
| D-3 | The probe finds its scroll view as `enclosingScrollView` when it is inside one (a `ScrollView`'s content); otherwise, walking up at most 6 superviews, the first `NSScrollView` in each ancestor's subtree, depth first in subview order, whose window rect equals the probe's within 1 pt (a `List` or `Table` the probe is the background of). The visible height is `contentView.bounds.height` | One probe for both shapes; public API only | A private-view-name search |
| D-4 | An entry keeps every y it was left at in `scrollOffsets: [PVScrollSlot: Double]`, one per named scroll view; `PVScrollSlot` *(new kit `String` raw-value struct)* has `.page`. The kit's scroll containers (`PVPageColumns`, `PVTable`, `PVNativeListBehavior`) call `pvRemembersScroll()`, which claims `.page`; the first claimant under the host clears `.page` for its content, so a nested container never claims it. A plain `ScrollView` names its slot: `pvRemembersScroll(.page)` on Promote; a second scroll view on one page passes another slot (the composer, later) | One page, one memory; the composer's two columns and the secondary panes are each one call, with no change to the file later | One scalar y: the next named add re-keys the file |
| D-5 | Claimants: the lists through `PVNativeListBehavior` (Sources' `Table`, `PVList`); Source types, Metadata and Properties through `PVTable`; the Source page, Source type page and the Person, Event and Place pages through their page's own `PVPageColumns` (`SourcePageView`, `SourceTypePageView`, `ConclusionDetailPage`); the `PVPageColumns` in `PersonSourcesSection.swift` and `PersonTimelineSection.swift` are previews. The kit knows nothing of navigation: `WorkspaceDestinationHost` hands it a `PVScrollMemory` through the environment | Every main page adopts through the container it already uses | A modifier on each page: thirteen call sites to forget |
| D-6 | Restore, per probe and slot: armed with the slot's y on mount and on every change of `memory.arrival`. A nil or 0 y scrolls to the top on the next main-actor turn when the view is not there (a reused scroll view: a section switch) and is done. Otherwise, on the next main-actor turn and after every document resize, it scrolls to y if `y ≤ documentHeight − (visibleHeight − topInset) + 0.5`, and is done. While armed, a bounds change at the top is not noted and one away from it disarms (the researcher, Home/End, a reveal, a focus hand-off) and is noted. Once done, every bounds change is noted. No time limit: content that never grows tall enough leaves the page at its top | AC-1.5 – AC-1.8, AC-1.10; "no usable offset opens at the top"; the probe owns where a page sits on arrival, so `scrollResetKey` arrival keys go | Clamping to the bottom; a timeout; keeping arrival reset keys beside it |
| D-7 | `WorkspaceNavigation.arrival: WorkspaceArrival` *(new: `id: Int`, `kind: .push | .history`)* is set in the private `apply`: the id increments when the identity changes or on any history move; the kind is `.history` from `performBack`, `performForward` and `performIndex`, `.push` from `performGo`, `attachProject` and `replaceCurrent`. A coalesced `go(to:)` or a same-identity `replaceCurrent` keeps the arrival. `onLocationCommit` keeps its signature; `WorkspaceView`'s closure reads `navigation.arrival.kind`. Its `.onAppear` re-apply calls `session.apply(location:)` alone, as today | One rule for when a visit begins; a section switch keeps the same `NSScrollView`; a closing page's last note must not land on the next entry | Location equality as the key: A → B → A |
| D-8 | Navigation holds the live revisit (`revisit`, not observed): `noteScrollOffset(_:slot:arrival:)` *(new)* writes a slot's y and drops a note of another arrival id; `noteListSelection` writes the selection (observed separately, as `listAnchor` is today). `apply` sets the held revisit to the entry's only when the arrival id changes. Before `performGo`, Back, Forward and a jump move the history, the held revisit is stamped on the current entry (`stampLeaving(_:)`, on the generic `stampCurrent`): the offsets on every entry; the selection and the open Source only on a list root, the open Source only on the Sources list root, read through `openSourceProvider` *(new closure)*, which `WorkspaceView` sets to `session.openSourceID`. `NavigationHistoryStore.go(to:)` strips the pushed location's revisit (a new visit starts clean), except a coalesced list visit, which copies the incoming selection as today | One clear rule instead of one hand clear per field per `with…`; `withPageSection` pushing Vitals' y onto Family is impossible | Per-field stamps and clears |
| D-9 | The revisit is one value, `WorkspaceRevisit` *(new: `listSelection: String?`, `openSourceId: String?`, `scrollOffsets: [PVScrollSlot: Double]`, `sectionAnchor: ConclusionSectionAnchor?`)*, the location's `revisit` member, ignored by `==`. It is encoded flat at the location's top level under the existing keys `listScrollAnchor` and `sectionAnchor` plus `scrollOffsets` (a `[String: Double]`); `openSourceId` is never encoded. Decoding is lenient per key: an unreadable key decodes as its empty value; a negative or non-finite y is dropped | Old history files read unchanged; user, 2026-11-25 (the y is written, so relaunch reopens where it was); S16-71's check 4.12 keeps relaunch closed | Nesting the value in the file: old files lose their selection |
| D-10 | On `.history`, `WorkspaceSession.applyHistoryState(_:)` *(new)* sets the open Source to the entry's `revisit.openSourceId` (nil closes) when the entry is the Sources list root; on `.push` the session is left as it is | AC-2.2 – AC-2.5; AC-2.3 keeps a sidebar visit's open Source | Applying on every commit: closes A on AC-2.3 |
| D-11 | Names: `listScrollAnchor` → `revisit.listSelection`, `withListScrollAnchor` → `withListSelection`, `WorkspaceNavigation.listAnchor` → `listSelection`, `noteListAnchor` → `noteListSelection`, `stampListAnchor` and `stampSectionAnchor` → `stampLeaving(_:)` (the section anchor is noted into the held revisit by `go(to:from:)`), `ListSelectionAnchorModifier` → `ListSelectionModifier`, with `ListAnchor.resolved` inlined into it and the enum gone; `ConclusionAnchorTarget` goes and `resolve` returns `Stop?` | It is no longer a scroll anchor; two types fewer | Keeping the false names |
| D-12 | No arrival scrolls to a row. Kept: `PVNativeListBehavior`'s `pvScrollsRowIntoView(selection…, restartsAt:whenChanged:)` with `scrollsOnAppear` at its default (false), so the keyboard's row stays in view and `restartKey` (a sort or filter) still resets; Home/End; `reveal` (an opened Source); the 150 ms repeat; `SourcePageView`'s error-count `scrollResetKey`; the record section's keyboard hand-off; the Timeline's `focusKeeper(…, scroll: { _ in })` and `unfold`'s `pendingReveal` (every Timeline item is built, since its placement measures them all, so the keeper hands the card the keyboard without a reveal) | The y owns arrival; what is not an arrival stays | Keeping both: the row scroll moves the page after the y lands |
| D-13 | Sources drift is accepted: on the Sources table a far y can show other rows than were left, because the platform estimates undrawn rows; this PR does not touch row heights | User, 2026-11-25 | A preparatory exact-heights PR |
| D-14 | No new copy, no new announcement | Nothing new is said or drawn | — |

**Rules this plan bends.** "(Batch 6) Back restores a section's scroll and focus, not its folds" → a record section's scroll is now the page's y and its anchor carries only the keyboard → the user's answer (2026-11-25: every main page, the offset replaces the section anchor's scroll, focus stays) → STEP-8 updates the rule. "(Batch 6) The Sources list is a native table" says no AppKit reach-in → the probe reads the table's `NSScrollView` → the user's rule of 2026-11-24 ("a little AppKit is allowed") → STEP-8 notes it on the rule. [`add-workspace-location`](../../../../.agents/skills/add-workspace-location/SKILL.md)'s ephemera row says scroll is omitted → the y is recorded → the user's rule of 2026-11-24 → STEP-8 updates the row.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `macos/App/DesignSystem/Components/ScrollMemory/PVScrollMemory.swift` *(new)* | file | `ScrollRowIntoView/PVScrollRowIntoView.swift` | That scrolls to an id through `ScrollViewReader`; this reads and writes a y |
| `PVScrollMemory` *(new)*: `struct { let arrival: Int; let offsets: [PVScrollSlot: Double]; let note: @MainActor (PVScrollSlot, Double) -> Void }`, `Equatable` on `arrival` and `offsets` | type | `PVListScroll` | A scroll request, not a memory |
| `PVScrollSlot` *(new)*: `struct: RawRepresentable, Hashable, Codable` over `String`, `static let page` | type | `ConclusionSectionAnchor.Part` | Open: a page names its own second slot |
| `EnvironmentValues.pvScrollMemory: PVScrollMemory?` *(new)* | key | `pvPageViewportSize` | — |
| `View.pvRemembersScroll(_ slot: PVScrollSlot = .page)` *(new)* | modifier | `pvScrollsRowIntoView` | That scrolls to an id |
| `PVScrollRestore` *(new, pure)*: `init(offset: Double?)`, `mutating func bounds(_ y: Double) -> Double?` (the y to note, or nil), `mutating func layout(documentHeight: Double, visibleHeight: Double, topInset: Double) -> Double?` (the y to scroll to), `isDone` | type | `ListScrollAnchorModifier`'s `pinnedAnchor` state | D-6 as a testable value |
| `PVScrollMemoryProbe` *(new, private `NSViewRepresentable`)* | type | `PVPopupWindowHost.startFollowing` | Follows a window, not a page's y |
| `WorkspaceRevisit` *(new)*, `WorkspaceLocation.revisit` | type, field | `sectionAnchor`, `listScrollAnchor` | Replaces both (D-9) |
| `WorkspaceNavigation.arrival`, `revisit`, `noteScrollOffset(_:slot:arrival:)`, `openSourceProvider` *(new)* | members | `listAnchor`, `noteListAnchor` | Same shape (D-7, D-8) |
| `WorkspaceArrival` *(new)* | type | `PendingNavigation` | That is a request; this is how a commit came |
| `WorkspaceSession.applyHistoryState(_:)` *(new)* | func | `setOpenSource` | The one rule of D-10 |
| `PVScrollMemoryTests.swift`, `PVScrollMemoryHostedTests.swift` *(new)* | tests | `PVPageColumnsTests.swift`, `SourcesOutlineHostedTests.swift` | — |

**Builds on.** S16-46's stamp-on-leave field; `WorkspaceDestinationHost`'s per-place `.id`; the kit containers every page already uses; `hostInBorderlessWindow` for hosted tests.
**Deletes.** `ListScrollAnchorModifier`; the `ListAnchor` enum (`settle`; `resolved` inlined); `WorkspaceLocation.listScrollAnchor` and `sectionAnchor` as fields (into `revisit`); `withPageSection`'s hand clear; `NavigationHistoryStore.stampListAnchor` and `stampSectionAnchor`; the `scrollResetKey` arguments `openPageSection` (`ConclusionDetailPage`), `sourceID` (`SourcePageView`'s first page) and `typeID` (`SourceTypePageView`); `ListSelectionAnchorModifier.reveal`; `SourcesOutline.sourceToReveal` and `closedOwnerID`; the reveal closure in `SourcesListContent`; `PVNativeListBehavior`'s `onAppear` selection scroll, `scrollsOnAppear: true` and `onChange(of: ids)` scroll; `PVTable`'s `.scrollTargetLayout()` and its comment; `conclusionAnchorRestore`'s `scrollAnchor:` and `scroll:` parameters, `scrollTarget`, `scrollRequest`, its `pvScrollsRowIntoView`; `ConclusionAnchorTarget` (its `stop` returned bare) and the scroll ids its builders pass (`PersonFamilyContent`, `PersonTimelineContent`, `PersonSourcesContent`, `ConclusionGallerySection`, `PlaceRelationshipRow`, `ReconciledValueRow`, `PersonRecordLinksColumn`); `PersonTimelineSection`'s `scroll:` argument at its `conclusionAnchorRestore` (its `pendingReveal` stays for unfold); the tests of each (§8).
**Next adds.** A new main page adopts by drawing in `PVPageColumns`, `PVTable`, `PVList` or under `pvNativeListBehavior`, or one `.pvRemembersScroll(_:)` inside a plain `ScrollView`; the composer's two columns are two slots (idea); a new kind of revisit is one member of `WorkspaceRevisit`. Exact Sources heights change nothing here.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| Every arrival scrolls to an old y | every main page | Re-arms per arrival (D-7); a y that no longer fits stays at the top (D-6); nothing drawn |
| Back sets the open Source | `SourcesOutline` via `openSourceID` | An id with no listed Source draws nothing (outline today); a selection no row has is cleared by `ListSelectionModifier` |
| A relaunch restores a y | the restored entry's page | As any arrival; the file value is validated (D-9) |

### Scale

At the map's Scale (3,000 Sources, S16-71's probe): a scroll event calls `note` (store one `Double`, no observation, no file write); the file is written only by the moves that write it today, with one more number per entry (100 entries). A restore is one `scroll(to:)`. The probe's subtree search (D-3) runs once per mount, over at most 6 ancestors' subtrees; it stops at the first match.

### Edges

- **Assumptions.** The document view is flipped (y grows down) for `ScrollView`, `List` and `Table`; T-5 holds each. `contentInsets.top` is the Table's header and 0 elsewhere; T-5 asserts top reads 0 on the Table.
- **Neighbors.** y 0 on a fresh view → done at once, never scrolls (AC-1.5); on a reused one → the top (AC-1.10). y exactly the max → restores; max + 1 → top (T-1). A bounds change at the top while armed is not noted; at 1 pt it disarms (T-1). A focus hand-off that scrolls a row into view before the content fits disarms the restore: the row stays in view (accepted).
- **Removed inputs.** Rows deleted since → shorter document → top (AC-1.6). The open Source deleted or filtered out → draws nothing, its graphs vanish, the y may land past the end → top. A Source open at the y's time but closed after relaunch → drift (D-13).
- **Real data.** None — no table or seed drives a rule.
- **Untrusted size.** The history file's y: non-finite or negative is dropped (D-9); a huge one never fits and leaves the top.

### Schema

None — no catalog change.

### Go core

None — Swift only.

### FFI

None —

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Memory value, modifier, probe, restore rule | `PVScrollMemory`, `pvRemembersScroll`, `PVScrollRestore` | `macos/App/DesignSystem/Components/ScrollMemory/PVScrollMemory.swift` *(new)* | Kit: no navigation import |
| Page scroll | `PVPageColumns.scroll(content:)` | — | `.pvRemembersScroll()` on the inner `VStack` (inside the `ScrollView`) |
| Table scroll | `PVTable.rowList` | — | `.pvRemembersScroll()` on the `LazyVStack` |
| Native list / table | `PVNativeListBehavior.body` | — | `.pvRemembersScroll()` on `content` (probe as background, D-3) |
| Promote | `PromoteView.body` | — | `.pvRemembersScroll(.page)` on the `ScrollView`'s `VStack` |
| Host | `WorkspaceDestinationHost.body` | — | `.environment(\.pvScrollMemory, …)` inside the `.id`, from `navigation.arrival.id`, `currentLocation.revisit.scrollOffsets`, `noteScrollOffset` |

`pvRemembersScroll(slot)`: reads `\.pvScrollMemory`; nil → the content unchanged; else the content with `.page` claimed (when `slot` is `.page`, the environment's value for the content carries a memory that no longer offers `.page`; another slot leaves it) and `.background(PVScrollMemoryProbe(memory, slot))`. A slot already claimed under the host is not claimed again. The probe's coordinator holds one `PVScrollRestore`, rebuilt when `memory.arrival` changes; it sets `postsBoundsChangedNotifications` and `postsFrameChangedNotifications`, observes with `NotificationCenter` and removes observers in `dismantleNSView`. It looks for the scroll view in `viewDidMoveToWindow` and on the next main turn after `updateNSView` until found.

States: no scroll view found → nothing happens (T-5 fails, Stop condition). Accessibility: none changes.

### Strings

None — no copy changes.

## 7. Steps

**STEP-1 — The entry records a y and a list's open row**
Files: `WorkspaceLocation.swift`, `WorkspaceRevisit.swift` *(new, beside it)*, `NavigationHistoryStore.swift`, `WorkspaceNavigation.swift`, `WorkspaceView.swift`, every caller of the renamed names (`rg -n "listScrollAnchor|withListScrollAnchor|listAnchor|noteListAnchor|stampListAnchor|ListAnchor\b|ListSelectionAnchorModifier" macos`). Skill: `add-workspace-location`.
Do: D-7 – D-9, D-11; `WorkspaceView` sets `openSourceProvider`; `withPageSection` drops its hand clear.
Check: T-2 pass; `xcodebuild test -scheme Provenencia -only-testing:ProvenenciaTests/WorkspaceNavigationTests` passes.

**STEP-2 — Back reopens the Source that was open**
Files: `WorkspaceSession.swift`, `WorkspaceView.swift`, `SourcesListView.swift`, `SourcesOutline.swift`, `WorkspaceNavigation.swift` (`ListSelection.settle`, the modifier's `reveal`).
Do: D-10; delete the reveal (Deletes).
Check: T-3, T-7 pass.

**STEP-3 — The kit remembers a scroll view's y**
Files: `DesignSystem/Components/ScrollMemory/PVScrollMemory.swift` *(new)*. Skill: `add-ui-component` (design-system layer).
Do: D-1 – D-4, D-6 and the macOS section's shape.
Check: T-1 pass.

**STEP-4 — Every main page's scroll view remembers**
Files: `PVPageColumns.swift`, `PVTable.swift`, `PVNativeListBehavior.swift`, `WorkspaceDestinationHost.swift`, `ConclusionDetailPage.swift`, `SourcePageView.swift`, `SourceTypePageView.swift`.
Do: D-4, D-5; the host's environment value; the three arrival `scrollResetKey` arguments go (D-6).
Check: T-5 pass.

**STEP-5 — Lists stop scrolling to a row on arrival**
Files: `PVNativeListBehavior.swift`, `PVTable.swift`, `SourceTypesListPane.swift`, `WorkspaceNavigation.swift`, `SourcesOutlineHostedTests.swift`.
Do: D-12 for the lists.
Check: T-6 pass; `SourcesTableHostedTests` and `PVListTests` pass.

**STEP-6 — A record section's anchor carries only the keyboard**
Files: `ConclusionAnchorRestore.swift` and its seven call sites (§4), their content builders, their tests.
Do: D-11 and D-12 for record pages.
Check: T-8 pass; `PersonFamilyContentTests`, `PersonTimelineContentTests`, `PersonSourcesContentTests` pass.

**STEP-7 — Promote remembers**
Files: `PromoteView.swift`.
Do: one `.pvRemembersScroll(.page)`.
Check: manual check 6.

**STEP-8 — Docs**
Files: `.agents/skills/add-workspace-location/SKILL.md` (the ephemera row: the offsets and the open Source are recorded in `revisit`; Step 5: the section anchor carries the keyboard and the page's y the scroll), `docs/macos-client-patterns.md` (its "Back to a page returns to the row it opened from" line, the same way), the kit README's PageColumns row (`scrollResetKey` is not for arrivals), `macos/App/DesignSystem/README.md` (a ScrollMemory row; ScrollRowIntoView's row drops `PVList`'s arrival note if it names one), `docs/deployment-plan/spike-16/deployment-plan.md` (the two rules under **Rules this plan bends**, map row), `docs/ideas/source-page-followups.md` and `docs/ideas/citation-composer-followups.md` (the two Out lines), `docs/deployment-plan/spike-16/completed.md`, this plan, `VERSION`, `core/version.go`, `MARKETING_VERSION`.
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-72-scroll-offset-history.md` reports no errors; `scripts/check-guidance-names.py` passes.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period ("Return every list to the position it was scrolled to."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `PVScrollMemoryTests.swift` `aRestoreLandsOnceTheContentFits` *(new, table)* | nil / 0 at top → done, no scroll; nil when not at top → scroll to 0; 1200 with document 900 → nil, then 2000 → 1200, done; max exactly → scroll; max + 1 → nil; armed bounds 0 → not noted; armed bounds 1 → noted, done; done bounds 40 → 40 | D-6, AC-1.5 – AC-1.8 |
| T-2 | Swift | `WorkspaceNavigationTests` `theRevisitIsStampedOnTheEntryBeingLeft`, `aPushStartsClean`, `aNoteOfAnotherArrivalIsDropped`, `arrivalCountsIdentityChangesAndHistoryMoves`, `scrollOffsetsRoundTripAndDecodeLeniently`, `theOpenSourceIsStampedOnTheSourcesListAndNeverWritten`, `oldFilesKeepTheirSelectionAndSectionAnchor` *(new)*; `listScrollAnchorRoundTrips`, `legacyHistoryMissingListScrollAnchorDecodesAsNil` and every test of a renamed name renamed | Leave a Source page at 600 → its entry `.page` 600; Back → 600; Vitals at 900 → `withPageSection(.family)` → Family's entry has no offsets, Vitals keeps 900; a coalesced visit keeps the live y; a Persons entry has no open Source; stale arrival note → unchanged; coalesced go → same arrival; −5 and a hand-written file with `"scrollOffsets": {"page": -1}` → no offset; the legacy fixture keeps the key `"listScrollAnchor"`; encoded JSON has no `openSourceId` and keeps the keys `listScrollAnchor` and `sectionAnchor` at the top level | D-7 – D-9, D-11, AC-1.9, AC-1.10 |
| T-3 | Swift | `WorkspaceSessionTests` `historyReopensTheSourceAListEntryHad` *(new, table)* | `.history` Sources root with `"s2"` → open s2; with nil → closed; `.push` → unchanged; `.history` Source page → unchanged | D-10, AC-2.2 – AC-2.5 |
| T-4 | Swift | (removed) `WorkspaceNavigationTests` `aRevealKeepsAnAnchorItDraws`; `SourcesOutlineTests` cases of `sourceToReveal` | Deleted with the reveal | D-10, D-12 |
| T-5 | Swift | `PVScrollMemoryHostedTests.swift` *(new, `.hostedWindows`)* `pageColumnsRestoreTheirY`, `aListRestoresItsY`, `aTableRestoresItsYUnderItsHeader`, `lateRowsMoveTheListOnce`, `aScrollBeforeTheRowsArriveWins`, `aNewArrivalRearms`, `aReusedScrollViewReturnsToTheTop`, `aNestedContainerIsNotClaimed`, `aSecondSlotIsRememberedApart` | Each host gets memory with y 400 over 3,000 pt of content → `contentView.bounds.minY + contentInsets.top` 400; Table at top reads 0; content 300 pt then 3,000 → 400 once; scroll to 50 first → stays 50; arrival change with nil on a scrolled view → top; a nested `PVTable` never notes `.page`; two `ScrollView`s, `.page` and `"second"`, each restore their own y | D-1 – D-6, AC-1.7, AC-1.8, AC-1.10 |
| T-6 | Swift | `SourcesOutlineHostedTests` `backRestoresTheOpenSourceTheSelectionAndTheY` *(new, replaces `anAnchorOnAGraphOfAClosedSource…` and `anAnchorSetBeforeThePageIsHosted…`)* | Harness with 15 extra Sources, s1 open, `g1-7` selected, scrolled to the graph; leave to a Source page; Back → s1 open, `g1-7` selected, y as stamped | AC-2.1, AC-2.2 |
| T-7 | Swift | `SourcesOutlineTests` `openingMovesASelectionOffTheClosedGroup` | Unchanged cases pass with `sourceToReveal` gone | D-8 |
| T-8 | Swift | `ConclusionAnchorRestoreTests` `anAnchorTakesTheKeyboardAndDoesNotScroll` *(new)*; existing cases return the stop alone | Anchor `.detailRow` "birth" → stop "birth"; no scroll request | D-11, D-12, AC-1.3 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `SourcesOutlineHostedTests`, `SourcesTableHostedTests`, `PVListTests`, `PVPageColumnsTests`, the Person content tests.

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
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together): the next minor after `VERSION` on `main`
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated): not gated
- [ ] Domain doc updated if a rule in docs/*.md changed: none; the skill and README rows of STEP-8
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

On a project with at least 200 Persons, 100 Sources (one with 8 graphs) and 30 Source types:

1. Persons: scroll far, open a Person, Back, Forward, Back: the list where it was, the row selected (AC-1.1). Quit and relaunch on the list (AC-1.9).
2. Source page: scroll, open a graph, Back (AC-1.2). Source type page and Properties the same way, then a history-menu jump (AC-1.4).
3. Person page: Sources section scrolled, open a Source from a row, Back: the y, and the keyboard on the row (AC-1.3). Switch sections, Back (AC-1.10).
4. Sources: `Open <graph>` from a closed Source's menu, Back (AC-2.1); open A, go to Persons, sidebar Sources (AC-2.3); Back to an entry with B open while A is open (AC-2.2); Back to an entry left with none open (AC-2.5); open A, relaunch (AC-2.4). Scroll far down by the wheel, open a Source page, Back: note how far the rows drift (D-13, for the Landed note).
5. Delete Persons until the list is short, Back to a far entry: the top (AC-1.6).
6. Promote: scroll, open the Source page from its header, Back (AC-1.11).
7. Each at Regular and Wide.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| The probe's frame match finds no `NSScrollView` for `List` or `Table` | T-5 `aListRestoresItsY`, `aTableRestoresItsYUnderItsHeader` |
| A reused page scroll view keeps the last section's y | D-6 scrolls to the top on a new arrival with no y; T-5 `aReusedScrollViewReturnsToTheTop` |
| Focus hand-off scrolls first on record pages | Accepted (Edges); manual check 3 |
| The Timeline cannot take the keyboard on an unbuilt card without its anchor scroll | Stop condition |

**Stop and report if:**

- No `NSScrollView` is found for one of `ScrollView`, `List`, `Table` by D-3 (T-5 fails), or a second probe on a page finds the same scroll view.
- A document view is not flipped, or `contentInsets.top` is not the Table header's height, so y 0 does not read the top.
- `PersonTimelineSection` no longer gives a restored anchor's card the keyboard once `scroll:` is gone (`PersonTimelineContentTests` or manual check 3).
- A hosted test needs a fixed sleep to pass (wait on state with a 10 s failure limit, as S16-71's hosted suites do).
- Any file under §4 no longer matches its row.

## 12. Open questions

None.

## 13. PR

**Title:** S16-72 — Back returns to the scroll position
**Body:** objective in one sentence; what shipped against US-1 and US-2; AC evidence; deviations from the plan; manual check, with the drift seen on Sources; `Plan: docs/deployment-plan/spike-16/prs/S16-72-scroll-offset-history.md`.
