# Review — S15-18 A Source type can be copied

**Verdict:** Fits with changes — Ready with changes (round 1)
**Rounds:** 1. **Reviewers:** maintainability (opus), executability (sonnet)

## To user
- None.

## Writer's own calls
- Copy is a new RPC, `CopySourceType`, not flags on `CreateSourceType` (D-1).
- The copy lives in `sourcevocab` (import direction), with `sourcetypes.Create` taking a `CreateInput` that carries stored formats (D-2, D-3).
- Formats copy as stored, by field id, with no re-parse (D-3).
- Copied suggestion rows are not audited, as assigning one is not (D-5).
- The revision carries the user (D-6, as Copy Source).
- The sheet copies saved values only; unsaved Details ask through the page's leave guard after Copy type (D-13).
- The board's own duplicate-key sentence is not built; the engine's message shows, as in Add type (Board line).
- The read area and the part tick are promoted to recipes in this PR rather than a preparatory PR (D-14), with the label rule (D-11): ten steps, at the size limit.
- Manual check 1 cannot show copied formats until S15-17 lands (no screen writes formats); T-1 and T-3 cover them.

## Round 1

### M-1 · blocker · Third copy of the label-edit rule
`SourceTypeAddModel.editLabel` and `SourceTypePageModel.editLabel` already hold it; D-8 added a third.
**Answer:** Fixed — D-11 adds `SourceTypeLabelCheck` beside `SourceTypeDraft`; the Add, page and Copy models hold it and their own copies go (Deletes); STEP-6.

### M-2 · blocker · FakeStore.copySourceType re-implements the engine's copy rules
`.cursor/rules/swift-tests.mdc`: new FakeStore methods script, they do not compute.
**Answer:** Fixed — D-7: `copySourceTypeResult` is scripted, `copySourceTypeCalls` records arguments; T-4 checks what Swift sends and that the scripted row lands in the list. Which rows a copy makes is tested in Go (T-1, T-3).

### M-3 · blocker · Part tick copied and read area reached across features
`add-ui-component`: promote to `Recipes/<Name>/` before a second feature uses a snowflake; S15-32 review M-1 made `partTick` so the rule lives once.
**Answer:** Fixed — D-14 moves `SourceFormLoadArea`/`SourceFormLoadState` to `Recipes/FormLoadArea/` as `PVFormLoadArea`/`PVFormLoadState` (its Read again string to `L10n.DesignSystem`) and promotes `partTick` to `Recipes/CopyPartTick/PVCopyPartTick`; STEP-5, no visible change. Kept in this PR, not a preparatory PR: it is a move with three callers and is one commit.

### M-4 · major · A second switch over Level for copy text
**Answer:** Fixed — D-12 and Strings: `LevelCopy.copyTick`.

### M-5 · major · copyFieldCount duplicates assignedCount
**Answer:** Fixed — D-12 reuses `L10n.SourceTypes.assignedCount(count:)`; the key is dropped.

### M-6 · major · formats-to-change-fields loop becomes a third copy
**Answer:** Fixed — D-3 adds `formatFieldDiffs(before, after)`; `Create`, `Delete` and `UpdateFormats` call it; T-2.

### M-7 · major · Form names keyed to the Copy sheet; S15-17 needs them next
**Answer:** Fixed — D-7 adds `CitationForm` in `Platform/` with a parity row (T-6), `CatalogCitationFormats.text(_:)`, and `L10n.CitationForms.name(_:)`.

### M-8 · minor · formats read as two optionals beside a hand-merged state
**Answer:** Fixed — D-8: `formatsState: PVFormLoadState` plus the value; handles from `CatalogQueryKey.typeSuggestionsKeys`.

### M-9 · minor · positional fifth parameter on Create
**Answer:** Fixed — D-3: `CreateInput`.

### M-10 · minor · sourcevocab's package doc and skill row go stale
**Answer:** Fixed — D-5 (package doc in STEP-2); STEP-10 updates `add-seeded-vocabulary` and puts "Copy a Source type" beside Copy Source in `docs/source-layer-data-model.md`.

### X-1 · major · Header draws no Copy button while the page loads
**Answer:** Fixed — D-9: in `loading`, the Copy button disabled before the trash's skeleton bar; T-5, STEP-8 check.

### X-2 · major · Copy's audit user left open
**Answer:** Fixed — D-6 passes `UserID`, as `CopySource`.

### X-3 · major · Create's other in-package callers
`rg` shows a fourth: `sourcetypes_test.go` `TestCreateUpdateGetByID` (line 577).
**Answer:** Fixed — D-3 lists all four; STEP-1 starts with the `rg` that lists them.

### X-4 · major · Several Swift model needs unspecified
**Answer:** Fixed — D-8: the first failure in the order formats, source, artifact, graph carries the message; `reload()` rereads failed levels and restarts the formats read. `.sourceTypePage(typeId:title:)` exists (`SourceTypeAddDialog.swift:31`). D-7: `levels.map(\.rawValue)`. Description trim agrees, as noted.

### X-5 · minor · copied-formats delete refusal
**Answer:** Fixed — T-1 asserts `deleteimpact.Impact(…KindMetadataField…)` has `ViaCitationFormats` with `Total == 2`, as `metadatafields_test.go` does.

### X-6 · minor · dynamic IN (…)
**Answer:** Fixed — D-5: one `?` per level joined by `,` (at most 3, validated); empty levels skip the statement.

### X-7 · minor · header label type
`LocalizedStringResource` conforms to `PVCopy` (`DesignSystem/Components/Copy/PVCopy.swift:17`).
**Answer:** Fixed — D-9: spoken label equals the tooltip "Copy…", as the board's CT-1 and the Source page's Copy.

### X-8 · minor · the board link cannot be read
**Answer:** Declined — the writer read the board (frames D7-1a – D7-10 and its notes) and recorded on the **Board** line that it draws D-9 – D-12 and § 6 Strings exactly, with the one difference named. The brief is local.

### X-9 · minor · checks that cannot run here
**Answer:** Partly Fixed — STEP-5 and STEP-6 checks are now `rg` commands; manual check 1 states formats cannot be set from a screen before S15-17. Declined for `xcodebuild`: the implementer runs on macOS, where `scripts/check-pr.sh` runs it (STEP-9).

### X-10 · nit · status and map row out of step
Logged; set when the plan is Planned.
