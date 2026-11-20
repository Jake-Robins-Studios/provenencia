# Review — S15-05 The Person page's Sources section shows each Source's date

**Verdict:** Fits with changes — Ready with changes (round 2: no blocker)
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet)

## To user
- None. (The one product call, whether the section draws the date's unknown or supplied mark, was answered before review: no, same as the Sources list; user, 2026-11-20.)

## Writer's own calls
- D-3: `ownedValue`'s owner paths also move `source_records`, so an in-place date edit refreshes the Source record and every page that cites the Source (the parameter is renamed `sourceOwners`).
- D-5: the date's text moves to `Platform/SourceDateText` and its look to the recipe `PVPublishedDate`; `SourcesRowDate` and `SourcesListRow.spokenBase` go. This takes over S15-42's planned rename; the map's S15-42 entry was changed.
- D-7: the five published-date strings move to `L10n.PublishedDate` with values unchanged; the Person section's caption reads "Published"; two placeholder strings are deleted.
- D-8: the benchmark dates every Source (worst case) under S16-12's 50 ms / 8 MB budget.
- Preview data: the brief's frames use the app's existing Johann preview Sources rather than new invented ones.

## Round 1

### M-1 · blocker · The date's text rules would live inside a view type that non-view code calls
D-5 put `line`/`help`/`spoken` on `struct PVPublishedDate: View`; `SourceCopyModel.dateLine` and `SourcePageIdentityHeader.sourceDate` would call a list-cell recipe for text. `docs/design-system-layers.md` puts value formatting in `Platform/`; `PVLastUpdated` composes `TimestampFormat`.
**Answer:** Fixed — D-5 splits text (`macos/App/Platform/SourceDateText.swift`) from look (`PVPublishedDate`, view only); `.cursor/rules/design-system-layers.mdc` added to Rules that bind; Codebase fit, Deletes, STEP-4, the map's S15-42 line and the brief's inventory follow.

### M-2 · blocker · A second copy of the Source row's spoken label
D-6 joined title, type, date and ref by hand; `SourcesListRow.spokenBase` already does that join.
**Answer:** Fixed — `spokenBase` moves to `SourceDateText.spokenRow`; D-6 calls it; STEP-4 renames the list's caller and test.

### M-3 · major · The recipe's copy stays in the Sources list's namespace, and D-7's reason was wrong
No PR moves the `sources.list.*` published-date keys (S16-25 converts query keys; S15-42 moves `sources.page.date…`). Recipes own their namespace.
**Answer:** Fixed — D-7 moves the five strings to `L10n.PublishedDate` (`publishedDate.*`), values unchanged; Strings, Deletes, STEP-4 and the DoD sweep follow.

### M-4 · major · D-3 makes two skill lines false
`add-audit-scope` (owner paragraph, `source_records` paragraph) and `add-date-value` (ownership paragraph).
**Answer:** Fixed — STEP-2 updates those paragraphs; `ownedValue`'s parameter becomes `sourceOwners` (D-3).

### M-5 · major · The benchmark copies `datevalues.insert`'s columns in raw SQL
**Answer:** Fixed — D-8 seeds through `datevalues.InsertTx(tx, …)` and writes the id in the `sources` INSERT.

### M-6 · minor · `loadRecords` repeats the `fillDates` loop
**Answer:** Fixed — D-2 adds `lookupDates`, called by `fillDates` and `loadRecords`.

### M-7 · minor · Reach misses `.conclusionDetail`
**Answer:** Fixed — Reach and Scale name `.conclusionDetail` as a follower and accept it as the coarse read's cost, as a Source rename today.

### M-8 · nit · Swift field name
**Answer:** Fixed — `CatalogPersonClaimGroup.sourceDate` (D-4).

### X-1 · blocker · The plan is Blocked on a board that does not exist
**Answer:** Declined as a plan defect — this is the intended gate (plan-pr step 3). The plan stays `Blocked — on board S15-D3` until the user agrees the board; then the Board line is filled and status moves to Planned.

### X-2 · blocker · STEP-5 preview data: the brief's Sources do not exist in the previews
**Answer:** Fixed — the brief's frames now use `johannClaims`' five Sources; §6 macOS has a fixture → Source → `sourceDate` table, and says no Source is added or renamed.

### X-3 · major · STEP-1 benchmark seed choices
**Answer:** Fixed — D-8 names `InsertTx`, the value (`KindPoint`, year `1800 + src%200`), extending the `sources` INSERT, the baseline (25 ms, 5.7 MB) and that the figures are read, not asserted.

### X-4 · major · T-1 sequencing and wrapping
**Answer:** Fixed — T-1 names the `r.Run` wrapper for `SetDate`, the Build cases (dropped the crafted dangling-row case: `settleDate`'s own tests in S15-43 hold it), the Apply rows' order and where they sit, and that "date edit" is the row that proves D-3.

### X-5 · major · Checks a Linux host cannot run
**Answer:** Fixed — §7 opens with a **Host** note: STEP-1 and STEP-2 on any Go host; stop and report at STEP-3 without protoc and Xcode.

### X-6 · minor · STEP-4/5 small choices
**Answer:** Fixed — the `#Preview` values and T-6's phrase input are exact; D-6 says the recipe owns font and ink and gives the modifier order; D-7 says both `L10n.swift` and `Localizable.xcstrings`; STEP-5 says dated test groups pass `sourceDate:` directly; STEP-6 names `docs/deployment-plan/spike-15/completed.md`.

### X-7 · nit · Temptations
**Answer:** Fixed — two Out lines (the list's other spoken-label code; earlier plans' prose); the DoD sweep names the old names and leaves landed plans' prose.

## Round 2

Both reviewers checked every round-1 answer against the code at `41f1f3e` and found that they hold. Neither raised a new blocker.

### M2-1 · minor · Scope In row still named `CatalogPersonClaimGroup.date`
**Answer:** Fixed — §3 reads `sourceDate`.

### M2-2 · minor (note) · `SourceDateText.spokenRow` puts a row join in a type named for the date
**Answer:** Declined — the join's only varying part is the date's spoken text, and its two callers are a Sources-feature row and a Conclusions row; a recipe home (as `PVLastUpdated.label`) would make `PersonSourcesContent`, a pure content type, call a view recipe for a string, which M-1 removed. One function, one place, as M-2 asked.

### X2-1 – X2-6 · nit
**Answer:** Fixed — STEP-3 names `macos/App/Platform/Generated/engine.pb.swift`; STEP-4 places `L10n.PublishedDate` before `LastUpdated`, says the Sources list's look is checked by hand (§10 step 6), and T-8 renames `publishedDateTextAndSpokenBase` → `publishedDateTextAndSpokenRow`; T-1 spells out `1 Jun 1880`; D-2 says how the id slice is built.
