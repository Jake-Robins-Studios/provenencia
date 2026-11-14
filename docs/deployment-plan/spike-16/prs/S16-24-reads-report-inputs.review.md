# Review — S16-24 Person, Event and Place reads report their inputs

**Verdict:** round 1: Fits with changes — Ready with changes; round 2: Fits with changes — Ready with changes; every finding Fixed, nothing To user; Planned
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet)

## To user

None.

## Writer's own calls

- The handles list carries ids only, not bridge and endpoint: the app's write effects name ids, so ids are what it can match (§3 Out).
- Family and Timeline record ids they read but do not show (a lone marriage event, provisional relatives and participants), so S16-25 can follow the writes that would make them show (D-6, D-7, AC-1.7, AC-1.8, AC-1.10).
- No cap on the lists: they are never larger than what the read already loads; the crafted 20,000-child hub is about 40,000 ids (§6 Scale, Edges).
- Record links record the person, graphs and Sources, not each line's other entity: the app draws only graphs and arcs (D-5).
- The claims value becomes `CatalogPersonClaims` so it can carry inputs (D-9, D-10).
- Sources are added at the two readers' lookups, not inside `sources.RecordIndex` (D-4, answer to M-2).
- A real-write-effects soundness test per relation is S16-25's Check (D-11).

## Round 1

### M-1 · blocker · Family recorder re-walks the kinship steps beside `loadSteps`
`recordAround` copied the walk `deriver.loadSteps` owns (`neighborsOf` at its two loads; `deps` states it a third time).
**Answer:** Fixed — D-7: `loadSteps` takes the recorder and `neighborsOf(nodes, in)` records each node, neighbour and association in its one walk; `deps` passes `g.NoPageInputs()`. `recordAround` is gone from D-7, §6 Codebase fit and Go core. A recording `nodeSource` was weighed and rejected (it records loaded ids but not the associations of the links derived from).

### M-2 · blocker · Recording sits beside the reads, not at them
`InputScope.Node` / `Follow` and `graphfill.RecordsOf` were mirrored by hand-written `Add…` calls; `.cursor/rules/catalog-queries.mdc` teaches read-through recording; a nil recorder was a second "records nothing" convention beside `NoInputs`.
**Answer:** Fixed — D-1: `PageInputs` gains `Node` and `Follow` (through its scope) and a `NoPageInputs()` constructor; nil is no longer a convention. D-2: `conclusiondetails.Handle`, `personNode`, `graphfill.RecordsOf` and `loadSteps` take the recorder. D-3 rewritten: a read records where it reads; `Add…` only for ids from rows in hand. D-4 – D-6 reworded to read through `in.Node`, `in.Follow`, `RecordsOf(…, in)`. STEP-1 adds `RecordsOf`'s parameter and T-1b. Sources stay an `Add` at each reader's `recs.Artifact` / `recs.Source` lookup: `sources.RecordIndex` is a whole entry read by Promote and the lists, and a recorder parameter there would widen every caller for two readers (D-4 Rejected).

### M-3 · major · The pattern is taught nowhere on the Go side
**Answer:** Fixed — STEP-9 adds a sentence to `.cursor/rules/catalog-queries.mdc` and to `add-ffi-handler`; the DoD lists both.

### M-4 · minor · Names
`g.Inputs` and `g.ReadInputs` side by side; `graphs` beside the effects' `evidence_graphs`.
**Answer:** Fixed — the recorder is `graphcache.PageInputs` / `NoPageInputs`; the wire list is `evidence_graphs`, Swift `evidenceGraphs`; the message is `PageInputs`, the Swift type `CatalogPageInputs`, the mapper `pageInputsProto` / `GoStore.mapPageInputs`.

### X-1 · major · Checks the container cannot run
**Answer:** Fixed — Stop condition: without `protoc`, its plugins or `xcodebuild`, stop after STEP-6, push and report; STEP-7 and STEP-8 run on the researcher's Mac; never hand-edit generated files.

### X-2 · major · Call sites missing from step file lists
**Answer:** Fixed — STEP-1 lists every `RecordsOf` caller; STEP-2 lists the `ForEntity` and `PersonDerivedRows` test callers in `autoreconciler` and `conclusionsummaries`; STEP-3 lists `placeentries_test.go`, `display_cache_test.go`, `promotealign/bench_test.go`; `go vet -tags fts5 ./...` is a Check.

### X-3 · major · D-3 contradicted D-7's walk
**Answer:** Fixed — D-3 rewritten (no SQL, no load, no derivation; walking memory is allowed); D-7 now records inside the existing walk (M-1) and spells the second Family pass.

### X-4 · minor · D-1 small choices
**Answer:** Fixed — `Add…` go through `InputScope.Add`; `Lists` drops non-16-byte ids; "records nothing" is `NoPageInputs()` (M-2).

### X-5 · minor · Which key kind recordAround records
**Answer:** Fixed — moot after M-1; `neighborsOf` records through `AddHandles`.

### X-6 · minor · T-10 and AC fixtures
**Answer:** Fixed — `wantInputs` checks "holds", not "equals"; T-4 builds its own fixture with Village; T-7 reuses the Ghost setup.

### X-7 · minor · When `attachSummary` changes
**Answer:** Fixed — STEP-2.

### X-8 · minor · Pictures and derived-row owner timing
**Answer:** Fixed — D-4 says pictures go through the same reader and owners are read before any is dropped.

## Round 2

The round 1 answers were checked against the code: M-1, M-3, M-4 and X-1 – X-8 hold; M-2 held for `Node` and `Follow` and left the two gaps below.

### M-5 · blocker · Timeline and Family hand-write `Add…` beside the node lookups they mirror
`PersonEvents`' event filter and `canonicalPerson`, and `shownKin` in both Family passes, read each id with `g.Cached`; the plan added the same ids by hand (the M-1 class again).
**Answer:** Fixed — D-1: `PageInputs` gains `Nodes` (loads, records nothing) and `Cached` (never loads, records the id found or not). D-3, D-6, D-7: those lookups read through `in.Cached` and batch loads through `in.Nodes`; the Timeline's and Family's `Add` lines are gone (the `PersonsByIDs` add with them). `Cached`, not `Node`, so no lookup starts loading. T-1 covers both methods; STEP-9's rule sentence names them.

### M-6 · major · `Options.Inputs` brought back a nil "records nothing" convention
**Answer:** Fixed — `Reader.Relationships(ids, opts, in)` takes the recorder as its last parameter like every other read in D-2; `Options` is unchanged; `For` and `deps` pass `g.NoPageInputs()`.

### X-9 · major · `personNode` callers outside STEP-4's files
**Answer:** Fixed — STEP-4 lists `timeline.go` and `family.go` (their `personNode` calls pass `c.Graph().NoPageInputs()` until STEP-5 and STEP-6); STEP-2 lists `claims.go`.

### X-10 · major · Nil graph in `RecordsOf`'s test
**Answer:** Fixed — D-1: `NoPageInputs` on a nil `*Graph` is safe and records nothing; STEP-1 says `records_test.go`'s nil-graph case passes `(*graphcache.Graph)(nil).NoPageInputs()` and still expects `database.ErrClosed`.

### X-11 · minor · `InputScope.Add` fires the test hook on an off scope
**Answer:** Fixed — D-1: a `NoPageInputs` recorder returns before calling `Add`.

### Nits
**Answer:** Fixed — §6 FFI sets `out.Inputs` after `attachSummary` and `attachPictures`; T-8's M3 case names `loadSteps`' second neighbour load; the DoD grep is `\.PageInputs\(\)`.
