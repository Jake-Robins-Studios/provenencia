# S15-58 — The page built-in goes

**Status:** Planned
**Spike / slice:** Spike 15 · Slice 11 — Metadata at any level
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: no view's layout or components change; the format editor's completion list is engine data and loses the `citation.page` row, as a deleted field would lose its row)
**Board:** —
**Depends on:** S15-56 (landed [#982](https://github.com/Jake-Robins-Studios/provenencia/pull/982))
**Blocks:** S15-59; S16-79's seed formats (D-8)
**Branch:** `s15-58-page-builtin-goes`
**Version bump:** minor, 0.44.0 (today's `VERSION`) → **0.45.0** (or the next minor after `main`'s `VERSION` when you rebase): the format language loses a placeholder and the wire reserves a field ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-seeded-vocabulary`](../../../../.agents/skills/add-seeded-vocabulary/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests)
**Context:** map scope entry S15-58 ([`../deployment-plan.md`](../deployment-plan.md)); working rules "The printed page is a metadata field", "A format reads a field from the nearest level that holds it", "Citation formats are data on the Source type", "Boards flag needed fields; the engine decides the rows", "The seed is the product default"; [`../evidence-explained-citation-map.md`](../evidence-explained-citation-map.md) §§ 1, 6.3, 6.8, 6.9, 6.10; [`docs/citation-formats.md`](../../../citation-formats.md); [`docs/source-layer-data-model.md`](../../../source-layer-data-model.md) § 5.2
**Planned:** 2026-11-26 against `main` @ `674de5a`
**Review:** [`S15-58-page-builtin-goes.review.md`](S15-58-page-builtin-goes.review.md) — Fits with changes / Ready with changes, two rounds; every finding Fixed or Declined; nothing open

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

A citation's printed page comes from one place: the seeded `page` field, read nearest-first like every other field. The `{citation.page}` built-in, which read the locator's `page_label`, goes from the format language, the seed's 17 page placeholders and the Source board's separate page requirement. A format that still names `{citation.page}` is a mistake the editor reports.

**Why now.** S15-56 made the printed page a Citation board row and stopped the composer writing `page_label`, so the built-in reads a key nothing writes any more. S15-59 then removes `page_label` from the locator; it needs no reader of it left.

**What stays.** The locator (S15-59), the other built-ins, the Source date's requirement, and every reader of the Citation's own Page value (S15-56). No view changes.

## 2. User stories

**US-1.** As a researcher, when a Citation cites a page, its citation prints the Page value nearest to it and nothing else, so one field holds the printed page.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Seeded census Source; Citation with own `page` "14" and locator `page_label` "14" | Full citation holds ", p. 14" (the census golden is unchanged) |
| AC-1.2 | Seeded census; Citation with locator `page_label` "23" and no `page` value at any level | Full citation holds no ", p." group |
| AC-1.3 | Seeded court report; no `page` value, `page_range` "41–58" | Full prints "41–58" where the page goes (the seed golden's `nopage` line is unchanged) |
| AC-1.4 | The 26 seeded types | No seeded format text contains `citation.page`; every seeded citation renders as before (`seed-citations.txt` unchanged) |

**US-2.** As a researcher editing a type's formats, I see `{citation.page}` reported as a mistake, so I write `{meta.page}` instead.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Parse `{citation.page}` as a full format | One diagnostic `unknown_builtin` at span 1–14 |
| AC-2.2 | Save full format `p. {citation.page}` on a type | Not saved; diagnostic full `unknown_builtin` 4–17 |
| AC-2.3 | A type whose stored full text is `p. {citation.page}` (written before this version) | The editor read returns the text as stored, with diagnostic full `unknown_builtin` 4–17 |
| AC-2.4 | The full form's completion list | Holds `{citation.image}` and `{citation.label}`, and no `{citation.page}`; the `page` field row stays |

**US-3.** As the engine, the Source board carries what the formats ask of the Source date only.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `GetSourceWorkspace` on a seeded census Source | `date_requirement` needed, not met; field 12 is reserved, so the reply has no page requirement |
| AC-3.2 | A type with full format `{source.date\|meta.page_range}.`, its Source with no date | `Board.Date` needed, unmet, one alternative `page_range`; after `page_range` is set on the Source, met elsewhere |

## 3. Scope

| In | Covered by |
| --- | --- |
| `{citation.page}` leaves the built-ins table and its target | STEP-1, AC-2.1, AC-2.4 |
| The seed's 17 `\|citation.page` options go | STEP-2, AC-1.1 – AC-1.4 |
| The renderer stops setting the built-in | STEP-4, AC-1.1, AC-1.2 |
| `Board.Page` and the page arm of `needsAt`'s built-in heads go | STEP-3, AC-3.2 |
| `page_requirement` reserved on the wire; the handler stops setting it | STEP-5, AC-3.1 |
| Swift's `CitationBuiltin.citationPage`, its name string and catalog key go | STEP-6, AC-2.4 |
| Tests that printed a page from a locator label read a `page` value | STEP-3, STEP-4 |
| Domain docs and the citation map | STEP-7 |

| Out | Home |
| --- | --- |
| The locator's `page_label`, `page_unknown`, `page_supplied`, `locator.PageRef.Label` and `.Mark` | S15-59 |
| Moving stored locator `page_label`s into `page` values | not planned (user, 2026-11-25: the product owner updates dogfood projects by hand) |
| Rewriting existing projects' stored formats | not planned (D-5) |
| Collapsing `levelNeeds.builtinHeads` to a date-only slice | not planned (D-4) |
| `FakeStore`'s `page_label` seed (`macos/App/Platform/FakeStore.swift`) | S15-59 |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Built-ins | `core/citationformat/builtins.go` `CitationPage`, `builtins` row `{LevelCitation, "page", UnknownText: "unpaginated"}` | The built-in this PR removes |
| Parse | `core/citationformat/parse.go` (`builtinRow` → `CodeUnknownBuiltin`) | Already reports any name not in `builtins`; needs no change |
| Completion list | `core/citationformat/placeholder.go` `BuiltinPlaceholders`; `core/database/citationrender/placeholders.go` `Placeholders` | Derived from `builtins`; needs no change |
| Seed | `core/database/sourcevocab/registry.go` | 17 placeholders read `{meta.page\|citation.page}`; court report's full reads `{meta.page\|citation.page\|meta.page_range}` |
| Render | `core/database/citationrender/load.go` `fillValues` | Sets `v.Builtins[citationformat.CitationPage]` from `s.page.Label` and `s.page.Mark`; `CitationImage` reads `s.page.ArtifactPage` and stays |
| Board | `core/database/sourcemetadata/annotation.go` `Board{Entries; Date, Page Annotation}`, `levelNeeds.builtinHeads`, `needsAt` | `needsAt` keeps chains headed by `SourceDate` or `CitationPage` at the Source level |
| Board build | `core/database/sourcemetadata/sourcemetadata.go` `buildBoards` (line 1102) | Sets `out[i].Page = annotate(ln, citationformat.CitationPage, …)` on the Source board |
| FFI | `api/proto/engine.proto` `GetSourceWorkspaceResponse.page_requirement = 12`; `api/ffi/handlers/sources.go` `GetSourceWorkspace` | Sets `out.PageRequirement = requirementProto(read[0].Page)`. No Swift reader (`rg PageRequirement macos` hits only `macos/App/Platform/Generated/engine.pb.swift`) |
| Swift mirror | `macos/App/Platform/CitationFormatVocabulary.swift` `CitationBuiltin.citationPage`; `macos/App/Platform/L10n.swift` `CitationFormats.nameCitationPage` and `builtinName`'s `.citationPage` arm; `macos/App/Resources/Localizable.xcstrings` `citationFormats.builtin.citationPage` | Mirrors the Go table; `api/ffi/swift_vocabulary_test.go` `TestSwiftVocabularyMatchesGo` holds the two equal |
| Preview | `macos/App/Features/SourceTypes/SourceTypePageView.swift` `#Preview("Source type page")` | Its fake full format reads `{citation.page}` |
| Tests | `core/citationformat/builtins_test.go` `TestBuiltins`, `TestBuiltinTargets`; `render_test.go` `censusFull`, `censusShort`, `censusValues` (declares `src, cit`), `TestRenderMarks` "unknown page" (declares `src, cit`); `parse_test.go` rows "unclosed group", "missing close before next placeholder"; `rewrite_test.go` `TestRewriteFields` | Name `citation.page`. The `rewrite_test.go` hit is a key string, not a placeholder, and stays |
| Tests | `core/database/sourcemetadata/annotation_test.go` `TestNeedsAt` ("a built-in head leaves its options used", "built-in heads only at the source level"), `TestCitationValuesResolve` ("a built-in that is not"), `TestAppendOptions`; `annotation_fuzz_test.go` `FuzzAnnotate`; `sourcemetadata_test.go` `TestSourceBoardBuiltins`, `TestListWorkspacesAnnotations` (line 3144), `TestSeedAnnotations` (line 3427) | Read `CitationPage` or `Board.Page` |
| Tests | `core/database/citationrender/render_test.go` `newCensus` (`pageLocator("14")`, compared by `TestRenderCensus`), `TestRenderNearestLevel`, `TestRenderUnknownAndSupplied`, `TestGroupKey`; `scale_test.go` `scaleValues`; `preview_test.go` `TestRenderPreview` (AC-7.2) | Print a page from a locator `page_label` through the built-in |
| Tests | `api/ffi/handlers/citation_render_test.go` `newRenderWorld` (`w.citation` with `pageLocatorJSON("14")`, compared with `renderCensusFull` by `TestRenderCitations`, `TestRenderCitationPreview` and `TestRenderSeededPage`), `TestRenderCitations` ("AC-1.2 equal pages group", "AC-1.6 unknown and supplied values"), `TestRenderSeededPage` ("AC-1.3 a Citation's page beats the locator's"); `sources_test.go` `TestGetSourceWorkspace` ("census asks the Source date and no built-in page", "a type with no formats asks nothing") | Same, and `GetPageRequirement` |
| Editor read | `core/database/sourcetypes/formats.go` `viewTx`; test `formats_test.go` `TestGetFormats` "stored text that does not parse comes back verbatim (AC-4.1)" | A stored text that does not parse comes back verbatim with its diagnostics; the precedent for AC-2.3 |

**Precedent.** S15-62 ([#950](https://github.com/Jake-Robins-Studios/provenencia/pull/950)) retired level-named placeholders: the parser started refusing them, the seed and tests were rewritten, and its Landed note records that stored formats were not migrated; the product owner rewrote the dogfood project's once by hand. Copy that handling (D-5). S15-60 ([#975](https://github.com/Jake-Robins-Studios/provenencia/pull/975)) wrote the 17 placeholders this PR edits and moved the built-in-head test onto a `newLedger` type; copy its seed-golden check.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | Remove the `page` row from `builtins` and the `CitationPage` target; the parser's existing `unknown_builtin` reports it | One table declares the built-ins; parse, completion and Swift parity derive from it | A dedicated "retired placeholder" diagnostic: a new code for one name the app has no users of |
| D-2 | In `registry.go`, every `{meta.page\|citation.page}` becomes `{meta.page}`, and court report's `{meta.page\|citation.page\|meta.page_range}` becomes `{meta.page\|meta.page_range}`. No other text changes | Map scope entry; the field answers first already, so renders with a `page` value are unchanged | — |
| D-3 | Tests that printed a page from a locator `page_label` set the Citation's own `page` value with the same text and mark instead; their locator JSON stays as written, and `pageLocator` (`core/database/citationrender/render_test.go`) and `pageLocatorJSON` (`api/ffi/handlers/citation_render_test.go`) each get a comment: the label no longer prints, S15-59 removes it | The locator keys are S15-59's; a test's printed text stays the same, so its expectation does not change | Removing the labels from the test locators here (S15-59's scope) |
| D-4 | `levelNeeds.builtinHeads` stays a map keyed by `citationformat.Target`; only the `CitationPage` comparison in `needsAt` goes, and its comment says its one key is `SourceDate`, the one built-in a board annotates | `annotate` takes any built-in head generically; the map has one key now, and the change stays one condition | A `dateHeads []Requirement` field: rewrites `annotate`, `fieldIDs` and their tests for no reader's gain |
| D-5 | No migration and no install-on-open rewrite of stored formats. A stored form that still names `{citation.page}` does not parse: it renders nothing and asks nothing of the boards until the researcher fixes it, and the editor shows it with `unknown_builtin` (AC-2.3). The PR description gives the product owner the two `replace` statements of §10 step 3 for the dogfood project; they rewrite the seeded forms, where `citation.page` is never a chain's head, and a researcher-written `{citation.page}` at a head or alone is fixed in the editor | Precedent S15-62 (user, 2026-11-22: one dogfood project, fixed by hand); `add-catalog-migration` forbids Go and seed backfills in migrations | A format step rewriting `source_types.citation_*`: S15-62 dropped the same one |
| D-6 | `GetSourceWorkspaceResponse` field 12 becomes `reserved 12; reserved "page_requirement";`, and its comment names the Source date alone | Proto practice in `engine.proto` (fields 6–8); no client reads it | Leaving it unset: a dead field the next reader would trust |
| D-7 | `TestSourceBoardBuiltins`' built-in-head case moves to the Source date: the `newLedger` type's full format is `{source.date\|meta.page_range}.` and it asserts `Board.Date` (AC-3.2) | Keeps the only built-in-head path tested once the page head is gone | Dropping the case: `annotate`'s built-in branch would lose its only chain test |

| D-8 | S16-79's planned voters-list formats read `{meta.page}`, edited in planning with both maps' notes; this PR changes nothing there | That plan is Blocked and unbuilt; a seed text with `citation.page` would no longer parse | Leaving it to S16-79's refresh: the plan would carry a format the parser refuses |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

None — the PR adds no file, type, function, key or helper; it only removes.

**Builds on.** The built-ins table (`core/citationformat/builtins.go`) and the Swift parity test (`TestSwiftVocabularyMatchesGo`); S15-62's retirement of a placeholder form.
**Deletes.** `citationformat.CitationPage` and its `builtins` row; the `CitationPage` comparison in `sourcemetadata.needsAt`; `sourcemetadata.Board.Page` and its assignment in `buildBoards`; the `CitationPage` line in `citationrender.fillValues`; `GetSourceWorkspaceResponse.page_requirement` and its assignment in `handlers.GetSourceWorkspace`; `CitationBuiltin.citationPage`, `L10n.CitationFormats.nameCitationPage`, its `builtinName` arm and the `citationFormats.builtin.citationPage` catalog entry; `TestRenderMarks`' "unknown page" row, and the then-unused `cit` in `TestRenderMarks` and `censusValues`. `locator.PageRef.Label` and `.Mark` lose their last reader outside `core/locator`; S15-59 deletes them.
**Next adds.** S15-59 deletes the locator's printed-page keys with no format or board left reading them, starting from the two test helpers D-3 marks. S16-79 seeds `{meta.page}` (D-8).

### Reach

None — no new path into existing code. A stored format naming `{citation.page}` already reaches the "does not parse" state every invalid stored text reaches (D-5).

### Scale

None — no write, list or loop changes. `TestRenderScale` keeps its SELECT counts: the added `page` row rides the `citation_metadata` read it already makes.

### Edges

- **Assumptions.** `annotate`'s built-in branch reads `ln.builtinHeads[head]`; with the page head gone, a call with any target other than `SourceDate` would return none, and no caller passes another (D-4, `buildBoards`). `citationformat.Missing` treats a built-in it has no value for as empty; nothing now sets or asks for the page built-in.
- **Neighbors.** A `page` value and a locator label: the value prints (AC-1.1). A locator label alone: no page prints (AC-1.2), a change only for Citations saved before S15-56 that the product owner has not retyped. A page marked unknown at any level: prints "unpaginated", the field's unknown text (S15-60 tests). Court report with no page: falls to `page_range` (AC-1.3).
- **Removed inputs.** A Citation's locator `page_unknown` and `page_supplied` stop reaching any citation: their marks print nowhere. Accepted, as AC-1.2.
- **Real data.** The whole shipped seed: `TestSeedCitations` renders all 26 types in three forms and with `-update` leaves `seed-citations.txt` unchanged (AC-1.4); `rg -c 'citation\.page' core/database/sourcevocab/registry.go` goes from 17 to 0.
- **Untrusted size.** None — no new read of data the app did not write.

### Schema

None — no catalog change (D-5).

### Go core

| Package | Change |
| --- | --- |
| `core/citationformat` | `builtins.go`: the `CitationPage` target and its row go (D-1) |
| `core/database/sourcevocab` | `registry.go`: D-2's text edit |
| `core/database/citationrender` | `load.go` `fillValues`: the `CitationPage` line goes |
| `core/database/sourcemetadata` | `annotation.go`: `Board` keeps `Entries` and `Date`; its comment says only a Source board carries the date's annotation. `needsAt` drops `\|\| t == citationformat.CitationPage`; the `levelNeeds`, `needsAt` and `Annotation` comments name the Source date alone (D-4). `sourcemetadata.go` `buildBoards`: the `Page` line goes |

Errors: none new; `citationformat.CodeUnknownBuiltin` covers `{citation.page}`.

### FFI

`api/proto/engine.proto` `GetSourceWorkspaceResponse`: field 12 reserved (D-6). Regenerate with `./scripts/generate-proto.sh`. `api/ffi/handlers/sources.go` `GetSourceWorkspace`: the `PageRequirement` line goes.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Built-in mirror | `CitationBuiltin` | `macos/App/Platform/CitationFormatVocabulary.swift` | `citationPage` case goes |
| Built-in name | `L10n.CitationFormats.builtinName` | `macos/App/Platform/L10n.swift` | `.citationPage` arm and `nameCitationPage` go |
| Preview | `#Preview("Source type page")` | `macos/App/Features/SourceTypes/SourceTypePageView.swift` | Fake full format reads `[, p. {meta.page}]` |

States: none change. Accessibility: none changes.

### Strings

Removed: `citationFormats.builtin.citationPage` ("Page") from `L10n.swift` and `Localizable.xcstrings`. No key is added.

## 7. Steps

**STEP-1 — The built-in goes**
Files: `core/citationformat/builtins.go`, `builtins_test.go`, `render_test.go`, `parse_test.go`.
Do: D-1. `TestBuiltins`' want table loses the page row, and its `LookupBuiltin(vocabkey.LevelCitation, "page")` check now expects not found. `TestBuiltinTargets` drops `CitationPage`. In `render_test.go`, `censusFull` and `censusShort` read `{meta.page}` and `censusValues` sets `meta("page"): text("14")` in place of `builtin(cit, "page")`; `TestRenderMarks` loses "unknown page"; each of the two functions drops `cit` from its `src, cit :=` line once unused. In `parse_test.go`, the two syntax rows use `{citation.label}` in place of `{citation.page}`, and T-1 is added.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/citationformat/...` passes.

**STEP-2 — The seed reads the field alone**
Files: `core/database/sourcevocab/registry.go`. Skill: `add-seeded-vocabulary`.
Do: D-2.
Check: `rg -c 'citation\.page' core/database/sourcevocab/registry.go` prints nothing; `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcevocab/...` passes; `CGO_ENABLED=1 go test -tags fts5 -run TestSeedCitations ./core/database/sourcevocab -update` leaves `git diff --exit-code core/database/sourcevocab/testdata` clean.

**STEP-3 — The Source board stops annotating a page**
Files: `core/database/sourcemetadata/annotation.go`, `sourcemetadata.go`, `annotation_test.go`, `annotation_fuzz_test.go`, `sourcemetadata_test.go`.
Do: the `sourcemetadata` row of §6 Go core. `TestNeedsAt`: "a built-in head leaves its options used" reads `{source.date|meta.<p>}` and its `page` column checks `builtinHeads[citationformat.SourceDate]` (rename the column `builtin`); "built-in heads only at the source level" reads `{source.date}`. `TestCitationValuesResolve` "a built-in that is not": target `citationformat.CitationImage`. `TestAppendOptions`: `CitationImage` in place of `CitationPage`. `FuzzAnnotate`: seed 1's third format `{citation.page|meta.<b>}` becomes `{source.date|meta.<b>}`, seed 2's first `{source.date}, {citation.page|meta.<a>|meta.<b>}` becomes `{source.date}, {meta.<a>|meta.<b>}`, and the call annotates `SourceDate`. `TestListWorkspacesAnnotations` and `TestSeedAnnotations`: their `Page` conditions and the page half of their messages go. `TestSourceBoardBuiltins`: drop each `.Page` assertion; the court report `page` entry asserts `len(Alternatives) == 1` and `Alternatives[0].Field.ID` equal to `pages.ID`, with its message "want suggested, needed, unmet, alternative page_range"; D-7, with the case's comment saying it holds the built-in-head path on the Source date.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcemetadata/...` passes; `CGO_ENABLED=1 go test -tags fts5 -run FuzzAnnotate -fuzz FuzzAnnotate -fuzztime 20s ./core/database/sourcemetadata` passes.

**STEP-4 — The renderer stops setting it**
Files: `core/database/citationrender/load.go`, `render_test.go`, `scale_test.go`, `preview_test.go`; `api/ffi/handlers/citation_render_test.go`.
Do: remove the `CitationPage` line in `fillValues`. Per D-3: `newCensus` sets `w.set(vocabkey.LevelCitation, cit, "page", "14", m)`; `scaleValues`' `citation_metadata` row adds `"page": "14"`; `TestRenderUnknownAndSupplied` sets `page` on `ca` marked unknown and on `cb` "23" marked supplied, and its format reads `{meta.page}`; `TestGroupKey`'s "Book of hours" format reads `{meta.page}` and each of its three Citations gets the `page` value of its `pageLocator` label; `TestRenderPreview` AC-7.2's format reads `{meta.page}`. Every other render test that fails because a locator label no longer prints gets the same treatment. In `api/ffi/handlers/citation_render_test.go`: `newRenderWorld` sets `page` "14" on `w.citation` with `setValues(t, dir, userID, ids, "citation", w.citation, …)`; "AC-1.2 equal pages group" sets `page` "14" on `same` and "15" on `other`; "AC-1.6": the format reads `{meta.page}` and the two Citations get the page marks through `SetMetadata` on a `citation` owner, as the test sets the publisher on the Source; "AC-1.3 a Citation's page beats the locator's" is renamed "AC-1.3 a Citation's own page answers" with its body unchanged. `TestRenderUnknownAndSupplied`: `ca` gets `page` marked unknown with no text, `cb` gets "23" marked supplied. T-3 is added.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/citationrender/...` passes, with `TestRenderScale` at its existing SELECT counts. The handler tests this step edits run in STEP-5's check, once `sources.go` compiles.

**STEP-5 — The wire reserves the field**
Files: `api/proto/engine.proto`, `api/proto/engine/engine.pb.go`, `macos/App/Platform/Generated/engine.pb.swift`, `api/ffi/handlers/sources.go`, `sources_test.go`. Skill: `add-ffi-handler`.
Do: D-6; `./scripts/generate-proto.sh` (on the Mac, where `protoc`, `protoc-gen-go` and `protoc-gen-swift` are installed; never hand-edit the generated files — without the tools, stop); remove the `PageRequirement` line. `TestGetSourceWorkspace`: "census asks the Source date and no built-in page" becomes "census asks the Source date" and loses its page check; "a type with no formats asks nothing" checks `GetDateRequirement()` alone.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/...` passes (the handler render tests of STEP-4 included); `rg -n 'PageRequirement|page_requirement' api core macos/App -g '!*.pb.*' -g '!engine.proto'` has no hit, and `rg -n page_requirement api/proto/engine.proto` hits only the `reserved` line.

**STEP-6 — Swift's mirror follows**
Files: `macos/App/Platform/CitationFormatVocabulary.swift`, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `macos/App/Features/SourceTypes/SourceTypePageView.swift`. Skill: `add-localized-string`.
Do: the §6 macOS table and §6 Strings.
Check: on the Mac, `CGO_ENABLED=1 go test -tags fts5 -run TestSwiftVocabularyMatchesGo ./api/ffi/` passes; `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS'` passes with no Swift warning.

**STEP-7 — Docs**
Files: `docs/citation-formats.md`, `docs/source-layer-data-model.md`, `docs/interpretation-layer-data-model.md`, `docs/deployment-plan/spike-15/evidence-explained-citation-map.md`, `deployment-plan.md`, `completed.md`, this plan.
Do: `citation-formats.md`: the `citation.page` row of the built-ins table goes; "The Citation level's built-ins are `citation.image` and `citation.label`"; "What each built-in reads" loses its `citation.page` clause. `source-layer-data-model.md` § 5.2: "A Source's board also carries what the formats ask of the Source date." `docs/interpretation-layer-data-model.md` § 3.2: "A citation prints an unknown page as \"unpaginated\" and a supplied one in square brackets." becomes "No citation reads these marks; a citation prints the Page field's marks." Citation map: § 1's Citation row drops the clause "; a locator's `page_label` answers until S15-58"; § 6.3's built-ins table loses the `{citation.page}` row; each `{meta.page|citation.page}` in §§ 6.8's format listings becomes `{meta.page}` and court report's becomes `{meta.page|meta.page_range}`; § 6.9 loses the sentence "Until S15-58 the seed reads `{meta.page|citation.page}`, so a locator's printed page answers when no level holds a value."; § 6.10's "Built-ins" paragraph reads "`{source.date}` is flagged in the Source page header where the date sits. Labels and titles always have a value." `deployment-plan.md`: rule "Citation formats are data on the Source type" loses "; `{citation.page}` until S15-58".
Check: `rg -n 'citation\.page' docs --glob '!docs/deployment-plan/spike-15/prs/**' --glob '!docs/deployment-plan/spike-15/design/archive/**' --glob '!*.review.md'` hits only history that stays: `completed.md` (the S15-60 paragraph) and in `deployment-plan.md` the rule "The printed page is a metadata field", the S15-58 and S15-60 rows, the S15-60, S15-56 and S15-58 scope entries and the "S15-58 — S16-79" dependency line; and `docs/deployment-plan/spike-16/deployment-plan.md`'s S16-79 row; `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-58-page-builtin-goes.md` passes.

**STEP-8 — Version and status**
Files: `VERSION`, `core/version.go`, every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`, `completed.md`, `deployment-plan.md` (map row), this plan.
Do: the header's bump; the DoD's status, map row and `completed.md` lines.
Check: `rg -n 'MARKETING_VERSION' macos/Provenencia.xcodeproj/project.pbxproj` shows the new version on every line; `scripts/check-pr.sh` prints `check-pr: PASS` (on the Mac).

Commits: STEP-1 – STEP-5 are one commit, "Retire the {citation.page} placeholder; citations print the Page field alone.", because the tree does not build between them; STEP-6, STEP-7 and STEP-8 one commit each. Otherwise one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/citationformat/parse_test.go` `TestParse` row "a retired page built-in" *(new)* | `{citation.page}`, full → `unknown_builtin` 1–14 | AC-2.1, D-1 |
| T-2 | Go | `core/citationformat/builtins_test.go` `TestBuiltins` | Want table without the page row; `LookupBuiltin(LevelCitation, "page")` not found | AC-2.4, D-1 |
| T-3 | Go | `core/database/citationrender/render_test.go` `TestRenderLocatorLabelAlone` *(new)* | Seeded census; Citation with `pageLocator("23")`, no `page` value → full holds no ", p." | AC-1.2 |
| T-4 | Go | `core/database/citationrender/render_test.go` `TestRenderCensus`; `api/ffi/handlers/citation_render_test.go` `TestRenderCitations` | Citation `page` "14" → `censusFull`, `censusShort` unchanged | AC-1.1, D-3 |
| T-5 | Go | `core/database/sourcevocab/render_test.go` `TestSeedCitations` | `-update` leaves `seed-citations.txt` unchanged, court report's `nopage` line included | AC-1.3, AC-1.4, D-2 |
| T-6 | Go | `core/database/sourcetypes/formats_test.go` `TestGetFormats` subtest "a stored citation.page reads with its mistake" *(new)* | `setRaw` full `p. {citation.page}` → `GetFormats` returns it verbatim with full `unknown_builtin` 4–17; `update` with the same text saves nothing (`res.Revision == 0`), same diagnostic | AC-2.2, AC-2.3, D-5 |
| T-7 | Go | `core/database/sourcemetadata/sourcemetadata_test.go` `TestSourceBoardBuiltins` | `newLedger` full `{source.date\|meta.page_range}.` → `Board.Date` needed, unmet, one alternative `page_range`; set `page_range` → met elsewhere | AC-3.2, D-7 |
| T-8 | Go | `api/ffi/handlers/sources_test.go` `TestGetSourceWorkspace` "census asks the Source date" | `date_requirement` needed, not met | AC-3.1, D-6 |
| T-9 | Go | `api/ffi/swift_vocabulary_test.go` `TestSwiftVocabularyMatchesGo` | Swift `CitationBuiltin` equals Go `Builtins()` without `citation.page` | AC-2.4 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `TestRenderScale` (SELECT counts), `TestSeedCitations` (golden), `TestNeedsAt`, `FuzzAnnotate`'s seed corpus.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it). Names: `citationformat.CitationPage`, `citation.page`, `Board.Page`, `page_requirement`, `PageRequirement`, `CitationBuiltin.citationPage`, `nameCitationPage`
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — or none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated) — none: no brief
- [ ] Domain doc updated if a rule in docs/*.md changed: docs/citation-formats.md, docs/source-layer-data-model.md § 5.2, docs/interpretation-layer-data-model.md § 3.2, the citation map §§ 1, 6.3, 6.8, 6.9, 6.10 (STEP-7)
- [ ] PR description: what shipped, AC evidence, deviations, manual check, and §10 step 3's statements for the product owner
```

## 10. Manual check

1. Open a project created with this build. On the seeded Newspaper type's page, open the full format: it holds `[, p. {meta.page}]` and shows no mistake. In the placeholder completion, the Citation group lists Image and Label, and the field list holds Page.
2. Type `{citation.page}` into the full format: the editor flags it as an unknown built-in and Save is refused (AC-2.2).
3. For the product owner, on a copy of the dogfood project, with `sqlite3`: `UPDATE source_types SET citation_full = replace(citation_full, '|citation.page|', '|'), citation_short = replace(citation_short, '|citation.page|', '|'), citation_list = replace(citation_list, '|citation.page|', '|');` then the same with `'|citation.page}'` → `'}'`. Open it with this build: each seeded type's formats open with no mistake, and a newspaper Citation with Page 2 still cites "p. 2" (AC-1.1).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A test expectation silently drops a page and is "fixed" by editing the expected text | D-3: expectations keep their text; the Citation gets the `page` value |
| An existing project's formats stop rendering | D-5, §10 step 3; the editor names the mistake |

**Stop and report if:**

- A seeded format text holds `citation.page` anywhere other than the 17 placeholders D-2 names, counted on `main` at rebase.
- `seed-citations.txt` changes after STEP-2.
- `TestRenderScale`'s SELECT counts change.
- A Swift file outside `Platform/Generated/` reads `pageRequirement` or `CitationBuiltin.citationPage` beyond the three §6 macOS rows.
- A test outside §4's rows needs more than D-3's substitution, or deleting a `Board.Page` assertion, to pass.

## 12. Open questions

None.

## 13. PR

**Title:** S15-58 — The page built-in goes
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check, with §10 step 3's statements; `Plan: docs/deployment-plan/spike-15/prs/S15-58-page-builtin-goes.md`.
