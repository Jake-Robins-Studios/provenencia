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
**Skills to load:** [`add-catalog-query`](../../../../.agents/skills/add-catalog-query/SKILL.md) (the leaf SQL package, STEP-1)
**Rules that bind:** `.cursor/rules/go-tests.mdc`
**Context:** [`docs/conclusion-reconciliation.md`](../../../conclusion-reconciliation.md) §5 (the pipeline), §8 (cardinality), §9 (values reached through other entities), §11.1 (places: "Several Locations on one Event … fold into chains"; places that do not connect "reconcile like any other multi-valued or mixed field"); [`docs/catalog-caches.md`](../../../catalog-caches.md) (the `nodes` row); working rules "(Batch 2) Every cache names the signal that updates it, and updates exactly", "(Batch 2) Memory is budgeted", Spike 16 rule "Crafted fan-out is capped, not engineered"; the user's calls of 2026-11-26 recorded in § 5
**Planned:** 2026-11-26 against `origin/main` @ `7a1d15c`
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

When an event's records place it in different Places, the Place the event shows is the one its records support, by the same rules as any other single-valued field: a place that contains another linked place folds into it, then the Sources vote, then weak evidence drops. A birth that three Sources place in Swift Current and one in England shows Swift Current, merged, with the England record marked outvoted (3 of 4 Sources). A birth placed in Swift Current and in Canada shows Swift Current, with the Canada record marked folded.

**Why now.** Dogfood, 2026-11-26: a Person's Birth place showed England, mixed, over Swift Current, which three of four records named. Each event–place link reconciles only its own records, and `FoldLocations` orders the places left after folding by their ref (`PLC-6HH94` sorts before `PLC-PP6PW`). No step counts records across links, although § 11.1 of the reconciliation doc says it should.

**What stays.** Place-to-place (`part_of`, `succeeded_by`), person-to-event and person-to-person links keep every link: they are many-valued (user, 2026-11-26). Which birth or death event a Person's life row leads with (the earliest dated) is unchanged. An event whose places all fold into one, or that names one place, reads exactly as today.

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
| A leaf package holds the credibility-order SQL so the graph cache can read it | STEP-1 |
| Each outcome row on a canonical node carries its record's Source, credibility and transcription certainty | STEP-2, T-3 |
| Each bridge end declares its cardinality; the location bridge's place end is single | STEP-3, T-2 |
| The subject module folds by a rule its caller passes, through `autoreconcile.ReconcileHandles` | STEP-4, T-1 |
| An event's places, everywhere they are composed (Event rows, Person life rows, search rows), are its location links' records reconciled with containment folding at the event's date | STEP-5, T-4, AC-1.1 – AC-2.4 |
| A Person's place owners list every location link of the event, each with what the vote did to it | STEP-5, T-4 |
| The Birth and Death place sheets show each record's outcome from the vote | STEP-6, T-6, AC-3.1 – AC-3.3 |
| Search documents are re-projected on open | STEP-7 |
| Docs: reconciliation § 9 and § 11.1, catalog caches | STEP-8 |

| Out | Home |
| --- | --- |
| Which birth or death event a Person leads with when it has two (earliest date today) | not planned: § 9 asks the researcher to merge duplicate events; raise it as an idea if dogfood says otherwise |
| Reconciling `part_of`, `succeeded_by`, participation or relationship links | not planned: those ends are multiple (user, 2026-11-26) |
| "folded into Swift Current" in place of the plain "folded" on a link's record | not planned: the owner field holds the link's own values, not the event's; the plain phrase is what a gallery record says today |
| A Reconciliation Claim that concludes an event's place | the Reconciliation Claims work in [`conclusion-reconciliation.md`](../../../conclusion-reconciliation.md) § 8 (not scheduled) |
| `conclusiondetails` reading provenance off the outcome row in place of the per-graph records | not planned: its records read the Citation words anyway |
| Evidence graph event titles (`grapheventtitles` sorts a Subject's places by ref) | not planned: an Evidence graph is one Source's reading; nothing votes there |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Folding an event's places | `core/database/conclusionsummaries/placechains.go` `FoldLocations` | Drops a place that is an ancestor of another linked place at the date, then sorts the rest by `Entity.Ref`. The ref sort is the whole decision between places that do not contain each other |
| An event's places | `core/database/conclusionsummaries/compose.go` `eventPlaces` | Reads each link's place shell from the place graph and returns `FoldLocations`; called by `oneEvent` (Event rows) and `lifeFacts` (Person life rows). Reads no record of any link |
| Life owners | `compose.go` `lifeFacts` | Lists a place owner for each link whose place survived the fold; a folded ancestor's link (Canada) has no owner, so its records never reach the sheet |
| Owner type | `core/database/conclusionsummaries/conclusionsummaries.go` `FieldOwner` | `ID`, `PropertyID`, `Place`; no outcome |
| Caps | `compose.go` `maxLifeOwners` (64), `maxEventPlaces` (20), `eventLocations` | Bound owners and distinct places; links to one place are not bounded |
| Sheet rows | `core/database/conclusiondetails/conclusiondetails.go` `PersonDerivedRows` | Composes each owner's field from the association node's own outcomes, so every link's record reads "kept" |
| Outcome rows | `core/database/graphcache/graph.go` `Outcome`; `load.go` `loadOutcomes`; `verify.go` `sameOutcomes` | Observation, Subject, reason, ranks, vote; no Source and no provenance |
| Credibility SQL | `core/database/sourcecredibilitygrades/registry.go` `RelativeOrderColumn`, `RelativeOrderJoins`, `orderBound`, `DefaultKey` | Read by `core/database/autoreconciler/autoreconciler.go` `sqlLoadCandidates` and `core/database/sources/records.go`; `graphcache` cannot import this package (`core/database` imports `graphcache`, this package imports `core/database`) |
| Subject values | `core/autoreconcile/modules.go` `moduleFor` | Subject-valued Properties use `keyModule` keyed by `EntityID`; nothing folds |
| Bridge ends | `core/connectrules/connectrules.go` `Endpoint`, `productBridges`; `core/hops/hops.go` `Hop` | An end has a Property key and a type; no cardinality |
| Search | `core/database/searchindex/handles.go` `personLifeMatch`, `eventMatchSecondary`; `searchindex.go` `ProjectionVersion` (12) | Index every place in `Places` |
| Swift | `macos/App/Features/Conclusions/PersonDetailContent.swift` `rows`; `EventDetailContent.swift` `placeRow`; `macos/App/Platform/DerivedPlace.swift`; `macos/App/Platform/ReconciledValueDisplay.swift` `outcomePhrase` | Lead and mixed come from `places` (mixed when more than one); the shown owner is the lead place; "folded", "outvoted (N of M Sources)" and "weak · …" already render. No Swift change |
| Tests | `core/database/conclusionsummaries/placechains_test.go` `TestBirthLocationsFoldWhenPartOf`, `TestSiblingBirthPlacesStayCompetingUnderASharedParent`, `TestPersonRowOwners`; `eventplaces_cap_test.go` `TestCraftedEventPlaces`, `TestEventPlacesCapInputs`, `TestCraftedLifeOwners`; `core/database/conclusiondetails/placerecords_test.go` | All use one Source, so no vote reaches a majority and each stays green unchanged |
| Test builder | `core/database/graphcache/graphcachetest/graphcachetest.go` `Canon` | One Source, Artifact, graph and Citation behind every Observation |

**Precedent.** `dateModule` in `core/autoreconcile/dates.go` is the shape of a module with a fold rule: copy its `split` / `fold` / `assemble` layout. `core/database/scalarcols` is the leaf SQL package `graphcache` already imports: copy its shape for STEP-1. S16-42 (`ProjectionVersion` 12, "an Event's dating") is the precedent for re-projecting search when what a summary row carries changes.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | The location bridge's `place` end is single; every other end of every product bridge is multiple (user, 2026-11-26). The cardinality is declared on `connectrules.Endpoint` with `propertymeta` constants; an empty value reads as multiple, so a plugin bridge is many-valued unless it says otherwise | One declaration that a bridge reader asks, in the registry that already owns bridge ends | The `place` Property's own `cardinality`: that is per association (one link has one place end), not how many places an event has |
| D-2 | The vote runs in the summary composer, in memory, from each association node's outcome rows: one function, `voteLocations`, replaces `eventPlaces` for both callers | Event rows, life rows, search rows and the sheet then read one answer | The auto-reconciler (SQL side): it cannot fold, because containment needs the place graph at the event's date |
| D-3 | Candidates are the association's outcome rows on the `place` Property with `ValueRank` 1 (the records behind the link's place). `against` → `Negative`; `provisional` → `Provisional`; every other reason votes. The value is the link's neighbour (`SubjectID` and `EntityID`); `SourceID`, `Provenance` come off the row (D-5) | A link's records are exactly the rows that made its place; a record that voted for another place inside its own association is that association's business | Counting a whole association as one vote: two Sources behind one link are two Sources |
| D-4 | Strength counts: weak drop and stronger-first ranking apply across links as in any field (user, 2026-11-26) | Same rules as fields | Sources only — the user chose strength |
| D-5 | `graphcache.Outcome` gains the record's `SourceID`, `Credibility` and `Uncertain`, read in `loadOutcomes` with the same joins `sqlLoadCandidates` uses (citation → artifact → Source → assessment). The credibility SQL moves to a leaf package (Codebase fit) that `graphcache`, `autoreconciler` and `sources` import | The node already reloads on every write that changes them (`effects` Handles for credibility and certainty), so the vote stays exact with no new signal | Reading `sources.RecordsOf` in the composer: a whole read fails inside a write (`database.ErrWholeOnWrite`), where search re-projects summaries |
| D-6 | Folding is the pipeline's: `folds(from, into)` is `isAncestor(from, into, at) && !isAncestor(into, from, at)` on the event's place graph at the date `FoldLocations` uses (an event row's dating low end, else high; a life row's pick date). A place that could fold into several places folds into the one with the most Sources, then the best ranked (user, 2026-11-26) | One fold rule for names, dates and places; the cycle guard matches `FoldLocations` | Folding "into each" (a shared parent that breaks no tie): it would need a pipeline change for one module |
| D-7 | Fast path: when the hop's place end is not single, or `FoldLocations` leaves at most one place, no association node is read; each link's verdict is `kept` (its place survived) or `folded` (its place is covered). This equals the vote's result | With one survivor every other place is an ancestor that folds into it; the vote cannot outvote, weaken or deny a lone root | Always voting: it would load every association of every event on the list paths |
| D-8 | The places an event shows are the vote's displayed values in result order (support, then the best-ranked record: stronger provenance, then the earlier Observation). Outvoted and weak places leave `Places`, so the lead, the +N and the mixed badge follow with no Swift change. `FoldLocations` loses its ref sort; survivors keep link order | The order is the pipeline's; ref is never a reason | Ordering ties by ref, as I first told the user: the pipeline's last tiebreak is the earliest record, which is stable and means something |
| D-9 | The vote reads at most 64 links (`maxVotingLinks`, *new*, equal to `maxLifeOwners`) in link order. A place reached only by links past the cap is not shown and has no owner | Spike 16 rule "Crafted fan-out is capped, not engineered"; real events have one to three links | No cap: a crafted event with 10,000 links to two places would load 10,000 nodes per row |
| D-10 | `FieldOwner` gains `Reason` and `Vote`: what the vote did to that link (`kept`, `folded`, `outvoted`, `weak`; `denied` and `provisional` stay the association's own). A link's reason is that of its best-ranked candidate whose outcome is `kept`, `folded`, `outvoted` or `weak`; with none, `kept` | One verdict per link is enough: every record behind one link holds the same place, so the vote treats them alike | A reason per record: identical for every record of a link |
| D-11 | Life owners list every location link of each picked event, up to `maxLifeOwners`: the links to the shown places first (place order, then link order), then every other link in link order. Each owner's `Place` is its own neighbour's shell | The sheet lists every record (US-3); the shown group stays first, as `PVProvenanceSheetContent` expects | Listing only the shown places' links: the outvoted record would vanish |
| D-12 | `PersonDerivedRows` lays each place owner's verdict over its field: every outcome whose reason is `kept` or `folded` takes the owner's `Reason` and `Vote`; a `folded` verdict also sets `ValueRank` to 0, so the phrase is the plain "folded". Other reasons stay | The sheet already renders these reasons | A new FFI field: the existing outcome carries everything |
| D-13 | `ProjectionVersion` becomes 13, so Open re-projects every search document; an outvoted place no longer matches its event or person in search | A summary row's places changed meaning; S16-42 precedent | Leaving old documents to heal on the next write to each handle |
| D-14 | No `CacheVersion` bump: the auto-reconciler's own rows do not change | The vote is composed, never stored | — |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `core/database/gradeorder` *(new)* — `Column`, `Joins(sourceIDExpr string)`, `DefaultKey` | package | `sourcecredibilitygrades` `RelativeOrderColumn`, `RelativeOrderJoins`, `DefaultKey` | Moved, not copied: `graphcache` cannot import `sourcecredibilitygrades`. `sourcecredibilitygrades.DefaultKey` stays as `= gradeorder.DefaultKey` for its seed and `sourcemove` |
| `graphcache.Outcome.SourceID`, `.Credibility`, `.Uncertain` *(new)* | fields | `autoreconcile.Candidate.SourceID`, `.Provenance` | The node's row now carries what the reconciler weighed; same columns, same joins |
| `graphcachetest.(*Canon).NewSource(grade string, uncertain bool)` *(new)* | helper | `evidencelayertest.(*Records).NewSource` | `Canon` writes rows directly; it needs its current Source, Artifact, graph and Citation switched, and a grade assessment |
| `connectrules.Endpoint.Cardinality` *(new)* | field | `propertymeta.CardinalitySingle` / `CardinalityMultiple` on Properties | Reuses the constants; the field lives on the bridge end it describes |
| `hops.Hop.ToCardinality() string` *(new)* | func | `Hop.To()` | Reads the `To` end's `Cardinality` from `connectrules.LookupBridge`; empty reads as multiple |
| `autoreconcile.subjectModule` *(new)* | type | `keyModule` (subject case of `moduleFor`) | `keyModule` cannot fold; `subjectModule{folds}` with a nil `folds` behaves as `keyModule` did and replaces it for subjects |
| `autoreconcile.ReconcileHandles(candidates []Candidate, folds func(from, into []byte) bool, cardinality string) (Result, error)` *(new)* | func | `Reconcile` | `Reconcile` takes no fold rule and a value type; this is the subject module with the caller's rule, validated as `Reconcile` validates |
| `conclusionsummaries.voteLocations(in *graphcache.InputScope, v vocab, pg *placeGraph, at *datevalue.Value, locations []graphcache.Link) (placeVote, error)` *(new)*, `placeVote{places []ChainedPlace; links map[string]linkVerdict}` *(new)*, `linkVerdict{reason autoreconcile.Reason; vote autoreconcile.Vote}` *(new)*, `maxVotingLinks = 64` *(new)* — file `core/database/conclusionsummaries/placevote.go` *(new)* | func, types | `eventPlaces` | Replaces it (Deletes) |
| `FieldOwner.Reason`, `FieldOwner.Vote` *(new)* | fields | `conclusiondetails.Outcome.Reason`, `.Vote` | Same types; the owner carries its link's verdict to `PersonDerivedRows` |

**Builds on.** The shared pipeline (`pipeline.go`: fold, elect, dropWeak, orderRows) through a module, as names and dates do; the `connectrules` bridge registry; the place graph's `isAncestor` and `FoldLocations`; the node's outcome rows (S16-11); `InputScope.Node` for inputs.
**Deletes.** `eventPlaces` (both callers move to `voteLocations`); the `Entity.Ref` sort at the end of `FoldLocations`; `sourcecredibilitygrades.RelativeOrderColumn`, `RelativeOrderJoins` and `orderBound` (moved); `keyModule`'s use for `ValueTypeSubject` in `moduleFor` (the `keyModule` type stays for text, integer, boolean, depiction and term).
**Next adds.** A later single bridge end (an event's one date-bearing parent, a plugin's one-to-one link) is one `Cardinality` on its `Endpoint` and a `voteLocations`-shaped reader; the reconcile and fold need nothing new.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| An event with two or more surviving places now reads its location associations | `voteLocations` → `InputScope.Node` | A merged or missing association node is skipped (its link has no candidates and keeps the place it names only if another link votes for it); a node with no `place` rows gives no candidates |
| A place owner whose place is not shown (outvoted, weak, folded) | `PersonDerivedRows`; `PVProvenanceSheetContent.groups` | Swift already groups by owner place and puts the shown owner first; T-6 pins the reasons the group shows |
| `Places` shorter than the event's surviving places | `DerivedPlace`, `EventsListView`, `PersonLifeDisplay`, Timeline cards | They read the first place and count the rest; fewer is today's one-place case |

### Scale

At the map's Scale (one to three places per event; the S11-21 large fixture at 4,000 and 16,000 persons, 8,000 town events):

- **Lists and search.** The vote reads association nodes only for an event with two or more places after folding (D-7). The large fixture's events have one place each, so the Persons, Events and Places lists and `RowsForSearch` read no new node; `TestLargeSourceBudgets` stays inside its budgets unchanged.
- **Conflict path.** At most 64 association nodes per event (D-9), loaded in one `InputScope.Nodes` call before the loop. `TestCraftedEventPlaces` (20 unrelated places from one Source) now takes this path: 20 nodes, within its one-second budget.
- **Memory.** Each outcome row gains a 16-byte Source id, an int and a bool. `BenchmarkCacheSizes` `nodes-B` at 16,000 persons grows by less than 8 MB (S16-11 added 18.6 MB for the rows themselves).
- **Load.** `loadOutcomes` joins four tables by primary key per row; `nodes-ms` in the same benchmark grows by less than 25 %.
- **Fold.** The pipeline's fold is quadratic in distinct values; distinct places per event are at most 20 (`maxEventPlaces`).

### Edges

- **Assumptions.** `foldValues` follows folds through chains and picks one sink; `isAncestor` is bounded by `summaryChainDepth` and guards cycles, and D-6 adds the reverse check, so a cycle at the date keeps both places as roots (T-4 "cycle"). The pipeline's result does not depend on input order (`Reconcile` contract), so link order cannot move the lead.
- **Neighbors.** One place: unchanged (fast path). Places that all fold into one: unchanged `Places`; new owners for the folded links (AC-3.2). Two unrelated places from one Source: no majority, both shown, as today, but led by the earlier record instead of the lower ref (T-4 "one Source"). Siblings under a named parent from one Source: unchanged (`TestSiblingBirthPlacesStayCompetingUnderASharedParent`); from three Sources: the parent tips the tie (AC-2.2).
- **Removed inputs.** A Source regraded to low trust, a Citation marked uncertain, or a record removed reloads the association node (effects Handles), which drops the summary rows that read it through `NodeKey` (T-8). A deleted place leaves the link's `Neighbor` without a shell: no candidate and no owner, as today.
- **Real data.** No seed or table drives the rule; the cardinality registry has four product bridges and one single end.
- **Untrusted size.** Distinct places per event: 20 (`eventLocations`). Links read by the vote: 64 (D-9), checked before any node load. Records per link: the association's outcome rows, already loaded with the node; linear in the vote.

### Schema

None — no catalog change. The outcome rows' new fields are read from existing columns.

### Go core

| Package | Change |
| --- | --- |
| `core/database/gradeorder` *(new)* | `const DefaultKey = "standard"`, `const Column` (today's `RelativeOrderColumn`, its `orderBound` clamp unexported), `func Joins(sourceIDExpr string) string`. Imports `core/vocabkey` only |
| `core/database/sourcecredibilitygrades` | `DefaultKey = gradeorder.DefaultKey`; the SQL helpers go |
| `core/database/autoreconciler`, `core/database/sources` | Read `gradeorder.Column` / `gradeorder.Joins` |
| `core/database/graphcache` | `Outcome` gains `SourceID []byte`, `Credibility int`, `Uncertain bool`; `loadOutcomes` adds `LEFT JOIN citations c ON c.id = o.citation_id LEFT JOIN artifacts a ON a.id = c.artifact_id` and `gradeorder.Joins("a.source_id")`, selecting `a.source_id`, `gradeorder.Column`, `COALESCE(c.transcription_uncertain, 0)`; `sameOutcomes` compares the three |
| `core/connectrules` | `Endpoint.Cardinality string`; `productBridges`' location `place` end is `propertymeta.CardinalitySingle` |
| `core/hops` | `func (h Hop) ToCardinality() string`: the `To` end's `Cardinality`, `propertymeta.CardinalityMultiple` when empty |
| `core/autoreconcile` | `subjectModule{folds func(from, into []byte) bool}`: key `EntityID` (no id → no evidence, as `idKey`), `fold` calls `folds` when set, `outvotes` true, `oneValue` false, `assemble` the best-ranked member's value. `moduleFor` returns `subjectModule{}` for `ValueTypeSubject`. `ReconcileHandles` checks cardinality and `Carries(ValueTypeSubject, …)`, then runs `reconcile` with no concluded value |
| `core/database/conclusionsummaries` | `placevote.go`: `voteLocations` builds the raw places as `eventPlaces` did, folds them, takes the fast path (D-7) or reads the first 64 links' association nodes, builds candidates (D-3, D-5), calls `ReconcileHandles` with D-6's rule, and returns the displayed places in result order with each link's verdict (D-10). `oneEvent` and `lifeFacts` call it; `lifeFacts` builds owners per D-11 with `Reason` / `Vote`. `FoldLocations` drops its sort |
| `core/database/conclusiondetails` | `PersonDerivedRows` applies D-12 to place owners |
| `core/database/searchindex` | `ProjectionVersion = 13`, with the history line "13: an event's places are its location links' records reconciled (S16-80)." |

Errors: none new; a node read error returns as today.

### FFI

None — the outcome fields the sheet reads already cross; `FieldOwner`'s new fields stay in Go.

### macOS

None — no Swift change. The lead, the +N, the mixed badge, the shown owner and the outcome phrases all read data the engine now sends differently.

### Strings

None — every phrase exists (`conclusions.outcome.folded`, `…outvotedBy`, `…weakBecause`).

## 7. Steps

**STEP-1 — Move the credibility SQL to a leaf.**
Files: `core/database/gradeorder/gradeorder.go` *(new)*, `core/database/sourcecredibilitygrades/registry.go`, `core/database/autoreconciler/autoreconciler.go`, `core/database/sources/records.go`. Skill: `add-catalog-query`.
Do: move per Codebase fit; no behaviour change.
Check: `go list -deps ./core/database/gradeorder | grep provenencia` lists only `core/vocabkey` and itself; `CGO_ENABLED=1 go test -tags fts5 ./core/database/autoreconciler/ ./core/database/sources/ ./core/database/sourcecredibilitygrades/` passes.

**STEP-2 — Outcome rows carry their evidence.**
Files: `core/database/graphcache/graph.go`, `load.go`, `verify.go`, `graph_test.go`, `core/database/graphcache/graphcachetest/graphcachetest.go`.
Do: D-5; add `Canon.NewSource`: it inserts a Source, Artifact, Evidence graph and Citation (`transcription_uncertain` from the argument), an assessment with the grade of that key when `grade` is not empty, and makes them the ones later Observations and members use. T-3.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/graphcache/...` passes, with `PROVENENCIA_GRAPH_VERIFY=1` too.

**STEP-3 — Bridge ends declare cardinality.**
Files: `core/connectrules/connectrules.go`, `core/connectrules/connectrules_test.go`, `core/hops/hops.go`, `core/hops/hops_test.go` *(new)*.
Do: D-1. T-2.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/connectrules/ ./core/hops/` passes.

**STEP-4 — The subject module folds by the caller's rule.**
Files: `core/autoreconcile/modules.go`, `autoreconcile.go` (package doc: subjects fold by a caller's rule), `modules_test.go`.
Do: Codebase fit rows for `subjectModule` and `ReconcileHandles`. T-1.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/autoreconcile/ ./core/database/autoreconciler/` passes (subject-valued Properties unchanged).

**STEP-5 — Events vote their places.**
Files: `core/database/conclusionsummaries/placevote.go` *(new)*, `compose.go`, `placechains.go`, `conclusionsummaries.go`, `eventplacevote_test.go` *(new)*.
Do: D-2, D-3, D-6 – D-11. T-4, T-8.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/conclusionsummaries/` passes, the tests listed in § 4 unchanged.

**STEP-6 — The sheet shows the vote.**
Files: `core/database/conclusiondetails/conclusiondetails.go`, `placerecords_test.go`.
Do: D-12. T-6.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/conclusiondetails/` passes.

**STEP-7 — Re-project search.**
Files: `core/database/searchindex/searchindex.go`.
Do: D-13.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/searchindex/ ./core/search/...` passes.

**STEP-8 — Measure.**
Do: run `CGO_ENABLED=1 go test -tags fts5 ./core/database/promotealign/ -run '^$' -bench BenchmarkCacheSizes -benchtime 1x` on `main` and on the branch, and `CGO_ENABLED=1 go test -tags fts5 ./core/database/promotealign/ -run TestLargeSourceBudgets -v` on the branch.
Check: `nodes-B` and `nodes-ms` within § 6 Scale; the budgets pass. Both figures go in the PR description.

**STEP-9 — Docs.**
Files: `docs/conclusion-reconciliation.md` (§ 9: a derived place reconciles across the event's location links; § 11.1: the vote, the containment fold at the event's date, the shared-parent rule of AC-2.2, and that bridge ends declare cardinality with only the location's place end single), `docs/catalog-caches.md` (`nodes` row: outcome rows carry each record's Source and provenance; the new `nodes-B` figure), `completed.md`, `deployment-plan.md` (map row), this plan (status).
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py --links docs/conclusion-reconciliation.md docs/catalog-caches.md` reports no broken link.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/autoreconcile/modules_test.go` `TestReconcileHandles` *(new)* | Table, ids A, B, C; `folds(C, A)` and `folds(C, B)` true: A from S1–S3, B from S4 → A kept, support 3, state merged; B outvoted `Vote{3, 4}` · A ×3 + C ×1 → one value A, support 4; C `folded` · A, B from S1, S2 → both kept, mixed, A first (earlier Observation id) · A credibility −1, B standard → A weak, B kept · C, A, B one Source each, A recorded first → C folds into A; B outvoted `Vote{2, 3}` · nil `folds` with A, C → two values, mixed · bad cardinality and a candidate with no `SubjectID` → errors as `Reconcile` | D-3, D-4, D-6, D-8 |
| T-2 | Go | `core/hops/hops_test.go` `TestToCardinality` *(new)* | `PlacesOfEvent` → single; `EventsAtPlace`, `ParentsOfPlace`, `PartsOfPlace`, `SuccessorsOfPlace`, `PredecessorsOfPlace`, `EventsOfSubject`, `SubjectsOfEvent`, `ParticipantsOfEvent` → multiple; a registered test bridge with no cardinality → multiple | D-1 |
| T-3 | Go | `core/database/graphcache/graph_test.go` `TestOutcomeEvidence` *(new)* | `Canon` with `NewSource("low_trust", true)` then a Location: the node's `place` outcome row has that Source id, `Credibility` −1, `Uncertain` true; a record under the first Source has 0 and false; `Verify` passes | D-5 |
| T-4 | Go | `core/database/conclusionsummaries/eventplacevote_test.go` `TestEventPlaceVote` *(new)* | Table on `Canon`, each case checking `EventsByIDs` `Places`, `PersonsByIDs` `Birth.Places` and `Birth.Owners.Places` (order, `Reason`, `Vote`): AC-1.1 (England's place minted first so its ref sorts first) → [Swift Current], England owner last, `outvoted {3, 4}` · AC-1.2 → [Swift Current, England] when Swift Current's Location is written first, and reversed when England's is · AC-1.3 → [England], Swift Current `weak` · AC-1.4 "one Source" → both · AC-2.1 → [Swift Current] with parents Saskatchewan, Canada; Canada owner `folded` · AC-2.2 → [Swift Current], Toronto `outvoted {2, 3}`, Canada `folded` · AC-2.3 (`part_of` with `end_date` 1922 through `Canon.Date`, birth `date` 1950) → [Dublin], United Kingdom `outvoted {2, 3}` · AC-2.4 (birth 1900) → [Dublin], United Kingdom `folded` · "cycle": A `part_of` B and B `part_of` A, one Source each → both shown | AC-1.1 – AC-2.4, D-6, D-7, D-8, D-11 |
| T-5 | Go | `eventplacevote_test.go` `TestEventPlaceVoteCap` *(new)* | 66 Locations to Swift Current and 5 to England, one Source each → the Person's place owners are 64, each among the first 64 links in `Follow(event, hops.PlacesOfEvent)` order; a place with no link among them is not in `Places`; `PersonsByIDs` stays within `databasetest.WithinBudget` of one second, cold | D-9 |
| T-6 | Go | `core/database/conclusiondetails/placerecords_test.go` `TestPlaceOwnersCarryTheVote` *(new)* | Real write path: three Sources (`f.source`) each file a birth at Swift Current, a fourth at England, each Subject promoted onto the first Source's handles (`f.promote(s, onto)`) → `placeRows`: England's field outcome `outvoted`, `Vote{3, 4}`; the others `kept`. Canada variant → Canada's outcome `folded`, `ValueRank` 0. Low-trust variant (AC-1.3) → `weak`, `Provenance.Credibility` −1 | AC-3.1, AC-3.2, AC-3.3, D-12 |
| T-7 | Go | `core/database/conclusionsummaries/placechains_test.go` `TestBirthLocationsFoldWhenPartOf`, `TestSiblingBirthPlacesStayCompetingUnderASharedParent`, `TestPersonRowOwners`; `eventplaces_cap_test.go` `TestCraftedEventPlaces`, `TestEventPlacesCapInputs`, `TestCraftedLifeOwners` | Unchanged, green | D-7, D-11 |
| T-8 | Go | `eventplacevote_test.go` `TestEventPlaceVoteFollowsEvidence` *(new)* | AC-1.2's world with England's Location written first, read once ([England, Swift Current]); then the England Source's assessment set to `low_trust` by SQL and `k.Commit` of England's association → the next `EventsByIDs` reads [Swift Current] (the cached row was dropped through the association's `NodeKey`) | D-5 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `core/database/conclusionsummaries` (owner order in `TestPersonRowOwners`), `core/database/searchindex` (a test that pins `ProjectionVersion`), `core/database/promotealign` `TestLargeSourceBudgets`.

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

The sweep covers `RelativeOrderColumn`, `RelativeOrderJoins` and `eventPlaces`. The brief and copy lines do not apply (no brief, no copy).

## 10. Manual check

1. Open the dogfood project. Open the Person whose Birth place showed England (the screenshot of 2026-11-26). The row reads Swift Current with no Mixed badge.
2. Open its provenance sheet: four records from 2 Places, the Swift Current group first with its three records "kept", the England record "outvoted (3 of 4 Sources)".
3. Open the birth Event: its Place row reads Swift Current, not mixed. In the Events list the place column reads Swift Current with no +1.
4. Search for "England": that Person and birth are not hits through the place.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| The vote moves a lead that a test elsewhere pins by ref | T-7 lists the tests that read places; each uses one Source, where only the tiebreak changes |
| Reading association nodes on a list path slows lists | D-7 fast path; STEP-8 measures the large fixture |
| A summary row cached before a credibility change keeps the old lead | T-8 |

**Stop and report if:**

- `FoldLocations`, `eventPlaces`, `lifeFacts` or `PersonDerivedRows` no longer match § 4.
- `graphcache` cannot import `gradeorder` without a cycle (STEP-1 check fails).
- A credibility or certainty write does not reload the association node, so T-8 fails without a new invalidation signal.
- `TestLargeSourceBudgets` fails, or `nodes-B` / `nodes-ms` exceed § 6 Scale.
- Any test in T-7 needs a changed expectation other than an order between places from one Source.
- The sheet in the manual check does not show the England record or shows it "kept": the Swift grouping reads something D-11 / D-12 does not set.

## 12. Open questions

None.

## 13. PR

**Title:** S16-80 — An event's places reconcile by their records
**Body:** objective in one sentence; what shipped against each US; AC evidence; the `BenchmarkCacheSizes` and `TestLargeSourceBudgets` figures; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-80-event-place-vote.md`.
