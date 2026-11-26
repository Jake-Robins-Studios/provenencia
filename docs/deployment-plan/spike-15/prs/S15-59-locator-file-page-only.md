# S15-59 — The locator only finds things in its Artifact

**Status:** Landed in [#991](https://github.com/Jake-Robins-Studios/provenencia/pull/991) (2026-11-26)
**Spike / slice:** Spike 15 · Slice 11 — Metadata at any level
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: the composer has not shown or written a printed page in the locator since S15-56, and no view reads the locator's label)
**Board:** —
**Depends on:** S15-58 (landed [#987](https://github.com/Jake-Robins-Studios/provenencia/pull/987))
**Blocks:** —
**Branch:** `s15-59-locator-file-page-only`
**Version bump:** minor, 0.45.0 (today's `VERSION`) → **0.46.0** (or the next minor after `main`'s `VERSION` when you rebase): a locator write the engine accepted until now is refused ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md), [`add-depiction-value`](../../../../.agents/skills/add-depiction-value/SKILL.md) (`ValidateDepictionRegion` and `Readable` read the Citation's locator)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests)
**Context:** map scope entry S15-59 ([`../deployment-plan.md`](../deployment-plan.md)); working rules "The locator only finds things in its Artifact", "The printed page is a metadata field", "A value can be marked unknown or supplied"; [`docs/interpretation-layer-data-model.md`](../../../interpretation-layer-data-model.md) §§ 3.2, 3.3, 3.6, 3.8
**Planned:** 2026-11-26 against `main` @ `8d95af5`
**Review:** [`S15-59-locator-file-page-only.review.md`](S15-59-locator-file-page-only.review.md) — Fits / Ready with changes, two rounds; every finding Fixed, Declined or answered by the user; nothing open

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

A Citation's locator says where the Citation is in its Artifact, and nothing else. The page selector holds the file page (`artifact_page`) alone; the printed page and its unknown and supplied marks live on the Citation's own Page value (S15-56). The locator's `page_label`, `page_unknown` and `page_supplied` keys and the label-only page selector go from `core/locator` and from the composer's `CitationLocatorDraft`. Locators already stored with those keys keep reading, rendering and saving.

**Why now.** S15-58 removed the last reader of the label outside `core/locator`; the keys are stored and checked but mean nothing.

**What stays.** The file page, the region, the text quote, unknown selector types, and depiction regions, which compare file pages as today. The listed Citation's `page_label` proto fields and `pageLabel` Swift properties (`ListedCitation`, `ReconcilerOutcomeDetail`, `CitationStepMenuRow.locatorText(pageLabel:locator:)`): they carry the Citation's Page value, not the locator key. No view changes.

## 2. User stories

**US-1.** As a researcher with Citations saved before this version, my Citations open, cite and save as before, so the retired keys never cost me a Citation.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Stored locator `{"version":1,"selectors":[{"type":"artifact"},{"type":"page","artifact_page":37,"page_label":"23","page_supplied":true}]}` | `locator.ArtifactPage` returns 37; `{citation.image}` renders "37" |
| AC-1.2 | Stored locator `{"version":1,"selectors":[{"type":"page","page_label":"14"}]}` | `locator.ArtifactPage` returns 0; the census full citation renders with no ", p." group (`TestRenderLocatorLabelAlone`, unchanged) |
| AC-1.3 | A Citation stored with AC-1.1's locator; the Metadata sheet saves a metadata change, sending the stored locator text unchanged | Saved; the stored locator is unchanged and the update records no `citation` row change |
| AC-1.4 | The same Citation; the composer saves it (its draft re-encodes the locator) | Saved; the stored locator is `{"version":1,"selectors":[{"type":"artifact"},{"type":"page","artifact_page":37}]}` |
| AC-1.5 | A stored Citation locator `{"version":1,"selectors":[{"type":"artifact"},{"type":"page","page_label":"14"}]}` and a depiction region with no page selector | `ValidateDepictionRegion` accepts it, as today |

**US-2.** As the engine, I refuse a new locator that holds a printed page, so nothing writes the retired keys again.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Create a Citation with `{"version":1,"selectors":[{"type":"artifact"},{"type":"page","page_label":"14"}]}` | `locator.invalid` |
| AC-2.2 | Update a Citation's locator to `{"version":1,"selectors":[{"type":"page","artifact_page":37,"page_unknown":true}]}` (differs from the stored one) | `locator.invalid`; the stored locator is unchanged |
| AC-2.3 | `locator.Validate` of `{"version":1,"selectors":[{"type":"page"}]}` and of `{"version":1,"selectors":[{"type":"page","artifact_page":0}]}` | `ErrInvalid` for both |
| AC-2.4 | `locator.Validate` of `{"version":1,"selectors":[{"type":"time_range","start_ms":0,"page_label":"x"}]}` | Accepted: only a page selector is checked for the retired keys |

**US-3.** As a researcher, the composer's locator never writes a printed page.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `CitationLocatorDraft.decode` of AC-1.1's locator, then `encodeJSON()` | `page == 37`; the JSON holds `"artifact_page":37` and neither `page_label` nor `page_supplied` |
| AC-3.2 | `CitationLocatorDraft.decode` of `{"version":1,"selectors":[{"type":"page","page_label":"iv"}]}` | Equals `.artifactOnly()`; `encodeJSON()` holds no `"type":"page"` |

## 3. Scope

| In | Covered by |
| --- | --- |
| `core/locator` reads ignore the retired keys and a page selector with no file page | STEP-1, AC-1.1, AC-1.2, AC-1.5 |
| `locator.Validate` refuses a page selector with no file page or with a retired key | STEP-1, AC-2.1 – AC-2.4 |
| `PageRef` and `Page` give way to `ArtifactPage`; its two callers follow | STEP-1, STEP-2, AC-1.1 |
| `citations.Update` checks the locator only when it changes | STEP-3, AC-1.3, AC-1.4, AC-2.2 |
| Go tests that write a retired key through a write path drop it | STEP-1, STEP-3, STEP-4 |
| Go tests share `depictionvaluetest.Locator` for the page-1 locator (D-8) | STEP-5 |
| `CitationLocatorDraft.pageLabel` goes; the draft reads and writes the file page alone | STEP-6, AC-3.1, AC-3.2 |
| Domain doc | STEP-7 |

| Out | Home |
| --- | --- |
| Rewriting stored locators that hold the retired keys | not planned (user, 2026-11-22: no migration; reads ignore them) |
| Refusing the retired keys in a depiction's region document | not planned (D-5) |
| Renaming the listed Citation's `page_label` proto fields and `pageLabel` Swift properties | not planned (S15-56: the name stays the display page's) |
| `FakeStore.listedPageLabels` (`macos/App/Platform/FakeStore.swift`) | not planned: it seeds the listed Citation's Page value, not the locator key |
| The citation map's `C.page_label` inventory rows and its storage list (`../evidence-explained-citation-map.md` §§ 6.2 – 6.7, 6.8 storage), and `../citation-formats.md` line 74 | not planned: design analysis written before slice 11; the map's rule "The printed page is a metadata field" records the move, and spike close distills both files ([`archive-docs`](../../../../.agents/skills/archive-docs/SKILL.md)) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Decode | `core/locator/validate.go` `selectorRaw` (`PageLabel`, `PageUnknown`, `PageSupplied`), `pageMark` | Decodes the retired keys; a non-bool `page_unknown` fails the decode, so the read fails |
| Read check | `core/locator/validate.go` `validatePage` | Refuses a page selector with no file page, no non-blank label and no unknown mark: a stored label-only selector reads only because of its label |
| Write check | `core/locator/validate.go` `Validate` | Accepts a label-only or unknown-only selector; checks the mark pair with `valuemark.Validate` |
| Page read | `core/locator/depiction.go` `PageRef` (`ArtifactPage`, `Label`, `Mark`), `Page`, `citationPage` | `Label` and `Mark` have no reader outside `core/locator` since S15-58 |
| Depiction | `core/locator/depiction.go` `ValidateDepictionRegion`, `regionDocPages` | Compares file pages through `citationPage`; the doc comment names label-only and unknown-only Citation locators |
| Callers | `core/database/citationrender/load.go` `subject.page locator.PageRef`, `fillValues` (`s.page.ArtifactPage`); `core/database/graphfill/load.go` (line 219, `ref.ArtifactPage`) | Read the file page only |
| Writers | `core/database/citations/citations.go` `normalizeCreateInput`, `Update` (line 347); `core/database/connect/connect.go` (`NormalizeCreateInput`) | `Update` validates `in.LocatorJSON` before it reads the stored row |
| Sheet save | `macos/App/Features/CitationComposer/CitationMetadataSheetModel.swift` `save` (line 78) | Sends `citation.locatorJSON`, the stored text, to `updateCitation`: a stored label would be refused by a write check that ignores whether the locator changed |
| Composer save | `macos/App/Features/CitationComposer/CitationFieldsDraft.swift` (line 96), `CitationComposerContext.swift` (line 144) | Send `locator.encodeJSON()`, re-encoded from the draft |
| Swift draft | `macos/App/Features/CitationComposer/CitationLocatorDraft.swift` `pageLabel`, `encodeJSON`, `decode` | Reads and writes `page_label`; no Swift code sets `pageLabel` since S15-56 |
| Go tests | `core/locator/validate_test.go` `TestValidate` (19 rows with a retired key), `TestPage`; `fuzz_test.go` `FuzzValidate`; `depiction_test.go` `TestValidateDepictionRegion` | Assert the keys' meaning |
| Go tests | `core/database/citations/citations_test.go` `validLocator` (line 40), `TestCitations` "a printed page alone is a valid locator, two page selectors are not" (line 374), "a printed page can be marked unknown, not unknown with a label" (line 407), and `locatorJSON` at lines 874 and 976; `core/database/conclusiondetails/conclusiondetails_test.go` line 231; `core/database/graphfill/records_test.go` line 299; `core/database/evidencegraphs/progress_test.go` `validLocator`; `api/ffi/handlers/citations_test.go` `validLocatorJSON`; `api/ffi/handlers/citation_render_test.go` `pageLocatorJSON` (callers at lines 82, 121, 122, 447) and the two locators at lines 176 and 178 | Write a retired key through `citations` or the FFI; each fails once `Validate` refuses it |
| Go tests | `core/database/citationrender/render_test.go` `pageLocator`, `TestRender`'s `imageLocator`, `TestRenderUnknownAndSupplied` | Insert locators with raw SQL (`world.cite`): stored documents. They pass unchanged once reads ignore the keys |
| Swift tests | `macos/ProvenenciaTests/CitationLocatorDraftTests.swift` `printedPageRoundTrips`, `printedPageAloneEncodesALabelOnlySelector`, `blankPrintedPageWritesNoSelector`, `printedPageSurvivesLocatorResets`, `nonStringPageLabelIsIgnored` | Assert `pageLabel` |

**Precedent.** S15-44 ([#905](https://github.com/Jake-Robins-Studios/provenencia/pull/905)) added the keys and split `Validate` (the write check) from `parse` (the read). This PR keeps that split and moves the keys out of both. S15-58 ([#987](https://github.com/Jake-Robins-Studios/provenencia/pull/987)) retired the `{citation.page}` reader and left stored text readable with no migration; copy its handling of stored data.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | Reads (`parse`, so `ArtifactPage` and `ValidateDepictionRegion`) ignore `page_label`, `page_unknown` and `page_supplied` whatever their JSON type, and accept a page selector with no `artifact_page` as no page. `artifact_page` below 1 and a second page selector stay invalid | Rule "The locator only finds things in its Artifact": no read fails on the stored keys; with them ignored, a label-only selector is a selector with nothing in it | Keeping read-side decoding of the keys to settle them: nothing reads them |
| D-2 | `selectorRaw` keeps `PageLabel`, `PageUnknown` and `PageSupplied` as `json.RawMessage` fields that record presence only: the one `decode` fills them, whatever the value's JSON type (`null` included), matching the key's case as `encoding/json` does, and no read looks at them. `Validate` refuses, with `ErrInvalid`, a page selector with no file page and a page selector where any of the three is non-nil. Only `type: "page"` selectors are checked | The map's Check: a new locator with one is refused; one decode of the format, so a later rule added to `decode` cannot miss the check | A second map decode in `Validate`: a private decoder beside the package's own; silently stripping the keys on write: a client still writing them would never learn |
| D-3 | `PageRef` and `Page` go; `ArtifactPage(locatorJSON string) int` returns the file page, 0 for none, an invalid document, or a page above `math.MaxInt32`. One method, `selectorRaw.filePage() (int, bool)`, returns `*ArtifactPage` and true when it is non-nil; `Validate` and `regionDocPages` call it and keep accepting a page above `math.MaxInt32`, as today. `citationPage(doc document) int` calls it and returns 0 for none or for a page above `math.MaxInt32`, as `citationPage` does today; `ArtifactPage` is `parse` then `citationPage` | One field left, both callers read `.ArtifactPage` alone; the file-page rule gets one home in the package | A one-field `PageRef`: a struct with nothing to group |
| D-4 | `citations.Update` reads the stored row first and calls `locator.Validate` only when `in.LocatorJSON` differs from the stored `LocatorJSON`. Order: trims, id length, `RequireUserID`, the stored-row read, then the locator check; an unknown Citation id with an invalid locator now returns `citations.ErrInvalid` | The Metadata sheet sends the stored text back unchanged (§4 Sheet save); an unchanged locator was checked when it was written, and refusing it would refuse a metadata save on any Citation stored with a label | Re-encoding the locator in `CitationMetadataSheetModel.save`: a reformatted JSON string records a `citation` change on every metadata save; stripping the keys in `Update`: D-2's rejected option |
| D-5 | `ValidateDepictionRegion` keeps its read-side checks for both documents (D-1) and does not call `Validate`; a region document's page selector must still hold `artifact_page` (`regionDocPages`) | It also runs on every read (`depictionvalue.Readable`), so it must not refuse stored text; the app writes region documents only through `CitationLocatorDraft.encodeJSON`, which after STEP-6 writes no retired key | A write-only region check: a second validator for documents no client writes the keys into |
| D-6 | A test that writes a retired key through `citations`, `connect` or the FFI drops the key; where its locator is a page-1 or page-12 file page or a label alone, it uses `depictionvaluetest.Locator`. Raw-SQL fixtures in `citationrender` keep their keys: they are the stored documents D-1 reads | The printed text of every render test comes from the Page value since S15-58, and no test reads page 12, so expectations do not change | Rewriting the raw-SQL fixtures: they are the read-tolerance cases |
| D-8 | Every Go test copy of the literal `{"version":1,"selectors":[{"type":"page","artifact_page":1}]}` reads `depictionvaluetest.Locator` (`core/depictionvalue/depictionvaluetest`, which imports nothing); the shared constants `citationstest.PageLocator` and `evidencelayertest.Locator` become `= depictionvaluetest.Locator` so their callers stay as they are (user, 2026-11-26: all copies) | This PR changes the locator format; the next change edits one constant | Only the copies this PR must edit: leaves about 16 |
| D-7 | The map's rule "The locator only finds things in its Artifact" and the S15-59 scope entry (Ships, Deletes, Check) say what D-2 – D-4 do. Edited in planning with the user's answer below; the implementer changes nothing in them | The plan and the map must agree | — |

**Rules this plan bends.** D-4 bends rule "The locator only finds things in its Artifact" (user, 2026-11-22), which said the next save of a Citation writes the retired keys out: a metadata-only save sends the stored locator unchanged and keeps them. The user's answer (2026-11-26): keep them; the composer's next save of the Citation's locator writes them out. The rule was updated in planning (D-7).

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `locator.ArtifactPage(locatorJSON string) int` *(new)* | func | `locator.Page` | Replaces it (D-3) |
| `selectorRaw.filePage() (int, bool)` *(new)* | method | the nil and `MaxInt32` checks in `citationPage` and `regionDocPages` (`core/locator/depiction.go`) | Replaces them, and serves `Validate` (D-3) |

**Builds on.** S15-44's `Validate`/`parse` split; `citations.Update`'s existing read of the stored row (`sqlGet`).
**Deletes.** The `*string` and `bool` meaning of `selectorRaw.PageLabel`, `.PageUnknown`, `.PageSupplied` (they become presence-only, D-2); `selectorRaw.pageMark`; `locator.PageRef` and `locator.Page`; the `valuemark` import in `core/locator` (package and tests); the label and mark branches of `validatePage` and of the package and `ValidateDepictionRegion` doc comments; `CitationLocatorDraft.pageLabel` and its reads in `encodeJSON` and `decode`; the handlers' `pageLocatorJSON`; every test-local copy of the page-1 locator literal (D-8); `core/locator` from `core/valuemark`'s package comment; the Swift tests `blankPrintedPageWritesNoSelector`, `printedPageSurvivesLocatorResets`, `nonStringPageLabelIsIgnored`; the `TestValidate` rows that assert a mark pair (now refused for the key alone).
**Next adds.** None named: slice 11 ends here.

### Reach

| New path or state | Destination | Checked |
| --- | --- | --- |
| A stored page selector with no `artifact_page` (label-only, unknown-only, or `{"type":"page"}`) now parses | `ArtifactPage` → 0; `citationrender.fillValues` sets no `CitationImage`; `graphfill` sets `ArtifactPage` 0; `ValidateDepictionRegion` treats the Citation as having no file page; Swift `CitationLocatorDraft.decode` already ignores such a selector | `{"type":"page"}` alone was unreadable before; no client wrote it (`Validate` refused it). T-2 rows |
| A stored page selector with a non-bool `page_unknown` or `page_supplied` beside a file page now parses | `ArtifactPage` returns the file page | T-2 row "a non-bool mark beside a file page" |
| A metadata save with an unchanged locator skips `locator.Validate` | `citations.Update` | The unchanged text is what is stored; the row change is computed as today. T-5 |

### Scale

None — no list or loop changes; `Update` already reads the stored row.

### Edges

- **Assumptions.** `ValidateDepictionRegion` assumes a Citation with no file page has no page selector worth comparing; D-1 keeps that (a selector with no `artifact_page` is no page). `Readable` assumes the read check never refuses what the write accepted: every document `Validate` accepts still parses (D-2 is stricter than D-1). `FuzzValidate` holds both (T-3).
- **Neighbors.** File page with a label → reads the file page, write refused (AC-1.1, AC-2.2). File page alone → read and write as today. Label alone → reads as no page, write refused (AC-1.2, AC-2.1). `{"type":"page"}` → reads as no page (was unreadable), write refused as today (AC-2.3). A retired key on a non-page selector → preserved, accepted (AC-2.4). `"Page_Label"` or `"page_label": null` on a page selector → read ignores it, write refused (D-2).
- **Removed inputs.** A stored `page_unknown` or `page_supplied` reaches nothing; since S15-58 no citation printed them. Accepted by the rule.
- **Real data.** None — no table or seed drives the rule. The dogfood project's few stored labels (user, 2026-11-22) read as AC-1.1 and AC-1.2.
- **Untrusted size.** None — no new walk: the retired fields fill in the decode `parse` already bounds at `MaxDocumentBytes`.

### Schema

None — no catalog change; stored locators are not migrated.

### Go core

| Package | Change |
| --- | --- |
| `core/locator` | `validate.go`: `selectorRaw`'s `PageLabel`, `PageUnknown`, `PageSupplied` become `json.RawMessage` with tags `page_label`, `page_unknown`, `page_supplied` and the comment "retired by S15-59: presence only; reads never look at them". `filePage` (D-3). `validatePage` refuses only `artifact_page` below 1. `Validate`: after `parse`, a page selector whose `filePage` is not ok, or with any retired field non-nil, → `ErrInvalid`. The package comment says a page selector holds `artifact_page`, that reads ignore the keys S15-59 retired, and that `Validate` refuses them. `depiction.go`: D-3; `ValidateDepictionRegion` reads `page := citationPage(citation)` and `hasPage := page > 0`; its comment drops the label-only and unknown-only clause and says a Citation page selector with no file page is no page |
| `core/valuemark` | `valuemark.go` package comment: the stores that call `Validate` are the Source's metadata values and date; "and a Citation's printed page (core/locator)" goes |
| `core/database/citationrender` | `load.go`: `subject.page` becomes `artifactPage int`, set from `locator.ArtifactPage(c.LocatorJSON)`; `fillValues` reads it |
| `core/database/graphfill` | `load.go`: `w.page = locator.ArtifactPage(citationLocator.String)` |
| `core/database/citations` | `citations.go` `Update`: D-4. The `locator.Validate` call moves below the `prev` read and runs when `in.LocatorJSON != prev.LocatorJSON`; its comment says an unchanged locator was checked when written |

Errors: none new; `locator.invalid` covers every refusal. `valuemark.invalid` is no longer returned for a locator.

### FFI

None — no message changes; `CreateCitationWithObservations`, `UpdateCitation` and `CreateCitedBridge` refuse what `Validate` refuses.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Locator draft | `CitationLocatorDraft` | `macos/App/Features/CitationComposer/CitationLocatorDraft.swift` | `pageLabel` and its doc comment go; `encodeJSON` appends a page selector only for a file page of 1 or more, holding `type` and `artifact_page`; `decode` reads `artifact_page` alone from a page selector |

States: none change. Accessibility: none changes.

### Strings

None — no copy names the locator's printed page since S15-56.

## 7. Steps

**STEP-1 — The locator holds the file page alone**
Files: `core/locator/validate.go`, `depiction.go`, `validate_test.go`, `fuzz_test.go`, `depiction_test.go`, `core/valuemark/valuemark.go`, `core/database/citationrender/load.go`, `core/database/graphfill/load.go`. Skill: `add-depiction-value`.
Do: the `core/locator`, `core/valuemark`, `citationrender` and `graphfill` rows of §6 Go core (the two callers change here so the tree builds). Tests: T-1, T-2, T-3, T-4.
Check: `go build ./... && go vet ./...` passes; `CGO_ENABLED=1 go test -tags fts5 ./core/locator/...` passes; `CGO_ENABLED=1 go test -tags fts5 -run FuzzValidate -fuzz FuzzValidate -fuzztime 20s ./core/locator` passes. Packages whose tests write a retired key fail until STEP-3 and STEP-4.

**STEP-2 — Render keeps reading stored locators**
Files: `core/database/citationrender/render_test.go`.
Do: `pageLocator`'s comment: "pageLocator is a Citation locator stored before S15-59, with a page_label alone. Reads ignore the label, so the selector is no page." `TestRenderLocatorLabelAlone`'s comment: "TestRenderLocatorLabelAlone is AC-1.2: a stored locator's page_label is ignored on read and prints nothing when no level holds a page value." `TestRender`'s `imageLocator` gets the comment "stored with a page_label; the file page still reads" (T-6).
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/citationrender/...` passes with `TestRenderScale` at its existing SELECT counts.

**STEP-3 — An unchanged locator saves without a second check**
Files: `core/database/citations/citations.go`, `citations_test.go`.
Do: the `core/database/citations` row of §6 Go core. In `citations_test.go`: `validLocator` (local to `TestCitations`) becomes `depictionvaluetest.Locator`; the `locatorJSON` literals in `TestListCitedTx` (line 874) and `TestFirstOfSource` (line 976) become `depictionvaluetest.Locator` (neither reads the page); the two subtests at lines 374 and 407 are replaced by T-5's two subtests.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/citations/...` passes.

**STEP-4 — Tests stop writing the retired keys**
Files: `core/database/conclusiondetails/conclusiondetails_test.go`, `core/database/graphfill/records_test.go`, `core/database/evidencegraphs/progress_test.go`, `api/ffi/handlers/citations_test.go`, `api/ffi/handlers/citation_render_test.go`.
Do: D-6 at each §4 site in these files: drop `,"page_label":"9"` (conclusiondetails line 231, graphfill line 299; they keep page 37); `validLocator` (progress) and `validLocatorJSON` (handlers) become `depictionvaluetest.Locator`; delete `pageLocatorJSON` and pass `validLocatorJSON` at its four callers; lines 176 and 178 become `{"version":1,"selectors":[{"type":"artifact"}]}`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./...` passes; `rg -n 'page_label|page_unknown|page_supplied' --type go` hits only `core/locator` (the retired fields' tags, its tests, the package comment) and `core/database/citationrender/render_test.go`, plus `page_label` in `api/proto`, `api/ffi/handlers/conclusion_detail*.go`, `citations.go` and `citations_test.go` as the listed Citation's Page value (`GetPageLabel`, `PageLabel:`).

**STEP-5 — Tests share one page-1 locator**
Files: `core/database/citations/citationstest/citationstest.go`, `core/database/evidencelayer/evidencelayertest/evidencelayertest.go`, and each file `rg -n '`\{"version":1,"selectors":\[\{"type":"page","artifact_page":1\}\]\}`' --type go` lists outside `core/depictionvalue/depictionvaluetest`, `core/locator`, `core/database/citationrender` and `core/database/graphcache/graphcachetest` (whose copy sits inside a SQL string) (at the planning base: `api/ffi/handlers/artifacts_test.go`, `api/ffi/handlers/conclusion_summaries_test.go`, `api/ffi/handlers/promote_align_test.go`, `core/database/connect/connect_test.go`, `core/database/effects/evidence_handles_test.go`, `core/database/effects/handle_paths_test.go`, `core/database/effects/released_metadata_scope_test.go`, `core/database/observations/observations_test.go`, `core/database/deleteimpact/impact_test.go`, `core/database/citations/delete_test.go`, `core/database/artifacts/artifacts_test.go`, `core/database/subjects/delete_test.go`, `core/database/evidencegraphs/evidencegraphs_test.go`, `core/database/graphfill/load_test.go`, `core/database/properties/properties_delete_test.go`, and `api/ffi/handlers/citations_test.go` `likenessLocatorJSON`).
Do: D-8. A named constant or variable that only holds the literal is replaced at its uses by `depictionvaluetest.Locator` and deleted; an inline literal becomes `depictionvaluetest.Locator`.
Check: the `rg` above hits only `core/depictionvalue/depictionvaluetest/depictionvaluetest.go` and `core/database/graphcache/graphcachetest/graphcachetest.go`; `CGO_ENABLED=1 go test -tags fts5 ./...` passes.

**STEP-6 — The composer's draft writes the file page alone**
Files: `macos/App/Features/CitationComposer/CitationLocatorDraft.swift`, `macos/ProvenenciaTests/CitationLocatorDraftTests.swift`. Skill: `add-swift-test`.
Do: the §6 macOS row. Tests: T-7; delete the three tests §6 Deletes names.
Check: on the Mac, `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/CitationLocatorDraftTests -only-testing:ProvenenciaTests/CitationComposerModelTests` passes; `rg -n 'pageLabel' macos/App/Features/CitationComposer/CitationLocatorDraft.swift` has no hit.

**STEP-7 — Docs**
Files: `docs/interpretation-layer-data-model.md`.
Do: `interpretation-layer-data-model.md` § 3.2: replace the section body with: the page selector names a page by its 1-based position in the Artifact (`artifact_page`, required, at least 1), its only key; an image Artifact has no file page, so its locator has no page selector; the page the original prints, and its unknown and supplied marks, are the Citation's Page metadata value (the seeded `page` field), not a locator fact; the schema `PageSelector { type: "page"; artifact_page: integer >= 1 }`; the one-page-selector rule and the region document's file page, kept from today's text; and one paragraph: locators stored before 0.46.0 may hold `page_label`, `page_unknown` and `page_supplied`; reads ignore them, a write holding one is refused, and the composer's next save of the Citation's locator leaves them out. Drop the "general rule" quote's `page_label` sentence, the `page_label` example and the pagination-values list. § 3.3 and § 3.6 examples: delete the `"page_label": "23"` line and the comma before it. § 3.8 invariant 11 reads "The page the original prints is the Citation's Page metadata value, not part of the locator."
Check: `rg -n 'page_label|page_unknown|page_supplied' docs/*.md` hits only § 3.2's stored-locators paragraph; `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-59-locator-file-page-only.md` passes.

**STEP-8 — Version and status**
Files: `VERSION`, `core/version.go`, every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`, `docs/deployment-plan/spike-15/completed.md`, `deployment-plan.md` (map row), this plan.
Do: the header's bump; the DoD's status, map row and `completed.md` lines.
Check: `rg -n 'MARKETING_VERSION' macos/Provenencia.xcodeproj/project.pbxproj` shows the new version on every line; `scripts/check-pr.sh` prints `check-pr: PASS` (on the Mac).

Commits: STEP-1 – STEP-4 are one commit, "Keep the locator to the file page; stored printed pages read and save.", because the test tree does not pass between them; STEP-5 – STEP-8 one commit each (STEP-5: "Share one page locator across the Go tests."). The subject is one full imperative sentence that says what changed for the researcher, ending in a period. No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/locator/validate_test.go` `TestValidate` | Every row whose JSON holds a retired key wants `ErrInvalid` (the `valuemark.ErrInvalid` rows included); "page selector with nothing in it" stays `ErrInvalid`. New rows: "a retired key on a padded page type" `{"type":" page ","artifact_page":3,"page_label":"x"}` → `ErrInvalid`; "a null retired key" `{"type":"page","artifact_page":3,"page_label":null}` → `ErrInvalid`; "a retired key in another case" `{"type":"page","artifact_page":3,"Page_Label":"x"}` → `ErrInvalid`; "a retired key on an unknown selector type" (AC-2.4's JSON) → accepted | AC-2.3, AC-2.4, D-2 |
| T-2 | Go | `core/locator/validate_test.go` `TestArtifactPage` *(new; replaces `TestPage`)* | `TestPage`'s documents with the want reduced to the file page (37 for "page with label" and "file page, label, supplied"; 4 for "page without label" and "stored supplied without a label…"; 0 for the rest), plus "a non-bool mark beside a file page" `{"type":"page","artifact_page":5,"page_unknown":"yes"}` → 5 | AC-1.1, AC-1.2, D-1, D-3 |
| T-3 | Go | `core/locator/fuzz_test.go` `FuzzValidate` | Same seeds. Nothing panics; when `Validate` accepts a document, `parse` accepts it, its page selector (if any) has a non-nil `ArtifactPage`, and `ArtifactPage(doc)` equals it when at most `math.MaxInt32`, else 0 | D-1, D-2 |
| T-4 | Go | `core/locator/depiction_test.go` `TestValidateDepictionRegion` | Every row keeps its expectation. Rename "region page selector carries an unpaired mark" → "region page selector carries retired keys" and "citation page selector carries an unpaired mark" → "citation page selector carries retired keys"; the `label` and `unknown` fixtures get the comment "stored before S15-59" | AC-1.5, D-5 |
| T-5 | Go | `core/database/citations/citations_test.go` `TestCitations` subtests "a page selector holds a file page" *(new)* and "a stored printed page reads and saves" *(new)* | Both start from `mustSeed(t)`, the same `obs` (sex = female) and the `createCitation` / `writes.Call(… "update_citation" …)` shapes of the subtests they replace. First: create with AC-2.1's locator → `locator.ErrInvalid`; create with `validLocator`, then update it to `{"version":1,"selectors":[{"type":"page","artifact_page":1},{"type":"page","artifact_page":2}]}` → `locator.ErrInvalid`; create with that two-selector locator → `locator.ErrInvalid`. Second: create with `{"version":1,"selectors":[{"type":"artifact"},{"type":"page","artifact_page":37}]}`; `dbtest.MustDB(t, c).Exec("UPDATE citations SET locator_json = ? WHERE id = ?", …)` to AC-1.1's locator; `Get` returns it verbatim; `Update` with that text and the Citation's other columns unchanged → returns no changes (AC-1.3); the same with a new `Label` → one change, `LocatorJSON` unchanged; `Update` with AC-2.2's locator → `locator.ErrInvalid`, stored text unchanged; `Update` with the created locator → saved, stored text equals it (AC-1.4) | AC-1.3, AC-1.4, AC-2.1, AC-2.2, D-4 |
| T-6 | Go | `core/database/citationrender/render_test.go` `TestRender` row "the image is the file page" | Unchanged: `imageLocator` (raw SQL, file page 37 with `page_label` "23") → "image 37" | AC-1.1 |
| T-7 | Swift | `macos/ProvenenciaTests/CitationLocatorDraftTests.swift` `storedPrintedPageIsDroppedOnSave` *(new; replaces `printedPageRoundTrips`)*, `labelOnlyPageSelectorReadsAsNoPage` *(new; replaces `printedPageAloneEncodesALabelOnlySelector`)* | AC-3.1; AC-3.2 | AC-3.1, AC-3.2 |
| T-8 | Swift | `macos/ProvenenciaTests/CitationComposerModelTests.swift` (line 794, the `locatorText` test) | Unchanged: a stored `page_label` is not read | AC-1.2 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: the `TestCitations` subtests, `FuzzValidate`'s corpus, `TestRenderScale` (SELECT counts).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left — none: no copy changes
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it). Names: `locator.PageRef`, `locator.Page(`, `pageMark`, `CitationLocatorDraft.pageLabel`, and `core/locator` in `core/valuemark`'s comment
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated — none
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New — none: no brief
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated) — none: no brief
- [ ] Domain doc updated if a rule in docs/*.md changed: docs/interpretation-layer-data-model.md §§ 3.2, 3.3, 3.6, 3.8 (STEP-7)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Open a project created with this build. In the composer, on a PDF Artifact, make a Citation on page 3 with a region; save. Reopen it: page 3 and the region are restored, and its Page value (if typed on the board) shows as before.
2. On a copy of the dogfood project, with `sqlite3`: `UPDATE citations SET locator_json = '{"version":1,"selectors":[{"type":"artifact"},{"type":"page","artifact_page":1,"page_label":"23","page_supplied":true}]}' WHERE ref = '<a PDF Citation's ref>';`. Open it with this build: the Citation opens on file page 1; its provenance sheet citation is unchanged. Edit its metadata in the Metadata sheet and save: saved. Then change its label in the composer and save: `SELECT locator_json FROM citations WHERE ref = '<ref>'` holds no `page_label` (AC-1.3, AC-1.4).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A save of a dogfood Citation stored with a label is refused | D-4; T-5; §10 step 2 |
| A test expectation is "fixed" by editing printed text | D-6: only locators change; no render expectation changes |

**Stop and report if:**

- A Go caller of `locator.Page` exists beyond the two §4 Callers rows, or a caller reads `PageRef.Label` or `.Mark`.
- A Swift file outside `CitationLocatorDraft.swift` and its tests reads or sets `CitationLocatorDraft.pageLabel`.
- A Swift write path other than `CitationMetadataSheetModel.save` sends a stored `locatorJSON` without re-encoding it, and passes a test only with D-4's skip.
- A test outside §4's rows fails, other than by D-6's substitution.
- `TestRenderScale`'s SELECT counts or `seed-citations.txt` change.

## 12. Open questions

None.

## 13. PR

**Title:** S15-59 — The locator only finds things in its Artifact
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-59-locator-file-page-only.md`.
