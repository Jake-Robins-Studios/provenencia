# Review — S15-17 The format editor

**Verdict:** round 1 Fits with changes — Ready with changes; round 2 in progress
**Rounds:** 2. **Reviewers:** maintainability (Opus), executability (Sonnet)

## To user
- None open. Both blockers were fixed in ways that keep the user's 2026-11-20 answers (one Save; preview against a Source only; warnings listed under the field). They widen the PR: `UpdateSourceType` carries formats and `UpdateCitationFormats` retires (M-1); `ListCitationBuiltins` becomes `ListCitationPlaceholders` (M-2); `LatestCall` replaces two hand-written counters (M-6). Reported to the user with the plan.

## Writer's own calls
- D-2: "first Citation" is the smallest id (the oldest, UUIDv7); a Source with none previews from the Source alone.
- D-3: a format with no target returns its diagnostics only, so warnings show on a type with no Sources; the format is checked before the target on every call.
- D-9: the formats read is not a session query key.
- D-11: 300 ms after typing stops, per form.
- D-15: the preview defaults to the type's most recently changed Source.
- D-16: built-in, level and diagnostic copy in a new `L10n.CitationFormats`; level names join `L10n.SourceTypes.LevelCopy`.
- The brief's copy (messages for 21 diagnostic codes, toasts, the missing line).

## Round 1

### M-1 · blocker · One Save sends two writes from Swift; it should be one engine write
**Plan:** D-6 (old): `updateCitationFormats` then `updateSourceType` from Swift. **Codebase:** `plan-spike` "No client-side copy of an engine rule"; `sourcetypes.Update` / `UpdateFormats` both take a tx; `updateChange(prev, next, formats)`; S15-33's optional draft. **Better shape:** `UpdateSourceTypeRequest` carries an optional formats draft in one `writes.Run`.
**Answer:** Fixed — D-4 (new): `UpdateSourceTypeRequest.formats`, `sourcetypes.UpdateWithFormats` with one change per row, `UpdateCitationFormats` and `sourcetypes.UpdateFormats` deleted (method 121 reserved), a `setFormats` test helper for the 20 seed sites; D-8 the Save; AC-7.7, AC-7.8, T-11; map rule "Requirements need a refresh signal" and the S15-17 scope entry updated; listed in **Rules this plan bends**. It keeps the user's "one Save" answer, so it was not sent to the user as a question.

### M-2 · blocker · Swift writes the placeholder syntax and re-derives the list-form rule
**Answer:** Fixed — D-5: `citationformat.BuiltinPlaceholders` / `MetaPlaceholder` and `citationrender.Placeholders`; method 126 becomes `ListCitationPlaceholders`, replacing `ListCitationBuiltins` (no client called it); Swift maps rows (`CatalogCitationPlaceholder`); T-12, T-13, AC-7.9, AC-7.10.

### M-3 · major · Swift re-derives which keys are shared
**Answer:** Fixed — D-14: every field pick records its choice; choices are sent while their field is in the vocabulary.

### M-4 · major · The preview's render type flattens `CitationRender`
**Answer:** Fixed — D-6: `CatalogCitationRender { runs; plain }`, used by `CatalogCitationPreview.render` and `CitationRunsText(render:)`.

### M-5 · major · Source candidates are a model-held derivation
**Answer:** Fixed — D-15: `DerivedValueID.sourcesOfType(typeID:)` and `CatalogSource.updatedOrder`, which `SourcesModel` also calls; the model keeps only the pick.

### M-6 · major · Third hand-rolled generation counter
**Answer:** Fixed — D-10: `LatestCall` in `Platform/`; `CatalogSearchModel` and `CatalogCounts` move onto it with their tests unchanged (Stop condition if they need changes); T-5.

### M-7 · major · Hand-rolled failure Callouts
**Answer:** Fixed — § 6 macOS: `PVRetryCallout` for the preview, `PVFormLoadArea` for the read; brief inventory row added.

### M-8 · major · The warning line is a plain `Button`
**Answer:** Fixed — `PVFocusRingButtonStyle`, `PVIcon(.warning)`, `PVErrorText` type; brief inventory row says so.

### M-9 · major · `PVSubsectionHeader` needs two extensions
**Answer:** Fixed — D-20 (meta tone, trailing accessory); brief rows marked Extend.

### M-10 · minor · `isEditable` stored copy
**Answer:** Fixed — D-7: computed from `session.sourceType(id:)`.

### M-11 · minor · The model holds AppKit handles
**Answer:** Fixed — D-12: the view owns the cursors; the model gets `didInsert(_:into:)`.

### M-12 · minor · Pipe-encoded ComboBox value
**Answer:** Fixed — rows are `Identifiable` (`id` = text) and looked up on commit.

### M-13 · minor · A second `switch` over `Level`
**Answer:** Fixed — D-16: `LevelCopy` gains `name`.

### X-1 · major · Insert rows for two fields with one key cannot be told apart
**Answer:** Fixed — field rows carry `OriginPill`; AC-2.4; brief § 2.1.

### X-2 · major · The preview waits on the Sources list
**Answer:** Fixed — D-11, D-15: `effectivePickID` from the derived list; the view re-renders on its change (`initial: true`); before the list lands, calls go with no target; AC-4.8, T-9.

### X-3 · major · Missing line wording
**Answer:** Fixed — D-16 gives the rule; T-14 pins two cases; brief copy aligned.

### X-4 · major · Preview failure hand-built
**Answer:** Fixed — same as M-7.

### X-5 · minor · "Date (year only)" vs "Date, year only"
**Answer:** Fixed — AC-2.3 reads "Date, year only"; `builtinName(_:option:)`.

### X-6 · minor · Insert at a cursor never placed
**Answer:** Fixed — D-12: `hasCaret`; never placed → the end; unmounted → `insert` returns false and nothing is recorded; AC-2.5, T-6.

### X-7 · minor · Preview Source picker rows
**Answer:** Fixed — § 6 macOS: label title, subtext ref, value id, placeholder with the type label; fallback per D-15.

### X-8 · minor · `isEditable`, `debounce`, `isDirty`
**Answer:** Fixed — D-7 (computed `isEditable`; `debounce` an init parameter, no mutable static); D-8 (`formats.isDirty` tested before the Details guard).

### X-9 · minor · Check order for a Citation target with a bad format
**Answer:** Fixed — intended; D-3 and AC-7.6, T-1.

### X-10 · minor · Locked type with no Sources
**Answer:** Fixed — D-18: the same no-Sources note.

### X-11 · nit · Duplicate level names
**Answer:** Logged; covered by M-13.

### X-12 · nit · Docs, sweep, protoc
**Answer:** Fixed — DoD sweep excludes landed plans and review logs; § 6 FFI names the protoc prerequisite.
