# Review — S16-27 One primitive for values derived from cached data

**Verdict:** Fits with changes — Ready with changes
**Rounds:** 2. **Reviewers:** maintainability (Opus), executability (Sonnet)

## To user

- **The three vocabulary lists' sorts (M-2, second half).** `PropertiesModel.visibleProperties`, `SourceTypesModel.visibleTypes` and `MetadataModel.visibleFields` sort a cached vocabulary list on each read with no memo. Bar 15 reads "every value", so they are in its letter. Recommendation: leave them out (not planned). Each list holds tens of rows, and a memo there adds a call and an id each and deletes nothing. The plan stays Draft until this is answered.

## Writer's own calls

- D-17: `SourcesModel`'s visible-rows memo moves too (not named in the map row; map updated).
- D-18: the Conclusion detail page's content moves too (M-2; map updated).
- D-14: Promote and Unpromote build with a held types or rules value where they built with empty lists.
- D-18: a section's content inputs are its whole read list, not per role.
- D-10: a debug-only check that a build reads only the keys it declares.

## Round 1

### M-1 · blocker · Inputs listed by hand at every call; three sites copy the snapshot's key list
Text, vocabulary and snapshot each repeated `[graph, propertiesWorkspace, connectRules]`; the risk that a build reads an undeclared handle was held only by review. Better shape: record reads during the build (a), or let an input be another derived value (b).
**Answer:** Fixed — (b), D-2: `DerivedInput` is `.key` or `.derived(id)`, stamped by the entry's version after validating its own inputs, as Go's `DerivedFrom`; text (D-15) and vocabulary (D-16) name `.derived(.evidenceGraphSnapshot(graphID:))`. And the half of (a) that answers the risk: D-10, a debug check that every key read through `queryHandle` during a build is declared; the Out row "a debug check …" is gone. (a) as the only input source was not taken: both hosts get their value from outside the build, so they would declare it anyway.

### M-2 · blocker · The detail page uses the same presentation call but stays rebuilt per pass
**Answer:** Fixed — D-7 replaces `sectionContent` with one `conclusionContent(CatalogQueryKey)` id; D-18 routes `ConclusionDetailLoaded.presentation` and the section host through one `conclusionContent` call; D-19 lists the detail sites' extras; AC-2.8, T-12, STEP-6; map scope entry updated. The three vocabulary sorts: To user (above), Out row added.

### M-3 · major · `QueryHandle.serial` guards a case D-5 already prevents
Verified: `evict(_ key:)` (`WorkspaceSession.swift` line 537) is the only removal and `typedHandle` creates only for a missing key.
**Answer:** Fixed — D-3 drops the serial; a stamp is the revision or -1; a Stop condition holds the premise ("a handle leaves `handles` anywhere but `evict`").

### M-4 · major · The entry re-implements `Memo`
**Answer:** Fixed — D-5: the store is `[DerivedValueID: Memo<DerivedStamp, Any>]`; `DerivedStamp` replaces the entry struct; §1 and Codebase fit say `Memo` is the store.

### M-5 · minor · Confusing names
**Answer:** Fixed — `cachedEvidenceGraphSnapshot(graphID:)` (D-13); the section helper is gone in favor of `WorkspaceSession.conclusionContent` (D-18).

### M-6 · minor · The sweep misses Swift doc comments
**Answer:** Fixed — STEP-3 adds `EvidenceCardText.swift` and `rg 'displayText\(rows|displaySnapshot\(rows'`; D-12 rewrites the index's doc; STEP-2's `rg` includes "Valid for one handle revision".

### M-7 · minor · Rule 5's "not a third cache key" sentence
**Answer:** Fixed — STEP-7 gives the replacement sentence.

### M-8 · nit · Two signatures
**Answer:** Fixed — D-1: one array `extra` with a default (also X-7).

### X-1 · blocker · The new file cannot reach `handles` or stored properties
**Answer:** Fixed — D-4 (`inputRevision(_:)` in the main file, `handles` stays private) and D-9 (the stored properties and their access in the class body).

### X-2 · major · The index's value type
**Answer:** Fixed — D-12: `Value == EvidenceGraphIndex`; the nil check sits outside `derived`.

### X-3 · major · `carryDerived` and `extra`
**Answer:** Fixed — D-11: ignores `extra`, keeps the stored one; no entry → nothing; "every other input" may be none.

### X-4 · major · How tests drive eviction
**Answer:** Fixed — §8 names `deletedEntitiesLoseTheirHiddenKeys` and `hiddenConclusionPagesAreCappedAtFifty` as templates, and each test names its key, effects and FakeStore field.

### X-5 · major · A second `SourcesModelTests` test reads the counter
**Answer:** Fixed — §4 and T-11 name both (lines 295–318, 455–497), counts unchanged.

### X-6 · major · T-7 and T-6 setup
**Answer:** Fixed — T-7 builds the keys itself and sets a `PropertiesSnapshot`; T-13 adds the second await.

### X-7 · minor · Overload ambiguity
**Answer:** Fixed — see M-8.

### X-8 · minor · Locale capture
**Answer:** Fixed — §4 says the closure reads `.autoupdatingCurrent`; D-19 reads it into a local in `body`.

### X-9 · minor · Memo row and doc link
**Answer:** Fixed — §4 Memo row corrected; `EvidenceCardText.swift` in STEP-3.

### X-10 · minor · Map Check says tests unchanged
**Answer:** Fixed — map scope Check now says "unchanged in what they assert".

### X-11 · nit
Logged. D-17 names `session.sourceTypesKey`, `evidenceGraphsKey`, `evidenceGraphProgressKey`; D-16 sorts Property ids as strings; the header names 0.15.4 → 0.15.5; D-5's fallback is the Stop condition.

## Round 2

The cap is reached: these answers are new plan text no reviewer has read. Round-2 verdicts: maintainability Fits with changes; executability Not ready (X-1, X-2 blockers), Ready with changes once X-1 – X-5 are resolved.

### M-9 · blocker · Each content site lists its inputs twice, and D-10 sees neither list
D-19 hand-listed each site's extras beside a closure that captured the same values in `body`, outside any build, so the debug check covered none of them.
**Answer:** Fixed — D-19: `make` takes `(Value, Extra)` and reads nothing else but handles it fetches inside the closure; the section host gains a generic `Extra: Equatable`; Timeline, Family and Sources get one `Inputs` struct each; record links pass `graphLocations`; the detail page's `make` takes `NameFormatOrders`, passed by the page. D-1 and D-5: `extra` is one `(any Equatable)?`, no array. The Stop condition and D-19's list of captured values are gone.

### M-10 · blocker · `private(set)` the new file cannot write; four parallel dictionaries
**Answer:** Fixed — D-9: one `derivedEntries: [DerivedValueID: DerivedEntry]` with `DerivedEntry { memo, inputs, version }`; `derivedBuilds` and `derivedReads` internal with internal setters. Also X-2.

### M-3 recheck · `typedHandle` replaces a handle on a type mismatch
**Answer:** Fixed — D-3 and the Stop condition name it as a programming error, not an eviction.

### Below blocker (not raised): the snapshot's key list twice in one file
**Answer:** Fixed — D-13 adds `evidenceGraphSnapshotKeys(graphID:)`, read by the async and the cached call. The copies in `EvidenceGraphModel.prepare`, `CitationComposerContext` and `PromoteModel` warm other keys too and stay.

### Below blocker (not raised): `DerivedValueID` as an enum
**Answer:** Declined — nothing switches on it; D-7 records why S16-25's struct shape is not needed here.

### X-1 · blocker · When the stamp is taken; an absent `.derived` input
**Answer:** Fixed — D-1: the stamp is taken after the build. D-2: a missing or invalid child is a miss for the parent; validation re-stamps the child's stored inputs recursively; a worked example gives T-6's counts.

### X-2 · blocker · `private(set)` contradiction
**Answer:** Fixed — see M-10.

### X-3 · major · The eviction drop and `derivedInputs`
**Answer:** Fixed — D-6 names `dropDerived(reading:)`, its home, the fixpoint over `.derived` dependants and the call from `evict`; D-9 holds the inputs in the entry; the build counter is not reset.

### X-4 · major · Test ids
**Answer:** Fixed — D-20 maps each primitive test to a real id.

### X-5 · major · `currentSnapshot()` and missing handles
**Answer:** Fixed — D-15: `currentSnapshot()` keeps its nil guard; `displaySnapshot` with no handle is the empty snapshot, as today; the model's `connectRules` and `fieldsSnapshot` stay.

### X-6 · minor · Which key the hosts use
**Answer:** Fixed — D-18: each host's existing `key`.

### X-7 · minor · AC-1.7 has no runnable check
**Answer:** Fixed — §10 step 8 removes an input in a Debug build and reads the assertion; T-15 points to it.

### X-8 · check · No `xcodebuild` here
Logged; the plan's "Runs on macOS" line covers it.

### X-9 · minor · The planned commit is not on local `main`
**Answer:** Fixed — a **Base** line says to compare against `origin/main`.

### X-10 · minor · Draft with one To user item
Logged; it waits on the user.
