# S16-46 — Back returns to the row you opened in a section

**Status:** Draft
**Spike / slice:** Spike 16 · Slice 6b — Person page follow-ups
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: Back moves the scroll and the keyboard to a row the page already draws; nothing on any page looks different, working rule "(Batch 6) Back restores a section's scroll and focus, not its folds")
**Board:** —
**Depends on:** S16-03 (sections as places, landed), S16-07 (one paged fold, landed)
**Blocks:** —
**Branch:** `s16-46-section-anchor`
**Version bump:** patch — it changes shipped app behavior ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-workspace-location`](../../../../.agents/skills/add-workspace-location/SKILL.md), [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md)
**Rules that bind:** `.cursor/rules/workspace-navigation.mdc`, `.cursor/rules/macos-client.mdc`, `.cursor/rules/swift-tests.mdc`, `.cursor/rules/design-system-layers.mdc`
**Context:** working rules "(Batch 6) Back restores a section's scroll and focus, not its folds", "(Batch 1) One paged fold that moves focus", "(Batch 1) One open section, one list of reads", "(Batch 1) The Timeline builds what it shows"; [audit](../person-page-audit.md) P-19; dogfood bar 21; [`navigation-history.md`](../../archive/spike-3/navigation-history.md) (List scroll row); [S15-48 plan](../../spike-15/prs/S15-48-source-type-page.md) D-10 (the list anchor's one mechanism)
**Planned:** 2026-11-19 against `main` @ `f757b45`
**Review:** [`S16-46-section-anchor.review.md`](S16-46-section-anchor.review.md) — round 1 answered; round 2 pending

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

On a Person, Event or Place page, the researcher opens a relative, an event, a Source or a related place from a row, looks at it, and presses Back. Today the page comes back at its top with nothing focused, so a researcher walking a family or a timeline loses their place on every hop (audit P-19). After this PR, Back and Forward put the page's scroll on the row that was opened and give that row the keyboard, and the same holds after quitting and relaunching.

**Why now.** Batch 6 took P-19 back from the parked list (user, 2026-11-17), and the working rule fixes its shape: an anchor on the history entry, scroll and focus restored, folds not.

**What stays.** Folds open closed on every visit (S13-16 UX-5): a row that a Show more had revealed is not revealed again; its fold's Show more gets the keyboard instead. A page opened any other way (a link, the omnibar, the sidebar, a section switch) opens at its top as today. The page's reads, its section switcher, the lists' scroll anchor and every view's look are unchanged.

## 2. User stories

**US-1.** As a researcher on a person's Family, when I open a relative's tile and press Back, the Family shows that tile in view with the keyboard on it, so I can go on to the next relative.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Anna's Family shows four children; open the third child's tile (Friedrich), press Back | Anna's Family; Friedrich's tile is in view and has the focus ring |
| AC-1.2 | A person with 35 children with one partner; Show more, open the 33rd child, press Back | The children fold is closed again (30 tiles); its "Show 5 more" row has the keyboard and is in view |
| AC-1.3 | Open a child's tile; delete that child, press Back | Anna's Family at its top; no tile is focused by the restore |

**US-2.** As a researcher on a Timeline, when I open an event or a person on an event and press Back, the Timeline shows that row in view with the keyboard on what I opened.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | A Timeline of 40 events; open the 30th event's title, press Back | The 30th row is at the top of the view; its title button has the keyboard |
| AC-2.2 | Open a participant card on the 12th row (Friedrich), press Back | The 12th row in view; Friedrich's card has the keyboard |
| AC-2.3 | At Regular width, a row with 8 participants; Show more on its people, open the 7th card, press Back | That row in view; its people's "Show 3 more" has the keyboard |
| AC-2.4 | A Timeline of 60 dated events; Show more, open the 55th, press Back | The dated fold is closed (50 rows); its "Show 10 more" row is in view and has the keyboard |
| AC-2.5 | Open the 30th event, press Back, then Forward, then Back | Each Back lands as in AC-2.1 |

**US-3.** As a researcher on a person's Sources, when I open a Source, a record's Evidence graph or a node of the record links diagram and press Back, the Sources section shows what I opened with the keyboard on it.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Open the title of the 3rd Source row, press Back | That row in view; its title link has the keyboard |
| AC-3.2 | Open the graph link of a record line, press Back | That line in view; its graph link has the keyboard |
| AC-3.3 | A Source with 8 record lines; Show more on it, open the 7th line's graph, press Back | That Source's lines are folded again (5); its "Show 3 more" has the keyboard |
| AC-3.4 | Open a graph from a node of the record links diagram, press Back | That node has the keyboard; at a width where the diagram stacks under the rows, the diagram is scrolled into view |

**US-4.** As a researcher, when I open the Event or Place a field row leads to (the row's open arrow) and press Back, the arrow I pressed has the keyboard.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | On a person's Vitals, press the Birth row's open arrow (the birth Event), press Back | Vitals; the Birth row in view; its open arrow has the keyboard |
| AC-4.2 | On an Event page, press the Place row's open arrow, press Back | The Event page; the Place row's open arrow has the keyboard |

**US-5.** As a researcher on an Event or Place page, when I open a picture's Citation or a related place and press Back, that tile or row has the keyboard.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-5.1 | On an Event page with three pictures, open the second picture (its Citation in the composer), press Back | The Event page; the second picture's tile is in view and has the keyboard |
| AC-5.2 | On a Place page, open a row under Contains, press Back | The Place page; that row is in view and has the keyboard, with a visible focus ring |

**US-6.** As a researcher, the place I return to survives history moves and a relaunch, and a page I reach any other way opens at its top.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-6.1 | Do AC-1.1's open, quit the app, relaunch, press Back | As AC-1.1 |
| AC-6.2 | A history file written before this PR (no `sectionAnchor` key), or one with an anchor part this build does not know | It loads; Back to a Person page opens it at its top |
| AC-6.3 | Do AC-1.1's open, press Back, then switch Anna's page to Timeline | The Timeline opens at its top; the new entry carries no anchor |
| AC-6.4 | Do AC-1.1's open; then open Anna from the omnibar | Anna's page opens at its top (a new entry) |

## 3. Scope

| In | Covered by |
| --- | --- |
| `ConclusionSectionAnchor` (a `Codable` part and id) and `WorkspaceLocation.sectionAnchor`: not identity, decodes nil from older files and unknown parts, cleared by `withPageSection` | STEP-1, AC-6.2, AC-6.3 |
| `WorkspaceNavigation.go(to:from:)` stamps the entry being left; the store's one stamp helper | STEP-1, AC-2.5, AC-6.1 |
| One restore modifier that resolves, scrolls and focuses once per mount | STEP-2 |
| `ConclusionShowMoreRow` focused through its section's stop, so a restore can focus it | STEP-2, AC-1.2, AC-2.3, AC-2.4, AC-3.3 |
| Family tiles record and restore | STEP-3, US-1 |
| Timeline row titles and participant cards record and restore | STEP-4, US-2 |
| Sources titles, record lines and diagram nodes record and restore | STEP-5, US-3 |
| Field rows' open arrow (Person Vitals, Event and Place Details) record and restore | STEP-6, US-4 |
| Event and Place picture tiles (no viewer) and Place relationship rows record and restore | STEP-7, US-5 |
| `add-workspace-location`, `navigation-history.md`, `macos-client-patterns.md` say how; the patch bump | STEP-8 |

| Out | Home |
| --- | --- |
| Restoring folds (a revealed page stays revealed on Back) | not planned: refused, S13-16 UX-5 and the working rule |
| The Person Gallery: a tile opens the likeness viewer, a sheet, not a place; the viewer's provenance links leave from the sheet | not planned (map scope: "open sheets rather than places") |
| The provenance sheet's Source, Citation and Observation links (Vitals, the Why) | not planned: they leave from a sheet, as the Gallery's viewer does |
| The lifeline's points and caps (they scroll the list; they open nothing) | not planned |
| Restoring the scroll offset of a page whose anchored row is gone | not planned: the rule opens it at its top |
| Section anchors on Source pages, Evidence graphs and other non-Conclusion pages | not planned |
| Clearing an entry's anchor when the page is left without an open | not planned: the rule keeps the row "last opened" (D-2) |

## 4. Current state

Verified at `f757b45`.

| Area | Where | Today |
| --- | --- | --- |
| Location | `macos/App/Features/Workspace/WorkspaceLocation.swift` `WorkspaceLocation` | `listScrollAnchor` is the one non-identity scroll field: in `CodingKeys`, the memberwise `init`, `init(from:)` with `nilIfEmpty`, `withListScrollAnchor(_:)`, and left out of `==`. `pageSection` is a typed `Codable` enum from `ConclusionPageSection.swift` (same folder) whose unknown raw values decode as nil. `withPageSection(_:)` copies every other field |
| Navigation | `macos/App/Features/Workspace/WorkspaceNavigation.swift` `WorkspaceNavigation` | `go(to:)`: an equal location goes straight to `performGo` (no guard); otherwise asks `leaveGuard`, then `performGo`, which stamps `pendingListScrollAnchor` on the outgoing entry. Nothing records which row a page opened |
| History store | `macos/App/Features/Workspace/NavigationHistoryStore.swift` `stampListScrollAnchor(_:)`, `go(to:)` | `stampListScrollAnchor` guards the index and a list root, normalizes, compares, assigns, no persist; `go(to:)` appends and persists, so a stamp before a push is written with it |
| Destination mount | `macos/App/Features/Workspace/Session/PlaceRegistry.swift` `.personDetail`, `.eventDetail`, `.placeDetail` `viewIdentity` | Each Conclusion page is keyed by `entityId`, so Back to another person's page mounts it fresh; a section switch swaps the section view under the same page (`PersonDetailSections`) |
| Content memo | `macos/App/Features/Workspace/Session/WorkspaceSession+Derived.swift` `conclusionContent` | One memo per section key per session, keyed on the section's `Inputs` (`extra`). Today a Back to a page it holds is a memo hit |
| Page scroll | `macos/App/DesignSystem/Components/PageColumns/PVPageColumns.swift` `PVPageColumns.scroll` | Owns the page's `ScrollView`; `scrollResetKey` (the open section) scrolls to the top on change. A fresh mount starts at the top |
| Scroll helper | `macos/App/DesignSystem/Components/ScrollRowIntoView/PVScrollRowIntoView.swift` `pvScrollsRowIntoView(_:anchor:animated:...whenRequested:)` | With a request token, scrolls to the view with `.id(row)` on the next main-actor turn. Family, Timeline, Sources and the Gallery each use it for Show more |
| Focus | `macos/App/Platform/FocusClaim.swift` `FocusClaim.claim`; `macos/App/Platform/FocusKeeper.swift` `FocusKeeper.hand` | The one focus writer, and the keeper's hand-back that the Gallery uses after its viewer closes |
| Show more | `macos/App/Features/Conclusions/ConclusionShowMoreRow.swift` `ConclusionShowMoreRow` | Holds a private `@FocusState hasKeyboard`; the section cannot focus it. Six callers: `PersonFamilySection.swift` (1), `PersonTimelineSection.swift` (2), `PersonSourcesSection.swift` (2), `ReconciledValueRow.swift` (1) |
| Family | `macos/App/Features/Conclusions/PersonFamilySection.swift` `PersonFamilySection`, `PersonFamilyDiagram` | `open: (WorkspaceLocation) -> Void` → `navigation.go(to:)`. Focus `String?` = tile id; tiles carry `.id(placed.id)`; Show more rows carry no `.id`. Tiles exist only once `width > 0` |
| Family content | `macos/App/Features/Conclusions/PersonFamilyContent.swift` `PersonFamilyContent`, `tileID(column:group:personID:)`, `Fold` | Tile id `"<l\|r>-<group>-<personID>"`: parent sets `p<k>` (k over all parent units), siblings `s`, partner and one-parent units `<index>` (over all units). Folds `.parentSets`, `.siblings`, `.partners`, `.children(Int)`, limit 30. Keeps no ids of hidden members. The focus person's tile has no location |
| Timeline | `macos/App/Features/Conclusions/PersonTimelineSection.swift` `PersonTimelineList` | Focus `String?` = a row's event id or a card id; items carry `.id(item.id)`, cards do not. `heights` holds each measured item; `keeper` is a `FocusKeeper<String>`. `scrollTarget`/`scrollRequest` with anchor `.top` |
| Timeline content | `macos/App/Features/Conclusions/PersonTimelineContent.swift` `PersonTimelineContent` | Item ids: event id, `"birth"`/`"death"`, `"undated"`, `"more.dated"`, `"more.undated"`. Card id `"<eventId>-<personId>"`. Keeps `datedFoldIDs`; `isShown(_:)`, `row(holdingCard:)`, `pages(toShow:)` answer from kept ids. Hidden undated ids are not kept |
| Sources | `macos/App/Features/Conclusions/PersonSourcesSection.swift` `PersonSourcesList`, `PersonSourcesFocus`, `focusedGraphID` | `open: (WorkspaceLocation) -> Void`, called by the diagram, the title `PVInkLink` and the graph `PVButton`. Focus cases `.graph`, `.unpromote`, `.node`; `focusedGraphID` switches over them exhaustively. The title has no focus case and no Return activation. Lines carry `.id(line.id)`; rows and Show more rows carry none. `pvScrollsRowIntoView` sits on `rows` only |
| Sources content | `macos/App/Features/Conclusions/PersonSourcesContent.swift` `PersonSourcesContent`, `Fold` | Row id = Source id; line id = claim id. Keeps `claimGraphs`, `graphLocations`, `foldedGraphs`. `rowFold` 50, `lineFold` 5 (fewest hidden 2). Hidden Source ids are not kept |
| Record links | `macos/App/Features/Conclusions/PersonRecordLinksColumn.swift` `PersonRecordLinksColumn`; `PersonRecordLinksContent.locations` | A node opens `links.locations[graphID]`; drawn by the companion host, which can land after the rows |
| Field rows | `macos/App/Features/Conclusions/ReconciledValueRow.swift` `ReconciledValueRow`, `ConclusionDetailRowsSection` | The open arrow (`PVIconButton`, `model.opens`) calls `navigation.go(to: opens.location)`; it has no focus binding and no Return activation. `ConclusionDetailRowsSection` is `ReconciledValueRow`'s one caller (Vitals, Event and Place Details); rows carry no `.id` |
| Gallery | `macos/App/Features/Conclusions/ConclusionGallerySection.swift` `ConclusionGallerySection.tileView` | With no `gallery.viewer` (Event, Place) a tile opens `navigation.go(to: tile.location)`; with one (Person) the viewer. `TileFocus`, `keeper`, `map`, `scroll` exist |
| Place relationships | `macos/App/Features/Conclusions/PlaceRelationshipRow.swift` `PlaceRelationshipRow`, `ConclusionDetailRelationshipSection`, `ConclusionDetailRelationship.id` | The row's `.plain` `Button` navigates itself; no focus state, no `.id`. A relationship is in one section only (self-loops refused since S16-36) |
| Tests | `macos/ProvenenciaTests/WorkspaceNavigationTests.swift` `leavingAListStampsTheOutgoingEntry`, `listScrollAnchorRoundTrips`, `legacyHistoryMissingListScrollAnchorDecodesAsNil`, `pageSectionPushAndRestore`; `PersonFamilyContentTests.swift`, `PersonTimelineContentTests.swift`, `PersonSourcesContentTests.swift` | The list anchor's stamp, round trip and legacy decode; the contents' folds |

**Precedent.** The list scroll anchor (`listScrollAnchor`, S15-48 D-10 and its tests): a non-identity field on the entry, `nilIfEmpty`, decodes nil from older files, stamped by the store with no persist. `pageSection`: a typed enum on the location whose unknown values decode as nil. The contents' query methods (`PersonTimelineContent.pages(toShow:)`, `isShown(_:)`, `PersonSourcesContent.foldedGraphIDs(by:)`) answer from ids the build keeps. The Gallery's `FocusKeeper.hand` after the viewer closes. Do not copy `pendingListScrollAnchor`: a section's anchor is known at the open (D-2).

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `ConclusionSectionAnchor` *(new)*, a `Codable, Equatable, Sendable` struct in `macos/App/Features/Workspace/ConclusionSectionAnchor.swift` *(new)* beside `ConclusionPageSection`: `part: Part`, `id: String`, `row: String?`. `enum Part: String, Codable { case family, timeline, sourceTitle, sourceLine, recordLinks, detailRow, picture, related }`; the raw values are frozen (written to history files). `row` names the row that holds `id` where the stop is inside a row: a Timeline card's event id, a Sources line's Source id; nil elsewhere. `WorkspaceLocation.sectionAnchor: ConclusionSectionAnchor?` *(new)*, not in `==`, decoded with `try? container.decodeIfPresent(...)` so an unknown part or a malformed value reads as nil; an empty `id` is normalized to a nil anchor | Typed, like `pageSection`, through the location's one `Codable` path; no hand grammar to parse | A `"<part>:<id>"` string with its own parser (M-2) — a second format beside `Codable` |
| D-2 | The anchor is written at the open: `WorkspaceNavigation.go(to:from: ConclusionSectionAnchor)` *(new)*, when `location != currentLocation` and history is attached, calls `NavigationHistoryStore.stampSectionAnchor(_:)` *(new)* on the current entry, then `go(to:)`, whose push persists both. The stamp comes before the leave guard; no Conclusion page installs one. An entry keeps its anchor until another open from it overwrites it: leaving by Back, the sidebar or the omnibar does not clear it, so Back or Forward to it later restores the last row opened from it | The opened row is known only at the open. The rule names the row "last opened" | A pending value stamped on every leave, like `pendingListScrollAnchor` — Back or a sidebar click would write an anchor for a row nobody opened. Clearing on a leave without an open — the rule says last opened, not last action |
| D-3 | `withPageSection(_:)` sets `sectionAnchor` to nil on its copy | A section switch is a new place, opened at its top (AC-6.3) | Keeping it — the next section would try to restore another section's row |
| D-4 | The store's two stamps share one private helper: `private func stampCurrent<T: Equatable>(_ keyPath: WritableKeyPath<WorkspaceLocation, T?>, _ value: T?)` (index guard, compare, assign, no persist). `stampListScrollAnchor` keeps its list-root guard and normalization and calls it; `stampSectionAnchor` calls it | The index guard and the no-persist rule live once (M-5) | A second copy of the body |
| D-5 | Each section's content answers a query, `func anchorTarget(for anchor: ConclusionSectionAnchor) -> ConclusionAnchorTarget<Stop>?` *(new)*, from ids its build keeps (§ Edges lists what each keeps). `Inputs` are unchanged | The session's content memo stays keyed on what the content draws, so an anchored Back is still a memo hit (M-1); it matches `pages(toShow:)` and `isShown(_:)` | Passing the anchor in `Inputs` — every anchored Back rebuilds the section (the memo is one per key per session) |
| D-6 | `struct ConclusionAnchorTarget<Stop: Hashable>: Equatable { var stop: Stop; var scrollID: String }` *(new)* and the restore modifier live in `macos/App/Features/Conclusions/ConclusionAnchorRestore.swift` *(new)*. `View.conclusionAnchorRestore(_ parts: Set<ConclusionSectionAnchor.Part>, isReady: Bool, focus: FocusState<Stop?>.Binding, keeper: Binding<FocusKeeper<Stop>>? = nil, map: @escaping (Stop) -> Stop = { $0 }, resolve: @escaping (ConclusionSectionAnchor) -> ConclusionAnchorTarget<Stop>?, scroll: @escaping (String) -> Void)`. It holds `@State didRestore`. On `onAppear` and on `isReady` turning true, once: when the location's anchor has a part in `parts` and `resolve` returns a target, it calls `scroll(target.scrollID)`, then gives the keyboard to `target.stop`: with a keeper, `FocusKeeper.hand(stop, keeper:focus:map:scroll:{ _ in })`; without, `FocusClaim.claim(focus, stop)` | One place turns an anchor into "scroll, then focus" (M-3); each page mounts per entity and each section per switch, so once per mount is once per arrival, and a later reload never moves the keyboard | A free-form `restore` closure per site — six copies of the same three lines. Restoring on every `currentLocation` change — a reload would steal focus |
| D-7 | `ConclusionShowMoreRow` takes `let stop: Focus` and focuses through the section's binding: `.focused(focus, equals: stop)`, `pvActivatesOnReturn(when: focus.wrappedValue == stop, press)`, and `press` reads `focus.wrappedValue == stop` before `expand()`. The private `hasKeyboard` goes. All six callers pass a stop (§ macOS) | A restore must be able to focus a Show more (the rule); one focus path | An optional `stop` with the private state kept for nil — two ways to focus one control |
| D-8 | One open shape. A section that hands `open` down passes `(WorkspaceLocation, ConclusionSectionAnchor) -> Void`, bound to `navigation.go(to:from:)` (`PersonFamilyDiagram`, `PersonTimelineList`, `PersonSourcesList` and the views under it). A leaf that already reads `WorkspaceNavigation` from the environment calls `navigation.go(to:from:)` itself (`ReconciledValueRow`, `ConclusionGallerySection`, `PlaceRelationshipRow`). Every opener named in § macOS writes an anchor | One signature to learn (M-4, X-2) | `open` beside an `openFrom` — the old closure would have no caller |
| D-9 | Folded: the stop is the fold's Show more. Gone: no restore; the page keeps its top. Folds are never revealed by a restore | The working rule | Revealing the fold through the anchor's page, as a lifeline click does — refused (S13-16 UX-5) |
| D-10 | Each new focus stop also gets `pvActivatesOnReturn(when: focus == stop)` like its siblings: the Source title, the field row's open arrow and the relationship row | A restored stop answers Return as the Timeline title and the graph link do | Focus without Return — the researcher lands on a control Return does not open |
| D-11 | Sources: the scroll modifier moves from `rows` to the `ConclusionPinnedSideColumn` in `PersonSourcesList.body`; the diagram column carries `.id(PersonSourcesList.diagramScrollID)` *(new)*, `"diagram"`. Node anchors (`.recordLinks`) restore from a second `conclusionAnchorRestore([.recordLinks], isReady: true, …)` inside the diagram host's body, resolving `links.locations[anchor.id] != nil` → `.node(graphID:)`. `focusedGraphID` returns nil for `.title` and `.more` | The node is drawn by the companion read, which can land after the rows; the proxy must reach the diagram when it stacks; a Back draws no highlight (nothing looks different) | Resolving a node against the claims — it would claim a node the diagram has not drawn |
| D-12 | The field rows' arrow focus is held by `ConclusionDetailRowsSection`: `@FocusState private var openFocus: String?`, passed to each `ReconciledValueRow` as `openFocus: FocusState<String?>.Binding` *(new parameter)*; the arrow gets `.focused(openFocus, equals: model.id)`. The row's private `Stop` is unchanged except for the Show more's `.more` (D-7) | The arrow's stop is the section's to restore, and the section is the row's one caller | A per-row `claimsOpenFocus` flag — a second way to claim focus |
| D-13 | Timeline restore waits for every item to be measured: `isReady` is `!content.items.isEmpty && heights.count == content.items.count`, then it scrolls through `scrollTarget`/`scrollRequest` (anchor `.top`) and hands the stop through its `keeper`. A Show more stop is not `isShown`, so on a width change the keeper does not hand it back; this matches today, where a Show more's private focus was not kept either | A partial placement would scroll to a row the final layout moves (X-9) | `pendingReveal`, which scrolls once the one target is measured |
| D-14 | Coverage is § Scope's In: every row or tile on a Person, Event or Place page that opens a place directly | The map row names Person, Event and Place pages; Vitals' arrow opens a place, so the map's Vitals exception does not apply | Person sections only — Event and Place Details share `ConclusionDetailRowsSection` with Vitals, so leaving them out would need a gate |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `ConclusionSectionAnchor` in `macos/App/Features/Workspace/ConclusionSectionAnchor.swift` *(new)* | type / file | `ConclusionPageSection` (same folder) | A section names a place; an anchor names a row inside one. It sits beside it so the location stays typed |
| `WorkspaceLocation.sectionAnchor` *(new)* | field | `listScrollAnchor`, `pageSection` | `listScrollAnchor` is for list roots only (`isListRoot`); the coding copies `pageSection`'s lenient decode |
| `WorkspaceNavigation.go(to:from:)` *(new)* | func | `go(to:)`, `noteListScroll` | Extends `go(to:)` with one stamp; `noteListScroll` reports while scrolling, the wrong moment (D-2) |
| `NavigationHistoryStore.stampSectionAnchor(_:)`, `stampCurrent(_:_:)` *(new)* | func | `stampListScrollAnchor(_:)` | Shares its body through `stampCurrent` (D-4) |
| `macos/App/Features/Conclusions/ConclusionAnchorRestore.swift` *(new)*: `ConclusionAnchorTarget`, `conclusionAnchorRestore` | file / type / modifier | `ListScrollAnchorModifier` (`WorkspaceNavigation.swift`), `FocusKeeper.hand` | That modifier drives `scrollPosition` and reports scrolling; this one restores one stop once and delegates focus to `FocusClaim` or `FocusKeeper.hand` |
| `anchorTarget(for:)` on `PersonFamilyContent`, `PersonTimelineContent`, `PersonSourcesContent` *(new)* | func | `pages(toShow:)`, `isShown(_:)`, `foldedGraphIDs(by:)` | Same pattern: a query over kept ids |
| `PersonFamilyContent.hiddenTiles`, `PersonTimelineContent.hiddenUndatedIDs`, `PersonSourcesContent.hiddenSourceIDs` *(new)* | stored ids | `datedFoldIDs`, `foldedGraphs` | Same shape as the kept ids beside them |
| `PersonFamilyContent.moreID(_:)`, `PersonTimelineContent.participantsMoreID(eventId:)` *(new)* | func | `tileID(column:group:personID:)`, `Slot.id` | Show more had no id |
| `PersonSourcesFocus.title(sourceID:)`, `.more(PersonSourcesContent.Fold)` *(new)* | cases | `PersonSourcesFocus` | Extends the section's one focus type |
| `ReconciledValueRow.openFocus`, `Stop.more` *(new)* | param / case | `ReconciledValueRow.Stop` | See D-12 |
| `ConclusionDetailRowsSection.anchorTarget(rows:anchor:)` *(new)* | func | — | Pure lookup so a test reaches it |

Searched: `rg -n "scrollTarget|FocusClaim.claim|FocusKeeper.hand|stampListScrollAnchor|pendingListScrollAnchor|decodeIfPresent" macos/App`.

**Builds on.** The list scroll anchor's field and stamp; `pageSection`'s typed decode; `FocusClaim`; `FocusKeeper.hand`; each section's `pvScrollsRowIntoView(scrollTarget, whenRequested: scrollRequest)`; the contents' kept-id queries.
**Deletes.** `ConclusionShowMoreRow.hasKeyboard` (the private `@FocusState`), replaced by the section's stop. The `(WorkspaceLocation) -> Void` shape of `open` on `PersonFamilyDiagram`, `PersonTimelineList`, `PersonSourcesList`, `PersonSourcesRowView`, `PersonSourcesLineView`, replaced by D-8's. The body of `stampListScrollAnchor` that `stampCurrent` takes over.
**Next adds.** A Conclusion kind that adopts sections (Event, Place) gets restore with a `Part` case, an `anchorTarget(for:)` and one modifier call. A later anchor from a sheet (the Gallery viewer) is one `Part` and one `go(to:from:)`.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| Back/Forward to a Conclusion page entry that carries an anchor | `PersonDetailView`, `EventDetailView`, `PlaceDetailView` and their sections | Resets: the page mounts per `entityId` (`PlaceRegistry` `viewIdentity`) and each section per switch, so `didRestore` is fresh. Missing: a gone id resolves to nil, the page stays at its top (AC-1.3). State: the page draws as today; only scroll and focus move |
| A history file with an anchor read after the row's entity changed | the same pages | Resolution is by id against what is drawn now, never by position |
| A history file of this build read by an older build, or an older build's file read by this one | `WorkspaceLocation.init(from:)` | The older build ignores the key; this build decodes a missing or unknown anchor as nil (T-2) |

### Scale

At the map's Scale (200 events with 10 participants, 20 children in four parent sets, a person in 50 Evidence graphs) and bar 2's crafted sizes (500 participants on one event, 100 relatives per role): the stamp writes one value to the entry being left with no extra persist. Each content build keeps a few more ids, one string per hidden member: Family at most `kinship.Rules.MaxKinPerRole` (100) per role; the Timeline the hidden undated event ids (at most the person's events); Sources the hidden Source ids (at most the person's Sources). No participant id is kept (§ Edges). `anchorTarget(for:)` runs once per mount and is one dictionary or set lookup, plus a scan of one shown row's cards. `Inputs` and the memo key are unchanged, so an anchored Back is a memo hit as today.

### Edges

What each content keeps and how `anchorTarget(for:)` answers (`a` is the anchor):

| Content | Kept | `a.id` shown → stop · scroll id | Folded → stop · scroll id | Else |
| --- | --- | --- | --- | --- |
| Family (`.family`) | `hiddenTiles: [String: Fold]`: hidden parent sets (k ≥ shown): each partner's `l-p<k>-<pid>` → `.parentSets`; hidden siblings `l-s-<pid>` → `.siblings`; a shown unit i's hidden children `r-<i>-<pid>` → `.children(i)`; a hidden unit i (i ≥ shown): its partner and every child `r-<i>-<pid>` → `.partners` (a one-parent unit has no partner; its children map the same way) | a shown tile with a location → that id · that id | `moreID(fold)` · same | nil (the focus person's tile opens nothing, so it is never written) |
| Timeline (`.timeline`) | `datedFoldIDs` (kept today) and `hiddenUndatedIDs: Set<String>` | a row: a built row's event id → that id · that id. A card (`a.row` = event id): the row is built and shows the card → the card id · the row's id; the row is built, does not show it, and `participantsHidden > 0` → `participantsMoreID(eventId:)` · the row's id | a row or a card whose row is in the hidden part of `datedFoldIDs` → `"more.dated"` · same; in `hiddenUndatedIDs` → `"more.undated"` · same | nil |
| Sources (`.sourceTitle`, `.sourceLine`) | `hiddenSourceIDs: Set<String>` | title: a shown row's id → `.title(sourceID:)` · the Source id. Line (`a.row` = Source id): a shown line → `.graph(claimID:)` · the claim id; the row is shown, the line is not, and `hiddenCount > 0` → `.more(.lines(sourceID:))` · `"more.<sourceID>"` | the title's or the line's Source in `hiddenSourceIDs` → `.more(.rows)` · `"more.rows"` | nil |

- **Assumptions.** Ids are stable across a reload for the same data. A tile id holds its group index, so a removed parent set or partner group shifts the index and the tile resolves as gone (page top, AC-1.3). A card's and a line's row is named on the anchor (`row`), never parsed out of the id.
- **Neighbors.** The last shown tile of a fold resolves to the tile; the first hidden one to the fold's Show more (T-6, T-7). At Regular a 6th card is behind its row's participants' Show more and at Wide it is shown (T-7). A recorded birth row resolves to its event id like any row (T-7). A placeholder marker, the Undated heading and the lifeline open nothing and are never anchors.
- **Removed inputs.** A row whose entity was deleted or merged: gone, no restore (T-6, T-7, T-8). A card or line whose row is folded, or whose row is shown with a non-empty fold, resolves to that fold's Show more even when the person left the event or the record was unpromoted: the content keeps no participant or per-Source claim ids (D-5), so the keyboard lands on the Show more where it would have been. A field row that lost its `opens`: `anchorTarget(rows:anchor:)` returns nil (T-10).
- **Real data.** None — no table or seed drives the rule.
- **Untrusted size.** The anchor comes from the app's own history file, decoded by `Codable`; a value that matches nothing costs one failed lookup.

### Schema

None — no catalog change.

### Go core

None — Swift only.

### FFI

None — no RPC changes.

### macOS

| Part | Written by (the open) | `ConclusionSectionAnchor` | Restore site · `isReady` · focus |
| --- | --- | --- | --- |
| `.family` | `PersonFamilyDiagram` tile tap | id = `placed.id` | `PersonFamilyDiagram` · `width > 0` · `focused` |
| `.timeline` | `PersonTimelineEventRow` title button; `card(_:)` | title: id = event id. Card: id = card id, row = event id | `PersonTimelineList` · D-13 · `focused` with `keeper` |
| `.sourceTitle` | `PersonSourcesRowView.title` | id = Source id | `PersonSourcesList` rows (parts `[.sourceTitle, .sourceLine]`) · `true` · `focus` |
| `.sourceLine` | `PersonSourcesLineView` graph link | id = claim id, row = Source id | as above |
| `.recordLinks` | the diagram's `open:` in `PersonSourcesList.diagram` | id = graph id | diagram host body (D-11) · `true` · `focus` |
| `.detailRow` | `ReconciledValueRow` open arrow | id = `model.id` | `ConclusionDetailRowsSection` · `true` · `openFocus` (D-12); stop and scroll id = `model.id` (each row gets `.id(row.id)`) |
| `.picture` | `ConclusionGallerySection.tileView` when `gallery.viewer == nil` | id = `tile.id` | `ConclusionGallerySection` · `true` · `focused` with `keeper` and `map`; stop `.image(id)`, scroll id `tile.id`, when `gallery.tiles` has it |
| `.related` | `PlaceRelationshipRow` button (takes `anchorID: String`, the `ConclusionDetailRelationship.id`) | id = that id | `ConclusionDetailRelationshipSection` with a new `@FocusState focused: String?` · `true`; stop and scroll id = `row.id` (each row gets `.id` and `.focused`) |

Show more stops (D-7): Family `PersonFamilyContent.moreID(more.fold)` with `.id(moreID)` on the row — `.parentSets` → `"more-parentSets"`, `.siblings` → `"more-siblings"`, `.partners` → `"more-partners"`, `.children(i)` → `"more-children-<i>"` (tile ids start `l-` or `r-`, so they cannot collide); Timeline dated/undated `item.id`, participants `PersonTimelineContent.participantsMoreID(eventId: row.id)` = `"more.<eventId>"`; Sources lines `.more(.lines(sourceID: row.id))` with `.id("more.<sourceID>")`, rows `.more(.rows)` with `.id("more.rows")`; `ReconciledValueRow` `Stop.more`. Sources rows get `.id(row.id)`; the title gets `.focused(focused, equals: .title(sourceID: row.id))` and D-10's Return activation.

Each site sets its existing `scrollTarget` and bumps `scrollRequest` in `scroll`; `ConclusionDetailRowsSection` and `ConclusionDetailRelationshipSection` gain that pair and `pvScrollsRowIntoView(scrollTarget, whenRequested: scrollRequest)` on their stack. Previews pass `{ _, _ in }` for `open`.

States: no loading, empty or error state changes; a section that failed or is empty never restores. Accessibility: the focus move is the announcement; no new string. Keyboard: each restored stop is one Tab already reaches, and answers Return (D-10).

### Strings

None — no copy changes, and no action changes what it covers.

## 7. Steps

**STEP-1 — The anchor on the entry**
Files: `macos/App/Features/Workspace/ConclusionSectionAnchor.swift` *(new)*, `macos/App/Features/Workspace/WorkspaceLocation.swift`, `macos/App/Features/Workspace/WorkspaceNavigation.swift`, `macos/App/Features/Workspace/NavigationHistoryStore.swift`, `macos/ProvenenciaTests/WorkspaceNavigationTests.swift`. Skill: `add-workspace-location`, `add-swift-test`.
Do: D-1 – D-4. Add `sectionAnchor` beside `listScrollAnchor` in the field list, `CodingKeys`, both inits and the `==` doc comment (not in `==`). Write T-1 – T-4.
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/WorkspaceNavigationTests` passes.

**STEP-2 — One restore, Show more by stop**
Files: `macos/App/Features/Conclusions/ConclusionAnchorRestore.swift` *(new)*, `macos/App/Features/Conclusions/ConclusionShowMoreRow.swift`, `PersonFamilyContent.swift` (`moreID`), `PersonTimelineContent.swift` (`participantsMoreID`), `PersonSourcesSection.swift` (`.more` case, `focusedGraphID` nil for it), `ReconciledValueRow.swift` (`Stop.more`), and the six callers. Skill: `add-ui-component`.
Do: D-6, D-7. Give each caller its stop (§ macOS).
Check: the app builds; with the keyboard, each Show more on a Person page still reveals a page and moves focus to its first item (Family, Timeline dated and participants, Sources rows and lines, a field row with more than 21 lines).

**STEP-3 — Family**
Files: `PersonFamilyContent.swift`, `PersonFamilySection.swift`, `PersonFamilyPreviewData.swift`, `macos/ProvenenciaTests/PersonFamilyContentTests.swift`.
Do: `hiddenTiles` and `anchorTarget(for:)` per the § Edges table; D-8's `open`; the restore per § macOS. Write T-6.
Check: T-6 passes; AC-1.1 by hand.

**STEP-4 — Timeline**
Files: `PersonTimelineContent.swift`, `PersonTimelineSection.swift`, `macos/ProvenenciaTests/PersonTimelineContentTests.swift`.
Do: `hiddenUndatedIDs` and `anchorTarget(for:)` per § Edges; D-8's `open` (the card writes `row`); the restore per D-13. Write T-7.
Check: T-7 passes; AC-2.1, AC-2.2, AC-2.5 by hand.

**STEP-5 — Sources and the record links**
Files: `PersonSourcesContent.swift`, `PersonSourcesSection.swift`, `macos/ProvenenciaTests/PersonSourcesContentTests.swift`.
Do: `.title(sourceID:)`, `hiddenSourceIDs`, `anchorTarget(for:)` per § Edges; D-8, D-10, D-11. Write T-8.
Check: T-8 passes; AC-3.1, AC-3.2, AC-3.4 by hand, AC-3.4 also at a width where the diagram stacks.

**STEP-6 — Field rows**
Files: `macos/App/Features/Conclusions/ReconciledValueRow.swift`, `macos/ProvenenciaTests/ConclusionAnchorRestoreTests.swift` *(new)*.
Do: D-12, D-10, the scroll pair, `anchorTarget(rows:anchor:)` (a row with that id and `opens` → target `model.id` · `model.id`, else nil), the restore. Write T-9, T-10.
Check: T-9 and T-10 pass; AC-4.1, AC-4.2 by hand.

**STEP-7 — Pictures and related places**
Files: `macos/App/Features/Conclusions/ConclusionGallerySection.swift`, `macos/App/Features/Conclusions/PlaceRelationshipRow.swift`.
Do: per § macOS; D-10 on the relationship row.
Check: the app builds; AC-5.1, AC-5.2 by hand (the focus ring visible on the relationship row); the Person Gallery still opens the viewer and Back from it is unchanged.

**STEP-8 — Docs and version**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj` (all four `MARKETING_VERSION`), `.agents/skills/add-workspace-location/SKILL.md` (When-this-applies: scroll and focus stay ephemera except a page's anchor; Step 5 gains a paragraph on `sectionAnchor`, `go(to:from:)`, `anchorTarget(for:)` and `conclusionAnchorRestore`), `docs/deployment-plan/archive/spike-3/navigation-history.md` (a "Section anchor" row beside "List scroll"), `docs/macos-client-patterns.md` ("One sectioned detail page": the Show more focuses through the section's stop; Back restores the opened row), `docs/deployment-plan/spike-16/completed.md`, `docs/deployment-plan/spike-16/deployment-plan.md` (S16-46 row: Status), this plan (status).
Do: bump the patch (0.23.3 → 0.23.4 at `f757b45`; the next patch of whatever `VERSION` holds at the branch's base) in all three places in one commit; then the docs per the Definition of done.
Check: `rg -n "0\.23\.4" VERSION core/version.go macos/Provenencia.xcodeproj/project.pbxproj` finds each; `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-46-section-anchor.md` and `python3 scripts/check-plan-docs.py --links .agents/skills/add-workspace-location/SKILL.md docs/macos-client-patterns.md` report no errors.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `macos/ProvenenciaTests/WorkspaceNavigationTests.swift` `sectionAnchorStampsTheEntryBeingLeft` *(new)* | Attached navigation; go Person p1; `go(to: p2, from: .init(part: .family, id: "r-0-p2"))` → p2 has nil; Back → p1 has that anchor; Forward, Back → still; go to the Places list by the sidebar, Back → p1 keeps it; a second navigation on the same file reloads it with the anchor | AC-2.5, AC-6.1, D-2 |
| T-2 | Swift | `WorkspaceNavigationTests.swift` `sectionAnchorIsNotIdentityAndDecodesLeniently` *(new)* | Two Person locations differing only in `sectionAnchor` are `==`; encode → decode keeps `.family`/`"x"`/nil row and `.timeline`/`"e-p"`/`"e"`; `{"section":"persons","entityId":"p1"}`, `…"sectionAnchor":{"part":"zzz","id":"x"}` and `…"sectionAnchor":"family:x"` decode with nil and the rest of the entry intact | AC-6.2, D-1 |
| T-3 | Swift | `WorkspaceNavigationTests.swift` `withPageSectionClearsTheSectionAnchor` *(new)* | A Family location with an anchor `.withPageSection(.timeline)` → nil | AC-6.3, D-3 |
| T-4 | Swift | `WorkspaceNavigationTests.swift` `sectionAnchorSkipsACoalescedVisit` *(new)* | On p1, `go(to: p1, from: …)` → no push, p1's anchor stays nil | D-2 |
| T-6 | Swift | `macos/ProvenenciaTests/PersonFamilyContentTests.swift` `anchorResolvesToTheTileOrItsFold` *(new)* | A partner group with 35 children: child 3 → that tile; child 33 → `moreID(.children(0))`; 32 units: unit 31's partner and one of its children → `moreID(.partners)`; a one-parent unit's hidden child → `moreID(.children(i))`; a hidden parent set's second partner → `moreID(.parentSets)`; a hidden sibling → `moreID(.siblings)`; an unknown person → nil | AC-1.1, AC-1.2, AC-1.3 |
| T-7 | Swift | `macos/ProvenenciaTests/PersonTimelineContentTests.swift` `anchorResolvesToTheRowCardOrFold` *(new)* | 60 dated events: event 30 → the event id · same; event 55 → `"more.dated"`; a card on event 12 → the card · event 12; at Regular the 7th of 8 cards → `"more.<event>"` · the event; at Wide the same anchor → the card; a card on event 55 → `"more.dated"`; an undated event past 50 → `"more.undated"`; a recorded birth's row → its event id; an unknown event → nil | AC-2.1 – AC-2.4, D-9 |
| T-8 | Swift | `macos/ProvenenciaTests/PersonSourcesContentTests.swift` `anchorResolvesToTheTitleLineOrFold` *(new)* | `.sourceTitle` s3 shown → `.title(sourceID: "s3")` · `"s3"`; a Source past 50 → `.more(.rows)` · `"more.rows"`; `.sourceLine` c2 (row s1) shown → `.graph(claimID: "c2")` · `"c2"`; the 7th of 8 lines → `.more(.lines(sourceID: "s1"))` · `"more.s1"`; a line whose Source is past 50 → `.more(.rows)`; an unknown Source → nil | AC-3.1 – AC-3.3 |
| T-9 | Swift | `macos/ProvenenciaTests/ConclusionAnchorRestoreTests.swift` `anchorPartsAreFrozen` *(new)* | `ConclusionSectionAnchor.Part.allCases.map(\.rawValue)` equals the eight names in D-1, in order | D-1 |
| T-10 | Swift | `ConclusionAnchorRestoreTests.swift` `detailRowAnchorNeedsAnOpensRow` *(new)* | Rows birth (opens an Event) and name (no opens): `.detailRow` birth → `"birth"`; name → nil; an unknown id → nil; a `.family` anchor → nil | AC-4.1, AC-4.2, D-12 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `WorkspaceNavigationTests` and the three content suites, and the Show more's keyboard paths (STEP-2's manual check). The fold-sized ACs (AC-1.2, AC-2.3, AC-2.4, AC-3.3) are proven by T-6 – T-8; the app shows the focus and scroll that the tests cannot.

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
- [ ] Domain doc updated if a rule in docs/*.md changed: navigation-history.md (Section anchor row), macos-client-patterns.md (sectioned page), add-workspace-location (Step 5)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

The sweep's old name is `hasKeyboard` in `ConclusionShowMoreRow`. There is no brief and no new copy; those two lines are checked as not applicable.

## 10. Manual check

On a Mac, in a project with a person who has children and a Timeline with participants (any family the reviewer has; the fold cases are covered by T-6 – T-8), at Regular and at Wide.

1. Person → Family → open a child's tile. Back: that tile is in view with the focus ring (AC-1.1). Tab moves on from it; Return opens it again.
2. Timeline → scroll to a row far down → open its title → Back (AC-2.1); Forward, Back (AC-2.5); open a participant card → Back (AC-2.2).
3. Sources → open a Source title → Back (AC-3.1); a graph line → Back (AC-3.2); a diagram node → Back, at Wide and at a width where the diagram stacks (AC-3.4).
4. Vitals → Birth's open arrow → Back (AC-4.1). An Event page → Place arrow → Back (AC-4.2); a picture → Back (AC-5.1). A Place page → a Contains row → Back; the ring is visible (AC-5.2).
5. Repeat step 1, quit (⌘Q), relaunch, Back (AC-6.1). Switch to Timeline: it opens at its top (AC-6.3). Open the person from the omnibar: the page opens at its top (AC-6.4).
6. Open a child's tile, delete the child from the child's page, Back: the Family at its top (AC-1.3).
7. Where the project has a fold (more than 30 tiles, 50 events, 5 or 12 people on an event, 5 record lines), open a row past it and Back: the fold's Show more has the keyboard (AC-1.2, AC-2.3, AC-2.4, AC-3.3).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A restore claims focus before the stop's view exists (Family before its width, Timeline before placement, the diagram after the rows) | `isReady` per site (D-13 for the Timeline); `FocusClaim` writes twice over two turns; the Timeline and Gallery hand through their keeper; the diagram restores from its own host body |
| The page's top reset (`scrollResetKey`) runs after the restore's scroll on a section switch Back | The restore scrolls through a request token, one main-actor turn after the reset's `onChange` |
| Moving focus to the Show more through the section's binding changes the keyboard path the fold had | STEP-2's manual check before any section work |
| The `.plain` relationship row draws no focus ring | STEP-7's check looks for it; a Stop condition below |

**Stop and report if:**

- `PlaceRegistry`'s `viewIdentity` for `.personDetail`, `.eventDetail` or `.placeDetail` is no longer `entityId` (D-6 would then restore once per page, not per arrival).
- A Conclusion page installs a `workspaceLeaveGuard` (D-2 stamps before the guard).
- A focus claim on a restored stop does not land after both `FocusClaim` turns on a mounted section (the stop's view exists and focus is still nil).
- The relationship row shows no focus ring when it has the keyboard (AC-5.2 needs a style change, which is chrome).
- The diagram draws a node whose `links.locations` lacks it, or the reverse.
- A section needs a fold revealed to scroll or focus its anchor (D-9 refuses it).
- `ConclusionShowMoreRow` or `ReconciledValueRow` has another caller at the base.

## 12. Open questions

None.

## 13. PR

**Title:** S16-46 — Back returns to the row you opened in a section
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-46-section-anchor.md`.
