# Review — S15-22 The Sources section groups a Source's Citations by citation

**Verdict:** Fits with changes — Not ready → fixed (round 1); plan Blocked on board S15-D15
**Rounds:** 1. **Reviewers:** maintainability (Opus), executability (Sonnet). Both read the plan and its brief S15-D15.

Round 2 not run: round 1's blockers were answered Fixed with plan text that follows the reviewers' own shapes (M-1, M-2, M-3, X-3), and the plan is Blocked on the board, so it is refreshed and reviewed again against the agreed frames before it moves to Planned (plan-pr "Refresh an existing plan").

## To user

- **The retry word on the citations notice (M-2).** The brief first said **Read again** (the provenance sheet's word, from `PVFormLoadArea`). Every read notice on the Person page says **Try again** (`PVRetryCallout`'s handle init, `L10n.Conclusions.readNoticeTryAgain`), and `add-workspace-place` "Stale-while-revalidate" asks Conclusions readers to draw that init. **Recommendation: Try again** (no rule bent; the page uses one word). The plan (D-10) and the brief (SC-7) now say Try again. Say if you want Read again instead; then D-10 passes the kit init and **Rules this plan bends** names that skill row.

## Writer's own calls

- Product calls answered by the user (2026-11-21): citation blocks sit under each record line; the pieces are the record's Observations; Full and Short copy as on the sheet; a record whose type has no full format shows nothing new.
- While the citations load, nothing stands in for the blocks (no skeleton or caption); the rows draw at once (D-8, brief SC-6).
- After Unpromote the old key's blocks stay until the new key answers (D-4, brief SC-8).
- The provenance sheet's host moves onto the shared `HeldQuery` in this PR (D-3), with no behavior change.
- `PVSpacing.measureCitation` = 680pt (D-9): the board may change the number.
- The negative piece reuses the sheet's "not {value}" (`readAsNot`), the label falls back to the property key (`CatalogObservation.displayLabel`).

## Round 1

### M-1 · blocker · `CitationKeyHold` is a second, feature-private version of the view-held key lifecycle
**Plan:** D-3, D-4: a second hand-written host with its own hold; STEP-6 names each holder in four docs.
**Codebase:** `ProvenanceSheetHost` is the only view-held lifecycle; `add-workspace-place` "View-held key" describes one pattern.
**Better shape:** One view-held query mechanism in `Features/Workspace/Session/` with a keep-previous flag; move `ProvenanceSheetHost` onto it; docs name the mechanism once.
**Answer:** Fixed — D-3 `HeldQuery` / `HeldQueryRead` and D-4 `HeldQueryKey` in `Features/Workspace/Session/HeldQuery.swift`; `ProvenanceSheetHost` moves onto it with `keepsPreviousValue: false` (STEP-2); STEP-7's docs name `HeldQuery`.

### M-2 · blocker · The failed notice hand-maps the handle against the skill
**Plan:** D-9 passed `citationsLoad`, `citationsFetching`, `citationsFailureRevision` and the kit init with "Read again".
**Codebase:** `QueryHandle+RetryCallout.swift` `PVRetryCallout.init(title:message:handle:compact:id:onRetry:)`; `add-workspace-place` "Stale-while-revalidate".
**Answer:** Fixed — D-10 draws the handle init from `HeldQueryRead.handle`; `PersonSourcesList` takes one `citations: HeldQueryRead<…>?`. The word goes **To user** (above), with Try again applied.

### M-3 · blocker · `citing(_:)` writes a second copy of the sheet's gather loop
**Codebase:** `PVProvenanceSheetContent.grouped(by:)`.
**Answer:** Fixed — D-1 `CitationGroups.gather(_:by:)`; `grouped(by:)` and `citing(_:)` both use it; T-2 covers it.

### M-4 · major · `CatalogPersonSourcesCitations` copies `CatalogProvenanceSheetRead`
**Answer:** Fixed — D-2: the key's value is `CatalogRenderedCitations` with `CatalogPageValue`; `citing` reads `value.byID` inside `conclusionContent`.

### M-5 · major · `Copy.Kind` gives S15-23's list form no slot
**Answer:** Declined — keying `Kind` on `CitationForm` makes every switch cover `.list`, so this PR would write the list form's word, label and announcement, which are S15-23's copy, decided by its own brief S15-D19 (map row S15-23; rule "One brief, one PR"). S15-23 adds its case when its brief settles the copy; D-7's Rejected column and § 3 Out say so.

### M-6 · major · The recipe exports the pairing's internals; the track width is stale
**Codebase:** `PVProvenanceColumns.copyTrackWidth` is 84 with its comment; `PVProvenanceColumnsTests` asserts it.
**Answer:** Fixed — D-7 `PVCitationCopyTrack` owns the HStack, both guides and the constants (84, 8); `PVProvenanceColumns.copyTrackWidth` and `copyTrackSpacing` are deleted and the test moves; Current state and the brief (SC-4, inventory, § 4.1) say 84; the brief's two inventory rows are one.

### M-7 · major · A second "not {value}" and a second label fallback
**Answer:** Fixed — D-6 uses `L10n.Conclusions.readAsNot` and `CatalogObservation.displayLabel` (the graph card moves onto it); `sourcesPieceNegated` is gone.

### M-8 · major · Literal separators instead of the join helpers
**Answer:** Fixed — D-9: `lineJoin` folds the pieces, `spokenJoin` speaks them; AC-1.3 updated.

### M-9 · minor · The 680pt measure is a feature constant
**Answer:** Fixed — `PVSpacing.measureCitation` (D-9).

### X-1 · blocker · Blocked on a board that does not exist
**Answer:** Declined — by design: plan-pr step 3 writes the brief and leaves the plan `Blocked — on board S15-D15` until the user agrees the board; the plan is then refreshed against the frames.

### X-2 · blocker · The copy track is 84pt, not 72pt
**Answer:** Fixed — see M-6.

### X-3 · blocker · `settle()` is never triggered
**Answer:** Fixed — D-3 settles on the current key's own state (`currentSettled`: a value or a failure), not the drawn load; a failed new key settles, releases the old one, and shows the notice (AC-3.5, T-6). `oldHandle` and `current` are gone: `HeldQuery` reads the handles itself.

### X-4 · major · One frame of blink before the hold is set
**Answer:** Fixed — D-4: `shown` reads `drawn`, set when the previous key settled, so the first frame after the key moves already draws the old value; `move` keeps the drawn key.

### X-5 · major · STEP-4 needs what STEP-5 creates
**Answer:** Fixed — steps re-cut: STEP-5 adds `PersonSourcesList`'s one `citations` parameter and the anchor wait; STEP-6 draws blocks and the notice.

### X-6 · major · `PersonSourcesContent` cannot be copied by `citing(_:)`
**Answer:** Fixed — D-5: `rows` becomes `private(set) var`; `citing` copies `self`; `citationIDs` and each line's `observed` are filled in `init`, `observed` through the `Line(…)` memberwise call.

### X-7 · major · Preview data has no Observations
**Answer:** Fixed — § 6 macOS: `johannCitedClaims` and `johannRenders` *(new)* match the brief's § 5 data; `johannClaims` stays; `PersonSourcesPreview` gains `renders:` and `citationsFailure:`.

### X-8 · major · The plan fails its own check (review log link)
**Answer:** Fixed — this log exists.

### X-9 · minor · Smaller choices
**Answer:** Fixed — namespace placed after `L10n.ProvenanceSheet` and the `.xcstrings` `rg` added (STEP-3); block ids stay positional within a line (D-9); T-5 uses no dates; copy buttons take no focus stop, Tab reaches them after Unpromote (D-9); blocks have no hover handler (D-9); the notice sits inside the rows `VStack` after the strong divider (D-10); test helpers named (STEP-4); remount confirmed (`PlaceRegistry` `.personDetail` `viewIdentity: { $0.entityId }`, § 4); empty ids → no call (AC-3.1, Reach, T-7).

### X-B1 · blocker · The brief is not drawn
**Answer:** Declined — expected; the user draws and agrees the board next.

### X-B2 · major · 72pt in the brief
**Answer:** Fixed — 84pt.

### X-B3 · major · No Wide frame for the failed callout
**Answer:** Fixed — frame 3a / 3b.

### X-B4 · minor · Frame data versus the shipped preview fixture
**Answer:** Fixed — the plan's new `johannCitedClaims` follows the brief's data; the shipped `johannClaims` stays for the other previews.

### X-B5 · minor · Motion on a static board
**Answer:** Declined — frames 5 and 6 show the states; the behavior is in SC-6, SC-9 and the plan's ACs.
