# Review — S16-66 The Sources list is a native outline list

**Verdict:** Fits with changes — Not ready (round 1, on the draft; every blocker Fixed). Round 2 runs once the S16-D12 board is agreed and §12 is answered.
**Rounds:** 1. **Reviewers:** maintainability (opus), executability (sonnet)

## To user
- Q-5: a collapsed Source whose graphs mix Promoted and Not started, none In progress. Recommendation: `8 graphs · 5 promoted`.
- Q-6 (from M-9): `PVListPage`'s layer. The brief says Recipe; the review suggests a component beside `PVListPageHeader`. Recommendation: the component.
- Q-1 – Q-4 are the board's (graph row height and lines, graph row separators, SO-W1, the menu separator and the graph-list Callout's placement).

## Writer's own calls
- The kit's native list body (`PVListBody`) split from `PVList`, rows owning their own height, a leading slot on `PVListRow`.
- Expanded and collapsed held on `WorkspaceSession` (`expandedSourceIDs`), not in history or the settings file.
- Flat rows with raw entity ids (old history anchors still resolve), built once per change through a derived value.
- Back to a graph in a collapsed Source expands it through a `reveal` hook on `ListSelectionAnchorModifier`.
- The closed summary rule (D-17) and its copy; "Show/Hide evidence graphs"; menu "Open" / "Open <name>".
- → and ← and a two-height list ship with their fallbacks recorded, never worked around with an `NSEvent` monitor.
- The updated column icon becomes 14 pt (as Persons; it was 12 on today's second line).

## Round 1

### M-1 · blocker · The row menu invents a second action-menu item model
**Answer:** Fixed — D-1's menu slot takes `[[PVActionMenuItem]]` sections; D-16 builds them; T-13 compares title and enabled pairs; the bent-rule line says the native menu presents the same items.

### M-2 · blocker · Back's reveal is a page-level second anchor-and-scroll path
**Answer:** Fixed — `ListSelectionAnchorModifier` gains a `reveal` hook through the pure `ListAnchor.settle` (D-9, T-6); `rowIDs` stays the drawn rows; `PVListBody` scrolls to a selection whose row appears late (D-1). `reachableIDs`, `revealRequest` and the page's second scroll modifier are gone.

### M-3 · major · "Open" names both expand and navigate
**Answer:** Fixed — `expandedSourceIDs`, `setSourcesExpanded(_:_:)`, `Disclosure.collapsed/.expanded`, `SourcesOutlineKeyAction.expand/.collapse`; `PVExpandedState.outlineChevron(isExpanded:)` beside `chevron(isExpanded:)` (D-13, T-18). "Open" means navigate only.

### M-4 · major · The updated column built a second time
**Answer:** Fixed — `PVLastUpdated.column` (D-26) replaces `ConclusionListRow.updatedColumn` and the inline copy; the recipe's doc comment is in STEP-10.

### M-5 · minor · Rows drop their Source, so Decisions look it up again
**Answer:** Fixed — `.graph(graph, source:)`, `.pendingGraph(source:)`, `SourcesOutline.ownerByGraphID`; `location(for:)` moved to `SourcesListNavigation` (D-10, T-14).

### M-6 · minor · The graph row's indent copies `PVListRow`'s geometry
**Answer:** Fixed — `PVListRow.titleLeading(leadingWidth:thumbnailSize:)` (D-2, D-12).

### M-7 · minor · STEP-10 misses docs the deletions make false
**Answer:** Fixed — the kit-layering focus-ring entry, `PVLastUpdated`'s comment, `NotStartedReading`'s and `PublishedDate`'s comments are named in STEP-10.

### M-8 · minor · The badge extension moves into the rows file
**Answer:** Fixed — `SourcesEvidenceStatus+Badge.swift` (D-27).

### M-9 · minor · `PVListPage` sits in Recipes
**Answer:** To user (Q-6) — the brief's inventory placed it; `loadingArea` takes `detailWidth` either way (D-3).

### X-1 · blocker · Collapsing can reopen straight away
**Answer:** Fixed — D-13, D-14 and D-15 select the Source before collapsing; the reveal only runs for an anchor that is not drawn (D-9).

### X-2 · major · Row accessibility has no owner
**Answer:** Fixed — `PVListBody` applies none; each row view applies its own (D-1, D-12, STEP-4).

### X-3 · major · `rows`' `graphs` parameter undefined
**Answer:** Fixed — `(String) -> QueryRead<[CatalogEvidenceGraph]>`, the derived build shown in D-5, the test input in T-3; a debug undeclared-read failure is a stop condition.

### X-4 · major · A Source with zero graphs gets a permanent pending row
**Answer:** Declined — a Source cannot reach zero graphs: `core/database/evidencegraphs/evidencegraphs.go` `ErrLastGraph` ("a Source keeps at least one graph"), enforced by `deleteimpact.GateLastGraph`. Cited in §6 Edges.

### X-5 · major · `captionBand` sweep hits `PersonFamilyLayout`
**Answer:** Fixed — STEP-5 and the DoD search `sources.captionBand`.

### X-6 · major · STEP-5's sweep runs before STEP-10's docs
**Answer:** Fixed — STEP-5 sweeps `macos` only; the DoD sweep excludes `docs/deployment-plan/` history for `ConclusionListFrame`.

### X-7 · minor · `derivedBuilds[...]`
**Answer:** Fixed — `derivedBuildCount(.sourcesOutline)`.

### X-8 · minor · "copy `graphCameras`, but observed"
**Answer:** Fixed — D-7 says the `@ObservationIgnored` attribute is not copied.

### X-9 · major · The secondary line with no summary
**Answer:** Fixed — D-11: dots only between present parts, with four examples.

### X-10 · major · Graph row spacer and guide not computed
**Answer:** Fixed — D-2 and D-12 give the expressions and the height frame.

### X-11 · minor · The updated icon drops from 12 to 14 pt
**Answer:** Fixed — D-11 says so (as Persons; the brief: "as Persons").

### X-12 · minor · Current state: `SourcesModelTests.columns(at:_:)` also uses `SourcesListColumns`
**Answer:** Fixed — in Deletes.

### X-13 · minor · Smaller choices
**Answer:** Fixed — D-16 reads `evidenceGraphsRead(sourceID:)` and every entry, Copy too, selects first; AC-2.11 marks the triangle click as STEP-8's; STEP-8 lists nine numbered lines; STEP-9 takes the next minor after `main`; T-16 is the copy test STEP-5 cites.
