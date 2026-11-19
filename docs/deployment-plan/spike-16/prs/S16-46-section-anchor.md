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

On a Person, Event or Place page, the researcher opens a relative, an event, a Source or a related place from a row, looks at it, and presses Back. Today the page comes back at its top with nothing focused, so a researcher walking a family or a timeline loses their place on every hop (audit P-19). After this PR, Back and Forward put the page's scroll on the row that was opened and give that row the keyboard. The same holds after quitting and relaunching.

**Why now.** Batch 6 took P-19 back from the parked list (user, 2026-11-17), and the working rule fixes its shape: an anchor on the history entry, scroll and focus restored, folds not.

**What stays.** Folds open closed on every visit (S13-16 UX-5): a row that a Show more had revealed is not revealed again; its fold's Show more gets the keyboard instead. A page opened any other way (a link, the omnibar, the sidebar, a section switch) opens at its top as today. The page's reads, its section switcher, the list scroll anchor of the Persons, Events and Places lists, and every view's look are unchanged.

## 2. User stories

**US-1.** As a researcher on a person's Family, when I open a relative's tile and press Back, the Family shows that tile in view with the keyboard on it, so I can go on to the next relative.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Anna's Family shows four children; open the third child's tile (Friedrich), press Back | Anna's Family; Friedrich's tile is scrolled into view and has the focus ring |
| AC-1.2 | A person with 35 children with one partner; Show more, open the 33rd child, press Back | The children fold is closed again (30 tiles); its "Show 5 more" row has the keyboard and is in view |
| AC-1.3 | Open a child's tile; on the child's page, merge or delete that child elsewhere so the tile is gone; press Back | Anna's Family at its top; no tile is focused by the restore |

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
| AC-5.2 | On a Place page, open a row under Contains, press Back | The Place page; that row is in view and has the keyboard |

**US-6.** As a researcher, the place I return to survives history moves and a relaunch, and a page I reach any other way opens at its top.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-6.1 | Do AC-1.1's open, quit the app, relaunch, press Back | As AC-1.1 |
| AC-6.2 | A history file written before this PR (no `sectionAnchor` key) | It loads; Back to a Person page opens it at its top |
| AC-6.3 | Do AC-1.1's open, press Back, then switch Anna's page to Timeline | The Timeline opens at its top; the new entry carries no anchor |
| AC-6.4 | Do AC-1.1's open; then open Anna from the omnibar | Anna's page opens at its top (a new entry) |

## 3. Scope

| In | Covered by |
| --- | --- |
| `WorkspaceLocation.sectionAnchor`: optional, not identity, decodes nil from older files, cleared by `withPageSection` | STEP-1, AC-6.2, AC-6.3 |
| `WorkspaceNavigation.go(to:sectionAnchor:)` stamps the entry being left; `NavigationHistoryStore.stampSectionAnchor` | STEP-1, AC-2.5, AC-6.1 |
| `ConclusionSectionAnchor` (the stored form and its parts), `ConclusionAnchorTarget`, the once-per-mount restore modifier | STEP-2 |
| `ConclusionShowMoreRow` focused through its section's stop, so a restore can focus it | STEP-2, AC-1.2, AC-2.3, AC-2.4, AC-3.3 |
| Family tiles record and restore | STEP-3, US-1 |
| Timeline row titles and participant cards record and restore | STEP-4, US-2 |
| Sources titles, record lines and diagram nodes record and restore | STEP-5, US-3 |
| Field rows' open arrow (Person Vitals, Event and Place Details) record and restore | STEP-6, US-4 |
| Event and Place picture tiles (no viewer) and Place relationship rows record and restore | STEP-7, US-5 |
| `add-workspace-location`, `navigation-history.md`, `macos-client-patterns.md` say how | STEP-8 |

| Out | Home |
| --- | --- |
| Restoring folds (a revealed page stays revealed on Back) | not planned: refused, S13-16 UX-5 and the working rule |
| The Person Gallery: a tile opens the likeness viewer, a sheet, not a place; the viewer's provenance links leave from the sheet | not planned (map scope: "open sheets rather than places") |
| The provenance sheet's Source, Citation and Observation links (Vitals, the Why) | not planned: they leave from a sheet, as the Gallery's viewer does |
| The lifeline's points and caps (they scroll the list; they open nothing) | not planned |
| Restoring the scroll offset of a page whose anchored row is gone | not planned: the rule opens it at its top |
| Section anchors on Source pages, Evidence graphs and other non-Conclusion pages | not planned |
| Persons, Events and Places list scroll (already `listScrollAnchor`) | — (shipped) |

## 4. Current state

Verified at `f757b45`.

| Area | Where | Today |
| --- | --- | --- |
| Location | `macos/App/Features/Workspace/WorkspaceLocation.swift` `WorkspaceLocation` | `listScrollAnchor` is the one non-identity scroll field: in `CodingKeys`, the memberwise `init`, `init(from:)` with `nilIfEmpty`, `withListScrollAnchor(_:)`, and left out of `==`. `withPageSection(_:)` copies every field, `listScrollAnchor` included. No section anchor |
| Navigation | `macos/App/Features/Workspace/WorkspaceNavigation.swift` `WorkspaceNavigation` | `go(to:)` coalesces equal locations, asks `leaveGuard`, then `performGo`, which stamps `pendingListScrollAnchor` on the outgoing entry. `pendingListScrollAnchor` is set by `noteListScroll` and only for list roots. Nothing records which row a page opened |
| History store | `macos/App/Features/Workspace/NavigationHistoryStore.swift` `stampListScrollAnchor(_:)`, `go(to:)` | `stampListScrollAnchor` writes the current entry with no persist; `go(to:)` appends and persists, so a stamp before a push is written with it |
| Destination mount | `macos/App/Features/Workspace/Session/PlaceRegistry.swift` `.personDetail`, `.eventDetail`, `.placeDetail` `viewIdentity` | Each Conclusion page is keyed by `entityId`, so Back to another person's page mounts it fresh; a section switch swaps the section view under the same page (`PersonDetailSections`) |
| Page scroll | `macos/App/DesignSystem/Components/PageColumns/PVPageColumns.swift` `PVPageColumns.scroll` | Owns the page's `ScrollView`; `scrollResetKey` (the open section) scrolls to the top on change. A fresh mount starts at the top |
| Scroll helper | `macos/App/DesignSystem/Components/ScrollRowIntoView/PVScrollRowIntoView.swift` `pvScrollsRowIntoView(_:anchor:animated:...whenRequested:)` | With a request token, scrolls to the row with `.id(row)` on the next main-actor turn. Family, Timeline, Sources and the Gallery each already use it for Show more |
| Show more | `macos/App/Features/Conclusions/ConclusionShowMoreRow.swift` `ConclusionShowMoreRow` | Holds a private `@FocusState hasKeyboard`; the section cannot focus it. Callers: `PersonFamilySection.swift` (1), `PersonTimelineSection.swift` (2), `PersonSourcesSection.swift` (2), `ReconciledValueRow.swift` (1) |
| Family | `macos/App/Features/Conclusions/PersonFamilySection.swift` `PersonFamilySection`, `PersonFamilyDiagram` | `open: (WorkspaceLocation) -> Void` → `navigation.go(to:)`. Focus `String?` = tile id; tiles carry `.id(placed.id)`; Show more rows carry no `.id`. `pvScrollsRowIntoView(scrollTarget, whenRequested: scrollRequest)` on the diagram. Tiles exist only once `width > 0` |
| Family content | `macos/App/Features/Conclusions/PersonFamilyContent.swift` `PersonFamilyContent`, `tileID(column:group:personID:)`, `Fold`, `Inputs` | Tile id is `"<l|r>-<group>-<personID>"` (groups `p<k>`, `s`, `<index>`). Folds: `.parentSets`, `.siblings`, `.partners`, `.children(Int)`, limit 30. Builds tiles only for shown members; keeps no ids of hidden ones |
| Timeline | `macos/App/Features/Conclusions/PersonTimelineSection.swift` `PersonTimelineList` | Focus `String?` = a row's event id or a card id. Items carry `.id(item.id)`; cards do not. Scrolls after placement through `pendingReveal` → `scrollTarget`/`scrollRequest` in `rebuild()` (anchor `.top`). `focusKeeper` keeps focus across width changes |
| Timeline content | `macos/App/Features/Conclusions/PersonTimelineContent.swift` `PersonTimelineContent` | Item ids: event id, `"birth"`/`"death"`, `"undated"`, `"more.dated"`, `"more.undated"`. Card id `participantLinkID(eventId:personId:)` = `"<eventId>-<personId>"`. `datedFoldIDs` holds the dated rows the fold counts; folded rows are never built. Participant fold 5 (Regular) / 12 (Wide) |
| Sources | `macos/App/Features/Conclusions/PersonSourcesSection.swift` `PersonSourcesList`, `PersonSourcesFocus` | Focus cases `.graph(claimID:)`, `.unpromote(claimID:)`, `.node(graphID:)`. The Source title (`PVInkLink`, a `Button`) has no focus case. Lines carry `.id(line.id)`; rows and Show more rows carry none. `pvScrollsRowIntoView` sits on `rows` only, so it cannot reach the diagram |
| Sources content | `macos/App/Features/Conclusions/PersonSourcesContent.swift` `PersonSourcesContent`, `Fold` (`.rows`, `.lines(sourceID:)`), `Inputs` | Row id = Source id; line id = claim id. `rowFold` 50, `lineFold` 5 (fewest hidden 2) |
| Record links | `macos/App/Features/Conclusions/PersonRecordLinksColumn.swift` `PersonRecordLinksColumn`; `PersonRecordLinksContent.locations` | A node opens `links.locations[graphID]`; drawn by the companion host, so it appears after the rows when its read is slower |
| Field rows | `macos/App/Features/Conclusions/ReconciledValueRow.swift` `ReconciledValueRow`, `ConclusionDetailRowsSection` | The open arrow (`PVIconButton`, `model.opens`) calls `navigation.go(to: opens.location)`. Each row has a private `Stop` (`.why`, `.provenance`, `.others`); the arrow has none. `ConclusionDetailRowsSection` draws Vitals (`provenance: .sheet`) and the Event and Place Details; rows carry no `.id` |
| Gallery | `macos/App/Features/Conclusions/ConclusionGallerySection.swift` `ConclusionGallerySection.tileView` | With no `gallery.viewer` (Event, Place) a tile opens `navigation.go(to: tile.location)` (the composer); with one (Person) it opens the viewer. Focus `TileFocus`; `FocusKeeper.hand(.image(id), …)` already hands focus back to a tile after the viewer closes |
| Place relationships | `macos/App/Features/Conclusions/PlaceRelationshipRow.swift` `PlaceRelationshipRow`, `ConclusionDetailRelationshipSection`, `ConclusionDetailRelationship.id` | The row's `Button` navigates itself; no focus state, no `.id`. A relationship is in one section only (Part of, Contains, Succession read different rows; self-loops are refused since S16-36) |
| Tests | `macos/ProvenenciaTests/WorkspaceNavigationTests.swift` `leavingAListStampsTheOutgoingEntry`, `listScrollAnchorRoundTrips`, `legacyHistoryMissingListScrollAnchorDecodesAsNil`, `pageSectionPushAndRestore`; `PersonFamilyContentTests.swift`, `PersonTimelineContentTests.swift`, `PersonSourcesContentTests.swift`, `ConclusionFoldTests.swift` | The list anchor's stamp, round trip and legacy decode; the contents' folds. Nothing about a page's anchor |

**Precedent.** The list scroll anchor (`listScrollAnchor`, S15-48 D-10 and its tests above): a non-identity field on the entry, written when leaving, `nilIfEmpty`, decodes nil from older files, stamped by the store with no persist. Copy its field, coding and tests. Do not copy `pendingListScrollAnchor`: a section's anchor is known at the open, not reported while scrolling (D-2). For the focus hand-back, copy `ConclusionGallerySection`'s `FocusKeeper.hand` after the viewer closes, and the Show more's `scrollTarget`/`scrollRequest` pair each section already has.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `WorkspaceLocation.sectionAnchor: String?` *(new)*. It holds `ConclusionSectionAnchor.stored`: `"<part>:<id>"`. Not in `==`; coded under the key `sectionAnchor`; `nilIfEmpty` in both inits. The part raw values are frozen, as `ConclusionPageSection`'s are: they are written to history files | One string mirrors `listScrollAnchor`, and the Workspace layer stays free of Conclusion types. The part names which part of the page owns the id, since an Event or Place page draws several parts under one location | A typed enum on `WorkspaceLocation` — the Workspace layer would import `Features/Conclusions` stop types. One anchor per section — the rule keeps one, the last opened |
| D-2 | The anchor is written at the open: `WorkspaceNavigation.go(to:sectionAnchor:)` *(new)*, when `location != currentLocation`, calls `NavigationHistoryStore.stampSectionAnchor(_:)` *(new)* on the current entry, then `go(to:)`, whose push persists both. With no history attached it only calls `go(to:)`. The stamp comes before the leave guard; no Conclusion page installs one | The opened row is known only at the open. The stamp-then-push writes the file once | A pending value stamped on every leave, like `pendingListScrollAnchor` — Back or a sidebar click would then write an anchor for a row nobody opened |
| D-3 | `withPageSection(_:)` sets `sectionAnchor` to nil on its copy | A section switch is a new place, opened at its top (AC-6.3) | Keeping it — the next section would try to restore the last section's id |
| D-4 | `ConclusionSectionAnchor` *(new)* in `macos/App/Features/Conclusions/ConclusionSectionAnchor.swift` *(new)*: `enum Part: String { case family, timeline, sources, recordLinks, detailRow, picture, related }`, `let part`, `let id`, `var stored: String`, `init(part:id:)`, `init?(stored: String?)` (splits at the first `:`; nil for nil, no `:`, an empty id or an unknown part), and `static func id(_ part: Part, in location: WorkspaceLocation) -> String?`. The same file holds `struct ConclusionAnchorTarget<Stop: Hashable>: Equatable { var stop: Stop; var scrollID: String }`, the extension `WorkspaceNavigation.go(to:from:)` that takes a `ConclusionSectionAnchor`, and the restore modifier of D-5 | One home for the stored form, so a site never builds the string by hand | A string prefix per call site |
| D-5 | Restore runs once per mount: `View.conclusionAnchorRestore(_ part:, isReady:, restore: (String) -> Void)` *(new)*, a modifier with `@State didRestore`. On `onAppear` and on `isReady` turning true, if not yet done and `isReady`: mark done, then call `restore` with the location's id for `part`, when there is one. It reads `WorkspaceNavigation` from the environment | Each Conclusion page mounts per entity, and each section per switch, so once per mount is once per arrival. A reload later never moves the keyboard | Restoring on every `currentLocation` change — a reload or a coalesced visit would steal focus |
| D-6 | Each section's content resolves its anchor while it is built: `Inputs` gains `anchor: String?`, the content's `init` gains `anchor: String? = nil`, and the content exposes `let anchorTarget: ConclusionAnchorTarget<Stop>?`. The lookup is exact and touches one list (§ Edges) | One lookup, in the pure type the tests already reach; the hidden members are in hand only while building | Keeping hidden ids or the raw read on the content for a later lookup — more memory on every build for a once-per-mount question |
| D-7 | `ConclusionShowMoreRow` takes `let stop: Focus` and focuses through the section's binding: `.focused(focus, equals: stop)`, `pvActivatesOnReturn(when: focus.wrappedValue == stop, press)`, and `press` reads `focus.wrappedValue == stop` before `expand()`. The private `hasKeyboard` goes. All six callers pass a stop (§ macOS) | A restore must be able to focus a Show more (the rule), and one focus path beats a second mode | An optional `stop` with the private state kept for nil — two ways to focus one control |
| D-8 | Stops and scroll ids per part, written at the open and resolved on restore: see the table in § macOS | — | — |
| D-9 | Folded: the stop is the fold's Show more. Gone: no restore; the page keeps its top. Folds are never revealed by a restore | The working rule | Revealing the fold through the anchor's page, as a lifeline click does — refused (S13-16 UX-5) |
| D-10 | Scroll: each site sets its existing `scrollTarget` to the target's `scrollID` and bumps `scrollRequest`; the Timeline sets `pendingReveal` instead, so it scrolls once the item is placed (`rebuild()`), with its existing `.top` anchor. Focus: `FocusClaim.claim` on the section's binding; the Gallery uses `FocusKeeper.hand(.image(id), …)` as it does after the viewer | Reuses each section's one scroll path and the one focus writer | A new scroll mechanism on `PVPageColumns` |
| D-11 | Sources: the scroll modifier moves from `rows` to the `ConclusionPinnedSideColumn` in `PersonSourcesList.body`, the diagram column carries `.id(PersonSourcesList.diagramScrollID)` *(new)*, `"diagram"`, and node anchors use the part `.recordLinks`, restored from inside the diagram host's body against `PersonRecordLinksContent.locations` | The node is drawn by the companion read, which can land after the rows; its restore waits for its own content. The proxy must reach the diagram when it stacks under the rows | Resolving a node against the claims — it would claim a node the diagram has not drawn yet |
| D-12 | The field rows' arrow: `ReconciledValueRow.Stop` gains `.open`, the arrow gets `.focused($focusedStop, equals: .open)`, and the row takes `claimsOpenFocus: Bool` (default false), claiming `.open` with `FocusClaim` on appear and when it turns true. `ConclusionDetailRowsSection` resolves through `static func anchorTarget(rows:id:) -> String?` *(new)*: the id of a row that has `opens`, else nil | The arrow is the only place a field row opens; its focus belongs to its row | A section-wide focus binding over every row's stops — rewires all three disclosures for one stop |
| D-13 | Coverage is § Scope's In: every row or tile on a Person, Event or Place page that opens a place directly | The map row names Person, Event and Place pages; Vitals' arrow opens a place, so the map's Vitals exception does not apply | Person sections only — Event and Place Details share `ConclusionDetailRowsSection` with Vitals, so leaving them out would need a gate |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `WorkspaceLocation.sectionAnchor` *(new)* | field | `WorkspaceLocation.listScrollAnchor` | Copied shape; `listScrollAnchor` is defined for list roots only (`isListRoot` guards), and a page is not one |
| `WorkspaceNavigation.go(to:sectionAnchor:)` *(new)* | func | `WorkspaceNavigation.go(to:)`, `noteListScroll` | Extends `go(to:)` with one stamp; `noteListScroll` reports while scrolling, the wrong moment (D-2) |
| `NavigationHistoryStore.stampSectionAnchor(_:)` *(new)* | func | `stampListScrollAnchor(_:)` | Same body without the list-root guard; the list guard is that function's point |
| `ConclusionSectionAnchor.swift` *(new)*: `ConclusionSectionAnchor`, `ConclusionAnchorTarget`, `conclusionAnchorRestore`, `WorkspaceNavigation.go(to:from:)` | file / types | `ListScrollAnchorModifier` (`WorkspaceNavigation.swift`) | That modifier drives `scrollPosition` over a lazy list of top rows and reports scrolling; a page restores one stop once, through each section's own scroll and focus |
| `anchorTarget` on `PersonFamilyContent`, `PersonTimelineContent`, `PersonSourcesContent` *(new)* | property | `firstRevealed(by:)` on the same types | Same idea (a stop the keyboard goes to), computed in the same pass |
| `PersonFamilyContent.moreID(_:)` *(new)* | func | `PersonFamilyContent.tileID(column:group:personID:)` | Show more had no id; this names it beside the tile id rule |
| `PersonTimelineContent.participantsMoreID(eventId:)` *(new)* | func | the item id `"more.dated"` in `Slot.id` | The participants' Show more is inside a row, not an item |
| `PersonSourcesFocus.title(sourceID:)`, `.more(PersonSourcesContent.Fold)`, `init?(anchorID:)`, `anchorID` *(new)* | cases / func | `PersonSourcesFocus` | Extends the one focus type of the section |
| `ReconciledValueRow.Stop.open`, `claimsOpenFocus` *(new)* | case / param | `ReconciledValueRow.Stop` | Extends the row's own stops |
| `ConclusionDetailRowsSection.anchorTarget(rows:id:)` *(new)* | func | — | Pure lookup so a test reaches it |
| `ConclusionSectionAnchorTests.swift` *(new)* | test file | `WorkspaceNavigationTests.swift` | The anchor's parse rules are Conclusions' own |

Searched: `rg -n "scrollTarget|FocusClaim.claim|FocusKeeper.hand|stampListScrollAnchor|pendingListScrollAnchor" macos/App`.

**Builds on.** The list scroll anchor's field and stamp; `FocusClaim`; `FocusKeeper.hand`; each section's `pvScrollsRowIntoView(scrollTarget, whenRequested: scrollRequest)`; `ConclusionFold.shown`; the section `Inputs` that `session.conclusionContent` keys on.
**Deletes.** `ConclusionShowMoreRow.hasKeyboard` (the private `@FocusState`), replaced by the section's stop.
**Next adds.** A Conclusion kind that adopts sections (Event, Place) gets restore by adding a part and resolving in its content. A later "open from a sheet" anchor (the Gallery viewer) would add a part and one stamp.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| Back/Forward to a Conclusion page entry that carries an anchor | `PersonDetailView`, `EventDetailView`, `PlaceDetailView` and their sections | Resets: the page mounts per `entityId` (`PlaceRegistry` `viewIdentity`) and each section per switch, so `didRestore` is fresh. Missing: a gone id resolves to nil, the page stays at its top (AC-1.3). State: the page draws as today; only scroll and focus move |
| A history file with a `sectionAnchor` read by this build after the row's entity changed | the same pages | Resolution is by id against what is drawn now, never by position |
| A history file of this build read by an older build | `WorkspaceLocation.init(from:)` | The unknown key is ignored; the older build opens at the top |

### Scale

At the map's Scale (200 events with 10 participants, 20 children in four parent sets, a person in 50 Evidence graphs), and at bar 2's crafted sizes (500 participants on one event, a Source with 10,000 Observations): the stamp writes one string to the entry being left and adds no persist (the push persists). Each content build adds one exact lookup for its anchor: Family compares the anchor with each hidden member's tile id (at most `MaxKinPerRole` 100 per role); the Timeline tests the anchor against each event id and against the one event whose id prefixes a card anchor, whose participants it then scans (at most 500, crafted); Sources compares against each claim id once. With no anchor (`nil`), each lookup is skipped. The restore runs once per mount. No read, cache key or list changes; the contents' memo key gains the anchor, which is constant for a mount.

### Edges

- **Assumptions.** Ids are stable across a reload for the same data: a tile id holds its column, group index and person id, so a removed parent set or partner group shifts the group index and the tile resolves as gone (AC-1.3's case, page top). Event, person and claim ids are fixed-length UUIDs, so a card id `"<eventId>-<personId>"` has one event-id prefix among the person's events; the match is still checked exactly against `participantLinkID` (T-7 "a card of a person no longer on the event is gone").
- **Neighbors.** An anchor on the last shown tile of a fold resolves to the tile; on the first hidden one to the fold's Show more (T-6, T-7). At Regular a 6th card is behind the participants' Show more and at Wide it is shown, so the same anchor lands on the card at Wide (T-7). A recorded birth row (a marker with a row) resolves to its event id like any row (T-7). A placeholder marker, the Undated heading and lifeline points open nothing and are never anchors.
- **Removed inputs.** A row whose entity was deleted or merged since the open: gone, no restore (T-6, T-7, T-8). A Source whose record line was unpromoted: the `"graph:<claimID>"` anchor is gone. A field row that lost its `opens` (the Event was un-promoted): `anchorTarget(rows:id:)` returns nil (T-10).
- **Real data.** None — no table or seed drives the rule.
- **Untrusted size.** The anchor comes from the app's own history file. `init?(stored:)` reads at most the string it is given and splits once; a stored id that matches nothing costs one failed lookup.

### Schema

None — no catalog change.

### Go core

None — Swift only.

### FFI

None — no RPC changes.

### macOS

The anchor is written where the row opens and resolved where the section draws. Every write site calls `navigation.go(to: location, from: ConclusionSectionAnchor(part:id:))`.

| Part | Written by (the open) | Anchor id | Resolves in | Stop when shown · scroll id | Stop when folded · scroll id |
| --- | --- | --- | --- | --- | --- |
| `.family` | `PersonFamilyDiagram` tile tap | the tile id (`placed.id`) | `PersonFamilyContent.anchorTarget` | the tile id · the tile id | `PersonFamilyContent.moreID(fold)` · same; the Show more gets `.id(moreID)` |
| `.timeline` | `PersonTimelineEventRow` title button and `card(_:)` | the row's event id, or the card's id | `PersonTimelineContent.anchorTarget` | the id · the item id holding it (the row's event id) | `"more.dated"` / `"more.undated"` · same (an item); a card behind a shown row's participants fold: `participantsMoreID(eventId:)` (`"more.<eventId>"`) · the row's event id |
| `.sources` | `PersonSourcesRowView.title`, `PersonSourcesLineView` graph link | `"source:<sourceID>"` / `"graph:<claimID>"` (`PersonSourcesFocus.anchorID`) | `PersonSourcesContent.anchorTarget` | `.title(sourceID:)` · the Source id (row gets `.id(row.id)`); `.graph(claimID:)` · the claim id | `.more(.rows)` · `"more.rows"`; `.more(.lines(sourceID:))` · `"more.<sourceID>"` (both Show more rows get the `.id`) |
| `.recordLinks` | the diagram's `open:` in `PersonSourcesList.diagram` | the graph id | `links.locations[id] != nil` in the diagram host body | `.node(graphID:)` · `PersonSourcesList.diagramScrollID` | — (a graph not drawn is gone) |
| `.detailRow` | `ReconciledValueRow` open arrow | `model.id` | `ConclusionDetailRowsSection.anchorTarget(rows:id:)` | `.open` on that row (D-12) · `model.id` (each row gets `.id(row.id)`) | — (field rows do not fold) |
| `.picture` | `ConclusionGallerySection.tileView` when `gallery.viewer == nil` | `tile.id` | `gallery.tiles.contains` | `.image(id)` through `FocusKeeper.hand` · the tile id (existing `scroll`) | — |
| `.related` | `PlaceRelationshipRow` button | `ConclusionDetailRelationship.id` (passed in as `anchorID`) | `ConclusionDetailRelationshipSection`: `section.relationships.contains` | a new `@FocusState focused: String?` on the section, `.focused($focused, equals: row.id)` · `row.id` (each row gets `.id`) | — (an omitted Contains row is gone) |

`isReady` per site: Family `width > 0` on `PersonFamilyDiagram`; Timeline, Sources rows, field rows, Gallery and relationships `true` (their view exists only with content); the record links `true` inside the companion host's body.

`ConclusionShowMoreRow` stops (D-7): Family `PersonFamilyContent.moreID(more.fold)`; Timeline dated/undated `item.id` (`"more.dated"`, `"more.undated"`), participants `PersonTimelineContent.participantsMoreID(eventId: row.id)`; Sources lines `.more(.lines(sourceID: row.id))`, rows `.more(.rows)`; `ReconciledValueRow` `Stop.more` *(new)*. `PersonFamilyContent.moreID`: `.parentSets` → `"more-parentSets"`, `.siblings` → `"more-siblings"`, `.partners` → `"more-partners"`, `.children(i)` → `"more-children-<i>"`; they cannot collide with tile ids, which start `l-` or `r-`.

The `open` closures change shape: `PersonFamilyDiagram.open` and `PersonTimelineList.open` become `(WorkspaceLocation, String) -> Void` (the second argument the anchor id); `PersonSourcesList.open` stays `(WorkspaceLocation) -> Void` for the line and title call sites and gains `openFrom: (WorkspaceLocation, PersonSourcesFocus) -> Void`; previews pass `{ _, _ in }`.

States: no loading, empty or error state changes; a section that failed or is empty never restores. Accessibility: the focus move is the announcement; no new string. Keyboard: the restored stop is the one Tab already reaches.

### Strings

None — no copy changes, and no action changes what it covers.

## 7. Steps

**STEP-1 — The anchor on the entry**
Files: `macos/App/Features/Workspace/WorkspaceLocation.swift`, `macos/App/Features/Workspace/WorkspaceNavigation.swift`, `macos/App/Features/Workspace/NavigationHistoryStore.swift`, `macos/ProvenenciaTests/WorkspaceNavigationTests.swift`. Skill: `add-workspace-location`, `add-swift-test`.
Do: D-1, D-2, D-3. Add `sectionAnchor` beside `listScrollAnchor` in the field list, `CodingKeys`, both inits and the `==` doc comment (not in `==`). Add `stampSectionAnchor(_:)` to the store and `go(to:sectionAnchor:)` to navigation. Write T-1 – T-4.
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/WorkspaceNavigationTests` passes.

**STEP-2 — One anchor type, one restore, Show more by stop**
Files: `macos/App/Features/Conclusions/ConclusionSectionAnchor.swift` *(new)*, `macos/App/Features/Conclusions/ConclusionShowMoreRow.swift`, the six callers (`PersonFamilySection.swift`, `PersonTimelineSection.swift` ×2, `PersonSourcesSection.swift` ×2, `ReconciledValueRow.swift`), `macos/ProvenenciaTests/ConclusionSectionAnchorTests.swift` *(new)*. Skill: `add-ui-component`, `add-swift-test`.
Do: D-4, D-5, D-7. Give each caller its stop (§ macOS); `PersonSourcesFocus` gains `.more(PersonSourcesContent.Fold)` here and `ReconciledValueRow.Stop` gains `.more`. Write T-5.
Check: the app builds; T-5 passes; with the keyboard, each Show more on a Person page still reveals a page and moves focus to its first item (Family, Timeline dated and participants, Sources rows and lines, a field row with more than 21 lines).

**STEP-3 — Family**
Files: `PersonFamilyContent.swift`, `PersonFamilySection.swift`, `PersonFamilyPreviewData.swift`, `macos/ProvenenciaTests/PersonFamilyContentTests.swift`.
Do: `Inputs.anchor`, `init(…, anchor:)`, `anchorTarget`, `moreID(_:)`; while folding each list, test the anchor against the shown tiles' ids and, for the hidden members, their would-be tile ids (`tileID` with the group they would have). `PersonFamilySection` passes `ConclusionSectionAnchor.id(.family, in: navigation.currentLocation)` and writes through `go(to:from:)`. `PersonFamilyDiagram`: the Show more gets `.id(moreID)`; `.conclusionAnchorRestore(.family, isReady: width > 0)` sets `scrollTarget`, bumps `scrollRequest`, and claims `focused`. Write T-6.
Check: T-6 passes; AC-1.1 and AC-1.2 by hand.

**STEP-4 — Timeline**
Files: `PersonTimelineContent.swift`, `PersonTimelineSection.swift`, `macos/ProvenenciaTests/PersonTimelineContentTests.swift`.
Do: `Inputs.anchor`, `init(…, anchor:)`, `anchorTarget`, `participantsMoreID(eventId:)`, resolved per § Edges and the table. The participants' Show more gets `.focused` through its stop (STEP-2). `PersonTimelineList.open` takes the anchor id; `.conclusionAnchorRestore(.timeline, isReady: true)` sets `pendingReveal` to `scrollID` (and calls `rebuild()` so a measured item scrolls at once) and claims `focused`. Write T-7.
Check: T-7 passes; AC-2.1 – AC-2.5 by hand.

**STEP-5 — Sources and the record links**
Files: `PersonSourcesContent.swift`, `PersonSourcesSection.swift`, `macos/ProvenenciaTests/PersonSourcesContentTests.swift`.
Do: `PersonSourcesFocus.title(sourceID:)`, `anchorID`, `init?(anchorID:)`; `Inputs.anchor`, `init(…, anchor:)`, `anchorTarget`. The title link gets `.focused(focused, equals: .title(sourceID: row.id))`; rows get `.id(row.id)`; Show more rows get `"more.rows"` / `"more.<sourceID>"`. D-11: move the scroll modifier, add `diagramScrollID`, restore `.recordLinks` in the diagram host body. Write T-8, T-9.
Check: T-8 and T-9 pass; AC-3.1 – AC-3.4 by hand, AC-3.4 at a width where the diagram stacks.

**STEP-6 — Field rows**
Files: `macos/App/Features/Conclusions/ReconciledValueRow.swift`, `macos/ProvenenciaTests/ConclusionSectionAnchorTests.swift` *(new)*, from STEP-2.
Do: D-12. `ConclusionDetailRowsSection` gets `scrollTarget`/`scrollRequest`, `.id(row.id)` on each row, `pvScrollsRowIntoView(scrollTarget, whenRequested: scrollRequest)` on its stack, and `.conclusionAnchorRestore(.detailRow, isReady: true)`. The arrow writes `.detailRow`. Write T-10.
Check: T-10 passes; AC-4.1, AC-4.2 by hand.

**STEP-7 — Pictures and related places**
Files: `macos/App/Features/Conclusions/ConclusionGallerySection.swift`, `macos/App/Features/Conclusions/PlaceRelationshipRow.swift`.
Do: the Gallery's no-viewer open writes `.picture`; `.conclusionAnchorRestore(.picture, isReady: true)` hands `.image(id)` through `FocusKeeper.hand` when `gallery.tiles` has it. `PlaceRelationshipRow` takes `anchorID: String` and writes `.related`; `ConclusionDetailRelationshipSection` gets `@FocusState focused: String?`, a scroll target, `.id(row.id)` and `.focused` on each row, and `.conclusionAnchorRestore(.related, isReady: true)`.
Check: the app builds; AC-5.1, AC-5.2 by hand; the Person Gallery still opens the viewer and Back from it is unchanged.

**STEP-8 — Docs and version**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj` (every `MARKETING_VERSION`), `.agents/skills/add-workspace-location/SKILL.md` (When-this-applies: scroll and focus stay ephemera except a page's anchor; Step 5 gains a paragraph on `sectionAnchor`, `go(to:from:)` and `conclusionAnchorRestore`), `docs/deployment-plan/archive/spike-3/navigation-history.md` (a "Section anchor" row beside "List scroll"), `docs/macos-client-patterns.md` ("One sectioned detail page": the Show more focuses through the section's stop; Back restores the opened row), `docs/deployment-plan/spike-16/completed.md`, `docs/deployment-plan/spike-16/deployment-plan.md` (map row), this plan (status).
Do: bump the patch (0.23.3 → 0.23.4 at `f757b45`; the next patch of whatever `VERSION` holds at the branch's base) in all three places in one commit; then the docs per the Definition of done.
Check: `rg -n "0\.23\.4" VERSION core/version.go macos/Provenencia.xcodeproj/project.pbxproj` finds each; `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-46-section-anchor.md` and `python3 scripts/check-plan-docs.py --links .agents/skills/add-workspace-location/SKILL.md docs/macos-client-patterns.md` report no errors.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `macos/ProvenenciaTests/WorkspaceNavigationTests.swift` `sectionAnchorStampsTheEntryBeingLeft` *(new)* | Attached navigation; go Person p1 (Family); `go(to: p2, sectionAnchor: "family:r-0-p2")` → current p2 has nil; Back → p1 has `"family:r-0-p2"`; Forward, Back → still; a second navigation on the same file reloads it with the anchor | AC-2.5, AC-6.1, D-2 |
| T-2 | Swift | `WorkspaceNavigationTests.swift` `sectionAnchorIsNotIdentityAndRoundTrips` *(new)* | Two Person locations that differ only in `sectionAnchor` are `==`; encode → decode keeps `"family:x"`; `{"section":"persons","entityId":"p1"}` decodes with nil | AC-6.2, D-1 |
| T-3 | Swift | `WorkspaceNavigationTests.swift` `withPageSectionClearsTheSectionAnchor` *(new)* | A Family location with an anchor `.withPageSection(.timeline)` → nil | AC-6.3, D-3 |
| T-4 | Swift | `WorkspaceNavigationTests.swift` `sectionAnchorSkipsACoalescedVisit` *(new)* | On p1, `go(to: p1, sectionAnchor: "family:x")` → no push, p1's anchor stays nil | D-2 |
| T-5 | Swift | `macos/ProvenenciaTests/ConclusionSectionAnchorTests.swift` `storedFormParses` *(new)* | `"family:r-0-p2"` → `.family`, `"r-0-p2"`; `"sources:graph:c1"` → `.sources`, `"graph:c1"`; `"zzz:x"`, `"family:"`, `"family"`, `""`, nil → nil; `stored` round-trips each part | D-4 |
| T-6 | Swift | `macos/ProvenenciaTests/PersonFamilyContentTests.swift` `anchorResolvesToTheTileOrItsFold` *(new)* | A partner group with 35 children: anchor on child 3's tile → that tile, scroll id the same; on child 33 → `moreID(.children(0))`; 31 partner groups, anchor on group 31's partner → `moreID(.partners)`; an unknown person id → nil; nil anchor → nil | AC-1.1, AC-1.2, AC-1.3 |
| T-7 | Swift | `macos/ProvenenciaTests/PersonTimelineContentTests.swift` `anchorResolvesToTheRowCardOrFold` *(new)* | 60 dated events: anchor on event 30 → stop and scroll the event id; on event 55 → `"more.dated"`; a card on event 12 → the card, scroll event 12; at Regular, the 7th of 8 cards → `"more.<event>"`, scroll the event; at Wide the same anchor → the card; a card on event 55 → `"more.dated"`; an undated event past 50 → `"more.undated"`; a recorded birth's row → its event id; a card of a person no longer on the event → nil | AC-2.1 – AC-2.4, D-9 |
| T-8 | Swift | `macos/ProvenenciaTests/PersonSourcesContentTests.swift` `anchorResolvesToTheTitleLineOrFold` *(new)* | `"source:s3"` shown → `.title(sourceID: "s3")`, scroll `"s3"`; a Source past 50 → `.more(.rows)`, `"more.rows"`; `"graph:c2"` shown → `.graph(claimID: "c2")`, `"c2"`; the 7th of 8 lines → `.more(.lines(sourceID:))`, `"more.<source>"`; a line of a Source past 50 → `.more(.rows)`; an unknown claim → nil | AC-3.1 – AC-3.3 |
| T-9 | Swift | `PersonSourcesContentTests.swift` `focusAnchorIDRoundTrips` *(new)* | `.graph(claimID: "c1")` ↔ `"graph:c1"`, `.title(sourceID: "s1")` ↔ `"source:s1"`; `.unpromote`, `.node`, `.more` have no anchor id; `"x:1"` → nil | D-8 |
| T-10 | Swift | `macos/ProvenenciaTests/ConclusionSectionAnchorTests.swift` `detailRowAnchorNeedsAnOpensRow` *(new)* | Rows birth (opens an Event) and name (no opens): `"birth"` → `"birth"`; `"name"` → nil; `"gone"` → nil | AC-4.1, AC-4.2, D-12 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `WorkspaceNavigationTests`, `PersonFamilyContentTests`, `PersonTimelineContentTests`, `PersonSourcesContentTests` (the content inits gain a defaulted parameter), and the Show more's keyboard paths (STEP-2's manual check).

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

Use a project with a person who has four children with one partner and a Timeline of at least 30 events (the dogfood project's Johann Weber family, or any family built to that shape), at Regular and at Wide.

1. Person → Family → open the third child's tile. Back: that tile is in view and has the focus ring (AC-1.1). Press Tab: focus moves on from that tile.
2. On a person with more than 30 children, Show more, open a child past 30, Back: the fold is closed and its Show more has the keyboard (AC-1.2).
3. Timeline → scroll to the 30th row → open its title → Back (AC-2.1); Forward, Back (AC-2.5); open a participant card → Back (AC-2.2). At Regular, a row with more than 5 people: Show more, open the 7th, Back (AC-2.3).
4. Sources → open a Source title → Back (AC-3.1); a graph line → Back (AC-3.2); a diagram node → Back, at Wide and at a width where the diagram stacks (AC-3.4).
5. Vitals → Birth's open arrow → Back (AC-4.1). An Event page → Place arrow → Back (AC-4.2); a picture → Back (AC-5.1). A Place page → a Contains row → Back (AC-5.2).
6. Repeat step 1, quit (⌘Q), relaunch, Back (AC-6.1). Switch Anna to Timeline: it opens at its top (AC-6.3). Open Anna from the omnibar: her page opens at its top (AC-6.4).
7. On the child's page from step 1, delete or merge the child, then Back: Anna's Family at its top (AC-1.3).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A restore claims focus before the stop's view exists (Family before its width, Timeline before placement, the diagram after the rows) | `isReady` per site; the Timeline scrolls through `pendingReveal`; `FocusClaim` writes twice over two turns; the diagram restores from its own host body |
| The page's top reset (`scrollResetKey`) runs after the restore's scroll on a section switch Back | The restore scrolls through a request token, one main-actor turn later than the reset's `onChange` |
| Moving focus to the Show more through the section's binding changes the keyboard path the fold had | STEP-2's manual check before any section work |
| `FocusKeeper` in the Timeline treats `"more.<id>"` as not shown and pulls focus elsewhere | `lost` only falls back for a stop with a fallback; `row(holdingCard:)` returns nil for a Show more id |

**Stop and report if:**

- `PlaceRegistry`'s `viewIdentity` for `.personDetail`, `.eventDetail` or `.placeDetail` is no longer `entityId`, so a page does not remount per entity (D-5 then restores once per page, not per arrival).
- A Conclusion page installs a `workspaceLeaveGuard` (D-2 stamps before the guard).
- A focus claim on a restored stop does not land after both `FocusClaim` turns on a mounted section (measured: the stop's view exists and focus is still nil); D-10 then needs another writer.
- The diagram's companion read draws a node whose `links.locations` lacks it, or the reverse.
- A section needs a fold revealed to scroll or focus its anchor (D-9 refuses it).
- `ConclusionShowMoreRow` has a seventh caller at the base.

## 12. Open questions

None.

## 13. PR

**Title:** S16-46 — Back returns to the row you opened in a section
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-46-section-anchor.md`.
