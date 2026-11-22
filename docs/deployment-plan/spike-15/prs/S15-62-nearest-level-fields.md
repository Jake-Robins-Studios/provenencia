# S15-62 — A format reads a field from the nearest level

**Status:** Landed in [#950](https://github.com/Jake-Robins-Studios/provenencia/pull/950) (2026-11-22)
**Spike / slice:** Spike 15 · Slice 11 — Metadata at any level
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no brief, the map's writer's call that the user did not veto, 2026-11-22: the completion list keeps its rows and components, and a field row loses its level badge. Boards gain rows drawn by the existing board row, per D-10, the user's answer)
**Board:** —
**Depends on:** S15-61 (landed [#943](https://github.com/Jake-Robins-Studios/provenencia/pull/943))
**Blocks:** S15-63, S15-54, S15-60, S15-67
**Branch:** `s15-62-nearest-level-fields`
**Version bump:** minor, 0.33.1 → **0.34.0** (if `main`'s `VERSION` is no longer 0.33.1 when you rebase, the next minor after it): a change in how every citation reads its fields, with the migration that carries stored formats over; the bump is for the feature, per `docs/versioning.md` and the spike's earlier plans (S15-38, S15-17), not for the format step, which `add-catalog-migration` leaves out of `VERSION` ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-catalog-migration`](../../../../.agents/skills/add-catalog-migration/SKILL.md), [`add-seeded-vocabulary`](../../../../.agents/skills/add-seeded-vocabulary/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests)
**Context:** map scope entry S15-62 ([`../deployment-plan.md`](../deployment-plan.md)); working rules "A format reads a field from the nearest level that holds it", "A field means one thing", "A format's fields are needed or used", "Boards flag needed fields; the engine decides the rows", "Built-in placeholders are one table", "Formats name fields by id", "One engine, in Go", "The seed is the product default"; map review K-2, K-3, K-13 ([`../deployment-plan.review.md`](../deployment-plan.review.md)); [`docs/citation-formats.md`](../../../citation-formats.md); [`docs/source-layer-data-model.md`](../../../source-layer-data-model.md) § 5.4; map §§ 6.3, 6.6, 6.8 ([`../evidence-explained-citation-map.md`](../evidence-explained-citation-map.md))
**Planned:** 2026-11-22 against `main` @ `d48e777` (compare with `origin/main` after `git fetch origin main`)
**Review:** [`S15-62-nearest-level-fields.review.md`](S15-62-nearest-level-fields.review.md) — round 2: Fits with changes / Ready with changes; every finding Fixed, nothing open

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

A citation format names a metadata field without a level, `{meta.provider}`, and the engine reads it from the nearest level that holds a value: the Evidence graph, then the Artifact, then the Source. A researcher who typed Provider on the Source instead of the Artifact still gets a full citation. A level-named field (`{artifact.meta.provider}`) becomes a format mistake. Every stored format and the seed are rewritten to the new form, so nothing a researcher wrote stops rendering.

**Why now.** A field's level kept being wrong in dogfood, so the user re-cut slice 11 around nearest-wins (2026-11-22, rule "A format reads a field from the nearest level that holds it"). S15-63 (one suggestion list), S15-54 (Citation values), S15-60 and S15-64 build on it.

**What stays.** Built-ins keep their level (`{source.title}`, `{source.date:year}`, `{citation.page}`). The list form reads the Source alone. `{a|b}` chains stay, now between fields or built-ins. Suggestions keep their level until S15-63. The batch render reads the same owners as today. Swift never parses a format.

## 2. User stories

**US-1.** As a researcher, when a field sits at a different level than the format expected, my citation still prints it.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Census Source with Provider "Ancestry" on the Source, none on its Artifact; the census full format reads `[; {meta.format}, *{meta.provider}*]` and Format "digital image" is on the Artifact | The Citation renders "…; digital image, *Ancestry* …", the same text as with Provider on the Artifact |
| AC-1.2 | Line number "14" on the graph and "9" on the Source; `{meta.line_number}` in the full form | Renders "14" (graph is nearer) |
| AC-1.3 | Item on the Artifact and on the Source, none on the graph | Renders the Artifact's value |
| AC-1.4 | Line number on the graph marked unknown (field unknown text "n.l."), "9" on the Source | Renders "n.l."; the Source's "9" is not read |
| AC-1.5 | The list form `{meta.jurisdiction}`, jurisdiction only on the graph | The list form prints nothing for it; with a value on the Source it prints the Source's |

**US-2.** As a researcher writing a format, I write a field once and am told when I name a level.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Type `{meta.prov` in the format editor | Completion offers Provider once, as `{meta.provider}`, with no level badge; accepting writes `{meta.provider}` |
| AC-2.2 | Text `{artifact.meta.provider}` | Diagnostic `meta_at_level` over `artifact.meta.provider`; the warning reads "Write meta. with no level: a field is read from the nearest level that has it" |
| AC-2.3 | Text `{citation.meta.page}` | `meta_at_level` (no longer `meta_not_at_level`) |
| AC-2.4 | Text `{meta.provider}` in the list form | No diagnostic |
| AC-2.5 | Text `{meta.short_title\|source.title}` | Parses; a chain between a field and a built-in |
| AC-2.6 | The preview of a census full format with no jurisdiction anywhere | "Missing: Jurisdiction" (no "on the Source") |

**US-3.** As a researcher with a project from before this version, my own formats keep working.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Stored `{source.meta.#<A>}, [{graph.meta.#<B>\|source.meta.#<B>}][ {artifact.meta.#<C>}]` before the migration | After: `{meta.#<A>}, [{meta.#<B>\|meta.#<B>}][ {meta.#<C>}]`; it parses, and `{meta.#<B>\|meta.#<B>}` reads as `{meta.#<B>}` (one requirement with one target) |
| AC-3.2 | A dogfood project's edited format, values at their usual levels | Renders the same text after the migration |

**US-4.** As a researcher, a board says whether a needed field is met at this owner or above.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | Certificate type (needs `{meta.jurisdiction}`), jurisdiction on the Source; the Artifact's board | Entry Jurisdiction: needed, `MetElsewhere` true, no value |
| AC-4.2 | Same, the Source's own board, no jurisdiction on the Source but one on a graph | Needed, `MetElsewhere` false (a graph is below the Source) |
| AC-4.3 | Census type; the Source's board | Entries for the fields the formats read at other levels before (Line number, Provider, …) appear unsuggested and empty, as on every board (D-10) |
| AC-4.4 | `DismissSuggestion` of the needed Jurisdiction on a graph board | Refused, as on the Source board |

## 3. Scope

| In | Covered by |
| --- | --- |
| `vocabkey.NearestFirst()` *(new)* | STEP-1, T-1 |
| Parser: `{meta.key}`; `meta_at_level` replaces `unprefixed_meta` and `meta_not_at_level`; list-form field targets pinned to the Source; a chain keeps each target once | STEP-2, AC-2.2 – AC-2.5, AC-3.1, T-2 – T-4 |
| `citationformat.MetaFieldPlaceholder(key)` and the built-ins docs | STEP-2, T-5 |
| `CitationValues.Resolve` walks nearest-first; `CitationValues.Without` *(new)* | STEP-3, AC-1.1 – AC-1.5, T-6 |
| Board annotations per field: heads on every board, `MetElsewhere` at the owner or above, dismiss refused on every board | STEP-4, AC-4.1 – AC-4.4, T-7, T-8 |
| `citationrender.Placeholders`: each field once under `meta.` | STEP-5, AC-2.1, T-9 |
| Migration `000069.sql` rewrites stored formats | STEP-6, AC-3.1, AC-3.2 |
| Seed formats rewritten; seed tests derive fields without levels | STEP-2, T-11, T-12 |
| Test fixtures across Go packages rewritten to `{meta.key}` | STEP-2 – STEP-7 |
| Wire comments; Swift completion rows, missing line, diagnostic enum and copy | STEP-7, STEP-8, AC-2.1, AC-2.2, AC-2.6, T-13 – T-15 |
| Docs: `citation-formats.md`, `source-layer-data-model.md` § 5.4, map §§ 6.3, 6.6, 6.8, 6.9 | STEP-9 |

| Out | Home |
| --- | --- |
| The Citation level in `NearestFirst` and `Resolve` | S15-54 |
| Ancestors beyond the Source on a board (a Citation's graph and Artifact) | S15-55 |
| One suggestion list per type; `registry_suggestions.go` and `TestSeedSuggestionsFollowFormats` as one list | S15-63 |
| Showing the inherited value on a board row | S15-64 |
| Drawing needed flags, met elsewhere and alternatives in Swift | S15-39 |
| A list field set below the Source (`list_below`) | S15-66 |
| The seeded `page` field; retiring `{citation.page}` | S15-60, S15-58 |
| Collapsing `{meta.#X\|meta.#X}` in stored text (it reads as one option already, D-4) | not planned; a researcher's next save of the format keeps it, and it renders the same |
| Formats stored apart from types | S15-67 |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Level type | `core/vocabkey/vocabkey.go` `Level`, `MetadataLevels()`, `HoldsMetadata()` | `MetadataLevels()` is Source, Artifact, graph. No nearest-first order |
| Parser | `core/citationformat/parse.go` `(*parser).option` | `meta.` first → `unprefixed_meta`; `<level>.meta.<field>` → a field target at that level; Citation level → `meta_not_at_level`; list form with non-Source level → `not_in_list_form` |
| Targets | `core/citationformat/parse.go` `Target`, `Ref`, `node.chain`, `Template.refs` | A field target carries its level. A chain keeps every option as written |
| Diagnostic list | `core/citationformat/parse.go` `DiagnosticCodes()`; `core/citationformat/doc_test.go` `TestDocMatchesEngine` | Holds `unprefixed_meta`, `meta_not_at_level`; the doc test ties the list to `docs/citation-formats.md` |
| Placeholder rows | `core/citationformat/placeholder.go` `MetaPlaceholder(l, key)`, `MetaFieldPlaceholder(l, key)`, `metaRef` | Write `{<level>.meta.<key>}`. `MetaPlaceholder` has one caller, `placeholder_test.go` `TestMetaPlaceholder` |
| Requirements | `core/citationformat/requirements.go` `Requirements`, `collect`, `Missing` | One requirement per distinct target sequence; unchanged code, sees deduped chains after D-4 |
| Resolver | `core/database/sourcemetadata/annotation.go` `CitationValues.Resolve` | Reads `Rows[t.Level][id]` only |
| Board needs | `annotation.go` `needsAt`, `fieldAt`, `levelNeeds.fieldIDs`, `annotate`, `needOfTx` | Field heads only at the board's level; `MetElsewhere` looks only at a chain's later options |
| Board reads | `core/database/sourcemetadata/sourcemetadata.go` `listWorkspaces`, `ListDraftWorkspace`, `readTypeBoards`, `buildEntries` | Resolver rows: the owner's level and the Source. `buildEntries` emits every `needs.order` head |
| Render | `core/database/citationrender/load.go` `fillValues` | Fills Source, Artifact and graph rows per Citation; unchanged |
| Preview | `core/database/citationrender/preview.go` `RenderPreview` | Missing chains through `sourcemetadata.AppendOptions`; unchanged code |
| Completion rows | `core/database/citationrender/placeholders.go` `Placeholders` | Per metadata level, every field again at that level |
| Handler | `api/ffi/handlers/citation_render.go` `ListCitationPlaceholders`; `api/ffi/handlers/metadata.go` `citationOptionProto` | Send `level` as the target's level |
| Wire | `api/proto/engine.proto` `CitationPlaceholder`, `CitationRequirementOption` | `level` always a level |
| Seed | `core/database/sourcevocab/registry.go` `certificateFormats`, `journalArticleFormats`, `seedTypes` | 348 level-named field tokens; 15 distinct chains, 9 of the form `{graph.meta.K\|source.meta.K}` (one of them with `\|source.title`) |
| Seed tests | `core/database/sourcevocab/registry_test.go` `derivedSuggestions`, `usualLevel`, `TestSeedSuggestionsFollowFormats`; `render_test.go` `TestSeedCitations` (fixture answers every field at every level), `core/database/sourcevocab/testdata/seed-citations.txt` | `derivedSuggestions` takes a field's level from the format |
| Migrations | `core/database/migrations/` | Last is `000068.sql` |
| Field-in-use probe | `core/database/deleteimpact/formatrefs.go` `citationFormatEdge` | Matches the `#<id>` token as text; unaffected |
| Swift store | `macos/App/Platform/GoStore.swift` `citationPlaceholders`, the `missing` mapping in the preview | Drop any row or option whose `level` is not a `Level` |
| Swift types | `macos/App/Platform/GenealogyStore.swift` `CatalogCitationPlaceholder.level: Level`, `CatalogCitationOption.level: Level` | Non-optional |
| Swift vocabulary | `macos/App/Platform/CitationFormatVocabulary.swift` `CitationDiagnosticCode` (`unprefixedMeta`, `metaNotAtLevel`); `api/ffi/swift_vocabulary_test.go` | Parity with `DiagnosticCodes()` |
| Completion UI | `macos/App/Features/SourceTypes/SourceTypeFormatsModel.swift` `completionOptions`; `SourceTypeFormatsSection.swift` `SourceTypeFormatCompletionRow`, the `announce` closure | Level in the subtext, a `PVBadge` with the level, the level in the spoken label |
| Copy | `macos/App/Platform/L10n.swift` `L10n.CitationFormats.missing(_:)`, `diagUnprefixedMeta`, `diagMetaNotAtLevel`, `diagnosticMessage` switch; `Localizable.xcstrings` | "Jurisdiction on the Source" per option |
| Preview data | `macos/App/Features/SourceTypes/SourceTypePageView.swift` `#Preview` store (lines ~307–320) | Level-named formats and a `source#f1` row |
| Tests with level-named formats | `core/citationformat/{parse,render,requirements,rewrite,placeholder,fuzz}_test.go`; `core/database/sourcemetadata/{annotation,annotation_fuzz,sourcemetadata}_test.go`; `core/database/citationrender/{render,preview,placeholders}_test.go`; `core/database/sourcetypes/formats_test.go`; `core/database/sourcevocab/copy_test.go`; `core/database/metadatafields/metadatafields_test.go`; `api/ffi/handlers/{citation_render,metadata,source_defs}_test.go`; `macos/ProvenenciaTests/SourceTypeFormatsModelTests.swift`, `CitationFormatsCopyTests.swift` | Fixtures write `{<level>.meta.…}` |

**Precedent.** S15-17 ([#924](https://github.com/Jake-Robins-Studios/provenencia/pull/924)) added `ListCitationPlaceholders`, the completion rows and the missing line: copy its row and option mapping in `GoStore` and its `CitationFormatsCopyTests` shape. For a data rewrite in a migration, `000036.sql` (audit-scope backfill, untested by rule) is the shape: plain SQL, no Go, no migration test.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `func NearestFirst() []Level` in `core/vocabkey`: `l := MetadataLevels(); slices.Reverse(l); return l`. A new slice each call. No other list of the order | Rule: declared once, `MetadataLevels()` reversed (the rule's `slices.Reversed` names no stdlib function returning a slice; this is the same order) | A literal list — a second copy (K-13) |
| D-2 | A metadata option is `meta.<field>`. In `option`: when `first == "meta"`, parse the field (`bad_field` on an empty or bad token, span the field; `unknown_option` on a `:option`). When `first` is a valid level and `rest` is `meta` or starts with `meta.`, the diagnostic is `meta_at_level` (span: the option), at every level, Citation included. An invalid first part stays `unknown_level` | Rule: a level-named metadata placeholder is a parse diagnostic | Keeping `meta_not_at_level` for the Citation — `meta_at_level` already covers it, so the old code is dead |
| D-3 | `CodeMetaAtLevel = "meta_at_level"` *(new)* takes `unprefixed_meta`'s place in `DiagnosticCodes()`; `CodeUnprefixedMeta` and `CodeMetaNotAtLevel` are deleted. The doc table's order follows | One list, the doc test ties it to the doc | — |
| D-4 | A field target's `Level` is `""` (read nearest-first) in the full and short forms and `ListFormLevel` in the list form; the parser sets it. `const ListFormLevel = vocabkey.LevelSource` *(new)* in `builtins.go` is the one declaration of the list form's level, and `ListFormAllows(l)` becomes `l == ListFormLevel`. A placeholder's `node.chain` keeps each distinct `Target` once, at its first occurrence; `Template.refs` keeps every occurrence, so `Fields`, `FieldSpans` and `RewriteFields` still see every token | The list form reads the Source alone in every caller (a preview with a Citation target included) without a form on the `Resolver`; dedupe makes a migrated `{meta.#X\|meta.#X}` read as `{meta.#X}` (rule) | Passing the form to `Resolver.Resolve` — widens an interface three packages implement; collapsing duplicates in SQL — needs a recursive CTE over every field id |
| D-5 | `MetaFieldPlaceholder(key string) Placeholder` writes `{meta.<key>}`, `Level` empty. `MetaPlaceholder` and `metaRef`'s level go; `TestMetaPlaceholder` is renamed `TestMetaFieldPlaceholder` and tests `MetaFieldPlaceholder` (T-5) | One row shape for a field; the only `MetaPlaceholder` caller is its test | Keeping `MetaPlaceholder(key)` — a second name for `.Text` |
| D-6 | `CitationValues.Resolve`: a built-in as today; a field named by key → zero; a field target with a `Level` → that level's row only; with `Level == ""` → the row of the first level in `vocabkey.NearestFirst()` whose `Rows` hold the id. The first row found answers whatever its text: an unknown row stops the walk (AC-1.4). Package doc and the type's doc say "nothing else walks the levels" | Rule: one walker; unknown stops the search | Walking in `citationformat` — the rule keeps it a parser |
| D-7 | `func (v CitationValues) Without(l vocabkey.Level) CitationValues` *(new)*: a copy whose `Rows` lacks `l` and whose `Builtins` lack every target at level `l` (a new map), sharing `Fields`. It always means "the resolver without that level" | `MetElsewhere` needs "the head at a level above the owner"; S15-64's inherited value is the same call (rule) | A second resolver type — two walkers |
| D-8 | `fieldAt(t, level)` keeps its name and widens by one condition: a field target named by id is at `level` when `t.Level == "" \|\| t.Level == level`. So a nearest-first field heads (and is used) on every board, and a list-form field (`ListFormLevel`) only on the Source board. `needsAt`'s `level` keeps both jobs (field heads and `builtinHeads`). `readTypeBoards` keeps its (type, level) keying; `buildEntries`' emit loop over `needs.order` does not change | Requirements are per field (rule); the list form reads the Source, so a list-only need below the Source would be a refusal where rule "The list entry reads the Source; a board flags a list field set below it" says hint (S15-66) (review M-1) | A head at any level whatever its `Level` — a book's Artifact board would show `author_sort` needed and undismissable, though typing it there never meets the list form |
| D-9 | Each board's caller (`listWorkspaces`, `ListDraftWorkspace`) builds `above := r.Without(o.Level)` once per board and puts it on `boardInput` as `above citationformat.Resolver` *(new field)*; `ListDraftWorkspace`'s `r` holds the Source only, so its `above` is `r` itself (the draft owner has no rows). `annotate(ln, head, r, above, fields)` takes `above` in place of a level. The head `buildEntries` passes is `Target{Field: FieldRef{ID: id}}` with no `Level`, so `buildEntries` loses its `level` parameter and its two callers stop passing it; the Source board's `Date` and `Page` heads stay the built-in targets. A needed chain is met elsewhere when its own first option (`ch.Targets[0]`, not the passed head) answers in `above`, or its tail is non-empty and `citationformat.Missing` finds it met in `r`; a built-in first option is tested in `above` too, which holds no built-in at the owner's level (D-7), so the Source board's own Source date never meets its own chain. `MetElsewhere` is true when every needed chain it heads is. A board's `CitationValues` holds only the owner and its ancestors (today the Source) (review M-2, X-4) | Rule: "met elsewhere" is met at the owner or above; the head's own value at the owner is not "elsewhere"; one `above` per board is the slot S15-64's inherited value reads | Counting the owner's own value — `MetElsewhere` would be true on every valued entry; `Without` per chain — a map copy per entry |
| D-10 | Every board emits every nearest-first field head the type's formats read (suggested or not), annotated; a needed one also when dismissed; `needOfTx` (unchanged code, through D-8) refuses dismissing a field needed at that board's level. A list-form-only head shows and is refused only on the Source board. No suggestion code changes | User, 2026-11-22: "Every board" — S15-63's end state one PR early, with no code S15-63 would delete | Emitting only where the type suggests the field at some level — temporary code (user declined) |
| D-11 | `Placeholders(c, f)`: every built-in row of `BuiltinPlaceholders(f)` (level by level, as today), then every project field once as `MetaFieldPlaceholder(field.Key)` with its `Field`, in `metadatafields.List` order. Same field rows for every form | One row per field (scope) | Fields inside the Source band — mixes a level-less row into a level band |
| D-12 | Migration `000069.sql` *(new)*: for each of `citation_full`, `citation_short`, `citation_list` on `source_types`, `UPDATE … SET col = replace(…)` nesting six replaces: `{source.meta.` → `{meta.`, `\|source.meta.` → `\|meta.`, and the same for `artifact` and `graph`, `WHERE col IS NOT NULL`. No `-- migrate:` line. No audit row (migrations write none). No test of the migration (skill). This is not a seed backfill, which `add-catalog-migration` forbids: it rewrites the syntax of every stored format, researcher-written and edited ones included, which `Install` never refreshes and which would otherwise stop parsing (`meta_at_level`) and render nothing; the map's S15-62 scope (user, 2026-11-22) calls for it. It adds and changes no vocabulary row | Scope; SQL-only migrations | A Go rewrite at open — the skill forbids install-on-open and Go in migrations |
| D-13 | `registry.go`: every `{<level>.meta.K` and `\|<level>.meta.K` becomes `{meta.K` / `\|meta.K`, and each `{meta.K\|meta.K` becomes `{meta.K` (so `{graph.meta.item\|source.meta.item\|source.title}` → `{meta.item\|source.title}`). `registry_suggestions.go` does not change | Rule; S15-63 owns suggestions | — |
| D-14 | `registry_test.go`: `derivedSuggestions` returns the type's fields as one list, in the order its formats first read them (full, then the list and short forms' needed chains the full form does not already meet, as today), plus the copy fields for `recordTypes`; no level. `TestSeedSuggestionsFollowFormats` checks that each type's suggested fields over all levels, as a set, equal that list (each field suggested at one level only, as today). Levels stay in `registry_suggestions.go` alone. `usualLevel` is deleted if nothing else calls it. `TestSeededFormatsNeedOnlySuggestedFields` keys `suggested` by type and field (any level) | Formats no longer carry a level, so the test cannot derive one; a hand-kept level table beside `registry_suggestions.go` would be a second copy S15-63 deletes (review M-3) | Giving `usualLevel(key)` a type argument and a website exception — a second level table |
| D-15 | Wire: no field changes. `CitationPlaceholder.level` is `""` for a field row; `CitationRequirementOption.level` is `""` for a field read nearest-first and `"source"` for a list-form field. Comments in `engine.proto` say so; regenerate with `./scripts/generate-proto.sh` | Backward-compatible; `level` already a string | A new message — nothing new to carry |
| D-16 | Swift: `CatalogCitationPlaceholder.level: Level?` and `CatalogCitationOption.level: Level?`, nil for an empty wire level. `GoStore` keeps a field row (id `"meta#<field id>"` replacing today's `"\(p.level)#\(p.field.id)"`, level nil, `text` and `ref` as sent) and drops a row or option only when a non-empty level is unknown or a built-in is unknown | Field rows have no level | A sentinel `Level` case — not a level, and `Level` mirrors Go |
| D-17 | Completion: `completionOptions` subtext is `[row.level.map(L10n.CitationFormats.levelName), row.field?.key, row.ref]` compacted. `SourceTypeFormatCompletionRow` draws the level `PVBadge` only when `row.level` is non-nil. `static func spokenLabel(of row:) -> String` *(new)* beside `label(of:)` in `SourceTypeFormatsModel` returns `completionHighlighted(name:level:)` with a level and `label(of:)` without; the row's accessibility label and the `.highlighted` announcement both call it (review M-4) | Same list, one row per field (scope) | A new "Any level" badge — chrome the map did not plan |
| D-18 | Missing line: in `L10n.CitationFormats.missing(_:)`, an option whose `level` is nil prints its name alone, always (never `missingOptionSameName`); one with a level keeps `missingOption(name:level:)`, and `missingOptionSameName(level:)` when an earlier option with a level has its name. "Missing: Jurisdiction"; list form "Missing: Jurisdiction on the Source" | A field has no level to name, except in the list form where the Source is the truth | — |
| D-19 | Copy: `L10n.CitationFormats.diagMetaAtLevel` *(new)*, key `citationFormats.diagnostic.meta_at_level`, "Write meta. with no level: a field is read from the nearest level that has it". `diagUnprefixedMeta`, `diagMetaNotAtLevel` and their catalog keys go; `CitationDiagnosticCode.metaAtLevel = "meta_at_level"` replaces `unprefixedMeta` at its position, `metaNotAtLevel` goes | Every diagnostic has a message | — |

**Rules this plan bends.** None. Rule "Boards flag needed fields" says a head is emitted "even when not suggested"; with no level that is every board, which the user confirmed (D-10, 2026-11-22). Its wording is updated in STEP-9.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `vocabkey.NearestFirst` | func | `vocabkey.MetadataLevels` | Built from it (D-1) |
| `citationformat.CodeMetaAtLevel` | const | `CodeUnprefixedMeta`, `CodeMetaNotAtLevel` | Replaces both |
| `sourcemetadata.CitationValues.Without` | method | `CitationValues.Resolve` | Extends the one resolver (D-7) |
| `citationformat.ListFormLevel` | const | `ListFormAllows` | The one declaration both it and the parser read (review M-5) |
| `boardInput.above` | field | `boardInput.resolver` | The board's resolver without the owner's level, built once per board |
| `SourceTypeFormatsModel.spokenLabel(of:)` | func | `label(of:)` | One place for a row's spoken name (review M-4) |
| `000069.sql` | migration | `000036.sql` (data backfill) | Next number |
| `L10n.CitationFormats.diagMetaAtLevel` | key | `diagUnprefixedMeta` | Replaces it |
| `CitationDiagnosticCode.metaAtLevel` | enum case | `unprefixedMeta` | Replaces it |

**Builds on.** S15-38's one resolver (`CitationValues`) for render and boards; S15-61's level list (unchanged); S15-17's completion rows; the `swift_vocabulary_test` parity.
**Deletes.** `CodeUnprefixedMeta`, `CodeMetaNotAtLevel`; `MetaPlaceholder` and the level in `MetaFieldPlaceholder`/`metaRef`; the two built `completionHighlighted` calls in `SourceTypeFormatsSection.swift` (now `spokenLabel`); `usualLevel` in `registry_test.go` if unused; the Swift cases `unprefixedMeta`, `metaNotAtLevel`, `L10n.CitationFormats.diagUnprefixedMeta`, `diagMetaNotAtLevel` and their `Localizable.xcstrings` keys; `derivedSuggestions`' level output.
**Next adds.** S15-54 adds `LevelCitation` to `MetadataLevels()`, so `NearestFirst()` and `Resolve` read it first with no change here. S15-55 adds ancestors' rows to the board resolver; `Without` and D-9 hold as is. S15-64 calls `Resolve` on `Without(owner level)`. S15-63 merges suggestions; D-10 already shows every field on every board.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A board entry for a field the type suggests only at another level | `sourcemetadata.buildEntries` → Swift `MetadataBoardView` | Rows are the same `WorkspaceEntry` shape the head path already emits on the Source board; a field whose row did not load is skipped, as today |
| A completion row with no level | `SourceTypeFormatCompletionRow`, `completionOptions` | D-16, D-17; `PVComboBoxMatch.filter` takes any subtext |
| A missing option with no level | `L10n.CitationFormats.missing` | D-18 |

### Scale

At the map's Scale: the migration rewrites at most 3 columns per type (26 seeded types plus a researcher's), one statement per column, in one transaction. A render reads the same batched owners as today (`fillValues` unchanged); `Resolve` does at most `len(NearestFirst())` = 3 map lookups per field target (4 from S15-54). A board read is unchanged in queries; each board now annotates every head of its type (a census type: 23 fields), with no extra query: `buildEntries` reads `needs.order` and the rows already loaded. `TestListWorkspacesAnnotationsScale` has no time budget; it asserts the annotations of 121 boards (`sourcemetadata_test.go`), so its expected annotations are updated where D-8 – D-10 change them, and its query count does not change.

### Edges

- **Assumptions.** `Requirements` dedupes by target sequence: a full-form `[F]` and a list-form `[source:F]` are two requirements; on the Source board `needsAt` merges them by field id (strongest need); below it only the full-form one heads (D-8), T-7. `AppendOptions`' `seen` is keyed by `Target`, so the same field in both forms shows twice in a board's alternatives only when both are tails, once with no level and once at the Source, which is accurate. `Resolve` assumes a board's `Rows` hold only the owner and its ancestors (D-9).
- **Neighbors.** A value at the owner and above: the owner's wins (T-6). A row marked unknown at a nearer level answers (AC-1.4). A whitespace-only row a crafted catalog holds stops the walk and prints nothing; the chain falls to its next option, never a farther level (T-6, a case). A list-form `{meta.K}` ignores graph and Artifact rows (AC-1.5).
- **Removed inputs.** A field deleted while a format names it: refused today by the field-in-use probe, which matches `#<id>` and still finds `{meta.#<id>}` (T-10's case in `deleteimpact` stays green).
- **Real data.** The seed's 72 formats: after D-13 every one parses; `TestSeedCitations` renders all 26 types identically (the fixture answers every field at every level). No seeded format names one field at two levels outside a chain (measured, § 4).
- **Untrusted size.** The migration only shortens text. A stored text longer than `MaxFormatBytes` stays unparsed, as today. Dedupe keeps a chain no longer than written.
- **Literal text.** `replace()` also rewrites an escaped `\{source.meta.` or a literal `|source.meta.` in a format's plain text; no seeded or plausible format holds one. Not planned.

### Schema

Migration `core/database/migrations/000069.sql` *(new)*:

```sql
UPDATE source_types SET citation_full = replace(replace(replace(replace(replace(replace(citation_full,
  '{source.meta.', '{meta.'), '|source.meta.', '|meta.'),
  '{artifact.meta.', '{meta.'), '|artifact.meta.', '|meta.'),
  '{graph.meta.', '{meta.'), '|graph.meta.', '|meta.')
WHERE citation_full IS NOT NULL;
-- the same for citation_short and citation_list
```

No new table or FK; `catalogmodel` unchanged. Schema hash unchanged (data only).

### Go core

| Package | Change |
| --- | --- |
| `core/vocabkey` | `func NearestFirst() []Level` *(new)*; `Level` doc: "From S15-62 a format names fields with no level; the level stays for owners, built-ins and the order" |
| `core/citationformat` | `parse.go`: D-2, D-3, D-4; `Target` doc: "`Level` is a built-in's level, or for a field `""` (nearest-first) or the Source (list form)". `placeholder.go`: D-5. `form.go` package doc: `{meta.key}`. `builtins.go`: `ListFormLevel` *(new)*, `ListFormAllows` reads it |
| `core/database/sourcemetadata` | `annotation.go`: D-6, D-7, D-8, D-9; callers in `sourcemetadata.go` (`listWorkspaces`, `ListDraftWorkspace`, `buildEntries`'s `annotation` closure) build `above` once per board and pass it to `annotate` |
| `core/database/citationrender` | `placeholders.go`: D-11. `load.go`, `preview.go`: no code change |
| `core/database/sourcevocab` | `registry.go`: D-13 |

Errors: none new.

### FFI

`api/proto/engine.proto`: comments on `CitationPlaceholder.level` and `CitationRequirementOption.level` (D-15). `api/ffi/handlers/citation_render.go` and `metadata.go` already send `string(r.Level)`; no code change. Regenerate with `./scripts/generate-proto.sh`.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Completion row | existing `SourceTypeFormatCompletionRow` | `Features/SourceTypes/SourceTypeFormatsSection.swift` | Badge only with a level (D-17) |
| Completion options | `SourceTypeFormatsModel.completionOptions` | `Features/SourceTypes/SourceTypeFormatsModel.swift` | D-17 |
| Missing line | `L10n.CitationFormats.missing` | `Platform/L10n.swift` | D-18 |
| Store mapping | `GoStore.citationPlaceholders`, preview `missing` | `Platform/GoStore.swift` | D-16 |
| Types | `CatalogCitationPlaceholder`, `CatalogCitationOption` | `Platform/GenealogyStore.swift` | `level: Level?`; doc comments say `{meta.line_number}` and id `meta#<field id>` |
| Preview data | `#Preview` store | `SourceTypePageView.swift` | `{meta.author}`, row id `meta#f1`, level nil |

States: unchanged. Accessibility: a field row is spoken by its label alone.

### Strings

L10n keys *(new)*: `L10n.CitationFormats.diagMetaAtLevel` = "Write meta. with no level: a field is read from the nearest level that has it". Removed: `citationFormats.diagnostic.unprefixed_meta`, `citationFormats.diagnostic.meta_not_at_level`. Copy that names the old scope: `citationFormats.diagnostic.unknown_level` ("Not a level: use source, artifact, graph or citation") stays true for built-ins; `sourceTypes.formats.completion.highlighted`'s comment says "then its level, when it has one".

## 7. Steps

The `scripts/check-pr.sh` and Swift checks (STEP-9, the DoD) run on macOS with Xcode; the Go checks run anywhere.

**STEP-1 — The nearest-first order**
Files: `core/vocabkey/vocabkey.go`, `core/vocabkey/vocabkey_test.go`.
Do: D-1. Extend `TestLevels` with `NearestFirst` (T-1).
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/vocabkey/` passes.

**STEP-2 — The parser reads `{meta.key}`, and the seed is written that way**
Files: `core/citationformat/parse.go`, `builtins.go`, `placeholder.go`, `form.go` and the `core/citationformat` tests; `core/database/sourcevocab/registry.go`, `registry_test.go`, `copy_test.go`; `docs/citation-formats.md` (Syntax and Diagnostics, so `TestDocMatchesEngine` holds). Skill: `add-seeded-vocabulary`.
Do: D-2 – D-5, D-13, D-14 in one step: `sourcevocab.Install` refuses a seed format with any diagnostic, so the seed must stop naming levels in the same step the parser starts refusing them, or every test that installs the seed fails. Rewrite every level-named field in these packages' tests to `{meta.…}`. T-2 – T-5, T-11, T-12. Do **not** run `-update`: `core/database/sourcevocab/testdata/seed-citations.txt` stays byte for byte.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/citationformat/ ./core/database/sourcevocab/` passes, `TestDocMatchesEngine`, `TestSeedCitations`, `TestSeedSuggestionsFollowFormats` and `TestSeededFormatsNeedOnlySuggestedFields` included; `git diff --exit-code core/database/sourcevocab/testdata` is clean; `rg -n '(source|artifact|graph)\.meta\.' core/database/sourcevocab/registry.go` prints nothing. Other packages with level-named test fixtures still fail; STEP-3 – STEP-6 fix them.

**STEP-3 — One walker**
Files: `core/database/sourcemetadata/annotation.go`, `annotation_test.go`.
Do: D-6, D-7. T-6.
Check: `CGO_ENABLED=1 go test -tags fts5 -run 'TestCitationValues' ./core/database/sourcemetadata/` passes.

**STEP-4 — Boards annotate per field**
Files: `annotation.go`, `sourcemetadata.go` (`boardInput`, `buildEntries`' `annotation` closure, `listWorkspaces`, `ListDraftWorkspace`), `annotation_test.go`, `annotation_fuzz_test.go`, `sourcemetadata_test.go`.
Do: D-8, D-9, D-10. `readTypeBoards` and its (type, level) keying do not change. Rewrite fixtures to `{meta.…}`. T-7, T-8.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcemetadata/` passes, `TestListWorkspacesAnnotationsScale` included.

**STEP-5 — Completion lists each field once**
Files: `core/database/citationrender/placeholders.go`, `placeholders_test.go`, `render_test.go`, `preview_test.go`.
Do: D-11; rewrite fixtures. T-9, T-10.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/citationrender/` passes, `TestRenderScale` included.

**STEP-6 — Stored formats are rewritten**
Files: `core/database/migrations/000069.sql` *(new)*; `core/database/sourcetypes/formats_test.go`, `core/database/metadatafields/metadatafields_test.go`. Skill: `add-catalog-migration`.
Do: D-12. Rewrite fixtures. The migration has no Go test (skill).
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/...` passes (Create runs the step and `verifySchema`). Then run the step's statements by hand on a scratch database holding AC-3.1's stored text:

```bash
sqlite3 :memory: "CREATE TABLE source_types (citation_full TEXT, citation_short TEXT, citation_list TEXT); INSERT INTO source_types VALUES ('{source.meta.#a}, [{graph.meta.#b|source.meta.#b}][ {artifact.meta.#c}]', NULL, NULL);" ".read core/database/migrations/000069.sql" "SELECT citation_full FROM source_types;"
```

It prints `{meta.#a}, [{meta.#b|meta.#b}][ {meta.#c}]` (AC-3.1).

**STEP-7 — Wire and handlers**
Files: `api/proto/engine.proto`, generated files; `api/ffi/handlers/citation_render_test.go`, `metadata_test.go`, `source_defs_test.go`. Skill: `add-ffi-handler`.
Do: D-15; `./scripts/generate-proto.sh`; rewrite fixtures; T-13.
Check: `CGO_ENABLED=1 go test -tags fts5 ./...` passes except `api/ffi` `TestSwiftVocabularyMatchesGo` (STEP-8).

**STEP-8 — Swift**
Files: `macos/App/Platform/CitationFormatVocabulary.swift`, `GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift` (only where a constructor call needs the optional level), `L10n.swift`, `Resources/Localizable.xcstrings`, `Features/SourceTypes/SourceTypeFormatsModel.swift`, `SourceTypeFormatsSection.swift`, `SourceTypePageView.swift`; `macos/ProvenenciaTests/SourceTypeFormatsModelTests.swift`, `CitationFormatsCopyTests.swift`. Skills: `add-localized-string`, `add-swift-test`.
Do: D-16 – D-19. T-14, T-15.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/ffi/` passes; `scripts/check-pr.sh` prints `check-pr: PASS`.

**STEP-9 — Docs**
Files: `docs/citation-formats.md` (Forms, Syntax, Needed and used, Storage example `{meta.#<id>}`, Rendering, Diagnostics; "The Citation level has only built-ins" stays until S15-54), `docs/source-layer-data-model.md` § 5.4 (**Citation** bullet: a field head shows on every board, a list-form one on the Source's; met elsewhere at the owner or above), map §§ 6.3, 6.6 (state the nearest-level rule, drop "every placeholder names its level", mark the old text superseded with the date), § 6.8 (every seed format rewritten as in D-13) and § 6.9 (its one level-named token); `docs/deployment-plan/spike-15/deployment-plan.md` (rule "A format reads a field from the nearest level that holds it": `NearestFirst()` is `MetadataLevels()` reversed with `slices.Reverse`, and it updates §§ 6.3, 6.6, 6.8, 6.9; rule "Boards flag needed fields": a nearest-first head shows on every board from S15-62; the map row's Status), `docs/deployment-plan/spike-15/completed.md`, this plan (Status, Landed note); version bump.
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-62-nearest-level-fields.md` reports no errors; `rg -n '(source|artifact|graph)\.meta\.' docs/citation-formats.md docs/source-layer-data-model.md .agents .cursor` prints only lines that describe the `meta_at_level` diagnostic or the migration.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period ("Read a citation's fields from the nearest level that holds them."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/vocabkey/vocabkey_test.go` `TestLevels` | `NearestFirst()` → graph, Artifact, Source; is `MetadataLevels()` reversed; a new slice each call | D-1 |
| T-2 | Go | `core/citationformat/parse_test.go` `TestParse` | `{meta.x}` → no diagnostic; `{source.meta.x}`, `{graph.meta.x}`, `{citation.meta.x}` (AC-2.3) → `meta_at_level` over the option; `{foo.meta.x}` → `unknown_level`; `{meta.}` → `bad_field`; `{meta.x:year}` → `unknown_option`; `{meta.x}` in list → none; `{graph.name}` in list → `not_in_list_form` | AC-2.2, AC-2.3, AC-2.4, D-2, D-3 |
| T-3 | Go | `core/citationformat/requirements_test.go` `TestRequirements` | `{meta.#X\|meta.#X}` → one requirement `[X]`; `{meta.x}` in full and in list → two requirements, targets `{"" x}` and `{source x}`; `{meta.short_title\|source.title}` → used | AC-2.5, AC-3.1, D-4 |
| T-4 | Go | `core/citationformat/rewrite_test.go` `TestFieldSpans`, `TestRewriteFields` | `{meta.a\|meta.a}` → two spans; a rewrite replaces both tokens | D-4 |
| T-5 | Go | `core/citationformat/placeholder_test.go` `TestMetaFieldPlaceholder` *(renamed from `TestMetaPlaceholder`)* | `line_number` → Text `{meta.line_number}`, Ref `meta.line_number`, Level empty | D-5 |
| T-6 | Go | `core/database/sourcemetadata/annotation_test.go` `TestCitationValuesResolve` | graph and Source rows → graph's; Artifact and Source → Artifact's; Source only → Source's; graph row unknown → that row (AC-1.4); list target `{source X}` with a graph row only → zero; a whitespace graph row → that row (prints nothing); `Without(graph)` → Source's; `Without(source)` → zero for `SourceDate` | AC-1.2, AC-1.3, AC-1.4, AC-1.5, D-6, D-7 |
| T-7 | Go | `annotation_test.go` `TestNeedsAt`, `TestAnnotate` | `{meta.#a}.` at graph → a needed head; a list-form `{meta.#a}.` alone → a head at source, none at graph; a full `[{meta.#a}]` and a list `{meta.#a}` → needed at source, used at graph; head answered on the Source → met elsewhere on an Artifact board, not on the Source board; head answered at the owner only → not met elsewhere; on the Source board a needed, set Source date → not met elsewhere | AC-4.1, AC-4.2, D-8, D-9 |
| T-8 | Go | `sourcemetadata_test.go` `TestListWorkspacesAnnotations`, `TestDismissNeeded` | A census Source board lists the graph and Artifact fields its formats read, unsuggested; an Artifact board on a certificate Source with jurisdiction on the Source → needed, met elsewhere; dismissing needed jurisdiction on a graph → refused; a book Artifact board does not list `author_sort` as needed (list-only) and dismissing it there is allowed | AC-4.1 – AC-4.4, D-8, D-10 |
| T-9 | Go | `core/database/citationrender/placeholders_test.go` `TestPlaceholders` | Two project fields, full form → built-ins of every level, then each field once as `{meta.<key>}`, level empty; list form → Source built-ins, then each field once | AC-2.1, D-11 |
| T-10 | Go | `core/database/citationrender/render_test.go` `TestRender` (new cases) | AC-1.1 census Provider on the Source → "…; digital image, *Ancestry* …"; AC-1.2; AC-1.3 | AC-1.1 – AC-1.3 |
| T-11 | Go | `core/database/sourcevocab/render_test.go` `TestSeedCitations` | The rewritten seed renders `core/database/sourcevocab/testdata/seed-citations.txt` unchanged | AC-3.2, D-13 |
| T-12 | Go | `registry_test.go` `TestSeedSuggestionsFollowFormats`, `TestSeededFormatsNeedOnlySuggestedFields` | Each type's suggested fields over all levels, as a set, equal its formats' fields (plus record types' copy fields); every needed chain has a field suggested at some level | D-14 |
| T-13 | Go | `api/ffi/handlers/citation_render_test.go` (the placeholders and preview cases) | `ListCitationPlaceholders` → a field row with `level` ""; a preview missing option for a full-form field → `level` "", list form → "source" | D-15, AC-2.6 |
| T-14 | Swift | `macos/ProvenenciaTests/SourceTypeFormatsModelTests.swift` `completionRowsComeFromTheFormsPlaceholdersRankedByTheTypedQueryAlone` (fixture with a nil-level field row) and `aFieldRowHasNoLevelInItsSubtextOrSpokenLabel` *(new)* | Query `meta.prov` → the Provider row first; its subtext is `provider meta.provider`; `spokenLabel(of:)` → "Provider"; a built-in row → "Title, Source" | AC-2.1, D-17 |
| T-15 | Swift | `macos/ProvenenciaTests/CitationFormatsCopyTests.swift` (missing-line test) | `[Jurisdiction (nil level)]` → "Missing: Jurisdiction"; `[Title (source built-in), Title (nil-level field)]` → "Missing: Title on the Source, or Title"; `[Jurisdiction (source)]` → "Missing: Jurisdiction on the Source"; `diagnosticMessage(.metaAtLevel)` → the D-19 text | AC-2.2, AC-2.6, D-18, D-19 |

AC-3.1 is the migration, not tested directly (skill): T-3 tests the text it produces, and the manual check runs it. Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `TestDocMatchesEngine`, `TestSwiftVocabularyMatchesGo`, `TestSeedCitations`, `TestListWorkspacesAnnotationsScale`, the `deleteimpact` field-in-use tests.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left (`unprefixed_meta`, `meta_not_at_level`, `MetaPlaceholder`, `diagUnprefixedMeta`, `diagMetaNotAtLevel`, `usualLevel`); `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; rule "Boards flag needed fields" says a head shows on every board from S15-62; docs/deployment-plan/spike-15/completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated) — not gated
- [ ] Domain doc updated: docs/citation-formats.md, docs/source-layer-data-model.md § 5.4, map §§ 6.3, 6.6, 6.8, 6.9
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Open a project created before this version (or a copy of a dogfood project) with a census Source, an Artifact and a graph. Note the provenance sheet's citation for one of its Citations. Open with the new build: the migration runs; the citation reads the same (AC-3.2).
2. On the census Source type's page, the full format reads `{meta.…}` everywhere a field was. Type `{meta.prov`: completion offers Provider once, no level badge; accept it (AC-2.1). Type `{artifact.meta.provider}`: the warning "Write meta. with no level…" sits at it (AC-2.2). Revert.
3. On the census Source, put Provider "Ancestry" on the Source page and clear it on the Artifact sheet. The provenance sheet's citation reads "…; digital image, *Ancestry* …" (AC-1.1).
4. On the census Source page, the board now also lists empty Line number, Dwelling and Provider rows (AC-4.3).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A seed format's text changes beyond the token rewrite | STEP-2's check: the golden file is unchanged and no level-named token remains |
| A board shows a field twice (suggested at its level and emitted as a head) | `buildEntries`' `seen` set already dedupes a suggested head; T-8 counts rows |
| Another branch takes migration `000069` first | Rebase renumbers; the file has no number inside it |

**Stop and report if:**

- `core/database/migrations/` already holds `000069.sql` at your base and it is not this PR's.
- `TestSeedCitations` differs from `core/database/sourcevocab/testdata/seed-citations.txt` after STEP-2 for any line.
- `CitationValues` is built anywhere besides `core/database/citationrender/load.go`, `ListDraftWorkspace` and `listWorkspaces` (`rg -n 'CitationValues\{' core api`), or anything besides `Resolve` would read `Rows` by level.
- `TestListWorkspacesAnnotationsScale` needs a change other than its expected annotations (a new query, a board count).
- A Swift view besides those in § 4 reads `CatalogCitationPlaceholder.level` or `CatalogCitationOption.level` non-optionally.
- `TestDocMatchesEngine` needs a doc change outside `docs/citation-formats.md`'s Syntax and Diagnostics.

## 12. Open questions

None.

## Landed

- `itemFields` in `core/database/sourcevocab/registry_test.go` is deleted with `usualLevel` (nothing else read it).
- `TestSeedAnnotations`' expectation table is rebuilt for D-10: each Source board lists its unsuggested heads (120 across the 26 types), and the Artifact and graph boards need the same fields as the Source board except those only the list form needs.
- The handler's draft-board test (`TestGetDraftMetadataBoard`) now expects the type's suggestions first, then the unsuggested heads the formats read.

## 13. PR

**Title:** S15-62 — A format reads a field from the nearest level
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-62-nearest-level-fields.md`.
