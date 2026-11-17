# Review — S16-44 The Event page's Date row shows as-ofs

**Verdict:** Fits with changes — Ready with changes (after round 1 fixes; the plan stays Blocked on board S16-D6)
**Rounds:** 1. **Reviewers:** maintainability (opus), executability (sonnet). Both read the plan and the S16-D6 brief.

## To user

- **As-of order** (asked while planning, answered 2026-11-17): date order, with Go ordering the values. → D-2.
- **A long as-of list** (M-2, M-8; answered 2026-11-17): the Conclusion page's paged fold (`ConclusionFold`, `Show N more`), in `ReconciledValueRow`, without waiting for S15-30. → D-5, brief DR-8.

## Writer's own calls

- D-1: Go sends `dating_properties` (key and role) on `EventSummary`, not on the shared `EventDating`.
- D-4: Swift reads `dating.kind` only to choose lines vs one value, never a key.
- D-5: every multi-valued row folds past 21 values, so a Place's long Names row folds too.
- D-6: one spoken-value helper and one relabel; `EventDetailContent.labeled` is deleted.
- An event with a `date` and as-ofs shows only its occurrence row (brief § 2.1).
- Version bump: minor.
- No round 2. Round 1's blockers were answered **Fixed** or **To user** (both answered), and the only reshape (M-1) follows the reviewer's own better shape. A fresh reviewer on the rewritten §5 – §8 is worth running once the board is agreed, before the status moves to Planned.

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
**Answer:** Fixed. D-3: `DateRowDisplay.Role` and `line(date:role:)`, tested by T-12. `EventDetailContent` only builds `Value`s.

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
