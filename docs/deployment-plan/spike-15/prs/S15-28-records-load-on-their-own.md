# S15-28 — A value's records load on their own

**Status:** Planned
**Spike / slice:** Spike 15 · Slice 8 — Provenance loading
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: Go and the wire only; the app's rows and sheet read what they read today until S15-29)
**Board:** —
**Depends on:** S16-11 (landed #793), S16-19 (landed #821), S16-24 (landed #839), S16-30 (landed #812), S16-80 (landed [#1007](https://github.com/Jake-Robins-Studios/provenencia/pull/1007))
**Blocks:** S15-29
**Branch:** `s15-28-records-load-on-their-own`
**Version bump:** minor, 0.49.0 → **0.50.0** (if `main`'s `VERSION` has moved, the next minor after it): a new RPC old clients ignore ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`use-catalog-session`](../../../../.agents/skills/use-catalog-session/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`
**Context:** [`provenance-loading.md`](../provenance-loading.md) "Load records when the sheet opens"; working rules: "Records load when the sheet opens", "Citations render on demand, from SQL", "Today's line stays the fallback, in Swift"; [`conclusion-reconciliation.md`](../../../conclusion-reconciliation.md) (the package table)
**Planned:** 2026-11-27 against `main` @ `5704482`
**Review:** [`S15-28-records-load-on-their-own.review.md`](S15-28-records-load-on-their-own.review.md) — Fits with changes / Ready with changes, 2 rounds; every finding Fixed; Planned

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

The engine gains what the provenance sheet needs to load a row's records when it opens instead of with the page: each field's record and Source counts on the detail read, the two denial facts on every record, and one sheet read (`GetProvenanceRecords`) that takes a row's (owner, Property) pairs, or a Person and a life row kind, and returns its owners' fields with their records, the records' rendered citations, and what it read. Nothing changes in the app yet: S15-29 switches the rows and the sheet to these reads and then stops the detail read sending records.

**Why now.** Working rule "Records load when the sheet opens". S15-21 put a load-on-open call under the sheet, S15-27 bounded what it draws, S15-31 made every detail row open it; the records are the last thing the sheet still takes from the page read.

**What stays.** The detail read still sends every field's outcomes, its derived rows and its pictures (D-1). `PictureTile.Record` keeps its outcome. `RenderCitations` stays for the app's current key. No catalog change, no SQL query added to the detail read.

## 2. User stories

**US-1.** As the app, when I draw a detail page's rows, I read each field's record count and Source count from the engine, so I never count records myself.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A name field with two records from one Source (`namedPerson`: James Robins, Kenneth Robins) | `record_counts` = records 2, sources 1 |
| AC-1.2 | A name field merged from two Sources, one record each, the same name on both | records 2, sources 2 |
| AC-1.3 | Two displayed values whose counted outcomes come from Sources A, A and B | sources 2 (distinct), not 3 |
| AC-1.4 | Two displayed values with Support 3 and 1 and no outcome counted under either | sources 4 (summed Support) |
| AC-1.5 | A Person's birth date row's owner field (`derivedRowsFixture`) | the owner field's `record_counts.records` = 2 |

**US-2.** As the app, when I word a record, I read whether a negative record eliminated a value and who denied a denied record, so I never search the field's records.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | A negative record that eliminates "James Robbins" (`TestForEntityEvidence`'s fixture) | the negative's `denied_a_value` is true; the denied record's `denied_by_source_title` is the negative's Source title |
| AC-2.2 | A negative record that eliminates nothing | `denied_a_value` false |
| AC-2.3 | A denied record whose denier is not among the field's outcomes, and any record not denied | `denied_by_source_title` "" |

**US-3.** As the app, when a provenance sheet opens, I ask one read for the row's records and their citations.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `fields` = one pair (`namedPersonID`'s Person, its name Property) | one owner: `entity` the Person, `event` and `place` empty, the name field with its value, both outcomes and counts {2,1}; `citations` holds the one Citation both records share |
| AC-3.2 | `fields` = (an event Subject's handle, `as_of`), (the same handle, `date`), where only `as_of` has records | one owner, the `as_of` field; `date` is left out |
| AC-3.3 | `derived` = (a Person, birth place), where three Sources name Swift Current and one names England (S16-80's fixture) | the owners `PersonDerivedRows` gives for that row, in its order, each with its `place`; the England link's records read `outvoted` with vote 3 of 4 |
| AC-3.4 | A pair repeated; an unknown or merged owner; a Person with no such row; a kind of `DERIVED_ROW_KIND_UNSPECIFIED`; no `row` | repeated: one owner, first place; the rest: no owners. None is an error |
| AC-3.5 | A malformed owner, Property or Person id | `request.invalid_id` |
| AC-3.6 | Any answer | `inputs` names the owners read (and the Person, for `derived`), every Evidence graph and Source of the records, and what the render read |
| AC-3.7 | Citations past `citationrender.MaxCitations` | every Citation is rendered, a batch of at most 2,000 at a time, in one transaction |
| AC-3.8 | The read run twice warm | the second answers the same bytes, issues no graph query, and prepares only the SELECTs `citationrender.Render` prepares for the same Citations |

**US-4.** As a contributor, I know the size of the records the page read sends and how fast the sheet read is at Scale.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | A Person with records from 30 Sources | the test logs the detail's payload with outcomes and with every outcome cleared; the second is smaller |
| AC-4.2 | One name field with 1,200 records, each its own Citation, over 30 Sources | `GetProvenanceRecords` answers 1,200 outcomes and 1,200 citations, warm, within 600 ms |

## 3. Scope

| In | Covered by |
| --- | --- |
| `FieldRecordCounts` on every field, on the wire as `record_counts` | STEP-1, STEP-4, STEP-5; AC-1.x |
| The two denial facts on every outcome | STEP-1, STEP-4, STEP-5; AC-2.x |
| One pairs-to-fields step under `FieldRecords` and the life rows | STEP-2; AC-3.1 – AC-3.4 |
| `citationrender.RenderAll` | STEP-3; AC-3.7 |
| `conclusiondetails.ProvenanceSheet` and `GetProvenanceRecords` | STEP-3, STEP-4, STEP-5; AC-3.x |
| Payload measurement and the 1,200-record timing | STEP-6; AC-4.x |
| The comments and the domain doc line the read makes false | STEP-4, STEP-7 |

| Out | Home |
| --- | --- |
| Rows reading `record_counts`; the sheet's key calling `GetProvenanceRecords`; Swift's `distinctSourceCount`, `sourceCount`, `recordCount`, `deniedSomething` and denier search going | S15-29 |
| The detail read no longer filling `ConclusionField.outcomes` (top-level fields and derived owners) | S15-29 (D-1) |
| `RenderCitations`, its method, messages, handler and store method, `citationrender.Render` (its only caller goes), and `docs/citation-formats.md`'s line naming `RenderCitations`, once the sheet no longer calls it | S15-29 |
| The sheet's pooled value groups' Source count (`pooledValueGroups`) | S15-29: it holds the records then |
| `FakeStore` and `GoStore` methods for the new read | S15-29 |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Detail composition | `core/database/conclusiondetails/conclusiondetails.go` `fieldsOf`, `finish`, `recordReader.outcome` | `fieldsOf` already composes named (owner, Property) pairs through `only`; `finish` orders outcomes and sets `GroupRank`; no counts or denial facts |
| Field, outcome and owner types | same file `Field`, `Outcome`, `OwnerField`, `DerivedRow` | no counts; `DeniedBy` is the only denial fact |
| Life rows | same file `PersonDerivedRows`, `ownerVerdict` | builds all four rows' owner lists, batch-loads with `g.Nodes`, builds `only`, calls `fieldsOf`, then picks each owner's field by Property: the pairs-to-fields step, inline |
| Package comment | same file, `package conclusiondetails` doc | its first sentence ends "…joined to the record's Source: the records a detail page's provenance sheet shows." |
| Render | `core/database/citationrender/render.go` `Render`, `render`, `MaxCitations`, `MaxBatchBytes` | `Render` refuses more than 2,000 ids; `render(tx, ids, in)` refuses a batch over 8 MiB with `citations.ErrInvalid` |
| Detail handler | `api/ffi/handlers/conclusion_detail.go` `conclusionFieldProto`, `reconcilerOutcomeProto`, `derivedRowsProto` | `derivedRowsProto` holds its own `kinds` map and maps each owner inline |
| Render handler | `api/ffi/handlers/citation_render.go` `RenderCitations` | maps results inline |
| Dispatch | `api/ffi/dispatch.go` `MethodRenderCitations` and its `case` | last method is `METHOD_MOVE_TO_SOURCE = 128` |
| Proto | `api/proto/engine.proto` `ConclusionField` (last field 7), `ReconcilerOutcomeDetail` (last field 25), `ConclusionOwnerField`, `PictureDetail` (comment "as the Why / shows it", wrapped across two lines), `RenderedCitation`, `PageInputs`, `DerivedRowKind` | — |
| Swift counts and denial rules (read only) | `macos/App/Platform/ReconciledValueDisplay.swift` `sourceCount`, `distinctSourceCount`, `deniedSomething`, `outcomePhrase` `.denied`; `macos/App/Features/Conclusions/ReconciledValueRowModel.swift` `recordCount` | the rules Go now states: AC-1.x and AC-2.x equal them |
| Domain doc | `docs/conclusion-reconciliation.md` package table, row "Detail read: each field's state, values, and outcomes with their evidence" | names no sheet read |
| Tests and fixtures | `core/database/conclusiondetails/conclusiondetails_test.go` `TestForEntityEvidence`, `TestForEntityRecordsInputs`, `TestForEntityManyAsOfs`, `fixture.asOfIn`, `holdsIDs`; `placerecords_test.go` `TestPlaceOwnersCarryTheVote`, `TestPersonDerivedRowsRecordInputs`, `fixture.placedBirth`; `core/database/citationrender/scale_test.go` `seedScale`, `TestRenderScale`; `api/ffi/handlers/conclusion_detail_test.go` `TestGetConclusionDetail`, `TestGetConclusionDetailWarmReadsNoRecordSQL`, `TestGetConclusionDetailCarriesDerivedRows`, `derivedRowsFixture`; `conclusion_summaries_test.go` `namedPersonID`; `promote_align_test.go` `namedPersonOnNewSource`; `promote_test.go` `promoteInDir`; `subjects_test.go` `subjectFixture`; `person_detail_test.go` `wantInputs` | — |

**Precedent.** `persondetail` (`Claims`, `PersonFamily`, `PersonEvents`, `RecordLinks`, with `api/ffi/handlers/person_detail.go`) is the shape of a section read: one core function records its inputs, the handler only parses and maps. S16-24 ([plan](../../spike-16/prs/S16-24-reads-report-inputs.md)) is the inputs shape (`in := c.Graph().PageInputs()`, `out.Inputs = pageInputsProto(in)` last; `wantInputs`). `TestRenderScale` is the timing shape (`databasetest.WithinBudget`, `databasetest.Warm`).

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | The detail read keeps sending outcomes in this PR; S15-29 stops it once Swift reads the counts and the sheet read (user, 2026-11-27) | `check-pr.sh` builds the app, which reads `ConclusionField.outcomes`; an empty field hides every provenance button | Dropping them here — breaks the build or the app |
| D-2 | One sheet read returns the owners with their records and the records' rendered citations, with one `inputs` (user, 2026-11-27) | One load, one error, one consistent read, as the detail read carries its summary | A records-only RPC beside `RenderCitations` — two calls per open, chunking in Swift |
| D-3 | The sheet read answers `ConclusionOwnerField`s for both request cases: a pair's owner has `entity` and `field`; a life row's owner also has `event` or `place`, as `derivedRowsProto` maps it | S15-29 maps one message into the `CatalogOwnerField` it already has, and words a folded record from the same read's values | Owner ids joined to the page read in Swift — two reads that refresh apart |
| D-4 | Counts and denial facts are set in `finish`, over the composed outcomes, for every field of every read | One rule for the detail read and the sheet read; a count equals the records the sheet lists | A grouped count over the node's rows — skips `recordReader.outcome`'s drop rule |
| D-5 | `Records` = the field's composed outcomes. `Sources`: no displayed value → 0; one → its `Support`; several → distinct `SourceID`s among outcomes with `GroupRank > 0`, or the summed `Support` when there are none | Swift's `recordCount` and `sourceCount` exactly | Counting only for state mixed — Swift applies it to multiple too |
| D-6 | `DeniedAValue`: some outcome in the same field has `DeniedBy` equal to this outcome's id. `DeniedBySourceTitle`: for reason `denied`, the `SourceTitle` of the field's outcome whose id is `DeniedBy`; "" when that outcome is not in the field or the reason is not `denied` | Swift's `deniedSomething` and `outcomePhrase` `.denied`, plain-phrase fallback included | — |
| D-7 | One pairs-to-fields step serves `FieldRecords` and the life rows; the life rows call it with their owners' pairs and lay `ownerVerdict`, `Event` and `Place` on the result. A life row is asked for by Person and kind | The vote's verdict lives on the Person's summary owners (S16-80); one fetch and skip rule for both | Pairs for life rows — loses the verdict |
| D-8 | `FieldRecords` collapses repeated pairs to the first; an unknown or merged owner, or a pair with no composed field, is left out. An unspecified kind, or a request with neither case, answers no owners. None is an error; a malformed id is `request.invalid_id` | The sheet shows what exists; the page's own key reports a gone handle | `conclusiondetails.not_found` — a second error state for a case the page already shows |
| D-9 | `citationrender.RenderAll` renders any number of Citations in one read transaction, a batch of `MaxCitations` at a time, within one `MaxBatchBytes` budget for the whole call; a batch that would pass the budget is left out, so its records fall back to today's line | The package that owns both caps owns the rule; rule "Today's line stays the fallback, in Swift" | Chunking in the handler — domain policy in `api/ffi/handlers`; failing the read — one huge batch blanks the sheet |
| D-10 | The life rows' read records the Person's handle on `in` | Its owners come from the Person's summary; a write that moves them refreshes the sheet | — |

**Rules this plan bends.** None. The map's rule "Records load when the sheet opens" and the S15-28 / S15-29 rows carry D-1 and D-2.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `conclusiondetails.FieldRecordCounts` *(new)*, `Field.RecordCounts` *(new)* | type, field | Swift `ReconciledValueDisplay.sourceCount` | Moves that rule into Go (D-5); one name in both layers |
| `Outcome.DeniedAValue`, `Outcome.DeniedBySourceTitle` *(new)* | fields | `Outcome.DeniedBy`, `Outcome.SourceTitle` | Extends the outcome |
| `recordCounts(f *Field)`, `denialFacts(f *Field)` *(new, unexported)* | func | `state` | Beside `state`, called from `finish` |
| `conclusiondetails.Pair` *(new)*, `fieldsByPair` *(new, unexported)* | type, func | the inline step in `PersonDerivedRows` | Pulled out of it (D-7) |
| `conclusiondetails.FieldRecords` *(new)* | func | `ForEntity`; test-only `FieldsOf` in `export_test.go` | Public read of named pairs, returning `[]OwnerField` |
| `conclusiondetails.PersonDerivedRow` *(new)*, `personDerivedRows` *(new, unexported)* | func | `PersonDerivedRows` | `PersonDerivedRows` becomes `personDerivedRows` with all four kinds |
| `conclusiondetails.SheetRequest`, `Sheet`, `ProvenanceSheet` *(new)* | type, func | `persondetail.PersonFamily` | The sheet read's one core entry |
| `citationrender.RenderAll` *(new)* | func | `citationrender.Render` | `Render` keeps its 2,000 cap for `RenderCitations` |
| `engine.FieldRecordCounts` *(new)*, `ConclusionField.record_counts = 8` | proto | `ReconciledValueDetail.support` | A field-level count has no home today |
| `ReconcilerOutcomeDetail.denied_a_value = 26`, `denied_by_source_title = 27` | proto | `denied_by_observation_id` | Beside it |
| `GetProvenanceRecordsRequest`, `ProvenancePair`, `ProvenancePairs`, `ProvenanceDerivedRow`, `GetProvenanceRecordsResponse`, `METHOD_GET_PROVENANCE_RECORDS = 129` *(new)* | proto, FFI | `GetConclusionDetailRequest`, `RenderCitationsResponse` | Reuses `ConclusionOwnerField`, `RenderedCitation`, `PageInputs`, `DerivedRowKind` |
| `api/ffi/handlers/provenance_records.go` `GetProvenanceRecords` *(new)* | handler | `GetConclusionDetail` | Own file, as each read has |
| `ownerFieldProto`, `derivedRowKinds` *(new)* in `conclusion_detail.go` | func, var | the owner loop and the `kinds` map inside `derivedRowsProto` | Pulled out so both handlers map owners and kinds one way |
| `renderedCitationsProto` *(new)* in `citation_render.go` | func | the loop in `RenderCitations` | Pulled out so both handlers map renders one way |
| `researchedPerson` *(new)* test helper in `api/ffi/handlers/provenance_records_test.go` *(new)* | helper | `namedPersonOnNewSource` | It builds one Subject on one Source; this composes many onto one handle |

**Builds on.** `fieldsOf`'s `only` (S16-30), `ownerVerdict` (S16-80), `PageInputs` (S16-24), `render` (S15-16), `add-ffi-handler` (`runRPC` table tests).
**Deletes.** The `kinds` map and the inline owner loop in `derivedRowsProto`; the inline loop in `RenderCitations`; the inline pairs-to-fields code in `PersonDerivedRows`. Nothing else becomes dead until S15-29.
**Next adds.** S15-29 adds the store method and the sheet key's loader over this read, then deletes `RenderCitations` and the detail's outcomes. A claim layered over values goes through `finish`, so counts follow it.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A read of named pairs from outside the detail read | `fieldsByPair` → `fieldsOf` | `fieldsOf` skips nil, merged and repeated nodes; `in.Node` answers nil for an unknown id (T-4) |
| A read of one life row | `personDerivedRows` | `PersonsByIDs` is empty for a non-Person → no row (T-6) |

### Scale

At the map's Scale (up to 1,200 records on one value; a Person page citing 30 Sources): the sheet read composes the named owners' outcome rows from the node and the records tier, with no SQL for records, as the detail read does; the render is `TestRenderScale`'s 14 SELECTs at 1,200 Citations. T-8 holds 600 ms warm (render's 400 ms budget plus composition). The detail read gains two ints per field and a bool and a string per outcome; T-7 logs the payload S15-29 will remove. No write is added.

### Edges

- **Assumptions.** `finish` sees every outcome of the field it finishes: `fieldsOf` composes all of a named Property's rows. `ownerVerdict` runs after `finish` and changes only `Reason`, `Vote` and `ValueRank`; counts read `GroupRank` and `SourceID`, denial facts read ids and `DeniedBy`, so neither moves (T-6 asserts the counts on a verdict row). `ownerVerdict` only rewrites `kept` and `folded` outcomes, so no outcome becomes `denied` after `denialFacts`. One field holds one outcome per Observation. Pair keys are the two 16-byte ids concatenated: fixed width, so no separator can collide.
- **Neighbors.** A negative that eliminates nothing (AC-2.2); a denied record whose denier `recordReader.outcome` dropped (AC-2.3); one displayed value backed by two Sources (Support, AC-1.2); several displayed values with nothing counted under them (AC-1.4); a picture's record, which no `finish` sees, so its denial facts stay zero, as Swift words a record with no field.
- **Removed inputs.** An owner merged between page and sheet: left out; a Property whose records were deleted: left out; a Citation deleted between the records and the render: `render` leaves it out and the record falls back to today's line.
- **Real data.** None — no table or seed drives these rules.
- **Untrusted size.** Pairs come from the app: repeats collapse, and each pair costs the named owner's outcome rows, which the detail read already composes in full. Records per value are unbounded by data; `RenderAll` works in batches of 2,000 ids within one 8 MiB budget per call, so the reply's citation text is bounded whatever the record count (D-9).

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/conclusiondetails` | `type FieldRecordCounts struct { Records, Sources int }`; `Field.RecordCounts`; `Outcome.DeniedAValue bool`, `Outcome.DeniedBySourceTitle string`; `finish` ends with `recordCounts(f)` and `denialFacts(f)` |
| same | `type Pair struct { OwnerID, PropertyID []byte }`. `fieldsByPair(c *database.Catalog, pairs []Pair, in *graphcache.PageInputs) (map[string]Field, map[string]*graphcache.Node, error)`: skips a pair whose ids are not 16 bytes; `g.Nodes(ids)` over the distinct owners, then `in.Node` each (nil stays nil); builds `only`; `fieldsOf(g, v, nodes, nil, only, in)` with `v` from `g.Vocabulary()`; keys the fields by `string(owner)+string(property)` and the nodes by owner |
| same | `func FieldRecords(c *database.Catalog, pairs []Pair, in *graphcache.PageInputs) ([]OwnerField, error)`: nil catalog or graph, or no pairs, is nil and reads nothing; one `OwnerField{Entity: canonicalentities.FromNode(n), Field: f}` per distinct pair with a field, in first-request order. Two pairs on one owner are two `OwnerField`s with the same entity |
| same | `personDerivedRows(c, personID []byte, kinds []DerivedRowKind, in)` is today's `PersonDerivedRows` body with `lists` filtered to `kinds` before anything is read or recorded, `in.AddHandles(personID)` first, and the inline field step replaced by `fieldsByPair` over the kept lists' owners. `PersonDerivedRows` passes the four kinds. `func PersonDerivedRow(c *database.Catalog, personID []byte, kind DerivedRowKind, in *graphcache.PageInputs) (DerivedRow, bool, error)` passes one kind; false when no row comes back |
| same | `type SheetRequest struct { Pairs []Pair; PersonID []byte; Kind DerivedRowKind }`; `type Sheet struct { Owners []OwnerField; Citations []citationrender.RenderedCitation }`; `func ProvenanceSheet(c *database.Catalog, req SheetRequest, in *graphcache.PageInputs) (Sheet, error)`: `Pairs` non-empty → `FieldRecords`; else `PersonID` set and `Kind` one of the four → `PersonDerivedRow`'s owners; else empty. Then `citationrender.RenderAll` over the owners' outcomes' `CitationID`s, in owner then outcome order (`RenderAll` drops repeats) |
| `core/database/citationrender` | `render` gains a `limit int` parameter (the byte cap); `Render` passes `MaxBatchBytes`. `func RenderAll(c *database.Catalog, citationIDs [][]byte, in *graphcache.PageInputs) ([]RenderedCitation, error)`: an id not 16 bytes is `citations.ErrInvalid`; no ids is nil and reads nothing; one read transaction, as `Render` opens it; `renderAll(tx, ids, in, batch, limit)` *(new, unexported)* drops repeated ids (the first stays), then calls `render` on each batch of `batch` ids with `limit` set to what is left of one byte budget for the whole call; a batch `render` refuses with `citations.ErrInvalid` is left out and spends nothing, and each rendered batch spends its text's size; `RenderAll` passes `MaxCitations` and `MaxBatchBytes`. The constants' comments become: `MaxCitations` "is the most ids one Render call takes, and the batch RenderAll renders at a time"; `MaxBatchBytes` "is the most text one Render or RenderAll call renders: the sum of the plain text of every full and short citation" |

### FFI

`api/proto/engine.proto`:

```proto
// FieldRecordCounts is what a field's row shows without its records: how many
// records sit behind it, and how many Sources its row names.
message FieldRecordCounts {
  int32 records = 1;
  int32 sources = 2;
}
// ConclusionField gains:
FieldRecordCounts record_counts = 8;
// ReconcilerOutcomeDetail gains:
bool denied_a_value = 26;           // a negative that eliminated a value in its field
string denied_by_source_title = 27; // for "denied": the denier's Source title; "" when not in the field

message ProvenancePair { string owner_id = 1; string property_id = 2; }
message ProvenancePairs { repeated ProvenancePair pairs = 1; }
message ProvenanceDerivedRow { string person_id = 1; DerivedRowKind kind = 2; }

// GetProvenanceRecords reads one provenance sheet: the fields a row names,
// each with its records, and those records' citations rendered.
message GetProvenanceRecordsRequest {
  string project_dir = 1;
  oneof row {
    ProvenancePairs fields = 2;
    ProvenanceDerivedRow derived = 3;
  }
}
message GetProvenanceRecordsResponse {
  repeated ConclusionOwnerField owners = 1;
  repeated RenderedCitation citations = 2; // each Citation of the owners' records once
  // inputs is what this value was built from.
  PageInputs inputs = 3;
}
```

`PictureDetail`'s comment's second sentence becomes "record is its earliest Observation, with its outcome; the tile opens that record's Citation." `Method`: `METHOD_GET_PROVENANCE_RECORDS = 129`; dispatch `MethodGetProvenanceRecords` and its `case`, as `MethodRenderCitations`. Handler `api/ffi/handlers/provenance_records.go` *(new)* `GetProvenanceRecords`: `unmarshalErr("get_provenance_records", err)`; ids through `parseID`; the kind through `derivedRowKinds` (unspecified or unknown → the zero `DerivedRowKind`); in `withProjectCatalog`: `in := c.Graph().PageInputs()`, `conclusiondetails.ProvenanceSheet`, owners through `ownerFieldProto`, citations through `renderedCitationsProto`, `out.Inputs = pageInputsProto(in)` last. `derivedRowKinds` is a `map[conclusiondetails.DerivedRowKind]engine.DerivedRowKind`; the proto-to-Go direction loops it. `conclusionFieldProto` sets `RecordCounts`; `reconcilerOutcomeProto` sets the two new fields. Regenerate with `./scripts/generate-proto.sh` (Go and Swift).

### macOS

None — Swift only gains generated code from the proto.

### Strings

None — no copy.

## 7. Steps

**STEP-1 — Counts and denial facts**
Files: `core/database/conclusiondetails/conclusiondetails.go`, `conclusiondetails_test.go`, `export_test.go`.
Do: the types, fields and `finish` calls per Go core, D-5 and D-6. Export `RecordCountsOf(f Field) FieldRecordCounts` and `DenialFactsOf(f Field) []Outcome` in `export_test.go` for T-1.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/conclusiondetails/` passes with T-1, T-2, T-13.

**STEP-2 — One pairs-to-fields step**
Files: `conclusiondetails.go`, `conclusiondetails_test.go`, `placerecords_test.go`.
Do: `Pair`, `fieldsByPair`, `FieldRecords`, `personDerivedRows`, `PersonDerivedRow` per Go core.
Check: the package tests pass with T-4 – T-6; `TestPlaceOwnersCarryTheVote` and `TestPersonDerivedRowsRecordInputs` pass unchanged.

**STEP-3 — Render in batches, and the sheet read**
Files: `core/database/citationrender/render.go`, `render_test.go` (package `citationrender`, so it calls `renderAll` directly); `conclusiondetails.go`, `conclusiondetails_test.go`.
Do: `render`'s `limit`, `RenderAll`, `renderAll`; `SheetRequest`, `Sheet`, `ProvenanceSheet`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/citationrender/ ./core/database/conclusiondetails/` passes with T-3, T-12; `TestRenderScale` passes unchanged.

**STEP-4 — Proto**
Files: `api/proto/engine.proto`, `api/proto/engine/engine.pb.go`, `macos/App/Platform/Generated/engine.pb.swift`. Skill: `add-ffi-handler`.
Do: the FFI section's messages, fields and comment. Run `./scripts/generate-proto.sh` on a machine with `protoc`, `protoc-gen-go` and `protoc-gen-swift` (the Mac that runs `xcodebuild`).
Check: `go build ./...` passes; `git diff --stat` lists both generated files; `rg -n -U "the Why\s*\n\s*/+ shows" api macos/App/Platform/Generated` finds nothing.

**STEP-5 — Handlers**
Files: `api/ffi/handlers/conclusion_detail.go`, `citation_render.go`, `provenance_records.go` *(new)*, `api/ffi/dispatch.go`, `conclusion_detail_test.go`, `provenance_records_test.go` *(new)*. Skills: `add-ffi-handler`, `use-catalog-session`.
Do: `derivedRowKinds`, `ownerFieldProto`, `renderedCitationsProto`, the counts and denial mapping, `GetProvenanceRecords`, dispatch.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/...` passes with T-9, T-10, T-11.

**STEP-6 — Scale**
Files: `api/ffi/handlers/provenance_records_test.go` *(new)*, which STEP-5 creates.
Do: `researchedPerson(t *testing.T, sources, perSource int) (dir, entityID, namePropertyID string)`: `dir, userID, _, typeID := subjectFixture(t)`; for each Source, `namedPersonOnNewSource(t, dir, userID, typeID, "James Robins", "male", observations.PolarityPositive)` (one Citation with a name and a sex record); then in one `withProjectCatalog`, per Subject, read its `graph_id` as `namedPerson` does, create one Artifact with `artifactstest.Create`, and file `perSource - 1` more Citations with `observationstest.Cite`, each with one name Observation `namevaluetest.Western("James Robins")`; promote the first Subject with `promoteInDir(t, dir, userID, subject, "")` and the rest onto its handle; `namePropertyID` from `propertyIDByKey(t, dir, "name")`. Every name record holds the same value, so the field has one value and `sources × perSource` records, each its own Citation. Then T-7, T-8.
Check: both pass; copy their logged payload sizes and timing into the PR description.

**STEP-7 — Comments and domain doc**
Files: `conclusiondetails.go` (package comment), `docs/conclusion-reconciliation.md`.
Do: the package comment's first sentence ends at "joined to the record's Source." (its clause about the sheet goes) and this sentence follows it: "FieldRecords, PersonDerivedRow and ProvenanceSheet read one provenance sheet's fields with their records; each field carries its record and Source counts and each outcome its denial facts, so a page row needs no records. ProvenanceSheet also renders the records' citations, from SQL, through citationrender." In the doc's package table, the `conclusiondetails` row reads "Detail read and provenance sheet read: each field's state, values, counts, and outcomes with their evidence".
Check: `rg -n "provenance sheet shows" core/database/conclusiondetails` finds nothing.

**STEP-8 — Version and docs**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj`, `../completed.md`, `../deployment-plan.md`, this plan.
Do: per the Definition of done.
Check: `scripts/check-pr.sh` prints `check-pr: PASS`.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log`. No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `conclusiondetails_test.go` `TestRecordCounts` *(new)*, table over hand-built `Field`s through `RecordCountsOf` | no displayed value → {0,0}; one displayed, Support 2, 2 outcomes → {2,2}; two displayed, counted outcomes from Sources A, A, B → Sources 2; two displayed with Support 3 and 1, nothing counted → Sources 4 | AC-1.3, AC-1.4, D-5 |
| T-2 | Go | `conclusiondetails_test.go` `TestForEntityEvidence` (extended), `TestDenialFacts` *(new)* through `DenialFactsOf` | the fixture's negative: `DeniedAValue` true and the denied record's `DeniedBySourceTitle` the negative's Source title; a negative that denies nothing → false; a `denied` outcome whose denier is not in the field → ""; a `kept` outcome → "" | AC-2.1, AC-2.2, AC-2.3, D-6 |
| T-3 | Go | `citationrender/render_test.go` `TestRenderAll` *(new)*, table through `renderAll` | `seedScale`'s 300 Citations with batch 120 → 300 rendered, in input order; the first id repeated at the end, past the first batch → once; with `unit` one rendered Citation's `size(Full) + size(Short)` (`seedScale`'s Citations render alike): the first 250 ids, batch 100, limit 60 × `unit` → both batches of 100 left out, the last 50 rendered; the same ids with limit 150 × `unit` → the first batch rendered, the second left out (the budget left is 50), the last 50 rendered; a 15-byte id → `citations.ErrInvalid`; no ids → nil | AC-3.7, D-9 |
| T-4 | Go | `conclusiondetails_test.go` `TestFieldRecords` *(new)*, table | one pair → the `ForEntity` field for that Property, owner entity the handle; an event Subject with `asOfIn` records, pairs (`as_of`, `date`) → one owner, `as_of`; a repeated pair → one; an unknown owner and a merged owner → none; no pairs → nil; `holdsIDs` on the owner, graph and Source | AC-3.1, AC-3.2, AC-3.4, D-8 |
| T-5 | Go | `conclusiondetails_test.go` `TestFieldRecordsMatchesTheDetail` *(new)* | for every field of `TestForEntityRecordsInputs`' Person, `FieldRecords` gives the detail's field, counts and denial facts included | D-3, D-4 |
| T-6 | Go | `placerecords_test.go` `TestPersonDerivedRow` *(new)* | S16-80's "three Sources outvote the fourth" → the birth place row equals `PersonDerivedRows`' birth place row, the England owner's `RecordCounts` {1,1} and Swift Current's {3,3} (D-5; the verdict moves neither); the inputs hold the Person; no death place → false; a non-Person id → false | AC-3.3, AC-3.4, D-7, D-10 |
| T-7 | Go | `provenance_records_test.go` `TestDetailPayloadWithoutRecords` *(new)* | `researchedPerson(t, 30, 2)`: marshal `GetConclusionDetail`'s answer; clear every field's and derived owner's `Outcomes`; marshal again; log both byte counts; the second is smaller | AC-4.1 |
| T-8 | Go | `provenance_records_test.go` `TestProvenanceRecordsScale` *(new)* | `researchedPerson(t, 30, 40)`: the name pair → 1,200 outcomes and 1,200 citations; `databasetest.WithinBudget(t, "1200 records", databasetest.Warm(read), 600*time.Millisecond)` | AC-4.2 |
| T-9 | Go | `provenance_records_test.go` `TestGetProvenanceRecords` *(new)*, `runRPC` table | bad proto → error; `namedPersonID`'s name pair → one owner, `event` and `place` nil, 2 outcomes, counts {2,1}, 1 citation, `wantInputs` with the handle, graph and Source; `derivedRowsFixture` birth date → one owner whose `entity` and `event` are the Event, 2 outcomes, inputs hold the Person and the Event; unspecified kind → no owners; no `row` → no owners; malformed owner, Property or Person id → `request.invalid_id` | AC-3.1, AC-3.4, AC-3.5, AC-3.6 |
| T-10 | Go | `provenance_records_test.go` `TestGetProvenanceRecordsWarmReadsNoRecordSQL` *(new)* | `namedPersonID`'s name pair read twice: same bytes; no graph query (`SetQueryCounterForTest`); the second read's `databasetest.CountSelects` equals a warm `citationrender.Render` of the same Citation ids | AC-3.8 |
| T-11 | Go | `conclusion_detail_test.go` `TestGetConclusionDetail`, `TestGetConclusionDetailCarriesDerivedRows` (extended) | the name field's `record_counts` = {2,1}; the derived owner field's `record_counts.records` = 2 | AC-1.1, AC-1.5 |
| T-12 | Go | `conclusiondetails_test.go` `TestProvenanceSheet` *(new)* | pairs → `FieldRecords`' owners with their Citations rendered once each; a Person and a kind → `PersonDerivedRow`'s owners; neither → empty and nothing recorded | AC-3.4, AC-3.6, D-2 |
| T-13 | Go | `conclusiondetails_test.go` `TestForEntityRecordCounts` *(new)* | one Source with two names → {2,1}; two Sources with the same name, one record each → {2,2} | AC-1.1, AC-1.2 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `TestPlaceOwnersCarryTheVote`, `TestFieldsOfOnly`, `TestRenderScale`, `TestGetConclusionDetailWarmReadsNoRecordSQL`, any `runRPC` case with `exact: true` over a `ConclusionField` or `ReconcilerOutcomeDetail` (it now carries the new fields), and the Xcode build after regeneration.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] Sweep: `rg -n -U "the Why\s*\n\s*/+ shows" api macos/App/Platform/Generated` and `rg -n "provenance sheet shows" core` find nothing; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped, with T-7's payload sizes and T-8's timing
- [ ] Domain doc: docs/conclusion-reconciliation.md package table row (STEP-7)
- [ ] PR description: what shipped, AC evidence, deviations, T-7 and T-8 numbers
```

## 10. Manual check

The app does not call the new read until S15-29; the tests are the check of the new read. In the app, open a Person, an Event and a Place page and open a provenance sheet on each: every row and sheet reads as before.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| Counts drift from what Swift shows today | T-1 and T-13 state Swift's rules; T-5 holds the sheet read equal to the detail |
| 600 ms is missed on a slow runner | The budget sits above `TestRenderScale`'s 400 ms for the same 1,200 Citations; Verify mode skips budgets |
| `researchedPerson(t, 30, 40)` is slow to seed (1,200 writes) | It seeds once per test; if the package's test time grows past 60 s, stop and report |

**Stop and report if:**

- `fieldsOf`, `finish`, `PersonDerivedRows`, `ownerVerdict` or `render` no longer have the signatures or behavior §4 gives.
- `ownerVerdict` changes `GroupRank`, `SourceID` or `DeniedBy`, or rewrites an outcome to `denied`.
- T-5 finds a field where `FieldRecords` and `ForEntity` disagree.
- Two owners of one life row share a pair, so `fieldsByPair`'s map would fold them.
- `./scripts/generate-proto.sh` fails or leaves the Swift file unchanged.
- T-8 is over budget warm outside Verify mode.

## 12. Open questions

None.

## 13. PR

**Title:** S15-28 — A value's records load on their own
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; T-7's payload sizes and T-8's timing; `Plan: docs/deployment-plan/spike-15/prs/S15-28-records-load-on-their-own.md`.
