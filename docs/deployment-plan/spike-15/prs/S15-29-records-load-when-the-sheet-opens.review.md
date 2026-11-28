# Review — S15-29 The provenance sheet loads its records when it opens

**Verdict:** Fits with changes — Ready with changes (every finding Fixed; the user answered the one To user)
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet)

## To user

- M-12 (round 2): the pooled Place heading's distinct-Source count, kept in Swift, bent the working rule "Records load when the sheet opens". Writer recommended bending the rule. **User (2026-11-28): "do it on this pr"** — Go counts it in this PR (D-8, STEP-1, T-15). That Go half was written after round 2, so no reviewer has read it; the implementer's STEP-1 tests are its first check.

Earlier, before review, the two product calls were asked before review and answered (user, 2026-11-28): a sheet whose read answers no owners gets no state of its own (D-9); a failed reload behind shown records stays silent; S15-D18 is descoped, since only the load area's two strings change.

## Writer's own calls

- D-1 / D-2: the page's entity id reaches the presenter through the sections context; the row model carries no owner id.
- D-3: the sheet's key encodes its request as tag-first ids (`fields` / `life`), one kind, one arm.
- D-8: Go pools a life row's place owners by `Place.Entity.ID` and the value's `Scalar`, and sends `pooled_support` on each displayed value of the sheet read only.
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

## Round 2

Both reviewers checked round 1's answers: M-1 – M-9, M-11 and X-1, X-3, X-6 – X-9 held; M-10, X-2, X-4 and X-5 were reopened below.

### M-12 · blocker · D-8 keeps the distinct-Source rule in Swift against the working rule (reopens M-10)
**Answer:** To user → answered: Go counts it in this PR. D-8 rewritten; STEP-1 (new) adds `PooledSupport`, `poolPlaceSupport` and `pooled_support = 6`; STEP-4 makes the heading read it; T-15; Out row and idea line removed; Rules this plan bends stays None.

### M-13 · blocker · `init(field:recordsField:…)` leaves open which field labels the value headings
**Answer:** Fixed — §6 macOS: headings and records both come from `recordsField`; `field` feeds only the summary. STEP-6 item 1 says so.

### X-10 · blocker · AC-4.4's `rg` cannot be copied from the table (reopens X-2)
**Answer:** Fixed — AC-4.4 points at the DoD's sweep, which carries the command with plain `|`.

### X-11 · blocker · Off macOS, the order and the stop rule disagree (reopens X-5)
**Answer:** Fixed — §7 opens: the PR needs the Mac; without `xcodebuild` or `protoc` stop before STEP-1; never hand-edit generated code. The Stop condition matches.

### X-12 · major · STEP-5 still large; `ConclusionAnchorRestoreTests` caller missing (reopens X-4)
**Answer:** Fixed — STEP-6 lists `ConclusionAnchorRestoreTests.swift` (passes `entityId: "e1"`); §7 says the tree builds after each sub-part and the tests pass at the step's end. The step stays one: its parts swap together.

### X-13 · major · `mapDerivedRow`'s inline owner mapping
**Answer:** Fixed — STEP-2: `mapDerivedRow` calls `mapOwnerField`.

### X-14 · minor · `reconcilerOutcomeProto` / `reconcilerOutcomesProto`
**Answer:** Fixed — no new helper; `GetProvenanceRecords` loops over `reconcilerOutcomeProto` (D-11); T-11 renamed.

### X-15 · minor · Smaller choices
**Answer:** Fixed — STEP-2 says "Add the doc comment"; STEP-3 says what counts a fixture passes; STEP-9's `macos-client-patterns.md` text covers the life rows sentence; D-3 drops empty ids; T-14 names `citationformat.Parse` and `Render` with `render_test.go`'s resolver; STEP-8 deletes the messages' comment blocks. Current state rows corrected (no `outcomes` doc today; `mergedName` is a static var; `ConclusionAnchorRestoreTests` added).

## Cost

Plan: 6,264 words at round 1, 7,048 at round 2, 7,617 at the verdict (check-plan-docs info line).

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| 1 | maintainability | opus | 203k |
| 1 | executability | sonnet | 191k |
| 2 | maintainability | opus | 178k |
| 2 | executability | sonnet | 175k |
