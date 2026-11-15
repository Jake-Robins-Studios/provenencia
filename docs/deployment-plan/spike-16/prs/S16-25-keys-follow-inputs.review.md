# Review — S16-25 Swift keys become plain values and follow their inputs

**Verdict:** round 1: Fits with changes — Not ready; round 2: pending
**Rounds:** 1. **Reviewers:** maintainability (Opus), executability (Sonnet)

## To user
- Before planning (answered 2026-11-15): the map's Check asked that a write inside a cited Source which changes no Source words leave record links alone (S16-12 PRF-1), but the only Source signal was `SourceScopes`, which every write in a Source sets, and S16-12 had marked a narrower signal "not planned" (2026-11-12). The user chose option 2: a `source_records` keyed read moved only by `sources`, `artifacts` and `source_credibility_assessments`, followed by the app and by the Go Source records entry. Recorded in **Rules this plan bends** and in STEP-6's map edits.

## Writer's own calls
- D-2: one non-optional `id` accessor plus two `citationsByArtifact` accessors, rather than positional `ids[0]`.
- D-3: no `onField` narrowing on `sources`, so a cover or public flag edit reloads pages that show the Source; the `date_values` path waits for S15-05.
- D-9: FakeStore keeps empty inputs; tests seed inputs.
- D-11: no end-to-end FFI test per relation (S16-24 D-11 had named one for this PR); the three halves are tested where they live.
- D-12: four commits.

## Round 1

### M-1 · blocker · `.revalidateOnInputs` is a second revalidate mechanism beside `.revalidate`
D-6/D-7 added a new Action case and a joined `.inputs.ids(in:)` used only to skip, with `revalidatedKeys` switching over two revalidate actions; `requireRowIDs` would let `.inputs` into `lastUpdated` or `merged`. Better: widen `.revalidate` to `(WorkspaceSession, CatalogQueryKey, CatalogWriteEffects) -> Bool`, build the existing constructors from it, make `followsInputs` one more constructor, and have `requireRowIDs` refuse `.inputs`.
**Answer:** Fixed — D-6 widens `.revalidate`; D-7 makes `.inputs` a label whose `ids(in:)` is empty and which `requireRowIDs` refuses; §6 Codebase fit and macOS sketch updated.

### M-2 · major · Own-id check belongs in `entityPage` with `followsOwnId`, not inside `followsInputs`
Inserting `ownId` into a copy of `handles` copies the set per key per write and would put a non-handle id into the handles set for a future key.
**Answer:** Fixed — D-10's `entityPage` declares `.applyHiddenPolicy(followsOwnId: .touchedHandles)`; D-7 reads the inputs unchanged; AC-3.3 and T-5 expect `[.inputs, .touchedHandles, .list(.propertyVocabulary)]`; §6 Scale says no per-write allocation.

### M-3 · major · Add `effects.Set.ReadIDs(Read)` instead of another `set.Reads` loop
**Answer:** Fixed — D-4 adds `Set.ReadIDs` beside `Set.Has`; `records.go`, `index.go`, `citationReads` and `evidence_graphs_test.go`'s `readIDs` use it (STEP-1, STEP-2); Swift `isMet` reads `CatalogQueryFollows.reads(.sourceRecords).ids(in:)` (D-8). The negative loop in `evidencegraphs_test.go` stays (Out).

### M-4 · major · S15-05 has no slot: a Source date edit will not name `source_records`
**Answer:** Fixed — took option (b): D-3 says a table the record gains adds its path in the PR that adds the column; Out names S15-05 as the home of the `date_values` path; STEP-6 writes that into the effects README and `add-audit-scope`; the registry constant's doc says so; T-1 carries a comment tying the tables to `sources.loadRecords`. Adding the path now was rejected: nothing reads the date from the record, and rule "updates exactly" would make it a reload for no reader.

### M-5 · major · Docs sweep misses places the PR makes false
**Answer:** Fixed — STEP-1 rewrites the `CatalogRead`, `evidenceGraphs`, `reads` and `sourceScopes` docs; D-2 rewrites `make`'s doc; D-1 rewrites `ownId`'s; STEP-6 rewrites `macos-client-patterns.md` rule 2 and the "Conclusion keys" first bullet; the DoD sweep adds "through `.source`" and "`guard case`s the key".

### M-6 · minor · D-1 gives `sourceWorkspace` and `typeSuggestions` an `ownId`
**Answer:** Fixed — D-1 names the change and why no reader is affected; the doc becomes "The key's single id, when it has exactly one"; §6 Next adds notes a deleted-Source eviction needs only `deletedWith: .source`.

### M-7 · minor · Positional `key.ids[1]`
**Answer:** Fixed — D-2: `key.id` for single-id loaders, `citationGraphId` and `citationArtifactId` for the one two-id kind.

### M-8 · minor · D-12's first commit fails the Swift vocabulary parity test
**Answer:** Fixed — the Swift `CatalogRead` case moved into STEP-1 (D-5), commit 1; the old STEP-3 is gone and the steps are renumbered.

### X-1 · blocker · `TestRecordsApply`'s "observation edit" subtest contradicts D-4
**Answer:** Fixed — STEP-2 gives `check` a `moves bool`; the subtest passes `false` and asserts the derived entry is kept. T-2 is that updated test (the planned new `TestRecordsApplyFollowsSourceRecords` is dropped: the existing real-write subtests cover every writer).

### X-2 · blocker · The "finds nothing" `rg` checks hit legitimate `guard case`s
**Answer:** Fixed — AC-3.4, STEP-3 and manual check 6 use `case \.[a-zA-Z]+(\(.*\))? = key`, which matches only pattern matches on a key; `make`'s comment is rewritten (D-2).

### X-3 · major · Swift checks cannot run without Xcode
**Answer:** Fixed — a **Runs on macOS** line under the header says which steps need Xcode and what to do without it; every `xcodebuild` command now matches `scripts/check-pr.sh` (`-destination 'platform=macOS'`, `CODE_SIGNING_ALLOWED=NO`).

### X-4 · major · T-2 and AC-2.4 cannot be written from the rows
**Answer:** Fixed — the resolve test is dropped. `TestReadsDeclare` is exhaustive over tables (T-1), so no evidence table can carry the read, and `TestRecordsApply`'s real writes (credibility included, through its `setGrade`) prove each Source-word write reloads the record and an Observation write does not (T-2). AC-2.4 and AC-2.5 are restated against that.

### X-5 · major · STEP-7 docs edits leave false text or open choices
**Answer:** Fixed — STEP-6 now gives exact old and new text for the "A Source's words live once" clause, names that rule's Binds line, rewrites `macos-client-patterns.md`'s first "Conclusion keys" bullet and rule 2, gives both `catalog-caches.md` cells, and quotes the differing `add-audit-scope` and README sentences separately.

### X-6 · minor · Commit order does not match step order
**Answer:** Fixed with M-8: commits follow the steps.

### X-7 · minor · Test-data and edge choices not made
**Answer:** Fixed — D-9 says claims values are always seeded with `setQueryValue` (FakeStore drops their inputs); T-8 and T-9 name which values use FakeStore seeds; §6 Edges covers an empty `source_records` entry and the deleted Source and Artifact (T-2 subtests); a strict-concurrency compile failure is a Stop.

### X-8 · minor · Credibility grade vocabulary edits are not covered
**Answer:** Fixed — §6 Edges (d): grades change only at install (S16-12 D-4); D-3 and the Stop list make a runtime grade write a Stop.
