# Review — S15-29 The provenance sheet loads its records when it opens

**Verdict:** (round 2 pending)
**Rounds:** 1 so far. **Reviewers:** maintainability (opus), executability (sonnet)

## To user

None. The two product calls were asked before review and answered (user, 2026-11-28): a sheet whose read answers no owners gets no state of its own (D-9); a failed reload behind shown records stays silent; S15-D18 is descoped, since only the load area's two strings change.

## Writer's own calls

- D-1 / D-2: the page's entity id reaches the presenter through the sections context; the row model carries no owner id.
- D-3: the sheet's key encodes its request as tag-first ids (`fields` / `life`), one kind, one arm.
- D-8: the pooled Place heading's Source count stays in Swift, over the sheet's own records (logged as an idea line).
- D-16: `provenance-loading.md` is retired in place (Status line) instead of deleted now; spike close deletes it.
- Version bump minor (0.52.0): the RPC removed was called only by this build.

## Round 1

### M-1 · blocker · Record counts and owner pooling would each be computed in two places
**Answer:** Fixed — D-5: the row computes `recordCount` and `ownerCount` once and passes them; the builders take counts (§6 macOS signatures); `PVProvenanceSheetContent.ownerGroups` is the one pooling rule (Codebase fit).

### M-2 · major · `CatalogDerivedRowKind` gets a third hand-kept spelling
**Answer:** Fixed — D-4: raw values in Go's spelling; one two-way wire mapping (`init?(wire:)`, `var wire`) used by `mapDerivedRow` and the request.

### M-3 · major · `entityId` added to the sections context while `PersonDetailSections` keeps its own copy
**Answer:** Fixed — D-2: `PersonDetailSections.entityId` goes; its sections read `context.entityId` (Deletes).

### M-4 · major · Two Swift types for one sheet reply
**Answer:** Fixed — D-10: `getProvenanceRecords` returns `CatalogProvenanceSheetRead`; `CatalogProvenanceRecords` dropped, `init(_ reply:)` deleted.

### M-5 · minor · D-10's function-typed parameter is the rejected flag in another form
**Answer:** Fixed — D-11: shared mappers send no outcomes; `reconcilerOutcomesProto` is added by `GetProvenanceRecords` only; T-11 tests it.

### M-6 · minor · Out row and Next adds point at S16-25, already landed
**Answer:** Fixed — the Out row and the sentence are gone; D-3 cites S16-25's shape as current.

### M-7 · minor · New key pattern with no line in the skill
**Answer:** Fixed — STEP-8 adds the line to `add-workspace-place`.

### M-8 · minor · Code comments the change makes false are not in the Steps
**Answer:** Fixed — STEP-1 (the `outcomes` doc) and STEP-5 item 5 (`RecordsSource`, the content type doc, the host doc, the registry arm) with their new text.

### M-9 · minor · Fixture keeps page fields with outcomes and restates Go's rule
**Answer:** Fixed — STEP-2: `counts:` defaults to `.init()`; page-field fixtures pass counts and no outcomes.

### M-10 · minor · The pooled heading's distinct-Source count stays in Swift
**Answer:** Fixed — kept as D-8; an Out row and a STEP-8 line in `docs/ideas/person-page-performance.md` log it.

### M-11 · minor · Written once
**Answer:** Fixed — D-12 keeps only the reserved line; the delete list lives in Deletes; Strings holds the copy.

### X-1 · blocker · STEP-2 deletes `sourceCount` but `PVProvenanceSheetContent` still calls it
**Answer:** Fixed — STEP-2 lists `PVProvenanceSheetContent.swift` (the `.single` summary) and says what replaces it; STEP-3 lists `Record.init` and `pooledValueGroups` for the denial and distinct-count callers.

### X-2 · blocker · The plan's `rg` checks are wrong as written
**Answer:** Fixed — every pattern uses `|` and `\(` in single quotes; STEP-2's pattern no longer matches `L10n.Conclusions.sourceCount(`.

### X-3 · blocker · STEP-7's final check cannot pass with the files listed
**Answer:** Fixed — D-16: the doc is retired in place; no link changes, so the check goes.

### X-4 · blocker · STEP-4 hides about ten changes across 24 files
**Answer:** Fixed, in part — the strings are their own step (STEP-4) and the Swift `renderCitations` removal moved to STEP-7. The key, content, row and host stay one step (STEP-5) because they swap together (the old key's ids come from the content's records); the step now has five ordered sub-parts, building after each.

### X-5 · major · The Swift checks cannot run on Linux
**Answer:** Fixed — §7 says where the Swift checks and `generate-proto.sh` run; a Stop condition covers working without `xcodebuild`.

### X-6 · major · Signatures left open
**Answer:** Fixed — §6 macOS gives the three builders' signatures, the summary rules over the passed counts, and the host's fields; the host takes `row:` and `request:` (the presenter builds the request); D-11 gives `reconcilerOutcomesProto`'s signature; T-9 says how it reads the sheet read's pair.

### X-7 · major · Old copy survives
**Answer:** Fixed — §6 macOS: the previews are renamed and the preview message becomes "The records could not be read."; Strings names both removals in `L10n.swift` and the catalog.

### X-8 · major · The Edges Neighbors line contradicts the Event builder
**Answer:** Fixed — Neighbors: the Event Date row filters with `hasRecords`; the Place Period row does not, and is the AC-2.2 and T-5 case.

### X-9 · minor · Smaller gaps
**Answer:** Fixed — D-8 says an empty `sourceID` counts once, as before; D-7 says `Record.init` and the picture viewer keep `in:`; STEP-2 names which tests pass counts; D-13 and a Stop condition cover `TestRenderScale`'s SELECT counts; STEP-8 gives `citation-formats.md` line 70's full sentence.

## Cost

Plan: 6,264 words at round 1, 7,048 after round 1's fixes (check-plan-docs info line).

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| 1 | maintainability | opus | 203k |
| 1 | executability | sonnet | 191k |
