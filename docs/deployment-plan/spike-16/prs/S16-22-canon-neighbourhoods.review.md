# Review — S16-22 Promote reads each handle's neighbourhood instead of walking the catalog

**Verdict:** pending round 2 (round 1: Fits with changes — Ready with changes)
**Rounds:** 1 so far. **Reviewers:** maintainability (Opus), executability (Sonnet)

## To user

None.

## Writer's own calls

- The view's link order is each handle's own (its filed links in node order, then `For`'s), not the walk's seed-dependent order (D-5). Measured: same link sets; order differs for 1–4% of the handles read; no row moved on the large fixture or in any test.
- The equivalence run against the walk is temporary: it runs in STEP-3 and is deleted with the walk in STEP-4; its output goes in the PR description (D-8).
- `budgetWarm` 950 → 150 ms and a 16,000-person subtest inside `TestLargeSourceBudgets` (D-13).
- `Reader.For` stays exported though its last outside caller goes (D-10, M-5).
- No version bump (S16-32 precedent).

## Round 1

### X-1 · blocker · STEP-3 does not compile: `terms` unused in `Propose`
**Answer:** Fixed — STEP-3 drops `Propose`'s `terms` variable; `inputs.terms` and `LoadTerms` stay until STEP-4 for `WalkRowsForTest`.

### X-2 · major · `ViewLinksForTest` underspecified
**Answer:** Fixed — D-16: it is `loadInputs` then `alignRows(c, in, nil)` (so `mergeFixed` adds promoted Subjects), returning a new map of the memo's non-nil entries; AC-2.1 counts those.

### X-3 · major · T-1 expectations omit keys, end order, link order
**Answer:** Fixed — T-1 compares `lesserFirst` shapes as sorted sets, names each link's associations, `OnlyImplied` and keys (participation keys from `w.edgesOf()`, parent keys from `w.keys`), and the link counts.

### X-4 · major · `Reader.Links` now carries `Associations`
**Answer:** Fixed — D-1 says so and that `Align` and `Connections` never read them.

### X-5 · minor · nil `personType`
**Answer:** Fixed — D-1 uses `n.Is(r.d.personType)`; a nil id matches no node.

### X-6 · minor · stale budget comment tail
**Answer:** Fixed — D-13 replaces the last two sentences.

### X-7 · minor · how to measure the base
**Answer:** Fixed — STEP-1 uses a second worktree at the branch's base commit.

### X-8 · minor · doc lines not covered
**Answer:** Fixed — D-15 names §7's opening and "Canonical adjacency" lines and the idea file's sentence; line 3 and B-11 are history and stay.

### X-9 · minor · `candidates` field shadows the entry; dead walk between steps; Verify run step
**Answer:** Fixed — the field is `ranked`; the Verify run is in STEP-5's check. The walk being unused between STEP-3 and STEP-4 is intended (D-8).

### M-1 · blocker · `Reader.Links` is a second copy of `Relationships`' compose loop
**Answer:** Fixed — D-1: `composeLinks(filed, implied...)` *(new)* holds the one LinkSet rule; `Relationships` and `Links` both call it. `Links` reads a person's implied links through `loadSteps` + `forLinks` like `For`, and does not run `loadSteps` for places and events (a city's 6,000 event pivots).

### M-2 · major · caller-supplied neighbour in `deriver.edge`
**Answer:** Fixed — D-2: `edge` reads the event end itself through `d.src.node` and returns an error; `filedEdges` *(new)*; `edgeOf` drops `self`; `world.edgesOf` uses `filedEdges`.

### M-3 · major · `ViewLinksForTest` copies `Propose`
**Answer:** Fixed — D-16 `alignRows` *(new)*; `Propose` and `ViewLinksForTest` share it.

### M-4 · major · doc lines missed by D-15 and the sweep
**Answer:** Fixed — D-15 adds §4.1's adapter line, §7's opening and query-count lines, and `Propose`'s doc comment; the DoD adds an unqualified `Canon` check on `promote-graph-alignment.md`.

### M-5 · minor · `Reader.For` loses its last outside caller
**Answer:** Declined — `For` is the documented name of a person's composed implied links in `matching-model.md`, `add-match-rule`, `catalog-caches.md` and the memo idea; unexporting it is a five-file sweep for no reader gained. D-10 now states this.

### M-6 · minor · person check copies `Node.Is`
**Answer:** Fixed — D-1 uses `n.Is(r.d.personType)`.

### M-7 · minor · third copy of the weights filter
**Answer:** Fixed — D-3 filters only fixed Subjects (`evidencelayer.go` keeps only weighted kinds from the same registry; `seed` checks again).

### M-8 · minor · two error contracts for lazy inputs
**Answer:** Fixed — D-6 adds the held-error contract to `CanonView`'s doc.
