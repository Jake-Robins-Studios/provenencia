# Review — S16-40 An event records when it was known to be under way

Plan: [`S16-40-event-as-of-property.md`](S16-40-event-as-of-property.md). Brief: [`../design/S16-D3-composer-as-of-date.md`](../design/S16-D3-composer-as-of-date.md). The Batch 5 map review ran in the same round; its findings are logged here because they re-cut the PRs after this one.

## Round 1 (2026-11-16)

Lint: `check-plan-docs.py` clean on the plan and the brief before the reviewers ran.

### Executability (verdict: Not ready)

| ID | Sev | Finding | Answer |
| --- | --- | --- | --- |
| X-1 | blocker | AC-1.2 claimed the composer's Property menu follows binding order; `CitationComposerVocabulary.listedProperties` sorts by label | **Fixed.** AC-1.2, D-1, manual check 2 and the brief's domain facts say the menu sorts by label; D-1's reason is the Properties page and `ListBindings` |
| X-2 | blocker | AC-2.4 / AO-4 kept Before across a Property switch; `applyObservationProperty` calls `clearValue()` | **Fixed.** AC-2.4 and AO-4 now say the value clears, as for every Property, and the fresh As of draft shows two chips; Current state names `applyObservationProperty` |
| X-3 | major | Blocked on an undrawn board; Depends on did not match the map's Spike 15 row | **Fixed** (header names the shared files with S15-13, S15-42 as non-dependencies; STEP-4's check lists AO-1 – AO-5). Status stays `Blocked — on board S16-D3`, as `plan-pr` requires |
| X-4 | major | `subjectvocab_test.go` line 74 counts six event bindings | **Fixed.** STEP-1 changes it to 7; Current state names it |
| X-5 | major | T-2 rows underspecified; helper locations wrong | **Fixed.** T-2 moves to `TestDateReconcile` (gains a `cardinality` field) with literal `want`, `state`, `shown`, `folded`; helper locations corrected |
| X-6 | major | T-3 could not be written from its row | **Fixed.** T-3 and T-5 give every input, the `nil` / unknown-id result and the `CatalogProperty` construction (as `PropertiesModelTests`) |
| X-7 | major | Qualifier → label/identifier mapping loose | **Fixed.** D-6 names a private `chip(_:)` map and every L10n key and suffix |
| X-8 | minor | Unknown qualifier and nil Property unstated | **Fixed.** D-9 (unknown qualifier: not offered, nothing selected); T-5 (unknown id → true) |
| X-9 | minor | Stale details | **Fixed** with X-5 |
| X-10 | minor | Version bump not in a Step | **Fixed.** STEP-5 |
| X-11 | nit | — | Logged |

### Maintainability (verdict: Fits with changes)

| ID | Sev | Finding | Answer |
| --- | --- | --- | --- |
| M-1 | blocker | The Property rule sat on `DateQualifier` in the wire-mirror file, beside an existing `offersNegative` | **Fixed.** D-4: `CitationComposerVocabulary.offersBeforeAfter(propertyID:)` beside `offersNegative`, tested beside it (T-5) |
| M-2 | major | `TestVocabKeysMatchSeed` not extended | **Fixed.** STEP-1, T-1 |
| M-3 | major | `date` and `end_date` descriptions still send attestations there | **Fixed** as D-10 with recommended wording; the wording is **To user** (report) |
| M-4 | minor | Key-and-origin check repeats `productKey` | **Fixed.** `CatalogProperty.productKey`, the third twin |
| M-5 | minor | `offered` was a second qualifier list, and `DateQualifier.asStated` (added for X-7) would fail the parity guard | **Fixed.** D-5: one `DateValueDraft.pointQualifiers` list, `offeredQualifiers` on the draft; `DateQualifier` gains nothing |
| M-6 | minor | Coexistence paragraph's key list | **Fixed.** STEP-5 |
| M-7 | minor | `EvidenceGraphSnapshot.dateLine` had no home | **Fixed.** S16-42 scope; Out row here |
| M-8 | nit | Property field status | **Fixed.** Extend, in plan and brief |

### Map review, Batch 5 (verdict: Reshape → user)

| ID | Sev | Finding | Answer |
| --- | --- | --- | --- |
| K-1 | blocker | A stand-in through `Side` cannot carry samples against bounds | **Fixed.** S16-41 is a bounds check beside `lifespan`; the user restated the rule: as of x is start ≤ x ≤ end, read with start/end logic (2026-11-16) |
| K-2 | blocker | S16-42 / S16-43 split `eventDating` | **To user → re-cut** (2026-11-16): S16-42 owns every `eventDating` reader; S16-43 is the lifeline's open sides only |
| K-3 | blocker | Swift copies the display-date rule; every as-of over FFI | **Fixed.** Rule "The engine sends the dating, not the as-ofs"; S16-42 sends kind, low, high, open sides |
| K-4 | blocker | S16-42 changed five surfaces and two views under one brief | **To user → re-cut**: S16-42 (shared line, S16-D4 names every surface), new S16-44 (Event page Date row, S16-D6) |
| K-5 | major | Hand-kept key lists missed | **Fixed.** `LifeEventOf` (S16-41), `searchindex` with `ProjectionVersion`, `eventWhen`, `dateLine` (S16-42) |
| K-6 | major | Decisions in scope entries; open neighbors | **Fixed / To user answered**: rules for lifespan yes / birth-death no, no weight of its own, half-open bounds, as-of vs occurrence (user, 2026-11-16); line wording per case is S16-D4's |
| K-7 | major | Docs and skills Batch 5 makes false | **Fixed.** S16-40: `seeded-vocabulary.md`, `date` / `end_date` descriptions; S16-41: `matching-model.md`, `add-date-value`, `add-match-rule`; S16-42: `structured-date-model.md` |
| K-8 | minor | Name and type the helper for dates | **Fixed.** Rule: typed on date slices, not keys |
| K-9 | minor | Cross-spike order inconsistent | **Fixed.** S15-13 lands first, S16-40 rebases; S15-D8 → S16-D3 in the graph |
| K-10 | minor | Wiring | **Fixed.** Spike README; briefs D4 – D6 stay in the design track until written, as D1 and D2 did |

## Round 2 (2026-11-16)

### Executability (verdict: Ready with changes)

| ID | Sev | Finding | Answer |
| --- | --- | --- | --- |
| X2-1 | blocker | Stop condition 1 named a `TestPipelineMultipleCardinality` date case that does not exist | **Fixed.** It names T-2's two cases in STEP-2 |
| X2-2 | minor | Nothing automated checks `CitationPropertyFields` passes the flag | Logged: the pass-through is one argument; the rule itself is T-3 / T-5, the wiring is manual check 2 |

### Maintainability (verdict: Fits with changes; no new blocker)

| Item | Answer |
| --- | --- |
| K-9 half done: Spike 15's map did not name S16-40 | **Fixed.** S15-42's Depends on names S16-40 in Spike 15's map |
| S16-40 scope entry still named S16-43 / S16-42 for the Date row | **Fixed.** S16-41 to S16-44; Date row S16-44 |
| Stale stop condition | **Fixed** with X2-1 |
| Binding count hard-coded | **Fixed.** STEP-1 reads `len(BindingsForType("event"))` |

## Verdict

Fits; Ready. No open blocker. To user: D-10's wording of the `date` and `end_date` descriptions. The plan stays `Blocked — on board S16-D3` until the board is agreed.

## Re-plan (2026-11-16)

The user dropped the composer's Before/After rule: an as-of takes every qualifier and is read by the window rule (the event started by the window's last day and was under way on its first). S16-40 lost its chrome and its brief (S16-D3 deleted) and absorbed S16-41's matching work; S16-43 merged into S16-42 (the lifeline already draws open sides from the engine). Matching needs no new helper: an as-of whose window misses the other side's period stand-in is the date comparer's `different`, confirmed by a probe against `propertycompare.Compare` at `14fbfca` (1990 vs "Before 1985", 1990 vs "After 1995", BEF 1990 vs 1995–2000, AFT 1990 vs 1970–1985: `conflict`; 1990 vs 1985–2000 and vs "After 1985": `partial`, `contains`; 1991 vs "Before 1990": `partial`, `near`). Rounds 1–2 above reviewed the earlier plan; the rewritten plan gets its own round below.

## Round 3, on the rewritten plan (2026-11-16)

### Executability (verdict: Ready with changes)

| ID | Sev | Finding | Answer |
| --- | --- | --- | --- |
| X3-1 | blocker | Version base wrong: `main` at `14fbfca` is 0.17.0 | **Fixed.** Next minor after `VERSION` on the branch base (0.18.0 at `14fbfca`) |
| X3-2 | blocker | `samplesAgainst` signature and return shape | **Fixed.** D-6 gives the signature; the open-end downgrade happens inside it, so it returns plain Results; D-7 ranks with `propertycompare.Better` |
| X3-3 | major | Picks by raw `DateEnds`, ties, index mapping | **Fixed.** `valuecompare.SampleExtremes` returns indexes; ends read by `AboutEnds`; samples sorted by Same key first; dedupe stated |
| X3-4 | major | Reading of "no positive value for key"; own `date`; base vs sample partial | **Fixed.** D-6 reads `other[key]`; mine's own `date` does not stop it; D-7 ranks all candidates with one ordering |
| X3-5 | major | T-4 assertions underspecified | **Fixed.** Per-row `sim`, `ev`, `is(…)`; AC-3.4 reuses AC-2.5's years so 0.55 / 1.1 are known; helpers named; 999-value loop given |
| X3-6 | major | `TestInvariants` never draws an as-of | **Fixed.** `groups()` appends `p.Samples`; an `asOf` pool; Edges and the Stop condition reworded |
| X3-7 | major | Shortlist restructure unspecified | **Fixed.** D-9: a reaches list fed by the date loop and one open reach for as-ofs; T-5 construction given |
| X3-8 | minor | Registry pair-claim test, `TestLead`, `TestMeta` | **Fixed.** STEP-3 files, T-3 |
| X3-9 | minor | STEP-1 message, struct fields, paths, skill line | **Fixed** |
| X3-10 | minor | `subjectHasValues` unchecked | Logged: covered by the shortlist and compare tests; no new graphalign case |
| X3-11 | minor | Checks not runnable on Linux | Logged |
| X3-12 | nit | `event-as-of.md` stale helper line | **Fixed** |

### Maintainability (verdict: Fits with changes)

| ID | Sev | Finding | Answer |
| --- | --- | --- | --- |
| M3-1 | blocker | Two readings of one as-of's window | **Fixed** (with X3-3): `AboutEnds`, Same-key order; T-4 row "ABT widens the pick" in both orders |
| M3-2 | blocker | Invariants never see an as-of | **Fixed** (with X3-6) |
| M3-3 | blocker | A second ranking beside `better`, order-dependent | **Fixed.** `propertycompare.Better` exports the one ordering; D-7 uses it for conflicts and matches; T-7 |
| M3-4 | major | Shortlist re-derives samples and copies the open branch | **Fixed.** `subjectcompare.Samples` beside `Side`; D-9 feeds the existing emission |
| M3-5 | blocker | An as-of on a birth would fix the lifespan; hand key list | **Fixed.** D-10: `LifeEventOf` reads keys from the period and samples into `LifeEvent.Samples`, which widen the span only; T-6 |
| M3-6 | major | S16-42 would write a second extremes loop | **Fixed.** `valuecompare.SampleExtremes`, reading supplied by the caller; S16-42 Context names it |
| M3-7 | major | Skill and matching-model lines | **Fixed.** STEP-7 names lines 30, 36, 54 and 212 and an `rg` |
| M3-8 | minor | `RolePeriodEnd` mislabels samples | **Fixed.** Renamed `RolePeriodMember`; four docs; sweep in DoD |
| M3-9 | minor | Place claim contradicts the idea file | **Fixed.** Dropped |
| M3-10 | minor | Reconciler at 10,000 as-ofs | Measured 2026-11-16: 0.6 s at 1,000 distinct dates, 61 s at 10,000 (`foldValues`, quadratic). Every `multiple` Property has the cost today; this PR adds none. **To user**: park as crafted hardening, or cap distinct values per Property under the Batch 1 rule "Crafted fan-out is capped, not engineered" |
| K3-1 | major | "One dating" rule contradicts itself; stale lines | **Fixed.** Rule rewritten; map order line and feature doc updated |
| K3-2 | major | S16-42 should name what S16-40 leaves | **Fixed.** S16-42 Context |
| K3-3 | major | S16-42 too large; split search indexing | **To user** (recommend: yes, a backend-only row after S16-42) |

### User answers (2026-11-16)

- M3-10: parked as crafted hardening in `docs/ideas/share-packages.md`.
- K3-3: keep S16-42 whole.
- An as-of inside a closed period scores as partial, like a date inside a period.

## Round 4 (2026-11-16, round 2 on the rewrite; verdict: Ready with changes)

| ID | Sev | Finding | Answer |
| --- | --- | --- | --- |
| R4-1 | blocker | The Same-key sort is empty on untyped profile values | **Fixed.** D-6 keys `propertycompare.Typed(v, meta)`; T-4 row "a tie decided by the sort" in every value order |
| R4-2 | major | `subject_section_test.go`'s period-member list | **Fixed.** STEP-3 files, T-3 |
| R4-3 | major | Match strength reads from the extremes only, unstated | **Fixed.** Stated in D-6 with the 1983 / 1990 / 2002 example; T-4 row "extremes set the strength". Kept: comparing every sample to find a better match is the cost D-6 bounds |
| R4-4 | minor | Stale `RolePeriodEnd` in T-3; Edges tie text; D-7 tie | **Fixed** |
| R4-5 | minor | §12 vs an open To-user item | **Fixed.** Answered by the user and parked |
| R4-6 | nit | Dead negative in the invariant pool | **Fixed.** Dropped |

## Verdict

Ready. No open blocker, no open To-user item. Two rounds on the rewritten plan (rounds 3 and 4).

## Refresh (2026-11-17, `main` @ `754d8f6`)

`main` moved 42 commits from `14fbfca` (S15-14 citation format engine, #867 citation date terms and `valuemark`, S16-39). `git diff --stat 14fbfca 754d8f6` touches no file under the plan's Current state; `matchregistry/inventory_test.go` moved its doc-table reading to `core/internal/doctable`, and `TestKnobInventoryMatchesRegistry` still reads the same two sections of `docs/matching-model.md`. `VERSION` is still 0.17.0. No Decision changed; only the planning base moved. `check-plan-docs.py`: 0 errors, 0 warnings. No reviewer round: nothing to review beyond the base.
