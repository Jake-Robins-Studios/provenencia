# Review — S16-44 The Event page's Date row shows as-ofs

**Verdict:** Fits with changes — Ready with changes, after round 2's fixes; no open blocker
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet). Both read the plan and the S16-D6 brief.

## To user

- **As-of order** (asked while planning, answered 2026-11-17): date order, with Go ordering the values. → D-2.
- **A long as-of list** (M-2, M-8; answered 2026-11-17): the Conclusion page's paged fold (`ConclusionFold`, `Show N more`), in `ReconciledValueRow`, without waiting for S15-30. → D-5, brief DR-8.
- **Board S16-D6** (agreed 2026-11-17): the role word in secondary ink, as drawn → D-3; the Why's own fold left to S15-27.

## Writer's own calls

- D-1: Go sends `dating_properties` (key and role) on `EventSummary`, not on the shared `EventDating`.
- D-4: Swift reads `dating.kind` only to choose lines vs one value, never a key.
- D-5: every multi-valued row folds past 21 values, so a Place's long Names row folds too.
- D-6: one spoken-value helper and one relabel; `EventDetailContent.labeled` is deleted.
- An event with a `date` and as-ofs shows only its occurrence row (brief § 2.1).
- Version bump: minor.
- The spoken label reads the 20 shown lines, not the board's `; 9,980 more` tail: the Show more button speaks the rest.
- A single-valued start or end shows its first displayed value only, even when mixed (round 2 X-8).
- A row with several fields and no dating line says `No date recorded` and titles its Why `Why “Date”` (round 2 X-4).

## Round 1

### X-1 · blocker · AC-3.5 and T-8 said `No date recorded` for a row that shows "Nothing recorded"
**Answer:** Fixed. The one-field row keeps that field's own empty text, as today. See AC-3.5, D-4 and T-9.

### X-2 · blocker · D-2 did not say whether `GroupRank` keeps the value's `Rank`
**Answer:** Fixed. D-2: `GroupRank` and `ValueRank` keep the value's `Rank`. Only the sort compares positions, through a `map[rank]position`, for both keys.

### X-3 · major · The Go fixture has no `as_of` helper
**Answer:** Fixed. STEP-1 names `f.asOf` and `asOfIn`, the variadic `Cite` call, and the phrase-only date literal.

### X-4 · major · A muted remainder line could not be drawn by the recipe
**Answer:** Fixed. Superseded by M-2: the remainder line is gone and the row folds with `ConclusionShowMoreRow`.

### X-5 · major · T-2's timing had no procedure
**Answer:** Fixed. STEP-1 runs T-2 5 times before and after the change and compares the medians; the Stop condition reads them.

### X-6 · major · The Why order with a start or end was not pinned
**Answer:** Fixed. T-5 asserts the record order (start, as-ofs, end) and the lead.

### X-7 · minor · Small mismatches
**Answer:** Fixed. Line 1314. The `summary` helper keeps its signature. The preview's `.years` case builds the dating from locals. T-5 pins the lead for AC-2.3.

### M-1 · blocker · D-1 had Swift choose which keys date an event (rule K-3)
**Answer:** Fixed, as the reviewer proposed. D-1: Go's `datingProperties(kind)` reads the event period registry, and `EventSummary.dating_properties` carries each key with its role. `dateRow` filters `detail.fields` by those keys, and `SeededPropertyKey.asOf` is dropped. New STEP-2, T-3, T-11 and AC-5.3. **Rules this plan bends** stays None.

### M-2 · blocker · The cap used a fake `Value` instead of the one Conclusion-page fold
**Answer:** To user → the paged fold (2026-11-17). D-5 folds in `ReconciledValueRow` with `ConclusionFold(limit: 20, minimumHidden: 2)` and reuses `L10n.Conclusions.showMore`. `eventDateMore` and `listedMore` are dropped, and the recipe is unchanged. S15-30 is not a dependency, because the row lives beside the fold.

### M-3 · blocker · The role wording was formatted in the feature
**Answer:** Fixed. Corrected in round 2 (M-10, M-11): D-3 adds `DateRowDisplay.line(date:role:)` returning `RoleLine { text, styled }` from one format per role, tested by T-12. `EventDetailContent` maps values through `PVProvenanceSheetContent.value(…role:)`, the one builder of a `Value`.

### M-4 · major · A third copy of the spoken `"; "` join
**Answer:** Fixed. D-6 adds `spokenValue` and `relabeled`, used by `init(field:)`, `spanning`, `dateRow` and `namesRow`.

### M-5 · major · The row's order and the header's low and high can disagree
**Answer:** Fixed (wording and tests). The case is named in Edges and in the brief's domain facts. T-1 rows cover a range plus a point, and `bef` plus a plain date. The order is not changed to match the header: the row is in date order and the header is the dating.

### M-6 · major · The Why at 10,000 records depends on S15-27
**Answer:** Fixed. Scale names it. The Out row points to S15-27. Both maps note the dependency (the S16-44 scope entry and the S15-27 row).

### M-7 · minor · Sort by `autoreconcile.SortKey`
**Answer:** Fixed. D-2 uses `SortKey`.

### M-8 · blocker · DR-8 went against the fold rule
**Answer:** To user → the fold (with M-2). The brief's DR-8 and inventory now name `ConclusionShowMoreRow`, and `ReconciledValueRow` is marked Extend.

### M-9 · major · The inventory left the role wording out of the shared formatter
**Answer:** Fixed. The brief's "Row date text" row is marked Extend and carries the role words.

## Round 2

Fresh reviewers saw the document and this log, after the board was agreed. Both checked round 1's answers: all held except M-3's.

### X-1 · blocker · The AC-5.1 `rg` would hit the generated Go descriptor's reserved names
**Answer:** Fixed. The `rg` excludes `*.pb.go` (DoD, STEP-4, manual check).

### X-2 · major · T-11 had no way to build its cases
**Answer:** Fixed. T-11 calls `eventSummaryProto` directly with each of AC-5.3's four lists, as the `eventDatingProto` tests do.

### X-3 · major · The Swift `Role` cases and `UNSPECIFIED` were unnamed
**Answer:** Fixed. D-1: Go's `DatingRole` starts at 1; Swift `Role { occurrence, start, end, asOf }`; `mapEventSummary` drops `UNSPECIFIED` and `UNRECOGNIZED` entries.

### X-4 · major · Several fields with an empty dating line
**Answer:** Fixed. D-4 and D-6: `No date recorded`, and `whyTitle(lead ?? label)` when the row has records. A T-9 case covers it.

### X-5 · minor · Where Show more sits
**Answer:** Fixed. D-5: after the summary HStack, before the other-values card, in both `.why` and `.sheet` modes.

### X-6 · minor · The gap had no SwiftUI unit
**Answer:** Fixed by M-10. The styled copy is one `Text`, so there is no gap to choose.

### X-7 · minor · One listed value
**Answer:** Fixed. D-6 keeps the `> 1` gate. A single styled line speaks its text.

### X-8 · minor · A mixed start or end
**Answer:** Fixed. D-3 uses the first displayed value of a single-valued field.

### X-9 · minor · Ordering and stale wording
**Answer:** Fixed. The `dated` helper gains `properties:` in STEP-3, the stop condition names STEP-4, the DoD names STEP-5, T-12 is its own test, and T-2 times with `time.Since`.

### M-10 · blocker · Role word and date joined in Swift
**Answer:** Fixed. D-3 has one format per role (`rowFrom`, `rowAsOf` reused, `rowUntil`) through `StyledFormat.attributed`, with a `DateRun` attribute on the date. `Value.styled` replaces `prefix`. The brief's "Row date text" row is updated to match.

### M-11 · blocker · Feature-built `Value`s with positional ranks
**Answer:** Fixed. `PVProvenanceSheetContent.value(…role:)` builds every line. `Value.id` is `propertyKey#rank`, and `rank` keeps the wire rank.

### M-12 · major · Stale M-3 answer and log header
**Answer:** Fixed. M-3's answer is corrected, round 2 is recorded, and the header matches the plan.

Not raised by the reviewer, taken anyway: D-5 now keeps its pages in a `ConclusionFoldState`, as `docs/macos-client-patterns.md` does.
