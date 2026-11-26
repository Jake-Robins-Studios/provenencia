# Review — S16-80 An event's places reconcile by their records

**Verdict:** Fits with changes — Ready with changes (round 2; To user open)
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet)

## To user

- **M-1, where "an event has one place" is declared.** The user chose the matching registry (`segment.go` `One`). The writer then found two consequences and asked again. `One` keys hold from both ends (a place would have one event). Matching knows no containment, so Promote would score Canada vs Swift Current as a −3 conflict. The user asked which shape fits best. **Writer's recommendation, applied in D-1 pending the user's confirmation:** no declaration yet. The vote passes single with a decided comment, and the one declaration both layers read is parked in [`ideas/one-bridge-cardinality.md`](../../../ideas/one-bridge-cardinality.md), to be built once matching can tell containment from conflict.

- **M-12, the reconciler's grouping policy.** Asked whether to bend S11-06 with a caller's fold rule, the user asked which shape is better long-term (2026-11-26). **Writer's answer, applied:** do not bend it. Containment enters as data: a subject value carries `Within` (what contains it at the date), value compare gains the subject comparer its "Add a comparer" slot always had (`noComparer` listed subject), and the subject module folds on `Contains` like `dateModule`. The policy holds, value compare stays pure, and matching can fill `Within` the same way later. `ReconcileHandles`, `keyModule.folds` and `validate` are gone; Rules this plan bends is None. Awaiting the user's veto only.
- **M-1:** answered 2026-11-26: no declaration yet (D-1).

## Writer's own calls

- D-3: denied, provisional and negative rows do not vote again across links. The link's own reconcile already weighed them, and this keeps the fast path exact.
- D-8: the last tiebreak between equally supported places is the earlier record, not the ref (the pipeline's own order).
- D-9: an event reads at most 64 location links (`maxLifeOwners`), in `eventLocations`, for every reader.
- D-15: a composition loads every conflicting event's association nodes in one `Graph.Nodes` call, so a sheet's graph queries do not grow with conflicts.
- S15-28 (Spike 15) reads a derived row's records by Person and row kind and calls `placeVerdict`; both maps say so.
- The Person's sheet now lists a folded parent place's records (`TestPersonRowOwners` "a parent Place is not an owner" becomes a folded owner), as AC-3.2 asks.
- D-13: search is re-projected (`ProjectionVersion` 13), so an outvoted place stops matching.
- Version: patch (0.46.1).

## Round 1

### M-1 · blocker · Bridge-end cardinality gets a second declaration, and it has one caller
`core/matchregistry/segment.go` `One` already declares one-cardinality links. A `connectrules.Endpoint.Cardinality` field would be a second declaration that disagrees with it, and `voteLocations` would be its only reader.
**Answer:** To user (above). D-1 drops the `connectrules` and `hops` changes, along with STEP-3 and T-2 of the draft.

### M-2 · blocker · The provenance sheet reads a record's provenance a second way
`(*recordReader).outcome` builds `Provenance` from Source records and per-graph Observations, while the node now carries the same facts.
**Answer:** Fixed. D-5 makes the node the one home, and § 6 Go core has `outcome` read the member's credibility and the row's certainty. The Out row is gone.

### M-3 · major · `Outcome.SourceID` repeats `Member.SourceID`, and credibility is per Source
**Answer:** Fixed. D-5 puts `Credibility` on `Member` (one join in `loadMembers`) and `Uncertain` on `Outcome` (one join), and takes the Source from the member. The Scale memory bound is cut to 2 MB.

### M-4 · blocker · The vote's overlay in `PersonDerivedRows` gives S15-28's records read no slot
**Answer:** Fixed. D-12 makes `placeVerdict` one function, and the cross-spike table in `deployment-plan.md` gains the row "S16-80 | S15-28".

### M-5 · major · The containment rule is written twice, and the fast path hand-derives verdicts
**Answer:** Fixed. D-6 extracts `(*placeGraph).folds`, which `FoldLocations` and the vote both call. D-7's fast-path verdicts read it too.

### M-6 · major · A second link cap sits beside "the one read of an event's places"
**Answer:** Fixed. D-9 caps links in `eventLocations` at `maxLifeOwners`, before the distinct-place cap. `maxVotingLinks` is gone. This also answers X-4.

### M-7 · major · `subjectModule` repeats `keyModule`, and `ReconcileHandles` repeats `Reconcile`'s checks
**Answer:** Fixed. `keyModule.folds` and a shared `validate` replace them (Codebase fit, STEP-4).

### M-8 · major · Skills the PR makes incomplete are not loaded or updated
**Answer:** Fixed. `add-match-rule` is in Skills to load, and STEP-9 adds the caller-fold line to it. The `add-seeded-vocabulary` concern goes away with M-1.

### M-9 · minor · `gradeorder` name and the `DefaultKey` alias
**Answer:** Fixed. The package is `sourcecredibilitygrades/gradeorder`, with one `DefaultKey` and no alias. STEP-2 moves every caller and test.

### M-10 · minor · Written once
**Answer:** Fixed. The graphcache details live in the Go core table only, the draft-history phrase is gone, and `placeVote.links` holds `FieldOwner` values instead of a separate verdict type.

### X-1 · blocker · STEP-7 omits two tests that pin `ProjectionVersion` 12
**Answer:** Fixed. STEP-7 names `searchindex_test.go` (line 246) and `core/search/handles_test.go` (line 385).

### X-2 · blocker · The version bump is in the DoD but in no step
**Answer:** Fixed. STEP-9 sets `VERSION`, `core/version.go` and both `MARKETING_VERSION` lines to 0.46.1 and runs `TestVersion`.

### X-3 · blocker · T-5 contradicts `maxLifeOwners`
**Answer:** Fixed. T-5 expects 63 place owners plus the date owner.

### X-4 · major · Order of the 64-link cap against the fast path is ambiguous
**Answer:** Fixed by M-6. The cap is applied in `eventLocations`, before raw places, the fast path and the owners.

### X-5 · major · Candidate `Value` fields are underspecified
**Answer:** Fixed. D-3 spells out the candidate: `Value{SubjectID: link.Neighbor, EntityID: link.Neighbor}`, with the Source and provenance taken from the member and the row. `folds` receives entity ids.

### X-6 · major · T-6 cannot be written from its row
**Answer:** Fixed. T-6 names the helper `placedBirth(src, toponym, person, birth, place) (personH, birthH, placeH)`.

### X-7 · major · The fast-path equivalence ignores negative and provisional records
**Answer:** Fixed. D-3 votes only `kept` and `folded` rows, and D-7 states why the equivalence then holds.

### X-8 · minor · STEP-9 names `completed.md` and `deployment-plan.md` without a path
**Answer:** Fixed. STEP-9 gives the full paths and says to update the map row's status.

### X-9 · minor · STEP order
**Answer:** Declined. The reviewer confirmed the order is sound.

### X-10 · minor · Checks that need more than the plan gives
**Answer:** Fixed. STEP-1 takes the baseline on the planning base before any change, and STEP-8 names `perf_test.go`. `nodes-B` is reported by `measure` (`bench_test.go` line 609, `metric+"-B"`).

### X-11 · minor · T-2 uses a registered test bridge
**Answer:** Fixed by M-1. The draft's T-2 is gone.

## Round 2

### M-11 · blocker · `placeVerdict` gives S15-28 no slot it can reach
The verdicts exist only on the Person row's owners; a read keyed by (association, Property) cannot get them.
**Answer:** Fixed. D-12 says S15-28's records read for a derived row takes the Person and the row kind, as `PersonDerivedRows` does. The Spike 16 cross-spike row says the same, and S15-28's row in the Spike 15 map now names it and depends on S16-80. Rejected: an exported verdict read by association, which would re-run the vote at a date the Person row did not use.

### M-12 · blocker · The caller-supplied fold rule bends the reconciler's fold policy
**Answer:** Fixed by reshape (above): no bend; a subject comparer in value compare and a subject module that folds on `Contains`.

### M-2 follow-up · The sheet's grade label stays on the Source record
**Answer:** Fixed. D-5 no longer claims one home: the vote and the sheet weigh a record from the node, and the sheet's `CredibilityKey` label stays the Source record's.

### X-1 · blocker · `TestPersonRowOwners` "a parent Place is not an owner" fails under D-11
**Answer:** Fixed. STEP-5 changes that case to "a parent Place is a folded owner", and T-7 and the Stop list name it.

### X-2 · blocker · The vote breaks `TestPersonDerivedRows` "graph queries do not grow with events and Places"
**Answer:** Fixed. D-15 loads every conflicting event's association nodes in one `Graph.Nodes` call per composition (`conflictLinks`). T-7 gives the small Person a conflict too, so both Persons take the vote path and `smallN == bigN` holds.

### X-3 · major · `Canon.NewSource` needs the credibility grades installed
**Answer:** Fixed. STEP-3: `OpenCatalog` calls `sourcecredibilitygradestest.Install`, and the assessment row's columns are named.

### X-4 · major · "England minted first" does not make its ref sort first
**Answer:** Fixed. `Canon.SetRef` is added (Codebase fit), and T-4 sets `PLC-A` / `PLC-B` and must fail on the old code.

### X-5 · major · `MARKETING_VERSION` appears on four lines
**Answer:** Fixed. § 4 and STEP-10 say all four.

### X-6 · major · Who builds `Parents` for the displayed places
**Answer:** Fixed. D-8: the displayed places are `FoldLocations`' own survivors, reused with their `Parents`.

### X-7 · major · D-3 and D-10 edge cases
**Answer:** Fixed. D-3: a row with no `SubjectID` or member is skipped, and rank 1 is the link's place (`linkLoadSQL`). D-11: a link with no verdict has no owner, and an event with no shell has no place owner.

### X-8 · minor · `placedBirth` and promote's bridge filing
**Answer:** Fixed. T-6 says the three Swift Current bridges file into one association, so the sheet has two owners.

### X-9 · minor · Credibility read through the member's Source rather than the Citation's Artifact
**Answer:** Fixed. An Edges line states the equality (`observations` ties a Citation to its Subject's graph, and the maintainability reviewer checked `requireSameGraph`).

### X-10 · minor · D-1 awaits the user
**Answer:** Agreed. The plan stays Draft until To user is answered.

### X-11 · minor · STEP-5 hides about five changes
**Answer:** Fixed. STEP-5 (the predicate, the link cap, the fast path, owners) and STEP-6 (the vote) are now separate.

## Cost

Plan: 5,880 words at round 1, 5,640 after round 1, 6,298 after round 2 (check-plan-docs info line).

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| 1 | maintainability | opus | 177k |
| 1 | executability | sonnet | 131k |
| 2 | maintainability | opus | 189k |
| 2 | executability | sonnet | 210k |
