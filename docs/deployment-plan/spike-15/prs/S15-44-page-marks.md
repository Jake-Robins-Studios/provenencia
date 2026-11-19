# S15-44 — The printed page can be marked unknown or supplied

**Status:** Landed in [#905](https://github.com/Jake-Robins-Studios/provenencia/pull/905) (2026-11-19)
**Spike / slice:** Spike 15 · Slice 4 — Formats as data
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: Go only. No view sets or shows the page's mark yet; S15-45 adds the composer's control, gated by S15-D24)
**Board:** —
**Depends on:** S15-14 (landed [#868](https://github.com/Jake-Robins-Studios/provenencia/pull/868)); builds on S15-13 (landed [#863](https://github.com/Jake-Robins-Studios/provenencia/pull/863)), S15-37 (landed [#879](https://github.com/Jake-Robins-Studios/provenencia/pull/879)) and S15-43 (landed [#900](https://github.com/Jake-Robins-Studios/provenencia/pull/900))
**Blocks:** S15-16, S15-45
**Branch:** `s15-44-page-marks`
**Version bump:** minor, 0.25.1 → **0.26.0** (if `main`'s `VERSION` is no longer 0.25.1 when you rebase, the next minor after it): a backward-compatible feature, the locator accepts two new keys and a page selector that holds only `page_unknown`, as S15-13 bumped minor for the label-only selector ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** — (no skill covers `core/locator`; the PR adds no table, migration, FFI method or copy)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests; "Fuzz targets": `core/locator` parses `locator_json` the app may not have written)
**Context:** working rule "A value can be marked unknown or supplied" ([`../deployment-plan.md`](../deployment-plan.md#working-rules)); [`../evidence-explained-citation-map.md`](../evidence-explained-citation-map.md) § 6.10 "Unknown and supplied"; [`docs/interpretation-layer-data-model.md`](../../../interpretation-layer-data-model.md) § 3.2 (`page` selector); the precedent plans [`S15-13-composer-printed-page.md`](S15-13-composer-printed-page.md) (the label-only selector, `PageRef`) and [`S15-43-source-date-marks.md`](S15-43-source-date-marks.md) (a mark checked with `valuemark.Validate`)
**Planned:** 2026-11-19 against `main` @ `5a8e505` (compare with `origin/main` after `git fetch origin main`; a local `main` may be stale)
**Review:** [`S15-44-page-marks.review.md`](S15-44-page-marks.review.md) — Fits with changes / Ready with changes, 2 rounds; every finding answered; nothing open

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

**US-1.** As the engine, when a Citation is written with a locator whose page selector carries a mark, I accept a pair `valuemark.Validate` accepts and refuse the rest, so that every locator the app writes holds a valid pair.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | `locator.Validate` on `{"version":1,"selectors":[{"type":"page","page_unknown":true}]}` (an image whose original prints no page) | nil |
| AC-1.2 | `locator.Validate` on a page selector `{"type":"page","artifact_page":37,"page_unknown":true}` | nil |
| AC-1.3 | `locator.Validate` on `{"type":"page","page_label":"23","page_supplied":true}` and on `{"type":"page","artifact_page":37,"page_label":"23","page_supplied":true}` | nil |
| AC-1.4 | `locator.Validate` on `{"type":"page","page_label":"23","page_unknown":true}` (an unknown page has no label) | `valuemark.ErrInvalid` (code `valuemark.invalid`) |
| AC-1.5 | `locator.Validate` on `{"type":"page","artifact_page":37,"page_supplied":true}` and on `{"type":"page","artifact_page":37,"page_label":"  ","page_supplied":true}` (supplied needs a label) | `valuemark.ErrInvalid`. On `{"type":"page","page_supplied":true}` (no file page, no label): `locator.ErrInvalid`, because the selector holds nothing (D-3 step 2 runs in `parse`, before the mark check) |
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
| AC-2.4 | `locator.Page` on stored pairs `Validate` refuses (a crafted catalog, or a stray key a client wrote without `Validate`): `{"type":"page","page_label":"23","page_unknown":true}`; `{"type":"page","page_label":"23","page_unknown":true,"page_supplied":true}`; `{"type":"page","page_unknown":true,"page_supplied":true}`; `{"type":"page","artifact_page":4,"page_supplied":true}` | Settled, never refused (D-6): `{Label: "23"}` (zero `Mark`); `{Label: "23", Mark: {Supplied: true}}`; `{Mark: {Unknown: true}}`; `{ArtifactPage: 4}` (zero `Mark`) |

**US-3.** As the engine, a depiction's region keeps working beside a marked page.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `ValidateDepictionRegion` with region `doc(page("1"), tri)` and a Citation locator `{"type":"page","artifact_page":1,"page_unknown":true}` | nil (the file pages agree; the mark is not compared) |
| AC-3.2 | `ValidateDepictionRegion` with region `doc(tri)` and a Citation locator `doc(art, {"type":"page","page_unknown":true})` | nil (the Citation has no file page, the region names none) |
| AC-3.3 | `ValidateDepictionRegion` with region `doc(page("1"), tri)` and the same unknown-only Citation locator | `locator.ErrInvalid` (the region names a file page the Citation lacks) |
| AC-3.4 | `ValidateDepictionRegion` with a region whose page selector is `{"type":"page","artifact_page":1,"page_label":"3","page_unknown":true}` and a Citation locator `doc(page("1"))`; and with region `doc(page("1"), tri)` and the Citation locator `{"type":"page","artifact_page":1,"page_label":"3","page_unknown":true}` | nil both times: the region check reads documents through `parse`, which does not check the pair (D-5, D-6) |

## 3. Scope

| In | Covered by |
| --- | --- |
| `selectorRaw` decodes `page_unknown` and `page_supplied` as JSON bools | STEP-1, AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, AC-1.7, AC-1.8 |
| `validatePage` accepts a selector that holds only `page_unknown`; `Validate` checks the pair with `valuemark.Validate` against the printed page | STEP-1, AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, AC-1.7, AC-1.8, AC-1.9 |
| `PageRef.Mark` *(new)*; `citationPage` returns a `PageRef` with the settled mark; `locator.Page` returns it | STEP-2, AC-2.1, AC-2.2, AC-2.3, AC-2.4, AC-3.1, AC-3.2, AC-3.3, AC-3.4 |
| `FuzzValidate` *(new)* over the locator parser (`.cursor/rules/go-tests.mdc` "Fuzz targets") | STEP-2, T-5 |
| The write path accepts and refuses through `locator.Validate`, unchanged code | STEP-3, AC-1.10 |
| Package and type doc comments, `interpretation-layer-data-model.md` § 3.2 | STEP-2, STEP-4 |

| Out | Home |
| --- | --- |
| Printing "unpaginated" and "[23]" from the mark | S15-16 (the resolver reads `PageRef.Mark`) |
| The composer's Unknown and Supplied control, and keeping the two keys on a Swift save (`CitationLocatorDraft` drops unmodeled page keys and a page selector with neither file page nor label) | S15-45 (S15-13's Out row already sends the unmodeled keys there) |
| The page's mark on the wire (`Observation`, a `ValueMark` on any citation message) | S15-16, if its render reply needs it; not planned otherwise |
| The mark in `graphfill`'s `citationWords` and today's citation line | Not planned: rule "Today's line stays the fallback" keeps the line as it is |
| A mark on the file page (`artifact_page`) | Not planned: the mark is about the printed page only (D-1) |
| Checking or refusing a mark on a depiction's region document | Not planned: D-5 |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Selector decode | `core/locator/validate.go` `selectorRaw` | Page keys `ArtifactPage *int` (`artifact_page`) and `PageLabel *string` (`page_label`); unknown keys are ignored by `json.Unmarshal`, so a `page_unknown` key today decodes and is dropped |
| Page rule | `core/locator/validate.go` `validatePage` | A selector with `artifact_page` ≥ 1 is valid whatever its label; without it, a non-blank `page_label` is required. `{"type":"page"}` → `ErrInvalid`. Knows no mark |
| Selector loop | `core/locator/validate.go` `validateDoc`, `parse`, `Validate` | `validateDoc` counts page selectors (at most one) and calls `validatePage` for each, in Citation locators and region documents alike. `parse` (decode + `validateDoc`) is the one read rule: `Page`, `ValidateDepictionRegion` and `regionDocPages` call it. `Validate` is `parse` with the result dropped; `citations` calls it on every write |
| Package doc | `core/locator/validate.go` package comment | "A page selector holds artifact_page …, page_label …, or both." |
| Page read | `core/locator/depiction.go` `PageRef`, `Page`, `citationPage` | `PageRef{ArtifactPage int; Label string}`; its doc says "The zero value is no page selector" and `ArtifactPage`'s says "0 when the selector holds only a printed page"; `Page` parses and returns the zero value for an invalid document; `citationPage(doc) (page int, label string, ok bool)` reads the one selector and drops a page above `math.MaxInt32` |
| Region check | `core/locator/depiction.go` `ValidateDepictionRegion` | Calls `citationPage` for the Citation's file page only: `page, _, ok := citationPage(citation)`. Its doc says the Citation's page selector "may hold only a page_label". Runs on write (`core/database/observations/depiction.go`) and on read (`core/depictionvalue/depictionvalue.go` `Readable`) |
| `PageRef` caller | `core/database/graphfill/load.go` (inside the observations scan, `locator.Page(citationLocator.String)`) | Copies `ref.ArtifactPage` and `ref.Label` into `citationWords`. Reads fields by name, so a new field compiles unchanged |
| Write path | `core/database/citations/citations.go` `normalizeCreateInput`, `Update` | Both return `locator.Validate`'s error unchanged |
| The mark type | `core/valuemark/valuemark.go` `Mark`, `Validate(m, hasValue)`, `Settle(m, hasValue)`, `ErrInvalid` (`valuemark.invalid`) | `Validate` refuses both facts, unknown with a value, supplied without one. `Settle` is the read rule (S15-53): it clears `Unknown` when there is a value and `Supplied` when there is none, and its result always passes `Validate`. The map's S15-53 entry names "S15-44's page read" as its next caller |
| Copy | `macos/App/Platform/L10n.swift` `L10n.Errors.valueMarkInvalid` | Maps `valuemark.invalid` to "A value can’t be both unknown and supplied; an unknown value has no text, and a supplied one needs text." (S15-37) |
| Fuzz | `core/locator` | No fuzz target and no testdata folder (`rg "func Fuzz" core/locator` is empty). The precedent is `core/citationformat/fuzz_test.go` `FuzzParse` (S15-14) |
| Tests | `core/locator/validate_test.go` `TestValidate` (`wantErr bool`, checked with `errors.Is(err, ErrInvalid)`), `TestPage`; `core/locator/depiction_test.go` `TestValidateDepictionRegion`; `core/database/citations/citations_test.go` `TestCitations` case "a printed page alone is a valid locator, two page selectors are not" | Table tests over JSON strings; `TestPage` compares `PageRef{ArtifactPage, Label}` |
| Domain doc | `docs/interpretation-layer-data-model.md` § 3.2 | `PageSelector` schema without marks; "Its `page` selector holds `page_label` alone" (images); "one with neither is invalid"; "An unnumbered page simply omits `page_label`." |

**Precedent.** `5630412` ("Accept a printed page alone in a citation's page selector.", S15-13, [#863](https://github.com/Jake-Robins-Studios/provenencia/pull/863)) changed `validatePage`, `PageRef` and the § 3.2 text in the same shape: copy its test rows (a JSON string per case in `TestValidate`, a `PageRef` per case in `TestPage`, the `TestCitations` create-then-update case) and its doc edit. S15-43 ([#900](https://github.com/Jake-Robins-Studios/provenencia/pull/900)) `core/database/sources/sources.go` `SetDate` calls `valuemark.Validate(mark, date != nil)` and returns its error bare, and `sources.settleDate` calls `valuemark.Settle` on read: copy both shapes. (`sourcemetadata.normalizeFor` adds `WithParams(id)` because a write holds many values; a locator holds one page, so the bare error is enough.)

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | The mark is about the printed page: `hasValue` for `valuemark.Validate` is `sel.PageLabel != nil && strings.TrimSpace(*sel.PageLabel) != ""`. `artifact_page` does not count as a value | The file page is where the Citation is in the file, always known when present; the printed page is what the original says (§ 3.2). The rule's "unknown has no text" is about the label. A blank label counts as none, as `validatePage` and the composer already treat it | Counting `artifact_page` as a value — an image page with a file page could never be unknown, and a supplied mark could sit on a file page with no label to bracket |
| D-2 | `selectorRaw` gains `PageUnknown bool \`json:"page_unknown"\`` and `PageSupplied bool \`json:"page_supplied"\``. Absent, `null` and `false` all read false. A non-bool value fails `json.Unmarshal`, so the document is `locator.ErrInvalid` | The map names the keys (rule "A value can be marked unknown or supplied", Storage). Plain `bool`: there is no difference to keep between absent and false; S15-45 writes each key only when true | `*bool` — a third state nobody reads |
| D-3 | Two checks, split between read and write. `validatePage` (in `parse`, so on read and write): (1) `artifact_page` present and below 1 → `locator.ErrInvalid` (today's first check); (2) the selector must hold a file page, a non-blank label, or `page_unknown` → else `locator.ErrInvalid`. `Validate` (write only): after `parse`, it finds the page selector with `pageSelector(doc)` *(new)* and runs `valuemark.Validate(sel.pageMark())`, returning its error bare (`valuemark.invalid`). One finder `pageSelector(doc document) (selectorRaw, bool)` *(new)* returns the one page selector of a parsed document; `Validate` and `citationPage` both use it. One method `selectorRaw.pageMark() (mark valuemark.Mark, hasLabel bool)` *(new)* computes the mark and D-1's `hasLabel`; `validatePage`, `Validate` and `citationPage` all call it | Writes refuse and reads settle, the split S15-53 made for metadata and S15-43 for the date. A refused pair carries the same code as the Source date and metadata values, and its copy already says what is wrong (§ 4 Copy). Step 2 widens S15-13's "file page or label" by one case: an image whose original prints no number is `{"type":"page","page_unknown":true}`. One `pageMark` keeps the write's and the read's "has a label" from drifting | The pair check inside `validatePage` — `parse` would refuse a stored pair, so a stray key on a locator that reads today (`{"artifact_page":1,"page_label":"3","page_unknown":true}`) would lose its page in `graphfill` and its depictions in `depictionvalue.Readable` (review M-2 "Outside my lens"); wrapping the pair error as `locator.ErrInvalid` — a second code for one rule |
| D-4 | `PageRef` gains `Mark valuemark.Mark` *(new field)*. `citationPage(doc document) (PageRef, bool)` *(changed)* builds the whole `PageRef` (trimmed label, the settled mark of D-6); a page above `math.MaxInt32` still returns `(PageRef{}, false)`. `Page` returns what `citationPage` returns. `ValidateDepictionRegion` reads `ref.ArtifactPage` from it | S15-13 D-4 shaped `PageRef` for this field. One reader builds the value, so a third field does not widen a tuple again | Keeping the tuple and adding a fourth return — the widening S15-13 review M-5 removed |
| D-5 | A region document's page selector goes through the same `validatePage` (through `parse`); its mark is never pair-checked (`ValidateDepictionRegion` reads through `parse`, not `Validate`), and `regionDocPages` keeps reading only `artifact_page`. A mark on a region document is ignored, as its `page_label` is (AC-3.4) | One structural page rule for every document, as S15-13 D-2 kept the selector count in one place. No writer puts a mark on a region document | Pair-checking region documents — a case no writer reaches |
| D-6 | `citationPage` settles the stored mark: `Mark: valuemark.Settle(mark, label != "")`, with the trimmed label (AC-2.4) | The map's S15-53 entry names this read as `Settle`'s next caller; a crafted catalog can hold any pair, and S15-16 prints from `PageRef.Mark`, so it must never see "unpaginated" beside a label | Refusing the stored pair in `parse` — D-3 Rejected; reading the raw pair — the resolver would print a refused pair |
| D-7 | `graphfill` is unchanged. The mark does not go on the wire in this PR. The map's S15-44 entry was reworded at planning to say so | The map row is Go-only; the resolver (S15-16) calls `locator.Page` itself; today's line stays as it is (rule "Today's line stays the fallback") | Carrying the mark in `citationWords` — a field nothing reads |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `selectorRaw.PageUnknown`, `selectorRaw.PageSupplied` *(new fields)* | field | `selectorRaw.PageLabel` | Extends the existing struct; the keys sit beside `page_label` in the same selector |
| `PageRef.Mark` *(new field)* | field | `valuemark.Mark` (searched `rg "valuemark.Mark" core`) | Reuses the one mark type, as `sourcemetadata.Row.Mark` and `sources.Source.DateMark` do |
| `selectorRaw.pageMark` *(new method)* | func | `validatePage`'s blank-label test, `citationPage`'s trim | One place computes the mark and "has a label" for the write check and the read settle |
| `pageSelector` *(new func)* | func | `core/locator/depiction.go` `citationPage`'s loop | Moved out of `citationPage` so the write check and the read settle find the selector in one place (review M-7) |
| `core/locator/fuzz_test.go` `FuzzValidate` *(new)* | test | `core/citationformat/fuzz_test.go` `FuzzParse` | Same shape over a different parser |

No new type or package. `citationPage` changes its return; `Validate` gains the pair check.

**Builds on.** `core/valuemark` (`Validate`, `Settle`), S15-13's `PageRef` and single page-selector rule, S15-43's call shape.
**Deletes.** `citationPage`'s `(page int, label string, ok bool)` return, replaced by `(PageRef, bool)` (D-4); its only callers are `Page` and `ValidateDepictionRegion`, both in `core/locator/depiction.go`. The § 3.2 sentence "An unnumbered page simply omits `page_label`."
**Next adds.** S15-16's resolver reads `locator.Page(json).Mark` with `Label` to print "unpaginated" (unknown) or "[23]" (supplied). S15-45 writes `page_unknown` / `page_supplied` from `CitationLocatorDraft` through S15-41's control, and decodes them so a save keeps them.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A stored page selector with neither file page nor label (`{"type":"page","page_unknown":true}`) | `macos/App/Features/CitationComposer/CitationLocatorDraft.swift` `decode` / `encodeJSON` | Not reachable from this PR: nothing writes the key until S15-45. When it is: `decode` leaves `page` nil and `pageLabel` "", and `encodeJSON` drops the selector, so a Swift save would erase the mark. S15-45 models the keys (Out) |
| The same selector, or a stored pair `Validate` refuses, in `graphfill` | `core/database/graphfill/load.go` | `Page` returns `ArtifactPage` 0 and `Label` "" for the unknown-only selector: the observation reads as a Citation with no page, as an artifact-only locator does today. A refused stored pair reads its page and label as today (D-6) |
| A Citation with an unknown-only page and a depiction | `core/locator/depiction.go` `ValidateDepictionRegion` | `ArtifactPage` 0 → "no file page"; AC-3.2 and AC-3.3 pin both outcomes |
| An older app opening a project whose locator holds `page_unknown` with no label or file page | The older app's `locator.Validate` / `Page` | It refuses the selector (`{"type":"page"}` with no known key): `Page` reads no page, and re-saving that Citation in the older app fails `locator.invalid`. Not reachable before S15-45 writes the key; the minor bump names the release that understands it |

### Scale

None — `validatePage` adds two bool checks per page selector, at most one per document; `Page` returns one more field. No query, list or loop changes.

### Edges

- **Assumptions.** `validateDoc` assumes a page selector has something in it; D-3 step 2 keeps that true with `page_unknown` as the third "something". `ValidateDepictionRegion` assumes `ArtifactPage` 0 means no file page; an unknown-only selector keeps that (AC-3.2, AC-3.3). `TestPage` rows assume `PageRef` compares with `!=`; `valuemark.Mark` is two bools, so `PageRef` stays comparable. A caller that tests `ref == PageRef{}` for "no page" is now wrong for an unknown-only selector; no caller does (`rg "PageRef\{\}" core` finds only `depiction.go`'s own returns), and the `PageRef` doc says so (§ 6 Go core). S15-16 relies on "`Page`'s mark always passes `valuemark.Validate` against its label": T-5 holds it for every input.
- **Neighbors.** Label "  " with supplied → refused (blank is no value, AC-1.5); label "  " with unknown and a file page → valid (`{"type":"page","artifact_page":37,"page_label":"  ","page_unknown":true}`, T-1 row); label "  " with unknown and no file page → valid (the unknown is the content); supplied alone → `locator.ErrInvalid` (nothing in the selector, AC-1.5); `page_unknown: false` alone → refused as `{"type":"page"}` is (AC-1.7). File page 0 with unknown → `locator.ErrInvalid`, not `valuemark.invalid` (AC-1.9).
- **Removed inputs.** None — the mark and its label are in one document; nothing deletes one under the other. A stored pair that disagrees reads settled (D-6).
- **Real data.** None — no table or seed drives the rule. No writer has put a mark key in a locator, so every stored document reads with the zero `Mark` (AC-2.3). A crafted catalog can hold any pair; it reads settled and never loses its page or depictions (AC-2.4, AC-3.4).
- **Untrusted size.** None new — the document is capped by `MaxDocumentBytes` before decode; two bools add no dimension.

### Schema

None — the locator is JSON in `citations.locator_json`; no migration.

### Go core

| Package | Change |
| --- | --- |
| `core/locator` `validate.go` | `selectorRaw`: `PageUnknown bool \`json:"page_unknown"\``, `PageSupplied bool \`json:"page_supplied"\`` *(new fields)* after `PageLabel`. `func (sel selectorRaw) pageMark() (valuemark.Mark, bool)` *(new)*. `func pageSelector(doc document) (selectorRaw, bool)` *(new)*: the first selector whose trimmed type is `TypePage` (a parsed document holds at most one). `validatePage`: D-3's two checks. `Validate`: `doc, err := parse(locatorJSON)`; on error return it; then, when `sel, ok := pageSelector(doc)` is ok, `return valuemark.Validate(sel.pageMark())`. `Validate`'s doc comment: "Validate is the write check: it checks locator JSON against version-1 invariants for known selector types, and refuses a page mark pair valuemark.Validate refuses (valuemark.ErrInvalid). Reads go through parse, which does not check the pair." Package comment: a page selector holds `artifact_page`, `page_label`, or both, or is marked `page_unknown`; it may mark the printed page `page_unknown` or `page_supplied`; `Validate` refuses a pair `valuemark.Validate` refuses, and `Page` settles a stored one |
| `core/locator` `depiction.go` | `PageRef.Mark valuemark.Mark` *(new field)*, doc comment "Mark is the printed page's unknown and supplied facts, settled against Label (valuemark.Settle)." `PageRef` doc gains: "A selector marked unknown alone gives no file page and no label, with Mark.Unknown set; only the zero value means no page selector." `ArtifactPage` doc: "0 when the selector holds no file page." `ValidateDepictionRegion` doc: "Both documents must pass Validate." becomes "Both documents must parse (Validate without its page mark check)."; the clause "which may hold only a page_label" becomes "which may hold no file page (only a page_label, or page_unknown)". `citationPage(doc document) (PageRef, bool)` *(changed)* builds its `PageRef` from `pageSelector`, D-6. `Page` returns its result. `ValidateDepictionRegion`: `ref, ok := citationPage(citation)`; `hasPage := ok && ref.ArtifactPage > 0`; compares `ref.ArtifactPage` |

Sketch:

```go
func (sel selectorRaw) pageMark() (valuemark.Mark, bool) {
	hasLabel := sel.PageLabel != nil && strings.TrimSpace(*sel.PageLabel) != ""
	return valuemark.Mark{Unknown: sel.PageUnknown, Supplied: sel.PageSupplied}, hasLabel
}

func validatePage(sel selectorRaw) error { // read and write
	if sel.ArtifactPage != nil && *sel.ArtifactPage < 1 {
		return ErrInvalid
	}
	mark, hasLabel := sel.pageMark()
	if sel.ArtifactPage == nil && !hasLabel && !mark.Unknown {
		return ErrInvalid
	}
	return nil
}

func pageSelector(doc document) (selectorRaw, bool) {
	for _, sel := range doc.Selectors {
		if strings.TrimSpace(sel.Type) == TypePage {
			return sel, true
		}
	}
	return selectorRaw{}, false
}

func Validate(locatorJSON string) error { // the write check
	doc, err := parse(locatorJSON)
	if err != nil {
		return err
	}
	if sel, ok := pageSelector(doc); ok {
		return valuemark.Validate(sel.pageMark())
	}
	return nil
}
```

In `citationPage`, the selector comes from `pageSelector` and the mark is `valuemark.Settle(mark, hasLabel)` from `sel.pageMark()`; `hasLabel` is true exactly when the trimmed label is non-empty, so it agrees with `Label != ""`.

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

**STEP-2 — `locator.Page` returns the settled mark; the parser is fuzzed**
Files: `core/locator/depiction.go`, `core/locator/validate_test.go` (`TestPage`), `core/locator/depiction_test.go`, `core/locator/fuzz_test.go` *(new)*.
Do: D-4. Change `TestPage`'s table to a `want PageRef` column, keep every row's values, add T-2's rows. Add T-3's rows to `TestValidateDepictionRegion`, with a local variable `unknown`, declared beside the test's `label` variable and built the same way, holding the selector `{"type":"page","page_unknown":true}`. Write T-5 and run it: `cd core/locator && CGO_ENABLED=1 go test -tags fts5 -run '^$' -fuzz FuzzValidate -fuzztime 5m .`; commit any crasher under `core/locator/testdata/fuzz/FuzzValidate/` *(new)* after fixing it.
Check: the 5-minute fuzz run finds no crasher; `CGO_ENABLED=1 go test -tags fts5 ./core/locator/... ./core/database/graphfill/... ./core/database/observations/...` passes; `go vet -tags fts5 ./api/... ./core/...` is clean.

**STEP-3 — The Citation write accepts and refuses the mark**
Files: `core/database/citations/citations_test.go`.
Do: add T-4 as a new case of `TestCitations`, beside "a printed page alone is a valid locator, two page selectors are not". No non-test code changes in `citations`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/citations/...` passes.

**STEP-4 — Docs and version**
Files: `docs/interpretation-layer-data-model.md` § 3.2; `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj`; this plan; `../deployment-plan.md`; `../completed.md`.
Do: in § 3.2, add `page_unknown?: boolean` and `page_supplied?: boolean` to `PageSelector`; after "Its `page` selector holds `page_label` alone, and `artifact_page` is omitted." add "When the original prints no page number, it holds `page_unknown` alone."; replace "A page selector holds `artifact_page`, a non-blank `page_label`, or both; one with neither is invalid" with "A page selector holds `artifact_page`, a non-blank `page_label`, or both, or is marked `page_unknown`; one with none of these is invalid" (the rest of that sentence, ", as is `artifact_page` below 1.", stays); replace "An unnumbered page simply omits `page_label`." with "A page whose original prints no number omits `page_label` and is marked `page_unknown`; a printed page the researcher took from elsewhere is marked `page_supplied`. The two never appear together, an unknown page has no `page_label`, and a supplied one has a non-blank one (`core/valuemark`). A citation prints an unknown page as "unpaginated" and a supplied one in square brackets." The next sentence, which starts "The composer writes `page_label`", stays. After the first JSON block of § 3.2 (`"artifact_page": 37, "page_label": "23"`), add the lead-in "A file page whose original prints no number:" and a JSON block `{"type": "page", "artifact_page": 37, "page_unknown": true}`. The version bump per the header. The DoD lines for this plan (Status → Landed in #N), the map row (Plan column links this plan as `prs/S15-44-page-marks.md`, Status `Landed #N`, as S15-19's row reads) and `completed.md` (one paragraph at the top, as S15-43's).
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-44-page-marks.md` reports no errors; `scripts/check-pr.sh` prints `check-pr: PASS` (on Linux its Xcode and Swift-warning steps cannot run: run the Go part there, `gofmt -l core api` empty, `go vet -tags fts5 ./api/... ./core/...` and `CGO_ENABLED=1 go test -tags fts5 ./api/... ./core/...` passing, and leave the full script to the Mac or CI, saying so in the report).

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period ("Let a citation's printed page be marked unknown or supplied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/locator/validate_test.go` `TestValidate` | New rows: unknown-only selector → nil; file page + unknown → nil; label + supplied, with and without a file page → nil; file page + blank label + unknown → nil; label + unknown → `valuemark.ErrInvalid`; supplied alone, file page + supplied, file page + blank label + supplied → `valuemark.ErrInvalid`; both facts, with and without a file page → `valuemark.ErrInvalid`; `page_unknown:false` alone, `page_supplied:false` alone → `ErrInvalid`; `"page_unknown":"yes"`, `"page_supplied":1` → `ErrInvalid`; file page 0 + unknown → `ErrInvalid`; existing rows unchanged | AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, AC-1.7, AC-1.8, AC-1.9, D-1, D-2, D-3 |
| T-2 | Go | `core/locator/validate_test.go` `TestPage` | Unknown-only → `PageRef{Mark: {Unknown: true}}`; artifact + file page 37 + " 23 " + supplied → `{37, "23", {Supplied: true}}`; AC-2.4's four stored pairs → their settled `PageRef`s; `{"type":"page","artifact_page":3000000000,"page_unknown":true}` → `PageRef{}` (above `math.MaxInt32`, D-4); every existing row → its old `ArtifactPage` and `Label` with the zero `Mark` | AC-2.1, AC-2.2, AC-2.3, AC-2.4, D-4, D-6 |
| T-3 | Go | `core/locator/depiction_test.go` `TestValidateDepictionRegion` | Region on page 1, Citation page 1 + unknown → nil; region without page, Citation `art` + unknown-only → nil; region on page 1, Citation `art` + unknown-only → `ErrInvalid`; AC-3.4's two cases → nil | AC-3.1, AC-3.2, AC-3.3, AC-3.4, D-5 |
| T-5 | Go | `core/locator/fuzz_test.go` `FuzzValidate` *(new)* | Seeds (`f.Add`): AC-1.1, AC-1.3, AC-1.4, AC-1.6 and AC-2.4's documents, `{"version":1,"selectors":[{"type":"page","artifact_page":3000000000,"page_unknown":true}]}`, `{"version":1,"selectors":[{"type":"artifact"}]}` and `{`. For each input: no panic; `ref := Page(doc)` has `valuemark.Validate(ref.Mark, ref.Label != "") == nil`; when `Validate(doc) == nil` and `Page(doc) != PageRef{}`, the raw pair equals `Page(doc).Mark` (settling changed nothing on a written document). The raw pair is read in the test, which is in package `locator`: `d, _ := decode(doc)`, `sel, _ := pageSelector(d)`, and `sel.pageMark()`; no test-side decoder. A file page above `math.MaxInt32` reads as the zero `PageRef` (D-4), which the `!= PageRef{}` guard excludes. 5-minute run, no crasher | D-3, D-6, `.cursor/rules/go-tests.mdc` |
| T-4 | Go | `core/database/citations/citations_test.go` `TestCitations` case "a printed page can be marked unknown, not unknown with a label" *(new)* | `createCitation` with the unknown-only locator → no error, `Citation.LocatorJSON` equals the input; `Update` with label + unknown → `errors.Is(err, valuemark.ErrInvalid)`; `Get` after → the create's locator | AC-1.10 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `core/locator` (the table column changes), `core/database/graphfill` (compiles against `PageRef`), `core/database/observations` (depiction checks).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none expected)
- [ ] Fuzz: `FuzzValidate` ran 5 minutes with no crasher (command and output in the report)
- [ ] Sweep: `rg "citationPage\(" core` shows only the `(PageRef, bool)` form; `rg -U "simply omits|hold only a\s+(//\s+)?page_label|holds only a\s+(//\s+)?printed page|must pass Validate|checked in .validatePage." docs core --glob '!**/S15-44-*'` has no hit; `scripts/check-guidance-names.py` passes (check-pr runs it)
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

## Landed

No difference from the plan.

## 13. PR

**Title:** S15-44 — The printed page can be marked unknown or supplied
**Body:** objective in one sentence; what shipped against US-1 – US-3; AC evidence; deviations from the plan; manual check (the locator test run); `Plan: docs/deployment-plan/spike-15/prs/S15-44-page-marks.md`.
