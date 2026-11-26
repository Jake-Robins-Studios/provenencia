# Review — S16-80 An event's places reconcile by their records

**Verdict:** Fits with changes — Ready with changes (round 3, asked for by the user after the reshape); To user answered; Planned
**Rounds:** 3. **Reviewers:** maintainability (opus), executability (sonnet)

## To user

- **"Catalog data comes in through `Rules`" (add-match-rule).** A place's `Within` (what contains it at the event's date) rides on the value, not in `Rules`, because it holds per value and per date. **Answered: accepted (user, 2026-11-26).** STEP-10 rewrites the skill line so per-value context the caller derives at the value's date rides on the value while catalog tables come through `Rules`.
- **M-1:** answered 2026-11-26: no declaration yet (D-1).
- **M-12:** answered by the reshape. The user asked for the long-term shape (2026-11-26): containment is data on the value, value compare's subject comparer owns the rule, and the reconciler folds on `Contains`.

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

## Round 3

The user asked for this round after the reshape, with the objective: robust, long-term, maintainable code with clean separation of concerns and no one-off branches, so new entities and relationships slot into existing infrastructure.

### M-13 · blocker · The containment rule is written in three places
**Answer:** Fixed. D-6: `(*placeGraph).subjectValue` is the one builder and value compare the one rule. `FoldLocations` and the fast path read `valuecompare.Compare`, and `isAncestor` goes.

### M-14 · blocker · The subject comparer's `Contains` similarity and cause are undecided
**Answer:** Fixed. D-6 sets similarity `value.Subjects.Partial` (new knob, 0.7, with an inventory row) and the new cause `within`. `Same` is `exact`, `Different` is `no_match`, and no entity is `Unknown` with `empty`. The whole add-match-rule skill is loaded.

### M-15 · blocker · `Within` bends "Catalog data comes in through `Rules`"
**Answer:** To user (above). It is listed under Rules this plan bends, and STEP-10 rewrites the skill line and `matching-model.md`'s value row.

### M-16 · blocker · D-15's pre-pass repeats the fold and the date
**Answer:** Fixed. D-8 splits the vote into `prepareVote` (one fold and the trigger) and `finishVote`, with one `eventFoldDate`. D-9 batches the node reads between them.

### M-17 · major · `subjectModule` repeats `keyModule` and `dateModule.fold`
**Answer:** Fixed. D-7: `keyModule.folds` and one `foldsOnContains`, which `dateModule` also uses. `subjects.go` is gone.

### M-18 · major · Two tests lose their only unsupported type
**Answer:** Fixed. STEP-4 moves `noComparer` and AC-1.10 to `"unregistered"`, and T-7 names them.

### M-19 · major · `placeVerdict` only for place owners
**Answer:** Fixed. D-13: `ownerVerdict` runs for every owner and does nothing when no vote ran.

### M-20 · minor · `subjectprofile.Value` stays without `Entity`
**Answer:** Fixed. A doc comment there (Go core row), plus a Reach row and a Risk row.

### M-21 · minor · `Within` has no stated bound
**Answer:** Fixed. `maxWithin` is 256, in D-6 and Edges.

### M-22 · minor · Written once
**Answer:** Fixed. The spec lives in D-6, and the other rows point to it. The `foldValues` restatement is kept only where AC-2.2 cites the user's call.

### X-1 · blocker · Comparer causes and similarity; AC-1.10; `noComparer`
**Answer:** Fixed, as M-14 and M-18.

### X-2 · major · STEP-5's interim `voteLocations` and the ref sort
**Answer:** Fixed. STEP-5 keeps `FoldLocations`' survivors and its ref sort, with each link `kept`. STEP-6 removes the sort along with the vote (D-10).

### X-3 · major · D-15's wiring
**Answer:** Fixed. D-9: a Person's pick locations are read once through its scope and passed on, and `prepareVote` lists every link of the event.

### X-4 · major · `TestPersonDerivedRows` edit
**Answer:** Fixed. STEP-6 gives the exact edit.

### X-5 · major · "Best-ranked candidate"
**Answer:** Fixed. D-12: the stronger `Provenance`, then the earlier `ObservationID`.

### X-6 · minor · T-5
**Answer:** Fixed. Each Location has its own Source, and the test computes the first 64 links from `Follow` order.

### X-7 · minor · Folded-owner assertion
**Answer:** Fixed. T-7 asserts `Reason` folded.

### X-8 · minor · The plan's Review header
**Answer:** Fixed.

### X-9 · minor · The map's scope line still describes the caller's rule
**Answer:** Fixed. The S16-80 "Ships" line in `deployment-plan.md` is rewritten.

### X-10 · major · § 7's "keep their catalog identity"
**Answer:** Fixed. It is listed under Rules this plan bends with the user's 2026-11-26 call, and STEP-10 rewrites the sentence and the row.

### X-11 · minor · STEP-2's check
**Answer:** Fixed. `go build ./... && go vet ./...` is added.

Smaller notes: `Within` is a set whose order is not part of the contract (D-6). A place outside the graph has an empty `Within`. Entities made before `NewSource` keep their Source (STEP-3).

## Cost

Plan: 5,880 words at round 1, 5,640 after round 1, 6,298 after round 2, 6,742 after round 3 (check-plan-docs info line).

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| 1 | maintainability | opus | 177k |
| 1 | executability | sonnet | 131k |
| 2 | maintainability | opus | 189k |
| 2 | executability | sonnet | 210k |
| 3 | maintainability | opus | 201k |
| 3 | executability | sonnet | 196k |
