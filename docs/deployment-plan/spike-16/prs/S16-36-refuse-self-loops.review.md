# Review — S16-36 A link from a record to itself is refused where links are read

**Verdict:** Fits — Ready with changes (two rounds; no open blocker)
**Rounds:** 2. **Reviewers:** maintainability (Opus), executability (Sonnet)

## To user
- M-1 (answered 2026-11-14): two guards, one per `graphcache` link read, instead of the working rule's "once". The user chose two guards; the rule, the map row, the scope entry and its Check were reworded in the planning commit.

## Writer's own calls
- D-1: the second guard sits in `WalkEvidenceGraph`, because the rule's readers include `graphalign`'s layer (Evidence graph bridges).
- D-2: the guards drop the link silently; the read does not fail, nothing is logged, and Verify does not flag it.
- D-3: `kinship.Edge.Readings` and `Edge.Ends` are deleted, not kept without their self-loop branch.
- D-4: `readsTerm`'s equal-ends check goes too, beyond the scope entry's list: the rule says no reader handles a self-loop, and the scope's `rg` check reaches its doc lines.
- D-6: a Place page's inputs lose the `ParentsOfPlace` keys, so a commit that changes only a place's wholes no longer drops its page.
- AC-4.1 lists three `rg` hits not about a stored link ("Toronto itself", a key corresponding to itself, `TestDeriveInvariants`' implied-link check) instead of rewording them.
- Out: no refusal in `observations.Update` for an edit that sets both bridge ends to one Subject; the read-time drop covers it.

## Round 1

### X-1 · blocker · T-3 passes with the equal-ends check deleted
A place-to-place `location` input is refused later by the bridge-type check, so the test held nothing.
**Answer:** Fixed — T-3 / AC-3.1 copy the "person person relationship" input with `personB` replaced by `person` (person-to-person is an allowed `relationship` rule, so only line 72 refuses it) and assert `countBridges(t, s.c, "relationship")` unchanged.

### X-2 · blocker · AC-4.1 and AC-4.2 `rg` commands match nothing as written
`\|` in ripgrep is a literal pipe.
**Answer:** Fixed — the commands moved out of the AC table into §10 as search 1 and search 2, in `bash` blocks with plain `|`; AC-4.1, AC-4.2, STEP-7 and the DoD refer to them.

### X-3 · major · AC-4.1's hit list is missing `core/connectrules/filing_test.go:39`
**Answer:** Fixed — added to AC-4.1 as the `DecisionSelfLink` filing test row (D-8).

### X-4 · major · `iter` in `kinship.go` and `bytes` in `placeentries.go` become unused
**Answer:** Fixed — STEP-5 and STEP-6 name both imports and the exact doc and comment lines to delete.

### X-5 · minor · T-2 placement and shape left to the implementer
**Answer:** Fixed — T-2 says the setup goes after the "A to-end on another Source" `UPDATE` and before `g := f.C.Graph()`, and rows use names.

### X-6 · minor · `Canon.PartOf(loop, loop)` not confirmed to work
`Canon.Link` writes one Observation per endpoint property (`from`, `to`), so two rows on one entity with different properties.
**Answer:** Fixed — a Stop condition if `PartOf(loop, loop)` or the commit fails in T-1.

### X-7 · minor · Doc and comment lines to delete not located
**Answer:** Fixed — with X-4.

### M-1 · blocker · D-1's second guard departs from the map's "one guard", and the plan settled that itself
**Answer:** To user → answered: two guards (2026-11-14). §5 **Rules this plan bends** records it; the working rule, the map row, the scope entry and its Check were reworded in the same commit.

### M-2 · blocker · `newState`'s new layer loop hand-codes `Edge.From`'s mapping
**Answer:** Fixed — D-3: `newState` loops `[][]byte{b.A, b.B}` and reads `b.From(end)`; same readings and order. §4 Precedent updated.

### M-3 · major · `dedupePlaceLinks` does nothing once D-6 lands
It came with the self hop (666da56); `finishLinks` dedupes `self|assoc|neighbor` and `Node.Follow` keeps one `FromEnd`.
**Answer:** Fixed — D-6 deletes it and its four calls; **Deletes**, STEP-6's `rg`, and a Stop condition if a place entry, page or succession test changes.

### M-4 · major · D-1's "one reader of Evidence graph bridges" is not true
`promotealign` `pageBridges` and the filer's `bridgeHeads` read endpoint Observations directly.
**Answer:** Fixed — D-1's Why names them as readers that decide a self-link through `DecisionSelfLink` and never read it as a link; §6 Edges **Neighbors** says the Promote page still lists such a bridge as a refused self-link; the `observations.Update` Out row says so too.

### M-5 · minor · D-9 records a rule for every reader only in Promote's doc
**Answer:** Fixed — D-9 adds the sentence to `conclusion-layer-data-model.md` §2.7 beside the "reads as absent" precedent, and `promote-graph-alignment.md` line 198 points to it.

## Round 2

Maintainability: every round-1 answer holds against the code; no new blocker. Verdict Fits. Noted, not raised: `Canon.View`, `newState` and `NewGraph` each read both ends in their own words (two plain field reads, not a second mechanism).

Executability: every round-1 answer holds; search 1 run against the tree, each hit accounted for. Verdict Ready with changes.

### X-1 · minor · T-1 indexes `NodesOnBridges`' map with `[]byte`
**Answer:** Fixed — `[string(loop)]`.

### X-2 · minor · STEP-1's guard breaks two `conclusionsummaries` tests that STEP-6 deletes
**Answer:** Fixed — `TestPlaceEntries` "self-loop" and `TestFiledPlaceLinks`' loop are deleted in STEP-1, whose check now runs `conclusionsummaries` and `promotealign` too; STEP-6 keeps the `pageReads` change.
