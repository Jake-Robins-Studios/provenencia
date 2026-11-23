# Review — S15-64 Boards show inherited values (and brief S15-D33)

**Documents:** [`S15-64-inherited-values.md`](S15-64-inherited-values.md), [`../design/S15-D33-inherited-values.md`](../design/S15-D33-inherited-values.md)
**Planned against:** `main` @ `3d8863a`

## Round 1 (2026-11-23)

**Maintainability** (fresh context): Fits with changes. **Executability** (fresh context, the implementing model): Not ready.

### M-1 · blocker · D-8 adds a second way to update the cache after a board write
The first draft's D-8 put a `level == .source` branch in `SourcePageContext.applySavedMetadata` that applied `.mutatedSourceWorkspace`. The reviewer pointed at the effects registry's keyed reads (`effects.Read`, `ReadSourceHoldings`, `CatalogRead`, `.sourceWorkspace`'s `refreshes`).
**Answer:** Fixed. The new D-9 adds `effects.ReadInheritedValues` ("inherited_values"), reported by `source_metadata`, mirrored in `CatalogRead`, and followed by `.sourceWorkspace`. `applySavedMetadata` is unchanged. The reload is measured at Scale by T-12, with a 100 ms Stop condition. S15-56 adds the Artifact and graph paths (Out).

### M-2 · blocker · The display rule for a marked value would be copied into Swift
**Answer:** Fixed. D-4 adds `citationformat.Display`, the field branch of `printed`, which `printed` now calls. The wire carries `display_text` (D-6). Swift's only rule is "Unknown" when the text is empty. `CatalogMetadataField.unknownText` is dropped.

### M-3 · blocker (Floors) · D-1 renames the walker a binding rule names
**Answer:** To user (R-1 below). The plan lists it under **Rules this plan bends**. STEP-9 rewrites the rule's sentences and the map row to name `Nearest`.

### M-4 · blocker · D-7 relies on a Swift copy of which rows stay
**Answer:** Fixed. D-5 and D-6 add `StaysWithoutValue` / `stays_without_value` (suggested, or a head), computed in `buildEntries`. D-7 makes `isEmptyRow` read it and drops the "opened empty" guess. AC-2.4 and T-9 cover a valued unsuggested head. This also answers X-3.

### M-5 · major · The brief's inventory contradicts itself; PVInput cannot draw the value
**Answer:** Fixed. The brief's IH-1 and IH-2 now pin one composition. At rest, the inherited value is drawn through `MetadataValueText` (secondary colour, italic when unknown) with the caption "From Source". Clicking it opens today's empty input with "Overrides …" under it. The inventory and D-11 match. This also answers X-4 and part of X-5.

### M-6 · major · The Swift inherited value repeats the entry's value fields; MetadataValueText cannot take it
**Answer:** Fixed in part. D-8 states the input shape: `MetadataValueText.init(text:openURL:isURL:…)`, with the entry init forwarding to it. One shared value struct for own and inherited values is declined for now: mapping an own value's mark belongs to S15-41, which reshapes the entry then. Mapping it here would leave an unused field.

### M-7 · minor · Caption style repeated
**Answer:** Fixed. A file-private `MetadataBoardCaption` serves the taken notice and the two new captions. The brief's inventory row is now Snowflake / Extend.

### M-8 · minor · Comments made false
**Answer:** Fixed. STEP-2, the Swift entry types row in § 6 and the DoD sweep now name the two "only link" comments. `.mutatedSourceWorkspace` is untouched now (M-1).

### M-9 · nit · `MetadataOwner owner` in place of a `level` string
**Answer:** Fixed (D-6).

### X-1 · blocker · AC-1.5 and T-2 use fields a Census board never lists
**Answer:** Fixed. The marks case is now a Book Source, since Book suggests `publisher` and `publication_place` (`registry_suggestions.go`). This applies to AC-1.5, T-2 and the brief's § 5 data and D33-5.

### X-2 · blocker · A one-column frame that is not built
**Answer:** Fixed. The brief drops D33-9 and every one-column clause, and § 2 says there is no one-column form (S15-D5).

### X-3 · blocker · Clear on an unsuggested head undecided
**Answer:** Fixed by M-4. D-7 also covers a row added through Add field: it has no inherited value and no "Overrides" caption until the owner's Save (T-9).

### X-4 · blocker · STEP-7 and D-10 cannot be executed
**Answer:** Fixed in part. D-11 pins the composition from the brief. D-12 (the board's refinements) remains open while the plan is Blocked on the board, as plan-pr allows.

### X-5 · major · Brief and plan disagree on where the row is drawn; mark rendering home
**Answer:** Fixed by M-2, M-5 and M-7.

### X-6 · major · Brief data does not match the real Census list
**Answer:** Fixed. § 5 lists the seeded Census order (16 fields) and the Book list.

### X-7 · major · `unknown_text` source
**Answer:** Fixed by M-2. The engine prints the value, and the Swift field gains nothing.

### X-8 · major · Unknown level dropped silently; reload failure
**Answer:** Fixed in D-8 and D-9. An unknown level is a version skew guarded by `swift_vocabulary_test.go`. The reload is the session's ordinary refresh: a failed read shows as the page's read failure does today, and the patched rows already on screen stay.

### X-9 · minor · Check, order and naming gaps
**Answer:** Fixed.
- STEP-9 names where each doc line goes.
- T-6 says census suggests `url`.
- T-10 moved to a handler test, because the write's effects are built there.
- T-11 follows the reads test at `SourcePageModelTests` line 445.
- FakeStore computing values is an Out line.
- The step-7 check now runs all seven manual steps.

## To user

- **R-1** (from M-3). The rule "A format reads a field from the nearest level that holds it" names `CitationValues.Resolve` as the one walker. D-1 moves the walk into `CitationValues.Nearest`, which `Resolve` calls, and the inherited value reads `Nearest` too. **Recommendation:** accept, and have STEP-9 rewrite the rule sentence and the map row.

## Verdict after round 1

All round-1 findings are answered: Fixed, Fixed in part with a reason, or To user. Round 2 runs because round 1 had blockers.
