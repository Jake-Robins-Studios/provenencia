# Review — S16-26 Conclusion lists merge the rows a write touched

**Verdict:** Fits with changes — Not ready (round 1); every finding Fixed; round 2 checks the fixes
**Rounds:** 1. **Reviewers:** maintainability (Opus), executability (Sonnet)

## To user
- M-1 (answered 2026-11-15): should hidden lists merge by switching them to `whenHidden: .revalidate` (the map row's wording), or should the `.run` gate drop its visibility test so a merge runs for any warmed key with a current value while the lists stay `.markStale`? The user chose the second ("Merge always"). The Evidence graph list merges while hidden too. Recorded in D-9 and in STEP-8's map edits.

## Writer's own calls
- D-1/D-2: one Go key type (`ListKey`) for every order in `conclusionsummaries`, replacing `CompareString` and `dateKeyLess`. Measured at 16,000 persons: same order over 20,115 titles, 8 ms against 47.6 ms.
- D-5: the filter is a field on the existing list requests, not a new RPC; an empty filter lists every row, and Swift never sends one.
- D-7: `refreshCached` reads one batch; `merged` keeps its per-id form on top.
- D-12: FakeStore gives composed rows keys from its own order.
- D-13: T-9's five writes, chosen from the planning measurement (touched 1–4 ids, no untouched row changed).
- Budget: `ceilingListRowsOfWrite = 20 ms` at 4,000 persons (measured at most 1.3 ms); a 10%-of-whole-list stop at 16,000.

## Round 1

### M-1 · major · Merge hidden lists without making them reload whole when hidden
D-9 switched the lists to `.revalidate` because `apply`'s `.run` gate ties "may merge" to "reloads whole when hidden"; a label edit would then reload three hidden lists at once.
**Answer:** To user → answered: Fixed — D-9 drops the visibility test from the gate; the lists stay `.markStale`; AC-1.7, AC-1.9, T-15, T-20 added.

### M-2 · major · Restrict `applyHiddenPolicyOnAny` to catalog-wide slots
**Answer:** Fixed — D-10 adds the precondition and the doc wording.

### M-3 · major · Build `ListXOf` on `XByIDs`
**Answer:** Fixed — D-4: `ListPersonsOf` is `PersonsByIDs` then `fillUpdated`.

### M-4 · minor · Drop `sortByKey`'s `less` parameter
**Answer:** Fixed — D-2: `sortByKey[T any](rows, key func(T) ListKey)`.

### M-5 · minor · One concept, three names
**Answer:** Fixed — `ListKey` in Go (type and field), proto (`message ListKey`, `list_key`) and Swift (`CatalogListKey`, `listKey`).

### M-6 · minor · No parity guard between Swift's comparison and Go's
**Answer:** Fixed — `testdata/list_keys.json` with Go test T-2b and Swift test T-10b, after `draft_board_scenarios.json`.

### M-7 · minor · `CatalogListRow` depends on last-updated
**Answer:** Fixed — D-8: `Identifiable, Sendable where ID == String` plus `listKey`.

### M-8 · minor · FakeStore error hook and the guidance line
**Answer:** Fixed — D-12: `listPersonSummariesError` throws on every call; T-14 copies the graph list's failure test; STEP-8 adds `seededPersonSummaries` to `swift-tests.mdc`.

### M-9 · minor · "Next adds" names an unwritten future
**Answer:** Fixed — the Spike 15 example is gone.

### M-10 · nit · The map row still says the existing `.merged`
**Answer:** Fixed — STEP-8 rewrites the map row and the scope entry.

### X-1 · blocker · T-9 cannot capture each write's touched set
**Answer:** Fixed — D-13 names the `runWrite` helper over `writes.Run`, the exact fixture calls of each write, what is setup and what is measured, and that `Prop` lookups happen before the write (a catalog read inside the write's transaction blocks; seen at planning).

### X-2 · blocker · Swift tests that pin today's lists are not all listed
**Answer:** Fixed — §4 lists every test that changes and every one that stays (checked after D-9: `applyLeavingPageLoadsTheNextListOnce` stays because its list is stale before the write; `renamingAPropertyStalesConclusionPages` stays because the lists stay `.markStale`); T-16 – T-20 rewrite the rest; a failure in an unnamed test is a Stop.

### X-3 · major · The leave contract and code comments
**Answer:** Fixed — §6 Reach says what a hidden key does during `apply(_:_:leavingPage:)`; STEP-6 gives the new text of the five doc comments.

### X-4 · major · STEP-3 needs protoc; Mark stale row
**Answer:** Fixed — the **Tools** note names each step's tools; the proto step moved after the Go-only steps (STEP-4); STEP-8 says the Mark stale row needs no change.

### X-5 · minor · STEP-8 under-specified
**Answer:** Fixed — STEP-8 gives each replacement sentence.

### X-6 · minor · Small choices left open
**Answer:** Fixed — D-1 lowercases `Ref` in both branches; T-3 follows `TestPersonsByIDs` (no merge helper needed); D-12 types the error hook and names `seededPersonSummaries`; T-11 seeds keys through it; T-12 seeds lists by `setQueryValue` with no FakeStore rows; `mergedRows` calls `requireRowIDs` (D-7); the stop condition names T-9's five writes.
