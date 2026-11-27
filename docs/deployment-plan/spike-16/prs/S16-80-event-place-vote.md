# S16-80 — An event's places reconcile by their records

**Status:** Landed in [#1007](https://github.com/Jake-Robins-Studios/provenencia/pull/1007) (2026-11-27)
**Landed:** As planned, except: the version is 0.48.3, since main was already at 0.48.2 when the PR was cut; `eventFoldDate` takes the event's `valuecompare.Dating`, which the new `eventDating` computes once, in place of the node and vocabulary; `FoldLocations` takes the places' subject values as an argument, and `finishVote` takes the vocabulary to name the place Property; `placePrep` carries the fold's survivors, the subject values and the place graph for `finishVote`; `lifeEvents` and `placesOfEvents` are deleted with their last callers; a displayed place the fold dropped (a container whose contained place has no record) is built from its shell by `placePrep.place`. Review round 1 added: `valuecompare.FoldsInto` (and `FoldsResult`, for the name fold that also reads the Detail) is the one fold-on-Contains check the reconciler, the name fold and `FoldLocations` share; `autoreconcile.RanksBefore` is the pipeline's candidate order, which `finishVote` reads for a link's verdict; `placePrep.vote` is a pointer, non-nil when `prepareVote` decided; `finishVote` maps each node's members once (`memberOf` is deleted); `searchindex.ReprojectChanged` also reprojects the rows composed from a written event place association's own values, moved or not, so an outvoted place leaves search on the write that outvoted it.
**Spike / slice:** Spike 16 · Slice 6k — Event places by evidence
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: the life rows, the Event page's Place row and the provenance sheet draw what they draw today; only which place leads, the mixed badge and each record's outcome words change, and every outcome phrase already exists)
**Board:** —
**Depends on:** —
**Blocks:** S15-28 (Spike 15)
**Branch:** `s16-80-event-place-vote`
**Version bump:** patch — a bugfix in which place an event shows, with no schema or wire change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-match-rule`](../../../../.agents/skills/add-match-rule/SKILL.md) (all of it: the comparer, its knob, its cause code), [`add-catalog-query`](../../../../.agents/skills/add-catalog-query/SKILL.md) (the leaf SQL package)
**Rules that bind:** `.cursor/rules/go-tests.mdc`
**Context:** [`docs/conclusion-reconciliation.md`](../../../conclusion-reconciliation.md) §5 (the pipeline), §7 (grouping policy, S11-06), §9 (values reached through other entities), §11.1 (places); [`docs/matching-model.md`](../../../matching-model.md) (value types, knob inventory); [`docs/catalog-caches.md`](../../../catalog-caches.md) (the `nodes` row); [`docs/ideas/one-bridge-cardinality.md`](../../../ideas/one-bridge-cardinality.md); working rules "(Batch 2) Every cache names the signal that updates it, and updates exactly", "(Batch 2) Memory is budgeted", Spike 16 rule "Crafted fan-out is capped, not engineered"; the user's calls of 2026-11-26 in § 5
**Planned:** 2026-11-26 against `origin/main` @ `4d0bb5f`
**Review:** [`S16-80-event-place-vote.review.md`](S16-80-event-place-vote.review.md) — Fits with changes · Ready with changes, 3 rounds; To user answered (2026-11-26)

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

The PR builds this from the existing layers, not a branch for places: value compare learns to compare subject values (the comparer slot it always reserved), the reconciler folds subjects on value compare's `Contains` as it folds dates, and a Place's containment at the event's date rides on the value as data.

**Why now.** Dogfood, 2026-11-26: a Person's Birth place showed England, mixed, over Swift Current, which three of four records named. Each event–place link reconciles only its own records, and `FoldLocations` orders the places left after folding by their ref (`PLC-6HH94` sorts before `PLC-PP6PW`). No step counts records across links, although § 11.1 of the reconciliation doc says it should.

**What stays.** Place-to-place (`part_of`, `succeeded_by`), person-to-event and person-to-person links keep every link: they are many-valued (user, 2026-11-26). Which birth or death event a Person's life row leads with (the earliest dated) is unchanged. Promote's matching is unchanged. Subject-valued Properties other than an event's place reconcile exactly as today. An event whose places all fold into one, or that names one place, shows the same place as today.

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
| Value compare compares subject values by entity and by the containment the value carries, with a registry knob and a cause code; the reconciler folds subjects on `Contains` through the shared simple module | STEP-4, T-1, T-2 |
| The place graph builds a place's subject value at a date; `FoldLocations` folds with value compare | STEP-5 |
| An event reads at most 64 location links, everywhere its places are read | STEP-5, T-5 |
| A Person's place owners list every location link of the event, each with what the vote did to it | STEP-5, STEP-6, T-4 |
| An event's places, everywhere they are composed (Event rows, Person life rows, search rows), are its location links' records reconciled at the event's date | STEP-6, T-4, AC-1.1 – AC-2.4 |
| Every derived row's sheet lays its owners' verdicts over their records, and every sheet reads a record's provenance off the node | STEP-7, T-6, AC-3.1, AC-3.2, AC-3.3 |
| Search documents are re-projected on open | STEP-8 |
| Version 0.48.1; docs: reconciliation § 7, § 9, § 11.1; matching model; catalog caches; add-match-rule | STEP-10 |

| Out | Home |
| --- | --- |
| A declaration of "one place per event" that matching also reads; matching filling `Within` | [`docs/ideas/one-bridge-cardinality.md`](../../../ideas/one-bridge-cardinality.md) (user, 2026-11-26) |
| Which birth or death event a Person leads with when it has two (earliest date today) | [`docs/ideas/one-bridge-cardinality.md`](../../../ideas/one-bridge-cardinality.md) open question; § 9 asks the researcher to merge duplicate events |
| Reconciling `part_of`, `succeeded_by`, participation or relationship links | not planned: those ends are multiple (user, 2026-11-26) |
| "folded into Swift Current" in place of the plain "folded" on a link's record | not planned: the owner field holds the link's own values, not the event's; the plain phrase is what a gallery record says today |
| A Reconciliation Claim that concludes an event's place | the Reconciliation Claims work in [`conclusion-reconciliation.md`](../../../conclusion-reconciliation.md) § 8 (not scheduled) |
| Evidence graph event titles (`grapheventtitles` sorts a Subject's places by ref) | not planned: an Evidence graph is one Source's reading; nothing votes there |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Folding an event's places | `core/database/conclusionsummaries/placechains.go` `FoldLocations`, `isAncestor` | Drops a place when `isAncestor(id, other, at) && !isAncestor(other, id, at)`, then sorts the rest by `Entity.Ref`. The ref sort is the whole decision between places that do not contain each other. `isAncestor` has no other caller |
| An event's places | `core/database/conclusionsummaries/compose.go` `eventPlaces` | Reads each link's place shell and returns `FoldLocations`; called by `oneEvent` (date: `keptDateAt` ×3 → `valuecompare.DatingOf`, `Low` else `High`) and `lifeFacts` (`lifePick.date`). Reads no record of any link |
| An event's links | `compose.go` `eventLocations` | "The one read of an event's places": keeps every link whose place is among the first `maxEventPlaces` (20) distinct places; links to one place are not bounded |
| Person composition | `compose.go` `composePersons`, `onePerson`, `lifeFacts`, `maxLifeOwners` (64, date and place owners together) | `lifeFacts` reads each pick's locations itself; a place owner for each link whose place survived the fold, so a folded ancestor's link (Canada) has no owner |
| Owner type | `core/database/conclusionsummaries/conclusionsummaries.go` `FieldOwner` | `ID`, `PropertyID`, `Place`; no outcome |
| Sheet rows | `core/database/conclusiondetails/conclusiondetails.go` `PersonDerivedRows` | Composes each owner's field from the association node's own outcomes, so every link's record reads "kept" |
| Sheet provenance | `conclusiondetails.go` `(*recordReader).outcome` | `Provenance` from the Source record's `Credibility` and the per-graph Observation's `TranscriptionUncertain` |
| Node evidence | `core/database/graphcache/graph.go` `Member`, `Outcome`; `load.go` `loadMembers`, `loadOutcomes`; `verify.go` `sameMembers`, `sameOutcomes` | A member has its Subject's Source and graph; an outcome row has no provenance |
| Credibility SQL | `core/database/sourcecredibilitygrades/registry.go` `DefaultKey`, `orderBound`, `RelativeOrderColumn`, `RelativeOrderJoins` | Read by `core/database/autoreconciler/autoreconciler.go`, `core/database/sources/records.go`, `core/database/sourcemove/sourcemove.go`. `graphcache` cannot import this package (`core/database` imports `graphcache`, this package imports `core/database`) |
| Value compare | `core/valuecompare/valuecompare.go` `comparers`, `Value`, the `Cause` list; `core/matchregistry/value.go`; `core/matchregistry/guard_test.go` `layerPackages` | No subject comparer; layer packages hold no number but 0 and 1, so a similarity is a registry knob (text's `Contains` reads `value.Text.Partial`) |
| Value compare tests | `core/valuecompare/valuecompare_test.go` `TestCompareUnsupported` (`noComparer` holds only subject); `contract_test.go` `TestComparerContract`; `core/propertycompare/propertycompare_test.go` case "AC-1.10 unsupported value type" (uses `ValueTypeSubject`, expects `CauseUnsupported`) | Subject is the only unsupported type the tests use |
| Reconciler modules | `core/autoreconcile/modules.go` `keyModule`, `moduleFor`, `compareValue`; `dates.go` `dateModule.fold` | Subjects use `keyModule` keyed by `EntityID` and never fold; `dateModule.fold` is the one "fold on `Contains`, broader side first" check |
| Matching's conversion | `core/subjectprofile/subjectprofile.go` `Value` | The one conversion into layer 2; copies no `EntityID`, so subject values stay `Unknown` in matching |
| Search | `core/database/searchindex/searchindex.go` `ProjectionVersion` (12), pinned by `searchindex_test.go` (line 246) and `core/search/handles_test.go` (line 385) | Documents index every place in `Places` |
| Swift | `macos/App/Features/Conclusions/PersonDetailContent.swift` `rows`; `EventDetailContent.swift` `placeRow`; `macos/App/Platform/DerivedPlace.swift`; `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheetContent.swift` `derived`; `macos/App/Platform/ReconciledValueDisplay.swift` `outcomePhrase` | Lead and mixed come from `places`; the sheet groups owners by place, shown place first; "folded" (`valueRank` 0), "outvoted (N of M Sources)" and "weak · …" render. No Swift change |
| Tests | `core/database/conclusionsummaries/placechains_test.go` `TestBirthLocationsFoldWhenPartOf`, `TestSiblingBirthPlacesStayCompetingUnderASharedParent`, `TestPersonRowOwners`, `TestPersonDerivedRows`; `eventplaces_cap_test.go` `TestCraftedEventPlaces`, `TestEventPlacesCapInputs`, `TestCraftedLifeOwners`; `core/database/conclusiondetails/placerecords_test.go` | All use one Source, so no vote reaches a majority |
| Test builders | `core/database/graphcache/graphcachetest/graphcachetest.go` `OpenCatalog`, `Canon`; `placerecords_test.go` `birthAt` | `OpenCatalog` installs no credibility grades; `Canon` has one Source, Artifact, graph and Citation, refs `TST-n` compared as strings; `birthAt` promotes fresh handles each call |
| Version | `VERSION`, `core/version.go` `Version`, `macos/Provenencia.xcodeproj/project.pbxproj` `MARKETING_VERSION` (four lines: app and tests, Debug and Release) | 0.48.0; `core/version_test.go` `TestVersion` |

**Precedent.** `valuecompare.date` and `dateModule` are a comparer with `Contains` and a module that folds on it. `value.Text.Partial` is the knob a `Contains` similarity reads. `core/database/scalarcols` is the leaf SQL package `graphcache` already imports. S16-42 bumped `ProjectionVersion` when a summary row's content changed.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | The vote reconciles with `propertymeta.CardinalitySingle`, a constant with `// decided: user, 2026-11-26: an event has one place; one declaration with matching waits on docs/ideas/one-bridge-cardinality.md` | Matching's `One` is the one cardinality declaration; location joins it once matching reads containment (user, 2026-11-26) | A `connectrules` field (a second declaration); location in `One` now (Promote would score Canada vs Swift Current as a conflict) |
| D-2 | The vote runs in the summary composer, in memory, from each association node's outcome rows, for Event rows and life rows alike | Event rows, life rows, search rows and the sheet read one answer | The auto-reconciler: containment needs the place graph at the event's date |
| D-3 | A link's candidates are its association's outcome rows on the `place` Property with `ValueRank` 1 and reason `kept` or `folded`, one per row: `ObservationID` the row's; `Value{SubjectID: link.Neighbor, EntityID: link.Neighbor, Within: …}` (D-6); `SourceID` the member's, found by the row's `SubjectID`; `Provenance{Credibility: member's, Uncertain: row's}`. A row with no `SubjectID` or no matching member is skipped. Denied, provisional and negative rows do not vote again. Rank 1 is the link's place: a link is read from its association's rank-1 kept value (`graphcache` `linkLoadSQL`) | They are the records that made the link's place; the link's own reconcile already decided the rest | One vote per association: two Sources behind one link are two Sources |
| D-4 | Strength counts: weak drop and stronger-first ranking apply across links as in any field (user, 2026-11-26) | Same rules as fields | Sources only |
| D-5 | A Source's credibility lives on `graphcache.Member` (one join in `loadMembers`), a Citation's transcription certainty on `graphcache.Outcome` (one join in `loadOutcomes`). The vote and every sheet weigh a record from these; the sheet's grade label (`CredibilityKey`) stays the Source record's | The node reloads on every credibility and certainty write (`effects` Handles), so neither needs a new signal | `sources.RecordsOf` in the composer: a whole read fails inside a write (`database.ErrWholeOnWrite`), where search re-projects summaries |
| D-6 | Containment is data on the value, and value compare is its one rule. `valuecompare.Value` gains `Entity` and `Within` (the entities that contain `Entity` at the value's date; a set: order is not part of the contract). The subject comparer: no `Entity` → `Unknown`, `CauseEmpty`; the same `Entity` → `Same`, similarity 1, `CauseExact`; one side's `Entity` in the other's `Within` and not the reverse → `Contains`, similarity `Rules.Subjects.Partial` (*new* knob, 0.7, as `value.Text.Partial`), `Broader` the container, `CauseWithin` (*new* cause `"within"`); anything else, a cycle included → `Different`, similarity 0, `CauseNoMatch`. `Key` at `Same` and `Equivalent` is the entity. `(*placeGraph).subjectValue(id, at) valuecompare.Value` *(new)* is the one builder: `Within` is the place graph's walk up `part_of` holding at `at`, within `summaryChainDepth`, at most `maxWithin` (256, *new*) entities, nearest first. A place outside the graph has an empty `Within` | One containment rule, in the layer that owns "how two values relate", pure; matching fills `Within` the same way later | A fold rule the caller passes the reconciler (a second fold policy); containment in `Rules` (it is per value and per date, not per catalog) |
| D-7 | The reconciler folds subjects through the shared simple module: `keyModule` gains `folds bool` and keeps the compare value in `unit.data`; `foldsOnContains(rules, from, into unit) bool` *(new)* is the one "`Contains`, `from` broader" check, used by `dateModule.fold` and by `keyModule` when `folds` is set. `moduleFor` returns `keyModule{…, folds: true}` for subjects. A subject value with no `Within` never folds, as today | S11-06 "fold on `Contains`" written once; the next type that folds by containment is one `moduleFor` entry | A `subjectModule` type: `keyModule` plus a copy of `dateModule.fold` |
| D-8 | One fold date per event: `eventFoldDate(n *graphcache.Node, v vocab) *datevalue.Value` *(new)*, today's `oneEvent` choice, for Event rows; `lifePick.date` for life rows (unchanged). The vote has two halves: `prepareVote(pg, at, locations) placePrep` *(new)* builds each linked place's subject value, folds with value compare, and either finishes the vote (at most one survivor: each link `kept`, or `folded` when value compare reads its place as `Contains`-broader than the survivor) or lists every link's association id; `finishVote(in, prep, …) (placeVote, error)` *(new)* reads those nodes and reconciles. `FoldLocations` is `prepareVote`'s fold | The vote's trigger, date and fold are each decided once; with one survivor the full vote's result is the same, since every other place folds into it and D-3 gives the vote no negative | A separate `conflictLinks` pre-pass that folds a second time |
| D-9 | `composePersons` and `composeEvents` run `prepareVote` for every row's events first (the Person's pick locations read once through its own scope and passed on to `onePerson` and `lifeFacts`), load every listed association in one `Graph.Nodes` call, then compose rows with `finishVote`, which reads them through `InputScope.Node` (recording the inputs) | A sheet's graph queries do not grow with how many events conflict | A `Nodes` call per event |
| D-10 | The places an event shows are the vote's displayed values in result order (support, then the best-ranked record: stronger provenance, then the earlier Observation). They are `FoldLocations`' own survivors, reused with their `Parents`. Outvoted and weak places leave `Places`, so the lead, the +N and the mixed badge follow with no Swift change. The `Entity.Ref` sort goes in STEP-6, with the vote | The order is the pipeline's; ref is never a reason | Ordering ties by ref |
| D-11 | `eventLocations` keeps at most `maxLifeOwners` links in link order, before its distinct-place cap | It stays "the one read of an event's places"; Spike 16 rule "Crafted fan-out is capped, not engineered" | A separate cap inside the vote |
| D-12 | `FieldOwner` gains `Reason` and `Vote`: what a vote did to that owner (`kept`, `folded`, `outvoted`, `weak`); empty when no vote ran. A link's verdict is the outcome of its best-ranked candidate (stronger `Provenance`, then the earlier `ObservationID`). Life owners list every location link of each picked event up to `maxLifeOwners` with the date owners: the shown places' links first (place order, then link order), then every other link in link order, each with its own neighbour's shell as `Place`. A link with no verdict (association node missing, or no shell) has no owner | The sheet lists every record (US-3); `PVProvenanceSheetContent.derived` puts the shown group first | Only the shown places' links |
| D-13 | `conclusiondetails.ownerVerdict(owner conclusionsummaries.FieldOwner, f *Field)` *(new)* lays an owner's verdict over its field: with `Reason` set, every outcome whose reason is `kept` or `folded` takes the owner's `Reason` and `Vote`, and `folded` sets `ValueRank` 0 (plain "folded"); with `Reason` empty it changes nothing. `PersonDerivedRows` calls it for every owner. S15-28's records read for a derived row takes the Person and the row kind and calls it too (both maps) | One function, no owner-kind branch; a later vote over date owners needs no change here | A place-only call; an exported verdict read by association (it would re-run the vote at a date the Person row did not use) |
| D-14 | `ProjectionVersion` becomes 13: Open re-projects every search document, and an outvoted place stops matching | A summary row's places changed meaning; S16-42 precedent | Old documents healing on the next write |
| D-15 | No `CacheVersion` bump | Subject grouping keys on the entity exactly as `idKey` did, and no stored row changes | — |

**Rules this plan bends.**

- **`add-match-rule` "Catalog data comes in through `Rules`".** `Within` is catalog-derived context that rides on the value, because it holds per value and per date. Why: containment at a date cannot be a catalog-wide table. User's answer: accepted, 2026-11-26. STEP-10 rewrites the line: catalog tables come through `Rules`; per-value context the caller derives at the value's date (a subject's `Within`) rides on the value.
- **§ 7 "Terms, subjects and depictions keep their catalog identity" and the subject row's Fold "none" (S11-06).** Subjects still group by identity and now fold on `Contains` when their value carries `Within`. User's answer: 2026-11-26, a place that contains another linked place folds into it (Canada into Swift Current). STEP-10 rewrites the sentence and the row.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `core/database/sourcecredibilitygrades/gradeorder` *(new)*: `DefaultKey`, `Column`, `Joins(sourceIDExpr string)` | package | `sourcecredibilitygrades` `DefaultKey`, `RelativeOrderColumn`, `RelativeOrderJoins` | Moved so `graphcache` can import it; one `DefaultKey`, no alias |
| `graphcache.Member.Credibility`, `graphcache.Outcome.Uncertain` *(new)* | fields | `autoreconcile.Provenance` | D-5 |
| `graphcachetest.(*Canon).NewSource(grade string, uncertain bool)`, `(*Canon).SetRef(id []byte, ref string)` *(new)* | helpers | `evidencelayertest.(*Records).NewSource` | `Canon` writes rows directly; refs compare as strings (`TST-12` < `TST-6`) |
| `valuecompare.Value.Entity`, `.Within`; `subject` comparer; `CauseWithin`; `SubjectRules{Partial}` and `Rules.Subjects` *(new)* | fields, comparer, cause, knob | `date` comparer, `TextRules.Partial` | D-6; the comparer slot `noComparer` reserved |
| `autoreconcile.Value.Within`; `keyModule.folds`; `foldsOnContains` *(new)* | field, field, func | `dateModule.fold` | D-7 |
| `(*placeGraph).subjectValue`, `maxWithin` *(new)* | method, const | `isAncestor` | The one upward walk; `isAncestor` goes |
| `eventFoldDate`, `prepareVote`, `finishVote`, `placePrep`, `placeVote{places []ChainedPlace; links map[string]FieldOwner}` *(new)*, in `core/database/conclusionsummaries/placevote.go` *(new)* | funcs, types | `eventPlaces` | D-8; replaces it |
| `FieldOwner.Reason`, `FieldOwner.Vote` *(new)* | fields | `conclusiondetails.Outcome.Reason`, `.Vote` | D-12 |
| `conclusiondetails.ownerVerdict` *(new)* | func | `PersonDerivedRows` loop | D-13 |

**Builds on.** Value compare's comparer slot and contract; the knob registry and inventory; the shared pipeline through `keyModule`, as dates fold; the place graph's `part_of` walk; the node's outcome rows and members (S16-11); `InputScope.Node` for inputs.
**Deletes.** `eventPlaces`; `isAncestor` (its one caller folds with value compare); the `Entity.Ref` sort in `FoldLocations`; `sourcecredibilitygrades.DefaultKey`, `RelativeOrderColumn`, `RelativeOrderJoins`, `orderBound` (moved); `dateModule.fold`'s inline check (now `foldsOnContains`); the subject entry of `noComparer`; `(*recordReader).outcome`'s provenance from the Source record and per-graph Observation.
**Next adds.** [`docs/ideas/one-bridge-cardinality.md`](../../../ideas/one-bridge-cardinality.md): matching fills `Within` from the same `subjectValue`, location joins `One`, and the vote reads it in place of D-1's constant. A later vote over date owners sets `FieldOwner.Reason` and the sheet follows through `ownerVerdict`.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| An event with two or more surviving places reads its location associations | `finishVote` → `InputScope.Node` | A missing or merged association node gives no candidates; a place with no candidate is not shown |
| A subject value with `Entity` set reaches value compare | `valuecompare.Compare`, `Key` | Matching never sets `Entity` (`subjectprofile.Value`), so its subject values stay `Unknown`; a doc comment there says so until the idea's step 2 |
| A place owner whose place is not shown | `PersonDerivedRows`; `PVProvenanceSheetContent.derived` | Swift groups by owner place with the shown owner first; T-6 pins the reasons |
| `Places` shorter than the event's surviving places | `DerivedPlace`, `EventsListView`, `PersonLifeDisplay`, Timeline cards | They read the first place and count the rest |

### Scale

At the map's Scale (one to three places per event; the S11-21 large fixture at 4,000 and 16,000 persons):

- **Lists and search.** Association nodes are read only for an event whose places do not all fold into one (D-8). The large fixture's events have one place each, so lists and `RowsForSearch` read no new node.
- **Conflict path.** At most 64 association nodes per event (D-11), with every other conflicting event's in one `Graph.Nodes` call per composition (D-9). `TestCraftedEventPlaces` (20 unrelated places from one Source) takes this path within its one-second budget.
- **Memory and load.** `Member` gains an int, `Outcome` a bool; `BenchmarkCacheSizes` `nodes-B` at 16,000 persons grows by less than 2 MB and `nodes-ms` by less than 15 %.
- **Fold.** The pipeline's fold compares every pair of an event's distinct places (at most 20); each comparison scans two `Within` lists of at most 256.

### Edges

- **Assumptions.** `foldValues` follows folds through chains and picks one sink; a cycle at the date reads as `Different`, so both places stay (T-4 "cycle"). `Reconcile`'s result does not depend on input order. `TestComparerContract` holds for the subject comparer (symmetric cause, `Same` = 1, `Different` = 0, `Contains` strictly between, `Key` agreeing with `Compare`).
- **Neighbors.** One place: unchanged. Places that all fold into one: unchanged `Places`, new owners for the folded links (AC-3.2). Two unrelated places from one Source: both shown, led by the earlier record instead of the lower ref. Two links to one place from one Source count as one Source. Siblings under a named parent from one Source: unchanged; from three Sources the parent tips the tie (AC-2.2). A subject-valued Property with no `Within`: unchanged.
- **Removed inputs.** A regraded Source, a Citation marked uncertain or a removed record reloads the association node (effects Handles), dropping the summary rows that read it through `NodeKey` (T-8). A deleted place has no shell: no candidate, no owner, as today.
- **Source of a record.** The member's Source equals the reconciler's (`artifacts.source_id` of the record's Citation): `observations` requires a Citation on its Subject's graph, and a Source move (S15-24) moves both.
- **Real data.** No table or seed drives the rule.
- **Untrusted size.** Links per event: 64, then distinct places: 20 (`eventLocations`, before any read). `Within`: 256 entities within depth 8 (a dense `part_of` mesh). Records per link: the association's outcome rows, already on the node.

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/sourcecredibilitygrades/gradeorder` *(new)* | Imports `core/vocabkey` only; every caller and test of the moved names reads it |
| `core/database/graphcache` | `loadMembers` adds `gradeorder.Joins("s.source_id")` and selects `gradeorder.Column`; `loadOutcomes` adds `LEFT JOIN citations c ON c.id = o.citation_id` and selects `COALESCE(c.transcription_uncertain, 0)`; `sameMembers` and `sameOutcomes` compare them |
| `core/valuecompare`, `core/matchregistry` | D-6. The comparer in `core/valuecompare/subject.go` *(new)*; `SubjectRules` in `rules.go`; `Subjects: SubjectRules{Partial: 0.7}` in `matchregistry/value.go` with `// estimate: as value.Text.Partial` |
| `core/autoreconcile` | D-7; `compareValue` passes `Entity: EntityID` and `Within` |
| `core/subjectprofile` | A comment on `Value`: it leaves `Entity` empty until matching fills `Within` (idea file) |
| `core/database/conclusionsummaries` | D-6's `subjectValue`; `FoldLocations` folds with `valuecompare.Compare` on subject values; D-8 – D-12; reconciles with `autoreconcile.Reconcile(valuerules.Product(), propertymeta.ValueTypeSubject, candidates, nil, single)` (`conclusionsummaries` cannot import `autoreconciler`, which imports `searchindex`; `valuerules.Product` is the same value as `autoreconciler.ValueRules`) |
| `core/database/conclusiondetails` | D-13; `(*recordReader).outcome` reads `Provenance` from the member's `Credibility` and the row's `Uncertain` (a member credibility map beside `graphOf`) |
| `core/database/searchindex` | D-14, history line "13: an event's places are its location links' records reconciled (S16-80)." |

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
Files: `core/database/sourcecredibilitygrades/gradeorder/gradeorder.go` *(new)*, `core/database/sourcecredibilitygrades/registry.go`, `grades.go`, `grades_test.go`, `core/database/autoreconciler/autoreconciler.go`, `core/database/sources/records.go`, `core/database/sourcemove/sourcemove.go` and their tests. Skill: `add-catalog-query`.
Do: move per D-5's package row; no behaviour change.
Check: `go build ./... && go vet ./...` pass; `go list -deps ./core/database/sourcecredibilitygrades/gradeorder | grep provenencia` lists only `core/vocabkey` and itself; `CGO_ENABLED=1 go test -tags fts5 ./core/database/...` passes.

**STEP-3 — The node carries provenance.**
Files: `core/database/graphcache/graph.go`, `load.go`, `verify.go`, `graph_test.go`, `core/database/graphcache/graphcachetest/graphcachetest.go`.
Do: D-5. `OpenCatalog` calls `sourcecredibilitygradestest.Install(c)`. `Canon.NewSource` inserts a Source, Artifact, Evidence graph and Citation (`transcription_uncertain` from the argument) and, when `grade` is not empty, a `source_credibility_assessments` row (`id`, `source_id`, `credibility_grade_id` of the provenencia grade with that key); entities and links made after it use them, those made before keep theirs. `Canon.SetRef` updates `canonical_entities.ref`. T-3.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/graphcache/...` passes, also with `PROVENENCIA_GRAPH_VERIFY=1`.

**STEP-4 — Value compare relates subjects; the reconciler folds them.**
Files: `core/valuecompare/subject.go` *(new)*, `valuecompare.go`, `rules.go`, `contract_test.go`, `valuecompare_test.go`; `core/matchregistry/value.go`; `docs/matching-model.md` (knob row `value.Subjects.Partial`, 0.7, estimate, "Similarity of a place within another"); `core/propertycompare/propertycompare_test.go`; `core/autoreconcile/modules.go`, `dates.go`, `modules_test.go`; `core/subjectprofile/subjectprofile.go` (comment). Skill: `add-match-rule` § Add a comparer, § Add a knob, § Add a relation, cause or unit code (the cause list in the archived `comparison-layers.md` §Detail gains `within`).
Do: D-6, D-7. `TestCompareUnsupported`'s `noComparer` and the AC-1.10 case of `propertycompare_test.go` move to the type string `"unregistered"`, so the unsupported path stays covered. T-1, T-2.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/valuecompare/ ./core/matchregistry/ ./core/propertycompare/ ./core/subjectcompare/ ./core/autoreconcile/ ./core/database/autoreconciler/` passes.

**STEP-5 — One fold, one link read, every link an owner.**
Files: `core/database/conclusionsummaries/placevote.go` *(new)*, `placechains.go`, `compose.go`, `conclusionsummaries.go`, `placechains_test.go`.
Do: D-6's `subjectValue`; `FoldLocations` folds with value compare (its ref sort stays until STEP-6); D-11; `eventFoldDate`; `prepareVote` with only its one-survivor half, and with two or more survivors returning `FoldLocations`' survivors as today with each link `kept`; both composers use it; `FieldOwner` fields and owners per D-12. `TestPersonRowOwners` case "a parent Place is not an owner" becomes "a parent Place is a folded owner": Yorkshire's link is a second owner after York's, `Reason` folded.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/conclusionsummaries/` passes, T-7's tests green with that one case changed.

**STEP-6 — Events vote their places.**
Files: `placevote.go`, `compose.go`, `placechains.go`, `placechains_test.go`, `eventplacevote_test.go` *(new)*.
Do: `prepareVote`'s listing half, `finishVote`, D-9, D-10 (the ref sort goes), D-3, D-4. `TestPersonDerivedRows` "graph queries do not grow with events and Places": create `bigPlaces` before the small Person's birth, give that birth `york` and `bigPlaces[0]`, and expect two place owners on the small row; both Persons now vote, and `smallN == bigN` holds. T-4, T-5, T-8.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/conclusionsummaries/ ./core/database/conclusiondetails/` passes.

**STEP-7 — The sheet shows the vote.**
Files: `core/database/conclusiondetails/conclusiondetails.go`, `placerecords_test.go`.
Do: D-5's sheet half, D-13. T-6.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/conclusiondetails/` passes.

**STEP-8 — Re-project search.**
Files: `core/database/searchindex/searchindex.go`, `searchindex_test.go` (line 246), `core/search/handles_test.go` (line 385).
Do: D-14; both tests expect 13.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/searchindex/ ./core/search/...` passes.

**STEP-9 — Measure.**
Do: rerun STEP-1's benchmark, and `CGO_ENABLED=1 go test -tags fts5 ./core/database/promotealign/ -run TestLargeSourceBudgets -v` (`perf_test.go`).
Check: within § 6 Scale; the budgets pass; both figures in the PR description.

**STEP-10 — Version and docs.**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj` (all four `MARKETING_VERSION` lines) → 0.48.1; `docs/conclusion-reconciliation.md` (§ 7: the policy sentence and the subject row per Rules this plan bends; § 9: a derived place reconciles across the event's location links; § 11.1: the vote, the containment fold at the event's date, the shared-parent rule of AC-2.2, and that "one place per event" is decided in the vote until the idea file); `docs/matching-model.md` (the **value** row lists a subject); `docs/catalog-caches.md` (`nodes` row: members carry credibility, outcome rows certainty; the new `nodes-B`); `.agents/skills/add-match-rule/SKILL.md` ("Catalog data comes in through `Rules`" per Rules this plan bends; § Add a comparer step 3's `noComparer` now holds `"unregistered"`); `docs/deployment-plan/spike-16/completed.md`; `docs/deployment-plan/spike-16/deployment-plan.md` (the S16-80 row's status); this plan (status). The version bump rides in this step's commit.
Do: per the Definition of done.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/ -run TestVersion` passes; `python3 scripts/check-plan-docs.py --links docs/conclusion-reconciliation.md docs/catalog-caches.md docs/matching-model.md` reports no broken link.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/autoreconcile/modules_test.go` `TestSubjectsFoldWithin` *(new)* | `Reconcile` of subject candidates A, B, C, where A's and B's `Within` hold C: A from S1–S3, B from S4 → A kept, support 3, merged; B outvoted `Vote{3, 4}` · A ×3 + C ×1 → one value A, support 4; C `folded` · A, B from S1, S2 → both kept, mixed, A first (earlier Observation id) · A credibility −1, B standard → A weak · C, A, B one Source each, A recorded first → C folds into A; B outvoted `Vote{2, 3}` · no `Within`, A and C → two values, mixed · no `EntityID` → no evidence | D-3, D-4, D-7, D-10 |
| T-2 | Go | `core/valuecompare/contract_test.go` `TestComparerContract` (a subject sample row and generator); `valuecompare_test.go` `TestSubjectCompare` *(new)*; `TestCompareUnsupported` on `"unregistered"` | Same entity → `Same`, 1, `exact`; A in B's `Within` → `Contains`, 0.7, `Broader` A, `within`, both orders; each in the other's `Within` → `Different`, 0, `no_match`; unrelated → `Different`; no entity → `Unknown`, `empty`; `Key` at `Same` equal exactly when `Same` | D-6 |
| T-3 | Go | `core/database/graphcache/graph_test.go` `TestNodeProvenance` *(new)* | `Canon.NewSource("low_trust", true)`, then a Location: its member has `Credibility` −1 and its `place` outcome row `Uncertain` true; a member under the first Source has 0 and false; `Verify` passes | D-5 |
| T-4 | Go | `core/database/conclusionsummaries/eventplacevote_test.go` `TestEventPlaceVote` *(new)* | Table on `Canon` (`NewSource` per Source), each case checking `EventsByIDs` `Places`, `PersonsByIDs` `Birth.Places` and `Birth.Owners.Places` (order, `Reason`, `Vote`): AC-1.1 (`SetRef`: England `PLC-A`, Swift Current `PLC-B`; fails on the old code) → [Swift Current], England owner last, `outvoted {3, 4}` · AC-1.2 → [Swift Current, England] when Swift Current's Location is written first, reversed when England's is · AC-1.3 → [England], Swift Current `weak` · AC-1.4 "one Source" → both · AC-2.1 → [Swift Current], parents Saskatchewan, Canada; Canada owner `folded` · AC-2.2 → [Swift Current], Toronto `outvoted {2, 3}`, Canada `folded` · AC-2.3 (`part_of` with `end_date` 1922 through `Canon.Date`, birth `date` 1950) → [Dublin], United Kingdom `outvoted {2, 3}` · AC-2.4 (birth 1900) → [Dublin], United Kingdom `folded` · "cycle": A `part_of` B and B `part_of` A, one Source each → both | AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-2.1, AC-2.2, AC-2.3, AC-2.4, D-6, D-8, D-10, D-12 |
| T-5 | Go | `eventplacevote_test.go` `TestEventPlaceVoteCap` *(new)* | 66 Locations to Swift Current and 5 to England, each from its own `NewSource` → the test computes the first 64 links in `Follow(event, hops.PlacesOfEvent)` order (as `firstPlaces` in `eventplaces_cap_test.go`); the birth keeps 63 place owners and its date owner, each among those 64; `Places` holds only places among them, in vote order; `PersonsByIDs` cold within `databasetest.WithinBudget` of one second | D-11 |
| T-6 | Go | `core/database/conclusiondetails/placerecords_test.go` `TestPlaceOwnersCarryTheVote` *(new)* | Helper `placedBirth(src sources.Source, toponym string, person, birth, place []byte) (personH, birthH, placeH []byte)` *(new)*: files a person, a birth and a place with that toponym on `src`, links them, and promotes each onto the handle given (nil promotes a new one). Three Sources at Swift Current onto shared handles, a fourth at England; the three Swift Current bridges file into one association (a bridge is filed by its ends), so the sheet has two owners → `placeRows`: England's outcome `outvoted`, `Vote{3, 4}`; the others `kept`. Canada variant → `folded`, `ValueRank` 0. Low-trust variant → `weak`, `Provenance.Credibility` −1 | AC-3.1, AC-3.2, AC-3.3, D-5, D-13 |
| T-7 | Go | `placechains_test.go` `TestBirthLocationsFoldWhenPartOf`, `TestSiblingBirthPlacesStayCompetingUnderASharedParent`, `TestPersonRowOwners`, `TestPersonDerivedRows`; `eventplaces_cap_test.go` `TestCraftedEventPlaces`, `TestEventPlacesCapInputs`, `TestCraftedLifeOwners`; `core/propertycompare/propertycompare_test.go` AC-1.10 | Green. Changed: `TestPersonRowOwners` "a parent Place is a folded owner" (STEP-5, asserting `Reason` folded); `TestPersonDerivedRows` query-count case (STEP-6); AC-1.10 on `"unregistered"` (STEP-4) | D-8, D-9, D-11, D-12 |
| T-8 | Go | `eventplacevote_test.go` `TestEventPlaceVoteFollowsEvidence` *(new)* | AC-1.2's world with England's Location first, read once ([England, Swift Current]); then England's Source assessed `low_trust` by SQL and `k.Commit` of England's association → `EventsByIDs` reads [Swift Current] | D-5 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `core/database/conclusionsummaries` (owner order), `core/matchregistry` (inventory and numbers guards), `core/database/promotealign` `TestLargeSourceBudgets`.

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
- [ ] Domain doc updated if a rule in docs/*.md changed: conclusion-reconciliation.md § 7, § 9, § 11.1; matching-model.md; catalog-caches.md `nodes` row
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

The sweep covers `RelativeOrderColumn`, `RelativeOrderJoins`, `sourcecredibilitygrades.DefaultKey`, `eventPlaces`, `isAncestor` and "keep their catalog identity". The brief and copy lines do not apply.

## 10. Manual check

1. Open the dogfood project. Open the Person whose Birth place showed England (the screenshot of 2026-11-26). The row reads Swift Current with no Mixed badge.
2. Open its provenance sheet: four records from 2 Places, the Swift Current group first with its three records "kept", the England record "outvoted (3 of 4 Sources)".
3. Open the birth Event: its Place row reads Swift Current, not mixed. In the Events list the place column reads Swift Current with no +1.
4. Search for "England": that Person and birth are not hits through the place.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| The vote moves a lead a test elsewhere pins by ref | T-7's tests use one Source, where only the tiebreak changes |
| Reading association nodes on a list path slows lists | D-8, D-9; STEP-9 at Scale |
| A summary row cached before a credibility change keeps the old lead | T-8 |
| A subject comparer changes matching | Matching sets no `Entity` (`subjectprofile.Value`); STEP-4's check runs the matching layers |

**Stop and report if:**

- `FoldLocations`, `eventPlaces`, `eventLocations`, `lifeFacts`, `composePersons` or `PersonDerivedRows` no longer match § 4.
- `graphcache` cannot import `gradeorder` without a cycle (STEP-2 check).
- A matching test (`core/subjectcompare`, `core/graphalign`, `core/database/promotealign`) changes result after STEP-4.
- A credibility or certainty write does not reload the association node, so T-8 fails without a new invalidation signal.
- `TestLargeSourceBudgets` fails, or `nodes-B` / `nodes-ms` exceed § 6 Scale.
- A test needs a changed expectation other than the three T-7 names or an order between places from one Source.
- The manual check's sheet does not list the England record, or lists it "kept".

## 12. Open questions

None.

## 13. PR

**Title:** S16-80 — An event's places reconcile by their records
**Body:** objective in one sentence; what shipped against each US; AC evidence; the `BenchmarkCacheSizes` and `TestLargeSourceBudgets` figures; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-80-event-place-vote.md`.
