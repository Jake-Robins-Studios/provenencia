# S16-80 — An event's places reconcile by their records

**Status:** Draft
**Spike / slice:** Spike 16 · Slice 6k — Event places by evidence
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: the life rows, the Event page's Place row and the provenance sheet draw what they draw today; only which place leads, the mixed badge and each record's outcome words change, and every outcome phrase already exists)
**Board:** —
**Depends on:** —
**Blocks:** —
**Branch:** `s16-80-event-place-vote`
**Version bump:** patch — a bugfix in which place an event shows, with no schema or wire change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-catalog-query`](../../../../.agents/skills/add-catalog-query/SKILL.md) (the leaf SQL package), [`add-match-rule`](../../../../.agents/skills/add-match-rule/SKILL.md) (the reconciler's module policy)
**Rules that bind:** `.cursor/rules/go-tests.mdc`
**Context:** [`docs/conclusion-reconciliation.md`](../../../conclusion-reconciliation.md) §5 (the pipeline), §8 (cardinality), §9 (values reached through other entities), §11.1 (places: "Several Locations on one Event … fold into chains"; places that do not connect "reconcile like any other multi-valued or mixed field"); [`docs/catalog-caches.md`](../../../catalog-caches.md) (the `nodes` row); [`docs/ideas/one-bridge-cardinality.md`](../../../ideas/one-bridge-cardinality.md); working rules "(Batch 2) Every cache names the signal that updates it, and updates exactly", "(Batch 2) Memory is budgeted", Spike 16 rule "Crafted fan-out is capped, not engineered"; the user's calls of 2026-11-26 recorded in § 5
**Planned:** 2026-11-26 against `origin/main` @ `7a1d15c`
**Review:** [`S16-80-event-place-vote.review.md`](S16-80-event-place-vote.review.md) — Fits with changes · Ready with changes, 2 rounds; To user open (M-1, M-12)

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

When an event's records place it in different Places, the Place the event shows is the one its records support, by the same rules as any other single-valued field: a place that contains another linked place folds into it, then the Sources vote, then weak evidence drops. A birth that three Sources place in Swift Current and one in England shows Swift Current, merged, with the England record marked outvoted (3 of 4 Sources). A birth placed in Swift Current and in Canada shows Swift Current, with the Canada record marked folded.

**Why now.** Dogfood, 2026-11-26: a Person's Birth place showed England, mixed, over Swift Current, which three of four records named. Each event–place link reconciles only its own records, and `FoldLocations` orders the places left after folding by their ref (`PLC-6HH94` sorts before `PLC-PP6PW`). No step counts records across links, although § 11.1 of the reconciliation doc says it should.

**What stays.** Place-to-place (`part_of`, `succeeded_by`), person-to-event and person-to-person links keep every link: they are many-valued (user, 2026-11-26). Which birth or death event a Person's life row leads with (the earliest dated) is unchanged. Promote's matching is unchanged. An event whose places all fold into one, or that names one place, reads exactly as today.

## 2. User stories

**US-1.** As a researcher, when an event's records name places that do not contain each other, the event shows the place most Sources name, so one stray record does not decide it.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A birth located at Swift Current by three Sources and at England by a fourth; England's ref sorts first | The Person's Birth place and the Event's Place read Swift Current, not mixed; the Events list's place column reads Swift Current with no +1 |
| AC-1.2 | A birth located at Swift Current by one Source and at England by another, both standard and certain | Both places show, mixed; the earlier-recorded place leads |
| AC-1.3 | As AC-1.2, but the Swift Current record's Source is graded low trust | England shows, not mixed |
| AC-1.4 | One Source locates the birth at both Swift Current and England | Both places show, mixed (one Source is no majority) |

**US-2.** As a researcher, when one record names a place that contains another record's place at the event's date, the event shows the smaller place and counts both records for it.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Swift Current (part of Saskatchewan, part of Canada) by three Sources, Canada by a fourth | Swift Current, not mixed, with its chain Saskatchewan, Canada |
| AC-2.2 | Canada by one Source, Swift Current by one, Toronto by one (both cities part of Canada through their provinces); Swift Current recorded first | Canada folds into Swift Current, which then holds 2 of 3 Sources: Swift Current shows, not mixed; Toronto is outvoted (user, 2026-11-26) |
| AC-2.3 | Dublin by two Sources and United Kingdom by one, Dublin part of United Kingdom by a `part_of` link that ends in 1922; the birth is in 1950 | United Kingdom does not fold (the link does not hold in 1950); Dublin wins 2 of 3 and United Kingdom is outvoted |
| AC-2.4 | As AC-2.3 with the birth in 1900 | United Kingdom folds into Dublin: Dublin shows, not mixed |

**US-3.** As a researcher reading the Birth place's provenance sheet, every record behind the event's place links is listed with what the vote did to it.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | AC-1.1's Person, Birth place sheet | Four records from 2 Places; the three Swift Current records read "kept", under the shown group; the England record reads "outvoted (3 of 4 Sources)" |
| AC-3.2 | AC-2.1's Person, Birth place sheet | The Canada record is listed, under a Canada group, and reads "folded"; today it is not listed at all |
| AC-3.3 | AC-1.3's Person | The Swift Current record reads "weak · low-trust Source" |

## 3. Scope

| In | Covered by |
| --- | --- |
| The credibility-order SQL moves to a leaf package the graph cache can import | STEP-2 |
| A node's members carry their Source's credibility; its outcome rows carry their Citation's transcription certainty | STEP-3, T-3 |
| A simple module can take a caller's fold rule; `autoreconcile.ReconcileHandles` runs the subject module with one | STEP-4, T-1 |
| An event reads at most 64 location links, everywhere its places are read | STEP-5, T-5 |
| An event's places, everywhere they are composed (Event rows, Person life rows, search rows), are its location links' records reconciled with containment folding at the event's date | STEP-6, T-4, AC-1.1 – AC-2.4 |
| A Person's place owners list every location link of the event, each with what the vote did to it | STEP-5, T-4 |
| The Birth and Death place sheets show each record's outcome from the vote, and every sheet reads a record's provenance off the node | STEP-7, T-6, AC-3.1, AC-3.2, AC-3.3 |
| Search documents are re-projected on open | STEP-8 |
| Version 0.46.1; docs: reconciliation § 9 and § 11.1, catalog caches, add-match-rule | STEP-10 |

| Out | Home |
| --- | --- |
| A declaration of "one place per event" that matching also reads | [`docs/ideas/one-bridge-cardinality.md`](../../../ideas/one-bridge-cardinality.md) (user, 2026-11-26) |
| Which birth or death event a Person leads with when it has two (earliest date today) | [`docs/ideas/one-bridge-cardinality.md`](../../../ideas/one-bridge-cardinality.md) open question; § 9 asks the researcher to merge duplicate events |
| Reconciling `part_of`, `succeeded_by`, participation or relationship links | not planned: those ends are multiple (user, 2026-11-26) |
| "folded into Swift Current" in place of the plain "folded" on a link's record | not planned: the owner field holds the link's own values, not the event's; the plain phrase is what a gallery record says today |
| A Reconciliation Claim that concludes an event's place | the Reconciliation Claims work in [`conclusion-reconciliation.md`](../../../conclusion-reconciliation.md) § 8 (not scheduled) |
| Evidence graph event titles (`grapheventtitles` sorts a Subject's places by ref) | not planned: an Evidence graph is one Source's reading; nothing votes there |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Folding an event's places | `core/database/conclusionsummaries/placechains.go` `FoldLocations` | Drops a place that is an ancestor of another linked place at the date (`isAncestor(id, other, at) && !isAncestor(other, id, at)`), then sorts the rest by `Entity.Ref`. The ref sort is the whole decision between places that do not contain each other |
| An event's places | `core/database/conclusionsummaries/compose.go` `eventPlaces` | Reads each link's place shell and returns `FoldLocations`; called by `oneEvent` (Event rows) and `lifeFacts` (Person life rows). Reads no record of any link |
| An event's links | `compose.go` `eventLocations` | "The one read of an event's places": keeps every link whose place is among the first `maxEventPlaces` (20) distinct places; links to one place are not bounded |
| Life owners | `compose.go` `lifeFacts`, `maxLifeOwners` (64, date and place owners together) | A place owner for each link whose place survived the fold; a folded ancestor's link (Canada) has no owner, so its records never reach the sheet |
| Owner type | `core/database/conclusionsummaries/conclusionsummaries.go` `FieldOwner` | `ID`, `PropertyID`, `Place`; no outcome |
| Sheet rows | `core/database/conclusiondetails/conclusiondetails.go` `PersonDerivedRows` | Composes each owner's field from the association node's own outcomes, so every link's record reads "kept" |
| Sheet provenance | `conclusiondetails.go` `(*recordReader).outcome` | `Provenance` from the Source record's `Credibility` and the per-graph Observation's `TranscriptionUncertain` |
| Node evidence | `core/database/graphcache/graph.go` `Member`, `Outcome`; `load.go` `loadMembers`, `loadOutcomes`; `verify.go` `sameMembers`, `sameOutcomes` | A member has its Subject's Source and graph; an outcome row has no provenance |
| Credibility SQL | `core/database/sourcecredibilitygrades/registry.go` `DefaultKey`, `orderBound`, `RelativeOrderColumn`, `RelativeOrderJoins` | Read by `core/database/autoreconciler/autoreconciler.go` `sqlLoadCandidates` and `core/database/sources/records.go`; `DefaultKey` also by `core/database/sourcemove/sourcemove.go` and tests. `graphcache` cannot import this package (`core/database` imports `graphcache`, this package imports `core/database`) |
| Modules | `core/autoreconcile/modules.go` `keyModule`, `moduleFor`; `autoreconcile.go` `Reconcile` | `keyModule` never folds; subjects key by `EntityID` (`idKey`); `Reconcile` validates cardinality and `Carries` inline |
| Matching's cardinality | `core/matchregistry/segment.go` `defaultSegment` `One` | Birth and death only; unchanged by this PR |
| Search | `core/database/searchindex/searchindex.go` `ProjectionVersion` (12), pinned by `searchindex_test.go` (line 246) and `core/search/handles_test.go` (line 385) | Documents index every place in `Places` |
| Swift | `macos/App/Features/Conclusions/PersonDetailContent.swift` `rows`; `EventDetailContent.swift` `placeRow`; `macos/App/Platform/DerivedPlace.swift`; `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheetContent.swift` `derived`; `macos/App/Platform/ReconciledValueDisplay.swift` `outcomePhrase` | Lead and mixed come from `places`; the sheet groups owners by place, shown place first; "folded" (with `valueRank` 0), "outvoted (N of M Sources)" and "weak · …" render. No Swift change |
| Tests | `core/database/conclusionsummaries/placechains_test.go` `TestBirthLocationsFoldWhenPartOf`, `TestSiblingBirthPlacesStayCompetingUnderASharedParent`, `TestPersonRowOwners`; `eventplaces_cap_test.go` `TestCraftedEventPlaces`, `TestEventPlacesCapInputs`, `TestCraftedLifeOwners`; `core/database/conclusiondetails/placerecords_test.go` | All use one Source, so no vote reaches a majority |
| Test builders | `core/database/graphcache/graphcachetest/graphcachetest.go` `Canon`; `placerecords_test.go` `birthAt` | `Canon` has one Source, Artifact, graph and Citation; `birthAt` promotes a fresh person, birth and place each call |
| Version | `VERSION`, `core/version.go` `Version`, `macos/Provenencia.xcodeproj/project.pbxproj` `MARKETING_VERSION` (four lines: app and tests, Debug and Release) | 0.46.0; `core/version_test.go` `TestVersion` holds `VERSION` and `core.Version` equal |

**Precedent.** `dateModule` in `core/autoreconcile/dates.go` is a module with a fold rule. `core/database/scalarcols` is the leaf SQL package `graphcache` already imports. S16-42 is the precedent for bumping `ProjectionVersion` when what a summary row carries changes.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `voteLocations` reconciles with `propertymeta.CardinalitySingle`, written as a constant with `// decided: user, 2026-11-26: an event has one place; one declaration with matching waits on docs/ideas/one-bridge-cardinality.md` | Matching's `One` is the one cardinality declaration, and location cannot join it until matching knows containment | A `connectrules` cardinality field (a second declaration with one reader); location in `One` now (Promote would score Canada vs Swift Current as a conflict) |
| D-2 | The vote runs in the summary composer, in memory, from each association node's outcome rows: `voteLocations` replaces `eventPlaces` for both callers | Event rows, life rows, search rows and the sheet then read one answer | The auto-reconciler: it cannot fold, because containment needs the place graph at the event's date |
| D-3 | A link's candidates are its association's outcome rows on the `place` Property with `ValueRank` 1 and reason `kept` or `folded`, one per row: `ObservationID` the row's, `Value{SubjectID: link.Neighbor, EntityID: link.Neighbor}`, `SourceID` the member's (by the row's `SubjectID`), `Provenance{Credibility: member's, Uncertain: row's}`. Denied, provisional and negative rows do not vote again. A row with no `SubjectID` or no matching member is skipped. Rank 1 is the link's place: a link is read from its association's rank-1 kept value (`graphcache` `linkLoadSQL`) | They are the records that made the link's place; the link's own reconcile already decided the rest | Counting a whole association as one vote: two Sources behind one link are two Sources |
| D-4 | Strength counts: weak drop and stronger-first ranking apply across links as in any field (user, 2026-11-26) | Same rules as fields | Sources only |
| D-5 | A Source's credibility lives on `graphcache.Member` (one join in `loadMembers`); a Citation's transcription certainty on `graphcache.Outcome` (one join in `loadOutcomes`). The vote and the sheet both read provenance there | The vote and the sheet weigh a record from the same node fields; the node reloads on every credibility and certainty write (`effects` Handles), so neither needs a new signal. The sheet's grade label (`CredibilityKey`) stays the Source record's | `sources.RecordsOf` in the composer: a whole read fails inside a write (`database.ErrWholeOnWrite`), where search re-projects summaries |
| D-6 | Containment is one predicate, `(*placeGraph).folds(from, into, at)` = `isAncestor(from, into, at) && !isAncestor(into, from, at)`. `FoldLocations` and the vote's fold rule both call it. The date is the one `FoldLocations` gets today (an event row's dating low end, else high; a life row's pick date; nil folds by undated links only, as today). A place that could fold into several folds into the one with the most Sources, then the best ranked (user, 2026-11-26) | One containment rule for the fold and the vote | Folding "into each" (a shared parent that breaks no tie): a pipeline change for one module |
| D-7 | Fast path: when `FoldLocations` leaves at most one place, no association node is read; a link's verdict is `folded` when `folds(its place, the survivor)`, else `kept`. With one survivor this is the vote's result, since every other place folds into it and D-3 gives the vote no negative | It keeps list reads node-free for every event whose places agree | Always voting: it would load every association of every event on the list paths |
| D-8 | The places an event shows are the vote's displayed values in result order (support, then the best-ranked record: stronger provenance, then the earlier Observation). The displayed places are `FoldLocations`' own survivors, reused with their `Parents` (a vote root is never a place the fold covered). Outvoted and weak places leave `Places`, so the lead, the +N and the mixed badge follow with no Swift change. `FoldLocations` loses its ref sort; survivors keep link order | The order is the pipeline's; ref is never a reason | Ordering ties by ref |
| D-9 | `eventLocations` keeps at most `maxLifeOwners` links in link order, before its distinct-place cap. Every reader of an event's places (the place graph seeds, the fold, the vote, the owners) then reads the same links | It stays "the one read of an event's places"; Spike 16 rule "Crafted fan-out is capped, not engineered" | A separate cap inside the vote: a place could be in the graph but in neither the vote nor `Places` |
| D-10 | `placeVote.links` maps an association id to its verdict as `FieldOwner` carries it (`Reason`, `Vote`): `kept`, `folded`, `outvoted` or `weak`. A link's verdict is the outcome of its best-ranked candidate | Every record behind one link holds one place, so the vote treats them alike | A reason per record |
| D-11 | Life owners list every location link of each picked event, up to `maxLifeOwners` with the date owners: the links to the shown places first (place order, then link order), then every other link in link order. Each owner's `Place` is its own neighbour's shell. A link with no verdict (its association node missing, or no shell) has no owner; an event with no shell has no place and no place owner | The sheet lists every record (US-3); `PVProvenanceSheetContent.derived` puts the shown group first | Only the shown places' links: the outvoted record would vanish |
| D-12 | `conclusiondetails.placeVerdict(owner conclusionsummaries.FieldOwner, f *Field)` *(new)* lays an owner's verdict over its field: every outcome whose reason is `kept` or `folded` takes the owner's `Reason` and `Vote`; `folded` also sets `ValueRank` 0, so the phrase is the plain "folded". `PersonDerivedRows` calls it for place owners | One function. The verdicts exist only on the Person row's owners, so S15-28's records read for a derived row takes the Person and the row kind, as `PersonDerivedRows` does, and calls it (both maps) | Inlining it in `PersonDerivedRows`' loop; an exported verdict read by association, which would re-run the vote at a date the Person row did not use |
| D-13 | `ProjectionVersion` becomes 13, so Open re-projects every search document; an outvoted place no longer matches its event or person in search | A summary row's places changed meaning; S16-42 precedent | Old documents healing on the next write to each handle |
| D-15 | `composePersons` and `composeEvents` load every conflicting event's association nodes in one `Graph.Nodes` call per composition, before composing rows: `conflictLinks(pg, at, locations) [][]byte` *(new)* returns the association ids of an event whose `FoldLocations` leaves two or more places. `voteLocations` then reads them through `InputScope.Node`, which records the inputs | A Person's sheet issues the same graph queries however many events and places conflict | A `Nodes` call per event |
| D-14 | No `CacheVersion` bump | The auto-reconciler's own rows do not change | — |

**Rules this plan bends.** The reconciler's grouping policy (`docs/conclusion-reconciliation.md` § 7, decided 2026-10-17 in S11-06; the `moduleFor` comment; `add-match-rule`: "values group on `Key` at `Same` and fold on `Contains`"; the § 7 subject row's Fold "none"). Subjects now fold by a rule the caller passes, because value compare is pure and cannot read the place graph. User's answer: pending (review log, To user). On acceptance, STEP-4 rewrites the `moduleFor` comment and STEP-10 rewrites § 7's policy and subject row ("fold: by a caller's rule; an event's place vote folds by containment at the event's date") and the `add-match-rule` line.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `core/database/sourcecredibilitygrades/gradeorder` *(new)* — `DefaultKey`, `Column`, `Joins(sourceIDExpr string)` | package | `sourcecredibilitygrades` `DefaultKey`, `RelativeOrderColumn`, `RelativeOrderJoins` | Moved, not copied, so `graphcache` can import it; nested under its domain; one `DefaultKey`, no alias |
| `graphcache.Member.Credibility`, `graphcache.Outcome.Uncertain` *(new)* | fields | `autoreconcile.Provenance` | The node carries what the reconciler weighed, each fact where it lives |
| `graphcachetest.(*Canon).NewSource(grade string, uncertain bool)` *(new)* | helper | `evidencelayertest.(*Records).NewSource` | `Canon` writes rows directly and needs its current Source, Artifact, graph and Citation switched, with a grade assessment |
| `keyModule.folds func(from, into unit) bool` *(new)* | field | `keyModule` | Nil folds nothing, as today; one simple-module type keeps every simple value type |
| `autoreconcile.ReconcileHandles(candidates []Candidate, folds func(from, into []byte) bool, cardinality string) (Result, error)` *(new)*, `validate` *(new)* | funcs | `Reconcile` | `Reconcile` takes no fold rule; both call `validate` (cardinality and `Carries`) |
| `conflictLinks` *(new)* | func | `placesOfEvents` | D-15; reads `FoldLocations` with no node load |
| `graphcachetest.(*Canon).SetRef(id []byte, ref string)` *(new)* | helper | `Canon.Entity`'s `TST-n` refs | Refs compare as strings (`TST-12` < `TST-6`); a test that pins the old ref order sets them |
| `(*placeGraph).folds` *(new)* | method | the predicate inside `FoldLocations` | Extracted, then called by both |
| `voteLocations(in *graphcache.InputScope, v vocab, pg *placeGraph, at *datevalue.Value, locations []graphcache.Link) (placeVote, error)` *(new)*, `placeVote{places []ChainedPlace; links map[string]FieldOwner}` *(new)* — file `core/database/conclusionsummaries/placevote.go` *(new)* | func, type | `eventPlaces` | Replaces it; `links` holds only `Reason` and `Vote` of each `FieldOwner` |
| `FieldOwner.Reason autoreconcile.Reason`, `FieldOwner.Vote autoreconcile.Vote` *(new)* | fields | `conclusiondetails.Outcome.Reason`, `.Vote` | Same types; carry the link's verdict to the sheet |
| `conclusiondetails.placeVerdict` *(new)* | func | `PersonDerivedRows` loop | D-12 |

**Builds on.** The shared pipeline (`pipeline.go`: fold, elect, dropWeak, orderRows) through a module, as names and dates do; the place graph's `isAncestor`; the node's outcome rows and members (S16-11); `InputScope.Node` for inputs.
**Deletes.** `eventPlaces`; the `Entity.Ref` sort at the end of `FoldLocations`; `sourcecredibilitygrades.DefaultKey`, `RelativeOrderColumn`, `RelativeOrderJoins`, `orderBound` (moved; every caller and test reads `gradeorder`); `(*recordReader).outcome`'s provenance from the Source record and per-graph Observation.
**Next adds.** [`docs/ideas/one-bridge-cardinality.md`](../../../ideas/one-bridge-cardinality.md): location joins `One`, and the vote reads it in place of D-1's constant, reusing `(*placeGraph).folds` for matching's containment.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| An event with two or more surviving places reads its location associations | `voteLocations` → `InputScope.Node` | A missing or merged association node gives no candidates; a place with no candidate is not shown |
| A place owner whose place is not shown (outvoted, weak, folded) | `PersonDerivedRows`; `PVProvenanceSheetContent.derived` | Swift groups by owner place with the shown owner first and greys the rest; T-6 pins the reasons |
| `Places` shorter than the event's surviving places | `DerivedPlace`, `EventsListView`, `PersonLifeDisplay`, Timeline cards | They read the first place and count the rest |

### Scale

At the map's Scale (one to three places per event; the S11-21 large fixture at 4,000 and 16,000 persons):

- **Lists and search.** The vote reads association nodes only for an event with two or more places after folding (D-7). The large fixture's events have one place each, so lists and `RowsForSearch` read no new node.
- **Conflict path.** At most 64 association nodes per event (D-9), loaded with every other conflicting event's in one `Graph.Nodes` call per composition (D-15). `TestCraftedEventPlaces` (20 unrelated places from one Source) takes this path within its one-second budget.
- **Memory and load.** `Member` gains an int, `Outcome` a bool. `BenchmarkCacheSizes` `nodes-B` at 16,000 persons grows by less than 2 MB and `nodes-ms` by less than 15 %.
- **Fold.** The pipeline's fold is quadratic in distinct values; distinct places per event are at most 20.

### Edges

- **Assumptions.** `foldValues` follows folds through chains and picks one sink; `isAncestor` is bounded by `summaryChainDepth` and guards cycles, and `folds` adds the reverse check, so a cycle at the date keeps both places (T-4 "cycle"). `Reconcile`'s result does not depend on input order, so link order cannot move the lead.
- **Neighbors.** One place: unchanged. Places that all fold into one: unchanged `Places`, new owners for the folded links (AC-3.2). Two unrelated places from one Source: both shown, as today, led by the earlier record instead of the lower ref (T-4 "one Source"). Two links to one place from one Source count as one Source. Siblings under a named parent from one Source: unchanged (`TestSiblingBirthPlacesStayCompetingUnderASharedParent`); from three Sources the parent tips the tie (AC-2.2).
- **Removed inputs.** A regraded Source, a Citation marked uncertain or a removed record reloads the association node (effects Handles), dropping the summary rows that read it through `NodeKey` (T-8). A deleted place leaves the link with no shell: no candidate, no owner, as today.
- **Source of a record.** The member's Source (`subjects.source_id`) equals the reconciler's (`artifacts.source_id` of the record's Citation): `observations` requires a Citation on its Subject's graph, and a Source move (S15-24) moves both together.
- **Real data.** No table or seed drives the rule.
- **Untrusted size.** Links per event: 64, then distinct places: 20 (`eventLocations`, before any read). A containment chain deeper than `summaryChainDepth` (8) does not fold, as today (crafted only). Records per link: the association's outcome rows, already on the node; linear in the vote.

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/sourcecredibilitygrades/gradeorder` *(new)* | `DefaultKey`, `Column` (today's `RelativeOrderColumn` with its clamp), `Joins`; imports `core/vocabkey` only |
| `sourcecredibilitygrades`, `autoreconciler`, `sources`, `sourcemove` and their tests | Read `gradeorder` |
| `core/database/graphcache` | `loadMembers` adds `gradeorder.Joins("s.source_id")` and selects `gradeorder.Column` into `Member.Credibility`; `loadOutcomes` adds `LEFT JOIN citations c ON c.id = o.citation_id` and selects `COALESCE(c.transcription_uncertain, 0)` into `Outcome.Uncertain`; `sameMembers` and `sameOutcomes` compare them |
| `core/autoreconcile` | `keyModule.fold` calls `folds` when set; `validate`; `ReconcileHandles` runs `keyModule{keyOf: idKey of EntityID, folds}` through `reconcile` with no concluded value; package doc names the caller's fold rule |
| `core/database/conclusionsummaries` | `eventLocations` per D-9; `folds` per D-6; `placevote.go`: `voteLocations` builds raw places as `eventPlaces` did, folds, takes the fast path (D-7) or reads the links' association nodes, builds candidates (D-3) and calls `ReconcileHandles`; `oneEvent` and `lifeFacts` call it; owners per D-11 |
| `core/database/conclusiondetails` | `placeVerdict` (D-12); `(*recordReader).outcome` reads `Provenance` from the member's `Credibility` and the row's `Uncertain` (the record reader keeps a member credibility map beside `graphOf`); `CredibilityKey` still comes from the Source record |
| `core/database/searchindex` | `ProjectionVersion = 13`, history line "13: an event's places are its location links' records reconciled (S16-80)." |

### FFI

None — the outcome fields the sheet reads already cross; `FieldOwner`'s new fields stay in Go.

### macOS

None — no Swift change.

### Strings

None — every phrase exists.

## 7. Steps

**STEP-1 — Baseline.**
Do: on the planning base, before any change, run `CGO_ENABLED=1 go test -tags fts5 ./core/database/promotealign/ -run '^$' -bench BenchmarkCacheSizes -benchtime 1x`.
Check: `nodes-B` and `nodes-ms` at both sizes recorded for the PR description.

**STEP-2 — Move the credibility SQL to a leaf.**
Files: `core/database/sourcecredibilitygrades/gradeorder/gradeorder.go` *(new)*, `core/database/sourcecredibilitygrades/registry.go`, `core/database/autoreconciler/autoreconciler.go`, `core/database/sources/records.go`, `core/database/sourcemove/sourcemove.go`, and each test that reads `sourcecredibilitygrades.DefaultKey` (`rg -n "sourcecredibilitygrades\.(DefaultKey|RelativeOrder)" core api`). Skill: `add-catalog-query`.
Do: move per Codebase fit; no behaviour change.
Check: `go list -deps ./core/database/sourcecredibilitygrades/gradeorder | grep provenencia` lists only `core/vocabkey` and itself; the `rg` finds nothing; `CGO_ENABLED=1 go test -tags fts5 ./core/database/...` passes.

**STEP-3 — The node carries provenance.**
Files: `core/database/graphcache/graph.go`, `load.go`, `verify.go`, `graph_test.go`, `core/database/graphcache/graphcachetest/graphcachetest.go` (`NewSource`, `SetRef`, the grade install).
Do: D-5. `OpenCatalog` also calls `sourcecredibilitygradestest.Install(c)`, so every grade exists. `Canon.NewSource` inserts a Source, Artifact, Evidence graph and Citation (`transcription_uncertain` from the argument), a `source_credibility_assessments` row (`id`, `source_id`, `credibility_grade_id` of the grade with that key, origin `provenencia`) when `grade` is not empty, and makes them the ones later Observations and members use. T-3.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/graphcache/...` passes, also with `PROVENENCIA_GRAPH_VERIFY=1`.

**STEP-4 — A module folds by the caller's rule.**
Files: `core/autoreconcile/modules.go`, `autoreconcile.go`, `modules_test.go`.
Do: Codebase fit rows for `keyModule.folds`, `validate`, `ReconcileHandles`; the `moduleFor` comment says subjects fold by the caller's rule (Rules this plan bends). T-1.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/autoreconcile/ ./core/database/autoreconciler/` passes.

**STEP-5 — One containment predicate, one link read, every link an owner.**
Files: `core/database/conclusionsummaries/compose.go`, `placechains.go`, `conclusionsummaries.go`, `placechains_test.go`.
Do: D-6 (`folds`, used by `FoldLocations`), D-9, and the fast path of D-7 inside a first `voteLocations` *(new)* in `core/database/conclusionsummaries/placevote.go` that both callers use; `FieldOwner` gains `Reason` and `Vote`; owners per D-11. `TestPersonRowOwners` case "a parent Place is not an owner" becomes "a parent Place is a folded owner": Yorkshire's link is a second owner after York's, `Reason` folded.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/conclusionsummaries/` passes, T-7's tests green with that one case changed.

**STEP-6 — Events vote their places.**
Files: `placevote.go`, `compose.go`, `eventplacevote_test.go` *(new)*.
Do: the vote path of D-1 – D-3, D-7, D-8, D-10, and D-15. T-4, T-5, T-8.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/conclusionsummaries/ ./core/database/conclusiondetails/` passes.

**STEP-7 — The sheet shows the vote.**
Files: `core/database/conclusiondetails/conclusiondetails.go`, `placerecords_test.go`.
Do: D-5's sheet half, D-12. T-6.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/conclusiondetails/` passes.

**STEP-8 — Re-project search.**
Files: `core/database/searchindex/searchindex.go`, `searchindex_test.go` (line 246), `core/search/handles_test.go` (line 385).
Do: D-13; both tests expect 13.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/searchindex/ ./core/search/...` passes.

**STEP-9 — Measure.**
Do: rerun STEP-1's benchmark, and `CGO_ENABLED=1 go test -tags fts5 ./core/database/promotealign/ -run TestLargeSourceBudgets -v` (`perf_test.go`).
Check: within § 6 Scale; the budgets pass; both figures in the PR description.

**STEP-10 — Version and docs.**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj` (all four `MARKETING_VERSION` lines) → 0.46.1; `docs/conclusion-reconciliation.md` (§ 7: the grouping policy and the subject row per Rules this plan bends; § 9: a derived place reconciles across the event's location links; § 11.1: the vote, the containment fold at the event's date, the shared-parent rule of AC-2.2, and that "one place per event" is decided in the vote until [`docs/ideas/one-bridge-cardinality.md`](../../../ideas/one-bridge-cardinality.md)); `docs/catalog-caches.md` (`nodes` row: members carry credibility, outcome rows certainty; the new `nodes-B`); `.agents/skills/add-match-rule/SKILL.md` (beside "The reconciler composes value compare under its own policy": a simple module may take a caller's fold rule, as the place vote's subject module does); `docs/deployment-plan/spike-16/completed.md`; `docs/deployment-plan/spike-16/deployment-plan.md` (update the S16-80 row's status); this plan (status). The version bump rides in this step's commit.
Do: per the Definition of done.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/ -run TestVersion` passes; `python3 scripts/check-plan-docs.py --links docs/conclusion-reconciliation.md docs/catalog-caches.md` reports no broken link.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/autoreconcile/modules_test.go` `TestReconcileHandles` *(new)* | Ids A, B, C; `folds(C, A)` and `folds(C, B)` true. A from S1–S3, B from S4 → A kept, support 3, merged; B outvoted `Vote{3, 4}` · A ×3 + C ×1 → one value A, support 4; C `folded` · A, B from S1, S2 → both kept, mixed, A first (earlier Observation id) · A credibility −1, B standard → A weak · C, A, B one Source each, A recorded first → C folds into A; B outvoted `Vote{2, 3}` · nil `folds`, A and C → two values, mixed · bad cardinality, a candidate with no `SubjectID` → the errors `Reconcile` returns | D-3, D-4, D-6, D-8 |
| T-2 | Go | `core/autoreconcile` existing tests | Every simple type with a nil `folds` reconciles as before | D-1 |
| T-3 | Go | `core/database/graphcache/graph_test.go` `TestNodeProvenance` *(new)* | `Canon` with `NewSource("low_trust", true)`, then a Location: the association's member has `Credibility` −1 and its `place` outcome row `Uncertain` true; a member under the first Source has 0 and false; `Verify` passes | D-5 |
| T-4 | Go | `core/database/conclusionsummaries/eventplacevote_test.go` `TestEventPlaceVote` *(new)* | Table on `Canon` with `NewSource`, each case checking `EventsByIDs` `Places`, `PersonsByIDs` `Birth.Places` and `Birth.Owners.Places` (order, `Reason`, `Vote`): AC-1.1 (`SetRef` gives England `PLC-A` and Swift Current `PLC-B`; the case fails on the old code) → [Swift Current], England owner last, `outvoted {3, 4}` · AC-1.2 → [Swift Current, England] when Swift Current's Location is written first, reversed when England's is · AC-1.3 → [England], Swift Current `weak` · AC-1.4 "one Source" → both · AC-2.1 → [Swift Current], parents Saskatchewan, Canada; Canada owner `folded` · AC-2.2 → [Swift Current], Toronto `outvoted {2, 3}`, Canada `folded` · AC-2.3 (`part_of` with `end_date` 1922 through `Canon.Date`, birth `date` 1950) → [Dublin], United Kingdom `outvoted {2, 3}` · AC-2.4 (birth 1900) → [Dublin], United Kingdom `folded` · "cycle": A `part_of` B and B `part_of` A, one Source each → both | AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-2.1, AC-2.2, AC-2.3, AC-2.4, D-6, D-7, D-8, D-11 |
| T-5 | Go | `eventplacevote_test.go` `TestEventPlaceVoteCap` *(new)* | 66 Locations to Swift Current and 5 to England, one Source each → the event reads the first 64 links in `Follow(event, hops.PlacesOfEvent)` order; the birth keeps 63 place owners and its date owner, each among those 64; a place with no link among them is not in `Places`; `PersonsByIDs` cold within `databasetest.WithinBudget` of one second | D-9 |
| T-6 | Go | `core/database/conclusiondetails/placerecords_test.go` `TestPlaceOwnersCarryTheVote` *(new)* | A helper `placedBirth(src sources.Source, toponym string, person, birth, place []byte) (personH, birthH, placeH []byte)` *(new)* files a person, a birth and a place with that toponym on `src`, links them, and promotes each onto the handle given (nil promotes a new one). Three Sources at Swift Current onto shared handles, a fourth at England (new place handle); the three Swift Current bridges file into one association (a bridge is filed by its ends), so the sheet has two owners → `placeRows`: England's outcome `outvoted`, `Vote{3, 4}`; the others `kept`. Canada variant → Canada's outcome `folded`, `ValueRank` 0. Low-trust variant → `weak`, `Provenance.Credibility` −1 | AC-3.1, AC-3.2, AC-3.3, D-5, D-12 |
| T-7 | Go | `placechains_test.go` `TestBirthLocationsFoldWhenPartOf`, `TestSiblingBirthPlacesStayCompetingUnderASharedParent`, `TestPersonRowOwners`; `eventplaces_cap_test.go` `TestCraftedEventPlaces`, `TestEventPlacesCapInputs`, `TestCraftedLifeOwners`; `TestPersonDerivedRows` | Green. Two changes: `TestPersonRowOwners` "a parent Place is not an owner" becomes "a parent Place is a folded owner" (STEP-5); `TestPersonDerivedRows` "graph queries do not grow with events and Places" gives the small Person a second place from the same Source (York and Town 0), so both Persons take the vote path and `smallN == bigN` still holds (D-15) | D-7, D-9, D-11, D-15 |
| T-8 | Go | `eventplacevote_test.go` `TestEventPlaceVoteFollowsEvidence` *(new)* | AC-1.2's world with England's Location first, read once ([England, Swift Current]); then England's Source assessed `low_trust` by SQL and `k.Commit` of England's association → `EventsByIDs` reads [Swift Current] | D-5 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `core/database/conclusionsummaries` (`TestPersonRowOwners` owner order), `TestPersonDerivedRows` query counts, `core/database/promotealign` `TestLargeSourceBudgets`.

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
- [ ] Domain doc updated if a rule in docs/*.md changed: conclusion-reconciliation.md § 9 and § 11.1; catalog-caches.md `nodes` row
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

The sweep covers "Contains folds, and no other relation does", `RelativeOrderColumn`, `RelativeOrderJoins`, `sourcecredibilitygrades.DefaultKey` and `eventPlaces`. The brief and copy lines do not apply.

## 10. Manual check

1. Open the dogfood project. Open the Person whose Birth place showed England (the screenshot of 2026-11-26). The row reads Swift Current with no Mixed badge.
2. Open its provenance sheet: four records from 2 Places, the Swift Current group first with its three records "kept", the England record "outvoted (3 of 4 Sources)".
3. Open the birth Event: its Place row reads Swift Current, not mixed. In the Events list the place column reads Swift Current with no +1.
4. Search for "England": that Person and birth are not hits through the place.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| The vote moves a lead a test elsewhere pins by ref | T-7's tests use one Source, where only the tiebreak changes |
| Reading association nodes on a list path slows lists | D-7; STEP-9 at Scale |
| A summary row cached before a credibility change keeps the old lead | T-8 |

**Stop and report if:**

- `FoldLocations`, `eventPlaces`, `eventLocations`, `lifeFacts` or `PersonDerivedRows` no longer match § 4.
- `graphcache` cannot import `gradeorder` without a cycle (STEP-2 check).
- A credibility or certainty write does not reload the association node, so T-8 fails without a new invalidation signal.
- `TestLargeSourceBudgets` fails, or `nodes-B` / `nodes-ms` exceed § 6 Scale.
- A T-7 test needs a changed expectation other than the two T-7 names or an order between places from one Source.
- The manual check's sheet does not list the England record, or lists it "kept".

## 12. Open questions

None.

## 13. PR

**Title:** S16-80 — An event's places reconcile by their records
**Body:** objective in one sentence; what shipped against each US; AC evidence; the `BenchmarkCacheSizes` and `TestLargeSourceBudgets` figures; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-80-event-place-vote.md`.
