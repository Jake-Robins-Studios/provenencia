# Review — S16-62 The subject and grade seeds write through `writes.Run`

**Verdict:** Fits with changes — Ready with changes
**Rounds:** 1. **Reviewers:** maintainability (Opus), executability (Sonnet)

## To user

- **Answered (user, 2026-11-19): a follow-up PR, S16-64, added to the map.** Where the shared change builders go (M-3, M-5): this PR adds the seventh to tenth copy of a per-package `createChange` / `updateChange` pair (`sourcetypes`, `metadatafields`, `datevalues`, `namevalues` and `depictionvalues` already hold one), and five more copies of the `return struct{}{}, changes, err` adaptor around `writes.Call` (127 today). Two helpers would remove both: `rowchange.Created` / `Updated` / `Deleted` (entity, id, fields), leaving each package only its `rowFields`; and `writes.Apply(c, op, fn func(*database.Tx) ([]rowchange.Change, error)) error`. **Recommendation:** keep this PR to the precedent's per-package builders (as written), and add a Batch 6 follow-up row to the map, "One change builder and one change-only write call", that moves all ten packages and the 127 adaptors in one mechanical PR. Doing the extract here would roughly double the PR and touch packages it does not otherwise change.

## Writer's own calls

- **Grades stay `None`, so their install is atomic but not audited** (D-6). The map's Check said "one revision per domain"; the grades get none. The registry entry already says a grade write moves nothing, and no researcher writes a grade.
- **A Property upsert refuses a changed value type** (D-2). Today's `Upsert` overwrites it; only seeds and fixtures call it, and `Update` already refuses.
- **A Property delete's audit record gains `cardinality`** (D-3). One column list for create, update and delete.
- **The map's premise is corrected.** These seeds never reprojected search by hand; they lacked the transaction, the audit and the effects. STEP-8 rewords the map row, its Check and bar 33's `rg` (the old command finds the auto-reconciler, not seeds).
- **`nameformats` / `namealiases` Install stay off `Run`** (Out, not planned): every table they write is `None`.

## Round 1

### M-1 · blocker · `propertyterms` gets a second UPDATE statement beside `sqlUpdate`
D-4 added `sqlSeedUpdate` for the seed's flags beside `Update`'s `sqlUpdate`; S15-52's review refused the same shape (its M-2).
**Answer:** Fixed — D-4: `sqlUpdate` is the one statement and writes label, description and the three flags; `Update` passes the stored flags. Scope row, Codebase fit and STEP-2 updated.

### M-2 · blocker · `EnsureBindingTx` builds a second shape of the `subject_type_property` update change
D-7's update dropped `subject_type_id`, which `ReorderBindings` records beside `sort_order`; `EntityID` is only the property id.
**Answer:** Fixed — D-7: `bindingOrderChange` *(new)* builds the one update shape; `ReorderBindings` and `EnsureBindingTx` both call it. AC-1.9, T-5, Codebase fit and Deletes updated.

### M-3 · major · A fourth through seventh copy of the per-package create/update change wrappers
**Answer:** Fixed (minimum) and To user — D-1: each of the four packages holds `createChange` and `updateChange` as `sourcetypes` and `metadatafields` do, so no `Create` or `UpsertTx` builds its own literal. The `rowchange` extract across ten packages is the To user item; Out names it.

### M-4 · major · `add-seeded-vocabulary` still teaches `Install(c) error` after STEP-8
**Answer:** Fixed — STEP-8 rewrites line 21 and "Future vocabulary domains" steps 3–4 (a domain with effects: `Install(tx)`, `ActionInstall`, `installSeed`; an all-`None` domain keeps `Install(c)`). The DoD sweep adds `Install(c) error`.

### M-5 · minor · Five more copies of the `struct{}{}` adaptor around `writes.Call`
**Answer:** To user — with M-3; a helper for the new callers only would be a second way. Out names it.

### M-6 · minor · `sourcecredibilitygrades.ActionInstall` names an action never recorded
**Answer:** Fixed — D-8: the constant's comment says no revision carries it while the table is `None`.

### M-7 · nit · `subjectvocabtest` mixes two helper conventions
**Answer:** Fixed — D-9: the package comment says why the error-returning helpers keep the old signatures.

### X-1 · major · T-6 asserts `user_id` NULL, but `dbtest` cannot read it
**Answer:** Fixed — T-6 counts `WHERE user_id IS NULL` with `dbtest.Count`.

### X-2 · major · Missing-row lookup on a transaction is left to the implementer
**Answer:** Fixed — D-1: `propertyterms` and `sourcecredibilitygrades` get `lookupTx(q database.Querier, …)`; their `Lookup` goes through it.

### X-3 · minor · The new entity strings have no named home
**Answer:** Fixed — D-6: string literals, which `TestResolversCoverEveryEntityType` collects and checks.

### X-4 · minor · `InverseKey` is not trimmed
**Answer:** Fixed — D-1.

### X-5 · minor · Non-empty ID guard
**Answer:** Fixed — D-1 records that no fixture passes an `ID`.

### X-6 · minor · `properties.Update` keys equal only because `NullString("")` is nil
**Answer:** Fixed — D-3 says so.

### X-7 · minor · Reading a revision's action from the onboarding test
**Answer:** Fixed — T-8 names `dbtest.Count` with the action.

### X-8 · nit · Callers row reads as a double count
**Answer:** Fixed — § 4 row clarified.
