# Review — S15-37 Metadata values can be marked unknown or supplied

**Verdict:** Fits with changes — Ready with changes (round 1)
**Rounds:** 1 (round 2 pending). **Reviewers:** maintainability (opus), executability (sonnet)

## To user
None.

## Writer's own calls
- D-3: a refused mark is `valuemark.invalid` with the field's wire id as its param, so S15-41 can place it on the row (the map names the code; the param is the writer's).
- D-5: create and delete value changes always carry all six columns (`value_text` nil for an unknown row), matching the facet release, rather than omitting empty and false keys.
- D-7: a write without a mark is a value with no mark (it clears a stored mark); S15-41 must send the row's mark on every write.
- D-9: an absent `unknown_text` on `UpdateMetadataFieldRequest` keeps the stored text until S15-46 sends it always (map S15-46 scope entry updated).
- D-12: the `valuemark.invalid` sentence: "A value can’t be both unknown and supplied; an unknown value has no text, and a supplied one needs text."

## Round 1

### M-1 · blocker · One metadata value row would be audited two ways, and this PR makes them disagree
`Clear`'s delete omits `value_text` when empty; the facet release always writes it. An unknown row is the first stored row with no text, so the two shapes would differ. Better shape: one column definition (an exported release, or one `auditFields` map plus a parity test).
**Answer:** Fixed — D-5 now builds create and delete changes from one `auditFields(st, row)` map through `rowchange.FullRow` / `DeletedRow`, every key always present; T-12 *(new)* asserts `Clear`'s delete `Fields` equal the owner release's for an unknown and a supplied row at every level. Option A (an exported release `deleteValueTx` calls) declined: `Clear` deletes by owner and field and the create change needs the same map, so the map is the part both share.

### M-2 · major · Three copies of the value facet's column list
**Answer:** Fixed — D-6 adds `metadataValueFacet(parent, table, ownerCol)`; the three value entries call it. The layout copies are left as they are (this PR does not change them).

### M-3 · major · Five copies of `ScanField`'s SELECT list
**Answer:** Fixed — D-10 adds `metadatafields.Columns(alias)` beside `ScanField` (precedent `observationrow.Columns`); the four `metadatafields` queries and `sourcevocab.sqlListSuggestions` build from it.

### M-4 · major · `Set` and `apply` each decide insert, update or skip
**Answer:** Fixed — D-4 adds `putValueTx`, which both call; the unchanged rule (text and mark) lives there.

### M-5 · minor · The docs sweep misses two places in `source-layer-data-model.md`
**Answer:** Fixed — STEP-8 and the DoD add § 5.5's DDL and § 11 rule 4.

### M-6 · minor · Absent means "clear" for the mark and "keep" for the unknown text
**Answer:** Fixed — D-9 says the keep rule lasts until S15-46; the map's S15-46 scope entry now says it sends `unknown_text` on every update and makes the field and `Update`'s parameter plain strings.

### M-7 · nit · "Three handler files" overstates S15-44
**Answer:** Fixed — D-11, Codebase fit and Next adds name S15-43 and "whichever PR puts the page's mark on the wire".

### X-1 · blocker · STEP-6 and STEP-7 checks cannot run without protoc tools and Xcode
**Answer:** Fixed — a Stop condition: without `protoc`, `protoc-gen-go`, `protoc-gen-swift` or `xcodebuild`, stop after STEP-5 and report; STEP-6 says never hand-edit generated code. (The ship loop runs on the Mac, as for every FFI plan.)

### X-2 · major · STEP-4 hides the `Update` SQL change
**Answer:** Fixed — D-9 names the one `sqlUpdate` statement, binding the stored text when the argument is nil.

### X-3 · major · The mark columns' value type in change rows
**Answer:** Fixed — D-5 says Go `bool`, as `updateLayoutTx` and `colBool`.

### X-4 · major · Where the `sourcevocab` read is tested
**Answer:** Fixed — T-6 names `sourcevocab_test.go` `TestAppendSuggestion`'s case "ListSuggestionsTx reads what ListSuggestions reads"; STEP-4 lists the file.

### X-5 · major · Breakage in other packages shows up late
**Answer:** Fixed — STEP-2 and STEP-3 run `go test ./core/... ./api/...`.

### X-6 · minor · Other `Row` scans not enumerated
**Answer:** Fixed — the Go core table says `scanRow` is the only scan that builds a `Row` (checked).

### X-7 · minor · No test proves D-1's checks refuse a crafted row
**Answer:** Fixed — T-1 gains crafted `INSERT` cases expecting a constraint error.

### X-8 · minor · Whitespace unknown and a refused supplied url
**Answer:** Fixed — T-1 gains both cases.

### X-9 · Swift vocabulary
No finding.
