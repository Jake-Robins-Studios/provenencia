# S15-28 — A value's records load on their own

**Status:** Draft
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
**Review:** — (not reviewed yet)

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

The engine gains what the provenance sheet needs to load a row's records when it opens instead of with the page: each field's record and Source counts on the detail read, the two denial facts on every record, and one sheet read (`GetProvenanceRecords`) that takes a row's (owner, Property) pairs, or a Person life row, and returns those fields with their records and the records' rendered citations, reporting what it read. Nothing changes in the app yet: S15-29 switches the rows and the sheet to these reads and then stops the detail read sending records.

**Why now.** Working rule "Records load when the sheet opens". S15-21 put a load-on-open call under the sheet, S15-27 bounded what it draws, S15-31 made every detail row open it; the records are the last thing the sheet still takes from the page read.

**What stays.** The detail read still sends every field's outcomes, its derived rows and its pictures as today (D-1). `PictureTile.Record` keeps its outcome. `RenderCitations` stays for the app's current key. No catalog change, no SQL query added to the detail read.

## 2. User stories

**US-1.** As the app, when I draw a detail page's rows, I read each field's record count and Source count from the engine, so I never count records myself.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A name field with two records from one Source (`namedPerson`: James Robins, Kenneth Robins) | `record_counts` = records 2, sources 1 |
| AC-1.2 | A name field merged from two Sources, one record each | records 2, sources 2 |
| AC-1.3 | A mixed field: Source A records two values, Source B records one of them | sources 2 (distinct Sources under the displayed values), not 3 |
| AC-1.4 | A field with displayed values but no record counted under any of them | sources = the displayed values' summed Support |
| AC-1.5 | A Person's birth date row's owner field (`derivedRowsFixture`) | the owner field carries `record_counts` with records 2 |

**US-2.** As the app, when I word a record, I read whether a negative record eliminated a value and who denied a denied record, so I never search the field's records.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | A negative record that eliminates "James Robbins" (`TestForEntityEvidence`'s fixture) | the negative's `denied_a_value` is true; the denied record's `denied_by_source_title` is the negative's Source title |
| AC-2.2 | A negative record that eliminates nothing | `denied_a_value` false |
| AC-2.3 | Any record not denied | `denied_by_source_title` "" |

**US-3.** As the app, when a provenance sheet opens, I ask one read for the row's records and their citations.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `fields` = one pair (a Person, its name Property) | one group: that owner, the name field with its values, both outcomes, its counts; `citations` holds both records' Citations rendered |
| AC-3.2 | `fields` = (an Event, `date`), (the Event, `as_of`), (the Event, `end_date`) where only `date` and `as_of` have records | two groups, in request order; `end_date` has none and is left out |
| AC-3.3 | `derived` = (a Person, birth place) where three Sources name Swift Current and one names England (S16-80's fixture) | one group per owner in the row's order; the England link's records read `outvoted` with vote 3 of 4, as `PersonDerivedRows` gives them |
| AC-3.4 | A pair repeated, or an unknown or merged owner, or a Person with no such row | repeated: one group, first place; unknown or merged: left out; no row: no groups. None is an error |
| AC-3.5 | A malformed owner, Property or Person id | `request.invalid_id` |
| AC-3.6 | Any answer | `inputs` names the owners read (and the Person, for `derived`), every Evidence graph and Source of the records, and what the citation render read |
| AC-3.7 | A field with 2,001 distinct Citations | every Citation is rendered, in two render calls |
| AC-3.8 | The read run twice warm | the second read issues no graph query and reads none of `warmReadTables` |

**US-4.** As a contributor, I know the size of the records the page read sends and how fast the sheet read is at Scale.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | A Person with records from 30 Sources | the test logs the detail's payload with outcomes and with every outcome cleared; the second is smaller |
| AC-4.2 | One name field with 1,200 records over 30 Sources | `GetProvenanceRecords` answers 1,200 outcomes and 1,200 citations, warm, within 600 ms |

## 3. Scope

| In | Covered by |
| --- | --- |
| `RecordCounts` on every field, on the wire as `FieldRecordCounts` | STEP-1, STEP-3, STEP-4; AC-1.x |
| The two denial facts on every outcome | STEP-1, STEP-3, STEP-4; AC-2.x |
| `FieldRecords` and `PersonDerivedRow` in `conclusiondetails` | STEP-2; AC-3.1 – AC-3.4 |
| `GetProvenanceRecords` with chunked citation render and inputs | STEP-3, STEP-4; AC-3.x |
| Payload measurement and the 1,200-record timing | STEP-5; AC-4.x |
| The comments and the domain doc line the read makes false | STEP-6 |

| Out | Home |
| --- | --- |
| Rows reading `record_counts`; the sheet's key calling `GetProvenanceRecords`; Swift's `distinctSourceCount`, `sourceCount`, `recordCount`, `deniedSomething` and denier search going | S15-29 |
| The detail read no longer filling `ConclusionField.outcomes` (top-level fields and derived owners) | S15-29 (D-1) |
| `RenderCitations`, its method, messages, handler and store method, once the sheet no longer calls it | S15-29 |
| The sheet's pooled value groups' Source count (`pooledValueGroups`) | S15-29: it holds the records then |
| `FakeStore` and `GoStore` methods for the new read | S15-29 |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Detail composition | `core/database/conclusiondetails/conclusiondetails.go` `fieldsOf`, `finish`, `recordReader.outcome` | `fieldsOf` already composes named (owner, Property) pairs through `only`; `finish` orders outcomes and sets `GroupRank`; no counts or denial facts |
| Field and outcome types | same file `Field`, `Outcome` | no counts; `DeniedBy` is the only denial fact |
| Life rows | same file `PersonDerivedRows`, `ownerVerdict` | composes all four rows at once; the only way to a derived row's records, verdict included |
| Package comment | same file, `package conclusiondetails` doc | says the outcomes are "the records a detail page's provenance sheet shows" |
| Detail handler | `api/ffi/handlers/conclusion_detail.go` `GetConclusionDetail`, `conclusionFieldProto`, `reconcilerOutcomeProto`, `derivedRowsProto` | maps every field with its outcomes |
| Render handler | `api/ffi/handlers/citation_render.go` `RenderCitations` | maps `citationrender.Render` results inline; one call, at most `citationrender.MaxCitations` (2,000) ids |
| Dispatch | `api/ffi/dispatch.go` `MethodRenderCitations` and its `case` | last method is `METHOD_MOVE_TO_SOURCE = 128` |
| Proto | `api/proto/engine.proto` `ConclusionField`, `ReconcilerOutcomeDetail` (last field 25), `PictureDetail` (comment "as the Why shows it"), `RenderedCitation`, `PageInputs`, `DerivedRowKind` | — |
| Swift counts and denial rules (read only, not changed here) | `macos/App/Platform/ReconciledValueDisplay.swift` `sourceCount`, `distinctSourceCount`, `deniedSomething`, `outcomePhrase` `.denied`; `macos/App/Features/Conclusions/ReconciledValueRowModel.swift` `recordCount` | the rules Go now states: AC-1.x and AC-2.x must equal them |
| Domain doc | `docs/conclusion-reconciliation.md` package table, row "Detail read: each field's state, values, and outcomes with their evidence" | names no sheet read |
| Tests | `core/database/conclusiondetails/conclusiondetails_test.go` `TestForEntityEvidence`, `TestForEntityRecordsInputs`, `TestFieldsOfOnly`; `placerecords_test.go` `TestPlaceOwnersCarryTheVote`; `api/ffi/handlers/conclusion_detail_test.go` `TestGetConclusionDetail`, `TestGetConclusionDetailWarmReadsNoRecordSQL` (`warmReadTables`), `TestGetConclusionDetailCarriesDerivedRows`, `derivedRowsFixture`; `api/ffi/handlers/conclusion_summaries_test.go` `namedPerson`; `api/ffi/handlers/person_detail_test.go` `wantInputs`; `core/database/citationrender/scale_test.go` `TestRenderScale` | — |

**Precedent.** S16-24 ([plan](../../spike-16/prs/S16-24-reads-report-inputs.md)) added `PageInputs` to the detail read: copy its handler shape (`in := c.Graph().PageInputs()`, pass it down, `out.Inputs = pageInputsProto(in)` last) and its `wantInputs` assertions. `GetConclusionDetail` composing `conclusiondetails` with `conclusionsummaries` and `files` in one handler is the shape for composing records with `citationrender`. `TestRenderScale` is the shape for the timing test (`databasetest.WithinBudget`, `databasetest.Warm`).

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | The detail read keeps sending outcomes in this PR; S15-29 stops it once Swift reads the counts and the sheet read (user, 2026-11-27) | `check-pr.sh` builds the app, which reads `ConclusionField.outcomes`; an empty field hides every provenance button | Dropping them here — breaks the build or the app |
| D-2 | One sheet read returns the fields with their records and the records' rendered citations, with one `inputs` (user, 2026-11-27) | One load, one error, one consistent read, as the detail read carries its summary; S15-29 makes one FFI call per sheet | A records-only RPC beside `RenderCitations` — two calls per open, chunking in Swift |
| D-3 | Each group carries a whole `ConclusionField` (values, state, counts, outcomes), keyed by owner id | The sheet words a folded record's value from the same read's values, so a write between two reads cannot mismatch ranks; reuses the message | Records only, joined to the detail's values in Swift — two reads that refresh apart |
| D-4 | Counts and denial facts are computed in `finish`, over the composed outcomes, for every field of every read | One rule for the detail read and the sheet read; a count equals the records the sheet lists, dropped rows included | A grouped count over the node's rows — skips `recordReader`'s drop rule, so it can differ from the list |
| D-5 | `Sources`: no displayed value → 0; one → its `Support`; several → distinct `SourceID`s among outcomes with `GroupRank > 0`, or the summed `Support` when there are none | Swift's `sourceCount` exactly, so S15-29's rows read the same | Counting only for state mixed — Swift applies it to multiple too |
| D-6 | `DeniedAValue`: some outcome in the same field has `DeniedBy` equal to this outcome's id. `DeniedBySource`: for reason `denied`, the `SourceTitle` of the field's outcome whose id is `DeniedBy`; "" when that outcome is not in the field | Swift's `deniedSomething` and `outcomePhrase` `.denied`, including its plain-phrase fallback | — |
| D-7 | A derived row's records come from `PersonDerivedRow(person, kind)`, which shares `PersonDerivedRows`' code with one kind, so `ownerVerdict` applies; the request names the Person and the kind, not pairs | The vote's verdict lives on the Person's summary owners (S16-80) | Pairs for derived rows — loses the verdict |
| D-8 | Pairs that repeat collapse to the first; an unknown or merged owner, or a Property with no record, is left out; no error. A malformed id is `request.invalid_id` | The sheet shows what exists; the page's own key reports a gone handle | `conclusiondetails.not_found` for a gone owner — a second error state in the sheet for a case the page already shows |
| D-9 | Citations: the distinct Citation ids of the groups' outcomes, in outcome order, rendered in chunks of `citationrender.MaxCitations` into the same `in`; a chunk refused as `citations.ErrInvalid` (over `MaxBatchBytes`) is left out, and those records fall back to today's line | No cap on records per value; rule "Today's line stays the fallback, in Swift" | Failing the read — one huge citation would blank the sheet |
| D-10 | `derived` adds the Person's handle to `in` | The row's owners come from the Person's summary; a write that moves them must refresh the sheet | — |
| D-11 | The handler's render mapping moves into one helper both handlers call | One mapping of `RenderedCitation` | Copying the loop |

**Rules this plan bends.** None. The map's rule "Records load when the sheet opens" and S15-28 / S15-29 rows are updated with D-1 and D-2 in the planning commit.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `conclusiondetails.RecordCounts` *(new)*, `Field.Counts` *(new)* | type, field | Swift `ReconciledValueDisplay.sourceCount` | Moves that rule into Go (D-5) |
| `Outcome.DeniedAValue`, `Outcome.DeniedBySource` *(new)* | fields | `Outcome.DeniedBy`; Swift `deniedSomething` | Extends the outcome; moves the rule into Go |
| `recordCounts(f *Field)`, `denialFacts(f *Field)` *(new, unexported)*, called from `finish` | func | `finish`, `state` | Beside `state`, same shape |
| `conclusiondetails.Pair`, `OwnerRecords`, `FieldRecords(c, pairs, in)` *(new)* | type, func | `fieldsOf` with `only`; test-only `FieldsOf` in `export_test.go` | A public wrapper over `fieldsOf`: it builds `only` from the pairs and orders groups by request |
| `conclusiondetails.PersonDerivedRow(c, personID, kind, in)` *(new)* | func | `PersonDerivedRows` | `PersonDerivedRows` becomes a call to an unexported `personDerivedRows(c, personID, kinds, in)` that both share |
| `engine.FieldRecordCounts` *(new)*, `ConclusionField.record_counts = 8` | proto | `ReconciledValueDetail.support` | A field-level count has no home today |
| `ReconcilerOutcomeDetail.denied_a_value = 26`, `denied_by_source_title = 27` | proto | `denied_by_observation_id` | Beside it |
| `GetProvenanceRecordsRequest`, `ProvenancePair`, `ProvenancePairs`, `ProvenanceDerivedRow`, `ProvenanceRecordGroup`, `GetProvenanceRecordsResponse`, `METHOD_GET_PROVENANCE_RECORDS = 129` *(new)* | proto, FFI | `GetConclusionDetailRequest`, `RenderCitationsResponse` | A new read; reuses `ConclusionField`, `RenderedCitation`, `PageInputs`, `DerivedRowKind` |
| `api/ffi/handlers/provenance_records.go` `GetProvenanceRecords` *(new)* | handler | `GetConclusionDetail` | Own file, as each read has |
| `renderedCitationsProto(got []citationrender.RenderedCitation)` *(new)* in `citation_render.go` | func | the loop in `RenderCitations` | D-11 |
| `derivedRowKinds` *(new)* package map in `conclusion_detail.go`, both directions | var | the `kinds` map inside `derivedRowsProto` | The request needs proto → Go; one table serves both |
| `researchedPerson(t, sources, perSource int) (dir, entityID string)` *(new)* test helper in `api/ffi/handlers/provenance_records_test.go` | helper | `namedPerson` | `namedPerson` makes one Subject; this files `sources` Sources, each one Person Subject with `perSource` name records, promoted onto one handle with `promoteInDir` |

**Builds on.** `fieldsOf`'s `only` (S16-30), `PersonDerivedRows` and `ownerVerdict` (S16-80), `PageInputs` (S16-24), `citationrender.Render` (S15-16), `add-ffi-handler` (`runRPC` table tests).
**Deletes.** The `kinds` map inside `derivedRowsProto` (replaced by `derivedRowKinds`); the inline mapping loop in `RenderCitations` (replaced by `renderedCitationsProto`). Nothing else becomes dead until S15-29.
**Next adds.** S15-29 adds `GoStore.provenanceRecords` and the sheet key's loader over this read, then deletes `RenderCitations` and the detail's outcomes. A claim layer laid over values (package comment) goes through `finish`, so counts follow it.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A read of named (owner, Property) pairs from outside the detail read | `fieldsOf` | `fieldsOf` skips nil, merged and repeated nodes; `in.Node` returns nil for an unknown id (D-8, T-5) |
| A read of one life row | `personDerivedRows` | `PersonsByIDs` empty for a non-Person → no row (T-6) |

### Scale

At the map's Scale (up to 1,200 records on one value; a Person page citing 30 Sources): the sheet read composes the named owners' outcome rows from the node and the records tier, as the detail read does, with no SQL for records; the citation render is `TestRenderScale`'s 14 SELECTs at 1,200. T-8 holds 600 ms warm (render's 400 ms budget plus composition). The detail read gains two ints per field and one bool and one string per outcome; T-7 logs the payload it will lose in S15-29. No write is added.

### Edges

- **Assumptions.** `finish` sees every outcome of the field it finishes: true for `fieldsOf`, which composes all of a named Property's rows. `ownerVerdict` runs after `finish` and changes `Reason`, `Vote` and `ValueRank` only, so counts (which read `GroupRank` and `SourceID`) and denial facts (which read `DeniedBy` and ids) are unchanged by it (T-6 asserts counts on a verdict row). A field's outcome ids are distinct (one row per Observation).
- **Neighbors.** A negative that eliminates nothing (AC-2.2); a denied record whose denier was dropped by `recordReader.outcome` (`DeniedBySource` "", T-2); a field with one displayed value supported by two Sources (Support, not distinct count, AC-1.2); several displayed values with no outcome under them (AC-1.4); a picture's record, which belongs to no field (`DeniedAValue` false, `DeniedBySource` "", as Swift words it with no field).
- **Removed inputs.** An owner merged between page and sheet: left out (D-8); a Property whose records were all deleted: left out; a Citation deleted between the records and the render: `Render` leaves it out and the record falls back to today's line.
- **Real data.** None — no table or seed drives these rules.
- **Untrusted size.** Pairs come from the app: duplicates collapse and each pair costs the named owner's outcome rows, which the detail read already composes in full. Records per value are unbounded by data; the render is chunked at 2,000 ids and 8 MiB per chunk (D-9).

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/conclusiondetails` | `type RecordCounts struct { Records, Sources int }`; `Field.Counts RecordCounts`; `Outcome.DeniedAValue bool`, `Outcome.DeniedBySource string`; `finish` calls `recordCounts(f)` and `denialFacts(f)` after it orders the outcomes |
| same | `type Pair struct { OwnerID, PropertyID []byte }`; `type OwnerRecords struct { OwnerID []byte; Field Field }`; `func FieldRecords(c *database.Catalog, pairs []Pair, in *graphcache.PageInputs) ([]OwnerRecords, error)` — nil catalog or graph, or no pairs, returns nil and reads nothing; a pair whose ids are not 16 bytes is skipped; nodes fetched through `in.Node` (which records them); one `fieldsOf(…, nil, only, in)`; groups in first-request order |
| same | `func PersonDerivedRow(c *database.Catalog, personID []byte, kind DerivedRowKind, in *graphcache.PageInputs) (DerivedRow, bool, error)` — false when the Person has no such row; `PersonDerivedRows` and it call `personDerivedRows(c, personID, kinds []DerivedRowKind, in)`, which builds only the named kinds' lists |

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

// GetProvenanceRecords reads one provenance sheet's records: the fields a row
// names, each with its records, and those records' citations rendered.
message GetProvenanceRecordsRequest {
  string project_dir = 1;
  oneof row {
    ProvenancePairs fields = 2;
    ProvenanceDerivedRow derived = 3;
  }
}
message ProvenanceRecordGroup {
  string owner_id = 1;
  ConclusionField field = 2;
}
message GetProvenanceRecordsResponse {
  repeated ProvenanceRecordGroup groups = 1;
  repeated RenderedCitation citations = 2; // each Citation of the groups' records once
  PageInputs inputs = 3;                   // inputs is what this value was built from.
}
```

`Method`: `METHOD_GET_PROVENANCE_RECORDS = 129`. Dispatch: `MethodGetProvenanceRecords` and its `case` in `api/ffi/dispatch.go`, as `MethodRenderCitations`. Handler `api/ffi/handlers/provenance_records.go` *(new)* `GetProvenanceRecords`: unmarshal (`unmarshalErr("get_provenance_records", err)`), parse ids with `parseID`, then in `withProjectCatalog`: `in := c.Graph().PageInputs()`; `FieldRecords` or, for `derived`, `in.AddHandles(person)` and `PersonDerivedRow` (each owner → a group with `owner.Entity.ID`); render per D-9 into `in`; `out.Inputs = pageInputsProto(in)` last. A request with neither case answers an empty response. `conclusionFieldProto` sets `RecordCounts`; `reconcilerOutcomeProto` sets the two new fields. Regenerate with `./scripts/generate-proto.sh` (Go and Swift).

### macOS

None — Swift only gains generated code from the proto.

### Strings

None — no copy.

## 7. Steps

**STEP-1 — Counts and denial facts**
Files: `core/database/conclusiondetails/conclusiondetails.go`, `conclusiondetails_test.go`, `export_test.go`.
Do: add `RecordCounts`, `Field.Counts`, the two `Outcome` fields, `recordCounts` and `denialFacts` per D-4 – D-6, called at the end of `finish`. Export both helpers for T-1 in `export_test.go` (`RecordCountsOf(f Field) RecordCounts`, `DenialFactsOf(f Field) []Outcome`).
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/conclusiondetails/` passes with T-1, T-2.

**STEP-2 — The two record reads**
Files: `conclusiondetails.go`, `conclusiondetails_test.go`, `placerecords_test.go`.
Do: add `Pair`, `OwnerRecords`, `FieldRecords`; split `PersonDerivedRows` into `personDerivedRows` and add `PersonDerivedRow`, per Go core.
Check: the package tests pass with T-3 – T-6; `TestPlaceOwnersCarryTheVote` and `TestPersonDerivedRowsRecordInputs` pass unchanged.

**STEP-3 — Proto**
Files: `api/proto/engine.proto`, generated `api/proto/engine/engine.pb.go`, `macos/App/Platform/Generated/engine.pb.swift`. Skill: `add-ffi-handler`.
Do: the messages and fields in FFI; rewrite `PictureDetail`'s comment to "record is its earliest Observation, with its outcome; the tile opens that record's Citation." Run `./scripts/generate-proto.sh`.
Check: `go build ./...` passes; `git diff --stat` shows both generated files.

**STEP-4 — Handlers**
Files: `api/ffi/handlers/conclusion_detail.go`, `citation_render.go`, `provenance_records.go` *(new)*, `api/ffi/dispatch.go`, `conclusion_detail_test.go`, `provenance_records_test.go` *(new)*. Skills: `add-ffi-handler`, `use-catalog-session`.
Do: `derivedRowKinds`, `renderedCitationsProto`, the counts and denial mapping, `GetProvenanceRecords`, dispatch.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/...` passes with T-9 – T-12.

**STEP-5 — Scale**
Files: `api/ffi/handlers/provenance_records_test.go` *(new)*.
Do: `researchedPerson`; T-7, T-8.
Check: both pass; copy their logged payload sizes and timing into the PR description.

**STEP-6 — Comments and domain doc**
Files: `conclusiondetails.go` (package comment), `docs/conclusion-reconciliation.md`.
Do: the package comment's first sentence ends at "joined to the record's Source." (its trailing clause about the sheet goes) and a new sentence follows: "FieldRecords and PersonDerivedRow read one provenance sheet's fields with their records; each field carries its record and Source counts and each outcome its denial facts, so a page row needs no records." In the doc's package table, the `conclusiondetails` row reads "Detail read and provenance sheet read: each field's state, values, counts, and outcomes with their evidence".
Check: `rg -n "as the Why shows it" api core docs` finds nothing.

**STEP-7 — Version and docs**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj`, `../completed.md`, `../deployment-plan.md`, this plan.
Do: per the Definition of done.
Check: `scripts/check-pr.sh` prints `check-pr: PASS`.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log`. No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `conclusiondetails_test.go` `TestRecordCounts` *(new)*, table over hand-built `Field`s through `RecordCountsOf` | empty → {0,0}; one displayed, Support 2, 2 outcomes → {2,2}; two displayed, outcomes under them from Sources A, A, B → Sources 2; two displayed with Support 3 and 1, no outcome under either → Sources 4 | AC-1.3, AC-1.4, D-5 |
| T-2 | Go | `conclusiondetails_test.go` `TestForEntityEvidence` (extended) and `TestDenialFacts` *(new)* through `DenialFactsOf` | the fixture's negative: `DeniedAValue` true, the denied record's `DeniedBySource` = the negative's Source title; a negative that denies nothing → false; a denied outcome whose denier is not in the field → "" | AC-2.1, AC-2.2, AC-2.3, D-6 |
| T-3 | Go | `conclusiondetails_test.go` `TestForEntityRecordCounts` *(new)* | one Source, two names → {2,1}; two Sources one name each → {2,2} | AC-1.1, AC-1.2 |
| T-4 | Go | `conclusiondetails_test.go` `TestFieldRecords` *(new)*, table | one pair → the same `Field` `ForEntity` gives for that Property; three pairs, one with no records → two groups in order; a repeated pair → one; an unknown and a merged owner → left out; no pairs → nil; inputs hold the owner, graphs and Sources | AC-3.1, AC-3.2, AC-3.4, D-8 |
| T-5 | Go | `conclusiondetails_test.go` `TestFieldRecordsMatchesTheDetail` *(new)* | for every field of `TestForEntityRecordsInputs`' Person, `FieldRecords` equals the detail's field, counts and denial facts included | D-3, D-4 |
| T-6 | Go | `placerecords_test.go` `TestPersonDerivedRow` *(new)* | S16-80's "three Sources outvote the fourth" → equals `PersonDerivedRows`' birth place row, verdict and counts included; a Person with no death place → false; a non-Person id → false | AC-3.3, AC-3.4, D-7 |
| T-7 | Go | `provenance_records_test.go` `TestDetailPayloadWithoutRecords` *(new)* | `researchedPerson(t, 30, 2)`: marshal `GetConclusionDetail`'s answer, clear every field's and derived owner's `Outcomes`, marshal again; log both byte counts; the second is smaller | AC-4.1 |
| T-8 | Go | `provenance_records_test.go` `TestProvenanceRecordsScale` *(new)* | `researchedPerson(t, 30, 40)`: the name pair → 1,200 outcomes, 1,200 citations; `databasetest.WithinBudget(t, "1200 records", databasetest.Warm(read), 600*time.Millisecond)` | AC-4.2 |
| T-9 | Go | `provenance_records_test.go` `TestGetProvenanceRecords` *(new)*, `runRPC` table | bad proto → error; `namedPerson`'s name pair → one group, 2 outcomes, counts {2,1}, 2 citations, `wantInputs` with the handle, graph and Source; `derivedRowsFixture` birth date → one group whose owner is the Event and whose field has 2 outcomes, inputs hold the Person and Event; malformed owner, Property or Person id → `request.invalid_id`; empty `row` → empty answer | AC-3.1, AC-3.3, AC-3.5, AC-3.6, D-10 |
| T-10 | Go | `provenance_records_test.go` `TestProvenanceRecordsChunkRender` *(new)* | `researchedPerson(t, 1, 2001)` → 2,001 distinct citations rendered | AC-3.7, D-9 |
| T-11 | Go | `provenance_records_test.go` `TestGetProvenanceRecordsWarmReadsNoRecordSQL` *(new)*, copying `TestGetConclusionDetailWarmReadsNoRecordSQL` | second read: no graph query, no `warmReadTables` read, same bytes | AC-3.8 |
| T-12 | Go | `conclusion_detail_test.go` `TestGetConclusionDetail` and `TestGetConclusionDetailCarriesDerivedRows` (extended) | the name field's `record_counts` = {2,1}; the derived owner field's `record_counts.records` = 2 | AC-1.1, AC-1.5 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `TestPlaceOwnersCarryTheVote`, `TestFieldsOfOnly`, `TestGetConclusionDetailWarmReadsNoRecordSQL` (the payload bytes change), the Xcode build after regeneration.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] Sweep: `rg -n "as the Why shows it"` across `api/`, `core/`, `docs/` and `.agents/` finds nothing; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped, with T-7's payload sizes and T-8's timing
- [ ] Domain doc: docs/conclusion-reconciliation.md package table row (STEP-6)
- [ ] PR description: what shipped, AC evidence, deviations, T-7 and T-8 numbers
```

## 10. Manual check

None — the app does not call the new read until S15-29; the handler tests are the check. The reviewer opens a Person, an Event and a Place page in the app and sees each row and its provenance sheet as before.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| Counts drift from what Swift shows today | T-1 and T-3 state Swift's rules; T-5 holds the sheet read equal to the detail |
| `generate-proto.sh` cannot run where the implementer works | Stop condition |
| 600 ms is missed on a slow runner | The budget sits above `TestRenderScale`'s 400 ms for the same 1,200 citations; Verify mode skips budgets |

**Stop and report if:**

- `fieldsOf`, `finish`, `PersonDerivedRows` or `ownerVerdict` no longer have the signatures or behavior §4 gives.
- `ownerVerdict` changes `GroupRank`, `SourceID` or `DeniedBy`, so counts or denial facts differ before and after it.
- T-5 finds a field where `FieldRecords` and `ForEntity` disagree.
- `./scripts/generate-proto.sh` fails or leaves the Swift file unchanged.
- T-8 is over budget warm outside Verify mode.

## 12. Open questions

None.

## 13. PR

**Title:** S15-28 — A value's records load on their own
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; T-7's payload sizes and T-8's timing; `Plan: docs/deployment-plan/spike-15/prs/S15-28-records-load-on-their-own.md`.
