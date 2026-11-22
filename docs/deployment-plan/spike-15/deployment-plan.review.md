# Review — Spike 15 PR map

**Verdict:** Fits with changes (after round 2; slice 8 reviewed in round 3; every To user item answered 2026-11-09). **Rounds:** 3 (round 3 covers slice 8 only, added after round 2). **Reviewers:** maintainability (Opus, fresh context each round, map review per [`review-plan`](../../../.agents/skills/review-plan/SKILL.md)).

## To user

- ~~K-2 · S15-26~~: kept (user, 2026-11-09).
- ~~K-18 · Format edits and the Person page reads~~: closed by the user's call (2026-11-09) to render citations on demand from SQL with nothing cached; see rule "Citations render on demand, from SQL", which replaces the round-1 answer to K-3. To be measured at Scale in S15-16.
- ~~K-16 · `{citation.item}`~~: the item is a graph-level metadata field, `item`, typed once per graph; no per-Citation derivation and no primary-subject toggle in this spike (user, 2026-11-09). Rule "The item is a graph field"; map § 6.5.

- ~~K-25 · S15-30~~: kept (user, 2026-11-09).
- ~~K-30 · The Why accordion~~: option (a); S15-31 moves Event and Place rows to the provenance sheet and deletes the Why before S15-29, with briefs S15-D11 and S15-D12 (user, 2026-11-09).

## Writer's own calls

- **K-4:** `CitationLineDisplay` stays in Swift as the fallback for a type with no format and for its other callers (Gallery captions, the likeness viewer, a denier's Source name), because its page words are localized there. The engine returns no text when a type has no format.
- **K-14:** Spike 15's new Swift query keys go into today's `CatalogQueryKey` enum, and S16-25 converts them with the rest, instead of waiting for S16-25, so slices 1 to 4 run alongside Spike 16 as the user asked.
- **K-15:** Scale additions (3,000 Sources from Spike 16; 60 Artifacts per Source; 100 Subjects per move bundle; 500 Sources per type) are the writer's estimates beside the user's numbers.

## Round 1

### K-1 · blocker · Two client-only PRs would save one user action as several writes
**Answer:** Fixed — rule "Metadata saves with its owner's write"; S15-08 adds values to `CreateArtifactRequest` and the graph create and update requests through the owner form of `CreateAll`; S15-10 and S15-11 send drafts.

### K-2 · blocker · The Swift metadata board only works for a Source, and three PRs would each copy it
**Answer:** To user (preparatory PR); added as S15-26 with rule "One metadata board", pending the user's call.

### K-3 · blocker · Rendered citations would be a second client cache with no update signal, and grouping is built twice
**Answer:** Fixed — rule "Citations render inside the reads that list them" replaces "Render in batches": one Go batch function returns runs, plain text, missing fields and a group key; the S16-30 and S16-13 reads call it; signals named (`ListSourceVocabulary` for format and field edits, Source scopes for values). S15-16, S15-21, S15-22 rescoped.

### K-4 · blocker · Retiring `CitationLineDisplay` is under-scoped, and the fallback would exist in Go and Swift
**Answer:** Fixed — rule "Today's line stays the fallback, in Swift"; S15-21 no longer retires it; S15-16 renders no text for a type without a format. Listed under Writer's own calls.

### K-5 · blocker · The built-in placeholders need one declared table
**Answer:** Fixed — rule "Built-in placeholders are one table"; S15-14 declares it, S15-16 serves it over FFI, S15-17's Insert field reads it.

### K-6 · major · The three levels are one concept with three names
**Answer:** Fixed — rule "One level type"; S15-06 adds the Go `Level` type, Swift enum and parity row.

### K-7 · major · Turning field keys into ids happens in two places, and the stored form is not decided
**Answer:** Fixed — rule "Formats name fields by id" rewritten: S15-14 defines the token and rewrite; one `sourcetypes` key-to-id function used by the type write and Install; delete refusal is a probe over the format columns; the rename Check is replaced (keys stay unrenamable); `add-catalog-delete` gains the text-reference case.

### K-8 · major · The "used by" count is a private copy of the in-use rule
**Answer:** Fixed — S15-08 computes `metadatafields.UsedBy` and the Metadata page count from the delete-impact totals.

### K-9 · major · S15-07 leaves out the functions S15-08 and S15-16 will need
**Answer:** Fixed — S15-07 moves every exported function to the owner form and adds a batch read by owners; `ListWorkspace` reads its fields in one query.

### K-10 · major · Three render RPCs where one would do, and the editor's warnings have no source
**Answer:** Fixed — rule "One render request for previews"; S15-14 returns diagnostics with positions; citation map § 7's bracket question closed.

### K-11 · major · Copy citation already exists; extend it
**Answer:** Fixed — S15-21 and S15-23 use the existing `PVClipboardButton` with one rich-payload write added to `PVClipboardCopyState`; Go returns runs and plain text, not rich text.

### K-12 · major · Sorting by date belongs to one rule
**Answer:** Fixed — rule "One date order"; S15-02 exports the rule and sends a sort key; S15-04 sorts by it in `SourcesModel`.

### K-13 · major · The move should rely on the effects registry
**Answer:** Fixed — rule "A move is the whole bundle" and S15-24 now record per-row changes and let scopes, `Reads`, search and caches follow from the registry; `evidencegraphs.CreateDefault`; S15-24 names the domain docs it updates.

### K-14 · major · Spike 16's map never names Spike 15
**Answer:** Fixed — Spike 16's map gains "Shared with Spike 15"; S15-05 and S15-22 depend on S16-03, S16-06, S16-07; S15-16 depends on S15-05. Ordering the new Swift keys after S16-25: Declined, by the user's instruction (2026-11-09) to run slices 1 to 4 alongside Spike 16; S16-25 converts them instead (Writer's own calls).

### K-15 · major · Scale misses sizes some entries depend on
**Answer:** Fixed — Scale line extended; S15-02, S15-08, S15-15 and S15-24 state their fan-out.

### K-16 · major · S15-16's `{citation.item}` needs a decision first
**Answer:** To user; settled 2026-11-09 (above).

### K-17 · minor · Docs and skills each PR makes false are not named
**Answer:** Fixed — S15-07 (`add-catalog-query` example), S15-15 (`add-catalog-delete` text references), S15-24 (two domain docs), S15-99 (retires the spike's `citation-formats.md` for the new domain doc). Spike 15 adds no cache, so `docs/catalog-caches.md` is untouched.

## Round 2

Fresh reviewer, document plus this log. Round-1 answers: K-2, K-3 (Go shape), K-4, K-5, K-8, K-9, K-10, K-11, K-13, K-14, K-15 hold; K-1, K-6, K-7, K-12, K-17 held only in part and are completed below; K-16 stays with the user.

### K-18 · blocker · A format or field edit has no signal that reaches the Person page's citations
**Answer:** To user (a change to Spike 16's S16-24 and S16-25 scope), with the recommendation above. The rule "Citations render inside the reads that list them" now says the refresh is open instead of claiming it works.

### K-19 · blocker · The graph form's one write cannot go through `CreateAll` on an existing graph
**Answer:** Fixed — rule "Metadata saves with its owner's write": drafts save through `sourcemetadata.Apply(tx, owner, draft)`, added in S15-07, with `CreateAll` as its empty-owner case; S15-08 wires it.

### K-20 · blocker · `Level` has no named home, and the format engine starts before it exists
**Answer:** Fixed — rule "One level type": `Level` lives in `core/vocabkey`; S15-06 adds it; S15-07 and S15-14 depend on S15-06 (map row, slice note, dependency graph).

### K-21 · blocker · Two binding rules contradict each other on `CitationLineDisplay`
**Answer:** Fixed — the sentence is gone from "One engine, in Go"; the citation map's § 6.2 row and the older `citation-formats.md` "Formatter" row now say it stays as the fallback.

### K-22 · blocker · The key-to-id lookup is put in `sourcetypes`
**Answer:** Fixed — `metadatafields.ResolveKeysTx(tx, keys, preferOrigin)` beside `lookupTx`, called by the `sourcetypes` format write and `sourcevocab.Install` (rule and S15-15, S15-20).

### K-23 · blocker · The shared date order would be exported from the Conclusion summary composer
**Answer:** Fixed — rule "One date order": the rule moves to `core/valuecompare` beside `DateEnds`, called by `conclusionsummaries` and `sources` (S15-02).

### Smaller round-2 notes
- **K-14 follow-up:** Spike 16's "Shared with Spike 15" S16-25 row no longer lists S15-09 (its boards come in the workspace read); Spike 15 keys added after S16-25 use its value keys (S15-17, S15-23 Context). Fixed.
- **K-17 follow-up:** S15-17 and S15-23 add their keys to `docs/catalog-caches.md` once S16-10 creates it. Fixed.
- **K-8 note:** what "Used by" counts across Sources, Artifacts, graphs and types is left to S15-08's plan.
- **S15-20:** the plan names how the dogfood Install run happens (`add-seeded-vocabulary` keeps `Install` out of FFI, Swift and open) and warns that a re-run overwrites edited product rows and restores deleted ones. Fixed in S15-20's Context and the citation map § 6.4.
- **S15-08:** "six tables probed" corrected: layout rows cascade and do not keep a field. Fixed.

## Round 3 — slice 8 (S15-27, S15-28, S15-29)

Fresh reviewer, slice 8 only. Writer's call to note: the rule "Citations render on demand, from SQL" now lets the provenance sheet hold its on-open call as one `CatalogQueryKey` while it is shown, evicted when hidden, so it gets S16-04's failure reading and the registry's refresh; nothing outlives the sheet (K-26).

### K-24 · blocker · A new grouped SQL query would duplicate facts the node and the wire already carry
**Answer:** Fixed — rule "Records load when the sheet opens": the detail read keeps `Support`, `Against`, values and state, and adds only `FieldRecordCounts` (record count, a mixed field's distinct Sources) composed from the node and the records tier; no new SQL. S15-29 removes Swift's count rules.

### K-25 · blocker · A kit recipe cannot use the Features fold
**Answer:** To user, kept (preparatory PR); added as S15-30 after S16-07, with the rule rewritten for the kit fold (`Platform/` state, `PVShowMoreRow`).

### K-26 · blocker · The on-open call had no home for S16-04's reading or refetch while open
**Answer:** Fixed — the sheet's on-open call is one `CatalogQueryKey` evicted when hidden (S15-21, which now depends on S16-04); S15-28's read reports its inputs and S15-29 refreshes through the registry. The rule "Citations render on demand, from SQL" says so.

### K-27 · major · One (owner, Property) key does not cover spanning or derived rows
**Answer:** Fixed — the records read takes a row's (owner, Property) pairs, mirroring `RecordsSource`, and returns records grouped by pair.

### K-28 · major · S15-27 re-derives an engine fact in Swift
**Answer:** Fixed — each outcome carries whether it denied a value and the denier's Source title (S15-28); `deniedSomething` and the denier search go in S15-29; S15-27 is the fold only.

### K-29 · major · Spike 16 PRs slice 8 touches are missing from both maps
**Answer:** Fixed — S15-28 depends on S16-24, S15-29 on S16-09, S15-21 on S16-04; Spike 16's shared table gains S16-09, S16-24 and S15-21's key under S16-25; S15-29 restates `.conclusionDetail`'s Source follow.

### K-30 · major · The deprecated Why reads the records S15-28 removes
**Answer:** To user; settled: S15-31 removes the Why (above).

### K-31 · major · Scale and fan-out at 1,200 records not stated
**Answer:** Fixed — S15-16 times 300 and 1,200 Citations; S15-28 times the records read at 1,200; S15-29 times a 1,200-record sheet and states one refetch per write touching the read's inputs.

### K-32 · major · Docs and skills S15-28 and S15-29 make false
**Answer:** Fixed — S15-28: the `conclusiondetails` package comment and `conclusion-reconciliation.md`; S15-29: `macos-client-patterns.md`, `design-system-layers.md`, `add-ui-component`, and retiring `provenance-loading.md`.

### K-33 · minor · The fold's unit
**Answer:** Fixed — the fold counts citation groups and never splits one (rule and S15-27).

### K-34 · minor · "Summary" already names something else
**Answer:** Fixed — `FieldRecordCounts`.

### K-35 · nit · `leadOutcomes` will be gone
**Answer:** Fixed — S15-28 says each `PictureTile.Record` keeps its outcome.

## Re-cut after S15-09's review (2026-11-12)

The user rejected S15-09's Copy details on each Artifact card (the cards grow too tall) and asked for a list that shows copy details read-only, editing in a sheet, and sharper thumbnails. The map gained S15-33 – S15-36 and S15-D14; S15-10 was reshaped and S15-D4 folded into S15-D14. One maintainability reviewer (Opus), fresh context, one round; findings renumbered from the reviewer's K-1 – K-11 to K-36 – K-46.

**To user (answered 2026-11-12):** trim #802 before merge (yes: K-41); the draft board as its own preparatory PR (yes: K-38); square thumbnail crop (yes); Add field as an inline row on every board (user's choice over a dialog on the sheet).

### K-36 · blocker · S15-33 should return the Artifact's saved rows so a sheet Save patches the cache
**Answer:** Fixed — S15-33 adds `metadata` to `UpdateArtifactResponse` and `CreateArtifactResponse`; S15-34 applies `.wroteMetadataBoard` from it, never `.mutatedSourceWorkspace`; the rule "An Artifact is added and edited in one sheet" says so.

### K-37 · major · The S15-34 / S15-35 cut leaves no way to see copy details between them
**Answer:** Fixed — S15-34 ships SA-4 (read-only copy details on today's cards); S15-35 changes only the layout.

### K-38 · major · The draft host should be its own preparatory PR
**Answer:** To user → yes. New S15-36 "A metadata board can hold a draft" (no chrome); S15-34, S15-10 and S15-11 depend on it. S15-11 still depends on S15-34 for the inline Add field row and the scrolling form dialog.

### K-39 · major · Read-only copy details would be a second way to draw a value
**Answer:** Fixed — S15-34 pulls one value view out of `MetadataBoardView.displayValue`; the URL is `PVButton(.link)` (also brief M-6).

### K-40 · major · S15-34's "goes" list is incomplete, including the compact style
**Answer:** Fixed — the trim of #802 (K-41) removes the disclosure, the per-Artifact boards and `.compact`; S15-34's scope names the card-edit state that goes, and the sheet's model follows `SourceGraphFormModel`.

### K-41 · major · S15-09 is marked Landed while its chrome is about to be deleted
**Answer:** To user → trim #802 before merge. The S15-09 row and scope entry record the trim.

### K-42 · minor · Docs and plans the new PRs make false
**Answer:** Fixed — S15-34's Context names `add-workspace-place`, `macos-client-patterns.md`, `DesignSystem/README.md` and the two plans' **Next adds**.

### K-43 · minor · Scale fan-out missing on S15-33, S15-34, S15-10
**Answer:** Fixed — each scope entry states one write per Save (S15-10: create then ingest) and no reload.

### K-44 · minor · Where the sheet's Add field and Clear live
**Answer:** Fixed — new rule "A board adds a field in an inline row" (user); a draft clears with no confirm (S15-36).

### K-45 · minor · Add mode is not one transaction
**Answer:** Fixed — the rule and S15-10 say the file ingests as its own write, and the retry sends the draft on `UpdateArtifact`.

### K-46 · nit · Two loaders for graph-unlink locks
Logged.

### Round 2 (fresh maintainability reviewer, Opus)

### K2-1 · blocker · The rule promises a sharp 128pt square with no derivative change
**Answer:** Fixed — 80pt in the rule and S15-35.

### K2-2 · blocker · No place for the sheet's Escape and Return order
**Answer:** Fixed — S15-34 scope (`PVSheet` yields to an inner edit).

### K2-3 · blocker · "The Add dialog goes" names no replacement per caller
**Answer:** Fixed — S15-36 holds the add row's state for every host, kept across `resetDrafts`; S15-34 lists what goes and what the header and empty-state buttons become.

### K2-4 · blocker · The "goes" list deletes the graph-lock behavior
**Answer:** Fixed — `LinkEdit`'s preflight, lock load and graph-keeps message move into the sheet's model.

### K2 minors (draft starting rows, returned rows into Swift, S15-09 status, trim keep list, S15-11 reload)
**Answer:** Fixed — S15-36 scope; S15-09 "In review, trim pending"; keep list names the pencil change; S15-11 says a graph Save reloads.

## Map review K3 — citation re-plan (2026-11-13)

**Verdict:** Reshape → Fits with changes after the answers below. **Rounds:** 1. **Reviewer:** maintainability (fresh).

**To user.** None: the findings change PR cuts and layers, not product calls.

### K3-1 · blocker · Needed fields belong in the engine's board merge, not a list Swift merges
**Answer:** Fixed — rule "Boards flag needed fields; the engine decides the rows"; S15-38 annotates `listWorkspaces` and `TypeSuggestion`, emits dismissed and unsuggested needed fields, `DismissSuggestion` refuses a needed field, every reply carries it; the date's and page's requirements are named on their reads. Map § 6.10.

### K3-2 · blocker · Requirements cached on `.sourceWorkspace` go stale after a format edit
**Answer:** Fixed — rule "Requirements need a refresh signal; renders do not"; S15-15 reports `.changedCitationFormats(typeId)`; S15-38 wires it and updates `docs/catalog-caches.md`.

### K3-3 · blocker · Citation date terms would be a second DateValue formatter
**Answer:** Fixed — `datevalue.CitationDisplay` beside `CompactDisplay` (rule "Dates in citations use citation terms", S15-14, map § 6.3).

### K3-4 · major · Missing per render and requirements per type are one concept
**Answer:** Fixed — one function from requirements and values to missing; the batch render drops its missing list; the preview keeps it (rule "A format's fields are needed or used", S15-14, S15-16).

### K3-5 · major · Unknown and supplied in three shapes, three controls
**Answer:** Fixed — `core/valuemark` (S15-14) used by all three stores and the resolver; one proto `ValueMark`; S15-41 builds the control once, S15-42 and S15-45 reuse it.

### K3-6 · major · S15-37 too big; who seeds `unknown_text`
**Answer:** Fixed — S15-37 (metadata values), S15-43 (Source date), S15-44 (locator page); S15-19 lands after S15-37 and seeds `UnknownText` through `Install`.

### K3-7 · major · Flags cut per screen though the board is shared
**Answer:** Fixed — S15-39 flags every board at once (brief on the board row); S15-40 is only the Artifact list mark; the header date flag joins S15-42; S15-11 and S15-13 are back to their original scope; the page's flag is S15-45.

### K3-8 · major · Dependency graph and slice order disagree
**Answer:** Fixed — S15-11 and S15-13 no longer depend on slice 4; S15-37, S15-38, S15-43, S15-44 scopes under Slice 4; S15-23's scope under Slice 9; missing edges added (S15-39 on S15-11 and S15-34; S15-42 on S15-38 and S15-41).

### K3-9 · minor · Editing a field's unknown text has no home
**Answer:** Fixed — S15-46 (Metadata page), brief S15-D25.

### K3-10 · minor · Docs and skills not named
**Answer:** Fixed — S15-44 updates `interpretation-layer-data-model.md` § 3.2; S15-19 updates `add-seeded-vocabulary` and `seeded-vocabulary.md`; S15-14 updates `add-date-value`.

### K3-11 – K3-14 · nits
**Answer:** K3-12, K3-13, K3-14 fixed. K3-11 declined: S15-03's plan is Landed and stays as written.

## Map review — "A Source type has its own page" (S15-47 – S15-49), 2026-11-14

**Verdict:** Fits with changes. **Reviewer:** maintainability (fresh context). One round; every finding Fixed in the map.

- **K-1 · blocker · S15-48 does not decide the model shape.** Fixed — S15-48 **Shape** splits `SourceTypesModel` into the list model and `SourceTypePageModel` (the `SourcesModel` / `SourcePageModel` precedent); S15-47 keeps the add draft on the list model; S15-12's status re-homes D-4 onto the page model.
- **K-2 · major · Leftover shared vocabulary chrome.** Fixed — S15-48 reuses `VocabularyPanelHeader`, `VocabularyLabeledSection`, `VocabularyFormActions` or moves them and `VocabularyPaneMode` into `Features/Metadata/`; S15-49 stays on `VocabularyListPane` or moves it; doc comments named.
- **K-3 · major · Skills and docs the page makes false.** Fixed — S15-48 updates `add-workspace-place` and `add-workspace-location`; S15-49 updates `macos-client-patterns.md` § 9 and `wide-layout.md`.
- **K-4 · major · Place details.** Fixed — `viewIdentity: typeId`, presentation `.sourceTypePage`, delete with `leavingPage:`, the three tests named.
- **K-5 · major · Crumb label is carried, not resolved.** Fixed — verified `LocationNames` resolves only `sourceTitle` and `graphName`; S15-48 adds a type-label resolver; the rule names delete-impact rows as a route; the Check covers a rename.
- **K-6 · major · Icon picker becomes two-caller.** Fixed — S15-47 moves it to its own file; S15-D26 decides sheet or inline grid.
- **K-7 · minor · S15-18 stale.** Fixed — Context and Check rewritten; depends on S15-12.
- **K-8 · minor · Back loses the list's scroll.** Fixed — verified `isListRoot` is false for `.sourceTypes`; S15-48 makes it a list root and restores the anchor.
- **K-9 · nit · Wording and a location factory.** Fixed — S15-47 rewires `onAdd`; S15-48 adds `WorkspaceLocation.sourceTypePage(typeId:title:)`.

## Map review — slice 11, Citation metadata (S15-54 – S15-61), 2026-11-22

**Verdict:** Fits with changes after round 2; every To user item answered. **Rounds:** 2. Reviewer: maintainability (fresh context each round).

**To user**
- **K11-13 · How the composer reads an existing Citation's board.** (a) The board rides the cached citations-by-Artifact read and the Citation writes patch it, as every other owner's board rides its owner's read (rule "One window": forms open from the page's values with no fresh read). (b) A fresh `GetMetadataBoard` read when the composer opens, which bends that rule. **Recommendation: (a).** It keeps one way to get an owner's board; the cost is one field on the citations row and its patch, read per Artifact (at Scale, up to 600 Citations with 8 values on one Source). **Answered (user, 2026-11-22): (a).** Findings are numbered K11-# here; the map cites them as "map review K-#".

**Writer's own calls**
- `schedule_number` is page-relative with the fields the user named; `item` and `record_id` stay graph-first.
- Stored locators keep old printed-page keys until the Citation is saved again; reads ignore them.
- K11-1's fix means the Conclusion detail, the gallery and the likeness viewer show only a Citation's own page, not one inherited from its graph or Artifact (a reader that needs the inherited page asks the render RPC).

### K11-1 · blocker · A second, hidden page-chain resolver cached in `graphfill`
**Answer:** Fixed. Rule "The printed page is a metadata field" now says readers outside a rendered citation show only the Citation's own `page` and nothing resolves the chain except a format; S15-54 declares `citation_metadata`'s effects path to its graph; S15-56 switches `graphfill` and `conclusiondetails`.

### K11-2 · blocker · Boards had no slot for a Citation's graph and Artifact
**Answer:** Fixed. S15-55 is now "Boards meet a chain at every level above": store entries declare ancestors, `listWorkspaces` and the draft read load them, and the draft request names its would-be parents. Rule "Boards flag needed fields" updated.

### K11-3 · major · The level registry ships S15-57's chrome inside S15-54
**Answer:** Fixed. S15-57 merged into S15-54, which is now visible and gated by S15-D30; S15-54 also adds the Citation owner to `fillValues`, so nothing parses without rendering.

### K11-4 · major · The Citation-first seed split across two PRs; two composer briefs
**Answer:** Fixed. S15-60 seeds all eight fields, `page` included, through one helper, before the composer PR; S15-56 removes the Printed page input under S15-D29; S15-D31 descoped; S15-58 is the Go retirement of `{citation.page}`.

### K11-5 · major · A fourth hand-copied set of `deleteimpact` rows
**Answer:** Fixed. New preparatory PR S15-61 builds each level's delete rows from one declared list; S15-54 adds the Citation as one entry.

### K11-6 · major · Rules the slice makes false left standing
**Answer:** Fixed. "Metadata lives at four levels", "One level type", "Suggestions have a level", "Citation formats are data", "Boards flag needed fields" and "A value can be marked" rewritten in place; S15-D20 and S15-D22 rows name the composer's board.

### K11-7 · major · Docs per PR misnamed or missing
**Answer:** Fixed. S15-59 names `interpretation-layer-data-model.md` §§ 3.2, 3.3, 3.6; S15-58 `citation-formats.md` and `source-layer-data-model.md` § 5.2; S15-54 `citation-formats.md` and `source-layer-data-model.md`; S15-61 `catalog-deletes.md`.

### K11-8 · minor · Deletes not listed
**Answer:** Fixed. S15-56, S15-58 and S15-59 carry **Deletes** lines.

### K11-9 · minor · Spike 16's S16-58 and S16-59 edit the same files
**Answer:** Fixed. A row in Spike 16's "Shared with Spike 15", a line in this map's Spike 16 dependencies, and the in-parallel text.

### K11-10 · minor · Fan-outs and an RPC name
**Answer:** Fixed. S15-54 states the Source-delete release (up to 4,800 rows) and uses `CreateCitationWithObservations`; S15-56 reads an existing Citation's board through `GetMetadataBoard` with no new query key.

### Round 2

Round-1 answers: K11-2, K11-3, K11-4, K11-6 and K11-9 confirmed fixed; K11-7, K11-8 and K11-10 were partial and are finished below; K11-1 and K11-5 led to K11-12 and K11-11.

- **K11-7 (finished):** S15-54 now names `source-layer-data-model.md` § 5.4 and § 5.5's heading and `citation-formats.md`'s "at the three levels that hold metadata".
- **K11-8 (finished):** S15-56's Deletes adds `printedPagePrompt`, `printedPageHelp`, the `.printedPage` focus case, `printedPageField`, the summary's `locator.pageLabel` read and `CitationComposerModel.pageLabel`.
- **K11-10 (finished):** the rule names `CreateCitationWithObservations`.
- **Executability note (round 2):** S15-17 replaced Insert field with completion; S15-54's Ships and Check and the S15-D30 rows now name the completion.

### K11-11 · blocker · S15-61's list beside `sourcemetadata.stores`
**Answer:** Fixed. S15-61 is now "Metadata levels are one declared list": one list in `catalogmodel` builds `sourcemetadata.stores` and the delete rows, with a parity test against `vocabkey.MetadataLevels()`; S15-55 takes ancestors from its parent path; S15-54 adds one entry. Deriving the effects registry's `SourceScope` paths is left as a later cleanup (Not this PR).

### K11-12 · blocker · `graphfill`'s read of the Citation's page named no lookup or reader
**Answer:** Fixed. Rule "The printed page is a metadata field" and S15-56: the key is declared once in `core/vocabkey`, resolved through `metadatafields.ResolveKeysTx` preferring the seed's origin, values read through `sourcemetadata.ListByOwnersTx`; no field means no page; unknown shows the unknown text, supplied shows in brackets (writer's call, as a citation prints them).

### K11-13 · blocker · S15-56's fresh board read bends "Forms open from the page's values with no fresh read"
**Answer:** To user; the user chose (a). S15-56's Ships says the board rides the cached citations-by-Artifact read and the writes patch it.

## Map review — slice 11 re-cut and slice 12, metadata at any level and formats apart from types (2026-11-22, later)

**Verdict:** Fits with changes. **Reviewer:** maintainability, fresh context. Scope: the re-cut slice 11 (S15-61 – S15-64, S15-54, S15-55, S15-60, S15-56, S15-58, S15-59), slice 12 (S15-67 – S15-72), S15-65 and S15-66, and their rules.

**To user.**
- ~~S15-65 · a citation preview beside the boards~~: skipped for now (user, 2026-11-22); descoped to `ideas/citation-composer-followups.md`.
- ~~URL follows nearest-wins~~: confirmed (user, 2026-11-22).

**Writer's own calls** (the user may veto):
- `sources.citation_format_id` NULL means "follow the type", so changing a type's default or a Source's type moves every Source that never chose.
- A format's delete is refused while in use (not released), and a format outlives the types that name it.
- Formats take no ref, join the omnibar as `citation_format`, and their list builds on `VocabularyListPane` with Used by widened to types and Sources (K-7).
- S15-63's merge order for suggestions: Source, then Artifact, then graph rows, a field's first row winning.
- No brief for S15-62's completion change: the same list with one row per field.
- S15-64 shows only values from above an owner, never from below (a Source's Citations).

### K-1 · blocker · S15-67 keeps everything keyed by type, so S15-71 re-keys it all
Every format reader is keyed by type id (`sourcetypes.StoredFormatsTx`, `RequirementsTx`, `readTypeBoards`, `needOfTx`); the format code sits in `sourcetypes/formats.go`.
**Answer:** Fixed. S15-67 adds `core/database/citationformats/` and one read that maps a Source or type to its format id. Templates and requirements are keyed by format id, and `readTypeBoards` splits into suggestions by type and needs by format. S15-71 changes only that read's SQL expression. Rule "A citation format is its own vocabulary" says so.

### K-2 · blocker · The nearest-level order is declared three times, and the level list holds one parent
`catalogmodel.MetadataLevelTables.Up` is a single parent; a Citation has two.
**Answer:** Fixed. The order is declared once in `vocabkey.NearestFirst`, with a parity test against the level list. S15-54 turns `Up` into ordered `Ups`, with the Artifact marked as the audit-scope path. Rule and the S15-54 and S15-62 scopes say so.

### K-3 · major · S15-64 and S15-65 should reuse the one resolver
**Answer:** Fixed. S15-62 makes `sourcemetadata.CitationValues.Resolve` walk nearest-first. S15-64's inherited value is `Resolve` without the owner's level, and S15-65 builds `CitationValues` with the draft's rows. The rule says nothing else walks the levels.

### K-4 · major · Between S15-68 and S15-69 one format has two editors and two writes
**Answer:** Fixed. S15-68 moves the editor to `Features/CitationFormats/` with its own `UpdateCitationFormat` write and a format-keyed signal. It also swaps the type page's editor for a link to the format, so S15-D36 draws that link too. S15-69 turns the link into the picker.

### K-5 · major · Field-in-use listing and type delete undecided
**Answer:** Fixed. From S15-67 the probe lists formats, and a format outlives a deleted type (rule, S15-67 scope and Check).

### K-6 · major · Skills, docs and map rules these PRs make false
**Answer:** Fixed. S15-63 updates `add-seeded-vocabulary` (`seedSuggestions`) and `add-workspace-place` (`.wroteTypeSuggestions`). S15-67 updates `add-catalog-delete`, `add-seeded-vocabulary` (`seedTypes … Formats`) and the citation-formats intro. S15-68 updates `add-workspace-place` and `docs/catalog-caches.md`. The six rules carry a "From S15-6x" note: "A Source type has its own page", "Requirements need a refresh signal", "A format's fields are needed or used", "Formats name fields by id", "Boards flag needed fields" and "Citations render on demand".

### K-7 · minor · Refs, search and list left to the plan
**Answer:** Fixed. Decided in the rule (Writer's own calls above).

### K-8 · minor · Three invisible PRs in a row; two dependencies stronger than needed
**Answer:** Fixed. S15-64 now depends on S15-63 only, since Artifact and graph boards already read their Source. S15-60 depends on S15-54 and S15-62. S15-55, S15-60 and S15-64 meet at S15-56.

### K-9 · minor · S15-72 lands before a shared format has a page
**Answer:** Fixed. S15-72 now depends on S15-69.

### K-10 · minor · Spike 16 overlap under-named
**Answer:** Fixed. S15-68 and S15-70 are added to both maps' S16-58/S16-59 row. S15-64 and S15-66 are added to the board-row rebase note.

### K-11 · minor · Missing fan-out lines
**Answer:** Fixed. S15-64, S15-66, S15-69 and S15-70 now have fan-out lines.

Noted, no change: S15-67 and S15-56 are at the ~10-step limit, and `plan-pr` should watch their step count.

### Round 2 (fresh reviewer: answers checked, new blockers only)

K-3, K-4, K-6, K-8, K-9, K-10 and K-11 applied consistently. **Verdict:** Fits with changes; both new blockers fixed. No round 3 (the loop's cap).

#### K-12 · blocker · "In use" for a format had three definitions, and the Source half had no owner
**Answer:** Fixed. In the rule, "in use" now means named: a type's default (S15-67) or a Source's choice (S15-71), each an inbound `deleteimpact` edge with its FK in `catalogmodel`. That count is the delete gate, `usedBy`. "Sources citing with it" is a separate count, taken through the one Source-to-format read. S15-71 adds the FK, the edge, the `COALESCE` and the skills it uses. S15-68 and S15-70 (row and scope) follow the rule.

#### K-13 · blocker · `NearestFirst` was a third copy of the level order
**Answer:** Fixed. `NearestFirst()` is `slices.Reversed(MetadataLevels())`. The parity test only checks that each entry's `Ups` agree with it. `citationformat` only parses, and `Resolve` is the one walker (rule; S15-54 and S15-62 scopes).

Minors fixed:
- S15-69 now applies `.changedSourceType`.
- Rule "Formats name fields by id" names the write's move to `citationformats`.
- S15-68's Ships adds the `citation_format` omnibar kind.
