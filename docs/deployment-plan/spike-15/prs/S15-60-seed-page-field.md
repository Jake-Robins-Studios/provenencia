# S15-60 — The seed has a page field

**Status:** Landed in [#975](https://github.com/Jake-Robins-Studios/provenencia/pull/975) (2026-11-25)
**Spike / slice:** Spike 15 · Slice 11 — Metadata at any level
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: the new Page row is a seeded suggestion, drawn by the existing board row like every other text field)
**Board:** —
**Depends on:** S15-54 (landed [#965](https://github.com/Jake-Robins-Studios/provenencia/pull/965)), S15-62 (landed [#950](https://github.com/Jake-Robins-Studios/provenencia/pull/950))
**Blocks:** S15-56
**Branch:** `s15-60-seed-page-field`
**Version bump:** minor, 0.41.1 (today's `VERSION`) → **0.42.0** (or the next minor after `main`'s `VERSION` when you rebase): every new project gets a Page field that its citations read ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-seeded-vocabulary`](../../../../.agents/skills/add-seeded-vocabulary/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests)
**Context:** map scope entry S15-60 ([`../deployment-plan.md`](../deployment-plan.md)); working rules "A format reads a field from the nearest level that holds it", "The printed page is a metadata field", "A type suggests fields, not levels", "The seed is the product default", "Boards flag needed fields; the engine decides the rows"; dogfood bar 13; [`../evidence-explained-citation-map.md`](../evidence-explained-citation-map.md) §§ 6.8, 6.9; [`docs/seeded-vocabulary.md`](../../../seeded-vocabulary.md) §§ 2.2, 2.3
**Planned:** 2026-11-25 against `main` @ `d0d0049`
**Review:** [`S15-60-seed-page-field.review.md`](S15-60-seed-page-field.review.md) — Fits with changes / Ready with changes, one round; every finding Fixed, M-1 answered by the user; nothing open

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

A new project seeds a text field `page` ("Page", unknown text "unpaginated"), suggested by the 13 types whose formats print a page. Every seeded format reads the printed page as `{meta.page|citation.page}`, so the page answers from the nearest level that holds it (Citation, graph, Artifact, Source), and a Citation with no `page` value anywhere still prints the locator's printed page until S15-58. A researcher who files a clipping types the page once on its graph; a whole-issue PDF's Citations each carry their own.

**Why now.** S15-62 made `{meta.key}` read nearest-first and S15-54 made the Citation a level, so the page needs no chain helper (map re-scope, 2026-11-22, later). S15-56 puts the Citation's board in the composer and drops the Printed page input; it needs the seeded field to exist first.

**What stays.** Out and D-5 list it. The other page-relative fields (`column`, `line_number` and the rest) need nothing: nearest-wins already reads them from the Citation first.

## 2. User stories

**US-1.** As a researcher on a new project, when I type a page at the level that fits how I filed, the citation prints it.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A `newspaper_item` Source with `published_in` "Calder Valley Gazette" and date 14 June 1880; one Artifact and its graph; two Citations with no printed page in the locator, the first holding `page` 2 and `column` 4, the second `page` 7 and `column` 1, each on the Citation | Full citations `"newspaper_item," Calder Valley Gazette, 14 June 1880, p. 2, col. 4.` and `"newspaper_item," Calder Valley Gazette, 14 June 1880, p. 7, col. 1.`; different group keys |
| AC-1.2 | A second `newspaper_item` Source (a clipping) with the same `published_in` and date and one Artifact, whose graph holds `page` 3 and `column` 2; five Citations with no values and no printed page | All five full citations are `"newspaper_item," Calder Valley Gazette, 14 June 1880, p. 3, col. 2.`; one group key |
| AC-1.3 | The census world of `TestRenderCitations` (`line_number` 14 on the graph, printed page 14 in the locator); a new Citation on that graph holding `line_number` 21 and `page` 15 on the Citation, locator printed page 14 | Its full citation reads `p. 15` and `line 21`; `w.citation` still reads `p. 14` and `line 14` |
| AC-1.4 | A census Citation whose locator holds printed page 14 and no level holds `page` | Prints `p. 14` (the built-in answers): `renderCensusFull` unchanged |
| AC-1.5 | A third Citation on AC-1.1's graph whose own `page` is marked unknown, no other value, locator with no printed page | `"newspaper_item," Calder Valley Gazette, 14 June 1880, p. unpaginated.` (the field's unknown text) |

**US-2.** As a researcher on a new project, a type that prints a page offers Page on every board, where its formats first read it.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | The seed's suggestion lists | Each of the 13 types in D-3 suggests `page` at the position D-3 gives; the other 13 types do not suggest it |
| AC-2.2 | A `court_report` Source board, no values | The `page` entry is suggested, needed, not met elsewhere, with alternatives the `{citation.page}` built-in then `page_range`; once the Source's `page_range` is set, `page` is met elsewhere |
| AC-2.3 | Any seeded type's Source board | `Board.Page` is none: no seeded format heads a chain with `{citation.page}` |

## 3. Scope

| In | Covered by |
| --- | --- |
| Seeded field `page` (D-1) | STEP-1, AC-1.5 |
| Every seeded `{citation.page}` becomes `{meta.page|citation.page}` (D-2) | STEP-1, AC-1.1 – AC-1.4 |
| Suggestion lists gain `page` (D-3) | STEP-1, AC-2.1 |
| Seed and annotation tests follow the new seed (D-5, D-6) | STEP-2, STEP-3, AC-2.2, AC-2.3 |
| Bar 13 through handler tests (D-7) | STEP-4, AC-1.1 – AC-1.5 |
| Map §§ 6.8, 6.9 and `docs/seeded-vocabulary.md` §§ 2.2, 2.3 rewritten (D-8) | STEP-5 |

| Out | Home |
| --- | --- |
| The composer's Citation board; `graphfill` and `conclusiondetails` reading the Citation's own page; the `vocabkey` key for `page` | S15-56 |
| Retiring `{citation.page}`, `Board.Page`, `page_requirement` | S15-58 |
| The locator's `page_label` and its marks | S15-59 |
| Adding `page` to existing projects | not planned (the product owner updates the dogfood project by hand; rule "The seed is the product default") |
| Needed flags drawn on the boards | S15-39, S15-41 |
| Reconciling the map's § 6.8 format listings with the seed beyond the page placeholders | not planned (the seed registry is the source of truth) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Seed formats | `core/database/sourcevocab/registry.go` `certificateFormats`, `journalArticleFormats`, `seedTypes` | 17 `{citation.page}` placeholders over 13 types, one of them court report's `{citation.page\|meta.page_range}`; no format reads a `page` field |
| Seed fields | `core/database/sourcevocab/registry_fields.go` `seedFields` | 68 fields, no `page`; the head comment says "The 67 metadata fields" |
| Seed suggestions | `core/database/sourcevocab/registry_suggestions.go` `seedSuggestions` | One list per type, derived from the formats; no `page` |
| Registry tests | `core/database/sourcevocab/registry_test.go` `TestSeedSuggestionsFollowFormats` (census: 17 fields), `TestSeedFieldsAreRead` (unknown text only on `publication_place`, `publisher`) | Fail once `page` is seeded |
| Install test | `core/database/sourcevocab/sourcevocab_test.go` `TestInstall` "empty catalog gets the seed" | Asserts 68 fields |
| Render golden | `core/database/sourcevocab/render_test.go` `fieldValues`, `fixture.Resolve`, `TestSeedCitations`; `core/database/sourcevocab/testdata/seed-citations.txt` | The full fixture answers the built-in page "14"; `noPage` blanks only the built-in |
| Board annotations | `core/database/sourcemetadata/annotation.go` `needsAt` (`builtinHeads`), `annotate` | A chain's first option is its head and takes its need; `Board.Page` is filled only from chains headed by `{citation.page}` |
| Annotation tests | `core/database/sourcemetadata/sourcemetadata_test.go` `TestSourceBoardBuiltins`, `seedExpectations`, `TestSeedAnnotations` | Assert `Board.Page` used or needed on the 13 seeded types, from the seed |
| Workspace handler test | `api/ffi/handlers/sources_test.go` `TestGetSourceWorkspace` case "census asks the Source date and the page" | Asserts `page_requirement` used on a seeded census |
| Render handler tests | `api/ffi/handlers/citation_render_test.go` `newRenderWorld`, `setValues`, `newArtifact`, `newCitation`, `TestRenderCitations` | Census world with the page from the locator; `setValues` takes any level string, `"citation"` included |
| Render path | `core/database/citationrender/load.go` | Reads the Citation's values and every ancestor's in one batched read (S15-54, S15-55) and sets `citationformat.CitationPage` from the locator: no change needed |
| `page_requirement` readers | `api/ffi/handlers/sources.go` (`out.PageRequirement`) | Set; no Swift code reads it (`rg pageRequirement macos/App` hits only `macos/App/Platform/Generated/engine.pb.swift`) |

**Precedent.** S15-19 ([#897](https://github.com/Jake-Robins-Studios/provenencia/pull/897)) seeded the fields and formats; S15-63 ([#955](https://github.com/Jake-Robins-Studios/provenencia/pull/955)) made the suggestion lists derived. Copy their shape: edit the three registry files, let `TestSeedSuggestionsFollowFormats` check the lists, read the golden diff.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `seedFields` gains `{Key: "page", Label: "Page", DataType: metadatafields.DataTypeText, Description: "The printed page, as it should appear in a citation (23).", UnknownText: "unpaginated"}`, between `folio` and `column`. The head comment becomes: "The 69 metadata fields: the 64 of the Spike 15 map, section 6.8, `subdistrict`, and four place fields for the types whose place is not a jurisdiction: label and a description that says to enter the value as it should appear in a citation. Publisher and place of publication carry the unknown text \"n.p.\" and page carries \"unpaginated\"." | Rule "The printed page is a metadata field"; "unpaginated" is the built-in's unknown text today (`core/citationformat/builtins.go`), so an unknown page prints the same | — |
| D-2 | Each `{citation.page}` in `registry.go` becomes `{meta.page\|citation.page}`; court report's `{citation.page\|meta.page_range}` becomes `{meta.page\|citation.page\|meta.page_range}`. No other format text changes | The field answers first, nearest-first; the built-in keeps a Citation's locator page answering until S15-58 drops the last option (map scope entry) | `{citation.page\|meta.page}`: the locator would win over a board value |
| D-3 | `seedSuggestions` gains `page` where the formats first read it: census after `folio`; the three certificates after `volume`; `church_register` after `volume`; `record_book` after `book`; `passenger_list` first; `book` after `publisher`; `journal_article`, `broadcast` and `statute` last; `newspaper_item` after `publication_place`; `court_report` after `published_in` | Rule "A type suggests fields, not levels": the list is derived from the formats in first-read order (measured by running `TestSeedSuggestionsFollowFormats` against D-2) | — |
| D-4 | No `vocabkey` constant for `page` in this PR | `vocabkey` names keys code reads by name (`core/vocabkey/vocabkey.go` package doc; `subjectvocab` `TestVocabKeysMatchSeed`); the first reader is S15-56's `graphfill` | Declaring it here with no reader |
| D-5 | `Board.Page`, `needsAt`'s `builtinHeads` and `page_requirement` stay unchanged. Their tests stop reading the seed for the built-in page: seeded assertions expect `Board.Page` none, and the built-in-head path is held on a test type whose full format is `{citation.page\|meta.page_range}.` (T-5) | S15-58 deletes them; no Swift reader, so none is a visible change; the code stays tested until it goes | Deleting them here (S15-58's scope) |
| D-6 | The render golden stays byte for byte: `fieldValues` answers `page` "14", the value the built-in answered; `fixture.Resolve`'s built-in `page` case goes (after D-2 no chain reaches it with the full fixture answering the field); `noPage` blanks the `page` field | The golden then proves no seeded citation reads differently; the handler tests (T-6) prove the field and the built-in fallback | A distinct fixture value: rewrites every page line and the census literals for no new evidence |
| D-7 | Bar 13's tests are one new test, `TestRenderSeededPage`, in `api/ffi/handlers/citation_render_test.go`, on a new project through RPCs, reusing `newRenderWorld`, `setValues`, `newArtifact`, `newCitation` and `renderCitations`; Citation values are set with `setValues` at level `"citation"`, the unknown mark with `SetMetadata`, an empty `ValueText` and `Mark: &engine.ValueMark{Unknown: true}` (run at planning); locators with no printed page are `likenessLocatorJSON` (`api/ffi/handlers/citations_test.go`, the same package); the clipping is its own Source, because a Source's Artifacts made by `newArtifact` share one graph (`graphLinking`) | The map's Check names handler tests; the helpers already build a seeded census world; the AC strings were rendered at planning with D-1 – D-3 applied | A `citationrender` test: does not run the seed through onboarding |
| D-8 | Every doc the seed change makes false is rewritten in this PR; STEP-5 lists them | The scope entry rewrites § 6.9 and `seeded-vocabulary.md`; the others state counts or rules this PR changes | Leaving § 6.8 or the counts: they would contradict the seed |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `page` seed row *(new)* | registry row | `seedFields` `folio`, `column` | Extends the registry; no new code |
| `TestRenderSeededPage` *(new)* | Go test | `TestRenderCitations` | A separate test keeps `newRenderWorld`'s census assertions as they are and holds bar 13 in one place; D-7 names the helpers it reuses |

**Builds on.** `sourcevocab`'s declarative registry and its derived-suggestion test; S15-62's nearest-first `{meta.key}`; S15-54's Citation level.
**Deletes.** None — the built-in and its requirement stay until S15-58 (D-5).
**Next adds.** S15-56 declares the `page` key in `vocabkey` and reads the Citation's own value in `graphfill`; S15-58 drops `|citation.page` from 17 placeholders (a mechanical edit of D-2's text) and deletes `Board.Page`, which T-5's test type then stops exercising.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A Page row on every board of the 13 types, on new projects | `sourcemetadata.ListWorkspaces` and the shared Swift board row | A suggested text field like any other; inherited values show as S15-64 shows them |
| A `page` value at the Citation level | `citationrender` (S15-54, S15-55 read it); set only through `SetMetadata` until S15-56 draws the composer board | Rendered nearest-first (T-6) |

### Scale

At the map's Scale (a render of 300 Citations reading their Citation values in one batched read): `page` is one more field in the same batched read; no query, write or cache changes. The seed installs one more field and 13 more suggestion rows at create.

### Edges

- **Assumptions.** `needsAt` gives a chain's need to its first option. With D-2 the `page` field heads every page chain, so on seeded types `Board.Page` is none and the `page` entry carries the need: needed only on court report (its chain is outside any group), used on the other 12 (T-4, T-5).
- **Neighbors.** A locator printed page with no `page` value anywhere: the built-in answers (AC-1.4). Both a `page` value and a locator page: the field answers (AC-1.3). A `page` marked unknown at a nearer level: prints "unpaginated" and stops the chain, so the locator's page is not read (AC-1.5; rule "A format reads a field from the nearest level that holds it"). Two Citations of one graph, one with its own page: their renders differ, so their group keys differ (AC-1.1). A `page` on a farther level (graph, Artifact, Source) beats a Citation's locator Printed page until S15-58, though the locator is the nearer level: accepted, with no test (user, 2026-11-25: one dogfood project, and no Page is typed on a board until S15-58 lands; take the simplest order).
- **Removed inputs.** A researcher deleting `page`: refused while a format names it (rule "A citation format is its own vocabulary": a field named in a format is in use; existing probe). A Citation, graph or Artifact deleted: its values go with it (S15-54's delete entries); the next nearest level answers.
- **Real data.** Run over the whole seed at planning: 17 placeholders in 13 types change; the derived lists are D-3's; `TestSeedCitations` with D-6's fixture rewrites nothing; `TestSeedAnnotations` gains `page` needed on court report's three boards (needed at the Source 30 → 31, below 52 → 54) and `Board.Page` none on all 26 types.
- **Untrusted size.** None — no new list read from data the app did not write.

### Schema

None — no catalog change; the seed writes rows into existing tables at create.

### Go core

| Package | Change |
| --- | --- |
| `core/database/sourcevocab` | `registry_fields.go` (D-1), `registry.go` (D-2), `registry_suggestions.go` (D-3) |

### FFI

None — no RPC or proto change.

### macOS

None — no Swift change; the board draws the new suggestion with its existing row.

### Strings

None — the field's label, description and unknown text are catalog data, not L10n.

## 7. Steps

**STEP-1 — Seed the field, the formats and the suggestions**
Files: `core/database/sourcevocab/registry_fields.go`, `registry.go`, `registry_suggestions.go`. Skill: `add-seeded-vocabulary`.
Do: D-1, D-2, D-3. `rg -c 'citation\.page' core/database/sourcevocab/registry.go` before and after: 17 both times, each now preceded by `meta.page|`.
Check: `CGO_ENABLED=1 go test -tags fts5 -run TestSeedSuggestionsFollowFormats ./core/database/sourcevocab` reports only the census count (fixed in STEP-2).

**STEP-2 — Seed tests**
Files: `core/database/sourcevocab/registry_test.go`, `sourcevocab_test.go`, `render_test.go`.
Do: T-1, T-2, T-3.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcevocab/...` passes; `go test -tags fts5 -run TestSeedCitations ./core/database/sourcevocab -update` leaves `git diff --exit-code core/database/sourcevocab/testdata` clean.

**STEP-3 — Annotation tests**
Files: `core/database/sourcemetadata/sourcemetadata_test.go`, `api/ffi/handlers/sources_test.go`.
Do: T-4, T-5, T-7.
Check: `CGO_ENABLED=1 go test -tags fts5 -run 'TestSourceBoardBuiltins|TestSeedAnnotations' ./core/database/sourcemetadata` and `-run TestGetSourceWorkspace ./api/ffi/handlers` pass.

**STEP-4 — Bar 13 through handler tests**
Files: `api/ffi/handlers/citation_render_test.go`.
Do: T-6.
Check: `CGO_ENABLED=1 go test -tags fts5 -run 'TestRenderSeededPage|TestRenderCitations' ./api/ffi/handlers` passes.

**STEP-5 — Docs**
Files: `docs/deployment-plan/spike-15/evidence-explained-citation-map.md`, `docs/seeded-vocabulary.md`, `docs/deployment-plan/spike-15/completed.md`, `docs/deployment-plan/spike-15/deployment-plan.md` (the S15-60 map row's status only), this plan (status).
Do:
- Map § 6.9: the "Decision (user, 2026-11-09): the item lives on the Evidence graph. The Citation composer gets no new fields." paragraph and the "The printed page stays on the Citation" paragraph go. In their place § 6.9 says: the item's fields are read nearest-first (rule "A format reads a field from the nearest level that holds it", user 2026-11-22), so a researcher sets each at the level that fits how they filed; the printed page is the seeded `page` field, set on each Citation of a whole-issue PDF (in the composer from S15-56), once on the graph or Artifact of a clipping, or on the Source when one Source is one item; until S15-58 the seed reads `{meta.page|citation.page}`, so a locator's printed page answers when no level holds a value. "Why the graph", "Why not the Artifact" and "Why not the Citation" become the reasons the graph is the usual home of the item's numbers, not a rule against other levels. Items 1–3 of "What follows" and the closing paragraph stay.
- Map § 6.8 Fields: after the "The item" row, the row `| The page | \`page\` (the printed page; unknown text "unpaginated") | Citation |` (columns Group, Keys, Usually entered on); "63 fields" becomes "64 fields"; `page` leaves the "Not seeded" list. § 6.8 Formats: each `{citation.page}` becomes as D-2.
- `seeded-vocabulary.md` § 1 "Implementation (Source seed today)": "68 fields" becomes "69 fields", and "The 68 are the map's 63" becomes "The 69 are the map's 64".
- Map § 6.10: the `unknown_text` sentence "Seeded on the fields that have a convention (\"n.p.\" for `publication_place` and `publisher`)" adds "and \"unpaginated\" for `page`".
- Map § 6.8 Fields: the column header "Usual level" becomes "Usually entered on", and "**Usual level** is where a type suggests the field: Source unless listed otherwise." becomes "**Usually entered on** is the level a researcher usually types the value on: Source unless listed otherwise." (a type suggests fields, not levels, since S15-63).
- `seeded-vocabulary.md` § 2.2: a row `citation  page` under the `graph` rows, aligned as they are; the sentence "`publisher` and `publication_place` carry the unknown text "n.p."; no other field does." becomes "`publisher` and `publication_place` carry the unknown text "n.p." and `page` carries "unpaginated"; no other field does." § 2.3: "the same 17 fields" becomes 18.
- Per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-60-seed-page-field.md` passes; `rg -n '\{citation\.page\}' docs/deployment-plan/spike-15/evidence-explained-citation-map.md` hits only § 6.3's built-ins table and § 6.10's "Built-ins" sentence (S15-58 owns both).

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/sourcevocab/registry_test.go` `TestSeedSuggestionsFollowFormats`, `TestSeedFieldsAreRead` | census list length 18 (creator first, citing last); the unknown-text check reads a `map[string]string` of expected texts (`publication_place` and `publisher` "n.p.", `page` "unpaginated"; every other field "") | AC-2.1, D-1, D-3 |
| T-2 | Go | `core/database/sourcevocab/sourcevocab_test.go` `TestInstall` | 26 types and 69 fields; message "the map says 26 and 69" | D-1 |
| T-3 | Go | `core/database/sourcevocab/render_test.go` `TestSeedCitations` | D-6: `fieldValues["page"] = "14"`; the built-in `page` case of `fixture.Resolve` deleted; `noPage` returns the zero Value for the field `page`; the `fixture` comment says the full fixture answers the page field, not the built-in → `core/database/sourcevocab/testdata/seed-citations.txt` unchanged, `court_report nopage full` still `41–58` | D-6 |
| T-4 | Go | `core/database/sourcemetadata/sourcemetadata_test.go` `TestSeedAnnotations` | `seedExpect.page` goes; every seeded type asserts `Board.Page.Need == ""`; court report `needed` becomes `published_in`, `page`; totals: needed 31, below 2×(31−4) = 54, unsuggested 29, dates 5; the `pages` count goes | AC-2.3 |
| T-5 | Go | same file, `TestSourceBoardBuiltins` | census: date needed and unmet, `Board.Page` none; court report: the `page` entry needed, not met elsewhere, alternatives `{Level: citation, Builtin: "page"}` then `page_range`, met elsewhere once the Source's `page_range` is "12-14"; `l := newLedger(t, c, userID)`, then `l.setFormats(t, c, userID, sourcetypes.Formats{Full: "{citation.page\|meta.page_range}."})`: `boardOf(t, c, sourceOwner(l.src.ID)).Page` is needed, unmet, one alternative `page_range`; after `runSet(c, userID, l.src.ID, Input{FieldID: pages.ID, ValueText: "12-14"})` it is met elsewhere. The census Artifact board and the `sourcetypesLedger` (`plain`) assertions stay as they are | AC-2.2, D-5 |
| T-6 | Go | `api/ffi/handlers/citation_render_test.go` `TestRenderSeededPage` *(new)* | One project: `w := newRenderWorld(t)`, `ids := fieldIDsByKey(t, w.dir)`. A local `newspaper := func() string` makes a Source with `seededSourceOfType(t, w.dir, w.userID, "newspaper_item")`, `SetSourceDate` `pointDate(1880, 6, 14)` and `setValues` `published_in`, and returns its id. One `t.Run` per AC, each making its own Source with `newspaper()` and `newArtifact`: AC-1.1 asserts both full plains literally and `GetGroupKey()` unequal; AC-1.2 makes five Citations in a loop, asserts each full plain literally and all group keys equal; AC-1.5 is a third Citation on AC-1.1's own Source made in that subtest; AC-1.3 uses `w` and asserts the new Citation's full plain equals `strings.NewReplacer("p. 14,", "p. 15,", "line 14,", "line 21,").Replace(renderCensusFull)` and `w.citation`'s equals `renderCensusFull`. AC-1.4 is `TestRenderCitations` AC-1.1, unchanged | AC-1.1 – AC-1.5 |
| T-7 | Go | `api/ffi/handlers/sources_test.go` `TestGetSourceWorkspace` | the census case is renamed "census asks the Source date and no built-in page" and asserts `page_requirement.need` `CITATION_NEED_UNSPECIFIED` | AC-2.3, D-5 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `core/database/sourcemetadata`, `core/database/citationrender`, `api/ffi/handlers` (tests over seeded types); at planning these were the only failures in `go test ./core/... ./api/...` with D-1 – D-3 applied.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — or none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated)
- [ ] Domain doc updated if a rule in docs/*.md changed: docs/seeded-vocabulary.md §§ 1, 2.2, 2.3; map §§ 6.8, 6.9, 6.10 (STEP-5); `rg -n '68 fields|map.s 63|The 67 metadata' docs core/database/sourcevocab` has no hit
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Create a new project. Add a Newspaper item Source with Published in "Calder Valley Gazette" and a date; add an Artifact. The Artifact sheet's board and the graph form's board offer Page after Place of publication and before Column.
2. On the graph form type Page 3 and Column 2; draw a Citation on the Artifact. The provenance sheet (or the Source page's citation of that Citation) reads "p. 3, col. 2".
3. Open the Metadata page: Page shows unknown text "unpaginated".

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A test outside §8 pins the seed's page chain | §8 names the suites that failed at planning; any other failure is a Stop condition |
| `-update` rewrites the golden | D-6's fixture keeps it byte for byte; a diff means the fixture or D-2 is wrong |

**Stop and report if:**

- `TestSeedSuggestionsFollowFormats` derives a list other than D-3's.
- `TestSeedCitations -update` changes `core/database/sourcevocab/testdata/seed-citations.txt`.
- A test outside §8 fails because of the seed change.
- A rendered string in AC-1.1 – AC-1.5 differs from the AC in anything but the page or column (the fixture's title or date is then not what the AC assumes; report the string).
- `citationrender` does not read a Citation-level value for a seeded Citation (S15-54 and S15-55 say it does).

## 12. Open questions

None.

## 13. PR

**Title:** S15-60 — The seed has a page field
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-60-seed-page-field.md`.

## Landed

- The version is 0.43.0 (`main` was already 0.42.0 when the branch was cut).
- Map § 6.8's "entries for the 63 fields" line also reads 64, with the Fields table; STEP-5 named only the table.
- T-5 checks the court report `page` entry through `entryOf` on the Source board (the field is now a suggested entry, not `Board.Page`).
- The manual check (section 10) was not run by the implementer.
- Docs fix round 1 also edited the citation map (levels table, status line, § 6.6, § 7, § 6.10), `deployment-plan.md` (seed rule, Scale) and `README.md` (field count), beyond STEP-5's map row only.
- `PVScrollMemoryHostedTests.anArrivalAheadOfItsLayoutDoesNotUseTheOldContent` (S16-72) is removed here: it failed in CI and the user asked for it (2026-11-25).
