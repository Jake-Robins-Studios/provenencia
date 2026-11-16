# S15-14 — The citation format engine

**Status:** Draft
**Spike / slice:** Spike 15 · Slice 4 — Formats as data
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: three pure Go packages that nothing in the app calls yet; every view looks the same)
**Board:** —
**Depends on:** S15-06 (landed [#782](https://github.com/mendahu/provenencia/pull/782))
**Blocks:** S15-15, S15-37, S15-38, S15-43, S15-44
**Branch:** `s15-14-citation-format-engine`
**Version bump:** none — new engine packages with no caller, no wire and no catalog change; nothing a researcher can see ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-date-value`](../../../../.agents/skills/add-date-value/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests; a `Fuzz` target for a parser of bytes the app did not write), `.cursor/rules/date-values.mdc`
**Context:** working rules "Follow the *Evidence Explained* style; never copy the book", "One level type", "Citation formats are data on the Source type", "Every placeholder names its level; fallback is written", "A format's fields are needed or used", "A value can be marked unknown or supplied", "Dates in citations use citation terms", "No transforms on metadata", "Formats name fields by id", "One engine, in Go", "Built-in placeholders are one table" ([`../deployment-plan.md`](../deployment-plan.md#working-rules)); [`../README.md`](../README.md#working-rules); [`../evidence-explained-citation-map.md`](../evidence-explained-citation-map.md) §§ 2, 6.3, 6.8 "Formats", 6.10
**Planned:** 2026-11-16 against `main` @ `eb7ee08`
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

A Source type's citation formats (full note, short note, source-list entry) are text in a small syntax of our own (map § 6.3). This PR builds the one engine that reads that syntax, in Go and with no database: it parses a format into a tree with positioned diagnostics, renders it through a resolver into italic and plain runs, derives which fields each format needs or uses, says which needed ones are missing, prints marked-unknown and supplied values, writes dates in citation terms through `core/datevalue`, declares the built-in placeholders once, and rewrites a format's field references between keys and ids. It also adds `core/valuemark`, the one unknown-and-supplied type the later stores share.

**Why now.** Every later PR of slices 4, 5, 6 and 9 that touches a format builds on it: S15-15 stores formats (key↔id rewrite, list-form rule, diagnostics), S15-16 renders Citations (resolver, runs, built-ins), S15-38 annotates boards (requirements), and S15-37, S15-43 and S15-44 store marks (`valuemark`). The rules it implements are settled in the map.

**What stays.** No table, RPC, Swift file or screen changes. The app keeps showing today's citation line (`CitationLineDisplay`). `datevalue.CompactDisplay` and every date the app's pages show are unchanged.

## 2. User stories

**US-1.** As the engine, when I parse a format, I get its tree or every diagnostic with its byte position, so the editor (S15-17) can point at the mistake and storage (S15-15) can refuse it.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Each of the 66 formats of map § 6.8 "Formats", parsed in its form | No diagnostic |
| AC-1.2 | `{meta.page}` (full) | One diagnostic `unprefixed_meta` spanning `meta.page` (bytes 1–10) |
| AC-1.3 | `p. [{citation.page}` (full) | One diagnostic `unclosed_group` at the `[` (bytes 3–4) |
| AC-1.4 | `{source.title}]` (full) | One diagnostic `stray_close_bracket` at bytes 14–15 |
| AC-1.5 | `{graph.meta.line_number}` in the list form | One diagnostic `not_in_list_form` spanning `graph.meta.line_number` |
| AC-1.6 | `{source.date:week}`, `{source.title:year}`, `{source.meta.url:year}` (full) | Each one diagnostic `unknown_option` spanning the option text |
| AC-1.7 | `[, ]{source.title}` (full) | One diagnostic `group_without_placeholder` at bytes 0–4 |
| AC-1.8 | `{source.foo} and {citation.meta.x} and {parish.title}` (full) | Three diagnostics in order: `unknown_builtin`, `meta_not_at_level`, `unknown_level` |
| AC-1.9 | A format of 4,097 bytes | One diagnostic `too_long` at 0–4097; nothing else is scanned |

**US-2.** As the engine, when I render a parsed format through a resolver, I get styled runs and plain text in which values print exactly as typed.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | The census full format (map § 6.8) with the values of § 8 T-6 spread over Source, Artifact, graph and Citation | Plain text: `1880 U.S. census, Ottawa County, Kansas, population schedule, ED 236, p. 14, dwelling 112, family 118, Ada Robins; digital image, Ancestry (https://www.ancestry.com : accessed 12 March 2025); citing NARA microfilm publication T9, roll 393.` with one italic run, `Ancestry` |
| AC-2.2 | `[, ED {source.meta.enumeration_district}]` with no ED value | Prints nothing |
| AC-2.3 | `[ ({artifact.meta.url}[ : accessed {artifact.meta.accessed_date}])]` with a URL and no accessed date | ` (https://example.org/1)` |
| AC-2.4 | `{source.title}` where the title is `*Kansas* [draft]` | Prints `*Kansas* [draft]`, not italic |
| AC-2.5 | `\{a\} \[b\] \*c\* \\` | Prints `{a} [b] *c* \` |
| AC-2.6 | `{graph.meta.line_number|source.meta.line_number}` with the graph empty and the Source `12` | `12` |

**US-3.** As the engine, a value marked unknown or supplied prints the way citation style marks it.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `{source.meta.publication_place}: {source.meta.publisher}` with both marked unknown and unknown text `n.p.` | `n.p.: n.p.` |
| AC-3.2 | `{source.meta.publication_place}` supplied `Topeka` | `[Topeka]` |
| AC-3.3 | `{source.date}` supplied, ABT 1880 | `[ca. 1880]` |
| AC-3.4 | `{source.date}` marked unknown | `n.d.`; `{citation.page}` marked unknown → `unpaginated` |
| AC-3.5 | `[, {source.meta.edition}]` marked unknown with no unknown text | Prints nothing (the group drops); `Missing` does not list it |
| AC-3.6 | `{graph.meta.line_number|source.meta.line_number}` with the graph marked unknown (no unknown text) and the Source `12` | Prints nothing: the graph's answer wins |
| AC-3.7 | `*{artifact.meta.provider}*` supplied `Ancestry` | One italic run `[Ancestry]` |

**US-4.** As the engine, I derive a type's requirements from its formats and say which needed ones are missing.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | Census full: `{source.meta.jurisdiction}` outside any group | One requirement, needed, options `[source.meta.jurisdiction]` |
| AC-4.2 | Census full: `[, line {graph.meta.line_number|source.meta.line_number}]` | One requirement, used, options `[graph.meta.line_number, source.meta.line_number]` |
| AC-4.3 | `{source.meta.short_title|source.title}` outside any group | One requirement, used (its chain holds an always-set built-in) |
| AC-4.4 | Missing over the census full and short formats with every value empty except the date | Exactly the needed requirements without an answer: `source.meta.jurisdiction` (once, though both formats need it) |
| AC-4.5 | A chain needed in the short form and used in the full | One requirement, needed |
| AC-4.6 | `{source.date:year}` in full and `{source.date}` in list | One requirement for `source.date`, needed |

**US-5.** As the engine, I write a DateValue in citation terms.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-5.1 | 3 March 1830, full / short | `3 March 1830` / `3 Mar. 1830` |
| AC-5.2 | ABT 1880 · BEF 3 March 1830 · AFT 1880 | `ca. 1880` · `bef. 3 March 1830` · `aft. 1880` |
| AC-5.3 | Range 1878 to 1882 | `1878–1882` (en dash) |
| AC-5.4 | `{source.date:year}` on 3 March 1830 | `1830` |
| AC-5.5 | Phrase-only `Christmas` · 1882 with phrase `Christmas` | `Christmas` · `1882` |

**US-6.** As the engine, I rewrite a format's field references between keys and ids, leaving every other byte as typed.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-6.1 | `{graph.meta.line_number|source.meta.line_number}` rewritten key → id → key | The original text, byte for byte |
| AC-6.2 | `{source.meta.url}` with `url` → id `0192f3a4-0000-7000-8000-000000000001` | `{source.meta.#0192f3a4-0000-7000-8000-000000000001}` |
| AC-6.3 | `{source.meta.#not-a-uuid}` | Diagnostic `bad_field` |

**US-7.** As a store (S15-37, S15-43, S15-44), I check a value's unknown and supplied facts with one rule.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-7.1 | Unknown with a value · supplied without one · both | `valuemark.ErrInvalid` each |
| AC-7.2 | Unknown without a value · supplied with one · neither, with or without a value | `nil` |

## 3. Scope

| In | Covered by |
| --- | --- |
| `core/valuemark`: `Mark`, `Validate`, `ErrInvalid` (`valuemark.invalid`) | STEP-1, AC-7.1, AC-7.2 |
| `datevalue.CitationDisplay` and `CitationStyle` | STEP-2, AC-5.1 – AC-5.5 |
| `core/citationformat`: `Form`, the built-ins table | STEP-3, AC-1.6, AC-1.8 |
| `Parse` to a `Template` with diagnostics and positions (every code in D-7), the list-form rule, limits | STEP-4, AC-1.1 – AC-1.9 |
| `Render` through a `Resolver` to runs and plain text, with marks and citation dates | STEP-5, AC-2.1 – AC-2.6, AC-3.1 – AC-3.7 |
| `Requirements` and `Missing` | STEP-6, AC-4.1 – AC-4.6 |
| The field-id token, `Fields` and `RewriteFields` | STEP-7, AC-6.1 – AC-6.3 |
| `FuzzParse` and the seed-format corpus | STEP-8, AC-1.1 |
| `docs/citation-formats.md` *(new)* with a parity test; link from `source-layer-data-model.md`; `add-date-value` and `date-values.mdc` name `CitationDisplay` | STEP-9 |

| Out | Home |
| --- | --- |
| Format columns on `source_types`, key → id resolution against the catalog, delete-impact probe, type RPCs | S15-15 |
| The catalog resolver, the batch render RPC, the preview request, the built-ins over FFI, the group key | S15-16 |
| Swift `Form`, diagnostic-code and built-in parity rows in `api/ffi/swift_vocabulary_test.go` | S15-16 (the first PR that sends them over FFI) |
| L10n copy for `valuemark.invalid` and for each diagnostic code | S15-37 (`valuemark.invalid`), S15-17 (diagnostics) |
| `is_unknown`, `is_supplied`, `unknown_text` storage and the proto `ValueMark` | S15-37 |
| The Source date's marks, the page's marks | S15-43, S15-44 |
| Board annotations, "met at another level" | S15-38 |
| Seeding the formats | S15-20 |
| Calendar marks (O.S., N.S., dual dating) and times of day in a citation date | not planned |
| Any whitespace or punctuation clean-up after an empty needed placeholder | not planned (rule "No transforms on metadata"; groups are the mechanism) |
| A diagnostic for options after an always-set built-in in a chain | not planned |
| Retiring the spike's `citation-formats.md` | S15-99 |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Level type | `core/vocabkey/vocabkey.go` `Level`, `Levels`, `MetadataLevels`, `Valid`, `HoldsMetadata` | Four levels, `citation` holds no metadata. This PR uses it as is |
| Date display | `core/datevalue/display.go` `CompactDisplay`, `applyQualifier`, `formatSide` | ISO-like summary (`About 1882-04`, `Between 1882 and 1882-04-03`). No citation style |
| Date type | `core/datevalue/datevalue.go` `Value`, `side`, `KindPoint`, `KindRange`, `QualifierABT` / `BEF` / `AFT` | `side` groups one end's components; `Validate` builds two |
| Date tests | `core/datevalue/display_test.go` `TestCompactDisplay`; `core/datevalue/datevaluetest/datevaluetest.go` `YMD`, `About`, `Before`, `After`, `Part` | Fixture builders this PR's tests reuse |
| Error codes | `core/apperr/apperr.go` `CodeDateValuesInvalid`, `CodeLocatorInvalid`, `New`, `KindUser` | No `valuemark` code. Codes are permanent once shipped |
| Field keys | `core/database/metadatafields/metadatafields.go` `Create` (key from `slug.Kebab`), `core/slug/slug.go` `Kebab`; `core/database/sourcevocab/registry.go` (`document_number`, `record_date`) | User keys are kebab-case (lowercase letters of any script, digits, `-`); product keys are snake_case. No key holds `#`, `.`, `:`, `|`, `{`, `}` or a space |
| Field ids | `metadatafields.Create` mints `uuid.NewV7()`; audit writes `uid.String()` | 16-byte UUIDv7; canonical string form is 36 characters |
| Always-set values | `core/database/sources/sources.go` (`in.Title == ""` refused), `core/database/sourcetypes/sourcetypes.go` (`label == ""` refused), `core/database/artifacts/artifacts.go` (`in.Label == ""` refused), `core/database/evidencegraphs/evidencegraphs.go` (`in.Name == ""` refused) | Source title, type label, Artifact label and graph name are never empty |
| Not always set | `core/database/migrations/000059.sql` (`citations.label TEXT`, nullable); `core/locator/depiction.go` `PageRef`, `Page` | A Citation's label, printed page and file page can be absent |
| Citation line today | `macos/App/Platform/CitationLineDisplay.swift` `CitationLineDisplay` | Stays the fallback (rule "Today's line stays the fallback, in Swift"); untouched |
| Citation engine | — | No template, placeholder or format parser exists in `core/` or `api/` (searched `text/template`, `placeholder`, `func Parse`) |
| Doc parity precedent | `core/matchregistry/inventory_test.go` `TestKnobInventoryMatchesRegistry` | A test that reads a `docs/*.md` table and compares it with a Go registry |
| Fuzz precedent | `core/raster/jpegdc_test.go` `FuzzDecodeJPEGDC` | `f.Add` seeds; crashers under `testdata/fuzz/<Target>/` |
| Domain docs | `docs/source-layer-data-model.md` § 3 `source_types`; `.agents/skills/add-date-value/SKILL.md` "Package"; `.cursor/rules/date-values.mdc` | Name `CompactDisplay` only; no citation-format doc |

**Precedent.** `core/datevalue` (pure value type, its own `ErrInvalid` code passed through by every store, table tests) is the shape for `core/valuemark`: copy its `ErrInvalid` declaration and its doc-comment style. `core/matchregistry/inventory_test.go` is the shape for the doc parity test: copy how it reads a Markdown table's backticked first column; do not copy its `notYetBuilt` machinery. `core/raster` `FuzzDecodeJPEGDC` is the shape for the fuzz target.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | Three packages: `core/valuemark` (pure, imports `core/apperr`), `core/citationformat` (pure, imports `core/vocabkey`, `core/datevalue`, `core/valuemark`, `github.com/google/uuid`), and `CitationDisplay` in `core/datevalue`. No `core/database` import anywhere | Rules "One engine, in Go", "A value can be marked unknown or supplied" (`valuemark` is its own pure package so `locator`, `sourcemetadata` and `sources` use it without importing the engine), "Dates in citations use citation terms" | `Mark` inside `citationformat` — `core/locator` would import the format engine for two booleans |
| D-2 | `valuemark.Mark{Unknown, Supplied bool}`; `func Validate(m Mark, hasValue bool) error` returns `ErrInvalid` when both are set, when `Unknown` and `hasValue`, or when `Supplied` and not `hasValue`; else `nil`. `ErrInvalid = apperr.New(apperr.CodeValueMarkInvalid, apperr.KindUser)`, with `CodeValueMarkInvalid = "valuemark.invalid"` *(new)* in `core/apperr` | The rule: never both; unknown has no text. A supplied fact with nothing supplied says nothing, so it is refused too. Its own code, passed through by stores, as `datevalue.ErrInvalid` is | Each store mapping to its own code — three copies of the rule's error; a method `m.Validate` — the map and S15-37's Check name `valuemark.Validate` |
| D-3 | `datevalue.CitationDisplay(v Value, s CitationStyle) string` with `type CitationStyle struct{ YearOnly, AbbreviateMonths bool }`. Rules: day-month-year in that order, each part present only when stored; a day without a month is dropped; times of day and zone are dropped; months spelled out, or abbreviated `Jan.`, `Feb.`, `Mar.`, `Apr.`, `May`, `June`, `July`, `Aug.`, `Sept.`, `Oct.`, `Nov.`, `Dec.`; qualifier prefix `ca. ` (ABT), `bef. ` (BEF), `aft. ` (AFT); a range prints `start–end` (U+2013), and once when both sides print the same; the phrase prints only when no structured part prints; `YearOnly` keeps the qualifier and prints only years; calendar is ignored. Empty result when nothing prints | Rule "Dates in citations use citation terms"; the map's examples ("ca. 1880", "bef. 3 March 1830", "1878–1882"). The style is a struct, not a citation `Form`, because `datevalue` cannot import `citationformat` (it imports `datevalue`); the map's sketch `CitationDisplay(v, form)` names the argument, not its type | Reusing `formatSide` — it writes ISO digits; extending `CompactDisplay` with a flag — the app's pages keep their style |
| D-4 | `CitationDisplay` reads each end through a new unexported `func (v Value) startSide() side` / `endSide() side` in `datevalue.go`, and `Validate` uses them too; `CompactDisplay` is not changed | One place builds a `side` from a `Value` (Validate builds it inline today); the precision rule ("present components only") is the shared part | Rewriting `CompactDisplay` onto `side` — Out (no change to the app's display) |
| D-5 | `type Form string` in `citationformat`: `FormFull = "full"`, `FormShort = "short"`, `FormList = "list"`; `Forms()` (new slice, that order); `(f Form) Valid() bool`. Short uses `AbbreviateMonths`; full and list spell months | The three forms of map § 6.3; the typed-key shape of `vocabkey.Level` | Reusing `vocabkey` for forms — `vocabkey` holds vocabulary keys, not render forms |
| D-6 | The built-ins table: `type Builtin struct{ Level vocabkey.Level; Name string; Date bool; Options []string; AlwaysSet bool; UnknownText string }`, `func Builtins() []Builtin` (new slice), `func LookupBuiltin(l vocabkey.Level, name string) (Builtin, bool)`. Rows, in this order: `source.title` (always set), `source.type` (always set), `source.date` (date, options `year`, `full`, unknown text `n.d.`), `artifact.label` (always set), `graph.name` (always set), `citation.page` (unknown text `unpaginated`), `citation.image`, `citation.label`. Whether a placeholder is allowed in the list form is one function, `func ListFormAllows(l vocabkey.Level) bool` (Source only), for built-ins and metadata alike | Rule "Built-in placeholders are one table"; map § 6.3 "Built-in placeholders" and "Resolving a placeholder"; always-set from § 4's write checks; unknown texts from the rule "A value can be marked unknown or supplied" | A per-row `InListForm` column — it would repeat the level for every row and could disagree with the metadata rule; `citation.label` always set — `citations.label` is nullable |
| D-7 | `func Parse(text string, form Form) (*Template, []Diagnostic)`. A non-nil template comes back only with zero diagnostics. `Diagnostic{Code DiagnosticCode; Span Span}`; `Span{Start, End int}` in UTF-8 byte offsets of `text`, half-open. `DiagnosticCodes()` lists every code. Codes: `unknown_form`, `too_long`, `too_deep`, `unclosed_placeholder`, `stray_close_brace`, `unclosed_group`, `stray_close_bracket`, `unclosed_italic`, `bad_escape`, `empty_option`, `unknown_level`, `unprefixed_meta`, `meta_not_at_level`, `bad_field`, `unknown_builtin`, `unknown_option`, `not_in_list_form`, `group_without_placeholder`. Diagnostics come back sorted by `Span.Start`. A diagnostic about one option spans that option's text (between `{` or `|` and `|` or `}`), except `unknown_option` (the text after `:`), `bad_field` (the text after `meta.`) and `empty_option` (zero width at its place) | Rule "One render request for previews" (diagnostics with positions); byte offsets are Go's native index, and S15-17 converts with Swift's `utf8` view, which is not parsing. Typed string codes so S15-16 can add a Swift parity row | Rune or UTF-16 offsets — a second index in Go that only Swift needs; returning an `error` — the editor needs all of them |
| D-8 | Grammar. Outside a placeholder: `\` escapes exactly `\ { } [ ] *` (any other escape, or `\` at the end, is `bad_escape`); `{` opens a placeholder that runs to the next `}` (none → `unclosed_placeholder`, and scanning stops); `}` is `stray_close_brace`; `[` opens a group, `]` closes the innermost (none open → `stray_close_bracket`); `*` opens italic, and the next `*` in the same group closes it (still open when the group or text ends → `unclosed_italic` at the opening `*`); `|` and everything else are literal. Inside a placeholder: options split on `|`; an empty option is `empty_option`. An option is `level.meta.field[:option]` or `level.name[:option]` with no spaces; the text after its first `:` is the option. A level with nothing after it (`{source}`) is `unknown_builtin`; `level.meta` with no field is `bad_field`. `level` must be `vocabkey.Level(level).Valid()` (`meta` as the first part is `unprefixed_meta`; anything else `unknown_level`); `meta` at a level that does not `HoldsMetadata` is `meta_not_at_level`; `field` is either a key of one or more Unicode letters, digits, `_` or `-`, or `#` plus a canonical lowercase UUID (36 characters), else `bad_field`; `name` must be in the built-ins table (`unknown_builtin`); `:option` must be in that row's `Options` (`unknown_option`, also for any option on metadata); in `FormList`, `!ListFormAllows(level)` is `not_in_list_form`. A group with no placeholder of its own (italic is transparent, a nested group is not its own) is `group_without_placeholder`. Limits: `MaxFormatBytes = 4096` (`too_long`, nothing else scanned); `MaxDepth = 8` nested groups and italic spans (`too_deep` at the opening that passes it, scanning stops) | Map § 6.3 "The syntax"; the map lists `\{ \[ \* \\`, and `\}` and `\]` join them so every special has a literal form. 66 of 66 map § 6.8 formats pass this grammar (checked while planning: longest 691 bytes, deepest 2 groups, every group has a placeholder of its own). The limits bound work on text the app did not write before any of it is done | Trimming spaces inside braces — two spellings of one placeholder; a group with only nested groups — no seeded format has one, and its drop rule would need a second rule |
| D-9 | Group rule: a group prints when every placeholder of its own prints non-empty text; otherwise it and everything inside it (nested groups included) print nothing. A nested group decides for itself only after its parent prints | Map § 6.3: an optional group is removed entirely if any placeholder inside it is empty, and groups nest; the census URL group (outer group: the URL; inner group: the accessed date) needs the inner group to drop alone | Counting nested groups' placeholders as the parent's — the URL would drop whenever the accessed date is empty |
| D-10 | `Resolver` is `interface{ Resolve(r Ref) Value }`; `Value{Text string; Date *datevalue.Value; Mark valuemark.Mark; UnknownText string}`. `Ref{Level vocabkey.Level; Builtin string; Field FieldRef; Option string; Span Span}` (`Builtin` empty means metadata). A date built-in reads `Value.Date` only; every other ref reads `Value.Text` only. An option is **answered** when its mark is unknown, or when its printed text is non-blank (`strings.TrimSpace` not empty; a date's text is `CitationDisplay`'s). A chain takes the first answered option, in order; none answered prints nothing. What prints: unknown → the built-in row's `UnknownText` for a built-in, `Value.UnknownText` for metadata (it wins over `Supplied` if a resolver sends both); supplied → `[` + text + `]`; else the text as given, untrimmed | Rules "Every placeholder names its level; fallback is written" (COALESCE), "A value can be marked unknown or supplied", "No transforms on metadata". An unknown answer at the graph is the item's answer, so the chain stops there (AC-3.6). No error from `Resolve`: S15-16 loads values in batches before rendering | Skipping an unknown option in a chain — a graph marked "line not given" would print the Source's line for it |
| D-11 | `func Render(t *Template, r Resolver) Rendered`; `Rendered{Runs []Run}`, `Run{Text string; Italic bool}`, `func (r Rendered) Plain() string`. Values go in as literal text after parsing. Adjacent runs of the same style merge; empty runs are dropped. A supplied value's brackets take the value's style. A nil or empty template renders no runs | Rule "One engine, in Go" (values never format); map § 6.3 "The engine" (styled runs; rich text is built from them by the caller) | Returning a missing list from `Render` — rule "A format's fields are needed or used": the batch render has none |
| D-12 | `type Need string` (`NeedNeeded = "needed"`, `NeedUsed = "used"`); `Requirement{Options []Ref; Need Need}`; `func Requirements(ts ...*Template) []Requirement` (nil templates skipped). A placeholder outside every group is needed; inside any group, used; a chain holding an always-set built-in is used. Requirements are one per chain identity (the ordered options' `Level`, `Builtin` and `Field`; `Option` and `Span` ignored), in order of first appearance; a chain needed in any template is needed. `func Missing(reqs []Requirement, r Resolver) []Requirement` returns the needed requirements with no answered option, in input order | Rule "A format's fields are needed or used"; map § 6.3: a built-in in a chain whose last option always has a value is never needed — used, because its first option still shapes the citation | Per-form requirement lists — S15-38 annotates a board from the type's three formats at once; including used ones in `Missing` — an empty used field drops its group cleanly and is not missing |
| D-13 | Field token: `FieldRef{Key string; ID uuid.UUID}` (exactly one set; `ByID()` is `ID != uuid.Nil`); `(f FieldRef) Token() string` is the key, or `#` + `ID.String()`. `(t *Template) Fields() []FieldRef` lists distinct field refs in order of first appearance. `(t *Template) RewriteFields(to func(FieldRef) (FieldRef, error)) (string, error)` replaces only each field's bytes with the token of `to`'s answer and returns the first error `to` returns; every other byte stays as typed | Rule "Formats name fields by id": one stored token and one rewrite. `#` cannot occur in a key (§ 4), so a token is never a key. Span replacement keeps a researcher's spacing and escapes through key → id → key | Re-printing the tree — it would rewrite escapes and spacing the researcher typed; a raw 32-hex token — the audit and logs already use the canonical form |
| D-14 | The tree is unexported. `Template` exports `Form()`, `Text()`, `Fields()`, `RewriteFields`; callers use `Render`, `Requirements` and `Missing` | Every caller in the map is served by these; an exported node set is API surface no PR reads | Exported node types — nothing outside the package walks the tree |
| D-15 | Tests live in `package citationformat_test`, table-driven; `FuzzParse` seeds from `core/citationformat/testdata/seed-formats.txt` *(new)*: the 66 map § 6.8 formats, one per line as `form<TAB>text`, wrapped lines joined with nothing between them | `go-tests.mdc` (fuzz target for a parser of bytes the app did not write); the same file proves AC-1.1. S15-20 replaces the file's role with the registry | Seeds only in code — the rule asks for `testdata/` |
| D-16 | `docs/citation-formats.md` *(new)* holds the syntax, the forms, the built-ins table, the diagnostic codes, needed and used, unknown and supplied, and citation dates. `TestDocMatchesEngine` *(new)* checks its built-ins table names exactly `Builtins()` and its diagnostics table names exactly `DiagnosticCodes()` | The scope entry ("Writes the syntax as a domain doc"); a doc table beside a registry drifts without a check (matchregistry precedent) | Generating the doc from Go — no generator exists for any doc |

**Rules this plan bends.** None. D-3's `CitationStyle` is the argument the rule's sketch calls `form` (import direction, D-3 Why); D-2's "supplied needs a value" adds to the rule's "never both; unknown has no text" without contradicting it (both are reported to the user).

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `core/valuemark` *(new)* | package | `core/datevalue` (pure value + `Validate`) | A mark sits beside text, dates and pages; it is not a date. Its own pure package is the map's call |
| `apperr.CodeValueMarkInvalid` *(new)* | error code | `CodeDateValuesInvalid` | One code per pure value package, as today |
| `datevalue.CitationDisplay`, `CitationStyle` *(new)* | func, type | `CompactDisplay` | The app's style stays; a second style beside it (rule) |
| `startSide`, `endSide` *(new)* | unexported func | inline `side` literals in `Validate` | Replaces those literals (D-4) |
| `core/citationformat` *(new)* | package | none: searched `text/template`, `placeholder`, `func Parse` in `core/`, `api/` | No template or format engine exists |
| `citationformat.Form` *(new)* | type | `vocabkey.Level` (typed key shape) | Forms are not vocabulary keys (D-5) |
| `Builtin`, `Builtins`, `LookupBuiltin`, `ListFormAllows` *(new)* | table, funcs | `vocabkey.Levels` | The table is the rule's one declaration; levels are reused, not copied |
| `Parse`, `Template`, `Diagnostic`, `DiagnosticCode`, `Span` *(new)* | funcs, types | `locator` JSON validation (`core/locator/validate.go`) | Different syntax; locator returns one error, the editor needs positions |
| `Render`, `Resolver`, `Value`, `Ref`, `Run`, `Rendered` *(new)* | funcs, types | — | First renderer |
| `Requirements`, `Missing`, `Requirement`, `Need` *(new)* | funcs, types | — | First requirement derivation |
| `FieldRef`, `Token`, `Fields`, `RewriteFields` *(new)* | type, funcs | — | First stored field reference in text |
| `FuzzParse`, `testdata/seed-formats.txt` *(new)* | test, fixture | `FuzzDecodeJPEGDC` | Same shape |
| `TestDocMatchesEngine` *(new)* | test | `TestKnobInventoryMatchesRegistry` | Same shape, smaller |
| `docs/citation-formats.md` *(new)* | doc | the spike's `citation-formats.md` (design notes, retired at S15-99) | The domain doc outlives the spike |

**Builds on.** `vocabkey.Level` for every prefix (rule "One level type"); `datevalue` for dates; the `apperr` registry; the matchregistry doc-parity and raster fuzz precedents.
**Deletes.** The inline `side` literals in `datevalue.Validate` (replaced by `startSide` / `endSide`, D-4). Nothing else becomes dead: no caller exists yet.
**Next adds.** S15-15: `Parse(text, form)` refuses a save with diagnostics; `Fields()` → `metadatafields.ResolveKeysTx` → `RewriteFields` to ids on write and back to keys on read; the delete-impact probe searches the format columns for `FieldRef{ID: id}.Token()`. S15-16: a `Resolver` over batched catalog reads, `Render` per Citation, `Missing` for the preview, `Builtins()` over FFI, and Swift parity rows for `Form`, `DiagnosticCode` and the built-in names. S15-37 / S15-43 / S15-44: `valuemark.Mark` in `sourcemetadata.Input`, the Source date write and `locator.PageRef`, checked with `valuemark.Validate`; S15-37 maps `valuemark.invalid` in `L10n.Errors`. S15-38: `Requirements(full, short, list)` per type, grouped by each option's `Level`. S15-17: diagnostic copy per code.

### Reach

None — no new path into existing code, no new state reachable. Nothing calls the new packages in this PR; `Validate`'s refactor (D-4) keeps its behavior (T-2).

### Scale

None — no write, list or loop changes in the app. At the map's Scale the engine's work is bounded by D-8's limits: `Parse` is one pass over at most 4,096 bytes; `Render` resolves each placeholder of one template once (the census full format has 18 placeholders, 24 options), so 300 Citations is under 8,000 `Resolve` calls. S15-16 measures the render RPC at 300 and 1,200 Citations (its Check); this PR sets no budget.

### Edges

- **Assumptions.** The chain is ordered (first answered wins; T-6 holds the order with the graph and Source swapped). Requirements are deduplicated by chain identity, so a field in two different chains is two requirements (T-9). A group's drop depends only on its own placeholders (D-9; T-6 holds the nested census URL group). `RewriteFields` assumes field spans do not overlap and are in text order, which the single forward scan guarantees (T-10 round trip). Values are inserted after parsing, so no value can change structure (T-6 rows with `*`, `[`, `{`, `\` in values).
- **Neighbors.** Unknown with unknown text vs. unknown without (prints vs. drops its group, both met: T-7, T-9). Supplied text vs. supplied date (both bracketed, the date keeps its qualifier: T-7). Whitespace-only text is unanswered; text with surrounding spaces prints as given (T-6). `{source.date}` vs. `{source.date:full}` print the same; `:year` keeps `ca.` (T-3). A range whose sides print the same prints once (`1882`, T-3). `{meta.x}` vs. `{source.meta.x}` vs. `{citation.meta.x}` (T-4). A key with a hyphen, an underscore, a non-ASCII letter (`île`) parses; `a.b`, `a b`, `A:B` do not (T-4).
- **Removed inputs.** A field a format names cannot be deleted (S15-15's probe). A resolver that finds nothing for a ref returns the zero `Value`, which is unanswered: a needed placeholder prints nothing and `Missing` lists it; a used one drops its group (T-6, T-9).
- **Real data.** The 66 formats of map § 6.8 parse with no diagnostic (T-5); the longest is 691 bytes with keys, about 1,300 with id tokens, under `MaxFormatBytes`; the deepest nesting is 2.
- **Untrusted size.** Format text comes from the catalog, which a crafted project can fill. Bounds, checked before any work: bytes ≤ `MaxFormatBytes` (4,096); nesting ≤ `MaxDepth` (8); options per chain and placeholders per format are bounded by the byte limit. Values come from the resolver and are copied once into runs, linear in their size. `FuzzParse` runs 5 minutes over the corpus (STEP-8).

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/apperr` | `CodeValueMarkInvalid = "valuemark.invalid"` *(new)* |
| `core/valuemark` *(new)* | `type Mark struct{ Unknown, Supplied bool }`; `var ErrInvalid`; `func Validate(m Mark, hasValue bool) error` (D-2) |
| `core/datevalue` | `type CitationStyle struct{ YearOnly, AbbreviateMonths bool }` *(new)*; `func CitationDisplay(v Value, s CitationStyle) string` *(new)* in `display.go` (D-3); `startSide`, `endSide` *(new)* in `datevalue.go` (D-4) |
| `core/citationformat` *(new)* | `form.go`: `Form`, `Forms`, `Valid`. `builtins.go`: `Builtin`, `Builtins`, `LookupBuiltin`, `ListFormAllows`. `parse.go`: `Parse`, `Template`, `Diagnostic`, `DiagnosticCode` and its constants, `DiagnosticCodes`, `Span`, `MaxFormatBytes`, `MaxDepth`, `FieldRef`, `Ref`. `render.go`: `Resolver`, `Value`, `Run`, `Rendered`, `Plain`, `Render`. `requirements.go`: `Need`, `Requirement`, `Requirements`, `Missing`. `rewrite.go`: `Token`, `ByID`, `Fields`, `RewriteFields`. Package doc in `form.go` names the syntax doc |

```go
// citationformat, signatures only
func Parse(text string, form Form) (*Template, []Diagnostic)
func Render(t *Template, r Resolver) Rendered
func Requirements(ts ...*Template) []Requirement
func Missing(reqs []Requirement, r Resolver) []Requirement
func (t *Template) RewriteFields(to func(FieldRef) (FieldRef, error)) (string, error)

type Resolver interface{ Resolve(r Ref) Value }
type Value struct {
	Text        string
	Date        *datevalue.Value
	Mark        valuemark.Mark
	UnknownText string // metadata only; a built-in's comes from its row
}
```

Errors: `valuemark.invalid` → `valuemark.Validate` refuses a mark (D-2). `citationformat` returns no error of its own; `RewriteFields` returns `to`'s.

### FFI

None — S15-16 and S15-15 carry the engine over FFI.

### macOS

None — no Swift change.

### Strings

None — no user-facing copy in this PR. The engine's literal output (`n.d.`, `unpaginated`, `ca.`, month names) is citation text in English, like the formats' own literals, and is not localized.

## 7. Steps

**STEP-1 — The value mark**
Files: `core/apperr/apperr.go`, `core/valuemark/valuemark.go` *(new)*, `core/valuemark/valuemark_test.go` *(new)*.
Do: add `CodeValueMarkInvalid` beside `CodeLocatorInvalid`; add the package per D-2 with a package comment that names the three stores that use it (S15-37, S15-43, S15-44) and the rule.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/valuemark/ ./core/apperr/` passes (T-1).

**STEP-2 — Citation dates**
Files: `core/datevalue/datevalue.go`, `core/datevalue/display.go`, `core/datevalue/display_test.go`. Skill: `add-date-value`.
Do: add `startSide` / `endSide` and use them in `Validate` (D-4); add `CitationStyle` and `CitationDisplay` per D-3 beside `CompactDisplay`, with the month names and qualifier words as unexported tables.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/datevalue/...` passes (T-2, T-3).

**STEP-3 — Forms and the built-ins table**
Files: `core/citationformat/form.go` *(new)*, `core/citationformat/builtins.go` *(new)*, `core/citationformat/builtins_test.go` *(new)*.
Do: D-5 and D-6. The package comment says: pure, no database; the syntax is in `docs/citation-formats.md` *(new)*, written in STEP-9.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/citationformat/` passes (T-8's table rows).

**STEP-4 — Parse**
Files: `core/citationformat/parse.go` *(new)*, `core/citationformat/parse_test.go` *(new)*.
Do: D-7, D-8, D-14: one forward scan over bytes with a stack of open groups and italic spans; each placeholder's options checked against `vocabkey` and the built-ins table; diagnostics collected and sorted; the template keeps the text, the form and, for each metadata option, its field's byte span.
Check: `CGO_ENABLED=1 go test -tags fts5 -run 'TestParse' ./core/citationformat/` passes (T-4).

**STEP-5 — Render**
Files: `core/citationformat/render.go` *(new)*, `core/citationformat/render_test.go` *(new)*.
Do: D-9, D-10, D-11. Dates print through `datevalue.CitationDisplay` with `AbbreviateMonths` for `FormShort` and `YearOnly` for `:year`.
Check: `CGO_ENABLED=1 go test -tags fts5 -run 'TestRender' ./core/citationformat/` passes (T-6, T-7).

**STEP-6 — Requirements and missing**
Files: `core/citationformat/requirements.go` *(new)*, `core/citationformat/requirements_test.go` *(new)*.
Do: D-12. `Missing` uses the same "answered" test as `Render` (one unexported function, used by both).
Check: `CGO_ENABLED=1 go test -tags fts5 -run 'TestRequirements|TestMissing' ./core/citationformat/` passes (T-9).

**STEP-7 — Field tokens and the rewrite**
Files: `core/citationformat/rewrite.go` *(new)*, `core/citationformat/rewrite_test.go` *(new)*.
Do: D-13.
Check: `CGO_ENABLED=1 go test -tags fts5 -run 'TestRewriteFields|TestFields' ./core/citationformat/` passes (T-10).

**STEP-8 — The seed corpus and the fuzz target**
Files: `core/citationformat/testdata/seed-formats.txt` *(new)*, `core/citationformat/fuzz_test.go` *(new)*, `core/citationformat/parse_test.go`.
Do: write the 66 formats of map § 6.8 "Formats" (`docs/deployment-plan/spike-15/evidence-explained-citation-map.md`), one per line as `form<TAB>text`, each wrapped format joined with nothing between its lines (every wrap falls between `]`, `}` or `*` and `[` or `{`). `TestSeedFormatsParse` *(new)* parses every line in its form (T-5). `FuzzParse` seeds from the file and from every T-4 input; for each input it checks T-11's invariants. Run the fuzzer for 5 minutes; commit any crasher under `testdata/fuzz/FuzzParse/` with its fix.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/citationformat/` passes; `go test -run '^$' -fuzz FuzzParse -fuzztime 5m ./core/citationformat/` finds nothing new (report its last line).

**STEP-9 — Docs**
Files: `docs/citation-formats.md` *(new)*, `core/citationformat/doc_test.go` *(new)*, `docs/source-layer-data-model.md` (§ 3, one sentence and link), `.agents/skills/add-date-value/SKILL.md` ("Package" tree and the types line), `.cursor/rules/date-values.mdc` (first bullet), `docs/deployment-plan/spike-15/completed.md`, `docs/deployment-plan/spike-15/deployment-plan.md` (map row), this plan (status).
Do: write the domain doc from map § 6.3 and this plan's D-6 to D-13, in Provenencia's words, with invented examples only (the census example of AC-2.1 is ours); add `TestDocMatchesEngine` (D-16); the skill and rule name `CitationDisplay` beside `CompactDisplay`; then the Definition of done's docs lines.
Check: `CGO_ENABLED=1 go test -tags fts5 -run TestDocMatchesEngine ./core/citationformat/` passes; `python3 scripts/check-plan-docs.py --links docs/citation-formats.md` reports no error.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/valuemark/valuemark_test.go` `TestValidate` *(new)* | The six rows of AC-7.1 and AC-7.2 → `ErrInvalid` / `nil`; the error's code is `valuemark.invalid` | AC-7.1, AC-7.2, D-2 |
| T-2 | Go | `core/datevalue/validate_test.go` (existing tests) | Unchanged results after `startSide` / `endSide` | D-4 |
| T-3 | Go | `core/datevalue/display_test.go` `TestCitationDisplay` *(new)* | AC-5.1, AC-5.2, AC-5.3, AC-5.4, AC-5.5; month-only `March`; day and month `3 March`; year and day without month → `1882`; `YearOnly` on ABT 3 March 1830 → `ca. 1830`; range 1882-01 to 1882-12 `YearOnly` → `1882`; each abbreviated month (`Sept.`, `June`); time only → empty; `TestCompactDisplay` unchanged | AC-5.1, AC-5.2, AC-5.3, AC-5.4, AC-5.5, D-3 |
| T-4 | Go | `core/citationformat/parse_test.go` `TestParse` *(new)* | AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, AC-1.7, AC-1.8, AC-1.9 and AC-6.3 with codes and spans; `unknown_form` for `Form("x")`; `bad_escape` for `\x` and a trailing `\`; `empty_option` for `{}` and `{source.title|}`; `stray_close_brace`; `unclosed_placeholder` stops the scan; `unclosed_italic` for `*a [b* c]` (two, at bytes 0 and 5); `too_deep` at the ninth `[`; keys `line_number`, `1880-census`, `île` parse; `a.b`, `a b`, `A:B` → `bad_field`; diagnostics sorted by start | AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, AC-1.7, AC-1.8, AC-1.9, AC-6.3, D-7, D-8 |
| T-5 | Go | `core/citationformat/parse_test.go` `TestSeedFormatsParse` *(new)* | Each of the 66 lines of `core/citationformat/testdata/seed-formats.txt` → a template, no diagnostic | AC-1.1, D-15 |
| T-6 | Go | `core/citationformat/render_test.go` `TestRender` *(new)* | Census full with: date 1880; Source `creator` `U.S.`, `jurisdiction` `Ottawa County, Kansas`, `schedule` `population schedule`, `enumeration_district` `236`; graph `dwelling_number` `112`, `family_number` `118`, `item` `Ada Robins`; page `14`; Artifact `format` `digital image`, `provider` `Ancestry`, `url` `https://www.ancestry.com`, `accessed_date` `12 March 2025`, `citing` `NARA microfilm publication T9, roll 393` → AC-2.1 runs and plain; the same with the item on the Source only → same text; AC-2.2, AC-2.3, AC-2.4, AC-2.5, AC-2.6; values `a*b`, `[x]`, `{y}`, `\` print as given; `  spaced  ` prints with its spaces; whitespace-only is unanswered; a ref the resolver does not know → unanswered; nil template → no runs | AC-2.1, AC-2.2, AC-2.3, AC-2.4, AC-2.5, AC-2.6, D-9 – D-11 |
| T-7 | Go | `core/citationformat/render_test.go` `TestRenderMarks` *(new)* | AC-3.1, AC-3.2, AC-3.3, AC-3.4, AC-3.5, AC-3.6, AC-3.7; short form `{source.date}` on 3 March 1830 → `3 Mar. 1830`; unknown and supplied both sent → unknown text | AC-3.1, AC-3.2, AC-3.3, AC-3.4, AC-3.5, AC-3.6, AC-3.7, D-10 |
| T-8 | Go | `core/citationformat/builtins_test.go` `TestBuiltins` *(new)* | Eight rows in D-6's order with their facts; `LookupBuiltin(LevelCitation, "page")` found, `(LevelSource, "page")` not; `ListFormAllows` true for Source only; every row's `Level` is `Valid()`; `Builtins()` returns a new slice each call | D-6 |
| T-9 | Go | `core/citationformat/requirements_test.go` `TestRequirements`, `TestMissing` *(new)* | AC-4.1, AC-4.2, AC-4.3, AC-4.4, AC-4.5, AC-4.6; a field in two different chains → two requirements; nil templates skipped; `Missing` with an unknown-without-text needed field → not listed; with a zero `Value` → listed | AC-3.5, AC-4.1, AC-4.2, AC-4.3, AC-4.4, AC-4.5, AC-4.6, D-12 |
| T-10 | Go | `core/citationformat/rewrite_test.go` `TestRewriteFields`, `TestFields` *(new)* | AC-6.1, AC-6.2; escapes and spaces outside fields kept byte for byte; a `to` error is returned and no text; `Fields` distinct in first-appearance order; `Token` of a key and of an id | AC-6.1, AC-6.2, D-13 |
| T-11 | Go | `core/citationformat/fuzz_test.go` `FuzzParse` *(new)* | Any input: `Parse` does not panic; a template comes back exactly when there are no diagnostics; every span is inside the text; with a template, `Render` with a resolver that answers every ref does not panic, and `RewriteFields` with the identity function returns the input | D-7, D-8, D-13, D-15 |
| T-12 | Go | `core/citationformat/doc_test.go` `TestDocMatchesEngine` *(new)* | The doc's built-ins table first column = `Builtins()` as `level.name`; its diagnostics table first column = `DiagnosticCodes()` | D-16 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `core/datevalue` tests (STEP-2 touches `Validate`).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left — none in this PR
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated — none
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New — no UI
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — none
- [ ] FuzzParse ran 5 minutes; its last output line is in the PR description; any crasher is committed under testdata/fuzz/FuzzParse/
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated) — not gated
- [ ] Domain doc: docs/citation-formats.md (new) written and linked from docs/source-layer-data-model.md § 3; add-date-value and date-values.mdc name CitationDisplay
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

None in the app — nothing calls the engine yet; slice 4's Check ("the census example renders in a handler test") is S15-16's. The reviewer checks the engine from the command line:

1. `CGO_ENABLED=1 go test -tags fts5 -v -run 'TestRender/census' ./core/citationformat/` prints the census row passing; read its expected text against map § 6.8's example.
2. `CGO_ENABLED=1 go test -tags fts5 -run TestSeedFormatsParse ./core/citationformat/` passes: every map format parses.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A seeded format in map § 6.8 does not parse under D-8 | Checked while planning (66 of 66); T-5 holds it |
| A later PR needs the tree exported | D-14 lists every map caller; a new need is a change to this package with its own decision |
| Citation terms ("ca.", month abbreviations, "unpaginated", "n.d.") differ from the edition on hand | Each is one table row in `datevalue` or the built-ins table; the user's edition check (map § 7) changes the row, not the code |
| `Validate`'s refactor changes a date's acceptance | T-2: the existing tests unchanged |

**Stop and report if:**

- A line of `core/citationformat/testdata/seed-formats.txt` *(new)* copied from map § 6.8 gets a diagnostic under D-8 (name the line and the code): the map or D-8 is wrong, and that is the planner's call.
- `core/citationformat` or `core/valuemark` would need to import a `core/database` package.
- `datevalue.Validate`'s existing tests fail after D-4 and the fix would change a test's expectation.
- A key in `core/database/sourcevocab/registry.go` or any test fixture's field key holds a character outside D-8's key set.
- The fuzzer finds a crash whose fix needs a change to a Decision (a limit, a code, the grammar).

## 12. Open questions

None.

## 13. PR

**Title:** S15-14 — The citation format engine
**Body:** objective in one sentence; what shipped against each US; AC evidence (test names); the fuzz run's last line; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-14-citation-format-engine.md`.
