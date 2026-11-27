# Review — S16-82 The Family read sends sibling groups and each couple's marriages

**Verdict:** Fits with changes — Ready; every finding answered, the To user item answered (2026-11-27).
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet)

## To user
- **M-1. Which PR deletes the old fields.** Answered 2026-11-27: S16-81 deletes them; the map and the working rule now say so. The map says S16-82 replaces `origin_siblings` and S16-81 has no Go or proto change; this plan keeps S16-82 additive and gives the Go, proto and Swift-mapping deletions (the Out row's list) to S16-81. Writer's recommendation: yes. Today's drawing is their only reader, and S16-81 rewrites it; replacing them here would mean adapting a drawing S16-81 throws away. On a yes, STEP-9 rewrites the map rows, both scope entries and the working rule.

## Writer's own calls
- `maxMarriagesPerCouple = 10` (D-6): real data has one to three.
- Couples are one flat list with indexes from groups and partner units (D-9, D-11).
- A co-parent known only through a child carries no marriage (Out row).
- No version bump.

## Round 1

### M-1 · blocker · New fields beside the old; deletions sent to a PR with no Go change
**Answer:** To user (above). Plan side done: the Out row lists every deletion; §5 Rules this plan bends names the change; STEP-9 writes it into the map.

### M-2 · blocker · `Couples` re-derives the parent-pairing rule
**Answer:** Fixed. D-13: `spouseLink` and `pairsParents` extracted from `parentUnits` and called by both (STEP-1).

### M-3 · major · Swift would match couples to groups
**Answer:** Fixed. D-11: `SiblingGroup.couple_indexes` and `FamilyUnit.couple_indexes`, computed in `persondetail` after the drop; AC-2.8, T-5, T-8.

### M-4 · major · Docs the PR makes false or incomplete
**Answer:** Fixed. STEP-9 and the DoD: `matching-model.md`'s MaxPivotEnd row, the kinship package doc, the caps list, `ideas/kinship-view.md` and the working rule's package.

### M-5 · minor · `Couple.Pivots` changes meaning
**Answer:** Fixed. D-12: `persondetail.FamilyCouple.Marriages`.

### X-1 · major · Proto and Xcode checks cannot run without the toolchain
**Answer:** Fixed. STEP-6, STEP-8 and §11: report as not run; never hand-edit generated files.

### X-2 · blocker · F4 half specified
**Answer:** Fixed. AC-1.4 states the four parents, who is whose child, and the four groups in order.

### X-3 · major · Couple order undefined
**Answer:** Fixed. D-5: partners in `kin[RoleSpouse]` order, then parent pairs `i < j`.

### X-4 · major · Couple edge cases
**Answer:** Fixed. D-5: dedupe by spouse id (first link wins); A's link else B's; pairs with the person skipped; a spouse who is also a parent listed once; T-3 rows.

### X-5 · major · `ByIDs` replacement, event type id, signature
**Answer:** Fixed. D-7 names each.

### X-6 · major · Cap set vs sent order
**Answer:** Fixed. AC-2.5 and T-7: the set is the first 10 in shape order, sent in date order.

### X-7 · major · Group test helper and format
**Answer:** Fixed. T-4: `groupsOf`, `"Heinrich+Anna: Margarethe, Johann, …"`, children in order.

### X-8 · major · Drop rules under-tested
**Answer:** Fixed. D-8 states the person-unread and same-parents cases; T-4 has a merged parent; T-9 extends `TestDropUnread`.

### X-9 · minor · AC-2.7's inputs case already passes
**Answer:** Fixed. AC-2.7 and T-5: a date edit, re-read, the new date carried and the event in the inputs.

### X-10 · minor · T-6 fixture
**Answer:** Fixed. T-6 uses the existing fixture's two marriages and asserts `Couples` is not empty.

### X-11 · minor · T-3 test data
**Answer:** Fixed. T-3 builds `Link`s by hand with `Shape{PatternMarriageSpouses, pivot}`.

### X-12 · minor · Caps list not updated
**Answer:** Fixed with M-4.

### X-13 · minor · Map row and plan disagree on replacing
**Answer:** Fixed with M-1 (STEP-9).

### X-14 · minor · STEP-4 too big; Swift mapping detail
**Answer:** Fixed. STEP-4 split into STEP-4 (read) and STEP-5 (order, drop, index); §6 macOS names the mapping functions and `FakeStore`.

## Round 2

### X-20 · blocker · Partner couples sent through `spouseLink`, which never sees the person
**Answer:** Fixed. D-5: a partner couple reads the person's own `kin[RoleSpouse]` link; `spouseLink` is for parent pairs only; a T-3 row with no `kinOf` entry for the person.

### X-21 · blocker · `TestPersonFamily` AC-1.14 breaks on the new index fields
**Answer:** Fixed. D-11: one `indexCouples`, called last in `Families` and again after the drop; AC-1.14 named in §8.

### X-22 · major · A dedupe that never fires; an unclear T-3 row
**Answer:** Fixed. The clause dropped; the T-3 row states its fixture and two couples.

### M-10 · blocker · D-1 moves the grouping out of the package the rule names
**Answer:** Fixed. Rules this plan bends (2): the user decided the engine groups; the package was the writer's wording; the rule now names `core/kinship`, reported to the user for veto. The DoD's "(none)" removed.

### Smaller point · Where the person sits in the kinship group
**Answer:** Fixed. D-4: appended last; `persondetail` sorts by birth.

## Cost
Plan: 4,459 words at round 1, about 5,600 at the answers.

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| 1 | maintainability | opus | 154k |
| 1 | executability | sonnet | 152k |
| 2 | both lenses | opus | — |
