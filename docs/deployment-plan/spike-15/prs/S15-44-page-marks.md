# S15-44 — The printed page can be marked unknown or supplied

**Status:** Draft
**Spike / slice:** Spike 15 · Slice 4 — Formats as data
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: Go only. No view sets or shows the page's mark yet; S15-45 adds the composer's control, gated by S15-D24)
**Board:** —
**Depends on:** S15-14 (landed [#868](https://github.com/Jake-Robins-Studios/provenencia/pull/868)); builds on S15-13 (landed [#863](https://github.com/Jake-Robins-Studios/provenencia/pull/863)), S15-37 (landed [#879](https://github.com/Jake-Robins-Studios/provenencia/pull/879)) and S15-43 (landed [#900](https://github.com/Jake-Robins-Studios/provenencia/pull/900))
**Blocks:** S15-16, S15-45
**Branch:** `s15-44-page-marks`
**Version bump:** minor, 0.25.1 → **0.26.0** (if `main`'s `VERSION` is no longer 0.25.1 when you rebase, the next minor after it): a backward-compatible feature, the locator accepts two new keys and a page selector that holds only `page_unknown`, as S15-13 bumped minor for the label-only selector ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** — (no skill covers `core/locator`; the PR adds no table, migration, FFI method or copy)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests)
**Context:** working rule "A value can be marked unknown or supplied" ([`../deployment-plan.md`](../deployment-plan.md#working-rules)); [`../evidence-explained-citation-map.md`](../evidence-explained-citation-map.md) § 6.10 "Unknown and supplied"; [`docs/interpretation-layer-data-model.md`](../../../interpretation-layer-data-model.md) § 3.2 (`page` selector); the precedent plans [`S15-13-composer-printed-page.md`](S15-13-composer-printed-page.md) (the label-only selector, `PageRef`) and [`S15-43-source-date-marks.md`](S15-43-source-date-marks.md) (a mark checked with `valuemark.Validate`)
**Planned:** 2026-11-19 against `main` @ `5a8e505` (compare with `origin/main` after `git fetch origin main`; a local `main` may be stale)
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

A Citation's printed page (`page_label` on the locator's `page` selector, S15-13) can carry the two facts of [`core/valuemark`](../../../../core/valuemark/valuemark.go): **unknown** (the original prints no page number; there is no label, and a citation prints "unpaginated") and **supplied** (the number is not printed on the page; the researcher took it from elsewhere, and a citation prints it in square brackets). The locator stores them as `page_unknown` and `page_supplied` in its JSON, refuses a pair `valuemark.Validate` refuses, and `locator.Page` returns the mark. This is the page third of the storage behind bar 11, beside S15-37 (metadata values) and S15-43 (the Source date).

**Why now.** S15-14 landed `valuemark`; S15-13 shaped `PageRef` so a field could be added without a signature change. The resolver (S15-16) reads the page's mark through `locator.Page` to print "unpaginated" or "[23]", and the composer (S15-45) writes it. Both need the locator to accept and return it first.

**What stays.** No view draws or sets the page's mark; the composer writes no mark, so every locator the app writes today is unmarked. `locator.Page`'s other fields, the region rules and the citation line ("p. 14") are unchanged. Nothing prints "unpaginated" yet (S15-16). No migration: the locator is JSON in `citations.locator_json`, and the citation's audit change already records the whole `locator_json` (`core/database/citations/citations.go` `Update`, `fields["locator_json"]`).

## 2. User stories

**US-1.** As the engine, when a Citation is written with a locator whose page selector carries a mark, I accept a pair `valuemark.Validate` accepts and refuse the rest, so that the resolver and the composer can trust the stored pair.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | `locator.Validate` on `{"version":1,"selectors":[{"type":"page","page_unknown":true}]}` (an image whose original prints no page) | nil |
| AC-1.2 | `locator.Validate` on a page selector `{"type":"page","artifact_page":37,"page_unknown":true}` | nil |
| AC-1.3 | `locator.Validate` on `{"type":"page","page_label":"23","page_supplied":true}` and on `{"type":"page","artifact_page":37,"page_label":"23","page_supplied":true}` | nil |
| AC-1.4 | `locator.Validate` on `{"type":"page","page_label":"23","page_unknown":true}` (an unknown page has no label) | `valuemark.ErrInvalid` (code `valuemark.invalid`) |
| AC-1.5 | `locator.Validate` on `{"type":"page","page_supplied":true}`, on `{"type":"page","artifact_page":37,"page_supplied":true}` and on `{"type":"page","artifact_page":37,"page_label":"  ","page_supplied":true}` (supplied needs a label) | `valuemark.ErrInvalid` |
| AC-1.6 | `locator.Validate` on `{"type":"page","page_unknown":true,"page_supplied":true}` and on `{"type":"page","artifact_page":37,"page_unknown":true,"page_supplied":true}` (both facts) | `valuemark.ErrInvalid` |
| AC-1.7 | `locator.Validate` on `{"type":"page","page_unknown":false}`, `{"type":"page","page_supplied":false}` and `{"type":"page"}` | `locator.ErrInvalid`, as `{"type":"page"}` is today |
| AC-1.8 | `locator.Validate` on `{"type":"page","page_unknown":"yes"}` and on `{"type":"page","artifact_page":1,"page_supplied":1}` (not a JSON bool) | `locator.ErrInvalid` (the document does not decode) |
| AC-1.9 | `locator.Validate` on `{"type":"page","artifact_page":0,"page_unknown":true}` | `locator.ErrInvalid` (a file page below 1 is refused before the mark) |
| AC-1.10 | `citations.Create` (through `createCitation`) with locator `{"version":1,"selectors":[{"type":"artifact"},{"type":"page","page_unknown":true}]}`; then `citations.Update` of that Citation with `{"version":1,"selectors":[{"type":"artifact"},{"type":"page","page_label":"14","page_unknown":true}]}` | The create succeeds and the stored `locator_json` is the input, trimmed; the update is refused with `valuemark.ErrInvalid` and the stored locator is unchanged |

**US-2.** As the resolver (S15-16), I read the printed page and its mark from one call.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | `locator.Page` on `{"version":1,"selectors":[{"type":"page","page_unknown":true}]}` | `PageRef{Mark: valuemark.Mark{Unknown: true}}` (no file page, no label) |
| AC-2.2 | `locator.Page` on `{"version":1,"selectors":[{"type":"artifact"},{"type":"page","artifact_page":37,"page_label":" 23 ","page_supplied":true}]}` | `PageRef{ArtifactPage: 37, Label: "23", Mark: valuemark.Mark{Supplied: true}}` |
| AC-2.3 | `locator.Page` on every locator `TestPage` covers today (no mark keys) | The same `ArtifactPage` and `Label` as today, and the zero `Mark`: an old locator reads unmarked |
| AC-2.4 | `locator.Page` on `{"version":1,"selectors":[{"type":"page","page_label":"23","page_unknown":true}]}` (an invalid pair, written by a client that skipped `Validate`) | The zero `PageRef`, as for any document that fails validation today |

**US-3.** As the engine, a depiction's region keeps working beside a marked page.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `ValidateDepictionRegion` with region `doc(page("1"), tri)` and a Citation locator `{"type":"page","artifact_page":1,"page_unknown":true}` | nil (the file pages agree; the mark is not compared) |
| AC-3.2 | `ValidateDepictionRegion` with region `doc(tri)` and a Citation locator `doc(art, {"type":"page","page_unknown":true})` | nil (the Citation has no file page, the region names none) |
| AC-3.3 | `ValidateDepictionRegion` with region `doc(page("1"), tri)` and the same unknown-only Citation locator | `locator.ErrInvalid` (the region names a file page the Citation lacks) |

## 3. Scope

| In | Covered by |
| --- | --- |
| `selectorRaw` decodes `page_unknown` and `page_supplied` as JSON bools | STEP-1, AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, AC-1.7, AC-1.8 |
| `validatePage` checks the pair with `valuemark.Validate` against the printed page, and accepts a selector that holds only `page_unknown` | STEP-1, AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, AC-1.7, AC-1.8, AC-1.9 |
| `PageRef.Mark` *(new)*; `citationPage` returns a `PageRef`; `locator.Page` returns the mark | STEP-2, AC-2.1, AC-2.2, AC-2.3, AC-2.4, AC-3.1, AC-3.2, AC-3.3 |
| The write path accepts and refuses through `locator.Validate`, unchanged code | STEP-3, AC-1.10 |
| Package doc, `interpretation-layer-data-model.md` § 3.2 | STEP-4 |

| Out | Home |
| --- | --- |
| Printing "unpaginated" and "[23]" from the mark | S15-16 (the resolver reads `PageRef.Mark`) |
| The composer's Unknown and Supplied control, and keeping the two keys on a Swift save (`CitationLocatorDraft` drops unmodeled page keys and a page selector with neither file page nor label) | S15-45 (S15-13's Out row already sends the unmodeled keys there) |
| The page's mark on the wire (`Observation`, a `ValueMark` on any citation message) | S15-16, if its render reply needs it; not planned otherwise |
| The mark in `graphfill`'s `citationWords` and today's citation line | Not planned: rule "Today's line stays the fallback" keeps the line as it is |
| A mark on the file page (`artifact_page`) | Not planned: the mark is about the printed page only (D-1) |
| Refusing a mark on a depiction's region document | Not planned: D-5 |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Selector decode | `core/locator/validate.go` `selectorRaw` | Page keys `ArtifactPage *int` (`artifact_page`) and `PageLabel *string` (`page_label`); unknown keys are ignored by `json.Unmarshal`, so a `page_unknown` key today decodes and is dropped |
| Page rule | `core/locator/validate.go` `validatePage` | A selector with `artifact_page` ≥ 1 is valid whatever its label; without it, a non-blank `page_label` is required. `{"type":"page"}` → `ErrInvalid`. Knows no mark |
| Selector loop | `core/locator/validate.go` `validateDoc` | Counts page selectors (at most one) and calls `validatePage` for each, in Citation locators and region documents alike |
| Package doc | `core/locator/validate.go` package comment | "A page selector holds artifact_page …, page_label …, or both." |
| Page read | `core/locator/depiction.go` `PageRef`, `Page`, `citationPage` | `PageRef{ArtifactPage int; Label string}`; `Page` parses and returns the zero value for an invalid document; `citationPage(doc) (page int, label string, ok bool)` reads the one selector and drops a page above `math.MaxInt32` |
| Region check | `core/locator/depiction.go` `ValidateDepictionRegion` | Calls `citationPage` for the Citation's file page only: `page, _, ok := citationPage(citation)` |
| `PageRef` caller | `core/database/graphfill/load.go` (inside the observations scan, `locator.Page(citationLocator.String)`) | Copies `ref.ArtifactPage` and `ref.Label` into `citationWords`. Reads fields by name, so a new field compiles unchanged |
| Write path | `core/database/citations/citations.go` `normalizeCreateInput`, `Update` | Both return `locator.Validate`'s error unchanged |
| The mark type | `core/valuemark/valuemark.go` `Mark`, `Validate(m, hasValue)`, `ErrInvalid` (`valuemark.invalid`) | Refuses both facts, unknown with a value, supplied without one |
| Copy | `macos/App/Platform/L10n.swift` `L10n.Errors.valueMarkInvalid` | Maps `valuemark.invalid` to "A value can’t be both unknown and supplied; an unknown value has no text, and a supplied one needs text." (S15-37) |
| Tests | `core/locator/validate_test.go` `TestValidate`, `TestPage`; `core/locator/depiction_test.go` `TestValidateDepictionRegion`; `core/database/citations/citations_test.go` `TestCitations` case "a printed page alone is a valid locator, two page selectors are not" | Table tests over JSON strings; `TestPage` compares `PageRef{ArtifactPage, Label}` |
| Domain doc | `docs/interpretation-layer-data-model.md` § 3.2 | `PageSelector` schema without marks; "one with neither is invalid"; "An unnumbered page simply omits `page_label`." |

**Precedent.** `5630412` ("Accept a printed page alone in a citation's page selector.", S15-13, [#863](https://github.com/Jake-Robins-Studios/provenencia/pull/863)) changed `validatePage`, `PageRef` and the § 3.2 text in the same shape: copy its test rows (a JSON string per case in `TestValidate`, a `PageRef` per case in `TestPage`, the `TestCitations` create-then-update case) and its doc edit. S15-43 ([#900](https://github.com/Jake-Robins-Studios/provenencia/pull/900)) `core/database/sources/sources.go` `SetDate` calls `valuemark.Validate(mark, date != nil)` and returns its error unchanged: copy that call shape.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | The mark is about the printed page: `hasValue` for `valuemark.Validate` is `sel.PageLabel != nil && strings.TrimSpace(*sel.PageLabel) != ""`. `artifact_page` does not count as a value | The file page is where the Citation is in the file, always known when present; the printed page is what the original says (§ 3.2). The rule's "unknown has no text" is about the label. A blank label counts as none, as `validatePage` and the composer already treat it | Counting `artifact_page` as a value — an image page with a file page could never be unknown, and a supplied mark could sit on a file page with no label to bracket |
| D-2 | `selectorRaw` gains `PageUnknown bool \`json:"page_unknown"\`` and `PageSupplied bool \`json:"page_supplied"\``. Absent, `null` and `false` all read false. A non-bool value fails `json.Unmarshal`, so the document is `locator.ErrInvalid` | The map names the keys (rule "A value can be marked unknown or supplied", Storage). Plain `bool`: there is no difference to keep between absent and false; S15-45 writes each key only when true | `*bool` — a third state nobody reads |
| D-3 | `validatePage` order: (1) `artifact_page` present and below 1 → `locator.ErrInvalid` (today's first check); (2) `valuemark.Validate(mark, hasValue)` → its error, returned unchanged (`valuemark.invalid`); (3) the selector must hold a file page, a non-blank label, or `page_unknown` → else `locator.ErrInvalid` | A malformed file page stays a locator error; a refused pair carries the same code as the Source date (`sources.SetDate`) and metadata values, and its copy already says what is wrong (§ 4 Copy). Step 3 widens S15-13's "file page or label" by one case: an image whose original prints no number is `{"type":"page","page_unknown":true}` | Wrapping the pair error as `locator.ErrInvalid` — a second code for one rule, and the copy "That citation locator isn’t valid" says nothing; a mark-only selector being refused — an image with an unnumbered page could not record it |
| D-4 | `PageRef` gains `Mark valuemark.Mark` *(new field)*. `citationPage(doc document) (PageRef, bool)` *(changed)* builds the whole `PageRef` (trimmed label, mark); a page above `math.MaxInt32` still returns `(PageRef{}, false)`. `Page` returns what `citationPage` returns. `ValidateDepictionRegion` reads `ref.ArtifactPage` from it | S15-13 D-4 shaped `PageRef` for this field. One reader builds the value, so a third field does not widen a tuple again | Keeping the tuple and adding a fourth return — the widening S15-13 review M-5 removed |
| D-5 | A region document's page selector is checked by the same `validatePage` (it already is, through `validateDoc`); `regionDocPages` keeps reading only `artifact_page`. A mark on a region document is accepted and ignored, as its `page_label` is | One page rule for every document, as S15-13 D-2 kept the selector count in one place. No writer puts a mark on a region document; refusing it adds a case nobody reaches | Refusing marks in `regionDocPages` — code for a case no writer reaches |
| D-6 | `Page` does not settle a stored mark (`valuemark.Settle`): a stored locator is valid by construction (`citations` validates on create and update), and an invalid one reads as the zero `PageRef`, as every invalid document does today (AC-2.4) | Unlike the metadata and date marks, the mark and its text live in one document written in one call, so they cannot drift apart (S15-43 settles because the date row can be deleted under the mark) | Settling — a second rule for documents `parse` already refuses |
| D-7 | `graphfill` is unchanged. The mark does not go on the wire in this PR | The map row is Go-only; the resolver (S15-16) calls `locator.Page` itself; today's line stays as it is (rule "Today's line stays the fallback") | Carrying the mark in `citationWords` — a field nothing reads |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `selectorRaw.PageUnknown`, `selectorRaw.PageSupplied` *(new fields)* | field | `selectorRaw.PageLabel` | Extends the existing struct; the keys sit beside `page_label` in the same selector |
| `PageRef.Mark` *(new field)* | field | `valuemark.Mark` (searched `rg "valuemark.Mark" core`) | Reuses the one mark type, as `sourcemetadata.Row.Mark` and `sources.Source.DateMark` do |

No new file, function, type or package. `citationPage` changes its return; `validatePage` gains the mark check.

**Builds on.** `core/valuemark` (`Validate`), S15-13's `PageRef` and single page-selector rule, S15-43's call shape.
**Deletes.** `citationPage`'s `(page int, label string, ok bool)` return, replaced by `(PageRef, bool)` (D-4); its only callers are `Page` and `ValidateDepictionRegion`, both in `core/locator/depiction.go`. The § 3.2 sentence "An unnumbered page simply omits `page_label`."
**Next adds.** S15-16's resolver reads `locator.Page(json).Mark` with `Label` to print "unpaginated" (unknown) or "[23]" (supplied). S15-45 writes `page_unknown` / `page_supplied` from `CitationLocatorDraft` through S15-41's control, and decodes them so a save keeps them.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A stored page selector with neither file page nor label (`{"type":"page","page_unknown":true}`) | `macos/App/Features/CitationComposer/CitationLocatorDraft.swift` `decode` / `encodeJSON` | Not reachable from this PR: nothing writes the key until S15-45. When it is: `decode` leaves `page` nil and `pageLabel` "", and `encodeJSON` drops the selector, so a Swift save would erase the mark. S15-45 models the keys (Out) |
| The same selector in `graphfill` | `core/database/graphfill/load.go` | `Page` returns `ArtifactPage` 0 and `Label` "": the observation reads as a Citation with no page, as an artifact-only locator does today; the citation line shows no page |
| A Citation with an unknown-only page and a depiction | `core/locator/depiction.go` `ValidateDepictionRegion` | `ArtifactPage` 0 → "no file page"; AC-3.2 and AC-3.3 pin both outcomes |
| An older app opening a project whose locator holds `page_unknown` with no label or file page | The older app's `locator.Validate` / `Page` | It refuses the selector (`{"type":"page"}` with no known key): `Page` reads no page, and re-saving that Citation in the older app fails `locator.invalid`. Not reachable before S15-45 writes the key; the minor bump names the release that understands it |

### Scale

None — `validatePage` adds two bool checks per page selector, at most one per document; `Page` returns one more field. No query, list or loop changes.

### Edges

- **Assumptions.** `validateDoc` assumes a page selector has something in it; D-3 step 3 keeps that true with `page_unknown` as the third "something". `ValidateDepictionRegion` assumes `ArtifactPage` 0 means no file page; an unknown-only selector keeps that (AC-3.2, AC-3.3). `TestPage` rows assume `PageRef` compares with `!=`; `valuemark.Mark` is two bools, so `PageRef` stays comparable.
- **Neighbors.** Label "  " with supplied → refused (blank is no value, AC-1.5); label "  " with unknown and a file page → valid (`{"type":"page","artifact_page":37,"page_label":"  ","page_unknown":true}`, T-1 row); label "  " with unknown and no file page → valid (the unknown is the content); `page_unknown: false` alone → refused as `{"type":"page"}` is (AC-1.7). File page 0 with unknown → `locator.ErrInvalid`, not `valuemark.invalid` (AC-1.9).
- **Removed inputs.** None — the mark and its label are in one document; nothing deletes one under the other (D-6).
- **Real data.** None — no table or seed drives the rule. Stored locators today hold no mark keys (no writer exists), so every stored document reads with the zero `Mark` (AC-2.3).
- **Untrusted size.** None new — the document is capped by `MaxDocumentBytes` before decode; two bools add no dimension.

### Schema

None — the locator is JSON in `citations.locator_json`; no migration.

### Go core

| Package | Change |
| --- | --- |
| `core/locator` `validate.go` | `selectorRaw`: `PageUnknown bool \`json:"page_unknown"\``, `PageSupplied bool \`json:"page_supplied"\`` *(new fields)* after `PageLabel`. `validatePage`: D-3's three checks. Package comment: a page selector holds `artifact_page`, `page_label`, or both, and may mark the printed page `page_unknown` or `page_supplied` |
| `core/locator` `depiction.go` | `PageRef.Mark valuemark.Mark` *(new field)*, doc comment "Mark is the printed page's unknown and supplied facts." `citationPage(doc document) (PageRef, bool)` *(changed)*. `Page` returns its result. `ValidateDepictionRegion`: `ref, ok := citationPage(citation)`; `hasPage := ok && ref.ArtifactPage > 0`; compares `ref.ArtifactPage` |

Sketch of `validatePage`:

```go
func validatePage(sel selectorRaw) error {
	if sel.ArtifactPage != nil && *sel.ArtifactPage < 1 {
		return ErrInvalid
	}
	hasLabel := sel.PageLabel != nil && strings.TrimSpace(*sel.PageLabel) != ""
	mark := valuemark.Mark{Unknown: sel.PageUnknown, Supplied: sel.PageSupplied}
	if err := valuemark.Validate(mark, hasLabel); err != nil {
		return err
	}
	if sel.ArtifactPage == nil && !hasLabel && !mark.Unknown {
		return ErrInvalid
	}
	return nil
}
```

Errors: `valuemark.invalid` → a refused pair (AC-1.4, AC-1.5, AC-1.6); `locator.invalid` → everything else, as today.

### FFI

None — no method or message changes; `CreateCitation` and `UpdateCitation` pass `locator_json` through to `citations`, which calls `locator.Validate`.

### macOS

None — no view changes (S15-45).

### Strings

None — `valuemark.invalid` is already mapped (§ 4 Copy).

## 7. Steps

**STEP-1 — The page selector takes the mark**
Files: `core/locator/validate.go`, `core/locator/validate_test.go`.
Do: D-2 fields; `validatePage` per D-3 and the sketch; the package comment. Add T-1 rows to `TestValidate`. Replace the table's `wantErr bool` with `wantErr error`: every existing `wantErr: true` row becomes `wantErr: ErrInvalid`, rows without it stay nil, and the loop checks `errors.Is(err, tt.wantErr)` when `tt.wantErr != nil`, else `err == nil`. New rows that expect a refused pair use `valuemark.ErrInvalid`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/locator/...` passes.

**STEP-2 — `locator.Page` returns the mark**
Files: `core/locator/depiction.go`, `core/locator/validate_test.go` (`TestPage`), `core/locator/depiction_test.go`.
Do: D-4. Change `TestPage`'s table to a `want PageRef` column, keep every row's values, add T-2's rows. Add T-3's rows to `TestValidateDepictionRegion`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/locator/... ./core/database/graphfill/...` passes; `go vet ./...` is clean.

**STEP-3 — The Citation write accepts and refuses the mark**
Files: `core/database/citations/citations_test.go`.
Do: add T-4 as a new case of `TestCitations`, beside "a printed page alone is a valid locator, two page selectors are not". No non-test code changes in `citations`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/citations/...` passes.

**STEP-4 — Docs and version**
Files: `docs/interpretation-layer-data-model.md` § 3.2; `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj`; this plan; `../deployment-plan.md`; `../completed.md`.
Do: in § 3.2, add `page_unknown?: boolean` and `page_supplied?: boolean` to `PageSelector`; replace "A page selector holds `artifact_page`, a non-blank `page_label`, or both; one with neither is invalid" with "A page selector holds `artifact_page`, a non-blank `page_label`, or both, or is marked `page_unknown`; one with none of these is invalid"; replace "An unnumbered page simply omits `page_label`." with "A page whose original prints no number omits `page_label` and is marked `page_unknown`; a printed page the researcher took from elsewhere is marked `page_supplied`. The two never appear together, an unknown page has no `page_label`, and a supplied one has a non-blank one (`core/valuemark`). A citation prints an unknown page as "unpaginated" and a supplied one in square brackets." Add an example `{"type": "page", "artifact_page": 37, "page_unknown": true}` after the existing one. The version bump per the header. The DoD lines for this plan, the map row and `completed.md`.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-44-page-marks.md` reports no errors; `scripts/check-pr.sh` prints `check-pr: PASS`.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period ("Let a citation's printed page be marked unknown or supplied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/locator/validate_test.go` `TestValidate` | New rows: unknown-only selector → nil; file page + unknown → nil; label + supplied, with and without a file page → nil; file page + blank label + unknown → nil; label + unknown → `valuemark.ErrInvalid`; supplied alone, file page + supplied, file page + blank label + supplied → `valuemark.ErrInvalid`; both facts, with and without a file page → `valuemark.ErrInvalid`; `page_unknown:false` alone, `page_supplied:false` alone → `ErrInvalid`; `"page_unknown":"yes"`, `"page_supplied":1` → `ErrInvalid`; file page 0 + unknown → `ErrInvalid`; existing rows unchanged | AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, AC-1.7, AC-1.8, AC-1.9, D-1, D-2, D-3 |
| T-2 | Go | `core/locator/validate_test.go` `TestPage` | Unknown-only → `PageRef{Mark: {Unknown: true}}`; artifact + file page 37 + " 23 " + supplied → `{37, "23", {Supplied: true}}`; label + unknown → zero `PageRef`; every existing row → its old `ArtifactPage` and `Label` with the zero `Mark` | AC-2.1, AC-2.2, AC-2.3, AC-2.4, D-4, D-6 |
| T-3 | Go | `core/locator/depiction_test.go` `TestValidateDepictionRegion` | Region on page 1, Citation page 1 + unknown → nil; region without page, Citation `art` + unknown-only → nil; region on page 1, Citation `art` + unknown-only → `ErrInvalid` | AC-3.1, AC-3.2, AC-3.3, D-5 |
| T-4 | Go | `core/database/citations/citations_test.go` `TestCitations` case "a printed page can be marked unknown, not unknown with a label" *(new)* | `createCitation` with the unknown-only locator → no error, `Citation.LocatorJSON` equals the input; `Update` with label + unknown → `errors.Is(err, valuemark.ErrInvalid)`; `Get` after → the create's locator | AC-1.10 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `core/locator` (the table column changes), `core/database/graphfill` (compiles against `PageRef`), `core/database/observations` (depiction checks).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none expected)
- [ ] Sweep: `rg "citationPage\(" core` shows only the `(PageRef, bool)` form; `rg "simply omits" docs` has no hit; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none)
- [ ] UI matches the brief inventory (no UI)
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (not gated: no brief)
- [ ] Domain doc updated: docs/interpretation-layer-data-model.md § 3.2 (STEP-4)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

None in the app — no view writes or shows the mark (S15-45). The slice Check line for this PR ("Locator tests: an unknown page has no label; both facts are refused; an old locator reads as unmarked") is T-1 (label + unknown, both facts) and T-2 (every existing row reads the zero `Mark`). The reviewer runs `CGO_ENABLED=1 go test -tags fts5 -run 'TestValidate|TestPage|TestValidateDepictionRegion' -v ./core/locator/` and sees each new row pass.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A Swift save drops the mark | Nothing writes it before S15-45, which models the keys (Out, Reach) |
| An older app refuses a re-save of an unknown-only Citation | Not reachable until S15-45 writes the key; the minor bump marks the release (Reach) |
| Changing `TestValidate`'s expectation column loses a row's old expectation | STEP-1 keeps each existing row's expectation; the diff of the old rows is the column only |

**Stop and report if:**

- `validatePage`, `selectorRaw`, `PageRef`, `Page` or `citationPage` no longer match §4 at your base.
- A caller of `citationPage` or `PageRef` exists outside `core/locator/depiction.go` and `core/database/graphfill/load.go` (`rg "citationPage|PageRef" --type go`).
- Any Go code writes or re-encodes a locator document (`rg "json.Marshal" core/locator core/database/citations`), so a mark could be dropped on a Go path.
- An existing `TestValidate`, `TestPage` or `TestValidateDepictionRegion` row needs a different expectation to pass.
- A test outside §8 fails because a stored locator now validates differently.

## 12. Open questions

None.

## 13. PR

**Title:** S15-44 — The printed page can be marked unknown or supplied
**Body:** objective in one sentence; what shipped against US-1 – US-3; AC evidence; deviations from the plan; manual check (the locator test run); `Plan: docs/deployment-plan/spike-15/prs/S15-44-page-marks.md`.
