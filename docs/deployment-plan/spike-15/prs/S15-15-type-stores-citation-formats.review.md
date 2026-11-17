# Review — S15-15 Source types store citation formats

**Verdict:** (round 2 pending)
**Rounds:** 1 so far. **Reviewers:** maintainability (Opus), executability (Sonnet)

## To user

- Answered before review (2026-11-17): the Swift mutation `.changedCitationFormats(typeId)` and the store method move to S15-17, the first Swift caller (D-11, Rules this plan bends).

## Writer's own calls

- Two new RPCs (`GetCitationFormats`, `UpdateCitationFormats`) instead of fields on `SourceType` / `UpdateSourceType` (D-3).
- One write replaces all three forms; blank stores NULL; text is not trimmed (D-4).
- Ambiguous keys are settled by `field_choices` on the wire, echoed by the read, with no hidden state in the write (D-5, D-6).
- A text-reference delete edge that matches the `#<id>` token as a substring and accepts over-refusal from a crafted literal (D-7).
- `usedBy` now counts Source types naming a field, and the "suggestion removed" toast says so (D-7, D-12).
- `unknown_field` and `ambiguous_field` join `citationformat.DiagnosticCodes` although `Parse` never emits them (D-8).

## Round 1

### M-1 · blocker · A format save reprojects the search document of every Source of the type
**Plan:** D-10 said there was no effects change, and the Scale line said the 500 Sources are not touched.
**Codebase:** `core/database/effects/registry.go` `"source_types"`: the Search paths `{DocSourceType, self()}` and `{DocSource, inbound("sources","source_type_id")}` have no field gate, and `writes.Run` reprojects them on every change.
**Better shape:** Gate both paths with `onField`. Add an effects test.
**Answer:** Fixed. D-10 gates the type doc on label, description and icon_key, and the Sources' docs on label. T-10 is added, and the Scale line is corrected.

### M-2 · blocker · S15-20's Install will re-implement the key→id storage pipeline
**Plan:** Parse, resolve and rewrite ran only inside `UpdateFormats`.
**Better shape:** One exported storage step, which `UpdateFormats` and S15-20's Install both call.
**Answer:** Fixed. D-9 adds `sourcetypes.ToStored(tx, in, choices, preferOrigin)`. `UpdateFormats` calls it with `""`, and Next adds names S15-20's call with `provenencia`. T-3 calls it directly.

### M-3 · major · A single-type stored-format read that later PRs will each copy as a batched read
**Answer:** Fixed. `StoredFormatsTx(tx, typeIDs)` is batched through `sqlbatch.Query` and replaces the single-id `sqlFormats`. Next adds names S15-16, S15-18 and S15-38. T-4 covers it.

### M-4 · major · The form-tagged diagnostic belongs in the engine package
**Answer:** Fixed. `citationformat.FormDiagnostic` is in `form.go` (D-8). The handler helper `citationFormatDiagnosticsProto` is for S15-16 to reuse (§ Go core).

### M-5 · major · Inbound via headings are a hand-kept Swift list with no Go parity
**Codebase:** `PVDeleteImpactTests.knownViaHeadingsMatchEngineEdges` already lacks the two S15-08 vias, and `swift_vocabulary_test.go` has only a cascade-via row.
**Answer:** Fixed. `deleteimpact.ResourceInboundVias()` is exported, and T-12 adds a parity row over `L10n.DeleteImpact.viaFormats`. If an existing inbound via lacks a heading, STEP-7 adds one.

### M-6 · major · `sourcetypes.Delete`'s audit change drops the type's formats
**Answer:** Fixed. D-10 says `Delete` records each non-empty format as `Old`. T-11 is added.

### M-7 · major · `sqlbatch.Each` batches only `[][]byte`
**Answer:** Fixed. D-2 makes `sqlbatch.Each` and `Query` generic over the element type, with no call-site edits. T-9 is added, plus a stop condition in case a call site needs an edit.

### M-8 · minor · The custom edge belongs beside its kin, not in `probes.go`
**Answer:** Fixed. The edge goes in `deleteimpact/formatrefs.go` (D-7), and `Count` is derived from `Totals`.

### M-9 · minor · `DiagnosticCode`'s comment becomes false
**Answer:** Fixed. D-8 rewords the comment.

### X-1 · blocker · `UpdateFormats` order contradicts AC-2.6
**Answer:** Fixed. § Go core gives `ToStored`'s order: parse all forms, then resolve only the forms that parsed, then return the union in D-9's order.

### X-2 · major · D-2 batching cannot be done as written
**Answer:** Fixed by M-7.

### X-3 · major · The toast plural forms are not decided
**Answer:** Fixed. D-12 gives the `defaultValue`, the xcstrings `one` and `other` values, and both comments.

### X-4 · major · What `Diagnostics` holds on a refused write
**Answer:** Fixed. D-9 and § Go core: only the write's diagnostics, with the stored `Formats` and `Choices`.

### X-5 · minor · `field_choices` edge cases are not decided
**Answer:** Fixed. D-5 covers an empty key, a duplicate key, a malformed or unknown id and a key mismatch (`ErrInvalid`). A sole-holder choice is accepted. Keys match exactly (D-2). T-3 cases are added.

### X-6 · minor · The malformed-id error does not match the handlers
**Answer:** Fixed. D-13: a malformed `type_id` gives the `parseID` error, as in `UpdateSourceType`. A malformed choice `field_id` maps to `sourcetypes.invalid`. T-6 is updated.

### X-7 · minor · The delete-impact edge shape is only half specified
**Answer:** Fixed. D-7 gives the `Count`, `List` and `Totals` shapes, bindings, map keys and the empty result.

### X-8 · minor · Test fixtures are not named
**Answer:** Fixed. T-3 names `database.Create`, `metadatafields.Upsert`, `sourcetypes.Upsert` and `c.DB()`, and T-4 uses the same fixtures. STEP-4 marks its files as edits.

### X-9 · minor · The map row's scope text is not in STEP-8
**Answer:** Fixed. STEP-8 names the map-table row cell and S15-38's row and scope entry.

### X-10 · minor · `used_by` comment target
**Answer:** Fixed. § FFI names `message MetadataField`.

### X-11 · nit
Logged. The temptations are covered: no `catalogmodel` change (§ Schema), and `docs/catalog-caches.md` belongs to S15-38. The type-delete test is now T-11.
