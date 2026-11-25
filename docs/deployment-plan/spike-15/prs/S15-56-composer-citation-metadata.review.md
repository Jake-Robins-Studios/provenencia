# Review — S15-56 The composer edits a Citation's metadata

**Verdict:** round 1: Fits with changes — Not ready (four executability blockers and one maintainability blocker, all Fixed). Round 2: pending
**Rounds:** 1. **Reviewers:** maintainability (opus), executability (sonnet). The plan and its brief S15-D29 were reviewed together

## To user

- **M-1** Drop the `.wroteMetadataBoard` patch of the composer's Citation list? The map's scope entry named it. Recommended: drop it. **Answered (user, 2026-11-25): drop it**, reload only; the map's scope entry is reworded.
- **M-4** Move the metadata board's files to their own folder in this PR? Recommended: yes, moves only. **Answered (user, 2026-11-25): move them in S15-56** (D-15).
- Asked while planning: the Citation menu row reads the Citation's own Page value (D-13), and locator `page_label`s are not moved (D-16) (user, 2026-11-25).

## Writer's own calls

- D-2 / D-3: one reader of the printed page in `sourcemetadata`, and the three `metadatafields` key and id readers take a `database.Querier` so `graphfill` can call them.
- D-4: the Conclusion detail's page is the display text, marks included ("p. unpaginated", "p. [14]"), as the seeded formats print it; no proto change.
- D-5: a new read `citation_boards` rather than reusing `citations`.
- D-8: the board lives on the composer context, built in one method; a Citation not in the cached list shows the failure line.
- D-12: one failure sentence for both cases; the engine's several `sourcemetadata.invalid` causes are not told apart.

## Round 1

### X-1 · blocker · The composer never loads the field list the board needs
`PlaceRegistry.swift`'s `.citationComposer` spec does not warm `.metadataFieldsList`; the host would get an empty list.
**Answer:** Fixed — D-8 and STEP-6 add the key to the spec; T-10 pins it. (Same as M-2.)

### X-2 · blocker · STEP-9's check cannot pass
`rg printedPage` hits `CitationLineDisplay.printedPage`, which stays.
**Answer:** Fixed — STEP-10's check names only the deleted symbols.

### X-3 · blocker · STEP-7 and STEP-8 use L10n keys STEP-9 creates
**Answer:** Fixed — new strings are STEP-7, before the composer steps; removals are STEP-10, after the form stops using them.

### X-4 · blocker · T-3 cannot assert what it says
`TestConclusionDetailProtoCarriesVoteArtifactAndMembers` builds an `Outcome` by hand.
**Answer:** Fixed — T-3 is `TestForEntityCitationParts` with the seed; the proto test stays as is (Current state).

### X-5 · major · `CitationPages` key type and empty-text rule not stated
**Answer:** Fixed — D-2: keyed `string(id)`, owners built per id, an empty `PageText` is absent.

### X-6 · major · Fixtures may lack the seeded `page` field
**Answer:** Fixed — STEP-2, STEP-4 and T-1 install the seed with `sourcevocabtest.Install`; T-1 makes the competing field with `metadatafields.Create`.

### X-7 · major · STEP-2 undercounts the tests to rewrite
**Answer:** Fixed — STEP-2 says what `TestLoadParsesEachCitationOnce` keeps and drops.

### X-8 · major · Swift tests broken by the Deletes are not in the steps
**Answer:** Fixed — STEP-9 lists `ArtifactViewerModelTests.swift` and the two `CitationComposerModelTests` tests; D-14 gives the new orders.

### X-9 · major · FakeStore records or applies the draft?
**Answer:** Fixed — D-7: record-only arrays `createCitationMetadata`, `updateCitationMetadata`; listed rows seeded.

### X-10 · major · STEP-7 underspecified; D-9's reuse of the cached list has gaps
**Answer:** Fixed — D-8: one `openMetadataBoard(for:)`, the listed row from `citationsKey(artifactID:)`, the board model after the host, the error cleared on each open, the unlisted case shows D-12's line, and the context is the object the `ensureCitationID` callers share.

### X-11 · minor · Atomicity of the list read
**Answer:** Fixed — D-6 takes the page from the board's own entries (M-7).

### X-12 · minor · Tests that change but are not named
**Answer:** Fixed — STEP-3 names `want` and `readsFixture`.

### X-13 · minor · A docs sentence goes false
**Answer:** Fixed — STEP-11 (with M-6).

### X-14 · nit · Line drift
Logged; Current state lines corrected.

### M-1 · blocker · The list patch duplicates the reload and leaves the page stale
**Answer:** To user → answered: dropped (D-9). STEP-6's patch and T-9 of the first draft are gone.

### M-2 · major · The composer place doesn't warm the field list
**Answer:** Fixed — as X-1; the getter is `metadataFields`.

### M-3 · major · D-5 reuses `citations` for another signal, with hand-written paths
**Answer:** Fixed in part — D-5 adds `citation_boards`, which `.citationCounts` does not follow. Deriving the paths from `MetadataTables.Ups` declined: `Ups` point from an owner up toward the Source; this path points down from an owner to the graphs of the Citations under it, which `catalogmodel/metadata.go` does not declare, and the four paths have different shapes (`up`, `field`, an `inbound` through `citations`, `graphsOfSource`).

### M-4 · major · The board becomes cross-feature but stays a Sources snowflake
**Answer:** To user → answered: move (D-15, STEP-6); the brief's inventory row is updated.

### M-5 · major · `vocabkey.FieldPage` has no parity guard
**Answer:** Fixed — D-1, T-11.

### M-6 · major · Docs and skills the PR makes false
**Answer:** Fixed — STEP-11 lists the four files.

### M-7 · minor · Two reads of the same rows in two transactions
**Answer:** Fixed — D-2 splits `PageFieldID` and `PageText`; D-6 formats from the board.

### M-8 · minor · Branch on the typed engine code
**Answer:** Fixed — D-12. A specific engine code is Out (not planned).

### M-9 · minor · The host is built in five places
**Answer:** Fixed — D-8's one method.

### M-10 · minor · T-6 asserts wall-clock time
**Answer:** Fixed — T-6 counts queries and logs the time.

### M-11 · minor · FakeStore's page should be scripted
**Answer:** Fixed — D-7.

### M-12 · minor · Two wire names for one fact
**Answer:** Fixed — the new field is `page_label`, as `ReconcilerOutcomeDetail`'s; renaming the old carriers is Out.

### M-13 · minor · Facts stated twice
**Answer:** Fixed — D-2's signatures live in Codebase fit, Strings points at Deletes, §6 macOS no longer restates D-10.

## Cost

Plan: 4,849 words at round 1, 5,459 after round 1's fixes (check-plan-docs info line).

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| 1 | maintainability | opus | 219k |
| 1 | executability | sonnet | 159k |
