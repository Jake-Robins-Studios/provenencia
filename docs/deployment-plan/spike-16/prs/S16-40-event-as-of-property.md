# S16-40 — An event records when it was known to be under way

**Status:** Blocked — on board S16-D3
**Spike / slice:** Spike 16 · Batch 5 · Slice 5a — An attestation is a sample
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S16-D3](../design/S16-D3-composer-as-of-date.md), board not drawn yet
**Board:** — (recorded here and on the brief's **Board** line when the user agrees it)
**Depends on:** S16-D3
**Blocks:** S16-41
**Branch:** `s16-40-event-as-of-property`
**Version bump:** minor, the next minor at merge (0.16.1 → 0.17.0 at the planning base) — a new seeded Property in new catalogs and a composer behaviour a researcher sees ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-seeded-vocabulary`](../../../../.agents/skills/add-seeded-vocabulary/SKILL.md), [`add-date-value`](../../../../.agents/skills/add-date-value/SKILL.md), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`
**Context:** [`../event-as-of.md`](../event-as-of.md); working rules [Batch 5](../deployment-plan.md#batch-5--event-as-of-dates): "As of is a fourth event date Property", "New catalogs only", "On every event", "The composer offers Exact and About on an as-of"; [`seeded-vocabulary.md` §3.2–3.3](../../../seeded-vocabulary.md#32-properties); [`conclusion-reconciliation.md` §8](../../../conclusion-reconciliation.md#8-cardinality)
**Planned:** 2026-11-16 against `main` @ `c1421af`
**Review:** [`S16-40-event-as-of-property.review.md`](S16-40-event-as-of-property.review.md)

### Implementer — read this first

1. **This file is the whole task.** Read it top to bottom before you change code. Then read every file under **Current state** and load every skill under **Skills to load**.
2. **Check the base.** Compare `main` with the **Planned** commit. If a file under **Current state** has changed so a row is no longer true, stop and report which rows.
3. **Decisions are made.** Do not reopen a **Decision** or a **Scope** line, and do not swap in a design you like better. If one cannot work, stop: say which ID it is, what you found (path, line, output), and what you would need. Do not improvise around it.
4. **Do only In.** Out stays out, even when it is one line away. Do not refactor, rename, or tidy code the plan does not name.
5. **Work the Steps in order.** Run each step's check before you start the next. A failing check is fixed in that step.
6. **Hit a Stop condition → stop.** Report it. Do not work around it.
7. **Done is the Definition of done.** Report each box with its evidence: the command and its result, the test name, or the manual check you ran.
8. **Docs-only lines in the DoD are part of the PR.** Do not skip them.

---

## 1. Objective

A researcher can record that a lasting event was under way on a day without claiming when it began, ended or happened: an obituary's "survived by X of Town Y" of 10 Jan 1990 becomes **As of 10 Jan 1990** on X's residence. A second record's As of 10 Feb 2015 sits beside it on the same event, and neither the Evidence graph nor the auto-reconciler reads the two as competing answers. The composer offers As stated and About for an as-of, not Before or After.

**Why now.** Dogfood, 2026-11-16: attestations put on `date` make one residence read `mixed` and make Promote score a date conflict between two records of it ([`../event-as-of.md`](../event-as-of.md#problem-dogfood-2026-11-16)). This PR gives the attestation its own Property; S16-41 to S16-43 teach the readers.

**What stays.** `date`, `start_date` and `end_date` and every reader of them. No list, page, Timeline, match or Promote result changes: nothing reads `as_of` until S16-41. Existing catalogs do not gain `as_of` (working rule "New catalogs only"). The Source page's date dialog keeps all four qualifiers.

## 2. User stories

**US-1.** As a researcher on a new project, when I author an Observation on an Event, I can pick **As of** and enter a date, so that an attestation is not recorded as when the event happened.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A catalog created by `onboarding.createCatalog` | `properties` has `as_of` (origin `provenencia`, label "As of", value type `date`, cardinality `multiple`), bound to `event` at sort order 5, locked; `event_picture` is at 6 |
| AC-1.2 | The composer's Property menu on an Event Subject | Lists As of after End date (the binding order) |
| AC-1.3 | A catalog created before this PR, opened after it | Has no `as_of`; opening adds none |

**US-2.** As a researcher, when I date an as-of, the editor offers only what an as-of can mean, so that I do not record a start or an end by mistake (S16-D3).

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Property As of, Kind Point | Qualifier chips: As stated, About (AO-1) |
| AC-2.2 | Property As of, Kind Range | No qualifier row, as any range (AO-2) |
| AC-2.3 | Editing an As of observation stored as `BEF 1990` | Chips: As stated, About, Before (selected); saving unchanged keeps `BEF 1990` (AO-3) |
| AC-2.4 | A draft on Start date with Before selected, switched to As of | Before stays shown and selected (AO-4) |
| AC-2.5 | Property Date, Start date, End date, or a researcher's date Property keyed `as_of` with origin `user` | The four chips, as today (AO-5) |

**US-3.** As a researcher, when two Sources each attest one residence on a different day, the event keeps both, so that two attestations never read as a disagreement.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Two as-of candidates from two Sources: 10 JAN 1990 and 10 FEB 2015 | Both kept, two displayed values, state `multiple` (not `mixed`) |
| AC-3.2 | Two as-of candidates: 1990 and 10 JAN 1990 | One value, 10 JAN 1990; the 1990 candidate folded into it |
| AC-3.3 | Two As of observations on one Event in an Evidence graph | No conflict mark on the card (the graph skips `multiple` keys) |

## 3. Scope

| In | Covered by |
| --- | --- |
| `vocabkey.PropertyAsOf` | STEP-1, AC-1.1 |
| `as_of` seed Property and event binding; `event_picture` moves to 6 | STEP-1, AC-1.1, AC-1.2 |
| Seed product-value test and autoreconcile `multiple` date cases | STEP-1, STEP-2, AC-1.1, AC-3.1, AC-3.2 |
| `SeededPropertyKey.asOf` in Swift | STEP-3 |
| `DateQualifier.offered(allowsBeforeAfter:current:)` and `DateQualifier.allowsBeforeAfter(for:)` *(new)*; `DateValueEditorForm` draws the offered chips (AO-1 – AO-5, AO-W1) | STEP-3, STEP-4, AC-2.1 – AC-2.5 |
| `CitationPropertyFields` passes the rule for its Property | STEP-4, AC-2.1 |
| `seeded-vocabulary.md` §3.2, §3.3 and the coexistence paragraph | STEP-5 |

| Out | Home |
| --- | --- |
| Any reader that dates, sorts, matches or draws an event by its as-ofs | S16-41, S16-42, S16-43 |
| The Event page's Date row showing as-ofs | S16-42 |
| `as_of` in an existing catalog | [event as-of follow-ups](../../../ideas/event-as-of-followups.md) (the user's later one-off command) |
| Refusing `BEF` / `AFT` on `as_of` in Go | not planned (working rule: the rule lives in the composer's editor) |
| Hiding As of on an event type | [properties and terms: lock event properties to event types](../../../ideas/properties-and-terms.md#lock-event-properties-to-specific-event-types) |
| A hint explaining As of in the composer | not planned (S16-D3 non-goal) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Property keys | `core/vocabkey/vocabkey.go` lines 89–92, `PropertyDate`, `PropertyStartDate`, `PropertyEndDate` | The three event date keys in the "read by name" block; no `as_of` |
| Seed Properties | `core/database/subjectvocab/registry.go` `seedProperties` (from line 155) | `date`, `start_date`, `end_date` have no `Cardinality` (single); `toponym`, `religion`, `languages_spoken` show the `Cardinality: propertymeta.CardinalityMultiple` shape |
| Seed bindings | same file, `seedBindings` (from line 188), event block lines 197–202 | `event_type` 0, `event_name` 1, `date` 2, `start_date` 3, `end_date` 4, `event_picture` 5; dates locked |
| Install | `core/database/subjectvocab/subjectvocab.go` `Install`; called only from `core/onboarding/ready.go` `createCatalog` | Upserts the registry into a new catalog; open never heals |
| Seed tests | `core/database/subjectvocab/subjectvocab_test.go` `TestSeedProductValues` (line 467), `TestInstallMatchesRegistry` | One case per product value; `event_picture` expects order 5 |
| Reconcile | `core/autoreconcile/pipeline.go` (`CardinalityMultiple` skips `elect`), `dates.go` `dateModule` | A `multiple` date keeps each distinct value; nested dates fold. No test covers a `multiple` date |
| Reconcile tests | `core/autoreconcile/pipeline_test.go` `TestPipelineMultipleCardinality`; `dates_test.go` helpers `date`, `ip`, `ymd`, `datePtr` | Text and term cases only |
| Swift keys | `macos/App/Platform/ConclusionVocabulary.swift` `SeededPropertyKey` (line 178), `DateQualifier` (line 279), `CatalogOrigin.isProduct` (line 158) | No `asOf`; `DateQualifier` holds the three qualifier strings |
| Swift guard | `api/ffi/swift_vocabulary_test.go` `TestSwiftVocabularyMatchesGo`, subtest "seeded Property keys are seeded" | Fails when Swift names a key the seed lacks; passes for a new seed key Swift does not name |
| Date editor | `macos/App/Features/Dates/DateValueEditorForm.swift` `qualifierSection` (lines 65–100) | Four hard-coded `PVChip`s ("", ABT, BEF, AFT), identifier suffixes `qualifier.exact`, `qualifier.abt`, `qualifier.bef`, `qualifier.aft`; no parameter limits them |
| Draft | `macos/App/Platform/DateValueDraft.swift` `pointQualifierOK` (line 275), `setKind` (line 105) | Accepts the four; switching to range clears the qualifier |
| Composer value field | `macos/App/Features/CitationComposer/CitationComposerAuthoringBox.swift` `CitationPropertyFields.valueControls` (line 368), `case .date` (line 415) | Builds `DateValueEditorForm(draft:accessibilityIdentifierPrefix:yearFocus:)`; `property` is `model.vocabulary.property(id:)`, a `CatalogProperty` with `key` and `origin` |
| Other editor caller | `macos/App/Features/Sources/SourceDateDialog.swift` line 47 | Source date; must keep four chips |
| Evidence graph marks | `macos/App/Features/EvidenceGraph/EvidenceCitedPropertyMarks.swift` `conflictCounts` | Skips `multiple` keys, from `PropertiesSnapshot.cardinalityByKey` |
| Swift tests | `macos/ProvenenciaTests/DateValueDraftTests.swift` | Draft validity; no qualifier-offer test |
| Docs | `docs/seeded-vocabulary.md` §3.2 table (line 315), §3.3 event block (line 371), the coexistence paragraph (line 355) | Three event date Properties |

**Precedent.** S11-48 seeded `religion` and `languages_spoken` as `multiple` Properties: a `seedProperties` row with `Cardinality: propertymeta.CardinalityMultiple`, a `seedBindings` row, a `TestSeedProductValues` case, and the §3.2 / §3.3 rows. Copy that; no migration. For the key-specific composer rule, copy the shape of `valueControls`' `property?.key == "age"` suffix, but put the rule on `DateQualifier` (D-4) instead of inline.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `as_of` is bound to `event` at sort order 5, locked; `event_picture` moves to 6 | The date Properties sit together in the composer's menu (AC-1.2); locked like the other dates (§3.2: event date Properties are locked) | Appending at 6 after the picture — splits the dates in the menu |
| D-2 | Seed description: "A day the event was known to be under way, from a record made then (an obituary's \"of Town Y\", a directory's year). Not when it began, ended or happened. More than one is allowed." | The Properties page shows it; it says what the label cannot | Leaving it empty — the label alone reads like a date of record |
| D-3 | No Go validation of the qualifier on `as_of` | Working rule: the rule lives in the composer's editor, not in `DateValue` or `observations`; S16-41's envelope skips an as-of with an open end | A per-Property refusal in `observations` — the user ruled it out |
| D-4 | The rule is two pure statics on `DateQualifier` (`ConclusionVocabulary.swift`): `allowsBeforeAfter(for property: CatalogProperty?) -> Bool` (false only for key `as_of` with `CatalogOrigin.isProduct(origin)`) and `offered(allowsBeforeAfter: Bool, current: String) -> [String]` (`["", ABT]`, plus `BEF` and `AFT` when allowed, plus `current` when it is `BEF` or `AFT` and not already listed; order "", ABT, BEF, AFT) | One home for the rule, unit-testable without a view; a researcher's own `as_of` (origin `user`) is not the seeded one (`CatalogOrigin.isProduct`) | A `Bool` computed inline in `CitationPropertyFields` — untestable and a second copy when S16-42 reads it; a `Set` parameter on the form — the order of chips becomes the caller's |
| D-5 | `DateValueEditorForm` gains `var allowsBeforeAfter: Bool = true`; `qualifierSection` loops over `DateQualifier.offered(allowsBeforeAfter:current: draft.qualifier)` and maps each value to today's label and identifier suffix (`exact`, `abt`, `bef`, `aft`) | The default keeps `SourceDateDialog` and every other caller unchanged; identifiers stay as UI tests know them | Hiding chips with `.opacity` or `.disabled` — S16-D3 says absent, not disabled |
| D-6 | `CitationPropertyFields` passes `allowsBeforeAfter: DateQualifier.allowsBeforeAfter(for: property)` | The Property is already read there (`property`) | Reading the key inside the form — the form has no Property |
| D-7 | `DateValueDraft` is unchanged | A stored `BEF` stays valid (AC-2.3); validity is not per Property | Clearing `BEF` on load — rewrites a value silently |
| D-8 | Reconcile is proven by tests in `autoreconcile` only; no code change | `multiple` already keeps distinct dates and folds nested ones (§8) | An end-to-end autoreconciler test — the cardinality reaches `Reconcile` through the generic `sqlLoadCandidates`, covered today |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `vocabkey.PropertyAsOf` *(new)* | const | `vocabkey.PropertyStartDate` | Extends the block; code reads the key by name from S16-41 |
| `as_of` seed row and binding *(new)* | registry row | `religion` row | Extends `seedProperties` / `seedBindings` |
| `SeededPropertyKey.asOf` *(new)* | const | `SeededPropertyKey.startDate` | Extends the enum; `TestSwiftVocabularyMatchesGo` guards it |
| `DateQualifier.allowsBeforeAfter(for:)`, `DateQualifier.offered(allowsBeforeAfter:current:)` *(new)* | func | `DateValueDraft.pointQualifierOK` (validity, all four); `DateValueDisplay` qualifier switch (labels) | Neither says which chips a Property offers; searched `DateQualifier`, `qualifier`, `pointQualifierOK` |
| `DateValueEditorForm.allowsBeforeAfter` *(new)* | parameter | `accessibilityIdentifierPrefix` (same form) | One flag, default true |

**Builds on.** `add-seeded-vocabulary` (registry rows, create-time Install); the S11-48 precedent; `DateValueEditorForm`'s chips.
**Deletes.** The four hand-written `PVChip` blocks in `qualifierSection`, replaced by one loop. Nothing else becomes dead.
**Next adds.** S16-41 reads `vocabkey.PropertyAsOf` in `matchregistry` and `subjectprofile`; S16-42 reads `SeededPropertyKey.asOf` in `EventDetailContent.dateRow`.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| An event with several date values on one Property | Evidence graph card marks (`EvidenceCitedPropertyMarks.conflictCounts`), conclusion detail `state` | `multiple` keys are skipped / read `multiple` today (toponym, religion); AC-3.3 |
| An event with only as-ofs | Event page Date row, Events list, Timeline | Shown as undated, exactly as an event with no date today (nothing reads `as_of` until S16-42); manual check 4 |
| A stored `BEF` / `AFT` as-of opened in the composer | `DateValueEditorForm` | The chip is shown selected (D-4, AC-2.3) |

### Scale

None — the seed adds one row to a create-time Install; the editor builds at most four chips; no list, loop or write changes.

### Edges

- **Assumptions.** `Reconcile` with `CardinalityMultiple` assumes a module whose `outvotes` is false keeps every distinct unit; `dateModule.outvotes` is false. T-2 holds it for dates. `TestSwiftVocabularyMatchesGo` assumes each Swift key is seeded; T-1 and the guard hold it.
- **Neighbors.** `date` (single): two disjoint dates stay `mixed` (`TestDateReconcile` "3 May and 14 June stay mixed", unchanged). A researcher's own `as_of` (origin `user`): four chips (AC-2.5, T-3). A range as-of: no qualifier row (AC-2.2). `start_date` with `BEF`: four chips (T-3).
- **Removed inputs.** A folded as-of (1990 into 10 JAN 1990) keeps its record on the kept value (`folded` reason), as any date (T-2).
- **Real data.** The seed is the only table: one new row and one new binding; `TestInstallMatchesRegistry` runs over the whole registry.
- **Untrusted size.** None — no read of data the app did not write is added.

### Schema

None — no catalog change: seeded rows only, at create time.

### Go core

| Package | Change |
| --- | --- |
| `core/vocabkey` | `PropertyAsOf = "as_of"` *(new)*, after `PropertyEndDate` |
| `core/database/subjectvocab` | `seedProperties`: `{Key: "as_of", Label: "As of", Description: <D-2>, ValueType: propertymeta.ValueTypeDate, Cardinality: propertymeta.CardinalityMultiple}` after `end_date`; `seedBindings`: `{TypeKey: "event", PropertyKey: "as_of", SortOrder: 5, Locked: true}`, `event_picture` → 6 |

Errors: none new.

### FFI

None — the Property reaches Swift through the existing vocabulary reads.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Date editor | Snowflake, Extend | `macos/App/Features/Dates/DateValueEditorForm.swift` | `allowsBeforeAfter` (D-5); chips from `DateQualifier.offered` |
| Qualifier chips | `PVChipGroup` + `PVChip` | `DesignSystem/Components/Chip/` | Same chips, same identifiers; fewer on As of |
| Property field | Snowflake, Ship | `CitationPropertyFields` | Passes the rule (D-6) |
| Property menu | `PVComboBox` | `CitationComposerAuthoringBox.propertyOptions` | Unchanged; lists As of from the seed |

States: Point on As of (two chips, AO-1); Range (no row, AO-2); stored Before/After (three chips, AO-3). Wide: unchanged, the authoring box keeps its 520pt column (AO-W1). Accessibility: the chips keep their labels; no new control.

### Strings

None — the label "As of" and its description are seed data, not L10n; no app copy is added or removed.

## 7. Steps

**STEP-1 — Seed `as_of`**
Files: `core/vocabkey/vocabkey.go`, `core/database/subjectvocab/registry.go`, `core/database/subjectvocab/subjectvocab_test.go`. Skill: `add-seeded-vocabulary`.
Do: add the key, the seed row and the binding (D-1, D-2); move `event_picture` to 6; add T-1's case and change `event_picture`'s expected order to 6.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/subjectvocab/... ./core/onboarding/... ./api/ffi/...` passes.

**STEP-2 — Prove the reconciler keeps as-ofs**
Files: `core/autoreconcile/pipeline_test.go`. Skill: `add-date-value`.
Do: add T-2's cases to `TestPipelineMultipleCardinality` with `propertymeta.ValueTypeDate`, using `dates_test.go`'s helpers.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/autoreconcile/...` passes.

**STEP-3 — The Swift key and the rule**
Files: `macos/App/Platform/ConclusionVocabulary.swift`, `macos/ProvenenciaTests/DateValueDraftTests.swift`. Skill: `add-swift-test`.
Do: `SeededPropertyKey.asOf = "as_of"`; `DateQualifier.allowsBeforeAfter(for:)` and `DateQualifier.offered(allowsBeforeAfter:current:)` (D-4); T-3.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/ffi/ -run TestSwiftVocabularyMatchesGo` passes; T-3 passes in `xcodebuild test`.

**STEP-4 — The editor offers the chips**
Files: `macos/App/Features/Dates/DateValueEditorForm.swift`, `macos/App/Features/CitationComposer/CitationComposerAuthoringBox.swift`. Skill: `add-ui-component`.
Do: D-5 and D-6. Keep each chip's label (`L10n.Sources.dateQualifierAsStated`, `L10n.Sources.dateQualifierAbout`, `L10n.Sources.dateQualifierBefore`, `L10n.Sources.dateQualifierAfter`), tone and identifier.
Check: the app builds; manual check 2 and 3 show the chips as S16-D3's frames.

**STEP-5 — Docs**
Files: `docs/seeded-vocabulary.md`, `completed.md`, `../deployment-plan.md` (S16-40 row), this plan (status), `../design/S16-D3-composer-as-of-date.md` → `../design/archive/`, `../design/README.md`.
Do: §3.2 adds `as_of  date  a day the event was known to be under way; cardinality multiple; locked on event; new catalogs only (S16-40)`; §3.3 adds `event  as_of  # date; multiple; locked (S16-40)` and moves `event_picture`; the coexistence paragraph adds: "use `as_of` for a day a record shows the event under way, without saying when it began or ended (an obituary's 'of Town Y'); several may sit on one event." Then per the Definition of done.
Check: links resolve; `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-40-event-as-of-property.md` passes.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/subjectvocab/subjectvocab_test.go` `TestSeedProductValues` | `{"as_of", "As of", date, multiple, "event", 5, true}` → passes; `event_picture` → order 6 | AC-1.1, D-1 |
| T-2 | Go | `core/autoreconcile/pipeline_test.go` `TestPipelineMultipleCardinality` | "disjoint dates both kept": `from("a", date(1, 1990, ip(1), ip(10)))`, `from("b", date(2, 2015, ip(2), ip(10)))` → two kept rows, `StateMultiple`; "a year folds into a day it contains": 1990 and 10 JAN 1990 → one kept row of 10 JAN 1990, the 1990 candidate folded | AC-3.1, AC-3.2, D-8 |
| T-3 | Swift | `macos/ProvenenciaTests/DateValueDraftTests.swift` `qualifiersOfferedForAsOf` *(new, parameterized)* | `offered(allowsBeforeAfter: false, current: "")` → `["", "ABT"]`; `(false, "BEF")` → `["", "ABT", "BEF"]`; `(false, "AFT")` → `["", "ABT", "AFT"]`; `(true, "")` → the four; `allowsBeforeAfter(for:)` → false for (`as_of`, `provenencia`), true for (`as_of`, `user`), (`start_date`, `provenencia`), and `nil` | AC-2.1, AC-2.3 – AC-2.5, D-4 |
| T-4 | Go | `api/ffi/swift_vocabulary_test.go` `TestSwiftVocabularyMatchesGo` *(existing)* | `SeededPropertyKey.asOf` → seeded | AC-1.1 |

AC-1.2, AC-1.3, AC-2.2, AC-2.4 and AC-3.3 are covered by the manual check: they are the existing generic paths (binding order, create-only Install, range form, `multiple` marks), each tested today for other Properties.

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `TestSeedProductValues` (the `event_picture` order), `TestInstallMatchesRegistry`, any Swift or Go test that counts event bindings (read the registry, do not restate it).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none expected)
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none)
- [ ] UI matches the brief inventory; no new kit primitive
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated
- [ ] Domain doc updated: docs/seeded-vocabulary.md §3.2, §3.3 and the coexistence paragraph
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Create a new project. Open Properties: As of is listed (date, Multiple, locked, bound to Event).
2. Open an image Citation in the composer, choose an Event Subject. The Property menu lists As of after End date. Pick it, Kind Point: the chips are As stated and About. Switch to Range: no qualifier row. Pick Start date, choose Before, then pick As of again: Before stays shown and selected (AC-2.4). Pick Start date again: four chips. At a Wide window, the box is the same width.
3. Save As of 10 Jan 1990 from one Citation and As of 10 Feb 2015 from a second Citation of another Source, both on the same residence handle. The Evidence graph card shows both values and no conflict mark.
4. Open that Event's page: the Date row reads as an undated event does today (S16-42 shows the as-ofs).
5. Open a project created before this build: Properties has no As of.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A test elsewhere restates the event binding order or count | T-1 runs first; fix the restating test to read the registry (`BindingsForType`), as the skill says |
| A UI test taps `.qualifier.bef` on a Source date dialog | The default keeps it; `SourceDateDialog` passes nothing |

**Stop and report if:**

- `TestPipelineMultipleCardinality` with two disjoint dates does not give `StateMultiple` (the reconciler needs a code change, which is Out).
- `CitationPropertyFields` has no `CatalogProperty` with `origin` for the chosen Property.
- S15-13 has changed `CitationPropertyFields.valueControls` so the date case is built elsewhere.
- The agreed S16-D3 board draws disabled chips, a hint, or a control not in the inventory.

## 12. Open questions

None.

## 13. PR

**Title:** S16-40 — An event records when it was known to be under way
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-40-event-as-of-property.md`.
